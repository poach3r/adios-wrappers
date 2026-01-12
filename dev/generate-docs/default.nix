/*
  Usage:
  nix run -f dev/generate-docs > docs/options.json
*/
let
  flake = builtins.getFlake (toString ../../.);
  pkgs = import flake.inputs.nixpkgs {};
in
pkgs.writeShellApplication {
  name = "generate-docs";
  runtimeInputs = [ pkgs.jq ];
  text = ''
    nix-instantiate --eval --strict --quiet --json dev/generate-docs/get-docs.nix \
      | jq \
      | sed 's/^  },$/  },\n/' \
      | sed 's/\\n"/"/' \
      | sed -r 's/(\\n)+/ /g'
  '';
}
