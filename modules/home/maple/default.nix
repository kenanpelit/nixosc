# modules/home/maple/default.nix
# ==============================================================================
# Local Maple Mono (7.8) font package set.
# - Returns an attrset of all Maple variants (NF/CN/NL/Variable/TTF/OTF/Woff2).
# ==============================================================================

{ lib, pkgs }:

let
  hashes = lib.importJSON ./hashes.json;
  version = "7.8";

  maple-font =
    { pname, hash, desc }:
    pkgs.stdenv.mkDerivation rec {
      inherit pname version;

      src = pkgs.fetchurl {
        url = "https://github.com/subframe7536/Maple-font/releases/download/v${version}/${pname}.zip";
        sha256 = hash;
      };

      sourceRoot = ".";
      nativeBuildInputs = [ pkgs.unzip ];

      installPhase = ''
        find . -name '*.ttf'   -exec install -Dt $out/share/fonts/truetype {} \;
        find . -name '*.otf'   -exec install -Dt $out/share/fonts/opentype {} \;
        find . -name '*.woff2' -exec install -Dt $out/share/fonts/woff2 {} \;
      '';

      meta = with lib; {
        homepage = "https://github.com/subframe7536/Maple-font";
        description = "Maple Mono ${desc} font set (v${version})";
        license = licenses.ofl;
        platforms = platforms.all;
      };
    };

  typeVariants = {
    truetype = { suffix = "TTF"; desc = "monospace TrueType"; };
    truetype-autohint = { suffix = "TTF-AutoHint"; desc = "monospace ttf autohint"; };
    variable = { suffix = "Variable"; desc = "monospace variable"; };
    woff2 = { suffix = "Woff2"; desc = "WOFF2.0"; };
    opentype = { suffix = "OTF"; desc = "OpenType"; };
    NF = { suffix = "NF"; desc = "Nerd Font"; };
    NF-unhinted = { suffix = "NF-unhinted"; desc = "Nerd Font unhinted"; };
    CN = { suffix = "CN"; desc = "monospace CN"; };
    CN-unhinted = { suffix = "CN-unhinted"; desc = "monospace CN unhinted"; };
    NF-CN = { suffix = "NF-CN"; desc = "Nerd Font CN"; };
    NF-CN-unhinted = { suffix = "NF-CN-unhinted"; desc = "Nerd Font CN unhinted"; };
  };

  ligatureVariants = {
    No-Ligature = { suffix = "NL"; desc = "No Ligature"; };
    Normal-Ligature = { suffix = "Normal"; desc = "Normal Ligature"; };
    Normal-No-Ligature = { suffix = "NormalNL"; desc = "Normal No Ligature"; };
  };

  getHash = name: hashes.${name} or lib.fakeSha256;

  mapleFonts =
    lib.concatMapAttrs
      (_: ligVariant:
        lib.concatMapAttrs
          (_: typeVariant:
            let pname = "MapleMono${ligVariant.suffix}-${typeVariant.suffix}";
            in {
              "${ligVariant.suffix}-${typeVariant.suffix}" = maple-font {
                inherit pname;
                desc = "${ligVariant.desc} ${typeVariant.desc}";
                hash = getHash pname;
              };
            })
          typeVariants)
      ligatureVariants
    //
    lib.mapAttrs
      (_: value:
        let pname = "MapleMono-${value.suffix}";
        in maple-font {
          inherit pname;
          inherit (value) desc;
          hash = getHash pname;
        })
      typeVariants;
in
mapleFonts
