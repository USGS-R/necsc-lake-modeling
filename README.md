#NE-CSC lake modeling effort for MI, MN, WI state lakes

This project contains all raw to intermediate data processing that goes into the modeling project [mda.lakes](https://github.com/USGS-R/mda.lakes) and the [lake attributes package](https://github.com/USGS-R/lakeattributes).

The building of the files is tracked from their raw (canonical) data sources and their intermediate storage after processing. Processing includes subsetting, filtering, aggregating, and averaging. 


## scope of this repo  
This repo does not store any large files, it stores summary files from processing jobs and instructions for processing and posting larger datasets. Each major dataset that is included in this study has three components: `sub` subsetting in time and/or space, `data` which includes the translation and manipulation of the raw file(s) coming from `sub`, and `summ` which is a summary of the processing and often involves a site-specific count or logical for the processing.   

We are attempting to capture all steps in the processing for the project in a repeatable set of scripts. The `remake` package facilitates this by allowing us to `make` the project and only process the steps that have dependencies that have changed or been updated. As such, the processing steps and dependencies are captured in the [remake.yml](remake.yml). The major datasets also have `configs` (see below) to specify the details of their processing. These `configs` are also dependencies of the processing steps, so if the configs change, several of the processing steps are likely to be re-run. 

## web processing or web access challenges  
We are accessing and slicing up large data using web resources, so things fail. In order to be robust to this and to also reduce kicking off very large jobs when small things change, the files used to make up the `sub` and `data` datasets are typically broken up into a collection of files that are named explicitly to enable processing only the relevant pieces. For example, the `NLDAS_sub` datasets are small(ish) .nc files that are split up across variables and time, where the number of time chunks is determined in the config (as is the variables used). So, when we extend the time range of the period (in the config) we only need to get rid of the last file in each variable, instead of one very large file. Likewise, the processing of this NLDAS data into lake-specific values is error prone, and we use a list of files that *should* be created and and index of files that already exist to specify the processing job. So, the first step of each processing job is to calculate this list of files, and then check which files are new and need to be created via processing jobs. This also makes it a bit easier to add new lakes or new variables to the processing. 

## example processing pattern: NLDAS
Processing the NLDAS dataset for this project has several steps:
1) figure out the spatial range of the `NHD_sub` used. This will tell us what the spatial region is for processing. 
2) calculate the list of files to be created for `NLDAS_sub` using `calc_nldas_files()`. This writes "data/NLDAS_sub/NLDAS_file_list.tsv" which contains all file names for copying the NLDAS dataset to a more robust host
3) figure out which files already exist on the server with `nldas_server_files()`
4) copy and post files from the `calc_nlas_files()` to the host using `nccopy_nldas()`, which runs on the difference between the "NLDAS_file_list.tsv" and the server file list.
5) write and post a `.ncml` file that describes all of these datasets to the THREDDS server
6) write a log file of this process  

And after all of this is done, a similar process is followed to process these files into raw driver data for each lake in the study (i.e., a list of files to be created is generated, and this list is used to set up jobs with the help of the config). Since we are using `remake`, the processing doesn't start if the dependency (in this case, the file list) isn't changed. 

## end-product files from this project  
A lot of the outputs described here are intermediate. The actual end-product datasets that are used by the modeling workflow include driver data files for each lake split up by lake id and variable, large tables, or geospatial files: 
 * `NLDAS_nhd_{permID}_19790101.20160116_apcpsfc.RData` for `apcpsfc` data covering the 1979-01-01 to 2016-01-16 period from NLDAS. These data are hosted on cida-test.er.usgs.gov in a directory for use by the models. There is a `driver_index.tsv` in this directory that indexes these files. 
 * `depth_data.tsv` is created and hosted on sciencebase because it contains some data we can't share yet (so SB controls permissions)
 * `temperature_data.tsv` is hosted on sciencebase too
 * `clarity_data.tsv` is hosted on sciencebase
 * `nhd_necsc.shp` shapefiles are posted on sciencebase and exposed as a WFS/WMS
 
