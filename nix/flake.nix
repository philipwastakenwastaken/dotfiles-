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

    bicep.url                 = "github:sofusa/bicep-language-server-nix";
    azure-pipelines.url       = "github:sofusa/azure-pipelines-language-server-nix";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    flake-utils,
    fenix,
    lazytest,
    bicep,
    azure-pipelines,
    neovim
  }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs        = import nixpkgs        { inherit system; config.allowUnfree = true; };
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
      in
      {
        packages.dotnetSdks = pkgs.buildEnv {
          name  = "dotnetSdks";
          paths = [
            (with pkgs-stable.dotnetCorePackages;
              combinePackages [
                dotnet_8.sdk
                dotnet_8.aspnetcore
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
                bicep.packages.${system}.bicep-langserver
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

            export DOTNET_ROOT="${pkgs-stable.dotnetCorePackages.dotnet_9.sdk}";

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
