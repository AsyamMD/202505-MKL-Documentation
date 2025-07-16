# Data Preprocessing

Since we used datasets from several sources, we need to preprocess the data to make it easier to analyse. The preprocessing mainly used CDO and NCO, which are powerful tools for manipulating climate data. Because the datasets are a lot, we will automate the process using bash scripts. In every scripts, we will utilize multiple threads to speed up the process. The number of threads are defined by either `-P` or `-j` option. To know how many threads available on your system, you can use the command `nproc`. To not overwhelm the system, we will use half of the available threads, so if you have 8 threads, you can use `-P 4` or `-j 4`.

## Remapping and Unifying Variable Names

### Folder Structure
---------
Managing files is crucial in this research. We will create a folder structure to organize the datasets and scripts. The folder structure is as follows:

```
scenario
├── historical
|   ├── 0-scripts
|   ├── scenario_historical_pr_year1-year2.nc
|   ├── scenario_historical_tg_year1-year2.nc
|   ├── scenario_historical_tn_year1-year2.nc
|   └──scenario_historical_tx_year1-year2.nc
├── ssp126
|   ├── 0-scripts
|   ├── scenario_ssp126_pr_year1-year2.nc
|   ├── scenario_ssp126_tg_year1-year2.nc
|   ├── scenario_ssp126_tn_year1-year2.nc
|   └── scenario_ssp126_tx_year1-year2.nc
├── ssp245
|   ├── 0-scripts
|   ├── scenario_ssp245_pr_year1-year2.nc
|   ├── scenario_ssp245_tg_year1-year2.nc
|   ├── scenario_ssp245_tn_year1-year2.nc
|   └── scenario_ssp245_tx_year1-year2.nc
├── ssp370
|   ├── 0-scripts
|   ├── scenario_ssp370_pr_year1-year2.nc
|   ├── scenario_ssp370_tg_year1-year2.nc
|   ├── scenario_ssp370_tn_year1-year2.nc
|   └── scenario_ssp370_tx_year1-year2.nc
└── ssp585
    ├── 0-scripts
    ├── scenario_ssp585_pr_year1-year2.nc
    ├── scenario_ssp585_tg_year1-year2.nc
    ├── scenario_ssp585_tn_year1-year2.nc
    └── scenario_ssp585_tx_year1-year2.nc

```

The `0-scripts` folder contains the scripts to download each dataset. We separate the files structure for each scenario: historical, ssp126, ssp245, ssp370, and ssp585. Each scenario folder contains the scripts and the downloaded datasets. The naming system for datasets managed by ESGF follows this format: `{variable}_{frequencies}_{scenario}_{experiment_id}_{forcing}_{grid_label}_{start_date}-{end_date}.nc`. For example, 'pr_day_CNRM-CM6-1-HR_historical_r1i1p1f2_gr_19500101-19741231.nc' is a daily precipitation dataset from the CNRM-CM6-1-HR model for the historical scenario, with a grid label of 'gr', and covering the period from January 1, 1950, to December 31, 1974.

This folder structure will help us to preprocess the data easily. We can run the script in the top-level folder, and it will process all the datasets in the subfolders. The scripts will be explained in the next section. Before that, we need to create a container folder for all of our preprocessed data, named `00-history`. To tidy up the file naming, we will use the following format: `{scenario}_{variable}_historical.nc` for ESGF datasets, and `{scenario}_{variable}_{year1}-{year2}.nc` for SA-OBS and ERA5-Land datasets. The `00-history` folder will contain the preprocessed datasets, which will be used for further analysis.

Also, we will create a txt file named `0-grid.txt` in the top-level folder. This file will contain the grid information for remapping the datasets. The content of the file is as follows:

```
gridtype = lonlat
xsize    = 551
ysize    = 251
xfirst   = 90
xinc     = 0.1
yfirst   = -15
yinc     = 0.1
```

This will clip the datasets to the region of interest, which is Indonesia. The horizontal resolution is 0.1 degrees, which is approximately 11 km at the equator. The grid will cover the region from 90°E to 145°E and from 15°S to 10°N.

## SA-OBS

