#!/bin/bash
#SBATCH -N 1
#SBATCH -t 00:30:00
#SBATCH -q debug
#SBATCH -A chem-var
#SBATCH -J calc_aeronet_hfx
#SBATCH -D ./
#SBATCH -o /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/tmprun/aeronet_hofx.log
#SBATCH -e /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/tmprun/aeronet_hofx.log


ROTDIR_BH=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/
ROTDIR_MP=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/Mariusz.Pagowski/expRuns/

EXPNAMES="RET_AeroDA_YesEmisStoch-CNTL-ENKF_C96_202006_bc1.5"
SDATE=2020060100
EDATE=2020062400
LASTCYC=20171016180
CYCINC=24
NDATE='/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate'

for EXPNAME in ${EXPNAMES}; do
    BACKUP_BH=${ROTDIR_BH}/${EXPNAME}/dr-data-longfcst-backup

    CDATE=${SDATE}
    while [ ${CDATE} -le ${EDATE} ]; do
	if [ ${CDATE} -eq ${LASTCYC} ]; then 
            BACKUP_MP=${ROTDIR_MP}/${EXPNAME}/dr-data
	else
            BACKUP_MP=${ROTDIR_MP}/${EXPNAME}/dr-data-longfcst-backup
	fi
        echo ${CDATE}
        CYMD=${CDATE:0:8}
        CY=${CDATE:0:4}
        CM=${CDATE:4:2}
        CD=${CDATE:6:2}
        CH=${CDATE:8:2}

        DATA_BH=${BACKUP_BH}/gdas.${CYMD}/${CH}/atmos
        DATA_MP=${BACKUP_MP}/gdas.${CYMD}/${CH}/atmos
	[[ ! -d ${DATA_BH} ]] && mkdir -p ${DATA_BH}
        rm -rf ${DATA_BH}/atmos/*
	echo ${DATA_MP}
	echo ${DATA_BH}
        ln -sf ${DATA_MP}/* ${DATA_BH}/

if [  0 -eq 1 ]; then
	if [ ${CDATE} -eq ${LASTCYC} ]; then 
            DATA_BH=${BACKUP_BH}/gdas.${CYMD}/${CH}/diag/aod_obs
            DATA_MP=${BACKUP_MP}/gdas.${CYMD}/${CH}/diag/
	else
            DATA_BH=${BACKUP_BH}/gdas.${CYMD}/${CH}/diag/aod_obs
            DATA_MP=${BACKUP_MP}/gdas.${CYMD}/${CH}/diag/aod_obs
	fi
	[[ ! -d ${DATA_BH} ]] && mkdir -p ${DATA_BH}
	echo ${DATA_MP}
	echo ${DATA_BH}
        cp -r ${DATA_MP}/* ${DATA_BH}/

	if [ ${CDATE} -eq ${LASTCYC} ]; then 
            DATA_BH=${BACKUP_BH}/enkfgdas.${CYMD}/${CH}/diag/aod_obs
            DATA_MP=${BACKUP_MP}/enkfgdas.${CYMD}/${CH}/diag/
	else
            DATA_BH=${BACKUP_BH}/enkfgdas.${CYMD}/${CH}/diag/aod_obs
            DATA_MP=${BACKUP_MP}/enkfgdas.${CYMD}/${CH}/diag/aod_obs
        fi
	[[ ! -d ${DATA_BH} ]] && mkdir -p ${DATA_BH}
	echo ${DATA_MP}
	echo ${DATA_BH}
        cp -r ${DATA_MP}/* ${DATA_BH}/
fi
        CDATE=$(${NDATE} ${CYCINC} ${CDATE})
    done
done
###############################################################
# Postprocessing
#mkdata="YES"
#[[ $mkdata = "YES" ]] && rm -rf ${DATA1}

#set +x
exit 0
