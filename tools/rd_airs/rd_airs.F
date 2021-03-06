
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
! $Header: /nas01/depts/ie/cempd/apps/CMAQ/v5.0.1/CMAQv5.0.1/models/TOOLS/src/rd_airs/rd_airs.F,v 1.1.1.1 2012/04/19 19:48:37 sjr Exp $

C-------------------------------------------------------------
C     Main Program reads data from AIRS dataset
C-------------------------------------------------------------
      Program RDairs
C-------------------------------------------------------------

      Use env_vars
      Use sitedata     

      Implicit none

C... local variables
      character*20 PNAME 
      character*132 record
      character*132 prevrec

      ! input values
      TYPE ( AIRS_ID ) :: rec_id
      TYPE ( AIRS_ID ) :: data_id
         
      Real recValues(24)
      Real dataValues(24)

      integer i, j
      integer istat

      logical newday
      logical process

      Data PNAME / 'RD_AIRS Version 1.0' /

C...  print program name and version at startup
      Write(*,'(/a/)') '<---- Starting Program ' // TRIM(PNAME) // ' ---->'

C...  get environment variables for program
      Write(*,'('' reading environment Variables'')')
      Call GET_ENVS

C...  open site data file and store sites in arrays
      Call loadsites( SITE_FILE )

C... open input file      
      OPEN(11,STATUS='OLD',FILE=IN_FILE)

C... open output file
      OPEN(19,STATUS='unknown',FILE=OUT_FILE)

C... set initial values      
      data_id%state_code = ''

      prevrec = ''
               
100   read(11,'(a)',end=200) record

      if( record(1:2).eq.'RD' ) Then
         Call read1(record, rec_id, recValues, istat)
        Else
         Call read2(record, rec_id, recValues, istat)
         Endif 
        

      !!!!! check if record should be processed  !!!!!!!!
      process = .true.
      
      if(NSTATES.gt.0) then
        process = .false.
        Do I=1,NSTATES
          if( rec_id%state_code .eq. STATES(I) ) process = .true.
          Enddo
         Endif

      if(process .and. istat.ne.0 ) then
        Write(*,'('' Syntax error found on record ''/,a)') TRIM(record)  
        process = .false.
        Endif

      if(process .and. NYEARS.gt.0) Then
        process = .false.
        Do I=1,NYEARS
          if( mod(rec_id%year,100) .eq. YEARS(I) ) process = .true.
          Enddo
        Endif 

 
      if(.Not.process) go to 100  ! do not process record

      ! check that input file was sorted
      if( record(1:30) .lt. prevrec(1:30) ) then
        Write(*,'(''**ERROR**  Input file was not sorted prior to run'')')
        Stop
        endif


      !!! Process record !!!!!
      prevrec = record

      ! check if new site or day 
      newday = .false.
      if( rec_id%state_code .ne. data_id%state_code ) newday = .true.
      if( rec_id%county_code .ne. data_id%county_code ) newday = .true.
      if( rec_id%site_code .ne. data_id%site_code ) newday = .true.
      if( rec_id%parameter .ne. data_id%parameter ) newday = .true.
      if( rec_id%poc .ne. data_id%poc ) newday = .true.
      if( rec_id%duration .ne. data_id%duration ) newday = .true.
      if( rec_id%units .ne. data_id%units ) newday = .true.
      if( rec_id%method .ne. data_id%method ) newday = .true.
      if( rec_id%year .ne. data_id%year ) newday = .true.
      if( rec_id%month .ne. data_id%month ) newday = .true.
      if( rec_id%day .ne. data_id%day ) newday = .true.

      if( newday ) then
        
        if( data_id%state_code.ne.'' ) Call writeRecord( data_id, dataValues )

        ! reset hour values to -99
        Do I=1,24
          dataValues(I) = -99.0
          EndDo 
        EndIf

      !  update data values from record values
      data_id%state_code = rec_id%state_code
      data_id%county_code = rec_id%county_code
      data_id%site_code = rec_id%site_code
      data_id%parameter = rec_id%parameter
      data_id%poc = rec_id%poc
      data_id%duration = rec_id%duration
      data_id%units = rec_id%units
      data_id%method = rec_id%method
      data_id%year = rec_id%year
      data_id%month = rec_id%month
      data_id%day = rec_id%day

      Do I=1,24
        if(recValues(I).ne.-99.0) dataValues(I) = recValues(I)
        EndDo

      goto 100  !read next record


