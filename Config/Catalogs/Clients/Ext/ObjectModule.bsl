
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	If Not IsFolder Then
		Description = pmGetDescription();
		FullName = pmGetFullName();
		// Phone
		Phone = SMS.GetValidPhoneNumber(Phone);
		// Analitical parameters
		Age = pmGetClientAge(CurrentSessionDate());
		AgeRange = pmGetClientAgeRange();
		Region = pmGetClientRegion();
		City = pmGetClientCity();
		// Address presentation
		AddressPresentation = cmGetAddressPresentation(Address);
		// Identity document data presentation
		IdentityDocumentPresentation = TrimAll(TrimAll(IdentityDocumentType) + " " + 
		                                       TrimAll(IdentityDocumentSeries) + " " + 
									           TrimAll(IdentityDocumentNumber) + " " + 
											   ?(IsBlankString(IdentityDocumentUnitCode), "", TrimAll(IdentityDocumentUnitCode) + " ") + 
									           ?(IsBlankString(IdentityDocumentIssuedBy), "", TrimAll(IdentityDocumentIssuedBy) + " ") + 
									           ?(ValueIsFilled(IdentityDocumentIssueDate), Format(IdentityDocumentIssueDate, "DF=dd.MM.yyyy"), ""));
		If ValueIsFilled(Sex) Then
			vSalutation = CachedCommonFunctions.cmGetSalutationBySex(Sex);
			If ValueIsFilled(vSalutation) And vSalutation <> Salutation Then
				Salutation = vSalutation;
			EndIf;
		EndIf;  
		If DeletionMark <> Ref.DeletionMark Then    
	        pmWriteToClientChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure OnCopy(pCopiedObject)
	ExternalCode = "";
	// Author and date
	Author = SessionParameters.CurrentUser;
	CreateDate = CurrentSessionDate();
EndProcedure // OnCopy

