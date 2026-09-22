
#Region Public

// -----------------------------------------------------------------------------
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// NOTHING SO FAR
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	#IF CLIENT THEN
		OpenForm("DataProcessor.GuestJoyExport.Form.Form",New Structure("DataProcessor",ThisObject.DataProcessor));
	#ELSE
		ExportData();	
	#ENDIF
EndProcedure // pmRun

// -----------------------------------------------------------------------------
Procedure ExportData() Export
	
	vPeriodFrom = InteractionParameters.LastFullSynchronizationTime;
	If NOT ValueIsFilled(vPeriodFrom) Then
		vPeriodFrom = CurrentSessionDate();
	EndIf;
	
	vDataTable = GetChangedReservations(vPeriodFrom, InteractionParameters);
	
	vColumnNameStructure = New Structure;
	vColumnNameStructure.Insert("ConfNumber","reservationId");
	vColumnNameStructure.Insert("ArrivalDate","dateArrival");
	vColumnNameStructure.Insert("DepartureDate","dateDeparture");
	vColumnNameStructure.Insert("ReservationStatusCode","status");
	vColumnNameStructure.Insert("RoomTypeCode","roomTypeCode");
	vColumnNameStructure.Insert("RoomType","roomTypeName");
	vColumnNameStructure.Insert("RoomNo","roomNumber");
	vColumnNameStructure.Insert("CreationDate","dateCreated");
	vColumnNameStructure.Insert("dateModified","dateModified"); //?
	vColumnNameStructure.Insert("Adults","adults");
	vColumnNameStructure.Insert("Children","children");
	vColumnNameStructure.Insert("NumberOfInfants","infants");
	vColumnNameStructure.Insert("sourceChannel","sourceChannel"); //?
	vColumnNameStructure.Insert("Customer","company");
	vColumnNameStructure.Insert("MarketingCodeCode","segmentCode");
	vColumnNameStructure.Insert("MarketingCodeDescription","segmentName");
	vColumnNameStructure.Insert("RoomRateCode","rateCode");
	vColumnNameStructure.Insert("RoomRate","rateName");
	vColumnNameStructure.Insert("RateAmount","ratePrice");
	vColumnNameStructure.Insert("TotalAmount","totalAmount");	
	vColumnNameStructure.Insert("CurrencyCode","currency");
	vColumnNameStructure.Insert("campaignCode","campaignCode"); //?
	vColumnNameStructure.Insert("campaignName","campaignName"); //?
	vColumnNameStructure.Insert("reservationTypeCode","reservationTypeCode"); //?
	vColumnNameStructure.Insert("reservationTypeName","reservationTypeName"); //?
	vColumnNameStructure.Insert("GuestCode","guestId");
	vColumnNameStructure.Insert("Email","email");
	vColumnNameStructure.Insert("FirstName","nameFirst");
	vColumnNameStructure.Insert("LastName","nameLast");
	vColumnNameStructure.Insert("Title","nameTitle");
	vColumnNameStructure.Insert("PhoneNumber","phone");
	vColumnNameStructure.Insert("GuestDateOfBirth","dateOfBirth");
	vColumnNameStructure.Insert("GuestSexCode","gender");
	vColumnNameStructure.Insert("GuestLanguage","language");  
	vColumnNameStructure.Insert("GuestCitizenship","nationality");
	vColumnNameStructure.Insert("GuestCitizenship","country");  //?
	vColumnNameStructure.Insert("GuestAddress","address");
	
	vDataTable = FormatDataTable(vDataTable, vColumnNameStructure);
	
	vJSONStructure = New Structure();
	vJSONStructure.Insert("propertyId", 	InteractionParameters.Hotel);
	vJSONStructure.Insert("reservations", 	vDataTable);
	
	vJSONString = Catalogs.DataConvertationRules.MapToJSON(vJSONStructure, "DF=yyyy-MM-dd");
	
	SendDataToGuestJoy(InteractionParameters, vJSONString);
	
