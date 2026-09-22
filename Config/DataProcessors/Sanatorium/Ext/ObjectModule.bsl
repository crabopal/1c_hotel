#Region Public

// -----------------------------------------------------------------------------
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // LoadDataProcessorAttributes

// -----------------------------------------------------------------------------
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // SaveDataProcessorAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export

EndProcedure // FillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	If Not pIsInteractive Then
		If UseMedicalRecordHistory Then
			LoadMedicalRecordsHistory(); 
		EndIf;
		If UseStatisticsRenderedAndPaidServices Then
			LoadStatisticsRenderedAndPaidServices();	
		EndIf;
		ClearHistoryFiles();
		If UseWebService Then
			ChangeOrderStatus();
		EndIf;    
	EndIf;
	If UseBus Then
		SendReservationMessages(pParameter, pIsInteractive);
	EndIf;
EndProcedure // Run

// -----------------------------------------------------------------------------
//
// Parameters:
//  pBody	 - String	 - Body
//  pHeaders - Map		 - Headers
//  rSuccess - Boolean	 - Success
//  rMessage - String	 - Message
//  pVersion - String	 - Version
// 
// Returns:
//  String - Result
//
Function HTTPRequest(pBody, pHeaders, rSuccess, rMessage, pVersion) Export
	vResult = "";
	Try       
		If pHeaders["command"] <> Undefined Then
			If pHeaders["command"] = "PostTransactionsRequest" Then
				vDataMap = JSONToMap(TrimAll(pBody));
				vResult = PostTransactionsRequest(vDataMap, ?(vDataMap["Transactions"] <> Undefined, vDataMap["Transactions"], New Array)); 		
			ElsIf pHeaders["command"] = "CreateGuestProfileRequest" Then
				vDataMap = JSONToMap(TrimAll(pBody)); 
				vResult = CreateGuestProfileRequest(vDataMap, ?(vDataMap["DocumentData"] <> Undefined, vDataMap["DocumentData"], New Map));
			Else
				rMessage = NStr("en = 'Unknown command: '; de = 'Unbekannter Befehl: '; ru = 'Неизвестная команда: '") + TrimAll(pHeaders["command"]);
				rSuccess = False;	
			EndIf;  
		Else
			rMessage = NStr("en = 'Unknown command'; de = 'Unbekannter Befehl'; ru = 'Неизвестная команда'");
			rSuccess = False;	
		EndIf;
	Except
		rMessage = ErrorDescription();
		rSuccess = False;
	EndTry;	
	Return vResult;	
EndFunction // HTTPRequest

// -----------------------------------------------------------------------------
//
// Parameters:
//  rMessage - String	 - Message
// 
// Returns:
//  Boolean - Result
//
Function CheckAccessToken(rMessage) Export
	If InteractionParameters.ActiveToDate > CurrentSessionDate() Then
		Return True;		
	EndIf;
	
	vType = "Auth/";
	vAuthorizationMap = New Map;  
	If IsBlankString(InteractionParameters.OAuth_RefreshToken) Then
		vAuthorizationMap.Insert("login", TrimAll(InteractionParameters.OAuth_ClientID));
		vAuthorizationMap.Insert("password", TrimAll(InteractionParameters.OAuth_ClientSecret));
		vType = vType + "Login";
	EndIf;
	
	vResponse = DataProcessors.Sanatorium.SendQueryToWebService(InteractionParameters, "POST", MapToJSON(vAuthorizationMap), vType, True);
	If TypeOf(vResponse) = Type("Map") Then
		vIntParObj						= InteractionParameters.GetObject();
		vIntParObj.ActiveToDate			= XMLValue(Type("Date"), vResponse["expirationDateTime"]);
		vIntParObj.OAuth_AccessToken	= vResponse["jwtToken"]; 
		vIntParObj.OAuth_RefreshToken	= vResponse["refreshToken"];
		vIntParObj.Write();	
		Return True;
	Else
		rMessage = vResponse;	
	EndIf; 
	
	Return False;	
EndFunction // CheckAccessToken

// -----------------------------------------------------------------------------
//
// Parameters:
//  pDocument	 - DocumentRef.Order - Order
//  rMessage	 - String			 - Message
// 
// Returns:
//  Boolean - Result
//
Function FillUnallocatedAccurals(pDocument, rMessage) Export 
	If Not CheckAccessToken(rMessage) Then
		Return False;	
	EndIf;   
	
	vExternalId = "";
	
	vParentDoc = pDocument.ParentDoc;
	If ValueIsFilled(vParentDoc) Then
		vExternalId = TrimAll(vParentDoc.Number) + "/";
	EndIf;
	
	vExternalId = vExternalId + TrimAll(pDocument.Client.Code);
		      
	vResponse = DataProcessors.Sanatorium.SendQueryToWebService(InteractionParameters, "GET", "", "Accounting/GetUnallocatedAccurals?externalId=" + vExternalId);
	If TypeOf(vResponse) = Type("Map") Then
		pDocument.Items.Clear();
		For Each vItem In vResponse["unallocatedAccurals"] Do
			vNewRow = pDocument.Items.Add();
			vNewRow.Item = GetOrderItem(vItem["name"]);
			vNewRow.Price = vItem["originalPricePerOne"];
			vNewRow.Quantity = vItem["quantity"];
			vNewRow.Sum = vItem["totalPrice"];
			vNewRow.ItemInfo = MapToJSON(vItem);
		EndDo; 
		pDocument.Sum = pDocument.Items.Total("Sum");  
		Return True;
	Else
		rMessage = vResponse;	
	EndIf;
	
	Return False;
EndFunction // GetUnallocatedAccurals

#EndRegion

#Region Private

#Region MedicalRecordsHistory

Procedure LoadMedicalRecordsHistory()

	If IsBlankString(MedicalRecordHistoryImportCatalog) Then
		vMessage = NStr("en = 'The directory with medical records is not specified!'; de = 'Das Verzeichnis mit Krankenakten ist nicht angegeben!'; ru = 'Не указан каталог с медицинскими записями!'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, "LoadMedicalRecordsHistory", Enums.ExternalSystemEventTypes.Error, "", "", vMessage, InteractionParameters.MaxLogLenght);
		Return;	
	EndIf;
		
	vFiles = FindFiles(TrimAll(MedicalRecordHistoryImportCatalog), "*.csv", False);
	If vFiles.Count() = 0 Then
		Return;	
	EndIf;
			
	vMedicalRecords = New ValueTable();
	vMedicalRecords.Columns.Add("ExternalId", cmGetStringTypeDescription());
	vMedicalRecords.Columns.Add("AccommodationCode", cmGetStringTypeDescription(12));
	vMedicalRecords.Columns.Add("AccommodationRef", cmGetDocumentTypeDescription("Accommodation"));
	vMedicalRecords.Columns.Add("ClientCode", cmGetStringTypeDescription(12));
	vMedicalRecords.Columns.Add("ClientRef", cmGetCatalogTypeDescription("Clients"));
	vMedicalRecords.Columns.Add("DepartureDate", cmGetDateTypeDescription());
	vMedicalRecords.Columns.Add("DepartureDiagnosis", cmGetStringTypeDescription());
	vMedicalRecords.Columns.Add("DepartureDiagnosisCode", cmGetStringTypeDescription(10));
	vMedicalRecords.Columns.Add("DepartureDiagnosisRef", cmGetCatalogTypeDescription("ICD10"));
	vMedicalRecords.Columns.Add("IsMainDiagnosis", cmGetBooleanTypeDescription());
	vMedicalRecords.Columns.Add("TreatmentResults", cmGetEnumTypeDescription("TreatmentResultStatuses"));

	For Each vFile In vFiles Do
		If Not tcCommonFunctionOnClientServer.cmExists(vFile) Then           
			vMessage = NStr("en = Medical record file not found! - '; de = 'Krankenaktendatei nicht gefunden! - '; ru = 'Файл с медицинскими записями не найден! - '") + vFile.Name;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, "LoadMedicalRecordsHistory", Enums.ExternalSystemEventTypes.Error, "", "", vMessage, InteractionParameters.MaxLogLenght);
			Continue;
		EndIf;
		
		vFileFullName = TrimAll(HistoryCatalog) + "/MedicalRecordsHistory" + Format(CurrentSessionDate(), "DF=_yyyy-MM-dd_HH-mm") + ".csv";
		vNumOfTries = 100;
		While vNumOfTries > 0 Do
			Try
				MoveFile(vFile.FullName, vFileFullName);
				Break;
			Except
				vNumOfTries = vNumOfTries - 1;
			EndTry;
		EndDo;
        If vNumOfTries = 0 Then
			vMessage = NStr("en = 'Failed to move medical records file to history folder'; de = 'Failed to move medical records file to history folder'; ru = 'Не удалось переместить файл с медицинскими записями в папку истории!'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, "LoadMedicalRecordsHistory", Enums.ExternalSystemEventTypes.Error, "", "", vMessage, InteractionParameters.MaxLogLenght);
			Continue;
		EndIf; 
		
		vExternalIdIndex = 2;
		vDepartureDateIndex = 4;
		vDepartureDiagnosisIndex = 5;
		vDepartureDiagnosisCodeIndex = 6;
		vIsMainDiagnosisIndex = 7;
		vTreatmentResultsIndex = 8;
		
		vTextDocument = New TextDocument;
		vTextDocument.Read(vFileFullName, TextEncoding.ANSI);
		
		vLineCount = vTextDocument.LineCount();
		If vLineCount <= 1 Then
			Continue;	
		EndIf;
		
		For i = 1 To vLineCount Do 
			vLine = vTextDocument.GetLine(i);
			If IsBlankString(vLine) Then
				Continue;	
			EndIf;
			
			vLineArr = StrSplit(vLine, ";", True);			
			If i = 1 Then
				For j = 0 To vLineArr.Count() - 1 Do
					If Lower(vLineArr[j]) = "externalid" Then
						vExternalIdIndex = j; 	
					ElsIf Lower(vLineArr[j]) = "departuredate" Then
						vDepartureDateIndex = j;
					ElsIf Lower(vLineArr[j]) = "departurediagnosis" Then
						vDepartureDiagnosisIndex = j;
					ElsIf Lower(vLineArr[j]) = "departurediagnosiscode" Then
						vDepartureDiagnosisCodeIndex = j;
					ElsIf Lower(vLineArr[j]) = "ismaindiagnosis" Then
						vIsMainDiagnosisIndex = j;
					ElsIf Lower(vLineArr[j]) = "treatmentresults" Then
						vTreatmentResultsIndex = j;
					EndIf;
				EndDo;
				Continue;
			EndIf;
			
			vMRNewRow = vMedicalRecords.Add();
			vMRNewRow.ExternalId = vLineArr[vExternalIdIndex];
			vExternalIdArr = StrSplit(TrimAll(vMRNewRow.ExternalId), "/", True);
			If vExternalIdArr.Count() > 1 Then
				vMRNewRow.AccommodationCode = vExternalIdArr[0];
				vMRNewRow.ClientCode = vExternalIdArr[1];
			Else
				vMRNewRow.AccommodationCode = "";
				vMRNewRow.ClientCode = vExternalIdArr[0];
			EndIf;
			vMRNewRow.DepartureDate = Date(Mid(vLineArr[vDepartureDateIndex], 7,4) + Mid(vLineArr[vDepartureDateIndex] ,4, 2) + Left(vLineArr[vDepartureDateIndex], 2));
			vMRNewRow.DepartureDiagnosis = TrimAll(vLineArr[vDepartureDiagnosisIndex]);
			vMRNewRow.DepartureDiagnosisCode = TrimAll(vLineArr[vDepartureDiagnosisCodeIndex]);
			vMRNewRow.IsMainDiagnosis = Boolean(TrimAll(vLineArr[vIsMainDiagnosisIndex]));
			vMRNewRow.TreatmentResults = GetTreatmentResultsByCode(Lower(TrimAll(vLineArr[vTreatmentResultsIndex])));	
		EndDo;
	EndDo;
	
	If vMedicalRecords.Count() > 0 Then
        vMedicalRecordsCopy = vMedicalRecords.Copy(, "AccommodationCode, ClientCode");
		vMedicalRecordsCopy.GroupBy("AccommodationCode, ClientCode");
		vRefList = GetAccommodationAndClientRef(vMedicalRecordsCopy);
		For Each vRefRow In vRefList Do
			vMedicalRecordsArr = vMedicalRecords.FindRows(New Structure("AccommodationCode, ClientCode", vRefRow.AccommodationCode, vRefRow.ClientCode));
			For Each vMedicalRecordsRow In vMedicalRecordsArr Do
				vMedicalRecordsRow.AccommodationRef = vRefRow.AccommodationRef;
				vMedicalRecordsRow.ClientRef = vRefRow.GuestRef;
			EndDo;
		EndDo;
		vMedicalRecordsCopy = vMedicalRecords.Copy(, "DepartureDiagnosis, DepartureDiagnosisCode");
		vMedicalRecordsCopy.GroupBy("DepartureDiagnosis, DepartureDiagnosisCode");
		vRefList = GetICD10Ref(vMedicalRecordsCopy);
		For Each vRefRow In vRefList Do
			vMedicalRecordsArr = vMedicalRecords.FindRows(New Structure("DepartureDiagnosisCode", vRefRow.DepartureDiagnosisCode));
			vDepartureDiagnosisRef = vRefRow.DepartureDiagnosisRef;
			If Not ValueIsFilled(vDepartureDiagnosisRef) Then
				vNewDepartureDiagnosisRef = Catalogs.ICD10.CreateItem();
				vNewDepartureDiagnosisRef.Code = vRefRow.DepartureDiagnosisCode;
				vNewDepartureDiagnosisRef.Description = vRefRow.DepartureDiagnosis;
				vNewDepartureDiagnosisRef.Write();
				vDepartureDiagnosisRef = vNewDepartureDiagnosisRef.Ref;
			EndIf;
			For Each vMedicalRecordsRow In vMedicalRecordsArr Do
				vMedicalRecordsRow.DepartureDiagnosisRef = vDepartureDiagnosisRef;
			EndDo;
		EndDo;
		vMedicalRecordsCopy = vMedicalRecords.Copy(, "ClientRef");
		vMedicalRecordsCopy.GroupBy("ClientRef");
		vMaxDiagnosisNumberByClient = GetMaxDiagnosisNumber(vMedicalRecordsCopy);	
		vMedicalRecordsCopy = vMedicalRecords.Copy(, "ExternalId");
		vMedicalRecordsCopy.GroupBy("ExternalId");
		For Each vMedicalRecordsRow In vMedicalRecordsCopy Do
			vMedicalRecordsArr = vMedicalRecords.FindRows(New Structure("ExternalId", vMedicalRecordsRow.ExternalId));
			If vMedicalRecordsArr.Count() = 0 Or Not ValueIsFilled(vMedicalRecordsArr[0].ClientRef) Then
				vMessage = StrTemplate(NStr("en = 'Could not find client with code %1!'; de = 'Could not find client with code %1!'; ru = 'Не удалось найти клиента с кодом %1!'"), vMedicalRecordsRow.ExternalId);
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, "LoadMedicalRecordsHistory", Enums.ExternalSystemEventTypes.Error, "", "", vMessage, InteractionParameters.MaxLogLenght);
				Continue;	
			EndIf;       
			vMaxDiagnosisNumberByClientArr = vMaxDiagnosisNumberByClient.FindRows(New Structure("ClientRef", vMedicalRecordsArr[0].ClientRef));
			If vMaxDiagnosisNumberByClientArr.Count() > 0 Then
				vDiagnosisNumber = vMaxDiagnosisNumberByClientArr[0].DiagnosisNumber + 1;
			Else
				vDiagnosisNumber = 0;
			EndIf;
			For Each vMedicalRecordsRow In vMedicalRecordsArr Do
				InformationRegisters.MedicalRecordsHistory.WriteData(vMedicalRecordsRow.ClientRef, vMedicalRecordsRow.AccommodationRef, 
																	 InteractionParameters.Hotel, vDiagnosisNumber, vMedicalRecordsRow.DepartureDate, 
																	 vMedicalRecordsRow.IsMainDiagnosis, vMedicalRecordsRow.DepartureDiagnosisRef, 
																	 vMedicalRecordsRow.TreatmentResults);  
				vDiagnosisNumber = vDiagnosisNumber + 1;	
			EndDo;
		EndDo;
	EndIf;	
