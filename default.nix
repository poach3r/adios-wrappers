{ sprinkles ? null }:

let
  sources = import ./npins;
  inputs = sources: {
    sprinkles = if sprinkles == null then import sources.sprinkles else sprinkles;
    adios = (import sources.adios).adios;
  };
in
(inputs sources).sprinkles.new {
  inherit inputs sources;
  outputs =
    self:
    let

      inherit (inputs.nixpkgs) pkgs;
    in {
      wrapperModules = self.inputs.adios.lib.importModules ./modules;

      packages = {
        nixfmt = pkgs.callPackage ./dev/nixfmt.nix {};
      };

      shells.default = pkgs.mkShell {
        packages = [
          self.output.packages.nixfmt
          pkgs.nixd
          pkgs.jq
          pkgs.npins
        ];
      };
    };
}
