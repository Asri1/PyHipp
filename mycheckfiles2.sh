#!/bin/bash  

echo "Number of hkl files"
hkl_count=$(find . -name "*.hkl" | grep -v -e spiketrain -e mountains | wc -l)
echo $hkl_count

echo "Number of mda files"
mda_count=$(find mountains -name "firings.mda" | wc -l)
echo $mda_count

echo ""
echo "#==========================================================="
echo "Start Times"
for f in *-slurm*.out; do
    echo "==> $f <=="
    grep "time.struct_time" "$f" | head -n 1
done

echo "End Times"
for f in *-slurm*.out; do
    echo "==> $f <=="
    grep "time.struct_time" "$f" | tail -n 1
    awk '/^[0-9]+\.[0-9]+$/ {val=$1} END {if (val!="") print val}' "$f"
    grep '"MessageId"' "$f"
done
echo "#==========================================================="

durations=()
for f in *-slurm*.out; do
    d=$(awk '/^[0-9]+\.[0-9]+$/ {val=$1} END {if (val!="") print val}' "$f")
    durations+=("$d")
done

job1=${durations[0]}   # RPLParallel
job2=${durations[1]}   # RPLSplit

serial_total=$(echo "$job1 + $job2" | bc -l)
parallel_total=$(python3 <<'EOF'
import re, time, glob

def parse_struct(line):
    fields = dict((m.group(1), int(m.group(2)))
                  for m in re.finditer(r'tm_(\w+)=([0-9]+)', line))
    return time.struct_time((
        fields['year'], fields['mon'], fields['mday'],
        fields['hour'], fields['min'], fields['sec'],
        fields['wday'], fields['yday'], fields['isdst']
    ))

starts, ends = [], []
for f in glob.glob("*-slurm*.out"):
    lines = [l.strip() for l in open(f) if "time.struct_time" in l]
    if lines:
        starts.append(parse_struct(lines[0]))
        ends.append(parse_struct(lines[-1]))

if starts and ends:
    print(time.mktime(max(ends)) - time.mktime(min(starts)))
EOF
)

time_saved=$(echo "$serial_total - $parallel_total" | bc -l)

channels_done=8
channels_target=110
extrapolated=$(echo "$job1 + $job2 * $channels_target / $channels_done" | bc -l)

echo ""
echo "Total serial time (s): $serial_total"
echo "Actual wall time (s): $parallel_total"
echo "Time saved (s): $time_saved"
echo "Extrapolated time for 110 channels (s): $extrapolated"