EndProcedure // LoadMedicalRecordsHistory

// -----------------------------------------------------------------------------
Function GetAccommodationAndClientRef(pDocList)
	vQ = New Query;
	vQ.Text =
	"SELECT
	|	DocList.AccommodationCode AS AccommodationCode,
	|	DocList.ClientCode AS ClientCode
	|INTO DocList
	|FROM
	|	&qDocList AS DocList
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Accommodation.Ref AS AccommodationRef,
	|	Accommodation.Guest AS GuestRef,
	|	DocList.AccommodationCode AS AccommodationCode,
	|	DocList.ClientCode AS ClientCode
	|FROM
	|	Document.Accommodation AS Accommodation
	|		INNER JOIN DocList AS DocList
	|		ON (CASE
	|				WHEN DocList.AccommodationCode = """"
	|					THEN FALSE
	|				ELSE Accommodation.Number = DocList.AccommodationCode
	|						AND Accommodation.Guest.Code = DocList.ClientCode
	|			END)
	|WHERE
	|	Accommodation.Posted
	|	AND NOT Accommodation.DeletionMark
	|	AND Accommodation.Hotel = &qHotel
	|
	|UNION ALL
	|
	|SELECT
	|	NULL,
	|	Clients.Ref,
	|	DocList.AccommodationCode,
	|	DocList.ClientCode
	|FROM
	|	Catalog.Clients AS Clients
	|		INNER JOIN DocList AS DocList
	|		ON (CASE
	|				WHEN DocList.AccommodationCode = """"
	|					THEN Clients.Code = DocList.ClientCode
	|				ELSE FALSE
	|			END)
	|WHERE
	|	NOT Clients.DeletionMark
	|	AND NOT Clients.IsFolder";
	vQ.SetParameter("qHotel", InteractionParameters.Hotel);
	vQ.SetParameter("qDocList", pDocList);
	Return vq.Execute().Unload();
EndFunction // GetAccommodationAndClientRef

// -----------------------------------------------------------------------------
Function GetICD10Ref(pDepartureDiagnosis)
	vQ = New Query;
	vQ.Text =
	"SELECT
	|	DepartureDiagnosisCodeList.DepartureDiagnosisCode AS DepartureDiagnosisCode,
	|	DepartureDiagnosisCodeList.DepartureDiagnosis AS DepartureDiagnosis
	|INTO DepartureDiagnosisCodeList
	|FROM
	|	&qDepartureDiagnosisCodeList AS DepartureDiagnosisCodeList
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DepartureDiagnosisCodeList.DepartureDiagnosisCode AS DepartureDiagnosisCode,
	|	DepartureDiagnosisCodeList.DepartureDiagnosis AS DepartureDiagnosis,
	|	ICD10.Ref AS DepartureDiagnosisRef
	|FROM
	|	DepartureDiagnosisCodeList AS DepartureDiagnosisCodeList
	|		LEFT JOIN Catalog.ICD10 AS ICD10
	|		ON DepartureDiagnosisCodeList.DepartureDiagnosisCode = ICD10.Code
	|WHERE
	|	CASE
	|			WHEN ICD10.Code IS NOT NULL 
	|				THEN NOT ICD10.DeletionMark
	|						AND NOT ICD10.IsFolder
	|			ELSE TRUE
	|		END";
	vQ.SetParameter("qDepartureDiagnosisCodeList", pDepartureDiagnosis);
	Return vQ.Execute().Unload();
EndFunction // GetICD10Ref

// ----------------------------------------------------------------------------
Function GetMaxDiagnosisNumber(pClient) 
	vQ = New Query;
	vQ.Text =
	"SELECT
	|	ClientList.ClientRef AS ClientRef
	|INTO ClientList
	|FROM
	|	&qClientList AS ClientList
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(ISNULL(MedicalRecordsHistory.DiagnosisNumber, -1)) AS DiagnosisNumber,
	|	ClientList.ClientRef AS ClientRef
	|FROM
	|	ClientList AS ClientList
	|		LEFT JOIN InformationRegister.MedicalRecordsHistory AS MedicalRecordsHistory
	|		ON ClientList.ClientRef = MedicalRecordsHistory.Client
	|
	|GROUP BY
	|	ClientList.ClientRef";
	vQ.SetParameter("qClientList", pClient);
	Return vQ.Execute().Unload();
EndFunction // GetMaxDiagnosisNumber

// -----------------------------------------------------------------------------
Function GetTreatmentResultsByCode(pTreatmentResultStatusesCode)
	If pTreatmentResultStatusesCode = "улучшение" Then
		Return Enums.TreatmentResultStatuses.Improvement;	
	ElsIf pTreatmentResultStatusesCode = "ухудшение" Then
		Return Enums.TreatmentResultStatuses.Deterioration;	
	ElsIf pTreatmentResultStatusesCode = "без изменения" Then		
		Return Enums.TreatmentResultStatuses.NoChange;
	Else
		Return Enums.TreatmentResultStatuses.NoChange;	
	EndIf;
EndFunction // GetTreatmentResultsByCode

#EndRegion

#Region StatisticsRenderedAndPaidServices 

