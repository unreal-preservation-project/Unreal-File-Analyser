XIncludeFile "UUID4.pbi"
XIncludeFile "Files.pbi"

UseZipPacker()
UseLZMAPacker()
UseTARPacker()

Enumeration ArchiveFormats
	#PB_Archive_NOT
	#PB_Archive_RAR
	#PB_Archive_ZIP
	#PB_Archive_7Z
	#PB_Archive_TAR
EndEnumeration

Procedure GetArchiveFormat(ArchivePath$)
	Select LCase(GetExtensionPart(ArchivePath$))
		Case "rar"
			ProcedureReturn #PB_Archive_RAR
		Case "zip"
			ProcedureReturn #PB_Archive_ZIP
		Case "7z"
			ProcedureReturn #PB_Archive_7Z
		Case "tar"
			ProcedureReturn #PB_Archive_TAR
		Default
			ProcedureReturn #PB_Archive_NOT
	EndSelect
EndProcedure

Procedure PopArchive(ArchivePath$, OutputPath$)
	Protected DirId, WasNotEmpty
	
	OutputPath$ = NormalizePath(OutputPath$)
	
	If Not FileSize(ArchivePath$) >= 0 Or FileSize(OutputPath$) >= 0
		ProcedureReturn #False
	EndIf
	
	If FileSize(OutputPath$) = -2
		; Directory already exists, just ckecing if its empty
		DirId = ExamineDirectory(#PB_Any, OutputPath$)
		WasNotEmpty = NextDirectoryEntry(DirId)
		FinishDirectory(DirId)
		
		If WasNotEmpty
			ProcedureReturn #False
		EndIf
	Else ; -1 implied -> The "dir tree" will be created
		
	EndIf
	
	
EndProcedure

Procedure GetFileListing(ArchivePath$)
	
	
	
EndProcedure

Procedure GetDetailedFileListing(ArchivePath$)
	
	
	
EndProcedure

; - - - - - - - - - -

CompilerIf #PB_Compiler_IsMainFile
	
	
CompilerEndIf

; IDE Options = PureBasic 5.62 (Windows - x64)
; CursorPosition = 48
; FirstLine = 10
; Folding = -
; EnableXP