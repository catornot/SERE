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
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        formatter = pkgs.nixfmt-tree;

        devShell =
          pkgs.mkShell.override
            {
              stdenv = pkgs.clangStdenv;
            }
            {
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
              ];

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