// -----------------------------------------------------------------------------
Procedure OnSetNewCode(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(SessionParameters.CurrentHotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(SessionParameters.CurrentHotel);
	EndIf;
	If vPrefix <> "" Then
		pPrefix = vPrefix;
	EndIf;
EndProcedure // OnSetNewCode

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	If Not DeletionMark And Not IsFolder Then
		// Try to find and update customer bound to client
		vCustomer = pmGetBoundCustomer();
		If ValueIsFilled(vCustomer) Then
			If Upper(TrimAll(vCustomer.Description)) <> Upper(TrimAll(FullName)) Or vCustomer.DateOfBirth <> DateOfBirth And ValueIsFilled(DateOfBirth) Then
				vCustomerObj = vCustomer.GetObject();
				vCustomerObj.Description = Upper(TrimAll(FullName));
				vCustomerObj.DateOfBirth = DateOfBirth;
				vCustomerObj.Write();
				vCustomerObj.pmWriteToCustomerChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			EndIf;
		EndIf; 
		// Clear hotel from billing instructions template folios 
		For Each vCRRow In ChargingRules Do
			vChargingFolio = vCRRow.ChargingFolio;
			If ValueIsFilled(vChargingFolio) And ValueIsFilled(vChargingFolio.Hotel) And Not vChargingFolio.IsMaster Then
				vChargingFolioObj = vChargingFolio.GetObject();
				vTransCount = vChargingFolioObj.pmGetAllFolioTransactionsCount();
				If vTransCount = 0 Then
					vChargingFolioObj.Hotel = Catalogs.Hotels.EmptyRef();
					vChargingFolioObj.Write(DocumentWriteMode.Write);
				EndIf;
			EndIf;
			If Not ValueIsFilled(vCRRow.ChargingRuleValue) Then
				vCRRow.ChargingRuleValue = Undefined; // Need to clear empty values of some type (like empty Service group or Service)
			EndIf;
		EndDo;  
	EndIf;
EndProcedure // OnWrite

// -----------------------------------------------------------------------------
Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	If AdditionalProperties.Property("CheckedAttributes") Then
		For Each vId In AdditionalProperties.CheckedAttributes Do
			CheckedAttributes.Add(vId);       
		EndDo;	
	EndIf;
EndProcedure

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
Function pmGetClientAge(pDate) Export
	If Not ValueIsFilled(DateOfBirth) Then
		Return Age;
	EndIf;
	If Not ValueIsFilled(pDate) Then
		Return Age;
	EndIf;
	vAge = Year(pDate) - Year(DateOfBirth);
	vBirthDateMonth = Month(DateOfBirth);
	vDateMonth = Month(pDate);
	If vBirthDateMonth > vDateMonth Then
		vAge = vAge - 1;  
	ElsIf vBirthDateMonth = vDateMonth And Day(DateOfBirth) > Day(pDate) Then
		vAge = vAge - 1;
	EndIf;
	If vAge < 0 Then
		vAge = 0;
	EndIf;
	Return vAge;
EndFunction // pmGetClientAge

// -----------------------------------------------------------------------------
Function pmGetClientAgeRange(pAge = -1) Export
	If Not ValueIsFilled(DateOfBirth) Then
		Return Catalogs.AgeRanges.AgeUndefined;
	EndIf;
	vAge = Age;
	If pAge <> -1 Then
		vAge = pAge;
	EndIf;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	AgeRanges.Ref AS Ref
	|FROM
	|	Catalog.AgeRanges AS AgeRanges
	|WHERE
	|	AgeRanges.DeletionMark = FALSE
	|	AND AgeRanges.FromAge <= &qAge
	|	AND AgeRanges.ToAge >= &qAge
	|
	|ORDER BY
	|	AgeRanges.FromAge";
	vQry.SetParameter("qAge", vAge);
	vQryRes = vQry.Execute().Unload();
	If vQryRes.Count() > 0 Then
		vQryResRow = vQryRes.Get(0);
		Return vQryResRow.Ref;
	Else
		Return Catalogs.AgeRanges.AgeUndefined;
	EndIf;
EndFunction // pmGetClientAgeRange

// -----------------------------------------------------------------------------
Function pmGetClientRegion() Export
	vAddressStruct = cmParseAddress(Address);
	Return vAddressStruct.Region;
EndFunction // pmGetClientRegion

// -----------------------------------------------------------------------------
Function pmGetClientCity() Export
	vAddressStruct = cmParseAddress(Address);
	If Not ValueIsFilled(vAddressStruct.City) And ValueIsFilled(vAddressStruct.Region) And ValueIsFilled(vAddressStruct.Street) Then
		Return TrimAll(vAddressStruct.Region);
	Else
		Return TrimAll(vAddressStruct.City);
	EndIf;
EndFunction // pmGetClientCity

// -----------------------------------------------------------------------------
Procedure pmWriteToClientChangeHistory(pPeriod, pUser) Export
	// Get channges description
	vChanges = cmGetObjectChanges(ThisObject);
	If Not IsBlankString(vChanges) Then
		vCChgRec = InformationRegisters.ClientChangeHistory.CreateRecordManager();
		
		FillCChgAttributes(vCChgRec, pPeriod, pUser);
		vCChgRec.Changes = vChanges;
		
		// Write record
		vCChgRec.Write(True);  
		
		// User activity history
		InformationRegisters.UserActionsHistory.WriteUserActivityRecord(Ref, vChanges, , pUser, pPeriod);
	EndIf;
EndProcedure // pmWriteToClientChangeHistory

// -----------------------------------------------------------------------------
Function pmGetPreviousObjectState(pPeriod) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	*
	|FROM
	|	InformationRegister.ClientChangeHistory.SliceLast(&qPeriod, Client = &qRef) AS ClientChangeHistory";
	vQry.SetParameter("qPeriod", pPeriod);
	vQry.SetParameter("qRef", Ref);
	vStates = vQry.Execute().Unload();
	If vStates.Count() > 0 Then
		Return vStates.Get(0);
	Else
		Return Undefined;
	EndIf;
EndFunction // pmGetPreviousObjectState

// -----------------------------------------------------------------------------
Procedure pmRestoreAttributesFromHistory(pChgRec) Export
	FillPropertyValues(ThisObject, pChgRec, , "Code, Description");
	If Not IsBlankString(pChgRec.Code) Then
		Code = pChgRec.Code;
	EndIf;
	If Not IsBlankString(pChgRec.Description) Then
		Description = pChgRec.Description;
	EndIf;
	// Restore tabular parts
	vChargingRules = pChgRec.ChargingRules.Get();
	If vChargingRules <> Undefined Then
		ChargingRules.Load(vChargingRules);
	Else
		ChargingRules.Clear();
	EndIf;
	vRoomProperties = pChgRec.RoomProperties.Get();
	If vRoomProperties <> Undefined Then
		RoomProperties.Load(vRoomProperties);
	Else
		RoomProperties.Clear();
	EndIf;
EndProcedure // pmRestoreAttributesFromHistory

// -----------------------------------------------------------------------------
Procedure pmFillIdentityDocumentType() Export
	If TrimAll(IdentityDocumentNumber) = "" Then
		If ValueIsFilled(Citizenship) Then
			If ValueIsFilled(SessionParameters.CurrentHotel) Then
				If Citizenship = SessionParameters.CurrentHotel.Citizenship Then
					IdentityDocumentType = SessionParameters.CurrentHotel.IdentityDocumentType;
				Else
					IdentityDocumentType = SessionParameters.CurrentHotel.IdentityDocumentTypeForForeigners;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // pmFillIdentityDocumentType

// -----------------------------------------------------------------------------
Procedure pmCreateFolios(pHotel, pDate) Export
	ChargingRules.Clear();
	vChargingRules = Undefined;
	If ValueIsFilled(pHotel) Then
		If pHotel.ClientChargingRules.Count() > 0 Then
			vChargingRules = pHotel.ClientChargingRules.Unload();
		EndIf;
	Else
		Return;
	EndIf;
	// Check list of template rules
	If vChargingRules = Undefined Then
		// Create new folio and take parameters from the hotel
		vFolioObj = Documents.Folio.CreateDocument();
		cmFillFolioFromTemplate(vFolioObj, Undefined, pHotel, pDate);
		vFolioObj.Hotel = Catalogs.Hotels.EmptyRef();
		vFolioObj.Client = Ref;
		vFolioObj.Write();
		
		// Add it to the charging rules
		vCR = ChargingRules.Add();
		vCR.ChargingRule = Enums.ChargingRuleTypes.Any;
		vCR.ChargingFolio = vFolioObj.Ref;
	Else
		For Each vRule In vChargingRules Do
			vTemplateFolio = vRule.ChargingFolio;
			
			// Create new folio from template
			vFolioObj = Documents.Folio.CreateDocument();
			cmFillFolioFromTemplate(vFolioObj, vTemplateFolio, pHotel, pDate);
			vFolioObj.Description = vTemplateFolio.Description;
			vFolioObj.Company = vTemplateFolio.Company;
			vFolioObj.FolioCurrency = vTemplateFolio.FolioCurrency;
			vFolioObj.ParentDoc = vTemplateFolio.ParentDoc;
			vFolioObj.Agent = vTemplateFolio.Agent;
			vFolioObj.Customer = vTemplateFolio.Customer;
			vFolioObj.Contract = vTemplateFolio.Contract;
			vFolioObj.Client = vTemplateFolio.Client;
			vFolioObj.GuestGroup = vTemplateFolio.GuestGroup;
			vFolioObj.Room = vTemplateFolio.Room;
			vFolioObj.DateTimeFrom = vTemplateFolio.DateTimeFrom;
			vFolioObj.DateTimeTo = vTemplateFolio.DateTimeTo;
			vFolioObj.PaymentSection = vTemplateFolio.PaymentSection;
			vFolioObj.PaymentMethod = vTemplateFolio.PaymentMethod;
			vFolioObj.CreditLimit = vTemplateFolio.CreditLimit;
			vFolioObj.DoNotUpdateCompany = vTemplateFolio.DoNotUpdateCompany;
			vFolioObj.DoNotUpdateCustomer = vTemplateFolio.DoNotUpdateCustomer;
			vFolioObj.DoNotFillAgent = vTemplateFolio.DoNotFillAgent;
			vFolioObj.HotelProduct = vTemplateFolio.HotelProduct;
			vFolioObj.IsMaster = vTemplateFolio.IsMaster;
			vFolioObj.Hotel = Catalogs.Hotels.EmptyRef();
			vFolioObj.Client = Ref;
			vFolioObj.Write();
			
			// Add it to the charging rules
			vCR = ChargingRules.Add();
			FillPropertyValues(vCR, vRule, , "ChargingFolio");
			vCR.ChargingFolio = vFolioObj.Ref;
		EndDo;
	EndIf;
EndProcedure // pmCreateFolios

// -----------------------------------------------------------------------------
Procedure pmBindClientToItsChargingRules() Export
	For Each vRow In ChargingRules Do
		vFolio = vRow.ChargingFolio;
		If ValueIsFilled(vFolio) Then
			If Not ValueIsFilled(vFolio.Client) Then
				vFolioObj = vFolio.GetObject();
				vFolioObj.Client = Ref;
				Try
					vFolioObj.Write();
				Except
					vErrInfo = ErrorInfo();
					WriteLogEvent(NStr("en = 'Catalog.Clients.AfterWrite'; de = 'Catalog.Clients.AfterWrite'''; ru = 'Справочник.Клиенты.ПослеЗаписи'"), EventLogLevel.Warning, Metadata(), Ref, cmGetRootErrorDescription(vErrInfo));
					tcCommonFunctionOnClientServer.TextMessage(cmGetRootErrorDescription(vErrInfo), MessageStatus.Attention);
				EndTry;
			EndIf;
		EndIf;
	EndDo;
EndProcedure // pmBindClientToItsChargingRules

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Author and date
	Author = SessionParameters.CurrentUser;
	CreateDate = CurrentSessionDate();
	// Initialization based on hotel
	vHotel = SessionParameters.CurrentHotel;
	If ValueIsFilled(vHotel) Then
		// Citizenship
		If Not ValueIsFilled(Citizenship) Then
			Citizenship = vHotel.Citizenship;
		EndIf;
		// Language
		If Not ValueIsFilled(Language) Then
			Language = vHotel.Language;
		EndIf;
		// Identity document
		If Not ValueIsFilled(IdentityDocumentType) Then
			IdentityDocumentType = vHotel.IdentityDocumentType;
		EndIf;
		// Default charging rules
		If vHotel.AlwaysCreateDefaultChargingRulesForNewClients Then
			pmCreateFolios(vHotel, CreateDate);
		EndIf;
	EndIf;
	// Refused from E-Mail/SMS mailings
	If Constants.NoSMSDeliveryByDefault.Get() Then
		NoSMSDelivery = True;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetForeignerRegistryRecords(pDateFrom, pDateTo) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ForeignerRegistryRecord.Ref AS ForeignerRegistryRecord
	|FROM
	|	Document.ForeignerRegistryRecord AS ForeignerRegistryRecord
	|WHERE
	|	ForeignerRegistryRecord.Guest = &qClient
	|	AND ForeignerRegistryRecord.Date >= &qDateFrom
	|	AND ForeignerRegistryRecord.Date < &qDateTo
	|	AND ForeignerRegistryRecord.Posted
	|ORDER BY
	|	ForeignerRegistryRecord.Date";
	vQry.SetParameter("qClient", Ref);
	vQry.SetParameter("qDateFrom", pDateFrom);
	vQry.SetParameter("qDateTo", pDateTo);
	vRecords = vQry.Execute().Unload();
	Return vRecords;
EndFunction // pmGetForeignerRegistryRecords

// -----------------------------------------------------------------------------
Function pmGetDescription() Export
	vDescription = Upper(TrimAll(LastName));
	If Not IsBlankString(FirstName) Then
		vDescription = vDescription + " " + Upper(Left(TrimL(FirstName), 1)) + ".";
	EndIf;
	If Not IsBlankString(SecondName) Then
		vDescription = vDescription + " " + Upper(Left(TrimL(SecondName), 1)) + ".";
	EndIf;
	Return vDescription;
EndFunction // pmGetDescription

// -----------------------------------------------------------------------------
Function pmGetFullName() Export
	Return TrimAll(TrimAll(LastName) + " " + TrimAll(FirstName) + " " + TrimAll(SecondName));
EndFunction // pmGetFullName

// -----------------------------------------------------------------------------
// Counts guest check-ins
// -----------------------------------------------------------------------------
Function pmCountNumberOfCheckIns(pPeriodFrom = Undefined, pPeriodTo = Undefined, pUseResourcesPayedAsIndividual = False, pUseResourcesPayedByRackRates = False) Export
	vNumberOfCheckIns = 0;
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SUM(ISNULL(SalesTurnovers.GuestsCheckedInTurnover, 0)) AS GuestsCheckedIn
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			Client = &qClient
	|				AND (NOT &qUseResourcesPayedAsIndividual
	|					OR &qUseResourcesPayedAsIndividual
	|						AND (Customer = &qEmptyCustomer
	|							OR Customer <> &qEmptyCustomer AND Customer.IsIndividual))
	|				AND (NOT &qUseResourcesPayedByRackRates
	|					OR &qUseResourcesPayedByRackRates
	|						AND ISNULL(RoomRate.IsRackRate, FALSE))) AS SalesTurnovers";
	vQry.SetParameter("qClient", Ref);
	vQry.SetParameter("qPeriodFrom", pPeriodFrom);
	vQry.SetParameter("qPeriodTo", pPeriodTo);
	vQry.SetParameter("qUseResourcesPayedAsIndividual", pUseResourcesPayedAsIndividual);
	vQry.SetParameter("qUseResourcesPayedByRackRates", pUseResourcesPayedByRackRates);
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		If vQryRes.GuestsCheckedIn <> NULL Then
			vNumberOfCheckIns = vQryRes.GuestsCheckedIn;
		EndIf;
		Break;
	EndDo;
	Return vNumberOfCheckIns;
EndFunction // pmCountNumberOfCheckIns

// -----------------------------------------------------------------------------
// Count guest nights
// -----------------------------------------------------------------------------
Function pmCountNumberOfNights(pPeriodFrom = Undefined, pPeriodTo = Undefined, pUseResourcesPayedAsIndividual = False, pUseResourcesPayedByRackRates = False) Export
	vNumberOfNights = 0;
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SUM(ISNULL(SalesTurnovers.GuestDaysTurnover, 0)) AS GuestDaysTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			Client = &qClient
	|				AND (NOT &qUseResourcesPayedAsIndividual
	|					OR &qUseResourcesPayedAsIndividual
	|						AND (Customer = &qEmptyCustomer
	|							OR Customer <> &qEmptyCustomer AND Customer.IsIndividual))
	|				AND (NOT &qUseResourcesPayedByRackRates
	|					OR &qUseResourcesPayedByRackRates
	|						AND ISNULL(RoomRate.IsRackRate, FALSE))) AS SalesTurnovers";
	vQry.SetParameter("qClient", Ref);
	vQry.SetParameter("qPeriodFrom", pPeriodFrom);
	vQry.SetParameter("qPeriodTo", pPeriodTo);
	vQry.SetParameter("qUseResourcesPayedAsIndividual", pUseResourcesPayedAsIndividual);
	vQry.SetParameter("qUseResourcesPayedByRackRates", pUseResourcesPayedByRackRates);
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		If vQryRes.GuestDaysTurnover <> NULL Then
			vNumberOfNights = vQryRes.GuestDaysTurnover;
		EndIf;
		Break;
	EndDo;
	Return vNumberOfNights;
