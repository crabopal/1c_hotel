#Region EventHandlers   

// -----------------------------------------------------------------------------
Function sendmessagePOST(pRequest)
	vSettings				= Hoteza.GetSettings();
	vSuccess				= True;
	vInteraction			 = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(vSettings.ExternalSystemCode, SessionParameters.CurrentHotel);
	vRequeuestBody 			= pRequest.GetBodyAsString();
	vResponseJSON			= "";
	If vInteraction <> Undefined and vRequeuestBody <> Undefined Then
		vJSON = new JSONReader;
		vJSON.SetString(vRequeuestBody);
		Try
			vRequestParameters = ReadJSON(vJSON);
		Except
			vSuccess 			= False;
			vErrorDescription 	= "Cant read request body as JSON";
		EndTry;
		
		If vSuccess and vRequestParameters <> Undefined and TypeOf(vRequestParameters) = Type("Structure") Then
			vResponseJSON = Hoteza.ProcessRequest("sendmessage", vRequestParameters, vInteraction);
		EndIf;
	EndIf;
	vResponse = New HTTPServiceResponse(200);
	vResponse.Headers = GetHeaders();
	vResponse.SetBodyFromString(vResponseJSON);
	Return vResponse;
EndFunction // SendmessagePOST

// -----------------------------------------------------------------------------
Function wakeupcallPOST(pRequest)
	vSettings				= Hoteza.GetSettings();
	vSuccess				= True;
	vInteraction			 = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(vSettings.ExternalSystemCode, SessionParameters.CurrentHotel);
	vRequeuestBody 			= pRequest.GetBodyAsString();
	vResponseJSON			= "";
	If vInteraction <> Undefined and vRequeuestBody <> Undefined Then
		vJSON = new JSONReader;
		vJSON.SetString(vRequeuestBody);
		Try
			vRequestParameters = ReadJSON(vJSON);
		Except
			vSuccess 			= False;
			vErrorDescription 	= "Cant read request body as JSON";
		EndTry;
		
		If vSuccess and vRequestParameters <> Undefined and TypeOf(vRequestParameters) = Type("Structure") Then
			vResponseJSON = Hoteza.ProcessRequest("wakeupcall", vRequestParameters, vInteraction);
		EndIf;
	EndIf;
	vResponse = New HTTPServiceResponse(200);
	vResponse.Headers = GetHeaders();
	vResponse.SetBodyFromString(vResponseJSON);
	Return vResponse;
EndFunction // WakeupcallPOST

// -----------------------------------------------------------------------------
Function clearwakeupcallPOST(pRequest)
	vSettings				= Hoteza.GetSettings();
	vSuccess				= True;
	vInteraction			 = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(vSettings.ExternalSystemCode, SessionParameters.CurrentHotel);
	vRequeuestBody 			= pRequest.GetBodyAsString();
	vResponseJSON			= "";
	If vInteraction <> Undefined and vRequeuestBody <> Undefined Then
		vJSON = new JSONReader;
		vJSON.SetString(vRequeuestBody);
		Try
			vRequestParameters = ReadJSON(vJSON);
		Except
			vSuccess 			= False;
			vErrorDescription 	= "Cant read request body as JSON";
		EndTry;
		
		If vSuccess and vRequestParameters <> Undefined and TypeOf(vRequestParameters) = Type("Structure") Then
			vResponseJSON = Hoteza.ProcessRequest("clearwakeupcall", vRequestParameters, vInteraction);
		EndIf;
	EndIf;
	vResponse = New HTTPServiceResponse(200);
	vResponse.Headers = GetHeaders();
	vResponse.SetBodyFromString(vResponseJSON);
	Return vResponse;
EndFunction // ClearwakeupcallPOST

// -----------------------------------------------------------------------------
Function billPOST(pRequest)
	vSettings				= Hoteza.GetSettings();
	vSuccess				= True;
	vInteraction			 = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(vSettings.ExternalSystemCode, SessionParameters.CurrentHotel);
	vRequeuestBody 			= pRequest.GetBodyAsString();
	vResponseJSON			= "";
	If vInteraction <> Undefined and vRequeuestBody <> Undefined Then
		vJSON = new JSONReader;
		vJSON.SetString(vRequeuestBody);
		Try
			vRequestParameters = ReadJSON(vJSON);
		Except
			vSuccess 			= False;
			vErrorDescription 	= "Cant read request body as JSON";
		EndTry;
		
		If vSuccess and vRequestParameters <> Undefined and TypeOf(vRequestParameters) = Type("Structure") Then
			vResponseJSON = Hoteza.ProcessRequest("bill", vRequestParameters, vInteraction);
		EndIf;
	EndIf;
	vResponse = New HTTPServiceResponse(200);
	vResponse.Headers = GetHeaders();
	vResponse.SetBodyFromString(vResponseJSON);
	Return vResponse;