Since SA-OBS is obtained from a different source than ESGF, we will preprocess it separately. The folder is `sa-obs`, in which had two subfolders: `1-data` and `2-stderr`. The `1-data` folder contains the raw data, while the `2-stderr` folder contains the standard error data. Below is the script to preprocess the SA-OBS data, take note that the script is located on the top-level folder, not in the `sa-obs` folder:

```shell
#!/bin/bash

# remapping and adjusting time axis
cdo -O -L -P 12 -f nc4 -z zstd,13 --shuffle -setmissval,nan \
    -remapnn,0-grid.txt \
    -settaxis,1950-01-01,00:00:00,1day \
    "./sa-obs/1-data/rr_0.25deg_reg_v2.0_saobs.nc" "./00-history/sa-obs_pr_1981-2017.nc"

cdo -O -L -P 12 -f nc4 -z zstd,13 --shuffle -setmissval,nan \
    -remapnn,0-grid.txt \
    -settaxis,1981-01-01,00:00:00,1day \
    "./sa-obs/1-data/tg_0.25deg_reg_v2.0_saobs.nc" "./00-history/sa-obs_tg_1981-2017.nc"

cdo -O -L -P 12 -f nc4 -z zstd,13 --shuffle -setmissval,nan \
    -remapnn,0-grid.txt \
    -settaxis,1981-01-01,00:00:00,1day \
    "./sa-obs/1-data/tx_0.25deg_reg_v2.0_saobs.nc" "./00-history/sa-obs_tx_1981-2017.nc"

cdo -O -L -P 12 -f nc4 -z zstd,13 --shuffle -setmissval,nan \
    -remapnn,0-grid.txt \
    -settaxis,1981-01-01,00:00:00,1day \
    "./sa-obs/1-data/tn_0.25deg_reg_v2.0_saobs.nc" "./00-history/sa-obs_tn_1981-2017.nc"

# renaming precipitation variable
ncrename -O -v rr,pr "./00-history/sa-obs_pr_1981-2017.nc"
```

We will unify all the datasets' missing value to NaN. The variable names will be standardized to `pr`, `tg`, `tn`, and `tx` for precipitation, temperature (mean), minimum temperature, and maximum temperature, respectively.

## ERA5-Land

Compared to other datasets, the ERA5-Land is in hourly frequency, as they do not provide daily sum precipitation. Inside the `era5-land` folder, there will be two subfolder named `pr` and `tas`, which contains the precipitation and temperature datasets, respectively. The script to preprocess the ERA5-Land data is as follows:

```shell
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
cdo -O -L -P 12 -cat -f nc4 -z zstd,13 --shuffle -setmissval,nan \
    -settaxis,1950-01-01,00:00:00,1day \
    [ -cat ./0-buffer/pr*.nc ] ./1-data/era5land_pr_complete.nc

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
cdo -O -L -P 12 -z zstd,13 --shuffle -setmissval,nan \
   -settaxis,1950-01-01,00:00:00,1day \
   [ -cat ./0-buffer/*dayavg.nc ] ./1-data/era5land_tg_complete.nc

### daymax
echo "Concatenating maximum temperature files..."
cdo -O -L -P 12 -z zstd,13 --shuffle -setmissval,nan \
   -settaxis,1950-01-01,00:00:00,1day \
   [ -cat ./0-buffer/*daymax.nc ] ./1-data/era5land_tx_complete.nc

### daymin
echo "Concatenating minimum temperature files..."
cdo -O -L -P 12 -z zstd,13 --shuffle -setmissval,nan \
   -settaxis,1950-01-01,00:00:00,1day \
   [ -cat ./0-buffer/*daymin.nc ] ./1-data/era5land_tn_complete.nc
```

The script above will process the raw downloaded ERA5-Land data, which is in hourly frequency, to daily frequency. The precipitation will be summed up to daily total, while the temperature will be averaged, maximum, and minimum to daily frequency. The output will be saved in the `1-data` folder, with the variable names standardized to `pr`, `tg`, `tn`, and `tx` for precipitation, temperature (mean), minimum temperature, and maximum temperature, respectively.

After that, we need to remap the datasets to the Indonesia region using the `0-grid.txt` file and change several variable names to match with the other datasets.

