{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  buildPackages,
  cimg,
  cmake,
  common-updater-scripts,
  coreutils,
  curl,
  fftw,
  gmic-qt,
  gnugrep,
  gnused,
  graphicsmagick,
  jq,
  libX11,
  libXext,
  libjpeg,
  libpng,
  libtiff,
  llvmPackages,
  ninja,
  opencv,
  openexr,
  pkg-config,
  writeShellScript,
  zlib,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "gmic";
  version = "3.5.3";

  outputs = [
    "out"
    "lib"
    "dev"
    "man"
  ];

  src = fetchFromGitHub {
    owner = "GreycLab";
    repo = "gmic";
    rev = "v.${finalAttrs.version}";
    hash = "sha256-DO9BtU0TW1HzCgrwx4Hocxlhl+tO0IztifqBloqmmtM=";
  };

  # TODO: build this from source
  # Reference: src/Makefile, directive gmic_stdlib_community.h
  gmic_stdlib = fetchurl {
    name = "gmic_stdlib_community.h";
    url = "https://gmic.eu/gmic_stdlib_community${
      lib.replaceStrings [ "." ] [ "" ] finalAttrs.version
    }.h";
    hash = "sha256-LWAzg72MZ4kOTAS+2xwR3iVY8vPch3NAjx/uXX2Y0W4=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
  ];

  buildInputs =
    [
      cimg
      fftw
      graphicsmagick
      libX11
      libXext
      libjpeg
      libpng
      libtiff
      opencv
      openexr
      zlib
    ]
    ++ lib.optionals stdenv.cc.isClang [
      llvmPackages.openmp
    ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_LIB_STATIC" false)
    (lib.cmakeBool "ENABLE_CURL" false)
    (lib.cmakeBool "ENABLE_DYNAMIC_LINKING" true)
    (lib.cmakeBool "ENABLE_OPENCV" true)
    (lib.cmakeBool "ENABLE_XSHM" true)
    (lib.cmakeBool "USE_SYSTEM_CIMG" true)
  ];

  postPatch =
    ''
      cp -r ${finalAttrs.gmic_stdlib} src/gmic_stdlib_community.h
    ''
    + lib.optionalString stdenv.hostPlatform.isDarwin ''
      substituteInPlace CMakeLists.txt \
        --replace "LD_LIBRARY_PATH" "DYLD_LIBRARY_PATH"
    ''
    + lib.optionalString (!stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
      substituteInPlace CMakeLists.txt --replace-fail \
        'LD_LIBRARY_PATH=''${GMIC_BINARIES_PATH} ''${GMIC_BINARIES_PATH}/gmic' \
        '${lib.getExe buildPackages.gmic}'
    '';

  passthru = {
    tests = {
      # Needs to update them all in lockstep.
      inherit cimg gmic-qt;
    };

    updateScript = writeShellScript "gmic-update-script" ''
      set -o errexit
      PATH=${
        lib.makeBinPath [
          common-updater-scripts
          coreutils
          curl
          gnugrep
          gnused
          jq
        ]
      }

      latestVersion=$(curl 'https://gmic.eu/files/source/' \
                       | grep -E 'gmic_[^"]+\.tar\.gz' \
                       | sed -E 's/.+<a href="gmic_([^"]+)\.tar\.gz".+/\1/g' \
                       | sort --numeric-sort --reverse | head -n1)

      if [[ "${finalAttrs.version}" = "$latestVersion" ]]; then
          echo "The new version same as the old version."
          exit 0
      fi

      for component in src gmic_stdlib; do
          update-source-version "--source-key=$component" "gmic" $latestVersion --ignore-same-version
      done
    '';
  };

  meta = {
    homepage = "https://gmic.eu/";
    description = "Open and full-featured framework for image processing";
    mainProgram = "gmic";
    license = lib.licenses.cecill21;
    maintainers = [ ];
    platforms = lib.platforms.unix;
  };
})
