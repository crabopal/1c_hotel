
#Region EventHandlers

//-----------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	vFormParameters = New Structure("RoomRevenueCharge", pCommandParameter);
	OpenForm("Document.Charge.Form.tcRoomRateTotalAmountCharges", vFormParameters, pCommandExecuteParameters.Source, pCommandExecuteParameters.Uniqueness, pCommandExecuteParameters.Window, pCommandExecuteParameters.URL);
EndProcedure

#EndRegion