```shell
#!/bin/bash

# change projection system
cdo -O -L -P 12 -f nc4 -z zstd,13 --shuffle -setmissval,nan \
    -remapnn,0-grid.txt \
    -settaxis,1950-01-01,00:00:00,1day \
    "./era5-land/1-data/pr_daysum_complete.nc" "./00-history/era5-land_pr_1950-2024.nc"

cdo -O -L -P 12 -f nc4 -z zstd,13 --shuffle -setmissval,nan \
    -remapnn,0-grid.txt \
    -settaxis,1950-01-01,00:00:00,1day \
    "./era5-land/1-data/tg_dayavg_complete.nc" "./00-history/era5-land_tg_1950-2024.nc"

cdo -O -L -P 12 -f nc4 -z zstd,13 --shuffle -setmissval,nan \
    -remapnn,0-grid.txt \
    -settaxis,1950-01-01,00:00:00,1day \
    "./era5-land/1-data/tx_daymax_complete.nc" "./00-history/era5-land_tx_1950-2024.nc"

cdo -O -L -P 12 -f nc4 -z zstd,13 --shuffle -setmissval,nan \
    -remapnn,0-grid.txt \
    -settaxis,1950-01-01,00:00:00,1day \
    "./era5-land/1-data/tn_daymin_complete.nc" "./00-history/era5-land_tn_1950-2024.nc"

# renaming variable names
ncrename -O -v valid_time,time "./00-history/era5-land_pr_1950-2024.nc"
ncrename -O -v valid_time,time "./00-history/era5-land_tg_1950-2024.nc"
ncrename -O -v valid_time,time "./00-history/era5-land_tx_1950-2024.nc"
ncrename -O -v valid_time,time "./00-history/era5-land_tn_1950-2024.nc"

ncrename -O -v latitude,lat "./00-history/era5-land_pr_1950-2024.nc"
ncrename -O -v latitude,lat "./00-history/era5-land_tg_1950-2024.nc"
ncrename -O -v latitude,lat "./00-history/era5-land_tx_1950-2024.nc"
ncrename -O -v latitude,lat "./00-history/era5-land_tn_1950-2024.nc"

ncrename -O -v longitude,lon "./00-history/era5-land_pr_1950-2024.nc"
ncrename -O -v longitude,lon "./00-history/era5-land_tg_1950-2024.nc"
ncrename -O -v longitude,lon "./00-history/era5-land_tx_1950-2024.nc"
ncrename -O -v longitude,lon "./00-history/era5-land_tn_1950-2024.nc"

# select date for data training
cdo -O -L -P 12 -f nc4 -z zstd,13 --shuffle \
    -seldate,1981-01-01T00:00:00,2017-12-31T23:59:59 \
    -settaxis,1981-01-01,00:00:00,1day \
    "./00-history/era5-land_pr_1950-2024.nc" "./00-history/era5-land_pr_1981-2017.nc"

cdo -O -L -P 12 -f nc4 -z zstd,13 --shuffle \
    -seldate,1981-01-01T00:00:00,2017-12-31T23:59:59 \
    -settaxis,1981-01-01,00:00:00,1day \
    "./00-history/era5-land_tg_1950-2024.nc" "./00-history/era5-land_tg_1981-2017.nc"

cdo -O -L -P 12 -f nc4 -z zstd,13 --shuffle \
    -seldate,1981-01-01T00:00:00,2017-12-31T23:59:59 \
    -settaxis,1981-01-01,00:00:00,1day \
    "./00-history/era5-land_tx_1950-2024.nc" "./00-history/era5-land_tx_1981-2017.nc"
    
cdo -O -L -P 12 -f nc4 -z zstd,13 --shuffle \
    -seldate,1981-01-01T00:00:00,2017-12-31T23:59:59 \
    -settaxis,1981-01-01,00:00:00,1day \
    "./00-history/era5-land_tn_1950-2024.nc" "./00-history/era5-land_tn_1981-2017.nc"
```

## CMIP6 ESGF Datasets

Just as previously mentioned, the ESGF datasets are stored in each scenario folder, which had the same structure. Since the datasets are too many, we will create a single bash script to preprocess all of the datasets. The script will be placed in the top-level folder, and it will process all of the datasets in the subfolders. The script is as follows:

