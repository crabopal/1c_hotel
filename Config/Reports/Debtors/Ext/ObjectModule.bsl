
#Region Public

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
	If Not ValueIsFilled(DebtorsFilterType) Then
		DebtorsFilterType = Enums.DebtorsFilterTypes.All;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Должники на '; en = 'Debts on '; de = 'Schuldner auf '") + 
							 Format(PeriodTo, "DF='dd.MM.yyyy HH:mm'") + 
							 ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(CheckInDate) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Должники заезжающие на '; en = 'Debts on check-in date '; de = 'Schulden am check-in-Datum '") + 
							 Format(CheckInDate, "DF='dd.MM.yyyy'") + 
							 ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(CheckOutDate) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Должники выезжающие на '; en = 'Debts on check-out date '; de = 'Schulden am check-out-Datum '") + 
							 Format(CheckOutDate, "DF='dd.MM.yyyy'") + 
							 ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(Room) Then
		If Not Room.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Room ';ru='Номер ';de='Zimmer '") + 
			                     TrimAll(Room.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Rooms folder ';ru='Группа номеров ';de='Gruppe Zimmer '") + 
			                     TrimAll(Room.Description) + 
			                     ";" + Chars.LF;
		EndIf;
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
	If ValueIsFilled(FolioCurrency) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Валюта фолио '; en = 'Folio currency '; de = 'Folio Währung '") + 
							 TrimAll(FolioCurrency.Description) + 
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
	If ValueIsFilled(Service) Then
		If Not Service.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Отбор лицевых счетов по услуге '; en = 'Filter folios by service '; de = 'Auswahl von personenkonten nach Dienstleistung '") + 
			                     TrimAll(Service.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Отбор лицевых счетов по группе услуг '; en = 'Filter folios by services folder '; de = 'Auswahl von personenkonten nach Dienstleistungsgruppe '") + 
			                     TrimAll(Service.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;					 
	If ValueIsFilled(DebtorsFilterType) Then
		If DebtorsFilterType = Enums.DebtorsFilterTypes.NoDecisionYet Then
			vParamPresentation = vParamPresentation + NStr("en='Show debts where there is no decision yet';ru='Показывать должников, по которым еще не принято какое-либо решение';de='Schuldner anzeigen, zu denen noch keine Entscheidung getroffen wurde'") + 
			                     ";" + Chars.LF;
		ElsIf DebtorsFilterType = Enums.DebtorsFilterTypes.ThereIsDecision Then
			vParamPresentation = vParamPresentation + NStr("en='Show debts where decision was already made';ru='Показывать должников, по которым уже принято решение';de='Schuldner anzeigen, zu denen die Entscheidung bereits getroffen wurde'") + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(DebtDecision) Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Решение по долгам '; en = 'Debts decision '; de = 'Lösung für die Schulden '") + 
			                     TrimAll(DebtDecision) + 
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
// Runs report and returns if report form should be shown
// -----------------------------------------------------------------------------
Procedure pmGenerate(pSpreadsheet) Export
	Var vTemplateAttributes;
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Fill report parameters
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qPeriodTo", ?(ValueIsFilled(PeriodTo), New Boundary(PeriodTo, BoundaryType.Excluding), '39991231235959'));
	ReportBuilder.Parameters.Insert("qCurrentDate", CurrentSessionDate());
	ReportBuilder.Parameters.Insert("qBegOfCurrentDate", ?(ValueIsFilled(Hotel) And ValueIsFilled(Hotel.AccountingDate), Hotel.AccountingDate, BegOfDay(CurrentSessionDate())));
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qFilterByRoom", ValueIsFilled(Room));
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qFilterByRoomType", ValueIsFilled(RoomType));
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qFilterByCustomer", ValueIsFilled(Customer));
	ReportBuilder.Parameters.Insert("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	ReportBuilder.Parameters.Insert("qContract", Contract);
	ReportBuilder.Parameters.Insert("qFilterByContract", ValueIsFilled(Contract));
	ReportBuilder.Parameters.Insert("qFolioCurrency", FolioCurrency);
	ReportBuilder.Parameters.Insert("qFilterByFolioCurrency", ValueIsFilled(FolioCurrency));
	ReportBuilder.Parameters.Insert("qService", Service);
	ReportBuilder.Parameters.Insert("qServiceIsFilled", ValueIsFilled(Service));
	ReportBuilder.Parameters.Insert("qDebtDecision", DebtDecision);
	ReportBuilder.Parameters.Insert("qEmptyDebtDecision", Enums.DebtsDecisionTypes.EmptyRef());
	ReportBuilder.Parameters.Insert("qDebtDecisionIsFilled", ValueIsFilled(DebtDecision));
	ReportBuilder.Parameters.Insert("qAll", True);
	ReportBuilder.Parameters.Insert("qNoDecisionYet", True);
	ReportBuilder.Parameters.Insert("qThereIsDecision", True);
	If ValueIsFilled(DebtorsFilterType) Then
		If DebtorsFilterType = Enums.DebtorsFilterTypes.NoDecisionYet Then
			ReportBuilder.Parameters.qAll = False;
			ReportBuilder.Parameters.qThereIsDecision = False;
		ElsIf DebtorsFilterType = Enums.DebtorsFilterTypes.ThereIsDecision Then
			ReportBuilder.Parameters.qAll = False;
			ReportBuilder.Parameters.qNoDecisionYet = False;
		EndIf;
	EndIf;
	ReportBuilder.Parameters.Insert("qCheckInDate", CheckInDate);
	ReportBuilder.Parameters.Insert("qCheckInDateIsFilled", ValueIsFilled(CheckInDate));
	ReportBuilder.Parameters.Insert("qCheckOutDate", CheckOutDate);
	ReportBuilder.Parameters.Insert("qCheckOutDateIsFilled", ValueIsFilled(CheckOutDate));	
	
	vUsePerPaymentSectionBalance = False;
	For Each vReportField In ReportBuilder.SelectedFields Do
		If Find(vReportField.Name, "PaymentSection") > 0 Then
			vUsePerPaymentSectionBalance = True;
			Break;
		EndIf;
	EndDo;
	ReportBuilder.Parameters.Insert("qUsePerPaymentSectionBalance", vUsePerPaymentSectionBalance);	
	
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

	// Apply appearance settings to the report spreadsheet
	cmApplyReportAppearance(ThisObject, pSpreadsheet, vTemplateAttributes);
EndProcedure // pmGenerate

// -----------------------------------------------------------------------------
Procedure pmInitializeReportBuilder() Export
	ReportBuilder = New ReportBuilder();
	
	// Initialize default query text
	QueryText = 
	"SELECT
	|	AccountsReceivableForecast.Hotel AS Hotel,
	|	AccountsReceivableForecast.FolioCurrency AS FolioCurrency,
	|	AccountsReceivableForecast.Folio AS Folio,
	|	CASE
	|		WHEN &qUsePerPaymentSectionBalance
	|			THEN ISNULL(AccountsReceivableForecast.Service.PaymentSection, VALUE(Catalog.PaymentSections.EmptyRef))
	|		ELSE VALUE(Catalog.PaymentSections.EmptyRef)
	|	END AS PaymentSection,
	|	SUM(AccountsReceivableForecast.SalesTurnover) AS ForecastSum
	|INTO ForecastData
	|FROM
	|	AccumulationRegister.AccountsReceivableForecast.Turnovers(
	|			&qBegOfCurrentDate,
	|			&qPeriodTo,
	|			PERIOD,
	|			Hotel IN HIERARCHY (&qHotel)
	|				AND (FolioCurrency = &qFolioCurrency
	|					OR &qFilterByFolioCurrency = FALSE)) AS AccountsReceivableForecast
	|WHERE
	|	AccountsReceivableForecast.SalesTurnover <> 0
	|
	|GROUP BY
	|	AccountsReceivableForecast.Hotel,
	|	AccountsReceivableForecast.FolioCurrency,
	|	AccountsReceivableForecast.Folio,
	|	CASE
	|		WHEN &qUsePerPaymentSectionBalance
	|			THEN ISNULL(AccountsReceivableForecast.Service.PaymentSection, VALUE(Catalog.PaymentSections.EmptyRef))
	|		ELSE VALUE(Catalog.PaymentSections.EmptyRef)
	|	END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Debts.Hotel AS Hotel,
	|	Debts.FolioCurrency AS FolioCurrency,
	|	Debts.FolioRoom AS FolioRoom,
	|	Debts.Folio AS Folio,
	|	Debts.FolioDescription AS FolioDescription,
	|	Debts.FolioCustomer AS FolioCustomer,
	|	Debts.FolioClient AS FolioClient,
	|	Debts.FolioGuestGroup AS FolioGuestGroup,
	|	Debts.FolioDateTimeFrom AS FolioDateTimeFrom,
	|	Debts.FolioDateTimeTo AS FolioDateTimeTo,
	|	Debts.FolioRemarks AS FolioRemarks,
	|	Debts.SumBalance AS SumBalance,
	|	Debts.CustomerSumBalance AS CustomerSumBalance,
	|	Debts.ClientSumBalance AS ClientSumBalance,
	|	Debts.LimitBalance AS LimitBalance,
	|	Debts.PlanBalance AS PlanBalance,
	|	Debts.OverlimitBalance AS OverlimitBalance,
	|	Debts.SumCurrentBalance AS SumCurrentBalance
	|{SELECT
	|	Hotel.*,
	|	FolioCurrency.* AS FolioCurrency,
	|	FolioRoom.* AS FolioRoom,
	|	Folio.* AS Folio,
	|	FolioDescription AS FolioDescription,
	|	FolioCustomer.* AS FolioCustomer,
	|	Debts.FolioContract.* AS FolioContract,
	|	Debts.FolioAgent.* AS FolioAgent,
	|	FolioClient.* AS FolioClient,
	|	FolioDateTimeFrom AS FolioDateTimeFrom,
	|	FolioDateTimeTo AS FolioDateTimeTo,
	|	FolioGuestGroup.* AS FolioGuestGroup,
	|	Debts.FolioParentDoc.* AS FolioParentDoc,
	|	Debts.FolioCompany.* AS FolioCompany,
	|	Debts.FolioRoomRoomType.* AS FolioRoomRoomType,
	|	FolioRemarks AS FolioRemarks,
	|	Debts.FolioAuthor.* AS FolioAuthor,
	|	Debts.FolioPaymentSection.* AS FolioPaymentSection,
	|	Debts.FolioPaymentMethod.* AS FolioPaymentMethod,
	|	Debts.FolioIsMaster AS FolioIsMaster,
	|	Debts.FolioIsClosed AS FolioIsClosed,
	|	Debts.FolioDateTimeFromHour AS FolioDateTimeFromHour,
	|	Debts.FolioDateTimeFromDay AS FolioDateTimeFromDay,
	|	Debts.FolioDateTimeFromWeek AS FolioDateTimeFromWeek,
	|	Debts.FolioDateTimeFromMonth AS FolioDateTimeFromMonth,
	|	Debts.FolioDateTimeFromQuarter AS FolioDateTimeFromQuarter,
	|	Debts.FolioDateTimeFromYear AS FolioDateTimeFromYear,
	|	Debts.IsCustomerBalance AS IsCustomerBalance,
	|	Debts.IsClientBalance AS IsClientBalance,
	|	SumBalance AS SumBalance,
	|	CustomerSumBalance AS CustomerSumBalance,
	|	ClientSumBalance AS ClientSumBalance,
	|	LimitBalance AS LimitBalance,
	|	PlanBalance AS PlanBalance,
	|	OverlimitBalance AS OverlimitBalance,
	|	SumCurrentBalance AS SumCurrentBalance}
	|FROM
	|	(SELECT
	|		FolioBalances.Hotel AS Hotel,
	|		FolioBalances.FolioCurrency AS FolioCurrency,
	|		FolioBalances.Folio AS Folio,
	|		FolioBalances.PaymentSection AS FolioPaymentSection,
	|		FolioBalances.Folio.Room AS FolioRoom,
	|		FolioBalances.Folio.Description AS FolioDescription,
	|		FolioBalances.Folio.Customer AS FolioCustomer,
	|		FolioBalances.Folio.Contract AS FolioContract,
	|		FolioBalances.Folio.Agent AS FolioAgent,
	|		FolioBalances.Folio.Client AS FolioClient,
	|		FolioBalances.Folio.DateTimeFrom AS FolioDateTimeFrom,
	|		FolioBalances.Folio.DateTimeTo AS FolioDateTimeTo,
	|		FolioBalances.Folio.GuestGroup AS FolioGuestGroup,
	|		FolioBalances.Folio.ParentDoc AS FolioParentDoc,
	|		FolioBalances.Folio.Company AS FolioCompany,
	|		FolioBalances.Folio.Room.RoomType AS FolioRoomRoomType,
	|		FolioBalances.Folio.Remarks AS FolioRemarks,
	|		FolioBalances.Folio.Author AS FolioAuthor,
	|		FolioBalances.Folio.PaymentMethod AS FolioPaymentMethod,
	|		FolioBalances.Folio.IsMaster AS FolioIsMaster,
	|		FolioBalances.Folio.IsClosed AS FolioIsClosed,
	|		HOUR(FolioBalances.Folio.DateTimeFrom) AS FolioDateTimeFromHour,
	|		DAY(FolioBalances.Folio.DateTimeFrom) AS FolioDateTimeFromDay,
	|		WEEK(FolioBalances.Folio.DateTimeFrom) AS FolioDateTimeFromWeek,
	|		MONTH(FolioBalances.Folio.DateTimeFrom) AS FolioDateTimeFromMonth,
	|		QUARTER(FolioBalances.Folio.DateTimeFrom) AS FolioDateTimeFromQuarter,
	|		YEAR(FolioBalances.Folio.DateTimeFrom) AS FolioDateTimeFromYear,
	|		CASE
	|			WHEN FolioBalances.Folio.Customer <> &qEmptyCustomer
	|					AND NOT FolioBalances.Folio.Customer.IsIndividual
	|				THEN TRUE
	|			ELSE FALSE
	|		END AS IsCustomerBalance,
	|		CASE
	|			WHEN FolioBalances.Folio.Customer <> &qEmptyCustomer
	|					AND NOT FolioBalances.Folio.Customer.IsIndividual
	|				THEN FALSE
	|			ELSE TRUE
	|		END AS IsClientBalance,
	|		FolioBalances.SumBalance AS SumBalance,
	|		CASE
	|			WHEN FolioBalances.Folio.Customer <> &qEmptyCustomer
	|					AND NOT FolioBalances.Folio.Customer.IsIndividual
	|				THEN FolioBalances.SumBalance
	|			ELSE 0
	|		END AS CustomerSumBalance,
	|		CASE
	|			WHEN FolioBalances.Folio.Customer <> &qEmptyCustomer
	|					AND NOT FolioBalances.Folio.Customer.IsIndividual
	|				THEN 0
	|			ELSE FolioBalances.SumBalance
	|		END AS ClientSumBalance,
	|		FolioBalances.LimitBalance AS LimitBalance,
	|		FolioBalances.SumCurrentBalance AS SumCurrentBalance,
	|		FolioBalances.SumBalance - FolioBalances.SumCurrentBalance + ISNULL(ForecastData.ForecastSum, 0) AS PlanBalance,
	|		FolioBalances.SumBalance - FolioBalances.LimitBalance + ISNULL(ForecastData.ForecastSum, 0) AS OverlimitBalance
	|	FROM
	|		(SELECT
	|			AccountsBalances.Hotel AS Hotel,
	|			AccountsBalances.FolioCurrency AS FolioCurrency,
	|			AccountsBalances.Folio AS Folio,
	|			AccountsBalances.PaymentSection AS PaymentSection,
	|			SUM(AccountsBalances.SumBalance) AS SumBalance,
	|			SUM(AccountsBalances.LimitBalance) AS LimitBalance,
	|			SUM(AccountsBalances.SumCurrentBalance) AS SumCurrentBalance,
	|			SUM(AccountsBalances.LimitCurrentBalance) AS LimitCurrentBalance
	|		FROM
	|			(SELECT
	|				AccountsBalance.Hotel AS Hotel,
	|				AccountsBalance.FolioCurrency AS FolioCurrency,
	|				AccountsBalance.Folio AS Folio,
	|				CASE
	|					WHEN &qUsePerPaymentSectionBalance
	|						THEN AccountsBalance.PaymentSection
	|					ELSE VALUE(Catalog.PaymentSections.EmptyRef)
	|				END AS PaymentSection,
	|				AccountsBalance.SumBalance AS SumBalance,
	|				-AccountsBalance.LimitBalance AS LimitBalance,
	|				0 AS SumCurrentBalance,
	|				0 AS LimitCurrentBalance
	|			FROM
	|				AccumulationRegister.Accounts.Balance(
	|						&qPeriodTo,
	|						Hotel IN HIERARCHY (&qHotel)
	|							AND (FolioCurrency = &qFolioCurrency
	|								OR &qFilterByFolioCurrency = FALSE)) AS AccountsBalance
	|			WHERE
	|				NOT &qServiceIsFilled
	|				AND (AccountsBalance.Folio.Room IN HIERARCHY (&qRoom)
	|						OR NOT &qFilterByRoom)
	|				AND (AccountsBalance.Folio.Room.RoomType IN HIERARCHY (&qRoomType)
	|						OR NOT &qFilterByRoomType)
	|				AND (AccountsBalance.Folio.Customer IN HIERARCHY (&qCustomer)
	|						OR NOT &qFilterByCustomer)
	|				AND (AccountsBalance.Folio.Contract = &qContract
	|						OR NOT &qFilterByContract)
	|				AND (&qAll
	|						OR &qNoDecisionYet
	|							AND AccountsBalance.Folio.DebtDecision = &qEmptyDebtDecision
	|						OR &qThereIsDecision
	|							AND AccountsBalance.Folio.DebtDecision <> &qEmptyDebtDecision
	|							AND (NOT &qDebtDecisionIsFilled
	|								OR &qDebtDecisionIsFilled
	|									AND AccountsBalance.Folio.DebtDecision IN HIERARCHY (&qDebtDecision)))
	|			
	|			UNION ALL
	|			
	|			SELECT
	|				AccountsCurrentBalance.Hotel,
	|				AccountsCurrentBalance.FolioCurrency,
	|				AccountsCurrentBalance.Folio,
	|				CASE
	|					WHEN &qUsePerPaymentSectionBalance
	|						THEN AccountsCurrentBalance.PaymentSection
	|					ELSE VALUE(Catalog.PaymentSections.EmptyRef)
	|				END,
	|				0,
	|				0,
	|				AccountsCurrentBalance.SumBalance,
	|				-AccountsCurrentBalance.LimitBalance
	|			FROM
	|				AccumulationRegister.Accounts.Balance(
	|						&qCurrentDate,
	|						Hotel IN HIERARCHY (&qHotel)
	|							AND (FolioCurrency = &qFolioCurrency
	|								OR &qFilterByFolioCurrency = FALSE)) AS AccountsCurrentBalance
	|			WHERE
	|				NOT &qServiceIsFilled
	|				AND (AccountsCurrentBalance.Folio.Room IN HIERARCHY (&qRoom)
	|						OR NOT &qFilterByRoom)
	|				AND (AccountsCurrentBalance.Folio.Room.RoomType IN HIERARCHY (&qRoomType)
	|						OR NOT &qFilterByRoomType)
	|				AND (AccountsCurrentBalance.Folio.Customer IN HIERARCHY (&qCustomer)
	|						OR NOT &qFilterByCustomer)
	|				AND (AccountsCurrentBalance.Folio.Contract = &qContract
	|						OR NOT &qFilterByContract)
	|				AND (&qAll
	|						OR &qNoDecisionYet
	|							AND AccountsCurrentBalance.Folio.DebtDecision = &qEmptyDebtDecision
	|						OR &qThereIsDecision
	|							AND AccountsCurrentBalance.Folio.DebtDecision <> &qEmptyDebtDecision
	|							AND (NOT &qDebtDecisionIsFilled
	|								OR &qDebtDecisionIsFilled
	|									AND AccountsCurrentBalance.Folio.DebtDecision IN HIERARCHY (&qDebtDecision)))
	|			
	|			UNION ALL
	|			
	|			SELECT
	|				AccountsBalance.Hotel,
	|				AccountsBalance.FolioCurrency,
	|				AccountsBalance.Folio,
	|				CASE
	|					WHEN &qUsePerPaymentSectionBalance
	|						THEN AccountsBalance.PaymentSection
	|					ELSE VALUE(Catalog.PaymentSections.EmptyRef)
	|				END,
	|				AccountsBalance.SumBalance,
	|				-AccountsBalance.LimitBalance,
	|				0,
	|				0
	|			FROM
	|				AccumulationRegister.Accounts.Balance(
	|						&qPeriodTo,
	|						Hotel IN HIERARCHY (&qHotel)
	|							AND (FolioCurrency = &qFolioCurrency
	|								OR &qFilterByFolioCurrency = FALSE)) AS AccountsBalance
	|					INNER JOIN (SELECT
	|						ServiceSalesMovements.Folio AS Folio
	|					FROM
	|						AccumulationRegister.Sales AS ServiceSalesMovements
	|					WHERE
	|						&qServiceIsFilled
	|						AND ServiceSalesMovements.Service IN HIERARCHY(&qService)
	|					
	|					GROUP BY
	|						ServiceSalesMovements.Folio) AS ServiceSales
	|					ON AccountsBalance.Folio = ServiceSales.Folio
	|			WHERE
	|				(AccountsBalance.Folio.Room IN HIERARCHY (&qRoom)
	|						OR NOT &qFilterByRoom)
	|				AND (AccountsBalance.Folio.Room.RoomType IN HIERARCHY (&qRoomType)
	|						OR NOT &qFilterByRoomType)
	|				AND (AccountsBalance.Folio.Customer IN HIERARCHY (&qCustomer)
	|						OR NOT &qFilterByCustomer)
	|				AND (AccountsBalance.Folio.Contract = &qContract
	|						OR NOT &qFilterByContract)
	|				AND (&qAll
	|						OR &qNoDecisionYet
	|							AND AccountsBalance.Folio.DebtDecision = &qEmptyDebtDecision
	|						OR &qThereIsDecision
	|							AND AccountsBalance.Folio.DebtDecision <> &qEmptyDebtDecision
	|							AND (NOT &qDebtDecisionIsFilled
	|								OR &qDebtDecisionIsFilled
	|									AND AccountsBalance.Folio.DebtDecision IN HIERARCHY (&qDebtDecision)))
	|			
	|			UNION ALL
	|			
	|			SELECT
	|				AccountsCurrentBalance.Hotel,
	|				AccountsCurrentBalance.FolioCurrency,
	|				AccountsCurrentBalance.Folio,
	|				CASE
	|					WHEN &qUsePerPaymentSectionBalance
	|						THEN AccountsCurrentBalance.PaymentSection
	|					ELSE VALUE(Catalog.PaymentSections.EmptyRef)
	|				END,
	|				0,
	|				0,
	|				AccountsCurrentBalance.SumBalance,
	|				-AccountsCurrentBalance.LimitBalance
	|			FROM
	|				AccumulationRegister.Accounts.Balance(
	|						&qCurrentDate,
	|						Hotel IN HIERARCHY (&qHotel)
	|							AND (FolioCurrency = &qFolioCurrency
	|								OR &qFilterByFolioCurrency = FALSE)) AS AccountsCurrentBalance
	|					INNER JOIN (SELECT
	|						ServiceSalesMovements.Folio AS Folio
	|					FROM
	|						AccumulationRegister.Sales AS ServiceSalesMovements
	|					WHERE
	|						&qServiceIsFilled
	|						AND ServiceSalesMovements.Service IN HIERARCHY(&qService)
	|					
	|					GROUP BY
	|						ServiceSalesMovements.Folio) AS ServiceSales
	|					ON AccountsCurrentBalance.Folio = ServiceSales.Folio
	|			WHERE
	|				(AccountsCurrentBalance.Folio.Room IN HIERARCHY (&qRoom)
	|						OR NOT &qFilterByRoom)
	|				AND (AccountsCurrentBalance.Folio.Room.RoomType IN HIERARCHY (&qRoomType)
	|						OR NOT &qFilterByRoomType)
	|				AND (AccountsCurrentBalance.Folio.Customer IN HIERARCHY (&qCustomer)
	|						OR NOT &qFilterByCustomer)
	|				AND (AccountsCurrentBalance.Folio.Contract = &qContract
	|						OR NOT &qFilterByContract)
	|				AND (&qAll
	|						OR &qNoDecisionYet
	|							AND AccountsCurrentBalance.Folio.DebtDecision = &qEmptyDebtDecision
	|						OR &qThereIsDecision
	|							AND AccountsCurrentBalance.Folio.DebtDecision <> &qEmptyDebtDecision
	|							AND (NOT &qDebtDecisionIsFilled
	|								OR &qDebtDecisionIsFilled
	|									AND AccountsCurrentBalance.Folio.DebtDecision IN HIERARCHY (&qDebtDecision)))) AS AccountsBalances
	|		
	|		GROUP BY
	|			AccountsBalances.Hotel,
	|			AccountsBalances.FolioCurrency,
	|			AccountsBalances.Folio,
	|			AccountsBalances.PaymentSection) AS FolioBalances
	|			LEFT JOIN ForecastData AS ForecastData
	|			ON FolioBalances.Folio = ForecastData.Folio
	|				AND FolioBalances.Hotel = ForecastData.Hotel
	|				AND FolioBalances.FolioCurrency = ForecastData.FolioCurrency
	|				AND (&qUsePerPaymentSectionBalance
	|						AND FolioBalances.PaymentSection = ForecastData.PaymentSection
	|					OR NOT &qUsePerPaymentSectionBalance)
	|	WHERE
	|		(FolioBalances.SumBalance <> 0
	|				OR CASE
	|					WHEN FolioBalances.Folio.Customer <> &qEmptyCustomer
	|							AND NOT FolioBalances.Folio.Customer.IsIndividual
	|						THEN FolioBalances.SumBalance
	|					ELSE 0
	|				END <> 0
	|				OR CASE
	|					WHEN FolioBalances.Folio.Customer <> &qEmptyCustomer
	|							AND NOT FolioBalances.Folio.Customer.IsIndividual
	|						THEN 0
	|					ELSE FolioBalances.SumBalance
	|				END <> 0
	|				OR FolioBalances.LimitBalance <> 0
	|				OR FolioBalances.SumBalance - FolioBalances.SumCurrentBalance <> 0
	|				OR FolioBalances.SumBalance - FolioBalances.LimitBalance <> 0
	|				OR FolioBalances.SumCurrentBalance <> 0)) AS Debts
	|WHERE
	|	(&qCheckInDateIsFilled
	|				AND BEGINOFPERIOD(Debts.FolioDateTimeFrom, DAY) = &qCheckInDate
	|			OR NOT &qCheckInDateIsFilled)
	|	AND (&qCheckOutDateIsFilled
	|				AND BEGINOFPERIOD(Debts.FolioDateTimeTo, DAY) = &qCheckOutDate
	|			OR NOT &qCheckOutDateIsFilled)
	|{WHERE
	|	Debts.Hotel.* AS Hotel,
	|	Debts.FolioCurrency.* AS FolioCurrency,
	|	Debts.Folio.* AS Folio,
	|	Debts.FolioDescription AS FolioDescription,
	|	Debts.FolioCompany.* AS FolioCompany,
	|	Debts.FolioIsClosed AS FolioIsClosed,
	|	Debts.FolioParentDoc.* AS FolioParentDoc,
	|	Debts.FolioCustomer.* AS FolioCustomer,
	|	Debts.FolioContract.* AS FolioContract,
	|	Debts.FolioAgent.* AS FolioAgent,
	|	Debts.FolioClient.* AS FolioClient,
	|	Debts.FolioGuestGroup.* AS FolioGuestGroup,
	|	Debts.FolioRoom.* AS FolioRoom,
	|	Debts.FolioDateTimeFrom AS FolioDateTimeFrom,
	|	Debts.FolioDateTimeTo AS FolioDateTimeTo,
	|	Debts.FolioRemarks AS FolioRemarks,
	|	Debts.FolioAuthor.* AS FolioAuthor,
	|	Debts.FolioPaymentSection.* AS FolioPaymentSection,
	|	Debts.FolioPaymentMethod.* AS FolioPaymentMethod,
	|	Debts.FolioIsMaster AS FolioIsMaster,
	|	Debts.FolioRoomRoomType.* AS FolioRoomRoomType,
	|	Debts.FolioDateTimeFromHour AS FolioDateTimeFromHour,
	|	Debts.FolioDateTimeFromDay AS FolioDateTimeFromDay,
	|	Debts.FolioDateTimeFromWeek AS FolioDateTimeFromWeek,
	|	Debts.FolioDateTimeFromMonth AS FolioDateTimeFromMonth,
	|	Debts.FolioDateTimeFromQuarter AS FolioDateTimeFromQuarter,
	|	Debts.FolioDateTimeFromYear AS FolioDateTimeFromYear,
	|	Debts.IsCustomerBalance AS IsCustomerBalance,
	|	Debts.IsClientBalance AS IsClientBalance,
	|	Debts.SumBalance AS SumBalance,
	|	Debts.LimitBalance AS LimitBalance,
	|	Debts.PlanBalance AS PlanBalance,
	|	Debts.OverlimitBalance AS OverlimitBalance,
	|	Debts.SumCurrentBalance AS SumCurrentBalance}
	|
	|ORDER BY
	|	Hotel,
	|	FolioCurrency,
	|	FolioRoom,
	|	FolioDateTimeFrom,
	|	FolioClient
	|{ORDER BY
	|	Hotel.*,
	|	Folio.*,
	|	FolioCurrency.* AS FolioCurrency,
	|	FolioDescription,
	|	Debts.FolioCompany.* AS FolioCompany,
	|	Debts.FolioIsClosed,
	|	Debts.FolioParentDoc.*,
	|	FolioCustomer.*,
	|	Debts.FolioContract.*,
	|	Debts.FolioAgent.*,
	|	FolioClient.*,
	|	FolioGuestGroup.*,
	|	FolioRoom.*,
	|	FolioDateTimeFrom,
	|	FolioDateTimeTo,
	|	FolioRemarks,
	|	Debts.FolioAuthor.*,
	|	Debts.FolioPaymentSection.*,
	|	Debts.FolioPaymentMethod.*,
	|	Debts.FolioIsMaster,
	|	Debts.FolioRoomRoomType.*,
	|	Debts.FolioDateTimeFromHour,
	|	Debts.FolioDateTimeFromDay,
	|	Debts.FolioDateTimeFromWeek,
	|	Debts.FolioDateTimeFromMonth,
	|	Debts.FolioDateTimeFromQuarter,
	|	Debts.FolioDateTimeFromYear,
	|	Debts.IsCustomerBalance AS IsCustomerBalance,
	|	Debts.IsClientBalance AS IsClientBalance,
	|	SumBalance AS SumBalance,
	|	LimitBalance AS LimitBalance,
	|	PlanBalance AS PlanBalance,
	|	OverlimitBalance AS OverlimitBalance,
	|	SumCurrentBalance AS SumCurrentBalance}
	|TOTALS
	|	SUM(SumBalance),
	|	SUM(CustomerSumBalance),
	|	SUM(ClientSumBalance),
	|	SUM(LimitBalance),
	|	SUM(PlanBalance),
	|	SUM(OverlimitBalance),
	|	SUM(SumCurrentBalance)
	|BY
	|	Hotel,
	|	FolioCurrency,
	|	FolioRoom,
	|	Folio
	|{TOTALS BY
	|	Hotel.*,
	|	Folio.*,
	|	FolioCurrency.* AS FolioCurrency,
	|	FolioDescription,
	|	Debts.FolioCompany.*,
	|	Debts.FolioIsClosed,
	|	Debts.FolioParentDoc.*,
	|	FolioCustomer.*,
	|	Debts.FolioContract.*,
	|	Debts.FolioAgent.*,
	|	FolioClient.*,
	|	FolioGuestGroup.*,
	|	FolioRoom.*,
	|	FolioDateTimeFrom,
	|	FolioDateTimeTo,
	|	Debts.IsCustomerBalance AS IsCustomerBalance,
	|	Debts.IsClientBalance AS IsClientBalance,
	|	Debts.FolioAuthor.*,
	|	Debts.FolioPaymentSection.*,
	|	Debts.FolioPaymentMethod.*,
	|	Debts.FolioIsMaster,
	|	Debts.FolioDateTimeFromHour,
	|	Debts.FolioDateTimeFromDay,
	|	Debts.FolioDateTimeFromWeek,
	|	Debts.FolioDateTimeFromMonth,
	|	Debts.FolioDateTimeFromQuarter,
	|	Debts.FolioDateTimeFromYear,
	|	Debts.FolioRoomRoomType.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Debtors';RU='Должники';de='Zahlungspflichtige'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

#EndRegion
