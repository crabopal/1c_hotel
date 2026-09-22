
#Region EventHandlers

 // -----------------------------------------------------------------------------
Procedure Filling(pBase)
	// Fill attributes with default values
	pmFillAttributesWithDefaultValues();
	// Fill from the base
	If ValueIsFilled(pBase) Then
		If TypeOf(pBase) = Type("DocumentRef.Folio") Then
			pmFillByFolio(pBase);
		ElsIf TypeOf(pBase) = Type("DocumentRef.Reservation") Then 
			pmFillByDocument(pBase);
		ElsIf TypeOf(pBase) = Type("DocumentRef.Accommodation") Then 
			pmFillByDocument(pBase);
		ElsIf TypeOf(pBase) = Type("CatalogRef.GuestGroups") Then
			pmFillByGuestGroup(pBase);
		EndIf;
	EndIf;
EndProcedure // Filling

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pWriteMode, pPostingMode)
	Var vMessage, vAttributeInErr;
	If DataExchange.Load Then
		Return;
	EndIf;
	If pWriteMode = DocumentWriteMode.Posting Then
		pCancel	= pmCheckDocumentAttributes(vMessage, vAttributeInErr);
		If pCancel Then
			WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
			tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
			Raise NStr(vMessage);
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure Posting(pCancel, pPostingMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// Initialize check query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	IssuedHotelProducts.ProductCode AS ProductCode,
	|	IssuedHotelProducts.Recorder AS Recorder
	|FROM
	|	InformationRegister.IssuedHotelProducts AS IssuedHotelProducts
	|WHERE
	|	IssuedHotelProducts.Recorder <> &qRecorder
	|	AND IssuedHotelProducts.Hotel = &qHotel
	|	AND IssuedHotelProducts.ProductCode = &qProductCode
	|	AND IssuedHotelProducts.Active";
	vQry.SetParameter("qRecorder", Ref);
	vQry.SetParameter("qHotel", Hotel);
	
	// Do for each hotel products row
	For Each vHPRow In HotelProducts Do
		If ValueIsFilled(vHPRow.HotelProduct) Then
			// Write to the hotel products log
			vHPLRec = RegisterRecords.HotelProductLog.AddExpense();
			vHPLRec.Period = Date;
			vHPLRec.Hotel = Hotel;
			vHPLRec.FolioCurrency = vHPRow.HotelProduct.Currency;
			If Not ValueIsFilled(vHPLRec.FolioCurrency) Then
				vHPLRec.FolioCurrency = Currency;
			EndIf;
			vHPLRec.HotelProduct = vHPRow.HotelProduct;
			vHPLRec.Sum = vHPRow.Sum;
		Else
			// Write to the issued hotel products
			vCurProductCode = TrimAll(vHPRow.ProductStartCode);
			For i = 1 To vHPRow.Quantity Do
				// Check if this hotel product is already registered by another document
				vQry.SetParameter("qProductCode", vCurProductCode);
				vHPs = vQry.Execute().Select();
				While vHPs.Next() Do
					vMessage = NStr("en='Product with code " + vCurProductCode + " is already issued by document " + String(vHPs.Recorder) + "!'; 
					                |de='Product with code " + vCurProductCode + " is already issued by document " + String(vHPs.Recorder) + "!';
					                |ru='Путевка с кодом " + vCurProductCode + " уже отгружен документом " + String(vHPs.Recorder) + "!'");
					WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, vMessage);
					tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
					pCancel = True;
					Return;
				EndDo;
				
				// Add movement
				vHPRec = RegisterRecords.IssuedHotelProducts.Add();
				vHPRec.Period = Date;
				
				vHPRec.ProductCode = vCurProductCode;
				
				FillPropertyValues(vHPRec, ThisObject);
				FillPropertyValues(vHPRec, vHPRow);
				
				vCurProductCode = cmAddToNumberWithPrefix(vCurProductCode, 2);
			EndDo;
		EndIf;
	EndDo;
	
	// Write movements
	RegisterRecords.IssuedHotelProducts.Write();
	RegisterRecords.HotelProductLog.Write();
EndProcedure // Posting

// -----------------------------------------------------------------------------
Procedure OnSetNewNumber(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(SessionParameters.CurrentHotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(SessionParameters.CurrentHotel);
	EndIf;
	If vPrefix <> "" Then
		pPrefix = vPrefix;
	EndIf;
EndProcedure // OnSetNewNumber

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel) 
	If DataExchange.Load Then
		Return;
	EndIf;  
EndProcedure // OnWrite

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
Function pmCheckDocumentAttributes(pMessage, pAttributeInErr) Export
	vHasErrors = False;
	pMessage = "";
	pAttributeInErr = "";
	vMsgTextRu = "";
	vMsgTextEn = "";
	vMsgTextDe = "";
	If AdditionalProperties.Property("InfoBaseUpdateMode") And AdditionalProperties.InfoBaseUpdateMode Then
		Return vHasErrors;
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
	If Not ValueIsFilled(Currency) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Валюта> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Currency> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Currency> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Currency", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(VATRate) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Ставка НДС %> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<VAT Rate %> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<VAT Rate %> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "VATRate", pAttributeInErr);
	EndIf;
	If vHasErrors Then
		pMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // CheckDocumentAttributes

// -----------------------------------------------------------------------------
Procedure pmFillAuthorAndDate() Export
	Date = CurrentSessionDate();
	Author = SessionParameters.CurrentUser;
EndProcedure // pmFillAuthorAndDate

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill author and document date
	pmFillAuthorAndDate();
	// Fill from session parameters
	If Not ValueIsFilled(ExchangeRateDate) Then
		ExchangeRateDate = Date;
	EndIf;
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(Currency) Then
		If ValueIsFilled(Hotel) Then
			Currency = Hotel.FolioCurrency;
			CurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, Currency, ExchangeRateDate);
		EndIf;
	EndIf;
	If Not ValueIsFilled(Company) Then
		If ValueIsFilled(Hotel) Then
			Company = Hotel.Company
		EndIf;
	EndIf;
	If Not ValueIsFilled(VATRate) Then
		If ValueIsFilled(Company) Then
			VATRate = Company.VATRate;
		EndIf;
	EndIf;
	If Not ValueIsFilled(VoucherShipmentType) Then
		VoucherShipmentType = Enums.VoucherShipmentTypes.RegistrationOfVouchersIssuedInTheHotel;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Procedure pmFillByFolio(pFolio) Export
	If Not ValueIsFilled(pFolio) Then
		Return;
	EndIf;
	
	If ValueIsFilled(pFolio.Hotel) Then
		If Hotel <> pFolio.Hotel Then
			Hotel = pFolio.Hotel;
			SetNewNumber(Catalogs.Hotels.pmGetPrefix(Hotel));
		EndIf;
	EndIf;
	
	// Fill customer, contract and guest group
	Customer = pFolio.Customer;
	Contract = pFolio.Contract;
	
	// Fill currency
	Currency = pFolio.FolioCurrency;
	CurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, Currency, ExchangeRateDate);
	
	// Fill company
	If ValueIsFilled(pFolio.Company) Then
		Company = pFolio.Company;
	Else
		If ValueIsFilled(Hotel) Then
			If ValueIsFilled(Hotel.Company) Then
				Company = Hotel.Company;
			EndIf;
		EndIf;
	EndIf;
	
	// Fill VAT rate
	If ValueIsFilled(Company) Then
		If ValueIsFilled(Company.VATRate) Then
			VATRate = Company.VATRate;
		EndIf;
	EndIf;
	If ValueIsFilled(pFolio.PaymentSection) Then
		If ValueIsFilled(pFolio.PaymentSection.VATRate) Then
			VATRate = pFolio.PaymentSection.VATRate;
		EndIf;
	EndIf;
	
	// Clear tabular part with hotel products
	HotelProducts.Clear();
	
	// Get products list from folio charges
	vFolioProducts = pFolio.GetObject().pmGetHotelProducts();
	
	// Fill hotel products tabular part
	FillHotelProducts(vFolioProducts);
	For Each vHPRow In HotelProducts Do
		vHPRow.GuestGroup = pFolio.GuestGroup;
	EndDo;
