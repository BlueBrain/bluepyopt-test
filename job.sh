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

# just to use modules from CI
module purge
unset MODULEPATH
module use /gpfs/bbp.cscs.ch/ssd/apps/hpc/jenkins/pulls/545/modules/all
module load unstable python-dev py-bluepyopt/1.9.27 neuron
module list

rm -rf x86_64
nrnivmodl mechanisms

export IPYTHONDIR=${PWD}/.ipython
export IPYTHON_PROFILE=benchmark.${SLURM_JOBID}

ipcontroller --init --ip='*' --ping=30000 --profile=${IPYTHON_PROFILE} &
sleep 5
srun --output="${LOGS}/engine.out" ipengine --timeout=300 --profile=${IPYTHON_PROFILE} &
sleep 5

python opt.py --checkpoint="${LOGS}/run.pkl"
