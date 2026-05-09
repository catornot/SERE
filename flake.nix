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
        dxvk-native = pkgs.stdenv.mkDerivation (finalAttrs: {
          pname = "dxvk-native";
          version = "2.7.1";

          src = fetchTarball {
            url = "https://github.com/doitsujin/dxvk/releases/download/v${finalAttrs.version}/dxvk-native-${finalAttrs.version}-steamrt-sniper.tar.gz";
            sha256 = "sha256:0y7fg1pggychscgmw5j7vw1sckl8z2sz2vb1x4jgnj4sknqdmnmw";
          };

          installPhase = ''
            mkdir -p $out
            cp -r * $out/
            mv $out/include/dxvk/* $out/include
            rmdir $out/include/dxvk
          '';
        });
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
                dxvk-native
                pkgs.nativefiledialog-extended
                pkgs.gtk3
                pkgs.imgui
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
