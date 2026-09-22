
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
	If Not ValueIsFilled(PeriodFrom) Then
		PeriodFrom = BegOfDay(CurrentSessionDate()); // For today
		PeriodTo = EndOfDay(PeriodFrom);
	EndIf;
	If Not ValueIsFilled(PeriodCheckType) Then
		PeriodCheckType = Enums.PeriodCheckTypes.Intersection;
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
	If Not ValueIsFilled(PeriodCheckType) Then
		vParamPresentation = vParamPresentation + NStr("en='Report period check type is not set';ru='Вид проверки периода отчета не установлен';de='Art der Kontrolle des Berichtszeitraums nicht festgelegt'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodCheckType = Enums.PeriodCheckTypes.Intersection Then
		vParamPresentation = vParamPresentation + NStr("en='Reservations for the period selected';ru='Отбор брони в выбранном периоде';de='Reservierungsauswahl im gewählten Zeitraum'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodCheckType = Enums.PeriodCheckTypes.StartsInPeriod Then
		vParamPresentation = vParamPresentation + NStr("en='Reservations with time from in the period selected';ru='Отбор брони с временем начала в выбранном периоде';de='Auswahl der Buchung mit Beginnzeit im gewählten Zeitraum'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodCheckType = Enums.PeriodCheckTypes.EndsInPeriod Then
		vParamPresentation = vParamPresentation + NStr("en='Reservations with time to in the period selected';ru='Отбор брони с временем окончания в выбранном периоде';de='Auswahl der Buchung mit Endzeit im gewählten Zeitraum'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodCheckType = Enums.PeriodCheckTypes.StartsOrEndsInPeriod Then
		vParamPresentation = vParamPresentation + NStr("en='Reservations with time from or time to in the period selected';ru='Отбор брони с временем начала или временем окончания в выбранном периоде';de='Auswahl der Buchung mit Beginn- und Endzeit im gewählten Zeitraum'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodCheckType = Enums.PeriodCheckTypes.DocDateInPeriod Then
		vParamPresentation = vParamPresentation + NStr("en='Reservations with creation date in the period selected';ru='Отбор брони с датой создания в выбранном периоде';de='Auswahl der Buchung mit Erstellungsdatum im gewählten Zeitraum'") + 
		                     ";" + Chars.LF;
	Endif;		
	If ValueIsFilled(Resource) Then
		vParamPresentation = vParamPresentation + NStr("en='Resource ';ru='Ресурс ';de='Ressource '") + 
							 TrimAll(Resource.Description) + 
							 ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(ResourceType) Then
		If Not ResourceType.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Resource type ';ru='Тип ресурса ';de='Ressourcentyp '") + 
			                     TrimAll(ResourceType.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Resource types folder ';ru='Группа типов ресурсов ';de='Ressourcentypengruppe '") + 
			                     TrimAll(ResourceType.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(GuestGroup) Then
		If Not GuestGroup.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Group ';ru='Группа ';de='Gruppe '") + 
			                     TrimAll(GuestGroup.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Папка групп '; en = 'Groups folder '; de = 'Gruppengruppe '") + 
			                     TrimAll(GuestGroup.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ShowActiveOnly Then
		vParamPresentation = vParamPresentation + NStr("en='Active reservations only';ru='Только действующая бронь';de='Nur gültige Reservierung'") + 
							 ";" + Chars.LF;
	EndIf;
	If ShowInactiveOnly Then
		vParamPresentation = vParamPresentation + NStr("en='Inactive reservations only';ru='Только недействующая бронь';de='Nur ungültige Reservierung'") + 
							 ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If Not Hotel.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Hotel ';ru='Гостиница ';de='Hotel '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц ';de='Hotelsgruppe '") + 
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
	ReportBuilder.Parameters.Insert("qGuestGroup", GuestGroup);
	ReportBuilder.Parameters.Insert("qGuestGroupIsEmpty", Not ValueIsFilled(GuestGroup));
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qBegOfTime", '00010101');
	ReportBuilder.Parameters.Insert("qEndOfTime", '39991231235959');
	ReportBuilder.Parameters.Insert("qBegOfCurrentDate", BegOfDay(CurrentSessionDate()));
	ReportBuilder.Parameters.Insert("qPeriodCheckType", PeriodCheckType);
	ReportBuilder.Parameters.Insert("qIntersection", Enums.PeriodCheckTypes.Intersection);
	ReportBuilder.Parameters.Insert("qCheckIn", Enums.PeriodCheckTypes.StartsInPeriod);
	ReportBuilder.Parameters.Insert("qCheckOut", Enums.PeriodCheckTypes.EndsInPeriod);
	ReportBuilder.Parameters.Insert("qCheckInOrCheckOut", Enums.PeriodCheckTypes.StartsOrEndsInPeriod);
	ReportBuilder.Parameters.Insert("qDocDateInPeriod", Enums.PeriodCheckTypes.DocDateInPeriod);
	ReportBuilder.Parameters.Insert("qResource", Resource);
	ReportBuilder.Parameters.Insert("qResourceIsEmpty", Not ValueIsFilled(Resource));
	ReportBuilder.Parameters.Insert("qResourceType", ResourceType);
	ReportBuilder.Parameters.Insert("qResourceTypeIsEmpty", Not ValueIsFilled(ResourceType));
	ReportBuilder.Parameters.Insert("qRecordType", AccumulationRecordType.Expense);
	ReportBuilder.Parameters.Insert("qShowActiveOnly", ShowActiveOnly);
	ReportBuilder.Parameters.Insert("qShowInactiveOnly", ShowInactiveOnly);
	ReportBuilder.Parameters.Insert("qShowInvoicesAndDeposits", ShowInvoicesAndDeposits);

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
	"SELECT
	|	Reservations.Hotel AS Hotel,
	|	Reservations.Customer AS Customer,
	|	Reservations.Customer.Author AS CustomerAuthor,
	|	Reservations.Contract AS Contract,
	|	Reservations.GuestGroup AS GuestGroup,
	|	Reservations.GuestGroup.Description AS GuestGroupDescription,
	|	Reservations.GuestGroup.Author AS GuestGroupAuthor,
	|	Reservations.ResourceReservationStatus AS ResourceReservationStatus,
	|	Reservations.Ref.Client AS Client,
	|	Reservations.DateTimeFrom AS DateTimeFrom,
	|	Reservations.Duration AS Duration,
	|	Reservations.DateTimeTo AS DateTimeTo,
	|	Reservations.EventActivity AS EventActivity,
	|	Reservations.ResourceType AS ResourceType,
	|	Reservations.Resource AS Resource,
	|	Reservations.TableConfiguration AS TableConfiguration,
	|	Reservations.NumberOfPersons AS NumberOfPersons,
	|	Reservations.NumberOfPersonsAsResource AS NumberOfPersonsAsResource,
	|	Reservations.ActivityRemarks AS ActivityRemarks,
	|	Reservations.Service AS Service,
	|	Reservations.ServiceRemarks AS ServiceRemarks,
	|	Reservations.Price AS Price,
	|	Reservations.Quantity AS Quantity,
	|	Reservations.Sum AS Sum,
	|	Reservations.DiscountSum AS DiscountSum,
	|	Reservations.SumWithoutDiscount AS SumWithoutDiscount,
	|	Reservations.VATRate AS VATRate,
	|	Reservations.VATSum AS VATSum,
	|	Reservations.HoursRented AS HoursRented,
	|	Reservations.Ref AS Recorder
	|{SELECT
	|	Hotel.* AS Hotel,
	|	Reservations.Ref.Agent.* AS Agent,
	|	Reservations.Ref.AgentCommission AS AgentCommission,
	|	Reservations.Ref.AgentCommissionType AS AgentCommissionType,
	|	Reservations.Ref.CustomerType.* AS CustomerType,
	|	Reservations.Ref.SourceOfBusiness.* AS SourceOfBusiness,
	|	Reservations.Ref.MarketingCode.* AS MarketingCode,
	|	Recorder.* AS Recorder,
	|	Customer.* AS Customer,
	|	CustomerAuthor.* AS CustomerAuthor,
	|	Contract.* AS Contract,
	|	GuestGroup.* AS GuestGroup,
	|	GuestGroupDescription AS GuestGroupDescription,
	|	GuestGroupAuthor.* AS GuestGroupAuthor,
	|	ResourceReservationStatus.* AS ResourceReservationStatus,
	|	Reservations.Ref.ContactPerson AS ContactPerson,
	|	Reservations.Ref.ResourceTariff.* AS ResourceTariff,
	|	Reservations.Ref.ClientType.* AS ClientType,
	|	Client.* AS Client,
	|	DateTimeFrom AS DateTimeFrom,
	|	Duration AS Duration,
	|	DateTimeTo AS DateTimeTo,
	|	EventActivity.* AS EventActivity,
	|	ResourceType.* AS ResourceType,
	|	Resource.* AS Resource,
	|	TableConfiguration.* AS TableConfiguration,
	|	NumberOfPersons AS NumberOfPersons,
	|	NumberOfPersonsAsResource AS NumberOfPersonsAsResource,
	|	ActivityRemarks AS ActivityRemarks,
	|	Service.* AS Service,
	|	ServiceRemarks AS ServiceRemarks,
	|	Price AS Price,
	|	Quantity AS Quantity,
	|	Sum AS Sum,
	|	DiscountSum AS DiscountSum,
	|	SumWithoutDiscount AS SumWithoutDiscount,
	|	VATRate.* AS VATRate,
	|	VATSum AS VATSum,
	|	HoursRented AS HoursRented,
	|	(BEGINOFPERIOD(Reservations.DateTimeFrom, DAY)) AS FromDate,
	|	(HOUR(Reservations.DateTimeFrom)) AS FromHour,
	|	(DAY(Reservations.DateTimeFrom)) AS FromDay,
	|	(WEEK(Reservations.DateTimeFrom)) AS FromWeek,
	|	(MONTH(Reservations.DateTimeFrom)) AS FromMonth,
	|	(QUARTER(Reservations.DateTimeFrom)) AS FromQuarter,
	|	(YEAR(Reservations.DateTimeFrom)) AS FromYear,
	|	Reservations.Ref.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	Reservations.Ref.PricePresentation AS PricePresentation,
	|	Reservations.Ref.DiscountCard.* AS DiscountCard,
	|	Reservations.Ref.DiscountType.* AS DiscountType,
	|	Reservations.Ref.Discount AS Discount,
	|	Reservations.Ref.ParentDoc.* AS ParentDoc,
	|	Reservations.Ref.Company.* AS Company,
	|	Reservations.Ref.Remarks AS Remarks,
	|	Reservations.Ref.Car AS Car,
	|	Reservations.Author.* AS Author,
	|	Reservations.Account.* AS Account,
	|	Reservations.AccountCurrency.* AS AccountCurrency,
	|	Reservations.DaysBeforeDateFrom AS DaysBeforeDateFrom,
	|	Reservations.InvoiceAge AS InvoiceAge,
	|	Reservations.SumInvoice AS SumInvoice,
	|	Reservations.SumPayed AS SumPayed,
	|	Reservations.AccountBalance,
	|	NumberOfPersons}
	|FROM
	|	(SELECT
	|		ReservationTotals.Ref.Hotel AS Hotel,
	|		ReservationTotals.Ref.GuestGroup AS GuestGroup,
	|		ReservationTotals.Ref.Customer AS Customer,
	|		ReservationTotals.Ref.Contract AS Contract,
	|		ReservationTotals.Ref.ContactPerson AS ContactPerson,
	|		ReservationTotals.Ref.Company AS Company,
	|		ReservationTotals.Ref.ResourceReservationStatus AS ResourceReservationStatus,
	|		ReservationTotals.Ref AS Ref,
	|		ReservationTotals.DateTimeFrom AS DateTimeFrom,
	|		ReservationTotals.Duration AS Duration,
	|		ReservationTotals.DateTimeTo AS DateTimeTo,
	|		ReservationTotals.EventActivity AS EventActivity,
	|		ReservationTotals.Resource AS Resource,
	|		ReservationTotals.ResourceType AS ResourceType,
	|		ReservationTotals.NumberOfPersons AS NumberOfPersons,
	|		ReservationTotals.NumberOfPersonsAsResource AS NumberOfPersonsAsResource,
	|		ReservationTotals.TableConfiguration AS TableConfiguration,
	|		ReservationTotals.ActivityRemarks AS ActivityRemarks,
	|		ReservationTotals.Service AS Service,
	|		ReservationTotals.ServiceRemarks AS ServiceRemarks,
	|		ReservationTotals.Price AS Price,
	|		ReservationTotals.Quantity AS Quantity,
	|		ReservationTotals.Sum AS Sum,
	|		ReservationTotals.DiscountSum AS DiscountSum,
	|		ReservationTotals.SumWithoutDiscount AS SumWithoutDiscount,
	|		ReservationTotals.VATRate AS VATRate,
	|		ReservationTotals.VATSum AS VATSum,
	|		ReservationTotals.HoursRented AS HoursRented,
	|		DATEDIFF(&qBegOfCurrentDate, BEGINOFPERIOD(ReservationTotals.Ref.DateTimeFrom, DAY), DAY) AS DaysBeforeDateFrom,
	|		ReservationTotals.Ref.Author AS Author,
	|		ReservationFolioBalances.Folio AS Account,
	|		ReservationFolioBalances.FolioCurrency AS AccountCurrency,
	|		ISNULL(ReservationFolioBalances.FolioBalance, 0) AS AccountBalance,
	|		0 AS InvoiceAge,
	|		0 AS SumInvoice,
	|		0 AS SumPayed
	|	FROM
	|		(SELECT
	|			ReservationHeaders.Ref AS Ref,
	|			ReservationHeaders.DateTimeFrom AS DateTimeFrom,
	|			ReservationHeaders.Duration AS Duration,
	|			ReservationHeaders.DateTimeTo AS DateTimeTo,
	|			NULL AS EventActivity,
	|			ReservationHeaders.Resource AS Resource,
	|			ReservationHeaders.ResourceType AS ResourceType,
	|			ReservationHeaders.NumberOfPersons AS NumberOfPersons,
	|			ReservationHeaders.NumberOfPersons AS NumberOfPersonsAsResource,
	|			NULL AS TableConfiguration,
	|			ReservationHeaders.Remarks AS ActivityRemarks,
	|			NULL AS Service,
	|			"""" AS ServiceRemarks,
	|			0 AS Price,
	|			0 AS Quantity,
	|			0 AS Sum,
	|			0 AS DiscountSum,
	|			0 AS SumWithoutDiscount,
	|			NULL AS VATRate,
	|			0 AS VATSum,
	|			0 AS HoursRented
	|		FROM
	|			Document.ResourceReservation AS ReservationHeaders
	|		WHERE
	|			ReservationHeaders.Posted
	|			AND (ReservationHeaders.Hotel IN HIERARCHY (&qHotel)
	|					OR &qHotelIsEmpty)
	|			AND (ReservationHeaders.GuestGroup = &qGuestGroup
	|					OR &qGuestGroupIsEmpty)
	|			AND (ReservationHeaders.Resource = &qResource
	|					OR &qResourceIsEmpty)
	|			AND ReservationHeaders.Resource <> VALUE(Catalog.Resources.EmptyRef)
	|			AND (ReservationHeaders.ResourceType IN HIERARCHY (&qResourceType)
	|					OR &qResourceTypeIsEmpty)
	|			AND (ISNULL(ReservationHeaders.ResourceReservationStatus.IsActive, FALSE)
	|					OR NOT &qShowActiveOnly)
	|			AND (NOT ISNULL(ReservationHeaders.ResourceReservationStatus.IsActive, FALSE)
	|					OR NOT &qShowInactiveOnly)
	|			AND (ReservationHeaders.DateTimeFrom < &qPeriodTo
	|						AND ReservationHeaders.DateTimeTo > &qPeriodFrom
	|						AND &qPeriodCheckType = &qIntersection
	|					OR ReservationHeaders.DateTimeFrom >= &qPeriodFrom
	|						AND ReservationHeaders.DateTimeFrom < &qPeriodTo
	|						AND (&qPeriodCheckType = &qCheckIn
	|							OR &qPeriodCheckType = &qCheckInOrCheckOut)
	|					OR ReservationHeaders.DateTimeTo > &qPeriodFrom
	|						AND ReservationHeaders.DateTimeTo <= &qPeriodTo
	|						AND (&qPeriodCheckType = &qCheckOut
	|							OR &qPeriodCheckType = &qCheckInOrCheckOut)
	|					OR ReservationHeaders.Date >= &qPeriodFrom
	|						AND ReservationHeaders.Date < &qPeriodTo
	|						AND &qPeriodCheckType = &qDocDateInPeriod)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			ReservationRows.Ref,
	|			ReservationRows.DateTimeFrom,
	|			DATEDIFF(ReservationRows.DateTimeFrom, ReservationRows.DateTimeTo, HOUR),
	|			ReservationRows.DateTimeTo,
	|			ReservationRows.EventActivity,
	|			ReservationRows.ServiceResource,
	|			ReservationRows.ServiceResource.Owner,
	|			ReservationRows.NumberOfPersons,
	|			0,
	|			ReservationRows.ResourceTableConfiguration,
	|			ReservationRows.ActivityRemarks,
	|			ReservationRows.Service,
	|			ReservationRows.Remarks,
	|			ReservationRows.Price,
	|			ReservationRows.Quantity,
	|			ReservationRows.Sum,
	|			ReservationRows.DiscountSum,
	|			ReservationRows.Sum - ReservationRows.DiscountSum,
	|			ReservationRows.VATRate,
	|			ReservationRows.VATSum,
	|			ReservationRows.HoursRented
	|		FROM
	|			Document.ResourceReservation.Services AS ReservationRows
	|		WHERE
	|			ReservationRows.Ref.Posted
	|			AND (ReservationRows.Ref.Hotel IN HIERARCHY (&qHotel)
	|					OR &qHotelIsEmpty)
	|			AND (ReservationRows.Ref.GuestGroup = &qGuestGroup
	|					OR &qGuestGroupIsEmpty)
	|			AND (ReservationRows.ServiceResource = &qResource
	|					OR &qResourceIsEmpty)
	|			AND (ReservationRows.ServiceResource.Owner IN HIERARCHY (&qResourceType)
	|					OR &qResourceTypeIsEmpty)
	|			AND (ISNULL(ReservationRows.Ref.ResourceReservationStatus.IsActive, FALSE)
	|					OR NOT &qShowActiveOnly)
	|			AND (NOT ISNULL(ReservationRows.Ref.ResourceReservationStatus.IsActive, FALSE)
	|					OR NOT &qShowInactiveOnly)
	|			AND (ReservationRows.DateTimeFrom < &qPeriodTo
	|						AND ReservationRows.DateTimeTo > &qPeriodFrom
	|						AND &qPeriodCheckType = &qIntersection
	|					OR ReservationRows.DateTimeFrom >= &qPeriodFrom
	|						AND ReservationRows.DateTimeFrom < &qPeriodTo
	|						AND (&qPeriodCheckType = &qCheckIn
	|							OR &qPeriodCheckType = &qCheckInOrCheckOut)
	|					OR ReservationRows.DateTimeTo > &qPeriodFrom
	|						AND ReservationRows.DateTimeTo <= &qPeriodTo
	|						AND (&qPeriodCheckType = &qCheckOut
	|							OR &qPeriodCheckType = &qCheckInOrCheckOut)
	|					OR ReservationRows.Ref.Date >= &qPeriodFrom
	|						AND ReservationRows.Ref.Date < &qPeriodTo
	|						AND &qPeriodCheckType = &qDocDateInPeriod)) AS ReservationTotals
	|			LEFT JOIN (SELECT
	|				AccountsBalance.Folio AS Folio,
	|				AccountsBalance.FolioCurrency AS FolioCurrency,
	|				AccountsBalance.Folio.ParentDoc AS FolioParentDoc,
	|				SUM(AccountsBalance.SumBalance) AS FolioBalance
	|			FROM
	|				AccumulationRegister.Accounts.Balance(&qEndOfTime, Folio.Hotel IN HIERARCHY (&qHotel)) AS AccountsBalance
	|			
	|			GROUP BY
	|				AccountsBalance.Folio,
	|				AccountsBalance.FolioCurrency,
	|				AccountsBalance.Folio.ParentDoc) AS ReservationFolioBalances
	|			ON ReservationTotals.Ref = ReservationFolioBalances.FolioParentDoc
	|				AND (&qShowInvoicesAndDeposits)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		InvoiceAccountsTurnovers.Hotel,
	|		InvoiceAccountsTurnovers.GuestGroup,
	|		InvoiceAccountsTurnovers.AccountingCustomer,
	|		InvoiceAccountsTurnovers.AccountingContract,
	|		InvoiceAccountsTurnovers.Invoice.ContactPerson,
	|		InvoiceAccountsTurnovers.Company,
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
	|		NULL,
	|		InvoiceAccountsTurnovers.Invoice.Remarks,
	|		NULL,
	|		NULL,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		NULL,
	|		0,
	|		0,
	|		0,
	|		InvoiceAccountsTurnovers.Invoice.Author,
	|		InvoiceAccountsTurnovers.Invoice,
	|		InvoiceAccountsTurnovers.AccountingCurrency,
	|		InvoiceAccountsTurnovers.SumReceipt - InvoiceAccountsTurnovers.SumExpense,
	|		DATEDIFF(BEGINOFPERIOD(InvoiceAccountsTurnovers.Invoice.Date, DAY), &qBegOfCurrentDate, DAY),
	|		InvoiceAccountsTurnovers.SumReceipt,
	|		InvoiceAccountsTurnovers.SumExpense
	|	FROM
	|		AccumulationRegister.InvoiceAccounts.Turnovers(
	|				&qBegOfTime,
	|				&qEndOfTime,
	|				Period,
	|				Hotel IN HIERARCHY (&qHotel)
	|					AND GuestGroup IN
	|						(SELECT
	|							PlannedFrom.GuestGroup
	|						FROM
	|							Document.ResourceReservation AS PlannedFrom
	|						WHERE
	|							PlannedFrom.Posted
	|							AND (PlannedFrom.Hotel IN HIERARCHY (&qHotel)
	|								OR &qHotelIsEmpty)
	|							AND (PlannedFrom.GuestGroup = &qGuestGroup
	|								OR &qGuestGroupIsEmpty)
	|							AND (PlannedFrom.Resource = &qResource
	|								OR &qResourceIsEmpty)
	|							AND (PlannedFrom.ResourceType IN HIERARCHY (&qResourceType)
	|								OR &qResourceTypeIsEmpty)
	|							AND (ISNULL(PlannedFrom.ResourceReservationStatus.IsActive, FALSE)
	|								OR NOT &qShowActiveOnly)
	|							AND (NOT ISNULL(PlannedFrom.ResourceReservationStatus.IsActive, FALSE)
	|								OR NOT &qShowInactiveOnly)
	|							AND (PlannedFrom.DateTimeFrom < &qPeriodTo
	|									AND PlannedFrom.DateTimeTo > &qPeriodFrom
	|									AND &qPeriodCheckType = &qIntersection
	|								OR PlannedFrom.DateTimeFrom >= &qPeriodFrom
	|									AND PlannedFrom.DateTimeFrom < &qPeriodTo
	|									AND (&qPeriodCheckType = &qCheckIn
	|										OR &qPeriodCheckType = &qCheckInOrCheckOut)
	|								OR PlannedFrom.DateTimeTo > &qPeriodFrom
	|									AND PlannedFrom.DateTimeTo <= &qPeriodTo
	|									AND (&qPeriodCheckType = &qCheckOut
	|										OR &qPeriodCheckType = &qCheckInOrCheckOut)
	|								OR PlannedFrom.Date >= &qPeriodFrom
	|									AND PlannedFrom.Date < &qPeriodTo
	|									AND &qPeriodCheckType = &qDocDateInPeriod)
	|							AND &qShowInvoicesAndDeposits
	|						GROUP BY
	|							PlannedFrom.GuestGroup)) AS InvoiceAccountsTurnovers) AS Reservations
	|{WHERE
	|	Reservations.Hotel.* AS Hotel,
	|	Reservations.Ref.Agent.* AS Agent,
	|	Reservations.Ref.AgentCommission AS AgentCommission,
	|	Reservations.Ref.AgentCommissionType AS AgentCommissionType,
	|	Reservations.Ref.CustomerType.* AS CustomerType,
	|	Reservations.Ref.SourceOfBusiness.* AS SourceOfBusiness,
	|	Reservations.Ref.MarketingCode.* AS MarketingCode,
	|	Reservations.Ref.* AS Recorder,
	|	Reservations.Customer.* AS Customer,
	|	Reservations.Customer.Author.* AS CustomerAuthor,
	|	Reservations.Contract.* AS Contract,
	|	Reservations.GuestGroup.* AS GuestGroup,
	|	Reservations.GuestGroup.Description AS GuestGroupDescription,
	|	Reservations.GuestGroup.Author.* AS GuestGroupAuthor,
	|	Reservations.Ref.ResourceReservationStatus.* AS ResourceReservationStatus,
	|	Reservations.Ref.ContactPerson AS ContactPerson,
	|	Reservations.Ref.ResourceTariff.* AS ResourceTariff,
	|	Reservations.Ref.ClientType.* AS ClientType,
	|	Reservations.Ref.Client.* AS Client,
	|	Reservations.DateTimeFrom AS DateTimeFrom,
	|	Reservations.Duration AS Duration,
	|	Reservations.DateTimeTo AS DateTimeTo,
	|	Reservations.EventActivity.* AS EventActivity,
	|	Reservations.ResourceType.* AS ResourceType,
	|	Reservations.Resource.* AS Resource,
	|	Reservations.TableConfiguration.* AS TableConfiguration,
	|	Reservations.NumberOfPersons AS NumberOfPersons,
	|	Reservations.NumberOfPersonsAsResource AS NumberOfPersonsAsResource,
	|	Reservations.ActivityRemarks AS ActivityRemarks,
	|	Reservations.Service.* AS Service,
	|	Reservations.ServiceRemarks AS ServiceRemarks,
	|	Reservations.Price AS Price,
	|	Reservations.Quantity AS Quantity,
	|	Reservations.Sum AS Sum,
	|	Reservations.DiscountSum AS DiscountSum,
	|	Reservations.SumWithoutDiscount AS SumWithoutDiscount,
	|	Reservations.VATRate.* AS VATRate,
	|	Reservations.VATSum AS VATSum,
	|	Reservations.HoursRented AS HoursRented,
	|	(BEGINOFPERIOD(Reservations.DateTimeFrom, DAY)) AS FromDate,
	|	(HOUR(Reservations.DateTimeFrom)) AS FromHour,
	|	(DAY(Reservations.DateTimeFrom)) AS FromDay,
	|	(WEEK(Reservations.DateTimeFrom)) AS FromWeek,
	|	(MONTH(Reservations.DateTimeFrom)) AS FromMonth,
	|	(QUARTER(Reservations.DateTimeFrom)) AS FromQuarter,
	|	(YEAR(Reservations.DateTimeFrom)) AS FromYear,
	|	Reservations.Ref.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	Reservations.Ref.PricePresentation AS PricePresentation,
	|	Reservations.Ref.DiscountCard.* AS DiscountCard,
	|	Reservations.Ref.DiscountType.* AS DiscountType,
	|	Reservations.Ref.Discount AS Discount,
	|	Reservations.Ref.ParentDoc.* AS ParentDoc,
	|	Reservations.Ref.Company.* AS Company,
	|	Reservations.Ref.Remarks AS Remarks,
	|	Reservations.Ref.Car AS Car,
	|	Reservations.Author.* AS Author,
	|	Reservations.Account.* AS Account,
	|	Reservations.AccountCurrency.* AS AccountCurrency,
	|	Reservations.DaysBeforeDateFrom AS DaysBeforeDateFrom,
	|	Reservations.InvoiceAge AS InvoiceAge,
	|	Reservations.SumInvoice AS SumInvoice,
	|	Reservations.SumPayed AS SumPayed,
	|	Reservations.AccountBalance}
	|
	|ORDER BY
	|	DateTimeFrom,
	|	Resource
	|{ORDER BY
	|	Hotel.* AS Hotel,
	|	Reservations.Ref.Agent.* AS Agent,
	|	Reservations.Ref.AgentCommission AS AgentCommission,
	|	Reservations.Ref.AgentCommissionType AS AgentCommissionType,
	|	Reservations.Ref.CustomerType.* AS CustomerType,
	|	Reservations.Ref.SourceOfBusiness.* AS SourceOfBusiness,
	|	Reservations.Ref.MarketingCode.* AS MarketingCode,
	|	Customer.* AS Customer,
	|	CustomerAuthor.* AS CustomerAuthor,
	|	Contract.* AS Contract,
	|	GuestGroup.* AS GuestGroup,
	|	GuestGroupDescription AS GuestGroupDescription,
	|	GuestGroupAuthor.* AS GuestGroupAuthor,
	|	ResourceReservationStatus.* AS ResourceReservationStatus,
	|	Reservations.Ref.ContactPerson AS ContactPerson,
	|	Reservations.Ref.ResourceTariff.* AS ResourceTariff,
	|	Reservations.Ref.ClientType.* AS ClientType,
	|	Client.* AS Client,
	|	DateTimeFrom AS DateTimeFrom,
	|	Duration AS Duration,
	|	DateTimeTo AS DateTimeTo,
	|	EventActivity.* AS EventActivity,
	|	ResourceType.* AS ResourceType,
	|	Resource.* AS Resource,
	|	TableConfiguration.* AS TableConfiguration,
	|	NumberOfPersons AS NumberOfPersons,
	|	NumberOfPersonsAsResource AS NumberOfPersonsAsResource,
	|	ActivityRemarks AS ActivityRemarks,
	|	Service.* AS Service,
	|	ServiceRemarks AS ServiceRemarks,
	|	Price AS Price,
	|	Quantity AS Quantity,
	|	Sum AS Sum,
	|	DiscountSum AS DiscountSum,
	|	SumWithoutDiscount AS SumWithoutDiscount,
	|	VATRate.* AS VATRate,
	|	VATSum AS VATSum,
	|	HoursRented AS HoursRented,
	|	Recorder.* AS Recorder,
	|	(BEGINOFPERIOD(Reservations.DateTimeFrom, DAY)) AS FromDate,
	|	(HOUR(Reservations.DateTimeFrom)) AS FromHour,
	|	(DAY(Reservations.DateTimeFrom)) AS FromDay,
	|	(WEEK(Reservations.DateTimeFrom)) AS FromWeek,
	|	(MONTH(Reservations.DateTimeFrom)) AS FromMonth,
	|	(QUARTER(Reservations.DateTimeFrom)) AS FromQuarter,
	|	(YEAR(Reservations.DateTimeFrom)) AS FromYear,
	|	Reservations.Ref.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	Reservations.Ref.PricePresentation AS PricePresentation,
	|	Reservations.Ref.DiscountCard.* AS DiscountCard,
	|	Reservations.Ref.DiscountType.* AS DiscountType,
	|	Reservations.Ref.Discount AS Discount,
	|	Reservations.Ref.ParentDoc.* AS ParentDoc,
	|	Reservations.Ref.Company.* AS Company,
	|	Reservations.Ref.Remarks AS Remarks,
	|	Reservations.Ref.Car AS Car,
	|	Reservations.Author.* AS Author,
	|	Reservations.Account.* AS Account,
	|	Reservations.AccountCurrency.* AS AccountCurrency,
	|	Reservations.DaysBeforeDateFrom AS DaysBeforeDateFrom,
	|	Reservations.InvoiceAge AS InvoiceAge,
	|	Reservations.SumInvoice AS SumInvoice,
	|	Reservations.SumPayed AS SumPayed,
	|	Reservations.AccountBalance}
	|TOTALS
	|	SUM(NumberOfPersonsAsResource),
	|	SUM(Sum),
	|	SUM(SumWithoutDiscount),
	|	SUM(VATSum),
	|	SUM(HoursRented)
	|BY
	|	OVERALL
	|{TOTALS BY
	|	Hotel.* AS Hotel,
	|	Reservations.Ref.Agent.* AS Agent,
	|	Reservations.Ref.AgentCommission AS AgentCommission,
	|	Reservations.Ref.AgentCommissionType AS AgentCommissionType,
	|	Reservations.Ref.CustomerType.* AS CustomerType,
	|	Reservations.Ref.SourceOfBusiness.* AS SourceOfBusiness,
	|	Reservations.Ref.MarketingCode.* AS MarketingCode,
	|	Recorder.* AS Recorder,
	|	Customer.* AS Customer,
	|	CustomerAuthor.* AS CustomerAuthor,
	|	Contract.* AS Contract,
	|	GuestGroup.* AS GuestGroup,
	|	GuestGroupDescription AS GuestGroupDescription,
	|	GuestGroupAuthor.* AS GuestGroupAuthor,
	|	ResourceReservationStatus.* AS ResourceReservationStatus,
	|	Reservations.Ref.ContactPerson AS ContactPerson,
	|	Reservations.Ref.ResourceTariff.* AS ResourceTariff,
	|	Reservations.Ref.ClientType.* AS ClientType,
	|	Client.* AS Client,
	|	Duration AS Duration,
	|	EventActivity.* AS EventActivity,
	|	ResourceType.* AS ResourceType,
	|	Resource.* AS Resource,
	|	TableConfiguration.* AS TableConfiguration,
	|	Service.* AS Service,
	|	VATRate.* AS VATRate,
	|	(BEGINOFPERIOD(Reservations.DateTimeFrom, DAY)) AS FromDate,
	|	(HOUR(Reservations.DateTimeFrom)) AS FromHour,
	|	(DAY(Reservations.DateTimeFrom)) AS FromDay,
	|	(WEEK(Reservations.DateTimeFrom)) AS FromWeek,
	|	(MONTH(Reservations.DateTimeFrom)) AS FromMonth,
	|	(QUARTER(Reservations.DateTimeFrom)) AS FromQuarter,
	|	(YEAR(Reservations.DateTimeFrom)) AS FromYear,
	|	Reservations.Ref.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	Reservations.Ref.DiscountCard.* AS DiscountCard,
	|	Reservations.Ref.DiscountType.* AS DiscountType,
	|	Reservations.Ref.Discount AS Discount,
	|	Reservations.Ref.ParentDoc.* AS ParentDoc,
	|	Reservations.Ref.Company.* AS Company,
	|	Reservations.Author.* AS Author,
	|	Reservations.Account.* AS Account,
	|	Reservations.AccountCurrency.* AS AccountCurrency,
	|	Reservations.DaysBeforeDateFrom AS DaysBeforeDateFrom,
	|	Reservations.InvoiceAge AS InvoiceAge,
	|	NumberOfPersons}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Resource reservations history';RU='История бронирования ресурсов';de='Verlauf der Ressourcenreservierung'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

#EndRegion
