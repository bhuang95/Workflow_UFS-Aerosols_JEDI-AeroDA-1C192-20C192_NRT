#!/bin/bash

TOPDIR=/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/CHGRESGDAS
SRC=v16-6

DETS="
v16-7
v16-8
v16-9
v16-10
v16-11
v16-12
v16-13
v16-14
"

for DET in ${DETS}; do
    SRCDIR=${TOPDIR}/${SRC}
    DETDIR=${TOPDIR}/${DET}

    cp -r ${SRCDIR} ${DETDIR}
    cd ${DETDIR}
    mv chgres_${SRC}.xml chgres_${DET}.xml
    mv crontab_chgres_${SRC}.sh crontab_chgres_${DET}.sh
done
