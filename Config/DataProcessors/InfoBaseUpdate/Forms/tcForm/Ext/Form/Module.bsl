
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Set the text of the update conditions
	vTemplate = DataProcessors.InfoBaseUpdate.GetTemplate("TermsDistributeUpdates");
	WarningText = vTemplate.GetText();
	Items.FormNext.Enabled = ConfirmSelection;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ConfirmationOnChange(Item)
	Items.FormNext.Enabled = ConfirmSelection;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure Next(Command)
	If ConfirmSelection Then
		Close(True);
	EndIf;
EndProcedure

#EndRegion

