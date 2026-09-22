
#Region Public

// -----------------------------------------------------------------------------
// Description: Checks if resource could be used
// Parameters: Resource, Document, Is posted, Reservation period, Error text in
//             russian, Error text in english
// Return value: True if resource could be used and false if not
// -----------------------------------------------------------------------------
Function cmCheckResourceAvailability(pResource, pDoc, pIsPosted, 
                                     pPeriodFrom, pPeriodTo, rMsgTextRu, rMsgTextEn, rMsgTextDe, pIsShareable = False, pNumberOfPersons = 0) Export
	// Initialize working variables
	vOK = True;
	vMsgTextRu = "";
	vMsgTextEn = "";
	vMsgTextDe = "";
	
	// Retrieve all necessary permissions
	vHavePermissionToUseOccupiedResources = cmCheckUserPermissions("HavePermissionToUseOccupiedResources");
	
	// Build and run query to check resource reservation history
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	ResourceReservationHistory.Recorder AS Recorder,
	|	ResourceReservationHistory.DateTimeFrom AS DateTimeFrom,
	|	ResourceReservationHistory.DateTimeTo AS DateTimeTo,
	|	ResourceReservationHistory.GuestGroup AS GuestGroup,
	|	ResourceReservationHistory.NumberOfPersons AS NumberOfPersons
	|FROM
	|	InformationRegister.ResourceReservationHistory AS ResourceReservationHistory
	|WHERE
	|	ResourceReservationHistory.Resource = &qResource
	|	AND ResourceReservationHistory.DateTimeFrom < &qPeriodTo
	|	AND ResourceReservationHistory.DateTimeTo > &qPeriodFrom
	|	AND ResourceReservationHistory.Recorder <> &qResourceReservation
	|	AND ResourceReservationHistory.ResourceReservationStatus.IsActive
	|
	|ORDER BY
	|	ResourceReservationHistory.PointInTime"; 
	vQry.SetParameter("qResource", pResource);
	vQry.SetParameter("qPeriodFrom", pPeriodFrom);
	vQry.SetParameter("qPeriodTo", pPeriodTo);
	vQry.SetParameter("qResourceReservation", pDoc);
	
	vAlreadyBookedPersons = 0;
	vQryTab = vQry.Execute().Unload();
	For Each vQryTabRow In vQryTab Do
		If Not pIsShareable Then
			vMsgTextRu = "Ресурс " + TrimAll(pResource) + " уже забронирован на период с " + 
			             Format(vQryTabRow.DateTimeFrom, "DF='dd.MM.yyyy HH:mm'") + " по " + 
			             Format(vQryTabRow.DateTimeTo, "DF='dd.MM.yyyy HH:mm'") + " для группы " + 
			             TrimAll(vQryTabRow.GuestGroup.Code) + 
			             ?(IsBlankString(vQryTabRow.GuestGroup.Description), "", " (" + TrimAll(vQryTabRow.GuestGroup.Description) + ")");
			vMsgTextEn = "Resource " + TrimAll(pResource) + " is already reserved for the period from " + 
			             Format(vQryTabRow.DateTimeFrom, "DF='dd.MM.yyyy HH:mm'") + " to " + 
			             Format(vQryTabRow.DateTimeTo, "DF='dd.MM.yyyy HH:mm'") + " for the group " + 
			             TrimAll(vQryTabRow.GuestGroup.Code) + 
			             ?(IsBlankString(vQryTabRow.GuestGroup.Description), "", " (" + TrimAll(vQryTabRow.GuestGroup.Description) + ")");
			vMsgTextDe = "Ressource " + TrimAll(pResource) + " ist bereits für den Zeitraum von " + 
			             Format(vQryTabRow.DateTimeFrom, "DF='dd.MM.yyyy HH:mm'") + " bis " + 
			             Format(vQryTabRow.DateTimeTo, "DF='dd.MM.yyyy HH:mm'") + " für die Gruppe " + 
			             TrimAll(vQryTabRow.GuestGroup.Code) + 
			             ?(IsBlankString(vQryTabRow.GuestGroup.Description), "", " (" + TrimAll(vQryTabRow.GuestGroup.Description) + ")");
			vMessage = NStr("ru = '" + TrimAll(vMsgTextRu) + "';" + "en = '" + TrimAll(vMsgTextEn) + "';" + "de = '" + TrimAll(vMsgTextDe) + "';");
			If Not vHavePermissionToUseOccupiedResources Then
				vOK = False;
				rMsgTextRu = rMsgTextRu + vMsgTextRu + Chars.LF;
				rMsgTextEn = rMsgTextEn + vMsgTextEn + Chars.LF;
			Else
				WriteLogEvent(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), EventLogLevel.Warning, pDoc.Metadata(), pDoc, vMessage);
				If cmShowNotEnoughRoomsMessages() Then
					tcCommonFunctionOnClientServer.TextMessage(cmGetMessageHeader(pDoc) + vMessage, MessageStatus.Attention);
				EndIf;
			EndIf;
		Else
			vAlreadyBookedPersons = vAlreadyBookedPersons + vQryTabRow.NumberOfPersons;
		EndIf;
	EndDo;
	If pIsShareable And vAlreadyBookedPersons > 0 And pResource.NumberOfPersonsPerResource > 0 And pNumberOfPersons > 0 And (pResource.NumberOfPersonsPerResource - vAlreadyBookedPersons) < pNumberOfPersons Then
		vOK = False;
		vMsgTextRu = "Ресурс " + TrimAll(pResource) + " уже забронирован на " + vAlreadyBookedPersons + " человек! Максимальное кол-во человек ресурса " + pResource.NumberOfPersonsPerResource + ". Не хватает " + (vAlreadyBookedPersons + pNumberOfPersons - pResource.NumberOfPersonsPerResource) + ". Период: " + 
		             Format(pPeriodFrom, "DF='dd.MM.yyyy HH:mm'") + " по " + 
		             Format(pPeriodTo, "DF='dd.MM.yyyy HH:mm'");
		vMsgTextEn = "Resource " + TrimAll(pResource) + " is already reserved for " + vAlreadyBookedPersons + " persons! Resource capacity is " + pResource.NumberOfPersonsPerResource + ". Not enough persons " + (vAlreadyBookedPersons + pNumberOfPersons - pResource.NumberOfPersonsPerResource) + ". Period: " + 
		             Format(pPeriodFrom, "DF='dd.MM.yyyy HH:mm'") + " to " + 
		             Format(pPeriodTo, "DF='dd.MM.yyyy HH:mm'");
		vMsgTextDe = "Ressource " + TrimAll(pResource) + " ist bereits für " + vAlreadyBookedPersons + " Personen reserviert! Ressource Kapazität ist " + pResource.NumberOfPersonsPerResource + " Personen. Nicht genug Personen " + (vAlreadyBookedPersons + pNumberOfPersons - pResource.NumberOfPersonsPerResource) + ". Periode: " + 
		             Format(pPeriodFrom, "DF='dd.MM.yyyy HH:mm'") + " to " + 
		             Format(pPeriodTo, "DF='dd.MM.yyyy HH:mm'");
		vMessage = NStr("ru = '" + TrimAll(vMsgTextRu) + "';" + "en = '" + TrimAll(vMsgTextEn) + "';" + "de = '" + TrimAll(vMsgTextDe) + "';");
		tcCommonFunctionOnClientServer.TextMessage(cmGetMessageHeader(pDoc) + vMessage, MessageStatus.Attention);
	EndIf;
	
	// OK
	Return vOK;
