#!/bin/bash

# make working directory
mkdir -p ./0-buffer ./1-data

# for precipitation
## define the function
precip() {
    infile="$1"
    base="$(basename "$infile" .nc)"
    echo "Processing precipitation for $base"
    cdo -O -L -P 4 -daysum -mulc,1000 "$infile" ./0-buffer/"${base}_daysum.nc" # convert to mm/day
    ncrename -v tp,pr ./0-buffer/"${base}_daysum.nc" # rename variable tp to pr
    ncatted -a units,pr,o,c,"mm" ./0-buffer/"${base}_daysum.nc" # change units to mm
}

export -f precip

## execute in parallel
find ./pr -name "*.nc" | parallel -j 5 --bar precip {}

## concatenate for several periods
echo "Concatenating precipitation files..."
cdo -O -L -P 12 -cat ./0-buffer/pr*.nc ./0-buffer/era5land_pr_whole.nc
cdo -O -L -P 12 -z zstd,13 --shuffle -settaxis,1981-01-01,00:00:00,1day -seldate,1981-01-01T00:00:00,2017-12-31T23:59:59 ./0-buffer/era5land_pr_whole.nc ./1-data/era5land_pr_1981-2017.nc
cdo -O -L -P 12 -z zstd,13 --shuffle -settaxis,1950-01-01,00:00:00,1day -seldate,1950-01-01T00:00:00,1980-12-31T23:59:59 ./0-buffer/era5land_pr_whole.nc ./1-data/era5land_pr_1950-1980.nc
cdo -O -L -P 12 -z zstd,13 --shuffle -settaxis,1981-01-01,00:00:00,1day -seldate,1981-01-01T00:00:00,2024-12-31T23:59:59 ./0-buffer/era5land_pr_whole.nc ./1-data/era5land_pr_1981-2024.nc
cdo -O -L -P 12 -z zstd,13 --shuffle -settaxis,2015-01-01,00:00:00,1day -seldate,2015-01-01T00:00:00,2024-12-31T23:59:59 ./0-buffer/era5land_pr_whole.nc ./1-data/era5land_pr_2015-2024.nc