EndFunction // pmCountNumberOfNights

// -----------------------------------------------------------------------------
// Get client revenue statistics
// -----------------------------------------------------------------------------
Function pmGetClientRevenueStatistics(pPeriodFrom = Undefined, pPeriodTo = Undefined, pUseResourcesPayedAsIndividual = False, pUseResourcesPayedByRackRates = False) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SalesTurnovers.ReportingCurrency AS ReportingCurrency,
	|	SUM(ISNULL(SalesTurnovers.SalesTurnover, 0)) AS SalesTurnover,
	|	SUM(ISNULL(SalesTurnovers.SalesWithoutVATTurnover, 0)) AS SalesWithoutVATTurnover,
	|	SUM(ISNULL(SalesTurnovers.RoomRevenueTurnover, 0)) AS RoomRevenueTurnover,
	|	SUM(ISNULL(SalesTurnovers.RoomRevenueWithoutVATTurnover, 0)) AS RoomRevenueWithoutVATTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			Client = &qClient
	|				AND (NOT &qUseResourcesPayedAsIndividual
	|					OR &qUseResourcesPayedAsIndividual
	|						AND (Customer = &qEmptyCustomer
	|							OR Customer <> &qEmptyCustomer
	|								AND Customer.IsIndividual))
	|				AND (NOT &qUseResourcesPayedByRackRates
	|					OR &qUseResourcesPayedByRackRates
	|						AND ISNULL(RoomRate.IsRackRate, FALSE))) AS SalesTurnovers
	|
	|GROUP BY
	|	SalesTurnovers.ReportingCurrency
	|
	|ORDER BY
	|	SalesTurnovers.ReportingCurrency.SortCode";
	vQry.SetParameter("qClient", Ref);
	vQry.SetParameter("qPeriodFrom", pPeriodFrom);
	vQry.SetParameter("qPeriodTo", pPeriodTo);
	vQry.SetParameter("qUseResourcesPayedAsIndividual", pUseResourcesPayedAsIndividual);
	vQry.SetParameter("qUseResourcesPayedByRackRates", pUseResourcesPayedByRackRates);
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	vQryRes = vQry.Execute().Unload();
	Return vQryRes;
