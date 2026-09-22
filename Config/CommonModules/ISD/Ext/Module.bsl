
#Region Public

// -------------------------------------------------------------------------------
//  Get or delete ticket
//
// Parameters:
//  pCommand - String											 - "new" or "del"
//  pDocRef	 - DocumentRef.Reservation, DocumentRef.Accommodation	 - Ref on document
//  pHotel	 - CatalogRef.Hotels									 - Ref on hotel
//
Procedure EditTicket(pCommand, pDocRef, pHotel) Export
	// Get interaction
	vExtIntegration = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionType(Enums.Integrations.ISD, pHotel);
	If Not ValueIsFilled(vExtIntegration) Then 
		vError = Nstr("en = 'Could not find ISD interaction to connect'; de = 'Es konnte keine ISD-Interaktion zum Herstellen einer Verbindung gefunden werden'; ru = 'Не удалось найти ISD взаимодействие для управления билетами'");
		tcCommonFunctionOnClientServer.TextMessage(vError);
		Return;
	EndIf;	 
	vNumber = XMLString(pDocRef.Number);
	If TypeOf(pDocRef) = Type("DocumentRef.Accommodation") Then
		// Get one room accommodation
		vDocList = GetOneCheckOutRoomAccommodations(pDocRef);
	Else	
		// Get one room reservation
		vGuestGroupObj = pDocRef.GuestGroup.GetObject();
		vReservationList = vGuestGroupObj.pmGetReservations(True, pDocRef.ReservationStatus.IsActive);
		vDocList = vReservationList.FindRows(New Structure("Number", vNumber));
	EndIf;
	// Get Custom fields
	vCustFieldsValues = cmGetReservationCustomFieldsValues(pDocRef);
	vOrderBar = "";
	For Each vRow In vCustFieldsValues Do
		If TrimAll(vRow.CharacteristicCode) = "NORDERBAR" Then
			vOrderBar = vRow.CharacteristicValue;
			Break;
		EndIf;
	EndDo;
	// Fill parameters
	vCmd = Lower(pCommand);
	vRequestParameters = New Structure;
	vRequestParameters.Insert("cmd", vCmd);
	vRequestParameters.Insert("bkid", vNumber);
	If vCmd = "new" Then
		If TypeOf(pDocRef) = Type("DocumentRef.Accommodation") Then
			vRequestParameters.Insert("arv", Format(pDocRef.CheckOutDate, "DF=dd.MM.yyyy"));
		Else
			vRequestParameters.Insert("arv", Format(pDocRef.CheckInDate, "DF=dd.MM.yyyy"));
		EndIf;
		vRequestParameters.Insert("ticc", vDocList.Count());
		If TypeOf(pDocRef) = Type("DocumentRef.Accommodation") Then
			If TrimAll(pHotel.Code) = TrimAll("P1389") Then
				vRequestParameters.Insert("tfid", "22878236");
			Else
				vRequestParameters.Insert("tfid", "22857131");
			EndIf;
		EndIf;
	Else // Delete
		vRequestParameters.Insert("cshl", vOrderBar);
	EndIf;	
	vRequestURL = "";
	vFirst = True;
	For Each vKeyAndValue In vRequestParameters Do
		If vFirst Then
			vRequestURL = vRequestURL + "?" + vKeyAndValue.Key + "=" + vKeyAndValue.Value; 
		Else
			vRequestURL = vRequestURL + "&" + vKeyAndValue.Key + "=" + vKeyAndValue.Value;
		EndIf;			
		vFirst = False;
	EndDo;
	vJSONRequest = "";
	Try
		vRequestParameters.Insert("Hotel", String(pHotel));
		vRequestParameters.Insert("Room", String(pDocRef.Room));
		vRequestParameters.Insert("User", String(SessionParameters.CurrentUser));
		vJSONSettings	= New JSONWriterSettings(JSONLineBreak.Auto, Chars.Tab);
		vJSONWriter 	= New JSONWriter;
		vJSONWriter.SetString(vJSONSettings);	
		WriteJSON(vJSONWriter, vRequestParameters);
		vJSONRequest = vJSONWriter.Close();
	Except	
	EndTry;
	
	// HTTP connection
	vHTTPConnection = New HTTPConnection(vExtIntegration.WSHost);
	vHTTPRequest = New HTTPRequest(vRequestURL);
	vRs = vHTTPConnection.Get(vHTTPRequest);
	vJSONResponse = vRs.GetBodyAsString();
	vDesc = "";
	If vRs.StatusCode = 200 Then
		vRes = Catalogs.DataConvertationRules.JSONtoMap(vJSONResponse);
		vDesc = vRes.Get("Descr");
		If vRes.Get("Result") = 0 Then
			If vExtIntegration.DebugMode Then
				If vRes.Get("Result") = 0 Then
					vEvent = Enums.ExternalSystemEventTypes.Success;
				Else
					vEvent = Enums.ExternalSystemEventTypes.Warning;
				EndIf;	
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vExtIntegration, vCmd + "Barcode", vEvent, vJSONRequest, vJSONResponse, vDesc);
			EndIf;
			vFields = GetListOfReservationCustomFields();
			If vCmd = "new" Then 
				vCSHITEMS = vRes.Get("CSHITEMS");
				If Not vCSHITEMS = Undefined And vCSHITEMS.Count() > 0 Then
					vListTickets = New Array;
					For Each vEl In vCSHITEMS Do
						vListTickets.Add(vEl.Value[1]);
					EndDo; 
					vRowCount = Min(vDocList.Count(), vListTickets.Count());
					For vInd = 0 To vRowCount - 1 Do 
						vDoc = vDocList[vInd].Reservation;
						// Barcode ticket
						vRcdMgr = InformationRegisters.ReservationCustomAttributeValues.CreateRecordManager();
						vRcdMgr.Owner = vDoc;
						vRcdMgr.Characteristic = vFields.NTICKET;
						vRcdMgr.CharacteristicValue = vListTickets[vInd];
						vRcdMgr.Write(True);
						// Barcode to recovery
						vRcdMgr = InformationRegisters.ReservationCustomAttributeValues.CreateRecordManager();
						vRcdMgr.Owner = vDoc;
						vRcdMgr.Characteristic = vFields.NORDERBAR;
						vRcdMgr.CharacteristicValue = vRes.Get("ORDERBAR");
						vRcdMgr.Write(True);
						// Order number
						vRcdMgr = InformationRegisters.ReservationCustomAttributeValues.CreateRecordManager();
						vRcdMgr.Owner = vDoc;
						vRcdMgr.Characteristic = vFields.NORDER;
						vRcdMgr.CharacteristicValue = vRes.Get("CSHLID");
						vRcdMgr.Write(True); 
						vEventType = "Barcode_EarlyCheckIn"; 
						vEventDescription = NStr("en = 'Early check-in'; de = 'Früh einchecken'; ru = 'Билет на подъем'", CurrentSystemLanguage());
						If TypeOf(vDoc) = Type("DocumentRef.Accommodation") Then
							vEventType = "Barcode_LateCheckOut";           
							vEventDescription = NStr("en = 'Late check-out'; de = 'Später check out'; ru = 'Поздний выезд'", CurrentSystemLanguage());
						EndIf;	   
						If vInd < vRowCount - 1 Then
							cmWait(1); 
						EndIf;	
						WriteKeyCardSecuritySystemEvent(pHotel, vDoc.Room, vEventType, pCommand, vListTickets[vInd], vEventDescription, vDoc.Guest, vDoc, vDoc.CheckInDate, vDoc.CheckOutDate);
					EndDo;
				EndIf;
			Else
				For Each vRowDoc In vDocList Do
					For Each vF In vFields Do  
						vDoc = vRowDoc.Reservation; 
						vRcdMgr = InformationRegisters.ReservationCustomAttributeValues.CreateRecordManager();
						vRcdMgr.Owner = vDoc;
						vRcdMgr.Characteristic = vF.Value;
						vRcdMgr.Delete(); 
						vEventType = "Barcode_Cancel_EarlyCheckIn"; 
						vEventDescription = NStr("en = 'Early check-in'; de = 'Früh einchecken'; ru = 'Билет на подъем'", CurrentSystemLanguage());
						If TypeOf(vDoc) = Type("DocumentRef.Accommodation") Then
							vEventType = "Barcode_Cancel_LateCheckOut";           
							vEventDescription = NStr("en = 'Late check-out'; de = 'Später check out'; ru = 'Поздний выезд'", CurrentSystemLanguage());
						EndIf;	
						WriteKeyCardSecuritySystemEvent(pHotel, vDoc.Room, vEventType, pCommand, "", vEventDescription, vDoc.Guest, vDoc, vDoc.CheckInDate, vDoc.CheckOutDate);
					EndDo; 
				EndDo;
			EndIf;	
		Else
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vExtIntegration, vCmd + "Barcode", Enums.ExternalSystemEventTypes.Error, vJSONRequest, vDesc);
			Raise vDesc;
		EndIf;
	Else
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vExtIntegration, vCmd + "Barcode", Enums.ExternalSystemEventTypes.Error, vJSONRequest, vRs.Error, vDesc);
		Raise vRs.Error;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - Ref
