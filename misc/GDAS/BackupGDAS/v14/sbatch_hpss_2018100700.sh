#!/bin/bash
#SBATCH -J hpss
#SBATCH -A wrf-chem 
#SBATCH -n 1
#SBATCH -t 24:00:00
#SBATCH -p service
#SBATCH -D ./
#SBATCH -o ./hpss-out.txt
#SBATCH -e ./hpss-out.txt

module load hpss
set -x

NMV="/bin/mv -f"
NRM="/bin/rm -rf"

source config_hera2hpss

htar -xvf ${TARFILE}
ERR=$?
if [ ${ERR} -ne 0 ]; then
    echo "HTAR failed and exit..."
    exit 100
fi

for FLD in ${FLDs}; do
    IMEM=1
    while [ ${IMEM} -le ${NMEM} ]; then
        MEMSTR="mem"$(printf %03d ${IMEM})
	[[ ! -d ${MEMSTR} ]] && mkdir -p ${MEMSTR}
	SRCFILE=${MEMSTR}/gdas.t{GH}z.${FLD}.${MEMSTR}.nemsio
	if [ ${FLD} = "atmf006" ]; then
	    TGTFILE=gdas.t${CH}z.ratmanl.${MEMSTR}.nemsio
        elif [ ${FLD} = "sfcf006" ]; then
	    TGTFILE=gdas.t${CH}z.sfcanl.${MEMSTR}.nemsio
        elif [ ${FLD} = "nstf006" ]; then
	    TGTFILE=gdas.t${CH}z.nstanl.${MEMSTR}.nemsio
        else
	    echo "Need to define TGTFILE for ${FLD}, please add here and exit now..."
	    exit 100
	fi
        ${NMV} ${SRCFILE} ${TGTFILE}

        ERR=$?
        if [ ${ERR} -ne 0 ]; then
            echo "Moving ${SRCFILE} failed and exit..."
            exit 100
	fi
do

#${NRM} *.nemsio

exit ${ERR}

