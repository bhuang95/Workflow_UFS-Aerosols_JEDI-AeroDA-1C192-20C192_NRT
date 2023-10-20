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
#set -x

NMV="/bin/mv -f"
NRM="/bin/rm -rf"

source ./config_hera2hpss

htar -xvf ${TARFILE}
ERR=$?
if [ ${ERR} -ne 0 ]; then
    echo "HTAR failed and exit..."
    exit 100
fi

echo ${FLDS}
for FLD in ${FLDS}; do
    echo ${FLD}
    IMEM=1
    while [ ${IMEM} -le ${NMEM} ]; do
        MEMSTR="mem"$(printf %03d ${IMEM})
	echo ${MEMSTR}
	[[ ! -d ${MEMSTR} ]] && mkdir -p ${MEMSTR}
	SRCFILE=gdas.t${GH}z.${FLD}.${MEMSTR}.nemsio
	if [ ${FLD} = "atmf006" ]; then
	    TGTFILE=${MEMSTR}/gdas.t${CH}z.ratmanl.${MEMSTR}.nemsio
        elif [ ${FLD} = "sfcf006" ]; then
	    TGTFILE=${MEMSTR}/gdas.t${CH}z.sfcanl.${MEMSTR}.nemsio
        elif [ ${FLD} = "nstf006" ]; then
	    TGTFILE=${MEMSTR}/gdas.t${CH}z.nstanl.${MEMSTR}.nemsio
        else
	    echo "Need to define TGTFILE for ${FLD}, please add here and exit now..."
	    exit 100
	fi
        echo ${SRCFILE} 
	echo ${TGTFILE}
        ${NMV} ${SRCFILE} ${TGTFILE}

        ERR=$?
        if [ ${ERR} -ne 0 ]; then
            echo "Moving ${SRCFILE} failed and exit..."
            exit 100
	fi
	IMEM=$((IMEM+1))
    done
done

${NRM} *.nemsio
echo "HBO"
exit ${ERR}

