// -----------------------------------------------------------------------------
Procedure pmLoadDataProcessorAttributes(pParameter) Export
	If ValueIsFilled(pParameter) And TypeOf(pParameter) = Type("DocumentRef.Folio") Then
		Folio = pParameter;
	EndIf;
	Hotel = Folio.Hotel;
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	SPAWSDLHostAddress = Hotel.SPAConnectionString;
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
Procedure pmRun(pParameter, pIsInteractive) Export
	#IF CLIENT THEN
		vForm = DataProcessor.GetForm();
		vForm.Open();
	#ENDIF
EndProcedure // pmRun

// -----------------------------------------------------------------------------
Function pmWriteCertificate() Export
	Try
		BeginTransaction();
		If Hotel.ExportGiftCertificatesToSPA Then
			vErrorText = pmSynchroniseWithSPA();
			If ValueIsFilled(vErrorText) Then
				Raise vErrorText;
			EndIf;
		EndIf;
		vErrorText = pmDoCertificateCharge();
		If ValueIsFilled(vErrorText) Then
			Raise vErrorText;
		EndIf;
		If Not OnlyCharge Then 
			If Not pmDoCertificatePayment() Then
				Raise NStr("en='Payment post error';ru='Ошибка проводки платежа';de='Fehler bei der Zahlungsdurchführung'");
			EndIf;
		EndIf;
		CommitTransaction();
	Except
		vErrorDescription = ErrorDescription();
		vResult = pmDeleteSPACertificate();
		If ValueIsFilled(vResult) Then
			tcCommonFunctionOnClientServer.TextMessage(vResult);
		EndIf;
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		Return vErrorDescription;
	EndTry;
EndFunction // pmWriteCertificate

