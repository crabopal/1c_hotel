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
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If Not ValueIsFilled(PeriodFrom) And Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("en='Report period is not set';ru='Период отчета не установлен';de='Berichtszeitraum nicht festgelegt'") + 
		                     ";" + Chars.LF;
	ElsIf ValueIsFilled(PeriodFrom) And Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период c '; en = 'Period from '; de = 'Periode von '") + 
		                     Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm:ss'") + 
		                     ";" + Chars.LF;
	ElsIf Not ValueIsFilled(PeriodFrom) And ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период по '; en = 'Period to '; de = 'Periode zu '") + 
		                     Format(PeriodTo, "DF='dd.MM.yyyy HH:mm:ss'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom = PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период на '; en = 'Period on '; de = 'Periode '") + 
		                     Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm:ss'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom < PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период '; en = 'Period '; de = 'Periode '") + PeriodPresentation(PeriodFrom, PeriodTo, cmLocalizationCode()) + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("en='Period is wrong!';ru='Неправильно задан период!';de='Der Zeitraum wurde falsch eingetragen!'") + 
		                     ";" + Chars.LF;
	EndIf;
	If ClosedFrom <> '00010101' OR ClosedTo <> '00010101' Then
		If ClosedFrom < ClosedTo Or ClosedTo = '00010101' Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Закрыты в периоде '; en = 'Closed in period '; de = 'Geschlossen im Zeitraum '") + PeriodPresentation(ClosedFrom, ClosedTo, cmLocalizationCode()) + 
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
	ReportBuilder.Parameters.Insert("qClosedFrom", ClosedFrom);
	ReportBuilder.Parameters.Insert("qClosedTo", ClosedTo);
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qFilterByRoomType", ValueIsFilled(RoomType));
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qFilterByRoom", ValueIsFilled(Room));
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
	//Message(ReportBuilder.GetQuery().Text); // For debug purpose
	
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
	"SELECT
	|	Folios.Ref AS Folio
	|INTO Folios
	|FROM
	|	Document.Folio AS Folios
	|WHERE
	|	NOT Folios.DeletionMark
	|	AND (Folios.DateTimeFrom < &qPeriodTo
	|			OR &qPeriodTo = &qEmptyDate
	|			OR Folios.DateTimeFrom = &qEmptyDate)
	|	AND (Folios.DateTimeTo > &qPeriodFrom
	|			OR &qPeriodFrom = &qEmptyDate
	|			OR Folios.DateTimeTo = &qEmptyDate)
	|	AND (Folios.IsClosedDate < &qClosedTo
	|			OR &qClosedTo = &qEmptyDate
	|			OR Folios.IsClosedDate = &qEmptyDate)
	|	AND (Folios.IsClosedDate > &qClosedFrom
	|			OR &qClosedFrom = &qEmptyDate
	|			OR Folios.IsClosedDate = &qEmptyDate)
	|	AND ((&qClosedFrom <> &qEmptyDate
	|				OR &qClosedTo <> &qEmptyDate)
	|				AND Folios.IsClosed
	|			OR &qClosedFrom = &qEmptyDate
	|				AND &qClosedTo = &qEmptyDate)
	|	AND Folios.Hotel IN HIERARCHY(&qHotel)
	|	AND (Folios.FolioCurrency = &qFolioCurrency
	|			OR NOT &qFilterByFolioCurrency)
	|	AND (Folios.Room IN HIERARCHY (&qRoom)
	|			OR NOT &qFilterByRoom)
	|	AND (Folios.Room.RoomType IN HIERARCHY (&qRoomType)
	|			OR NOT &qFilterByRoomType)
	|	AND (Folios.GuestGroup = &qGuestGroup
	|			OR NOT &qFilterByGuestGroup)
	|	AND (Folios.Customer IN HIERARCHY (&qCustomer)
	|			OR NOT &qFilterByCustomer)
	|	AND (Folios.Contract = &qContract
	|			OR NOT &qFilterByContract)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FolioBalances.Folio AS Folio,
	|	CASE
	|		WHEN FolioBalances.Folio.Customer <> &qEmptyCustomer
	|				AND NOT FolioBalances.Folio.Customer.IsIndividual
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS IsCustomerBalance,
	|	CASE
	|		WHEN FolioBalances.Folio.Customer <> &qEmptyCustomer
	|				AND NOT FolioBalances.Folio.Customer.IsIndividual
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS IsClientBalance,
	|	FolioBalances.SumBalance AS SumBalance,
	|	CASE
	|		WHEN FolioBalances.Folio.Customer <> &qEmptyCustomer
	|				AND NOT FolioBalances.Folio.Customer.IsIndividual
	|			THEN FolioBalances.SumBalance
	|		ELSE 0
	|	END AS CustomerSumBalance,
	|	CASE
	|		WHEN FolioBalances.Folio.Customer <> &qEmptyCustomer
	|				AND NOT FolioBalances.Folio.Customer.IsIndividual
	|			THEN 0
	|		ELSE FolioBalances.SumBalance
	|	END AS ClientSumBalance,
	|	FolioBalances.LimitBalance AS LimitBalance
	|INTO FolioBalances
	|FROM
	|	AccumulationRegister.Accounts.Balance(
	|			,
	|			Folio IN
	|				(SELECT
	|					Folios.Folio
	|				FROM
	|					Folios AS Folios)) AS FolioBalances
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FoliosList.Folio.Hotel AS Hotel,
	|	FoliosList.Folio.FolioCurrency AS FolioCurrency,
	|	FoliosList.Folio.PaymentSection AS FolioPaymentSection,
	|	FoliosList.Folio.PaymentMethod AS FolioPaymentMethod,
	|	FoliosList.Folio.Customer AS FolioCustomer,
	|	FoliosList.Folio.Contract AS FolioContract,
	|	FoliosList.Folio.GuestGroup AS FolioGuestGroup,
	|	FoliosList.Folio.Client AS FolioClient,
	|	ISNULL(FolioBalances.IsCustomerBalance, FALSE) AS IsCustomerBalance,
	|	ISNULL(FolioBalances.IsClientBalance, TRUE) AS IsClientBalance,
	|	ISNULL(FolioBalances.SumBalance, 0) AS SumBalance,
	|	ISNULL(FolioBalances.CustomerSumBalance, 0) AS CustomerSumBalance,
	|	ISNULL(FolioBalances.ClientSumBalance, 0) AS ClientSumBalance,
	|	ISNULL(FolioBalances.LimitBalance, 0) AS LimitBalance
	|{SELECT
	|	Hotel.*,
	|	FolioCurrency.* AS FolioCurrency,
	|	FolioPaymentSection.* AS FolioPaymentSection,
	|	FolioPaymentMethod.* AS FolioPaymentMethod,
	|	FolioCustomer.* AS FolioCustomer,
	|	FolioContract.* AS FolioContract,
	|	FolioGuestGroup.* AS FolioGuestGroup,
	|	FoliosList.Folio.Agent.* AS FolioAgent,
	|	FolioClient.* AS FolioClient,
	|	FoliosList.Folio.* AS FolioRef,
	|	FoliosList.Folio.Description AS FolioDescription,
	|	FoliosList.Folio.Remarks AS FolioRemarks,
	|	FoliosList.Folio.DateTimeFrom AS FolioDateTimeFrom,
	|	FoliosList.Folio.DateTimeTo AS FolioDateTimeTo,
	|	FoliosList.Folio.ParentDoc.* AS FolioParentDoc,
	|	FoliosList.Folio.Company.* AS FolioCompany,
	|	FoliosList.Folio.Room.RoomType.* AS FolioRoomRoomType,
	|	FoliosList.Folio.Room.* AS FolioRoom,
	|	FoliosList.Folio.Author.* AS FolioAuthor,
	|	FoliosList.Folio.IsMaster AS FolioIsMaster,
	|	FoliosList.Folio.IsClosed AS FolioIsClosed,
	|	SumBalance AS SumBalance,
	|	CustomerSumBalance AS CustomerSumBalance,
	|	ClientSumBalance AS ClientSumBalance,
	|	LimitBalance AS LimitBalance}
	|FROM
	|	Folios AS FoliosList
	|		LEFT JOIN FolioBalances AS FolioBalances
	|		ON (FolioBalances.Folio = FoliosList.Folio)
	|{WHERE
	|	FoliosList.Folio.Hotel.* AS Hotel,
	|	FoliosList.Folio.FolioCurrency.* AS FolioCurrency,
	|	FoliosList.Folio.PaymentSection.* AS FolioPaymentSection,
	|	FoliosList.Folio.PaymentMethod.* AS FolioPaymentMethod,
	|	FoliosList.Folio.* AS FolioRef,
	|	FoliosList.Folio.Description AS FolioDescription,
	|	FoliosList.Folio.Remarks AS FolioRemarks,
	|	FoliosList.Folio.Company.* AS FolioCompany,
	|	FoliosList.Folio.ParentDoc.* AS FolioParentDoc,
	|	FoliosList.Folio.Customer.* AS FolioCustomer,
	|	FoliosList.Folio.Contract.* AS FolioContract,
	|	FoliosList.Folio.Agent.* AS FolioAgent,
	|	FoliosList.Folio.Client.* AS FolioClient,
	|	FoliosList.Folio.GuestGroup.* AS FolioGuestGroup,
	|	FoliosList.Folio.Room.* AS FolioRoom,
	|	FoliosList.Folio.Room.RoomType.* AS FolioRoomRoomType,
	|	FoliosList.Folio.DateTimeFrom AS FolioDateTimeFrom,
	|	FoliosList.Folio.DateTimeTo AS FolioDateTimeTo,
	|	FoliosList.Folio.Remarks AS FolioRemarks,
	|	FoliosList.Folio.Author.* AS FolioAuthor,
	|	FoliosList.Folio.IsMaster AS FolioIsMaster,
	|	FoliosList.Folio.IsClosed AS FolioIsClosed,
	|	(ISNULL(FolioBalances.IsCustomerBalance, FALSE)) AS IsCustomerBalance,
	|	(ISNULL(FolioBalances.IsClientBalance, TRUE)) AS IsClientBalance,
	|	(ISNULL(FolioBalances.SumBalance, 0)) AS SumBalance,
	|	(ISNULL(FolioBalances.CustomerSumBalance, 0)) AS CustomerSumBalance,
	|	(ISNULL(FolioBalances.ClientSumBalance, 0)) AS ClientSumBalance,
	|	(ISNULL(FolioBalances.LimitBalance, 0)) AS LimitBalance}
	|{ORDER BY
	|	Hotel.*,
	|	FolioCurrency.* AS FolioCurrency,
	|	FolioPaymentSection.* AS FolioPaymentSection,
	|	FolioPaymentMethod.* AS FolioPaymentMethod,
	|	FolioCustomer.* AS FolioCustomer,
	|	FolioContract.* AS FolioContract,
	|	FolioGuestGroup.* AS FolioGuestGroup,
	|	FoliosList.Folio.Agent.* AS FolioAgent,
	|	FolioClient.* AS FolioClient,
	|	FoliosList.Folio.* AS FolioRef,
	|	FoliosList.Folio.Description AS FolioDescription,
	|	FoliosList.Folio.Remarks AS FolioRemarks,
	|	FoliosList.Folio.DateTimeFrom AS FolioDateTimeFrom,
	|	FoliosList.Folio.DateTimeTo AS FolioDateTimeTo,
	|	FoliosList.Folio.ParentDoc.* AS FolioParentDoc,
	|	FoliosList.Folio.Company.* AS FolioCompany,
	|	FoliosList.Folio.Room.RoomType.* AS FolioRoomRoomType,
	|	FoliosList.Folio.Room.* AS FolioRoom,
	|	FoliosList.Folio.Author.* AS FolioAuthor,
	|	FoliosList.Folio.IsMaster AS FolioIsMaster,
	|	FoliosList.Folio.IsClosed AS FolioIsClosed}
	|TOTALS
	|	SUM(SumBalance),
	|	SUM(CustomerSumBalance),
	|	SUM(ClientSumBalance),
	|	SUM(LimitBalance)
	|BY
	|	Hotel,
	|	FolioCurrency
	|{TOTALS BY
	|	Hotel.*,
	|	FolioCurrency.* AS FolioCurrency,
	|	FolioPaymentSection.* AS FolioPaymentSection,
	|	FolioPaymentMethod.* AS FolioPaymentMethod,
	|	FolioCustomer.* AS FolioCustomer,
	|	FolioContract.* AS FolioContract,
	|	FolioGuestGroup.* AS FolioGuestGroup,
	|	FoliosList.Folio.Agent.* AS FolioAgent,
	|	FolioClient.* AS FolioClient,
	|	FoliosList.Folio.* AS FolioRef,
	|	FoliosList.Folio.Description AS FolioDescription,
	|	FoliosList.Folio.Remarks AS FolioRemarks,
	|	FoliosList.Folio.DateTimeFrom AS FolioDateTimeFrom,
	|	FoliosList.Folio.DateTimeTo AS FolioDateTimeTo,
	|	FoliosList.Folio.ParentDoc.* AS FolioParentDoc,
	|	FoliosList.Folio.Company.* AS FolioCompany,
	|	FoliosList.Folio.Room.RoomType.* AS FolioRoomRoomType,
	|	FoliosList.Folio.Room.* AS FolioRoom,
	|	FoliosList.Folio.Author.* AS FolioAuthor,
	|	FoliosList.Folio.IsMaster AS FolioIsMaster,
	|	FoliosList.Folio.IsClosed AS FolioIsClosed}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Folios';RU='Лицевые счета';de='Personenkonten'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
