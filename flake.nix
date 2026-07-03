{
  inputs = {
    utils.url = "github:numtide/flake-utils";
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
      in
      {
        formatter = pkgs.nixfmt-tree;

        devShell =
          pkgs.mkShell.override
            {
              stdenv = pkgs.clangStdenv;
            }
            rec {
              packages = with pkgs; [
                ninja
                clang-tools
                lldb
                (if system == "x86_64-darwin" || system == "aarch64-darwin" then null else valgrind)
                include-what-you-use
                ccache
                pkg-config
                cmake
              ];

              buildInputs = [
                pkgs.gtk3
                pkgs.imgui
                pkgs.sdl3
                pkgs.sdl3-image
                pkgs.libGL
                pkgs.libxkbcommon
                pkgs.libx11
                pkgs.libxcursor
                pkgs.libxi
                pkgs.libxrandr
                pkgs.wayland
                pkgs.libGLU
                pkgs.libGLX
                pkgs.libxext.out
              ];

              LD_LIBRARY_PATH = nixpkgs.lib.makeLibraryPath buildInputs;

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
