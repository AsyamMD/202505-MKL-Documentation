#!/bin/bash

# make working directory
mkdir -p ./0-buffer ./1-data

# for temperature
## define the function
temper() {
    infile="$1"
    base="$(basename "$infile" .nc)"
    echo "Processing temperature for $base"
    # processes for daily average
    cdo -O -L -P 4 -dayavg -vertmean -subc,273.15 "$infile" ./0-buffer/"${base}_dayavg.nc" # convert to degC
    ncrename -v t2m,tg ./0-buffer/"${base}_dayavg.nc" # rename variable t2m to tg
    ncatted -a units,tg,o,c,"degC" ./0-buffer/"${base}_dayavg.nc" # change units to degC

    # processes for daily maximum
    cdo -O -L -P 4 -daymax -vertmean -subc,273.15 "$infile" ./0-buffer/"${base}_daymax.nc" # daily maximum
    ncrename -v t2m,tx ./0-buffer/"${base}_daymax.nc" # rename variable tas to tx
    ncatted -a units,tx,o,c,"degC" ./0-buffer/"${base}_daymax.nc" # change units to degC

    # processes for daily minimum
    cdo -O -L -P 4 -daymin -vertmean -subc,273.15 "$infile" ./0-buffer/"${base}_daymin.nc" # daily minimu
    ncrename -v t2m,tn ./0-buffer/"${base}_daymin.nc" # rename variable tas to tn
    ncatted -a units,tn,o,c,"degC" ./0-buffer/"${base}_daymin.nc" # change units to degC
}

export -f temper

## execute in parallel
find ./tas -name "*.nc" | parallel -j 5 --bar temper {}

## concatenate for several periods
### dayavg
echo "Concatenating average temperature files..."
cdo -O -L -P 12 -cat ./0-buffer/*dayavg.nc ./0-buffer/era5land_tg_whole.nc
cdo -O -L -P 12 -z zstd,13 --shuffle -settaxis,1981-01-01,00:00:00,1day -seldate,1981-01-01T00:00:00,2017-12-31T23:59:59 ./0-buffer/era5land_tg_whole.nc ./1-data/era5land_tg_dayavg_1981-2017.nc
cdo -O -L -P 12 -z zstd,13 --shuffle -settaxis,1950-01-01,00:00:00,1day -seldate,1950-01-01T00:00:00,1980-12-31T23:59:59 ./0-buffer/era5land_tg_whole.nc ./1-data/era5land_tg_dayavg_1950-1980.nc
cdo -O -L -P 12 -z zstd,13 --shuffle -settaxis,1981-01-01,00:00:00,1day -seldate,1981-01-01T00:00:00,2024-12-31T23:59:59 ./0-buffer/era5land_tg_whole.nc ./1-data/era5land_tg_dayavg_1981-2024.nc
cdo -O -L -P 12 -z zstd,13 --shuffle -settaxis,2015-01-01,00:00:00,1day -seldate,2015-01-01T00:00:00,2024-12-31T23:59:59 ./0-buffer/era5land_tg_whole.nc ./1-data/era5land_tg_dayavg_2015-2024.nc

### daymax
echo "Concatenating maximum temperature files..."
cdo -O -L -P 12 -cat ./0-buffer/*daymax.nc ./0-buffer/era5land_tx_whole.nc
cdo -O -L -P 12 -z zstd,13 --shuffle -settaxis,1981-01-01,00:00:00,1day -seldate,1981-01-01T00:00:00,2017-12-31T23:59:59 ./0-buffer/era5land_tx_whole.nc ./1-data/era5land_tx_daymax_1981-2017.nc
cdo -O -L -P 12 -z zstd,13 --shuffle -settaxis,1950-01-01,00:00:00,1day -seldate,1950-01-01T00:00:00,1980-12-31T23:59:59 ./0-buffer/era5land_tx_whole.nc ./1-data/era5land_tx_daymax_1950-1980.nc
cdo -O -L -P 12 -z zstd,13 --shuffle -settaxis,1981-01-01,00:00:00,1day -seldate,1981-01-01T00:00:00,2024-12-31T23:59:59 ./0-buffer/era5land_tx_whole.nc ./1-data/era5land_tx_daymax_1981-2024.nc
cdo -O -L -P 12 -z zstd,13 --shuffle -settaxis,2015-01-01,00:00:00,1day -seldate,2015-01-01T00:00:00,2024-12-31T23:59:59 ./0-buffer/era5land_tx_whole.nc ./1-data/era5land_tx_daymax_2015-2024.nc

### daymin
echo "Concatenating minimum temperature files..."
cdo -O -L -P 12 -cat ./0-buffer/*daymin.nc ./0-buffer/era5land_tn_whole.nc
cdo -O -L -P 12 -z zstd,13 --shuffle -settaxis,1981-01-01,00:00:00,1day -seldate,1981-01-01T00:00:00,2017-12-31T23:59:59 ./0-buffer/era5land_tn_whole.nc ./1-data/era5land_tn_daymin_1981-2017.nc
cdo -O -L -P 12 -z zstd,13 --shuffle -settaxis,1950-01-01,00:00:00,1day -seldate,1950-01-01T00:00:00,1980-12-31T23:59:59 ./0-buffer/era5land_tn_whole.ncc ./1-data/era5land_tn_daymin_1950-1980.nc
cdo -O -L -P 12 -z zstd,13 --shuffle -settaxis,1981-01-01,00:00:00,1day -seldate,1981-01-01T00:00:00,2024-12-31T23:59:59 ./0-buffer/era5land_tn_whole.nc ./1-data/era5land_tn_daymin_1981-2024.nc
cdo -O -L -P 12 -z zstd,13 --shuffle -settaxis,2015-01-01,00:00:00,1day -seldate,2015-01-01T00:00:00,2024-12-31T23:59:59 ./0-buffer/era5land_tn_whole.nc ./1-data/era5land_tn_daymin_2015-2024.nc