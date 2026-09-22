#Region EventHandlers

// ----------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	vFilter = Undefined;
	If TypeOf(pCommandParameter) = Type("CatalogRef.GuestGroups") Then
		vFilter = New Structure("GuestGroup", pCommandParameter);
	ElsIf TypeOf(pCommandParameter) = Type("CatalogRef.Customers") Then		
		vFilter = New Structure("Customer", pCommandParameter);
	ElsIf TypeOf(pCommandParameter) = Type("CatalogRef.Contracts") Then		
		vFilter = New Structure("Contract", pCommandParameter);
	EndIf;
	
	vFormParameters = New Structure("Filter", vFilter);
	
	OpenForm("Document.Folio.ListForm", vFormParameters, pCommandExecuteParameters.Source, pCommandExecuteParameters.Uniqueness, pCommandExecuteParameters.Window, pCommandExecuteParameters.URL);
EndProcedure // CommandProcessing

#EndRegion
