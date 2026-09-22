
#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	vRef = Data.Ref;
	If ValueIsFilled(vRef) Then
		Presentation = "№" + TrimAll(Data.Number) + 
		               NStr("en = ' Resource res.'; ru = ' Бронь ресурса'; de = ' Ressource res.'") + 
		               ?(ValueIsFilled(vRef.Customer), " " + Trimall(vRef.Customer), "") + 
		               ?(ValueIsFilled(vRef.Client), " " + Trimall(vRef.Client.FullName), "") + 
					   NStr("en = ' from '; ru = ' c '; de = ' ab '") + Format(vRef.DateTimeFrom, "DF=dd.MM.yyyy HH:mm") + 
					   ?(ValueIsFilled(vRef.Resource), " " + TrimAll(vRef.Resource), "");
		StandardProcessing = False;
	EndIf;
EndProcedure // PresentationGetProcessing

// --------------------------------------------------------------------------------
Procedure FormGetProcessing(pFormType, pParameters, pSelectedForm, pAdditionalInformation, pStandardProcessing)
	SetPrivilegedMode(True);
	vCurSession = GetCurrentInfoBaseSession();
	SetPrivilegedMode(False);
	vSessionNumber = vCurSession.SessionNumber;
	vSessionStartTime = vCurSession.SessionStarted;
	vAppRunMode = CachedCommonFunctions.cmGetAppRunMode(vSessionNumber, vSessionStartTime);
	If vAppRunMode.MobileDeviceMode Then 
		If pFormType = "ObjectForm" Or pSelectedForm = "tcDocumentForm" Then
			pStandardProcessing = False;
			pSelectedForm = "mcDocumentForm";
		ElsIf pFormType = "ListForm" Or pSelectedForm = "tcReservationListForm" Then
			pStandardProcessing = False;
			pSelectedForm = "mcReservationListForm";
		EndIf; 
	EndIf;
EndProcedure // FormGetProcessing

#EndRegion

#Region Public

