#!/bin/bash
set -x

RORUNCMD="/apps/rocoto/1.3.6/bin/rocotorun"
XMLDIR="/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/CHGRESGDAS/"
TASKS="
 v16-2-PACE
"
#    v16-6
#    v16-7
#    v16-8
#   v16-9
#    v16-10
#    v16-11
#    v16-12
#    v16-13
#    v16-14
for TASK in ${TASKS}; do
    echo "Run ${TASK}"
${XMLDIR}/${TASK}/crontab_chgres_${TASK}.sh
done
