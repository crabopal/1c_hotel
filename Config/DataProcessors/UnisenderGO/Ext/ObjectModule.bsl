#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pParameter	 - Structure - Parameter
//
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
//
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
//
Procedure pmFillAttributesWithDefaultValues() Export
	// NOTHING SO FAR  
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
//
// Parameters:
//  pSenderName			 - String	 - Sender name
//  pFromEMail			 - String	 - From EMail
//  pSubject			 - String	 - Subject
//  pTexts				 - String	 - Texts
//  pTextParameters		 - Map		 - Text parameters (Key - Name, Value - Value)
//  pTextAttachments	 - Map		 - Text attachments (Key - Name, Value - Path)
//  pAttachments		 - Map		 - Attachments (Key - Name, Value - Path)
//  pToEMail			 - Array	 - To EMail (String)
//  pReplyToEMail		 - Array	 - Reply to EMail (String)
//  pExternalTemplateID	 - String	 - External template ID
//  pMessage			 - String	 - Error message
// 
// Returns:
//  Boolean - Result
//
Function Send(pSenderName, pFromEMail, pSubject, pTexts, pTextParameters, pTextAttachments, pAttachments, pToEMail, pReplyToEMail, pExternalTemplateID, pMessage) Export 
	pMessage = ""; 
	vMessage = New Map;
	pExternalTemplate = Undefined; 
	If pExternalTemplateID <> Undefined And ValueIsFilled(pExternalTemplateID) Then
		vMessage.Insert("template_id", pExternalTemplateID);
		If Not GetExternalTemplate(pExternalTemplateID, pExternalTemplate, pSubject, pTexts, pTextParameters, pMessage) Then
			Return False;	
		EndIf;
	EndIf;
		
	vRecipients = New Array;
	If pToEMail <> Undefined Then
		For Each vRow In pToEMail Do
			vEMail = New Map;
			vEMail.Insert("email", TrimAll(vRow));
			If pTextParameters <> Undefined Then    
				vEMail.Insert("substitutions", pTextParameters);
			EndIf;
			vRecipients.Add(vEMail);
		EndDo;
	EndIf;
	vMessage.Insert("recipients", vRecipients);
	
	If pReplyToEMail <> Undefined Then
		For Each vRow In pReplyToEMail Do
			vMessage.Insert("reply_to", TrimAll(vRow));	
			Break;
		EndDo;
	EndIf;
	
	vTexts = pTexts;	
	If pExternalTemplate <> Undefined Then
		If pExternalTemplate["from_email"] = Undefined Or Not ValueIsFilled(pExternalTemplate["from_email"]) Then
			vMessage.Insert("from_email", TrimAll(pFromEMail));	
			vMessage.Insert("from_name", TrimAll(pSenderName));	
		EndIf;
		If (pExternalTemplate["body"]["html"] = Undefined Or Not ValueIsFilled(pExternalTemplate["body"]["html"])) And (pExternalTemplate["body"]["plaintext"] = Undefined Or Not ValueIsFilled(pExternalTemplate["body"]["plaintext"])) Then
			vBody = New Map;  
			If pTextAttachments <> Undefined Then
				vInlineAttachments = New Array;
				For Each vRow In pTextAttachments Do 
					vAttachment = New Map;
					vAttachment.Insert("type", "application/octet-stream");
					vAttachment.Insert("name", vRow.Key);
					vAttachment.Insert("content", GetBase64StringFromBinaryData(New BinaryData(vRow.Value.GetBinaryData())));
					vInlineAttachments.Add(vAttachment);
					vTexts = StrReplace(vTexts, vRow.Key, "cid:" + vRow.Key);
				EndDo;
				vMessage.Insert("inline_attachments", vInlineAttachments);
			EndIf;
			If Find(Lower(TrimAll(vTexts)), "<html") = 0 Then				 
				vBody.Insert("plaintext", TrimAll(vTexts));
			Else  
				vBody.Insert("html", TrimAll(vTexts));
			EndIf;  
			vMessage.Insert("body", vBody);	  
		EndIf;
		If pExternalTemplate["subject"] = Undefined Or Not ValueIsFilled(pExternalTemplate["subject"]) Then
			vMessage.Insert("subject", TrimAll(pSubject)); 	
		EndIf;
	Else       
		vMessage.Insert("from_email", TrimAll(pFromEMail));	
		vMessage.Insert("from_name", TrimAll(pSenderName));	
		vBody = New Map;
		If pTextAttachments <> Undefined Then
			vInlineAttachments = New Array;
			For Each vRow In pTextAttachments Do 
				vAttachment = New Map;
				vAttachment.Insert("type", "application/octet-stream");
				vAttachment.Insert("name", vRow.Key);
				vAttachment.Insert("content", GetBase64StringFromBinaryData(New BinaryData(vRow.Value.GetBinaryData())));
				vInlineAttachments.Add(vAttachment);
				vTexts = StrReplace(vTexts, vRow.Key, "cid:" + vRow.Key);
			EndDo;
			vMessage.Insert("inline_attachments", vInlineAttachments);
		EndIf;
		If Find(Lower(TrimAll(vTexts)), "<html") = 0 Then				 
			vBody.Insert("plaintext", TrimAll(vTexts));
		Else  
			vBody.Insert("html", TrimAll(vTexts));
		EndIf; 
		vMessage.Insert("body", vBody);			
		vMessage.Insert("subject", TrimAll(pSubject));	
	EndIf;
		
	If pAttachments <> Undefined Then
		vAttachments = New Array;
		For Each vKeyAndValue In pAttachments Do 
			vAttachment = New Map;
			vAttachment.Insert("type", "application/octet-stream");
			vAttachment.Insert("name", vKeyAndValue.Key);
			vAttachment.Insert("content", GetBase64StringFromBinaryData(New BinaryData(vKeyAndValue.Value)));
			vAttachments.Add(vAttachment);
		EndDo;
		vMessage.Insert("attachments", vAttachments);
	EndIf;
	
	vData = New Map;
	vData.Insert("message", vMessage); 
	
	vResponse = Undefined;
	If Not SendQuery(MapToJSON(vData), "email/send.json", "POST", vResponse) Then
		pMessage = vResponse;
		Return False;	
	EndIf;
	Return True;
