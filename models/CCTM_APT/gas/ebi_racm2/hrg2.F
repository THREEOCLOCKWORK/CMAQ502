
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

      SUBROUTINE HRG2( DTC )
C**********************************************************************
C
C  FUNCTION: To solve for the concentration of HO, HO2, HONO, and
C            HNO4 alebraically.
C
C  PRECONDITIONS: For the RACM2 family of mechanisms
C
C  KEY SUBROUTINES/FUNCTIONS CALLED: None
C
C  REVISION HISTORY: Created by EBI solver program, March 4, 2013
C
C**********************************************************************
      USE HRDATA

      IMPLICIT NONE


C..INCLUDES: None


C..ARGUMENTS:
      REAL DTC                      ! Time step

C..PARAMETERS: None


C..EXTERNAL FUNCTIONS: NONE


C..SAVED LOCAL VARIABLES:
      CHARACTER( 16 ), SAVE :: PNAME = 'HRG2'             ! Program name


C..SCRATCH LOCAL VARIABLES:
      REAL    O1D_S                 ! sum of O1D loss frequencies
      REAL    OH_S                  ! stoich coeff for OH from O1D+H2O or H2
      REAL    HO2_S                 ! stoich coeff for HO2 from O1D+H2 rxn
      REAL    EXN_S                 ! sum of NO2EX loss frequencies
      REAL    XOH_S                 ! stoich coeff for OH & HONO from NO2EX loss rxn
      REAL    R4_19                 ! production of OH from HONO
      REAL    R19_4                 ! production of HONO from OH
      REAL    R4_5                  ! production of OH from HO2
      REAL    R5_4                  ! production of HO2 from OH
      REAL    R5_21                 ! production of HO2 from HNO4
      REAL    R21_5                 ! production of HNO4 from HO2
      REAL    P4, P5, P19, P21      ! species production form other paths
      REAL    L4, L5, L19, L21      ! species loss terms

      REAL    A, B, C               ! coeffs of quadratic eq. for HO2
      REAL    Q                     ! intermediate term

      REAL    T1, T2, T3            ! intermediate terms

      REAL    L21_INV               ! reciprocal of HNO4 loss term

C**********************************************************************


c..stoichiometric coefficient for production of HOX from O3 via O1D
      O1D_S =           RKI(  40 )                   ! O1D=O3P
     &       +          RKI(  41 )                   ! O1D=O3P
     &       +          RKI(  42 )                   ! O1D=2*HO

      OH_S =   2.000 * RKI(  42 )                   ! O1D=2*HO

      OH_S  = OH_S / O1D_S


c..Production of HO from HO2 (r4,5 terms )
      R4_5 =           RKI(  35 ) * YC( O3      )   ! HO2+O3=HO
     &      +          RKI(  50 ) * YC( NO      )   ! HO2+NO=HO+NO2
     &      +  0.700 * RKI(  59 ) * YC( NO3     )   ! HO2+NO3=0.7*HO+...
     &      +  0.440 * RKI( 231 ) * YC( ACO3    )   ! HO2+ACO3=0.44*HO+...
     &      +  0.440 * RKI( 232 ) * YC( RCO3    )   ! HO2+RCO3=0.44*HO+...
     &      +  0.150 * RKI( 233 ) * YC( ACTP    )   ! HO2+ACTP=0.15*HO+...

      R4_5  = R4_5 * DTC

c..Production of HO from HONO (r4,19 terms )
      R4_19 =           RKI(   7 )                   ! HONO=HO+NO

      R4_19 = R4_19 * DTC

