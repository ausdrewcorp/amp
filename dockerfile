FROM cubecoders/ampbase

RUN apt-get update && apt-get -y upgrade && \
    apt install git -y && \
    git clone https://github.com/noobient/killinuxfloor.git && \
    cd killinuxfloor && \
    ./install.sh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/ampstart.sh"]
CMD []
