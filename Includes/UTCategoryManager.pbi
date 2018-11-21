XIncludeFile "Strings.pbi"

; TODO: Add a UUID4 ?

Structure Category
	Id$
	*Parent.Category
	List *Children.Category()
EndStructure

Procedure CreateCategory(Id$, *Parent.Category = #Null)
	If Id$
		Protected *Category.Category = AllocateStructure(Category)
		
		If *Category
			*Category\Id$ = Id$
			If *Parent <> #Null
				LastElement(*Parent\Children())
				If AddElement(*Parent\Children())
					*Parent\Children() = *Category
					*Category\Parent = *Parent
				Else
					FreeStructure(*Category)
					*Category = 0
				EndIf
			EndIf
		EndIf
	EndIf
	
	ProcedureReturn *Category
EndProcedure

Procedure FreeCategory(*Category.Category, FreeChildrens=#True)
	If *Category
		; "Recursing" into childrens
		ForEach *Category\Children()
			FreeCategory(*Category\Children(), FreeChildrens)
		Next
		
		; Cleaning self from parent's list
		If *Category\Parent
			Protected HasBeenDeleted = #False
			
			ForEach *Category\Parent\Children()
				If *Category\Parent\Children() = *Category
					DeleteElement(*Category\Parent\Children(), 1)
					HasBeenDeleted = #True
					Break
				EndIf
				
			Next
			
			If Not HasBeenDeleted
				DebuggerWarning("Children category could not be found in parent's list !")
			EndIf
		EndIf
		
		FreeStructure(*Category)
	EndIf
EndProcedure

Procedure GetCategory(*Root.Category, FullId$, Delimiter$)
	Protected Dim Ids$(0), i.i
	ExplodeStringToArray(Ids$(), FullId$, Delimiter$, #True)
	
	If Not ArraySize(Ids$())
		ProcedureReturn *Root
	EndIf
	
	*CurrentCategory.Category = *Root
	*NewCategory.Category = *Root
	For i=0 To ArraySize(Ids$()) - 1
		ForEach *CurrentCategory\Children()
			If *CurrentCategory\Children()\Id$ = Ids$(i)
				*NewCategory = *CurrentCategory\Children()
				Break
			EndIf
		Next
		
		If *CurrentCategory = *NewCategory
			Debug "Couldn't find desired category"
			*CurrentCategory = 0
			Break
		Else
			*CurrentCategory = *NewCategory
		EndIf
	Next
	
	FreeArray(Ids$())
	ProcedureReturn *CurrentCategory
EndProcedure

Procedure GetSubCategory(*Root.Category, FullId$)
	If *Root
		ForEach *Root\Children()
			If *Root\Children()\Id$ = FullId$
				*TmpPtr.Category = *Root\Children()
				ProcedureReturn *TmpPtr
			EndIf
		Next
	EndIf
	
	ProcedureReturn #Null
EndProcedure

Procedure OrphanCategory(*Category.Category)
	Protected HasBeenDeleted = #False
	
	If *Category
		If *Category\Parent
			ForEach *Category\Parent\Children()
				If *Category\Parent\Children() = *Category
					DeleteElement(*Category\Parent\Children(), 1)
					HasBeenDeleted = #True
					Break
				EndIf
			Next
			
			If Not HasBeenDeleted
				DebuggerWarning("Children category could not be found in parent's list !")
			EndIf
			
			*Category\Parent = #Null
		EndIf
		
		ProcedureReturn #True
	EndIf
	
	ProcedureReturn #False
EndProcedure

; IDE Options = PureBasic 5.62 (Windows - x64)
; CursorPosition = 2
; Folding = -
; EnableXP