EndFunction // BillPOST

// -----------------------------------------------------------------------------
Function dndPOST(pRequest)
	vSettings				= Hoteza.GetSettings();
	vSuccess				= True;
	vInteraction			 = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(vSettings.ExternalSystemCode, SessionParameters.CurrentHotel);
	vRequeuestBody 			= pRequest.GetBodyAsString();
	vResponseJSON			= "";
	If vInteraction <> Undefined and vRequeuestBody <> Undefined Then
		vJSON = new JSONReader;
		vJSON.SetString(vRequeuestBody);
		Try
			vRequestParameters = ReadJSON(vJSON);
		Except
			vSuccess 			= False;
			vErrorDescription 	= "Cant read request body as JSON";
		EndTry;
		
		If vSuccess and vRequestParameters <> Undefined and TypeOf(vRequestParameters) = Type("Structure") Then
			vResponseJSON = Hoteza.ProcessRequest("dnd", vRequestParameters, vInteraction);
		EndIf;
	EndIf;
	vResponse = New HTTPServiceResponse(200);
	vResponse.Headers = GetHeaders();
	vResponse.SetBodyFromString(vResponseJSON);
	Return vResponse;
EndFunction // DndPOST

// -----------------------------------------------------------------------------
Function roomstatusPOST(pRequest)
	vSettings				= Hoteza.GetSettings();
	vSuccess				= True;
	vInteraction			 = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(vSettings.ExternalSystemCode, SessionParameters.CurrentHotel);
	vRequeuestBody 			= pRequest.GetBodyAsString();
	vResponseJSON			= "";
	If vInteraction <> Undefined and vRequeuestBody <> Undefined Then
		vJSON = new JSONReader;
		vJSON.SetString(vRequeuestBody);
		Try
			vRequestParameters = ReadJSON(vJSON);
		Except
			vSuccess 			= False;
			vErrorDescription 	= "Cant read request body as JSON";
		EndTry;
		
		If vSuccess and vRequestParameters <> Undefined and TypeOf(vRequestParameters) = Type("Structure") Then
			vResponseJSON = Hoteza.ProcessRequest("roomstatus", vRequestParameters, vInteraction);
		EndIf;
	EndIf;
	vResponse = New HTTPServiceResponse(200);
	vResponse.Headers = GetHeaders();
	vResponse.SetBodyFromString(vResponseJSON);
	Return vResponse;
EndFunction // RoomstatusPOST

// -----------------------------------------------------------------------------
Function salePOST(pRequest)
	vSettings				= Hoteza.GetSettings();
	vSuccess				= True;
	vInteraction			 = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(vSettings.ExternalSystemCode, SessionParameters.CurrentHotel);
	vRequeuestBody 			= pRequest.GetBodyAsString();
	vResponseJSON			= "";
	If vInteraction <> Undefined and vRequeuestBody <> Undefined Then
		vJSON = new JSONReader;
		vJSON.SetString(vRequeuestBody);
		Try
			vRequestParameters = ReadJSON(vJSON);
		Except
			vSuccess 			= False;
			vErrorDescription 	= "Cant read request body as JSON";
		EndTry;
		
		If vSuccess and vRequestParameters <> Undefined and TypeOf(vRequestParameters) = Type("Structure") Then
			vResponseJSON = Hoteza.ProcessRequest("sale", vRequestParameters, vInteraction);
		EndIf;
	EndIf;
	vResponse = New HTTPServiceResponse(200);
	vResponse.Headers = GetHeaders();
	vResponse.SetBodyFromString(vResponseJSON);
	Return vResponse;
EndFunction // SalePOST

