#!/bin/bash

#-----------------------------------------------------------
# Retrieve gfs v14 data from hpss.
#
# v14 data starts July 19, 2017 at 12z
#-----------------------------------------------------------

bundle=$1

set -x

cdate=2019070718
cyy=`echo ${cdate} | cut -c1-4`
cmm=`echo ${cdate} | cut -c5-6`
cdd=`echo ${cdate} | cut -c7-8`
chh=`echo ${cdate} | cut -c9-10`

datadir=/scratch1/BMC/chem-var/MAPP_2018/bhuang/BackupGdas/v15/${cdate}/
srcdir=${datadir}/tmp/enkf/enkfgdas.${cyy}${cmm}${cdd}/${chh}/
detdir=${datadir}/enkfgdas.${cyy}${cmm}${cdd}/${chh}/

ms=61
me=70

cd ${detdir}
mm=${ms}
while [ ${mm} -le ${me} ]; do
  if [ ${mm} -lt 10 ]; then
    memdet="00${mm}"
  else
    memdet="0${mm}"
  fi
  echo ${mm}

  dir1=${srcdir}/mem${memdet}/RESTART/
  dir2=${detdir}/mem${memdet}/RESTART/

  mkdir -p ${dir2}
  mv ${dir1}/*sfcanl_data.tile*.nc ${dir2}/
  #ls ${dir1}/*sfcanl_data.tile1.nc
  echo ${dir2}
  mm=$(( ${mm} + 1 ))
done

exit 0
