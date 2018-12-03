cur_path=$(pwd)
cur_dir=$(basename $cur_path)

while [ ! "$cur_dir" = "ccdprobs_771" ]; do
  cur_path=$(dirname $cur_path)
  cur_dir=$(basename $cur_path)
done

echo $cur_path
