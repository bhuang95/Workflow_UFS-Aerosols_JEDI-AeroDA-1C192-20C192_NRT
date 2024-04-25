#!/bin/bash

set -x
ITASK=7
RORUNCMD="/apps/rocoto/1.3.6/bin/rocotorun"
XMLDIR="/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/CHGRESGDAS/v15-${ITASK}/"
#DBDIR="/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/CHGRES_GDAS_v15"
DBDIR="/scratch1/NCEPDEV/rstprod/Bo.Huang/ChgresGDAS/CHGRES_GDAS_v15"

TASKS="
	chgres_v15
"

for TASK in ${TASKS}; do
    echo "Run ${TASK}"
    ${RORUNCMD} -w ${XMLDIR}/${TASK}-${ITASK}.xml -d ${DBDIR}/${TASK}-${ITASK}.db
done