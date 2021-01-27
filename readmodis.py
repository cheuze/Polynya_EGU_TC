# -*- coding: utf-8 -*-
"""
Created on Fri Dec 11 08:43:19 2020

@author: xheuce
"""

from pyhdf.SD import SD, SDC 

import xarray as xr

import numpy as np
import glob

file_list = glob.glob('MYD*.hdf')

#----------------------------------------------------------------------------------------#
# Read bits function

def bits_stripping(bit_start,bit_count,value):
	bitmask=pow(2,bit_start+bit_count)-1
	return np.right_shift(np.bitwise_and(value,bitmask),bit_start)

#----------------------------------------------------------------------------------------#


for f in file_list:

# Read HDF Files

    file = SD(f, SDC.READ)
    try:
        data_selected_id = file.select('Cloud_Mask')
        data = data_selected_id.get()

        data_shape = data.shape
    

# Extract flags

# creating a Dataframe with keys and values
        df = xr.Dataset()
        df['status_flag'] = xr.DataArray(bits_stripping(0,1,data[0,:,:])) 
        df['cloudmask_flag_bit1'] = xr.DataArray(bits_stripping(1,1,data[0,:,:]))
        df['cloudmask_flag_bit2'] = xr.DataArray(bits_stripping(2,1,data[0,:,:]))
        df['daynight_flag'] = xr.DataArray(bits_stripping(3,1,data[0,:,:]))
        df['sunglint_flag'] = xr.DataArray(bits_stripping(4,1,data[0,:,:]))
        df['icebackground_flag'] = xr.DataArray(bits_stripping(5,1,data[0,:,:]))
        df['landwater_flag_bit1'] = xr.DataArray(bits_stripping(6,1,data[0,:,:]))
        df['landwater_flag_bit2'] = xr.DataArray(bits_stripping(7,1,data[0,:,:]))
    
        filename=f[0:-4] + '.nc'
        df.to_netcdf(path=filename)
    except:
        pass

    
#    xr.Dataset.to_netcdf(path='C:\Users\xheuce\Desktop\' filename, mode='w', format="NETCDF4_CLASSIC", group=None, engine=None, encoding=None, unlimited_dims=None, compute=True, invalid_netcdf=False)
    
    
    