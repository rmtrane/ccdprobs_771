#!/bin/bash

## Get path to project folder
project_folder=$(pwd | awk -F "/ccdprobs_771" '{print $1"/ccdprobs_771"}')
cd "$project_folder"/simulation/

for folder in mb-simulated-data/*; do
  data=$(basename $folder)

  mkdir -p for_plots/

  last_line=$(grep -En ";" "$folder"/"$data"_ccdprobs.tmap | cut -d ":" -f1)
  n_lines=$(wc -l "$folder"/"$data"_ccdprobs.tmap | sed "s/^[ \t]*//" | cut -d " " -f1)
  ## Get taxa
  head -n $last_line "$folder"/"$data"_ccdprobs.tmap > for_plots/"$data".taxa
  ## Get ccdprobs
  tail_n=$(($n_lines - $last_line))
  tail -n $tail_n "$folder"/"$data"_ccdprobs.tmap > for_plots/"$data"_mb.tmap

  last_line=$(grep -En ";" "$folder"/"$data"_ccdprobs.smap | cut -d ":" -f1)
  n_lines=$(wc -l "$folder"/"$data"_ccdprobs.smap | sed "s/^[ \t]*//" | cut -d " " -f1)
  tail_n=$(($n_lines - $last_line))
  tail -n $tail_n "$folder"/"$data"_ccdprobs.smap > for_plots/"$data"_mb.smap

done

for folder in bistro-simulated-data/*; do
  data=$(basename $folder)

  last_line=$(grep -En ";" "$folder"/run1-nopars.tmap | cut -d ":" -f1)
  n_lines=$(wc -l "$folder"/run1-nopars.tmap | sed "s/^[ \t]*//" | cut -d " " -f1)
  tail_n=$(($n_lines - $last_line))
  tail -n $tail_n "$folder"/run1-nopars.tmap > for_plots/"$data"_bistro.tmap

  last_line=$(grep -En ";" "$folder"/run1-nopars.smap | cut -d ":" -f1)
  n_lines=$(wc -l "$folder"/run1-nopars.smap | sed "s/^[ \t]*//" | cut -d " " -f1)
  tail_n=$(($n_lines - $last_line))
  tail -n $tail_n "$folder"/run1-nopars.smap > for_plots/"$data"_bistro.smap

done
