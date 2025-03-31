{
  description = "flake for development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
    neovim.url = "github:nix-community/neovim-nightly-overlay";

    bicep.url = "github:sofusa/bicep-language-server-nix";
    azure-pipelines.url = "github:sofusa/azure-pipelines-language-server-nix";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    flake-utils,
    bicep,
    azure-pipelines,
    neovim
  }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
        pkgs-stable = import nixpkgs-stable { inherit system; config.allowUnfree = true; };
      in
      {
        packages.dotnetSdks = pkgs.buildEnv {
          name = "dotnetSdks";
          paths = [
            (with pkgs-stable.dotnetCorePackages;
            combinePackages [
              dotnet_9.sdk
              dotnet_9.aspnetcore
              dotnet_8.sdk
              dotnet_8.aspnetcore
            ])
          ];
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [ 
            # neovim
            pkgs.neovim 
            pkgs.fzf

            # vscode
            pkgs.vscode

            # dotnet
            self.packages.${system}.dotnetSdks
            pkgs-stable.csharpier
            pkgs.azure-functions-core-tools

            # azure
            pkgs-stable.azure-cli
            pkgs-stable.powershell
            bicep.packages.${system}.bicep-langserver
            azure-pipelines.packages.${system}.azure-pipelines-language-server

            # git
            pkgs.lazygit
            pkgs.git-credential-manager

            # shell
            pkgs.fish
            pkgs.fd
            pkgs.ripgrep
            pkgs.zellij
            pkgs.eza
            pkgs.starship
            pkgs.yazi
        
            # javascript
            pkgs.nodePackages.npm
            pkgs.nodePackages.nodejs

            # vscode
            pkgs.vscode

            # Chrome
            pkgs.google-chrome
            pkgs.chromedriver

            # Playwright
            pkgs.playwright-driver.browsers
	  ];

          shellHook =
            ''
              export PLAYWRIGHT_BROWSERS_PATH="${pkgs.playwright-driver.browsers}"
              export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true;

              export DOTNET_ROOT="${pkgs-stable.dotnetCorePackages.dotnet_9.sdk}";

              export EDITOR=nvim

              export GCM_CREDENTIAL_STORE=secretservice
              git config --global credential.helper "${pkgs.git-credential-manager}/bin/git-credential-manager"

              # Azure DevOps fix
              git config --global credential.useHttpPath true

              zellij
            '';
        };
      }
  );
}
