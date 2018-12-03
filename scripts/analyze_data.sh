#!/bin/bash

cd ~/Documents/UW-Madison/ccdprobs_771/real-data-analysis/
src_path="/Users/ralphmoellertran/Documents/UW-Madison/ccdprobs/src"

for folder in original-data/*; do
  data=$(basename $folder)

  mkdir -p mb-analysis/"$data"
  cp "$folder"/"$data".nex mb-analysis/"$data"/

  cd mb-analysis/"$data"

  mb "$data.nex" > mb_output.log
  "$src_path"/mbsum --skip 2001 "$data".nex.run1.t "$data".nex.run2.t --out "$data"_mbsum.out
  "$src_path"/ccdprobs --out "$data"_ccdprobs --in "$data"_mbsum.out

  cd -

  mkdir -p bistro-analysis/"$data"
  cp "$folder"/"$data".fasta bistro-analysis/"$data"

  cd bistro-analysis/"$data"

  bistro -f "$data".fasta -b 10000 -r 10000 > bistro_output.log

  cd -
done
