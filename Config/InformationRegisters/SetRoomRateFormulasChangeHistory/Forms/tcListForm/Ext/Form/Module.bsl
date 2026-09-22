
#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ActionRestore(pCommand)
	OpenForm("Document.SetRoomRateFormulas.Form.tcDocumentForm", New Structure("Key", Items.List.CurrentData.SetRoomRateFormulas));
	
	Notify("SetRoomRateFormulasActionRestore", Items.List.CurrentData.Period);
EndProcedure

#EndRegion
