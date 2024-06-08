#!/bin/bash

# Create a symlink for server files so they're accessible from the file manager
if [ ! -L "/AMP/killinuxfloor/server" ]; then
    ln -s /home/amp /AMP/killinuxfloor/server
fi

cp -aP /home/steam/* /home/amp/
chown -R amp:amp /home/amp 

cd /home/amp && \
find . -type l -exec bash -c 'ln -sfn "/home/amp$(readlink {} | cut -c12-)" {}' \; && \
chown -R amp:amp /home/amp 