{ types, ... } @ adios:
{
  name = "zsh";

  inputs = {
    mkWrapper.path = "/mkWrapper";
    nixpkgs.path = "/nixpkgs";
  };

  options = {
    zshrc = {
      type = types.string;
      description = ''
        zsh script to be injected into the wrapped package's `.zshrc`.
      '';
      mutatorType = types.listOf types.pathLike;
      mergeFunc = adios.lib.merge.lists.concat;
    };

    extraZshrc = {
      type = types.string;
      description = ''
        zsh script to be injected after the `zshrcFiles` option in the wrapped 
        package's `.zshrc`.
      '';
      mutatorType = types.listOf types.pathLike;
      mergeFunc = adios.lib.merge.lists.concat;
    };

    zshrcFiles = {
      type = types.listOf types.pathLike;
      description = ''
        zsh files to be sourced after the `zshrc` option in the wrapped package's `.zshrc` file.
      '';
      mutatorType = types.listOf types.pathLike;
      mergeFunc = adios.lib.merge.lists.concat;
    };

    extraZshrcFiles = {
      type = types.listOf types.pathLike;
      description = ''
        zsh files to be sourced at the end of the wrapped package's `.zshrc` file.
      '';
      mutatorType = types.listOf types.pathLike;
      mergeFunc = adios.lib.merge.lists.concat;
    };

    settings = {
      type = types.attrsOf types.bool;
      description = "";
    };

    variables = {
      type = types.attrs;
      description = ''
        Variables to be defined in the wrapped package's `.zshrc` file.
      '';
    };

    aliases = {
      type = types.attrsOf (
        types.union [
          types.string
          (types.struct "global alias" {
            global = types.bool;
            command = types.string;
          })
        ]
      );
      description = "";
    };

    plugins = {
      type = types.listOf (
        types.union [
          types.derivation
          (types.struct "plugin" {
            package = types.derivation;
            path = types.string;
          })
        ]
      );
      description = ''
        Plugins to be appended to the wrapped package's `.zshrc`.

        If a value is a derivation, it will be sourced as 
        `<derivation>/share/<derivation.pname>/<derivation.pname>.zsh` which
        should be compatible with the majority of plugins. If this path is 
        incorrect then the value may be defined as an attrSet containing the 
        attrs `package` and `path` and will be sourced as `<package>/<path>`.
      '';
      example =
        { pkgs }:
        {
          plugins = [
            pkgs.zsh-autosuggestions
            pkgs.zsh-syntax-highlighting
            pkgs.zsh-vi-mode
            {
              package = pkgs.zsh-fzf-tab;
              path = "share/fzf-tab/fzf-tab.plugin.zsh";
            }
            {
              package = pkgs.nix-zsh-completions;
              path = "share/zsh/plugins/nix/nix-zsh-completions.plugin.zsh";
            }
          ];
        };
      mutatorType = types.listOf types.pathLike;
      mergeFunc = adios.lib.merge.lists.concat;
    };

    extraPackages = {
      type = types.listOf types.derivation;
      description = ''
        Runtime dependencies to be injected into the wrapped package's path.
      '';
      mutatorType = types.listOf types.pathLike;
      mergeFunc = adios.lib.merge.lists.concat;
    };

    package = {
      type = types.derivation;
      defaultFunc = { inputs }: inputs.nixpkgs.pkgs.zsh;
      description = "The zsh package to be wrapped.";
    };
  };

  impl =
    { options, inputs }:
    let
      inherit (inputs.nixpkgs.pkgs) writeText;
      inherit (inputs.nixpkgs.lib) makeBinPath getExe;
      inherit (builtins) concatStringsSep attrValues mapAttrs;
      # Concatenates a list of strings so they're formatted properly for the .zshrc
      concat = elems: (concatStringsSep "\n" elems) + "\n\n";
      # Whether a .zshrc should be generated
      shouldConfigure =
        options ? zshrc
        || options ? zshrcFile
        || options ? plugins
        || options ? settings
        || options ? aliases
        || options ? variables;
      # Generates zsh sourcing all the files in a list
      sourceFiles = files: concat (map (file: "source ${file}") files);
      zshrc =
        let
          zshrcFiles = if options ? zshrcFiles then sourceFiles "${options.zshrcFiles}\n" else "";
          extraZshrcFiles = if options ? extraZshrcFiles then "${options.extraZshrcFiles}\n" else "";
          zshrcText = if options ? zshrc then "${options.zshrc}\n" else "";
          extraZshrcText = if options ? extraZshrc then "${options.extraZshrc}\n" else "";
          settings =
            if options ? settings then
              concat (
                attrValues (mapAttrs (name: value: "${if value then "" else "un"}setopt ${name}") options.settings)
              )
            else
              "";
          variables =
            if options ? variables then
              concat (attrValues (mapAttrs (name: value: "${name}=${toString value}") options.variables))
            else
              "";
          aliases =
            if options ? aliases then
              concat (
                attrValues (
                  mapAttrs (
                    name: value:
                    if value ? global then "alias -g ${name}='${value.command}'" else "alias ${name}='${value}'"
                  ) options.aliases
                )
              )
            else
              "";
          plugins =
            if options ? plugins then
              sourceFiles (
                map (
                  plugin:
                  if plugin ? path then
                    "${plugin.package}/${plugin.path}"
                  else
                    "${plugin}/share/${plugin.pname}/${plugin.pname}.zsh"
                ) options.plugins
              )
            else
              "";
        in
        zshrcFiles
        + zshrcText
        + variables
        + aliases
        + settings
        + extraZshrcFiles
        + extraZshrcText
        + plugins;
    in
    inputs.mkWrapper {
      inherit (options) package;
      wrapperArgs =
        if options ? extraPackages then "--prefix PATH : ${makeBinPath options.extraPackages}" else null;
      symlinks = {
        "$out/.zshrc" = if shouldConfigure then writeText ".zshrc" zshrc else null;
      };
      environment = {
        ZDOTDIR = if shouldConfigure then "$out" else null;
      };
    };
}
