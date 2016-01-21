#NE-CSC lake modeling effort for MI, MN, WI state lakes

This project contains all raw to intermediate data processing that goes into the modeling project [mda.lakes](https://github.com/USGS-R/mda.lakes) and the lake attributes package [lakeattributes](https://github.com/USGS-R/lakeattributes).

The building of the files is tracked from their raw (canonical) data sources and their intermediate storage after processing. Processing includes subsetting, filtering, aggregating, and averaging. 

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
| `temperature_data`  | Water temperature data from the [Water Quality Portal](http://waterqualitydata.us/) and mapped to permIDs in `NHD_summ` |
| `temperature_summ`  | `clarity_data` is summarized into a .tsv hosted in this repository |

## dependencies
`yaml`, `remake`, `storr`, `dplyr`, `rgeos`, `rgdal`, `geoknife`

### Building the data files

Starting to use `remake` package to deal with the dependencies of inputs and outputs for processing data

```r
devtools::install_github("richfitz/storr")
devtools::install_github("richfitz/remake")

# then from the top level directory, 

library('remake')
make()
```