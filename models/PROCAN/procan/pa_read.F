
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
C $Header: /project/yoj/arc/PROCAN/src/driver/pa/pa_read.F,v 1.8 2011/11/02 14:33:59 yoj Exp $

      SUBROUTINE PA_READ

C***********************************************************************
 
C Function: To read the Process Analysis input commmand file 
 
C Preconditions: None
  
C Key Subroutines/Functions Called: GETCHR
C                                   GETCYCLE
C                                   GETDESC
C                                   GETFAMILY
C                                   GETIPROUT
C                                   GETIRROUT
C                                   GETRXNSUM
C                                   GETWORD
C                                   RDLINE 
 
C Revision History:
C  Prototype created by Jerry Gipson, May, 1997
C  Modified May, 1997 by Jerry Gipson to be consistent with beta CTM
C  Modified Sept, 1997 by Jerry Gipson to be consistent with targeted CTM
C  Fixed default domain problem, Jerry Gipson, Feb '98
C  Updated May 2002 by Jerry Gipson for dynamic allocation version of CCTM
C  Updated August 2004 by Jerry Gipson to get input file path from environment variables
C  Modified output_domain error message, J. Gipson Aug '04 
C  Aug 2011 Jeff Young: Replaced I/O API include files with IOAPI's M3UTILIO

C***********************************************************************
      USE M3UTILIO      ! IOAPI module

      IMPLICIT NONE
      
C Includes:
      INCLUDE 'PA_GLOBAL.EXT'
      INCLUDE 'PA_PARSE.EXT'
      INCLUDE 'PA_VARS.EXT'
      
C Arguments: None
                                        
C Parameters:
      ! env var for PACP input file name
      CHARACTER( 16 ), PARAMETER :: PACP_INFILE = 'PACP_INFILE'  

C External Functions: 

C Local Variables:
      CHARACTER( 16 ) :: CMND       ! Current command being processed
      CHARACTER( 16 ) :: LASTCMND   ! Previous command processed

      INTEGER NDOMAIN    ! Number of GETDOMIN calls

      LOGICAL LIRRTYPE   ! Flag for input IRRTYPE command
      LOGICAL LIRRNONE   ! Flag for no IRR analysis
      LOGICAL LRDONLY    ! Flag for read only file
      LOGICAL LFMTTED    ! Flag for formatted file

C***********************************************************************
 
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Open irr mb file and get the first non-comment line
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!     IFILE  = JUNIT( )
!     OPEN( UNIT = IFILE, FILE = 'pa.inp', STATUS = 'OLD' )

      LRDONLY = .TRUE.
      LFMTTED = .TRUE.

      IFILE = GETEFILE ( PACP_INFILE, LRDONLY, LFMTTED, 'PA_READ' )
      IF ( IFILE .LT. 0 ) THEN
         MSG = 'PACP_INFILE not found; looking for pa.inp'
         CALL M3MESG( MSG )
         IFILE = GETEFILE ( 'pa.inp', LRDONLY, LFMTTED, 'PA_READ' )
         IF ( IFILE .LT. 0 ) THEN 
            MSG = 'ERROR: Could not open PACP input file'
            CALL M3EXIT( 'PA_READ', IZERO, IZERO, MSG, XSTAT2 )
         END IF
      END IF
 
      LINNUM  = 0
      NDOMAIN = 0
      LIRRTYPE = .FALSE.
      LIRRNONE = .FALSE.
      CALL RDLINE
      CALL GETCHR
      CALL GETWORD

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Process the IRRTYPE command if it is present
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      IF ( WORD .EQ. 'IRRTYPE' ) THEN
         LIRRTYPE = .TRUE.
         IF ( CHR .NE. '=' ) THEN
            WRITE( MSG, 94060 ) 
            CALL M3MESG( MSG )
            WRITE( MSG, 94000 ) LINNUM, INBUF
            CALL M3MESG( MSG )
            WRITE( MSG, 94020 ) CHR
            CALL M3MESG( MSG )
            CALL M3EXIT( 'PA_READ', IZERO, IZERO, ' ', XSTAT2 )
         END IF
         CALL GETCHR
         CALL GETWORD
         IF ( WORD .EQ. 'FULL' ) THEN
            LFULLIRR = .TRUE.
            LPARTIRR = .FALSE.
         ELSE IF ( WORD .EQ. 'PARTIAL' ) THEN
            LFULLIRR = .FALSE.
            LPARTIRR = .TRUE.
         ELSE IF ( WORD .EQ. 'NONE' ) THEN
            LIRRNONE = .TRUE.
            LFULLIRR = .FALSE.
            LPARTIRR = .FALSE.             
         ELSE
            WRITE( MSG, 94080 ) 
            CALL M3MESG( MSG )
            WRITE( MSG, 94000 ) LINNUM, INBUF
            CALL M3MESG( MSG )
            WRITE( MSG, 94040 ) WORD
            CALL M3MESG( MSG )
            CALL M3EXIT( 'PA_READ', IZERO, IZERO, ' ', XSTAT2 )
         END IF
         IF ( CHR .NE. ';' ) THEN
            WRITE( MSG, 94100 ) 
            CALL M3MESG( MSG )
            WRITE( MSG, 94000 ) LINNUM, INBUF
            CALL M3MESG( MSG )
            WRITE( MSG, 94020 ) CHR
            CALL M3MESG( MSG )
            CALL M3EXIT( 'PA_READ', IZERO, IZERO, ' ', XSTAT2 )
         ELSE
            CALL GETCHR
            CALL GETWORD
         END IF
      END IF

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c Top of loop for processing remaining commands
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
20    CONTINUE
      CMND = WORD
      IF ( WORD .EQ. 'DEFINE' ) THEN
         CALL GETWORD
         IF ( WORD .EQ. 'FAMILY' ) THEN 
            CALL GETFAMILY
         ELSE IF ( WORD .EQ. 'RXNSUM' ) THEN
            CALL GETRXNSUM
         ELSE IF ( WORD .EQ. 'CYCLE' ) THEN
            CALL GETCYCLE
         ELSE
            WRITE( MSG, 94120 ) 
            CALL M3MESG( MSG )
            WRITE( MSG, 94000 ) LINNUM, INBUF
            CALL M3MESG( MSG )
            WRITE( MSG,94040 ) WORD
            CALL M3MESG( MSG )
            CALL M3EXIT( 'PA_READ', IZERO, IZERO, ' ', XSTAT2 )
         END IF
      ELSE IF ( WORD .EQ. 'IRR_OUTPUT' ) THEN
         CALL GETIRROUT
      ELSE IF ( WORD .EQ. 'IPR_OUTPUT' ) THEN
         CALL GETIPROUT
      ELSE IF ( WORD .EQ. 'DESCRIPTION' ) THEN
         CALL GETDESC( LASTCMND )
