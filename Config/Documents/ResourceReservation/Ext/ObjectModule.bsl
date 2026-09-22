Var ChargesToRepostStorno;

#Region Public

// -----------------------------------------------------------------------------
Procedure pmWriteToResourceReservationChangeHistory(pPeriod, pUser) Export
	// Get channges description
	vChanges = cmGetObjectChanges(ThisObject);
	If Not IsBlankString(vChanges) Then
		// Do movement on current date
		vRChgRec = InformationRegisters.ResourceReservationChangeHistory.CreateRecordManager();
		
		FillRChgAttributes(vRChgRec, pPeriod, pUser);
		vRChgRec.Changes = vChanges;
		
		// Write record
		vRChgRec.Write(True);  
		
		// User activity history
		InformationRegisters.UserActionsHistory.WriteUserActivityRecord(Ref, vChanges, Hotel, pUser, pPeriod);
	EndIf;
EndProcedure // pmWriteToResourceReservationChangeHistory

// -----------------------------------------------------------------------------
Procedure pmRestoreAttributesFromHistory(pRChgRec) Export
	FillPropertyValues(ThisObject, pRChgRec, , "Number, Date, Author");
	If Not IsBlankString(pRChgRec.Number) Then
		Number = pRChgRec.Number;
	EndIf;
	If ValueIsFilled(pRChgRec.Date) Then
		Date = pRChgRec.Date;
	EndIf;
	If ValueIsFilled(pRChgRec.Author) Then
		Author = pRChgRec.Author;
	EndIf;
	// Restore tabular parts
	vServicePackages = pRChgRec.ServicePackages.Get();
	If vServicePackages <> Undefined Then
		ServicePackages.Load(vServicePackages);
	Else
		ServicePackages.Clear();
	EndIf;
	vServices = pRChgRec.Services.Get();
	If vServices <> Undefined Then
		Services.Load(vServices);
	Else
		Services.Clear();
	EndIf;
EndProcedure // pmRestoreAttributesFromHistory

// -----------------------------------------------------------------------------
Function pmGetPreviousObjectState(pPeriod) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	*
	|FROM
	|	InformationRegister.ResourceReservationChangeHistory.SliceLast(&qPeriod, ResourceReservation = &qDoc) AS ResourceReservationChangeHistory";
	vQry.SetParameter("qPeriod", pPeriod);
	vQry.SetParameter("qDoc", Ref);
	vStates = vQry.Execute().Unload();
	If vStates.Count() > 0 Then
		Return vStates.Get(0);
	Else
		Return Undefined;
	EndIf;
EndFunction // pmGetPreviousObjectState

// -----------------------------------------------------------------------------
Function pmCheckDocumentAttributes(pIsPosted, pMessage, pAttributeInErr, pDoNotCheckRests = False) Export
	vHasErrors = False;
	pMessage = "";
	pAttributeInErr = "";
	vMsgTextRu = "";
	vMsgTextEn = "";
	vMsgTextDe = "";
	If AdditionalProperties.Property("InfoBaseUpdateMode") And AdditionalProperties.InfoBaseUpdateMode Then
		Return vHasErrors;
	EndIf;
	vIsResourceBlock = False;
	If ValueIsFilled(EventActivity) And 
	   TypeOf(EventActivity) = Type("CatalogRef.EventActivities") Then
		vIsResourceBlock = EventActivity.IsResourceBlock;
	EndIf;
	If Not ValueIsFilled(Hotel) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Гостиница> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Hotel> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Hotel> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Hotel", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(Company) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Фирма> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Company> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Company> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Company", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(ExchangeRateDate) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Дата курса> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Exchange rate date> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Exchange rate date> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "ExchangeRateDate", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(ReportingCurrency) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Отчетная валюта> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Reporting currency> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Reporting currency> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "ReportingCurrency", pAttributeInErr);
	EndIf;
	If ReportingCurrencyExchangeRate <= 0 Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Курс отчетной валюты> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Reporting currency exchange rate> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Reporting currency exchange rate> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "ReportingCurrencyExchangeRate", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(GuestGroup) And Not vIsResourceBlock Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Номер группы> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Guest group> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Guest group> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "GuestGroup", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(ResourceReservationStatus) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Статус брони> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Reservation status> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Reservation status> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "ResourceReservationStatus", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(ChargingFolio) And Not vIsResourceBlock Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Лицевой счет> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Folio> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Folio> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "ChargingFolio", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(FolioCurrency) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Валюта лицевого счета> должна быть заполнена!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Folio currency> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Folio currency> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "FolioCurrency", pAttributeInErr);
	EndIf;
	If FolioCurrencyExchangeRate = 0 Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Курс валюты лицевого счета> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Folio currency exchange rate> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Folio currency exchange rate> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "FolioCurrencyExchangeRate", pAttributeInErr);
	EndIf;
	If ValueIsFilled(DateTimeFrom) And ValueIsFilled(DateTimeTo) Then
		If Not ValueIsFilled(Resource) And cm0SecondShift(DateTimeFrom) > cm0SecondShift(DateTimeTo) Or 
		   ValueIsFilled(Resource) And DateTimeFrom > DateTimeTo Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Время окончания брони должно быть позже времени начала брони!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "Reservation period to should be after reservation period from time!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "Reservation period to should be after reservation period from time!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "DateTimeTo", pAttributeInErr);
		EndIf;
	EndIf;
	If Not vHasErrors And Not (AdditionalProperties.Property("CloseOfDayMode") And AdditionalProperties.CloseOfDayMode) Then
		If ValueIsFilled(DateTimeFrom) And ValueIsFilled(DateTimeTo) Then
			If ValueIsFilled(Contract) Then
				If Contract.PeriodCheckType = 0 Then
					If ValueIsFilled(Contract.ValidFromDate) And 
					   DateTimeFrom < BegOfDay(Contract.ValidFromDate) Or
					   ValueIsFilled(Contract.ValidToDate) And
					   DateTimeFrom > EndOfDay(Contract.ValidToDate) Then
						vHasErrors = True; 
						vMsgTextRu = vMsgTextRu + "Выбранный договор не действует на указанном периоде брони!" + Chars.LF;
						vMsgTextEn = vMsgTextEn + "Contract is not valid on period selected!" + Chars.LF;
						vMsgTextDe = vMsgTextDe + "Contract is not valid on period selected!" + Chars.LF;
						pAttributeInErr = ?(pAttributeInErr = "", "Contract", pAttributeInErr);
					EndIf;
				ElsIf Contract.PeriodCheckType = 1 Then
					If ValueIsFilled(Contract.ValidFromDate) And 
					   Date < BegOfDay(Contract.ValidFromDate) Or
					   ValueIsFilled(Contract.ValidToDate) And
					   Date > EndOfDay(Contract.ValidToDate) Then
						vHasErrors = True; 
						vMsgTextRu = vMsgTextRu + "Выбранный договор не действует на дату создания брони!" + Chars.LF;
						vMsgTextEn = vMsgTextEn + "Contract is not valid on reservation creation date!" + Chars.LF;
						vMsgTextDe = vMsgTextDe + "Contract is not valid on reservation creation date!" + Chars.LF;
						pAttributeInErr = ?(pAttributeInErr = "", "Contract", pAttributeInErr);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(ClientType) And ClientType.CustomerIsMandatory And Not ValueIsFilled(Customer) Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Реквизит <Заказчик> должен быть заполнен для типа клиента " + TrimAll(ClientType) + "!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "<Customer> attribute should be filled for client type " + TrimAll(ClientType) + "!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "Das Attribut <Firma> sollte für den Kundentyp ausgefüllt werden " + TrimAll(ClientType) + "!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "Customer", pAttributeInErr);
		EndIf;
		If ValueIsFilled(ResourceReservationStatus) Then
			If ResourceReservationStatus.IsActive Then
				// Check resource availability
				If ValueIsFilled(Resource) And Not pDoNotCheckRests Then
					// Check resource
					If Not vHasErrors Then
						If Not cmCheckResourceAvailability(Resource, Ref, pIsPosted, 
														   DateTimeFrom, cm0SecondShift(DateTimeTo), vMsgTextRu, vMsgTextEn, vMsgTextDe, IsShareable, NumberOfPersons) Then
							vHasErrors = True; 
							pAttributeInErr = ?(pAttributeInErr = "", "DateTimeFrom", pAttributeInErr);
						EndIf;
					EndIf;
					// Check child resources
					If Not vHasErrors Then
						vChildren = Resource.GetObject().pmGetResourceChildren();
						For Each vChildrenRow In vChildren Do
							If Not cmCheckResourceAvailability(vChildrenRow.Resource, Ref, pIsPosted, 
															   DateTimeFrom, cm0SecondShift(DateTimeTo), vMsgTextRu, vMsgTextEn, vMsgTextDe, IsShareable, NumberOfPersons) Then
								vHasErrors = True; 
								pAttributeInErr = ?(pAttributeInErr = "", "DateTimeFrom", pAttributeInErr);
							EndIf;
						EndDo;
					EndIf;
					// Check parent resource
					If Not vHasErrors Then
						vParentResource = Resource.Parent;
						If ValueIsFilled(vParentResource) Then
							If Not cmCheckResourceAvailability(vParentResource, Ref, pIsPosted, 
															   DateTimeFrom, cm0SecondShift(DateTimeTo), vMsgTextRu, vMsgTextEn, vMsgTextDe, IsShareable, NumberOfPersons) Then
								vHasErrors = True; 
								pAttributeInErr = ?(pAttributeInErr = "", "DateTimeFrom", pAttributeInErr);
							EndIf;
						EndIf;
					EndIf;
				EndIf;
				// Check services
				If Not pDoNotCheckRests Then
					For Each vSrvRow In Services Do
						If ValueIsFilled(vSrvRow.ServiceResource) And TypeOf(vSrvRow.ServiceResource) = Type("CatalogRef.Resources") And vSrvRow.DoResourceReservation Then
							vDateTimeFrom = vSrvRow.AccountingDate + (vSrvRow.TimeFrom - BegOfDay(vSrvRow.TimeFrom));
							vDateTimeTo = cm0SecondShift(vSrvRow.AccountingDate + (vSrvRow.TimeTo - BegOfDay(vSrvRow.TimeTo)));
							// Check service resource
							If Not vHasErrors Then
								If Not cmCheckResourceAvailability(vSrvRow.ServiceResource, Ref, pIsPosted, 
																   vDateTimeFrom, vDateTimeTo, vMsgTextRu, vMsgTextEn, vMsgTextDe, vSrvRow.IsShareable, vSrvRow.NumberOfPersons) Then
									vHasErrors = True; 
									pAttributeInErr = ?(pAttributeInErr = "", "Services", pAttributeInErr);
								EndIf;
							EndIf;
							// Check child resources
							If Not vHasErrors Then
								vChildren = vSrvRow.ServiceResource.GetObject().pmGetResourceChildren();
								For Each vChildrenRow In vChildren Do
									If Not cmCheckResourceAvailability(vChildrenRow.Resource, Ref, pIsPosted, 
																	   vDateTimeFrom, vDateTimeTo, vMsgTextRu, vMsgTextEn, vMsgTextDe, vSrvRow.IsShareable, vSrvRow.NumberOfPersons) Then
										vHasErrors = True; 
										pAttributeInErr = ?(pAttributeInErr = "", "Services", pAttributeInErr);
									EndIf;
								EndDo;
							EndIf;
							// Check parent resource
							If Not vHasErrors Then
								vParentResource = vSrvRow.ServiceResource.Parent;
								If ValueIsFilled(vParentResource) Then
									If Not cmCheckResourceAvailability(vParentResource, Ref, pIsPosted, 
																	   vDateTimeFrom, vDateTimeTo, vMsgTextRu, vMsgTextEn, vMsgTextDe, vSrvRow.IsShareable, vSrvRow.NumberOfPersons) Then
										vHasErrors = True; 
										pAttributeInErr = ?(pAttributeInErr = "", "Services", pAttributeInErr);
									EndIf;
								EndIf;
							EndIf;
						EndIf;
					EndDo;
				EndIf;
			EndIf;
		EndIf;
		// Check services
		For Each vSrvRow In Services Do
			If vSrvRow.Quantity = 0 Then
				Continue;
			EndIf;
			If vSrvRow.Price <> 0 And vSrvRow.Sum = 0 Then
				vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "В строке услуг №" + Format(vSrvRow.LineNumber, "ND=10; NFD=0; NG=") + " указана цена, но не рассчитана сума услуги!" + Chars.LF;
				vMsgTextEn = vMsgTextEn + "Service with line number " + Format(vSrvRow.LineNumber, "ND=10; NFD=0; NG=") + " has price but service amount is not calculated!" + Chars.LF;
				vMsgTextDe = vMsgTextDe + "Service with line number " + Format(vSrvRow.LineNumber, "ND=10; NFD=0; NG=") + " has price but service amount is not calculated!" + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "Services", pAttributeInErr);
				Break;
			EndIf;
		EndDo;
	Endif;
	If vHasErrors Then
		pMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // pmCheckDocumentAttributes

// -----------------------------------------------------------------------------
Procedure pmInitializePeriod() Export
	If Not ValueIsFilled(DateTimeFrom) Then
		DateTimeFrom = (BegOfDay(Date) + 1) + 12*3600; // + 1 day
	EndIf;
	If Not ValueIsFilled(DateTimeTo) Then
		DateTimeTo = Date(Year(DateTimeFrom), Month(DateTimeFrom), Day(DateTimeFrom), 
							Hour(DateTimeFrom), Minute(DateTimeFrom), 0) + Duration*3600;
	EndIf;
EndProcedure // pmInitializePeriod

// -----------------------------------------------------------------------------
// Calculates and returns duration for giving reservation start and end times
// -----------------------------------------------------------------------------
Function pmCalculateDuration() Export
	Return cmCalculateDurationInHours(DateTimeFrom, DateTimeTo);
EndFunction // pmCalculateDuration

// -----------------------------------------------------------------------------
// Calculates and returns check out date based on giving duration and check in date
// -----------------------------------------------------------------------------
Function pmCalculateDateTimeTo() Export
	vDateTimeTo = cm0SecondShift(DateTimeTo);
	If ValueIsFilled(DateTimeFrom) Then
		vDateTimeTo = cm0SecondShift(DateTimeFrom + Duration*3600);
	EndIf;
	Return vDateTimeTo;
EndFunction // pmCalculateDateTimeTo

// -----------------------------------------------------------------------------
Procedure pmFillAuthorAndDate() Export
	Date = CurrentSessionDate();
	Author = SessionParameters.CurrentUser;
EndProcedure // pmFillAuthorAndDate

// -----------------------------------------------------------------------------
Procedure pmCreateGuestGroup(pAllotment = Undefined) Export
	vIsResourceBlock = False;
	If ValueIsFilled(EventActivity) And 
	   TypeOf(EventActivity)= Type("CatalogRef.EventActivities") Then
		vIsResourceBlock = EventActivity.IsResourceBlock;
	EndIf;
	If vIsResourceBlock Then
		Return;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If Not Hotel.AssignReservationGuestGroupsManually Then
			vGuestGroupObj = Catalogs.GuestGroups.CreateItem();
			vGuestGroupObj.GroupType = Catalogs.GroupTypes.Resources;
			vGuestGroupObj.Owner = Hotel;
			vGuestGroupFolder = Hotel.GetObject().pmGetGuestGroupFolder();
			If ValueIsFilled(vGuestGroupFolder) Then
				vGuestGroupObj.Parent = vGuestGroupFolder;
				vGuestGroupObj.SetNewCode();
			EndIf;
			vGuestGroupObj.OneCustomerPerGuestGroup = Hotel.OneCustomerPerGuestGroup;
			If ValueIsFilled(pAllotment) Then
				vGuestGroupObj.Allotment = pAllotment;
				If ValueIsFilled(pAllotment.Customer) Then
					vGuestGroupObj.Customer = pAllotment.Customer;
				EndIf;
			EndIf;
			vGuestGroupObj.Write();
			// Fill document attribute
			GuestGroup = vGuestGroupObj.Ref;
		EndIf;
	EndIf;
EndProcedure // pmCreateGuestGroup

// -----------------------------------------------------------------------------
Procedure pmCreateFolio() Export
	vIsResourceBlock = False;
	If ValueIsFilled(EventActivity) And 
	   TypeOf(EventActivity)= Type("CatalogRef.EventActivities") Then
		vIsResourceBlock = EventActivity.IsResourceBlock;
	EndIf;
	If vIsResourceBlock And ValueIsFilled(Hotel) Then
		FolioCurrency = Hotel.FolioCurrency;
		FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, FolioCurrency, ?(ValueIsFilled(ExchangeRateDate), ExchangeRateDate, Date));
		Return;
	EndIf;
	// Check if resource is filled and check resource template folio
	vTemplateFolio = Documents.Folio.EmptyRef();
	If ValueIsFilled(Resource) And ValueIsFilled(Resource.TemplateFolio) Then
		vTemplateFolio = Resource.TemplateFolio;
	ElsIf ValueIsFilled(ResourceType) And ValueIsFilled(ResourceType.TemplateFolio) Then
		vTemplateFolio = ResourceType.TemplateFolio;
	EndIf;
	If ValueIsFilled(vTemplateFolio) Then
		vIsTemplate = Not vTemplateFolio.IsMaster;
		If vIsTemplate Then
			// Create new folio from template
			vFolioObj = Documents.Folio.CreateDocument();
			cmFillFolioFromTemplate(vFolioObj, vTemplateFolio, Hotel, Date);
			vFolioObj.ParentDoc = Ref;
			vFolioObj.Write(DocumentWriteMode.Write);
			
			// Fill document charging folio
			ChargingFolio = vFolioObj.Ref;
			FolioCurrency = vFolioObj.FolioCurrency;
			FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, FolioCurrency, ?(ValueIsFilled(ExchangeRateDate), ExchangeRateDate, Date));
		Else
			// Fill document charging folio
			ChargingFolio = vTemplateFolio;
			FolioCurrency = vTemplateFolio.FolioCurrency;
			FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, FolioCurrency, ?(ValueIsFilled(ExchangeRateDate), ExchangeRateDate, Date));
		EndIf;
		Return;
	EndIf;
	// Take hotel charging rules
	vChargingRules = Undefined;
	If ValueIsFilled(Hotel) Then
		If Hotel.ChargingRules.Count() > 0 Then
			vChargingRules = Hotel.ChargingRules.Unload();
		EndIf;
	EndIf;
	// Check list of template rules
	If vChargingRules = Undefined Then
		// Create new folio and take parameters from the hotel
		vFolioObj = Documents.Folio.CreateDocument();
		cmFillFolioFromTemplate(vFolioObj, Undefined, Hotel, Date);
		vFolioObj.ParentDoc = Ref;
		vFolioObj.Write(DocumentWriteMode.Write);
		
		// Fill document charging folio
		ChargingFolio = vFolioObj.Ref;
		FolioCurrency = vFolioObj.FolioCurrency;
		FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, FolioCurrency, ?(ValueIsFilled(ExchangeRateDate), ExchangeRateDate, Date));
	Else
		For Each vRule In vChargingRules Do
			vIsTemplate = True;
			vTemplateFolio = vRule.ChargingFolio;
			If ValueIsFilled(vTemplateFolio) Then
				vIsTemplate = Not vTemplateFolio.IsMaster;
			EndIf;
			If vIsTemplate Then
				// Create new folio from template
				vFolioObj = Documents.Folio.CreateDocument();
				cmFillFolioFromTemplate(vFolioObj, vTemplateFolio, Hotel, Date);
				vFolioObj.ParentDoc = Ref;
				vFolioObj.Write(DocumentWriteMode.Write);
				
				// Fill document charging folio
				ChargingFolio = vFolioObj.Ref;
				FolioCurrency = vFolioObj.FolioCurrency;
				FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, FolioCurrency, ?(ValueIsFilled(ExchangeRateDate), ExchangeRateDate, Date));
			Else
				// Fill document charging folio
				ChargingFolio = vRule.ChargingFolio;
				FolioCurrency = vRule.ChargingFolio.FolioCurrency;
				FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, FolioCurrency, ?(ValueIsFilled(ExchangeRateDate), ExchangeRateDate, Date));
			EndIf;
			Break;
		EndDo;
	EndIf;
EndProcedure // pmCreateFolio

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues(pAllotment = Undefined) Export
	// Fill author and document date
	pmFillAuthorAndDate();
	// Fill from session parameters
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If Not ValueIsFilled(Company) Then
			Company = Hotel.Company;
		EndIf;
		If ValueIsFilled(Author) And ValueIsFilled(Author.Company) Then
			Company = Author.Company;
		EndIf;
		If Not ValueIsFilled(ResourceReservationStatus) Then
			ResourceReservationStatus = Hotel.NewResourceReservationStatus;
			If ValueIsFilled(ResourceReservationStatus) Then
				DoCharging = ResourceReservationStatus.DoCharging;
			EndIf;
		EndIf;
		If Not ValueIsFilled(ResourceTariff) And ValueIsFilled(Hotel.ResourceTariff) Then
			ResourceTariff = Hotel.ResourceTariff;
		EndIf;
		If Not ValueIsFilled(PlannedPaymentMethod) Then
			PlannedPaymentMethod = Hotel.PlannedPaymentMethod;
		EndIf;
		If Not ValueIsFilled(ReportingCurrency) Then
			ReportingCurrency = Hotel.ReportingCurrency;
		EndIf;
		If Not ValueIsFilled(Owner) Then
			If ValueIsFilled(Hotel.IndividualsContract) Then
				Owner = Hotel.IndividualsContract;
			ElsIf ValueIsFilled(Hotel.IndividualsCustomer) Then
				Owner = Hotel.IndividualsCustomer;
			EndIf;
		EndIf;
		ReportingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, ReportingCurrency, Date);
		// Initialize document period
		pmInitializePeriod();
	EndIf;
	If Not ValueIsFilled(ExchangeRateDate) Then
		ExchangeRateDate = Date;
	EndIf;
	vIsResourceBlock = False;
	If ValueIsFilled(EventActivity) And 
	   TypeOf(EventActivity) = Type("CatalogRef.EventActivities") Then
		vIsResourceBlock = EventActivity.IsResourceBlock;
	EndIf;
	// Create guest group if is new
	If Not ValueIsFilled(GuestGroup) Then
		If Not vIsResourceBlock Then
			pmCreateGuestGroup(pAllotment);
		EndIf;
	ElsIf ValueIsFilled(pAllotment) And pAllotment <> GuestGroup.Allotment Then
		vGuestGroupObj = GuestGroup.GetObject();
		vGuestGroupObj.Allotment = pAllotment;
		If ValueIsFilled(pAllotment.Customer) Then
			vGuestGroupObj.Customer = pAllotment.Customer;
		EndIf;
		vGuestGroupObj.Write();
	EndIf;
	// Create charging folio if is new
	If Not ValueIsFilled(ChargingFolio) Then
		If ValueIsFilled(GuestGroup) Then
			vFirstRR = GetFirstResourceReservationOfTheGroup();
			If ValueIsFilled(vFirstRR) And ValueIsFilled(vFirstRR.ChargingFolio) Then
				ChargingFolio = vFirstRR.ChargingFolio;
				FolioCurrency = ChargingFolio.FolioCurrency;
				If Not ValueIsFilled(ExchangeRateDate) Then
					If ValueIsFilled(Date) Then
						ExchangeRateDate = BegOfDay(Date);
					Else
						ExchangeRateDate = BegOfDay(CurrentSessionDate());
					EndIf;
				EndIf;
				FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, FolioCurrency, ExchangeRateDate);
			EndIf;
		EndIf;
	EndIf;
	If Not ValueIsFilled(ChargingFolio) Then
		pmCreateFolio();
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function GetFirstResourceReservationOfTheGroup()
	vDoc = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	ResourceReservations.Ref AS Ref
	|FROM
	|	Document.ResourceReservation AS ResourceReservations
	|WHERE
	|	ResourceReservations.GuestGroup = &qGuestGroup
	|	AND (ResourceReservations.ResourceReservationStatus.IsActive
	|			OR ResourceReservations.ResourceReservationStatus.ServicesAreDelivered)
	|	AND ResourceReservations.Posted
	|
	|ORDER BY
	|	ResourceReservations.DateTimeFrom,
	|	ResourceReservations.PointInTime";
	vQry.SetParameter("qGuestGroup", GuestGroup);
	vDocs = vQry.Execute().Unload();
	If vDocs.Count() > 0 Then
		vDoc = vDocs.Get(0).Ref;
	EndIf;
	Return vDoc;
EndFunction // GetFirstResourceReservationOfTheGroup

// -----------------------------------------------------------------------------
Function pmGetAccumulatingDiscountResources() Export
	// Initialize map with resources
	vRes = New ValueTable();
	vRes.Columns.Add("DiscountType", cmGetCatalogTypeDescription("DiscountTypes"), "Discount type", 20);
	vRes.Columns.Add("DiscountDimension", cmGetDiscountDimensionTypeDescription(), "Discount dimension", 20);
	vRes.Columns.Add("Resource", cmGetAccumulatingDiscountResourceTypeDescription(), "Discount resource", 20);
	vRes.Columns.Add("Bonus", cmGetAccumulatingDiscountResourceTypeDescription(), "Bonus", 20);
	// Get list of accumulating discount types defined in the catalog
	vDiscountType = Undefined;
	If ValueIsFilled(DiscountType) And DiscountType.IsAccumulatingDiscount Then
		vDiscountType = DiscountType;
	EndIf;
	vAccDisTypes = cmGetAccumulatingDiscountTypes(vDiscountType, Hotel);
	// Get resources
	For Each vAccDisType In vAccDisTypes Do
		vDiscountType = vAccDisType.DiscountType;
		vDiscountTypeObj = vDiscountType.GetObject();
		vAccDisRes = vDiscountTypeObj.pmGetAccumulatingDiscountResources(BegOfDay(DateTimeFrom),
		                                                                 Customer,
		                                                                 Contract,
		                                                                 Client,
		                                                                 DiscountCard,
		                                                                 ?(vDiscountType.IsPerVisit, GuestGroup, Undefined));
		If vAccDisRes.Count() = 0 Then
			vResRow = vRes.Add();
			vResRow.DiscountType = vDiscountType;
			vResRow.DiscountDimension = vDiscountTypeObj.pmGetDefaultAccumulatingDiscountDimension();
			vResRow.Resource = 0;
			vResRow.Bonus = 0;
		Else
			For Each vAccDis In vAccDisRes Do
				vResRow = vRes.Add();
				vResRow.DiscountType = vAccDis.DiscountType;
				vResRow.DiscountDimension = vAccDis.DiscountDimension;
				vResRow.Resource = vAccDis.Resource;
				vResRow.Bonus = vAccDis.Bonus;
			EndDo;
		EndIf;
	EndDo;
	// Return
	Return vRes;
