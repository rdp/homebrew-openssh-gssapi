# homebrew-openssh-gssapi

homebrew tap that has an openssh option that supports GSSAPI et al

meant to allow you to ssh into boxes from OS X using your kerberos/kinit tickets, so you don't have to type your password in every time.

also overcomes the infamous erorr message: 
/Users/<username>/.ssh/config: line 3: Bad configuration option: gssapitrustdns

to install (install homebrew then):

$ brew install  rdp/homebrew-openssh-gssapi/openssh --enable-gssapi-support

The reason this is a "tap" is that Homebrew "main" are reluctant to apply this patch since it isn't included in OS X main:

https://github.com/Homebrew/homebrew-dupes/pull/583

however almost *every distro* and it has a "generally good security history"
https://sources.debian.net/patches/openssh/1:7.5p1-5/
so I'm OK with it, providing it here.

Patches/pull requests welcome (ex: to update to a newer openssh version, currently at 7.5p1, the latest as of at least sep 27 2017).


Based loosely on the following:
https://sources.debian.net/patches/openssh/1:7.5p1-5/
https://github.com/macports/macports-ports/blob/master/net/openssh/Portfile
https://github.com/Homebrew/homebrew-dupes/pull/583
