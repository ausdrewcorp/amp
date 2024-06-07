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

# Assuming 'amp' user is already created, if not, create it
RUN useradd -m amp && echo "amp:amp" | chpasswd && adduser amp sudo

# Add amp to sudoers
RUN echo 'amp ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN mkdir -p /AMP/killinuxfloor && \
    ln -s /home/amp /AMP/killinuxfloor/KF2

# Change the ownership of the /home/steam directory to amp user
RUN chown -R amp:amp /home/steam && \
    chown -R amp:amp /AMP && \
    chown amp:amp /etc/systemd/system/kf2.service.d/kf2.service.conf

ENTRYPOINT ["/ampstart.sh"]
CMD []