# Homebrew-openssh-kerberos-friendly

Homebrew tap that has an openssh option that supports GSSAPI et al

Meant to allow you to ssh into boxes from OS X using your kerberos/kinit tickets, so you don't have to type your password in every time.

also overcomes this error message: 
/Users/<username>/.ssh/config: line 3: Bad configuration option: gssapitrustdns

== Installation ===========
To install this customized version of ssh (install homebrew then):

$ brew install rdp/homebrew-openssh-gssapi/openssh --with-gssapi-support

Then you can create your kinit tickets and use them like normal with ssh or scp.
(the default "ssh" on the command line will become your new homebrew one, after installation,
the original is also preserved if you want to revert back to it $ brew remove openssh
you may need to restart your terminal to get the new ones, as well).

The reason this is a "tap" (i.e. homebrew alternative formula) is that Homebrew "main" are reluctant to apply this patch since it isn't included in OS X main:
https://github.com/Homebrew/homebrew-dupes/pull/583

however almost *every distro* includes it, and it has a "generally good security history"
https://sources.debian.net/patches/openssh/1:7.5p1-5/
so I'm OK with it.

Based loosely on the following:
https://sources.debian.net/patches/openssh/1:7.5p1-5/
https://github.com/macports/macports-ports/blob/master/net/openssh/Portfile
https://github.com/Homebrew/homebrew-dupes/pull/583


Patches/pull requests welcome (ex: to update to a newer openssh version, currently at 7.5p1, the latest as of at least sep 27 2017).
