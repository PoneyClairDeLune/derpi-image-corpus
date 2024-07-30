#!/bin/bash
# Setup romigrou/ssim
#echo "Building the SSIM metric CLI util..."
#git clone https://github.com/romigrou/ssim.git
#cd ssim
#make rmgr-ssim-cli
# Setup kornelski/dssim
echo "Installing DSSIM..."
curl -Lo dssim.deb https://github.com/kornelski/dssim/releases/download/3.2.3/dssim_3.2.3_amd64.deb
sudo dpkg -i dssim.deb
exit
