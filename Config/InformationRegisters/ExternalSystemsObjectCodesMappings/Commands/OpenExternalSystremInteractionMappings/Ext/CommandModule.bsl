
#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	vInteractionID = TrimAll(tcOnServer.cmGetAttributeByRef(pCommandParameter, "InteractionID")); 
	vExtCode = TrimAll(tcOnServer.cmGetAttributeByRef(pCommandParameter, "Code"));
	vCurHotel = tcOnServer.cmGetAttributeByRef(pCommandParameter, "Hotel");
	If ValueIsFilled(vCurHotel) Then
		vHotels = New Array;
		vHotels.Add(tcOnServer.cmGetAttributeByRef(pCommandParameter, "Hotel"));
		vHotels.Add(PredefinedValue("Catalog.Hotels.EmptyRef"));      
		
		vExtCodes =  New Array;     
		If ValueIsFilled(vInteractionID) Then
			vExtCodes.Add(vInteractionID);       
		Else
			vExtCodes.Add(vExtCode);             
		EndIf;
		
		vFormParameters = New Structure("Filter", New Structure("Hotel, ExternalSystemCode", vHotels, vExtCodes));
	Else
		vFormParameters = New Structure("Filter", New Structure("ExternalSystemCode", vExtCodes));
	EndIf;

	OpenForm("InformationRegister.ExternalSystemsObjectCodesMappings.ListForm", vFormParameters, pCommandExecuteParameters.Source, pCommandExecuteParameters.Uniqueness, pCommandExecuteParameters.Window, pCommandExecuteParameters.URL);
EndProcedure // CommandProcessing

#EndRegion         
