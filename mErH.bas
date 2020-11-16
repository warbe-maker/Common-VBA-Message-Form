Attribute VB_Name = "mErH"
Option Explicit
Option Private Module
' -----------------------------------------------------------------------------------------------
' Standard  Module mErrHndlr: Global error handling for any VBA Project.
'
' Methods: - AppErr   Converts a positive number into a negative error number ensuring it not
'                     conflicts with a VB Runtime Error. A negative error number is turned back into the
'                     original positive Application  Error Number.
'          - ErrMsg Either passes on the error to the caller or when the entry procedure is
'                     reached, displays the error with a complete path from the entry procedure
'                     to the procedure with the error.
'          - BoP      Maintains the call stack at the Begin of a Procedure (optional when using
'                     this common error handler)
'          - EoP      Maintains the call stack at the End of a Procedure, triggers the display of
'                     the Execution Trace when the entry procedure is finished and the
'                     Conditional Compile Argument ExecTrace = 1
'          - ErrDsply Displays the error message in a proper formated manner
'                     The local Conditional Compile Argument "AlternativeMsgBox = 1" enforces the use
'                     of the Alternative VBA MsgBox which provideds an improved readability.
'
' Usage:   Private/Public Sub/Function any()
'              Const PROC = "any"  ' procedure's name as error source
'
'              On Error GoTo eh
'              mErH.BoP ErrSrc(PROC)   ' puts the procedure on the call stack
'
'              ' <any code>
'
'          xt: ' <any "finally" code like re-protecting an unprotected sheet for instance>
'                               mErH.EoP ErrSrc(PROC)   ' takes the procedure off from the call stack
'                               Exit Sub/Function
'
'           eh: mErH.ErrMsg err_source:=ErrSrc(PROC)
'           End ....
'
' Note: When never a mErH.BoP/mErH.EoP procedure had been executed the ErrMsg
'       is displayed with the procedure the error occoured. Else the error is
'       passed on back up to the first procedure with a mErH.BoP/mErH.EoP code
'       line executed and displayed when it had been reached.
'
' Uses: fMsg
'       mTrc (optionally, when the Conditional Compile Argument ExecTrace = 1)
'
' Requires: Reference to "Microsoft Scripting Runtime"
'
'          For further details see the Github blog post
'          "A comprehensive common VBA Error Handler inspired by the best of the web"
' https://warbe-maker.github.io/vba/common/2020/10/02/Comprehensive-Common-VBA-Error-Handler.html
'
' W. Rauschenberger, Berlin, Nov 2020
' -----------------------------------------------------------------------------------------------

Public Const CONCAT         As String = "||"

Public Enum StartupPosition         ' ---------------------------
    Manual = 0                      ' Used to position the
    CenterOwner = 1                 ' final setup message form
    CenterScreen = 2                ' horizontally and vertically
    WindowsDefault = 3              ' centered on the screen
End Enum                            ' ---------------------------

Public Type tSection                ' ------------------
       sLabel As String             ' Structure of the
       sText As String              ' UserForm's
       bMonspaced As Boolean        ' message area which
End Type                            ' consists of
Public Type tMessage                ' three message
       section(1 To 4) As tSection  ' sections
End Type                            ' -------------------

Private cllErrPath          As Collection
Private cllErrorPath        As Collection   ' managed by ErrPath... procedures exclusively
Private dctStck             As Dictionary
Private sErrHndlrEntryProc  As String
Private lSubsequErrNo       As Long ' a number possibly different from lInitialErrNo when it changes when passed on to the Entry Procedure

' Test button, displayed with Conditional Compile Argument Test = 1
Public Property Get ExitAndContinue() As String:        ExitAndContinue = "Exit procedure" & vbLf & "and continue" & vbLf & "with next":    End Property

' Debugging button, displayed with Conditional Compile Argument Debugging = 1
Public Property Get ResumeError() As String:            ResumeError = "Resume" & vbLf & "error code line":                                  End Property

