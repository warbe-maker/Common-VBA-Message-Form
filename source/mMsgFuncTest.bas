Attribute VB_Name = "mMsgFuncTest"
Option Explicit
Option Compare Text
' ------------------------------------------------------------------------------
' Standard Module mMsgFuncTest
' All tests obligatory for a complete regression test performed after any code
' modification. Tests are to be extended when new features or functions are
' implemented.
'
' Note:    Test which explicitely raise an errors are only correctly asserted
'          when the error is passed on to the calling/entry procedure - which
'          requires the Conditional Compile Argument 'Debugging = 1'.
'
' W. Rauschenberger, Berlin June 2020
' -------------------------------------------------------------------------------
#If VBA7 Then
    Public Declare PtrSafe Sub Sleep Lib "kernel32" (ByVal ms As LongPtr)
#Else
    Public Declare PtrSafe Sub Sleep Lib "kernel32" (ByVal ms As Long)
#End If

Public Const BTTN_FINISH        As String = "Test Done"
Public Const BTTN_PASSED        As String = "Passed"
Public Const BTTN_FAILED        As String = "Failed"

Dim TestMsgWidthMin         As Long
Dim TestMsgWidthMax         As Long
Dim TestMsgHeightMin        As Long
Dim TestMsgHeightMax        As Long
Dim bRegressionTest         As Boolean
Dim TestMsgHeightIncrDecr   As Long
Dim TestMsgWidthIncrDecr    As Long
Dim Message                 As TypeMsg
Dim sBttnTerminate          As String
Dim vButton4                As Variant
Dim vButton5                As Variant
Dim vButton6                As Variant
Dim vButton7                As Variant
Dim vButtons                As Collection

Private Property Get BTTN_TERMINATE() As String ' composed constant
    BTTN_TERMINATE = "Terminate" & vbLf & "Regression" & vbLf & "Test"
End Property

Public Property Let RegressionTest(ByVal b As Boolean)
    bRegressionTest = b
    If b Then sBttnTerminate = "Terminate" & vbLf & "Regression" & vbLf & "Test" Else sBttnTerminate = vbNullString
End Property

Private Function AppErr(ByVal app_err_no As Long) As Long
' ------------------------------------------------------------------------------
' Ensures that a programmed (i.e. an application) error numbers never conflicts
' with the number of a VB runtime error. Thr function returns a given positive
' number (app_err_no) with the vbObjectError added - which turns it into a
' negative value. When the provided number is negative it returns the original
' positive "application" error number e.g. for being used with an error message.
' ------------------------------------------------------------------------------
    If app_err_no >= 0 Then AppErr = app_err_no + vbObjectError Else AppErr = Abs(app_err_no - vbObjectError)
End Function

Private Sub ClearVBEImmediateWindow()
    Dim v   As Variant
    For Each v In Application.VBE.Windows
        If v.Caption = "Direktbereich" Then
            v.SetFocus
            Application.SendKeys "^g ^a {DEL}"
            DoEvents
            Exit Sub
        End If
    Next v
End Sub

Public Sub cmdTest01_Click()
    wsTest.RegressionTest = False
    wsTest.TestNumber = 1
    mMsgFuncTest.Test_01_ErrMsg
End Sub

Public Sub cmdTest03_Click()
' ------------------------------------------------------------------------------
' Procedures for test start via Command Buttons on Test Worksheet
' ------------------------------------------------------------------------------
'    wsTest.RegressionTest = False
    wsTest.TestNumber = 3
    mMsgFuncTest.Test_03_WidthDeterminedByMinimumWidth
End Sub

Public Sub cmdTest04_Click()
    wsTest.RegressionTest = False
    wsTest.TestNumber = 4
    mMsgFuncTest.Test_04_WidthDeterminedByTitle
End Sub

Public Sub cmdTest05_Click()
    wsTest.RegressionTest = False
    wsTest.TestNumber = 5
    mMsgFuncTest.Test_05_WidthDeterminedByMonoSpacedMessageSection
End Sub

Public Sub cmdTest06_Click()
    wsTest.RegressionTest = False
    wsTest.TestNumber = 6
    mMsgFuncTest.Test_06_WidthDeterminedByReplyButtons
End Sub

Public Sub cmdTest07_Click()
    wsTest.RegressionTest = False
    wsTest.TestNumber = 7
    mMsgFuncTest.Test_07_MonoSpacedSectionWidthExceedsMaxMsgWidth
End Sub

Public Sub cmdTest08_Click()
    wsTest.RegressionTest = False
    wsTest.TestNumber = 8
    mMsgFuncTest.Test_08_MonoSpacedMessageSectionExceedsMaxHeight
End Sub

Public Sub cmdTest09_Click()
    wsTest.RegressionTest = False
    wsTest.TestNumber = 9
    mMsgFuncTest.Test_09_ButtonsOnly
End Sub

Public Sub cmdTest10_Click()
    wsTest.RegressionTest = False
    wsTest.TestNumber = 10
    mMsgFuncTest.Test_10_ButtonsMatrix
End Sub

Public Sub cmdTest11_Click()
    wsTest.RegressionTest = False
    wsTest.TestNumber = 11
    mMsgFuncTest.Test_11_ButtonScrollBarVertical
End Sub

Public Sub cmdTest12_Click()
    wsTest.RegressionTest = False
    wsTest.TestNumber = 12
    mMsgFuncTest.Test_12_ButtonScrollBarHorizontal
End Sub

Public Sub cmdTest13_Click()
    wsTest.RegressionTest = False
    wsTest.TestNumber = 13
    mMsgFuncTest.Test_13_ButtonsMatrix_with_horizomtal_and_vertical_scrollbar
End Sub

Public Sub cmdTest17_Click()
    wsTest.RegressionTest = False
    wsTest.TestNumber = 17
    mMsgFuncTest.Test_17_MessageAsString
End Sub

Public Sub cmdTest30_Click()
    wsTest.RegressionTest = False
    wsTest.TestNumber = 30
    mMsgFuncTest.Test_30_Monitor
End Sub

Public Sub cmdTest90_Click()
    wsTest.RegressionTest = False
    wsTest.TestNumber = 90
    mMsgFuncTest.Test_90_All_in_one_Demonstration
End Sub

Private Function ErrMsg(ByVal err_source As String, _
               Optional ByVal err_no As Long = 0, _
               Optional ByVal err_dscrptn As String = vbNullString, _
               Optional ByVal err_line As Long = 0) As Variant
' ------------------------------------------------------------------------------
' Universal error message display service including a debugging option
' (Conditional Compile Argument 'Debugging = 1') and an optional additional
' "about the error" information which may be connected to an error message by
' two vertical bars (||).
'
' A copy of this function is used in each procedure with an error handling
' (On error Goto eh).
'
' The function considers the Common VBA Error Handling Component (ErH) which
' may be installed (Conditional Compile Argument 'ErHComp = 1') and/or the
' Common VBA Message Display Component (mMsg) installed (Conditional Compile
' Argument 'MsgComp = 1'). Only when none of the two is installed the error
' message is displayed by means of the VBA.MsgBox.
'
' Usage: Example with the Conditional Compile Argument 'Debugging = 1'
'
'        Private/Public <procedure-name>
'            Const PROC = "<procedure-name>"
'
'            On Error Goto eh
'            ....
'        xt: Exit Sub/Function/Property
'
'        eh: Select Case ErrMsg(ErrSrc(PROC))
'               Case vbResume:  Stop: Resume
'               Case vbPassOn:  Err.Raise Err.Number, ErrSrc(PROC), Err.Description
'               Case Else:      GoTo xt
'            End Select
'        End Sub/Function/Property
'
'        The above may appear a lot of code lines but will be a godsend in case
'        of an error!
'
' Uses:  - For programmed application errors (Err.Raise AppErr(n), ....) the
'          function AppErr will be used which turns the positive number into a
'          negative one. The error message will regard a negative error number
'          as an 'Application Error' and will use AppErr to turn it back for
'          the message into its original positive number. Together with the
'          ErrSrc there will be no need to maintain numerous different error
'          numbers for a VB-Project.
'        - The caller provides the source of the error through the module
'          specific function ErrSrc(PROC) which adds the module name to the
'          procedure name.
'
' W. Rauschenberger Berlin, Nov 2021
' ------------------------------------------------------------------------------
#If ErHComp = 1 Then
    '~~ ------------------------------------------------------------------------
    '~~ When the Common VBA Error Handling Component (mErH) is installed in the
    '~~ VB-Project (which includes the mMsg component) the mErh.ErrMsg service
    '~~ is preferred since it provides some enhanced features like a path to the
    '~~ error.
    '~~ ------------------------------------------------------------------------
    ErrMsg = mErH.ErrMsg(err_source, err_no, err_dscrptn, err_line)
    GoTo xt
#ElseIf MsgComp = 1 Then
    '~~ ------------------------------------------------------------------------
    '~~ When only the Common Message Services Component (mMsg) is installed but
    '~~ not the mErH component the mMsg.ErrMsg service is preferred since it
    '~~ provides an enhanced layout and other features.
    '~~ ------------------------------------------------------------------------
    ErrMsg = mMsg.ErrMsg(err_source, err_no, err_dscrpt, err_line)
    GoTo xt