!     ELSE IF ( WORD .EQ. 'OUTPUT_DOMAIN' ) THEN
     
      ELSE IF ( WORD .EQ. 'ENDPA' ) THEN
         GO TO 100
      ELSE
         WRITE( MSG, 94140 ) 
         CALL M3MESG( MSG )
         WRITE( MSG, 94000 ) LINNUM, INBUF
         CALL M3MESG( MSG )
         WRITE( MSG, 94040 ) WORD
         CALL M3MESG( MSG )
         CALL M3EXIT( 'PA_READ', IZERO, IZERO, ' ', XSTAT2 )
      END IF
      LASTCMND = CMND
      CALL GETWORD
      GO TO 20
100   CONTINUE

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c Print Warning messages for inconsistencies,omissions, etc.
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      IF ( LIRRTYPE ) THEN
         IF ( LFULLIRR .AND. NIRROUT .GT. 0 ) THEN
            WRITE( MSG, 94240 ) 
            CALL M3MESG( MSG )
            WRITE( MSG, 94260 ) 
            CALL M3MESG( MSG )
         ELSE IF ( LPARTIRR .AND. NIRROUT .EQ. 0 ) THEN
            LPARTIRR = .FALSE.
            WRITE( MSG, 94280 ) 
            CALL M3MESG( MSG )
            WRITE( MSG, 94300 ) 
            CALL M3MESG( MSG )
         ELSE IF ( LIRRNONE .AND. NIRROUT .GT. 0 ) THEN
            WRITE( MSG, 94320 ) 
            CALL M3MESG( MSG )
            WRITE( MSG, 94340 ) 
            CALL M3MESG( MSG )
         END IF
      ELSE
         IF ( NIRROUT .GT. 0 ) THEN
            LPARTIRR = .TRUE.
            LFULLIRR = .FALSE.
            WRITE( MSG, 94360 ) 
            CALL M3MESG( MSG )
            WRITE( MSG, 94380 ) 
            CALL M3MESG( MSG )
         END IF
      END IF            
      RETURN 

C*********************** FORMAT Statements *****************************

94000 FORMAT( '   Line No. ', I4, ': ', A )
94020 FORMAT( '   Character found: ', A )
94040 FORMAT( '   Word found: ', A )
94060 FORMAT( 'ERROR: Equal sign expected after IRRTYPE' )
94080 FORMAT( 'ERROR: FULL, PARTIAL, or NONE must follow IRRTYPE' )
94100 FORMAT( 'ERROR: A ; must follow FULL, PARTIAL, or NONE' )
94120 FORMAT( 'ERROR: FAMILY, RXNSUM, OR CYCLE must follow the DEFINE',
     &                 ' command' )
94140 FORMAT( 'ERROR: Invalid command' )
94160 FORMAT( 'WARNING: No output domain was specified.' )
94180 FORMAT( '         Output will be generated for the full domain.' )
94200 FORMAT( 'WARNING: Multiple output domains were specified.' )
94220 FORMAT( '         The last specification will be used.' )
94240 FORMAT( 'WARNING: LIRRTYPE = FULL but PARTIAL commands included' )
94260 FORMAT( '         A FULL IRR analysis will be assumed' )
94280 FORMAT( 'WARNING: LIRRTYPE = PARTIAL but no PARTIAL commands',
     &                    ' included' )
94300 FORMAT( '         No IRR outputs will be generated' )
94320 FORMAT( 'WARNING: LIRRTYPE = NONE but PARTIAL IRR commands', 
     &                     ' included' )
94340 FORMAT( '          No IRR outputs will be generated' )
94360 FORMAT( 'WARNING: LIRRTYPE not specified but PARTIAL commands',
     &                     ' included' )
94380 FORMAT( '         A PARTIAL IRR analysis will be generated' )  

94400 FORMAT( 'ERROR: OUTPUT_DOMAIN command included for dynamic allocation',
     &                     ' version' )
94420 FORMAT( '       OUTPUT_DOMAIN command must be removed from PACP',
     &        ' input file;' )
94440 FORMAT( '       set output domain via enviroment variables in CCTM',
     &        ' run script' )

      END

