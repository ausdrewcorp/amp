FROM cubecoders/ampbase:python3

RUN apt-get update && apt-get install -y sudo git apt software-properties-common python3-launchpadlib locales locales-all && \
    apt-get update && apt-get upgrade -y

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
    ENV LANG en_US.UTF-8  
    ENV LANGUAGE en_US:en  
    ENV LC_ALL en_US.UTF-8     

COPY docker/systemctl3.py /usr/bin/systemctl
COPY docker/journalctl3.py /usr/bin/journalctl

RUN git clone https://github.com/noobient/killinuxfloor.git && \
    cd killinuxfloor && \
    sed -i 's/name: steam/name: amp/g' ./roles/install/tasks/user.yml && \
    find . -type f -exec sed -i 's/User=steam/User=amp/g' {} \; && \
    find . -type f -exec sed -i 's/Group=steam/Group=amp/g' {} \; && \
    find . -type f -exec sed -i 's/owner: steam/owner: amp/g' {} \; && \
    find . -type f -exec sed -i 's/group: steam/group: amp/g' {} \; && \
    find . -type f -exec sed -i 's|/home/steam|/home/amp|g' {} \; && \
    find . -type f -exec sed -i 's/become_user: steam/become_user: amp/g' {} \; && \
    sed -i '34d' ./roles/install/tasks/steam.yml && \
    sed -i '15d' ./roles/install/tasks/main.yml && \
    echo y | ./install.sh --extra-vars 'skip_kfgame=true steam_home=/home/amp'


# Copy /home/steam to /home/amp while preserving symbolic links
#RUN cp -aP /home/steam /home/amp && \
#    userdel steam && \
#    rm -rf /home/steam
#
## Update symbolic links to point to /home/amp instead of /home/steam
#RUN cd /home/amp && \
#    find . -type l -exec bash -c 'ln -sfn "/home/amp$(readlink {} | cut -c12-)" {}' \; && \
#    ls -la /home/amp

RUN deluser amp

ENTRYPOINT ["/ampstart.sh"]
CMD []