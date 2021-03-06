
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
C $Header: /project/work/rep/arc/CCTM/src/depv/m3dry/MOSAIC_MOD.F,v 1.6 2012/03/28 16:11:09 yoj Exp $

c:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
      Module MOSAIC_MOD
      
C Contains the shared variables and subrountes needed estimated the resistances
C from natural and agricultrual lands for NH3 bidirectional flux
 
C Revision History: J. Bash June 16 2011:    Created
C                   J. Young Oct 31 2011:    changed lai0, laimn0, rsmin, veg0, vegmn0,
C                                             z00, & luf_fac to pointers to save memory
C                   D. Schwede Mar 12 2012:  fixed errors in crop lai
C                   D. Schwede Sept 07 2012: updated code for NLCD40 land use classification

      Implicit None
      
C shared variables 
!     Integer, Save :: n_lufrac
      Real, Save, Allocatable :: hcanj   (:)   ! Canopy height for LU j
      Real, Save, Allocatable :: lufraccr(:)   ! Column Row LU fraction
      Real, Save, Allocatable :: laijcr  (:)   ! Column Row LAI for LU j      
      Real, Save, Allocatable :: vegjcr  (:)   !
      Real, Save, Allocatable :: z0jcr   (:)   ! Column Row z0 for LU j      
      Real, Save, Allocatable :: rbcj    (:)   ! Colum Row boundary layer resist for LU j      

      Real, Save, Pointer     :: lai0_p    (:)   ! Met model LAI for LU j (MOSAIC)
      Real, Save, Pointer     :: laimn0_p  (:)   ! Met model min LAI for LU j (MOSAIC)
      Real, Save, Pointer     :: rsmin_p   (:)   ! Min Rs for LU j (m3dry & MOSAIC)
      Real, Save, Pointer     :: veg0_p    (:)   ! (MOSAIC)
      Real, Save, Pointer     :: vegmn0_p  (:)   ! (MOSAIC)
      Real, Save, Pointer     :: z00_p     (:)   ! Met model z0 for LU j (MOSAIC)
      Real, Save, Pointer     :: luf_fac_p (:)   ! Leaf emission pot. (NH3 bidi & MOSAIC)

      Real, Save, Allocatable :: rgndcj     ( :,:,: )  ! Rgnd for LU j
      Real, Save, Allocatable :: rincj      ( :,:,: )  ! Rinc for LU j      
      Real, Save, Allocatable :: deltaj     ( :,:,: )  ! Surface wetness for LU j 
      Real, Save, Allocatable :: ustarj     ( :,:,: )  ! u* for LU j  
      Real, Save, Allocatable :: raj        ( :,:,: )  ! aerodynamic resistance for LU j  
      Real, Save, Allocatable :: laij       ( :,:,: )  ! LAI for LU j 
      Real, Save, Allocatable :: vegj       ( :,:,: )  ! veg for LU j 
      Real, Save, Allocatable :: z0j        ( :,:,: )  ! z0 for LU j 
      Real, Save, Allocatable :: rstomj     ( :,:,:,: )
      Real, Save, Allocatable :: rcanj      ( :,:,:,: )! stomatal, mesiphyll and cuticular resistances only
      Real, Save, Allocatable :: rsurfj     ( :,:,:,: )! Rsurf for LU j        
      Real, Save, Allocatable :: depvel_gasj( :,:,:,: ) ! deposition velocity by land use type
      Real, Save, Allocatable :: vd_fst_gasj( :,:,:,: ) ! deposition velocity for stomatal and
      Real, Save, Allocatable :: adepvj     ( :,:,:,: ) ! deposition velocity for stomatal and
      
!     Character( 80 ), Save   :: LAND_SCHEME 

C Private variables used in this module and subroutines       
      Integer, Save, Private  :: logdev 
      
      Contains

         Subroutine Init_Mosaic( jdate, jtime, ltotg, MOSAIC, ABFLUX )
       
         Use HGRD_DEFN
         Use LSM_Mod
         Use UTILIO_DEFN
       
         Implicit None    

C...include files

         Include SUBST_FILES_ID   ! file name parameters                 
       
         Integer, Intent( In )  :: jdate
         Integer, Intent( In )  :: jtime  
         Integer, Intent( In )  :: ltotg 
         Logical, Intent( In )  :: MOSAIC         
         Logical, Intent( In )  :: ABFLUX         
         Character( 240 )       :: xmsg = ' '
         Character(  16 ), save :: pname = 'Init_Mosaic'
         Integer l
         Integer gxoff, gyoff            ! global origin offset from file
         Integer :: strtcolgc2, endcolgc2, strtrowgc2, endrowgc2
                                                                                   
       
