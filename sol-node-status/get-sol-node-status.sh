#!/bin/bash
# VERSION: 0.7
# BLAME: Jason <yalim@asu.edu>

set -euo pipefail

readonly working_dir="/packages/public/sol-node-status"
cd "$working_dir"

readonly density_limit=10 # save one per ten minutes
readonly snapshot_dir="snapshot"
readonly snapshot_dat=$(date "+${snapshot_dir}/node-status-%FT%T.csv")
readonly snapshot_job_stats_dat=$(date "+${snapshot_dir}/job-stats-%FT%T.csv")
readonly snapshot_density_proc="${snapshot_dir}/.snapshot_modulo.do.not.delete"
# short format is necessary to be able to easily parse the Reason column later
# %N: NodeList, %C: Cores (A/I/O/T), %P: Partition, %T: State Extended
# %O: CPU Load, %c: Cores on Node, %f: features, %E: Reason
readonly sinfo_short_fmt="%N %C %P %T %O %c %f '%E'"
# long format necessary since some fields are not availabe in the short fmt.
#   N.B.: GresUsed req. fmt. :: undoc. limit of 21 char. 
readonly sinfo_long_fmt='FreeMem,AllocMem,Memory,GresUsed:300,Gres:300,Timestamp'

! [[ -d "$snapshot_dir" ]] && mkdir -p "$snapshot_dir" || :
! [[ -e "$snapshot_density_proc" ]] && echo 0 > "$snapshot_density_proc" || :

./bin/local-sq-stats > "$snapshot_job_stats_dat"

paste                                   \
  <(sinfo --Node -o "$sinfo_short_fmt" | sed -e s/\"/\\\\\"/g -e s/\'/\"/g ) \
  <(sinfo --Node -O "$sinfo_long_fmt" ) \
  > "$snapshot_dat"
./plot-sol-node-status.py "$snapshot_dat" "$snapshot_job_stats_dat"

# Inject refresh attribute into output plotly html
awk '
  { 
    if ( NR == 2 ) { 
      print "<head><meta http-equiv=\"refresh\" content=\"30\"/></head>" 
    } else {
      print
    }
  }
' sol2.html \
  | sed -e 's/<body>/<body style="background-color:#eee;">/' \
        -e 's/class="plotly-graph-div" style="/&margin:auto;/' \
  > sol.html
rm sol2.html

readonly count=$(awk 'NR==1 {print ++$1}' "$snapshot_density_proc")

# Save and compress every <density_limit> steps
if (( count == density_limit )); then
  echo 0 > "$snapshot_density_proc"
  zstd -19 --rm "$snapshot_dat"
  zstd -19 --rm "$snapshot_job_stats_dat"
else
  echo $count > "$snapshot_density_proc"
  rm "$snapshot_dat" "$snapshot_job_stats_dat"
fi