EndFunction // cmCheckResourceAvailability

// -----------------------------------------------------------------------------
// Description: Calculates and returns duration for giving start of resource 
//              reservation period and end of resource reservation period
// Parameters: Date & time from, Date & time to
// Return value: Number, duration in hours
// -----------------------------------------------------------------------------
Function cmCalculateDurationInHours(pDateTimeFrom, pDateTimeTo) Export
	vDuration = 0;
	If ValueIsFilled(pDateTimeFrom) And
	   ValueIsFilled(pDateTimeTo) Then
		vPerInSec = cm0SecondShift(pDateTimeTo) - cm0SecondShift(pDateTimeFrom);
		vDuration = Round(vPerInSec /3600, 7);
	EndIf;
	Return vDuration;
EndFunction // cmCalculateDurationInHours

// -----------------------------------------------------------------------------
// Description: Returns value table with services that should be automatically 
//              charged for the given resource
// Parameters: Hotel, Date & time from, Date & time to, Client type, Resource type, 
//             Resource, Service package, Service packages value list
// Return value: Value table with services and prices
// -----------------------------------------------------------------------------
Function cmGetResourcePrices(pHotel, pDateTimeFrom, pDateTimeTo, pClientType, pResourceType, pResource, pServicePackage, pServicePackages = Undefined, pTariff = Undefined) Export
	vTariff = pTariff;
	If vTariff = Undefined Then
		vTariff = Catalogs.ResourceTariffs.EmptyRef();
	EndIf;
	// Run query to get resource prices from the information register
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CalendarDays.AccountingDate AS AccountingDate,
	|	CalendarDays.CalendarDayType AS CalendarDayType,
	|	CalendarDays.Timetable AS Timetable,
	|	ResourcePrices.PriceTime AS PriceTime,
	|	ResourcePrices.PriceQuantity AS PriceQuantity,
	|	&qEmptyDate AS DateTimeFrom,
	|	&qEmptyDate AS DateTimeTo,
	|	ResourcePrices.Service AS Service,
	|	ResourcePrices.Price AS Price,
	|	ResourcePrices.Currency AS Currency,
	|	0 AS Quantity,
	|	ResourcePrices.Service.Unit AS Unit,
	|	ResourcePrices.VATRate AS VATRate,
	|	ResourcePrices.MinimumQuantity AS MinimumQuantity,
	|	ResourcePrices.MaximumQuantity AS MaximumQuantity,
	|	ResourcePrices.FreeOfChargeQuantity AS FreeOfChargeQuantity,
	|	ResourcePrices.IsResourceRevenue AS IsResourceRevenue,
	|	ResourcePrices.IsPricePerPerson AS IsPricePerPerson,
	|	ResourcePrices.IsPricePerMinute AS IsPricePerMinute,
	|	ResourcePrices.IsPricePerDay AS IsPricePerDay
	|FROM
	|	InformationRegister.CalendarDays.SliceLast(
	|			&qDateTimeFrom,
	|			Calendar = &qCalendar
	|				AND AccountingDate >= BEGINOFPERIOD(&qDateTimeFrom, DAY)
	|				AND AccountingDate <= BEGINOFPERIOD(&qDateTimeTo, DAY)) AS CalendarDays
	|		LEFT JOIN InformationRegister.ResourcePrices.SliceLast(
	|				&qDateTimeFrom,
	|				(Hotel = &qHotel
	|					OR Hotel = &qEmptyHotel)
	|					AND ResourceTariff = &qTariff
	|					AND (ClientType = &qClientType
	|						OR ClientType = &qClientTypeParent
	|							AND &qClientTypeParent <> VALUE(Catalog.ClientTypes.EmptyRef))
	|					AND (ClientType = &qClientType
	|						OR ClientType = &qClientTypeParent
	|							AND &qClientTypeParent <> VALUE(Catalog.ClientTypes.EmptyRef))
	|					AND (Resource = &qResource
	|						OR ResourceType = &qResourceType
	|							AND Resource = &qEmptyResource
	|						OR ResourceType = &qEmptyResourceType
	|							AND Resource = &qEmptyResource)) AS ResourcePrices
	|		ON (CalendarDays.CalendarDayType = ResourcePrices.CalendarDayType
	|				OR ResourcePrices.CalendarDayType = &qEmptyCalendarDayType)
	|
	|ORDER BY
	|	CalendarDays.AccountingDate,
	|	ResourcePrices.Service.IsResourceRevenue DESC,
	|	ResourcePrices.Service.SortCode,
	|	ResourcePrices.Service.Description,
	|	PriceTime,
	|	PriceQuantity";
	vQry.SetParameter("qEmptyDate", '00010101'); 
	vQry.SetParameter("qDateTimeFrom", pDateTimeFrom); 
	vQry.SetParameter("qDateTimeTo", pDateTimeTo); 
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef()); 
	vQry.SetParameter("qTariff", vTariff);
	vQry.SetParameter("qClientType", pClientType);
	vQry.SetParameter("qClientTypeParent", ?(ValueIsFilled(pClientType), pClientType.Parent, Catalogs.ClientTypes.EmptyRef()));
	vQry.SetParameter("qResource", pResource);
	vQry.SetParameter("qEmptyResource", Catalogs.Resources.EmptyRef()); 
	vQry.SetParameter("qResourceType", pResourceType);
	vQry.SetParameter("qEmptyResourceType", Catalogs.ResourceTypes.EmptyRef()); 
	vQry.SetParameter("qEmptyCalendarDayType", Catalogs.CalendarDayTypes.EmptyRef()); 
	vQry.SetParameter("qCalendar", ?(ValueIsFilled(pResource), pResource.Calendar, Catalogs.Calendars.EmptyRef()));
	vQry.SetParameter("qEmptyQuantityCalculationRule", Catalogs.QuantityCalculationRules.EmptyRef()); 
	vPrices = vQry.Execute().Unload();
	vPrices.Columns.Add("Remarks", cmGetStringTypeDescription());
	// Process prices retrieved to fill service period and check price time and quantity
	vPrevPricesRow = Undefined;
	vPrevPriceQuantity = 0;
	i = 0;
	While i < vPrices.Count() Do
		vPricesRow = vPrices.Get(i);
		If Not ValueIsFilled(vPricesRow.Service) Then
			i = i + 1;
			Continue;
		EndIf;
		// Calculate number of hours or minutes between period from and period to
		vSrvQuantity = 0;
		If ValueIsFilled(pDateTimeFrom) And ValueIsFilled(pDateTimeTo) Then
			If pDateTimeFrom < pDateTimeTo Then
				If vPricesRow.IsPricePerMinute Then
					vSrvQuantity = Int(((pDateTimeTo - pDateTimeFrom) + 1)/60); // in minutes
				Else
					vSrvQuantity = Int(((pDateTimeTo - pDateTimeFrom) + 1)/3600); // in hours
				EndIf;
			EndIf;
		EndIf;
		// Check should we move to the next row
		vNumberOfDeletedRows = 0;
		// Delete service price records with price quantity greater then calculated price quantity
		If vPricesRow.PriceQuantity > vSrvQuantity Then
			vPrices.Delete(vPricesRow);
			Continue;
		ElsIf vPricesRow.PriceQuantity > vPrevPriceQuantity Then
			If vPrevPricesRow <> Undefined Then
				If vPrevPricesRow.AccountingDate = vPricesRow.AccountingDate And 
				   vPrevPricesRow.Service = vPricesRow.Service Then
					vPrices.Delete(vPrevPricesRow);
					vPrevPricesRow = Undefined;
					vNumberOfDeletedRows = vNumberOfDeletedRows + 1;
				EndIf;
			EndIf;
		EndIf;
		vPrevPriceQuantity = vPricesRow.PriceQuantity;
		// Fill service price period
		vPricePeriodFrom = vPricesRow.AccountingDate;
		If vPricesRow.PriceTime > BegOfDay(vPricesRow.PriceTime) Then
			vPricePeriodFrom = vPricePeriodFrom + (vPricesRow.PriceTime - BegOfDay(vPricesRow.PriceTime));
		EndIf;
		vPricesRow.DateTimeFrom = vPricePeriodFrom;
		vPricesRow.DateTimeTo = EndOfDay(vPricePeriodFrom);
		If vPricesRow.DateTimeTo > pDateTimeTo Then
			vPricesRow.DateTimeTo = pDateTimeTo;
		EndIf;
		// Check previous price row
		If vPrevPricesRow <> Undefined Then
			If vPrevPricesRow.AccountingDate = vPricesRow.AccountingDate And 
			   vPrevPricesRow.Service = vPricesRow.Service Then
				If vPricesRow.DateTimeFrom <= pDateTimeFrom And
				   vPrevPricesRow.DateTimeFrom < vPricesRow.DateTimeFrom Then
					vPrices.Delete(vPrevPricesRow);
					vPrevPricesRow = Undefined;
					vNumberOfDeletedRows = vNumberOfDeletedRows + 1;
				EndIf;
			EndIf;
		EndIf;
		// Check end of resource reservaion period
		If pDateTimeTo <= vPricesRow.DateTimeFrom Then
			vPrices.Delete(vPricesRow);
			vNumberOfDeletedRows = vNumberOfDeletedRows + 1;
		Else
			// Fill end of period for the previous price row
			If vPrevPricesRow <> Undefined Then
				If vPrevPricesRow.AccountingDate = vPricesRow.AccountingDate And 
				   vPrevPricesRow.Service = vPricesRow.Service Then
					If vPricesRow.DateTimeFrom <= pDateTimeTo And
					   vPrevPricesRow.DateTimeFrom < vPricesRow.DateTimeFrom Then
						vPrevPricesRow.DateTimeTo = vPricesRow.DateTimeFrom;
					EndIf;
				EndIf;
			EndIf;
			// Check start of period for the current row
			If vPricesRow.DateTimeFrom <= pDateTimeFrom Then
				vPricesRow.DateTimeFrom = pDateTimeFrom;
			EndIf;
			// Delete previous prices row if it's attributes are the same as for the new one
			If vPrevPricesRow <> Undefined Then
				If vPrevPricesRow.AccountingDate = vPricesRow.AccountingDate And 
				   vPrevPricesRow.Service = vPricesRow.Service Then
					If vPricesRow.DateTimeFrom = vPrevPricesRow.DateTimeFrom And 
					   vPricesRow.DateTimeTo = vPrevPricesRow.DateTimeTo Then
						vPrices.Delete(vPrevPricesRow);
						vNumberOfDeletedRows = vNumberOfDeletedRows + 1;
					EndIf;
				EndIf;
			EndIf;
			// Save previous prices row
			vPrevPricesRow = vPricesRow;
		EndIf;
		// Next row
		i = i - vNumberOfDeletedRows + 1;
	EndDo;
	// Add services from the service package
	If ValueIsFilled(pServicePackage) Or (pServicePackages <> Undefined And pServicePackages.Count() > 0) Then
		vServicePackages = New ValueList();
		If ValueIsFilled(pServicePackage) Then
			vServicePackages.Add(pServicePackage);
		EndIf;
		If pServicePackages <> Undefined And pServicePackages.Count() > 0 Then
			For Each pServicePackagesRow In pServicePackages Do
				If ValueIsFilled(pServicePackagesRow.ServicePackage) Then
					vServicePackages.Add(pServicePackagesRow.ServicePackage);
				EndIf;
			EndDo;
		EndIf;
		For Each vServicePackagesItem In vServicePackages Do
			vServicePackage = vServicePackagesItem.Value;
			If vServicePackage.DateValidFrom <= BegOfDay(pDateTimeFrom) And 
			   (vServicePackage.DateValidTo >= BegOfDay(pDateTimeFrom) Or Not ValueIsFilled(vServicePackage.DateValidTo)) Then
				vServices = Catalogs.ServicePackages.GetServices(vServicePackage, pDateTimeFrom);
				vSPRows = vServices.FindRows(New Structure("ClientType", pClientType));
				If vSPRows.Count() = 0 And ValueIsFilled(pClientType) Then
					vSPRows = vServices.FindRows(New Structure("ClientType", Catalogs.ClientTypes.EmptyRef()));
				EndIf;
				If vSPRows.Count() > 0 Then
					vDays = New ValueTable();
					If ValueIsFilled(pResource) And ValueIsFilled(pResource.Calendar) Then
						vDays = pResource.Calendar.GetObject().pmGetDays(pDateTimeFrom, pDateTimeTo, , , Catalogs.RoomTypes.EmptyRef(), pDateTimeFrom);
					EndIf;
					For Each vSPRow In vSPRows Do
						// Get accounting date
						vAccountingDate = ?(ValueIsFilled(pDateTimeFrom), BegOfDay(pDateTimeFrom), BegOfDay(CurrentSessionDate()));
						If ValueIsFilled(vSPRow.AccountingDate) Then
							vAccountingDate = BegOfDay(vSPRow.AccountingDate);
						ElsIf vSPRow.AccountingDayNumber = 9999 Then
							vAccountingDate = ?(ValueIsFilled(pDateTimeTo), BegOfDay(pDateTimeTo), BegOfDay(CurrentSessionDate()));
						ElsIf vSPRow.AccountingDayNumber > 0 Then
							vAccountingDate = ?(ValueIsFilled(pDateTimeFrom), BegOfDay(pDateTimeFrom) + (vSPRow.AccountingDayNumber - 1)*24*3600, BegOfDay(CurrentSessionDate()) + (vSPRow.AccountingDayNumber - 1)*24*3600);
						ElsIf ValueIsFilled(vSPRow.QuantityCalculationRule) Then
							vAccountingDate = ?(ValueIsFilled(pDateTimeFrom), BegOfDay(pDateTimeFrom), BegOfDay(CurrentSessionDate()));
						EndIf;
						// Get calendar day type and timetable 
						vCalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
						vTimetable = Catalogs.Timetables.EmptyRef();
						If vDays.Count() > 0 Then
							vDaysRow = vDays.Find(vAccountingDate, "Period");
							If vDaysRow <> Undefined Then
								vCalendarDayType = vDaysRow.CalendarDayType;
								vTimetable = vDaysRow.Timetable;
							EndIf;
						EndIf;
						// Check calendar day type
						If ValueIsFilled(vSPRow.CalendarDayType) And vSPRow.CalendarDayType <> vCalendarDayType Then
							Continue;
						EndIf;
						// Add prices row
						vPricesRow = vPrices.Add();
						vPricesRow.AccountingDate = vAccountingDate;
						vPricesRow.CalendarDayType = vCalendarDayType;
						vPricesRow.Timetable = vTimetable;
						vPricesRow.PriceTime = '00010101';
						vPricesRow.PriceQuantity = 0;
						vPricesRow.DateTimeFrom = vPricesRow.AccountingDate;
						vPricesRow.DateTimeTo = EndOfDay(vPricesRow.AccountingDate);
						vPricesRow.Service = vSPRow.Service;
						vPricesRow.Price = vSPRow.Price;
						vPricesRow.Currency = vSPRow.Currency;
						vPricesRow.Quantity = vSPRow.Quantity;
						vRemarks = TrimAll(vSPRow.Remarks);
						If ValueIsFilled(vSPRow.QuantityCalculationRule) Then
							vIsDayUse = False;
							// Calculate quantity
							vQuantity = cmCalculateServiceQuantity(vSPRow.Service, vSPRow.QuantityCalculationRule, 
																   vPricesRow.AccountingDate, pDateTimeFrom, pDateTimeTo, 
																   Undefined, Undefined, True, True, False, False, True, True, 
																   vSPRow.Price, vSPRow.Currency, vRemarks, vIsDayUse);
							// Remove prices row if quantity is equal 0
							If vQuantity = 0 Then
								vPrices.Delete(vPricesRow);
								Continue;
							Else
								vPricesRow.Quantity = vPricesRow.Quantity * vQuantity;
							EndIf;
						EndIf;
						vPricesRow.Unit = vSPRow.Unit;
						vPricesRow.VATRate = vSPRow.VATRate;
						vPricesRow.MinimumQuantity = 0;
						vPricesRow.FreeOfChargeQuantity = 0;
						vPricesRow.IsResourceRevenue = vPricesRow.Service.IsResourceRevenue;
						vPricesRow.IsPricePerPerson = vSPRow.IsServicePerPerson;
						vPricesRow.IsPricePerMinute = False;
						vPricesRow.IsPricePerDay = False;
						vPricesRow.Remarks = vRemarks;
					EndDo;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	Return vPrices;
