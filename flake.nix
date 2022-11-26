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
      apriltag =  pkgs.stdenv.mkDerivation rec {
        pname = "apriltag";
        version = "3.2.0";
        src = pkgs.fetchFromGitHub {
          owner = "AprilRobotics";
          repo = pname;
          rev = "v${version}";
          sha256 = "pJFTzWX8zLzcDfPCg8v44fwlxEMVeRylcggFk7B5m7g=";
        };
        nativeBuildInputs = with pkgs; [
          cmake
          ninja
        ];
        postInstall = ''
          mv $out/share/*/cmake/* $out/share/*/
          rmdir $out/share/*/cmake
          mkdir -p $out/lib/cmake
          mv $out/share/* $out/lib/cmake
          rm -rf $out/share
        '';
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
      voctree = pkgs.fetchurl {
        url = "https://gitlab.com/alicevision/trainedVocabularyTreeData/raw/master/vlfeat_K80L3.SIFT.tree";
        sha256 = "SuecIXD7tUoAGV+GbytCE+orS8MD9FG2s2Bwmh0ZTLg=";
      };
      qmlAlembic = pkgs.stdenv.mkDerivation rec {
        pname = "qmlAlembic";
        version = "2022.09.08";
        src = pkgs.fetchFromGitHub {
          owner = "alicevision";
          repo = "qmlAlembic";
          rev = "896c52d88a9ef46b0d07eb42d11c631eda18d18c";
          sha256 = "cEqnZQsm6VwucYk6qD/mqXE7bsZz+KQwrTflvzslV50=";
        };
        dontWrapQtApps = true;
        nativeBuildInputs = with pkgs; [
          cmake
        ];
        buildInputs = with pkgs; [
          qt5.qtdeclarative
          qt5.qt3d
          ilmbase
          alembic_
        ];
        postInstall = ''
          mkdir -p $out/${pkgs.qt5.qtbase.qtQmlPrefix}
          mv $out/qml/* $out/${pkgs.qt5.qtbase.qtQmlPrefix}
          rmdir $out/qml
        '';
      };
      qtOIIO = pkgs.stdenv.mkDerivation rec {
        pname = "QtOIIO";
        version = "2022.10.31";
        src = pkgs.fetchFromGitHub {
          owner = "alicevision";
          repo = "QtOIIO";
          rev = "a41dae9c2688277b600e73376146eb26afc671f5";
          sha256 = "/422K75v51aKfGV2DSs/+jekbwyJyNStVyjU2CwmncA=";
        };
        dontWrapQtApps = true;
        nativeBuildInputs = with pkgs; [
          cmake
        ];
        buildInputs = with pkgs; [
          qt5.qtdeclarative
          qt5.qt3d
          openimageio2
        ];
        postInstall = ''
          mkdir -p $out/${pkgs.qt5.qtbase.qtQmlPrefix}
          mv $out/qml/* $out/${pkgs.qt5.qtbase.qtQmlPrefix}
          mv $out/imageformats $out/lib
          rmdir $out/qml
        '';
      };
      qtAliceVision = pkgs.stdenv.mkDerivation rec {
        pname = "QtAliceVision";
        version = "2022.06.03";
        src = pkgs.fetchFromGitHub {
          owner = "alicevision";
          repo = "QtAliceVision";
          rev = "104d35444a29380c88d550d6b8065d4f855242f0";
          sha256 = "q6Vn6afMmCLqEgRplTW5mAFoX8AFIx0V8LAl45yc/Ho=";
        };
        dontWrapQtApps = true;
        nativeBuildInputs = with pkgs; [
          cmake
        ];
        buildInputs = with pkgs; [
          qt5.qtdeclarative
          qt5.qtcharts
          boost
          coin-utils
          coin-clp
          coin-osi
          popsift
          alembic_
          openimageio2
          ceres-solver
          alicevision
        ];
        postInstall = ''
          mkdir -p $out/${pkgs.qt5.qtbase.qtQmlPrefix}
          mv $out/qml/* $out/${pkgs.qt5.qtbase.qtQmlPrefix}
          rmdir $out/qml
        '';
      };
      meshroom = pkgs.stdenv.mkDerivation rec {
        pname = "meshroom";
        version = "2022.11.15";
        src = pkgs.fetchFromGitHub {
          owner = "alicevision";
          repo = pname;
          rev = "8e9128be8d58f2caf55ad9bc9a41e86798dfd5eb";
          sha256 = "IDoP0JnSI7zz/GSMQZCTQGw5Qg0qr7zMdDqwZJ7OE18=";
        };
        nativeBuildInputs = with pkgs; [
          qt5.wrapQtAppsHook
        ];
        dontConfigure = true;
        dontBuild = true;
        installPhase = ''
          mkdir -p $out/{bin,lib}
          cp -r $src/meshroom $out/lib/
        '';
        dontWrapQtApps = true;
        postFixup = ''
          qtWrapperArgs+=("''${gappsWrapperArgs[@]}")
          makeQtWrapper ${mesh-py}/bin/python3 $out/bin/meshroom \
                      --prefix PYTHONPATH : $out/lib/ \
                      --prefix PATH : ${alicevision}/bin/ \
                      --prefix ALICEVISION_SENSOR_DB : ${alicevision}/share/aliceVision/cameraSensors.db \
                      --prefix ALICEVISION_VOCTREE : ${voctree} \
                      --prefix ALICEVISION_ROOT : ${alicevision} \
                      --add-flags $out/lib/meshroom/ui
        '';
        buildInputs = [
          pkgs.qt5.qt3d.bin
          pkgs.qt5.qtcharts.bin
          qmlAlembic
          qtOIIO
          qtAliceVision
        ];
      };
    in {
      defaultPackage = meshroom;
      devShells.april = apriltag;
      devShells.alice = alicevision;
      devShells.mesh = meshroom;
    });
}
