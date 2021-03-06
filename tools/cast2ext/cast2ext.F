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
! $Header: /nas01/depts/ie/cempd/apps/CMAQ/v5.0.1/CMAQv5.0.1/models/TOOLS/src/cast2ext/cast2ext.F,v 1.1.1.1 2012/04/19 19:48:37 sjr Exp $

C-------------------------------------------------------------
      Program cast2ext
C-------------------------------------------------------------

      Use m3utilio

      Implicit none

C... external functions
      Integer getParsedNumber

C... local variables
      Character*128 infile, outfile 
      character*512 record
      character*32 header(100) 
      character*32 field(100) 
      Integer in, out, logunit, status
      Character*32 datefld
      Character*32 flagname 
      Integer nfields, kdate, i, pos

      in = 10
      out = 20
 
C... get filenames from evironment variables
      LOGUNIT = INIT3()
      CALL ENVSTR( 'INFILE', 'Input data file', 'castnet_hr.csv', infile, STATUS)
      CALL ENVSTR( 'OUTFILE', 'Output data file', 'castnet.csv', outfile, STATUS)


C... open files
      Open(unit=in, file=infile,status='OLD',err=501)
      Open(unit=out, file=outfile, err=502)

C... read header record
      Read(in,'(a)',err=501) record
      nfields = getParsedNumber(record, ',')

      Do i=1,nfields
        Call getParsedField( record, ',', i, header(i), .false. )
        Call LeftTrim(header(i))
        if( header(i).eq.'date_time' ) then
          header(i) = 'dateon'
          kdate = i
          endif
        enddo

C.. print new header record
      record = header(1)
      Do i=2,nfields
        record = TRIM(record) // ',' // TRIM(header(i))
        if( i.eq.kdate ) then
          record = TRIM(record) // ',' // 'dateoff'
          endif
        enddo
      Write(out,'(a)') TRIM(record)


C...  read each data record and write it with changed data fields
      Do 
        Read(in,'(a)',iostat=status) record

        ! check for eof
        if( status.ne.0 ) Then
          exit
          endif        

        ! read input fields
        Do i=1,nfields                                                                                
          Call getParsedField( record, ',', i, field(i), .false. )
          enddo

        ! build new record 
        record = TRIM(field(1))
        Do i=2,nfields

          ! check if next field is an invalid flag
          if( i<nfields ) then
            flagname = TRIM(header(i)) // '_f'
            if( flagname .eq. header(i+1) ) then
              if( INDEX('#IJKLMNF', field(i+1)(1:1) ) .gt. 0 ) field(i) = '-999'
              endif
            endif

          record = TRIM(record) // ',' // TRIM(field(i))

          if( i.eq.kdate ) then
            pos = index(field(i), ':00:00"')
            if(pos.eq.0) then
              Write(*,'('' **ERROR** Cannot find :00:00 in field:'',a)') TRIM(field(i))
              stop
              endif
            datefld = field(i)(1:pos) // '59:59"'
            record = TRIM(record) // ',' // TRIM(datefld)
            endif

          enddo

        Write(out,'(a)') TRIM(record)

        endDo
           

      ! close files and exit
      Close(unit=in)
      Close(unit=out)
      Stop

501   Write(*,'(''Error opening input file'')')
      Stop

502   Write(*,'(''Error opening output file'')') 
      Stop

      End Program cast2ext