EndFunction // cmGetResourcePrices

// -----------------------------------------------------------------------------
// Description: Returns value table with services that should be automatically 
//              charged for the given resource
// Parameters: Hotel, Date & time from, Date & time to, Client type, Resource type, 
//             Resource, Service package, Service packages value list
// Return value: Value table with services and prices
// -----------------------------------------------------------------------------
Procedure cmAddResourceReservationServicesDimensionsColumns(pServicesTab) Export
	pServicesTab.Columns.Add("Hotel", cmGetCatalogTypeDescription("Hotels"), "Hotel", 20);
	pServicesTab.Columns.Add("Agent", cmGetCatalogTypeDescription("Customers"), "Agent", 20);
	pServicesTab.Columns.Add("Customer", cmGetCatalogTypeDescription("Customers"), "Customer", 20);
	pServicesTab.Columns.Add("Contract", cmGetCatalogTypeDescription("Contracts"), "Contract", 20);
	pServicesTab.Columns.Add("GuestGroup", cmGetCatalogTypeDescription("GuestGroups"), "GuestGroup", 20);
	pServicesTab.Columns.Add("ClientType", cmGetCatalogTypeDescription("ClientTypes"), "Client type", 20);
	pServicesTab.Columns.Add("MarketingCode", cmGetCatalogTypeDescription("MarketingCodes"), "Marketing code", 20);
	pServicesTab.Columns.Add("SourceOfBusiness", cmGetCatalogTypeDescription("SourcesOfBusiness"), "Source of business", 20);
	pServicesTab.Columns.Add("PaymentMethod", cmGetCatalogTypeDescription("PaymentMethods"), "Payment method", 20);
	pServicesTab.Columns.Add("ExchangeRateDate", cmGetDateTypeDescription(), "Exchange rate date", 20);
	pServicesTab.Columns.Add("Folio", cmGetDocumentTypeDescription("Folio"), "Charging folio", 10);
	pServicesTab.Columns.Add("FolioCurrency", cmGetCatalogTypeDescription("Currencies"), "Folio currency", 10);
	pServicesTab.Columns.Add("FolioCurrencyExchangeRate", cmGetExchangeRateTypeDescription(), "Folio currency exchange rate", 20);
	pServicesTab.Columns.Add("ReportingCurrency", cmGetCatalogTypeDescription("Currencies"), "Reporting currency", 10);
	pServicesTab.Columns.Add("ReportingCurrencyExchangeRate", cmGetExchangeRateTypeDescription(), "Reporting currency exchange rate", 20);
	pServicesTab.Columns.Add("DiscountCard", cmGetCatalogTypeDescription("DiscountCards"), "Discount card", 20);
	pServicesTab.Columns.Add("HotelProduct", cmGetCatalogTypeDescription("HotelProducts"), "Hotel product", 20);
	pServicesTab.Columns.Add("ResourceType", cmGetCatalogTypeDescription("ResourceTypes"), "Resource type", 20);
	pServicesTab.Columns.Add("Resource", cmGetCatalogTypeDescription("Resources"), "Resource type", 20);
	pServicesTab.Columns.Add("ResourceRevenue", cmGetNumberTypeDescription(19, 7), "Resource revenue", 10);
	pServicesTab.Columns.Add("ResourceRevenueWithoutVAT", cmGetNumberTypeDescription(19, 7), "Resource revenue without VAT", 10);
	pServicesTab.Columns.Add("BoardPlace", cmGetCatalogTypeDescription("Resources"), "Board place", 20);
