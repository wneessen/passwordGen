## Dockerfile for apg.pl
## 
FROM        archlinux:latest
LABEL       maintainer="wn@neessen.net"

# WORKAROUND for glibc 2.33 and old Docker
# See https://github.com/actions/virtual-environments/issues/2658
# Thanks to https://github.com/lxqt/lxqt-panel/pull/1562
RUN			patched_glibc=glibc-linux4-2.33-4-x86_64.pkg.tar.zst && \
			curl -LO "https://repo.archlinuxcn.org/x86_64/$patched_glibc" && \
			bsdtar -C / -xvf "$patched_glibc"
RUN         pacman -Sy --noconfirm --noprogressbar
RUN         pacman -S --noconfirm --noprogressbar gcc make cpanminus glibc

RUN         /usr/bin/vendor_perl/cpanm CryptX

# Apparently this is needed twice
RUN			patched_glibc=glibc-linux4-2.33-4-x86_64.pkg.tar.zst && \
			curl -LO "https://repo.archlinuxcn.org/x86_64/$patched_glibc" && \
			bsdtar -C / -xvf "$patched_glibc"
RUN         pacman -Rs --noconfirm --noprogressbar gcc make

RUN         /usr/bin/groupadd -r apg && /usr/bin/useradd -r -g apg -c "apg.pl user" -m -s /bin/bash -d /opt/apg apg
COPY        ["LICENSE", "README.md", "apg.pl", "/opt/apg/"]
RUN         chown -R apg:apg /opt/apg
WORKDIR     /opt/apg
USER        apg
ENTRYPOINT  ["/usr/bin/env", "LC_ALL=C", "/usr/bin/perl", "apg.pl"]
