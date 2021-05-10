# Homebrew-openssh-with-various-patches

Homebrew tap for openssh to support GSSAPIAuthentication/GSSAPIDelegateCredentials/GSSAPITrustDNS et al. (and a few other things).

These options allow you to ssh into other boxes from OS X using your kerberos/kinit tickets, so you don't have to type your password in every time.

also overcomes this error message: 
/Users/username/.ssh/config: line 3: Bad configuration option: gssapitrustdns
  
See also https://stackoverflow.com/a/46454141/32453

Read on for justification, but first, for those impatient:

== Installation ===========

To install this patched version of ssh (install homebrew then), add the tap:

$ brew tap rdp/homebrew-openssh-gssapi

Then run one of these:

Want kerberos support?

$ brew install rdp/homebrew-openssh-gssapi/openssh-patched --with-gssapi-support

To install a version that has the "HPN" performance improvements to "speed up openssh for large file transfer"

$ brew install rdp/homebrew-openssh-gssapi/openssh-patched --with-hpn

to install a version with "Added native OS X Keychain and Launch Daemon support to ssh-agent" 
    (i.e. get key pairs also from the KeyChain, not just from ssh-agent...I think. Optional.)

$ brew install rdp/homebrew-openssh-gssapi/openssh-patched --with-keychain-support

Or combine them, my preferred option:

$ brew install rdp/homebrew-openssh-gssapi/openssh-patched --with-gssapi-support --with-keychain-support

(note you can't do any other combination, they conflict currently, PR's or funding welcome!)

Now you can create your kinit tickets and use them like normal with ssh or scp, etc.

The default "ssh" on your command line will become your new homebrew tap one, after installation,
the original is also preserved if you want to revert back to it $ brew remove rdp/homebrew-openssh-gssapi/openssh-patched
you may need to restart your terminal to get the new ones, as well.

The reason this is a "tap" (i.e. homebrew alternative formula) is that Homebrew "mainline" are reluctant to apply these patches 
to the mainline openssh formula, since they aren't included in OS X main (anymore) nor openssh main 
(even though some are supported in various other distros like Debian,
and the keychain patch is supported by macports' version), they're just extra wary of 3rd party patches to security related infrastructure:

See https://archive.is/hSB6d#10%25 for a conversation.  There have been quite a few over the years I think.

however almost *every distro* includes the gssapi patch, and it has a "generally good security history"
https://sources.debian.net/patches/openssh/1:7.5p1-5/
so I'm OK with it, and created this tap to allow people to still access it, though upstream disdains it apparently.

Based loosely on the following:

https://github.com/macports/macports-ports/blob/master/net/openssh/Portfile though its kerberos goes on the PATH and doesn't support kinit --keychain which is painful...
https://sources.debian.net/patches/openssh/1:7.5p1-5/
https://archive.is/hSB6d#10%25
https://github.com/seththeriault/homebrew-openssh-gssapi
https://github.com/Homebrew/homebrew-core/blob/master/Formula/openssh.rb

And various other contributions/contributors, thanks!

Patches/pull requests welcome (ex: update to a newer openssh version)

Want me to add other patches, ex: macports' https://trac.macports.org/browser/trunk/dports/net/openssh various patches? Let me know via issues!

==== Hints:
Now that you've got it installed, 

to use kerberos keys, once you have the new openssh installed, in your ~/.ssh/config file you need/want this:
```
GSSAPIAuthentication yes
GSSAPIDelegateCredentials yes
GSSAPITrustDNS yes
```

Also you can use kinit on OS X like
```
$ kinit --keychain
or
$ kinit --keychain bob@MY.REAL.COM
```
to "save" your password: https://superuser.com/a/950769/39364
