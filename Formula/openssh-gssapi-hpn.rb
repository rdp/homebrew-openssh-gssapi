class OpensshGssapiHpn < Formula
  desc "OpenBSD freely-licensed SSH connectivity tools"
  homepage "https://www.openssh.com/"
  url "https://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-7.6p1.tar.gz"
  mirror "https://www.mirrorservice.org/pub/OpenBSD/OpenSSH/portable/openssh-7.6p1.tar.gz"
  version "7.6p1"
  sha256 "a323caeeddfe145baaa0db16e98d784b1fbc7dd436a6bf1f479dfd5cd1d21723"

  # Please don't resubmit the keychain patch option. It will never be accepted.
  # https://github.com/Homebrew/homebrew-dupes/pull/482#issuecomment-118994372

  option "with-gssapi-support", "Add GSSAPI key exchange support"
  option "with-hpn", "Enable High Performance SSH (hpn-ssh) patch, helps large file transfer apparently"
  option "with-keychain-support", "Add native OS X Keychain and Launch Daemon support to ssh-agent"

  depends_on "autoconf" => :build if build.with? "keychain-support"	
  depends_on "openssl"
  depends_on "ldns" => :optional
  depends_on "pkg-config" => :build if build.with? "ldns"

  conflicts_with 'openssh'

  if build.with? "keychain-support"	
    patch do	
      url "https://trac.macports.org/export/135165/trunk/dports/net/openssh/files/0002-Apple-keychain-integration-other-changes.patch"	
      sha256 "bcc9b9103fe2333ec6053fcdf5aac51ca2f07138cd05b66c37c01c92585ed778"	
    end	
  end

  if build.with? "gssapi-support"
    patch do
      url "https://sources.debian.org/data/main/o/openssh/1:7.6p1-5/debian/patches/gssapi.patch"
      sha256 "3a76ae38ec12873659b0113d097e2a2922d7fd46a1000125da6a5163c4b49051"
    end
  end

  if build.with? "hpn"
    patch do
      url 'https://downloads.sourceforge.net/project/hpnssh/HPN-SSH%2014v14%207.6p1/openssh-7_6_P1-hpn-KitchenSink-14.14.diff'
      sha256 "96b66d0ce26a8e6f9e925c4c991ccab4e9050f95a420e7f7e59f39c89fa17939"
    end 
  end

  # Both these patches are applied by Apple.
  patch do
    url "https://raw.githubusercontent.com/Homebrew/patches/1860b0a74/openssh/patch-sandbox-darwin.c-apple-sandbox-named-external.diff"
    sha256 "d886b98f99fd27e3157b02b5b57f3fb49f43fd33806195970d4567f12be66e71"
  end

  patch do
    url "https://raw.githubusercontent.com/Homebrew/patches/d8b2d8c2/openssh/patch-sshd.c-apple-sandbox-named-external.diff"
    sha256 "3505c58bf1e584c8af92d916fe5f3f1899a6b15cc64a00ddece1dc0874b2f78f"
  end

  resource "com.openssh.sshd.sb" do
    url "https://opensource.apple.com/source/OpenSSH/OpenSSH-209.50.1/com.openssh.sshd.sb"
    sha256 "a273f86360ea5da3910cfa4c118be931d10904267605cdd4b2055ced3a829774"
  end

  def install
    system "autoreconf -i" if build.with? "keychain-support"	
    if build.with? "keychain-support"	
      ENV.append "CPPFLAGS", "-D__APPLE_LAUNCHD__ -D__APPLE_KEYCHAIN__"	
      ENV.append "LDFLAGS", "-framework CoreFoundation -framework SecurityFoundation -framework Security"	
    end

    ENV.append "CPPFLAGS", "-D__APPLE_SANDBOX_NAMED_EXTERNAL__"

    # Ensure sandbox profile prefix is correct.
    # We introduce this issue with patching, it's not an upstream bug.
    inreplace "sandbox-darwin.c", "@PREFIX@/share/openssh", etc/"ssh"

    args = %W[
      --with-libedit
      --with-kerberos5
      --prefix=#{prefix}
      --sysconfdir=#{etc}/ssh
      --with-pam
      --with-ssl-dir=#{Formula["openssl"].opt_prefix}
    ]

    args << "--with-ldns" if build.with? "ldns"

    system "./configure", *args
    system "make"
    ENV.deparallelize
    system "make", "install"

    # This was removed by upstream with very little announcement and has
    # potential to break scripts, so recreate it for now.
    # Debian have done the same thing.
    bin.install_symlink bin/"ssh" => "slogin"

    buildpath.install resource("com.openssh.sshd.sb")
    (etc/"ssh").install "com.openssh.sshd.sb" => "org.openssh.sshd.sb"
  end

  test do
    assert_match "OpenSSH_", shell_output("#{bin}/ssh -V 2>&1")

    begin
      pid = fork { exec sbin/"sshd", "-D", "-p", "8022" }
      sleep 2
      assert_match "sshd", shell_output("lsof -i :8022")
    ensure
      Process.kill(9, pid)
      Process.wait(pid)
    end
  end
end
