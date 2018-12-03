#!/bin/bash

project_folder=$(pwd | awk -F "/ccdprobs_771" '{print $1"/ccdprobs_771"}')

cd "$project_folder"

for data_folder in simulation/original-data/*; do
#data_folder="simulation/original-data/whales"
    # Get name of data set
    data=$(basename $data_folder)
    ## Create folder, if it doesn't exists, to hold estimated tree
    mkdir -p simulation/estimated-trees/"$data"/

    ## Check if this has already been done
    if [ -f simulation/estimated-trees/"$data"_tree_for_sim.txt ]; then
        echo "A tree for $data has already been estimated. This will be skipped. To re-estimate, delete the file "$data"_tree_for_sim.txt"
        continue
    fi
    ## Create a temporary copy of the data in said folder (MrBayes doesn't allow the data to be in separate folder)
    cp "$data_folder"/"$data".nex simulation/estimated-trees/"$data"/.
    ## Go to the folder
    cd simulation/estimated-trees/"$data"
    ## Run MrBayes
    mb "$data.nex"
    ## From the original .nex file, get number of characters in aligned DNA
    grep -Eo "nchar=[0-9]+" "$data".nex | cut -d "=" -f2 > n_chars
    ## From .con.tre file, get consensus tree for simulation
    tail -n2 "$data".nex.con.tre | head -n1 | awk -F " = " '{print $2}' > "$data"_tree_for_sim.txt
    ## From .pstat file, get stationary distribution for simulation
    awk -F "\t" '$1 ~ /pi/ {print $1 "\t" $2}' "$data".nex.pstat > stationary_distribution
    ## From .pstat file, get transition probabilities
    awk -F "\t" '$1 ~ /r\([ACGT]<->[ACGT]\)/ {print $1 "\t" $2}' "$data".nex.pstat > transition_probabilities
    ## Remove temporary file
    rm "$data.nex"
    ## Go back to project_folder
    cd -
done
