# MsgBox Alternative

Displays a message in a dialog box, waits for the user to click a button, and returns a variant indicating which button the user clicked.

### Why an alternative MsgBox?
The alternative implementation addresses many of the MsgBox's deficiencies - without re-implementing it to 100%.

| VB MsgBox | Alternative |
| ------ | ---- |
| The message width and height is limited and cannot be altered | The maximum width and height is specified as a percentage of the screen size which defaults 80% width and  90% height (hardly ever used)|
| When a message exceeds the (hard to tell) size limit it is truncated | When the maximum size is exceeded a vertical and/or a horizontal scroll bar is applied
| The message is displayed with a proportional font | A message may (or part of it) may be displayed mono-spaced |
| Composing a fair designed message is time consuming and it is difficult to come up with a satisfying result | Up to 3 _Message Sections_ each with an optional _Message Text Label_ and a _Monospaced_ option allow an appealing design without any extra  effort |
| The maximum reply _Buttons_ is 3 | Up to 7 reply _Buttons_ may be displayed in up to 7 reply _Button Rows_ in any order |
| The caption of the reply _Buttons_ is based on a value (vbOKOnly=0, 	vbOKCancel=1, vbAbortRetryIgnore=2, vbYesNoCancel=	3, vbYesNo=	4, vbRetryCancel=5) which result in 1 to 3 reply _Buttons_ with corresponding untranslated native English captions | The caption of the reply _Buttons_ may be specified by those values known from the VB MsgBox but additionally allows any multi-line text |
| Specifying the default button | (yet) not implemented |
| Display of an ?, !, etc. image | (yet) not implemented |

## Interfaces
The alternative implementation  comes with three functions (in module _mMsg_) which are the interface to the UserForm _fMsg_ and return the clicked reply _Button_ value to the caller.

### _Box_ (see [example](#simple-message))

Pretty MsgBox alike, displays a single message with any number of line breaks, with up to 7 reply _buttons_ in up to 7 rows in any order.

#### Syntax
```
mMsg.Box prompt[, buttons][, title]
```
or alternatively when the clicked reply button matters:
```
Select Case mMsg.Box(prompt[, buttons][, title])
   Case ....
   Case ....
End Select
```
The _Box_ function syntax has these named arguments:

