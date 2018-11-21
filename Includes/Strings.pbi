
; Returns: The number of entries in the Array.
; Source: http://www.purebasic.fr/english/viewtopic.php?f=13&t=41704
Procedure ExplodeStringToArray(Array a$(1), s$, delimeter$, cleanString.b=#True)
	If cleanString
		s$ = Trim(s$, delimeter$)
		
		While FindString(s$, delimeter$+delimeter$)
			s$ = ReplaceString(s$, delimeter$+delimeter$, delimeter$)
		Wend
	EndIf

	Protected count, i
	count = CountString(s$,delimeter$) + 1
	
	Dim a$(count)
	For i = 1 To count
		a$(i - 1) = StringField(s$,i,delimeter$)
	Next
	ProcedureReturn count
EndProcedure

; IDE Options = PureBasic 5.62 (Windows - x64)
; CursorPosition = 21
; Folding = -
; EnableXP