c..Remaining HO production
      P4 =   2.000 * RXRAT(   3 )      ! H2O2=2*HO
     &    +          RXRAT(   8 )      ! HNO3=HO+NO2
     &    +  0.200 * RXRAT(   9 )      ! HNO4=0.2*HO+0.8*HO2+...
     &    +  0.340 * RXRAT(  19 )      ! MACR=0.34*HO+0.66*HO2+...
     &    +          RXRAT(  28 )      ! OP1=HO+HO2+HCHO
     &    +          RXRAT(  29 )      ! OP2=HO+HO2+ALD
     &    +          RXRAT(  30 )      ! PAA=HO+MO2
     &    +  OH_S  * RXRAT(   2 )      ! O1D=2*HO
     &    +  0.080 * RXRAT( 126 )      ! ETE+O3=0.08*HO+0.15*HO2+...
     &    +  0.220 * RXRAT( 127 )      ! OLT+O3=0.22*HO+0.32*HO2+...
     &    +  0.460 * RXRAT( 128 )      ! OLI+O3=0.46*HO+0.07*HO2+...
     &    +  0.280 * RXRAT( 129 )      ! DIEN+O3=0.28*HO+0.3*HO2+...
     &    +  0.250 * RXRAT( 130 )      ! ISO+O3=0.25*HO+0.25*HO2+...
     &    +  0.850 * RXRAT( 131 )      ! API+O3=0.85*HO+0.1*HO2+...
     &    +  0.850 * RXRAT( 132 )      ! LIM+O3=0.85*HO+0.1*HO2+...
     &    +  0.190 * RXRAT( 133 )      ! MACR+O3=0.19*HO+0.14*HO2+...
     &    +  0.160 * RXRAT( 134 )      ! MVK+O3=0.16*HO+0.11*HO2+...
     &    +  0.100 * RXRAT( 135 )      ! UALD+O3=0.1*HO+0.072*HO2+...
     &    +  0.050 * RXRAT( 136 )      ! DCB1+O3=0.05*HO+HO2+...
     &    +  0.050 * RXRAT( 137 )      ! DCB2+O3=0.05*HO+HO2+...
     &    +  0.050 * RXRAT( 138 )      ! DCB3+O3=0.05*HO+HO2+1.5*CO+...
     &    +  0.050 * RXRAT( 139 )      ! EPX+O3=0.05*HO+1.5*HO2+...
     &    +  0.500 * RXRAT( 157 )      ! EPX+NO3=0.5*HO+1.5*HO2+...
     &    +  0.280 * RXRAT( 160 )      ! TR2=0.28*HO+0.29*HO2+...
     &    +  0.490 * RXRAT( 161 )      ! TOLP=0.49*HO+0.01*HO2+...
     &    +  0.158 * RXRAT( 162 )      ! XY2=0.158*HO+0.308*HO2+...
     &    +  0.390 * RXRAT( 163 )      ! XYLP=0.39*HO+0.01*HO2+...
     &    +  0.158 * RXRAT( 164 )      ! XYO2=0.158*HO+0.308*HO2+...
     &    +  0.390 * RXRAT( 165 )      ! XYOP=0.39*HO+0.01*HO2+...

      P4 = YC0( HO ) + P4 * DTC

c..Production of HO2 from OH ( r5,4 terms )
      R5_4 =           RKI(  34 ) * YC( O3      )   ! HO+O3=HO2
     &      +          RKI(  43 )                   ! HO=HO2
     &      +          RKI(  47 ) * YC( H2O2    )   ! HO+H2O2=HO2
     &      +          RKI(  58 ) * YC( NO3     )   ! HO+NO3=HO2+NO2
     &      +          RKI(  69 ) * YC( SO2     )   ! HO+SO2=HO2+SULF+...
     &      +          RKI(  70 ) * YC( CO      )   ! HO+CO=HO2
     &      +  0.049 * RKI(  75 ) * YC( HC8     )   ! HO+HC8=0.049*HO2+...
     &      +  0.350 * RKI(  80 ) * YC( ACE     )   ! HO+ACE=0.35*HO2+...
     &      +  0.648 * RKI(  81 ) * YC( BENZENE )   ! HO+BENZENE=...
     &      +  0.177 * RKI(  82 ) * YC( TOL     )   ! HO+TOL=0.177*HO2+...
     &      +  0.177 * RKI(  83 ) * YC( XYM     )   ! HO+XYM=0.177*HO2+...
     &      +  0.177 * RKI(  84 ) * YC( XYP     )   ! HO+XYP=0.177*HO2+...
     &      +  0.177 * RKI(  85 ) * YC( XYO     )   ! HO+XYO=0.177*HO2+...
     &      +          RKI(  89 ) * YC( HCHO    )   ! HO+HCHO=HO2+CO
     &      +          RKI(  95 ) * YC( HKET    )   ! HO+HKET=HO2+MGLY
     &      +          RKI(  99 ) * YC( GLY     )   ! HO+GLY=HO2+2*CO
     &      +  0.520 * RKI( 101 ) * YC( DCB1    )   ! HO+DCB1=0.52*HO2+...
     &      +  0.520 * RKI( 102 ) * YC( DCB2    )   ! HO+DCB2=0.52*HO2+...
     &      +  0.560 * RKI( 103 ) * YC( DCB3    )   ! HO+DCB3=0.56*HO2+...
     &      +  0.730 * RKI( 105 ) * YC( PHEN    )   ! HO+PHEN=0.73*HO2+...
     &      +  0.730 * RKI( 106 ) * YC( CSL     )   ! HO+CSL=0.73*HO2+...
     &      +          RKI( 107 ) * YC( EPX     )   ! HO+EPX=HO2+XO2+...
     &      +          RKI( 109 ) * YC( MOH     )   ! HO+MOH=HO2+HCHO
     &      +          RKI( 110 ) * YC( EOH     )   ! HO+EOH=HO2+ACD
     &      +          RKI( 111 ) * YC( ROH     )   ! HO+ROH=HO2+...
     &      +          RKI( 112 ) * YC( ETEG    )   ! HO+ETEG=HO2+ALD
     &      +          RKI( 117 ) * YC( ORA1    )   ! HO+ORA1=HO2

      R5_4  = R5_4 * DTC

