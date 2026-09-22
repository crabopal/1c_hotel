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
	If Not ValueIsFilled(AccountingDate) Then
		If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.AccountingDate) Then
			AccountingDate = BegOfDay(Hotel.AccountingDate);
		Else
			AccountingDate = BegOfDay(CurrentSessionDate());
		EndIf;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If Not ValueIsFilled(AccountingDate) Then
		vParamPresentation = vParamPresentation + NStr("en='Report period is not set';ru='Период отчета не установлен';de='Berichtszeitraum nicht festgelegt'") + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("ru = 'Дата '; en = 'Date '; de = 'Datum '") + 
		                     Format(AccountingDate, "DF=dd.MM.yyyy") + 
		                     ";" + Chars.LF;
	EndIf;
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
	If ValueIsFilled(Customer) Then
		If Not Customer.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("de='Firma ';en='Customer ';ru='Контрагент '") + 
			                     TrimAll(Customer.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("de='Firmengruppe ';en='Customers folder ';ru='Группа контрагентов '") + 
			                     TrimAll(Customer.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(Service) Then
		If Not Service.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Service ';ru='Услуга ';de='Dienstleistung '") + 
			                     TrimAll(Service.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа услуг '; en = 'Services folder '; de = 'Dienstleistungengruppe '") + 
			                     TrimAll(Service.Description) + 
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
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц ';de='Hotelsgruppe '") + 
			                     TrimAll(Hotel.Description) + 
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
	ReportBuilder.Parameters.Insert("qAccountingDate", AccountingDate);
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qRoomIsEmpty", Not ValueIsFilled(Room));
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qRoomTypeIsEmpty", Not ValueIsFilled(RoomType));
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qCustomerIsEmpty", Not ValueIsFilled(Customer));
	ReportBuilder.Parameters.Insert("qService", Service);
	ReportBuilder.Parameters.Insert("qServiceIsEmpty", Not ValueIsFilled(Service));
	vServicesList = New ValueList();
	If ValueIsFilled(ServiceGroup) Then
		If Not ServiceGroup.IncludeAll Then
			vServicesList = cmGetServiceGroupServices(ServiceGroup);
		EndIf;
	EndIf;
	ReportBuilder.Parameters.Insert("qServiceGroupIsEmpty", vServicesList.Count() = 0);
	ReportBuilder.Parameters.Insert("qServicesList", vServicesList);
	vUseForecast = True;
	If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.AccountingDate) And Hotel.AccountingDate > AccountingDate Then
		vUseForecast = False;
	EndIf;
	ReportBuilder.Parameters.Insert("qUseForecast", vUseForecast);
	ReportBuilder.Parameters.Insert("qShowMainRoomGuestsOnly", ShowMainRoomGuestsOnly);
	ReportBuilder.Parameters.Insert("qShowBBGuestsAtCheckInDate", ShowBBGuestsAtCheckInDate);
	ReportBuilder.Parameters.Insert("qShowBOGuests", ShowBOGuests);

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
	|	Rooms.Hotel AS Hotel,
	|	Rooms.AccountingDate AS AccountingDate,
	|	Rooms.Service AS Service,
	|	Rooms.ParentDoc.Guest AS Client,
	|	Rooms.ParentDoc.Customer AS Customer,
	|	Rooms.ParentDoc.Room AS Room,
	|	Rooms.ParentDoc.RoomType AS RoomType,
	|	Rooms.ParentDoc.ClientType AS ClientType,
	|	Rooms.ParentDoc.AccommodationTemplate AS AccommodationTemplate,
	|	Rooms.ParentDoc.CheckInDate AS CheckInDate,
	|	Rooms.ParentDoc.CheckOutDate AS CheckOutDate,
	|	Rooms.ParentDoc.AccommodationType AS AccommodationType,
	|	Rooms.StatusIcon AS StatusIcon,
	|	CASE
	|		WHEN ISNULL(Rooms.ParentDoc.AccommodationTemplate, VALUE(Catalog.AccommodationTemplates.EmptyRef)) <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|			THEN 1
	|		ELSE 0
	|	END AS NumberOfRooms,
	|	CASE
	|		WHEN &qShowMainRoomGuestsOnly
	|			THEN ISNULL(Rooms.ParentDoc.NumberOfAdults, 0) + ISNULL(Rooms.ParentDoc.NumberOfTeenagers, 0) + ISNULL(Rooms.ParentDoc.NumberOfChildren, 0) + ISNULL(Rooms.ParentDoc.NumberOfInfants, 0)
	|		ELSE ISNULL(Rooms.ParentDoc.NumberOfPersons, 0)
	|	END AS NumberOfPersons,
	|	CASE
	|		WHEN &qShowMainRoomGuestsOnly
	|			THEN ISNULL(Rooms.ParentDoc.NumberOfAdults, 0)
	|		WHEN NOT &qShowMainRoomGuestsOnly
	|				AND ISNULL(Rooms.ParentDoc.AccommodationTemplate, VALUE(Catalog.AccommodationTemplates.EmptyRef)) <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|			THEN ISNULL(Rooms.ParentDoc.NumberOfAdults, 0)
	|		ELSE 0
	|	END AS NumberOfAdults,
	|	CASE
	|		WHEN &qShowMainRoomGuestsOnly
	|			THEN ISNULL(Rooms.ParentDoc.NumberOfTeenagers, 0)
	|		WHEN NOT &qShowMainRoomGuestsOnly
	|				AND ISNULL(Rooms.ParentDoc.AccommodationTemplate, VALUE(Catalog.AccommodationTemplates.EmptyRef)) <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|			THEN ISNULL(Rooms.ParentDoc.NumberOfTeenagers, 0)
	|		ELSE 0
	|	END AS NumberOfTeenagers,
	|	CASE
	|		WHEN &qShowMainRoomGuestsOnly
	|			THEN ISNULL(Rooms.ParentDoc.NumberOfChildren, 0)
	|		WHEN NOT &qShowMainRoomGuestsOnly
	|				AND ISNULL(Rooms.ParentDoc.AccommodationTemplate, VALUE(Catalog.AccommodationTemplates.EmptyRef)) <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|			THEN ISNULL(Rooms.ParentDoc.NumberOfChildren, 0)
	|		ELSE 0
	|	END AS NumberOfChildren,
	|	CASE
	|		WHEN &qShowMainRoomGuestsOnly
	|			THEN ISNULL(Rooms.ParentDoc.NumberOfInfants, 0)
	|		WHEN NOT &qShowMainRoomGuestsOnly
	|				AND ISNULL(Rooms.ParentDoc.AccommodationTemplate, VALUE(Catalog.AccommodationTemplates.EmptyRef)) <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|			THEN ISNULL(Rooms.ParentDoc.NumberOfInfants, 0)
	|		ELSE 0
	|	END AS NumberOfInfants,
	|	ServiceRegistrations.NumberOfBreakfasts AS NumberOfBreakfasts,
	|	ServiceRegistrations.NumberOfLunches AS NumberOfLunches,
	|	ServiceRegistrations.NumberOfDinners AS NumberOfDinners
	|{SELECT
	|	Hotel.* AS Hotel,
	|	AccountingDate AS AccountingDate,
	|	Room.* AS Room,
	|	RoomType.* AS RoomType,
	|	Rooms.ParentDoc.Resource.* AS Resource,
	|	Service.* AS Service,
	|	Client.* AS Client,
	|	ClientType.* AS ClientType,
	|	Customer.* AS Customer,
	|	Rooms.ParentDoc.DiscountType.* AS DiscountType,
	|	AccommodationType.* AS AccommodationType,
	|	Rooms.ParentDoc.GuestGroup.* AS GuestGroup,
	|	AccommodationTemplate.* AS AccommodationTemplate,
	|	CheckInDate AS CheckInDate,
	|	CheckOutDate AS CheckOutDate,
	|	Rooms.ParentDoc.* AS ParentDoc,
	|	StatusIcon AS StatusIcon,
	|	NumberOfRooms AS NumberOfRooms,
	|	NumberOfPersons AS NumberOfPersons,
	|	NumberOfAdults AS NumberOfAdults,
	|	NumberOfTeenagers AS NumberOfTeenagers,
	|	NumberOfChildren AS NumberOfChildren,
	|	NumberOfInfants AS NumberOfInfants,
	|	NumberOfBreakfasts AS NumberOfBreakfasts,
	|	NumberOfLunches AS NumberOfLunches,
	|	NumberOfDinners AS NumberOfDinners}
	|FROM
	|	(SELECT
	|		Services.Hotel AS Hotel,
	|		Services.AccountingDate AS AccountingDate,
	|		Services.ParentDoc AS ParentDoc,
	|		Services.Service AS Service,
	|		Services.StatusIcon AS StatusIcon
	|	FROM
	|		(SELECT
	|			SalesMovements.Hotel AS Hotel,
	|			SalesMovements.ServiceDate AS AccountingDate,
	|			SalesMovements.ParentDoc AS ParentDoc,
	|			CASE
	|				WHEN SalesMovements.ParentDoc REFS Document.Accommodation
	|						AND ISNULL(SalesMovements.ParentDoc.AccommodationStatus.IsInHouse, FALSE)
	|					THEN """"
	|				WHEN SalesMovements.ParentDoc REFS Document.Accommodation
	|						AND NOT ISNULL(SalesMovements.ParentDoc.AccommodationStatus.IsInHouse, FALSE)
	|					THEN ""OUT""
	|				ELSE """"
	|			END AS StatusIcon,
	|			CASE
	|				WHEN NOT TermsUpgrade.Service IS NULL
	|					THEN TermsUpgrade.Service.UpgradeToTerms
	|				WHEN NOT TermsUpgradeForecast.Service IS NULL
	|					THEN TermsUpgradeForecast.Service.UpgradeToTerms
	|				ELSE SalesMovements.Service
	|			END AS Service
	|		FROM
	|			AccumulationRegister.Sales AS SalesMovements
	|				LEFT JOIN AccumulationRegister.Sales AS TermsUpgrade
	|				ON SalesMovements.ServiceDate = TermsUpgrade.ServiceDate
	|					AND (SalesMovements.Service = TermsUpgrade.Service.UpgradeFromTerms
	|						OR TermsUpgrade.Service.UpgradeFromTerms = VALUE(Catalog.Services.EmptyRef))
	|					AND (SalesMovements.ParentDoc = TermsUpgrade.ParentDoc
	|							AND NOT SalesMovements.ParentDoc.Number IS NULL
	|						OR SalesMovements.ParentDoc.Reservation = TermsUpgrade.ParentDoc
	|							AND NOT SalesMovements.ParentDoc.Reservation.Number IS NULL)
	|					AND (NOT TermsUpgrade.Service.UpgradeToTerms.Code IS NULL)
	|					AND (&qHotelIsEmpty
	|						OR TermsUpgrade.Hotel IN HIERARCHY (&qHotel))
	|				LEFT JOIN AccumulationRegister.SalesForecast AS TermsUpgradeForecast
	|				ON SalesMovements.ServiceDate = TermsUpgradeForecast.ServiceDate
	|					AND (SalesMovements.Service = TermsUpgradeForecast.Service.UpgradeFromTerms
	|						OR TermsUpgradeForecast.Service.UpgradeFromTerms = VALUE(Catalog.Services.EmptyRef))
	|					AND (SalesMovements.ParentDoc = TermsUpgradeForecast.ParentDoc
	|							AND NOT SalesMovements.ParentDoc.Number IS NULL
	|						OR SalesMovements.ParentDoc.Reservation = TermsUpgradeForecast.ParentDoc
	|							AND NOT SalesMovements.ParentDoc.Reservation.Number IS NULL)
	|					AND (NOT TermsUpgradeForecast.Service.UpgradeToTerms.Code IS NULL)
	|					AND (&qHotelIsEmpty
	|						OR TermsUpgradeForecast.Hotel IN HIERARCHY (&qHotel))
	|					AND (TermsUpgrade.Service IS NULL)
	|		WHERE
	|			CASE
	|					WHEN SalesMovements.ServicePackage.IsMealBoardTerm
	|							AND NOT(SalesMovements.ServicePackage.IsBB
	|									OR SalesMovements.ServicePackage.IsHB
	|									OR SalesMovements.ServicePackage.IsFB
	|									OR SalesMovements.ServicePackage.IsAI
	|									OR SalesMovements.ServicePackage.IsUAI
	|									OR SalesMovements.ServicePackage.IsFC
	|									OR &qShowBOGuests)
	|						THEN FALSE
	|					WHEN SalesMovements.ServicePackage.IsMealBoardTerm
	|							AND SalesMovements.ServicePackage.IsBB
	|							AND NOT &qShowBBGuestsAtCheckInDate
	|							AND BEGINOFPERIOD(SalesMovements.ParentDoc.CheckInDate, DAY) = &qAccountingDate
	|						THEN DATEADD(SalesMovements.ServiceDate, DAY, 1) = &qAccountingDate
	|					WHEN SalesMovements.ServicePackage.IsMealBoardTerm
	|							AND SalesMovements.ServicePackage.IsBB
	|							AND &qShowBBGuestsAtCheckInDate
	|							AND BEGINOFPERIOD(SalesMovements.ParentDoc.CheckInDate, DAY) = &qAccountingDate
	|						THEN SalesMovements.ServiceDate = &qAccountingDate
	|					WHEN SalesMovements.ServicePackage.IsMealBoardTerm
	|							AND BEGINOFPERIOD(SalesMovements.ParentDoc.CheckOutDate, DAY) = &qAccountingDate
	|							AND (SalesMovements.ServicePackage.IsBB
	|								OR SalesMovements.ServicePackage.IsHB
	|								OR SalesMovements.ServicePackage.IsFB
	|								OR SalesMovements.ServicePackage.IsAI
	|								OR SalesMovements.ServicePackage.IsUAI
	|								OR SalesMovements.ServicePackage.IsFC
	|								OR &qShowBOGuests)
	|						THEN DATEADD(SalesMovements.ServiceDate, DAY, 1) = &qAccountingDate
	|					ELSE SalesMovements.ServiceDate = &qAccountingDate
	|				END
	|			AND (&qHotelIsEmpty
	|					OR SalesMovements.Hotel IN HIERARCHY (&qHotel))
	|			AND (&qRoomIsEmpty
	|					OR SalesMovements.Room IN HIERARCHY (&qRoom))
	|			AND (&qRoomTypeIsEmpty
	|					OR SalesMovements.RoomType IN HIERARCHY (&qRoomType))
	|			AND (&qCustomerIsEmpty
	|					OR SalesMovements.ParentDoc.Customer IN HIERARCHY (&qCustomer))
	|			AND (NOT &qServiceGroupIsEmpty
	|						AND SalesMovements.Service IN (&qServicesList)
	|						AND (&qServiceIsEmpty
	|							OR SalesMovements.Service IN HIERARCHY (&qService))
	|					OR &qServiceGroupIsEmpty
	|						AND NOT &qServiceIsEmpty
	|						AND SalesMovements.Service IN HIERARCHY (&qService)
	|					OR &qServiceGroupIsEmpty
	|						AND &qServiceIsEmpty
	|						AND SalesMovements.GuestDays <> 0)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			SalesForecastMovements.Hotel,
	|			SalesForecastMovements.ServiceDate,
	|			SalesForecastMovements.ParentDoc,
	|			CASE
	|				WHEN SalesForecastMovements.ParentDoc REFS Document.Accommodation
	|						AND ISNULL(SalesForecastMovements.ParentDoc.AccommodationStatus.IsInHouse, FALSE)
	|					THEN """"
	|				WHEN SalesForecastMovements.ParentDoc REFS Document.Accommodation
	|						AND NOT ISNULL(SalesForecastMovements.ParentDoc.AccommodationStatus.IsInHouse, FALSE)
	|					THEN ""OUT""
	|				WHEN SalesForecastMovements.ParentDoc REFS Document.Reservation
	|					THEN ""EXP""
	|				ELSE """"
	|			END,
	|			CASE
	|				WHEN NOT TermsUpgrade.Service IS NULL
	|					THEN TermsUpgrade.Service.UpgradeToTerms
	|				WHEN NOT TermsUpgradeForecast.Service IS NULL
	|					THEN TermsUpgradeForecast.Service.UpgradeToTerms
	|				ELSE SalesForecastMovements.Service
	|			END
	|		FROM
	|			AccumulationRegister.SalesForecast AS SalesForecastMovements
	|				LEFT JOIN AccumulationRegister.Sales AS TermsUpgrade
	|				ON SalesForecastMovements.ServiceDate = TermsUpgrade.ServiceDate
	|					AND (SalesForecastMovements.Service = TermsUpgrade.Service.UpgradeFromTerms
	|						OR TermsUpgrade.Service.UpgradeFromTerms = VALUE(Catalog.Services.EmptyRef))
	|					AND (SalesForecastMovements.ParentDoc = TermsUpgrade.ParentDoc
	|							AND NOT SalesForecastMovements.ParentDoc.Number IS NULL
	|						OR SalesForecastMovements.ParentDoc.Reservation = TermsUpgrade.ParentDoc
	|							AND NOT SalesForecastMovements.ParentDoc.Reservation.Number IS NULL)
	|					AND (NOT TermsUpgrade.Service.UpgradeToTerms.Code IS NULL)
	|					AND (&qHotelIsEmpty
	|						OR TermsUpgrade.Hotel IN HIERARCHY (&qHotel))
	|				LEFT JOIN AccumulationRegister.SalesForecast AS TermsUpgradeForecast
	|				ON SalesForecastMovements.ServiceDate = TermsUpgradeForecast.ServiceDate
	|					AND (SalesForecastMovements.Service = TermsUpgradeForecast.Service.UpgradeFromTerms
	|						OR TermsUpgradeForecast.Service.UpgradeFromTerms = VALUE(Catalog.Services.EmptyRef))
	|					AND (SalesForecastMovements.ParentDoc = TermsUpgradeForecast.ParentDoc
	|							AND NOT SalesForecastMovements.ParentDoc.Number IS NULL
	|						OR SalesForecastMovements.ParentDoc.Reservation = TermsUpgradeForecast.ParentDoc
	|							AND NOT SalesForecastMovements.ParentDoc.Reservation.Number IS NULL)
	|					AND (NOT TermsUpgradeForecast.Service.UpgradeToTerms.Code IS NULL)
	|					AND (&qHotelIsEmpty
	|						OR TermsUpgradeForecast.Hotel IN HIERARCHY (&qHotel))
	|					AND (TermsUpgrade.Service IS NULL)
	|		WHERE
	|			CASE
	|					WHEN SalesForecastMovements.ServicePackage.IsMealBoardTerm
	|							AND NOT(SalesForecastMovements.ServicePackage.IsBB
	|									OR SalesForecastMovements.ServicePackage.IsHB
	|									OR SalesForecastMovements.ServicePackage.IsFB
	|									OR SalesForecastMovements.ServicePackage.IsAI
	|									OR SalesForecastMovements.ServicePackage.IsUAI
	|									OR SalesForecastMovements.ServicePackage.IsFC
	|									OR &qShowBOGuests)
	|						THEN FALSE
	|					WHEN SalesForecastMovements.ServicePackage.IsMealBoardTerm
	|							AND SalesForecastMovements.ServicePackage.IsBB
	|							AND NOT &qShowBBGuestsAtCheckInDate
	|							AND BEGINOFPERIOD(SalesForecastMovements.ParentDoc.CheckInDate, DAY) = &qAccountingDate
	|						THEN DATEADD(SalesForecastMovements.ServiceDate, DAY, 1) = &qAccountingDate
	|					WHEN SalesForecastMovements.ServicePackage.IsMealBoardTerm
	|							AND SalesForecastMovements.ServicePackage.IsBB
	|							AND &qShowBBGuestsAtCheckInDate
	|							AND BEGINOFPERIOD(SalesForecastMovements.ParentDoc.CheckInDate, DAY) = &qAccountingDate
	|						THEN SalesForecastMovements.ServiceDate = &qAccountingDate
	|					WHEN SalesForecastMovements.ServicePackage.IsMealBoardTerm
	|							AND BEGINOFPERIOD(SalesForecastMovements.ParentDoc.CheckOutDate, DAY) = &qAccountingDate
	|							AND (SalesForecastMovements.ServicePackage.IsBB
	|								OR SalesForecastMovements.ServicePackage.IsHB
	|								OR SalesForecastMovements.ServicePackage.IsFB
	|								OR SalesForecastMovements.ServicePackage.IsAI
	|								OR SalesForecastMovements.ServicePackage.IsUAI
	|								OR SalesForecastMovements.ServicePackage.IsFC
	|								OR &qShowBOGuests)
	|						THEN DATEADD(SalesForecastMovements.ServiceDate, DAY, 1) = &qAccountingDate
	|					ELSE SalesForecastMovements.ServiceDate = &qAccountingDate
	|				END
	|			AND (&qHotelIsEmpty
	|					OR SalesForecastMovements.Hotel IN HIERARCHY (&qHotel))
	|			AND (&qRoomIsEmpty
	|					OR SalesForecastMovements.Room IN HIERARCHY (&qRoom))
	|			AND (&qRoomTypeIsEmpty
	|					OR SalesForecastMovements.RoomType IN HIERARCHY (&qRoomType))
	|			AND (&qCustomerIsEmpty
	|					OR SalesForecastMovements.ParentDoc.Customer IN HIERARCHY (&qCustomer))
	|			AND (NOT &qServiceGroupIsEmpty
	|						AND SalesForecastMovements.Service IN (&qServicesList)
	|						AND (&qServiceIsEmpty
	|							OR SalesForecastMovements.Service IN HIERARCHY (&qService))
	|					OR &qServiceGroupIsEmpty
	|						AND NOT &qServiceIsEmpty
	|						AND SalesForecastMovements.Service IN HIERARCHY (&qService)
	|					OR &qServiceGroupIsEmpty
	|						AND &qServiceIsEmpty
	|						AND SalesForecastMovements.GuestDays <> 0)
	|			AND &qUseForecast) AS Services
	|	
	|	GROUP BY
	|		Services.Hotel,
	|		Services.AccountingDate,
	|		Services.ParentDoc,
	|		Services.Service,
	|		Services.StatusIcon) AS Rooms
	|		LEFT JOIN (SELECT
	|			Registrations.Hotel AS Hotel,
	|			Registrations.AccountingDate AS AccountingDate,
	|			Registrations.ParentDoc AS ParentDoc,
	|			SUM(CASE
	|					WHEN Registrations.MealType = VALUE(Enum.MealTypes.Breakfast)
	|						THEN Registrations.Quantity
	|					ELSE 0
	|				END) AS NumberOfBreakfasts,
	|			SUM(CASE
	|					WHEN Registrations.MealType = VALUE(Enum.MealTypes.Lunch)
	|						THEN Registrations.Quantity
	|					ELSE 0
	|				END) AS NumberOfLunches,
	|			SUM(CASE
	|					WHEN Registrations.MealType = VALUE(Enum.MealTypes.Dinner)
	|						THEN Registrations.Quantity
	|					ELSE 0
	|				END) AS NumberOfDinners
	|		FROM
	|			Document.ServiceRegistration AS Registrations
	|		WHERE
	|			Registrations.Posted
	|			AND Registrations.AccountingDate = &qAccountingDate
	|			AND Registrations.Hotel = &qHotel
	|		
	|		GROUP BY
	|			Registrations.Hotel,
	|			Registrations.AccountingDate,
	|			Registrations.ParentDoc) AS ServiceRegistrations
	|		ON (ServiceRegistrations.Hotel = Rooms.Hotel)
	|			AND (ServiceRegistrations.AccountingDate = Rooms.AccountingDate)
	|			AND (ServiceRegistrations.ParentDoc = Rooms.ParentDoc)
	|WHERE
	|	(NOT &qShowMainRoomGuestsOnly
	|			OR &qShowMainRoomGuestsOnly
	|				AND ISNULL(Rooms.ParentDoc.AccommodationTemplate, VALUE(Catalog.AccommodationTemplates.EmptyRef)) <> VALUE(Catalog.AccommodationTemplates.EmptyRef))
	|{WHERE
	|	Rooms.Hotel.* AS Hotel,
	|	Rooms.AccountingDate AS AccountingDate,
	|	Rooms.ParentDoc.Room.* AS Room,
	|	Rooms.ParentDoc.RoomType.* AS RoomType,
	|	Rooms.ParentDoc.Resource.* AS Resource,
	|	Rooms.Service.* AS Service,
	|	Rooms.ParentDoc.Guest.* AS Client,
	|	Rooms.ParentDoc.ClientType.* AS ClientType,
	|	Rooms.ParentDoc.Customer.* AS Customer,
	|	Rooms.ParentDoc.DiscountType.* AS DiscountType,
	|	Rooms.ParentDoc.AccommodationType.* AS AccommodationType,
	|	Rooms.ParentDoc.GuestGroup.* AS GuestGroup,
	|	Rooms.ParentDoc.AccommodationTemplate.* AS AccommodationTemplate,
	|	Rooms.ParentDoc.CheckInDate AS CheckInDate,
	|	Rooms.ParentDoc.CheckOutDate AS CheckOutDate,
	|	Rooms.ParentDoc.* AS ParentDoc,
	|	(CASE
	|			WHEN ISNULL(Rooms.ParentDoc.AccommodationTemplate, VALUE(Catalog.AccommodationTemplates.EmptyRef)) <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|				THEN 1
	|			ELSE 0
	|		END) AS NumberOfRooms,
	|	(CASE
	|			WHEN &qShowMainRoomGuestsOnly
	|				THEN ISNULL(Rooms.ParentDoc.NumberOfAdults, 0) + ISNULL(Rooms.ParentDoc.NumberOfTeenagers, 0) + ISNULL(Rooms.ParentDoc.NumberOfChildren, 0) + ISNULL(Rooms.ParentDoc.NumberOfInfants, 0)
	|			ELSE ISNULL(Rooms.ParentDoc.NumberOfPersons, 0)
	|		END) AS NumberOfPersons,
	|	(CASE
	|			WHEN &qShowMainRoomGuestsOnly
	|				THEN ISNULL(Rooms.ParentDoc.NumberOfAdults, 0)
	|			WHEN NOT &qShowMainRoomGuestsOnly
	|					AND ISNULL(Rooms.ParentDoc.AccommodationTemplate, VALUE(Catalog.AccommodationTemplates.EmptyRef)) <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|				THEN ISNULL(Rooms.ParentDoc.NumberOfAdults, 0)
	|			ELSE 0
	|		END) AS NumberOfAdults,
	|	(CASE
	|			WHEN &qShowMainRoomGuestsOnly
	|				THEN ISNULL(Rooms.ParentDoc.NumberOfTeenagers, 0)
	|			WHEN NOT &qShowMainRoomGuestsOnly
	|					AND ISNULL(Rooms.ParentDoc.AccommodationTemplate, VALUE(Catalog.AccommodationTemplates.EmptyRef)) <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|				THEN ISNULL(Rooms.ParentDoc.NumberOfTeenagers, 0)
	|			ELSE 0
	|		END) AS NumberOfTeenagers,
	|	(CASE
	|			WHEN &qShowMainRoomGuestsOnly
	|				THEN ISNULL(Rooms.ParentDoc.NumberOfChildren, 0)
	|			WHEN NOT &qShowMainRoomGuestsOnly
	|					AND ISNULL(Rooms.ParentDoc.AccommodationTemplate, VALUE(Catalog.AccommodationTemplates.EmptyRef)) <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|				THEN ISNULL(Rooms.ParentDoc.NumberOfChildren, 0)
	|			ELSE 0
	|		END) AS NumberOfChildren,
	|	(CASE
	|			WHEN &qShowMainRoomGuestsOnly
	|				THEN ISNULL(Rooms.ParentDoc.NumberOfInfants, 0)
	|			WHEN NOT &qShowMainRoomGuestsOnly
	|					AND ISNULL(Rooms.ParentDoc.AccommodationTemplate, VALUE(Catalog.AccommodationTemplates.EmptyRef)) <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|				THEN ISNULL(Rooms.ParentDoc.NumberOfInfants, 0)
	|			ELSE 0
	|		END) AS NumberOfInfants,
	|	ServiceRegistrations.NumberOfBreakfasts AS NumberOfBreakfasts,
	|	ServiceRegistrations.NumberOfLunches AS NumberOfLunches,
	|	ServiceRegistrations.NumberOfDinners AS NumberOfDinners}
	|
	|ORDER BY
	|	Hotel,
	|	Room,
	|	CheckInDate,
	|	AccommodationType
	|{ORDER BY
	|	Hotel.* AS Hotel,
	|	AccountingDate AS AccountingDate,
	|	Room.* AS Room,
	|	RoomType.* AS RoomType,
	|	Rooms.ParentDoc.Resource.* AS Resource,
	|	Service.* AS Service,
	|	Client.* AS Client,
	|	ClientType.* AS ClientType,
	|	Customer.* AS Customer,
	|	Rooms.ParentDoc.DiscountType.* AS DiscountType,
	|	AccommodationType.* AS AccommodationType,
	|	Rooms.ParentDoc.GuestGroup.* AS GuestGroup,
	|	AccommodationTemplate.* AS AccommodationTemplate,
	|	CheckInDate AS CheckInDate,
	|	CheckOutDate AS CheckOutDate,
	|	Rooms.ParentDoc.* AS ParentDoc,
	|	StatusIcon AS StatusIcon,
	|	NumberOfPersons AS NumberOfPersons,
	|	NumberOfAdults AS NumberOfAdults,
	|	NumberOfTeenagers AS NumberOfTeenagers,
	|	NumberOfChildren AS NumberOfChildren,
	|	NumberOfInfants AS NumberOfInfants,
	|	NumberOfBreakfasts AS NumberOfBreakfasts,
	|	NumberOfLunches AS NumberOfLunches,
	|	NumberOfDinners AS NumberOfDinners}
	|TOTALS
	|	SUM(NumberOfRooms),
	|	SUM(NumberOfPersons),
	|	SUM(NumberOfAdults),
	|	SUM(NumberOfTeenagers),
	|	SUM(NumberOfChildren),
	|	SUM(NumberOfInfants),
	|	SUM(NumberOfBreakfasts),
	|	SUM(NumberOfLunches),
	|	SUM(NumberOfDinners)
	|BY
	|	OVERALL
	|{TOTALS BY
	|	Hotel.* AS Hotel,
	|	Room.* AS Room,
	|	RoomType.* AS RoomType,
	|	Rooms.ParentDoc.Resource.* AS Resource,
	|	Service.* AS Service,
	|	Client.* AS Client,
	|	ClientType.* AS ClientType,
	|	Customer.* AS Customer,
	|	Rooms.ParentDoc.DiscountType.* AS DiscountType,
	|	Rooms.ParentDoc.GuestGroup.* AS GuestGroup,
	|	AccommodationTemplate.* AS AccommodationTemplate,
	|	Rooms.ParentDoc.* AS ParentDoc}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("ru='Список гостей на питание';de='Restaurant-Kontrollliste';en='Restaurant control list'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