EndProcedure

// -----------------------------------------------------------------------------
Function SendDataToGuestJoy(pInteractionParameters, pJSON, pGetRaw = False) Export
	
	vResult 		= New Structure("Success, Error, Raw, Result", False, "", "", Undefined);
	vResponse		= Undefined;
	vMethod 		= "POST";	
	Try
		If Not ValueIsFilled(pInteractionParameters) Then
			vResult.Success = False;
			vResult.Error 	= "Empty InterectionParameters";
			Return vResult;
		EndIf;
		
		vRequestHeaders 				= New Structure("Accept, Authorization");
		vRequestHeaders.Accept 			= "application/json";

		vRequestParameters = New Structure;
		vRequestParameters.Insert("token", pInteractionParameters.InteractionID);
		
		vURL			= pInteractionParameters.HttpAddress;
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInteractionParameters, vRequestHeaders, vURL, vMethod, "guest-import", pJSON, "application/json",, vRequestParameters);
		
	Except
		vResult.Success = False;
		vResult.Error	= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		vRawValue 		= Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "guest-import", vLogEventType, ,vRawValue , vResult.Error);
	EndTry;
	
	If pGetRaw = True Then
		vRawValue = Undefined;
		If vResponse <> Undefined Then
			vRawValue = vResponse.Body;	
		EndIf;
		vResult.Raw = vRawValue;	
	EndIf;
	
	Return vResult;
	
