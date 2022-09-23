/* REXX */
/*------------------------------------------------------------------*/
/*                                                                  */
/* This EXEC is provided as an example and for tutorial purposes    */
/* ONLY.  It has not been submitted for formal IBM tests and it is  */
/* distributed on an 'AS IS' basis without any warranties either    */
/* expressed or implied.                                            */
/*                                                                  */
/* Description: Change the WLM Enable capping value for one or more */
/*              LPAR target(s) which can be LPAR or image           */
/*              activation profile.                                 */
/*                                                                  */
/*              Supported in TSO foreground or background via JCL   */
/*                                                                  */
/*  Assumption: If the target is an image activation profile,       */
/*              the exec assumes the activation profile name is     */
/*              the same as the image name.                         */
/*                                                                  */
/*              Note: this exec self-detects the parent CPC name    */
/*                    based upon the system configuration files     */
/*                                                                  */
/*  Sample output:                                                  */
/*                                                                  */
/*               WLM Change Report          18 Mar 2022 08:57:08    */
/*               ******************                                 */
/*                                                                  */
/*       SYSID     TYPE WLM       Time    Stage                     */
/*       ----- -------- --- ---------- --------                     */
/*       IMGA       LPAR   0   08:57:08     Orig                     */
/*       IMGA       LPAR   1   08:57:26  Changed                     */
/*                                                                  */
/*       IMGB       LPAR   0   08:57:31     Orig                     */
/*       IMGB       LPAR   1   08:57:49  Changed                     */
/*                                                                  */
/*       IMGC       LPAR   0   08:57:53     Orig                     */
/*       IMGC       LPAR   1   08:58:09  Changed                     */
/*                                                                  */
/*       IMGD    PROFILE   0   08:58:12     Orig                     */
/*       IMGD    PROFILE   1   08:58:26  Changed                     */
/*                                                                  */
/*       CHGWLM: Change WLM request completed! 18 Mar 2022 09:00:05 */
/*                                                                  */
/*                                                                  */
/*  Function/Code flow:                                             */
/*    - Process input parameters and save them as                   */
/*      InTestMode RequestCount InTGT_Name. InWLM.                  */
/*                                                                  */
/*    - For each LPAR target                                        */
/*       - Call BCPii Connect API to connect to the LPAR and its CPC*/
/*         Note: The parent CPC name is obtained from the input     */  
/*               system configuration file and the LPAR name will   */
/*               also be validated using the configuration file     */  
/*                                                                  */
/*       - Using the return connection tokens:                      */
/*         - Call Get_WLM to obtain the original WLM value          */
/*                                                                  */
/*       - If NOT running in test mode                              */
/*         - Call SetWLMValue to set the WLM with the input set     */
/*           value                                                  */
/*                                                                  */
/*         - Besides checking RC=0, as a sanity check               */
/*           Get_WLM to verify the returned WLM match to the input  */
/*           WLM value                                              */
/*                                                                  */
/*  Execution:                                                      */
/*   Run in TSO foreground:                                         */
/*      Execute 'ex' from command line                              */
/*          You will be prompted for input:                         */
/*           -Test mode : Enter 'N' to override or any other key to */
/*                        continue                                  */
/*           - # of requests, i.e. # of LPAR target for the request */
/*           - LPAR target, WLM value to be changed                 */
/*                                                                  */
/*   Run in TSO background via JCL using IKJEFT01                   */
/*                                                                  */
/*  Dependencies:                                                   */
/*    1. Proper environment set up to run z/OS BCPii APIs to run    */
/*       REXX EXECs                                                 */
/*    2. Proper RACF settings to use the z/OS BCPii APIs            */
/*    3. Proper BCPii permission settings on the SE(s)              */
/*                                                                  */
/*    See the 'BCPii setup and installation' in the BCPii chapter   */
/*    from the MVS Programming: Callable Services for High-Level    */
/*    Languages publication for details                              */
/*                                                                  */
/*    OR                                                            */
/*                                                                  */
/*    https://www.ibm.com/docs/en/zos/2.4.0?topic=bcpii-setup-      */
/*    installation                                                  */
/*                                                                  */
/*------------------------------------------------------------------*/
parse upper arg inParm
 
/* Based on the number of parameters to determine if this exec runs
   in foreground TSO or batch from JCL
*/
NumOfParms = WORDS(inParm)
 
CPC_Count = 3   /* Default to process for CPC1, CPC2 and CPC3 */
PgmTestMode = 1 /* When ON, no weight will be changed */
lineIndex = 0
 
