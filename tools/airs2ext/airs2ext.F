
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
! $Header: /nas01/depts/ie/cempd/apps/CMAQ/v5.0.1/CMAQv5.0.1/models/TOOLS/src/airs2ext/airs2ext.F,v 1.1.1.1 2012/04/19 19:48:37 sjr Exp $

C-------------------------------------------------------------
C     Program converts hourly airs data to daily to 
C     use with sitecmp program
C-------------------------------------------------------------
      Program airs2day
C-------------------------------------------------------------

      Use m3utilio

      Implicit none

C... local variables
      Character*128 infile, outfile 
      Character*256 record
      Character*16  species
      Integer in, out, logunit, status
      Integer state, county, site, year
      Integer st, cnty, id, yr, mon, dy, h   
      Real lat, lon, latitude, longitude

      Real ozone(12,31,24)    ! month,day,hour
      Real ozdata(24)

      in = 10
      out = 20
 
C... get filenames from evironment variables
      LOGUNIT = INIT3()

      CALL ENVSTR( 'SPECIES', 'Species Name', 'ozone', species, STATUS)
      CALL ENVSTR( 'INFILE', 'Input data file', 'ozone.txt', infile, STATUS)
      CALL ENVSTR( 'OUTFILE', 'Output data file', 'o3.txt', outfile, STATUS)

C... print program stating line
      Write(*,'(/''<--- Starting program airs2ext version 1.0 --->''/)')
      
C... open files
      Open(unit=in, file=infile,status='OLD',err=501)
      Open(unit=out, file=outfile, err=502)

C... print title records to output file
      Write(out,'(2a)') 'site_id,dateon,dateoff,', species


C... initialize values
      ozone = -99.0
      state = 0
      county = 0
      site = 0
      year = 0
      latitude = -99.0
      longitude = -99.0
               
      Do 
        Read(in,'(a)',iostat=status) record

        ! check for eof
        if( status.ne.0 ) Then
          Call outRecord(out, state, county, site, year, latitude, longitude,  ozone)
          exit
          endif        
 
        ! check for new site or year
        Read(record,'(i2,i4,i5,19x,i4,2i3,2f8.0,2x,24f6.0)') 
     &    st, cnty, id, yr, mon, dy, lat, lon, ozdata
       
        if( st.ne.state .or. cnty.ne.county .or. id.ne.site .or. yr.ne.year ) Then
          Call outRecord(out, state, county, site, year, latitude, longitude, ozone)

          ! initialize values
          ozone = -99.0
          state = st
          county = cnty
          site = id
          year = yr
          latitude = lat
          longitude = lon
          endif

        ! update ozone array
        do h=1,24
          if( ozone(mon,dy,h).le.0 ) ozone(mon, dy, h) = ozdata(h)
          enddo

        endDo
           

      ! close files and exit
      Close(unit=in)
      Close(unit=out)
      Stop

501   Write(*,'(''Error opening input file'')')
      Stop

502   Write(*,'(''Error opening output file'')') 
      Stop

      End Program airs2day

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cc   output yearly record for site
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      Subroutine outRecord(out, state, county, site, year, latitude, longitude, ozone)

      Use m3utilio

      Implicit none

      ! arguments 
      Integer out     
      Integer state, county, site, year
      Real latitude, longitude
      Real ozone(12,31,24)