!        LAND_SCHEME = 'UNKNOWN'
!        CALL SUBHFILE ( GRID_CRO_2D, GXOFF, GYOFF,
!     &                  STRTCOLGC2, EndCOLGC2, STRTROWGC2, EndROWGC2 )
       
!        If ( .Not. DESC3( GRID_CRO_2D ) ) Then
!           XMSG = 'COULD NOT GET GRID_CRO_2D FILE DESCRIPTION '
!           CALL M3EXIT ( PNAME, JDATE, JTIME, XMSG, XSTAT2 )
!        End If        
         
!        Do l = 1, NVARS3D ! determine land character
!           If ( VNAME3D( l ) .EQ. 'DLUSE' ) Then
!              If ( INDEX( VDESC3D( l ), 'USGS24' ) .Ne. 0 ) LAND_SCHEME = 'USGS24'
!              If ( INDEX( VDESC3D( l ), 'MODIS' ) .Ne. 0 )  LAND_SCHEME = 'MODIS'
C...overwrite if NLCD-MODIS scheme
!              If ( INDEX( VDESC3D( l ), 'NLCD-MODIS' ) .Ne. 0 ) LAND_SCHEME = 'NLCD-MODIS'
!           End If
!        End Do         
!        Write(Logdev,*) 'Land use scheme is ', TRIM(LAND_SCHEME) 
       
         Select Case( LAND_SCHEME )
            Case( 'USGS24' )
!              n_lufrac = n_usgs            
               rsmin_p   => RSMIN_USGS                         ! array assignment
               lai0_p    => LAI0_USGS                          !  "       "
               laimn0_p  => LAIMN0_USGS                        !  "       "
               veg0_p    => VEG0_USGS                          !  "       "
               vegmn0_p  => VEGMN0_USGS                        !  "       "
               z00_p     => Z00_USGS                           !  "       "
               luf_fac_p => LUF_FAC_USGS                       !  "       "
            Case( 'MODIS' )
!              n_lufrac = n_modis
               rsmin_p   => RSMIN_MODIS                        ! array assignment
               lai0_p    => LAI0_MODIS                         !  "       "
               laimn0_p  => LAIMN0_MODIS                       !  "       "
               veg0_p    => VEG0_MODIS                         !  "       "
               vegmn0_p  => VEGMN0_MODIS                       !  "       "
               z00_p     => Z00_MODIS                          !  "       "
               luf_fac_p => LUF_FAC_MODIS                      !  "       "
            Case( 'NLCD50' )
!              n_lufrac = n_nlcd
               rsmin_p   => RSMIN_NLCD50                       ! array assignment
               lai0_p    => LAI0_NLCD50                        !  "       "
               laimn0_p  => LAIMN0_NLCD50                      !  "       "
               veg0_p    => VEG0_NLCD50                        !  "       "
               vegmn0_p  => VEGMN0_NLCD50                      !  "       "
               z00_p     => Z00_NLCD50                         !  "       "
               luf_fac_p => LUF_FAC_NLCD50                     !  "       "
            Case( 'NLCD40' )
!              n_lufrac = n_nlcd
               rsmin_p   => RSMIN_NLCD40                       ! array assignment
               lai0_p    => LAI0_NLCD40                        !  "       "
               laimn0_p  => LAIMN0_NLCD40                      !  "       "
               veg0_p    => VEG0_NLCD40                        !  "       "
               vegmn0_p  => VEGMN0_NLCD40                      !  "       "
               z00_p     => Z00_NLCD40                         !  "       "
               luf_fac_p => LUF_FAC_NLCD40                     !  "       "
            Case Default
