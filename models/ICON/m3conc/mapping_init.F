
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
C $Header: /project/yoj/arc/ICON/src/par/mapping_init.F,v 1.1 2011/11/02 13:17:25 yoj Exp $ 

        SUBROUTINE MAPPING_INIT ( XCELL_F, YCELL_F, XCELL_C, YCELL_C,
     &                            COL, ROW, COL_RATIO, ROW_RATIO,
     &                            COL_DISP, ROW_DISP, COL_LOC, ROW_LOC )

C-----------------------------------------------------------------------
C Purpose:
 
C Initialize the starting column and row location of the new shifted 
C decomposition
 
C Revision history:
 
C   Orginal version: 02/15/00 by David Wong, LM
 
C   7/20/00 David Wong, LM
C           -- convert XCELL_C, YCELL_C, XCELL_F, and YCELL_F into integer
C              before computing the ratio. This will avoid machine precision
C              problem to compute the ratio first and let the machine to
C              convert the answer into integer.
C   2/20/02 David Wong, LM
C           -- modified the ROW_DISP and COL_DISP calculations for the cases 
C              when the corresponding *_RATIO is 1 which means resolutions are 
C              the same in the fine and coarse grid.
C           -- modified the arithmetic when accessing the 2nd index of COLSX_PE 
C              and ROWSX_PE since they are starting from 1 rather than from 0.
C   27 May 06 J.Young: ck appropriate grid resolutions; changed row/col to
C                      col/row
                          
C Argument list:
 
C In:
C        XCELL_C -- resolution of the x-direction in the coarse domain
C        YCELL_C -- resolution of the y-direction in the coarse domain
C        XCELL_F -- resolution of the x-direction in the fine domain
C        YCELL_F -- resolution of the y-direction in the fine domain
C        COL     -- number of steps that the fine domain (1,1) cell needs to 
C                   leave the current coarse domain grid cell in the column
C                   direction
C        ROW     -- number of steps that the fine domain (1,1) cell needs to 
C                   leave the current coarse domain grid cell in the row 
C                   direction
 
C Out:
C        COL_RATIO -- the ratio between number of columns of the fine domain to
C                     the coarse domain
C        ROW_RATIO -- the ratio between number of rows of the fine domain to
C                     the coarse domain
C        COL_DISP  -- the column-wise distance between the starting point of 
C                     the fine domain and the coarse grid boundary;
C                     with a parallel decomposition, between the starting point of
C                     the fine domain in a processor and the coarse grid boundary
C                     (not nec. the physical application boundary)
C        ROW_DISP  -- the row-wise distance between the starting point of
C                     the fine domain and the coarse grid boundary;
C                     with a parallel decomposition, between the starting point of
C                     the fine domain in a processor and the coarse grid boundary
C                     (not nec. the physical application boundary)
 
C InOut:
C        COL_LOC   -- In:  the column location of the (1,1) cell of the fine
C                          domain in the coarse domain
C                     Out: the column location of the starting cell of the fine
C                          domain in the coarse domain
C        ROW_LOC   -- In:  the row location of the (1,1) cell of the fine 
C                          domain in the coarse domain
C                     Out: the row location of the starting cell of the fine 
C                          domain in the coarse domain
                          
C-----------------------------------------------------------------------

        USE HGRD_DEFN

        IMPLICIT NONE

#ifdef parallel
        INCLUDE SUBST_MPI        ! MPI definitions and parameters.
#endif

        REAL( 8 ) :: XCELL_C, YCELL_C, XCELL_F, YCELL_F
        INTEGER COL, ROW
        INTEGER COL_RATIO, ROW_RATIO, COL_DISP, ROW_DISP
        INTEGER COL_LOC, ROW_LOC

        INTEGER MY_PE           ! my PE number
        INTEGER TEMP_MY_PE      ! temporary PE number in modules arithmic or
                                ! integer division
        INTEGER ERROR           ! error returning code
        INTEGER SUM             ! summation variable

        CHARACTER( 16 ) :: PNAME = 'MAPPING_INIT'
        CHARACTER( 80 ) :: MSG = ' '

C-----------------------------------------------------------------------

        COL_RATIO = INT( YCELL_C ) / INT( YCELL_F )
        ROW_RATIO = INT( XCELL_C ) / INT( XCELL_F )

        IF ( COL_RATIO .LE. 0 .OR. ROW_RATIO .LE. 0 ) THEN
           WRITE( *,* ) ' *** COL_RATIO: ', COL_RATIO,
     &                  ' *** ROW_RATIO: ', ROW_RATIO
           MSG = 'Error in grid cell resolution'
           CALL M3EXIT( PNAME, 0, 0, MSG, 1 )
        END IF

        IF ( COL_RATIO .EQ. 1 ) THEN
           COL_DISP = 0
        ELSE 
           COL_DISP = COL_RATIO - COL + 1
        END IF

        IF ( ROW_RATIO .EQ. 1 ) THEN
           ROW_DISP = 0
        ELSE 
           ROW_DISP = ROW_RATIO - ROW + 1
        END IF

#ifdef parallel
        CALL MPI_COMM_RANK ( MPI_COMM_WORLD, MY_PE, ERROR )

        TEMP_MY_PE = MOD( MY_PE, NPCOL )
        IF ( TEMP_MY_PE .EQ. 0 ) THEN
           SUM = 0
        ELSE
!          SUM = COLSX_PE( 2,TEMP_MY_PE-1 )
           SUM = COLSX_PE( 2,TEMP_MY_PE )
        END IF

        IF ( SUM .EQ. 0 ) THEN
           COL_LOC = COL_LOC
        ELSE
           COL_LOC = COL_LOC + ( ( SUM + COL_DISP ) / COL_RATIO )
           COL_DISP = MOD( ( COL_DISP + SUM ), COL_RATIO )
        END IF

        TEMP_MY_PE = MY_PE / NPCOL
        IF ( TEMP_MY_PE .EQ. 0 ) THEN
           SUM = 0
        ELSE
!          SUM = ROWSX_PE( 2,( TEMP_MY_PE-1 )*NPCOL )
           SUM = ROWSX_PE( 2,( TEMP_MY_PE )*NPCOL )
        END IF

        IF ( SUM .EQ. 0 ) THEN
           ROW_LOC = ROW_LOC
        ELSE
           ROW_LOC = ROW_LOC + ( ( SUM + ROW_DISP ) / ROW_RATIO )
           ROW_DISP = MOD( ( ROW_DISP + SUM ), ROW_RATIO )
        END IF

#else
        COL_LOC = COL_LOC
        ROW_LOC = ROW_LOC
#endif

        RETURN
        END SUBROUTINE MAPPING_INIT
