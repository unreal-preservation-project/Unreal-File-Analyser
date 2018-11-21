XIncludeFile "UUID4.pbi"

Structure UUID4
	*UUID4
EndStructure

Procedure GenerateUUID4Structure()
	Protected *UUID4.UUID4 = AllocateMemory(SizeOf(*UUID4))
	
	If *UUID4
		*UUID4\UUID4 = GenerateUUID4Buffer()
		If Not *UUID4\UUID4
			FreeMemory(*UUID4)
			*UUID4 = #Null
		EndIf
	EndIf
	
	ProcedureReturn *UUID4
EndProcedure

Procedure FreeUUID4Struct(*UUID4.UUID4)
	FreeMemory(*UUID4\UUID4)
	FreeMemory(*UUID4)
EndProcedure

Procedure CompareUUID4Struct(*UUID4_1.UUID4, *UUID4_2.UUID4)
	If *UUID4_1 And *UUID4_2
		ProcedureReturn CompareMemory(*UUID4_1\UUID4, *UUID4_2\UUID4, #UUID4_LENGTH)
	EndIf
	
	DebuggerError("One or more null pointer(*x.UUID4) were given to compare against one another !")
	ProcedureReturn #False
EndProcedure

Procedure.s GetUUID4StructString(*UUID4.UUID4)
	Protected UUID4$ = #Null$, i.i
	
	If *UUID4
		For i=0 To #UUID4_LENGTH-1
			If i=4 Or i=6 Or i=8 Or i=10
				UUID4$+"-"
			EndIf
			
			UUID4$+RSet(Hex(PeekB(*UUID4\UUID4+i)&$FF),2,"0")
		Next
	EndIf
	
	ProcedureReturn UUID4$
EndProcedure

; - - - - -

CompilerIf #PB_Compiler_IsMainFile
	Define i.i
	
	For i=1 To 200
		UUID4 = GenerateUUID4Structure()
		Debug GetUUID4StructString(UUID4)
		FreeUUID4Struct(UUID4)
	Next
CompilerEndIf

; IDE Options = PureBasic 5.62 (Windows - x64)
; Folding = -
; EnableXP