rm -f mpi.f90 xacc-noomp.f90 xacc.f90 a.out log
rm -f *.o *.mod *.xmod

# OK
for i in global_variables_sc.f90 env_variables.f90 opt_variables.f90 nvtx.f90 timelog.f90 performance_analyzer.f90 
do
    cat ./modules/$i >> xacc.f90
done

# OK
for i in Occupation_Redistribution.f90 write_GS_data.f90 Fermi_Dirac_distribution.f90 sp_energy.f90 Density_Update.f90 CG.f90 diag.f90 Gram_Schmidt.f90
do
    cat ./GS/$i >> xacc.f90
done

# OK
for i in init_Ac.f90 dt_evolve.f90 Fourier_tr.f90 k_shift_wf.f90 dt_evolve_hpsi.f90
do
    cat ./RT/$i >> xacc.f90
done
# ACC dake
cat ./RT/hpsi_RT.f90 >> xacc-noomp.f90

# OK
cat ./common/preprocessor.f90 >> xacc.f90

# OK
for i in hpsi_stencil.f90 hpsi.f90 psi_rho.f90 Ylm_dYlm.f90 Hartree.f90
do
    cat ./common/$i >> xacc.f90
done

# OK
for i in init_wf.f90 input_ps.f90 fd_coef.f90 prep_ps.f90 init.f90
do
    cat ./preparation/$i >> xacc.f90
done

# NG jikkou error -> OK
cat ./RT/current.f90 >> xacc.f90

# NG nan -> OK
cat ./common/ion_force.f90 >> xacc.f90

# OK daga ataiga sukosi zureru -> preprocessor in omni compiler ga genin. mondai nasi
cat ./common/Exc_Cor.f90 >> xacc.f90

# NG Nan -> OK
cat ./common/total_energy.f90 >> xacc.f90

# NG Nan -> OK? ... no omp ni sureba
cat ./stencil/F90/hpsi.f90 >> xacc-noomp.f90

# OK daga sokudo osokunaru hutatsu
cat ./stencil/F90/total_energy.f90 >> xacc.f90
cat ./stencil/F90/current.f90 >> xacc-noomp.f90

#------------------
xmpcc -DARTED_CURRENT_OPTIMIZED -DARTED_LBLK -DARTED_SC -DARTED_STENCIL_OPTIMIZED -DARTED_STENCIL_PADDING -omp -c modules/env_variables_internal.c
xmpcc -DARTED_CURRENT_OPTIMIZED -DARTED_LBLK -DARTED_SC -DARTED_STENCIL_OPTIMIZED -DARTED_STENCIL_PADDING -omp -c modules/papi_wrap.c

xmpf90  -DARTED_CURRENT_OPTIMIZED -DARTED_LBLK -DARTED_SC -DARTED_STENCIL_OPTIMIZED -DARTED_STENCIL_PADDING -omp -cpp -Minfo=acc -xacc --Wn-acc --Wl-acc -I/opt/pgi/linux86-64/2016/mpi/mpich/include -D_OPENMP -ta=tesla,cc35,ptxinfo,maxregcount:128 -Mpreprocess -Kieee -c xacc.f90
if [ $? -ne 0 ]; then
    exit 1
fi
xmpf90  -DARTED_CURRENT_OPTIMIZED -DARTED_LBLK -DARTED_SC -DARTED_STENCIL_OPTIMIZED -DARTED_STENCIL_PADDING -cpp -Minfo=acc -xacc --Wn-acc --Wl-acc -I/opt/pgi/linux86-64/2016/mpi/mpich/include -D_OPENMP -ta=tesla,cc35,ptxinfo,maxregcount:128 -Mpreprocess -Kieee -c xacc-noomp.f90
if [ $? -ne 0 ]; then
    exit 1
fi

#mpif90 -DARTED_CURRENT_OPTIMIZED -DARTED_LBLK -DARTED_SC -DARTED_STENCIL_OPTIMIZED -DARTED_STENCIL_PADDING -mp -acc -ta=tesla,cc35,ptxinfo,maxregcount:128 -Mpreprocess -Kieee -module /home/mnakao/work/xmp-trunk/include/ -c mpi.f90

xmpf90 -DARTED_CURRENT_OPTIMIZED -DARTED_LBLK -DARTED_SC -DARTED_STENCIL_OPTIMIZED -DARTED_STENCIL_PADDING -omp -cpp -Minfo=acc -xacc --Wn-acc --Wl-acc -I/opt/pgi/linux86-64/2016/mpi/mpich/include -D_OPENMP -ta=tesla,cc35,ptxinfo,maxregcount:128 -Mpreprocess -Kieee xacc.o xacc-noomp.o env_variables_internal.o papi_wrap.o -llapack -lblas ./main/sc.f90
if [ $? -ne 0 ]; then
    exit 1
fi

