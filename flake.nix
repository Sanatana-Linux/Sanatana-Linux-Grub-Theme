{
  description = "Flake to manage Bhairava Grub Theme for the Sanatana Linux.";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    with nixpkgs.lib;
    {
      nixosModule = { config, ... }:
        let
          cfg = config.boot.loader.grub.bhairava-grub-theme;

          bhairava-grub-theme = pkgs.stdenv.mkDerivation {
            name = "bhairava-grub-grub-theme";
            src = ./.;
            installPhase = ''
              mkdir -p $out/grub/theme/icons
              cp -rf backgrounds/bg.png $out/grub/theme/bg.png
              cp -rf assets/assets/1080p/* $out/grub/theme/
              cp -rf assets/logos/1080p/* $out/grub/theme/icons/ 
              cp -rf common/* $out/grub/theme/
              cp -rf config/theme-1080p.txt $out/grub/theme/theme.txt
            '';
          };
        in
        {
          options = {
            boot.loader.grub.bhairava-grub-theme = {
              enable = mkOption {
                type = types.bool;
                default = false;
                example = true;
                description = ''
                  Enable the Bhairava Grub Theme  
                '';
              };
            };
          };

          config = mkIf cfg.enable (mkMerge [{
            environment.systemPackages = [ bhairava-grub-theme ];
            boot.loader.grub = {
              theme = "${bhairava-grub-theme}/grub/theme";
            };
          }]);
        };
    };
}

