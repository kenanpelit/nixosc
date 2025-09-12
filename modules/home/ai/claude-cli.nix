# modules/home/ai/claude-cli.nix
{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, glibc
, gcc-unwrapped
, openssl
, zlib
, curl
}:

stdenv.mkDerivation rec {
  pname = "claude-cli";
  version = "0.1.0"; # Gerçek versiyonu kullanın
  
  # Not: Bu URL'yi Anthropic'in resmi indirme linki ile değiştirin
  # Şu an için placeholder URL kullanıyorum
  src = fetchurl {
    url = "https://github.com/anthropics/claude-cli/releases/download/v${version}/claude-cli-linux-x64";
    # Gerçek SHA256 hash'ini hesaplamanız gerekecek
    sha256 = "0000000000000000000000000000000000000000000000000000000000000000";
  };

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    glibc
    gcc-unwrapped.lib
    openssl
    zlib
    curl
  ];

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/bin
    cp $src $out/bin/claude
    chmod +x $out/bin/claude
    
    runHook postInstall
  '';

  # Eğer binary çalışmazsa, bu alternatif yöntemi deneyin
  postFixup = ''
    # Binary'nin dinamik kütüphanelerini düzelt
    patchelf --set-interpreter ${glibc}/lib/ld-linux-x86-64.so.2 $out/bin/claude
  '';

  meta = with lib; {
    description = "Claude CLI - Command line interface for Claude AI";
    homepage = "https://docs.anthropic.com/en/docs/claude-code";
    changelog = "https://github.com/anthropics/claude-cli/releases/tag/v${version}";
    license = licenses.proprietary;
    maintainers = [ ];
    platforms = platforms.linux;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