!              Write(Logdev,*) 'Land use scheme is ', LAND_SCHEME
               xmsg = 'Land use scheme not supported'
               CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT2 )
         End Select                                       
         z00_p = z00_p / 100.0 ! convert to meters
       
         If ( .Not. ALLOCATED ( hcanj ) ) Then
            ALLOCATE ( hcanj( n_lufrac ) )
         End If
         
         If ( .Not. ALLOCATED ( lufraccr ) ) Then
            ALLOCATE ( lufraccr( n_lufrac ) )
         End If
         
         If ( .Not. ALLOCATED ( laijcr ) ) Then
            ALLOCATE ( laijcr( n_lufrac ) )
         End If  
         
          If ( .Not. ALLOCATED ( vegjcr ) ) Then
            ALLOCATE ( vegjcr( n_lufrac ) )
         End If           
         
         If ( .Not. ALLOCATED ( z0jcr ) ) Then
            ALLOCATE ( z0jcr( n_lufrac ) )
         End If
         
          If ( .Not. ALLOCATED ( rbcj ) ) Then
            ALLOCATE ( rbcj( n_lufrac ) )
         End If               
         
         If ( .Not. ALLOCATED ( rgndcj ) ) Then
            ALLOCATE ( rgndcj( n_lufrac,my_ncols,my_nrows ) )
         End If

         If ( .Not. ALLOCATED ( rincj ) ) Then
            ALLOCATE ( rincj( n_lufrac,my_ncols,my_nrows ) )
         End If

         If ( .Not. ALLOCATED ( rcanj ) ) Then
            ALLOCATE ( rcanj( n_lufrac,ltotg,my_ncols,my_nrows ) )
         End If
         
         If ( .Not. ALLOCATED ( rstomj ) ) Then
            ALLOCATE ( rstomj( n_lufrac,ltotg,my_ncols,my_nrows ) )
         End If
         
         If ( .Not. ALLOCATED ( rsurfj ) ) Then
            ALLOCATE ( rsurfj( n_lufrac,ltotg,my_ncols,my_nrows ) )
         End If
         
         If ( .Not. ALLOCATED ( deltaj ) ) Then
            ALLOCATE ( deltaj( n_lufrac,my_ncols,my_nrows ) )
         End If          
         
         If ( .Not. ALLOCATED ( ustarj ) ) Then
            ALLOCATE ( ustarj( n_lufrac,my_ncols,my_nrows ) )
         End If
         
         If ( .Not. ALLOCATED ( raj ) ) Then
            ALLOCATE ( raj( n_lufrac,my_ncols,my_nrows ) )
         End If  
         
         If ( .Not. ALLOCATED ( laij ) ) Then
            ALLOCATE ( laij( n_lufrac,my_ncols,my_nrows ) )
         End If
         
         If ( .Not. ALLOCATED ( vegj ) ) Then
            ALLOCATE ( vegj( n_lufrac,my_ncols,my_nrows ) )
         End If
         
         If ( .Not. ALLOCATED ( z0j ) ) Then
            ALLOCATE ( z0j( n_lufrac,my_ncols,my_nrows ) )
         End If  
         
         If ( mosaic .Or. abflux ) Then
            If ( .Not. ALLOCATED ( depvel_gasj ) )
     &         Allocate ( depvel_gasj( n_lufrac,ltotg,my_ncols,my_nrows ) )
         End If                         
         If ( mosaic ) Then
            If ( .Not. ALLOCATED ( vd_fst_gasj ) )
     &         Allocate ( vd_fst_gasj( n_lufrac,ltotg,my_ncols,my_nrows ) )
         End If                         
       
         Return   
          
         End Subroutine Init_Mosaic
       
         Subroutine calc_lai( jday, jtime, soit2, lufrac,
     &                         laig, zruf, laicrj, z0crj, vegcrj, logdev, c, r )

C***********************************************************************
C  Function:
C     Calculate the lai for each LUC in the gridcell
 
C  Preconditions:  none
 
C  Subroutines and Functions Called:  none
 
C  Revision History:
C***********************************************************************

         Use LSM_Mod, Only: n_lufrac, Land_Scheme

         Implicit None

C Arguments:
         Integer, Intent( In )  :: jday
         Integer, Intent( In )  :: jtime     
         Real,    Intent( In )  :: soit2              ! temeperature in 1 m of soil
         Real,    Intent( In )  :: lufrac( n_lufrac ) ! fractional land use
         Real,    Intent( In )  :: laig               ! grid value for LAI
         Real,    Intent( In )  :: zruf               ! grid value for roughness
         Real,    Intent( Out ) :: laicrj( n_lufrac )
         Real,    Intent( Out ) :: vegcrj( n_lufrac )
         Real,    Intent( Out ) :: z0crj ( n_lufrac )
         Integer, Intent( In )  :: logdev
         Integer, Intent( In )  :: c, r               ! column, row for reporting errors

C Local variables:
         Real    :: arg, arg1, argw
         Real    :: correction
         Integer :: idaype
         Real    :: fseas
         Real    :: vseas
         Integer :: j
         Real    :: lai_crop
         Real    :: lai_mos5, lai_mos6, lai_mos45, lai_mos14
         Real    :: new_sum_nat_lai
         Real    :: root1
         Real    :: root2
         Real    :: sig
         Real    :: sum_nat_lai
         Real    :: sum_mos_lai
         Real    :: sum_crop_frac
         Real    :: sum_mos_frac
         Real    :: sum_lai
         Real    :: total_frac
         Real    :: znotc

C initialize
         idaype = 0
         lai_crop = 0.0
         root1 = 0.0
         root2 = 0.0
         sum_nat_lai = 0.0
         sum_mos_lai = 0.0
         sum_crop_frac = 0.0
         sum_mos_frac = 0.0
         total_frac = 0.0
         znotc = 0.0