// -----------------------------------------------------------------------------
Function pmDoCertificateCharge()
	vError = "";
	vQuantity = 1;
	// Get hotel
	vHotel = Undefined;
	vSum = 0;
	If ValueIsFilled(Folio.Hotel) Then
		vHotel = Folio.Hotel;
	ElsIf ValueIsFilled(Folio.ParentDoc) Then
		vHotel = Folio.ParentDoc.Hotel;
	Else
		vHotel = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(vHotel) Then
		vError = NStr("en='Hotel is not set!';ru='Не удалось определить гостиницу!';de='Das Hotel konnte nicht bestimmt werden!'");
		Return vError;
	EndIf;
	// Get service to be charged by service code or hotel
	vService = Certificate;
	
	vServicePrices = vService.GetObject().pmGetServicePrices(Folio.Hotel, CurrentSessionDate());
	vVATRate = Catalogs.VATRates.EmptyRef();
	If ValueIsFilled(Folio.Hotel.Company) Then
		vVATRate = Folio.Hotel.Company.VATRate;
	EndIf;
	If vServicePrices.Count() > 0 Then
		vVATRate = vServicePrices.Get(0).VATRate;
		vSum = vServicePrices.Get(0).Price;
	EndIf;
	
	// Create charge document
	vChargeObj = Documents.Charge.CreateDocument();
	vChargeObj.pmFillAttributesWithDefaultValues();
	If ValueIsFilled(Folio.Hotel) Then
		If vChargeObj.Hotel <> Folio.Hotel Then
			vChargeObj.Hotel = Folio.Hotel;
			vChargeObj.SetNewNumber(Catalogs.Hotels.pmGetPrefix(vChargeObj.Hotel));
		EndIf;
	EndIf;
	If Not ValueIsFilled(vChargeObj.Hotel) Then
		vError = NStr("en='Hotel is not set!';ru='Не удалось установить гостиницу!';de='Das Hotel konnte nicht festgelegt werden!'");
		Return vError;
	EndIf;
	
	// Get currency by code
	vCurrency = Folio.FolioCurrency;
	If Not ValueIsFilled(vCurrency) Then
		vCurrency = vHotel.FolioCurrency;
	EndIf;
	
	// Post this document
	vChargeObj.ParentDoc = Folio.ParentDoc;
	vChargeObj.IsFixedCharge = False;
	vChargeObj.Hotel = Folio.Hotel;
	If ValueIsFilled(Folio.ParentDoc) And TypeOf(Folio.ParentDoc) = Type("DocumentRef.ResourceReservation") And
		ValueIsFilled(Folio.ParentDoc.ExchangeRateDate) And 
		ValueIsFilled(vChargeObj.Service) And ValueIsFilled(vChargeObj.Service.ServiceType) And 
		vChargeObj.Service.ServiceType.ActualAmountIsChargedExternally Then
		vChargeObj.ExchangeRateDate = Folio.ParentDoc.ExchangeRateDate;
	EndIf;
	vChargeObj.FolioCurrency = Folio.FolioCurrency;
	vChargeObj.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(vChargeObj.Hotel, vChargeObj.FolioCurrency, vChargeObj.ExchangeRateDate);
	vChargeObj.ReportingCurrency = Folio.Hotel.ReportingCurrency;
	vChargeObj.ReportingCurrencyExchangeRate = cmGetCurrencyExchangeRate(vChargeObj.Hotel, vChargeObj.ReportingCurrency, vChargeObj.ExchangeRateDate);
	vChargeObj.Folio = Folio;
	vChargeObj.Service = vService;
	vChargeObj.PaymentSection = vChargeObj.Service.PaymentSection;
	If vSum < 0 And vQuantity > 0 Then
		vQuantity = -vQuantity;
	EndIf;
	If Not ValueIsFilled(vCurrency) Or vCurrency = vChargeObj.FolioCurrency Then
		vChargeObj.Price = cmRecalculatePrice(vSum, vQuantity);
	Else
		vSum = cmExtConvertCurrencies(vSum, vCurrency, , vChargeObj.FolioCurrency, vChargeObj.FolioCurrencyExchangeRate, vChargeObj.ExchangeRateDate, vChargeObj.Hotel, "");
		vChargeObj.Price = cmRecalculatePrice(vSum, vQuantity);
	EndIf;
	vChargeObj.Unit = vService.Unit;
	vChargeObj.Quantity = vQuantity;
	vChargeObj.Sum = vSum;
	vChargeObj.VATRate = vVATRate;
	vChargeObj.VATSum = cmCalculateVATSum(vChargeObj.VATRate, vChargeObj.Sum, vChargeObj.Date);
	vChargeObj.IsRoomRevenue = vService.IsRoomRevenue;
	//vChargeObj.IsInPrice = vService.IsInPrice;
	vChargeObj.Company = Folio.Company;
	vChargeObj.IsAdditional = True;
	vChargeObj.GiftCertificate = TrimAll(CertificateNumber);
	vChargeObj.Write(DocumentWriteMode.Posting);
	Return vError;
EndFunction // pmDoCertificateCharge