c..Production of HO2 from HNO4 (r5,21 term )
      R5_21 =   0.800 * RKI(   9 )                   ! HNO4=0.8*HO2+...
     &       +          RKI(  67 )                   ! HNO4=HO2+NO2

      R5_21 = R5_21 * DTC

c..Remaining HO2 production terms
      P5 =   2.000 * RXRAT(  11 )      ! HCHO=HO2+HO2+CO
     &    +          RXRAT(  12 )      ! ACD=HO2+MO2+CO
     &    +          RXRAT(  13 )      ! ALD=HO2+ETHP+CO
     &    +  1.220 * RXRAT(  15 )      ! UALD=1.22*HO2+0.784*ACO3+...
     &    +          RXRAT(  18 )      ! HKET=HO2+ACO3+HCHO
     &    +  0.660 * RXRAT(  19 )      ! MACR=0.66*HO2+0.34*HO+...
     &    +  2.000 * RXRAT(  23 )      ! GLY=2*HO2+2*CO
     &    +          RXRAT(  24 )      ! MGLY=HO2+ACO3+CO
     &    +  1.500 * RXRAT(  25 )      ! DCB1=1.5*HO2+0.25*ACO3+...
     &    +  1.500 * RXRAT(  26 )      ! DCB2=1.5*HO2+0.25*ACO3+...
     &    +          RXRAT(  27 )      ! BALD=HO2+CHO+CO
     &    +          RXRAT(  28 )      ! OP1=HO2+HO+HCHO
     &    +          RXRAT(  29 )      ! OP2=HO2+HO+ALD
     &    +          RXRAT(  31 )      ! ONIT=HO2+NO2+0.2*ALD+0.8*KET
     &    +  0.150 * RXRAT( 126 )      ! ETE+O3=0.15*HO2+0.08*HO+...
     &    +  0.320 * RXRAT( 127 )      ! OLT+O3=0.32*HO2+0.22*HO+...
     &    +  0.070 * RXRAT( 128 )      ! OLI+O3=0.07*HO2+0.46*HO+...
     &    +  0.300 * RXRAT( 129 )      ! DIEN+O3=0.3*HO2+0.28*HO+...
     &    +  0.250 * RXRAT( 130 )      ! ISO+O3=0.25*HO2+0.25*HO+...
     &    +  0.100 * RXRAT( 131 )      ! API+O3=0.1*HO2+0.85*HO+...
     &    +  0.100 * RXRAT( 132 )      ! LIM+O3=0.1*HO2+0.85*HO+...
     &    +  0.140 * RXRAT( 133 )      ! MACR+O3=0.14*HO2+0.19*HO+...
     &    +  0.110 * RXRAT( 134 )      ! MVK+O3=0.11*HO2+0.16*HO+...
     &    +  0.072 * RXRAT( 135 )      ! UALD+O3=0.072*HO2+0.1*HO+...
     &    +          RXRAT( 136 )      ! DCB1+O3=HO2+0.05*HO+...
     &    +          RXRAT( 137 )      ! DCB2+O3=HO2+0.05*HO+...
     &    +          RXRAT( 138 )      ! DCB3+O3=HO2+0.05*HO+1.5*CO+...
     &    +  1.500 * RXRAT( 139 )      ! EPX+O3=1.5*HO2+0.05*HO+...
     &    +          RXRAT( 148 )      ! HCHO+NO3=HO2+CO+HNO3
     &    +          RXRAT( 152 )      ! UALD+NO3=HO2+XO2+0.668*CO+...
     &    +          RXRAT( 153 )      ! GLY+NO3=HO2+2*CO+HNO3
     &    +  1.500 * RXRAT( 157 )      ! EPX+NO3=1.5*HO2+0.5*HO+...
     &    +  0.290 * RXRAT( 160 )      ! TR2=0.29*HO2+0.28*HO+...
     &    +  0.010 * RXRAT( 161 )      ! TOLP=0.01*HO2+0.49*HO+...
     &    +  0.308 * RXRAT( 162 )      ! XY2=0.308*HO2+0.158*HO+...
     &    +  0.010 * RXRAT( 163 )      ! XYLP=0.01*HO2+0.39*HO+...
     &    +  0.308 * RXRAT( 164 )      ! XYO2=0.308*HO2+0.158*HO+...
     &    +  0.010 * RXRAT( 165 )      ! XYOP=0.01*HO2+0.39*HO+...
     &    +          RXRAT( 172 )      ! MO2+NO=HO2+NO2+HCHO
     &    +          RXRAT( 173 )      ! ETHP+NO=HO2+NO2+ACD
     &    +  0.660 * RXRAT( 174 )      ! HC3P+NO=0.66*HO2+0.131*MO2+...
     &    +  0.200 * RXRAT( 175 )      ! HC5P+NO=0.2*HO2+0.051*MO2+...
     &    +  0.606 * RXRAT( 176 )      ! HC8P+NO=0.606*HO2+...
     &    +          RXRAT( 177 )      ! ETEP+NO=HO2+NO2+1.6*HCHO+...
     &    +  0.780 * RXRAT( 178 )      ! OLTP+NO=0.78*HO2+0.97*NO2+...
     &    +  0.830 * RXRAT( 179 )      ! OLIP+NO=0.83*HO2+0.95*NO2+...
     &    +  0.918 * RXRAT( 180 )      ! BENP+NO=0.918*HO2+...
     &    +  0.950 * RXRAT( 182 )      ! TOLP+NO=0.95*HO2+0.95*NO2+...
     &    +  0.500 * RXRAT( 183 )      ! PER1+NO=0.5*HO2+0.95*NO2+...
     &    +  0.950 * RXRAT( 185 )      ! XYLP+NO=0.95*HO2+0.95*NO2+...
     &    +  0.950 * RXRAT( 186 )      ! PER2+NO=0.95*HO2+0.95*NO2+...
     &    +  0.950 * RXRAT( 187 )      ! XYOP+NO=0.95*HO2+0.95*NO2+...
     &    +  0.880 * RXRAT( 188 )      ! ISOP+NO=0.88*HO2+0.88*NO2+...
     &    +  0.820 * RXRAT( 189 )      ! APIP+NO=0.82*HO2+0.82*NO2+...
     &    +          RXRAT( 190 )      ! LIMP+NO=HO2+0.68*UALD+...
     &    +  0.670 * RXRAT( 194 )      ! MEKP+NO=0.67*HO2+NO2+...
     &    +  0.770 * RXRAT( 195 )      ! KETP+NO=0.77*HO2+0.23*ACO3+...
     &    +  0.500 * RXRAT( 197 )      ! MCP+NO=0.5*HO2+NO2+...
     &    +  0.300 * RXRAT( 198 )      ! MVKP+NO=0.3*HO2+0.7*ACO3+...
     &    +          RXRAT( 199 )      ! UALP+NO=HO2+NO2+0.61*CO+...
     &    +          RXRAT( 202 )      ! ADDC+NO=HO2+NO2+0.32*HKET+...
     &    +          RXRAT( 204 )      ! ORAP+NO=HO2+GLY+NO2
     &    +          RXRAT( 205 )      ! OLNN+NO=HO2+NO2+ONIT
     &    +  0.740 * RXRAT( 248 )      ! MO2+MO2=0.74*HO2+1.37*HCHO+...
     &    +          RXRAT( 249 )      ! ETHP+MO2=HO2+0.75*HCHO+...
     &    +  0.894 * RXRAT( 250 )      ! HC3P+MO2=0.894*HO2+...
     &    +  0.842 * RXRAT( 251 )      ! HC5P+MO2=0.842*HO2+...
     &    +  0.910 * RXRAT( 252 )      ! HC8P+MO2=0.91*HO2+...
     &    +          RXRAT( 253 )      ! ETEP+MO2=HO2+1.95*HCHO+...
     &    +          RXRAT( 254 )      ! OLTP+MO2=HO2+1.5*HCHO+...
     &    +          RXRAT( 255 )      ! OLIP+MO2=HO2+0.75*HCHO+...
     &    +  1.600 * RXRAT( 256 )      ! BENP+MO2=1.6*HO2+...
     &    +          RXRAT( 257 )      ! TLP1+MO2=HO2+HCHO+BALD
     &    +  2.000 * RXRAT( 258 )      ! TOLP+MO2=2*HO2+HCHO+...
     &    +  2.000 * RXRAT( 259 )      ! PER1+MO2=2*HO2+HCHO+MGLY+DCB1
     &    +          RXRAT( 260 )      ! XYL1+MO2=HO2+HCHO+BALD
     &    +  2.000 * RXRAT( 261 )      ! XYLP+MO2=2*HO2+HCHO+DCB2
     &    +  2.000 * RXRAT( 262 )      ! PER2+MO2=2*HO2+HCHO+MGLY+...
     &    +  2.000 * RXRAT( 263 )      ! XYOP+MO2=2*HO2+HCHO+...
     &    +          RXRAT( 264 )      ! ISOP+MO2=HO2+1.31*HCHO+...
     &    +          RXRAT( 265 )      ! APIP+MO2=HO2+0.75*HCHO+...
     &    +          RXRAT( 266 )      ! LIMP+MO2=HO2+1.04*HCHO+...
     &    +  0.900 * RXRAT( 267 )      ! ACO3+MO2=0.9*HO2+0.9*MO2+...
     &    +  0.900 * RXRAT( 268 )      ! RCO3+MO2=0.9*HO2+0.9*MO2+...
     &    +  0.500 * RXRAT( 269 )      ! ACTP+MO2=0.5*HO2+0.5*ACO3+...
     &    +  0.834 * RXRAT( 270 )      ! MEKP+MO2=0.834*HO2+HCHO+...
     &    +          RXRAT( 271 )      ! KETP+MO2=HO2+0.75*HCHO+...
     &    +  0.500 * RXRAT( 272 )      ! MACP+MO2=0.5*HO2+...
     &    +          RXRAT( 273 )      ! MCP+MO2=HO2+NO2+1.5*HCHO+...
     &    +          RXRAT( 274 )      ! MVKP+MO2=HO2+1.16*ACO3+...
     &    +          RXRAT( 275 )      ! UALP+MO2=HO2+0.305*CO+...
     &    +          RXRAT( 276 )      ! BALP+MO2=HO2+BAL1+HCHO
     &    +          RXRAT( 277 )      ! BAL1+MO2=HO2+BAL2+HCHO
     &    +  2.000 * RXRAT( 278 )      ! ADDC+MO2=2*HO2+HCHO+...
     &    +          RXRAT( 279 )      ! MCTP+MO2=HO2+MCTO+HCHO
     &    +          RXRAT( 280 )      ! ORAP+MO2=HO2+HCHO+GLY
     &    +  2.000 * RXRAT( 281 )      ! OLNN+MO2=2*HO2+HCHO+ONIT
     &    +  0.500 * RXRAT( 282 )      ! OLND+MO2=0.5*HO2+0.5*NO2+...
     &    +          RXRAT( 283 )      ! ADCN+MO2=HO2+0.7*NO2+HCHO+...
     &    +          RXRAT( 284 )      ! XO2+MO2=HO2+HCHO
     &    +  0.500 * RXRAT( 285 )      ! ETHP+ACO3=0.5*HO2+0.5*MO2+...
     &    +  0.394 * RXRAT( 286 )      ! HC3P+ACO3=0.394*HO2+...
     &    +  0.342 * RXRAT( 287 )      ! HC5P+ACO3=0.342*HO2+...
     &    +  0.303 * RXRAT( 288 )      ! HC8P+ACO3=0.303*HO2+...
     &    +  0.500 * RXRAT( 289 )      ! ETEP+ACO3=0.5*HO2+0.5*MO2+...
     &    +  0.500 * RXRAT( 290 )      ! OLTP+ACO3=0.5*HO2+0.5*MO2+...
     &    +  0.500 * RXRAT( 291 )      ! OLIP+ACO3=0.5*HO2+0.5*MO2+...
     &    +  0.600 * RXRAT( 292 )      ! BENP+ACO3=0.6*HO2+MO2+...
     &    +          RXRAT( 294 )      ! TOLP+ACO3=HO2+MO2+DCB2
     &    +          RXRAT( 295 )      ! PER1+ACO3=HO2+MO2+MGLY+DCB1
     &    +          RXRAT( 297 )      ! XYLP+ACO3=HO2+MO2+DCB2
     &    +          RXRAT( 298 )      ! PER2+ACO3=HO2+MO2+MGLY+...
     &    +          RXRAT( 299 )      ! XYOP+ACO3=HO2+MO2+...
     &    +  0.500 * RXRAT( 300 )      ! ISOP+ACO3=0.5*HO2+0.5*MO2+...
     &    +  0.500 * RXRAT( 301 )      ! APIP+ACO3=0.5*HO2+0.5*MO2+...
     &    +  0.500 * RXRAT( 302 )      ! LIMP+ACO3=0.5*HO2+0.5*MO2+...
     &    +  0.330 * RXRAT( 306 )      ! MEKP+ACO3=0.33*HO2+0.5*MO2+...
     &    +  0.500 * RXRAT( 307 )      ! KETP+ACO3=0.5*HO2+0.5*MO2+...
     &    +  0.500 * RXRAT( 309 )      ! MCP+ACO3=0.5*HO2+NO2+HCHO+...
     &    +  0.500 * RXRAT( 310 )      ! MVKP+ACO3=0.5*HO2+0.5*MO2+...
     &    +  0.500 * RXRAT( 311 )      ! UALP+ACO3=0.5*HO2+0.5*MO2+...
     &    +  2.000 * RXRAT( 314 )      ! ADDC+ACO3=2*HO2+MO2+...
     &    +          RXRAT( 315 )      ! MCTP+ACO3=HO2+MO2+MCTO
     &    +          RXRAT( 317 )      ! OLNN+ACO3=HO2+MO2+ONIT
     &    +          RXRAT( 319 )      ! ADCN+ACO3=HO2+MO2+0.7*NO2+...
     &    +          RXRAT( 322 )      ! MO2+NO3=HO2+HCHO+NO2
     &    +          RXRAT( 323 )      ! ETHP+NO3=HO2+NO2+ACD
     &    +  0.254 * RXRAT( 324 )      ! HC3P+NO3=0.254*HO2+...
     &    +  0.488 * RXRAT( 325 )      ! HC5P+NO3=0.488*HO2+...
     &    +  0.820 * RXRAT( 326 )      ! HC8P+NO3=0.82*HO2+...
     &    +          RXRAT( 327 )      ! ETEP+NO3=HO2+NO2+1.6*HCHO+...
     &    +  0.790 * RXRAT( 328 )      ! OLTP+NO3=0.79*HO2+...
     &    +  0.860 * RXRAT( 329 )      ! OLIP+NO3=0.86*HO2+0.72*ALD+...
     &    +          RXRAT( 330 )      ! BENP+NO3=HO2+NO2+0.5*DCB2+...
     &    +          RXRAT( 332 )      ! TOLP+NO3=HO2+NO2+DCB2
     &    +  0.500 * RXRAT( 333 )      ! PER1+NO3=0.5*HO2+NO2+...
     &    +          RXRAT( 335 )      ! XYLP+NO3=HO2+NO2+DCB3
     &    +          RXRAT( 336 )      ! PER2+NO3=HO2+NO2+MGLY+DCB1+...
     &    +          RXRAT( 337 )      ! XYOP+NO3=HO2+NO2+0.368*GLY+...
     &    +          RXRAT( 338 )      ! ISOP+NO3=HO2+NO2+0.75*HCHO+...
     &    +          RXRAT( 339 )      ! APIP+NO3=HO2+NO2+ALD+KET
     &    +          RXRAT( 340 )      ! LIMP+NO3=HO2+NO2+0.385*OLI+...
     &    +  0.670 * RXRAT( 344 )      ! MEKP+NO3=0.67*HO2+NO2+...
     &    +          RXRAT( 345 )      ! KETP+NO3=HO2+NO2+DCB1
     &    +          RXRAT( 347 )      ! MCP+NO3=HO2+NO2+HCHO+HKET
     &    +  0.300 * RXRAT( 348 )      ! MVKP+NO3=0.3*HO2+0.7*ACO3+...
     &    +          RXRAT( 349 )      ! UALP+NO3=HO2+NO2+0.61*CO+...
     &    +          RXRAT( 352 )      ! ADDC+NO3=HO2+NO2+0.32*HKET+...
     &    +          RXRAT( 354 )      ! ORAP+NO3=HO2+GLY+NO2
     &    +          RXRAT( 355 )      ! OLNN+NO3=HO2+NO2+ONIT
     &    +          RXRAT( 358 )      ! OLNN+OLNN=HO2+2*ONIT
     &    +  0.500 * RXRAT( 359 )      ! OLNN+OLND=0.5*HO2+0.5*NO2+...

      P5 = YC0( HO2 ) + P5 * DTC

