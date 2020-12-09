class OpensshPatched < Formula
  desc "OpenBSD freely-licensed SSH connectivity tools with some patches"
  homepage "https://www.openssh.com/"
  url "https://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-8.4p1.tar.gz"
  version "8.4p1"
  sha256 "5a01d22e407eb1c05ba8a8f7c654d388a13e9f226e4ed33bd38748dafa1d2b24"

  # used to say: Please don't resubmit the keychain patch option. It will never be accepted.
  # now here it is...
  # https://github.com/Homebrew/homebrew-dupes/pull/482#issuecomment-118994372

  option "with-gssapi-support", "Add GSSAPI key exchange support"
  option "with-hpn", "Enable High Performance SSH (hpn-ssh) patch, helps large file transfer apparently"
  option "with-keychain-support", "Add native OS X Keychain and Launch Daemon support to ssh-agent" # doesn't work together with HPN as of today FWIW...

  depends_on "autoconf" => :build # if build.with? "keychain-support"
  depends_on "automake" => :build
  depends_on "openssl"
  depends_on "ldns" => :optional
  depends_on "pkg-config" => :build if build.with? "ldns"

  conflicts_with 'openssh'

  if build.with? "keychain-support"
    patch do
      url "https://gist.githubusercontent.com/leonklingele/01c01e6d9d143fa5b1df8e2354d808e4/raw/b509dedea2a6a4bab3dc75f7be2a7a1ac1cfb24e/0001-apple-keychain-integration-other-changes.patch"
      sha256 "3cc0a5c8000cc0005c6b00b0c3c4acee38f0d2b0008eaf2193c9c8d1ae58bfdc"
    end
  end

  if build.with? "hpn"
    patch do
      url 'https://sourceforge.net/projects/hpnssh/files/Patches/HPN-SSH%2015v1%208.4p1/openssh-8_4_P1-hpn-KitchenSink-15.1.diff'
      sha256 "addec311972075ea38f3978b7b98c893152937110a91bf8f00a95c369428c44b"
    end
  end

  if build.with? "gssapi-support"
    patch do
      url "https://raw.githubusercontent.com/rdp/homebrew-openssh-gssapi/master/gssapi.8.4p1.patch" # was "https://sources.debian.org/data/main/o/openssh/1:8.4p1-2/debian/patches/gssapi.patch"
      sha256 "15139c42894dd0ebd182608ecd7151a9eef6158aed30c676e7685e8407c6d1cb"
    end
  end

  # Both these patches were once upon a time applied by Apple.
  patch do
    url "https://raw.githubusercontent.com/Homebrew/patches/1860b0a74/openssh/patch-sandbox-darwin.c-apple-sandbox-named-external.diff"
    sha256 "d886b98f99fd27e3157b02b5b57f3fb49f43fd33806195970d4567f12be66e71"
  end

  patch do
    url "https://raw.githubusercontent.com/Homebrew/patches/d8b2d8c2/openssh/patch-sshd.c-apple-sandbox-named-external.diff"
    sha256 "3505c58bf1e584c8af92d916fe5f3f1899a6b15cc64a00ddece1dc0874b2f78f"
  end

  # no idea what this is for...
  resource "com.openssh.sshd.sb" do
    url "https://opensource.apple.com/source/OpenSSH/OpenSSH-209.50.1/com.openssh.sshd.sb"
    sha256 "a273f86360ea5da3910cfa4c118be931d10904267605cdd4b2055ced3a829774"
  end

  def install
    system "autoreconf -i" # keychain, hpn need it...
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
    args << "--with-keychain=apple" if build.with? "keychain-support" # macports' patch required this LOL

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
        keychain-support with ssh-agent keys:
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
