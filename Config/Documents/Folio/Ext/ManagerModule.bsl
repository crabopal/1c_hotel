
#Region Public

// -----------------------------------------------------------------------------
Procedure PrintFolio(pFolio, pFoliosList, pGroupBy, pLanguage, pObjectPrintForm, pTransactions, pSpreadsheet=Undefined, rMessage = "", pServicesToMerge = Undefined)  Export 
	// Basic checks
	vHotel = pFolio.Hotel;
	If Not ValueIsFilled(pFolio.Hotel) Then
		vHotel = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(vHotel) Then
		rMessage = NStr("en = 'Default hotel should be selected!'; 
		|de = 'Das aktuelle Hotel ist nicht angegeben!'; 
		|ru = 'Не задана текущая гостиница!'");
		Return;
	EndIf;
	vCompany = pFolio.Company;
	If Not ValueIsFilled(pFolio.Company) Then
		vCompany = vHotel.Company;
	EndIf;
	If Not ValueIsFilled(vCompany) Then
		rMessage = NStr("en = 'Default hotel company should be selected!'; 
		|de = 'Beim Hotel muss standardmäßig eine Firma festgelegt sein!'; 
		|ru = 'У гостиницы должна быть указана фирма по умолчанию!'");
		Return;
	EndIf;
	If Not ValueIsFilled(pLanguage) Then
		pLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	
	vIsByDays = True;
	vFolioObj = pFolio.GetObject();
	
	pSpreadsheet = ?(pSpreadsheet = Undefined, New SpreadsheetDocument, pSpreadsheet);
	pSpreadsheet.Clear();
	If ValueIsFilled(pLanguage) Then
		If pLanguage = Catalogs.Languages.EN Then
			vTemplate = vFolioObj.GetTemplate("FolioDetailedEn");
			If Not IsBlankString(pGroupBy) Then
				If pGroupBy = "InPrice" Or pGroupBy = "All" Or pGroupBy = "ByService" Then
					vTemplate = vFolioObj.GetTemplate("FolioShortEn");
					vIsByDays = False;
				ElsIf pGroupBy = "PropertyDamage" Then
					vTemplate = vFolioObj.GetTemplate("FolioPropertyDamageEn");
				ElsIf pGroupBy = "ExternalClient" Then
					vTemplate = vFolioObj.GetTemplate("FolioExternalClientEn");
				EndIf;
			EndIf;
		ElsIf pLanguage = Catalogs.Languages.RU Then
			vTemplate = vFolioObj.GetTemplate("FolioDetailedRu");
			If Not IsBlankString(pGroupBy) Then
				If pGroupBy = "InPrice" Or pGroupBy = "All" Or pGroupBy = "ByService" Then
					vTemplate = vFolioObj.GetTemplate("FolioShortRu");
					vIsByDays = False;
				ElsIf pGroupBy = "PropertyDamage" Then
					vTemplate = vFolioObj.GetTemplate("FolioPropertyDamageRu");
				ElsIf pGroupBy = "ExternalClient" Then
					vTemplate = vFolioObj.GetTemplate("FolioExternalClientRu");
				EndIf;
			EndIf;
		ElsIf pLanguage = Catalogs.Languages.DE Then
			vTemplate = vFolioObj.GetTemplate("FolioDetailedDe");
			If Not IsBlankString(pGroupBy) Then
				If pGroupBy = "InPrice" Or pGroupBy = "All" Or pGroupBy = "ByService" Then
					vTemplate = vFolioObj.GetTemplate("FolioShortDe");
					vIsByDays = False;
				ElsIf pGroupBy = "PropertyDamage" Then
					vTemplate = vFolioObj.GetTemplate("FolioPropertyDamageDe");
				ElsIf pGroupBy = "ExternalClient" Then
					vTemplate = vFolioObj.GetTemplate("FolioExternalClientDe");
				EndIf;
			EndIf;
		Else      
			vMsg = StrTemplate(NStr("en = 'No folio print form template found for the %1 language!'; 
			|de = 'No folio print form template found for the %1 language!'; 
			|ru = 'Не найден шаблон печатной формы лицевого счета для языка %1!'"), pLanguage.Code);
			tcCommonFunctionOnClientServer.TextMessage(vMsg);
			Return;
		EndIf;
	Else
		vTemplate = vFolioObj.GetTemplate("FolioDetailedRu");
		If Not IsBlankString(pGroupBy) Then
			If pGroupBy = "InPrice" Or pGroupBy = "All" Or pGroupBy = "ByService" Then
				vTemplate = vFolioObj.GetTemplate("FolioShortRu");
				vIsByDays = False;
			ElsIf pGroupBy = "PropertyDamage" Then
				vTemplate = vFolioObj.GetTemplate("FolioPropertyDamageRu");
			ElsIf pGroupBy = "ExternalClient" Then
				vTemplate = vFolioObj.GetTemplate("FolioExternalClientRu");
			EndIf;
		EndIf;
	EndIf;
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(pObjectPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;
	
	// Read parameter value
	vParameter = Upper(TrimAll(pObjectPrintForm.Parameter));
	vIgnoreVATRate = (StrFind(vParameter, "IGNORE_VATRATE_ON_GROUPING") > 0);
	
	// Load pictures
	vLogoIsSet = False;
	vLogo = New Picture;
	If ValueIsFilled(pFolio.Hotel) Then
		If pFolio.Hotel.Logo <> Undefined Then
			vLogo = pFolio.Hotel.Logo.Get();
			If vLogo = Undefined Then
				vLogo = New Picture;
			Else
				vLogoIsSet = True;
			EndIf;
		EndIf;
	EndIf;
	
	// 3G, 9G, 12G Headers
	If pLanguage = Catalogs.Languages.RU Then
		If vHotel.PrintGHeaders Then
			If pGroupBy = "PropertyDamage" Then
				vGHeader = vTemplate.GetArea("H9G");
			ElsIf pGroupBy = "ExternalClient" Then
				vGHeader = vTemplate.GetArea("H12G");
			Else
				vGHeader = vTemplate.GetArea("H3G");
			EndIf;
			pSpreadsheet.Put(vGHeader);
		EndIf;
	EndIf;
	
	// Build header structure
	vHeaderStruct = New Structure("mHotelPrintName, mHotelPostAddressPresentation, mHotelPhones, mCompanyLegacyName, mCompanyTIN", "", "", "", "", "");
	
	// Header
	vHeader = vTemplate.GetArea("Header");
	// Hotel
	vHeaderStruct.mHotelPrintName = Catalogs.Hotels.pmGetHotelPrintName(vHotel, pLanguage);
	vHeaderStruct.mHotelPostAddressPresentation = Catalogs.Hotels.pmGetHotelPostAddressPresentation(vHotel, pLanguage);
	vHotelPhones = TrimAll(vHotel.Phones);
	vHotelFax = TrimAll(vHotel.Fax);
	vHeaderStruct.mHotelPhones = vHotelPhones + ?(IsBlankString(vHotelFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", pLanguage) + vHotelFax);
	// Company
	vHeaderStruct.mCompanyLegacyName = TrimAll(vCompany.GetObject().pmGetCompanyPrintName(pLanguage));
	vCompanyTIN = TrimAll(vCompany.TIN);
	vCompanyKPP = TrimAll(vCompany.KPP);
	vHeaderStruct.mCompanyTIN = ?(IsBlankString(vCompanyTIN), "", cmNStr("EN='TIN ';RU='ИНН/КПП ';de='TIN '", pLanguage) + vCompanyTIN) + ?(IsBlankString(vCompanyKPP), "", "/" + vCompanyKPP);
	If vHeaderStruct.mCompanyLegacyName = vHeaderStruct.mHotelPrintName Then
		vHeaderStruct.mCompanyLegacyName = vHeaderStruct.mCompanyTIN;
		vHeaderStruct.mCompanyTIN = "";
	EndIf;
	// Folio date and number
	If pObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintPropertyDamageRu 
		Or pObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintPropertyDamageEn 
		Or pObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintPropertyDamageRu Then
		mFolioNumber = StrReplace(cmNStr("en='Hotel property damage list №[mFolioNumber]'; ru='Акт №[mFolioNumber] о порче имущества гостиницы'; de='Schäden Liste No. [mFolioNumber]'", pLanguage), "[mFolioNumber]", cmGetDocumentNumberPresentation(pFolio.Number));
	Else
		If ValueIsFilled(vHotel) And vHotel.DoNotPrintFolioNumberInFolioPrintForms And Not pFolio.IsClosed Then
			mFolioNumber = cmNStr("en='PROFORMA'; ru='ПРЕЧЕК'; de='PROFORMA'", pLanguage);
		Else
			mFolioNumber = cmNStr("en='FOLIO N'; ru='СЧЕТ №'; de='FOLIO Nr.'", pLanguage) + cmGetDocumentNumberPresentation(pFolio.Number);
		EndIf;
	EndIf;
	// Client
	mClient = "";
	mCitizenship = "";
	If ValueIsFilled(pFolio.Client) Then
		vClient = pFolio.Client;
		mClient = TrimAll(TrimAll(vClient.LastName) + " " + TrimAll(vClient.FirstName) + " " + TrimAll(vClient.SecondName));
		If ValueIsFilled(pFolio.Client.Citizenship) Then
			mCitizenship = pFolio.Client.Citizenship.GetObject().pmGetCountryDescription(pLanguage);
		EndIf;
	EndIf;
	// External client from the folio description
	If pGroupBy = "ExternalClient" Then
		If IsBlankString(mClient) Then
			mClient = TrimAll(pFolio.Description);
		EndIf;
	EndIf;
	// Customer
	mCustomerLegacyName = "";
	If ValueIsFilled(pFolio.Customer) And ValueIsFilled(pFolio.Hotel) And 
		pFolio.Hotel.IndividualsCustomer <> pFolio.Customer Then
		mCustomerLegacyName = TrimAll(pFolio.Customer.LegacyName);
		If IsBlankString(mCustomerLegacyName) Then
			mCustomerLegacyName = TrimAll(pFolio.Customer.Description);
		EndIf;
		vAddress = "";
		If Not IsBlankString(pFolio.Customer.LegacyAddress) Then
			vAddress = TrimAll(pFolio.Customer.LegacyAddress);
		ElsIf Not IsBlankString(pFolio.Customer.PostAddress) Then
			vAddress = TrimAll(pFolio.Customer.PostAddress);
		EndIf;
		vAddress = cmGetAddressPresentation(vAddress);
		mCustomerLegacyName = mCustomerLegacyName + Chars.LF + vAddress;
	ElsIf ValueIsFilled(pFolio.Client) And Not IsBlankString(pFolio.Client.FolioCustomerPresentation) Then
		mCustomerLegacyName = TrimAll(pFolio.Client.FolioCustomerPresentation);
	ElsIf ValueIsFilled(pFolio.ParentDoc) And ValueIsFilled(pFolio.ParentDoc.Customer) And ValueIsFilled(pFolio.Hotel) And 
		pFolio.Hotel.IndividualsCustomer <> pFolio.ParentDoc.Customer Then
		mCustomerLegacyName = TrimAll(pFolio.ParentDoc.Customer.LegacyName);
		If IsBlankString(mCustomerLegacyName) Then
			mCustomerLegacyName = TrimAll(pFolio.ParentDoc.Customer.Description);
		EndIf;
		vAddress = "";
		If Not IsBlankString(pFolio.ParentDoc.Customer.LegacyAddress) Then
			vAddress = TrimAll(pFolio.ParentDoc.Customer.LegacyAddress);
		ElsIf Not IsBlankString(pFolio.ParentDoc.Customer.PostAddress) Then
			vAddress = TrimAll(pFolio.ParentDoc.Customer.PostAddress);
		EndIf;
		vAddress = cmGetAddressPresentation(vAddress);
		mCustomerLegacyName = mCustomerLegacyName + Chars.LF + vAddress;
	EndIf;
	If ValueIsFilled(pObjectPrintForm) And Not IsBlankString(vParameter) Then
		If StrFind(vParameter, "FOLIO_CUSTOMER") > 0 And Not ValueIsFilled(pFolio.Customer) Then
			mCustomerLegacyName = "";
		EndIf;
	EndIf;
	If IsBlankString(mCustomerLegacyName) Then
		If ValueIsFilled(pFolio.Client) Then
			vAddress = "";
			If Not IsBlankString(pFolio.Client.Address) Then
				vAddress = cmGetAddressPresentation(pFolio.Client.Address);
				If Not IsBlankString(vAddress) And Find(vAddress, Chars.LF) > 0 Then
					mClient = mClient + Chars.LF + vAddress;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	// Contract
	mContractDescription = "";
	If ValueIsFilled(pFolio.Contract) Then
		mContractDescription = TrimAll(pFolio.Contract.Description);
	EndIf;
	// Currency
	mFolioCurrency = "";
	If ValueIsFilled(pFolio.FolioCurrency) Then
		vCurrencyObj = pFolio.FolioCurrency.GetObject();
		mFolioCurrency = vCurrencyObj.pmGetCurrencyDescription(pLanguage);
	EndIf;
	// Room and room type
	mRoom = TrimAll(pFolio.Room);
	If ValueIsFilled(pObjectPrintForm) And Not IsBlankString(vParameter) Then
		If StrFind(vParameter, "ACCOMMODATION_TYPE") > 0 Then
			If ValueIsFilled(pFolio.ParentDoc) And 
				(TypeOf(pFolio.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(pFolio.ParentDoc) = Type("DocumentRef.Reservation")) Then
				If ValueIsFilled(pFolio.ParentDoc.AccommodationType) Then
					If pFolio.ParentDoc.AccommodationType.Type = Enums.AccomodationTypes.Beds Or
						pFolio.ParentDoc.AccommodationType.Type = Enums.AccomodationTypes.AdditionalBed Then
						mRoom = mRoom + ", " + pFolio.ParentDoc.AccommodationType.GetObject().pmGetAccommodationTypeDescription(pLanguage);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	mRoomType = "";
	If ValueIsFilled(pFolio.Room) Then
		If ValueIsFilled(pFolio.Room.RoomType) Then
			vRoomTypeToPrint = pFolio.Room.RoomType;
			vCurDoc = pFolio.ParentDoc;
			If ValueIsFilled(vCurDoc) And (TypeOf(vCurDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vCurDoc) = Type("DocumentRef.Reservation")) Then
				If ValueIsFilled(vRoomTypeToPrint) And ValueIsFilled(vCurDoc.RoomTypeUpgrade) And vCurDoc.RoomTypeUpgrade.BaseRoomType = vRoomTypeToPrint Then
					vRoomTypeToPrint = vCurDoc.RoomTypeUpgrade;
				EndIf;
			EndIf;
			vRoomTypeObj = vRoomTypeToPrint.GetObject();
			mRoomType = vRoomTypeObj.pmGetRoomTypeDescription(pLanguage);
		EndIf;
	EndIf;
	// Check in and check out dates
	mCheckInDate = Format(pFolio.DateTimeFrom, "DF='dd.MM.yy HH:mm'");
	mCheckOutDate = Format(pFolio.DateTimeTo, "DF='dd.MM.yy HH:mm'");
	// Check if transactions are selected
	vMinAccDate = '39991231';
	vMaxAccDate = '00010101';
	If pTransactions.Count() > 0 Then
		For Each vTrnRow In pTransactions Do
			If TypeOf(vTrnRow.Document) = Type("DocumentRef.Charge") Then
				vService = vTrnRow.Service;
				vAccountingDate = vTrnRow.AccountingDate;
				If ValueIsFilled(vService) And ValueIsFilled(vService.QuantityCalculationRule) Then
					vAccountingDateMove = cmGetAccountingDateMove(vService.QuantityCalculationRule, False, ?(ValueIsFilled(pFolio.ParentDoc), pFolio.ParentDoc, pFolio));
					If vAccountingDateMove < 0 Then
						vAccountingDate = vTrnRow.AccountingDate - 24*3600;
					EndIf;
				EndIf;
				vMinAccDate = Min(vMinAccDate, vAccountingDate);
				vMaxAccDate = Max(vMaxAccDate, vAccountingDate);
			EndIf;
		EndDo;
		If vMinAccDate <> '39991231' And vMaxAccDate <> '00010101' Then
			mCheckInDate = Format(vMinAccDate, "DF='dd.MM.yy'");
			mCheckOutDate = Format(vMaxAccDate + 24*3600, "DF='dd.MM.yy'");
		EndIf;
	EndIf;
	// Guest group
	mGuestGroup = TrimAll(pFolio.GuestGroup);
	vHotelPrefix = Catalogs.Hotels.pmGetPrefix(pFolio.Hotel);
	If Not IsBlankString(vHotelPrefix) And pFolio.Hotel.ShowHotelPrefixBeforeGroupCode Then
		mGuestGroup = vHotelPrefix + mGuestGroup;
	EndIf;
	// Room rate
	mRoomRate = "";
	If ValueIsFilled(pFolio.ParentDoc) And 
		(TypeOf(pFolio.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(pFolio.ParentDoc) = Type("DocumentRef.Reservation")) Then
		If ValueIsFilled(pFolio.ParentDoc.RoomRate) Then
			mRoomRate = TrimAll(pFolio.ParentDoc.RoomRate.GetObject().pmGetRoomRateDescription(pLanguage));
		EndIf;
	EndIf;
	// Set parameters and put report section
	FillPropertyValues(vHeader.Parameters, vHeaderStruct);
	
	vHeader.Parameters.mFolioNumber = mFolioNumber;
	vHeader.Parameters.mClient = mClient;
	vHeader.Parameters.mCustomerLegacyName = mCustomerLegacyName;
	If pLanguage <> Catalogs.Languages.DE Then
		vHeader.Parameters.mFolioCurrency = mFolioCurrency;
	EndIf;
	If pGroupBy <> "ExternalClient" Then
		If pLanguage <> Catalogs.Languages.DE Then
			vHeader.Parameters.mCitizenship = mCitizenship;
		EndIf;
		vHeader.Parameters.mRoom = mRoom;
		vHeader.Parameters.mRoomType = mRoomType;
		vHeader.Parameters.mCheckInDate = mCheckInDate;
		vHeader.Parameters.mCheckOutDate = mCheckOutDate;
		vHeader.Parameters.mGuestGroup = mGuestGroup;
		vHeader.Parameters.mRoomRate = mRoomRate;
	EndIf;
	
	// Logo
	If vLogoIsSet Then
		vHeader.Drawings.Logo.Print = True;
		vHeader.Drawings.Logo.Picture = vLogo;
	Else
		vHeader.Drawings.Delete(vHeader.Drawings.Logo);
	EndIf;
	
	// QR-Code
	Try
		If StrFind(vParameter, "SHOW_QRCODE") > 0 Then
			vQRCodeStructure = New Structure("FolioNumber,Hotel");
			vQRCodeStructure.FolioNumber = pFolio.Number;
			vQRCodeStructure.Hotel = pFolio.Hotel.Code;
			
			qrStr = Catalogs.DataConvertationRules.MapToJSON(vQRCodeStructure);
			vHeader.Drawings.QRCodeControl.Print = True;
			vHeader.Drawings.QRCodeControl.Picture = cmGetQRCodePicture(qrStr);
		Else
			vHeader.Drawings.Delete(vHeader.Drawings.QRCodeControl);		
		EndIf;
	Except
	EndTry;
	
	// Put header
	pSpreadsheet.Put(vHeader);
	
	// Get row template area
	vRow = vTemplate.GetArea("Row");
	
	// Get all folio transactions
	If pTransactions.Count() = 0 Then
		vTransactions = pFolio.GetObject().pmGetAllFolioTransactions();
		For Each vTransactionsRow In vTransactions Do
			If vTransactionsRow.RecordType = AccumulationRecordType.Receipt Then
				vTransactionsRowService = vTransactionsRow.Service;
				If ValueIsFilled(vTransactionsRowService) And ValueIsFilled(vTransactionsRowService.QuantityCalculationRule) Then
					vAccountingDateMove = cmGetAccountingDateMove(vTransactionsRowService.QuantityCalculationRule, False, ?(ValueIsFilled(pFolio.ParentDoc), pFolio.ParentDoc, pFolio));
					If vAccountingDateMove > 0 Then
						vTransactionsRow.ServiceDate = vTransactionsRow.ServiceDate - (24*3600);
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	Else
		vTransactions = pTransactions;
		If vTransactions.Columns.Find("ServiceDate") = Undefined Then
			vTransactions.Columns.Add("ServiceDate", cmGetDateTimeTypeDescription());
			For Each vTransactionsRow In vTransactions Do
				If vTransactionsRow.RecordType = AccumulationRecordType.Receipt And ValueIsFilled(vTransactionsRow.Charge) Then
					vTransactionsRow.ServiceDate = vTransactionsRow.Charge.ServiceDate;
					vTransactionsRowService = vTransactionsRow.Service;
					If ValueIsFilled(vTransactionsRowService) And ValueIsFilled(vTransactionsRowService.QuantityCalculationRule) Then
						vAccountingDateMove = cmGetAccountingDateMove(vTransactionsRowService.QuantityCalculationRule, False, ?(ValueIsFilled(pFolio.ParentDoc), pFolio.ParentDoc, pFolio));
						If vAccountingDateMove > 0 Then
							vTransactionsRow.ServiceDate = vTransactionsRow.ServiceDate - (24*3600);
						EndIf;
					EndIf;
				Else
					vTransactionsRow.ServiceDate = vTransactionsRow.Period;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	cmRemoveTransactionsWithStorno(vTransactions);
	If pFoliosList.Count() > 1 Then
		For Each vFoliosListItem In pFoliosList Do
			If vFoliosListItem.Value <> pFolio Then
				vFolioTransactions = vFoliosListItem.Value.GetObject().pmGetAllFolioTransactions();
				For Each vFolioTransactionsRow In vFolioTransactions Do
					vTransactionsRow = vTransactions.Add();
					FillPropertyValues(vTransactionsRow, vFolioTransactionsRow);
				EndDo;
			EndIf;
		EndDo;
		vTransactions.Sort("Period");
	EndIf;
	
	// Payment VAT amounts
	vVATRatePaymentTransactions = New ValueTable();
	vVATRatePaymentTransactions.Columns.Add("VATRate", cmGetCatalogTypeDescription("VATRates"));
	vVATRatePaymentTransactions.Columns.Add("RecordType");
	vVATRatePaymentTransactions.Columns.Add("Sum", cmGetSumTypeDescription());
	vVATRatePaymentTransactions.Columns.Add("VATSum", cmGetSumTypeDescription());
	
	// Join payment sections if cash register has "Do not print payment sections" flag turned on
	vDoGroupBy = False;
	For Each vTranRow In vTransactions Do
		If TypeOf(vTranRow.Document) = Type("DocumentRef.Payment") Or TypeOf(vTranRow.Document) = Type("DocumentRef.CustomerPayment") Or TypeOf(vTranRow.Document) = Type("DocumentRef.Return") Then
			If ValueIsFilled(vTranRow.Folio) And ValueIsFilled(vTranRow.Folio.Company) And ValueIsFilled(vTranRow.Folio.Company.VATRate) And 
				ValueIsFilled(vTranRow.Document.CashRegister) And vTranRow.Document.CashRegister.DoNotPrintPaymentSections Then
				If vTranRow.PaymentSum <> 0 Then
					vDoGroupBy = True;
					vTranRow.PaymentSection = Catalogs.PaymentSections.EmptyRef();
					vTranRow.VATRate = vTranRow.Folio.Company.VATRate;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	If vDoGroupBy Then 
		vTransactions.GroupBy("Document, Charge, RecordType, Folio, FolioParentDoc, ChargeParentDoc, FolioClient, PaymentSection, Service, Price, Period, ServiceDate, Remarks, PaymentMethod, RecorderNumber, Payer, IsRoomRevenue, IsInPrice, CalendarDayType, Room, VATRate, Performer", "Sum, VATSum, Quantity, Limit, PaymentSum");
	EndIf;
	
	// Change accounting dates for breakfast
	If Not IsBlankString(pGroupBy) And pGroupBy <> "ByService" And pGroupBy <> "PropertyDamage" And pGroupBy <> "ExternalClient" Then
		For Each vTranRow In vTransactions Do
			If vTranRow.IsInPrice And ValueIsFilled(vTranRow.Service.QuantityCalculationRule) Then
				vAccountingDateMove = cmGetAccountingDateMove(vTranRow.Service.QuantityCalculationRule, False, ?(ValueIsFilled(pFolio.ParentDoc), pFolio.ParentDoc, pFolio));
				If vAccountingDateMove < 0 Then
					vTranRow.Period = vTranRow.Period - 24*3600;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	// Join services according to service parameters
	If Not IsBlankString(pGroupBy) And pGroupBy <> "ByService" And pGroupBy <> "PropertyDamage" And pGroupBy <> "ExternalClient" Then
		// Try to replace accommodation service to the one that should be used for printing
		vChargeParentDoc = Undefined;
		vAccountingDate = '00010101';
		vFirstRoomRateService = Undefined;
		vFirstRoomRateServiceIsFound = False;
		For Each vTranRow In vTransactions Do
			vTranRowService = vTranRow.Service;
			If ValueIsFilled(vTranRowService) Then
				If vChargeParentDoc <> vTranRow.ChargeParentDoc Then
					vChargeParentDoc = vTranRow.ChargeParentDoc;
					vAccountingDate = '00010101';
					vFirstRoomRateService = Undefined;
					vFirstRoomRateServiceIsFound = False;
				EndIf;
				If vAccountingDate <> BegOfDay(vTranRow.Period) Then
					vAccountingDate = BegOfDay(vTranRow.Period);
					vFirstRoomRateService = Undefined;
					vFirstRoomRateServiceIsFound = False;
				EndIf;
				If vTranRowService.IsRoomRevenue And vTranRowService.IsInPrice And Not vTranRowService.RoomRevenueAmountsOnly Then
					If ValueIsFilled(vTranRowService.HideIntoServiceOnPrint) Then
						vTranRow.Service = vTranRowService.HideIntoServiceOnPrint;
					EndIf;
					If Not vFirstRoomRateServiceIsFound Then
						vFirstRoomRateService = vTranRowService;
						vFirstRoomRateServiceIsFound = True;
					Else
						If vFirstRoomRateService <> vTranRowService Then
							vTranRow.Quantity = 0;
						EndIf;
					EndIf;
				ElsIf vTranRowService.DoNotGroupIntoRoomRateOnPrint And ValueIsFilled(vTranRowService.HideIntoServiceOnPrint) Then
					vTranRow.Service = vTranRowService.HideIntoServiceOnPrint;
				EndIf;
			EndIf;
		EndDo;
		// Try to merge other services to the accommodation service
		vFirstReplacedService = Undefined;
		vCurAccountingDate = '00010101';
		i = 0;
		While i < vTransactions.Count() Do
			vTranRow = vTransactions.Get(i);
			vTranRowService = vTranRow.Service;
			If BegOfDay(vTranRow.Period) <> vCurAccountingDate Then
				vCurAccountingDate = BegOfDay(vTranRow.Period);
				vFirstReplacedService = Undefined;
			EndIf;
			If ValueIsFilled(vTranRowService) And ValueIsFilled(vTranRowService.HideIntoServiceOnPrint) Then
				If Not vTranRowService.DoNotGroupIntoRoomRateOnPrint Then
					// Try to find service to hide current one to
					vHideToServices = vTransactions.FindRows(New Structure("Service, Period, Folio", vTranRowService.HideIntoServiceOnPrint, BegOfDay(vTranRow.Period), vTranRow.Folio));
					If vHideToServices.Count() = 0 And BegOfDay(vTranRow.Period) >= BegOfDay(vTranRow.Folio.DateTimeTo) Then
						// Try to find service for the previous date
						vHideToServices = vTransactions.FindRows(New Structure("Service, Period, Folio", vTranRowService.HideIntoServiceOnPrint, BegOfDay(vTranRow.Period) - 24*3600, vTranRow.Folio));
					EndIf;
					If vHideToServices.Count() > 0 Then
						vSrv2Hide2 = vHideToServices.Get(0);
						vSrv2Hide2.Sum = vSrv2Hide2.Sum + vTranRow.Sum;
						vSrv2Hide2.VATSum = vSrv2Hide2.VATSum + vTranRow.VATSum;
						vSrv2Hide2.Price = cmRecalculatePrice(vSrv2Hide2.Sum, vSrv2Hide2.Quantity);
						// Delete current service
						vTransactions.Delete(i);
						Continue;
					Else
						If Not ValueIsFilled(vFirstReplacedService) Then
							vFirstReplacedService = vTranRowService;
						Else
							If vTranRowService <> vFirstReplacedService Then
								vTranRow.Quantity = 0;
							EndIf;
						EndIf;
						vTranRow.Service = vTranRowService.HideIntoServiceOnPrint; 
					EndIf;
				EndIf;
			EndIf;
			i = i + 1;
		EndDo;
	EndIf;
	
	// Try to merge checked services to the accommodation service
	If pServicesToMerge.Count() <> 0 Then
		vFirstReplacedService = Undefined;
		vCurAccountingDate = '00010101';
		
		For Each vService In pServicesToMerge Do
			vTransactionsToMerge = vTransactions.FindRows(New Structure("Service", vService.Value));
			For Each vTranToMerge In vTransactionsToMerge Do
				vTranToMergeServ = vTranToMerge.Service;
				If BegOfDay(vTranToMerge.Period) <> vCurAccountingDate Then
					vCurAccountingDate = BegOfDay(vTranToMerge.Period);
					vFirstReplacedService = Undefined;
				EndIf;
				If ValueIsFilled(vTranToMergeServ) Then
					// Try to find service to hide current one to
					vHideToServices = vTransactions.FindRows(New Structure("IsRoomRevenue, IsInPrice, Period, Folio", True, True, BegOfDay(vTranToMerge.Period), vTranToMerge.Folio));
					If vHideToServices.Count() = 0 And BegOfDay(vTranToMerge.Period) >= BegOfDay(vTranToMerge.Folio.DateTimeTo) Then
						// Try to find service for the previous date
						vHideToServices = vTransactions.FindRows(New Structure("IsRoomRevenue, IsInPrice, Period, Folio", True, True, BegOfDay(vTranToMerge.Period) - 24*3600, vTranToMerge.Folio));
					EndIf;
					If vHideToServices.Count() > 0 Then
						vSrv2Hide2 = vHideToServices.Get(0);
						vSrv2Hide2.Sum = vSrv2Hide2.Sum + vTranToMerge.Sum;
						vTranToMerge.VATRate = vSrv2Hide2.VATRate;
						vTranToMerge.VATSum = cmCalculateVATSum(vTranToMerge.VATRate, vTranToMerge.Sum, vTranToMerge.AccountingDate);
						vSrv2Hide2.VATSum = vSrv2Hide2.VATSum + vTranToMerge.VATSum;
						vSrv2Hide2.Price = cmRecalculatePrice(vSrv2Hide2.Sum, vSrv2Hide2.Quantity);
						// Delete current service
						vTransactions.Delete(vTransactions.IndexOf(vTranToMerge));
						Continue;
					Else
						vAccomodationRows = vTransactions.FindRows(New Structure("IsRoomRevenue, IsInPrice, Folio", True, True, vTranToMerge.Folio));
						vFoliosAccomod = vAccomodationRows.Get(0);
						vTranToMergeServ = vFoliosAccomod.Get(0).Service;
						vTranToMerge.VATRate = vFoliosAccomod.VATRate;
						vTranToMerge.VATSum = cmCalculateVATSum(vTranToMerge.VATRate, vTranToMerge.Sum, vTranToMerge.AccountingDate);
					EndIf;
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
	// Get accommodation service name
	vAccommodationService = Undefined;	
	vAccommodationServiceVATRate = Undefined;	
	i = 0;
	While i < vTransactions.Count() Do
		vTran = vTransactions.Get(i);
		If vTran.RecordType = AccumulationRecordType.Receipt Then
			If pGroupBy = "InPricePerFolioPerDay" Or pGroupBy = "InPricePerDay" Or
				pGroupBy = "AllPerFolioPerDay" Or pGroupBy = "AllPerDay" Or
				pGroupBy = "InPricePerFolio" Or pGroupBy = "InPrice" Or
				pGroupBy = "AllPerFolio" Or pGroupBy = "All" Then
				If vTran.Sum = 0 Then
					vTransactions.Delete(i);
					Continue;
				EndIf;
			EndIf;
			If vAccommodationService = Undefined Then
				If vTran.IsRoomRevenue And Not vTran.Service.RoomRevenueAmountsOnly Then
					vAccommodationService = vTran.Service;
					vAccommodationServiceVATRate = vTran.VATRate;
				EndIf;
			EndIf;
		EndIf;
		i = i + 1;
	EndDo;
	
	// Group by transactions according to the folio print type
	vTransactionsCopy = vTransactions.Copy();
	vGroupByAccommodation = False;
	If Not IsBlankString(pGroupBy) And pGroupBy <> "PropertyDamage" And pGroupBy <> "ExternalClient" Then
		If pGroupBy = "InPricePerDay" Then
			vGroupByAccommodation = True;
			// Change transaction services
			For Each vTran In vTransactions Do
				If vTran.RecordType = AccumulationRecordType.Receipt Then
					// Reset "is in price" flag if necessary
					If ValueIsFilled(vTran.Service) And vTran.Service.DoNotGroupIntoRoomRateOnPrint Then
						vTran.IsInPrice = False;
					EndIf;
					vTran.Document = Undefined;
					vTran.Period = BegOfDay(vTran.Period);
					vTran.PaymentMethod = Catalogs.PaymentMethods.EmptyRef();
					vTran.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
					vTran.Room = Catalogs.Rooms.EmptyRef();
					If Not vTran.IsRoomRevenue And vTran.IsInPrice Then
						If ValueIsFilled(vAccommodationService) And (vIgnoreVATRate Or Not vIgnoreVATRate And vAccommodationServiceVATRate = vTran.VATRate) Then
							vTran.Service = vAccommodationService;
							vTran.Quantity = 0;
							vTran.Price = 0;
							vTran.VATRate = ?(vIgnoreVATRate, vAccommodationServiceVATRate, vTran.VATRate);
						EndIf;
						vTran.Remarks = "";
					ElsIf vTran.IsRoomRevenue And vTran.IsInPrice Then
						// Reset quantity for services where amount should be added to room revenue only
						If vTran.Service.RoomRevenueAmountsOnly Then
							vTran.Quantity = 0;
							vTran.Price = 0;
						EndIf;
						// Reset service to accommodation service	
						If ValueIsFilled(vAccommodationService) And (vIgnoreVATRate Or Not vIgnoreVATRate And vAccommodationServiceVATRate = vTran.VATRate) Then
							vTran.Service = vAccommodationService;
							vTran.VATRate = ?(vIgnoreVATRate, vAccommodationServiceVATRate, vTran.VATRate);
						EndIf;
						vTran.Remarks = "";
						// Reset quantity and price for transfered charges
						If ValueIsFilled(vTran.Charge) Then
							If Not cmIsInDocumentChain(pFolio.ParentDoc, vTran.Charge.ParentDoc) Then
								vTran.Quantity = 0;
								vTran.Price = 0;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
		ElsIf pGroupBy = "AllPerDay" Then
			vGroupByAccommodation = True;
			// Change transaction services
			For Each vTran In vTransactions Do
				If vTran.RecordType = AccumulationRecordType.Receipt Then
					vTran.Document = Undefined;
					vTran.Period = BegOfDay(vTran.Period);
					vTran.Remarks = "";
					vTran.Room = Catalogs.Rooms.EmptyRef();
					vTran.PaymentMethod = Catalogs.PaymentMethods.EmptyRef();
					vTran.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
					If Not vTran.IsRoomRevenue Then
						If ValueIsFilled(vAccommodationService) And (vIgnoreVATRate Or Not vIgnoreVATRate And vAccommodationServiceVATRate = vTran.VATRate) Then
							vTran.Service = vAccommodationService;
							vTran.Quantity = 0;
							vTran.Price = 0;
							vTran.VATRate = ?(vIgnoreVATRate, vAccommodationServiceVATRate, vTran.VATRate);
						EndIf;
					Else
						// Reset quantity for services where amount should be added to room revenue only
						If vTran.Service.RoomRevenueAmountsOnly Then
							vTran.Service = vAccommodationService;
							vTran.Quantity = 0;
							vTran.Price = 0;
							vTran.VATRate = ?(vIgnoreVATRate, vAccommodationServiceVATRate, vTran.VATRate);
						EndIf;
						// Reset quantity and price for transfered charges
						If ValueIsFilled(vTran.Charge) Then
							If Not cmIsInDocumentChain(pFolio.ParentDoc, vTran.Charge.ParentDoc) Then
								vTran.Quantity = 0;
								vTran.Price = 0;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
		ElsIf pGroupBy = "InPrice" Then
			vGroupByAccommodation = True;
			// Change transaction services
			For Each vTran In vTransactions Do
				If vTran.RecordType = AccumulationRecordType.Receipt Then
					// Reset "is in price" flag if necessary
					If ValueIsFilled(vTran.Service) And vTran.Service.DoNotGroupIntoRoomRateOnPrint Then
						vTran.IsInPrice = False;
					EndIf;
					vTran.Document = Undefined;
					vTran.Period = BegOfDay(pFolio.Date);
					vTran.ServiceDate = BegOfDay(pFolio.Date);
					vTran.PaymentMethod = Catalogs.PaymentMethods.EmptyRef();
					If Not vTran.IsRoomRevenue And vTran.IsInPrice Then
						If ValueIsFilled(vAccommodationService) And (vIgnoreVATRate Or Not vIgnoreVATRate And vAccommodationServiceVATRate = vTran.VATRate) Then
							vTran.Service = vAccommodationService;
							vTran.Quantity = 0;
							vTran.Price = 0;
							vTran.VATRate = ?(vIgnoreVATRate, vAccommodationServiceVATRate, vTran.VATRate);
						EndIf;
						vTran.Remarks = "";
					ElsIf vTran.IsRoomRevenue And vTran.IsInPrice Then
						// Reset quantity for services where amount should be added to room revenue only
						If vTran.Service.RoomRevenueAmountsOnly Then
							vTran.Quantity = 0;
							vTran.Price = 0;
						EndIf;
						// Reset service to accommodation service	
						If ValueIsFilled(vAccommodationService) And (vIgnoreVATRate Or Not vIgnoreVATRate And vAccommodationServiceVATRate = vTran.VATRate) Then
							vTran.Service = vAccommodationService;
							vTran.VATRate = ?(vIgnoreVATRate, vAccommodationServiceVATRate, vTran.VATRate);
						EndIf;
						vTran.Remarks = "";
						// Reset quantity and price for transfered charges
						If ValueIsFilled(vTran.Charge) Then
							If Not cmIsInDocumentChain(pFolio.ParentDoc, vTran.Charge.ParentDoc) Then
								vTran.Quantity = 0;
								vTran.Price = 0;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
		ElsIf pGroupBy = "All" Then
			vGroupByAccommodation = True;
			// Change transaction services
			For Each vTran In vTransactions Do
				If vTran.RecordType = AccumulationRecordType.Receipt Then
					vTran.Document = Undefined;
					vTran.Period = BegOfDay(pFolio.Date);
					vTran.ServiceDate = BegOfDay(pFolio.Date);
					// Reset quantity for services where amount should be added to room revenue only
					If vTran.Service.RoomRevenueAmountsOnly Then
						vTran.Quantity = 0;
						vTran.Price = 0;
					EndIf;
					// Reset service to accommodation service	
					If ValueIsFilled(vAccommodationService) And (vIgnoreVATRate Or Not vIgnoreVATRate And vAccommodationServiceVATRate = vTran.VATRate) Then
						vTran.Service = vAccommodationService;
						vTran.VATRate = ?(vIgnoreVATRate, vAccommodationServiceVATRate, vTran.VATRate);
					EndIf;
					vTran.Remarks = "";
					vTran.PaymentMethod = Catalogs.PaymentMethods.EmptyRef();
					vTran.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
					If Not vTran.IsRoomRevenue Then
						vTran.Quantity = ?(ValueIsFilled(vAccommodationService), 0, vTran.Quantity);
						vTran.Price = 0;
					Else
						// Reset quantity and price for transfered charges
						If ValueIsFilled(vTran.Charge) Then
							If Not cmIsInDocumentChain(pFolio.ParentDoc, vTran.Charge.ParentDoc) Then
								vTran.Quantity = 0;
								vTran.Price = 0;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
		ElsIf pGroupBy = "ByService" Then
			// Change transaction services
			For Each vTran In vTransactions Do
				If vTran.RecordType = AccumulationRecordType.Receipt Then
					vTran.Document = Undefined;
					vTran.Period = BegOfDay(pFolio.Date);
					vTran.ServiceDate = BegOfDay(pFolio.Date);
					vTran.Price = 0;
					vTran.Remarks = "";
					vTran.PaymentMethod = Catalogs.PaymentMethods.EmptyRef();
					vTran.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
					vTran.Room = Catalogs.Rooms.EmptyRef();
				EndIf;
			EndDo;
		EndIf;
		// Group by transactions
		If StrFind(vParameter, "GROUP_BY_PRICE") > 0 Then
			vTransactions.GroupBy("Period, ServiceDate, Document, RecordType, Service, PaymentMethod, CalendarDayType, Remarks, Room, VATRate, Price", "Sum, VATSum, Quantity");
		Else
			vTransactions.GroupBy("Period, ServiceDate, Document, RecordType, Service, PaymentMethod, CalendarDayType, Remarks, Room, VATRate", "Sum, VATSum, Price, Quantity");
		EndIf;
		// Recalculate price for all charges and delete zero sum rows
		i = 0;
		While i < vTransactions.Count() Do
			vTran = vTransactions.Get(i);
			If vTran.Sum = 0 And pGroupBy <> "ByService" Then
				vTransactions.Delete(i);
			Else
				If vTran.RecordType = AccumulationRecordType.Receipt Then
					If Not vIgnoreVATRate Then
						vTran.VATSum = cmCalculateVATSum(vTran.VATRate, vTran.Sum, vTran.Period);
					EndIf;
					vTran.Price = cmRecalculatePrice(vTran.Sum, vTran.Quantity);
				EndIf;
				i = i + 1;
			EndIf;
		EndDo;
	EndIf;
	
	// Print transactions
	vTotalSum = 0;
	vTotalPaymentSum = 0;
	vTotalVATSum = 0;
	vTotalPaymentVATSum = 0;
	For Each vTran In vTransactions Do
		vPrintThisTransaction = True;
		
		// Fill parameters
		If (IsBlankString(pGroupBy) Or pGroupBy = "PropertyDamage") And vTran.Period <> BegOfDay(vTran.Period) Then
			mAccountingDate = Format(vTran.ServiceDate, "DF='dd.MM HH:mm'");
		Else
			mAccountingDate = Format(vTran.ServiceDate, "DF=dd.MM.yy");
		EndIf;
		mPrice = 0;
		If vTran.RecordType = AccumulationRecordType.Expense Then
			If StrFind(vParameter, "DO_NOT_SHOW_PAYMENTS") > 0 Then
				vPrintThisTransaction = False;
			EndIf;
			
			mDescription = TrimAll(vTran.PaymentMethod);
			If ValueIsFilled(vTran.PaymentMethod) Then
				vPaymentMethodObj = vTran.PaymentMethod.GetObject();
				mDescription = vPaymentMethodObj.pmGetPaymentMethodDescription(pLanguage);
			EndIf;
			
			// Add payment number and date
			If StrFind(vParameter, "DO_NOT_SHOW_PAYMENT_REMARKS") > 0 Then
				vTran.Remarks = "";
			Else
				mDescription = mDescription + ?(IsBlankString(mDescription), "", " - ") + 
				?(ValueIsFilled(vTran.Document), cmNStr("en='Doc. #';ru='Док. №';de='Dokument Nr.'", pLanguage) + 
				cmGetDocumentNumberPresentation(vTran.Document.Number) + 
				?(vIsByDays, "", cmNStr("en=' - ';ru=' от ';de=' vom '", pLanguage) + Format(vTran.Document.Date, "DF=dd.MM.yy")), "");
			EndIf;
			
			If ValueIsFilled(vTran.Document) And 
				TypeOf(vTran.Document) = Type("DocumentRef.Payment") Or 
				TypeOf(vTran.Document) = Type("DocumentRef.Return") Then
				If ValueIsFilled(vTran.Document.Payer) And 
					vTran.Document.Payer <> vTran.Document.Folio.Client And 
					vTran.Document.Payer <> vTran.Document.Folio.Customer Then
					If TypeOf(vTran.Document.Payer) = Type("CatalogRef.Clients") Then
						mDescription = mDescription + " - " + TrimAll(vTran.Document.Payer.FullName);
					ElsIf TypeOf(vTran.Document.Payer) = Type("CatalogRef.Customers") Then
						If IsBlankString(vTran.Document.Payer.LegacyName) Then
							mDescription = mDescription + " - " + TrimAll(vTran.Document.Payer);
						Else
							mDescription = mDescription + " - " + TrimAll(vTran.Document.Payer.LegacyName);
						EndIf;
					EndIf;
				EndIf;
				If vTran.Document.PaymentCurrency <> vTran.Document.FolioCurrency Then
					mDescription = mDescription + " - " + cmFormatSum(vTran.Document.Sum, vTran.Document.PaymentCurrency);
				EndIf;
			EndIf;
			mQuantity = "";
			mSum = "";
			mPaymentSum = vTran.Sum;
			
			vTotalPaymentSum = vTotalPaymentSum + vTran.Sum;
			vTotalPaymentVATSum = vTotalPaymentVATSum + vTran.VATSum;
			
			vVATPaymentRow = vVATRatePaymentTransactions.Add();
			vVATPaymentRow.VATRate = vTran.VATRate;
			vVATPaymentRow.RecordType = AccumulationRecordType.Receipt;
			vVATPaymentRow.Sum = vTran.Sum;
			vVATPaymentRow.VATSum = vTran.VATSum;
		Else
			mDescription = TrimAll(vTran.Service);
			mSum = vTran.Sum;
			mPaymentSum = "";
			mQuantity = "";
			If Round(vTran.Quantity, 3) <> vTran.Quantity Then
				mQuantity = ?(vTran.Quantity = 0, "", Format(vTran.Quantity, "ND=17; NFD=3"));
			Else
				mQuantity = ?(vTran.Quantity = 0, "", String(vTran.Quantity));
			EndIf;
			If ValueIsFilled(vTran.Service) Then
				vServiceObj = vTran.Service.GetObject();
				mDescription = vServiceObj.pmGetServiceDescription(pLanguage, ?((vTran.Service = vAccommodationService) And vGroupByAccommodation, True, False));
				If IsBlankString(pGroupBy) Or pGroupBy = "PropertyDamage" Or pGroupBy = "ExternalClient" Then
					vRetailSum = Round(vTran.Quantity * vTran.Price, 2);
					If vRetailSum > 0 And vRetailSum > vTran.Sum Then
						vDiscountAmount = vRetailSum - vTran.Sum;
						vDiscountPercent = Round(vDiscountAmount * 100 / vRetailSum, 0);
						If vDiscountPercent >= 1 Then
							mDescription = mDescription + " - " + 
							cmNStr("en='Discount '; ru='Скидка '; de='Rabatt '; lv='Atlaide '", pLanguage) + 
							cmFormatSum(vDiscountAmount, pFolio.FolioCurrency) + 
							" (" + vDiscountPercent + "%)";
						EndIf;
					EndIf;
				EndIf;
				If vTran.Quantity <> 0 Then
					mQuantity = vServiceObj.pmGetServiceQuantityPresentation(vTran.Quantity, pLanguage);
				EndIf;
			EndIf;
			vTotalSum = vTotalSum + vTran.Sum;
			vTotalVATSum = vTotalVATSum + cmCalculateVATSum(vTran.VATRate, vTran.Sum, vTran.Period);
			
			If StrFind(vParameter, "DO_NOT_SHOW_CHARGE_REMARKS") > 0 Then
				vTran.Remarks = "";
			EndIf;
		EndIf;
		If Not IsBlankString(vTran.Remarks) Then
			mDescription = mDescription + " - " + cmNStr(vTran.Remarks, pLanguage);
		EndIf;
		If (IsBlankString(pGroupBy) Or pGroupBy = "ExternalClient") And ValueIsFilled(vTran.Document) Then
			If vTran.RecordType = AccumulationRecordType.Receipt Then
				If TypeOf(vTran.Document) = Type("DocumentRef.Charge") Then
					If Not IsBlankString(vTran.Document.Details) Then
						mDescription = mDescription + ?(IsBlankString(mDescription), "", Chars.LF) + 
						TrimAll(vTran.Document.Details);
					EndIf;
					// Try to find order for this charge
					vOrder = Documents.Order.GetOrderByCharge(vTran.Document);
					If ValueIsFilled(vOrder) And vOrder.Items.Count() > 0 Then
						vItems = "";
						For Each vOrderItemsRow In vOrder.Items Do
							vItems = vItems + ?(IsBlankString(vItems), "", Chars.LF) + 
							TrimAll(vOrderItemsRow.Item) + " - " + 
							cmFormatSum(vOrderItemsRow.Price, vOrder.Currency, "NZ=", , True) + 
							" x " + vOrderItemsRow.Quantity + " = " + 
							cmFormatSum(vOrderItemsRow.Sum, vOrder.Currency, "NZ=");
						EndDo;
						mDescription = mDescription + ?(IsBlankString(mDescription), "", Chars.LF) + 
						TrimAll(vItems);
					EndIf;
				EndIf;
			Else
				If (TypeOf(vTran.Document) = Type("DocumentRef.Payment") Or 
					TypeOf(vTran.Document) = Type("DocumentRef.Preauthorisation") Or 
					TypeOf(vTran.Document) = Type("DocumentRef.Return")) And 
					Not IsBlankString(vTran.Document.SlipText) Then
					mDescription = mDescription + Chars.LF + TrimAll(vTran.Document.SlipText);
				EndIf;
			EndIf;
		EndIf;
		// Set parameters
		If pGroupBy <> "InPrice" And pGroupBy <> "All" And pGroupBy <> "ByService" Then
			Try
				vRow.Parameters.mAccountingDate = mAccountingDate;
			Except
			EndTry;
		EndIf;
		mPrice = ?(vTran.Quantity <> 0, Round(vTran.Sum/vTran.Quantity, 2), vTran.Price);
		vRow.Parameters.mPrice = Format(mPrice, "ND=17; NFD=2");
		vRow.Parameters.mQuantity = mQuantity;
		vRow.Parameters.mDescription = mDescription;
		vRow.Parameters.mPaymentSum = Format(mPaymentSum, "ND=17; NFD=2");
		vRow.Parameters.mSum = Format(mSum, "ND=17; NFD=2");
		// Put row
		If (Not IsBlankString(mSum) Or Not IsBlankString(mPaymentSum)) And vPrintThisTransaction Then
			pSpreadsheet.Put(vRow);
		EndIf;
	EndDo;
	
	// VAT totals
	vVATRateTransactions = New ValueTable();
	If (vTotalSum - vTotalPaymentSum) = 0 And vTotalPaymentSum <> 0 And Not vCompany.PrintVATInFolioByCharges Then
		vTotalVATSum = vTotalPaymentVATSum;
		If Not vIgnoreVATRate Then
			vVATRateTransactions = vVATRatePaymentTransactions;
		EndIf;
	ElsIf vIgnoreVATRate Then
		vVATRateTransactions = vTransactionsCopy.Copy();
	Else
		vVATRateTransactions = vTransactions.Copy();
	EndIf;
	vVATRateTransactions.GroupBy("VATRate, RecordType", "Sum, VATSum");
	vVATRateTransactions.Sort("VATRate");
	If StrFind(vParameter, "CALCULATE_VAT_AMOUNT_BY_VAT_RATE_TOTALS") > 0 Then
		vTotalVATSum = 0;
		For Each vVATRate In vVATRateTransactions Do
			If vVATRate.RecordType = AccumulationRecordType.Receipt Then
				vTotalVATSum = vTotalVATSum + cmCalculateVATSum(vVATRate.VATRate, vVATRate.Sum, vMinAccDate);
			EndIf;
		EndDo;
	EndIf;
	
	// Footer
	vFooterTotals = vTemplate.GetArea("FooterTotals");
	vFooter = vTemplate.GetArea("Footer");
	
	// Fill parameters
	mTotalSum = Format(vTotalSum, "ND=17; NFD=2; NZ=") + " " + mFolioCurrency;
	If ValueIsFilled(vCompany) And vCompany.DoNotPrintVAT Then
		mTotalVATSum = "";
	Else
		If vTotalVATSum <> 0 Or vTotalPaymentVATSum <> 0 Then
			mTotalVATSum = cmNStr("en='Including VAT ';ru='В том числе НДС ';de='Darunter MwSt. '", pLanguage) + Format(vTotalVATSum, "ND=17; NFD=2") + " " + mFolioCurrency;
		Else
			mTotalVATSum = cmNStr("en='No VAT';ru='НДС не облагается';de='MwSt. wird nicht berechnet'", pLanguage); 
			If vVATRateTransactions.Count() > 0 Then 
				For Each vRowVatRate In vVATRateTransactions Do
					vVATRate = vRowVatRate.VATRate;
					If ValueIsFilled(vVATRate) And Not vVATRate.NoVAT And vVATRate.TaxRate = 0 Then
						mTotalVATSum = cmNStr("EN='Including VAT ';RU='НДС ';de='Darunter MwSt. '", pLanguage) + Format(vTotalVATSum, "ND=17; NFD=2; NZ=0.00") + " " + mFolioCurrency;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	mTotalPaymentSum = Format(vTotalPaymentSum, "ND=17; NFD=2; NZ=") + " " + mFolioCurrency;
	mBalance = Format(vTotalSum - vTotalPaymentSum, "ND=17; NFD=2; NZ=") + " " + mFolioCurrency;
	mTotalSumInWords = cmSumInWords(vTotalSum, pFolio.FolioCurrency, pLanguage);
	mEmployee = SessionParameters.CurrentUser.GetObject().pmGetEmployeeDescription(pLanguage);
	mEmployeePosition = cmNStr("en='Manager';ru='Администратор';de='Manager'", pLanguage);
	If Not IsBlankString(SessionParameters.CurrentUser.Position) Then
		mEmployeePosition = cmNStr(TrimAll(SessionParameters.CurrentUser.Position), pLanguage);
	EndIf;
	mClosed = ?(pFolio.IsClosed, cmNStr("en=' closed';ru=' закрыт';de=' geschlossen'", pLanguage), "");
	
	// Damaged property list
	mDamagedProperty = "";
	If pGroupBy = "PropertyDamage" Then
		For Each vTran In vTransactions Do
			If vTran.RecordType = AccumulationRecordType.Receipt Then
				If Not IsBlankString(vTran.Remarks) Then
					vRemarks = TrimAll(vTran.Remarks);
					If IsBlankString(mDamagedProperty) Then
						mDamagedProperty = vRemarks;
					Else
						mDamagedProperty = mDamagedProperty + ", " + vRemarks;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	// Set footer totals parameters
	vFooterTotals.Parameters.mTotalSum = mTotalSum;
	vFooterTotals.Parameters.mTotalPaymentSum = mTotalPaymentSum;
	If pGroupBy <> "PropertyDamage" Then
		vFooterTotals.Parameters.mBalance = mBalance;
		vFooterTotals.Parameters.mClosed = mClosed;
	Else
		vFooterTotals.Parameters.mClient = mClient;
	EndIf;
	If pGroupBy <> "PropertyDamage" And pLanguage <> Catalogs.Languages.DE Then
		vFooterTotals.Parameters.mTotalVATSum = mTotalVATSum;
	EndIf;
	If pLanguage <> Catalogs.Languages.DE Then
		vFooterTotals.Parameters.mTotalSumInWords = mTotalSumInWords;
	EndIf;
	// Put footer totals
	pSpreadsheet.Put(vFooterTotals);
	
	// Put VAT footers
	If ValueIsFilled(vCompany) And Not vCompany.IsUsingSimpleTaxSystem Then
		vVATHeader = vTemplate.GetArea("VATHeader");
		vVATHeader.Parameters.mFolioCurrency = mFolioCurrency;
		pSpreadsheet.Put(vVATHeader);
		// VAT percents
		vVATRateRow = vTemplate.GetArea("VATRateRow");
		For Each vVATRate In vVATRateTransactions Do
			If vVATRate.RecordType = AccumulationRecordType.Receipt Then
				vVATRateVATSum = vVATRate.VATSum;
				If StrFind(vParameter, "CALCULATE_VAT_AMOUNT_BY_VAT_RATE_TOTALS") > 0 Then
					vVATRateVATSum = cmCalculateVATSum(vVATRate.VATRate, vVATRate.Sum, vMinAccDate);
				EndIf;
				
				vVATRateRow.Parameters.mVATRate = TrimAll(vVATRate.VATRate);
				vVATRateRow.Parameters.mSumWithoutVAT = Format(vVATRate.Sum - vVATRateVATSum, "ND=17; NFD=2; NZ=");
				vVATRateRow.Parameters.mVATSum = Format(vVATRateVATSum, "ND=17; NFD=2; NZ=");
				vVATRateRow.Parameters.mSumWithVAT = Format(vVATRate.Sum, "ND=17; NFD=2; NZ=");
				pSpreadsheet.Put(vVATRateRow);
			EndIf;
		EndDo;
	EndIf;
	
	// Put footer signatures
	If StrFind(vParameter, "NO_MANAGER_IN_FOOTER") > 0 Then
		mEmployee = "";
		mEmployeePosition = "";
	EndIf;
	vFooter.Parameters.mEmployee = mEmployee;
	If pGroupBy = "PropertyDamage" Then
		vFooter.Parameters.mDamagedProperty = mDamagedProperty;
	Else
		Try
			vFooter.Parameters.mEmployeePosition = mEmployeePosition;
		Except
		EndTry;
		If pFolio.Hotel.PrintClientSignatureOnFolio Then
			vFooter.Parameters.mGuestSignature = cmNStr("en='Client signature ______________________';ru='Подпись клиента ______________________';de='Unterschrift des Kunden ______________________'", pLanguage);
		Else
			vFooter.Parameters.mGuestSignature = "";
		EndIf;
		vFooter.Parameters.mFormText = "";
		// Print bonuses if any      
		If StrFind(vParameter, "SHOW_BONUSES_BALANCE") > 0 Then
			vFooter.Parameters.mFormText = FillBonuses(pFolio, pLanguage);  
		EndIf;
		// Fill form text
		vFooter.Parameters.mFormText = vFooter.Parameters.mFormText + ?(IsBlankString(vFooter.Parameters.mFormText), "", Chars.LF) + TrimR(pObjectPrintForm.FormText);
	EndIf;
	// Put footer
	pSpreadsheet.Put(vFooter);
	
	// Setup default attributes with black and white print mode
	cmSetDefaultPrintFormSettings(pSpreadsheet, PageOrientation.Portrait, True, , True);
	// Check authorities
	cmSetSpreadsheetProtection(pSpreadsheet);
	// Get and fill workstation print form settings
	If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
		vWorkstationPrintSettings = SessionParameters.CurrentWorkstation.WorkstationPrintSettings;
		If ValueIsFilled(vWorkstationPrintSettings) Then
			// Try to find records for the current object print form
			vFilter = New Structure("ObjectPrintingForm, IsActive", pObjectPrintForm, True); 
			vPrintSettingsSet = vWorkstationPrintSettings.PrintFormsList.FindRows(vFilter);
			If vPrintSettingsSet.Count() > 0 Then
				For Each vPrintSettings In vPrintSettingsSet Do
					// Fill settings
					cmSetSpreadsheetSettings(pSpreadsheet, vPrintSettings);
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PrintFolio

// -----------------------------------------------------------------------------
Procedure PrintFolioByClients(pFolio, pFoliosList, pGroupBy, pLanguage, pObjectPrintForm, pTransactions, pSpreadsheet=Undefined, rMessage = "", pServicesToMerge = Undefined) Export
	// Basic checks
	vHotel = pFolio.Hotel;
	If Not ValueIsFilled(pFolio.Hotel) Then
		vHotel = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(vHotel) Then
		rMessage = NStr("ru='Не задана текущая гостиница!';de='Das aktuelle Hotel ist nicht angegeben!';en='Default hotel should be selected!'");
		Return;
	EndIf;
	vCompany = pFolio.Company;
	If Not ValueIsFilled(pFolio.Company) Then
		vCompany = vHotel.Company;
	EndIf;
	If Not ValueIsFilled(vCompany) Then
		rMessage = NStr("ru='У гостиницы должна быть указана фирма по умолчанию!';de='Beim Hotel muss standardmäßig eine Firma festgelegt sein!';en='Default hotel company should be selected!'");
		Return;
	EndIf;
	If Not ValueIsFilled(pLanguage) Then
		pLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	
	// Choose template
	If Not ValueIsFilled(pFolio) Then
		Return;
	EndIf;
	vFolioObj = pFolio.GetObject();
	
	pSpreadsheet = ?(pSpreadsheet = Undefined, New SpreadsheetDocument, pSpreadsheet);
	pSpreadsheet.Clear();
	If ValueIsFilled(pLanguage) Then
		If pLanguage = Catalogs.Languages.EN Then
			vTemplate = vFolioObj.GetTemplate("FolioClientListEn");
		ElsIf pLanguage = Catalogs.Languages.RU Then
			vTemplate = vFolioObj.GetTemplate("FolioClientListRu");
		ElsIf pLanguage = Catalogs.Languages.DE Then
			vTemplate = vFolioObj.GetTemplate("FolioClientListDe");
		Else
			rMessage = StrTemplate(NStr("ru='Не найден шаблон печатной формы лицевого счета для языка %1!'; 
			|de='No folio print form template found for the %1 language!'; 
			|en='No folio print form template found for the %1 language!'"), pLanguage.Code);
			Return;
		EndIf;
	Else
		vTemplate = vFolioObj.GetTemplate("FolioClientListRu");
	EndIf;
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(pObjectPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;
	
	// Read parameter value
	vParameter = Upper(TrimAll(pObjectPrintForm.Parameter));
	vIgnoreVATRate = (StrFind(vParameter, "IGNORE_VATRATE_ON_GROUPING") > 0);
	
	// Load pictures
	vLogoIsSet = False;
	vLogo = New Picture;
	If ValueIsFilled(pFolio.Hotel) Then
		If pFolio.Hotel.Logo <> Undefined Then
			vLogo = pFolio.Hotel.Logo.Get();
			If vLogo = Undefined Then
				vLogo = New Picture;
			Else
				vLogoIsSet = True;
			EndIf;
		EndIf;
	EndIf;
	
	// 3G Headers
	If pLanguage = Catalogs.Languages.RU Then
		If vHotel.PrintGHeaders Then
			vGHeader = vTemplate.GetArea("H3G");
			pSpreadsheet.Put(vGHeader);
		EndIf;
	EndIf;
	
	// Build header structure
	vHeaderStruct = New Structure("mHotelPrintName, mHotelPostAddressPresentation, mHotelPhones, mCompanyLegacyName, mCompanyTIN", "", "", "", "", "");
	
	// Header
	vHeader = vTemplate.GetArea("Header");
	// Hotel
	vHeaderStruct.mHotelPrintName = Catalogs.Hotels.pmGetHotelPrintName(vHotel, pLanguage);
	vHeaderStruct.mHotelPostAddressPresentation = Catalogs.Hotels.pmGetHotelPostAddressPresentation(vHotel, pLanguage);
	vHotelPhones = TrimAll(vHotel.Phones);
	vHotelFax = TrimAll(vHotel.Fax);
	vHeaderStruct.mHotelPhones = vHotelPhones + ?(IsBlankString(vHotelFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", pLanguage) + vHotelFax);
	// Company
	vHeaderStruct.mCompanyLegacyName = TrimAll(vCompany.GetObject().pmGetCompanyPrintName(pLanguage));
	vCompanyTIN = TrimAll(vCompany.TIN);
	vCompanyKPP = TrimAll(vCompany.KPP);
	vHeaderStruct.mCompanyTIN = ?(IsBlankString(vCompanyTIN), "", cmNStr("EN='TIN ';RU='ИНН/КПП ';de='TIN '", pLanguage) + vCompanyTIN) + ?(IsBlankString(vCompanyKPP), "", "/" + vCompanyKPP);
	If vHeaderStruct.mCompanyLegacyName = vHeaderStruct.mHotelPrintName Then
		vHeaderStruct.mCompanyLegacyName = vHeaderStruct.mCompanyTIN;
		vHeaderStruct.mCompanyTIN = "";
	EndIf;
	// Folio date and number
	If ValueIsFilled(vHotel) And vHotel.DoNotPrintFolioNumberInFolioPrintForms And Not pFolio.IsClosed Then
		mFolioNumber = cmNStr("en='PROFORMA'; ru='ПРЕЧЕК'; de='PROFORMA'", pLanguage);
	Else
		mFolioNumber = cmNStr("en='FOLIO N'; ru='СЧЕТ №'; de='FOLIO Nr.'", pLanguage) + cmGetDocumentNumberPresentation(pFolio.Number);
	EndIf;
	// Client
	mClient = "";
	mCitizenship = "";
	If ValueIsFilled(pFolio.Client) Then
		vClient = pFolio.Client;
		mClient = TrimAll(TrimAll(vClient.LastName) + " " + TrimAll(vClient.FirstName) + " " + TrimAll(vClient.SecondName));
		If ValueIsFilled(pFolio.Client.Citizenship) Then
			mCitizenship = pFolio.Client.Citizenship.GetObject().pmGetCountryDescription(pLanguage);
		EndIf;
	EndIf;
	// Customer
	mCustomerLegacyName = "";
	If ValueIsFilled(pFolio.Customer) And ValueIsFilled(pFolio.Hotel) And 
		pFolio.Hotel.IndividualsCustomer <> pFolio.Customer Then
		mCustomerLegacyName = TrimAll(pFolio.Customer.LegacyName);
		If IsBlankString(mCustomerLegacyName) Then
			mCustomerLegacyName = TrimAll(pFolio.Customer.Description);
		EndIf;
		vAddress = "";
		If Not IsBlankString(pFolio.Customer.LegacyAddress) Then
			vAddress = TrimAll(pFolio.Customer.LegacyAddress);
		ElsIf Not IsBlankString(pFolio.Customer.PostAddress) Then
			vAddress = TrimAll(pFolio.Customer.PostAddress);
		EndIf;
		vAddress = cmGetAddressPresentation(vAddress);
		mCustomerLegacyName = mCustomerLegacyName + Chars.LF + vAddress;
	ElsIf ValueIsFilled(pFolio.Client) And Not IsBlankString(pFolio.Client.FolioCustomerPresentation) Then
		mCustomerLegacyName = TrimAll(pFolio.Client.FolioCustomerPresentation);
	ElsIf ValueIsFilled(pFolio.ParentDoc) And ValueIsFilled(pFolio.ParentDoc.Customer) And ValueIsFilled(pFolio.Hotel) And 
		pFolio.Hotel.IndividualsCustomer <> pFolio.ParentDoc.Customer Then
		mCustomerLegacyName = TrimAll(pFolio.ParentDoc.Customer.LegacyName);
		If IsBlankString(mCustomerLegacyName) Then
			mCustomerLegacyName = TrimAll(pFolio.ParentDoc.Customer.Description);
		EndIf;
		vAddress = "";
		If Not IsBlankString(pFolio.ParentDoc.Customer.LegacyAddress) Then
			vAddress = TrimAll(pFolio.ParentDoc.Customer.LegacyAddress);
		ElsIf Not IsBlankString(pFolio.ParentDoc.Customer.PostAddress) Then
			vAddress = TrimAll(pFolio.ParentDoc.Customer.PostAddress);
		EndIf;
		vAddress = cmGetAddressPresentation(vAddress);
		mCustomerLegacyName = mCustomerLegacyName + Chars.LF + vAddress;
	EndIf;
	If Not IsBlankString(vParameter) Then
		If Find(Upper(vParameter), "FOLIO_CUSTOMER") > 0 And Not ValueIsFilled(pFolio.Customer) Then
			mCustomerLegacyName = "";
		EndIf;
	EndIf;
	If IsBlankString(mCustomerLegacyName) Then
		If ValueIsFilled(pFolio.Client) Then
			vAddress = "";
			If Not IsBlankString(pFolio.Client.Address) Then
				vAddress = cmGetAddressPresentation(pFolio.Client.Address);
				If Not IsBlankString(vAddress) And Find(vAddress, Chars.LF) > 0 Then
					mClient = mClient + Chars.LF + vAddress;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	// Contract
	mContractDescription = "";
	If ValueIsFilled(pFolio.Contract) Then
		mContractDescription = TrimAll(pFolio.Contract.Description);
	EndIf;
	// Currency
	mFolioCurrency = "";
	If ValueIsFilled(pFolio.FolioCurrency) Then
		vCurrencyObj = pFolio.FolioCurrency.GetObject();
		mFolioCurrency = vCurrencyObj.pmGetCurrencyDescription(pLanguage);
	EndIf;
	// Room and room type
	mRoom = TrimAll(pFolio.Room);
	mRoomType = "";
	If ValueIsFilled(pFolio.Room) Then
		If ValueIsFilled(pFolio.Room.RoomType) Then
			vRoomTypeToPrint = pFolio.Room.RoomType;
			vCurDoc = pFolio.ParentDoc;
			If ValueIsFilled(vCurDoc) And (TypeOf(vCurDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vCurDoc) = Type("DocumentRef.Reservation")) Then
				If ValueIsFilled(vRoomTypeToPrint) And ValueIsFilled(vCurDoc.RoomTypeUpgrade) And vCurDoc.RoomTypeUpgrade.BaseRoomType = vRoomTypeToPrint Then
					vRoomTypeToPrint = vCurDoc.RoomTypeUpgrade;
				EndIf;
			EndIf;
			vRoomTypeObj = vRoomTypeToPrint.GetObject();
			mRoomType = vRoomTypeObj.pmGetRoomTypeDescription(pLanguage);
		EndIf;
	EndIf;
	// Check in and check out dates
	mCheckInDate = Format(pFolio.DateTimeFrom, "DF='dd.MM.yy HH:mm'");
	mCheckOutDate = Format(pFolio.DateTimeTo, "DF='dd.MM.yy HH:mm'");
	// Check if transactions are selected
	vMinAccDate = '39991231';
	vMaxAccDate = '00010101';
	If pTransactions.Count() > 0 Then
		For Each vTrnRow In pTransactions Do
			If TypeOf(vTrnRow.Document) = Type("DocumentRef.Charge") Then
				vService = vTrnRow.Service;
				vAccountingDate = vTrnRow.AccountingDate;
				If ValueIsFilled(vService) And ValueIsFilled(vService.QuantityCalculationRule) Then
					vAccountingDateMove = cmGetAccountingDateMove(vService.QuantityCalculationRule, False, ?(ValueIsFilled(pFolio.ParentDoc), pFolio.ParentDoc, pFolio));
					If vAccountingDateMove < 0 Then
						vAccountingDate = vTrnRow.AccountingDate - 24*3600;
					EndIf;
				EndIf;
				vMinAccDate = Min(vMinAccDate, vAccountingDate);
				vMaxAccDate = Max(vMaxAccDate, vAccountingDate);
			EndIf;
		EndDo;
		If vMinAccDate <> '39991231' And vMaxAccDate <> '00010101' Then
			mCheckInDate = Format(vMinAccDate, "DF='dd.MM.yy'");
			mCheckOutDate = Format(vMaxAccDate + 24*3600, "DF='dd.MM.yy'");
		EndIf;
	EndIf;
	// Guest group
	mGuestGroup = TrimAll(pFolio.GuestGroup);
	vHotelPrefix = Catalogs.Hotels.pmGetPrefix(pFolio.Hotel);
	If Not IsBlankString(vHotelPrefix) And pFolio.Hotel.ShowHotelPrefixBeforeGroupCode Then
		mGuestGroup = vHotelPrefix + mGuestGroup;
	EndIf;
	// Room rate
	mRoomRate = "";
	If ValueIsFilled(pFolio.ParentDoc) And 
		(TypeOf(pFolio.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(pFolio.ParentDoc) = Type("DocumentRef.Reservation")) Then
		If ValueIsFilled(pFolio.ParentDoc.RoomRate) Then
			mRoomRate = TrimAll(pFolio.ParentDoc.RoomRate.GetObject().pmGetRoomRateDescription(pLanguage));
		EndIf;
	EndIf;
	// Set parameters and put report section
	FillPropertyValues(vHeader.Parameters, vHeaderStruct);
	
	vHeader.Parameters.mFolioNumber = mFolioNumber;
	vHeader.Parameters.mClient = mClient;
	vHeader.Parameters.mCustomerLegacyName = mCustomerLegacyName;
	If pLanguage <> Catalogs.Languages.DE Then
		vHeader.Parameters.mFolioCurrency = mFolioCurrency;
		vHeader.Parameters.mCitizenship = mCitizenship;
	EndIf;
	vHeader.Parameters.mRoom = mRoom;
	vHeader.Parameters.mRoomType = mRoomType;
	vHeader.Parameters.mCheckInDate = mCheckInDate;
	vHeader.Parameters.mCheckOutDate = mCheckOutDate;
	vHeader.Parameters.mGuestGroup = mGuestGroup;
	vHeader.Parameters.mRoomRate = mRoomRate;
	// Logo
	If vLogoIsSet Then
		vHeader.Drawings.Logo.Print = True;
		vHeader.Drawings.Logo.Picture = vLogo;
	Else
		vHeader.Drawings.Delete(vHeader.Drawings.Logo);
	EndIf;
	// Put header
	pSpreadsheet.Put(vHeader);
	
	// Get row template area
	vGuest = vTemplate.GetArea("Guest");
	vRow = vTemplate.GetArea("Row");
	
	// Payment VAT amounts
	vVATRatePaymentTransactions = New ValueTable();
	vVATRatePaymentTransactions.Columns.Add("VATRate", cmGetCatalogTypeDescription("VATRates"));
	vVATRatePaymentTransactions.Columns.Add("RecordType");
	vVATRatePaymentTransactions.Columns.Add("Sum", cmGetSumTypeDescription());
	vVATRatePaymentTransactions.Columns.Add("VATSum", cmGetSumTypeDescription());
	
	// Get all folio transactions
	If pTransactions.Count() = 0 Then
		vTransactions = pFolio.GetObject().pmGetAllFolioTransactions();
		For Each vTransactionsRow In vTransactions Do
			If vTransactionsRow.RecordType = AccumulationRecordType.Receipt Then
				vTransactionsRowService = vTransactionsRow.Service;
				If ValueIsFilled(vTransactionsRowService) And ValueIsFilled(vTransactionsRowService.QuantityCalculationRule) Then
					vAccountingDateMove = cmGetAccountingDateMove(vTransactionsRowService.QuantityCalculationRule, False, ?(ValueIsFilled(pFolio.ParentDoc), pFolio.ParentDoc, pFolio));
					If vAccountingDateMove > 0 Then
						vTransactionsRow.ServiceDate = vTransactionsRow.ServiceDate - (24*3600);
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	Else
		vTransactions = pTransactions;
		If vTransactions.Columns.Find("ServiceDate") = Undefined Then
			vTransactions.Columns.Add("ServiceDate", cmGetDateTimeTypeDescription());
			For Each vTransactionsRow In vTransactions Do
				If vTransactionsRow.RecordType = AccumulationRecordType.Receipt And ValueIsFilled(vTransactionsRow.Charge) Then
					vTransactionsRow.ServiceDate = vTransactionsRow.Charge.ServiceDate;
					vTransactionsRowService = vTransactionsRow.Service;
					If ValueIsFilled(vTransactionsRowService) And ValueIsFilled(vTransactionsRowService.QuantityCalculationRule) Then
						vAccountingDateMove = cmGetAccountingDateMove(vTransactionsRowService.QuantityCalculationRule, False, ?(ValueIsFilled(pFolio.ParentDoc), pFolio.ParentDoc, pFolio));
						If vAccountingDateMove > 0 Then
							vTransactionsRow.ServiceDate = vTransactionsRow.ServiceDate - (24*3600);
						EndIf;
					EndIf;
				Else
					vTransactionsRow.ServiceDate = vTransactionsRow.Period;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	cmRemoveTransactionsWithStorno(vTransactions);
	If pFoliosList.Count() > 1 Then
		For Each vFoliosItem In pFoliosList Do
			If vFoliosItem.Value <> pFolio Then
				vFolioTransactions = vFoliosItem.Value.GetObject().pmGetAllFolioTransactions();
				For Each vFolioTransactionsRow In vFolioTransactions Do
					vTransactionsRow = vTransactions.Add();
					FillPropertyValues(vTransactionsRow, vFolioTransactionsRow);
				EndDo;
			EndIf;
		EndDo;
		vTransactions.Sort("Period");
	EndIf;
	
	// Join payment sections if cash register has "Do not print payment sections" flag turned on
	vDoGroupBy = False;
	For Each vTranRow In vTransactions Do
		If vTranRow.PaymentSum <> 0 Then
			If TypeOf(vTranRow.Document) = Type("DocumentRef.Payment") Or TypeOf(vTranRow.Document) = Type("DocumentRef.CustomerPayment") Or TypeOf(vTranRow.Document) = Type("DocumentRef.Return") Then
				If ValueIsFilled(vTranRow.Folio) And ValueIsFilled(vTranRow.Folio.Company) And ValueIsFilled(vTranRow.Folio.Company.VATRate) And 
					ValueIsFilled(vTranRow.Document.CashRegister) And vTranRow.Document.CashRegister.DoNotPrintPaymentSections Then
					vDoGroupBy = True;
					vTranRow.PaymentSection = Catalogs.PaymentSections.EmptyRef();
					vTranRow.VATRate = vTranRow.Folio.Company.VATRate;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	If vDoGroupBy Then 
		vTransactions.GroupBy("Document, Charge, RecordType, Folio, FolioParentDoc, ChargeParentDoc, FolioClient, PaymentSection, Service, Price, Period, Remarks, ServiceDate, PaymentMethod, RecorderNumber, Payer, IsRoomRevenue, IsInPrice, CalendarDayType, Room, VATRate, Performer", "Sum, VATSum, Quantity, Limit, PaymentSum");
	EndIf;
	
	// Change accounting dates for breakfast
	If Not IsBlankString(pGroupBy) And pGroupBy <> "ByService" And pGroupBy <> "PropertyDamage" And pGroupBy <> "ExternalClient" Then
		For Each vTranRow In vTransactions Do
			If vTranRow.IsInPrice And ValueIsFilled(vTranRow.Service.QuantityCalculationRule) Then
				vAccountingDateMove = cmGetAccountingDateMove(vTranRow.Service.QuantityCalculationRule, False, ?(ValueIsFilled(pFolio.ParentDoc), pFolio.ParentDoc, pFolio));
				If vAccountingDateMove < 0 Then
					vTranRow.Period = vTranRow.Period - 24*3600;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	// Join services according to service parameters
	If Not IsBlankString(pGroupBy) And pGroupBy <> "ByService" And pGroupBy <> "PropertyDamage" And pGroupBy <> "ExternalClient" Then
		// Try to replace accommodation service to the one that should be used for printing
		vChargeParentDoc = Undefined;
		vAccountingDate = '00010101';
		vFirstRoomRateService = Undefined;
		vFirstRoomRateServiceIsFound = False;
		For Each vTranRow In vTransactions Do
			vTranRowService = vTranRow.Service;
			If ValueIsFilled(vTranRowService) Then
				If vChargeParentDoc <> vTranRow.ChargeParentDoc Then
					vChargeParentDoc = vTranRow.ChargeParentDoc;
					vAccountingDate = '00010101';
					vFirstRoomRateService = Undefined;
					vFirstRoomRateServiceIsFound = False;
				EndIf;
				If vAccountingDate <> BegOfDay(vTranRow.Period) Then
					vAccountingDate = BegOfDay(vTranRow.Period);
					vFirstRoomRateService = Undefined;
					vFirstRoomRateServiceIsFound = False;
				EndIf;
				If vTranRowService.IsRoomRevenue And vTranRowService.IsInPrice And Not vTranRowService.RoomRevenueAmountsOnly Then
					If ValueIsFilled(vTranRowService.HideIntoServiceOnPrint) Then
						vTranRow.Service = vTranRowService.HideIntoServiceOnPrint;
					EndIf;
					If Not vFirstRoomRateServiceIsFound Then
						vFirstRoomRateService = vTranRowService;
						vFirstRoomRateServiceIsFound = True;
					Else
						If vFirstRoomRateService <> vTranRowService And ValueIsFilled(vTranRowService.HideIntoServiceOnPrint) Then
							vTranRow.Quantity = 0;
						EndIf;
					EndIf;
				ElsIf vTranRowService.DoNotGroupIntoRoomRateOnPrint And ValueIsFilled(vTranRowService.HideIntoServiceOnPrint) Then
					vTranRow.Service = vTranRowService.HideIntoServiceOnPrint;
				EndIf;
			EndIf;
		EndDo;
		// Try to merge other services to the accommodation service
		vFirstReplacedService = Undefined;
		vCurAccountingDate = '00010101';
		i = 0;
		While i < vTransactions.Count() Do
			vTranRow = vTransactions.Get(i);
			vTranRowService = vTranRow.Service;
			If BegOfDay(vTranRow.Period) <> vCurAccountingDate Then
				vCurAccountingDate = BegOfDay(vTranRow.Period);
				vFirstReplacedService = Undefined;
			EndIf;
			If ValueIsFilled(vTranRowService) And ValueIsFilled(vTranRowService.HideIntoServiceOnPrint) Then
				If Not vTranRowService.DoNotGroupIntoRoomRateOnPrint Then
					// Try to find service to hide current one to
					vHideToServices = vTransactions.FindRows(New Structure("Service, Period, Folio", vTranRowService.HideIntoServiceOnPrint, BegOfDay(vTranRow.Period), vTranRow.Folio));
					If vHideToServices.Count() = 0 And BegOfDay(vTranRow.Period) >= BegOfDay(vTranRow.Folio.DateTimeTo) Then
						// Try to find service for the previous date
						vHideToServices = vTransactions.FindRows(New Structure("Service, Period, Folio", vTranRowService.HideIntoServiceOnPrint, BegOfDay(vTranRow.Period) - 24*3600, vTranRow.Folio));
					EndIf;
					If vHideToServices.Count() > 0 Then
						vSrv2Hide2 = vHideToServices.Get(0);
						vSrv2Hide2.Sum = vSrv2Hide2.Sum + vTranRow.Sum;
						vSrv2Hide2.VATSum = vSrv2Hide2.VATSum + vTranRow.VATSum;
						vSrv2Hide2.Price = cmRecalculatePrice(vSrv2Hide2.Sum, vSrv2Hide2.Quantity);
						// Delete current service
						vTransactions.Delete(i);
						Continue;
					Else
						If Not ValueIsFilled(vFirstReplacedService) Then
							vFirstReplacedService = vTranRowService;
						Else
							If vTranRowService <> vFirstReplacedService Then
								vTranRow.Quantity = 0;
							EndIf;
						EndIf;
						vTranRow.Service = vTranRowService.HideIntoServiceOnPrint; 
					EndIf;
				EndIf;
			EndIf;
			i = i + 1;
		EndDo;
	EndIf;
	
	// Try to merge checked services to the accommodation service
	If pServicesToMerge.Count() <> 0 Then
		vFirstReplacedService = Undefined;
		vCurAccountingDate = '00010101';
		
		For Each vService In pServicesToMerge Do
			vTransactionsToMerge = vTransactions.FindRows(New Structure("Service", vService.Value));
			For Each vTranToMerge In vTransactionsToMerge Do
				vTranToMergeServ = vTranToMerge.Service;
				If BegOfDay(vTranToMerge.Period) <> vCurAccountingDate Then
					vCurAccountingDate = BegOfDay(vTranToMerge.Period);
					vFirstReplacedService = Undefined;
				EndIf;
				If ValueIsFilled(vTranToMergeServ) Then
					// Try to find service to hide current one to
					vHideToServices = vTransactions.FindRows(New Structure("IsRoomRevenue, IsInPrice, Period, Folio", True, True, BegOfDay(vTranToMerge.Period), vTranToMerge.Folio));
					If vHideToServices.Count() = 0 And BegOfDay(vTranToMerge.Period) >= BegOfDay(vTranToMerge.Folio.DateTimeTo) Then
						// Try to find service for the previous date
						vHideToServices = vTransactions.FindRows(New Structure("IsRoomRevenue, IsInPrice, Period, Folio", True, True, BegOfDay(vTranToMerge.Period) - 24*3600, vTranToMerge.Folio));
					EndIf;
					If vHideToServices.Count() > 0 Then
						vSrv2Hide2 = vHideToServices.Get(0);
						vSrv2Hide2.Sum = vSrv2Hide2.Sum + vTranToMerge.Sum;
						vTranToMerge.VATRate = vSrv2Hide2.VATRate;
						vTranToMerge.VATSum = cmCalculateVATSum(vTranToMerge.VATRate, vTranToMerge.Sum, vTranToMerge.AccountingDate);
						vSrv2Hide2.VATSum = vSrv2Hide2.VATSum + vTranToMerge.VATSum;
						vSrv2Hide2.Price = cmRecalculatePrice(vSrv2Hide2.Sum, vSrv2Hide2.Quantity);
						// Delete current service
						vTransactions.Delete(vTransactions.IndexOf(vTranToMerge));
						Continue;
					Else
						vAccomodationRows = vTransactions.FindRows(New Structure("IsRoomRevenue, IsInPrice, Folio", True, True, vTranToMerge.Folio));
						vFoliosAccomod = vAccomodationRows.Get(0);
						vTranToMerge.Service = vFoliosAccomod.Get(0).Service;
						vTranToMerge.VATRate = vFoliosAccomod.VATRate;
						vTranToMerge.VATSum = cmCalculateVATSum(vTranToMerge.VATRate, vTranToMerge.Sum, vTranToMerge.AccountingDate);
					EndIf;
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
	// Get accommodation service name
	vAccommodationService = Undefined;	
	vAccommodationServiceVATRate = Undefined;	
	i = 0;
	While i < vTransactions.Count() Do
		vTran = vTransactions.Get(i);
		If vTran.RecordType = AccumulationRecordType.Receipt Then
			If pGroupBy = "InPricePerFolioPerDay" Or pGroupBy = "InPricePerDay" Or
				pGroupBy = "AllPerFolioPerDay" Or pGroupBy = "AllPerDay" Or
				pGroupBy = "InPricePerFolio" Or pGroupBy = "InPrice" Or
				pGroupBy = "AllPerFolio" Or pGroupBy = "All" Then
				If vTran.Sum = 0 Then
					vTransactions.Delete(i);
					Continue;
				EndIf;
			EndIf;
			If vAccommodationService = Undefined Then
				If vTran.IsRoomRevenue And Not vTran.Service.RoomRevenueAmountsOnly Then
					vAccommodationService = vTran.Service;
					vAccommodationServiceVATRate = vTran.VATRate;
				EndIf;
			EndIf;
		EndIf;
		i = i + 1;
	EndDo;
	
	// Add and fill client, room, period, column from the charge/payment documents
	If vTransactions.Columns.Find("Client") = Undefined Then 
		vTransactions.Columns.Add("Client", cmGetCatalogTypeDescription("Clients"));
	EndIf;
	If vTransactions.Columns.Find("Resource") = Undefined Then 
		vTransactions.Columns.Add("Resource", cmGetCatalogTypeDescription("Resources"));
	EndIf;
	vTransactions.Columns.Add("CheckInDate", cmGetDateTimeTypeDescription());
	vTransactions.Columns.Add("CheckOutDate", cmGetDateTimeTypeDescription());
	vTransactions.Columns.Add("RoomType", cmGetCatalogTypeDescription("RoomTypes"));
	For Each vTran In vTransactions Do
		If ValueIsFilled(vTran.Document) And 
			TypeOf(vTran.Document) <> Type("DocumentRef.CloseOfPeriod") And 
			TypeOf(vTran.Document) <> Type("DocumentRef.CreditNote") And 
			TypeOf(vTran.Document) <> Type("DocumentRef.DebitNote") Then
			vParentDoc = vTran.Document.ParentDoc;
			If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Then
				vTran.Client = vParentDoc.Guest;
				vTran.RoomType = vParentDoc.RoomType;
				vTran.Room = vParentDoc.Room;
				vParentDocObj = vParentDoc.GetObject();
				vFirstAccInChain = vParentDocObj.pmGetFirstAccommodationInChain();
				If Not ValueIsFilled(vFirstAccInChain) Then
					vFirstAccInChain = vParentDoc;
				EndIf;
				vTran.CheckInDate = vFirstAccInChain.CheckInDate;
				vLastAccInChain = vParentDocObj.pmGetLastAccommodationInChain();
				If Not ValueIsFilled(vLastAccInChain) Then
					vLastAccInChain = vParentDoc;
				EndIf;
				vTran.CheckOutDate = vLastAccInChain.CheckOutDate;
			ElsIf TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Then
				vTran.Client = vParentDoc.Guest;
				vTran.RoomType = vParentDoc.RoomType;
				vTran.Room = vParentDoc.Room;
				vTran.CheckInDate = vParentDoc.CheckInDate;
				vTran.CheckOutDate = vParentDoc.CheckOutDate;
			ElsIf TypeOf(vParentDoc) = Type("DocumentRef.ResourceReservation") Then
				vTran.Client = vParentDoc.Client;
				vTran.Resource = vParentDoc.Resource;
				vTran.CheckInDate = vParentDoc.DateTimeFrom;
				vTran.CheckOutDate = vParentDoc.DateTimeTo;
			ElsIf TypeOf(vParentDoc) = Type("DocumentRef.Folio") Then
				vTran.Client = vParentDoc.Client;
				If ValueIsFilled(vParentDoc.Room) Then
					vTran.RoomType = vParentDoc.Room.RoomType;
				EndIf;
				vTran.Room = vParentDoc.Room;
				vTran.CheckInDate = vParentDoc.DateTimeFrom;
				vTran.CheckOutDate = vParentDoc.DateTimeTo;
			EndIf;
		EndIf;
	EndDo;
	
	// Group by transactions according to the folio print type
	vGroupByAccommodation = False;
	vTransactionsCopy = vTransactions.Copy();
	If Not IsBlankString(pGroupBy) Then
		If pGroupBy = "InPrice" Then
			vGroupByAccommodation = True;
			// Change transaction services
			For Each vTran In vTransactions Do
				// Reset "is in price" flag if necessary
				If ValueIsFilled(vTran.Service) And vTran.Service.DoNotGroupIntoRoomRateOnPrint Then
					vTran.IsInPrice = False;
				EndIf;
				If vTran.RecordType = AccumulationRecordType.Receipt Then
					vTran.Document = Undefined;
					vTran.Period = BegOfDay(pFolio.Date);
					vTran.ServiceDate = BegOfDay(pFolio.Date);
					vTran.PaymentMethod = Catalogs.PaymentMethods.EmptyRef();
					If Not vTran.IsRoomRevenue And vTran.IsInPrice Then
						If ValueIsFilled(vAccommodationService) And (vIgnoreVATRate Or Not vIgnoreVATRate And vAccommodationServiceVATRate = vTran.VATRate) Then
							vTran.Service = vAccommodationService;
							vTran.Quantity = 0;
							vTran.Price = 0;
							vTran.VATRate = ?(vIgnoreVATRate, vAccommodationServiceVATRate, vTran.VATRate);
						EndIf;
						vTran.Remarks = "";
					ElsIf vTran.IsRoomRevenue And vTran.IsInPrice Then
						// Reset quantity for services where amount should be added to room revenue only
						If vTran.Service.RoomRevenueAmountsOnly Then
							vTran.Quantity = 0;
							vTran.Price = 0;
						EndIf;
						// Reset service to accommodation service	
						If ValueIsFilled(vAccommodationService) And (vIgnoreVATRate Or Not vIgnoreVATRate And vAccommodationServiceVATRate = vTran.VATRate) Then
							vTran.Service = vAccommodationService;
							vTran.VATRate = ?(vIgnoreVATRate, vAccommodationServiceVATRate, vTran.VATRate);
						EndIf;
						vTran.Remarks = "";
					EndIf;
				EndIf;
			EndDo;
		ElsIf pGroupBy = "All" Then
			vGroupByAccommodation = True;
			// Change transaction services
			For Each vTran In vTransactions Do
				If vTran.RecordType = AccumulationRecordType.Receipt Then
					vTran.Document = Undefined;
					vTran.Period = BegOfDay(pFolio.Date);
					vTran.ServiceDate = BegOfDay(pFolio.Date);
					// Reset quantity for services where amount should be added to room revenue only
					If vTran.Service.RoomRevenueAmountsOnly Then
						vTran.Quantity = 0;
						vTran.Price = 0;
					EndIf;
					// Reset service to accommodation service	
					If ValueIsFilled(vAccommodationService) And (vIgnoreVATRate Or Not vIgnoreVATRate And vAccommodationServiceVATRate = vTran.VATRate) Then
						vTran.Service = vAccommodationService;
						vTran.VATRate = ?(vIgnoreVATRate, vAccommodationServiceVATRate, vTran.VATRate);
					EndIf;
					vTran.Remarks = "";
					vTran.PaymentMethod = Catalogs.PaymentMethods.EmptyRef();
					vTran.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
					If Not vTran.IsRoomRevenue Then
						vTran.Quantity = ?(ValueIsFilled(vAccommodationService), 0, vTran.Quantity);
						vTran.Price = 0;
					EndIf;
				EndIf;
			EndDo;
		ElsIf pGroupBy = "ByService" Then
			// Change transaction services
			For Each vTran In vTransactions Do
				If vTran.RecordType = AccumulationRecordType.Receipt Then
					vTran.Document = Undefined;
					vTran.Period = BegOfDay(pFolio.Date);
					vTran.ServiceDate = BegOfDay(pFolio.Date);
					vTran.Price = 0;
					vTran.Remarks = "";
					vTran.PaymentMethod = Catalogs.PaymentMethods.EmptyRef();
					vTran.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
				EndIf;
			EndDo;
		EndIf;
		// Group by transactions
		vTransactions.GroupBy("Period, ServiceDate, Document, RecordType, Service, PaymentMethod, CalendarDayType, Remarks, Client, CheckInDate, CheckOutDate, Room, RoomType, Resource, VATRate", "Sum, VATSum, Price, Quantity");
		// Recalculate price for all charges and delete zero sum rows
		i = 0;
		While i < vTransactions.Count() Do
			vTran = vTransactions.Get(i);
			If vTran.Sum = 0 And pGroupBy <> "ByService" Then
				vTransactions.Delete(i);
			Else
				If vTran.RecordType = AccumulationRecordType.Receipt Then
					If Not vIgnoreVATRate Then
						vTran.VATSum = cmCalculateVATSum(vTran.VATRate, vTran.Sum, vTran.Period);
					EndIf;
					vTran.Price = cmRecalculatePrice(vTran.Sum, vTran.Quantity);
				EndIf;
				i = i + 1;
			EndIf;
		EndDo;
	EndIf;
	If vTransactions.Count() > 0 Then
		vTransactions.Sort("Room, RoomType, CheckInDate, CheckOutDate, Client DESC, Resource, Period");
	EndIf;
	
	// Initialize totals
	vTotalSum = 0;
	vTotalPaymentSum = 0;
	vTotalVATSum = 0;
	vTotalPaymentVATSum = 0;
	// Initialize current client
	vCurClient = Catalogs.Clients.EmptyRef();
	vCurCheckInDate = '00010101';
	vCurCheckOutDate = '00010101';
	vCurRoomType = Catalogs.RoomTypes.EmptyRef();
	vCurRoom = Catalogs.Rooms.EmptyRef();
	vCurResource = Catalogs.Resources.EmptyRef();
	// Print transactions
	For Each vTran In vTransactions Do
		vPrintThisTransaction = True;
		vWrkClient = Catalogs.Clients.EmptyRef();
		If ValueIsFilled(vTran.Client) Then
			vWrkClient = vTran.Client;
		EndIf;
		vWrkCheckInDate = '00010101';
		If ValueIsFilled(vTran.CheckInDate) Then
			vWrkCheckInDate = vTran.CheckInDate;
		EndIf;
		vWrkCheckOutDate = '00010101';
		If ValueIsFilled(vTran.CheckOutDate) Then
			vWrkCheckOutDate = vTran.CheckOutDate;
		EndIf;
		vWrkRoomType = Catalogs.RoomTypes.EmptyRef();
		If ValueIsFilled(vTran.RoomType) Then
			vWrkRoomType = vTran.RoomType;
		EndIf;
		vWrkRoom = Catalogs.Rooms.EmptyRef();
		If ValueIsFilled(vTran.Room) Then
			vWrkRoom = vTran.Room;
		EndIf;
		vWrkResource = Catalogs.Resources.EmptyRef();
		If ValueIsFilled(vTran.Resource) Then
			vWrkResource = vTran.Resource;
		EndIf;
		
		// Check should we print client header
		If vWrkClient <> vCurClient Or 
			vWrkCheckInDate <> vCurCheckInDate Or 
			vWrkCheckOutDate <> vCurCheckOutDate Or
			vWrkRoom <> vCurRoom Or
			vWrkRoomType <> vCurRoomType Or
			vWrkResource <> vCurResource Then
			// Fill working variables
			vCurClient = vWrkClient;
			vCurCheckInDate = vWrkCheckInDate;
			vCurCheckOutDate = vWrkCheckOutDate;
			vCurRoomType = vWrkRoomType;
			vCurRoom = vWrkRoom;
			vCurResource = vWrkResource;
			// Build cient description
			mGuest = "";
			If ValueIsFilled(vCurClient) Then
				mGuest = TrimAll(vCurClient.FullName);
			EndIf;
			If ValueIsFilled(vCurCheckInDate) Then
				If Not IsBlankString(mGuest) Then
					mGuest = mGuest + ", ";
				EndIf;
				mGuest = mGuest + Format(vCurCheckInDate, "DF='dd.MM.yy HH:mm'");
			EndIf;
			If ValueIsFilled(vCurCheckOutDate) Then
				mGuest = mGuest + " - " + Format(vCurCheckOutDate, "DF='dd.MM.yy HH:mm'");
			EndIf;
			If ValueIsFilled(vCurRoom) Then
				mGuest = mGuest + ", " + TrimAll(vCurRoom);
			ElsIf ValueIsFilled(vCurRoomType) Then
				mGuest = mGuest + ", " + vCurRoomType.GetObject().pmGetRoomTypeDescription(pLanguage);
			ElsIf ValueIsFilled(vCurResource) Then
				mGuest = mGuest + ", " + vCurResource.GetObject().pmGetResourceDescription(pLanguage);
			EndIf;
			// Put row
			vGuest.Parameters.mGuest = TrimAll(mGuest);
			If Not IsBlankString(mGuest) Then
				pSpreadsheet.Put(vGuest);
			EndIf;
		EndIf;
		// Fill parameters
		mAccountingDate = Format(vTran.ServiceDate, "DF=dd.MM.yy");
		mPrice = 0;
		If vTran.RecordType = AccumulationRecordType.Expense Then
			If StrFind(vParameter, "DO_NOT_SHOW_PAYMENTS") > 0 Then
				vPrintThisTransaction = False;
			EndIf;
			
			mDescription = TrimAll(vTran.PaymentMethod);
			If ValueIsFilled(vTran.PaymentMethod) Then
				vPaymentMethodObj = vTran.PaymentMethod.GetObject();
				mDescription = vPaymentMethodObj.pmGetPaymentMethodDescription(pLanguage);
			EndIf;
			
			// Add payment number and date
			mQuantity = "";
			mSum = "";
			mPaymentSum = vTran.Sum;
			
			If StrFind(vParameter, "DO_NOT_SHOW_PAYMENT_REMARKS") > 0 Then
				vTran.Remarks = "";
			Else
				mDescription = mDescription + ?(IsBlankString(mDescription), "", " - ") + 
				?(ValueIsFilled(vTran.Document), cmNStr("en='Doc. #';ru='Док. №';de='Dokument Nr.'", pLanguage) + 
				cmGetDocumentNumberPresentation(vTran.Document.Number) + 
				cmNStr("en=' - ';ru=' от ';de=' vom '", pLanguage) + Format(vTran.Document.Date, "DF=dd.MM.yy"), "");
			EndIf;
			
			vTotalPaymentSum = vTotalPaymentSum + vTran.Sum;
			vTotalPaymentVATSum = vTotalPaymentVATSum + vTran.VATSum;
			
			vVATPaymentRow = vVATRatePaymentTransactions.Add();
			vVATPaymentRow.VATRate = vTran.VATRate;
			vVATPaymentRow.RecordType = AccumulationRecordType.Receipt;
			vVATPaymentRow.Sum = vTran.Sum;
			vVATPaymentRow.VATSum = vTran.VATSum;
		Else
			mDescription = TrimAll(vTran.Service);
			mSum = vTran.Sum;
			mPaymentSum = "";
			mQuantity = "";
			If Round(vTran.Quantity, 3) <> vTran.Quantity Then
				mQuantity = ?(vTran.Quantity = 0, "", Format(vTran.Quantity, "ND=17; NFD=3"));
			Else
				mQuantity = ?(vTran.Quantity = 0, "", String(vTran.Quantity));
			EndIf;
			If ValueIsFilled(vTran.Service) Then
				vServiceObj = vTran.Service.GetObject();
				mDescription = vServiceObj.pmGetServiceDescription(pLanguage, ?((vTran.Service = vAccommodationService) And vGroupByAccommodation, True, False));
				If vTran.Quantity <> 0 Then
					mQuantity = vServiceObj.pmGetServiceQuantityPresentation(vTran.Quantity, pLanguage);
				EndIf;
			EndIf;
			vTotalSum = vTotalSum + vTran.Sum;
			vTotalVATSum = vTotalVATSum + cmCalculateVATSum(vTran.VATRate, vTran.Sum, vTran.Period);
			
			If StrFind(vParameter, "DO_NOT_SHOW_CHARGE_REMARKS") > 0 Then
				vTran.Remarks = "";
			EndIf;
		EndIf;
		If Not IsBlankString(vTran.Remarks) Then
			mDescription = mDescription + " - " + cmNStr(vTran.Remarks, pLanguage);
		EndIf;
		// Set parameters
		mPrice = ?(vTran.Quantity <> 0, Round(vTran.Sum/vTran.Quantity, 2), vTran.Price);
		vRow.Parameters.mPrice = Format(mPrice, "ND=17; NFD=2");
		vRow.Parameters.mQuantity = mQuantity;
		vRow.Parameters.mDescription = Chars.Tab + mDescription;
		vRow.Parameters.mPaymentSum = Format(mPaymentSum, "ND=17; NFD=2");
		vRow.Parameters.mSum = Format(mSum, "ND=17; NFD=2");
		// Put row
		If (Not IsBlankString(mSum) Or Not IsBlankString(mPaymentSum)) And vPrintThisTransaction Then
			pSpreadsheet.Put(vRow);
		EndIf;
	EndDo;
	
	// VAT totals
	vVATRateTransactions = New ValueTable();
	If (vTotalSum - vTotalPaymentSum) = 0 And vTotalPaymentSum <> 0 And Not vCompany.PrintVATInFolioByCharges Then
		If Not vIgnoreVATRate Then
			vVATRateTransactions = vVATRatePaymentTransactions;
		EndIf;
		vTotalVATSum = vTotalPaymentVATSum;
	ElsIf vIgnoreVATRate Then
		vVATRateTransactions = vTransactionsCopy.Copy();
	Else
		vVATRateTransactions = vTransactions.Copy();
	EndIf;
	vVATRateTransactions.GroupBy("VATRate, RecordType", "Sum, VATSum");
	vVATRateTransactions.Sort("VATRate");
	If StrFind(vParameter, "CALCULATE_VAT_AMOUNT_BY_VAT_RATE_TOTALS") > 0 Then
		vTotalVATSum = 0;
		For Each vVATRate In vVATRateTransactions Do
			If vVATRate.RecordType = AccumulationRecordType.Receipt Then
				vTotalVATSum = vTotalVATSum + cmCalculateVATSum(vVATRate.VATRate, vVATRate.Sum, vMinAccDate);
			EndIf;
		EndDo;
	EndIf;
	
	// Footer
	vFooter = vTemplate.GetArea("Footer");
	vFooterTotals = vTemplate.GetArea("FooterTotals");
	// Fill parameters
	mTotalSum = Format(vTotalSum, "ND=17; NFD=2; NZ=") + " " + mFolioCurrency;
	If ValueIsFilled(vCompany) And vCompany.DoNotPrintVAT Then
		mTotalVATSum = "";
	Else
		If vTotalVATSum <> 0 Or vTotalPaymentVATSum <> 0 Then
			mTotalVATSum = cmNStr("EN='Including VAT ';RU='В том числе НДС ';de='Darunter MwSt. '", pLanguage) + Format(vTotalVATSum, "ND=17; NFD=2") + " " + mFolioCurrency;
		Else
			mTotalVATSum = cmNStr("EN='No VAT';RU='НДС не облагается';de='MwSt. wird nicht berechnet'", pLanguage);       
			If vVATRateTransactions.Count() > 0 Then 
				For Each vRowVatRate In vVATRateTransactions Do
					vVATRate = vRowVatRate.VATRate;
					If ValueIsFilled(vVATRate) And Not vVATRate.NoVAT And vVATRate.TaxRate = 0 Then
						mTotalVATSum = cmNStr("EN='Including VAT ';RU='НДС ';de='Darunter MwSt. '", pLanguage) + Format(vTotalVATSum, "ND=17; NFD=2; NZ=0.00") + " " + mFolioCurrency;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	mTotalPaymentSum = Format(vTotalPaymentSum, "ND=17; NFD=2; NZ=") + " " + mFolioCurrency;
	mBalance = Format(vTotalSum - vTotalPaymentSum, "ND=17; NFD=2; NZ=") + " " + mFolioCurrency;
	mTotalSumInWords = cmSumInWords(vTotalSum, pFolio.FolioCurrency, pLanguage);
	mEmployee = SessionParameters.CurrentUser.GetObject().pmGetEmployeeDescription(pLanguage);
	mEmployeePosition = cmNStr("en='Manager';ru='Администратор';de='Manager'", pLanguage);
	If Not IsBlankString(SessionParameters.CurrentUser.Position) Then
		mEmployeePosition = cmNStr(TrimAll(SessionParameters.CurrentUser.Position), pLanguage);
	EndIf;
	mClosed = ?(pFolio.IsClosed, cmNStr("en=' closed';ru=' закрыт';de=' geschlossen'", pLanguage), "");
	// Set parameters
	vFooterTotals.Parameters.mTotalSum = mTotalSum;
	vFooterTotals.Parameters.mTotalPaymentSum = mTotalPaymentSum;
	vFooterTotals.Parameters.mBalance = mBalance;
	If pLanguage <> Catalogs.Languages.DE Then
		vFooterTotals.Parameters.mTotalSumInWords = mTotalSumInWords;
		vFooterTotals.Parameters.mTotalVATSum = mTotalVATSum;
	EndIf;
	vFooterTotals.Parameters.mClosed = mClosed;
	// Put footer totals
	pSpreadsheet.Put(vFooterTotals);
	
	// Put VAT footers
	If ValueIsFilled(vCompany) And Not vCompany.IsUsingSimpleTaxSystem Then
		vVATHeader = vTemplate.GetArea("VATHeader");
		vVATHeader.Parameters.mFolioCurrency = mFolioCurrency;
		pSpreadsheet.Put(vVATHeader);
		
		// VAT percents
		vVATRateRow = vTemplate.GetArea("VATRateRow");
		For Each vVATRate In vVATRateTransactions Do
			If vVATRate.RecordType = AccumulationRecordType.Receipt Then
				vVATRateVATSum = vVATRate.VATSum;
				If StrFind(vParameter, "CALCULATE_VAT_AMOUNT_BY_VAT_RATE_TOTALS") > 0 Then
					vVATRateVATSum = cmCalculateVATSum(vVATRate.VATRate, vVATRate.Sum, vMinAccDate);
				EndIf;
				
				vVATRateRow.Parameters.mVATRate = TrimAll(vVATRate.VATRate);
				vVATRateRow.Parameters.mSumWithoutVAT = Format(vVATRate.Sum - vVATRateVATSum, "ND=17; NFD=2; NZ=");
				vVATRateRow.Parameters.mVATSum = Format(vVATRateVATSum, "ND=17; NFD=2; NZ=");
				vVATRateRow.Parameters.mSumWithVAT = Format(vVATRate.Sum, "ND=17; NFD=2; NZ=");
				pSpreadsheet.Put(vVATRateRow);
			EndIf;
		EndDo;
	EndIf;
	
	// Print footer with signatures 
	If StrFind(vParameter, "NO_MANAGER_IN_FOOTER") > 0 Then
		mEmployee = "";
		mEmployeePosition = "";
	EndIf;
	vFooter.Parameters.mEmployee = mEmployee;
	Try
		vFooter.Parameters.mEmployeePosition = mEmployeePosition;
	Except
	EndTry;
	vFooter.Parameters.mFormText = "";
	// Print bonuses if any      
	If StrFind(vParameter, "SHOW_BONUSES_BALANCE") > 0 Then
		vFooter.Parameters.mFormText = FillBonuses(pFolio, pLanguage);  
	EndIf;
	vFooter.Parameters.mFormText = vFooter.Parameters.mFormText + ?(IsBlankString(vFooter.Parameters.mFormText), "", Chars.LF) + TrimR(pObjectPrintForm.FormText);
	If pFolio.Hotel.PrintClientSignatureOnFolio Then
		vFooter.Parameters.mGuestSignature = cmNStr("en = 'Client signature ______________________'; de = 'Unterschrift des Kunden ______________________'; ru = 'Подпись клиента ______________________'", pLanguage);
	Else
		vFooter.Parameters.mGuestSignature = "";
	EndIf;
	// Put footer
	pSpreadsheet.Put(vFooter);
	
	// Setup default attributes with black and white print mode
	cmSetDefaultPrintFormSettings(pSpreadsheet, PageOrientation.Portrait, True, , True);
	// Check authorities
	cmSetSpreadsheetProtection(pSpreadsheet);
	// Get and fill workstation print form settings
	If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
		vWorkstationPrintSettings = SessionParameters.CurrentWorkstation.WorkstationPrintSettings;
		If ValueIsFilled(vWorkstationPrintSettings) Then
			// Try to find records for the current object print form
			vFilter = New Structure("ObjectPrintingForm, IsActive", pObjectPrintForm, True); 
			vPrintSettingsSet = vWorkstationPrintSettings.PrintFormsList.FindRows(vFilter);
			If vPrintSettingsSet.Count() > 0 Then
				For Each vPrintSettings In vPrintSettingsSet Do
					// Fill settings
					cmSetSpreadsheetSettings(pSpreadsheet, vPrintSettings);
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PrintFolioByClients

// -----------------------------------------------------------------------------
Procedure PrintSelectedCharges(pFolio, pFoliosList, pGroupBy, pLanguage, pObjectPrintForm, pTransactions, pSpreadsheet=Undefined, rMessage = "") Export
	If pTransactions = Undefined Or pTransactions.Count() = 0 Then
		rMessage = NStr("en = 'No transaction is selected!'; de = 'Keine Transaktion ausgewählt!'; ru = 'Не выбрана транзакция!'");
		Return;
	EndIf;
	
	// Basic checks
	vHotel = pFolio.Hotel;
	If Not ValueIsFilled(pFolio.Hotel) Then
		vHotel = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(vHotel) Then
		rMessage = NStr("en = 'Default hotel should be selected!'; de = 'Das aktuelle Hotel ist nicht angegeben!'; ru = 'Не задана текущая гостиница!'");
		Return;
	EndIf;
	vCompany = pFolio.Company;
	If Not ValueIsFilled(pFolio.Company) Then
		vCompany = vHotel.Company;
	EndIf;
	If Not ValueIsFilled(vCompany) Then
		rMessage = NStr("en = 'Default hotel company should be selected!'; de = 'Beim Hotel muss standardmäßig eine Firma festgelegt sein!'; ru = 'У гостиницы должна быть указана фирма по умолчанию!'");
		Return;
	EndIf;
	If Not ValueIsFilled(pLanguage) Then
		pLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	
	SelCharge = pTransactions.Get(0).Document;
	SelGuestGroup = pFolio.GuestGroup;
	SelParentDoc = SelCharge.ParentDoc;
	SelClient = pFolio.Client;
	SelDateTimeFrom = pFolio.DateTimeFrom;
	SelDateTimeTo = pFolio.DateTimeTo;
	SelRoom = pFolio.Room;
	SelRoomType = Undefined;
	If ValueIsFilled(SelRoom) Then
		SelRoomType = SelRoom.RoomType;
	EndIf;
	If pFolio = vHotel.ReservationAdvancesFolio And ValueIsFilled(SelParentDoc) Then
		If TypeOf(SelParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(SelParentDoc) = Type("DocumentRef.Accommodation") Then
			SelGuestGroup = SelParentDoc.GuestGroup;
			SelClient = SelParentDoc.Guest;
			SelDateTimeFrom = SelParentDoc.CheckInDate;
			SelDateTimeTo = SelParentDoc.CheckOutDate;
			SelRoom = SelParentDoc.Room;
			SelRoomType = SelParentDoc.RoomType;
		ElsIf TypeOf(SelParentDoc) = Type("DocumentRef.ResourceReservation") Then
			SelGuestGroup = SelParentDoc.GuestGroup;
			SelClient = SelParentDoc.Client;
		EndIf;
	EndIf;
	
	// Choose template
	If Not ValueIsFilled(pFolio) Then
		Return;
	EndIf;
	vFolioObj = pFolio.GetObject();
	
	pSpreadsheet = ?(pSpreadsheet = Undefined, New SpreadsheetDocument, pSpreadsheet);
	pSpreadsheet.Clear();
	If ValueIsFilled(pLanguage) Then
		If pLanguage = Catalogs.Languages.EN Then
			vTemplate = vFolioObj.GetTemplate("FolioPrintChargeEn");
		ElsIf pLanguage = Catalogs.Languages.DE Then
			vTemplate = vFolioObj.GetTemplate("FolioPrintChargeDe");
		ElsIf pLanguage = Catalogs.Languages.RU Then
			vTemplate = vFolioObj.GetTemplate("FolioPrintChargeRu");
		Else
			rMessage = StrTemplate(NStr("ru='Не найден шаблон печатной формы лицевого счета для языка %1!'; 
			|de='No folio print form template found for the %1 language!';
			|en='No folio print form template found for the %1 language!'"),  pLanguage.Code);
			Return;
		EndIf;
	Else
		vTemplate = vFolioObj.GetTemplate("FolioPrintChargeRu");
	EndIf;
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(pObjectPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;
	
	// Read parameter value
	vParameter = Upper(TrimAll(pObjectPrintForm.Parameter));
	
	// Load pictures
	vLogoIsSet = False;
	vLogo = New Picture;
	If ValueIsFilled(pFolio.Hotel) Then
		If pFolio.Hotel.Logo <> Undefined Then
			vLogo = pFolio.Hotel.Logo.Get();
			If vLogo = Undefined Then
				vLogo = New Picture;
			Else
				vLogoIsSet = True;
			EndIf;
		EndIf;
	EndIf;
	
	// Header
	If ValueIsFilled(pObjectPrintForm) And Find(Upper(pObjectPrintForm.Parameter), "COPY_1") > 0 Then
		vHeader = vTemplate.GetArea("Header|Copy1");
	ElsIf ValueIsFilled(pObjectPrintForm) And Find(Upper(pObjectPrintForm.Parameter), "COPY_2") > 0 Then
		vHeader = vTemplate.GetArea("Header|Copy2");
	Else
		vHeader = vTemplate.GetArea("Header");
	EndIf;
	
	// Hotel
	mHotelPrintName = Catalogs.Hotels.pmGetHotelPrintName(vHotel, pLanguage);
	mHotelPostAddressPresentation = Catalogs.Hotels.pmGetHotelPostAddressPresentation(vHotel, pLanguage);
	vHotelPhones = TrimAll(vHotel.Phones);
	vHotelFax = TrimAll(vHotel.Fax);
	mHotelPhones = vHotelPhones + ?(IsBlankString(vHotelFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", pLanguage) + vHotelFax);
	// Company
	mCompanyLegacyName = TrimAll(vCompany.GetObject().pmGetCompanyPrintName(pLanguage));
	vCompanyTIN = TrimAll(vCompany.TIN);
	vCompanyKPP = TrimAll(vCompany.KPP);
	mCompanyTIN = cmNStr("EN='TIN ';RU='ИНН/КПП ';de='TIN '", pLanguage) + vCompanyTIN + ?(IsBlankString(vCompanyKPP), "", "/" + vCompanyKPP);
	If mCompanyLegacyName = mHotelPrintName Then
		mCompanyLegacyName = mCompanyTIN;
		mCompanyTIN = "";
	EndIf;
	// Folio date and number
	If ValueIsFilled(vHotel) And vHotel.DoNotPrintFolioNumberInFolioPrintForms And Not pFolio.IsClosed Then
		mFolioNumber = cmNStr("en='PROFORMA'; ru='ПРЕЧЕК'; de='PROFORMA'", pLanguage);
	Else
		mFolioNumber = cmGetDocumentNumberPresentation(pFolio.Number);
	EndIf;
	// Charge number
	mChargeNumber = cmGetDocumentNumberPresentation(SelCharge.Number);
	// Client
	mClient = "";
	If ValueIsFilled(SelClient) Then
		mClient = TrimAll(TrimAll(SelClient.LastName) + " " + TrimAll(SelClient.FirstName) + " " + TrimAll(SelClient.SecondName));
	EndIf;
	// External client from the folio description
	If IsBlankString(mClient) Then
		mClient = TrimAll(pFolio.Description);
	EndIf;
	// Customer
	mCustomerLegacyName = "";
	If ValueIsFilled(pFolio.Customer) And ValueIsFilled(pFolio.Hotel) And 
		pFolio.Hotel.IndividualsCustomer <> pFolio.Customer Then
		mCustomerLegacyName = TrimAll(pFolio.Customer.LegacyName);
		If IsBlankString(mCustomerLegacyName) Then
			mCustomerLegacyName = TrimAll(pFolio.Customer.Description);
		EndIf;
		vAddress = "";
		If Not IsBlankString(pFolio.Customer.LegacyAddress) Then
			vAddress = TrimAll(pFolio.Customer.LegacyAddress);
		ElsIf Not IsBlankString(pFolio.Customer.PostAddress) Then
			vAddress = TrimAll(pFolio.Customer.PostAddress);
		EndIf;
		vAddress = cmGetAddressPresentation(vAddress);
		mCustomerLegacyName = mCustomerLegacyName + Chars.LF + vAddress;
	ElsIf ValueIsFilled(SelClient) And Not IsBlankString(SelClient.FolioCustomerPresentation) Then
		mCustomerLegacyName = TrimAll(SelClient.FolioCustomerPresentation);
	ElsIf ValueIsFilled(SelParentDoc) And ValueIsFilled(SelParentDoc.Customer) And ValueIsFilled(pFolio.Hotel) And 
		pFolio.Hotel.IndividualsCustomer <> SelParentDoc.Customer Then
		mCustomerLegacyName = TrimAll(SelParentDoc.Customer.LegacyName);
		If IsBlankString(mCustomerLegacyName) Then
			mCustomerLegacyName = TrimAll(SelParentDoc.Customer.Description);
		EndIf;
		vAddress = "";
		If Not IsBlankString(SelParentDoc.Customer.LegacyAddress) Then
			vAddress = TrimAll(SelParentDoc.Customer.LegacyAddress);
		ElsIf Not IsBlankString(SelParentDoc.Customer.PostAddress) Then
			vAddress = TrimAll(SelParentDoc.Customer.PostAddress);
		EndIf;
		vAddress = cmGetAddressPresentation(vAddress);
		mCustomerLegacyName = mCustomerLegacyName + Chars.LF + vAddress;
	EndIf;
	If ValueIsFilled(pObjectPrintForm) And Not IsBlankString(pObjectPrintForm.Parameter) Then
		If Find(Upper(pObjectPrintForm.Parameter), "FOLIO_CUSTOMER") > 0 And Not ValueIsFilled(pFolio.Customer) Then
			mCustomerLegacyName = "";
		EndIf;
	EndIf;
	If IsBlankString(mCustomerLegacyName) Then
		If ValueIsFilled(pFolio.Client) Then
			vAddress = "";
			If Not IsBlankString(pFolio.Client.Address) Then
				vAddress = cmGetAddressPresentation(pFolio.Client.Address);
				If Not IsBlankString(vAddress) And Find(vAddress, Chars.LF) > 0 Then
					mClient = mClient + Chars.LF + vAddress;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	// Contract
	mContractDescription = "";
	If ValueIsFilled(pFolio.Contract) Then
		mContractDescription = TrimAll(pFolio.Contract.Description);
	EndIf;
	// Currency
	mFolioCurrency = "";
	If ValueIsFilled(pFolio.FolioCurrency) Then
		vCurrencyObj = pFolio.FolioCurrency.GetObject();
		mFolioCurrency = vCurrencyObj.pmGetCurrencyDescription(pLanguage);
	EndIf;
	// Room and room type
	mRoom = TrimAll(pFolio.Room);
	If ValueIsFilled(pObjectPrintForm) And Not IsBlankString(pObjectPrintForm.Parameter) Then
		If Find(Upper(pObjectPrintForm.Parameter), "ACCOMMODATION_TYPE") > 0 Then
			If ValueIsFilled(SelParentDoc) And 
				(TypeOf(SelParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(SelParentDoc) = Type("DocumentRef.Reservation")) Then
				If ValueIsFilled(SelParentDoc.AccommodationType) Then
					If SelParentDoc.AccommodationType.Type = Enums.AccomodationTypes.Beds Or
						SelParentDoc.AccommodationType.Type = Enums.AccomodationTypes.AdditionalBed Then
						mRoom = mRoom + ", " + SelParentDoc.AccommodationType.GetObject().pmGetAccommodationTypeDescription(pLanguage);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	mRoomType = "";
	If ValueIsFilled(SelRoomType) Then
		vRoomTypeToPrint = SelRoomType;
		If ValueIsFilled(SelParentDoc) And (TypeOf(SelParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(SelParentDoc) = Type("DocumentRef.Reservation")) Then
			If ValueIsFilled(vRoomTypeToPrint) And ValueIsFilled(SelParentDoc.RoomTypeUpgrade) And SelParentDoc.RoomTypeUpgrade.BaseRoomType = vRoomTypeToPrint Then
				vRoomTypeToPrint = SelParentDoc.RoomTypeUpgrade;
			EndIf;
		EndIf;
		vRoomTypeObj = vRoomTypeToPrint.GetObject();
		mRoomType = vRoomTypeObj.pmGetRoomTypeDescription(pLanguage);
	EndIf;
	// Check in and check out dates
	mCheckInDate = Format(SelDateTimeFrom, "DF='dd.MM.yy HH:mm'");
	mCheckOutDate = Format(SelDateTimeTo, "DF='dd.MM.yy HH:mm'");
	// Guest group
	mGuestGroup = TrimAll(SelGuestGroup);
	vHotelPrefix = Catalogs.Hotels.pmGetPrefix(pFolio.Hotel);
	If Not IsBlankString(vHotelPrefix) And pFolio.Hotel.ShowHotelPrefixBeforeGroupCode Then
		mGuestGroup = vHotelPrefix + mGuestGroup;
	EndIf;
	// Set parameters and put report section
	vHeader.Parameters.mHotelPrintName = mHotelPrintName;
	vHeader.Parameters.mHotelPostAddressPresentation = mHotelPostAddressPresentation;
	vHeader.Parameters.mHotelPhones = mHotelPhones;
	vHeader.Parameters.mCompanyLegacyName = mCompanyLegacyName;
	vHeader.Parameters.mCompanyTIN = mCompanyTIN;
	vHeader.Parameters.mFolioNumber = mFolioNumber;
	vHeader.Parameters.mChargeNumber = mChargeNumber;
	vHeader.Parameters.mClient = mClient;
	vHeader.Parameters.mCustomerLegacyName = mCustomerLegacyName;
	If pLanguage <> Catalogs.Languages.DE Then
		vHeader.Parameters.mFolioCurrency = mFolioCurrency;
	EndIf;
	vHeader.Parameters.mRoom = mRoom;
	vHeader.Parameters.mRoomType = mRoomType;
	vHeader.Parameters.mCheckInDate = mCheckInDate;
	vHeader.Parameters.mCheckOutDate = mCheckOutDate;
	vHeader.Parameters.mGuestGroup = mGuestGroup;
	// Logo
	If ValueIsFilled(pObjectPrintForm) And Find(Upper(pObjectPrintForm.Parameter), "COPY_1") > 0 Then
		If vLogoIsSet Then
			vHeader.Drawings.Logo.Print = True;
			vHeader.Drawings.Logo.Picture = vLogo;
		Else
			vHeader.Drawings.Delete(vHeader.Drawings.Logo);
		EndIf;
	ElsIf ValueIsFilled(pObjectPrintForm) And Find(Upper(pObjectPrintForm.Parameter), "COPY_2") > 0 Then
		If vLogoIsSet Then
			vHeader.Drawings.Logo.Print = True;
			vHeader.Drawings.Logo.Picture = vLogo;
			vHeader.Drawings.Logo1.Print = True;
			vHeader.Drawings.Logo1.Picture = vLogo;
		Else
			vHeader.Drawings.Delete(vHeader.Drawings.Logo);
			vHeader.Drawings.Delete(vHeader.Drawings.Logo1);
		EndIf;
	Else
		If vLogoIsSet Then
			vHeader.Drawings.Logo.Print = True;
			vHeader.Drawings.Logo.Picture = vLogo;
			vHeader.Drawings.Logo1.Print = True;
			vHeader.Drawings.Logo1.Picture = vLogo;
			vHeader.Drawings.Logo2.Print = True;
			vHeader.Drawings.Logo2.Picture = vLogo;
		Else
			vHeader.Drawings.Delete(vHeader.Drawings.Logo);
			vHeader.Drawings.Delete(vHeader.Drawings.Logo1);
			vHeader.Drawings.Delete(vHeader.Drawings.Logo2);
		EndIf;
	EndIf;
	// Put header
	pSpreadsheet.Put(vHeader);
	
	// Get row template area
	If ValueIsFilled(pObjectPrintForm) And Find(Upper(pObjectPrintForm.Parameter), "COPY_1") > 0 Then
		vRow = vTemplate.GetArea("Row|Copy1");
	ElsIf ValueIsFilled(pObjectPrintForm) And Find(Upper(pObjectPrintForm.Parameter), "COPY_2") > 0 Then
		vRow = vTemplate.GetArea("Row|Copy2");
	Else
		vRow = vTemplate.GetArea("Row");
	EndIf;
	
	// Print transactions
	vTotalSum = 0;
	vTotalVATSum = 0;
	For Each vTranItem In pTransactions Do
		vPrintThisTransaction = True;
		vTran = vTranItem.Document;
		vTranRemarks = vTran.Remarks;
		
		// Fill parameters
		mAccountingDate = Format(vTran.Date, "DF=dd.MM.yy");
		If TypeOf(vTran) = Type("DocumentRef.Payment") Or TypeOf(vTran) = Type("DocumentRef.Return") Or TypeOf(vTran) = Type("DocumentRef.DepositTransfer") Then
			If StrFind(vParameter, "DO_NOT_SHOW_PAYMENTS") > 0 Then
				vPrintThisTransaction = False;
			EndIf;
			
			mDescription = TrimAll(vTran.PaymentMethod);
			If ValueIsFilled(vTran.PaymentMethod) Then
				vPaymentMethodObj = vTran.PaymentMethod.GetObject();
				mDescription = vPaymentMethodObj.pmGetPaymentMethodDescription(pLanguage);
			EndIf;
			
			// Add payment number and date
			If StrFind(vParameter, "DO_NOT_SHOW_PAYMENT_REMARKS") > 0 Then
				vTranRemarks = "";
			Else
				mDescription = mDescription + ?(IsBlankString(mDescription), "", " - ") + 
				?(ValueIsFilled(vTran), cmNStr("en='Doc. #';ru='Док. №';de='Dokument Nr.'", pLanguage) + cmGetDocumentNumberPresentation(vTran.Number) + cmNStr("en=' - ';ru=' от ';de=' vom '", pLanguage) + Format(vTran.Date, "DF=dd.MM.yy"), "");
			EndIf;
			
			If ValueIsFilled(vTran) And 
				TypeOf(vTran) = Type("DocumentRef.Payment") Or 
				TypeOf(vTran) = Type("DocumentRef.Return") Then
				If ValueIsFilled(vTran.Payer) And 
					vTran.Payer <> vTran.Folio.Client And 
					vTran.Payer <> vTran.Folio.Customer Then
					If TypeOf(vTran.Payer) = Type("CatalogRef.Clients") Then
						mDescription = mDescription + " - " + TrimAll(vTran.Payer.FullName);
					ElsIf TypeOf(vTran.Payer) = Type("CatalogRef.Customers") Then
						If IsBlankString(vTran.Payer.LegacyName) Then
							mDescription = mDescription + " - " + TrimAll(vTran.Payer);
						Else
							mDescription = mDescription + " - " + TrimAll(vTran.Payer.LegacyName);
						EndIf;
					EndIf;
				EndIf;
				If vTran.PaymentCurrency <> vTran.FolioCurrency Then
					mDescription = mDescription + " - " + cmFormatSum(vTran.Sum, vTran.PaymentCurrency);
				EndIf;
			EndIf;
			If TypeOf(vTran) = Type("DocumentRef.DepositTransfer") Then
				If pFolio = vTran.FolioFrom Then
					mSum = vTran.SumInFolioFromCurrency;
				Else
					mSum = vTran.SumInFolioToCurrency;
				EndIf;
			ElsIf TypeOf(vTran) = Type("DocumentRef.Return") Then
				mSum = -vTran.SumInFolioCurrency;
			Else
				mSum = vTran.SumInFolioCurrency;
			EndIf;
			
			// Set parameters
			vRow.Parameters.mAccountingDate = mAccountingDate;
			vRow.Parameters.mPrice = "";
			vRow.Parameters.mQuantity = "";
			vRow.Parameters.mDescription = mDescription;
			vRow.Parameters.mSum = Format(mSum, "ND=17; NFD=2");
		Else
			mAccountingDate = Format(vTran.ServiceDate, "DF=dd.MM.yy");
			mDescription = TrimAll(vTran.Service);
			mSum = vTran.Sum - vTran.DiscountSum;
			mPrice = Round(mSum / vTran.Quantity, 2);
			mQuantity = "";
			If Round(vTran.Quantity, 3) <> vTran.Quantity Then
				mQuantity = ?(vTran.Quantity = 0, "", Format(vTran.Quantity, "ND=17; NFD=3"));
			Else
				mQuantity = ?(vTran.Quantity = 0, "", String(vTran.Quantity));
			EndIf;
			If ValueIsFilled(vTran.Service) Then
				vServiceObj = vTran.Service.GetObject();
				mDescription = vServiceObj.pmGetServiceDescription(pLanguage, False);
				If vTran.Quantity <> 0 Then
					mQuantity = vServiceObj.pmGetServiceQuantityPresentation(vTran.Quantity, pLanguage);
				EndIf;
			EndIf;
			vTotalVATSum = vTotalVATSum + cmCalculateVATSum(vTran.VATRate, mSum, vTran.Date);
			If StrFind(vParameter, "DO_NOT_SHOW_CHARGE_REMARKS") > 0 Then
				vTranRemarks = "";
			EndIf;
			If Not IsBlankString(vTranRemarks) Then
				mDescription = mDescription + " - " + cmNStr(vTranRemarks, pLanguage);
			EndIf;
			If Not IsBlankString(vTran.Details) Then
				mDescription = mDescription + ?(IsBlankString(mDescription), "", Chars.LF) + 
				TrimAll(vTran.Details);
			EndIf;
			
			// Try to find order for this charge
			vOrder = Documents.Order.GetOrderByCharge(vTran);
			If ValueIsFilled(vOrder) And vOrder.Items.Count() > 0 Then
				vItems = "";
				For Each vOrderItemsRow In vOrder.Items Do
					vItems = vItems + ?(IsBlankString(vItems), "", Chars.LF) + 
					TrimAll(vOrderItemsRow.Item) + " - " + 
					cmFormatSum(vOrderItemsRow.Price, vOrder.Currency, "NZ=", , True) + 
					" x " + vOrderItemsRow.Quantity + " = " + 
					cmFormatSum(vOrderItemsRow.Sum, vOrder.Currency, "NZ=");
				EndDo;
				mDescription = mDescription + ?(IsBlankString(mDescription), "", Chars.LF) + 
				TrimAll(vItems);
			EndIf;
			
			// Set parameters
			vRow.Parameters.mAccountingDate = mAccountingDate;
			vRow.Parameters.mPrice = Format(mPrice, "ND=17; NFD=2");
			vRow.Parameters.mQuantity = mQuantity;
			vRow.Parameters.mDescription = mDescription;
			vRow.Parameters.mSum = Format(mSum, "ND=17; NFD=2");
		EndIf;
		vTotalSum = vTotalSum + mSum;
		
		// Put row
		If vPrintThisTransaction Then
			pSpreadsheet.Put(vRow);
		EndIf;
	EndDo;
	
	// Footer
	If ValueIsFilled(pObjectPrintForm) And Find(Upper(pObjectPrintForm.Parameter), "COPY_1") > 0 Then
		vFooterTotals = vTemplate.GetArea("FooterTotals|Copy1");
		vFooter = vTemplate.GetArea("Footer|Copy1");
	ElsIf ValueIsFilled(pObjectPrintForm) And Find(Upper(pObjectPrintForm.Parameter), "COPY_2") > 0 Then
		vFooterTotals = vTemplate.GetArea("FooterTotals|Copy2");
		vFooter = vTemplate.GetArea("Footer|Copy2");
	Else
		vFooterTotals = vTemplate.GetArea("FooterTotals");
		vFooter = vTemplate.GetArea("Footer");
	EndIf;
	
	// Fill parameters
	mTotalSum = Format(vTotalSum, "ND=17; NFD=2; NZ=") + " " + mFolioCurrency;
	If ValueIsFilled(vCompany) And vCompany.DoNotPrintVAT Then
		mTotalVATSum = "";
	Else
		If vTotalVATSum <> 0 Then
			mTotalVATSum = cmNStr("en='Including VAT ';ru='В том числе НДС ';de='Darunter MwSt. '", pLanguage) + Format(vTotalVATSum, "ND=17; NFD=2") + " " + mFolioCurrency;
		Else
			mTotalVATSum = cmNStr("en='No VAT';ru='НДС не облагается';de='MwSt. wird nicht berechnet'", pLanguage); 
			If pTransactions.Count() > 0 Then 
				For Each vRowVatRate In pTransactions Do
					vVATRate = vRowVatRate.VATRate;
					If ValueIsFilled(vVATRate) And Not vVATRate.NoVAT And vVATRate.TaxRate = 0 Then
						mTotalVATSum = cmNStr("EN='Including VAT ';RU='НДС ';de='Darunter MwSt. '", pLanguage) + Format(vTotalVATSum, "ND=17; NFD=2; NZ=0.00") + " " + mFolioCurrency;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	If pLanguage <> Catalogs.Languages.DE Then
		mTotalSumInWords = cmSumInWords(vTotalSum, pFolio.FolioCurrency, pLanguage);
	EndIf;
	mEmployee = SessionParameters.CurrentUser.GetObject().pmGetEmployeeDescription(pLanguage);
	mEmployeePosition = cmNStr("en='Manager';ru='Администратор';de='Manager'", pLanguage);
	If Not IsBlankString(SessionParameters.CurrentUser.Position) Then
		mEmployeePosition = cmNStr(TrimAll(SessionParameters.CurrentUser.Position), pLanguage);
	EndIf;
	// Set parameters
	vFooterTotals.Parameters.mTotalSum = mTotalSum;
	If pLanguage <> Catalogs.Languages.DE Then
		vFooterTotals.Parameters.mTotalSumInWords = mTotalSumInWords;
	EndIf;
	vFooter.Parameters.mEmployee = mEmployee;
	Try
		vFooter.Parameters.mEmployeePosition = mEmployeePosition;
	Except
	EndTry;
	vFooter.Parameters.mGuestSignature = cmNStr("en='Client signature ______________________';ru='Подпись клиента ______________________';de='Unterschrift des Kunden ______________________'", pLanguage);
	// Put footer
	pSpreadsheet.Put(vFooterTotals);
	pSpreadsheet.Put(vFooter);
	
	// Setup default attributes with black and white print mode
	If ValueIsFilled(pObjectPrintForm) And Find(Upper(pObjectPrintForm.Parameter), "COPY_1") > 0 Then
		cmSetDefaultPrintFormSettings(pSpreadsheet, PageOrientation.Portrait, True, , True);
	Else
		cmSetDefaultPrintFormSettings(pSpreadsheet, PageOrientation.Landscape, True, , True);
	EndIf;
	// Check authorities
	cmSetSpreadsheetProtection(pSpreadsheet);
	// Get and fill workstation print form settings
	If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
		vWorkstationPrintSettings = SessionParameters.CurrentWorkstation.WorkstationPrintSettings;
		If ValueIsFilled(vWorkstationPrintSettings) Then
			// Try to find records for the current object print form
			vFilter = New Structure("ObjectPrintingForm, IsActive", pObjectPrintForm, True); 
			vPrintSettingsSet = vWorkstationPrintSettings.PrintFormsList.FindRows(vFilter);
			If vPrintSettingsSet.Count() > 0 Then
				For Each vPrintSettings In vPrintSettingsSet Do
					// Fill settings
					cmSetSpreadsheetSettings(pSpreadsheet, vPrintSettings);
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PrintSelectedCharges

// -----------------------------------------------------------------------------
//  Print income cash order
//
// Parameters:
//  pSpreadsheet	 - SpreadsheetDocument	 - SpreadsheetDocument
//  pTemplete		 - Templete				 - Templete
//  pPaymentList	 - ValueList			 - Documents payment list
//  pObjectPrintForm - PrintForm			 - PrintForm
// 
// Returns:
//  SpreadsheetDocument - Result
//
Function PrintPKO(pSpreadsheet, pTemplete, pPaymentList, pObjectPrintForm) Export 
	vErr = "";
	
	// Language
	vLanguage = SessionParameters.CurrentLanguage;
	If ValueIsFilled(pObjectPrintForm) And ValueIsFilled(pObjectPrintForm.Language) Then
		vLanguage = pObjectPrintForm.Language;
	EndIf;
	
	// Clear output spreadsheet
	pSpreadsheet = ?(pSpreadsheet = Undefined, New SpreadsheetDocument, pSpreadsheet);
	pSpreadsheet.Clear();
	
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(pObjectPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	Else
		vTemplate = pTemplete;
	EndIf;
	
	For Each vInd In pPaymentList Do
		
		Document = vInd.Value;
		
		vParameters = New Structure;
		vParameters.Insert("mHotelName");
		vParameters.Insert("mCompanyName");
		vParameters.Insert("mCompanyTIN");
		vParameters.Insert("mCompanyKPP");
		vParameters.Insert("mCompanyOKPOCode");
		vParameters.Insert("mCompanyOKDP");
		vParameters.Insert("mCompanyDepartment");
		vParameters.Insert("mCompanyAddress");
		vParameters.Insert("mDebetAccount");
		vParameters.Insert("mCreditAccount");
		vParameters.Insert("mReason");
		vParameters.Insert("mSupplement");
		vParameters.Insert("mDirectorPosition");
		vParameters.Insert("mDirectorName");
		vParameters.Insert("mCashierName");
		vParameters.Insert("mAccountantGeneralName");
		vParameters.Insert("mGuestName");
		vParameters.Insert("mGuestAddress1");
		vParameters.Insert("mGuestAddress2");
		vParameters.Insert("mGuestIDType");
		vParameters.Insert("mGuestIDSeries");
		vParameters.Insert("mGuestIDNumber");
		vParameters.Insert("mGuestIDIssued");
		vParameters.Insert("mRoom");
		vParameters.Insert("mCheckInDate");
		vParameters.Insert("mCheckOutDate");
		vParameters.Insert("mSum");
		vParameters.Insert("mSumInWords");
		vParameters.Insert("mSumCurr");
		vParameters.Insert("mPaymentNumber");
		vParameters.Insert("mDate");
		vParameters.Insert("mAuthor");
		vParameters.Insert("mCurrency");
		vParameters.Insert("mVatSum");
		vParameters.Insert("mRemarks");
		
		// Fill parameters
		vHotel = Undefined;
		If ValueIsFilled(Document) Then
			If ValueIsFilled(Document.Hotel) Then
				vHotel = Document.Hotel;
			EndIf;
		ElsIf ValueIsFilled(SessionParameters.CurrentHotel) Then
			vHotel = SessionParameters.CurrentHotel;
		EndIf;
		vCompany = Undefined;
		If ValueIsFilled(Document) Then
			If ValueIsFilled(Document.Company) Then
				vCompany = Document.Company;
			EndIf;
		ElsIf ValueIsFilled(vHotel) Then
			vCompany = vHotel.Company;
		EndIf;
		If ValueIsFilled(vCompany) Then
			// Hotel name
			vHotelName = TrimAll(vHotel.LegacyName);
			If IsBlankString(vHotelName) Then
				vHotelName = TrimAll(vHotel.Description);
			EndIf;
			vParameters.mHotelName = vHotelName;
			
			// Company name
			vCompanyName = TrimAll(vCompany.LegacyName);
			If IsBlankString(vCompanyName) Then
				vCompanyName = TrimAll(vCompany.Description);
			EndIf;
			vParameters.mCompanyName = vCompanyName;
			
			// Company parameters
			vParameters.mDirectorName = cmNStr(vCompany.Director, vLanguage);
			vParameters.mCompanyTIN = TrimAll(vCompany.TIN);
			vParameters.mCompanyKPP = TrimAll(vCompany.KPP);
			vParameters.mCompanyOKPOCode = TrimAll(vCompany.OKPO);
			vParameters.mCompanyOKDP = TrimAll(vCompany.OKDP);
			vParameters.mCompanyAddress = cmGetAddressPresentation(vCompany.LegacyAddress);
			vParameters.mCashierName = cmNStr(vCompany.CashierGeneral, vLanguage);
			If ValueIsFilled(SessionParameters.CurrentUser) And vCompany.RKOShowCurrentManagerAsCashier Then
				vParameters.mCashierName = SessionParameters.CurrentUser.GetObject().pmGetEmployeeDescription(vLanguage);
			EndIf;
			vParameters.mAccountantGeneralName = cmNStr(vCompany.AccountantGeneral, vLanguage);
			
			// Debet/credit account
			vParameters.mDebetAccount = "50.01";
			vParameters.mCreditAccount = "62.Р";
			
			// Reason
			If IsBlankString(vCompany.RKOReason) Then
				vParameters.mReason = "";
			Else
				vParameters.mReason = TrimAll(vCompany.RKOReason);
			EndIf;
			
			// Supplement
			vParameters.mSupplement = "";
					
			// Forms date
			vParameters.mDate = Document.Date;
			
			vParameters.mPaymentNumber = cmCastToNumber(Document.Number);
			
			vParentDoc = Document.ParentDoc;
			
			// Guest
			vGuest = "";
			vPeriod = "";
			If ValueIsFilled(vParentDoc) Then
				vGuest = vParentDoc.Guest;
				vPeriod = Format(vParentDoc.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(vParentDoc.CheckOutDate, "DF='dd.MM.yyyy HH:mm'");
			EndIf;	
			If ValueIsFilled(vGuest) Then
				// Guest name
				vParameters.mGuestName = TrimAll(vGuest.LastName) + " " + 
				TrimAll(vGuest.FirstName) + " " + 
				TrimAll(vGuest.SecondName);
				
				If Not IsBlankString(vPeriod) Then
					vParameters.mGuestName = vParameters.mGuestName + ", " + vPeriod;
				EndIf;	
			EndIf;
			vParameters.mRemarks = "";
			vSum = Document.Sum;
			vParameters.mSum = Format(vSum, "ND=17; NFD=2");
			vParameters.mSumInWords = cmSumInWords(vSum, Document.PaymentCurrency, vLanguage);
			vParameters.mCurrency = TrimAll(Document.PaymentCurrency);
			vParameters.mAuthor = Document.Author;
			vParameters.mSumCurr = cmFormatSum(vSum,Document.PaymentCurrency, , vLanguage, False);	
			If Document.VATSum>0 Then      
				vSumPres = cmFormatSum(Document.VATSum, Document.PaymentCurrency, , Catalogs.Languages.RU, False); 
				vParameters.mVatSum = StrTemplate(cmNStr("en = 'VAT(%1) %2'; de = 'Mehrwertsteuer (%1) %2'; ru = 'НДС(%1) %2'", vLanguage), String(Document.VATRate), vSumPres);
			EndIf;
			If Document.PaymentSections.Count()>0 Then
				vTran = Document.PaymentSections[0];
				If ValueIsFilled(vTran.ChequeService) Then
					If Not IsBlankString(vTran.ChequeService.DescriptionTranslations) Then
						vParameters.mRemarks = cmNStr(vTran.ChequeService.DescriptionTranslations, vLanguage);
					Else	
						vParameters.mRemarks = vTran.ChequeService.Description;
					EndIf;
				ElsIf ValueIsFilled(vTran.PaymentSection) Then
					If Not IsBlankString(vTran.ChequeService.DescriptionTranslations) Then
						vParameters.mRemarks = cmNStr(vTran.PaymentSection.DescriptionTranslations, vLanguage);
					Else	
						vParameters.mRemarks = TrimAll(vTran.PaymentSection.Description);
					EndIf;
				EndIf;	
			EndIf;	
		Else
			// Hotel name
			vParameters.mHotelName = "";
			// Company name
			vParameters.mCompanyName = "";
			
			// Company parameters
			vParameters.mDirectorName = "";
			vParameters.mCompanyTIN = "";
			vParameters.mCompanyKPP = "";
			vParameters.mCompanyOKPOCode = "";
			vParameters.mCompanyAddress = "";
			vParameters.mCashierName = "";
			vParameters.mAccountantGeneralName = "";
			
			// Debet account, reason, supplement and director position
			// Debet/credit account
			vParameters.mDebetAccount = "50.01";
			vParameters.mCreditAccount = "62.Р";
			vParameters.mGuestName = "";
			vParameters.mReason = "";
			vParameters.mSupplement = "";
			
			// Forms date
			vParameters.mDate = Document.Date;
			vParameters.mDocNumber = "";
			
			vParameters.mSum = "";
			vParameters.mSumInWords = "";
			vParameters.mCurrency = "";
			vParameters.mAuthor = "";
		EndIf;
		vHeader = pTemplete.GetArea("Header");
		FillPropertyValues(vHeader.Parameters, vParameters);
		pSpreadsheet.Put(vHeader);
	EndDo;
	Return vErr;	
EndFunction	       

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - DocimentRef.Folio - Ref
//  pReceiverNode	 - Node	 - Ref
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Hotel, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function FillBonuses(pFolio, pLanguage)
	vBonusesStr = "";
	If ValueIsFilled(pFolio) Then
		// Check if discount card is choosen
		vDiscountCard = Undefined;
		If ValueIsFilled(pFolio.ParentDoc) And ValueIsFilled(pFolio.ParentDoc.DiscountCard) And 
			ValueIsFilled(pFolio.ParentDoc.DiscountCard.DiscountType) And 
			pFolio.ParentDoc.DiscountCard.DiscountType.BonusCalculationFactor <> 0 Then
			vDiscountCard = pFolio.ParentDoc.DiscountCard;
		EndIf;
		If ValueIsFilled(vDiscountCard) Then
			vDiscountTypeObj = vDiscountCard.DiscountType.GetObject();
			vBonuses = vDiscountTypeObj.pmGetAccumulatingDiscountResources(CurrentSessionDate(), , , , vDiscountCard);
			If vBonuses.Count() > 0 Then
				vBonusesRow = vBonuses.Get(0);
				If vBonusesRow.Bonus <> 0 Then
					vBonusesStr = StrTemplate(cmNStr("en = 'Bonuses %1 (%2)'; de = 'Bonuses %1 (%2)'; ru = 'Накоплено %1 бонусов (%2)'", pLanguage), vBonusesRow.Bonus, TrimAll(vDiscountTypeObj.Code));
				EndIf;
			EndIf;
		Else
			vClient = pFolio.Client;
			If ValueIsFilled(vClient) Then
				// Check if discount type is directly assigned in the parent document
				vDiscountType = Undefined;
				If ValueIsFilled(pFolio.ParentDoc) And ValueIsFilled(pFolio.ParentDoc.DiscountType) And 
					pFolio.ParentDoc.DiscountType.HasToBeDirectlyAssigned And 
					pFolio.ParentDoc.DiscountType.BonusCalculationFactor <> 0 Then
					vDiscountType = pFolio.ParentDoc.DiscountType;
				EndIf;
				vDiscountTypes = cmGetBonusDiscountTypes(vDiscountType);
				For Each vDiscountTypesRow In vDiscountTypes Do
					vDiscountTypeObj = vDiscountTypesRow.DiscountType.GetObject();
					vBonuses = vDiscountTypeObj.pmGetAccumulatingDiscountResources(CurrentSessionDate(), , , vClient);
					If vBonuses.Count() > 0 Then
						vBonusesRow = vBonuses.Get(0);
						If vBonusesRow.Bonus <> 0 Then
							If IsBlankString(vBonusesStr) Then
								vBonusesStr = StrTemplate(cmNStr("en = 'Bonuses %1 (%2)'; de = 'Bonuses %1 (%2)'; ru = 'Накоплено %1 бонусов (%2)'", pLanguage), vBonusesRow.Bonus, TrimAll(vDiscountTypeObj.Code));
							Else
								vBonusesStr = vBonusesStr + Chars.LF + Chars.Tab + Chars.Tab + vBonusesRow.Bonus 
								+ " (" + TrimAll(vDiscountTypeObj.Code) + ")";
							EndIf;
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	Return vBonusesStr;
EndFunction // FillBonuses

#EndRegion
