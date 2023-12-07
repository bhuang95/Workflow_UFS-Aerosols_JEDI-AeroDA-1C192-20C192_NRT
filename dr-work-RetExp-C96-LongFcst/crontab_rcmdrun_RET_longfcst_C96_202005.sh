#!/bin/bash

#rocotostat -w /home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work-RetExp/RET_ENKF_AEROSEMIS-ON_STOCHINIT-OFF-201710.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/ENKF_AEROSEMIS-ON_STOCHINIT-OFF-201710/dr-work/RET_ENKF_AEROSEMIS-ON_STOCHINIT-OFF-201710.db

RORUNCMD="/apps/rocoto/1.3.3/bin/rocotorun"
XMLDIR="/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work-RetExp-C96-LongFcst"
DBDIR="/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/"

EXPS="
	RET_AeroDA_NoEmisStoch_C96_202006
"
	#RET_FreeRun_NoEmisStoch_C96_202006

for EXP in ${EXPS}; do
    echo "${RORUNCMD} -w ${XMLDIR}/${EXP}_LongFcst.xml -d ${DBDIR}/${EXP}/dr-work-longfcst/${EXP}_LongFcst.db"
    ${RORUNCMD} -w ${XMLDIR}/${EXP}_LongFcst.xml -d ${DBDIR}/${EXP}/dr-work-longfcst/${EXP}_LongFcst.db
    echo "${RORUNCMD} -w ${XMLDIR}/${EXP}_LongFcst_Diag.xml -d ${DBDIR}/${EXP}/dr-work-longfcst/${EXP}_LongFcst_Diag.db"
    ${RORUNCMD} -w ${XMLDIR}/${EXP}_LongFcst_Diag.xml -d ${DBDIR}/${EXP}/dr-work-longfcst/${EXP}_LongFcst_Diag.db
done

#TASKS="
#       RET_ENKF_AEROSEMIS-ON_STOCHINIT-OFF-201710
#       "
#
#       #NRT-prepEmis 
#       #NRT-prepGDAS 
#       #NRT-freeRun 
#       #NRT-aeroDA
#       #NRT-postDiag-aodObs-freeRun
#       #NRT-postDiag-aodObs-aeroDA
#for TASK in ${TASKS}; do
#    echo "Run ${TASK}"
#    ${RORUNCMD} -w ${XMLDIR_DA}/${TASK}.xml -d ${DBDIR_DA}/${TASK}.db
#done
