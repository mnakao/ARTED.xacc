!
!  Copyright 2016 ARTED developers
!
!  Licensed under the Apache License, Version 2.0 (the "License");
!  you may not use this file except in compliance with the License.
!  You may obtain a copy of the License at
!
!      http://www.apache.org/licenses/LICENSE-2.0
!
!  Unless required by applicable law or agreed to in writing, software
!  distributed under the License is distributed on an "AS IS" BASIS,
!  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
!  See the License for the specific language governing permissions and
!  limitations under the License.
!
!This file is "k_shift_wf.f90"
!This file contain a subroutine.
!Subroutine k_shift_wf(iter,iter_GS_max)
!--------10--------20--------30--------40--------50--------60--------70--------80--------90--------100-------110-------120--------130
Subroutine k_shift_wf(atomic_position_update_switch,iter_GS_max)
  use Global_Variables
  implicit none
  integer :: iter_GS,iter_GS_max,ik,ib1,ib2
  character(3) :: atomic_position_update_switch

  if(AD_RHO == 'GS')then
    Vloc_t(:)=Vloc(:)
    Vloc(:)=Vloc_GS(:)
  end if
  zu_GS(:,:,:)=zu_GS0(:,:,:)
  call diag_omp
  do iter_GS=1,iter_GS_max
    call CG_omp(Ncg)
    call Gram_Schmidt
    call Total_Energy_omp(atomic_position_update_switch,'GS')
    call Ion_Force_omp(atomic_position_update_switch,'GS')
    if (Myrank == 0) then
      write(*,'(1x,a15,i3,f20.14,f15.8)')'iter_GS, Eall =',iter_GS,Eall-Eall0,force(3,1)
    end if
  end do

  ovlp_occ_l=0.d0
!$omp parallel do private(ik,ib1,ib2)
  do ik=Nk_s,NK_e
    do ib1=1,NB
      do ib2=1,NBoccmax
        ovlp_occ_l(ib1,ik)=ovlp_occ_l(ib1,ik)+occ(ib2,ik)*abs(sum(conjg(zu_GS(:,ib1,ik))*zu(:,ib2,ik))*Hxyz)**2
      enddo
    enddo
  enddo
  call MPI_ALLREDUCE(ovlp_occ_l,ovlp_occ,NK*NB,MPI_REAL8, MPI_SUM,NEW_COMM_WORLD,ierr)

  if(AD_RHO == 'GS')then
    Vloc(:)=Vloc_t(:)
  end if

  return
End Subroutine k_shift_wf
!--------10--------20--------30--------40--------50--------60--------70--------80--------90--------100-------110-------120--------130
Subroutine k_shift_wf_last(atomic_position_update_switch,iter_GS_max)
  use Global_Variables
  implicit none
  integer :: iter_GS,iter_GS_max,ik,ib1,ib2,ib,ia
  character(3) :: atomic_position_update_switch
  real(8) :: esp_all(NB,NK)

  if(AD_RHO == 'GS')then
    Vloc_t(:)=Vloc(:)
    Vloc(:)=Vloc_GS(:)
  end if
  zu_GS(:,:,:)=zu_GS0(:,:,:)
  call diag_omp
  do iter_GS=1,iter_GS_max
    call CG_omp(Ncg)
    call Gram_Schmidt
    call Total_Energy_omp(atomic_position_update_switch,'GS')
    call Ion_Force_omp(atomic_position_update_switch,'GS')
    if (Myrank == 0) then
      write(*,'(1x,a15,i3,f20.14,f15.8)')'iter_GS, Eall =',iter_GS,Eall-Eall0,force(3,1)
    end if
  end do

  esp=0d0
  call diag_omp
  call MPI_ALLREDUCE(esp,esp_all,NK*NB,MPI_REAL8, MPI_SUM,NEW_COMM_WORLD,ierr)

  ovlp_occ_l=0.d0
!$omp parallel do private(ik,ib1,ib2)
  do ik=Nk_s,NK_e
    do ib1=1,NB
      do ib2=1,NBoccmax
        ovlp_occ_l(ib1,ik)=ovlp_occ_l(ib1,ik)+occ(ib2,ik)*abs(sum(conjg(zu_GS(:,ib1,ik))*zu(:,ib2,ik))*Hxyz)**2
      enddo
    enddo
  enddo
  call MPI_ALLREDUCE(ovlp_occ_l,ovlp_occ,NK*NB,MPI_REAL8, MPI_SUM,NEW_COMM_WORLD,ierr)

  
  file_nex=trim(directory)//trim(SYSname)//'_last_band_map.out'
  if (Myrank == 0)then
    open(409,file=file_nex,position = position_option) 
    do ik=1,NK
      write(409,'(1x,i5,1000e26.16E3)')ik,(esp_all(ib,ik),ovlp_occ(ib,ik)*NKxyz,ib=1,NB)
    end do
    close(409)

    do ia=1,NI
      write(*,'(1x,i7,3f15.6)') ia,force(1,ia),force(2,ia),force(3,ia)
    end do

    write(*,*) 'number of excited electron',sum(ovlp_occ(NBoccmax+1:NB,:)),sum(occ)-sum(ovlp_occ(1:NBoccmax,:))
    write(*,*) 'var_tot,var_max=',sum(esp_var(:,:))/(NK*Nelec/2),maxval(esp_var(:,:)) 

  end if

  if(AD_RHO == 'GS')then
    Vloc(:)=Vloc_t(:)
  end if

  return
End Subroutine k_shift_wf_last
