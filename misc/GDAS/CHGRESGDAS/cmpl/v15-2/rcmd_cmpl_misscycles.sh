#!/bin/bash


GFSVER="v15"
CYCLE=2020062412
MISSRECORD="/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/CHGRESGDAS/${GFSVER}/record.chgres_hpss_htar_allmissing_${GFSVER}"
XMLDIR="/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/CHGRESGDAS/${GFSVER}"
DBDIR="/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/CHGRES_GDAS_${GFSVER}"

TASKS="
	chgres_${GFSVER}
"
echo ${CYCLE} >> ${MISSRECORD}
RORUNCMD="/apps/rocoto/1.3.3/bin/rocotocomplete"
${RORUNCMD} -w ${XMLDIR}/chgres_${GFSVER}.xml -d ${DBDIR}/chgres_${GFSVER}.db -c ${CYCLE}00 -t hpss2hera
${RORUNCMD} -w ${XMLDIR}/chgres_${GFSVER}.xml -d ${DBDIR}/chgres_${GFSVER}.db -c ${CYCLE}00 -m echgres
${RORUNCMD} -w ${XMLDIR}/chgres_${GFSVER}.xml -d ${DBDIR}/chgres_${GFSVER}.db -c ${CYCLE}00 -t hera2hpss

#for TASK in ${TASKS}; do
#    echo "Run ${TASK}"
#    ${RORUNCMD} -w ${XMLDIR}/${TASK}.xml -d ${DBDIR}/${TASK}.db
#done
