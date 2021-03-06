
!------------------------------------------------------------------------!
!  The Community Multiscale Air Quality (CMAQ) system software is in     !
!  continuous development by various groups and is based on information  !
!  from these groups: Federal Government employees, contractors working  !
!  within a United States Government contract, and non-Federal sources   !
!  including research institutions.  These groups give the Government    !
!  permission to use, prepare derivative works of, and distribute copies !
!  of their work in the CMAQ system to the public and to permit others   !
!  to do so.  The United States Environmental Protection Agency          !
!  therefore grants similar permission to use the CMAQ system software,  !
!  but users are requested to provide copies of derivative works or      !
!  products designed to operate in the CMAQ system to the United States  !
!  Government without restrictions as to use by others.  Software        !
!  that is used with the CMAQ system but distributed under the GNU       !
!  General Public License or the GNU Lesser General Public License is    !
!  subject to their copyright restrictions.                              !
!------------------------------------------------------------------------!


C RCS file, release, date & time of last delta, author, state, [and locker]
C $Header: /project/yoj/arc/CCTM/src/hadv/yamo/hadvyppm.F,v 1.5 2011/10/21 16:11:19 yoj Exp $

C what(1) key, module and SID; SCCS file; date and time of last delta:
C %W% %P% %G% %U%

C:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#ifdef isam
      SUBROUTINE HADV ( CGRID, JDATE, JTIME, TSTEP, ASTEP, ISAM )
#else
      SUBROUTINE HADV ( CGRID, JDATE, JTIME, TSTEP, ASTEP )
#endif

C-----------------------------------------------------------------------
C Function:
C   Advection in the horizontal plane
C   The process time step is set equal to TSTEP(2). Boundary concentrations
C   are coupled in RDBCON with SqRDMT = Sq. Root [det ( metric tensor )]
C   = Jacobian / (map scale factor)**2
C   where Air Density X SqRDMT is loaded into last BCON slot for advection.
      
C Preconditions:
C   Dates and times represented YYYYDDD:HHMMSS.
C   No "skipped" dates and times.  All boundary input variables have the
C   same boundary perimeter structure with a thickness of 1
C   CGRID in transport units: SQRT{DET[metric tensor]}*concentration (Mass/Vol)
      
C Subroutines and functions called:
 
C Revision history:
C  19 Jan 2004: Jeff Young
C   7 Jul 2007: Jeff Young - declare MTRHOJ dimensions properly in order to retain
C                            them as declared in X_YAMO and Y_YAMO
C   21 Jun 10 J.Young: convert for Namelist redesign
C   16 Feb 11 S.Roselle: replaced I/O API include files with UTILIO_DEFN
C   11 May 11 D.Wong: incorporated twoway model implementation
C   19 Jul 13 R.Kwok: isam
C-----------------------------------------------------------------------

      USE GRID_CONF             ! horizontal & vertical domain specifications
      USE CGRID_SPCS            ! CGRID mechanism species
      USE UTILIO_DEFN

      USE SUBST_MODULES         ! stenex
!     USE SUBST_COMM_MODULE     ! stenex
!     USE SUBST_UTIL_MODULE     ! stenex

#ifdef isam
      USE SA_DEFN               ! 20120816
#endif

      IMPLICIT NONE
      
C Includes:

      INCLUDE SUBST_FILES_ID    ! file name parameters
      INCLUDE SUBST_PE_COMM     ! PE communication displacement and direction

C Arguments:
      
      REAL, POINTER :: CGRID( :,:,:,: )
      INTEGER     JDATE         ! current model date, coded YYYYDDD
      INTEGER     JTIME         ! current model time, coded HHMMSS
      INTEGER     TSTEP( 3 )    ! time step vector (HHMMSS)
                                ! TSTEP(1) = local output step
                                ! TSTEP(2) = sciproc sync. step (chem)
                                ! TSTEP(3) = twoway model time step w.r.t. wrf time
                                !            step and wrf/cmaq call frequency

      INTEGER     ASTEP( : )    ! layer advection time step
#ifdef isam
      REAL, POINTER :: ISAM( :,:,:,:,: )
#endif

C External Functions: None
      
C Parameters:

C Advected species dimension

      INTEGER, SAVE :: N_SPC_ADV

C File Variables:

      REAL, ALLOCATABLE, SAVE :: BCON( :,: )    ! boundary concentrations
      REAL         RHOJ( NCOLS,NROWS )          ! RhoJ

C Local Variables:

