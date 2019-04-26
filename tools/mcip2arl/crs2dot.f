
! RCS file, release, date & time of last delta, author, state, [and locker]
! $Header: /nas01/depts/ie/cempd/apps/CMAQ/v5.0.1/CMAQv5.0.1/models/TOOLS/src/mcip2arl/crs2dot.f,v 1.1.1.1 2012/04/19 19:48:37 sjr Exp $

SUBROUTINE crs2dot (varcrs, vardot)

!-------------------------------------------------------------------------------
! Name:     Cross to Dot 
! Purpose:  Interpolates in horizontal from cross to dot points.
! Notes:    Based on PSU/NCAR model routine.
! Revised:  20 Apr 1999  Original version.  (TLO)
!           29 Oct 1999  Converted to free-form f90.  (TLO)
!           23 Nov 2005  Assume grid dimensions different by one for dot & crs
!-------------------------------------------------------------------------------

  IMPLICIT NONE

  REAL,            INTENT(IN)  :: varcrs ( : , : )
  REAL,            INTENT(OUT) :: vardot ( : , : )

  INTEGER                      :: ix, jx, ie, je, i, j

!-------------------------------------------------------------------------------
! Extract domain dimensions (vardot is always one larger in x and y)
!-------------------------------------------------------------------------------

  ix = SIZE(varcrs,1)
  jx = SIZE(varcrs,2)

  ie = ix - 1
  je = jx - 1

!-------------------------------------------------------------------------------
! For interior of grid, interpolate cross point values to dot points using
! four-point interpolation.
!-------------------------------------------------------------------------------

  DO j = 2, jx
    DO i = 2, ix
      vardot(i,j) = 0.25 * ( varcrs(i,j)   + varcrs(i-1,j)  &
                           + varcrs(i,j-1) + varcrs(i-1,j-1) )
    END DO
  END DO

!-------------------------------------------------------------------------------
! For outermost rows and columns, interpolate cross point values to dot points
! using two-point interpolation.  In row and column 1, there are no cross points
! below or to the left of the dow row that is being interpolated.  In row JX
! and column IX, cross points are not defined.
!-------------------------------------------------------------------------------

  DO i = 2, ix
    vardot(i,1)  = 0.5 * ( varcrs(i,1)  + varcrs(i-1,1)  )
    vardot(i,jx) = 0.5 * ( varcrs(i,jx) + varcrs(i-1,jx) )
  END DO

  DO j = 2, jx
    vardot(1, j) = 0.5 * ( varcrs(1, j) + varcrs(1, j-1) )
    vardot(ix,j) = 0.5 * ( varcrs(ix,j) + varcrs(ix,j-1) )
  END DO

!-------------------------------------------------------------------------------
! Define dot point corners and persist last row and column.
!-------------------------------------------------------------------------------

  vardot(1,   1   ) = varcrs(1, 1)
  vardot(ix+1,jx+1) = varcrs(ie,je)

  vardot(ix+1,1:jx) = varcrs(ix,:)
  vardot(1:ix,jx+1) = varcrs(:,jx)

  RETURN

END SUBROUTINE crs2dot
