#!/bin/bash

# Create a symlink for server files so they're accessible from the file manager
if [ ! -L "/AMP/killinuxfloor/server" ]; then
    ln -s /home/amp /AMP/killinuxfloor/server
fi