' Test button, displayed with Conditional Compile Argument Test = 1
Public Property Get ResumeNext() As String:             ResumeNext = "Continue with code line" & vbLf & "following the error line":         End Property

' Default error message button
Public Property Get ErrMsgDefaultButton() As String:    ErrMsgDefaultButton = "Terminate execution":                                                  End Property

Private Property Get StckEntryProc() As String
    If Not StckIsEmpty _
    Then StckEntryProc = dctStck.Items()(0) _
    Else StckEntryProc = vbNullString
End Property

Public Function AppErr(ByVal err_no As Long) As Long
' -----------------------------------------------------------------
' Used with Err.Raise AppErr(<l>).
' When the error number <l> is > 0 it is considered an "Application
' Error Number and vbObjectErrror is added to it into a negative
' number in order not to confuse with a VB runtime error.
' When the error number <l> is negative it is considered an
' Application Error and vbObjectError is added to convert it back
' into its origin positive number.
' ------------------------------------------------------------------
    If err_no < 0 Then
        AppErr = err_no - vbObjectError
    Else
        AppErr = vbObjectError + err_no
    End If
End Function

Public Sub BoP(ByVal s As String)
' ----------------------------------
' Trace and stack Begin of Procedure
' ----------------------------------
    Const PROC = "BoP"
    
    On Error GoTo eh
    
    StckPush s
#If ExecTrace Then
    mTrc.BoP s    ' start of the procedure's execution trace
#End If

xt: Exit Sub

eh: MsgBox Err.Description, vbOKOnly, "Error in " & ErrSrc(PROC)
    Stop: Resume
End Sub

Public Sub EoP(ByVal s As String)
' --------------------------------
' Trace and stack End of Procedure
' --------------------------------
#If ExecTrace Then
    mTrc.EoP s
    mErH.StckPop s
#End If
End Sub

Public Function ErrMsg( _
                  ByVal err_source As String, _
         Optional ByVal err_number As Long = 0, _
         Optional ByVal err_dscrptn As String = vbNullString, _
         Optional ByVal err_line As Long = 0, _
         Optional ByVal err_buttons As Variant = vbNullString, _
         Optional ByVal err_asserted = 0) As Variant
' ----------------------------------------------------------------------
' When the errbuttons argument specifies more than one button the error
' message is immediately displayed and the users choice is returned,
' else when the caller (err_source) is the "Entry Procedure" the error
' is displayed with the path to the error,
' else the error is passed on to the "Entry Procedure" whereby the
' .ErrorPath string is assebled.
' ----------------------------------------------------------------------
    
    Static sLine                As String   ' provided error line (if any) for the the finally displayed message
    Static lInitialErrNo        As Long
    Static lInitialErrLine      As Long
    Static sInitialErrSource    As String
    Static sInitialErrDscrptn   As String
    Static sInitialErrInfo      As String
    Dim sDetails                As String
        
    If err_number = 0 Then err_number = Err.Number
    If err_dscrptn = vbNullString Then err_dscrptn = Err.Description
    If err_line = 0 Then err_line = Erl
    
    If ErrHndlrFailed(err_number, err_source, err_buttons) Then GoTo xt
    If cllErrPath Is Nothing Then Set cllErrPath = New Collection
    If err_line <> 0 Then sLine = err_line Else sLine = "0"
    ErrHndlrManageButtons err_buttons
    ErrMsgMatter err_source:=err_source, err_no:=err_number, err_line:=err_line, err_dscrptn:=err_dscrptn, msg_details:=sDetails
    
    If sInitialErrSource = vbNullString Then
        '~~ This is the initial/first execution of the error handler within the error raising procedure.
        sInitialErrInfo = sDetails
        lInitialErrLine = err_line
        lInitialErrNo = err_number
        sInitialErrSource = err_source
        sInitialErrDscrptn = err_dscrptn
    ElseIf err_number <> lInitialErrNo _
        And err_number <> lSubsequErrNo _
        And err_source <> sInitialErrSource Then
        '~~ In the rare case when the error number had changed during the process of passing it back up to the entry procedure
        lSubsequErrNo = err_number
        sInitialErrInfo = sDetails
    End If
    
    If ErrBttns(err_buttons) = 1 _
    And sErrHndlrEntryProc <> vbNullString _
    And StckEntryProc <> err_source Then
        '~~ When the user has no choice to press any button but the only one displayed button
        '~~ and the Entry Procedure is known but yet not reached the error is passed on back
        '~~ up to the Entry Procedure whereupon the path to the error is assembled
        ErrPathAdd err_source
