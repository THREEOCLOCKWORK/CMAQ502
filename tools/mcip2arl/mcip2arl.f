
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
! $Header: /nas01/depts/ie/cempd/apps/CMAQ/v5.0.1/CMAQv5.0.1/models/TOOLS/src/mcip2arl/mcip2arl.f,v 1.1.1.1 2012/04/19 19:48:37 sjr Exp $

PROGRAM mcip2arl

!-------------------------------------------------------------------------------
! Name:     MCIP2ARL
! Purpose:  Get MCIP output and convert to ARL one-byte packed format.  
! Revised:  21 Nov 2005  Converted from mm5toarl (RRD) 
!-------------------------------------------------------------------------------

  IMPLICIT NONE

  INCLUDE 'PARMS3.EXT'     
  INCLUDE 'FDESC3.EXT'      
  INCLUDE 'IODECL3.EXT'    

  CHARACTER(16)             :: INPFILE
  CHARACTER(80)             :: LABEL, OUTFILE
  CHARACTER(5)              :: BASE(3) = (/'DOT3D','CRO3D','CRO2D'/)
  CHARACTER(6)              :: SUFFIX
  INTEGER                   :: LOGDEV
  LOGICAL                   :: FTEST

  REAL,         ALLOCATABLE :: dat_dot (:,:)
  REAL,         ALLOCATABLE :: tmp_dot (:,:)
  REAL,         ALLOCATABLE :: dat_crs (:,:)
  REAL,         ALLOCATABLE :: tmp_crs (:,:)
  REAL,         ALLOCATABLE :: sig  (:)       
  CHARACTER(1), ALLOCATABLE :: cvar (:)

! hysplit packed data configuration
  INTEGER, PARAMETER        :: nsfc =  4     ! number of surface variables
  INTEGER, PARAMETER        :: nvar = 10     ! total number of variables

  REAL,    PARAMETER        :: g    = 9.81   ! m/s**2; gravity

! arl packed variables names
  CHARACTER(4)  :: vchar(nvar) = (/ 'PRSS',            'SHTF',              &
                                    'USTR',            'MXHT',              &
                                    'PRES',            'UWND',              &
                                    'VWND',            'WWND',              &
                                    'TEMP',            'SPHU'              /)

! equivalent  mcip variable names
  CHARACTER(16) :: mchar(nvar) = (/ 'PRSFC           ','HFX             ',  &
                                    'USTAR           ','PBL             ',  &
                                    'PRES            ','UWIND           ',  &
                                    'VWIND           ','WWIND           ',  &
                                    'TA              ','QV              '  /)

! base file name index where each variable can be found 
  INTEGER       :: nbase(nvar) = (/  3,                 3,                  &
                                     3,                 3,                  &
                                     2,                 1,                  &
                                     1,                 2,                  &
                                     2,                 2                  /) 

  INTEGER       :: narg,iargc
  INTEGER       :: j,k,n,nx,ny,nz,ntime
  INTEGER       :: iyr,imo,ida,ihr,ifh,imn
  INTEGER       :: jdate,jtime,jstep       
  REAL          :: clat1,clon1,clat2,clon2

!-------------------------------------------------------------------------------
! Configure subroutine interface argumment lists
!-------------------------------------------------------------------------------

  INTERFACE
     SUBROUTINE setgrid (nsfc,nvar,vchar,sig,clat1,clon1,clat2,clon2)
     INTEGER,       INTENT(IN)    :: nsfc, nvar
     CHARACTER(4),  INTENT(IN)    :: vchar ( : )
     REAL,          INTENT(IN)    :: sig   ( : )
     REAL,          INTENT(IN)    :: clat1,clon1,clat2,clon2
     END SUBROUTINE setgrid

    SUBROUTINE crs2dot (varcrs, vardot)
    REAL,           INTENT(IN)    :: varcrs ( : , : )
    REAL,           INTENT(OUT)   :: vardot ( : , : )
    END SUBROUTINE crs2dot
  END INTERFACE

!-------------------------------------------------------------------------------
! Check command line for file name suffix
!-------------------------------------------------------------------------------