Select
 /* Running in TSO foreground, prompting fIr input parms
 */
 When NumOfParms = 0 Then
  Do
   Say ' '
   Say ' '
   Say ' '
   Say ' '
   Say ' '
   Say ' ====> THIS EXEC IS DEFAULT TO RUN IN TEST MODE !'
   Say '       ------------------------------------------'
   Say ' '
   Say '    ===> Enter 'N' to override the test mode (to perform '||,
                 'change WLM request'
   Say ' '
   Say '    ===> OR hit any key to continue with TEST MODE! '
   Say ' '
   PARSE UPPER PULL InTestMode
   If InTestMode = 'N' Then
     PgmTestMode = 0 /* User overrides the test mode */
 
   Say ' ====> Enter # of request to set the WLM value(s)? '
   Say ' '
   PARSE UPPER PULL RequestCount
 
   If DATATYPE(RequestCount,'N') ^= 1 | RequestCount <= 0 Then
    Do
     Say
     Say 'CHGWLM: Program aborted! ERROR: Request count must ',
     Say '          be numeric and greater than zero '
     Say
     Exit 8
    End
   Else
    rqi.0 = RequestCount
 
   Do rqi = 1 to rqi.0
    Say ' ====> Enter Target Type: "1" for LPAR'
    Say ' ====>                    "2" for Image activation profile'
    Say ' '
 
    PARSE UPPER PULL InTarget_Type.rqi
 
    If InTarget_Type.rqi ^= 1 & InTarget_Type.rqi ^= 2 Then
     Do
      Say
      Say 'CHGWLM: Program aborted! ERROR: Target Type value '||,
                    'must be 1 or 2'
      Say
      Exit 8
     End
    Else
     Do
      If InTarget_Type.rqi = 1 Then
       Do
        Say ' ====> Enter an LPAR NAME #'||rqi
        InTarget_TypeText.rqi = "LPAR"
       End
      Else
       Do
        Say ' ====> Enter an Image Activation Profile Name #'||rqi
        InTarget_TypeText.rqi = "PROFILE"
       End
      Say ' '
 
      PARSE UPPER PULL InTarget_Name.rqi
 
      If InTarget_Name.rqi ^= '' Then
       Do
        If PgmTestMode = 0 Then
         Do
          Say ' ====> ENTER WLM VALUE (0 or 1) to set for '|| ,
           InTarget_TypeText.rqi ||' '||InTarget_Name.rqi||' #'rqi
          Say ' '
          PARSE UPPER PULL InWLMValue.rqi
          If InWLMValue.rqi  ^= 0 & InWLMValue.rqi ^= 1 Then
            Do
             Say
             Say 'CHGWLM: Program aborted! ERROR: Value must be 0 or 1'
             Say
             Exit 8
            End
         End /* End if PgmTestMode = 0 */
       End /* End if InTarget_Name.rqi ^= '' */
      Else
       Do
        Say
        Say 'CHGWLM: Program aborted! ERROR: Null value is detected'
        Say
        Exit 8
       End /* End Else if InTarget_Name.rqi ^= '' */
     End /*End Else if InTarget_Type */
   End /* End do rqi */
 
   Batch = 0
   ConfigFile.1 = 'MYHLQ.CNTL.DATA(CONFGCP1)'
   ConfigFile.2 = 'MYHLQ.CNTL.DATA(CONFGCP2)'
   ConfigFile.3 = 'MYHLQ.CNTL.DATA(CONFGCP3)'
  End /* End when NumOfParms = 0 */
 
 /*----------------------------------------------------------------*/
 /* Running in TSO background, i.e. via JCL                        */
 /*  Expected parms in the following order:                        */
 /*                 RequestCount                                   */
 /*                 Target Name.1 WLMValueToBeSet.1                */
 /*                 Target Name.2 WLMValueToBeSet.2                */
 /*                                                                */
 /*  Note: Unlike running in TSO forground, when running via JCL,  */
 /*        even though the PgmTestMode flag is on, the weight      */
 /*        values being set are expected in the input parameters   */
 /*----------------------------------------------------------------*/
 When NumOfParms > 0 Then
  Do
   Batch = 1
 
   /* Set total numbers of parameters
   */
   ParmCount = WORDS(inParm)
 
   /* Set # of LPAR requests (i.e value of first parm)
   */
   InTestMode   = WORD(inParm,1)
   RequestCount = WORD(inParm,2)
 
   Select
    When InTestMode = 'TEST'   Then PgmTestMode = 1
    When InTestMode = 'NOTEST' Then PgmTestMode = 0
    Otherwise
     Do
      Say
      Say 'CHGWLM: Program aborted! ERROR: Specify TEST or NOTEST '||,
          'for the first parameter!'
      Say
      Exit 8
     End
   End
 
   /* Validate the request count is numeric and greater than zero
   */
   If DATATYPE(RequestCount,'N') ^= 1 | RequestCount <= 0 Then
    Do
     Say
     Say 'CHGWLM: Program aborted! ERROR: Request count must be numeric'
     Say '        and greater than zero '
     Say
     Exit 8
    End
   Else
    Do
     /* Validate correct # of parameters are passed
        Add 2 for the TestMode and RequestCount
     */
     ExpectedParmCount = (RequestCount * 3) + 2
     If ParmCount ^= ExpectedParmCount Then
      Do
       Say
       Say 'CHGWLM: Program aborted! ERROR: Incorrect # of parms! '
       Say '        Expected:' ExpectedParmCount ||' Actual: '||,
                    ParmCount
       Say
       Exit 8
      End
     Else
     rqi.0 = RequestCount
    End
 
   wi = 2   /* Initialize the word index */
 
   /* Read the parameter lists and set the input parameters
   */
   Do rqi = 1 to rqi.0
     wi = wi + 1
     InTarget_Type.rqi = WORD(inParm,wi)
 
     If InTarget_Type.rqi ^= 1 & InTarget_Type.rqi ^= 2 Then
      Do
       Say
       Say 'CHGWLM: Program aborted! ERROR: Target Type value '||,
                     'must be 1 or 2 for word#'||wi
       Say
       Exit 8
      End
     Else
      Do
       If InTarget_Type.rqi = 1 Then
        InTarget_TypeText.rqi = "LPAR"
       Else
        InTarget_TypeText.rqi = "PROFILE"
      End
 
     wi = wi + 1
     InTarget_Name.rqi = WORD(inParm,wi)
 
     /* Sanity check to make sure Target Name is not numeric
     */
     If DATATYPE(InTarget_Name.rqi,'N') ^= 1 Then
      Do
       wi = wi + 1
       InWLMValue.rqi = WORD(inParm,wi)
       If InWLMValue.rqi ^= 1 & InWLMValue.rqi ^= 0 Then
        Do
         Say
         Say 'CHGWLM: Program aborted! ERROR: WLM Value must be '||,
             '0 or 1 for word#'||wi
         Say
         Exit 8
        End
      End /* End if DATATYPE(InTarget_Name.rqi,'N') */
     Else
      Do
       Say
       Say 'CHGWLM: Program aborted! ERROR: LPAR name is expected '||,
         'for word #'||wi
       Say
       Exit 8
      End
   End /* End do rqi */
  End /* End when NumOfParms > 0 */
 
 Otherwise
  Do
   say '*** Unexpected parms, program aborted **  '
   exit 8
  End