EndFunction // pmGetClientRevenueStatistics

// -----------------------------------------------------------------------------
// Get client reservation statistics
// -----------------------------------------------------------------------------
Function pmGetClientReservationStatistics() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservation.ReservationStatus AS ReservationStatus,
	|	COUNT(*) AS Count
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.Posted
	|	AND Reservation.Guest = &qGuest
	|	AND Reservation.ReservationStatus <> Reservation.Hotel.CheckInReservationStatus
	|
	|GROUP BY
	|	Reservation.ReservationStatus
	|
	|ORDER BY
	|	Reservation.ReservationStatus.SortCode";
	vQry.SetParameter("qGuest", Ref);
	vQryRes = vQry.Execute().Unload();
	Return vQryRes;
EndFunction // pmGetClientReservationStatistics

// -----------------------------------------------------------------------------
// Get client last accommodation
// -----------------------------------------------------------------------------
Function pmGetClientLastAccommodation() Export
	vLastAcc = Undefined;
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	Accommodation.Ref AS Ref
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Posted
	|	AND Accommodation.Guest = &qGuest
	|	AND Accommodation.AccommodationStatus.IsCheckOut
	|	AND Accommodation.AccommodationStatus.IsActive
	|
	|ORDER BY
	|	Accommodation.PointInTime DESC";
	vQry.SetParameter("qGuest", Ref);
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vLastAcc = vQryRes.Ref;
		Break;
	EndDo;
	Return vLastAcc;
