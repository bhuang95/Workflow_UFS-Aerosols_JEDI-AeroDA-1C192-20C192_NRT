#!/bin/bash

set -x
RORUNCMD="/apps/rocoto/1.3.6/bin/rocotostat"
ITASK=6
XMLDIR="/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/CHGRESGDAS/v15-${ITASK}"
#DBDIR="/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/CHGRES_GDAS_v15"
DBDIR="/scratch1/NCEPDEV/rstprod/Bo.Huang/ChgresGDAS/CHGRES_GDAS_v15"

/apps/rocoto/1.3.6/bin/rocotostat -w ${XMLDIR}/chgres_v15-${ITASK}.xml -d ${DBDIR}/chgres_v15-${ITASK}.db | less

#TASKS="
#	chgres_v15
#"

#/apps/rocoto/1.3.6/bin/rocotostat -w /home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/CHGRESGDAS/v15/chgres_v15.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/CHGRES_GDAS_v15/chgres_v15.db | less

#for TASK in ${TASKS}; do
#    echo "Run ${TASK}"
#    ${RORUNCMD} -w ${XMLDIR}/${TASK}.xml -d ${DBDIR}/${TASK}.db
#done
