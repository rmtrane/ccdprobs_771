#!/bin/bash

## Get path to project folder
project_folder=$(pwd | awk -F "/ccdprobs_771" '{print $1"/ccdprobs_771"}')
cd "$project_folder"/simulation

## Path to mbsum and ccdprobs:
src_path="/Users/ralphmoellertran/Documents/UW-Madison/ccdprobs/src"

for folder in mb-simulated-data/*; do
  data=$(basename $folder)
  "$src_path"/mbsum --skip 10001 "$folder"/"$data"_sim_data.nex.run1.t "$folder"/"$data"_sim_data.nex.run2.t --out "$folder/$data"_mbsum.out
  "$src_path"/ccdprobs --out "$folder/$data"_ccdprobs --in "$folder/$data"_mbsum.out
done
