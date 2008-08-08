#!/bin/sh
# 1) Copy everything into ~/.gmail_boomerang
mkdir ~/.gmail_boomerang
cp -r * ~/.gmail_boomerang/
chmod +x ~/.gmail_boomerang/*.rb
# 2) Install the crontab
cat crontab.txt | crontab
echo "GmailBoomerang is installed! Enjoy!"