EndFunction // pmGetClientLastAccommodation

// -----------------------------------------------------------------------------
// Get client last resource reservation
// -----------------------------------------------------------------------------
Function pmGetClientLastResourceReservation() Export
	vLastRes = Undefined;
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	ResourceReservation.Ref AS Ref
	|FROM
	|	Document.ResourceReservation AS ResourceReservation
	|WHERE
	|	ResourceReservation.Posted
	|	AND ResourceReservation.Client = &qGuest
	|	AND ResourceReservation.ResourceReservationStatus.IsActive
	|
	|ORDER BY
	|	ResourceReservation.PointInTime DESC";
	vQry.SetParameter("qGuest", Ref);
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vLastRes = vQryRes.Ref;
		Break;
	EndDo;
	Return vLastRes;
EndFunction // pmGetClientLastResourceReservation

// -----------------------------------------------------------------------------
// Get client first accommodation
// -----------------------------------------------------------------------------
Function pmGetClientFirstAccommodation() Export
	vFirstAcc = Undefined;
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	Accommodation.Ref AS Ref
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Posted
	|	AND Accommodation.Guest = &qGuest
	|	AND Accommodation.AccommodationStatus.IsCheckIn
	|	AND Accommodation.AccommodationStatus.IsActive
	|
	|ORDER BY
	|	Accommodation.PointInTime";
	vQry.SetParameter("qGuest", Ref);
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vFirstAcc = vQryRes.Ref;
		Break;
	EndDo;
	Return vFirstAcc;
