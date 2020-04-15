#!/bin/bash
#SBATCH --constraint="cpu|nvme"
#SBATCH --ntasks=6
#SBATCH --partition=prod
#SBATCH --job-name=bluepyopt_test
#SBATCH --time=00:10:00
#SBATCH --account=proj16

set -e
set -x

PWD=$(pwd)
LOGS=$PWD/logs/${SLURM_JOBID}
mkdir -p $LOGS

module load unstable python-dev py-bluepyopt/1.9.27 neuron
module list

rm -rf x86_64
nrnivmodl mechanisms

export IPYTHONDIR=${PWD}/.ipython
export IPYTHON_PROFILE=benchmark.${SLURM_JOBID}

ipcontroller --init --ip='*' --ping=30000 --profile=${IPYTHON_PROFILE} &> job.log &
sleep 5
srun --output="${LOGS}/engine.out" ipengine --timeout=300 --profile=${IPYTHON_PROFILE} &
sleep 5

max_ngen=2
offspring_size=6

python opt.py --checkpoint="${LOGS}/run.pkl" --max_ngen=$max_ngen --offspring_size=$offspring_size

# show the log
cat job.log

# basic sanity check
expected_jobs=$((max_ngen*offspring_size))
finished_jobs=`grep "finished on" job.log | wc -l`


if [[ ${finished_jobs} -ne $expected_jobs ]]; then
    echo "ERRRO : Only ran ${finished_jobs} jobs instead of 12"
    exit 1
else
    echo "PASS : Ran expected ${finished_jobs} jobs!"
    exit 0
fi