//  pAction					 - String								 - Action to call
//  pDocument				 - DocumentRef.Accommodation			 - Ref
//  pKeyParams				 - Structure							 - Parameters
// 
// Returns:
//  Structure - Result call
//
Function IssueCard(pInteractionParameters, pAction, pDocument, pKeyParams) Export
	Try
			
		vCard = pKeyParams.Card;

		vGuest = pDocument.Guest;
		vCheckInDate = pKeyParams.PeriodFrom;
		If Not ValueIsFilled(vCheckInDate) Then
			vCheckInDate = pDocument.CheckInDate;
		EndIf;
		vCheckOutDate = pKeyParams.PeriodTo;
		If Not ValueIsFilled(vCheckOutDate) Then
			vCheckOutDate = pDocument.CheckOutDate;
		EndIf;
		vBrand = "";
		vModel = "";
		vPlate = "";
		
		If ValueIsFilled(vCard) And ValueIsFilled(vCard.Vehicle) Then
			vVehicle = vCard.Vehicle;
			vBrand = vVehicle.Brand;
			vModel = vVehicle.Model;
			vPlate = vVehicle.CarNumber;
		EndIf;
		
		vCardType = Undefined;
		If ValueIsFilled(vCard) And ValueIsFilled(vCard.IdentificationCardType) Then
			vCardType = vCard.IdentificationCardType;
		EndIf;
		If TypeOf(pDocument) = Type("DocumentRef.Accommodation") Then
			If pDocument.AccommodationStatus.IsActive = False Or pDocument.AccommodationStatus.IsInHouse = False Then
				If ValueIsFilled(vCardType) Then
					If vCardType.DoNotClearCardInISD = False Then
						vCheckOutDate = CurrentSessionDate();
					EndIf;
				Else
					vCheckOutDate = CurrentSessionDate();
				EndIf;
			EndIf;	
		ElsIf TypeOf(pDocument) = Type("DocumentRef.Reservation") Then	
			If pDocument.ReservationStatus.IsActive = False Or pDocument.ReservationStatus.IsAnnulation = True Or pDocument.ReservationStatus.IsNoShow = True Then
				If ValueIsFilled(vCardType) Then
					If vCardType.DoNotClearCardInISD = False Then
						vCheckOutDate = CurrentSessionDate();
					EndIf;
				Else
					vCheckOutDate = CurrentSessionDate();
				EndIf;
			EndIf;	
		EndIf;

		vRequestParams = New Structure();
		vRequestParams.Insert("cli_guid", 		XMLString(vGuest));
		vRequestParams.Insert("cli_first", 		TrimAll(vGuest.FirstName));
		vRequestParams.Insert("cli_last", 		TrimAll(vGuest.LastName));
		vRequestParams.Insert("cli_sur", 		TrimAll(vGuest.SecondName));
		vRequestParams.Insert("cli_birth", 		Format(vGuest.DateOfBirth, "DF=dd.MM.yyyy"));
		vRequestParams.Insert("cli_tel",   		TrimAll(vGuest.Phone));
		vRequestParams.Insert("pointsale", 		TrimAll(pKeyParams.WorkstationID));
		vRequestParams.Insert("media_num", 		TrimAll(pKeyParams.KeyID));
		vRequestParams.Insert("dt_arrive", 		Format(vCheckInDate, "DF=yyyy-MM-dd-HH-mm"));
		vRequestParams.Insert("dt_depart", 		Format(vCheckOutDate, "DF=yyyy-MM-dd-HH-mm"));
		vRequestParams.Insert("Room",     	    TrimAll(pDocument.Room));
		vRequestParams.Insert("Hotel",     	    TrimAll(pDocument.Hotel));
		vRequestParams.Insert("tariff_id", 		pKeyParams.TariffID);
		vRequestParams.Insert("park_id", 		pKeyParams.ParkID);
		vRequestParams.Insert("brand", 			vBrand);
		vRequestParams.Insert("model", 			vModel);
		vRequestParams.Insert("plate", 			vPlate);
		vRequestParams.Insert("kkm_regnum", 	pKeyParams.kkm_regnum);
		vRequestParams.Insert("kkm_fnserial", 	pKeyParams.kkm_fnserial);
		vRequestParams.Insert("kkm_fiscdoc", 	pKeyParams.kkm_fiscdoc);
		vRequestParams.Insert("kkm_fpd",     	pKeyParams.kkm_fpd);
		
		vResult = CallHTTPAction(pInteractionParameters, pAction, vRequestParams);
		If vResult.Success And ValueIsFilled(pKeyParams.Card) Then
			vCardObj = vCard.GetObject();
			vCardObj.StatusDescription = "";
			vCardObj.ISDRateCode = pKeyParams.TariffID;
			vCardObj.ISDParkingRateCode = pKeyParams.ParkID;
			vCardObj.Issued = True;
			vCardObj.ChangeDate = CurrentSessionDate();
			vCardObj.ChangeAuthor = SessionParameters.CurrentUser;
			vCardObj.DateTimeFrom = vCheckInDate;
			vCardObj.DateTimeTo = vCheckOutDate;

			vCardObj.Write();   
			
			vEventType = "Card_EarlyCheckIn"; 
			vEventDescription = NStr("en = 'Early check-in'; de = 'Früh einchecken'; ru = 'Ранний заезд'", CurrentSystemLanguage());
			If TypeOf(pDocument) = Type("DocumentRef.Accommodation") Then
				vEventType = "Card_CheckIn";           
				vEventDescription = NStr("en = 'Issuing a key in ISD'; de = 'Ausgabe eines Schlüssels in ISD'; ru = 'Ключ-карта'", CurrentSystemLanguage());
			EndIf;	
			WriteKeyCardSecuritySystemEvent(pDocument.Hotel, pDocument.Room, vEventType, pAction, TrimAll(pKeyParams.KeyID), vEventDescription, vGuest, pDocument, vCheckInDate, vCheckOutDate);
		EndIf;	
		
	Except
		WriteLogEvent("Debug", EventLogLevel.Error, , , ErrorDescription());
		// Log exception
		vJson = Catalogs.DataConvertationRules.MapToJSON(vRequestParams);
		vExceptionText = cmGetRootErrorDescription(ErrorInfo());
		vResult = ProcessAPICallEception(pInteractionParameters, vExceptionText, pAction, vJson);
	EndTry;
	
	Return vResult;
EndFunction // CheckInGuest

// --------------------------------------------------------------------------------
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - Ref
// 
// Returns:
//  Structure - Result call
//
Function GetTariffs(pInteractionParameters) Export 
	
	vAction  = "getTariffs";
	vRes = CallHTTPAction(pInteractionParameters, vAction);
	
	Return vRes;
EndFunction // GetTariffs

// --------------------------------------------------------------------------------
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - Ref
//  pKeyParams				 - Structure							 - Parameters
// 
// Returns:
//  Structure - Result call
//
Function TestCard(pInteractionParameters, pKeyParams) Export 
	vAction  = "testCard";
	vRes = CallHTTPAction(pInteractionParameters, vAction, pKeyParams);
	Return vRes;
EndFunction // TestCard

// --------------------------------------------------------------------------------
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - Ref
//  pKeyParams				 - Structure							 - Parameters
// 
// Returns:
//  Structure - Result call
//
Function CardInfo(pInteractionParameters, pKeyParams) Export 
	vAction  = "cardInfo";
	vRes = CallHTTPAction(pInteractionParameters, vAction, pKeyParams);
	Return vRes;
EndFunction // CardInfo

// --------------------------------------------------------------------------------
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - Ref
//  pKeyParams				 - Structure							 - Parameters
// 
// Returns:
//  Structure - Result call
//
Function ClearCard(pInteractionParameters, pKeyParams) Export 

	vAction  = "clearCard";
	
	vRes = CallHTTPAction(pInteractionParameters, vAction, pKeyParams);

	Return vRes;
EndFunction // ClearCard

// --------------------------------------------------------------------------------
Function ReplaceCard(pInteractionParameters, pKeyParams) Export 
	
	vAction  = "replaceMedia";
	vCardID = TrimAll(pKeyParams.KeyNewID);
	vParams = New Structure;
	vParams.Insert("src_media_num", TrimAll(pKeyParams.KeyOldID));
	vParams.Insert("dst_media_num", vCardID); 
	vParams.Insert("pointsale", TrimAll(pKeyParams.WorkstationID));
	vParams.Insert("Hotel", String(SessionParameters.CurrentHotel));
	vParams.Insert("User", String(SessionParameters.CurrentUser));
		
	vRes = CallHTTPAction(pInteractionParameters, vAction, vParams);
	If vRes.Success And pKeyParams.Property("Card") And ValueIsFilled(pKeyParams.Card) Then
		vCardObj = pKeyParams.Card.GetObject();
		vCardObj.ChangeAuthor = SessionParameters.CurrentUser;
		vCardObj.ChangeDate = CurrentSessionDate();
		vCardObj.Identifier = vCardID;
		vCardObj.CardUID = Format(GetBinaryDataBufferFromHexString(vCardID).ReadInt64(0, ByteOrder.BigEndian), "NG=0");
		vCardObj.Write();  
		
		vDoc = vCardObj.ParentDoc;
		
		vEventType = "Card_Replace"; 
		vEventDescription = NStr("en = 'Replace a key in ISD'; de = 'Schlüsselneuausgabe in ISD'; ru = 'Перевыпуск ключа'", CurrentSystemLanguage());
		
		WriteKeyCardSecuritySystemEvent(vDoc.Hotel, vDoc.Room, vEventType, vAction, TrimAll(pKeyParams.KeyOldID) + ">" + vCardID, vEventDescription, vDoc.Guest, vDoc, vDoc.CheckInDate, vDoc.CheckOutDate);
	EndIf;	

	Return vRes;
