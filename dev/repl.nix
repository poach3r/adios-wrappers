# This is for repl development only - ignore as a user
#
# If you're trying to add a module and want to test it, use this command when
# entering the repl:
#
# nix repl --expr '{ wrappers = import ./dev/repl.nix; }'
let
  flake = builtins.getFlake (toString ../.);
  sources = import ./npins;
  inherit (flake) inputs outputs;
  pkgs = import sources.nixpkgs {};
  adios = inputs.adios.adios;

  root = {
    modules = outputs.wrapperModules;
  };

  tree = adios root {
    options = {
      "/nixpkgs" = { inherit pkgs; };
    };
  };
in
tree.modules