Procedure LoadStatisticsRenderedAndPaidServices()
	If IsBlankString(RenderedServicesImportCatalog) Then
		vMessage = NStr("en = 'The catalog of rendered services is not specified!'; de = 'Der Katalog der erbrachten Leistungen ist nicht angegeben!'; ru = 'Не указан каталог оказанных услуг!'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, "LoadStatisticsRenderedAndPaidServices", Enums.ExternalSystemEventTypes.Error, "", "", vMessage, InteractionParameters.MaxLogLenght);
		Return;	
	EndIf;
	
	If IsBlankString(PaymentsImportCatalog) Then
		vMessage = NStr("en = 'Payment catalog not specified!'; de = 'Zahlungskatalog nicht angegeben!'; ru = 'Не указан каталог платежей!'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, "LoadStatisticsRenderedAndPaidServices", Enums.ExternalSystemEventTypes.Error, "", "", vMessage, InteractionParameters.MaxLogLenght);
		Return;	
	EndIf;
		
	vRenderedServicesFiles = FindFiles(TrimAll(RenderedServicesImportCatalog), "*.csv", False);
	vPaymentsFiles = FindFiles(TrimAll(PaymentsImportCatalog), "*.csv", False);
	If vRenderedServicesFiles.Count() = 0 Or vPaymentsFiles.Count() = 0 Then
		Return;	
	EndIf;
	
	vRenderedServices = New ValueTable();
	vRenderedServices.Columns.Add("PatientFullName", cmGetStringTypeDescription());
	vRenderedServices.Columns.Add("Room", cmGetCatalogTypeDescription("Rooms"));
	vRenderedServices.Columns.Add("ServiceItem", cmGetCatalogTypeDescription("OrderItems"));
	vRenderedServices.Columns.Add("PrescriptionPrice", cmGetNumberTypeDescription(17, 2, False)); 
	vRenderedServices.Columns.Add("DateComplete", cmGetDateTimeTypeDescription());
	vRenderedServices.Columns.Add("Service", cmGetCatalogTypeDescription("Services"));
	
	vPayments = New ValueTable();
	vPayments.Columns.Add("PatientFullName", cmGetStringTypeDescription()); 
	vPayments.Columns.Add("PaidDate", cmGetDateTimeTypeDescription());
	vPayments.Columns.Add("TotalPrice", cmGetNumberTypeDescription(17, 2, False)); 
	vPayments.Columns.Add("PaymentMethods", cmGetCatalogTypeDescription("PaymentMethods"));
	
	vMinDate = '39991231';
	vMaxDate = '00010101';
	For Each vFile In vRenderedServicesFiles Do
		If Not tcCommonFunctionOnClientServer.cmExists(vFile) Then           
			vMessage = NStr("en = File with rendered services not found! - '; de = 'Datei mit erbrachten Leistungen nicht gefunden! - '; ru = 'Файл с оказанными услугами не найден! - '") + vFile.Name;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, "LoadStatisticsRenderedAndPaidServices", Enums.ExternalSystemEventTypes.Error, "", "", vMessage, InteractionParameters.MaxLogLenght);
			Continue;
		EndIf; 
		
		vFileFullName = TrimAll(HistoryCatalog) + "/RenderedServicesHistory" + Format(CurrentSessionDate(), "DF=_yyyy-MM-dd_HH-mm-ss") + ".csv";
		vNumOfTries = 100;
		While vNumOfTries > 0 Do
			Try
				MoveFile(vFile.FullName, vFileFullName);
				Break;
			Except
				vNumOfTries = vNumOfTries - 1;
			EndTry;
		EndDo;
        If vNumOfTries = 0 Then
			vMessage = NStr("en = 'Failed to move file with rendered services to history folder!'; de = 'Datei mit erbrachten Diensten konnte nicht in den Verlaufsordner verschoben werden!'; ru = 'Не удалось переместить файл с оказанными услугами в папку истории!'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, "LoadStatisticsRenderedAndPaidServices", Enums.ExternalSystemEventTypes.Error, "", "", vMessage, InteractionParameters.MaxLogLenght);
			Continue;
		EndIf;
		
		vPatientFullNameIndex = 1;
		vRoomNameIndex = 4;
		vServiceItemNameIndex = 6;
		vPrescriptionPriceIndex = 7;
		vDateCompleteIndex = 8; 
		vServicePointNameIndex = 11; 
		
		vTextDocument = New TextDocument;
		vTextDocument.Read(vFileFullName, TextEncoding.ANSI);
		
		vLineCount = vTextDocument.LineCount();
		If vLineCount <= 1 Then
			Continue;	
		EndIf; 
		
		For i = 1 To vLineCount Do 
			vLine = vTextDocument.GetLine(i);
			If IsBlankString(vLine) Then
				Continue;	
			EndIf;    
			
			vLineArr = StrSplit(vLine, ";", True);			
			If i = 1 Then
				For j = 0 To vLineArr.Count() - 1 Do
					If Lower(vLineArr[j]) = "patientfullname" Then
						vPatientFullNameIndex = j; 	
					ElsIf Lower(vLineArr[j]) = "roomname" Then
						vRoomNameIndex = j;
					ElsIf Lower(vLineArr[j]) = "serviceitemname" Then
						vServiceItemNameIndex = j;
					ElsIf Lower(vLineArr[j]) = "prescriptionprice" Then
						vPrescriptionPriceIndex = j;
					ElsIf Lower(vLineArr[j]) = "datecomplete" Then
						vDateCompleteIndex = j;
					ElsIf Lower(vLineArr[j]) = "servicepointname" Then
						vServicePointNameIndex = j;
					EndIf;
				EndDo;
				Continue;
			EndIf;
			
			vRSNewRow = vRenderedServices.Add();
			vRSNewRow.PatientFullName = TrimAll(vLineArr[vPatientFullNameIndex]);   
			vRoomName =  TrimAll(vLineArr[vRoomNameIndex]);
			If Not IsBlankString(vRoomName) And vRoomName <> "0" Then
				vRSNewRow.Room = cmGetObjectRefByExternalSystemCode(InteractionParameters.Hotel, InteractionParameters.InteractionID, "Rooms", TrimAll(vLineArr[vRoomNameIndex]));
			EndIf;    
			vRSNewRow.ServiceItem = GetServiceItemByName(TrimAll(vLineArr[vServiceItemNameIndex]));
			vRSNewRow.PrescriptionPrice = Number(TrimAll(vLineArr[vPrescriptionPriceIndex]));
			vRSNewRow.DateComplete = BegOfDay(Date(Mid(vLineArr[vDateCompleteIndex], 7, 4) + Mid(vLineArr[vDateCompleteIndex] ,4, 2) + Left(vLineArr[vDateCompleteIndex], 2) + Mid(vLineArr[vDateCompleteIndex], 12, 2) + Mid(vLineArr[vDateCompleteIndex], 15, 2)));
			vRSNewRow.Service = GetServiceByName(TrimAll(vLineArr[vServicePointNameIndex]));
			
			vMinDate = Min(vMinDate, vRSNewRow.DateComplete);
			vMaxDate = Max(vMaxDate, vRSNewRow.DateComplete);
		EndDo;
	EndDo;
	
	For Each vFile In vPaymentsFiles Do
		If Not tcCommonFunctionOnClientServer.cmExists(vFile) Then           
			vMessage = NStr("en = Payment file not found! - '; de = 'Zahlungsdatei nicht gefunden! - '; ru = 'Файл с платежами не найден! - '") + vFile.Name;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, "LoadStatisticsRenderedAndPaidServices", Enums.ExternalSystemEventTypes.Error, "", "", vMessage, InteractionParameters.MaxLogLenght);
			Continue;
		EndIf;
		
		vFileFullName = TrimAll(HistoryCatalog) + "/PaymentsHistory" + Format(CurrentSessionDate(), "DF=_yyyy-MM-dd_HH-mm-ss") + ".csv";
		vNumOfTries = 100;
		While vNumOfTries > 0 Do
			Try
				MoveFile(vFile.FullName, vFileFullName);
				Break;
			Except
				vNumOfTries = vNumOfTries - 1;
			EndTry;
		EndDo;
        If vNumOfTries = 0 Then
			vMessage = NStr("en = 'Failed to move the file with payments to the history folder!'; de = 'Die Datei mit den Zahlungen konnte nicht in den Verlaufsordner verschoben werden!'; ru = 'Не удалось переместить файл с платежами в папку истории!'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, "LoadStatisticsRenderedAndPaidServices", Enums.ExternalSystemEventTypes.Error, "", "", vMessage, InteractionParameters.MaxLogLenght);
			Continue;
		EndIf; 
		
		vPatientFullNameIndex = 2;
		vPaidDateIndex = 4; 
		vTotalPriceIndex = 6;
		vCodeIndex = 8;
		
		vTextDocument = New TextDocument;
		vTextDocument.Read(vFileFullName, TextEncoding.ANSI);
		
		vLineCount = vTextDocument.LineCount();
		If vLineCount <= 1 Then
			Continue;	
		EndIf;  
		
		For i = 1 To vLineCount Do 
			vLine = vTextDocument.GetLine(i);
			If IsBlankString(vLine) Then
				Continue;	
			EndIf;
			
			vLineArr = StrSplit(vLine, ";", True);
			If i = 1 Then
				For j = 0 To vLineArr.Count() - 1 Do
					If Lower(vLineArr[j]) = "patientfullname" Then
						vPatientFullNameIndex = j; 	
					ElsIf Lower(vLineArr[j]) = "paiddate" Then
						vPaidDateIndex = j;
					ElsIf Lower(vLineArr[j]) = "totalprice" Then
						vTotalPriceIndex = j;
					ElsIf Lower(vLineArr[j]) = "code" Then
						vCodeIndex = j;
					EndIf;
				EndDo;
				Continue;
			EndIf;
			
			vPNewRow = vPayments.Add();
			vPNewRow.PatientFullName = TrimAll(vLineArr[vPatientFullNameIndex]);
			vPNewRow.PaidDate = Date(Mid(vLineArr[vPaidDateIndex], 7, 4) + Mid(vLineArr[vPaidDateIndex] ,4, 2) + Left(vLineArr[vPaidDateIndex], 2) + Mid(vLineArr[vPaidDateIndex], 12, 2) + Mid(vLineArr[vPaidDateIndex], 15, 2)); 
			vPNewRow.TotalPrice = Number(TrimAll(vLineArr[vTotalPriceIndex]));
			vPNewRow.PaymentMethods = cmGetObjectRefByExternalSystemCode(InteractionParameters.Hotel, InteractionParameters.InteractionID, "PaymentMethods", TrimAll(vLineArr[vCodeIndex]));
		EndDo; 
	EndDo;
	
	If vPayments.Count() > 0 And vRenderedServices.Count() > 0 Then
		BeginTransaction(DataLockControlMode.Managed); 
		Try
			vFolioObj = Documents.Folio.CreateDocument();
			vFolioObj.pmFillAttributesWithDefaultValues();
			vFolioObj.Hotel = InteractionParameters.Hotel; 
			vFolioObj.Date = CurrentSessionDate();
			vFolioObj.DateTimeFrom = BegOfDay(vMinDate);
			vFolioObj.DateTimeTo = EndOfDay(vMaxDate);
			vFolioObj.Description = NStr("en = 'Charge from sanatorium'; de = 'Laden aus Sanatorium'; ru = 'Начисление из санаториума'");
			vFolioObj.Write();
			
			vRenderedServicesByPatient = vRenderedServices.Copy(, "PatientFullName, Room, DateComplete");
			vRenderedServicesByPatient.GroupBy("PatientFullName, Room, DateComplete");
			
			For Each vRenderedServiceByPatientRow In vRenderedServicesByPatient Do
				vRenderedServicesArr = vRenderedServices.FindRows(New Structure("PatientFullName, Room, DateComplete", vRenderedServiceByPatientRow.PatientFullName, vRenderedServiceByPatientRow.Room, vRenderedServiceByPatientRow.DateComplete));
				
				vNewOrder = Documents.Order.CreateDocument();
				vNewOrder.pmFillAuthorAndDate();
				vNewOrder.OrderTime = vRenderedServiceByPatientRow.DateComplete;
				vNewOrder.Remarks = vRenderedServiceByPatientRow.PatientFullName;
				vNewOrder.Type = StatisticsOrderType; 
				vNewOrder.Status = GetOrderStatus(vNewOrder.Type); 
				If StatisticsOrderType.ServicesAllowed.Count() > 0 Then
					vNewOrder.Service = StatisticsOrderType.ServicesAllowed[0].Service;
				EndIf;
				vNewOrder.Hotel = InteractionParameters.Hotel;
				vNewOrder.Folio = vFolioObj.Ref;  
				vNewOrder.Room = vRenderedServiceByPatientRow.Room;
				vNewOrder.Items.Clear();
				For Each vRenderedServiceRow In vRenderedServicesArr Do
                	vNewOrderItem = vNewOrder.Items.Add();
					vNewOrderItem.Item = vRenderedServiceRow.ServiceItem;
					vNewOrderItem.Quantity = 1;
					vNewOrderItem.Service = vRenderedServiceRow.Service;
					vNewOrderItem.Sum = vRenderedServiceRow.PrescriptionPrice;
					vNewOrderItem.Price = Round(vNewOrderItem.Sum / vNewOrderItem.Quantity, 2, RoundMode.Round15as20); 
				EndDo; 
				vNewOrder.Sum = vNewOrder.Items.Total("Sum"); 
				vNewOrder.Write(DocumentWriteMode.Posting);
			EndDo;
			
			For Each vPaymentRow In vPayments Do 
				If vPaymentRow.TotalPrice < 0 Then
					vNewDocObj = Documents.Return.CreateDocument();
				Else
					vNewDocObj = Documents.Payment.CreateDocument();	
				EndIf;
				
				vNewDocObj.Fill(vFolioObj.Ref); 
				vNewDocObj.PaymentCurrency = InteractionParameters.Hotel.BaseCurrency;
				vNewDocObj.PaymentMethod = vPaymentRow.PaymentMethods;
				vNewDocObj.Remarks = vPaymentRow.PatientFullName;
				vNewDocObj.Date = vPaymentRow.PaidDate;
				vNewDocObj.Sum = ?(vPaymentRow.TotalPrice < 0, -vPaymentRow.TotalPrice, vPaymentRow.TotalPrice); 
				vNewDocObj.VATSum = cmCalculateVATSum(vNewDocObj.VATRate, vNewDocObj.Sum, vNewDocObj.Date);
				vNewDocObj.SumInFolioCurrency = Round(cmConvertCurrencies(vNewDocObj.Sum, vNewDocObj.PaymentCurrency, vNewDocObj.PaymentCurrencyExchangeRate, vNewDocObj.FolioCurrency, vNewDocObj.FolioCurrencyExchangeRate, vNewDocObj.ExchangeRateDate, vNewDocObj.Hotel), 2);
				vNewDocObj.VATSumInFolioCurrency = cmCalculateVATSum(vNewDocObj.VATRate, vNewDocObj.SumInFolioCurrency, vNewDocObj.Date);
				vNewDocObj.PaymentSections.Clear();
				vNewDocObj.StatisticsOnly = True;
				vNewDocObj.Write(DocumentWriteMode.Posting);
			EndDo;
				
			CommitTransaction();
		Except
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;   
			vErrorInfo = ErrorInfo();
			vMessage = NStr("en = 'Failed to load statistics on services provided and paid for! '; de = 'Statistiken zu bereitgestellten und bezahlten Diensten konnten nicht geladen werden! '; ru = 'Не удалось загрузить статистику по оказанным и оплаченным услугам! '");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, "LoadStatisticsRenderedAndPaidServices", Enums.ExternalSystemEventTypes.Error, "", "", vMessage + BriefErrorDescription(vErrorInfo), InteractionParameters.MaxLogLenght);
		EndTry;	
	EndIf;
EndProcedure // LoadStatisticsRenderedAndPaidServices

// -----------------------------------------------------------------------------
Function GetServiceItemByName(pServiceItemName)
	vOrderItem = Catalogs.OrderItems.EmptyRef();
	
	If IsBlankString(pServiceItemName) Then
		Return vOrderItem; 
	EndIf;   
	
	vServiceItemNameArr = StrSplit(pServiceItemName, "\", False);
	
	vServiceItemNameCount = vServiceItemNameArr.Count(); 
	If vServiceItemNameCount = 0 Then
		Return vOrderItem;	
	EndIf; 
	
	For i = 0 To vServiceItemNameCount - 1 Do
		vServiceItemNameArr[i] = TrimAll(StrReplace(vServiceItemNameArr[i], """", ""));	
	EndDo;
	
	vQ = New Query;
	vQ.Text = 
	"SELECT
	|	OrderItems.Ref AS Ref,
	|	OrderItems.Parent AS Parent,
	|	OrderItems.IsFolder AS IsFolder,
	|	OrderItems.Description AS Description
	|FROM
	|	Catalog.OrderItems AS OrderItems
	|WHERE
	|	NOT OrderItems.DeletionMark
	|	AND OrderItems.Description IN (&qServiceItemNames)";
	vQ.SetParameter("qServiceItemNames", vServiceItemNameArr);
	vOrderItems = vQ.Execute().Unload();
	
	vOrderItemsArr = vOrderItems.FindRows(New Structure("Description, IsFolder",  vServiceItemNameArr[vServiceItemNameCount - 1], False));
	vCurParent = Undefined;
	For Each vOrderItemRow In vOrderItemsArr Do 
		vCurParent = vOrderItemRow.Parent; 
		For i = 1 To vServiceItemNameCount Do
			If Not ValueIsFilled(vCurParent) And vServiceItemNameCount = i Then 
				vOrderItem = vOrderItemRow.Ref;
				Break; 
			ElsIf ValueIsFilled(vCurParent) And vServiceItemNameCount = i Then
				Break;
			ElsIf vServiceItemNameArr[vServiceItemNameCount - (i + 1)] = TrimAll(vCurParent.Description) Then
				vCurParent = vCurParent.Parent;
			Else
				Break;	
			EndIf;	
		EndDo;
		If ValueIsFilled(vOrderItem) Then
			Break;	
		EndIf;
	EndDo;
	
	If Not ValueIsFilled(vOrderItem) Then
		vNotFindParent = False;
		vCurParent = Catalogs.OrderItems.EmptyRef();
		For i = 0 To vServiceItemNameCount - 2 Do
			If Not vNotFindParent Then
				vOrderItemsArr = vOrderItems.FindRows(New Structure("Description, Parent, IsFolder",  vServiceItemNameArr[i], vCurParent, True));
				
				If vOrderItemsArr.Count() > 0 Then
					vCurParent = vOrderItemsArr[0].Ref;
					Continue;
				EndIf;
			EndIf;
			
			vNotFindParent = True;
			
			vNewOrderItem = Catalogs.OrderItems.CreateFolder();
			vNewOrderItem.Description = TrimAll(vServiceItemNameArr[i]);
			vNewOrderItem.Parent = vCurParent;
			vNewOrderItem.Write();
			vCurParent = vNewOrderItem.Ref;
		EndDo;
		
		vOrderItemsArr = vOrderItems.FindRows(New Structure("Description, Parent, IsFolder", vServiceItemNameArr[vServiceItemNameCount - 1], vCurParent, False));
		If vOrderItemsArr.Count() > 0 Then
			vOrderItem = vOrderItemsArr[0].Ref;	
		Else
			vNewOrderItem = Catalogs.OrderItems.CreateItem();
			vNewOrderItem.Description = TrimAll(vServiceItemNameArr[vServiceItemNameCount - 1]);
			vNewOrderItem.Parent = vCurParent;
			vNewOrderItem.Write();
			vOrderItem = vNewOrderItem.Ref;
		EndIf;
	EndIf;
		
	Return vOrderItem;
EndFunction // GetServiceItemByName

// -----------------------------------------------------------------------------
Function GetServiceByName(pServiceName)
	vService = Catalogs.Services.EmptyRef();
	
	If IsBlankString(pServiceName) Then
		Return vService; 
	EndIf;   
	
	vServiceNameArr = StrSplit(pServiceName, "\", False);
	
	vServiceNameCount = vServiceNameArr.Count(); 
	If vServiceNameCount = 0 Then
		Return vService;	
	EndIf; 
	
	For i = 0 To vServiceNameCount - 1 Do
		vServiceNameArr[i] = TrimAll(StrReplace(vServiceNameArr[i], """", ""));	
	EndDo;
	
	vQ = New Query;
	vQ.Text = 
	"SELECT
	|	Services.Ref AS Ref,
	|	Services.Parent AS Parent,
	|	Services.IsFolder AS IsFolder,
	|	Services.Description AS Description
	|FROM
	|	Catalog.Services AS Services
	|WHERE
	|	NOT Services.DeletionMark
	|	AND Services.Description IN(&qServiceItemNames)";
	vQ.SetParameter("qServiceItemNames", vServiceNameArr);
	vOrderItems = vQ.Execute().Unload();
	
	vOrderItemsArr = vOrderItems.FindRows(New Structure("Description, IsFolder",  vServiceNameArr[vServiceNameCount - 1], False));
	vCurParent = Undefined;
	For Each vOrderItemRow In vOrderItemsArr Do 
		vCurParent = vOrderItemRow.Parent; 
		For i = 1 To vServiceNameCount Do
			If vCurParent = MedicalServicesFolder And vServiceNameCount = i Then 
				vService = vOrderItemRow.Ref;
				Break; 
			ElsIf ValueIsFilled(vCurParent) And vCurParent <> MedicalServicesFolder And vServiceNameCount = i Then
				Break;   
			ElsIf Not ValueIsFilled(vCurParent) And ValueIsFilled(MedicalServicesFolder) Then 
				Break;
			ElsIf vServiceNameArr[vServiceNameCount - (i + 1)] = TrimAll(vCurParent.Description) Then
				vCurParent = vCurParent.Parent;
			Else
				Break;	
			EndIf;	
		EndDo;
		If ValueIsFilled(vService) Then
			Break;	
		EndIf;
	EndDo;
	
	If Not ValueIsFilled(vService) Then
		vNotFindParent = False;
		vCurParent = MedicalServicesFolder;
		For i = 0 To vServiceNameCount - 2 Do
			If Not vNotFindParent Then
				vServiceItemsArr = vOrderItems.FindRows(New Structure("Description, Parent, IsFolder",  vServiceNameArr[i], vCurParent, True));
				
				If vServiceItemsArr.Count() > 0 Then
					vCurParent = vServiceItemsArr[0].Ref;
					Continue;
				EndIf;
			EndIf;
			
			vNotFindParent = True;
			
			vNewServiceItem = Catalogs.Services.CreateFolder();
			vNewServiceItem.SetNewCode();
			vNewServiceItem.Description = TrimAll(vServiceNameArr[i]);
			vNewServiceItem.Parent = vCurParent;
			vNewServiceItem.Write();
			vCurParent = vNewServiceItem.Ref;
		EndDo;
		
		vServiceItemsArr = vOrderItems.FindRows(New Structure("Description, Parent, IsFolder", vServiceNameArr[vServiceNameCount - 1], vCurParent, False));
		If vServiceItemsArr.Count() > 0 Then
			vService = vServiceItemsArr[0].Ref;	
		Else
			vNewServiceItem = Catalogs.Services.CreateItem();
			vNewServiceItem.SetNewCode();
			vNewServiceItem.Description = TrimAll(vServiceNameArr[vServiceNameCount - 1]);
			vNewServiceItem.Parent = vCurParent;
			vNewServiceItem.Write();
			vService = vNewServiceItem.Ref;
		EndIf;
	EndIf;
		
	Return vService;
EndFunction // GetServiceByName

// -----------------------------------------------------------------------------
Function GetOrderStatus(pOrderType)
	// get order status from order type
	vOrderTypeObj = pOrderType.GetObject();
	If vOrderTypeObj.StatusesCourse.Count() > 0 Then
		// use the first in line
		Return vOrderTypeObj.StatusesCourse[0].Status;
	EndIf;	
	Return Catalogs.OrderStatuses.Complete;
EndFunction // GetOrderStatus

#EndRegion

#Region Order

// -----------------------------------------------------------------------------
Procedure ChangeOrderStatus()
	vQ = New Query;
	vQ.Text = 
	"SELECT
	|	SUM(DocumentPayment.Sum) AS Sum,
	|	DocumentPayment.Order AS OrderRef
	|INTO PaymentAndReturn
	|FROM
	|	(SELECT
	|		PaymentList.Sum AS Sum,
	|		PaymentList.Order AS Order
	|	FROM
	|		Document.Payment AS PaymentList
	|	WHERE
	|		PaymentList.Posted
	|		AND PaymentList.Hotel = &qHotel
	|		AND NOT PaymentList.Folio.IsClosed
	|		AND PaymentList.Order <> VALUE(Document.Order.EmptyRef)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		-ReturnList.Sum,
	|		ReturnList.Order
	|	FROM
	|		Document.Return AS ReturnList
	|	WHERE
	|		ReturnList.Posted
	|		AND ReturnList.Hotel = &qHotel
	|		AND NOT ReturnList.Folio.IsClosed
	|		AND ReturnList.Order <> VALUE(Document.Order.EmptyRef)) AS DocumentPayment
	|
	|GROUP BY
	|	DocumentPayment.Order
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Order.Ref AS OrderRef,
	|	ISNULL(PaymentAndReturn.Sum, 0) AS Sum,
	|	Order.Type AS Type,
	|	Order.Status AS Status
	|FROM
	|	Document.Order AS Order
	|		INNER JOIN PaymentAndReturn AS PaymentAndReturn
	|		ON Order.Ref = PaymentAndReturn.OrderRef
	|WHERE
	|	NOT Order.DeletionMark
	|	AND Order.Posted
	|	AND Order.Type = &qType
	|	AND NOT Order.Status.isOrderCancel
	|	AND CASE
	|			WHEN ISNULL(PaymentAndReturn.Sum, 0) > 0
	|					AND NOT Order.Status.IsPaid
	|				THEN TRUE
	|			WHEN ISNULL(PaymentAndReturn.Sum, 0) > 0
	|					AND Order.Status.IsPaid
	|					AND NOT Order.Status.isOrderComplete
	|				THEN TRUE
	|			WHEN ISNULL(PaymentAndReturn.Sum, 0) = 0
	|					AND Order.Status.IsPaid
	|				THEN TRUE
	|			ELSE FALSE
	|		END";
	vQ.SetParameter("qHotel", InteractionParameters.Hotel);
	vQ.SetParameter("qType", InteractionParameters.OrderType);
	vOrders = vQ.Execute().Unload();
	For Each vOrder In vOrders Do
		vStatus = vOrder.Status;
		vNewStatus = vOrder.Status;
		vStatusesCourse = vOrder.Type.StatusesCourse;
		vStatusesCourseCount = vStatusesCourse.Count() - 1;
		vExternalCode = "";
		If vOrder.Sum > 0 And Not vStatus.IsPaid Then
			vStatusExists = False;
			For i = 0 To vStatusesCourseCount Do
				If vStatusesCourse[i].Status = vStatus Then
					vStatusExists = True;
					For j = i To vStatusesCourseCount Do
						If vStatusesCourse[j].Status.IsPaid Then
							vNewStatus = vStatusesCourse[j].Status;	
							Break;	
						EndIf;
					EndDo;
					Break;
				EndIf;
			EndDo;
			If vStatus = vNewStatus And Not vStatusExists Then
				For i = 0 To vStatusesCourseCount Do
					If vStatusesCourse[vStatusesCourseCount - i].Status.IsPaid Then
						vNewStatus = vStatusesCourse[vStatusesCourseCount - i].Status; 	
						Break;
					EndIf;
				EndDo;
			EndIf;
			SendCreateInvoice(vOrder.OrderRef, vNewStatus, vExternalCode);
		ElsIf vOrder.Sum > 0 And vStatus.IsPaid And Not vStatus.isOrderComplete Then
			SendCreateInvoice(vOrder.OrderRef, vNewStatus, vExternalCode);	
		Else       
			SendCancelInvoice(vOrder.OrderRef, vNewStatus);
		EndIf;
		If vStatus <> vNewStatus Then
			vOrderObj = vOrder.OrderRef.GetObject();
			vOrderObj.Status = vNewStatus;
			If Not IsBlankString(vExternalCode) Then
				vOrderObj.ExternalCode = vExternalCode;	
			Endif;
			vOrderObj.Write(DocumentWriteMode.Posting);
		EndIf;	
	EndDo; 
EndProcedure // ChangeOrderStatus

// -----------------------------------------------------------------------------
Procedure SendCreateInvoice(pOrder, rNewStatus, rExternalCode)
	vCreateInvoiceMap = New Map;
	
	vExternalId = "";
	vParentDoc = pOrder.ParentDoc;
	If ValueIsFilled(vParentDoc) Then
		vExternalId = TrimAll(vParentDoc.Number) + "/";
	EndIf;
	vExternalId = vExternalId + TrimAll(pOrder.Client.Code);
	vCreateInvoiceMap.Insert("medicalRecordExternalId", vExternalId);
	
	vItems = New Array;
	For Each vRow In pOrder.Items Do
		vItem = JSONToMap(vRow.ItemInfo);
		vItem["quantity"] = vRow.Quantity;
		vItem["pricePerOne"] = vRow.Price;
		vItem["totalPrice"] = vRow.Sum;
		vItems.Add(vItem);
	EndDo;
	vCreateInvoiceMap.Insert("items", vItems);
	
	vPayments = New Array;
	vPaymentsList = GetPaymentByOrder(pOrder);
	For Each vRow In vPaymentsList Do
		vPayment = New Map;
		vPayment.Insert("invoicePaymentId", TrimAll(vRow.invoicePaymentId));   		
		vPayment.Insert("paymentInstrumentCode", cmGetObjectExternalSystemCodeByRef(InteractionParameters.Hotel, InteractionParameters.InteractionID, "PaymentMethods", vRow.PaymentMethod,, True));
		vPayment.Insert("name", TrimAll(vRow.name));
		vPayment.Insert("paymentAmount", vRow.paymentAmount);
		vPayments.Add(vPayment);
	EndDo;
	vCreateInvoiceMap.Insert("payments", vPayments);
	
	vResponse = DataProcessors.Sanatorium.SendQueryToWebService(InteractionParameters, "POST", MapToJSON(vCreateInvoiceMap), "Accounting/CreateInvoice/");
	If TypeOf(vResponse) = Type("Map") Then
		rExternalCode = vResponse["invoiceUid"]; 
		vStatus = pOrder.Status;
		vStatusesCourse = pOrder.Type.StatusesCourse;
		vStatusesCourseCount = vStatusesCourse.Count() - 1;
		vStatusExists = False;
		For i = 0 To vStatusesCourseCount Do
			If vStatusesCourse[i].Status = vStatus Then
				vStatusExists = True;
				For j = i To vStatusesCourseCount Do
					If vStatusesCourse[j].Status.isOrderComplete Then
						rNewStatus = vStatusesCourse[j].Status;	
						Break;	
					EndIf;
				EndDo;
				Break;
			EndIf;
		EndDo;
		If vStatus = rNewStatus And Not vStatusExists Then
			For i = 0 To vStatusesCourseCount Do
				If vStatusesCourse[vStatusesCourseCount - i].Status.isOrderComplete Then
					rNewStatus = vStatusesCourse[vStatusesCourseCount - i].Status; 	
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
EndProcedure // SendCreateInvoice

// -----------------------------------------------------------------------------
Function GetPaymentByOrder(pOrder)
	vQ = New Query;
	vQ.Text =
	"SELECT
	|	PaymentList.Number AS invoicePaymentId,
	|	PaymentList.Sum AS paymentAmount,
	|	PaymentList.PaymentMethod AS PaymentMethod,
	|	PaymentList.PaymentMethod.Description AS name
	|FROM
	|	Document.Payment AS PaymentList
	|		LEFT JOIN Document.Return AS Return
	|		ON PaymentList.Ref = Return.Payment
	|			AND (NOT Return.DeletionMark)
	|			AND (Return.Posted)
	|WHERE
	|	PaymentList.Posted
	|	AND (CAST(PaymentList.OrderNumber AS STRING(100))) = &qOrderNumber
	|	AND Return.Number IS NULL
	|	AND PaymentList.Hotel = &qHotel";
	vQ.SetParameter("qOrderNumber", TrimAll(pOrder.Number));
	vQ.SetParameter("qHotel", InteractionParameters.Hotel);
	Return vQ.Execute().Unload();
EndFunction // GetPaymentByOrder

// -----------------------------------------------------------------------------
Procedure SendCancelInvoice(pOrder, rNewStatus)
	vCancelInvoiceMap = New Map;
	vCancelInvoiceMap.Insert("invoiceGuid", pOrder.ExternalCode);
		
	vRefundPayment = New Map;
	vReturnsList = GetReturnByOrder(pOrder);
	If vReturnsList.Count() > 0 Then
		vRow = vReturnsList[0]; 
		vRefundPayment.Insert("invoicePaymentId", TrimAll(vRow.invoicePaymentId));  
		vRefundPayment.Insert("paymentInstrumentCode", cmGetObjectExternalSystemCodeByRef(InteractionParameters.Hotel, InteractionParameters.InteractionID, "PaymentMethods", vRow.PaymentMethod,, True));
		vRefundPayment.Insert("name", TrimAll(vRow.name));
		vRefundPayment.Insert("paymentAmount", -vRow.paymentAmount);
	EndIf;
	vCancelInvoiceMap.Insert("refundPayment", vRefundPayment);
	
	vResponse = DataProcessors.Sanatorium.SendQueryToWebService(InteractionParameters, "POST", MapToJSON(vCancelInvoiceMap), "Accounting/CancelInvoice/");
	If TypeOf(vResponse) = Type("Map") Then 
		rNewStatus = Catalogs.OrderStatuses.Cancel;
		If ValueIsFilled(pOrder.Charge) Then
			vChargeObject = pOrder.Charge.GetObject();
			vChargeObject.SetDeletionMark(True);
		EndIf;
	EndIf;
EndProcedure // SendCancelInvoice

// -----------------------------------------------------------------------------
Function GetReturnByOrder(pOrder)
	vQ = New Query;
	vQ.Text =
	"SELECT TOP 1
	|	Return.Number AS invoicePaymentId,
	|	Return.Sum AS paymentAmount,
	|	Return.PaymentMethod.Description AS name,
	|	Return.PaymentMethod AS PaymentMethod
	|FROM
	|	Document.Payment AS PaymentList
	|		LEFT JOIN Document.Return AS Return
	|		ON PaymentList.Ref = Return.Payment
	|			AND (Return.Posted)
	|WHERE
	|	PaymentList.Posted
	|	AND (CAST(PaymentList.OrderNumber AS STRING(100))) = &qOrderNumber
	|	AND Return.Number IS NOT NULL 
	|	AND PaymentList.Hotel = &qHotel
	|
	|ORDER BY
	|	Return.Date DESC";
	vQ.SetParameter("qOrderNumber", TrimAll(pOrder.Number));
	vQ.SetParameter("qHotel", InteractionParameters.Hotel);
	Return vQ.Execute().Unload();
EndFunction // GetReturnByOrder

// -----------------------------------------------------------------------------
Function GetOrderItem(pItem)
	// Find by decription
	vQ = New Query;
	vQ.Text = 
	"SELECT
	|	OrderItems.Ref AS Ref
	|FROM
	|	Catalog.OrderItems AS OrderItems
	|WHERE
	|	NOT OrderItems.IsFolder
	|	AND OrderItems.Description = &qDescription
	|	AND (OrderItems.Hotel = &qHotel
	|			OR OrderItems.Hotel = &qEmptyHotel)";
	vQ.SetParameter("qDescription", TrimAll(pItem));
	vQ.SetParameter("qHotel", InteractionParameters.Hotel);
	vQ.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());

	qRes = vQ.Execute().Select();
	If qRes.Next() Then
		Return qRes.Ref;
	EndIf;
	
	// Not found - create a new one
	vItem = Catalogs.OrderItems.CreateItem();
	vItem.SetNewCode();
	vItem.Description = TrimAll(pItem);
	vItem.Hotel = InteractionParameters.Hotel;
	vItem.Write();
	Return vItem.Ref;
EndFunction // GetOrderItem

#EndRegion

#Region Invoice

#EndRegion

#Region ReservationMessages

// -----------------------------------------------------------------------------
Procedure SendReservationMessages(pParameter = Undefined, pIsInteractive = False)
	Try      
		vPeriodFrom = InteractionParameters.LastFullSynchronizationTime;
		vPeriodTo = Undefined;
		vReservationsList = Undefined;
		vUnloadType = 0;
		
		If pIsInteractive And pParameter <> Undefined Then
			vPeriodFrom = pParameter.PeriodFrom; 
			vPeriodTo = pParameter.PeriodTo;
	      	vUnloadType = pParameter.UnloadType;
			vReservationsList = pParameter.ReservationsList;
		EndIf;
		
		vDataReservations = GetChangedReservations(vUnloadType, vPeriodFrom, vPeriodTo, vReservationsList, InteractionParameters.Hotel);
		vCurDate = CurrentSessionDate();
		If vDataReservations.Count() > 0 Then 
			vReservationUpdatedMessageList = New Array; 
			vResult = False;
			For Each vDataReservation In vDataReservations Do
				vReservationUpdatedMessageList.Add(ReservationMessagesStructure(vDataReservation.Ref, vDataReservation.Number, 
												   vDataReservation.GuestGroup, vDataReservation.Period, vDataReservation.IsShared));
				
				If MaxNumberOfGuestsInMessage > 0 And vReservationUpdatedMessageList.Count() % MaxNumberOfGuestsInMessage = 0 Then
					vResult = DataProcessors.Sanatorium.SendQueryToBus(InteractionParameters, MapToJSON(vReservationUpdatedMessageList), "/ReservationMessages");
					vReservationUpdatedMessageList = New Array;
					If Not vResult Then
						Break;	
					EndIf	
				EndIf; 
			EndDo;  
			
			If vReservationUpdatedMessageList.Count() > 0 Then
				vResult = DataProcessors.Sanatorium.SendQueryToBus(InteractionParameters, MapToJSON(vReservationUpdatedMessageList), "/ReservationMessages");	
			EndIf;
											   
			If vResult And Not pIsInteractive Then
				vObj 								= InteractionParameters.GetObject();
				vObj.LastFullSynchronizationTime 	= vCurDate;
				vObj.Write(); 
			EndIf;
		EndIf;	
	Except
		vError = ErrorInfo();	
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, "SendReservationMessages", Enums.ExternalSystemEventTypes.Error, "", "", "Failed to send reservation messages! " + BriefErrorDescription(vError), InteractionParameters.MaxLogLenght);
	EndTry;
EndProcedure // SendReservationMessages

// -----------------------------------------------------------------------------
Function GetChangedReservations(pUnloadType, pPeriodFrom, pPeriodTo, pReservationsList, pHotel)
	vQuery = New Query();
	If pUnloadType = 0 Then
		vQuery.Text =   			
		"SELECT
		|	Statuses.Ref AS Ref
		|INTO Statuses
		|FROM
		|	(SELECT
		|		AccommodationStatuses.Ref AS Ref
		|	FROM
		|		Catalog.AccommodationStatuses AS AccommodationStatuses
		|	WHERE
		|		AccommodationStatuses.IsActive
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ReservationStatuses.Ref
		|	FROM
		|		Catalog.ReservationStatuses AS ReservationStatuses
		|	WHERE
		|		NOT ReservationStatuses.IsCheckIn) AS Statuses
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ReservationsList.Ref AS Ref,
		|	ReservationsList.Period AS Period,
		|	ReservationsList.Number AS Number,
		|	ReservationsList.GuestGroup AS GuestGroup
		|INTO ReservationsChangeList
		|FROM
		|	(SELECT
		|		AccommodationChangeHistorySliceLast.Accommodation AS Ref,
		|		AccommodationChangeHistorySliceLast.Period AS Period,
		|		AccommodationChangeHistorySliceLast.Number AS Number,
		|		AccommodationChangeHistorySliceLast.GuestGroup AS GuestGroup,
		|		AccommodationChangeHistorySliceLast.AccommodationStatus AS Status
		|	FROM
		|		InformationRegister.AccommodationChangeHistory.SliceLast(
		|				&qPeriodTo,
		|				Hotel = &qHotel
		|					AND Period >= &qPeriodFrom
		|					AND Accommodation.Guest <> VALUE(Catalog.Clients.EmptyRef)) AS AccommodationChangeHistorySliceLast
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ReservationChangeHistorySliceLast.Reservation,
		|		ReservationChangeHistorySliceLast.Period,
		|		ReservationChangeHistorySliceLast.Number,
		|		ReservationChangeHistorySliceLast.GuestGroup,
		|		ReservationChangeHistorySliceLast.ReservationStatus
		|	FROM
		|		InformationRegister.ReservationChangeHistory.SliceLast(
		|				&qPeriodTo,
		|				Hotel = &qHotel
		|					AND Period >= &qPeriodFrom
		|					AND Reservation.Guest <> VALUE(Catalog.Clients.EmptyRef)) AS ReservationChangeHistorySliceLast) AS ReservationsList
		|		INNER JOIN Statuses AS Statuses
		|		ON ReservationsList.Status = Statuses.Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP Statuses
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Statuses.Ref AS Ref
		|INTO StatusesActive
		|FROM
		|	(SELECT
		|		AccommodationStatuses.Ref AS Ref
		|	FROM
		|		Catalog.AccommodationStatuses AS AccommodationStatuses
		|	WHERE
		|		AccommodationStatuses.IsActive
		|		AND AccommodationStatuses.IsInHouse
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ReservationStatuses.Ref
		|	FROM
		|		Catalog.ReservationStatuses AS ReservationStatuses
		|	WHERE
		|		NOT ReservationStatuses.IsCheckIn
		|		AND ReservationStatuses.IsActive) AS Statuses
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ReservationsList.Ref AS Ref,
		|	ReservationsList.Number AS Number,
		|	ReservationsList.GuestGroup AS GuestGroup,
		|	ReservationsList.Guest AS Guest
		|INTO ReservationsActiveList
		|FROM
		|	(SELECT
		|		Accommodation.Ref AS Ref,
		|		Accommodation.Number AS Number,
		|		Accommodation.GuestGroup AS GuestGroup,
		|		Accommodation.AccommodationStatus AS Status,
		|		Accommodation.Guest AS Guest
		|	FROM
		|		Document.Accommodation AS Accommodation
		|	WHERE
		|		Accommodation.Hotel = &qHotel
		|				AND Accommodation.Guest <> VALUE(Catalog.Clients.EmptyRef)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Reservation.Ref,
		|		Reservation.Number,
		|		Reservation.GuestGroup,
		|		Reservation.ReservationStatus,
		|		Reservation.Guest
		|	FROM
		|		Document.Reservation AS Reservation
		|	WHERE
		|		Reservation.Hotel = &qHotel
		|				AND Reservation.Guest <> VALUE(Catalog.Clients.EmptyRef)) AS ReservationsList
		|		INNER JOIN StatusesActive AS StatusesActive
		|		ON ReservationsList.Status = StatusesActive.Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP StatusesActive
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ReservationsActiveList.Ref AS Ref,
		|	ReservationsActiveList.Number AS Number,
		|	ReservationsActiveList.GuestGroup AS GuestGroup,
		|	ClientChangeHistorySliceLast.Period AS Period
		|INTO ReservationsActiveByClientsList
		|FROM
		|	ReservationsActiveList AS ReservationsActiveList
		|		INNER JOIN InformationRegister.ClientChangeHistory.SliceLast(&qPeriodTo, Period >= &qPeriodFrom) AS ClientChangeHistorySliceLast
		|		ON ReservationsActiveList.Guest = ClientChangeHistorySliceLast.Client
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ReservationsList.Ref AS Ref,
		|	MAX(ReservationsList.Period) AS Period,
		|	ReservationsList.Number AS Number,
		|	ReservationsList.GuestGroup AS GuestGroup
		|INTO ReservationsList
		|FROM
		|	(SELECT
		|		ReservationsChangeList.Ref AS Ref,
		|		ReservationsChangeList.Period AS Period,
		|		ReservationsChangeList.Number AS Number,
		|		ReservationsChangeList.GuestGroup AS GuestGroup
		|	FROM
		|		ReservationsChangeList AS ReservationsChangeList
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ReservationsActiveByClientsList.Ref,
		|		ReservationsActiveByClientsList.Period,
		|		ReservationsActiveByClientsList.Number,
		|		ReservationsActiveByClientsList.GuestGroup
		|	FROM
		|		ReservationsActiveByClientsList AS ReservationsActiveByClientsList) AS ReservationsList
		|
		|GROUP BY
		|	ReservationsList.Ref,
		|	ReservationsList.Number,
		|	ReservationsList.GuestGroup
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP ReservationsChangeList
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP ReservationsActiveByClientsList
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ReservationsActiveList.Number AS Number,
		|	ReservationsActiveList.GuestGroup AS GuestGroup,
		|	SUM(1) AS IsShared
		|INTO AllReservationsList
		|FROM
		|	ReservationsActiveList AS ReservationsActiveList
		|		INNER JOIN ReservationsList AS ReservationsList
		|		ON ReservationsActiveList.Number = ReservationsList.Number
		|			AND ReservationsActiveList.GuestGroup = ReservationsList.GuestGroup
		|
		|GROUP BY
		|	ReservationsActiveList.Number,
		|	ReservationsActiveList.GuestGroup
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP ReservationsActiveList
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ReservationsList.Ref AS Ref,
		|	ReservationsList.Period AS Period,
		|	ReservationsList.Number AS Number,
		|	ReservationsList.GuestGroup AS GuestGroup,
		|	CASE
		|		WHEN ISNULL(AllReservationsList.IsShared, 0) > 1
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS IsShared
		|FROM
		|	ReservationsList AS ReservationsList
		|		LEFT JOIN AllReservationsList AS AllReservationsList
		|		ON ReservationsList.Number = AllReservationsList.Number
		|			AND ReservationsList.GuestGroup = AllReservationsList.GuestGroup";
		
		vQuery.SetParameter("qPeriodFrom", pPeriodFrom);
		vQuery.SetParameter("qPeriodTo", pPeriodTo);
		vQuery.SetParameter("qHotel", pHotel);
	ElsIf pUnloadType = 1 Then
		vQuery.Text =   
		"SELECT
		|	Statuses.Ref AS Ref
		|INTO Statuses
		|FROM
		|	(SELECT
		|		AccommodationStatuses.Ref AS Ref
		|	FROM
		|		Catalog.AccommodationStatuses AS AccommodationStatuses
		|	WHERE
		|		AccommodationStatuses.IsActive
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ReservationStatuses.Ref
		|	FROM
		|		Catalog.ReservationStatuses AS ReservationStatuses
		|	WHERE
		|		NOT ReservationStatuses.IsCheckIn) AS Statuses
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ReservationsList.Ref AS Ref,
		|	ReservationsList.Period AS Period,
		|	ReservationsList.Number AS Number,
		|	ReservationsList.GuestGroup AS GuestGroup
		|INTO ReservationsList
		|FROM
		|	(SELECT
		|		Accommodation.Ref AS Ref,
		|		UNDEFINED AS Period,
		|		Accommodation.Number AS Number,
		|		Accommodation.GuestGroup AS GuestGroup,
		|		Accommodation.AccommodationStatus AS Status
		|	FROM
		|		Document.Accommodation AS Accommodation
		|	WHERE
		|		Accommodation.Hotel = &qHotel
		|		AND NOT Accommodation.DeletionMark
		|		AND Accommodation.Posted
		|		AND Accommodation.CheckOutDate > &qPeriodFrom
		|		AND CASE
		|				WHEN &qPeriodTo <> DATETIME(1, 1, 1, 0, 0, 0)
		|					THEN Accommodation.CheckInDate < &qPeriodTo
		|				ELSE TRUE
		|			END
		|		AND Accommodation.AccommodationStatus.IsActive
		|		AND Accommodation.Guest <> VALUE(Catalog.Clients.EmptyRef)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Reservation.Ref,
		|		UNDEFINED,
		|		Reservation.Number,
		|		Reservation.GuestGroup,
		|		Reservation.ReservationStatus
		|	FROM
		|		Document.Reservation AS Reservation
		|	WHERE
		|		Reservation.Hotel = &qHotel
		|		AND NOT Reservation.DeletionMark
		|		AND Reservation.Posted
		|		AND Reservation.CheckOutDate > &qPeriodFrom
		|		AND CASE
		|				WHEN &qPeriodTo <> DATETIME(1, 1, 1, 0, 0, 0)
		|					THEN Reservation.CheckInDate < &qPeriodTo
		|				ELSE TRUE
		|			END
		|		AND NOT Reservation.ReservationStatus.IsCheckIn
		|		AND Reservation.Guest <> VALUE(Catalog.Clients.EmptyRef)) AS ReservationsList
		|		INNER JOIN Statuses AS Statuses
		|		ON ReservationsList.Status = Statuses.Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AllReservation.Number AS Number,
		|	AllReservation.GuestGroup AS GuestGroup,
		|	SUM(AllReservation.IsShared) AS IsShared
		|INTO AllReservationsList
		|FROM
		|	(SELECT
		|		Accommodation.Number AS Number,
		|		Accommodation.GuestGroup AS GuestGroup,
		|		1 AS IsShared
		|	FROM
		|		Document.Accommodation AS Accommodation
		|	WHERE
		|		Accommodation.Hotel = &qHotel
		|		AND Accommodation.Posted
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Reservation.Number,
		|		Reservation.GuestGroup,
		|		1
		|	FROM
		|		Document.Reservation AS Reservation
		|	WHERE
		|		Reservation.Hotel = &qHotel
		|		AND Reservation.Posted) AS AllReservation
		|		INNER JOIN ReservationsList AS ReservationsList
		|		ON AllReservation.Number = ReservationsList.Number
		|			AND AllReservation.GuestGroup = ReservationsList.GuestGroup
		|
		|GROUP BY
		|	AllReservation.Number,
		|	AllReservation.GuestGroup
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CASE
		|		WHEN ISNULL(AllReservationsList.IsShared, 1) > 1
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS IsShared,
		|	ReservationsList.Ref AS Ref,
		|	ReservationsList.Period AS Period,
		|	ReservationsList.Number AS Number,
		|	ReservationsList.GuestGroup AS GuestGroup
		|FROM
		|	ReservationsList AS ReservationsList
		|		LEFT JOIN AllReservationsList AS AllReservationsList
		|		ON ReservationsList.Number = AllReservationsList.Number
		|			AND ReservationsList.GuestGroup = AllReservationsList.GuestGroup";
		vQuery.SetParameter("qPeriodFrom", pPeriodFrom);
		vQuery.SetParameter("qPeriodTo", pPeriodTo);
		vQuery.SetParameter("qHotel", pHotel);	
	Else
		vQuery.Text =   
		"SELECT
		|	Statuses.Ref AS Ref
		|INTO Statuses
		|FROM
		|	(SELECT
		|		AccommodationStatuses.Ref AS Ref
		|	FROM
		|		Catalog.AccommodationStatuses AS AccommodationStatuses
		|	WHERE
		|		AccommodationStatuses.IsActive
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ReservationStatuses.Ref
		|	FROM
		|		Catalog.ReservationStatuses AS ReservationStatuses
		|	WHERE
		|		NOT ReservationStatuses.IsCheckIn) AS Statuses
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ReservationsList.Ref AS Ref,
		|	ReservationsList.Period AS Period,
		|	ReservationsList.Number AS Number,
		|	ReservationsList.GuestGroup AS GuestGroup
		|INTO ReservationsList
		|FROM
		|	(SELECT
		|		Accommodation.Ref AS Ref,
		|		UNDEFINED AS Period,
		|		Accommodation.Number AS Number,
		|		Accommodation.GuestGroup AS GuestGroup,
		|		Accommodation.AccommodationStatus AS Status
		|	FROM
		|		Document.Accommodation AS Accommodation
		|	WHERE
		|		Accommodation.Hotel = &qHotel
		|		AND Accommodation.Ref IN(&qReservationsList)
		|		AND Accommodation.Guest <> VALUE(Catalog.Clients.EmptyRef)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Reservation.Ref,
		|		UNDEFINED,
		|		Reservation.Number,
		|		Reservation.GuestGroup,
		|		Reservation.ReservationStatus
		|	FROM
		|		Document.Reservation AS Reservation
		|	WHERE
		|		Reservation.Hotel = &qHotel
		|		AND Reservation.Ref IN(&qReservationsList)
		|		AND Reservation.Guest <> VALUE(Catalog.Clients.EmptyRef)) AS ReservationsList
		|		INNER JOIN Statuses AS Statuses
		|		ON ReservationsList.Status = Statuses.Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AllReservation.Number AS Number,
		|	AllReservation.GuestGroup AS GuestGroup,
		|	SUM(AllReservation.IsShared) AS IsShared
		|INTO AllReservationsList
		|FROM
		|	(SELECT
		|		Accommodation.Number AS Number,
		|		Accommodation.GuestGroup AS GuestGroup,
		|		1 AS IsShared
		|	FROM
		|		Document.Accommodation AS Accommodation
		|	WHERE
		|		Accommodation.Hotel = &qHotel
		|		AND Accommodation.Posted
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Reservation.Number,
		|		Reservation.GuestGroup,
		|		1
		|	FROM
		|		Document.Reservation AS Reservation
		|	WHERE
		|		Reservation.Hotel = &qHotel
		|		AND Reservation.Posted) AS AllReservation
		|		INNER JOIN ReservationsList AS ReservationsList
		|		ON AllReservation.Number = ReservationsList.Number
		|			AND AllReservation.GuestGroup = ReservationsList.GuestGroup
		|
		|GROUP BY
		|	AllReservation.Number,
		|	AllReservation.GuestGroup
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CASE
		|		WHEN ISNULL(AllReservationsList.IsShared, 1) > 1
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS IsShared,
		|	ReservationsList.Ref AS Ref,
		|	ReservationsList.Period AS Period,
		|	ReservationsList.Number AS Number,
		|	ReservationsList.GuestGroup AS GuestGroup
		|FROM
		|	ReservationsList AS ReservationsList
		|		LEFT JOIN AllReservationsList AS AllReservationsList
		|		ON ReservationsList.Number = AllReservationsList.Number
		|			AND ReservationsList.GuestGroup = AllReservationsList.GuestGroup";
		
		vQuery.SetParameter("qReservationsList", pReservationsList);
		vQuery.SetParameter("qHotel", pHotel);	
	EndIf;
	Return vQuery.Execute().Unload();	
EndFunction // GetChangedReservations

// -----------------------------------------------------------------------------
Function ReservationMessagesStructure(pDocument, pNumber, pGuestGroup, pPeriod, pIsShared) 
	vReservationMessage = New Map; 
	vReservationMessage.Insert("PublishDate", CurrentSessionDate()); 
	vReservationMessage.Insert("Id", TrimAll(pNumber) + "/" + TrimAll(pDocument.Guest.Code));
	vReservationMessage.Insert("SharedBookingId", Format(pGuestGroup.Code, "NFD=0; NZ=0; NG="));
	If TypeOf(pDocument) = Type("DocumentRef.Reservation") Then
		vReservationMessage.Insert("ArrivalDate", pDocument.CheckInDate);
		vReservationMessage.Insert("DepartureDate", pDocument.CheckOutDate);
		vReservationMessage.Insert("Status", GetExternalCodeFromRef("ReservationStatuses", pDocument.ReservationStatus, True));     
	Else                       
		vReservation = pDocument.Reservation; 
		If ValueIsFilled(vReservation) Then
			vReservationMessage.Insert("ArrivalDate", vReservation.CheckInDate);
			vReservationMessage.Insert("DepartureDate", vReservation.CheckOutDate);	
		Else
			vReservationMessage.Insert("ArrivalDate", pDocument.CheckInDate);
			vReservationMessage.Insert("DepartureDate", pDocument.CheckOutDate);	
		EndIf;
		
		vReservationMessage.Insert("ActualArrivalDate", pDocument.CheckInDate);
		vReservationMessage.Insert("FactArrivalDateTime", pDocument.CheckInDate);
		
		vReservationMessage.Insert("Irrevocable", False);
		vStatus = pDocument.AccommodationStatus;
		If vStatus.IsCheckOut And Not vStatus.IsInHouse Then
			vReservationMessage.Insert("ActualDepartureDate", pDocument.CheckOutDate);
			vReservationMessage.Insert("FactDepartureDateTime", pDocument.CheckOutDate);
			vReservationMessage.Insert("Irrevocable", True);
		EndIf;   
		vReservationMessage.Insert("Status", GetExternalCodeFromRef("AccommodationStatuses", pDocument.AccommodationStatus, True));
	EndIf;
	vReservationMessage.Insert("CreatedDate", pDocument.Date);
	vReservationMessage.Insert("GenericNo", TrimAll(pNumber) + "/" + TrimAll(pDocument.Guest.Code));
	vReservationMessage.Insert("Guid", String(pDocument.UUID()));
	vReservationMessage.Insert("IsShared", pIsShared);
	
	vMainGuest = Undefined;
	vReservationMessage.Insert("ReservationGuests", GetReservationGuestsStructure(pNumber, pDocument.Guest, pDocument.HotelProduct, pDocument.NoPost, vMainGuest));
	vReservationMessage.Insert("MainGuest", vMainGuest);
	
	If pPeriod <> Undefined Then
		vReservationMessage.Insert("ModifiedDate", pPeriod);
	Else
		vReservationMessage.Insert("ModifiedDate", CurrentSessionDate());	
	EndIf;
	vReservationMessage.Insert("Property", GetPropertyStructure(InteractionParameters.Hotel));
	
	vCurrentTimeline = Undefined;
	vReservationMessage.Insert("Timelines", GetTimelineStructure(pDocument, vCurrentTimeline));
	vReservationMessage.Insert("CurrentTimeline", vCurrentTimeline);
	
	vReservationMessage.Insert("Folio", GetFolioStructure(pDocument, pNumber));
	 
	If ValueIsFilled(pDocument.Author) Then 
		vReservationMessage.Insert("CreatedUser", pDocument.Author.GetObject().pmGetEmployeeDescription(SessionParameters.CurrentLanguage));
	EndIf;
	
	Return vReservationMessage;	
EndFunction // ReservationMessagesStructure

// ----------------------------------------------------------------------------
Function GetFolioStructure(pDocument, pNumber)
	vAmount = 0;
	vPaymentsAmount = 0;
	vStayAmount = 0;
	vBalanceForecast = 0;
	vFolio = New Map;
	vFolio.Insert("GenericNo", TrimAll(pNumber));
	vFolioList = GetFolioList(pDocument);
	vPockets = New Array;
	For Each vFolioRow In vFolioList Do	
        vPockets.Add(GetPocket(vFolioRow.Folio, vAmount, vPaymentsAmount, vStayAmount, vBalanceForecast)); 
	EndDo; 
	vFolio.Insert("Pockets", vPockets);
	vFolio.Insert("BalanceDetails", GetFolioPocketInfoStructure(vAmount, vPaymentsAmount, vStayAmount, vBalanceForecast));
	vFolio.Insert("Balance", vAmount);
	Return vFolio;
EndFunction //GetFolioStructure

// ----------------------------------------------------------------------------
Function GetPocket(pFolio, rAmount, rPaymentsAmount, rStayAmount, rBalanceForecast)
	vAmount = 0;
	vPaymentsAmount = 0;
	vStayAmount = 0;
	vBalanceForecast = 0;	
		
	vPocket = New Map; 
	vDocumentNumber = cmGetDocumentNumberPresentation(pFolio.Number);
	If cmIsNumber(vDocumentNumber) Then
		vPocket.Insert("PocketId", Number(vDocumentNumber));	
	Else
		vPocket.Insert("PocketId", 0);	
	EndIf;
	vPocket.Insert("PocketCode", TrimAll(pFolio.Number));   
	
	vFolioObj = pFolio.GetObject();
	
	vAmountWithCreditLimit = 0;
	vAmount = vFolioObj.pmGetBalance(,,, vAmountWithCreditLimit);
	vPocket.Insert("Amount", vAmount);
	vPocket.Insert("AmountWithCreditLimit", vAmountWithCreditLimit);
	
	vCharges = vFolioObj.pmGetAllFolioCharges();
	vCharges.GroupBy("Folio", "Sum");
	For Each vChargesRow In vCharges Do
		vStayAmount = vStayAmount + vChargesRow.Sum;
		vBalanceForecast = vBalanceForecast + vChargesRow.Sum;
	EndDo; 
	
	vPayments = vFolioObj.pmGetAllFolioPayments();
	For Each vPaymentsRow In vPayments Do
		vPaymentsAmount = vPaymentsAmount + vPaymentsRow.Sum;
	EndDo;

	vPocket.Insert("BalanceDetails", GetFolioPocketInfoStructure(vAmount, vPaymentsAmount, vStayAmount, vBalanceForecast));
			
	rAmount = rAmount + vAmount;
	rPaymentsAmount = rPaymentsAmount + vPaymentsAmount;
	rStayAmount = rStayAmount + vStayAmount;
	rBalanceForecast = rBalanceForecast + vBalanceForecast;
	Return vPocket;
EndFunction // GetPocket

// ----------------------------------------------------------------------------
Function GetFolioList(pDocument)
	vFolios = cmGetActiveDocumentFolios(pDocument);
	If TypeOf(pDocument) = Type("DocumentRef.Accommodation") Then
		vResFolios = New ValueTable();
		If ValueIsFilled(pDocument.Reservation) Then
			vResFolios = cmGetActiveDocumentFolios(pDocument.Reservation);
			If vResFolios.Count() > 0 Then
				For Each vResFoliosRow In vResFolios Do
					If vFolios.Find(vResFoliosRow.Folio, "Folio") = Undefined Then
						vFoliosRow = vFolios.Add();
						FillPropertyValues(vFoliosRow, vResFoliosRow);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		If ValueIsFilled(pDocument.ParentDoc) And pDocument.ParentDoc <> pDocument.Reservation Then
			vParFolios = cmGetActiveDocumentFolios(pDocument.ParentDoc);
			If vParFolios.Count() > 0 Then
				For Each vParFoliosRow In vParFolios Do
					If vFolios.Find(vParFoliosRow.Folio, "Folio") = Undefined Then
						vFoliosRow = vFolios.Add();
						FillPropertyValues(vFoliosRow, vParFoliosRow);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	Return vFolios;
EndFunction // GetFolioList

// ----------------------------------------------------------------------------
Function GetFolioPocketInfoStructure(pBalance = 0, pPaymentsAmount = 0, pStayAmount = 0, pBalanceForecast = 0)
	vFolioPocketInfo = New Map;
	vFolioPocketInfo.Insert("LocalCurrencyBalance", pBalance);
	vFolioPocketInfo.Insert("LocalCurrencyPaymentsAmount", pPaymentsAmount);
	vFolioPocketInfo.Insert("LocalCurrencyStayAmount", pStayAmount);
	vFolioPocketInfo.Insert("LocalCurrencyBalanceForecast", pBalanceForecast);
	Return vFolioPocketInfo;
EndFunction // GetFolioPocketInfoStructure

// ----------------------------------------------------------------------------
Function GetReservationGuestsStructure(pReservationNumber, pGuest, pHotelProduct, pNoPost, vMainGuest)
	vReservationGuests = New Array;
	If ValueIsFilled(pGuest) Then
		vGuest = New Map;
		vGuest.Insert("BirthDate", Format(pGuest.DateOfBirth, "DF=yyyy-MM-dd"));
		vGuest.Insert("LanguageCode", pGuest.Language.Code);
		vGuest.Insert("NoPost", pNoPost);
		vGuest.Insert("Email", pGuest.EMail);
		vGuest.Insert("Title", TrimAll(pGuest.Salutation));
		vGuest.Insert("FirstName", TrimAll(pGuest.FirstName));
		vGuest.Insert("GenericNo", TrimAll(pGuest.Code));
		vGuest.Insert("ProfileGenericNo", TrimAll(pGuest.Code));
		vGuest.Insert("Guid", String(pGuest.UUID()));
		vGuest.Insert("Id", TrimAll(pReservationNumber) + "/" + TrimAll(pGuest.Code));
		vGuest.Insert("LastName", TrimAll(pGuest.LastName));
		vGuest.Insert("MiddleName", TrimAll(pGuest.SecondName));
		vGuest.Insert("Notes", TrimAll(pGuest.Remarks));
		vGuest.Insert("Phones", GetPhones(pGuest));
		vGuest.Insert("Phone", TrimAll(pGuest.Phone));
		vGuest.Insert("ReceiveSmsNotifications", pGuest.NoSMSDelivery);
		vGuest.Insert("Sex", ?(Enums.Sex.Female = pGuest.Sex, "F", "M")); 
		vGuest.Insert("DocumentData", GetDocumentDataStructure(pGuest));
		vGuest.Insert("CitizenshipCountryCode", TrimAll(pGuest.Citizenship.Code));
		vGuest.Insert("DiscountCode", cmGetObjectExternalSystemCodeByRef(InteractionParameters.Hotel, InteractionParameters.InteractionID, "DiscountTypes", pGuest.DiscountType,, True));	
		vAddressMap = Undefined;	
		If Not IsBlankString(pGuest.Address) Then
			vAddressMap = cmParseAddress(pGuest.Address);	
		ElsIf Not IsBlankString(pGuest.PostalAddress) Then
			vAddressMap = cmParseAddress(pGuest.PostalAddress);	
		EndIf;
		
		If vAddressMap <> Undefined Then
			vGuest.Insert("CountryName", vAddressMap.Country.Description);
			vGuest.Insert("Region", vAddressMap.Region);
			vGuest.Insert("District", vAddressMap.Area);
			vGuest.Insert("City", vAddressMap.City);
			vGuest.Insert("Street", vAddressMap.Street);
			vGuest.Insert("HouseNo", vAddressMap.House);
			vGuest.Insert("FlatNo", vAddressMap.Flat);
			vGuest.Insert("Zip", vAddressMap.PostCode);
		EndIf;
		vGuest.Insert("CustomFieldValues", GetCustomFieldValues(pGuest, pHotelProduct));
		vMainGuest = vGuest;
	    vReservationGuests.Add(vGuest); 
	EndIf;
	Return vReservationGuests;
EndFunction // GetMainGuestStructure

// ----------------------------------------------------------------------------
Function GetDocumentDataStructure(pGuest)
	vDocumentData = New Map;
	vDocumentData.Insert("DocumentTypeCode", cmGetObjectExternalSystemCodeByRef(InteractionParameters.Hotel, InteractionParameters.InteractionID, "IdentityDocumentTypes", pGuest.IdentityDocumentType,, True));                          
	vDocumentData.Insert("DocumentTypeName", TrimAll(pGuest.IdentityDocumentType.Description));
	vDocumentData.Insert("DocumentNumber", TrimAll(pGuest.IdentityDocumentNumber));
	vDocumentData.Insert("DocumentSeries", TrimAll(pGuest.IdentityDocumentSeries));   
	vDocumentData.Insert("DepartmentCode", TrimAll(pGuest.IdentityDocumentUnitCode));
	vDocumentData.Insert("IssueDate", GetValidDate(pGuest.IdentityDocumentIssueDate));
	vDocumentData.Insert("ExpirationDate", GetValidDate(pGuest.IdentityDocumentValidToDate));
	vDocumentData.Insert("IssuerInfo", TrimAll(pGuest.IdentityDocumentIssuedBy));
    Return vDocumentData;                     
EndFunction // GetDocumentDataStructure

// ----------------------------------------------------------------------------
Function GetCustomFieldValues(pGuest, pHotelProduct)
	vCustomFieldValues = New Array;
	If ValueIsFilled(pHotelProduct) Then
		vCustomFieldValues.Add(GetCustomField("TICKET", TrimAll(pHotelProduct.Code)));	
	EndIf; 
	If ValueIsFilled(pGuest.MilitaryRank) Then
		vCustomFieldValues.Add(GetCustomField("ZVAN", cmGetObjectExternalSystemCodeByRef(InteractionParameters.Hotel, InteractionParameters.InteractionID, "MilitaryRanks", pGuest.MilitaryRank,, True)));	
	EndIf;
	If Not IsBlankString(pGuest.Relationship) Then
		vCustomFieldValues.Add(GetCustomField("Relationship", GetRelationshipByName(TrimAll(pGuest.Relationship))));	
	EndIf;
	Return vCustomFieldValues;
EndFunction // GetDocumentDataStructure

// ----------------------------------------------------------------------------
Function GetCustomField(pCode, pValue)
	vCustomField = New Structure;
	vCustomField.Insert("Code", pCode);
	vCustomField.Insert("StringValue", pValue);
	Return vCustomField;
EndFunction // GetCustomField

// ----------------------------------------------------------------------------
Function GetRelationshipByName(pName)
	If pName = "Wife" Or pName = "Жена" Or pName = "Ehefrau" Then
		Return "Жена";	
	ElsIf pName = "Husband" Or pName = "Муж" Or pName = "Ehemann" Then
		Return "Муж";	
	ElsIf pName = "Daughter" Or pName = "Дочь" Or pName = "Tochter" Then
		Return "Дочь";	
	ElsIf pName = "Son" Or pName = "Сын" Or pName = "Sohn" Then
		Return "Сын";	
	ElsIf pName = "Mother" Or pName = "Мать" Or pName = "Mutter" Then
		Return "Мать";	
	ElsIf pName = "Father" Or pName = "Отец" Or pName = "Vater" Then
		Return "Отец";	
	ElsIf pName = "Grandmother" Or pName = "Бабушка" Or pName = "Großmutter" Then
		Return "Бабушка";	
	ElsIf pName = "Grandfather" Or pName = "Дедушка" Or pName = "Großvater" Then
		Return "Дедушка";	
	ElsIf pName = "Other degree of kinship (adults)" Or pName = "Другая степень родства (взрослые)" Or pName = "Ander Verwandtschaft-typ (die Erwachsenen)" Then
		Return "ДСРВзрослые";	
	ElsIf pName = "Other degree of kinship (children)" Or pName = "Другая степень родства (дети)" Or pName = "Ander Verwandtschaft-typ (Kinder)" Then
		Return "ДСРДети";	
	Else
		Return "";	
	EndIf;	
EndFunction // GetRelationshipByName

// ----------------------------------------------------------------------------
Function GetPhones(pGuest)
	vPhones = New Array;
	If Not IsBlankString(pGuest.Phone) Then
		vPhones.Add(GetPhone(pGuest.Phone, "Основной"));	
	EndIf; 
	If Not IsBlankString(pGuest.Fax) Then
		vPhones.Add(GetPhone(pGuest.Fax, "Доп. телефон"));	
	EndIf;
	Return vPhones;
EndFunction // GetPhones

// ----------------------------------------------------------------------------
Function GetPhone(pPhoneNumber, pPhoneType)
	vPhone = New Structure;
	vPhone.Insert("PhoneNumber", TrimAll(pPhoneNumber));
	vPhone.Insert("PhoneType", TrimAll(pPhoneType));
	Return vPhone;
EndFunction

// ----------------------------------------------------------------------------
Function GetPropertyStructure(pHotel)
	vProperty = New Map;
	vProperty.Insert("Code", cmGetObjectExternalSystemCodeByRef(InteractionParameters.Hotel, InteractionParameters.InteractionID, "Hotels", pHotel, True));
	vProperty.Insert("CurrencyCode", cmGetObjectExternalSystemCodeByRef(InteractionParameters.Hotel, InteractionParameters.InteractionID, "Currencies",  pHotel.BaseCurrency,, True)); 
	vProperty.Insert("Name", TrimAll(pHotel.Description));
    Return vProperty;
EndFunction // GetPropertyStructure

// ----------------------------------------------------------------------------
Function GetPackagesStructure(pServices, rAmount, rFolioCurrency)
	vPackages = New Array;
	For Each vService In pServices Do 
		If ValueIsFilled(vService.ServicePackage) And Not vService.IsRoomRevenue Then
			vPackage = New Map;
			vPackage.Insert("Code", cmGetObjectExternalSystemCodeByRef(InteractionParameters.Hotel, InteractionParameters.InteractionID, "ServicePackages", vService.ServicePackage,, True));
			vPackage.Insert("Amount", vService.Sum);
			vFolioCurrency = cmGetObjectExternalSystemCodeByRef(InteractionParameters.Hotel, InteractionParameters.InteractionID, "Currencies",  vService.FolioCurrency,, True);
			vPackage.Insert("CurrencyCode", vFolioCurrency);
			vPackages.Add(vPackage);
		EndIf; 
		If rFolioCurrency = Undefined Then
			rFolioCurrency = vFolioCurrency;
		ElsIf Not IsBlankString(rFolioCurrency) And rFolioCurrency <> vFolioCurrency Then
			rFolioCurrency = "";	
		EndIf;
        rAmount = rAmount + vService.Sum;
	EndDo;
    Return vPackages;
EndFunction // GetPackagesStructure

// ----------------------------------------------------------------------------
Function GetTimelineStructure(pDocument, rCurrentTimeline)
	vServices = pDocument.Services.Unload();
	vServices.GroupBy("AccountingDate, FolioCurrency, IsRoomRevenue, ServicePackage", "Sum");
	
	vAccountingDate = BegOfDay(pDocument.CheckInDate);
	vTimelineArr = New Array;
	vCurDate = BegOfDay(CurrentSessionDate());
	While vAccountingDate < pDocument.CheckOutDate Do
		vAmount = 0;
		vFolioCurrency = Undefined; 
		vTimeline = New Map;
		vTimeline.Insert("Id", DayOfYear(vAccountingDate));
		vTimeline.Insert("EffectiveDate", vAccountingDate);
		vTimeline.Insert("DateRange", DateRangeStructure(vAccountingDate, EndOfDay(vAccountingDate)));
		vTimeline.Insert("DiscountCode", cmGetObjectExternalSystemCodeByRef(InteractionParameters.Hotel, InteractionParameters.InteractionID, "DiscountTypes", pDocument.DiscountType,, True));
        vTimeline.Insert("Layout", GetLayoutStructure(pDocument));
		vTimeline.Insert("Packages", GetPackagesStructure(vServices.FindRows(New Structure("AccountingDate", vAccountingDate)), vAmount, vFolioCurrency));
		vTimeline.Insert("PaymentsShareCoefficient", GetPaymentsShareCoefficient(pDocument.SharePercent));
		vTimeline.Insert("RateCode", cmGetObjectExternalSystemCodeByRef(InteractionParameters.Hotel, InteractionParameters.InteractionID, "RoomRates", pDocument.RoomRate,, True));
		vTimeline.Insert("RateName", TrimAll(pDocument.RoomRate.Description));
		vTimeline.Insert("RoomCode", cmGetObjectExternalSystemCodeByRef(InteractionParameters.Hotel, InteractionParameters.InteractionID, "Rooms", pDocument.Room));
		vTimeline.Insert("RoomTypeCode", cmGetObjectExternalSystemCodeByRef(InteractionParameters.Hotel, InteractionParameters.InteractionID, "RoomTypes", pDocument.RoomType,, True));
		vTimeline.Insert("RoomTypeName", TrimAll(pDocument.RoomType.Description)); 
		vTimeline.Insert("StayPriceLocalCurrencyAmount", vAmount);
		vTimeline.Insert("StayPriceLocalCurrencyCode", vFolioCurrency);
		vTimeline.Insert("StayType", 0);
		vTimelineArr.Add(vTimeline); 
		If vCurDate = vAccountingDate Or (rCurrentTimeline = Undefined And (vCurDate < vAccountingDate Or vCurDate > vAccountingDate)) Then
			rCurrentTimeline = vTimeline;	
		EndIf;
		vAccountingDate = vAccountingDate + 24 * 3600;
	EndDo;	
    Return vTimelineArr;
EndFunction // GetCurrentTimelineStructure()

// ----------------------------------------------------------------------------
Function GetPaymentsShareCoefficient(pSharePercent)
	Try
		If Not IsBlankString(pSharePercent) Then
			Return Number(pSharePercent);	
		EndIf; 
		Return 0;
	Except
		Return 0;	
	EndTry;
EndFunction // GetPaymentsShareCoefficient()

// ----------------------------------------------------------------------------
Function GetLayoutStructure(pDocument, pIsOld = False)
	vLayout = New Map;
	If pIsOld Then
		vLayout.Insert("OldAdultCount", pDocument.NumberOfAdults);
		vLayout.Insert("OldChild1Count", pDocument.NumberOfTeenagers);
		vLayout.Insert("OldChild2Count", pDocument.NumberOfChildren);
		vLayout.Insert("OldChild3Count", pDocument.NumberOfInfants);
	Else
		vLayout.Insert("AdultCount", pDocument.NumberOfAdults);
		vLayout.Insert("Child1Count", pDocument.NumberOfTeenagers);
		vLayout.Insert("Child2Count", pDocument.NumberOfChildren);
		vLayout.Insert("Child3Count", pDocument.NumberOfInfants);	
	EndIf;
    Return vLayout;
EndFunction // GetLayoutStructure()

// ----------------------------------------------------------------------------
Function DateRangeStructure(pDateTimeFrom, pDateTimeTo)
	vDateRange = New Map;
	vDateRange.Insert("DateTimeFrom", pDateTimeFrom);
	vDateRange.Insert("DateTimeTo", pDateTimeTo);
	Return vDateRange;
EndFunction // DateRangeStructure

// ----------------------------------------------------------------------------
Function GetValidDate(pDate)
	If Not ValueIsFilled(pDate) Then
		Return pDate;	
	EndIf;
	
	If pDate < AddMonth(CurrentSessionDate(), -12 * 120) Then
		Return '00010101';	
	EndIf;        
	
	Return pDate;
EndFunction // GetValidDate

#EndRegion

#Region Transactions

// -----------------------------------------------------------------------------
Function GetRoomAndClientRef(pReservationGuestId)
	vQ = New Query;
	vQ.Text =
	"SELECT
	|	Accommodation.Room.Description AS RoomCode,
	|	Accommodation.Guest.Code AS ClientCode
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	CASE
	|			WHEN &qAccommodationNumber <> """"
	|				THEN Accommodation.Number = &qAccommodationNumber
	|						AND Accommodation.Guest.Code = &ClientsCode
	|						AND Accommodation.Posted
	|						AND NOT Accommodation.DeletionMark
	|						AND Accommodation.Hotel = &qHotel
	|			ELSE FALSE
	|		END
	|
	|UNION ALL
	|
	|SELECT
	|	"""",
	|	Clients.Code
	|FROM
	|	Catalog.Clients AS Clients
	|WHERE
	|	CASE
	|			WHEN &qAccommodationNumber = """"
	|				THEN Clients.Code = &ClientsCode
	|						AND NOT Clients.DeletionMark
	|						AND NOT Clients.IsFolder
	|			ELSE FALSE
	|		END";
	vQ.SetParameter("qHotel", InteractionParameters.Hotel);
	
	vReservationGuestIdArr = StrSplit(pReservationGuestId, "/", True);
	If vReservationGuestIdArr.Count() = 2 Then
		vQ.SetParameter("qAccommodationNumber", vReservationGuestIdArr[0]);
		vQ.SetParameter("ClientsCode", vReservationGuestIdArr[1]);
	Else
		vQ.SetParameter("qAccommodationNumber", "");
		vQ.SetParameter("ClientsCode", pReservationGuestId);
	EndIf;
	Return vQ.Execute().Unload();
EndFunction // GetRoomAndClientRef

// ----------------------------------------------------------------------------
Function PostTransactionsRequest(pDataMap, pTransactions)
	If pDataMap["ReservationGuestId"] = Undefined And IsBlankString(pDataMap["ReservationGuestId"]) And pDataMap["FolioGenericNo"] = Undefined And IsBlankString(pDataMap["FolioGenericNo"]) Then
		Raise NStr("en = 'No value specified for ""FolioGenericNo"" or ""ReservationGuestId""'; de = 'Kein Wert für ""FolioGenericNo"" oder ""ReservationGuestId"" angegeben'; ru = 'Не указано значение ""FolioGenericNo"" или ""ReservationGuestId""'");
	EndIf;
	
	vFolioNumber = "";
	vRoomCode = "";
	vClientCode = ""; 
	vServiceCode = "";
	If pDataMap["FolioGenericNo"] <> Undefined And Not IsBlankString(pDataMap["FolioGenericNo"]) Then
		vFolioNumber = TrimAll(pDataMap["FolioGenericNo"]);	
	ElsIf pDataMap["ReservationGuestId"] <> Undefined And Not IsBlankString(pDataMap["ReservationGuestId"]) Then
		vCatalogsRef = GetRoomAndClientRef(TrimAll(pDataMap["ReservationGuestId"]));
		If vCatalogsRef.Count() = 0  Then
			Raise NStr("en = 'Client not found'; de = 'Kunde nicht gefunden'; ru = 'Клиент не найден'");	
		EndIf;
		vRoomCode = TrimAll(vCatalogsRef[0].RoomCode);
		vClientCode = TrimAll(vCatalogsRef[0].ClientCode);
	EndIf;
	
	If ValueIsFilled(OrderType) And OrderType.ServicesAllowed.Count() > 0 Then
		vServiceCode = TrimAll(OrderType.ServicesAllowed[0].Service.Code);
	EndIf;
		
	vSucceeded = True; 
	vResult = "";
	
	vXDTOSource 					= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "Source"));
	vXDTOSource.ExternalSystemCode 	= InteractionParameters.Code;
	
	BeginTransaction(DataLockControlMode.Managed);    
	Try        
		For Each vTransactionsRow In pTransactions Do
			vXDTOOrderClient 			= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderClient"));
			vXDTOOrderDetails  			= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderDetails"));
			vXDTOOrderItems 			= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderItems"));
			
			vXDTOOrderClient.FolioNumber		= vFolioNumber;	
			vXDTOOrderClient.Room				= vRoomCode;
			vXDTOOrderClient.ClientID			= vClientCode;
			
			vXDTOOrderDetails.Hotel = InteractionParameters.Hotel.Code;
			If ValueIsFilled(OrderType) Then
				vXDTOOrderDetails.OrderType = OrderType.Code;
				If OrderType.StatusesCourse.Count() > 0 Then
					vXDTOOrderDetails.OrderStatus = OrderType.StatusesCourse[0].Status.Code; 
				EndIf;
			EndIf;
			vXDTOOrderDetails.Service			= vServiceCode;
			If vTransactionsRow["ScheduleDate"] <> Undefined And Not IsBlankString(vTransactionsRow["ScheduleDate"]) And (vTransactionsRow["PostImmediately"] = Undefined Or Not vTransactionsRow["PostImmediately"]) Then
				vXDTOOrderDetails.OrderDate		= XMLValue(Type("Date"), TrimAll(vTransactionsRow["ScheduleDate"]));
			Else
				vXDTOOrderDetails.OrderDate		= CurrentSessionDate();	
			EndIf;
			vXDTOOrderDetails.GuestsQuantity	= 1;
			If vTransactionsRow["TransactionCode"] <> Undefined And Not IsBlankString(vTransactionsRow["TransactionCode"]) Then
				vXDTOOrderDetails.OrderID 		= TrimAll(vTransactionsRow["TransactionCode"]);
			EndIf;
			If vTransactionsRow["Name"] <> Undefined And Not IsBlankString(vTransactionsRow["Name"]) Then
				vXDTOOrderDetails.Remarks = NStr("de='Bestellung Nr. ';en='Order N ';ru='Заказ № '") + TrimAll(vTransactionsRow["Name"]);
			EndIf;
			
			vTotalSum = 0;
			If vTransactionsRow["Items"] <> Undefined Then
				For Each vItemRow In vTransactionsRow["Items"] Do
					vXDTOOrderItem 			= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderItem"));
					vXDTOOrderItem.Service 	= vItemRow["ServiceItemCode"];
					vXDTOOrderItem.ItemName = vItemRow["Name"];
					vXDTOOrderItem.Quantity = vItemRow["Count"];
					vXDTOOrderItem.Sum 		= vItemRow["Amount"];
					vXDTOOrderItem.Price 	= vXDTOOrderItem.Sum / vXDTOOrderItem.Quantity;
					vXDTOOrderItems.OrderItem.Add(vXDTOOrderItem);
					vTotalSum 				= vTotalSum + vXDTOOrderItem.Sum;
				EndDo
			EndIf;
			
			vXDTOOrderDetails.OrderItems 		= vXDTOOrderItems;
			vXDTOOrderDetails.Sum 				= vTotalSum;
			vXDTOOrderDetails.Quantity 			= 1;
			
			vOrder 	= cmWritePOSOrder(vXDTOOrderClient, vXDTOOrderDetails, vXDTOSource);
			If Not IsBlankString(vOrder.Error) Then
				vResult = vOrder.Error;
				vSucceeded = False;
				Break;
			EndIf;
		EndDo;
		
		If pDataMap["DryRun"] Or Not vSucceeded Then
			Raise "";
		EndIf;
		
		CommitTransaction();
	Except  
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
	EndTry;
	
	Return MapToJSON(PostTransactionsResponse(pDataMap, vSucceeded, vResult));
EndFunction // PostTransactionsRequest

// ----------------------------------------------------------------------------
Function PostTransactionsResponse(pDataMap, pSucceeded, pErrorMessage)
	vResultMap = New Map;
	vResultMap.Insert("Succeeded", pSucceeded); 
	vResultMap.Insert("ErrorMessage", pErrorMessage);
	vResultMap.Insert("CorrelationId", pDataMap["CorrelationId"]);	
	Return vResultMap;
EndFunction // PostTransactionsResponse

#EndRegion

#Region GuestProfile

// ----------------------------------------------------------------------------
Function CreateGuestProfileRequest(pDataMap, pDocumentData)
	vClient = cmWriteExternalClient(pDataMap["GenericNo"], "", pDataMap["LastName"], pDataMap["FirstName"], pDataMap["MiddleName"], pDataMap["Sex"], 
								    pDataMap["CitizenshipCountryCode"], GetBirthDate(pDataMap["BirthDate"]),  pDataMap["Phone"], "", pDataMap["Email"],
								    pDataMap["Notes"], pDataMap["ReceiveSmsNotifications"], TrimAll(InteractionParameters.Hotel.Code), TrimAll(InteractionParameters.InteractionID), 
								    pDataMap["MainProfileGenericNo"], pDocumentData["DocumentTypeCode"], pDocumentData["DocumentSeries"], pDocumentData["DocumentNumber"],
								    GetDate(pDocumentData["IssueDate"]), GetDate(pDocumentData["ExpirationDate"]), pDocumentData["DepartmentCode"], pDocumentData["IssuerInfo"], "",
								    BuildAddress(pDataMap), Undefined, Catalogs.Languages.FindByCode(pDataMap["LanguageCode"]), "XDTO");
										
	Return MapToJSON(CreateGuestProfileResponse(pDataMap, TrimAll(vClient.ClientCode), vClient.ErrorDescription));	
EndFunction // CreateGuestProfileRequest

// ----------------------------------------------------------------------------
Function GetBirthDate(pBirthDate)
    vBirthDate = '00010101';
	If pBirthDate <> Undefined Then
	Try
    	vBirthDate = Date(StrReplace(pBirthDate, "-", ""));
	Except
		vBirthDate = '00010101';
	EndTry;	
	EndIf;
	Return vBirthDate;
EndFunction //GetBirthDate

// ----------------------------------------------------------------------------
Function GetDate(pDate)
    vDate = '00010101';
	If pDate <> Undefined Then
	Try
    	vDate = XMLValue(Type("Date"), pDate)
	Except
		vDate = '00010101';
	EndTry;	
	EndIf;
	Return vDate;
EndFunction //GetBirthDate

// ----------------------------------------------------------------------------
Function BuildAddress(pDataMap)
	vCountry = "";
	If pDataMap["CountryName"] <> Undefined Then
		vCountry = pDataMap["CountryName"];	
	EndIf;
	vPostCode = "";
	If pDataMap["Zip"] <> Undefined Then
		vPostCode = pDataMap["Zip"];	
	EndIf;
	vRegion = "";
	If pDataMap["Region"] <> Undefined Then
		vRegion = pDataMap["Region"];	
	EndIf; 
	vArea = "";
	If pDataMap["District"] <> Undefined Then
		vArea = pDataMap["District"];	
	EndIf;
	vCity = "";
	If pDataMap["City"] <> Undefined Then
		vCity = pDataMap["City"];	
	EndIf; 
	vStreet = "";
	If pDataMap["Street"] <> Undefined Then
		vStreet = pDataMap["Street"];	
	EndIf;
	vHouse = "";
	If pDataMap["HouseNo"] <> Undefined Then
		vHouse = pDataMap["HouseNo"];
		If pDataMap["BuildingNo"] <> Undefined Then
			vHouse = vHouse + "к" + pDataMap["BuildingNo"]	
		EndIf;
		If pDataMap["Structure"] <> Undefined Then
			vHouse = vHouse + "стр" + pDataMap["Structure"]	
		EndIf;
	EndIf;	
	vFlat = "";
	If pDataMap["FlatNo"] <> Undefined Then
		vFlat = pDataMap["FlatNo"];	
	EndIf;
	Return cmBuildAddress(vCountry, vPostCode, vRegion, vArea, vCity, vStreet, vHouse, vFlat) 	
EndFunction // BuildAddress

// ----------------------------------------------------------------------------
Function CreateGuestProfileResponse(pDataMap, pClientCode, pErrorDescription)
	vResultMap = New Map;
	vResultMap.Insert("Succeeded", Not IsBlankString(pClientCode));
	vResultMap.Insert("ErrorMessage", pErrorDescription);
	vResultMap.Insert("GenericNo", pClientCode);
	vResultMap.Insert("CorrelationId", pDataMap["CorrelationId"]);
	Return vResultMap;
EndFunction // CreateGuestProfileResponse

#EndRegion

// -----------------------------------------------------------------------------
Procedure ClearHistoryFiles()  
	If IsBlankString(HistoryCatalog) Then 
		Return;
	EndIf;   
	
	If NumberOfFilesInHistory = 0 Then
		Return;
	EndIf;
	
	vFilesList = New ValueList();
	vFiles = FindFiles(TrimAll(HistoryCatalog), "*_????-??-??_??-??.csv");
	For Each vFile In vFiles Do
		vFilesList.Add(vFile, vFile.Name);
	EndDo;
	vFilesList.SortByPresentation(SortDirection.Asc);
	vFilesListCount = vFilesList.Count();  
	    
	While vFilesListCount > NumberOfFilesInHistory Do
		vFile = vFilesList[vFilesListCount - 1].Value;
		DeleteFiles(vFile.FullName);
		vFilesListCount = vFilesListCount - 1;
	EndDo;
EndProcedure // ClearHistoryFiles

// -----------------------------------------------------------------------------
Function GetExternalCodeFromRef(pDataType, pRef, pGetCode)
	vData = InformationRegisters.ExternalSystemIntegrationData.GetData(InteractionParameters, pDataType, "Code", pRef);
	
	If vData.Count() > 0 Then
		vObjectExternalCode = vData[0].ExternalSystemDataCode;		
	Else
		If pGetCode Then
			If Metadata.Catalogs.Contains(pRef.Metadata()) Then
				vObjectExternalCode = TrimAll(pRef.Code);
			Else
				vObjectExternalCode = TrimAll(pRef.Number);	
			EndIf;
		Else
			vObjectExternalCode = TrimAll(pRef.Description);
		EndIf;	
	EndIf;   
	Return vObjectExternalCode;
EndFunction // GetDataFromMapping

// ----------------------------------------------------------------------------
Function MapToJSON(pMap)
	vJSONWriter = New JSONWriter;
	vJSONWriter.SetString(New JSONWriterSettings(JSONLineBreak.None));
	WriteJSON(vJSONWriter, pMap);
	Return vJSONWriter.Close();	
EndFunction // MapToJSON

// ----------------------------------------------------------------------------
Function JSONToMap(pJSON)
	vJSONReader = New JSONReader;
	vJSONReader.SetString(pJSON);
	Return ReadJSON(vJSONReader, True); 	
EndFunction // JSONToMap

#EndRegion
