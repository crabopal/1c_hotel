#Region EventHandlers 

// -----------------------------------------------------------------------------
Function getStatusFromAnketaPOST(pRequest)
	WriteLogEvent("HTTP_AlfaBank_getStatusFromAnketaPOST", EventLogLevel.Information,,,"Anketa status request recived");
	vSettings				= GetSettings();
	vSuccess				= True;
	vRequeuestBody 			= pRequest.GetBodyAsString();
	vErrorDescription		= "";
	If vRequeuestBody <> Undefined Then
		vJSON = new JSONReader;
		vJSON.SetString(vRequeuestBody);
		Try
			vRequestParameters = ReadJSON(vJSON);
		Except
			vSuccess 			= False;
			vErrorDescription 	= "Cant read request body as JSON" + Chars.LF;
		EndTry;

		Try
			If vSuccess and vRequestParameters <> Undefined and TypeOf(vRequestParameters) = Type("Structure") Then
				vAppId 		= "";
				vGuestGroup = "";
				vHotel	= SessionParameters.CurrentHotel;
				If vRequestParameters.Property("appId") Then
					vAppId = vRequestParameters.appId;	
				Else
					vSuccess = False;
					vErrorDescription 	= vErrorDescription + "Missing appId parameter" + Chars.LF;
				EndIf;
				If vRequestParameters.Property("reference") Then
					vReference 	= vRequestParameters.reference;
					vGuestGroup = vReference;
				Else
					vSuccess = False;
					vErrorDescription 	= vErrorDescription + "Missing reference parameter" + Chars.LF;
				EndIf;
				If vRequestParameters.Property("currentStatus") Then
					vCurrentStatus = vRequestParameters.currentStatus; 
				Else
					vSuccess = False;
					vErrorDescription 	= vErrorDescription + "Missing currentStatus parameter" + Chars.LF;
				EndIf;
				
				If vSuccess and ValueIsFilled(vAppId) and ValueIsFilled(vGuestGroup) and ValueIsFilled(vHotel) Then
					If vCurrentStatus = "appDecline" or vCurrentStatus = "appOperatorReject" or vCurrentStatus = "appOverdue" Then
						cmCancelGroupReservation(vGuestGroup, vHotel.Code, vSettings.ExternalSystemCode);		
					ElsIf vCurrentStatus = "appFinalComplete" Then
						If vRequestParameters.Property("credSum") Then
							vSum = Number(vRequestParameters.credSum);
							If vSum > 0 Then 
								vExternalPaymentResult = cmWriteExternalPayment("", vGuestGroup, ,,,,,"Альфа-Банк Кредит", vSum, "643",,vHotel.Code,vSettings.ExternalSystemCode,,,,,,,,"XDTO");
								If ValueIsFilled(vExternalPaymentResult.ErrorDescription) Then
									vSuccess = False;
									vErrorDescription 	= vErrorDescription + vExternalPaymentResult.ErrorDescription + Chars.LF;
								EndIf;
							EndIf;
						Else
							vErrorDescription 	= vErrorDescription + "Missing credSum parameter" + Chars.LF;
							vSuccess = False;
						EndIf;
					EndIf;
					If NOT IsBlankString(vCurrentStatus) and vSuccess = True Then
						Try
							vGuestGroupRef = Catalogs.GuestGroups.FindByCode(Number(vGuestGroup), False, , vHotel);
						Except
						EndTry;
						If Not ValueIsFilled(vGuestGroupRef) Then
							vGuestGroupRef = cmGetGuestGroupByExternalCode(vHotel, vGuestGroup, "", "", False);
						EndIf;
						If ValueIsFilled(vGuestGroupRef) Then
							vGuestGroupObj = vGuestGroupRef.GetObject();
							vGuestGroupObj.Description = vCurrentStatus;
							vGuestGroupObj.Write();
						Else
							If NOT(vCurrentStatus = "appDecline" or vCurrentStatus = "appOperatorReject" or vCurrentStatus = "appOverdue") Then
								vSuccess = False;
								vErrorDescription 	= vErrorDescription + "Failed to find guest group by code" + Chars.LF;
							EndIf;
						EndIf;
					EndIf;
				Else
					vSuccess = False;
					vErrorDescription 	= vErrorDescription + "Not all parameters are filled!" + Chars.LF;
				EndIf;
			EndIf;
		Except
			vSuccess = False;
	        vErrorDescription = vErrorDescription + ErrorDescription() + Chars.LF;
		EndTry;
	Else
		vSuccess = False;
		vErrorDescription = "Request body is missing!"
	EndIf;
	
	
	If vSuccess Then
		vJSONResponse 	= New JSONWriter;
		vJSONResponse.ValidateStructure = False;
		vJSONResponse.SetString();
		vJSONResponse.WriteStartObject();			
		vJSONResponse.WritePropertyName("appId");
		vJSONResponse.WriteValue(vAppId);
		vJSONResponse.WriteEndObject();	
		vResult = vJSONResponse.Close();

		vResponse = New HTTPServiceResponse(200);
		vResponse.SetBodyFromString(vResult);		
	Else
		WriteLogEvent("HTTP_AlfaBank_getStatusFromAnketaPOST", EventLogLevel.Error,,,vErrorDescription);
		vResponse = New HTTPServiceResponse(400);
	EndIf;
	
	Return vResponse;
EndFunction // GetStatusFromAnketaPOST

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetSettings()
	vResult = new Structure("ExternalSystemCode, WSHost, ResourceAddress, EchoToken, TimeStamp, Version");
	vResult.ExternalSystemCode	= "AlfaBankAnketa";
	vResult.WSHost				= Undefined;
	vResult.ResourceAddress		= Undefined;
	vResult.EchoToken			= String(New UUID);
	vResult.TimeStamp			= Format(CurrentSessionDate(),"DF=yyyy-MM-ddTHH:mm:ss+03:00");
	vResult.Version				= "16";
	Return vResult;
EndFunction // GetSettings

#EndRegion
 


