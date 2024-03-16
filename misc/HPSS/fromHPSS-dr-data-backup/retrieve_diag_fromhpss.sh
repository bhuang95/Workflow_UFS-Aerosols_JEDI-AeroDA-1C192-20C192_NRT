#!/bin/bash --login
#SBATCH -J hera2hpss
#SBATCH -A chem-var
#SBATCH -n 1
#SBATCH -t 24:00:00
#SBATCH -p service
#SBATCH -D ./
#SBATCH -o ./hera2hpss.out
#SBATCH -e ./hera2hpss.out

set -x
# Back up cycled data to HPSS at ${CDATE}-6 cycle

source config_hpss2hera

NDATE="/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"

module load hpss
#export PATH="/apps/hpss/bin:$PATH"
set -x

NCP="/bin/cp -r"
NMV="/bin/mv -f"
NRM="/bin/rm -rf"
NLN="/bin/ln -sf"


CDATE=${SDATE}
while [ ${CDATE} -le ${EDATE} ]; do
CDATE=$(${NDATE} ${CYCINC} ${CDATE})
    CY=${CDATE:0:4}
    CM=${CDATE:4:2}
    CD=${CDATE:6:2}
    CH=${CDATE:8:2}
    CYMD=${CDATE:0:8}
    HPSSDIR=${HPSSEXP}/${CY}/${CY}${CM}/${CYMD}/

done
RMDATE=${GDATE}
RMDIR=${TMPDIR}/../${RMDATE}
RMREC=${RMDIR}/remove.record

if ( grep YES ${RMREC} ); then
    ${NRM} ${RMDIR}
fi

CY=${CDATE:0:4}
CM=${CDATE:4:2}
CD=${CDATE:6:2}
CH=${CDATE:8:2}
CYMD=${CDATE:0:8}

GY=${GDATE:0:4}
GM=${GDATE:4:2}
GD=${GDATE:6:2}
GH=${GDATE:8:2}
GYMD=${GDATE:0:8}

ICNT=0
DATAHPSSDIR=${ARCHHPSSDIR}/${PSLOT}/dr-data-backup/${CY}/${CY}${CM}/${CYMD}/
hsi "mkdir -p ${DATAHPSSDIR}"
ERR=$?
ICNT=$((${ICNT}+${ERR}))

# Back up gdas cntl
# Copy gridded reanalysis files
DIAGDIR=${ROTDIR}/gdas.${CYMD}/${CH}/diag/
REANLDIR=${ROTDIR}/GriddedReanl/${CY}/${CY}${CM}/${CYMD}
[[ ! -d ${REANLDIR} ]] && mkdir -p ${REANLDIR}

${NCP} ${DIAGDIR}/aod_grid/fv3_aod_LUTs_fv_tracer*.nc ${REANLDIR}
ERR=$?
ICNT=$((${ICNT}+${ERR}))
${NCP} ${DIAGDIR}/aeros_grid_ll/fv3_aeros_fv_tracer*.nc ${REANLDIR}
ERR=$?
ICNT=$((${ICNT}+${ERR}))
${NCP} ${DIAGDIR}/aeros_grid_pll/fv3_aeros_fv_tracer*.nc ${REANLDIR}
ERR=$?
ICNT=$((${ICNT}+${ERR}))

if [ ${AERODA} = "YES" ]; then
    cd ${REANLDIR}
    ANLORG=fv3_aod_LUTs_fv_tracer_aeroanl_${CDATE}_ll.nc
    ANLTGT=NARA-2.0_AOD_${CDATE}.nc
    ${NMV} ${ANLORG} ${ANLTGT}
    ${NLN} ${ANLTGT} ${ANLORG}
    ERR=$?
    ICNT=$((${ICNT}+${ERR}))

    ANLORG=fv3_aeros_fv_tracer_aeroanl_${CDATE}_ll.nc
    ANLTGT=NARA-2.0_AEROS_${CDATE}_LL.nc
    ${NMV} ${ANLORG} ${ANLTGT}
    ${NLN} ${ANLTGT} ${ANLORG}
    ERR=$?
    ICNT=$((${ICNT}+${ERR}))

    ANLORG=fv3_aeros_fv_tracer_aeroanl_${CDATE}_pll.nc
    ANLTGT=NARA-2.0_AEROS_${CDATE}_PLL.nc
    ${NMV} ${ANLORG} ${ANLTGT}
    ${NLN} ${ANLTGT} ${ANLORG}
    ERR=$?
    ICNT=$((${ICNT}+${ERR}))
fi

CNTLDIR=${ROTDIR}/gdas.${CYMD}/${CH}
CNTLDIR_ATMOS=${CNTLDIR}/model_data

cd ${CNTLDIR}
TARFILE=${DATAHPSSDIR}/gdas.${CDATE}.diag.tar
htar -P -cvf ${TARFILE} *
ERR=$?
ICNT=$((${ICNT}+${ERR}))

ENKFDIR=${ROTDIR}/enkfgdas.${CYMD}/${CH}

if [ ${AERODA} = "YES" ]; then
    cd ${ENKFDIR}
    TARFILE=${DATAHPSSDIR}/enkfgdas.${CDATE}.diag.tar
    htar -P -cvf ${TARFILE} *
    ERR=$?
    ICNT=$((${ICNT}+${ERR}))
fi

if [ ${ICNT} -ne 0 ]; then
    echo "HTAR cntl data failed at ${CDATE}" >> ${HPSSRECORD}
    exit ${ICNT}
else
    echo "HTAR diag at ${CDATE} passed and exit now".
    echo "${CNTLDIR_ATMOS}"
    echo "$(ls ${DIAGDIR}/aod_grid/fv3_aod_LUTs_fv_tracer*.nc)"
    echo "$(ls ${DIAGDIR}/aeros_grid_ll/fv3_aeros_fv_tracer*.nc)"
    echo "$(ls ${DIAGDIR}/aeros_grid_pll/fv3_aeros_fv_tracer*.nc)"
    ${NRM} ${CNTLDIR_ATMOS}
    ${NRM} ${DIAGDIR}/aod_grid/fv3_aod_LUTs_fv_tracer*.nc
    ${NRM} ${DIAGDIR}/aeros_grid_ll/fv3_aeros_fv_tracer*.nc
    ${NRM} ${DIAGDIR}/aeros_grid_pll/fv3_aeros_fv_tracer*.nc

fi
exit ${ICNT}
