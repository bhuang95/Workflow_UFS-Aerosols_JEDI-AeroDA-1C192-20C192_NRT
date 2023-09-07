import datetime as dt
import netCDF4 as nc
import os, argparse
import numpy as np

'''
Command:
    python correct_fillvalue_gbbepx.py -v INVARS.nml -a forward
'''

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=(
            'Replace background aerosol file with JEDI aerosol analysis'
        )
    )


    required = parser.add_argument_group(title='required arguments')

    required.add_argument(
        '-v', '--variable',
        help="Input file containing the  variables",
        type=str, required=True)

    required.add_argument(
        '-a', '--action',
        help="Change fill values",
        type=str, required=True)


    args = parser.parse_args()
    invarnml = args.variable
    actfv = args.action

    infile='input.nc'

    with open(invarnml, 'r') as fd:
	    invars=fd.read().strip().split(' ')
    print(invars)

    #small_value = np.finfo(np.float64).eps  #1E-30
    small_value = 1E-30

    with nc.Dataset(infile,'a') as infile:
        for vname in invars:
            print(vname)
            indata = infile.variables[vname][:]
            #np.savetxt('indata.out', indata[0,:,:])
            if actfv == "forward": 
                fv = infile.variables[vname]._FillValue
                val = small_value
            elif actfv == "backward":
                fv = small_value
                val = np.float64(0.0)
            else:
                print("Please define action = forward or backward")
                exit(100)
            indata[np.abs(indata-fv) <= small_value] = val
            infile.variables[vname][:] = indata[:]