!         write(logdev,*) 'in calc-lai: land_scheme, n_lufrac ',land_scheme,n_lufrac


C calculate fseas based on deep soil temperature
         If ( soit2 .Le. 290.0 ) Then
            fseas = MAX( 1.0 - 0.015625 * ( 290.0 - soit2 ) ** 2, 0.0 )
         Else
            fseas = 1.0
         End If

C get individual LAIs for LUCs for this date 
         Do j = 1, n_lufrac
            total_frac = total_frac + lufrac( j )
            vegcrj( j ) = ( ( 1.0 - fseas ) * vegmn0_p( j ) + fseas * veg0_p( j ) )/100.
            If ( ( Land_Scheme .EQ. 'USGS24' .And. ( j .Ge. 2 .And. j .LE. 4 ) ) .OR.
     &           ( Land_Scheme .EQ. 'NLCD50' .And. ( j .EQ. 20 .OR. j .EQ. 43  ) ) .OR.
     &           ( Land_Scheme .EQ. 'NLCD40' .And. ( j .EQ. 12 .OR. j .EQ. 38  ) ) .OR.
     &           ( Land_Scheme .EQ. 'MODIS' .And. ( j .EQ. 12 ) ) ) Then
               sum_crop_frac = sum_crop_frac + lufrac( j )
            Else If ( ( Land_Scheme .EQ. 'USGS24' .And. ( j .EQ. 5 .OR. j .EQ. 6 ) ) .OR.
     &                ( Land_Scheme .EQ. 'NLCD50' .And. j .EQ. 45 ).OR.
     &                ( Land_Scheme .EQ. 'NLCD40' .And. j .EQ. 14 ).OR.
     &                ( Land_Scheme .EQ. 'MODIS' .And. ( j .EQ. 14 ) ) ) Then
               sum_mos_frac = sum_mos_frac + lufrac( j )
               sum_mos_lai = sum_mos_lai + lufrac( j ) * ( laimn0_p( j )
     &                     + fseas * ( lai0_p( j ) - laimn0_p( j ) ) )
            Else
               laicrj( j ) = laimn0_p( j ) + fseas * ( lai0_p( j ) - laimn0_p( j ) )
               sum_nat_lai = sum_nat_lai + lufrac( j ) * laicrj( j )
               z0crj( j ) = z00_p( j )
            End If
         End Do

C total frac needs to be non-water
         Select Case(Land_Scheme)
            Case('USGS24')
               If ( lufrac( 16 ) .Gt. 0.10 ) Then
                  total_frac = total_frac - lufrac( 16 )
               Else
                  total_frac = 1.0
               End If
            Case('NLCD50')
               argw = lufrac( 1 ) + lufrac( 31 ) + lufrac( 48 ) + lufrac( 50 )
               If ( argw .Gt. 0.10 ) Then
                  total_frac = total_frac - argw
               Else
                  total_frac = 1.0
               End If
            Case('NLCD40')
               argw = lufrac( 17 ) + lufrac( 21 )
               If ( argw .Gt. 0.10 ) Then
                  total_frac = total_frac - argw
               Else
                  total_frac = 1.0
               End If
            Case('MODIS')
               If ( lufrac( 17 ) .Gt. 0.10 ) Then
                  total_frac = total_frac - lufrac( 16 )
               Else
                  total_frac = 1.0
               End If
         End Select

         If ( ( sum_crop_frac + 0.5 * sum_mos_frac ) .Le. 0.0 ) Then
            lai_crop = 0.5
         Else
            arg1 = total_frac * laig - sum_nat_lai - 0.5 * sum_mos_lai

#ifdef Verbose
            If ( arg1 .Le. 0.0 ) Then
               Write( logdev,* ) ' '
               Write( logdev,'(a, 2i4)' ) 'Sum Natural+Mosaic LAI too big at c,r: ', c, r
               Write( logdev,* ) 'arg1,total_frac,laig             : ', arg1, total_frac, laig
               Write( logdev,* ) 'soit2,fseas                      : ', soit2, fseas
               Write( logdev,* ) 'sum_nat_lai,sum_mos_lai          : ', sum_nat_lai, sum_mos_lai
               Write( logdev,* ) 'sum_crop_frac, sum_mos_frac      : ', sum_crop_frac, sum_mos_frac
               Write( logdev,* ) ' '
            End If
#endif

            lai_crop = arg1 / ( sum_crop_frac + 0.5 * sum_mos_frac )