#If ExecTrace Then
        mTrc.EoP err_source, sInitialErrInfo
#End If
        mErH.StckPop Itm:=err_source
        sInitialErrInfo = vbNullString
        Err.Raise err_number, err_source, err_dscrptn
    End If
    
    If ErrBttns(err_buttons) > 1 _
    Or StckEntryProc = err_source _
    Or StckEntryProc = vbNullString Then
        '~~ When the user has the choice between several errbuttons displayed
        '~~ or the Entry Procedure is unknown or has been reached
        If Not ErrPathIsEmpty Then ErrPathAdd err_source
        '~~ Display the error message
#If ExecTrace Then
    mTrc.Pause
#End If

#If Test Then
        '~~ When the Conditional Compile Argument Test = 1 and the error number is one asserted
        '~~ the display of the error message is suspended to avoid a user interaction
        If lInitialErrNo <> err_asserted _
        Then ErrMsg = ErrDsply(err_source:=sInitialErrSource, err_number:=lInitialErrNo, err_dscrptn:=sInitialErrDscrptn, err_line:=lInitialErrLine, err_buttons:=err_buttons)
#Else
        ErrMsg = ErrDsply(err_number:=lInitialErrNo, err_line:=lInitialErrLine, err_buttons:=err_buttons)
#End If

#If ExecTrace Then
    mTrc.Continue
#End If
        Select Case ErrMsg
            Case ResumeError, ResumeNext, ExitAndContinue
            Case Else: ErrPathErase
        End Select
#If ExecTrace Then
        mTrc.EoP err_source, sInitialErrInfo
#End If
        mErH.StckPop Itm:=err_source
        sInitialErrInfo = vbNullString
        sInitialErrSource = vbNullString
        sInitialErrDscrptn = vbNullString
        lInitialErrNo = 0
    End If
    
'    '~~ Each time a known Entry Procedure is reached the execution trace
'    '~~ maintained by the BoP and mErH.EoP and the BoC and EoC statements is displayed
'    If StckEntryProc = err_source _
'    Or StckEntryProc = vbNullString Then
'        Select Case ErrMsg
'            Case ResumeError, ResumeNext, ExitAndContinue
'            Case vbOK
'            Case Else: StckErase
'        End Select
'    End If
'    mErH.StckPop err_source

xt:
#If ExecTrace Then
'    mTrc.Continue
#End If
End Function

Private Sub ErrHndlrManageButtons(ByRef err_buttons As Variant)

    If err_buttons = vbNullString _
    Then err_buttons = ErrMsgDefaultButton _
    Else ErrHndlrAddButtons ErrMsgDefaultButton, err_buttons ' add the default button before the errbuttons specified
    
'~~ Special features are only available with the Alternative VBA MsgBox
#If Debugging Or Test Then
    ErrHndlrAddButtons err_buttons, vbLf ' errbuttons in new row
#End If
#If Debugging Then
    ErrHndlrAddButtons err_buttons, ResumeError
#End If
#If Test Then
     ErrHndlrAddButtons err_buttons, ResumeNext
     ErrHndlrAddButtons err_buttons, ExitAndContinue
#End If

End Sub
Private Function ErrHndlrFailed( _
        ByVal err_number As Long, _
        ByVal err_source As String, _
        ByVal err_buttons As Variant) As Boolean
