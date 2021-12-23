#!/bin/bash

echo -n -e "Fetching buildroot source... \t\t\t"

if [[ -d buildroot ]]; then
	echo "done!"
else
	git clone https://github.com/buildroot/buildroot.git
fi

echo -n -e "Fetching kernel 5.15.11 ... \t\t\t"
if [[ -d linux ]]; then
	echo "done!"
else
	echo -n -e "\tstart download ... \t\t\t"
	curl "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.11.tar.xz"
	echo -n -e "\tdownload complete ... \t\t\t"
	echo -n -e "\tstart unzip... \t\t\t"
	mkdir -p linux
	tar -xf "linux-5.15.11.tar.xz" -C linux
	echo -n -e "\tunzip complete ... \t\t\t"
fi


