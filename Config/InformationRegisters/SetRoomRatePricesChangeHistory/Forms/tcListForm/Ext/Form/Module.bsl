
&AtClient
Procedure ActionRestore(Command)
	OpenForm("Document.SetRoomRatePrices.Form.tcDocumentForm", New Structure("Key", Items.List.CurrentData.SetRoomRatePrices));
	Notify("SetRoomRatePricesActionRestore", Items.List.CurrentData.Period);
EndProcedure
