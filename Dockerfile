## Dockerfile for apg.pl
## 
FROM        archlinux
LABEL       maintainer="wn@neessen.net"
RUN         pacman -Sy --noconfirm --noprogressbar
RUN         pacman -S --noconfirm --noprogressbar gcc make cpanminus glibc
RUN         /usr/bin/vendor_perl/cpanm CryptX
RUN         pacman -Rs --noconfirm --noprogressbar gcc make cpanminus
RUN         /usr/bin/groupadd -r apg && /usr/bin/useradd -r -g apg -c "apg.pl user" -m -s /bin/bash -d /opt/apg apg
COPY        ["LICENSE", "README.md", "apg.pl", "/opt/apg/"]
RUN         chown -R apg:apg /opt/apg
WORKDIR     /opt/apg
USER        apg
ENTRYPOINT  ["/usr/bin/perl", "apg.pl"]