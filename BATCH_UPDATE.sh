#!/bin/sh

mkdir logs >& /dev/null
log=log.`date +%Y%m%d.%H%M`
ln -sf $log logs/log
make update > logs/$log 2>&1