#ifdef Verbose
            If ( lai_crop .Gt. 3.16 ) Then
               Write( logdev,* ) ' '
               Write( logdev,'(a, 2i4, a, f12.5)' ) 'CROP LAI too big at c,r: ', c, r, ' lai crop = ', lai_crop 
               Write( logdev,* ) 'arg1,total_frac,laig             : ', arg1, total_frac, laig
               Write( logdev,* ) 'soit2,fseas                      : ', soit2, fseas
               Write( logdev,* ) 'sum_nat_lai,sum_mos_lai          : ', sum_nat_lai, sum_mos_lai
               Write( logdev,* ) 'sum_crop_frac, sum_mos_frac      : ', sum_crop_frac, sum_mos_frac
               Write( logdev,* ) ' '
            End If
#endif

C check to see if correction needed
            If ( lai_crop .Lt. 0.5 .OR. lai_crop .Gt. 3.16 ) Then   ! method didn't work - numerical error - use approximation based on fseas

#ifdef Verbose
               Write( logdev,'(a, 2i4, a, f12.5)' ) 'Numerical error in Calc_LAI at c,r: ', c, r, ' - bad lai_crop = ', lai_crop
#endif
               Select Case(Land_Scheme)
                  Case('USGS24')
                     lai_crop = MAX( laimn0_p( 2 ) + fseas * ( 3.16 - laimn0_p( 2 ) ), 0.5 )   ! max lai-crop is really 3.16 not 3.0 as in table
                  Case('NLCD50')  ! since values are the same for LUC 20 and 43 only need one
                     lai_crop = MAX( laimn0_p( 20 ) + fseas * ( 3.16 - laimn0_p( 20 ) ), 0.5 )
                  Case('NLCD40')  ! since values are the same for LUC 12 and 38 only need one
                     lai_crop = MAX( laimn0_p( 38 ) + fseas * ( 3.16 - laimn0_p( 38 ) ), 0.5 )
                  Case('MODIS')
                     lai_crop = MAX( laimn0_p( 12 ) + fseas * ( 3.16 - laimn0_p( 12 ) ), 0.5 )
               End Select
               
#ifdef Verbose
               Write( logdev,'(47x, a, f12.5)' ) 'New lai_crop = ', lai_crop
#endif

               Select Case(Land_Scheme)
                  Case('USGS24')
                     lai_mos5 = 0.5 * ( laimn0_p( 5 ) + fseas * ( lai0_p( 5 ) - laimn0_p( 5 ) ) ) + 0.5 * lai_crop
                     lai_mos6 = 0.5 * ( laimn0_p( 6 ) + fseas * ( lai0_p( 6 ) - laimn0_p( 6 ) ) ) + 0.5 * lai_crop
                     new_sum_nat_lai = total_frac * laig - ( lai_crop * sum_crop_frac + lai_mos5 * lufrac( 5 ) + 
     &                                 lai_mos6 * lufrac( 6 ) )
                  Case('NLCD50')
                     lai_mos45 = 0.5 * ( laimn0_p( 45 ) + fseas * ( lai0_p( 45 ) - laimn0_p( 45 ) ) ) + 0.5 * lai_crop
                     new_sum_nat_lai = total_frac * laig - ( lai_crop * sum_crop_frac + lai_mos45* lufrac( 45 ) )
                  Case('NLCD40')
                     lai_mos14 = 0.5 * ( laimn0_p( 14 ) + fseas * ( lai0_p( 14 ) - laimn0_p( 14 ) ) ) + 0.5 * lai_crop
                     new_sum_nat_lai = total_frac * laig - ( lai_crop * sum_crop_frac + lai_mos14* lufrac( 14 ) )
                  Case('MODIS')
                     lai_mos14 = 0.5 * ( laimn0_p( 14 ) + fseas * ( lai0_p( 14 ) - laimn0_p( 14 ) ) ) + 0.5 * lai_crop
                     new_sum_nat_lai = total_frac * laig - ( lai_crop * sum_crop_frac + lai_mos14 * lufrac( 14 ) )
               End Select
            
               If ( sum_nat_lai .Lt. 0.1 .OR. new_sum_nat_lai .LT. 0.1 ) Then   ! not worth doing a correction
                  correction = 1.0
               Else
                  correction = new_sum_nat_lai / sum_nat_lai
               End If

