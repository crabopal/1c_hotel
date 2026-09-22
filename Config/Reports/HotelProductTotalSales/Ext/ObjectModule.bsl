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
		PeriodFrom = BegOfMonth(CurrentSessionDate()); // For beg of month
		PeriodTo = EndOfDay(CurrentSessionDate());
	EndIf;
	// Initialie flags
	If Not ShowHotelProductTotalAmount And 
	   Not ShowHotelProductSales And 
	   Not ShowHotelProductAccountsReceivable And 
	   Not ShowGuestGroupPayments Then
		ShowHotelProductTotalAmount = True;
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
	If ValueIsFilled(HotelProduct) Then
		If Not HotelProduct.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Путевка '; en = 'Hotel product '; de = 'Einweisung '") + 
			                     TrimAll(HotelProduct.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Тип путевок/курсовок '; en = 'Vaucher type '; de = 'Einweisungtyp '") + 
			                     TrimAll(HotelProduct.Description) + 
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
							 TrimAll(GuestGroup.Code) + 
							 ";" + Chars.LF;
	EndIf;							 
	If ValueIsFilled(ServiceGroup) Then
		If Not ServiceGroup.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Набор услуг '; en = 'Service group '; en = 'Dienstgruppe '") + 
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
Procedure pmGenerate(pSpreadsheet, pAddChart = False) Export
	Var vTemplateAttributes;
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Fill report parameters
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qPrevPeriodFrom", BegOfMonth(BegOfMonth(PeriodFrom) - 1));
	ReportBuilder.Parameters.Insert("qPrevPeriodTo", PeriodFrom - 1);
	ReportBuilder.Parameters.Insert("qNextPeriodFrom", PeriodTo + 1);
	ReportBuilder.Parameters.Insert("qNextPeriodTo", EndOfMonth(EndOfMonth(PeriodTo) + 1));
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	ReportBuilder.Parameters.Insert("qIsEmptyCustomer", Not ValueIsFilled(Customer));
	ReportBuilder.Parameters.Insert("qContract", Contract);
	ReportBuilder.Parameters.Insert("qEmptyContract", Catalogs.Contracts.EmptyRef());
	ReportBuilder.Parameters.Insert("qIsEmptyContract", Not ValueIsFilled(Contract));
	ReportBuilder.Parameters.Insert("qHotelProduct", HotelProduct);
	ReportBuilder.Parameters.Insert("qIsEmptyHotelProduct", Not ValueIsFilled(HotelProduct));
	ReportBuilder.Parameters.Insert("qEmptyHotelProduct", Catalogs.HotelProducts.EmptyRef());
	ReportBuilder.Parameters.Insert("qGuestGroup", GuestGroup);
	ReportBuilder.Parameters.Insert("qIsEmptyGuestGroup", Not ValueIsFilled(GuestGroup));
	ReportBuilder.Parameters.Insert("qEmptyPaymentMethod", Catalogs.PaymentMethods.EmptyRef());
	ReportBuilder.Parameters.Insert("qDurationCalculationRuleTypeByDays", Enums.DurationCalculationRuleTypes.ByDays);
	ReportBuilder.Parameters.Insert("qTogether", Enums.AccomodationTypes.Together);
	ReportBuilder.Parameters.Insert("qAdditionalBed", Enums.AccomodationTypes.AdditionalBed);
	ReportBuilder.Parameters.Insert("qEmptyRoom", Catalogs.Rooms.EmptyRef());
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
	ReportBuilder.Parameters.Insert("qShowHotelProductTotalAmount", ShowHotelProductTotalAmount);
	ReportBuilder.Parameters.Insert("qShowHotelProductSales", ShowHotelProductSales);
	ReportBuilder.Parameters.Insert("qShowHotelProductAccountsReceivable", ShowHotelProductAccountsReceivable);
	ReportBuilder.Parameters.Insert("qShowGuestGroupPayments", ShowGuestGroupPayments);
	ReportBuilder.Parameters.Insert("qEmptyPaymentSection", Catalogs.PaymentSections.EmptyRef());
	ReportBuilder.Parameters.Insert("qDepositTransfer", Catalogs.PaymentMethods.DepositTransfer);
	ReportBuilder.Parameters.Insert("qShowDifferencesOnly", ShowDifferencesOnly);
	ReportBuilder.Parameters.Insert("qSplitPaymentsByColumns", SplitPaymentsByColumns);
	If IsBlankString(Hotel.AdditionalServicesFolioCondition) Then
		ReportBuilder.Parameters.Insert("qFolioFilter", "~!999999999999");
	Else
		ReportBuilder.Parameters.Insert("qFolioFilter", "%" + TrimAll(Hotel.AdditionalServicesFolioCondition) + "%");
	EndIf;
	If ShowHotelProductTotalAmountByCreateDate Then
		ReportBuilder.Parameters.Insert("qTotalsPeriodFrom", Undefined);
		ReportBuilder.Parameters.Insert("qTotalsPeriodTo", Undefined);
	Else
		ReportBuilder.Parameters.Insert("qTotalsPeriodFrom", PeriodFrom);
		ReportBuilder.Parameters.Insert("qTotalsPeriodTo", PeriodTo);
	EndIf;
	ReportBuilder.Parameters.Insert("qShowHotelProductTotalAmountByCreateDate", ShowHotelProductTotalAmountByCreateDate);
	
	// Execute report builder query
	ReportBuilder.Execute();
	
	// Apply appearance settings to the report template
	vTemplateAttributes = cmApplyReportTemplateAppearance(ThisObject);
	
	// Output report to the spreadsheet
	ReportBuilder.Put(pSpreadsheet);
	//ReportBuilder.Template.Show(); // For debug purpose

	// Apply appearance settings to the report spreadsheet
	cmApplyReportAppearance(ThisObject, pSpreadsheet, vTemplateAttributes);
	
	// Add chart 
	If pAddChart Then
		cmAddReportChart(pSpreadsheet, ThisObject);
	EndIf;
EndProcedure // pmGenerate
	
// -----------------------------------------------------------------------------
Procedure pmInitializeReportBuilder() Export
	ReportBuilder = New ReportBuilder();
	
	// Initialize default query text
	QueryText = 
	"SELECT
	|	HotelProductGroups.GuestGroup AS GuestGroup,
	|	HotelProductGroups.Folio AS Folio
	|INTO HotelProductGroups
	|FROM
	|	AccumulationRegister.HotelProductSales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			Hotel IN HIERARCHY (&qHotel)
	|				AND (CASE
	|						WHEN Customer = &qEmptyCustomer
	|							THEN Hotel.IndividualsCustomer
	|						ELSE Customer
	|					END IN HIERARCHY (&qCustomer)
	|					OR &qIsEmptyCustomer)
	|				AND (Contract = &qContract
	|					OR &qIsEmptyContract)
	|				AND (GuestGroup = &qGuestGroup
	|					OR &qIsEmptyGuestGroup)
	|				AND (HotelProduct IN HIERARCHY (&qHotelProduct)
	|					OR &qIsEmptyHotelProduct)
	|				AND (Service IN (&qServicesList)
	|					OR NOT &qUseServicesList)) AS HotelProductGroups
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	HotelProductTotalSalesTurnovers.ReportingCurrency AS ReportingCurrency,
	|	HotelProductTotalSalesTurnovers.Hotel AS Hotel,
	|	HotelProductTotalSalesTurnovers.HotelProduct AS HotelProduct,
	|	HotelProductTotalSalesTurnovers.Agent AS Agent,
	|	CASE
	|		WHEN HotelProductTotalSalesTurnovers.Customer = &qEmptyCustomer
	|			THEN HotelProductTotalSalesTurnovers.Hotel.IndividualsCustomer
	|		ELSE HotelProductTotalSalesTurnovers.Customer
	|	END AS Customer,
	|	CASE
	|		WHEN HotelProductTotalSalesTurnovers.Customer = &qEmptyCustomer
	|				AND HotelProductTotalSalesTurnovers.Contract = &qEmptyContract
	|			THEN HotelProductTotalSalesTurnovers.Hotel.IndividualsContract
	|		ELSE HotelProductTotalSalesTurnovers.Contract
	|	END AS Contract,
	|	HotelProductTotalSalesTurnovers.GuestGroup AS GuestGroup,
	|	HotelProductTotalSalesTurnovers.Client AS Client,
	|	CASE
	|		WHEN NOT HotelProductTotalSalesTurnovers.Folio.HotelProduct IS NULL
	|				AND HotelProductTotalSalesTurnovers.Folio.HotelProduct <> &qEmptyHotelProduct
	|			THEN HotelProductTotalSalesTurnovers.Folio
	|		WHEN NOT HotelProductTotalSalesTurnovers.ParentDoc IS NULL
	|			THEN HotelProductTotalSalesTurnovers.ParentDoc
	|		ELSE HotelProductTotalSalesTurnovers.Folio
	|	END AS ParentDoc,
	|	HotelProductTotalSalesTurnovers.ParentDoc.NumberOfPersons AS NumberOfPersons,
	|	CASE
	|		WHEN NOT &qSplitPaymentsByColumns
	|			THEN HotelProductTotalSalesTurnovers.PaymentMethod
	|		ELSE &qEmptyPaymentMethod
	|	END AS PaymentMethod,
	|	HotelProductTotalSalesTurnovers.Folio.Room AS Room,
	|	HotelProductTotalSalesTurnovers.ParentDoc.RoomRate AS RoomRate,
	|	HotelProductTotalSalesTurnovers.ParentDoc.AccommodationType AS AccommodationType,
	|	HotelProductTotalSalesTurnovers.ParentDoc.ClientType AS ClientType,
	|	HotelProductTotalSalesTurnovers.ParentDoc.MarketingCode AS MarketingCode,
	|	HotelProductTotalSalesTurnovers.ParentDoc.SourceOfBusiness AS SourceOfBusiness,
	|	HotelProductTotalSalesTurnovers.ParentDoc.TripPurpose AS TripPurpose,
	|	HotelProductTotalSalesTurnovers.ParentDoc.DiscountType AS DiscountType,
	|	CASE
	|		WHEN NOT HotelProductTotalSalesTurnovers.ParentDoc.CheckInDate IS NULL
	|			THEN HotelProductTotalSalesTurnovers.ParentDoc.CheckInDate
	|		WHEN NOT HotelProductTotalSalesTurnovers.Folio.DateTimeFrom IS NULL
	|			THEN HotelProductTotalSalesTurnovers.Folio.DateTimeFrom
	|		WHEN NOT HotelProductTotalSalesTurnovers.ParentDoc.DateTimeFrom IS NULL
	|			THEN HotelProductTotalSalesTurnovers.ParentDoc.DateTimeFrom
	|		ELSE &qEmptyDate
	|	END AS CheckInDate,
	|	CASE
	|		WHEN NOT HotelProductTotalSalesTurnovers.ParentDoc.CheckOutDate IS NULL
	|			THEN HotelProductTotalSalesTurnovers.ParentDoc.CheckOutDate
	|		WHEN NOT HotelProductTotalSalesTurnovers.Folio.DateTimeTo IS NULL
	|			THEN HotelProductTotalSalesTurnovers.Folio.DateTimeTo
	|		WHEN NOT HotelProductTotalSalesTurnovers.ParentDoc.DateTimeTo IS NULL
	|			THEN HotelProductTotalSalesTurnovers.ParentDoc.DateTimeTo
	|		ELSE &qEmptyDate
	|	END AS CheckOutDate,
	|	HotelProductTotalSalesTurnovers.SalesTurnover AS Sales,
	|	HotelProductTotalSalesTurnovers.RoomRevenueTurnover AS RoomRevenue,
	|	HotelProductTotalSalesTurnovers.SalesWithoutVATTurnover AS SalesWithoutVAT,
	|	HotelProductTotalSalesTurnovers.RoomRevenueWithoutVATTurnover AS RoomRevenueWithoutVAT,
	|	HotelProductTotalSalesTurnovers.CommissionSumTurnover AS CommissionSum,
	|	HotelProductTotalSalesTurnovers.CommissionSumWithoutVATTurnover AS CommissionSumWithoutVAT,
	|	HotelProductTotalSalesTurnovers.DiscountSumTurnover AS DiscountSum,
	|	HotelProductTotalSalesTurnovers.DiscountSumWithoutVATTurnover AS DiscountSumWithoutVAT,
	|	HotelProductTotalSalesTurnovers.RoomsRentedTurnover AS RoomsRented,
	|	HotelProductTotalSalesTurnovers.BedsRentedTurnover AS BedsRented,
	|	HotelProductTotalSalesTurnovers.AdditionalBedsRentedTurnover AS AdditionalBedsRented,
	|	HotelProductTotalSalesTurnovers.GuestDaysTurnover AS GuestDays,
	|	HotelProductTotalSalesTurnovers.GuestsCheckedInTurnover AS GuestsCheckedIn
	|INTO HotelProductTotalSales
	|FROM
	|	AccumulationRegister.HotelProductSales.Turnovers(
	|			&qTotalsPeriodFrom,
	|			&qTotalsPeriodTo,
	|			Period,
	|			&qShowHotelProductTotalAmount
	|				AND (NOT &qShowHotelProductTotalAmountByCreateDate
	|					OR &qShowHotelProductTotalAmountByCreateDate
	|						AND HotelProduct.CreateDate >= &qPeriodFrom
	|						AND HotelProduct.CreateDate <= &qPeriodTo)
	|				AND Hotel IN HIERARCHY (&qHotel)
	|				AND (CASE
	|						WHEN Customer = &qEmptyCustomer
	|							THEN Hotel.IndividualsCustomer
	|						ELSE Customer
	|					END IN HIERARCHY (&qCustomer)
	|					OR &qIsEmptyCustomer)
	|				AND (Contract = &qContract
	|					OR &qIsEmptyContract)
	|				AND (GuestGroup = &qGuestGroup
	|					OR &qIsEmptyGuestGroup)
	|				AND (HotelProduct IN HIERARCHY (&qHotelProduct)
	|					OR &qIsEmptyHotelProduct)
	|				AND (Service IN (&qServicesList)
	|					OR NOT &qUseServicesList)) AS HotelProductTotalSalesTurnovers
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	HotelProductSalesTurnovers.ReportingCurrency AS ReportingCurrency,
	|	HotelProductSalesTurnovers.Hotel AS Hotel,
	|	HotelProductSalesTurnovers.HotelProduct AS HotelProduct,
	|	HotelProductSalesTurnovers.Agent AS Agent,
	|	CASE
	|		WHEN HotelProductSalesTurnovers.Customer = &qEmptyCustomer
	|			THEN HotelProductSalesTurnovers.Hotel.IndividualsCustomer
	|		ELSE HotelProductSalesTurnovers.Customer
	|	END AS Customer,
	|	CASE
	|		WHEN HotelProductSalesTurnovers.Customer = &qEmptyCustomer
	|				AND HotelProductSalesTurnovers.Contract = &qEmptyContract
	|			THEN HotelProductSalesTurnovers.Hotel.IndividualsContract
	|		ELSE HotelProductSalesTurnovers.Contract
	|	END AS Contract,
	|	HotelProductSalesTurnovers.GuestGroup AS GuestGroup,
	|	HotelProductSalesTurnovers.Client AS Client,
	|	CASE
	|		WHEN NOT HotelProductSalesTurnovers.Folio.HotelProduct IS NULL
	|				AND HotelProductSalesTurnovers.Folio.HotelProduct <> &qEmptyHotelProduct
	|			THEN HotelProductSalesTurnovers.Folio
	|		WHEN NOT HotelProductSalesTurnovers.ParentDoc IS NULL
	|			THEN HotelProductSalesTurnovers.ParentDoc
	|		ELSE HotelProductSalesTurnovers.Folio
	|	END AS ParentDoc,
	|	HotelProductSalesTurnovers.ParentDoc.NumberOfPersons AS NumberOfPersons,
	|	CASE
	|		WHEN NOT &qSplitPaymentsByColumns
	|			THEN HotelProductSalesTurnovers.PaymentMethod
	|		ELSE &qEmptyPaymentMethod
	|	END AS PaymentMethod,
	|	HotelProductSalesTurnovers.Folio.Room AS Room,
	|	HotelProductSalesTurnovers.ParentDoc.RoomRate AS RoomRate,
	|	HotelProductSalesTurnovers.ParentDoc.AccommodationType AS AccommodationType,
	|	HotelProductSalesTurnovers.ParentDoc.ClientType AS ClientType,
	|	HotelProductSalesTurnovers.ParentDoc.MarketingCode AS MarketingCode,
	|	HotelProductSalesTurnovers.ParentDoc.SourceOfBusiness AS SourceOfBusiness,
	|	HotelProductSalesTurnovers.ParentDoc.TripPurpose AS TripPurpose,
	|	HotelProductSalesTurnovers.ParentDoc.DiscountType AS DiscountType,
	|	CASE
	|		WHEN NOT HotelProductSalesTurnovers.ParentDoc.CheckInDate IS NULL
	|			THEN HotelProductSalesTurnovers.ParentDoc.CheckInDate
	|		WHEN NOT HotelProductSalesTurnovers.Folio.DateTimeFrom IS NULL
	|			THEN HotelProductSalesTurnovers.Folio.DateTimeFrom
	|		WHEN NOT HotelProductSalesTurnovers.ParentDoc.DateTimeFrom IS NULL
	|			THEN HotelProductSalesTurnovers.ParentDoc.DateTimeFrom
	|		ELSE &qEmptyDate
	|	END AS CheckInDate,
	|	CASE
	|		WHEN NOT HotelProductSalesTurnovers.ParentDoc.CheckOutDate IS NULL
	|			THEN HotelProductSalesTurnovers.ParentDoc.CheckOutDate
	|		WHEN NOT HotelProductSalesTurnovers.Folio.DateTimeTo IS NULL
	|			THEN HotelProductSalesTurnovers.Folio.DateTimeTo
	|		WHEN NOT HotelProductSalesTurnovers.ParentDoc.DateTimeTo IS NULL
	|			THEN HotelProductSalesTurnovers.ParentDoc.DateTimeTo
	|		ELSE &qEmptyDate
	|	END AS CheckOutDate,
	|	HotelProductSalesTurnovers.SalesTurnover AS Sales,
	|	HotelProductSalesTurnovers.SalesWithoutVATTurnover AS SalesWithoutVAT,
	|	HotelProductSalesTurnovers.GuestDaysTurnover AS GuestDays
	|INTO HotelProductCurPeriodSales
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			&qShowHotelProductSales
	|				AND Service.IsHotelProductService
	|				AND HotelProduct <> &qEmptyHotelProduct
	|				AND Hotel IN HIERARCHY (&qHotel)
	|				AND (CASE
	|						WHEN Customer = &qEmptyCustomer
	|							THEN Hotel.IndividualsCustomer
	|						ELSE Customer
	|					END IN HIERARCHY (&qCustomer)
	|					OR &qIsEmptyCustomer)
	|				AND (Contract = &qContract
	|					OR &qIsEmptyContract)
	|				AND (GuestGroup = &qGuestGroup
	|					OR &qIsEmptyGuestGroup)
	|				AND (HotelProduct IN HIERARCHY (&qHotelProduct)
	|					OR &qIsEmptyHotelProduct)
	|				AND (Service IN (&qServicesList)
	|					OR NOT &qUseServicesList)) AS HotelProductSalesTurnovers
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	HotelProductSalesTurnoversPrevPer.ReportingCurrency AS ReportingCurrency,
	|	HotelProductSalesTurnoversPrevPer.Hotel AS Hotel,
	|	HotelProductSalesTurnoversPrevPer.HotelProduct AS HotelProduct,
	|	HotelProductSalesTurnoversPrevPer.Agent AS Agent,
	|	CASE
	|		WHEN HotelProductSalesTurnoversPrevPer.Customer = &qEmptyCustomer
	|			THEN HotelProductSalesTurnoversPrevPer.Hotel.IndividualsCustomer
	|		ELSE HotelProductSalesTurnoversPrevPer.Customer
	|	END AS Customer,
	|	CASE
	|		WHEN HotelProductSalesTurnoversPrevPer.Customer = &qEmptyCustomer
	|				AND HotelProductSalesTurnoversPrevPer.Contract = &qEmptyContract
	|			THEN HotelProductSalesTurnoversPrevPer.Hotel.IndividualsContract
	|		ELSE HotelProductSalesTurnoversPrevPer.Contract
	|	END AS Contract,
	|	HotelProductSalesTurnoversPrevPer.GuestGroup AS GuestGroup,
	|	HotelProductSalesTurnoversPrevPer.Client AS Client,
	|	CASE
	|		WHEN NOT HotelProductSalesTurnoversPrevPer.Folio.HotelProduct IS NULL
	|				AND HotelProductSalesTurnoversPrevPer.Folio.HotelProduct <> &qEmptyHotelProduct
	|			THEN HotelProductSalesTurnoversPrevPer.Folio
	|		WHEN NOT HotelProductSalesTurnoversPrevPer.ParentDoc IS NULL
	|			THEN HotelProductSalesTurnoversPrevPer.ParentDoc
	|		ELSE HotelProductSalesTurnoversPrevPer.Folio
	|	END AS ParentDoc,
	|	HotelProductSalesTurnoversPrevPer.ParentDoc.NumberOfPersons AS NumberOfPersons,
	|	CASE
	|		WHEN NOT &qSplitPaymentsByColumns
	|			THEN HotelProductSalesTurnoversPrevPer.PaymentMethod
	|		ELSE &qEmptyPaymentMethod
	|	END AS PaymentMethod,
	|	HotelProductSalesTurnoversPrevPer.Folio.Room AS Room,
	|	HotelProductSalesTurnoversPrevPer.ParentDoc.RoomRate AS RoomRate,
	|	HotelProductSalesTurnoversPrevPer.ParentDoc.AccommodationType AS AccommodationType,
	|	HotelProductSalesTurnoversPrevPer.ParentDoc.ClientType AS ClientType,
	|	HotelProductSalesTurnoversPrevPer.ParentDoc.MarketingCode AS MarketingCode,
	|	HotelProductSalesTurnoversPrevPer.ParentDoc.SourceOfBusiness AS SourceOfBusiness,
	|	HotelProductSalesTurnoversPrevPer.ParentDoc.TripPurpose AS TripPurpose,
	|	HotelProductSalesTurnoversPrevPer.ParentDoc.DiscountType AS DiscountType,
	|	CASE
	|		WHEN NOT HotelProductSalesTurnoversPrevPer.ParentDoc.CheckInDate IS NULL
	|			THEN HotelProductSalesTurnoversPrevPer.ParentDoc.CheckInDate
	|		WHEN NOT HotelProductSalesTurnoversPrevPer.Folio.DateTimeFrom IS NULL
	|			THEN HotelProductSalesTurnoversPrevPer.Folio.DateTimeFrom
	|		WHEN NOT HotelProductSalesTurnoversPrevPer.ParentDoc.DateTimeFrom IS NULL
	|			THEN HotelProductSalesTurnoversPrevPer.ParentDoc.DateTimeFrom
	|		ELSE &qEmptyDate
	|	END AS CheckInDate,
	|	CASE
	|		WHEN NOT HotelProductSalesTurnoversPrevPer.ParentDoc.CheckOutDate IS NULL
	|			THEN HotelProductSalesTurnoversPrevPer.ParentDoc.CheckOutDate
	|		WHEN NOT HotelProductSalesTurnoversPrevPer.Folio.DateTimeTo IS NULL
	|			THEN HotelProductSalesTurnoversPrevPer.Folio.DateTimeTo
	|		WHEN NOT HotelProductSalesTurnoversPrevPer.ParentDoc.DateTimeTo IS NULL
	|			THEN HotelProductSalesTurnoversPrevPer.ParentDoc.DateTimeTo
	|		ELSE &qEmptyDate
	|	END AS CheckOutDate,
	|	HotelProductSalesTurnoversPrevPer.SalesTurnover AS Sales,
	|	HotelProductSalesTurnoversPrevPer.SalesWithoutVATTurnover AS SalesWithoutVAT,
	|	HotelProductSalesTurnoversPrevPer.GuestDaysTurnover AS GuestDays
	|INTO HotelProductPrevPeriodSales
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPrevPeriodFrom,
	|			&qPrevPeriodTo,
	|			Period,
	|			&qShowHotelProductSales
	|				AND Service.IsHotelProductService
	|				AND HotelProduct <> &qEmptyHotelProduct
	|				AND Hotel IN HIERARCHY (&qHotel)
	|				AND (CASE
	|						WHEN Customer = &qEmptyCustomer
	|							THEN Hotel.IndividualsCustomer
	|						ELSE Customer
	|					END IN HIERARCHY (&qCustomer)
	|					OR &qIsEmptyCustomer)
	|				AND (Contract = &qContract
	|					OR &qIsEmptyContract)
	|				AND (GuestGroup = &qGuestGroup
	|					OR &qIsEmptyGuestGroup)
	|				AND (HotelProduct IN HIERARCHY (&qHotelProduct)
	|					OR &qIsEmptyHotelProduct)
	|				AND (Service IN (&qServicesList)
	|					OR NOT &qUseServicesList)) AS HotelProductSalesTurnoversPrevPer
	|		INNER JOIN HotelProductCurPeriodSales AS HotelProductCurPeriodSales
	|		ON HotelProductSalesTurnoversPrevPer.HotelProduct = HotelProductCurPeriodSales.HotelProduct
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	HotelProductSalesTurnoversNextPer.ReportingCurrency AS ReportingCurrency,
	|	HotelProductSalesTurnoversNextPer.Hotel AS Hotel,
	|	HotelProductSalesTurnoversNextPer.HotelProduct AS HotelProduct,
	|	HotelProductSalesTurnoversNextPer.Agent AS Agent,
	|	CASE
	|		WHEN HotelProductSalesTurnoversNextPer.Customer = &qEmptyCustomer
	|			THEN HotelProductSalesTurnoversNextPer.Hotel.IndividualsCustomer
	|		ELSE HotelProductSalesTurnoversNextPer.Customer
	|	END AS Customer,
	|	CASE
	|		WHEN HotelProductSalesTurnoversNextPer.Customer = &qEmptyCustomer
	|				AND HotelProductSalesTurnoversNextPer.Contract = &qEmptyContract
	|			THEN HotelProductSalesTurnoversNextPer.Hotel.IndividualsContract
	|		ELSE HotelProductSalesTurnoversNextPer.Contract
	|	END AS Contract,
	|	HotelProductSalesTurnoversNextPer.GuestGroup AS GuestGroup,
	|	HotelProductSalesTurnoversNextPer.Client AS Client,
	|	CASE
	|		WHEN NOT HotelProductSalesTurnoversNextPer.Folio.HotelProduct IS NULL
	|				AND HotelProductSalesTurnoversNextPer.Folio.HotelProduct <> &qEmptyHotelProduct
	|			THEN HotelProductSalesTurnoversNextPer.Folio
	|		WHEN NOT HotelProductSalesTurnoversNextPer.ParentDoc IS NULL
	|			THEN HotelProductSalesTurnoversNextPer.ParentDoc
	|		ELSE HotelProductSalesTurnoversNextPer.Folio
	|	END AS ParentDoc,
	|	HotelProductSalesTurnoversNextPer.ParentDoc.NumberOfPersons AS NumberOfPersons,
	|	CASE
	|		WHEN NOT &qSplitPaymentsByColumns
	|			THEN HotelProductSalesTurnoversNextPer.PaymentMethod
	|		ELSE &qEmptyPaymentMethod
	|	END AS PaymentMethod,
	|	HotelProductSalesTurnoversNextPer.Folio.Room AS Room,
	|	HotelProductSalesTurnoversNextPer.ParentDoc.RoomRate AS RoomRate,
	|	HotelProductSalesTurnoversNextPer.ParentDoc.AccommodationType AS AccommodationType,
	|	HotelProductSalesTurnoversNextPer.ParentDoc.ClientType AS ClientType,
	|	HotelProductSalesTurnoversNextPer.ParentDoc.MarketingCode AS MarketingCode,
	|	HotelProductSalesTurnoversNextPer.ParentDoc.SourceOfBusiness AS SourceOfBusiness,
	|	HotelProductSalesTurnoversNextPer.ParentDoc.TripPurpose AS TripPurpose,
	|	HotelProductSalesTurnoversNextPer.ParentDoc.DiscountType AS DiscountType,
	|	CASE
	|		WHEN NOT HotelProductSalesTurnoversNextPer.ParentDoc.CheckInDate IS NULL
	|			THEN HotelProductSalesTurnoversNextPer.ParentDoc.CheckInDate
	|		WHEN NOT HotelProductSalesTurnoversNextPer.Folio.DateTimeFrom IS NULL
	|			THEN HotelProductSalesTurnoversNextPer.Folio.DateTimeFrom
	|		WHEN NOT HotelProductSalesTurnoversNextPer.ParentDoc.DateTimeFrom IS NULL
	|			THEN HotelProductSalesTurnoversNextPer.ParentDoc.DateTimeFrom
	|		ELSE &qEmptyDate
	|	END AS CheckInDate,
	|	CASE
	|		WHEN NOT HotelProductSalesTurnoversNextPer.ParentDoc.CheckOutDate IS NULL
	|			THEN HotelProductSalesTurnoversNextPer.ParentDoc.CheckOutDate
	|		WHEN NOT HotelProductSalesTurnoversNextPer.Folio.DateTimeTo IS NULL
	|			THEN HotelProductSalesTurnoversNextPer.Folio.DateTimeTo
	|		WHEN NOT HotelProductSalesTurnoversNextPer.ParentDoc.DateTimeTo IS NULL
	|			THEN HotelProductSalesTurnoversNextPer.ParentDoc.DateTimeTo
	|		ELSE &qEmptyDate
	|	END AS CheckOutDate,
	|	HotelProductSalesTurnoversNextPer.SalesTurnover AS Sales,
	|	HotelProductSalesTurnoversNextPer.SalesWithoutVATTurnover AS SalesWithoutVAT,
	|	HotelProductSalesTurnoversNextPer.GuestDaysTurnover AS GuestDays
	|INTO HotelProductNextPeriodSales
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qNextPeriodFrom,
	|			&qNextPeriodTo,
	|			Period,
	|			&qShowHotelProductSales
	|				AND Service.IsHotelProductService
	|				AND HotelProduct <> &qEmptyHotelProduct
	|				AND Hotel IN HIERARCHY (&qHotel)
	|				AND (CASE
	|						WHEN Customer = &qEmptyCustomer
	|							THEN Hotel.IndividualsCustomer
	|						ELSE Customer
	|					END IN HIERARCHY (&qCustomer)
	|					OR &qIsEmptyCustomer)
	|				AND (Contract = &qContract
	|					OR &qIsEmptyContract)
	|				AND (GuestGroup = &qGuestGroup
	|					OR &qIsEmptyGuestGroup)
	|				AND (HotelProduct IN HIERARCHY (&qHotelProduct)
	|					OR &qIsEmptyHotelProduct)
	|				AND (Service IN (&qServicesList)
	|					OR NOT &qUseServicesList)) AS HotelProductSalesTurnoversNextPer
	|		INNER JOIN HotelProductCurPeriodSales AS HotelProductCurPeriodSales
	|		ON HotelProductSalesTurnoversNextPer.HotelProduct = HotelProductCurPeriodSales.HotelProduct
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	HotelProductAccountsReceivable.AccountingCurrency AS ReportingCurrency,
	|	HotelProductAccountsReceivable.Hotel AS Hotel,
	|	HotelProductAccountsReceivable.HotelProduct AS HotelProduct,
	|	HotelProductAccountsReceivable.Folio.Agent AS Agent,
	|	HotelProductAccountsReceivable.AccountingCustomer AS Customer,
	|	HotelProductAccountsReceivable.AccountingContract AS Contract,
	|	HotelProductAccountsReceivable.GuestGroup AS GuestGroup,
	|	CASE
	|		WHEN NOT HotelProductAccountsReceivable.Folio.HotelProduct IS NULL
	|				AND HotelProductAccountsReceivable.Folio.HotelProduct <> &qEmptyHotelProduct
	|			THEN HotelProductAccountsReceivable.Folio.Client
	|		ELSE HotelProductAccountsReceivable.Client
	|	END AS Client,
	|	CASE
	|		WHEN NOT HotelProductAccountsReceivable.Folio.HotelProduct IS NULL
	|				AND HotelProductAccountsReceivable.Folio.HotelProduct <> &qEmptyHotelProduct
	|			THEN HotelProductAccountsReceivable.Folio
	|		WHEN NOT HotelProductAccountsReceivable.ParentDoc IS NULL
	|			THEN HotelProductAccountsReceivable.ParentDoc
	|		ELSE HotelProductAccountsReceivable.Folio
	|	END AS ParentDoc,
	|	HotelProductAccountsReceivable.ParentDoc.NumberOfPersons AS NumberOfPersons,
	|	CASE
	|		WHEN NOT &qSplitPaymentsByColumns
	|			THEN HotelProductAccountsReceivable.Folio.PaymentMethod
	|		ELSE &qEmptyPaymentMethod
	|	END AS PaymentMethod,
	|	CASE
	|		WHEN NOT HotelProductAccountsReceivable.Folio.HotelProduct IS NULL
	|				AND HotelProductAccountsReceivable.Folio.HotelProduct <> &qEmptyHotelProduct
	|			THEN HotelProductAccountsReceivable.Folio.Room
	|		WHEN HotelProductAccountsReceivable.Room <> &qEmptyRoom
	|			THEN HotelProductAccountsReceivable.Room
	|		ELSE HotelProductAccountsReceivable.ParentDoc.Room
	|	END AS Room,
	|	HotelProductAccountsReceivable.ParentDoc.RoomRate AS RoomRate,
	|	HotelProductAccountsReceivable.ParentDoc.AccommodationType AS AccommodationType,
	|	HotelProductAccountsReceivable.ParentDoc.ClientType AS ClientType,
	|	HotelProductAccountsReceivable.ParentDoc.MarketingCode AS MarketingCode,
	|	HotelProductAccountsReceivable.ParentDoc.SourceOfBusiness AS SourceOfBusiness,
	|	HotelProductAccountsReceivable.ParentDoc.TripPurpose AS TripPurpose,
	|	HotelProductAccountsReceivable.ParentDoc.DiscountType AS DiscountType,
	|	CASE
	|		WHEN NOT HotelProductAccountsReceivable.ParentDoc.CheckInDate IS NULL
	|			THEN HotelProductAccountsReceivable.ParentDoc.CheckInDate
	|		WHEN NOT HotelProductAccountsReceivable.Folio.DateTimeFrom IS NULL
	|			THEN HotelProductAccountsReceivable.Folio.DateTimeFrom
	|		WHEN NOT HotelProductAccountsReceivable.ParentDoc.DateTimeFrom IS NULL
	|			THEN HotelProductAccountsReceivable.ParentDoc.DateTimeFrom
	|		ELSE &qEmptyDate
	|	END AS CheckInDate,
	|	CASE
	|		WHEN NOT HotelProductAccountsReceivable.ParentDoc.CheckOutDate IS NULL
	|			THEN HotelProductAccountsReceivable.ParentDoc.CheckOutDate
	|		WHEN NOT HotelProductAccountsReceivable.Folio.DateTimeTo IS NULL
	|			THEN HotelProductAccountsReceivable.Folio.DateTimeTo
	|		WHEN NOT HotelProductAccountsReceivable.ParentDoc.DateTimeTo IS NULL
	|			THEN HotelProductAccountsReceivable.ParentDoc.DateTimeTo
	|		ELSE &qEmptyDate
	|	END AS CheckOutDate,
	|	HotelProductAccountsReceivable.Sum AS Sum,
	|	HotelProductAccountsReceivable.Sum - HotelProductAccountsReceivable.VATSum AS SumWithoutVAT
	|INTO HotelProductAccountsReceivable
	|FROM
	|	AccumulationRegister.AccountsReceivable AS HotelProductAccountsReceivable
	|WHERE
	|	&qShowHotelProductAccountsReceivable
	|	AND HotelProductAccountsReceivable.Service.IsHotelProductService
	|	AND HotelProductAccountsReceivable.Hotel IN HIERARCHY(&qHotel)
	|	AND (HotelProductAccountsReceivable.AccountingCustomer IN HIERARCHY (&qCustomer)
	|			OR &qIsEmptyCustomer)
	|	AND (HotelProductAccountsReceivable.AccountingContract = &qContract
	|			OR &qIsEmptyContract)
	|	AND (HotelProductAccountsReceivable.GuestGroup = &qGuestGroup
	|			OR &qIsEmptyGuestGroup)
	|	AND (HotelProductAccountsReceivable.HotelProduct IN HIERARCHY (&qHotelProduct)
	|			OR &qIsEmptyHotelProduct)
	|	AND (HotelProductAccountsReceivable.Service IN (&qServicesList)
	|			OR NOT &qUseServicesList)
	|	AND HotelProductAccountsReceivable.GuestGroup IN
	|			(SELECT
	|				HotelProductGroups.GuestGroup
	|			FROM
	|				HotelProductGroups)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	HotelProductPeriodAccountsReceivable.AccountingCurrency AS ReportingCurrency,
	|	HotelProductPeriodAccountsReceivable.Hotel AS Hotel,
	|	HotelProductPeriodAccountsReceivable.HotelProduct AS HotelProduct,
	|	HotelProductPeriodAccountsReceivable.Folio.Agent AS Agent,
	|	HotelProductPeriodAccountsReceivable.AccountingCustomer AS Customer,
	|	HotelProductPeriodAccountsReceivable.AccountingContract AS Contract,
	|	HotelProductPeriodAccountsReceivable.GuestGroup AS GuestGroup,
	|	CASE
	|		WHEN NOT HotelProductPeriodAccountsReceivable.Folio.HotelProduct IS NULL
	|				AND HotelProductPeriodAccountsReceivable.Folio.HotelProduct <> &qEmptyHotelProduct
	|			THEN HotelProductPeriodAccountsReceivable.Folio.Client
	|		ELSE HotelProductPeriodAccountsReceivable.Client
	|	END AS Client,
	|	CASE
	|		WHEN NOT HotelProductPeriodAccountsReceivable.Folio.HotelProduct IS NULL
	|				AND HotelProductPeriodAccountsReceivable.Folio.HotelProduct <> &qEmptyHotelProduct
	|			THEN HotelProductPeriodAccountsReceivable.Folio
	|		WHEN NOT HotelProductPeriodAccountsReceivable.ParentDoc IS NULL
	|			THEN HotelProductPeriodAccountsReceivable.ParentDoc
	|		ELSE HotelProductPeriodAccountsReceivable.Folio
	|	END AS ParentDoc,
	|	HotelProductPeriodAccountsReceivable.ParentDoc.NumberOfPersons AS NumberOfPersons,
	|	CASE
	|		WHEN NOT &qSplitPaymentsByColumns
	|			THEN HotelProductPeriodAccountsReceivable.Folio.PaymentMethod
	|		ELSE &qEmptyPaymentMethod
	|	END AS PaymentMethod,
	|	CASE
	|		WHEN NOT HotelProductPeriodAccountsReceivable.Folio.HotelProduct IS NULL
	|				AND HotelProductPeriodAccountsReceivable.Folio.HotelProduct <> &qEmptyHotelProduct
	|			THEN HotelProductPeriodAccountsReceivable.Folio.Room
	|		WHEN HotelProductPeriodAccountsReceivable.Room <> &qEmptyRoom
	|			THEN HotelProductPeriodAccountsReceivable.Room
	|		ELSE HotelProductPeriodAccountsReceivable.ParentDoc.Room
	|	END AS Room,
	|	HotelProductPeriodAccountsReceivable.ParentDoc.RoomRate AS RoomRate,
	|	HotelProductPeriodAccountsReceivable.ParentDoc.AccommodationType AS AccommodationType,
	|	HotelProductPeriodAccountsReceivable.ParentDoc.ClientType AS ClientType,
	|	HotelProductPeriodAccountsReceivable.ParentDoc.MarketingCode AS MarketingCode,
	|	HotelProductPeriodAccountsReceivable.ParentDoc.SourceOfBusiness AS SourceOfBusiness,
	|	HotelProductPeriodAccountsReceivable.ParentDoc.TripPurpose AS TripPurpose,
	|	HotelProductPeriodAccountsReceivable.ParentDoc.DiscountType AS DiscountType,
	|	CASE
	|		WHEN NOT HotelProductPeriodAccountsReceivable.ParentDoc.CheckInDate IS NULL
	|			THEN HotelProductPeriodAccountsReceivable.ParentDoc.CheckInDate
	|		WHEN NOT HotelProductPeriodAccountsReceivable.Folio.DateTimeFrom IS NULL
	|			THEN HotelProductPeriodAccountsReceivable.Folio.DateTimeFrom
	|		WHEN NOT HotelProductPeriodAccountsReceivable.ParentDoc.DateTimeFrom IS NULL
	|			THEN HotelProductPeriodAccountsReceivable.ParentDoc.DateTimeFrom
	|		ELSE &qEmptyDate
	|	END AS CheckInDate,
	|	CASE
	|		WHEN NOT HotelProductPeriodAccountsReceivable.ParentDoc.CheckOutDate IS NULL
	|			THEN HotelProductPeriodAccountsReceivable.ParentDoc.CheckOutDate
	|		WHEN NOT HotelProductPeriodAccountsReceivable.Folio.DateTimeTo IS NULL
	|			THEN HotelProductPeriodAccountsReceivable.Folio.DateTimeTo
	|		WHEN NOT HotelProductPeriodAccountsReceivable.ParentDoc.DateTimeTo IS NULL
	|			THEN HotelProductPeriodAccountsReceivable.ParentDoc.DateTimeTo
	|		ELSE &qEmptyDate
	|	END AS CheckOutDate,
	|	HotelProductPeriodAccountsReceivable.Sum AS Sum,
	|	HotelProductPeriodAccountsReceivable.Sum - HotelProductPeriodAccountsReceivable.VATSum AS SumWithoutVAT
	|INTO HotelProductPeriodAccountsReceivable
	|FROM
	|	AccumulationRegister.AccountsReceivable AS HotelProductPeriodAccountsReceivable
	|WHERE
	|	&qShowHotelProductAccountsReceivable
	|	AND HotelProductPeriodAccountsReceivable.Period >= &qPeriodFrom
	|	AND HotelProductPeriodAccountsReceivable.Period <= &qPeriodTo
	|	AND HotelProductPeriodAccountsReceivable.Service.IsHotelProductService
	|	AND HotelProductPeriodAccountsReceivable.Hotel IN HIERARCHY(&qHotel)
	|	AND (HotelProductPeriodAccountsReceivable.AccountingCustomer IN HIERARCHY (&qCustomer)
	|			OR &qIsEmptyCustomer)
	|	AND (HotelProductPeriodAccountsReceivable.AccountingContract = &qContract
	|			OR &qIsEmptyContract)
	|	AND (HotelProductPeriodAccountsReceivable.GuestGroup = &qGuestGroup
	|			OR &qIsEmptyGuestGroup)
	|	AND (HotelProductPeriodAccountsReceivable.HotelProduct IN HIERARCHY (&qHotelProduct)
	|			OR &qIsEmptyHotelProduct)
	|	AND (HotelProductPeriodAccountsReceivable.Service IN (&qServicesList)
	|			OR NOT &qUseServicesList)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	HotelProductPayments.AccountingCurrency AS ReportingCurrency,
	|	HotelProductPayments.Hotel AS Hotel,
	|	CASE
	|		WHEN NOT HotelProductPayments.Folio.HotelProduct IS NULL
	|				AND HotelProductPayments.Folio.HotelProduct <> &qEmptyHotelProduct
	|			THEN HotelProductPayments.Folio.HotelProduct
	|		WHEN NOT HotelProductPayments.Folio.ParentDoc.HotelProduct IS NULL
	|				AND HotelProductPayments.Folio.ParentDoc.HotelProduct <> &qEmptyHotelProduct
	|			THEN HotelProductPayments.Folio.ParentDoc.HotelProduct
	|		ELSE HotelProductPayments.ParentDoc.HotelProduct
	|	END AS HotelProduct,
	|	HotelProductPayments.Folio.Agent AS Agent,
	|	HotelProductPayments.AccountingCustomer AS Customer,
	|	HotelProductPayments.AccountingContract AS Contract,
	|	HotelProductPayments.GuestGroup AS GuestGroup,
	|	CASE
	|		WHEN NOT HotelProductPayments.Folio.HotelProduct IS NULL
	|				AND HotelProductPayments.Folio.HotelProduct <> &qEmptyHotelProduct
	|			THEN HotelProductPayments.Folio.Client
	|		ELSE HotelProductPayments.Client
	|	END AS Client,
	|	CASE
	|		WHEN NOT HotelProductPayments.Folio.HotelProduct IS NULL
	|				AND HotelProductPayments.Folio.HotelProduct <> &qEmptyHotelProduct
	|			THEN HotelProductPayments.Folio
	|		WHEN NOT HotelProductPayments.Folio.ParentDoc IS NULL
	|			THEN HotelProductPayments.Folio.ParentDoc
	|		WHEN NOT HotelProductPayments.ParentDoc IS NULL
	|			THEN HotelProductPayments.ParentDoc
	|		ELSE HotelProductPayments.Folio
	|	END AS ParentDoc,
	|	CASE
	|		WHEN NOT HotelProductPayments.Folio.ParentDoc.NumberOfPersons IS NULL
	|			THEN HotelProductPayments.Folio.ParentDoc.NumberOfPersons
	|		ELSE HotelProductPayments.ParentDoc.NumberOfPersons
	|	END AS NumberOfPersons,
	|	CASE
	|		WHEN HotelProductPayments.Recorder.PaymentMethod = &qDepositTransfer
	|				AND NOT &qSplitPaymentsByColumns
	|			THEN HotelProductPayments.Folio.PaymentMethod
	|		WHEN NOT &qSplitPaymentsByColumns
	|			THEN HotelProductPayments.Recorder.PaymentMethod
	|		ELSE &qEmptyPaymentMethod
	|	END AS PaymentMethod,
	|	CASE
	|		WHEN NOT HotelProductPayments.Folio.Room IS NULL
	|				AND HotelProductPayments.Folio.Room <> &qEmptyRoom
	|			THEN HotelProductPayments.Folio.Room
	|		WHEN HotelProductPayments.Room <> &qEmptyRoom
	|			THEN HotelProductPayments.Room
	|		ELSE HotelProductPayments.ParentDoc.Room
	|	END AS Room,
	|	CASE
	|		WHEN NOT HotelProductPayments.Folio.ParentDoc.RoomRate IS NULL
	|			THEN HotelProductPayments.Folio.ParentDoc.RoomRate
	|		ELSE HotelProductPayments.ParentDoc.RoomRate
	|	END AS RoomRate,
	|	CASE
	|		WHEN NOT HotelProductPayments.Folio.ParentDoc.AccommodationType IS NULL
	|			THEN HotelProductPayments.Folio.ParentDoc.AccommodationType
	|		ELSE HotelProductPayments.ParentDoc.AccommodationType
	|	END AS AccommodationType,
	|	CASE
	|		WHEN NOT HotelProductPayments.Folio.ParentDoc.ClientType IS NULL
	|			THEN HotelProductPayments.Folio.ParentDoc.ClientType
	|		ELSE HotelProductPayments.ParentDoc.ClientType
	|	END AS ClientType,
	|	CASE
	|		WHEN NOT HotelProductPayments.Folio.ParentDoc.MarketingCode IS NULL
	|			THEN HotelProductPayments.Folio.ParentDoc.MarketingCode
	|		ELSE HotelProductPayments.ParentDoc.MarketingCode
	|	END AS MarketingCode,
	|	CASE
	|		WHEN NOT HotelProductPayments.Folio.ParentDoc.SourceOfBusiness IS NULL
	|			THEN HotelProductPayments.Folio.ParentDoc.SourceOfBusiness
	|		ELSE HotelProductPayments.ParentDoc.SourceOfBusiness
	|	END AS SourceOfBusiness,
	|	CASE
	|		WHEN NOT HotelProductPayments.Folio.ParentDoc.TripPurpose IS NULL
	|			THEN HotelProductPayments.Folio.ParentDoc.TripPurpose
	|		ELSE HotelProductPayments.ParentDoc.TripPurpose
	|	END AS TripPurpose,
	|	CASE
	|		WHEN NOT HotelProductPayments.Folio.ParentDoc.DiscountType IS NULL
	|			THEN HotelProductPayments.Folio.ParentDoc.DiscountType
	|		ELSE HotelProductPayments.ParentDoc.DiscountType
	|	END AS DiscountType,
	|	CASE
	|		WHEN NOT HotelProductPayments.Folio.ParentDoc.CheckInDate IS NULL
	|			THEN HotelProductPayments.Folio.ParentDoc.CheckInDate
	|		WHEN NOT HotelProductPayments.ParentDoc.CheckInDate IS NULL
	|			THEN HotelProductPayments.ParentDoc.CheckInDate
	|		WHEN NOT HotelProductPayments.Folio.DateTimeFrom IS NULL
	|			THEN HotelProductPayments.Folio.DateTimeFrom
	|		WHEN NOT HotelProductPayments.ParentDoc.DateTimeFrom IS NULL
	|			THEN HotelProductPayments.ParentDoc.DateTimeFrom
	|		ELSE &qEmptyDate
	|	END AS CheckInDate,
	|	CASE
	|		WHEN NOT HotelProductPayments.Folio.ParentDoc.CheckOutDate IS NULL
	|			THEN HotelProductPayments.Folio.ParentDoc.CheckOutDate
	|		WHEN NOT HotelProductPayments.ParentDoc.CheckOutDate IS NULL
	|			THEN HotelProductPayments.ParentDoc.CheckOutDate
	|		WHEN NOT HotelProductPayments.Folio.DateTimeTo IS NULL
	|			THEN HotelProductPayments.Folio.DateTimeTo
	|		WHEN NOT HotelProductPayments.ParentDoc.DateTimeTo IS NULL
	|			THEN HotelProductPayments.ParentDoc.DateTimeTo
	|		ELSE &qEmptyDate
	|	END AS CheckOutDate,
	|	HotelProductPayments.Sum AS PaymentSum,
	|	HotelProductPayments.Sum - HotelProductPayments.VATSum AS PaymentSumWithoutVAT,
	|	CASE
	|		WHEN HotelProductPayments.Recorder.PaymentMethod.IsByCash
	|			THEN HotelProductPayments.Sum
	|		WHEN HotelProductPayments.Recorder REFS Document.DepositTransfer
	|				AND HotelProductPayments.Recorder.FolioFrom.PaymentMethod.IsByCash
	|				AND HotelProductPayments.Recorder.FolioFrom = HotelProductPayments.Folio
	|			THEN HotelProductPayments.Sum
	|		WHEN HotelProductPayments.Recorder REFS Document.DepositTransfer
	|				AND HotelProductPayments.Recorder.FolioTo.PaymentMethod.IsByCash
	|				AND HotelProductPayments.Recorder.FolioTo = HotelProductPayments.Folio
	|			THEN HotelProductPayments.Sum
	|		ELSE 0
	|	END AS PaymentSumByCash,
	|	CASE
	|		WHEN HotelProductPayments.Recorder.PaymentMethod.IsByCreditCard
	|			THEN HotelProductPayments.Sum
	|		WHEN HotelProductPayments.Recorder REFS Document.DepositTransfer
	|				AND HotelProductPayments.Recorder.FolioFrom.PaymentMethod.IsByCreditCard
	|				AND HotelProductPayments.Recorder.FolioFrom = HotelProductPayments.Folio
	|			THEN HotelProductPayments.Sum
	|		WHEN HotelProductPayments.Recorder REFS Document.DepositTransfer
	|				AND HotelProductPayments.Recorder.FolioTo.PaymentMethod.IsByCreditCard
	|				AND HotelProductPayments.Recorder.FolioTo = HotelProductPayments.Folio
	|			THEN HotelProductPayments.Sum
	|		ELSE 0
	|	END AS PaymentSumByCreditCard,
	|	CASE
	|		WHEN HotelProductPayments.Recorder.PaymentMethod.IsByBankTransfer
	|			THEN HotelProductPayments.Sum
	|		WHEN HotelProductPayments.Recorder REFS Document.DepositTransfer
	|				AND HotelProductPayments.Recorder.FolioFrom.PaymentMethod.IsByBankTransfer
	|				AND HotelProductPayments.Recorder.FolioFrom = HotelProductPayments.Folio
	|			THEN HotelProductPayments.Sum
	|		WHEN HotelProductPayments.Recorder REFS Document.DepositTransfer
	|				AND HotelProductPayments.Recorder.FolioTo.PaymentMethod.IsByBankTransfer
	|				AND HotelProductPayments.Recorder.FolioTo = HotelProductPayments.Folio
	|			THEN HotelProductPayments.Sum
	|		ELSE 0
	|	END AS PaymentSumByBankTransfer,
	|	CASE
	|		WHEN HotelProductPayments.Recorder.PaymentMethod.IsViaInternetAcquiring
	|			THEN HotelProductPayments.Sum
	|		WHEN HotelProductPayments.Recorder REFS Document.DepositTransfer
	|				AND HotelProductPayments.Recorder.FolioFrom.PaymentMethod.IsViaInternetAcquiring
	|				AND HotelProductPayments.Recorder.FolioFrom = HotelProductPayments.Folio
	|			THEN HotelProductPayments.Sum
	|		WHEN HotelProductPayments.Recorder REFS Document.DepositTransfer
	|				AND HotelProductPayments.Recorder.FolioTo.PaymentMethod.IsViaInternetAcquiring
	|				AND HotelProductPayments.Recorder.FolioTo = HotelProductPayments.Folio
	|			THEN HotelProductPayments.Sum
	|		ELSE 0
	|	END AS PaymentSumByInternet,
	|	CASE
	|		WHEN HotelProductPayments.Recorder.PaymentMethod.IsByBonuses
	|			THEN HotelProductPayments.Sum
	|		WHEN HotelProductPayments.Recorder REFS Document.DepositTransfer
	|				AND HotelProductPayments.Recorder.FolioFrom.PaymentMethod.IsByBonuses
	|				AND HotelProductPayments.Recorder.FolioFrom = HotelProductPayments.Folio
	|			THEN HotelProductPayments.Sum
	|		WHEN HotelProductPayments.Recorder REFS Document.DepositTransfer
	|				AND HotelProductPayments.Recorder.FolioTo.PaymentMethod.IsByBonuses
	|				AND HotelProductPayments.Recorder.FolioTo = HotelProductPayments.Folio
	|			THEN HotelProductPayments.Sum
	|		ELSE 0
	|	END AS PaymentSumByBonuses,
	|	CASE
	|		WHEN HotelProductPayments.Recorder.PaymentMethod.IsByGiftCertificate
	|			THEN HotelProductPayments.Sum
	|		WHEN HotelProductPayments.Recorder REFS Document.DepositTransfer
	|				AND HotelProductPayments.Recorder.FolioFrom.PaymentMethod.IsByGiftCertificate
	|				AND HotelProductPayments.Recorder.FolioFrom = HotelProductPayments.Folio
	|			THEN HotelProductPayments.Sum
	|		WHEN HotelProductPayments.Recorder REFS Document.DepositTransfer
	|				AND HotelProductPayments.Recorder.FolioTo.PaymentMethod.IsByGiftCertificate
	|				AND HotelProductPayments.Recorder.FolioTo = HotelProductPayments.Folio
	|			THEN HotelProductPayments.Sum
	|		ELSE 0
	|	END AS PaymentSumByGiftCertificates
	|INTO HotelProductPayments
	|FROM
	|	AccumulationRegister.CustomerAccounts AS HotelProductPayments
	|WHERE
	|	&qShowGuestGroupPayments
	|	AND HotelProductPayments.RecordType = VALUE(AccumulationrecordType.Expense)
	|	AND (HotelProductPayments.PaymentSection = &qEmptyPaymentSection
	|				AND NOT HotelProductPayments.Folio.Description LIKE &qFolioFilter
	|			OR HotelProductPayments.PaymentSection <> &qEmptyPaymentSection
	|				AND ISNULL(HotelProductPayments.PaymentSection.IsForHotelProducts, FALSE)
	|			OR HotelProductPayments.Recorder REFS Document.DepositTransfer
	|				AND HotelProductPayments.Recorder.FolioFrom = HotelProductPayments.Folio
	|				AND NOT HotelProductPayments.Folio.Description LIKE &qFolioFilter)
	|	AND HotelProductPayments.Hotel IN HIERARCHY(&qHotel)
	|	AND (HotelProductPayments.AccountingCustomer IN HIERARCHY (&qCustomer)
	|			OR &qIsEmptyCustomer)
	|	AND (HotelProductPayments.AccountingContract = &qContract
	|			OR &qIsEmptyContract)
	|	AND (HotelProductPayments.GuestGroup = &qGuestGroup
	|			OR &qIsEmptyGuestGroup)
	|	AND HotelProductPayments.GuestGroup IN
	|			(SELECT
	|				HotelProductGroups.GuestGroup
	|			FROM
	|				HotelProductGroups AS HotelProductGroups)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VoidedHotelProductsByCreateDate.Currency AS ReportingCurrency,
	|	VoidedHotelProductsByCreateDate.Hotel AS Hotel,
	|	VoidedHotelProductsByCreateDate.Description AS HotelProduct,
	|	VoidedHotelProductsByCreateDate.Client AS Client,
	|	VoidedHotelProductsByCreateDate.PaymentMethod AS PaymentMethod,
	|	VoidedHotelProductsByCreateDate.CheckInDate AS CheckInDate,
	|	VoidedHotelProductsByCreateDate.CheckOutDate AS CheckOutDate,
	|	VoidedHotelProductsByCreateDate.Sum AS Sales,
	|	VoidedHotelProductsByCreateDate.Duration AS GuestDays
	|INTO VoidedHotelProductsByCreateDate
	|FROM
	|	Catalog.HotelProducts AS VoidedHotelProductsByCreateDate
	|WHERE
	|	VoidedHotelProductsByCreateDate.CreateDate >= &qPeriodFrom
	|	AND VoidedHotelProductsByCreateDate.CreateDate <= &qPeriodTo
	|	AND VoidedHotelProductsByCreateDate.Hotel IN HIERARCHY(&qHotel)
	|	AND (VoidedHotelProductsByCreateDate.Ref IN HIERARCHY (&qHotelProduct)
	|			OR &qIsEmptyHotelProduct)
	|	AND (VoidedHotelProductsByCreateDate.Service IN (&qServicesList)
	|			OR NOT &qUseServicesList)
	|	AND VoidedHotelProductsByCreateDate.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VoidedHotelProductsByDeleteDate.Currency AS ReportingCurrency,
	|	VoidedHotelProductsByDeleteDate.Hotel AS Hotel,
	|	VoidedHotelProductsByDeleteDate.Description AS HotelProduct,
	|	VoidedHotelProductsByDeleteDate.Client AS Client,
	|	VoidedHotelProductsByDeleteDate.PaymentMethod AS PaymentMethod,
	|	VoidedHotelProductsByDeleteDate.CheckInDate AS CheckInDate,
	|	VoidedHotelProductsByDeleteDate.CheckOutDate AS CheckOutDate,
	|	-VoidedHotelProductsByDeleteDate.Sum AS Sales,
	|	VoidedHotelProductsByDeleteDate.Duration AS GuestDays
	|INTO VoidedHotelProductsByDeleteDate
	|FROM
	|	Catalog.HotelProducts AS VoidedHotelProductsByDeleteDate
	|WHERE
	|	VoidedHotelProductsByDeleteDate.DeletionMarkDate >= &qPeriodFrom
	|	AND VoidedHotelProductsByDeleteDate.DeletionMarkDate <= &qPeriodTo
	|	AND VoidedHotelProductsByDeleteDate.Hotel IN HIERARCHY(&qHotel)
	|	AND (VoidedHotelProductsByDeleteDate.Ref IN HIERARCHY (&qHotelProduct)
	|			OR &qIsEmptyHotelProduct)
	|	AND (VoidedHotelProductsByDeleteDate.Service IN (&qServicesList)
	|			OR NOT &qUseServicesList)
	|	AND VoidedHotelProductsByDeleteDate.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SalesByHotelProducts.ReportingCurrency AS ReportingCurrency,
	|	SalesByHotelProducts.HotelProduct AS HotelProduct,
	|	SUM(SalesByHotelProducts.Sales) AS Sales,
	|	SUM(SalesByHotelProducts.PeriodSales) AS PeriodSales,
	|	SUM(SalesByHotelProducts.NextPeriodSales) AS NextPeriodSales,
	|	SUM(SalesByHotelProducts.PrevPeriodSales) AS PrevPeriodSales,
	|	SUM(SalesByHotelProducts.SalesInSettlements) AS SalesInSettlements,
	|	SUM(SalesByHotelProducts.PeriodSalesInSettlements) AS PeriodSalesInSettlements,
	|	SUM(SalesByHotelProducts.PaymentAmount) AS PaymentAmount
	|INTO SalesByHotelProducts
	|FROM
	|	(SELECT
	|		HotelProductTotalSales.ReportingCurrency AS ReportingCurrency,
	|		HotelProductTotalSales.HotelProduct AS HotelProduct,
	|		HotelProductTotalSales.Sales AS Sales,
	|		0 AS PeriodSales,
	|		0 AS NextPeriodSales,
	|		0 AS PrevPeriodSales,
	|		0 AS SalesInSettlements,
	|		0 AS PeriodSalesInSettlements,
	|		0 AS PaymentAmount
	|	FROM
	|		HotelProductTotalSales AS HotelProductTotalSales
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		VoidedHotelProductsByCreateDate.ReportingCurrency,
	|		VoidedHotelProductsByCreateDate.HotelProduct,
	|		0,
	|		0,
	|		0,
	|		0,
	|		VoidedHotelProductsByCreateDate.Sales,
	|		0,
	|		0
	|	FROM
	|		VoidedHotelProductsByCreateDate AS VoidedHotelProductsByCreateDate
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		VoidedHotelProductsByDeleteDate.ReportingCurrency,
	|		VoidedHotelProductsByDeleteDate.HotelProduct,
	|		0,
	|		0,
	|		0,
	|		0,
	|		VoidedHotelProductsByDeleteDate.Sales,
	|		0,
	|		0
	|	FROM
	|		VoidedHotelProductsByDeleteDate AS VoidedHotelProductsByDeleteDate
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		HotelProductCurPeriodSales.ReportingCurrency,
	|		HotelProductCurPeriodSales.Hotel,
	|		0,
	|		HotelProductCurPeriodSales.Sales,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0
	|	FROM
	|		HotelProductCurPeriodSales AS HotelProductCurPeriodSales
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		HotelProductNextPeriodSales.ReportingCurrency,
	|		HotelProductNextPeriodSales.Hotel,
	|		0,
	|		0,
	|		HotelProductNextPeriodSales.Sales,
	|		0,
	|		0,
	|		0,
	|		0
	|	FROM
	|		HotelProductNextPeriodSales AS HotelProductNextPeriodSales
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		HotelProductPrevPeriodSales.ReportingCurrency,
	|		HotelProductPrevPeriodSales.Hotel,
	|		0,
	|		0,
	|		0,
	|		HotelProductPrevPeriodSales.Sales,
	|		0,
	|		0,
	|		0
	|	FROM
	|		HotelProductPrevPeriodSales AS HotelProductPrevPeriodSales
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		HotelProductAccountsReceivable.ReportingCurrency,
	|		HotelProductAccountsReceivable.HotelProduct,
	|		0,
	|		0,
	|		0,
	|		0,
	|		HotelProductAccountsReceivable.Sum,
	|		0,
	|		0
	|	FROM
	|		HotelProductAccountsReceivable AS HotelProductAccountsReceivable
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		HotelProductPeriodAccountsReceivable.ReportingCurrency,
	|		HotelProductPeriodAccountsReceivable.HotelProduct,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		HotelProductPeriodAccountsReceivable.Sum,
	|		0
	|	FROM
	|		HotelProductPeriodAccountsReceivable AS HotelProductPeriodAccountsReceivable
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		HotelProductPayments.ReportingCurrency,
	|		HotelProductPayments.HotelProduct,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		HotelProductPayments.PaymentSum
	|	FROM
	|		HotelProductPayments AS HotelProductPayments) AS SalesByHotelProducts
	|
	|GROUP BY
	|	SalesByHotelProducts.ReportingCurrency,
	|	SalesByHotelProducts.HotelProduct
	|
	|HAVING
	|	SUM(SalesByHotelProducts.Sales) = SUM(SalesByHotelProducts.PeriodSalesInSettlements) AND
	|	SUM(SalesByHotelProducts.PeriodSalesInSettlements) = SUM(SalesByHotelProducts.PaymentAmount)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	HotelProductSales.ReportingCurrency AS ReportingCurrency,
	|	HotelProductSales.Hotel AS Hotel,
	|	HotelProductSales.HotelProduct AS HotelProduct,
	|	HotelProductSales.Agent AS Agent,
	|	HotelProductSales.Customer AS Customer,
	|	HotelProductSales.Contract AS Contract,
	|	HotelProductSales.GuestGroup AS GuestGroup,
	|	HotelProductSales.Client AS Client,
	|	HotelProductSales.Count AS Count,
	|	CASE
	|		WHEN HotelProductSales.AccommodationType.Type = &qTogether
	|			THEN 0
	|		WHEN HotelProductSales.AccommodationType.Type = &qAdditionalBed
	|			THEN 0
	|		ELSE HotelProductSales.Count
	|	END AS FamilyCount,
	|	HotelProductSales.Sales AS Sales,
	|	HotelProductSales.RoomRevenue AS RoomRevenue,
	|	HotelProductSales.SalesWithoutVAT AS SalesWithoutVAT,
	|	HotelProductSales.RoomRevenueWithoutVAT AS RoomRevenueWithoutVAT,
	|	HotelProductSales.CommissionSum AS CommissionSum,
	|	HotelProductSales.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	HotelProductSales.DiscountSum AS DiscountSum,
	|	HotelProductSales.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|	HotelProductSales.RoomsRented AS RoomsRented,
	|	HotelProductSales.BedsRented AS BedsRented,
	|	HotelProductSales.AdditionalBedsRented AS AdditionalBedsRented,
	|	HotelProductSales.GuestDays AS GuestDays,
	|	HotelProductSales.GuestsCheckedIn AS GuestsCheckedIn,
	|	HotelProductSales.PeriodSales AS PeriodSales,
	|	HotelProductSales.PeriodSalesWithoutVAT AS PeriodSalesWithoutVAT,
	|	HotelProductSales.PeriodGuestDays AS PeriodGuestDays,
	|	HotelProductSales.PrevPeriodSales AS PrevPeriodSales,
	|	HotelProductSales.PrevPeriodSalesWithoutVAT AS PrevPeriodSalesWithoutVAT,
	|	HotelProductSales.PrevPeriodGuestDays AS PrevPeriodGuestDays,
	|	HotelProductSales.NextPeriodSales AS NextPeriodSales,
	|	HotelProductSales.NextPeriodSalesWithoutVAT AS NextPeriodSalesWithoutVAT,
	|	HotelProductSales.NextPeriodGuestDays AS NextPeriodGuestDays,
	|	HotelProductSales.SalesInSettlements AS SalesInSettlements,
	|	HotelProductSales.SalesWithoutVATInSettlements AS SalesWithoutVATInSettlements,
	|	HotelProductSales.PeriodSalesInSettlements AS PeriodSalesInSettlements,
	|	HotelProductSales.PeriodSalesWithoutVATInSettlements AS PeriodSalesWithoutVATInSettlements,
	|	HotelProductSales.PaymentAmount AS PaymentAmount,
	|	HotelProductSales.PaymentAmountWithoutVAT AS PaymentAmountWithoutVAT,
	|	HotelProductSales.CashSum AS CashSum,
	|	HotelProductSales.CreditCardSum AS CreditCardSum,
	|	HotelProductSales.BankTransferSum AS BankTransferSum,
	|	HotelProductSales.InternetSum AS InternetSum,
	|	HotelProductSales.BonusesSum AS BonusesSum,
	|	HotelProductSales.GiftCertificatesSum AS GiftCertificatesSum
	|{SELECT
	|	ReportingCurrency.*,
	|	HotelProductSales.HotelProduct.RoomQuota.* AS RoomQuota,
	|	Hotel.*,
	|	HotelProduct.*,
	|	HotelProductSales.HotelProduct.Parent.* AS HotelProductParent,
	|	Agent.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	Client.*,
	|	HotelProductSales.ParentDoc.* AS ParentDoc,
	|	HotelProductSales.ParentDoc.Remarks AS Remarks,
	|	HotelProductSales.NumberOfPersons AS NumberOfPersons,
	|	HotelProductSales.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	HotelProductSales.RoomRate.* AS RoomRate,
	|	HotelProductSales.AccommodationType.* AS AccommodationType,
	|	HotelProductSales.ClientType.* AS ClientType,
	|	HotelProductSales.MarketingCode.* AS MarketingCode,
	|	HotelProductSales.SourceOfBusiness.* AS SourceOfBusiness,
	|	HotelProductSales.TripPurpose.* AS TripPurpose,
	|	HotelProductSales.DiscountType.* AS DiscountType,
	|	HotelProductSales.Room.* AS Room,
	|	HotelProductSales.Room.RoomType.* AS RoomType,
	|	HotelProductSales.CheckInDate AS CheckInDate,
	|	(CASE
	|			WHEN HotelProductSales.RoomRate.DurationCalculationRuleType = &qDurationCalculationRuleTypeByDays
	|				THEN DATEDIFF(BEGINOFPERIOD(HotelProductSales.CheckInDate, DAY), ENDOFPERIOD(HotelProductSales.CheckOutDate, DAY), DAY)
	|			WHEN BEGINOFPERIOD(HotelProductSales.CheckInDate, DAY) = BEGINOFPERIOD(HotelProductSales.CheckOutDate, DAY)
	|				THEN 1
	|			ELSE DATEDIFF(BEGINOFPERIOD(HotelProductSales.CheckInDate, DAY), BEGINOFPERIOD(HotelProductSales.CheckOutDate, DAY), DAY)
	|		END) AS Duration,
	|	HotelProductSales.CheckOutDate AS CheckOutDate,
	|	Count,
	|	(CASE
	|			WHEN HotelProductSales.AccommodationType.Type = &qTogether
	|				THEN 0
	|			WHEN HotelProductSales.AccommodationType.Type = &qAdditionalBed
	|				THEN 0
	|			ELSE HotelProductSales.Count
	|		END) AS FamilyCount,
	|	Sales,
	|	RoomRevenue,
	|	SalesWithoutVAT,
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
	|	PrevPeriodSales,
	|	PrevPeriodSalesWithoutVAT,
	|	PrevPeriodGuestDays,
	|	PeriodSales,
	|	PeriodSalesWithoutVAT,
	|	PeriodGuestDays,
	|	NextPeriodSales,
	|	NextPeriodSalesWithoutVAT,
	|	NextPeriodGuestDays,
	|	SalesInSettlements,
	|	SalesWithoutVATInSettlements,
	|	PeriodSalesInSettlements,
	|	PeriodSalesWithoutVATInSettlements,
	|	PaymentAmount,
	|	PaymentAmountWithoutVAT,
	|	CashSum,
	|	CreditCardSum,
	|	BankTransferSum,
	|	InternetSum,
	|	BonusesSum,
	|	GiftCertificatesSum}
	|FROM
	|	(SELECT
	|		HotelProductTotalSales.ReportingCurrency AS ReportingCurrency,
	|		HotelProductTotalSales.Hotel AS Hotel,
	|		HotelProductTotalSales.HotelProduct AS HotelProduct,
	|		HotelProductTotalSales.Agent AS Agent,
	|		HotelProductTotalSales.Customer AS Customer,
	|		HotelProductTotalSales.Contract AS Contract,
	|		HotelProductTotalSales.GuestGroup AS GuestGroup,
	|		HotelProductTotalSales.Client AS Client,
	|		HotelProductTotalSales.ParentDoc AS ParentDoc,
	|		HotelProductTotalSales.NumberOfPersons AS NumberOfPersons,
	|		HotelProductTotalSales.PaymentMethod AS PlannedPaymentMethod,
	|		HotelProductTotalSales.Room AS Room,
	|		HotelProductTotalSales.RoomRate AS RoomRate,
	|		HotelProductTotalSales.AccommodationType AS AccommodationType,
	|		HotelProductTotalSales.ClientType AS ClientType,
	|		HotelProductTotalSales.MarketingCode AS MarketingCode,
	|		HotelProductTotalSales.SourceOfBusiness AS SourceOfBusiness,
	|		HotelProductTotalSales.TripPurpose AS TripPurpose,
	|		HotelProductTotalSales.DiscountType AS DiscountType,
	|		HotelProductTotalSales.IsVoided AS IsVoided,
	|		MIN(HotelProductTotalSales.CheckInDate) AS CheckInDate,
	|		MAX(HotelProductTotalSales.CheckOutDate) AS CheckOutDate,
	|		SUM(HotelProductTotalSales.Sales) AS Sales,
	|		SUM(HotelProductTotalSales.RoomRevenue) AS RoomRevenue,
	|		SUM(HotelProductTotalSales.SalesWithoutVAT) AS SalesWithoutVAT,
	|		SUM(HotelProductTotalSales.RoomRevenueWithoutVAT) AS RoomRevenueWithoutVAT,
	|		SUM(HotelProductTotalSales.CommissionSum) AS CommissionSum,
	|		SUM(HotelProductTotalSales.CommissionSumWithoutVAT) AS CommissionSumWithoutVAT,
	|		SUM(HotelProductTotalSales.DiscountSum) AS DiscountSum,
	|		SUM(HotelProductTotalSales.DiscountSumWithoutVAT) AS DiscountSumWithoutVAT,
	|		SUM(HotelProductTotalSales.RoomsRented) AS RoomsRented,
	|		SUM(HotelProductTotalSales.BedsRented) AS BedsRented,
	|		SUM(HotelProductTotalSales.AdditionalBedsRented) AS AdditionalBedsRented,
	|		SUM(HotelProductTotalSales.GuestDays) AS GuestDays,
	|		SUM(HotelProductTotalSales.GuestsCheckedIn) AS GuestsCheckedIn,
	|		SUM(HotelProductTotalSales.PeriodSales) AS PeriodSales,
	|		SUM(HotelProductTotalSales.PeriodSalesWithoutVAT) AS PeriodSalesWithoutVAT,
	|		SUM(HotelProductTotalSales.PeriodGuestDays) AS PeriodGuestDays,
	|		SUM(HotelProductTotalSales.PrevPeriodSales) AS PrevPeriodSales,
	|		SUM(HotelProductTotalSales.PrevPeriodSalesWithoutVAT) AS PrevPeriodSalesWithoutVAT,
	|		SUM(HotelProductTotalSales.PrevPeriodGuestDays) AS PrevPeriodGuestDays,
	|		SUM(HotelProductTotalSales.NextPeriodSales) AS NextPeriodSales,
	|		SUM(HotelProductTotalSales.NextPeriodSalesWithoutVAT) AS NextPeriodSalesWithoutVAT,
	|		SUM(HotelProductTotalSales.NextPeriodGuestDays) AS NextPeriodGuestDays,
	|		SUM(HotelProductTotalSales.SalesInSettlements) AS SalesInSettlements,
	|		SUM(HotelProductTotalSales.SalesWithoutVATInSettlements) AS SalesWithoutVATInSettlements,
	|		SUM(HotelProductTotalSales.PeriodSalesInSettlements) AS PeriodSalesInSettlements,
	|		SUM(HotelProductTotalSales.PeriodSalesWithoutVATInSettlements) AS PeriodSalesWithoutVATInSettlements,
	|		SUM(HotelProductTotalSales.PaymentAmount) AS PaymentAmount,
	|		SUM(HotelProductTotalSales.PaymentAmountWithoutVAT) AS PaymentAmountWithoutVAT,
	|		SUM(HotelProductTotalSales.CashSum) AS CashSum,
	|		SUM(HotelProductTotalSales.CreditCardSum) AS CreditCardSum,
	|		SUM(HotelProductTotalSales.BankTransferSum) AS BankTransferSum,
	|		SUM(HotelProductTotalSales.InternetSum) AS InternetSum,
	|		SUM(HotelProductTotalSales.BonusesSum) AS BonusesSum,
	|		SUM(HotelProductTotalSales.GiftCertificatesSum) AS GiftCertificatesSum,
	|		COUNT(DISTINCT HotelProductTotalSales.HotelProduct) AS Count
	|	FROM
	|		(SELECT
	|			HotelProductTotalSales.ReportingCurrency AS ReportingCurrency,
	|			HotelProductTotalSales.Hotel AS Hotel,
	|			HotelProductTotalSales.HotelProduct AS HotelProduct,
	|			HotelProductTotalSales.Agent AS Agent,
	|			HotelProductTotalSales.Customer AS Customer,
	|			HotelProductTotalSales.Contract AS Contract,
	|			HotelProductTotalSales.GuestGroup AS GuestGroup,
	|			HotelProductTotalSales.Client AS Client,
	|			HotelProductTotalSales.ParentDoc AS ParentDoc,
	|			HotelProductTotalSales.NumberOfPersons AS NumberOfPersons,
	|			HotelProductTotalSales.PaymentMethod AS PaymentMethod,
	|			HotelProductTotalSales.Room AS Room,
	|			HotelProductTotalSales.RoomRate AS RoomRate,
	|			HotelProductTotalSales.AccommodationType AS AccommodationType,
	|			HotelProductTotalSales.ClientType AS ClientType,
	|			HotelProductTotalSales.MarketingCode AS MarketingCode,
	|			HotelProductTotalSales.SourceOfBusiness AS SourceOfBusiness,
	|			HotelProductTotalSales.TripPurpose AS TripPurpose,
	|			HotelProductTotalSales.DiscountType AS DiscountType,
	|			HotelProductTotalSales.CheckInDate AS CheckInDate,
	|			HotelProductTotalSales.CheckOutDate AS CheckOutDate,
	|			FALSE AS IsVoided,
	|			HotelProductTotalSales.Sales AS Sales,
	|			HotelProductTotalSales.RoomRevenue AS RoomRevenue,
	|			HotelProductTotalSales.SalesWithoutVAT AS SalesWithoutVAT,
	|			HotelProductTotalSales.RoomRevenueWithoutVAT AS RoomRevenueWithoutVAT,
	|			HotelProductTotalSales.CommissionSum AS CommissionSum,
	|			HotelProductTotalSales.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|			HotelProductTotalSales.DiscountSum AS DiscountSum,
	|			HotelProductTotalSales.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|			HotelProductTotalSales.RoomsRented AS RoomsRented,
	|			HotelProductTotalSales.BedsRented AS BedsRented,
	|			HotelProductTotalSales.AdditionalBedsRented AS AdditionalBedsRented,
	|			HotelProductTotalSales.GuestDays AS GuestDays,
	|			HotelProductTotalSales.GuestsCheckedIn AS GuestsCheckedIn,
	|			0 AS PeriodSales,
	|			0 AS PeriodSalesWithoutVAT,
	|			0 AS PeriodGuestDays,
	|			0 AS PrevPeriodSales,
	|			0 AS PrevPeriodSalesWithoutVAT,
	|			0 AS PrevPeriodGuestDays,
	|			0 AS NextPeriodSales,
	|			0 AS NextPeriodSalesWithoutVAT,
	|			0 AS NextPeriodGuestDays,
	|			0 AS SalesInSettlements,
	|			0 AS SalesWithoutVATInSettlements,
	|			0 AS PeriodSalesInSettlements,
	|			0 AS PeriodSalesWithoutVATInSettlements,
	|			0 AS PaymentAmount,
	|			0 AS PaymentAmountWithoutVAT,
	|			0 AS CashSum,
	|			0 AS CreditCardSum,
	|			0 AS BankTransferSum,
	|			0 AS InternetSum,
	|			0 AS BonusesSum,
	|			0 AS GiftCertificatesSum
	|		FROM
	|			HotelProductTotalSales AS HotelProductTotalSales
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			VoidedHotelProductsByCreateDate.ReportingCurrency,
	|			VoidedHotelProductsByCreateDate.Hotel,
	|			VoidedHotelProductsByCreateDate.HotelProduct,
	|			0,
	|			0,
	|			0,
	|			0,
	|			VoidedHotelProductsByCreateDate.Client,
	|			0,
	|			0,
	|			VoidedHotelProductsByCreateDate.PaymentMethod,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			VoidedHotelProductsByCreateDate.CheckInDate,
	|			VoidedHotelProductsByCreateDate.CheckOutDate,
	|			FALSE,
	|			VoidedHotelProductsByCreateDate.Sales,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			VoidedHotelProductsByCreateDate.GuestDays,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0
	|		FROM
	|			VoidedHotelProductsByCreateDate AS VoidedHotelProductsByCreateDate
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			VoidedHotelProductsByDeleteDate.ReportingCurrency,
	|			VoidedHotelProductsByDeleteDate.Hotel,
	|			VoidedHotelProductsByDeleteDate.HotelProduct,
	|			0,
	|			0,
	|			0,
	|			0,
	|			VoidedHotelProductsByDeleteDate.Client,
	|			0,
	|			0,
	|			VoidedHotelProductsByDeleteDate.PaymentMethod,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			VoidedHotelProductsByDeleteDate.CheckInDate,
	|			VoidedHotelProductsByDeleteDate.CheckOutDate,
	|			TRUE,
	|			VoidedHotelProductsByDeleteDate.Sales,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			VoidedHotelProductsByDeleteDate.GuestDays,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0
	|		FROM
	|			VoidedHotelProductsByDeleteDate AS VoidedHotelProductsByDeleteDate
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			HotelProductCurPeriodSales.ReportingCurrency,
	|			HotelProductCurPeriodSales.Hotel,
	|			HotelProductCurPeriodSales.HotelProduct,
	|			HotelProductCurPeriodSales.Agent,
	|			HotelProductCurPeriodSales.Customer,
	|			HotelProductCurPeriodSales.Contract,
	|			HotelProductCurPeriodSales.GuestGroup,
	|			HotelProductCurPeriodSales.Client,
	|			HotelProductCurPeriodSales.ParentDoc,
	|			HotelProductCurPeriodSales.NumberOfPersons,
	|			HotelProductCurPeriodSales.PaymentMethod,
	|			HotelProductCurPeriodSales.Room,
	|			HotelProductCurPeriodSales.RoomRate,
	|			HotelProductCurPeriodSales.AccommodationType,
	|			HotelProductCurPeriodSales.ClientType,
	|			HotelProductCurPeriodSales.MarketingCode,
	|			HotelProductCurPeriodSales.SourceOfBusiness,
	|			HotelProductCurPeriodSales.TripPurpose,
	|			HotelProductCurPeriodSales.DiscountType,
	|			HotelProductCurPeriodSales.CheckInDate,
	|			HotelProductCurPeriodSales.CheckOutDate,
	|			FALSE,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			HotelProductCurPeriodSales.Sales,
	|			HotelProductCurPeriodSales.SalesWithoutVAT,
	|			HotelProductCurPeriodSales.GuestDays,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0
	|		FROM
	|			HotelProductCurPeriodSales AS HotelProductCurPeriodSales
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			HotelProductPrevPeriodSales.ReportingCurrency,
	|			HotelProductPrevPeriodSales.Hotel,
	|			HotelProductPrevPeriodSales.HotelProduct,
	|			HotelProductPrevPeriodSales.Agent,
	|			HotelProductPrevPeriodSales.Customer,
	|			HotelProductPrevPeriodSales.Contract,
	|			HotelProductPrevPeriodSales.GuestGroup,
	|			HotelProductPrevPeriodSales.Client,
	|			HotelProductPrevPeriodSales.ParentDoc,
	|			HotelProductPrevPeriodSales.NumberOfPersons,
	|			HotelProductPrevPeriodSales.PaymentMethod,
	|			HotelProductPrevPeriodSales.Room,
	|			HotelProductPrevPeriodSales.RoomRate,
	|			HotelProductPrevPeriodSales.AccommodationType,
	|			HotelProductPrevPeriodSales.ClientType,
	|			HotelProductPrevPeriodSales.MarketingCode,
	|			HotelProductPrevPeriodSales.SourceOfBusiness,
	|			HotelProductPrevPeriodSales.TripPurpose,
	|			HotelProductPrevPeriodSales.DiscountType,
	|			HotelProductPrevPeriodSales.CheckInDate,
	|			HotelProductPrevPeriodSales.CheckOutDate,
	|			FALSE,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			HotelProductPrevPeriodSales.Sales,
	|			HotelProductPrevPeriodSales.SalesWithoutVAT,
	|			HotelProductPrevPeriodSales.GuestDays,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0
	|		FROM
	|			HotelProductPrevPeriodSales AS HotelProductPrevPeriodSales
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			HotelProductNextPeriodSales.ReportingCurrency,
	|			HotelProductNextPeriodSales.Hotel,
	|			HotelProductNextPeriodSales.HotelProduct,
	|			HotelProductNextPeriodSales.Agent,
	|			HotelProductNextPeriodSales.Customer,
	|			HotelProductNextPeriodSales.Contract,
	|			HotelProductNextPeriodSales.GuestGroup,
	|			HotelProductNextPeriodSales.Client,
	|			HotelProductNextPeriodSales.ParentDoc,
	|			HotelProductNextPeriodSales.NumberOfPersons,
	|			HotelProductNextPeriodSales.PaymentMethod,
	|			HotelProductNextPeriodSales.Room,
	|			HotelProductNextPeriodSales.RoomRate,
	|			HotelProductNextPeriodSales.AccommodationType,
	|			HotelProductNextPeriodSales.ClientType,
	|			HotelProductNextPeriodSales.MarketingCode,
	|			HotelProductNextPeriodSales.SourceOfBusiness,
	|			HotelProductNextPeriodSales.TripPurpose,
	|			HotelProductNextPeriodSales.DiscountType,
	|			HotelProductNextPeriodSales.CheckInDate,
	|			HotelProductNextPeriodSales.CheckOutDate,
	|			FALSE,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			HotelProductNextPeriodSales.Sales,
	|			HotelProductNextPeriodSales.SalesWithoutVAT,
	|			HotelProductNextPeriodSales.GuestDays,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0
	|		FROM
	|			HotelProductNextPeriodSales AS HotelProductNextPeriodSales
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			HotelProductAccountsReceivable.ReportingCurrency,
	|			HotelProductAccountsReceivable.Hotel,
	|			HotelProductAccountsReceivable.HotelProduct,
	|			HotelProductAccountsReceivable.Agent,
	|			HotelProductAccountsReceivable.Customer,
	|			HotelProductAccountsReceivable.Contract,
	|			HotelProductAccountsReceivable.GuestGroup,
	|			HotelProductAccountsReceivable.Client,
	|			HotelProductAccountsReceivable.ParentDoc,
	|			HotelProductAccountsReceivable.NumberOfPersons,
	|			HotelProductAccountsReceivable.PaymentMethod,
	|			HotelProductAccountsReceivable.Room,
	|			HotelProductAccountsReceivable.RoomRate,
	|			HotelProductAccountsReceivable.AccommodationType,
	|			HotelProductAccountsReceivable.ClientType,
	|			HotelProductAccountsReceivable.MarketingCode,
	|			HotelProductAccountsReceivable.SourceOfBusiness,
	|			HotelProductAccountsReceivable.TripPurpose,
	|			HotelProductAccountsReceivable.DiscountType,
	|			HotelProductAccountsReceivable.CheckInDate,
	|			HotelProductAccountsReceivable.CheckOutDate,
	|			FALSE,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			HotelProductAccountsReceivable.Sum,
	|			HotelProductAccountsReceivable.SumWithoutVAT,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0
	|		FROM
	|			HotelProductAccountsReceivable AS HotelProductAccountsReceivable
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			HotelProductPeriodAccountsReceivable.ReportingCurrency,
	|			HotelProductPeriodAccountsReceivable.Hotel,
	|			HotelProductPeriodAccountsReceivable.HotelProduct,
	|			HotelProductPeriodAccountsReceivable.Agent,
	|			HotelProductPeriodAccountsReceivable.Customer,
	|			HotelProductPeriodAccountsReceivable.Contract,
	|			HotelProductPeriodAccountsReceivable.GuestGroup,
	|			HotelProductPeriodAccountsReceivable.Client,
	|			HotelProductPeriodAccountsReceivable.ParentDoc,
	|			HotelProductPeriodAccountsReceivable.NumberOfPersons,
	|			HotelProductPeriodAccountsReceivable.PaymentMethod,
	|			HotelProductPeriodAccountsReceivable.Room,
	|			HotelProductPeriodAccountsReceivable.RoomRate,
	|			HotelProductPeriodAccountsReceivable.AccommodationType,
	|			HotelProductPeriodAccountsReceivable.ClientType,
	|			HotelProductPeriodAccountsReceivable.MarketingCode,
	|			HotelProductPeriodAccountsReceivable.SourceOfBusiness,
	|			HotelProductPeriodAccountsReceivable.TripPurpose,
	|			HotelProductPeriodAccountsReceivable.DiscountType,
	|			HotelProductPeriodAccountsReceivable.CheckInDate,
	|			HotelProductPeriodAccountsReceivable.CheckOutDate,
	|			FALSE,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			HotelProductPeriodAccountsReceivable.Sum,
	|			HotelProductPeriodAccountsReceivable.SumWithoutVAT,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0
	|		FROM
	|			HotelProductPeriodAccountsReceivable AS HotelProductPeriodAccountsReceivable
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			HotelProductPayments.ReportingCurrency,
	|			HotelProductPayments.Hotel,
	|			HotelProductPayments.HotelProduct,
	|			HotelProductPayments.Agent,
	|			HotelProductPayments.Customer,
	|			HotelProductPayments.Contract,
	|			HotelProductPayments.GuestGroup,
	|			HotelProductPayments.Client,
	|			HotelProductPayments.ParentDoc,
	|			HotelProductPayments.NumberOfPersons,
	|			HotelProductPayments.PaymentMethod,
	|			HotelProductPayments.Room,
	|			HotelProductPayments.RoomRate,
	|			HotelProductPayments.AccommodationType,
	|			HotelProductPayments.ClientType,
	|			HotelProductPayments.MarketingCode,
	|			HotelProductPayments.SourceOfBusiness,
	|			HotelProductPayments.TripPurpose,
	|			HotelProductPayments.DiscountType,
	|			HotelProductPayments.CheckInDate,
	|			HotelProductPayments.CheckOutDate,
	|			FALSE,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			HotelProductPayments.PaymentSum,
	|			HotelProductPayments.PaymentSumWithoutVAT,
	|			HotelProductPayments.PaymentSumByCash,
	|			HotelProductPayments.PaymentSumByCreditCard,
	|			HotelProductPayments.PaymentSumByBankTransfer,
	|			HotelProductPayments.PaymentSumByInternet,
	|			HotelProductPayments.PaymentSumByBonuses,
	|			HotelProductPayments.PaymentSumByGiftCertificates
	|		FROM
	|			HotelProductPayments AS HotelProductPayments) AS HotelProductTotalSales
	|	
	|	GROUP BY
	|		HotelProductTotalSales.ReportingCurrency,
	|		HotelProductTotalSales.Hotel,
	|		HotelProductTotalSales.HotelProduct,
	|		HotelProductTotalSales.Agent,
	|		HotelProductTotalSales.Customer,
	|		HotelProductTotalSales.Contract,
	|		HotelProductTotalSales.GuestGroup,
	|		HotelProductTotalSales.Client,
	|		HotelProductTotalSales.ParentDoc,
	|		HotelProductTotalSales.NumberOfPersons,
	|		HotelProductTotalSales.PaymentMethod,
	|		HotelProductTotalSales.Room,
	|		HotelProductTotalSales.RoomRate,
	|		HotelProductTotalSales.AccommodationType,
	|		HotelProductTotalSales.ClientType,
	|		HotelProductTotalSales.MarketingCode,
	|		HotelProductTotalSales.SourceOfBusiness,
	|		HotelProductTotalSales.TripPurpose,
	|		HotelProductTotalSales.DiscountType,
	|		HotelProductTotalSales.IsVoided) AS HotelProductSales
	|WHERE
	|	(NOT &qShowDifferencesOnly
	|			OR &qShowDifferencesOnly
	|				AND NOT HotelProductSales.HotelProduct IN
	|						(SELECT
	|							SalesByHotelProducts.HotelProduct
	|						FROM
	|							SalesByHotelProducts AS SalesByHotelProducts))
	|{WHERE
	|	HotelProductSales.ReportingCurrency.*,
	|	HotelProductSales.HotelProduct.RoomQuota.* AS RoomQuota,
	|	HotelProductSales.Hotel.* AS Hotel,
	|	HotelProductSales.HotelProduct.RoomType.* AS RoomType,
	|	HotelProductSales.HotelProduct.* AS HotelProduct,
	|	HotelProductSales.HotelProduct.Parent.* AS HotelProductParent,
	|	HotelProductSales.Agent.* AS Agent,
	|	HotelProductSales.Customer.* AS Customer,
	|	HotelProductSales.Contract.* AS Contract,
	|	HotelProductSales.GuestGroup.* AS GuestGroup,
	|	HotelProductSales.Client.* AS Client,
	|	HotelProductSales.ParentDoc.* AS ParentDoc,
	|	HotelProductSales.ParentDoc.Remarks AS Remarks,
	|	HotelProductSales.NumberOfPersons AS NumberOfPersons,
	|	HotelProductSales.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	HotelProductSales.RoomRate.* AS RoomRate,
	|	HotelProductSales.AccommodationType.* AS AccommodationType,
	|	HotelProductSales.ClientType.* AS ClientType,
	|	HotelProductSales.MarketingCode.* AS MarketingCode,
	|	HotelProductSales.SourceOfBusiness.* AS SourceOfBusiness,
	|	HotelProductSales.TripPurpose.* AS TripPurpose,
	|	HotelProductSales.DiscountType.* AS DiscountType,
	|	HotelProductSales.Room.* AS Room,
	|	HotelProductSales.Room.RoomType.* AS RoomType,
	|	HotelProductSales.CheckInDate AS CheckInDate,
	|	(CASE
	|			WHEN HotelProductSales.RoomRate.DurationCalculationRuleType = &qDurationCalculationRuleTypeByDays
	|				THEN DATEDIFF(BEGINOFPERIOD(HotelProductSales.CheckInDate, DAY), ENDOFPERIOD(HotelProductSales.CheckOutDate, DAY), DAY)
	|			WHEN BEGINOFPERIOD(HotelProductSales.CheckInDate, DAY) = BEGINOFPERIOD(HotelProductSales.CheckOutDate, DAY)
	|				THEN 1
	|			ELSE DATEDIFF(BEGINOFPERIOD(HotelProductSales.CheckInDate, DAY), BEGINOFPERIOD(HotelProductSales.CheckOutDate, DAY), DAY)
	|		END) AS Duration,
	|	HotelProductSales.CheckOutDate AS CheckOutDate,
	|	HotelProductSales.Count,
	|	(CASE
	|			WHEN HotelProductSales.AccommodationType.Type = &qTogether
	|				THEN 0
	|			WHEN HotelProductSales.AccommodationType.Type = &qAdditionalBed
	|				THEN 0
	|			ELSE HotelProductSales.Count
	|		END) AS FamilyCount,
	|	HotelProductSales.Sales,
	|	HotelProductSales.RoomRevenue,
	|	HotelProductSales.SalesWithoutVAT,
	|	HotelProductSales.RoomRevenueWithoutVAT,
	|	HotelProductSales.CommissionSum,
	|	HotelProductSales.CommissionSumWithoutVAT,
	|	HotelProductSales.DiscountSum,
	|	HotelProductSales.DiscountSumWithoutVAT,
	|	HotelProductSales.RoomsRented,
	|	HotelProductSales.BedsRented,
	|	HotelProductSales.AdditionalBedsRented,
	|	HotelProductSales.GuestDays,
	|	HotelProductSales.GuestsCheckedIn,
	|	HotelProductSales.PeriodSales,
	|	HotelProductSales.PeriodSalesWithoutVAT,
	|	HotelProductSales.PeriodGuestDays,
	|	HotelProductSales.PrevPeriodSales,
	|	HotelProductSales.PrevPeriodSalesWithoutVAT,
	|	HotelProductSales.PrevPeriodGuestDays,
	|	HotelProductSales.NextPeriodSales,
	|	HotelProductSales.NextPeriodSalesWithoutVAT,
	|	HotelProductSales.NextPeriodGuestDays,
	|	HotelProductSales.SalesInSettlements,
	|	HotelProductSales.SalesWithoutVATInSettlements,
	|	HotelProductSales.PeriodSalesInSettlements,
	|	HotelProductSales.PeriodSalesWithoutVATInSettlements,
	|	HotelProductSales.PaymentAmount,
	|	HotelProductSales.PaymentAmountWithoutVAT,
	|	HotelProductSales.CashSum,
	|	HotelProductSales.CreditCardSum,
	|	HotelProductSales.BankTransferSum,
	|	HotelProductSales.InternetSum,
	|	HotelProductSales.BonusesSum,
	|	HotelProductSales.GiftCertificatesSum}
	|
	|ORDER BY
	|	ReportingCurrency,
	|	Customer,
	|	HotelProduct
	|{ORDER BY
	|	ReportingCurrency.*,
	|	HotelProductSales.HotelProduct.RoomQuota.* AS RoomQuota,
	|	Hotel.*,
	|	HotelProduct.*,
	|	HotelProductSales.HotelProduct.Parent.* AS HotelProductParent,
	|	Agent.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	Client.*,
	|	HotelProductSales.ParentDoc.* AS ParentDoc,
	|	HotelProductSales.ParentDoc.Remarks AS Remarks,
	|	HotelProductSales.NumberOfPersons AS NumberOfPersons,
	|	HotelProductSales.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	HotelProductSales.RoomRate.* AS RoomRate,
	|	HotelProductSales.AccommodationType.* AS AccommodationType,
	|	HotelProductSales.ClientType.* AS ClientType,
	|	HotelProductSales.MarketingCode.* AS MarketingCode,
	|	HotelProductSales.SourceOfBusiness.* AS SourceOfBusiness,
	|	HotelProductSales.TripPurpose.* AS TripPurpose,
	|	HotelProductSales.DiscountType.* AS DiscountType,
	|	HotelProductSales.Room.* AS Room,
	|	HotelProductSales.Room.RoomType.* AS RoomType,
	|	HotelProductSales.CheckInDate AS CheckInDate,
	|	(CASE
	|			WHEN HotelProductSales.RoomRate.DurationCalculationRuleType = &qDurationCalculationRuleTypeByDays
	|				THEN DATEDIFF(BEGINOFPERIOD(HotelProductSales.CheckInDate, DAY), ENDOFPERIOD(HotelProductSales.CheckOutDate, DAY), DAY)
	|			WHEN BEGINOFPERIOD(HotelProductSales.CheckInDate, DAY) = BEGINOFPERIOD(HotelProductSales.CheckOutDate, DAY)
	|				THEN 1
	|			ELSE DATEDIFF(BEGINOFPERIOD(HotelProductSales.CheckInDate, DAY), BEGINOFPERIOD(HotelProductSales.CheckOutDate, DAY), DAY)
	|		END) AS Duration,
	|	HotelProductSales.CheckOutDate AS CheckOutDate,
	|	Count,
	|	(CASE
	|			WHEN HotelProductSales.AccommodationType.Type = &qTogether
	|				THEN 0
	|			WHEN HotelProductSales.AccommodationType.Type = &qAdditionalBed
	|				THEN 0
	|			ELSE HotelProductSales.Count
	|		END) AS FamilyCount,
	|	Sales,
	|	RoomRevenue,
	|	SalesWithoutVAT,
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
	|	PeriodSales,
	|	PeriodSalesWithoutVAT,
	|	PeriodGuestDays,
	|	NextPeriodSales,
	|	NextPeriodSalesWithoutVAT,
	|	NextPeriodGuestDays,
	|	PrevPeriodSales,
	|	PrevPeriodSalesWithoutVAT,
	|	PrevPeriodGuestDays,
	|	SalesInSettlements,
	|	SalesWithoutVATInSettlements,
	|	PeriodSalesInSettlements,
	|	PeriodSalesWithoutVATInSettlements,
	|	PaymentAmount,
	|	PaymentAmountWithoutVAT,
	|	CashSum,
	|	CreditCardSum,
	|	BankTransferSum,
	|	InternetSum,
	|	BonusesSum,
	|	GiftCertificatesSum}
	|TOTALS
	|	SUM(Count),
	|	SUM(FamilyCount),
	|	SUM(Sales),
	|	SUM(RoomRevenue),
	|	SUM(SalesWithoutVAT),
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
	|	SUM(PeriodSales),
	|	SUM(PeriodSalesWithoutVAT),
	|	SUM(PeriodGuestDays),
	|	SUM(PrevPeriodSales),
	|	SUM(PrevPeriodSalesWithoutVAT),
	|	SUM(PrevPeriodGuestDays),
	|	SUM(NextPeriodSales),
	|	SUM(NextPeriodSalesWithoutVAT),
	|	SUM(NextPeriodGuestDays),
	|	SUM(SalesInSettlements),
	|	SUM(SalesWithoutVATInSettlements),
	|	SUM(PeriodSalesInSettlements),
	|	SUM(PeriodSalesWithoutVATInSettlements),
	|	SUM(PaymentAmount),
	|	SUM(PaymentAmountWithoutVAT),
	|	SUM(CashSum),
	|	SUM(CreditCardSum),
	|	SUM(BankTransferSum),
	|	SUM(InternetSum),
	|	SUM(BonusesSum),
	|	SUM(GiftCertificatesSum)
	|BY
	|	OVERALL,
	|	ReportingCurrency,
	|	Customer HIERARCHY
	|{TOTALS BY
	|	ReportingCurrency.*,
	|	HotelProductSales.HotelProduct.RoomQuota.* AS RoomQuota,
	|	Hotel.*,
	|	HotelProduct.*,
	|	HotelProductSales.HotelProduct.Parent.* AS HotelProductParent,
	|	Agent.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	Client.*,
	|	(CASE
	|			WHEN HotelProductSales.RoomRate.DurationCalculationRuleType = &qDurationCalculationRuleTypeByDays
	|				THEN DATEDIFF(BEGINOFPERIOD(HotelProductSales.CheckInDate, DAY), ENDOFPERIOD(HotelProductSales.CheckOutDate, DAY), DAY)
	|			WHEN BEGINOFPERIOD(HotelProductSales.CheckInDate, DAY) = BEGINOFPERIOD(HotelProductSales.CheckOutDate, DAY)
	|				THEN 1
	|			ELSE DATEDIFF(BEGINOFPERIOD(HotelProductSales.CheckInDate, DAY), BEGINOFPERIOD(HotelProductSales.CheckOutDate, DAY), DAY)
	|		END) AS Duration,
	|	HotelProductSales.ParentDoc.* AS ParentDoc,
	|	HotelProductSales.NumberOfPersons AS NumberOfPersons,
	|	HotelProductSales.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	HotelProductSales.Room.* AS Room,
	|	HotelProductSales.Room.RoomType.* AS RoomType,
	|	HotelProductSales.RoomRate.* AS RoomRate,
	|	HotelProductSales.AccommodationType.* AS AccommodationType,
	|	HotelProductSales.ClientType.* AS ClientType,
	|	HotelProductSales.MarketingCode.* AS MarketingCode,
	|	HotelProductSales.SourceOfBusiness.* AS SourceOfBusiness,
	|	HotelProductSales.TripPurpose.* AS TripPurpose,
	|	HotelProductSales.DiscountType.* AS DiscountType}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Vaucher sales'; RU='Продажи путевок'; DE='Verkauf von Reiseschecks'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
