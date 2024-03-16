#!/bin/bash
##!/bin/bash --login
#SBATCH -J hpss-2019070318
#SBATCH -A wrf-chem 
#SBATCH -n 1
#SBATCH -t 24:00:00
#SBATCH -p service
#SBATCH -D ./
#SBATCH -o ./hpss-2019070318-out.txt
#SBATCH -e ./hpss-2019070318-out.txt


module load hpss
set -x

echo "2019070318" >> /home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/BackupGDAS/v15/record.extract_success_v15

heracntldir=/scratch1/BMC/chem-var/MAPP_2018/bhuang/BackupGdas//v15/2019070318/gdas.20190703/18
heraenkfdir=/scratch1/BMC/chem-var/MAPP_2018/bhuang/BackupGdas//v15/2019070318/enkfgdas.20190703/18
hpssdir=/BMC/fim/5year/MAPP_2018/bhuang/BackupGdas/v15/201907
hsi "mkdir -p ${hpssdir}"

if [ -f ${heracntldir}/gdas.t18z.atmanl.nemsio ] && [ -f ${heracntldir}/gdas.t18z.sfcanl.nemsio ]; then
    cd ${heracntldir}
    htar -cv -f ${hpssdir}/gdas.2019070318.tar *
    err=$?
    if [ ${err} != '0' ]; then
        echo "HTAR cntl failed at ${cdate} and exit."
        exit ${err}
    else
        echo "HTAR cntl succeeded at 2019070318."
    fi
else
    echo "${heracntldir}/gdas.t18z.atmanl.nemsio does not exist and exit"
    exit 1
fi


nens1=`ls ${heraenkfdir}/mem???/gdas.t18z.ratmanl.nemsio | wc -l`
nens2=`ls ${heraenkfdir}/mem???/RESTART/*sfcanl_data.tile6.nc | wc -l`
if [ ${nens1} -eq 80 ] && [ ${nens2} -eq 80 ]; then
    cd ${heraenkfdir}
    htar -cv -f ${hpssdir}/enkfgdas.2019070318.tar *
    err=$?
    if [ ${err} != '0' ]; then
        echo "HTAR enkf failed at ${cdate} and exit."
        exit ${err}
    else
        echo "HTAR enkf succeeded at 2019070318."
        echo "2019070318" >> /home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/BackupGDAS/v15/record.hpss_htar_success_v15
        cdatep6=`/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate 6 2019070318`
        echo "${cdatep6}" > /home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/BackupGDAS/v15/CYCLE.info
        rm -rf ${heracntldir}
        rm -rf ${heraenkfdir}
cd /home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/BackupGDAS/v15
/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/BackupGDAS/v15/driver.hera_hpssDownload_v15.sh
        exit ${err}
    fi
else
    echo "${heraenkfdir} is not complete and exit"
    exit 1
fi
