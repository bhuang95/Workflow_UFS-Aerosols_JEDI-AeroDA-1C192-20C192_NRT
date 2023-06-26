#!/bin/bash 
set -x
OBSDIR_NESDIS=${OBSDIR_NESDIS:-"/scratch2/BMC/public/data/sat/nesdis/viirs/aod/conus/"}
OBSDIR_NRT=${OBSDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata_UFS-Aerosols/AODObs"}
CDATE=${CDATE:-"2023062500"}
CYCINTHR=${CYCINTHR:-"6"}
AODTYPE=${AODTYPE:-"NOAA_VIIRS"}
CASE_OBS=${CASE_OBS:-"C192"}
AODSAT=${AODSAT:-"npp j01"}
NDATE=${NDATE:-"/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"}

#echo "HBO1"
#echo ${OBSDIR_NESDIS}
#echo ${OBSDIR_NRT}
#echo ${CDATE}
#echo ${CYCINTHR}
#echo ${AODSAT}
#echo "HBO2"

ecode=0
# Dependenc1 1: whether IODAV3 AOD files already exists
#for sat in ${AODSAT}; do
#    obsfile=${OBSDIR_NRT}/${AODTYPE}-${CASE_OBS}/${CDATE}/${AODTYPE}_AOD_${sat}.${CDATE}.iodav3.nc
#done


YY=$(echo "${CDATE}" | cut -c1-4)
MM=$(echo "${CDATE}" | cut -c5-6)
DD=$(echo "${CDATE}" | cut -c7-8)
HH=$(echo "${CDATE}" | cut -c9-10)

HALFCYCLE=$(( CYCINTHR/2 )) #3
CYCINTHR_P3=$((CYCINTHR+3))
STARTOBS=$(${NDATE} -${HALFCYCLE} ${CDATE}) # c-3
ENDOBS=$(${NDATE} ${CYCINTHR_P3} ${CDATE}) # c+6
ENDOBS_P24=$(${NDATE} 24 ${ENDOBS}) # c+30

STARTYY=`echo "${STARTOBS}" | cut -c1-4`
STARTMM=`echo "${STARTOBS}" | cut -c5-6`
STARTDD=`echo "${STARTOBS}" | cut -c7-8`
STARTHH=`echo "${STARTOBS}" | cut -c9-10`
STARTYMD=${STARTYY}${STARTMM}${STARTDD}
STARTYMDH=${STARTYY}${STARTMM}${STARTDD}${STARTHH}

ENDYY=`echo "${ENDOBS}" | cut -c1-4`
ENDMM=`echo "${ENDOBS}" | cut -c5-6`
ENDDD=`echo "${ENDOBS}" | cut -c7-8`
ENDHH=`echo "${ENDOBS}" | cut -c9-10`
ENDYMD=${ENDYY}${ENDMM}${ENDDD}
ENDYMDH=${ENDYY}${ENDMM}${ENDDD}${ENDHH}

ENDYY_P24=`echo "${ENDOBS_P24}" | cut -c1-4`
ENDMM_P24=`echo "${ENDOBS_P24}" | cut -c5-6`
ENDDD_P24=`echo "${ENDOBS_P24}" | cut -c7-8`
ENDHH_P24=`echo "${ENDOBS_P24}" | cut -c9-10`
ENDYMD_P24=${ENDYY_P24}${ENDMM_P24}${ENDDD_P24}
ENDYMDH_P24=${ENDYY_P24}${ENDMM_P24}${ENDDD_P24}${ENDHH_P24}

echo ${STARTYMDH}
echo ${ENDYMDH}

ecode=0
for sat in ${AODSAT}; do
    if ( ! ls ${OBSDIR_NESDIS}/*_${sat}_*_e${ENDYMDH}*_*.nc ); then
	ecode=$((eode+1))
        if ( ls ${OBSDIR_NESDIS}/*_${sat}_*_e${ENDYMDH_P24}*_*.nc ); then
            echo "Data after 24 hours are avaiable and job is forced to submit"	
	    ecode=0
	else
            echo "Too early and end files do not exist. Waiting"
	    ecode=$((eode+1))
        fi
    else
	echo "${OBSDIR_NESDIS}/*_${sat}_s${ENDYMDH}*_*.nc is available and start this task"   
	ecode=$((eode+0))
    fi
done

exit ${ecode}
