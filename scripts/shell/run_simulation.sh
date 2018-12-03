#!/bin/bash

project_folder=$(pwd | awk -F "/ccdprobs_771" '{print $1"/ccdprobs_771"}')
cd "$project_folder"/scripts/shell

bash estimate_trees.sh
bash simulate_data.sh
bash analyse_sim_data.sh
#bash mbsum_ccdprobs.sh
