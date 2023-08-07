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

source config_hera2hpss

module load hpss
export PATH="/apps/hpss/bin:$PATH"
set -x

NCP="/bin/cp -r"
NMV="/bin/mv -f"
NRM="/bin/rm -rf"
NLN="/bin/ln -sf"

GDATE=$(${NDATE} -${CYCINTHR} ${CDATE})

CY=${CDATE:0:4}
CM=${CDATE:4:2}
CD=${CDATE:6:2}
CH=${CDATE:8:2}
CYMD=${CDATE:0:8}
CPREFIX=${CYMD}.${CH}0000

GY=${GDATE:0:4}
GM=${GDATE:4:2}
GD=${GDATE:6:2}
GH=${GDATE:8:2}
GYMD=${GDATE:0:8}

DATAHPSSDIR=${ARCHHPSSDIR}/${PSLOT}/dr-data/${GY}/${GY}${GM}/${GYMD}/
hsi "mkdir -p ${DATAHPSSDIR}"
ERR=$?
if [ ${ERR} -ne 0 ]; then
    echo "*hsi mkdir* failed at ${GDATE}" >> ${HPSSRECORD}
    exit ${ERR}
fi


# Back up gdas cntl
# Copy cntl
LOGDIR=${ROTDIR}/${PSLOT}/dr-data/logs/${GDATE}/
CNTLDIR=${ROTDIR}/${PSLOT}/dr-data/gdas.${GYMD}/${GH}
CNTLDIR_ATMOS=${CNTLDIR}/atmos/
CNTLDIR_CHEM=${CNTLDIR}/chem/
CNTLDIR_DIAG=${CNTLDIR}/diag/
CNTLDIR_ATMOS_RT=${CNTLDIR_ATMOS}/RESTART

CNTLBAK=${ROTDIR}/${PSLOT}/dr-data-backup/gdas.${GYMD}/${GH}
CNTLBAK_ATMOS_RT=${CNTBAK}/atmos/RESTART/
CNTLBAK_DIAG=${CNTLBAK}/diag/aod_obs

[[ ! -d ${CNTLBAK_ATMOS_RT} ]] $$ mkdir -p ${CNTLBAK_ATMOS_RT}
[[ ! -d ${CNTLBAK_DIAG} ]] $$ mkdir -p ${CNTLBAK_DIAG}