// -----------------------------------------------------------------------------
Function wakeupcallanswerPOST(pRequest)
	vSettings				= Hoteza.GetSettings();
	vSuccess				= True;
	vInteraction			 = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(vSettings.ExternalSystemCode, SessionParameters.CurrentHotel);
	vRequeuestBody 			= pRequest.GetBodyAsString();
	vResponseJSON			= "";
	If vInteraction <> Undefined and vRequeuestBody <> Undefined Then
		vJSON = new JSONReader;
		vJSON.SetString(vRequeuestBody);
		Try
			vRequestParameters = ReadJSON(vJSON);
		Except
			vSuccess 			= False;
			vErrorDescription 	= "Cant read request body as JSON";
		EndTry;
		
		If vSuccess and vRequestParameters <> Undefined and TypeOf(vRequestParameters) = Type("Structure") Then
			vResponseJSON = Hoteza.ProcessRequest("wakeupcallanswer", vRequestParameters, vInteraction);
		EndIf;
	EndIf;
	vResponse = New HTTPServiceResponse(200);
	vResponse.Headers = GetHeaders();
	vResponse.SetBodyFromString(vResponseJSON);
	Return vResponse;
EndFunction // WakeupcallanswerPOST

// -----------------------------------------------------------------------------
Function swaprequestPOST(pRequest)
	vSettings				= Hoteza.GetSettings();
	vSuccess				= True;
	vInteraction			 = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(vSettings.ExternalSystemCode, SessionParameters.CurrentHotel);
	vRequeuestBody 			= pRequest.GetBodyAsString();
	vResponseJSON			= "";
	If vInteraction <> Undefined and vRequeuestBody <> Undefined Then
		vJSON = new JSONReader;
		vJSON.SetString(vRequeuestBody);
		Try
			vRequestParameters = ReadJSON(vJSON);
		Except
			vSuccess 			= False;
			vErrorDescription 	= "Cant read request body as JSON";
		EndTry;
		
		If vSuccess and vRequestParameters <> Undefined and TypeOf(vRequestParameters) = Type("Structure") Then
			vResponseJSON = Hoteza.ProcessRequest("swaprequest", vRequestParameters, vInteraction);
		EndIf;
	EndIf;
	vResponse = New HTTPServiceResponse(200);
	vResponse.Headers = GetHeaders();
	vResponse.SetBodyFromString(vResponseJSON);
	Return vResponse;
EndFunction // SwaprequestPOST

// -----------------------------------------------------------------------------
Function pingPOST(pRequest)
	vSettings				= Hoteza.GetSettings();
	vSuccess				= True;
	vInteraction			 = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(vSettings.ExternalSystemCode, SessionParameters.CurrentHotel);
	vResponseJSON			= "";
	If vInteraction <> Undefined Then
		vResponseJSON = Hoteza.ProcessRequest("ping", New Structure, vInteraction);
	EndIf;
	vResponse = New HTTPServiceResponse(200);
	vResponse.Headers = GetHeaders();
	vResponse.SetBodyFromString(vResponseJSON);
	Return vResponse;
EndFunction // PingPOST

// -----------------------------------------------------------------------------
Function xprscheckoutPOST(pRequest)
	vSettings				= Hoteza.GetSettings();
	vSuccess				= True;
	vInteraction			 = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(vSettings.ExternalSystemCode, SessionParameters.CurrentHotel);
	vRequeuestBody 			= pRequest.GetBodyAsString();
	vResponseJSON			= "";
	If vInteraction <> Undefined and vRequeuestBody <> Undefined Then
		vJSON = new JSONReader;
		vJSON.SetString(vRequeuestBody);
		Try
			vRequestParameters = ReadJSON(vJSON);
		Except
			vSuccess 			= False;
			vErrorDescription 	= "Cant read request body as JSON";
		EndTry;
		
		If vSuccess and vRequestParameters <> Undefined and TypeOf(vRequestParameters) = Type("Structure") Then
			vResponseJSON = Hoteza.ProcessRequest("xprscheckout", vRequestParameters, vInteraction);
		EndIf;
	EndIf;
	vResponse = New HTTPServiceResponse(200);
	vResponse.Headers = GetHeaders();
	vResponse.SetBodyFromString(vResponseJSON);
	Return vResponse;
EndFunction // XprscheckoutPOST

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetHeaders()
	vResult = New Map;
	vResult.Insert("Content-Type", "application/json");
	Return vResult;
EndFunction // GetHeaders 

#EndRegion