EndProcedure // pmFillByFolio

// -----------------------------------------------------------------------------
Procedure pmFillByDocument(pDoc) Export
	If Not ValueIsFilled(pDoc) Then
		Return;
	EndIf;
	
	If ValueIsFilled(pDoc.Hotel) Then
		If Hotel <> pDoc.Hotel Then
			Hotel = pDoc.Hotel;
			SetNewNumber(Catalogs.Hotels.pmGetPrefix(Hotel));
		EndIf;
	EndIf;
	
	// Fill customer, contract, guest group and room quota
	Customer = pDoc.Customer;
	Contract = pDoc.Contract;
	RoomQuota = pDoc.RoomQuota;
	
	// Fill currency
	If ValueIsFilled(Contract) Then
		Currency = Contract.AccountingCurrency;
		CurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, Currency, ExchangeRateDate);
	Else
		If ValueIsFilled(Customer) Then
			Currency = Customer.AccountingCurrency;
			CurrencyExchangeRate = cmGetCurrencyExchangeRate(Hotel, Currency, ExchangeRateDate);
		EndIf;
	EndIf;
	
	// Fill company
	If ValueIsFilled(pDoc.Company) Then
		Company = pDoc.Company;
	Else
		If ValueIsFilled(Hotel) Then
			If ValueIsFilled(Hotel.Company) Then
				Company = Hotel.Company;
			EndIf;
		EndIf;
	EndIf;
	
	// Fill VAT rate
	If ValueIsFilled(Company) Then
		If ValueIsFilled(Company.VATRate) Then
			VATRate = Company.VATRate;
		EndIf;
	EndIf;
	
	// Clear hotel products
	HotelProducts.Clear();
	
	// Add hotel product from the document
	vSkipFillingProductPrice = False;
	If ValueIsFilled(Hotel) Then
		vSkipFillingProductPrice = Hotel.DoNotFillProductCostFillingIssueHotelProducts;
	EndIf;
	If ValueIsFilled(pDoc.HotelProduct) Then
		vHPRow = HotelProducts.Add();
		FillHotelProductsRow(vHPRow, pDoc.HotelProduct, vSkipFillingProductPrice);
		vHPRow.GuestGroup = pDoc.GuestGroup;
		If TypeOf(pDoc) = Type("DocumentRef.Reservation") Then
			vHPRow.ParentDoc = pDoc;
			vHPRow.RoomType = pDoc.RoomType;
		ElsIf TypeOf(pDoc) = Type("DocumentRef.Accommodation") Then
			vHPRow.RoomType = pDoc.RoomType;
		EndIf;
	EndIf;
