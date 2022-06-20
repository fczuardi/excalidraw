{
  description = "Sketch handrawn like diagrams.";
  nixConfig.bash-prompt = "\[nix develop\]$ ";
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-22.05;
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, flake-utils }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      formatter = pkgs.nixpkgs-fmt;
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          nodejs
          yarn
        ];
      };

      # see https://nixos.org/manual/nixpkgs/stable/#language-javascript
      packages.default = pkgs.mkYarnPackage {
        src = ./.;

        # HACK: the package.lock from upstream didnt have a version field
        # I have manually added one

        # HACK: the package.lock from upstream uses the "resolutions" field
        # we need to manually update the yarn.lock file to use the version on all instances
        # otherwise tht following error occurs:
        #
        # Error: Couldn't find any versions for "@typescript-eslint/typescript-estree" that
        # matches "3.10.1" in our cache (possible versions are ""). This is usually caused by a 
        # missing entry in the lockfile, running Yarn without the --offline flag may help fix this issue.
        #
        # this error was reported on the old yarn2nix repository:
        # https://github.com/nix-community/yarn2nix/issues/136

        # HACK: the dependency that is listed on the "resolutios" was also a devdependency
        # I have changed the version of this dependency manually on package.json as well

        # HACK: to prevent permission denied error on the yarn build phase:
        # EACCES: permission denied, mkdir '/build/nrcrf46hp7cwmvm8qs2in2wrwg9cn1sw-source/deps/excalidraw/node_modules/.cache'
        configurePhase = ''
          cp -r $node_modules node_modules
          chmod -R +w node_modules
        '';
        buildPhase = ''
          yarn --offline build:app
          mv build $out
        '';
        # skip those phases
        installPhase = "true";
        fixupPhase = "true";
        distPhase = "true";
      };
    });
}
