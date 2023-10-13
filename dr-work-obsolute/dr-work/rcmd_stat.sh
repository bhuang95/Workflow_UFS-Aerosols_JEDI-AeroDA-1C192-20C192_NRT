#!/bin/bash
set -x

ROSTATCMD="/apps/rocoto/1.3.3/bin/rocotostat"
XMLDIR_DA="/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work"
DBDIR_DA="/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work"

TASK=$1

### Prep emission files (gbbepx, ceds, megan)
echo "Prep emission files (gbbepx, ceds, megan)"
${ROSTATCMD} -w ${XMLDIR_DA}/${TASK}.xml -d ${DBDIR_DA}/${TASK}.db | less
