
!-----------------------------------------------------------------------!
!  The Community Multiscale Air Quality (CMAQ) system software is in    !
!  continuous development by various groups and is based on information !
!  from these groups: Federal Government employees, contractors working !
!  within a United States Government contract, and non-Federal sources  !
!  including research institutions.  These groups give the Government   !
!  permission to use, prepare derivative works of, and distribute copies!
!  of their work in the CMAQ system to the public and to permit others  !
!  to do so.  The United States Environmental Protection Agency         !
!  therefore grants similar permission to use the CMAQ system software, !
!  but users are requested to provide copies of derivative works or     !
!  products designed to operate in the CMAQ system to the United States !
!  Government without restrictions as to use by others.  Software       !
!  that is used with the CMAQ system but distributed under the GNU      !
!  General Public License or the GNU Lesser General Public License is   !
!  subject to their copyright restrictions.                             !
!-----------------------------------------------------------------------!

! RCS file, release, date & time of last delta, author, state, [and locker]
! $Header: /nas01/depts/ie/cempd/apps/CMAQ/v5.0.1/CMAQv5.0.1/models/TOOLS/src/sitecmp/module_sites.F,v 1.1.1.1 2012/04/19 19:48:37 sjr Exp $

C what(1) key, module and SID; SCCS file; date and time of last delta:
C %W% %P% %G% %U%

C*************************************************************************
C
C  MODULE: defines site data
C             
C*************************************************************************
      MODULE SITE_DATA

      INTEGER  NSITES

      CHARACTER*256   SITE_FNAME  

      CHARACTER*10, ALLOCATABLE :: SITE( : )

      INTEGER, ALLOCATABLE :: TZ( : ) 
      INTEGER, ALLOCATABLE :: COL( : )
      INTEGER, ALLOCATABLE :: ROW( : )

      REAL, ALLOCATABLE :: LAT( : )   
      REAL, ALLOCATABLE :: LON( : ) 
      REAL, ALLOCATABLE :: SX( : )  
      REAL, ALLOCATABLE :: SY( : )  


      CONTAINS


cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Subroutine to get data from file type 1
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

         SUBROUTINE FL_TYP1
C*************************************************************************
C
C  FUNCTION:  To provide site data
C             
C*************************************************************************
         USE ENV_VARS
         USE M3UTILIO

         IMPLICIT NONE 

      
C..ARGUMENTS: None

C..PARAMETERS: None

C..EXTERNAL FUNCTIONS:
         INTEGER getNumberOfFields

C..SAVED LOCAL VARIABLES: None

C..SCRATCH LOCAL VARIABLES:
         CHARACTER*80    RECORD       ! input record buffer
         CHARACTER*80    FIELD        ! input field
         CHARACTER*16    ENV_DFLT     ! Environment variable default value
         CHARACTER*16    PNAME        ! Program Name
         CHARACTER*80    ENV_DESC     ! Environment variable description
         CHARACTER*80    MSG          ! Error message
         CHARACTER*256   RET_VAL      ! Returned value of environment variable

         INTEGER   NFIELDS
         INTEGER   LFN   
         INTEGER   N   
         INTEGER   NN   
         INTEGER   STATUS  
         INTEGER   TZONE  

         Integer   numsites
         Character*(10)              ::    prevSite
         Character*(10), allocatable ::    idfld(:)
         Real, allocatable           ::    lonfld(:)
         Real, allocatable           ::    latfld(:)
         Integer, allocatable        ::    tzfld(:)
         Logical, allocatable        ::    active(:)   

         Integer                     ::    siteField
         Integer                     ::    t
         Character*(10)              ::    ftypes(10)
         Character*(10)              ::    sitehdrs(10)

         Data ftypes /'CASTNET', 'SEARCH', 'IMPROVE', 'NADP', 'AIRMON', 'STN', 
     &                'MDN', 'MET', 'DEARS', 'OUTPUT'/

         Data sitehdrs /'site_id', 'site_id', 'site_code', 'SiteID', 'Site', 'SITE',
     &                  'siteID', 'site_id', 'PID', 'SiteId'/

