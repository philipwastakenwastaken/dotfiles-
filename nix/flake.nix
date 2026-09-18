{
  description = "flake for development environment";

  inputs = {
    nixpkgs.url          = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url   = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url      = "github:numtide/flake-utils";
    neovim.url           = "github:nix-community/neovim-nightly-overlay";
    fenix.url            = "github:nix-community/fenix";
    azure-pipelines = {
      url = "github:sofusa/azure-pipelines-language-server-nix";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    flake-utils,
    fenix,
    azure-pipelines,
    neovim
  }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        dotnet10BinOverlay = final: prev: {
          dotnetCorePackages = prev.dotnetCorePackages // {
            sdk_10_0        = prev.dotnetCorePackages.sdk_10_0-bin;
            aspnetcore_10_0 = prev.dotnetCorePackages.aspnetcore_10_0-bin;
            runtime_10_0    = prev.dotnetCorePackages.runtime_10_0-bin;
            dotnet_10       = prev.dotnetCorePackages.dotnet_10 // {
              sdk        = prev.dotnetCorePackages.sdk_10_0-bin;
              aspnetcore = prev.dotnetCorePackages.aspnetcore_10_0-bin;
              runtime    = prev.dotnetCorePackages.runtime_10_0-bin;
            };
          };
        };
        pkgs        = import nixpkgs        { inherit system; config.allowUnfree = true; overlays = [ dotnet10BinOverlay ]; };
        pkgs-stable = import nixpkgs-stable { inherit system; config.allowUnfree = true; };
        rustToolchain = fenix.packages.${system}.complete.withComponents [
          "cargo"
          "clippy"
          "rust-src"
          "rustc"
          "rustfmt"
        ];
        rustAnalyzer =
          # Use the toolchain component instead of the cargo-built nightly package.
          fenix.packages.${system}.complete.rust-analyzer;

        azureCli = pkgs.azure-cli.withExtensions [
          pkgs.azure-cli-extensions.log-analytics
          pkgs.azure-cli-extensions.application-insights
        ];

        bicepVersion = "0.47.16";
        bicepCliAsset = {
          x86_64-linux = {
            name = "bicep-linux-x64";
            hash = "sha256-ZMNFpY4MPkixvJik5i1rOtsdI4KBKX3jQArq+yaXqlo=";
          };
          aarch64-linux = {
            name = "bicep-linux-arm64";
            hash = "sha256-RAYhTMJ0z6x8ghVSrsIXi4CuxjfZHtiyRCgpZMHPJOM=";
          };
          x86_64-darwin = {
            name = "bicep-osx-x64";
            hash = "sha256-i6V3G1JhQT2IWDgp8uokUJ62WwbYmWIMFyg+y2DVynM=";
          };
          aarch64-darwin = {
            name = "bicep-osx-arm64";
            hash = "sha256-aARqCEyIUDz2vRHazyocT/y346ycazENKV4CSvIbvqQ=";
          };
        }.${system};

        bicep-cli-unwrapped = pkgs.stdenvNoCC.mkDerivation {
          pname = "bicep-cli";
          version = bicepVersion;

          src = pkgs.fetchurl {
            url = "https://github.com/Azure/bicep/releases/download/v${bicepVersion}/${bicepCliAsset.name}";
            hash = bicepCliAsset.hash;
          };

          dontUnpack = true;
          installPhase = ''
            install -Dm755 $src $out/bin/bicep
          '';
        };

        bicep-cli =
          if pkgs.stdenv.hostPlatform.isLinux
          then pkgs.buildFHSEnv {
            name = "bicep";
            targetPkgs = pkgs: [
              pkgs.icu
              pkgs.openssl
              pkgs.stdenv.cc.cc.lib
              pkgs.zlib
            ];
            runScript = "${bicep-cli-unwrapped}/bin/bicep";
          }
          else bicep-cli-unwrapped;

        bicep-langserver = pkgs.stdenv.mkDerivation rec {
          pname = "bicep-langserver";
          version = bicepVersion;

          src = pkgs.fetchurl {
            url = "https://github.com/Azure/bicep/releases/download/v${version}/bicep-langserver.zip";
            hash = "sha256-Ep0+N6pmjcsaSY7kBSi6WfU1JYodOrDODfKCVodGvoA=";
          };

          dontUnpack = true;
          nativeBuildInputs = [
            pkgs.makeWrapper
            pkgs.unzip
          ];

          installPhase = ''
            mkdir -p $out/lib/bicep-langserver
            unzip $src -d $out/lib/bicep-langserver
            makeWrapper \
              ${pkgs.dotnetCorePackages.runtime_10_0}/bin/dotnet \
              $out/bin/bicep-langserver \
              --add-flags "$out/lib/bicep-langserver/Bicep.LangServer.dll"
          '';
        };

        bicep = pkgs.symlinkJoin {
          name = "bicep-${bicepVersion}";
          paths = [
            bicep-cli
            bicep-langserver
          ];
        };

        playwrightBrowsers =
          let
            driver = pkgs.playwright-driver;
            components = driver.components // {
              webkit =
                if pkgs.stdenv.hostPlatform.isLinux
                then driver.components.webkit.overrideAttrs (previousAttrs: {
                  buildInputs = (previousAttrs.buildInputs or [ ]) ++ [
                    pkgs.libmanette
                  ];
                })
                else driver.components.webkit;
            };
            browserNames = [
              "chromium"
              "chromium-headless-shell"
              "firefox"
              "webkit"
              "ffmpeg"
            ];
          in
          pkgs.linkFarm "playwright-browsers" (
            map
              (name: {
                name = "${pkgs.lib.replaceStrings [ "-" ] [ "_" ] name}-${driver.browsersJSON.${name}.revision}";
                path = components.${name};
              })
              browserNames
          );
      in
      {
        packages.bicep = bicep;

        packages.dotnetSdks =
          # combinePackages uses symlinkJoin, so the SDK directories (e.g.
          # share/dotnet/sdk/10.0.202) are symlinks back to each per-SDK store.
          # When MSBuild loads its task assembly, .NET resolves the path through
          # those symlinks and computes the dotnet host from the resolved
          # location — landing in the per-SDK store, which only contains its own
          # runtime. That breaks `dotnet test` whenever a project targets a
          # framework version different from the active SDK's. We dereference
          # all symlinks here so every file lives in this single store path,
          # alongside a shared/ tree containing all runtimes.
          let
            combined = with pkgs.dotnetCorePackages;
              combinePackages [
                sdk_10_0-bin
                dotnet_9.sdk
                dotnet_8.sdk
              ];
          in
          pkgs.runCommand "dotnetSdks" { } ''
            mkdir -p $out
            cp -RL ${combined}/. $out/
            chmod -R u+w $out
          '';

        devShells.default = pkgs.mkShell {
          buildInputs =
            let
              common = [
                # neovim
                pkgs.neovim
                pkgs.tree-sitter
                pkgs.fzf
                pkgs.lua-language-server
                pkgs.stylua
                pkgs.vscode-langservers-extracted
                pkgs.roslyn-ls
                pkgs.prettier
                pkgs.powershell-editor-services

                # vscode
                pkgs.vscode

                pkgs.yarn

                pkgs.bottom

                # dotnet
                self.packages.${system}.dotnetSdks
                pkgs-stable.csharpier
                pkgs.azure-functions-core-tools

                pkgs.redis

                # azure
                azureCli
                pkgs.powershell
                pkgs.azure-storage-azcopy
                bicep
                azure-pipelines.packages.${system}.azure-pipelines-language-server
                pkgs.azurite

                # git
		pkgs.git
                pkgs.lazygit
                pkgs.git-credential-manager
                pkgs.gh

                # shell
                pkgs.bashInteractive
                pkgs.fish
                pkgs.fd
                pkgs.ripgrep
                pkgs.zellij
                pkgs.eza
                pkgs.starship
                pkgs.yazi

                # rust
                rustToolchain
                rustAnalyzer
                pkgs.openssl

                # python
                pkgs.uv
                pkgs.pyright
                pkgs.ruff

                # javascript
                pkgs.nodejs

                # Chrome
                pkgs.google-chrome
                pkgs.chromedriver

                # Playwright
                playwrightBrowsers
              ];

              linuxOnly = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
                # ASP.NET Core dev-certs browser trust
                pkgs.nssTools

                # Niri
                pkgs.xwayland-satellite
                pkgs.waybar-mpris
              ];

              darwinOnly = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
                # macOS‑specific packages go here (currently none)
              ];
            in
              common ++ linuxOnly ++ darwinOnly;

          shellHook = ''
            # Expose common shared libs so pip/uv-installed Python wheels
            # (numpy, pandas, etc.) can find libstdc++ and friends at runtime.
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [
              pkgs.stdenv.cc.cc.lib
              pkgs.zlib
            ]}:$LD_LIBRARY_PATH"

            export PLAYWRIGHT_BROWSERS_PATH="${playwrightBrowsers}"
            export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true;

            export AZURE_BICEP_USE_BINARY_FROM_PATH=true

            export DOTNET_ROOT="${self.packages.${system}.dotnetSdks}/share/dotnet"
            export DOTNET_ROOT_X64="$DOTNET_ROOT"
            export PATH="$DOTNET_ROOT:$PATH"
            unset SSL_CERT_DIR
            export NIX_SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            export SSL_CERT_FILE="$NIX_SSL_CERT_FILE"
            if compgen -G "$HOME/.aspnet/dev-certs/trust/*.pem" > /dev/null; then
              export SSL_CERT_FILE="$HOME/.aspnet/dev-certs/trust/ca-bundle-with-aspnet-dev-certs.crt"
              cat "$NIX_SSL_CERT_FILE" "$HOME"/.aspnet/dev-certs/trust/*.pem > "$SSL_CERT_FILE"
            fi

            export EDITOR=nvim
	    export SHELL=fish

            case "$(uname)" in
                Darwin*)
                  ;;
                *)
                  export GCM_CREDENTIAL_STORE=secretservice
                  git config --global credential.credentialStore secretservice
                  ;;
              esac
              git config --global credential.helper \
                  "${pkgs.git-credential-manager}/bin/git-credential-manager"

            zellij
          '';
        };
      }
    );
}