EndFunction // pmGetClientFirstAccommodation

// -----------------------------------------------------------------------------
Function pmGetBonusesAmount(pHotel = Undefined, pCurrency = Undefined, pDiscountCard = Undefined, rBonus = 0) Export
	rBonusAmount = 0;
	rBonus = 0;
	vHotel = pHotel;
	If Not ValueIsFilled(vHotel) Then
		vHotel = SessionParameters.CurrentHotel;
	EndIf;
	// Get bonus calculation date 
	vBonusCalculationDate = CurrentSessionDate();
	If ValueIsFilled(vHotel) And ValueIsFilled(vHotel.DateToGetBonusBalance) Then
		If vHotel.DateToGetBonusBalance = Enums.DatesToGetBonusBalance.CheckOutDate Then
			vBonusCalculationDate = '39991231235959';
		EndIf;
	EndIf;
	If Not IsNew() Then
		// Get accummulation discount types
		vBonusTypes = cmGetBonusDiscountTypes();
		For Each vBonusTypesRow In vBonusTypes Do
			vDiscountTypeObj = vBonusTypesRow.DiscountType.GetObject();
			vBonuses = vDiscountTypeObj.pmGetAccumulatingDiscountResources(vBonusCalculationDate, , , Ref, pDiscountCard);
			If vBonuses.Count() > 0 Then
				vBonusesRow = vBonuses.Get(0);
				If vBonusesRow.Bonus <> 0 Then
					rBonus = rBonus + vBonusesRow.Bonus;
					If vBonusesRow.Bonus <> 0 And ValueIsFilled(pCurrency) Then
						// Recalculate bonuses to the input currency
						vRates = InformationRegisters.CurrencyRates.SliceLast(CurrentSessionDate(), New Structure("Hotel, Currency", vHotel, pCurrency));
						If vRates.Count() > 0 Then
							vRatesRow = vRates.Get(0);
							If vRatesRow.BonusRate <> 0 Then
								rBonusAmount = rBonusAmount + cmRoundDown(vBonusesRow.Bonus/(vRatesRow.BonusRate * ?(vDiscountTypeObj.BonusRateMultiplier = 0, 1, vDiscountTypeObj.BonusRateMultiplier)), 2);
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	Return rBonusAmount;
EndFunction // pmGetBonusesAmount

