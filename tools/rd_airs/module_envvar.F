
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
! $Header: /nas01/depts/ie/cempd/apps/CMAQ/v5.0.1/CMAQv5.0.1/models/TOOLS/src/rd_airs/module_envvar.F,v 1.1.1.1 2012/04/19 19:48:37 sjr Exp $

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c   Module for reading the environment variables used for this program
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      MODULE ENV_VARS


      CHARACTER*256  SITE_FILE              ! Site info file

      CHARACTER*256  IN_FILE                ! Input Data file

      CHARACTER*256  OUT_FILE               ! Output file

      INTEGER        YEARS(20)              ! list of years to process
      CHARACTER*2   STATES(20)              ! list of States to process

      CHARACTER*5   PARAMETER               ! parameter code

      CHARACTER*1   TIMEINTVL               ! time interval code

      LOGICAL       CHECKUNITS              ! switch to verify units

      Integer       UNITSCODE               ! units code for checking

      INTEGER NSTATES
      INTEGER NYEARS

      CONTAINS

C*************************************************************************
C  FUNCTION:  To get environment variables            
C*************************************************************************
         SUBROUTINE GET_ENVS
 
         Use m3utilio

         IMPLICIT NONE 

C..SCRATCH LOCAL VARIABLES:
         INTEGER LOGUNIT
         LOGICAL LERROR
         INTEGER STATUS   
         CHARACTER*2  STATEABRS(20)  
         INTEGER I
   
         LERROR = .FALSE. 

         LOGUNIT = init3()

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Get the name of the input data file
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc      
         CALL ENVSTR( 'INFILE', 'input data file', '', IN_FILE, STATUS)

         IF( STATUS .NE. 0 ) THEN
            CALL M3MESG( 'ERROR: no file name assigned to INFILE' )
            LERROR = .TRUE.
         ENDIF

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Get the name of the site file
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc      
         CALL ENVSTR( 'SITEFILE', 'Site File', '', SITE_FILE, STATUS)

         IF( STATUS .NE. 0 ) THEN
            CALL M3MESG( 'ERROR: no file name assigned to SITEFILE' )
            LERROR = .TRUE.
         ENDIF

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Get the name of the output file
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc      
         CALL ENVSTR( 'OUTFILE', 'output File', 'output.dat', OUT_FILE, STATUS)

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Get the Check unit switch
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc      
         CHECKUNITS = ENVYN( 'CHECKUNITS', 'Verify units switch', .TRUE., STATUS)

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Get the Units Code        
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc      
         UNITSCODE = ENVINT( 'UNITSCODE', 'Units Code', 007, STATUS)

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Get the parameter code (default ozone 44201)
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc      
         CALL ENVSTR( 'PARAMETER', 'parameter code', '44201', parameter, STATUS)

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Get the time interval code (default is 1 hour)
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc      
         CALL ENVSTR( 'INTERVAL', 'time interval code', '1', timeIntvl, STATUS)


cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Get the list of state codes
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
       
         if( STRLIST('STATES','States to process', 20, NSTATES, STATEABRS) ) Then
           Call getStates( NSTATES, STATEABRS )
          Else           
           NSTATES = 0
           Endif 

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Get the list of years to process
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
         if( INTLIST('YEARS','Years to process', 20, NYEARS, YEARS) ) Then
           Do I=1,NYEARS
             YEARS(I) = MOD( YEARS(I), 100 )
             Enddo
          Else
           NYEARS = 0
           Endif



cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Stop if errors detected
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

         IF( LERROR ) THEN
           CALL M3ERR( 'GETENV', 0, 0, 
     &         'Error in assigning environment variables -- stopping', .TRUE. ) 
           ENDIF


         RETURN
         END SUBROUTINE GET_ENVS


cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  routine to build state codes from state abr
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc   
         Subroutine getStates(num, stateAbrs)

         Integer num
         Character*2 stateAbrs(*)

         Integer I, J
         Character*2 codes(56)

         Data codes/'AL','AK','xx','AZ','AR','CA','xx','CO','CT','DE',
     &              'DC','FL','GA','xx','HI','ID','IL','IN','IA','KS',
     &              'KY','LA','ME','MD','MA','MI','MN','MS','MO','MT',
     &              'NE','NV','NH','NJ','NM','NY','NC','ND','OH','OK',
     &              'OR','PA','xx','RI','SC','SD','TN','TX','UT','VT',
     &              'VA','xx','WA','WV','WI','WY'/ 

         Do I=1,num 
           call ucase(stateAbrs(I), 2) 
           States(I) = stateAbrs(I)
           Do J=1,56
             if( trim(stateAbrs(I)) .eq. codes(J) ) then
               Write(States(I),'(I2.2)') J
               EXIT           
               EndIf
             EndDo
           EndDo 

         write(*,'(/'' state abreviations:'',20a3)')( stateAbrs(i),i=1,num)   
         write(*,'( '' state codes:       '',20a3)')( states(i),i=1,num)   
         write(*,'(1x)')

         Return
         End Subroutine getStates

C***********************************************************************
C  Routine to change character string to upper characters
C***********************************************************************
      SUBROUTINE UCASE ( STR, NCHR )

      IMPLICIT NONE

      CHARACTER STR*( * )
      INTEGER NCHR
      INTEGER I
      INTEGER K

      DO I = 1, NCHR
        K = ICHAR(STR(I:I))
        IF ( ( K .GE. 97 ) .AND. ( K .LE. 122 ) )
     &    STR( I:I ) = CHAR( K - 32 )
      END DO

      RETURN
      END SUBROUTINE UCASE

      END MODULE ENV_VARS

