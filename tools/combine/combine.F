
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
! $Header: /nas01/depts/ie/cempd/apps/CMAQ/v5.0.1/CMAQv5.0.1/models/TOOLS/src/combine/combine.F,v 1.1.1.1 2012/04/19 19:48:37 sjr Exp $
 
      PROGRAM COMBINE
C***********************************************************************
C  This program combines variables from a set of IOAPI input files
C  to an output file.  The file assigned to environmental variable
C  SPECIES_DEF  defines the new species variables and how they
C  are constructed.
C
C  Environmental variables used
C      SPECIES_DEF --> Species definition file defining the new
C                      variables of the output file
C      INFILE1     --> input file number 1, (max of 9)
C      OUTFILE     --> IOAPI output file name
C      GENSPEC     --> Indicates to generate a species definition file
C                      from INFILE1     
C
C   record type descriptions in SPECIES_DEF file
C     / records are comment lines
C     # records can be used to define parameters
C              #start   YYYYDDD  HHMMSS (default is start of INFILE1)
C              #end     YYYYDDD  HHMMSS (default is end of dataset)
C              #layer      KLAY     (default is all layers)
C
C     All other records are read as variable definition records 
C     
C   format of variable definition records (comma seperated fields)  
C     field 1: variable name (maximun of 16 characters)
C     field 2: units (maximum of 16 characters)
C     field 3: formular expression (maximun of 512 characters)
C
C
C     Note:  Formular expressions supports operators +-*/ and are
C            evaluated from left to right using precedence order of */+-.  
C            Order of evaluation can be forced by use of parentheses.
C            When part of an experssion is enclosed in parentheses, that
C            part is evaluated first.  Variables from input file are
C            defined by their name followed by it's file number enclosed
C            in brackets.
C
C 
C***********************************************************************

      USE SPEC_DEF
      USE M3FILES
      USE EVALUATOR

      USE M3UTILIO

      IMPLICIT NONE     


C...External functions
      LOGICAL FLUSH3  

C...Local Variables
      Integer status
      Character*(256) specFile
      Integer logdev, istat
      Integer n, isize
      Logical kswit

      Real, Allocatable :: buffer(:)


C...start IOAPI
      LOGDEV = INIT3()
      WRITE( *, '('' API Started'')' )

C...get environment variables for input file names     
      Call NAMEVAL( 'SPECIES_DEF', specFile )

C...check GENSPEC to generate new species definition file
      if( ENVYN('GENSPEC', 'Generate new species definition file',
     &           .FALSE., status) ) then
         Call GENSPEC( specFile )
         Stop
         Endif

C...read and load species definition file
      Call readSpec( specFile, status )
      if( status.ne.0 ) then
        Write(*,'(''**ERROR** Cannot open or read SPECIES_DEF file:'',a)')
     &            TRIM(specFile)
        Stop
        endif

C...open M3FILES
      Call OPEN_M3FILES()
      if( N_M3FILES.eq.0 ) then
        Write(*,'(''**ERROR** Cannot open IOAPI file:'',a)')
     &        M3FILENAME(1)
        Stop
        endif  

C...  build description of output file
      TSTEP3D = TSTEP
      SDATE3D = startDate
      STIME3D = startTime
      NVARS3D = numSpec
      if( Klayer .gt. 0)  then
        NLAYS3D = 1
        NLAYS = 1
        endif

      do n = 1, numSpec
        VNAME3D( n ) = specName( n )
        UNITS3D( n ) = specUnits( n )
        VDESC3D( n ) = specDesc( n )
        VTYPE3D( n ) = M3REAL
        enddo

C...try to create new file. if error, open file as old 
      if( .NOT. OPEN3( 'OUTFILE', 3, 'COMBINE' ) ) THEN
        if( .NOT. OPEN3( 'OUTFILE', 2, 'COMBINE' ) ) THEN
          WRITE( *, '(''**ERROR** while openning OUTFILE'')' )
          KSWIT = SHUT3()
          stop 
          endif
        endif 

C...fill Description Common Block
      if( .NOT.  DESC3( 'OUTFILE' ) ) THEN
        WRITE( *, '(''**ERROR** WHILE RUNNING DESC3 ON OUTFILE'')' )
        KSWIT = SHUT3()
        stop 
        endif

C...compare grid values with input file
      KSWIT = .true.
      IF ( NROWS .NE. NROWS3D ) KSWIT = .false.
      IF ( NCOLS .NE. NCOLS3D ) KSWIT = .false.
      IF ( NLAYS .NE. NLAYS3D ) KSWIT = .false.
      IF ( TSTEP .NE. TSTEP3D ) KSWIT = .false.
      IF ( XCELL .NE. XCELL3D ) KSWIT = .false.
      IF ( YCELL .NE. YCELL3D ) KSWIT = .false.
      IF ( ABS(XORIG-XORIG3D) .gt. 0.1 ) KSWIT = .false.
      IF ( ABS(YORIG-YORIG3D) .gt. 0.1 ) KSWIT = .false.

      if( .NOT.KSWIT ) then
        WRITE( *, '(''**ERROR** Inconsistenece file parameters'',
     &        '' for OUTFILE'')' )
        write(*,'(''NROWS='',2i8)') NROWS, NROWS3D
        write(*,'(''NCOLS='',2i8)') NCOLS, NCOLS3D
        write(*,'(''NLAYS='',2i8)') NLAYS, NLAYS3D
        write(*,'(''TSTEP='',2i8)') TSTEP, TSTEP3D
        write(*,'(''XCELL='',2f16.2)') XCELL, XCELL3D
        write(*,'(''YCELL='',2f16.2)') YCELL, YCELL3D
        write(*,'(''XORIG='',2f16.2)') XORIG, XORIG3D
        write(*,'(''YORIG='',2f16.2)') YORIG, YORIG3D
        KSWIT = SHUT3()
        stop 
        endif

c...allocate memory for buffer array
      isize = NCOLS3D * NROWS3D * NLAYS3D
      Allocate( buffer( isize ), stat=istat )
      if( istat.ne.0 ) then
        write(*,'(''**ERROR** Cannot allocate array of size'',i12)') isize
        stop
        endif

C...start time loop 
      Do
        write(*, '('' Copying Variables at time:'',i7,'':'',i6)' )
     &    startDate, startTime

        DO n = 1, numSpec

          Call evaluate(specExpression(n), startDate, startTime,
     &                  Klayer, isize, buffer)

          ! write species record to outfile
          if(.NOT.WRITE3('OUTFILE', specName(n), startDate,
     &                   startTime, buffer) ) THEN
            write( *, '('' **Error** Cannot write to OUTFILE at'',2i8)')
     &            startDate, startTime
            KSWIT = SHUT3()
            stop 
            endif

           KSWIT = flush3('OUTFILE')
          enddo

        ! if no time step, exit after one step
        if( TSTEP.le.0 ) exit

        ! advance to next step
        call NEXTIME ( startDate, startTime, TSTEP )
        if( SECSDIFF(startDate, startTime, endDate, endTime) .lt. 0 )
     &     exit

        enddo       

C... shut down netcdf
      KSWIT = SHUT3()
      WRITE(*,'('' API Shut down'')')
      STOP
      END






