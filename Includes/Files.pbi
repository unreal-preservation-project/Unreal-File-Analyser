
Procedure.s NormalizePath(Path$)
	If Not Right(Path$, 1) = "/" And Not Right(Path$, 1) = "\"
		; Couldn't find the constant that do that automatically	
		CompilerIf #PB_Compiler_OS = #PB_OS_Windows
			Path$+"\"
		CompilerElse
			Path$+"/"
		CompilerEndIf
	EndIf
	
	; TODO: Fix the rest of the slashes ?
	
	ProcedureReturn Path$
EndProcedure


; This is just a concept, Might be used to cleanup the code in one of the main program loops, not much space is saved but meh...
Procedure WalkDirectoryTree(Path$, *CallbackOnItem, Flags, Filter="*.*")
	
	
EndProcedure

; CallBack(BasePath==Path$[0], AbsolutePath, RelativePath, Flags(DIR/FILE, ...))

; - - - - - - - - - -

CompilerIf #PB_Compiler_IsMainFile
	
	
	
	
	
CompilerEndIf

; IDE Options = PureBasic 5.62 (Windows - x64)
; CursorPosition = 17
; Folding = -
; EnableXP