# Dynamically-Enable-or-Disable-WLM
* **Introduction** 

  Are you tired of doing repetitive LPAR control updates from the HMC/SE?  If your sysplex is like ours, having 15 or more LPARs on a PLEX, you would be as excited as me hearing about how we use APIs to dynamically update a LPAR control value for 15 LPARs without logging on to the HMC/SEs.  In our organization,  we perform test runs very frequently.  In order to perform test runs in a more consistent environment and have the result data not be impacted by processing related weight changes, we like to run our tests with the WLM disabled in most cases.  Having a job to dynamically disable the WLM for all our target systems and later to restore the old values back are extremely convenient and efficient.

  This repository provides a sample REXX EXEC [CHGWLM.rexx](https://github.com/lowenho/Dynamically-Enable-or-Disable-WLM/blob/main/CHGWLM.rexx) to demonstrate how we use a few APIs from z/OS BCPii to change the WLM (Workload Manager Enabled Capping values) for multiple LPARs on a PLEX all at once   The REXX EXEC is made flexible to be executed either in TSO foreground or in background (Batch) via a JCL which may be more preferrable for repetitive tasks or automation.  More good news is that these APIs are free for all z/OS users.  They are provided by the z/OS BCPii component which comes with z/OS.  Its address space comes up at IPL as long as you have the proper installation.  For more information on the BCPii set up, please see the BCPii installation section from https://www.ibm.com/docs/en/zos/2.1.0?topic=services-base-control-program-internal-interface-bcpii.   


* **Files** 
 
  [CHGWLM.rexx](https://github.com/lowenho/Dynamically-Enable-or-Disable-WLM/blob/main/CHGWLM.rexx) : REXX EXEC to process the request to change the current WLM value for one or more targets 
  
  [CHGWLM.jcl](https://github.com/lowenho/Dynamically-Enable-or-Disable-WLM/blob/main/CHGWLM.jcl) : JCL to invoke the CHGWLM EXEC to run in TSO background, having the input parameters specified in the SYSTSIN DD. 

  [CONFGCP1.txt](https://github.com/lowenho/Dynamically-Enable-or-Disable-WLM/blob/main/CONFGCP1.txt), [CONFGCP2.txt](https://github.com/lowenho/Dynamically-Enable-or-Disable-WLM/blob/main/CONFGCP2.txt), [CONFGCP3.txt](https://github.com/lowenho/Dynamically-Enable-or-Disable-WLM/blob/main/CONFGCP3.txt) : System configuration files for each CPC.   
  
  
   Notes: These files are used as input data for the EXEC to learn about the current system configuration and the target names.  Having these files defined outside of the EXEC make it flexible to be used by different environments.
    
* **Input**

  For TSO foreground users:  Use the ‘EX’ execute command, input will be prompted  
 
  For TSO background users: See the sample input from the SYSTSIN DD in the [CHGWLM.jcl](https://github.com/lowenho/Dynamically-Enable-or-Disable-WLM/blob/main/CHGWLM.jcl) file.
  
  Note: A test mode parameter can be specified to only retrieve the current WLM value without performing the change request. This is useful when you are not sure whether a change is needed although the EXEC will not process the change request when the current value is the same as the value to be changed. For TSO foreground users, input will be prompted.  For TSO background users, specify 'TEST' or 'NOTEST' as the first parameter.    

* **Output**

   The original and changed WLM values will be displayed for each target. Please see the sample output in the prolog section in [CHGWLM.rexx](https://github.com/lowenho/Dynamically-Enable-or-Disable-WLM/blob/main/CHGWLM.rexx).  
   
* **Dependencies**

    Proper environment set up, including RACF settings to use the z/OS BCPii APIs is required. 
    Proper BCPii permission on the SE(s) is also required for the target CPCs and LPARs 
    For details, please see https://www.ibm.com/docs/en/zos/2.4.0?topic=bcpii-setup-installation or the "BCPii setup and installation" in the BCPii chapter from the MVS Programming: Callable Services for High-Level Languages publication. 
    
