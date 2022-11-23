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
        preConfigure = ''
          echo PRECONFigure
          echo $PWD
          ls -la
        '';
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
      # TBB (2020) needs update
      # tbb = pkgs.tbb.overrideAttrs (self: super: rec {
      tbb = pkgs.stdenv.mkDerivation rec {
        pname = "tbb";
        version = "2021.7.0";
        src = pkgs.fetchFromGitHub {
          owner = "oneapi-src";
          repo = "oneTBB";
          rev = "v${version}";
          sha256 = "Lawhms0yq5p8BrQXMy6dPe29dpSlHdSntum+6bAkpyo=";
        };
        nativeBuildInputs = with pkgs; [
          cmake
        ];
      };
      cctag = pkgs.stdenv.mkDerivation rec {
        pname = "CCTag";
        version = "1.0.3";
        src = pkgs.fetchFromGitHub {
          owner = "alicevision";
          repo = pname;
          rev = "v${version}";
          sha256 = "foB+e7BCuUucyhN8FsI6BIT3/fsNLTjY6QmjkMWZu6A=";
        };
        nativeBuildInputs = with pkgs; [
          cmake
        ];
        buildInputs = with pkgs; [
          eigen
          boost
          opencv
          tbb
          unfree.cudatoolkit
        ];
        cmakeFlags = [
          "-DTBB_DIR:PATH=${pkgs.tbb}/lib/cmake"
        ];
      };
      vtkIOMPI = pkgs.vtk.overrideAttrs (self: super: rec {
        buildInputs = super.buildInputs ++ (with pkgs; [
          mpi
        ]);
        cmakeFlags = super.cmakeFlags ++ [
          "-DVTK_USE_MPI=ON"
        ];
      });
      # New PCL derivation
      pcl_new = pkgs.pcl.overrideAttrs (self: (super: rec {
        version = "1.12.1";
        src = pkgs.fetchFromGitHub {
          owner = "PointCloudLibrary";
          repo = "pcl";
          rev = "${super.pname}-${version}";
          sha256 = "ZVJFF3eoNfUafjHOjZe+ePUE0U+1+/BNYyS95xLm5hM=";
        };
        buildInputs = super.buildInputs ++ [
          unfree.cudatoolkit
        ];
        propagatedBuildInputs = with pkgs; [
          boost
          flann
          libpng
          libtiff
          qhull
          vtkIOMPI
        ];
        cmakeFlags = super.cmakeFlags ++ ["-DWITH_CUDA=true"];
      }));
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
          ceres-solver
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
          cctag
          popsift
          # pcl_new
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
