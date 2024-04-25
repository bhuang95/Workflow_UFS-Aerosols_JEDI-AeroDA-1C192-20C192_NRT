#!/bin/bash

squeue | grep Bo.Huang > sjobs.log
FNUM=$(cat sjobs.log | wc -l)

IL=1
while [ ${IL} -le ${FNUM} ]; do
   JOBID=$(sed -n ${IL}p sjobs.log | awk -F " " '{print $1}')
   JOBNAME=$(scontrol show job ${JOBID} | grep StdOut)
   echo ${JOBNAME}
   IL=$((${IL}+1))
done

