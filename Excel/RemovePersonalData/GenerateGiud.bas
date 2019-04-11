Attribute VB_Name = "GenerateGiud"
Option Explicit

Function Guid() As String
    Guid = RandomHex(3) + "-" + _
        RandomHex(2) + "-" + _
        RandomHex(2) + "-" + _
        RandomHex(2) + "-" + _
        RandomHex(6)
End Function

'From: https://www.mrexcel.com/forum/excel-questions/301472-need-help-generate-hexadecimal-codes-randomly.html#post1479527
Private Function RandomHex(lngCharLength As Long)
    Dim i As Long
    Randomize
    For i = 1 To lngCharLength
        RandomHex = RandomHex & Right$("0" & Hex(Rnd() * 256), 2)
    Next
End Function
