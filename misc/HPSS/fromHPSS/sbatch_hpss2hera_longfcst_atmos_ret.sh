#!/bin/bash --login
#SBATCH -J hera2hpss
#SBATCH -A chem-var
#SBATCH -n 1
#SBATCH -t 24:00:00
#SBATCH -p service
#SBATCH -D ./
#SBATCH -o ./hera2hpss.out
#SBATCH -e ./hera2hpss.out

#set -x
# Back up cycled data to HPSS at ${CDATE}-6 cycle


ARCHHPSSDIR="/BMC/fim/5year/MAPP_2018/bhuang/UFS-Aerosols-expRuns/UFS-Aerosols_RETcyc/"
HOMEgfs="/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/"
ROTDIR="/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc//RET_FreeRun_NoEmisStoch_C96_202006/dr-data-longfcst-backup/"
PSLOT="RET_FreeRun_NoEmisStoch_C96_202006"
NDATE="/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"

module load hpss
#export PATH="/apps/hpss/bin:$PATH"
#set -x

SDATE=2020060100
EDATE=2020060500
CYCINTHR=24

NCP="/bin/cp -r"
NMV="/bin/mv -f"
NRM="/bin/rm -rf"
NLN="/bin/ln -sf"

CDATE=${SDATE}
while [ ${CDATE} -le ${EDATE} ]; do
    CY=${CDATE:0:4}
    CM=${CDATE:4:2}
    CD=${CDATE:6:2}
    CH=${CDATE:8:2}
    CYMD=${CDATE:0:8}

    DATAHPSSDIR=${ARCHHPSSDIR}/${PSLOT}/dr-data-longfcst-backup/${CY}/${CY}${CM}/${CYMD}/
    #hsi "mkdir -p ${DATAHPSSDIR}"
    #ERR=$?
    #if [ ${ERR} -ne 0 ]; then
    #    echo "*hsi mkdir* failed at ${CDATE}" >> ${HPSSRECORD}
    #    exit ${ERR}
    #fi


# Back up gdas cntl

    CNTLDIR_CDATE=${ROTDIR}/gdas.${CYMD}/${CH}
    CNTLDIR_ATMOS_CDATE=${CNTLDIR_CDATE}/atmos/
    CNTLDIR_DIAG_CDATE=${CNTLDIR_CDATE}/diag/

    [[ ! -d ${CNTLDIR_ATMOS_CDATE} ]] && mkdir -p ${CNTLDIR_ATMOS_CDATE}
    cd ${CNTLDIR_ATMOS_CDATE}
    TARFILE=${DATAHPSSDIR}/gdas.longfcst.atmos.${CDATE}.tar
    echo ${TARFILE}
    echo ${CNTLDIR_ATMOS_CDATE}
    htar -xvf ${TARFILE} 
    ERR=$?
    if [ ${ERR} -ne 0 ]; then
        #echo "HTAR cntl restart data failed at ${CDATE}" >> ${HPSSRECORD}
        exit ${ERR}
    else
        echo "HTAR is complete and remove data"
    fi
    
    echo "${CNTLDIR_DIAG_CDATE}/aod_grid"
    mv ${CNTLDIR_DIAG_CDATE}/aod_grid ${CNTLDIR_DIAG_CDATE}/aod_grid_oldExe
    CDATE=$(${NDATE} ${CYCINTHR} ${CDATE})
done
