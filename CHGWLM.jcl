//CHGWLMS  JOB MSGLEVEL=(1,1),MSGCLASS=H,CLASS=A,REGION=0M,             00010001
//  NOTIFY=&SYSUID                                                      00020001
//***********************************************************//         00030001
//*                                                         *//         00040001
//* FUNCTION: EXECUTE CHGWLM EXEC                           *//         00050001
//*                                                         *//         00060001
//* INPUT: IN THE ORDER OF THE FOLLOWING PARAMETERS         *//         00061002
//*      1. %CHGWLM - REXX EXEC NAME                        *//         00061103
//*      2. TEST/NOTEST                                     *//         00061203
//*          - TEST: DISPLAY CURRENT SETTING                *//         00061303
//*          - NOTEST: CHANGE CURRENT SETTING               *//         00061403
//*      3. REQUEST COUNT                                   *//         00061503
//*          - TOTAL NUMBERS OF LPARS FOR THE CHANGE REQUEST*//         00061603
//*      4. FOR EACH LPAR:                                  *//         00061703
//*       4A. TARGET TYPE ( 1 OR 2)                         *//         00061803
//*            - 1 FOR LPAR (CHANGE DYNAMCIALLY)            *//         00061903
//*            - 2 FOR ACTIVATION PROFILE                   *//         00062003
//*       4B. TARGET NAME:                                  *//         00062103
//*       4C. WLM VALUE TO BE CHANGED TO                    *//         00062203
//*                                                         *//         00062402
//*                                                         *//         00067602
//* POSSIBLE ERRORS:                                        *//         00068304
//*                                                         *//         00068404
//*    JCL ERROR: UNRECOVERABLE COMMAND SYSTEM ERROR        *//         00068504
//*      - CHECK CONTINUATION DASHES IN THE SYSTSIN DD      *//         00068604
//*                                                         *//         00068704
//*    RETURN CODE OF 'F02'X FROM BCPII API                 *//         00068804
//*      - UPDATE ACCESS IS NEEDED TO SET WLM               *//         00068904
//*      - ENSURE USERID IS IN THE PROPER RACF GROUP OR HAS *//         00069004
//*        AT LEAST UPDATE ACCESS TO THE FACILITY CLASS FOR *//         00069104
//*        THE TARGET(S)                                    *//         00069204
//*                                                         *//         00069204
//*---------------------------------------------------------*//         00071004
//*                                                                     00071104
//  SET  OUTMEM=DTYYMMDD                                                00071204
//*                                                                     00071304
//CHGWLM    EXEC PGM=IKJEFT01,DYNAMNBR=30,REGION=4096K                  00071404
//SYSEXEC   DD   DSN=MYHLQ.REXX,DISP=SHR                                00071504
//SYSPRINT  DD  SYSOUT=A                                                00071604
//SYSTSPRT DD   SYSOUT=A                                                00071704
//CONFGDD1 DD DISP=SHR,DSN=MYHLQ.CNTL.DATA(CONFGCP1)                    00071804
//CONFGDD2 DD DISP=SHR,DSN=MYHLQ.CNTL.DATA(CONFGCP2)                    00071904
//CONFGDD3 DD DISP=SHR,DSN=MYHLQ.CNTL.DATA(CONFGCP3)                    00072004
//RXOUTDD  DD DISP=SHR,DSN=MYHLQ.CNTL.REXX.OUTPUT(&OUTMEM)              00072104
//SYSTSIN   DD   *                                                      00072604
 %CHGWLM NOTEST 15        -                                             00073004
                 1 IMGA 0 -                                             00080001
                 1 IMGB 0 -                                             00080001
                 1 IMGC 0 -                                             00080001
                 1 IMGD 0 -                                             00080001
                 1 IMGE 0 -                                             00080001
                 1 IMGF 0 -                                             00080001
                 1 IMGG 0 -                                             00080001
                 1 IMGH 0 -                                             00080001
                 1 IMGI 0 -                                             00080001
                 1 IMGJ 0 -                                             00080001
                 1 IMGK 0 -                                             00080001
                 1 IMGL 0 -                                             00080001
                 1 IMGM 0 -                                             00080001
                 1 IMGN 0 -                                             00080001
                 1 IMGO 0                                               00080001
                                                                        00140001
/*                                                                      00150001