## intermediate files that summarize the end-product files  
These files *are* part of this repo (or will be when they exist)
 * `depth_data_summary.tsv` is a list of all `ids` with any depth data. No actual depth data is here because of data sharing reasons. 
 * `temperature_data_summary.tsv` is a file of `id`, `time.start`, `time.end`, and `num.samples` in the temperature timeseries file: `temperature_data.tsv` for each lake
 * `clarity_data_summary.tsv` is a file of `id`, `time.start`, `time.end`, and `num.samples` in the clarity timeseries file: `clarity_data.tsv` for each lake
 * `nhd_centroids.tsv` is a file that contains `id`, `lon`, `lat`, `area`, and `state` for each feature in the `nhd_necsc.shp` it is the canonical source of centroid info for each lake, and this info should not be duplicated elsewhere. 
 * `NLDAS_driver_file_list.tsv` is a list of all of the files that *should* exist on the cida-test web server, but not all of these files may be completely processed at any given time. Instead see `NLDAS_driver_index.tsv` for that
 * `NLDAS_driver_index.tsv` is a list of `id`, `time.start`, `time.end`, `variable`, and `file.name` for each file that *does* exist on the cida-test webserver. It is also available via http://cida-test.er.usgs.gov/mda.lakes/drivers_GLM_NLDAS/driver_index.tsv and now that I say that, it maybe shouldn't also exist in this repo (should maybe be temporary..and posted when it changes?)

## data types for this project

| file     | description                                                        |
|--------------|:-------------------------------------------------------------|
| `NHD_sub`     | [National Hydrography Dataset](http://nhd.usgs.gov/) is pulled from ftp, and subsetted to include area of interest   |
| `NHD_summ`    | `NHD_sub` is summarized into a .tsv hosted in this repository |
| `NLDAS_sub`   | the [North American Land Data Assimilation System](http://ldas.gsfc.nasa.gov/nldas/) data is subset to the area of interest (the extent of the NHD file) and uploaded to a thredds server for processing by the [Geo Data Portal](http://cida.usgs.gov/gdp) |
| `NLDAS_data`    | `NLDAS_sub` is processed to create lake-specific driver files according to the permIDs in `NHD_summ` |
| `NLDAS_summ`    | `NLDAS_data` is summarized into a .tsv hosted in this repository |
| `clarity_data`  | Water clarity data from the [Water Quality Portal](http://waterqualitydata.us/) and mapped to permIDs in `NHD_summ` |
| `clarity_summ`  | `clarity_data` is summarized into a .tsv hosted in this repository |
| `depth_data`  | Lake depth data mapped to permIDs in `NHD_summ` |
| `temperature_data`  | Water temperature data from the [Water Quality Portal](http://waterqualitydata.us/) and mapped to permIDs in `NHD_summ` |
| `temperature_summ`  | `temperature_data` is summarized into a .tsv hosted in this repository |

## development guidelines  

### configurations
files within the `configs` folder are used to define the processing routines, and are also dependencies of the make-like system used for data processing ([remake](https://github.com/richfitz/remake)). We are currently setting these config files up for each step above in the data types table, and they should be named appropriately relative to that convention (e.g., "configs/NHD_sub_config.yml").  

### functions vs scripts
since we are using [remake](https://github.com/richfitz/remake), processing scripts should be based on functions that have a working directory at the top level of this project. These functions can take inputs that are related to other outputs, or can internally define processing parameters based on the `config` for the file output.

### file outputs
Each function should have some kind of trackable output that stays locally. For example, `NHD_sub` is an external file that is posted as a result of processing, but `NHD_summ` is a summary file that holds data that summarizes that file and any of the important processing steps (and warnings if applicable).  

Most files generated by this project will not be hosted by this repository as they are too large. Details for accessing them from their actual destinations should be included in the `_summ` files. 


## dependencies
`yaml`, `remake`, `storr`, `dplyr`, `rgeos`, `rgdal`, `geoknife` are used. These dependencies should also be tracked in the `remake` yaml files. 

### Building the data files

Starting to use `remake` package to deal with the dependencies of inputs and outputs for processing data

```r
devtools::install_github("richfitz/storr")
devtools::install_github("richfitz/remake")

# then from the top level directory, 

library('remake')
make()
```
