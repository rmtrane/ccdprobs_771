#!/bin/bash

## Get path to project folder
project_folder=$(pwd | awk -F "/ccdprobs_771" '{print $1"/ccdprobs_771"}')

cd "$project_folder"/simulation

## Create folder if not already created
mkdir -p "simulated-data"

## For each data set that already has been estimated a tree for:
for data_folder in estimated-trees/*; do
  ## Get data name, i.e. name of directory
  data=$(basename $data_folder)
  ## Create correpsonding folder in "simulated_data"
  mkdir -p simulated-data/"$data"
  ## Start output file with the header from the original data file
  n_matrix=$(grep -n matrix original-data/"$data"/"$data".nex | cut -d ":" -f1)
  head -n "$n_matrix" original-data/"$data"/"$data".nex > simulated-data/"$data"/"$data"_sim_data.nex
  ## Copy needed summary files to new folder
  cp estimated-trees/"$data"/{stationary_distribution,transition_probabilities,"$data"_tree_for_sim.txt,n_chars} simulated-data/"$data"
  ## Go to folder
  cd simulated-data/"$data"/
  ## Create files to write to
  #touch {stat_for_bistro,tran_for_bistro}
  ## Run the julia script to simulate data
  julia "$project_folder"/scripts/julia/simulate_data.jl
  ## Update n_chars in .nex file
  nchars=$(head -n1 n_chars)
  sed -E "s/nchar=([0-9]+);/nchar=$nchars;/" "$data"_sim_data.nex > tmp.nex
  ## Get rid of " in output
  sed -E 's/"//g' tmp.nex > tmp1.nex; mv tmp1.nex "$data"_sim_data.nex; rm tmp.nex
  ## Go back to "simulation" folder
  cd "$project_folder"/simulation
done