!     REAL         XTRHOJ( 0:NCOLS,NROWS )
!     REAL         YTRHOJ( 0:NROWS,NCOLS ) <- violates stenex setup
      REAL, ALLOCATABLE, SAVE :: XTRHOJ( :,: )
      REAL, ALLOCATABLE, SAVE :: YTRHOJ( :,: )
      INTEGER       ALLOCSTAT

      INTEGER, SAVE :: ASPC                     ! RHOJ index in CGRID

      CHARACTER( 16 ) :: PNAME = 'HADVYPPM'
      LOGICAL, SAVE :: FIRSTIME = .TRUE.
      LOGICAL XYFIRST

      integer, save :: logdev

      CHARACTER( 96 ) :: XMSG = ' '

      INTEGER      STEP                         ! ASTEP( L ), (dt) in sec
      INTEGER      DSTEP                        ! dt accumulator
      INTEGER      FDATE                        ! interpolation date
      INTEGER      FTIME                        ! interpolation time
      INTEGER      SYNCSTEP

      INTEGER      COL, ROW, LVL                ! loop counters

C Required interface for allocatable array dummy arguments

      INTERFACE
         SUBROUTINE RDBCON ( FDATE, FTIME, TSTEP, LVL, BCON )
            IMPLICIT NONE
            INTEGER, INTENT( IN )  :: FDATE, FTIME, TSTEP, LVL
            REAL,    INTENT( OUT ) :: BCON( :,: )
         END SUBROUTINE RDBCON
#ifdef isam
         SUBROUTINE X_PPM ( CGRID, FDATE, FTIME, TSTEP, LVL, BCON, ISAM )
#else
         SUBROUTINE X_PPM ( CGRID, FDATE, FTIME, TSTEP, LVL, BCON )
#endif
            USE HGRD_DEFN
            IMPLICIT NONE
            REAL, POINTER          :: CGRID( :,:,:,: )
            INTEGER, INTENT( IN )  :: FDATE, FTIME, TSTEP, LVL
!           REAL,    INTENT( IN )  :: BCON( NBNDY,* )
            REAL,    INTENT( IN )  :: BCON( :,: )
#ifdef isam
            REAL, POINTER          :: ISAM( :,:,:,:,: )
#endif
         END SUBROUTINE X_PPM
#ifdef isam
         SUBROUTINE X_YAMO ( CGRID, FDATE, FTIME, TSTEP, LVL, BCON, MTRHOJ, ISAM )
#else
         SUBROUTINE X_YAMO ( CGRID, FDATE, FTIME, TSTEP, LVL, BCON, MTRHOJ )
#endif
            USE HGRD_DEFN
            IMPLICIT NONE
            REAL, POINTER          :: CGRID( :,:,:,: )
            INTEGER, INTENT( IN )  :: FDATE, FTIME, TSTEP, LVL
!           REAL,    INTENT( IN )  :: BCON( NBNDY,* )
            REAL,    INTENT( IN )  :: BCON( :,: )
            REAL,    INTENT( IN )  :: MTRHOJ( 0:,1: )
!           REAL,    INTENT( IN )  :: MTRHOJ( :,: )
#ifdef isam
            REAL, POINTER          :: ISAM( :,:,:,:,: )
#endif
         END SUBROUTINE X_YAMO
#ifdef isam
         SUBROUTINE Y_PPM ( CGRID, FDATE, FTIME, TSTEP, LVL, BCON, ISAM )
#else
         SUBROUTINE Y_PPM ( CGRID, FDATE, FTIME, TSTEP, LVL, BCON )
#endif
            USE HGRD_DEFN
            IMPLICIT NONE
            REAL, POINTER          :: CGRID( :,:,:,: )
            INTEGER, INTENT( IN )  :: FDATE, FTIME, TSTEP, LVL
!           REAL,    INTENT( IN )  :: BCON( NBNDY,: )
            REAL,    INTENT( IN )  :: BCON( :,: )
#ifdef isam
            REAL, POINTER          :: ISAM( :,:,:,:,: )
#endif
         END SUBROUTINE Y_PPM
#ifdef isam
         SUBROUTINE Y_YAMO ( CGRID, FDATE, FTIME, TSTEP, LVL, BCON, MTRHOJ, ISAM )
#else
         SUBROUTINE Y_YAMO ( CGRID, FDATE, FTIME, TSTEP, LVL, BCON, MTRHOJ )
#endif
            USE HGRD_DEFN
            IMPLICIT NONE
            REAL, POINTER          :: CGRID( :,:,:,: )
            INTEGER, INTENT( IN )  :: FDATE, FTIME, TSTEP, LVL
!           REAL,    INTENT( IN )  :: BCON( NBNDY,1: )
            REAL,    INTENT( IN )  :: BCON( :,: )
            REAL,    INTENT( IN )  :: MTRHOJ( 1:,0: )
!           REAL,    INTENT( IN )  :: MTRHOJ( :,: )
#ifdef isam
            REAL, POINTER          :: ISAM( :,:,:,:,: )
#endif
         END SUBROUTINE Y_YAMO
!        SUBROUTINE LCKSUMMER ( PNAME, CGRID, JDATE, JTIME, LVL )
!           IMPLICIT NONE
!           CHARACTER( * ), INTENT( IN ) :: PNAME
!           REAL, POINTER                :: CGRID( :,:,:,: )
!           INTEGER, INTENT( IN )        :: JDATE, JTIME, LVL
!        END SUBROUTINE LCKSUMMER
      END INTERFACE
