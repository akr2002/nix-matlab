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
    # TODO: This doesn't work - matlab is unusable
    runScriptPrefix = ''
      #!${pkgs.bash}/bin/bash
      export MATLAB_JAVA=/usr/lib/openjdk
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
    };

    defaultPackage.x86_64-linux = self.packages.x86_64-linux.matlab;

  };
}