C**********************************************************************
         DATA  PNAME       / 'FL_TYP1'  /
         LFN = JUNIT()
         SITE_FNAME = SITE_FILE

         OPEN(unit=lfn, file=SITE_FNAME, status='old', iostat=status)
         if(status.ne.0) then
           MSG = 'Cannot open site file:' // trim(SITE_FNAME)
           CALL M3ERR( PNAME, 0, 0, MSG, .TRUE. )
           endif

         !  read file to determine number of sites
         numsites = 0
         DO
           READ( LFN, '(A)', iostat=status ) RECORD
           if(status.ne.0) EXIT
           Call getField(record, char(9), 1, field)
           nfields = getNumberOfFields(record, char(9))
           IF(nfields.ge.3 .and. LEN_TRIM(field).ge.3) numsites = numsites + 1
           ENDDO
      
         if( numsites.eq.0 ) then
           write(*,'(''**ERROR**, No sites found in site file:'',a)') trim(SITE_FNAME)
           Stop
           endif

 
         ALLOCATE( idfld( numsites ), lonfld( numsites ), latfld( numsites ) )
         ALLOCATE( tzfld( numsites ), active( numsites) )

         active = .false.

         REWIND( LFN )
         ! read all site data from LFN
         N = 0
         DO
            READ( LFN, '(A)', iostat=status ) RECORD
            if( status.ne.0 ) EXIT

            nfields = getNumberOfFields(record, char(9))
            Call getField(record, char(9), 1, field)
            IF(nfields.ge.3 .and. LEN_TRIM(field).ge.3) THEN
               N = N + 1
               idfld( N ) = field
               Call getField(record, char(9), 2, field)
               read(field,'(f16.0)',iostat=status) lonfld(n)
               if( status.ne.0 ) then
                 write(*,'(''**WARNING**  Invalid site record:'',a)') TRIM(record)
                 CYCLE
                 endif

               Call getField(record, char(9), 3, field)
               read(field,'(f16.0)',iostat=status) latfld(n)
               if( status.ne.0 ) then
                 write(*,'(''**WARNING**  Invalid site record:'',a)') TRIM(record)
                 CYCLE
                 endif

               ! compute Time zone offset from longitude
               tzfld(n) = -(lonfld(n)+7.5) / 15

               ! try to read Time zone offset from field 4
               if(nfields.eq.4) then
                 Call getField(record, char(9), 4, field)
                 READ(field, '(BN,i10)', iostat=status) tzone
                 if(status.eq.0 .and. field.ne.' ') tzfld(n) = tzone
                 endif

               endif
            enddo

         close(unit=LFN)
         write(*,'(i6,'' total sites read'')') numsites

         OPEN(unit=lfn, file=IN_TABLE, status='old', iostat=status)
         if(status.ne.0) then
           MSG = 'Cannot open site file:' // trim(IN_TABLE)
           CALL M3ERR( PNAME, 0, 0, MSG, .TRUE. )
           endif

         ! find table type index t
         do n=1,SIZE(ftypes)
           if( TABLE_TYPE.eq.ftypes(n) ) t = n
           enddo

         ! determine location of site field in table file
         siteField = 0

         do
           read(lfn,'(a)',iostat=status) record
           if( status.ne.0 ) then
             write(*,'(''**ERROR** Invalid table header in table file'')')
             Stop
             endif

           call rmCommas(record)
           nfields = getNumberOfFields(record, ',')

           if( nfields.lt.3 ) CYCLE


           if( INDEX(record,TRIM(sitehdrs(t))).gt.0 ) then
             Do n=1,nfields
               call getField(record, ',', n, field)
               call rmQuots( field )
               call LeftTrim(field)
               if( INDEX(field,TRIM(sitehdrs(t))).gt.0 ) siteField = n
               EndDo
             EndIf
           if( siteField.gt.0 ) EXIT
           enddo


         ! read table file and check for active sites
         prevSite = ' '
         do
           read(lfn,'(a)',iostat=status) record
           if( status.ne.0 ) EXIT
           call rmCommas(record)

           Call getField(record, ',', siteField, field )
           call rmQuots( field )
           if( field .eq. prevSite ) CYCLE

           do n=1,numsites
             if( field .eq. idfld(n) ) then
               active(n) = .true.
               EXIT
               endif
             enddo
           prevSite = field
           enddo

         !  count number of active sites
         nsites = 0
         do n=1,numsites
           if( active(n) ) nsites = nsites + 1
           enddo


         ! build list of active sites
         ALLOCATE( SITE( nsites ), TZ( nsites ), LON( nsites ), LAT( nsites ) )

         nn = 0
         do n=1,numsites
           if( active(n) ) then
             nn = nn + 1
             SITE(nn) = idfld(n)
             TZ(nn) = tzfld(n)
             LON(nn) = lonfld(n)
             LAT(nn) = latfld(n)
             endif
           enddo


         write(*,'(i6,'' active sites loaded'')') NSITES

         close(lfn)
         RETURN

         END SUBROUTINE FL_TYP1


         SUBROUTINE SET_SITE_LOC

