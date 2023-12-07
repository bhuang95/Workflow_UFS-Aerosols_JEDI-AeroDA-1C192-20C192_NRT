#!/bin/bash -l

set -x
# Back up cycled data to HPSS at ${CDATE}-6 cycle

source config_hera2hpss

module load hpss
export PATH="/apps/hpss/bin:$PATH"
set -x

HPSSRECORD=${TMPDIR}/record.failed_HERA2HPSS

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
    echo "*hsi mkdir* failed at ${CDATE}"
    echo ${CDATE} >> ${HPSSRECORD}
    exit ${ERR}
fi

# Copy cntl
LOGDIR=${ROTDIR}/${PSLOT}/dr-data/logs/${GDATE}/
CNTLDIR=${ROTDIR}/${PSLOT}/dr-data/gdas.${GYMD}/${GH}
CNTLDIR_ATMOS=${CNTLDIR}/atmos/
CNTLDIR_CHEM=${CNTLDIR}/chem/
CNTLDIR_DIAG=${CNTLDIR}/diag/
CNTLBAK=${ROTDIR}/${PSLOT}/dr-data-backup/gdas.${GYMD}/${GH}
CNTLBAK_ATMOS=${CNTBAK}/atmos/RESTART/
CNTLBAK_DIAG=${CNTLBAK}/diag/

[[ ! -d ${CNTLBAK_ATMOS} ]] $$ mkdir -p ${CNTLBAK_ATMOS}
[[ ! -d ${CNTLBAK_DIAG} ]] $$ mkdir -p ${CNTLBAK_DIAG}

