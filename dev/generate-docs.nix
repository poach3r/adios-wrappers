/*
  nix-instantiate --eval --strict --quiet --json dev/generate-docs.nix \
    | jq \
    | sed 's/^  },$/  },\n/' \
    | sed 's/\\n"/"/' \
    | sed -r 's/(\\n)+/ /g'
*/
let
  inherit (builtins) mapAttrs getFlake;
  optionalAttrs = cond: attrs: if cond then attrs else {};
in
  mapAttrs (
    _: wrapper:
    mapAttrs (
      _: option:
      (removeAttrs option [
        "defaultFunc"
        "mergeFunc"
      ])
      // {
        type = option.type.name;
      } // optionalAttrs (option ? mutatorType) {
        mutatorType = option.mutatorType.name;
      }
    ) wrapper.options
  ) (getFlake (toString ../.)).wrapperModules
