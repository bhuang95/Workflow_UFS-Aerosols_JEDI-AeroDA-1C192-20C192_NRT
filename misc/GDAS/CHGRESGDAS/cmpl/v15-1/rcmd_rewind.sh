#!/bin/bash
GFSVER="v15"
CYCLE=2020061306
MISSRECORD="/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/CHGRESGDAS/${GFSVER}/record.chgres_hpss_htar_allmissing_${GFSVER}"
XMLDIR="/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/CHGRESGDAS/${GFSVER}"
DBDIR="/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/CHGRES_GDAS_${GFSVER}"


TASKS="
	hpss2hera
"

RORUNCMD="/apps/rocoto/1.3.3/bin/rocotorewind"
for TASK in ${TASKS}; do
    ${RORUNCMD} -w ${XMLDIR}/chgres_${GFSVER}.xml -d ${DBDIR}/chgres_${GFSVER}.db -c ${CYCLE}00 -t ${TASK}
done

RORUNCMD="/apps/rocoto/1.3.3/bin/rocotoboot"
for TASK in ${TASKS}; do
    ${RORUNCMD} -w ${XMLDIR}/chgres_${GFSVER}.xml -d ${DBDIR}/chgres_${GFSVER}.db -c ${CYCLE}00 -t ${TASK}
done




/apps/rocoto/1.3.3/bin/rocotostat -w /home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/CHGRESGDAS/v15/chgres_v15.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/CHGRES_GDAS_v15/chgres_v15.db | less

#for TASK in ${TASKS}; do
#    echo "Run ${TASK}"
#    ${RORUNCMD} -w ${XMLDIR}/${TASK}.xml -d ${DBDIR}/${TASK}.db
#done