| Part | Description | Corresponding _fMsg_ Property |
| ---- |-----------| --- |
| title | Optional. String expression displayed in the title bar of the dialog box. When omitted, the application name is placed in the title bar. | Title |
| prompt | String expression displayed as message. There is no length limit. When the maximum height or width is exceeded a vertical and/or horizontal scrollbars is displayed. Lines may be separated by using a carriage return character (vbCr or Chr(13), a linefeed character (vbLf or Chr(10)), or carriage return - linefeed character combination (vbCrLf or Chr(13) & Chr(10)) between each line. | Text(1) |
| buttons | Optional.  Variant expression, either MsgBox values like vbOkOnly, vbYesNo, etc. or a comma delimited string specifying the caption of up to 7 reply buttons. If omitted, the default value for buttons is 0 (vbOkOnly). | Buttons |

### _Msg_ (see [example](#common-message))
Displays a message in up to 3 sections, each with an optional label and optionally monospaced and up to 7 buttons in up to 7 rows in any order.
#### Syntax
```
mMsg.Msg(title _
[[, label1][, text1][, monospaced1]] _
[[, label2][, text2][, monospaced2]] _
[[, label3][, text3][, monospaced3]] _
[,buttons])
```
The _Msg_ function syntax has these named arguments:

| Part | Description | Corresponding _fMsg_ Property |
| ---- |-----------| --- |
| title | Optional. String expression displayed in the title bar of the dialog box. When omitted, the application name is placed in the title bar. | Title |
| label1<br>label2<br>label3 | Optional. String expression displayed as label above the corresponding text_ | Label(section) |
| text1<br>text2<br>text3 | Optional.  String expression displayed as message section. There is no length limit. When the maximum height or width is exceeded a vertical and/or horizontal scrollbars is displayed. Lines may be separated by using a carriage return character (vbCr or Chr(13), a linefeed character (vbLf or Chr(10)), or carriage return - linefeed character combination (vbCrLf or Chr(13) & Chr(10)) between each line. | Text(section) | monospaced1<br>monospaced2<br>monospaced3 | Optional. Defaults to False. When True,  the corresponding text is displayed with a mono-spaced font see [Proportional- versus Mono-spaced](#proportional-versus-mono-spaced) | Monospaced(section)
| buttons | Optional.  Variant expression, either MsgBox values like vbOkOnly, vbYesNo, etc. or a comma delimited string specifying the caption of up to 7 reply buttons. If omitted, the default value for buttons is 0 (vbOkOnly). | Buttons |

### _ErrMsg_ (see [example](#error-message))
Displays an appealingly designed error message. This function is pretty specific because it is used by a common, nevertheless elaborated, error handler (yet not available on GitHub) with 
#### Syntax
```
mMsg.ErrMsg(errnumber _
[, errsource][, errdescription][, errline][, errtitle][, errpath[, errinfo]
```
| Part | Description | Corresponding _fMsg_ Property |
| ---- |-----------| --- |
| errnumber | Optional. Defaults to 0. A number expression. |
| errsource | Optional. Defaults to vbNullString. String expression indicating the fully qualified name of the procedure where the error occoured. | - |
| errdescription | String expression displayed as top message section with an above label "Error Description". There is no length limit. When the maximum height or width is exceeded a vertical and/or horizontal scrollbars is displayed. Lines may be separated by using a carriage return character (vbLf or Chr(10)), or carriage return - linefeed character combination (vbCrLf or Chr(13) & Chr(10)) between each line. | Text(1) |
| errline | Optional. Defaults to vbNullString. String expression indicating the line number within the error causing procedure's module where the error occured or had bee raised. | - |
| errtitle | Optional. String expression displayed in the title bar of the dialog box. When not provided, the title is assembled by using errnumber, errsource, and errline. | AppTitle |
| errpath | Optional. The "call stack" from the entry procedure down to the error source procedure. Displayed mono-spaced in order to allow a properly indented layout | Text(2), Monospaced(2) see [Proportional- versus Mono-spaced](#proportional-versus-mono-spaced) |
| errinfo | Optional. Defaults to vbNullString. String expression providing an additional information about the error. Displayed under a label "Additional information". When not provided, the string is extracted from the errdescription which follows an "||" indication.| Text(3) |

### Syntax of the _buttons_ argument
```
button:=string|value[, rowbreak][, button2][, rowbreak][, button3][, rowbreak][, button4][, rowbreak][, button5][, rowbreak][, button6][, rowbreak][, button7]
```
| | |
|-|-|
string, button2 ... button7| captions for the buttons 1 to 7|
|value|the VB MsgBox argument for 1 to 3 buttons all in one row|
|rowbreak| vbLf or Chr(10). Indicates that the next button is displayed in the row below|

## Installation

- Download
  - fMsg.frm
  - fmsg.frx
  - mMsg.bas
- Import
  - fMsf.frm
  - mMsg.bas

## Usage, Examples

### Simple message

image

### Error message

image

### Common message

image


### Examples Summary
The examples above illustrate the use of the 3 functions (interfaces) in the module _mMsg_: _Box_, _Msg_, _ErrMsg_ using the UserForm _fMsg_

Considering the [Common Public Properties](<Implementation.md#common-public-properties>) of the UserForm and the mechanism to receive the return value of the clicked reply button some can go ahead without the installation of the _mMsg_ module and implement his/her own application specific message function using those already implemented as examples only.

## Proportional versus Mono-Spaced

#### _Monospaced_ = True

Because the text is ++not++  "wrapped" the width of the _Message Form_ is determined by the longest text line (up to the _Maximum Form Width_ specified). When the maximum width is exceeded a vertical scroll bar is applied.<br>Note: The title and the broadest _Button Row_ May still determine an even broader final _Message Form_.

#### _Monospaced_ = False (default)
Because the text is "wrapped"
the width of a proportional-spaced text is determined by the current form width.<br>Note: When a message is displayed exclusively proportional-spaced the _Message Form_ width is determined by the length of the title, the required space for the broadest _Buttons Row_ and the specified _Minimum Form Width_.