// --------------------------------------------------------------------------------
Procedure PrintConfirmationList(pConfirmationSpreadsheet, SelReservationArray, SelReservations, SelDateFrom, SelDateTo, SelCurrency, SelByDays, SelShortView, SelShowTasks, SelHideTotals, SelDoNotJoinServices, SelLanguage, SelObjectPrintForm, rDoPrint = Undefined, SelShowArrangement = False) Export
	If Not ValueIsFilled(SelLanguage) Then
		SelLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	
	// Fill and check grouping parameter
	vParameter = UPPER(TrimAll(SelObjectPrintForm.Parameter));
	
	// Choose template
	vSpreadsheet = pConfirmationSpreadsheet;
	vSpreadsheet.Clear();
	vTemplateName = "ResourceReservationConfirmationRu";
	If ValueIsFilled(SelLanguage) Then
		If SelLanguage = Catalogs.Languages.EN Then
			vTemplateName = "ResourceReservationConfirmationEn";
		ElsIf SelLanguage = Catalogs.Languages.DE Then
			vTemplateName = "ResourceReservationConfirmationDe";
		ElsIf SelLanguage = Catalogs.Languages.RU Then
			vTemplateName = "ResourceReservationConfirmationRu";
		Else
			tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Не найден шаблон печатной формы подтверждения бронирования ресурса для языка " + SelLanguage.Code + "!'; 
			             |de='Keine Ressource Reservierungsbestätigung druckformularvorlage gefunden für die " + SelLanguage.Code + " sprache!';
			             |en='No resource reservation confirmation print form template found for the " + SelLanguage.Code + " language!'"));
			Return;
		EndIf;
	EndIf;
	If SelShortView Then
		vTemplateName = "Short" + vTemplateName;
	EndIf;
	vTemplate = Documents.ResourceReservation.GetTemplate(vTemplateName);
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(SelObjectPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;

	For Each vSelReservation In SelReservationArray Do
		If SelReservationArray.IndexOf(vSelReservation) > 0 Then
			vSpreadsheet.PutHorizontalPageBreak();
		EndIf;
		
		SelReservation = vSelReservation.Value; 
		// Hotel object
		vHotel = SelReservation.Hotel;
		// Load pictures
		vLogoIsSet = False;
		vLogo = New Picture;
		If ValueIsFilled(SelReservation.Hotel) Then
			If SelReservation.Hotel.Logo <> Undefined Then
				vLogo = SelReservation.Hotel.Logo.Get();
				If vLogo = Undefined Then
					vLogo = New Picture;
				Else
					vLogoIsSet = True;
				EndIf;
			EndIf;
		EndIf;
		
		// Print event header
		PrintEventHeader(vSpreadsheet, vTemplate, vLogo, vLogoIsSet, vHotel, SelReservation, SelLanguage, vParameter);
		
		// Table rows
		vDayArea = vTemplate.GetArea("Day");
		vResourceArea = vTemplate.GetArea("Resource");
		vResourceRemarksArea = vTemplate.GetArea("ResourceRemarks");
		vActivitiesHeaderArea = vTemplate.GetArea("DayScheduleHeader");
		vActivityArea = vTemplate.GetArea("DayEvent");
		vTableHeaderArea = vTemplate.GetArea("TableHeader");
		vServiceTypeArea = vTemplate.GetArea("ServiceType");
		vServiceTypeTotalsArea = vTemplate.GetArea("ServiceTypeTotals");
		vServiceTypeTotalsPerDayArea = vTemplate.GetArea("ServiceTypeTotalsPerDay");
		vServiceArea = vTemplate.GetArea("Service");
		If Not SelShortView Then
			vServiceRemarksArea = vTemplate.GetArea("ServiceRemarks");
			vServiceItemsArea = vTemplate.GetArea("ServiceItem");
		EndIf;
		vTableFooterPerDayHeader = vTemplate.GetArea("TableFooterPerDayHeader");
		vTableFooterPerDay = vTemplate.GetArea("TableFooterPerDay");
		vTableFooterHeader = vTemplate.GetArea("TableFooterHeader");
		vTableFooter = vTemplate.GetArea("TableFooter");
		vEmptyRow = vTemplate.GetArea("EmptyRow");
		
		// Build map of service items tabular parts
		vSIMap = New Map();
		
		// Build table of all guest group services
		vServices = Undefined;
		vReservations = SelReservation.GuestGroup.GetObject().pmGetResourceReservations();
		For Each vRes In vReservations Do
			If ValueIsFilled(vRes.Status) And vRes.Status.IsActive Then
				vCurRes = vRes.Reservation;
				If vSIMap.Get(vCurRes) = Undefined Then
					vSIMap.Insert(vCurRes, vCurRes.ServiceItems.Unload());
				EndIf;
				If vServices = Undefined Then
					vServices = vCurRes.Services.Unload();
					vServices.Clear();
					vServices.Columns.Add("ResourceType");
					vServices.Columns.Add("ResourceTypeSortCode");
					vServices.Columns.Add("Resource");
					vServices.Columns.Add("ResourceSortCode");
					vServices.Columns.Add("ResourceReservation");
					vServices.Columns.Add("ResourceReservationPointInTime");
					vServices.Columns.Add("ServiceType");
					vServices.Columns.Add("ServiceTypeSortCode");
				EndIf;
				For Each vResSrvRow In vCurRes.Services Do
					vSrvRow = vServices.Add();
					FillPropertyValues(vSrvRow, vCurRes);
					FillPropertyValues(vSrvRow, vResSrvRow);
					If ValueIsFilled(vSrvRow.Service) Then
						vSrvRow.ServiceType = vSrvRow.Service.ServiceType;
					EndIf;
					If ValueIsFilled(vSrvRow.ServiceType) Then
						vSrvRow.ServiceTypeSortCode = vSrvRow.ServiceType.SortCode;
					Else
						vSrvRow.ServiceTypeSortCode = 999999999;
					EndIf;
					If Not ValueIsFilled(vSrvRow.ServiceResource) Then
						vSrvRow.ServiceResource = vCurRes.Resource;
					EndIf;
					If Not ValueIsFilled(vSrvRow.TimeFrom) And Not ValueIsFilled(vSrvRow.TimeTo) Then
						vSrvRow.DateTimeFrom = vCurRes.DateTimeFrom;
						vSrvRow.TimeFrom = vSrvRow.DateTimeFrom;
						vSrvRow.DateTimeTo = vCurRes.DateTimeTo;
						vSrvRow.TimeTo = vSrvRow.DateTimeTo;
					EndIf;
					If ValueIsFilled(vSrvRow.ResourceType) Then
						vSrvRow.ResourceTypeSortCode = vSrvRow.ResourceType.SortCode;
					Else
						vSrvRow.ResourceTypeSortCode = 999999999;
					EndIf;
					If ValueIsFilled(vSrvRow.Resource) Then
						vSrvRow.ResourceSortCode = vSrvRow.Resource.SortCode;
					Else
						vSrvRow.ResourceSortCode = 999999999;
					EndIf;
					vSrvRow.ResourceReservation = vCurRes;
					vSrvRow.ResourceReservationPointInTime = vCurRes.PointInTime();
					If Not ValueIsFilled(vSrvRow.TimeFrom) And Not ValueIsFilled(vSrvRow.TimeTo) Then
						If ValueIsFilled(vCurRes.DateTimeFrom) And ValueIsFilled(vSrvRow.AccountingDate) Then
							vSrvRow.TimeFrom = vCurRes.DateTimeFrom;
							vSrvRow.DateTimeFrom = vSrvRow.AccountingDate + (vSrvRow.TimeFrom - BegOfDay(vSrvRow.TimeFrom));
							vSrvRow.TimeTo = vCurRes.DateTimeTo;
							vSrvRow.DateTimeTo = vSrvRow.AccountingDate + (vSrvRow.TimeTo - BegOfDay(vSrvRow.TimeTo));
							If vSrvRow.TimeFrom >= vSrvRow.TimeTo Then
								vSrvRow.DateTimeTo = vSrvRow.DateTimeTo + (24*3600);
							EndIf;
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
		If vServices = Undefined Then
			vServices = vCurRes.Services.Unload();
			vServices.Clear();
			vServices.Columns.Add("ResourceType");
			vServices.Columns.Add("ResourceTypeSortCode");
			vServices.Columns.Add("Resource");
			vServices.Columns.Add("ResourceSortCode");
			vServices.Columns.Add("ResourceReservation");
			vServices.Columns.Add("ResourceReservationPointInTime");
			vServices.Columns.Add("ServiceType");
			vServices.Columns.Add("ServiceTypeSortCode");
		Else
			vServices.Sort("AccountingDate, ResourceTypeSortCode, ResourceSortCode, ResourceReservationPointInTime, IsResourceRevenue DESC, ServiceTypeSortCode, DateTimeFrom, TimeFrom");
		EndIf;
		// Hide some services to the other ones
		vDoGroupBy = False;
		If Not SelDoNotJoinServices Then
			// Try to replace accommodation service to the one that should be used for printing
			For Each vSrvRow In vServices Do
				vSrvRowService = vSrvRow.Service;
				If ValueIsFilled(vSrvRowService) And ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
					If vSrvRowService.DoNotGroupIntoRoomRateOnPrint Then
						vSrvRow.Service = vSrvRowService.HideIntoServiceOnPrint;
					EndIf;
				EndIf;
			EndDo;
			// Try to merge other services to the accommodation service
			For Each vSrvRow In vServices Do
				vSrvRowService = vSrvRow.Service;
				If ValueIsFilled(vSrvRowService) And ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
					If Not vSrvRowService.DoNotGroupIntoRoomRateOnPrint Then
						// Try to find row with service to join to
						vJoinToServices = vServices.FindRows(New Structure("Service, AccountingDate", vSrvRowService.HideIntoServiceOnPrint, vSrvRow.AccountingDate));
						If vJoinToServices.Count() > 0 Then
							vDoGroupBy = True;
							
							vOldServiceId = vSrvRow.ServiceId;
							vOldServiceRemarks = TrimAll(vSrvRow.Remarks);
							
							vJoinToSrvRow = vJoinToServices.Get(0);
							FillPropertyValues(vSrvRow, vJoinToSrvRow, , "LineNumber, Sum, VATSum, Quantity, Price, BaseCurrencyPrice,
							                                             |DiscountSum, VATDiscountSum, CommissionSum, VATCommissionSum, HoursRented");
							vSrvRow.Quantity = 0;
							vSrvRow.Price = 0;
							
							// Replace old service id by new one in the service items
							vSITable = vSIMap.Get(vSrvRow.ResourceReservation);
							For Each vSITableRow In vSITable Do
								If vSITableRow.ServiceId = vOldServiceId Then
									vSITableRow.ServiceId = vSrvRow.ServiceId;
								EndIf;
							EndDo;
							vSIMap.Insert(vSrvRow.ResourceReservation, vSITable);
							
							// Join remarks
							vSrvRow.Remarks = TrimAll(vSrvRow.Remarks) + Chars.LF + vOldServiceRemarks;
							vJoinToSrvRow.Remarks = vSrvRow.Remarks;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		If vDoGroupBy And vServices.Count() > 0 Then
			vServices.GroupBy("AccountingDate, CalendarDayType, Company, DateTimeFrom, DateTimeTo, 
			                  |Discount, DiscountType, DiscountConfirmationText, DiscountServiceGroup, 
							  |IsManual, IsManualPrice, IsResourceRevenue, Remarks,
							  |EventActivity, ActivityRemarks, NumberOfPersons,
							  |Resource, ResourceReservation, ResourceReservationPointInTime, ResourceSortCode, 
							  |ResourceTableConfiguration, ResourceType, ResourceTypeSortCode, 
							  |Service, ServiceId, ServiceItem, ServiceResource, ServiceType, ServiceTypeSortCode, 
							  |TimeFrom, TimeTo, Timetable, Unit, VATRate", 
							  "Sum, VATSum, Quantity, Price, BaseCurrencyPrice, 
							  |DiscountSum, VATDiscountSum, CommissionSum, VATCommissionSum, 
							  |HoursRented");
		EndIf;
		
		// Recalculate all amounts to the printing form currency
		For Each vSrvRow In vServices Do
			vSrvRow.Sum = vSrvRow.Sum - vSrvRow.DiscountSum;
			vSrvRow.VATSum = vSrvRow.VATSum - vSrvRow.VATDiscountSum;
			vSrvRow.Price = cmRecalculatePrice(vSrvRow.Sum, vSrvRow.Quantity);
			
			vFolioCurrency = vSrvRow.ResourceReservation.FolioCurrency;
			vFolioCurrencyExchangeRate = vSrvRow.ResourceReservation.FolioCurrencyExchangeRate;
			If ValueIsFilled(SelCurrency) And SelCurrency <> vFolioCurrency Then
				If SelCurrency = vHotel.BaseCurrency And vSrvRow.BaseCurrencyPrice <> 0 Then
					vSrvRow.Price = vSrvRow.BaseCurrencyPrice;
					vSrvRow.Sum = Round(vSrvRow.Price * vSrvRow.Quantity, 2);
				Else
					vSrvRow.Sum = Round(cmConvertCurrencies(vSrvRow.Sum, vFolioCurrency, vFolioCurrencyExchangeRate, SelCurrency, 0, CurrentSessionDate(), vHotel), 2);
					vSrvRow.Price = Round(vSrvRow.Sum / ?(vSrvRow.Quantity = 0, 1, vSrvRow.Quantity), 2);
				EndIf;
				cmPriceOnChange(vSrvRow.Price, vSrvRow.Quantity, vSrvRow.Sum, vSrvRow.VATRate, vSrvRow.VATSum, vSrvRow.AccountingDate);
			EndIf;
		EndDo;
		
		// Print services
		vTotalSum = 0;
		vTotalVATSum = 0;
		
		// Initialize grouping parameters
		vDayNumber = 0;
		vCurAccountingDate = Undefined;
		vFirstAccountingDate = Undefined;
		vCurResourceReservation = Undefined;
		vPrintTableHeader = True;
		vCurServiceType = Undefined;
		
		// Group services by accounting date, resource
		vConditions = vServices.Copy();
		vConditions.GroupBy("AccountingDate, ResourceType, ResourceTypeSortCode, Resource, ResourceSortCode, ResourceReservation, ResourceReservationPointInTime", );
		If Find(vParameter, "DO_NOT_GROUP_BY_RESOURCE_TYPE") > 0 Then
			vConditions.Sort("AccountingDate, ResourceSortCode, ResourceReservationPointInTime");
		Else
			vConditions.Sort("AccountingDate, ResourceTypeSortCode, ResourceSortCode, ResourceReservationPointInTime");
		EndIf;
		For Each vConditionsRow In vConditions Do
			// Select services for the each condition
			vRowsArray = vServices.FindRows(New Structure("AccountingDate, ResourceType, Resource, ResourceReservation", 
			                                vConditionsRow.AccountingDate,
			                                vConditionsRow.ResourceType,  
			                                vConditionsRow.Resource, 
			                                vConditionsRow.ResourceReservation));
			vCndServices = vServices.CopyColumns();
			For Each vRowElement In vRowsArray Do
				vCndServicesRow = vCndServices.Add();
				FillPropertyValues(vCndServicesRow, vRowElement);
			EndDo;
			
			vFolioCurrency = vConditionsRow.ResourceReservation.FolioCurrency;
			vFolioCurrencyExchangeRate = vConditionsRow.ResourceReservation.FolioCurrencyExchangeRate;
		
			// Print day header
			vDayHeaderWasPrinted = False;
			If vCurAccountingDate <> vConditionsRow.AccountingDate Then
				vPrintTableHeader = True;
				vCurServiceType = Undefined;
				vTotalSumPerDay = 0;
				
				// Print event header
				If ValueIsFilled(vFirstAccountingDate) Then
					// Print previous day totals
					vDayServices = vServices.Copy();
					i = 0;
					While i < vDayServices.Count() Do
						vDaySrvRow = vDayServices.Get(i);
						If vDaySrvRow.AccountingDate <> vCurAccountingDate Then
							vDayServices.Delete(i);
						Else
							i = i + 1;
						EndIf;
					EndDo;
					vDayServices.GroupBy("ServiceType, ServiceTypeSortCode", "Sum");
					vDayServices.Sort("ServiceTypeSortCode");
					If Not ValueIsFilled(SelDateFrom) And Not ValueIsFilled(SelDateTo) Or BegOfDay(SelDateTo) > BegOfDay(SelDateFrom) Then
						If Not SelHideTotals Then   
							If vDayServices.Count() > 0 Then
								vSpreadsheet.Put(vTableFooterPerDayHeader);
								For Each vSrvTypeRow In vDayServices Do
									If ValueIsFilled(vSrvTypeRow.ServiceType) Then
										vServiceTypeTotalsPerDayArea.Parameters.mServiceType = vSrvTypeRow.ServiceType.GetObject().pmGetServiceTypeDescription(SelLanguage);
									Else
										vServiceTypeTotalsPerDayArea.Parameters.mServiceType = cmNStr("en='<Other>';ru='<Прочее>';de='<Andere>'", SelLanguage);
									EndIf;
									vServiceTypeTotalsPerDayArea.Parameters.mServiceTypeSum = cmFormatSum(vSrvTypeRow.Sum, ?(ValueIsFilled(SelCurrency), SelCurrency, SelReservation.FolioCurrency), , SelLanguage);
									vSpreadsheet.Put(vServiceTypeTotalsPerDayArea);
									vTotalSumPerDay = vTotalSumPerDay + vSrvTypeRow.Sum;
								EndDo;
								vTableFooterPerDay.Parameters.mTotalSumPerDay = cmFormatSum(vTotalSumPerDay, ?(ValueIsFilled(SelCurrency), SelCurrency, SelReservation.FolioCurrency), , SelLanguage);
								vSpreadsheet.Put(vTableFooterPerDay);
							EndIf;
						EndIf;
						If SelByDays Then
							// Put page break
							vSpreadsheet.PutHorizontalPageBreak();
							// Print event header
							PrintEventHeader(vSpreadsheet, vTemplate, vLogo, vLogoIsSet, vHotel, SelReservation, SelLanguage, vParameter);
						EndIf;
					EndIf;
				EndIf;
				
				vCurAccountingDate = vConditionsRow.AccountingDate;
				vDayNumber = vDayNumber + 1;
				
				// Check accounting date
				If ValueIsFilled(SelDateFrom) And BegOfDay(vConditionsRow.AccountingDate) < BegOfDay(SelDateFrom) Then
					Continue;
				EndIf;
				If ValueIsFilled(SelDateTo) And BegOfDay(vConditionsRow.AccountingDate) > BegOfDay(SelDateTo) Then
					Continue;
				EndIf;
				
				If Not ValueIsFilled(vFirstAccountingDate) Then
					vFirstAccountingDate = vCurAccountingDate;
				EndIf;
				
				// Put day area
				vDayArea.Parameters.mAccountingDate = cmGetDayOfWeekName(WeekDay(vCurAccountingDate), False, SelLanguage) + " " + Format(vCurAccountingDate, "DF=dd.MM.yyyy");
				vSpreadsheet.Put(vDayArea);
				
				vDayHeaderWasPrinted = True;
			EndIf;
		
			// Print resource header
			If vCurResourceReservation <> vConditionsRow.ResourceReservation Or 
			   vDayHeaderWasPrinted And SelByDays Then
				vCurResourceReservation = vConditionsRow.ResourceReservation;
				vPrintTableHeader = True;
				vCurServiceType = Undefined;
				
				// Put resource reservation area
				If ValueIsFilled(vCurResourceReservation) Then
					// Try to find resource revenue services
					vResourceArea.Parameters.mResource = "";
					vResRevenueServices = vCurResourceReservation.Services.FindRows(New Structure("IsResourceRevenue", True));
					If vResRevenueServices.Count() > 0 And ValueIsFilled(vCurResourceReservation.Resource) Then
						vResourceArea.Parameters.mResource = vCurResourceReservation.Resource.GetObject().pmGetResourceDescription(SelLanguage);
						If vCurResourceReservation.NumberOfPersons > 0 Then
							vResourceArea.Parameters.mResource = vResourceArea.Parameters.mResource + ", " + Format(vCurResourceReservation.NumberOfPersons, "ND=10; NFD=0") + cmNStr("en=' prs.';ru=' чел.';de=' Pers.'", SelLanguage);
						EndIf;
					Else
						If vCurResourceReservation.NumberOfPersons > 0 Then
							vResourceArea.Parameters.mResource = Format(vCurResourceReservation.NumberOfPersons, "ND=10; NFD=0") + cmNStr("en=' prs.';ru=' чел.';de=' Pers.'", SelLanguage);
						EndIf;
					EndIf;
					vSpreadsheet.Put(vResourceArea);
					// Resource remarks
					mResourceRemarks = "";
					If ValueIsFilled(vCurResourceReservation.ChargingFolio) Then
						If Not IsBlankString(mResourceRemarks) Then
							mResourceRemarks = mResourceRemarks + Chars.LF;
						EndIf;
						mResourceRemarks = mResourceRemarks + cmNStr("en='Folio #: ';ru='Лицевой счет №: ';de='Personenkonto Nr.: '", SelLanguage) + cmGetDocumentNumberPresentation(vCurResourceReservation.ChargingFolio.Number);
					EndIf;
					If ValueIsFilled(vCurResourceReservation.ResourceReservationStatus) Then
						If Not IsBlankString(mResourceRemarks) Then
							mResourceRemarks = mResourceRemarks + Chars.LF;
						EndIf;
						mResourceRemarks = mResourceRemarks + cmNStr("en='Status: ';ru='Статус: ';de='Status: '", SelLanguage) + TrimAll(vCurResourceReservation.ResourceReservationStatus);
					EndIf;
					If ValueIsFilled(vCurResourceReservation.ResourceTableConfiguration) Then
						If Not IsBlankString(mResourceRemarks) Then
							mResourceRemarks = mResourceRemarks + Chars.LF;
						EndIf;
						mResourceRemarks = mResourceRemarks + cmNStr("en='Setup: ';ru='Рассадка: ';de='Platzanweisung: '", SelLanguage) + vCurResourceReservation.ResourceTableConfiguration.GetObject().pmGetTableConfigurationDescription(SelLanguage);
					EndIf;
					If Not IsBlankString(vCurResourceReservation.Remarks) Then
						If Not IsBlankString(mResourceRemarks) Then
							mResourceRemarks = mResourceRemarks + Chars.LF;
						EndIf;
						mResourceRemarks = mResourceRemarks + TrimAll(vCurResourceReservation.Remarks);
					EndIf;
					If Not IsBlankString(mResourceRemarks) Then
						vRemarksLines = cmGetTextLinesArray(mResourceRemarks);
						For Each vRemarksLine In vRemarksLines Do
							vResourceRemarksArea.Parameters.mResourceRemarks = TrimR(vRemarksLine);
							// Put remarks line
							vSpreadsheet.Put(vResourceRemarksArea);
						EndDo;
					EndIf;
				EndIf;
			EndIf;

			// Print activities header
			vSpreadsheet.Put(vActivitiesHeaderArea);
			vDateTimeFrom = Undefined;
			vDateTimeTo = Undefined;
			If ValueIsFilled(vCurResourceReservation) Then
				vDateTimeFrom = vCurResourceReservation.DateTimeFrom;
				vDateTimeTo = vCurResourceReservation.DateTimeTo;
			EndIf;
			vActivities = vServices.Copy();
			vActivities.Sort("TimeFrom");
			// Print activities
			vCurActivity = Undefined;
			vCurServiceResource = Undefined;
			vCurTimeTo = Undefined;
			For Each vSrvRow In vActivities Do
				If vSrvRow.AccountingDate <> vCurAccountingDate Then
					Continue;
				EndIf;
				vServiceResource = Undefined;
				If ValueIsFilled(vSrvRow.ServiceResource) Then
					vServiceResource = vSrvRow.ServiceResource;
				Else
					vServiceResource = vSrvRow.Resource;
				EndIf;
				If Not ValueIsFilled(vSrvRow.EventActivity) Or 
				   (vCurActivity = vSrvRow.EventActivity And vCurServiceResource = vServiceResource And vCurTimeTo = vSrvRow.TimeTo) Then
					Continue;
				EndIf;
				vCurActivity = vSrvRow.EventActivity;
				vCurTimeTo = vSrvRow.TimeTo;
				
				vNumberOfPersons = ?(vSrvRow.NumberOfPersons <> 0, vSrvRow.NumberOfPersons, SelReservation.NumberOfPersons);
				
				// Fill row parameters
				mActivity = vSrvRow.EventActivity;
				
				vCurServiceResource = vServiceResource;
				mServiceResource = "";
				If ValueIsFilled(vServiceResource) Then
					If TypeOf(vServiceResource) = Type("CatalogRef.Resources") Then
						mServiceResource = vServiceResource.GetObject().pmGetResourceDescription(SelLanguage);
					Else
						mServiceResource = TrimAll(vServiceResource);
					EndIf;
				EndIf;
				mServiceConfiguration = "";
				If ValueIsFilled(vSrvRow.ResourceTableConfiguration) Then
					mServiceConfiguration = vSrvRow.ResourceTableConfiguration.GetObject().pmGetTableConfigurationDescription(SelLanguage);
				EndIf;
				mActivityRemarks = cmNStr(vSrvRow.ActivityRemarks, SelLanguage);
				
				// Time
				mPeriod = "";
				If vSrvRow.IsResourceRevenue And ValueIsFilled(vDateTimeFrom) And Not ValueIsFilled(vSrvRow.TimeFrom) Then
					mPeriod = Format(vDateTimeFrom, "DF='HH:mm'") + " - " + Format(vDateTimeTo, "DF='HH:mm'");
				Else
					If ValueIsFilled(vSrvRow.TimeFrom) Then
						mPeriod = Format(vSrvRow.TimeFrom, "DF='HH:mm'") + " - " + Format(vSrvRow.TimeTo, "DF='HH:mm'");
					EndIf;
				EndIf;
				
				vActivityArea.Parameters.mActivity = mActivity;
				vActivityArea.Parameters.mServiceResource = mServiceResource;
				vActivityArea.Parameters.mServiceConfiguration = mServiceConfiguration;
				vActivityArea.Parameters.mPeriod = mPeriod;
				vActivityArea.Parameters.mActivityRemarks = TrimR(mActivityRemarks);
				vActivityArea.Parameters.mNumberOfPersons = vNumberOfPersons;
				If Not SelShortView And ValueIsFilled(vCurResourceReservation) And ValueIsFilled(vCurResourceReservation.ResourceReservationStatus) Then
					vActivityArea.Parameters.mStatus = TrimAll(vCurResourceReservation.ResourceReservationStatus.Code);
				EndIf;
				
				// Put row
				vSpreadsheet.Put(vActivityArea);
			EndDo;
			
			If Not SelHideTotals Then
				// Print table header
				If vPrintTableHeader Then
					vPrintTableHeader = False;
					vSpreadsheet.Put(vTableHeaderArea);
				EndIf;
				// Print services
				For Each vSrvRow In vCndServices Do
					// Print service type header
					If vCurServiceType <> vSrvRow.ServiceType Then
						vCurServiceType = vSrvRow.ServiceType;
						If ValueIsFilled(vCurServiceType) Then
							vServiceTypeArea.Parameters.mServiceType = vCurServiceType.GetObject().pmGetServiceTypeDescription(SelLanguage);
						Else
							vServiceTypeArea.Parameters.mServiceType = cmNStr("en='<Other>';ru='<Прочее>';de='<Andere>'", SelLanguage);
						EndIf;
						vSpreadsheet.Put(vServiceTypeArea);
					EndIf;	
						
					// Fill row parameters
					mPrice = vSrvRow.Price;
					mSum = vSrvRow.Sum;
					mQuantity = ?(vSrvRow.Quantity=0, "", vSrvRow.Quantity);
					If ValueIsFilled(vSrvRow.Service) Then
						If vSrvRow.Quantity <> 0 Then
							If vSrvRow.IsResourceRevenue Then
								mQuantity = Catalogs.Services.pmGetServiceQuantityPresentation(vSrvRow.Service, vSrvRow.Quantity, SelLanguage);
							Else
								mQuantity = Format(vSrvRow.Quantity, "ND=10; NFD=1; NG=") + " " + Catalogs.Services.pmGetServiceUnitDescription(vSrvRow.Service, SelLanguage);
							EndIf;
						EndIf;
					EndIf;
					If Not ValueIsFilled(vSrvRow.ServiceItem) Then
						mService = ?(ValueIsFilled(vSrvRow.Service), Catalogs.Services.pmGetServiceDescription(vSrvRow.Service, SelLanguage), TrimAll(vSrvRow.Service));
					Else
						If TypeOf(vSrvRow.ServiceItem) = Type("CatalogRef.ServiceItems") Then
							mService = Catalogs.ServiceItems.pmGetServiceItemDescription(vSrvRow.ServiceItem, SelLanguage); 
						Else
							mService = cmNStr(vSrvRow.ServiceItem, SelLanguage);
						EndIf;
					EndIf;
					mServiceRemarks = "";
					If Not IsBlankString(vSrvRow.Remarks) Then
						mServiceRemarks = cmNStr(vSrvRow.Remarks, SelLanguage);
					EndIf;
					mServiceResource = "";
					If ValueIsFilled(vSrvRow.ServiceResource) Then
						If TypeOf(vSrvRow.ServiceResource) = Type("CatalogRef.Resources") Then
							mServiceResource = vSrvRow.ServiceResource.GetObject().pmGetResourceDescription(SelLanguage);
						Else
							mServiceResource = TrimAll(vSrvRow.ServiceResource);
						EndIf;
					EndIf;
					mServiceConfiguration = "";
					If ValueIsFilled(vSrvRow.ResourceTableConfiguration) Then
						mServiceConfiguration = vSrvRow.ResourceTableConfiguration.GetObject().pmGetTableConfigurationDescription(SelLanguage);
					EndIf;
					
					vTotalSum = vTotalSum + vSrvRow.Sum;
					vTotalVATSum = vTotalVATSum + vSrvRow.VATSum;
					
					// Time
					mPeriod = "";
					If vSrvRow.IsResourceRevenue And ValueIsFilled(vDateTimeFrom) And Not ValueIsFilled(vSrvRow.TimeFrom) Then
						mPeriod = Format(vDateTimeFrom, "DF='HH:mm'") + " - " + Format(vDateTimeTo, "DF='HH:mm'");
					Else
						If ValueIsFilled(vSrvRow.TimeFrom) Then
							mPeriod = Format(vSrvRow.TimeFrom, "DF='HH:mm'") + " - " + Format(vSrvRow.TimeTo, "DF='HH:mm'");
						EndIf;
					EndIf;
					
					vServiceArea.Parameters.mService = mService;
					If Not SelShortView Then
						vServiceArea.Parameters.mServiceResource = mServiceResource;
						vServiceArea.Parameters.mServiceConfiguration = mServiceConfiguration;
					EndIf;
					vServiceArea.Parameters.mPeriod = mPeriod;
					If ValueIsFilled(vCurResourceReservation) Then
						vServiceArea.Parameters.mPrice = cmFormatSum(mPrice, ?(ValueIsFilled(SelCurrency), SelCurrency, vCurResourceReservation.FolioCurrency), , SelLanguage);
						vServiceArea.Parameters.mSum = cmFormatSum(mSum, ?(ValueIsFilled(SelCurrency), SelCurrency, vCurResourceReservation.FolioCurrency), , SelLanguage);
					Else
						vServiceArea.Parameters.mPrice = Format(mPrice, "ND=17; NFD=2");
						vServiceArea.Parameters.mSum = Format(mSum, "ND=17; NFD=2");
					EndIf;
					vServiceArea.Parameters.mQuantity = mQuantity;
					If SelShortView Then
						vServiceArea.Parameters.mServiceRemarks = TrimR(mServiceRemarks);
					EndIf;
					
					// Put row
					vSpreadsheet.Put(vServiceArea);
					
					// Print service remarks
					If Not SelShortView Then
						If Not IsBlankString(mServiceRemarks) Then
							vRemarksLines = cmGetTextLinesArray(mServiceRemarks);
							For Each vRemarksLine In vRemarksLines Do
								vServiceRemarksArea.Parameters.mServiceRemarks = TrimR(vRemarksLine);
								// Put remarks line
								vSpreadsheet.Put(vServiceRemarksArea);
							EndDo;
						EndIf;
					EndIf;
					
					// Print service items
					If Not SelShortView Then
						vAllSIs = vSIMap.Get(vConditionsRow.ResourceReservation);
						vSIs = vAllSIs.FindRows(New Structure("ServiceID", vSrvRow.ServiceId));
						If vSIs.Count() > 0 Then
							For Each vSIsRow In vSIs Do
								If ValueIsFilled(vSIsRow.ServiceItem) Then
									If TypeOf(vSIsRow.ServiceItem) = Type("Catalogref.ServiceItems") Then
										vServiceItemsArea.Parameters.mServiceItem = Catalogs.ServiceItems.pmGetServiceItemDescription(vSIsRow.ServiceItem, SelLanguage);
									Else
										vServiceItemsArea.Parameters.mServiceItem = TrimAll(vSIsRow.ServiceItem);
									EndIf;
									If vSIsRow.OrderOfServing > 0 Then
										vServiceItemsArea.Parameters.mServiceItem = vServiceItemsArea.Parameters.mServiceItem + Chars.Tab + "(" + vSIsRow.OrderOfServing + ")";
									EndIf;
									If Not IsBlankString(vSIsRow.Output) Then
										vServiceItemsArea.Parameters.mServiceItem = vServiceItemsArea.Parameters.mServiceItem + Chars.LF + Chars.Tab + TrimAll(vSIsRow.Output);
									EndIf;
									// Recalculate service item prices
									vSIsRowSum = vSIsRow.Sum;
									vSIsRowPrice = vSIsRow.Price;
									If ValueIsFilled(SelCurrency) And SelCurrency <> vFolioCurrency Then
										If SelCurrency = vHotel.BaseCurrency And vSIsRow.BaseCurrencyPrice <> 0 Then
											vSIsRowPrice = vSIsRow.BaseCurrencyPrice;
											vSIsRowSum = Round(vSIsRowPrice * vSIsRow.Quantity, 2);
										Else
											vSIsRowSum = Round(cmConvertCurrencies(vSIsRowSum, vFolioCurrency, vFolioCurrencyExchangeRate, SelCurrency, 0, CurrentSessionDate(), vHotel), 2);
											vSIsRowPrice = Round(vSIsRowSum / ?(vSIsRow.Quantity = 0, 1, vSIsRow.Quantity), 2);
										EndIf;
									EndIf;
									// Fill printing form area paramters
									vServiceItemsArea.Parameters.mSIPrice = cmFormatSum(vSIsRowPrice, ?(ValueIsFilled(SelCurrency), SelCurrency, vSIsRow.Currency), , SelLanguage);
									vServiceItemsArea.Parameters.mSIQuantity = Format(vSIsRow.Quantity, "ND=10; NFD=1; NG=") + cmNStr(vSIsRow.Unit, SelLanguage);
									vServiceItemsArea.Parameters.mSISum = cmFormatSum(vSIsRowSum, ?(ValueIsFilled(SelCurrency), SelCurrency, vSIsRow.Currency), , SelLanguage);
									// Put row
									vSpreadsheet.Put(vServiceItemsArea);
								EndIf;
							EndDo;
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
		
		// Reset accounting date
		If ValueIsFilled(SelDateTo) Then
			vCurAccountingDate = BegOfDay(SelDateTo);
		EndIf;
		
		If Not SelHideTotals Then   
			// Totals per last day
			If vConditions.Count() > 0 Then
				vTotalSumPerDay = 0;
				// Print previous day totals
				vDayServices = vServices.Copy();
				i = 0;
				While i < vDayServices.Count() Do
					vDaySrvRow = vDayServices.Get(i);
					If vDaySrvRow.AccountingDate <> vCurAccountingDate Then
						vDayServices.Delete(i);
					Else
						i = i + 1;
					EndIf;
				EndDo;
				vDayServices.GroupBy("ServiceType, ServiceTypeSortCode", "Sum");
				vDayServices.Sort("ServiceTypeSortCode");
				If vDayServices.Count() > 0 Then
					vSpreadsheet.Put(vTableFooterPerDayHeader);
					For Each vSrvTypeRow In vDayServices Do
						If ValueIsFilled(vSrvTypeRow.ServiceType) Then
							vServiceTypeTotalsPerDayArea.Parameters.mServiceType = vSrvTypeRow.ServiceType.GetObject().pmGetServiceTypeDescription(SelLanguage);
						Else
							vServiceTypeTotalsPerDayArea.Parameters.mServiceType = cmNStr("en='<Other>';ru='<Прочее>';de='<Andere>'", SelLanguage);
						EndIf;
						vServiceTypeTotalsPerDayArea.Parameters.mServiceTypeSum = cmFormatSum(vSrvTypeRow.Sum, ?(ValueIsFilled(SelCurrency), SelCurrency, SelReservation.FolioCurrency), , SelLanguage);
						vSpreadsheet.Put(vServiceTypeTotalsPerDayArea);
						vTotalSumPerDay = vTotalSumPerDay + vSrvTypeRow.Sum;
					EndDo;
					vTableFooterPerDay.Parameters.mTotalSumPerDay = cmFormatSum(vTotalSumPerDay, ?(ValueIsFilled(SelCurrency), SelCurrency, SelReservation.FolioCurrency), , SelLanguage);
					vSpreadsheet.Put(vTableFooterPerDay);
				EndIf;
			EndIf;
			
			// Totals by service types
			If Not ValueIsFilled(SelDateFrom) And Not ValueIsFilled(SelDateTo) Then
				vSpreadsheet.Put(vTableFooterHeader);
				vServices.GroupBy("ServiceType, ServiceTypeSortCode", "Sum");
				vServices.Sort("ServiceTypeSortCode");
				If vServices.Count() > 0 Then
					For Each vSrvTypeRow In vServices Do
						If ValueIsFilled(vSrvTypeRow.ServiceType) Then
							vServiceTypeTotalsArea.Parameters.mServiceType = vSrvTypeRow.ServiceType.GetObject().pmGetServiceTypeDescription(SelLanguage);
						Else
							vServiceTypeTotalsArea.Parameters.mServiceType = cmNStr("en='<Other>';ru='<Прочее>';de='<Andere>'", SelLanguage);
						EndIf;
						vServiceTypeTotalsArea.Parameters.mServiceTypeSum = cmFormatSum(vSrvTypeRow.Sum, ?(ValueIsFilled(SelCurrency), SelCurrency, SelReservation.FolioCurrency), , SelLanguage);
						vSpreadsheet.Put(vServiceTypeTotalsArea);
					EndDo;
				EndIf;
				
				// Table footer
				vTblFooter = vTemplate.GetArea("TableFooter");
				// Fill parameters
				mTotalSum = cmFormatSum(vTotalSum, ?(ValueIsFilled(SelCurrency), SelCurrency, SelReservation.FolioCurrency), , SelLanguage);
				// Set parameters
				vTblFooter.Parameters.mTotalSum = mTotalSum;
				// Put table footer
				vSpreadsheet.Put(vTblFooter);
			EndIf;
		EndIf;
		
		// Confirmation reply
		vConfRepl = vTemplate.GetArea("ConfirmationReply");
		If Not IsBlankString(SelReservation.ConfirmationReply) Then
			vConfirmationReply = TrimAll(SelReservation.ConfirmationReply);
		EndIf;
		vConfRepl.Parameters.mConfirmationReply = vConfirmationReply;
		vSpreadsheet.Put(vConfRepl);
		
		// Footer
		vFooter = vTemplate.GetArea("Footer");
		If Not SelHideTotals Then   
			If ValueIsFilled(SelReservation.Company) And SelReservation.Company.DoNotPrintVAT Then
				vFooter.Parameters.mVATPresentation = "";
			Else
				vFooter.Parameters.mVATPresentation = cmNStr("ru='* В цену входит НДС';en='* All rates include VAT (if other is not specified)';de='* All rates include VAT (if other is not specified)'", SelLanguage);
				If ValueIsFilled(SelReservation) Then
					If ValueIsFilled(SelReservation.Company) Then
						If ValueIsFilled(SelReservation.Company.VATRate) Then
							If SelReservation.Company.VATRate.TaxRate = 0 Or
							   SelReservation.Company.VATRate.NoVAT Then
								vFooter.Parameters.mVATPresentation = cmNStr("ru='* Без НДС';en='* No VAT (if other is not specified)';de='* No VAT (if other is not specified)'", SelLanguage);
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		vFooter.Parameters.mSalesDivisionContacts = Catalogs.Hotels.pmGetHotelSalesDivisionContacts(vHotel, SelLanguage);
		// Customer
		mCustomerLegacyName = "";
		If ValueIsFilled(SelReservation.Customer) Then
			mCustomerLegacyName = TrimAll(SelReservation.Customer.LegacyName);
			If IsBlankString(mCustomerLegacyName) Then
				mCustomerLegacyName = TrimAll(SelReservation.Customer.Description);
			EndIf;
		EndIf;
		vFooter.Parameters.mCustomerLegacyName = mCustomerLegacyName;
		mHotelPrintName = Catalogs.Hotels.pmGetHotelPrintName(vHotel, SelLanguage);
		vFooter.Parameters.mHotelPrintName = mHotelPrintName;
		mGuestGroupCode = TrimAll(SelReservation.GuestGroup.Code);
		
		vNumOfEmptyLines = 0;
		vEmptyRow = vTemplate.GetArea("EmptyRow");
		vFooterArray = New Array();
		vFooterArray.Add(vFooter);
		Try
			While vSpreadsheet.CheckPut(vFooterArray) Do
				vFooterArray.Insert(0, vEmptyRow);
				vNumOfEmptyLines = vNumOfEmptyLines + 1;
			EndDo;
		Except
		EndTry;
		If vNumOfEmptyLines > 0 Then
			vFooterArray.Delete(0);
		EndIf;
		For Each vArea In vFooterArray Do
			vSpreadsheet.Put(vArea);
		EndDo;	
		
		If ValueIsFilled(vSelReservation) And SelShowArrangement Then
			vResourceTableConfiguration = vSelReservation.ResourceTableConfiguration;
			If ValueIsFilled(vResourceTableConfiguration) Then
				vPicture = vResourceTableConfiguration.Picture.Get();
				If vPicture <> Undefined Then
					vSpreadsheet.PutHorizontalPageBreak();
					
					vArrangementTemplate = vTemplate.GetArea("Arrangement");
					vArrangementTemplate.Drawings.ArrangementControl.Print = True;
					vArrangementTemplate.Drawings.ArrangementControl.Picture = vPicture;
					vSpreadsheet.Put(vArrangementTemplate);
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	vSpreadsheet.PutHorizontalPageBreak();
	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Portrait, True);
	// Check authorities
	cmSetSpreadsheetProtection(vSpreadsheet);
	// Get and fill workstation print form settings
	If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
		vWorkstationPrintSettings = SessionParameters.CurrentWorkstation.WorkstationPrintSettings;
		If ValueIsFilled(vWorkstationPrintSettings) Then
			// Try to find records for the current object print form
			vFilter = New Structure("ObjectPrintingForm, IsActive", SelObjectPrintForm, True); 
			vPrintSettingsSet = vWorkstationPrintSettings.PrintFormsList.FindRows(vFilter);
			If vPrintSettingsSet.Count() > 0 Then
				For Each vPrintSettings In vPrintSettingsSet Do
					// Fill settings
					cmSetSpreadsheetSettings(vSpreadsheet, vPrintSettings);
					// Check printing direction
					If vPrintSettings.PrintDirection <> Enums.PrintDirections.Screen Then
						vName = cmGetPrintFormFileName(vPrintSettings, NStr("en='Confirmation';ru='Подтверждение';de='Bestätigung'")) + " " + mGuestGroupCode;
						cmDoSpreadsheetOutput(vSpreadsheet, vPrintSettings, vName, SelLanguage);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PrintConfirmationArray

// --------------------------------------------------------------------------------
Procedure PrintConfirmation(pConfirmationSpreadsheet, SelReservation, SelReservations, SelDateFrom, SelDateTo, SelCurrency, SelByDays, SelShortView, SelShowTasks, SelHideTotals, SelDoNotJoinServices, SelLanguage, SelObjectPrintForm, rDoPrint = Undefined, SelShowArrangement = False) Export
	If Not ValueIsFilled(SelLanguage) Then
		SelLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	
	// Fill and check grouping parameter
	vParameter = UPPER(TrimAll(SelObjectPrintForm.Parameter));
	
	// Choose template
	vResObj = SelReservation.GetObject();
	vSpreadsheet = pConfirmationSpreadsheet;
	vSpreadsheet.Clear();
	vTemplateName = "ResourceReservationConfirmationRu";
	If ValueIsFilled(SelLanguage) Then
		If SelLanguage = Catalogs.Languages.EN Then
			vTemplateName = "ResourceReservationConfirmationEn";
		ElsIf SelLanguage = Catalogs.Languages.DE Then
			vTemplateName = "ResourceReservationConfirmationDe";
		ElsIf SelLanguage = Catalogs.Languages.RU Then
			vTemplateName = "ResourceReservationConfirmationRu";
		Else
			tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Не найден шаблон печатной формы подтверждения бронирования ресурса для языка " + SelLanguage.Code + "!'; 
			             |de='Keine Ressource Reservierungsbestätigung druckformularvorlage gefunden für die " + SelLanguage.Code + " sprache!';
			             |en='No resource reservation confirmation print form template found for the " + SelLanguage.Code + " language!'"));
			Return;
		EndIf;
	EndIf;
	If SelShortView Then
		vTemplateName = "Short" + vTemplateName;
	EndIf;
	vTemplate = vResObj.GetTemplate(vTemplateName);
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(SelObjectPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;
	
	// Hotel object
	vHotel = SelReservation.Hotel; 
	// Load pictures
	vLogoIsSet = False;
	vLogo = New Picture;
	If ValueIsFilled(SelReservation.Hotel) Then
		If SelReservation.Hotel.Logo <> Undefined Then
			vLogo = SelReservation.Hotel.Logo.Get();
			If vLogo = Undefined Then
				vLogo = New Picture;
			Else
				vLogoIsSet = True;
			EndIf;
		EndIf;
	EndIf;
	
	// Print event header
	PrintEventHeader(vSpreadsheet, vTemplate, vLogo, vLogoIsSet, vHotel, SelReservation, SelLanguage, vParameter);
	
	// Table rows
	vDayArea = vTemplate.GetArea("Day");
	vResourceArea = vTemplate.GetArea("Resource");
	vResourceRemarksArea = vTemplate.GetArea("ResourceRemarks");
	vActivitiesHeaderArea = vTemplate.GetArea("DayScheduleHeader");
	vActivityArea = vTemplate.GetArea("DayEvent");
	vTableHeaderArea = vTemplate.GetArea("TableHeader");
	vServiceTypeArea = vTemplate.GetArea("ServiceType");
	vServiceTypeTotalsArea = vTemplate.GetArea("ServiceTypeTotals");
	vServiceTypeTotalsPerDayArea = vTemplate.GetArea("ServiceTypeTotalsPerDay");
	vServiceArea = vTemplate.GetArea("Service");
	If Not SelShortView Then
		vServiceRemarksArea = vTemplate.GetArea("ServiceRemarks");
		vServiceItemsArea = vTemplate.GetArea("ServiceItem");
	EndIf;
	vTableFooterPerDayHeader = vTemplate.GetArea("TableFooterPerDayHeader");
	vTableFooterPerDay = vTemplate.GetArea("TableFooterPerDay");
	vTableFooterHeader = vTemplate.GetArea("TableFooterHeader");
	vTableFooter = vTemplate.GetArea("TableFooter");
	vEmptyRow = vTemplate.GetArea("EmptyRow");
	
	// Build map of service items tabular parts
	vSIMap = New Map();
	
	// Build table of all guest group services
	vServices = Undefined;
	vReservations = SelReservation.GuestGroup.GetObject().pmGetResourceReservations();
	For Each vRes In vReservations Do
		If ValueIsFilled(vRes.Status) And vRes.Status.IsActive Then
			vCurRes = vRes.Reservation;
			If vSIMap.Get(vCurRes) = Undefined Then
				vSIMap.Insert(vCurRes, vCurRes.ServiceItems.Unload());
			EndIf;
			If vServices = Undefined Then
				vServices = vCurRes.Services.Unload();
				vServices.Clear();
				vServices.Columns.Add("ResourceType");
				vServices.Columns.Add("ResourceTypeSortCode");
				vServices.Columns.Add("Resource");
				vServices.Columns.Add("ResourceSortCode");
				vServices.Columns.Add("ResourceReservation");
				vServices.Columns.Add("ResourceReservationPointInTime");
				vServices.Columns.Add("ServiceType");
				vServices.Columns.Add("ServiceTypeSortCode");
			EndIf;
			For Each vResSrvRow In vCurRes.Services Do
				vSrvRow = vServices.Add();
				FillPropertyValues(vSrvRow, vCurRes);
				FillPropertyValues(vSrvRow, vResSrvRow);
				If ValueIsFilled(vSrvRow.Service) Then
					vSrvRow.ServiceType = vSrvRow.Service.ServiceType;
				EndIf;
				If ValueIsFilled(vSrvRow.ServiceType) Then
					vSrvRow.ServiceTypeSortCode = vSrvRow.ServiceType.SortCode;
				Else
					vSrvRow.ServiceTypeSortCode = 999999999;
				EndIf;
				If Not ValueIsFilled(vSrvRow.ServiceResource) Then
					vSrvRow.ServiceResource = vCurRes.Resource;
				EndIf;
				If Not ValueIsFilled(vSrvRow.TimeFrom) And Not ValueIsFilled(vSrvRow.TimeTo) Then
					vSrvRow.DateTimeFrom = vCurRes.DateTimeFrom;
					vSrvRow.TimeFrom = vSrvRow.DateTimeFrom;
					vSrvRow.DateTimeTo = vCurRes.DateTimeTo;
					vSrvRow.TimeTo = vSrvRow.DateTimeTo;
				EndIf;
				If ValueIsFilled(vSrvRow.ResourceType) Then
					vSrvRow.ResourceTypeSortCode = vSrvRow.ResourceType.SortCode;
				Else
					vSrvRow.ResourceTypeSortCode = 999999999;
				EndIf;
				If ValueIsFilled(vSrvRow.Resource) Then
					vSrvRow.ResourceSortCode = vSrvRow.Resource.SortCode;
				Else
					vSrvRow.ResourceSortCode = 999999999;
				EndIf;
				vSrvRow.ResourceReservation = vCurRes;
				vSrvRow.ResourceReservationPointInTime = vCurRes.PointInTime();
				If Not ValueIsFilled(vSrvRow.TimeFrom) And Not ValueIsFilled(vSrvRow.TimeTo) Then
					If ValueIsFilled(vCurRes.DateTimeFrom) And ValueIsFilled(vSrvRow.AccountingDate) Then
						vSrvRow.TimeFrom = vCurRes.DateTimeFrom;
						vSrvRow.DateTimeFrom = vSrvRow.AccountingDate + (vSrvRow.TimeFrom - BegOfDay(vSrvRow.TimeFrom));
						vSrvRow.TimeTo = vCurRes.DateTimeTo;
						vSrvRow.DateTimeTo = vSrvRow.AccountingDate + (vSrvRow.TimeTo - BegOfDay(vSrvRow.TimeTo));
						If vSrvRow.TimeFrom >= vSrvRow.TimeTo Then
							vSrvRow.DateTimeTo = vSrvRow.DateTimeTo + (24*3600);
						EndIf;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	If vServices = Undefined Then
		vServices = vCurRes.Services.Unload();
		vServices.Clear();
		vServices.Columns.Add("ResourceType");
		vServices.Columns.Add("ResourceTypeSortCode");
		vServices.Columns.Add("Resource");
		vServices.Columns.Add("ResourceSortCode");
		vServices.Columns.Add("ResourceReservation");
		vServices.Columns.Add("ResourceReservationPointInTime");
		vServices.Columns.Add("ServiceType");
		vServices.Columns.Add("ServiceTypeSortCode");
	Else
		vServices.Sort("AccountingDate, ResourceTypeSortCode, ResourceSortCode, ResourceReservationPointInTime, IsResourceRevenue DESC, ServiceTypeSortCode, DateTimeFrom, TimeFrom");
	EndIf;
	// Hide some services to the other ones
	vDoGroupBy = False;
	If Not SelDoNotJoinServices Then
		// Try to replace accommodation service to the one that should be used for printing
		For Each vSrvRow In vServices Do
			vSrvRowService = vSrvRow.Service;
			If ValueIsFilled(vSrvRowService) And ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
				If vSrvRowService.DoNotGroupIntoRoomRateOnPrint Then
					vSrvRow.Service = vSrvRowService.HideIntoServiceOnPrint;
				EndIf;
			EndIf;
		EndDo;
		// Try to merge other services to the accommodation service
		For Each vSrvRow In vServices Do
			vSrvRowService = vSrvRow.Service;
			If ValueIsFilled(vSrvRowService) And ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
				If Not vSrvRowService.DoNotGroupIntoRoomRateOnPrint Then
					vJoinToServices = vServices.FindRows(New Structure("Service, AccountingDate", vSrvRowService.HideIntoServiceOnPrint, vSrvRow.AccountingDate));
					If vJoinToServices.Count() > 0 Then
						vDoGroupBy = True;
						
						vOldServiceId = vSrvRow.ServiceId;
						vOldServiceRemarks = TrimAll(vSrvRow.Remarks);
						
						vJoinToSrvRow = vJoinToServices.Get(0);
						FillPropertyValues(vSrvRow, vJoinToSrvRow, , "LineNumber, Sum, VATSum, Quantity, Price, BaseCurrencyPrice,
						                                             |DiscountSum, VATDiscountSum, CommissionSum, VATCommissionSum, HoursRented");
						vSrvRow.Quantity = 0;
						vSrvRow.Price = 0;
						
						// Replace old service id by new one in the service items
						vSITable = vSIMap.Get(vSrvRow.ResourceReservation);
						For Each vSITableRow In vSITable Do
							If vSITableRow.ServiceId = vOldServiceId Then
								vSITableRow.ServiceId = vSrvRow.ServiceId;
							EndIf;
						EndDo;
						vSIMap.Insert(vSrvRow.ResourceReservation, vSITable);
						
						// Join remarks
						vSrvRow.Remarks = TrimAll(vSrvRow.Remarks) + Chars.LF + vOldServiceRemarks;
						vJoinToSrvRow.Remarks = vSrvRow.Remarks;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	If vDoGroupBy And vServices.Count() > 0 Then
		vServices.GroupBy("AccountingDate, CalendarDayType, Company, DateTimeFrom, DateTimeTo, 
		                  |Discount, DiscountType, DiscountConfirmationText, DiscountServiceGroup, 
						  |IsManual, IsManualPrice, IsResourceRevenue, Remarks,
						  |EventActivity, ActivityRemarks, NumberOfPersons,
						  |Resource, ResourceReservation, ResourceReservationPointInTime, ResourceSortCode, 
						  |ResourceTableConfiguration, ResourceType, ResourceTypeSortCode, 
						  |Service, ServiceId, ServiceItem, ServiceResource, ServiceType, ServiceTypeSortCode, 
						  |TimeFrom, TimeTo, Timetable, Unit, VATRate", 
						  "Sum, VATSum, Quantity, Price, BaseCurrencyPrice, 
						  |DiscountSum, VATDiscountSum, CommissionSum, VATCommissionSum, 
						  |HoursRented");
	EndIf;
	
	// Recalculate all amounts to the printing form currency
	For Each vSrvRow In vServices Do
		vSrvRow.Sum = vSrvRow.Sum - vSrvRow.DiscountSum;
		vSrvRow.VATSum = vSrvRow.VATSum - vSrvRow.VATDiscountSum;
		vSrvRow.Price = cmRecalculatePrice(vSrvRow.Sum, vSrvRow.Quantity);
		
		vFolioCurrency = vSrvRow.ResourceReservation.FolioCurrency;
		vFolioCurrencyExchangeRate = vSrvRow.ResourceReservation.FolioCurrencyExchangeRate;
		If ValueIsFilled(SelCurrency) And SelCurrency <> vFolioCurrency Then
			If SelCurrency = vHotel.BaseCurrency And vSrvRow.BaseCurrencyPrice <> 0 Then
				vSrvRow.Price = vSrvRow.BaseCurrencyPrice;
				vSrvRow.Sum = Round(vSrvRow.Price * vSrvRow.Quantity, 2);
			Else
				vSrvRow.Sum = Round(cmConvertCurrencies(vSrvRow.Sum, vFolioCurrency, vFolioCurrencyExchangeRate, SelCurrency, 0, CurrentSessionDate(), vHotel), 2);
				vSrvRow.Price = Round(vSrvRow.Sum / ?(vSrvRow.Quantity = 0, 1, vSrvRow.Quantity), 2);
			EndIf;
			cmPriceOnChange(vSrvRow.Price, vSrvRow.Quantity, vSrvRow.Sum, vSrvRow.VATRate, vSrvRow.VATSum, vSrvRow.AccountingDate);
		EndIf;
	EndDo;
	
	// Print services
	vTotalSum = 0;
	vTotalVATSum = 0;
	
	// Initialize grouping parameters
	vDayNumber = 0;
	vCurAccountingDate = Undefined;
	vFirstAccountingDate = Undefined;
	vCurResourceReservation = Undefined;
	vPrintTableHeader = True;
	vCurServiceType = Undefined;
	vDayActivitiesWerePrinted = False;
	
	// Group services by accounting date, resource
	vConditions = vServices.Copy();
	vConditions.GroupBy("AccountingDate, ResourceType, ResourceTypeSortCode, Resource, ResourceSortCode, ResourceReservation, ResourceReservationPointInTime", );
	If Find(vParameter, "DO_NOT_GROUP_BY_RESOURCE_TYPE") > 0 Then
		vConditions.Sort("AccountingDate, ResourceSortCode, ResourceReservationPointInTime");
	Else
		vConditions.Sort("AccountingDate, ResourceTypeSortCode, ResourceSortCode, ResourceReservationPointInTime");
	EndIf;
	For Each vConditionsRow In vConditions Do
		// Select services for the each condition
		vRowsArray = vServices.FindRows(New Structure("AccountingDate, ResourceType, Resource, ResourceReservation", 
		                                vConditionsRow.AccountingDate,
		                                vConditionsRow.ResourceType,  
		                                vConditionsRow.Resource, 
		                                vConditionsRow.ResourceReservation));
		vCndServices = vServices.CopyColumns();
		For Each vRowElement In vRowsArray Do
			vCndServicesRow = vCndServices.Add();
			FillPropertyValues(vCndServicesRow, vRowElement);
		EndDo;
		
		vFolioCurrency = vConditionsRow.ResourceReservation.FolioCurrency;
		vFolioCurrencyExchangeRate = vConditionsRow.ResourceReservation.FolioCurrencyExchangeRate;
	
		// Print day header
		vDayHeaderWasPrinted = False;
		If vCurAccountingDate <> vConditionsRow.AccountingDate Then
			vPrintTableHeader = True;
			vCurServiceType = Undefined;
			vTotalSumPerDay = 0;
			vDayActivitiesWerePrinted = False;
			
			// Check accounting date
			If ValueIsFilled(SelDateFrom) And BegOfDay(vConditionsRow.AccountingDate) < BegOfDay(SelDateFrom) Then
				Continue;
			EndIf;
			If ValueIsFilled(SelDateTo) And BegOfDay(vConditionsRow.AccountingDate) > BegOfDay(SelDateTo) Then
				Continue;
			EndIf;
			
			// Print event header
			If ValueIsFilled(vFirstAccountingDate) Then
				// Print previous day totals
				vDayServices = vServices.Copy();
				i = 0;
				While i < vDayServices.Count() Do
					vDaySrvRow = vDayServices.Get(i);
					If vDaySrvRow.AccountingDate <> vCurAccountingDate Then
						vDayServices.Delete(i);
					Else
						i = i + 1;
					EndIf;
				EndDo;
				If Not SelHideTotals Then 
					vDayServices.GroupBy("ServiceType, ServiceTypeSortCode", "Sum");
					vDayServices.Sort("ServiceTypeSortCode");
					If Not ValueIsFilled(SelDateFrom) And Not ValueIsFilled(SelDateTo) Or BegOfDay(SelDateTo) > BegOfDay(SelDateFrom) Then
						If vDayServices.Count() > 0 Then
							vSpreadsheet.Put(vTableFooterPerDayHeader);
							For Each vSrvTypeRow In vDayServices Do
								If ValueIsFilled(vSrvTypeRow.ServiceType) Then
									vServiceTypeTotalsPerDayArea.Parameters.mServiceType = vSrvTypeRow.ServiceType.GetObject().pmGetServiceTypeDescription(SelLanguage);
								Else
									vServiceTypeTotalsPerDayArea.Parameters.mServiceType = cmNStr("en='<Other>';ru='<Прочее>';de='<Andere>'", SelLanguage);
								EndIf;
								vServiceTypeTotalsPerDayArea.Parameters.mServiceTypeSum = cmFormatSum(vSrvTypeRow.Sum, ?(ValueIsFilled(SelCurrency), SelCurrency, SelReservation.FolioCurrency), , SelLanguage);
								vSpreadsheet.Put(vServiceTypeTotalsPerDayArea);
								vTotalSumPerDay = vTotalSumPerDay + vSrvTypeRow.Sum;
							EndDo;
							vTableFooterPerDay.Parameters.mTotalSumPerDay = cmFormatSum(vTotalSumPerDay, ?(ValueIsFilled(SelCurrency), SelCurrency, SelReservation.FolioCurrency), , SelLanguage);
							vSpreadsheet.Put(vTableFooterPerDay);
						EndIf;
					EndIf;
				EndIf;	
				If SelByDays Then
					// Put page break
					vSpreadsheet.PutHorizontalPageBreak();
					// Print event header
					PrintEventHeader(vSpreadsheet, vTemplate, vLogo, vLogoIsSet, vHotel, SelReservation, SelLanguage, vParameter);
				EndIf; 				
			EndIf;
			
			vCurAccountingDate = vConditionsRow.AccountingDate;
			vDayNumber = vDayNumber + 1;
			
			If Not ValueIsFilled(vFirstAccountingDate) Then
				vFirstAccountingDate = vCurAccountingDate;
			EndIf;
			
			// Put day area
			vDayArea.Parameters.mAccountingDate = cmGetDayOfWeekName(WeekDay(vCurAccountingDate), False, SelLanguage) + " " + Format(vCurAccountingDate, "DF=dd.MM.yyyy");
			vSpreadsheet.Put(vDayArea);
			
			vDayHeaderWasPrinted = True;
		EndIf;

		// Print activities header once per day
		If Not vDayActivitiesWerePrinted Then
			vDayActivitiesWerePrinted = True;
			vSpreadsheet.Put(vActivitiesHeaderArea);
			vDateTimeFrom = Undefined;
			vDateTimeTo = Undefined;
			If ValueIsFilled(vConditionsRow.ResourceReservation) Then
				vDateTimeFrom = vConditionsRow.ResourceReservation.DateTimeFrom;
				vDateTimeTo = vConditionsRow.ResourceReservation.DateTimeTo;
			EndIf;
			vActivities = vServices.Copy();
			vActivities.Sort("TimeFrom");
			// Print activities
			vCurActivity = Undefined;
			vCurServiceResource = Undefined;
			vCurTimeTo = Undefined;
			For Each vSrvRow In vActivities Do
				If vSrvRow.AccountingDate <> vCurAccountingDate Then
					Continue;
				EndIf;
				vServiceResource = Undefined;
				If ValueIsFilled(vSrvRow.ServiceResource) Then
					vServiceResource = vSrvRow.ServiceResource;
				Else
					vServiceResource = vSrvRow.Resource;
				EndIf;
				If Not ValueIsFilled(vSrvRow.EventActivity) Or 
				   (vCurActivity = vSrvRow.EventActivity And vCurServiceResource = vServiceResource And vCurTimeTo = vSrvRow.TimeTo) Then
					Continue;
				EndIf;
				vCurActivity = vSrvRow.EventActivity;
				vCurTimeTo = vSrvRow.TimeTo;
				
				vNumberOfPersons = ?(vSrvRow.NumberOfPersons <> 0, vSrvRow.NumberOfPersons, SelReservation.NumberOfPersons);
				
				// Fill row parameters
				mActivity = vSrvRow.EventActivity;

				vCurServiceResource = vServiceResource;
				mServiceResource = "";
				If ValueIsFilled(vServiceResource) Then
					If TypeOf(vServiceResource) = Type("CatalogRef.Resources") Then
						mServiceResource = vServiceResource.GetObject().pmGetResourceDescription(SelLanguage);
					Else
						mServiceResource = TrimAll(vServiceResource);
					EndIf;
				EndIf;
				mServiceConfiguration = "";
				If ValueIsFilled(vSrvRow.ResourceTableConfiguration) Then
					mServiceConfiguration = vSrvRow.ResourceTableConfiguration.GetObject().pmGetTableConfigurationDescription(SelLanguage);
				EndIf;
				mActivityRemarks = cmNStr(vSrvRow.ActivityRemarks, SelLanguage);
				
				// Time
				mPeriod = "";
				If vSrvRow.IsResourceRevenue And ValueIsFilled(vDateTimeFrom) And Not ValueIsFilled(vSrvRow.TimeFrom) Then
					mPeriod = Format(vDateTimeFrom, "DF='HH:mm'") + " - " + Format(vDateTimeTo, "DF='HH:mm'");
				Else
					If ValueIsFilled(vSrvRow.TimeFrom) Then
						mPeriod = Format(vSrvRow.TimeFrom, "DF='HH:mm'") + " - " + Format(vSrvRow.TimeTo, "DF='HH:mm'");
					EndIf;
				EndIf;
				
				vActivityArea.Parameters.mActivity = mActivity;
				vActivityArea.Parameters.mServiceResource = mServiceResource;
				vActivityArea.Parameters.mServiceConfiguration = mServiceConfiguration;
				vActivityArea.Parameters.mPeriod = mPeriod;
				vActivityArea.Parameters.mActivityRemarks = TrimR(mActivityRemarks);
				vActivityArea.Parameters.mNumberOfPersons = vNumberOfPersons;
				If Not SelShortView And ValueIsFilled(vConditionsRow.ResourceReservation) And ValueIsFilled(vConditionsRow.ResourceReservation.ResourceReservationStatus) Then
					vActivityArea.Parameters.mStatus = TrimAll(vConditionsRow.ResourceReservation.ResourceReservationStatus.Code);
				EndIf;
				
				// Put row
				vSpreadsheet.Put(vActivityArea);
			EndDo;
		EndIf;
	
		// Print resource header
		If vCurResourceReservation <> vConditionsRow.ResourceReservation Or 
		   vDayHeaderWasPrinted And SelByDays Then
			vCurResourceReservation = vConditionsRow.ResourceReservation;
			vPrintTableHeader = True;
			vCurServiceType = Undefined;
			
			// Put resource reservation area
			If ValueIsFilled(vCurResourceReservation) Then
				// Try to find resource revenue services
				vResourceArea.Parameters.mResource = "";
				vResRevenueServices = vCurResourceReservation.Services.FindRows(New Structure("IsResourceRevenue", True));
				If vResRevenueServices.Count() > 0 And ValueIsFilled(vCurResourceReservation.Resource) Then
					vResourceArea.Parameters.mResource = vCurResourceReservation.Resource.GetObject().pmGetResourceDescription(SelLanguage);
					If vCurResourceReservation.NumberOfPersons > 0 Then
						vResourceArea.Parameters.mResource = vResourceArea.Parameters.mResource + ", " + Format(vCurResourceReservation.NumberOfPersons, "ND=10; NFD=0") + cmNStr("en=' prs.';ru=' чел.';de=' Pers.'", SelLanguage);
					EndIf;
				Else
					If vCurResourceReservation.NumberOfPersons > 0 Then
						vResourceArea.Parameters.mResource = Format(vCurResourceReservation.NumberOfPersons, "ND=10; NFD=0") + cmNStr("en=' prs.';ru=' чел.';de=' Pers.'", SelLanguage);
					EndIf;
				EndIf;
				vSpreadsheet.Put(vResourceArea);
				// Resource remarks
				mResourceRemarks = "";
				If ValueIsFilled(vCurResourceReservation.ChargingFolio) Then
					If Not IsBlankString(mResourceRemarks) Then
						mResourceRemarks = mResourceRemarks + Chars.LF;
					EndIf;
					mResourceRemarks = mResourceRemarks + cmNStr("en='Folio #: ';ru='Лицевой счет №: ';de='Personenkonto Nr.: '", SelLanguage) + cmGetDocumentNumberPresentation(vCurResourceReservation.ChargingFolio.Number);
				EndIf;
				If ValueIsFilled(vCurResourceReservation.ResourceReservationStatus) Then
					If Not IsBlankString(mResourceRemarks) Then
						mResourceRemarks = mResourceRemarks + Chars.LF;
					EndIf;
					mResourceRemarks = mResourceRemarks + cmNStr("en='Status: ';ru='Статус: ';de='Status: '", SelLanguage) + TrimAll(vCurResourceReservation.ResourceReservationStatus);
				EndIf;
				If ValueIsFilled(vCurResourceReservation.ResourceTableConfiguration) Then
					If Not IsBlankString(mResourceRemarks) Then
						mResourceRemarks = mResourceRemarks + Chars.LF;
					EndIf;
					mResourceRemarks = mResourceRemarks + cmNStr("en='Setup: ';ru='Рассадка: ';de='Platzanweisung: '", SelLanguage) + vCurResourceReservation.ResourceTableConfiguration.GetObject().pmGetTableConfigurationDescription(SelLanguage);
				EndIf;
				If Not IsBlankString(vCurResourceReservation.Remarks) Then
					If Not IsBlankString(mResourceRemarks) Then
						mResourceRemarks = mResourceRemarks + Chars.LF;
					EndIf;
					mResourceRemarks = mResourceRemarks + TrimAll(vCurResourceReservation.Remarks);
				EndIf;
				If Not IsBlankString(mResourceRemarks) Then
					vRemarksLines = cmGetTextLinesArray(mResourceRemarks);
					For Each vRemarksLine In vRemarksLines Do
						vResourceRemarksArea.Parameters.mResourceRemarks = TrimR(vRemarksLine);
						// Put remarks line
						vSpreadsheet.Put(vResourceRemarksArea);
					EndDo;
				EndIf;
			EndIf;
		EndIf;
		
		If Not SelHideTotals Then   
			// Print table header
			If vPrintTableHeader Then
				vPrintTableHeader = False;
				vSpreadsheet.Put(vTableHeaderArea);
			EndIf;
			// Print services
			For Each vSrvRow In vCndServices Do
				// Print service type header
				If vCurServiceType <> vSrvRow.ServiceType Then
					vCurServiceType = vSrvRow.ServiceType;
					If ValueIsFilled(vCurServiceType) Then
						vServiceTypeArea.Parameters.mServiceType = vCurServiceType.GetObject().pmGetServiceTypeDescription(SelLanguage);
					Else
						vServiceTypeArea.Parameters.mServiceType = cmNStr("en='<Other>';ru='<Прочее>';de='<Andere>'", SelLanguage);
					EndIf;
					vSpreadsheet.Put(vServiceTypeArea);
				EndIf;	
					
				// Fill row parameters
				mPrice = vSrvRow.Price;
				mSum = vSrvRow.Sum;
				mQuantity = ?(vSrvRow.Quantity=0, "", vSrvRow.Quantity);
				If ValueIsFilled(vSrvRow.Service) Then
					If vSrvRow.Quantity <> 0 Then
						If vSrvRow.IsResourceRevenue Then
							mQuantity = Catalogs.Services.pmGetServiceQuantityPresentation(vSrvRow.Service, vSrvRow.Quantity, SelLanguage);
						Else
							mQuantity = Format(vSrvRow.Quantity, "ND=10; NFD=1; NG=") + " " + Catalogs.Services.pmGetServiceUnitDescription(vSrvRow.Service, SelLanguage);
						EndIf;
					EndIf;
				EndIf;
				If Not ValueIsFilled(vSrvRow.ServiceItem) Then
					mService = ?(ValueIsFilled(vSrvRow.Service), Catalogs.Services.pmGetServiceDescription(vSrvRow.Service, SelLanguage), TrimAll(vSrvRow.Service));
				Else
					If TypeOf(vSrvRow.ServiceItem) = Type("CatalogRef.ServiceItems") Then
						mService = Catalogs.ServiceItems.pmGetServiceItemDescription(vSrvRow.ServiceItem, SelLanguage);
					Else
						mService = cmNStr(vSrvRow.ServiceItem, SelLanguage);
					EndIf;
				EndIf;
				mServiceRemarks = "";
				If Not IsBlankString(vSrvRow.Remarks) Then
					mServiceRemarks = cmNStr(vSrvRow.Remarks, SelLanguage);
				EndIf;
				mServiceResource = "";
				If ValueIsFilled(vSrvRow.ServiceResource) Then
					If TypeOf(vSrvRow.ServiceResource) = Type("CatalogRef.Resources") Then
						mServiceResource = vSrvRow.ServiceResource.GetObject().pmGetResourceDescription(SelLanguage);
					Else
						mServiceResource = TrimAll(vSrvRow.ServiceResource);
					EndIf;
				EndIf;
				mServiceConfiguration = "";
				If ValueIsFilled(vSrvRow.ResourceTableConfiguration) Then
					mServiceConfiguration = vSrvRow.ResourceTableConfiguration.GetObject().pmGetTableConfigurationDescription(SelLanguage);
				EndIf;
				
				vTotalSum = vTotalSum + vSrvRow.Sum;
				vTotalVATSum = vTotalVATSum + vSrvRow.VATSum;
				
				// Time
				mPeriod = "";
				If vSrvRow.IsResourceRevenue And ValueIsFilled(vDateTimeFrom) And Not ValueIsFilled(vSrvRow.TimeFrom) Then
					mPeriod = Format(vDateTimeFrom, "DF='HH:mm'") + " - " + Format(vDateTimeTo, "DF='HH:mm'");
				Else
					If ValueIsFilled(vSrvRow.TimeFrom) Then
						mPeriod = Format(vSrvRow.TimeFrom, "DF='HH:mm'") + " - " + Format(vSrvRow.TimeTo, "DF='HH:mm'");
					EndIf;
				EndIf;
				
				vServiceArea.Parameters.mService = mService;
				If Not SelShortView Then
					vServiceArea.Parameters.mServiceResource = mServiceResource;
					vServiceArea.Parameters.mServiceConfiguration = mServiceConfiguration;
				EndIf;
				vServiceArea.Parameters.mPeriod = mPeriod;
				If ValueIsFilled(vCurResourceReservation) Then
					vServiceArea.Parameters.mPrice = cmFormatSum(mPrice, ?(ValueIsFilled(SelCurrency), SelCurrency, vCurResourceReservation.FolioCurrency), , SelLanguage);
					vServiceArea.Parameters.mSum = cmFormatSum(mSum, ?(ValueIsFilled(SelCurrency), SelCurrency, vCurResourceReservation.FolioCurrency), , SelLanguage);
				Else
					vServiceArea.Parameters.mPrice = Format(mPrice, "ND=17; NFD=2");
					vServiceArea.Parameters.mSum = Format(mSum, "ND=17; NFD=2");
				EndIf;
				vServiceArea.Parameters.mQuantity = mQuantity;
				If SelShortView Then
					vServiceArea.Parameters.mServiceRemarks = TrimR(mServiceRemarks);
				EndIf;
				
				// Put row
				vSpreadsheet.Put(vServiceArea);
				
				// Print service remarks
				If Not SelShortView Then
					If Not IsBlankString(mServiceRemarks) Then
						vRemarksLines = cmGetTextLinesArray(mServiceRemarks);
						For Each vRemarksLine In vRemarksLines Do
							vServiceRemarksArea.Parameters.mServiceRemarks = TrimR(vRemarksLine);
							// Put remarks line
							vSpreadsheet.Put(vServiceRemarksArea);
						EndDo;
					EndIf;
				EndIf;
				
				// Print service items
				If Not SelShortView Then
					vAllSIs = vSIMap.Get(vConditionsRow.ResourceReservation);
					vSIs = vAllSIs.FindRows(New Structure("ServiceID", vSrvRow.ServiceId));
					If vSIs.Count() > 0 Then
						For Each vSIsRow In vSIs Do
							If ValueIsFilled(vSIsRow.ServiceItem) Then
								If TypeOf(vSIsRow.ServiceItem) = Type("Catalogref.ServiceItems") Then
									vServiceItemsArea.Parameters.mServiceItem = Catalogs.ServiceItems.pmGetServiceItemDescription(vSIsRow.ServiceItem, SelLanguage);
								Else
									vServiceItemsArea.Parameters.mServiceItem = TrimAll(vSIsRow.ServiceItem);
								EndIf;
								If vSIsRow.OrderOfServing > 0 Then
									vServiceItemsArea.Parameters.mServiceItem = vServiceItemsArea.Parameters.mServiceItem + Chars.Tab + "(" + vSIsRow.OrderOfServing + ")";
								EndIf;
								If Not IsBlankString(vSIsRow.Output) Then
									vServiceItemsArea.Parameters.mServiceItem = vServiceItemsArea.Parameters.mServiceItem + Chars.LF + Chars.Tab + TrimAll(vSIsRow.Output);
								EndIf;
								// Recalculate service item prices
								vSIsRowSum = vSIsRow.Sum;
								vSIsRowPrice = vSIsRow.Price;
								If ValueIsFilled(SelCurrency) And SelCurrency <> vFolioCurrency Then
									If SelCurrency = vHotel.BaseCurrency And vSIsRow.BaseCurrencyPrice <> 0 Then
										vSIsRowPrice = vSIsRow.BaseCurrencyPrice;
										vSIsRowSum = Round(vSIsRowPrice * vSIsRow.Quantity, 2);
									Else
										vSIsRowSum = Round(cmConvertCurrencies(vSIsRowSum, vFolioCurrency, vFolioCurrencyExchangeRate, SelCurrency, 0, CurrentSessionDate(), vHotel), 2);
										vSIsRowPrice = Round(vSIsRowSum / ?(vSIsRow.Quantity = 0, 1, vSIsRow.Quantity), 2);
									EndIf;
								EndIf;
								// Fill printing form area paramters
								vServiceItemsArea.Parameters.mSIPrice = cmFormatSum(vSIsRowPrice, ?(ValueIsFilled(SelCurrency), SelCurrency, vSIsRow.Currency), , SelLanguage);
								vServiceItemsArea.Parameters.mSIQuantity = Format(vSIsRow.Quantity, "ND=10; NFD=1; NG=") + cmNStr(vSIsRow.Unit, SelLanguage);
								vServiceItemsArea.Parameters.mSISum = cmFormatSum(vSIsRowSum, ?(ValueIsFilled(SelCurrency), SelCurrency, vSIsRow.Currency), , SelLanguage);
								// Put row
								vSpreadsheet.Put(vServiceItemsArea);
							EndIf;
						EndDo;
					EndIf;
				EndIf;
			EndDo;
		Endif;
	EndDo;
	
	// Reset accounting date
	If ValueIsFilled(SelDateTo) Then
		vCurAccountingDate = BegOfDay(SelDateTo);
	EndIf;
	
	// Totals per last day
	If vConditions.Count() > 0 Then
		vTotalSumPerDay = 0;
		// Print previous day totals
		vDayServices = vServices.Copy();
		i = 0;
		While i < vDayServices.Count() Do
			vDaySrvRow = vDayServices.Get(i);
			If vDaySrvRow.AccountingDate <> vCurAccountingDate Then
				vDayServices.Delete(i);
			Else
				i = i + 1;
			EndIf;
		EndDo;
		
		If Not SelHideTotals Then   
			vDayServices.GroupBy("ServiceType, ServiceTypeSortCode", "Sum");
			vDayServices.Sort("ServiceTypeSortCode");
			If vDayServices.Count() > 0 Then
				vSpreadsheet.Put(vTableFooterPerDayHeader);
				For Each vSrvTypeRow In vDayServices Do
					If ValueIsFilled(vSrvTypeRow.ServiceType) Then
						vServiceTypeTotalsPerDayArea.Parameters.mServiceType = vSrvTypeRow.ServiceType.GetObject().pmGetServiceTypeDescription(SelLanguage);
					Else
						vServiceTypeTotalsPerDayArea.Parameters.mServiceType = cmNStr("en='<Other>';ru='<Прочее>';de='<Andere>'", SelLanguage);
					EndIf;
					vServiceTypeTotalsPerDayArea.Parameters.mServiceTypeSum = cmFormatSum(vSrvTypeRow.Sum, ?(ValueIsFilled(SelCurrency), SelCurrency, SelReservation.FolioCurrency), , SelLanguage);
					vSpreadsheet.Put(vServiceTypeTotalsPerDayArea);
					vTotalSumPerDay = vTotalSumPerDay + vSrvTypeRow.Sum;
				EndDo;
				vTableFooterPerDay.Parameters.mTotalSumPerDay = cmFormatSum(vTotalSumPerDay, ?(ValueIsFilled(SelCurrency), SelCurrency, SelReservation.FolioCurrency), , SelLanguage);
				vSpreadsheet.Put(vTableFooterPerDay);
			EndIf;
			
			// Totals by service types
			If Not ValueIsFilled(SelDateFrom) And Not ValueIsFilled(SelDateTo) Then
				vSpreadsheet.Put(vTableFooterHeader);
				vServices.GroupBy("ServiceType, ServiceTypeSortCode", "Sum");
				vServices.Sort("ServiceTypeSortCode");
				If vServices.Count() > 0 Then
					For Each vSrvTypeRow In vServices Do
						If ValueIsFilled(vSrvTypeRow.ServiceType) Then
							vServiceTypeTotalsArea.Parameters.mServiceType = vSrvTypeRow.ServiceType.GetObject().pmGetServiceTypeDescription(SelLanguage);
						Else
							vServiceTypeTotalsArea.Parameters.mServiceType = cmNStr("en='<Other>';ru='<Прочее>';de='<Andere>'", SelLanguage);
						EndIf;
						vServiceTypeTotalsArea.Parameters.mServiceTypeSum = cmFormatSum(vSrvTypeRow.Sum, ?(ValueIsFilled(SelCurrency), SelCurrency, SelReservation.FolioCurrency), , SelLanguage);
						vSpreadsheet.Put(vServiceTypeTotalsArea);
					EndDo;
				EndIf;
				
				// Table footer
				vTblFooter = vTemplate.GetArea("TableFooter");
				// Fill parameters
				mTotalSum = cmFormatSum(vTotalSum, ?(ValueIsFilled(SelCurrency), SelCurrency, SelReservation.FolioCurrency), , SelLanguage);
				// Set parameters
				vTblFooter.Parameters.mTotalSum = mTotalSum;
				// Put table footer
				vSpreadsheet.Put(vTblFooter);
			EndIf;
		EndIf;
	EndIf;
	
	// Confirmation reply
	vConfRepl = vTemplate.GetArea("ConfirmationReply");
	If Not IsBlankString(SelReservation.ConfirmationReply) Then
		vConfirmationReply = TrimAll(SelReservation.ConfirmationReply);
	EndIf;
	vConfRepl.Parameters.mConfirmationReply = vConfirmationReply;
	vSpreadsheet.Put(vConfRepl);
	
	If SelShowTasks Then
		vDepartmentTasksRow = vTemplate.GetArea("DepartmentTasksRow");
		For Each vRes In vReservations Do
			If ValueIsFilled(vRes.Status) And vRes.Status.IsActive Then
				vTasks = GetTasks(vRes.Reservation);
				vDepartment = Undefined;
				For Each vTaskRow In vTasks Do
					If vTaskRow.ForDepartment <> vDepartment Then
						If vDepartment <> Undefined Then
							vSpreadsheet.Put(vDepartmentTasksRow);
						EndIf;
						vDepartmentTasksRow = vTemplate.GetArea("DepartmentTasksRow");
						If ValueIsFilled(vTaskRow.ForDepartment) Then
							vDepartmentTasksRow.Parameters.mDepartment = vTaskRow.ForDepartment; 
						Else
							vDepartmentTasksRow.Parameters.mDepartment = cmNStr("en='General information'; ru='Общая информация'; de='Allgemeine Informationen'", SelLanguage);
						EndIf;
						vDepartmentTasksRow.Parameters.mDepartmentTasks = vTaskRow.Ref.Remarks;
						vDepartment = vTaskRow.ForDepartment;
					Else
						vDepartmentTasksRow.Parameters.mDepartmentTasks = vDepartmentTasksRow.Parameters.mDepartmentTasks + Chars.LF + vTaskRow.Ref.Remarks;
					EndIf;
				EndDo;  
				If vTasks.Count() > 0 Then
					vSpreadsheet.Put(vDepartmentTasksRow);
				EndIf;
			EndIf;
		EndDo;
	EndIf;

	// Footer
	vFooter = vTemplate.GetArea("Footer");
	If Not SelHideTotals Then
		If ValueIsFilled(SelReservation.Company) And SelReservation.Company.DoNotPrintVAT Then
			vFooter.Parameters.mVATPresentation = "";
		Else
			vFooter.Parameters.mVATPresentation = cmNStr("ru='* В цену входит НДС';en='* All rates include VAT (if other is not specified)';de='* All rates include VAT (if other is not specified)'", SelLanguage);
			If ValueIsFilled(SelReservation) Then
				If ValueIsFilled(SelReservation.Company) Then
					If ValueIsFilled(SelReservation.Company.VATRate) Then
						If SelReservation.Company.VATRate.TaxRate = 0 Or
						   SelReservation.Company.VATRate.NoVAT Then
							vFooter.Parameters.mVATPresentation = cmNStr("ru='* Без НДС';en='* No VAT (if other is not specified)';de='* No VAT (if other is not specified)'", SelLanguage);
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	vFooter.Parameters.mSalesDivisionContacts = Catalogs.Hotels.pmGetHotelSalesDivisionContacts(vHotel, SelLanguage);
	// Customer
	mCustomerLegacyName = "";
	If ValueIsFilled(SelReservation.Customer) Then
		mCustomerLegacyName = TrimAll(SelReservation.Customer.LegacyName);
		If IsBlankString(mCustomerLegacyName) Then
			mCustomerLegacyName = TrimAll(SelReservation.Customer.Description);
		EndIf;
	EndIf;
	vFooter.Parameters.mCustomerLegacyName = mCustomerLegacyName;
	mHotelPrintName = Catalogs.Hotels.pmGetHotelPrintName(vHotel, SelLanguage);
	vFooter.Parameters.mHotelPrintName = mHotelPrintName;
	mGuestGroupCode = TrimAll(SelReservation.GuestGroup.Code);
	
	vNumOfEmptyLines = 0;
	vEmptyRow = vTemplate.GetArea("EmptyRow");
	vFooterArray = New Array();
	vFooterArray.Add(vFooter);
	Try
		While vSpreadsheet.CheckPut(vFooterArray) Do
			vFooterArray.Insert(0, vEmptyRow);
			vNumOfEmptyLines = vNumOfEmptyLines + 1;
		EndDo;
	Except
	EndTry;
	If vNumOfEmptyLines > 0 Then
		vFooterArray.Delete(0);
	EndIf;
	For Each vArea In vFooterArray Do
		vSpreadsheet.Put(vArea);
	EndDo;
	
	If ValueIsFilled(SelReservation) And SelShowArrangement Then
		vResourceTableConfiguration = SelReservation.ResourceTableConfiguration;
		If ValueIsFilled(vResourceTableConfiguration) Then
			vPicture = vResourceTableConfiguration.Picture.Get();
			If vPicture <> Undefined Then
				vSpreadsheet.PutHorizontalPageBreak();
				
				vArrangementTemplate = vTemplate.GetArea("Arrangement");
				vArrangementTemplate.Drawings.ArrangementControl.Print = True;
				vArrangementTemplate.Drawings.ArrangementControl.Picture = vPicture;
				vSpreadsheet.Put(vArrangementTemplate);
			EndIf;
		EndIf;
	EndIf;
	
	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Portrait, True);
	// Check authorities
	cmSetSpreadsheetProtection(vSpreadsheet);
	// Get and fill workstation print form settings
	If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
		vWorkstationPrintSettings = SessionParameters.CurrentWorkstation.WorkstationPrintSettings;
		If ValueIsFilled(vWorkstationPrintSettings) Then
			// Try to find records for the current object print form
			vFilter = New Structure("ObjectPrintingForm, IsActive", SelObjectPrintForm, True); 
			vPrintSettingsSet = vWorkstationPrintSettings.PrintFormsList.FindRows(vFilter);
			If vPrintSettingsSet.Count() > 0 Then
				For Each vPrintSettings In vPrintSettingsSet Do
					// Fill settings
					cmSetSpreadsheetSettings(vSpreadsheet, vPrintSettings);
					// Check printing direction
					If vPrintSettings.PrintDirection <> Enums.PrintDirections.Screen Then
						vName = cmGetPrintFormFileName(vPrintSettings, NStr("en='Confirmation';ru='Подтверждение';de='Bestätigung'")) + " " + mGuestGroupCode;
						cmDoSpreadsheetOutput(vSpreadsheet, vPrintSettings, vName, SelLanguage, rDoPrint);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PrintConfirmation

// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Hotel, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
Procedure PrintEventHeader(vSpreadsheet, vTemplate, vLogo, vLogoIsSet, vHotel, SelReservation, SelLanguage, pParameter = "")
	// Header
	vHeader = vTemplate.GetArea("Header");
	vHeaderRemarks = vTemplate.GetArea("HeaderRemarks");
	// Hotel
	mHotelPrintName = Catalogs.Hotels.pmGetHotelPrintName(vHotel, SelLanguage);
	mHotelPostAddressPresentation = Catalogs.Hotels.pmGetHotelPostAddressPresentation(vHotel, SelLanguage);
	mHotelPhones = TrimAll(SelReservation.Hotel.Phones);
	mHotelFax = TrimAll(SelReservation.Hotel.Fax);
	mHotelEMail = TrimAll(SelReservation.Hotel.EMail);
	// Contact person
	mContactPersonName = TrimR(SelReservation.ContactPerson);
	// Customer
	mCustomerLegacyName = "";
	If ValueIsFilled(SelReservation.Customer) Then
		mCustomerLegacyName = TrimAll(SelReservation.Customer.LegacyName);
		If IsBlankString(mCustomerLegacyName) Then
			mCustomerLegacyName = TrimAll(SelReservation.Customer.Description);
		EndIf;
	EndIf;
	// Contract
	mContractDescription = "";
	If ValueIsFilled(SelReservation.Contract) Then
		mContractDescription = TrimAll(SelReservation.Contract.Description);
	EndIf;
	// Phones and E-Mail
	mPhones = "";
	mEMail = "";
	If Not IsBlankString(SelReservation.Phone) Then
		mPhones = mPhones + TrimAll(SelReservation.Phone);
	EndIf;
	If Not IsBlankString(SelReservation.Fax) Then
		mPhones = mPhones + ?(IsBlankString(mPhones), "", ", ") + TrimAll(SelReservation.Fax);
	EndIf;
	If Not IsBlankString(SelReservation.EMail) Then
		mEMail = TrimAll(SelReservation.EMail);
	EndIf;
	If ValueIsFilled(SelReservation.Customer) Then
		If Not IsBlankString(SelReservation.Customer.Phone) Then
			mPhones = mPhones + ?(IsBlankString(mPhones), "", ", ") + TrimAll(SelReservation.Customer.Phone);
		EndIf;
		If Not IsBlankString(SelReservation.Customer.Fax) Then
			mPhones = mPhones + ?(IsBlankString(mPhones), "", ", ") + TrimAll(SelReservation.Customer.Fax);
		EndIf;
		If IsBlankString(mEMail) Then
			mEMail = TrimAll(SelReservation.Customer.EMail);
		EndIf;
	EndIf;
	// Document date
	mDate = Format(SelReservation.Date, "DF='dd.MM.yyyy'");
	// Employee
	mEmployee = "";
	If ValueIsFilled(SelReservation.GuestGroup.Author) Then
		mEmployee = SelReservation.GuestGroup.Author.GetObject().pmGetEmployeeDescription(SelLanguage);
		If Not IsBlankString(SelReservation.GuestGroup.Author.Phones) Then
			mEmployeePhone = SelReservation.GuestGroup.Author.Phones;
		EndIf;
	ElsIf ValueIsFilled(SelReservation.Author) Then
		mEmployee = SelReservation.Author.GetObject().pmGetEmployeeDescription(SelLanguage);
		If Not IsBlankString(SelReservation.Author.Phones) Then
			mEmployeePhone = SelReservation.Author.Phones;
		EndIf;
	EndIf;
	// Guest group
	mGuestGroupClient = "";
	If ValueIsFilled(SelReservation.GuestGroup.Client) Then
		mGuestGroupClient = TrimAll(SelReservation.GuestGroup.Client.FullName);
	ElsIf Not ValueIsFilled(SelReservation.GuestGroup.Customer) And Not ValueIsFilled(SelReservation.Customer) Then
		mGuestGroupClient = cmNStr("en='Private person';ru='Частное лицо';de='Privatperson'", SelLanguage);
	EndIf;
	mGuestGroupCode = TrimAll(SelReservation.GuestGroup.Code);
	vHotelPrefix = Catalogs.Hotels.pmGetPrefix(SelReservation.Hotel);
	If Not IsBlankString(vHotelPrefix) And SelReservation.Hotel.ShowHotelPrefixBeforeGroupCode Then
		mGuestGroupCode = vHotelPrefix + mGuestGroupCode;
	EndIf;
	mGuestGroupCheckInDate = Undefined;
	mGuestGroupCheckOutDate = Undefined;
	If ValueIsFilled(SelReservation.GuestGroup.CheckInDate) Then
		mGuestGroupCheckInDate = SelReservation.GuestGroup.CheckInDate;
		mGuestGroupCheckOutDate = SelReservation.GuestGroup.CheckOutDate;
	Else
		mGuestGroupCheckInDate = SelReservation.DateTimeFrom;
		mGuestGroupCheckOutDate = SelReservation.DateTimeTo;
	EndIf;
	mGuestGroupDescription = TrimAll(SelReservation.GuestGroup.Description);
	mGuestGroupRemarks = "";
	vPlannedPaymentMethod = "";
	If ValueIsFilled(SelReservation.PlannedPaymentMethod) Then
		vPlannedPaymentMethod = SelReservation.PlannedPaymentMethod.GetObject().pmGetPaymentMethodDescription(SelLanguage);
	EndIf;
	If Not IsBlankString(vPlannedPaymentMethod) Then
		If Find(pParameter, "SHOW_PLANNED_PAYMENT_METHOD") > 0 Then
			mGuestGroupRemarks = cmNStr("en='Payment method is: ';ru='Тип оплаты: ';de='Art der Bezahlung: '", SelLanguage) + vPlannedPaymentMethod + Chars.LF;
		EndIf;
	EndIf;
	mGuestGroupRemarks = mGuestGroupRemarks + TrimAll(SelReservation.GuestGroup.Remarks);
	// Set parameters and put report section
	vHeader.Parameters.mHotelPrintName = mHotelPrintName;
	vHeader.Parameters.mHotelPostAddressPresentation = mHotelPostAddressPresentation;
	vHeader.Parameters.mHotelPhones = mHotelPhones;
	vHeader.Parameters.mHotelFax = mHotelFax;
	vHeader.Parameters.mHotelEMail = mHotelEMail;
	vHeader.Parameters.mContactPersonName = mContactPersonName;
	vHeader.Parameters.mCustomerLegacyName = mCustomerLegacyName;
	vHeader.Parameters.mContractDescription = mContractDescription;
	vHeader.Parameters.mFax = mPhones;
	vHeader.Parameters.mEMail = mEMail;
	vHeader.Parameters.mEmployee = mEmployee;
	vHeader.Parameters.mEmployeePhone = mEmployeePhone;
	vHeader.Parameters.mGuestGroup = SelReservation.GuestGroup;
	vHeader.Parameters.mGuestGroupCode = mGuestGroupCode;
	vHeader.Parameters.mGuestGroupClient = mGuestGroupClient;
	vHeader.Parameters.mGuestGroupCheckInDate = mGuestGroupCheckInDate;
	vHeader.Parameters.mGuestGroupCheckOutDate = mGuestGroupCheckOutDate;
	vHeader.Parameters.mGuestGroupDescription = mGuestGroupDescription;
	// Logo
	If vLogoIsSet Then
		vHeader.Drawings.Logo.Print = True;
		vHeader.Drawings.Logo.Picture = vLogo;
	Else
		vHeader.Drawings.Delete(vHeader.Drawings.Logo);
	EndIf;
	// Put header		
	vSpreadsheet.Put(vHeader);
	// Put header remarks
	vRemarksLines = cmGetTextLinesArray(mGuestGroupRemarks);
	For Each vRemarksLine In vRemarksLines Do
		vHeaderRemarks.Parameters.mGuestGroupRemarks = TrimR(vRemarksLine);
		// Put remarks line
		vSpreadsheet.Put(vHeaderRemarks);
	EndDo;
EndProcedure // PrintEventHeader

// -----------------------------------------------------------------------------
Function GetTasks(pDocument)
	vQ = New Query("SELECT
	|	Message.ForDepartment,
	|	Message.Ref
	|FROM
	|	Document.Message AS Message
	|WHERE
	|	(Message.ByObject = &qRes 
	|	 OR Message.ByObject = &qGuestGroup)
	//|	AND Message.ForDepartment <> VALUE(Catalog.Departments.EmptyRef)
	|	AND Message.Posted
	|ORDER BY
	|	ForDepartment
	| ");
	vQ.SetParameter("qRes", pDocument);
	vQ.SetParameter("qGuestGroup", pDocument.GuestGroup);  
	vQRes = vQ.Execute().Unload();
	Return vQRes;	
EndFunction

#EndRegion
