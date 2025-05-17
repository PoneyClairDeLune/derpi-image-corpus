#!/bin/bash
mkdir -p run
# Setup romigrou/ssim
#echo "Building the SSIM metric CLI util..."
#git clone https://github.com/romigrou/ssim.git
#cd ssim
#make rmgr-ssim-cli
# Setup kornelski/dssim
echo "Installing DSSIM..."
if [ ! -f "$(which dssim)" ]; then
	curl -Lo dssim.deb https://github.com/kornelski/dssim/releases/download/3.2.3/dssim_3.2.3_amd64.deb
	sudo dpkg -i dssim.deb
fi
echo "Installing Grok J2K..."
if [ ! -f "$(which grk_compress)" ]; then
	sudo apt install -y grokj2k-tools
fi
if [ ! -f "./run/dssim" ]; then
	ln -s "$(which dssim)" run/dssim
fi
exit