EndProcedure // cmAddResourceReservationServicesDimensionsColumns

// -----------------------------------------------------------------------------
// Description: Fills sales accummulation registers dimensions columns for the 
//              services value table row
// Parameters: Services valu table row, Resource reservation object, Client 
//             citizenship, Client region, Client city, Client age
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmFillResourceReservationServicesDimensionsColumns(pSrv, pObj) Export
	pSrv.Hotel = pObj.Hotel;
	pSrv.Agent = pObj.Agent;
	pSrv.Customer = pObj.Customer;
	pSrv.Contract = pObj.Contract;
	pSrv.GuestGroup = pObj.GuestGroup;
	pSrv.ClientType = pObj.ClientType;
	pSrv.MarketingCode = pObj.MarketingCode;
	pSrv.SourceOfBusiness = pObj.SourceOfBusiness;
	pSrv.ResourceType = pObj.ResourceType;
	pSrv.Resource = pObj.Resource;
	pSrv.EventActivity = ?(ValueIsFilled(pSrv.EventActivity), pSrv.EventActivity, pObj.EventActivity);
	pSrv.PaymentMethod = pObj.ChargingFolio.PaymentMethod;
	pSrv.ExchangeRateDate = pObj.ExchangeRateDate;
	pSrv.NumberOfPersons = pObj.NumberOfPersons;
	pSrv.FolioCurrencyExchangeRate = pObj.FolioCurrencyExchangeRate;
	pSrv.ReportingCurrency = pObj.ReportingCurrency;
	pSrv.ReportingCurrencyExchangeRate = pObj.ReportingCurrencyExchangeRate;
	pSrv.DiscountCard = pObj.DiscountCard;
	If pSrv.IsResourceRevenue Then
		pSrv.ResourceRevenue = pSrv.Sum - pSrv.DiscountSum;
		pSrv.ResourceRevenueWithoutVAT = pSrv.Sum - pSrv.DiscountSum - pSrv.VATSum;
	EndIf;
	If ValueIsFilled(pSrv.ServiceResource) And TypeOf(pSrv.ServiceResource) = Type("CatalogRef.Resources") And pSrv.ServiceResource.IsBoardPlace Then
		pSrv.BoardPlace = pSrv.ServiceResource;
	ElsIf ValueIsFilled(pSrv.Resource) And pSrv.Resource.IsBoardPlace Then
		pSrv.BoardPlace = pSrv.Resource;
	EndIf;
	pSrv.FolioCurrency = pObj.FolioCurrency;
