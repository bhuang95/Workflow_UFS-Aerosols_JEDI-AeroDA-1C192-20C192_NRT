#!/bin/bash

#-----------------------------------------------------------
# Retrieve gfs v14 data from hpss.
#
# v14 data starts July 19, 2017 at 12z
#-----------------------------------------------------------

bundle=$1

set -x

srcdir=/scratch1/BMC/chem-var/MAPP_2018/bhuang/BackupGdas/v14/2017113018/temp/enkf/
detdir=/scratch1/BMC/chem-var/MAPP_2018/bhuang/BackupGdas/v14/2017113018/enkfgdas.20171130/18/


cd ${detdir}
MEMBER=1
while [ $MEMBER -le 80 ]; do
  if [ $MEMBER -lt 10 ]; then
    MEMBER_CH="00${MEMBER}"
  else
    MEMBER_CH="0${MEMBER}"
  fi
  echo ${MEMBER_CH}
  mkdir -p mem${MEMBER_CH}
  mv ${srcdir}/*.mem${MEMBER_CH}* ./mem${MEMBER_CH}
  MEMBER=$(( $MEMBER + 1 ))
done

exit 0
