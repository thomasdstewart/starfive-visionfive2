#!/bin/sh
vmdb2 --verbose --output visionfive2.img visionfive2.yaml
cat visionfive2.img | xz -9 > visionfive2.img.xz