c..Production of HONO from OH (r19,4 terms )

      R19_4 =   RKI(  49 ) * YC( NO      ) * DTC      ! OH+NO=HONO

c..Remaining HONO production terms
      P19   = YC0( HONO )

c..Production of HNO4 from HO2 (r21,5 term )

      R21_5 =   RKI(  66 ) * YC( NO2     ) * DTC      ! HO2+NO2=HNO4

c..Remaining HNO4 production terms
      P21   =   YC0( HNO4 )

c..HO loss terms not in R5_4 & R19_4
      L4 =           RKI(  44 ) * YC( HO2     )   ! HO+HO2=
     &    +          RKI(  53 ) * YC( HONO    )   ! HO+HONO=NO2
     &    +          RKI(  56 ) * YC( NO2     )   ! HO+NO2=HNO3
     &    +          RKI(  57 ) * YC( HNO3    )   ! HO+HNO3=NO3
     &    +          RKI(  68 ) * YC( HNO4    )   ! HO+HNO4=NO2
     &    +          RKI(  71 )                   ! HO=MO2
     &    +          RKI(  72 ) * YC( ETH     )   ! HO+ETH=ETHP
     &    +          RKI(  73 ) * YC( HC3     )   ! HO+HC3=HC3P
     &    +          RKI(  74 ) * YC( HC5     )   ! HO+HC5=HC5P
     &    +  0.951 * RKI(  75 ) * YC( HC8     )   ! HO+HC8=0.049*HO2+...
     &    +          RKI(  76 ) * YC( ETE     )   ! HO+ETE=ETEP
     &    +          RKI(  77 ) * YC( OLT     )   ! HO+OLT=OLTP
     &    +          RKI(  78 ) * YC( OLI     )   ! HO+OLI=OLIP
     &    +          RKI(  79 ) * YC( DIEN    )   ! HO+DIEN=OLIP
     &    +  0.352 * RKI(  81 ) * YC( BENZENE )   ! HO+BENZENE=...
     &    +  0.823 * RKI(  82 ) * YC( TOL     )   ! HO+TOL=0.177*HO2+...
     &    +  0.823 * RKI(  83 ) * YC( XYM     )   ! HO+XYM=0.177*HO2+...
     &    +  0.823 * RKI(  84 ) * YC( XYP     )   ! HO+XYP=0.177*HO2+...
     &    +  0.823 * RKI(  85 ) * YC( XYO     )   ! HO+XYO=0.177*HO2+...
     &    +          RKI(  86 ) * YC( ISO     )   ! HO+ISO=ISOP+ISOPRXN
     &    +          RKI(  87 ) * YC( API     )   ! HO+API=APIP+TRPRXN
     &    +          RKI(  88 ) * YC( LIM     )   ! HO+LIM=LIMP+TRPRXN
     &    +          RKI(  90 ) * YC( ACD     )   ! HO+ACD=ACO3
     &    +          RKI(  91 ) * YC( ALD     )   ! HO+ALD=RCO3
     &    +          RKI(  92 ) * YC( ACT     )   ! HO+ACT=ACTP
     &    +          RKI(  93 ) * YC( MEK     )   ! HO+MEK=MEKP
     &    +          RKI(  94 ) * YC( KET     )   ! HO+KET=KETP
     &    +          RKI(  96 ) * YC( MACR    )   ! HO+MACR=...
     &    +          RKI(  97 ) * YC( MVK     )   ! HO+MVK=MVKP
     &    +          RKI(  98 ) * YC( UALD    )   ! HO+UALD=...
     &    +          RKI( 100 ) * YC( MGLY    )   ! HO+MGLY=ACO3+CO
     &    +  0.480 * RKI( 101 ) * YC( DCB1    )   ! HO+DCB1=0.52*HO2+...
     &    +  0.480 * RKI( 102 ) * YC( DCB2    )   ! HO+DCB2=0.52*HO2+...
     &    +  0.440 * RKI( 103 ) * YC( DCB3    )   ! HO+DCB3=0.56*HO2+...
     &    +          RKI( 104 ) * YC( BALD    )   ! HO+BALD=BALP
     &    +  0.270 * RKI( 105 ) * YC( PHEN    )   ! HO+PHEN=0.73*HO2+...
     &    +  0.270 * RKI( 106 ) * YC( CSL     )   ! HO+CSL=0.73*HO2+...
     &    +          RKI( 108 ) * YC( MCT     )   ! HO+MCT=MCTO
     &    +  0.650 * RKI( 113 ) * YC( OP1     )   ! HO+OP1=0.35*HO+...
     &    +  0.990 * RKI( 114 ) * YC( OP2     )   ! HO+OP2=0.01*HO+...
     &    +          RKI( 116 ) * YC( MAHP    )   ! HO+MAHP=MACP
     &    +          RKI( 118 ) * YC( ORA2    )   ! HO+ORA2=0.64*MO2+...
     &    +  0.650 * RKI( 119 ) * YC( PAA     )   ! HO+PAA=0.35*HO+...
     &    +          RKI( 120 ) * YC( PAN     )   ! HO+PAN=XO2+NO3+HCHO
     &    +          RKI( 121 ) * YC( PPN     )   ! HO+PPN=XO2+NO3+HCHO
     &    +          RKI( 122 ) * YC( MPAN    )   ! HO+MPAN=NO2+HKET
     &    +          RKI( 123 ) * YC( ONIT    )   ! HO+ONIT=HC3P+NO2
     &    +          RKI( 124 ) * YC( NALD    )   ! HO+NALD=NO2+XO2+HKET
     &    +          RKI( 125 ) * YC( ISON    )   ! HO+ISON=NALD+...

      L4    = 1.0 + L4 * DTC + R5_4 + R19_4

