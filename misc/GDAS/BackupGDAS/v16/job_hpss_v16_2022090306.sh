#!/bin/bash
##!/bin/bash --login
#SBATCH -J hpss-2022090306
#SBATCH -A wrf-chem 
#SBATCH -n 1
#SBATCH -t 24:00:00
#SBATCH -p service
#SBATCH -D ./
#SBATCH -o ./hpss-2022090306-out.txt
#SBATCH -e ./hpss-2022090306-out.txt


module load hpss
set -x

echo "2022090306" >> /home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/BackupGDAS/v16/record.extract_success_v16

heracntldir=/scratch1/BMC/chem-var/MAPP_2018/bhuang/BackupGdas//v16/2022090306/gdas.20220903/06
heraenkfdir=/scratch1/BMC/chem-var/MAPP_2018/bhuang/BackupGdas//v16/2022090306/enkfgdas.20220903/06
heraenkf_m6dir=/scratch1/BMC/chem-var/MAPP_2018/bhuang/BackupGdas//v16/2022090306/enkfgdas.20220903/00
hpssdir=/BMC/fim/5year/MAPP_2018/bhuang/BackupGdas/v16/202209
hsi "mkdir -p ${hpssdir}"

if [ -f ${heracntldir}/atmos/gdas.t06z.atmanl.nc ] && [ -f ${heracntldir}/atmos/gdas.t06z.sfcanl.nc ]; then
    cd ${heracntldir}
    htar -cv -f ${hpssdir}/gdas.2022090306.tar *
    err=$?
    if [ ${err} != '0' ]; then
        echo "HTAR cntl failed at ${cdate} and exit."
        exit ${err}
    else
        echo "HTAR cntl succeeded at 2022090306."
    fi
else
    echo "-f ${heracntldir}/atmos/gdas.t06z.atmanl.nc does not exist and exist"
    exit 1
fi

if [ 2022090306 -eq 2021032100 ]; then
    nens1=`ls ${heraenkf_m6dir}/mem???/gdas.t00z.atmf006.nemsio | wc -l`
    nens2=`ls ${heraenkf_m6dir}/mem???/gdas.t00z.sfcf006.nemsio | wc -l`
    if [ ${nens1} -eq 80 ] && [ ${nens2} -eq 80 ] ; then
        cd ${heraenkf_m6dir}
        htar -cv -f ${hpssdir}/enkfgdas.2022090300.tar *
        err=$?
        if [ ${err} != '0' ]; then
            echo "HTAR enkf failed at ${cdatem6} and exit."
            exit ${err}
        else
            echo "HTAR enkf succeeded at 2022090300."
            rm -rf ${heraenkf_m6dir}
        fi
    fi
#else
#    echo "${heraenkf_m6dir} is not complete and exit"
#    exit 1
fi

nens1=`ls ${heraenkfdir}/atmos/mem???/gdas.t06z.ratminc.nc | wc -l`
nens2=`ls ${heraenkfdir}/atmos/mem???/gdas.t06z.atmf006.nc | wc -l`
nens3=`ls ${heraenkfdir}/atmos/mem???/gdas.t06z.sfcf006.nc | wc -l`
nens4=`ls ${heraenkfdir}/atmos/mem???/RESTART/*0000.sfcanl_data*.nc| wc -l`
if [ ${nens1} -eq 80 ] && [ ${nens2} -eq 80 ] && [ ${nens3} -eq 80 ] && [ ${nens4} -eq 480 ]; then
    cd ${heraenkfdir}
    htar -cv -f ${hpssdir}/enkfgdas.2022090306.tar *
    err=$?
    if [ ${err} != '0' ]; then
        echo "HTAR enkf failed at ${cdate} and exit."
        exit ${err}
    else
        echo "HTAR enkf succeeded at 2022090306."
        echo "2022090306" >> /home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/BackupGDAS/v16/record.hpss_htar_success_v16
        cdatep6=`/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate 6 2022090306`
        echo "${cdatep6}" > /home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/BackupGDAS/v16/CYCLE.info
        rm -rf ${heracntldir}
        rm -rf ${heraenkfdir}
cd /home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/BackupGDAS/v16
/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/BackupGDAS/v16/driver.hera_hpssDownload_v16.sh
        exit ${err}
    fi
else
    echo "${heraenkfdir} is not complete and exit"
    exit 1
fi