#ifdef Verbose
               Select Case(Land_Scheme)
                  Case('USGS24')
                     Write( logdev,* ) 'Old lai: ', laicrj( 1 ), laicrj( 7 ), laicrj( 11 ), laicrj( 15 )   
                  Case('NLCD50')
                     Write( logdev,* ) 'Old lai: ', laicrj( 1 ), laicrj( 14 ), laicrj( 9 ), laicrj( 11 )
                  Case('NLCD40')
                     Write( logdev,* ) 'Old lai: ', laicrj( 17 ), laicrj( 10 ), laicrj( 4 ), laicrj( 5 )
                  Case('MODIS')
                     Write( logdev,* ) 'Old lai: ', laicrj( 17 ), laicrj( 10 ), laicrj( 4 ), laicrj( 5 )
               End Select           
               Write( logdev,* ) 'correction = ', correction
#endif

               Select Case(Land_Scheme)
                  Case('USGS24')
                     laijcr( 1 ) = laicrj( 1 ) * correction
                     Do j = 7, 15
                        laijcr( j ) = laicrj( j ) * correction
                     End do
#ifdef Verbose
                     Write( logdev,* ) 'New lai: ', laicrj( 1 ), laicrj( 7 ), laicrj( 11 ), laicrj( 15 )
#endif                     
                  Case('NLCD50')
                     Do j = 2, 19
                        laicrj( j ) = laicrj( j ) * correction
                     End Do
                     Do j = 21, 30
                        laicrj( j ) = laicrj( j ) * correction
                     End Do
                     Do j = 32, 42
                        laicrj( j ) = laicrj( j ) * correction
                     End Do
                     laicrj( 44 ) = laicrj( 44 ) * correction
                     laicrj( 46 ) = laicrj( 46 ) * correction
                     laicrj( 47 ) = laicrj( 47 ) * correction
                  Case('NLCD40')
                     Do j = 1, 11
                        laicrj( j ) = laicrj( j ) * correction
                     End Do
                     laicrj( 13 ) = laicrj( 13 ) * correction
                     Do j = 15, 16
                        laicrj( j ) = laicrj( j ) * correction
                     End Do
                     Do j = 22, 40
                       laicrj( j ) = laicrj( j ) * correction
                     End Do                  
                  Case('MODIS')
                     Do j = 1, 11
                        laicrj( j ) = laicrj( j ) * correction
                     End Do
                     laicrj( 13 ) = laicrj( 13 ) * correction
                     Do j = 15, 16
                        laicrj( j ) = laicrj( j ) * correction
                     End Do
                     Do j = 18, 20
                       laicrj( j ) = laicrj( j ) * correction
                     End Do                  
               End Select            
            End If   ! correction needed

         End If

c estimate vseas
         vseas = (lai_crop-0.5)/2.5
         vseas = min(max(vseas,0.0),1.0)      

C find z0_crop by finding days past emergence
         sig = ( ( lai_crop ) ** ( 1.0 / 1.923 ) ) / 2.273
         arg = 0.0184 * 0.0184 - 4.0 * 1.057e-4 * sig
         root1 = ( 0.0184 + SQRT( arg ) ) / ( 2.0 * 1.057E-4 )
         root2 = ( 0.0184 - SQRT( arg ) ) / ( 2.0 * 1.057E-4 )