#End If
    '~~ -------------------------------------------------------------------
    '~~ When neither the mMsg nor the mErH component is installed the error
    '~~ message is displayed by means of the VBA.MsgBox
    '~~ -------------------------------------------------------------------
    Dim ErrBttns    As Variant
    Dim ErrAtLine   As String
    Dim ErrDesc     As String
    Dim ErrLine     As Long
    Dim ErrNo       As Long
    Dim ErrSrc      As String
    Dim ErrText     As String
    Dim ErrTitle    As String
    Dim ErrType     As String
    Dim ErrAbout    As String
        
    '~~ Obtain error information from the Err object for any argument not provided
    If err_no = 0 Then err_no = Err.Number
    If err_line = 0 Then ErrLine = Erl
    If err_source = vbNullString Then err_source = Err.Source
    If err_dscrptn = vbNullString Then err_dscrptn = Err.Description
    If err_dscrptn = vbNullString Then err_dscrptn = "--- No error description available ---"
    
    If InStr(err_dscrptn, "||") <> 0 Then
        ErrDesc = Split(err_dscrptn, "||")(0)
        ErrAbout = Split(err_dscrptn, "||")(1)
    Else
        ErrDesc = err_dscrptn
    End If
    
    '~~ Determine the type of error
    Select Case err_no
        Case Is < 0
            ErrNo = AppErr(err_no)
            ErrType = "Application Error "
        Case Else
            ErrNo = err_no
            If (InStr(1, err_dscrptn, "DAO") <> 0 _
            Or InStr(1, err_dscrptn, "ODBC Teradata Driver") <> 0 _
            Or InStr(1, err_dscrptn, "ODBC") <> 0 _
            Or InStr(1, err_dscrptn, "Oracle") <> 0) _
            Then ErrType = "Database Error " _
            Else ErrType = "VB Runtime Error "
    End Select
    
    If err_source <> vbNullString Then ErrSrc = " in: """ & err_source & """"   ' assemble ErrSrc from available information"
    If err_line <> 0 Then ErrAtLine = " at line " & err_line                    ' assemble ErrAtLine from available information
    ErrTitle = Replace(ErrType & ErrNo & ErrSrc & ErrAtLine, "  ", " ")         ' assemble ErrTitle from available information
       
    ErrText = "Error: " & vbLf & _
              ErrDesc & vbLf & vbLf & _
              "Source: " & vbLf & _
              err_source & ErrAtLine
    If ErrAbout <> vbNullString _
    Then ErrText = ErrText & vbLf & vbLf & _
                  "About: " & vbLf & _
                  ErrAbout
    
#If Debugging Then
    ErrBttns = vbYesNo
    ErrText = ErrText & vbLf & vbLf & _
              "Debugging:" & vbLf & _
              "Yes    = Resume Error Line" & vbLf & _
              "No     = Terminate"
#Else
    ErrBttns = vbCritical
#End If
    
    ErrMsg = MsgBox(Title:=ErrTitle _
                  , Prompt:=ErrText _
                  , Buttons:=ErrBttns)
xt: Exit Function

End Function

Private Function ErrSrc(ByVal sProc As String) As String
    ErrSrc = "mMsgFuncTest." & sProc
End Function

Public Sub Explore(ByVal ctl As Variant, _
          Optional ByVal applied As Boolean = True)
' ------------------------------------------------------------------------------
'
' ------------------------------------------------------------------------------
    Const PROC = "Explore"
    
    On Error GoTo eh
    Dim MsgForm     As fMsg
    Dim MsgTitle   As String
    Dim dct         As New Dictionary
    Dim v           As Variant
    Dim Appl        As String   ' ControlApplied
    Dim l           As String   ' .Left
    Dim W           As String   ' .Width
    Dim T           As String   ' .Top
    Dim H           As String   ' .Height
    Dim SW          As String   ' .ScrollWidth
    Dim SH          As String   ' .ScrollHeight
    Dim FW          As String   ' MsgForm.InsideWidth
    Dim CW          As String   ' Content width
    Dim CH          As String   ' Content height
    Dim FH          As String   ' MsgForm.InsideHeight
    Dim i           As Long
    Dim Item        As String
    Dim j           As String
    Dim frm         As Msforms.Frame
    
    MsgTitle = "Explore"
    Unload mMsg.MsgInstance(MsgTitle) ' Ensure there is no process monitoring with this title still displayed
    Set MsgForm = mMsg.MsgInstance(MsgTitle)
    
    If TypeName(ctl) <> "Frame" And TypeName(ctl) <> "fMsg" Then Exit Sub
    
    '~~ Collect Controls
    mDct.DctAdd dct, ctl, ctl.Name, order_byitem, seq_ascending, sense_casesensitive
      
    i = 0: j = 1
    Do
        If TypeName(dct.Keys()(i)) = "Frame" Or TypeName(dct.Keys()(i)) = "fMsg" Then
            For Each v In dct.Keys()(i).Controls
                If v.Parent Is dct.Keys()(i) Then
                    Item = dct.Items()(i) & ":" & v.Name
                    If applied Then
                        If MsgForm.IsApplied(v) Then mDct.DctAdd dct, v, Item
                    Else
                        mDct.DctAdd dct, v, Item
                    End If
                End If
            Next v
        End If
        If TypeName(dct.Keys()(i)) = "Frame" Or TypeName(dct.Keys()(i)) = "fMsg" Then j = j + 1
        If i + 1 < dct.Count Then i = i + 1 Else Exit Do
    Loop
        
    '~~ Display facts
    Debug.Print "====================+====+=======+=======+=======+=======+=======+=======+=======+=======+=======+======="
    Debug.Print "                    |Ctl | Left  | Width |Content| Top   |Height |Content|VScroll|HScroll| Width | Height"
    Debug.Print "Name                |Appl| Pos   |       | Width | Pos   |       |Height |Height | Width | Form  |  Form "
    Debug.Print "--------------------+----+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------"
    For Each v In dct
        Set ctl = v
        If MsgForm.IsApplied(ctl) Then Appl = "Yes " Else Appl = " No "
        l = Align(Format(ctl.Left, "000.0"), 7, AlignCentered, " ")
        W = Align(Format(ctl.Width, "000.0"), 7, AlignCentered, " ")
        T = Align(Format(ctl.Top, "000.0"), 7, AlignCentered, " ")
        H = Align(Format(ctl.Height, "000.0"), 7, AlignCentered, " ")
        FH = Align(Format(MsgForm.InsideHeight, "000.0"), 7, AlignCentered, " ")
        FW = Align(Format(MsgForm.InsideWidth, "000.0"), 7, AlignCentered, " ")
        If TypeName(ctl) = "Frame" Then
            Set frm = ctl
            CW = Align(Format(MsgForm.FrameContentWidth(frm), "000.0"), 7, AlignCentered, " ")
            CH = Align(Format(MsgForm.FrameContentHeight(frm), "000.0"), 7, AlignCentered, " ")
            SW = "   -   "
            SH = "   -   "
            With frm
                Select Case .ScrollBars
                    Case fmScrollBarsHorizontal
                        Select Case .KeepScrollBarsVisible
                            Case fmScrollBarsBoth, fmScrollBarsHorizontal
                                SW = Align(Format(.ScrollWidth, "000.0"), 7, AlignCentered, " ")
                        End Select
                    Case fmScrollBarsVertical
                        Select Case .KeepScrollBarsVisible
                            Case fmScrollBarsBoth, fmScrollBarsVertical
                                SH = Align(Format(.ScrollHeight, "000.0"), 7, AlignCentered, " ")
                        End Select
                    Case fmScrollBarsBoth
                        Select Case .KeepScrollBarsVisible
                            Case fmScrollBarsBoth
                                SW = Align(Format(.ScrollWidth, "000.0"), 7, AlignCentered, " ")
                                SH = Align(Format(.ScrollHeight, "000.0"), 7, AlignCentered, " ")
                            Case fmScrollBarsVertical
                                SH = Align(Format(.ScrollHeight, "000.0"), 7, AlignCentered, " ")
                            Case fmScrollBarsHorizontal
                                SW = Align(Format(.ScrollWidth, "000.0"), 7, AlignCentered, " ")
                        End Select
                End Select
            End With
        End If
        
        Debug.Print Align(ctl.Name, 20, AlignLeft) & "|" & Appl & "|" & l & "|" & W & "|" & CW & "|" & T & "|" & H & "|" & CH & "|" & SH & "|" & SW & "|" & FW & "|" & FH
    Next v

xt: Set dct = Nothing

eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbResume:  Stop: Resume
        Case Else:      GoTo xt
    End Select
End Sub

Function IsUcase(ByVal s As String) As Boolean

    Dim i   As Integer: i = Asc(s)
    IsUcase = (i >= 65 And i <= 90) Or _
              (i >= 192 And i <= 214) Or _
              (i >= 216 And i <= 223) Or _
              (i = 128) Or _
              (i = 138) Or _
              (i = 140) Or _
              (i = 142) Or _
              (i = 154) Or _
              (i = 156) Or _
              (i >= 158 And i <= 159) Or _
              (i = 163) Or _
              (i = 165)
End Function

Private Sub MessageInit(ByRef msg_form As fMsg, _
                        ByVal msg_title As String, _
               Optional ByVal caller As String = vbNullString)
' ------------------------------------------------------------------------------
' Initializes the all message sections with the defaults throughout this test
' module which uses a module global declared Message for a consistent layout.
' ------------------------------------------------------------------------------
    Dim i As Long
    
    mMsg.MsgInstance fi_key:=msg_title, fi_unload:=True                    ' Ensures a message starts from scratch
    Set msg_form = mMsg.MsgInstance(msg_title)
    
    For i = 1 To msg_form.NoOfDesignedMsgSects
        With Message.Section(i)
            .Label.Text = vbNullString
            .Label.FontColor = rgbBlue
            .Text.Text = vbNullString
            .Text.MonoSpaced = False
            .Text.FontItalic = False
            .Text.FontUnderline = False
            .Text.FontColor = rgbBlack
        End With
    Next i
    If bRegressionTest Then mMsgFuncTest.RegressionTest = True Else mMsgFuncTest.RegressionTest = False

End Sub

Private Function PrcPnt(ByVal pp_value As Single, _
                        ByVal pp_dimension As String) As String
    PrcPnt = mMsg.Prcnt(pp_value, pp_dimension) & "% (" & mMsg.Pnts(pp_value, "w") & "pt)"
End Function

Private Function Readable(ByVal s As String) As String
' ------------------------------------------------------------------------------
' Convert a string (s) into a readable form by replacing all underscores
' with a whitespace and all characters immediately following an underscore
' to a lowercase letter.
' ------------------------------------------------------------------------------
    Dim i       As Long
    Dim sResult As String
    
    s = Replace(s, "_", " ")
    s = Replace(s, "  ", " ")
    For i = 1 To Len(s)
        If IsUcase(Mid(s, i, 1)) Then
            sResult = sResult & " " & Mid(s, i, 1)
        Else
            sResult = sResult & Mid(s, i, 1)
        End If
    Next i
    Readable = Right(sResult, Len(sResult) - 1)

End Function

Private Function Repeat(repeat_string As String, repeat_n_times As Long)
    Dim s As String
    Dim C As Long
    Dim l As Long
    Dim i As Long

    l = Len(repeat_string)
    C = l * repeat_n_times
    s = Space$(C)

    For i = 1 To C Step l
        Mid(s, i, l) = repeat_string
    Next

    Repeat = s
End Function

Private Function RepeatString( _
           ByVal rep_n_times As Long, _
           ByVal rep_pattern As String, _
  Optional ByVal rep_with_line_numbers As Boolean = False, _
  Optional ByVal rep_with_linen_umbers_as_prefix As Boolean = True, _
  Optional ByVal rep_with_with_line_breaks As String = vbNullString) As String
' ------------------------------------------------------------------------------
' Repeat the string (rep_pattern) n (rep_n_times) times, otionally with a line-
' number, either prefixed (linenumbersprefix=True) or attached. When the pattern
' ends with a vbLf, vbCr, or vbCrLf the attached line number is put at the left.
' The string rep_with_with_line_breaks is attached to the assembled rep_pattern.
' ------------------------------------------------------------------------------
    
    Dim i       As Long
    Dim s       As String
    Dim ln      As String
    Dim sFormat As String
    
    On Error Resume Next
    If rep_with_line_numbers Then sFormat = String$(Len(CStr(rep_n_times)), "0")
    
    For i = 1 To rep_n_times
        If rep_with_line_numbers Then ln = Format(i, sFormat)
        If rep_with_linen_umbers_as_prefix Then
            s = s & ln & " " & rep_pattern & rep_with_with_line_breaks
        Else
            s = s & rep_pattern & " " & ln & rep_with_with_line_breaks
        End If
        If Err.Number <> 0 Then
            Debug.Print "Repeate had to stop after " & i & "which resulted in a string length of " & Len(s)
            RepeatString = s
            Exit Function
        End If
    Next i
    RepeatString = s
End Function

Public Sub RepeatTest()
    Debug.Print RepeatString(10, "a", True, False, vbLf)
End Sub

Public Sub Test_00_Regression()
' --------------------------------------------------------------------------------------
' Regression testing makes use of all available design means - by the way testing them.
' Note: Each test procedure is completely independant and thus may be executed directly.
' --------------------------------------------------------------------------------------
    Const PROC = "Test_00_Regression"
    
    On Error GoTo eh
    Dim rng     As Range
    Dim sTest   As String
    Dim sMakro  As String
    
    BoP ErrSrc(PROC)
    
    '~~ Indicating 'regression testing mode' in which asserted errors are not displayed
    '~~ in order not to interrupt an otherwise self asserting regression testing procedure.
    mErH.Regression = True
    
    ThisWorkbook.Save
    Unload fMsg
    wsTest.RegressionTest = True
    mMsgFuncTest.RegressionTest = True
    
    For Each rng In wsTest.RegressionTests
        If rng.Value = "R" Then
            sTest = Format(rng.Offset(, -2), "00")
            sMakro = "cmdTest" & sTest & "_Click"
            wsTest.TerminateRegressionTest = False
            Application.Run "Msg.xlsb!" & sMakro
            If wsTest.TerminateRegressionTest Then Exit For
        End If
    Next rng

xt: EoP ErrSrc(PROC)
    mErH.Regression = False
    Exit Sub

eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbResume:  Stop: Resume
        Case Else:      GoTo xt
    End Select
End Sub

Public Sub Test_01_ErrMsg()
' ------------------------------------------------------------------------------
' Test of the "universal error message display which includes
' - the 'Debugging Option' activated by the Conditional Compile Argument
'   'Debugging = 1')
' - an optional additional "about the error" information which may be
'   concatenated with an error message by two vertical bars (||)".
' All tests primarily use the 'Private Function ErrMsg' which passes on the
' display of the error message to the ErrMsg function of the mMsg module when
' the Conditional Compile Argument 'CompMsg = 1' or passes on the function to
' the ErrMsg function of the mErH module when the Conditional Compile Argument
' 'CompErH = 1'.
' Summarized all this means that testing has to be performed with the following
' three Conditional Compile Argument variants:
' ErHComp = 0 : MsgComp = 0 > display of the error message by VBA.MsgBox
' ErHComp = 0 : MsgComp = 1 > display of the error message by mMsg.ErrMsg
' ErHComp = 1               > display of the error message by mErH.ErrMsg
' For the last testing variant the mErH component is installed!
' ------------------------------------------------------------------------------
    Const PROC = "Test_01_ErrMsg"
    
    On Error GoTo eh
    
    '~~ An 'Application Error 5 is regarded an asserted error number and when the
    '~~ Regression property is set to TRUE the display of the error message is suppressed
    BoTP ErrSrc(PROC), AppErr(5)
    
    wsTest.TestNumber = 1
    
    Err.Raise Number:=AppErr(5), Source:=ErrSrc(PROC), _
              Description:="This is a test error description!||This is part of the error description, " & _
                           "concatenated by a double vertical bar and therefore displayed as an additional 'About the error' section " & _
                           "- one of the specific features of the mMsg.ErrMsg service."
        
xt: EoP ErrSrc(PROC)
    mMsg.Buttons vButtons, BTTN_PASSED, BTTN_FAILED
    Select Case mMsg.Box(box_title:="Test result of " & Readable(PROC) _
                       , box_msg:=vbNullString _
                       , box_buttons:=vButtons _
                        )
        Case BTTN_PASSED:       wsTest.Passed = True
        Case BTTN_FAILED:       wsTest.Failed = True
        Case sBttnTerminate:    wsTest.TerminateRegressionTest = True
    End Select
    Exit Sub

eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbResume:  Stop: Resume
        Case Else:      GoTo xt
    End Select
End Sub

Public Function Test_02_Buttons_7_By_7() As Variant
' ------------------------------------------------------------------------------
'
' ------------------------------------------------------------------------------
    Dim cll As Collection
    Dim i As Long
    For i = 1 To 50
        Set cll = mMsg.Buttons(cll, "B" & Format(i, "00"))
    Next i
    Debug.Assert cll.Count = 55
    Debug.Assert cll(8) = vbLf
    Debug.Assert cll(16) = vbLf
    Debug.Assert cll(24) = vbLf
    Debug.Assert cll(32) = vbLf
    Debug.Assert cll(40) = vbLf
    Debug.Assert cll(48) = vbLf
    Test_02_Buttons_7_By_7 = _
    mMsg.Box(box_title:="49 buttons ordered in 7 rows, row breaks inserted by the Buttons service, an excessive 50th button is ignored without notice", _
             box_buttons:=cll)

End Function

Public Function Test_02_Buttons_Added() As Variant
' ------------------------------------------------------------------------------
'
' ------------------------------------------------------------------------------
    Dim cll As Collection
    
    mMsg.Buttons cll, "B01,B02,B03,B04,B05"             ' initially specified buttons
    Debug.Assert cll.Count = 5
    Set cll = mMsg.Buttons(cll, "B06,B07,B08,B09,B10")  ' secondary added buttons
    Debug.Assert cll.Count = 11
    Debug.Assert cll(8) = vbLf
    Test_02_Buttons_Added = _
    mMsg.Box(box_title:="7 buttons oin first and 3 buttons in second row (row break after 7 buttons inserted by service)", _
             box_buttons:=cll)
End Function

Public Function Test_02_Buttons_Numeric() As Variant
' ------------------------------------------------------------------------------
'
' ------------------------------------------------------------------------------
    Dim cll As Collection
    
    mMsg.Buttons cll, vbResumeOk
    Debug.Assert cll.Count = 1
    Test_02_Buttons_Numeric = _
    mMsg.Box(box_title:="Buttons 'Resume Error Line', 'Ok'", _
             box_buttons:=cll)
End Function

Public Function Test_03_WidthDeterminedByMinimumWidth() As Variant
' ------------------------------------------------------------------------------
'
' ------------------------------------------------------------------------------
    Const PROC      As String = "Test_03_WidthDeterminedByMinimumWidth"
    
    On Error GoTo eh
    Dim MsgForm         As fMsg
    Dim MsgTitle        As String
    Dim cll             As Collection
    
    wsTest.TestNumber = 3
    MsgTitle = Readable(PROC)
    MessageInit msg_form:=MsgForm, msg_title:=MsgTitle, caller:=ErrSrc(PROC) ' set test-global message specifications
    
    '~~ Obtain initial test values from the Test Worksheet
    With wsTest
        TestMsgWidthMin = .MsgWidthMin
        TestMsgWidthMax = .MsgWidthMax
        TestMsgHeightMax = .MsgHeightMax
        MsgForm.DsplyFrmsWthBrdrsTestOnly = wsTest.TestOptionDisplayFrames
    End With
    TestMsgWidthIncrDecr = wsTest.MsgWidthIncrDecr
    If TestMsgWidthIncrDecr = 0 Then Err.Raise AppErr(1), ErrSrc(PROC), "Width increment/decrement must not be 0 for this test!"
    
    vButton4 = "Repeat with minimum width" & vbLf & "+ " & PrcPnt(TestMsgWidthIncrDecr, "w")
    vButton5 = "Repeat with minimum width" & vbLf & "- " & PrcPnt(TestMsgWidthIncrDecr, "w")
    
    mMsg.Buttons cll, sBttnTerminate, BTTN_PASSED, BTTN_FAILED, vbLf, vButton4, vButton5
    
    Do
        With Message.Section(1)
            .Label.Text = "Test description:"
            .Text.Text = wsTest.TestDescription
        End With
        With Message.Section(2)
            .Label.Text = "Expected test result:"
            .Text.Text = "The width of all message sections is adjusted either to the specified minimum form width (" & PrcPnt(TestMsgWidthMin, "w") & ") or " _
                       & "to the width determined by the reply buttons."
        End With
        With Message.Section(3)
            .Label.Text = "Please also note:"
            .Text.Text = "1. The message form height is adjusted to the required height up to the specified " & _
                         "maximum heigth which for this test is " & PrcPnt(TestMsgHeightMax, "h") & " and not exceeded." & vbLf & _
                         "2. The minimum width limit for this test is " & PrcPnt(20, "w") & " and the maximum width limit for this test is " & PrcPnt(99, "w") & "."
            .Text.FontColor = rgbRed
        End With
                                                                                                  
        Test_03_WidthDeterminedByMinimumWidth = _
        mMsg.Dsply(dsply_title:=MsgTitle _
                 , dsply_msg:=Message _
                 , dsply_buttons:=vButtons _
                 , dsply_modeless:=wsTest.TestOptionDisplayModeless _
                 , dsply_width_min:=TestMsgWidthMin _
                 , dsply_width_max:=TestMsgWidthMax _
                 , dsply_height_max:=TestMsgHeightMax _
                  )
        Select Case Test_03_WidthDeterminedByMinimumWidth
            Case vButton5
                TestMsgWidthMin = Max(TestMsgWidthMin - TestMsgWidthIncrDecr, 20)
                mMsg.Buttons vButtons, sBttnTerminate, BTTN_PASSED, BTTN_FAILED, vbLf, vButton4, vButton5
            Case vButton4
                TestMsgWidthMin = Min(TestMsgWidthMin + TestMsgWidthIncrDecr, 99)
                mMsg.Buttons vButtons, sBttnTerminate, BTTN_PASSED, BTTN_FAILED, vbLf, vButton4, vButton5
            Case BTTN_PASSED:       wsTest.Passed = True:   Exit Do
            Case BTTN_FAILED:       wsTest.Failed = True:   Exit Do
            Case sBttnTerminate:    wsTest.TerminateRegressionTest = True:  Exit Do
            Case Else ' Stop and Next are passed on to the caller
        End Select
    
    Loop

xt: Exit Function

eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbResume:  Stop: Resume
        Case Else:      GoTo xt
    End Select
End Function

Public Function Test_04_WidthDeterminedByTitle() As Variant
' ------------------------------------------------------------------------------
'
' ------------------------------------------------------------------------------
    Const PROC          As String = "Test_04_WidthDeterminedByTitle"
    
    On Error GoTo eh
    Dim MsgForm     As fMsg
    Dim MsgTitle    As String
    
    wsTest.TestNumber = 4
    MsgTitle = Readable(PROC) & "  (This title uses more space than the minimum specified message form width and thus the width is determined by the title)"
    MessageInit msg_form:=MsgForm, msg_title:=MsgTitle, caller:=ErrSrc(PROC) ' set test-global message specifications
    
    '~~ Obtain initial test values from the Test Worksheet
    MsgForm.DsplyFrmsWthBrdrsTestOnly = wsTest.TestOptionDisplayFrames
    
    MessageInit msg_form:=MsgForm, msg_title:=MsgTitle, caller:=ErrSrc(PROC) ' set test-global message specifications
    With Message.Section(1)
        .Label.Text = "Test description:"
        .Text.Text = wsTest.TestDescription
    End With
    With Message.Section(2)
        .Label.Text = "Expected test result:"
        .Text.Text = "The message form width is adjusted to the title's lenght."
    End With
    With Message.Section(3)
        .Label.Text = "Please note:"
        .Text.Text = "The two message sections in this test do use a proportional font " & _
                     "and thus are adjusted to form width determined by other factors." & vbLf & _
                     "The message form height is adjusted to the need up to the specified " & _
                     "maximum heigth based on the screen height which for this test is " & _
                     PrcPnt(TestMsgHeightMax, "h") & "."
    End With
    mMsg.Buttons vButtons, sBttnTerminate, BTTN_PASSED, BTTN_FAILED
    
    Test_04_WidthDeterminedByTitle = _
    mMsg.Dsply(dsply_title:=MsgTitle _
             , dsply_msg:=Message _
             , dsply_buttons:=vButtons _
             , dsply_width_max:=wsTest.MsgWidthMax _
             , dsply_width_min:=wsTest.MsgWidthMin _
             , dsply_height_max:=wsTest.MsgHeightMax _
             , dsply_modeless:=wsTest.TestOptionDisplayModeless _
              )
    Select Case Test_04_WidthDeterminedByTitle
        Case BTTN_PASSED:       wsTest.Passed = True
        Case BTTN_FAILED:       wsTest.Failed = True
        Case sBttnTerminate:    wsTest.TerminateRegressionTest = True
    End Select
xt: Exit Function

eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbResume:  Stop: Resume
        Case Else:      GoTo xt
    End Select
End Function

Public Function Test_05_WidthDeterminedByMonoSpacedMessageSection() As Variant
' ------------------------------------------------------------------------------
'
' ------------------------------------------------------------------------------
    Const PROC          As String = "Test_05_WidthDeterminedByMonoSpacedMessageSection"
        
    On Error GoTo eh
    Dim MsgForm                         As fMsg
    Dim MsgTitle                        As String
    Dim BttnRepeatMaxWidthIncreased     As String
    Dim BttnRepeatMaxWidthDecreased     As String
    Dim BttnRepeatMaxHeightIncreased    As String
    Dim BttnRepeatMaxHeightDecreased    As String
    
    wsTest.TestNumber = 5
    MsgTitle = Readable(PROC)
    
    '~~ Obtain initial test values from the Test Worksheet
    With wsTest
        TestMsgWidthMin = Pnts(.MsgWidthMin, "w")
        TestMsgWidthMax = Pnts(.MsgWidthMax, "w")
        TestMsgWidthIncrDecr = Pnts(.MsgWidthIncrDecr, "w")
        TestMsgHeightMin = Pnts(25, "h")
        TestMsgHeightMax = Pnts(.MsgHeightMax, "h")
        TestMsgHeightIncrDecr = Pnts(.MsgHeightIncrDecr, "h")
    End With
    If TestMsgWidthIncrDecr = 0 Then Err.Raise AppErr(1), ErrSrc(PROC), "Width increment/decrement must not be 0 for this test!"
    If TestMsgHeightIncrDecr = 0 Then Err.Raise AppErr(1), ErrSrc(PROC), "Height increment/decrement must not be 0 for this test!"
    
    BttnRepeatMaxWidthIncreased = "Repeat with" & vbLf & "maximum width" & vbLf & "+ " & PrcPnt(TestMsgWidthIncrDecr, "w")
    BttnRepeatMaxWidthDecreased = "Repeat with" & vbLf & "maximum width" & vbLf & "- " & PrcPnt(TestMsgWidthIncrDecr, "w")
    BttnRepeatMaxHeightIncreased = "Repeat with" & vbLf & "maximum height" & vbLf & "+ " & PrcPnt(TestMsgHeightIncrDecr, "h")
    BttnRepeatMaxHeightDecreased = "Repeat with" & vbLf & "maximum height" & vbLf & "- " & PrcPnt(TestMsgHeightIncrDecr, "h")
    
    mMsg.Buttons vButtons, sBttnTerminate, BTTN_PASSED, BTTN_FAILED, vbLf, BttnRepeatMaxWidthIncreased, BttnRepeatMaxWidthDecreased
    MessageInit msg_form:=MsgForm, msg_title:=MsgTitle, caller:=ErrSrc(PROC) ' set test-global message specifications
    
    Do
        AssertWidthAndHeight TestMsgWidthMin _
                           , TestMsgWidthMax _
                           , TestMsgHeightMin _
                           , TestMsgHeightMax
        
        With Message.Section(1)
            .Label.Text = "Test description:"
            .Text.Text = "The length of the longest monospaced message section line determines the width of the message form - " & _
                         "provided it does not exceed the specified maximum form width which for this test is " & PrcPnt(TestMsgWidthMax, "w") & " " & _
                         "of the screen size. The maximum form width may be incremented/decremented by " & PrcPnt(TestMsgWidthIncrDecr, "w") & " in order to test the result."
        End With
        With Message.Section(2)
            .Label.Text = "Expected test result:"
            .Text.Text = "Initally, the message form width is adjusted to the longest line in the " & _
                         "monospaced message section and all other message sections are adjusted " & _
                         "to this (enlarged) width." & vbLf & _
                         "When the maximum form width is reduced by " & PrcPnt(TestMsgWidthIncrDecr, "w") & " the monospaced message section is displayed with a horizontal scrollbar."
        End With
        With Message.Section(3)
            .Label.Text = "Please note the following:"
            .Text.Text = "- In contrast to the message sections above, this section uses the ""monospaced"" option which ensures" & vbLf & _
                         "  the message text is not ""word wrapped""." & vbLf & _
                         "- The message form height is adjusted to the need up to the specified maximum heigth" & vbLf & _
                         "  based on the screen height which for this test is " & PrcPnt(TestMsgHeightMax, "h") & "."
            .Text.MonoSpaced = True
            .Text.FontUnderline = False
        End With
            
        '~~ Assign test values from the Test Worksheet
        mMsg.MsgInstance(MsgTitle).DsplyFrmsWthBrdrsTestOnly = wsTest.TestOptionDisplayFrames
                
        Test_05_WidthDeterminedByMonoSpacedMessageSection = _
        mMsg.Dsply(dsply_title:=MsgTitle _
                 , dsply_msg:=Message _
                 , dsply_buttons:=vButtons _
                 , dsply_modeless:=wsTest.TestOptionDisplayModeless _
                 , dsply_width_min:=TestMsgWidthMin _
                 , dsply_width_max:=TestMsgWidthMax _
                 , dsply_height_min:=TestMsgHeightMin _
                 , dsply_height_max:=TestMsgHeightMax _
                  )
        Select Case Test_05_WidthDeterminedByMonoSpacedMessageSection
            Case BttnRepeatMaxWidthDecreased
                TestMsgWidthMax = TestMsgWidthMax - TestMsgWidthIncrDecr
                mMsg.Buttons vButtons, sBttnTerminate, BTTN_PASSED, BTTN_FAILED, vbLf, BttnRepeatMaxWidthIncreased, BttnRepeatMaxWidthDecreased
            Case BttnRepeatMaxWidthIncreased
                TestMsgWidthMax = TestMsgWidthMax + TestMsgWidthIncrDecr
                mMsg.Buttons vButtons, sBttnTerminate, BTTN_PASSED, BTTN_FAILED, vbLf, BttnRepeatMaxWidthIncreased, BttnRepeatMaxWidthDecreased
            Case BTTN_PASSED:       wsTest.Passed = True:                   Exit Do
            Case BTTN_FAILED:       wsTest.Failed = True:                   Exit Do ' Stop, Previous, and Next are passed on to the caller
            Case sBttnTerminate:    wsTest.TerminateRegressionTest = True:  Exit Do
        End Select
    
    Loop

xt: Exit Function

eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbResume:  Stop: Resume
        Case Else:      GoTo xt
    End Select
End Function

Public Function Test_06_WidthDeterminedByReplyButtons() As Variant
' ------------------------------------------------------------------------------
'
' ------------------------------------------------------------------------------
    Const PROC      As String = "Test_06_WidthDeterminedByReplyButtons"
    
    On Error GoTo eh
    Dim MsgForm     As fMsg
    Dim MsgTitle    As String
    
    wsTest.TestNumber = 6
    MsgTitle = Readable(PROC)
    MessageInit msg_form:=MsgForm, msg_title:=MsgTitle, caller:=ErrSrc(PROC) ' set test-global message specifications
    
    ' Initializations for this test
    MsgForm.DsplyFrmsWthBrdrsTestOnly = wsTest.TestOptionDisplayFrames
    TestMsgWidthMax = wsTest.MsgWidthMax
    
    With Message.Section(1)
        .Label.Text = "Test description:"
        .Text.Text = wsTest.TestDescription
    End With
    With Message.Section(2)
        .Label.Text = "Expected test result:"
        .Text.Text = "The message form width is adjusted to the space required by the number of reply buttons and all message sections are adjusted to this (enlarged) width."
    End With
    With Message.Section(3)
        .Label.Text = "Please also note:"
        .Text.Text = "The message form height is adjusted to the required height limited only by the specified maximum heigth " & _
                     "which is a percentage of the screen height (for this test = " & PrcPnt(TestMsgHeightMax, "h") & "."
    End With
    vButton4 = "Repeat with 5 buttons"
    vButton5 = "Repeat with 4 buttons"
    vButton6 = "Dummy button"
    
    mMsg.Buttons vButtons, sBttnTerminate, vButton4, vButton5, vButton6, vbLf, BTTN_PASSED, BTTN_FAILED
    
    Do
        Test_06_WidthDeterminedByReplyButtons = _
        mMsg.Dsply(dsply_title:=MsgTitle _
                 , dsply_msg:=Message _
                 , dsply_buttons:=vButtons _
                 , dsply_width_max:=TestMsgWidthMax _
                 , dsply_modeless:=wsTest.TestOptionDisplayModeless _
                  )
        Select Case Test_06_WidthDeterminedByReplyButtons
            Case vButton4
                mMsg.Buttons vButtons, sBttnTerminate, vButton4, vButton5, vButton6, vbLf, BTTN_PASSED, BTTN_FAILED
            Case vButton5
                mMsg.Buttons vButtons, sBttnTerminate, vButton4, vButton5, vbLf, BTTN_PASSED, BTTN_FAILED
            Case BTTN_PASSED:       wsTest.Passed = True:                   Exit Do
            Case BTTN_FAILED:       wsTest.Failed = True:                   Exit Do
            Case sBttnTerminate:    wsTest.TerminateRegressionTest = True:  Exit Do

        End Select
    Loop

xt: Exit Function

eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbResume:  Stop: Resume
        Case Else:      GoTo xt
    End Select
End Function

Public Function Test_07_MonoSpacedSectionWidthExceedsMaxMsgWidth() As Variant
' ------------------------------------------------------------------------------
'
' ------------------------------------------------------------------------------
    Const PROC = "Test_07_MonoSpacedSectionWidthExceedsMaxMsgWidth"
    
    On Error GoTo eh
    Dim MsgForm     As fMsg
    Dim MsgTitle    As String
    
    wsTest.TestNumber = 7
    MsgTitle = Readable(PROC)
    MessageInit msg_form:=MsgForm, msg_title:=MsgTitle, caller:=ErrSrc(PROC) ' set test-global message specifications
    
    '~~ Obtain initial test values from the Test Worksheet
    With wsTest
        TestMsgWidthMin = .MsgWidthMin
        TestMsgWidthMax = .MsgWidthMax
        TestMsgHeightMax = .MsgHeightMax
    End With
    MsgForm.DsplyFrmsWthBrdrsTestOnly = wsTest.TestOptionDisplayFrames
    
    MessageInit msg_form:=MsgForm, msg_title:=MsgTitle, caller:=ErrSrc(PROC) ' set test-global message specifications
    With Message.Section(1)
        .Label.Text = "Test description:"
        .Text.Text = "The width used by the 3rd ""monospaced"" message section exceeds the maximum form width which for this test is " & PrcPnt(TestMsgWidthMax, "w") & "."
    End With
    With Message.Section(2)
        .Label.Text = "Expected test result:"
        .Text.Text = "The monospaced message section comes with a horizontal scrollbar."
    End With
    With Message.Section(3)
        .Label.Text = "Please note the following:"
        .Text.Text = "This (single line!) monspaced message section exceeds the specified maximum form width which for this test is " & PrcPnt(TestMsgWidthMax, "w") & "."
        .Text.MonoSpaced = True
    End With
    mMsg.Buttons vButtons, sBttnTerminate, BTTN_PASSED, BTTN_FAILED
    
    Test_07_MonoSpacedSectionWidthExceedsMaxMsgWidth = _
    mMsg.Dsply(dsply_title:=MsgTitle _
             , dsply_msg:=Message _
             , dsply_buttons:=vButtons _
             , dsply_width_min:=TestMsgWidthMin _
             , dsply_width_max:=TestMsgWidthMax _
             , dsply_height_max:=TestMsgHeightMax _
             , dsply_modeless:=wsTest.TestOptionDisplayModeless _
              )
    Select Case Test_07_MonoSpacedSectionWidthExceedsMaxMsgWidth
        Case BTTN_PASSED:       wsTest.Passed = True
        Case BTTN_FAILED:       wsTest.Failed = True
        Case sBttnTerminate:    wsTest.TerminateRegressionTest = True
    End Select
    
xt: Exit Function

eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbResume:  Stop: Resume
        Case Else:      GoTo xt
    End Select
End Function

Public Function Test_08_MonoSpacedMessageSectionExceedsMaxHeight() As Variant
' ------------------------------------------------------------------------------
'
' ------------------------------------------------------------------------------
    Const PROC = "Test_08_MonoSpacedMessageSectionExceedsMaxHeight"
    
    On Error GoTo eh
    Dim MsgForm     As fMsg
    Dim MsgTitle    As String
    
    wsTest.TestNumber = 8
    MsgTitle = Readable(PROC)
    MessageInit msg_form:=MsgForm, msg_title:=MsgTitle, caller:=ErrSrc(PROC) ' set test-global message specifications
    
    '~~ Obtain initial test values from the Test Worksheet
    With wsTest
        TestMsgWidthMin = .MsgWidthMin
        TestMsgWidthMax = .MsgWidthMax
        TestMsgHeightMax = .MsgHeightMax
    End With
    MsgForm.DsplyFrmsWthBrdrsTestOnly = wsTest.TestOptionDisplayFrames
       
    MessageInit msg_form:=MsgForm, msg_title:=MsgTitle, caller:=ErrSrc(PROC) ' set test-global message specifications
    With Message.Section(1)
        .Label.Text = "Test description:"
        .Text.Text = "The height of the monospaced message section exxceeds the maximum form height (for this test " & _
                      PrcPnt(TestMsgHeightMax, "h") & " of the screen height."
    End With
    With Message.Section(3)
        .Label.Text = "Please note the following:"
        .Text.Text = "The monospaced message's height is reduced to fit the maximum form height and a vertical scrollbar is added."
    End With
    With Message.Section(2)
        .Label.Text = "Expected test result:"
        .Text.Text = RepeatString(25, "This monospaced message comes with a vertical scrollbar." & vbLf, True)
        .Text.MonoSpaced = True
    End With
    mMsg.Buttons vButtons, sBttnTerminate, BTTN_PASSED, BTTN_FAILED
    
    Test_08_MonoSpacedMessageSectionExceedsMaxHeight = _
    mMsg.Dsply(dsply_title:=MsgTitle _
             , dsply_msg:=Message _
             , dsply_buttons:=vButtons _
             , dsply_width_min:=TestMsgWidthMin _
             , dsply_width_max:=TestMsgWidthMax _
             , dsply_height_max:=TestMsgHeightMax _
             , dsply_modeless:=wsTest.TestOptionDisplayModeless _
              )
    Select Case Test_08_MonoSpacedMessageSectionExceedsMaxHeight
        Case BTTN_PASSED:       wsTest.Passed = True
        Case BTTN_FAILED:       wsTest.Failed = True
        Case sBttnTerminate:    wsTest.TerminateRegressionTest = True
    End Select

xt: Exit Function

eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbResume:  Stop: Resume
        Case Else:      GoTo xt
    End Select
End Function

Public Function Test_09_ButtonsOnly() As Variant
    Const PROC = "Test_09_ButtonsOnly"
    
    On Error GoTo eh
    Dim MsgForm             As fMsg
    Dim MsgTitle            As String
    Dim i                   As Long
    Dim cllStory            As New Collection
    Dim vReply              As Variant
    Dim bMonospaced         As Boolean: bMonospaced = True ' initial test value
    
    wsTest.TestNumber = 9
    MsgTitle = Readable(PROC) & ": No message, just buttons (finish with " & BTTN_PASSED & " or " & BTTN_FAILED & ")"
    MessageInit msg_form:=MsgForm, msg_title:=MsgTitle, caller:=ErrSrc(PROC)
    
    '~~ Obtain initial test values and their corresponding change (increment/decrement) value
    '~~ for this test  from the Test Worksheet
    With wsTest
        TestMsgWidthMax = .MsgWidthMax:     TestMsgWidthIncrDecr = .MsgWidthIncrDecr
        TestMsgWidthMin = .MsgWidthMin:     TestMsgHeightIncrDecr = .MsgWidthIncrDecr
        TestMsgHeightMax = .MsgHeightMax
    End With
    If TestMsgWidthIncrDecr = 0 Then Err.Raise AppErr(1), ErrSrc(PROC), "Width increment/decrement must not be 0 for this test!"
    If TestMsgHeightIncrDecr = 0 Then Err.Raise AppErr(1), ErrSrc(PROC), "Height increment/decrement must not be 0 for this test!"
    
    '~~ Assemble the matrix of buttons as collection for  the argument buttons
    For i = 1 To 4 ' rows
        cllStory.Add "Click this button in case ...." & vbLf & "(no lengthy message text above but everything is said in the button)"
        cllStory.Add vbLf
    Next i
    cllStory.Add BTTN_PASSED
    cllStory.Add vbLf
    cllStory.Add BTTN_FAILED
    If sBttnTerminate <> vbNullString Then
        cllStory.Add vbLf
        cllStory.Add sBttnTerminate
    End If
    
    Do
        mMsg.MsgInstance(MsgTitle).DsplyFrmsWthBrdrsTestOnly = wsTest.TestOptionDisplayFrames
        '~~ Obtain initial test values from the Test Worksheet
                         
        Test_09_ButtonsOnly = _
        mMsg.Dsply(dsply_title:=MsgTitle _
                 , dsply_msg:=Message _
                 , dsply_buttons:=cllStory _
                 , dsply_modeless:=wsTest.TestOptionDisplayModeless _
                 , dsply_button_default:=BTTN_PASSED _
                 , dsply_button_width_min:=40 _
                 , dsply_width_min:=TestMsgWidthMin _
                 , dsply_width_max:=TestMsgWidthMax _
                 , dsply_height_max:=TestMsgHeightMax _
                  )
        Select Case Test_09_ButtonsOnly
            Case BTTN_PASSED:       wsTest.Passed = True:                   Exit Do
            Case BTTN_FAILED:       wsTest.Failed = True:                   Exit Do
            Case "Ok":                                                      Exit Do ' The very last item in the collection is the "Finished" button
            Case sBttnTerminate:    wsTest.TerminateRegressionTest = True:  Exit Do

        End Select
    Loop

xt: Exit Function

eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbResume:  Stop: Resume
        Case Else:      GoTo xt
    End Select
End Function

Public Function Test_10_ButtonsMatrix() As Variant
    Const PROC = "Test_10_ButtonsMatrix"
    
    On Error GoTo eh
    Dim MsgForm             As fMsg
    Dim bMonospaced         As Boolean: bMonospaced = True ' initial test value
    Dim i, j                As Long
    Dim MsgTitle            As String
    Dim cllMatrix           As Collection
    Dim lChangeHeightPcntg  As Long
    Dim lChangeWidthPcntg   As Long
    Dim lChangeMinWidthPt   As Long
        
    wsTest.TestNumber = 10
    '~~ Obtain initial test values and their corresponding change (increment/decrement) value
    '~~ for this test  from the Test Worksheet
    With wsTest
        TestMsgWidthMin = .MsgWidthMin:   lChangeMinWidthPt = .MsgWidthIncrDecr
        TestMsgWidthMax = .MsgWidthMax:   lChangeWidthPcntg = .MsgWidthIncrDecr
        TestMsgHeightMax = .MsgHeightMax: lChangeHeightPcntg = .MsgHeightIncrDecr
    End With
    If TestMsgWidthIncrDecr = 0 Then Err.Raise AppErr(1), ErrSrc(PROC), "Width increment/decrement must not be 0 for this test!"
    If TestMsgHeightIncrDecr = 0 Then Err.Raise AppErr(1), ErrSrc(PROC), "Height increment/decrement must not be 0 for this test!"
    
    MsgTitle = "Just to demonstrate what's theoretically possible: Buttons only! Finish with " & BTTN_PASSED & " (default) or " & BTTN_FAILED
    MessageInit msg_form:=MsgForm, msg_title:=MsgTitle, caller:=ErrSrc(PROC) ' set test-global message specifications

    '~~ Assemble the matrix of buttons as collection for  the argument buttons
    Set cllMatrix = New Collection
    For i = 1 To 7 ' rows
        For j = 1 To 7 ' row buttons
            If i = 7 And j = 6 Then
                cllMatrix.Add BTTN_PASSED
                cllMatrix.Add BTTN_FAILED
                Exit For
            Else
                cllMatrix.Add "Button" & vbLf & i & "-" & j
            End If
        Next j
        If i < 7 Then cllMatrix.Add vbLf
    Next i
    
    Do
        '~~ Obtain initial test values from the Test Worksheet
        mMsg.MsgInstance(MsgTitle).DsplyFrmsWthBrdrsTestOnly = wsTest.TestOptionDisplayFrames
                             
        Test_10_ButtonsMatrix = _
        mMsg.Dsply(dsply_title:=MsgTitle _
                 , dsply_msg:=Message _
                 , dsply_buttons:=cllMatrix _
                 , dsply_button_reply_with_index:=False _
                 , dsply_button_default:=BTTN_PASSED _
                 , dsply_button_width_min:=40 _
                 , dsply_width_min:=TestMsgWidthMin _
                 , dsply_width_max:=TestMsgWidthMax _
                 , dsply_height_max:=TestMsgHeightMax _
                 , dsply_modeless:=wsTest.TestOptionDisplayModeless _
                  )
            
        Select Case Test_10_ButtonsMatrix
            Case BTTN_PASSED:       wsTest.Passed = True:                   Exit Do
            Case BTTN_FAILED:       wsTest.Failed = True:                   Exit Do
            Case sBttnTerminate:    wsTest.TerminateRegressionTest = True:  Exit Do
        End Select
    Loop

xt: Exit Function

eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbResume:  Stop: Resume
        Case Else:      GoTo xt
    End Select
End Function

Public Function Test_11_ButtonScrollBarVertical() As Variant
    Const PROC = "Test_11_ButtonScrollBarVertical"
    
    On Error GoTo eh
    Dim MsgForm             As fMsg
    Dim MsgTitle            As String
    Dim i, j                As Long
    Dim cll                 As New Collection
    Dim lChangeHeightPcntg  As Long
    Dim lChangeWidthPcntg   As Long
    Dim lChangeMinWidthPt   As Long
    
    wsTest.TestNumber = 11
    MsgTitle = Readable(PROC)
    MessageInit msg_form:=MsgForm, msg_title:=MsgTitle, caller:=ErrSrc(PROC) ' set test-global message specifications
    
    With wsTest
        TestMsgWidthMin = .MsgWidthMin:   lChangeMinWidthPt = .MsgWidthIncrDecr
        TestMsgWidthMax = .MsgWidthMax:     lChangeWidthPcntg = .MsgWidthIncrDecr
        TestMsgHeightMax = .MsgHeightMax: lChangeHeightPcntg = .MsgHeightIncrDecr
    End With
    If TestMsgWidthIncrDecr = 0 Then Err.Raise AppErr(1), ErrSrc(PROC), "Width increment/decrement must not be 0 for this test!"
    If TestMsgHeightIncrDecr = 0 Then Err.Raise AppErr(1), ErrSrc(PROC), "Height increment/decrement must not be 0 for this test!"
    
    '~~ Obtain initial test values from the Test Worksheet
    MsgForm.DsplyFrmsWthBrdrsTestOnly = wsTest.TestOptionDisplayFrames
    
    MessageInit msg_form:=MsgForm, msg_title:=MsgTitle, caller:=ErrSrc(PROC) ' set test-global message specifications
    With Message.Section(1)
        .Label.Text = "Test description:"
        .Text.Text = "The number of the used reply ""buttons"", their specific order respectively exceeds " & _
                     "the specified maximum forms height - which for this test has been limited to " & _
                     PrcPnt(TestMsgHeightMax, "h") & " of the screen height."
    End With
    With Message.Section(2)
        .Label.Text = "Expected result:"
        .Text.Text = "The height for the vertically ordered buttons is reduced to fit the specified " & _
                     "maximum message form heigth and a vertical scrollbar is applied."
    End With
    With Message.Section(3)
        .Label.Text = "Finish test:"
        .Text.Text = "Click " & BTTN_PASSED & " or " & BTTN_FAILED & " (test is repeated with any other button)"
    End With
    For i = 1 To 5
        For j = 0 To 1
            cll.Add "Reply" & vbLf & "Button" & vbLf & i + j
        Next j
        cll.Add vbLf
    Next i
    cll.Add BTTN_PASSED
    cll.Add BTTN_FAILED
    
    Do
        Test_11_ButtonScrollBarVertical = _
        mMsg.Dsply(dsply_title:=MsgTitle _
                 , dsply_msg:=Message _
                 , dsply_buttons:=cll _
                 , dsply_width_min:=TestMsgWidthMin _
                 , dsply_width_max:=TestMsgWidthMax _
                 , dsply_height_max:=TestMsgHeightMax _
                 , dsply_modeless:=wsTest.TestOptionDisplayModeless _
                  )
        Select Case Test_11_ButtonScrollBarVertical
            Case BTTN_PASSED:       wsTest.Passed = True:                   Exit Do
            Case BTTN_FAILED:       wsTest.Failed = True:                   Exit Do
            Case sBttnTerminate:    wsTest.TerminateRegressionTest = True:  Exit Do
        End Select
    Loop
    
    
xt: Exit Function

eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbResume:  Stop: Resume
        Case Else:      GoTo xt
    End Select
End Function

Public Function Test_12_ButtonScrollBarHorizontal() As Variant

    Const PROC = "Test_12_ButtonScrollBarHorizontal"
    Const INIT_WIDTH = 40
    Const CHANGE_WIDTH = 10
    
    On Error GoTo eh
    Dim MsgForm     As fMsg
    Dim MsgTitle    As String
    Dim Bttn10Plus  As String
    Dim Bttn10Minus As String
    
    wsTest.TestNumber = 12
    MsgTitle = Readable(PROC)
    MessageInit msg_form:=MsgForm, msg_title:=MsgTitle, caller:=ErrSrc(PROC) ' set test-global message specifications
    
    TestMsgWidthMax = INIT_WIDTH
    With wsTest
        TestMsgWidthMin = .MsgWidthMin
        TestMsgHeightMax = .MsgHeightMax
    End With

    Do
        mMsg.MsgInstance(MsgTitle).DsplyFrmsWthBrdrsTestOnly = wsTest.TestOptionDisplayFrames
        
        With Message.Section(1)
            .Label.Text = "Test description:"
            .Text.Text = "The button's width (determined by the longest buttons caption text line), " & _
                         "their number, and the button's order (all in one row) exceeds the form's " & _
                         "maximum width, explicitely specified for this test as " & _
                         PrcPnt(TestMsgWidthMax, "w") & " of the screen width."
        End With
        With Message.Section(2)
            .Label.Text = "Expected result:"
            .Text.Text = "The buttons are dsiplayed with a horizontal scroll bar to meet the specified maximimum form width."
        End With
        With Message.Section(3)
            .Label.Text = "Finish test:"
            .Text.Text = "This test is repeated with any button clicked other than the ""Ok"" button"
        End With
        
        Bttn10Plus = "Repeat with maximum form width" & vbLf & "extended by " & PrcPnt(CHANGE_WIDTH, "w") & " to " & PrcPnt(TestMsgWidthMax, "w")
        Bttn10Minus = "Repeat with maximum form width" & vbLf & "reduced by " & PrcPnt(CHANGE_WIDTH, "w") & " to " & PrcPnt(TestMsgWidthMax, "w")
            
        '~~ Obtain initial test values from the Test Worksheet
    
        mMsg.Buttons vButtons, Bttn10Plus, Bttn10Minus, BTTN_PASSED, BTTN_FAILED
        Test_12_ButtonScrollBarHorizontal = _
        mMsg.Dsply(dsply_title:=MsgTitle _
                 , dsply_msg:=Message _
                 , dsply_buttons:=vButtons _
                 , dsply_width_min:=TestMsgWidthMin _
                 , dsply_width_max:=TestMsgWidthMax _
                 , dsply_modeless:=wsTest.TestOptionDisplayModeless _
                 , dsply_button_default:=BTTN_PASSED _
                  )
        Select Case Test_12_ButtonScrollBarHorizontal
            Case Bttn10Minus:       TestMsgWidthMax = TestMsgWidthMax - CHANGE_WIDTH
            Case Bttn10Plus:        TestMsgWidthMax = TestMsgWidthMax + CHANGE_WIDTH
            Case BTTN_PASSED:       wsTest.Passed = True:                   Exit Do
            Case BTTN_FAILED:       wsTest.Failed = True:                   Exit Do
            Case sBttnTerminate:    wsTest.TerminateRegressionTest = True:  Exit Do
        End Select
    Loop
xt: Exit Function

eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbResume:  Stop: Resume
        Case Else:      GoTo xt
    End Select
End Function

Public Function Test_13_ButtonsMatrix_with_horizomtal_and_vertical_scrollbar() As Variant
    Const PROC = "Test_13_ButtonsMatrix_Horizontal_and_Vertical_Scrollbar"
    
    On Error GoTo eh
    Dim MsgForm                 As fMsg
    Dim i, j                    As Long
    Dim MsgTitle                As String
    Dim cllMatrix               As Collection
    Dim bMonospaced             As Boolean: bMonospaced = True ' initial test value
    Dim TestMsgWidthMin         As Long
    Dim TestMsgWidthMaxSpecInPt As Long
    Dim TestMsgHeightMax        As Long
    
    wsTest.TestNumber = 13
    '~~ Obtain initial test values and their corresponding change (increment/decrement) value
    '~~ for this test  from the Test Worksheet
    With wsTest
        TestMsgWidthMin = .MsgWidthMin
        TestMsgWidthMax = .MsgWidthMax
        TestMsgHeightMax = .MsgHeightMax
    End With
    
    MsgTitle = "Buttons only! With a vertical and a horizontal scrollbar! Finish with " & BTTN_PASSED & " or " & BTTN_FAILED
    MessageInit msg_form:=MsgForm, msg_title:=MsgTitle, caller:=ErrSrc(PROC)  ' set test-global message specifications
    
    '~~ Assemble the matrix of buttons as collection for  the argument buttons
    Set cllMatrix = New Collection
    For i = 1 To 7 ' rows
        For j = 1 To 7 ' row buttons
            If i = 7 And j = 5 Then
                cllMatrix.Add BTTN_PASSED
                cllMatrix.Add BTTN_FAILED
                Exit For
            Else
                cllMatrix.Add vbLf & " ---- Button ---- " & vbLf & i & "-" & j & vbLf & " "
            End If
        Next j
        If i < 7 Then cllMatrix.Add vbLf
    Next i
    
    Do
        '~~ Obtain initial test values from the Test Worksheet
        mMsg.MsgInstance(MsgTitle).DsplyFrmsWthBrdrsTestOnly = wsTest.TestOptionDisplayFrames
                             
        Test_13_ButtonsMatrix_with_horizomtal_and_vertical_scrollbar = _
        mMsg.Dsply(dsply_title:=MsgTitle _
                 , dsply_msg:=Message _
                 , dsply_buttons:=cllMatrix _
                 , dsply_button_reply_with_index:=False _
                 , dsply_button_default:=BTTN_PASSED _
                 , dsply_button_width_min:=40 _
                 , dsply_width_min:=TestMsgWidthMin _
                 , dsply_width_max:=TestMsgWidthMax _
                 , dsply_height_max:=TestMsgHeightMax _
                 , dsply_modeless:=wsTest.TestOptionDisplayModeless _
                  )
        Select Case Test_13_ButtonsMatrix_with_horizomtal_and_vertical_scrollbar
            Case BTTN_PASSED:       wsTest.Passed = True:                   Exit Do
            Case BTTN_FAILED:       wsTest.Failed = True:                   Exit Do
            Case sBttnTerminate:    wsTest.TerminateRegressionTest = True:  Exit Do
        End Select
    Loop

xt: Exit Function

eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbResume:  Stop: Resume
        Case Else:      GoTo xt
    End Select
End Function

Public Function Test_16_ButtonByDictionary()
' -----------------------------------------------
' The buttons argument is provided as Dictionary.
' -----------------------------------------------
    Const PROC  As String = "Test_16_ButtonByDictionary"
    
    Dim dct     As New Collection
    Dim MsgTitle   As String
    Dim MsgForm As fMsg
    
    wsTest.TestNumber = 16
    MsgTitle = "Test: Button by value (" & ErrSrc(PROC) & ")"
    MessageInit msg_form:=MsgForm, msg_title:=MsgTitle, caller:=ErrSrc(PROC) ' set test-global message specifications
    
    '~~ Obtain initial test values from the Test Worksheet
    With wsTest
        TestMsgWidthMin = .MsgWidthMin
        TestMsgWidthMax = .MsgWidthMax
        TestMsgHeightMax = .MsgHeightMax
    End With
    
    MessageInit msg_form:=MsgForm, msg_title:=MsgTitle, caller:=ErrSrc(PROC)  ' set test-global message specifications
    MsgForm.DsplyFrmsWthBrdrsTestOnly = wsTest.TestOptionDisplayFrames
    
    With Message.Section(1)
        .Label.Text = "Test description:"
        .Text.Text = "The ""buttons"" argument is provided as string expression."
    End With
    With Message.Section(2)
        .Label.Text = "Expected result:"
        .Text.Text = "The buttons ""Yes"" an ""No"" are displayed centered in two rows"
    End With
    dct.Add "Yes"
    dct.Add "No"
    
    Test_16_ButtonByDictionary = _
    mMsg.Dsply(dsply_title:=MsgTitle _
             , dsply_msg:=Message _
             , dsply_buttons:=dct _
             , dsply_width_min:=TestMsgWidthMin _
             , dsply_width_max:=TestMsgWidthMax _
             , dsply_height_max:=TestMsgHeightMax _
             , dsply_modeless:=wsTest.TestOptionDisplayModeless _
              )

xt: Exit Function

eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbResume:  Stop: Resume
        Case Else:      GoTo xt
    End Select
End Function

Public Function Test_17_MessageAsString() As Variant
' ------------------------------------------------------------------------------
'
' ------------------------------------------------------------------------------
    Const PROC  As String = "Test_17_Box_MessageAsString"
        
    On Error GoTo eh
    Dim MsgForm     As fMsg
    Dim MsgTitle    As String
    
    wsTest.TestNumber = 17
    MsgTitle = Readable(PROC)
    MessageInit msg_form:=MsgForm, msg_title:=MsgTitle, caller:=ErrSrc(PROC) ' set test-global message specifications
    
    '~~ Obtain initial test values from the Test Worksheet
    With wsTest
        TestMsgWidthMin = .MsgWidthMin
        TestMsgWidthMax = .MsgWidthMax
        TestMsgHeightMax = .MsgHeightMax
    End With
    MsgForm.DsplyFrmsWthBrdrsTestOnly = wsTest.TestOptionDisplayFrames
    
    mMsg.Buttons vButtons, sBttnTerminate, BTTN_PASSED, BTTN_FAILED
        
    Test_17_MessageAsString = _
    mMsg.Box( _
             box_title:=MsgTitle _
           , box_msg:="This is a message provided as a simple string argument!" _
           , box_buttons:=vButtons _
           , box_width_min:=TestMsgWidthMin _
           , box_width_max:=TestMsgWidthMax _
           , box_height_max:=TestMsgHeightMax _
            )
    Select Case Test_17_MessageAsString
        Case BTTN_PASSED:       wsTest.Passed = True
        Case BTTN_FAILED:       wsTest.Failed = True
        Case sBttnTerminate:    wsTest.TerminateRegressionTest = True
    End Select

xt: Exit Function

eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbResume:  Stop: Resume
        Case Else:      GoTo xt
    End Select
End Function

Public Function Test_20_ButtonByValue()

    Const PROC  As String = "Test_20_ButtonByValue"
    
    On Error GoTo eh
    Dim MsgForm     As fMsg
    Dim MsgTitle   As String
    
    wsTest.TestNumber = 20
    MsgTitle = "Test: Button by value (" & PROC & ")"
    MessageInit msg_form:=MsgForm, msg_title:=MsgTitle, caller:=ErrSrc(PROC) ' set test-global message specifications
        
    '~~ Obtain initial test values from the Test Worksheet
    With wsTest
        TestMsgWidthMin = .MsgWidthMin
        TestMsgWidthMax = .MsgWidthMax
        TestMsgHeightMax = .MsgHeightMax
    End With
    MsgForm.DsplyFrmsWthBrdrsTestOnly = wsTest.TestOptionDisplayFrames
    
    MessageInit msg_form:=MsgForm, msg_title:=MsgTitle, caller:=ErrSrc(PROC)  ' set test-global message specifications
    With Message.Section(1)
        .Label.Text = "Test description:"
        .Text.Text = "The ""buttons"" argument is provided as VB MsgBox value vbYesNo."
    End With
    With Message.Section(2)
        .Label.Text = "Expected result:"
        .Text.Text = "The buttons ""Yes"" an ""No"" are displayed centered in one row"
    End With
    Test_20_ButtonByValue = _
    mMsg.Dsply(dsply_title:=MsgTitle _
             , dsply_msg:=Message _
             , dsply_buttons:=vbOKOnly _
             , dsply_width_min:=TestMsgWidthMin _
             , dsply_width_max:=TestMsgWidthMax _
             , dsply_height_max:=TestMsgHeightMax _
             , dsply_modeless:=wsTest.TestOptionDisplayModeless _
              )
            
xt: Exit Function

eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbResume:  Stop: Resume
        Case Else:      GoTo xt
    End Select
End Function

Public Function Test_21_ButtonByString()

    Const PROC  As String = "Test_21_ButtonByString"
    
    On Error GoTo eh
    Dim MsgForm     As fMsg
    Dim MsgTitle    As String
    
    wsTest.TestNumber = 21
    MsgTitle = "Test: Button by value (" & ErrSrc(PROC) & ")"
    MessageInit msg_form:=MsgForm, msg_title:=MsgTitle, caller:=ErrSrc(PROC) ' set test-global message specifications
        
    '~~ Obtain initial test values from the Test Worksheet
    With wsTest
        TestMsgWidthMin = .MsgWidthMin
        TestMsgWidthMax = .MsgWidthMax
        TestMsgHeightMax = .MsgHeightMax
    End With
    MsgForm.DsplyFrmsWthBrdrsTestOnly = wsTest.TestOptionDisplayFrames
    
    MessageInit msg_form:=MsgForm, msg_title:=MsgTitle, caller:=ErrSrc(PROC)  ' set test-global message specifications
    With Message.Section(1)
        .Label.Text = "Test description:"
        .Text.Text = "The ""buttons"" argument is provided as string expression."
    End With
    With Message.Section(2)
        .Label.Text = "Expected result:"
        .Text.Text = "The buttons ""Yes"" an ""No"" are displayed centered in two rows"
    End With
    Test_21_ButtonByString = _
    mMsg.Dsply(dsply_title:=MsgTitle _
             , dsply_msg:=Message _
             , dsply_buttons:="Yes," & vbLf & ",No" _
             , dsply_width_min:=TestMsgWidthMin _
             , dsply_width_max:=TestMsgWidthMax _
             , dsply_height_max:=TestMsgHeightMax _
             , dsply_modeless:=wsTest.TestOptionDisplayModeless _
              )

xt: Exit Function

eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbResume:  Stop: Resume
        Case Else:      GoTo xt
    End Select
End Function

Public Function Test_22_ButtonByCollection()

    Const PROC  As String = "Test_22_ButtonByCollection"
    
    On Error GoTo eh
    Dim MsgForm     As fMsg
    Dim MsgTitle    As String
    Dim cll         As New Collection
    
    wsTest.TestNumber = 22
    MsgTitle = "Test: Button by value (" & ErrSrc(PROC) & ")"
    MessageInit msg_form:=MsgForm, msg_title:=MsgTitle, caller:=ErrSrc(PROC) ' set test-global message specifications
    
    '~~ Obtain initial test values from the Test Worksheet
    With wsTest
        TestMsgWidthMin = .MsgWidthMin
        TestMsgWidthMax = .MsgWidthMax
        TestMsgHeightMax = .MsgHeightMax
    End With
    MsgForm.DsplyFrmsWthBrdrsTestOnly = wsTest.TestOptionDisplayFrames
    
    cll.Add "Yes"
    cll.Add "No"
    
    MessageInit msg_form:=MsgForm, msg_title:=MsgTitle, caller:=ErrSrc(PROC)  ' set test-global message specifications
    With Message.Section(1)
        .Label.Text = "Test description:"
        .Text.Text = "The ""buttons"" argument is provided as string expression."
    End With
    With Message.Section(2)
        .Label.Text = "Expected result:"
        .Text.Text = "The buttons ""Yes"" an ""No"" are displayed centered in two rows"
    End With
    Test_22_ButtonByCollection = _
    mMsg.Dsply(dsply_title:=MsgTitle _
             , dsply_msg:=Message _
             , dsply_buttons:=cll _
             , dsply_width_min:=TestMsgWidthMin _
             , dsply_width_max:=TestMsgWidthMax _
             , dsply_height_max:=TestMsgHeightMax _
             , dsply_modeless:=wsTest.TestOptionDisplayModeless _
              )

xt: Exit Function

eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbResume:  Stop: Resume
        Case Else:      GoTo xt
    End Select
End Function

Public Function Test_30_Monitor() As Variant
    Const PROC = "Test_30_Monitor"
    
    On Error GoTo eh
    Dim MsgForm     As fMsg
    Dim MsgTitle    As String
    Dim i           As Long
    Dim PrgrsHeader As String
    Dim PrgrsMsg    As String
    Dim iLoops      As Long
    Dim lWait       As Long
    
    PrgrsHeader = " No. Status   Step"
    iLoops = 12
    
    wsTest.TestNumber = 30
    MsgTitle = Readable(PROC)
    MessageInit msg_form:=MsgForm, msg_title:=MsgTitle, caller:=ErrSrc(PROC) ' set test-global message specifications
    
    MsgForm.DsplyFrmsWthBrdrsTestOnly = wsTest.TestOptionDisplayFrames
    PrgrsMsg = vbNullString
    
    For i = 1 To iLoops
        PrgrsMsg = mBasic.Align(i, 4, AlignRight, " ") & mBasic.Align("Passed", 8, AlignCentered, " ") & Repeat(repeat_n_times:=Int(((i - 1) / 10)) + 1, repeat_string:="  " & mBasic.Align(i, 2, AlignRight) & ".  Follow-Up line after " & Format(lWait, "0000") & " Milliseconds.")
        If i < iLoops Then
            mMsg.Monitor mntr_title:=MsgTitle _
                       , mntr_msg:=PrgrsMsg _
                       , mntr_msg_monospaced:=True _
                       , mntr_header:=" No. Status  Step"
            '~~ Simmulation of a process
            lWait = 100 * i
            DoEvents
            Sleep 200
        Else
            mMsg.Monitor mntr_title:=MsgTitle _
                       , mntr_msg:=PrgrsMsg _
                       , mntr_header:=" No. Status  Step" _
                       , mntr_footer:="Process finished! Close this window"
        End If
    Next i
    
    mMsg.Buttons vButtons, BTTN_PASSED, BTTN_FAILED
    Select Case mMsg.Box(box_title:="Test result of " & Readable(PROC) _
                       , box_msg:=vbNullString _
                       , box_buttons:=vButtons _
                        )
        Case BTTN_PASSED:       wsTest.Passed = True
        Case BTTN_FAILED:       wsTest.Failed = True
        Case sBttnTerminate:    wsTest.TerminateRegressionTest = True
    End Select

xt: Exit Function

eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbResume:  Stop: Resume
        Case Else:      GoTo xt
    End Select
End Function

Public Function Test_90_All_in_one_Demonstration() As Variant
' ------------------------------------------------------------------------------
' Demo as test of as many features as possible at once.
' ------------------------------------------------------------------------------
    Const PROC              As String = "Test_90_All_in_one_Demonstration"

    On Error GoTo eh
    Dim MsgForm     As fMsg
    Dim MsgTitle    As String
    Dim cll         As New Collection
    Dim i, j        As Long
    Dim Message     As TypeMsg
   
    wsTest.TestNumber = 90
    MsgTitle = Readable(PROC)
    MessageInit msg_form:=MsgForm, msg_title:=MsgTitle, caller:=ErrSrc(PROC) ' set test-global message specifications
    With wsTest
        TestMsgWidthMin = .MsgWidthMin
        TestMsgWidthMax = .MsgWidthMax
        TestMsgHeightMax = .MsgHeightMax
    End With
    MsgForm.DsplyFrmsWthBrdrsTestOnly = wsTest.TestOptionDisplayFrames
    
    With Message.Section(1)
        .Label.Text = "Displayed message summary "
        .Label.FontColor = rgbBlue
        .Label.FontBold = True
        .Text.Text = "- Display of (all) 4 message sections, each with an (optional) label" & vbLf _
                   & "- One monospaced section text exceeding the specified maximum width" & vbLf _
                   & "- Display of some of the 49(7x7) possible reply buttons" & vbLf _
                   & "- Font options like color, bold, and italic"
    End With
    With Message.Section(2)
        .Label.Text = "Unlimited message width"
        .Label.FontColor = rgbBlue
        .Label.FontBold = True
        .Text.Text = "This section's text is mono-spaced and thus not word-wrapped. I.e. the longest line determines the messag width." & vbLf _
                   & "Because the maximimum width for this demo has been specified " & PrcPnt(TestMsgWidthMax, "w") & " of the screen width (defaults to " & PrcPnt(80, "w") & vbLf _
                   & "the text is displayed with a horizontal scrollbar. The size limit for a section's text is only limited by VBA" & vbLf _
                   & "which as about 1GB! (see also unlimited message height below)"
        .Text.MonoSpaced = True
        .Text.FontItalic = True
    End With
    With Message.Section(3)
        .Label.Text = "Unlimited message height"
        .Label.FontColor = rgbBlue
        .Label.FontBold = True
        .Text.Text = "All the message sections together ecxeed the maximum height, specified for this demo " & PrcPnt(TestMsgHeightMax, "h") & " " _
                   & "of the screen height (defaults to " & PrcPnt(85, "h") & ". Thus the message area is displayed with a vertical scrollbar. I. e. no matter " _
                   & "how much text is displayed, it is never truncated. The only limit is VBA's limit for a text " _
                   & "string which is abut 1GB! With 4 strings, each in one section the limit is thus about 4GB !!!!"
    End With
    With Message.Section(4)
        .Label.Text = "Reply buttons flexibility"
        .Label.FontColor = rgbBlue
        .Label.FontBold = True
        .Text.Text = "This demo displays only some of the 49 possible reply buttons (7 rows by 7 buttons). " _
                   & "It also shows that a reply button can have any caption text and the buttons can be " _
                   & "displayed in any order within the 7 x 7 limit. Of cource the VBA.MsgBox classic " _
                   & "vbOkOnly, vbYesNoCancel, etc. are also possible - even in a mixture." & vbLf & vbLf _
                   & "By the way: End this demo with either " & BTTN_PASSED & " or " & BTTN_FAILED & " clicked (else it loops)."
    End With
    '~~ Prepare the buttons collection
    For j = 1 To 1
        For i = 1 To 5
            cll.Add "Sample multiline" & vbLf & "reply button" & vbLf & "Button-" & j & "-" & i
        Next i
        cll.Add vbLf
    Next j
    cll.Add BTTN_PASSED
    cll.Add BTTN_FAILED
        
    Do
        Test_90_All_in_one_Demonstration = _
        mMsg.Dsply(dsply_title:=MsgTitle _
                 , dsply_msg:=Message _
                 , dsply_buttons:=cll _
                 , dsply_button_default:=BTTN_PASSED _
                 , dsply_width_min:=TestMsgWidthMin _
                 , dsply_width_max:=TestMsgWidthMax _
                 , dsply_height_max:=TestMsgHeightMax _
                 , dsply_modeless:=wsTest.TestOptionDisplayModeless _
                  )
        Select Case Test_90_All_in_one_Demonstration
            Case BTTN_PASSED:       wsTest.Passed = True:                   Exit Do
            Case BTTN_FAILED:       wsTest.Failed = True:                   Exit Do
            Case sBttnTerminate:    wsTest.TerminateRegressionTest = True:  Exit Do
        End Select
    Loop
    
xt: Exit Function

eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbResume:  Stop: Resume
        Case Else:      GoTo xt
    End Select
End Function

Public Function Test_91_MinimumMessage() As Variant
' ------------------------------------------------------------------------------
'
' ------------------------------------------------------------------------------
    Const PROC      As String = "Test_91_MinimumMessage"
    
    On Error GoTo eh
    Dim MsgForm     As fMsg
    Dim MsgTitle    As String
    
    wsTest.TestNumber = 1
    MsgTitle = Readable(PROC)
    MessageInit msg_form:=MsgForm, msg_title:=MsgTitle, caller:=ErrSrc(PROC)  ' set test-global message specifications
    
    '~~ Obtain initial test values from the Test Worksheet
    With wsTest
        TestMsgWidthMin = .MsgWidthMin
        TestMsgWidthMax = .MsgWidthMax
        TestMsgHeightMax = .MsgHeightMax
    End With
    MsgForm.DsplyFrmsWthBrdrsTestOnly = wsTest.TestOptionDisplayFrames
    
    TestMsgWidthIncrDecr = wsTest.MsgWidthIncrDecr
    TestMsgHeightIncrDecr = wsTest.MsgHeightIncrDecr
    If TestMsgWidthIncrDecr = 0 Then Err.Raise AppErr(1), ErrSrc(PROC), "Width increment/decrement must not be 0 for this test!"
    If TestMsgHeightIncrDecr = 0 Then Err.Raise AppErr(1), ErrSrc(PROC), "Height increment/decrement must not be 0 for this test!"
    
    With Message.Section(1)
        .Label.Text = "Test description:"
        .Text.Text = wsTest.TestDescription
    End With
    With Message.Section(2)
        .Label.Text = "Expected test result:"
        .Text.Text = "The width of all message sections is adjusted either to the specified minimum form width (" & PrcPnt(TestMsgWidthMin, "w") & ") or " _
                   & "to the width determined by the reply buttons."
    End With
    With Message.Section(3)
        .Label.Text = "Please also note:"
        .Text.Text = "The message form height is adjusted to the required height up to the specified " & _
                     "maximum heigth which is " & PrcPnt(TestMsgHeightMax, "h") & " and not exceeded."
        .Text.FontColor = rgbRed
    End With
                                                                                              
    mMsg.Dsply dsply_title:=MsgTitle _
             , dsply_msg:=Message _
             , dsply_width_min:=TestMsgWidthMin _
             , dsply_width_max:=TestMsgWidthMax _
             , dsply_height_max:=TestMsgHeightMax _
             , dsply_modeless:=wsTest.TestOptionDisplayModeless
             
xt: Exit Function

eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbResume:  Stop: Resume
        Case Else:      GoTo xt
    End Select
End Function

Public Sub Test_99_Individual()
' ---------------------------------------------------------------------------------
' Individual test
' ---------------------------------------------------------------------------------
    Const PROC = "Test_99_Individual"
    
    On Error GoTo eh
    Dim MsgForm     As fMsg
    Dim MsgTitle    As String
    
    MsgTitle = "This title is rather short"
    MessageInit msg_form:=MsgForm, msg_title:=MsgTitle, caller:=ErrSrc(PROC) ' set test-global message specifications
    
    '~~ Obtain initial test values from the Test Worksheet
    TestMsgWidthMax = 80
    MsgForm.DsplyFrmsWthBrdrsTestOnly = wsTest.TestOptionDisplayFrames
    
    MessageInit msg_form:=MsgForm, msg_title:=MsgTitle, caller:=ErrSrc(PROC)  ' set test-global message specifications
    With Message.Section(1)
        .Label.Text = "Test label extra long for this specific test:"
        .Text.Text = "A short message text" & vbLf & _
                     "A short message text" & vbLf & _
                     "A short message text" & vbLf & _
                     "A short message text" & vbLf & _
                     "A short message text"
    End With
    With Message.Section(2)
        .Label.Text = "Test label extra long in order to test the adjustment of the message window width:"
        .Text.Text = "A short message text"
        .Text.MonoSpaced = True
    End With
    With Message.Section(3)
        .Label.Text = "Test label extra long for this specific test:"
        .Text.Text = "A short message text"
    End With
    mMsg.Buttons vButtons, "Button-1", "Button-2"
    mMsg.Dsply dsply_title:=MsgTitle _
             , dsply_msg:=Message _
             , dsply_buttons:=vButtons _
             , dsply_button_default:="Button-1" _
             , dsply_width_min:=30 _
             , dsply_width_max:=TestMsgWidthMax
    
xt: Exit Sub

eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbResume:  Stop: Resume
        Case Else:      GoTo xt
    End Select
End Sub

Private Sub BoP(ByVal b_proc As String, _
           ParamArray b_arguments() As Variant)
' ------------------------------------------------------------------------------
' Begin of Procedure stub. The service is handed over to the corresponding
' procedures in the Common mTrc Component (Execution Trace) or the Common mErH
' Component (Error Handler) provided the components are installed which is
' indicated by the corresponding Conditional Compile Arguments ErHComp = 1 and
' TrcComp = 1.
' ------------------------------------------------------------------------------
    Dim s As String
    If UBound(b_arguments) >= 0 Then s = Join(b_arguments, ",")
#If ErHComp = 1 Then
    mErH.BoP b_proc, s
#ElseIf ExecTrace = 1 And TrcComp = 1 Then
    mTrc.BoP b_proc, s
#End If
End Sub

Private Sub EoP(ByVal e_proc As String, _
       Optional ByVal e_inf As String = vbNullString)
' ------------------------------------------------------------------------------
' End of Procedure stub. Handed over to the corresponding procedures in the
' Common Component mTrc (Execution Trace) or mErH (Error Handler) provided the
' components are installed which is indicated by the corresponding Conditional
' Compile Arguments.
' ------------------------------------------------------------------------------
#If ErHComp = 1 Then
    mErH.EoP e_proc
#ElseIf ExecTrace = 1 And TrcComp = 1 Then
    mTrc.EoP e_proc, e_inf
#End If
End Sub


