
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
C $Header: /project/yoj/arc/CCTM/src/gas/ebi_saprc99/hrg4.F,v 1.2 2011/10/21 16:11:06 yoj Exp $

C what(1) key, module and SID; SCCS file; date and time of last delta:
C %W% %P% %G% %U%

       SUBROUTINE HRG4( DTC )

C**********************************************************************
C
C  FUNCTION:  To solve for the concentration of NO3 and N2O5
C
C  PRECONDITIONS: For the SAPRC99 family of mechanisms
C
C  KEY SUBROUTINES/FUNCTIONS CALLED: None
C
C  REVISION HISTORY: Created by EBI solver program, Feb. 11, 2011
C
C**********************************************************************
      USE HRDATA

      IMPLICIT NONE


C..INCLUDES: NONE


C..ARGUMENTS:
      REAL DTC             ! Time step


C..PARAMETERS: NONE


C..EXTERNAL FUNCTIONS: NONE


C..SAVED LOCAL VARIABLES:
      CHARACTER( 16 ), SAVE   ::  PNAME = 'HRG4'    ! Program name


C..SCRATCH LOCAL VARIABLES:
      REAL   A, B, C, Q   ! Quadratic equation terms
      REAL   CMN          ! Temp scalar
      REAL   L15          ! Loss of NO3
      REAL   L16          ! Loss of N2O5
      REAL   P15          ! Production of NO3
      REAL   K15_15       ! Kno3+no3 * delta t
      REAL   R15_16       ! Kn2o5-->no3 * delta t
      REAL   R16_15       ! Kno3+no2-->n2o5[NO2] * delta t


C**********************************************************************


c..Production of NO3 (except from N2O5 )
      P15 =           RXRAT(   6 )      ! O3P+NO2=NO3
     &     +          RXRAT(   8 )      ! O3+NO2=NO3
     &     +          RXRAT(  27 )      ! HO+HNO3=NO3
     &     +  0.390 * RXRAT(  34 )      ! HNO4=0.39*NO3+0.61*NO2+...

c..Loss frequency of NO3 ( except NO3 + NO3 if present )
      L15 =           RKI(   9 ) * YC( NO       )   ! NO3+NO=2*NO2
     &     +          RKI(  11 ) * YC( NO2      )   ! NO3+NO2=N2O5
     &     +          RKI(  14 ) * YC( NO2      )   ! NO3+NO2=NO+NO2
     &     +          RKI(  15 )                    ! NO3=NO
     &     +          RKI(  16 )                    ! NO3=NO2+O3P
     &     +          RKI(  26 ) * YC( HO       )   ! NO3+HO=HO2+NO2
     &     +          RKI(  39 ) * YC( HO2      )   ! NO3+HO2=0.8*HO+...
     &     +          RKI(  48 ) * YC( C_O2     )   ! NO3+C_O2=HCHO+...
     &     +          RKI(  53 ) * YC( RO2_R    )   ! NO3+RO2_R=NO2+HO2
     &     +          RKI(  58 ) * YC( R2O2     )   ! NO3+R2O2=NO2
     &     +          RKI(  65 ) * YC( RO2_N    )   ! NO3+RO2_N=NO2+...
     &     +          RKI(  73 ) * YC( CCO_O2   )   ! NO3+CCO_O2=C_O2+NO2
     &     +          RKI(  83 ) * YC( RCO_O2   )   ! NO3+RCO_O2=NO2+...
     &     +          RKI(  94 ) * YC( BZCO_O2  )   ! NO3+BZCO_O2=NO2+...
     &     +          RKI( 106 ) * YC( MA_RCO3  )   ! NO3+MA_RCO3=NO2+...
     &     +          RKI( 129 ) * YC( HCHO     )   ! NO3+HCHO=HNO3+HO2+CO
     &     +          RKI( 132 ) * YC( CCHO     )   ! NO3+CCHO=HNO3+CCO_O2
     &     +          RKI( 135 ) * YC( RCHO     )   ! NO3+RCHO=HNO3+RCO_O2
     &     +          RKI( 148 ) * YC( GLY      )   ! NO3+GLY=HNO3+...
     &     +          RKI( 151 ) * YC( MGLY     )   ! NO3+MGLY=HNO3+CO+...
     &     +          RKI( 154 ) * YC( PHEN     )   ! NO3+PHEN=HNO3+BZ_O
     &     +          RKI( 156 ) * YC( CRES     )   ! NO3+CRES=HNO3+BZ_O
     &     +          RKI( 157 ) * YC( NPHE     )   ! NO3+NPHE=HNO3+...
     &     +          RKI( 160 ) * YC( BALD     )   ! NO3+BALD=HNO3+...
     &     +          RKI( 163 ) * YC( METHACRO )   ! NO3+METHACRO=...
     &     +          RKI( 172 ) * YC( ISOPROD  )   ! NO3+ISOPROD=...
     &     +          RKI( 187 ) * YC( ETHENE   )   ! NO3+ETHENE=RO2_R+...
     &     +          RKI( 191 ) * YC( ISOPRENE )   ! NO3+ISOPRENE=...
     &     +          RKI( 195 ) * YC( TRP1     )   ! NO3+TRP1=...
     &     +          RKI( 213 ) * YC( OLE1     )   ! NO3+OLE1=...
     &     +          RKI( 217 ) * YC( OLE2     )   ! NO3+OLE2=...

c..Loss frequency of N2O5
      L16 =           RKI(  12 )                    ! N2O5=NO2+NO3
     &     +          RKI(  13 )                    ! N2O5=2*HNO3

c..K15_15, R15_16, and R16_15 terms
      K15_15  = RKI(  40 ) * DTC

      R15_16  = ( RKI(  12 ) ) * DTC 


      R16_15  = RKI(  11 ) * YC( NO2 ) * DTC

c..Solution of quadratic equation to get NO3 & N2O5
      CMN = 1.0 + L16 * DTC
      A = 2.0 * K15_15 * CMN
      B = CMN * ( 1.0 + L15 * DTC ) - R15_16 * R16_15
      C = CMN * ( YC0( NO3 ) + P15 * DTC ) +  R15_16 * YC0( N2O5 )

      Q = -0.5 * ( B + SIGN( 1.0, B ) * SQRT( B * B + 4.0 * A * C ) )
      YCP( NO3 ) = MAX( Q / A , -C / Q  )
      YCP( N2O5 ) = ( YC0( N2O5 ) + R16_15 * YCP( NO3 ) ) / CMN

      RETURN

      END
