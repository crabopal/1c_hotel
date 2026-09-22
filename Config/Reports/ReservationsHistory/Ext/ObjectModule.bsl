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
		vParamPresentation = vParamPresentation + NStr("en='Reservations with check-in date in the period selected';ru='Отбор брони с датой заезда в выбранном периоде';de='Auswahl der Buchung mit Anreisedatum im gewählten Zeitraum'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodCheckType = Enums.PeriodCheckTypes.EndsInPeriod Then
		vParamPresentation = vParamPresentation + NStr("en='Reservations with check-out date in the period selected';ru='Отбор брони с датой выезда в выбранном периоде';de='Auswahl der Buchung mit Abreisedatum im gewählten Zeitraum'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodCheckType = Enums.PeriodCheckTypes.StartsOrEndsInPeriod Then
		vParamPresentation = vParamPresentation + NStr("en='Reservations with check-in or check-out date in the period selected';ru='Отбор брони с датой заезда или датой выезда в выбранном периоде';de='Auswahl der Buchung mit Anreise- oder Abreisedatum im gewählten Zeitraum'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodCheckType = Enums.PeriodCheckTypes.DocDateInPeriod Then
		vParamPresentation = vParamPresentation + NStr("en='Reservations with creation date in the period selected';ru='Отбор брони с датой создания в выбранном периоде';de='Auswahl der Buchung mit Erstellungsdatum im gewählten Zeitraum'") + 
		                     ";" + Chars.LF;
	Endif;		
	If ValueIsFilled(Room) Then
		If Not Room.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Room ';ru='Номер ';de='Zimmer '") + 
			                     TrimAll(Room.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Rooms folder ';ru='Группа номеров ';de='Zimmergruppe '") + 
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
			vParamPresentation = vParamPresentation + NStr("en='Room types folder ';ru='Группа типов номеров ';de='Zimmertypengruppe '") + 
			                     TrimAll(RoomType.Description) + 
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
			                     TrimAll(Hotel.Description) + ";" + Chars.LF;
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
	ReportBuilder.Parameters.Insert("qBegOfCurrentDate", BegOfDay(CurrentSessionDate()));
	ReportBuilder.Parameters.Insert("qDocumentType", DocumentType);
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qShowInactiveOnly", ShowInactiveOnly);
	ReportBuilder.Parameters.Insert("qShowActiveOnly", ShowActiveOnly);
	ReportBuilder.Parameters.Insert("qShowInvoicesAndDeposits", ShowInvoicesAndDeposits);
	ReportBuilder.Parameters.Insert("qPeriodCheckType", PeriodCheckType);
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qShowMainRoomGuestsOnly", ShowMainRoomGuestsOnly);

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
	|	ReservationsRef.Ref AS Ref,
	|	ReservationsRef.Guest AS Guest,
	|	ReservationsRef.GuestGroup AS GuestGroup,
	|	SUM(Accommodations.GuestsCheckedIn) AS NumberOfCheckedInGuests,
	|	SUM(Accommodations.RoomsCheckedIn) AS NumberOfCheckedInRooms,
	|	SUM(Accommodations.BedsCheckedIn) AS NumberOfCheckedInBeds,
	|	SUM(Accommodations.AdditionalBedsCheckedIn) AS NumberOfCheckedInAdditionalBeds
	|INTO ReservationTotals
	|FROM
	|	Document.Reservation AS ReservationsRef
	|		INNER JOIN Catalog.ReservationStatuses AS ReservationStatusList
	|		ON ReservationsRef.ReservationStatus = ReservationStatusList.Ref
	|		LEFT JOIN AccumulationRegister.RoomInventory AS Accommodations
	|		ON (Accommodations.ParentDoc = ReservationsRef.Ref)
	|			AND (Accommodations.IsAccommodation)
	|			AND (Accommodations.IsCheckIn)
	|			AND (Accommodations.RecordType = VALUE(AccumulationRecordType.Expense))
	|			AND (Accommodations.Period = Accommodations.CheckInDate)
	|WHERE
	|	ReservationsRef.Posted
	|	AND CASE
	|			WHEN &qHotel = VALUE(Catalog.Hotels.EmptyRef)
	|				THEN TRUE
	|			ELSE ReservationsRef.Hotel IN HIERARCHY (&qHotel)
	|		END
	|	AND CASE
	|			WHEN &qRoom = VALUE(Catalog.Rooms.EmptyRef)
	|				THEN TRUE
	|			ELSE ReservationsRef.Room IN HIERARCHY (&qRoom)
	|		END
	|	AND CASE
	|			WHEN &qRoomType = VALUE(Catalog.RoomTypes.EmptyRef)
	|				THEN TRUE
	|			ELSE ReservationsRef.RoomType IN HIERARCHY (&qRoomType)
	|		END
	|	AND CASE
	|			WHEN NOT &qShowActiveOnly
	|				THEN TRUE
	|			ELSE ReservationStatusList.IsActive
	|		END
	|	AND CASE
	|			WHEN NOT &qShowInactiveOnly
	|				THEN TRUE
	|			ELSE NOT ReservationStatusList.IsActive
	|		END
	|	AND CASE
	|			WHEN &qPeriodCheckType = VALUE(Enum.PeriodCheckTypes.Intersection)
	|				THEN ReservationsRef.CheckInDate < &qPeriodTo
	|						AND ReservationsRef.CheckOutDate > &qPeriodFrom
	|			WHEN &qPeriodCheckType = VALUE(Enum.PeriodCheckTypes.StartsInPeriod)
	|				THEN ReservationsRef.CheckInDate BETWEEN &qPeriodFrom AND &qPeriodTo
	|			WHEN &qPeriodCheckType = VALUE(Enum.PeriodCheckTypes.EndsInPeriod)
	|				THEN ReservationsRef.CheckOutDate BETWEEN &qPeriodFrom AND &qPeriodTo
	|			WHEN &qPeriodCheckType = VALUE(Enum.PeriodCheckTypes.StartsOrEndsInPeriod)
	|				THEN ReservationsRef.CheckInDate BETWEEN &qPeriodFrom AND &qPeriodTo
	|						OR ReservationsRef.CheckOutDate BETWEEN &qPeriodFrom AND &qPeriodTo
	|			WHEN &qPeriodCheckType = VALUE(Enum.PeriodCheckTypes.DocDateInPeriod)
	|				THEN ReservationsRef.Date BETWEEN &qPeriodFrom AND &qPeriodTo
	|		END
	|
	|GROUP BY
	|	ReservationsRef.Ref,
	|	ReservationsRef.Guest,
	|	ReservationsRef.GuestGroup
	|
	|INDEX BY
	|	Ref,
	|	Guest,
	|	GuestGroup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GuestStatistics.Client AS Client,
	|	SUM(GuestStatistics.GuestsCheckedIn) AS NumberOfClientPreviousCheckIns
	|INTO GuestStatistics
	|FROM
	|	AccumulationRegister.Sales AS GuestStatistics
	|		INNER JOIN ReservationTotals AS ReservationTotals
	|		ON GuestStatistics.Client = ReservationTotals.Guest
	|			AND (ReservationTotals.Guest <> VALUE(Catalog.Clients.EmptyRef))
	|
	|GROUP BY
	|	GuestStatistics.Client
	|
	|INDEX BY
	|	Client
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FolioList.Ref AS Ref,
	|	FolioList.ParentDoc AS ParentDoc
	|INTO FolioList
	|FROM
	|	Document.Folio AS FolioList
	|		INNER JOIN ReservationTotals AS ReservationTotals
	|		ON FolioList.ParentDoc = ReservationTotals.Ref
	|
	|INDEX BY
	|	Ref
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
	|		INNER JOIN ReservationTotals AS ReservationTotals
	|		ON CustomerAccountsMovements.GuestGroup = ReservationTotals.GuestGroup
	|			AND CustomerAccountsMovements.ParentDoc = ReservationTotals.Ref
	|WHERE
	|	CustomerAccountsMovements.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND NOT &qShowInvoicesAndDeposits
	|
	|GROUP BY
	|	CustomerAccountsMovements.ParentDoc,
	|	CustomerAccountsMovements.AccountingCurrency
	|
	|INDEX BY
	|	Reservation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReservationTotals.GuestGroup AS GuestGroup,
	|	COUNT(ReservationTotals.Ref) AS ReservationsCount
	|INTO ReservationsPerGuestGroup
	|FROM
	|	ReservationTotals AS ReservationTotals
	|
	|GROUP BY
	|	ReservationTotals.GuestGroup
	|
	|INDEX BY
	|	GuestGroup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReservationStatistics.ParentDoc AS Ref,
	|	SUM(ReservationStatistics.RoomsRentedTurnover) AS RoomsRented,
	|	SUM(ReservationStatistics.GuestDaysTurnover) AS GuestDays,
	|	SUM(ReservationStatistics.RoomRevenueTurnover) AS RoomRevenue
	|INTO ReservationStatistics
	|FROM
	|	AccumulationRegister.AccountsReceivableForecast.Turnovers(
	|			,
	|			,
	|			,
	|			ParentDoc IN
	|				(SELECT
	|					ReservationTotals.Ref
	|				FROM
	|					ReservationTotals AS ReservationTotals)) AS ReservationStatistics
	|
	|GROUP BY
	|	ReservationStatistics.ParentDoc
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ChargeList.Ref AS Ref,
	|	ChargeList.ParentDoc AS ParentDoc
	|INTO ChargeList
	|FROM
	|	Document.Charge AS ChargeList
	|		INNER JOIN ReservationTotals AS ReservationTotals
	|		ON ChargeList.ParentDoc = ReservationTotals.Ref
	|
	|INDEX BY
	|	ParentDoc
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccountsBalance.Folio AS Folio,
	|	AccountsBalance.FolioCurrency AS FolioCurrency,
	|	FolioList.ParentDoc AS FolioParentDoc,
	|	SUM(AccountsBalance.SumBalance) AS FolioBalance
	|INTO ReservationFolioBalances
	|FROM
	|	AccumulationRegister.Accounts.Balance(
	|			,
	|			Folio IN
	|					(SELECT
	|						FolioList.Ref
	|					FROM
	|						FolioList AS FolioList)
	|				AND &qShowInvoicesAndDeposits) AS AccountsBalance
	|		INNER JOIN FolioList AS FolioList
	|		ON AccountsBalance.Folio = FolioList.Ref
	|
	|GROUP BY
	|	AccountsBalance.Folio,
	|	AccountsBalance.FolioCurrency,
	|	FolioList.ParentDoc
	|
	|INDEX BY
	|	FolioParentDoc
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReservationsList.Hotel AS Hotel,
	|	ReservationsList.GuestGroup AS GuestGroup,
	|	ReservationsList.Guest AS Guest,
	|	ReservationsList.ReservationStatus AS ReservationStatus,
	|	ReservationsList.CheckInDate AS CheckInDate,
	|	ReservationsList.Duration AS Duration,
	|	ReservationsList.CheckOutDate AS CheckOutDate,
	|	ReservationsList.RoomType AS RoomType,
	|	ReservationsList.AccommodationTemplate AS AccommodationTemplate,
	|	ReservationsList.AccommodationType AS AccommodationType,
	|	ReservationsList.Room AS Room,
	|	ReservationsList.RoomRate AS RoomRate,
	|	ReservationsList.RoomRateType AS RoomRateType,
	|	ReservationsList.Date AS Date,
	|	ReservationsList.NumberOfAdults AS NumberOfAdults,
	|	ReservationsList.NumberOfTeenagers AS NumberOfTeenagers,
	|	ReservationsList.NumberOfChildren AS NumberOfChildren,
	|	ReservationsList.NumberOfInfants AS NumberOfInfants,
	|	ReservationsList.Agent AS Agent,
	|	ReservationsList.CustomerType AS CustomerType,
	|	ReservationsList.ClientType AS ClientType,
	|	ReservationsList.PlannedPaymentMethod AS PlannedPaymentMethod,
	|	ReservationsList.IsMaster AS IsMaster,
	|	ReservationsList.HotelProduct AS HotelProduct,
	|	ReservationsList.RoomQuota AS RoomQuota,
	|	ReservationsList.GuaranteeType AS GuaranteeType,
	|	ReservationsList.MarketingCode AS MarketingCode,
	|	ReservationsList.TripPurpose AS TripPurpose,
	|	ReservationsList.SourceOfBusiness AS SourceOfBusiness,
	|	ReservationsList.DiscountCard AS DiscountCard,
	|	ReservationsList.DiscountType AS DiscountType,
	|	ReservationsList.Discount AS Discount,
	|	ReservationsList.AgentCommission AS AgentCommission,
	|	ReservationsList.AgentCommissionType AS AgentCommissionType,
	|	ReservationsList.RoomQuantity AS RoomQuantity,
	|	ReservationsList.NumberOfBedsPerRoom AS NumberOfBedsPerRoom,
	|	ReservationsList.NumberOfPersonsPerRoom AS NumberOfPersonsPerRoom,
	|	ReservationsList.ParentDoc AS ParentDoc,
	|	ReservationsList.RoomTypeUpgrade AS RoomTypeUpgrade,
	|	ReservationsList.PricePresentation AS PricePresentation,
	|	ReservationsList.WaitTillDate AS WaitTillDate,
	|	ReservationsList.ServicePackage AS ServicePackage,
	|	ReservationsList.Car AS Car,
	|	ReservationsList.AnnulationReason AS AnnulationReason,
	|	ReservationsList.DateOfAnnulation AS DateOfAnnulation,
	|	ReservationsList.AuthorOfAnnulation AS AuthorOfAnnulation,
	|	ReservationsList.ExternalCode AS ExternalCode,
	|	ReservationsList.Customer AS Customer,
	|	ReservationsList.Contract AS Contract,
	|	ReservationsList.ContactPerson AS ContactPerson,
	|	ReservationsList.Ref AS Ref,
	|	ReservationsList.Remarks AS Remarks,
	|	ReservationsList.Company AS Company,
	|	ReservationsList.Author AS Author,
	|	ReservationFolioBalances.Folio AS Account,
	|	ReservationFolioBalances.FolioCurrency AS AccountCurrency,
	|	GuestGroupAttachments.DocumentNumber AS DocumentNumber,
	|	GuestGroupAttachments.Period AS DocumentDate,
	|	DATEDIFF(&qBegOfCurrentDate, BEGINOFPERIOD(ReservationsList.CheckInDate, DAY), DAY) AS DaysBeforeCheckIn,
	|	0 AS InvoiceAge,
	|	0 AS SumInvoice,
	|	ISNULL(ReservationFolioBalances.FolioBalance, 0) AS AccountBalance,
	|	0 AS SumPayedByInvoice,
	|	ReservationsList.NumberOfPersons AS NumberOfPersons,
	|	ReservationsList.NumberOfRooms AS NumberOfRooms,
	|	ReservationsList.NumberOfBeds AS NumberOfBeds,
	|	ReservationsList.NumberOfAdditionalBeds AS NumberOfAdditionalBeds,
	|	ReservationTotals.NumberOfCheckedInGuests AS NumberOfCheckedInGuests,
	|	ReservationTotals.NumberOfCheckedInRooms AS NumberOfCheckedInRooms,
	|	ReservationTotals.NumberOfCheckedInBeds AS NumberOfCheckedInBeds,
	|	ReservationTotals.NumberOfCheckedInAdditionalBeds AS NumberOfCheckedInAdditionalBeds,
	|	1 / ReservationsPerGuestGroup.ReservationsCount AS GuestGroupsCount,
	|	0 AS AverageGuestGroupsCountPerWeek
	|INTO Reservations
	|FROM
	|	Document.Reservation AS ReservationsList
	|		INNER JOIN ReservationTotals AS ReservationTotals
	|		ON ReservationsList.Ref = ReservationTotals.Ref
	|		LEFT JOIN ReservationFolioBalances AS ReservationFolioBalances
	|		ON ReservationsList.Ref = ReservationFolioBalances.FolioParentDoc
	|		LEFT JOIN ReservationsPerGuestGroup AS ReservationsPerGuestGroup
	|		ON ReservationsList.GuestGroup = ReservationsPerGuestGroup.GuestGroup
	|		LEFT JOIN InformationRegister.GuestGroupAttachments AS GuestGroupAttachments
	|		ON ReservationsList.GuestGroup = GuestGroupAttachments.GuestGroup
	|			AND ReservationsList.Number = GuestGroupAttachments.ReservationNumber
	|			AND (GuestGroupAttachments.DocumentType = &qDocumentType)
	|			AND (&qDocumentType <> VALUE(Catalog.GuestGroupAttachmentDocumentTypes.EmptyRef))
	|
	|UNION ALL
	|
	|SELECT
	|	InvoiceAccountsTurnovers.Hotel,
	|	InvoiceAccountsTurnovers.GuestGroup,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	InvoiceAccountsTurnovers.AccountingCustomer,
	|	InvoiceAccountsTurnovers.AccountingContract,
	|	InvoiceAccountsTurnovers.Invoice.ContactPerson,
	|	NULL,
	|	InvoiceAccountsTurnovers.Invoice.Remarks,
	|	InvoiceAccountsTurnovers.Company,
	|	InvoiceAccountsTurnovers.Invoice.Author,
	|	InvoiceAccountsTurnovers.Invoice,
	|	InvoiceAccountsTurnovers.AccountingCurrency,
	|	NULL,
	|	NULL,
	|	0,
	|	DATEDIFF(BEGINOFPERIOD(InvoiceAccountsTurnovers.Invoice.Date, DAY), &qBegOfCurrentDate, DAY),
	|	InvoiceAccountsTurnovers.SumReceipt,
	|	InvoiceAccountsTurnovers.SumReceipt - InvoiceAccountsTurnovers.SumExpense,
	|	InvoiceAccountsTurnovers.SumExpense,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0
	|FROM
	|	AccumulationRegister.InvoiceAccounts.Turnovers(
	|			,
	|			,
	|			Period,
	|			GuestGroup IN
	|					(SELECT
	|						ReservationsPerGuestGroup.GuestGroup
	|					FROM
	|						ReservationsPerGuestGroup AS ReservationsPerGuestGroup)
	|				AND &qShowInvoicesAndDeposits) AS InvoiceAccountsTurnovers
	|
	|INDEX BY
	|	Ref,
	|	Guest
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReservationServices.ParentDoc AS Ref,
	|	ReservationServices.FolioCurrency AS Currency,
	|	SUM(ReservationServices.ExpectedSalesTurnover) AS ExpectedAmount,
	|	SUM(ReservationServices.ExpectedCommissionSumTurnover) AS ExpectedCommissionSumTurnover
	|INTO Services
	|FROM
	|	AccumulationRegister.AccountsReceivableForecast.Turnovers(
	|			,
	|			,
	|			Period,
	|			ParentDoc IN
	|				(SELECT
	|					ReservationTotals.Ref
	|				FROM
	|					ReservationTotals AS ReservationTotals)) AS ReservationServices
	|
	|GROUP BY
	|	ReservationServices.ParentDoc,
	|	ReservationServices.FolioCurrency
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReservationChargedServices.Charge.ParentDoc AS Ref,
	|	ReservationChargedServices.FolioCurrency AS Currency,
	|	SUM(ReservationChargedServices.SumReceipt) AS Amount
	|INTO ChargedServices
	|FROM
	|	AccumulationRegister.CurrentAccountsReceivable.BalanceAndTurnovers(
	|			,
	|			,
	|			Period,
	|			RegisterRecordsAndPeriodBoundaries,
	|			Charge.ParentDoc IN
	|				(SELECT
	|					ChargeList.ParentDoc
	|				FROM
	|					ChargeList AS ChargeList)) AS ReservationChargedServices
	|		INNER JOIN ChargeList AS ChargeList
	|		ON ReservationChargedServices.Charge = ChargeList.Ref
	|
	|GROUP BY
	|	ReservationChargedServices.Charge.ParentDoc,
	|	ReservationChargedServices.FolioCurrency
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Reservations.Hotel AS Hotel,
	|	Reservations.Customer AS Customer,
	|	Reservations.Contract AS Contract,
	|	Reservations.GuestGroup AS GuestGroup,
	|	Reservations.ReservationStatus AS ReservationStatus,
	|	Reservations.Guest AS Guest,
	|	Reservations.CheckInDate AS CheckInDate,
	|	Reservations.Duration AS Duration,
	|	Reservations.CheckOutDate AS CheckOutDate,
	|	Reservations.RoomType AS RoomType,
	|	Reservations.AccommodationTemplate AS AccommodationTemplate,
	|	Reservations.AccommodationType AS AccommodationType,
	|	Reservations.Room AS Room,
	|	Reservations.RoomRate AS RoomRate,
	|	Reservations.Ref AS Recorder,
	|	Reservations.NumberOfPersons AS NumberOfPersons,
	|	Reservations.NumberOfRooms AS NumberOfRooms,
	|	Reservations.NumberOfBeds AS NumberOfBeds,
	|	Reservations.NumberOfAdditionalBeds AS NumberOfAdditionalBeds,
	|	Reservations.NumberOfCheckedInGuests AS NumberOfCheckedInGuests,
	|	Reservations.NumberOfCheckedInRooms AS NumberOfCheckedInRooms,
	|	Reservations.NumberOfCheckedInBeds AS NumberOfCheckedInBeds,
	|	Reservations.NumberOfCheckedInAdditionalBeds AS NumberOfCheckedInAdditionalBeds,
	|	BEGINOFPERIOD(Reservations.Date, DAY) AS CreateDate,
	|	WEEK(Reservations.Date) AS CreateWeek,
	|	Services.Currency AS Currency,
	|	ChargedServices.Amount AS Amount,
	|	Services.ExpectedAmount AS ExpectedAmount,
	|	Reservations.GuestGroupsCount AS GuestGroupsCount,
	|	Reservations.AverageGuestGroupsCountPerWeek AS AverageGuestGroupsCountPerWeek,
	|	Reservations.AccountBalance AS AccountBalance,
	|	Services.ExpectedCommissionSumTurnover AS CommissionSum,
	|	Reservations.NumberOfAdults AS NumberOfAdults,
	|	Reservations.NumberOfTeenagers AS NumberOfTeenagers,
	|	Reservations.NumberOfChildren AS NumberOfChildren,
	|	Reservations.NumberOfInfants AS NumberOfInfants,
	|	ISNULL(ReservationPayments.AmountPayed, 0) AS SumPayed,
	|	ISNULL(ReservationStatistics.RoomsRented, 0) AS RoomsRented,
	|	ISNULL(ReservationStatistics.GuestDays, 0) AS GuestDays,
	|	ISNULL(ReservationStatistics.RoomRevenue, 0) AS RoomRevenue
	|{SELECT
	|	Hotel.* AS Hotel,
	|	Reservations.Agent.* AS Agent,
	|	Reservations.CustomerType AS CustomerType,
	|	Customer.* AS Customer,
	|	Contract.* AS Contract,
	|	GuestGroup.* AS GuestGroup,
	|	Reservations.ContactPerson AS ContactPerson,
	|	Reservations.ClientType.* AS ClientType,
	|	CheckInDate AS CheckInDate,
	|	Duration AS Duration,
	|	CheckOutDate AS CheckOutDate,
	|	(HOUR(Reservations.CheckInDate)) AS CheckInHour,
	|	(BEGINOFPERIOD(Reservations.CheckInDate, DAY)) AS CheckInDay,
	|	(BEGINOFPERIOD(Reservations.CheckInDate, WEEK)) AS CheckInWeek,
	|	(BEGINOFPERIOD(Reservations.CheckInDate, MONTH)) AS CheckInMonth,
	|	(BEGINOFPERIOD(Reservations.CheckInDate, QUARTER)) AS CheckInQuarter,
	|	(YEAR(Reservations.CheckInDate)) AS CheckInYear,
	|	(HOUR(Reservations.Date)) AS CreateHour,
	|	CreateDate,
	|	CreateWeek,
	|	(BEGINOFPERIOD(Reservations.Date, MONTH)) AS CreateMonth,
	|	(BEGINOFPERIOD(Reservations.Date, QUARTER)) AS CreateQuarter,
	|	(YEAR(Reservations.Date)) AS CreateYear,
	|	Guest.* AS Guest,
	|	RoomType.* AS RoomType,
	|	AccommodationType.* AS AccommodationType,
	|	AccommodationTemplate.* AS AccommodationTemplate,
	|	Room.* AS Room,
	|	Reservations.RoomRateType.* AS RoomRateType,
	|	RoomRate.* AS RoomRate,
	|	Reservations.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	Reservations.ReservationStatus.* AS ReservationStatus,
	|	Reservations.IsMaster AS IsMaster,
	|	Reservations.HotelProduct.* AS HotelProduct,
	|	Reservations.RoomQuota.* AS RoomQuota,
	|	Reservations.MarketingCode.* AS MarketingCode,
	|	Reservations.TripPurpose.* AS TripPurpose,
	|	Reservations.SourceOfBusiness.* AS SourceOfBusiness,
	|	Reservations.DiscountCard AS DiscountCard,
	|	Reservations.DiscountType AS DiscountType,
	|	Reservations.Discount AS Discount,
	|	Reservations.AgentCommission AS AgentCommission,
	|	Reservations.AgentCommissionType AS AgentCommissionType,
	|	Reservations.RoomQuantity AS RoomQuantity,
	|	Reservations.NumberOfBedsPerRoom AS NumberOfBedsPerRoom,
	|	Reservations.NumberOfPersonsPerRoom AS NumberOfPersonsPerRoom,
	|	Reservations.ParentDoc.* AS ParentDoc,
	|	Reservations.RoomTypeUpgrade.* AS RoomTypeUpgrade,
	|	Reservations.PricePresentation AS PricePresentation,
	|	Reservations.WaitTillDate AS WaitTillDate,
	|	Reservations.ServicePackage.* AS ServicePackage,
	|	Reservations.Company.* AS Company,
	|	Reservations.Remarks AS Remarks,
	|	Reservations.Car AS Car,
	|	Reservations.Author.* AS Author,
	|	Reservations.AnnulationReason AS AnnulationReason,
	|	Reservations.DateOfAnnulation AS DateOfAnnulation,
	|	Reservations.AuthorOfAnnulation AS AuthorOfAnnulation,
	|	Reservations.Ref.* AS Recorder,
	|	Reservations.ExternalCode AS ExternalCode,
	|	Reservations.DocumentNumber,
	|	Reservations.DocumentDate,
	|	GuestStatistics.NumberOfClientPreviousCheckIns AS NumberOfClientPreviousCheckIns,
	|	Currency.* AS Currency,
	|	NumberOfPersons,
	|	NumberOfRooms,
	|	NumberOfBeds,
	|	NumberOfAdditionalBeds,
	|	NumberOfCheckedInGuests,
	|	NumberOfCheckedInRooms,
	|	NumberOfCheckedInBeds,
	|	NumberOfCheckedInAdditionalBeds,
	|	Amount,
	|	ExpectedAmount,
	|	Reservations.Account.*,
	|	Reservations.AccountCurrency.*,
	|	Reservations.DaysBeforeCheckIn,
	|	Reservations.InvoiceAge,
	|	Reservations.SumInvoice,
	|	Reservations.SumPayedByInvoice,
	|	Reservations.AccountBalance,
	|	GuestGroupsCount,
	|	AverageGuestGroupsCountPerWeek,
	|	Services.ExpectedCommissionSumTurnover AS CommissionSum,
	|	NumberOfAdults,
	|	NumberOfTeenagers,
	|	NumberOfChildren,
	|	NumberOfInfants,
	|	SumPayed,
	|	RoomsRented,
	|	GuestDays,
	|	RoomRevenue}
	|FROM
	|	Reservations AS Reservations
	|		LEFT JOIN Services AS Services
	|		ON Reservations.Ref = Services.Ref
	|		LEFT JOIN ChargedServices AS ChargedServices
	|		ON Reservations.Ref = ChargedServices.Ref
	|		LEFT JOIN GuestStatistics AS GuestStatistics
	|		ON Reservations.Guest = GuestStatistics.Client
	|		LEFT JOIN ReservationPayments AS ReservationPayments
	|		ON Reservations.Ref = ReservationPayments.Reservation
	|		LEFT JOIN ReservationStatistics AS ReservationStatistics
	|		ON Reservations.Ref = ReservationStatistics.Ref
	|WHERE
	|	CASE
	|			WHEN NOT &qShowMainRoomGuestsOnly
	|				THEN TRUE
	|			ELSE Reservations.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|		END
	|{WHERE
	|	Reservations.Ref.* AS Recorder,
	|	Reservations.ExternalCode AS ExternalCode,
	|	Reservations.Hotel.* AS Hotel,
	|	Reservations.RoomType.* AS RoomType,
	|	Reservations.Room.* AS Room,
	|	Reservations.Customer.* AS Customer,
	|	Reservations.CustomerType.* AS CustomerType,
	|	Reservations.Contract.* AS Contract,
	|	Reservations.ContactPerson AS ContactPerson,
	|	Reservations.Agent.* AS Agent,
	|	Reservations.GuestGroup.* AS GuestGroup,
	|	Reservations.ParentDoc.* AS ParentDoc,
	|	Reservations.HotelProduct.* AS HotelProduct,
	|	Reservations.ReservationStatus.* AS ReservationStatus,
	|	Reservations.CheckInDate AS CheckInDate,
	|	Reservations.Duration AS Duration,
	|	Reservations.CheckOutDate AS CheckOutDate,
	|	Reservations.RoomQuota.* AS RoomQuota,
	|	Reservations.RoomQuantity AS RoomQuantity,
	|	Reservations.ClientType.* AS ClientType,
	|	Reservations.AccommodationType AS AccommodationType,
	|	Reservations.AccommodationTemplate AS AccommodationTemplate,
	|	Reservations.Guest.* AS Guest,
	|	Reservations.GuaranteeType.* AS GuaranteeType,
	|	Reservations.MarketingCode.* AS MarketingCode,
	|	Reservations.TripPurpose.* AS TripPurpose,
	|	Reservations.SourceOfBusiness.* AS SourceOfBusiness,
	|	Reservations.RoomRateType.* AS RoomRateType,
	|	Reservations.RoomRate.* AS RoomRate,
	|	Reservations.DiscountCard AS DiscountCard,
	|	Reservations.DiscountType AS DiscountType,
	|	Reservations.Discount AS Discount,
	|	Reservations.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	Reservations.WaitTillDate AS WaitTillDate,
	|	Reservations.RoomTypeUpgrade.* AS RoomTypeUpgrade,
	|	Reservations.PricePresentation AS PricePresentation,
	|	Reservations.ServicePackage.* AS ServicePackage,
	|	Reservations.Company.* AS Company,
	|	Reservations.Remarks AS Remarks,
	|	Reservations.Car AS Car,
	|	Reservations.Author.* AS Author,
	|	Reservations.AgentCommission AS AgentCommission,
	|	Reservations.AgentCommissionType AS AgentCommissionType,
	|	Reservations.IsMaster AS IsMaster,
	|	Reservations.NumberOfPersons AS NumberOfPersons,
	|	Reservations.NumberOfRooms AS NumberOfRooms,
	|	Reservations.NumberOfBeds AS NumberOfBeds,
	|	Reservations.NumberOfAdditionalBeds AS NumberOfAdditionalBeds,
	|	Reservations.NumberOfCheckedInGuests AS NumberOfCheckedInGuests,
	|	Reservations.NumberOfCheckedInRooms AS NumberOfCheckedInRooms,
	|	Reservations.NumberOfCheckedInBeds AS NumberOfCheckedInBeds,
	|	Reservations.NumberOfCheckedInAdditionalBeds AS NumberOfCheckedInAdditionalBeds,
	|	Reservations.DocumentNumber,
	|	Reservations.DocumentDate,
	|	Services.Currency.* AS Currency,
	|	ChargedServices.Amount AS Amount,
	|	Services.ExpectedAmount AS ExpectedAmount,
	|	(ISNULL(ReservationPayments.AmountPayed, 0)) AS SumPayed,
	|	Reservations.Account.*,
	|	Reservations.AccountCurrency.*,
	|	Reservations.DaysBeforeCheckIn,
	|	Reservations.InvoiceAge,
	|	Reservations.AccountBalance,
	|	Reservations.SumInvoice,
	|	Reservations.SumPayedByInvoice,
	|	Reservations.GuestGroupsCount,
	|	Reservations.NumberOfAdults AS NumberOfAdults,
	|	Reservations.NumberOfTeenagers AS NumberOfTeenagers,
	|	Reservations.NumberOfChildren AS NumberOfChildren,
	|	Reservations.NumberOfInfants AS NumberOfInfants,
	|	(ISNULL(ReservationStatistics.RoomsRented, 0)) AS RoomsRented,
	|	(ISNULL(ReservationStatistics.GuestDays, 0)) AS GuestDays,
	|	(ISNULL(ReservationStatistics.RoomRevenue, 0)) AS RoomRevenue}
	|
	|ORDER BY
	|	Hotel,
	|	Customer,
	|	Contract,
	|	GuestGroup,
	|	CheckInDate,
	|	Guest
	|{ORDER BY
	|	Reservations.Ref.* AS Recorder,
	|	Hotel.* AS Hotel,
	|	Reservations.Agent.* AS Agent,
	|	Customer.* AS Customer,
	|	Reservations.CustomerType.* AS CustomerType,
	|	Contract.* AS Contract,
	|	GuestGroup.* AS GuestGroup,
	|	CheckInDate AS CheckInDate,
	|	Guest.* AS Guest,
	|	Reservations.MarketingCode.* AS MarketingCode,
	|	Reservations.TripPurpose.* AS TripPurpose,
	|	Reservations.SourceOfBusiness.* AS SourceOfBusiness,
	|	Reservations.ReservationStatus.* AS ReservationStatus,
	|	RoomRate.* AS RoomRate,
	|	Reservations.RoomRateType.* AS RoomRateType,
	|	Reservations.GuaranteeType.* AS GuaranteeType,
	|	Reservations.DiscountCard.* AS DiscountCard,
	|	Reservations.DiscountType.* AS DiscountType,
	|	Reservations.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	Reservations.Room.* AS Room,
	|	Reservations.RoomType.* AS RoomType,
	|	Reservations.ExternalCode AS ExternalCode,
	|	Reservations.WaitTillDate AS WaitTillDate,
	|	Reservations.RoomTypeUpgrade.* AS RoomTypeUpgrade,
	|	Reservations.PricePresentation AS PricePresentation,
	|	Reservations.ServicePackage.* AS ServicePackage,
	|	CheckInDate AS CheckInDate,
	|	Duration AS Duration,
	|	CheckOutDate AS CheckOutDate,
	|	Reservations.RoomRateType.* AS RoomRateType,
	|	AccommodationType.* AS AccommodationType,
	|	AccommodationTemplate.* AS AccommodationTemplate,
	|	RoomRate.* AS RoomRate,
	|	Reservations.Company.* AS Company,
	|	Reservations.Author.* AS Author,
	|	Reservations.RoomQuota.* AS RoomQuota,
	|	Reservations.DocumentNumber,
	|	Reservations.DocumentDate,
	|	Currency.*,
	|	Amount,
	|	ExpectedAmount,
	|	(HOUR(Reservations.CheckInDate)) AS CheckInHour,
	|	(BEGINOFPERIOD(Reservations.CheckInDate, DAY)) AS CheckInDay,
	|	(BEGINOFPERIOD(Reservations.CheckInDate, WEEK)) AS CheckInWeek,
	|	(BEGINOFPERIOD(Reservations.CheckInDate, MONTH)) AS CheckInMonth,
	|	(BEGINOFPERIOD(Reservations.CheckInDate, QUARTER)) AS CheckInQuarter,
	|	(YEAR(Reservations.CheckInDate)) AS CheckInYear,
	|	(HOUR(Reservations.Date)) AS CreateHour,
	|	CreateDate,
	|	CreateWeek,
	|	(BEGINOFPERIOD(Reservations.Date, MONTH)) AS CreateMonth,
	|	(BEGINOFPERIOD(Reservations.Date, QUARTER)) AS CreateQuarter,
	|	(YEAR(Reservations.Date)) AS CreateYear,
	|	NumberOfPersons,
	|	NumberOfRooms,
	|	NumberOfBeds,
	|	NumberOfAdditionalBeds,
	|	NumberOfCheckedInGuests,
	|	NumberOfCheckedInRooms,
	|	NumberOfCheckedInBeds,
	|	NumberOfCheckedInAdditionalBeds,
	|	Reservations.Account.*,
	|	Reservations.AccountCurrency.*,
	|	Reservations.DaysBeforeCheckIn,
	|	Reservations.InvoiceAge,
	|	Reservations.SumInvoice,
	|	Reservations.AccountBalance,
	|	Reservations.SumPayedByInvoice,
	|	GuestGroupsCount,
	|	NumberOfAdults,
	|	NumberOfTeenagers,
	|	NumberOfChildren,
	|	NumberOfInfants,
	|	RoomsRented,
	|	GuestDays,
	|	RoomRevenue}
	|TOTALS
	|	SUM(Duration),
	|	SUM(NumberOfPersons),
	|	SUM(NumberOfRooms),
	|	SUM(NumberOfBeds),
	|	SUM(NumberOfAdditionalBeds),
	|	SUM(NumberOfCheckedInGuests),
	|	SUM(NumberOfCheckedInRooms),
	|	SUM(NumberOfCheckedInBeds),
	|	SUM(NumberOfCheckedInAdditionalBeds),
	|	SUM(Amount),
	|	SUM(ExpectedAmount),
	|	SUM(GuestGroupsCount),
	|	CASE
	|		WHEN CreateDate IS NULL
	|				AND NOT CreateWeek IS NULL
	|			THEN SUM(GuestGroupsCount) / 7
	|		ELSE SUM(AverageGuestGroupsCountPerWeek)
	|	END AS AverageGuestGroupsCountPerWeek,
	|	SUM(AccountBalance),
	|	SUM(CommissionSum),
	|	SUM(NumberOfAdults),
	|	SUM(NumberOfTeenagers),
	|	SUM(NumberOfChildren),
	|	SUM(NumberOfInfants),
	|	SUM(SumPayed),
	|	SUM(RoomsRented),
	|	SUM(GuestDays),
	|	SUM(RoomRevenue)
	|BY
	|	OVERALL,
	|	CreateWeek,
	|	CreateDate
	|{TOTALS BY
	|	Hotel.* AS Hotel,
	|	RoomType.* AS RoomType,
	|	Room.* AS Room,
	|	Customer.* AS Customer,
	|	Reservations.Ref.* AS Recorder,
	|	Reservations.CustomerType.* AS CustomerType,
	|	Contract.* AS Contract,
	|	Reservations.ContactPerson AS ContactPerson,
	|	Reservations.Agent.* AS Agent,
	|	GuestGroup.* AS GuestGroup,
	|	Reservations.HotelProduct.* AS HotelProduct,
	|	ReservationStatus.* AS ReservationStatus,
	|	Reservations.GuaranteeType.* AS GuaranteeType,
	|	Reservations.RoomQuota.* AS RoomQuota,
	|	Reservations.ClientType.* AS ClientType,
	|	Reservations.MarketingCode.* AS MarketingCode,
	|	Reservations.TripPurpose.* AS TripPurpose,
	|	Reservations.SourceOfBusiness.* AS SourceOfBusiness,
	|	Reservations.RoomRateType.* AS RoomRateType,
	|	Reservations.RoomTypeUpgrade.* AS RoomTypeUpgrade,
	|	Reservations.PricePresentation AS PricePresentation,
	|	Reservations.ServicePackage.* AS ServicePackage,
	|	RoomRate.* AS RoomRate,
	|	AccommodationType.* AS AccommodationType,
	|	AccommodationTemplate.* AS AccommodationTemplate,
	|	Reservations.DiscountCard.* AS DiscountCard,
	|	Reservations.DiscountType.* AS DiscountType,
	|	Reservations.Company.* AS Company,
	|	Reservations.Author.* AS Author,
	|	Reservations.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	Reservations.Account.*,
	|	Reservations.AccountCurrency.*,
	|	Reservations.WaitTillDate AS WaitTillDate,
	|	Reservations.DocumentNumber,
	|	Currency.*,
	|	(HOUR(Reservations.CheckInDate)) AS CheckInHour,
	|	(BEGINOFPERIOD(Reservations.CheckInDate, DAY)) AS CheckInDay,
	|	(BEGINOFPERIOD(Reservations.CheckInDate, WEEK)) AS CheckInWeek,
	|	(BEGINOFPERIOD(Reservations.CheckInDate, MONTH)) AS CheckInMonth,
	|	(BEGINOFPERIOD(Reservations.CheckInDate, QUARTER)) AS CheckInQuarter,
	|	(YEAR(Reservations.CheckInDate)) AS CheckInYear,
	|	(HOUR(Reservations.Date)) AS CreateHour,
	|	CreateDate,
	|	CreateWeek,
	|	(BEGINOFPERIOD(Reservations.Date, MONTH)) AS CreateMonth,
	|	(BEGINOFPERIOD(Reservations.Date, QUARTER)) AS CreateQuarter,
	|	(YEAR(Reservations.Date)) AS CreateYear,
	|	Services.ExpectedCommissionSumTurnover AS CommissionSum}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Reservations history'; RU='История брони'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