! check for command line input/output file names
  NARG=IARGC()
  IF(NARG.LT.2)THEN
     WRITE(*,*)'Usage: mcip2arl [suffix] [outfile]'
     WRITE(*,*)'where {suffix} = input file METxxxxD_{suffix}'
     STOP
  END IF

  DO WHILE(NARG.GT.0)
     CALL GETARG(NARG,LABEL)
     IF(narg.EQ.1) SUFFIX =LABEL
     IF(narg.EQ.2) OUTFILE=LABEL
     NARG=NARG-1
  END DO

! MCIP input files
  DO N=1,3
     INPFILE='MET'//BASE(N)//'_'//SUFFIX
     INQUIRE (FILE=INPFILE, EXIST=FTEST)
     IF(.NOT.FTEST) THEN
        WRITE(*,*) 'File not found:',N,' - ',INPFILE
     END IF
  END DO
  IF(.NOT.FTEST) STOP

!-------------------------------------------------------------------------------
! Loop through each MCIP file 
!-------------------------------------------------------------------------------

  LOGDEV  = INIT3()     !  initialization returns unit # for log
  IF(logdev.LT.0) STOP 'ERROR: Cannot open the IOAPI log file'

! allocate output file to reserve unit
  OPEN(10,FILE='MCIP.CFG')

! open and check all input files
  DO N=1,3
     INPFILE='MET'//BASE(N)//'_'//SUFFIX

     IF(.NOT.OPEN3(INPFILE,FSREAD3,'mcip2arl'))THEN
        FTEST = SHUT3()
        WRITE(*,*) 'ERROR: cannot open the input file - ',INPFILE
        STOP
     END IF

!    load the descriptors 
     IF(.NOT.DESC3(INPFILE))THEN
        FTEST = SHUT3()
        WRITE(*,*) 'ERROR: cannot load descriptors - ',INPFILE
        STOP
     END IF

!    insure we have the right type of data file
     IF(FTYPE3D.NE.GRDDED3)THEN
        FTEST = SHUT3()
        WRITE(*,*) 'ERROR: file type not gridded data - ',FTYPE3D
        STOP
     END IF
  END DO

  CLOSE(10)

! First file (3D dot) allocate variables and configure HYSPLIT meteo file
  INPFILE='MET'//BASE(1)//'_'//SUFFIX
  IF(.NOT.DESC3(INPFILE))THEN
     STOP 'Unable to get descriptor'

  ELSE
     ntime = MXREC3D
     nx    = NCOLS3D
     ny    = NROWS3D
     nz    = NLAYS3D 

     ALLOCATE (dat_dot (nx,   ny  ))
     ALLOCATE (tmp_dot (nx,   ny  ))
     ALLOCATE (dat_crs (nx-1, ny-1))
     ALLOCATE (tmp_crs (nx-1, ny-1))
     ALLOCATE (sig (nz))       
     ALLOCATE (cvar (nx*ny))

!    grid system corners for geo-reference
     INPFILE='GRIDDOT2D_'//SUFFIX
     FTEST=OPEN3(INPFILE,FSREAD3,'mcip2arl')
     IF(.NOT.FTEST)THEN
        WRITE(*,*)'Error opening dot grid file: ',INPFILE
        STOP
     END IF
     FTEST=READ3(INPFILE,'LAT             ',1,JDATE,JTIME, dat_dot)
     CLAT1=dat_dot(1,1)
     CLAT2=dat_dot(nx,ny)
     FTEST=READ3(INPFILE,'LON             ',1,JDATE,JTIME, dat_dot)
     CLON1=dat_dot(1,1)
     CLON2=dat_dot(nx,ny)

!    vertical structure defined at half levels
     DO k = 1, nz
        sig(k) = 0.5*(vglvs3d(k+1)+vglvs3d(k))
     END DO

!    Set up ARL format variables and grid definitions
     CALL setgrid (nsfc,nvar,vchar,sig,clat1,clon1,clat2,clon2)
     CALL PAKSET(10,'MCIP.CFG',1,nx,ny,(nz+1))
     OPEN(10,FILE=OUTFILE,RECL=(50+nx*ny),ACCESS='DIRECT',FORM='UNFORMATTED')