C figure out which root to use - PX assumes maturity 87 days after emergence
C which should have been caught by testing lai
         If ( root1 .Gt. 87.0 ) root1 = 0.0
         If ( root2 .Gt. 87.0 ) root2 = 0.0
         idaype = NINT( MAX( root1, root2 ) )
         If ( idaype .Le. 0 .OR. jday .Gt. 288 ) Then
            znotc = 0.05
         Else If ( idaype .Gt. 87 ) Then
            znotc = 0.15
         Else
            znotc = 5.00 + 0.23 * REAL( idaype ) - 1.32E-3 * REAL( idaype * idaype )
            znotc = znotc / 100.0  ! convert to meters
         End If
         
         Select Case(Land_Scheme)
            Case('USGS24')
               Do j = 2, 4
                  laicrj( j ) = lai_crop
                  z0crj( j )  = znotc
                  vegcrj( j ) = ((1.-vseas)*vegmn0_p(j) + vseas*veg0_p(j))/100.0
               End Do

               Do j = 5, 6
                  laicrj( j ) = 0.5 * ( laimn0_p( j ) + fseas * ( lai0_p( j ) - laimn0_p( j ) ) )
     &                        + 0.5 * lai_crop
                  z0crj( j )  = 0.5 * ( znotc + z00_p( j ) )
                  vegcrj( j ) = ( (1.0-vseas) * vegmn0_p(j) + vseas * veg0_p(j) ) / 100.0
               End Do
            Case('NLCD50')
               laicrj( 20 ) = lai_crop
               z0crj ( 20 ) = znotc
               vegcrj( 20 ) = ( (1.0-vseas) * vegmn0_p(20) + vseas * veg0_p(20) ) / 100.0
               laicrj( 43 ) = lai_crop
               z0crj ( 43 ) = znotc
               vegcrj( 43 ) = ( (1.0-vseas) * vegmn0_p(43) + vseas * veg0_p(43) ) / 100.0
               laicrj( 45 ) = 0.5 * ( laimn0_p( 45 ) + fseas * ( lai0_p( 45 ) - laimn0_p( 45 ) ) )
     &                      + 0.5 * lai_crop
               z0crj ( 45 ) = 0.5 * ( znotc + z00_p( 45 ) )
               vegcrj( 45 ) = ( (1.0-vseas) * vegmn0_p(45) + vseas * veg0_p(45) ) / 100.0
            Case('NLCD40')
               laicrj( 12 ) = lai_crop
               z0crj ( 12 ) = znotc
               vegcrj( 12 ) = ( (1.0-vseas) * vegmn0_p(12) + vseas * veg0_p(12) ) / 100.0
               laicrj( 14 ) = 0.5 * ( laimn0_p( 14 ) + fseas * ( lai0_p( 14 ) - laimn0_p( 14 ) ) )
     &                      + 0.5 * lai_crop
               z0crj ( 14 ) = 0.5 * ( znotc + z00_p( 14 ) )
               vegcrj( 14 ) = ( (1.0-vseas) * vegmn0_p(14) + vseas * veg0_p(14) ) / 100.0
               laicrj( 38 ) = lai_crop
               z0crj ( 38 ) = znotc
               vegcrj( 38 ) = ( (1.0-vseas) * vegmn0_p(12) + vseas * veg0_p(12) ) / 100.0
            Case('MODIS')
               laicrj( 12 ) = lai_crop
               z0crj ( 12 ) = znotc
               vegcrj( 12 ) = ( (1.0-vseas) * vegmn0_p(12) + vseas * veg0_p(12) ) / 100.0
               laicrj( 14 ) = 0.5 * ( laimn0_p( 14 ) + fseas * ( lai0_p( 14 ) - laimn0_p( 14 ) ) )
     &                      + 0.5 * lai_crop
               z0crj ( 14 ) = 0.5 * ( znotc + z00_p( 14 ) )
               vegcrj( 14 ) = ( (1.0-vseas) * vegmn0_p(14) + vseas * veg0_p(14) ) / 100.0
         End Select      

         sum_lai = SUM( laicrj * lufrac )

#ifdef Verbose
         If ( ( sum_lai - laig ) / laig .Gt. 0.05 ) Then
            Write( logdev,* ) ' '
            Write( logdev,* ) 'Error in total LAI'
            Write( logdev,* ) 'LAI grid = ', laig, ' LAI mosaic = ', sum_lai
            Write( logdev,* ) ' '
         End If
#endif

         Return

         End Subroutine Calc_LAI      

         Subroutine RA_MM5( WS10, US, VS, THETA, THETAV, TG, QVS, QSS, SNOW, PSFPA,
     &                      LWMASK, WG, WFC, Z, ZNT, UST, RA, rich, psih, betap, hu, dthvdz )

         Implicit None

         Real US,VS,THETA, THETAV, TG, QVS, QSS, SNOW, PSFPA, LWMASK, WG, WFC, Z, ZNT, UST, RA
         Real BETAH, GAMAH, PR0, BH, RICRIT, CZO, OZO, CP, R, ROVCP, EP1, G, ROVG, KARMAN, PI
         Real HU, BETAP, QFC, CVIRT, TV0, CPOT, TH0, THETAG, CPAIR
         Real RICRITI, WS, GZ1OZ0, DTHVDZ, DTHVM, VCONV, WSPD, GOVRTH, RICH, RICUT
         Real ZOL, PSIH, AH, SQLNZZ0
         Real PSURF
         Real WS10
         Integer ISNOW, ISTI

C Calculate Ra via the richardson number as done for MM5

         Data BETAH/ 8.21 /, GAMAH/ 11.6 /, PR0/ 0.95 /
         Data BH/ 15.7 /

         Data RICRIT/ 0.25 /
         Data CZO/ 0.032 /, OZO/ 0.0001 /
         Data KARMAN/ 0.4 /

         Save BETAH, GAMAH, PR0, BH, RICRIT, CZO, OZO, KARMAN

C from param.F
         CP    = 1004.E0
         R     = 287.04
         ROVCP = R / CP
         EP1   = 0.608
         G     = 9.81
         ROVG  = R / G
         PI    = 4.0 * ATAN( 1.0 )

         ISNOW = NINT( SNOW )
         ISNOW = MAX( 0, ISNOW )

         ISTI  = NINT( LWMASK )
         PSURF = PSFPA / 100.0  ! CONVERT TO MB

