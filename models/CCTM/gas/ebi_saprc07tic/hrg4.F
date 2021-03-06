
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
C $Header$

C what(1) key, module and SID; SCCS file; date and time of last delta:
C %W% %P% %G% %U%

       SUBROUTINE HRG4( DTC )

C**********************************************************************
C
C  FUNCTION:  To solve for the concentration of NO3 and N2O5
C
C  PRECONDITIONS: For the SAPRC07TIC family of mechanisms
C
C  KEY SUBROUTINES/FUNCTIONS CALLED: None
C
C  REVISION HISTORY: Created by EBI solver program, Oct. 18, 2012
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
     &     +          RXRAT(  27 )      ! OH+HNO3=NO3
     &     +  0.390 * RXRAT(  34 )      ! HNO4=0.39*NO3+0.61*NO2+...
     &     +  0.400 * RXRAT(  69 )      ! PAN=0.4*NO3+0.6*NO2+...
     &     +  0.400 * RXRAT(  79 )      ! PAN2=0.4*NO3+0.6*NO2+...
     &     +  0.400 * RXRAT(  90 )      ! PBZN=0.4*NO3+0.6*NO2+...
     &     +  0.400 * RXRAT( 102 )      ! MAPAN=0.4*NO3+0.6*NO2+...
     &     +          RXRAT( 569 )      ! CLONO2=NO3+CL
     &     +          RXRAT( 571 )      ! CL+CLONO2=NO3+CL2
     &     +  0.310 * RXRAT( 701 )      ! ISOPNOOD+NO=0.31*NO3+...
     &     +  0.155 * RXRAT( 703 )      ! ISOPNOOD+MEO2=0.155*NO3+...
     &     +  0.155 * RXRAT( 704 )      ! ISOPNOOD+RO2C=0.155*NO3+...
     &     +  0.310 * RXRAT( 705 )      ! ISOPNOOD+MECO3=0.31*NO3+...
     &     +          RXRAT( 772 )      ! MVKN+OH=NO3+0.65*MGLY+...
     &     +  0.150 * RXRAT( 774 )      ! MACRN+OH=0.08*NO3+...

c..Loss frequency of NO3 ( except NO3 + NO3 if present )
      L15 =           RKI(   9 ) * YC( NO               )   ! NO3+NO=2*NO2
     &     +          RKI(  11 ) * YC( NO2              )   ! NO3+NO2=N2O5
     &     +          RKI(  15 ) * YC( NO2              )   ! NO3+NO2=NO+NO2
     &     +          RKI(  16 )                            ! NO3=NO
     &     +          RKI(  17 )                            ! NO3=NO2+O3P
     &     +          RKI(  26 ) * YC( OH               )   ! NO3+OH=HO2+NO2
     &     +          RKI(  39 ) * YC( HO2              )   ! NO3+HO2=0.8*OH+...
     &     +          RKI(  53 ) * YC( MEO2             )   ! NO3+MEO2=HCHO+...
     &     +          RKI(  58 ) * YC( RO2C             )   ! NO3+RO2C=NO2
     &     +          RKI(  63 ) * YC( RO2XC            )   ! NO3+RO2XC=NO2
     &     +          RKI(  72 ) * YC( MECO3            )   ! NO3+MECO3=MEO2+...
     &     +          RKI(  82 ) * YC( RCO3             )   ! NO3+RCO3=NO2+...
     &     +          RKI(  93 ) * YC( BZCO3            )   ! NO3+BZCO3=NO2+...
     &     +          RKI( 201 ) * YC( HCHO             )   ! NO3+HCHO=HNO3+HO2+CO
     &     +          RKI( 204 ) * YC( CCHO             )   ! NO3+CCHO=HNO3+MECO3
     &     +          RKI( 207 ) * YC( RCHO             )   ! NO3+RCHO=HNO3+RCO3
     &     +          RKI( 227 ) * YC( GLY              )   ! NO3+GLY=HNO3+...
     &     +          RKI( 230 ) * YC( MGLY             )   ! NO3+MGLY=HNO3+CO+...
     &     +          RKI( 233 ) * YC( CRES             )   ! NO3+CRES=HNO3+BZO
     &     +          RKI( 239 ) * YC( BALD             )   ! NO3+BALD=HNO3+BZCO3
     &     +          RKI( 249 ) * YC( MACR             )   ! NO3+MACR=...
     &     +          RKI( 257 ) * YC( IPRD             )   ! NO3+IPRD=...
     &     +          RKI( 264 ) * YC( HOCCHO           )   ! NO3+HOCCHO=HNO3+...
     &     +          RKI( 267 ) * YC( ACROLEIN         )   ! NO3+ACROLEIN=...
     &     +          RKI( 507 ) * YC( ETHENE           )   ! NO3+ETHENE=xHO2+...
     &     +          RKI( 511 ) * YC( PROPENE          )   ! NO3+PROPENE=...
     &     +          RKI( 515 ) * YC( BUTADIENE13      )   ! NO3+BUTADIENE13=...
     &     +          RKI( 521 ) * YC( APIN             )   ! NO3+APIN=...
     &     +          RKI( 539 ) * YC( OLE1             )   ! NO3+OLE1=...
     &     +          RKI( 543 ) * YC( OLE2             )   ! NO3+OLE2=...
     &     +          RKI( 549 ) * YC( TERP             )   ! NO3+TERP=...
     &     +          RKI( 553 ) * YC( SESQ             )   ! NO3+SESQ=...
     &     +          RKI( 565 ) * YC( CL               )   ! NO3+CL=CLO+NO2
     &     +          RKI( 685 ) * YC( ISOPRENE         )   ! NO3+ISOPRENE=NISOPO2
     &     +          RKI( 686 ) * YC( NISOPO2          )   ! NO3+NISOPO2=...
     &     +          RKI( 714 ) * YC( NIT1             )   ! NO3+NIT1=...
     &     +          RKI( 715 ) * YC( NIT1NO3OOA       )   ! NO3+NIT1NO3OOA=...
     &     +          RKI( 722 ) * YC( NIT1NO3OOB       )   ! NO3+NIT1NO3OOB=...
     &     +          RKI( 754 ) * YC( MACO3            )   ! NO3+MACO3=NO2+CO+...

c..Loss frequency of N2O5
      L16 =           RKI(  12 )                            ! N2O5=NO2+NO3
     &     +          RKI(  13 )                            ! N2O5=2*HNO3
     &     +          RKI(  14 )                            ! N2O5=2*HNO3

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
