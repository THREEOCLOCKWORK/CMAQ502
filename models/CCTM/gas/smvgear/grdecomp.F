
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
C $Header: /project/yoj/arc/CCTM/src/gas/smvgear/grdecomp.F,v 1.3 2011/10/21 16:11:14 yoj Exp $ 

C what(1) key, module and SID; SCCS file; date and time of last delta:
C @(#)grdecomp.F        1.1 /project/mod3/CMAQ/src/chem/smvgear/SCCS/s.grdecomp.  F 07 Jul 1997 12:45:23

       SUBROUTINE DECOMP

C***********************************************************************
C
C  FUNCTION:  To decompose the matrix [P] into lower- and upper
C             triangular form to facilitate solution of the set of 
C             linear simultaneous equations of the form [A]{x}={b}.
C
C  PRECONDITIONS: None
C                                                                     
C  KEY SUBROUTINES/FUNCTIONS CALLED: None
C
C  REVISION HISTORY: Prototype created by Jerry Gipson, June, 1995.
C                      Based on  the code originally developed by 
C                      M. Jacobson, (Atm. Env., Vol 28, No 2, 1994).
C                    Revised 3/14/96 by Jerry Gipson to conform to
C                      the Models-3 minimum IOV configuration
C                    Revised December 1996 by Jerry Gipson to conform
C                      to the Models-3 interim CTM that includes emissions
C                      in chemistry.
C                    Modified June, 1997 by Jerry Gipson to be consistent
C                      with beta CTM
C                    Modified September, 1997 by Jerry Gipson to be
C                      consistent with the targetted CTM
C                    16 Aug 01 J.Young: Use HGRD_DEFN
C                    31 Jan 05 J.Young: get BLKSIZE from dyn alloc horizontal
C                    & vertical domain specifications module (GRID_CONF)
C                    30 Jun 10 J.Young: convert for Namelist redesign; move all
C                    local include file variables into GRVARS module
C***********************************************************************

      USE GRVARS              ! inherits GRID_CONF

      IMPLICIT NONE
      
C..INCLUDES: None
      
C..ARGUMENTS: None

C..PARAMETERS: None

C..EXTERNAL FUNCTIONS: None

C..SAVED LOCAL VARIABLES: None

C..SCRATCH LOCAL VARIABLES:
      INTEGER IAR             ! Pointer to diagonal terms
      INTEGER IC              ! Loop index for ops in decomp loop 1
      INTEGER IDLO            ! Start index for decomp loop 1
      INTEGER IDHI            ! End index for decomp loop 1
      INTEGER IJ0             ! Pointer to ij term 1 in decomp loop 1
      INTEGER IJ1             ! Pointer to ij term 2 in decomp loop 1
      INTEGER IJA             ! Pointer to ij term 1 in decomp loop 2
      INTEGER IJB             ! Pointer to ij term 2 in decomp loop 2
      INTEGER IK0             ! Pointer to ik term 1 in decomp loop 1
      INTEGER IK1             ! Pointer to ik term 2 in decomp loop 1
      INTEGER J               ! Loop index for number of species
      INTEGER JC              ! Loop index for ops in decomp loop 2
      INTEGER JHI1            ! End index for 2-term decomp loop 2
      INTEGER JHI2            ! End index for 1-term decomp loop 2
      INTEGER JLO1            ! Start index for 2-term decomp loop 2
      INTEGER JLO2            ! Start index for 1-term decomp loop 2
      INTEGER KJ0             ! Pointer to kj term 1 in decomp loop 1
      INTEGER KJ1             ! Pointer to kj term 2 in decomp loop 1
      INTEGER NCELL           ! Loop index for number of cells      
c***********************************************************************      
      integer mxijdeca, mxijdecb, mxikdeca, mxikdecb, mxkjdeca, mxkjdecb
 
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  First loop of L-U decomposition 
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      JHI2 = JZLO( NCSP )
      DO 100 J = 1, ISCHAN

         IDLO = IDEC1LO( J, NCSP )
         IDHI = IDEC1HI( J, NCSP )
!     if ( idhi .gt. 0 ) then
!        mxijdeca = 0
!        mxijdecb = 0
!        mxikdeca = 0
!        mxikdecb = 0
!        mxkjdeca = 0
!        mxkjdecb = 0
!        do ic = idlo, idhi
!           if ( ijdeca( ic ) .gt. mxijdeca ) mxijdeca = ijdeca( ic )
!           if ( ijdecb( ic ) .gt. mxijdecb ) mxijdecb = ijdecb( ic )
!           if ( ikdeca( ic ) .gt. mxikdeca ) mxikdeca = ikdeca( ic )
!           if ( ikdecb( ic ) .gt. mxikdecb ) mxikdecb = ikdecb( ic )
!           if ( kjdeca( ic ) .gt. mxkjdeca ) mxkjdeca = kjdeca( ic )
!           if ( kjdecb( ic ) .gt. mxkjdecb ) mxkjdecb = kjdecb( ic )
!        end do
!        write( *,* ) '@==================== j', j, ' =========================@'
!        write( *,* ) '@=@ mxijdeca: ', mxijdeca
!        write( *,* ) '@=@ mxijdecb: ', mxijdecb
!        write( *,* ) '@=@ mxikdeca: ', mxikdeca
!        write( *,* ) '@=@ mxikdecb: ', mxikdecb
!        write( *,* ) '@=@ mxkjdeca: ', mxkjdeca
!        write( *,* ) '@=@ mxkjdecb: ', mxkjdecb
!     end if
         DO IC = IDLO, IDHI
            IJ0 = IJDECA( IC )
            IJ1 = IJDECB( IC )
            IK0 = IKDECA( IC )
            IK1 = IKDECB( IC )
            KJ0 = KJDECA( IC )
            KJ1 = KJDECB( IC )
            DO NCELL = 1, NUMCELLS
               CC2( NCELL, IJ0 ) = CC2( NCELL, IJ0 ) - 
     &                             CC2( NCELL, IK0 ) * CC2( NCELL, KJ0 )
               CC2( NCELL, IJ1 ) = CC2( NCELL, IJ1 ) - 
     &                             CC2( NCELL, IK1 ) * CC2( NCELL, KJ1 )
            END DO
         END DO
    
c...vdiag = 1 / current diagonal term of the decomposed matrix
         IAR = JARRAYPT( J, J, NCSP )
         DO NCELL = 1, NUMCELLS
            VDIAG( NCELL, J )  = 1.0 / CC2( NCELL, IAR )
         END DO
   
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Second loop of decompostion. The elements of L are divided by the
c  diagonal element, and the process is divided into parts to improve
c  vectorization.
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
         JLO1 = JHI2 + 1
         JHI1 = JHI2 + JHIZ1( J, NCSP ) 
         JLO2 = JHI1 + 1 
         JHI2 = JHI1 + JHIZ2( J, NCSP )
         
c...determine 2 terms at a time
         DO JC = JLO1, JHI1
            IJA = JZEROA( JC )
            IJB = JZEROB( JC )
            DO NCELL = 1, NUMCELLS
               CC2( NCELL, IJA ) = CC2( NCELL, IJA ) * VDIAG( NCELL, J )  
               CC2( NCELL, IJB ) = CC2( NCELL, IJB ) * VDIAG( NCELL, J )  
            END DO
         END DO
 
c...determine 1 term at a time 
         DO JC = JLO2, JHI2 
            IJA = JZEROA( JC )
            DO NCELL = 1, NUMCELLS
               CC2( NCELL, IJA ) = CC2( NCELL, IJA ) * VDIAG( NCELL, J )  
            END DO
         END DO

100   CONTINUE

      RETURN
      END