' ------------------------------------------
'
' ------------------------------------------

    If err_number = 0 Then
        MsgBox "The error handling has been called with an error number = 0 !" & vbLf & vbLf & _
               "This indicates that in procedure" & vbLf & _
               ">>>>> " & err_source & " <<<<<" & vbLf & _
               "an ""Exit ..."" statement before the call of the error handling is missing!" _
               , vbExclamation, _
               "Exit ... statement missing in " & err_source & "!"
                ErrHndlrFailed = True
        Exit Function
    End If
    
    If IsNumeric(err_buttons) Then
        '~~ When err_buttons is a numeric value, only the VBA MsgBox values for the button argument are supported
        Select Case err_buttons
            Case vbOKOnly, vbOKCancel, vbYesNo, vbRetryCancel, vbYesNoCancel, vbAbortRetryIgnore
            Case Else
                MsgBox "When the errbuttons argument is a numeric value Only the valid VBA MsgBox vaulues are supported. " & _
                       "For valid values please refer to:" & vbLf & _
                       "https://docs.microsoft.com/en-us/office/vba/Language/Reference/User-Interface-Help/msgbox-function" _
                       , vbOKOnly, "Only the valid VBA MsgBox vaulues are supported!"
                ErrHndlrFailed = True
                Exit Function
        End Select
    End If

End Function

Private Sub ErrHndlrAddButtons(ByRef v1 As Variant, _
                               ByRef v2 As Variant)
' ---------------------------------------------------
' Returns v1 followed by v2 whereby both may be a
' errbuttons argument which means  a string, a
' Dictionary or a Collection. When v1 is a Dictionary
' or Collection v2 must be a string or long and vice
' versa.
' ---------------------------------------------------
    
    Dim dct As New Dictionary
    Dim cll As New Collection
    Dim v   As Variant
    
    Select Case TypeName(v1)
        Case "Dictionary"
            Select Case TypeName(v2)
                Case "String", "Long": v1.Add v2, v2
                Case Else ' Not added !
            End Select
        Case "Collection"
            Select Case TypeName(v2)
                Case "String", "Long": v1.Add v2
                Case Else ' Not added !
            End Select
        Case "String", "Long"
            Select Case TypeName(v2)
                Case "String"
                    v1 = v1 & "," & v2
                Case "Dictionary"
                    dct.Add v1, v1
                    For Each v In v2
                        dct.Add v, v
                    Next v
                    Set v2 = dct
                Case "Collection"
                    cll.Add v1
                    For Each v In v2
                        cll.Add v
                    Next v
                    Set v2 = cll
            End Select
    End Select
    
End Sub

Public Function ErrDsply( _
                ByVal err_source As String, _
                ByVal err_number As Long, _
                ByVal err_dscrptn As String, _
                ByVal err_line As Long, _
       Optional ByVal err_buttons As Variant = vbOKOnly) As Variant
' -----------------------------------------------------------------
' Displays the error message either by means of VBA MsgBox or, when
' the Conditional Compile Argument AlternativeMsgBox = 1 by means
' of the Alternative VBA MsgBox (UserForm fMsg). In any case the
' path to the error may be displayed, provided the entry procedure
' has BoP/EoP code lines.
'
' W. Rauschenberger, Berlin, Sept 2020
' -------------------------------------------------------------
    
    Dim sErrPath    As String
    Dim sTitle      As String
    Dim sErrLine    As String
    Dim sDetails    As String
    Dim sDscrptn    As String
    Dim sInfo       As String
    Dim sSource     As String
    
    ErrMsgMatter err_source:=err_source, err_no:=err_number, err_line:=err_line, err_dscrptn:=err_dscrptn, _
                 msg_title:=sTitle, msg_line:=sErrLine, msg_details:=sDetails, msg_source:=sSource, msg_dscrptn:=sDscrptn, msg_info:=sInfo
    sErrPath = ErrPathErrMsg(msg_details:=sDetails, err_source:=err_source)
    '~~ Display the error message by means of the Common UserForm fMsg
    With fMsg
        .MsgTitle = sTitle
        .MsgLabel(1) = "Error description:":        .MsgText(1) = sDscrptn
        .MsgLabel(2) = "Error source:":             .MsgText(2) = sSource & sErrLine:   .MsgMonoSpaced(2) = True
        .MsgLabel(3) = "Error path (call stack):":  .MsgText(3) = sErrPath:             .MsgMonoSpaced(3) = True
        .MsgLabel(4) = "Info:":                     .MsgText(4) = sInfo
        .MsgButtons = err_buttons
        .Setup
        .Show
        If ErrBttns(err_buttons) = 1 Then
            ErrDsply = err_buttons ' a single reply errbuttons return value cannot be obtained since the form is unloaded with its click
        Else
            ErrDsply = .ReplyValue ' when more than one button is displayed the form is unloadhen the return value is obtained
        End If
    End With

