
#Region Public

// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Filter.Hotel.Value, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

// --------------------------------------------------------------------------------
Procedure Print(pHotel, pSpreadsheet, pObjectListForPrint, pLanguage) Export
	// Basic checks  	
	If ValueIsFilled(pHotel) Then
		vHotel = pHotel;
	Else
		vHotel = SessionParameters.CurrentHotel;    
	EndIf;
	If Not ValueIsFilled(vHotel) Then
		vMessage = NStr("en = 'Default hotel should be selected!'; de = 'Das aktuelle Hotel ist nicht angegeben!'; ru = 'Не задана текущая гостиница!'"); 
		tcCommonFunctionOnClientServer.UserMessage(vMessage);
		Return;
	EndIf;
	
	If ValueIsFilled(pHotel.Company) Then
		vCompany = pHotel.Company;
	Else
		vCompany = vHotel.Company;
	EndIf;
	If Not ValueIsFilled(vCompany) Then
		vMessage = NStr("en = 'Default hotel company should be selected!'; de = 'Beim Hotel muss standardmäßig eine Firma festgelegt sein!'; ru = 'У гостиницы должна быть указана фирма по умолчанию!'");  
		tcCommonFunctionOnClientServer.UserMessage(vMessage);
		Return;
	EndIf;
	If Not ValueIsFilled(pLanguage) Then
		pLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	
	// Choose template
	pSpreadsheet.Clear();
	If ValueIsFilled(pLanguage) Then
		If pLanguage = Catalogs.Languages.EN Then
			vTemplate = InformationRegisters.LostAndFound.GetTemplate("LostItemsEn");
		ElsIf pLanguage = Catalogs.Languages.RU Then
			vTemplate = InformationRegisters.LostAndFound.GetTemplate("LostItemsRu");
		ElsIf pLanguage = Catalogs.Languages.DE Then
			vTemplate = InformationRegisters.LostAndFound.GetTemplate("LostItemsDe");
		Else
			tcCommonFunctionOnClientServer.UserMessage(NStr("ru='Не найден шаблон печатной формы бланка возврата для языка " + pLanguage.Code + "!'; 
			                  |de='No print form template found for the " + pLanguage.Code + " language!'; 
			                  |en='No print form template found for the " + pLanguage.Code + " language!'"));
			Return;
		EndIf;
	Else
		vTemplate = InformationRegisters.LostAndFound.GetTemplate("LostItemsRu");  		
	EndIf;
		
	// Load pictures
	vLogoIsSet = False;
	vLogo = New Picture;
	If ValueIsFilled(pHotel) Then
		If pHotel.Logo <> Undefined Then
			vLogo = pHotel.Logo.Get();
			If vLogo = Undefined Then
				vLogo = New Picture;
			Else
				vLogoIsSet = True;
			EndIf;
		EndIf;
	EndIf;
	
	// Build header structure
	vHeaderStruct = New Structure("mHotelPrintName, mHotelPostAddressPresentation, mHotelPhones, mCompanyLegacyName, mCompanyTIN", "", "", "", "", "");
	// Header
	vHeader = vTemplate.GetArea("Header");	
	For Each vSelRowItem In pObjectListForPrint Do
		vSelRow = vSelRowItem.Value;
		
		vRcd = InformationRegisters.LostAndFound.CreateRecordManager();
		FillPropertyValues(vRcd, vSelRow);
		vRcd.Read();
		
		// Put row
		If vRcd.Code <> 0 Then
			// Hotel
			vHeader.Parameters.mHotelPrintName = Catalogs.Hotels.pmGetHotelPrintName(vHotel, pLanguage);
			vHeader.Parameters.mHotelPostAddressPresentation = Catalogs.Hotels.pmGetHotelPostAddressPresentation(vHotel, pLanguage);
			vHotelPhones = TrimAll(vHotel.Phones);
			vHotelEMail = TrimAll(vHotel.EMail);
			vHotelFax = TrimAll(vHotel.Fax);
			vHeader.Parameters.mHotelPhones = vHotelPhones + ?(IsBlankString(vHotelFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", pLanguage) + vHotelFax);
			
			// Company
			vHeader.Parameters.mCompanyLegacyName = TrimAll(vCompany.GetObject().pmGetCompanyPrintName(pLanguage));
			vCompanyTIN = TrimAll(vCompany.TIN);
			vCompanyKPP = TrimAll(vCompany.KPP);
			vHeader.Parameters.mCompanyTIN = ?(IsBlankString(vCompanyTIN), "", cmNStr("en = 'TIN '; de = 'INN '; ru = 'ИНН '", pLanguage) + vCompanyTIN) + ?(IsBlankString(vCompanyKPP), "", "/КПП " + vCompanyKPP);
			If vHeader.Parameters.mCompanyLegacyName = vHeaderStruct.mHotelPrintName Then
				vHeader.Parameters.mCompanyLegacyName = vHeaderStruct.mCompanyTIN;
				vHeader.Parameters.mCompanyTIN = "";
			EndIf;
			
			// Logo
			If vLogoIsSet Then
				vHeader.Drawings.Logo.Print = True;
				vHeader.Drawings.Logo.Picture = vLogo;
			Else
				vHeader.Drawings.Delete(vHeader.Drawings.Logo);
			EndIf;		
			vHeader.Parameters.mNumber = vRcd.Code;
			vHeader.Parameters.mDate = Format(vRcd.DateWhenFound, "DF=dd.MM.yyyy" );
			vHeader.Parameters.mDescription = vRcd.Remarks;
			vHeader.Parameters.mRoom = vRcd.Room;
			vHeader.Parameters.mGuest = vRcd.Guest;
			vHeader.Parameters.mPlace = vRcd.StorePlace;
			vHeader.Parameters.mFindEmployee = vRcd.FoundBy;
			vHeader.Parameters.mReturnEmployee = vRcd.ReturnedBy;
			vHeader.Parameters.mReturnedPerson = vRcd.DeliveredTo;
			vHeader.Parameters.mReturnDate = Format(vRcd.DateWhenReturned, "DF=dd.MM.yyyy" );		
			
			pSpreadsheet.Put(vHeader);
		EndIf;
	EndDo;		  
EndProcedure // Print

// --------------------------------------------------------------------------------
Procedure PrintRegistration(pHotel, pSpreadsheet, pObjectListForPrint, pLanguage) Export
	// Basic checks  	
	If ValueIsFilled(pHotel) Then
		vHotel = pHotel;
	Else
		vHotel = SessionParameters.CurrentHotel;    
	EndIf;
	If Not ValueIsFilled(vHotel) Then
		vMessage = NStr("en = 'Default hotel should be selected!'; de = 'Das aktuelle Hotel ist nicht angegeben!'; ru = 'Не задана текущая гостиница!'"); 
		tcCommonFunctionOnClientServer.UserMessage(vMessage);
		Return;
	EndIf;
	If Not ValueIsFilled(pLanguage) Then
		pLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	
	// Choose template
	pSpreadsheet.Clear();
	If ValueIsFilled(pLanguage) Then
		If pLanguage = Catalogs.Languages.EN Then
			vTemplate = InformationRegisters.LostAndFound.GetTemplate("ItemCardEn");
		ElsIf pLanguage = Catalogs.Languages.RU Then
			vTemplate = InformationRegisters.LostAndFound.GetTemplate("ItemCardRu");
		ElsIf pLanguage = Catalogs.Languages.DE Then
			vTemplate = InformationRegisters.LostAndFound.GetTemplate("ItemCardDe");
		Else
			tcCommonFunctionOnClientServer.UserMessage(NStr("ru='Не найден шаблон печатной формы бланка возврата для языка " + pLanguage.Code + "!'; 
			                  |de='No print form template found for the " + pLanguage.Code + " language!'; 
			                  |en='No print form template found for the " + pLanguage.Code + " language!'"));
			Return;
		EndIf;
	Else
		vTemplate = InformationRegisters.LostAndFound.GetTemplate("ItemCardRu");  		
	EndIf;
	
	// Build header structure
	vHeaderStruct = New Structure("mHotel", "");
	
	// Header
	vHeader = vTemplate.GetArea("Header");	
	For Each vSelRowItem In pObjectListForPrint Do
		vSelRow = vSelRowItem.Value;
		
		vRcd = InformationRegisters.LostAndFound.CreateRecordManager();
		FillPropertyValues(vRcd, vSelRow);
		vRcd.Read();
		
		// Put row
		If vRcd.Code <> 0 Then
			vHeader.Parameters.mHotel = Catalogs.Hotels.pmGetHotelPrintName(vHotel, pLanguage);
			vHeader.Parameters.mCode = vRcd.Code;
			vHeader.Parameters.mDateWhenFound = Format(vRcd.DateWhenFound, "DF=dd.MM.yyyy" );
			vHeader.Parameters.mRemarks = vRcd.Remarks;
			vHeader.Parameters.mRoomNumber = ?(ValueIsFilled(vRcd.Room) And TypeOf(vRcd.Room) = Type("CatalogRef.Rooms"), vRcd.Room, Undefined);
			vHeader.Parameters.mRoom = vRcd.Room;
			vHeader.Parameters.mGuest = vRcd.Guest;
			vHeader.Parameters.mGuestGroup = vRcd.GuestGroup;
			vHeader.Parameters.mFoundBy = vRcd.FoundBy;
			vHeader.Parameters.mAuthor = vRcd.Author;
			
			pSpreadsheet.Put(vHeader);
		EndIf;
	EndDo;		  
EndProcedure // PrintRegistration

#EndRegion
