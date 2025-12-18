{ pkgs }:

pkgs.stdenv.mkDerivation {
  pname = "operator-mono";
  version = "1.0";

  # Point this to the local folder containing your font files (otf, ttf, etc.)
  src = ./fonts/operator-mono;

  installPhase = ''
    mkdir -p $out/share/fonts/truetype
    cp *.ttf $out/share/fonts/truetype/
  '';
}