EndProcedure // cmFillResourceReservationServicesDimensionsColumns

// -----------------------------------------------------------------------------
// Description: Calculates subtraction of two value table with services. 
// Parameters: First value table with services to subtract from, Secon value
//             table with services which is subtracted
// Return value: None
// -----------------------------------------------------------------------------
Function cmGetResourceReservationServicesDifference(pTabS, pTabC) Export
	// Create resulting value table
	vDiffTabS = pTabS.Copy();
	
	// Add services from second table with negative resources
	For Each vTabCRow In pTabC Do
		vTabSRow = vDiffTabS.Add();
		FillPropertyValues(vTabSRow, vTabCRow);
		vTabSRow.Quantity = -vTabCRow.Quantity;
		vTabSRow.Sum = -vTabCRow.Sum;
		vTabSRow.VATRate = vTabCRow.VATRate;
		vTabSRow.VATSum = -vTabCRow.VATSum;
		vTabSRow.HoursRented = -vTabCRow.HoursRented;
		vTabSRow.IsResourceRevenue = vTabCRow.IsResourceRevenue;
		vTabSRow.IsManual = vTabCRow.IsManual;
		vTabSRow.CommissionSum = -vTabCRow.CommissionSum;
		vTabSRow.VATCommissionSum = -vTabCRow.VATCommissionSum;
		vTabSRow.DiscountSum = -vTabCRow.DiscountSum;
		vTabSRow.VATDiscountSum = -vTabCRow.VATDiscountSum;
		vTabSRow.ResourceRevenue = -vTabCRow.ResourceRevenue;
		vTabSRow.ResourceRevenueWithoutVAT = -vTabCRow.ResourceRevenueWithoutVAT;
	EndDo;
	
	// Reset folio to empty value
	vDiffTabS.FillValues(Documents.Folio.EmptyRef(), "Folio");
	
	// Group by services
	vGroupByColumns = "Hotel, Company, Agent, Customer, Contract, GuestGroup, ClientType, " + 
	                  "MarketingCode, SourceOfBusiness, ResourceType, Resource, EventActivity, BoardPlace, PaymentMethod, ServiceResource, TimeFrom, TimeTo, " + 
	                  "AccountingDate, ExchangeRateDate, Service, CalendarDayType, Timetable, " +
	                  "Price, Unit, VATRate, Remarks, FolioCurrency, FolioCurrencyExchangeRate, Folio, " +
	                  "DiscountCard, DiscountType, DiscountConfirmationText, Discount, AgentCommission, AgentCommissionType, " +
	                  "ReportingCurrency, ReportingCurrencyExchangeRate, IsResourceRevenue, IsManual, LineNumber";
	vSumColumns = "Quantity, Sum, VATSum, HoursRented, CommissionSum, VATCommissionSum, DiscountSum, VATDiscountSum, ResourceRevenue, ResourceRevenueWithoutVAT"; 
	vDiffTabS.GroupBy(vGroupByColumns, vSumColumns);
	
	// Return result
	Return vDiffTabS;
EndFunction // cmGetResourceReservationServicesDifference

// -----------------------------------------------------------------------------
// Description: Checks if all service row resources are zero
// Parameters: Services value table row
// Return value: True if all resources are zero
// -----------------------------------------------------------------------------
Function cmResourceReservationServiceResourcesAreZero(pSrvRow) Export
	If pSrvRow.Quantity = 0 And
	   pSrvRow.Sum = 0 And
	   pSrvRow.VATSum = 0 And
	   pSrvRow.CommissionSum = 0 And
	   pSrvRow.VATCommissionSum = 0 And
	   pSrvRow.DiscountSum = 0 And
	   pSrvRow.VATDiscountSum = 0 And
	   pSrvRow.HoursRented = 0 And
	   pSrvRow.ResourceRevenue = 0 And
	   pSrvRow.ResourceRevenueWithoutVAT = 0 Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // cmResourceReservationServiceResourcesAreZero

// -----------------------------------------------------------------------------
// Description: Tries to find row in the given value table with 
//              columns equal to the data in the input services row
// Parameters: Services value table, Services value table row
// Return value: Services value table row if it was found, undefined otherwise
// -----------------------------------------------------------------------------
Function cmGetResourceReservationChargeRow(pTabC, pSrvRow) Export
	vRows = pTabC.FindRows(New Structure("AccountingDate", pSrvRow.AccountingDate));
	For Each vRow In vRows Do
		If pSrvRow.Service = vRow.Service And
		   pSrvRow.LineNumber = vRow.LineNumber And
		   pSrvRow.ServiceResource = vRow.ServiceResource And
		   pSrvRow.TimeFrom = vRow.TimeFrom And
		   pSrvRow.TimeTo = vRow.TimeTo And
		   TrimR(pSrvRow.Remarks) = TrimR(vRow.Remarks) And
		   pSrvRow.AgentCommission = vRow.AgentCommission And
		   pSrvRow.VATRate = vRow.VATRate And
		   pSrvRow.Price = vRow.Price And
		   pSrvRow.IsResourceRevenue = vRow.IsResourceRevenue And
		   pSrvRow.IsManual = vRow.IsManual Then
			Return vRow;
		EndIf;
	EndDo;
	Return Undefined;
EndFunction // cmGetResourceReservationChargeRow

// -----------------------------------------------------------------------------
// Description: Returns value table with folio balances for the given 
//              resource reservation documents value list
// Parameters: Resource reservation documents value list, Hotel
// Return value: Value table
// -----------------------------------------------------------------------------
Function cmGetResourceReservationListBalances(pDocList, pHotel) Export
	// Build and run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	FolioAccountsBalance.FolioCurrency AS FolioCurrency,
	|	FolioAccountsBalance.Folio.ParentDoc AS FolioParentDoc,
	|	SUM(FolioAccountsBalance.SumBalance) AS FolioSumBalance,
	|	-SUM(FolioAccountsBalance.LimitBalance) AS FolioLimitBalance
	|FROM
	|	AccumulationRegister.Accounts.Balance(
	|			&qBalancesPeriod,
	|				Folio.ParentDoc IN (&qDocList)) AS FolioAccountsBalance
	|
	|GROUP BY
	|	FolioAccountsBalance.FolioCurrency,
	|	FolioAccountsBalance.Folio.ParentDoc";
	vQry.SetParameter("qBalancesPeriod", ?(ValueIsFilled(pHotel), ?(pHotel.ShowDebtsOnCurrentDate, CurrentSessionDate(), '39991231235959'), '39991231235959'));
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	vQry.SetParameter("qDocList", pDocList);
	Return vQry.Execute().Unload();
EndFunction // cmGetResourceReservationListBalances

