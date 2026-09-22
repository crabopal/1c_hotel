
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Description = Upper(TrimAll(Description));
	If Not IsFolder Then
		vIsIndividual = pmGetIsIndividualFlag();
		If IsIndividual <> vIsIndividual Then
			IsIndividual = vIsIndividual;
		EndIf; 
		If DeletionMark <> Ref.DeletionMark Then
	       pmWriteToCustomerChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

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
Procedure OnCopy(pCopiedObject)
	If Not IsFolder Then
		ExternalCode = "";
		// Author and date
		Author = SessionParameters.CurrentUser;
		CreateDate = CurrentSessionDate();
	EndIf;
EndProcedure // OnCopy

// -----------------------------------------------------------------------------
Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	If AdditionalProperties.Property("CheckedAttributes") Then
		For Each vId In AdditionalProperties.CheckedAttributes Do
			CheckedAttributes.Add(vId);       
		EndDo;	
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel) 
	If DataExchange.Load Then
		Return;
	EndIf;
	// Clear hotel from billing instructions template folios
	If Not DeletionMark Then
		For Each vCRRow In ChargingRules Do
			// Need to clear empty values of some type (like empty Service group or Service)
			If Not ValueIsFilled(vCRRow.ChargingRuleValue) Then
				vCRRow.ChargingRuleValue = Undefined;
			EndIf;
			// Clear hotel from template folios
			vChargingFolio = vCRRow.ChargingFolio;
			vChargingFolioObj = Undefined;
			If ValueIsFilled(vChargingFolio) And ValueIsFilled(vChargingFolio.Hotel) And Not vChargingFolio.IsMaster Then
				vChargingFolioObj = vChargingFolio.GetObject();
				vTransCount = vChargingFolioObj.pmGetAllFolioTransactionsCount();
				If vTransCount = 0 Then
					vChargingFolioObj.Hotel = Catalogs.Hotels.EmptyRef();
				EndIf;
			EndIf;
			// Fill customer in template folios
			If Not IsFolder Then
				If ValueIsFilled(vChargingFolio) And vChargingFolio.Customer <> Ref And 
				   Not vChargingFolio.DoNotUpdateCustomer And Not vChargingFolio.IsMaster Then
					vChargingFolioObj = vChargingFolio.GetObject();
					vChargingFolioObj.Customer = Ref;
					If ValueIsFilled(vChargingFolioObj.Contract) And vChargingFolioObj.Contract.Owner <> vChargingFolioObj.Customer Then
						vChargingFolioObj.Contract = Catalogs.Contracts.EmptyRef();
					EndIf;
				EndIf;
			EndIf;
			If vChargingFolioObj <> Undefined And vChargingFolioObj.Modified() Then
				vChargingFolioObj.Write(DocumentWriteMode.Write);
			EndIf;
		EndDo;
	EndIf;
EndProcedure // OnWrite

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
Function pmGetIsIndividualFlag() Export
	vIsIndividual = False;
	vIndividualsFolder = Constants.IndividualsFolder.Get();
	If Not ValueIsFilled(vIndividualsFolder) Then
		vIndividualsFolder = Catalogs.Customers.IndividualsFolder;
	EndIf;
	If BelongsToItem(vIndividualsFolder) Then
		vIsIndividual = True;
	Else
		If ValueIsFilled(SessionParameters.CurrentHotel) And 
		   ValueIsFilled(SessionParameters.CurrentHotel.IndividualsCustomer) And 
		   Ref = SessionParameters.CurrentHotel.IndividualsCustomer Then
			vIsIndividual = True;
		EndIf;
	EndIf; 
	Return vIsIndividual;
EndFunction // pmGetIsIndividualFlag

