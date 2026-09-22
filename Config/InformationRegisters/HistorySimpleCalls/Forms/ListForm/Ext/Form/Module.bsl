
#Region FormTableItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ListSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	If pField.Name = "File" Then
		BeginRunningApplication(New NotifyDescription, pItem.CurrentData.File);
	EndIf;
	pStandardProcessing = False;
EndProcedure

#EndRegion