// -----------------------------------------------------------------------------
//  Get characteristics
// 
// Returns:
//  ValueTable 
//
Function pmGetLimitsAndConditions() Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	NestedSelect.Owner AS Owner,
	|	NestedSelect.Hotel AS Hotel,
	|	LimitsAndSpecialConditionTypes.Ref AS Characteristic,
	|	NestedSelect.CharacteristicValue AS CharacteristicValue
	|FROM
	|	ChartOfCharacteristicTypes.LimitsAndSpecialConditionTypes AS LimitsAndSpecialConditionTypes
	|		LEFT JOIN (SELECT
	|			LimitsAndSpecialConditions.Owner AS Owner,
	|			LimitsAndSpecialConditions.Hotel AS Hotel,
	|			LimitsAndSpecialConditions.Characteristic AS Characteristic,
	|			LimitsAndSpecialConditions.CharacteristicValue AS CharacteristicValue
	|		FROM
	|			InformationRegister.LimitsAndSpecialConditions AS LimitsAndSpecialConditions
	|		WHERE
	|			LimitsAndSpecialConditions.Owner = &qClient
	|			AND NOT LimitsAndSpecialConditions.Characteristic.DeletionMark) AS NestedSelect
	|		ON LimitsAndSpecialConditionTypes.Ref = NestedSelect.Characteristic
	|WHERE
	|	NOT LimitsAndSpecialConditionTypes.DeletionMark";
	vQry.SetParameter("qClient", Ref);
	vChars = vQry.Execute().Unload();
	Return vChars;