// -----------------------------------------------------------------------------
Procedure pmCreateFolios(pHotel, pDate, pPayer = Undefined) Export
	ChargingRules.Clear();
	vChargingRules = Undefined;
	If pPayer = Enums.WhoPays.Agent And Not IsFolder And ValueIsFilled(Agent) And ValueIsFilled(Agent.Parent) Then
		vParent = Agent.Parent;
	Else
		vParent = Parent;
	EndIf;
	While ValueIsFilled(vParent) Do
		If vParent.ChargingRules.Count() > 0 Then
			vChargingRules = vParent.ChargingRules.Unload();
			Break;
		EndIf;
		vParent = vParent.Parent;
	EndDo;
	If vChargingRules = Undefined Then
		If ValueIsFilled(pHotel) Then
			If pHotel.CustomerChargingRules.Count() > 0 Then
				vChargingRules = pHotel.CustomerChargingRules.Unload();
			EndIf;
		Else
			Return;
		EndIf;
	EndIf;
	// Check list of template rules
	If vChargingRules = Undefined Then
		// Create new folio and take parameters from the hotel
		vFolioObj = Documents.Folio.CreateDocument();
		cmFillFolioFromTemplate(vFolioObj, Undefined, pHotel, pDate);
		vFolioObj.Hotel = Catalogs.Hotels.EmptyRef();
		If pPayer = Enums.WhoPays.Agent And Not IsFolder And ValueIsFilled(Agent) Then
			vFolioObj.Customer = Agent;
			vFolioObj.Contract = Undefined;
		Else  
			vAgent = Agent;
			If IsFolder Then
				vAgent = Catalogs.Customers.EmptyRef();	
			EndIf;
			vFolioObj.Customer = vAgent;
			vFolioObj.Contract = Contract;
		EndIf;
		If ValueIsFilled(pHotel) And ValueIsFilled(pHotel.PaymentMethodForCustomerPayments) Then
			vFolioObj.PaymentMethod = pHotel.PaymentMethodForCustomerPayments;
		ElsIf ValueIsFilled(PlannedPaymentMethod) Then
			vFolioObj.PaymentMethod = PlannedPaymentMethod;
		EndIf;
		If ValueIsFilled(AccountingCurrency) Then
			vFolioObj.FolioCurrency = AccountingCurrency;
		EndIf;
		vFolioObj.Write();
		
		// Add it to the charging rules
		vCR = ChargingRules.Add();
		vCR.ChargingRule = Enums.ChargingRuleTypes.InRate;
		vCR.ChargingFolio = vFolioObj.Ref;
	Else
		For Each vRule In vChargingRules Do
			// Create new folio from template
			vFolioObj = Documents.Folio.CreateDocument();
			cmFillFolioFromTemplate(vFolioObj, vRule.ChargingFolio, pHotel, pDate);
			vFolioObj.Hotel = Catalogs.Hotels.EmptyRef();
			If pPayer = Enums.WhoPays.Agent And Not IsFolder And ValueIsFilled(Agent) Then
				vFolioObj.Customer = Agent;
				vFolioObj.Contract = Undefined;
			Else  
				vRef = Ref;
				If IsFolder Then
					vRef = Catalogs.Customers.EmptyRef();	
				EndIf;
				vFolioObj.Customer = vRef;
				vFolioObj.Contract = Contract;
			EndIf;
			If ValueIsFilled(AccountingCurrency) Then
				vFolioObj.FolioCurrency = AccountingCurrency;
			EndIf;
			vFolioObj.IsMaster = vRule.ChargingFolio.IsMaster;
			vFolioObj.Write();
			
			// Add it to the charging rules
			vCR = ChargingRules.Add();
			FillPropertyValues(vCR, vRule, , "ChargingFolio");
			vCR.ChargingFolio = vFolioObj.Ref;
		EndDo;
	EndIf;
