#!/bin/bash

RORUNCMD="/apps/rocoto/1.3.6/bin/rocotorun"
XMLDIR="/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/CHGRESGDAS/v14"
DBDIR="/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/CHGRES_GDAS_v14"

TASKS="
	chgres_v14
"

for TASK in ${TASKS}; do
    echo "${RORUNCMD} -w ${XMLDIR}/${TASK}.xml -d ${DBDIR}/${TASK}.db"
    ${RORUNCMD} -w ${XMLDIR}/${TASK}.xml -d ${DBDIR}/${TASK}.db
done
