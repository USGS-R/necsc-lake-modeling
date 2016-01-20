#NE-CSC lake modeling effort for MI, MN, WI state lakes

### Building the data files

Starting to use `remake` package to deal with the dependencies of inputs and outputs for processing data

```r
devtools::install_github("richfitz/storr")
devtools::install_github("richfitz/remake")

# then from the top level directory, 

library('remake')
make()
```