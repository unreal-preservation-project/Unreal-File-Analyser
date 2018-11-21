; UMOD file format info: http://www.unrealtexture.com/Unreal/Downloads/3DEditing/UnrealEd/Tutorials/unrealwiki-offline/umod-file-format.html

; A previous version of this file(without checks and some stuff) can be found at:
;     * https://gist.github.com/aziascreations/b477e52fe19559a4edc6cc621603de39
;     * https://pastebin.com/cEW3XgyZ

#UMOD_MAGIC_NBR = $9FE3C5A3

Enumeration UmodFileBits
	#UMOD_FILE_REGULAR = $00
	#UMOD_FILE_MANIFEST = $03	
EndEnumeration

Enumeration UmodError 1
	#ERROR_UMOD_IO_SIZE
	#ERROR_UMOD_IO_READ
	#ERROR_UMOD_MALLOC
	#ERROR_UMOD_INVALID_HEADER
	#ERROR_UMOD_INVALID_DIR_ENTRY
	#ERROR_UMOD_INVALID_CRC
	#ERROR_UMOD_MALFORMED_DIRECTORY
	#ERROR_UMOD_MISSING_MANIFEST
	#ERROR_UMOD_OVERLAPPING_FILES ; Between each other and/or the directory/header
EndEnumeration

; All variables using the .l type are technically unsigned in the format...
; And it is located at the end of the file, because header==footer...
Structure UmodHeader
	DirectoryOffset.l
	UmodSize.l
	UmodFileVersion.l
	CRC32.l ; Not sure.
EndStructure

Structure UmodDirectoryEntry
	FilenameLength.a ; A trailling 0x00 is counted in ! (So Len(Filename$) == this - 1)
	Filename$
	FileByteOffset.l
	FileLength.l
	FileBitFields.l
	
	;FileCRC32$
	;FileMD5$
	;FileSHA1$
	; And other hashes if required
EndStructure

Structure Umod
	Header.UmodHeader
	Array DirectoryEntries.UmodDirectoryEntry(0)
	Array *FileData(0)
	
	Filename$
EndStructure

; TODO: Handle the .l as unsigned long instead of signed one, this WILL cause errors down the line on bigger UMODs!
;       Should only be a problem when the umod's size gets close to 2GiB

; INFO: filename size - http://www.unrealtexture.com/Unreal/Downloads/3DEditing/UnrealEd/Tutorials/unrealwiki-offline/umod-creating.html