EndFunction // ClearCard

// --------------------------------------------------------------------------------
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - Ref
//  pKeyParams				 - Structure							 - Parameters
// 
// Returns:
//  Structure - Result call
//
Function GetDetails(pInteractionParameters, pKeyParams) Export 
	vAction  = "getDetails";
	vRes = CallHTTPAction(pInteractionParameters, vAction, pKeyParams);
	Return vRes;
EndFunction // CardInfo

// --------------------------------------------------------------------------------
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - Ref
// 
// Returns:
//  Structure - Result call
//
Function GetParking(pInteractionParameters) Export 

	vAction  = "getParking";
	vRes = CallHTTPAction(pInteractionParameters, vAction);

	Return vRes;
EndFunction // GetParking

// --------------------------------------------------------------------------------
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - Ref
//  pKeyParams				 - Structure							 - Parameters
// 
// Returns:
//  Structure - Result call
//
Function IsReplacedCard(pInteractionParameters, pKeyParams) Export 
	vAction  = "isReplaced";
	vRes = CallHTTPAction(pInteractionParameters, vAction, pKeyParams);
	Return vRes;
EndFunction // IsReplacedCard

// --------------------------------------------------------------------------------
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - Ref
// 
// Returns:
//  Structure - Result call
//
Function GetMassBonusCheck(pInteractionParameters) Export 
	
	vAction  = "massBonusCheck";
	vRes = CallHTTPAction(pInteractionParameters, vAction);
	
	Return vRes;
EndFunction // GetMassBonusCheck  

// --------------------------------------------------------------------------------
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - Ref
//  pKeyParams				 - Structure							 - Parameters
// 
// Returns:
//  Structure - Result call
//
Function GetMassIsReplased(pInteractionParameters, pKeyParams) Export 
	
	vAction  = "massIsReplased";
	vRes = CallHTTPAction(pInteractionParameters, vAction, pKeyParams);
	
	Return vRes;
EndFunction // GetMassIsReplased

// --------------------------------------------------------------------------------
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - Ref
//  pKeyParams				 - Structure							 - Parameters
// 
// Returns:
//  Structure - Result call
//
Function AddHotBonus(pInteractionParameters, pKeyParams) Export 
	
	vAction  = "addHotBonus";
	vRes = CallHTTPAction(pInteractionParameters, vAction, pKeyParams);
	
	Return vRes;
EndFunction // AddHotBonus

// --------------------------------------------------------------------------------
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - Ref
//  pKeyParams				 - Structure							 - Parameters
// 
// Returns:
//  Structure - Result call
//
Function IssueBonusCard(pInteractionParameters, pKeyParams) Export 
	
	vAction  = "newTicket";
	vRes = CallHTTPAction(pInteractionParameters, vAction, pKeyParams);
	
	Return vRes;
EndFunction // AddHotBonus

// --------------------------------------------------------------------------------
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions	 - Ref 
//  pKeyParams				 - Structure - Parameters
//  pAddressStorage			 - String	 - Storage address
//
Procedure GetBonusesTransactions(pInteractionParameters, pKeyParams, pAddressStorage = Undefined) Export
	vResult = New Structure("Balance, Transactions", 0, NewPropertiesForBonusesTransactions());
	
	vAction  = "getBonusDetails";
	vRes = CallHTTPAction(pInteractionParameters, vAction, pKeyParams);
	If vRes.Success Then
		vParams = Catalogs.DataConvertationRules.JSONtoStructure(vRes.RawResponse); 	
		If vParams.Property("bonus_in_total") Then
			vResult.Balance = Number(vParams.bonus_in_total) - Number(vParams.bonus_out_total); 
		EndIf;	 
		If vParams.Property("cardDetails") Then
			For Each vRow In vParams.cardDetails Do
				vNewRow = vResult.Transactions.Add();	
				vNewRow.Date = Date(vRow.dt);
				vNewRow.SalePoint = vRow.detail;
				vNewRow.Operation = vRow.descr; 
				vNewRow.PurchaseAmount = Number(vRow.bonus_in);
			EndDo;	  
			vResult.Transactions.Sort("Date");
		EndIf;	
	EndIf;	  
	
	PutToTempStorage(vResult, pAddressStorage);
EndProcedure

// --------------------------------------------------------------------------------
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - Ref
// 
// Returns:
//  String - PSALID
//
Function GetPSALID(pInteractionParameters) Export
	vISDWorkstationID = "";
	vISDWorkstations = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "Workstation", "ID", SessionParameters.CurrentWorkstation);
	If vISDWorkstations.Count() > 0 Then
		vISDWorkstationID = vISDWorkstations.Get(0).ExternalSystemDataCode;
	EndIf;
	Return vISDWorkstationID;
EndFunction