EndFunction

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetChangedReservations(pPeriodFrom, pInteractionParameters)
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	Docs.Reservation.SortCode AS SortCode,
		|	Docs.Reservation.Number AS ConfNumber,
		|	Docs.Reservation.ReservationStatus AS ReservationStatus,
		|	Docs.Reservation.CheckInDate AS ArrivalDate,
		|	Docs.Reservation.CheckOutDate AS DepartureDate,
		|	Docs.Reservation.Guest.Salutation.Description AS Title,
		|	Docs.Reservation.Guest.FirstName AS FirstName,
		|	Docs.Reservation.Guest.LastName AS LastName,
		|	Docs.Reservation.Guest.SecondName AS MiddleName,
		|	CASE
		|		WHEN Docs.Reservation.Phone = """"
		|			THEN Docs.Reservation.Guest.Phone
		|		ELSE Docs.Reservation.Phone
		|	END AS PhoneNumber,
		|	CASE
		|		WHEN Docs.Reservation.EMail = """"
		|			THEN Docs.Reservation.Guest.EMail
		|		ELSE Docs.Reservation.EMail
		|	END AS Email,
		|	Docs.Reservation.NumberOfAdults AS Adults,
		|	Docs.Reservation.NumberOfTeenagers + Docs.Reservation.NumberOfChildren AS Children,
		|	Docs.Reservation.ClientType AS VipCode,
		|	Docs.Reservation.GuestGroup.Description AS GroupNameID,
		|	Docs.Reservation.Customer.Description AS CompanyName,
		|	Docs.Reservation.RoomRate AS RoomRate,
		|	Docs.Reservation.RoomType AS RoomType,
		|	Docs.Reservation.Room.Description AS RoomNo,
		|	Docs.Reservation.Date AS CreationDate,
		|	Docs.Reservation.Remarks AS Comments,
		|	Docs.Reservation.Ref AS Ref,
		|	Docs.Reservation.Number AS Number,
		|	Docs.Reservation.AccommodationTemplate AS AccommodationTemplate,
		|	Docs.Reservation.Duration AS Duration,
		|	Docs.Reservation.Hotel AS Hotel,
		|	Docs.Reservation.AccommodationStatus AS AccommodationStatus,
		|	Docs.Reservation.NumberOfInfants AS NumberOfInfants,
		|	Docs.Reservation.Customer AS Customer,
		|	Docs.Reservation.MarketingCode AS MarketingCode,
		|	Docs.Reservation.Guest.Code AS GuestCode,
		|	Docs.Reservation.Guest.Sex AS GuestSex,
		|	Docs.Reservation.Guest.Citizenship AS GuestCitizenship,
		|	Docs.Reservation.Guest.Address AS GuestAddress,
		|	Docs.Reservation.Guest.DateOfBirth AS GuestDateOfBirth,
		|	Docs.Reservation.Guest.Language AS GuestLanguage
		|INTO ReservationsData
		|FROM
		|	(SELECT
		|		ReservationChangeHistory.Reservation AS Reservation
		|	FROM
		|		InformationRegister.ReservationChangeHistory AS ReservationChangeHistory
		|	WHERE
		|		ReservationChangeHistory.Period >= &qPeriodFrom
		|		AND ReservationChangeHistory.Hotel = &qHotel
		|		AND ReservationChangeHistory.Reservation.Posted
		|		AND ReservationChangeHistory.Reservation.Guest <> VALUE(Catalog.Clients.EmptyRef)
		|		AND ReservationChangeHistory.Reservation.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
		|		AND NOT ReservationChangeHistory.Reservation.ReservationStatus.IsCheckIn
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		AccommodationChangeHistory.Accommodation
		|	FROM
		|		InformationRegister.AccommodationChangeHistory AS AccommodationChangeHistory
		|	WHERE
		|		AccommodationChangeHistory.Period >= &qPeriodFrom
		|		AND AccommodationChangeHistory.Hotel = &qHotel
		|		AND AccommodationChangeHistory.Accommodation.Posted
		|		AND AccommodationChangeHistory.Accommodation.Guest <> VALUE(Catalog.Clients.EmptyRef)
		|		AND AccommodationChangeHistory.Accommodation.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
		|		AND AccommodationChangeHistory.Accommodation.AccommodationStatus.IsActive) AS Docs
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SUM(ReservationServices.Sum - ReservationServices.DiscountSum) AS TotalAmount,
		|	ReservationsData.Ref AS Ref,
		|	ReservationServices.FolioCurrency AS FolioCurrency
		|INTO ReservationsTotalAmount
		|FROM
		|	ReservationsData AS ReservationsData
		|		LEFT JOIN Document.Reservation.Services AS ReservationServices
		|		ON ReservationsData.Number = ReservationServices.Ref.Number
		|WHERE
		|	NOT ReservationServices.Ref.DeletionMark
		|	AND ReservationServices.Ref.Posted
		|
		|GROUP BY
		|	ReservationsData.Ref,
		|	ReservationServices.FolioCurrency
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ReservationsData.SortCode AS SortCode,
		|	ReservationsData.ConfNumber AS ConfNumber,
		|	ReservationsData.ReservationStatus AS ReservationStatus,
		|	ReservationsData.ArrivalDate AS ArrivalDate,
		|	ReservationsData.DepartureDate AS DepartureDate,
		|	ReservationsData.Title AS Title,
		|	ReservationsData.FirstName AS FirstName,
		|	ReservationsData.LastName AS LastName,
		|	ReservationsData.MiddleName AS MiddleName,
		|	ReservationsData.PhoneNumber AS PhoneNumber,
		|	ReservationsData.Email AS Email,
		|	ReservationsData.Adults AS Adults,
		|	ReservationsData.Children AS Children,
		|	ReservationsData.VipCode AS VipCode,
		|	ReservationsData.GroupNameID AS GroupNameID,
		|	ReservationsData.CompanyName AS CompanyName,
		|	ReservationsData.RoomType AS RoomType,
		|	ReservationsData.RoomNo AS RoomNo,
		|	ReservationsData.CreationDate AS CreationDate,
		|	ReservationsData.Comments AS Comments,
		|	ReservationsTotalAmount.TotalAmount AS TotalAmount,
		|	ReservationsTotalAmount.FolioCurrency AS FolioCurrency,
		|	ReservationsData.Hotel AS Hotel,
		|	CASE
		|		WHEN ReservationsData.Duration = 0
		|			THEN ReservationsTotalAmount.TotalAmount
		|		ELSE ReservationsTotalAmount.TotalAmount / ReservationsData.Duration
		|	END AS RateAmount,
		|	ReservationsData.AccommodationTemplate AS AccommodationTemplate,
		|	ReservationsData.RoomRate AS RoomRate,
		|	ReservationsData.Ref AS Ref,
		|	ReservationsData.AccommodationStatus AS AccommodationStatus,
		|	ReservationsData.NumberOfInfants AS NumberOfInfants,
		|	ReservationsData.Customer AS Customer,
		|	ReservationsData.MarketingCode AS MarketingCode,
		|	ReservationsData.GuestCode AS GuestCode,
		|	ReservationsData.GuestSex AS GuestSex,
		|	ReservationsData.GuestCitizenship AS GuestCitizenship,
		|	ReservationsData.GuestAddress AS GuestAddress,
		|	ReservationsData.GuestDateOfBirth AS GuestDateOfBirth,
		|	ReservationsData.GuestLanguage AS GuestLanguage
		|INTO ReservationsFullData
		|FROM
		|	ReservationsData AS ReservationsData
		|		LEFT JOIN ReservationsTotalAmount AS ReservationsTotalAmount
		|		ON ReservationsData.Ref = ReservationsTotalAmount.Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP ReservationsData
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP ReservationsTotalAmount
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ReservationsFullData.SortCode AS SortCode,
		|	ReservationsFullData.ConfNumber AS ConfNumber,
		|	ISNULL(ReservationsFullData.AccommodationStatus, ReservationsFullData.ReservationStatus) AS ReservationStatus,
		|	ReservationsFullData.ArrivalDate AS ArrivalDate,
		|	ReservationsFullData.DepartureDate AS DepartureDate,
		|	ReservationsFullData.Title AS Title,
		|	ReservationsFullData.FirstName AS FirstName,
		|	ReservationsFullData.LastName AS LastName,
		|	ReservationsFullData.MiddleName AS MiddleName,
		|	ReservationsFullData.PhoneNumber AS PhoneNumber,
		|	ReservationsFullData.Email AS Email,
		|	ReservationsFullData.Adults AS Adults,
		|	ReservationsFullData.Children AS Children,
		|	ReservationsFullData.VipCode AS VipCode,
		|	ReservationsFullData.GroupNameID AS GroupNameID,
		|	ReservationsFullData.CompanyName AS CompanyName,
		|	ReservationsFullData.RoomType AS RoomType,
		|	ReservationsFullData.RoomNo AS RoomNo,
		|	ReservationsFullData.CreationDate AS CreationDate,
		|	ReservationsFullData.Comments AS Comments,
		|	ReservationsFullData.TotalAmount AS TotalAmount,
		|	ReservationsFullData.FolioCurrency AS Currency,
		|	ReservationsFullData.Hotel AS Hotel,
		|	ReservationsFullData.RateAmount AS RateAmount,
		|	ReservationsFullData.AccommodationTemplate AS AccommodationTemplate,
		|	ReservationsFullData.RoomRate AS RoomRate,
		|	PRESENTATION(ReservationsFullData.RoomRate.Code) AS RoomRateCode,
		|	PRESENTATION(ISNULL(ReservationsFullData.AccommodationStatus.Code, ReservationsFullData.ReservationStatus.Code)) AS ReservationStatusCode,
		|	PRESENTATION(ReservationsFullData.AccommodationTemplate.Code) AS AccommodationTemplateCode,
		|	PRESENTATION(ReservationsFullData.FolioCurrency.Code) AS CurrencyCode,
		|	PRESENTATION(ReservationsFullData.RoomType.Code) AS RoomTypeCode,
		|	ReservationsFullData.NumberOfInfants AS NumberOfInfants,
		|	ReservationsFullData.Customer AS Customer,
		|	ReservationsFullData.MarketingCode.Description AS MarketingCodeDescription,
		|	ReservationsFullData.MarketingCode.Code AS MarketingCodeCode,
		|	ReservationsFullData.GuestCode AS GuestCode,
		|	ReservationsFullData.GuestCitizenship.ISOCode3 AS GuestCitizenship,
		|	ReservationsFullData.GuestAddress AS GuestAddress,
		|	ReservationsFullData.GuestDateOfBirth AS GuestDateOfBirth,
		|	ReservationsFullData.GuestLanguage AS GuestLanguage,
		|	ReservationsFullData.GuestSex AS GuestSex,
		|	""Unknown"" AS GuestSexCode
		|FROM
		|	ReservationsFullData AS ReservationsFullData";
	vQuery.SetParameter("qPeriodFrom",	pPeriodFrom);
	vQuery.SetParameter("qHotel", 		pInteractionParameters.Hotel);
	vData = vQuery.Execute().Unload();
	
	If vData.Count() > 0 Then
		vResStatuses 	= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "reservationStatuses");
		vAccStatuses 	= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "accommodationStatuses");
		vRoomTypes 		= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomTypes");
		vCurrencies 	= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "currencies");
		vRoomRates 		= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "roomRates");
		vAccTemplates 	= InformationRegisters.ExternalSystemIntegrationData.GetData(pInteractionParameters, "AccommodationTemplates");
		For each vRow in vData Do
			vResStatus 	= vResStatuses.Find(vRow.ReservationStatus, 		"RefKey1");
			vAccStatus 	= vAccStatuses.Find(vRow.ReservationStatus, 		"RefKey1");
			vRoomType 	= vRoomTypes.Find(vRow.RoomType, 					"RefKey1");
			vCurrency 	= vCurrencies.Find(vRow.Currency, 					"RefKey1");
			vRoomRate 	= vRoomRates.Find(vRow.RoomRate, 					"RefKey1");
			vAccTemplate= vAccTemplates.Find(vRow.AccommodationTemplate, 	"RefKey1");
			
			If vResStatus <> Undefined Then
				vRow.ReservationStatusCode = vResStatus.id;
			EndIf;
			
			If vAccStatus <> Undefined Then
				vRow.ReservationStatusCode = vAccStatus.id;
			EndIf;
			
			If vRoomType <> Undefined Then
				vRow.RoomTypeCode = vRoomType.id;
			EndIf;

			If vCurrency <> Undefined Then
				vRow.CurrencyCode = vCurrency.id;
			EndIf;

			If vRoomRate <> Undefined Then
				vRow.RoomRateCode = vRoomRate.id;
			EndIf;

			If vAccTemplate <> Undefined Then
				vRow.AccommodationTemplateCode = vAccTemplate.id;
			EndIf;

			If vRow.GuestSex = Enums.Sex.Male Then
				vRow.GuestSexCode = "Male";	
			ElsIf vRow.GuestSex = Enums.Sex.Female Then 
				vRow.GuestSexCode = "Female";		
			EndIf;
		EndDo;
	EndIf;
	
	Return vData;
EndFunction // GetChangedReservations

// -----------------------------------------------------------------------------
Function FormatDataTable(pDataTable, pColumnNameStructure);
	
	vResult = New ValueTable;
	
	For each vColumn in pColumnNameStructure Do
		vResult.Columns.Add(vColumn.Value);
	EndDo;
	
	For each vRow in pDataTable Do
		vNewRow = vResult.Add();
		For each vColumn in pColumnNameStructure Do
			If pDataTable.Columns.Find(vColumn.Key) <> Undefined Then
				vNewRow[vColumn.Value] = vRow[vColumn.Key];
			EndIf;
		EndDo;
	EndDo;
	
	Return vResult;
	
EndFunction

#EndRegion
