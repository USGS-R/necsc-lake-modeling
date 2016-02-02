#NE-CSC lake modeling effort for MI, MN, WI state lakes

This project contains all raw to intermediate data processing that goes into the modeling project [mda.lakes](https://github.com/USGS-R/mda.lakes) and the [lake attributes package](https://github.com/USGS-R/lakeattributes).

The building of the files is tracked from their raw (canonical) data sources and their intermediate storage after processing. Processing includes subsetting, filtering, aggregating, and averaging. 


## scope of this repo  
This repo does not store any large files, it stores summary files from processing jobs and instructions for processing and posting larger datasets. Each major dataset that is included in this study has three components: `sub` subsetting in time and/or space, `data` which includes the translation and manipulation of the raw file(s) coming from `sub`, and `summ` which is a summary of the processing and often involves a site-specific count or logical for the processing.   

We are attempting to capture all steps in the processing for the project in a repeatable set of scripts. The `remake` package facilitates this by allowing us to `make` the project and only process the steps that have dependencies that have changed or been updated. As such, the processing steps and dependencies are captured in the [remake.yml](remake.yml). The major datasets also have `configs` (see below) to specify the details of their processing. These `configs` are also dependencies of the processing steps, so if the configs change, several of the processing steps are likely to be re-run. 

## web processing or web access challenges  
We are accessing and slicing up large data using web resources, so things fail. In order to be robust to this and to also reduce kicking off very large jobs when small things change, the files used to make up the `sub` and `data` datasets are typically broken up into a collection of files that are named explicitly to enable processing only the relevant pieces. For example, the `NLDAS_sub` datasets are small(ish) .nc files that are split up across variables and time, where the number of time chunks is determined in the config (as is the variables used). So, when we extend the time range of the period (in the config) we only need to get rid of the last file in each variable, instead of one very large file. Likewise, the processing of this NLDAS data into lake-specific values is error prone, and we use a list of files that *should* be created and and index of files that already exist to specify the processing job. So, the first step of each processing job is to calculate this list of files, and then check which files are new and need to be created via processing jobs. This also makes it a bit easier to add new lakes or new variables to the processing. 

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