// -----------------------------------------------------------------------------
// Description: Returns value table with all resource reservation statuses
// Parameters: None
// Return value: Value table with resource reservation statuses 
// -----------------------------------------------------------------------------
Function cmGetAllResourceReservationStatuses() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ResourceReservationStatuses.Ref AS ResourceReservationStatus,
	|	ResourceReservationStatuses.Code AS Code,
	|	ResourceReservationStatuses.Description AS Description,
	|	ResourceReservationStatuses.SortCode AS SortCode,
	|	ResourceReservationStatuses.IsActive,
	|	ResourceReservationStatuses.IsGuaranteed,
	|	ResourceReservationStatuses.DoCharging,
	|	ResourceReservationStatuses.ServicesAreDelivered
	|FROM
	|	Catalog.ResourceReservationStatuses AS ResourceReservationStatuses
	|WHERE
	|	NOT ResourceReservationStatuses.DeletionMark
	|	AND NOT ResourceReservationStatuses.IsFolder
	|	AND (ResourceReservationStatuses.Hotel = &qHotel
	|			OR ResourceReservationStatuses.Hotel = &qEmptyHotel)
	|
	|ORDER BY
	|	SortCode";
	vQry.SetParameter("qHotel", SessionParameters.CurrentHotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vElements = vQry.Execute().Unload();
	Return vElements;
EndFunction // cmGetAllResourceReservationStatuses

// -----------------------------------------------------------------------------
// Description: Returns value table with all event activities
// Parameters: None
// Return value: Value table with event activities
// -----------------------------------------------------------------------------
Function cmGetAllEventActivities() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	EventActivities.Ref AS EventActivity,
	|	EventActivities.Code AS Code,
	|	EventActivities.Description AS Description,
	|	EventActivities.IsResourceBlock AS IsResourceBlock,
	|	EventActivities.ExternalCode AS ExternalCode
	|FROM
	|	Catalog.EventActivities AS EventActivities
	|WHERE
	|	NOT EventActivities.DeletionMark
	|
	|ORDER BY
	|	Description";
	vElements = vQry.Execute().Unload();
	Return vElements;
EndFunction // cmGetAllEventActivities

// -----------------------------------------------------------------------------
// Description: Returns services are delivered resource reservation statuses
// Parameters: Hotel reference
// Return value: Resource reservation status reference
// -----------------------------------------------------------------------------
Function cmGetDeliveredResourceReservationStatus(pHotel) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ResourceReservationStatuses.Ref AS ResourceReservationStatus
	|FROM
	|	Catalog.ResourceReservationStatuses AS ResourceReservationStatuses
	|WHERE
	|	NOT ResourceReservationStatuses.DeletionMark
	|	AND NOT ResourceReservationStatuses.IsFolder
	|	AND ResourceReservationStatuses.IsActive
	|	AND ResourceReservationStatuses.ServicesAreDelivered
	|	AND (ResourceReservationStatuses.Hotel = &qHotel
	|			OR ResourceReservationStatuses.Hotel = &qEmptyHotel)
	|
	|ORDER BY
	|	ResourceReservationStatuses.SortCode";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vElements = vQry.Execute().Unload();
	If vElements.Count() > 0 Then
		Return vElements.Get(0).ResourceReservationStatus;
	ElsIf ValueIsFilled(pHotel) Then
		Return pHotel.NewResourceReservationStatus;
	EndIf;
	Return Catalogs.ResourceReservationStatuses.EmptyRef();
EndFunction // cmGetDeliveredResourceReservationStatus 

// -----------------------------------------------------------------------------
// Description: Returns value table with all resources
// Parameters: Hotel, Resources folder where to search resources
// Return value: Value table with resources
// -----------------------------------------------------------------------------
Function cmGetAllResources(pHotel, pResourcesFolder = Undefined) Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT 
	|	Resources.Ref AS Resource
	|FROM
	|	Catalog.Resources AS Resources
	|WHERE
	|	(Resources.Hotel = &qHotel OR &qHotelIsEmpty) AND " + 
		?(ValueIsFilled(pResourcesFolder), "Resources.Ref IN HIERARCHY(&qResourcesFolder) AND ", "") + "
	|	Resources.DeletionMark = FALSE
	|ORDER BY Resources.SortCode";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(pHotel));
	vQry.SetParameter("qResourcesFolder", pResourcesFolder);
	vList = vQry.Execute().Unload();
	Return vList;
EndFunction // cmGetAllResources

// -----------------------------------------------------------------------------
// Description: Returns value list with all resources where "is board place" flag is switched on
// Parameters: Hotel, Resources folder where to search resources
// Return value: Value list with resources
// -----------------------------------------------------------------------------
Function cmGetBoardPlaces(pHotel, pResourcesFolder = Undefined) Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT 
	|	Resources.Ref AS Resource
	|FROM
	|	Catalog.Resources AS Resources
	|WHERE
	|	(Resources.Hotel = &qHotel OR Resources.Hotel = &qEmptyHotel OR &qHotelIsEmpty) AND
	|	Resources.IsBoardPlace AND " + 
		?(ValueIsFilled(pResourcesFolder), "Resources.Ref IN HIERARCHY(&qResourcesFolder) AND ", "") + "
	|	NOT Resources.DeletionMark
	|ORDER BY 
	|	Resources.SortCode, 
	|	Resources.Description";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(pHotel));
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qResourcesFolder", pResourcesFolder);
	vBoardPlaces = vQry.Execute().Unload();
	vList = New ValueList();
	For Each vBoardPlacesRow In vBoardPlaces Do
		vList.Add(vBoardPlacesRow.Resource);
	EndDo;
	Return vList;
EndFunction // cmGetBoardPlaces

// -----------------------------------------------------------------------------
// Description: Returns value table with all resources where "is board place" flag is switched on and 
//              door lock system additional authorization is set
// Parameters: Hotel item reference, Door lock system authorisation item reference
// Return value: Value table with resources
// -----------------------------------------------------------------------------
Function cmGetBoardPlacesByDoorLockSystemAuthorization(pHotel, pDoorLockSystemAuthorization) Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	Resources.Ref AS BoardPlace
	|FROM
	|	Catalog.Resources AS Resources
	|WHERE
	|	(Resources.Hotel = &qHotel
	|			OR Resources.Hotel = &qEmptyHotel)
	|	AND Resources.IsBoardPlace
	|	AND Resources.DoorLockSystemAuthorization = &qDoorLockSystemAuthorization
	|	AND NOT Resources.DeletionMark
	|
	|ORDER BY
	|	Resources.SortCode,
	|	Resources.Description";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qDoorLockSystemAuthorization", pDoorLockSystemAuthorization);
	vBoardPlaces = vQry.Execute().Unload();
	Return vBoardPlaces;
EndFunction // cmGetBoardPlacesByDoorLockSystemAuthorization