End Function

Private Function ErrBttns( _
                 ByVal bttns As Variant) As Long
' ------------------------------------------------
' Returns the number of specified bttns.
' ------------------------------------------------
    Dim v As Variant
    
    For Each v In Split(bttns, ",")
        If IsNumeric(v) Then
            Select Case v
                Case vbOKOnly:                              ErrBttns = ErrBttns + 1
                Case vbOKCancel, vbYesNo, vbRetryCancel:    ErrBttns = ErrBttns + 2
                Case vbAbortRetryIgnore, vbYesNoCancel:     ErrBttns = ErrBttns + 3
            End Select
        Else
            Select Case v
                Case vbNullString, vbLf, vbCr, vbCrLf
                Case Else:  ErrBttns = ErrBttns + 1
            End Select
        End If
    Next v

End Function

Private Sub ErrMsgMatter(ByVal err_source As String, _
                         ByVal err_no As Long, _
                         ByVal err_line As Long, _
                         ByVal err_dscrptn As String, _
                Optional ByRef msg_title As String, _
                Optional ByRef msg_type As String, _
                Optional ByRef msg_line As String, _
                Optional ByRef msg_no As Long, _
                Optional ByRef msg_details As String, _
                Optional ByRef msg_dscrptn As String, _
                Optional ByRef msg_info As String, _
                Optional ByRef msg_source As String)
' -------------------------------------------------------
' Returns all the matter to build a proper error message.
' -------------------------------------------------------
                
    If InStr(1, err_source, "DAO") <> 0 _
    Or InStr(1, err_source, "ODBC Teradata Driver") <> 0 _
    Or InStr(1, err_source, "ODBC") <> 0 _
    Or InStr(1, err_source, "Oracle") <> 0 Then
        msg_type = "Database Error "
    Else
      msg_type = IIf(err_no > 0, "VB-Runtime Error ", "Application Error ")
    End If
   
    msg_line = IIf(err_line <> 0, "at line " & err_line, vbNullString)     ' Message error line
    msg_no = IIf(err_no < 0, err_no - vbObjectError, err_no)                ' Message error number
    msg_title = msg_type & msg_no & " in " & err_source & " " & msg_line             ' Message title
    msg_details = IIf(err_line <> 0, msg_type & msg_no & " in " & err_source & " (at line " & err_line & ")", msg_type & msg_no & " in " & err_source)
    msg_dscrptn = IIf(InStr(err_dscrptn, CONCAT) <> 0, Split(err_dscrptn, CONCAT)(0), err_dscrptn)
    If InStr(err_dscrptn, CONCAT) <> 0 Then msg_info = Split(err_dscrptn, CONCAT)(1)
    msg_source = Application.Name & ":  " & Application.ActiveWindow.Caption & ":  " & err_source
    
End Sub

Private Sub ErrPathAdd(ByVal s As String)
    
    If cllErrorPath Is Nothing Then Set cllErrorPath = New Collection _

    If Not ErrPathItemExists(s) Then
        Debug.Print s & " added to path"
        cllErrorPath.Add s ' avoid duplicate recording of the same procedure/item
    End If
End Sub

Private Function ErrPathItemExists(ByVal s As String) As Boolean

    Dim v As Variant
    
    For Each v In cllErrorPath
        If InStr(v & " ", s & " ") <> 0 Then
            ErrPathItemExists = True
            Exit Function
        End If
    Next v
    
