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
    sed -i '34d' ./roles/install/tasks/steam.yml && \
    sed -i '15d' ./roles/install/tasks/main.yml && \
    echo y | ./install.sh --extra-vars 'skip_kfgame=true'

# Rename the 'steam' user to 'amp' and rename the home folder
RUN usermod -l amp steam && \
    usermod -d /home/amp -m amp && \
    adduser amp sudo

# Rename the steam group to amp
RUN groupmod -n amp steam

# Add amp to sudoers for specific commands
RUN echo 'amp ALL=NOPASSWD: /bin/systemctl start kf2.service' >> /etc/sudoers && \
    echo 'amp ALL=NOPASSWD: /bin/systemctl stop kf2.service' >> /etc/sudoers && \
    echo 'amp ALL=NOPASSWD: /bin/systemctl restart kf2.service' >> /etc/sudoers && \
    echo 'amp ALL=NOPASSWD: /bin/systemctl status kf2.service' >> /etc/sudoers && \
    echo 'amp ALL=NOPASSWD: /bin/journalctl --system --unit=kf2.service --follow' >> /etc/sudoers && \
    echo 'amp ALL=NOPASSWD: /bin/systemctl daemon-reload' >> /etc/sudoers && \
    echo 'amp ALL=NOPASSWD: /usr/bin/firewall-cmd --get-log-denied' >> /etc/sudoers && \
    echo 'amp ALL=NOPASSWD: /usr/bin/firewall-cmd --set-log-denied=all' >> /etc/sudoers && \
    echo 'amp ALL=NOPASSWD: /usr/bin/firewall-cmd --set-log-denied=off' >> /etc/sudoers && \
    echo 'amp ALL=NOPASSWD: /usr/local/bin/check-log-throttling' >> /etc/sudoers

# Change the ownership of the /home/amp directory to amp user
RUN chown -R amp:amp /home/amp && \
    mkdir /AMP && \
    chown -R amp:amp /AMP && \
    chown amp:amp /etc/systemd/system/kf2.service.d/kf2.service.conf

USER amp
ENTRYPOINT ["/ampstart.sh"]
CMD []