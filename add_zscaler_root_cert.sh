#!/usr/bin/env bash

# Fetch the Zscaler root certificate
sudo curl -K -s -o /usr/local/share/ca-certificates/ZscalerRootCA.crt https://raw.githubusercontent.com/TerrorSquad/ansible-post-installation/master/post-installation/defaults/ZscalerRootCA.crt
# Add Zscaler root certificate to the system trust store
sudo update-ca-certificates
