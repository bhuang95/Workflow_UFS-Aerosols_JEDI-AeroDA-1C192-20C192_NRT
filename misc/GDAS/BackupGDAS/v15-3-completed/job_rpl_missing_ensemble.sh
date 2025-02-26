#!/bin/bash

#-----------------------------------------------------------
# Retrieve gfs v14 data from hpss.
#
# v14 data starts July 19, 2017 at 12z
#-----------------------------------------------------------

#bundle=$1
#
#set -x

cdate=2020052418
cyy=`echo ${cdate} | cut -c1-4`
cmm=`echo ${cdate} | cut -c5-6`
cdd=`echo ${cdate} | cut -c7-8`
chh=`echo ${cdate} | cut -c9-10`

datadir=/scratch1/BMC/chem-var/MAPP_2018/bhuang/BackupGdas/v15-3/${cdate}/
detdir=${datadir}/enkfgdas.${cyy}${cmm}${cdd}/${chh}/

ms=61
me=70
inc=-60

cd ${detdir}
mm=${ms}
while [ ${mm} -le ${me} ]; do
  #if [ ${mm} -lt 10 ]; then
  #  memdet="00${mm}"
  #else
  #  memdet="0${mm}"
  #fi
  #echo ${mm}
  mmsrc=$(( ${mm} + ${inc} ))
  memdet=$(printf "%03d" ${mm})
  memsrc=$(printf "%03d" ${mmsrc})

  filesrc=mem${memsrc}
  filedet=mem${memdet}

  echo ${filesrc}
  echo ${filedet}
  echo ${detdir}
  echo "*************"
  if [ -d ${filedet} ]; then
      rm -rf ${filedet}
  fi

  cp -r ${filesrc} ${filedet}

  mm=$(( ${mm} + 1 ))
done

exit 0