// --------------------------------------------------------------------------------
//
// Parameters:
//  pDocument	 - DocumentRef.Accommodation - Ref
// 
// Returns:
//  ValueTable - Mapping list
//
Function GetMappingISDByAccommodation(pDocument) Export 
	vResult = New ValueTable();
	vResult.Columns.Add("Document");
	vResult.Columns.Add("CardType");
	vResult.Columns.Add("PackagesHash");
	vResult.Columns.Add("RoomRate");
	vResult.Columns.Add("RoomRateCode");
	vResult.Columns.Add("RoomRateDesc");
	vResult.Columns.Add("ParkingDesc");
	vResult.Columns.Add("ParkingCode");
	vResult.Columns.Add("IsFound");
	vResult.Columns.Add("SortCode");
	vResult.Columns.Add("Quantity");
	vResult.Columns.Add("PeriodFrom");                   
	vResult.Columns.Add("PeriodTo");
    vResult.Columns.Add("UUIDRowMapping");  
	
	If Not ValueIsFilled(pDocument) Or ValueIsFilled(pDocument) And Not TypeOf(pDocument) = Type("DocumentRef.Accommodation") Then
		// Not support
		Return vResult;
	EndIf;	
	// Get ISD interaction
	vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionType(Enums.Integrations.ISD, pDocument.Hotel);
	If Not ValueIsFilled(vInteraction) Then
		Return vResult;
	EndIf;
	// Get one room documents
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Docs.Ref AS Ref
	|INTO vDocs
	|FROM
	|	Document.Accommodation AS Docs
	|WHERE
	|	Docs.Room = &qRoom
	|	AND Docs.GuestGroup = &qGuestGroup
	|	AND Docs.Posted
	|	AND Docs.AccommodationType.DoNotIssueKeyCards = FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	vPackages.Doc AS Doc,
	|	vPackages.ServicePackage AS ServicePackage,
	|	vPackages.ServicePackageCardType AS CardType,
	|	vPackages.RoomRate AS RoomRate,
	|	vPackages.RoomRateCardType AS RoomRateCardType,
	|	CASE
	|		WHEN vPackages.PeriodFrom = DATETIME(1, 1, 1)
	|			THEN vPackages.Doc.CheckInDate
	|		ELSE vPackages.PeriodFrom
	|	END AS PeriodFrom,
	|	CASE
	|		WHEN vPackages.PeriodTo = DATETIME(1, 1, 1)
	|			THEN vPackages.Doc.CheckOutDate
	|		ELSE vPackages.PeriodTo
	|	END AS PeriodTo
	|FROM
	|	(SELECT
	|		Accommodation.Ref AS Doc,
	|		Accommodation.ServicePackage AS ServicePackage,
	|		Accommodation.ServicePackage.IdentificationCardType AS ServicePackageCardType,
	|		Accommodation.RoomRate AS RoomRate,
	|		Accommodation.RoomRate.IdentificationCardType AS RoomRateCardType,
	|		Accommodation.CheckInDate AS PeriodFrom,
	|		Accommodation.CheckOutDate AS PeriodTo
	|	FROM
	|		Document.Accommodation AS Accommodation
	|	WHERE
	|		Accommodation.Ref IN
	|				(SELECT
	|					vDocs.Ref AS Ref
	|				FROM
	|					vDocs AS vDocs)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AccommodationServicePackages.Ref,
	|		AccommodationServicePackages.ServicePackage,
	|		AccommodationServicePackages.ServicePackage.IdentificationCardType,
	|		AccommodationServicePackages.Ref.RoomRate,
	|		AccommodationServicePackages.Ref.RoomRate.IdentificationCardType,
	|		AccommodationServicePackages.DateFrom,
	|		AccommodationServicePackages.DateTo
	|	FROM
	|		Document.Accommodation.ServicePackages AS AccommodationServicePackages
	|	WHERE
	|		AccommodationServicePackages.Ref IN
	|				(SELECT
	|					vDocs.Ref AS Ref
	|				FROM
	|					vDocs AS vDocs)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Accommodation.Ref,
	|		RoomRatesServicePackages.ServicePackage,
	|		RoomRatesServicePackages.ServicePackage.IdentificationCardType,
	|		Accommodation.RoomRate,
	|		Accommodation.RoomRate.IdentificationCardType,
	|		Accommodation.CheckInDate,
	|		Accommodation.CheckOutDate
	|	FROM
	|		Document.Accommodation AS Accommodation
	|			LEFT JOIN Catalog.RoomRates.ServicePackages AS RoomRatesServicePackages
	|			ON Accommodation.RoomRate = RoomRatesServicePackages.Ref
	|	WHERE
	|		Accommodation.Ref IN
	|				(SELECT
	|					vDocs.Ref AS Ref
	|				FROM
	|					vDocs AS vDocs)
	|		AND RoomRatesServicePackages.ServicePackage.IdentificationCardType <> VALUE(Catalog.IdentificationCardTypes.EmptyRef)) AS vPackages
	|
	|GROUP BY
	|	vPackages.Doc,
	|	vPackages.ServicePackage,
	|	vPackages.RoomRateCardType,
	|	vPackages.ServicePackageCardType,
	|	vPackages.RoomRate,
	|	CASE
	|		WHEN vPackages.PeriodFrom = DATETIME(1, 1, 1)
	|			THEN vPackages.Doc.CheckInDate
	|		ELSE vPackages.PeriodFrom
	|	END,
	|	CASE
	|		WHEN vPackages.PeriodTo = DATETIME(1, 1, 1)
	|			THEN vPackages.Doc.CheckOutDate
	|		ELSE vPackages.PeriodTo
	|	END
	|
	|ORDER BY
	|	Doc,
	|	CardType,
	|	PeriodFrom,
	|	PeriodTo";

	vQry.SetParameter("qRoom", pDocument.Room);
	vQry.SetParameter("qGuestGroup", pDocument.GuestGroup);
	
	vOneRoomDocs = vQry.Execute().Unload();
	
	vCardTypes = vOneRoomDocs.Copy(, "CardType");
	vCardTypes.GroupBy("CardType");
	vAllDocs = vOneRoomDocs.Copy(, "Doc");
	vAllDocs.GroupBy("Doc");

	vPackagesByRoom = New ValueTable();
	vPackagesByRoom.Columns.Add("ServicePackage");
	vPackagesByRoom.Columns.Add("PeriodFrom");
	vPackagesByRoom.Columns.Add("PeriodTo");
	vCasheTab = New Array;
	vGuests = New Array;
	vIsForFolioSplit = False;
	
	For Each vDocRow In vAllDocs Do
		vDoc = vDocRow.Doc;
		vRoomRateCardType = vDoc.RoomRate.IdentificationCardType;
		If vIsForFolioSplit = False Then
			vIsForFolioSplit = vDoc.IsForFolioSplit;
		EndIf;
		If vGuests.Find(vDoc) = Undefined Then
			vGuests.Add(vDoc);
		EndIf;	
		vRowCashe = Undefined;
		vListPackages = New ValueList;
		For Each vCardTypeRow In vCardTypes Do
			vCardType = vCardTypeRow.CardType;
			If Not vRowCashe  = Undefined Then 
				vRowCashe.PackagesList = vListPackages;
				vCasheTab.Add(vRowCashe);
				vRowCashe = Undefined;
				vListPackages = New ValueList;
			EndIf;
			If ValueIsFilled(vCardType) Then
				vFilterRows = vOneRoomDocs.FindRows(New Structure("Doc, CardType", vDoc, vCardType));
				For Each vSPRow In vFilterRows Do
					vSP = vSPRow.ServicePackage;
					If ValueIsFilled(vSP) Then
						If vRowCashe  = Undefined Then
							vRowCashe = FillRowCashe(vCardType, vDoc, vRoomRateCardType, vSPRow.PeriodFrom, vSPRow.PeriodTo, vSP);
							vListPackages.Add(vSP);
						Else
							If vRowCashe.CardType = vCardType And BegOfDay(vRowCashe.PeriodFrom) = BegOfDay(vSPRow.PeriodFrom) And  BegOfDay(vRowCashe.PeriodTo) = BegOfDay(vSPRow.PeriodTo) Then
								If vListPackages.FindByValue(vSP) = Undefined Then
									vListPackages.Add(vSP);
								EndIf;
							Else	
								vRowCashe.PackagesList = vListPackages;
								vCasheTab.Add(vRowCashe);
								vRowCashe = FillRowCashe(vCardType, vDoc, vRoomRateCardType, vSPRow.PeriodFrom, vSPRow.PeriodTo, vSP);
								vListPackages = New ValueList;
								vListPackages.Add(vSP);
							EndIf;
						EndIf;	
						If vSP.IsPerPerson = False And vCardType.AskGuestVehicle = False And vPackagesByRoom.FindRows(New Structure("ServicePackage, PeriodFrom, PeriodTo", vSP, vSPRow.PeriodFrom, vSPRow.PeriodTo)).Count() = 0 Then
							vPackagesByRoomRow = vPackagesByRoom.Add();
							vPackagesByRoomRow.ServicePackage = vSP;
							vPackagesByRoomRow.PeriodFrom = vSPRow.PeriodFrom;
							vPackagesByRoomRow.PeriodTo = vSPRow.PeriodTo;
						EndIf;
					Else
						Continue;
					EndIf;	
				EndDo;
			EndIf;
		EndDo;
		If Not vRowCashe  = Undefined Then 
			vRowCashe.PackagesList = vListPackages;
			vCasheTab.Add(vRowCashe);
		EndIf;
		// Let's check the addition of the room rate to the table
		If ValueIsFilled(vRoomRateCardType) Then
			vMainCardAdd = False;
			For Each vCurRowCashe In vCasheTab Do
				If vCurRowCashe.Document = vDoc And vCurRowCashe.CardType = vRoomRateCardType Then
					vMainCardAdd = True;
					Break;
				EndIf;	
			EndDo;	
			If vMainCardAdd = False Then
				vRowCashe = New Structure("Document, CardType, RoomRate, PackagesList, PeriodFrom, PeriodTo");
				vRowCashe.Document = vDoc;
				vRowCashe.CardType = vRoomRateCardType;
				vRowCashe.RoomRate = vDoc.RoomRate;
				vRowCashe.PackagesList = New ValueList;
				vRowCashe.PeriodFrom = vDoc.CheckInDate;
				vRowCashe.PeriodTo = vDoc.CheckOutDate;
				vCasheTab.Add(vRowCashe);
			EndIf;	
		EndIf;	
	EndDo;
	// Add one room packages for each guest 
	If Not vIsForFolioSplit Then 
		For Each vPackagesByRoomRow In vPackagesByRoom Do
			vSP = vPackagesByRoomRow.ServicePackage;
			For Each vGuestDoc In vGuests Do
				vPkgIsSet = False;  
				For Each vCurRowCashe In vCasheTab Do
					If vCurRowCashe.Document = vGuestDoc And vCurRowCashe.CardType = vSP.IdentificationCardType Then
						If vCurRowCashe.PackagesList.FindByValue(vSP) = Undefined And vCurRowCashe.PeriodFrom = vPackagesByRoomRow.PeriodFrom And vCurRowCashe.PeriodTo = vPackagesByRoomRow.PeriodTo Then
							vCurRowCashe.PackagesList.Add(vSP);
							vCurRowCashe.PeriodFrom = vPackagesByRoomRow.PeriodFrom; 
							vCurRowCashe.PeriodTo = vPackagesByRoomRow.PeriodTo;
							vPkgIsSet = True;
							Break;
						Else
							If vCurRowCashe.PeriodFrom = vPackagesByRoomRow.PeriodFrom And vCurRowCashe.PeriodTo = vPackagesByRoomRow.PeriodTo Then 
								vPkgIsSet = True;
								Break;
							EndIf;
						EndIf;	
					EndIf;	
				EndDo;
				If vPkgIsSet = False Then
					vRowCashe = FillRowCashe(vSP.IdentificationCardType, vGuestDoc, Undefined, vPackagesByRoomRow.PeriodFrom, vPackagesByRoomRow.PeriodTo, vSP);
					vListPackagesGuest = New ValueList;
					vListPackagesGuest.Add(vSP);
					vRowCashe.PackagesList = vListPackagesGuest;
					vCasheTab.Add(vRowCashe);
				EndIf;
			EndDo;
		EndDo; 	
	EndIf;
	// Result table
	For Each vCurRowCashe In vCasheTab Do
		vNewRow = vResult.Add();
		vNewRow.Document = vCurRowCashe.Document;
		vNewRow.CardType = vCurRowCashe.CardType;
		vNewRow.RoomRate = vCurRowCashe.RoomRate;
		vPackagesHash = ""; 
		vPackagesList = vCurRowCashe.PackagesList;
		vPackagesList.SortByValue();
		For Each vRowPackg In vPackagesList Do
			If IsBlankString(vPackagesHash) Then
				vPackagesHash = XMLString(vRowPackg.Value);
			Else	
				vPackagesHash = vPackagesHash + "_" + XMLString(vRowPackg.Value);
			EndIf;
		EndDo;
		vNewRow.PackagesHash = vPackagesHash;
		vNewRow.PeriodFrom = vCurRowCashe.PeriodFrom; 
		vNewRow.PeriodTo = vCurRowCashe.PeriodTo;
	EndDo;	
	
	// Fill external codes
	vInd = 0;
	While vInd <= vResult.Count() - 1 Do  
		vTariffs = InformationRegisters.ExternalSystemIntegrationData.GetData(vInteraction, "Tariffs");
		vMappingRow = vResult[vInd];
		vMappingRow.Quantity = 1;   
		vMappingRow.IsFound = True;
		If ValueIsFilled(vMappingRow.CardType) Then
			vMappingRow.SortCode = vMappingRow.CardType.SortCode;
			vUUIDCardType = XMLString(vMappingRow.CardType);
		Else
			vUUIDCardType = "";
			vMappingRow.SortCode = 999;
		EndIf;      
		vTariffs.Sort("ISDCode Desc, ISDParkingCode Desc");
		vFilter = vTariffs.FindRows(New Structure("CardType, Packages, RoomRate, Hotel", vUUIDCardType, vMappingRow.PackagesHash, vMappingRow.RoomRate, vMappingRow.Document.Hotel)); 	
		If vFilter.Count() = 0 Then
			// Add to match
			vUUID = String(New UUID());
			InformationRegisters.ExternalSystemIntegrationData.WriteData(vInteraction, "Tariffs", "RoomRate", vUUID , Undefined, vMappingRow.RoomRate);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(vInteraction, "Tariffs", "Packages", vUUID, Undefined, vMappingRow.PackagesHash);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(vInteraction, "Tariffs", "CardType", vUUID, Undefined, vUUIDCardType);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(vInteraction, "Tariffs", "ISDCode",  vUUID, Undefined, "");
			InformationRegisters.ExternalSystemIntegrationData.WriteData(vInteraction, "Tariffs", "ISDDescription",  vUUID, Undefined, "");
			InformationRegisters.ExternalSystemIntegrationData.WriteData(vInteraction, "Tariffs", "Hotel",  vUUID, Undefined, vMappingRow.Document.Hotel);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(vInteraction, "Tariffs", "ISDParkingCode",  vUUID, Undefined, ""); 
			vMappingRow.IsFound = False;
			vMappingRow.UUIDRowMapping = vUUID;   
		Else    
			vFilterRow = vFilter[0];
			vMappingRow.RoomRateCode = vFilterRow.ISDCode;
			vMappingRow.ParkingCode = vFilterRow.ISDParkingCode;
			vMappingRow.RoomRateDesc = vFilterRow.ISDDescription;
			vMappingRow.ParkingDesc  = vFilterRow.ISDParkingDescription;  
			vMappingRow.UUIDRowMapping = vFilterRow.RefKey1;  
			If IsBlankString(vMappingRow.RoomRateCode) And IsBlankString(vMappingRow.ParkingCode) Then
				vMappingRow.IsFound = False;
			EndIf;	
		EndIf;
		vInd = vInd + 1;                                      
	EndDo;
	vResult.GroupBy("Document, CardType, PackagesHash, RoomRate, PeriodFrom, PeriodTo, RoomRateCode, RoomRateDesc, ParkingDesc, ParkingCode, IsFound, Quantity, SortCode, UUIDRowMapping");
	vResult.Sort("SortCode");	
	Return vResult;