EndProcedure // pmCreateFolios

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues(pHotel = Undefined) Export
	// Author and date
	Author = SessionParameters.CurrentUser;
	CreateDate = CurrentSessionDate();
	// Initialization based on hotel
	If Not pHotel = Undefined And ValueIsFilled(pHotel) THen
		vHotel = pHotel;
	Else
		vHotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(vHotel) Then
		// Language
		If Not ValueIsFilled(Language) Then
			Language = vHotel.Language;
		EndIf;
		// Currency
		If Not ValueIsFilled(AccountingCurrency) Then
			AccountingCurrency = vHotel.FolioCurrency;
		EndIf;
		// Planned payment method
		PlannedPaymentMethod = vHotel.PlannedPaymentMethod;
		// Default charging rules
		If vHotel.AlwaysCreateDefaultChargingRulesForNewCustomers Then
			pmCreateFolios(vHotel, CreateDate);
		Else
			vParent = Parent;
			While ValueIsFilled(vParent) Do
				If vParent.AlwaysCreateDefaultChargingRulesForNewCustomers Then
					pmCreateFolios(vHotel, CreateDate);
					Break;
				EndIf;
				vParent = vParent.Parent;
			EndDo;
		EndIf;
		If ChargingRules.Count() > 0 Then
			vChargingFolio = ChargingRules.Get(0).ChargingFolio;
			If ValueIsFilled(vChargingFolio) And ValueIsFilled(vChargingFolio.PaymentMethod) Then
				If PlannedPaymentMethod <> vChargingFolio.PaymentMethod Then
					PlannedPaymentMethod = vChargingFolio.PaymentMethod;
				EndIf;
			EndIf;
		EndIf;
		// Do not post commission to customer accounts
		DoNotPostCommission = vHotel.DoNotPostCommission;
	EndIf;
	// Fill customer type
	If ValueIsFilled(Parent) And ValueIsFilled(Parent.CustomerType) Then
		CustomerType = Parent.CustomerType;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Fill planned payment method from charging rules
// -----------------------------------------------------------------------------
Procedure pmFillPlannedPaymentMethodFromChargingRules() Export
	If ChargingRules.Count() > 0 Then
		vFirstCRRow = ChargingRules.Get(0);
		If ValueIsFilled(vFirstCRRow.ChargingFolio) And ValueIsFilled(vFirstCRRow.ChargingFolio.PaymentMethod) Then
			If PlannedPaymentMethod <> vFirstCRRow.ChargingFolio.PaymentMethod Then
				PlannedPaymentMethod = vFirstCRRow.ChargingFolio.PaymentMethod;
			EndIf;
		Else
			If ValueIsFilled(SessionParameters.CurrentHotel) Then
				If ValueIsFilled(SessionParameters.CurrentHotel.PlannedPaymentMethod) Then
					If PlannedPaymentMethod <> SessionParameters.CurrentHotel.PlannedPaymentMethod Then
						PlannedPaymentMethod = SessionParameters.CurrentHotel.PlannedPaymentMethod;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	Else
		If ValueIsFilled(SessionParameters.CurrentHotel) Then
			If ValueIsFilled(SessionParameters.CurrentHotel.PlannedPaymentMethod) Then
				If PlannedPaymentMethod <> SessionParameters.CurrentHotel.PlannedPaymentMethod Then
					PlannedPaymentMethod = SessionParameters.CurrentHotel.PlannedPaymentMethod;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // pmFillPlannedPaymentMethodFromChargingRules

// -----------------------------------------------------------------------------
Function pmLoadCustomerContactPersonsList() Export
	// Load customer contact persons list
	vCPList = New ValueList();
	If Not IsBlankString(ContactPerson) Then
		vCPList.Add(TrimR(ContactPerson));
	EndIf;
	For Each vCP In ContactPersons Do
		vCPStr = "";
		If Not IsBlankString(vCP.ContactPerson) Then
			vCPStr = TrimR(vCP.ContactPerson);
		ElsIf ValueIsFilled(vCP.Client) Then
			vCPStr = TrimAll(vCP.Client.FullName) + ?(IsBlankString(vCP.Position), "", " - " + TrimAll(vCP.Position)) + ?(IsBlankString(vCP.Phone), "", ", " + TrimAll(vCP.Phone)) + ?(IsBlankString(vCP.Phone2), "", ", " + TrimAll(vCP.Phone2)) + ?(IsBlankString(vCP.EMail), "", ", " + TrimAll(vCP.EMail));
		EndIf;
		If Not IsBlankString(vCPStr) Then
			If vCPList.FindByValue(vCPStr) = Undefined Then
				vCPList.Add(vCPStr);
			EndIf;
		EndIf;
	EndDo;
	Return vCPList;
