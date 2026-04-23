{
  description = "flake for development environment";

  inputs = {
    nixpkgs.url          = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url   = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url      = "github:numtide/flake-utils";
    neovim.url           = "github:nix-community/neovim-nightly-overlay";
    fenix.url            = "github:nix-community/fenix";
    lazytest = {
      url = "github:philipwastakenwastaken/lazytest";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.fenix.follows = "fenix";
    };

    azure-pipelines.url       = "github:sofusa/azure-pipelines-language-server-nix";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    flake-utils,
    fenix,
    lazytest,
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

        bicep-langserver = pkgs.stdenv.mkDerivation rec {
          pname = "bicep-langserver";
          version = "0.42.1";

          src = pkgs.fetchzip {
            url = "https://github.com/Azure/bicep/releases/download/v${version}/bicep-langserver.zip";
            sha256 = "1fmxjy25x9zh39z5983sm0bgssk1p7gljwprshjnr8lxqg5pam6k";
            stripRoot = false;
          };

          installPhase = ''
            mkdir -p $out/bin
            cp -r $src $out/bin/Bicep.LangServer/

            cat <<EOF > $out/bin/bicep-langserver
            #!/usr/bin/env bash
            exec dotnet $out/bin/Bicep.LangServer/Bicep.LangServer.dll "\$@"
            EOF

            chmod +x $out/bin/bicep-langserver
          '';
        };
      in
      {
        packages.dotnetSdks = pkgs.buildEnv {
          name  = "dotnetSdks";
          paths = [
            (with pkgs.dotnetCorePackages;
              combinePackages [
                sdk_10_0-bin
                dotnet_9.sdk
                dotnet_8.sdk
              ])
          ];
        };

        packages.lazytest = lazytest.packages.${system}.default;

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

                # dotnet
                self.packages.${system}.dotnetSdks
                self.packages.${system}.lazytest
                pkgs-stable.csharpier
                pkgs.azure-functions-core-tools

                # azure
                pkgs.azure-cli
                pkgs.powershell
                pkgs.azure-storage-azcopy
                bicep-langserver
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
                pkgs.playwright-driver.browsers
              ];

              linuxOnly = pkgs.lib.optionals pkgs.stdenv.isLinux [
                # Niri
                pkgs.xwayland-satellite
                pkgs.waybar-mpris
              ];

              darwinOnly = pkgs.lib.optionals pkgs.stdenv.isDarwin [
                # macOS‑specific packages go here (currently none)
              ];
            in
              common ++ linuxOnly ++ darwinOnly;

          shellHook = ''
            export PLAYWRIGHT_BROWSERS_PATH="${pkgs.playwright-driver.browsers}"
            export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true;

            export DOTNET_ROOT="${self.packages.${system}.dotnetSdks}/share/dotnet"
            export DOTNET_ROOT_X64="$DOTNET_ROOT"
            export PATH="$DOTNET_ROOT:$PATH"

            export EDITOR=nvim
	    export SHELL=fish

            case "$(uname)" in
                Darwin*)
                  ;;
                *)
                  # Linux (and everything else): keep Git‑Credential‑Manager
                  export GCM_CREDENTIAL_STORE=secretservice
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
