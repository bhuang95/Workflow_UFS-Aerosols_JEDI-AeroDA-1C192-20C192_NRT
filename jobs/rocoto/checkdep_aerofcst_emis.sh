#!/bin/bash 
set -x
EMISDIR_NRT=${EMISDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata_UFS-Aerosols/gocart_emissions/nexus"}
GBBDIR_NRT=${GBBDIR_NRT:-"${EMISDIR_NRT}/GBBEPx"}
CEDSDIR_NRT=${CEDSDIR_NRT:-"${EMISDIR_NRT}/CEDS"}
MEGANDIR_NRT=${MEGANDIR_NRT:-"${EMISDIR_NRT}/MEGAN_OFFLINE_BVOC"}
CEDSVER=${CEDSVER:-"2019"}
CDATE=${CDATE:-"2023062400"}
DAYINTHR=24
NDATE=${NDATE:-"/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"}

CH=$(echo "${CDATE}" | cut -c9-10)

MDATE=$(${NDATE} -${DAYINTHR} ${CDATE})
PDATE=$(${NDATE} +${DAYINTHR} ${CDATE})

for IDATE in ${MDATE} ${CDATE} ${PDATE}; do

    IYY=$(echo ${IDATE} | cut -c1-4)
    IMM=$(echo ${IDATE} | cut -c5-6)
    IDD=$(echo ${IDATE} | cut -c7-8)
    IHH=$(echo ${IDATE} | cut -c9-10)
    IYMD=$(echo ${IDATE} | cut -c1-8)

    GBBFILE=${GBBDIR_NRT}/GBBEPx_all01GRID.emissions_v004_${IYMD}.nc
    CEDSFILE=${CEDSDIR_NRT}/${IYY}/CEDS.${CEDSVER}.emis.${IYMD}.nc
    MEGANFILE=${MEGANDIR_NRT}/${IYY}/MEGAN.OFFLINE.BIOVOC.${IYY}.emis.${IYMD}.nc
    
    for IFILE in ${GBBFILE} ${CEDSFILE} ${MEGANFILE}; do
        if [ ! -f ${IFILE} ]; then
            echo "Missing ${IFILE}"
	    exit 99
        fi
    done
done

#if [ ${CH} = "18" ]; then
#   DAYINTHR=48
#   PDATE=$(${NDATE} +${DAYINTHR} ${CDATE})
#   PYY=$(echo ${PDATE} | cut -c1-4)
#   PYMD=$(echo ${PDATE} | cut -c1-8)
#
#   GBBFILE=${GBBDIR_NRT}/GBBEPx_all01GRID.emissions_v004_${PYMD}.nc
#   CEDSFILE=${CEDSDIR_NRT}/${PYY}/CEDS.${CEDSVER}.emis.${PYMD}.nc
#   MEGANFILE=${MEGANDIR_NRT}/${PYY}/MEGAN.OFFLINE.BIOVOC.${PYY}.emis.${PYMD}.nc
#   for IFILE in ${GBBFILE}  ${CEDSFILE} ${MEGANFILE}; do
#       if [ ! -f ${IFILE} ]; then
#           echo "Missing ${IFILE}"
#           exit 99
#       fi
#   done
#fi

exit 0
