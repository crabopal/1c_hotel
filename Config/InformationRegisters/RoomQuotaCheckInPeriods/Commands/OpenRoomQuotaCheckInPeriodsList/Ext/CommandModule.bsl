

#Region EventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	FormParameters = New Structure("RoomQuota",pCommandParameter);
	OpenForm("InformationRegister.RoomQuotaCheckInPeriods.ListForm", FormParameters, pCommandExecuteParameters.Source, pCommandExecuteParameters.Uniqueness, pCommandExecuteParameters.Window, pCommandExecuteParameters.URL);
EndProcedure

#EndRegion