```shell
#!/bin/bash

scenario=(
    "access-cm2"
    "cnrm-cm6-1-HR"
    "ec-earth3"
    "ec-earth3-veg"
    "hadgem3-gc31-mm"
    "mpi-esm1-2-hr"
)

vars=(
  "pr"
  "tas"
  "tasmax"
  "tasmin"
)

# --- Logging Setup ---
# Define a log file with a timestamp to capture all script output (stdout and stderr).
LOG_FILE="./00-history-processing_$(date +%Y%m%d_%H%M%S).log"
# Use `exec` and `tee` to redirect all subsequent output to both the console and the log file.
exec &> >(tee -a "$LOG_FILE")
echo "Script output will be logged to: $LOG_FILE"

# make working directory
mkdir -p ./00-history/ 

# The `history-revv` function was not called and contained syntax errors.
# The logic has been moved to the main script body and corrected.
# Loop variables are renamed to `s` and `v` to avoid shadowing the global arrays.
for s in "${scenario[@]}"; do
    for v in "${vars[@]}"; do
        # Use `mapfile` to safely read file paths from `find` into an array.
        # This is more robust than using a simple string variable.
        mapfile -t input_files < <(find "./${s}/historical/" -name "${v}_*.nc" | sort)

        # Check if any files were found before proceeding.
        if [ ${#input_files[@]} -eq 0 ]; then
            echo "No input files found for scenario: ${s}, variable: ${v}"
            echo "============================"
            echo " "
            continue # Skip to the next iteration
        fi

        # 1. Remap each file to a temporary directory before concatenating
        remap_dir="./${s}/historical/1-remap/"
        mkdir -p "$remap_dir"
        remapped_files=() # Create an array to hold paths of remapped files

        echo "Remapping ${#input_files[@]} files for ${s} / ${v}..."
        for infile in "${input_files[@]}"; do
            base=$(basename "$infile" .nc)
            remap_file="${remap_dir}/${base}_remap.nc"
            cdo -O -L remapnn,0-grid.txt "$infile" "$remap_file"
            remapped_files+=("$remap_file") # Add remapped file to our list
        done

        # 2. Define output variable names and processing logic using a clean `case` statement
        output_var_name=""
        cdo_operator=""
        units=""
        case "$v" in
          "pr")
            output_var_name="pr"
            cdo_operator="-mulc,86400"
            units="mm/day"
            ;;
          "tas")
            output_var_name="tg"
            cdo_operator="-subc,273.15"
            units="degC"
            ;;
          "tasmax")
            output_var_name="tx"
            cdo_operator="-subc,273.15"
            units="degC"
            ;;
          "tasmin")
            output_var_name="tn"
            cdo_operator="-subc,273.15"
            units="degC"
            ;;
        esac

        echo "Concatenating remapped files for ${s} / ${v} and creating final output..."
        echo "============================"
        echo " "

        # 3. Process the remapped files and save to the final output file
        output_file="./00-history/${s}_${output_var_name}_historical.nc"
        
        cdo -O -L -P 12 -z zstd,13 --shuffle -setmissval,nan \
        ${cdo_operator} \
        -settaxis,1950-01-01,00:00:00,1day \
        -seldate,1950-01-01T00:00:00,2014-12-31T23:59:59 \
        -cat "${remapped_files[@]}" "$output_file"

        # 4. Rename the variable inside the NetCDF file and update its units attribute
        ncrename -O -v "${v},${output_var_name}" "$output_file"
        ncatted -O -a "units,${output_var_name},o,c,${units}" "$output_file"

        # 5. Clean up the temporary directory
        rm -rf "$remap_dir"
    done
done

echo "All processing complete."

# Calculate and display the total script execution time.
duration=$SECONDS
echo "Total execution time: $(($duration / 60)) minutes and $(($duration % 60)) seconds."
```

Thankfully, all of the ESGF datasets have the same attributes and variable names, so we do not need to change the variable and attributes names. Keep in mind that the script above will take a long time to run, so be patient. In my case, using Intel i7-12700H with 20 threads, 40 GB of RAM, and WSL1, it took around 60 minutes to process all of the datasets. The output will be saved in the `00-history` folder, with the variable names standardized to `pr`, `tg`, `tn`, and `tx` for precipitation, temperature (mean), minimum temperature, and maximum temperature, respectively.