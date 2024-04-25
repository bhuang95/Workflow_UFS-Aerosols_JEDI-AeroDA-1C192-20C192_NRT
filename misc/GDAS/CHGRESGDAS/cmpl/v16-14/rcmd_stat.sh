#!/bin/bash
set -x
RORUNCMD="/apps/rocoto/1.3.6/bin/rocotostat"
ITASK=14
XMLDIR="/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/CHGRESGDAS/v16-${ITASK}"
#DBDIR="/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/CHGRES_GDAS_v16"
DBDIR="/scratch1/NCEPDEV/rstprod/Bo.Huang/ChgresGDAS/CHGRES_GDAS_v16"

/apps/rocoto/1.3.6/bin/rocotostat -w ${XMLDIR}/chgres_v16-${ITASK}.xml -d ${DBDIR}/chgres_v16-${ITASK}.db | less

#TASKS="
#	chgres_v16
#"

#/apps/rocoto/1.3.6/bin/rocotostat -w /home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/CHGRESGDAS/v16/chgres_v16.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/CHGRES_GDAS_v16/chgres_v16.db | less

#for TASK in ${TASKS}; do
#    echo "Run ${TASK}"
#    ${RORUNCMD} -w ${XMLDIR}/${TASK}.xml -d ${DBDIR}/${TASK}.db
#done