EndProcedure // pmFillByDocument

// -----------------------------------------------------------------------------
Procedure pmFillByGuestGroup(pGuestGroup) Export
	If Not ValueIsFilled(pGuestGroup) Then
		Return;
	EndIf;
	
	// Clear hotel products
	HotelProducts.Clear();
	
	// Get list of reservations in the group
	vGuestGroupProducts = pGuestGroup.GetObject().pmGetHotelProducts();
	
	// Fill hotel products tabular part
	FillHotelProducts(vGuestGroupProducts);
	For Each vHPRow In HotelProducts Do
		vHPRow.GuestGroup = pGuestGroup;
	EndDo;
EndProcedure // pmFillByGuestGroup

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure FillHotelProductsRow(pHPRow, pHotelProduct, pSkipFillingProductPrice = False)
	pHPRow.HotelProductParent = pHotelProduct.Parent;
	If ValueIsFilled(pHPRow.HotelProductParent) Then
		pHPRow.Service = pHPRow.HotelProductParent.Service;
	EndIf;
	pHPRow.CheckInDate = pHotelProduct.CheckInDate;
	pHPRow.Duration = pHotelProduct.Duration;
	pHPRow.CheckOutDate = pHotelProduct.CheckOutDate;
	If Not pSkipFillingProductPrice Then
		pHPRow.Price = pHotelProduct.Sum;
	Else
		pHPRow.Price = 0;
	EndIf;
	pHPRow.Quantity = 1;
	pHPRow.ProductStartCode = TrimR(pHotelProduct.Code);
	pHPRow.ProductEndCode = cmAddToNumberWithPrefix(pHPRow.ProductStartCode, pHPRow.Quantity);
	pHPRow.Sum = Round(pHPRow.Price*pHPRow.Quantity, 2);
	pHPRow.VATSum = cmCalculateVATSum(VATRate, pHPRow.Sum, Date);
	pHPRow.RoomType = pHotelProduct.RoomType;