// -----------------------------------------------------------------------------
Function pmDoCertificatePayment()
	// Create payment for the folio being found
	vPaymentObj = Documents.Payment.CreateDocument();
	vPaymentObj.Fill(Folio);
	vPaymentObj.GiftCertificate = TrimAll(CertificateNumber);
	// Get service to be charged by service code or hotel
	vSum = 0;
	vService = Certificate;
	vServicePrices = vService.GetObject().pmGetServicePrices(Folio.Hotel, CurrentSessionDate());
	vVATRate = Catalogs.VATRates.EmptyRef();
	If ValueIsFilled(Folio.Hotel.Company) Then
		vVATRate = Folio.Hotel.Company.VATRate;
	EndIf;
	If vServicePrices.Count() > 0 Then
		vVATRate = vServicePrices.Get(0).VATRate;
		vSum = vServicePrices.Get(0).Price;
	EndIf;
    // Get currency by code
	vCurrency = Folio.FolioCurrency;
	If Not ValueIsFilled(vCurrency) Then
		vCurrency = Folio.Hotel.FolioCurrency;
	EndIf;
	If ValueIsFilled(vCurrency) Then
		If ValueIsFilled(Folio.ParentDoc) Then
			vExchangeRateDate = Folio.ParentDoc.ExchangeRateDate;
		Else
			vExchangeRateDate = CurrentSessionDate();
		EndIf;
		vSum = cmExtConvertCurrencies(vSum, vCurrency, , Folio.FolioCurrency, cmGetCurrencyExchangeRate(Folio.Hotel, Folio.FolioCurrency, vExchangeRateDate), vExchangeRateDate, Folio.Hotel, "");
	EndIf;
    vPaymentObj.Sum = vSum;
	vPaymentObj.SumInFolioCurrency = vSum;                                  
	vFrm = vPaymentObj.GetForm(,, Folio);
	vFrm.DoModal();
	If Not ValueIsFilled(vPaymentObj.Ref) Or Not vPaymentObj.Posted Then
		Return False;
	EndIf;
	Return True;
EndFunction // pmDoCertificatePayment

// -----------------------------------------------------------------------------
Function pmDeleteSPACertificate()
	Try	
		vDefinition = New WSDefinitions(SPAWSDLHostAddress + "/1CHotelInterfaces.1cws?WSDL");
		For Each vService In vDefinition.Services Do
			If vService.Name = "HotelInterfaces" Then
				vNamespaceURI = vService.NamespaceURI;
				break;
			EndIf;
		EndDo;
		If Not ValueIsFilled(vNamespaceURI) Then
			vNamespaceURI = "http://www.salon1c.ru/ws/Interfaces/Hotel";
		EndIf;
		vProxy = New WSProxy(vDefinition,vNamespaceURI,"HotelInterfaces","HotelInterfacesSoap");
		vResult = vProxy.DeleteCertificate(TrimAll(Certificate.Code), CertificateNumber, ?(ValueIsFilled(Folio.Client), TrimAll(Folio.Client.Code), ""));
		If ValueIsFilled(vResult) Then
			Raise vResult;
		EndIf;
	Except
		vErrorDescription = ErrorDescription();
		Return vErrorDescription;
	EndTry;
EndFunction // pmDeleteSPACertificate

// -----------------------------------------------------------------------------
Function pmSynchroniseWithSPA()
	Try	
		vDefinition = New WSDefinitions(SPAWSDLHostAddress);
		For Each vService In vDefinition.Services Do
			If vService.Name = "HotelInterfaces" Then
				vNamespaceURI = vService.NamespaceURI;
				break;
			EndIf;
		EndDo;
		If Not ValueIsFilled(vNamespaceURI) Then
			vNamespaceURI = "http://www.salon1c.ru/ws/Interfaces/Hotel";
		EndIf;
		vGuestCode = TrimAll(Folio.Client.Code);
		vGuestLastName = TrimAll(Folio.Client.LastName);
		vGuestFirstName = TrimAll(Folio.Client.FirstName);
		vGuestSecondName = TrimAll(Folio.Client.SecondName);
		If ValueIsFilled(Folio.Client.DateOfBirth) Then
			vGuestDateOfBirth = Format(Folio.Client.DateOfBirth, "DF=yyyyMMdd");
		Else
			vGuestDateOfBirth = "";
		EndIf;
		vProxy = New WSProxy(vDefinition,vNamespaceURI,"HotelInterfaces","HotelInterfacesSoap");
		vResult = vProxy.WriteExternalCertificate(TrimAll(Certificate.Code), CertificateNumber, vGuestLastName, vGuestFirstName, vGuestSecondName, vGuestDateOfBirth, vGuestCode);
		If ValueIsFilled(vResult) Then
			Raise vResult;
		EndIf;
	Except
		vErrorDescription = ErrorDescription();
		Return vErrorDescription;
	EndTry;
EndFunction // pmSynchroniseWithSPA