
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
C $Header: /project/yoj/arc/CCTM/src/emis/emis/STK_EMIS.F,v 1.4 2012/01/19 15:25:35 yoj Exp $

C what(1) key, module and SID; SCCS file; date and time of last delta:
C %W% %P% %G% %U%

C:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
      MODULE STK_EMIS

C-----------------------------------------------------------------------
C Function: stack emissions by source from stack emissions file and
C           3d point source emissions

C Revision History:
C     16 Jan 2007 J.Young: initial implementation
C     16 Feb 2011 S.Roselle: replaced I/O API include files with UTILIO_DEFN

C-----------------------------------------------------------------------

      USE UDTYPES, ONLY: RARRY2, CARRY1

      IMPLICIT NONE

      INTEGER,         ALLOCATABLE, SAVE :: NSRC_EMIS( : )   ! no. of pt sources
      INTEGER,         ALLOCATABLE, SAVE :: NVARS_EMIS( : )  ! no. of species
      INTEGER, PARAMETER                 :: NVARS_FIRE = 1   ! 

      LOGICAL,         ALLOCATABLE, SAVE :: FIREFLAG( : )    ! which is the fire file?

c     TYPE :: RARRY2
c        REAL,    POINTER :: ARRY( :,: )
c        INTEGER          :: LEN1, LEN2
c     END TYPE RARRY2

c     TYPE :: CARRY1
c        CHARACTER( 16 ), POINTER :: ARRY( : )
c        INTEGER                  :: LEN
c     END TYPE CARRY1

      TYPE( RARRY2 ), ALLOCATABLE, SAVE :: STKEMIS( : )   ! stack emissions [mol/s]
      TYPE( CARRY1 ), ALLOCATABLE, SAVE :: STKSPC( : )    ! emitted species names
      TYPE( RARRY2 ), ALLOCATABLE, SAVE :: FIREVAR( : )   ! fire variables, 2 assumed
      TYPE( CARRY1 ), ALLOCATABLE, SAVE :: FIRENAM( : )   ! fire variable names

      INTEGER, PARAMETER                :: FGRPS = 1      ! assuming one fire sector

      INTEGER,        ALLOCATABLE, SAVE :: STKDATE( : )   ! src grp timestamp date
!     INTEGER,        ALLOCATABLE, SAVE :: STKTIME( : )   ! src grp timestamp time
      INTEGER,        ALLOCATABLE, SAVE :: SYNCOFF( : )   ! src grp timestamp date offset

      CONTAINS

         FUNCTION STK_EMIS_INIT ( STKENAME, JDATE, JTIME ) RESULT ( SUCCESS )

         USE UTILIO_DEFN

         IMPLICIT NONE

         CHARACTER( 16 ), INTENT( IN ) :: STKENAME( : )  ! stack groups emis file names
         INTEGER, INTENT( IN )         :: JDATE, JTIME
         LOGICAL SUCCESS

         INTEGER I, J, N, NGRPS, LEN1, LEN2, V

         INTEGER ASTAT
         CHARACTER( 96 ) :: XMSG = ' '
         CHARACTER( 16 ) :: PNAME = 'STK_EMIS_INIT'

C-----------------------------------------------------------------------

         SUCCESS = .TRUE.

         NGRPS = SIZE( STKENAME )

         ALLOCATE ( NSRC_EMIS( NGRPS ), STAT = ASTAT )
         CALL CHECKMEM( ASTAT, 'NSRC_EMIS', PNAME )

         ALLOCATE ( NVARS_EMIS( NGRPS ), STAT = ASTAT )
         CALL CHECKMEM( ASTAT, 'NVARS_EMIS', PNAME )

         ALLOCATE ( STKDATE( NGRPS ), STAT = ASTAT )
         CALL CHECKMEM( ASTAT, 'STKDATE', PNAME )

