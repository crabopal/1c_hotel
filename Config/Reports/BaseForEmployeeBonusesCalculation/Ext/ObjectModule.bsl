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
	If ValueIsFilled(RoomType) Then
		If Not RoomType.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Room type ';ru='Тип номер ';de='Zimmertyp '") + 
			                     TrimAll(RoomType.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Room types folder ';ru='Группа типов номеров ';de='Zimmertypgruppe '") + 
			                     TrimAll(RoomType.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(Department) Then
		If Not Department.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Department ';ru='Отдел ';de='Abteilung '") + 
			                     TrimAll(Department.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Departments folder ';ru='Группа отделов ';de='Abteilunggruppe '") + 
			                     TrimAll(Department.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(Employee) Then
		If Not Employee.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Employee ';ru='Сотрудник ';de='Mitarbeiter '") + 
			                     TrimAll(Employee.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Employees folder ';ru='Группа сотрудников ';de='Mitarbeitergruppe '") + 
			                     TrimAll(Employee.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(WalkinSourceOfBusiness) Then
		If Not WalkinSourceOfBusiness.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Source ';ru='Источник ';de='Quelle '") + 
			                     TrimAll(WalkinSourceOfBusiness.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа источников '; en = 'Sources folder '; de = 'Quellegruppe '") + 
			                     TrimAll(WalkinSourceOfBusiness.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;					 
	If ValueIsFilled(CateringServiceGroup) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Набор услуг питания '; en = 'Catering services '; de = 'Catering Dienstleistungen '") + 
		                     TrimAll(CateringServiceGroup.Description) + 
		                     ";" + Chars.LF;
	EndIf;					 
	If ValueIsFilled(ExtrasServiceGroup) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Набор доп. услуг '; en = 'Extras services '; de = 'Extras Dienstleistungen '") + 
		                     TrimAll(ExtrasServiceGroup.Description) + 
		                     ";" + Chars.LF;
	EndIf;					 
	If ValueIsFilled(UpsellServiceGroup) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Услуги upsell '; en = 'Upsell services '; de = 'Upsell Dienstleistungen '") + 
		                     TrimAll(UpsellServiceGroup.Description) + 
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
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');
	ReportBuilder.Parameters.Insert("qSourceOfBusiness", WalkinSourceOfBusiness);
	ReportBuilder.Parameters.Insert("qSourceOfBusinessIsEmpty", Not ValueIsFilled(WalkinSourceOfBusiness));
	ReportBuilder.Parameters.Insert("qDepartment", Department);
	ReportBuilder.Parameters.Insert("qDepartmentIsEmpty", Not ValueIsFilled(Department));
	ReportBuilder.Parameters.Insert("qEmployee", Employee);
	ReportBuilder.Parameters.Insert("qEmployeeIsEmpty", Not ValueIsFilled(Employee));
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qRoomTypeIsEmpty", Not ValueIsFilled(RoomType));
	vUseExtrasServicesList = False;
	vExtrasServicesList = New ValueList();
	If ValueIsFilled(ExtrasServiceGroup) Then
		If Not ExtrasServiceGroup.IncludeAll Then
			vUseExtrasServicesList = True;
			vExtrasServicesList = cmGetServiceGroupServices(ExtrasServiceGroup);
		EndIf;
	EndIf;
	ReportBuilder.Parameters.Insert("qUseExtrasServicesList", vUseExtrasServicesList);
	ReportBuilder.Parameters.Insert("qExtrasServicesList", vExtrasServicesList);
	ReportBuilder.Parameters.Insert("qExtrasPercent", ExtrasPercent);
	vUseCateringServicesList = False;
	vCateringServicesList = New ValueList();
	If ValueIsFilled(CateringServiceGroup) Then
		If Not CateringServiceGroup.IncludeAll Then
			vUseCateringServicesList = True;
			vCateringServicesList = cmGetServiceGroupServices(CateringServiceGroup);
		EndIf;
	EndIf;
	ReportBuilder.Parameters.Insert("qUseCateringServicesList", vUseCateringServicesList);
	ReportBuilder.Parameters.Insert("qCateringServicesList", vCateringServicesList);
	ReportBuilder.Parameters.Insert("qCateringPercent", CateringPercent);
	vUseUpsellServicesList = False;
	vUpsellServicesList = New ValueList();
	If ValueIsFilled(UpsellServiceGroup) Then
		If Not UpsellServiceGroup.IncludeAll Then
			vUseUpsellServicesList = True;
			vUpsellServicesList = cmGetServiceGroupServices(UpsellServiceGroup);
		EndIf;
	EndIf;
	ReportBuilder.Parameters.Insert("qUseUpsellServicesList", vUseUpsellServicesList);
	ReportBuilder.Parameters.Insert("qUpsellServicesList", vUpsellServicesList);
	ReportBuilder.Parameters.Insert("qUpsellPercent", UpsellPercent);
	ReportBuilder.Parameters.Insert("qWalkinPercent", WalkinPercent);
	ReportBuilder.Parameters.Insert("qExtrasType", NStr("en='1. Extras'; ru='1. Доп. услуги'; de='1. Extras'"));
	ReportBuilder.Parameters.Insert("qCateringType", NStr("en='2. Catering'; ru='2. Питание'; de='2. Catering'"));
	ReportBuilder.Parameters.Insert("qUpsellType", NStr("en='3. Upsell'; ru='3. Повышение категории'; de='3. Upsell'"));
	ReportBuilder.Parameters.Insert("qWalkinType", NStr("en='4. Walk-in'; ru='4. Заезд от стойки'; de='4. Walk-in'"));
	vBaseTypeCodesList = New ValueList();
	If BaseTypeCodesList.Count() > 0 Then
		vBaseTypeCodesList.LoadValues(BaseTypeCodesList.UnloadValues());
	Else
		vBaseTypeCodesList.Add(0);
		vBaseTypeCodesList.Add(1);
		vBaseTypeCodesList.Add(2);
		vBaseTypeCodesList.Add(3);
	EndIf;
	ReportBuilder.Parameters.Insert("qBaseTypeCodesList", vBaseTypeCodesList);
	
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
	|	BonusesBase.BaseType AS BaseType,
	|	BonusesBase.Company AS Company,
	|	BonusesBase.Hotel AS Hotel,
	|	BonusesBase.ReportingCurrency AS ReportingCurrency,
	|	BonusesBase.Service AS Service,
	|	BonusesBase.AccountingDate AS AccountingDate,
	|	BonusesBase.Room AS Room,
	|	BonusesBase.Customer AS Customer,
	|	BonusesBase.Client AS Client,
	|	BonusesBase.Recorder AS Recorder,
	|	BonusesBase.ParentDoc AS ParentDoc,
	|	BonusesBase.Sales AS Sum,
	|	BonusesBase.Bonuses AS Bonuses,
	|	BonusesBase.FullSales AS SumBeforeDiscount,
	|	BonusesBase.Sales - BonusesBase.CommissionSum AS SumWithoutCommission,
	|	BonusesBase.SalesWithoutVAT AS SumWithoutVAT,
	|	BonusesBase.BonusesWithoutVAT AS BonusesWithoutVAT,
	|	BonusesBase.CommissionSum AS CommissionSum,
	|	BonusesBase.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|	BonusesBase.DiscountSum AS DiscountSum,
	|	BonusesBase.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|	BonusesBase.VATSum AS VATSum,
	|	BonusesBase.Employee AS Employee,
	|	BonusesBase.Period AS Period
	|{SELECT
	|	BaseType,
	|	Period,
	|	Company.*,
	|	Hotel.*,
	|	ReportingCurrency.*,
	|	Service.*,
	|	AccountingDate,
	|	Room.*,
	|	BonusesBase.Resource.*,
	|	BonusesBase.Agent.*,
	|	Customer.*,
	|	BonusesBase.Contract.*,
	|	BonusesBase.ClientType.*,
	|	BonusesBase.MarketingCode.*,
	|	BonusesBase.SourceOfBusiness.*,
	|	Client.*,
	|	BonusesBase.Folio.*,
	|	BonusesBase.Remarks AS Remarks,
	|	Recorder.*,
	|	ParentDoc.*,
	|	BonusesBase.GuestGroup.*,
	|	BonusesBase.TripPurpose.*,
	|	BonusesBase.ServicePackage.*,
	|	BonusesBase.VATRate.*,
	|	BonusesBase.RoomType.*,
	|	BonusesBase.RoomRateType.*,
	|	BonusesBase.RoomRate.*,
	|	Employee.*,
	|	BonusesBase.Performer.* AS Performer,
	|	Sum,
	|	SumBeforeDiscount,
	|	SumWithoutCommission,
	|	SumWithoutVAT,
	|	CommissionSum,
	|	CommissionSumWithoutVAT,
	|	DiscountSum,
	|	DiscountSumWithoutVAT,
	|	VATSum}
	|FROM
	|	(SELECT
	|		&qExtrasType AS BaseType,
	|		0 AS BaseTypeCode,
	|		&qExtrasPercent AS BaseTypePercent,
	|		CASE
	|			WHEN ExtraServices.Sales > 0
	|					AND NOT ExtraServices.Recorder REFS Document.Storno
	|				THEN ExtraServices.Author
	|			WHEN NOT ExtraServices.Recorder.CorrectedCharge.Number IS NULL
	|				THEN ExtraServices.Recorder.CorrectedCharge.Author
	|			WHEN NOT ExtraServices.Recorder.ParentCharge.Number IS NULL
	|				THEN ExtraServices.Recorder.ParentCharge.Author
	|			ELSE ExtraServices.Author
	|		END AS Employee,
	|		CASE
	|			WHEN ExtraServices.Sales > 0
	|					AND NOT ExtraServices.Recorder REFS Document.Storno
	|				THEN ExtraServices.Period
	|			WHEN NOT ExtraServices.Recorder.CorrectedCharge.Number IS NULL
	|				THEN ExtraServices.Recorder.CorrectedCharge.Date
	|			WHEN NOT ExtraServices.Recorder.ParentCharge.Number IS NULL
	|				THEN ExtraServices.Recorder.ParentCharge.Date
	|			ELSE ExtraServices.Period
	|		END AS Period,
	|		ExtraServices.Company AS Company,
	|		ExtraServices.Hotel AS Hotel,
	|		ExtraServices.ReportingCurrency AS ReportingCurrency,
	|		ExtraServices.Service AS Service,
	|		ExtraServices.AccountingDate AS AccountingDate,
	|		ExtraServices.Room AS Room,
	|		ExtraServices.Resource AS Resource,
	|		ExtraServices.Agent AS Agent,
	|		ExtraServices.Customer AS Customer,
	|		ExtraServices.Contract AS Contract,
	|		ExtraServices.ClientType AS ClientType,
	|		ExtraServices.MarketingCode AS MarketingCode,
	|		ExtraServices.SourceOfBusiness AS SourceOfBusiness,
	|		ExtraServices.Client AS Client,
	|		ExtraServices.Folio AS Folio,
	|		ExtraServices.Recorder.Remarks AS Remarks,
	|		ExtraServices.Recorder AS Recorder,
	|		ExtraServices.ParentDoc AS ParentDoc,
	|		ExtraServices.GuestGroup AS GuestGroup,
	|		ExtraServices.TripPurpose AS TripPurpose,
	|		ExtraServices.ServicePackage AS ServicePackage,
	|		ExtraServices.VATRate AS VATRate,
	|		ExtraServices.RoomType AS RoomType,
	|		ExtraServices.RoomRateType AS RoomRateType,
	|		ExtraServices.RoomRate AS RoomRate,
	|		CASE
	|			WHEN NOT ExtraServices.Recorder.ParentCharge.Performer IS NULL
	|				THEN ExtraServices.Recorder.ParentCharge.Performer
	|			ELSE ExtraServices.Recorder.Performer
	|		END AS Performer,
	|		ExtraServices.Sales AS Sales,
	|		ExtraServices.Sales * &qExtrasPercent / 100 AS Bonuses,
	|		ExtraServices.SalesWithoutVAT AS SalesWithoutVAT,
	|		ExtraServices.SalesWithoutVAT * &qExtrasPercent / 100 AS BonusesWithoutVAT,
	|		ExtraServices.CommissionSum AS CommissionSum,
	|		ExtraServices.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
	|		ExtraServices.DiscountSum AS DiscountSum,
	|		ExtraServices.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
	|		ExtraServices.Sales + ExtraServices.DiscountSum AS FullSales,
	|		ExtraServices.VATSum AS VATSum
	|	FROM
	|		AccumulationRegister.Sales AS ExtraServices
	|	WHERE
	|		NOT ExtraServices.IsCorrection
	|		AND NOT CASE
	|					WHEN NOT ExtraServices.Recorder.CorrectedCharge.Number IS NULL
	|						THEN ExtraServices.Recorder.CorrectedCharge.IsInPrice
	|					WHEN NOT ExtraServices.Recorder.ParentCharge.Number IS NULL
	|						THEN ExtraServices.Recorder.ParentCharge.IsInPrice
	|					ELSE ExtraServices.Recorder.IsInPrice
	|				END
	|		AND ExtraServices.Hotel IN HIERARCHY(&qHotel)
	|		AND ISNULL(ExtraServices.Folio.IsClosed, FALSE)
	|		AND (ExtraServices.Folio.DateTimeTo > &qEmptyDate
	|					AND (ExtraServices.Folio.DateTimeTo BETWEEN &qPeriodFrom AND &qPeriodTo)
	|				OR ExtraServices.Folio.DateTimeTo = &qEmptyDate
	|					AND (ExtraServices.Period BETWEEN &qPeriodFrom AND &qPeriodTo))
	|		AND (ExtraServices.RoomType IN HIERARCHY (&qRoomType)
	|				OR &qRoomTypeIsEmpty)
	|		AND (ExtraServices.Service IN (&qExtrasServicesList)
	|				OR NOT &qUseExtrasServicesList)
	|		AND (&qUseCateringServicesList
	|					AND NOT ExtraServices.Service IN (&qCateringServicesList)
	|				OR NOT &qUseCateringServicesList)
	|		AND (&qUseUpsellServicesList
	|					AND NOT ExtraServices.Service IN (&qUpsellServicesList)
	|				OR NOT &qUseUpsellServicesList)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		&qCateringType,
	|		1,
	|		&qCateringPercent,
	|		CASE
	|			WHEN CateringServices.Sales > 0
	|					AND NOT CateringServices.Recorder REFS Document.Storno
	|				THEN CateringServices.Author
	|			WHEN NOT CateringServices.Recorder.CorrectedCharge.Number IS NULL
	|				THEN CateringServices.Recorder.CorrectedCharge.Author
	|			WHEN NOT CateringServices.Recorder.ParentCharge.Number IS NULL
	|				THEN CateringServices.Recorder.ParentCharge.Author
	|			ELSE CateringServices.Author
	|		END,
	|		CASE
	|			WHEN CateringServices.Sales > 0
	|					AND NOT CateringServices.Recorder REFS Document.Storno
	|				THEN CateringServices.Period
	|			WHEN NOT CateringServices.Recorder.CorrectedCharge.Number IS NULL
	|				THEN CateringServices.Recorder.CorrectedCharge.Date
	|			WHEN NOT CateringServices.Recorder.ParentCharge.Number IS NULL
	|				THEN CateringServices.Recorder.ParentCharge.Date
	|			ELSE CateringServices.Period
	|		END,
	|		CateringServices.Company,
	|		CateringServices.Hotel,
	|		CateringServices.ReportingCurrency,
	|		CateringServices.Service,
	|		CateringServices.AccountingDate,
	|		CateringServices.Room,
	|		CateringServices.Resource,
	|		CateringServices.Agent,
	|		CateringServices.Customer,
	|		CateringServices.Contract,
	|		CateringServices.ClientType,
	|		CateringServices.MarketingCode,
	|		CateringServices.SourceOfBusiness,
	|		CateringServices.Client,
	|		CateringServices.Folio,
	|		CateringServices.Recorder.Remarks,
	|		CateringServices.Recorder,
	|		CateringServices.ParentDoc,
	|		CateringServices.GuestGroup,
	|		CateringServices.TripPurpose,
	|		CateringServices.ServicePackage,
	|		CateringServices.VATRate,
	|		CateringServices.RoomType,
	|		CateringServices.RoomRateType,
	|		CateringServices.RoomRate,
	|		CASE
	|			WHEN NOT CateringServices.Recorder.ParentCharge.Performer IS NULL
	|				THEN CateringServices.Recorder.ParentCharge.Performer
	|			ELSE CateringServices.Recorder.Performer
	|		END,
	|		CateringServices.Sales,
	|		CateringServices.Sales * &qCateringPercent / 100,
	|		CateringServices.SalesWithoutVAT,
	|		CateringServices.SalesWithoutVAT * &qCateringPercent / 100,
	|		CateringServices.CommissionSum,
	|		CateringServices.CommissionSumWithoutVAT,
	|		CateringServices.DiscountSum,
	|		CateringServices.DiscountSumWithoutVAT,
	|		CateringServices.Sales + CateringServices.DiscountSum,
	|		CateringServices.VATSum
	|	FROM
	|		AccumulationRegister.Sales AS CateringServices
	|	WHERE
	|		NOT CateringServices.IsCorrection
	|		AND NOT CASE
	|					WHEN NOT CateringServices.Recorder.CorrectedCharge.Number IS NULL
	|						THEN CateringServices.Recorder.CorrectedCharge.IsInPrice
	|					WHEN NOT CateringServices.Recorder.ParentCharge.Number IS NULL
	|						THEN CateringServices.Recorder.ParentCharge.IsInPrice
	|					ELSE CateringServices.Recorder.IsInPrice
	|				END
	|		AND CateringServices.Hotel IN HIERARCHY(&qHotel)
	|		AND ISNULL(CateringServices.Folio.IsClosed, FALSE)
	|		AND (CateringServices.Folio.DateTimeTo > &qEmptyDate
	|					AND (CateringServices.Folio.DateTimeTo BETWEEN &qPeriodFrom AND &qPeriodTo)
	|				OR CateringServices.Folio.DateTimeTo = &qEmptyDate
	|					AND (CateringServices.Period BETWEEN &qPeriodFrom AND &qPeriodTo))
	|		AND (CateringServices.RoomType IN HIERARCHY (&qRoomType)
	|				OR &qRoomTypeIsEmpty)
	|		AND CateringServices.Service IN(&qCateringServicesList)
	|		AND &qUseCateringServicesList
	|		AND (&qUseUpsellServicesList
	|					AND NOT CateringServices.Service IN (&qUpsellServicesList)
	|				OR NOT &qUseUpsellServicesList)
	|		AND (&qUseExtrasServicesList
	|					AND NOT CateringServices.Service IN (&qUseExtrasServicesList)
	|				OR NOT &qUseExtrasServicesList)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		&qUpsellType,
	|		2,
	|		&qUpsellPercent,
	|		CASE
	|			WHEN UpsellServices.Sales > 0
	|					AND NOT UpsellServices.Recorder REFS Document.Storno
	|				THEN UpsellServices.Author
	|			WHEN NOT UpsellServices.Recorder.CorrectedCharge.Number IS NULL
	|				THEN UpsellServices.Recorder.CorrectedCharge.Author
	|			WHEN NOT UpsellServices.Recorder.ParentCharge.Number IS NULL
	|				THEN UpsellServices.Recorder.ParentCharge.Author
	|			ELSE UpsellServices.Author
	|		END,
	|		CASE
	|			WHEN UpsellServices.Sales > 0
	|					AND NOT UpsellServices.Recorder REFS Document.Storno
	|				THEN UpsellServices.Period
	|			WHEN NOT UpsellServices.Recorder.CorrectedCharge.Number IS NULL
	|				THEN UpsellServices.Recorder.CorrectedCharge.Date
	|			WHEN NOT UpsellServices.Recorder.ParentCharge.Number IS NULL
	|				THEN UpsellServices.Recorder.ParentCharge.Date
	|			ELSE UpsellServices.Period
	|		END,
	|		UpsellServices.Company,
	|		UpsellServices.Hotel,
	|		UpsellServices.ReportingCurrency,
	|		UpsellServices.Service,
	|		UpsellServices.AccountingDate,
	|		UpsellServices.Room,
	|		UpsellServices.Resource,
	|		UpsellServices.Agent,
	|		UpsellServices.Customer,
	|		UpsellServices.Contract,
	|		UpsellServices.ClientType,
	|		UpsellServices.MarketingCode,
	|		UpsellServices.SourceOfBusiness,
	|		UpsellServices.Client,
	|		UpsellServices.Folio,
	|		UpsellServices.Recorder.Remarks,
	|		UpsellServices.Recorder,
	|		UpsellServices.ParentDoc,
	|		UpsellServices.GuestGroup,
	|		UpsellServices.TripPurpose,
	|		UpsellServices.ServicePackage,
	|		UpsellServices.VATRate,
	|		UpsellServices.RoomType,
	|		UpsellServices.RoomRateType,
	|		UpsellServices.RoomRate,
	|		CASE
	|			WHEN NOT UpsellServices.Recorder.ParentCharge.Performer IS NULL
	|				THEN UpsellServices.Recorder.ParentCharge.Performer
	|			ELSE UpsellServices.Recorder.Performer
	|		END,
	|		UpsellServices.Sales,
	|		UpsellServices.Sales * &qUpsellPercent / 100,
	|		UpsellServices.SalesWithoutVAT,
	|		UpsellServices.SalesWithoutVAT * &qUpsellPercent / 100,
	|		UpsellServices.CommissionSum,
	|		UpsellServices.CommissionSumWithoutVAT,
	|		UpsellServices.DiscountSum,
	|		UpsellServices.DiscountSumWithoutVAT,
	|		UpsellServices.Sales + UpsellServices.DiscountSum,
	|		UpsellServices.VATSum
	|	FROM
	|		AccumulationRegister.Sales AS UpsellServices
	|	WHERE
	|		NOT UpsellServices.IsCorrection
	|		AND NOT CASE
	|					WHEN NOT UpsellServices.Recorder.CorrectedCharge.Number IS NULL
	|						THEN UpsellServices.Recorder.CorrectedCharge.IsInPrice
	|					WHEN NOT UpsellServices.Recorder.ParentCharge.Number IS NULL
	|						THEN UpsellServices.Recorder.ParentCharge.IsInPrice
	|					ELSE UpsellServices.Recorder.IsInPrice
	|				END
	|		AND UpsellServices.Hotel IN HIERARCHY(&qHotel)
	|		AND ISNULL(UpsellServices.Folio.IsClosed, FALSE)
	|		AND (UpsellServices.Folio.DateTimeTo > &qEmptyDate
	|					AND (UpsellServices.Folio.DateTimeTo BETWEEN &qPeriodFrom AND &qPeriodTo)
	|				OR UpsellServices.Folio.DateTimeTo = &qEmptyDate
	|					AND (UpsellServices.Period BETWEEN &qPeriodFrom AND &qPeriodTo))
	|		AND (UpsellServices.RoomType IN HIERARCHY (&qRoomType)
	|				OR &qRoomTypeIsEmpty)
	|		AND UpsellServices.Service IN(&qUpsellServicesList)
	|		AND &qUseUpsellServicesList
	|		AND (&qUseExtrasServicesList
	|					AND NOT UpsellServices.Service IN (&qExtrasServicesList)
	|				OR NOT &qUseExtrasServicesList)
	|		AND (&qUseCateringServicesList
	|					AND NOT UpsellServices.Service IN (&qCateringServicesList)
	|				OR NOT &qUseCateringServicesList)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		&qWalkinType,
	|		3,
	|		&qWalkinPercent,
	|		CASE
	|			WHEN NOT WalkinServices.Recorder REFS Document.Storno
	|					AND NOT WalkinServices.Charge.ParentDoc.Reservation.Number IS NULL
	|				THEN WalkinServices.Charge.ParentDoc.Reservation.Author
	|			WHEN NOT WalkinServices.Recorder REFS Document.Storno
	|					AND NOT WalkinServices.Charge.ParentDoc.Number IS NULL
	|				THEN WalkinServices.Charge.ParentDoc.Author
	|			WHEN NOT WalkinServices.Recorder.CorrectedCharge.ParentDoc.Reservation.Number IS NULL
	|				THEN WalkinServices.Recorder.CorrectedCharge.ParentDoc.Reservation.Author
	|			WHEN NOT WalkinServices.Recorder.CorrectedCharge.ParentDoc.Number IS NULL
	|				THEN WalkinServices.Recorder.CorrectedCharge.ParentDoc.Author
	|			WHEN NOT WalkinServices.Recorder.ParentCharge.ParentDoc.Reservation.Number IS NULL
	|				THEN WalkinServices.Recorder.ParentCharge.ParentDoc.Reservation.Author
	|			WHEN NOT WalkinServices.Recorder.ParentCharge.ParentDoc.Number IS NULL
	|				THEN WalkinServices.Recorder.ParentCharge.ParentDoc.Author
	|			ELSE WalkinServices.Recorder.Author
	|		END,
	|		CASE
	|			WHEN NOT WalkinServices.Recorder REFS Document.Storno
	|					AND NOT WalkinServices.Charge.ParentDoc.Reservation.Number IS NULL
	|				THEN WalkinServices.Charge.ParentDoc.Reservation.Date
	|			WHEN NOT WalkinServices.Recorder REFS Document.Storno
	|					AND NOT WalkinServices.Charge.ParentDoc.Number IS NULL
	|				THEN WalkinServices.Charge.ParentDoc.Date
	|			WHEN NOT WalkinServices.Recorder.CorrectedCharge.ParentDoc.Reservation.Number IS NULL
	|				THEN WalkinServices.Recorder.CorrectedCharge.ParentDoc.Reservation.Date
	|			WHEN NOT WalkinServices.Recorder.CorrectedCharge.ParentDoc.Number IS NULL
	|				THEN WalkinServices.Recorder.CorrectedCharge.ParentDoc.Date
	|			WHEN NOT WalkinServices.Recorder.ParentCharge.ParentDoc.Reservation.Number IS NULL
	|				THEN WalkinServices.Recorder.ParentCharge.ParentDoc.Reservation.Date
	|			WHEN NOT WalkinServices.Recorder.ParentCharge.ParentDoc.Number IS NULL
	|				THEN WalkinServices.Recorder.ParentCharge.ParentDoc.Date
	|			ELSE WalkinServices.Period
	|		END,
	|		WalkinServices.Company,
	|		WalkinServices.Hotel,
	|		WalkinServices.FolioCurrency,
	|		VALUE(Catalog.Services.EmptyRef),
	|		CASE
	|			WHEN NOT WalkinServices.Recorder REFS Document.Storno
	|					AND NOT WalkinServices.Charge.ParentDoc.Reservation.Number IS NULL
	|				THEN BEGINOFPERIOD(WalkinServices.Charge.ParentDoc.Reservation.Date, DAY)
	|			WHEN NOT WalkinServices.Recorder REFS Document.Storno
	|					AND NOT WalkinServices.Charge.ParentDoc.Number IS NULL
	|				THEN BEGINOFPERIOD(WalkinServices.Charge.ParentDoc.Date, DAY)
	|			WHEN NOT WalkinServices.Recorder.CorrectedCharge.ParentDoc.Reservation.Number IS NULL
	|				THEN BEGINOFPERIOD(WalkinServices.Recorder.CorrectedCharge.ParentDoc.Reservation.Date, DAY)
	|			WHEN NOT WalkinServices.Recorder.CorrectedCharge.ParentDoc.Number IS NULL
	|				THEN BEGINOFPERIOD(WalkinServices.Recorder.CorrectedCharge.ParentDoc.Date, DAY)
	|			WHEN NOT WalkinServices.Recorder.ParentCharge.ParentDoc.Reservation.Number IS NULL
	|				THEN BEGINOFPERIOD(WalkinServices.Recorder.ParentCharge.ParentDoc.Reservation.Date, DAY)
	|			WHEN NOT WalkinServices.Recorder.ParentCharge.ParentDoc.Number IS NULL
	|				THEN BEGINOFPERIOD(WalkinServices.Recorder.ParentCharge.ParentDoc.Date, DAY)
	|			ELSE BEGINOFPERIOD(WalkinServices.Period, DAY)
	|		END,
	|		WalkinServices.Charge.ParentDoc.Room,
	|		WalkinServices.Charge.ParentDoc.Resource,
	|		WalkinServices.Charge.ParentDoc.Agent,
	|		WalkinServices.Charge.ParentDoc.Customer,
	|		WalkinServices.Charge.ParentDoc.Contract,
	|		WalkinServices.Charge.ParentDoc.ClientType,
	|		WalkinServices.Charge.ParentDoc.MarketingCode,
	|		WalkinServices.Charge.ParentDoc.SourceOfBusiness,
	|		WalkinServices.Charge.ParentDoc.Guest,
	|		WalkinServices.Charge.Folio,
	|		"""",
	|		WalkinServices.Charge.ParentDoc,
	|		WalkinServices.Charge.ParentDoc,
	|		WalkinServices.GuestGroup,
	|		WalkinServices.Charge.ParentDoc.TripPurpose,
	|		WalkinServices.Charge.ParentDoc.ServicePackage,
	|		WalkinServices.Charge.VATRate,
	|		WalkinServices.Charge.ParentDoc.RoomType,
	|		WalkinServices.Charge.ParentDoc.RoomRate.RoomRateType,
	|		WalkinServices.Charge.ParentDoc.RoomRate,
	|		CASE
	|			WHEN NOT WalkinServices.Recorder.ParentCharge.Performer IS NULL
	|				THEN WalkinServices.Recorder.ParentCharge.Performer
	|			ELSE WalkinServices.Recorder.Performer
	|		END,
	|		SUM(WalkinServices.Sum),
	|		SUM(WalkinServices.Sum * &qWalkinPercent / 100),
	|		SUM(WalkinServices.Sum - WalkinServices.VATSum),
	|		SUM((WalkinServices.Sum - WalkinServices.VATSum) * &qWalkinPercent / 100),
	|		SUM(WalkinServices.CommissionSum),
	|		0,
	|		0,
	|		0,
	|		0,
	|		SUM(WalkinServices.VATSum)
	|	FROM
	|		AccumulationRegister.CurrentAccountsReceivable AS WalkinServices
	|	WHERE
	|		WalkinServices.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND NOT CASE
	|					WHEN NOT WalkinServices.Recorder.CorrectedCharge.Number IS NULL
	|						THEN WalkinServices.Recorder.CorrectedCharge.IsInPrice
	|					WHEN NOT WalkinServices.Recorder.ParentCharge.Number IS NULL
	|						THEN WalkinServices.Recorder.ParentCharge.IsInPrice
	|					ELSE NOT WalkinServices.Recorder.IsInPrice
	|				END
	|		AND WalkinServices.Hotel IN HIERARCHY(&qHotel)
	|		AND WalkinServices.Charge.ParentDoc REFS Document.Accommodation
	|		AND ISNULL(WalkinServices.Charge.ParentDoc.AccommodationStatus.IsActive, FALSE)
	|		AND NOT ISNULL(WalkinServices.Charge.ParentDoc.AccommodationStatus.IsInHouse, TRUE)
	|		AND WalkinServices.Charge.ParentDoc.CheckOutDate BETWEEN &qPeriodFrom AND &qPeriodTo
	|		AND (WalkinServices.Charge.ParentDoc.RoomType IN HIERARCHY (&qRoomType)
	|				OR &qRoomTypeIsEmpty)
	|		AND (NOT &qSourceOfBusinessIsEmpty
	|					AND WalkinServices.Charge.ParentDoc.SourceOfBusiness IN HIERARCHY (&qSourceOfBusiness)
	|				OR &qSourceOfBusinessIsEmpty
	|					AND (WalkinServices.Charge.ParentDoc.Reservation.Number IS NULL
	|							AND WalkinServices.Charge.ParentDoc.Author = WalkinServices.Charge.ParentDoc.GuestGroup.Author
	|							AND (WalkinServices.Charge.ParentDoc.Author IN HIERARCHY (&qEmployee)
	|								OR WalkinServices.Charge.ParentDoc.Author.Department IN HIERARCHY (&qDepartment))
	|						OR NOT WalkinServices.Charge.ParentDoc.Reservation.Number IS NULL
	|							AND WalkinServices.Charge.ParentDoc.Reservation.Author = WalkinServices.Charge.ParentDoc.GuestGroup.Author
	|							AND (WalkinServices.Charge.ParentDoc.Reservation.Author IN HIERARCHY (&qEmployee)
	|								OR WalkinServices.Charge.ParentDoc.Reservation.Author.Department IN HIERARCHY (&qDepartment))))
	|	
	|	GROUP BY
	|		CASE
	|			WHEN NOT WalkinServices.Recorder REFS Document.Storno
	|					AND NOT WalkinServices.Charge.ParentDoc.Reservation.Number IS NULL
	|				THEN WalkinServices.Charge.ParentDoc.Reservation.Author
	|			WHEN NOT WalkinServices.Recorder REFS Document.Storno
	|					AND NOT WalkinServices.Charge.ParentDoc.Number IS NULL
	|				THEN WalkinServices.Charge.ParentDoc.Author
	|			WHEN NOT WalkinServices.Recorder.CorrectedCharge.ParentDoc.Reservation.Number IS NULL
	|				THEN WalkinServices.Recorder.CorrectedCharge.ParentDoc.Reservation.Author
	|			WHEN NOT WalkinServices.Recorder.CorrectedCharge.ParentDoc.Number IS NULL
	|				THEN WalkinServices.Recorder.CorrectedCharge.ParentDoc.Author
	|			WHEN NOT WalkinServices.Recorder.ParentCharge.ParentDoc.Reservation.Number IS NULL
	|				THEN WalkinServices.Recorder.ParentCharge.ParentDoc.Reservation.Author
	|			WHEN NOT WalkinServices.Recorder.ParentCharge.ParentDoc.Number IS NULL
	|				THEN WalkinServices.Recorder.ParentCharge.ParentDoc.Author
	|			ELSE WalkinServices.Recorder.Author
	|		END,
	|		CASE
	|			WHEN NOT WalkinServices.Recorder REFS Document.Storno
	|					AND NOT WalkinServices.Charge.ParentDoc.Reservation.Number IS NULL
	|				THEN WalkinServices.Charge.ParentDoc.Reservation.Date
	|			WHEN NOT WalkinServices.Recorder REFS Document.Storno
	|					AND NOT WalkinServices.Charge.ParentDoc.Number IS NULL
	|				THEN WalkinServices.Charge.ParentDoc.Date
	|			WHEN NOT WalkinServices.Recorder.CorrectedCharge.ParentDoc.Reservation.Number IS NULL
	|				THEN WalkinServices.Recorder.CorrectedCharge.ParentDoc.Reservation.Date
	|			WHEN NOT WalkinServices.Recorder.CorrectedCharge.ParentDoc.Number IS NULL
	|				THEN WalkinServices.Recorder.CorrectedCharge.ParentDoc.Date
	|			WHEN NOT WalkinServices.Recorder.ParentCharge.ParentDoc.Reservation.Number IS NULL
	|				THEN WalkinServices.Recorder.ParentCharge.ParentDoc.Reservation.Date
	|			WHEN NOT WalkinServices.Recorder.ParentCharge.ParentDoc.Number IS NULL
	|				THEN WalkinServices.Recorder.ParentCharge.ParentDoc.Date
	|			ELSE WalkinServices.Period
	|		END,
	|		WalkinServices.Company,
	|		WalkinServices.Hotel,
	|		WalkinServices.FolioCurrency,
	|		CASE
	|			WHEN NOT WalkinServices.Recorder REFS Document.Storno
	|					AND NOT WalkinServices.Charge.ParentDoc.Reservation.Number IS NULL
	|				THEN BEGINOFPERIOD(WalkinServices.Charge.ParentDoc.Reservation.Date, DAY)
	|			WHEN NOT WalkinServices.Recorder REFS Document.Storno
	|					AND NOT WalkinServices.Charge.ParentDoc.Number IS NULL
	|				THEN BEGINOFPERIOD(WalkinServices.Charge.ParentDoc.Date, DAY)
	|			WHEN NOT WalkinServices.Recorder.CorrectedCharge.ParentDoc.Reservation.Number IS NULL
	|				THEN BEGINOFPERIOD(WalkinServices.Recorder.CorrectedCharge.ParentDoc.Reservation.Date, DAY)
	|			WHEN NOT WalkinServices.Recorder.CorrectedCharge.ParentDoc.Number IS NULL
	|				THEN BEGINOFPERIOD(WalkinServices.Recorder.CorrectedCharge.ParentDoc.Date, DAY)
	|			WHEN NOT WalkinServices.Recorder.ParentCharge.ParentDoc.Reservation.Number IS NULL
	|				THEN BEGINOFPERIOD(WalkinServices.Recorder.ParentCharge.ParentDoc.Reservation.Date, DAY)
	|			WHEN NOT WalkinServices.Recorder.ParentCharge.ParentDoc.Number IS NULL
	|				THEN BEGINOFPERIOD(WalkinServices.Recorder.ParentCharge.ParentDoc.Date, DAY)
	|			ELSE BEGINOFPERIOD(WalkinServices.Period, DAY)
	|		END,
	|		WalkinServices.Charge.ParentDoc.Room,
	|		WalkinServices.Charge.ParentDoc.Resource,
	|		WalkinServices.Charge.ParentDoc.Agent,
	|		WalkinServices.Charge.ParentDoc.Customer,
	|		WalkinServices.Charge.ParentDoc.Contract,
	|		WalkinServices.Charge.ParentDoc.ClientType,
	|		WalkinServices.Charge.ParentDoc.MarketingCode,
	|		WalkinServices.Charge.ParentDoc.SourceOfBusiness,
	|		WalkinServices.Charge.ParentDoc.Guest,
	|		WalkinServices.Charge.Folio,
	|		WalkinServices.Charge.ParentDoc,
	|		WalkinServices.GuestGroup,
	|		WalkinServices.Charge.ParentDoc.TripPurpose,
	|		WalkinServices.Charge.ParentDoc.ServicePackage,
	|		WalkinServices.Charge.VATRate,
	|		WalkinServices.Charge.ParentDoc.RoomType,
	|		WalkinServices.Charge.ParentDoc.RoomRate.RoomRateType,
	|		WalkinServices.Charge.ParentDoc.RoomRate,
	|		CASE
	|			WHEN NOT WalkinServices.Recorder.ParentCharge.Performer IS NULL
	|				THEN WalkinServices.Recorder.ParentCharge.Performer
	|			ELSE WalkinServices.Recorder.Performer
	|		END,
	|		WalkinServices.Charge.ParentDoc) AS BonusesBase
	|WHERE
	|	BonusesBase.Employee IN HIERARCHY(&qEmployee)
	|	AND (ISNULL(BonusesBase.Employee.Department, VALUE(Catalog.Departments.EmptyRef)) = VALUE(Catalog.Departments.EmptyRef)
	|			OR ISNULL(BonusesBase.Employee.Department, VALUE(Catalog.Departments.EmptyRef)) <> VALUE(Catalog.Departments.EmptyRef)
	|				AND BonusesBase.Employee.Department IN HIERARCHY (&qDepartment))
	|	AND BonusesBase.BaseTypeCode IN(&qBaseTypeCodesList)
	|{WHERE
	|	BonusesBase.Period,
	|	BonusesBase.Recorder.*,
	|	BonusesBase.ReportingCurrency.*,
	|	BonusesBase.Hotel.*,
	|	BonusesBase.Service.*,
	|	BonusesBase.ClientType.*,
	|	BonusesBase.MarketingCode.*,
	|	BonusesBase.SourceOfBusiness.*,
	|	BonusesBase.Company.*,
	|	BonusesBase.AccountingDate,
	|	BonusesBase.ParentDoc.*,
	|	BonusesBase.Folio.*,
	|	BonusesBase.Recorder.Remarks AS Remarks,
	|	BonusesBase.GuestGroup.*,
	|	BonusesBase.Client.*,
	|	BonusesBase.TripPurpose.*,
	|	BonusesBase.ServicePackage.*,
	|	BonusesBase.Room.*,
	|	BonusesBase.Resource.*,
	|	BonusesBase.VATRate.*,
	|	BonusesBase.Agent.*,
	|	BonusesBase.Customer.*,
	|	BonusesBase.Contract.*,
	|	BonusesBase.RoomType.*,
	|	BonusesBase.Employee.*,
	|	BonusesBase.Performer.* AS Performer,
	|	BonusesBase.RoomRateType.*,
	|	BonusesBase.RoomRate.*,
	|	BonusesBase.Sales AS Sum,
	|	BonusesBase.Bonuses AS Bonuses,
	|	BonusesBase.SalesWithoutVAT AS SumWithoutVAT,
	|	BonusesBase.BonusesWithoutVAT AS BonusesWithoutVAT,
	|	BonusesBase.CommissionSum,
	|	BonusesBase.CommissionSumWithoutVAT,
	|	BonusesBase.DiscountSum,
	|	BonusesBase.DiscountSumWithoutVAT,
	|	BonusesBase.VATSum}
	|
	|ORDER BY
	|	Hotel,
	|	Employee,
	|	BaseType,
	|	Service,
	|	Period
	|{ORDER BY
	|	BaseType,
	|	BonusesBase.BaseTypeCode,
	|	Period,
	|	ReportingCurrency.*,
	|	Hotel.*,
	|	Service.*,
	|	BonusesBase.ClientType.*,
	|	BonusesBase.SourceOfBusiness.*,
	|	Company.*,
	|	AccountingDate,
	|	Recorder.*,
	|	ParentDoc.*,
	|	BonusesBase.Folio.*,
	|	BonusesBase.GuestGroup.*,
	|	Client.*,
	|	BonusesBase.TripPurpose.*,
	|	BonusesBase.ServicePackage.*,
	|	Room.*,
	|	BonusesBase.Resource.*,
	|	BonusesBase.VATRate.*,
	|	BonusesBase.Agent.*,
	|	Customer.*,
	|	BonusesBase.Contract.*,
	|	BonusesBase.RoomType.*,
	|	Employee.*,
	|	BonusesBase.Performer.* AS Performer,
	|	BonusesBase.RoomRateType.*,
	|	BonusesBase.RoomRate.*,
	|	VATSum,
	|	Sum,
	|	Bonuses,
	|	SumWithoutCommission,
	|	SumWithoutVAT,
	|	BonusesWithoutVAT}
	|TOTALS
	|	SUM(Sum),
	|	SUM(Bonuses),
	|	SUM(SumBeforeDiscount),
	|	SUM(SumWithoutCommission),
	|	SUM(SumWithoutVAT),
	|	SUM(BonusesWithoutVAT),
	|	SUM(CommissionSum),
	|	SUM(CommissionSumWithoutVAT),
	|	SUM(DiscountSum),
	|	SUM(DiscountSumWithoutVAT),
	|	SUM(VATSum)
	|BY
	|	OVERALL,
	|	Hotel,
	|	Employee,
	|	BaseType,
	|	Service
	|{TOTALS BY
	|	BaseType,
	|	BonusesBase.BaseTypePercent,
	|	Recorder.*,
	|	ReportingCurrency.*,
	|	Hotel.*,
	|	Service.*,
	|	BonusesBase.ClientType.*,
	|	BonusesBase.MarketingCode.*,
	|	BonusesBase.SourceOfBusiness.*,
	|	Company.*,
	|	AccountingDate,
	|	ParentDoc.*,
	|	BonusesBase.Folio.*,
	|	BonusesBase.GuestGroup.*,
	|	Client.*,
	|	BonusesBase.TripPurpose.*,
	|	BonusesBase.ServicePackage.*,
	|	Room.*,
	|	BonusesBase.Resource.*,
	|	BonusesBase.VATRate.*,
	|	BonusesBase.Agent.*,
	|	Customer.*,
	|	BonusesBase.Contract.*,
	|	BonusesBase.RoomType.*,
	|	Employee.*,
	|	BonusesBase.Performer.* AS Performer,
	|	BonusesBase.RoomRateType.*,
	|	BonusesBase.RoomRate.*}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("ru='Расчет базы для премирования сотрудников';de='Berechnung der Basis für Boni an Mitarbeiter';en='Base for employee bonuses calculation'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
