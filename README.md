# Homebrew-openssh-kerberos-friendly

Homebrew tap that includes a formula for openssh with an option that supports GSSAPIAuthentication/GSSAPIDelegateCredentials/GSSAPITrustDNS et al.

Meant to allow you to ssh into other boxes from OS X using your kerberos/kinit tickets, so you don't have to type your password in every time.

also overcomes this error message: 
/Users/<username>/.ssh/config: line 3: Bad configuration option: gssapitrustdns
  
See also https://stackoverflow.com/a/46454141/32453

== Installation ===========

To install this kerberos friendlier version of ssh (install homebrew then):

$ brew install rdp/homebrew-openssh-gssapi/openssh --with-gssapi-support --with-hpn

Then you can create your kinit tickets and use them like normal with ssh or scp, etc.
(the default "ssh" on the command line will become your new homebrew one, after installation,
the original is also preserved if you want to revert back to it $ brew remove openssh
you may need to restart your terminal to get the new ones, as well).

--with-hpn is optionally, and is a patch to "speed up openssh for large file transfer"

The reason this is a "tap" (i.e. homebrew alternative formula) is that Homebrew "main" are reluctant to apply this patch since it isn't included in OS X main:
https://github.com/Homebrew/homebrew-dupes/pull/583

however almost *every distro* includes it, and it has a "generally good security history"
https://sources.debian.net/patches/openssh/1:7.5p1-5/
so I'm OK with it.

Based loosely on the following:

https://sources.debian.net/patches/openssh/1:7.5p1-5/
https://github.com/macports/macports-ports/blob/master/net/openssh/Portfile
https://github.com/Homebrew/homebrew-dupes/pull/583

Patches/pull requests welcome (ex: to update to a newer openssh version, currently at 7.5p1, the latest as of at least sep 2017).  

Want me to add other patches, ex: https://trac.macports.org/browser/trunk/dports/net/openssh ? Let me know in issues!


Hints:

In your ~/.ssh/config you need/want this:

GSSAPIAuthentication yes
GSSAPIDelegateCredentials yes
GSSAPITrustDNS yes

And also you can use kinit on OS X like
$ kinit --keychain
or
$ kinit --keychain bob@MY.REAL.COM

to "save" your password: https://superuser.com/a/950769/39364
