&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	OpenForm("Catalog.RoomQuotas.ListForm", New Structure("AllotmentBusinessType", PredefinedValue("Enum.AllotmentBusinessTypes.BusinessBlock")), pCommandExecuteParameters.Source, "BusinessBlocks", pCommandExecuteParameters.Window, pCommandExecuteParameters.URL);
EndProcedure
