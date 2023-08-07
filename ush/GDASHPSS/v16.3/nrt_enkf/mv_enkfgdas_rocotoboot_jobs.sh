#!/bin/bash
##SBATCH -A wrf-chem
##SBATCH -t 07:59:00
##SBATCH -p service
##SBATCH -o move.out
##SBATCH -J move_gdas

module load rocoto
set -x 
UTILDIR_NRT=${UTILDIR_NRT:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/ush/GDASHPSS/v16.3/nrt_enkf"}
GDASDIR_HERA=${GDASDIR_HERA:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-data/GDASfromHPSS"}

incdate=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate

#submit missing job at cyc and cyc+6
sdate=$(cat ${UTILDIR_NRT}/record_sdate.txt)
edate=$(cat ${UTILDIR_NRT}/record_edate.txt)
jobmove='YES'
jobroc='YES'

cdate=${sdate}
while [ ${cdate} -le ${edate} ]; do
    echo ${cdate}
    gdate=`${incdate} -6 ${cdate}`

    tmpdir=${GDASDIR_HERA}/tmp_${cdate}

    cyy=`echo ${cdate} | cut -c 1-4`
    cmm=`echo ${cdate} | cut -c 5-6`
    cdd=`echo ${cdate} | cut -c 7-8`
    chh=`echo ${cdate} | cut -c 9-10`

    gyy=`echo ${gdate} | cut -c 1-4`
    gmm=`echo ${gdate} | cut -c 5-6`
    gdd=`echo ${gdate} | cut -c 7-8`
    ghh=`echo ${gdate} | cut -c 9-10`

## Move data out of ${tmpdir}
    if [ ${jobmove} = 'YES' ]; then 
        srcdir=${tmpdir}/enkfgdas.${gyy}${gmm}${gdd}/${ghh}
        detdir=${GDASDIR_HERA}/enkfgdas.${gyy}${gmm}${gdd}/
	[ ! -d ${detdir} ] && mkdir -p ${detdir} 
        
	echo ${srcdir}
	echo ${detdir}
	echo '+++++++++++++++'
        mv ${srcdir} ${detdir}

        err=$?
        if [ $err -ne 0 ]; then
            echo 'Move ensemble failed'
            echo ${cdate}
            exit 1
        fi

        srcdir=${tmpdir}/gdas.${cyy}${cmm}${cdd}/${chh}
        detdir=${GDASDIR_HERA}/gdas.${cyy}${cmm}${cdd}/
	[ ! -d ${detdir} ] && mkdir -p ${detdir} 

	echo ${srcdir}
	echo ${detdir}
	echo '+++++++++++++++'
        mv ${srcdir} ${detdir}

        err=$?
        if [ $err -ne 0 ]; then
            echo 'Move control failed'
            echo ${cdate}
            exit 1
        fi
    fi
    cdate=`${incdate} 6 ${cdate}`

done
exit $?