// -----------------------------------------------------------------------------
// Description: Returns service used quantity for given date and time period
// Parameters: Service item reference, Date, Time from, time to
// Return value: Number
// -----------------------------------------------------------------------------
Function cmGetServiceUsedQuantity(pService, pAccountingDate, pTimeFrom, pTimeTo, pDocumentToSkip = Undefined) Export
	vQ = 0;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SUM(SalesMovements.Quantity) AS Quantity
	|FROM
	|	AccumulationRegister.Sales AS SalesMovements
	|WHERE
	|	SalesMovements.Service = &qService
	|	AND (NOT &qDocumentIsFilled
	|			OR &qDocumentIsFilled
	|				AND SalesMovements.ParentDoc <> &qDocument)
	|	AND (NOT &qDocumentIsFilled
	|			OR &qDocumentIsFilled
	|				AND SalesMovements.Recorder <> &qDocument)
	|	AND SalesMovements.AccountingDate = &qDate
	|	AND (SalesMovements.TimeFrom = &qEmptyDate
	|				AND SalesMovements.TimeTo = &qEmptyDate
	|			OR &qTimeFrom = &qEmptyDate
	|				AND &qTimeTo = &qEmptyDate
	|			OR SalesMovements.TimeFrom < SalesMovements.TimeTo
	|				AND &qTimeFrom < &qTimeTo
	|				AND SalesMovements.TimeFrom < &qTimeTo
	|				AND SalesMovements.TimeTo > &qTimeFrom
	|			OR SalesMovements.TimeFrom >= SalesMovements.TimeTo
	|				AND &qTimeFrom < &qTimeTo
	|				AND &qTimeTo > SalesMovements.TimeFrom
	|			OR SalesMovements.TimeFrom < SalesMovements.TimeTo
	|				AND &qTimeFrom >= &qTimeTo
	|				AND SalesMovements.TimeTo > &qTimeFrom
	|			OR SalesMovements.TimeFrom >= SalesMovements.TimeTo
	|				AND &qTimeFrom >= &qTimeTo
	|				AND &qTimeTo > SalesMovements.TimeFrom
	|			OR SalesMovements.TimeFrom >= SalesMovements.TimeTo
	|				AND &qTimeFrom >= &qTimeTo
	|				AND &qTimeFrom < SalesMovements.TimeTo)
	|
	|UNION ALL
	|
	|SELECT
	|	SUM(SalesForecastMovements.Quantity)
	|FROM
	|	AccumulationRegister.SalesForecast AS SalesForecastMovements
	|WHERE
	|	SalesForecastMovements.Service = &qService
	|	AND (NOT &qDocumentIsFilled
	|			OR &qDocumentIsFilled
	|				AND SalesForecastMovements.Recorder <> &qDocument)
	|	AND SalesForecastMovements.AccountingDate = &qDate
	|	AND (SalesForecastMovements.TimeFrom = &qEmptyDate
	|				AND SalesForecastMovements.TimeTo = &qEmptyDate
	|			OR &qTimeFrom = &qEmptyDate
	|				AND &qTimeTo = &qEmptyDate
	|			OR SalesForecastMovements.TimeFrom < SalesForecastMovements.TimeTo
	|				AND &qTimeFrom < &qTimeTo
	|				AND SalesForecastMovements.TimeFrom < &qTimeTo
	|				AND SalesForecastMovements.TimeTo > &qTimeFrom
	|			OR SalesForecastMovements.TimeFrom >= SalesForecastMovements.TimeTo
	|				AND &qTimeFrom < &qTimeTo
	|				AND &qTimeTo > SalesForecastMovements.TimeFrom
	|			OR SalesForecastMovements.TimeFrom < SalesForecastMovements.TimeTo
	|				AND &qTimeFrom >= &qTimeTo
	|				AND SalesForecastMovements.TimeTo > &qTimeFrom
	|			OR SalesForecastMovements.TimeFrom >= SalesForecastMovements.TimeTo
	|				AND &qTimeFrom >= &qTimeTo
	|				AND &qTimeTo > SalesForecastMovements.TimeFrom
	|			OR SalesForecastMovements.TimeFrom >= SalesForecastMovements.TimeTo
	|				AND &qTimeFrom >= &qTimeTo
	|				AND &qTimeFrom < SalesForecastMovements.TimeTo)";
	vQry.SetParameter("qService", pService);
	vQry.SetParameter("qDate", pAccountingDate);
	vQry.SetParameter("qTimeFrom", pTimeFrom);
	vQry.SetParameter("qTimeTo", pTimeTo);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qDocument", pDocumentToSkip);
	vQry.SetParameter("qDocumentIsFilled", ValueIsFilled(pDocumentToSkip));
	vQryRes = vQry.Execute().Unload();
	For Each vQryResRow In vQryRes Do
		If vQryResRow.Quantity <> Null Then
			vQ = vQ + vQryResRow.Quantity;
		EndIf;
	EndDo;
	Return vQ;
EndFunction // cmGetServiceUsedQuantity

// -----------------------------------------------------------------------------
// Description: Returns service used quantity for given date and time period
// Parameters: Service item reference, Date, Time from, time to
// Return value: Number
// -----------------------------------------------------------------------------
Function cmServicesAvailableQuantity(pServicesList, pHotel, pAccountingDate, pTimeFrom, pTimeTo, pDocumentToSkip = Undefined) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Services.Ref AS Service,
	|	Services.AvailableQuantity - ISNULL(ServicesUsedTotals.Quantity, 0) AS AvailableQuantity
	|FROM
	|	Catalog.Services AS Services
	|		LEFT JOIN (SELECT
	|			UsedServices.Service AS Service,
	|			SUM(UsedServices.Quantity) AS Quantity
	|		FROM
	|			(SELECT
	|				SalesMovements.Service AS Service,
	|				SUM(SalesMovements.Quantity) AS Quantity
	|			FROM
	|				AccumulationRegister.Sales AS SalesMovements
	|			WHERE
	|				SalesMovements.Service IN(&qServicesList)
	|				AND SalesMovements.Service.AvailableQuantity > 0
	|				AND NOT SalesMovements.Service.DeletionMark
	|				AND NOT SalesMovements.Service.IsFolder
	|				AND (SalesMovements.Service.Hotel = &qHotel
	|						OR SalesMovements.Service.Hotel = &qEmptyHotel)
	|				AND (NOT &qDocumentIsFilled
	|						OR &qDocumentIsFilled
	|							AND SalesMovements.ParentDoc <> &qDocument)
	|				AND (NOT &qDocumentIsFilled
	|						OR &qDocumentIsFilled
	|							AND SalesMovements.Recorder <> &qDocument)
	|				AND SalesMovements.AccountingDate = &qDate
	|				AND (SalesMovements.TimeFrom = &qEmptyDate
	|							AND SalesMovements.TimeTo = &qEmptyDate
	|						OR &qTimeFrom = &qEmptyDate
	|							AND &qTimeTo = &qEmptyDate
	|						OR SalesMovements.TimeFrom < SalesMovements.TimeTo
	|							AND &qTimeFrom < &qTimeTo
	|							AND SalesMovements.TimeFrom < &qTimeTo
	|							AND SalesMovements.TimeTo > &qTimeFrom
	|						OR SalesMovements.TimeFrom >= SalesMovements.TimeTo
	|							AND &qTimeFrom < &qTimeTo
	|							AND &qTimeTo > SalesMovements.TimeFrom
	|						OR SalesMovements.TimeFrom < SalesMovements.TimeTo
	|							AND &qTimeFrom >= &qTimeTo
	|							AND SalesMovements.TimeTo > &qTimeFrom
	|						OR SalesMovements.TimeFrom >= SalesMovements.TimeTo
	|							AND &qTimeFrom >= &qTimeTo
	|							AND &qTimeTo > SalesMovements.TimeFrom
	|						OR SalesMovements.TimeFrom >= SalesMovements.TimeTo
	|							AND &qTimeFrom >= &qTimeTo
	|							AND &qTimeFrom < SalesMovements.TimeTo)
	|			
	|			GROUP BY
	|				SalesMovements.Service
	|			
	|			UNION ALL
	|			
	|			SELECT
	|				SalesForecastMovements.Service,
	|				SUM(SalesForecastMovements.Quantity)
	|			FROM
	|				AccumulationRegister.SalesForecast AS SalesForecastMovements
	|			WHERE
	|				SalesForecastMovements.Service IN(&qServicesList)
	|				AND SalesForecastMovements.Service.AvailableQuantity > 0
	|				AND NOT SalesForecastMovements.Service.DeletionMark
	|				AND NOT SalesForecastMovements.Service.IsFolder
	|				AND (SalesForecastMovements.Service.Hotel = &qHotel
	|						OR SalesForecastMovements.Service.Hotel = &qEmptyHotel)
	|				AND (NOT &qDocumentIsFilled
	|						OR &qDocumentIsFilled
	|							AND SalesForecastMovements.Recorder <> &qDocument)
	|				AND SalesForecastMovements.AccountingDate = &qDate
	|				AND (SalesForecastMovements.TimeFrom = &qEmptyDate
	|							AND SalesForecastMovements.TimeTo = &qEmptyDate
	|						OR &qTimeFrom = &qEmptyDate
	|							AND &qTimeTo = &qEmptyDate
	|						OR SalesForecastMovements.TimeFrom < SalesForecastMovements.TimeTo
	|							AND &qTimeFrom < &qTimeTo
	|							AND SalesForecastMovements.TimeFrom < &qTimeTo
	|							AND SalesForecastMovements.TimeTo > &qTimeFrom
	|						OR SalesForecastMovements.TimeFrom >= SalesForecastMovements.TimeTo
	|							AND &qTimeFrom < &qTimeTo
	|							AND &qTimeTo > SalesForecastMovements.TimeFrom
	|						OR SalesForecastMovements.TimeFrom < SalesForecastMovements.TimeTo
	|							AND &qTimeFrom >= &qTimeTo
	|							AND SalesForecastMovements.TimeTo > &qTimeFrom
	|						OR SalesForecastMovements.TimeFrom >= SalesForecastMovements.TimeTo
	|							AND &qTimeFrom >= &qTimeTo
	|							AND &qTimeTo > SalesForecastMovements.TimeFrom
	|						OR SalesForecastMovements.TimeFrom >= SalesForecastMovements.TimeTo
	|							AND &qTimeFrom >= &qTimeTo
	|							AND &qTimeFrom < SalesForecastMovements.TimeTo)
	|			
	|			GROUP BY
	|				SalesForecastMovements.Service) AS UsedServices
	|		
	|		GROUP BY
	|			UsedServices.Service) AS ServicesUsedTotals
	|		ON Services.Ref = ServicesUsedTotals.Service
	|WHERE
	|	Services.Ref IN(&qServicesList)
	|	AND Services.AvailableQuantity > 0
	|	AND NOT Services.DeletionMark
	|	AND NOT Services.IsFolder
	|	AND (Services.Hotel = &qHotel
	|			OR Services.Hotel = &qEmptyHotel)";
	vQry.SetParameter("qServicesList", pServicesList);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qDate", pAccountingDate);
	vQry.SetParameter("qTimeFrom", pTimeFrom);
	vQry.SetParameter("qTimeTo", pTimeTo);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qDocument", pDocumentToSkip);
	vQry.SetParameter("qDocumentIsFilled", ValueIsFilled(pDocumentToSkip));
	vQryRes = vQry.Execute().Unload();
	Return vQryRes;
