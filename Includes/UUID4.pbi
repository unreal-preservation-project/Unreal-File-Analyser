XIncludeFile "RandomHelper.pbi"

#UUID4_LENGTH = 128/8
#UUID4_REGEX = "^[0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$"

Procedure GenerateUUID4Buffer()
	*UUID4 = AllocateMemory(#UUID4_LENGTH, #PB_Memory_NoClear)
	
	If *UUID4
		GetRandomData(*UUID4, #UUID4_LENGTH)
		PokeA(*UUID4 + 6, 64+GetRandom(15))
		PokeA(*UUID4 + 8, 128+GetRandom(63))
	EndIf
	
	ProcedureReturn *UUID4
EndProcedure

Procedure.s GenerateUUID4String()
	Protected i.b, UUID$, Dim _UUID4Bytes.b(#UUID4_LENGTH)
	
	For i=0 To #UUID4_LENGTH-1
		_UUID4Bytes(i)=GetRandom(255)
	Next
	_UUID4Bytes(6)=64+GetRandom(15)
	_UUID4Bytes(8)=128+GetRandom(63)
	
	For i=0 To #UUID4_LENGTH-1
		If i=4 Or i=6 Or i=8 Or i=10
			UUID$+"-"
		EndIf
		UUID$+RSet(Hex(_UUID4Bytes(i)&$FF),2,"0")
	Next
	
	FreeArray(_UUID4Bytes())
	ProcedureReturn UUID$
EndProcedure

Procedure CompareUUID4(*UUID4_1, *UUID4_2)
	If *UUID4_1 And *UUID4_2 And MemorySize(*UUID4_1) >= #UUID4_LENGTH And MemorySize(*UUID4_2) >= #UUID4_LENGTH
		ProcedureReturn CompareMemory(*UUID4_1, *UUID4_2, #UUID4_LENGTH)
	EndIf
	
	DebuggerError("One or more null pointer(*x) were given to compare against one another, or they didn't have the right size!")
	ProcedureReturn #False
EndProcedure

; IDE Options = PureBasic 5.62 (Windows - x64)
; CursorPosition = 22
; FirstLine = 3
; Folding = -
; EnableXP
; Executable = uuid4-test.exe