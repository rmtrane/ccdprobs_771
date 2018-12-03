#!/bin/bash

## Get path to project folder
project_folder=$(pwd | awk -F "/ccdprobs_771" '{print $1"/ccdprobs_771"}')
cd "$project_folder"/simulation

src_path="/Users/ralphmoellertran/Documents/UW-Madison/ccdprobs/src"

## Create folders if not already created
mkdir -p {mb-simulated-data,bistro-simulated-data}

## For each data set that already has been estimated a tree for:
for data_folder in simulated-data/*; do
  ## Get data name, i.e. name of directory
  data=$(basename $data_folder)
  ## Create directories for results of analyses
  mkdir -p {mb-simulated-data,bistro-simulated-data}/"$data"
  ## Copy .nex with simulated data to mb folder
  cp simulated-data/"$data"/"$data"_sim_data.nex mb-simulated-data/"$data"
  ## Go to mb folder, and run MrBayes on simulated data
  cd mb-simulated-data/"$data"
  mb "$data"_sim_data.nex > mb_output.log
  "$src_path"/mbsum --skip 2001 "$data"_sim_data.nex.run1.t "$data"_sim_data.nex.run2.t --out "$data"_mbsum.out
  "$src_path"/ccdprobs --out "$data"_ccdprobs --in "$data"_mbsum.out
  ## Go to bistro folder, copy relevant files, and run bistro on simulated data in .fasta file
  cd "$project_folder"/simulation/bistro-simulated-data/"$data"
  cp ../../simulated-data/"$data"/{"$data"_sim_data.fasta,stat_for_bistro,tran_for_bistro} .
  bistro -f "$data"_sim_data.fasta -b 10000 -r 10000 > bistro_output.log

  cd "$project_folder"/simulation
done
