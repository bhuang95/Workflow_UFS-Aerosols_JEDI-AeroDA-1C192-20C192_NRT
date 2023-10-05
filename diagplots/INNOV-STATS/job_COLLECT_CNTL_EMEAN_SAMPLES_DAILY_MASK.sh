#!/bin/bash
##SBATCH -J innov_stats
##SBATCH -A wrf-chem
##SBATCH -o /scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/misc/innov_stats.out
##SBATCH -e /scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/misc/innov_stats.out
##SBATCH -n 1
##SBATCH -p service
##SBATCH -t 05:30:00

set -x
module use -a /contrib/anaconda/modulefiles
module load anaconda/latest

curdir=`pwd`
aod=NOAA_VIIRS_npp
cycst=2017100600
cyced=2017102700
spcyc=2017101000
topexpdir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/
nodaexp=FreeRun-201710
daexp=ENKF_AEROSEMIS-OFF-201710  #ENKF_AEROSEMIS-ON_STOCHINIT-ON-201710   #ENKF_AEROSEMIS-OFF-201710  #ENKF_AEROSEMIS-ON_STOCHINIT-OFF-201710
expdir=${topexpdir}/${daexp}
plotdir=${expdir}/diagplots/INNOV-STATS/${aod}-daily-masks-${cycst}-${cyced}/

pycleccntl=COLLECT_CNTL_EMEAN_SAMPLES_DAILY_MASK.py
pyclecens=COLLECT_ENS_SPREAD_SAMPLES_DAILY_MASK.py
pypltens=PLT_ENS_RMSE_SPREAD_DAILY_MASK.py
pypltcntl=PLT_AOD_STATS_DAILY_MASKS.py
pypltscaling=PLT_SCALING_FACTOR_DAILY_MASK.py

[[ ! -d ${plotdir} ]] && mkdir -p ${plotdir}
cd ${plotdir}

ln -sf ${curdir}/masks ./
[[ ! -d output ]] && mkdir -p output

# Collect cntl and emean obs, hfx, bias, mse over masks
cp -r ${curdir}/${pycleccntl} ./
#python ${pycleccntl} -i ${cycst} -j ${cyced} -e ${daexp} -f ${nodaexp} -d ${topexpdir} -a ${aod} 
[[ $? -ne 0 ]] && exit 100

# Collect ensemble spread samples over masks
cp -r ${curdir}/${pyclecens} ./
#python ${pyclecens} -i ${cycst} -j ${cyced} -e ${daexp} -d ${topexpdir} -a ${aod}
[[ $? -ne 0 ]] && exit 100

# Plot ensemble spread-error consistency over masks
cp -r ${curdir}/${pypltens} ./
#python ${pypltens} -i ${cycst} -j ${cyced} -e ${daexp} -d ${topexpdir} -a ${aod} -s ${spcyc}
[[ $? -ne 0 ]] && exit 100
[[ ! -d figures ]] && mkdir -p figures
mv *.png ./figures/
mv *.txt ./figures/

# Plot cntl and ensemean stats over masks
cp -r ${curdir}/${pypltcntl} ./
#python ${pypltcntl} -i ${cycst} -j ${cyced} -e ${daexp} -f ${nodaexp} -d ${topexpdir} -a ${aod} -s ${spcyc}
[[ $? -ne 0 ]] && exit 100
[[ ! -d figures ]] && mkdir -p figures
mv *.png ./figures/
mv *.txt ./figures/

# Plot AOD and HFX bar plot for scaling plot 
cp -r ${curdir}/${pypltscaling} ./
AERODA=YES
python ${pypltscaling} -i ${cycst} -j ${cyced} -e ${daexp} -f ${AERODA} -d ${topexpdir} -a ${aod} -s ${spcyc}
[[ $? -ne 0 ]] && exit 100
[[ ! -d figures ]] && mkdir -p figures
mv *.png ./figures/
mv *.txt ./figures/

# Plot AOD and HFX bar plot for scaling plot 
cp -r ${curdir}/${pypltscaling} ./
AERODA=NO
python ${pypltscaling} -i ${cycst} -j ${cyced} -e ${nodaexp} -f ${AERODA} -d ${topexpdir} -a ${aod} -s ${spcyc}
[[ $? -ne 0 ]] && exit 100
[[ ! -d figures ]] && mkdir -p figures
mv *.png ./figures/
mv *.txt ./figures/

exit 0


