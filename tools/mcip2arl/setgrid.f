
!***********************************************************************
!   Portions of Models-3/CMAQ software were developed or based on      *
!   information from various groups: Federal Government employees,     *
!   contractors working on a United States Government contract, and    *
!   non-Federal sources (including research institutions).  These      *
!   research institutions have given the Government permission to      *
!   use, prepare derivative works, and distribute copies of their      *
!   work in Models-3/CMAQ to the public and to permit others to do     *
!   so.  EPA therefore grants similar permissions for use of the       *
!   Models-3/CMAQ software, but users are requested to provide copies  *
!   of derivative works to the Government without restrictions as to   *
!   use by others.  Users are responsible for acquiring their own      *
!   copies of commercial software associated with Models-3/CMAQ and    *
!   for complying with vendor requirements.  Software copyrights by    *
!   the MCNC Environmental Modeling Center are used with their         *
!   permissions subject to the above restrictions.                     *
!***********************************************************************

! RCS file, release, date & time of last delta, author, state, [and locker]
! $Header: /nas01/depts/ie/cempd/apps/CMAQ/v5.0.1/CMAQv5.0.1/models/TOOLS/src/mcip2arl/setgrid.f,v 1.1.1.1 2012/04/19 19:48:37 sjr Exp $

SUBROUTINE setgrid (nsfc,nvar,vchar,sig,clat1,clon1,clat2,clon2)

!-------------------------------------------------------------------------------
! Name:     Setgrid      
! Purpose:  Defines mapping of latitude-longitude to grid units and initializes
!           ARL packing subroutines 
! Revised:  22 Nov 2005 
!-------------------------------------------------------------------------------

  IMPLICIT NONE

  INCLUDE 'PARMS3.EXT'      
  INCLUDE 'FDESC3.EXT'      
  INCLUDE 'IODECL3.EXT'
  
  INTEGER,       INTENT(IN)    :: nsfc, nvar 
  CHARACTER(4),  INTENT(IN)    :: vchar ( : )
  REAL,          INTENT(IN)    :: sig   ( : )
  REAL,          INTENT(IN)    :: clat1,clon1,clat2,clon2

  INTEGER                      :: k,n
  REAL                         :: parmap(9)
  REAL                         :: grids (12)
  REAL                         :: tru1, tru2   

  REAL,          EXTERNAL      :: eqvlat
  
!-------------------------------------------------------------------------------
! Create array that will be written to initialize ARL data packing
!-------------------------------------------------------------------------------

  IF( GDTYP3D == LAMGRD3 )THEN      ! lambert conformal

     tru1      = P_ALP3D            ! convert to real(8) 
     tru2      = P_BET3D  
     grids(3)  = eqvlat(tru1,tru2)  ! lat of grid spacing 

     grids(1)  = grids(3)           ! pole position
     grids(2)  = P_GAM3D            ! 180 from cut longitude

     CALL stlmbr(parmap,eqvlat(tru1,tru2),grids(2))
     CALL stcm2p(parmap,1.,1.,clat1,clon1,FLOAT(NCOLS3D),FLOAT(NROWS3D),clat2,clon2)

     grids(4)  = P_GAM3D            ! lon of grid spacing
     grids(5)  = YCELL3D/1000.0     ! grid size
     grids(6)  = 0.0                ! orientation
     grids(7)  = grids(3)           ! cone angle                         
     grids(8)  = (NCOLS3D+1)/2.0 
     grids(9)  = (NROWS3D+1)/2.0

!    grids(10) = YCENT3D
!    grids(11) = XCENT3D
!    use cmapf routines to determine grid center (mcip seems to be wrong)
     CALL cxy2ll(parmap,grids(8),grids(9),grids(10),grids(11))

  ELSEIF( GDTYP3D == POLGRD3 )THEN  ! polar sterographic

     grids(1)  = 90.0*P_ALP3D       ! pole position
     grids(2)  = 0.0                ! 180 from cut longitude
     grids(3)  = P_BET3D            ! lat of grid spacing 
     grids(4)  = P_GAM3D            ! lon of grid spacing
     grids(5)  =  YCELL3D/1000.0    ! grid size
     grids(6)  = 0.0                ! orientation
     grids(7)  = 90.0               ! cone angle
     grids(8)  = (NCOLS3D+1)/2.0 
     grids(9)  = (NROWS3D+1)/2.0
     grids(10) = YCENT3D
     grids(11) = XCENT3D

  ELSEIF( GDTYP3D == MERGRD3 )THEN  ! mercator projection 

     grids(1)  = 90.0               ! pole position
     grids(2)  =P_BET3D             ! 180 from cut longitude
     grids(3)  = P_ALP3D            ! lat of grid spacing 
     grids(4)  =P_BET3D             ! lon of grid spacing
     grids(5)  = YCELL3D/1000.0     ! grid size
     grids(6)  = 0.0                ! orientation
     grids(7)  = 90.0-P_GAM3D       ! cone angle
     grids(8)  = (NCOLS3D+1)/2.0 
     grids(9)  = (NROWS3D+1)/2.0
     grids(10) = YCENT3D
     grids(11) = XCENT3D

  ELSE
     WRITE(*,*)'MCIP grid not defined in program: ',GDTYP3D
     STOP

  END IF 
  grids(12) = 0.0                  ! unused

!-------------------------------------------------------------------------------
! Write ARL data packing configuration file                      
!-------------------------------------------------------------------------------

  OPEN(10,FILE='MCIP.CFG')      
  WRITE(10,'(20X,a4)') 'MCIP'                       ! abbreviated data set name
  WRITE(10,'(20X,i4)') 99,1                         ! grid & coordinate system
  WRITE(10,'(20X,f10.2)') grids                     ! grid orientation array
  WRITE(10,'(20X,i4)') ncols3d, nrows3d, (nlays3d+1)                       
 
! surface level information
  WRITE(10,'(20x,f6.0,i3,20(1x,a4))') 1.0, nsfc, (vchar(n),n=1,nsfc)

! upper level information
  DO k = 1, nlays3d
     WRITE(10,'(20x,f6.4,i3,20(1x,a4))') sig(k), (nvar-nsfc), (vchar(n),n=nsfc+1,nvar)
  END DO

  CLOSE (10)
  RETURN

END SUBROUTINE setgrid  
