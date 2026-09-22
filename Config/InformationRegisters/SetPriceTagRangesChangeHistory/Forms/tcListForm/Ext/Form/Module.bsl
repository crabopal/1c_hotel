
&AtClient
Procedure ActionRestore(Command)
	OpenForm("Document.SetPriceTagRanges.Form.tcDocumentForm", New Structure("Key", Items.List.CurrentData.SetPriceTagRanges));
	Notify("SetPriceTagRangesActionRestore", Items.List.CurrentData.Period);
EndProcedure