EndFunction // Send

// -----------------------------------------------------------------------------
//
// Parameters:
//  pID				 - String	 - External template ID
//  pTemplate		 - Map		 - Structure from response body
//  rSubject		 - String	 - Subject
//  rHTML			 - String	 - HTML
//  pTextParameters	 - Map		 - Text parameters (Key - Name, Value - Value)
//  pMessage		 - String	 - Error message
// 
// Returns:
//  Boolean - Result
//
Function GetExternalTemplate(Val pID, pTemplate = Undefined, rSubject = Undefined, rHTML = Undefined, pTextParameters = Undefined, pMessage) Export 
	vData = New Map;
	vData.Insert("id", pID);
		
	vResponse = Undefined;
	If SendQuery(MapToJSON(vData), "template/get.json", "POST", vResponse) Then 
		pTemplate = vResponse["template"];
		
		If pTemplate <> Undefined Then   
			rSubject =	pTemplate["subject"]; 
			rHTML =	pTemplate["body"]["html"];
 			
			If pTextParameters <> Undefined Then
				For Each TextParameter In pTextParameters Do
					If rHTML <> Undefined Then
						rHTML = StrReplace(rHTML, "{{" + TrimAll(TextParameter.Key) + "}}", TextParameter.Value);
					EndIf;
					If rSubject <> Undefined Then 
						rSubject = StrReplace(rSubject, "{{" + TrimAll(TextParameter.Key) + "}}", TextParameter.Value);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	Else
		pMessage = vResponse;
		Return False;
	EndIf;
	
	Return True;
EndFunction // GetTemplateList

