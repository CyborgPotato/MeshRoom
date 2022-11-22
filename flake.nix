{
  description = "A basic flake with a shell";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      geogram = pkgs.stdenv.mkDerivation rec {
        pname = "geogram";
        version = "1.7.7";
        src = pkgs.fetchFromGitHub {
          owner = pname;
          repo = "geogram";
          rev = "v${version}";
          deepClone = true;
          fetchSubmodules = true;
          sha256 = "WQhCt/tMsgtAOmv4oVQ7irutOd5sIdSPYdIw6WKr4mg=";
        };
        nativeBuildInputs = with pkgs; [
          cmake
        ];
        buildInputs = with pkgs; [
          xorg.libX11
          xorg.libXrandr
          xorg.libXinerama
          xorg.libXcursor
          xorg.libXi
          xorg.libXxf86vm
          libGL
          libGLU
        ];
        preConfigure = ''
          chmod +x ./configure.sh
          ./configure.sh
          cd build
          cd Linux*Release
        '';
        preBuild = ''
          cd ..
        '';
      };
      coin-utils = pkgs.stdenv.mkDerivation rec {
        pname = "coin-utils";
        version = "2.11.6";
        src = pkgs.fetchFromGitHub {
          owner = "coin-or";
          repo = pname;
          rev = "releases/${version}";
          sha256 = "avXp7eKSZ/Fe1QmSJiNDMnPQ70LlOHrBeUYb9lhka8c=";
        };
      };
      coin-osi = pkgs.stdenv.mkDerivation rec {
        pname = "coin-osi";
        version = "0.108.7";
        src = pkgs.fetchFromGitHub {
          owner = "coin-or";
          repo = "osi";
          rev = "releases/${version}";
          sha256 = "MTmt/MgsfEAXor2EZXJX05bQg5oOtMaN7oNxGv2PHJg=";
        };
        nativeBuildInputs = with pkgs; [
          pkg-config
        ];
        buildInputs = with pkgs; [
          coin-utils
        ];
      };
      coin-clp = pkgs.stdenv.mkDerivation rec {
        pname = "coin-clp";
        version = "1.17.7";
        src = pkgs.fetchFromGitHub {
          owner = "coin-or";
          repo = "clp";
          rev = "releases/${version}";
          sha256 = "CfAK/UbGaWvyk2ZxKEgziVruzZfz7WMJVi/YvdR/UNA=";
        };
        nativeBuildInputs = with pkgs; [
          pkg-config
          libtool
        ];
        buildInputs = with pkgs; [
          coin-utils
          coin-osi
        ];
      };
      coin-cgl = pkgs.stdenv.mkDerivation rec {
        pname = "coin-cgl";
        version = "0.60.6";
        src = pkgs.fetchFromGitHub {
          owner = "coin-or";
          repo = "cgl";
          rev = "releases/${version}";
          sha256 = "e+CNAqWszOk6XjKvlY/AoHowkraFvJISyKKUHVM+60s=";
        };
        nativeBuildInputs = with pkgs; [
          pkg-config
          libtool
          gfortran
        ];
        buildInputs = with pkgs; [
          coin-utils
          coin-osi
          coin-clp
        ];
      };
      coin-cbc = pkgs.stdenv.mkDerivation rec {
        pname = "coin-cbc";
        version = "2.10.8";
        src = pkgs.fetchFromGitHub {
          owner = "coin-or";
          repo = "cbc";
          rev = "releases/${version}";
          sha256 = "3WjgjZataRb7QPQPo2LJGNehflw0/dXquCwnGPG0z4Y=";
        };
        nativeBuildInputs = with pkgs; [
          pkg-config
          libtool
        ];
        buildInputs = with pkgs; [
          coin-utils
          coin-osi
          coin-cgl
          coin-clp
        ];
      };
      coin-vol = pkgs.stdenv.mkDerivation rec {
        pname = "coin-vol";
        version = "1.5.4";
        src = pkgs.fetchFromGitHub {
          owner = "coin-or";
          repo = "vol";
          rev = "releases/${version}";
          sha256 = "pioQed4+6xN7o2XOSsI5VgvYIxTELG16snuyfi7mT+0=";
        };
        nativeBuildInputs = with pkgs; [
          pkg-config
          libtool
        ];
        buildInputs = with pkgs; [
          coin-utils
          coin-osi
        ];
      };
      alicevision = pkgs.stdenv.mkDerivation rec {
        pname = "alicevision";
        version = "672fb43cea53bbf07b262f0e3ee618c62aec2f9b";
        src = pkgs.fetchFromGitHub {
          owner = pname;
          repo = pname;
          rev = version;
          deepClone = true;
          fetchSubmodules = true;
          sha256 = "DDvHpqSIt6fbH1tufP21iVxtJl6CNE1ppZ2KMDn4t8c=";
        };
        nativeBuildInputs = with pkgs; [
          cmake
          pkg-config
        ];
        buildInputs = with pkgs; [
          icu
          boost
          llvmPackages.openmp
          ceres-solver
          openexr
          flann
          eigen
          openimageio2
          geogram
          wget
          python38
          cudatoolkit
          doxygen
          coin-utils
          coin-clp
          coin-cgl
          coin-cbc
          coin-vol
        ];
        hardeningDisable = [
          "all"
        ];
        cmakeFlags = [
          "-DCeres_DIR:PATH=${pkgs.ceres-solver}/include"
          "-DOPENEXR_HOME:PATH=${pkgs.openexr}/include"
          "-DFLANN_INCLUDE_DIR_HINTS:PATH=${pkgs.flann}/include"
          "-DCMAKE_MODULE_PATH:PATH=${pkgs.eigen}/share/cmake/Modules/"
          "-DOpenImageIO_LIBRARY_DIR_HINTS:PATH=${pkgs.openimageio2}/lib/"
          "-DOpenImageIO_INCLUDE_DIR:PATH=${pkgs.openimageio2.dev}/include/"
          "-DCOIN_INCLUDE_DIR:PATH=${coin-utils}/include;${coin-cbc}/include;${coin-cgl}/include;${coin-clp};${coin-osi}/include;${coin-vol}/include"
          "-DCOIN_CBC_LIBRARY:PATH=${coin-cbc}/lib"
          "-DCOIN_CBC_SOLVER_LIBRARY:PATH=${coin-cbc}/lib"
          "-DCOIN_CGL_LIBRARY:PATH=${coin-cgl}/lib"
          "-DCOIN_CLP_LIBRARY:PATH=${coin-cgl}/lib"
          "-DCOIN_COIN_UTILS_LIBRARY:PATH=${coin-utils}/lib"
          "-DCOIN_OSI_LIBRARY:PATH=${coin-osi}/lib"
          "-DCOIN_OSI_CBC_LIBRARY:PATH=${coin-cbc}/lib"
          "-DCOIN_OSI_CLP_LIBRARY:PATH=${coin-clp}/lib"
          "-DCOIN_OSI_VOL_LIBRARY:PATH=${coin-vol}/lib"
          "-DCOIN_VOL_LIBRARY:PATH=${coin-vol}/lib"
          "-DAV_BUILD_COINUTILS=OFF"
        ];
      };
      meshroom = pkgs.stdenv.mkDerivation rec {
        pname = "meshroom";
        version = "8e9128be8d58f2caf55ad9bc9a41e86798dfd5eb";
        src = pkgs.fetchFromGitHub {
          owner = "alicevision";
          repo = pname;
          rev = version;
          sha256 = "IDoP0JnSI7zz/GSMQZCTQGw5Qg0qr7zMdDqwZJ7OE18=";
        };
        buildInputs = with pkgs; [
          alicevision
        ];
      };
    in {
      defaultPackage = alicevision;#meshroom;
      devShells.alice = alicevision;
      devShells.mesh = meshroom;
      devShells.default = pkgs.mkShell {
        nativeBuildInputs = [ pkgs.bashInteractive ];
        buildInputs = [
          alicevision
        ];
      };
    });
}
