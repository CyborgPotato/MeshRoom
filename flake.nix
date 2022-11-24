{
  description = "A basic flake with a shell";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      unfree = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      geogram = pkgs.stdenv.mkDerivation rec {
        pname = "geogram";
        version = "1.7.7";
        src = pkgs.fetchFromGitHub {
          owner = "alicevision";
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
          owner = "alicevision";
          repo = "CoinUtils";
          rev = "b29532e31471d26dddee99095da3340e80e8c60c";
          deepClone = true;
          sha256 = "hJtWLNf8QWCBn7td8GtZpIejMrxiWy/L/TVFQKHAotg=";
        };
        nativeBuildInputs = with pkgs; [
          cmake
        ];
      };
      coin-osi = pkgs.stdenv.mkDerivation rec {
        pname = "coin-osi";
        version = "0.108.7";
        src = pkgs.fetchFromGitHub {
          owner = "alicevision";
          repo = "osi";
          rev = "52bafbabf8d29bcfd57818f0dd50ee226e01db7f";
          deepClone = true;
          sha256 = "V29t8oPk0u7UFyMu76U4B8YhxLh85PdHj4QDOHXFlm0=";
        };
        nativeBuildInputs = with pkgs; [
          cmake
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
          owner = "alicevision";
          repo = "clp";
          rev = "4da587acebc65343faafea8a134c9f251efab5b9";
          deepClone = true;
          sha256 = "txkbKGVJCH4kJR8sESPZihch8gyyzWUeYfuTANgZjHY=";
        };
        nativeBuildInputs = with pkgs; [
          cmake
          pkg-config
          libtool
        ];
        buildInputs = with pkgs; [
          coin-utils
          coin-osi
        ];
      };
      suitesparse_new = pkgs.suitesparse.overrideAttrs (self: super: rec {
        version = "6.0.1";
        src = pkgs.fetchFromGitHub {
          owner = "DrTimothyAldenDavis";
          repo = "SuiteSparse";
          rev = "v${version}";
          sha256 = "v+ymKQXlbh2XQPbiUxIgwKoB1L7Z5RQ1/HUxbH6O4D4=";
        };
        dontUseCmakeConfigure=true;
        CMAKE_OPTIONS="-DCMAKE_BUILD_TYPE=Release -DGLOBAL_INSTALL=false -DLOCAL_INSTALL=true -DALLOW_64BIT_BLAS=true -DBLAS_LIBRARIES=${pkgs.blas}/lib -DLAPACK_LIBRARIES=${pkgs.lapack}/lib";
        nativeBuildInputs = super.nativeBuildInputs ++ (with pkgs; [
          cmake
        ]);
        buildInputs = super.buildInputs ++ (with pkgs; [
          gfortran
        ]);
        installPhase = ''
          make install
          mkdir $doc
          mkdir $out
          mv ./lib $dev/
          mv ./include $dev/
        '';
      });
      ceres-solver_new = pkgs.ceres-solver.overrideAttrs (self: super: rec {
        pname = "ceres-solver";
        version = "2.1.0";
        src = pkgs.fetchFromGitHub {
          owner = "ceres-solver";
          repo = "ceres-solver";
          rev = "352b320ab1b5438a0838aea09cbbf07fa4ff5d71";
          sha256 = "MvfBPRbZA3KVHFQW7CkRpP/i3a6ZuNZQybYrdzuPKyw=";
        };
        patches = [];
        propagatedBuildInputs = (with pkgs; [
          eigen
          glog
          blas
          suitesparse_new
        ]);
      });
      apriltag =  pkgs.stdenv.mkDerivation rec {
        pname = "apriltag";
        version = "3.1.3";
        src = pkgs.fetchFromGitHub {
          owner = "alicevision";
          repo = pname;
          rev = "v${version}";
          sha256 = "DY4IB9B73wAzke8t3hRSdFuLcj2lOXpbSeobYGyzMFI=";
        };
        nativeBuildInputs = with pkgs; [
          cmake
        ];
      };
      # Alembic dev CMAKE is malformed, and looks for lib in dev output when it's in alembic.lib
      alembic_ = pkgs.alembic.overrideAttrs (self: super: {
        outputs = [ "out" ];
        buildPhase = ''
          cmake -DUSE_HDF5=ON -DCMAKE_INSTALL_PREFIX=$out/ -DUSE_TESTS=OFF .
          make -j17
          mkdir $out
        '';
        installPhase = ''
          make install
        '';
      });
      popsift = pkgs.stdenv.mkDerivation rec {
        pname = "popsift";
        version = "0.9.x";
        src = pkgs.fetchFromGitHub {
          owner = "alicevision";
          repo = pname;
          rev = "4c22d41579c17d7326938929c00c54cfa01a4592";
          sha256 = "X9yLCMWKXRYdxzV1dsgswjgfaB+29judbIAlDYX+G3c=";
        };
        nativeBuildInputs = with pkgs; [
          cmake
        ];
        buildInputs = with pkgs; [
          boost
          unfree.cudatoolkit
          libdevil
        ];
      };
      alicevision = pkgs.stdenv.mkDerivation rec {
        pname = "alicevision";
        version = "2022-10-15";
        src = pkgs.fetchFromGitHub {
          owner = pname;
          repo = pname;
          rev = "672fb43cea53bbf07b262f0e3ee618c62aec2f9b";
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
          ceres-solver_new
          openexr
          opencv
          flann
          eigen
          openimageio2
          geogram
          wget
          python38
          unfree.cudatoolkit
          doxygen
          coin-utils
          coin-clp
          coin-osi
          assimp
          alembic_
          apriltag
          popsift
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
          "-DALICEVISION_USE_OPENCV=ON"
          "-DOpenCV_DIR:PATH=${pkgs.opencv}/lib/cmake/"
        ];
      };
      py = pkgs.python3;
      pyside2_3d = py.pkgs.pyside2.overrideAttrs (self: super: {
        buildInputs = super.buildInputs ++ (with pkgs.qt5; [
          qt3d
        ]);
      });
      mesh-py = py.withPackages (p: with p; [
        pyside2_3d
        psutil
        markdown
        requests
      ]);
      meshroom = pkgs.stdenv.mkDerivation rec {
        pname = "meshroom";
        version = "8e9128be8d58f2caf55ad9bc9a41e86798dfd5eb";
        src = pkgs.fetchFromGitHub {
          owner = "alicevision";
          repo = pname;
          rev = version;
          sha256 = "IDoP0JnSI7zz/GSMQZCTQGw5Qg0qr7zMdDqwZJ7OE18=";
        };
        propagatedNativeBuildInputs = [
          pkgs.stdenv.cc.cc.lib
        ];
        #export  QML2_IMPORT_PATH=/nix/store/365hahbdvz2r7nwk1fyi73ypd3yqlmfp-qtcharts-5.15.7-bin/lib/qt-5.15.7/qml:/nix/store/61y1jna9wj6n3663g0yamw4ngick2qmf-qt3d-5.15.7-bin/lib/qt-5.15.7/qml:$QML2_IMPORT_PATH
        propagatedBuildInputs = [
          mesh-py
          pkgs.qt5.qt3d.bin
          pkgs.qt5.qtcharts.bin
        ];
        buildInputs = with pkgs; [
          alicevision
        ];
      };
    in {
      defaultPackage = alicevision;#meshroom;
      devShells.alice = alicevision;
      devShells.mesh = meshroom;
      devShells.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          bashInteractive
          qt5.qttools.dev
        ];
        propagatedBuildInputs = [
          mesh-py
        ];
        QT_QPA_PLATFORM_PLUGIN_PATH="${pkgs.qt5.qtbase}/${pkgs.qt5.qtbase.qtPluginPrefix}/platforms";
        shellHook = ''
          # source venv/bin/activate
          # export PIP_CACHE_DIR="$PWD/venv/cache"
          # Source locally
          export PYTHONPATH=./:$PYTHONPATH
          cd source
          # fixes libstdc++ issues and libgl.so issues
          export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib/:/run/opengl-driver/lib/:${pkgs.glib.out}/lib:${pkgs.libkrb5.out}/lib:${pkgs.libglvnd.out}/lib:${pkgs.xorg.libxcb}/lib
          # fixes xcb issues :
          # export QT_PLUGIN_PATH=${pkgs.qt5.qtbase}/${pkgs.qt5.qtbase.qtPluginPrefix}
        '';
      };
    });
}