End /* End Select */
 
/*------------------------------------------------------------*/
/* Constants                                                  */
/*------------------------------------------------------------*/
CPC.0 = CPC_Count
today = date(S)
If Batch = 0 Then
 OutMemName = 'WL'||Substr(today,3,6)
outfile = 'MYHLQ.CNTL.REXX.OUTPUT('||OutMemName||')'
 
 
/*============================================================*/
/*============================================================*/
/*                                                            */
/*                        MAINLINE                            */
/*                                                            */
/*============================================================*/
/*============================================================*/
Global_RC = 0
ReportHeaderDone = 0
FailedTarget.0 = 0
fi = 0  /* Failing index */
 
/* Copy the BCPii constants to this exec
*/
Call GetBCPiiConstants
 
/* Process one Target at a time, using the previously set parameters
   which are in stem variables of InTarget_Name and InWLMValue.
*/
Do rqi = 1 to rqi.0   /* request index: For each target LPAR */
 
 CPCConnectToken = 0
 TargetConnectToken = 0
 
 /* Call BCPii API to connect to CPCs and Targets
 */
 Call ConnectToTarget InTarget_Name.rqi,InTarget_Type.rqi
 
 TargetToken.rqi = TargetConnectToken
 
 CPCToken.rqi = CPCConnectToken
 
 If Global_RC = 0 Then
   Do
    /* Write a blankline in the output report between each request
       except for the first request for visibility
    */
    If rqi > 1 & pgmTestMode = 0 Then
     Do
      lineIndex = lineIndex + 1
      outLine.lineIndex = ' '
     End
 
    EachSetRequstRC.rqi = 0 /* each set request has its own RC */
    fp_GetOrig = 1       /* Setting foot print */
 
    /* Call to obtain the original weight values
    */
    Call Get_WLM TargetToken.rqi,InTarget_TypeText.rqi
    OrigTargetName.rqi = RtnTargetName
    OrigWLMValue.rqi = RtnWLMValue
 
    fp_GetOrig = 0   /* Reset foot print */
 
    /* If not running Test mode, proceed to perform SET request
    */
    If PgmTestMode = 0 Then
     Do
      If InWLMValue.rqi = OrigWLMValue.rqi Then
       Do
     /* fp_NoChange = 1 */
        lineIndex = lineIndex + 1
        outLine.lineIndex = ,
          LEFT(OrigTargetName.rqi,5),
          RIGHT(InTarget_TypeText.rqi,8),
          RIGHT(OrigWLMValue.rqi,3),
          RIGHT(Time(),10),
          RIGHT('NoChange',8)
       End
      Else
       Do
        Call SetWLMValue  ,
         CPCToken.rqi,TargetToken.rqi,InWLMValue.rqi,OrigWLMValue.rqi,
                             ,OrigTargetName.rqi
 
        /* If the SET request succeeds, call to obtain the current
           weight values and verify they were changed to the set values
        */
        If Global_RC = 0 & SET_RequestRC = 0 Then
         Do
          fp_Changed = 1
          Call Get_WLM TargetToken.rqi,InTarget_TypeText.rqi
 
 
          /* Check to make sure they were changed to the SET values
          */
          If RtnWLMValue = InWLMValue.rqi Then
            Do
             say 'CHGWLM: WLM value has been set '||,
                 'successfully for '|| OrigTargetName.rqi
            End
          Else
            Do
             /* The returned WLM values does not match to the value
                to be set, report the error
             */
             say
             say 'CHGWLM: ERROR: SET request failed for '|| ,
                  OrigTargetName.rqi
 
             say 'CHGWLM: WLM value Expected: '||InWLMValue.rqi||,
                  ' Actual: '||RtnWLMValue
 
             say
             Global_RC = 8
            End
         End
        Else
         Do
          If Global_RC ^= 0 Then
           say 'CHGWLM: Program RC = ' Global_RC
 
          /* Record the failing RC for the current Target and then
             set the failing Target name for error reporting later
          */
          If SET_RequestRC ^= 0 Then
           Do
            EachSetRequstRC.rqi = SET_RequestRC
 
            fi = fi + 1
            FailedTarget.fi = OrigTargetName.rqi
            FailedRC.fi    = EachSetRequstRC.rqi
 
            say 'CHGWLM:  Set request RC = ' EachSetRequstRC.rqi||,
                '('||d2x(EachSetRequstRC.rqi)||'x)'
           End
         End
       End /* End Else if PgmTestMode = 0 */
     End /* End if PgmTestMode = 0 */
   End /* End if Global_RC = 0 */
 
 If CPCConnectRC = 0 Then
  Call Disconnect CPCConnectToken
