#!/bin/bash
#SBATCH -n 1
#SBATCH -t 02:20:00
#SBATCH -p service
#SBATCH -A chem-var
#SBATCH -J VIIRS_AOD_HOFX_DIFF_IODAV3
#SBATCH -D ./
#SBATCH -o /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/VIIRS_AOD_HOFX_DIFF_IODAV3.out
#SBATCH -e /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/VIIRS_AOD_HOFX_DIFF_IODAV3.out


# This jobs plots the AOD, HOFX and their difference in a 3X1 figure.
set -x 

module use -a /contrib/anaconda/modulefiles
module load anaconda/latest

codedir=$(pwd)
topexpdir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/
ndate=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate

#cycst=2017101500 # Starting cycle
#cyced=2017102700 # Ending cycle
cycst=2020061600 # Starting cycle
cyced=2020062300 # Ending cycle
	# All four cycles at 00/06/12/18Z has to be available at a certain day. Otherwise, it will crash/ 
	
# (if cycinc=24, set cycst and cyced as YYYYMMDD00)
cycinc=24 
# (6 or 24 hours)

#freerunexp="FreeRun-1C192-0C192-201710"
freerunexp="RET_FreeRun_NoEmisStoch_C96_202006"
	# Not necessary
#aerodaexp="
#	ENKF_AEROSEMIS-ON_STOCH_MODIFIED_INIT-ON-201710_bc_1.5
#	"
aerodaexp="
	RET_AeroDA_NoEmisStoch_C96_202006
	"
        # DA experiments
	#ENKF_AEROSEMIS-ON_STOCH_MODIFIED_INIT-ON-201710_nobias_correction
exps="${freerunexp}"

for exp in ${exps}; do
    topplotdir=${topexpdir}/${exp}/diagplots/VIIRS_AOD_HOFX_DIFF_IODAV3
    if ( echo ${aerodaexp} | grep ${exp} ); then
        aeroda=True
        emean=False
        prefix=AeroDA_EmisPert1
    elif ( echo ${freerunexp} | grep ${exp} ); then
        aeroda=False
        emean=False
        prefix=FreeRun
    else
	echo "Please deefine aeroda, emean, prefix accordingly for your exps"
    fi

    datadir=${topexpdir}/${exp}/dr-data-backup

    plotdir=${topplotdir}/${prefix}
    [[ ! -d ${plotdir} ]] && mkdir -p ${plotdir}

    cp plt_VIIRS_AOD_HOFX_DIFF_IODAV3.py ${plotdir}/plt_VIIRS_AOD_HOFX_DIFF_IODAV3.py

    cd ${plotdir}/

    cyc=${cycst}
    while [ ${cyc} -le ${cyced} ]; do
        echo ${cyc}
        python plt_VIIRS_AOD_HOFX_DIFF_IODAV3.py -c ${cyc} -i ${cycinc} -a ${aeroda} -m ${emean} -p ${prefix} -t ${datadir}
        ERR=$?
        [[ ${ERR} -ne 0 ]] && exit 100
        cyc=$(${ndate} ${cycinc} ${cyc})
    done
done
exit 0
