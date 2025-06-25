#!/usr/bin/env python3

import os
import cdsapi
from random import randint
from time import sleep
import concurrent.futures

# --- Configuration ---
YS = 1966  # Start year
YE = 1966  # End year

# Geographical area
NORTH = 10
WEST = 90
SOUTH = -15
EAST = 145
AREA = [NORTH, WEST, SOUTH, EAST]  # Format: [North, West, South, East]

# Variables to download: API name -> short name for filename
VNAME = {
    '2m_temperature': 'tas',
    'total_precipitation': 'pr'
}

MONTHS = ['%02d' % m for m in range(1, 13)]
DAYS = ['%02d' % d for d in range(1, 32)] # API will adjust for actual days in month
TIMES = [
    '00:00', '01:00', '02:00', '03:00',
    '04:00', '05:00', '06:00', '07:00',
    '08:00', '09:00', '10:00', '11:00',
    '12:00', '13:00', '14:00', '15:00',
    '16:00', '17:00', '18:00', '19:00',
    '20:00', '21:00', '22:00', '23:00'
]
DATASET = "reanalysis-era5-land"
OUTPUT_BASE_DIR = "."  # Base directory for output files

MAX_WORKERS = 12
MAX_RETRIES_PER_FILE = 3
INITIAL_RETRY_DELAY_RANGE = (30, 180)

# --- Helper Functions ---

def download_era5_data(cds_client_instance, dataset_name, api_var_name, short_var_name, year_str, month_str, day_list, time_list, area_coords, base_output_dir):
    """
    Downloads a single ERA5-Land data file.
    Files will be saved under base_output_dir/short_var_name/filename.nc
    """
    # Create a directory for the specific variable if it doesn't exist
    variable_specific_output_dir = os.path.join(base_output_dir, short_var_name)
    os.makedirs(variable_specific_output_dir, exist_ok=True)
    
    # Filename includes variable, year, and month for clarity
    netcdf_filename = f"{short_var_name}_{year_str}_{month_str}.nc"
    netcdf_filepath = os.path.join(variable_specific_output_dir, netcdf_filename)

    if os.path.isfile(netcdf_filepath):
        print(f"File {netcdf_filepath} already on disk. Skipping.")
        return f"Skipped: {netcdf_filepath} (already exists)"

    request_params = {
        "variable": [api_var_name],
        "year": year_str,
        "month": month_str,
        "day": day_list,
        "time": time_list,
        "format": "netcdf",
        "area": area_coords,
	"download_format": "unarchived"
    }

    print(f"Requesting with cdsapi: {netcdf_filepath}")
    
    current_retry = 0
    while current_retry < MAX_RETRIES_PER_FILE:
        try:
            cds_client_instance.retrieve(dataset_name, request_params, netcdf_filepath)
            print(f"Successfully downloaded: {netcdf_filepath}")
            return f"Success: {netcdf_filepath}"
        except Exception as e:
            current_retry += 1
            wait_time = randint(INITIAL_RETRY_DELAY_RANGE[0], INITIAL_RETRY_DELAY_RANGE[1]) * current_retry
            print(f"Error downloading {netcdf_filepath} (Attempt {current_retry}/{MAX_RETRIES_PER_FILE}): {e}")
            if current_retry < MAX_RETRIES_PER_FILE:
                print(f"Retrying in {wait_time}s...")
                sleep(wait_time)
            else:
                print(f"Failed to download {netcdf_filepath} after {MAX_RETRIES_PER_FILE} attempts.")
                return f"Failed: {netcdf_filepath} after {MAX_RETRIES_PER_FILE} retries ({e})"
    
    return f"Failed: {netcdf_filepath} (exhausted retries)"


# --- Main Execution ---
if __name__ == "__main__":
    if not os.path.exists(OUTPUT_BASE_DIR) and OUTPUT_BASE_DIR != ".":
        # Create the main output base directory if it's specified and doesn't exist
        os.makedirs(OUTPUT_BASE_DIR, exist_ok=True)

    cds_service_client = cdsapi.Client() 

    tasks_to_submit = []

    # Iteration order: variable -> year -> month
    for api_variable_name, short_filename_prefix in VNAME.items():
        print(f"\nProcessing variable: {api_variable_name} (short name: {short_filename_prefix})")
        # Note: The variable-specific directory (e.g., ./tas/) 
        # will be created by the download_era5_data function.
        for year_int in range(YS, YE + 1):
            year_string = f"{year_int:04d}"
            for month_string in MONTHS:
                task_args = (
                    cds_service_client, 
                    DATASET,
                    api_variable_name,
                    short_filename_prefix, # This will be used for the directory name
                    year_string,
                    month_string,
                    DAYS,
                    TIMES,
                    AREA,
                    OUTPUT_BASE_DIR
                )
                tasks_to_submit.append(task_args)

    if not tasks_to_submit:
        print("No tasks to process. Check your year range and variable list.")
    else:
        print(f"\nFound {len(tasks_to_submit)} tasks. Starting parallel downloads with {MAX_WORKERS} workers using cdsapi...")

        with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
            future_to_task_details = {
                # Args for logging: (api_var, short_name, year, month)
                executor.submit(download_era5_data, *args): (args[2], args[3], args[4], args[5]) 
                for args in tasks_to_submit
            }

            for future in concurrent.futures.as_completed(future_to_task_details):
                task_details = future_to_task_details[future] 
                try:
                    result_message = future.result()
                    # The result_message will contain the full path, e.g., "Success: ./tas/tas_2024_01.nc"
                    print(f"Task ({task_details[1]}, {task_details[2]}-{task_details[3]}): {result_message}")
                except Exception as exc:
                    print(f"Task ({task_details[1]}, {task_details[2]}-{task_details[3]}) generated an unexpected exception during future.result(): {exc}")
    
    print("\nAll processing finished.")