EndFunction // pmLoadCustomerContactPersonsList

// -----------------------------------------------------------------------------
Function pmCheckCustomerAttributes(pMessage, pAttributeInErr) Export
	vHasErrors = False;
	pMessage = "";
	pAttributeInErr = "";
	vMsgTextRu = "";
	vMsgTextEn = "";
	If IsBlankString(Description) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Наименование> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Description> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Description", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(AccountingCurrency) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Валюта взаиморасчетов> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Accounting currency> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "AccountingCurrency", pAttributeInErr);
	EndIf;
	If vHasErrors Then
		pMessage = "ru = '" + TrimAll(vMsgTextRu) + "';" + "en = '" + TrimAll(vMsgTextEn) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // pmCheckCustomerAttributes

// -----------------------------------------------------------------------------
Procedure pmWriteToCustomerChangeHistory(pPeriod, pUser) Export
	// Get channges description
	vChanges = cmGetObjectChanges(ThisObject);
	If Not IsBlankString(vChanges) Then
		vCChgRec = InformationRegisters.CustomerChangeHistory.CreateRecordManager();
		
		FillCChgAttributes(vCChgRec, pPeriod, pUser);
		vCChgRec.Changes = vChanges;
		
		// Write record
		vCChgRec.Write(True);  
		
		// User activity history
		InformationRegisters.UserActionsHistory.WriteUserActivityRecord(Ref, vChanges, , pUser, pPeriod);
	EndIf;
EndProcedure // pmWriteToCustomerChangeHistory

// -----------------------------------------------------------------------------
Function pmGetPreviousObjectState(pPeriod) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	*
	|FROM
	|	InformationRegister.CustomerChangeHistory.SliceLast(&qPeriod, Customer = &qRef) AS CustomerChangeHistory";
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
	vContactPersons = pChgRec.ContactPersons.Get();
	If vContactPersons <> Undefined Then
		ContactPersons.Load(vContactPersons);
	Else
		ContactPersons.Clear();
	EndIf;
	vRoomRates = pChgRec.RoomRates.Get();
	If vRoomRates <> Undefined Then
		RoomRates.Load(vRoomRates);
	Else
		RoomRates.Clear();
	EndIf;
EndProcedure // pmRestoreAttributesFromHistory