C
C-- compute sfc rh from soil moisture
C*     SATURATED FOR WATER SURFACE AND SNOW (ISNOW=1)
         HU = 1.0
         BETAP = 1.0
C*
C-- FOR SURFACE OVER LAND

C..... beta method, Lee & Pielke (JAM,May1992)
         If ( ISTI .Ne. 0 .And. ISNOW .Ne. 1 .And. WFC .Gt. 0. .And. WG .Le. WFC ) Then
           BETAP = 0.25 * ( 1.0 - COS( WG / WFC * PI) )**2
           HU = BETAP + (1.0 - BETAP) * QVS / QSS
         End If

         QFC = HU * QSS

C.......... compute the thetav at ground
         CVIRT = ( 1.0 + EP1 * QFC )
         TV0   = TG *CVIRT
         CPOT  = ( 1000.0 / PSURF )**ROVCP   ! psurf needs to be in mb
         TH0   = TV0 * CPOT
!        THETAG = CPOT * TG
!        CPAIR = 1004.67 * (1.0 + 0.84 * QVS)   ! J/(K KG)

C
C-----CALCULATE BULK RICHARDSON NO. OF SURFACE LAYER, ACCORDING TO
C        AKB(1976), EQ(12).
C
         RICRITI = 1.0 / RICRIT
         GZ1OZ0  = LOG( Z / ZNT )
         WS      = SQRT( US*US + VS*VS )
!        WS      = WS10
         DTHVDZ  = THETAV - TH0
         DTHVM   = MAX( -DTHVDZ, 0.0 )
         VCONV   = 2.0 * SQRT( DTHVM )
         WSPD    = SQRT( WS*WS + VCONV*VCONV )
         WSPD    = MAX( WSPD, 1.0 )
         GOVRTH  = G / THETA
         RICH    = GOVRTH * Z * DTHVDZ / ( WSPD * WSPD )
         RICUT   = 1.0 / ( RICRITI + GZ1OZ0 )

C------------------------------------------------------------------
C-- NOTE THAT THE REGIMES USED IN HIRPBL HAVE BEEN CHANGED:
C-- USE PLEIM(2006) TO CALCULATE PSI
         ZOL = 0.0
         If ( RICH .Ge. RICUT ) Then
 
C-----CLASS 1; VERY STABLE CONDITIONS:     Z/L > 1
 
               ZOL = RICH*GZ1OZ0/(1-RICRITI*RICUT)
               PSIH    =  1.-BETAH-ZOL

         Else If (RICH .Ge. 0.0 ) Then

C-----CLASS 2; STABLE: for 1 > Z/L >0
 
               ZOL = RICH*GZ1OZ0/(1-RICRITI*RICH)
               PSIH = -BETAH * ZOL

         Else
 
C-----CLASS 3 or 4; UNSTABLE:
C           CLASS 4 IS FOR ACM NON-LOCAL CONVECTION (H/L < -3)
 
             AH=0.04+0.355*ALOG(GZ1OZ0)
             SQLNZZ0=SQRT(GZ1OZ0)
             PSIH = AH*ALOG(1.-BH*SQLNZZ0*RICH)
 
         End If

         RA = PR0*(GZ1OZ0-PSIH)/(KARMAN*UST)

         Return
         End Subroutine RA_MM5

         Subroutine RA_WRF ( moli, zol, zntol, zh, ustar, z0crj, j, c, r )

         Implicit None

         Real,    Intent( In ) :: moli, zol, zntol,zh, ustar, z0crj 
         Integer, Intent( IN ) :: j, c, r

         Real    y, ynt, psih, alogz1z0

         Real,    Parameter :: betah = 5.0  ! WRF uses Dyer
         Real,    Parameter :: gamah = 16.0 ! WRF uses Dyer
         Real,    Parameter :: pr0   = 0.95 ! Prandtl number for neutral stability
         Real,    Parameter :: karman = 0.4 ! von Karman constant

         If ( moli .Lt. 0.0 ) Then
            y    = Sqrt( 1.0 - gamah * zol )
            ynt  = Sqrt( 1.0 - gamah * zntol )
            psih =  2.0 * Log( ( y + 1.0 ) / ( ynt + 1.0 ) )
         Else
            If ( ( zol - zntol ) .Le. 1.0 ) Then
               psih = -betah * ( zol - zntol )
            Else
               psih = 1.0 - betah - ( zol - zntol )
            End If
         End If
         alogz1z0   = Log( zh / z0crj )
         raj(j,c,r) = pr0 * ( alogz1z0 - psih ) / ( karman * ustar ) ! update the shared array

         Return
         End Subroutine RA_WRF
      
      End Module Mosaic_Mod
   

  