End /* End do */
 
/* Report failing requests
*/
FailedTarget.0 = fi
If FailedTarget.0 > 0 Then
 Do
  lineIndex = lineIndex + 1
  outLine.lineIndex = ' '
  lineIndex = lineIndex + 1
  outLine.lineIndex = ,
   '*** CHGWLM: ERROR: '||FailedTarget.0||' out of '||RequestCount||,
   ' Set requests FAILED:'
  lineIndex = lineIndex + 1
  outLine.lineIndex = ' '
 
  Do i = 1 to FailedTarget.0
   FailedRC.i = Strip(FailedRC.i,L,'0')
   HexRC = d2x(FailedRC.i)
   lineIndex = lineIndex + 1
   outLine.lineIndex = ,
       '*** CHGWLM: ERROR: Set request failed for '||FailedTarget.i||,
       '      RC = ' ||FailedRC.i||'('||HexRC||'x)'
  End
 End
 
lineIndex = lineIndex + 1
outLine.lineIndex = ' '
lineIndex = lineIndex + 1
outLine.lineIndex = 'CHGWLM: Change WLM request completed! '|| ,
                                                       Date() Time()
/* Send output to screen for foreground or send to sysout for
   background
*/
say
say
Do j = 1 to lineIndex
 say outLine.j
End
 
/* Write the output to the output DD
*/
Call WriteToOutputDD
 
finish:
 
 
If Batch = 0 Then
 Do
  say ' '
  say 'CHGWLM: Output is also saved in '|| outfile
 End
 
say
 
If Global_RC = 0 & FailedTarget.0 = 0 Then
 Do
  say 'CHGWLM: Program completed successfully '
 End
Else
 Do
  If Global_RC ^= 0 Then
  say 'CHGWLM: Program failed! RC = ' Global_RC||'('||,
        d2X(Global_RC)||'x)'
 Else
  say 'CHGWLM: Program failed! '
  Global_RC = 16
 End
 
Exit Global_RC
 
