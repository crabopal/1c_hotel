// -----------------------------------------------------------------------------
// Reports framework start
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure pmSaveReportAttributes(pGenerateOnly = False) Export
	cmSaveReportAttributes(ThisObject, , pGenerateOnly);
EndProcedure // pmSaveReportAttributes

// -----------------------------------------------------------------------------
Procedure pmLoadReportAttributes(pParameter = Undefined) Export
	cmLoadReportAttributes(ThisObject, pParameter);
EndProcedure // pmLoadReportAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill parameters with default values
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(PeriodFrom) Then
		PeriodFrom = BegOfDay(CurrentSessionDate()); // For today
		PeriodTo = EndOfDay(PeriodFrom);
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If Not ValueIsFilled(PeriodFrom) And Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("en='Report period is not set';ru='Период отчета не установлен';de='Berichtszeitraum nicht festgelegt'") + 
		                     ";" + Chars.LF;
	ElsIf ValueIsFilled(PeriodFrom) And Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период c '; en = 'Period from '; de = 'Periode von '") + 
		                     Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm'") + 
		                     ";" + Chars.LF;
	ElsIf Not ValueIsFilled(PeriodFrom) And ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период по '; en = 'Period to '; de = 'Periode zu '") + 
		                     Format(PeriodTo, "DF='dd.MM.yyyy HH:mm'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom = PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период на '; en = 'Period on '; de = 'Periode '") + 
		                     Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom < PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период '; en = 'Period '; de = 'Periode '") + PeriodPresentation(PeriodFrom, PeriodTo, cmLocalizationCode()) + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("en='Period is wrong!';ru='Неправильно задан период!';de='Der Zeitraum wurde falsch eingetragen!'") + 
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(Customer) Then
		If Not Customer.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("de='Firma ';en='Customer ';ru='Контрагент '") + 
			                     TrimAll(Customer.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("de='Gruppe Firmen ';en='Customers folder ';ru='Группа контрагентов '") + 
			                     TrimAll(Customer.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(Contract) Then
		vParamPresentation = vParamPresentation + NStr("en='Contract ';ru='Договор ';de='Vertrag '") + 
							 TrimAll(Contract.Description) + 
							 ";" + Chars.LF;
	EndIf;							 
	If ValueIsFilled(GuestGroup) Then
		vParamPresentation = vParamPresentation + NStr("en='Guest group ';ru='Группа ';de='Gruppe '") + 
							 TrimAll(GuestGroup.Code) + 
							 ";" + Chars.LF;
	EndIf;							 
	If ValueIsFilled(Agent) Then
		If Not Agent.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Agent ';ru='Агент ';de='Vertreter '") + 
			                     TrimAll(Agent.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Agents folder ';ru='Группа агентов ';de='Gruppe Vertreter '") + 
			                     TrimAll(Agent.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(ServiceGroup) Then
		If Not ServiceGroup.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Набор услуг '; en = 'Service group '; de = 'Dienstgruppe '") + 
			                     TrimAll(ServiceGroup.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа наборов услуг '; en = 'Service groups folder '; de = 'Dienstgruppengruppe '") + 
			                     TrimAll(ServiceGroup.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;					 
	If ValueIsFilled(Hotel) Then
		If Not Hotel.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Hotel ';ru='Гостиница ';de='Hotel '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц ';de='Gruppe Hotels '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	Return vParamPresentation;
EndFunction // pmGetReportParametersPresentation

// -----------------------------------------------------------------------------
// Runs report
// -----------------------------------------------------------------------------
Procedure pmGenerate(pSpreadsheet) Export
	Var vTemplateAttributes;
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Fill report parameters
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qServicesPeriodFrom", '00010101');
	ReportBuilder.Parameters.Insert("qServicesPeriodTo", '39991231235959');
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qCustomerIsEmpty", Not ValueIsFilled(Customer));
	ReportBuilder.Parameters.Insert("qContract", Contract);
	ReportBuilder.Parameters.Insert("qContractIsEmpty", Not ValueIsFilled(Contract));
	ReportBuilder.Parameters.Insert("qGuestGroup", GuestGroup);
	ReportBuilder.Parameters.Insert("qGuestGroupIsEmpty", Not ValueIsFilled(GuestGroup));
	ReportBuilder.Parameters.Insert("qAgent", Agent);
	ReportBuilder.Parameters.Insert("qAgentIsEmpty", Not ValueIsFilled(Agent));
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');
	ReportBuilder.Parameters.Insert("qShowExpectedAmounts", ShowExpectedAmounts);
	vShowPrice = False;
	If ReportBuilder.SelectedFields.Find("Price") <> Undefined Then
		vShowPrice = True;
	EndIf;
	ReportBuilder.Parameters.Insert("qShowPrice", vShowPrice);
	vShowExpectedPrice = False;
	If ReportBuilder.SelectedFields.Find("ExpectedPrice") <> Undefined Then
		vShowExpectedPrice = True;
	EndIf;
	ReportBuilder.Parameters.Insert("qShowExpectedPrice", vShowExpectedPrice);
	vShowServices = False;
	If ReportBuilder.SelectedFields.Find("Service") <> Undefined Then
		vShowServices = True;
	EndIf;
	ReportBuilder.Parameters.Insert("qShowServices", vShowServices);
	ReportBuilder.Parameters.Insert("qEmptyService", Catalogs.Services.EmptyRef());
	vShowDates = False;
	If ReportBuilder.SelectedFields.Find("AccountingDate") <> Undefined Then
		vShowDates = True;
	EndIf;
	ReportBuilder.Parameters.Insert("qShowDates", vShowDates);
	vUseServicesList = False;
	vServicesList = New ValueList();
	If ValueIsFilled(ServiceGroup) Then
		If Not ServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(ServiceGroup);
		EndIf;
	EndIf;
	ReportBuilder.Parameters.Insert("qUseServicesList", vUseServicesList);
	ReportBuilder.Parameters.Insert("qServicesList", vServicesList);
	ReportBuilder.Parameters.Insert("qEmptyAccommodationType", Catalogs.AccommodationTypes.EmptyRef());
	ReportBuilder.Parameters.Insert("qEmptyRoomType", Catalogs.RoomTypes.EmptyRef());
	ReportBuilder.Parameters.Insert("qEmptyRoom", Catalogs.Rooms.EmptyRef());
	ReportBuilder.Parameters.Insert("qEmptyRoomRate", Catalogs.RoomRates.EmptyRef());
	ReportBuilder.Parameters.Insert("qEmptyResource", Catalogs.Resources.EmptyRef());
	ReportBuilder.Parameters.Insert("qEmptyReservation", Documents.Reservation.EmptyRef());
	ReportBuilder.Parameters.Insert("qEmptyResourceReservationStatus", Catalogs.ResourceReservationStatuses.EmptyRef());
	ReportBuilder.Parameters.Insert("qEmptyPaymentMethod", Catalogs.PaymentMethods.EmptyRef());
	ReportBuilder.Parameters.Insert("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	ReportBuilder.Parameters.Insert("qEmptyContract", Catalogs.Contracts.EmptyRef());
	ReportBuilder.Parameters.Insert("qEmptyClient", Catalogs.Clients.EmptyRef());
	
	// Execute report builder query
	ReportBuilder.Execute();
	
	// Apply appearance settings to the report template
	vTemplateAttributes = cmApplyReportTemplateAppearance(ThisObject);
	
	// Output report to the spreadsheet
	ReportBuilder.Put(pSpreadsheet);
	//ReportBuilder.Template.Show(); // For debug purpose

	// Apply appearance settings to the report spreadsheet
	cmApplyReportAppearance(ThisObject, pSpreadsheet, vTemplateAttributes);
EndProcedure // pmGenerate
	
// -----------------------------------------------------------------------------
Procedure pmInitializeReportBuilder() Export
	ReportBuilder = New ReportBuilder();
	
	// Initialize default query text
	QueryText = 
	"SELECT
	|	AccountsReceivable.Company AS Company,
	|	AccountsReceivable.Hotel AS Hotel,
	|	AccountsReceivable.FolioCurrency AS FolioCurrency,
	|	ISNULL(AccountsReceivable.Charge.Folio.Agent, &qEmptyCustomer) AS Agent,
	|	ISNULL(AccountsReceivable.Charge.Folio.PaymentMethod, &qEmptyPaymentMethod) AS PaymentMethod,
	|	ISNULL(AccountsReceivable.Charge.ParentDoc.Customer, &qEmptyCustomer) AS Customer,
	|	ISNULL(AccountsReceivable.Charge.ParentDoc.Contract, &qEmptyContract) AS Contract,
	|	AccountsReceivable.GuestGroup AS GuestGroup,
	|	AccountsReceivable.Charge.ParentDoc AS ParentDoc,
	|	CAST(AccountsReceivable.Charge.ParentDoc.Remarks AS STRING(1024)) AS Remarks,
	|	ISNULL(AccountsReceivable.Charge.Service, &qEmptyService) AS Service,
	|	BEGINOFPERIOD(AccountsReceivable.Period, DAY) AS AccountingDate,
	|	CASE
	|		WHEN NOT AccountsReceivable.Charge.ParentDoc.Guest IS NULL
	|			THEN AccountsReceivable.Charge.ParentDoc.Guest
	|		WHEN NOT AccountsReceivable.Charge.ParentDoc.Client IS NULL
	|			THEN AccountsReceivable.Charge.ParentDoc.Client
	|		ELSE ISNULL(AccountsReceivable.Charge.Folio.Client, &qEmptyClient)
	|	END AS Client,
	|	CASE
	|		WHEN AccountsReceivable.Charge.ParentDoc.CheckInDate IS NULL
	|			THEN ISNULL(AccountsReceivable.Charge.Folio.DateTimeFrom, &qEmptyDate)
	|		ELSE AccountsReceivable.Charge.ParentDoc.CheckInDate
	|	END AS CheckInDate,
	|	CASE
	|		WHEN AccountsReceivable.Charge.ParentDoc.CheckOutDate IS NULL
	|			THEN ISNULL(AccountsReceivable.Charge.Folio.DateTimeTo, &qEmptyDate)
	|		ELSE AccountsReceivable.Charge.ParentDoc.CheckOutDate
	|	END AS CheckOutDate,
	|	CASE
	|		WHEN NOT AccountsReceivable.Charge.ParentDoc.AccommodationStatus IS NULL
	|			THEN AccountsReceivable.Charge.ParentDoc.AccommodationStatus
	|		WHEN NOT AccountsReceivable.Charge.ParentDoc.ReservationStatus IS NULL
	|			THEN AccountsReceivable.Charge.ParentDoc.ReservationStatus
	|		ELSE ISNULL(AccountsReceivable.Charge.ParentDoc.ResourceReservationStatus, &qEmptyResourceReservationStatus)
	|	END AS Status,
	|	CASE
	|		WHEN AccountsReceivable.Charge.AccommodationType = &qEmptyAccommodationType
	|				AND NOT AccountsReceivable.Charge.ParentDoc.AccommodationType IS NULL
	|			THEN AccountsReceivable.Charge.ParentDoc.AccommodationType
	|		ELSE ISNULL(AccountsReceivable.Charge.AccommodationType, &qEmptyAccommodationtype)
	|	END AS AccommodationType,
	|	CASE
	|		WHEN AccountsReceivable.Charge.Room = &qEmptyRoom
	|				AND NOT AccountsReceivable.Charge.ParentDoc.Room IS NULL
	|			THEN AccountsReceivable.Charge.ParentDoc.Room
	|		ELSE ISNULL(AccountsReceivable.Charge.Room, &qEmptyRoom)
	|	END AS Room,
	|	CASE
	|		WHEN AccountsReceivable.Charge.RoomType = &qEmptyRoomType
	|				AND NOT AccountsReceivable.Charge.ParentDoc.RoomType IS NULL
	|			THEN AccountsReceivable.Charge.ParentDoc.RoomType
	|		ELSE ISNULL(AccountsReceivable.Charge.RoomType, &qEmptyRoomType)
	|	END AS RoomType,
	|	ISNULL(AccountsReceivable.Charge.ParentDoc.Resource, &qEmptyResource) AS Resource,
	|	CASE
	|		WHEN AccountsReceivable.Charge.RoomRate = &qEmptyRoomRate
	|				AND NOT AccountsReceivable.Charge.ParentDoc.RoomRate IS NULL
	|			THEN AccountsReceivable.Charge.ParentDoc.RoomRate
	|		ELSE ISNULL(AccountsReceivable.Charge.RoomRate, &qEmptyRoomRate)
	|	END AS RoomRate,
	|	CASE
	|		WHEN AccountsReceivable.Charge.ParentDoc.DateTimeFrom IS NULL
	|			THEN ISNULL(AccountsReceivable.Charge.ParentDoc.Reservation, &qEmptyReservation)
	|		ELSE AccountsReceivable.Charge.ParentDoc
	|	END AS Reservation,
	|	CASE
	|		WHEN AccountsReceivable.Quantity <> 0
	|			THEN CAST((ISNULL(AccountsReceivable.Charge.Sum, 0) - ISNULL(AccountsReceivable.Charge.DiscountSum, 0)) / AccountsReceivable.Quantity AS NUMBER(17, 2))
	|		ELSE 0
	|	END AS Price,
	|	ISNULL(AccountsReceivable.Charge.IsSplit, FALSE) AS IsSplit,
	|	SUM(AccountsReceivable.Quantity) AS Quantity,
	|	SUM(AccountsReceivable.Sum) AS Sales,
	|	SUM(AccountsReceivable.Sum - AccountsReceivable.VATSum) AS SalesWithoutVAT,
	|	SUM(CASE
	|			WHEN ISNULL(AccountsReceivable.Charge.IsRoomRevenue, FALSE)
	|				THEN AccountsReceivable.Sum
	|			ELSE 0
	|		END) AS RoomRevenue,
	|	SUM(CASE
	|			WHEN ISNULL(AccountsReceivable.Charge.IsRoomRevenue, FALSE)
	|				THEN AccountsReceivable.Sum - AccountsReceivable.VATSum
	|			ELSE 0
	|		END) AS RoomRevenueWithoutVAT,
	|	SUM(CASE
	|			WHEN AccountsReceivable.Recorder.ParentCharge IS NULL
	|				THEN ISNULL(AccountsReceivable.Charge.CommissionSum, 0)
	|			ELSE -ISNULL(AccountsReceivable.Charge.CommissionSum, 0)
	|		END) AS CommissionSum,
	|	SUM(CASE
	|			WHEN AccountsReceivable.Recorder.ParentCharge IS NULL
	|				THEN ISNULL(AccountsReceivable.Charge.CommissionSum, 0) - ISNULL(AccountsReceivable.Charge.VATCommissionSum, 0)
	|			ELSE -(ISNULL(AccountsReceivable.Charge.CommissionSum, 0) - ISNULL(AccountsReceivable.Charge.VATCommissionSum, 0))
	|		END) AS CommissionSumWithoutVAT,
	|	SUM(CASE
	|			WHEN AccountsReceivable.Recorder.ParentCharge IS NULL
	|				THEN ISNULL(AccountsReceivable.Charge.DiscountSum, 0)
	|			ELSE -ISNULL(AccountsReceivable.Charge.DiscountSum, 0)
	|		END) AS DiscountSum,
	|	SUM(CASE
	|			WHEN AccountsReceivable.Recorder.ParentCharge IS NULL
	|				THEN ISNULL(AccountsReceivable.Charge.DiscountSum, 0) - ISNULL(AccountsReceivable.Charge.VATDiscountSum, 0)
	|			ELSE -(ISNULL(AccountsReceivable.Charge.DiscountSum, 0) - ISNULL(AccountsReceivable.Charge.VATDiscountSum, 0))
	|		END) AS DiscountSumWithoutVAT,
	|	SUM(CASE
	|			WHEN AccountsReceivable.Recorder.ParentCharge IS NULL
	|				THEN ISNULL(AccountsReceivable.Charge.RoomsRented, 0)
	|			ELSE -ISNULL(AccountsReceivable.Charge.RoomsRented, 0)
	|		END) AS RoomsRented,
	|	SUM(CASE
	|			WHEN AccountsReceivable.Recorder.ParentCharge IS NULL
	|				THEN ISNULL(AccountsReceivable.Charge.BedsRented, 0)
	|			ELSE -ISNULL(AccountsReceivable.Charge.BedsRented, 0)
	|		END) AS BedsRented,
	|	SUM(CASE
	|			WHEN AccountsReceivable.Recorder.ParentCharge IS NULL
	|				THEN ISNULL(AccountsReceivable.Charge.AdditionalBedsRented, 0)
	|			ELSE -ISNULL(AccountsReceivable.Charge.AdditionalBedsRented, 0)
	|		END) AS AdditionalBedsRented,
	|	SUM(CASE
	|			WHEN AccountsReceivable.Recorder.ParentCharge IS NULL
	|				THEN ISNULL(AccountsReceivable.Charge.GuestDays, 0)
	|			ELSE -ISNULL(AccountsReceivable.Charge.GuestDays, 0)
	|		END) AS GuestDays,
	|	SUM(CASE
	|			WHEN AccountsReceivable.Recorder.ParentCharge IS NULL
	|				THEN ISNULL(AccountsReceivable.Charge.GuestsCheckedIn, 0)
	|			ELSE -ISNULL(AccountsReceivable.Charge.GuestsCheckedIn, 0)
	|		END) AS GuestsCheckedIn,
	|	SUM(CASE
	|			WHEN AccountsReceivable.Quantity > 0
	|					AND ISNULL(AccountsReceivable.Charge.GuestsCheckedIn, 0) <> 0
	|					AND AccountsReceivable.Recorder.ParentCharge IS NULL
	|				THEN ISNULL(AccountsReceivable.Charge.RoomsRented, 0) / AccountsReceivable.Quantity
	|			WHEN AccountsReceivable.Quantity < 0
	|					AND ISNULL(AccountsReceivable.Charge.GuestsCheckedIn, 0) <> 0
	|					AND AccountsReceivable.Recorder.ParentCharge IS NULL
	|				THEN -ISNULL(AccountsReceivable.Charge.RoomsRented, 0) / AccountsReceivable.Quantity
	|			WHEN AccountsReceivable.Quantity > 0
	|					AND ISNULL(AccountsReceivable.Charge.GuestsCheckedIn, 0) <> 0
	|					AND AccountsReceivable.Recorder.ParentCharge IS NOT NULL 
	|				THEN -ISNULL(AccountsReceivable.Charge.RoomsRented, 0) / AccountsReceivable.Quantity
	|			WHEN AccountsReceivable.Quantity < 0
	|					AND ISNULL(AccountsReceivable.Charge.GuestsCheckedIn, 0) <> 0
	|					AND AccountsReceivable.Recorder.ParentCharge IS NOT NULL 
	|				THEN ISNULL(AccountsReceivable.Charge.RoomsRented, 0) / AccountsReceivable.Quantity
	|			ELSE 0
	|		END) AS RoomsCheckedIn,
	|	SUM(CASE
	|			WHEN AccountsReceivable.Quantity > 0
	|					AND ISNULL(AccountsReceivable.Charge.GuestsCheckedIn, 0) <> 0
	|					AND AccountsReceivable.Recorder.ParentCharge IS NULL
	|				THEN ISNULL(AccountsReceivable.Charge.BedsRented, 0) / AccountsReceivable.Quantity
	|			WHEN AccountsReceivable.Quantity < 0
	|					AND ISNULL(AccountsReceivable.Charge.GuestsCheckedIn, 0) <> 0
	|					AND AccountsReceivable.Recorder.ParentCharge IS NULL
	|				THEN -ISNULL(AccountsReceivable.Charge.BedsRented, 0) / AccountsReceivable.Quantity
	|			WHEN AccountsReceivable.Quantity > 0
	|					AND ISNULL(AccountsReceivable.Charge.GuestsCheckedIn, 0) <> 0
	|					AND AccountsReceivable.Recorder.ParentCharge IS NOT NULL 
	|				THEN -ISNULL(AccountsReceivable.Charge.BedsRented, 0) / AccountsReceivable.Quantity
	|			WHEN AccountsReceivable.Quantity < 0
	|					AND ISNULL(AccountsReceivable.Charge.GuestsCheckedIn, 0) <> 0
	|					AND AccountsReceivable.Recorder.ParentCharge IS NOT NULL 
	|				THEN ISNULL(AccountsReceivable.Charge.BedsRented, 0) / AccountsReceivable.Quantity
	|			ELSE 0
	|		END) AS BedsCheckedIn,
	|	SUM(CASE
	|			WHEN AccountsReceivable.Quantity > 0
	|					AND ISNULL(AccountsReceivable.Charge.GuestsCheckedIn, 0) <> 0
	|					AND AccountsReceivable.Recorder.ParentCharge IS NULL
	|				THEN ISNULL(AccountsReceivable.Charge.AdditionalBedsRented, 0) / AccountsReceivable.Quantity
	|			WHEN AccountsReceivable.Quantity < 0
	|					AND ISNULL(AccountsReceivable.Charge.GuestsCheckedIn, 0) <> 0
	|					AND AccountsReceivable.Recorder.ParentCharge IS NULL
	|				THEN -ISNULL(AccountsReceivable.Charge.AdditionalBedsRented, 0) / AccountsReceivable.Quantity
	|			WHEN AccountsReceivable.Quantity > 0
	|					AND ISNULL(AccountsReceivable.Charge.GuestsCheckedIn, 0) <> 0
	|					AND AccountsReceivable.Recorder.ParentCharge IS NOT NULL 
	|				THEN -ISNULL(AccountsReceivable.Charge.AdditionalBedsRented, 0) / AccountsReceivable.Quantity
	|			WHEN AccountsReceivable.Quantity < 0
	|					AND ISNULL(AccountsReceivable.Charge.GuestsCheckedIn, 0) <> 0
	|					AND AccountsReceivable.Recorder.ParentCharge IS NOT NULL 
	|				THEN ISNULL(AccountsReceivable.Charge.AdditionalBedsRented, 0) / AccountsReceivable.Quantity
	|			ELSE 0
	|		END) AS AdditionalBedsCheckedIn
	|INTO ChargedAccountsReceivable
	|FROM
	|	AccumulationRegister.CurrentAccountsReceivable AS AccountsReceivable
	|WHERE
	|	AccountsReceivable.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND AccountsReceivable.Period >= &qServicesPeriodFrom
	|	AND AccountsReceivable.Period <= &qServicesPeriodTo
	|	AND AccountsReceivable.Hotel IN HIERARCHY(&qHotel)
	|	AND (AccountsReceivable.Charge.ParentDoc.Customer IN HIERARCHY (&qCustomer)
	|			OR &qCustomerIsEmpty)
	|	AND (AccountsReceivable.Charge.ParentDoc.Contract IN HIERARCHY (&qContract)
	|			OR &qContractIsEmpty)
	|	AND (AccountsReceivable.GuestGroup = &qGuestGroup
	|			OR &qGuestGroupIsEmpty)
	|	AND (AccountsReceivable.Charge.Folio.Agent IN HIERARCHY (&qAgent)
	|			OR &qAgentIsEmpty)
	|	AND (NOT AccountsReceivable.Charge.ParentDoc.CheckInDate IS NULL
	|				AND AccountsReceivable.Charge.ParentDoc.CheckInDate >= &qPeriodFrom
	|			OR NOT AccountsReceivable.Charge.ParentDoc.DateTimeFrom IS NULL
	|				AND AccountsReceivable.Charge.ParentDoc.DateTimeFrom >= &qPeriodFrom)
	|	AND (NOT AccountsReceivable.Charge.ParentDoc.CheckInDate IS NULL
	|				AND AccountsReceivable.Charge.ParentDoc.CheckInDate <= &qPeriodTo
	|			OR NOT AccountsReceivable.Charge.ParentDoc.DateTimeFrom IS NULL
	|				AND AccountsReceivable.Charge.ParentDoc.DateTimeFrom <= &qPeriodTo)
	|	AND (AccountsReceivable.Charge.Service IN (&qServicesList)
	|			OR NOT &qUseServicesList)
	|	AND (AccountsReceivable.Sum <> 0
	|			OR AccountsReceivable.Quantity <> 0)
	|
	|GROUP BY
	|	AccountsReceivable.Company,
	|	AccountsReceivable.Hotel,
	|	AccountsReceivable.FolioCurrency,
	|	ISNULL(AccountsReceivable.Charge.Folio.Agent, &qEmptyCustomer),
	|	ISNULL(AccountsReceivable.Charge.Folio.PaymentMethod, &qEmptyPaymentMethod),
	|	ISNULL(AccountsReceivable.Charge.ParentDoc.Customer, &qEmptyCustomer),
	|	ISNULL(AccountsReceivable.Charge.ParentDoc.Contract, &qEmptyContract),
	|	AccountsReceivable.GuestGroup,
	|	AccountsReceivable.Charge.ParentDoc,
	|	CAST(AccountsReceivable.Charge.ParentDoc.Remarks AS STRING(1024)),
	|	ISNULL(AccountsReceivable.Charge.Service, &qEmptyService),
	|	BEGINOFPERIOD(AccountsReceivable.Period, DAY),
	|	CASE
	|		WHEN NOT AccountsReceivable.Charge.ParentDoc.Guest IS NULL
	|			THEN AccountsReceivable.Charge.ParentDoc.Guest
	|		WHEN NOT AccountsReceivable.Charge.ParentDoc.Client IS NULL
	|			THEN AccountsReceivable.Charge.ParentDoc.Client
	|		ELSE ISNULL(AccountsReceivable.Charge.Folio.Client, &qEmptyClient)
	|	END,
	|	CASE
	|		WHEN AccountsReceivable.Charge.ParentDoc.CheckInDate IS NULL
	|			THEN ISNULL(AccountsReceivable.Charge.Folio.DateTimeFrom, &qEmptyDate)
	|		ELSE AccountsReceivable.Charge.ParentDoc.CheckInDate
	|	END,
	|	CASE
	|		WHEN AccountsReceivable.Charge.ParentDoc.CheckOutDate IS NULL
	|			THEN ISNULL(AccountsReceivable.Charge.Folio.DateTimeTo, &qEmptyDate)
	|		ELSE AccountsReceivable.Charge.ParentDoc.CheckOutDate
	|	END,
	|	CASE
	|		WHEN NOT AccountsReceivable.Charge.ParentDoc.AccommodationStatus IS NULL
	|			THEN AccountsReceivable.Charge.ParentDoc.AccommodationStatus
	|		WHEN NOT AccountsReceivable.Charge.ParentDoc.ReservationStatus IS NULL
	|			THEN AccountsReceivable.Charge.ParentDoc.ReservationStatus
	|		ELSE ISNULL(AccountsReceivable.Charge.ParentDoc.ResourceReservationStatus, &qEmptyResourceReservationStatus)
	|	END,
	|	CASE
	|		WHEN AccountsReceivable.Charge.AccommodationType = &qEmptyAccommodationType
	|				AND NOT AccountsReceivable.Charge.ParentDoc.AccommodationType IS NULL
	|			THEN AccountsReceivable.Charge.ParentDoc.AccommodationType
	|		ELSE ISNULL(AccountsReceivable.Charge.AccommodationType, &qEmptyAccommodationtype)
	|	END,
	|	CASE
	|		WHEN AccountsReceivable.Charge.Room = &qEmptyRoom
	|				AND NOT AccountsReceivable.Charge.ParentDoc.Room IS NULL
	|			THEN AccountsReceivable.Charge.ParentDoc.Room
	|		ELSE ISNULL(AccountsReceivable.Charge.Room, &qEmptyRoom)
	|	END,
	|	CASE
	|		WHEN AccountsReceivable.Charge.RoomType = &qEmptyRoomType
	|				AND NOT AccountsReceivable.Charge.ParentDoc.RoomType IS NULL
	|			THEN AccountsReceivable.Charge.ParentDoc.RoomType
	|		ELSE ISNULL(AccountsReceivable.Charge.RoomType, &qEmptyRoomType)
	|	END,
	|	ISNULL(AccountsReceivable.Charge.ParentDoc.Resource, &qEmptyResource),
	|	CASE
	|		WHEN AccountsReceivable.Charge.RoomRate = &qEmptyRoomRate
	|				AND NOT AccountsReceivable.Charge.ParentDoc.RoomRate IS NULL
	|			THEN AccountsReceivable.Charge.ParentDoc.RoomRate
	|		ELSE ISNULL(AccountsReceivable.Charge.RoomRate, &qEmptyRoomRate)
	|	END,
	|	CASE
	|		WHEN AccountsReceivable.Charge.ParentDoc.DateTimeFrom IS NULL
	|			THEN ISNULL(AccountsReceivable.Charge.ParentDoc.Reservation, &qEmptyReservation)
	|		ELSE AccountsReceivable.Charge.ParentDoc
	|	END,
	|	CASE
	|		WHEN AccountsReceivable.Quantity <> 0
	|			THEN CAST((ISNULL(AccountsReceivable.Charge.Sum, 0) - ISNULL(AccountsReceivable.Charge.DiscountSum, 0)) / AccountsReceivable.Quantity AS NUMBER(17, 2))
	|		ELSE 0
	|	END,
	|	ISNULL(AccountsReceivable.Charge.IsSplit, FALSE)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccountsReceivableForecast.Company AS Company,
	|	AccountsReceivableForecast.Hotel AS Hotel,
	|	AccountsReceivableForecast.FolioCurrency AS FolioCurrency,
	|	AccountsReceivableForecast.Agent AS Agent,
	|	AccountsReceivableForecast.PaymentMethod AS PaymentMethod,
	|	ISNULL(AccountsReceivableForecast.Recorder.Customer, &qEmptyCustomer) AS Customer,
	|	ISNULL(AccountsReceivableForecast.Recorder.Contract, &qEmptyContract) AS Contract,
	|	AccountsReceivableForecast.GuestGroup AS GuestGroup,
	|	AccountsReceivableForecast.Recorder AS ParentDoc,
	|	CAST(AccountsReceivableForecast.Recorder.Remarks AS STRING(1024)) AS Remarks,
	|	AccountsReceivableForecast.Service AS Service,
	|	AccountsReceivableForecast.AccountingDate AS AccountingDate,
	|	AccountsReceivableForecast.Client AS Client,
	|	ISNULL(AccountsReceivableForecast.Recorder.CheckInDate, &qEmptyDate) AS CheckInDate,
	|	ISNULL(AccountsReceivableForecast.Recorder.CheckOutDate, &qEmptyDate) AS CheckOutDate,
	|	CASE
	|		WHEN NOT AccountsReceivableForecast.Recorder.ReservationStatus IS NULL
	|			THEN AccountsReceivableForecast.Recorder.ReservationStatus
	|		ELSE ISNULL(AccountsReceivableForecast.Recorder.ResourceReservationStatus, &qEmptyResourceReservationStatus)
	|	END AS Status,
	|	CASE
	|		WHEN AccountsReceivableForecast.AccommodationType = &qEmptyAccommodationType
	|				AND NOT AccountsReceivableForecast.Recorder.AccommodationType IS NULL
	|			THEN AccountsReceivableForecast.Recorder.AccommodationType
	|		ELSE AccountsReceivableForecast.AccommodationType
	|	END AS AccommodationType,
	|	CASE
	|		WHEN AccountsReceivableForecast.Room = &qEmptyRoom
	|				AND NOT AccountsReceivableForecast.Recorder.Room IS NULL
	|			THEN AccountsReceivableForecast.Recorder.Room
	|		ELSE AccountsReceivableForecast.Room
	|	END AS Room,
	|	CASE
	|		WHEN AccountsReceivableForecast.RoomType = &qEmptyRoomType
	|				AND NOT AccountsReceivableForecast.Recorder.RoomType IS NULL
	|			THEN AccountsReceivableForecast.Recorder.RoomType
	|		ELSE AccountsReceivableForecast.RoomType
	|	END AS RoomType,
	|	CASE
	|		WHEN AccountsReceivableForecast.Resource = &qEmptyResource
	|				AND NOT AccountsReceivableForecast.Recorder.Resource IS NULL
	|			THEN AccountsReceivableForecast.Recorder.Resource
	|		ELSE AccountsReceivableForecast.Resource
	|	END AS Resource,
	|	CASE
	|		WHEN AccountsReceivableForecast.RoomRate = &qEmptyRoomRate
	|				AND NOT AccountsReceivableForecast.Recorder.RoomRate IS NULL
	|			THEN AccountsReceivableForecast.Recorder.RoomRate
	|		ELSE AccountsReceivableForecast.RoomRate
	|	END AS RoomRate,
	|	AccountsReceivableForecast.Recorder AS Reservation,
	|	CASE
	|		WHEN NOT &qShowExpectedPrice
	|			THEN 0
	|		WHEN AccountsReceivableForecast.ExpectedQuantity <> 0
	|			THEN CAST(AccountsReceivableForecast.ExpectedSales / AccountsReceivableForecast.ExpectedQuantity AS NUMBER(17, 2))
	|		ELSE 0
	|	END AS ExpectedPrice,
	|	AccountsReceivableForecast.IsSplit AS IsSplit,
	|	SUM(AccountsReceivableForecast.ExpectedQuantity) AS ExpectedQuantity,
	|	SUM(AccountsReceivableForecast.ExpectedSales) AS ExpectedSales,
	|	SUM(AccountsReceivableForecast.ExpectedSalesWithoutVAT) AS ExpectedSalesWithoutVAT,
	|	SUM(AccountsReceivableForecast.ExpectedRoomRevenue) AS ExpectedRoomRevenue,
	|	SUM(AccountsReceivableForecast.ExpectedRoomRevenueWithoutVAT) AS ExpectedRoomRevenueWithoutVAT,
	|	SUM(AccountsReceivableForecast.ExpectedCommissionSum) AS ExpectedCommissionSum,
	|	SUM(AccountsReceivableForecast.ExpectedCommissionSumWithoutVAT) AS ExpectedCommissionSumWithoutVAT,
	|	SUM(AccountsReceivableForecast.ExpectedDiscountSum) AS ExpectedDiscountSum,
	|	SUM(AccountsReceivableForecast.ExpectedDiscountSumWithoutVAT) AS ExpectedDiscountSumWithoutVAT,
	|	SUM(AccountsReceivableForecast.ExpectedRoomsRented) AS ExpectedRoomsRented,
	|	SUM(AccountsReceivableForecast.ExpectedBedsRented) AS ExpectedBedsRented,
	|	SUM(AccountsReceivableForecast.ExpectedAdditionalBedsRented) AS ExpectedAdditionalBedsRented,
	|	SUM(AccountsReceivableForecast.ExpectedGuestDays) AS ExpectedGuestDays,
	|	SUM(AccountsReceivableForecast.ExpectedGuestsCheckedIn) AS ExpectedGuestsCheckedIn,
	|	SUM(AccountsReceivableForecast.ExpectedRoomsCheckedIn) AS ExpectedRoomsCheckedIn,
	|	SUM(AccountsReceivableForecast.ExpectedBedsCheckedIn) AS ExpectedBedsCheckedIn,
	|	SUM(AccountsReceivableForecast.ExpectedAdditionalBedsCheckedIn) AS ExpectedAdditionalBedsCheckedIn
	|INTO ExpectedAccountsReceivable
	|FROM
	|	AccumulationRegister.AccountsReceivableForecast AS AccountsReceivableForecast
	|WHERE
	|	&qShowExpectedAmounts
	|	AND AccountsReceivableForecast.Period >= &qServicesPeriodFrom
	|	AND AccountsReceivableForecast.Period <= &qServicesPeriodTo
	|	AND AccountsReceivableForecast.Hotel IN HIERARCHY(&qHotel)
	|	AND (AccountsReceivableForecast.Recorder.Customer IN HIERARCHY (&qCustomer)
	|			OR &qCustomerIsEmpty)
	|	AND (AccountsReceivableForecast.Recorder.Contract IN HIERARCHY (&qContract)
	|			OR &qContractIsEmpty)
	|	AND (AccountsReceivableForecast.GuestGroup = &qGuestGroup
	|			OR &qGuestGroupIsEmpty)
	|	AND (AccountsReceivableForecast.Agent IN HIERARCHY (&qAgent)
	|			OR &qAgentIsEmpty)
	|	AND (NOT AccountsReceivableForecast.Recorder.CheckInDate IS NULL
	|				AND AccountsReceivableForecast.Recorder.CheckInDate >= &qPeriodFrom
	|			OR NOT AccountsReceivableForecast.Recorder.DateTimeFrom IS NULL
	|				AND AccountsReceivableForecast.Recorder.DateTimeFrom >= &qPeriodFrom)
	|	AND (NOT AccountsReceivableForecast.Recorder.CheckInDate IS NULL
	|				AND AccountsReceivableForecast.Recorder.CheckInDate <= &qPeriodTo
	|			OR NOT AccountsReceivableForecast.Recorder.DateTimeFrom IS NULL
	|				AND AccountsReceivableForecast.Recorder.DateTimeFrom <= &qPeriodTo)
	|	AND (AccountsReceivableForecast.Service IN (&qServicesList)
	|			OR NOT &qUseServicesList)
	|	AND (AccountsReceivableForecast.ExpectedQuantity <> 0
	|			OR AccountsReceivableForecast.ExpectedSales <> 0)
	|
	|GROUP BY
	|	AccountsReceivableForecast.Company,
	|	AccountsReceivableForecast.Hotel,
	|	AccountsReceivableForecast.FolioCurrency,
	|	AccountsReceivableForecast.Agent,
	|	AccountsReceivableForecast.PaymentMethod,
	|	ISNULL(AccountsReceivableForecast.Recorder.Customer, &qEmptyCustomer),
	|	ISNULL(AccountsReceivableForecast.Recorder.Contract, &qEmptyContract),
	|	AccountsReceivableForecast.GuestGroup,
	|	AccountsReceivableForecast.Recorder,
	|	CAST(AccountsReceivableForecast.Recorder.Remarks AS STRING(1024)),
	|	AccountsReceivableForecast.Service,
	|	AccountsReceivableForecast.AccountingDate,
	|	AccountsReceivableForecast.Client,
	|	ISNULL(AccountsReceivableForecast.Recorder.CheckInDate, &qEmptyDate),
	|	ISNULL(AccountsReceivableForecast.Recorder.CheckOutDate, &qEmptyDate),
	|	CASE
	|		WHEN NOT AccountsReceivableForecast.Recorder.ReservationStatus IS NULL
	|			THEN AccountsReceivableForecast.Recorder.ReservationStatus
	|		ELSE ISNULL(AccountsReceivableForecast.Recorder.ResourceReservationStatus, &qEmptyResourceReservationStatus)
	|	END,
	|	CASE
	|		WHEN AccountsReceivableForecast.AccommodationType = &qEmptyAccommodationType
	|				AND NOT AccountsReceivableForecast.Recorder.AccommodationType IS NULL
	|			THEN AccountsReceivableForecast.Recorder.AccommodationType
	|		ELSE AccountsReceivableForecast.AccommodationType
	|	END,
	|	CASE
	|		WHEN AccountsReceivableForecast.Room = &qEmptyRoom
	|				AND NOT AccountsReceivableForecast.Recorder.Room IS NULL
	|			THEN AccountsReceivableForecast.Recorder.Room
	|		ELSE AccountsReceivableForecast.Room
	|	END,
	|	CASE
	|		WHEN AccountsReceivableForecast.RoomType = &qEmptyRoomType
	|				AND NOT AccountsReceivableForecast.Recorder.RoomType IS NULL
	|			THEN AccountsReceivableForecast.Recorder.RoomType
	|		ELSE AccountsReceivableForecast.RoomType
	|	END,
	|	CASE
	|		WHEN AccountsReceivableForecast.Resource = &qEmptyResource
	|				AND NOT AccountsReceivableForecast.Recorder.Resource IS NULL
	|			THEN AccountsReceivableForecast.Recorder.Resource
	|		ELSE AccountsReceivableForecast.Resource
	|	END,
	|	CASE
	|		WHEN AccountsReceivableForecast.RoomRate = &qEmptyRoomRate
	|				AND NOT AccountsReceivableForecast.Recorder.RoomRate IS NULL
	|			THEN AccountsReceivableForecast.Recorder.RoomRate
	|		ELSE AccountsReceivableForecast.RoomRate
	|	END,
	|	CASE
	|		WHEN NOT &qShowExpectedPrice
	|			THEN 0
	|		WHEN AccountsReceivableForecast.ExpectedQuantity <> 0
	|			THEN CAST(AccountsReceivableForecast.ExpectedSales / AccountsReceivableForecast.ExpectedQuantity AS NUMBER(17, 2))
	|		ELSE 0
	|	END,
	|	AccountsReceivableForecast.IsSplit,
	|	AccountsReceivableForecast.Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomerTurnovers.Company AS Company,
	|	CustomerTurnovers.Hotel AS Hotel,
	|	CustomerTurnovers.FolioCurrency AS FolioCurrency,
	|	CustomerTurnovers.PaymentMethod AS PaymentMethod,
	|	CustomerTurnovers.Agent AS Agent,
	|	CustomerTurnovers.Customer AS Customer,
	|	CustomerTurnovers.Contract AS Contract,
	|	CustomerTurnovers.GuestGroup AS GuestGroup,
	|	CustomerTurnovers.ParentDoc AS ParentDoc,
	|	CustomerTurnovers.Reservation AS Reservation,
	|	CustomerTurnovers.Client AS Client,
	|	CustomerTurnovers.CheckInDate AS CheckInDate,
	|	CustomerTurnovers.CheckOutDate AS CheckOutDate,
	|	CustomerTurnovers.AccommodationType AS AccommodationType,
	|	CustomerTurnovers.Status AS Status,
	|	CustomerTurnovers.Room AS Room,
	|	CustomerTurnovers.RoomType AS RoomType,
	|	CustomerTurnovers.Resource AS Resource,
	|	CustomerTurnovers.Service AS Service,
	|	CustomerTurnovers.AccountingDate AS AccountingDate,
	|	CustomerTurnovers.Sales AS Sales,
	|	CustomerTurnovers.SalesWithoutVAT AS SalesWithoutVAT,
	|	CustomerTurnovers.RoomRevenue AS RoomRevenue,
	|	CustomerTurnovers.RoomRevenueWithoutVAT AS RoomRevenueWithoutVAT,
	|	CustomerTurnovers.CommissionSum AS CommissionSum,
	|	CustomerTurnovers.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	CustomerTurnovers.DiscountSum AS DiscountSum,
	|	CustomerTurnovers.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|	CustomerTurnovers.RoomsRented AS RoomsRented,
	|	CustomerTurnovers.BedsRented AS BedsRented,
	|	CustomerTurnovers.AdditionalBedsRented AS AdditionalBedsRented,
	|	CustomerTurnovers.GuestDays AS GuestDays,
	|	CustomerTurnovers.GuestsCheckedIn AS GuestsCheckedIn,
	|	CustomerTurnovers.RoomsCheckedIn AS RoomsCheckedIn,
	|	CustomerTurnovers.BedsCheckedIn AS BedsCheckedIn,
	|	CustomerTurnovers.AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn,
	|	CustomerTurnovers.Quantity AS Quantity,
	|	CustomerTurnovers.ExpectedSales AS ExpectedSales,
	|	CustomerTurnovers.ExpectedSalesWithoutVAT AS ExpectedSalesWithoutVAT,
	|	CustomerTurnovers.ExpectedRoomRevenue AS ExpectedRoomRevenue,
	|	CustomerTurnovers.ExpectedRoomRevenueWithoutVAT AS ExpectedRoomRevenueWithoutVAT,
	|	CustomerTurnovers.ExpectedCommissionSum AS ExpectedCommissionSum,
	|	CustomerTurnovers.ExpectedCommissionSumWithoutVAT AS ExpectedCommissionSumWithoutVAT,
	|	CustomerTurnovers.ExpectedDiscountSum AS ExpectedDiscountSum,
	|	CustomerTurnovers.ExpectedDiscountSumWithoutVAT AS ExpectedDiscountSumWithoutVAT,
	|	CustomerTurnovers.ExpectedRoomsRented AS ExpectedRoomsRented,
	|	CustomerTurnovers.ExpectedBedsRented AS ExpectedBedsRented,
	|	CustomerTurnovers.ExpectedAdditionalBedsRented AS ExpectedAdditionalBedsRented,
	|	CustomerTurnovers.ExpectedGuestDays AS ExpectedGuestDays,
	|	CustomerTurnovers.ExpectedGuestsCheckedIn AS ExpectedGuestsCheckedIn,
	|	CustomerTurnovers.ExpectedRoomsCheckedIn AS ExpectedRoomsCheckedIn,
	|	CustomerTurnovers.ExpectedBedsCheckedIn AS ExpectedBedsCheckedIn,
	|	CustomerTurnovers.ExpectedAdditionalBedsCheckedIn AS ExpectedAdditionalBedsCheckedIn,
	|	CustomerTurnovers.ExpectedQuantity AS ExpectedQuantity
	|{SELECT
	|	Company.*,
	|	Hotel.*,
	|	FolioCurrency.*,
	|	PaymentMethod.*,
	|	Agent.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	Client.*,
	|	CheckInDate,
	|	CheckOutDate,
	|	AccommodationType.*,
	|	Status.*,
	|	Room.*,
	|	RoomType.*,
	|	Resource.*,
	|	CustomerTurnovers.RoomRate.* AS RoomRate,
	|	CustomerTurnovers.Price AS Price,
	|	CustomerTurnovers.ExpectedPrice AS ExpectedPrice,
	|	ParentDoc.*,
	|	CustomerTurnovers.Remarks AS Remarks,
	|	Reservation.*,
	|	Service.*,
	|	AccountingDate,
	|	(CASE
	|			WHEN CustomerTurnovers.Sales <> CustomerTurnovers.ExpectedSales
	|					AND NOT CustomerTurnovers.Reservation IS NULL
	|					AND NOT CustomerTurnovers.Reservation = &qEmptyReservation
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS PlanAndFactAreDifferent,
	|	Sales,
	|	SalesWithoutVAT,
	|	RoomRevenue,
	|	RoomRevenueWithoutVAT,
	|	CommissionSum,
	|	CommissionSumWithoutVAT,
	|	DiscountSum,
	|	DiscountSumWithoutVAT,
	|	RoomsRented,
	|	BedsRented,
	|	AdditionalBedsRented,
	|	GuestDays,
	|	GuestsCheckedIn,
	|	RoomsCheckedIn,
	|	BedsCheckedIn,
	|	AdditionalBedsCheckedIn,
	|	Quantity,
	|	ExpectedSales,
	|	ExpectedSalesWithoutVAT,
	|	ExpectedRoomRevenue,
	|	ExpectedRoomRevenueWithoutVAT,
	|	ExpectedCommissionSum,
	|	ExpectedCommissionSumWithoutVAT,
	|	ExpectedDiscountSum,
	|	ExpectedDiscountSumWithoutVAT,
	|	ExpectedRoomsRented,
	|	ExpectedBedsRented,
	|	ExpectedAdditionalBedsRented,
	|	ExpectedGuestDays,
	|	ExpectedGuestsCheckedIn,
	|	ExpectedRoomsCheckedIn,
	|	ExpectedBedsCheckedIn,
	|	ExpectedAdditionalBedsCheckedIn,
	|	ExpectedQuantity}
	|FROM
	|	(SELECT
	|		CustomerSales.Company AS Company,
	|		CustomerSales.Hotel AS Hotel,
	|		CustomerSales.FolioCurrency AS FolioCurrency,
	|		CustomerSales.PaymentMethod AS PaymentMethod,
	|		CustomerSales.Agent AS Agent,
	|		CustomerSales.Customer AS Customer,
	|		CustomerSales.Contract AS Contract,
	|		CustomerSales.GuestGroup AS GuestGroup,
	|		CustomerSales.ParentDoc AS ParentDoc,
	|		CustomerSales.Remarks AS Remarks,
	|		CustomerSales.Service AS Service,
	|		CustomerSales.AccountingDate AS AccountingDate,
	|		CustomerSales.Client AS Client,
	|		CustomerSales.CheckInDate AS CheckInDate,
	|		CustomerSales.CheckOutDate AS CheckOutDate,
	|		CustomerSales.Status AS Status,
	|		CustomerSales.AccommodationType AS AccommodationType,
	|		CustomerSales.Room AS Room,
	|		CustomerSales.RoomType AS RoomType,
	|		CustomerSales.Resource AS Resource,
	|		CustomerSales.RoomRate AS RoomRate,
	|		CustomerSales.Reservation AS Reservation,
	|		CustomerSales.Price AS Price,
	|		CustomerSales.ExpectedPrice AS ExpectedPrice,
	|		SUM(CustomerSales.Sales) AS Sales,
	|		SUM(CustomerSales.SalesWithoutVAT) AS SalesWithoutVAT,
	|		SUM(CustomerSales.RoomRevenue) AS RoomRevenue,
	|		SUM(CustomerSales.RoomRevenueWithoutVAT) AS RoomRevenueWithoutVAT,
	|		SUM(CustomerSales.CommissionSum) AS CommissionSum,
	|		SUM(CustomerSales.CommissionSumWithoutVAT) AS CommissionSumWithoutVAT,
	|		SUM(CustomerSales.DiscountSum) AS DiscountSum,
	|		SUM(CustomerSales.DiscountSumWithoutVAT) AS DiscountSumWithoutVAT,
	|		SUM(CustomerSales.RoomsRented) AS RoomsRented,
	|		SUM(CustomerSales.BedsRented) AS BedsRented,
	|		SUM(CustomerSales.AdditionalBedsRented) AS AdditionalBedsRented,
	|		SUM(CustomerSales.GuestDays) AS GuestDays,
	|		SUM(CustomerSales.GuestsCheckedIn) AS GuestsCheckedIn,
	|		SUM(CustomerSales.RoomsCheckedIn) AS RoomsCheckedIn,
	|		SUM(CustomerSales.BedsCheckedIn) AS BedsCheckedIn,
	|		SUM(CustomerSales.AdditionalBedsCheckedIn) AS AdditionalBedsCheckedIn,
	|		SUM(CustomerSales.Quantity) AS Quantity,
	|		SUM(CustomerSales.ExpectedSales) AS ExpectedSales,
	|		SUM(CustomerSales.ExpectedSalesWithoutVAT) AS ExpectedSalesWithoutVAT,
	|		SUM(CustomerSales.ExpectedRoomRevenue) AS ExpectedRoomRevenue,
	|		SUM(CustomerSales.ExpectedRoomRevenueWithoutVAT) AS ExpectedRoomRevenueWithoutVAT,
	|		SUM(CustomerSales.ExpectedCommissionSum) AS ExpectedCommissionSum,
	|		SUM(CustomerSales.ExpectedCommissionSumWithoutVAT) AS ExpectedCommissionSumWithoutVAT,
	|		SUM(CustomerSales.ExpectedDiscountSum) AS ExpectedDiscountSum,
	|		SUM(CustomerSales.ExpectedDiscountSumWithoutVAT) AS ExpectedDiscountSumWithoutVAT,
	|		SUM(CustomerSales.ExpectedRoomsRented) AS ExpectedRoomsRented,
	|		SUM(CustomerSales.ExpectedBedsRented) AS ExpectedBedsRented,
	|		SUM(CustomerSales.ExpectedAdditionalBedsRented) AS ExpectedAdditionalBedsRented,
	|		SUM(CustomerSales.ExpectedGuestDays) AS ExpectedGuestDays,
	|		SUM(CustomerSales.ExpectedGuestsCheckedIn) AS ExpectedGuestsCheckedIn,
	|		SUM(CustomerSales.ExpectedRoomsCheckedIn) AS ExpectedRoomsCheckedIn,
	|		SUM(CustomerSales.ExpectedBedsCheckedIn) AS ExpectedBedsCheckedIn,
	|		SUM(CustomerSales.ExpectedAdditionalBedsCheckedIn) AS ExpectedAdditionalBedsCheckedIn,
	|		SUM(CustomerSales.ExpectedQuantity) AS ExpectedQuantity
	|	FROM
	|		(SELECT
	|			CASE
	|				WHEN ChargedAccountsReceivable.Company IS NULL
	|					THEN ExpectedAccountsReceivable.Company
	|				ELSE ChargedAccountsReceivable.Company
	|			END AS Company,
	|			CASE
	|				WHEN ChargedAccountsReceivable.Hotel IS NULL
	|					THEN ExpectedAccountsReceivable.Hotel
	|				ELSE ChargedAccountsReceivable.Hotel
	|			END AS Hotel,
	|			CASE
	|				WHEN ChargedAccountsReceivable.FolioCurrency IS NULL
	|					THEN ExpectedAccountsReceivable.FolioCurrency
	|				ELSE ChargedAccountsReceivable.FolioCurrency
	|			END AS FolioCurrency,
	|			CASE
	|				WHEN ChargedAccountsReceivable.Agent IS NULL
	|					THEN ExpectedAccountsReceivable.Agent
	|				ELSE ChargedAccountsReceivable.Agent
	|			END AS Agent,
	|			CASE
	|				WHEN ChargedAccountsReceivable.PaymentMethod IS NULL
	|					THEN ExpectedAccountsReceivable.PaymentMethod
	|				ELSE ChargedAccountsReceivable.PaymentMethod
	|			END AS PaymentMethod,
	|			CASE
	|				WHEN ChargedAccountsReceivable.Customer IS NULL
	|					THEN ExpectedAccountsReceivable.Customer
	|				ELSE ChargedAccountsReceivable.Customer
	|			END AS Customer,
	|			CASE
	|				WHEN ChargedAccountsReceivable.Contract IS NULL
	|					THEN ExpectedAccountsReceivable.Contract
	|				ELSE ChargedAccountsReceivable.Contract
	|			END AS Contract,
	|			CASE
	|				WHEN ChargedAccountsReceivable.GuestGroup IS NULL
	|					THEN ExpectedAccountsReceivable.GuestGroup
	|				ELSE ChargedAccountsReceivable.GuestGroup
	|			END AS GuestGroup,
	|			CASE
	|				WHEN ChargedAccountsReceivable.ParentDoc IS NULL
	|					THEN ExpectedAccountsReceivable.ParentDoc
	|				ELSE ChargedAccountsReceivable.ParentDoc
	|			END AS ParentDoc,
	|			CASE
	|				WHEN ChargedAccountsReceivable.ParentDoc IS NULL
	|					THEN ExpectedAccountsReceivable.Remarks
	|				ELSE ChargedAccountsReceivable.Remarks
	|			END AS Remarks,
	|			CASE
	|				WHEN NOT &qShowServices
	|					THEN &qEmptyService
	|				WHEN ChargedAccountsReceivable.Service IS NULL
	|					THEN ExpectedAccountsReceivable.Service
	|				ELSE ChargedAccountsReceivable.Service
	|			END AS Service,
	|			CASE
	|				WHEN NOT &qShowDates
	|					THEN &qEmptyDate
	|				WHEN ChargedAccountsReceivable.AccountingDate IS NULL
	|					THEN ExpectedAccountsReceivable.AccountingDate
	|				ELSE ChargedAccountsReceivable.AccountingDate
	|			END AS AccountingDate,
	|			CASE
	|				WHEN ChargedAccountsReceivable.Client IS NULL
	|					THEN ExpectedAccountsReceivable.Client
	|				ELSE ChargedAccountsReceivable.Client
	|			END AS Client,
	|			CASE
	|				WHEN ChargedAccountsReceivable.CheckInDate IS NULL
	|					THEN ExpectedAccountsReceivable.CheckInDate
	|				ELSE ChargedAccountsReceivable.CheckInDate
	|			END AS CheckInDate,
	|			CASE
	|				WHEN ChargedAccountsReceivable.CheckOutDate IS NULL
	|					THEN ExpectedAccountsReceivable.CheckOutDate
	|				ELSE ChargedAccountsReceivable.CheckOutDate
	|			END AS CheckOutDate,
	|			CASE
	|				WHEN ChargedAccountsReceivable.Status IS NULL
	|					THEN ExpectedAccountsReceivable.Status
	|				ELSE ChargedAccountsReceivable.Status
	|			END AS Status,
	|			CASE
	|				WHEN ChargedAccountsReceivable.AccommodationType IS NULL
	|					THEN ExpectedAccountsReceivable.AccommodationType
	|				ELSE ChargedAccountsReceivable.AccommodationType
	|			END AS AccommodationType,
	|			CASE
	|				WHEN ChargedAccountsReceivable.Room IS NULL
	|					THEN ExpectedAccountsReceivable.Room
	|				ELSE ChargedAccountsReceivable.Room
	|			END AS Room,
	|			CASE
	|				WHEN ChargedAccountsReceivable.RoomType IS NULL
	|					THEN ExpectedAccountsReceivable.RoomType
	|				ELSE ChargedAccountsReceivable.RoomType
	|			END AS RoomType,
	|			CASE
	|				WHEN ChargedAccountsReceivable.Resource IS NULL
	|					THEN ExpectedAccountsReceivable.Resource
	|				ELSE ChargedAccountsReceivable.Resource
	|			END AS Resource,
	|			CASE
	|				WHEN ChargedAccountsReceivable.RoomRate IS NULL
	|					THEN ExpectedAccountsReceivable.RoomRate
	|				ELSE ChargedAccountsReceivable.RoomRate
	|			END AS RoomRate,
	|			CASE
	|				WHEN ChargedAccountsReceivable.Reservation IS NULL
	|					THEN ExpectedAccountsReceivable.Reservation
	|				ELSE ChargedAccountsReceivable.Reservation
	|			END AS Reservation,
	|			CASE
	|				WHEN NOT &qShowPrice
	|					THEN 0
	|				WHEN ChargedAccountsReceivable.Price IS NULL
	|					THEN ISNULL(ExpectedAccountsReceivable.ExpectedPrice, 0)
	|				ELSE ChargedAccountsReceivable.Price
	|			END AS Price,
	|			CASE
	|				WHEN NOT &qShowExpectedPrice
	|					THEN 0
	|				ELSE ISNULL(ExpectedAccountsReceivable.ExpectedPrice, 0)
	|			END AS ExpectedPrice,
	|			ISNULL(ChargedAccountsReceivable.Quantity, 0) AS Quantity,
	|			ISNULL(ChargedAccountsReceivable.Sales, 0) AS Sales,
	|			ISNULL(ChargedAccountsReceivable.SalesWithoutVAT, 0) AS SalesWithoutVAT,
	|			ISNULL(ChargedAccountsReceivable.RoomRevenue, 0) AS RoomRevenue,
	|			ISNULL(ChargedAccountsReceivable.RoomRevenueWithoutVAT, 0) AS RoomRevenueWithoutVAT,
	|			ISNULL(ChargedAccountsReceivable.CommissionSum, 0) AS CommissionSum,
	|			ISNULL(ChargedAccountsReceivable.CommissionSumWithoutVAT, 0) AS CommissionSumWithoutVAT,
	|			ISNULL(ChargedAccountsReceivable.DiscountSum, 0) AS DiscountSum,
	|			ISNULL(ChargedAccountsReceivable.DiscountSumWithoutVAT, 0) AS DiscountSumWithoutVAT,
	|			ISNULL(ChargedAccountsReceivable.RoomsRented, 0) AS RoomsRented,
	|			ISNULL(ChargedAccountsReceivable.BedsRented, 0) AS BedsRented,
	|			ISNULL(ChargedAccountsReceivable.AdditionalBedsRented, 0) AS AdditionalBedsRented,
	|			ISNULL(ChargedAccountsReceivable.GuestDays, 0) AS GuestDays,
	|			ISNULL(ChargedAccountsReceivable.GuestsCheckedIn, 0) AS GuestsCheckedIn,
	|			ISNULL(ChargedAccountsReceivable.RoomsCheckedIn, 0) AS RoomsCheckedIn,
	|			ISNULL(ChargedAccountsReceivable.BedsCheckedIn, 0) AS BedsCheckedIn,
	|			ISNULL(ChargedAccountsReceivable.AdditionalBedsCheckedIn, 0) AS AdditionalBedsCheckedIn,
	|			ISNULL(ExpectedAccountsReceivable.ExpectedQuantity, 0) AS ExpectedQuantity,
	|			ISNULL(ExpectedAccountsReceivable.ExpectedSales, 0) AS ExpectedSales,
	|			ISNULL(ExpectedAccountsReceivable.ExpectedSalesWithoutVAT, 0) AS ExpectedSalesWithoutVAT,
	|			ISNULL(ExpectedAccountsReceivable.ExpectedRoomRevenue, 0) AS ExpectedRoomRevenue,
	|			ISNULL(ExpectedAccountsReceivable.ExpectedRoomRevenueWithoutVAT, 0) AS ExpectedRoomRevenueWithoutVAT,
	|			ISNULL(ExpectedAccountsReceivable.ExpectedCommissionSum, 0) AS ExpectedCommissionSum,
	|			ISNULL(ExpectedAccountsReceivable.ExpectedCommissionSumWithoutVAT, 0) AS ExpectedCommissionSumWithoutVAT,
	|			ISNULL(ExpectedAccountsReceivable.ExpectedDiscountSum, 0) AS ExpectedDiscountSum,
	|			ISNULL(ExpectedAccountsReceivable.ExpectedDiscountSumWithoutVAT, 0) AS ExpectedDiscountSumWithoutVAT,
	|			ISNULL(ExpectedAccountsReceivable.ExpectedRoomsRented, 0) AS ExpectedRoomsRented,
	|			ISNULL(ExpectedAccountsReceivable.ExpectedBedsRented, 0) AS ExpectedBedsRented,
	|			ISNULL(ExpectedAccountsReceivable.ExpectedAdditionalBedsRented, 0) AS ExpectedAdditionalBedsRented,
	|			ISNULL(ExpectedAccountsReceivable.ExpectedGuestDays, 0) AS ExpectedGuestDays,
	|			ISNULL(ExpectedAccountsReceivable.ExpectedGuestsCheckedIn, 0) AS ExpectedGuestsCheckedIn,
	|			ISNULL(ExpectedAccountsReceivable.ExpectedRoomsCheckedIn, 0) AS ExpectedRoomsCheckedIn,
	|			ISNULL(ExpectedAccountsReceivable.ExpectedBedsCheckedIn, 0) AS ExpectedBedsCheckedIn,
	|			ISNULL(ExpectedAccountsReceivable.ExpectedAdditionalBedsCheckedIn, 0) AS ExpectedAdditionalBedsCheckedIn
	|		FROM
	|			ChargedAccountsReceivable AS ChargedAccountsReceivable
	|				FULL JOIN (SELECT
	|					AccountsReceivableForecast.Company AS Company,
	|					AccountsReceivableForecast.Hotel AS Hotel,
	|					AccountsReceivableForecast.FolioCurrency AS FolioCurrency,
	|					AccountsReceivableForecast.Agent AS Agent,
	|					AccountsReceivableForecast.PaymentMethod AS PaymentMethod,
	|					AccountsReceivableForecast.Customer AS Customer,
	|					AccountsReceivableForecast.Contract AS Contract,
	|					AccountsReceivableForecast.GuestGroup AS GuestGroup,
	|					AccountsReceivableForecast.ParentDoc AS ParentDoc,
	|					AccountsReceivableForecast.Remarks AS Remarks,
	|					AccountsReceivableForecast.Service AS Service,
	|					AccountsReceivableForecast.AccountingDate AS AccountingDate,
	|					AccountsReceivableForecast.Client AS Client,
	|					AccountsReceivableForecast.CheckInDate AS CheckInDate,
	|					AccountsReceivableForecast.CheckOutDate AS CheckOutDate,
	|					AccountsReceivableForecast.Status AS Status,
	|					AccountsReceivableForecast.AccommodationType AS AccommodationType,
	|					AccountsReceivableForecast.Room AS Room,
	|					AccountsReceivableForecast.RoomType AS RoomType,
	|					AccountsReceivableForecast.Resource AS Resource,
	|					AccountsReceivableForecast.RoomRate AS RoomRate,
	|					AccountsReceivableForecast.Reservation AS Reservation,
	|					AccountsReceivableForecast.ExpectedPrice AS ExpectedPrice,
	|					AccountsReceivableForecast.IsSplit AS IsSplit,
	|					AccountsReceivableForecast.ExpectedQuantity AS ExpectedQuantity,
	|					AccountsReceivableForecast.ExpectedSales AS ExpectedSales,
	|					AccountsReceivableForecast.ExpectedSalesWithoutVAT AS ExpectedSalesWithoutVAT,
	|					AccountsReceivableForecast.ExpectedRoomRevenue AS ExpectedRoomRevenue,
	|					AccountsReceivableForecast.ExpectedRoomRevenueWithoutVAT AS ExpectedRoomRevenueWithoutVAT,
	|					AccountsReceivableForecast.ExpectedCommissionSum AS ExpectedCommissionSum,
	|					AccountsReceivableForecast.ExpectedCommissionSumWithoutVAT AS ExpectedCommissionSumWithoutVAT,
	|					AccountsReceivableForecast.ExpectedDiscountSum AS ExpectedDiscountSum,
	|					AccountsReceivableForecast.ExpectedDiscountSumWithoutVAT AS ExpectedDiscountSumWithoutVAT,
	|					AccountsReceivableForecast.ExpectedRoomsRented AS ExpectedRoomsRented,
	|					AccountsReceivableForecast.ExpectedBedsRented AS ExpectedBedsRented,
	|					AccountsReceivableForecast.ExpectedAdditionalBedsRented AS ExpectedAdditionalBedsRented,
	|					AccountsReceivableForecast.ExpectedGuestDays AS ExpectedGuestDays,
	|					AccountsReceivableForecast.ExpectedGuestsCheckedIn AS ExpectedGuestsCheckedIn,
	|					AccountsReceivableForecast.ExpectedRoomsCheckedIn AS ExpectedRoomsCheckedIn,
	|					AccountsReceivableForecast.ExpectedBedsCheckedIn AS ExpectedBedsCheckedIn,
	|					AccountsReceivableForecast.ExpectedAdditionalBedsCheckedIn AS ExpectedAdditionalBedsCheckedIn
	|				FROM
	|					ExpectedAccountsReceivable AS AccountsReceivableForecast) AS ExpectedAccountsReceivable
	|				ON ChargedAccountsReceivable.Reservation = ExpectedAccountsReceivable.Reservation
	|					AND ChargedAccountsReceivable.Client = ExpectedAccountsReceivable.Client
	|					AND ChargedAccountsReceivable.Service = ExpectedAccountsReceivable.Service
	|					AND ChargedAccountsReceivable.AccountingDate = ExpectedAccountsReceivable.AccountingDate
	|					AND ChargedAccountsReceivable.IsSplit = ExpectedAccountsReceivable.IsSplit) AS CustomerSales
	|	
	|	GROUP BY
	|		CustomerSales.Company,
	|		CustomerSales.Hotel,
	|		CustomerSales.FolioCurrency,
	|		CustomerSales.PaymentMethod,
	|		CustomerSales.Agent,
	|		CustomerSales.Customer,
	|		CustomerSales.Contract,
	|		CustomerSales.GuestGroup,
	|		CustomerSales.ParentDoc,
	|		CustomerSales.Remarks,
	|		CustomerSales.Reservation,
	|		CustomerSales.Service,
	|		CustomerSales.AccountingDate,
	|		CustomerSales.Client,
	|		CustomerSales.CheckInDate,
	|		CustomerSales.CheckOutDate,
	|		CustomerSales.Status,
	|		CustomerSales.AccommodationType,
	|		CustomerSales.Room,
	|		CustomerSales.RoomType,
	|		CustomerSales.Resource,
	|		CustomerSales.RoomRate,
	|		CustomerSales.ExpectedPrice,
	|		CustomerSales.Price) AS CustomerTurnovers
	|{WHERE
	|	CustomerTurnovers.Company.*,
	|	CustomerTurnovers.Hotel.*,
	|	CustomerTurnovers.FolioCurrency.*,
	|	CustomerTurnovers.PaymentMethod.*,
	|	CustomerTurnovers.Agent.*,
	|	CustomerTurnovers.Customer.*,
	|	CustomerTurnovers.Contract.*,
	|	CustomerTurnovers.GuestGroup.*,
	|	CustomerTurnovers.ParentDoc.*,
	|	CustomerTurnovers.Remarks AS Remarks,
	|	CustomerTurnovers.Reservation.*,
	|	CustomerTurnovers.Client.* AS Client,
	|	CustomerTurnovers.CheckInDate AS CheckInDate,
	|	CustomerTurnovers.CheckOutDate AS CheckOutDate,
	|	CustomerTurnovers.AccommodationType.* AS AccommodationType,
	|	CustomerTurnovers.Status.* AS Status,
	|	CustomerTurnovers.Room.* AS Room,
	|	CustomerTurnovers.RoomType.* AS RoomType,
	|	CustomerTurnovers.Resource.* AS Resource,
	|	CustomerTurnovers.RoomRate.* AS RoomRate,
	|	CustomerTurnovers.Price AS Price,
	|	CustomerTurnovers.ExpectedPrice AS ExpectedPrice,
	|	CustomerTurnovers.Service.*,
	|	CustomerTurnovers.AccountingDate AS AccountingDate,
	|	(CASE
	|			WHEN CustomerTurnovers.Sales <> CustomerTurnovers.ExpectedSales
	|					AND NOT CustomerTurnovers.Reservation IS NULL
	|					AND NOT CustomerTurnovers.Reservation = &qEmptyReservation
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS PlanAndFactAreDifferent,
	|	CustomerTurnovers.Sales,
	|	CustomerTurnovers.SalesWithoutVAT,
	|	CustomerTurnovers.RoomRevenue,
	|	CustomerTurnovers.RoomRevenueWithoutVAT,
	|	CustomerTurnovers.CommissionSum,
	|	CustomerTurnovers.CommissionSumWithoutVAT,
	|	CustomerTurnovers.DiscountSum,
	|	CustomerTurnovers.DiscountSumWithoutVAT,
	|	CustomerTurnovers.RoomsRented,
	|	CustomerTurnovers.BedsRented,
	|	CustomerTurnovers.AdditionalBedsRented,
	|	CustomerTurnovers.GuestDays,
	|	CustomerTurnovers.GuestsCheckedIn,
	|	CustomerTurnovers.RoomsCheckedIn,
	|	CustomerTurnovers.BedsCheckedIn,
	|	CustomerTurnovers.AdditionalBedsCheckedIn,
	|	CustomerTurnovers.Quantity,
	|	CustomerTurnovers.ExpectedSales,
	|	CustomerTurnovers.ExpectedSalesWithoutVAT,
	|	CustomerTurnovers.ExpectedRoomRevenue,
	|	CustomerTurnovers.ExpectedRoomRevenueWithoutVAT,
	|	CustomerTurnovers.ExpectedCommissionSum,
	|	CustomerTurnovers.ExpectedCommissionSumWithoutVAT,
	|	CustomerTurnovers.ExpectedDiscountSum,
	|	CustomerTurnovers.ExpectedDiscountSumWithoutVAT,
	|	CustomerTurnovers.ExpectedRoomsRented,
	|	CustomerTurnovers.ExpectedBedsRented,
	|	CustomerTurnovers.ExpectedAdditionalBedsRented,
	|	CustomerTurnovers.ExpectedGuestDays,
	|	CustomerTurnovers.ExpectedGuestsCheckedIn,
	|	CustomerTurnovers.ExpectedRoomsCheckedIn,
	|	CustomerTurnovers.ExpectedBedsCheckedIn,
	|	CustomerTurnovers.ExpectedAdditionalBedsCheckedIn,
	|	CustomerTurnovers.ExpectedQuantity}
	|
	|ORDER BY
	|	Company,
	|	Hotel,
	|	FolioCurrency,
	|	Agent,
	|	Customer,
	|	Contract,
	|	GuestGroup,
	|	CheckInDate,
	|	Client,
	|	Service,
	|	AccountingDate
	|{ORDER BY
	|	Company.*,
	|	Hotel.*,
	|	FolioCurrency.*,
	|	PaymentMethod.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	Agent.*,
	|	Client.*,
	|	CheckInDate,
	|	CheckOutDate,
	|	AccommodationType.*,
	|	Status.*,
	|	Room.*,
	|	RoomType.*,
	|	Resource.*,
	|	CustomerTurnovers.RoomRate.* AS RoomRate,
	|	CustomerTurnovers.Price AS Price,
	|	CustomerTurnovers.ExpectedPrice AS ExpectedPrice,
	|	ParentDoc.*,
	|	Reservation.*,
	|	Service.*,
	|	AccountingDate,
	|	Sales,
	|	SalesWithoutVAT,
	|	RoomRevenue,
	|	RoomRevenueWithoutVAT,
	|	CommissionSum,
	|	CommissionSumWithoutVAT,
	|	DiscountSum,
	|	DiscountSumWithoutVAT,
	|	RoomsRented,
	|	BedsRented,
	|	AdditionalBedsRented,
	|	GuestDays,
	|	GuestsCheckedIn,
	|	RoomsCheckedIn,
	|	BedsCheckedIn,
	|	AdditionalBedsCheckedIn,
	|	Quantity,
	|	ExpectedSales,
	|	ExpectedSalesWithoutVAT,
	|	ExpectedRoomRevenue,
	|	ExpectedRoomRevenueWithoutVAT,
	|	ExpectedCommissionSum,
	|	ExpectedCommissionSumWithoutVAT,
	|	ExpectedDiscountSum,
	|	ExpectedDiscountSumWithoutVAT,
	|	ExpectedRoomsRented,
	|	ExpectedBedsRented,
	|	ExpectedAdditionalBedsRented,
	|	ExpectedGuestDays,
	|	ExpectedGuestsCheckedIn,
	|	ExpectedRoomsCheckedIn,
	|	ExpectedBedsCheckedIn,
	|	ExpectedAdditionalBedsCheckedIn,
	|	ExpectedQuantity}
	|TOTALS
	|	SUM(Sales),
	|	SUM(SalesWithoutVAT),
	|	SUM(RoomRevenue),
	|	SUM(RoomRevenueWithoutVAT),
	|	SUM(CommissionSum),
	|	SUM(CommissionSumWithoutVAT),
	|	SUM(DiscountSum),
	|	SUM(DiscountSumWithoutVAT),
	|	SUM(RoomsRented),
	|	SUM(BedsRented),
	|	SUM(AdditionalBedsRented),
	|	SUM(GuestDays),
	|	SUM(GuestsCheckedIn),
	|	SUM(RoomsCheckedIn),
	|	SUM(BedsCheckedIn),
	|	SUM(AdditionalBedsCheckedIn),
	|	SUM(Quantity),
	|	SUM(ExpectedSales),
	|	SUM(ExpectedSalesWithoutVAT),
	|	SUM(ExpectedRoomRevenue),
	|	SUM(ExpectedRoomRevenueWithoutVAT),
	|	SUM(ExpectedCommissionSum),
	|	SUM(ExpectedCommissionSumWithoutVAT),
	|	SUM(ExpectedDiscountSum),
	|	SUM(ExpectedDiscountSumWithoutVAT),
	|	SUM(ExpectedRoomsRented),
	|	SUM(ExpectedBedsRented),
	|	SUM(ExpectedAdditionalBedsRented),
	|	SUM(ExpectedGuestDays),
	|	SUM(ExpectedGuestsCheckedIn),
	|	SUM(ExpectedRoomsCheckedIn),
	|	SUM(ExpectedBedsCheckedIn),
	|	SUM(ExpectedAdditionalBedsCheckedIn),
	|	SUM(ExpectedQuantity)
	|BY
	|	OVERALL,
	|	Hotel,
	|	FolioCurrency,
	|	Agent,
	|	Customer,
	|	Contract,
	|	GuestGroup,
	|	ParentDoc
	|{TOTALS BY
	|	Company.*,
	|	Hotel.*,
	|	FolioCurrency.*,
	|	PaymentMethod.*,
	|	Agent.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	Client.*,
	|	Room.*,
	|	AccommodationType.*,
	|	Status.*,
	|	RoomType.*,
	|	Resource.*,
	|	CustomerTurnovers.RoomRate.* AS RoomRate,
	|	CustomerTurnovers.Price AS Price,
	|	CustomerTurnovers.ExpectedPrice AS ExpectedPrice,
	|	Service.*,
	|	AccountingDate,
	|	Reservation,
	|	ParentDoc.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Check customer guests';RU='Сверка начислений по гостям от контрагентов';de='Abgleich der Berechnungen nach Gästen von den Vertragspartnern'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