200   if( data_id%state_code.ne.'' ) Call writeRecord( data_id, dataValues )

C...  print program name and version on exit   
      Write(*,'(/a/)') '<---- Exiting Program ' // TRIM(PNAME) // ' ---->'

      End Program RDairs


ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c      routine to write output record
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      Subroutine WriteRecord( data_id, values )

      Use sitedata  
      Use env_vars

      Implicit none

C... arguments
      TYPE ( AIRS_ID ) :: data_id    
      Real values(24)

C... local variables
      Integer i 
      Integer luse
      Real lat, lon
      Character*6 cValues(24)
      Real factor

C.. check for invalid parameter
      if(data_id%parameter .ne. PARAMETER) then
        Return
        Endif

C.. check for invalid time duration
      if(TIMEINTVL.ne.'*' .and. TIMEINTVL.ne.data_id%duration) then
        Write(*,'(''Invalid TIMEINTVL code '',a,'' for site '',3a)')
     &   data_id%duration,data_id%state_code, data_id%county_code, data_id%site_code
        Return
        Endif

      factor = 1.0

      if( CHECKUNITS ) then
        if(UNITSCODE.eq.008) then ! (convert to ppb (008))
          if(data_id%units .eq. 007) then
            factor = 1000.
            data_id%units = UNITSCODE
            Endif

          if(data_id%units .eq. 040) then
            factor = 10.0
            data_id%units = UNITSCODE                         
            Endif
          endif

   
        if(UNITSCODE.eq.007) then ! (convert to ppm (007))
          if(data_id%units .eq. 008) then
            factor = 0.001
            data_id%units = UNITSCODE
            Endif
 
          if(data_id%units .eq. 040) then                     
            factor = 0.01                                     
            data_id%units = UNITSCODE                         
            Endif 
          endif

        if(data_id%units .ne. UNITSCODE) then
          Write(*,'(''Invalid units code '',i3.3,'' for site '',3a)') 
     &       data_id%units, data_id%state_code, data_id%county_code,
     &       data_id%site_code
          Return
          Endif
        Endif  ! CHECKUNITS condition

C...  Convert real values to character values
      Do i=1,24
        ! adjust values by units factor
        if( INT(values(i)) .ne. -99 ) values(i) = factor * values(i)

        if( INT(values(i)) .eq. -99 )  Then
              Write(cValues(i),'(i6)') -99
         Else if( ABS(values(i)) .ge. 1000.0 ) Then
              Write(cValues(i),'(f6.0)') values(i)
         Else if( ABS(values(i)) .ge. 100.0 ) Then
              Write(cValues(i),'(f6.1)') values(i)
         Else if( ABS(values(i)) .ge. 10.0 ) Then
              Write(cValues(i),'(f6.2)') values(i)
         Else  
              Write(cValues(i),'(f6.3)') values(i)
         Endif
     
        Enddo

      ! get lat, lon, luse values for site
      Call getLL(data_id%state_code, data_id%county_code, data_id%site_code, luse, lat, lon)
      
      ! check if site was found
      if(INT(lat).eq.-99 .and. INT(lon).eq.-99 ) Then
         Write(*,'('' No site found for '',3a)') 
     &          data_id%state_code, data_id%county_code, data_id%site_code
        Else     
         write(19,'(4(a,1x),a1,1x,a1,2i4.3,i5.4,2i3.2,2f8.3,i2,24a6)')
     &     data_id%state_code, data_id%county_code, data_id%site_code,
     &     data_id%parameter, data_id%poc, data_id%duration, data_id%units,
     &     data_id%method, data_id%year, data_id%month, data_id%day,
     &     lat, lon, luse, cValues
         Endif  
      Return
 
      End Subroutine WriteRecord


ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c      routine to read input record (format type 1)
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      Subroutine Read1( record, input_id, values, status )

      Use sitedata  

      !arguments
      Character*(*) record
      TYPE ( AIRS_ID ) :: input_id     
      Real values(24)
      Integer status 

