# BluePyOpt Test Repository

This repository provides a basic test to verify if [BluePyOpt](https://github.com/BlueBrain/BluePyOpt)
is installed correctly and functioning as expected. It's handy when verifying installations on clusters.

## Requirements

See BluePyOpt installation for more details. Main dependencies are:

- [NEURON](https://www.neuron.yale.edu/neuron/) simulator
- [BluePyOpt](https://github.com/BlueBrain/BluePyOpt)


## Usage

Execute the test script:

```bash
#!/bin/bash
#SBATCH --ntasks=6
#SBATCH --partition=prod
#SBATCH --job-name=bluepyopt_test
#SBATCH --time=00:10:00
#SBATCH --account=proj16

PWD=$(pwd)
LOGS=$PWD/logs/${SLURM_JOBID}
mkdir -p $LOGS

# just to use modules if you have
module purge
module load unstable python-dev py-bluepyopt neuron

# compile mod files
rm -rf x86_64
nrnivmodl mechanisms

#ipython settings
export IPYTHONDIR=${PWD}/.ipython
export IPYTHON_PROFILE=benchmark.${SLURM_JOBID}

# start controller and engines
ipcontroller --init --ip='*' --ping=30000 --profile=${IPYTHON_PROFILE} &
sleep 5
srun --output="${LOGS}/engine.out" ipengine --timeout=300 --profile=${IPYTHON_PROFILE} &
sleep 5

# launch small test
max_ngen=2
offspring_size=6
python opt.py --checkpoint="${LOGS}/run.pkl" --max_ngen=$max_ngen --offspring_size=$offspring_size
```

## License

See LICENSE file.

