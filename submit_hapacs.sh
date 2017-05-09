#! /bin/bash
#PBS -S /bin/bash
#PBS -N ARTED.log.16-9
#PBS -A XMPTCA
#PBS -q tcaq
#PBS -l select=4:ncpus=20:mpiprocs=4:ompthreads=1
#PBS -l place=scatter
#PBS -l walltime=00:20:00
#PBS -j oe

cd ${PBS_O_WORKDIR}
module purge
module load pgi/16.10 cuda/8.0.44 mvapich2/2.2_pgi_medium_cuda-8.0.44

mpirun_rsh -np 16 -hostfile ${PBS_NODEFILE} MV2_ENABLE_AFFINITY=0 ./select_GPU ./a.out < ./data/input_sc.dat

#mpirun_rsh -np 2 -hostfile ${PBS_NODEFILE} MV2_NUM_PORTS=2 MV2_ENABLE_AFFINITY=0 MV2_USE_CUDA=1 OMP_NUM_THREADS=5 MV2_SHOW_CPU_BINDING=1 MV2_CPU_MAPPING=0-4:5-9:10-14:15-19 numactl --localalloc ./select_GPU ./a.out < ./data/input_sc.dat
