Attribute VB_Name = "SwapDataPointsForGuid"
Option Explicit
Private DataPointGuid As New Dictionary

Sub Run()
    Dim Cell As Object
    
    If MoreThanOneColumnsSelected Then
        MsgBox "Please only select one column"
        Exit Sub
    End If

    For Each Cell In Selection.Cells
        Cell = SwapDataPointForGuid(Cell.Value2)
    Next Cell

    ActiveWorkbook.RefreshAll
    
    Set DataPointGuid = Nothing
End Sub

Private Function SwapDataPointForGuid(DataPoint As String) As String
    If Not DataPointGuid.Exists(DataPoint) Then
        DataPointGuid(DataPoint) = Guid()
    End If
    
    SwapDataPointForGuid = DataPointGuid(DataPoint)
End Function

Private Function MoreThanOneColumnsSelected() As Boolean
    Dim Column As Object
    Dim Count As Integer
    
    Count = 0
    For Each Column In Selection.Columns
        Count = Count + 1
        
        If Count > 1 Then
            MoreThanOneColumnsSelected = True
            Exit Function
        End If
    Next Column
    
    MoreThanOneColumnsSelected = False
End Function