EndFunction // pmGetLimitsAndConditions

// -----------------------------------------------------------------------------
//  Get characteristic value
//
Function pmGetLimitsAndConditionsValue(pCharacteristic, pHotel) Export
	vCharValue = Undefined;
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	LimitsAndSpecialConditions.CharacteristicValue AS CharacteristicValue
	|FROM
	|	InformationRegister.LimitsAndSpecialConditions AS LimitsAndSpecialConditions
	|WHERE
	|	LimitsAndSpecialConditions.Owner = &qClient
	|	AND (LimitsAndSpecialConditions.Hotel = &qHotel
	|			OR LimitsAndSpecialConditions.Hotel = &qEmptyHotel)
	|	AND LimitsAndSpecialConditions.Characteristic = &qCharacteristic
	|
	|ORDER BY
	|	LimitsAndSpecialConditions.Characteristic.Code";
	vQry.SetParameter("qClient", Ref);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qCharacteristic", pCharacteristic);
	vChars = vQry.Execute().Select();
	While vChars.Next() Do
		vCharValue = vChars.CharacteristicValue;
		Break;
	EndDo;
	Return vCharValue;
EndFunction // pmGetLimitsAndConditionsValue

// -----------------------------------------------------------------------------
Procedure pmSaveLimitsAndConditionsValue(pCharacteristic, pCharacteristicValue, pHotel) Export
	vCharsMgr = InformationRegisters.LimitsAndSpecialConditions.CreateRecordManager();
	vCharsMgr.Owner = Ref;
	vCharsMgr.Characteristic = pCharacteristic;
	vCharsMgr.Hotel = pHotel;
	vCharsMgr.Read();
	If vCharsMgr.Selected() Then
		vCharsMgr.Owner = Ref;
		vCharsMgr.Characteristic = pCharacteristic;
		vCharsMgr.CharacteristicValue = pCharacteristicValue;
		vCharsMgr.Hotel = pHotel;
		vCharsMgr.Write();
	EndIf;
EndProcedure // pmSaveLimitsAndConditionsValue

// -----------------------------------------------------------------------------
Function pmGetBoundCustomer() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Customers.Ref AS Ref
	|FROM
	|	Catalog.Customers AS Customers
	|WHERE
	|	Customers.Client = &qClient
	|	AND NOT Customers.IsFolder
	|	AND NOT Customers.DeletionMark
	|
	|ORDER BY
	|	Customers.Code DESC";
	vQry.SetParameter("qClient", Ref);
	vCustomers = vQry.Execute().Unload();
	If vCustomers.Count() > 0 Then
		Return vCustomers.Get(0).Ref;
	Else
		Return Undefined;
	EndIf;
EndFunction // pmGetBoundCustomer

// -----------------------------------------------------------------------------
Procedure FillCChgAttributes(pCChgRec, pPeriod, pUser) Export
	FillPropertyValues(pCChgRec, ThisObject);
	
	pCChgRec.Period = pPeriod;
	pCChgRec.Client = ThisObject.Ref;
	pCChgRec.User = pUser;
	
	// Store tabular parts
	vChargingRules = New ValueStorage(ChargingRules.Unload());
	pCChgRec.ChargingRules = vChargingRules;
	vRoomProperties = New ValueStorage(RoomProperties.Unload());
	pCChgRec.RoomProperties = vRoomProperties;
EndProcedure // FillCChgAttributes

#EndRegion
