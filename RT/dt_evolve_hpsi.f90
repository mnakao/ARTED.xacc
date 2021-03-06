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
#ifdef ARTED_SC
# define TIMELOG_BEG(id) call timelog_thread_begin(id)
# define TIMELOG_END(id) call timelog_thread_end(id)
#else
# define TIMELOG_BEG(id)
# define TIMELOG_END(id)
#endif

subroutine dt_evolve_hpsi
  use Global_Variables
  use timelog
  use omp_lib
  use opt_variables
  implicit none
  integer    :: tid
  integer    :: ikb,ik,ib,i
  integer    :: iexp
  complex(8) :: zfac(4)
#ifdef ARTED_SC
  integer    :: loop_count
  loop_count = 0
#endif

  zfac(1)=(-zI*dt)
  do i=2,4
    zfac(i)=zfac(i-1)*(-zI*dt)/i
  end do

  call timelog_begin(LOG_HPSI)
#ifdef ARTED_SC
!$omp parallel private(tid) shared(zfac) firstprivate(loop_count)
#else
!$omp parallel private(tid) shared(zfac)
#endif
!$  tid=omp_get_thread_num()

!$omp do private(ik,ib,iexp)
  do ikb=1,NKB
    ik=ik_table(ikb)
    ib=ib_table(ikb)

    call init(ztpsi(:,4,tid),zu(:,ib,ik))
    call hpsi_omp_KB_RT(ik,ztpsi(:,4,tid),ztpsi(:,1,tid))
    call hpsi_omp_KB_RT(ik,ztpsi(:,1,tid),ztpsi(:,2,tid))
    call hpsi_omp_KB_RT(ik,ztpsi(:,2,tid),ztpsi(:,3,tid))
    call hpsi_omp_KB_RT(ik,ztpsi(:,3,tid),ztpsi(:,4,tid))
    call update(zfac,ztpsi(:,:,tid),zu(:,ib,ik))

#ifdef ARTED_CURRENT_OPTIMIZED
    call current_omp_KB_ST(ib,ik,zu(:,ib,ik))
#endif

#ifdef ARTED_SC
    loop_count = loop_count + 1
#endif
  end do
!$omp end do

#ifdef ARTED_SC
  hpsi_called(tid) = loop_count
#endif

!$omp end parallel
  call timelog_end(LOG_HPSI)

contains
  subroutine init(tpsi,zu)
    use Global_Variables, only: NLx,NLy,NLz
    use opt_variables, only: PNLx,PNLy,PNLz
    use timelog
    implicit none
    complex(8) :: tpsi(0:PNLz-1,0:PNLy-1,0:PNLx-1)
    complex(8) :: zu(0:NLz-1,0:NLy-1,0:NLx-1)
    integer :: ix,iy,iz

    TIMELOG_BEG(LOG_HPSI_INIT)
!dir$ vector aligned
    do ix=0,NLx-1
    do iy=0,NLy-1
    do iz=0,NLz-1
      tpsi(iz,iy,ix)=zu(iz,iy,ix)
    end do
    end do
    end do
    TIMELOG_END(LOG_HPSI_INIT)
  end subroutine

  subroutine update(zfac,tpsi,zu)
    use Global_Variables, only: NLx,NLy,NLz
    use opt_variables, only: PNLx,PNLy,PNLz
    use timelog
    implicit none
    complex(8) :: zfac(4)
    complex(8) :: tpsi(0:PNLz-1,0:PNLy-1,0:PNLx-1,4)
    complex(8) :: zu(0:NLz-1,0:NLy-1,0:NLx-1)
    integer :: ix,iy,iz

    TIMELOG_BEG(LOG_HPSI_UPDATE)
!dir$ vector aligned
    do ix=0,NLx-1
    do iy=0,NLy-1
    do iz=0,NLz-1
      zu(iz,iy,ix)=zu(iz,iy,ix)+zfac(1)*tpsi(iz,iy,ix,1) &
      &                        +zfac(2)*tpsi(iz,iy,ix,2) &
      &                        +zfac(3)*tpsi(iz,iy,ix,3) &
      &                        +zfac(4)*tpsi(iz,iy,ix,4)
    end do
    end do
    end do
    TIMELOG_END(LOG_HPSI_UPDATE)
  end subroutine
end subroutine

