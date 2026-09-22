
#Region Public

// ---------------------------------------------------------------------------------
Function Hello(pInteractionParameters, rMessage) Export
	If Not ValueIsFilled(pInteractionParameters) Then
		vMsg = Nstr("en = 'It is necessary to fill the interaction system'; de = 'Es ist notwendig, das Interaktionssystem zu füllen'; ru = 'Необходимо заполнить систему взаимодействия'");
		WriteLogEvent("DataProcessors.SamsungLYNK.Hello", EventLogLevel.Error, , , vMsg);
		Raise vMsg;
	EndIf;
	If Not pInteractionParameters.IsActive Then
		vMsg = Nstr("en = 'Interaction system is off, synchronization failed'; de = 'Interaktionssystem ist ausgeschaltet, Synchronisation fehlgeschlagen'; ru = 'Cистема взаимодействия выключена'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SamsungLYNK.Start", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
		WriteLogEvent("DataProcessors.SamsungLYNK.Hello", EventLogLevel.Error, , , vMsg);
		Raise vMsg;
	EndIf;
	If Not ValueIsFilled(pInteractionParameters.Hotel) Then
		vMsg = Nstr("en = 'It is necessary to fill the hotel'; de = 'Es ist notwendig, das hotel zu füllen'; ru = 'Необходимо заполнить гостиницу'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SamsungLYNK.Start", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
		WriteLogEvent("DataProcessors.SamsungLYNK.Hello", EventLogLevel.Error, , CurrentSessionDate(), vMsg);
		Raise vMsg;
	EndIf;
	If Not ValueIsFilled(pInteractionParameters.HttpServer) Or Not ValueIsFilled(pInteractionParameters.HttpPort) Then
		vMsg = Nstr("en = 'It is necessary to fill the HTTP server and port'; de = 'Es ist notwendig, das HTTP server und port zu füllen'; ru = 'Необходимо заполнить HTTP сервер и порт'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SamsungLYNK.Start", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
		WriteLogEvent("DataProcessors.SamsungLYNK.Hello", EventLogLevel.Error, , CurrentSessionDate(), vMsg);
		Raise vMsg;
	EndIf;
	If pInteractionParameters.DebugMode Then
		rMessage = NStr("en='Start of execution';ru='Начало выполнения';de='Ausführung starten'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SamsungLYNK.Start", Enums.ExternalSystemEventTypes.Info, , , rMessage);
	EndIf;
	rMessage = "";
	vResult = False;
	Try
		vSuccess = True; 
		// HTTP connection
		vHTTPConnection = New HTTPConnection(pInteractionParameters.HttpServer, pInteractionParameters.HttpPort, , , , ?(pInteractionParameters.SessionTimeout <> 0, pInteractionParameters.SessionTimeout, 10));
		vResponse = SendQuery(pInteractionParameters, vHTTPConnection, "openapi/hello", "POST", Undefined, Undefined, vSuccess);
		If vSuccess And vResponse <> Undefined Then
			If pInteractionParameters.DebugMode Then
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SamsungLYNK.Response.hello", Enums.ExternalSystemEventTypes.Info, , vResponse);
			EndIf;
			vResponseStructure = GetStructureByXMLString(vResponse, vSuccess);
			If vSuccess And vResponseStructure <> Undefined And TypeOf(vResponseStructure) = Type("Structure") Then
				If vResponseStructure.Property("response") Then
					If vResponseStructure.response.Property("statuscode") And vResponseStructure.response.statuscode.Property("Value") And vResponseStructure.response.statuscode.Value <> "0" Then	
						rMessage 	= GetResponseCodeDescription(vResponseStructure.response.statuscode) + ": Hello";
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SamsungLYNK.ResponseError", Enums.ExternalSystemEventTypes.Warning, , , rMessage);
						WriteLogEvent(pInteractionParameters.InteractionID + "_SamsungLYNK_Hello", EventLogLevel.Warning, , CurrentSessionDate(), "Response error!" + rMessage);
					Else
						rMessage = NStr("en = 'Completed'; de = 'Abgeschlossen'; ru = 'Завершено'");
						vResult = True;
					EndIf;	
				Else
					rMessage 	= NStr("en = 'Missing result in response from SamsungLYNK: Hello'; de = 'Fehlendes Ergebnis als Antwort von SamsungLYNK: Hello'; ru = 'Отсутствует результат в ответе от SamsungLYNK: Hello'");
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SamsungLYNK.ReadResponse", Enums.ExternalSystemEventTypes.Warning, , , rMessage);
					WriteLogEvent(pInteractionParameters.InteractionID + "_SamsungLYNK_Hello", EventLogLevel.Warning, , CurrentSessionDate(), "Response error!" + rMessage);		
				EndIf;
			Else
				rMessage 	= NStr("en = 'Can''t read request body as XML: Hello'; de = 'Anforderungshauptteil kann nicht als XML gelesen werden: Hello'; ru = 'Не удается прочитать тело запроса как XML: Hello'");
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SamsungLYNK.GetStructureByXMLString", Enums.ExternalSystemEventTypes.Warning, , , rMessage);
				WriteLogEvent(pInteractionParameters.InteractionID + "_SamsungLYNK_Hello", EventLogLevel.Warning, , CurrentSessionDate(), "Response error!" + rMessage);	
			EndIf;
		EndIf;
	Except
		rMessage = ErrorDescription();
		WriteLogEvent(pInteractionParameters.InteractionID + "_SamsungLYNK_Hello", EventLogLevel.Warning, , CurrentSessionDate(), "Error!" + rMessage);
	EndTry;
	Return vResult;	
EndFunction // Hello

// ---------------------------------------------------------------------------------
Procedure Sync(pInteractionParameters) Export
	If Not ValueIsFilled(pInteractionParameters) Then
		vMsg = Nstr("en = 'It is necessary to fill the interaction system'; de = 'Es ist notwendig, das Interaktionssystem zu füllen'; ru = 'Необходимо заполнить систему взаимодействия'");
		WriteLogEvent("DataProcessors.SamsungLYNK.Sync", EventLogLevel.Error, , , vMsg);
		Raise vMsg;
	EndIf;
	If Not pInteractionParameters.IsActive Then
		vMsg = Nstr("en = 'Interaction system is off, synchronization failed'; de = 'Interaktionssystem ist ausgeschaltet, Synchronisation fehlgeschlagen'; ru = 'Cистема взаимодействия выключена'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SamsungLYNK.Start", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
		WriteLogEvent("DataProcessors.SamsungLYNK.Sync", EventLogLevel.Error, , , vMsg);
		Raise vMsg;
	EndIf;
	If Not ValueIsFilled(pInteractionParameters.Hotel) Then
		vMsg = Nstr("en = 'It is necessary to fill the hotel'; de = 'Es ist notwendig, das hotel zu füllen'; ru = 'Необходимо заполнить гостиницу'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SamsungLYNK.Start", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
		WriteLogEvent("DataProcessors.SamsungLYNK.Sync", EventLogLevel.Error, , CurrentSessionDate(), vMsg);
		Raise vMsg;
	EndIf;
	If Not ValueIsFilled(pInteractionParameters.HttpServer) Or Not ValueIsFilled(pInteractionParameters.HttpPort) Then
		vMsg = Nstr("en = 'It is necessary to fill the HTTP server and port'; de = 'Es ist notwendig, das HTTP server und port zu füllen'; ru = 'Необходимо заполнить HTTP сервер и порт'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SamsungLYNK.Start", Enums.ExternalSystemEventTypes.Warning, , , vMsg);
		WriteLogEvent("DataProcessors.SamsungLYNK.Sync", EventLogLevel.Error, , CurrentSessionDate(), vMsg);
		Raise vMsg;
	EndIf;
	If pInteractionParameters.DebugMode Then
		vMessage = NStr("en='Start of execution';ru='Начало выполнения';de='Ausführung starten'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SamsungLYNK.Start", Enums.ExternalSystemEventTypes.Info, , , vMessage);
	EndIf;
	vDocs = GetDocsToSync(pInteractionParameters.Hotel);
	If vDocs.Count() > 0 Then
		If pInteractionParameters.DebugMode Then
			vMessage = NStr("en = 'Found not synced documents'; de = 'Nicht synchronisierte Dokumente gefunden'; ru = 'Найдены несинхронизированные документы'") + ": " + vDocs.Count();
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SamsungLYNK.GetDocsToSync", Enums.ExternalSystemEventTypes.Info, , , vMessage);
		EndIf;
	Else
		If pInteractionParameters.DebugMode Then
			vMessage = NStr("en = 'There are no unsynchronized documents'; de = 'Es gibt keine nicht synchronisierten Dokumente'; ru = 'Нет несинхронизированных документов'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SamsungLYNK.GetDocsToSync", Enums.ExternalSystemEventTypes.Error, , , vMessage);
		EndIf;
	EndIf;
	//HTTP connection
	vHTTPConnection = New HTTPConnection(pInteractionParameters.HttpServer, pInteractionParameters.HttpPort, , , , ?(pInteractionParameters.SessionTimeout <> 0, pInteractionParameters.SessionTimeout, 10));

	For Each vDoc In vDocs Do
		vSuccess	= True;
		Try
			vRequest 	= GetRequest(vDoc);
			If ValueIsFilled(vRequest.ResourceAddress) And ValueIsFilled(vRequest.MethodName) Then
				If pInteractionParameters.DebugMode Then
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SamsungLYNK.Request", Enums.ExternalSystemEventTypes.Info, ?(vRequest.Header <> Undefined, vRequest.Header, vRequest.Body));
				EndIf;
				vResponse = SendQuery(pInteractionParameters, vHTTPConnection, vRequest.ResourceAddress, vRequest.MethodName, vRequest.Header, vRequest.Body, vSuccess);
				If vSuccess And vResponse <> Undefined Then
					If pInteractionParameters.DebugMode Then
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SamsungLYNK.Response", Enums.ExternalSystemEventTypes.Info, , vResponse);
					EndIf;
					vResponseStructure = GetStructureByXMLString(vResponse, vSuccess);
					If vSuccess And vResponseStructure <> Undefined And TypeOf(vResponseStructure) = Type("Structure") Then
						If vResponseStructure.Property("response") Then
							If vResponseStructure.response.Property("statuscode") And vResponseStructure.response.statuscode.Property("Value") And vResponseStructure.response.statuscode.Value <> "0" Then	
								vSuccess 			= False;
								vErrorDescription 	= GetResponseCodeDescription(vResponseStructure.response.statuscode) + ": " + TrimAll(vDoc.Ref);
								InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SamsungLYNK.ResponseError", Enums.ExternalSystemEventTypes.Warning, , , vErrorDescription);
								WriteLogEvent(pInteractionParameters.InteractionID + "_SamsungLYNK_Sync", EventLogLevel.Warning, , CurrentSessionDate(), "Response error!" + vErrorDescription);
							EndIf;
						Else
							vSuccess 			= False;
							vErrorDescription 	= NStr("en = 'Missing result in response from SamsungLYNK: '; de = 'Fehlendes Ergebnis als Antwort von SamsungLYNK: '; ru = 'Отсутствует результат в ответе от SamsungLYNK: '") + TrimAll(vDoc.Ref);
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SamsungLYNK.ReadResponse", Enums.ExternalSystemEventTypes.Warning, , , vErrorDescription);
							WriteLogEvent(pInteractionParameters.InteractionID + "_SamsungLYNK_Sync", EventLogLevel.Warning, , CurrentSessionDate(), "Response error!" + vErrorDescription);				
						EndIf;
					Else
						vSuccess 			= False;
						vErrorDescription 	= NStr("en = 'Can''t read request body as XML: '; de = 'Anforderungshauptteil kann nicht als XML gelesen werden: '; ru = 'Не удается прочитать тело запроса как XML: '") + TrimAll(vDoc.Ref);
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SamsungLYNK.GetStructureByXMLString", Enums.ExternalSystemEventTypes.Warning, , , vErrorDescription);
						WriteLogEvent(pInteractionParameters.InteractionID + "_SamsungLYNK_Sync", EventLogLevel.Warning, , CurrentSessionDate(), "Response error!" + vErrorDescription);
					EndIf;	
				EndIf;
			Else
				vSuccess 			= False;
				vErrorDescription 	= NStr("en = 'Can''t create HTTP request for document: '; de = 'HTTP-Anforderung für Dokument kann nicht erstellt werden: '; ru = 'Невозможно создать HTTP-запрос для документа: '") + TrimAll(vDoc.Ref);
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SamsungLYNK.GetRequest", Enums.ExternalSystemEventTypes.Warning, , , vErrorDescription);
				WriteLogEvent(pInteractionParameters.InteractionID + "_SamsungLYNK_Sync", EventLogLevel.Warning, , CurrentSessionDate(), "Response error!" + vErrorDescription);	
			EndIf;
		Except
			vSuccess 			= False;
			vErrorDescription	= ErrorDescription();
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SamsungLYNK.Error", Enums.ExternalSystemEventTypes.Warning, , , vErrorDescription);
			WriteLogEvent(pInteractionParameters.InteractionID + "_SamsungLYNK_Sync", EventLogLevel.Warning, , CurrentSessionDate(), "Error! " + vErrorDescription);
			Break;
		EndTry;
		vObj = vDoc.Ref.GetObject();
		vObj.IsProcessed = vSuccess;
		vObj.Write();
	EndDo;
	vHTTPConnection = Undefined;
	If pInteractionParameters.DebugMode Then
		vMessage = NStr("en='End of execution';ru='Конец исполнения';de='Ende der Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SamsungLYNK.End", Enums.ExternalSystemEventTypes.Info, , , vMessage);
	EndIf;
EndProcedure

// ---------------------------------------------------------------------------------
Function PPVStatus(pInteractionParameters, pRoom) Export 
	vBody = "";
	vBodyStructure = New Structure(); 
	vAccommodation = GetMainRoomAccommodation(pRoom, pInteractionParameters.Hotel);
	If vAccommodation <> Undefined Then 
		vDefaultChannel = cmGetObjectRefByExternalSystemCode(pInteractionParameters.Hotel, "SamsungLYNK", "RoomInterfaceTypes", "DefaultChannel", False);
		If vDefaultChannel <> Undefined Then
			TurnOnParametersArr = StrSplit(vDefaultChannel.TurnOnParameters, ";", False);
			vBodyStructure = GetBodyMap_PPVStatus(vAccommodation, TurnOnParametersArr[0]); 	
		Else	
			vBodyStructure = GetBodyMap_PPVStatus(vAccommodation, "PPVSet_0"); 	
		EndIf;
		vBody = GetXMLStringByStructure(vBodyStructure);
	EndIf;
	Return vBody; 			
EndFunction // PPVStatus

// ---------------------------------------------------------------------------------
Function Display(pInteractionParameters, pRoom) Export
	vBody = "";
	vAccommodation = GetMainRoomAccommodation(pRoom, pInteractionParameters.Hotel);
	If vAccommodation <> Undefined Then  	
		vBody = GetXMLStringByStructure(GetBodyMap_Display(vAccommodation));
	EndIf;
	Return vBody;
EndFunction // Display

// ---------------------------------------------------------------------------------
Function Information(pInteractionParameters, pRoom) Export
	vBody = "";
	vAccommodation = GetMainRoomAccommodation(pRoom, pInteractionParameters.Hotel);
	If vAccommodation <> Undefined Then  	
		vBody = GetXMLStringByStructure(GetBodyMap_Information(vAccommodation));
	EndIf;
	Return vBody;
EndFunction // Display

// ---------------------------------------------------------------------------------
Function RoomsList(pInteractionParameters) Export 	
	Return GetXMLStringByStructure(GetBodyMap_RoomsList(pInteractionParameters));
EndFunction // Display

// ---------------------------------------------------------------------------------
Function GetErrorResponseXML(pName) Export 
	vBody = "";
	If pName = "ppvstatus" Then
		vBody = GetXMLStringByStructure(New Structure("response", New Structure("command, statuscode, channelbank, startdate, starttime, period", pName, "1", "", "", "", ""))); 	
	ElsIf pName = "display" Then
		vBody = GetXMLStringByStructure(New Structure("response", New Structure("command, statuscode, roomnumber, companyname, guestname, balance", pName, "1", "", "", "", "")));	
	ElsIf pName = "information" Then 
		vBody = GetXMLStringByStructure(New Structure("response", New Structure("command, statuscode, roomnumber, roomtype, guestname, language", pName, "1", "", "", "", "")));
	EndIf;
	Return vBody;
EndFunction // GetErrorResponseXML

// ---------------------------------------------------------------------------------
Function GetMainRoomAccommodation(pRoom, pHotel) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	Docs.Ref AS Ref,
	|	Docs.Date AS Date,
	|	Docs.PointInTime AS PointInTime
	|FROM
	|	Document.Accommodation AS Docs
	|WHERE
	|	Docs.Room = &qRoom
	|	AND Docs.Posted
	|	AND Docs.AccommodationStatus.IsInHouse
	|	AND Docs.AccommodationStatus.IsActive
	|	AND Docs.CheckInDate < &qCheckOutDate
	|	AND Docs.CheckOutDate > &qCheckInDate
	|	AND (Docs.AccommodationType.Type = &qRoomAccommodationType
	|			OR Docs.AccommodationType.Type = &qBedsAccommodationType)
	|	AND Docs.Hotel = &qHotel
	|
	|ORDER BY
	|	Docs.Date,
	|	Docs.PointInTime";
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qCheckInDate", CurrentSessionDate());
	vQry.SetParameter("qCheckOutDate", CurrentSessionDate());
	vQry.SetParameter("qRoomAccommodationType", Enums.AccomodationTypes.Room);
	vQry.SetParameter("qBedsAccommodationType", Enums.AccomodationTypes.Beds);
	vOneRoomDocs = vQry.Execute().Unload();
	If vOneRoomDocs.Count() > 0 Then
		Return vOneRoomDocs.Get(0).Ref;
	Else
		Return Undefined;
	EndIf;
EndFunction // GetMainRoomAccommodation

#EndRegion

#Region Internal

#Region XMLParsing

// -------------------------------------------------------------------------
Function GetStructureByXMLString(Val pXMLString, rSuccess = True)
	vResult = New Structure();
	Try
		If ValueIsFilled(pXMLString) Then
			ReadXMLtoMap(pXMLString, vResult, "Value");	
		EndIf;
		rSuccess = True;
	Except
		vResult = Undefined;
	EndTry;
	Return vResult;
EndFunction // GetStructureByXMLString

// -------------------------------------------------------------------------
Function ReadXMLtoMap(pXMLString, rResult, pTextValueName, rXMLReader = Undefined, pReturnLevel = Undefined, pDoNotRead = False)
	#If Not WebClient THEN

		If rXMLReader = Undefined Then
			rXMLReader	= New XMLReader;
			rXMLReader.SetString(pXMLString);
		EndIf;
		
		If pReturnLevel = Undefined Then
			vReturnLevel = 1;
		Else
			vReturnLevel = pReturnLevel; 	
		EndIf;
		
		vCurrentLevel 		= vReturnLevel;
		vCurrentResult 		= Undefined;
		vArrayResult		= Undefined;
		While pDoNotRead Or rXMLReader.Read() Do
			If rXMLReader.NodeType = XMLNodeType.StartElement Then
				// Increase level
				vCurrentLevel 	= vCurrentLevel + 1;
				
				// If level > 2 then go deeper
				If vCurrentLevel > vReturnLevel + 1 Then
					ReadXMLtoMap(pXMLString, vCurrentResult, pTextValueName, rXMLReader, vCurrentLevel, True);
					
					// Decrease level
					vCurrentLevel = vCurrentLevel - 1;
					Continue;
				EndIf;
				
				// Get current result by name
				rResult.Property(rXMLReader.Name, vCurrentResult);
				If vCurrentResult = Undefined Then
					
					// If not found - add to result
					rResult.Insert(rXMLReader.Name, New Structure());
					vCurrentResult = rResult[rXMLReader.Name]; 
				ElsIf TypeOf(vCurrentResult) <> Type("Array") Then
					
					// If found and its not array - create array instead
					vInsertResult = New Array;
					vInsertResult.Add(vCurrentResult);
					rResult[rXMLReader.Name] 	= vInsertResult;
					
					// Get array result to add in the end and create current result 
					vArrayResult				= rResult[rXMLReader.Name];
					vCurrentResult 				= New Structure();
				Else
					
					// Get array result to add in the end and create current result 
					vArrayResult 	= rResult[rXMLReader.Name];
					vCurrentResult 	= New Structure();
				EndIf;
				While rXMLReader.NextAttribute() Do
					vCurrentResult.Insert(GetProperStructureName(rXMLReader.Name), rXMLReader.Value);
				EndDo;
			ElsIf rXMLReader.NodeType = XMLNodeType.Text Then			
				// If text - add value to current result with special name
				vCurrentResult.Insert(pTextValueName, rXMLReader.Value);
				
			ElsIf rXMLReader.NodeType = XMLNodeType.EndElement Then
				
				// If result is array - add current result to array
				If vArrayResult <> Undefined Then
					vArrayResult.Add(vCurrentResult);	
				EndIf;
				
				// Decrease level
				vCurrentLevel = vCurrentLevel - 1;
				
				// If current level < return level + 1 - return
				If vCurrentLevel < vReturnLevel + 1 Then
					Return rResult;
				EndIf;
			EndIf;
			pDoNotRead = False;
		EndDo;
	#EndIf
EndFunction // ReadXMLtoMap

// -------------------------------------------------------------------------
Function GetProperStructureName(pName)
	vResult = pName;
	vResult = StrReplace(vResult, ":", "");
	vResult = StrReplace(vResult, ".", "");
	vResult = StrReplace(vResult, ",", "");
	vResult = StrReplace(vResult, "-", "");
	Return vResult;
EndFunction // GetProperStructureName

// -------------------------------------------------------------------------
Function GetXMLStringByStructure(Val pStructure)
	vResponseXML = "";
	Try
 		xmlResponse = New XMLWriter;
		vXMLWriterSettings = New XMLWriterSettings("UTF-8", "1.0", False, False);
		xmlResponse.SetString(vXMLWriterSettings);
		xmlResponse.WriteXMLDeclaration();
		WriterMaptoXML(xmlResponse, pStructure);
		vResponseXML = xmlResponse.Close();
	Except
		vResponseXML = "";
	EndTry;
	Return vResponseXML;
EndFunction // GetXMLStringByStructure

// -------------------------------------------------------------------------
Procedure WriterMaptoXML(pxmlResponse, pStructure)
	For Each vItem In pStructure Do
		If TypeOf(vItem.Value) = Type("Structure") Then
			pxmlResponse.WriteStartElement(vItem.Key);
			WriterMaptoXML(pxmlResponse, vItem.Value);
			pxmlResponse.WriteEndElement();
		ElsIf TypeOf(vItem.Value) = Type("Array") Then 
			If vItem.Value.Count() > 0 Then
				For Each vRow In vItem.Value Do
					pxmlResponse.WriteStartElement(vItem.Key);
					WriterMaptoXML(pxmlResponse, vRow);
					pxmlResponse.WriteEndElement();
				EndDo;
			EndIf;
		Else
			pxmlResponse.WriteStartElement(vItem.Key);
			pxmlResponse.WriteText(TrimAll(vItem.Value));
			pxmlResponse.WriteEndElement();
		EndIf;
	EndDo;	
EndProcedure // WriterMaptoXML

#EndRegion

// -------------------------------------------------------------------------
Function SendQuery(pInteractionParameters, pHTTPConnection, pResourceAddress, pMethodName, pHTTPHeader, pBodyAsString, rSuccess)
	vResult = Undefined;
	vHTTPHeader = New Map();
	If pHTTPHeader <> Undefined Then
		vHTTPHeader = pHTTPHeader;	
	EndIf;	
	vHTTPResponse = Undefined;
		
	//Send query
	vHTTPRequest = New HTTPRequest(pResourceAddress, vHTTPHeader);
	If pBodyAsString <> Undefined Then 
		vHTTPRequest.SetBodyFromString(pBodyAsString);
	EndIf;
	If pMethodName = "POST" Then 
		vHTTPResponse = pHTTPConnection.Post(vHTTPRequest);
	ElsIf pMethodName = "DELETE" Then
		vHTTPResponse = pHTTPConnection.Delete(vHTTPRequest);	
	EndIf;
	If vHTTPResponse <> Undefined Then
		If vHTTPResponse.StatusCode = 200 Then
			rSuccess = True;
			vResult = vHTTPResponse.GetBodyAsString();
		Else
			rSuccess = False;
			vErrorDescription = "Response error! " + GetHTTPResponseCodeDescription(vHTTPResponse.StatusCode);
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SamsungLYNK.SendQuery", Enums.ExternalSystemEventTypes.Warning, , , vErrorDescription);
			WriteLogEvent(pInteractionParameters.InteractionID + "_SamsungLYNK_Sync", EventLogLevel.Error, , CurrentSessionDate(), vErrorDescription);	
		EndIf;
	EndIf;
	Return vResult;
EndFunction // SendQuery

#Region HTTPHeader

// -------------------------------------------------------------------------
Function GetRequest(pDocRow)
	vResult = New Structure("ResourceAddress, MethodName, Header, Body", Undefined, Undefined, Undefined, Undefined);
	If ValueIsFilled(pDocRow.ParentDoc) Then
		If Not pDocRow.IsCanceled Then
			vTurnOnParametersArr = StrSplit(pDocRow.TurnOnParameters, ";", False);
			If vTurnOnParametersArr[0] 	    = "CheckIn" Then
				vExtraParameters			= GetExtraParameters(vTurnOnParametersArr);
				vResult.ResourceAddress 	= "openapi/checkin";
				vResult.MethodName 			= "POST";
				vResult.Header 				= GetHeaderMap_CheckIn(pDocRow.ParentDoc, vExtraParameters);
			ElsIf vTurnOnParametersArr[0] 	= "Message" Then
				vExtraParameters			= GetExtraParameters(vTurnOnParametersArr);
				vResult.ResourceAddress 	= "openapi/message";
				vResult.MethodName 			= "POST";
				vResult.Header              = GetHeaderMap_Message();
				vResult.Body 				= GetElement_Message(pDocRow.ParentDoc, pDocRow.Remarks, vExtraParameters, pDocRow.MessageDateTime);
			ElsIf vTurnOnParametersArr[0]   = "SmartHubOn" Then
				vResult.ResourceAddress 	= "openapi/smarthub";
				vResult.MethodName 			= "POST";
				vResult.Header 				= GetHeaderMap_SmartHubOn(pDocRow.ParentDoc);  
			ElsIf vTurnOnParametersArr[0]   = "SmartHubOff" Then
				vResult.ResourceAddress 	= "openapi/smarthub";
				vResult.MethodName 			= "POST";
				vResult.Header 				= GetHeaderMap_SmartHubOff(pDocRow.ParentDoc);
			ElsIf vTurnOnParametersArr[0]   = "BillingInfoUpdated" Then
				vResult.ResourceAddress 	= "openapi/billinginfoupdated";
				vResult.MethodName 			= "POST";
				vResult.Header 				= GetHeaderMap_BillingInfoUpdated(pDocRow.ParentDoc);
			ElsIf vTurnOnParametersArr[0]   = "PPVSet_0" Then
				vResult.ResourceAddress 	= "openapi/ppvset";
				vResult.MethodName 			= "POST";
				vResult.Header 				= GetHeaderMap_PPVSet(pDocRow.ParentDoc, 0);
			ElsIf vTurnOnParametersArr[0]   = "PPVSet_1" Then
				vResult.ResourceAddress 	= "openapi/ppvset";
				vResult.MethodName 			= "POST";
				vResult.Header 				= GetHeaderMap_PPVSet(pDocRow.ParentDoc, 1);
			ElsIf vTurnOnParametersArr[0]   = "PPVSet_2" Then
				vResult.ResourceAddress 	= "openapi/ppvset";
				vResult.MethodName 			= "POST";
				vResult.Header 				= GetHeaderMap_PPVSet(pDocRow.ParentDoc, 2);
			ElsIf vTurnOnParametersArr[0]   = "PPVSet_3" Then
				vResult.ResourceAddress 	= "openapi/ppvset";
				vResult.MethodName 			= "POST";
				vResult.Header 				= GetHeaderMap_PPVSet(pDocRow.ParentDoc, 3);
			EndIf;
		Else
			vTurnOffParametersArr = StrSplit(pDocRow.TurnOffParameters, ";", False);
			If vTurnOffParametersArr[0]  	= "CheckOut" Then
				vResult.ResourceAddress 	= "openapi/checkout";
				vResult.MethodName 			= "DELETE";
				vResult.Header 				= GetHeaderMap_CheckOut(pDocRow.ParentDoc);
			EndIf;
		EndIf;
	EndIf;
	Return vResult;
EndFunction

// -------------------------------------------------------------------------
Function GetHeaderMap_CheckIn(pAccommodation, pExtraParameters)
	vHeader = New Map();
	vHeader.Insert("guestname", Transliterate(TrimAll(pAccommodation.Guest.FirstName)) + ":" + tcOnServer.GetDocumentNumberPresentation(pAccommodation.Guest.Code));
	vHeader.Insert("roomnumber", TrimAll(pAccommodation.Room.Description));
	vHeader.Insert("language", GetLanguageByGuest(pAccommodation.Guest));
	If pExtraParameters.Property("poweron") And pExtraParameters.poweron <> Undefined Then  
		If Boolean(pExtraParameters.poweron) Then	
			vHeader.Insert("poweron", "TRUE");
		Else
			vHeader.Insert("poweron", "FALSE");	
		EndIf;
	Else
		vHeader.Insert("poweron", "FALSE");	
	EndIf;
	If pExtraParameters.Property("smarthubapp") And pExtraParameters.smarthubapp <> Undefined Then 
		If Boolean(pExtraParameters.smarthubapp) Then
			vHeader.Insert("smarthubapp", "TRUE");
		Else
			vHeader.Insert("smarthubapp", "FALSE");	
		EndIf;
	Else
		vHeader.Insert("smarthubapp", "FALSE");	
	EndIf;
	Return vHeader;
EndFunction // GetHeaderMap_CheckIn

// -------------------------------------------------------------------------
Function GetHeaderMap_CheckOut(pAccommodation)
	vHeader = New Map();
	vHeader.Insert("roomnumber", TrimAll(pAccommodation.Room.Description));
	Return vHeader;
EndFunction // GetHeaderMap_CheckOut

// -------------------------------------------------------------------------
Function GetHeaderMap_Message()
	vHeader = New Map();
	vHeader.Insert("Content-Type", "application/x-www-form-urlencoded");
	Return vHeader;
EndFunction // GetHeaderMap_Message

// -------------------------------------------------------------------------
Function GetElement_Message(pAccommodation, pMessage, pExtraParameters, pReservedTime = '00010101')
	vElementArr = New Array();
	vElementArr.Add("roomlist=" + TrimAll(pAccommodation.Room.Description));
	vElementArr.Add("title=" + ?(StrLen(pMessage) > 10, Left(pMessage, 10) + "...", pMessage));
	vElementArr.Add("message=" + pMessage);
	If pExtraParameters <> Undefined And pExtraParameters.Property("messagetype") And pExtraParameters.messagetype <> Undefined Then
		vElementArr.Add("messagetype=" + pExtraParameters.messagetype);
	Else
		vElementArr.Add("messagetype=CONFIRM");	
	EndIf;
	If pExtraParameters <> Undefined And pExtraParameters.Property("closetime") And pExtraParameters.closetime <> Undefined And cmIsNumber(pExtraParameters.closetime) Then
		vElementArr.Add("closetime=" + pExtraParameters.closetime);
	Else
		vElementArr.Add("closetime=60");	
	EndIf;
	If pReservedTime <> '00010101' Then
		vElementArr.Add("reservedtime=" + Format(pReservedTime, "DF='yyyyMMdd HH:mm'"));
	EndIf;
	vElementStr = StrConcat(vElementArr, "&"); 
	Return vElementStr;
EndFunction // GetHeaderMap_BillingInfoUpdated

// -------------------------------------------------------------------------
Function GetHeaderMap_BillingInfoUpdated(pAccommodation)
	vHeader = New Map();
	vHeader.Insert("roomnumber", TrimAll(pAccommodation.Room.Description));
	Return vHeader;
EndFunction // GetHeaderMap_BillingInfoUpdated

// -------------------------------------------------------------------------
Function GetHeaderMap_SmartHubOn(pAccommodation)
	vHeader = New Map();
	vHeader.Insert("roomnumber", TrimAll(pAccommodation.Room.Description));
	vHeader.Insert("guestname", Transliterate(TrimAll(pAccommodation.Guest.FirstName)) + ":" + tcOnServer.GetDocumentNumberPresentation(pAccommodation.Guest.Code));
	vHeader.Insert("smarthub", True);
	Return vHeader;
EndFunction // GetHeaderMap_SmartHubOn

// -------------------------------------------------------------------------
Function GetHeaderMap_SmartHubOff(pAccommodation)
	vHeader = New Map();
	vHeader.Insert("roomnumber", TrimAll(pAccommodation.Room.Description));
	vHeader.Insert("guestname", Transliterate(TrimAll(pAccommodation.Guest.FirstName)) + ":" + tcOnServer.GetDocumentNumberPresentation(pAccommodation.Guest.Code));
	vHeader.Insert("smarthub", False);
	Return vHeader;
EndFunction // GetHeaderMap_SmartHubOff

// -------------------------------------------------------------------------
Function GetHeaderMap_PPVSet(pAccommodation, pChannelBank)
	vHeader = New Map();
	vCurDate = CurrentSessionDate();
	vPeriod = cmCalculateDuration(, vCurDate, pAccommodation.CheckOutDate); 
	vHeader.Insert("roomnumber", TrimAll(pAccommodation.Room.Description));
	vHeader.Insert("channelbank", pChannelBank);
	vHeader.Insert("startdate", Format(vCurDate, "DF=dd/MM/yyyy"));
	vHeader.Insert("starttime", Format(vCurDate, "DF=HH:mm"));
	vHeader.Insert("period", ?(vPeriod > 0, vPeriod, 1));
	Return vHeader;
EndFunction // GetHeaderMap_PPVSet

// -------------------------------------------------------------------------
Function GetBodyMap_PPVStatus(pAccommodation, pDefaultChannel)
	vXMLStructure = New Structure();
	vCurDate = CurrentSessionDate();
	vPeriod = cmCalculateDuration(, vCurDate, pAccommodation.CheckOutDate);
	If pDefaultChannel = "PPVSet_0" Then 
		vXMLStructure.Insert("channelbank", "0");
	ElsIf pDefaultChannel = "PPVSet_1" Then
		vXMLStructure.Insert("channelbank", "1");	
	ElsIf pDefaultChannel = "PPVSet_2" Then
		vXMLStructure.Insert("channelbank", "2");	
	ElsIf pDefaultChannel = "PPVSet_3" Then
		vXMLStructure.Insert("channelbank", "3");	
	Else
		vXMLStructure.Insert("channelbank", "0");	
	EndIf;
	vXMLStructure.Insert("startdate", Format(vCurDate, "DF=dd/MM/yyyy"));
	vXMLStructure.Insert("starttime", Format(vCurDate, "DF=HH:mm"));
	vXMLStructure.Insert("period", ?(vPeriod > 0, vPeriod, 1));
	vXMLStructure.Insert("command", "ppvstatus");
	vXMLStructure.Insert("statuscode", "0");
	Return New Structure("response", vXMLStructure);
EndFunction // GetBodyMap_PPVStatus

// -------------------------------------------------------------------------
Function GetBodyMap_Display(pAccommodation)
	vXMLStructure = New Structure();
	vNameStructure = New Structure();
	vItemsStructure = New Structure();
	vXMLStructure.Insert("command", "display");
	vNameStructure.Insert("roomnumber", TrimAll(pAccommodation.Room.Description));
	vNameStructure.Insert("companyname", TransliterateStr(?(ValueIsFilled(pAccommodation.Company), TrimAll(pAccommodation.Company.Description), TrimAll(pAccommodation.GuestGroup.Description))));
	vNameStructure.Insert("guestname", TrimAll(pAccommodation.Guest.FirstName) + ":" + tcOnServer.GetDocumentNumberPresentation(pAccommodation.Guest.Code));
	vNameStructure.Insert("checkoutdate", Format(pAccommodation.CheckOutDate, "DF=yyyy-MM-dd"));
	vXMLStructure.Insert("name", vNameStructure);
	vItems = GetRoomTransactions(pAccommodation);
	vNumber = 1;
	vItemsArr = New Array();
	For Each vItemsRow In vItems Do
		If Not vItemsRow.IsClientItem Then
			Continue;
		EndIf;
		If vItemsRow.Amount = 0 Then
			Continue;
		EndIf;
		vItemsArr.Add(GetItemsStructure(vNumber, vItemsRow, pAccommodation));
		vNumber = vNumber + 1;
	EndDo;
	vXMLStructure.Insert("item", vItemsArr);
	vXMLStructure.Insert("balance", GetBalance(pAccommodation));
	vXMLStructure.Insert("statuscode", "0");
	Return New Structure("response", vXMLStructure);
EndFunction // GetBodyMap_Display

// -------------------------------------------------------------------------
Function GetBodyMap_Information(pAccommodation)
	vXMLStructure = New Structure();
	vXMLStructure.Insert("command", "information");
	vXMLStructure.Insert("roomnumber", TrimAll(pAccommodation.Room.Description));
	vXMLStructure.Insert("roomtype", TransliterateStr(TrimAll(pAccommodation.Room.RoomType.Description)));
	vXMLStructure.Insert("guestname", TrimAll(pAccommodation.Guest.FirstName) + ":" + tcOnServer.GetDocumentNumberPresentation(pAccommodation.Guest.Code));
	vXMLStructure.Insert("languageid", GetLanguageByGuest(pAccommodation.Guest));
	vXMLStructure.Insert("statuscode", "0");
	Return New Structure("response", vXMLStructure);
EndFunction // GetBodyMap_Information

// -------------------------------------------------------------------------
Function GetBodyMap_RoomsList(pInteractionParameters)
	vRoomsInfo = GetRoomsInfo(pInteractionParameters.Hotel);
	vXMLStructure = New Structure();
	If vRoomsInfo.Count() > 0 Then 
		vXMLStructure.Insert("command", "roomslist");
		vRoomsInfoArr = New Array();
		For Each vRoomInfo In vRoomsInfo Do
			vRoomInfoStructure = New Structure();
			vRoomInfoStructure.Insert("roomnumber", vRoomInfo.roomnumber);
			vRoomInfoStructure.Insert("roomstatus", ?(vRoomInfo.roomstatus, "TRUE", "FALSE"));
			vRoomInfoStructure.Insert("guests", New Structure("guestname", ?(vRoomInfo.roomstatus, vRoomInfo.guestname + ":" + tcOnServer.GetDocumentNumberPresentation(vRoomInfo.guestid), "")));
			If vRoomInfo.roomstatus Then
				vRoomInfoStructure.Insert("smarthubapp", ?(vRoomInfo.smarthubapp, "TRUE", "FALSE"));	
				vRoomInfoStructure.Insert("languageid", vRoomInfo.languageid);
			EndIf;
			vRoomsInfoArr.Add(vRoomInfoStructure);
		EndDo;
		vXMLStructure.Insert("room", vRoomsInfoArr);
		vXMLStructure.Insert("statuscode", "0");
	EndIf;
	Return New Structure("response", vXMLStructure);
EndFunction // GetBodyMap_RoomsList

#EndRegion

#Region Additional_Functions

// -------------------------------------------------------------------------
Function GetLanguageByGuest(pGuest)
	vLanguage = "ENG";
	If ValueIsFilled(pGuest) And ValueIsFilled(pGuest.Language) Then
		If pGuest.Language = Catalogs.Languages.RU Then
			vLanguage = "RUS";	
		ElsIf pGuest.Language = Catalogs.Languages.EN Then
			vLanguage = "ENG";	
		ElsIf pGuest.Language = Catalogs.Languages.DE Then
	   		vLanguage = "DEU";
		EndIf;
	EndIf;
	Return vLanguage;
EndFunction // GetLanguageByGuest

// -------------------------------------------------------------------------
Function GetDocsToSync(pHotel)
	vQ = New Query;
	vQ.Text = "SELECT
	          |	RoomInterfaceStatus.Ref AS Ref,
	          |	RoomInterfaceStatus.RoomInterfaceType.TurnOnParameters AS TurnOnParameters,
	          |	RoomInterfaceStatus.RoomInterfaceType.TurnOffParameters AS TurnOffParameters,
	          |	RoomInterfaceStatus.ParentDoc AS ParentDoc,
	          |	RoomInterfaceStatus.Hotel AS Hotel,
	          |	RoomInterfaceStatus.Room AS Room,
	          |	RoomInterfaceStatus.Remarks AS Remarks,
	          |	RoomInterfaceStatus.IsProcessed AS IsProcessed,
	          |	RoomInterfaceStatus.IsCanceled AS IsCanceled,
	          |	RoomInterfaceStatus.Message AS Message,
	          |	RoomInterfaceStatus.CancellationMessage AS CancellationMessage,
	          |	RoomInterfaceStatus.Date AS Date,
	          |	RoomInterfaceStatus.InterfaceType AS InterfaceType,
	          |	RoomInterfaceStatus.MessageDateTime AS MessageDateTime
	          |FROM
	          |	Document.RoomInterfaceStatus AS RoomInterfaceStatus
	          |WHERE
	          |	NOT RoomInterfaceStatus.DeletionMark
	          |	AND NOT RoomInterfaceStatus.IsProcessed
	          |	AND RoomInterfaceStatus.RoomInterfaceType.InterfaceType = &qInterfaceType
	          |	AND NOT RoomInterfaceStatus.ParentDoc.CheckInDate IS NULL
	          |	AND RoomInterfaceStatus.ParentDoc.CheckInDate <= &qEndOfCurrentDate
	          |	AND NOT RoomInterfaceStatus.ParentDoc.CheckOutDate IS NULL
	          |	AND RoomInterfaceStatus.ParentDoc.CheckOutDate >= &qBegOfCurrentDate
	          |	AND NOT RoomInterfaceStatus.IsProcessingError
	          |	AND RoomInterfaceStatus.Hotel = &qHotel
	          |
	          |ORDER BY
	          |	Date";	
	vQ.SetParameter("qHotel", pHotel);
	vQ.SetParameter("qInterfaceType", Enums.InterfaceTypes.TV);
	vQ.SetParameter("qEndOfCurrentDate", EndOfDay(CurrentSessionDate()));
	vQ.SetParameter("qBegOfCurrentDate", BegOfDay(CurrentSessionDate()));

	Return vQ.Execute().Unload();
EndFunction

// -------------------------------------------------------------------------
Function GetResponseCodeDescription(pCode)
	vResult = "";
	If	pCode = "0" Then
    	vResult = NStr("en = 'Success'; de = 'Erfolg'; ru = 'Успех'");
	ElsIf pCode = "1" Then
		vResult = NStr("en = 'Unknown command'; de = 'Unbekannter Befehl'; ru = 'Неизвестная команда'");
	ElsIf pCode = "2" Then
		vResult = NStr("en = 'Both IP address and Room number are not valid.'; de = 'Sowohl die IP-Adresse als auch die Zimmer sind ungültig.'; ru = 'И IP-адрес, и номер комнаты недействительны.'");
	ElsIf pCode = "3" Then
		vResult = NStr("en = 'Room unoccupied'; de = 'Zimmer unbesetzt'; ru = 'Номер свободен'");
	ElsIf pCode = "4" Then 
		vResult = NStr("en = 'Unknown Account number'; de = 'Unbekannte Kontonummer'; ru = 'Неизвестный номер счета'");
	ElsIf pCode = "5" Then 
		vResult = NStr("en = 'Account number not checked into room'; de = 'Kontonummer nicht im Zimmer eingecheckt'; ru = 'Номер счета не зарегистрирован в комнате'");
	ElsIf pCode = "6" Then 
		vResult = NStr("en = 'Invalid payment method'; de = 'Ungültige Zahlungsmethode'; ru = 'Неверный способ оплаты'");
	ElsIf pCode = "7" Then 
		vResult = NStr("en = 'Account balance changed'; de = 'Kontostand geändert'; ru = 'Баланс аккаунта изменен'");
	ElsIf pCode = "8" Then 
		vResult = NStr("en = 'Locked folio'; de = 'Gesperrtes Folio'; ru = 'Заблокированный фолио'");
	ElsIf pCode = "9" Then 
		vResult = NStr("en = 'Guest message not found'; de = 'Gastnachricht nicht gefunden'; ru = 'Гостевое сообщение не найдено'");
	ElsIf pCode = "10" Then 
		vResult = NStr("en = 'Guest message cannot be delivered'; de = 'Gastnachricht kann nicht zugestellt werden'; ru = 'Гостевое сообщение не может быть доставлено'");
	ElsIf pCode = "11" Then 
		vResult = NStr("en = 'Not allowed at this time of day'; de = 'Zu dieser Tageszeit nicht erlaubt'; ru = 'Не разрешено в это время суток'");
	Else
		vResult = NStr("en = 'Unknown response code'; de = 'Unbekannter Antwortcode'; ru = 'Неизвестный код ответа'");
	EndIf;
	Return vResult;
EndFunction // GetResponseCodeDescription

// -------------------------------------------------------------------------
Function GetHTTPResponseCodeDescription(pCode)
	vResult = "";
	If	pCode = 200 Then
    	vResult = NStr("en = 'OK'; de = 'OK'; ru = 'OK'");
	ElsIf pCode = 201 Then
		vResult = NStr("en = 'CREATED'; de = 'ERSTELLT'; ru = 'СОЗДАН'");
	ElsIf pCode = 304 Then
		vResult = NStr("en = 'NOT MODIFIED'; de = 'NICHT MODIFIZIERT'; ru = 'НЕ МОДИФИЦИРОВАНО'");
	ElsIf pCode = 400 Then
		vResult = NStr("en = 'BAD REQUEST'; de = 'UNGÜLTIGE ANFORDERUNG'; ru = 'ПЛОХОЙ ЗАПРОС'");
	ElsIf pCode = 401 Then 
		vResult = NStr("en = 'UNAUTHORIZED'; de = 'NICHT AUTORISIERT'; ru = 'НЕСАНКЦИОНИРОВАНО'");
	ElsIf pCode = 403 Then 
		vResult = NStr("en = 'FORBIDDEN'; de = 'VERBOTEN'; ru = 'ЗАПРЕЩЕНО'");
	ElsIf pCode = 404 Then 
		vResult = NStr("en = 'NOT FOUND'; de = 'NICHT GEFUNDEN'; ru = 'НЕ НАЙДЕН'");
	ElsIf pCode = 409 Then 
		vResult = NStr("en = 'CONFLICT'; de = 'KONFLIKT'; ru = 'КОНФЛИКТ'");
	ElsIf pCode = 500 Then 
		vResult = NStr("en = 'INTERNAL SERVER ERROR'; de = 'INTERNER SERVERFEHLER'; ru = 'ВНУТРЕННЯЯ ОШИБКА СЕРВЕРА'");
	Else
		vResult = NStr("en = 'Unknown response code'; de = 'Unbekannter Antwortcode'; ru = 'Неизвестный код ответа'");
	EndIf;
	Return vResult;
EndFunction // GetHTTPResponseCodeDescription

// -----------------------------------------------------------------------------
Function GetExtraParameters(Val pTurnOnParametersArr)
	vResult = New Structure();
	vTurnOnParametersArrCount = pTurnOnParametersArr.Count(); 
	If pTurnOnParametersArr.Count() > 1 Then
		For vNumber = 1 To vTurnOnParametersArrCount - 1 Do
			vExtraParameterArr = StrSplit(pTurnOnParametersArr[vNumber], "=", False);
			vResult.Insert(TrimAll(vExtraParameterArr[0]), ?(vExtraParameterArr.Count() > 1, vExtraParameterArr[1], Undefined));
		EndDo;
	EndIf;
	Return vResult;
EndFunction // GetExtraParameters

// -----------------------------------------------------------------------------
Function Transliterate(Val pStr)
	vStr = "";
	For vNumber = 1 To StrLen(pStr) Do
		vChar = Mid(pStr, vNumber, 1);
		vCharCode = CharCode(vChar);
		If vCharCode > 127 Then
			vStr = vStr + "&#" + Format(vCharCode, "NFD=0; NZ=0; NG=") + ";";	
		Else
			vStr = vStr + vChar;   	
		EndIf;
	EndDo;
	Return vStr;
EndFunction // Transliterate

// -----------------------------------------------------------------------------
Function TransliterateStr(Val pStr)
	vStr = pStr;
	vStr = StrReplace(vStr, "А", "A");
	vStr = StrReplace(vStr, "Б", "B");
	vStr = StrReplace(vStr, "В", "V");
	vStr = StrReplace(vStr, "Г", "G");
	vStr = StrReplace(vStr, "Д", "D");
	vStr = StrReplace(vStr, "Е", "E");
	vStr = StrReplace(vStr, "Ё", "E");
	vStr = StrReplace(vStr, "Ж", "Zh");
	vStr = StrReplace(vStr, "З", "Z");
	vStr = StrReplace(vStr, "И", "I");
	vStr = StrReplace(vStr, "Й", "Y");
	vStr = StrReplace(vStr, "К", "K");
	vStr = StrReplace(vStr, "Л", "L");
	vStr = StrReplace(vStr, "М", "M");
	vStr = StrReplace(vStr, "Н", "N");
	vStr = StrReplace(vStr, "О", "O");
	vStr = StrReplace(vStr, "П", "P");
	vStr = StrReplace(vStr, "Р", "R");
	vStr = StrReplace(vStr, "С", "S");
	vStr = StrReplace(vStr, "Т", "T");
	vStr = StrReplace(vStr, "У", "U");
	vStr = StrReplace(vStr, "Ф", "F");
	vStr = StrReplace(vStr, "Х", "H");
	vStr = StrReplace(vStr, "Ц", "C");
	vStr = StrReplace(vStr, "Ч", "Ch");
	vStr = StrReplace(vStr, "Ш", "Sh");
	vStr = StrReplace(vStr, "Щ", "Sch");
	vStr = StrReplace(vStr, "Ь", "'");
	vStr = StrReplace(vStr, "Ы", "Yi");
	vStr = StrReplace(vStr, "Ъ", "");
	vStr = StrReplace(vStr, "Э", "E");
	vStr = StrReplace(vStr, "Ю", "Yu");
	vStr = StrReplace(vStr, "Я", "Ya");
	vStr = StrReplace(vStr, "а", "a");
	vStr = StrReplace(vStr, "б", "b");
	vStr = StrReplace(vStr, "в", "v");
	vStr = StrReplace(vStr, "г", "g");
	vStr = StrReplace(vStr, "д", "d");
	vStr = StrReplace(vStr, "е", "e");
	vStr = StrReplace(vStr, "ё", "e");
	vStr = StrReplace(vStr, "ж", "zh");
	vStr = StrReplace(vStr, "з", "z");
	vStr = StrReplace(vStr, "и", "i");
	vStr = StrReplace(vStr, "й", "y");
	vStr = StrReplace(vStr, "к", "k");
	vStr = StrReplace(vStr, "л", "l");
	vStr = StrReplace(vStr, "м", "m");
	vStr = StrReplace(vStr, "н", "n");
	vStr = StrReplace(vStr, "о", "o");
	vStr = StrReplace(vStr, "п", "p");
	vStr = StrReplace(vStr, "р", "r");
	vStr = StrReplace(vStr, "с", "s");
	vStr = StrReplace(vStr, "т", "t");
	vStr = StrReplace(vStr, "у", "u");
	vStr = StrReplace(vStr, "ф", "f");
	vStr = StrReplace(vStr, "х", "h");
	vStr = StrReplace(vStr, "ц", "c");
	vStr = StrReplace(vStr, "ч", "ch");
	vStr = StrReplace(vStr, "ш", "sh");
	vStr = StrReplace(vStr, "щ", "sch");
	vStr = StrReplace(vStr, "ь", "'");
	vStr = StrReplace(vStr, "ы", "yi");
	vStr = StrReplace(vStr, "ъ", "");
	vStr = StrReplace(vStr, "э", "e");
	vStr = StrReplace(vStr, "ю", "yu");
	vStr = StrReplace(vStr, "я", "ya");
	Return vStr;
EndFunction // Transliterate

// -----------------------------------------------------------------------------
Function GetRoomTransactions(pAccDocRef)
	vOneRoomAccommodations = cmGetOneRoomAccommodations(pAccDocRef.Room, pAccDocRef.GuestGroup, pAccDocRef.CheckInDate, pAccDocRef.CheckOutDate);
	vItems = GetDocumentListTransactions(vOneRoomAccommodations, pAccDocRef.Hotel);
	Return vItems;
EndFunction // GetRoomTransactions

// -----------------------------------------------------------------------------
Function GetDocumentListTransactions(pDocList, pHotel)
	// Build and run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accounts.Period AS Period,
	|	Accounts.TransactionItem AS TransactionItem,
	|	Accounts.Amount AS Amount,
	|	Accounts.IsPayment AS IsPayment,
	|	Accounts.IsClientItem AS IsClientItem,
	|	Accounts.FolioCurrency AS FolioCurrency,
	|	Accounts.FolioParentDoc AS FolioParentDoc
	|FROM
	|	(SELECT
	|		ClientAccounts.Period AS Period,
	|		CASE
	|			WHEN ClientAccounts.RecordType = &qExpense
	|				THEN ClientAccounts.PaymentMethod
	|			ELSE ClientAccounts.Service
	|		END AS TransactionItem,
	|		ClientAccounts.FolioCurrency AS FolioCurrency,
	|		ClientAccounts.Folio.ParentDoc AS FolioParentDoc,
	|		CASE
	|			WHEN ClientAccounts.RecordType = &qExpense
	|				THEN -ClientAccounts.Sum
	|			ELSE ClientAccounts.Sum
	|		END AS Amount,
	|		CASE
	|			WHEN ClientAccounts.RecordType = &qExpense
	|				THEN TRUE
	|			ELSE FALSE
	|		END AS IsPayment,
	|		TRUE AS IsClientItem
	|	FROM
	|		AccumulationRegister.Accounts AS ClientAccounts
	|	WHERE
	|		ClientAccounts.Period < &qBalancesPeriod
	|		AND (ClientAccounts.Folio.Customer = &qEmptyCustomer
	|				OR ClientAccounts.Folio.Customer <> &qEmptyCustomer
	|					AND ClientAccounts.Folio.Customer.IsIndividual)
	|		AND ClientAccounts.Folio.ParentDoc IN(&qDocList)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CustomerAccounts.Period,
	|		CASE
	|			WHEN CustomerAccounts.RecordType = &qExpense
	|				THEN CustomerAccounts.PaymentMethod
	|			ELSE CustomerAccounts.Service
	|		END,
	|		CustomerAccounts.FolioCurrency,
	|		CustomerAccounts.Folio.ParentDoc,
	|		CASE
	|			WHEN CustomerAccounts.RecordType = &qExpense
	|				THEN -CustomerAccounts.Sum
	|			ELSE CustomerAccounts.Sum
	|		END,
	|		CASE
	|			WHEN CustomerAccounts.RecordType = &qExpense
	|				THEN TRUE
	|			ELSE FALSE
	|		END,
	|		FALSE
	|	FROM
	|		AccumulationRegister.Accounts AS CustomerAccounts
	|	WHERE
	|		CustomerAccounts.Period < &qBalancesPeriod
	|		AND CustomerAccounts.Folio.Customer <> &qEmptyCustomer
	|		AND NOT CustomerAccounts.Folio.Customer.IsIndividual
	|		AND CustomerAccounts.Folio.ParentDoc IN(&qDocList)) AS Accounts
	|
	|ORDER BY
	|	Accounts.Period";
	vQry.SetParameter("qBalancesPeriod", ?(ValueIsFilled(pHotel), ?(pHotel.ShowDebtsOnCurrentDate, CurrentSessionDate(), '39991231235959'), '39991231235959'));
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	vQry.SetParameter("qDocList", pDocList);
	vQry.SetParameter("qExpense", AccumulationRecordType.Expense);
	Return vQry.Execute().Unload();
EndFunction // GetDocumentListTransactions

// -----------------------------------------------------------------------------
Function GetItemsStructure(pNumber, pItemsRow, pAccDocRef)
	vLanguage = pAccDocRef.Hotel.Language;
	If ValueIsFilled(pAccDocRef.Guest) And ValueIsFilled(pAccDocRef.Guest.Language) Then
		vLanguage = pAccDocRef.Guest.Language;
	EndIf;
	If Not ValueIsFilled(vLanguage) Then
		vLanguage = Catalogs.Languages.RU;
	EndIf;
	If pItemsRow.IsPayment Then
		vItemDescription = TransliterateStr(TrimAll(pItemsRow.TransactionItem.GetObject().pmGetPaymentMethodDescription(vLanguage)));
	Else
		vItemDescription = TransliterateStr(TrimAll(pItemsRow.TransactionItem.GetObject().pmGetServiceDescription(vLanguage)));
	EndIf;
	vItemsStructure = New Structure("itemcode", Format(pNumber, "NFD=0; NZ=0; NG="));
	vItemsStructure.Insert("itemname", vItemDescription);
	vItemsStructure.Insert("month", Format(pItemsRow.Period, "DF=MM"));
	vItemsStructure.Insert("day", Format(pItemsRow.Period, "DF=dd"));
	vItemsStructure.Insert("chargepayment", ?(pItemsRow.IsPayment, "1", "0"));
	vItemsStructure.Insert("amount", Format(pItemsRow.Amount, "NFD=2; NDS=.; NZ=0; NG="));	
	Return vItemsStructure;
EndFunction // GetItemsStructure

// -----------------------------------------------------------------------------
Function GetBalance(pAccDocRef)
	vOneRoomAccommodations = cmGetOneRoomAccommodations(pAccDocRef.Room, pAccDocRef.GuestGroup, pAccDocRef.CheckInDate, pAccDocRef.CheckOutDate);
	vBalances = cmGetDocumentListBalances(vOneRoomAccommodations, pAccDocRef.Hotel);
	vBalanceAmount = 0;
	vFolioCurrency = Undefined;
	For Each vBalancesRow In vBalances Do
		If vFolioCurrency <> Undefined And vBalancesRow.FolioCurrency <> vFolioCurrency Then
			Raise "Balance in different currencies found!";
		EndIf;
		vFolioCurrency = vBalancesRow.FolioCurrency;
		vBalanceAmount = vBalanceAmount + vBalancesRow.ClientSumBalance - vBalancesRow.ClientLimitBalance;
	EndDo;
	If vBalanceAmount < 0 Then
		vBalanceAmount = 0;
	EndIf;
	vBalance = Format(vBalanceAmount, "NFD=2; NDS=.; NZ=0; NG=");
	Return vBalance;
EndFunction // GetBALMessage

// -----------------------------------------------------------------------------
Function GetRoomsInfo(pHotel)
	vQuery = New Query();
	vQuery.Text =
	"SELECT
	|	Rooms.Ref AS Ref,
	|	CASE
	|		WHEN Rooms.TVCode <> """"
	|			THEN Rooms.TVCode
	|		ELSE Rooms.Description
	|	END AS Description
	|INTO Rooms
	|FROM
	|	Catalog.Rooms AS Rooms
	|WHERE
	|	NOT Rooms.DeletionMark
	|	AND NOT Rooms.IsFolder
	|	AND NOT Rooms.IsVirtual
	|	AND Rooms.Owner = &qHotel
	|	AND Rooms.IsUseTVInterface
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Accommodation.Ref AS Ref,
	|	Accommodation.Room AS Room,
	|	Accommodation.TurnOnParameters AS TurnOnParameters,
	|	Accommodation.GuestFirstName AS GuestFirstName,
	|	Accommodation.GuestCode AS GuestCode,
	|	Accommodation.GuestLanguage AS GuestLanguage
	|INTO AccommodationList
	|FROM
	|	(SELECT
	|		InterfaceStatus.TurnOnParameters AS TurnOnParameters,
	|		Accommodations.Ref AS Ref,
	|		Accommodations.Room AS Room,
	|		Accommodations.GuestFirstName AS GuestFirstName,
	|		Accommodations.GuestCode AS GuestCode,
	|		Accommodations.GuestLanguage AS GuestLanguage
	|	FROM
	|		(SELECT
	|			Accommodation.Ref AS Ref,
	|			Accommodation.Room AS Room,
	|			Accommodation.Guest.FirstName AS GuestFirstName,
	|			Accommodation.Guest.Code AS GuestCode,
	|			Accommodation.Guest.Language AS GuestLanguage
	|		FROM
	|			Document.Accommodation AS Accommodation
	|		WHERE
	|			NOT Accommodation.DeletionMark
	|			AND Accommodation.Posted
	|			AND Accommodation.Hotel = &qHotel
	|			AND Accommodation.AccommodationStatus.IsInHouse
	|			AND Accommodation.AccommodationStatus.IsActive
	|			AND Accommodation.CheckInDate <= &qCheckOutDate
	|			AND Accommodation.CheckOutDate >= &qCheckInDate
	|			AND (Accommodation.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Room)
	|					OR Accommodation.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Beds))
	|		
	|		GROUP BY
	|			Accommodation.Ref,
	|			Accommodation.Room,
	|			Accommodation.Guest.FirstName,
	|			Accommodation.Guest.Code,
	|			Accommodation.Guest.Language) AS Accommodations
	|			LEFT JOIN (SELECT TOP 1
	|				RoomInterfaceStatus.ParentDoc AS ParentDoc,
	|				RoomInterfaceStatus.RoomInterfaceType.TurnOnParameters AS TurnOnParameters
	|			FROM
	|				Document.RoomInterfaceStatus AS RoomInterfaceStatus
	|			WHERE
	|				NOT RoomInterfaceStatus.DeletionMark
	|				AND RoomInterfaceStatus.Hotel = &qHotel
	|				AND RoomInterfaceStatus.IsProcessed
	|				AND NOT RoomInterfaceStatus.IsCanceled
	|				AND (RoomInterfaceStatus.RoomInterfaceType.TurnOnParameters LIKE ""%smarthubapp=False%""
	|						OR RoomInterfaceStatus.RoomInterfaceType.TurnOnParameters LIKE ""%smarthubapp=True%""
	|						OR RoomInterfaceStatus.RoomInterfaceType.TurnOnParameters LIKE ""SmartHubOn;""
	|						OR RoomInterfaceStatus.RoomInterfaceType.TurnOnParameters LIKE ""SmartHubOff;"")
	|			
	|			ORDER BY
	|				RoomInterfaceStatus.PointInTime DESC) AS InterfaceStatus
	|			ON Accommodations.Ref = InterfaceStatus.ParentDoc) AS Accommodation
	|
	|INDEX BY
	|	Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Rooms.Description AS roomnumber,
	|	CASE
	|		WHEN NOT AccommodationList.TurnOnParameters IS NULL
	|			THEN CASE
	|					WHEN AccommodationList.TurnOnParameters LIKE ""SmartHubOn;""
	|							OR AccommodationList.TurnOnParameters LIKE ""%smarthubapp=True%""
	|						THEN TRUE
	|					ELSE FALSE
	|				END
	|		ELSE FALSE
	|	END AS smarthubapp,
	|	CASE
	|		WHEN AccommodationList.GuestFirstName IS NULL
	|			THEN """"
	|		ELSE AccommodationList.GuestFirstName
	|	END AS guestname,
	|	CASE
	|		WHEN AccommodationList.GuestCode IS NULL
	|			THEN """"
	|		ELSE AccommodationList.GuestCode
	|	END AS guestid,
	|	CASE
	|		WHEN AccommodationList.Ref IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS roomstatus,
	|	CASE
	|		WHEN NOT AccommodationList.Ref IS NULL
	|			THEN CASE
	|					WHEN AccommodationList.GuestLanguage = VALUE(Catalog.Languages.EN)
	|						THEN ""ENG""
	|					ELSE CASE
	|							WHEN AccommodationList.GuestLanguage = VALUE(Catalog.Languages.RU)
	|								THEN ""RUS""
	|							ELSE CASE
	|									WHEN AccommodationList.GuestLanguage = VALUE(Catalog.Languages.DE)
	|										THEN ""DEU""
	|									ELSE ""ENG""
	|								END
	|						END
	|				END
	|		ELSE ""ENG""
	|	END AS languageid
	|FROM
	|	Rooms AS Rooms
	|		LEFT JOIN AccommodationList AS AccommodationList
	|		ON Rooms.Ref = AccommodationList.Room
	|
	|ORDER BY
	|	Rooms.Ref.SortCode";
	vQuery.SetParameter("qHotel", pHotel);
	vQuery.SetParameter("qCheckInDate", CurrentSessionDate());
	vQuery.SetParameter("qCheckOutDate", CurrentSessionDate());
	Return vQuery.Execute().Unload();
EndFunction // GetRoomsInfo

#EndRegion

#EndRegion