EndFunction // cmServicesAvailableQuantity

// -----------------------------------------------------------------------------
// Description: Returns service used quantity for given date and time period
// Parameters: Service item reference, Date, Time from, time to
// Return value: Number
// -----------------------------------------------------------------------------
Function cmServicesAvailableQuantityByDays(pServicesList, pHotel, pPeriodFrom, pPeriodTo, pDocumentToSkip = Undefined) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Services.Ref AS Service,
	|	AllDates.AccountingDate AS AccountingDate,
	|	Services.AvailableQuantity - ISNULL(ServicesUsedTotals.Quantity, 0) AS AvailableQuantity
	|FROM
	|	Catalog.Services AS Services
	|		LEFT JOIN (SELECT
	|			HotelDates.Period AS AccountingDate,
	|			HotelDates.CounterClosingBalance AS CounterClosingBalance
	|		FROM
	|			AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, Day, RegisterRecordsAndPeriodBoundaries, Hotel = &qHotel) AS HotelDates) AS AllDates
	|		ON (TRUE)
	|		LEFT JOIN (SELECT
	|			UsedServices.AccountingDate AS AccountingDate,
	|			UsedServices.Service AS Service,
	|			SUM(UsedServices.Quantity) AS Quantity
	|		FROM
	|			(SELECT
	|				SalesMovements.AccountingDate AS AccountingDate,
	|				SalesMovements.Service AS Service,
	|				SUM(SalesMovements.Quantity) AS Quantity
	|			FROM
	|				AccumulationRegister.Sales AS SalesMovements
	|			WHERE
	|				SalesMovements.Service IN(&qServicesList)
	|				AND SalesMovements.Service.AvailableQuantity > 0
	|				AND NOT SalesMovements.Service.DeletionMark
	|				AND NOT SalesMovements.Service.IsFolder
	|				AND (SalesMovements.Service.Hotel = &qHotel
	|						OR SalesMovements.Service.Hotel = &qEmptyHotel)
	|				AND (NOT &qDocumentIsFilled
	|						OR &qDocumentIsFilled
	|							AND SalesMovements.ParentDoc <> &qDocument)
	|				AND (NOT &qDocumentIsFilled
	|						OR &qDocumentIsFilled
	|							AND SalesMovements.Recorder <> &qDocument)
	|				AND SalesMovements.AccountingDate >= &qPeriodFrom
	|				AND SalesMovements.AccountingDate <= &qPeriodTo
	|			
	|			GROUP BY
	|				SalesMovements.AccountingDate,
	|				SalesMovements.Service
	|			
	|			UNION ALL
	|			
	|			SELECT
	|				SalesForecastMovements.AccountingDate,
	|				SalesForecastMovements.Service,
	|				SUM(SalesForecastMovements.Quantity)
	|			FROM
	|				AccumulationRegister.SalesForecast AS SalesForecastMovements
	|			WHERE
	|				SalesForecastMovements.Service IN(&qServicesList)
	|				AND SalesForecastMovements.Service.AvailableQuantity > 0
	|				AND NOT SalesForecastMovements.Service.DeletionMark
	|				AND NOT SalesForecastMovements.Service.IsFolder
	|				AND (SalesForecastMovements.Service.Hotel = &qHotel
	|						OR SalesForecastMovements.Service.Hotel = &qEmptyHotel)
	|				AND (NOT &qDocumentIsFilled
	|						OR &qDocumentIsFilled
	|							AND SalesForecastMovements.Recorder <> &qDocument)
	|				AND SalesForecastMovements.AccountingDate >= &qPeriodFrom
	|				AND SalesForecastMovements.AccountingDate <= &qPeriodTo
	|			
	|			GROUP BY
	|				SalesForecastMovements.AccountingDate,
	|				SalesForecastMovements.Service) AS UsedServices
	|		
	|		GROUP BY
	|			UsedServices.AccountingDate,
	|			UsedServices.Service) AS ServicesUsedTotals
	|		ON Services.Ref = ServicesUsedTotals.Service
	|			AND (AllDates.AccountingDate = ServicesUsedTotals.AccountingDate)
	|WHERE
	|	Services.Ref IN(&qServicesList)
	|	AND Services.AvailableQuantity > 0
	|	AND NOT Services.DeletionMark
	|	AND NOT Services.IsFolder
	|	AND (Services.Hotel = &qHotel
	|			OR Services.Hotel = &qEmptyHotel)";
	vQry.SetParameter("qServicesList", pServicesList);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qPeriodFrom", BegOfDay(pPeriodFrom));
	vQry.SetParameter("qPeriodTo", BegOfDay(pPeriodTo));
	vQry.SetParameter("qDocument", pDocumentToSkip);
	vQry.SetParameter("qDocumentIsFilled", ValueIsFilled(pDocumentToSkip));
	vQryRes = vQry.Execute().Unload();
	Return vQryRes;
EndFunction // cmServicesAvailableQuantityByDays

#EndRegion