// -----------------------------------------------------------------------------
// Counts customer guests check-ins
// -----------------------------------------------------------------------------
Function pmCountNumberOfCheckIns() Export
	vNumberOfCheckIns = 0;
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SUM(ISNULL(RoomInventory.GuestsCheckedIn, 0)) AS GuestsCheckedIn,
	|	RoomInventory.Customer AS Customer
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|WHERE
	|	RoomInventory.Customer = &qCustomer
	|	AND RoomInventory.IsAccommodation
	|
	|GROUP BY
	|	RoomInventory.Customer";
	vQry.SetParameter("qCustomer", Ref);
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
// Count customer guests nights
// -----------------------------------------------------------------------------
Function pmCountNumberOfNights() Export
	vNumberOfNights = 0;
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SUM(ISNULL(SalesTurnovers.GuestDaysTurnover, 0)) AS GuestDaysTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(, , Period, Customer = &qCustomer) AS SalesTurnovers";
	vQry.SetParameter("qCustomer", Ref);
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
// Get customer revenue statistics
// -----------------------------------------------------------------------------
Function pmGetCustomerRevenueStatistics() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CustomerSales.DataType AS DataType,
	|	CustomerSales.ReportingCurrency AS ReportingCurrency,
	|	CustomerSales.ReportingCurrencySortCode AS ReportingCurrencySortCode,
	|	SUM(CustomerSales.RoomsRentedTurnover) AS RoomsRentedTurnover,
	|	SUM(CustomerSales.GuestDaysTurnover) AS GuestDaysTurnover,
	|	SUM(CustomerSales.RoomsCheckedInTurnover) AS RoomsCheckedInTurnover,
	|	SUM(CustomerSales.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover,
	|	SUM(CustomerSales.SalesTurnover) AS SalesTurnover,
	|	SUM(CustomerSales.SalesWithoutVATTurnover) AS SalesWithoutVATTurnover,
	|	SUM(CustomerSales.RoomRevenueTurnover) AS RoomRevenueTurnover,
	|	SUM(CustomerSales.RoomRevenueWithoutVATTurnover) AS RoomRevenueWithoutVATTurnover,
	|	SUM(CustomerSales.RoomsRentedTurnoverAsCustomer) AS RoomsRentedTurnoverAsCustomer,
	|	SUM(CustomerSales.GuestDaysTurnoverAsCustomer) AS GuestDaysTurnoverAsCustomer,
	|	SUM(CustomerSales.RoomsCheckedInTurnoverAsCustomer) AS RoomsCheckedInTurnoverAsCustomer,
	|	SUM(CustomerSales.GuestsCheckedInTurnoverAsCustomer) AS GuestsCheckedInTurnoverAsCustomer,
	|	SUM(CustomerSales.SalesTurnoverAsCustomer) AS SalesTurnoverAsCustomer,
	|	SUM(CustomerSales.SalesWithoutVATTurnoverAsCustomer) AS SalesWithoutVATTurnoverAsCustomer,
	|	SUM(CustomerSales.RoomRevenueTurnoverAsCustomer) AS RoomRevenueTurnoverAsCustomer,
	|	SUM(CustomerSales.RoomRevenueWithoutVATTurnoverAsCustomer) AS RoomRevenueWithoutVATTurnoverAsCustomer
	|FROM
	|	(SELECT
	|		""FACT"" AS DataType,
	|		SalesTurnovers.ReportingCurrency AS ReportingCurrency,
	|		SalesTurnovers.ReportingCurrency.SortCode AS ReportingCurrencySortCode,
	|		SUM(ISNULL(SalesTurnovers.RoomsRentedTurnover, 0)) AS RoomsRentedTurnover,
	|		SUM(ISNULL(SalesTurnovers.GuestDaysTurnover, 0)) AS GuestDaysTurnover,
	|		SUM(ISNULL(SalesTurnovers.RoomsCheckedInTurnover, 0)) AS RoomsCheckedInTurnover,
	|		SUM(ISNULL(SalesTurnovers.GuestsCheckedInTurnover, 0)) AS GuestsCheckedInTurnover,
	|		SUM(ISNULL(SalesTurnovers.SalesTurnover, 0)) AS SalesTurnover,
	|		SUM(ISNULL(SalesTurnovers.SalesWithoutVATTurnover, 0)) AS SalesWithoutVATTurnover,
	|		SUM(ISNULL(SalesTurnovers.RoomRevenueTurnover, 0)) AS RoomRevenueTurnover,
	|		SUM(ISNULL(SalesTurnovers.RoomRevenueWithoutVATTurnover, 0)) AS RoomRevenueWithoutVATTurnover,
	|		0 AS RoomsRentedTurnoverAsCustomer,
	|		0 AS GuestDaysTurnoverAsCustomer,
	|		0 AS RoomsCheckedInTurnoverAsCustomer,
	|		0 AS GuestsCheckedInTurnoverAsCustomer,
	|		0 AS SalesTurnoverAsCustomer,
	|		0 AS SalesWithoutVATTurnoverAsCustomer,
	|		0 AS RoomRevenueTurnoverAsCustomer,
	|		0 AS RoomRevenueWithoutVATTurnoverAsCustomer
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(, , Period, Customer = &qCustomer) AS SalesTurnovers
	|	
	|	GROUP BY
	|		SalesTurnovers.ReportingCurrency,
	|		SalesTurnovers.ReportingCurrency.SortCode
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		""FACT"",
	|		SalesTurnovers.ReportingCurrency,
	|		SalesTurnovers.ReportingCurrency.SortCode,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		SUM(ISNULL(SalesTurnovers.RoomsRentedTurnover, 0)),
	|		SUM(ISNULL(SalesTurnovers.GuestDaysTurnover, 0)),
	|		SUM(ISNULL(SalesTurnovers.RoomsCheckedInTurnover, 0)),
	|		SUM(ISNULL(SalesTurnovers.GuestsCheckedInTurnover, 0)),
	|		SUM(ISNULL(SalesTurnovers.SalesTurnover, 0)),
	|		SUM(ISNULL(SalesTurnovers.SalesWithoutVATTurnover, 0)),
	|		SUM(ISNULL(SalesTurnovers.RoomRevenueTurnover, 0)),
	|		SUM(ISNULL(SalesTurnovers.RoomRevenueWithoutVATTurnover, 0))
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(, , Period, ParentDoc.Customer = &qCustomer) AS SalesTurnovers
	|	
	|	GROUP BY
	|		SalesTurnovers.ReportingCurrency,
	|		SalesTurnovers.ReportingCurrency.SortCode
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		""FORECAST"",
	|		SalesForecastTurnovers.ReportingCurrency,
	|		SalesForecastTurnovers.ReportingCurrency.SortCode,
	|		SUM(ISNULL(SalesForecastTurnovers.RoomsRentedTurnover, 0)),
	|		SUM(ISNULL(SalesForecastTurnovers.GuestDaysTurnover, 0)),
	|		SUM(ISNULL(SalesForecastTurnovers.RoomsCheckedInTurnover, 0)),
	|		SUM(ISNULL(SalesForecastTurnovers.GuestsCheckedInTurnover, 0)),
	|		SUM(ISNULL(SalesForecastTurnovers.SalesTurnover, 0)),
	|		SUM(ISNULL(SalesForecastTurnovers.SalesWithoutVATTurnover, 0)),
	|		SUM(ISNULL(SalesForecastTurnovers.RoomRevenueTurnover, 0)),
	|		SUM(ISNULL(SalesForecastTurnovers.RoomRevenueWithoutVATTurnover, 0)),
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(&qForecastPeriodFrom, , Period, Customer = &qCustomer) AS SalesForecastTurnovers
	|	
	|	GROUP BY
	|		SalesForecastTurnovers.ReportingCurrency,
	|		SalesForecastTurnovers.ReportingCurrency.SortCode
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		""FORECAST"",
	|		SalesForecastTurnovers.ReportingCurrency,
	|		SalesForecastTurnovers.ReportingCurrency.SortCode,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		SUM(ISNULL(SalesForecastTurnovers.RoomsRentedTurnover, 0)),
	|		SUM(ISNULL(SalesForecastTurnovers.GuestDaysTurnover, 0)),
	|		SUM(ISNULL(SalesForecastTurnovers.RoomsCheckedInTurnover, 0)),
	|		SUM(ISNULL(SalesForecastTurnovers.GuestsCheckedInTurnover, 0)),
	|		SUM(ISNULL(SalesForecastTurnovers.SalesTurnover, 0)),
	|		SUM(ISNULL(SalesForecastTurnovers.SalesWithoutVATTurnover, 0)),
	|		SUM(ISNULL(SalesForecastTurnovers.RoomRevenueTurnover, 0)),
	|		SUM(ISNULL(SalesForecastTurnovers.RoomRevenueWithoutVATTurnover, 0))
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(&qForecastPeriodFrom, , Period, ParentDoc.Customer = &qCustomer) AS SalesForecastTurnovers
	|	
	|	GROUP BY
	|		SalesForecastTurnovers.ReportingCurrency,
	|		SalesForecastTurnovers.ReportingCurrency.SortCode) AS CustomerSales
	|
	|GROUP BY
	|	CustomerSales.DataType,
	|	CustomerSales.ReportingCurrency,
	|	CustomerSales.ReportingCurrencySortCode
	|
	|ORDER BY
	|	DataType,
	|	ReportingCurrencySortCode";
	vQry.SetParameter("qForecastPeriodFrom", BegOfDay(CurrentSessionDate()));
	vQry.SetParameter("qCustomer", Ref);
	vQryRes = vQry.Execute().Unload();
	Return vQryRes;
EndFunction // pmGetCustomerRevenueStatistics

// -----------------------------------------------------------------------------
// Get customer reservation statistics
// -----------------------------------------------------------------------------
Function pmGetCustomerReservationStatistics() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ReservationStatusStatistics.ReservationStatus AS ReservationStatus,
	|	ReservationStatusStatistics.ReservationStatus.SortCode AS ReservationStatusSortCode,
	|	SUM(ReservationStatusStatistics.Count) AS Count,
	|	SUM(ReservationStatusStatistics.CountAsCustomer) AS CountAsCustomer
	|FROM
	|	(SELECT
	|		Reservations.ReservationStatus AS ReservationStatus,
	|		COUNT(Reservations.Number) AS Count,
	|		0 AS CountAsCustomer
	|	FROM
	|		Document.Reservation AS Reservations
	|	WHERE
	|		Reservations.Posted
	|		AND Reservations.Customer = &qCustomer
	|		AND ISNULL(Reservations.PlannedPaymentMethod.IsByBankTransfer, FALSE)
	|	
	|	GROUP BY
	|		Reservations.ReservationStatus
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Reservations.ReservationStatus,
	|		0,
	|		COUNT(Reservations.Number)
	|	FROM
	|		Document.Reservation AS Reservations
	|	WHERE
	|		Reservations.Posted
	|		AND Reservations.Customer = &qCustomer
	|	
	|	GROUP BY
	|		Reservations.ReservationStatus) AS ReservationStatusStatistics
	|
	|GROUP BY
	|	ReservationStatusStatistics.ReservationStatus,
	|	ReservationStatusStatistics.ReservationStatus.SortCode
	|
	|ORDER BY
	|	ReservationStatusSortCode";
	vQry.SetParameter("qCustomer", Ref);
	vQryRes = vQry.Execute().Unload();
	Return vQryRes;
EndFunction // pmGetCustomerReservationStatistics

// -----------------------------------------------------------------------------
// Get customer last accommodation
// -----------------------------------------------------------------------------
Function pmGetCustomerLastAccommodation() Export
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
	|	AND Accommodation.Customer = &qCustomer
	|	AND Accommodation.AccommodationStatus.IsCheckOut
	|	AND Accommodation.AccommodationStatus.IsActive
	|
	|ORDER BY
	|	Accommodation.PointInTime DESC";
	vQry.SetParameter("qCustomer", Ref);
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vLastAcc = vQryRes.Ref;
		Break;
	EndDo;
	Return vLastAcc;
EndFunction // pmGetCustomerLastAccommodation

// -----------------------------------------------------------------------------
// Get customer first accommodation
// -----------------------------------------------------------------------------
Function pmGetCustomerFirstAccommodation() Export
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
	|	AND Accommodation.Customer = &qCustomer
	|	AND Accommodation.AccommodationStatus.IsCheckIn
	|	AND Accommodation.AccommodationStatus.IsActive
	|
	|ORDER BY
	|	Accommodation.PointInTime";
	vQry.SetParameter("qCustomer", Ref);
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vFirstAcc = vQryRes.Ref;
		Break;
	EndDo;
	Return vFirstAcc;
EndFunction // pmGetCustomerFirstAccommodation

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure FillCChgAttributes(pCChgRec, pPeriod, pUser) Export
	FillPropertyValues(pCChgRec, ThisObject);
	
	vRef = Ref;
	If IsFolder Then
		vRef = Catalogs.Customers.EmptyRef();	
	EndIf;	
	pCChgRec.Period = pPeriod;
	pCChgRec.Customer = vRef;
	pCChgRec.User = pUser;
	
	// Store tabular parts
	vChargingRules = New ValueStorage(ChargingRules.Unload());
	pCChgRec.ChargingRules = vChargingRules;
	vContactPersons = New ValueStorage(ContactPersons.Unload());
	pCChgRec.ContactPersons = vContactPersons;
	vRoomRates = New ValueStorage(RoomRates.Unload());
	pCChgRec.RoomRates = vRoomRates;
EndProcedure // FillCChgAttributes

#EndRegion