/*============================================================*/
/*============================================================*/
/*                                                            */
/*                  PROCEDURES                                */
/*                                                            */
/*============================================================*/
/*============================================================*/
 
/*-----------------------------------------------------------------*/
/*                                                                 */
/* Procedure: Get_WLM                                              */
/*   Call BCPii Query API to retrieve the WLM value for the input  */
/*   target                                                        */
/*                                                                 */
/*-----------------------------------------------------------------*/
Get_WLM:
 
 InConnectToken = arg(1)
 InTargetTypeText = arg(2)
 
 /* Set up the query parm for the HWIQuery API call
 */
 QueryParm.0 = 2
 QueryParm.1.ATTRIBUTEIDENTIFIER = HWI_NAME
 QueryParm.2.ATTRIBUTEIDENTIFIER = HWI_WLM     /* Initial weight */
 
 Call Query InConnectToken
 
 If Global_RC = 0 Then
  Do
   RtnTargetName = QueryParm.1.ATTRIBUTEVALUE
   RtnWLMValue   = QueryParm.2.ATTRIBUTEVALUE
  End
 
/* Return output data
*/
If ^ReportHeaderDone Then
 Do
  ReportHeaderDone = 1
  lineIndex = lineIndex + 1
  outLine.lineIndex = '                    WLM Change Report            ',
                      Date() Time()
  lineIndex = lineIndex + 1
  outLine.lineIndex = '                    ******************     '
  lineIndex = lineIndex + 1
  outLine.lineIndex = ' '
  If PgmTestMode = 1 Then
   Do
    lineIndex = lineIndex + 1
    outLine.lineIndex = ,
        'Program is in TEST mode, NO change was performed'
   End
  lineIndex = lineIndex + 1
  outLine.lineIndex = ' '
  lineIndex = lineIndex + 1
  outLine.lineIndex = ,
      'SYSID     TYPE WLM       Time    Stage'
  lineIndex = lineIndex + 1
  outLine.lineIndex = ,
      '----- -------- --- ---------- --------'
 End
 
If RtnWLMValue = 0 Then
 RtnWLMValue = 0
Else
 RtnWLMValue = STRIP(RtnWLMValue,'L',0)
 
Select
 When fp_GetOrig = 1 Then OutText = 'Orig'
 When fp_Changed = 1 Then OutText = 'Changed'
 /* When fp_NoChange = 1     Then OutText = 'NoChange' */
 Otherwise OutText = ' '
End
 
lineIndex = lineIndex + 1
outLine.lineIndex = ,
    LEFT(RtnTargetName,5),
    RIGHT(InTargetTypeText,8),
    RIGHT(RtnWLMValue,3),
    RIGHT(Time(),10),
    RIGHT(OutText,8)
 
Return /* Get_WLM */
 
/*-----------------------------------------------------------------*/
/* Procedure: SetWLMValue                                          */
/*   Call BCPii SET2 API to change the WLM value                   */
/*   for the input Target represented by the InTargetToken         */
/*                                                                 */
/* Input:                                                          */
/*                                                                 */
/*  InCPCToken: CPC connection token for the input Target          */
/*  InTargetToken : Target connection token, its WLM value is being*/
/*              changed                                            */
/*  InWLMValue: WLM value being changed to                         */
/*                                                                 */
/*  InOrigMin : Original WLM value being restored upon any failure */
/*  InName:   : Target name for reporting error                    */
/*                                                                 */
/* Output: None                                                    */
/*         'SET request completed successfully' message text       */
/*         will be issued                                          */
/*-----------------------------------------------------------------*/
SetWLMValue:
  InCPCToken    = arg(1)
  InTargetToken = arg(2)
  InWLMValue    = arg(3)
  InOrigWLM     = arg(4)
  InName        = arg(5)
 
  SET_RequestRC = 0
 
    SetParm.0 = 1
    SetParm.1.SET2_CTOKEN = InTargetToken
    SetParm.1.SET2_SETTYPE = HWI_WLM
    SetParm.1.SET2_SETVALUE = InWLMValue
 
    Call Set2 InCPCToken
 
    If Global_RC = HWI_OK Then
      Call WaitTime 10
    Else
     Do
      SET_RequestRC = Global_RC
      say
      say 'CHGWLM: ERROR: SET request failed for '||InName
     End
 
Return /* End SetWLMValue */
 
/*------------------------------------------------------------*/
/*                                                            */
/* Procedure: ConnectToTarget                                 */
/*  Using the input LPAR name to call Get_CPCName to find     */
/*  the associated CPC name which is required for BCPii APIs  */
/*                                                            */
/*  Input: InTarget : LPAR name                               */
/* Output: CPCConnectToken : CPC Token for BCPii API          */
/*         TargetConnectToken : TARGET Token for BCPii API    */
/*                                                            */
/*------------------------------------------------------------*/
ConnectToTarget:
  InTarget = arg(1)
  InTargetType = arg(2)
 
