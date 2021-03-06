
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
C $Header: /project/yoj/arc/PROCAN/src/driver/pa/pa_compmech.F,v 1.8 2011/11/02 14:33:55 yoj Exp $

      SUBROUTINE PA_COMPMECH

C***********************************************************************
 
C Function: To produce a compressed mechanism structure for the PA
C           output listing program
 
C Preconditions: None
  
C Key Subroutines/Functions Called: None
 
C Revision History:
C  Prototype created by Jerry Gipson, August, 1996
C  Modified May, 1997 by Jerry Gipson to be consistent with beta CTM
C  Modified Dec. 7, 2000 by Jerry Gipson to correct problem in getting
C  character length of a species name used in the compressed mechanism
C  Modified May 2002 by Jerry Gipson to increase number of reaction lines
C  (for saprc99)
C  Aug 2011 Jeff Young: Replaced I/O API include files with IOAPI's M3UTILIO
 
C***********************************************************************
      USE M3UTILIO      ! IOAPI module

      IMPLICIT NONE
      
C Includes:
      INCLUDE 'PA_GLOBAL.EXT'
      INCLUDE 'PA_PARSE.EXT'
      INCLUDE 'PA_VARS.EXT'
      
C Arguments: None
                                        
C Parameters: None

C External Functions: 
      CHARACTER( 10 ) :: TRIMCOEF  ! Trims size of coefficients

C Local Variables:
      CHARACTER( 72 ) :: LINOUT  ! line of mechanism text
      CHARACTER( 10 ) :: COUT    ! Coefficient in character representation
      CHARACTER(  1 ) :: SIGNC   ! Sign character
      CHARACTER( 16 ) :: SPCNAM  ! Species name
      CHARACTER( LABLEN ) :: TEMPSTR  ! Temporary holder of right-justified label

      INTEGER COUTLEN  ! Length of character based coefficient
      INTEGER ENDPOS   ! Ending position on line for next product
      INTEGER EQPOS    ! Position of equals sign
      INTEGER EXPOS    ! Eclamation point position 
      INTEGER IE1, IE2 ! Ending position of characters in a string
      INTEGER IEND     ! Position of last non-blank character in LINOUT
      INTEGER INDX     ! Index for species name
      INTEGER IS1, IS2 ! Starting position of characters in a string
      INTEGER ISTAR    ! Counter for sign
      INTEGER LEN1     ! Actual label length
      INTEGER :: LINLEN = 72   ! Max length of line of mechanism text
      INTEGER MAXLEN   ! Max length of a label on output
      INTEGER :: NAMLEN = 16   ! Max length of a species/label name
      INTEGER NRX      ! Loop index for reactions
      INTEGER N        ! Loop index
      INTEGER NFAM     ! Loop index for familys 
      INTEGER OUTLEN   ! Number of characters in output string

      REAL SPCOEF      ! Single Precision coefficient

C***********************************************************************
      
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Find the longest reaction label length and trim to six characters
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      MAXLEN = 0
      DO NRX = 1, NRXNS
         MAXLEN = MAX( MAXLEN, LEN_TRIM( RXLABEL( NRX ) ) )
      END DO
      IF ( MAXLEN .GT. 6 ) MAXLEN = 6

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Set the compressed mechanism list for each reaction
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      DO 100 NRX = 1, NRXNS

c..First get the reaction label right justified
                  !123456789012345678901234 
         LINOUT = 'c    &              IRR<'
         IEND = LEN_TRIM( LINOUT )
         DO N = 1, LABLEN
            TEMPSTR( N:N ) = ' '
         END DO
         IS1 = LBLANK( RXLABEL( NRX ) ) + 1
         IE1 = LEN_TRIM( RXLABEL( NRX ) )
         LEN1 = IE1 - IS1 + 1
         LEN1 = MIN( MAXLEN, LEN1 )
         IE1 = IS1 + LEN1 - 1
         IE2 = LABLEN
         IS2 = LABLEN - LEN1 + 1
         TEMPSTR( IS2:IE2 ) = RXLABEL( NRX )( IS1:IE1 ) 
         IS2 = LABLEN - MAXLEN + 1          
         LINOUT = LINOUT( 1 : IEND ) // TEMPSTR( IS2:IE2 ) // '> !'
         IEND = LEN_TRIM( LINOUT ) + 1
         EXPOS = IEND - 1
          
c..List reactants
         DO N = 1, NREACT( NRX )
            INDX = IRR( NRX, N )
            SPCNAM = GC_SPC( INDX )
            OUTLEN = MIN( 6, LEN_TRIM( SPCNAM ) )
            IF ( N .EQ. 1 ) THEN
               LINOUT = LINOUT( 1:IEND ) // SPCNAM( 1:OUTLEN )
            ELSE
               LINOUT = LINOUT( 1:IEND ) // '+' // 
     &                  SPCNAM( 1:OUTLEN )
            END IF
            IEND = LEN_TRIM( LINOUT )
         END DO

c..Add hv, H2O, M, N2 or O2
         IF ( BTEST( IRXBITS( NRX ), 1 ) ) THEN
            LINOUT = LINOUT( 1:IEND ) // '+hv'
            IEND = LEN_TRIM( LINOUT )
         END IF
         IF ( BTEST( IRXBITS( NRX ), 2 ) ) THEN
            LINOUT = LINOUT( 1:IEND ) // '+M'
            IEND = LEN_TRIM( LINOUT )
         END IF
         IF ( BTEST( IRXBITS( NRX ), 3 ) ) THEN
            LINOUT = LINOUT( 1:IEND ) // '+H2O'
            IEND = LEN_TRIM( LINOUT )
         END IF
         IF ( BTEST( IRXBITS( NRX ), 4 ) ) THEN
            LINOUT = LINOUT( 1:IEND ) // '+O2'
            IEND = LEN_TRIM( LINOUT )
         END IF
         IF ( BTEST( IRXBITS( NRX ), 5 ) ) THEN
            LINOUT = LINOUT( 1:IEND ) // '+N2'
            IEND = LEN_TRIM( LINOUT )
         END IF
         EQPOS = IEND + 1                
         LINOUT = LINOUT( 1:IEND ) // '='
         IEND = IEND + 1               

