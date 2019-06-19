class OpensshPatched < Formula
  desc "OpenBSD freely-licensed SSH connectivity tools with some patches"
  homepage "https://www.openssh.com/"
  url "https://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-7.6p1.tar.gz"
  mirror "https://www.mirrorservice.org/pub/OpenBSD/OpenSSH/portable/openssh-7.6p1.tar.gz"
  version "7.6p1"
  sha256 "a323caeeddfe145baaa0db16e98d784b1fbc7dd436a6bf1f479dfd5cd1d21723"

  # Please don't resubmit the keychain patch option. It will never be accepted.
  # except now it is...
  # https://github.com/Homebrew/homebrew-dupes/pull/482#issuecomment-118994372

  option "with-gssapi-support", "Add GSSAPI key exchange support"
  option "with-hpn", "Enable High Performance SSH (hpn-ssh) patch, helps large file transfer apparently"
  option "with-keychain-support", "Add native OS X Keychain and Launch Daemon support to ssh-agent" # doesn't work with HPN as of today FWIW...

  depends_on "autoconf" => :build if build.with? "keychain-support"
  depends_on "openssl"
  depends_on "ldns" => :optional
  depends_on "pkg-config" => :build if build.with? "ldns"

  conflicts_with 'openssh'

  if build.with? "keychain-support"
    patch do
      url "https://raw.githubusercontent.com/macports/macports-ports/cd1cc0653a300ac6714501bdb64bdedabddb8d75/net/openssh/files/0002-Apple-keychain-integration-other-changes.patch"
      sha256 "1c5e070ed53f77160dd2b658e0d3877cc01ee9cd44711e0ba76092a2a66b4e33"
    end
  end

  if build.with? "gssapi-support"
    patch do
      url "https://raw.githubusercontent.com/rdp/homebrew-openssh-gssapi/master/gssapi.patch" # original https://sources.debian.org/data/main/o/openssh/1:7.6p1-2/debian/patches/gssapi.patch but it was unstable, so bundle :|
      sha256 "3a76ae38ec12873659b0113d097e2a2922d7fd46a1000125da6a5163c4b49051"
    end
  end

  if build.with? "hpn"
    patch do
      url 'https://downloads.sourceforge.net/project/hpnssh/HPN-SSH%2014v14%207.6p1/openssh-7_6_P1-hpn-KitchenSink-14.14.diff'
      sha256 "b5b658049459996eee6ac65f4c5145dfcf529f9825320366ff78937edb2e1186"
    end
  end

  # Both these patches were applied by Apple.
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

  def caveats
    if build.with? "keychain-support" then <<-EOS
        keychain-support:
        NOTE: replacing system daemons is unsupported. Proceed at your own risk.
        See also some warnings here: https://github.com/rdp/homebrew-openssh-gssapi/issues/1

        For complete functionality, please modify:
          /System/Library/LaunchAgents/org.openbsd.ssh-agent.plist

        and change ProgramArguments from
          /usr/bin/ssh-agent
        to
          #{HOMEBREW_PREFIX}/bin/ssh-agent

        You will need to restart or issue the following commands
        for the changes to take effect:

          launchctl unload /System/Library/LaunchAgents/org.openbsd.ssh-agent.plist
          launchctl load /System/Library/LaunchAgents/org.openbsd.ssh-agent.plist

        Finally, add  these lines somewhere to your ~/.bash_profile:
          eval $(ssh-agent)

          function cleanup {
            echo "Killing SSH-Agent"
            kill -9 $SSH_AGENT_PID
          }

          trap cleanup EXIT

        After that, you can start storing private key passwords in
        your OS X Keychain.
      EOS
    end
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