C*************************************************************************
C
C  FUNCTION: Finds the col and row location of each site
C             
C*************************************************************************
         USE ENV_VARS
         USE M3FILES
         USE M3UTILIO
         USE GRID_DATA
         IMPLICIT NONE     

C..ARGUMENTS: None

C..PARAMETERS: None

C..EXTERNAL FUNCTIONS:

C..SAVED LOCAL VARIABLES: None

C..SCRATCH LOCAL VARIABLES:
         CHARACTER*24  CRDATE      ! Create date
         CHARACTER*80  MSG         ! Log message
         CHARACTER*16  PNAME       ! Program Name
         CHARACTER*256   RET_VAL   ! Returned value of environment variable

         INTEGER   C, R, N         ! Loop indices
         INTEGER   IOUT            ! Output file unit number
         INTEGER   JDATE           ! Create date YYYYDDD
         INTEGER   JTIME           ! Create timeHHMMSS

         REAL   LATIN           ! Input lat
         REAL   LONIN           ! Input lon
         REAL   X               ! x-coordinate for lambert projection
         REAL   Y               ! y-coordinate for lambert projection
         REAL   XW, XE          ! X-coordinates of grid cell edges  
         REAL   YS, YN          ! Y-coordinates of grid cell edges  
         LOGICAL PROJ           ! projection is supported
   
C**********************************************************************
         DATA PNAME / 'SET_SITE_LOC' /
         DATA PROJ  / .FALSE. /

         ALLOCATE( COL( NSITES ), ROW( NSITES ), SX( NSITES ), SY( NSITES ) )

         Call SETPROJ( GDTYP3D, Real(M3GRID%P_ALP),Real(M3GRID%P_BET),
     &                 Real(M3GRID%P_GAM),Real(M3GRID%XCENT),Real(M3GRID%YCENT) )

C  process each site
         DO N = 1, NSITES

c..for now make sure longitude is negative
            LONIN = MIN( LON( N ), -1.0 * LON( N ) )
            LATIN = LAT( N )
         
c..get the x,y coordinates 
            Call ToProj(GDTYP3D, LONIN, LATIN, X, Y)

c..save x,y cooridinates
            SX( N ) = X
            SY( N ) = Y

c..find the column location 
            COL( N )  = 0
            DO C = 1, NCOLS3D
               XW = M3GRID % XORIG + FLOAT( C - 1 ) * M3GRID % XCELL 
               XE = XW + M3GRID % XCELL
               IF( X .GE. XW .AND. X .LT. XE ) COL( N ) = C
            ENDDO

c..find the row location 
            ROW( N ) = 0
            DO R = 1, NROWS3D
               YS = M3GRID % YORIG + FLOAT( R - 1 ) * M3GRID % YCELL 
               YN = YS + M3GRID % YCELL
               IF( Y .GE. YS .AND. Y .LT. YN ) ROW( N ) = R
            ENDDO

           ! Write(*,'(a,2f10.4,2i5)') SITE(N),LON(N),LAT(N), COL(N), ROW(N)
         ENDDO

         RETURN

92000 FORMAT( '! INPUT M3 FILE ', I2, ': ', A )
92020 FORMAT( '! INPUT SITE FILE: ', A )
92040 FORMAT( '! SITEID STATE REGION LON LAT COL ROW X Y ' )
92060 FORMAT( A9, 1X, A2, 1X, A2, F8.3, 1X, F8.3, 1X, I3, 1X, I3, 2F15.2 )

         END SUBROUTINE SET_SITE_LOC

C  function to find the index number of a site
      Integer Function getSiteNumber( id ) result (siteNo)

      CHARACTER*(*) :: id
      Integer :: i

      !  local variables
      Character*(10), save :: prevId  
      Integer, save        :: prevNo

      siteNo = -1

      !  check for repeat
      if( id .eq. prevId ) then
        siteNo = prevNo
        return
        endif

      ! search list for match 
      do i=1,NSITES
       if( TRIM(id) .eq. TRIM(SITE(I)) ) then
         siteNo = i

         ! save for next lookup
         prevId = id
         prevNo = siteNo
         return
         endif
       Enddo 
      
      !Write(*,'('' cannot find match for site '',a)') id
      Return
      End Function getSiteNumber


