#!/bin/sh
#
# RCS file, release, date & time of last delta, author, state, [and locker]
# $Header: /nas01/depts/ie/cempd/apps/CMAQ/v5.0.1/CMAQv5.0.1/models/TOOLS/src/combine/combineAll.sh,v 1.1.1.1 2012/04/19 19:48:37 sjr Exp $ 
#
# what(1) key, module and SID; SCCS file; date and time of last delta:
# %W% %P% %G% %U%
#
#  example script for running the combine program on Unix
#
#  generates a new concentration file from output from the CMAQ model run
#

BASE=/project/model_evalb/extract_util

EXECUTION_ID=combine; export EXECUTION_ID

EXEC=${BASE}/bin/${EXECUTION_ID}.exe

## use GENSPEC switch to generate a new specdef file (does not generate output file)
   GENSPEC=N; export GENSPEC

## define name of species definition file
   SPECIES_DEF=spec_def.conc; export SPECIES_DEF

## define name of output file
   OUTFILE=out.conc; export OUTFILE

   YEAR=01
   MONTH=01

   for DAY in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31
   do

   INFILE1=${BASE}/cmaq_data/CCTM_J2a.CONC.20010101; export INFILE1
   INFILE2=${BASE}/cmaq_data/CCTM_J2a.AEROVIS.20010101; export INFILE2
   INFILE3=${BASE}/cmaq_data/METCRO3D_010101; export INFILE3
   INFILE4=${BASE}/cmaq_data/CCTM_J2a.AERODIAM.20010101; export INFILE4
   INFILE5=${BASE}/cmaq_data/METCRO3D_010101; export INFILE5

      echo running combine with INFILE = ${INFILE1}
      ${EXEC}
   done

   echo runs competed with output file = $OUTFILE