EndFunction // pmGetAccumulatingDiscountResources

// -----------------------------------------------------------------------------
// Get reservation prices for all day types of room rate
// -----------------------------------------------------------------------------
Function pmCalculatePricePresentation(Val pLang = Undefined) Export
	vPricePresentation = "";
	If pLang = Undefined Then
		pLang = SessionParameters.CurrentLanguage;
	EndIf;
	vPrices = pmGetPrices();
	If ValueIsFilled(Hotel) And Hotel.UseMaximumPriceInPricePresentation Then
		vMaxPrice = 0;
		For Each vPrice In vPrices Do
			If vPrice.Price > vMaxPrice Then
				vMaxPrice = vPrice.Price;
			EndIf;
		EndDo;
		vPricePresentation = cmFormatSum(vMaxPrice, FolioCurrency, "NZ=---", pLang);
	Else
		For Each vPrice In vPrices Do
			If Not IsBlankString(vPricePresentation) Then
				vPricePresentation = vPricePresentation + Chars.LF;
			EndIf;
			vPricePresentation = vPricePresentation + cmFormatSum(vPrice.Price, FolioCurrency, "NZ=---", pLang) + 
			                     ?(ValueIsFilled(vPrice.CalendarDayType), " - " + vPrice.CalendarDayType.GetObject().pmGetDayTypeDescription(pLang), "");
		EndDo;
	EndIf;
	// Check length of price presentation
	If StrLen(vPricePresentation) > 250 Then
		vPricePresentation = Left(vPricePresentation, 247) + "...";
	EndIf;
	// Return
	Return vPricePresentation;
EndFunction // pmCalculatePricePresentation

// -----------------------------------------------------------------------------
Function pmGetComplexCommission() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	CommissionSliceLast.Period AS SliceLastPeriod,
	|	CommissionSliceLast.Agent AS SliceLastAgent,
	|	CommissionSliceLast.Contract AS SliceLastContract,
	|	CommissionSliceLast.ServiceGroup AS SliceLastServiceGroup,
	|	CommissionSliceLast.RoomClass AS SliceLastRoomClass,
	|	CommissionSliceLast.RoomType AS SliceLastRoomType,
	|	CommissionSliceLast.Hotel AS SliceLastHotel,
	|	CommissionSliceLast.Commission AS SliceLastCommission,
	|	CommissionSliceLast.CommissionType AS SliceLastCommissionType
	|INTO CommissionSliceLast
	|FROM
	|	InformationRegister.Commission.SliceLast(
	|			&qPeriodFrom,
	|			Agent = &qAgent
	|				AND Contract = &qContract
	|				AND (Hotel = &qHotel
	|					OR Hotel = &qEmptyHotel)) AS CommissionSliceLast
	|
	|ORDER BY
	|	SliceLastPeriod DESC,
	|	CommissionSliceLast.ServiceGroup.Code
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Commissions.Period AS Period,
	|	Commissions.Agent AS Agent,
	|	Commissions.Contract AS Contract,
	|	Commissions.ServiceGroup AS ServiceGroup,
	|	Commissions.RoomClass AS RoomClass,
	|	Commissions.RoomType AS RoomType,
	|	Commissions.Hotel AS Hotel,
	|	Commissions.Commission AS Commission,
	|	Commissions.CommissionType AS CommissionType
	|FROM
	|	(SELECT
	|		ComplexCommission.Period AS Period,
	|		ComplexCommission.Agent AS Agent,
	|		ComplexCommission.Contract AS Contract,
	|		ComplexCommission.ServiceGroup AS ServiceGroup,
	|		ComplexCommission.RoomClass AS RoomClass,
	|		ComplexCommission.RoomType AS RoomType,
	|		ComplexCommission.Hotel AS Hotel,
	|		ComplexCommission.Commission AS Commission,
	|		ComplexCommission.CommissionType AS CommissionType
	|	FROM
	|		InformationRegister.Commission AS ComplexCommission
	|			INNER JOIN CommissionSliceLast AS CommissionSliceLast
	|			ON ComplexCommission.Period = CommissionSliceLast.SliceLastPeriod
	|				AND ComplexCommission.Agent = CommissionSliceLast.SliceLastAgent
	|				AND ComplexCommission.Contract = CommissionSliceLast.SliceLastContract
	|				AND ComplexCommission.Hotel = CommissionSliceLast.SliceLastHotel
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ComplexCommissionChanges.Period,
	|		ComplexCommissionChanges.Agent,
	|		ComplexCommissionChanges.Contract,
	|		ComplexCommissionChanges.ServiceGroup,
	|		ComplexCommissionChanges.RoomClass,
	|		ComplexCommissionChanges.RoomType,
	|		ComplexCommissionChanges.Hotel,
	|		ComplexCommissionChanges.Commission,
	|		ComplexCommissionChanges.CommissionType
	|	FROM
	|		InformationRegister.Commission AS ComplexCommissionChanges
	|	WHERE
	|		ComplexCommissionChanges.Period > &qPeriodFrom
	|		AND ComplexCommissionChanges.Period < &qPeriodTo
	|		AND ComplexCommissionChanges.Agent = &qAgent
	|		AND ComplexCommissionChanges.Contract = &qContract
	|		AND (ComplexCommissionChanges.Hotel = &qHotel
	|				OR ComplexCommissionChanges.Hotel = &qEmptyHotel)) AS Commissions
	|
	|ORDER BY
	|	Commissions.Period DESC,
	|	ISNULL(Commissions.RoomClass.SortCode, 0) DESC,
	|	ISNULL(Commissions.RoomType.SortCode, 0) DESC,
	|	Commissions.ServiceGroup.Code";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qAgent", Agent);
	vQry.SetParameter("qContract", Contract);
	vQry.SetParameter("qPeriodFrom", DateTimeFrom);
	vQry.SetParameter("qPeriodTo", DateTimeTo);
	vComplexCommission = vQry.Execute().Unload();
	Return vComplexCommission;
EndFunction // pmGetComplexCommission

// -----------------------------------------------------------------------------
Procedure pmMoveToNewDate(pAccountingDate) Export
	vOldDateTimeFrom = DateTimeFrom;
	vShiftInSeconds = BegOfDay(pAccountingDate) - BegOfDay(DateTimeFrom);
	DateTimeFrom = BegOfDay(pAccountingDate) + (DateTimeFrom - BegOfDay(DateTimeFrom));
	DateTimeTo = DateTimeFrom + (DateTimeTo - vOldDateTimeFrom);
	For Each vSrvRow In Services Do
		If ValueIsFilled(vSrvRow.AccountingDate) Then
			vSrvRow.AccountingDate = vSrvRow.AccountingDate + vShiftInSeconds;
		EndIf;
		If ValueIsFilled(vSrvRow.DateTimeFrom) Then
			vSrvRow.DateTimeFrom = vSrvRow.DateTimeFrom + vShiftInSeconds;
		EndIf;
		If ValueIsFilled(vSrvRow.DateTimeTo) Then
			vSrvRow.DateTimeTo = vSrvRow.DateTimeTo + vShiftInSeconds;
		EndIf;
	EndDo;
	pmCalculateServices();
EndProcedure // pmMoveToNewDate

// -----------------------------------------------------------------------------
//  Calculates services for the given document.
//
// Parameters:
//  rWarnings						 - String	 - 
//  pPeriodDiscount					 - String	 - 
//  pPeriodDiscountType				 - String	 - 
//  pPeriodDiscountServiceGroup		 - String	 - 
//  pPeriodDiscountConfirmationText	 - String	 - 
// 
// Returns:
//  Boolean - False if warnings were rised during services calculation.
//
Function pmCalculateServices(rWarnings = "", pPeriodDiscount = 0, pPeriodDiscountType = Undefined, 
                                             pPeriodDiscountServiceGroup = Undefined, pPeriodDiscountConfirmationText = "") Export
	// User exit before calculate services
	vBeforeCalculateServicesUserExit = Catalogs.ExternalDataProcessors.ResourceReservationBeforeCalculateServices;
	If vBeforeCalculateServicesUserExit.ExternalProcessingType = Enums.ExternalProcessingTypes.Algorithm And Not IsBlankString(vBeforeCalculateServicesUserExit.Algorithm) Then
		SetSafeMode(True);
		Execute(TrimR(vBeforeCalculateServicesUserExit.Algorithm));
		SetSafeMode(False);
	EndIf;
	// Fill period
	vDateTimeFrom = DateTimeFrom;
	vDateTimeTo = cm0SecondShift(DateTimeTo);
	// Save services with prices changed manually
	vIsManualServices = Services.Unload(New Array, );
	vMCServices = Services.Unload();
	i = 0;
	While i < vMCServices.Count() Do
		vSrv = vMCServices.Get(i);
		If ValueIsFilled(vSrv.IsManualAuthor) And ValueIsFilled(vSrv.IsManualDate) Then
			vIsManualServicesRow = vIsManualServices.Add();
			FillPropertyValues(vIsManualServicesRow, vSrv);
		EndIf;
		If Not vSrv.IsManualPrice Then
			vMCServices.Delete(i);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	// Table with service IDs of automatically calculated services
	vAutoServices = New ValueTable();
	vAutoServices.Columns.Add("AccountingDate", cmGetDateTypeDescription());
	vAutoServices.Columns.Add("Service", cmGetCatalogTypeDescription("Services"));
	vAutoServices.Columns.Add("Sequence", cmGetNumberTypeDescription(6, 0));
	vAutoServices.Columns.Add("ServiceID", cmGetStringTypeDescription(36));
	// First clear services added automatically
	i = 0;
	While i < Services.Count() Do
		vSrv = Services.Get(i);
		If Not vSrv.IsManual Then
			// Save service ID
			vAutoServicesArray = vAutoServices.FindRows(New Structure("AccountingDate, Service", vSrv.AccountingDate, vSrv.Service));
			vSequence = vAutoServicesArray.Count() + 1;
			vAutoServicesRow = vAutoServices.Add();
			vAutoServicesRow.AccountingDate = vSrv.AccountingDate; 
			vAutoServicesRow.Service = vSrv.Service; 
			vAutoServicesRow.Sequence = vSequence; 
			vAutoServicesRow.ServiceID = vSrv.ServiceID; 
			// Delete auto service
			Services.Delete(i);
		Else
			vSrv.Company = Company;
			If vSrv.Company <> ChargingFolio.Company And ChargingFolio.DoNotUpdateCompany Then
				vSrv.Company = ChargingFolio.Company;
			EndIf;
			i = i + 1;
		EndIf;
	EndDo;
	// Check should we calculate services at all
	If DoNotCalculateServices Or 
	   ValueIsFilled(EventActivity) And TypeOf(EventActivity) = Type("CatalogRef.EventActivities") And 
	   EventActivity.IsResourceBlock Then
		GoTo ~pmCalculateServicesEnd;
	EndIf;
	// Discount confirmation text
	If Not ValueIsFilled(DiscountType) Or ValueIsFilled(DiscountType) And (DiscountType.IsAccumulatingDiscount Or IsBlankString(DiscountType.ConfirmationPattern)) Then
		DiscountConfirmationText = "";
	EndIf;
	// Get list of accumulating discount types with actual resources
	vAccDiscounts = pmGetAccumulatingDiscountResources();
	// Initialize value of discount should be applied to the whole period
	vPeriodDiscount = pPeriodDiscount;
	vPeriodDiscountType = pPeriodDiscountType;
	vPeriodDiscountServiceGroup = pPeriodDiscountServiceGroup;
	vPeriodDiscountConfirmationText = pPeriodDiscountConfirmationText;
	// Get list of price records for the given resource type and resource
	vPrices = cmGetResourcePrices(Hotel, vDateTimeFrom, vDateTimeTo, ClientType, ResourceType, Resource, ServicePackage, ServicePackages, ResourceTariff);
	If ValueIsFilled(ClientType) And vPrices.Count() = 0 Then
		vPrices = cmGetResourcePrices(Hotel, vDateTimeFrom, vDateTimeTo, Catalogs.ClientTypes.EmptyRef(), ResourceType, Resource, ServicePackage, ServicePackages, ResourceTariff);
	EndIf;
	// Get complex commission
	vComplexCommission = pmGetComplexCommission();
	// Create discount type object
	vIsAmountDiscount = False;
	vFixedDiscount = Discount;
	vFixedDiscountTypeObj = Undefined;
	If ValueIsFilled(DiscountType) Then
		vFixedDiscountTypeObj = DiscountType.GetObject();
		If DiscountType.IsAmountDiscount Then
			vIsAmountDiscount = True;
		EndIf;
	EndIf;
	// Build value table of discount percents per services
	vFixedDiscountPercents = New ValueTable();
	vFixedDiscountPercents.Columns.Add("Service", cmGetCatalogTypeDescription("Services"));
	vFixedDiscountPercents.Columns.Add("Discount", cmGetDiscountTypeDescription());
	If ValueIsFilled(DiscountType) Then
		If DiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Then
			vServices = vPrices.Copy(, "Service");
			vServices.GroupBy("Service", );
			For Each vServicesRow In vServices Do
				If cmIsServiceInServiceGroup(vServicesRow.Service, DiscountServiceGroup) Then
					vFixedDiscountPercentsRow = vFixedDiscountPercents.Add();
					vFixedDiscountPercentsRow.Service = vServicesRow.Service;
					vFixedDiscountPercentsRow.Discount = vFixedDiscountTypeObj.pmGetDiscount(DateTimeFrom, vServicesRow.Service, Hotel);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	// Fill services
	i = 0;
	For Each vPricesRow In vPrices Do
		If Not ValueIsFilled(vPricesRow.Service) Then
			Continue;
		EndIf;
		vCurAccountingDate = vPricesRow.AccountingDate;
		vCurCalendarDayType = vPricesRow.CalendarDayType;
		vCurTimetable = vPricesRow.Timetable;
		vCurService = vPricesRow.Service;
		vCurIsResourceRevenue = vPricesRow.IsResourceRevenue;
		vCurIsPricePerPerson = vPricesRow.IsPricePerPerson;
		vCurIsPricePerMinute = vPricesRow.IsPricePerMinute;
		vCurIsPricePerDay = vPricesRow.IsPricePerDay;
		// Retrieve current fixed discount
		If vFixedDiscountPercents.Count() > 0 Then
			vFixedDiscountPercentsRow = vFixedDiscountPercents.Find(vCurService, "Service");
			If vFixedDiscountPercentsRow <> Undefined Then
				vFixedDiscount = vFixedDiscountPercentsRow.Discount;
			EndIf;
		EndIf;
		// Check that service fit to the service group
		If cmIsServiceInServiceGroup(vCurService, ServiceGroupToBeCharged) Then
			vCurPrice = vPricesRow.Price;
			vCurCurrency = vPricesRow.Currency;
			vCurUnit = vCurService.Unit;
			vCurFolio = ChargingFolio;
			If Not ValueIsFilled(vCurFolio) Then
				Continue;
			EndIf;
			vCurFolioCurrency = FolioCurrency;
			vCurFolioCurrencyExchangeRate = FolioCurrencyExchangeRate;
			vCurBaseCurrencyPrice = Round(cmConvertCurrencies(vCurPrice, vCurCurrency, , Hotel.BaseCurrency, 1, ?(ValueIsFilled(vCurAccountingDate), vCurAccountingDate, ExchangeRateDate), Hotel), 2);
			vCurPrice = Round(cmConvertCurrencies(vCurPrice, vCurCurrency, , vCurFolioCurrency, vCurFolioCurrencyExchangeRate, ?(ValueIsFilled(vCurAccountingDate), vCurAccountingDate, ExchangeRateDate), Hotel), 2);
			vCompany = Company;
			If ValueIsFilled(vCurFolio.Company) And vCurFolio.DoNotUpdateCompany Then
				vCompany = vCurFolio.Company;
			EndIf;
			vCurVATRate = ?(vCompany.IsUsingSimpleTaxSystem, vCompany.VATRate, vPricesRow.VATRate);
			vCurMinQuantity = vPricesRow.MinimumQuantity;
			vCurMaxQuantity = vPricesRow.MaximumQuantity;
			vCurFoCQuantity = vPricesRow.FreeOfChargeQuantity;
			vCurDateTimeFrom = vPricesRow.DateTimeFrom;
			vCurDateTimeTo = vPricesRow.DateTimeTo;
			vCurRemarks = TrimAll(vPricesRow.Remarks);
			// Calculate quantity
			vCurQuantity = vPricesRow.Quantity;
			If vCurQuantity = 0 Then
				If vCurDateTimeFrom < vCurDateTimeTo Then
					If EndOfDay(vCurDateTimeTo) = vCurDateTimeTo Then
						vCurDateTimeTo = vCurDateTimeTo + 1;
					EndIf;
					If vCurIsPricePerMinute Then
						vCurQuantity = (vCurDateTimeTo - cm0SecondShift(vCurDateTimeFrom))/60;
					ElsIf vCurIsPricePerDay Then
						vCurQuantity = Round((EndOfDay(vCurDateTimeTo) - BegOfDay(vCurDateTimeFrom))/(24*3600), 0);
					Else
						vCurQuantity = (vCurDateTimeTo - cm0SecondShift(vCurDateTimeFrom))/3600;
					EndIf;
					// Check for free of charge quantity
					If vCurFoCQuantity <> 0 Then
						If vCurQuantity > vCurFoCQuantity Then
							vCurQuantity = vCurQuantity - vCurFoCQuantity;
						Else
							vCurQuantity = 0;
						EndIf;
					EndIf;
					// Check for minimum quantity
					If vCurQuantity < vCurMinQuantity Then
						vCurQuantity = vCurMinQuantity;
					EndIf;
					// Check for maximum quantity
					If vCurQuantity > vCurMaxQuantity And vCurMaxQuantity <> 0 Then
						vCurQuantity = vCurMaxQuantity;
					EndIf;
				EndIf;
			EndIf;
			// Take number of persons into account
			vCurSrvQuantity = vCurQuantity;
			If vCurIsPricePerPerson Then
				vCurQuantity = vCurQuantity * NumberOfPersons;
			EndIf;
			// Add service to the services tabular part if quantity is not zero
			If vCurQuantity <> 0 Then
				// Try to restore old service ID for this service
				vOldServiceID = "";
				vServicesArray = Services.FindRows(New Structure("AccountingDate, Service", vCurAccountingDate, vCurService));
				vCurSequence = vServicesArray.Count() + 1;
				vAutoServicesArray = vAutoServices.FindRows(New Structure("AccountingDate, Service, Sequence", vCurAccountingDate, vCurService, vCurSequence));
				If vAutoServicesArray.Count() = 1 Then
					vOldServiceID = vAutoServicesArray.Get(0).ServiceID;
				EndIf;
				// Add service
				vSrv = Services.Insert(i);
				If IsBlankString(vOldServiceID) Then
					vSrv.ServiceId = String(New UUID());
				Else
					vSrv.ServiceId = vOldServiceID;
				EndIf;
				i = i + 1;
				vSrv.AccountingDate = vCurAccountingDate;
				vSrv.Service = vCurService;
				vSrv.Price = vCurPrice;
				vSrv.BaseCurrencyPrice = vCurBaseCurrencyPrice;
				vSrv.Unit = vCurUnit;
				vSrv.Quantity = vCurQuantity;
				vSrv.Sum = Round(vCurPrice * vCurQuantity, 2);
				vSrv.VATRate = vCurVATRate;
				vSrv.VATSum = cmCalculateVATSum(vCurVATRate, vSrv.Sum, vSrv.AccountingDate);
				vSrv.Remarks = vCurRemarks;
				vSrv.Company = Company;
				If vSrv.Company <> vCurFolio.Company And vCurFolio.DoNotUpdateCompany Then
					vSrv.Company = vCurFolio.Company;
				EndIf;
				vSrv.ServiceResource = Resource;
				vSrv.IsResourceRevenue = vCurIsResourceRevenue;
				vSrv.IsPricePerMinute = vCurIsPricePerMinute;
				vSrv.IsPricePerDay = vCurIsPricePerDay;
				vSrv.Timetable = vCurTimetable;
				vSrv.DateTimeFrom = vCurDateTimeFrom;
				vSrv.DateTimeTo = vCurDateTimeTo;
				If BegOfDay(vCurDateTimeFrom) = vCurDateTimeFrom And 
				   EndOfDay(vCurDateTimeTo) = vCurDateTimeTo And 
				   vCurDateTimeFrom < DateTimeFrom And
				   vCurDateTimeTo > DateTimeTo Then
					vSrv.TimeFrom = DateTimeFrom;
					vSrv.TimeTo = DateTimeTo;
				Else
					vSrv.TimeFrom = vCurDateTimeFrom;
					vSrv.TimeTo = vCurDateTimeTo;
				EndIf;
				vSrv.IsManual = False;
				If vSrv.IsResourceRevenue Then
					If vCurIsPricePerMinute Then
						vSrv.HoursRented = vCurSrvQuantity/60;
					ElsIf vCurIsPricePerDay Then
						If ValueIsFilled(vSrv.ServiceResource) Then
							If vSrv.ServiceResource.RoundTheClockOperation Then
								vSrv.HoursRented = vCurSrvQuantity * 24;
							ElsIf vSrv.ServiceResource.FullOccupancyHoursPerDay <> 0 Then
								vSrv.HoursRented = vCurSrvQuantity * vSrv.ServiceResource.FullOccupancyHoursPerDay;
							Else
								vSrv.HoursRented = vCurSrvQuantity;
							EndIf;
						Else
							vSrv.HoursRented = vCurSrvQuantity;
						EndIf;
					Else
						vSrv.HoursRented = vCurSrvQuantity;
					EndIf;
				EndIf;
				// Fill resource and service times
				If ValueIsFilled(vSrv.Service.Resource) And ValueIsFilled(vSrv.AccountingDate) Then
					vSrv.ServiceResource = vSrv.Service.Resource;
					vResourceObj = vSrv.ServiceResource.GetObject();
					vDefaultTimes = vResourceObj.pmGetResourceDefaultChargingTimes(vSrv.AccountingDate);
					If ValueIsFilled(vDefaultTimes.TimeFrom) And ValueIsFilled(vDefaultTimes.TimeTo) And vDefaultTimes.TimeTo >= vDefaultTimes.TimeFrom Then
						vSrv.TimeFrom = vDefaultTimes.TimeFrom;
						vSrv.TimeTo = vDefaultTimes.TimeTo;
					EndIf;
					If vSrv.ServiceResource <> Resource Then
						vSrv.DoResourceReservation = True;
					EndIf;
				EndIf;
				// Calculate commission for this service if applicable
				pmSetServiceCommissions(vSrv, vComplexCommission);
				// Calculate discount for this service if applicable
				vCurDiscount = 0;
				vCurDiscountType = Undefined;
				vCurDiscountServiceGroup = Undefined;
				vCurDiscountConfirmationText = "";
				// Check manual discount set in the document
				If cmIsServiceInServiceGroup(vSrv.Service, DiscountServiceGroup) Then
					vCurDiscount = vFixedDiscount;
					If vCurDiscount <> 0 Then
						If ValueIsFilled(DiscountType) And (vCurAccountingDate < DiscountType.DateValidFrom Or
						   vCurAccountingDate > DiscountType.DateValidTo And ValueIsFilled(DiscountType.DateValidTo)) Then
							vCurDiscount = 0;
						Else
							vCurDiscountType = DiscountType;
							vCurDiscountServiceGroup = DiscountServiceGroup;
							vCurDiscountConfirmationText = DiscountConfirmationText;
						EndIf;
					EndIf;
				EndIf;
				// Check accumulating discounts
				If Not TurnOffAutomaticDiscounts Then
					// Check period discount
					If vPeriodDiscount <> 0 Then
						If Not ValueIsFilled(vPeriodDiscountType) Or ValueIsFilled(vPeriodDiscountType) And (vCurAccountingDate >= vPeriodDiscountType.DateValidFrom And (vCurAccountingDate <= vPeriodDiscountType.DateValidTo Or Not ValueIsFilled(vPeriodDiscountType.DateValidTo))) Then
							If cmFirstDiscountIsGreater(vPeriodDiscount, vCurDiscount) Then
								vCurDiscount = vPeriodDiscount;
								vCurDiscountType = vPeriodDiscountType;
								vCurDiscountServiceGroup = vPeriodDiscountServiceGroup;
								vCurDiscountConfirmationText = vPeriodDiscountConfirmationText;
							EndIf;
						EndIf;
					EndIf;
					// Retrieve accumulation discounts
					For Each vAccDiscount In vAccDiscounts Do
						vDiscountType = vAccDiscount.DiscountType;
						If ValueIsFilled(vDiscountType) Then
							If vCurAccountingDate < vDiscountType.DateValidFrom Or
							   (vCurAccountingDate > vDiscountType.DateValidTo And ValueIsFilled(vDiscountType.DateValidTo)) Then
								Continue;
							EndIf;
						EndIf;
						vDiscountDimension = vAccDiscount.DiscountDimension;
						vDiscountServiceGroup = vDiscountType.DiscountServiceGroup;
						If cmIsServiceInServiceGroup(vSrv.Service, vDiscountServiceGroup) Then
							vDiscountTypeObj = vDiscountType.GetObject();
							
							// Check that this discount type fits to the service folio
							vSrvDiscountDimension = Undefined;
							vSrvResource = vDiscountTypeObj.pmCalculateResource(vSrv, NumberOfPersons, ChargingFolio, DiscountCard, vSrvDiscountDimension, True);
							If Not ValueIsFilled(Hotel.DateToGetBonusBalance) Or 
							   Hotel.DateToGetBonusBalance = Enums.DatesToGetBonusBalance.CheckInDate Then
								vSrvResource = 0;
							EndIf;
							If TypeOf(vSrvDiscountDimension) = TypeOf(vDiscountDimension) Then
								// Add resource calculated for this service to the current discount resource
								If vSrvResource <> 0 Then
									vAccDiscount.Resource = vAccDiscount.Resource + vSrvResource;
								EndIf;
							   
								// Retrieve discount percent valid for current discount resource										
								vResource = vAccDiscount.Resource;
								vDiscountConfirmationText = "";
								vDiscount = vDiscountTypeObj.pmGetAccumulatingDiscount(vSrv.Service, vSrv.AccountingDate, 
																					   vResource, 
																					   vDiscountConfirmationText);
								If vDiscount <> 0 Then
									If cmFirstDiscountIsGreater(vDiscount, vCurDiscount) Then
										vCurDiscount = vDiscount;
										vCurDiscountType = vDiscountType;
										vCurDiscountServiceGroup = vDiscountServiceGroup;
										vCurDiscountConfirmationText = vDiscountConfirmationText;
									EndIf;
								EndIf;
							EndIf;
						EndIf;
					EndDo;
				EndIf;
				// Calculate discount sum
				If vCurDiscount <> 0 Then
					If cmIsServiceInServiceGroup(vSrv.Service, vCurDiscountServiceGroup) Then
						vSrv.Discount = vCurDiscount;
						vSrv.DiscountType = vCurDiscountType;
						vSrv.DiscountServiceGroup = vCurDiscountServiceGroup;
						vSrv.DiscountConfirmationText = vCurDiscountConfirmationText;
						// Check should we set value for the period discount
						If ValueIsFilled(vCurDiscountType) Then
							If vCurDiscountType.IsPerPeriod Then
								If vCurDiscount > vPeriodDiscount And vCurDiscount > 0 Or 
								   vCurDiscount < vPeriodDiscount And vCurDiscount < 0 Then
									vPeriodDiscount = vCurDiscount;
									vPeriodDiscountType = vCurDiscountType;
									vPeriodDiscountServiceGroup = vCurDiscountServiceGroup;
									vPeriodDiscountConfirmationText = vCurDiscountConfirmationText;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				Else
					If ValueIsFilled(DiscountType) And 
					   DiscountType.IsAccumulatingDiscount And DiscountType.HasToBeDirectlyAssigned Then 
						If cmIsServiceInServiceGroup(vSrv.Service, DiscountServiceGroup) Then
							vSrv.Discount = 0; // This is not mistake
							vSrv.DiscountType = DiscountType;
							vSrv.DiscountServiceGroup = DiscountServiceGroup;
							vSrv.DiscountConfirmationText = DiscountConfirmationText;
						EndIf;
					EndIf;
				EndIf;
				pmCalculateServiceDiscounts(vSrv);
				// Calculate commission for this service if applicable
				pmCalculateServiceCommissions(vSrv);
				// Try to restore author and date of services added manually or from manually added service packages
				If Not vSrv.IsManual Then
					If vIsManualServices.Count() > 0 Then
						vIsManualServicesRows = vIsManualServices.FindRows(New Structure("ServicePackage, AccountingDate, Service", vSrv.ServicePackage, vSrv.AccountingDate, vSrv.Service));
						For Each vIsManualServicesRow In vIsManualServicesRows Do
							vSrv.IsManualAuthor = vIsManualServicesRow.IsManualAuthor;
							vSrv.IsManualDate = vIsManualServicesRow.IsManualDate;
							Break;
						EndDo;
					EndIf;
				EndIf;
				// Try to find current service in the table of services changed manually
				If vMCServices.Count() > 0 Then
					vMCSrvRows = vMCServices.FindRows(New Structure("AccountingDate, Service, DateTimeFrom", vSrv.AccountingDate, vSrv.Service, vSrv.DateTimeFrom));
					If vMCSrvRows.Count() > 0 Then
						vMCSrv = vMCSrvRows.Get(0);
						FillPropertyValues(vSrv, vMCSrv, , "LineNumber, Company, HoursRented, DateTimeFrom, DateTimeTo, Timetable, CalendarDayType" + 
														   ?(vMCSrv.DiscountIsChanged, "", ", DiscountType, Discount, DiscountServiceGroup, DiscountSum, VATDiscountSum, DiscountConfirmationText") + 
														   ?(vMCSrv.CommissionIsChanged, "", ", AgentCommissionType, AgentCommission, CommissionSum, VATCommissionSum"));
						If vSrv.IsResourceRevenue Then
							If vCurIsPricePerMinute Then
								vSrv.HoursRented = vSrv.Quantity/60;
							ElsIf vCurIsPricePerDay Then
								If ValueIsFilled(vSrv.ServiceResource) Then
									If vSrv.ServiceResource.RoundTheClockOperation Then
										vSrv.HoursRented = vSrv.Quantity * 24;
									ElsIf vSrv.ServiceResource.FullOccupancyHoursPerDay <> 0 Then
										vSrv.HoursRented = vSrv.Quantity * vSrv.ServiceResource.FullOccupancyHoursPerDay;
									Else
										vSrv.HoursRented = vSrv.Quantity;
									EndIf;
								Else
									vSrv.HoursRented = vSrv.Quantity;
								EndIf;
							Else
								vSrv.HoursRented = vSrv.Quantity;
							EndIf;
							vSrv.IsPricePerMinute = vCurIsPricePerMinute;
							vSrv.IsPricePerDay = vCurIsPricePerDay;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	// Check amount discount
	If vIsAmountDiscount And DiscountSum <> 0 Then
		vDiscountSum = DiscountSum;
		vNumServices = Services.Count();
		If vNumServices > 0 Then
			// Do first run
			vNumDiscountServices = 0;
			vFirstRunDiscountSum = Int(vDiscountSum/vNumServices);
			For Each vSrvRow In Services Do
				If vSrvRow.Sum <> 0 And vSrvRow.Sum >= vFirstRunDiscountSum And 
				   cmIsServiceInServiceGroup(vSrvRow.Service, DiscountServiceGroup) Then
					vSrvRow.DiscountSum = vFirstRunDiscountSum;
					vSrvRow.VATDiscountSum = cmCalculateVATSum(vSrvRow.VATRate, vSrvRow.DiscountSum, vSrvRow.AccountingDate);
					vDiscountSum = vDiscountSum - vFirstRunDiscountSum;
					vNumDiscountServices = vNumDiscountServices + 1;
				EndIf;
			EndDo;
			// Do second run
			If vDiscountSum <> 0 And vNumDiscountServices > 0 Then
				vSecondRunDiscountSum = Round(vDiscountSum/vNumDiscountServices, 2);
				For Each vSrvRow In Services Do
					If vSrvRow.Sum <> 0 And vSrvRow.Sum >= vSecondRunDiscountSum And 
					   cmIsServiceInServiceGroup(vSrvRow.Service, DiscountServiceGroup) Then
						If vDiscountSum > 0 Then
							If vDiscountSum > vSecondRunDiscountSum Then
								vSrvRow.DiscountSum = vSrvRow.DiscountSum + vSecondRunDiscountSum;
								vDiscountSum = vDiscountSum - vSecondRunDiscountSum;
							Else
								vSrvRow.DiscountSum = vSrvRow.DiscountSum + vDiscountSum;
								vDiscountSum = 0;
							EndIf;
						Else
							If vDiscountSum < vSecondRunDiscountSum Then
								vSrvRow.DiscountSum = vSrvRow.DiscountSum + vSecondRunDiscountSum;
								vDiscountSum = vDiscountSum - vSecondRunDiscountSum;
							Else
								vSrvRow.DiscountSum = vSrvRow.DiscountSum + vDiscountSum;
								vDiscountSum = 0;
							EndIf;
						EndIf;
						vSrvRow.VATDiscountSum = cmCalculateVATSum(vSrvRow.VATRate, vSrvRow.DiscountSum, vSrvRow.AccountingDate);
					EndIf;
				EndDo;
			EndIf;
			// Do third run
			If vDiscountSum <> 0 And vNumDiscountServices > 0 Then
				For Each vSrvRow In Services Do
					If vSrvRow.Sum <> 0 And vSrvRow.Sum >= vDiscountSum And 
					   cmIsServiceInServiceGroup(vSrvRow.Service, DiscountServiceGroup) Then
						vSrvRow.DiscountSum = vSrvRow.DiscountSum + vDiscountSum;
						vSrvRow.VATDiscountSum = cmCalculateVATSum(vSrvRow.VATRate, vSrvRow.DiscountSum, vSrvRow.AccountingDate);
						vDiscountSum = 0;
						Break;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	// Calculate price presentation
	vPricePresentation = pmCalculatePricePresentation();
	If TrimAll(vPricePresentation) <> TrimAll(PricePresentation) Then
		PricePresentation = TrimAll(vPricePresentation);
	EndIf;
	// Check should we call this function recursively to recalculate discounts
	If vPeriodDiscount <> pPeriodDiscount Then
		Return pmCalculateServices(rWarnings, vPeriodDiscount, vPeriodDiscountType, 
		                                      vPeriodDiscountServiceGroup, vPeriodDiscountConfirmationText);
	EndIf;