C  function to return latitude value for site n
      Real Function getLatitude( id ) result (latitude)

      if(id .le. size(LAT)) Then
        latitude = lat(id)
      else
        latitude = -99
        endif

      Return
      End Function getLatitude
      

C  function to return longitude value for site n
      Real Function getLongitude( id ) result (longitude)

      if(id .le. size(LON)) Then
        longitude = lon(id)
      else
        longitude = -99
        endif

      Return
      End Function getLongitude


      !****************************************************************************
      !  routine to set map projection
      !****************************************************************************
      Subroutine SetProj(gdtype, alpha, beta, gamma, xcent, ycent)

      IMPLICIT NONE

      ! arguments
      Integer gdtype
      Real alpha, beta, gamma, xcent, ycent

      ! external functions
      logical SETLAM
      logical SETPOL

      !  check for LAT/LON projection
      if( gdtype .eq. 1 ) then
        return
        endif

      !  check for lambert projection
      if( gdtype .eq. 2 ) then
        if( .NOT. SETLAM( alpha, beta, gamma, xcent, ycent) ) then
          Call m3err ('writeSite', 0, 0, 'Lambert projection setup error', .TRUE.)
          endif
        return
        endif

      !  check for Polar projection
      if( gdtype .eq. 6 ) then
        if( .NOT. SETPOL( alpha, beta, gamma, xcent, ycent) ) then
          Call m3err ('writeSite', 0, 0, 'Polar projection setup error', .TRUE.)
          endif
        return
        endif


      Call m3err ('sitecmp', 0, 0, 'Map projection setup error', .TRUE.)

      end Subroutine SetProj


      !C****************************************************************************
      !C  routine to compute map projection from LAT/LON
      !C****************************************************************************
      Subroutine ToProj(gdtype, longitude, latitude, x, y)

      IMPLICIT NONE

      ! arguments
      Integer gdtype
      Real longitude, latitude, x, y

      ! external functions
      logical LL2LAM
      logical LL2POL

      !  check for LAT/LON projection
      if( gdtype .eq. 1 ) then
        x = longitude
        y = latitude
        return
        endif

      !  check for lambert projection
      if( gdtype .eq. 2 ) then
        if(.NOT.LL2LAM(longitude, latitude, x, y) ) then
          Call m3err('sitecmp', 0, 0, 'Lat/Lon to Lambert error', .TRUE.)
          endif
        return
        endif

      !  check for polar projection
      if( gdtype .eq. 6 ) then
        if(.NOT.LL2POL(longitude, latitude, x, y) ) then
          Call m3err('sitecmp', 0, 0, 'Lat/Lon to Polar error', .TRUE.)
          endif
        return
        endif

      Call m3err ('writeSite', 0, 0, 'Map projection setup error', .TRUE.)

      end Subroutine ToProj


      !C****************************************************************************
      !C  routine to compute LAT/LON from map projection
      !C****************************************************************************
      Subroutine ToLL(gdtype, x, y, longitude, latitude)

      IMPLICIT NONE

      ! arguments
      Integer gdtype
      Real longitude, latitude, x, y

      ! external functions
      logical LAM2LL
      logical POL2LL

      !  check for LAT/LON projection
      if( gdtype .eq. 1 ) then
        longitude = x
        latitude = y
        return
        endif

      !  check for lambert projection
      if( gdtype .eq. 2 ) then
        if(.NOT.LAM2LL(x, y, longitude, latitude) ) then
          Call m3err('sitecmp', 0, 0, 'Lat/Lon to Lambert error', .TRUE.)
          endif
        return
        endif

      !  check for polar projection
      if( gdtype .eq. 6 ) then
        if(.NOT.POL2LL(x, y, longitude, latitude) ) then
          Call m3err('sitecmp', 0, 0, 'Lat/Lon to Polar error', .TRUE.)
          endif
        return
        endif

      Call m3err ('writeSite', 0, 0, 'Map projection setup error', .TRUE.)

      end Subroutine ToLL

      END MODULE SITE_DATA