Procedure LoadUmodMetadata(Path$, CompleteVerification.b = #True)
	Protected *Umod.Umod, i.i, Filename$, FileId, ErrorCode = 0, CurrentArrayIndex
	
	If FileSize(Path$) < 0
		ProcedureReturn #ERROR_UMOD_IO_SIZE * -1
	EndIf
	
	FileId = ReadFile(#PB_Any, Path$, #PB_File_SharedRead | #PB_Ascii)
	If Not FileId
		ProcedureReturn #ERROR_UMOD_IO_READ * -1
	EndIf
	
	*Umod = AllocateStructure(Umod)
	If Not *Umod
		ProcedureReturn #ERROR_UMOD_MALLOC * -1
	EndIf
	
	; Reading the header...
	FileSeek(FileId, Lof(FileId)-SizeOf(UmodHeader)-4, #PB_Absolute)
	; Fuck this, I'm using GOTOs, I don't want to deal with a bunch of nested IFs and spaghetti.
	If Not UCase(Hex(ReadLong(FileId), #PB_Long)) = UCase("9FE3C5A3")
		ErrorCode = #ERROR_UMOD_INVALID_HEADER
		Goto LUM_END
	EndIf
	*Umod\Header\DirectoryOffset = ReadLong(FileId)
	*Umod\Header\UmodSize = ReadLong(FileId)
	*Umod\Header\UmodFileVersion = ReadLong(FileId)
	*Umod\Header\CRC32 = ReadLong(FileId)
	
	; TODO: Add some directory position checks before reading it
	
	; Reading the directory...
	FileSeek(FileId, *Umod\Header\DirectoryOffset + 1, #PB_Absolute)
	Repeat
		CurrentArrayIndex = ArraySize(*Umod\DirectoryEntries())
		Filename$ = ""
		
		ReDim *Umod\DirectoryEntries(CurrentArrayIndex+1)
		ReDim *Umod\FileData(CurrentArrayIndex+1)
		
		*Umod\DirectoryEntries(CurrentArrayIndex)\FilenameLength = ReadAsciiCharacter(FileId)
		
		For i=0 To *Umod\DirectoryEntries(CurrentArrayIndex)\FilenameLength -2
			Filename$ = Filename$ + Chr(ReadAsciiCharacter(FileId))
		Next
		
		If Not ReadAsciiCharacter(FileId) = #Null
			DebuggerWarning("0x00 wasn't found at the end of the filename !")
			ErrorCode = #ERROR_UMOD_INVALID_DIR_ENTRY
			Goto LUM_END
		EndIf
		
		*Umod\DirectoryEntries(CurrentArrayIndex)\Filename$ = Filename$
		
		*Umod\DirectoryEntries(CurrentArrayIndex)\FileByteOffset = ReadLong(FileId)
		*Umod\DirectoryEntries(CurrentArrayIndex)\FileLength = ReadLong(FileId)
		*Umod\DirectoryEntries(CurrentArrayIndex)\FileBitFields = ReadLong(FileId)
		
		; TODO: Add file position against header and directory check here
	Until Loc(FileId) >= Lof(FileId)-SizeOf(UmodHeader)-4
	
	; TODO: Add a file position check here between files., And a manifest one too
	
	; TODO: Check if manifest is present too
	
	*Umod\Filename$ = GetFilePart(Path$)
	
	LUM_END:
	If ErrorCode
		FreeStructure(*Umod)
		*Umod = ErrorCode * -1
	EndIf
	
	CloseFile(FileId)
	
	ProcedureReturn *Umod
EndProcedure

; This procedure assumes that you didn't change the file between operations or renamed it.
Procedure LoadUmod(Path$, *Umod.Umod = #Null, CompleteVerification.b = #True, FreeOnError.b = #False)
	Protected i.i, ErrorCode = 0, FileId
	
	If Not *Umod
		*Umod = LoadUmodMetadata(Path$, CompleteVerification)
		If *Umod <= 0
			ProcedureReturn *Umod
		EndIf
		; If not freed when only accessible within this scope memory leaks will occur if an error occurs
		FreeOnError = #True
	EndIf
	
	If FileSize(Path$) < 0 Or *Umod\Filename$ <> GetFilePart(Path$)
		ErrorCode = #ERROR_UMOD_IO_SIZE
		Goto LU_END
	EndIf
	
	FileId = ReadFile(#PB_Any, Path$, #PB_File_SharedRead | #PB_Ascii)
	If Not FileId
		ErrorCode = #ERROR_UMOD_IO_READ
		Goto LU_END
	EndIf
	
	For i=0 To ArraySize(*Umod\DirectoryEntries())-1
		*Umod\FileData(i) = AllocateMemory(*Umod\DirectoryEntries(i)\FileLength, #PB_Memory_NoClear)
		If Not *Umod\FileData(i)
			ErrorCode = #ERROR_UMOD_MALLOC
			Goto LU_END
		EndIf
		FileSeek(FileId, *Umod\DirectoryEntries(i)\FileByteOffset, #PB_Absolute)
		ReadData(FileId, *Umod\FileData(i), MemorySize(*Umod\FileData(i)))
	Next
	
	LU_END:
	If ErrorCode
		For i=0 To ArraySize(*Umod\DirectoryEntries()) - 1
			If *Umod\FileData(i)
				FreeMemory(*Umod\FileData(i))
			EndIf
		Next
		
		If FreeOnError
			FreeStructure(*Umod)
		EndIf
		
		*Umod = ErrorCode * -1
	EndIf
	
	CloseFile(FileId)
	
	ProcedureReturn*Umod
EndProcedure

;- Manifest Reader?

Procedure DebugUmodStructure(*Umod.Umod, PrintFileContent=#True)
	Protected i.i
	
	If *Umod <= 0
		DebuggerWarning("DebugUmodStructure => *Umod <= 0")
		ProcedureReturn
	EndIf
	
	Debug "Header:"
	Debug #TAB$+"Dir. Offset: 0x" + Hex(*Umod\Header\DirectoryOffset)
	Debug #TAB$+"Size (B):    " + Str(*Umod\Header\UmodSize)
	Debug #TAB$+"UMOD Ver.:   0x" + Hex(*Umod\Header\UmodFileVersion) + " ("+Str(*Umod\Header\UmodFileVersion)+")"
	Debug #TAB$+"CRC?:        0x" + Hex(*Umod\Header\CRC32, #PB_Long)
	Debug ""
	
	Debug "File directory:"
	For i=0 To ArraySize(*Umod\DirectoryEntries())-1
		Debug #TAB$+"Filename len.: "+*Umod\DirectoryEntries(i)\FilenameLength
		Debug #TAB$+"Filename:      "+*Umod\DirectoryEntries(i)\Filename$
		Debug #TAB$+"Data offset:   0x"+Hex(*Umod\DirectoryEntries(i)\FileByteOffset) + " ("+Str(*Umod\DirectoryEntries(i)\FileByteOffset)+")"
		Debug #TAB$+"Data length:   "+*Umod\DirectoryEntries(i)\FileLength+" (bytes)"
		Debug #TAB$+"Bit fields:    0x"+Hex(*Umod\DirectoryEntries(i)\FileBitFields)+" | 0b"+Bin(*Umod\DirectoryEntries(i)\FileBitFields)
		Debug ""
	Next
	
	If PrintFileContent
		Debug "File content: (Base64)"
		For i=0 To ArraySize(*Umod\DirectoryEntries())-1
			Debug #TAB$+*Umod\DirectoryEntries(i)\Filename$+":"
			If *Umod\FileData(i)
				Debug #TAB$+Base64Encoder(*Umod\FileData(i), MemorySize(*Umod\FileData(i)))
			Else
				Debug #TAB$+"> File not loaded into memory !"
			EndIf
			Debug ""
		Next
	EndIf
	
	Debug "END"
EndProcedure

Procedure GetUmodDirectoryArray(*Umod.Umod, Array Filepaths$(1))
	Protected i.i
	
	If Not *Umod
		ProcedureReturn #False
	EndIf
	
	ReDim Filepaths$(ArraySize(*Umod\DirectoryEntries()))
	
	For i=0 To ArraySize(*Umod\DirectoryEntries()) - 1
		Filepaths$(i) = *Umod\DirectoryEntries(i)\Filename$
	Next
	
	ProcedureReturn #True
EndProcedure

Procedure GetUmodFileIndex(*Umod.Umod, Filepath$)
	Protected i.i
	
	If *Umod > 0
		For i=0 To ArraySize(*Umod\DirectoryEntries()) - 1
			If *Umod\DirectoryEntries(i)\Filename$ = Filepath$
				ProcedureReturn i
			EndIf
		Next
	EndIf
	
	ProcedureReturn -1
EndProcedure

Procedure GetUmodFileBuffer(*Umod.Umod, Filepath$)
	Protected Index.i
	
	If *Umod > 0
		Index = GetUmodFileIndex(*Umod.Umod, Filepath$)
		If Index > -1
			ProcedureReturn *Umod\FileData(Index)
		EndIf
	EndIf
	
	ProcedureReturn #Null
EndProcedure

Procedure FreeUmod(*Umod.Umod)
	Protected i.i
	
	If *Umod > 0
		For i=0 To ArraySize(*Umod\DirectoryEntries()) - 1
			If *Umod\FileData(i)
				FreeMemory(*Umod\FileData(i))
			EndIf
		Next
		
		If FreeOnError
			FreeStructure(*Umod)
		EndIf
	EndIf
EndProcedure

Procedure SaveUmodFileByIndex(*Umod.Umod, FileIndex.i, Destination$, AllowOverwrite = #False);, KeepFolderStructure = #False)
	If Right(Destination$, 1) <> "/" And Right(Destination$, 1) <> "\"
		Destination$ = Destination$ + "/"
	EndIf
	
	If *Umod > 0 And FileSize(Destination$) = -2 And ArraySize(*Umod\DirectoryEntries()) >= FileIndex + 1 And *Umod\FileData(FileIndex) <> #Null
		Filename$ = GetFilePart(*Umod\DirectoryEntries(FileIndex)\Filename$)
		
		If FileSize(Destination$+Filename$) >= 0
			If AllowOverwrite 
				If Not DeleteFile(Destination$+Filename$, #PB_FileSystem_Force)
					ProcedureReturn #False
				EndIf
			Else
				ProcedureReturn #False
			EndIf
		EndIf
		
		FileId = CreateFile(#PB_Any, Destination$+Filename$)
		If FileId
			WriteData(FileId, *Umod\FileData(FileIndex), MemorySize(*Umod\FileData(FileIndex)))
			CloseFile(FileId)
			
			Debug "Extracted "+Filename$+" successfully !"
			
			ProcedureReturn #True
		EndIf
	EndIf
	
	ProcedureReturn #False
EndProcedure

; Procedure SaveUmodFileByName(*Umod.Umod, Filename$, Destination$, Overwrite = #False)
; 	
; EndProcedure

CompilerIf #PB_Compiler_IsMainFile
	#UMOD_DECALSTAY$ = "Test-Umod\DecalStay.umod"
	#UMOD_EXCESSIVE$ = "Test-Umod\Excessive100.umod"
	
	DebugUmodStructure(LoadUmod(#UMOD_DECALSTAY$, #Null))
	Debug #CRLF$+#CRLF$+"###############################"+#CRLF$+#CRLF$
	
	*UmodExcessive = LoadUmodMetadata(#UMOD_EXCESSIVE$)
	DebugUmodStructure(*UmodExcessive)
	Debug #CRLF$+#CRLF$+"###############################"+#CRLF$+#CRLF$
	
	DebugUmodStructure(LoadUmod(#UMOD_EXCESSIVE$, *UmodExcessive))
	
	SaveUmodFileByIndex(*UmodExcessive, 3, "./WorkingDir/", #True)
	
	; Powershell speedtest: 
	;    Command: Measure-Command {.\speed-test01.exe}
	;    1st run: ~50ms (Files were read by another program recently so they might have been sitting somewhere in memory ?)
	;    subsequent runs: <10ms
CompilerEndIf

; IDE Options = PureBasic 5.62 (Windows - x64)
; CursorPosition = 63
; FirstLine = 37
; Folding = --
; EnableXP
; Executable = speed-test01.exe