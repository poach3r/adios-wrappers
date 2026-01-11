I'll go over npins-specific instructions here. Any other source pinning tool should work the same.

First, add the relevant sources to your lockfile:

```
npins init # Only if you don't already have an `npins/` folder
npins add github llakala adios -b providers-and-consumers
npins add github llakala adios-wrappers -b main
```

Now, create a file under `wrappers/default.nix`, containing these contents:

```nix
{
  sources ? import ../npins,
  pkgs ? import sources.nixpkgs {},
}:
let
  inherit (pkgs) lib;
  adios = import "${sources.adios}/adios";
  adios-wrappers = import sources.adios-wrappers { adios = sources.adios; };

  root = {
    name = "root";
    modules = lib.recursiveUpdate adios-wrappers (adios.lib.importModules ./.);
  };

  tree = (adios root).eval {
    options = {
      "/nixpkgs" = {
        inherit pkgs;
      };
    };
  };
in
tree.root.modules
```

Finally, create a `shell.nix` (if you don't have one already), and load your wrapped programs. This will allow iterating
your wrappers without a full system rebuild. For example:

```nix
{
  sources ? import ./npins,
  pkgs ? import sources.nixpkgs {},
  wrappers ? import ./wrappers { inherit sources pkgs; },
}:

pkgs.mkShellNoCC {
  allowSubstitutes = false; # Prevent a cache.nixos.org call every time
  packages = [
    (wrappers.foo {})
    (wrappers.bar {})
    (wrappers.baz {})
  ];
}
```
