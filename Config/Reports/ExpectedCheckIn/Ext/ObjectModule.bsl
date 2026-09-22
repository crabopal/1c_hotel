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
	If Not ValueIsFilled(RoomType) And ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.RoomType) Then
		RoomType = SessionParameters.CurrentUser.RoomType;
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
	If ValueIsFilled(RoomType) Then
		If Not RoomType.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Room type ';ru='Тип номера ';de='Zimmertyp '") + 
			                     TrimAll(RoomType.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Room types folder ';ru='Группа типов номеров ';de='Gruppe Zimmertypen '") + 
			                     TrimAll(RoomType.Description) + 
			                     ";" + Chars.LF;
		EndIf;
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
	If ValueIsFilled(RoomRate) Then
		If Not RoomRate.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("de='Tarif ';en='Room rate ';ru='Тариф '") + 
			                     TrimAll(RoomRate.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("de='Tarifgruppe ';en='Room rates folder ';ru='Группа тарифов '") + 
			                     TrimAll(RoomRate.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(GuestGroup) Then
		vParamPresentation = vParamPresentation + NStr("en='Guest group ';ru='Группа ';de='Gruppe '") + 
							 TrimAll(GuestGroup.Code) + 
							 ";" + Chars.LF;
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
	ReportBuilder.Parameters.Insert("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qBegOfTime", '00010101');
	ReportBuilder.Parameters.Insert("qEndOfTime", '39991231235959');
	ReportBuilder.Parameters.Insert("qBegOfCurrentDate", BegOfDay(CurrentSessionDate()));
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qCustomerIsEmpty", Not ValueIsFilled(Customer));
	ReportBuilder.Parameters.Insert("qContract", Contract);
	ReportBuilder.Parameters.Insert("qContractIsEmpty", Not ValueIsFilled(Contract));
	ReportBuilder.Parameters.Insert("qRoomRate", RoomRate);
	ReportBuilder.Parameters.Insert("qRoomRateIsEmpty", Not ValueIsFilled(RoomRate));
	ReportBuilder.Parameters.Insert("qGuestGroup", GuestGroup);
	ReportBuilder.Parameters.Insert("qGuestGroupIsEmpty", Not ValueIsFilled(GuestGroup));
	ReportBuilder.Parameters.Insert("qReservation", Reservation);
	ReportBuilder.Parameters.Insert("qReservationIsEmpty", Not ValueIsFilled(Reservation));
	ReportBuilder.Parameters.Insert("qShowInvoicesAndDeposits", ShowInvoicesAndDeposits);
	ReportBuilder.Parameters.Insert("qEmptyString", "");
	ReportBuilder.Parameters.Insert("qSent", Enums.AttachmentStatuses.Sent);
	ReportBuilder.Parameters.Insert("qReady", Enums.AttachmentStatuses.Ready);
	ReportBuilder.Parameters.Insert("qEmptyEmployee", Catalogs.Employees.EmptyRef());
	ReportBuilder.Parameters.Insert("qEmptyAttachmentType", Enums.AttachmentTypes.EmptyRef());
	ReportBuilder.Parameters.Insert("qVATRate", ?(ValueIsFilled(Hotel), ?(ValueIsFilled(Hotel.Company), ?(ValueIsFilled(Hotel.Company.VATRate), Hotel.Company.VATRate.TaxRate, 0), 0), 0));
	ReportBuilder.Parameters.Insert("qShowGroupBalances", ShowGroupBalances);
	ReportBuilder.Parameters.Insert("qShowMainRoomGuestsOnly", ShowMainRoomGuestsOnly);
	ReportBuilder.Parameters.Insert("qShowCheckedInGuests", ShowCheckedInGuests);
	ReportBuilder.Parameters.Insert("qEmptyTemplate", Catalogs.AccommodationTemplates.EmptyRef());
	vUseGuestGroupAttachments = False;
	For Each vReportField In ReportBuilder.SelectedFields Do
		If Find(lower(vReportField.Name), "attachment") > 0 Then
			vUseGuestGroupAttachments = True;
			Break;
		EndIf;
	EndDo;
	ReportBuilder.Parameters.Insert("qUseGuestGroupAttachments", vUseGuestGroupAttachments);
	ReportBuilder.Parameters.Insert("qForecastPeriodFrom", tcOnServer.GetForecastStartDate(Hotel));
	ReportBuilder.Parameters.Insert("qForecastPeriodTo", '39991231235959');
	ReportBuilder.Parameters.Insert("qCustomAttribute1", CustomAttribute1);
	ReportBuilder.Parameters.Insert("qCustomAttribute2", CustomAttribute2);
	ReportBuilder.Parameters.Insert("qCustomAttribute3", CustomAttribute3);

	// Execute report builder query
	ReportBuilder.Execute();
	
	// Apply appearance settings to the report template
	vTemplateAttributes = cmApplyReportTemplateAppearance(ThisObject);
	
	// Output report to the spreadsheet
	Try
		ReportBuilder.Put(pSpreadsheet);
	Except
		tcCommonFunctionOnClientServer.TextMessage(cmGetRootErrorDescription(ErrorInfo()), MessageStatus.Attention);
	EndTry;
	//ReportBuilder.Template.Show(); // For debug purpose

	// Apply appearance settings to the report spreadsheet
	cmApplyReportAppearance(ThisObject, pSpreadsheet, vTemplateAttributes);
EndProcedure // pmGenerate

// -----------------------------------------------------------------------------
Procedure pmInitializeReportBuilder() Export
	ReportBuilder = New ReportBuilder();
	
	// Initialize default query text
	QueryText = 
	"SELECT DISTINCT
	|	ReservationChangesPlan1.Ref AS Ref,
	|	DATEADD(ReservationChangesPlan1.AccountingDate, DAY, 1) AS BookedOutEndDate,
	|	BookedOutReservations.BookedOutDate AS BookedOutDate
	|INTO BookedOutEndReservations
	|FROM
	|	Document.Reservation.RoomRates AS ReservationChangesPlan1
	|		LEFT JOIN (SELECT DISTINCT
	|			ReservationChangesPlan2.Ref AS Ref,
	|			ReservationChangesPlan2.AccountingDate AS BookedOutDate
	|		FROM
	|			Document.Reservation.RoomRates AS ReservationChangesPlan2
	|		WHERE
	|			ReservationChangesPlan2.IsBookedOut
	|			AND ReservationChangesPlan2.AccountingDate = BEGINOFPERIOD(&qPeriodFrom, DAY)
	|			AND ReservationChangesPlan2.Ref.Hotel = &qHotel
	|			AND ReservationChangesPlan2.Ref.Posted
	|			AND ReservationChangesPlan2.Ref.ReservationStatus.IsActive) AS BookedOutReservations
	|		ON ReservationChangesPlan1.Ref = BookedOutReservations.Ref
	|WHERE
	|	ReservationChangesPlan1.IsBookedOut
	|	AND ReservationChangesPlan1.Ref.Hotel = &qHotel
	|	AND BookedOutReservations.BookedOutDate IS NULL
	|	AND ReservationChangesPlan1.AccountingDate = DATEADD(BEGINOFPERIOD(&qPeriodFrom, DAY), DAY, -1)
	|	AND ReservationChangesPlan1.Ref.Posted
	|	AND ReservationChangesPlan1.Ref.ReservationStatus.IsActive
	|	AND &qPeriodFrom <> DATETIME(1, 1, 1)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PlannedCheckIn.GuestGroup AS GuestGroup,
	|	MIN(PlannedCheckIn.CheckInDate) AS CheckInDate,
	|	MAX(PlannedCheckIn.CheckOutDate) AS CheckOutDate
	|INTO ExpectedGuestGroups
	|FROM
	|	AccumulationRegister.RoomInventory AS PlannedCheckIn
	|WHERE
	|	(&qShowGroupBalances
	|			OR &qShowInvoicesAndDeposits)
	|	AND PlannedCheckIn.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND PlannedCheckIn.RoomType IN HIERARCHY(&qRoomType)
	|	AND (PlannedCheckIn.IsReservation
	|			OR &qShowCheckedInGuests
	|				AND PlannedCheckIn.IsAccommodation
	|				AND PlannedCheckIn.IsCheckIn)
	|	AND (&qHotelIsEmpty
	|			OR PlannedCheckIn.Hotel IN HIERARCHY (&qHotel))
	|	AND (PlannedCheckIn.CheckInDate >= &qPeriodFrom
	|				AND PlannedCheckIn.CheckInDate <= &qPeriodTo
	|			OR PlannedCheckIn.Recorder IN
	|				(SELECT
	|					BookedOutEndReservations.Ref
	|				FROM
	|					BookedOutEndReservations AS BookedOutEndReservations))
	|	AND (&qCustomerIsEmpty
	|			OR PlannedCheckIn.Customer IN HIERARCHY (&qCustomer))
	|	AND (&qContractIsEmpty
	|			OR PlannedCheckIn.Contract = &qContract)
	|	AND (&qRoomRateIsEmpty
	|			OR PlannedCheckIn.RoomRate IN HIERARCHY (&qRoomRate))
	|	AND (&qGuestGroupIsEmpty
	|			OR PlannedCheckIn.GuestGroup = &qGuestGroup)
	|	AND (&qReservationIsEmpty
	|			OR PlannedCheckIn.Recorder = &qReservation)
	|
	|GROUP BY
	|	PlannedCheckIn.GuestGroup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PlannedCheckIn.Guest AS Guest
	|INTO ExpectedGuests
	|FROM
	|	AccumulationRegister.RoomInventory AS PlannedCheckIn
	|WHERE
	|	PlannedCheckIn.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND PlannedCheckIn.RoomType IN HIERARCHY(&qRoomType)
	|	AND (PlannedCheckIn.IsReservation
	|			OR &qShowCheckedInGuests
	|				AND PlannedCheckIn.IsAccommodation
	|				AND PlannedCheckIn.IsCheckIn)
	|	AND (&qHotelIsEmpty
	|			OR PlannedCheckIn.Hotel IN HIERARCHY (&qHotel))
	|	AND (PlannedCheckIn.CheckInDate >= &qPeriodFrom
	|				AND PlannedCheckIn.CheckInDate <= &qPeriodTo
	|			OR PlannedCheckIn.Recorder IN
	|				(SELECT
	|					BookedOutEndReservations.Ref
	|				FROM
	|					BookedOutEndReservations AS BookedOutEndReservations))
	|	AND (&qCustomerIsEmpty
	|			OR PlannedCheckIn.Customer IN HIERARCHY (&qCustomer))
	|	AND (&qContractIsEmpty
	|			OR PlannedCheckIn.Contract = &qContract)
	|	AND (&qRoomRateIsEmpty
	|			OR PlannedCheckIn.RoomRate IN HIERARCHY (&qRoomRate))
	|	AND (&qGuestGroupIsEmpty
	|			OR PlannedCheckIn.GuestGroup = &qGuestGroup)
	|	AND (&qReservationIsEmpty
	|			OR PlannedCheckIn.Recorder = &qReservation)
	|
	|GROUP BY
	|	PlannedCheckIn.Guest
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GuestStatistics.Client AS Guest,
	|	SUM(GuestStatistics.GuestsCheckedIn) AS NumberOfClientCheckIns,
	|	SUM(GuestStatistics.RoomsRented) AS NumberOfClientRoomNights,
	|	SUM(GuestStatistics.GuestDays) AS NumberOfClientGuestDays,
	|	SUM(GuestStatistics.RoomRevenue) AS ClientRoomRevenue,
	|	SUM(GuestStatistics.Sales) AS ClientSales
	|INTO GuestStatistics
	|FROM
	|	AccumulationRegister.Sales AS GuestStatistics
	|		INNER JOIN ExpectedGuests AS ExpectedGuests
	|		ON GuestStatistics.Client = ExpectedGuests.Guest
	|
	|GROUP BY
	|	GuestStatistics.Client
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomerAccountsMovements.ParentDoc AS Reservation,
	|	CustomerAccountsMovements.AccountingCurrency AS AccountingCurrency,
	|	SUM(CustomerAccountsMovements.Sum) AS AmountPayed
	|INTO ReservationPayments
	|FROM
	|	AccumulationRegister.CustomerAccounts AS CustomerAccountsMovements
	|		INNER JOIN ExpectedGuestGroups AS ExpectedGuestGroups
	|		ON CustomerAccountsMovements.GuestGroup = ExpectedGuestGroups.GuestGroup
	|WHERE
	|	CustomerAccountsMovements.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND (CustomerAccountsMovements.Hotel IN HIERARCHY (&qHotel)
	|			OR &qHotelIsEmpty)
	|	AND CustomerAccountsMovements.ParentDoc.CheckInDate >= &qPeriodFrom
	|	AND CustomerAccountsMovements.ParentDoc.CheckInDate <= &qPeriodTo
	|	AND (&qCustomerIsEmpty
	|			OR CustomerAccountsMovements.ParentDoc.Customer IN HIERARCHY (&qCustomer))
	|	AND (&qContractIsEmpty
	|			OR CustomerAccountsMovements.ParentDoc.Contract = &qContract)
	|	AND (&qRoomRateIsEmpty
	|			OR CustomerAccountsMovements.ParentDoc.RoomRate IN HIERARCHY (&qRoomRate))
	|	AND (&qGuestGroupIsEmpty
	|			OR CustomerAccountsMovements.GuestGroup = &qGuestGroup)
	|	AND (&qReservationIsEmpty
	|			OR CustomerAccountsMovements.ParentDoc = &qReservation)
	|
	|GROUP BY
	|	CustomerAccountsMovements.ParentDoc,
	|	CustomerAccountsMovements.AccountingCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccountsBalance.Folio AS Folio,
	|	AccountsBalance.Folio.GuestGroup AS FolioGuestGroup,
	|	AccountsBalance.FolioCurrency AS FolioCurrency,
	|	AccountsBalance.Folio.ParentDoc AS FolioParentDoc,
	|	SUM(AccountsBalance.SumBalance + AccountsBalance.LimitBalance) AS FolioBalance
	|INTO FolioBalances
	|FROM
	|	AccumulationRegister.Accounts.Balance(
	|			&qEndOfTime,
	|			&qShowInvoicesAndDeposits
	|				AND (&qHotelIsEmpty
	|					OR Folio.Hotel IN HIERARCHY (&qHotel))
	|				AND (&qCustomerIsEmpty
	|					OR Folio.Customer IN HIERARCHY (&qCustomer))
	|				AND (&qContractIsEmpty
	|					OR Folio.Contract = &qContract)
	|				AND (&qGuestGroupIsEmpty
	|					OR Folio.GuestGroup = &qGuestGroup)
	|				AND (&qReservationIsEmpty
	|					OR Folio.ParentDoc = &qReservation)) AS AccountsBalance
	|		INNER JOIN ExpectedGuestGroups AS ExpectedGuestGroups
	|		ON AccountsBalance.Folio.GuestGroup = ExpectedGuestGroups.GuestGroup
	|
	|GROUP BY
	|	AccountsBalance.Folio,
	|	AccountsBalance.Folio.GuestGroup,
	|	AccountsBalance.FolioCurrency,
	|	AccountsBalance.Folio.ParentDoc
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GuestGroupSales.GuestGroup AS GuestGroup,
	|	GuestGroupSales.ReportingCurrency AS ReportingCurrency,
	|	SUM(GuestGroupSales.SalesTurnover) AS SalesTurnover,
	|	SUM(GuestGroupSales.SalesWithoutVATTurnover) AS SalesWithoutVATTurnover
	|INTO GuestGroupSales
	|FROM
	|	(SELECT
	|		SalesTurnovers.GuestGroup AS GuestGroup,
	|		SalesTurnovers.ReportingCurrency AS ReportingCurrency,
	|		SalesTurnovers.SalesTurnover AS SalesTurnover,
	|		SalesTurnovers.SalesWithoutVATTurnover AS SalesWithoutVATTurnover
	|	FROM
	|		AccumulationRegister.Sales.Turnovers(
	|				,
	|				,
	|				Period,
	|				&qShowGroupBalances
	|					AND GuestGroup IN
	|						(SELECT
	|							ExpectedGuestGroups.GuestGroup
	|						FROM
	|							ExpectedGuestGroups AS ExpectedGuestGroups)) AS SalesTurnovers
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SalesForecastTurnovers.GuestGroup,
	|		SalesForecastTurnovers.ReportingCurrency,
	|		SalesForecastTurnovers.SalesTurnover,
	|		SalesForecastTurnovers.SalesWithoutVATTurnover
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(
	|				&qForecastPeriodFrom,
	|				&qForecastPeriodTo,
	|				Period,
	|				&qShowGroupBalances
	|					AND GuestGroup IN
	|						(SELECT
	|							ExpectedGuestGroups.GuestGroup
	|						FROM
	|							ExpectedGuestGroups AS ExpectedGuestGroups)) AS SalesForecastTurnovers) AS GuestGroupSales
	|
	|GROUP BY
	|	GuestGroupSales.GuestGroup,
	|	GuestGroupSales.ReportingCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GuestGroupPayments.GuestGroup AS GuestGroup,
	|	GuestGroupPayments.AccountingCurrency AS AccountingCurrency,
	|	SUM(ISNULL(GuestGroupPayments.SumExpense, 0)) AS PaymentsTurnover,
	|	SUM(ISNULL(GuestGroupPayments.SumExpense - GuestGroupPayments.SumExpense * &qVATRate / (100 + &qVATRate), 0)) AS PaymentsWithoutVATTurnover
	|INTO GuestGroupPayments
	|FROM
	|	AccumulationRegister.CustomerAccounts.BalanceAndTurnovers(
	|			,
	|			,
	|			Period,
	|			RegisterRecords,
	|			&qShowGroupBalances
	|				AND GuestGroup IN
	|					(SELECT
	|						ExpectedGuestGroups.GuestGroup
	|					FROM
	|						ExpectedGuestGroups AS ExpectedGuestGroups)) AS GuestGroupPayments
	|
	|GROUP BY
	|	GuestGroupPayments.GuestGroup,
	|	GuestGroupPayments.AccountingCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GuestGroupBalances.GuestGroup AS GuestGroup,
	|	GuestGroupBalances.Currency AS Currency,
	|	SUM(GuestGroupBalances.SalesTurnover) AS Sales,
	|	SUM(GuestGroupBalances.SalesWithoutVATTurnover) AS SalesWithoutVAT,
	|	SUM(GuestGroupBalances.PaymentsTurnover) AS Payments,
	|	SUM(GuestGroupBalances.PaymentsWithoutVATTurnover) AS PaymentsWithoutVAT,
	|	SUM(GuestGroupBalances.GroupBalance) AS GroupBalance,
	|	SUM(GuestGroupBalances.GroupBalanceWithoutVAT) AS GroupBalanceWithoutVAT
	|INTO GuestGroupBalances
	|FROM
	|	(SELECT
	|		GuestGroupSales.GuestGroup AS GuestGroup,
	|		GuestGroupSales.ReportingCurrency AS Currency,
	|		GuestGroupSales.SalesTurnover AS SalesTurnover,
	|		GuestGroupSales.SalesWithoutVATTurnover AS SalesWithoutVATTurnover,
	|		0 AS PaymentsTurnover,
	|		0 AS PaymentsWithoutVATTurnover,
	|		GuestGroupSales.SalesTurnover AS GroupBalance,
	|		GuestGroupSales.SalesWithoutVATTurnover AS GroupBalanceWithoutVAT
	|	FROM
	|		GuestGroupSales AS GuestGroupSales
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GuestGroupPayments.GuestGroup,
	|		GuestGroupPayments.AccountingCurrency,
	|		0,
	|		0,
	|		GuestGroupPayments.PaymentsTurnover,
	|		GuestGroupPayments.PaymentsWithoutVATTurnover,
	|		-GuestGroupPayments.PaymentsTurnover,
	|		-GuestGroupPayments.PaymentsWithoutVATTurnover
	|	FROM
	|		GuestGroupPayments AS GuestGroupPayments) AS GuestGroupBalances
	|
	|GROUP BY
	|	GuestGroupBalances.GuestGroup,
	|	GuestGroupBalances.Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventory.Hotel AS Hotel,
	|	RoomInventory.GuestGroup AS GuestGroup,
	|	RoomInventory.Customer AS Customer,
	|	RoomInventory.ReservationStatus AS ReservationStatus,
	|	RoomInventory.Guest AS Guest,
	|	RoomInventory.CheckInDate AS CheckInDate,
	|	RoomInventory.CheckOutDate AS CheckOutDate,
	|	RoomInventory.RoomType AS RoomType,
	|	CASE
	|		WHEN RoomInventory.Recorder.RoomTypeUpgrade = VALUE(Catalog.RoomTypes.EmptyRef)
	|			THEN RoomInventory.RoomType
	|		ELSE RoomInventory.Recorder.RoomTypeUpgrade
	|	END AS PriceByRoomType,
	|	RoomInventory.AccommodationType AS AccommodationType,
	|	RoomInventory.RoomRate AS RoomRate,
	|	RoomInventory.PlannedPaymentMethod AS PlannedPaymentMethod,
	|	RoomInventory.Remarks AS Remarks,
	|	RoomInventory.Recorder AS Recorder,
	|	CASE
	|		WHEN &qShowMainRoomGuestsOnly
	|			THEN ISNULL(RoomInventory.Recorder.NumberOfAdults, 0) + ISNULL(RoomInventory.Recorder.NumberOfTeenagers, 0) + ISNULL(RoomInventory.Recorder.NumberOfChildren, 0) + ISNULL(RoomInventory.Recorder.NumberOfInfants, 0)
	|		ELSE RoomInventory.GuestsReserved
	|	END AS GuestsReserved,
	|	ISNULL(RoomInventory.Recorder.NumberOfAdults, 0) AS NumberOfAdults,
	|	ISNULL(RoomInventory.Recorder.NumberOfTeenagers, 0) AS NumberOfTeenagers,
	|	ISNULL(RoomInventory.Recorder.NumberOfChildren, 0) AS NumberOfChildren,
	|	ISNULL(RoomInventory.Recorder.NumberOfInfants, 0) AS NumberOfInfants,
	|	RoomInventory.RoomsReserved AS RoomsReserved,
	|	RoomInventory.BedsReserved AS BedsReserved,
	|	RoomInventory.AdditionalBedsReserved AS AdditionalBedsReserved,
	|	RoomInventory.PricePresentation AS PricePresentation,
	|	RoomInventory.GuestGroupSales AS GuestGroupSales,
	|	RoomInventory.GuestGroupSalesWithoutVAT AS GuestGroupSalesWithoutVAT,
	|	RoomInventory.GuestGroupPayments AS GuestGroupPayments,
	|	RoomInventory.GuestGroupPaymentsWithoutVAT AS GuestGroupPaymentsWithoutVAT,
	|	RoomInventory.GuestGroupBalances AS GuestGroupBalances,
	|	RoomInventory.GuestGroupBalancesWithoutVAT AS GuestGroupBalancesWithoutVAT,
	|	ISNULL(GuestStatistics.NumberOfClientCheckIns, 0) AS NumberOfClientCheckins,
	|	ISNULL(GuestStatistics.NumberOfClientRoomNights, 0) AS NumberOfClientRoomNights,
	|	ISNULL(GuestStatistics.NumberOfClientGuestDays, 0) AS NumberOfClientGuestDays,
	|	ISNULL(GuestStatistics.ClientRoomRevenue, 0) AS ClientRoomRevenue,
	|	ISNULL(GuestStatistics.ClientSales, 0) AS ClientSales,
	|	ISNULL(ReservationPayments.AmountPayed, 0) AS SumPayed,
	|	CASE
	|		WHEN RoomInventory.Recorder.NumberOfBeds <> 0
	|			THEN RoomInventory.Recorder.BedsSetup.NumberOfExtraBeds
	|		ELSE 0
	|	END AS ExtraBedsNeeded,
	|	CASE
	|		WHEN RoomInventory.Recorder.NumberOfBeds <> 0
	|			THEN RoomInventory.Recorder.BedsSetup.NumberOfBabycots
	|		ELSE 0
	|	END AS BabycotsNeeded
	|{SELECT
	|	Hotel.*,
	|	GuestGroup.*,
	|	RoomInventory.GuestGroup.Remarks AS GuestGroupRemarks,
	|	RoomInventory.CustomerType.*,
	|	Customer.*,
	|	RoomInventory.Contract.*,
	|	RoomInventory.ContactPerson,
	|	RoomInventory.Agent.*,
	|	ReservationStatus.*,
	|	RoomInventory.ClientType.*,
	|	(CASE
	|			WHEN NOT RoomInventory.Customer.ClientTypeRemarks IS NULL
	|					AND RoomInventory.Customer.ClientTypeRemarks <> &qEmptyString
	|				THEN RoomInventory.Customer.ClientTypeRemarks
	|			ELSE RoomInventory.ClientType.Remarks
	|		END) AS ClientTypeRemarks,
	|	Guest.*,
	|	RoomInventory.Guest.Remarks AS GuestRemarks,
	|	CheckInDate,
	|	RoomInventory.Duration,
	|	CheckOutDate,
	|	RoomInventory.WaitTillDate,
	|	RoomInventory.CheckInAccountingDate,
	|	RoomInventory.CheckOutAccountingDate,
	|	(HOUR(RoomInventory.CheckInDate)) AS CheckInHour,
	|	(DAY(RoomInventory.CheckInDate)) AS CheckInDay,
	|	(WEEK(RoomInventory.CheckInDate)) AS CheckInWeek,
	|	(MONTH(RoomInventory.CheckInDate)) AS CheckInMonth,
	|	(QUARTER(RoomInventory.CheckInDate)) AS CheckInQuarter,
	|	(YEAR(RoomInventory.CheckInDate)) AS CheckInYear,
	|	(HOUR(RoomInventory.Recorder.Date)) AS CreateHour,
	|	(BEGINOFPERIOD(RoomInventory.Recorder.Date, DAY)) AS CreateDate,
	|	(WEEK(RoomInventory.Recorder.Date)) AS CreateWeek,
	|	(MONTH(RoomInventory.Recorder.Date)) AS CreateMonth,
	|	(QUARTER(RoomInventory.Recorder.Date)) AS CreateQuarter,
	|	(YEAR(RoomInventory.Recorder.Date)) AS CreateYear,
	|	RoomInventory.Room.*,
	|	RoomType.*,
	|	PriceByRoomType.*,
	|	AccommodationType.*,
	|	RoomInventory.Recorder.AccommodationTemplate.* AS AccommodationTemplate,
	|	RoomInventory.Room.BedsSetup.* AS BedsSetupInRoom,
	|	RoomInventory.Recorder.BedsSetup.* AS BedsSetupInReservation,
	|	(CASE
	|			WHEN RoomInventory.Recorder.BedsSetup <> VALUE(Catalog.BedsSetups.EmptyRef)
	|					AND RoomInventory.Recorder.BedsSetup <> RoomInventory.Room.BedsSetup
	|					AND RoomInventory.Room <> VALUE(Catalog.Rooms.EmptyRef)
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS BedsSetupDiscrepancy,
	|	ExtraBedsNeeded,
	|	BabycotsNeeded,
	|	RoomInventory.RoomRateType.*,
	|	RoomRate.*,
	|	PricePresentation,
	|	PlannedPaymentMethod.*,
	|	RoomsReserved,
	|	BedsReserved,
	|	AdditionalBedsReserved,
	|	GuestsReserved,
	|	NumberOfAdults,
	|	NumberOfTeenagers,
	|	NumberOfChildren,
	|	NumberOfInfants,
	|	Remarks,
	|	RoomInventory.RoomPropertiesDescriptions,
	|	RoomInventory.RoomPropertiesCodes,
	|	RoomInventory.HousekeepingRemarks,
	|	RoomInventory.Car,
	|	RoomInventory.IsMaster,
	|	RoomInventory.HotelProduct.*,
	|	RoomInventory.RoomQuota.*,
	|	RoomInventory.MarketingCode.*,
	|	RoomInventory.TripPurpose.*,
	|	RoomInventory.SourceOfBusiness.*,
	|	RoomInventory.DiscountCard.*,
	|	RoomInventory.DiscountType.*,
	|	RoomInventory.Discount,
	|	RoomInventory.AgentCommission,
	|	RoomInventory.AgentCommissionType,
	|	RoomInventory.RoomQuantity,
	|	RoomInventory.NumberOfBedsPerRoom,
	|	RoomInventory.NumberOfPersonsPerRoom,
	|	RoomInventory.Company.*,
	|	RoomInventory.ParentDoc.*,
	|	RoomInventory.Author.*,
	|	Recorder.*,
	|	RoomInventory.Recorder.ExternalCode AS ExternalCode,
	|	RoomInventory.PointInTime,
	|	RoomInventory.Account.*,
	|	RoomInventory.AccountCurrency.*,
	|	(NULL) AS EmptyColumn,
	|	RoomInventory.InvoiceAge,
	|	RoomInventory.DaysBeforeCheckIn,
	|	RoomInventory.SumInvoice,
	|	RoomInventory.SumPayedByInvoice,
	|	RoomInventory.AccountBalance,
	|	GuestGroupSales,
	|	GuestGroupSalesWithoutVAT,
	|	GuestGroupPayments,
	|	GuestGroupPaymentsWithoutVAT,
	|	GuestGroupBalances,
	|	GuestGroupBalancesWithoutVAT,
	|	NumberOfClientCheckins,
	|	NumberOfClientRoomNights,
	|	NumberOfClientGuestDays,
	|	ClientRoomRevenue,
	|	ClientSales,
	|	SumPayed,
	|	(CASE
	|			WHEN GuestGroupLastAttachments.AttachmentType IS NULL
	|				THEN &qEmptyAttachmentType
	|			ELSE GuestGroupLastAttachments.AttachmentType
	|		END) AS AttachmentType,
	|	(CASE
	|			WHEN (CAST(GuestGroupLastAttachments.DocumentText AS STRING(100))) <> &qEmptyString
	|				THEN GuestGroupLastAttachments.DocumentText
	|			WHEN (CAST(GuestGroupLastAttachments.Remarks AS STRING(100))) <> &qEmptyString
	|				THEN GuestGroupLastAttachments.Remarks
	|			WHEN (CAST(GuestGroupLastAttachments.FileName AS STRING(100))) <> &qEmptyString
	|				THEN GuestGroupLastAttachments.FileName
	|			ELSE &qEmptyString
	|		END) AS AttachmentText,
	|	(CASE
	|			WHEN GuestGroupLastAttachments.Author IS NULL
	|				THEN &qEmptyEmployee
	|			ELSE GuestGroupLastAttachments.Author
	|		END) AS AttachmentAuthor,
	|	ClientsInformation.ClientsInformationCounter AS ClientsInformationCounter,
	|	ReservationCustomAttributeValues1.CharacteristicValue.* AS CustomAttribute1,
	|	ReservationCustomAttributeValues2.CharacteristicValue.* AS CustomAttribute2,
	|	ReservationCustomAttributeValues3.CharacteristicValue.* AS CustomAttribute3}
	|FROM
	|	(SELECT
	|		RoomInventoryMovements.Recorder.Hotel AS Hotel,
	|		RoomInventoryMovements.Recorder.GuestGroup AS GuestGroup,
	|		RoomInventoryMovements.Recorder.CustomerType AS CustomerType,
	|		RoomInventoryMovements.Recorder.Customer AS Customer,
	|		RoomInventoryMovements.Recorder.Contract AS Contract,
	|		RoomInventoryMovements.Recorder.ContactPerson AS ContactPerson,
	|		RoomInventoryMovements.Recorder.Agent AS Agent,
	|		CASE
	|			WHEN VALUETYPE(RoomInventoryMovements.Recorder) = TYPE(Document.Reservation)
	|				THEN RoomInventoryMovements.Recorder.ReservationStatus
	|			ELSE RoomInventoryMovements.Recorder.AccommodationStatus
	|		END AS ReservationStatus,
	|		RoomInventoryMovements.Recorder.ClientType AS ClientType,
	|		RoomInventoryMovements.Recorder.Guest AS Guest,
	|		RoomInventoryMovements.Recorder.CheckInDate AS CheckInDate,
	|		RoomInventoryMovements.Recorder.Duration AS Duration,
	|		RoomInventoryMovements.Recorder.CheckOutDate AS CheckOutDate,
	|		RoomInventoryMovements.Recorder.WaitTillDate AS WaitTillDate,
	|		RoomInventoryMovements.CheckInAccountingDate AS CheckInAccountingDate,
	|		RoomInventoryMovements.CheckOutAccountingDate AS CheckOutAccountingDate,
	|		RoomInventoryMovements.Room AS Room,
	|		RoomInventoryMovements.RoomType AS RoomType,
	|		RoomInventoryMovements.AccommodationType AS AccommodationType,
	|		RoomInventoryMovements.RoomRateType AS RoomRateType,
	|		RoomInventoryMovements.RoomRate AS RoomRate,
	|		RoomInventoryMovements.Recorder.PricePresentation AS PricePresentation,
	|		RoomInventoryMovements.Recorder.PlannedPaymentMethod AS PlannedPaymentMethod,
	|		RoomInventoryMovements.RoomsReserved AS RoomsReserved,
	|		RoomInventoryMovements.BedsReserved AS BedsReserved,
	|		RoomInventoryMovements.AdditionalBedsReserved AS AdditionalBedsReserved,
	|		RoomInventoryMovements.GuestsReserved AS GuestsReserved,
	|		RoomInventoryMovements.Recorder.Remarks AS Remarks,
	|		RoomInventoryMovements.Recorder.HousekeepingRemarks AS HousekeepingRemarks,
	|		RoomInventoryMovements.Recorder.RoomPropertiesCodes AS RoomPropertiesCodes,
	|		RoomInventoryMovements.Recorder.RoomPropertiesDescriptions AS RoomPropertiesDescriptions,
	|		RoomInventoryMovements.Recorder.Car AS Car,
	|		RoomInventoryMovements.Recorder.IsMaster AS IsMaster,
	|		RoomInventoryMovements.Recorder.HotelProduct AS HotelProduct,
	|		RoomInventoryMovements.Recorder.RoomQuota AS RoomQuota,
	|		RoomInventoryMovements.Recorder.MarketingCode AS MarketingCode,
	|		RoomInventoryMovements.Recorder.TripPurpose AS TripPurpose,
	|		RoomInventoryMovements.Recorder.SourceOfBusiness AS SourceOfBusiness,
	|		RoomInventoryMovements.Recorder.DiscountCard AS DiscountCard,
	|		RoomInventoryMovements.Recorder.DiscountType AS DiscountType,
	|		RoomInventoryMovements.Recorder.Discount AS Discount,
	|		RoomInventoryMovements.Recorder.AgentCommission AS AgentCommission,
	|		RoomInventoryMovements.Recorder.AgentCommissionType AS AgentCommissionType,
	|		RoomInventoryMovements.Recorder.RoomQuantity AS RoomQuantity,
	|		RoomInventoryMovements.Recorder.NumberOfBedsPerRoom AS NumberOfBedsPerRoom,
	|		RoomInventoryMovements.Recorder.NumberOfPersonsPerRoom AS NumberOfPersonsPerRoom,
	|		RoomInventoryMovements.Recorder.Company AS Company,
	|		RoomInventoryMovements.Recorder.ParentDoc AS ParentDoc,
	|		RoomInventoryMovements.Recorder.Author AS Author,
	|		RoomInventoryMovements.Recorder AS Recorder,
	|		RoomInventoryMovements.Recorder.PointInTime AS PointInTime,
	|		ReservationFolioBalances.Folio AS Account,
	|		ReservationFolioBalances.FolioCurrency AS AccountCurrency,
	|		DATEDIFF(&qBegOfCurrentDate, BEGINOFPERIOD(RoomInventoryMovements.Recorder.CheckInDate, DAY), DAY) AS DaysBeforeCheckIn,
	|		0 AS InvoiceAge,
	|		0 AS SumInvoice,
	|		ISNULL(ReservationFolioBalances.FolioBalance, 0) AS AccountBalance,
	|		0 AS SumPayedByInvoice,
	|		GuestGroupBalances.Sales AS GuestGroupSales,
	|		GuestGroupBalances.SalesWithoutVAT AS GuestGroupSalesWithoutVAT,
	|		GuestGroupBalances.Payments AS GuestGroupPayments,
	|		GuestGroupBalances.PaymentsWithoutVAT AS GuestGroupPaymentsWithoutVAT,
	|		GuestGroupBalances.Balances AS GuestGroupBalances,
	|		GuestGroupBalances.BalancesWithoutVAT AS GuestGroupBalancesWithoutVAT
	|	FROM
	|		(SELECT
	|			RoomInventoryDetailedMovements.Recorder AS Recorder,
	|			RoomInventoryDetailedMovements.Room AS Room,
	|			RoomInventoryDetailedMovements.RoomType AS RoomType,
	|			RoomInventoryDetailedMovements.AccommodationType AS AccommodationType,
	|			RoomInventoryDetailedMovements.RoomRateType AS RoomRateType,
	|			RoomInventoryDetailedMovements.RoomRate AS RoomRate,
	|			RoomInventoryDetailedMovements.CheckInAccountingDate AS CheckInAccountingDate,
	|			RoomInventoryDetailedMovements.CheckOutAccountingDate AS CheckOutAccountingDate,
	|			MAX(CASE
	|					WHEN VALUETYPE(RoomInventoryDetailedMovements.Recorder) = TYPE(Document.Reservation)
	|						THEN RoomInventoryDetailedMovements.ExpectedRoomsCheckedIn
	|					ELSE RoomInventoryDetailedMovements.RoomsCheckedIn
	|				END) AS RoomsReserved,
	|			MAX(CASE
	|					WHEN VALUETYPE(RoomInventoryDetailedMovements.Recorder) = TYPE(Document.Reservation)
	|						THEN RoomInventoryDetailedMovements.ExpectedBedsCheckedIn
	|					ELSE RoomInventoryDetailedMovements.BedsCheckedIn
	|				END) AS BedsReserved,
	|			MAX(CASE
	|					WHEN VALUETYPE(RoomInventoryDetailedMovements.Recorder) = TYPE(Document.Reservation)
	|						THEN RoomInventoryDetailedMovements.ExpectedAdditionalBedsCheckedIn
	|					ELSE RoomInventoryDetailedMovements.AdditionalBedsCheckedIn
	|				END) AS AdditionalBedsReserved,
	|			MAX(CASE
	|					WHEN VALUETYPE(RoomInventoryDetailedMovements.Recorder) = TYPE(Document.Reservation)
	|						THEN RoomInventoryDetailedMovements.ExpectedGuestsCheckedIn
	|					ELSE RoomInventoryDetailedMovements.GuestsCheckedIn
	|				END) AS GuestsReserved
	|		FROM
	|			AccumulationRegister.RoomInventory AS RoomInventoryDetailedMovements
	|		WHERE
	|			RoomInventoryDetailedMovements.RecordType = VALUE(AccumulationRecordType.Expense)
	|			AND (RoomInventoryDetailedMovements.IsReservation
	|					OR &qShowCheckedInGuests
	|						AND RoomInventoryDetailedMovements.IsAccommodation
	|						AND RoomInventoryDetailedMovements.IsCheckIn)
	|			AND (&qHotelIsEmpty
	|					OR RoomInventoryDetailedMovements.Hotel IN HIERARCHY (&qHotel))
	|			AND RoomInventoryDetailedMovements.RoomType IN HIERARCHY(&qRoomType)
	|			AND (RoomInventoryDetailedMovements.CheckInDate >= &qPeriodFrom
	|						AND RoomInventoryDetailedMovements.CheckInDate < &qPeriodTo
	|						AND RoomInventoryDetailedMovements.CheckInDate = RoomInventoryDetailedMovements.PeriodFrom
	|					OR RoomInventoryDetailedMovements.Recorder IN
	|							(SELECT
	|								BookedOutEndReservations.Ref
	|							FROM
	|								BookedOutEndReservations AS BookedOutEndReservations)
	|						AND RoomInventoryDetailedMovements.Period = RoomInventoryDetailedMovements.PeriodFrom)
	|			AND (&qCustomerIsEmpty
	|					OR RoomInventoryDetailedMovements.Customer IN HIERARCHY (&qCustomer))
	|			AND (&qContractIsEmpty
	|					OR RoomInventoryDetailedMovements.Contract = &qContract)
	|			AND (&qRoomRateIsEmpty
	|					OR RoomInventoryDetailedMovements.RoomRate IN HIERARCHY (&qRoomRate))
	|			AND (&qGuestGroupIsEmpty
	|					OR RoomInventoryDetailedMovements.GuestGroup = &qGuestGroup)
	|			AND (&qReservationIsEmpty
	|					OR RoomInventoryDetailedMovements.Recorder = &qReservation)
	|			AND (NOT &qShowMainRoomGuestsOnly
	|					OR &qShowMainRoomGuestsOnly
	|						AND RoomInventoryDetailedMovements.Recorder.AccommodationTemplate <> &qEmptyTEmplate)
	|		
	|		GROUP BY
	|			RoomInventoryDetailedMovements.Recorder,
	|			RoomInventoryDetailedMovements.CheckInAccountingDate,
	|			RoomInventoryDetailedMovements.CheckOutAccountingDate,
	|			RoomInventoryDetailedMovements.Room,
	|			RoomInventoryDetailedMovements.RoomType,
	|			RoomInventoryDetailedMovements.AccommodationType,
	|			RoomInventoryDetailedMovements.RoomRateType,
	|			RoomInventoryDetailedMovements.RoomRate) AS RoomInventoryMovements
	|			LEFT JOIN (SELECT
	|				FolioBalances.Folio AS Folio,
	|				FolioBalances.FolioCurrency AS FolioCurrency,
	|				FolioBalances.FolioParentDoc AS FolioParentDoc,
	|				FolioBalances.FolioBalance AS FolioBalance
	|			FROM
	|				FolioBalances AS FolioBalances) AS ReservationFolioBalances
	|			ON RoomInventoryMovements.Recorder = ReservationFolioBalances.FolioParentDoc
	|			LEFT JOIN (SELECT
	|				GuestGroupBalances.GuestGroup AS GuestGroup,
	|				GuestGroupBalances.Currency AS Currency,
	|				GuestGroupBalances.Sales AS Sales,
	|				GuestGroupBalances.SalesWithoutVAT AS SalesWithoutVAT,
	|				GuestGroupBalances.Payments AS Payments,
	|				GuestGroupBalances.PaymentsWithoutVAT AS PaymentsWithoutVAT,
	|				GuestGroupBalances.GroupBalance AS Balances,
	|				GuestGroupBalances.GroupBalanceWithoutVAT AS BalancesWithoutVAT
	|			FROM
	|				GuestGroupBalances AS GuestGroupBalances) AS GuestGroupBalances
	|			ON RoomInventoryMovements.Recorder.GuestGroup = GuestGroupBalances.GuestGroup
	|				AND RoomInventoryMovements.Recorder.ReportingCurrency = GuestGroupBalances.Currency
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		InvoiceAccountsTurnovers.Hotel,
	|		InvoiceAccountsTurnovers.GuestGroup,
	|		NULL,
	|		InvoiceAccountsTurnovers.AccountingCustomer,
	|		InvoiceAccountsTurnovers.AccountingContract,
	|		InvoiceAccountsTurnovers.Invoice.ContactPerson,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		GuestGroupTotals.CheckInDate,
	|		DATEDIFF(GuestGroupTotals.CheckInDate, GuestGroupTotals.CheckOutDate, DAY),
	|		GuestGroupTotals.CheckOutDate,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		0,
	|		0,
	|		0,
	|		0,
	|		InvoiceAccountsTurnovers.Invoice.Remarks,
	|		&qEmptyString,
	|		&qEmptyString,
	|		&qEmptyString,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		InvoiceAccountsTurnovers.Company,
	|		InvoiceAccountsTurnovers.Invoice.ParentDoc,
	|		InvoiceAccountsTurnovers.Invoice.Author,
	|		NULL,
	|		NULL,
	|		InvoiceAccountsTurnovers.Invoice,
	|		InvoiceAccountsTurnovers.AccountingCurrency,
	|		0,
	|		DATEDIFF(BEGINOFPERIOD(InvoiceAccountsTurnovers.Invoice.Date, DAY), &qBegOfCurrentDate, DAY),
	|		InvoiceAccountsTurnovers.SumReceipt,
	|		InvoiceAccountsTurnovers.SumReceipt - InvoiceAccountsTurnovers.SumExpense,
	|		InvoiceAccountsTurnovers.SumExpense,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0
	|	FROM
	|		AccumulationRegister.InvoiceAccounts.Turnovers(
	|				&qBegOfTime,
	|				&qEndOfTime,
	|				Period,
	|				&qShowInvoicesAndDeposits
	|					AND (&qHotelIsEmpty
	|						OR Hotel IN HIERARCHY (&qHotel))
	|					AND (&qGuestGroupIsEmpty
	|						OR GuestGroup = &qGuestGroup)
	|					AND GuestGroup IN
	|						(SELECT
	|							ExpectedGuestGroups.GuestGroup
	|						FROM
	|							ExpectedGuestGroups AS ExpectedGuestGroups)) AS InvoiceAccountsTurnovers
	|			LEFT JOIN (SELECT
	|				ExpectedGuestGroups.GuestGroup AS GuestGroup,
	|				ExpectedGuestGroups.CheckInDate AS CheckInDate,
	|				ExpectedGuestGroups.CheckOutDate AS CheckOutDate
	|			FROM
	|				ExpectedGuestGroups AS ExpectedGuestGroups) AS GuestGroupTotals
	|			ON InvoiceAccountsTurnovers.GuestGroup = GuestGroupTotals.GuestGroup) AS RoomInventory
	|		LEFT JOIN (SELECT
	|			ClientsInformationRecords.Client AS Client,
	|			COUNT(ClientsInformationRecords.InformationType) AS ClientsInformationCounter
	|		FROM
	|			InformationRegister.ClientsInformation.SliceLast(
	|					,
	|					NOT InformationType.DeletionMark
	|						AND (CAST(Remarks AS STRING(1024))) <> &qEmptyString) AS ClientsInformationRecords
	|		
	|		GROUP BY
	|			ClientsInformationRecords.Client) AS ClientsInformation
	|		ON RoomInventory.Guest = ClientsInformation.Client
	|		LEFT JOIN InformationRegister.GuestGroupAttachments.SliceLast(&qPeriodFrom, ) AS GuestGroupLastAttachments
	|		ON RoomInventory.GuestGroup = GuestGroupLastAttachments.GuestGroup
	|			AND (GuestGroupLastAttachments.AttachmentStatus <> &qSent)
	|			AND (GuestGroupLastAttachments.AttachmentStatus <> &qReady)
	|			AND (&qUseGuestGroupAttachments)
	|		LEFT JOIN GuestStatistics AS GuestStatistics
	|		ON RoomInventory.Recorder.Guest = GuestStatistics.Guest
	|			AND (RoomInventory.Recorder.Guest <> VALUE(Catalog.Clients.EmptyRef))
	|		LEFT JOIN ReservationPayments AS ReservationPayments
	|		ON RoomInventory.Recorder = ReservationPayments.Reservation
	|		LEFT JOIN InformationRegister.ReservationCustomAttributeValues AS ReservationCustomAttributeValues1
	|		ON (RoomInventory.Recorder.Reservation = ReservationCustomAttributeValues1.Owner
	|				OR RoomInventory.Recorder = ReservationCustomAttributeValues1.Owner
	|					AND RoomInventory.Recorder.Reservation.Number IS NULL)
	|			AND (ReservationCustomAttributeValues1.Characteristic = &qCustomAttribute1)
	|		LEFT JOIN InformationRegister.ReservationCustomAttributeValues AS ReservationCustomAttributeValues2
	|		ON (RoomInventory.Recorder.Reservation = ReservationCustomAttributeValues2.Owner
	|				OR RoomInventory.Recorder = ReservationCustomAttributeValues2.Owner
	|					AND RoomInventory.Recorder.Reservation.Number IS NULL)
	|			AND (ReservationCustomAttributeValues2.Characteristic = &qCustomAttribute2)
	|		LEFT JOIN InformationRegister.ReservationCustomAttributeValues AS ReservationCustomAttributeValues3
	|		ON (RoomInventory.Recorder.Reservation = ReservationCustomAttributeValues3.Owner
	|				OR RoomInventory.Recorder = ReservationCustomAttributeValues3.Owner
	|					AND RoomInventory.Recorder.Reservation.Number IS NULL)
	|			AND (ReservationCustomAttributeValues3.Characteristic = &qCustomAttribute3)
	|{WHERE
	|	RoomInventory.Recorder.*,
	|	RoomInventory.Recorder.ExternalCode AS ExternalCode,
	|	RoomInventory.Hotel.*,
	|	RoomInventory.RoomType.*,
	|	(CASE
	|			WHEN RoomInventory.Recorder.RoomTypeUpgrade = VALUE(Catalog.RoomTypes.EmptyRef)
	|				THEN RoomInventory.RoomType
	|			ELSE RoomInventory.Recorder.RoomTypeUpgrade
	|		END) AS PriceByRoomType,
	|	RoomInventory.Room.*,
	|	RoomInventory.Customer.*,
	|	RoomInventory.CustomerType.*,
	|	RoomInventory.Contract.*,
	|	RoomInventory.ContactPerson,
	|	RoomInventory.Agent.*,
	|	RoomInventory.GuestGroup.*,
	|	RoomInventory.GuestGroup.Remarks AS GuestGroupRemarks,
	|	RoomInventory.ParentDoc.*,
	|	RoomInventory.HotelProduct.*,
	|	RoomInventory.ReservationStatus.*,
	|	RoomInventory.CheckInDate,
	|	RoomInventory.Duration,
	|	RoomInventory.CheckOutDate,
	|	RoomInventory.WaitTillDate,
	|	RoomInventory.CheckInAccountingDate,
	|	RoomInventory.CheckOutAccountingDate,
	|	(CASE
	|			WHEN &qShowMainRoomGuestsOnly
	|				THEN ISNULL(RoomInventory.Recorder.NumberOfAdults, 0) + ISNULL(RoomInventory.Recorder.NumberOfTeenagers, 0) + ISNULL(RoomInventory.Recorder.NumberOfChildren, 0) + ISNULL(RoomInventory.Recorder.NumberOfInfants, 0)
	|			ELSE RoomInventory.GuestsReserved
	|		END) AS GuestsReserved,
	|	(ISNULL(RoomInventory.Recorder.NumberOfAdults, 0)) AS NumberOfAdults,
	|	(ISNULL(RoomInventory.Recorder.NumberOfTeenagers, 0)) AS NumberOfTeenagers,
	|	(ISNULL(RoomInventory.Recorder.NumberOfChildren, 0)) AS NumberOfChildren,
	|	(ISNULL(RoomInventory.Recorder.NumberOfInfants, 0)) AS NumberOfInfants,
	|	RoomInventory.RoomsReserved,
	|	RoomInventory.BedsReserved,
	|	RoomInventory.AdditionalBedsReserved,
	|	RoomInventory.RoomQuota.*,
	|	RoomInventory.RoomQuantity,
	|	RoomInventory.ClientType.*,
	|	RoomInventory.Guest.*,
	|	RoomInventory.Guest.Remarks AS GuestRemarks,
	|	RoomInventory.MarketingCode.*,
	|	RoomInventory.TripPurpose.*,
	|	RoomInventory.SourceOfBusiness.*,
	|	RoomInventory.RoomRateType.*,
	|	RoomInventory.RoomRate.*,
	|	RoomInventory.PricePresentation,
	|	RoomInventory.DiscountCard,
	|	RoomInventory.DiscountType,
	|	RoomInventory.Discount,
	|	RoomInventory.PlannedPaymentMethod.*,
	|	RoomInventory.Author.*,
	|	RoomInventory.Car,
	|	RoomInventory.Remarks,
	|	RoomInventory.RoomPropertiesDescriptions,
	|	RoomInventory.RoomPropertiesCodes,
	|	RoomInventory.HousekeepingRemarks,
	|	RoomInventory.AgentCommission,
	|	RoomInventory.AgentCommissionType,
	|	RoomInventory.Recorder.AccommodationTemplate.* AS AccommodationTemplate,
	|	RoomInventory.Room.BedsSetup.* AS BedsSetupInRoom,
	|	RoomInventory.Recorder.BedsSetup.* AS BedsSetupInReservation,
	|	(CASE
	|			WHEN RoomInventory.Recorder.BedsSetup <> VALUE(Catalog.BedsSetups.EmptyRef)
	|					AND RoomInventory.Recorder.BedsSetup <> RoomInventory.Room.BedsSetup
	|					AND RoomInventory.Room <> VALUE(Catalog.Rooms.EmptyRef)
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS BedsSetupDiscrepancy,
	|	(CASE
	|			WHEN RoomInventory.Recorder.NumberOfBeds <> 0
	|				THEN RoomInventory.Recorder.BedsSetup.NumberOfExtraBeds
	|			ELSE 0
	|		END) AS ExtraBedsNeeded,
	|	(CASE
	|			WHEN RoomInventory.Recorder.NumberOfBeds <> 0
	|				THEN RoomInventory.Recorder.BedsSetup.NumberOfBabycots
	|			ELSE 0
	|		END) AS BabycotsNeeded,
	|	RoomInventory.IsMaster,
	|	RoomInventory.Account.*,
	|	RoomInventory.DaysBeforeCheckIn,
	|	RoomInventory.InvoiceAge,
	|	RoomInventory.AccountCurrency.*,
	|	RoomInventory.AccountBalance,
	|	RoomInventory.SumInvoice,
	|	RoomInventory.SumPayedByInvoice,
	|	(ISNULL(ReservationPayments.AmountPayed, 0)) AS SumPayed,
	|	(ISNULL(GuestStatistics.NumberOfClientCheckIns, 0)) AS NumberOfClientCheckins,
	|	(ISNULL(GuestStatistics.NumberOfClientRoomNights, 0)) AS NumberOfClientRoomNights,
	|	(ISNULL(GuestStatistics.NumberOfClientGuestDays, 0)) AS NumberOfClientGuestDays,
	|	(ISNULL(GuestStatistics.ClientRoomRevenue, 0)) AS ClientRoomRevenue,
	|	(ISNULL(GuestStatistics.ClientSales, 0)) AS ClientSales,
	|	RoomInventory.GuestGroupSales AS GuestGroupSales,
	|	RoomInventory.GuestGroupSalesWithoutVAT AS GuestGroupSalesWithoutVAT,
	|	RoomInventory.GuestGroupPayments AS GuestGroupPayments,
	|	RoomInventory.GuestGroupPaymentsWithoutVAT AS GuestGroupPaymentsWithoutVAT,
	|	RoomInventory.GuestGroupBalances AS GuestGroupBalances,
	|	RoomInventory.GuestGroupBalancesWithoutVAT AS GuestGroupBalancesWithoutVAT,
	|	(CASE
	|			WHEN GuestGroupLastAttachments.AttachmentType IS NULL
	|				THEN &qEmptyAttachmentType
	|			ELSE GuestGroupLastAttachments.AttachmentType
	|		END) AS AttachmentType,
	|	(CASE
	|			WHEN (CAST(GuestGroupLastAttachments.DocumentText AS STRING(100))) <> &qEmptyString
	|				THEN GuestGroupLastAttachments.DocumentText
	|			WHEN (CAST(GuestGroupLastAttachments.Remarks AS STRING(100))) <> &qEmptyString
	|				THEN GuestGroupLastAttachments.Remarks
	|			WHEN (CAST(GuestGroupLastAttachments.FileName AS STRING(100))) <> &qEmptyString
	|				THEN GuestGroupLastAttachments.FileName
	|			ELSE &qEmptyString
	|		END) AS AttachmentText,
	|	(CASE
	|			WHEN GuestGroupLastAttachments.Author IS NULL
	|				THEN &qEmptyEmployee
	|			ELSE GuestGroupLastAttachments.Author
	|		END) AS AttachmentAuthor,
	|	ClientsInformation.ClientsInformationCounter AS ClientsInformationCounter,
	|	ReservationCustomAttributeValues1.CharacteristicValue.* AS CustomAttribute1,
	|	ReservationCustomAttributeValues2.CharacteristicValue.* AS CustomAttribute2,
	|	ReservationCustomAttributeValues3.CharacteristicValue.* AS CustomAttribute3}
	|
	|ORDER BY
	|	Hotel,
	|	GuestGroup,
	|	CheckInDate,
	|	Guest
	|{ORDER BY
	|	Customer.*,
	|	RoomInventory.CustomerType.*,
	|	RoomInventory.Contract.*,
	|	RoomInventory.Agent.*,
	|	GuestGroup.*,
	|	Guest.*,
	|	RoomInventory.MarketingCode.*,
	|	RoomInventory.TripPurpose.*,
	|	RoomInventory.SourceOfBusiness.*,
	|	RoomInventory.RoomRateType.*,
	|	RoomInventory.ClientType.*,
	|	RoomRate.*,
	|	PricePresentation,
	|	RoomInventory.DiscountCard,
	|	RoomInventory.DiscountType.*,
	|	PlannedPaymentMethod.*,
	|	RoomInventory.Room.*,
	|	RoomType.*,
	|	PriceByRoomType.*,
	|	Hotel.*,
	|	RoomInventory.PointInTime,
	|	CheckInDate,
	|	RoomInventory.Duration,
	|	CheckOutDate,
	|	RoomInventory.WaitTillDate,
	|	RoomInventory.Recorder.AccommodationTemplate.* AS AccommodationTemplate,
	|	RoomInventory.Room.BedsSetup.* AS BedsSetupInRoom,
	|	RoomInventory.Recorder.BedsSetup.* AS BedsSetupInReservation,
	|	(CASE
	|			WHEN RoomInventory.Recorder.BedsSetup <> VALUE(Catalog.BedsSetups.EmptyRef)
	|					AND RoomInventory.Recorder.BedsSetup <> RoomInventory.Room.BedsSetup
	|					AND RoomInventory.Room <> VALUE(Catalog.Rooms.EmptyRef)
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS BedsSetupDiscrepancy,
	|	ExtraBedsNeeded,
	|	BabycotsNeeded,
	|	GuestsReserved,
	|	NumberOfAdults,
	|	NumberOfTeenagers,
	|	NumberOfChildren,
	|	NumberOfInfants,
	|	RoomsReserved,
	|	BedsReserved,
	|	AdditionalBedsReserved,
	|	RoomInventory.Author.*,
	|	RoomInventory.CheckInAccountingDate,
	|	RoomInventory.CheckOutAccountingDate,
	|	(HOUR(RoomInventory.CheckInDate)) AS CheckInHour,
	|	(DAY(RoomInventory.CheckInDate)) AS CheckInDay,
	|	(WEEK(RoomInventory.CheckInDate)) AS CheckInWeek,
	|	(MONTH(RoomInventory.CheckInDate)) AS CheckInMonth,
	|	(QUARTER(RoomInventory.CheckInDate)) AS CheckInQuarter,
	|	(YEAR(RoomInventory.CheckInDate)) AS CheckInYear,
	|	(HOUR(RoomInventory.Recorder.Date)) AS CreateHour,
	|	(BEGINOFPERIOD(RoomInventory.Recorder.Date, DAY)) AS CreateDate,
	|	(WEEK(RoomInventory.Recorder.Date)) AS CreateWeek,
	|	(MONTH(RoomInventory.Recorder.Date)) AS CreateMonth,
	|	(QUARTER(RoomInventory.Recorder.Date)) AS CreateQuarter,
	|	(YEAR(RoomInventory.Recorder.Date)) AS CreateYear,
	|	Recorder.*,
	|	RoomInventory.RoomPropertiesDescriptions,
	|	RoomInventory.RoomPropertiesCodes,
	|	RoomInventory.Recorder.ExternalCode AS ExternalCode,
	|	RoomInventory.RoomQuota,
	|	RoomInventory.Account.*,
	|	RoomInventory.AccountCurrency.*,
	|	RoomInventory.DaysBeforeCheckIn,
	|	RoomInventory.InvoiceAge,
	|	RoomInventory.AccountBalance,
	|	RoomInventory.SumInvoice,
	|	RoomInventory.SumPayedByInvoice,
	|	NumberOfClientCheckins,
	|	NumberOfClientRoomNights,
	|	NumberOfClientGuestDays,
	|	ClientRoomRevenue,
	|	ClientSales,
	|	SumPayed,
	|	GuestGroupSales,
	|	GuestGroupSalesWithoutVAT,
	|	GuestGroupPayments,
	|	GuestGroupPaymentsWithoutVAT,
	|	GuestGroupBalances,
	|	GuestGroupBalancesWithoutVAT,
	|	ClientsInformation.ClientsInformationCounter AS ClientsInformationCounter,
	|	ReservationCustomAttributeValues1.CharacteristicValue.* AS CustomAttribute1,
	|	ReservationCustomAttributeValues2.CharacteristicValue.* AS CustomAttribute2,
	|	ReservationCustomAttributeValues3.CharacteristicValue.* AS CustomAttribute3}
	|TOTALS
	|	SUM(GuestsReserved),
	|	SUM(NumberOfAdults),
	|	SUM(NumberOfTeenagers),
	|	SUM(NumberOfChildren),
	|	SUM(NumberOfInfants),
	|	SUM(RoomsReserved),
	|	SUM(BedsReserved),
	|	SUM(AdditionalBedsReserved),
	|	CASE
	|		WHEN NOT Recorder IS NULL
	|			THEN 0
	|		WHEN GuestGroup IS NULL
	|			THEN 0
	|		ELSE MAX(GuestGroupSales)
	|	END AS GuestGroupSales,
	|	CASE
	|		WHEN NOT Recorder IS NULL
	|			THEN 0
	|		WHEN GuestGroup IS NULL
	|			THEN 0
	|		ELSE MAX(GuestGroupSalesWithoutVAT)
	|	END AS GuestGroupSalesWithoutVAT,
	|	CASE
	|		WHEN NOT Recorder IS NULL
	|			THEN 0
	|		WHEN GuestGroup IS NULL
	|			THEN 0
	|		ELSE MAX(GuestGroupPayments)
	|	END AS GuestGroupPayments,
	|	CASE
	|		WHEN NOT Recorder IS NULL
	|			THEN 0
	|		WHEN GuestGroup IS NULL
	|			THEN 0
	|		ELSE MAX(GuestGroupPaymentsWithoutVAT)
	|	END AS GuestGroupPaymentsWithoutVAT,
	|	CASE
	|		WHEN NOT Recorder IS NULL
	|			THEN 0
	|		WHEN GuestGroup IS NULL
	|			THEN 0
	|		ELSE MAX(GuestGroupBalances)
	|	END AS GuestGroupBalances,
	|	CASE
	|		WHEN NOT Recorder IS NULL
	|			THEN 0
	|		WHEN GuestGroup IS NULL
	|			THEN 0
	|		ELSE MAX(GuestGroupBalancesWithoutVAT)
	|	END AS GuestGroupBalancesWithoutVAT,
	|	SUM(SumPayed),
	|	SUM(ExtraBedsNeeded),
	|	SUM(BabycotsNeeded)
	|BY
	|	OVERALL,
	|	Hotel,
	|	GuestGroup,
	|	Recorder
	|{TOTALS BY
	|	Hotel.*,
	|	RoomInventory.CheckInAccountingDate,
	|	RoomInventory.CheckOutAccountingDate,
	|	(HOUR(RoomInventory.CheckInDate)) AS CheckInHour,
	|	(DAY(RoomInventory.CheckInDate)) AS CheckInDay,
	|	(WEEK(RoomInventory.CheckInDate)) AS CheckInWeek,
	|	(MONTH(RoomInventory.CheckInDate)) AS CheckInMonth,
	|	(QUARTER(RoomInventory.CheckInDate)) AS CheckInQuarter,
	|	(YEAR(RoomInventory.CheckInDate)) AS CheckInYear,
	|	(HOUR(RoomInventory.Recorder.Date)) AS CreateHour,
	|	(BEGINOFPERIOD(RoomInventory.Recorder.Date, DAY)) AS CreateDate,
	|	(WEEK(RoomInventory.Recorder.Date)) AS CreateWeek,
	|	(MONTH(RoomInventory.Recorder.Date)) AS CreateMonth,
	|	(QUARTER(RoomInventory.Recorder.Date)) AS CreateQuarter,
	|	(YEAR(RoomInventory.Recorder.Date)) AS CreateYear,
	|	RoomType.*,
	|	PriceByRoomType.*,
	|	RoomInventory.Room.*,
	|	Customer.*,
	|	RoomInventory.CustomerType.*,
	|	RoomInventory.Contract.*,
	|	RoomInventory.ContactPerson,
	|	RoomInventory.Agent.*,
	|	GuestGroup.*,
	|	RoomInventory.HotelProduct.*,
	|	ReservationStatus.*,
	|	RoomInventory.RoomQuota.*,
	|	RoomInventory.ClientType.*,
	|	RoomInventory.MarketingCode.*,
	|	RoomInventory.TripPurpose.*,
	|	RoomInventory.SourceOfBusiness.*,
	|	RoomInventory.RoomRateType.*,
	|	RoomInventory.RoomRate.*,
	|	RoomInventory.Author.*,
	|	RoomInventory.Recorder.AccommodationTemplate.* AS AccommodationTemplate,
	|	RoomInventory.Room.BedsSetup.* AS BedsSetupInRoom,
	|	RoomInventory.Recorder.BedsSetup.* AS BedsSetupInReservation,
	|	(CASE
	|			WHEN RoomInventory.Recorder.BedsSetup <> VALUE(Catalog.BedsSetups.EmptyRef)
	|					AND RoomInventory.Recorder.BedsSetup <> RoomInventory.Room.BedsSetup
	|					AND RoomInventory.Room <> VALUE(Catalog.Rooms.EmptyRef)
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS BedsSetupDiscrepancy,
	|	PricePresentation,
	|	RoomInventory.DiscountCard,
	|	RoomInventory.DiscountType,
	|	Recorder.*,
	|	PlannedPaymentMethod.*,
	|	RoomInventory.Account.*,
	|	RoomInventory.AccountCurrency.*,
	|	NumberOfClientCheckins,
	|	NumberOfClientRoomNights,
	|	NumberOfClientGuestDays,
	|	ReservationCustomAttributeValues1.CharacteristicValue.* AS CustomAttribute1,
	|	ReservationCustomAttributeValues2.CharacteristicValue.* AS CustomAttribute2,
	|	ReservationCustomAttributeValues3.CharacteristicValue.* AS CustomAttribute3}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Expected check in';RU='Планируемый заезд';de='Geplante Anreise'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
