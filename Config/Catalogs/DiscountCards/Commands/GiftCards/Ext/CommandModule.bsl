
#Region EventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)   
	vFilter = New Structure("SelMode", 2);
	
	OpenForm("Catalog.DiscountCards.ListForm", vFilter, , New UUID, pCommandExecuteParameters.Window, pCommandExecuteParameters.URL);
EndProcedure

#EndRegion