/* Call to obtain the CPC name for the specified LPAR
*/
Call Get_CPCName InTarget
CPCName = RESULT
 
If Global_RC = 0 & CPCName ^= '' Then
 Do
  /* Connect to the CPC to obtain the CPC Connection which is required
     to connect to the LPAR
  */
  Call Connect InConnectToken,HWI_CPC,LEFT(CPCName,17)
 
  If Global_RC = 0 Then
   Do
    CPCConnectRC = 0
    CPCConnectToken = OutConnectToken
 
    /* Call to connect to the input LPAR using the returned CPC token
    */
    If InTargetType = 1 Then
     Call Connect CPCConnectToken,HWI_IMAGE,LEFT(InTarget,17)
    Else
     Call Connect CPCConnectToken,HWI_IMAGE_ACTPROF,LEFT(InTarget,17)
 
    If Global_RC = 0 Then
      TargetConnectToken = OutConnectToken
   End
 End
Else
 Do
  If Global_RC ^= 0 Then
   CPCConnectRC = Global_RC
 
  If CPCName = '' Then
   Do
    Say 'CHGWLM: Program aborted! Unable to obtain the CPC name '||,
        'for '||InTarget
    Say '  Enter a valid LPAR name or check the configuration files!'
   End
 End
 
Return /* ConnectToTargets */
 
/*------------------------------------------------------------*/
/*                                                            */
/* Procedure: Get_CPCName                                     */
/*   With the input Target name, read the system configuration */
/*   files to find the CPC name which will be used by BCPii   */
/*   to obtain a token to the SE                              */
/*                                                            */
/*  Input: InTarget : Target name                             */
/* Output: OutCPCName : CPC where the Target is activated in  */
/*                                                            */
/*------------------------------------------------------------*/
Get_CPCName:
 
  InTarget = arg(1)
 
/* Read the system configuration files
*/
Call ReadinputDD
 
/* Initialize
*/
OutCPCName = ''
Done  = 0
Found = 0
 
/* Traverse each input system configuration file to locate which CPC
   the Target is associated with
*/
Do i = 1 to CPC.0 While ^Found
 /* Traverse each Config file to locate the Target name
 */
 j = 1
 Do While (j <= InFile.i.0 & ^Done)
  If WORD(InFile.i.j,1) = 'CPCNAME' Then
   CPCName.i = WORD(InFile.i.j,3)
 
  If WORD(InFile.i.j,1) = 'IMGCOUNT' Then
   Do
    TargetCount.i = WORD(InFile.i.j,3)
    j = j + 1
 
    Do k = 1 to TargetCount.i While ^Found
     If WORD(InFile.i.j,1) = IMG.k & ,
        WORD(InFile.i.j,3) = InTarget Then
       Do
        Found = 1
        OutCPCName = CPCName.i
        Done = 1
       End
     Else
      j = j + 1
    End
   End
  Else
   j = j + 1
 End /* End Do while */
End /* End Do i */
 
Return OutCPCName /* Get_TargetName */
 
/*-------------------------------------------------------------*/
/*                                                             */
/* Procedure: WriteToOutput                                    */
/*                                                             */
/*-------------------------------------------------------------*/
WriteToOutputDD:
 
If Batch = 0 Then
 "ALLOC F(RXOUTDD) DA('"outfile"')"
 
"EXECIO * DISKW RXOUTDD (STEM outLine. FINIS"
 
If Batch = 0 Then
 "FREE F(RXOUTDD)"
Return    /* End WriteToOutputDD */
 
/*-----------------------------------------------------------------*/
/* Procedure: ReadinputDD                                          */
/*    - Using EXECIO to read the system configuration file for     */
/*      the desired CPC(s),                                        */
/*    - Using the CPC.0 count to determine how many CPC(s) is      */
/*      provided for processing                                    */
/*                                                                 */
/* Output: where i represents the n-th config. file                */
/*    1. InFile.i.  - stem for the input config. file              */
/*    2. InFile.i.0 - total # of lines for config file             */
/*-----------------------------------------------------------------*/
ReadinputDD:
 
