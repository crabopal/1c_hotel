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
		vParamPresentation = vParamPresentation + NStr("en='Guests in rooms for the period selected';ru='Отбор гостей проживавших в выбранном периоде';de='Auswahl von Gästen die im ausgewählten Zeitraum übernachten'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodCheckType = Enums.PeriodCheckTypes.StartsInPeriod Then
		vParamPresentation = vParamPresentation + NStr("en='Guests checked in during the period selected';ru='Отбор гостей заехавших в выбранном периоде';de='Auswahl von Gästen, die im ausgewählten Zeitraum angereist sind'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodCheckType = Enums.PeriodCheckTypes.EndsInPeriod Then
		vParamPresentation = vParamPresentation + NStr("en='Guests checked out during the period selected';ru='Отбор гостей выехавших в выбранном периоде';de='Auswahl von Gästen, die im ausgewählten Zeitraum abgereist sind'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodCheckType = Enums.PeriodCheckTypes.StartsOrEndsInPeriod Then
		vParamPresentation = vParamPresentation + NStr("en='Guests checked in or checked out during the period selected';ru='Отбор гостей заехавших или выехавших в выбранном периоде';de='Auswahl von Gästen, die im ausgewählten Zeitraum an- oder abgereist sind'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodCheckType = Enums.PeriodCheckTypes.DocDateInPeriod Then
		vParamPresentation = vParamPresentation + NStr("en='Guests registered during the period selected';ru='Отбор гостей зарегистрированных в выбранном периоде';de='Auswahl von im ausgewählten Zeitraum registrierten Gästen'") + 
		                     ";" + Chars.LF;
	Endif;		
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
	If ValueIsFilled(GuestGroup) Then
		vParamPresentation = vParamPresentation + NStr("en='Guest group ';ru='Группа ';de='Gruppe '") + 
							 TrimAll(TrimAll(GuestGroup.Code) + " " + TrimAll(GuestGroup.Description)) + 
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
	If ValueIsFilled(Guest) Then
		If Not Guest.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Гость '; en = 'Guest '; de = 'Gast '") + 
			                     TrimAll(Guest.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа клиентов '; en = 'Clients folder '; de = 'Kundengruppe '") + 
			                     TrimAll(Guest.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If Tags.Count() > 0 Then
		vParamPresentation = vParamPresentation + NStr("de='Tags ';en='Tags ';ru='Теги '");
		For Each vTagsItem In Tags Do
			If Tags.IndexOf(vTagsItem) > 0 Then
				If TagsCheckMode Then
					vParamPresentation = vParamPresentation + NStr("en=' AND '; ru=' И '; de=' UND '");
				Else
					vParamPresentation = vParamPresentation + NStr("en=' OR '; ru=' ИЛИ '; de=' ODER '");
				EndIf;
			EndIf;
			vParamPresentation = vParamPresentation + TrimAll(vTagsItem.Value);
		EndDo;
		vParamPresentation = vParamPresentation + ";" + Chars.LF;
	EndIf;
	If ShowInHouseOnly Then
		vParamPresentation = vParamPresentation + NStr("en='In-house guests only';ru='Только проживающие (не выселенные) гости';de='Nur übernachtende (nicht ausquartierte) Gäste'") + 
							 ";" + Chars.LF;
	EndIf;
	If ShowNotInHouseOnly Then
		vParamPresentation = vParamPresentation + NStr("en='Checked-out guests only';ru='Только выселенные гости';de='Nur ausquartierte Gäste'") + 
							 ";" + Chars.LF;
	EndIf;
	If ShowRoomMovesOnly Then
		vParamPresentation = vParamPresentation + NStr("en='Expected room moves only';ru='Только планируемые переселения';de='Nur geplante Umsiedlungen'") + 
							 ";" + Chars.LF;
	EndIf;
	If ShowMainRoomGuestsOnly Then
		vParamPresentation = vParamPresentation + NStr("en='Main room guests only';ru='Только основные гости номера';de='Nur Hauptgäste des Zimmers'") + 
							 ";" + Chars.LF;
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
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qBegOfPeriodFrom", BegOfDay(PeriodFrom));
	ReportBuilder.Parameters.Insert("qPeriodTo", PeriodTo);
	ReportBuilder.Parameters.Insert("qEndOfPeriodTo", EndOfDay(PeriodTo));
	ReportBuilder.Parameters.Insert("qPeriodCheckType", PeriodCheckType);
	ReportBuilder.Parameters.Insert("qAccommodation", Enums.PeriodCheckTypes.Intersection);
	ReportBuilder.Parameters.Insert("qCheckIn", Enums.PeriodCheckTypes.StartsInPeriod);
	ReportBuilder.Parameters.Insert("qCheckOut", Enums.PeriodCheckTypes.EndsInPeriod);
	ReportBuilder.Parameters.Insert("qCheckInOrCheckOut", Enums.PeriodCheckTypes.StartsOrEndsInPeriod);
	ReportBuilder.Parameters.Insert("qDocDateInPeriod", Enums.PeriodCheckTypes.DocDateInPeriod);
	ReportBuilder.Parameters.Insert("qRoom", Room);
	ReportBuilder.Parameters.Insert("qRoomIsFilled", ValueIsFilled(Room));
	ReportBuilder.Parameters.Insert("qRoomType", RoomType);
	ReportBuilder.Parameters.Insert("qShowInHouseOnly", ShowInHouseOnly);
	ReportBuilder.Parameters.Insert("qShowNotInHouseOnly", ShowNotInHouseOnly);
	ReportBuilder.Parameters.Insert("qEndOfTime", '39991231235959');
	ReportBuilder.Parameters.Insert("qEmptyDate", '00010101');
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qCustomerIsEmpty", Not ValueIsFilled(Customer));
	ReportBuilder.Parameters.Insert("qGuest", Guest);
	ReportBuilder.Parameters.Insert("qGuestIsEmpty", Not ValueIsFilled(Guest));
	ReportBuilder.Parameters.Insert("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	ReportBuilder.Parameters.Insert("qEmptyForeignerRegistryRecord", Documents.ForeignerRegistryRecord.EmptyRef());
	ReportBuilder.Parameters.Insert("qEmptyClientDataScan", Documents.ClientDataScans.EmptyRef());
	If ReportBuilder.SelectedFields.Find("ClientSumBalance") <> Undefined Then
		ReportBuilder.Parameters.Insert("qShowBalances", True);
	Else
		ReportBuilder.Parameters.Insert("qShowBalances", False);
	EndIf;
	If ReportBuilder.SelectedFields.Find("Sales") <> Undefined Or ReportBuilder.SelectedFields.Find("RoomRevenue") <> Undefined Then
		ReportBuilder.Parameters.Insert("qShowSales", True);
	Else
		ReportBuilder.Parameters.Insert("qShowSales", False);
	EndIf;
	If ReportBuilder.SelectedFields.Find("TotalSales") <> Undefined Or ReportBuilder.SelectedFields.Find("TotalRoomRevenue") <> Undefined Then
		ReportBuilder.Parameters.Insert("qShowTotalSales", True);
	Else
		ReportBuilder.Parameters.Insert("qShowTotalSales", False);
	EndIf;
	If ReportBuilder.SelectedFields.Find("TotalCustomerSales") <> Undefined Then
		ReportBuilder.Parameters.Insert("qShowTotalCustomerSales", True);
	Else
		ReportBuilder.Parameters.Insert("qShowTotalCustomerSales", False);
	EndIf;
	vShowFRR = False;
	vShowCDS = False;
	For Each vFld In ReportBuilder.SelectedFields Do
		If Left(vFld.Name, 23) = "ForeignerRegistryRecord" Then
			vShowFRR = True;
		EndIf;
		If Left(vFld.Name, 14) = "ClientDataScan" Then
			vShowCDS = True;
		EndIf;
	EndDo;
	ReportBuilder.Parameters.Insert("qShowFRR", vShowFRR);
	ReportBuilder.Parameters.Insert("qShowCDS", vShowCDS);
	If ReportBuilder.SelectedFields.Find("NumberOfCheckins") <> Undefined Then
		ReportBuilder.Parameters.Insert("qNumberOfVisitsIsUsed", True);
	Else
		ReportBuilder.Parameters.Insert("qNumberOfVisitsIsUsed", False);
	EndIf;
	ReportBuilder.Parameters.Insert("qShowMainRoomGuestsOnly", ShowMainRoomGuestsOnly);
	ReportBuilder.Parameters.Insert("qShowRoomMovesOnly", ShowRoomMovesOnly);
	ReportBuilder.Parameters.Insert("qShowReservations", ShowReservations);
	ReportBuilder.Parameters.Insert("qGuestGroup", GuestGroup);
	ReportBuilder.Parameters.Insert("qGuestGroupIsEmpty", Not ValueIsFilled(GuestGroup));
	ReportBuilder.Parameters.Insert("qCustomAttribute1", CustomAttribute1);
	ReportBuilder.Parameters.Insert("qCustomAttribute2", CustomAttribute2);
	ReportBuilder.Parameters.Insert("qCustomAttribute3", CustomAttribute3);
	ReportBuilder.Parameters.Insert("qTagsList", Tags);
	ReportBuilder.Parameters.Insert("qTagsCount", Tags.Count());
	ReportBuilder.Parameters.Insert("qTagsConditionAND", TagsCheckMode);

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
	|	ClientTags.Client AS Client,
	|	COUNT(ClientTags.Tag) AS TagsCount
	|INTO ClientsWithTags
	|FROM
	|	InformationRegister.ClientTags AS ClientTags
	|WHERE
	|	ClientTags.Tag IN(&qTagsList)
	|	AND NOT ClientTags.Client.DeletionMark
	|	AND ClientTags.Client REFS Catalog.Clients
	|
	|GROUP BY
	|	ClientTags.Client
	|
	|HAVING
	|	(NOT &qTagsConditionAND
	|			AND COUNT(ClientTags.Tag) > 0
	|		OR &qTagsConditionAND
	|			AND COUNT(ClientTags.Tag) = &qTagsCount)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInventory.Recorder.Hotel AS Hotel,
	|	RoomInventory.Room AS Room,
	|	RoomInventory.Recorder.Customer AS Customer,
	|	CASE
	|		WHEN RoomInventory.Recorder.AccommodationStatus IS NULL
	|			THEN RoomInventory.Recorder.ReservationStatus
	|		ELSE RoomInventory.Recorder.AccommodationStatus
	|	END AS AccommodationStatus,
	|	RoomInventory.Recorder.Guest AS Guest,
	|	RoomInventory.CheckInDate AS CheckInDate,
	|	RoomInventory.Duration AS Duration,
	|	RoomInventory.CheckOutDate AS CheckOutDate,
	|	RoomInventory.RoomType AS RoomType,
	|	RoomInventory.AccommodationType AS AccommodationType,
	|	RoomInventory.Recorder.RoomRate AS RoomRate,
	|	RoomInventory.Recorder.Remarks AS Remarks, 
	|	RoomInventory.Recorder.HousekeepingRemarks AS HousekeepingRemarks,
	|	RoomInventory.Recorder.GuestGroup AS GuestGroup,
	|	CASE
	|		WHEN &qShowMainRoomGuestsOnly
	|			THEN ISNULL(RoomInventory.Recorder.NumberOfAdults, 0) + ISNULL(RoomInventory.Recorder.NumberOfTeenagers, 0) + ISNULL(RoomInventory.Recorder.NumberOfChildren, 0) + ISNULL(RoomInventory.Recorder.NumberOfInfants, 0)
	|		ELSE RoomInventory.InHouseGuests + RoomInventory.GuestsReserved
	|	END AS InHouseGuests,
	|	ISNULL(RoomInventory.Recorder.NumberOfAdults, 0) AS NumberOfAdults,
	|	ISNULL(RoomInventory.Recorder.NumberOfTeenagers, 0) AS NumberOfTeenagers,
	|	ISNULL(RoomInventory.Recorder.NumberOfChildren, 0) AS NumberOfChildren,
	|	ISNULL(RoomInventory.Recorder.NumberOfInfants, 0) AS NumberOfInfants,
	|	RoomInventory.InHouseRooms + RoomInventory.RoomsReserved AS InHouseRooms,
	|	RoomInventory.InHouseBeds + RoomInventory.BedsReserved AS InHouseBeds,
	|	RoomInventory.InHouseAdditionalBeds + RoomInventory.AdditionalBedsReserved AS InHouseAdditionalBeds,
	|	RoomInventory.Recorder.HotelProduct.Sum AS HotelProductSum,
	|	RoomInventory.Recorder.PricePresentation AS PricePresentation,
	|	ExpectedRoomMoves.Room AS RoomTo,
	|	ISNULL(GuestPeriodSales.Sales, 0) AS Sales,
	|	ISNULL(GuestPeriodSales.RoomRevenue, 0) AS RoomRevenue,
	|	ISNULL(GuestTotalSales.Sales, 0) AS TotalSales,
	|	ISNULL(GuestTotalSales.RoomRevenue, 0) AS TotalRoomRevenue,
	|	ISNULL(GuestTotalCustomerSales.Sales, 0) AS TotalCustomerSales,
	|	ISNULL(ClientBalances.ClientSumBalance, 0) AS ClientSumBalance,
	|	ISNULL(ClientTotals.NumberOfCheckins, 0) AS NumberOfCheckins,
	|	ISNULL(RoomInventory.Recorder.RoomQuantity, 1) AS RoomQuantity,
	|	CASE
	|		WHEN GuestsExportedToUMMS.CheckInDate = BEGINOFPERIOD(RoomInventory.CheckInDate, DAY)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Unloaded
	|{SELECT
	|	Hotel.*,
	|	Room.*,
	|	RoomInventory.Recorder.CustomerType.* AS CustomerType,
	|	Customer.*,
	|	RoomInventory.Recorder.Contract.* AS Contract,
	|	RoomInventory.Recorder.ContactPerson AS ContactPerson,
	|	RoomInventory.Recorder.Agent.* AS Agent,
	|	RoomInventory.Recorder.ClientType.* AS ClientType,
	|	Guest.*,
	|	CheckInDate,
	|	Duration,
	|	CheckOutDate,
	|	RoomInventory.CheckInAccountingDate AS CheckInAccountingDate,
	|	RoomInventory.CheckOutAccountingDate AS CheckOutAccountingDate,
	|	(HOUR(RoomInventory.Recorder.CheckInDate)) AS CheckInHour,
	|	(DAY(RoomInventory.Recorder.CheckInDate)) AS CheckInDay,
	|	(WEEK(RoomInventory.Recorder.CheckInDate)) AS CheckInWeek,
	|	(MONTH(RoomInventory.Recorder.CheckInDate)) AS CheckInMonth,
	|	(QUARTER(RoomInventory.Recorder.CheckInDate)) AS CheckInQuarter,
	|	(YEAR(RoomInventory.Recorder.CheckInDate)) AS CheckInYear,
	|	RoomType.*,
	|	AccommodationType.*,
	|	RoomInventory.Recorder.RoomRateType.* AS RoomRateType,
	|	RoomInventory.Recorder.AccommodationTemplate.* AS AccommodationTemplate,
	|	RoomRate.*,
	|	PricePresentation,
	|	RoomInventory.Recorder.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	InHouseGuests,
	|	NumberOfAdults,
	|	NumberOfTeenagers,
	|	NumberOfChildren,
	|	NumberOfInfants,
	|	InHouseRooms,
	|	InHouseBeds,
	|	InHouseAdditionalBeds,
	|	Remarks,
	|	RoomInventory.Recorder.Car AS Car,
	|	GuestGroup.*,
	|	AccommodationStatus.*,
	|	RoomInventory.Recorder.IsMaster AS IsMaster,
	|	RoomInventory.Recorder.HotelProduct.* AS HotelProduct,
	|	RoomInventory.Recorder.RoomQuota.* AS RoomQuota,
	|	RoomInventory.Recorder.MarketingCode.* AS MarketingCode,
	|	RoomInventory.Recorder.TripPurpose.* AS TripPurpose,
	|	RoomInventory.Recorder.SourceOfBusiness.* AS SourceOfBusiness,
	|	RoomInventory.Recorder.DiscountCard.* AS DiscountCard,
	|	RoomInventory.Recorder.DiscountType.* AS DiscountType,
	|	RoomInventory.Recorder.Discount AS Discount,
	|	RoomInventory.Recorder.AgentCommission AS AgentCommission,
	|	RoomInventory.Recorder.AgentCommissionType AS AgentCommissionType,
	|	RoomInventory.Recorder.NumberOfBedsPerRoom AS NumberOfBedsPerRoom,
	|	RoomInventory.Recorder.NumberOfPersonsPerRoom AS NumberOfPersonsPerRoom,
	|	HotelProductSum,
	|	RoomInventory.Recorder.HotelProduct.Currency.* AS HotelProductCurrency,
	|	RoomInventory.Recorder.ParentDoc.* AS ParentDoc,
	|	RoomInventory.Recorder.Author.* AS Author,
	|	RoomInventory.Recorder.* AS Recorder,
	|	RoomTo.*,
	|	RoomInventory.ForeignerRegistryRecord.* AS ForeignerRegistryRecord,
	|	RoomInventory.ClientDataScan.* AS ClientDataScan,
	|	(CASE
	|			WHEN RoomInventory.ForeignerRegistryRecord.MigrationCardDateTo <> &qEmptyDate
	|				THEN DATEDIFF(RoomInventory.ForeignerRegistryRecord.MigrationCardDateTo, RoomInventory.Recorder.CheckOutDate, DAY)
	|			ELSE 0
	|		END) AS MigrationCardDateToDeviance,
	|	(CASE
	|			WHEN RoomInventory.ForeignerRegistryRecord.VisaToDate <> &qEmptyDate
	|				THEN DATEDIFF(RoomInventory.ForeignerRegistryRecord.VisaToDate, RoomInventory.Recorder.CheckOutDate, DAY)
	|			ELSE 0
	|		END) AS VisaToDateDeviance,
	|	RoomInventory.Recorder.Guest.TagsPresentation AS ClientTagsPresentation,
	|	RoomInventory.Recorder.PointInTime AS PointInTime,
	|	Sales,
	|	RoomRevenue,
	|	TotalSales,
	|	TotalRoomRevenue,
	|	TotalCustomerSales,
	|	ClientSumBalance,
	|	NumberOfCheckins,
	|	RoomQuantity,
	|	(CASE
	|			WHEN RoomInventory.Recorder.RoomTypeUpgrade <> RoomInventory.Recorder.RoomType
	|					AND RoomInventory.Recorder.RoomTypeUpgrade <> VALUE(Catalog.RoomTypes.EmptyRef)
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS PriceForRoomTypeIsDifferent,
	|	ReservationCustomAttributeValues1.CharacteristicValue.* AS CustomAttribute1,
	|	ReservationCustomAttributeValues2.CharacteristicValue.* AS CustomAttribute2,
	|	ReservationCustomAttributeValues3.CharacteristicValue.* AS CustomAttribute3,
	|	(NULL) AS EmptyColumn,
	|	Unloaded}
	|FROM
	|	(SELECT
	|		RoomInventoryPeriods.Recorder AS Recorder,
	|		RoomInventoryPeriods.Room AS Room,
	|		RoomInventoryPeriods.RoomType AS RoomType,
	|		RoomInventoryPeriods.AccommodationType AS AccommodationType,
	|		RoomInventoryPeriods.PeriodFrom AS CheckInDate,
	|		RoomInventoryPeriods.PeriodDuration AS Duration,
	|		RoomInventoryPeriods.PeriodTo AS CheckOutDate,
	|		RoomInventoryPeriods.CheckInAccountingDate AS CheckInAccountingDate,
	|		RoomInventoryPeriods.CheckOutAccountingDate AS CheckOutAccountingDate,
	|		CASE
	|			WHEN ForeignerRegistryRecords.ForeignerRegistryRecord IS NULL
	|				THEN &qEmptyForeignerRegistryRecord
	|			ELSE ForeignerRegistryRecords.ForeignerRegistryRecord
	|		END AS ForeignerRegistryRecord,
	|		CASE
	|			WHEN ClientDataScans.Ref IS NULL
	|				THEN &qEmptyClientDataScan
	|			ELSE ClientDataScans.Ref
	|		END AS ClientDataScan,
	|		MAX(RoomInventoryPeriods.InHouseGuests) AS InHouseGuests,
	|		MAX(RoomInventoryPeriods.InHouseRooms) AS InHouseRooms,
	|		MAX(RoomInventoryPeriods.InHouseBeds) AS InHouseBeds,
	|		MAX(RoomInventoryPeriods.InHouseAdditionalBeds) AS InHouseAdditionalBeds,
	|		MAX(RoomInventoryPeriods.GuestsReserved) AS GuestsReserved,
	|		MAX(RoomInventoryPeriods.RoomsReserved) AS RoomsReserved,
	|		MAX(RoomInventoryPeriods.BedsReserved) AS BedsReserved,
	|		MAX(RoomInventoryPeriods.AdditionalBedsReserved) AS AdditionalBedsReserved
	|	FROM
	|		AccumulationRegister.RoomInventory AS RoomInventoryPeriods
	|			LEFT JOIN InformationRegister.AccommodationForeignerRegistryRecords.SliceLast(&qEndOfTime, &qShowFRR) AS ForeignerRegistryRecords
	|			ON RoomInventoryPeriods.Recorder = ForeignerRegistryRecords.Accommodation
	|			LEFT JOIN Document.ClientDataScans AS ClientDataScans
	|			ON RoomInventoryPeriods.Recorder = ClientDataScans.ParentDoc
	|				AND (ClientDataScans.Posted)
	|				AND (&qShowCDS)
	|	WHERE
	|		RoomInventoryPeriods.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND CASE
	|				WHEN NOT &qShowReservations
	|					THEN RoomInventoryPeriods.IsAccommodation
	|				ELSE RoomInventoryPeriods.IsAccommodation
	|						OR RoomInventoryPeriods.IsReservation
	|			END
	|		AND RoomInventoryPeriods.Hotel IN HIERARCHY(&qHotel)
	|		AND (&qRoomIsFilled
	|					AND RoomInventoryPeriods.Room IN HIERARCHY (&qRoom)
	|				OR NOT &qRoomIsFilled)
	|		AND RoomInventoryPeriods.RoomType IN HIERARCHY(&qRoomType)
	|		AND (&qCustomerIsEmpty
	|				OR RoomInventoryPeriods.Customer IN HIERARCHY (&qCustomer))
	|		AND (&qGuestIsEmpty
	|				OR RoomInventoryPeriods.Guest IN HIERARCHY (&qGuest))
	|		AND (ISNULL(RoomInventoryPeriods.AccommodationStatus.IsInHouse, FALSE)
	|				OR NOT &qShowInHouseOnly)
	|		AND (NOT ISNULL(RoomInventoryPeriods.AccommodationStatus.IsInHouse, FALSE)
	|				OR NOT &qShowNotInHouseOnly)
	|		AND (RoomInventoryPeriods.PeriodFrom < &qPeriodTo
	|					AND RoomInventoryPeriods.PeriodTo > &qPeriodFrom
	|					AND &qPeriodCheckType = &qAccommodation
	|				OR RoomInventoryPeriods.PeriodFrom >= &qPeriodFrom
	|					AND RoomInventoryPeriods.PeriodFrom < &qPeriodTo
	|					AND RoomInventoryPeriods.PeriodFrom = RoomInventoryPeriods.CheckInDate
	|					AND (&qPeriodCheckType = &qCheckIn
	|						OR &qPeriodCheckType = &qCheckInOrCheckOut)
	|				OR RoomInventoryPeriods.PeriodTo > &qPeriodFrom
	|					AND RoomInventoryPeriods.PeriodTo <= &qPeriodTo
	|					AND RoomInventoryPeriods.PeriodTo = RoomInventoryPeriods.CheckOutDate
	|					AND (&qPeriodCheckType = &qCheckOut
	|						OR &qPeriodCheckType = &qCheckInOrCheckOut)
	|				OR RoomInventoryPeriods.Recorder.Date >= &qPeriodFrom
	|					AND RoomInventoryPeriods.Recorder.Date < &qPeriodTo
	|					AND &qPeriodCheckType = &qDocDateInPeriod)
	|	
	|	GROUP BY
	|		RoomInventoryPeriods.Recorder,
	|		RoomInventoryPeriods.Room,
	|		RoomInventoryPeriods.RoomType,
	|		RoomInventoryPeriods.AccommodationType,
	|		RoomInventoryPeriods.PeriodFrom,
	|		RoomInventoryPeriods.PeriodDuration,
	|		RoomInventoryPeriods.PeriodTo,
	|		RoomInventoryPeriods.CheckInAccountingDate,
	|		RoomInventoryPeriods.CheckOutAccountingDate,
	|		CASE
	|			WHEN ForeignerRegistryRecords.ForeignerRegistryRecord IS NULL
	|				THEN &qEmptyForeignerRegistryRecord
	|			ELSE ForeignerRegistryRecords.ForeignerRegistryRecord
	|		END,
	|		CASE
	|			WHEN ClientDataScans.Ref IS NULL
	|				THEN &qEmptyClientDataScan
	|			ELSE ClientDataScans.Ref
	|		END) AS RoomInventory
	|		LEFT JOIN (SELECT
	|			GuestSales.ParentDoc AS ParentDoc,
	|			GuestSales.SalesTurnover AS Sales,
	|			GuestSales.RoomRevenueTurnover AS RoomRevenue
	|		FROM
	|			AccumulationRegister.Sales.Turnovers(
	|					&qBegOfPeriodFrom,
	|					&qEndOfPeriodTo,
	|					,
	|					&qShowSales
	|						AND NOT IsCorrection) AS GuestSales) AS GuestPeriodSales
	|		ON RoomInventory.Recorder = GuestPeriodSales.ParentDoc
	|			AND (&qShowSales)
	|		LEFT JOIN (SELECT
	|			GuestSales.ParentDoc AS ParentDoc,
	|			GuestSales.SalesTurnover AS Sales,
	|			GuestSales.RoomRevenueTurnover AS RoomRevenue
	|		FROM
	|			AccumulationRegister.Sales.Turnovers(
	|					,
	|					,
	|					,
	|					&qShowTotalSales
	|						AND NOT IsCorrection) AS GuestSales) AS GuestTotalSales
	|		ON RoomInventory.Recorder = GuestTotalSales.ParentDoc
	|			AND (&qShowTotalSales)
	|		LEFT JOIN (SELECT
	|			GuestSales.ParentDoc AS ParentDoc,
	|			GuestSales.SalesTurnover AS Sales
	|		FROM
	|			AccumulationRegister.Sales.Turnovers(
	|					,
	|					,
	|					,
	|					&qShowTotalCustomerSales
	|						AND NOT ISNULL(Customer.IsIndividual, TRUE)
	|						AND NOT IsCorrection) AS GuestSales) AS GuestTotalCustomerSales
	|		ON RoomInventory.Recorder = GuestTotalCustomerSales.ParentDoc
	|			AND (&qShowTotalCustomerSales)
	|		LEFT JOIN (SELECT
	|			AccountsBalance.Folio.ParentDoc AS FolioParentDoc,
	|			SUM(AccountsBalance.SumBalance) AS ClientSumBalance
	|		FROM
	|			AccumulationRegister.Accounts.Balance(
	|					&qEndOfPeriodTo,
	|					&qShowBalances
	|						AND (Folio.Customer = &qEmptyCustomer
	|							OR Folio.Customer <> &qEmptyCustomer
	|								AND Folio.Customer.IsIndividual)) AS AccountsBalance
	|		
	|		GROUP BY
	|			AccountsBalance.Folio.ParentDoc) AS ClientBalances
	|		ON RoomInventory.Recorder = ClientBalances.FolioParentDoc
	|			AND (&qShowBalances)
	|		LEFT JOIN (SELECT
	|			ClientTurnovers.Client AS Client,
	|			ClientTurnovers.GuestsCheckedInTurnover AS NumberOfCheckins
	|		FROM
	|			AccumulationRegister.Sales.Turnovers(
	|					,
	|					&qBegOfPeriodFrom,
	|					PERIOD,
	|					&qNumberOfVisitsIsUsed
	|						AND NOT IsCorrection
	|						AND (&qHotelIsEmpty
	|							OR Hotel IN HIERARCHY (&qHotel))) AS ClientTurnovers) AS ClientTotals
	|		ON RoomInventory.Recorder.Guest = ClientTotals.Client
	|		LEFT JOIN Document.Accommodation.RoomRates AS ExpectedRoomMoves
	|		ON RoomInventory.Recorder = ExpectedRoomMoves.Ref
	|			AND RoomInventory.Recorder.Room <> ExpectedRoomMoves.Room
	|			AND (BEGINOFPERIOD(ExpectedRoomMoves.AccountingDate, DAY) = &qBegOfPeriodFrom)
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
	|		LEFT JOIN InformationRegister.GuestsExportedToUMMS AS GuestsExportedToUMMS
	|		ON RoomInventory.Recorder.Guest = GuestsExportedToUMMS.Guest
	|			AND (BEGINOFPERIOD(RoomInventory.CheckInDate, DAY) = GuestsExportedToUMMS.CheckInDate)
	|			AND (BEGINOFPERIOD(RoomInventory.CheckOutDate, DAY) = GuestsExportedToUMMS.CheckOutDate)
	|WHERE
	|	(NOT &qShowMainRoomGuestsOnly
	|			OR &qShowMainRoomGuestsOnly
	|				AND (RoomInventory.Recorder.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Room)
	|					OR RoomInventory.Recorder.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Beds)))
	|	AND (NOT &qShowRoomMovesOnly
	|			OR &qShowRoomMovesOnly
	|				AND NOT ExpectedRoomMoves.Room IS NULL)
	|	AND (&qGuestGroupIsEmpty
	|			OR NOT &qGuestGroupIsEmpty
	|				AND RoomInventory.Recorder.GuestGroup = &qGuestGroup)
	|	AND (&qTagsCount = 0
	|			OR &qTagsCount > 0
	|				AND RoomInventory.Recorder.Guest IN
	|					(SELECT
	|						ClientsWithTags.Client
	|					FROM
	|						ClientsWithTags AS ClientsWithTags))
	|{WHERE
	|	RoomInventory.Recorder.* AS Recorder,
	|	RoomInventory.ForeignerRegistryRecord.* AS ForeignerRegistryRecord,
	|	RoomInventory.ClientDataScan.* AS ClientDataScan,
	|	RoomInventory.Recorder.Hotel.* AS Hotel,
	|	RoomInventory.RoomType.* AS RoomType,
	|	RoomInventory.Room.* AS Room,
	|	RoomInventory.AccommodationType.* AS AccommodationType,
	|	RoomInventory.Recorder.Customer.* AS Customer,
	|	RoomInventory.Recorder.CustomerType AS CustomerType,
	|	RoomInventory.Recorder.Contract.* AS Contract,
	|	RoomInventory.Recorder.ContactPerson AS ContactPerson,
	|	RoomInventory.Recorder.Agent.* AS Agent,
	|	RoomInventory.Recorder.GuestGroup.* AS GuestGroup,
	|	RoomInventory.Recorder.ParentDoc.* AS ParentDoc,
	|	RoomInventory.Recorder.HotelProduct.* AS HotelProduct,
	|	(CASE
	|			WHEN RoomInventory.Recorder.AccommodationStatus IS NULL
	|				THEN RoomInventory.Recorder.ReservationStatus
	|			ELSE RoomInventory.Recorder.AccommodationStatus
	|		END) AS AccommodationStatus,
	|	RoomInventory.CheckInDate AS CheckInDate,
	|	RoomInventory.Duration AS Duration,
	|	RoomInventory.CheckOutDate AS CheckOutDate,
	|	RoomInventory.CheckInAccountingDate AS CheckInAccountingDate,
	|	RoomInventory.CheckOutAccountingDate AS CheckOutAccountingDate,
	|	(CASE
	|			WHEN &qShowMainRoomGuestsOnly
	|				THEN ISNULL(RoomInventory.Recorder.NumberOfAdults, 0) + ISNULL(RoomInventory.Recorder.NumberOfTeenagers, 0) + ISNULL(RoomInventory.Recorder.NumberOfChildren, 0) + ISNULL(RoomInventory.Recorder.NumberOfInfants, 0)
	|			ELSE RoomInventory.InHouseGuests + RoomInventory.GuestsReserved
	|		END) AS InHouseGuests,
	|	(ISNULL(RoomInventory.Recorder.NumberOfAdults, 0)) AS NumberOfAdults,
	|	(ISNULL(RoomInventory.Recorder.NumberOfTeenagers, 0)) AS NumberOfTeenagers,
	|	(ISNULL(RoomInventory.Recorder.NumberOfChildren, 0)) AS NumberOfChildren,
	|	(ISNULL(RoomInventory.Recorder.NumberOfInfants, 0)) AS NumberOfInfants,
	|	(RoomInventory.InHouseRooms + RoomInventory.RoomsReserved) AS InHouseRooms,
	|	(RoomInventory.InHouseBeds + RoomInventory.BedsReserved) AS InHouseBeds,
	|	(RoomInventory.InHouseAdditionalBeds + RoomInventory.AdditionalBedsReserved) AS InHouseAdditionalBeds,
	|	(ISNULL(GuestPeriodSales.Sales, 0)) AS Sales,
	|	(ISNULL(GuestPeriodSales.RoomRevenue, 0)) AS RoomRevenue,
	|	(ISNULL(GuestTotalSales.Sales, 0)) AS TotalSales,
	|	(ISNULL(GuestTotalSales.RoomRevenue, 0)) AS TotalRoomRevenue,
	|	(ISNULL(GuestTotalCustomerSales.Sales, 0)) AS TotalCustomerSales,
	|	(ISNULL(ClientBalances.ClientSumBalance, 0)) AS ClientSumBalance,
	|	RoomInventory.Recorder.RoomQuota.* AS RoomQuota,
	|	(ISNULL(RoomInventory.Recorder.RoomQuantity, 1)) AS RoomQuantity,
	|	RoomInventory.Recorder.ClientType.* AS ClientType,
	|	RoomInventory.Recorder.Guest.* AS Guest,
	|	RoomInventory.Recorder.MarketingCode.* AS MarketingCode,
	|	RoomInventory.Recorder.TripPurpose.* AS TripPurpose,
	|	RoomInventory.Recorder.SourceOfBusiness.* AS SourceOfBusiness,
	|	RoomInventory.Recorder.RoomRateType.* AS RoomRateType,
	|	RoomInventory.Recorder.RoomRate.* AS RoomRate,
	|	RoomInventory.Recorder.PricePresentation AS PricePresentation,
	|	RoomInventory.Recorder.DiscountCard.* AS DiscountCard,
	|	RoomInventory.Recorder.DiscountType.* AS DiscountType,
	|	RoomInventory.Recorder.Discount AS Discount,
	|	RoomInventory.Recorder.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	RoomInventory.Recorder.Car AS Car,
	|	RoomInventory.Recorder.Remarks AS Remarks,
	|	RoomInventory.Recorder.Author.* AS Author,
	|	RoomInventory.Recorder.AgentCommission AS AgentCommission,
	|	RoomInventory.Recorder.AgentCommissionType.* AS AgentCommissionType,
	|	RoomInventory.Recorder.AccommodationTemplate.* AS AccommodationTemplate,
	|	RoomInventory.Recorder.IsMaster AS IsMaster,
	|	ExpectedRoomMoves.Room.* AS RoomTo,
	|	(CASE
	|			WHEN RoomInventory.ForeignerRegistryRecord.MigrationCardDateTo <> &qEmptyDate
	|				THEN DATEDIFF(RoomInventory.ForeignerRegistryRecord.MigrationCardDateTo, RoomInventory.Recorder.CheckOutDate, DAY)
	|			ELSE 0
	|		END) AS MigrationCardDateToDeviance,
	|	(CASE
	|			WHEN RoomInventory.ForeignerRegistryRecord.VisaToDate <> &qEmptyDate
	|				THEN DATEDIFF(RoomInventory.ForeignerRegistryRecord.VisaToDate, RoomInventory.Recorder.CheckOutDate, DAY)
	|			ELSE 0
	|		END) AS VisaToDateDeviance,
	|	RoomInventory.Recorder.Guest.TagsPresentation AS ClientTagsPresentation,
	|	(ISNULL(ClientTotals.NumberOfCheckins, 0)) AS NumberOfCheckins,
	|	RoomInventory.Recorder.AccommodationStatus.IsCheckIn AS IsCheckIn,
	|	RoomInventory.Recorder.AccommodationStatus.IsCheckOut AS IsCheckOut,
	|	RoomInventory.Recorder.AccommodationStatus.IsRoomChange AS IsRoomChange,
	|	RoomInventory.Recorder.AccommodationStatus.IsInHouse AS IsInHouse,
	|	(CASE
	|			WHEN RoomInventory.Recorder.RoomTypeUpgrade <> RoomInventory.Recorder.RoomType
	|					AND RoomInventory.Recorder.RoomTypeUpgrade <> VALUE(Catalog.RoomTypes.EmptyRef)
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS PriceForRoomTypeIsDifferent,
	|	ReservationCustomAttributeValues1.CharacteristicValue.* AS CustomAttribute1,
	|	ReservationCustomAttributeValues2.CharacteristicValue.* AS CustomAttribute2,
	|	ReservationCustomAttributeValues3.CharacteristicValue.* AS CustomAttribute3}
	|
	|ORDER BY
	|	Hotel,
	|	Room,
	|	CheckInDate,
	|	Guest
	|{ORDER BY
	|	RoomInventory.Recorder.* AS Recorder,
	|	RoomInventory.ForeignerRegistryRecord.* AS ForeignerRegistryRecord,
	|	RoomInventory.ClientDataScan.* AS ClientDataScan,
	|	Customer.* AS Customer,
	|	RoomInventory.Recorder.CustomerType.* AS CustomerType,
	|	RoomInventory.Recorder.Contract.* AS Contract,
	|	RoomInventory.Recorder.Agent.* AS Agent,
	|	GuestGroup.* AS GuestGroup,
	|	Guest.* AS Guest,
	|	RoomInventory.Recorder.MarketingCode.* AS MarketingCode,
	|	RoomInventory.Recorder.TripPurpose.* AS TripPurpose,
	|	RoomInventory.Recorder.SourceOfBusiness.* AS SourceOfBusiness,
	|	RoomRate.* AS RoomRate,
	|	RoomInventory.Recorder.RoomRateType.* AS RoomRateType,
	|	RoomInventory.Recorder.DiscountCard.* AS DiscountCard,
	|	RoomInventory.Recorder.DiscountType.* AS DiscountType,
	|	RoomInventory.Recorder.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	Room.* AS Room,
	|	RoomType.* AS RoomType,
	|	AccommodationType.* AS AccommodationType,
	|	RoomTo.* AS RoomTo,
	|	Hotel.* AS Hotel,
	|	RoomInventory.Recorder.PointInTime AS PointInTime,
	|	CheckInDate AS CheckInDate,
	|	Duration AS Duration,
	|	CheckOutDate AS CheckOutDate,
	|	RoomInventory.Recorder.RoomRateType.* AS RoomRateType,
	|	RoomInventory.Recorder.AccommodationTemplate.* AS AccommodationTemplate,
	|	RoomRate.* AS RoomRate,
	|	PricePresentation AS PricePresentation,
	|	RoomInventory.Recorder.Author.* AS Author,
	|	RoomInventory.Recorder.Guest.TagsPresentation AS ClientTagsPresentation,
	|	InHouseGuests AS InHouseGuests,
	|	NumberOfAdults,
	|	NumberOfTeenagers,
	|	NumberOfChildren,
	|	NumberOfInfants,
	|	InHouseRooms AS InHouseRooms,
	|	InHouseBeds AS InHouseBeds,
	|	InHouseAdditionalBeds AS InHouseAdditionalBeds,
	|	RoomInventory.CheckInAccountingDate AS CheckInAccountingDate,
	|	RoomInventory.CheckOutAccountingDate AS CheckOutAccountingDate,
	|	(HOUR(RoomInventory.Recorder.CheckInDate)) AS CheckInHour,
	|	(DAY(RoomInventory.Recorder.CheckInDate)) AS CheckInDay,
	|	(WEEK(RoomInventory.Recorder.CheckInDate)) AS CheckInWeek,
	|	(MONTH(RoomInventory.Recorder.CheckInDate)) AS CheckInMonth,
	|	(QUARTER(RoomInventory.Recorder.CheckInDate)) AS CheckInQuarter,
	|	(YEAR(RoomInventory.Recorder.CheckInDate)) AS CheckInYear,
	|	Sales,
	|	RoomRevenue,
	|	TotalSales,
	|	TotalRoomRevenue,
	|	TotalCustomerSales,
	|	ClientSumBalance,
	|	NumberOfCheckins,
	|	RoomQuantity,
	|	RoomInventory.Recorder.RoomQuota.* AS RoomQuota,
	|	ReservationCustomAttributeValues1.CharacteristicValue.* AS CustomAttribute1,
	|	ReservationCustomAttributeValues2.CharacteristicValue.* AS CustomAttribute2,
	|	ReservationCustomAttributeValues3.CharacteristicValue.* AS CustomAttribute3,
	|	Unloaded}
	|TOTALS
	|	SUM(InHouseGuests),
	|	SUM(NumberOfAdults),
	|	SUM(NumberOfTeenagers),
	|	SUM(NumberOfChildren),
	|	SUM(NumberOfInfants),
	|	SUM(InHouseRooms),
	|	SUM(InHouseBeds),
	|	SUM(InHouseAdditionalBeds),
	|	SUM(HotelProductSum),
	|	SUM(Sales),
	|	SUM(RoomRevenue),
	|	SUM(TotalSales),
	|	SUM(TotalRoomRevenue),
	|	SUM(TotalCustomerSales),
	|	SUM(ClientSumBalance),
	|	SUM(RoomQuantity)
	|BY
	|	OVERALL,
	|	Hotel,
	|	Room
	|{TOTALS BY
	|	Hotel.* AS Hotel,
	|	RoomInventory.CheckInAccountingDate AS CheckInAccountingDate,
	|	RoomInventory.CheckOutAccountingDate AS CheckOutAccountingDate,
	|	(HOUR(RoomInventory.Recorder.CheckInDate)) AS CheckInHour,
	|	(DAY(RoomInventory.Recorder.CheckInDate)) AS CheckInDay,
	|	(WEEK(RoomInventory.Recorder.CheckInDate)) AS CheckInWeek,
	|	(MONTH(RoomInventory.Recorder.CheckInDate)) AS CheckInMonth,
	|	(QUARTER(RoomInventory.Recorder.CheckInDate)) AS CheckInQuarter,
	|	(YEAR(RoomInventory.Recorder.CheckInDate)) AS CheckInYear,
	|	RoomType.* AS RoomType,
	|	Room.* AS Room,
	|	RoomTo.* AS RoomTo,
	|	AccommodationType.* AS AccommodationType,
	|	Guest.* AS Guest,
	|	Customer.* AS Customer,
	|	RoomInventory.Recorder.CustomerType.* AS CustomerType,
	|	RoomInventory.Recorder.Contract.* AS Contract,
	|	RoomInventory.Recorder.ContactPerson AS ContactPerson,
	|	RoomInventory.Recorder.Agent.* AS Agent,
	|	GuestGroup.* AS GuestGroup,
	|	RoomInventory.Recorder.HotelProduct.* AS HotelProduct,
	|	AccommodationStatus.* AS AccommodationStatus,
	|	RoomInventory.Recorder.RoomQuota.* AS RoomQuota,
	|	RoomInventory.Recorder.ClientType.* AS ClientType,
	|	RoomInventory.Recorder.MarketingCode.* AS MarketingCode,
	|	RoomInventory.Recorder.TripPurpose.* AS TripPurpose,
	|	RoomInventory.Recorder.SourceOfBusiness.* AS SourceOfBusiness,
	|	RoomInventory.Recorder.RoomRateType.* AS RoomRateType,
	|	RoomInventory.Recorder.AccommodationTemplate.* AS AccommodationTemplate,
	|	RoomRate.* AS RoomRate,
	|	PricePresentation AS PricePresentation,
	|	RoomInventory.Recorder.DiscountCard.* AS DiscountCard,
	|	RoomInventory.Recorder.DiscountType.* AS DiscountType,
	|	RoomInventory.Recorder.Author.* AS Author,
	|	RoomInventory.Recorder.* AS Recorder,
	|	RoomInventory.ForeignerRegistryRecord.* AS ForeignerRegistryRecord,
	|	RoomInventory.ClientDataScan.* AS ClientDataScan,
	|	RoomInventory.Recorder.PlannedPaymentMethod.* AS PlannedPaymentMethod,
	|	RoomInventory.Recorder.Guest.TagsPresentation AS ClientTagsPresentation,
	|	(CASE
	|			WHEN RoomInventory.Recorder.RoomTypeUpgrade <> RoomInventory.Recorder.RoomType
	|					AND RoomInventory.Recorder.RoomTypeUpgrade <> VALUE(Catalog.RoomTypes.EmptyRef)
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS PriceForRoomTypeIsDifferent,
	|	ReservationCustomAttributeValues1.CharacteristicValue.* AS CustomAttribute1,
	|	ReservationCustomAttributeValues2.CharacteristicValue.* AS CustomAttribute2,
	|	ReservationCustomAttributeValues3.CharacteristicValue.* AS CustomAttribute3,
	|	NumberOfCheckins}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("en='Room occupation history';de='Zimmerbesatzungsgeschichte';ru='История заселения номеров'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
