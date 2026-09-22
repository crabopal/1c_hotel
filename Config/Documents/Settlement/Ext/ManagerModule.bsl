
#Region Public

// --------------------------------------------------------------------------------
Function MergeCorrections(pServices) Export
	vServices = pServices.Unload();
	vID = 0;
	While vID < vServices.Count() Do
		vServicesRow = vServices.Get(vID);
		vCharge = vServicesRow.Charge;
		If vServicesRow.Folio <> vCharge.Folio Then
			vServicesRow.Folio = vCharge.Folio;
		EndIf;
		If vServicesRow.ParentDoc <> vCharge.ParentDoc Then
			vServicesRow.ParentDoc = vCharge.ParentDoc;
		EndIf;
		If vCharge.IsCorrection Then
			vRows = vServices.FindRows(New Structure("Charge", vCharge.CorrectedCharge));
			If vRows.Count() = 1 Then
				vRow = vRows.Get(0);
				vRow.Sum = vRow.Sum + vServicesRow.Sum;
				vRow.VATSum = vRow.VATSum + vServicesRow.VATSum;
				vRow.CommissionSum = vRow.CommissionSum + vServicesRow.CommissionSum;
				vRow.VATCommissionSum = vRow.VATCommissionSum + vServicesRow.VATCommissionSum;
				vRow.Price = ?(vRow.Quantity = 0, vRow.Sum, Round(vRow.Sum/vRow.Quantity, 2));
				
				vServices.Delete(vID);
				Continue;
			EndIf;
		EndIf;
		vID = vID + 1;
	EndDo;
	Return vServices;
EndFunction // MergeCorrections