c..List products
         LINNUM = 1
         DO N = 1, NPRDCT( NRX )
            INDX = IRR( NRX,N + 3 )
            SPCNAM = GC_SPC( INDX )
            OUTLEN = MIN( 6, LEN_TRIM( SPCNAM ) )
            SPCOEF = SC( NRX,N )
            IF ( SPCOEF .NE. 1.0 ) THEN
               COUT = TRIMCOEF( SPCOEF )
               COUTLEN = LEN_TRIM( COUT )
               ISTAR = 1
            ELSE
               COUTLEN = 0
               ISTAR = 0
            END IF                
            ENDPOS = IEND + 1 + COUTLEN + OUTLEN
            IF ( ENDPOS .GT. LINLEN ) THEN
               MECLINE( NRX,LINNUM ) = LINOUT
               LINNUM = LINNUM + 1
               IF ( LINNUM .GT. MXMECHLINE ) THEN
                  WRITE( MSG, 94000 )
                  CALL M3MESG( MSG )
                  CALL M3EXIT( 'MECHCOMP', IZERO, IZERO, ' ', XSTAT2 )
               END IF
               LINOUT = ''
               LINOUT( 1:1 ) = 'c'
               LINOUT( EXPOS:EXPOS ) = '!'
               IEND = EXPOS + 6
            END IF
            IF ( SPCOEF .LT. 0.0 ) THEN
               SIGNC = '-'
            ELSE
               SIGNC = '+'
            END IF
            IF ( N .NE. 1 .OR. SIGNC .EQ. '-' ) THEN
               LINOUT = LINOUT( 1:IEND ) // SIGNC
               IEND = IEND + 1
            END IF
            IF ( SPCOEF .EQ. 1.0 ) THEN
               LINOUT = LINOUT( 1:IEND ) // SPCNAM( 1:OUTLEN )
            ELSE
               LINOUT = LINOUT( 1:IEND ) // COUT( 1:COUTLEN ) //
     &                 '*' // SPCNAM( 1:OUTLEN )
            END IF
            IEND = LEN_TRIM( LINOUT )
         END DO             
         MECLINE( NRX, LINNUM ) = LINOUT 
         MECNUMLNS( NRX ) = LINNUM 
100   CONTINUE      

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Now get a compressed list of Family definitions
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      DO 200 NFAM = 1, NFAMLYS
         IEND = LEN_TRIM( FAMNAME( NFAM ) )
         LINOUT = 'c    ' // FAMNAME( NFAM )( 1:IEND ) // '='
         IEND = LEN_TRIM( LINOUT )
         EQPOS = IEND
         LINNUM = 1
         DO N = 1, NUMFAMMEM( NFAM )
            SPCNAM = FAMMEMNAM( NFAM, N )
            OUTLEN = MIN( 6, LEN_TRIM( SPCNAM ) )
            IF ( FAMSC( NFAM, N ) .NE. 1.0 ) THEN
               COUT = TRIMCOEF( FAMSC( NFAM, N ) )  
               COUTLEN = LEN_TRIM( COUT )
               ISTAR = 1
            ELSE
               COUTLEN = 0
               ISTAR = 0
            END IF             
            ENDPOS = IEND + 1 + COUTLEN + OUTLEN
            IF ( ENDPOS .GT. LINLEN ) THEN
               FAMLINE( NFAM, LINNUM ) = LINOUT
               LINNUM = LINNUM + 1
               IF ( LINNUM .GT. MXFAMLINE ) THEN
                   WRITE( MSG, 94020 )
                   CALL M3MESG( MSG )
                   CALL M3EXIT( 'MECHCOMP', IZERO, IZERO, ' ', XSTAT2 )
               END IF
               LINOUT = ''
               LINOUT( 1:1 ) = 'c'
               IEND = EQPOS
            END IF
            IF ( FAMSC( NFAM, N ) .LT. 0.0 ) THEN
               SIGNC = '-'
            ELSE
               SIGNC = '+'
            END IF
            IF ( N .NE. 1 .OR. SIGNC .EQ. '-' ) THEN
               LINOUT = LINOUT( 1:IEND ) // SIGNC
               IEND = IEND + 1
            END IF
            IF ( FAMSC( NFAM, N ) .EQ. 1.0 ) THEN
               LINOUT = LINOUT( 1:IEND ) // SPCNAM( 1:OUTLEN )
            ELSE
               LINOUT = LINOUT( 1:IEND ) // COUT( 1:COUTLEN ) //
     &                  '*' // SPCNAM( 1:OUTLEN )
            END IF
            IEND = LEN_TRIM( LINOUT )
         END DO    
         FAMLINE( NFAM, LINNUM ) = LINOUT 
         FAMNUMLNS( NFAM ) = LINNUM 
200   CONTINUE

      RETURN

C*********************** FORMAT Statements *****************************

94000 FORMAT( 'ERROR: Maximum number of lines for compressed',
     &          ' mechanism exceeded' )
94020 FORMAT( 'ERROR: Maximum number of lines for compressed',
     &          ' family definition exceeded' )

      END  


