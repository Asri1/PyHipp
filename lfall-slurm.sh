#!/bin/bash

# Submit this script with: sbatch <this-filename>

#SBATCH --time=24:00:00   # walltime
#SBATCH --ntasks=1   # number of processor cores (i.e. tasks)
#SBATCH --nodes=1   # number of nodes
#SBATCH --cpus-per-task=1   # number of CPUs for this task
#SBATCH -J "lfall"   # job name

## /SBATCH -p general # partition (queue)
#SBATCH -o lfall-slurm.%N.%j.out # STDOUT
#SBATCH -e lfall-slurm.%N.%j.err # STDERR

# LOAD MODULES, INSERT CODE, AND RUN YOUR PROGRAMS HERE
python -u -c "import PyHipp as pyh; \
import time; \
import DataProcessingTools as DPT; \
lfall = DPT.objects.processDirs(dirs=None, exclude=['*eye*', '*mountains*'], objtype=pyh.FreqSpectrum, saveLevel=1); \
lfall.save();
print(time.localtime());"

aws sns publish --topic-arn arn:aws:sns:ap-southeast-1:406682759819:awsnotify --message "LFJobDone"