// --------------------------------------------------------------------------------
Function PrintInvoice(vSpreadsheet, pInvoice, pLanguage, pPrintForm, pClear = True) Export 
	If Not ValueIsFilled(pInvoice) Then 
		Return Undefined; 
	EndIF;
	// Basic checks
	vHotel = pInvoice.Hotel;
	If Not ValueIsFilled(pInvoice.Hotel) Then
		vHotel = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(vHotel) Then
		Return Undefined;
	EndIf;
	vCompany = pInvoice.Company;
	If Not ValueIsFilled(pInvoice.Company) Then
		vCompany = vHotel.Company;
	EndIf;
	If Not ValueIsFilled(vCompany) Then
		Return Undefined;
	EndIf;
	If Not ValueIsFilled(pLanguage) Then
		pLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	vAccount = pInvoice.BankAccount;
	If Not ValueIsFilled(vAccount) Then
		vAccount = vCompany.BankAccount;
	EndIf;
	If Not ValueIsFilled(vAccount) Then
		Raise NStr("ru='Не задан расчетный счет фирмы!';de='Das Verrechnungskonto der Firma ist nicht angegeben!';en='Company account should be filled!'");
	EndIf;
	
	// Fill and check grouping parameter
	vParameter = Upper(TrimAll(pPrintForm.Parameter));
	vDoNotShowPayDueDate = (Find(vParameter, "DO_NOT_SHOW_PAY_DUE_DATE") > 0);
	vShowContract = (Find(vParameter, "SHOW_CONTRACT") > 0);
	vDoNotShowClientCitizenship = (Find(vParameter, "DO_NOT_SHOW_CLIENT_CITIZENSHIP") > 0);
	vShowPricesRoomType = (Find(vParameter, "SHOW_PRICES_ROOM_TYPE") > 0);
	
	If pClear Then
		vSpreadsheet.Clear();
	EndIf;
	
	// Choose template
	vTemplate = Undefined;
	vIsByDays = True;
	vInvoiceObject = pInvoice.GetObject();
	If ValueIsFilled(pLanguage) Then
		If pLanguage = Catalogs.Languages.EN Then
			vTemplate = vInvoiceObject.GetTemplate("InvoiceEn");
		ElsIf pLanguage = Catalogs.Languages.RU Then
			vTemplate = vInvoiceObject.GetTemplate("InvoiceRu");
		ElsIf pLanguage = Catalogs.Languages.DE Then
			vTemplate = vInvoiceObject.GetTemplate("InvoiceDe");
		Else
			vTemplate = vInvoiceObject.GetTemplate("InvoiceEn");
		EndIf;
	Else
		vTemplate = vInvoiceObject.GetTemplate("InvoiceEn");
	EndIf;
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(pPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;
	
	// Load pictures
	vLogoIsSet = False;
	vLogo = New Picture;
	If ValueIsFilled(pInvoice.Hotel) Then
		If pInvoice.Hotel.Logo <> Undefined Then
			vLogo = pInvoice.Hotel.Logo.Get();
			If vLogo = Undefined Then
				vLogo = New Picture;
			Else
				vLogoIsSet = True;
			EndIf;
		EndIf;
	EndIf;
	
	// Header
	vHeader = vTemplate.GetArea("Header");
	
	// Hotel
	vHotelObj = vHotel.GetObject();
	mHotelPrintName = vHotelObj.pmGetHotelPrintName(pLanguage);
	mHotelPostAddressPresentation = vHotelObj.pmGetHotelPostAddressPresentation(pLanguage);
	vHotelPhones = TrimAll(vHotel.Phones);
	vHotelFax = TrimAll(vHotel.Fax);
	vHotelEMail = TrimAll(vHotel.EMail);
	mHotelPhones = vHotelPhones + 
	               ?(IsBlankString(vHotelFax), "", cmNStr("en = ', fax '; de = ', fax '; ru = ', факс '", pLanguage) + vHotelFax) + 
				   ?(IsBlankString(vHotelEMail), "", cmNStr("en = ', e-mail '; de = ', e-mail '; ru = ', e-mail '", pLanguage) + vHotelEMail);
	
	// Company
	vCompanyObj = vCompany.GetObject();
	vCompanyLegacyName = vCompanyObj.pmGetCompanyPrintName(pLanguage);
	vCompanyLegacyAddress = vCompanyObj.pmGetCompanyLegacyAddressPresentation(pLanguage);
	vCompanyPostAddress = vCompanyObj.pmGetCompanyPostAddressPresentation(pLanguage);
	If lower(vCompanyPostAddress) = lower(vCompanyLegacyAddress) Then
		vCompanyPostAddress = "";
	EndIf;
	vCompanyCodes = "";
	vCompanyTIN = TrimAll(vCompany.TIN);
	vCompanyKPP = TrimAll(vCompany.KPP);
	vCompanyVATC = TrimAll(vCompany.VATC);
	If Not IsBlankString(vCompanyTIN) Then
		vCompanyCodes = cmNStr("en='Reg. N';de='Reg. N';ru='ИНН'", pLanguage) + ?(IsBlankString(vCompanyKPP), " ", "/" + cmNStr("en='KPP ';de='KPP ';ru='КПП '", pLanguage)) + vCompanyTIN + ?(IsBlankString(vCompanyKPP), "", "/" + vCompanyKPP);
	EndIf;
	If Not IsBlankString(vCompanyVATC) Then
		vCompanyCodes = vCompanyCodes + ?(IsBlankString(vCompanyCodes), "", ", ") + cmNStr("en='VAT Code ';ru='код НДС ';de='Mw.St. Code ';lv='PVN '", pLanguage) + vCompanyVATC;
	EndIf;
	vCompanyPhones = TrimAll(vCompany.Phones) + ?(IsBlankString(vCompany.Fax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", pLanguage) + TrimAll(vCompany.Fax));
	mCompanyLegacyName = TrimAll(vCompanyLegacyName + ?(IsBlankString(vCompanyCodes), "", ", " + vCompanyCodes) + Chars.LF + vCompanyLegacyAddress + Chars.LF + ?(IsBlankString(vCompanyPostAddress), "", vCompanyPostAddress + Chars.LF) + vCompanyPhones);
	
	mCompanyBank = TrimAll(TrimAll(vAccount.BankName) + " " + TrimAll(vAccount.BankCity));
	mCompanyBankAccount = TrimAll(vAccount.AccountNumber);
	If Not IsBlankString(vAccount.BankBIC) Then
		mCompanyBank = mCompanyBank + Chars.LF + cmNStr("en='BIC ';ru='БИК ';de='BIC '", pLanguage) + TrimAll(vAccount.BankBIC);
	EndIf;
	If Not IsBlankString(vAccount.BankCorrAccountNumber) Then
		mCompanyBank = mCompanyBank + Chars.LF + cmNStr("en='Corr. acc. № ';ru='Корр. сч. № ';de='Korrespondenzkonto Nr.'", pLanguage) + TrimAll(vAccount.BankCorrAccountNumber);
	EndIf;
	If Not IsBlankString(vAccount.BankTINCode) Then
		mCompanyBank = mCompanyBank + Chars.LF + TrimAll(vAccount.BankTINCode);
	EndIf;
	If Not IsBlankString(vAccount.BankIBAN) Then
		mCompanyBank = mCompanyBank + Chars.LF + cmNStr("en = 'IBAN CODE '; de = 'IBAN CODE '; ru = 'IBAN CODE '", pLanguage) + TrimAll(vAccount.BankIBAN);
	EndIf;
	If Not IsBlankString(vAccount.BankSWIFTCode) Then
		mCompanyBank = mCompanyBank + Chars.LF + cmNStr("en = 'SWIFT CODE '; de = 'SWIFT CODE '; ru = 'SWIFT CODE '", pLanguage) + TrimAll(vAccount.BankSWIFTCode);
	EndIf;
	
	vHeaderStruct = New Structure;
	
	// Invoice date and number
	mInvoiceNumber = cmGetDocumentNumberPresentation(pInvoice.Number);
	mInvoiceDate = Format(pInvoice.Date, "DF=dd.MM.yyyy");
	
	// Client
	vClient = Undefined;
	mClient = "";
	mCitizenship = Undefined;
	mPricesRoomType = Undefined;
	If ValueIsFilled(pInvoice.ParentDoc) And TypeOf(pInvoice.ParentDoc) = Type("DocumentRef.Folio") Then
		If ValueIsFilled(pInvoice.ParentDoc.Client) Then
			vClient = pInvoice.ParentDoc.Client;
			mClient = TrimAll(vClient.FullName);
			mCitizenship = vClient.Citizenship;
		EndIf;
		mCheckInDate  = pInvoice.ParentDoc.DateTimeFrom;
		mCheckOutDate = pInvoice.ParentDoc.DateTimeTo;
		mRoom         = pInvoice.ParentDoc.Room;
		mRoomType     = pInvoice.ParentDoc.Room.RoomType;
		If ValueIsFilled(pInvoice.ParentDoc.ParentDoc) And 
		  (TypeOf(pInvoice.ParentDoc.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(pInvoice.ParentDoc.ParentDoc) = Type("DocumentRef.Reservation")) Then
			mPricesRoomType = pInvoice.ParentDoc.ParentDoc.RoomTypeUpgrade;
		EndIf;
	ElsIf ValueIsFilled(pInvoice.ParentDoc) And (TypeOf(pInvoice.ParentDoc) = Type("DocumentRef.Accommodation") or TypeOf(pInvoice.ParentDoc) = Type("DocumentRef.Reservation"))  Then
		If ValueIsFilled(pInvoice.ParentDoc.Guest) Then
			vClient = pInvoice.ParentDoc.Guest;
			mClient = TrimAll(vClient.FullName);
			mCitizenship = vClient.Citizenship;
		EndIf;
		mCheckInDate  = pInvoice.ParentDoc.CheckInDate;
		mCheckOutDate = pInvoice.ParentDoc.CheckOutDate;
		mRoom         = pInvoice.ParentDoc.Room;
		mRoomType     = pInvoice.ParentDoc.Room.RoomType;
		mPricesRoomType = pInvoice.ParentDoc.RoomTypeUpgrade;
	ElsIf ValueIsFilled(pInvoice.ParentDoc) And TypeOf(pInvoice.ParentDoc) = Type("DocumentRef.ResourceReservation") Then	
		If ValueIsFilled(pInvoice.ParentDoc.Client) Then
			vClient = pInvoice.ParentDoc.Client;
			mClient = TrimAll(vClient.FullName);
			mCitizenship = vClient.Citizenship;
		EndIf;
		mCheckInDate  = pInvoice.ParentDoc.DateTimeFrom;
		mCheckOutDate = pInvoice.ParentDoc.DateTimeTo;
		mRoom         = pInvoice.ParentDoc.ResourceType;
		mRoomType     = "";		
	ElsIf ValueIsFilled(pInvoice.GuestGroup) Then
		vGuestGroup   = pInvoice.GuestGroup;
		If ValueIsFilled(vGuestGroup.Client) Then
			vClient = vGuestGroup.Client;
			mClient = TrimAll(vClient.FullName);
			mCitizenship = vClient.Citizenship;
		EndIf;
		mCheckInDate  = vGuestGroup.CheckInDate;
		mCheckOutDate = vGuestGroup.CheckOutDate;
		If ValueIsFilled(vGuestGroup.ClientDoc) Then
			If TypeOf(vGuestGroup.ClientDoc) = Type("DocumentRef.ResourceReservation") Then	
				mRoom = vGuestGroup.ClientDoc.ResourceType;
				mRoomType = "";
			Else
				mRoom = vGuestGroup.ClientDoc.Room;
				mRoomType = vGuestGroup.ClientDoc.Room.RoomType;
				If TypeOf(vGuestGroup.ClientDoc) = Type("DocumentRef.Reservation") Or TypeOf(vGuestGroup.ClientDoc) = Type("DocumentRef.Accommodation") Then
					mPricesRoomType = vGuestGroup.ClientDoc.RoomTypeUpgrade;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	If vLogoIsSet Then
		vHeader.Drawings.Logo.Print = True;
		vHeader.Drawings.Logo.Picture = vLogo;
	Else
		vHeader.Drawings.Delete(vHeader.Drawings.Logo);
	EndIf;
	
    vCustomerCode = "";
	mCustomerLegacyName = "";
	vHeaderStruct.Insert("mClient", mClient);
	vHeaderStruct.Insert("mCurrency", pInvoice.AccountingCurrency);
	If ValueIsFilled(pInvoice.AccountingCustomer) and pInvoice.AccountingCustomer <> vHotel.IndividualsCustomer Then
		vCustomer = pInvoice.AccountingCustomer;
		vCustomerLegacyName = TrimAll(vCustomer.LegacyName);
		If IsBlankString(vCustomerLegacyName) Then
			vCustomerLegacyName = TrimAll(vCustomer.Description);
		EndIf;
		vCustomerLegacyAddress = cmGetAddressPresentation(vCustomer.LegacyAddress);
		vCustomerPostAddress = cmGetAddressPresentation(vCustomer.PostAddress);
		If lower(vCustomerPostAddress) = lower(vCustomerLegacyAddress) Then
			vCustomerPostAddress = "";
		EndIf;
		vCustomerCodes = "";
		vCustomerTIN = TrimAll(vCustomer.TIN);
		vCustomerKPP = TrimAll(vCustomer.KPP);
		vCustomerVATC = TrimAll(vCustomer.VATC);
		If Not IsBlankString(vCustomerTIN) Then
			vCustomerCodes = cmNStr("en = 'Reg. N'; de = 'Reg. N'; ru = 'ИНН'", pLanguage) + ?(IsBlankString(vCustomerKPP), " ", "/" + cmNStr("en = 'KPP '; de = 'KPP '; ru = 'КПП '", pLanguage)) + vCustomerTIN + ?(IsBlankString(vCustomerKPP), "", "/" + vCustomerKPP);
		EndIf;
		If Not IsBlankString(vCustomerVATC) Then
			vCustomerCodes = ?(IsBlankString(vCustomerCodes), "", ", ") + cmNStr("en = 'VAT Code '; de = 'Mw.St. Code '; ru = 'код НДС '", pLanguage) + vCustomerVATC;
		EndIf;
		If Not vCustomer.IsIndividual Then
			vCustomerCode = TrimAll(vCustomer.Code);
		EndIf;
		// Fax and E-Mail
		vCustomerPhones = TrimAll(vCustomer.Phone);
		vCustomerFax = TrimAll(vCustomer.Fax);
		vCustomerEMail = TrimAll(vCustomer.EMail);
		vCustomerPhones = vCustomerPhones + 
		                  ?(IsBlankString(vCustomerFax), "", ?(IsBlankString(vCustomerPhones), "", ", ") + cmNStr("en = 'fax '; de = 'fax '; ru = 'факс '", pLanguage) + vCustomerFax);
		vCustomerPhones = vCustomerPhones + 
						  ?(IsBlankString(vCustomerEMail), "", ?(IsBlankString(vCustomerPhones), "", ", ") + cmNStr("en = 'e-mail '; de = 'e-mail '; ru = 'e-mail '", pLanguage) + vCustomerEMail);
		// Name
		mCustomerLegacyName = vCustomerLegacyName + ?(IsBlankString(vCustomerCodes), "", ", " + vCustomerCodes) + Chars.LF + 
		                      ?(IsBlankString(vCustomerLegacyAddress), "", vCustomerLegacyAddress + Chars.LF) + 
							  ?(IsBlankString(vCustomerPostAddress), "", vCustomerPostAddress + Chars.LF) + 
							  ?(IsBlankString(vCustomerPhones), "", vCustomerPhones);
		mCustomerLegacyName = TrimAll(mCustomerLegacyName);
		If ValueIsFilled(pInvoice.AccountingContract) And vShowContract Then
			mCustomerLegacyName = mCustomerLegacyName + ?(IsBlankString(mCustomerLegacyName), "", Chars.LF) + 
			                      TrimAll(pInvoice.AccountingContract.Description);
		EndIf;
	Else
		If ValueIsFilled(vClient) And Not IsBlankString(vClient.FolioCustomerPresentation) Then
			mCustomerLegacyName = TrimAll(vClient.FolioCustomerPresentation);
		Else
			mCustomerLegacyName = mClient;
		EndIf;
	EndIf;
	vHeaderStruct.Insert("mCustomerLegacyName", mCustomerLegacyName);
	vHeaderStruct.Insert("mCheckInDate", mCheckInDate);
	vHeaderStruct.Insert("mCheckOutDate", mCheckOutDate);
	If vDoNotShowClientCitizenship Then
		mCitizenship = "";
	EndIf;
	vHeaderStruct.Insert("mCitizenship", mCitizenship);
	vHeaderStruct.Insert("mGuestGroup", pInvoice.GuestGroup);
	If ValueIsFilled(pInvoice.GuestGroup) Then
		mGuestGroupDescription = "";
		If Not IsBlankString(pInvoice.GuestGroup.ID) Then
			mGuestGroupDescription = mGuestGroupDescription + "Ref. # " + TrimAll(pInvoice.GuestGroup.ID);
		ElsIf Not IsBlankString(pInvoice.GuestGroup.Description) Then
			mGuestGroupDescription = mGuestGroupDescription + TrimAll(pInvoice.GuestGroup.Description);
		EndIf;
		
		vHeaderStruct.Insert("mGuestGroupDescription", mGuestGroupDescription);
	EndIf;
	vHeaderStruct.Insert("mRoom", mRoom);
	If ValueIsFilled(mRoomType) Then
		If vShowPricesRoomType And ValueIsFilled(mPricesRoomType) Then
			vHeaderStruct.Insert("mRoomType", mRoomType.GetObject().pmGetRoomTypeDescription(pLanguage) + Chars.LF + 
			                                  cmNStr("en='Prices by room type: '; ru='Цены по типу номера: '; de='Preise nach Zimmertyp: '", pLanguage) + 
											  mPricesRoomType.GetObject().pmGetRoomTypeDescription(pLanguage));
		Else
			vHeaderStruct.Insert("mRoomType", mRoomType.GetObject().pmGetRoomTypeDescription(pLanguage));
		EndIf;
	Else
		vHeaderStruct.Insert("mRoomType", "");
	EndIf;
	vHeaderStruct.Insert("mHotelPrintName", mHotelPrintName);
	vHeaderStruct.Insert("mHotelPostAddressPresentation", mHotelPostAddressPresentation);
	vHeaderStruct.Insert("mHotelPhones", mHotelPhones);
	vHeaderStruct.Insert("mCompanyLegacyName", mCompanyLegacyName);
	vHeaderStruct.Insert("mCompanyBankAccount", mCompanyBankAccount);
	vHeaderStruct.Insert("mCompanyBank", mCompanyBank);
	vHeaderStruct.Insert("mInvoiceNumber", mInvoiceNumber);
	vHeaderStruct.Insert("mInvoiceDate", mInvoiceDate);
	mFullInvoiceNumber = TrimAll(pInvoice.Number) + ?(IsBlankString(vCustomerCode), "", " " + vCustomerCode);
	vHeaderStruct.Insert("mFullInvoiceNumber", mFullInvoiceNumber);
	
	FillPropertyValues(vHeader.Parameters,vHeaderStruct);
	vSpreadsheet.Put(vHeader);
	
	vVT = New ValueTable;
	vVT.Columns.Add("Description");
	vVT.Columns.Add("Quantity");
	vVT.Columns.Add("Sum");
	vVT.Columns.Add("Type");
	vVT.Columns.Add("Date");
	vVT.Columns.Add("Price");
	
	vVATRates = New ValueTable;
	vVATRates.Columns.Add("mVATRate");
	vVATRates.Columns.Add("mSumWithoutVAT");
	vVATRates.Columns.Add("mVATSum");
	vVATRates.Columns.Add("mSumWithVAT");

	vServices = MergeCorrections(pInvoice.Services);

	vAgentCommission = 0;
	
	mTotalSum = 0;
	mTotalSumVATSum = 0;	
	mTotalPaymentSum = 0;
	vTotalCommissionSum = 0;
	mTotalCommissionSum = pInvoice.CommissionSum;
	For Each vServicesRow In vServices Do
		vVTRow = vVT.Add();	
		vVTRow.Description = vServicesRow.Service;
		vVTRow.Quantity = vServicesRow.Quantity;
		vVTRow.Sum = vServicesRow.Sum;
		vVTRow.Price = vServicesRow.Price;
		vVTRow.Date = vServicesRow.AccountingDate;
		vVTRow.Type = "Service";
		
		mTotalSum = mTotalSum + vVTRow.Sum;
		mTotalSumVATSum = mTotalSumVATSum + vServicesRow.VATSum;
		vTotalCommissionSum = vTotalCommissionSum + vServicesRow.CommissionSum;
		If vAgentCommission = 0 Then
			vAgentCommission = vServicesRow.AgentCommission;
		EndIf;		
		
		vVATRatesRow = vVATRates.Add();	
		vVATRatesRow.mVATRate = vServicesRow.VATRate;
		vVATRatesRow.mSumWithoutVAT = vServicesRow.Sum - vServicesRow.VATSum;
		vVATRatesRow.mVATSum = vServicesRow.VATSum;
		vVATRatesRow.mSumWithVAT = vServicesRow.Sum;
	EndDo;
	
	// Group services by price
	vVT.GroupBy("Description, Price, Type, Date", "Quantity, Sum");
	
	For Each vPaymentDocuments In pInvoice.PaymentDocuments Do
		vVTRow = vVT.Add();	
		vVTRow.Description = vPaymentDocuments.PaymentDoc.PaymentMethod;
		vVTRow.Quantity    = 1;
		vVTRow.Sum         = vPaymentDocuments.Sum;
		vVTRow.Date        = vPaymentDocuments.PaymentDocDate;
		vVTRow.Type        = "Payment";
		mTotalPaymentSum   = mTotalPaymentSum + vPaymentDocuments.Sum; 
	EndDo;
	
	mBalance = mTotalSum - mTotalPaymentSum;	
	
	vVT.Sort("Date");
	For Each vRow In vVT Do
		vSHRow = vTemplate.GetArea("Row");
		vSHRowStruct = New Structure;
		
		vSHRowStruct.Insert("mDate", Format(vRow.Date,"DF=dd.MM.yy"));
		vSHRowStruct.Insert("mDescription", vRow.Description);
		If vRow.Type = "Service" Then
			vSHRowStruct.Insert("mSum", Format(vRow.Sum, "ND=17; NFD=2; NZ="));
			vSHRowStruct.Insert("mPrice", Format(vRow.Price, "ND=17; NFD=2; NZ="));
			vSHRowStruct.Insert("mQuantity", vRow.Quantity);
		ElsIf vRow.Type = "Payment" Then
			vSHRowStruct.Insert("mPaymentSum", Format(vRow.Sum, "ND=17; NFD=2; NZ="));
		EndIf;
		
		FillPropertyValues(vSHRow.Parameters, vSHRowStruct);
		vSpreadsheet.Put(vSHRow);	
	EndDo;
	
	vFooterH1 = vTemplate.GetArea("FooterH1");
	vFooterH2 = vTemplate.GetArea("FooterH2");
	vFooterCommission = vTemplate.GetArea("Commission");
	vFooterStuct = New Structure;
	
	// Agent commision
	vShowCommission = False;
	mTotalSumNoCommission = mTotalSum;
	mAgentCommission = "";
	If mTotalCommissionSum <> 0 And ValueIsFilled(pInvoice.AccountingCustomer) And Not pInvoice.AccountingCustomer.DoNotPostCommission Then
		vShowCommission = True;
		mBalance = mBalance - mTotalCommissionSum;
		mTotalSumNoCommission = mTotalSumNoCommission - mTotalCommissionSum;
		If vAgentCommission <> 0 Then
			If ValueIsFilled(pInvoice.GuestGroup) Then
				mAgentCommission = "" + GetAgentCommissionDescription(vAgentCommission, pInvoice.GuestGroup.ClientDoc, pLanguage);
			Else
				mAgentCommission = "" + vAgentCommission + "%";
			EndIf;
		EndIf;
		If pInvoice.PerInvoiceCommission <> 0 Then
			mAgentCommission = mAgentCommission + ?(IsBlankString(mAgentCommission), "", ", ") + cmNStr("en='per invoice '; ru='по акту '; de='per Rechnung '", pLanguage) + pInvoice.PerInvoiceCommission + "%";
		EndIf;
		vFooterCommission.Parameters.mTotalCommissionSum = cmFormatSum(mTotalCommissionSum, pInvoice.AccountingCurrency);
		vFooterCommission.Parameters.mAgentCommission = mAgentCommission;
		vFooterCommission.Parameters.mTotalSumNoCommission = cmFormatSum(mTotalSumNoCommission, pInvoice.AccountingCurrency);
	EndIf;
	
	vFooterStuct.Insert("mTotalSum", Format(mTotalSum, "ND=17; NFD=2; NZ=") + " " + pInvoice.AccountingCurrency);
	vFooterStuct.Insert("mTotalPaymentSum", Format(mTotalPaymentSum, "ND=17; NFD=2; NZ=") + " " + pInvoice.AccountingCurrency);
	vFooterStuct.Insert("mBalance", Format(mBalance, "ND=17; NFD=2; NZ=") + " " + pInvoice.AccountingCurrency);
	mTotalSumInWords = cmSumInWords(mTotalSum,  pInvoice.AccountingCurrency, pLanguage);
	vFooterStuct.Insert("mTotalSumInWords", mTotalSumInWords);
	
	FillPropertyValues(vFooterH1.Parameters, vFooterStuct);
	FillPropertyValues(vFooterH2.Parameters, vFooterStuct);
	
	vSpreadsheet.Put(vFooterH1);
	// Put commission
	If vShowCommission Then
		vSpreadsheet.Put(vFooterCommission);
	EndIf;
	vSpreadsheet.Put(vFooterH2);
	
	vTemplateVATRateRow = vTemplate.GetArea("VATRateRow");
	
	vVATRates.GroupBy("mVATRate", "mSumWithVAT, mVATSum, mSumWithoutVAT");
	For Each vVATRateRow In vVATRates Do
		vTemplateVATRateRowStuct = New Structure;
		vTemplateVATRateRowStuct.Insert("mVATRate", TrimAll(vVATRateRow.mVATRate));
		vTemplateVATRateRowStuct.Insert("mSumWithoutVAT", Format(vVATRateRow.mSumWithoutVAT, "ND=17; NFD=2; NZ="));
		vTemplateVATRateRowStuct.Insert("mVATSum", Format(vVATRateRow.mVATSum, "ND=17; NFD=2; NZ="));
		vTemplateVATRateRowStuct.Insert("mSumWithVAT", Format(vVATRateRow.mSumWithVAT, "ND=17; NFD=2; NZ="));
		
		FillPropertyValues(vTemplateVATRateRow.Parameters,vTemplateVATRateRowStuct);
		vSpreadsheet.Put(vTemplateVATRateRow);
	EndDo;
	
	mEmployee = SessionParameters.CurrentUser.GetObject().pmGetEmployeeDescription(pLanguage);
	
	vFooter1Stuct = New Structure;
	If vCompany.InvoiceIsSignedByManager Then
		vFooter1 = vTemplate.GetArea("Footer1");
	Else
		vFooter1 = vTemplate.GetArea("Footer2");
	EndIf;
	
	vFooterRemarks = TrimAll(pInvoice.RemarksForPrinting);
	If pInvoice.SumDue > 0 And ValueIsFilled(pInvoice.CheckDate) And (ValueIsFilled(pInvoice.GuestGroup) And 
	   ValueIsFilled(pInvoice.GuestGroup.CheckInDate) And BegOfDay(pInvoice.GuestGroup.CheckInDate) >= BegOfDay(pInvoice.CheckDate) Or Not ValueIsFilled(pInvoice.GuestGroup)) Then
		vFooterRemarks = vFooterRemarks + ?(IsBlankString(vFooterRemarks), "", Chars.LF) + 
		                 ?(vDoNotShowPayDueDate, "",  cmNStr("en = 'Payment before '; de = 'Zahlung vor '; ru = 'Оплата до '; lv = 'Apmaksāt līdz '", pLanguage) + Format(pInvoice.CheckDate, "DF=dd.MM.yyyy"));
	EndIf;
	vFooter1Stuct.Insert("mRemarks", TrimAll(vFooterRemarks));
	vFooter1Stuct.Insert("mEmployee", mEmployee);
	FillPropertyValues(vFooter1.Parameters,vFooter1Stuct);
	vSpreadsheet.Put(vFooter1);
	
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Portrait, True, , True);
	cmSetSpreadsheetProtection(vSpreadsheet);
	
	Return vSpreadsheet;
EndFunction // PrintInvoice

// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Hotel, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetAgentCommissionDescription(pAgentCommission, pDoc, pLanguage) Export
	vStr = "%";
	If ValueIsFilled(pDoc) And (TypeOf(pDoc) = Type("DocumentRef.Accommodation") Or TypeOf(pDoc) = Type("DocumentRef.Reservation")) Then
		If pDoc.AgentCommissionType = Enums.AgentCommissionTypes.Percent Then
			vStr = TrimAll(pAgentCommission) + cmNStr("en='%';ru='%';de='%'", pLanguage);
		ElsIf pDoc.AgentCommissionType = Enums.AgentCommissionTypes.FirstDayPercent Then
			vStr = TrimAll(pAgentCommission) + cmNStr("en = '% for the 1-st day'; de = '% für den ersten Tag'; ru = '% за 1-ый день'", pLanguage);
		ElsIf pDoc.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerCheckInPerClient Then
			vStr = cmFormatSum(pAgentCommission, pDoc.Agent.AccountingCurrency) + cmNStr("en = ' per guest per check-in'; de = ' pro Gast pro Check-in'; ru = ' за гостя за заезд'", pLanguage);
		ElsIf pDoc.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerCheckInPerRoom Then
			vStr = cmFormatSum(pAgentCommission, pDoc.Agent.AccountingCurrency) + cmNStr("en = ' per room per check-in'; de = ' pro Zimmer pro Check-in'; ru = ' за номер за заезд'", pLanguage);
		ElsIf pDoc.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerDayPerClient Then
			vStr = cmFormatSum(pAgentCommission, pDoc.Agent.AccountingCurrency) + cmNStr("en = ' per guest per night'; de = ' pro Gast pro Nacht'; ru = ' за гостя за ночь'", pLanguage);
		ElsIf pDoc.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerDayPerRoom Then
			vStr = cmFormatSum(pAgentCommission, pDoc.Agent.AccountingCurrency) + cmNStr("en = ' per room per night'; de = ' pro Zimmer pro Nacht'; ru = ' за номер за ночь'", pLanguage);
		EndIf;
	EndIf;
	Return vStr;
EndFunction // GetAgentCommissionDescription

#EndRegion