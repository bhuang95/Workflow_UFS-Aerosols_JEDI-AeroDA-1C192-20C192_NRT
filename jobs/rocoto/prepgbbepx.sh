#!/bin/ksh -x

GBBDIR_NRT=${GBBDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata_UFS-Aerosols/GBBEPx/"}
GBBDIR_HERA=${GBBDIR_HERA:-"/scratch2/BMC/public/data/grids/nesdis/GBBEPx/0p1deg/"}
CDATE=${CDATE:-"2023062600"}

CYMD=$(echo "${CDATE}" | cut -c1-8)


GBBDET=${GBBDIR_NRT}/${CYMD}
GBBFILE=GBBEPx-all01GRID_v4r0_${CYMD}.nc

[[ ! -d ${GBBDET} ]] && mkdir -p ${GBBDET}
[[ -e ${GBBDET}/${GBBFILE} ]] && rm -rf ${GBBDET}/${GBBFILE}

if [ -e ${GBBDIR_HERA}/${GBBFILE} ]; then
    cp -rL ${GBBDIR_HERA}/${GBBFILE} ${GBBDET}/${GBBFILE}
    ERR=$?
else
    echo "Copying GBBEPx at ${CDATE} failed and exit 100."
    ERR=100
fi

sleep 60
echo $(date) EXITING $0 with return code ${ERR} >&2
exit ${ERR}
