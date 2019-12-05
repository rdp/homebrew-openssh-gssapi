# Homebrew-openssh-with-various-patches

Homebrew tap for openssh with option to support GSSAPIAuthentication/GSSAPIDelegateCredentials/GSSAPITrustDNS et al.

These patches allow you to ssh into other boxes from OS X using your kerberos/kinit tickets, so you don't have to type your password in every time.

also overcomes this error message: 
/Users/username/.ssh/config: line 3: Bad configuration option: gssapitrustdns
  
See also https://stackoverflow.com/a/46454141/32453

== Installation ===========

To install this patched version of ssh (install homebrew then) run one of these:

$ brew install rdp/homebrew-openssh-gssapi/openssh-patched --with-gssapi-support

To install a version that has the "HPN" performance improvements to "speed up openssh for large file transfer"

$ brew install rdp/homebrew-openssh-gssapi/openssh-patched --with-hpn

to install a version with "Added native OS X Keychain and Launch Daemon support to ssh-agent"

$ brew install rdp/homebrew-openssh-gssapi/openssh-patched --with-keychain-support

Or combine them:

$ brew install rdp/homebrew-openssh-gssapi/openssh-patched --with-gssapi-support --with-keychain-support

(note you can't do any other combination, they conflict, PR's or funding welcome!)

Then you can create your kinit tickets and use them like normal with ssh or scp, etc.
(the default "ssh" on the command line will become your new homebrew one, after installation,
the original is also preserved if you want to revert back to it $ brew remove openssh
you may need to restart your terminal to get the new ones, as well).

The reason this is a "tap" (i.e. homebrew alternative formula) is that Homebrew "mainline" are reluctant to apply these patches 
since they aren't included in OS X main (anymore) nor openssh main (even though some are supported in various other distros like Debian,
and the keychain patch is supported by macports' version), they're just wary of unaccepted patches to security related infrastructure:

See https://github.com/Homebrew/homebrew-dupes/pull/583 for the conversation.

however almost *every distro* includes the gssapi patch, and it has a "generally good security history"
https://sources.debian.net/patches/openssh/1:7.5p1-5/
so I'm OK with it, and created this tap to allow people to still access it.

Based loosely on the following:

https://github.com/macports/macports-ports/blob/master/net/openssh/Portfile
https://sources.debian.net/patches/openssh/1:7.5p1-5/
https://github.com/Homebrew/homebrew-dupes/pull/583
https://github.com/seththeriault/homebrew-openssh-gssapi
https://github.com/Homebrew/homebrew-core/blob/master/Formula/openssh.rb

And various other contributions/contributors, thanks!

Patches/pull requests welcome (ex: to update to a newer openssh version)

Want me to add other patches, ex: macports' https://trac.macports.org/browser/trunk/dports/net/openssh ? Let me know via issues!

==== Hints:

To use kerberos keys, once you have the new openssh installed, in your ~/.ssh/config file you need/want this:
```
GSSAPIAuthentication yes
GSSAPIDelegateCredentials yes
GSSAPITrustDNS yes
```
And also you can use kinit on OS X like
```
$ kinit --keychain
or
$ kinit --keychain bob@MY.REAL.COM
```
to "save" your password: https://superuser.com/a/950769/39364