Do i = 1 to CPC.0
 If Batch = 0 Then
   "ALLOC F(ConfgDD) DA('"ConfigFile.i"') LRECL(137) OLD"
 
 Select
  When i = 1 Then
   Do
    If Batch = 0 Then
     "EXECIO * DISKR ConfgDD (FINIS STEM InCFile1."
    Else
     "EXECIO * DISKR ConfgDD1 (FINIS STEM InCFile1."
 
    Do j = 1 to InCFile1.0
     InFile.i.j = InCFile1.j
    End
 
    InFile.i.0 = InCFile1.0
   End
  When i = 2 Then
   Do
    If Batch = 0 Then
     "EXECIO * DISKR ConfgDD (FINIS STEM InCFile2."
    Else
     "EXECIO * DISKR ConfgDD2 (FINIS STEM InCFile2."
    Do j = 1 to InCFile2.0
     InFile.i.j = InCFile2.j
    End
    InFile.i.0 = InCFile2.0
   End
  When i = 3 Then
   Do
    If Batch = 0 Then
     "EXECIO * DISKR ConfgDD (FINIS STEM InCFile3."
    Else
     "EXECIO * DISKR ConfgDD3 (FINIS STEM InCFile3."
    Do j = 1 to InCFile3.0
     InFile.i.j = InCFile3.j
    End
    InFile.i.0 = InCFile3.0
   End
  Otherwise
   Do
    say
    say '*** Internal Error. Check CPC_Count variable **  '
    say
    Return 8
   End
 End /* End Select */
 
 If Batch = 0 Then
   "FREE F(ConfgDD)"
End /* End Do */
 
Return /* End ReadinputDD */
 
/*-----------------------------------------------------------------*/
/*                                                                 */
/* Procedure: Wait for an amount of time specified as the input    */
/*                                                                 */
/*-----------------------------------------------------------------*/
WaitTime:
  InSecond = arg(1)
 
say 'CHGWLM: Waiting '||InSecond||' seconds(for SE processing) .....'
CALL SYSCALLS('ON')
ADDRESS SYSCALL
"SLEEP" InSecond
CALL SYSCALLS 'OFF'
 
Return
 
/*============================================================*/
/*============================================================*/
/*                                                            */
/*             BCPII HELPER PROCEDURES                        */
/*                                                            */
/*============================================================*/
/*============================================================*/
 
/*-------------------------------------------------------------*/
/* BCPii HWICONN request                                       */
/*-------------------------------------------------------------*/
Connect:
 
  InConnectToken = arg(1)
  ConnectType = arg(2)
  ConnectTypeValue = arg(3)
 
  address bcpii "hwiconn ",
                "ReturnCode ",
                "InConnectToken ",
                "OutConnectToken ",
                "ConnectType ",
                "ConnectTypeValue ",
                "DiagArea."
 
  REXXHostRc = RC
 
  If REXXHostRc <> 0 | ReturnCode <> 0 Then
    Do
      say 'REXX RC (decimal) = ' RC
      say 'HWICONN rc (hex) = ' d2x(ReturnCode)
      say 'DiagArea.Diag_Index    = '  DiagArea.Diag_Index
      say 'DiagArea.Diag_Key      = '  DiagArea.Diag_Key
      say 'DiagArea.Diag_Actual   = '  DiagArea.Diag_Actual
      say 'DiagArea.Diag_Expected = '  DiagArea.Diag_Expected
      say 'DiagArea.Diag_CommErr  = '  DiagArea.Diag_CommErr
      say 'DiagArea.Diag_Text     = '  DiagArea.Diag_Text
      say ' '
      say 'Error connecting to ' ConnectTypeValue
      say ' '
    End
  /*
  Else
    Do
     say 'OutConnectToken = ' C2X(OutConnectToken)
    End
  */
If REXXHostRc <> 0 Then
  Global_RC = REXXHostRc
Else
  Global_RC = ReturnCode
 
If Global_RC <> 0 Then
  signal finish
 
Return Global_RC
 
/*-------------------------------------------------------------*/
/* BCPii HWIDISC request                                       */
/*-------------------------------------------------------------*/
Disconnect:
 
  InConnectToken = arg(1)
 
  address bcpii "hwidisc ",
                "ReturnCode ",
                "InConnectToken ",
                "DiagArea."
 
  REXXHostRc = RC
 
  If REXXHostRc <> 0 | ReturnCode <> 0 Then
    Do
      say 'REXX RC (decimal) = ' RC
      say 'HWIDISC rc (hex) = ' d2x(ReturnCode)
      say 'DiagArea.Diag_Index    = '  DiagArea.Diag_Index
      say 'DiagArea.Diag_Key      = '  DiagArea.Diag_Key
      say 'DiagArea.Diag_Actual   = '  DiagArea.Diag_Actual
      say 'DiagArea.Diag_Expected = '  DiagArea.Diag_Expected
      say 'DiagArea.Diag_CommErr  = '  DiagArea.Diag_CommErr
      say 'DiagArea.Diag_Text     = '  DiagArea.Diag_Text
    End
  /*
  Else
    say 'Disconnected  ' ||C2X(InConnectToken)
  */
 
  /* No need to worry about disconnect failure as BCPii performs
     implicit disconnect when the task ends
  */
  If REXXHostRc <> 0 Then
    DISC_RC = REXXHostRc
  Else
    DISC_RC = ReturnCode
 