EndFunction // GetMappingISDByAccommodation

// --------------------------------------------------------------------------------
//
// Parameters:
//  pDocument	 - DocumentRef.Reservation	 - Ref
// 
// Returns:
//  ValueTable - Mapping list
//
Function GetMappingISDByReservation(pDocument) Export 
	vResult = New ValueTable();
	vResult.Columns.Add("Document");
	vResult.Columns.Add("CardType");
	vResult.Columns.Add("PackagesHash");
	vResult.Columns.Add("RoomRate");
	vResult.Columns.Add("RoomRateCode");
	vResult.Columns.Add("RoomRateDesc");
	vResult.Columns.Add("ParkingDesc");
	vResult.Columns.Add("ParkingCode");
	vResult.Columns.Add("IsFound");
	vResult.Columns.Add("SortCode");
	vResult.Columns.Add("Quantity");
	vResult.Columns.Add("PeriodFrom");                   
	vResult.Columns.Add("PeriodTo");
	
	If Not ValueIsFilled(pDocument) Or ValueIsFilled(pDocument) And Not TypeOf(pDocument) = Type("DocumentRef.Reservation")  
		Or TypeOf(pDocument) = Type("DocumentRef.Reservation") And pDocument.ReservationStatus.IsInWaitingList = False Then
		// Not support
		Return vResult;
	EndIf;	

	// Get ISD interaction
	vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionType(Enums.Integrations.ISD, pDocument.Hotel);
	If Not ValueIsFilled(vInteraction) Then
		Return vResult;
	EndIf;
	// Get one room documents
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Docs.Ref AS Ref
	|INTO vDocs
	|FROM
	|	Document.Reservation AS Docs
	|WHERE
	|	Docs.Room = &qRoom
	|	AND Docs.GuestGroup = &qGuestGroup
	|	AND Docs.Posted
	|	AND Docs.AccommodationType.DoNotIssueKeyCards = FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	vPackages.Doc AS Doc,
	|	vPackages.ServicePackage AS ServicePackage,
	|	vPackages.ServicePackageCardType AS CardType,
	|	vPackages.RoomRate AS RoomRate,
	|	vPackages.RoomRateCardType AS RoomRateCardType,
	|	CASE
	|		WHEN vPackages.PeriodFrom = DATETIME(1, 1, 1)
	|			THEN vPackages.Doc.CheckInDate
	|		ELSE vPackages.PeriodFrom
	|	END AS PeriodFrom,
	|	CASE
	|		WHEN vPackages.PeriodTo = DATETIME(1, 1, 1)
	|			THEN vPackages.Doc.CheckOutDate
	|		ELSE vPackages.PeriodTo
	|	END AS PeriodTo
	|FROM
	|	(SELECT
	|		Accommodation.Ref AS Doc,
	|		Accommodation.ServicePackage AS ServicePackage,
	|		Accommodation.ServicePackage.IdentificationCardType AS ServicePackageCardType,
	|		Accommodation.RoomRate AS RoomRate,
	|		Accommodation.RoomRate.IdentificationCardType AS RoomRateCardType,
	|		Accommodation.CheckInDate AS PeriodFrom,
	|		Accommodation.CheckOutDate AS PeriodTo
	|	FROM
	|		Document.Reservation AS Accommodation
	|	WHERE
	|		Accommodation.Ref IN
	|				(SELECT
	|					vDocs.Ref AS Ref
	|				FROM
	|					vDocs AS vDocs)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AccommodationServicePackages.Ref,
	|		AccommodationServicePackages.ServicePackage,
	|		AccommodationServicePackages.ServicePackage.IdentificationCardType,
	|		AccommodationServicePackages.Ref.RoomRate,
	|		AccommodationServicePackages.Ref.RoomRate.IdentificationCardType,
	|		AccommodationServicePackages.DateFrom,
	|		AccommodationServicePackages.DateTo
	|	FROM
	|		Document.Reservation.ServicePackages AS AccommodationServicePackages
	|	WHERE
	|		AccommodationServicePackages.Ref IN
	|				(SELECT
	|					vDocs.Ref AS Ref
	|				FROM
	|					vDocs AS vDocs)) AS vPackages
	|
	|GROUP BY
	|	vPackages.Doc,
	|	vPackages.ServicePackage,
	|	vPackages.RoomRateCardType,
	|	vPackages.ServicePackageCardType,
	|	vPackages.RoomRate,
	|	CASE
	|		WHEN vPackages.PeriodFrom = DATETIME(1, 1, 1)
	|			THEN vPackages.Doc.CheckInDate
	|		ELSE vPackages.PeriodFrom
	|	END,
	|	CASE
	|		WHEN vPackages.PeriodTo = DATETIME(1, 1, 1)
	|			THEN vPackages.Doc.CheckOutDate
	|		ELSE vPackages.PeriodTo
	|	END
	|
	|ORDER BY
	|	Doc,
	|	CardType,
	|	PeriodFrom,
	|	PeriodTo";

	vQry.SetParameter("qRoom", pDocument.Room);
	vQry.SetParameter("qGuestGroup", pDocument.GuestGroup);
	
	vOneRoomDocs = vQry.Execute().Unload();
	
	vCardTypes = vOneRoomDocs.Copy(, "CardType");
	vCardTypes.GroupBy("CardType");
	vAllDocs = vOneRoomDocs.Copy(, "Doc");
	vAllDocs.GroupBy("Doc");

	vPackagesByRoom = New ValueTable();
	vPackagesByRoom.Columns.Add("ServicePackage");
	vPackagesByRoom.Columns.Add("PeriodFrom");
	vPackagesByRoom.Columns.Add("PeriodTo");
	vCasheTab = New Array;
	vGuests = New Array;
	vIsForFolioSplit = False;
	
	For Each vDocRow In vAllDocs Do
		vDoc = vDocRow.Doc;
		vRoomRateCardType = vDoc.RoomRate.IdentificationCardType;
		If vIsForFolioSplit = False Then
			vIsForFolioSplit = vDoc.IsForFolioSplit;
		EndIf;
		If vGuests.Find(vDoc) = Undefined Then
			vGuests.Add(vDoc);
		EndIf;	
		vRowCashe = Undefined;
		vListPackages = New ValueList;
		For Each vCardTypeRow In vCardTypes Do
			vCardType = vCardTypeRow.CardType;
			If Not vRowCashe  = Undefined Then 
				vRowCashe.PackagesList = vListPackages;
				vCasheTab.Add(vRowCashe);
				vRowCashe = Undefined;
				vListPackages = New ValueList;
			EndIf;
			If ValueIsFilled(vCardType) Then
				vFilterRows = vOneRoomDocs.FindRows(New Structure("Doc, CardType", vDoc, vCardType));
				For Each vSPRow In vFilterRows Do
					vSP = vSPRow.ServicePackage;
					If ValueIsFilled(vSP) Then
						If vRowCashe  = Undefined Then
							vRowCashe = FillRowCashe(vCardType, vDoc, vRoomRateCardType, vSPRow.PeriodFrom, vSPRow.PeriodTo, vSP);
							vListPackages.Add(vSP);
						Else
							If vRowCashe.CardType = vCardType And BegOfDay(vRowCashe.PeriodFrom) = BegOfDay(vSPRow.PeriodFrom) And  BegOfDay(vRowCashe.PeriodTo) = BegOfDay(vSPRow.PeriodTo) Then
								If vListPackages.FindByValue(vSP) = Undefined Then
									vListPackages.Add(vSP);
								EndIf;
							Else	
								vRowCashe.PackagesList = vListPackages;
								vCasheTab.Add(vRowCashe);
								vRowCashe = FillRowCashe(vCardType, vDoc, vRoomRateCardType, vSPRow.PeriodFrom, vSPRow.PeriodTo, vSP);
								vListPackages = New ValueList;
								vListPackages.Add(vSP);
							EndIf;
						EndIf;	
						If vSP.IsPerPerson = False And vCardType.AskGuestVehicle = False And vPackagesByRoom.FindRows(New Structure("ServicePackage, PeriodFrom, PeriodTo", vSP, vSPRow.PeriodFrom, vSPRow.PeriodTo)).Count() = 0 Then
							vPackagesByRoomRow = vPackagesByRoom.Add();
							vPackagesByRoomRow.ServicePackage = vSP;
							vPackagesByRoomRow.PeriodFrom = vSPRow.PeriodFrom;
							vPackagesByRoomRow.PeriodTo = vSPRow.PeriodTo;
						EndIf;
					Else
						Continue;
					EndIf;	
				EndDo;
			EndIf;
		EndDo;
		If Not vRowCashe  = Undefined Then 
			vRowCashe.PackagesList = vListPackages;
			vCasheTab.Add(vRowCashe);
		EndIf;
		// Let's check the addition of the room rate to the table
		If ValueIsFilled(vRoomRateCardType) Then
			vMainCardAdd = False;
			For Each vCurRowCashe In vCasheTab Do
				If vCurRowCashe.Document = vDoc And vCurRowCashe.CardType = vRoomRateCardType Then
					vMainCardAdd = True;
					Break;
				EndIf;	
			EndDo;	
			If vMainCardAdd = False Then
				vRowCashe = New Structure("Document, CardType, RoomRate, PackagesList, PeriodFrom, PeriodTo");
				vRowCashe.Document = vDoc;
				vRowCashe.CardType = vRoomRateCardType;
				vRowCashe.RoomRate = vDoc.RoomRate;
				vRowCashe.PackagesList = New ValueList;
				vRowCashe.PeriodFrom = vDoc.CheckInDate;
				vRowCashe.PeriodTo = vDoc.CheckOutDate;
				vCasheTab.Add(vRowCashe);
			EndIf;	
		EndIf;	
	EndDo;
	// Add one room packages for each guest 
	If Not vIsForFolioSplit Then 
		For Each vPackagesByRoomRow In vPackagesByRoom Do
			vSP = vPackagesByRoomRow.ServicePackage;
			For Each vGuestDoc In vGuests Do
				vPkgIsSet = False;  
				For Each vCurRowCashe In vCasheTab Do
					If vCurRowCashe.Document = vGuestDoc And vCurRowCashe.CardType = vSP.IdentificationCardType Then
						If vCurRowCashe.PackagesList.FindByValue(vSP) = Undefined And vCurRowCashe.PeriodFrom = vPackagesByRoomRow.PeriodFrom And vCurRowCashe.PeriodTo = vPackagesByRoomRow.PeriodTo Then
							vCurRowCashe.PackagesList.Add(vSP);
							vCurRowCashe.PeriodFrom = vPackagesByRoomRow.PeriodFrom; 
							vCurRowCashe.PeriodTo = vPackagesByRoomRow.PeriodTo;
							vPkgIsSet = True;
							Break;
						Else
							If vCurRowCashe.PeriodFrom = vPackagesByRoomRow.PeriodFrom And vCurRowCashe.PeriodTo = vPackagesByRoomRow.PeriodTo Then 
								vPkgIsSet = True;
								Break;
							EndIf;
						EndIf;	
					EndIf;	
				EndDo;
				If vPkgIsSet = False Then
					vRowCashe = FillRowCashe(vSP.IdentificationCardType, vGuestDoc, Undefined, vPackagesByRoomRow.PeriodFrom, vPackagesByRoomRow.PeriodTo, vSP);
					vListPackagesGuest = New ValueList;
					vListPackagesGuest.Add(vSP);
					vRowCashe.PackagesList = vListPackagesGuest;
					vCasheTab.Add(vRowCashe);
				EndIf;
			EndDo;
		EndDo; 	
	EndIf;
	// Result table
	For Each vCurRowCashe In vCasheTab Do
		vNewRow = vResult.Add();
		vNewRow.Document = vCurRowCashe.Document;
		vNewRow.CardType = vCurRowCashe.CardType;
		vNewRow.RoomRate = vCurRowCashe.RoomRate;
		vPackagesHash = ""; 
		vPackagesList = vCurRowCashe.PackagesList;
		vPackagesList.SortByValue();
		For Each vRowPackg In vPackagesList Do
			If IsBlankString(vPackagesHash) Then
				vPackagesHash = XMLString(vRowPackg.Value);
			Else	
				vPackagesHash = vPackagesHash + "_" + XMLString(vRowPackg.Value);
			EndIf;
		EndDo;
		vNewRow.PackagesHash = vPackagesHash;
		vNewRow.PeriodFrom = vCurRowCashe.PeriodFrom; 
		vNewRow.PeriodTo = vCurRowCashe.PeriodTo;
	EndDo;	
	
	// Fill external codes  
	vUseAccommodationRule = False;
	vUseAccommodationRules = InformationRegisters.ExternalSystemIntegrationData.GetData(vInteraction, "EarlyCheckInRoomRates", "UseAccommodationRules");
	If vUseAccommodationRules.Count() > 0 Then
		vUseAccommodationRule = vUseAccommodationRules[0].UseAccommodationRules;
	EndIf;
	If vUseAccommodationRule Then 
		vTariffs = InformationRegisters.ExternalSystemIntegrationData.GetData(vInteraction, "Tariffs");
		vInd = 0;
		While vInd <= vResult.Count() - 1 Do
			vMappingRow = vResult[vInd];
			vMappingRow.Quantity = 1;
			If ValueIsFilled(vMappingRow.CardType) Then
				vMappingRow.SortCode = vMappingRow.CardType.SortCode;
				vUUIDCardType = XMLString(vMappingRow.CardType);
			Else
				vUUIDCardType = "";
				vMappingRow.SortCode = 999;
			EndIf;       
			vTariffs.Sort("ISDCode Desc, ISDParkingCode Desc");
			vFilter = vTariffs.FindRows(New Structure("CardType, Packages, RoomRate, Hotel", vUUIDCardType, vMappingRow.PackagesHash, vMappingRow.RoomRate, vMappingRow.Document.Hotel)); 	
			If vFilter.Count() = 0 Then
				// Add to match
				vUUID = String(New UUID());
				InformationRegisters.ExternalSystemIntegrationData.WriteData(vInteraction, "Tariffs", "RoomRate", vUUID , Undefined, vMappingRow.RoomRate);
				InformationRegisters.ExternalSystemIntegrationData.WriteData(vInteraction, "Tariffs", "Packages", vUUID, Undefined, vMappingRow.PackagesHash);
				InformationRegisters.ExternalSystemIntegrationData.WriteData(vInteraction, "Tariffs", "CardType", vUUID, Undefined, vUUIDCardType);
				InformationRegisters.ExternalSystemIntegrationData.WriteData(vInteraction, "Tariffs", "ISDCode",  vUUID, Undefined, "");
				InformationRegisters.ExternalSystemIntegrationData.WriteData(vInteraction, "Tariffs", "ISDDescription",  vUUID, Undefined, "");
				InformationRegisters.ExternalSystemIntegrationData.WriteData(vInteraction, "Tariffs", "Hotel",  vUUID, Undefined, vMappingRow.Document.Hotel);
				InformationRegisters.ExternalSystemIntegrationData.WriteData(vInteraction, "Tariffs", "ISDParkingCode",  vUUID, Undefined, "");
			Else
				vFilterRow = vFilter[0];
				vMappingRow.RoomRateCode = vFilterRow.ISDCode;
				vMappingRow.ParkingCode = vFilterRow.ISDParkingCode;
				vMappingRow.RoomRateDesc = vFilterRow.ISDDescription;
				vMappingRow.ParkingDesc  = vFilterRow.ISDParkingDescription;
				If IsBlankString(vMappingRow.RoomRateCode) And IsBlankString(vMappingRow.ParkingCode) Then
					vMappingRow.IsFound = False;    
				Else
					vMappingRow.IsFound = True;
				EndIf;
			EndIf;
			vInd = vInd + 1;                                      
		EndDo;	
	Else	
		vTariffs = InformationRegisters.ExternalSystemIntegrationData.GetData(vInteraction, "EarlyCheckInRoomRates");
		vInd = 0;
		While vInd <= vResult.Count() - 1 Do
			vMappingRow = vResult[vInd];
			vMappingRow.Quantity = 1;
			If ValueIsFilled(vMappingRow.CardType) Then
				vMappingRow.SortCode = vMappingRow.CardType.SortCode;
				vUUIDCardType = XMLString(vMappingRow.CardType);
			Else
				vUUIDCardType = "";
				vMappingRow.SortCode = 999;
			EndIf;    
			vTariffs.Sort("ISDCode Desc, ISDParkingCode Desc");
			vFilter = vTariffs.FindRows(New Structure("CardType, Packages, RoomRate, Hotel", vUUIDCardType, vMappingRow.PackagesHash, vMappingRow.RoomRate, vMappingRow.Document.Hotel)); 	
			If vFilter.Count() = 0 Then
				vFilter = vTariffs.FindRows(New Structure("IsDefault, Hotel", True, vMappingRow.Document.Hotel)); 
				If vFilter.Count() > 0 Then
					vFilterRow = vFilter[0];
					vMappingRow.RoomRateCode = vFilterRow.ISDCode;
					vMappingRow.ParkingCode  = vFilterRow.ISDParkingCode;
					vMappingRow.RoomRateDesc = vFilterRow.ISDDescription;
					vMappingRow.ParkingDesc  = vFilterRow.ISDParkingDescription;
					If IsBlankString(vMappingRow.RoomRateCode) And IsBlankString(vMappingRow.ParkingCode) Then
					vMappingRow.IsFound = False;    
				Else
					vMappingRow.IsFound = True;
				EndIf;
				EndIf;	
			Else            
				vFilterRow = vFilter[0];
				vMappingRow.RoomRateCode = vFilterRow.ISDCode;
				vMappingRow.ParkingCode  = vFilterRow.ISDParkingCode;
				vMappingRow.RoomRateDesc = vFilterRow.ISDDescription;
				vMappingRow.ParkingDesc  = vFilterRow.ISDParkingDescription;
				If IsBlankString(vMappingRow.RoomRateCode) And IsBlankString(vMappingRow.ParkingCode) Then
					vMappingRow.IsFound = False;    
				Else
					vMappingRow.IsFound = True;
				EndIf;
			EndIf;
			
			vInd = vInd + 1;                                      
		EndDo; 
	EndIf;
	vResult.GroupBy("Document, CardType, PackagesHash, RoomRate, PeriodFrom, PeriodTo, RoomRateCode, RoomRateDesc, ParkingDesc, ParkingCode, IsFound, Quantity, SortCode");
	vResult.Sort("SortCode");
	
	Return vResult;
