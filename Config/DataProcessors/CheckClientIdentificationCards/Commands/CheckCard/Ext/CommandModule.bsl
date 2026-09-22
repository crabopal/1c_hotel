#Region EventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	OpenForm("DataProcessor.CheckClientIdentificationCards.Form.tcForm", , pCommandExecuteParameters.Source, pCommandExecuteParameters.Uniqueness, , , , FormWindowOpeningMode.LockWholeInterface);
EndProcedure // CommandProcessing

#EndRegion
