#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure IsImportantDateOnChange(pItem)
	If Object.IsImportantDate Then
		Object.ValueType = GetDateTypeDescription();
	EndIf;
EndProcedure // IsImportantDateOnChange

#EndRegion

#Region Internal

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetDateTypeDescription()
	Return cmGetDateTypeDescription();
EndFunction // GetDateTypeDescription

#EndRegion