c..HO2 loss terms not included in R4_5 & R21_5 (except for HO2+HO2 )
      L5 =           RKI(  44 ) * YC( HO      )   ! HO2+HO=
     &    +          RKI(  51 ) * YC( NO      )   ! HO2+NO=HNO3
     &    +  0.300 * RKI(  59 ) * YC( NO3     )   ! HO2+NO3=0.7*HO+...
     &    +          RKI( 212 ) * YC( MO2     )   ! HO2+MO2=OP1
     &    +          RKI( 213 ) * YC( ETHP    )   ! HO2+ETHP=OP2
     &    +          RKI( 214 ) * YC( HC3P    )   ! HO2+HC3P=OP2
     &    +          RKI( 215 ) * YC( HC5P    )   ! HO2+HC5P=OP2
     &    +          RKI( 216 ) * YC( HC8P    )   ! HO2+HC8P=OP2
     &    +          RKI( 217 ) * YC( ETEP    )   ! HO2+ETEP=OP2
     &    +          RKI( 218 ) * YC( OLTP    )   ! HO2+OLTP=OP2
     &    +          RKI( 219 ) * YC( OLIP    )   ! HO2+OLIP=OP2
     &    +          RKI( 220 ) * YC( BENP    )   ! HO2+BENP=OP2
     &    +          RKI( 221 ) * YC( TLP1    )   ! HO2+TLP1=OP2
     &    +          RKI( 222 ) * YC( TOLP    )   ! HO2+TOLP=OP2
     &    +          RKI( 223 ) * YC( PER1    )   ! HO2+PER1=OP2
     &    +          RKI( 224 ) * YC( XYL1    )   ! HO2+XYL1=OP2
     &    +          RKI( 225 ) * YC( XYLP    )   ! HO2+XYLP=OP2
     &    +          RKI( 226 ) * YC( PER2    )   ! HO2+PER2=OP2
     &    +          RKI( 227 ) * YC( XYOP    )   ! HO2+XYOP=OP2
     &    +          RKI( 228 ) * YC( ISOP    )   ! HO2+ISOP=ISHP
     &    +          RKI( 229 ) * YC( APIP    )   ! HO2+APIP=OP2
     &    +          RKI( 230 ) * YC( LIMP    )   ! HO2+LIMP=OP2
     &    +  0.560 * RKI( 231 ) * YC( ACO3    )   ! HO2+ACO3=0.44*HO+...
     &    +  0.560 * RKI( 232 ) * YC( RCO3    )   ! HO2+RCO3=0.44*HO+...
     &    +  0.850 * RKI( 233 ) * YC( ACTP    )   ! HO2+ACTP=0.15*HO+...
     &    +          RKI( 234 ) * YC( MEKP    )   ! HO2+MEKP=OP2
     &    +          RKI( 235 ) * YC( KETP    )   ! HO2+KETP=OP2
     &    +          RKI( 236 ) * YC( MACP    )   ! HO2+MACP=MAHP
     &    +          RKI( 237 ) * YC( MCP     )   ! HO2+MCP=MAHP
     &    +          RKI( 238 ) * YC( MVKP    )   ! HO2+MVKP=OP2
     &    +          RKI( 239 ) * YC( UALP    )   ! HO2+UALP=OP2
     &    +          RKI( 240 ) * YC( ADDC    )   ! HO2+ADDC=OP2
     &    +          RKI( 241 ) * YC( CHO     )   ! HO2+CHO=CSL
     &    +          RKI( 242 ) * YC( MCTP    )   ! HO2+MCTP=OP2
     &    +          RKI( 243 ) * YC( ORAP    )   ! HO2+ORAP=OP2
     &    +          RKI( 244 ) * YC( OLNN    )   ! HO2+OLNN=ONIT
     &    +          RKI( 245 ) * YC( OLND    )   ! HO2+OLND=ONIT
     &    +          RKI( 246 ) * YC( ADCN    )   ! HO2+ADCN=OP2
     &    +          RKI( 247 ) * YC( XO2     )   ! HO2+XO2=OP2

      L5    = 1.0 + L5 * DTC + R4_5 + R21_5