EndFunction // GetMappingISDByAccommodation

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
Function ProcessAPICallEception(pInteractionParameters, pExceptionText, pAction, pSOAPXML)
	vResult = New Structure("Success, StatusDescription, RawResponse", False, pExceptionText, "Runtime exception");
	InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, pAction, Enums.ExternalSystemEventTypes.Error, pSOAPXML, pExceptionText);
	Return vResult;
EndFunction // ProcessAPICallEception

// --------------------------------------------------------------------------------
Function CallHTTPAction(pInteractionParameters, pAction, vParams = Undefined)
	vResult = New Structure ("Success, RawResponse, StatusDescription, MapResponse", False, , "");
	Try
		vPort = Undefined;
		If pInteractionParameters.HttpPort <> 0 Then
			vPort = pInteractionParameters.HttpPort;
		EndIf;	
		vUsr = TrimAll(pInteractionParameters.Login);
		vPwd = TrimAll(pInteractionParameters.Password);
		vSSL = Undefined;
		If pInteractionParameters.HTTPUseSSL Then
			vSSL = New OpenSSLSecureConnection(Undefined, Undefined);       	
		EndIf;
		
		// HTTP header
		vHTTPHeaders = New Map;
		vHTTPHeaders.Insert("Content-Type", "application/json;charset=utf-8");
		
		// HTTP connection
		vHTTPConnection = New HTTPConnection(pInteractionParameters.HttpServer, vPort, vUsr, vPwd, , , vSSL);
		
		vRequest = "?cmd=" + pAction;
		
		If Not vParams = Undefined Then
			For Each vKeyAndValue In vParams Do
				vRequest = vRequest + "&" + vKeyAndValue.Key + "=" + vKeyAndValue.Value;
			EndDo;
		EndIf; 
		// Send data
		vHTTPRequest = New HTTPRequest(vRequest, vHTTPHeaders);
		vResponse = vHTTPConnection.Get(vHTTPRequest);
		vJSONResponse = vResponse.GetBodyAsString();
		If vParams = Undefined Then
			vParams = New Structure ("Action", pAction);
		Else
			vParams.Insert("Action", pAction);
		EndIf;
		vJSONRequest = "";
		Try
			vJSONSettings	= New JSONWriterSettings(JSONLineBreak.Auto, Chars.Tab);
			vJSONWriter 	= New JSONWriter;
			vJSONWriter.SetString(vJSONSettings);	
			WriteJSON(vJSONWriter, vParams);
			vJSONRequest = vJSONWriter.Close();
		Except	
		EndTry;
		If IsBlankString(vJSONRequest) Then
			vJSONRequest = vRequest; 
		EndIf;	
		vDesc = "";
		// Log data exchange in debug mode
		If vResponse.StatusCode = 200 Then
			// Check response
			vRes = Catalogs.DataConvertationRules.JSONtoMap(vJSONResponse);
			vResult.Success = vRes.Get("result");
			vResult.MapResponse = vRes;
			vResult.RawResponse = vJSONResponse;
			vDesc = vRes.Get("descr");
			If vResult.Success = False Then
				vResult.StatusDescription = vDesc;
			EndIf;	
			If pInteractionParameters.DebugMode Then
				If vResult.Success = False Then
					vEvent = Enums.ExternalSystemEventTypes.Warning;
				Else
					vEvent = Enums.ExternalSystemEventTypes.Success;
				EndIf;	
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, pAction, vEvent, vJSONRequest, vJSONResponse, vDesc);
			EndIf;
		Else
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, pAction, Enums.ExternalSystemEventTypes.Warning, vJSONRequest, vJSONResponse, vDesc);
			vExceptionText = Nstr("en = 'No connection to ISD server!'; de = 'Keine Verbindung zum ISD-Server!'; ru = 'Нет связи с сервером ISD!'");
			vResult = ProcessAPICallEception(pInteractionParameters, vExceptionText, pAction, vJSONRequest);
		EndIf;
	Except
		// Log exception
		vExceptionText = cmGetRootErrorDescription(ErrorInfo());
		vExceptionText = Nstr("en = 'No connection to ISD server!'; de = 'Keine Verbindung zum ISD-Server!'; ru = 'Нет связи с сервером ISD!'") + " " + vExceptionText;
		vResult = ProcessAPICallEception(pInteractionParameters, vExceptionText, pAction, vJSONRequest);
	EndTry;
	
	Return vResult;
