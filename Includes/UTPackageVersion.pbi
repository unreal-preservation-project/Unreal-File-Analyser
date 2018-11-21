; As described in:
; http://eliotvu.com/page/unreal-package-file-format

Enumeration UnrealEngineVersion
	; U and U2 are also missing (U could be 69 since it's the same engine ?)
	#UE_UT99 = 69
	; UT2003 is missing from the docs :/
	#UE_UT_UT2004 = 128
	#UE_UT_UT3 = 512
	
	; Is UT4 fixed or one of those ?
	#UE_UDK_November = 648
	#UE_UDK_December = 664
	#UE_UDK_January = 678
	#UE_UDK_May = 706
	
	#UE_UNKNOWN = 1
EndEnumeration

Procedure GetPackageEngineVersion(FilePath$, ReturnNegativeOnError.b = #False, ReturnUnchangedVersion.b = #False)
	Protected FileID, EngineVersion = #UE_UNKNOWN
	
	If FileSize(FilePath$) < 6
		If ReturnNegativeOnError
			ProcedureReturn -1
		Else
			ProcedureReturn 0
		EndIf
	EndIf
	
	FileID = ReadFile(#PB_Any, FilePath$)
	
	If Not FileID
		If ReturnNegativeOnError
			ProcedureReturn -2
		Else
			ProcedureReturn 0
		EndIf
	EndIf
	
	ReadLong(FileID)
	EngineVersion = ReadWord(FileID)
	
	CloseFile(FileID)
	
	If Not ReturnUnchangedVersion
		If EngineVersion <> #UE_UT99 And
		   EngineVersion <> #UE_UT_UT2004 And
		   EngineVersion <> #UE_UT_UT3 And
		   EngineVersion <> #UE_UDK_November And
		   EngineVersion <> #UE_UDK_December And
		   EngineVersion <> #UE_UDK_January And
		   EngineVersion <> #UE_UDK_May
			; The number read is not supported
			EngineVersion = #UE_UNKNOWN
		EndIf
	EndIf
	
	ProcedureReturn EngineVersion
EndProcedure

CompilerIf #PB_Compiler_IsMainFile
	Debug GetPackageEngineVersion("D:\Jeux\UnrealTournament\Textures\Ascorp.utx", #True, #True)
CompilerEndIf

; IDE Options = PureBasic 5.62 (Windows - x64)
; CursorPosition = 4
; Folding = -
; EnableXP