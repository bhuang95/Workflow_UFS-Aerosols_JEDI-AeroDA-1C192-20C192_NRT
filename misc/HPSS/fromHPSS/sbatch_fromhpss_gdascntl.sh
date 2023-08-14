#!/bin/bash --login
#SBATCH -J hera2hpss
#SBATCH -A chem-var
#SBATCH -n 1
#SBATCH -t 24:00:00
#SBATCH -p service
#SBATCH -D ./
#SBATCH -o /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/logs/hpss2hera_gdasmet_cntl.out
#SBATCH -e /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/logs/hpss2hera_gdasmet_cntl.out

set -x
# Back up cycled data to HPSS at ${CDATE}-6 cycle

module load hpss

HERADIR=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata_UFS-Aerosols/GDASAnl/
HPSSDIR=/BMC/fim/5year/MAPP_2018/bhuang/UFS-Aerosols-expRuns/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-data/
CASE_CNTL=C192

SDATE=2023081000
EDATE=2023081006
CYCINTHR=6

NDATE="/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"

CDATE=${SDATE}

while [ ${CDATE} -le ${EDATE} ]; do
    CY=${CDATE:0:4}
    CM=${CDATE:4:2}
    CD=${CDATE:6:2}
    CH=${CDATE:8:2}
    CYMD=${CDATE:0:8}

    ORGDIR=${HPSSDIR}/${CY}/${CY}${CM}/${CYMD}/
    ORGFILE=gdasmet_cntl.${CDATE}.tar  

    TGTDIR=${HERADIR}/${CASE_CNTL}/gdas.${CYMD}/${CH}

    if [ ! -d ${TGTDIR} ]; then
	echo ${TGTDIR}
	echo ${ORGDIR}/${ORGFILE}
        mkdir -p ${TGTDIR}
	cd ${TGTDIR}
	htar -xvf ${ORGDIR}/${ORGFILE}
    fi
    CDATE=$(${NDATE} ${CYCINTHR} ${CDATE})
done