EndFunction // CallSOAPAction

// --------------------------------------------------------------------------------
Function GetListOfReservationCustomFields() 
	vFields = "NORDERBAR,NORDER,NTICKET";
	vArrFields = StrSplit(vFields, ",");
	vRes = New Structure(vFields);
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ReservationCustomAttributes.Ref AS Ref
	|FROM
	|	ChartOfCharacteristicTypes.ReservationCustomAttributes AS ReservationCustomAttributes
	|WHERE
	|	NOT ReservationCustomAttributes.DeletionMark
	|	AND ReservationCustomAttributes.Code IN(&qCodeList)
	|	AND ReservationCustomAttributes.IsFolder = FALSE
	|
	|GROUP BY
	|	ReservationCustomAttributes.Ref
	|
	|ORDER BY
	|	ReservationCustomAttributes.SortCode";
	vQry.SetParameter("qCodeList", vArrFields);
	vCustFields = vQry.Execute().Select();
	While vCustFields.Next() Do
	      vRes[TrimAll(vCustFields.Ref.Code)] = vCustFields.Ref; 
	EndDo; 
	
	Return vRes;
EndFunction // cmGetListOfReservationCustomFields

// -----------------------------------------------------------------------------
// Description: Returns list of one room accommodations for the given room and guest group
// Parameters: Room item reference, Guest group item reference, Accommodation period
// Return value: Value table with one room accommodations
// -----------------------------------------------------------------------------
Function GetOneRoomAccommodations(pRoom, pGuestGroup, pCheckInDate, pCheckOutDate, pNumber = "") Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Docs.Ref AS Ref,
	|	Docs.AccommodationType AS AccommodationType,
	|	Docs.AccommodationType.Type AS AccommodationTypeType,
	|	Docs.SortCode AS SortCode
	|FROM
	|	Document.Accommodation AS Docs
	|WHERE
	|	Docs.Room = &qRoom
	|	AND Docs.GuestGroup = &qGuestGroup
	|	AND (&qNumberIsFilled
	|				AND Docs.Number = &qNumber
	|			OR NOT &qNumberIsFilled)
	|	AND Docs.Posted
	|	AND Docs.AccommodationStatus.IsActive
	|	AND Docs.CheckInDate < &qCheckOutDate
	|	AND Docs.CheckOutDate > &qCheckInDate
	|	AND NOT Docs.RoomType.IsVirtual
	|
	|ORDER BY
	|	Docs.Date,
	|	Docs.PointInTime";
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vQry.SetParameter("qCheckInDate", pCheckInDate);
	vQry.SetParameter("qCheckOutDate", pCheckOutDate);
	vQry.SetParameter("qNumber", pNumber);
	vQry.SetParameter("qNumberIsFilled", ValueIsFilled(pNumber));
	vOneRoomDocs = vQry.Execute().Unload();
	Return vOneRoomDocs;