!    Get the file starting date/time
     JDATE = SDATE3D       
     JTIME = STIME3D
     JSTEP = TSTEP3D 

!    Convert times to integer from character string
     ihr=JTIME/10000
     imn=JTIME-ihr*10000 
     iyr=MOD(JDATE/1000,100)
     CALL DAYMON(JDATE,imo,ida)
     ifh=0                        ! forecast hour always zero
  END IF 

!-------------------------------------------------------------------------------
! Loop over times 
!-------------------------------------------------------------------------------

  DO j = 1, ntime

!    process surface fields
     INPFILE='MET'//BASE(3)//'_'//SUFFIX
     DO n = 1, nsfc
        FTEST=READ3(INPFILE,MCHAR(n),1,JDATE,JTIME, dat_crs)
        IF(.NOT.FTEST) STOP 'Unable to read surface file'

!       convert pressure from Pa to hPa
        IF(MCHAR(n)(1:5).EQ.'PRSFC') dat_crs = dat_crs /100.0

        CALL CRS2DOT(dat_crs, dat_dot)
!       dat_dot = TRANSPOSE (tmp_dot) 
        CALL PAKREC(10,dat_dot,cvar,nx,ny,(nx*ny),vchar(n),iyr,imo,ida,ihr,imn,ifh,1,0)  
     END DO

!    process all the cross point upper air fields                                 
     INPFILE='MET'//BASE(2)//'_'//SUFFIX
     cloop : DO n = nsfc+1, nvar 
        IF(nbase(n).NE.2) CYCLE cloop
        DO k = 1, nz 
           FTEST=READ3(INPFILE,MCHAR(n),K,JDATE,JTIME, dat_crs)
           IF(.NOT.FTEST) STOP 'Unable to read cross file'

!          convert vertical velocity from m/s to hPa/s using omega = -W g rho
           IF(MCHAR(n)(1:5).EQ.'WWIND')THEN
              FTEST=READ3(INPFILE,'DENS            ',K,JDATE,JTIME, tmp_crs)
              IF(.NOT.FTEST) STOP 'Unable to read cross file'
              dat_crs = -dat_crs * g * tmp_crs /100.0 
           END IF

!          convert pressure from Pa to hPa
           IF(MCHAR(n)(1:4).EQ.'PRES') dat_crs = dat_crs /100.0

           CALL CRS2DOT(dat_crs, dat_dot)
!          dat_dot = TRANSPOSE (tmp_dot) 
           CALL PAKREC(10,dat_dot,cvar,nx,ny,(nx*ny),vchar(n),iyr,imo,ida,ihr,imn,ifh,k+1,0)  
        END DO
     END DO cloop

!    process all the dot point upper air fields                                 
     INPFILE='MET'//BASE(1)//'_'//SUFFIX
     dloop : DO n = nsfc+1, nvar 
        IF(nbase(n).NE.1) CYCLE dloop
        DO k = 1, nz 
           FTEST=READ3(INPFILE,MCHAR(n),K,JDATE,JTIME, dat_dot)
           IF(.NOT.FTEST) STOP 'Unable to read dot file'
!          dat_dot = TRANSPOSE (tmp_dot) 
           CALL PAKREC(10,dat_dot,cvar,nx,ny,(nx*ny),vchar(n),iyr,imo,ida,ihr,imn,ifh,k+1,0)  
        END DO
     END DO dloop
     WRITE(*,*)'Finished: ',iyr,imo,ida,ihr

!    Close out time period by writing index record                      
     CALL PAKNDX(10)     
     CALL NEXTIME(JDATE,JTIME,JSTEP)

!    Convert times to integer from character string
     ihr=JTIME/10000
     imn=JTIME-ihr*10000 
     iyr=MOD(JDATE/1000,100)
     CALL DAYMON(JDATE,imo,ida)
  END DO 

!-------------------------------------------------------------------------------
! Deallocate variables.
!-------------------------------------------------------------------------------

  FTEST = SHUT3()
  IF(.NOT.FTEST) WRITE(*,*)'ERROR: shutdown of IOAPI'


END PROGRAM mcip2arl