// -----------------------------------------------------------------------------
//
// Parameters:
//  pLimit	 - Number	 - Limit
//  pOffset	 - Number	 - Offset
// 
// Returns:
//  Array - Template list
//
Function GetTemplateList(pLimit = 50, pOffset = 0) Export 
	vTemplateList = New Array;
	
	vData = New Map;
	vData.Insert("limit", pLimit);
	vData.Insert("offset", pOffset);
		
	vResponse = Undefined;
	If SendQuery(MapToJSON(vData), "template/list.json", "POST", vResponse) Then
		vTemplateList = vResponse["templates"];
	Else
		tcCommonFunctionOnClientServer.TextMessage(vResponse);
	EndIf;
	
	Return vTemplateList;
EndFunction // GetTemplateList 

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function MapToJSON(pMap)	
	vJSONWriter = New JSONWriter;
	vJSONWriter.SetString(New JSONWriterSettings(JSONLineBreak.None));
	WriteJSON(vJSONWriter, pMap);
	Return vJSONWriter.Close();	
EndFunction // MapToJSON

// -----------------------------------------------------------------------------
Function JSONToMap(pJson)
	vJSONReader = New JSONReader; 
	vJSONReader.SetString(pJson);
	Return ReadJSON(vJSONReader, True);	
EndFunction // MapToJSON

// -----------------------------------------------------------------------------
Function SendQuery(pData, pType, pMethod = "POST", rResponse)
	vHTTPServer = "go1.unisender.ru";  
	vHttpAddress = "/ru/transactional/api/v1/";
	If ValueIsFilled(InteractionParameters.HttpServer) Then
		vHttp = StrReplace(StrReplace(InteractionParameters.HttpServer, "https://", ""), "http://", "");
		vHTTPServer = Left(vHttp, StrFind(vHttp, "/") - 1);
		vHttpAddress = Right(vHttp, StrLen(vHttp) - StrFind(vHttp, "/") + 1);
	EndIf;
	vHttpAddress = vHttpAddress + TrimAll(pType); 
	Try
		// HTTP connection
		vSSL = Undefined;
		If InteractionParameters.HttpUseSsl Then
			vSSL = New OpenSSLSecureConnection(Undefined, Undefined);       	
		EndIf;
		
		vHTTPConnection = New HTTPConnection(vHTTPServer,,,,, 15, vSSL);
		
		vHeader = New Map;
		vHeader.Insert("Content-Type", "application/json");
		vHeader.Insert("Accept", "application/json");
		vHeader.Insert("X-API-KEY", TrimAll(InteractionParameters.InteractionID));
		
		// Send query
		vHTTPRequest = New HTTPRequest(vHttpAddress, vHeader);
		If ValueIsFilled(pData) Then
			vHTTPRequest.SetBodyFromString(pData, TextEncoding.UTF8);
		EndIf;
		
		vRS = vHTTPConnection.CallHTTPMethod(pMethod, vHTTPRequest);
			
		vRSString = vRS.GetBodyAsString(TextEncoding.UTF8);
				
		Try
			rResponse = JSONToMap(vRSString);
			If Not vRS.StatusCode = 200 Or rResponse["status"] <> "success" Then
				rResponse = Format(rResponse["code"], "NFD=0; NG=") + ": " + rResponse["message"];
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, pType, Enums.ExternalSystemEventTypes.Error, pData, rResponse,, InteractionParameters.MaxLogLenght);
				Return False;
			ElsIf InteractionParameters.DebugMode Then
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, pType, Enums.ExternalSystemEventTypes.Info, pData, vRSString,, InteractionParameters.MaxLogLenght);	
			EndIf;
		Except
			rResponse = vRSString; 
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, pType, Enums.ExternalSystemEventTypes.Error, pData, vRSString,, InteractionParameters.MaxLogLenght);
			Return False;
		EndTry;
		Return True;
	Except
		vError = ErrorInfo();
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, pType+".SendQuery", Enums.ExternalSystemEventTypes.Error, pData, "", "Failed to send post query! " + DetailErrorDescription(vError), InteractionParameters.MaxLogLenght); 
		rResponse = BriefErrorDescription(vError);
		Return False;
	EndTry;	
EndFunction // SendQuery

#EndRegion