Function pmIsResource(pName) Export
	If pName = "Sales" 
	   Or pName = "RoomRevenue" 
	   Or pName = "SalesWithoutVAT" 
	   Or pName = "RoomRevenueWithoutVAT" 
	   Or pName = "CommissionSum" 
	   Or pName = "CommissionSumWithoutVAT" 
	   Or pName = "DiscountSum" 
	   Or pName = "DiscountSumWithoutVAT" 
	   Or pName = "RoomsRented" 
	   Or pName = "BedsRented" 
	   Or pName = "AdditionalBedsRented" 
	   Or pName = "Count" 
	   Or pName = "FamilyCount" 
	   Or pName = "GuestDays" 
	   Or pName = "GuestsCheckedIn" 
	   Or pName = "PrevPeriodSales"
	   Or pName = "PrevPeriodSalesWithoutVAT"
	   Or pName = "PrevPeriodGuestDays" 
	   Or pName = "NextPeriodSales"
	   Or pName = "NextPeriodSalesWithoutVAT"
	   Or pName = "NextPeriodGuestDays" 
	   Or pName = "PeriodSales"
	   Or pName = "PeriodSalesWithoutVAT"
	   Or pName = "PeriodGuestDays" 
	   Or pName = "SalesInSettlements"
	   Or pName = "SalesWithoutVATInSettlements"
	   Or pName = "PeriodSalesInSettlements"
	   Or pName = "PeriodSalesWithoutVATInSettlements"
	   Or pName = "PaymentAmount"
	   Or pName = "PaymentAmountWithoutVAT" 
	   Or pName = "CashSum" 
	   Or pName = "CreditCardSum" 
	   Or pName = "BankTransferSum" 
	   Or pName = "InternetSum" 
	   Or pName = "BonusesSum" 
	   Or pName = "GiftCertificatesSum" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // pmIsResource

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
