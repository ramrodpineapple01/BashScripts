#!/bin/bash

clear

read -p "Enter web url to download: " WEB_URL

wget --save-cookies cookies.txt \
     --keep-session-cookies \
     --post-data 'user=foo&password=bar' \
     --delete-after \
     ${WEB_URL}

wget \
	 --load-cookies cookies.txt \
     --recursive \
     --no-clobber \
     --page-requisites \
     --html-extension \
     --convert-links \
     --restrict-file-names=windows \
     --domains website.org \
     --no-parent \
         ${WEB_URL}