EndProcedure // FillHotelProductsRow

// -----------------------------------------------------------------------------
Procedure UpdateHotelProductsRow(pHPRow, pHotelProduct)
	pHPRow.Quantity = pHPRow.Quantity + 1;
	pHPRow.ProductEndCode = TrimR(pHotelProduct.Code);
	pHPRow.Sum = Round(pHPRow.Price*pHPRow.Quantity, 2);
	pHPRow.VATSum = cmCalculateVATSum(VATRate, pHPRow.Sum, Date);
EndProcedure // UpdateHotelProductsRow

// -----------------------------------------------------------------------------
Procedure FillHotelProducts(pProducts)
	vSkipCheckingProductPrice = False;
	If ValueIsFilled(Hotel) Then
		vSkipCheckingProductPrice = Hotel.DoNotFillProductCostFillingIssueHotelProducts;
	EndIf;
	vMaxi = pProducts.Count() - 1;
	i = 0;
	While i <= vMaxi Do
		vProductsRow = pProducts.Get(i);
		If i = vMaxi Then
			vHPRow = HotelProducts.Add();
			FillHotelProductsRow(vHPRow, vProductsRow.HotelProduct, vSkipCheckingProductPrice);
		Else
			vHPRow = HotelProducts.Add();
			FillHotelProductsRow(vHPRow, vProductsRow.HotelProduct, vSkipCheckingProductPrice);
			// Check next row
			vPrevProductCode = TrimR(vProductsRow.HotelProduct.Code);
			While i < vMaxi Do
				vNextProductsRow = pProducts.Get(i + 1);
				If vProductsRow.HotelProduct.Parent = vNextProductsRow.HotelProduct.Parent And 
				   vProductsRow.HotelProduct.Duration = vNextProductsRow.HotelProduct.Duration And 
				   vProductsRow.HotelProduct.CheckOutDate = vNextProductsRow.HotelProduct.CheckOutDate And 
				   (Not vSkipCheckingProductPrice And vProductsRow.HotelProduct.Sum = vNextProductsRow.HotelProduct.Sum Or vSkipCheckingProductPrice) And 
				   vProductsRow.HotelProduct.RoomType = vNextProductsRow.HotelProduct.RoomType Then
					If cmSubtractNumbersWithPrefix(TrimR(vNextProductsRow.HotelProduct.Code), vPrevProductCode) = 2 Then
						UpdateHotelProductsRow(vHPRow, vNextProductsRow.HotelProduct);
						vPrevProductCode = TrimR(vNextProductsRow.HotelProduct.Code);
						i = i + 1;
						Continue;
					EndIf;
				EndIf;
				Break;
			EndDo;
		EndIf;
		i = i + 1;
	EndDo;
EndProcedure // FillHotelProducts

#EndRegion