EndFunction // GetOneRoomAccommodations

// --------------------------------------------------------------------------------
Function GetOneCheckOutRoomAccommodations(pDoc)
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref AS Reservation,
	|	Accommodation.Date AS Date,
	|	Accommodation.Number AS Number,
	|	Accommodation.Posted AS Posted,
	|	Accommodation.AccommodationStatus AS Status,
	|	Accommodation.Guest AS Guest,
	|	Accommodation.Room AS Room,
	|	Accommodation.AccommodationType AS AccommodationType,
	|	Accommodation.AccommodationType.SortCode AS AccommodationTypeSortCode,
	|	Accommodation.NumberOfPersonsPerRoom AS NumberOfPersonsPerRoom,
	|	ISNULL(Accommodation.Room.SortCode, 0) AS RoomSortCode,
	|	Accommodation.PointInTime AS PointInTime
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.GuestGroup = &qGuestGroup
	|	AND Accommodation.Posted
	|	AND Accommodation.Number = &qNumber
	|	AND Accommodation.AccommodationStatus.IsActive = TRUE
	|	AND Accommodation.AccommodationStatus.IsInHouse = FALSE
	|	AND Accommodation.AccommodationStatus.IsCheckOut = TRUE
	|
	|ORDER BY
	|	RoomSortCode,
	|	AccommodationTypeSortCode,
	|	Number,
	|	Date,
	|	PointInTime";
	vQry.SetParameter("qGuestGroup", pDoc.GuestGroup);
	vQry.SetParameter("qNumber", pDoc.Number);
	vDocs = vQry.Execute().Unload();

	Return vDocs;
EndFunction

// --------------------------------------------------------------------------------
Function FillRowCashe(pCardType, pDoc, pRoomRateCardType, pPeriodFrom, pPeriodTo, pSP)
	
	vRowCashe = New Structure("Document, CardType, RoomRate, PackagesList, PeriodFrom, PeriodTo");
	vRowCashe.Document = pDoc;
	vRowCashe.CardType = pCardType;
	If pCardType = pRoomRateCardType Then
		vRowCashe.RoomRate = pDoc.RoomRate;
	ElsIf Not ValueIsFilled(pCardType) And ValueIsFilled(pRoomRateCardType) Then
		vRowCashe.RoomRate = pDoc.RoomRate;
		vRowCashe.CardType =  pRoomRateCardType;
	Else
		vRowCashe.RoomRate = Catalogs.RoomRates.EmptyRef();
	EndIf;
	vPeriodFrom = pDoc.CheckInDate;
	If ValueIsFilled(pSP.DateValidFrom) Then
		If ValueIsFilled(pPeriodFrom) Then
			vPeriodFrom = BegOfDay(pPeriodFrom) + (pDoc.CheckInDate - BegOfDay(pDoc.CheckInDate));
		EndIf;
		If BegOfDay(vPeriodFrom) < BegOfDay(pSP.DateValidFrom) Then
			 vPeriodFrom = BegOfDay(pSP.DateValidFrom) + (pDoc.CheckInDate - BegOfDay(pDoc.CheckInDate));
		EndIf;	
	Else	
		If ValueIsFilled(pPeriodFrom) Then
			vPeriodFrom = BegOfDay(pPeriodFrom) + (pDoc.CheckInDate - BegOfDay(pDoc.CheckInDate));
		EndIf;	
	EndIf;
	vPeriodTo = pDoc.CheckOutDate;
	If ValueIsFilled(pSP.DateValidTo) Then
		If ValueIsFilled(pPeriodTo) Then
			vPeriodTo = BegOfDay(pPeriodTo) + (pDoc.CheckOutDate - BegOfDay(pDoc.CheckOutDate));
		EndIf;
		If BegOfDay(vPeriodTo) > BegOfDay(pSP.DateValidTo) Then
			 vPeriodTo = BegOfDay(pSP.DateValidTo) + (pDoc.CheckOutDate - BegOfDay(pDoc.CheckOutDate));
		EndIf;
	Else	
		If ValueIsFilled(pPeriodTo) Then
			vPeriodTo = BegOfDay(pPeriodTo) + (pDoc.CheckOutDate - BegOfDay(pDoc.CheckOutDate));
		EndIf;
	EndIf;
	vCardType = vRowCashe.CardType;
	If ValueIsFilled(vCardType) Then
		If ValueIsFilled(vCardType.BeginTime) Then
			vPeriodFrom = BegOfDay(vPeriodFrom) + (vCardType.BeginTime - Date(1, 1, 1));
		EndIf;
		If vCardType.SubtractMinutes <> 0 Then
			vPeriodFrom = vPeriodFrom - vCardType.SubtractMinutes * 60;
		EndIf;
		If ValueIsFilled(vCardType.ExpirationTime) Then
			vPeriodTo = BegOfDay(vPeriodTo) + (vCardType.ExpirationTime - Date(1, 1, 1));
		EndIf;
		If vCardType.AddMinutes <> 0 And BegOfDay(vPeriodTo) <> BegOfDay(pDoc.CheckOutDate) Then
			vPeriodTo = vPeriodTo + vCardType.AddMinutes * 60;
		EndIf;
	EndIf;

	vRowCashe.PeriodFrom = vPeriodFrom; 
	vRowCashe.PeriodTo = vPeriodTo;
	Return vRowCashe;

EndFunction // FillRowCashe

// --------------------------------------------------------------------------------
Function NewPropertiesForBonusesTransactions()	
	
	vNewTable = New ValueTable();
	vNewTable.Columns.Add("Date",				New TypeDescription("Date"));
	vNewTable.Columns.Add("Status",				New TypeDescription("String"));
	vNewTable.Columns.Add("Operation",			New TypeDescription("String"));
	vNewTable.Columns.Add("SalePoint",			New TypeDescription("String"));
	vNewTable.Columns.Add("Author",				New TypeDescription("String"));
	vNewTable.Columns.Add("PurchaseAmount",		New TypeDescription("Number"));
	vNewTable.Columns.Add("PaymentAmount",		New TypeDescription("Number"));
	vNewTable.Columns.Add("BonusesSum",			New TypeDescription("Number"));
	vNewTable.Columns.Add("BonusAccumulated",	New TypeDescription("Number"));
	vNewTable.Columns.Add("BonusPresent",		New TypeDescription("Number"));
	vNewTable.Columns.Add("BonusAction",		New TypeDescription("Number"));
	
	Return vNewTable;
EndFunction // NewPropertiesForBonusesTransactions

// --------------------------------------------------------------------------------
Procedure WriteKeyCardSecuritySystemEvent(pHotel, pRoom, pEventType, pCardType, pCardCode, pEventDescription, pGuest, pDoc, pPeriodFrom, pPeriodTo, pNumberOfKeys = 1, pGroupOfKeys = 0)
	
	// Write record to the information register
	vRecMgr = InformationRegisters.SafetySystemEvents.CreateRecordManager();
	vRecMgr.Period = CurrentSessionDate();
	vRecMgr.Author = SessionParameters.CurrentUser;
	vRecMgr.Hotel = pHotel;
	vRecMgr.Room = pRoom;
	vRecMgr.EventType = pEventType;
	vRecMgr.CardType = Upper(pCardType);
	vRecMgr.CardCode = pCardCode;
	vRecMgr.EventDescription = pEventDescription;
	vRecMgr.IsActive = True;
	vRecMgr.Guest = pGuest;
	vRecMgr.ParentDoc = pDoc;
	vRecMgr.PeriodFrom = pPeriodFrom;
	vRecMgr.PeriodTo = pPeriodTo;
	vRecMgr.NumberOfKeys = pNumberOfKeys;
	vRecMgr.KeysSet = pGroupOfKeys;
	vRecMgr.Write();
	
EndProcedure //  WriteKeyCardSecuritySystemEvent()

#EndRegion
