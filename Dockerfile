FROM docker.io/library/debian:bullseye
LABEL name="starfive-visionfive2"
LABEL url="https://gitlab.com/thomasdstewart/starfive-visionfive2"
LABEL maintainer="thomas@stewarts.org.uk"

RUN apt-get update && \
    apt-get -y --no-install-recommends install vmdb2 dosfstools qemu-utils qemu-user-static debootstrap binfmt-support time kpartx bmap-tools python3 fakemachine ca-certificates wget unzip && \
    apt-get clean && \
    rm -rf ./install.sh /var/lib/apt/lists/*

COPY build.sh /
CMD ["/build.sh"]
