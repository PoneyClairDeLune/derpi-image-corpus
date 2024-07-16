#!/bin/bash
# Setup romigrou/ssim
echo "Building the SSIM metric CLI util..."
git clone https://github.com/romigrou/ssim.git
cd ssim
make rmgr-ssim-cli
exit