if [ -s ${CNTLDIR_ATMOS} ]; then
    ${NCP} ${LOGDIR} ${CNTLDIR}/logs

    ${NRM} ${CNTLDIR_ATMOS}/gdas.t??z.*?.txt
    ${NRM} ${CNTLDIR_ATMOS}/gdas.t??z.master.grb2f???
    if [ ${AERODA} = "YES" ]; then
        ${NRM} ${CNTLDIR_ATMOS_RT}/${CPREFIX}.fv_tracer_aeroanl_tmp.res.tile?.nc
    fi
    
    ${NCP} ${CNTLDIR_DIAG}/* ${CNTLBAK_DIAG}
    ${NCP} ${CNTLDIR_ATMOS_RT}/${CPREFIX}.coupler* ${CNTLBAK_ATMOS_RT}/
    ${NCP} ${CNTLDIR_ATMOS_RT}/${CPREFIX}.fv_core* ${CNTLBAK_ATMOS_RT}/
    ${NCP} ${CNTLDIR_ATMOS_RT}/${CPREFIX}.fv_tracer* ${CNTLBAK_ATMOS_RT}/
    
    ERR=$?
    if [ ${ERR} -ne 0 ]; then
        echo "Copy cntl data failed at ${GDATE}" >> ${HPSSRECORD}
        exit ${ERR}
    fi

    cd ${CNTLDIR}
    TARFILE=${DATAHPSSDIR}/gdas.${GDATE}.tar
    htar -P -cvf ${TARFILE} *
    ERR=$?
    if [ ${ERR} -ne 0 ]; then
        echo "HTAR cntl data failed at ${CDATE}" >> ${HPSSRECORD}
        exit ${ERR}
    fi
fi

# Back up gdasenkf cntl
NGRPS=$((10#${NMEM_ENKF} / 10#${NMEM_ENSGRP_ARCH}))
if [ ${ENSRUN} = "YES" ] then
    ENKFDIR=${ROTDIR}/${PSLOT}/dr-data/enkfgdas.${GYMD}/${GH}
    ENKFDIR_ATMOS=${ENKFDIR}/atmos/
    ENKFDIR_CHEM=${ENKFDIR}/chem/
    ENKFDIR_DIAG=${ENKFDIR}/diag/
    ENKFDIR_ATMOS_MEAN_RT=${ENKFDIR_ATMOS}/ensmean/RESTART

    ENKFBAK=${ROTDIR}/${PSLOT}/dr-data-backup/enkfgdas.${GYMD}/${GH}
    ENKFBAK_ATMOS=${ENKFBAK}/atmos/
    ENKFBAK_DIAG=${ENKFBAK}/diag/aod_obs
    ENKFBAK_ATMOS_MEAN_RT=${ENKFBAK_ATMOS}/ensmean/RESTART

    ${NRM} ${ENKFDIR_ATMOS}/mem???/*.txt

    if [ ${AERODA} = "YES" ]; then
        ${NRM} ${ENKFDIR_ATMOS}/ensmean/RESTART/${CPREFIX}.fv_tracer_aeroanl_tmp.res.tile?.nc
        ${NRM} ${ENKFDIR_ATMOS}/mem???/RESTART/${CPREFIX}.fv_tracer_aeroanl_tmp.res.tile?.nc
    fi

    ${NCP} ${ENKFDIR_DIAG}/* ${ENKFBAK_DIAG}/
    ${NCP} ${ENKFDIR_ATMOS_MEAN_RT}/${CPREFIX}.coupler* ${ENKFBAK_ATMOS_MEAN_RT}/
    ${NCP} ${ENKFDIR_ATMOS_MEAN_RT}/${CPREFIX}.fv_core* ${ENKFBAK_ATMOS_MEAN_RT}/
    ${NCP} ${ENKFDIR_ATMOS_MEAN_RT}/${CPREFIX}.fv_tracer* ${ENKFBAK_ATMOS_MEAN_RT}/

    ERR=$?
    if [ ${ERR} -ne 0 ]; then
        echo "Copy enkf data failed at ${CDATE}" >> ${HPSSRECORD}
        exit ${ERR}
    fi

    IGRP=0
    LGRP_ATMOS=${TMPDIR}/list.atmos.grp${IGRP}
    [[ -f ${LGRP_ATMOS} ]] && rm -rf ${LGRP_ATMOS}
    echo "ensmean" > ${LGRP_ATMOS}
    IGRP=1
    while [ ${IGRP} -le ${NGRPS} ]; do
        ENSED=$((${NMEM_ENSGRP_ARCH} * 10#${IGRP}))
	ENSST=$((${ENSED} - ${NMEM_ENSGRP_ARCH} + 1))
	    
	LGRP_ATMOS=${TMPDir}/list.atmos.grp${IGRP}
	LGRP_CHEM=${TMPDir}/list.chem.grp${IGRP}
	[[ -f ${LGRP_ATMOS} ]] && rm -rf ${LGRP_ATMOS}
	[[ -f ${LGRP_CHEM} ]] && rm -rf ${LGRP_CHEM}

	IMEM=${ENSST}
	while [ ${IMEM} -le ${ENSED} ]; do
	    MEMSTR="mem"`printf %03d ${IMEM}`
            echo ${MEMSTR} >> ${LGRP_ATMOS}
            echo ${MEMSTR} >> ${LGRP_CHEM}
	    IMEM=$((IMEM+1))
	done
	IGRP=$((IGRP+1))
    done

    IGRP=0
    TARFILE=${DATAHPSSDIR}/enkfgdas.${GDATE}.atmos.ensmean.tar
    LGRP=${TMPDIR}/list.atmos.grp${IGRP}
    cd ${ENKFDIR_ATMOS}
    htar -P -cvf ${TARFILE}  $(cat ${LGRP})
    ERR=$?
    if [ ${ERR} -ne 0 ]; then
        echo "HTAR enkf data failed at ${GDATE} and atmos.grp${IGRP}" >> ${HPSSRECORD}
        exit ${ERR}
    fi

    for field in "atmos" "chem"; do
        if [ ${field} = "atmos" ]; then
	    ENKFDIR_FIELD=${ENKFDIR_ATMOS}
	elif [ ${field} = "chem" ]; then
	    ENKFDIR_FIELD=${ENKFDIR_CHEM}
	else
	    echo "Only atmos and chem defined for field variable"
	    exit 100
	fi

        IGRP=1
        while [ ${IGRP} -le ${NGRPS} ]; do
	    TARFILE=${DATAHPSSDIR}/enkfgdas.${GDATE}.${field}.grp${IGRP}.tar
	    LGRP=${TMPDIR}/list.${field}.grp${IGRP}
	    cd ${ENKFDIR_FIELD}
	    htar -P -cvf ${TARFILE}  $(cat ${LGRP})
	    ERR=$?
            if [ ${ERR} -ne 0 ]; then
                echo "HTAR enkf data* failed at ${GDATE} and ${field}.grp${IGRP}" >> ${HPSSRECORD}
                exit ${ERR}
            fi
            IGRP=$((IGRP+1))
         done
    done

    CPCNTLDIAG=${ENKFDIR_DIAG}/cntl
    [[ ! -d ${CPCNTLDIAG} ]] && mkdir -p ${CPCNTLDIAG}
    ${NCP} ${CNTLDIR_DIAG}/* ${CPCNTLDIAG}/
    cd ${ENKFDIR_DIAG}
    TARFILE=${DATAHPSSDIR}/diag.cntlenkf.${GDATE}.tar
    htar -P -cvf ${TARFILE}  $(cat ${LGRP})
    ERR=$?
    if [ ${ERR} -ne 0 ]; then
        echo "HTAR enkf diag data failed at ${GDATE}" >> ${HPSSRECORD}
        exit ${ERR}
    fi

fi #ENSRUN

## Back up GDAS met files
if [ ${AERODA} = "YES" ]; then
    GDASMETDIR_CNTL=${METDIR_NRT}/${CASE_CNTL}/gdas.${GYMD}/${GH}
    GDASMETDIR_ENKF=${METDIR_NRT}/${CASE_ENKF}/enkfgdas.${GYMD}/${GH}

    cd ${GDASMETDIR_CNTL}
    TARFILE=${DATAHPSSDIR}/gdasmet_gdas.${GDATE}.tar
    htar -P -cvf ${TARFILE} *
    ERR=$?
    if [ ${ERR} -ne 0 ]; then
        echo "HTAR GDASMET cntl data failed at ${GDATE}" >> ${HPSSRECORD}
        exit ${ERR}
    fi

    cd ${GDASMETDIR_ENKF}
    TARFILE=${DATAHPSSDIR}/gdasmet_enkfgdas.${GDATE}.tar
    htar -P -cvf ${TARFILE} *
    ERR=$?
    if [ ${ERR} -ne 0 ]; then
        echo "HTAR GDASMET enkf data failed at ${GDATE}" >> ${HPSSRECORD}
        echo ${CDATE} >> ${HPSSRECORD}
        exit ${ERR}
    fi
fi # ${AERODA}


if [ ${ERR} -eq 0 ]; then
    echo "HTAR is successful at ${GDATE}"
    ${NRM} ${CNTLDIR}
    if [ ${AERODA} = "YES" ]; then
        ${NRM} ${ENKFDIR}
        ${NRM} ${GDASMETDIR_ENKF}
        ${NRM} ${GDASMETDIR_CNTL}
    fi
else
    echo "HTAR failed at ${GDATE}" >> ${HPSSRECORD}
    exit ${ERR}
fi

exit ${ERR}
