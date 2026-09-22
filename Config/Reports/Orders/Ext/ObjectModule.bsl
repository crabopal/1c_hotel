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
	If ByDateOfOrder Then
		vParamPresentation = vParamPresentation + NStr("en='By date of order ';ru='По дате заказа ';de='Nach bestelldatum '") + ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("en='By date';ru='По дате';de='Nach Datum'") + ";" + Chars.LF;	
	EndIf;
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
	If ValueIsFilled(Room) Then
		vParamPresentation = vParamPresentation + NStr("en='Room ';ru='Номер ';de='Zimmer '") + 
			                 TrimAll(Room.Description) + 
			                 ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(Service) Then
		If Service.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Services folder ';ru='Группа услуг ';de='Dienstleistungsgruppe '") + 
				                 TrimAll(Service.Description) + 
				                 ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Service ';ru='Услуга ';de='Dienstleistung '") + 
				                 TrimAll(Service.Description) + 
				                 ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(Client) Then
		vParamPresentation = vParamPresentation + NStr("en='Client ';ru='Клиент ';de='Klient '") + 
			                 TrimAll(Client.FullName) + 
			                 ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(GuestGroup) Then
		vParamPresentation = vParamPresentation + NStr("en='Guest group ';ru='Группа гостей ';de='Gästegruppen '") + 
			                 TrimAll(GuestGroup.Description) + 
			                 ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(Type) Then
		vParamPresentation = vParamPresentation + NStr("en='Type ';ru='Тип ';de='Typ '") + 
			                 TrimAll(Type.Description) + 
			                 ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(Hotel) Then
		vParamPresentation = vParamPresentation + NStr("en='Hotel ';ru='Гостиница ';de='Hotel '") + 
			                 Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                 TrimAll(Hotel.Description) + ";" + Chars.LF;
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
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qRoomIsEmpty", Not ValueIsFilled(Room));
	ReportBuilder.Parameters.Insert("qClient", Client);
	ReportBuilder.Parameters.Insert("qClientIsEmpty", Not ValueIsFilled(Client));
	ReportBuilder.Parameters.Insert("qGuestGroup", GuestGroup);
	ReportBuilder.Parameters.Insert("qGuestGroupIsEmpty", Not ValueIsFilled(GuestGroup));
	ReportBuilder.Parameters.Insert("qType", Type);
	ReportBuilder.Parameters.Insert("qTypeIsEmpty", Not ValueIsFilled(Type));
	ReportBuilder.Parameters.Insert("qByDateOfOrder", ByDateOfOrder);
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodFromIsEmpty", Not ValueIsFilled(PeriodFrom));
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qPeriodToIsEmpty", Not ValueIsFilled(PeriodTo));
	ReportBuilder.Parameters.Insert("qService", Service);
	ReportBuilder.Parameters.Insert("qServiceIsEmpty", Not ValueIsFilled(Service));

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
	|	Order.Number AS Number,
	|	Order.Date AS Date,
	|	Order.Type AS Type,
	|	Order.Status AS Status,
	|	Order.Department AS Department,
	|	Order.OrderTime AS OrderTime,
	|	Order.OrderDateFrom AS OrderDateFrom,
	|	Order.OrderDateTo AS OrderDateTo,
	|	Order.Client AS Client,
	|	Order.Phone AS Phone,
	|	Order.Remarks AS Remarks,
	|	Order.Author AS Author,
	|	Order.Room AS Room,
	|	Order.PickupFrom AS PickupFrom,
	|	Order.Destination AS Destination,
	|	Order.GuestsQuantity AS GuestsQuantity,
	|	Order.ChildSeatsNumber AS ChildSeatsNumber,
	|	Order.TransferType AS TransferType,
	|	Order.Vehicle AS Vehicle,
	|	Order.RentTime AS RentTime,
	|	Order.RentResources AS RentResources,
	|	Order.Hotel AS Hotel,
	|	Order.Price AS Price,
	|	Order.Unit AS Unit,
	|	Order.Quantity AS Quantity,
	|	Order.Sum AS Sum,
	|	Order.ItemsSum AS ItemsSum,
	|	Order.Currency AS Currency,
	|	Order.ParentDoc AS ParentDoc,
	|	Order.Service AS Service,
	|	Order.GuestGroup AS GuestGroup,
	|	Order.Charge AS Charge,
	|	Order.Employee AS Employee,
	|	Order.OrderPaymentType AS OrderPaymentType,
	|	Order.Folio AS Folio,
	|	Order.RouteType AS RouteType,
	|	Order.DiscountCard AS DiscountCard,
	|	Order.DiscountType AS DiscountType,
	|	Order.Discount AS Discount,
	|	Order.ManualDiscountType AS ManualDiscountType,
	|	Order.ManualDiscount AS ManualDiscount,
	|	Order.ManualDiscountSum AS ManualDiscountSum,
	|	Order.ManualPriceChangeReason AS ManualPriceChangeReason,
	|	Order.ClientType AS ClientType,
	|	Order.NoDiscounts AS NoDiscounts,
	|	Order.Carrier AS Carrier,
	|	Order.Manager AS Manager,
	|	Order.Ref AS Ref
	|{SELECT
	|	Ref.*,
	|	Number,
	|	Date,
	|	Type.*,
	|	Status.*,
	|	Department.*,
	|	OrderTime,
	|	OrderDateFrom,
	|	OrderDateTo,
	|	Client.*,
	|	Phone,
	|	Remarks,
	|	Author.*,
	|	Room.*,
	|	PickupFrom,
	|	Destination,
	|	GuestsQuantity,
	|	ChildSeatsNumber,
	|	TransferType.*,
	|	Vehicle.*,
	|	RentTime,
	|	RentResources.*,
	|	Hotel.*,
	|	Price,
	|	Unit,
	|	Quantity,
	|	Sum,
	|	ItemsSum,
	|	Currency.*,
	|	ParentDoc.*,
	|	Service.*,
	|	GuestGroup.*,
	|	Charge.*,
	|	Employee.*,
	|	OrderPaymentType.*,
	|	Folio.*,
	|	RouteType.*,
	|	DiscountCard.*,
	|	DiscountType.*,
	|	Discount,
	|	ManualDiscountType.*,
	|	ManualDiscount,
	|	ManualDiscountSum,
	|	ManualPriceChangeReason,
	|	ClientType.*,
	|	NoDiscounts,
	|	Carrier.*,
	|	Manager.*}
	|FROM
	|	Document.Order AS Order
	|WHERE
	|	NOT Order.DeletionMark
	|	AND Order.Posted
	|	AND (Order.Hotel IN HIERARCHY (&qHotel)
	|			OR &qHotelIsEmpty)
	|	AND (Order.Room IN HIERARCHY (&qRoom)
	|			OR &qRoomIsEmpty)
	|	AND (Order.Client IN HIERARCHY (&qClient)
	|			OR &qClientIsEmpty)
	|	AND (Order.GuestGroup IN HIERARCHY (&qGuestGroup)
	|			OR &qGuestGroupIsEmpty)
	|	AND (Order.Type IN HIERARCHY (&qType)
	|			OR &qTypeIsEmpty)
	|	AND (Order.Service IN HIERARCHY (&qService)
	|			OR &qServiceIsEmpty)
	|	AND (&qByDateOfOrder
	|				AND (Order.OrderTime >= &qPeriodFrom
	|					OR &qPeriodFromIsEmpty)
	|				AND (Order.OrderTime <= &qPeriodTo
	|					OR &qPeriodToIsEmpty)
	|			OR NOT &qByDateOfOrder
	|				AND (Order.Date >= &qPeriodFrom
	|					OR &qPeriodFromIsEmpty)
	|				AND (Order.Date <= &qPeriodTo
	|					OR &qPeriodToIsEmpty))
	|
	|ORDER BY
	|	OrderDateFrom
	|{ORDER BY
	|	Number,
	|	Date,
	|	Type.*,
	|	Status.*,
	|	Department.*,
	|	OrderTime,
	|	OrderDateFrom,
	|	OrderDateTo,
	|	Client.*,
	|	Phone,
	|	Remarks,
	|	Author.*,
	|	Room.*,
	|	PickupFrom,
	|	Destination,
	|	GuestsQuantity,
	|	ChildSeatsNumber,
	|	TransferType.*,
	|	Vehicle.*,
	|	RentTime,
	|	RentResources.*,
	|	Hotel.*,
	|	Price,
	|	Unit,
	|	ItemsSum,
	|	Currency.*,
	|	ParentDoc.*,
	|	Service.*,
	|	GuestGroup.*,
	|	Charge.*,
	|	Employee.*,
	|	OrderPaymentType.*,
	|	Folio.*,
	|	RouteType.*,
	|	DiscountCard.*,
	|	DiscountType.*,
	|	Discount,
	|	ManualDiscountType.*,
	|	ManualDiscount,
	|	ManualDiscountSum,
	|	ManualPriceChangeReason,
	|	ClientType.*,
	|	NoDiscounts,
	|	Carrier.*,
	|	Manager.*}
	|TOTALS
	|	SUM(Quantity),
	|	SUM(Sum)
	|BY
	|	OVERALL
	|{TOTALS BY
	|	Number,
	|	Date,
	|	Type.*,
	|	Status.*,
	|	Department.*,
	|	OrderTime,
	|	OrderDateFrom,
	|	OrderDateTo,
	|	Client.*,
	|	Phone,
	|	Remarks,
	|	Author.*,
	|	Room.*,
	|	PickupFrom,
	|	Destination,
	|	GuestsQuantity,
	|	ChildSeatsNumber,
	|	TransferType.*,
	|	Vehicle.*,
	|	RentTime,
	|	RentResources.*,
	|	Hotel.*,
	|	Price,
	|	Unit,
	|	ItemsSum,
	|	Currency.*,
	|	ParentDoc.*,
	|	Service.*,
	|	GuestGroup.*,
	|	Charge.*,
	|	Employee.*,
	|	OrderPaymentType.*,
	|	Folio.*,
	|	RouteType.*,
	|	DiscountCard.*,
	|	DiscountType.*,
	|	Discount,
	|	ManualDiscountType.*,
	|	ManualDiscount,
	|	ManualDiscountSum,
	|	ManualPriceChangeReason,
	|	ClientType.*,
	|	NoDiscounts,
	|	Carrier.*,
	|	Manager.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("ru='Заказы';de='Bestellungen';en='Orders'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