C..EXTERNAL FUNCTIONS:
      Character*16 real2Str

      ! local variables
      character*1 sep
      Integer ndys

      Integer m, d, h, jday, daycnt
      Real daysum

      character*16 field
      character*21 dateon, dateoff

      Logical, save :: first
      Character*16, save :: step
      Integer, save :: startdate
      Integer, save :: enddate
      Real, save :: latmin
      Real, save :: latmax
      Real, save :: lonmin
      Real, save :: lonmax
      Integer status


      data sep/','/
      data first /.true./

      !  check for first time 
      if(first) then
        first = .false.

        ! get timestep for output
        CALL ENVSTR( 'STEP', 'Output Time Step', 'DAY', step, STATUS)
        if(step.ne.'DAY' .and. step.ne.'HOUR') then
          Write(*,'('' Invalid time step, program stopped'')')
          stop
          endif
 
        ! get starting date
        startdate = ENVINT('START_DATE','Start date', 0, STATUS)
 
        ! get ending date
        enddate = ENVINT('END_DATE','End date', 0, STATUS)

        ! get domain definition
        latmin = ENVREAL( 'LAT_MIN', 'Minimum Latitude', 0.0, STATUS)
        latmax = ENVREAL( 'LAT_MAX', 'Maximum Latitude', 90.0, STATUS)
        lonmin = ENVREAL( 'LON_MIN', 'Minimum Longitude', -180.0, STATUS)
        lonmax = ENVREAL( 'LON_MAX', 'Maximum Longitude', 180.0, STATUS)

        endif  ! end of first pass


      ! check if invalid year or year outside date range
      if( startdate.gt.0 .and. enddate.gt.0 ) then
        if( year .lt. startdate/1000 ) return
        if( year .gt. enddate/1000 ) return 
        endif

      ! check if site is outside domain
      if( latitude.lt.latmin .or. latitude.gt.latmax ) return
      if( longitude.lt.lonmin .or. longitude.gt.lonmax ) return

      Write(*,'(''processing site:'',i2.2,i3.3,i4.4)') state,county,site

      ! process each day of year
      do m=1,12
        ndys = 31
        if((m.eq.4).or.(m.eq.6).or.(m.eq.9).or.(m.eq.11)) ndys=30
        if(m.eq.2) ndys = 28
        if((m.eq.2).and.(mod(year,4).eq.0)) ndys = 29  

        do d=1,ndys

          ! check to process day
          if( startdate.gt.0 .and. enddate.gt.0 ) then
            jday = 1000*year + JULIAN(year, m, d)
            if(jday.lt.startdate .or. jday.gt.enddate) CYCLE
            endif

          if(step.eq.'DAY') then

            ! build date fields 
            write(dateon,'(''"'',i4.4,''-'',i2.2,''-'',i2.2,'' 00:00:00"'')')
     &           year, m, d
            write(dateoff,'(''"'',i4.4,''-'',i2.2,''-'',i2.2,'' 23:59:00"'')')
     &           year, m, d

            field = '-999'
            daysum = 0.0
            daycnt = 0
            do h=1,24
              if( ozone(m,d,h).ge.0.0 ) then
                daycnt = daycnt+1
                daysum = daysum + ozone(m,d,h)
                endif
              enddo

            if( daycnt.ge.16 ) then 
              write(field,'(f16.2)') daysum/daycnt
              Call LeftTrim(field)
              write(out, '(i2.2,i3.3,i4.4,6a)')
     &          state, county, site, sep,  
     &          dateon, sep, dateoff, sep, trim(field)
              endif

            endif

          if(step.eq.'HOUR') then
            do h=1,24

              ! build date fields 
              write(dateon,'(''"'',i4.4,''-'',i2.2,''-'',i2.2,i3.2,'':00:00"'')')
     &           year, m, d, h-1
              write(dateoff,'(''"'',i4.4,''-'',i2.2,''-'',i2.2,i3.2,'':59:00"'')')
     &           year, m, d, h-1
  
              field = '-999'
              if(ozone(m,d,h).ge.0.0) field = real2Str( ozone(m,d,h),'(g12.5)')

              if(field.ne.'-999') then
                write(out, '(i2.2,i3.3,i4.4,6a)')
     &            state, county, site, sep, dateon, sep, dateoff, sep, trim(field)
                endif

              enddo
            endif
  
          enddo
        enddo 

      return
      end subroutine outRecord


C****************************************************************************
C  routine to convert real to string
C****************************************************************************
      Character*16 Function real2Str( value, fmt ) result(realStr)
 
      IMPLICIT NONE
 
      ! argument
      Real value
      Character*(*) fmt
 
      ! local variables
      Character*16 MISSING_VALUE
      Character*80 record
      Integer status
 
      MISSING_VALUE = '-999'
 
      if( value.gt.-99.00001 .AND. value.lt.-98.99999 ) then
        realStr = MISSING_VALUE
        Call LeftTrim(realStr)
        return
        endif
 
      Write(record,fmt,iostat=status) value
      Call LeftTrim(record)
      realStr = record
      return
      End Function real2Str


C****************************************************************************
C  routine to remove leading blank spaces from Character String
C****************************************************************************
      Subroutine LeftTrim( STRING )

      CHARACTER*(*) STRING
      Integer I

      Do I=1,LEN(STRING)
        if(STRING(I:I) .ne. CHAR(32)) Then
          STRING = STRING(I:)
          RETURN
          EndIf 
         EndDo

      Return
      End Subroutine LeftTrim

C****************************************************************************
C  routine to remove trailing white spaces from Character String
C****************************************************************************
      Subroutine RightTrim( STRING )
 
      CHARACTER*(*) STRING
      Integer I
 
      Do I=LEN(STRING),1,-1
        if(STRING(I:I) .lt. CHAR(32)) STRING(I:I) = CHAR(32)
        if(STRING(I:I) .gt. CHAR(32)) Exit
        EndDo

      Return
      End Subroutine RightTrim