~pmCalculateServicesEnd:
	// User exit after calculate services
	vAfterCalculateServicesUserExit = Catalogs.ExternalDataProcessors.ResourceReservationAfterCalculateServices;
	If vAfterCalculateServicesUserExit.ExternalProcessingType = Enums.ExternalProcessingTypes.Algorithm And Not IsBlankString(vAfterCalculateServicesUserExit.Algorithm) Then
		SetSafeMode(True);
		Execute(TrimR(vAfterCalculateServicesUserExit.Algorithm));
		SetSafeMode(False);
	EndIf;
	Return False;
EndFunction // pmCalculateServices

// -----------------------------------------------------------------------------
Procedure pmCalculateServiceDiscounts(pSrvRow) Export
	pSrvRow.DiscountSum = Round(pSrvRow.Sum * pSrvRow.Discount/100, 2);
	If ValueIsFilled(pSrvRow.DiscountType) Then
		vDiscountType = pSrvRow.DiscountType;
		If vDiscountType.RoundPrice Then
			pSrvRow.DiscountSum = cmRoundDiscountAmount(pSrvRow.DiscountSum, vDiscountType.RoundPriceDigits, vDiscountType.RoundPriceType);
		EndIf;
		vWeekDays = vDiscountType.WeekDays;
		If Not IsBlankString(vWeekDays) Then
			If StrFind(vWeekDays, String(WeekDay(pSrvRow.AccountingDate))) = 0 Then
				pSrvRow.DiscountSum = 0;
			EndIf;
		EndIf;
	EndIf;
	pSrvRow.VATDiscountSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.DiscountSum, pSrvRow.AccountingDate);
	pSrvRow.BaseCurrencyPrice = pSrvRow.BaseCurrencyPrice - Round(pSrvRow.BaseCurrencyPrice * pSrvRow.Discount/100, 2);
EndProcedure // pmCalculateServiceDiscounts