Return DISC_RC
 
/*-------------------------------------------------------------*/
/* BCPii HWIQUERY request                                      */
/*-------------------------------------------------------------*/
Query:
 
  InConnectToken = arg(1)
  address bcpii "hwiquery ",
                "ReturnCode ",
                "InConnectToken ",
                "QueryParm. ",
                "DiagArea."
 
  REXXHostRc = RC
 
  If REXXHostRc <> 0 | ReturnCode <> 0 Then
    Do
      say 'REXX RC (decimal) = ' RC
      say 'HWIQUERY rc (hex) = ' d2x(ReturnCode)
      say 'DiagArea.Diag_Index    = '  DiagArea.Diag_Index
      say 'DiagArea.Diag_Key      = '  DiagArea.Diag_Key
      say 'DiagArea.Diag_Actual   = '  DiagArea.Diag_Actual
      say 'DiagArea.Diag_Expected = '  DiagArea.Diag_Expected
      say 'DiagArea.Diag_CommErr  = '  DiagArea.Diag_CommErr
      say 'DiagArea.Diag_Text     = '  DiagArea.Diag_Text
    End
  /*
  Else
    Do
      say ' '
      say '*---------------------------------------------------*'
      say '* HWIQUERY returning all data in the QueryParm stem *'
      say '*---------------------------------------------------*'
      say 'Number of attributes requested = '||QueryParm.0
      do qi=1 to QueryParm.0
      say 'Attr'||i||'(BCPii Attr '||,
           QueryParm.qi.ATTRIBUTEIDENTIFIER||') = '||,
           QueryParm.qi.ATTRIBUTEVALUE
      end
    End
  */
 
  If REXXHostRc <> 0 Then
    Global_RC = REXXHostRc
  Else
    Global_RC = ReturnCode
 
If Global_RC <> 0 Then
 QueryErrorFlag = 1
/*
If Global_RC <> 0 Then
  signal finish
*/
Return Global_RC
 
/*-------------------------------------------------------------*/
/* BCPii HWISET2 request                                       */
/*-------------------------------------------------------------*/
Set2:
 
  InConnectToken = arg(1)
  address bcpii "hwiset2 ",
                "ReturnCode ",
                "InConnectToken ",
                "SetParm. ",
                "DiagArea."
 
  REXXHostRc = RC
 
  If REXXHostRc <> 0 | ReturnCode <> 0 Then
    Do
      say 'REXX RC (decimal) = ' RC
      say 'HWISET2 rc (hex) = ' d2x(ReturnCode)
      say 'DiagArea.Diag_Index    = '  DiagArea.Diag_Index
      say 'DiagArea.Diag_Key      = '  DiagArea.Diag_Key
      say 'DiagArea.Diag_Actual   = '  DiagArea.Diag_Actual
      say 'DiagArea.Diag_Expected = '  DiagArea.Diag_Expected
      say 'DiagArea.Diag_CommErr  = '  DiagArea.Diag_CommErr
      say 'DiagArea.Diag_Text     = '  DiagArea.Diag_Text
    End
  /*
  Else
    Do
      say ' '
      say '** HWISET2 completed **'
    End
  */
  If REXXHostRc <> 0 Then
    Global_RC = REXXHostRc
  Else
    Global_RC = ReturnCode
 
Return Global_RC
 
/*-------------------------------------------------------------*/
/* Read in BCPii External constants                            */
/*-------------------------------------------------------------*/
GetBCPiiConstants:
 
"ALLOC F(HWICIREX) DA('SYS1.MACLIB(HWICIREX)') SHR REUS"      /* @02C*/
"execio * diskr "HWICIREX" (stem  linelist.  finis   "
"FREE F(HWICIREX)"
do x = 1 to linelist.0
  interpret linelist.x
end
drop linelist.
 
"ALLOC F(HWIC2REX) DA('SYS1.MACLIB(HWIC2REX)') SHR REUS"      /* @02C*/
"execio * diskr "HWIC2REX" (stem  linelist.  finis   "
"FREE F(HWIC2REX)"
do x = 1 to linelist.0
  interpret linelist.x
end
drop linelist.
 
Return 0  /* End GetBCPiiConstants */
 
