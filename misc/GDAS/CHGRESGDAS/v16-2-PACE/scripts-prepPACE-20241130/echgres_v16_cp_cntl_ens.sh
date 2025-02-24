#! /usr/bin/env bash
##SBATCH -N 4
##SBATCH -t 00:30:00
##SBATCH -q debug
##SBATCH -A chem-var
##SBATCH -J fgat
##SBATCH -D ./
##SBATCH -o ./bump_gfs_c96.out
##SBATCH -e ./bump_gfs_c96.out

export HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT"}
export ROTDIR=${ROTDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/CHGRES_GDAS_v16/dr-data"}


export CDATE=${CDATE:-"2021032100"}
export LEVS=${LEVS:-"128"}
export ENSGRP=${ENSGRP:-"01"}
export NMEM_EFCSGRP=${NMEM_EFCSGRP:-"5"}
export NMEMSPROED=${NMEMSPROED:-"40"}
export CASE_CNTL=${CASE_CNTL:-"C96"}
export CASE_ENKF=${CASE_ENKF:-"C96"}
export CASE_CNTL_OPE=${CASE_CNTL_OPE:-"C384"}
export CASE_ENKF_OPE=${CASE_ENKF_OPE:-"C384"}

export CYCINTHR=6
export NDATE="/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"
FHR="06"

ENSED=$((${NMEM_EFCSGRP} * 10#${ENSGRP}))

if [ ${ENSED} -gt ${NMEMSPROED} ]; then
    echo "Exceed maximum ensemble size and exit."
    exit 100
fi

if [ ${ENSGRP} = "01" ]; then
    ENSST=0
else
    ENSST=$((ENSED - NMEM_EFCSGRP + 1))
fi
GDATE=$(${NDATE} -${CYCINTHR} ${CDATE})

ENSST=1
ENSED=40

CYMD=${CDATE:0:8}
CY=${CDATE:0:4}
CM=${CDATE:4:2}
CD=${CDATE:6:2}
CH=${CDATE:8:2}

GYMD=${GDATE:0:8}
GY=${GDATE:0:4}
GM=${GDATE:4:2}
GD=${GDATE:6:2}
GH=${GDATE:8:2}

NCP="/bin/cp -r"
NMV="/bin/mv -f"
NRM="/bin/rm -rf"
NLN="/bin/ln -sf"

DATA=${ROTDIR}/tmp/echgres_grp${ENSGRP}
[[ -d ${DATA} ]] && ${NRM}  ${DATA}
mkdir -p ${DATA} 

GDASDIR=${ROTDIR}
GDASCNTLIN=${GDASDIR}/gdas.${CDATE}/INPUT
GDASCNTLOUT1=${GDASDIR}/gdas.${CDATE}/OUTPUT_NC
GDASCNTLOUT2=${GDASDIR}/gdas.${CDATE}/OUTPUT_NC_CHGRES

GDASENKFIN=${GDASDIR}/enkfgdas.${CDATE}/INPUT
GDASENKFIN_GES=${GDASDIR}/enkfgdas.${GDATE}/INPUT
GDASENKFOUT1=${GDASDIR}/enkfgdas.${CDATE}/OUTPUT_NC
GDASENKFOUT2=${GDASDIR}/enkfgdas.${CDATE}/OUTPUT_NC_CHGRES

[[ ! -d ${GDASDIR} ]] && mkdir -p ${GDASDIR}
[[ ! -d ${GDASCNTLIN} ]] && mkdir -p ${GDASCNTLIN}
[[ ! -d ${GDASCNTLOUT1} ]] && mkdir -p ${GDASCNTLOUT1}
[[ ! -d ${GDASCNTLOUT2} ]] && mkdir -p ${GDASCNTLOUT2}

[[ ! -d ${GDASENKFIN} ]] && mkdir -p ${GDASENKFIN}
[[ ! -d ${GDASENKFIN_GES} ]] && mkdir -p ${GDASENKFIN_GES}
[[ ! -d ${GDASENKFOUT1} ]] && mkdir -p ${GDASENKFOUT1}
[[ ! -d ${GDASENKFOUT2} ]] && mkdir -p ${GDASENKFOUT2}

set -x

#Run NEMSIO2NC
IMEM=${ENSST}
CNTL_RST=${GDASCNTLOUT2}/RESTART
CNTL_ATM=${GDASCNTLOUT2}/gdas.t${CH}z.atmanl.${CASE_CNTL}.nc
while [ ${IMEM} -le ${ENSED} ]; do
    MEMSTR="mem"`printf %03d ${IMEM}`
    ENS_ATM=${GDASENKFOUT2}/${MEMSTR}/gdas.t${CH}z.ratmanl.${MEMSTR}.${CASE_ENKF}.nc
    ENS_RST=${GDASENKFOUT2}/${MEMSTR}/RESTART

    [[ ! -d ${ENS_RST} ]] && mkdir -p ${ENS_RST}


    ${NCP} ${CNTL_ATM} ${ENS_ATM}
    ${NCP} ${CNTL_RST}/* ${ENS_RST}/

    IMEM=$((IMEM+1))
done
exit