!        ALLOCATE ( STKTIME( NGRPS ), STAT = ASTAT )
!        CALL CHECKMEM( ASTAT, 'STKTIME', PNAME )

         ALLOCATE ( SYNCOFF( NGRPS ), STAT = ASTAT )
         CALL CHECKMEM( ASTAT, 'SYNCOFF', PNAME )

         ALLOCATE ( STKEMIS( NGRPS ), STAT = ASTAT )
         CALL CHECKMEM( ASTAT, 'STKEMIS', PNAME )

         ALLOCATE ( STKSPC( NGRPS ), STAT = ASTAT )
         CALL CHECKMEM( ASTAT, 'STKSPC', PNAME )

         ALLOCATE ( FIREFLAG( NGRPS ), STAT = ASTAT )
         CALL CHECKMEM( ASTAT, 'FIREFLAG', PNAME )
         FIREFLAG = .FALSE.   ! array

         ALLOCATE ( FIREVAR( FGRPS ), STAT = ASTAT )
         CALL CHECKMEM( ASTAT, 'FIREVAR', PNAME )

         ALLOCATE ( FIRENAM( FGRPS ), STAT = ASTAT )
         CALL CHECKMEM( ASTAT, 'FIRENAM', PNAME )

         DO N = 1, NGRPS

            IF ( .NOT. OPEN3( STKENAME( N ), FSREAD3, PNAME ) ) THEN
               XMSG = 'Could not open '// TRIM( STKENAME( N ) ) // ' file'
               CALL M3MESG( XMSG )
               SUCCESS = .FALSE.; RETURN
            END IF

            IF ( .NOT. DESC3( STKENAME( N ) ) ) THEN
               XMSG = 'Could not get ' // TRIM( STKENAME( N ) ) // ' file description'
               CALL M3MESG( XMSG )
               SUCCESS = .FALSE.; RETURN
            END IF

            STKDATE( N ) = SDATE3D
!           STKTIME( N ) = STIME3D
            SYNCOFF( N ) = SECSDIFF( JDATE,JTIME, STKDATE( N ),JTIME )
            NSRC_EMIS( N ) = NROWS3D
            NVARS_EMIS( N ) = NVARS3D
            LEN1 = NSRC_EMIS( N )
            LEN2 = NVARS_EMIS( N )
            DO I = 1, LEN2
               IF ( VNAME3D( I ) .EQ. 'HFLUX' ) FIREFLAG( N ) = .TRUE.
            END DO
            IF ( FIREFLAG( N ) ) THEN   ! subtract off 'HFLUX'
               LEN2 = LEN2 - NVARS_FIRE
               NVARS_EMIS( N ) = LEN2
            END IF

            STKEMIS( N )%LEN1 = LEN1
            STKEMIS( N )%LEN2 = LEN2
            ALLOCATE ( STKEMIS( N )%ARRY( LEN1,LEN2 ), STAT = ASTAT )
            CALL CHECKMEM( ASTAT, 'STKEMIS', PNAME )
            STKEMIS( N )%ARRY = 0.0   ! array

            STKSPC( N )%LEN = LEN2
            ALLOCATE ( STKSPC( N )%ARRY( LEN2 ), STAT = ASTAT )
            CALL CHECKMEM( ASTAT, 'STKSPC', PNAME )

            IF ( FIREFLAG( N ) ) THEN   ! subtract and save off 'HFLUX'
               ALLOCATE ( FIREVAR( 1 )%ARRY( LEN1,NVARS_FIRE ), STAT = ASTAT )
               CALL CHECKMEM( ASTAT, 'FIREVAR', PNAME )
               ALLOCATE ( FIRENAM( 1 )%ARRY( NVARS_FIRE ), STAT = ASTAT )
               CALL CHECKMEM( ASTAT, 'FIRENAM', PNAME )
               I = 0
               DO J = 1, NVARS3D
C The FIRENAM_FIREVAR to match use in PT3D_DEFN
                  IF ( TRIM( VNAME3D( J ) ) .EQ. 'HFLUX' ) THEN
                     FIRENAM( 1 )%ARRY( 1 ) = VNAME3D( J )
                     CYCLE
                  END IF
                  I = I + 1
                  STKSPC( N )%ARRY( I ) = VNAME3D( J )
               END DO
               FIRENAM( 1 )%LEN = NVARS_FIRE
               FIREVAR( 1 )%LEN1 = LEN1
               FIREVAR( 1 )%LEN2 = NVARS_FIRE
            ELSE
!              STKSPC( N )%ARRY = VNAME3D   ! array
               DO J = 1, STKSPC( N )%LEN
                  STKSPC( N )%ARRY( J ) = VNAME3D( J )
               END DO
            END IF

         END DO

         RETURN

         END FUNCTION STK_EMIS_INIT

      END MODULE STK_EMIS
