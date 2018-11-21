Global IsRandomCryptoSafe = #False

; CompilerIf #NoCryptRND = #True
; 	
; CompilerEndIf

Macro InitCryptRandom()
	IsRandomCryptoSafe = OpenCryptRandom()
EndMacro

Macro EndCryptRandom()
	If IsRandomCryptoSafe
		IsRandomCryptoSafe = #False
		CloseCryptRandom()
	EndIf
EndMacro

Macro GetRandomData(Buffer, Length)
	CompilerIf #PB_Compiler_Debugger
		If Not MemorySize(Buffer) = Length
			If MemorySize(Buffer) < Length
				DebuggerWarning("Random data generated will barf itself in memory (outside the buffer)!")
			Else
				DebuggerWarning("Buffer size and random data length desired aren't the same!")
			EndIf
		EndIf
	CompilerEndIf
	
	If IsRandomCryptoSafe
		CryptRandomData(Buffer, Length)
	Else
		RandomData(Buffer, Length)
	EndIf
EndMacro

Procedure GetRandom(Maximum)
	If IsRandomCryptoSafe
		CryptRandom(Maximum)
	Else
		Random(Maximum)
	EndIf
EndProcedure

; TODO add a compiler check if a #NoCryptRND constant is set to avoid openning it since they may have backdoors if PB uses "in-CPU" RNG.
InitCryptRandom()

CompilerIf #PB_Compiler_Debugger
	If Not IsRandomCryptoSafe
		DebuggerWarning("No cryptographic safe random number generator is available on the system !")
	EndIf
CompilerEndIf

; IDE Options = PureBasic 5.62 (Windows - x64)
; CursorPosition = 42
; FirstLine = 9
; Folding = -
; EnableXP