c..HONO loss terms not included in R4_19
      L19 =           RKI(  53 ) * YC( HO      )   ! HONO+HO=NO2

      L19   = 1.0 + L19 * DTC + R4_19

c..HNO4 loss terms not inluded in R5_21
      L21 =   0.200 * RKI(   9 )                   ! HNO4=0.8*HO2+...
     &     +          RKI(  68 ) * YC( HO      )   ! HNO4+HO=NO2

      L21   = 1.0 + L21 * DTC + R5_21

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Solution section
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

c..compute terms used to calculate a,b & c
      L21_INV = 1.0 / L21
      T1 = 1.0 / ( L4 * L19 - R4_19 * R19_4 )
      T2 = R5_4 * T1
      T3 = R5_21 * L21_INV

c..solve quadratic equation for HO2
      A = 2.0 * ( RKI(  45 ) + RKI(  46 ) ) * DTC

      B = L5 - T3 * R21_5 - T2 * R4_5 * L19

      C = P5 + T3 * P21 + T2 * ( P4 * L19 + P19 * R4_19 )

      Q = -0.5 * ( B + SIGN( 1.0, B ) * SQRT( B * B + 4.0 * A * C ) )

      YCP( HO2 ) = MAX( Q / A , -C / Q  )

c..compute remaining species concentrations
      YCP( HO ) = ( ( P4 + R4_5 * YCP( HO2 ) ) * L19 + R4_19 * P19 ) * T1

      YCP( HNO4 ) = ( P21 + R21_5 * YCP( HO2 ) ) * L21_INV

      YCP( HONO ) = ( P19 + R19_4 * YCP( HO ) ) / L19

      RETURN

      END


