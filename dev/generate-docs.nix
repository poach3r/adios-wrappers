/*
  nix eval -f dev/generate-docs.nix --json --offline \
  | jq \
  | rg -N --color=never --passthru '^  },$' -r "  },"\n \
  | rg -N --color=never --passthru '(\\\n)"' -r '"' \
  | rg --passthru --color=never -N '(\\\n)+' -r " " \
  > docs/options.json
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
