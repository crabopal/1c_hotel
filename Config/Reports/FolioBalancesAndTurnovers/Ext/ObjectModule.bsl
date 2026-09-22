
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
		                     TrimAll(GuestGroup.Code) + " " + TrimAll(GuestGroup.Description) + 
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
	If ValueIsFilled(FolioCurrency) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Валюта фолио '; en = 'Folio currency '; de = 'Folio Währung '") + 
							 TrimAll(FolioCurrency.Description) + 
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
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", ?(ValueIsFilled(PeriodTo), PeriodTo, '39991231235959'));
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qFilterByRoomType", ValueIsFilled(RoomType));
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qFilterByCustomer", ValueIsFilled(Customer));
	ReportBuilder.Parameters.Insert("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	ReportBuilder.Parameters.Insert("qContract", Contract);
	ReportBuilder.Parameters.Insert("qFilterByContract", ValueIsFilled(Contract));
	ReportBuilder.Parameters.Insert("qGuestGroup", GuestGroup);
	ReportBuilder.Parameters.Insert("qFilterByGuestGroup", ValueIsFilled(GuestGroup));
	ReportBuilder.Parameters.Insert("qFolioCurrency", FolioCurrency);
	ReportBuilder.Parameters.Insert("qFilterByFolioCurrency", ValueIsFilled(FolioCurrency));

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
	|	FolioBalancesAndTurnovers.Hotel AS Hotel,
	|	FolioBalancesAndTurnovers.FolioCurrency AS FolioCurrency,
	|	FolioBalancesAndTurnovers.PaymentSection AS PaymentSection,
	|	FolioBalancesAndTurnovers.Folio.PaymentSection AS FolioPaymentSection,
	|	FolioBalancesAndTurnovers.Folio.PaymentMethod AS FolioPaymentMethod,
	|	FolioBalancesAndTurnovers.Folio.Customer AS FolioCustomer,
	|	FolioBalancesAndTurnovers.Folio.Contract AS FolioContract,
	|	FolioBalancesAndTurnovers.Folio.GuestGroup AS FolioGuestGroup,
	|	FolioBalancesAndTurnovers.Folio.Client AS FolioClient,
	|	CASE
	|		WHEN FolioBalancesAndTurnovers.Folio.Customer <> &qEmptyCustomer
	|				AND NOT FolioBalancesAndTurnovers.Folio.Customer.IsIndividual
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS IsCustomerBalance,
	|	CASE
	|		WHEN FolioBalancesAndTurnovers.Folio.Customer <> &qEmptyCustomer
	|				AND NOT FolioBalancesAndTurnovers.Folio.Customer.IsIndividual
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS IsClientBalance,
	|	FolioBalancesAndTurnovers.SumOpeningBalance AS SumOpeningBalance,
	|	CASE
	|		WHEN FolioBalancesAndTurnovers.Folio.Customer <> &qEmptyCustomer
	|				AND NOT FolioBalancesAndTurnovers.Folio.Customer.IsIndividual
	|			THEN FolioBalancesAndTurnovers.SumOpeningBalance
	|		ELSE 0
	|	END AS CustomerSumOpeningBalance,
	|	CASE
	|		WHEN FolioBalancesAndTurnovers.Folio.Customer <> &qEmptyCustomer
	|				AND NOT FolioBalancesAndTurnovers.Folio.Customer.IsIndividual
	|			THEN 0
	|		ELSE FolioBalancesAndTurnovers.SumOpeningBalance
	|	END AS ClientSumOpeningBalance,
	|	FolioBalancesAndTurnovers.SumClosingBalance AS SumClosingBalance,
	|	CASE
	|		WHEN FolioBalancesAndTurnovers.Folio.Customer <> &qEmptyCustomer
	|				AND NOT FolioBalancesAndTurnovers.Folio.Customer.IsIndividual
	|			THEN FolioBalancesAndTurnovers.SumClosingBalance
	|		ELSE 0
	|	END AS CustomerSumClosingBalance,
	|	CASE
	|		WHEN FolioBalancesAndTurnovers.Folio.Customer <> &qEmptyCustomer
	|				AND NOT FolioBalancesAndTurnovers.Folio.Customer.IsIndividual
	|			THEN 0
	|		ELSE FolioBalancesAndTurnovers.SumClosingBalance
	|	END AS ClientSumClosingBalance,
	|	FolioBalancesAndTurnovers.SumReceipt AS SumReceipt,
	|	CASE
	|		WHEN FolioBalancesAndTurnovers.Folio.Customer <> &qEmptyCustomer
	|				AND NOT FolioBalancesAndTurnovers.Folio.Customer.IsIndividual
	|			THEN FolioBalancesAndTurnovers.SumReceipt
	|		ELSE 0
	|	END AS CustomerSumReceipt,
	|	CASE
	|		WHEN FolioBalancesAndTurnovers.Folio.Customer <> &qEmptyCustomer
	|				AND NOT FolioBalancesAndTurnovers.Folio.Customer.IsIndividual
	|			THEN 0
	|		ELSE FolioBalancesAndTurnovers.SumReceipt
	|	END AS ClientSumReceipt,
	|	FolioBalancesAndTurnovers.SumExpense AS SumExpense,
	|	CASE
	|		WHEN FolioBalancesAndTurnovers.Folio.Customer <> &qEmptyCustomer
	|				AND NOT FolioBalancesAndTurnovers.Folio.Customer.IsIndividual
	|			THEN FolioBalancesAndTurnovers.SumExpense
	|		ELSE 0
	|	END AS CustomerSumExpense,
	|	CASE
	|		WHEN FolioBalancesAndTurnovers.Folio.Customer <> &qEmptyCustomer
	|				AND NOT FolioBalancesAndTurnovers.Folio.Customer.IsIndividual
	|			THEN 0
	|		ELSE FolioBalancesAndTurnovers.SumExpense
	|	END AS ClientSumExpense,
	|	FolioBalancesAndTurnovers.LimitOpeningBalance AS LimitOpeningBalance,
	|	FolioBalancesAndTurnovers.LimitExpense AS LimitExpense,
	|	FolioBalancesAndTurnovers.LimitReceipt AS LimitReceipt,
	|	FolioBalancesAndTurnovers.LimitClosingBalance AS LimitClosingBalance
	|{SELECT
	|	Hotel.*,
	|	FolioCurrency.* AS FolioCurrency,
	|	PaymentSection.* AS PaymentSection,
	|	FolioPaymentSection.* AS FolioPaymentSection,
	|	FolioPaymentMethod.* AS FolioPaymentMethod,
	|	FolioCustomer.* AS FolioCustomer,
	|	FolioContract.* AS FolioContract,
	|	FolioGuestGroup.* AS FolioGuestGroup,
	|	FolioBalancesAndTurnovers.Folio.Agent.* AS FolioAgent,
	|	FolioClient.* AS FolioClient,
	|	FolioBalancesAndTurnovers.Folio.* AS FolioRef,
	|	FolioBalancesAndTurnovers.Folio.Description AS FolioDescription,
	|	FolioBalancesAndTurnovers.Folio.Remarks AS FolioRemarks,
	|	FolioBalancesAndTurnovers.Folio.DateTimeFrom AS FolioDateTimeFrom,
	|	FolioBalancesAndTurnovers.Folio.DateTimeTo AS FolioDateTimeTo,
	|	FolioBalancesAndTurnovers.Folio.ParentDoc.* AS FolioParentDoc,
	|	FolioBalancesAndTurnovers.Folio.Company.* AS FolioCompany,
	|	FolioBalancesAndTurnovers.Folio.Room.RoomType.* AS FolioRoomRoomType,
	|	FolioBalancesAndTurnovers.Folio.Room.* AS FolioRoom,
	|	FolioBalancesAndTurnovers.Folio.Author.* AS FolioAuthor,
	|	FolioBalancesAndTurnovers.Folio.IsMaster AS FolioIsMaster,
	|	FolioBalancesAndTurnovers.Folio.IsClosed AS FolioIsClosed,
	|	SumOpeningBalance AS SumOpeningBalance,
	|	CustomerSumOpeningBalance AS CustomerSumOpeningBalance,
	|	ClientSumOpeningBalance AS ClientSumOpeningBalance,
	|	SumReceipt AS SumReceipt,
	|	CustomerSumReceipt AS CustomerSumReceipt,
	|	ClientSumReceipt AS ClientSumReceipt,
	|	SumExpense AS SumExpense,
	|	CustomerSumExpense AS CustomerSumExpense,
	|	ClientSumExpense AS ClientSumExpense,
	|	SumClosingBalance AS SumClosingBalance,
	|	CustomerSumClosingBalance AS CustomerSumClosingBalance,
	|	ClientSumClosingBalance AS ClientSumClosingBalance,
	|	LimitOpeningBalance AS LimitOpeningBalance,
	|	LimitReceipt AS LimitReceipt,
	|	LimitExpense AS LimitExpense,
	|	LimitClosingBalance AS LimitClosingBalance}
	|FROM
	|	AccumulationRegister.Accounts.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			RegisterRecordsAndPeriodBoundaries,
	|			Hotel IN HIERARCHY (&qHotel)
	|				AND (FolioCurrency = &qFolioCurrency
	|					OR NOT &qFilterByFolioCurrency)
	|				AND (Folio.Room.RoomType IN HIERARCHY (&qRoomType)
	|					OR NOT &qFilterByRoomType)
	|				AND (Folio.GuestGroup = &qGuestGroup
	|					OR NOT &qFilterByGuestGroup)
	|				AND (Folio.Customer IN HIERARCHY (&qCustomer)
	|					OR NOT &qFilterByCustomer)
	|				AND (Folio.Contract = &qContract
	|					OR NOT &qFilterByContract)) AS FolioBalancesAndTurnovers
	|{WHERE
	|	FolioBalancesAndTurnovers.Hotel.* AS Hotel,
	|	FolioBalancesAndTurnovers.FolioCurrency.* AS FolioCurrency,
	|	FolioBalancesAndTurnovers.PaymentSection.* AS PaymentSection,
	|	FolioBalancesAndTurnovers.Folio.PaymentSection.* AS FolioPaymentSection,
	|	FolioBalancesAndTurnovers.Folio.PaymentMethod.* AS FolioPaymentMethod,
	|	FolioBalancesAndTurnovers.Folio.* AS FolioRef,
	|	FolioBalancesAndTurnovers.Folio.Description AS FolioDescription,
	|	FolioBalancesAndTurnovers.Folio.Remarks AS FolioRemarks,
	|	FolioBalancesAndTurnovers.Folio.Company.* AS FolioCompany,
	|	FolioBalancesAndTurnovers.Folio.ParentDoc.* AS FolioParentDoc,
	|	FolioBalancesAndTurnovers.Folio.Customer.* AS FolioCustomer,
	|	FolioBalancesAndTurnovers.Folio.Contract.* AS FolioContract,
	|	FolioBalancesAndTurnovers.Folio.Agent.* AS FolioAgent,
	|	FolioBalancesAndTurnovers.Folio.Client.* AS FolioClient,
	|	FolioBalancesAndTurnovers.Folio.GuestGroup.* AS FolioGuestGroup,
	|	FolioBalancesAndTurnovers.Folio.Room.* AS FolioRoom,
	|	FolioBalancesAndTurnovers.Folio.Room.RoomType.* AS FolioRoomRoomType,
	|	FolioBalancesAndTurnovers.Folio.DateTimeFrom AS FolioDateTimeFrom,
	|	FolioBalancesAndTurnovers.Folio.DateTimeTo AS FolioDateTimeTo,
	|	FolioBalancesAndTurnovers.Folio.Remarks AS FolioRemarks,
	|	FolioBalancesAndTurnovers.Folio.Author.* AS FolioAuthor,
	|	FolioBalancesAndTurnovers.Folio.IsMaster AS FolioIsMaster,
	|	FolioBalancesAndTurnovers.Folio.IsClosed AS FolioIsClosed,
	|	(CASE
	|			WHEN FolioBalancesAndTurnovers.Folio.Customer <> &qEmptyCustomer
	|					AND NOT FolioBalancesAndTurnovers.Folio.Customer.IsIndividual
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS IsCustomerBalance,
	|	(CASE
	|			WHEN FolioBalancesAndTurnovers.Folio.Customer <> &qEmptyCustomer
	|					AND NOT FolioBalancesAndTurnovers.Folio.Customer.IsIndividual
	|				THEN FALSE
	|			ELSE TRUE
	|		END) AS IsClientBalance,
	|	FolioBalancesAndTurnovers.SumOpeningBalance AS SumOpeningBalance,
	|	(CASE
	|			WHEN FolioBalancesAndTurnovers.Folio.Customer <> &qEmptyCustomer
	|					AND NOT FolioBalancesAndTurnovers.Folio.Customer.IsIndividual
	|				THEN FolioBalancesAndTurnovers.SumOpeningBalance
	|			ELSE 0
	|		END) AS CustomerSumOpeningBalance,
	|	(CASE
	|			WHEN FolioBalancesAndTurnovers.Folio.Customer <> &qEmptyCustomer
	|					AND NOT FolioBalancesAndTurnovers.Folio.Customer.IsIndividual
	|				THEN 0
	|			ELSE FolioBalancesAndTurnovers.SumOpeningBalance
	|		END) AS ClientSumOpeningBalance,
	|	FolioBalancesAndTurnovers.SumClosingBalance AS SumClosingBalance,
	|	(CASE
	|			WHEN FolioBalancesAndTurnovers.Folio.Customer <> &qEmptyCustomer
	|					AND NOT FolioBalancesAndTurnovers.Folio.Customer.IsIndividual
	|				THEN FolioBalancesAndTurnovers.SumClosingBalance
	|			ELSE 0
	|		END) AS CustomerSumClosingBalance,
	|	(CASE
	|			WHEN FolioBalancesAndTurnovers.Folio.Customer <> &qEmptyCustomer
	|					AND NOT FolioBalancesAndTurnovers.Folio.Customer.IsIndividual
	|				THEN 0
	|			ELSE FolioBalancesAndTurnovers.SumClosingBalance
	|		END) AS ClientSumClosingBalance,
	|	FolioBalancesAndTurnovers.SumReceipt AS SumReceipt,
	|	(CASE
	|			WHEN FolioBalancesAndTurnovers.Folio.Customer <> &qEmptyCustomer
	|					AND NOT FolioBalancesAndTurnovers.Folio.Customer.IsIndividual
	|				THEN FolioBalancesAndTurnovers.SumReceipt
	|			ELSE 0
	|		END) AS CustomerSumReceipt,
	|	(CASE
	|			WHEN FolioBalancesAndTurnovers.Folio.Customer <> &qEmptyCustomer
	|					AND NOT FolioBalancesAndTurnovers.Folio.Customer.IsIndividual
	|				THEN 0
	|			ELSE FolioBalancesAndTurnovers.SumReceipt
	|		END) AS ClientSumReceipt,
	|	FolioBalancesAndTurnovers.SumExpense AS SumExpense,
	|	(CASE
	|			WHEN FolioBalancesAndTurnovers.Folio.Customer <> &qEmptyCustomer
	|					AND NOT FolioBalancesAndTurnovers.Folio.Customer.IsIndividual
	|				THEN FolioBalancesAndTurnovers.SumExpense
	|			ELSE 0
	|		END) AS CustomerSumExpense,
	|	(CASE
	|			WHEN FolioBalancesAndTurnovers.Folio.Customer <> &qEmptyCustomer
	|					AND NOT FolioBalancesAndTurnovers.Folio.Customer.IsIndividual
	|				THEN 0
	|			ELSE FolioBalancesAndTurnovers.SumExpense
	|		END) AS ClientSumExpense,
	|	FolioBalancesAndTurnovers.LimitOpeningBalance AS LimitOpeningBalance,
	|	FolioBalancesAndTurnovers.LimitExpense AS LimitExpense,
	|	FolioBalancesAndTurnovers.LimitReceipt AS LimitReceipt,
	|	FolioBalancesAndTurnovers.LimitClosingBalance AS LimitClosingBalance}
	|
	|ORDER BY
	|	Hotel,
	|	FolioCurrency,
	|	FolioPaymentSection
	|{ORDER BY
	|	Hotel.*,
	|	FolioCurrency.* AS FolioCurrency,
	|	PaymentSection.* AS PaymentSection,
	|	FolioPaymentSection.* AS FolioPaymentSection,
	|	FolioPaymentMethod.* AS FolioPaymentMethod,
	|	FolioCustomer.* AS FolioCustomer,
	|	FolioContract.* AS FolioContract,
	|	FolioGuestGroup.* AS FolioGuestGroup,
	|	FolioBalancesAndTurnovers.Folio.Agent.* AS FolioAgent,
	|	FolioClient.* AS FolioClient,
	|	FolioBalancesAndTurnovers.Folio.* AS FolioRef,
	|	FolioBalancesAndTurnovers.Folio.Description AS FolioDescription,
	|	FolioBalancesAndTurnovers.Folio.Remarks AS FolioRemarks,
	|	FolioBalancesAndTurnovers.Folio.DateTimeFrom AS FolioDateTimeFrom,
	|	FolioBalancesAndTurnovers.Folio.DateTimeTo AS FolioDateTimeTo,
	|	FolioBalancesAndTurnovers.Folio.ParentDoc.* AS FolioParentDoc,
	|	FolioBalancesAndTurnovers.Folio.Company.* AS FolioCompany,
	|	FolioBalancesAndTurnovers.Folio.Room.RoomType.* AS FolioRoomRoomType,
	|	FolioBalancesAndTurnovers.Folio.Room.* AS FolioRoom,
	|	FolioBalancesAndTurnovers.Folio.Author.* AS FolioAuthor,
	|	FolioBalancesAndTurnovers.Folio.IsMaster AS FolioIsMaster,
	|	FolioBalancesAndTurnovers.Folio.IsClosed AS FolioIsClosed,
	|	SumOpeningBalance AS SumOpeningBalance,
	|	CustomerSumOpeningBalance AS CustomerSumOpeningBalance,
	|	ClientSumOpeningBalance AS ClientSumOpeningBalance,
	|	SumReceipt AS SumReceipt,
	|	CustomerSumReceipt AS CustomerSumReceipt,
	|	ClientSumReceipt AS ClientSumReceipt,
	|	SumExpense AS SumExpense,
	|	CustomerSumExpense AS CustomerSumExpense,
	|	ClientSumExpense AS ClientSumExpense,
	|	SumClosingBalance AS SumClosingBalance,
	|	CustomerSumClosingBalance AS CustomerSumClosingBalance,
	|	ClientSumClosingBalance AS ClientSumClosingBalance,
	|	LimitOpeningBalance AS LimitOpeningBalance,
	|	LimitReceipt AS LimitReceipt,
	|	LimitExpense AS LimitExpense,
	|	LimitClosingBalance AS LimitClosingBalance}
	|TOTALS
	|	SUM(SumOpeningBalance),
	|	SUM(CustomerSumOpeningBalance),
	|	SUM(ClientSumOpeningBalance),
	|	SUM(SumClosingBalance),
	|	SUM(CustomerSumClosingBalance),
	|	SUM(ClientSumClosingBalance),
	|	SUM(SumReceipt),
	|	SUM(CustomerSumReceipt),
	|	SUM(ClientSumReceipt),
	|	SUM(SumExpense),
	|	SUM(CustomerSumExpense),
	|	SUM(ClientSumExpense),
	|	SUM(LimitOpeningBalance),
	|	SUM(LimitExpense),
	|	SUM(LimitReceipt),
	|	SUM(LimitClosingBalance)
	|BY
	|	OVERALL,
	|	Hotel,
	|	FolioCurrency,
	|	FolioPaymentSection
	|{TOTALS BY
	|	Hotel.*,
	|	FolioCurrency.* AS FolioCurrency,
	|	PaymentSection.* AS PaymentSection,
	|	FolioPaymentSection.* AS FolioPaymentSection,
	|	FolioPaymentMethod.* AS FolioPaymentMethod,
	|	FolioCustomer.* AS FolioCustomer,
	|	FolioContract.* AS FolioContract,
	|	FolioGuestGroup.* AS FolioGuestGroup,
	|	FolioBalancesAndTurnovers.Folio.Agent.* AS FolioAgent,
	|	FolioClient.* AS FolioClient,
	|	FolioBalancesAndTurnovers.Folio.* AS FolioRef,
	|	FolioBalancesAndTurnovers.Folio.ParentDoc.* AS FolioParentDoc,
	|	FolioBalancesAndTurnovers.Folio.Company.* AS FolioCompany,
	|	FolioBalancesAndTurnovers.Folio.Room.RoomType.* AS FolioRoomRoomType,
	|	FolioBalancesAndTurnovers.Folio.Room.* AS FolioRoom,
	|	FolioBalancesAndTurnovers.Folio.Author.* AS FolioAuthor,
	|	FolioBalancesAndTurnovers.Folio.IsMaster AS FolioIsMaster,
	|	FolioBalancesAndTurnovers.Folio.IsClosed AS FolioIsClosed}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Folio balances and turnovers';RU='Остатки и обороты по лицевым счетам';de='Restbestände und Umsätze nach Personenkonten'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

#EndRegion