C-----------------------------------------------------------------------

      IF ( FIRSTIME ) THEN
         FIRSTIME = .FALSE.
         logdev = init3 ()

C Get CGRID offsets

         N_SPC_ADV = N_GC_TRNS + N_AE_TRNS + N_NR_TRNS + N_TR_ADV + 1
                                                  ! add 1 for advecting RHOJ
         ALLOCATE ( BCON( NBNDY,N_SPC_ADV ), STAT = ALLOCSTAT )
         IF ( ALLOCSTAT .NE. 0 ) THEN
            XMSG = 'Failure allocating BCON'
            CALL M3EXIT ( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
         END IF

         ASPC = GC_STRT - 1 + N_GC_SPCD

         ALLOCATE ( XTRHOJ( 0:NCOLS,  NROWS ), STAT = ALLOCSTAT )
         ALLOCATE ( YTRHOJ(   NCOLS,0:NROWS ), STAT = ALLOCSTAT )
         IF ( ALLOCSTAT .NE. 0 ) THEN
            XMSG = 'Failure allocating XTRHOJ or YTRHOJ'
            CALL M3EXIT ( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
         END IF

      END IF                    ! if firstime

      SYNCSTEP = TIME2SEC( TSTEP( 2 ) )

      DO 301 LVL = 1, NLAYS

         STEP = TIME2SEC ( ASTEP( LVL ) )
         DSTEP = STEP
         FDATE = JDATE
         FTIME = JTIME
         XYFIRST = .TRUE.

101      CONTINUE

         CALL RDBCON ( FDATE, FTIME, ASTEP( LVL ), LVL, BCON )

!        write( logdev,* ) ' lvl, fdate, ftime: ', lvl, fdate, ftime

         IF ( XYFIRST ) THEN

            XYFIRST = .FALSE.

            DO ROW = 1, MY_NROWS
               DO COL = 1, MY_NCOLS
                  YTRHOJ( COL,ROW ) = CGRID( COL,ROW,LVL,ASPC )
               END DO
            END DO
            CALL SUBST_COMM ( YTRHOJ, DSPL_N0_E0_S1_W0, DRCN_S, '2 0' )

!     write( logdev,* ) ' x_ppm/y_yamo - lvl, fdate, ftime: ', lvl, fdate, ftime

#ifdef isam
            CALL X_PPM ( CGRID, FDATE, FTIME, ASTEP( LVL ), LVL, BCON, ISAM )
#else
            CALL X_PPM ( CGRID, FDATE, FTIME, ASTEP( LVL ), LVL, BCON )
#endif
!           CALL LCKSUMMER ( 'X_PPM', CGRID, FDATE, FTIME, LVL )

#ifdef isam
            CALL Y_YAMO ( CGRID, FDATE, FTIME, ASTEP( LVL ), LVL, BCON, YTRHOJ, ISAM )
#else
            CALL Y_YAMO ( CGRID, FDATE, FTIME, ASTEP( LVL ), LVL, BCON, YTRHOJ )
#endif
!           CALL LCKSUMMER ( 'Y_YAMO', CGRID, FDATE, FTIME, LVL )

         ELSE

            XYFIRST = .TRUE.

            DO ROW = 1, MY_NROWS
               DO COL = 1, MY_NCOLS
                  XTRHOJ( COL,ROW ) = CGRID( COL,ROW,LVL,ASPC )
               END DO
            END DO
            CALL SUBST_COMM ( XTRHOJ, DSPL_N0_E0_S0_W1, DRCN_W, '1 0' )

!     write( logdev,* ) ' y_ppm/x_yamo - lvl, fdate, ftime: ', lvl, fdate, ftime

#ifdef isam
            CALL Y_PPM ( CGRID, FDATE, FTIME, ASTEP( LVL ), LVL, BCON, ISAM )
#else
            CALL Y_PPM ( CGRID, FDATE, FTIME, ASTEP( LVL ), LVL, BCON )
#endif
!           CALL LCKSUMMER ( 'Y_PPM', CGRID, FDATE, FTIME, LVL )

#ifdef isam
            CALL X_YAMO ( CGRID, FDATE, FTIME, ASTEP( LVL ), LVL, BCON, XTRHOJ, ISAM )
#else
            CALL X_YAMO ( CGRID, FDATE, FTIME, ASTEP( LVL ), LVL, BCON, XTRHOJ )
#endif
!           CALL LCKSUMMER ( 'X_YAMO', CGRID, FDATE, FTIME, LVL )

         END IF

         DSTEP = DSTEP + STEP
         IF ( DSTEP .LE. SYNCSTEP ) THEN
            CALL NEXTIME( FDATE, FTIME, SEC2TIME( STEP ) )
            GO TO 101
         END IF

301   CONTINUE

      RETURN
      END
