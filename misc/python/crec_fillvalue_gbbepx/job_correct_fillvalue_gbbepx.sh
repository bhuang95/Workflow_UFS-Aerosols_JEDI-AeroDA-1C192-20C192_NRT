#!/bin/bash

#module use -a /contrib/anaconda/modulefiles
#module load anaconda/latest
#module load nco

vars="BC CO CO2 MeanFRP NH3 NOx OC PM2.5 SO2"
echo ${vars} > invar.nml

echo "Correcting gbbepx fillValues forward"
python correct_fillvalue_gbbepx.py  -v invar.nml -a forward
ERR=$?
[[ ${ERR} -ne 0 ]] && exit 100

echo "Modify fillValue to -9999.0"
for var in ${vars}; do
    echo ${var}
    ncatted -a _FillValue,${var},m,f,-9999. input.nc
    ERR=$?
    [[ ${ERR} -ne 0 ]] && exit 100
done

python correct_fillvalue_gbbepx.py  -v invar.nml -a backward
ERR=$?
[[ ${ERR} -ne 0 ]] && exit 100

exit ${ERR}
