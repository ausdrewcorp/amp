FROM cubecoders/ampbase:python3

RUN apt-get update && apt-get install -y sudo git apt software-properties-common python3-launchpadlib locales locales-all && \
    apt-get update && apt-get upgrade -y

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen

ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8     

RUN git clone https://github.com/noobient/killinuxfloor.git && \
    cd killinuxfloor && \
    sed -i '34d' ./roles/install/tasks/steam.yml && \
    sed -i '15d' ./roles/install/tasks/main.yml && \
    echo y | ./install.sh --extra-vars 'skip_kfgame=true'

RUN ln -s /home/steam /AMP/killinuxfloor

# Change the ownership of the /home/steam directory to amp user
RUN chown -R amp:amp /home/steam

ENTRYPOINT ["/ampstart.sh"]
CMD []