CMAQv5.0.2 DDM-3D User's Guide: https://www.airqualitymodeling.org/index.php/CMAQv5.0.2_Direct_Decoupled_Method 

************************************************

16 March 2015: Sergey L. Napelenok --- Aerosol sensitivity code was updated to ensure stability and robustness for fine-scale application.  Propagating sensitivity through some ISSOROPIA cases were found to be unstable under certain conditions.  These cases were replaced with solutions for a more simple ion system.  Other minor changes were made to how small numbers were handled by the sensitivity code.  Furthermore, sensitivity to activity coefficients was found to function improperly and was disabled.  Finally, updates to sensitivity of minor ions in aqueous chemistry were also disable to further ensure stable solution. 

List of changed modules: 

aero_sens.F  
aqchem.F  
ddmsens.f  
isofwd.f

************************************************

8 September 2014: Sergey L. Napelenok --- Minor changes to cloud module, aerosol, module, chemistry driver, and sensitivity interface file to prevent instability on some platforms, particularly with the gfortran compiler. 

List of changed modules:

acmcld.F  
aqchem.F  
hrdriver.F  (CB05TUCL, SAPRC07TC, SAPRC99)
convcld_acm.F  
dact.inc  
ddmsens.f  
hddmsens.f  
sinput.F
