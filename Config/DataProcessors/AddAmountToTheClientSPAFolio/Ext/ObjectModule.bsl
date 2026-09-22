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
Function pmWriteAmount() Export
	Try
		BeginTransaction();
		If Hotel.ExportGiftCertificatesToSPA Then
			vErrorText = pmSynchroniseWithSPA();
			If ValueIsFilled(vErrorText) Then
				Raise vErrorText;
			EndIf;
		EndIf;
		If Not pmDoCertificatePayment() Then
			Raise NStr("en='Payment post error';ru='Ошибка проводки платежа';de='Fehler bei der Zahlungsdurchführung'");
		EndIf;
		CommitTransaction();
	Except
		vErrorDescription = ErrorDescription();
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		Return vErrorDescription;
	EndTry;
EndFunction // pmWriteAmount

// -----------------------------------------------------------------------------
Function pmDoCertificatePayment()
	// Create payment for the folio being found
	vPaymentObj = Documents.Payment.CreateDocument();
	vPaymentObj.Fill(Folio);
	vPaymentObj.GiftCertificate = "" + ?(ValueIsFilled(Folio.GuestGroup), Format(Folio.GuestGroup.Code, "ND=12; NFD=; NZ=; NG="), "0") + "/" + ?(ValueIsFilled(Folio.Client), TrimAll(Folio.Client.Code), "0");
	vVATRate = Catalogs.VATRates.EmptyRef();
	If ValueIsFilled(Folio.Hotel.Company) Then
		vVATRate = Folio.Hotel.Company.VATRate;
	EndIf;
	vSum = Amount;
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
		vResult = vProxy.WriteFolioAmount(Amount, vGuestLastName, vGuestFirstName, vGuestSecondName, vGuestDateOfBirth, vGuestCode);
		If ValueIsFilled(vResult) Then
			Raise vResult;
		EndIf;
	Except
		vErrorDescription = ErrorDescription();
		Return vErrorDescription;
	EndTry;
EndFunction // pmSynchroniseWithSPA