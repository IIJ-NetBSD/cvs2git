#!/bin/sh

mkdir logs > /dev/null 2>&1
log=log.`date +%Y%m%d.%H%M`
ln -sf $log logs/log
make update > logs/$log 2>&1
