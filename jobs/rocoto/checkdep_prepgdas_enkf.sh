#!/bin/bash 
set -x
METDIR_HERA=${METDIR_HERA:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-data/downloadHpss/test/"}
NMEM_AERO=${NMEM_AERO:-"20"}
CDATE=${CDATE:-"2023062400"}
CYCINTHR=${CYCINTHR:-"06"}
NDATE=${NDATE:-"/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"}

GDATE=$(${NDATE} -${CYCINTHR} ${CDATE})

CYY=$(echo "${CDATE}" | cut -c1-4)
CMM=$(echo "${CDATE}" | cut -c5-6)
CDD=$(echo "${CDATE}" | cut -c7-8)
CHH=$(echo "${CDATE}" | cut -c9-10)


GYY=$(echo "${GDATE}" | cut -c1-4)
GMM=$(echo "${GDATE}" | cut -c5-6)
GDD=$(echo "${GDATE}" | cut -c7-8)
GHH=$(echo "${GDATE}" | cut -c9-10)

ecode=0
nfiles=$(ls ${METDIR_HERA}/enkfgdas.${CYY}${CMM}${CDD}/${CHH}/atmos/mem???/gdas.t${CHH}z.ratminc.nc | wc -l)
if [ ${nfiles} != ${NMEM_AERO} ]; then
    ecode=$((ecode+1))
fi

nfiles=$(ls ${METDIR_HERA}/enkfgdas.${GYY}${GMM}${GDD}/${GHH}/atmos/mem???/gdas.t${GHH}z.atmf006.nc | wc -l)
if [ ${nfiles} != ${NMEM_AERO} ]; then
    ecode=$((ecode+1))
fi

nfiles=$(ls ${METDIR_HERA}/enkfgdas.${GYY}${GMM}${GDD}/${GHH}/atmos/mem???/gdas.t${GHH}z.sfcf006.nc | wc -l)
if [ ${nfiles} != ${NMEM_AERO} ]; then
    ecode=$((ecode+1))
fi

exit ${ecode}
