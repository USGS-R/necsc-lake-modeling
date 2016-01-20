This is the ncml file used to aggregate the NLDAS MIWIMN data
```xml
<?xml version="1.0" encoding="UTF-8"?>
<netcdf xmlns="http://www.unidata.ucar.edu/namespaces/netcdf/ncml-2.2">
    <aggregation type="union">    
		<netcdf>
			<aggregation type="joinExisting" dimName="time">
                <scan location="." suffix="_apcpsfc.nc" />
			</aggregation>
		</netcdf>
		<netcdf>
			<aggregation type="joinExisting" dimName="time">
                <scan location="." suffix="_dswrfsfc.nc" />
			</aggregation>
		</netcdf>
		<netcdf>
			<aggregation type="joinExisting" dimName="time">
                <scan location="." suffix="_pressfc.nc" />
			</aggregation>
		</netcdf>
		<netcdf>
			<aggregation type="joinExisting" dimName="time">
                <scan location="." suffix="_spfh2m.nc" />
			</aggregation>
		</netcdf>
		<netcdf>
			<aggregation type="joinExisting" dimName="time">
                <scan location="." suffix="_tmp2m.nc" />
			</aggregation>
		</netcdf>
		<netcdf>
			<aggregation type="joinExisting" dimName="time">
                <scan location="." suffix="_ugrd10m.nc" />
			</aggregation>
		</netcdf>
		<netcdf>
			<aggregation type="joinExisting" dimName="time">
                <scan location="." suffix="_vgrd10m.nc" />
			</aggregation>
		</netcdf>
		<netcdf>
			<aggregation type="joinExisting" dimName="time">
                <scan location="." suffix="_dlwrfsfc" />
			</aggregation>
		</netcdf>
	</aggregation>	
</netcdf>
```
