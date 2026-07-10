{
  inputs = {
    utils.url = "github:numtide/flake-utils";

    self.submodules = true; # flakes don't copy submodles by default so we need this
  };
  outputs =
    {
      self,
      nixpkgs,
      utils,
    }:
    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        SERESettings = {
          "RuiWidth" = 1920;
          "RuiHeight" = 1080;
          "GamePath" = "/mnt/x/Games/EA/Titanfall2/";
          "CustomRpakPath" = "";
        };
      in
      {
        formatter = pkgs.nixfmt-tree;

        packages = {
          sere = pkgs.llvmPackages.stdenv.mkDerivation rec {
            name = "SERE";

            src = ./.;

            nativeBuildInputs = with pkgs; [
              ninja
              pkg-config
              cmake
              makeWrapper
              patchelf
            ];

            buildInputs = with pkgs; [
              gtk3
              imgui
              sdl3
              sdl3-image
              libGL
              libxkbcommon
              libx11
              libxcursor
              libxi
              libxrandr
              wayland
              libGLU
              libGLX
              libxext.out
              tbb
            ];

            runtimeDependencies = with pkgs; [
              wayland
              libxkbcommon
              libx11
              libxcursor
              libxi
              libxrandr
              wayland
              libGLU
              libGLX
              libxext.out
            ];

            configurePhase = ''
              mkdir -p build
              cmake . -G "Ninja" -B build -DSDL_X11_XSCRNSAVER=OFF -DSDL_X11_XTEST=OFF
            '';

            buildPhase = ''
              mkdir -p build
              cmake --build build -j24
            '';

            installPhase = ''
              runHook preInstall

              mkdir -p $out/bin
              cp -r build/SERE/* $out/bin

              runHook postInstall
            '';

            postInstall = ''
              patchelf $out/bin/SERE --add-rpath ${pkgs.tbb}/lib
              wrapProgram $out/bin/SERE --set LD_LIBRARY_PATH ${nixpkgs.lib.makeLibraryPath runtimeDependencies}
              cp ${pkgs.writers.writeJSON "settings.json" SERESettings} $out/bin/settings.json
            '';

          };

          default = self.packages.${system}.sere;
        };

        devShell =
          pkgs.mkShell.override
            {
              stdenv = pkgs.clangStdenv;
            }
            {
              inherit (self.packages.${system}.sere) buildInputs;

              nativeBuildInputs = with pkgs; [
                lldb
                (if system == "x86_64-darwin" || system == "aarch64-darwin" then null else valgrind)
                include-what-you-use
                ccache
              ] ++ self.packages.${system}.sere.nativeBuildInputs;


              LD_LIBRARY_PATH = nixpkgs.lib.makeLibraryPath self.packages.${system}.sere.runtimeDependencies;

              shellHook = ''
                export CC="ccache clang"
                export CXX="ccache clang++"

                cp -f ${pkgs.writeText ".clangd" ''
                  CompileFlags:
                    CompilationDatabase: "build"
                ''} .clangd
              '';
            };
      }
    );
}
