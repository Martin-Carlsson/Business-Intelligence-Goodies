VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "SpeedUp"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private StartTime As Double

Sub Enable()
    Dim wks As Worksheet
    
    StartTime = Timer

    Application.StatusBar = "Calculating..."
    Application.ScreenUpdating = False
    Application.DisplayStatusBar = True
    Application.Calculation = xlCalculationManual
    Application.EnableEvents = False
    Application.DisplayAlerts = False
    For Each wks In ThisWorkbook.Worksheets
        wks.DisplayPageBreaks = False
    Next
End Sub

Private Sub Class_Terminate()
    Application.StatusBar = False
    Application.ScreenUpdating = True
    Application.DisplayStatusBar = True
    Application.Calculation = xlCalculationAutomatic
    Application.EnableEvents = True
    Application.DisplayAlerts = True
    If Err.Number <> 0 Then MsgBox "Error: (" & Err.Number & ") " & Err.Description, vbCritical

    Debug.Print "Seconds: " & Round(Timer - StartTime, 2)
End Sub

'On Error Resume Next
'Dim SpeedUp As New SpeedUp: SpeedUp.Enable