C... external routines
      integer getParsedNumber

      ! local variables
      Integer i
      Integer nfields
      Character*10 field
      Integer hour

      ! initialize values to missing
      Do i=1,24
        values(i) = -99.0
        Enddo

      nfields = getParsedNumber( record, '|' )

      if( nfields.lt.13 ) then
        status = -1
        return
        Endif

      !  get state, county, and site codes from record
      Call getParsedField( record, '|', 3, input_id%state_code, .false. )
      Call getParsedField( record, '|', 4, input_id%county_code, .false. )
      Call getParsedField( record, '|', 5, input_id%site_code, .false. )

      !  get parameter from record
      Call getParsedField( record, '|', 6, input_id%parameter, .false. )

      !  read the poc from field 7 
      Call getParsedField( record, '|', 7, input_id%poc, .false. )

      !  read the duration from field 8 
      Call getParsedField( record, '|', 8, input_id%duration, .false. )
      
      !  read the units from field 9 
      Call getParsedField( record, '|', 9, field, .false. )
      Read(field,'(I10)',iostat = status) input_id%units

      !  read the method from field 10 
      Call getParsedField( record, '|', 10, field, .false. )
      Read(field,'(I10)',iostat = status) input_id%method

      !  read the date from field 11 
      Call getParsedField( record, '|', 11, field, .false. )
      Read(field,'(i4,2i2)',iostat = status) input_id%year,
     &  input_id%month, input_id%day

      !  read the hour from field 12 
      Call getParsedField( record, '|', 12, field, .false. )
      Read(field,'(i2)',iostat = status) hour

      !  read the value from field 13 
      Call getParsedField( record, '|', 13, field, .false. )
      if( field.ne.' ' ) Read(field,'(f10.0)',iostat = status) values(hour+1)

      Return
      End 


ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c      routine to read input record (format type 2)
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      Subroutine Read2( record, input_id, values, status )

      Use sitedata  

      !arguments
      Character*(*) record
      TYPE ( AIRS_ID ) :: input_id     
      Real values(24)
      Integer status 

      ! local variables
      Integer i, hour, idec, istat
      Character*4 cValues(8)

      ! initialize values to missing
      Do i=1,24
        values(i) = -99.0
        Enddo

      Read(record,'(1x,a2,a3,a4,a5,2a1,2i3,4i2,i1)',iostat=status)
     & input_id%state_code, input_id%county_code, input_id%site_code, 
     & input_id%parameter, input_id%poc, input_id%duration, input_id%units,
     & input_id%method, input_id%year,input_id%month, input_id%day, hour, idec

      If(status.ne.0) return

      ! convert year to 4 digits
      if( input_id%year .lt. 100 ) then
        if( input_id%year .gt. 50 ) input_id%year = 1900 + input_id%year
        if( input_id%year .le. 50 ) input_id%year = 2000 + input_id%year
        Endif

      ! read values for hours as characters
      if( status.eq.0 ) then
        Read(record,'(32x,8(a4,1x))',iostat=status)(cValues(i),i=1,8)

        !  convert character fields to real
        Do i=1,8
          if( cValues(i).ne.' ' ) Then
            Read(cValues(i),'(f4.0)',iostat = istat) values(hour+i)
            if( istat.eq.0 ) Then
              values(hour+i) = values(hour+i) / (10.0**idec)
              Else
              values(hour+i) = -99.0
              Endif
            Endif
          Enddo
        EndIf 

      Return
      End 