// -----------------------------------------------------------------------------
Procedure pmSetServiceCommissions(pSrvRow, pComplexCommission = Undefined) Export
	pSrvRow.AgentCommissionType = Undefined;
	pSrvRow.AgentCommission = 0;
	pSrvRow.CommissionSum = 0;
	pSrvRow.VATCommissionSum = 0;
	pSrvRow.AgentCommissionType = AgentCommissionType;
	pSrvRow.AgentCommission = AgentCommission;
	If pComplexCommission <> Undefined And pComplexCommission.Count() > 0 Then
		For Each vComplexCommissionRow In pComplexCommission Do
			If BegOfDay(vComplexCommissionRow.Period) <= pSrvRow.AccountingDate Then
				If cmIsServiceInServiceGroup(pSrvRow.Service, vComplexCommissionRow.ServiceGroup) Then
					If Not ValueIsFilled(vComplexCommissionRow.RoomClass) And Not ValueIsFilled(vComplexCommissionRow.RoomType) Then
						pSrvRow.AgentCommissionType = vComplexCommissionRow.CommissionType;
						pSrvRow.AgentCommission = vComplexCommissionRow.Commission;
						Break;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	If pSrvRow.AgentCommission <> 0 Then
		// Check that current service fit to the commission service group
		If cmIsServiceInServiceGroup(pSrvRow.Service, AgentCommissionServiceGroup) Then
			If pSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.Percent Then
				pSrvRow.CommissionSum = Round((pSrvRow.Sum - pSrvRow.DiscountSum) * pSrvRow.AgentCommission/100, 2);
				pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
			ElsIf pSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.FirstDayPercent Then
				If BegOfDay(DateTimeFrom) = BegOfDay(pSrvRow.AccountingDate) Then
					pSrvRow.CommissionSum = Round((pSrvRow.Sum - pSrvRow.DiscountSum) * pSrvRow.AgentCommission/100, 2);
					pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
				Else
					pSrvRow.AgentCommissionType = Undefined;
					pSrvRow.AgentCommission = 0;
				EndIf;
			ElsIf (pSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerDayPerRoom Or pSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerDayPerClient) And pSrvRow.IsResourceRevenue Then
				vAgentCurrency = ReportingCurrency;
				If ValueIsFilled(Contract) And ValueIsFilled(Contract.AgentCommissionType) Then
					vAgentCurrency = Contract.AccountingCurrency;
				ElsIf ValueIsFilled(Agent) Then
					vAgentCurrency = Agent.AccountingCurrency;
				EndIf;		
				pSrvRow.CommissionSum = Round(cmConvertCurrencies(pSrvRow.AgentCommission, vAgentCurrency, , FolioCurrency, FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
				pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
			ElsIf (pSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerCheckInPerRoom Or pSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerCheckInPerClient) And pSrvRow.IsResourceRevenue Then
				If BegOfDay(DateTimeFrom) = BegOfDay(pSrvRow.AccountingDate) Then
					vAgentCurrency = ReportingCurrency;
					If ValueIsFilled(Contract) And ValueIsFilled(Contract.AgentCommissionType) Then
						vAgentCurrency = Contract.AccountingCurrency;
					ElsIf ValueIsFilled(Agent) Then
						vAgentCurrency = Agent.AccountingCurrency;
					EndIf;		
					pSrvRow.CommissionSum = Round(cmConvertCurrencies(pSrvRow.AgentCommission, vAgentCurrency, , FolioCurrency, FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
					pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
				Else
					pSrvRow.AgentCommissionType = Undefined;
					pSrvRow.AgentCommission = 0;
				EndIf;
			Else
				pSrvRow.AgentCommissionType = Undefined;
				pSrvRow.AgentCommission = 0;
			EndIf;
		Else
			pSrvRow.AgentCommissionType = Undefined;
			pSrvRow.AgentCommission = 0;
		EndIf;
	EndIf;
EndProcedure // pmSetServiceCommissions

// -----------------------------------------------------------------------------
Procedure pmCalculateServiceCommissions(pSrvRow) Export
	pSrvRow.CommissionSum = 0;
	pSrvRow.VATCommissionSum = 0;
	If pSrvRow.AgentCommission <> 0 Then
		// Check that current service fit to the commission service group
		If cmIsServiceInServiceGroup(pSrvRow.Service, AgentCommissionServiceGroup) Then
			If pSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.Percent Then
				pSrvRow.CommissionSum = Round((pSrvRow.Sum - pSrvRow.DiscountSum) * pSrvRow.AgentCommission/100, 2);
				pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
			ElsIf pSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.FirstDayPercent Then
				If BegOfDay(DateTimeFrom) = BegOfDay(pSrvRow.AccountingDate) Then
					pSrvRow.CommissionSum = Round((pSrvRow.Sum - pSrvRow.DiscountSum) * pSrvRow.AgentCommission/100, 2);
					pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
				Else
					pSrvRow.AgentCommissionType = Undefined;
					pSrvRow.AgentCommission = 0;
				EndIf;
			ElsIf (pSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerDayPerRoom Or pSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerDayPerClient) And pSrvRow.IsResourceRevenue Then
				vAgentCurrency = ReportingCurrency;
				If ValueIsFilled(Contract) And ValueIsFilled(Contract.AgentCommissionType) Then
					vAgentCurrency = Contract.AccountingCurrency;
				ElsIf ValueIsFilled(Agent) Then
					vAgentCurrency = Agent.AccountingCurrency;
				EndIf;		
				pSrvRow.CommissionSum = Round(cmConvertCurrencies(pSrvRow.AgentCommission, vAgentCurrency, , FolioCurrency, FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
				pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
			ElsIf (pSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerCheckInPerRoom Or pSrvRow.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerCheckInPerClient) And pSrvRow.IsResourceRevenue Then
				If BegOfDay(DateTimeFrom) = BegOfDay(pSrvRow.AccountingDate) Then
					vAgentCurrency = ReportingCurrency;
					If ValueIsFilled(Contract) And ValueIsFilled(Contract.AgentCommissionType) Then
						vAgentCurrency = Contract.AccountingCurrency;
					ElsIf ValueIsFilled(Agent) Then
						vAgentCurrency = Agent.AccountingCurrency;
					EndIf;		
					pSrvRow.CommissionSum = Round(cmConvertCurrencies(pSrvRow.AgentCommission, vAgentCurrency, , FolioCurrency, FolioCurrencyExchangeRate, ExchangeRateDate, Hotel), 2);
					pSrvRow.VATCommissionSum = cmCalculateVATSum(pSrvRow.VATRate, pSrvRow.CommissionSum, pSrvRow.AccountingDate);
				Else
					pSrvRow.AgentCommissionType = Undefined;
					pSrvRow.AgentCommission = 0;
				EndIf;
			Else
				pSrvRow.AgentCommissionType = Undefined;
				pSrvRow.AgentCommission = 0;
			EndIf;
		Else
			pSrvRow.AgentCommissionType = Undefined;
			pSrvRow.AgentCommission = 0;
		EndIf;
	EndIf;
EndProcedure // pmCalculateServiceCommissions

// -----------------------------------------------------------------------------
//  Get resource reservation attributes valid on specified date
//
// Parameters:
//  pDate - Date - is optional, if is not specified, then function gets attributes on current date
// 
// Returns:
//  ValueTable - Result 
//
Function pmGetResourceReservationAttributes(Val pDate = Undefined) Export
	// Fill parameter default values 
	If Not ValueIsFilled(pDate) Then
		pDate = CurrentSessionDate();
	EndIf;
	
	// Build and run query
	qGetLastAttr = New Query;
	qGetLastAttr.Text = 
	"SELECT 
	|	* 
	|FROM
	|	InformationRegister.ResourceReservationChangeHistory.SliceLast(
	|	&qDate, 
	|	ResourceReservation = &qResourceReservation) AS ResourceReservationChangeHistory";
	qGetLastAttr.SetParameter("qDate", pDate);
	qGetLastAttr.SetParameter("qResourceReservation", Ref);
	vAttr = qGetLastAttr.Execute().Unload();
	
	Return vAttr;
EndFunction // pmGetResourceReservationAttributes

// -----------------------------------------------------------------------------
// Get reservation prices for all day types of room rate
// -----------------------------------------------------------------------------
Function pmGetPrices() Export
	vPrices = Services.Unload();
	// Remove not is resource revenue services
	vNotResourceRevenueRows = vPrices.FindRows(New Structure("IsResourceRevenue", False));
	If vNotResourceRevenueRows <> Undefined Then
		For Each vNotResourceRevenueRow In vNotResourceRevenueRows Do
			vPrices.Delete(vNotResourceRevenueRow);
		EndDo;
	EndIf;
	// Recalculate prices taking discounts into account
	For Each vCurSrv In vPrices Do
		If ValueIsFilled(Agent) And Not Agent.DoNotPostCommission And Agent = Customer And AgentCommission <> 0 And Agent = Owner Then
			If vCurSrv.DiscountSum <> 0 Then
				vCurSrv.Sum = vCurSrv.Sum - vCurSrv.DiscountSum - vCurSrv.CommissionSum;
				cmSumOnChange(vCurSrv.Service, vCurSrv.Price, vCurSrv.Quantity, vCurSrv.Sum, vCurSrv.VATRate, vCurSrv.VATSum, True, vCurSrv.AccountingDate);
			Else
				vCurSrv.Sum = vCurSrv.Sum - vCurSrv.CommissionSum;
				cmSumOnChange(vCurSrv.Service, vCurSrv.Price, vCurSrv.Quantity, vCurSrv.Sum, vCurSrv.VATRate, vCurSrv.VATSum, True, vCurSrv.AccountingDate);
			EndIf;
		Else
			If vCurSrv.DiscountSum <> 0 Then
				vCurSrv.Sum = vCurSrv.Sum - vCurSrv.DiscountSum;
				cmSumOnChange(vCurSrv.Service, vCurSrv.Price, vCurSrv.Quantity, vCurSrv.Sum, vCurSrv.VATRate, vCurSrv.VATSum, True, vCurSrv.AccountingDate);
			EndIf;
		EndIf;
	EndDo;	
	// Group services by prices
	vPrices.GroupBy("CalendarDayType, Service, Price", );
	// Return prices
	Return vPrices;
EndFunction // pmGetPrices

// -----------------------------------------------------------------------------
Function pmGetDocumentLanguage() Export
	If ValueIsFilled(Customer) Then
		If ValueIsFilled(Customer.Language) Then
			Return Customer.Language;
		EndIf;
	EndIf;
	If ValueIsFilled(Client) Then
		If ValueIsFilled(Client.Language) Then
			Return Client.Language;
		EndIf;
	EndIf;
	Return Catalogs.Languages.EmptyRef();
EndFunction // pmGetDocumentLanguage

// -----------------------------------------------------------------------------
Procedure pmProcessHotelChange() Export
	If ValueIsFilled(Hotel) Then
		SetNewNumber(Catalogs.Hotels.pmGetPrefix(Hotel));
		If Not ValueIsFilled(Company) Or ValueIsFilled(Company) And ValueIsFilled(Company.Hotel) And Company.Hotel <> Hotel Then
			Company = Hotel.Company;
		EndIf;
		ReportingCurrency = Hotel.ReportingCurrency;
		ReportingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, ReportingCurrency, Date);
		// Recreate guest group as it has hotel as owner
		pmCreateGuestGroup();
	EndIf;
EndProcedure // pmProcessHotelChange	

// -----------------------------------------------------------------------------
Procedure pmSetDiscounts() Export
	// Do nothing if this is inactive document
	If Not ValueIsFilled(ResourceReservationStatus) Or ValueIsFilled(ResourceReservationStatus) And (Not ResourceReservationStatus.IsActive Or ResourceReservationStatus.ServicesAreDelivered) Then
		Return;
	EndIf;
	// Check if manual discount is choosen
	If ValueIsFilled(DiscountType) And DiscountType.IsManualDiscount Then
		// Check if discount type is for individuals only
		If DiscountType.IsForIndividualsOnly Then
			If ValueIsFilled(Customer) And Not Customer.IsIndividual Or ValueIsFilled(Agent) Then
				DiscountType = Catalogs.DiscountTypes.EmptyRef();
				DiscountConfirmationText = "";
				DiscountServiceGroup = Catalogs.ServiceGroups.EmptyRef();
				Discount = 0;
			EndIf;
		EndIf;
		Return;
	ElsIf Not ValueIsFilled(DiscountType) And Discount <> 0 Then
		Return;
	EndIf;
	// Fill discounts from the different sources
	DiscountType = Catalogs.DiscountTypes.EmptyRef();
	DiscountConfirmationText = "";
	DiscountServiceGroup = Catalogs.ServiceGroups.EmptyRef();
	Discount = 0;
	vOldTurnOffAutomaticDiscounts = TurnOffAutomaticDiscounts;
	vTurnOffAutomaticDiscountsWasSet = False;
	TurnOffAutomaticDiscounts = False;
	If ValueIsFilled(Contract) And Contract.NoDiscounts Then
		Return;
	EndIf;
	If ValueIsFilled(ClientType) And ClientType.NoDiscounts Then
		Return;
	EndIf;
	If ValueIsFilled(Client) And ValueIsFilled(Client.DiscountCard) And Not ValueIsFilled(DiscountCard) Then
		DiscountCard = Client.DiscountCard;
	EndIf;
	If ValueIsFilled(DiscountCard) Then
		If DiscountCard.TurnOffAutomaticDiscounts Then
			TurnOffAutomaticDiscounts = DiscountCard.TurnOffAutomaticDiscounts;
			vTurnOffAutomaticDiscountsWasSet = True;
		EndIf;
		If ValueIsFilled(DiscountCard.DiscountType) Then
			vDiscountType = DiscountCard.DiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(DateTimeFrom, , Hotel);
			If cmCompareDiscounts(vDiscount, Discount) Or vDiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Or 
			   vDiscountType.IsAccumulatingDiscount And vDiscountType.HasToBeDirectlyAssigned Or
			   vDiscountType.IsAccumulatingDiscount And vDiscountType.BonusCalculationFactor <> 0 Then 
				DiscountType = vDiscountType;
				DiscountConfirmationText = DiscountCard.Metadata().Synonym + " " + TrimAll(DiscountCard.Description);
				DiscountServiceGroup = DiscountType.DiscountServiceGroup;
				If Not vDiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Then
					Discount = vDiscount;
				EndIf;
				If ValueIsFilled(DiscountCard.ClientType) Then
					ClientType = DiscountCard.ClientType;
				EndIf;
			EndIf;
		EndIf;
	EndIf;	
	If ValueIsFilled(ClientType) Then
		If ClientType.TurnOffAutomaticDiscounts Then
			TurnOffAutomaticDiscounts = ClientType.TurnOffAutomaticDiscounts;
			vTurnOffAutomaticDiscountsWasSet = True;
		EndIf;
		If ValueIsFilled(ClientType.DiscountType) Then
			vDiscountType = ClientType.DiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(DateTimeFrom, , Hotel);
			If cmCompareDiscounts(vDiscount, Discount) Or 
			   vDiscountType.IsAccumulatingDiscount And vDiscountType.HasToBeDirectlyAssigned Or 
			   vDiscountType.IsAccumulatingDiscount And vDiscountType.BonusCalculationFactor <> 0 Then 
				DiscountType = vDiscountType;
				If IsBlankString(ClientTypeConfirmationText) Then
					DiscountConfirmationText = NStr("en='Client type discount';ru='По типу клиента';de='Nach Kundentyp'");
				Else
					DiscountConfirmationText = ClientTypeConfirmationText;
				EndIf;
				DiscountServiceGroup = DiscountType.DiscountServiceGroup;
				If Not vDiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Then
					Discount = vDiscount;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(MarketingCode) Then
		If MarketingCode.TurnOffAutomaticDiscounts Then
			TurnOffAutomaticDiscounts = MarketingCode.TurnOffAutomaticDiscounts;
			vTurnOffAutomaticDiscountsWasSet = True;
		EndIf;
		If ValueIsFilled(MarketingCode.DiscountType) Then
			vDiscountType = MarketingCode.DiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(DateTimeFrom, , Hotel);
			If cmCompareDiscounts(vDiscount, Discount) Or 
			   vDiscountType.IsAccumulatingDiscount And vDiscountType.HasToBeDirectlyAssigned Or 
			   vDiscountType.IsAccumulatingDiscount And vDiscountType.BonusCalculationFactor <> 0 Then 
				DiscountType = vDiscountType;
				If IsBlankString(MarketingCodeConfirmationText) Then
					DiscountConfirmationText = NStr("en='Marketing code discount';ru='По направлению маркетинга';de='Nach Marketingrichtung'");
				Else
					DiscountConfirmationText = MarketingCodeConfirmationText;
				EndIf;
				DiscountServiceGroup = DiscountType.DiscountServiceGroup;
				If Not vDiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Then
					Discount = vDiscount;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(Client) Then
		If ValueIsFilled(Client.DiscountType) Then
			vDiscountType = Client.DiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(DateTimeFrom, , Hotel);
			If cmCompareDiscounts(vDiscount, Discount) Or 
			   vDiscountType.IsAccumulatingDiscount And vDiscountType.HasToBeDirectlyAssigned Or 
			   vDiscountType.IsAccumulatingDiscount And vDiscountType.BonusCalculationFactor <> 0 Then 
				DiscountType = vDiscountType;
				DiscountServiceGroup = DiscountType.DiscountServiceGroup;
				If IsBlankString(Client.DiscountConfirmationText) Then
					DiscountConfirmationText = NStr("en='Client discount';ru='По клиенту';de='Nach Kunde'");
				Else
					DiscountConfirmationText = Client.DiscountConfirmationText;
				EndIf;
				If Not vDiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Then
					Discount = vDiscount;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(Customer) Then
		If ValueIsFilled(Customer.DiscountType) Then
			vDiscountType = Customer.DiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(DateTimeFrom, , Hotel);
			If cmCompareDiscounts(vDiscount, Discount) Or 
			   vDiscountType.IsAccumulatingDiscount And vDiscountType.HasToBeDirectlyAssigned Or 
			   vDiscountType.IsAccumulatingDiscount And vDiscountType.BonusCalculationFactor <> 0 Then 
				DiscountType = vDiscountType;
				DiscountServiceGroup = DiscountType.DiscountServiceGroup;
				If IsBlankString(Customer.DiscountConfirmationText) Then
					DiscountConfirmationText = NStr("en='Customer discount';ru='По контрагенту';de='Nach Partner'");
				Else
					DiscountConfirmationText = Customer.DiscountConfirmationText;
				EndIf;
				If Not vDiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Then
					Discount = vDiscount;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(Contract) Then
		If ValueIsFilled(Contract.DiscountType) Then
			vDiscountType = Contract.DiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(DateTimeFrom, , Hotel);
			If cmCompareDiscounts(vDiscount, Discount) Or 
			   vDiscountType.IsAccumulatingDiscount And vDiscountType.HasToBeDirectlyAssigned Or 
			   vDiscountType.IsAccumulatingDiscount And vDiscountType.BonusCalculationFactor <> 0 Then 
				DiscountType = vDiscountType;
				DiscountServiceGroup = DiscountType.DiscountServiceGroup;
				If IsBlankString(Contract.DiscountConfirmationText) Then
					DiscountConfirmationText = NStr("en='Contract discount';ru='По договору';de='Nach Vertrag'");
				Else
					DiscountConfirmationText = Contract.DiscountConfirmationText;
				EndIf;
				If Not vDiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Then
					Discount = vDiscount;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If Catalogs.ExternalDataProcessors.SetDiscounts.ExternalProcessingType = Enums.ExternalProcessingTypes.Algorithm Then
		If Not IsBlankString(Catalogs.ExternalDataProcessors.SetDiscounts.Algorithm) Then
			Execute(TrimAll(Catalogs.ExternalDataProcessors.SetDiscounts.Algorithm));
		EndIf;
	EndIf;
	If ValueIsFilled(DiscountType) Then
		If DiscountType.IsForIndividualsOnly Then
			If ValueIsFilled(Customer) And Not Customer.IsIndividual Or ValueIsFilled(Agent) Then
				DiscountType = Catalogs.DiscountTypes.EmptyRef();
				DiscountConfirmationText = "";
				DiscountServiceGroup = Catalogs.ServiceGroups.EmptyRef();
				Discount = 0;
			EndIf;
		EndIf;
		If ValueIsFilled(DiscountType) And DiscountType.TurnOffAutomaticDiscounts Then
			TurnOffAutomaticDiscounts = DiscountType.TurnOffAutomaticDiscounts;
			vTurnOffAutomaticDiscountsWasSet = True;
		EndIf;
	EndIf;
	If Not vTurnOffAutomaticDiscountsWasSet Then
		TurnOffAutomaticDiscounts = vOldTurnOffAutomaticDiscounts;
	EndIf;
	// Check should we reset client type or not
	If ValueIsFilled(DiscountType) And DiscountType.ForceSetOfClientType Then
		If DiscountType.ClientType <> ClientType Then
			ClientType = DiscountType.ClientType;
		EndIf;
	EndIf;
EndProcedure // pmSetDiscounts

// -----------------------------------------------------------------------------
Function pmGetThisDocumentRef() Export
	vObjectRef = Ref;
	If IsNew() Then
		vObjectRef = GetNewObjectRef();
		If Not ValueIsFilled(vObjectRef) Then
			SetNewObjectRef(Documents.ResourceReservation.GetRef());
			vObjectRef = GetNewObjectRef();
		EndIf;
	EndIf;
	Return vObjectRef;
EndFunction // pmGetThisDocumentRef

// -----------------------------------------------------------------------------
Procedure pmDeleteUnusedChargingFolio() Export
	vObjectRef = pmGetThisDocumentRef();
	// If folio left in the list do not have any transactions based on it then delete it
	If Not ValueIsFilled(ChargingFolio) Then
		Return;
	EndIf;
	vFolioRef = ChargingFolio;
	If ValueIsFilled(vFolioRef.ParentDoc) And 
	   vFolioRef.ParentDoc <> vObjectRef And 
	  (ValueIsFilled(vFolioRef.ParentDoc.DataVersion) Or ValueIsFilled(vObjectRef.DataVersion)) Then
		Return;
	EndIf;
	If Not vFolioRef.IsMaster And Not vFolioRef.DeletionMark Then
		vFolioObj = vFolioRef.GetObject();
		vFolioObj.Read();
		If IsNew() Then
			vFolioObj.ParentDoc = Undefined;
			vFolioObj.Write(DocumentWriteMode.Write);
		EndIf;
		vTransCount = vFolioObj.pmGetAllFolioTransactionsCount();
		If vTransCount = 0 Then
			vFolioObj.IsClosed = True;
			vFolioObj.Write(DocumentWriteMode.Write);
			vFolioObj.SetDeletionMark(True);
		EndIf;
	EndIf;
EndProcedure // pmDeleteUnusedChargingFolio

// -----------------------------------------------------------------------------
Procedure pmChargeServices(pCancel, pPostingMode, pCloseOfDayMode, pAccountingDate, pCRTab) Export
	ChargesToRepostStorno = New ValueList();

	// 1. Build table of already charged services
	vChargesTab = cmGetTableOfResourceReservationAlreadyChargedServices(Ref);
	
	// 2. Create table of document services
	vServicesTab = Services.Unload();
	If Not DoCharging Then
		vServicesTab.Clear();
		
		// Write to accumulation discount resources
		If ValueIsFilled(ResourceReservationStatus) And ResourceReservationStatus.IsActive Then
			PostToAccumulatingDiscountResources(vServicesTab);
		EndIf;
	Else
		// Remove services with 0 quantity
		i = 0;
		While i < vServicesTab.Count() Do
			vSrvRow = vServicesTab.Get(i);
			If vSrvRow.Quantity = 0 Then
				vServicesTab.Delete(i);
			Else
				i = i + 1;
			EndIf;
		EndDo;
		// Remove future services if charging should be done by close of period
		If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.AccountingDate) And 
		   ValueIsFilled(ResourceReservationStatus) And ResourceReservationStatus.IsActive Then
			If Hotel.CloseOfPeriodDoChargeServices Then
				i = 0;
				While i < vServicesTab.Count() Do
					vSrvRow = vServicesTab.Get(i);
					If Not vSrvRow.Service.AlwaysChargeInAdvance And vSrvRow.AccountingDate > DoChargingToDate And 
					    (Not pCloseOfDayMode And vSrvRow.AccountingDate > pAccountingDate Or 
					     pCloseOfDayMode And vSrvRow.AccountingDate > pAccountingDate) Then
						vServicesTab.Delete(i);
					Else
						i = i + 1;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	// Remove services that shouldn't be charged to the folio
	If Not DoChargingIgnoringProhibition Then
		i = 0;
		While i < vServicesTab.Count() Do
			vSrvRec = vServicesTab.Get(i);
			vSrvService = vSrvRec.Service;
			If ValueIsFilled(vSrvService) And ValueIsFilled(vSrvService.ServiceType) And 
			   vSrvService.ServiceType.ActualAmountIsChargedExternally Then
				// Delete service
				vServicesTab.Delete(i);
			Else
				i = i + 1;
			EndIf;
		EndDo;
	EndIf;
	
	// Add analitical dimensions to the services table
	cmAddResourceReservationServicesDimensionsColumns(vServicesTab);
	
	// If accommodation is active
	For Each vSrv In vServicesTab Do
		// Fill is manual column
		If vSrv.IsManualPrice Then
			vSrv.IsManual = True;
		EndIf;
		// Fill additional charge attributes
		cmFillResourceReservationServicesDimensionsColumns(vSrv, ThisObject);
	EndDo;
	
	// 3. Build difference table between already charged services and 
	// services in the document. We will do it ignoring folios.
	vServicesDifferenceTab = cmGetResourceReservationServicesDifference(vServicesTab, vChargesTab);
	
	// 4. Set current folio and service remarks
	pmSetCurrentFolio(vServicesTab, pCRTab);
	
	// 5. Create charging for each service in difference services
	ChargeServiceDifferences(vServicesDifferenceTab, vServicesTab, vChargesTab);
	
	// 6. Repost storno for changed charges
	If ChargesToRepostStorno.Count() > 0 Then
		RepostStornosForChangedCharges();
	EndIf;
EndProcedure // pmChargeServices

// -----------------------------------------------------------------------------
Procedure RepostStornosForChangedCharges()
	// Get list of stornos to repost
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Storno.Ref AS Ref
	|FROM
	|	Document.Storno AS Storno
	|WHERE
	|	Storno.ParentCharge IN (&qChargesToRepostStorno)
	|	AND Storno.Posted";
	vQry.SetParameter("qChargesToRepostStorno", ChargesToRepostStorno);
	vStornos = vQry.Execute().Unload();
	For Each vStornosRow In vStornos Do
		vStornoObj = vStornosRow.Ref.GetObject();
		vStornoObj.Write(DocumentWriteMode.Posting);
	EndDo;
EndProcedure // RepostStornosForChangedCharges

// -----------------------------------------------------------------------------
Procedure pmSetCurrentFolio(pServices, pCRTab) Export
	For Each vSrvRow In pServices Do
		// Set current service folio
		If ValueIsFilled(ChargingFolio) Then
			vSrvRow.Folio = ChargingFolio;
		EndIf;
		// Check group charging rules
		If pCRTab.Count() > 0 Then
			For Each vCRRow In pCRTab Do
				If cmIsServiceFitToTheChargingRule(vCRRow, vSrvRow.Service, vSrvRow.AccountingDate, False, False, , True) Then
					vCurFolio = vCRRow.ChargingFolio;
					If FolioCurrency = vCurFolio.FolioCurrency Then
						vSrvRow.Folio = vCurFolio;
						Break;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
EndProcedure // pmSetCurrentFolio

// -----------------------------------------------------------------------------
Function pmGetResourceReservationHistoryState(pPeriod) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	*
	|FROM
	|	InformationRegister.ResourceReservationChangeHistory.SliceLast(&qPeriod, ResourceReservation = &qResourceReservation) AS ResourceReservationChangeHistorySliceLast";
	vQry.SetParameter("qPeriod", pPeriod);
	vQry.SetParameter("qResourceReservation", Ref);
	vResStates = vQry.Execute().Unload();
	Return vResStates;
EndFunction // pmGetResourceReservationHistoryState

#EndRegion

#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure Posting(pCancel, pPostingMode)
	Var vMessage, vAttributeInErr;
	If DataExchange.Load Then
		Return;
	EndIf;
	// Add data locks
	vDataLock = New DataLock();
	If ValueIsFilled(Resource) Then
		vResItem = vDataLock.Add("Catalog.Resources");
		vResItem.Mode = DataLockMode.Exclusive;
		vResItem.SetValue("Ref", Resource);
	EndIf;
	If vDataLock.Count() > 0 Then
		vDataLock.Lock();
	EndIf;
	// Clear register records
	RegisterRecords.ResourceReservationHistory.Clear();
	RegisterRecords.SalesForecast.Clear();
	RegisterRecords.AccountsReceivableForecast.Clear();
	RegisterRecords.ServiceRegistration.Clear();
	// Check document posting mode
	vCloseOfDayMode = False;
	vAccountingDate = BegOfDay(CurrentSessionDate());
	If Hotel.CloseOfPeriodDoChargeServices Then
		If AdditionalProperties.Property("CloseOfDayMode") Then
			vCloseOfDayMode = AdditionalProperties.CloseOfDayMode;
		EndIf;
		If ValueIsFilled(Hotel.AccountingDate) Then
			vAccountingDate = Hotel.AccountingDate;
			If ValueIsFilled(vAccountingDate) And AdditionalProperties.Property("AccountingDate") Then
				If ValueIsFilled(AdditionalProperties.AccountingDate) And TypeOf(AdditionalProperties.AccountingDate) = Type("Date") Then
					vAccountingDate = AdditionalProperties.AccountingDate;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	// Fill folio parameters
	If ResourceReservationStatus.IsActive Then
		FillFolioParameters(pCancel);
	EndIf;
	SetFolioStatuses(pCancel);
	// Get group charging rules
	vCRTab = New ValueTable();
	If ValueIsFilled(GuestGroup) Then
		vCRTab = GuestGroup.ChargingRules.Unload();
	EndIf;
	// Post to registers
	PostToRegisters(pCancel, vCloseOfDayMode, vAccountingDate, vCRTab);
	If Not pCancel Then
		If Not vCloseOfDayMode Then
			pCancel	= pmCheckDocumentAttributes(True, vMessage, vAttributeInErr);
			If pCancel Then
				WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
				vMessage = NStr(vMessage);
				If Not IsBlankString(vMessage) Then
					Raise String(Ref) + " - " + vMessage;
				EndIf;
			EndIf;
		EndIf;
	Else
		Return;
	EndIf;
	// Post to expected customer sales. Those records are used to compare charged guest group services with planned ones
	If ResourceReservationStatus.IsActive Then
		If DoCharging Then
			PostToExpectedCustomerSales(pCancel, vCloseOfDayMode, vAccountingDate, vCRTab);
		EndIf;
	Else
		PostToCancelledExpectedCustomerSales(pCancel, vCRTab);
	EndIf;
	// Post services if necessary
	pmChargeServices(pCancel, pPostingMode, vCloseOfDayMode, vAccountingDate, vCRTab);
	// Move guests to the appropriate folder
	MoveClients(pCancel, pPostingMode);
	// Fill head of group, group customer, group period and number of clients
	FillGroupParameters();
	// Check should we update customer/contract/agent/planned payment method in all resource reservations of the same guest group
	If GuestGroup.OneCustomerPerGuestGroup And Not AdditionalProperties.Property("IsInRecursion") Then
		vResDocs = GuestGroup.GetObject().pmGetResourceReservations();
		For Each vResDocsRow In vResDocs Do
			vCurReservation = vResDocsRow.Reservation;
			If vCurReservation <> Ref Then
				vResourceReservationIsChanged = False;
				If vCurReservation.Customer <> Customer Or
				   vCurReservation.Contract <> Contract Or
				   vCurReservation.ContactPerson <> ContactPerson Or
				   vCurReservation.PlannedPaymentMethod <> PlannedPaymentMethod Or
				   vCurReservation.Owner <> Owner Or
				   vCurReservation.Discount <> Discount Or
				   vCurReservation.DiscountType <> DiscountType Or
				   vCurReservation.DiscountConfirmationText <> DiscountConfirmationText Or
				   vCurReservation.DiscountServiceGroup <> DiscountServiceGroup Or
				   vCurReservation.DiscountCard <> DiscountCard Or
				   vCurReservation.TurnOffAutomaticDiscounts <> TurnOffAutomaticDiscounts Then
					vResourceReservationIsChanged = True;
				EndIf;
				If vResourceReservationIsChanged Then
					vCurReservationObj = vCurReservation.GetObject();
					vCurReservationObj.Customer = Customer;
					vCurReservationObj.Contract = Contract;
					vCurReservationObj.ContactPerson = ContactPerson;
					vCurReservationObj.Agent = Agent;
					vCurReservationObj.Owner = Owner;
					vCurReservationObj.PlannedPaymentMethod = PlannedPaymentMethod;
					vCurReservationObj.Discount = Discount;
					vCurReservationObj.DiscountType = DiscountType;
					vCurReservationObj.DiscountConfirmationText = DiscountConfirmationText;
					vCurReservationObj.DiscountServiceGroup = DiscountServiceGroup;
					vCurReservationObj.DiscountCard = DiscountCard;
					vCurReservationObj.TurnOffAutomaticDiscounts = TurnOffAutomaticDiscounts;
					// Recalculate services
					vCurReservationObj.pmCalculateServices();
					// Post document
					vCurReservationObj.AdditionalProperties.Insert("IsInRecursion", True);
					vCurReservationObj.Write(DocumentWriteMode.Posting);
					// Save data to the document history
					vCurReservationObj.pmWriteToResourceReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // Posting

 // -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pWriteMode, pPostingMode)
	Var vMessage, vAttributeInErr;
	If DataExchange.Load Then
		Return;
	EndIf;
	vCloseOfDayMode = False;
	If AdditionalProperties.Property("CloseOfDayMode") Then
		vCloseOfDayMode = AdditionalProperties.CloseOfDayMode;
	EndIf;
	If pWriteMode = DocumentWriteMode.Posting Then
		If Not vCloseOfDayMode Then
			// Fill activity in services
			If ValueIsFilled(EventActivity) Then
				If TypeOf(EventActivity) = Type("CatalogRef.EventActivities") And EventActivity.IsResourceBlock Then
					If Services.Count() > 0 Then
						Services.Clear();
					EndIf;
					If ServiceItems.Count() > 0 Then
						ServiceItems.Clear();
					EndIf;
					If NumberOfPersons <> 0 Then
						NumberOfPersons = 0;
					EndIf;
					If PreparationTime <> 0 Then
						PreparationTime = 0;
					EndIf;
					If DisassembleTime <> 0 Then
						DisassembleTime = 0;
					EndIf;
					If ValueIsFilled(ResourceTableConfiguration) Then
						ResourceTableConfiguration = Undefined;
					EndIf;
					If ValueIsFilled(GuaranteeType) Then
						GuaranteeType = Undefined;
					EndIf;
				EndIf;
			Else
				If ValueIsFilled(Resource) And Not DoResourceReservation Then
					DoResourceReservation = True;
				EndIf;
			EndIf;
			// Preprocess services
			For Each vSrvRow In Services Do
				If ValueIsFilled(EventActivity) Then
					If Services.IndexOf(vSrvRow) = 0 Then
						If vSrvRow.NumberOfPersons <> NumberOfPersons Then
							vSrvRow.NumberOfPersons = NumberOfPersons;
						EndIf;
						If vSrvRow.EventActivity <> EventActivity Then
							vSrvRow.EventActivity = EventActivity;
						EndIf;
						If vSrvRow.ResourceTableConfiguration <> ResourceTableConfiguration Then
							vSrvRow.ResourceTableConfiguration = ResourceTableConfiguration;
						EndIf;
						If vSrvRow.ActivityRemarks <> ActivityRemarks Then
							vSrvRow.ActivityRemarks = ActivityRemarks;
						EndIf;
					Else
						If vSrvRow.EventActivity <> EventActivity And Not ValueIsFilled(vSrvRow.ServiceResource) Then
							vSrvRow.EventActivity = EventActivity;
						EndIf;
						If vSrvRow.NumberOfPersons <> NumberOfPersons And Not ValueIsFilled(vSrvRow.ServiceResource) Then
							vSrvRow.NumberOfPersons = NumberOfPersons;
						EndIf;
					EndIf;
				EndIf;
				If vSrvRow.IsManual Then
					If ValueIsFilled(vSrvRow.AccountingDate) And 
					  (ValueIsFilled(vSrvRow.TimeFrom) Or ValueIsFilled(vSrvRow.TimeTo)) Then
						vDateTimeFrom = BegOfDay(vSrvRow.AccountingDate) + (vSrvRow.TimeFrom - BegOfDay(vSrvRow.TimeFrom));
						If vSrvRow.TimeFrom < vSrvRow.TimeTo Then
							vDateTimeTo = BegOfDay(vSrvRow.AccountingDate) + (vSrvRow.TimeTo - BegOfDay(vSrvRow.TimeTo));
						Else
							vDateTimeTo = BegOfDay(vSrvRow.AccountingDate) + 24*3600 + (vSrvRow.TimeTo - BegOfDay(vSrvRow.TimeTo));
						EndIf;
						If vSrvRow.DateTimeFrom <> vDateTimeFrom Then
							vSrvRow.DateTimeFrom = vDateTimeFrom;
						EndIf;
						If vSrvRow.DateTimeTo <> vDateTimeTo Then
							vSrvRow.DateTimeTo = vDateTimeTo;
						EndIf;
					Else
						If vSrvRow.DateTimeFrom <> DateTimeFrom Then
							vSrvRow.DateTimeFrom = DateTimeFrom;
						EndIf;
						If vSrvRow.DateTimeTo <> DateTimeTo Then
							vSrvRow.DateTimeTo = DateTimeTo;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
			// Check document attributes
			pCancel	= pmCheckDocumentAttributes(Posted, vMessage, vAttributeInErr, True);
			If pCancel Then
				WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
				tcCommonFunctionOnClientServer.UserMessage(NStr(vMessage));
				Raise String(Ref) + " - " + NStr(vMessage);
			Else
				vLastDocState = pmGetPreviousObjectState(CurrentSessionDate());
				
				// Check do charging
				vDoCharging = False;
				If ValueIsFilled(ResourceReservationStatus) And ResourceReservationStatus.IsActive And Not ResourceReservationStatus.ServicesAreDelivered And
				   ValueIsFilled(ChargingFolio) And ValueIsFilled(ChargingFolio.PaymentMethod) And ChargingFolio.PaymentMethod.ChargeServicesInAdvance Then
					vDoCharging = True;
				Else
					If ValueIsFilled(ResourceReservationStatus) Then
						vDoCharging = ResourceReservationStatus.DoCharging;
					EndIf;
				EndIf;
				If vDoCharging <> DoCharging Then
					DoCharging = vDoCharging;
				EndIf;
				
				// Check new manual services and fill author and date for them
				vProcessAllManualServices = True;
				If vLastDocState <> Undefined Then
					vLastDocStateServices = vLastDocState.Services.Get();
					If vLastDocStateServices <> Undefined Then
						vProcessAllManualServices = False;
						vManualServices = Services.FindRows(New Structure("IsManual, IsManualAuthor, IsManualDate", True, Catalogs.Employees.EmptyRef(), '00010101'));
						For Each vManualServicesRow In vManualServices Do
							// Search service in the previous services state list
							vLastDocStateManualServices = vLastDocStateServices.FindRows(New Structure("IsManual, AccountingDate, Service", True, vManualServicesRow.AccountingDate, vManualServicesRow.Service));
							If vLastDocStateManualServices.Count() = 0 Then
								vManualServicesRow.IsManualAuthor = SessionParameters.CurrentUser;
								vManualServicesRow.IsManualDate = CurrentSessionDate();
							EndIf;
						EndDo;
					EndIf;
				EndIf;
				If vProcessAllManualServices Then
					vManualServices = Services.FindRows(New Structure("IsManual, IsManualAuthor, IsManualDate", True, Catalogs.Employees.EmptyRef(), '00010101'));
					For Each vManualServicesRow In vManualServices Do
						vManualServicesRow.IsManualAuthor = SessionParameters.CurrentUser;
						vManualServicesRow.IsManualDate = CurrentSessionDate();
					EndDo;
				EndIf;
				
				// Process service packages added to the document manually and fill author and date for them
				vServicePackages = ServicePackages.Unload(, "ServicePackage");
				vServicePackages.GroupBy("ServicePackage", );
				If ValueIsFilled(ServicePackage) And Not ServicePackage.IsMealBoardTerm Then
					If vServicePackages.Find(ServicePackage, "ServicePackage") = Undefined Then
						vServicePackagesRow = vServicePackages.Add();
						vServicePackagesRow.ServicePackage = ServicePackage;
					EndIf;
				EndIf;
				vProcessAllManualPackages = True;
				If vLastDocState <> Undefined Then
					vLastDocStateServicePackages = vLastDocState.ServicePackages.Get();
					If vLastDocStateServicePackages <> Undefined Then
						vProcessAllManualPackages = False;
						vLastDocStateServicePackages.GroupBy("ServicePackage", );
						If ValueIsFilled(vLastDocState.ServicePackage) And Not vLastDocState.ServicePackage.IsMealBoardTerm Then
							If vLastDocStateServicePackages.Find(vLastDocState.ServicePackage, "ServicePackage") = Undefined Then
								vLastDocStateServicePackagesRow = vLastDocStateServicePackages.Add();
								vLastDocStateServicePackagesRow.ServicePackage = vLastDocState.ServicePackage;
							EndIf;
						EndIf;
						For Each vServicePackagesRow In vServicePackages Do
							If ValueIsFilled(vServicePackagesRow.ServicePackage) Then
								If vLastDocStateServicePackages.Find(vServicePackagesRow.ServicePackage, "ServicePackage") = Undefined Then
									vSPServicesRows = Services.FindRows(New Structure("ServicePackage, IsManualAuthor, IsManualDate", vServicePackagesRow.ServicePackage, Catalogs.Employees.EmptyRef(), '00010101'));
									For Each vSPServicesRow In vSPServicesRows Do
										vSPServicesRow.IsManualAuthor = SessionParameters.CurrentUser;
										vSPServicesRow.IsManualDate = CurrentSessionDate();
									EndDo;
								EndIf;
							EndIf;
						EndDo;
					EndIf;
				EndIf;
				If vProcessAllManualPackages Then
					For Each vServicePackagesRow In vServicePackages Do
						If ValueIsFilled(vServicePackagesRow.ServicePackage) Then
							vSPServicesRows = Services.FindRows(New Structure("ServicePackage, IsManualAuthor, IsManualDate", vServicePackagesRow.ServicePackage, Catalogs.Employees.EmptyRef(), '00010101'));
							For Each vSPServicesRow In vSPServicesRows Do
								vSPServicesRow.IsManualAuthor = SessionParameters.CurrentUser;
								vSPServicesRow.IsManualDate = CurrentSessionDate();
							EndDo;
						EndIf;
					EndDo;
				EndIf;
			EndIf;
		EndIf;
	Else
		If pWriteMode = DocumentWriteMode.UndoPosting Or DeletionMark Then
			vSkipSetDeletionMarkCheck = False;
			If AdditionalProperties.Property("AllowSetDeletionMark") And AdditionalProperties.AllowSetDeletionMark Then
				vSkipSetDeletionMarkCheck = True;
			EndIf;
			If Not vSkipSetDeletionMarkCheck And Not cmCheckUserPermissions("HavePermissionToSetDeletionMarkForResourceReservations") Then
				pCancel = True;
				tcCommonFunctionOnClientServer.UserMessage(NStr("en='You do not have rights to mark resource reservation for deletion! Change reservation status instead.';ru='Нет прав на пометку брони ресурсов на удаление! Вместо удаления измените статус брони.';de='Sie haben kein Recht, Ressource Reservierung für Löschung zu markieren! Ändern Sie stattdessen den reservierungsstatus.'"));
				Return;
			EndIf;
		EndIf;
		If ValueIsFilled(Hotel) And Hotel.DoNotEditSettledDocs And DoCharging And 
		  (pWriteMode = DocumentWriteMode.UndoPosting Or DeletionMark) And 
		  (Services.Total("Sum") <> 0 Or Services.Total("Quantity") <> 0) And 
		   ValueIsFilled(ResourceReservationStatus) And ResourceReservationStatus.ServicesAreDelivered And 
		   cmGetDocumentCharges(Ref, Undefined, Undefined, Hotel, Undefined, True).Count() > 0 Then
			vDocBalanceIsZero = False;
			vDocBalancesRow = cmGetDocumentCurrentAccountsReceivableBalance(Ref);
			If vDocBalancesRow <> Undefined Then
				If vDocBalancesRow.SumBalance = 0 And vDocBalancesRow.QuantityBalance = 0 Then
					vDocBalanceIsZero = True;
				EndIf;
			Else
				vDocBalanceIsZero = True;
			EndIf;
			If vDocBalanceIsZero Then
				pCancel = True;
				tcCommonFunctionOnClientServer.UserMessage(NStr("en='All resource reservation charges are closed by settlements! Resource reservation is read only.';
				             |ru='Все начисления брони ресурсов уже закрыты актами об оказании услуг! Редактирование такой брони запрещено.';
							 |de='Alle Anrechnungen der Ressourcenreservierung wurden bereits durch Übergabeprotokolle über die Dienstleistungserbringung geschlossen! Die Bearbeitung einer solchen Reservierung ist verboten.'"));
				Return;
			EndIf;
		EndIf;
		If DeletionMark Then
			If ValueIsFilled(ResourceReservationStatus) And ResourceReservationStatus.ServicesAreDelivered Then
				If Not cmCheckUserPermissions("HavePermissionToEditCompletedResourceReservations") Then
					pCancel = True;
					tcCommonFunctionOnClientServer.UserMessage(NStr("en='You do not have rights to edit completed resource reservations where services are delivered!'; ru='Нет прав на редактирование завершенной брони ресурсов по которой все услуги оказаны!'; de='Es gibt keine Rechte, die geschlossen Ressourcenbuchungen zu editieren!'"));
					Return;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(ResourceReservationStatus) Then
		If Not ResourceReservationStatus.IsActive And 
           Not ResourceReservationStatus.ServicesAreDelivered Then
			If Not ValueIsFilled(DateOfAnnulation) Then
				DateOfAnnulation = CurrentSessionDate();
				AuthorOfAnnulation = SessionParameters.CurrentUser;
			EndIf;
		Else
			If ValueIsFilled(DateOfAnnulation) Then
				DateOfAnnulation = '00010101';
				AuthorOfAnnulation = Catalogs.Employees.EmptyRef();
				AnnulationReason = Undefined;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure Filling(pBase)
	// Fill from the base
	If ValueIsFilled(pBase) Then
		If Not TypeOf(pBase) = Type("Structure") Then 
			If TypeOf(pBase) = Type("CatalogRef.ObjectTemplates") Then
				// Fill attributes with default values
				pmFillAttributesWithDefaultValues();
				// Fill attributes from template
				If ValueIsFilled(pBase.SourceOfBusiness) Then
					SourceOfBusiness = pBase.SourceOfBusiness;
				EndIf;
				If ValueIsFilled(pBase.MarketingCode) Then
					MarketingCode = pBase.MarketingCode;
					MarketingCodeConfirmationText = TrimAll(pBase.MarketingCodeConfirmationText);
				EndIf;
				If ValueIsFilled(pBase.ClientType) Then
					ClientType = pBase.ClientType;
					ClientTypeConfirmationText = TrimAll(pBase.ClientTypeConfirmationText);
				EndIf;
				If ValueIsFilled(pBase.ResourceType) Then
					ResourceType = pBase.ResourceType;
				EndIf;
				If ValueIsFilled(pBase.Resource) Then
					Resource = pBase.Resource;
				EndIf;
				If ValueIsFilled(pBase.DiscountType) Then
					DiscountType = pBase.DiscountType;
					DiscountConfirmationText = TrimAll(pBase.DiscountConfirmationText);
				EndIf;
				If pBase.Discount <> 0 Then
					Discount = pBase.Discount;
				EndIf;
				If ValueIsFilled(pBase.DiscountServiceGroup) Then
					DiscountServiceGroup = pBase.DiscountServiceGroup;
				EndIf;
				If ValueIsFilled(pBase.ResourceReservationStatus) Then
					ResourceReservationStatus = pBase.ResourceReservationStatus;
					DoCharging = pBase.DoCharging;
				EndIf;
				If Not IsBlankString(pBase.ConfirmationReply) Then
					ConfirmationReply = TrimAll(pBase.ConfirmationReply);
				EndIf;
				If ValueIsFilled(pBase.PlannedPaymentMethod) Then
					PlannedPaymentMethod = pBase.PlannedPaymentMethod;
				EndIf;
				If ValueIsFilled(pBase.ReportingCurrency) Then
					ReportingCurrency = pBase.ReportingCurrency;
					ReportingCurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, ReportingCurrency, ExchangeRateDate);
				EndIf;
				If ValueIsFilled(pBase.Company) Then
					Company = pBase.Company;
				EndIf;
				If ValueIsFilled(pBase.Customer) Then
					Customer = pBase.Customer;
				EndIf;
				If ValueIsFilled(pBase.Contract) Then
					Contract = pBase.Contract;
				EndIf;
				If Not IsBlankString(pBase.Remarks) Then
					Remarks = TrimAll(pBase.Remarks);
				EndIf;
			ElsIf TypeOf(pBase) = Type("DocumentRef.Accommodation") Then
				FillPropertyValues(ThisObject, pBase, , "Number, Date, Author, DeletionMark, Posted");
				ParentDoc = pBase;
				DateTimeFrom = cm1SecondShift(pBase.CheckOutDate);
				Duration = 1;
				DateTimeTo = pmCalculateDateTimeTo();
				// Fill attributes with default values
				pmFillAttributesWithDefaultValues(pBase.RoomQuota);
			ElsIf TypeOf(pBase) = Type("CatalogRef.RoomQuotas") Then
				Hotel = pBase.Hotel;
				Customer = pBase.Customer;
				pmCreateGuestGroup(pBase);
				DateTimeFrom = cm1SecondShift(pBase.PeriodFrom);
				Duration = 1;
				DateTimeTo = cm0SecondShift(DateTimeFrom) + Duration * 3600;
				// Fill attributes with default values
				pmFillAttributesWithDefaultValues(pBase);
			ElsIf TypeOf(pBase) = Type("CatalogRef.GuestGroups") Then
				Hotel = pBase.Owner;
				GuestGroup = pBase;
				Customer = pBase.Customer;
				Contract = pBase.Contract;
				Agent = pBase.Agent;
				Client = pBase.Client;
				SourceOfBusiness = pBase.SourceOfBusiness;
				MarketingCode = pBase.MarketingCode;
				TripPurpose = pBase.TripPurpose;
				DateTimeFrom = cm1SecondShift(pBase.CheckInDate);
				Duration = 1;
				DateTimeTo = cm0SecondShift(DateTimeFrom) + Duration * 3600;
				// Fill attributes with default values
				pmFillAttributesWithDefaultValues(pBase.Allotment);
			EndIf;
			// Calculate services
			pmCalculateServices();
		Else
			If pBase.Property("NotDefaultValues") Then
				If Not pBase.NotDefaultValues Then
					pmFillAttributesWithDefaultValues();	
				EndIf;
			EndIf;
		EndIf;
	Else
		// Fill attributes with default values
		pmFillAttributesWithDefaultValues();   
	EndIf;
EndProcedure // Filling

// -----------------------------------------------------------------------------
Procedure OnSetNewNumber(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(Hotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(Hotel);
	ElsIf ValueIsFilled(SessionParameters.CurrentHotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(SessionParameters.CurrentHotel);
	EndIf;
	If vPrefix <> "" Then
		pPrefix = vPrefix;
	EndIf;
EndProcedure // OnSetNewNumber

// -----------------------------------------------------------------------------
Procedure OnCopy(pCopiedObject)
	ExternalCode = "";
	AnnulationReason = Undefined;
	AuthorOfAnnulation = Catalogs.Employees.EmptyRef();
	DateOfAnnulation = '00010101';
	// Clear author and date of manual services
	For Each vSrvRow In Services Do
		If ValueIsFilled(vSrvRow.IsManualAuthor) Then
			vSrvRow.IsManualAuthor = Undefined;
		EndIf;
		If ValueIsFilled(vSrvRow.IsManualDate) Then
			vSrvRow.IsManualDate = '00010101';
		EndIf;
	EndDo;
	// Calculate services
	pmCalculateServices();
EndProcedure // OnCopy

// -----------------------------------------------------------------------------
Procedure UndoPosting(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	// Check user permissions to change status
	If Not AdditionalProperties.Property("InfoBaseUpdateMode") And Not AdditionalProperties.Property("CloseOfDayMode") Then
		If Not cmCheckUserPermissions("HavePermissionToEditResourceReservations") Then
			If (Not ValueIsFilled(Author.Department) And Author <> SessionParameters.CurrentUser Or 
			   ValueIsFilled(Author.Department) And Author <> SessionParameters.CurrentUser And 
			   ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Department) And 
			   Author.Department <> SessionParameters.CurrentUser.Department) Then
				Raise String(Ref) + " - " + NStr("en='You do not have rights to edit resource reservations!'; ru='Нет прав на редактирование брони ресурсов!'; de='Es gibt keine Rechte, die Ressourcenbuchungen zu editieren!'");
			EndIf;
		EndIf;
		If Not cmCheckUserPermissions("HavePermissionToEditClosedForEditDocuments") Then
			If IsClosedForEdit Then
				Raise String(Ref) + " - " + NStr("en='You do not have rights to change closed for edit document!';ru='Нет прав на изменение документа с включенным запретом редактирования!';de='Sie haben keine Rechte, das Dokument zu bearbeiten mit eingeschlossenem Bearbeitungsverbot!'");
			EndIf;
		EndIf;
		If ValueIsFilled(ResourceReservationStatus) And ResourceReservationStatus.ServicesAreDelivered Then
			If Not cmCheckUserPermissions("HavePermissionToEditCompletedResourceReservations") Then
				Raise String(Ref) + " - " + NStr("en='You do not have rights to edit completed resource reservations where services are delivered!'; ru='Нет прав на редактирование завершенной брони ресурсов по которой все услуги оказаны!'; de='Es gibt keine Rechte, die geschlossen Ressourcenbuchungen zu editieren!'");
			EndIf;
		EndIf;
	EndIf;
	// Remove charges
	pmUndoPosting(pCancel)
EndProcedure // UndoPosting

// -----------------------------------------------------------------------------
Procedure BeforeDelete(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	// Remove charges
	If Posted Then
		If ValueIsFilled(Hotel) And Hotel.DoNotEditSettledDocs And DoCharging And 
		  (Services.Total("Sum") <> 0 Or Services.Total("Quantity") <> 0) And 
		   ValueIsFilled(ResourceReservationStatus) And ResourceReservationStatus.ServicesAreDelivered And 
		   cmGetDocumentCharges(Ref, Undefined, Undefined, Hotel, Undefined, True).Count() > 0 Then
			vDocBalanceIsZero = False;
			vDocBalancesRow = cmGetDocumentCurrentAccountsReceivableBalance(Ref);
			If vDocBalancesRow <> Undefined Then
				If vDocBalancesRow.SumBalance = 0 And vDocBalancesRow.QuantityBalance = 0 Then
					vDocBalanceIsZero = True;
				EndIf;
			Else
				vDocBalanceIsZero = True;
			EndIf;
			If vDocBalanceIsZero Then
				pCancel = True;
				tcCommonFunctionOnClientServer.UserMessage(NStr("en='All resource reservation charges are closed by settlements! Resource reservation is read only.';
				             |ru='Все начисления брони ресурсов уже закрыты актами об оказании услуг! Редактирование такой брони запрещено.';
							 |de='Alle Anrechnungen der Ressourcenreservierung wurden bereits durch Übergabeprotokolle über die Dienstleistungserbringung geschlossen! Die Bearbeitung einer solchen Reservierung ist verboten.'"));
				Return;
			EndIf;
		EndIf;
		pmUndoPosting(pCancel);
	EndIf;
EndProcedure // BeforeDelete

// -----------------------------------------------------------------------------
Procedure pmUndoPosting(pCancel) Export
	// Build table of already charged services and then delete all (or future) chargings 
	vChargesTab = cmGetTableOfResourceReservationAlreadyChargedServices(Ref);
	For Each vChargesRec In vChargesTab Do
		vChargeObj = vChargesRec.Ref.GetObject();
		If Not cmIfChargeIsInClosedDay(vChargeObj) Then
			vChargeObj.SetDeletionMark(True);
		EndIf;
	EndDo;
EndProcedure // UndoPosting

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure FillRRHAttributes(pRRHRec, pPeriod)
	FillPropertyValues(pRRHRec, ThisObject);
	
	pRRHRec.Period = pPeriod;
	
	pRRHRec.IsResourceBlock = False;
	If ValueIsFilled(EventActivity) And 
	   TypeOf(EventActivity) = Type("CatalogRef.EventActivities") And 
	   EventActivity.IsResourceBlock Then
		pRRHRec.IsResourceBlock = True;
	EndIf;
	
	pRRHRec.Timestamp = CurrentSessionDate();
EndProcedure // FillRRHAttributes

// -----------------------------------------------------------------------------
Procedure FillPreparationRRHAttributes(pRRHRec, pPeriod)
	If PreparationTime > 0 Then
		FillPropertyValues(pRRHRec, ThisObject);
		
		pRRHRec.Period = pPeriod;

		pRRHRec.IsPreparationTime = True;
		pRRHRec.IsResourceBlock = False;
		If ValueIsFilled(EventActivity) And 
		   TypeOf(EventActivity) = Type("CatalogRef.EventActivities") And 
		   EventActivity.IsResourceBlock Then
			pRRHRec.IsResourceBlock = True;
		EndIf;
		
		pRRHRec.DateTimeFrom = DateTimeFrom - PreparationTime*60;
		pRRHRec.DateTimeTo = DateTimeFrom - 60;
		pRRHRec.Duration = cmCalculateDurationInHours(pRRHRec.DateTimeFrom, pRRHRec.DateTimeTo);
		
		pRRHRec.Timestamp = CurrentSessionDate();
	EndIf;
EndProcedure // FillPreparationRRHAttributes

// -----------------------------------------------------------------------------
Procedure FillDisassembleRRHAttributes(pRRHRec, pPeriod)
	If DisassembleTime > 0 Then
		FillPropertyValues(pRRHRec, ThisObject);
		
		pRRHRec.Period = pPeriod;

		pRRHRec.IsDisassembleTime = True;
		pRRHRec.IsResourceBlock = False;
		If ValueIsFilled(EventActivity) And 
		   TypeOf(EventActivity) = Type("CatalogRef.EventActivities") And 
		   EventActivity.IsResourceBlock Then
			pRRHRec.IsResourceBlock = True;
		EndIf;
		
		pRRHRec.DateTimeFrom = DateTimeTo + 60;
		pRRHRec.DateTimeTo = DateTimeTo + DisassembleTime*60;
		pRRHRec.Duration = cmCalculateDurationInHours(pRRHRec.DateTimeFrom, pRRHRec.DateTimeTo);
		
		pRRHRec.Timestamp = CurrentSessionDate();
	EndIf;
EndProcedure // FillDisassembleRRHAttributes

// -----------------------------------------------------------------------------
Procedure FillServiceRRHAttributes(pRRHRec, pSrvRow, pPeriod)
	FillPropertyValues(pRRHRec, ThisObject);
	FillPropertyValues(pRRHRec, pSrvRow);

	pRRHRec.Period = pPeriod;
	pRRHRec.RowNumber = pSrvRow.LineNumber;

	pRRHRec.IsResourceBlock = False;
	If ValueIsFilled(pSrvRow.EventActivity) Then
		If TypeOf(pSrvRow.EventActivity) = Type("CatalogRef.EventActivities") And pSrvRow.EventActivity.IsResourceBlock Then
			pRRHRec.IsResourceBlock = True;
		EndIf;
	ElsIf ValueIsFilled(EventActivity) Then
		pRRHRec.EventActivity = EventActivity;
		If TypeOf(EventActivity) = Type("CatalogRef.EventActivities") And EventActivity.IsResourceBlock Then
			pRRHRec.IsResourceBlock = True;
		EndIf;
	EndIf;

	If ValueIsFilled(pSrvRow.ServiceResource) Then
		pRRHRec.Resource = pSrvRow.ServiceResource;
		pRRHRec.ResourceType = pRRHRec.Resource.Owner;
	Else
		pRRHRec.Resource = Resource;
		pRRHRec.ResourceType = ResourceType;
	EndIf;
	If ValueIsFilled(pSrvRow.TimeFrom) Or ValueIsFilled(pSrvRow.TimeTo) Then
		vDateTimeFrom = BegOfDay(pSrvRow.AccountingDate) + (pSrvRow.TimeFrom - BegOfDay(pSrvRow.TimeFrom));
		If pSrvRow.TimeFrom < pSrvRow.TimeTo Then
			vDateTimeTo = BegOfDay(pSrvRow.AccountingDate) + (pSrvRow.TimeTo - BegOfDay(pSrvRow.TimeTo));
		Else
			vDateTimeTo = BegOfDay(pSrvRow.AccountingDate) + 24*3600 + (pSrvRow.TimeTo - BegOfDay(pSrvRow.TimeTo));
		EndIf;
		pRRHRec.DateTimeFrom = vDateTimeFrom;
		pRRHRec.DateTimeTo = vDateTimeTo;
		pRRHRec.Duration = cmCalculateDurationInHours(pRRHRec.DateTimeFrom, pRRHRec.DateTimeTo);
	Else
		pRRHRec.DateTimeFrom = DateTimeFrom;
		pRRHRec.DateTimeTo = DateTimeTo;
		pRRHRec.Duration = Duration;
	EndIf;

	pRRHRec.Timestamp = CurrentSessionDate();
EndProcedure // FillServiceRRHAttributes

// -----------------------------------------------------------------------------
Procedure FillServicePreparationRRHAttributes(pRRHRec, pSrvRow, pPeriod)
	If pSrvRow.PreparationTime > 0 Then
		If ValueIsFilled(pSrvRow.TimeFrom) Or ValueIsFilled(pSrvRow.TimeTo) Then
			FillPropertyValues(pRRHRec, ThisObject);
			FillPropertyValues(pRRHRec, pSrvRow);

			pRRHRec.Period = pPeriod;
			pRRHRec.RowNumber = pSrvRow.LineNumber;
			pRRHRec.IsPreparationTime = True;

			pRRHRec.IsResourceBlock = False;
			If ValueIsFilled(pSrvRow.EventActivity) Then
				If TypeOf(pSrvRow.EventActivity) = Type("CatalogRef.EventActivities") And pSrvRow.EventActivity.IsResourceBlock Then
					pRRHRec.IsResourceBlock = True;
				EndIf;
			ElsIf ValueIsFilled(EventActivity) Then
				pRRHRec.EventActivity = EventActivity;
				If TypeOf(EventActivity) = Type("CatalogRef.EventActivities") And EventActivity.IsResourceBlock Then
					pRRHRec.IsResourceBlock = True;
				EndIf;
			EndIf;
			
			If ValueIsFilled(pSrvRow.ServiceResource) Then
				pRRHRec.Resource = pSrvRow.ServiceResource;
				pRRHRec.ResourceType = pRRHRec.Resource.Owner;
			Else
				pRRHRec.Resource = Resource;
				pRRHRec.ResourceType = ResourceType;
			EndIf;

			vDateTimeFrom = BegOfDay(pSrvRow.AccountingDate) + (pSrvRow.TimeFrom - BegOfDay(pSrvRow.TimeFrom));
			If pSrvRow.TimeFrom < pSrvRow.TimeTo Then
				vDateTimeTo = BegOfDay(pSrvRow.AccountingDate) + (pSrvRow.TimeTo - BegOfDay(pSrvRow.TimeTo));
			Else
				vDateTimeTo = BegOfDay(pSrvRow.AccountingDate) + 24*3600 + (pSrvRow.TimeTo - BegOfDay(pSrvRow.TimeTo));
			EndIf;
			
			pRRHRec.DateTimeFrom = vDateTimeFrom - pSrvRow.PreparationTime*60;
			pRRHRec.DateTimeTo = vDateTimeFrom - 60;
			pRRHRec.Duration = cmCalculateDurationInHours(pRRHRec.DateTimeFrom, pRRHRec.DateTimeTo);

			pRRHRec.Timestamp = CurrentSessionDate();
		EndIf;
	EndIf;
EndProcedure // FillServicePreparationRRHAttributes

// -----------------------------------------------------------------------------
Procedure FillServiceDisassembleRRHAttributes(pRRHRec, pSrvRow, pPeriod)
	If pSrvRow.DisassembleTime > 0 Then
		If ValueIsFilled(pSrvRow.TimeFrom) Or ValueIsFilled(pSrvRow.TimeTo) Then
			FillPropertyValues(pRRHRec, ThisObject);
			FillPropertyValues(pRRHRec, pSrvRow);

			pRRHRec.Period = pPeriod;
			pRRHRec.RowNumber = pSrvRow.LineNumber;
			pRRHRec.IsDisassembleTime = True;

			pRRHRec.IsResourceBlock = False;
			If ValueIsFilled(pSrvRow.EventActivity) Then
				If TypeOf(pSrvRow.EventActivity) = Type("CatalogRef.EventActivities") And pSrvRow.EventActivity.IsResourceBlock Then
					pRRHRec.IsResourceBlock = True;
				EndIf;
			ElsIf ValueIsFilled(EventActivity) Then
				pRRHRec.EventActivity = EventActivity;
				If TypeOf(EventActivity) = Type("CatalogRef.EventActivities") And EventActivity.IsResourceBlock Then
					pRRHRec.IsResourceBlock = True;
				EndIf;
			EndIf;
			
			If ValueIsFilled(pSrvRow.ServiceResource) Then
				pRRHRec.Resource = pSrvRow.ServiceResource;
				pRRHRec.ResourceType = pRRHRec.Resource.Owner;
			Else
				pRRHRec.Resource = Resource;
				pRRHRec.ResourceType = ResourceType;
			EndIf;

			vDateTimeFrom = BegOfDay(pSrvRow.AccountingDate) + (pSrvRow.TimeFrom - BegOfDay(pSrvRow.TimeFrom));
			If pSrvRow.TimeFrom < pSrvRow.TimeTo Then
				vDateTimeTo = BegOfDay(pSrvRow.AccountingDate) + (pSrvRow.TimeTo - BegOfDay(pSrvRow.TimeTo));
			Else
				vDateTimeTo = BegOfDay(pSrvRow.AccountingDate) + 24*3600 + (pSrvRow.TimeTo - BegOfDay(pSrvRow.TimeTo));
			EndIf;
			
			pRRHRec.DateTimeFrom = vDateTimeTo + 60;
			pRRHRec.DateTimeTo = vDateTimeTo + pSrvRow.DisassembleTime*60;
			pRRHRec.Duration = cmCalculateDurationInHours(pRRHRec.DateTimeFrom, pRRHRec.DateTimeTo);

			pRRHRec.Timestamp = CurrentSessionDate();
		EndIf;
	EndIf;
EndProcedure // FillServiceDisassembleRRHAttributes

// -----------------------------------------------------------------------------
Procedure PostToResourceReservationHistory(pCancel)
	// Do main resorce movements
	If ValueIsFilled(Resource) And DoResourceReservation Then
		If PreparationTime > 0 Then
			vRRHRec = RegisterRecords.ResourceReservationHistory.Add();
			FillPreparationRRHAttributes(vRRHRec, Date);
		EndIf;
		
		vRRHRec = RegisterRecords.ResourceReservationHistory.Add();
		FillRRHAttributes(vRRHRec, Date);

		If DisassembleTime > 0 Then
			vRRHRec = RegisterRecords.ResourceReservationHistory.Add();
			FillDisassembleRRHAttributes(vRRHRec, Date);
		EndIf;
	EndIf;	
		
	// Check services and do additional resource movements
	For Each vSrvRow In Services Do
		If ValueIsFilled(vSrvRow.ServiceResource) And TypeOf(vSrvRow.ServiceResource) = Type("CatalogRef.Resources") And vSrvRow.DoResourceReservation Then
			If vSrvRow.PreparationTime > 0 Then
				vRRHRec = RegisterRecords.ResourceReservationHistory.Add();
				FillServicePreparationRRHAttributes(vRRHRec, vSrvRow, Date);
			EndIf;

			vRRHRec = RegisterRecords.ResourceReservationHistory.Add();
			FillServiceRRHAttributes(vRRHRec, vSrvRow, Date);

			If vSrvRow.DisassembleTime > 0 Then
				vRRHRec = RegisterRecords.ResourceReservationHistory.Add();
				FillServiceDisassembleRRHAttributes(vRRHRec, vSrvRow, Date);
			EndIf;
		EndIf;
	EndDo;
	
	// Write RegisterRecords	
	RegisterRecords.ResourceReservationHistory.Write();
EndProcedure // PostToResourceReservationHistory

// -----------------------------------------------------------------------------
Procedure FillSFAttributes(pSFRec, pSrvRec, pPeriod, pServiceDate, pSrvService, pSrvQuantity, pSrvVATRate, pSrvSumInReportingCurrency, pSrvVATSumInReportingCurrency, pSrvDiscountSumInReportingCurrency, pSrvVATDiscountSumInReportingCurrency, pSrvCommissionSumInReportingCurrency, pSrvVATCommissionSumInReportingCurrency, pIsInRoomRevenue = True, pHotelAccountingDate, pFolio)
	vIsMainService = True;
	vMainService = pSrvRec.Service;
	If pSrvService <> pSrvRec.Service Then
		vIsMainService = False;
	EndIf;
	
	FillPropertyValues(pSFRec, ThisObject);
	FillPropertyValues(pSFRec, pSrvRec);
	
	pSFRec.Period = pPeriod;
	If pSFRec.AccountingDate < pHotelAccountingDate Then
		pSFRec.Period = pHotelAccountingDate;
		pSFRec.AccountingDate = pHotelAccountingDate;
	EndIf;
	pSFRec.ServiceDate = pServiceDate;
	
	pSFRec.Service = pSrvService;
	
	pSFRec.ParentDoc = Ref;
	pSFRec.Folio = pFolio;
	
	If ValueIsFilled(pSrvRec.ServiceResource) And TypeOf(pSrvRec.ServiceResource) = Type("CatalogRef.Resources") Then
		pSFRec.Resource = pSrvRec.ServiceResource;
		pSFRec.ResourceType = pSrvRec.ServiceResource.Owner;
		If pSrvRec.ServiceResource.IsBoardPlace Then
			pSFRec.BoardPlace = pSrvRec.ServiceResource;
		EndIf;
	EndIf;
	
	// Fill customer, contract and payment method from the folio
	If ValueIsFilled(ChargingFolio) Then
		pSFRec.Customer = ChargingFolio.Customer;
		pSFRec.Contract = ChargingFolio.Contract;
		pSFRec.Agent = ChargingFolio.Agent;
		pSFRec.PaymentMethod = ChargingFolio.PaymentMethod;
		If ValueIsFilled(ChargingFolio.GuestGroup) Then
			pSFRec.GuestGroup = ChargingFolio.GuestGroup;
		EndIf;
	EndIf;
	
	If ValueIsFilled(Client) Then
		pSFRec.Age = Client.Age;
		pSFRec.AgeRange = Client.AgeRange;
	Else
		pSFRec.Age = 0;
		pSFRec.AgeRange = Undefined;
	EndIf;
	
	pSFRec.Sales = pSrvSumInReportingCurrency;
	pSFRec.SalesWithoutVAT = pSFRec.Sales - pSrvVATSumInReportingCurrency;
	pSFRec.VATSum = pSrvVATSumInReportingCurrency;
	pSFRec.RoomRevenue = 0;
	pSFRec.RoomRevenueWithoutVAT = 0;
	pSFRec.ExtraBedRevenue = 0;
	pSFRec.ExtraBedRevenueWithoutVAT = 0;
	pSFRec.Quantity = pSrvQuantity;
	pSFRec.Price = cmRecalculatePrice(pSFRec.Sales, pSFRec.Quantity);
	pSFRec.ResourceRevenue = 0;
	pSFRec.ResourceRevenueWithoutVAT = 0;
	
	If pSrvRec.IsResourceRevenue Then
		If pIsInRoomRevenue Then
			pSFRec.ResourceRevenue = pSFRec.Sales;
			pSFRec.ResourceRevenueWithoutVAT = pSFRec.SalesWithoutVAT;
		Else
			pSFRec.ResourceRevenue = 0;
			pSFRec.ResourceRevenueWithoutVAT = 0;
		EndIf;
		If vIsMainService Then
			pSFRec.HoursRented = pSFRec.Quantity;
			If pSFRec.Service.IsPricePerMinute Then
				pSFRec.HoursRented = pSFRec.Quantity/60;
			EndIf;
		EndIf;
	EndIf;
	
	pSFRec.CommissionSum = pSrvCommissionSumInReportingCurrency;
	pSFRec.CommissionSumWithoutVAT = pSrvCommissionSumInReportingCurrency - pSrvVATCommissionSumInReportingCurrency;
	
	pSFRec.DiscountSum = pSrvDiscountSumInReportingCurrency;
	pSFRec.DiscountSumWithoutVAT = pSrvDiscountSumInReportingCurrency - pSrvVATDiscountSumInReportingCurrency;
	
	pSFRec.RoomsRented = 0;
	pSFRec.BedsRented = 0;
	pSFRec.AdditionalBedsRented = 0;
	pSFRec.GuestDays = 0;
	pSFRec.GuestsCheckedIn = 0;
	pSFRec.RoomsCheckedIn = 0;
	pSFRec.BedsCheckedIn = 0;
	pSFRec.AdditionalBedsCheckedIn = 0;
	pSFRec.BookingWindow = 0;
	
	// Check if customer and agent are the same
	If ValueIsFilled(ChargingFolio) Then
		vDoNotPostCommission = False;
		If ValueIsFilled(ChargingFolio.Agent) And ChargingFolio.Agent.DoNotPostCommission Then
			vDoNotPostCommission = True;
		EndIf;
		If Not vDoNotPostCommission Then
			If ValueIsFilled(ChargingFolio.Agent) And 
			   ChargingFolio.Agent <> ChargingFolio.Customer And 
			   pSrvCommissionSumInReportingCurrency <> 0 Then
				pSFRec.CommissionSum = 0;
				pSFRec.CommissionSumWithoutVAT = 0;
				
				// Add new record
				vSFRec = RegisterRecords.SalesForecast.Add();
				FillPropertyValues(vSFRec, pSFRec, , "RecordType");
				
				// Fill dimensions
				vSFRec.Customer = ChargingFolio.Agent;
				vSFRec.Contract = ChargingFolio.Agent.AgentCommissionContract;
				vSFRec.Agent = ChargingFolio.Agent;
				vSFRec.GuestGroup = Catalogs.GuestGroups.EmptyRef();
				
				// Reset resources
				vSFRec.Sales = 0;
				vSFRec.SalesWithoutVAT = 0;
				vSFRec.RoomRevenue = 0;
				vSFRec.RoomRevenueWithoutVAT = 0;
				vSFRec.ExtraBedRevenue = 0;
				vSFRec.ExtraBedRevenueWithoutVAT = 0;
				vSFRec.Quantity = 0;
				vSFRec.DiscountSum = 0;
				vSFRec.DiscountSumWithoutVAT = 0;
				vSFRec.RoomsRented = 0;
				vSFRec.BedsRented = 0;
				vSFRec.AdditionalBedsRented = 0;
				vSFRec.GuestDays = 0;
				vSFRec.GuestsCheckedIn = 0;
				vSFRec.RoomsCheckedIn = 0;
				vSFRec.BedsCheckedIn = 0;
				vSFRec.AdditionalBedsCheckedIn = 0;
				vSFRec.ResourceRevenue = 0;
				vSFRec.ResourceRevenueWithoutVAT = 0;
				vSFRec.HoursRented = 0;
				vSFRec.BookingWindow = 0;
				
				// Fill commission
				vSFRec.CommissionSum = pSrvCommissionSumInReportingCurrency;
				vSFRec.CommissionSumWithoutVAT = pSrvCommissionSumInReportingCurrency - pSrvVATCommissionSumInReportingCurrency;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // FillSFAttributes

// -----------------------------------------------------------------------------
Procedure FillARFAttributes(pARFRec, pSrvRec, pPeriod, pHotelAccountingDate, pFolio)
	FillPropertyValues(pARFRec, ThisObject);
	FillPropertyValues(pARFRec, pSrvRec);
	
	pARFRec.Period = pPeriod;
	If pARFRec.AccountingDate < pHotelAccountingDate Then
		pARFRec.Period = pHotelAccountingDate;
		pARFRec.AccountingDate = pHotelAccountingDate;
	EndIf;
	pARFRec.ParentDoc = Ref;
	pARFRec.Folio = pFolio;
	
	If ValueIsFilled(pSrvRec.ServiceResource) And TypeOf(pSrvRec.ServiceResource) = Type("CatalogRef.Resources") Then
		pARFRec.Resource = pSrvRec.ServiceResource;
	EndIf;
	
	// Fill customer, contract and payment method from the folio
	If ValueIsFilled(ChargingFolio) Then
		pARFRec.Customer = ChargingFolio.Customer;
		pARFRec.Contract = ChargingFolio.Contract;
		pARFRec.Agent = ChargingFolio.Agent;
		pARFRec.PaymentMethod = ChargingFolio.PaymentMethod;
		If ValueIsFilled(ChargingFolio.GuestGroup) Then
			pARFRec.GuestGroup = ChargingFolio.GuestGroup;
		EndIf;
	EndIf;
	
	vSumInFolioCurrency = pSrvRec.Sum - pSrvRec.DiscountSum;
	vVATSumInFolioCurrency = pSrvRec.VATSum - pSrvRec.VATDiscountSum;
	pARFRec.Sales = vSumInFolioCurrency;
	pARFRec.SalesWithoutVAT = vSumInFolioCurrency - vVATSumInFolioCurrency;
	pARFRec.RoomRevenue = 0;
	pARFRec.RoomRevenueWithoutVAT = 0;
	pARFRec.ExtraBedRevenue = 0;
	pARFRec.ExtraBedRevenueWithoutVAT = 0;
	pARFRec.Price = cmRecalculatePrice(vSumInFolioCurrency, pSrvRec.Quantity);
	pARFRec.Quantity = pSrvRec.Quantity;
	
	vDiscountSumInFolioCurrency = pSrvRec.DiscountSum;
	vVATDiscountSumInFolioCurrency = pSrvRec.VATDiscountSum;
	pARFRec.DiscountSum = vDiscountSumInFolioCurrency;
	pARFRec.DiscountSumWithoutVAT = vDiscountSumInFolioCurrency - vVATDiscountSumInFolioCurrency;
	
	pARFRec.RoomsRented = 0;
	pARFRec.BedsRented = 0;
	pARFRec.AdditionalBedsRented = 0;
	pARFRec.GuestDays = 0;
	pARFRec.GuestsCheckedIn = 0;
	pARFRec.RoomsCheckedIn = 0;
	pARFRec.BedsCheckedIn = 0;
	pARFRec.AdditionalBedsCheckedIn = 0;
	pARFRec.BookingWindow = 0;
	
	pARFRec.ExpectedSales = pARFRec.Sales;
	pARFRec.ExpectedSalesWithoutVAT = pARFRec.SalesWithoutVAT;
	pARFRec.ExpectedRoomRevenue = pARFRec.RoomRevenue;
	pARFRec.ExpectedRoomRevenueWithoutVAT = pARFRec.RoomRevenueWithoutVAT;
	pARFRec.ExpectedExtraBedRevenue = pARFRec.ExtraBedRevenue;
	pARFRec.ExpectedExtraBedRevenueWithoutVAT = pARFRec.ExtraBedRevenueWithoutVAT;
	pARFRec.ExpectedDiscountSum = pARFRec.DiscountSum;
	pARFRec.ExpectedDiscountSumWithoutVAT = pARFRec.DiscountSumWithoutVAT;
	pARFRec.ExpectedRoomsRented = pARFRec.RoomsRented;
	pARFRec.ExpectedBedsRented = pARFRec.BedsRented;
	pARFRec.ExpectedAdditionalBedsRented = pARFRec.AdditionalBedsRented;
	pARFRec.ExpectedGuestDays = pARFRec.GuestDays;
	pARFRec.ExpectedGuestsCheckedIn = pARFRec.GuestsCheckedIn;
	pARFRec.ExpectedRoomsCheckedIn = pARFRec.RoomsCheckedIn;
	pARFRec.ExpectedBedsCheckedIn = pARFRec.BedsCheckedIn;
	pARFRec.ExpectedAdditionalBedsCheckedIn = pARFRec.AdditionalBedsCheckedIn;
	pARFRec.ExpectedQuantity = pARFRec.Quantity;
	pARFRec.ExpectedBookingWindow = pARFRec.BookingWindow;
	
	// Commission
	pARFRec.CommissionSum = pSrvRec.CommissionSum;
	pARFRec.CommissionSumWithoutVAT = pSrvRec.CommissionSum - pSrvRec.VATCommissionSum;
	pARFRec.ExpectedCommissionSum = pARFRec.CommissionSum;
	pARFRec.ExpectedCommissionSumWithoutVAT = pARFRec.CommissionSumWithoutVAT;
	
	// Check if customer and agent are the same
	If ValueIsFilled(ChargingFolio) Then
		vDoNotPostCommission = False;
		If ValueIsFilled(ChargingFolio.Agent) And ChargingFolio.Agent.DoNotPostCommission Then
			vDoNotPostCommission = True;
		EndIf;
		If vDoNotPostCommission Then
			pARFRec.CommissionSum = 0;
			pARFRec.CommissionSumWithoutVAT = 0;
			pARFRec.ExpectedCommissionSum = 0;
			pARFRec.ExpectedCommissionSumWithoutVAT = 0;
		Else
			If ValueIsFilled(ChargingFolio.Agent) And 
			   ChargingFolio.Agent <> ChargingFolio.Customer And 
			   pSrvRec.CommissionSum <> 0 Then
				pARFRec.CommissionSum = 0;
				pARFRec.CommissionSumWithoutVAT = 0;
				pARFRec.ExpectedCommissionSum = 0;
				pARFRec.ExpectedCommissionSumWithoutVAT = 0;
				
				// Add new record
				vARFRec = RegisterRecords.AccountsReceivableForecast.Add();
				FillPropertyValues(vARFRec, pARFRec, , "RecordType");
				
				// Fill dimensions
				vARFRec.Customer = ChargingFolio.Agent;
				vARFRec.Contract = ChargingFolio.Agent.AgentCommissionContract;
				vARFRec.Agent = ChargingFolio.Agent;
				vARFRec.GuestGroup = Catalogs.GuestGroups.EmptyRef();
				
				// Reset resources
				vARFRec.Sales = 0;
				vARFRec.SalesWithoutVAT = 0;
				vARFRec.RoomRevenue = 0;
				vARFRec.RoomRevenueWithoutVAT = 0;
				vARFRec.ExtraBedRevenue = 0;
				vARFRec.ExtraBedRevenueWithoutVAT = 0;
				vARFRec.Quantity = 0;
				vARFRec.DiscountSum = 0;
				vARFRec.DiscountSumWithoutVAT = 0;
				vARFRec.RoomsRented = 0;
				vARFRec.BedsRented = 0;
				vARFRec.AdditionalBedsRented = 0;
				vARFRec.GuestDays = 0;
				vARFRec.GuestsCheckedIn = 0;
				vARFRec.RoomsCheckedIn = 0;
				vARFRec.BedsCheckedIn = 0;
				vARFRec.AdditionalBedsCheckedIn = 0;
				vARFRec.BookingWindow = 0;
				
				vARFRec.ExpectedSales = 0;
				vARFRec.ExpectedSalesWithoutVAT = 0;
				vARFRec.ExpectedRoomRevenue = 0;
				vARFRec.ExpectedRoomRevenueWithoutVAT = 0;
				vARFRec.ExpectedExtraBedRevenue = 0;
				vARFRec.ExpectedExtraBedRevenueWithoutVAT = 0;
				vARFRec.ExpectedQuantity = 0;
				vARFRec.ExpectedDiscountSum = 0;
				vARFRec.ExpectedDiscountSumWithoutVAT = 0;
				vARFRec.ExpectedRoomsRented = 0;
				vARFRec.ExpectedBedsRented = 0;
				vARFRec.ExpectedAdditionalBedsRented = 0;
				vARFRec.ExpectedGuestDays = 0;
				vARFRec.ExpectedGuestsCheckedIn = 0;
				vARFRec.ExpectedRoomsCheckedIn = 0;
				vARFRec.ExpectedBedsCheckedIn = 0;
				vARFRec.ExpectedAdditionalBedsCheckedIn = 0;
				vARFRec.ExpectedBookingWindow = 0;
				
				// Fill commission
				vARFRec.CommissionSum = pSrvRec.CommissionSum;
				vARFRec.CommissionSumWithoutVAT = pSrvRec.CommissionSum - pSrvRec.VATCommissionSum;
				vARFRec.ExpectedCommissionSum = vARFRec.CommissionSum;
				vARFRec.ExpectedCommissionSumWithoutVAT = vARFRec.CommissionSumWithoutVAT;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // FillARFAttributes

// -----------------------------------------------------------------------------
Procedure FillExpectedARFAttributes(pARFRec, pSrvRec, pPeriod, pFolio)
	FillPropertyValues(pARFRec, ThisObject);
	FillPropertyValues(pARFRec, pSrvRec);
	
	pARFRec.Period = pPeriod;
	pARFRec.ParentDoc = Ref;
	pARFRec.Folio = pFolio;
	
	If ValueIsFilled(pSrvRec.ServiceResource) And TypeOf(pSrvRec.ServiceResource) = Type("CatalogRef.Resources") Then
		pARFRec.Resource = pSrvRec.ServiceResource;
	EndIf;
	
	// Fill customer, contract and payment method from the folio
	If ValueIsFilled(ChargingFolio) Then
		pARFRec.Customer = ChargingFolio.Customer;
		pARFRec.Contract = ChargingFolio.Contract;
		pARFRec.Agent = ChargingFolio.Agent;
		pARFRec.PaymentMethod = ChargingFolio.PaymentMethod;
		If ValueIsFilled(ChargingFolio.GuestGroup) Then
			pARFRec.GuestGroup = ChargingFolio.GuestGroup;
		EndIf;
	EndIf;
	
	vSumInFolioCurrency = pSrvRec.Sum - pSrvRec.DiscountSum;
	vVATSumInFolioCurrency = pSrvRec.VATSum - pSrvRec.VATDiscountSum;
	pARFRec.ExpectedSales = vSumInFolioCurrency;
	pARFRec.ExpectedSalesWithoutVAT = vSumInFolioCurrency - vVATSumInFolioCurrency;
	pARFRec.ExpectedRoomRevenue = 0;
	pARFRec.ExpectedRoomRevenueWithoutVAT = 0;
	pARFRec.ExpectedExtraBedRevenue = 0;
	pARFRec.ExpectedExtraBedRevenueWithoutVAT = 0;
	pARFRec.Price = cmRecalculatePrice(vSumInFolioCurrency, pSrvRec.Quantity);
	pARFRec.ExpectedQuantity = pSrvRec.Quantity;
	
	vDiscountSumInFolioCurrency = pSrvRec.DiscountSum;
	vVATDiscountSumInFolioCurrency = pSrvRec.VATDiscountSum;
	pARFRec.ExpectedDiscountSum = vDiscountSumInFolioCurrency;
	pARFRec.ExpectedDiscountSumWithoutVAT = vDiscountSumInFolioCurrency - vVATDiscountSumInFolioCurrency;
	
	pARFRec.ExpectedRoomsRented = 0;
	pARFRec.ExpectedBedsRented = 0;
	pARFRec.ExpectedAdditionalBedsRented = 0;
	pARFRec.ExpectedGuestDays = 0;
	pARFRec.ExpectedGuestsCheckedIn = 0;
	pARFRec.ExpectedRoomsCheckedIn = 0;
	pARFRec.ExpectedBedsCheckedIn = 0;
	pARFRec.ExpectedAdditionalBedsCheckedIn = 0;
	pARFRec.ExpectedBookingWindow = 0;
	
	pARFRec.Sales = 0;
	pARFRec.SalesWithoutVAT = 0;
	pARFRec.RoomRevenue = 0;
	pARFRec.RoomRevenueWithoutVAT = 0;
	pARFRec.ExtraBedRevenue = 0;
	pARFRec.ExtraBedRevenueWithoutVAT = 0;
	pARFRec.CommissionSum = 0;
	pARFRec.CommissionSumWithoutVAT = 0;
	pARFRec.DiscountSum = 0;
	pARFRec.DiscountSumWithoutVAT = 0;
	pARFRec.RoomsRented = 0;
	pARFRec.BedsRented = 0;
	pARFRec.AdditionalBedsRented = 0;
	pARFRec.GuestDays = 0;
	pARFRec.GuestsCheckedIn = 0;
	pARFRec.RoomsCheckedIn = 0;
	pARFRec.BedsCheckedIn = 0;
	pARFRec.AdditionalBedsCheckedIn = 0;
	pARFRec.Quantity = 0;
	pARFRec.BookingWindow = 0;
	
	// Commission
	pARFRec.ExpectedCommissionSum = pSrvRec.CommissionSum;
	pARFRec.ExpectedCommissionSumWithoutVAT = pSrvRec.CommissionSum - pSrvRec.VATCommissionSum;
	
	// Check if customer and agent are the same
	If ValueIsFilled(pFolio) Then
		vDoNotPostCommission = False;
		If ValueIsFilled(ChargingFolio.Agent) And ChargingFolio.Agent.DoNotPostCommission Then
			vDoNotPostCommission = True;
		EndIf;
		If vDoNotPostCommission Then
			pARFRec.ExpectedCommissionSum = 0;
			pARFRec.ExpectedCommissionSumWithoutVAT = 0;
		Else
			If ValueIsFilled(ChargingFolio.Agent) And 
			   ChargingFolio.Agent <> ChargingFolio.Customer And 
			   pSrvRec.CommissionSum <> 0 Then
				pARFRec.ExpectedCommissionSum = 0;
				pARFRec.ExpectedCommissionSumWithoutVAT = 0;
				
				// Add new record
				vARFRec = RegisterRecords.AccountsReceivableForecast.Add();
				FillPropertyValues(vARFRec, pARFRec, , "RecordType");
				
				// Fill dimensions
				vARFRec.Customer = ChargingFolio.Agent;
				vARFRec.Contract = ChargingFolio.Agent.AgentCommissionContract;
				vARFRec.Agent = ChargingFolio.Agent;
				vARFRec.GuestGroup = Catalogs.GuestGroups.EmptyRef();
				
				// Reset expected resources
				vARFRec.ExpectedSales = 0;
				vARFRec.ExpectedSalesWithoutVAT = 0;
				vARFRec.ExpectedRoomRevenue = 0;
				vARFRec.ExpectedRoomRevenueWithoutVAT = 0;
				vARFRec.ExpectedExtraBedRevenue = 0;
				vARFRec.ExpectedExtraBedRevenueWithoutVAT = 0;
				vARFRec.ExpectedQuantity = 0;
				vARFRec.ExpectedDiscountSum = 0;
				vARFRec.ExpectedDiscountSumWithoutVAT = 0;
				vARFRec.ExpectedRoomsRented = 0;
				vARFRec.ExpectedBedsRented = 0;
				vARFRec.ExpectedAdditionalBedsRented = 0;
				vARFRec.ExpectedGuestDays = 0;
				vARFRec.ExpectedGuestsCheckedIn = 0;
				vARFRec.ExpectedRoomsCheckedIn = 0;
				vARFRec.ExpectedBedsCheckedIn = 0;
				vARFRec.ExpectedAdditionalBedsCheckedIn = 0;
				vARFRec.ExpectedBookingWindow = 0;
				
				// Fill expected commission
				vARFRec.ExpectedCommissionSum = pSrvRec.CommissionSum;
				vARFRec.ExpectedCommissionSumWithoutVAT = pSrvRec.CommissionSum - pSrvRec.VATCommissionSum;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // FillExpectedARFAttributes

// -----------------------------------------------------------------------------
Procedure FillCancelledARFAttributes(pARFRec, pSrvRec, pPeriod, pFolio)
	FillPropertyValues(pARFRec, ThisObject);
	FillPropertyValues(pARFRec, pSrvRec);
	
	pARFRec.Period = pPeriod;
	pARFRec.ParentDoc = Ref;
	pARFRec.Folio = pFolio;
	
	If ValueIsFilled(pSrvRec.ServiceResource) And TypeOf(pSrvRec.ServiceResource) = Type("CatalogRef.Resources") Then
		pARFRec.Resource = pSrvRec.ServiceResource;
	EndIf;
	
	// Fill customer, contract and payment method from the folio
	If ValueIsFilled(pFolio) Then
		pARFRec.Customer = pFolio.Customer;
		pARFRec.Contract = pFolio.Contract;
		pARFRec.Agent = pFolio.Agent;
		pARFRec.PaymentMethod = pFolio.PaymentMethod;
		If ValueIsFilled(pFolio.GuestGroup) Then
			pARFRec.GuestGroup = pFolio.GuestGroup;
		EndIf;
	EndIf;
	
	vSumInFolioCurrency = pSrvRec.Sum - pSrvRec.DiscountSum;
	vVATSumInFolioCurrency = pSrvRec.VATSum - pSrvRec.VATDiscountSum;
	
	pARFRec.ExpectedSales = vSumInFolioCurrency;
	pARFRec.ExpectedSalesWithoutVAT = vSumInFolioCurrency - vVATSumInFolioCurrency;
	pARFRec.ExpectedRoomRevenue = 0;
	pARFRec.ExpectedRoomRevenueWithoutVAT = 0;
	pARFRec.ExpectedExtraBedRevenue = 0;
	pARFRec.ExpectedExtraBedRevenueWithoutVAT = 0;
	pARFRec.Price = cmRecalculatePrice(vSumInFolioCurrency, pSrvRec.Quantity);
	pARFRec.ExpectedQuantity = pSrvRec.Quantity;
	
	vDiscountSumInFolioCurrency = pSrvRec.DiscountSum;
	vVATDiscountSumInFolioCurrency = pSrvRec.VATDiscountSum;
	pARFRec.ExpectedDiscountSum = vDiscountSumInFolioCurrency;
	pARFRec.ExpectedDiscountSumWithoutVAT = vDiscountSumInFolioCurrency - vVATDiscountSumInFolioCurrency;
	
	pARFRec.ExpectedRoomsRented = 0;
	pARFRec.ExpectedBedsRented = 0;
	pARFRec.ExpectedAdditionalBedsRented = 0;
	pARFRec.ExpectedGuestDays = 0;
	pARFRec.ExpectedGuestsCheckedIn = 0;
	pARFRec.ExpectedRoomsCheckedIn = 0;
	pARFRec.ExpectedBedsCheckedIn = 0;
	pARFRec.ExpectedAdditionalBedsCheckedIn = 0;
	pARFRec.ExpectedBookingWindow = 0;
	
	pARFRec.Sales = 0;
	pARFRec.SalesWithoutVAT = 0;
	pARFRec.RoomRevenue = 0;
	pARFRec.RoomRevenueWithoutVAT = 0;
	pARFRec.ExtraBedRevenue = 0;
	pARFRec.ExtraBedRevenueWithoutVAT = 0;
	pARFRec.CommissionSum = 0;
	pARFRec.CommissionSumWithoutVAT = 0;
	pARFRec.DiscountSum = 0;
	pARFRec.DiscountSumWithoutVAT = 0;
	pARFRec.RoomsRented = 0;
	pARFRec.BedsRented = 0;
	pARFRec.AdditionalBedsRented = 0;
	pARFRec.GuestDays = 0;
	pARFRec.GuestsCheckedIn = 0;
	pARFRec.RoomsCheckedIn = 0;
	pARFRec.BedsCheckedIn = 0;
	pARFRec.AdditionalBedsCheckedIn = 0;
	pARFRec.Quantity = 0;
	pARFRec.BookingWindow = 0;
	
	// Commission
	pARFRec.ExpectedCommissionSum = pSrvRec.CommissionSum;
	pARFRec.ExpectedCommissionSumWithoutVAT = pSrvRec.CommissionSum - pSrvRec.VATCommissionSum;
	
	// Check if customer and agent are the same
	If ValueIsFilled(pFolio) Then
		vDoNotPostCommission = False;
		If ValueIsFilled(pFolio.Agent) And pFolio.Agent.DoNotPostCommission Then
			vDoNotPostCommission = True;
		EndIf;
		If vDoNotPostCommission Then
			pARFRec.ExpectedCommissionSum = 0;
			pARFRec.ExpectedCommissionSumWithoutVAT = 0;
		Else
			If ValueIsFilled(pFolio.Agent) And 
			   pFolio.Agent <> pFolio.Customer And 
			   pSrvRec.CommissionSum <> 0 Then
				pARFRec.ExpectedCommissionSum = 0;
				pARFRec.ExpectedCommissionSumWithoutVAT = 0;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // FillCancelledARFAttributes

// -----------------------------------------------------------------------------
Procedure FillServiceRegistrationAttributes(pSRRec, pSrvRec, pPeriod, pFolio) 
	pSRRec.Period = pPeriod;
	
	FillPropertyValues(pSRRec, ThisObject);
	FillPropertyValues(pSRRec, pSrvRec);
	If ValueIsFilled(pFolio) Then
		If ValueIsFilled(pFolio.GuestGroup) Then
			pSRRec.GuestGroup = pFolio.GuestGroup;
		EndIf;
	EndIf;
	
	// Fill folio
	pSRRec.Folio = pFolio;
	
	// Fill parent document by this document ref
	pSRRec.ParentDoc = Ref;
	
	// Fill accounting date
	pSRRec.AccountingDate = BegOfDay(pPeriod);
	
	// Resources
	pSRRec.Sum = pSrvRec.Sum - pSrvRec.DiscountSum;
	
	// Attributes
	pSRRec.Price = cmRecalculatePrice(pSRRec.Sum, pSRRec.Quantity);
EndProcedure // FillServiceRegistrationAttributes

// -----------------------------------------------------------------------------
Procedure PostToForecastSales(pCancel, pCloseOfDayMode, pHotelAccountingDate, pCRTab)
	// Do movement on accounting date for each service in services
	For Each vSrvRec In Services Do
		If Not ValueIsFilled(vSrvRec.Service) Or vSrvRec.Quantity = 0 Then
			Continue;
		EndIf;
		If Not DoCharging Or 
		   DoCharging And 
		   Not vSrvRec.Service.AlwaysChargeInAdvance And 
		   Hotel.CloseOfPeriodDoChargeServices And 
		   vSrvRec.AccountingDate > DoChargingToDate And
		   vSrvRec.AccountingDate > pHotelAccountingDate Then
			If Not ResourceReservationStatus.DoNotChargeForecastServices Then
				vSrvService = vSrvRec.Service;
				vServiceType = vSrvService.ServiceType;
				
				If Not (ValueIsFilled(vServiceType) And vServiceType.ActualAmountIsChargedExternally And vSrvRec.AccountingDate < pHotelAccountingDate) Then
					vSrvSumInReportingCurrency = Round(cmConvertCurrencies((vSrvRec.Sum - vSrvRec.DiscountSum), FolioCurrency, , ReportingCurrency, , ?(ValueIsFilled(vSrvRec.AccountingDate), vSrvRec.AccountingDate, ExchangeRateDate), Hotel), 2);
					vSrvDiscountSumInReportingCurrency = Round(cmConvertCurrencies(vSrvRec.DiscountSum, FolioCurrency, , ReportingCurrency, , ?(ValueIsFilled(vSrvRec.AccountingDate), vSrvRec.AccountingDate, ExchangeRateDate), Hotel), 2);
					vSrvVATDiscountSumInReportingCurrency = Round(cmConvertCurrencies(vSrvRec.VATDiscountSum, FolioCurrency, , ReportingCurrency, , ?(ValueIsFilled(vSrvRec.AccountingDate), vSrvRec.AccountingDate, ExchangeRateDate), Hotel), 2);
					vSrvCommissionSumInReportingCurrency = Round(cmConvertCurrencies(vSrvRec.CommissionSum, FolioCurrency, , ReportingCurrency, , ?(ValueIsFilled(vSrvRec.AccountingDate), vSrvRec.AccountingDate, ExchangeRateDate), Hotel), 2);
					vSrvVATCommissionSumInReportingCurrency = Round(cmConvertCurrencies(vSrvRec.VATCommissionSum, FolioCurrency, , ReportingCurrency, , ?(ValueIsFilled(vSrvRec.AccountingDate), vSrvRec.AccountingDate, ExchangeRateDate), Hotel), 2);
					vSrvVATSumInReportingCurrency = Round(cmConvertCurrencies(vSrvRec.VATSum, FolioCurrency, , ReportingCurrency, , ?(ValueIsFilled(vSrvRec.AccountingDate), vSrvRec.AccountingDate, ExchangeRateDate), Hotel), 2);
					vSrvQuantity = vSrvRec.Quantity;
					vSrvVATRate = vSrvRec.VATRate;
					vRateSumInReportingCurrency = ?(vSrvRec.IsResourceRevenue, vSrvSumInReportingCurrency - vSrvDiscountSumInReportingCurrency, 0);
					vVATRateSumInReportingCurrency = cmCalculateVATSum(vSrvVATRate, vRateSumInReportingCurrency, vSrvRec.AccountingDate);
					
					vBaseSumInReportingCurrency = vSrvSumInReportingCurrency;

					// Set current service folio
					vFolio = ChargingFolio;
					// Check group charging rules
					If pCRTab.Count() > 0 Then
						For Each vCRRow In pCRTab Do
							If cmIsServiceFitToTheChargingRule(vCRRow, vSrvRec.Service, vSrvRec.AccountingDate, False, False, , True) Then
								vCurFolio = vCRRow.ChargingFolio;
								If FolioCurrency = vCurFolio.FolioCurrency Then
									vFolio = vCurFolio;
									Break;
								EndIf;
							EndIf;
						EndDo;
					EndIf;
					
					If vSrvSumInReportingCurrency >= 0 Then
						vBDLSettingsDate = GetServiceBreakdownListActiveDate(vSrvService, vSrvRec.AccountingDate, Hotel);
						vBDLSettings = cmGetServiceBreakdownList(vSrvService, vBDLSettingsDate, Hotel, Catalogs.RoomRates.EmptyRef(), Catalogs.RoomTypes.EmptyRef(), Catalogs.AccommodationTypes.EmptyRef());
						For Each vBDLSettingsRow In vBDLSettings Do
							If ValueIsFilled(vBDLSettingsRow.Item) And Not vBDLSettingsRow.IsNotInForecast Then
								vItemService = vBDLSettingsRow.Item;
								
								// Item VAT rate
								vItemVATRate = vSrvRec.VATRate;
								If ValueIsFilled(vBDLSettingsRow.VATRate) And Not vBDLSettingsRow.IsTax Then
									vItemVATRate = vBDLSettingsRow.VATRate;
								EndIf;
								
								// Item price
								vItemPrice = 0;
								If vBDLSettingsRow.Price <> 0 And ValueIsFilled(vBDLSettingsRow.Currency) Then
									vItemPrice = cmConvertCurrencies(vBDLSettingsRow.Price, vBDLSettingsRow.Currency, , ReportingCurrency, , ExchangeRateDate, Hotel);
								ElsIf Not IsBlankString(vBDLSettingsRow.PriceCalculationFormula) Then
									vPriceFormula = TrimAll(vBDLSettingsRow.PriceCalculationFormula);
									vPriceFormula = cmGetFormulaExecutionText(vPriceFormula, ThisObject);
									SetSafeMode(True);
									Execute(vPriceFormula);
									SetSafeMode(False);
				 				EndIf;
								
								// Item quantity
								vItemQuantity = vSrvQuantity;
								If vBDLSettingsRow.Quantity <> 0 Then
									vItemQuantity = vBDLSettingsRow.Quantity;
								ElsIf Not IsBlankString(vBDLSettingsRow.QuantityCalculationFormula) Then
									vQuantityFormula = TrimAll(vBDLSettingsRow.QuantityCalculationFormula);
									vQuantityFormula = cmGetFormulaExecutionText(vQuantityFormula, ThisObject);
									SetSafeMode(True);
									Execute(vQuantityFormula);
									SetSafeMode(False);
								EndIf;
								
								// Check rest of amount
								If Round(vItemPrice*vItemQuantity, 2) > vSrvSumInReportingCurrency Then
									If vItemQuantity <> 0 Then
										vItemPrice = Round(vSrvSumInReportingCurrency/vItemQuantity, 2);
									Else
										Continue;
									EndIf;
								EndIf;
								
								// Service date
								vServiceDate = vSrvRec.AccountingDate;
								If vBDLSettingsRow.ServiceDateNumber > 0 Then
									If BegOfDay(DateTimeFrom) <= BegOfDay(vServiceDate) Then
										vN = (BegOfDay(vServiceDate) - BegOfDay(DateTimeFrom))/(24*3600) + 1;
										If vN <> vBDLSettingsRow.ServiceDateNumber Then
											vItemQuantity = 0;
										EndIf;
									EndIf;
								ElsIf vBDLSettingsRow.ServiceDateNumber < 0 Then
									If BegOfDay(DateTimeTo) >= BegOfDay(vServiceDate) Then
										vN = -(BegOfDay(DateTimeTo) - BegOfDay(vServiceDate))/(24*3600) - 1;
										If vN <> vBDLSettingsRow.ServiceDateNumber Then
											vItemQuantity = 0;
										EndIf;
									EndIf;
								EndIf;
								If vItemQuantity = 0 Then
									Continue;
								EndIf;
								If vBDLSettingsRow.ServiceDateShift <> 0 Then
									If BegOfDay(DateTimeFrom) < BegOfDay(DateTimeTo) Then
										vServiceDate = vServiceDate + vBDLSettingsRow.ServiceDateShift * 24 * 3600;
									EndIf;
								EndIf;
								
								// Calculate amount to be posted by this item service
								vItemSumInReportingCurrency = Round(vItemPrice*vItemQuantity, 2);
								If Not vBDLSettingsRow.IsTax Then
									vItemVATSumInReportingCurrency = cmCalculateVATSum(vItemVATRate, vItemSumInReportingCurrency, vSrvRec.AccountingDate);
								Else
									vItemVATSumInReportingCurrency = 0;
								EndIf;
								vItemDiscountSumInReportingCurrency = 0;
								vItemVATDiscountSumInReportingCurrency = 0;
								vItemCommissionSumInReportingCurrency = 0;
								vItemVATCommissionSumInReportingCurrency = 0;
								
								// Do correction of the amounts to be posted by main charge service
								vSrvSumInReportingCurrency = vSrvSumInReportingCurrency - vItemSumInReportingCurrency;
								vSrvDiscountSumInReportingCurrency = vSrvDiscountSumInReportingCurrency - vItemDiscountSumInReportingCurrency;
								vSrvCommissionSumInReportingCurrency = vSrvCommissionSumInReportingCurrency - vItemCommissionSumInReportingCurrency;
								vSrvVATSumInReportingCurrency = vSrvVATSumInReportingCurrency - vItemVATSumInReportingCurrency;
								vSrvVATDiscountSumInReportingCurrency = vSrvVATDiscountSumInReportingCurrency - vItemVATDiscountSumInReportingCurrency;
								vSrvVATCommissionSumInReportingCurrency = vSrvVATCommissionSumInReportingCurrency - vItemVATCommissionSumInReportingCurrency;
								
								vSFRec = RegisterRecords.SalesForecast.Add();
								FillSFAttributes(vSFRec, vSrvRec, vSrvRec.AccountingDate, vServiceDate, vItemService, vItemQuantity, vItemVATRate, vItemSumInReportingCurrency, vItemVATSumInReportingCurrency, vItemDiscountSumInReportingCurrency, vItemVATDiscountSumInReportingCurrency, vItemCommissionSumInReportingCurrency, vItemVATCommissionSumInReportingCurrency, vBDLSettingsRow.IsInRoomRevenue, pHotelAccountingDate, vFolio);
							EndIf;
						EndDo;
					EndIf;
					
					vSFRec = RegisterRecords.SalesForecast.Add();
					FillSFAttributes(vSFRec, vSrvRec, vSrvRec.AccountingDate, vSrvRec.AccountingDate, vSrvService, vSrvQuantity, vSrvVATRate, vSrvSumInReportingCurrency, vSrvVATSumInReportingCurrency, vSrvDiscountSumInReportingCurrency, vSrvVATDiscountSumInReportingCurrency, vSrvCommissionSumInReportingCurrency, vSrvVATCommissionSumInReportingCurrency, , pHotelAccountingDate, vFolio);
					
					vARFRec = RegisterRecords.AccountsReceivableForecast.Add();
					FillARFAttributes(vARFRec, vSrvRec, vSrvRec.AccountingDate, pHotelAccountingDate, vFolio);
					
					// Post to service registration if necessary
					If vSrvService.ServiceRegistrationIsTurnedOn Then
						vSRRec = RegisterRecords.ServiceRegistration.AddReceipt();
						FillServiceRegistrationAttributes(vSRRec, vSrvRec, vSrvRec.AccountingDate, vFolio);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
EndProcedure // PostToForecastSales

// -----------------------------------------------------------------------------
Procedure PostToExpectedCustomerSales(pCancel, pCloseOfDayMode, pAccountingDate, pCRTab)
	// Do movement on accounting date for each service in services
	For Each vSrvRec In Services Do	
		If Not ValueIsFilled(vSrvRec.Service) Or vSrvRec.Quantity = 0 Then
			Continue;
		EndIf;
		If ValueIsFilled(vSrvRec.Service) Then
			If vSrvRec.Service.AlwaysChargeInAdvance Then
				Continue;
			EndIf;
			If Hotel.CloseOfPeriodDoChargeServices And vSrvRec.AccountingDate > DoChargingToDate And 
			  (Not pCloseOfDayMode And vSrvRec.AccountingDate > pAccountingDate Or 
			   pCloseOfDayMode And vSrvRec.AccountingDate > pAccountingDate) Then
				Continue;
			EndIf;
			// Set current service folio
			vFolio = ChargingFolio;
			// Check group charging rules
			If pCRTab.Count() > 0 Then
				For Each vCRRow In pCRTab Do
					If cmIsServiceFitToTheChargingRule(vCRRow, vSrvRec.Service, vSrvRec.AccountingDate, False, False, , True) Then
						vCurFolio = vCRRow.ChargingFolio;
						If FolioCurrency = vCurFolio.FolioCurrency Then
							vFolio = vCurFolio;
							Break;
						EndIf;
					EndIf;
				EndDo;
			EndIf;
			If ValueIsFilled(ResourceReservationStatus) And ResourceReservationStatus.ServicesAreDelivered Then
				vARFRec = RegisterRecords.AccountsReceivableForecast.Add();
				FillExpectedARFAttributes(vARFRec, vSrvRec, vSrvRec.AccountingDate, vFolio);
			ElsIf Not ValueIsFilled(vSrvRec.Service.ServiceType) Or ValueIsFilled(vSrvRec.Service.ServiceType) And 
			      Not vSrvRec.Service.ServiceType.ActualAmountIsChargedExternally Then
				vARFRec = RegisterRecords.AccountsReceivableForecast.Add();
				FillExpectedARFAttributes(vARFRec, vSrvRec, vSrvRec.AccountingDate, vFolio);
			EndIf;
		EndIf;
	EndDo;
EndProcedure // PostToExpectedCustomerSales

// -----------------------------------------------------------------------------
Procedure PostToCancelledExpectedCustomerSales(pCancel, pCRTab)
	// Do movement on accounting date for each service in services
	For Each vSrvRec In Services Do	
		If Not ValueIsFilled(vSrvRec.Service) Or vSrvRec.Quantity = 0 Then
			Continue;
		EndIf;
		If ValueIsFilled(vSrvRec.Service) Then
			// Set current service folio
			vFolio = ChargingFolio;
			// Check group charging rules
			If pCRTab.Count() > 0 Then
				For Each vCRRow In pCRTab Do
					If cmIsServiceFitToTheChargingRule(vCRRow, vSrvRec.Service, vSrvRec.AccountingDate, False, False, , True) Then
						vCurFolio = vCRRow.ChargingFolio;
						If FolioCurrency = vCurFolio.FolioCurrency Then
							vFolio = vCurFolio;
							Break;
						EndIf;
					EndIf;
				EndDo;
			EndIf;
			vARFRec = RegisterRecords.AccountsReceivableForecast.Add();
			FillCancelledARFAttributes(vARFRec, vSrvRec, vSrvRec.AccountingDate, vFolio);
		EndIf;
	EndDo;
EndProcedure // PostToCancelledExpectedCustomerSales

// -----------------------------------------------------------------------------
Procedure PostToRegisters(pCancel, pCloseOfDayMode, pHotelAccountingDate, pCRTab)
	// To the resource reservation history
	PostToResourceReservationHistory(pCancel);
	// If reservation is active
	If ResourceReservationStatus.IsActive And Not ResourceReservationStatus.DoNotChargeForecastServices Then
		// To the forecast sales
		PostToForecastSales(pCancel, pCloseOfDayMode, pHotelAccountingDate, pCRTab);
	EndIf;
EndProcedure // PostToRegisters

// -----------------------------------------------------------------------------
Procedure DoChargeTransfer(pServiceRow, pChargeRow)
	vChargeFolio = pChargeRow.Folio;
	vServiceFolio = pServiceRow.Folio;
	If vChargeFolio <> vServiceFolio Then
		vChargeObj = pChargeRow.Ref.GetObject();
		FillPropertyValues(vChargeObj, pServiceRow, , "Folio");
		If Not ValueIsFilled(pChargeRow.ChargeTransfer) Then
			vChargeObj.Folio = vServiceFolio;
		EndIf;
		If TypeOf(pChargeRow.ParentDoc) <> TypeOf(Ref) Then
			vChargeObj.ParentDoc = Ref;
		EndIf;
		vChargeObj.Date = pServiceRow.AccountingDate;
		vChargeObj.ServiceDate = pServiceRow.AccountingDate;
		vChargeObj.SetTime(AutoTimeMode.DontUse);
		If Not ValueIsFilled(vChargeObj.Author) Then
			vChargeObj.Author = SessionParameters.CurrentUser;
		EndIf;
		vChargeObj.IsCorrection = False;
		vChargeObj.CorrectionDate = '00010101';
		vChargeObj.CorrectedCharge = Undefined;
		vChargeObj.Write(DocumentWriteMode.Posting);
	EndIf;
EndProcedure // DoChargeTransfer

// -----------------------------------------------------------------------------
Procedure DoCharge(pServiceRow, pChargeRow, pCurrentAccountingDate = '00010101', pSwitchOffAutoCorrections = True)
	If ValueIsFilled(pServiceRow.AccountingDate) Then
		If pChargeRow = Undefined Then
			vChargeObj = Documents.Charge.CreateDocument();
			FillPropertyValues(vChargeObj, pServiceRow);
			If pServiceRow.AccountingDate < pCurrentAccountingDate Then
				If pSwitchOffAutoCorrections And Not (ValueIsFilled(ResourceReservationStatus) And ResourceReservationStatus.ServicesAreDelivered) Then
				   // Do nothing
				   Return;
				EndIf;
				vChargeObj.Date = pCurrentAccountingDate;
				vChargeObj.ServiceDate = pServiceRow.AccountingDate;
				If pSwitchOffAutoCorrections Then
					vChargeObj.IsCorrection = False;
					vChargeObj.CorrectionDate = '00010101';
				Else
					vChargeObj.IsCorrection = True;
					vChargeObj.CorrectionDate = pServiceRow.AccountingDate;
				EndIf;
			Else
				vChargeObj.Date = pServiceRow.AccountingDate;
				vChargeObj.ServiceDate = pServiceRow.AccountingDate;
				vChargeObj.IsCorrection = False;
				vChargeObj.CorrectionDate = '00010101';
			EndIf;
			vChargeObj.CorrectedCharge = Undefined;
			vChargeObj.Author = SessionParameters.CurrentUser;
			vChargeObj.SetTime(AutoTimeMode.DontUse);
			If ValueIsFilled(pServiceRow.IsManualAuthor) Then
				vChargeObj.Author = pServiceRow.IsManualAuthor;
			EndIf;
			vChargeObj.ParentDoc = Ref;
		Else
			vChargeRef = pChargeRow.Ref;
			// Try to find posted correction charges and if they are not available (were deleted) then clear CorrectedCharge field
			vSkipAccountingDateCheck = False;
			If pSwitchOffAutoCorrections And vChargeRef.CorrectedCharge = vChargeRef Then
				vCorrectionCharges = cmGetChargeCorrectionCharges(vChargeRef);
				If vCorrectionCharges.Count() = 0 Then
					vSkipAccountingDateCheck = True;
					vChargeObj = vChargeRef.GetObject();
					vChargeObj.IsCorrection = False;
					vChargeObj.CorrectionDate = '00010101';
					vChargeObj.CorrectedCharge = Undefined;
					vChargeObj.AdditionalProperties.Insert("ChargeSplitMode", True);
					If vChargeObj.Posted Then
						vChargeObj.Write(DocumentWriteMode.Posting);
					Else
						vChargeObj.DeletionMark = False;
						vChargeObj.Write(DocumentWriteMode.Write);
					EndIf;
					vChargeRef = vChargeObj.Ref;
				EndIf;
			EndIf;
			If vChargeRef.CorrectedCharge <> vChargeRef Then
				If BegOfDay(vChargeRef.Date) < pCurrentAccountingDate And Not vSkipAccountingDateCheck Then
					If pSwitchOffAutoCorrections Then
						If pServiceRow.SourceOfBusiness <> vChargeRef.SourceOfBusiness Or 
						   pServiceRow.MarketingCode <> vChargeRef.MarketingCode Or
						   pServiceRow.ClientType <> vChargeRef.ClientType Then
							vChargeObj = vChargeRef.GetObject();
							FillPropertyValues(vChargeObj, pServiceRow);
							vChargeObj.IsCorrection = False;
							vChargeObj.CorrectionDate = '00010101';
							vChargeObj.CorrectedCharge = Undefined;
							vChargeObj.Date = BegOfDay(vChargeRef.Date);
							vChargeObj.ServiceDate = pServiceRow.AccountingDate;
							If Not ValueIsFilled(vChargeObj.Author) Then
								vChargeObj.Author = SessionParameters.CurrentUser;
							EndIf;
							If ValueIsFilled(pServiceRow.IsManualAuthor) Then
								vChargeObj.Author = pServiceRow.IsManualAuthor;
							EndIf;
							vChargeObj.ParentDoc = Ref;
							vChargeObj.SetTime(AutoTimeMode.DontUse);
						Else
						   // Do nothing
						   Return;
						EndIf;
					Else
						vChargeObj = vChargeRef.Copy();
						FillPropertyValues(vChargeObj, pServiceRow);
						vChargeObj.Date = pCurrentAccountingDate;
						vChargeObj.ServiceDate = pServiceRow.AccountingDate;
						vChargeObj.SetTime(AutoTimeMode.DontUse);
						vChargeObj.Author = SessionParameters.CurrentUser;
						vChargeObj.ParentDoc = Ref;
						vChargeObj.IsCorrection = True;
						vChargeObj.CorrectionDate = vChargeRef.Date;
						vChargeObj.CorrectedCharge = vChargeRef;
						// If all resources are zero, then do nothing
						If vChargeObj.Sum = 0 And vChargeObj.VATSum = 0 And 
						   vChargeObj.DiscountSum = 0 And vChargeObj.VATDiscountSum = 0 And 
						   vChargeObj.CommissionSum = 0 And vChargeObj.VATCommissionSum = 0 And
						   vChargeObj.RoomsRented = 0 And vChargeObj.BedsRented = 0 And vChargeObj.AdditionalBedsRented = 0 And 
						   vChargeObj.GuestDays = 0 And vChargeObj.GuestsCheckedIn = 0 Then
						   // Do nothing
						   Return;
						EndIf;
					EndIf;
				Else
					vChargeObj = vChargeRef.GetObject();
					FillPropertyValues(vChargeObj, pServiceRow);
					vChargeObj.IsCorrection = False;
					vChargeObj.CorrectionDate = '00010101';
					vChargeObj.CorrectedCharge = Undefined;
					vChargeObj.Date = BegOfDay(vChargeRef.Date);
					vChargeObj.ServiceDate = pServiceRow.AccountingDate;
					If Not ValueIsFilled(vChargeObj.Author) Then
						vChargeObj.Author = SessionParameters.CurrentUser;
					EndIf;
					If ValueIsFilled(pServiceRow.IsManualAuthor) Then
						vChargeObj.Author = pServiceRow.IsManualAuthor;
					EndIf;
					vChargeObj.ParentDoc = Ref;
					If vSkipAccountingDateCheck Then
						vChargeObj.AdditionalProperties.Insert("ChargeSplitMode", True);
					EndIf;
					vChargeObj.SetTime(AutoTimeMode.DontUse);
				EndIf;
			Else
				// Do nothing
				Return;
			EndIf;
		EndIf;
		
		// Resource
		If ValueIsFilled(pServiceRow.ServiceResource) And TypeOf(pServiceRow.ServiceResource) = Type("CatalogRef.Resources") Then
			vChargeObj.Resource = pServiceRow.ServiceResource; 
		EndIf;
		
		// Fill charge exchange rate date and folio and reporting currency exchange rates
		vChargeObj.ExchangeRateDate = ?(ValueIsFilled(pServiceRow.AccountingDate), pServiceRow.AccountingDate, ExchangeRateDate);
		vChargeObj.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(vChargeObj.Hotel, vChargeObj.FolioCurrency, vChargeObj.ExchangeRateDate);
		vChargeObj.ReportingCurrencyExchangeRate = cmGetCurrencyExchangeRate(vChargeObj.Hotel, vChargeObj.ReportingCurrency, vChargeObj.ExchangeRateDate);
		
		// Fill charge payment section
		vChargeObj.PaymentSection = vChargeObj.Service.PaymentSection;
		
		// Do not add splitted services to the hotel product sales
		If vChargeObj.IsSplit Then
			vChargeObj.HotelProduct = Catalogs.HotelProducts.EmptyRef();
		EndIf;

		vChargeIsNew = vChargeObj.IsNew();
		
		// Post charge
		If vChargeObj.Folio.DeletionMark Then
			vFolioObj = vChargeObj.Folio.GetObject();
			vFolioObj.SetDeletionMark(False);
		EndIf;
		vChargeObj.Write(DocumentWriteMode.Posting);

		If Not vChargeIsNew Then
			ChargesToRepostStorno.Add(vChargeObj.Ref);
		EndIf;
	EndIf;
EndProcedure // DoCharge

// -----------------------------------------------------------------------------
Procedure DeleteCharge(pChargeRow, pCurrentAccountingDate = '00010101', pSwitchOffAutoCorrections = True)
	vChargeRef = pChargeRow.Ref;
	// Try to find posted correction charges and if they are not available (were deleted) then clear CorrectedCharge field
	If pSwitchOffAutoCorrections And vChargeRef.CorrectedCharge = vChargeRef Then
		vCorrectionCharges = cmGetChargeCorrectionCharges(vChargeRef);
		If vCorrectionCharges.Count() = 0 Then
			vChargeObj = vChargeRef.GetObject();
			vChargeObj.IsCorrection = False;
			vChargeObj.CorrectionDate = '00010101';
			vChargeObj.CorrectedCharge = Undefined;
			vChargeObj.AdditionalProperties.Insert("ChargeSplitMode", True);
			If vChargeObj.Posted Then
				vChargeObj.Write(DocumentWriteMode.Posting);
			Else
				vChargeObj.DeletionMark = False;
				vChargeObj.Write(DocumentWriteMode.Write);
			EndIf;
			vChargeRef = vChargeObj.Ref;
		EndIf;
	EndIf;
	// Check charge accounting date
	If vChargeRef.CorrectedCharge <> vChargeRef Then
		If BegOfDay(vChargeRef.Date) < pCurrentAccountingDate Then
			If pSwitchOffAutoCorrections Then
				If Not vChargeRef.IsSplit And 
				  (SourceOfBusiness <> vChargeRef.SourceOfBusiness Or 
				   MarketingCode <> vChargeRef.MarketingCode Or
				   ClientType <> vChargeRef.ClientType) Then
					// Update charge hotel product
					vChargeObj = vChargeRef.GetObject();
					vChargeObj.SourceOfBusiness = SourceOfBusiness;
					vChargeObj.MarketingCode = MarketingCode;
					vChargeObj.ClientType = ClientType;
					If vChargeObj.Folio.DeletionMark Then
						vFolioObj = vChargeObj.Folio.GetObject();
						vFolioObj.SetDeletionMark(False);
					EndIf;
					vChargeObj.Write(DocumentWriteMode.Posting);
				EndIf;
			Else
				vChargeObj = vChargeRef.Copy();
				vChargeObj.pmFillAuthorAndDate(pCurrentAccountingDate);
				vChargeObj.IsCorrection = True;
				vChargeObj.CorrectionDate = vChargeRef.Date;
				vChargeObj.CorrectedCharge = vChargeRef;
				// Correction for resources
				vChargeObj.Quantity = -pChargeRow.Quantity;
				vChargeObj.Sum = -pChargeRow.Sum;
				vChargeObj.VATSum = -pChargeRow.VATSum;
				vChargeObj.DiscountSum = -pChargeRow.DiscountSum;
				vChargeObj.VATDiscountSum = -pChargeRow.VATDiscountSum;
				vChargeObj.CommissionSum = -pChargeRow.CommissionSum;
				vChargeObj.VATCommissionSum = -pChargeRow.VATCommissionSum;
				vChargeObj.RoomsRented = -pChargeRow.RoomsRented;
				vChargeObj.BedsRented = -pChargeRow.BedsRented;
				vChargeObj.AdditionalBedsRented = -pChargeRow.AdditionalBedsRented;
				vChargeObj.GuestDays = -pChargeRow.GuestDays;
				vChargeObj.GuestsCheckedIn = -pChargeRow.GuestsCheckedIn;
				vChargeObj.Write(DocumentWriteMode.Posting);
			EndIf;
		Else
			vChargeObj = vChargeRef.GetObject();
			vChargeObj.SetDeletionMark(True);
		EndIf;
	EndIf;
EndProcedure // DeleteCharge

// -----------------------------------------------------------------------------
//  Checks if all service row resources like amount, quantity, VAT quantity, discount sum and so on are equal zero
//
// Parameters:
//  pSrvRow	 - ValueTableRow - Service row to check
// 
// Returns:
//  Boolean - True if all resources are zero, False if at least one of them is not
//
Function ServiceResourcesAreZero(pSrvRow)
	If pSrvRow.Quantity = 0 And
	   pSrvRow.Sum = 0 And
	   pSrvRow.VATSum = 0 And
	   pSrvRow.CommissionSum = 0 And
	   pSrvRow.VATCommissionSum = 0 And
	   pSrvRow.DiscountSum = 0 And
	   pSrvRow.VATDiscountSum = 0 And
	   pSrvRow.HoursRented = 0 Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // ServiceResourcesAreZero

// -----------------------------------------------------------------------------
Procedure ChargeServiceDifferences(pTab, pServices, pCharges)
	vCurrentAccountingDate = '00010101';
	If Hotel.DoNotEditClosedDateDocs Then
		vCurrentAccountingDate = tcOnServer.GetForecastStartDate(Hotel);
	EndIf;
	vServicesChargedExternally = New ValueList();
	// For each row in current services table
	For Each vServiceRow In pServices Do
		vService = vServiceRow.Service;
		If Not ValueIsFilled(vService) Then
			Continue;
		EndIf;
		// Try to find difference rows for the current service row
		vDiffRows = pTab.FindRows(New Structure("AccountingDate, LineNumber", vServiceRow.AccountingDate, vServiceRow.LineNumber));
		If vDiffRows.Count() = 1 Then
			vDiffRow = vDiffRows.Get(0);
			If ServiceResourcesAreZero(vDiffRow) Then
				vChargeRow = cmGetChargeRow(pCharges, vServiceRow);
				If vChargeRow <> Undefined Then
					// Charge is the same as current service
					DoChargeTransfer(vServiceRow, vChargeRow);
					pCharges.Delete(vChargeRow);
				EndIf;
				Continue;
			EndIf;
		EndIf;
		// Add new charge for the current service row
		vChargeRow = cmGetChargeRow(pCharges, vServiceRow);
		DoCharge(vServiceRow, vChargeRow, vCurrentAccountingDate, Hotel.SwitchOffAutoCorrections);
		If vChargeRow <> Undefined Then
			pCharges.Delete(vChargeRow);
		EndIf;
	EndDo; // By services
	// Delete all charges left in previously charged table of services
	For Each vChargeRow In pCharges Do
		DeleteCharge(vChargeRow, vCurrentAccountingDate, Hotel.SwitchOffAutoCorrections);
	EndDo;
	pCharges.Clear();
EndProcedure // ChargeServiceDifferences

// -----------------------------------------------------------------------------
Procedure PostToAccumulatingDiscountResources(pServices)
	vAccountingDate = Hotel.AccountingDate;
	If ValueIsFilled(vAccountingDate) And AdditionalProperties.Property("AccountingDate") Then
		If ValueIsFilled(AdditionalProperties.AccountingDate) And TypeOf(AdditionalProperties.AccountingDate) = Type("Date") Then
			vAccountingDate = AdditionalProperties.AccountingDate;
		EndIf;
	EndIf;
	pServices.Columns.Add("IsRoomRevenue", cmGetBooleanTypeDescription());
	pServices.Columns.Add("GuestDays", cmGetNumberTypeDescription(19, 7));
	pServices.Columns.Add("GuestsCheckedIn", cmGetNumberTypeDescription(19, 7));
	pServices.FillValues(False, "IsRoomRevenue");
	pServices.FillValues(0, "GuestDays");
	pServices.FillValues(0, "GuestsCheckedIn");
	vDiscountType = Undefined;
	If ValueIsFilled(DiscountType) And DiscountType.IsAccumulatingDiscount Then
		vDiscountType = DiscountType;
	EndIf;
	vAccDiscounts = cmGetAccumulatingDiscountTypes(vDiscountType, Hotel);
	For Each vAccDiscount In vAccDiscounts Do
		vDiscountType = vAccDiscount.DiscountType;
		If TurnOffAutomaticDiscounts Then
			If DiscountType <> vDiscountType Then
				Continue;
			EndIf;
		EndIf;
		If ValueIsFilled(vDiscountType) And vDiscountType.ExternalBonusSystemIsUsed Then
			Continue;
		EndIf;
		vDiscountServiceGroup = vDiscountType.DiscountServiceGroup;
		For Each vSrvRow In pServices Do
			// Check period
			If vSrvRow.AccountingDate <= vAccountingDate Or vSrvRow.AccountingDate <= DoChargingToDate Then
				Continue;
			EndIf;
			// Check discount type is valid period
			If vSrvRow.AccountingDate < vAccDiscount.DateValidFrom Or ValueIsFilled(vAccDiscount.DateValidTo) And vSrvRow.AccountingDate > vAccDiscount.DateValidTo Then
				Continue;
			EndIf;
			// Process service
			vService = vSrvRow.Service;
			If Not vService.AlwaysChargeInAdvance Then
				If cmIsServiceInServiceGroup(vService, vDiscountServiceGroup) Then
					vDiscountTypeObj = vDiscountType.GetObject();
					vDiscountDimension = Undefined;
					vResource = vDiscountTypeObj.pmCalculateResource(vSrvRow, NumberOfPersons, ChargingFolio, DiscountCard, vDiscountDimension);
					If vResource <> 0 Then
						If ValueIsFilled(vDiscountDimension) Then
							Movement = RegisterRecords.AccumulatingDiscountResources.Add();
							If vResource > 0 Then
								Movement.RecordType = AccumulationRecordType.Receipt;
							Else
								Movement.RecordType = AccumulationRecordType.Expense;
							EndIf;
							Movement.Period = vSrvRow.AccountingDate;
							Movement.DiscountType = vDiscountType;
							Movement.DiscountDimension = vDiscountDimension;
							If vDiscountType.IsPerVisit Or vDiscountType.BonusCalculationFactor <> 0 Then
								Movement.GuestGroup = GuestGroup;
							EndIf;
							Movement.Resource = vResource;
							If vDiscountTypeObj.BonusCalculationFactor <> 0 Then
								Movement.Bonus = vResource * vDiscountTypeObj.BonusCalculationFactor;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	RegisterRecords.AccumulatingDiscountResources.Write();
EndProcedure // PostToAccumulatingDiscountResources

// -----------------------------------------------------------------------------
Procedure FillFolioParameters(pCancel)
	// Set parameters of the charging folio
	If ValueIsFilled(ChargingFolio) Then
		If ValueIsFilled(ChargingFolio.ParentDoc) And ChargingFolio.ParentDoc <> Ref Or 
		   Not ValueIsFilled(ChargingFolio.ParentDoc) And ValueIsFilled(ChargingFolio.GuestGroup) Then
			Return;
		EndIf;
		vFolioRef = ChargingFolio;
		vFolioObj = vFolioRef.GetObject();
		vDoCheckOfAnaliticalParametersChange = False;
		vFolioIsChanged = False;
		If vFolioObj.FolioCurrency <> FolioCurrency Then
			vFolioObj.FolioCurrency = FolioCurrency;
			vDoCheckOfAnaliticalParametersChange = True;
			vFolioIsChanged = True;
		EndIf;
		If Not ChargingFolio.IsMaster Then
			If vFolioObj.Hotel <> Hotel Then
				vFolioObj.Hotel = Hotel;
				vDoCheckOfAnaliticalParametersChange = True;
				vFolioIsChanged = True;
			EndIf;
			If Not vFolioObj.DoNotUpdateCompany Then
				If vFolioObj.Company <> Company Then
					vFolioObj.Company = Company;
					vDoCheckOfAnaliticalParametersChange = True;
					vFolioIsChanged = True;
				EndIf;
			EndIf;
			If vFolioObj.ParentDoc <> Ref Then
				vFolioObj.ParentDoc = Ref;
				vFolioIsChanged = True;
			EndIf;
			If ValueIsFilled(Owner) Then
				If TypeOf(Owner) = Type("CatalogRef.Contracts") Then
					If vFolioObj.Customer <> Owner.Owner Or vFolioObj.Contract <> Owner Then
						If Not vFolioObj.DoNotUpdateCustomer Then
							vFolioObj.Customer = Owner.Owner;
							vFolioObj.Contract = Owner;
							vDoCheckOfAnaliticalParametersChange = True;
							vFolioIsChanged = True;
						EndIf;
					EndIf;
				Else
					If vFolioObj.Customer <> Owner Then
						If Not vFolioObj.DoNotUpdateCustomer Then
							vFolioObj.Customer = Owner;
							vFolioObj.Contract = Catalogs.Contracts.EmptyRef();
							vDoCheckOfAnaliticalParametersChange = True;
							vFolioIsChanged = True;
						EndIf;
					EndIf;
				EndIf;
			Else
				If vFolioObj.Customer <> Owner Then
					If Not vFolioObj.DoNotUpdateCustomer Then
						vFolioObj.Customer = Customer;
						vDoCheckOfAnaliticalParametersChange = True;
						vFolioIsChanged = True;
					EndIf;
				EndIf;
				If vFolioObj.Contract <> Contract Then
					If Not vFolioObj.DoNotUpdateCustomer Then
						vFolioObj.Contract = Contract;
						vDoCheckOfAnaliticalParametersChange = True;
						vFolioIsChanged = True;
					EndIf;
				EndIf;
			EndIf;
			If vFolioObj.Agent <> Agent Then
				If Not vFolioObj.DoNotFillAgent Then
					vFolioObj.Agent = Agent;
					vFolioIsChanged = True;
				EndIf;
			EndIf;
			If vFolioObj.GuestGroup <> GuestGroup Then
				vFolioObj.GuestGroup = GuestGroup;
				vFolioIsChanged = True;
			EndIf;
			If vFolioObj.Client <> Client Then
				vFolioObj.Client = Client;
				vFolioIsChanged = True;
			EndIf;
			If vFolioObj.DateTimeFrom <> DateTimeFrom Then
				vFolioObj.DateTimeFrom = DateTimeFrom;
				vFolioIsChanged = True;
			EndIf;
			If vFolioObj.DateTimeTo <> DateTimeTo Then
				vFolioObj.DateTimeTo = DateTimeTo;
				vFolioIsChanged = True;
			EndIf;
			If ValueIsFilled(PlannedPaymentMethod) Then
				If vFolioObj.PaymentMethod <> PlannedPaymentMethod Then
					vFolioObj.PaymentMethod = PlannedPaymentMethod;
					vFolioIsChanged = True;
				EndIf;
			EndIf;
			If ValueIsFilled(ResourceReservationStatus) Then
				If Not ResourceReservationStatus.IsActive Or 
				   ResourceReservationStatus.ServicesAreDelivered Then
					If Not vFolioObj.IsClosed Then
						// Check that there is no other active documents referencing this folio
						vFolioDocs = cmGetActiveFolioDocuments(vFolioObj.Ref, Ref);
						// Close folio
						If vFolioDocs.Count() = 0 Then
							vFolioObj.IsClosed = True;
							vFolioIsChanged = True;
						EndIf;
					EndIf;
				Else
					If vFolioObj.IsClosed Then
						// Open folio
						vFolioObj.IsClosed = False;
						vFolioIsChanged = True;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		If vFolioObj.DeletionMark Then
			vFolioObj.DeletionMark = False;
			vFolioIsChanged = True;
		EndIf;
		If vFolioIsChanged Then
			If Not vDoCheckOfAnaliticalParametersChange Then
				vFolioObj.AdditionalProperties.Insert("SkipCheckOfAnaliticalParametersChange", True);
			EndIf;
			vFolioObj.Write(DocumentWriteMode.Write);
		EndIf;
	EndIf;
EndProcedure // FillFolioParameters

// -----------------------------------------------------------------------------
Procedure SetFolioStatuses(pCancel)
	If Not ResourceReservationStatus.IsActive Or 
	   ResourceReservationStatus.ServicesAreDelivered Then
		// Close all folios of the current document
		vFolios = cmGetActiveDocumentFolios(Ref);
		If ValueIsFilled(ChargingFolio) And Not ChargingFolio.IsClosed Then
			If vFolios.Find(ChargingFolio, "Folio") = Undefined Then
				vFoliosRow = vFolios.Add();
				vFoliosRow.Folio = ChargingFolio;
			EndIf;
		EndIf;
		For Each vFoliosRow In vFolios Do
			If ValueIsFilled(vFoliosRow.Folio) Then
				If Not vFoliosRow.Folio.IsMaster Then
					vFolioRef = vFoliosRow.Folio;
					// Check that there is no other active documents referencing this folio
					vFolioDocs = cmGetActiveFolioDocuments(vFolioRef, Ref);
					If Not vFolioRef.IsClosed Then
						// Close folio
						If vFolioDocs.Count() = 0 Then
							vFolioObj = vFolioRef.GetObject();
							vFolioObj.IsClosed = True;
							vFolioObj.DeletionMark = False;
							vFolioObj.AdditionalProperties.Insert("SkipCheckOfAnaliticalParametersChange", True);
							vFolioObj.Write(DocumentWriteMode.Write);
						EndIf;
					Else
						// Open folio
						If vFolioDocs.Count() > 0 Then
							vFolioObj = vFolioRef.GetObject();
							vFolioObj.IsClosed = False;
							vFolioObj.DeletionMark = False;
							vFolioObj.AdditionalProperties.Insert("SkipCheckOfAnaliticalParametersChange", True);
							vFolioObj.Write(DocumentWriteMode.Write);
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	Else
		// Activate all folios of the current document
		vFolios = cmGetInactiveDocumentFolios(Ref);
		If ValueIsFilled(ChargingFolio) And ChargingFolio.IsClosed Then
			If vFolios.Find(ChargingFolio, "Folio") = Undefined Then
				vFoliosRow = vFolios.Add();
				vFoliosRow.Folio = ChargingFolio;
			EndIf;
		EndIf;
		For Each vFoliosRow In vFolios Do
			If ValueIsFilled(vFoliosRow.Folio) Then
				If Not vFoliosRow.Folio.IsMaster Then
					vFolioRef = vFoliosRow.Folio;
					If vFolioRef.IsClosed Then
						vFolioObj = vFolioRef.GetObject();
						vFolioObj.IsClosed = False;
						vFolioObj.DeletionMark = False;
						vFolioObj.AdditionalProperties.Insert("SkipCheckOfAnaliticalParametersChange", True);
						vFolioObj.Write(DocumentWriteMode.Write);
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		// Check should we open guest group folios or not
		If ValueIsFilled(GuestGroup) And GuestGroup.ChargingRules.Count() > 0 Then
			For Each vGGCRRow In GuestGroup.ChargingRules Do
				If ValueIsFilled(vGGCRRow.ChargingFolio) And vGGCRRow.ChargingFolio.IsClosed Then
					vFolioObj = vGGCRRow.ChargingFolio.GetObject();
					vFolioObj.IsClosed = False;
					vFolioObj.DeletionMark = False;
					vFolioObj.AdditionalProperties.Insert("SkipCheckOfAnaliticalParametersChange", True);
					vFolioObj.Write(DocumentWriteMode.Write);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
EndProcedure // SetFolioStatuses

// -----------------------------------------------------------------------------
Procedure MoveClients(pCancel, pPostingMode)
	If ValueIsFilled(Client) Then
		vDoWrite = False;
		vClientObj = Undefined;
		If ValueIsFilled(ResourceReservationStatus) Then
			If ResourceReservationStatus.IsActive Then
				If Client.Parent <> Catalogs.Clients.ReservedGuests And 
				   Client.Parent <> Catalogs.Clients.BlackListPersons And
				   Client.Parent <> Catalogs.Clients.CheckedInGuests Then
					vClientObj = Client.GetObject();
					vClientObj.Parent = Catalogs.Clients.ReservedGuests;
					vDoWrite = True;
				EndIf;
			EndIf;
		EndIf;
		If Not IsBlankString(Phone) And IsBlankString(Client.Phone) Then
			If Not vDoWrite Then
				vClientObj = Client.GetObject();
			EndIf;
			vClientObj.Phone = TrimAll(Phone);
			vDoWrite = True;
		EndIf;
		If Not IsBlankString(Fax) And IsBlankString(Client.Fax) Then
			If Not vDoWrite Then
				vClientObj = Client.GetObject();
			EndIf;
			vClientObj.Fax = TrimAll(Fax);
			vDoWrite = True;
		EndIf;
		If Not IsBlankString(EMail) And IsBlankString(Client.EMail) Then
			If Not vDoWrite Then
				vClientObj = Client.GetObject();
			EndIf;
			vClientObj.EMail = TrimAll(EMail);
			vDoWrite = True;
		EndIf;
		If vDoWrite Then
			vClientObj.Write();
			vClientObj.pmWriteToClientChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		EndIf;
	EndIf;
EndProcedure // MoveClients

// -----------------------------------------------------------------------------
Procedure FillGroupParameters()
	If ValueIsFilled(GuestGroup) Then
		// Customer
		vUpdateCustomer = False;
		vUpdateContract = False;
		If GuestGroup.OneCustomerPerGuestGroup Then
			If GuestGroup.Customer <> Customer Then
				vUpdateCustomer = True;
			EndIf;
			If GuestGroup.Contract <> Contract Then
				vUpdateContract = True;
			EndIf;
		EndIf;
		// Agent
		vUpdateAgent = False;
		If GuestGroup.OneCustomerPerGuestGroup Then
			If GuestGroup.Agent <> Agent Then
				vUpdateAgent = True;
			EndIf;
		EndIf;
		// Client
		vUpdateClient = False;
		If ValueIsFilled(Client) And Not GuestGroup.FixedClient Then
			If Not ValueIsFilled(GuestGroup.Client) Then
				vUpdateClient = True;
			EndIf;
		EndIf;
		// Client document
		vUpdateClientDoc = False;
		If Not ValueIsFilled(GuestGroup.ClientDoc) Or 
		   ValueIsFilled(GuestGroup.ClientDoc) And TypeOf(GuestGroup.ClientDoc) = Type("DocumentRef.ResourceReservation") And 
		   GuestGroup.FixedClient And ValueIsFilled(GuestGroup.Client) And GuestGroup.Client = Client Then
			vUpdateClientDoc = True;
		EndIf;
		// Group status
		vUpdateGroupStatus = False;
		vCurGuestGroupStatus = GuestGroup.Status;
		If Not ValueIsFilled(vCurGuestGroupStatus) Or 
		   ValueIsFilled(vCurGuestGroupStatus) And 
		   (TypeOf(vCurGuestGroupStatus) <> Type("CatalogRef.ReservationStatuses") Or 
		    TypeOf(vCurGuestGroupStatus) = Type("CatalogRef.ReservationStatuses") And Not vCurGuestGroupStatus.DoNotCreateReservationsInBlock) Then
			vGuestGroupStatus = cmGetGuestGroupStatus(GuestGroup);
			If vCurGuestGroupStatus <> vGuestGroupStatus Then
				vUpdateGroupStatus = True;
			EndIf;
		EndIf;
		// Group period and number of guests checked-in
		vUpdatePeriod = False;
		vGroupParams = cmGetGroupPeriodAndGuestsCheckedIn(GuestGroup);
		If vGroupParams.Count() = 0 Then
			If DateTimeFrom < GuestGroup.CheckInDate Or
			   DateTimeTo > GuestGroup.CheckOutDate Or 
			   Not ValueIsFilled(GuestGroup.CheckInDate) Then
				vUpdatePeriod = True;
			EndIf;
		EndIf;
		// Update guest group
		If vUpdateCustomer Or vUpdateContract Or vUpdateAgent Or vUpdateClient Or vUpdateClientDoc Or vUpdateGroupStatus Or vUpdatePeriod Then
			vGroupObj = GuestGroup.GetObject();
			If vUpdateCustomer Then
				vGroupObj.Customer = Customer;
			EndIf;
			If vUpdateContract Then
				vGroupObj.Contract = Contract;
			EndIf;
			If vUpdateAgent Then
				vGroupObj.Agent = Agent;
			EndIf;
			If vUpdateClient Then
				vGroupObj.Client = Client;
				vGroupObj.ClientDoc = Ref;
			ElsIf vUpdateClientDoc Then
				vGroupObj.ClientDoc = Ref;
			EndIf;
			If vUpdatePeriod Then
				If DateTimeFrom < GuestGroup.CheckInDate Or Not ValueIsFilled(GuestGroup.CheckInDate) Then
					vGroupObj.CheckInDate = DateTimeFrom;
				EndIf;
				If DateTimeTo > GuestGroup.CheckOutDate Then
					vGroupObj.CheckOutDate = DateTimeTo;
				EndIf;
				vGroupObj.Duration = cmCalculateDuration(, vGroupObj.CheckInDate, vGroupObj.CheckOutDate);
			EndIf;
			If vUpdateGroupStatus Then
				vGroupObj.Status = vGuestGroupStatus;
			EndIf;
			vGroupObj.Write();
		EndIf;
	EndIf;
EndProcedure // FillGroupParameters

// -----------------------------------------------------------------------------
Procedure FillRChgAttributes(pRChgRec, pPeriod, pUser)
	FillPropertyValues(pRChgRec, ThisObject);
	
	pRChgRec.Period = pPeriod;
	pRChgRec.ResourceReservation = Ref;
	pRChgRec.User = pUser;
	
	// Store tabular parts
	vServicePackages = New ValueStorage(ServicePackages.Unload());
	pRChgRec.ServicePackages = vServicePackages;
	vServices = New ValueStorage(Services.Unload());
	pRChgRec.Services = vServices;
EndProcedure // FillRChgAttributes

#EndRegion