if [ -s ${CNTLDIR_ATMOS} ]; then
    ${NCP} ${LOGDIR} ${CNTLDIR}/log 

    ${NRM} ${CNTLDIR_ATMOS}/gdas.t??z.*?.txt
    ${NRM} ${CNTLDIR_ATMOS}/gdas.t??z.master.grb2f???
    
    ${NCP} ${CNTLDIR_DIAG}/* ${CNTLBAK_DIAG}
    ${NCP} ${CNTLDIR_ATMOS}/RESTART/${CPREFIX}.coupler* ${CNTLBAK_ATMOS}/
    ${NCP} ${CNTLDIR_ATMOS}/RESTART/${CPREFIX}.fv_core* ${CNTLBAK_ATMOS}/
    ${NCP} ${CNTLDIR_ATMOS}/RESTART/${CPREFIX}.fv_tracer* ${CNTLBAK_ATMOS}/
    
    ERR=$?
    if [ ${ERR} -ne 0 ]; then
        echo "*copy cntl data* failed at ${CDATE}"
        echo ${CDATE} >> ${HPSSRECORD}
        exit ${ERR}
    fi

    cd ${CNTLDIR}
    TARFILE=${DATAHPSSDIR}/gdas.${GDATE}.tar
    htar -P -cvf ${TARFILE} *
    ERR=$?
    if [ ${ERR} -ne 0 ]; then
        echo "*htar cntl data* failed at ${CDATE}"
        echo ${CDATE} >> ${HPSSRECORD}
        exit ${ERR}
    fi
fi


NGRPS=\$((10#\${NMEM} / 10#\${NMEM_GRP}))
if [ ${ENSRUN} = "YES" ] then
    ENKFDIR=${ROTDIR}/${PSLOT}/dr-data/enkfgdas.${GYMD}/${GH}
    ENKFDIR_ATMOS=${ENKFDIR}/atmos/
    ENKFDIR_CHEM=${ENKFDIR}/chem/
    ENKFDIR_DIAG=${ENKFDIR}/diag/

    ENKFBAK=${ROTDIR}/${PSLOT}/dr-data-backup/enkfgdas.${GYMD}/${GH}
    ENKFBAK_ATMOS=${ENKFBAK}/atmos/
    ENKFBAK_DIAG=${ENKFBAK}/diag/

    ENKFBAK_ATMOS_MEAN=${ENKFBAK}/atmos/ensmean/RESTART

    ${NRM}/${ENKFDIR_ATMOS}/*.txt

    ${NCP} ${ENKFDIR_DIAG}/* ${ENKFBAK_DIAG}/
    ${NCP} ${ENKFDIR_ATMOS}/ensmean/RESTART/${CPREFIX}.coupler* ${ENKFBAK_ATMOS_MEAN}/
    ${NCP} ${ENKFDIR_ATMOS}/ensmean/RESTART/${CPREFIX}.fv_core* ${ENKFBAK_ATMOS_MEAN}/
    ${NCP} ${ENKFDIR_ATMOS}/ensmman/RESTART/${CPREFIX}.fv_tracer* ${ENKFBAK_ATMOS_MEAN}/

    ERR=$?
    if [ ${ERR} -ne 0 ]; then
        echo "*copy enkf data* failed at ${CDATE}"
        echo ${CDATE} >> ${HPSSRECORD}
        exit ${ERR}
    fi

    IGRP=0
    LGRP_ATMOS=${TMPDIR}/list.atmos.grp${IGRP}
    [[ -f ${LGRP_ATMOS} ]] && rm -rf ${LGRP_ATMOS}
    echo "ensmean" > \${LGRP_ATMOS}
    IGRP=1
    while [ ${IGRP} -le ${NGRPS} ]; do
        ENSED=$((${NMEM_GRP} * 10#${IGRP}))
	ENSST=$((ENSED - NMEM_GRP + 1))
	    
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
        echo "*htar enkf atmos data* failed at ${CDATE} and grp${IGRP}"
        echo ${CDATE} >> ${HPSSRECORD}
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
                echo "*htar enkf data* failed at ${CDATE} and ${field}.grp${IGRP}"
                echo ${CDATE} >> ${HPSSRECORD}
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
        echo "*htar diag data* failed at ${CDATE}"
        echo ${CDATE} >> ${HPSSRECORD}
        exit ${ERR}
    fi
fi #End of ENSRUN

###STOP HERE###

    if [ \${ERR} -eq 0 ]; then
        echo "HTAR is successful at \${cycN}"
	/bin/rm -rf \${enkfGDAS}
	/bin/rm -rf \${cntlGDAS}
	/bin/rm -rf \${tmpDiag}
    else
        echo "HTAR failed at \${cycN}"
        echo \${cycN} >> \${RECORDDIR}/\${HPSSRECORD}
        exit \${ERR}
    fi
    #cycN=\`\${incdate} \${cycInc}  \${cycN}\`
fi




fi

nanal=${NMEM_ENKF}
cycN=\`\${incdate} -6 ${CDATE}\`
cycN1=\`\${incdate} 6 \${cycN}\`

tmpDiag=\${tmpDir}/run_diag_\${cycN}
mkdir -p \${tmpDir}
mkdir -p \${bakupDir}

[[ -d \${tmpDiag} ]] && rm -rf \${tmpDiag}
mkdir -p \${tmpDiag}

echo \${cycN}
cycY=\`echo \${cycN} | cut -c 1-4\`
cycM=\`echo \${cycN} | cut -c 5-6\`
cycD=\`echo \${cycN} | cut -c 7-8\`
cycH=\`echo \${cycN} | cut -c 9-10\`
cycYMD=\`echo \${cycN} | cut -c 1-8\`

echo \${cycN1}
cyc1Y=\`echo \${cycN1} | cut -c 1-4\`
cyc1M=\`echo \${cycN1} | cut -c 5-6\`
cyc1D=\`echo \${cycN1} | cut -c 7-8\`
cyc1H=\`echo \${cycN1} | cut -c 9-10\`
cyc1YMD=\`echo \${cycN1} | cut -c 1-8\`
cyc1prefix=\${cyc1YMD}.\${cyc1H}0000


if [ -s ${CNTLDIR_ATMOS} ]; then
    ${NCP} ${LOGDIR} ${CNTLDIR}/log 

    ${NRM} ${CNTLDIR_ATMOS}/gdas.t??z.*?.txt
    ${NRM} ${CNTLDIR_ATMOS}/gdas.t??z.master.grb2f???
    

    CNTLDIR_ATMOS_BAKUP={ROTDIR}/${PSLOT}/dr-data/gdas.${GYMD}/${GH}
fi


NGRPS=\$((10#\${NMEM} / 10#\${NMEM_GRP}))

nanal=${NMEM_ENKF}
cycN=\`\${incdate} -6 ${CDATE}\`
cycN1=\`\${incdate} 6 \${cycN}\`

tmpDiag=\${tmpDir}/run_diag_\${cycN}
mkdir -p \${tmpDir}
mkdir -p \${bakupDir}

[[ -d \${tmpDiag} ]] && rm -rf \${tmpDiag}
mkdir -p \${tmpDiag}

echo \${cycN}
cycY=\`echo \${cycN} | cut -c 1-4\`
cycM=\`echo \${cycN} | cut -c 5-6\`
cycD=\`echo \${cycN} | cut -c 7-8\`
cycH=\`echo \${cycN} | cut -c 9-10\`
cycYMD=\`echo \${cycN} | cut -c 1-8\`

echo \${cycN1}
cyc1Y=\`echo \${cycN1} | cut -c 1-4\`
cyc1M=\`echo \${cycN1} | cut -c 5-6\`
cyc1D=\`echo \${cycN1} | cut -c 7-8\`
cyc1H=\`echo \${cycN1} | cut -c 9-10\`
cyc1YMD=\`echo \${cycN1} | cut -c 1-8\`
cyc1prefix=\${cyc1YMD}.\${cyc1H}0000

#hpssDir=/ESRL/BMC/wrf-chem/5year/Bo.Huang/JEDIFV3-AERODA/expRuns/
hpssExpDir=\${hpssDir}/\${expName}/dr-data/\${cycY}/\${cycY}\${cycM}/\${cycY}\${cycM}\${cycD}/
hsi "mkdir -p \${hpssExpDir}"

cntlGDAS=\${dataDir}/gdas.\${cycYMD}/\${cycH}/
cntlGDAS_atmos=\${dataDir}/gdas.\${cycYMD}/\${cycH}/atmos/
cntlGDAS_chem=\${dataDir}/gdas.\${cycYMD}/\${cycH}/chem/
cntlGDAS_diag=\${dataDir}/gdas.\${cycYMD}/\${cycH}/diag/

if [ -s \${cntlGDAS} ]; then
### Copy the logfiles
    /bin/cp -r \${logDir}/\${cycN} \${cntlGDAS}/\${cycN}_log
    /bin/rm -rf \${logDir}/\${cycN}/gdasensprepmet0[2-5].log \${cntlGDAS}/\${cycN}_log

### Clean unnecessary cntl files
    /bin/rm -rf \${cntlGDAS_atmos}/gdas.t??z.*?.txt
    /bin/rm -rf \${cntlGDAS_atmos}/gdas.t??z.master.grb2f???
    /bin/rm -rf \${cntlGDAS_atmos}/gdas.t??z.sfluxgrbf???.grib2
   
### Backup cntl data
    cntlBakup_RST=\${bakupDir}/gdas.\${cycYMD}/\${cycH}/atmos/RESTART
    cntlBakup_diag=\${bakupDir}/gdas.\${cycYMD}/\${cycH}/diag/
    mkdir -p \${cntlBakup_RST}
    mkdir -p \${cntlBakup_diag}
   
    /bin/cp -r \${cntlGDAS_diag}/* \${cntlBakup_diag}
    /bin/cp -r \${cntlGDAS_diag} \${tmpDiag}/diaggdas.\${cycN}
     
    /bin/cp -r \${cntlGDAS_atmos}/RESTART/\${cyc1prefix}.coupler* \${cntlBakup_RST}/
    /bin/cp -r \${cntlGDAS_atmos}/RESTART/\${cyc1prefix}.fv_core* \${cntlBakup_RST}/
    /bin/cp -r \${cntlGDAS_atmos}/RESTART/\${cyc1prefix}.fv_tracer* \${cntlBakup_RST}/
        
    ERR=\$?
    if [ \${ERR} -ne 0 ]; then
       echo "Copy Control gdas.\${cycN} failed and exit at error code \${ERR}"
       echo \${cycN} >> \${RECORDDIR}/\${HPSSRECORD}
       exit \${ERR}
    fi

    cd \${cntlGDAS}
    TARFILE=gdas.\${cycN}.tar
    htar -P -cvf \${hpssExpDir}/\${TARFILE} *

    ERR=\$?
    if [ \${ERR} -ne 0 ]; then
       echo "HTAR failed at gdas.\${cycN} and exit at error code \${ERR}"
       echo \${cycN} >> \${RECORDDIR}/\${HPSSRECORD}
       exit \${ERR}
    else
       echo "HTAR at gdas.\${cycN} completed !"
    fi
    
    if [ \${ENSRUN} = "YES" ]; then
    ### Start EnKF
        enkfGDAS=\${dataDir}/enkfgdas.\${cycYMD}/\${cycH}/
        enkfGDAS_atmos=\${dataDir}/enkfgdas.\${cycYMD}/\${cycH}/atmos
        enkfGDAS_chem=\${dataDir}/enkfgdas.\${cycYMD}/\${cycH}/chem
        enkfGDAS_diag=\${dataDir}/enkfgdas.\${cycYMD}/\${cycH}/diag

    ### Clean unnecessary enkf files
        /bin/rm -rf \${enkfGDAS_atmos}/mem???/*.txt

        enkfBakup_diag=\${bakupDir}/gdas.\${cycYMD}/\${cycH}/diag/
        mkdir -p \${enkfBakup_diag}
        /bin/cp -r \${enkfGDAS_diag}/* \${enkfBakup_diag}
        /bin/cp -r \${enkfGDAS_diag} \${tmpDiag}/diagenkfgdas.\${cycN}

    ### Backup ensemble mean files
        enkfGDAS_Mean_atmos=\${dataDir}/enkfgdas.\${cycYMD}/\${cycH}/atmos/ensmean
        enkfBakup_Mean_RST=\${bakupDir}/enkfgdas.\${cycYMD}/\${cycH}/atmos/ensmean/RESTART

        mkdir -p \${enkfBakup_Mean_RST}/
        #/bin/cp -r \${enkfGDAS_Mean}/obs \${enkfBakup_Mean}/
        /bin/cp -r \${enkfGDAS_Mean_atmos}/RESTART/\${cyc1prefix}.coupler* \${enkfBakup_Mean_RST}/
        /bin/cp -r \${enkfGDAS_Mean_atmos}/RESTART/\${cyc1prefix}.fv_tracer* \${enkfBakup_Mean_RST}/
        /bin/cp -r \${enkfGDAS_Mean_atmos}/RESTART/\${cyc1prefix}.fv_core* \${enkfBakup_Mean_RST}/

        ERR=\$?
        if [ \${ERR} -ne 0 ]; then
            echo "Copy ensmean gdas.\${cycN} failed and exit at error code \${ERR}"
            echo \${cycN} >> \${RECORDDIR}/\${HPSSRECORD}
            exit \${ERR}
        fi

#        ianal=1
#        while [ \${ianal} -le \${nanal} ]; do
#           memStr=mem\`printf %03i \$ianal\`
#
#           enkfGDAS_Mem_atmos=\${dataDir}/enkfgdas.\${cycYMD}/\${cycH}/atmos/\${memStr}
#
#           ERR=\$?
#           if [ \${ERR} -ne 0 ]; then
#               echo "Copy ensmem gdas.\${cycN} failed and exit at error code \${ERR}"
#               echo \${cycN} >> \${RECORDDIR}/\${HPSSRECORD}
#               exit \${ERR}
#           fi
#
#           ianal=\$[\$ianal+1]
#    
#        done

        if [ \$? != '0' ]; then
           echo "Copy EnKF enkfgdas.\${cycYMD}\${cycH} failed and exit at error code \$?"
            echo \${cycN} >> \${RECORDDIR}/\${HPSSRECORD}
           exit \$?
        fi
        
        # Tar ensemble files to HPSS
        IGRP=0
	LGRP_atmos=\${tmpDir}/list.atmos.grp\${IGRP}
	[[ -f \${LGRP_atmos} ]] && rm -rf \${LGRP_atmos}
	echo "ensmean" > \${LGRP_atmos}
        IGRP=1
        while [ \${IGRP} -le \${NGRPS} ]; do
            ENSED=\$((\${NMEM_GRP} * 10#\${IGRP}))
	    ENSST=\$((ENSED - NMEM_GRP + 1))
	    
	    LGRP_atmos=\${tmpDir}/list.atmos.grp\${IGRP}
	    LGRP_chem=\${tmpDir}/list.chem.grp\${IGRP}
	    [[ -f \${LGRP_atmos} ]] && rm -rf \${LGRP_atmos}
	    [[ -f \${LGRP_chem} ]] && rm -rf \${LGRP_chem}

	    #if [ \${IGRP} -eq 1 ]; then
	    #	echo "ensmean" > \${LGRP_atmos}
	    #fi

	    IMEM=\${ENSST}
	    while [ \${IMEM} -le \${ENSED} ]; do
		MEMSTR="mem"\`printf %03d \${IMEM}\`
                echo \${MEMSTR} >> \${LGRP_atmos}
                echo \${MEMSTR} >> \${LGRP_chem}
		IMEM=\$((IMEM+1))
	    done
	    IGRP=\$((IGRP+1))
	done

	IGRP=0
	while [ \${IGRP} -le \${NGRPS} ]; do
	    if [ \${IGRP} -eq 0 ]; then
	        TARFILE=enkfgdas.\${cycN}.atmos.ensmean.tar
	    else
	        TARFILE=enkfgdas.\${cycN}.atmos.grp\${IGRP}.tar
	    fi
	    LGRP=\${tmpDir}/list.atmos.grp\${IGRP}
	    cd \${enkfGDAS_atmos}
	    htar -P -cvf \${hpssExpDir}/\${TARFILE}  \$(cat \${LGRP})
	    ERR=\$?
	    echo \${ERR}
	    if [ \${ERR} -ne 0 ]; then
	        echo "HTAR failed at enkfgdas.\${cycN} and grp\${IGRP} and exit at error code \${ERR}"
          	echo \${cycN} >> \${RECORDDIR}/\${HPSSRECORD}
	    	exit \${ERR}
  	    else
  	        echo "HTAR at enkfgdas.\${cycN} completed !"
  	    fi



	    if [ \${IGRP} -ge 1 ]; then
	        TARFILE=enkfgdas.\${cycN}.chem.grp\${IGRP}.tar
	        LGRP=\${tmpDir}/list.chem.grp\${IGRP}
	        cd \${enkfGDAS_chem}
	        htar -P -cvf \${hpssExpDir}/\${TARFILE}  \$(cat \${LGRP})
	        ERR=\$?
	        echo \${ERR}
	        if [ \${ERR} -ne 0 ]; then
	            echo "HTAR failed at enkfgdas.\${cycN} and grp\${IGRP} and exit at error code \${ERR}"
          	    echo \${cycN} >> \${RECORDDIR}/\${HPSSRECORD}
	            exit \${ERR}
  	        else
  	            echo "HTAR at enkfgdas.\${cycN} completed !"
  	         fi
             fi
             IGRP=\$((IGRP+1))
	done
    fi #End of EnKF

    cd \${tmpDiag}
    TARFILE=diag.\${cycN}.tar
    htar -P -cvf \${hpssExpDir}/\${TARFILE} *

    ERR=\$?
    if [ \${ERR} -ne 0 ]; then
       echo "HTAR failed at gdas.\${cycN} and exit at error code \${ERR}"
       echo \${cycN} >> \${RECORDDIR}/\${HPSSRECORD}
       exit \${ERR}
    else
       echo "HTAR at gdas.\${cycN} completed !"
    fi

    if [ \${ERR} -eq 0 ]; then
        echo "HTAR is successful at \${cycN}"
	/bin/rm -rf \${enkfGDAS}
	/bin/rm -rf \${cntlGDAS}
	/bin/rm -rf \${tmpDiag}
    else
        echo "HTAR failed at \${cycN}"
        echo \${cycN} >> \${RECORDDIR}/\${HPSSRECORD}
        exit \${ERR}
    fi
    #cycN=\`\${incdate} \${cycInc}  \${cycN}\`
fi

exit 0
EOF

cd ${HERA2HPSSDIR}
sbatch job_hpss_${CDATE}.sh
ERR=$?

#sleep 60

exit ${ERR}
