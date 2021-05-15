{
  description = "Nix files made to ease imperative installation of matlab";

  # https://nixos.wiki/wiki/Flakes#Using_flakes_project_from_a_legacy_Nix
  inputs.flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;
  };

  outputs = { self, nixpkgs, flake-compat }: 
  let
    # We don't use flake-utils.lib.eachDefaultSystem since only x86_64-linux is
    # supported
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    targetPkgs = import ./common.nix;
    # TODO: Make it possible to override this - imperatively or declaratively?
    defaultRunPath = "$HOME/downloads/software/matlab/installation";
    runScriptPrefix = ''
      #!${pkgs.bash}/bin/bash
      # Needed for simulink even on wayland systems
      export QT_QPA_PLATFORM=xcb
    '';
  in {

    packages.x86_64-linux.matlab = pkgs.buildFHSUserEnv {
      name = "matlab";
      inherit targetPkgs;
      runScript = runScriptPrefix + ''
        exec ${defaultRunPath}/bin/matlab "$@"
      '';
    };
    packages.x86_64-linux.matlab-shell = pkgs.buildFHSUserEnv {
      name = "matlab-shell";
      inherit targetPkgs;
    };
    packages.x86_64-linux.mlint = pkgs.buildFHSUserEnv {
      name = "mlint";
      inherit targetPkgs;
      runScript = runScriptPrefix + ''
        exec ${defaultRunPath}/bin/glnxa64/mlint "$@"
      '';
    };
    overlay = final: prev: {
      inherit (self.packages.x86_64-linux) matlab matlab-shell mlint;
    };
    devShell.x86_64-linux = pkgs.mkShell {
      buildInputs = (targetPkgs pkgs) ++ [
        self.packages.x86_64-linux.matlab-shell
      ];
      # From some reason using the attribute matlab-shell directly as the
      # devShell doesn't make it run like that by default.
      shellHook = ''
        exec matlab-shell
      '';
    };

    defaultPackage.x86_64-linux = self.packages.x86_64-linux.matlab;

  };
}
