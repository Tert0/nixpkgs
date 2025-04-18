{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  libpcap,
  boost,
}:

stdenv.mkDerivation rec {
  pname = "usbtop";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "aguinet";
    repo = "usbtop";
    rev = "release-${version}";
    sha256 = "0qbad0aq6j4jrh90l6a0akk71wdzhyzmy6q8wl138axyj2bp9kss";
  };

  nativeBuildInputs = [ cmake ];
  buildInputs = [
    libpcap
    boost
  ];

  meta = with lib; {
    homepage = "https://github.com/aguinet/usbtop";
    description = "Top utility that shows an estimated instantaneous bandwidth on USB buses and devices";
    mainProgram = "usbtop";
    maintainers = [ ];
    license = licenses.bsd3;
    platforms = platforms.linux;
  };
}
