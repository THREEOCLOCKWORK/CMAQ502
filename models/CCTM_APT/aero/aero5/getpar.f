
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
C $Header: /project/yoj/arc/CCTM/src/aero/aero5/getpar.f,v 1.7 2012/01/19 13:13:27 yoj Exp $

C:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
      Subroutine getpar( m3_wet_flag, limit_sg  )

C  Calculates the 3rd moments (M3), masses, aerosol densities, and
C  geometric mean diameters (Dg) of all 3 modes, and the natural logs of
C  geometric standard deviations (Sg) of the Aitken and accumulation modes.

C  The input logical variable, M3_WET_FLAG, dictates whether the
C  calculations in GETPAR are to assume that the aerosol is "wet" or
C  "dry."  In the present context, a "wet" aerosol consists of all
C  chemical components of the aerosol.  A "dry" aerosol excludes
C  particle-bound water and also excludes secondary organic aerosol.

C  NOTE! 2nd moment concentrations (M2) are passed into GETPAR in the
C  CBLK array and are modified within GETPAR only in the event that
C  the Sg value of a given mode has gone outside of the acceptable
C  range (1.05 to 2.50).  The GETPAR calculations implicitly assume
C  that the input value of M2 is consistent with the input value of
C  M3_WET_FLAG.  If, for example, the input M2 value was calculated
C  for a "dry" aerosol and the M3_WET_FLAG is .TRUE., GETPAR would
C  incorrectly adjust the M2 concentrations!

C
C SH  03/10/11 Renamed met_data to aeromet_data
C-----------------------------------------------------------------------

      Use aero_data
      Use aeromet_data   ! Includes CONST.EXT

      Implicit None

C Arguments:
      Logical, Intent( In ) :: m3_wet_flag ! true = include H2O and SOA in 3rd moment
                                           ! false = exclude H2O and SOA from 3rd moment

      Logical, Intent( In ) :: limit_sg  ! fix coarse and accum Sg's to the input value?

C Output variables:
C  updates arrays in aero_data module
C  moment3_conc   3rd moment concentration [ ug /m**3 ]
C  aeromode_mass  mass concentration: [ ug / m**3 ]
C  aeromode_dens  avg particle density [ kg / m**3 ]
C  aeromode_diam  geometric mean diameter [ m ]
C  aeromode_sdev  log of geometric standard deviation

C Local Variables:
      Real( 8 ) :: xxm0        ! temporary storage of moment 0 conc's
      Real( 8 ) :: xxm2        ! temporary storage of moment 2 conc's
      Real( 8 ) :: xxm3        ! temporary storage of moment 3 conc's
      Real( 8 ) :: xfsum       ! (ln(M0)+2ln(M3))/3; used in Sg calcs
      Real( 8 ) :: lxfm2       ! ln(M2); used in Sg calcs
      Real( 8 ) :: l2sg        ! square of ln(Sg); used in diameter calcs
      Real      :: es36        ! exp(4.5*l2sg); used in diameter calcs
      Real      :: m3augm      ! temp variable for wet 3rd moment calcs

      Real( 8 ), Parameter :: one3d = 1.0D0 / 3.0D0
      Real( 8 ), Parameter :: two3d = 2.0D0 / 3.0D0

      Real,      Parameter :: one3  = 1.0 / 3.0
      Real,      Parameter :: dgmin = 1.0E-09   ! minimum particle diameter [ m ]
      Real,      Parameter :: densmin = 1.0E03  ! minimum particle density [ kg/m**3 ]

      Real( 8 ) :: minl2sg( n_mode )   ! min value of ln(sg)**2 for each mode
      Real( 8 ) :: maxl2sg( n_mode )   ! max value of ln(sg)**2 for each mode

      Real      :: factor
      Real( 8 ) :: sumM3
      Real( 8 ) :: sumMass
      Integer   :: n, spc   ! loop counters

C-----------------------------------------------------------------------

C *** Set bounds for ln(Sg)**2

      Do n = 1 , n_mode
         If ( limit_sg ) Then
            minl2sg( n ) = aeromode_sdev( n ) ** 2
            maxl2sg( n ) = aeromode_sdev( n ) ** 2
         Else
            minl2sg( n ) = Log( min_sigma_g ) ** 2
            maxl2sg( n ) = Log( max_sigma_g ) ** 2
         End If
      End Do

C *** Calculate aerosol 3rd moment concentrations [ m**3 / m**3 ]

      Do n = 1, n_mode
         sumM3 = 0.0
         sumMass = 0.0

         Do spc = 1, n_aerospc
            If ( aerospc( spc )%tracer ) Cycle
            If ( aerospc( spc )%name( n ) .eq. ' ' ) Cycle

            If ( .Not. aerospc( spc )%no_M2Wet .Or. m3_wet_flag ) Then
               factor = 1.0E-9 * f6pi / aerospc( spc )%density
               sumM3  = sumM3 + factor * aerospc_conc( spc,n )
               sumMass = sumMass + aerospc_conc( spc,n )
            End If
         End Do

         moment3_conc( n )  = Max (sumM3, Real( aeromode( n )%min_m3conc, 8 ) )
         aeromode_mass( n ) = sumMass
      End Do

C *** Calculate modal average particle densities [ kg/m**3 ]

      Do n = 1, n_mode
        aeromode_dens( n ) = Max( densmin,
     &                            1.0E-9 * f6pi * aeromode_mass( n ) / moment3_conc( n ) )
      End Do

C *** Calculate geometric standard deviations as follows:
c        ln^2(Sg) = 1/3*ln(M0) + 2/3*ln(M3) - ln(M2)
c     NOTES:
c      1. Equation 10-5a of [Binkowski:1999] and Equation 5a of
c         Binkowski&Roselle(2003) contain typographical errors.
c      2. If the square of the logarithm of the geometric standard
c         deviation is out of an acceptable range, reset this value and
c         adjust the second moments to be consistent with this value.
c         In this manner, M2 is artificially increased when Sg exceeds
c         the maximum limit.  M2 is artificially decreased when Sg falls
c         below the minimum limit.

C *** Aitken Mode:

      Do n = 1, n_mode
         xxm0 = moment0_conc( n )
         xxm2 = moment2_conc( n )
         xxm3 = moment3_conc( n )

         xfsum = one3d * Log( xxm0 ) + two3d * Log( xxm3 )

         lxfm2 = Log( xxm2 )
         l2sg = xfsum - lxfm2

         l2sg = Max( l2sg, minl2sg( n ) )
         l2sg = Min( l2sg, maxl2sg( n ) )

         lxfm2 = xfsum - l2sg
         moment2_conc( n )  = Exp ( lxfm2 )
         aeromode_sdev( n ) = Sqrt( l2sg )

         ES36 = Exp( 4.5 * l2sg )
         aeromode_diam( n ) = Max( dgmin, ( moment3_conc( n )
     &                      / ( moment0_conc( n ) * es36 ) ) ** one3 )

      End Do

      Return
      End Subroutine getpar