End Function

Private Sub ErrPathErase()
    Set cllErrorPath = Nothing
End Sub

Private Function ErrPathErrMsg(ByVal msg_details As String, _
                               ByVal err_source) As String
' ------------------------------------------------------------------
' Returns the error path for being displayed in the error message.
' ------------------------------------------------------------------
    
    Dim i   As Long
    Dim j   As Long
    Dim s   As String
    
    ErrPathErrMsg = vbNullString
    If Not ErrPathIsEmpty Then
        '~~ When the error path is not empty and not only contains the error source procedure
        For i = cllErrorPath.Count To 1 Step -1
            s = cllErrorPath.TrcEntryItem(i)
            If i = cllErrorPath.Count _
            Then ErrPathErrMsg = s _
            Else ErrPathErrMsg = ErrPathErrMsg & vbLf & Space(j * 2) & "|_" & s
            j = j + 1
        Next i
    Else
        '~~ When the error path is empty the stack may provide an alternative information
        If Not StckIsEmpty Then
            For i = 0 To dctStck.Count - 1
                If ErrPathErrMsg <> vbNullString Then
                   ErrPathErrMsg = ErrPathErrMsg & vbLf & Space((i - 1) * 2) & "|_" & dctStck.Items()(i)
                Else
                   ErrPathErrMsg = dctStck.Items()(i)
                End If
            Next i
        End If
        ErrPathErrMsg = ErrPathErrMsg & " " & msg_details
    End If
End Function

Private Function ErrPathIsEmpty() As Boolean
    ErrPathIsEmpty = cllErrorPath Is Nothing
    If Not ErrPathIsEmpty Then ErrPathIsEmpty = cllErrorPath.Count = 0
End Function

Private Function ErrSrc(ByVal sProc As String) As String
    ErrSrc = "mErH." & sProc
End Function

Public Function Space(ByVal l As Long) As String
' --------------------------------------------------
' Unifies the VB differences SPACE$ and Space$ which
' lead to code diferences where there aren't any.
' --------------------------------------------------
    Space = VBA.Space$(l)
End Function

Private Function StckBottom() As String
    If Not StckIsEmpty Then StckBottom = dctStck.Items()(0)
End Function

Private Sub StckErase()
    If Not dctStck Is Nothing Then dctStck.RemoveAll
End Sub

Public Function StckIsEmpty() As Boolean
    StckIsEmpty = dctStck Is Nothing
    If Not StckIsEmpty Then StckIsEmpty = dctStck.Count = 0
End Function

Private Function StckPop( _
       Optional ByVal Itm As String = vbNullString) As String
' -----------------------------------------------------------
' Returns the popped of the stack. When itm is provided and
' is not on the top of the stack pop is suspended.
' -----------------------------------------------------------
    Const PROC = "StckPop"
    
    On Error GoTo eh

    If Not StckIsEmpty Then
        If Itm <> vbNullString And StckTop = Itm Then
            StckPop = dctStck.Items()(dctStck.Count - 1) ' Return the poped item
            dctStck.Remove dctStck.Count                  ' Remove item itm from stack
        ElseIf Itm = vbNullString Then
            dctStck.Remove dctStck.Count                  ' Unwind! Remove item itm from stack
        End If
    End If
    
xt: Exit Function

eh: MsgBox Err.Description, vbOKOnly, "Error in " & ErrSrc(PROC)
End Function

Private Sub StckPush(ByVal s As String)

    If dctStck Is Nothing Then Set dctStck = New Dictionary
    If dctStck.Count = 0 Then
        sErrHndlrEntryProc = s ' First pushed = bottom item = entry procedure
#If ExecTrace Then
        mTrc.Terminate ' ensures any previous trace is erased
#End If
    End If
    dctStck.Add dctStck.Count + 1, s

End Sub

Private Function StckTop() As String
    If Not StckIsEmpty Then StckTop = dctStck.Items()(dctStck.Count - 1)
End Function

