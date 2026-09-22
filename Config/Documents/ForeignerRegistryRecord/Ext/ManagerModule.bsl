
#Region Public

// -----------------------------------------------------------------------------
Procedure Print(pRef, pForm, pEmployee, pSpreadsheet = Undefined, pMessage, rDoPrint = Undefined) Export 
	vSpreadsheet = ?(pSpreadsheet = Undefined, New SpreadsheetDocument, pSpreadsheet);;
	// Check predefined forms
	If pForm = Catalogs.ObjectPrintingForms.ForeignerRegistryRecordPrintNotificationForm Then
		PrintNotification(pRef, pForm.Language, pForm, pEmployee, vSpreadsheet, rDoPrint);
	ElsIf pForm = Catalogs.ObjectPrintingForms.ForeignerRegistryRecordPrintDepartureNotificationForm Then
		PrintNotification(pRef, pForm.Language, pForm, pEmployee, vSpreadsheet, rDoPrint);
	ElsIf pForm = Catalogs.ObjectPrintingForms.ForeignerRegistryRecordPrintArrivalSheetForm Then
		PrintAddressSheet(pRef, pForm.Language, pForm, vSpreadsheet, rDoPrint);
	ElsIf pForm = Catalogs.ObjectPrintingForms.ForeignerRegistryRecordPrintForeignerCardForm Then
		PrintForeignerCard(pRef, pForm.Language, pForm, vSpreadsheet, rDoPrint);
	ElsIf pForm = Catalogs.ObjectPrintingForms.ForeignerRegistryRecordPrintAllClientDataScans Then
		PrintAllClientDataScans(pRef, pForm.Language, pForm, vSpreadsheet);
	Else
		pMessage = NStr("en='No print form processor found!';ru='В настройках печатной формы не задан обработчик!';de='In den Einstellungen der Druckunterlagen wurde kein Bearbeiter vorgegeben!'");
	EndIf;
EndProcedure	

// -----------------------------------------------------------------------------
Procedure PrintAllClientDataScans(pRef, pLang, pForm, pSpreadsheet)
	vTemplate = Documents.ClientDataScans.GetTemplate("PicturePrintTemplate");
	vClientDataScans = Documents.ForeignerRegistryRecord.pmGetClientDataScansDocument(pRef);
	If ValueIsFilled(vClientDataScans) Then
		// Get current row
		For Each vCurRow In vClientDataScans.ScanPictures Do
			vPicture = vCurRow.ScanPicture.Get();
			If vPicture = Undefined Then
				Continue;
			ElsIf TypeOf(vPicture) = Type("String") Then
				vPicture = New Picture(Documents.ForeignerRegistryRecord.pmGetImageCatalogName(pRef) + TrimAll(vPicture));
			EndIf;
			If vClientDataScans.ScanPictures.IndexOf(vCurRow) > 0 Then
				pSpreadsheet.PutHorizontalPageBreak();
			EndIf;
			// Put picture there
			vPictureArea = vTemplate.GetArea("Picture");
			vPictureArea.Drawings.ScanPicture.Print = True;
			vPictureArea.Drawings.ScanPicture.Picture = vPicture;
			pSpreadsheet.Put(vPictureArea);
		EndDo;
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Client data scans were not found!'; ru='Не найдены сканы документов клиента!'; de='Die Scans Dokumente des Kunden ist nict gefunden!'"));
	EndIf;
EndProcedure // PrintAllClientDataScans

// -----------------------------------------------------------------------------
Procedure PrintNotification(pRef, pLanguage, pForm, pEmployee, pSpreadsheet, rDoPrint = Undefined)
	// Choose template
	vRegObj = pRef.GetObject();
	vSpreadsheet = pSpreadsheet;
	vSpreadsheet.Clear();
	
	vTemplate = Undefined;
	
	vPage1 = Undefined;
	vPage2 = Undefined;
	vPage3 = Undefined;
	vPage4 = Undefined;
	
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(pForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;
	
	// Fill template parameters
	If pForm = Catalogs.ObjectPrintingForms.ForeignerRegistryRecordPrintDepartureNotificationForm Then
		If vTemplate = Undefined Then
			If vRegObj.Hotel.PrintForeignerDepartureNotificationApplication Then
				vTemplate = vRegObj.GetTemplate("ForeignerDepartureNotification");
			Else
				vTemplate = vRegObj.GetTemplate("ForeignerDepartureNotification20200914");
			EndIf;
		EndIf;
		
		// Pages
		vPage1 = vTemplate.GetArea("Page1");
		vPage2 = vTemplate.GetArea("Page2");
		
		If vRegObj.Hotel.PrintForeignerDepartureNotificationApplication Then
			SetParametersForDepartureNotificationPages(vPage1, vPage2, pRef, pEmployee);
		Else
			SetParametersForDepartureNotificationPages20200914(vPage1, vPage2, pRef, pEmployee);
		EndIf;
		
		// Put page 1
		vSpreadsheet.Put(vPage1);
		// New page
		vSpreadsheet.PutHorizontalPageBreak();
		// Put page 2
		vSpreadsheet.Put(vPage2);
	Else
		If vRegObj.CheckInDate >= '20250205' Then
			If vTemplate = Undefined Then
				vTemplate = vRegObj.GetTemplate("ForeignerNotification20250205");
			EndIf;
			
			// Pages
			vPage1 = vTemplate.GetArea("Page1");
			vPage2 = vTemplate.GetArea("Page2");
			vPage3 = vTemplate.GetArea("Page3");
			vPage4 = vTemplate.GetArea("Page4");
			
			SetParametersNotificationForPages20250205(vPage1, vPage2, vPage3, vPage4, pRef, pEmployee);
			
			// Put page 1
			vSpreadsheet.Put(vPage1);
			// New page
			vSpreadsheet.PutHorizontalPageBreak();
			// Put page 2
			vSpreadsheet.Put(vPage2);
			// New page
			vSpreadsheet.PutHorizontalPageBreak();
			// Put page 3
			vSpreadsheet.Put(vPage3);
			// New page
			vSpreadsheet.PutHorizontalPageBreak();
			// Put page 4
			vSpreadsheet.Put(vPage4);
		ElsIf vRegObj.CheckInDate >= '20230101' Then
			If vTemplate = Undefined Then
				vTemplate = vRegObj.GetTemplate("ForeignerNotification20230101");
			EndIf;
			
			// Pages
			vPage1 = vTemplate.GetArea("Page1");
			vPage2 = vTemplate.GetArea("Page2");
			vPage3 = vTemplate.GetArea("Page3");
			vPage4 = vTemplate.GetArea("Page4");
			
			SetParametersNotificationForPages20230101(vPage1, vPage2, vPage3, vPage4, pRef, pEmployee);
			
			// Put page 1
			vSpreadsheet.Put(vPage1);
			// New page
			vSpreadsheet.PutHorizontalPageBreak();
			// Put page 2
			vSpreadsheet.Put(vPage2);
			// New page
			vSpreadsheet.PutHorizontalPageBreak();
			// Put page 3
			vSpreadsheet.Put(vPage3);
			// New page
			vSpreadsheet.PutHorizontalPageBreak();
			// Put page 4
			vSpreadsheet.Put(vPage4);
		ElsIf vRegObj.CheckInDate >= '20210223' Then
			If vTemplate = Undefined Then
				vTemplate = vRegObj.GetTemplate("ForeignerNotification20210223");
			EndIf;
			
			// Pages
			vPage1 = vTemplate.GetArea("Page1");
			vPage2 = vTemplate.GetArea("Page2");
			vPage3 = vTemplate.GetArea("Page3");
			vPage4 = vTemplate.GetArea("Page4");
			
			SetParametersNotificationForPages20210223(vPage1, vPage2, vPage3, vPage4, pRef, pEmployee);
			
			// Put page 1
			vSpreadsheet.Put(vPage1);
			// New page
			vSpreadsheet.PutHorizontalPageBreak();
			// Put page 2
			vSpreadsheet.Put(vPage2);
			// New page
			vSpreadsheet.PutHorizontalPageBreak();
			// Put page 3
			vSpreadsheet.Put(vPage3);
			// New page
			vSpreadsheet.PutHorizontalPageBreak();
			// Put page 4
			vSpreadsheet.Put(vPage4);
		ElsIf ValueIsFilled(vRegObj.ParentDoc) And ValueIsFilled(vRegObj.ParentDoc.Company) And 
		      Not IsBlankString(vRegObj.ParentDoc.Company.DocumentGivingRightToProvidePremises) Then
			If vTemplate = Undefined Then
				vTemplate = vRegObj.GetTemplate("ForeignerNotification20200914");
			EndIf;
			
			// Pages
			vPage1 = vTemplate.GetArea("Page1");
			vPage2 = vTemplate.GetArea("Page2");
			
			SetParametersNotificationForPages20200914(vPage1, vPage2, pRef, pEmployee);
			
			// Put page 1
			vSpreadsheet.Put(vPage1);
			// New page
			vSpreadsheet.PutHorizontalPageBreak();
			// Put page 2
			vSpreadsheet.Put(vPage2);
		Else
			If vTemplate = Undefined Then
				vTemplate = vRegObj.GetTemplate("ForeignerNotification20171123");
			EndIf;
			
			// Pages
			vPage1 = vTemplate.GetArea("Page1");
			vPage2 = vTemplate.GetArea("Page2");
			
			SetParametersNotificationForPages20171123(vPage1, vPage2, pRef, pEmployee);
			
			// Put page 1
			vSpreadsheet.Put(vPage1);
			// New page
			vSpreadsheet.PutHorizontalPageBreak();
			// Put page 2
			vSpreadsheet.Put(vPage2);
		EndIf;
	EndIf;

	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Portrait, True);
	vSpreadsheet.TopMargin = 0;
	vSpreadsheet.BottomMargin = 0;
	vSpreadsheet.DuplexPrinting = DuplexPrintingType.UsePrinterSettings;
	// Check authorities
	cmSetSpreadsheetProtection(vSpreadsheet);
	// Get and fill workstation print form settings
	If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
		vWorkstationPrintSettings = SessionParameters.CurrentWorkstation.WorkstationPrintSettings;
		If ValueIsFilled(vWorkstationPrintSettings) Then
			// Try to find records for the current object print form
			vFilter = New Structure("ObjectPrintingForm, IsActive", pForm, True); 
			vPrintSettingsSet = vWorkstationPrintSettings.PrintFormsList.FindRows(vFilter);
			If vPrintSettingsSet.Count() > 0 Then
				For Each vPrintSettings In vPrintSettingsSet Do
					// Fill settings
					cmSetSpreadsheetSettings(vSpreadsheet, vPrintSettings);
					// Check printing direction
					If vPrintSettings.PrintDirection <> Enums.PrintDirections.Screen Then
						vName = cmGetPrintFormFileName(vPrintSettings, NStr("en='Notification';ru='Уведомление';de='Benachrichtigung'")) + " " + TrimAll(pRef.Number);
						cmDoSpreadsheetOutput(vSpreadsheet, vPrintSettings, vName, , rDoPrint);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PrintNotification

// -----------------------------------------------------------------------------
Procedure PrintAddressSheet(pRef, pLanguage,pForm, pSpreadsheet, rDoPrint = Undefined)
	// Choose template
	vRegObj = pRef.GetObject();
	vSpreadsheet = pSpreadsheet;
	vSpreadsheet.Clear();
	vTemplate = vRegObj.GetTemplate("AddressArrivalSheet");
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(pForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;
	
	// Pages 1 and 2
	vPage11 = vTemplate.GetArea("Page11");
	vSex = Undefined;
	If pRef.Sex = Enums.Sex.Female Then
		vSex = vTemplate.GetArea("SexF");
	Else
		vSex = vTemplate.GetArea("SexM");
	EndIf;
	vPage12 = vTemplate.GetArea("Page12");
	vPage2 = vTemplate.GetArea("Page2");
	
	// Calculate and set parameters
	SetParametersAddressSheetForPages(vPage11, vPage12, vPage2, pRef);
	
	// Put page 1
	vSpreadsheet.Put(vPage11);
	vSpreadsheet.Put(vSex);
	vSpreadsheet.Put(vPage12);
	// New page
	vSpreadsheet.PutHorizontalPageBreak();
	// Put page 2
	vSpreadsheet.Put(vPage2);
	
	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Portrait, True);
	// Check authorities
	cmSetSpreadsheetProtection(vSpreadsheet);
	// Get and fill workstation print form settings
	If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
		vWorkstationPrintSettings = SessionParameters.CurrentWorkstation.WorkstationPrintSettings;
		If ValueIsFilled(vWorkstationPrintSettings) Then
			// Try to find records for the current object print form
			vFilter = New Structure("ObjectPrintingForm, IsActive", pForm, True); 
			vPrintSettingsSet = vWorkstationPrintSettings.PrintFormsList.FindRows(vFilter);
			If vPrintSettingsSet.Count() > 0 Then
				For Each vPrintSettings In vPrintSettingsSet Do
					// Fill settings
					cmSetSpreadsheetSettings(vSpreadsheet, vPrintSettings);
					// Check printing direction
					If vPrintSettings.PrintDirection <> Enums.PrintDirections.Screen Then
						vName = cmGetPrintFormFileName(vPrintSettings, NStr("en='Address arrival sheet';ru='Адресный листок прибытия';de='Meldeschein Ankunft'")) + " " + TrimAll(pRef.Number);
						cmDoSpreadsheetOutput(vSpreadsheet, vPrintSettings, vName, , rDoPrint);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PrintAddressSheet

// -----------------------------------------------------------------------------
Procedure PrintForeignerCard(pRef, pLanguage,pForm, pSpreadsheet, rDoPrint = Undefined)
	// Choose template
	vRegObj = pRef.GetObject();
	vSpreadsheet = pSpreadsheet;
	vSpreadsheet.Clear();
	vTemplate = vRegObj.GetTemplate("ForeignerCard");
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(pForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;
	
	// Card template
	vPage = vTemplate.GetArea("Card");
	
	// Calculate and set parameters
	SetParameters(vPage, pRef);
	
	// Put page 1
	vSpreadsheet.Put(vPage);

	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Portrait, True);
	// Check authorities
	cmSetSpreadsheetProtection(vSpreadsheet);
	// Get and fill workstation print form settings
	If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
		vWorkstationPrintSettings = SessionParameters.CurrentWorkstation.WorkstationPrintSettings;
		If ValueIsFilled(vWorkstationPrintSettings) Then
			// Try to find records for the current object print form
			vFilter = New Structure("ObjectPrintingForm, IsActive", pForm, True); 
			vPrintSettingsSet = vWorkstationPrintSettings.PrintFormsList.FindRows(vFilter);
			If vPrintSettingsSet.Count() > 0 Then
				For Each vPrintSettings In vPrintSettingsSet Do
					// Fill settings
					cmSetSpreadsheetSettings(vSpreadsheet, vPrintSettings);
					// Check printing direction
					If vPrintSettings.PrintDirection <> Enums.PrintDirections.Screen Then
						vName = cmGetPrintFormFileName(vPrintSettings, NStr("en='Foreigner guest card';ru='Карточка учета проживания иностранного гражданина';de='Karte für die Anmeldung eines ausländisches Gastes'")) + " " + TrimAll(pRef.Number);
						cmDoSpreadsheetOutput(vSpreadsheet, vPrintSettings, vName, , rDoPrint);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PrintForeignerCard

// -----------------------------------------------------------------------------
Procedure SetParametersForDepartureNotificationPages(pPage1, pPage2, pRef, pEmployee) Export
	vHotel = pRef.Hotel;
	
	pPage1.Parameters.mOfficialOrganName1 = TrimAll(Mid(vHotel.MigrationOfficeName, 1, 30));
	pPage1.Parameters.mOfficialOrganName2 = TrimAll(Mid(vHotel.MigrationOfficeName, 31, 30));
	pPage1.Parameters.mOfficialOrganName3 = TrimAll(Mid(vHotel.MigrationOfficeName, 61, 30));
	pPage1.Parameters.mOfficialOrganName4 = TrimAll(Mid(vHotel.MigrationOfficeName, 91, 30));
	pPage1.Parameters.mOfficialOrganName5 = TrimAll(Mid(vHotel.MigrationOfficeName, 121, 30));
	
	// Try to fill guest data	
	If ValueIsFilled(pRef.Guest) Then
		pPage1.Parameters.mGuestFullName = TrimAll(TrimAll(pRef.LastName) + " " + TrimAll(pRef.FirstName) + " " + TrimAll(pRef.SecondName));
		pPage1.Parameters.mGuestDateOfBirth = Format(pRef.DateOfBirth, "DF=dd.MM.yyyy");
		pPage1.Parameters.mGuestCitizenship = TrimAll(pRef.Citizenship);
	Else // Guest is not selected, so fill all guest data with blanks
		pPage1.Parameters.mGuestFullName = "";
		pPage1.Parameters.mGuestDateOfBirth = "";
		pPage1.Parameters.mGuestCitizenship = "";
	EndIf;
	
	// Hotel address
	vHotelAddressStr = "";
	If ValueIsFilled(vHotel) And Not IsBlankString(vHotel.PostAddress) Then
		vHotelAddressStr = vHotel.PostAddress;
		
		vAddress = cmParseAddress(vHotelAddressStr);
		
		pPage1.Parameters.mHotelAddress1 = TrimAll(vAddress.Region);
		pPage1.Parameters.mHotelAddress2 = TrimAll(vAddress.Area) + ", " + TrimAll(vAddress.City);
		
		vHouse = TrimAll(vAddress.House);
		vBuilding = "";
		vHouseBuilding = "";
		ParseHouseNumber(vHouse, vBuilding, vHouseBuilding);
		vFlat = vAddress.Flat;
		vFlat = StrReplace(vFlat, "/", "");
		
		pPage1.Parameters.mHotelAddress3 = TrimAll(vAddress.Street) + ?(IsBlankString(vHouse), "", ", д. " + TrimAll(vHouse)) + ?(IsBlankString(vBuilding), "", " к. " + vBuilding) + ?(IsBlankString(vHouseBuilding), "", " стр. " + vHouseBuilding) + ?(IsBlankString(vFlat), "", ", кв. " + vFlat);
		pPage1.Parameters.mHotelAddress4 = "";
	Else
		pPage1.Parameters.mHotelAddress1 = "";
		pPage1.Parameters.mHotelAddress2 = "";
		pPage1.Parameters.mHotelAddress3 = "";
		pPage1.Parameters.mHotelAddress4 = "";
	EndIf;
	
	// Company name and TIN
	vCompany = Undefined;
	If ValueIsFilled(pRef.Hotel) And ValueIsFilled(pRef.Hotel.CompanyRegisteredInUFMS) Then
		vCompany = pRef.Hotel.CompanyRegisteredInUFMS;
	Else 
		If ValueIsFilled(pRef.ParentDoc) And ValueIsFilled(pRef.ParentDoc.Company) Then
			vCompany = pRef.ParentDoc.Company;
		Else
			vCompany = pRef.Hotel.Company;
		EndIf;
	EndIf;
	
	vCompanyAddressStr = "";
	If ValueIsFilled(vCompany) Then
		vCompanyName = TrimAll(vCompany.LegacyName);
		
		pPage2.Parameters.mCompanyName1 = TrimAll(Left(vCompanyName, 40));
		pPage2.Parameters.mCompanyName2 = TrimAll(Mid(vCompanyName, 41));
		
		vCompanyAddress = cmParseAddress(TrimAll(vCompany.LegacyAddress));
		
		pPage2.Parameters.mCompanyAddress1 = TrimAll(vCompanyAddress.Region);
		pPage2.Parameters.mCompanyAddress2 = TrimAll(vCompanyAddress.Area) + ", " + TrimAll(vCompanyAddress.City);
		
		vHouse = TrimAll(vCompanyAddress.House);
		vBuilding = "";
		vHouseBuilding = "";
		ParseHouseNumber(vHouse, vBuilding, vHouseBuilding);
		vFlat = TrimAll(vCompanyAddress.Flat);
		vFlat = StrReplace(vFlat, "/", "");
		
		pPage2.Parameters.mCompanyAddress3 = TrimAll(vCompanyAddress.Street) + ?(IsBlankString(vHouse), "", ", д. " + TrimAll(vHouse)) + ?(IsBlankString(vBuilding), "", " к. " + vBuilding) + ?(IsBlankString(vHouseBuilding), "", " стр. " + vHouseBuilding) + ?(IsBlankString(vHouseBuilding), "", ", кв. " + vFlat);
		
		pPage2.Parameters.mCompanyTIN = TrimAll(vCompany.TIN);
	Else
		pPage2.Parameters.mCompanyName1 = "";
		pPage2.Parameters.mCompanyAddress1 = "";
		pPage2.Parameters.mCompanyAddress2 = "";
		pPage2.Parameters.mCompanyAddress3 = "";
		pPage2.Parameters.mCompanyTIN = "";
	EndIf;

	// Employee that signes notification
	If ValueIsFilled(pEmployee) Then
		// Employee name
		pPage2.Parameters.mEmployeeLastName = TrimAll(pEmployee.LastName);
		pPage2.Parameters.mEmployeeFirstName = TrimAll(pEmployee.FirstName);
		pPage2.Parameters.mEmployeeSecondName = TrimAll(pEmployee.SecondName);
		
		pPage2.Parameters.mIdentificationDocumentType = TrimAll(pEmployee.IdentityDocumentType);
		pPage2.Parameters.mIdentificationDocumentSeries = TrimAll(pEmployee.IdentityDocumentSeries);
		pPage2.Parameters.mIdentificationDocumentNumber = TrimAll(pEmployee.IdentityDocumentNumber);
		
		pPage2.Parameters.mIdentificationDocumentIssueDate = Format(pEmployee.IdentityDocumentIssueDate, "DF=dd.MM.yyyy");
		pPage2.Parameters.mIdentificationDocumentUnitCode = TrimAll(pEmployee.IdentityDocumentUnitCode);
		pPage2.Parameters.mIdentificationDocumentIssuedBy = TrimAll(pEmployee.IdentityDocumentIssuedBy);
		
		// Employee address
		vEmployeeAddress = cmParseAddress(TrimAll(pEmployee.Address));
		
		pPage2.Parameters.mEmployeeAddress1 = TrimAll(vEmployeeAddress.Region) + ?(IsBlankString(vEmployeeAddress.Area), "", ", " + TrimAll(vEmployeeAddress.Area));
		
		vHouse = TrimAll(vEmployeeAddress.House);
		vBuilding = "";
		vHouseBuilding = "";
		ParseHouseNumber(vHouse, vBuilding, vHouseBuilding);
		vFlat = TrimAll(vEmployeeAddress.Flat);
		vFlat = StrReplace(vFlat, "/", "");
		
		pPage2.Parameters.mEmployeeAddress2 = TrimAll(vEmployeeAddress.City) + ", " + TrimAll(vEmployeeAddress.Street) + ?(IsBlankString(vHouse), "", ", д. " + TrimAll(vHouse)) + ?(IsBlankString(vBuilding), "", " к. " + vBuilding) + ?(IsBlankString(vHouseBuilding), "", " стр. " + vHouseBuilding) + ?(IsBlankString(vHouseBuilding), "", ", кв. " + vFlat);
		
		// Employee phone
		If Not IsBlankString(pEmployee.Phones) Then
			vEmployeePhone = StringToArray("7" + RemoveDelimeters(TrimAll(pEmployee.Phones)), 11);
		Else
			vEmployeePhone = StringToArray("", 11);
		EndIf;
		SetAttributeParameters(pPage2, "mEmployeePhone", vEmployeePhone, 11);
		
		// Employee proxy document
		pPage2.Parameters.mEmployeeProxyType1 = TrimAll(pEmployee.ProxyDocumentType);
		pPage2.Parameters.mEmployeeProxyType2 = ?(IsBlankString(pEmployee.ProxyDocumentSeries), "", "серия " + TrimAll(pEmployee.ProxyDocumentSeries) + " ") + 
		                                        ?(IsBlankString(pEmployee.ProxyDocumentNumber), "", "номер " + TrimAll(pEmployee.ProxyDocumentNumber));
		pPage2.Parameters.mEmployeeProxyType3 = ?(ValueIsFilled(pEmployee.ProxyDocumentIssueDate), "выд. " + Format(pEmployee.ProxyDocumentIssueDate, "DF=dd.MM.yyyy"), "") + 
		                                        ?(ValueIsFilled(pEmployee.ProxyDocumentValidToDate), " действ. до " + Format(pEmployee.ProxyDocumentValidToDate, "DF=dd.MM.yyyy"), "");
	Else // Employee is not selected, so fill all employee data with blanks except address and phone
		// Employee name
		pPage2.Parameters.mEmployeeLastName = "";
		pPage2.Parameters.mEmployeeFirstName = "";
		pPage2.Parameters.mEmployeeSecondName = "";
		
		pPage2.Parameters.mIdentificationDocumentType = "";
		pPage2.Parameters.mIdentificationDocumentSeries = "";
		pPage2.Parameters.mIdentificationDocumentNumber = "";
		
		pPage2.Parameters.mIdentificationDocumentIssueDate = "";
		pPage2.Parameters.mIdentificationDocumentUnitCode = "";
		pPage2.Parameters.mIdentificationDocumentIssuedBy = "";
		
		// Employee address
		pPage2.Parameters.mEmployeeAddress1 = "";
		pPage2.Parameters.mEmployeeAddress2 = "";
		
		// Employee phone
		vEmployeePhone = StringToArray("", 11);
		SetAttributeParameters(pPage2, "mEmployeePhone", vEmployeePhone, 11);
		
		// Employee proxy document
		pPage2.Parameters.mEmployeeProxyType1 = "";
		pPage2.Parameters.mEmployeeProxyType2 = "";
		pPage2.Parameters.mEmployeeProxyType3 = "";
	EndIf;
	
	pPage2.Parameters.mDate = Format(pRef.Date, "DF=dd.MM.yyyy");
EndProcedure // SetParametersForDepartureNotificationPages

// -----------------------------------------------------------------------------
Procedure SetParametersForDepartureNotificationPages20200914(pPage1, pPage2, pRef, pEmployee) Export
	// Try to fill guest data	
	If ValueIsFilled(pRef.Guest) Then
		// Guest name
		If IsBlankString(pRef.LastName) Then
			vGuestLastName = StringToArray(pRef.Guest.LastName, 30);
			SetAttributeParameters(pPage1, "mGuestLastName", vGuestLastName, 30);
			vGuestName = StringToArray(TrimAll(pRef.Guest.FirstName) + " " + 
			                           TrimAll(pRef.Guest.SecondName), 30);
			SetAttributeParameters(pPage1, "mGuestName", vGuestName, 30);
		Else
			vGuestLastName = StringToArray(pRef.LastName, 30);
			SetAttributeParameters(pPage1, "mGuestLastName", vGuestLastName, 30);
			vGuestName = StringToArray(TrimAll(pRef.FirstName) + " " + 
			                           TrimAll(pRef.SecondName), 30);
			SetAttributeParameters(pPage1, "mGuestName", vGuestName, 30);
		EndIf;
		
		// Guest date of birth
		vGuestDateOfBirth = StringToArray(DateToString(pRef.DateOfBirth), 8);
		SetAttributeParameters(pPage1, "mGuestBirthDate", vGuestDateOfBirth, 8);
	Else // Guest is not selected, so fill all guest data with blanks
		// Guest name
		SetAttributeParameters(pPage1, "mGuestLastName", StringToArray("", 30), 30);
		SetAttributeParameters(pPage1, "mGuestName", StringToArray("", 30), 30);
		
		// Guest date of birth
		SetAttributeParameters(pPage1, "mGuestBirthDate", StringToArray("", 8), 8);
	EndIf;
	
	// Check out date
	If ValueIsFilled(pRef.CheckOutDate) Then
		vCheckOutDate = StringToArray(DateToString(pRef.CheckOutDate), 8);
		SetAttributeParameters(pPage1, "mDateTo", vCheckOutDate, 8);
	Else
		SetAttributeParameters(pPage1, "mDateTo", StringToArray("", 8), 8);
	EndIf;
	
	// Company name and TIN
	vCompany = Undefined;
	If ValueIsFilled(pRef.Hotel) And ValueIsFilled(pRef.Hotel.CompanyRegisteredInUFMS) Then
		vCompany = pRef.Hotel.CompanyRegisteredInUFMS;
	Else 
		If ValueIsFilled(pRef.ParentDoc) And ValueIsFilled(pRef.ParentDoc.Company) Then
			vCompany = pRef.ParentDoc.Company;
		Else
			vCompany = pRef.Hotel.Company;
		EndIf;
	EndIf;
	vCompanyAddressStr = "";
	If ValueIsFilled(vCompany) Then
		vCompanyName = StringToArray(StrReplace(TrimAll(vCompany.LegacyName),"""",""), 93);
		SetAttributeParameters(pPage2, "mCompanyName", vCompanyName, 93);
		
		vCompanyTIN = StringToArray(vCompany.TIN, 12);
		SetAttributeParameters(pPage2, "mCompanyTIN", vCompanyTIN, 12);
		
		vCompanyAddressStr = StrReplace(StrReplace(cmGetAddressPresentation(TrimAll(?(IsBlankString(vCompany.PostAddressTranslations), vCompany.PostAddress, cmNStr(vCompany.PostAddressTranslations, SessionParameters.CurrentLanguage)))), ",", " "), "  ", " ");
		If Mid(vCompanyAddressStr, 35, 1) = " " Then
			vCompanyAddressStr = Left(vCompanyAddressStr, 34) + Mid(vCompanyAddressStr, 36);
		EndIf;
		vCompanyAddress = StringToArray(vCompanyAddressStr, 72);
		SetAttributeParameters(pPage2, "mCompanyAddress", vCompanyAddress, 72);
	Else
		SetAttributeParameters(pPage2, "mCompanyName", StringToArray("", 93), 93);
		SetAttributeParameters(pPage2, "mCompanyTIN", StringToArray("", 12), 12);
		SetAttributeParameters(pPage2, "mCompanyAddress", StringToArray("", 72), 72);
	EndIf;
		
	// Hotel address
	vHotelAddressStr = "";
	If ValueIsFilled(pRef.Hotel) Then
		vHotelAddressStr = pRef.Hotel.PostAddress;
		vAddress = cmParseAddress(vHotelAddressStr);
		
		vAddressRegion = StringToArray(vAddress.Region, 30);
		SetAttributeParameters(pPage1, "mAddressRegion", vAddressRegion, 30);
		
		vAddressArea = StringToArray(vAddress.Area, 35);
		SetAttributeParameters(pPage1, "mAddressArea", vAddressArea, 35);
		
		vAddressCity = StringToArray(vAddress.City, 32);
		SetAttributeParameters(pPage1, "mAddressCity", vAddressCity, 32);
		
		vAddressStreet = StringToArray(vAddress.Street, 35);
		SetAttributeParameters(pPage1, "mAddressStreet", vAddressStreet, 35);
		
		vHouse = TrimAll(vAddress.House);
		vBuilding = "";
		vHouseBuilding = "";
		ParseHouseNumber(vHouse, vBuilding, vHouseBuilding);
		
		vAddressHouse = StringToArray(TrimAll(vHouse), 7);
		SetAttributeParameters(pPage1, "mAddressHouse", vAddressHouse, 7);
		
		If Not IsBlankString(vBuilding) Then
			vAddressBuilding = StringToArray(vBuilding, 3);
		Else
			vAddressBuilding = StringToArray("", 3);
		EndIf;
		SetAttributeParameters(pPage1, "mAddressBuilding", vAddressBuilding, 3);
		
		If Not IsBlankString(vHouseBuilding) Then
			vAddressHouseBuilding = StringToArray(vHouseBuilding, 7);
		Else
			vAddressHouseBuilding = StringToArray("", 7);
		EndIf;
		SetAttributeParameters(pPage1, "mAddressHouseBuilding", vAddressHouseBuilding, 7);
		
		vFlat = vAddress.Flat;
		vFlat = StrReplace(vFlat, "/", "");
		vAddressFlat = StringToArray(vFlat, 4);
		SetAttributeParameters(pPage1, "mAddressFlat", vAddressFlat, 4);
	Else
		SetAttributeParameters(pPage1, "mAddressRegion", StringToArray("", 30), 30);
		SetAttributeParameters(pPage1, "mAddressArea", StringToArray("", 35), 35);
		SetAttributeParameters(pPage1, "mAddressCity", StringToArray("", 32), 32);
		SetAttributeParameters(pPage1, "mAddressStreet", StringToArray("", 35), 35);
		SetAttributeParameters(pPage1, "mAddressHouse", StringToArray("", 7), 7);
		SetAttributeParameters(pPage1, "mAddressBuilding", StringToArray("", 3), 3);
		SetAttributeParameters(pPage1, "mAddressHouseBuilding", StringToArray("", 7), 7);
		SetAttributeParameters(pPage1, "mAddressFlat", StringToArray("", 4), 4);
	EndIf;

	// Hotel phone
	vHotelPhoneStr = "";
	If ValueIsFilled(pRef.Hotel) Then
		vHotelPhoneStr = RemoveDelimeters(TrimAll(pRef.Hotel.Phones));
		If Left(vHotelPhoneStr, 1) = "7" And StrLen(vHotelPhoneStr) > 10 Then
			vHotelPhoneStr = Mid(vHotelPhoneStr, 2);
		EndIf;
	EndIf;

	// Employee that signes notification
	If ValueIsFilled(pEmployee) Then
		// Employee name
		vEmployeeLastName = StringToArray(pEmployee.LastName, 34);
		SetAttributeParameters(pPage1, "mEmployeeLastName", vEmployeeLastName, 34);
		vEmployeeName = StringToArray(TrimAll(pEmployee.FirstName) + " " + 
								      TrimAll(pEmployee.SecondName), 34);
		SetAttributeParameters(pPage1, "mEmployeeName", vEmployeeName, 34);
		
		// Employee identification document
		If Find(Upper(TrimAll(pEmployee.IdentityDocumentType)), "ПАСПОРТ") > 0 Then
			vEmployeeIDType = StringToArray("ПАСПОРТ", 31);
		Else
			vEmployeeIDType = StringToArray(pEmployee.IdentityDocumentType, 31);
		EndIf;
		SetAttributeParameters(pPage1, "mEmployeeIDType", vEmployeeIDType, 31);
		
		vEmployeeIDSeries = StringToArray(TrimAll(StrReplace(pEmployee.IdentityDocumentSeries, " ", "")), 5);
		SetAttributeParameters(pPage1, "mEmployeeIDSeries", vEmployeeIDSeries, 5);
		
		vEmployeeIDNumber = StringToArray(TrimAll(pEmployee.IdentityDocumentNumber), 9);
		SetAttributeParameters(pPage1, "mEmployeeIDNumber", vEmployeeIDNumber, 9);
		
		vEmployeeIDIssuedDate = StringToArray(DateToString(pEmployee.IdentityDocumentIssueDate), 8);
		SetAttributeParameters(pPage1, "mEmployeeIDIssuedDate", vEmployeeIDIssuedDate, 8);
		
		vEmployeeIDValidToDate = StringToArray(DateToString(pEmployee.IdentityDocumentValidToDate), 8);
		SetAttributeParameters(pPage1, "mEmployeeIDValidToDate", vEmployeeIDValidToDate, 8);
		
		// Employee phone
		If Not IsBlankString(pEmployee.Phones) Then
			vEmployeePhoneStr = RemoveDelimeters(TrimAll(pEmployee.Phones));
			If Left(vEmployeePhoneStr, 1) = "7" And StrLen(vEmployeePhoneStr) > 10 Then
				vEmployeePhoneStr = Mid(vEmployeePhoneStr, 2);
			EndIf;
			vEmployeePhone = StringToArray(vEmployeePhoneStr, 10);
		Else
			vEmployeePhone = StringToArray(vHotelPhoneStr, 10);
		EndIf;
		SetAttributeParameters(pPage1, "mEmployeePhone", vEmployeePhone, 10);
		
		// Employee proxy document
		vEmployeeProxyDocType = StringToArray(pEmployee.ProxyDocumentType, 46);
		SetAttributeParameters(pPage2, "mEmployeeProxyType", vEmployeeProxyDocType, 46);
		
		vEmployeeProxySeries = StringToArray(TrimAll(StrReplace(pEmployee.ProxyDocumentSeries, " ", "")), 5);
		SetAttributeParameters(pPage2, "mEmployeeProxySeries", vEmployeeProxySeries, 5);
		
		vEmployeeProxyNumber = StringToArray(TrimAll(pEmployee.ProxyDocumentNumber), 9);
		SetAttributeParameters(pPage2, "mEmployeeProxyNumber", vEmployeeProxyNumber, 9);
		
		vEmployeeProxyIssuedDate = StringToArray(DateToString(pEmployee.ProxyDocumentIssueDate), 8);
		SetAttributeParameters(pPage2, "mEmployeeProxyIssuedDate", vEmployeeProxyIssuedDate, 8);
		
		If ValueIsFilled(pEmployee.ProxyDocumentValidToDate) Then
			vEmployeeProxyValidToDate = StringToArray(DateToString(pEmployee.ProxyDocumentValidToDate), 8);
			SetAttributeParameters(pPage2, "mEmployeeProxyValidToDate", vEmployeeProxyValidToDate, 8);
			SetAttributeParameters(pPage2, "mEmployeeProxyValidToNoLimit", StringToArray("", 10), 10);
		ElsIf ValueIsFilled(pEmployee.ProxyDocumentNumber) Then
			SetAttributeParameters(pPage2, "mEmployeeProxyValidToDate", StringToArray("", 8), 8);
			SetAttributeParameters(pPage2, "mEmployeeProxyValidToNoLimit", StringToArray("БЕССРОЧНО", 10), 10);
		Else
			SetAttributeParameters(pPage2, "mEmployeeProxyValidToDate", StringToArray("", 8), 8);
			SetAttributeParameters(pPage2, "mEmployeeProxyValidToNoLimit", StringToArray("", 10), 10);
		EndIf;
	Else // Employee is not selected, so fill all employee data with blanks except address and phone
		// Employee name
		SetAttributeParameters(pPage2, "mEmployeeLastName", StringToArray("", 34), 34);
		SetAttributeParameters(pPage2, "mEmployeeName", StringToArray("", 34), 34);
		
		// Employee identification document
		SetAttributeParameters(pPage2, "mEmployeeIDType", StringToArray("", 31), 31);
		SetAttributeParameters(pPage2, "mEmployeeIDSeries", StringToArray("", 5), 5);
		SetAttributeParameters(pPage2, "mEmployeeIDNumber", StringToArray("", 9), 9);
		SetAttributeParameters(pPage2, "mEmployeeIDIssuedDate", StringToArray("", 8), 8);
		SetAttributeParameters(pPage2, "mEmployeeIDValidToDate", StringToArray("", 8), 8);
		
		// Employee phone
		vEmployeePhone = StringToArray(vHotelPhoneStr, 10);
		SetAttributeParameters(pPage2, "mEmployeePhone", vEmployeePhone, 10);
		
		// Employee proxy document
		SetAttributeParameters(pPage2, "mEmployeeProxyType", StringToArray("", 46), 46);
		SetAttributeParameters(pPage2, "mEmployeeProxySeries", StringToArray("", 5), 5);
		SetAttributeParameters(pPage2, "mEmployeeProxyNumber", StringToArray("", 9), 9);
		SetAttributeParameters(pPage2, "mEmployeeProxyIssuedDate", StringToArray("", 8), 8);
		SetAttributeParameters(pPage2, "mEmployeeProxyValidToDate", StringToArray("", 8), 8);
		SetAttributeParameters(pPage2, "mEmployeeProxyValidToNoLimit", StringToArray("", 10), 10);
	EndIf;
EndProcedure // SetParametersForDepartureNotificationPages20200914

// -----------------------------------------------------------------------------
Procedure SetParametersNotificationForPages(pPage1, pPage2, pPage3, pPage4, pRef, pEmployee) Export
	SetParametersNotificationForPages20230101(pPage1, pPage2, pPage3, pPage4, pRef, pEmployee);
EndProcedure // SetParametersNotificationForPages

// -----------------------------------------------------------------------------
Procedure SetParametersNotificationForPages20250205(pPage1, pPage2, pPage3, pPage4, pRef, pEmployee) Export
	Var vVisaSeries;
	Var vVisaNumber;
	Var vMigrationCardSeries;
	Var vMigrationCardNumber;
	
	// Check char
	vX = "Х";
	
	// Try to fill guest data	
	If ValueIsFilled(pRef.Guest) Then
		// Guest name RUS
		If IsBlankString(pRef.LastName) Then
			vGuestLastName = StringToArray(pRef.Guest.LastName, 28);
			vGuestFirstName = StringToArray(pRef.Guest.FirstName, 28);
			vGuestSecondName = StringToArray(pRef.Guest.SecondName, 24);  
		Else
			vGuestLastName = StringToArray(pRef.LastName, 28);
			vGuestFirstName = StringToArray(pRef.FirstName, 28);
			vGuestSecondName = StringToArray(pRef.SecondName, 24);  
		EndIf;

		// Guest name LAT
		vGuestLastNameLAT = StringToArray(pRef.Guest.LastName, 22);
		vGuestFirstNameLAT = StringToArray(pRef.Guest.FirstName, 23);
		vGuestSecondNameLAT = StringToArray(pRef.Guest.SecondName, 23);

		SetAttributeParameters(pPage1, "mGuestLastName", vGuestLastName, 28);
		SetAttributeParameters(pPage1, "mGuestFirstName", vGuestFirstName, 28);
		SetAttributeParameters(pPage1, "mGuestSecondName", vGuestSecondName, 24);
		SetAttributeParameters(pPage1, "mGuestLastNameLAT", vGuestLastNameLAT, 22);
		SetAttributeParameters(pPage1, "mGuestFirstNameLAT", vGuestFirstNameLAT, 23);
		SetAttributeParameters(pPage1, "mGuestSecondNameLAT", vGuestSecondNameLAT, 23);
		SetAttributeParameters(pPage3, "mGuestLastName", vGuestLastName, 28);
		SetAttributeParameters(pPage3, "mGuestFirstName", vGuestFirstName, 28);
		SetAttributeParameters(pPage3, "mGuestSecondName", vGuestSecondName, 23);      

		// Guest citizenship
		vGuestCitizenship = StringToArray(TrimAll(pRef.Citizenship), 27);
		SetAttributeParameters(pPage1, "mGuestCitizenship", vGuestCitizenship, 26);
		SetAttributeParameters(pPage3, "mGuestCitizenship", vGuestCitizenship, 27);
		
		// Guest date of birth
		vGuestDateOfBirth = StringToArray(DateToString(pRef.DateOfBirth), 8);
		SetAttributeParameters(pPage1, "mGuestBirthDate", vGuestDateOfBirth, 8);
		SetAttributeParameters(pPage3, "mGuestBirthDate", vGuestDateOfBirth, 8);
		
		// Guest place of birth
		vGuestPlaceOfBirth = cmParseAddress(pRef.PlaceOfBirth);
		
		vGuestPlaceOfBirthCountry = StringToArray(vGuestPlaceOfBirth.Country, 25);
		SetAttributeParameters(pPage1, "mGuestBirthPlaceCountry", vGuestPlaceOfBirthCountry, 25);
		
		vGuestPlaceOfBirthCity = StringToArray(vGuestPlaceOfBirth.City, 62);
		SetAttributeParameters(pPage1, "mGuestBirthPlaceCity", vGuestPlaceOfBirthCity, 62);
		
		// Guest sex
		If pRef.Sex = Enums.Sex.Male Then
			pPage1.Parameters.mGuestSexMale = vX;
			pPage1.Parameters.mGuestSexFemale = "";
			pPage3.Parameters.mGuestSexMale = vX;
			pPage3.Parameters.mGuestSexFemale = "";
		ElsIf pRef.Sex = Enums.Sex.Female Then
			pPage1.Parameters.mGuestSexMale = "";
			pPage1.Parameters.mGuestSexFemale = vX;
			pPage3.Parameters.mGuestSexMale = "";
			pPage3.Parameters.mGuestSexFemale = vX;
		Else
			pPage1.Parameters.mGuestSexMale = "";
			pPage1.Parameters.mGuestSexFemale = "";
			pPage3.Parameters.mGuestSexMale = "";
			pPage3.Parameters.mGuestSexFemale = "";
		EndIf;
		
		// Guest phone
		If IsBlankString(pRef.Guest.Phone) Then
			SetAttributeParameters(pPage1, "mGuestPhone", StringToArray("", 10), 10);
		Else
			vGuestPhone = TrimAll(pRef.Guest.Phone);
			If Left(vGuestPhone, 1) = "7" And StrLen(vGuestPhone) > 10 Then
				vGuestPhone = Mid(vGuestPhone, 2);
			EndIf;
			SetAttributeParameters(pPage1, "mGuestPhone", StringToArray(vGuestPhone, 10), 10);
		EndIf;
		
		// Guest identification document
		If  ValueIsFilled(pRef.Hotel) And ValueIsFilled(pRef.Hotel.BirthCertificateRecord) And pRef.IdentityDocumentType = pRef.Hotel.BirthCertificateRecord Then     
			
			vGuestIDNumber = StringToArray(TrimAll(pRef.IdentityDocumentNumber), 21);
			SetAttributeParameters(pPage1, "mGuestBirthCertificateNumber", vGuestIDNumber, 21);
			
			vGuestIDIssuedDate = StringToArray(DateToString(pRef.IdentityDocumentIssueDate), 8);   
			SetAttributeParameters(pPage1, "mGuestBirthCertificateDate", vGuestIDIssuedDate, 8);
			
			vGuestIDIssuedBy = StringToArray(DateToString(pRef.IdentityDocumentIssuedBy), 93);
			SetAttributeParameters(pPage1, "mGuestBirthCertificateIssuedBy", vGuestIDIssuedBy, 93);
		Else
			If Find(Upper(TrimAll(pRef.IdentityDocumentType)), "ПАСПОРТ") > 0 Then
				vGuestIDType = StringToArray("ПАСПОРТ", 29);
			Else
				vGuestIDType = StringToArray(pRef.IdentityDocumentType, 29);
			EndIf;
			SetAttributeParameters(pPage1, "mGuestIDType", vGuestIDType, 29);
			SetAttributeParameters(pPage3, "mGuestIDType", vGuestIDType, 10);
			
			vGuestIDSeries = StringToArray(TrimAll(StrReplace(pRef.IdentityDocumentSeries, " ", "")), 6);
			SetAttributeParameters(pPage1, "mGuestIDSeries", vGuestIDSeries, 6);
			SetAttributeParameters(pPage3, "mGuestIDSeries", vGuestIDSeries, 6);
			
			vGuestIDNumber = StringToArray(TrimAll(pRef.IdentityDocumentNumber), 21);
			SetAttributeParameters(pPage1, "mGuestIDNumber", vGuestIDNumber, 21);
			SetAttributeParameters(pPage3, "mGuestIDNumber", vGuestIDNumber, 10);
			
			vGuestIDIssuedDate = StringToArray(DateToString(pRef.IdentityDocumentIssueDate), 8);
			SetAttributeParameters(pPage1, "mGuestIDIssuedDate", vGuestIDIssuedDate, 8);
			SetAttributeParameters(pPage3, "mGuestIDIssuedDate", vGuestIDIssuedDate, 8);
			
			vGuestIDValidToDate = StringToArray(DateToString(pRef.IdentityDocumentValidToDate), 8);
			SetAttributeParameters(pPage1, "mGuestIDValidToDate", vGuestIDValidToDate, 8);
			SetAttributeParameters(pPage3, "mGuestIDValidToDate", vGuestIDValidToDate, 8);   
		EndIf;
		
	Else // Guest is not selected, so fill all guest data with blanks
		// Guest name
		SetAttributeParameters(pPage1, "mGuestLastName", StringToArray("", 28), 28);
		SetAttributeParameters(pPage1, "mGuestFirstName", StringToArray("", 28), 28);
		SetAttributeParameters(pPage1, "mGuestSecondName", StringToArray("", 24), 24);
		
		SetAttributeParameters(pPage3, "mGuestLastName", StringToArray("", 28), 28);
		SetAttributeParameters(pPage3, "mGuestFirstName", StringToArray("", 28), 28);
		SetAttributeParameters(pPage3, "mGuestSecondName", StringToArray("", 23), 23);   
		
		SetAttributeParameters(pPage1, "mGuestLastNameLAT", StringToArray("", 22), 22);
		SetAttributeParameters(pPage1, "mGuestFirstNameLAT", StringToArray("", 23), 23);
		SetAttributeParameters(pPage1, "mGuestSecondNameLAT", StringToArray("", 23), 23);
		
		// Guest citizenship
		SetAttributeParameters(pPage1, "mGuestCitizenship", StringToArray("", 26), 26);
		SetAttributeParameters(pPage3, "mGuestCitizenship", StringToArray("", 27), 27);
		
		// Guest date of birth
		SetAttributeParameters(pPage1, "mGuestBirthDate", StringToArray("", 8), 8);
		SetAttributeParameters(pPage3, "mGuestBirthDate", StringToArray("", 8), 8);
		
		// Guest place of birth
		SetAttributeParameters(pPage1, "mGuestBirthPlaceCountry", StringToArray("", 25), 25);
		SetAttributeParameters(pPage1, "mGuestBirthPlaceCity", StringToArray("", 62), 62);
		
		// Guest sex
		pPage1.Parameters.mGuestSexMale = "";
		pPage1.Parameters.mGuestSexFemale = "";
		pPage3.Parameters.mGuestSexMale = "";
		pPage3.Parameters.mGuestSexFemale = "";
		
		// Guest phone
		SetAttributeParameters(pPage1, "mGuestPhone", StringToArray("", 10), 10);
		
		// Guest identification document
		SetAttributeParameters(pPage1, "mGuestIDType", StringToArray("", 29), 29);
		SetAttributeParameters(pPage3, "mGuestIDType", StringToArray("", 10), 10);
		SetAttributeParameters(pPage1, "mGuestIDSeries", StringToArray("", 6), 6);
		SetAttributeParameters(pPage3, "mGuestIDSeries", StringToArray("", 6), 6);
		SetAttributeParameters(pPage1, "mGuestIDNumber", StringToArray("", 21), 21);
		SetAttributeParameters(pPage3, "mGuestIDNumber", StringToArray("", 10), 10);
		SetAttributeParameters(pPage1, "mGuestIDIssuedDate", StringToArray("", 8), 8);
		SetAttributeParameters(pPage3, "mGuestIDIssuedDate", StringToArray("", 8), 8);
		SetAttributeParameters(pPage1, "mGuestIDValidToDate", StringToArray("", 8), 8);
		SetAttributeParameters(pPage3, "mGuestIDValidToDate", StringToArray("", 8), 8);
	EndIf;
	
	// Guest profession and standing
	vGuestProfession = StringToArray(TrimAll(pRef.Profession), 27);
	SetAttributeParameters(pPage1, "mGuestProfession", vGuestProfession, 27);
	
	// Legal representatives
	If Not IsBlankString(pRef.LegalRepresentativeLastName) Then
		vLegalRepresentativeName = TrimAll(TrimAll(pRef.LegalRepresentativeLastName) + " " + TrimAll(pRef.LegalRepresentativeFirstName) + " " + TrimAll(pRef.LegalRepresentativeSecondName));
		vLegalRepresentative = pRef.LegalRepresentative;
		If ValueIsFilled(vLegalRepresentative) Then
			vLegalRepresentatives = StringToArray(vLegalRepresentativeName + 
			                        ?(ValueIsFilled(vLegalRepresentative.DateOfBirth), ", " + Format(vLegalRepresentative.DateOfBirth, "DF=dd.MM.yyyy"), "") +
			                        ?(ValueIsFilled(vLegalRepresentative.Sex), ", " + TrimAll(vLegalRepresentative.Sex), "") + 
									?(Not IsBlankString(vLegalRepresentative.IdentityDocumentNumber), ", №" + TrimAll(TrimAll(vLegalRepresentative.IdentityDocumentSeries) + " " + TrimAll(vLegalRepresentative.IdentityDocumentNumber)), ""), 130);
		Else
			vLegalRepresentatives = StringToArray(vLegalRepresentativeName, 130);
		EndIf;
	ElsIf ValueIsFilled(pRef.LegalRepresentative) Then
		vLegalRepresentative = pRef.LegalRepresentative;
		vLegalRepresentatives = StringToArray(TrimAll(TrimAll(vLegalRepresentative.LastName) + " " + TrimAll(vLegalRepresentative.FirstName) + " " + TrimAll(vLegalRepresentative.SecondName)) + 
		                        ?(ValueIsFilled(vLegalRepresentative.DateOfBirth), ", " + Format(vLegalRepresentative.DateOfBirth, "DF=dd.MM.yyyy"), "") +
		                        ?(ValueIsFilled(vLegalRepresentative.Sex), ", " + TrimAll(vLegalRepresentative.Sex), "") + 
								?(Not IsBlankString(vLegalRepresentative.IdentityDocumentNumber), ", №" + TrimAll(TrimAll(vLegalRepresentative.IdentityDocumentSeries) + " " + TrimAll(vLegalRepresentative.IdentityDocumentNumber)), ""), 130);
	ElsIf Not IsBlankString(pRef.LegalRepresentatives) Then
		vLegalRepresentatives = StringToArray(TrimAll(pRef.LegalRepresentatives), 130);
	Else
		vLegalRepresentatives = StringToArray("", 130);
	EndIf;
	SetAttributeParameters(pPage1, "mLegalRepresentatives", vLegalRepresentatives, 130);
	
	// Previous place of stay
	vPreviousStayAddressStr = pRef.PreviousPlaceOfStay;
	vPreviousStayAddressPars = cmParseAddress(vPreviousStayAddressStr);
		
	vPreviousStayAddressRegion = StringToArray(vPreviousStayAddressPars.Region, 31);
	SetAttributeParameters(pPage2, "mPreviousStayAddressRegion", vPreviousStayAddressRegion, 31);
	
	vPreviousStayAddressArea = StringToArray(vPreviousStayAddressPars.Area, 31);
	SetAttributeParameters(pPage2, "mPreviousStayAddressArea", vPreviousStayAddressArea, 31);
	
	vPreviousStayAddressCity = StringToArray(vPreviousStayAddressPars.City, 31);
	SetAttributeParameters(pPage2, "mPreviousStayAddressCity", vPreviousStayAddressCity, 31);
	
	vPreviousStayAddressStreet = StringToArray(vPreviousStayAddressPars.Street, 31);
	SetAttributeParameters(pPage2, "mPreviousStayAddressStreet", vPreviousStayAddressStreet, 31);
	
	vHouse = TrimAll(vPreviousStayAddressPars.House);
	
	vBuilding = "";
	ParseHouseAndBuilding(vHouse, vBuilding);  
	pPage2.Parameters.mPreviousStayAddressHouseType = "";
	pPage2.Parameters.mPreviousStayAddressHouse = "";
	If Not IsBlankString(vHouse) Then
		pPage2.Parameters.mPreviousStayAddressHouseType = "ДОМ";
		pPage2.Parameters.mPreviousStayAddressHouse = vHouse;
	EndIf;
	pPage2.Parameters.mPreviousStayAddressBuilding = vBuilding;
	
	vFlat = vPreviousStayAddressPars.Flat;
	vFlat = StrReplace(vFlat, "/", "");
	pPage2.Parameters.mPreviousStayAddressFlatType = "";
	pPage2.Parameters.mPreviousStayAddressFlat = "";
	If Not IsBlankString(vFlat) Then
		pPage2.Parameters.mPreviousStayAddressFlatType = "КВАРТИРА";
		pPage2.Parameters.mPreviousStayAddressFlat = vFlat;
	EndIf;
	
	// Visa
	If Not IsBlankString(pRef.VisaNumber) Then
		pPage1.Parameters.mVisa = vX;
		SeriesAndNumberToArray(pRef.VisaNumber, 4, 24, vVisaSeries, vVisaNumber);
		SetAttributeParameters(pPage1, "mVisaSeries", vVisaSeries, 4);
		SetAttributeParameters(pPage1, "mVisaNumber", vVisaNumber, 24);
		vVisaIssuedDate = StringToArray(DateToString(pRef.VisaIssuedDate), 8);
		SetAttributeParameters(pPage1, "mVisaIssuedDate", vVisaIssuedDate, 8);
		vVisaValidToDate = StringToArray(DateToString(pRef.VisaToDate), 8);
		SetAttributeParameters(pPage1, "mVisaValidToDate", vVisaValidToDate, 8);
	Else
		pPage1.Parameters.mVisa = "";
		SetAttributeParameters(pPage1, "mVisaSeries", StringToArray("", 4), 4);
		SetAttributeParameters(pPage1, "mVisaNumber", StringToArray("", 24), 24);
		SetAttributeParameters(pPage1, "mVisaIssuedDate", StringToArray("", 8), 8);
		SetAttributeParameters(pPage1, "mVisaValidToDate", StringToArray("", 8), 8);
	EndIf;
	
	pPage1.Parameters.mResidencePermit = "";
	pPage1.Parameters.mTempResidencePermit = "";
	pPage1.Parameters.mTempResidencePermitForEducation = "";
	If ValueIsFilled(pRef.ResidencePermitDocument) And pRef.ResidencePermitDocument = Enums.ConfirmingDocuments.PermResidencePermit Or 
	   ValueIsFilled(pRef.VisaType) And TrimAll(pRef.VisaType.Code) = "ВЖ" Then
		pPage1.Parameters.mVisa = "";
		pPage1.Parameters.mResidencePermit = vX;
		
		SeriesAndNumberToArray(pRef.VisaNumber, 4, 24, vVisaSeries, vVisaNumber);
		SetAttributeParameters(pPage1, "mVisaSeries", vVisaSeries, 4);
		SetAttributeParameters(pPage1, "mVisaNumber", vVisaNumber, 24);
		
		vVisaFromDate = StringToArray(DateToString(pRef.VisaFromDate), 8);
		SetAttributeParameters(pPage1, "mVisaIssuedDate", vVisaFromDate, 8);
		
		vVisaValidToDate = StringToArray(DateToString(pRef.VisaToDate), 8);
		SetAttributeParameters(pPage1, "mVisaValidToDate", vVisaValidToDate, 8);
	ElsIf ValueIsFilled(pRef.ResidencePermitDocument) And pRef.ResidencePermitDocument = Enums.ConfirmingDocuments.TempResidencePermit Or 
	      ValueIsFilled(pRef.VisaType) And TrimAll(pRef.VisaType.Code) = "ВР" Then
		pPage1.Parameters.mVisa = "";
		If pRef.ForEducationPurposes Then
			pPage1.Parameters.mTempResidencePermitForEducation = vX;
		Else
			pPage1.Parameters.mTempResidencePermit = vX;
		EndIf;
		
		SeriesAndNumberToArray(pRef.VisaIdentifier, 4, 24, vVisaSeries, vVisaNumber);
		SetAttributeParameters(pPage1, "mVisaSeries", vVisaSeries, 4);
		SetAttributeParameters(pPage1, "mVisaNumber", vVisaNumber, 24);
		
		vVisaIssuedDate = StringToArray(DateToString(pRef.VisaIssuedDate), 8);
		SetAttributeParameters(pPage1, "mVisaIssuedDate", vVisaIssuedDate, 8);
		
		vVisaValidToDate = StringToArray(DateToString(pRef.VisaToDate), 8);
		SetAttributeParameters(pPage1, "mVisaValidToDate", vVisaValidToDate, 8);
	ElsIf ValueIsFilled(pRef.IdentityDocumentType) And TrimAll(pRef.IdentityDocumentType.Code) = "12" Or
	      ValueIsFilled(pRef.IdentityDocumentType) And TrimAll(pRef.IdentityDocumentType.Code) = "19" Or
	      ValueIsFilled(pRef.IdentityDocumentType) And TrimAll(pRef.IdentityDocumentType.Code) = "20" Then
		pPage1.Parameters.mVisa = "";
		pPage1.Parameters.mResidencePermit = vX;
		
		SeriesAndNumberToArray(pRef.VisaNumber, 4, 24, vVisaSeries, vVisaNumber);
		SetAttributeParameters(pPage1, "mVisaSeries", vVisaSeries, 4);
		SetAttributeParameters(pPage1, "mVisaNumber", vVisaNumber, 24);
		
		vVisaFromDate = StringToArray(DateToString(pRef.VisaFromDate), 8);
		SetAttributeParameters(pPage1, "mVisaIssuedDate", vVisaFromDate, 8);
		
		vVisaValidToDate = StringToArray(DateToString(pRef.VisaToDate), 8);
		SetAttributeParameters(pPage1, "mVisaValidToDate", vVisaValidToDate, 8);
	ElsIf ValueIsFilled(pRef.IdentityDocumentType) And TrimAll(pRef.IdentityDocumentType.Code) = "101" Or
	      ValueIsFilled(pRef.IdentityDocumentType) And TrimAll(pRef.IdentityDocumentType.Code) = "101a" Then
		pPage1.Parameters.mVisa = "";
		pPage1.Parameters.mTempResidencePermit = vX;
		
		SeriesAndNumberToArray(pRef.VisaIdentifier, 4, 24, vVisaSeries, vVisaNumber);
		SetAttributeParameters(pPage1, "mVisaSeries", vVisaSeries, 4);
		SetAttributeParameters(pPage1, "mVisaNumber", vVisaNumber, 24);
		
		vVisaIssuedDate = StringToArray(DateToString(pRef.VisaIssuedDate), 8);
		SetAttributeParameters(pPage1, "mVisaIssuedDate", vVisaIssuedDate, 8);
		
		vVisaValidToDate = StringToArray(DateToString(pRef.VisaToDate), 8);
		SetAttributeParameters(pPage1, "mVisaValidToDate", vVisaValidToDate, 8);
	EndIf;

	// Migration card
	If Not IsBlankString(pRef.MigrationCardNumber) Then
		vSeriesLength = 4;
		vBlankPos = Find(TrimAll(pRef.MigrationCardNumber), " ");
		If vBlankPos > 4 Then
			vSeriesLength = vBlankPos - 1;
		EndIf;
		If StrLen(TrimAll(pRef.MigrationCardNumber)) >= 17 Then
			SeriesAndNumberToArray(pRef.MigrationCardNumber, vSeriesLength, 13, vMigrationCardSeries, vMigrationCardNumber);
		Else
			vMigrationCardSeries = StringToArray(Left(TrimAll(pRef.MigrationCardNumber), vSeriesLength), vSeriesLength);
			vMigrationCardNumber = StringToArray(Right(TrimAll(pRef.MigrationCardNumber), StrLen(TrimAll(pRef.MigrationCardNumber)) - vSeriesLength), 13);
		EndIf;
		SetAttributeParameters(pPage1, "mMigrationCardSeries", vMigrationCardSeries, 4);
		SetAttributeParameters(pPage1, "mMigrationCardNumber", vMigrationCardNumber, 13);
	EndIf;

	vBorderCrossingDate = StringToArray(DateToString(pRef.BorderCrossingDate), 8);
	SetAttributeParameters(pPage1, "mBorderCrossingDate", vBorderCrossingDate, 8);
	
	// Guest trip purpose
	pPage1.Parameters.mTripPurposeOfficial = "";
	pPage1.Parameters.mTripPurposeTourism = "";
	pPage1.Parameters.mTripPurposeBusiness = "";
	pPage1.Parameters.mTripPurposeStudying = "";
	pPage1.Parameters.mTripPurposeWork = "";
	pPage1.Parameters.mTripPurposePrivate = "";
	pPage1.Parameters.mTripPurposeTransit = "";
	pPage1.Parameters.mTripPurposeHumanitarian = "";
	pPage1.Parameters.mTripPurposeOther = "";
	
	If pRef.TripPurpose = Catalogs.TripPurposes.Official Or 
	   pRef.TripPurpose = Catalogs.TripPurposes.Commerce Then
		pPage1.Parameters.mTripPurposeOfficial = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Tourism Then
		pPage1.Parameters.mTripPurposeTourism = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Business Then
		pPage1.Parameters.mTripPurposeBusiness = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Study Or
	      pRef.TripPurpose = Catalogs.TripPurposes.Scientific Then
		pPage1.Parameters.mTripPurposeStudying = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Work Then
		pPage1.Parameters.mTripPurposeWork = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Private Then
		pPage1.Parameters.mTripPurposePrivate = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Transit Or 
		  pRef.TripPurpose = Catalogs.TripPurposes.Crewman Then
		pPage1.Parameters.mTripPurposeTransit = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Humanitarian Then
		pPage1.Parameters.mTripPurposeHumanitarian = vX;
	Else
		pPage1.Parameters.mTripPurposeOther = vX;
	EndIf;
	
	// Company name and TIN
	vCompany = Undefined;
	If ValueIsFilled(pRef.Hotel) And ValueIsFilled(pRef.Hotel.CompanyRegisteredInUFMS) Then
		vCompany = pRef.Hotel.CompanyRegisteredInUFMS;
	Else 
		If ValueIsFilled(pRef.ParentDoc) And ValueIsFilled(pRef.ParentDoc.Company) Then
			vCompany = pRef.ParentDoc.Company;
		Else
			vCompany = pRef.Hotel.Company;
		EndIf;
	EndIf;
	vCompanyAddressStr = "";
	If ValueIsFilled(vCompany) Then
		vCompanyAddressStr = TrimAll(vCompany.PostAddress);
		
		vCompanyName = StringToArray(StrReplace(TrimAll(vCompany.LegacyName),"""",""), 42);
		SetAttributeParameters(pPage4, "mCompanyName", vCompanyName, 42);
		
		vCompanyTIN = StringToArray(vCompany.TIN, 13);
		SetAttributeParameters(pPage4, "mCompanyTIN", vCompanyTIN, 13);
		
		SetAttributeParameters(pPage2, "mCompanyDocumentGivingRightToProvidePremises1Row", StringToArray("", 22), 22);
		SetAttributeParameters(pPage2, "mCompanyDocumentGivingRightToProvidePremises2Row", StringToArray("", 22), 22);
		SetAttributeParameters(pPage2, "mCompanyDocumentGivingRightToProvidePremises3Row", StringToArray("", 22), 22);
		SetAttributeParameters(pPage2, "mCompanyDocumentGivingRightToProvidePremises4Row", StringToArray("", 22), 22);
		SetAttributeParameters(pPage2, "mCompanyDocumentGivingRightToProvidePremises5Row", StringToArray("", 22), 22);
	
		vCompanyDocumentGivingRightToProvidePremisesArray = cmGetTextLinesArray(TrimAll(vCompany.DocumentGivingRightToProvidePremises));
		i = 0;
		While i < vCompanyDocumentGivingRightToProvidePremisesArray.Count() Do
			If i = 0 Then
				vCharsArray = StringToArray(vCompanyDocumentGivingRightToProvidePremisesArray.Get(i), 22);
				SetAttributeParameters(pPage2, "mCompanyDocumentGivingRightToProvidePremises1Row", vCharsArray, 22);
			ElsIf i = 1 Then
				vCharsArray = StringToArray(vCompanyDocumentGivingRightToProvidePremisesArray.Get(i), 22);
				SetAttributeParameters(pPage2, "mCompanyDocumentGivingRightToProvidePremises2Row", vCharsArray, 22);
			ElsIf i = 2 Then
				vCharsArray = StringToArray(vCompanyDocumentGivingRightToProvidePremisesArray.Get(i), 22);
				SetAttributeParameters(pPage2, "mCompanyDocumentGivingRightToProvidePremises3Row", vCharsArray, 22);
			ElsIf i = 3 Then
				vCharsArray = StringToArray(vCompanyDocumentGivingRightToProvidePremisesArray.Get(i), 22);
				SetAttributeParameters(pPage2, "mCompanyDocumentGivingRightToProvidePremises4Row", vCharsArray, 22);
			ElsIf i = 4 Then
				vCharsArray = StringToArray(vCompanyDocumentGivingRightToProvidePremisesArray.Get(i), 22);
				SetAttributeParameters(pPage2, "mCompanyDocumentGivingRightToProvidePremises5Row", vCharsArray, 22);
			Else
				Break;
			EndIf;
			i = i + 1;
		EndDo;
	Else
		SetAttributeParameters(pPage4, "mCompanyName", StringToArray("", 42), 42);
		SetAttributeParameters(pPage4, "mCompanyTIN", StringToArray("", 13), 13);
		
		SetAttributeParameters(pPage2, "mCompanyDocumentGivingRightToProvidePremises1Row", StringToArray("", 22), 22);
		SetAttributeParameters(pPage2, "mCompanyDocumentGivingRightToProvidePremises2Row", StringToArray("", 22), 22);
		SetAttributeParameters(pPage2, "mCompanyDocumentGivingRightToProvidePremises3Row", StringToArray("", 22), 22); 
		SetAttributeParameters(pPage2, "mCompanyDocumentGivingRightToProvidePremises4Row", StringToArray("", 22), 22);
		SetAttributeParameters(pPage2, "mCompanyDocumentGivingRightToProvidePremises5Row", StringToArray("", 22), 22);
	EndIf;
		
	// Hotel address
	vHotelAddressStr = "";
	If ValueIsFilled(pRef.Hotel) Then
		vHotelAddressStr = pRef.Hotel.PostAddress;
		vHotelAddressPars = cmParseAddress(vHotelAddressStr);
		
		vStayAddressRegion = StringToArray(vHotelAddressPars.Region, 31);
		SetAttributeParameters(pPage2, "mStayAddressRegion", vStayAddressRegion, 31);
		SetAttributeParameters(pPage3, "mStayAddressRegion", vStayAddressRegion, 31);

		vStayAddressArea = StringToArray(vHotelAddressPars.Area, 31);
		SetAttributeParameters(pPage2, "mStayAddressArea", vStayAddressArea, 31);
		SetAttributeParameters(pPage3, "mStayAddressArea", vStayAddressArea, 31);
		
		vStayAddressCity = StringToArray(vHotelAddressPars.City, 31);
		SetAttributeParameters(pPage2, "mStayAddressCity", vStayAddressCity, 31);
		SetAttributeParameters(pPage3, "mStayAddressCity", vStayAddressCity, 31);
		
		vStayAddressStreet = StringToArray(vHotelAddressPars.Street, 31);
		SetAttributeParameters(pPage2, "mStayAddressStreet", vStayAddressStreet, 31);
		SetAttributeParameters(pPage3, "mStayAddressStreet", vStayAddressStreet, 31);
		
		vHouse = TrimAll(vHotelAddressPars.House);
		vBuilding = "";
		ParseHouseAndBuilding(vHouse, vBuilding);  
		pPage2.Parameters.mStayAddressHouseType = "";
		pPage2.Parameters.mStayAddressHouse = "";
		If Not IsBlankString(vHouse) Then
			pPage2.Parameters.mStayAddressHouseType = "ДОМ";
			pPage2.Parameters.mStayAddressHouse = vHouse;
		EndIf;
		pPage2.Parameters.mStayAddressBuilding = vBuilding;

		pPage3.Parameters.mStayAddressHouseType = "";
		pPage3.Parameters.mStayAddressHouse = "";
		If Not IsBlankString(vHouse) Then
			pPage3.Parameters.mStayAddressHouseType = "ДОМ";
			pPage3.Parameters.mStayAddressHouse = vHouse;
		EndIf;
		pPage3.Parameters.mStayAddressBuilding = vBuilding;
		
		vFlat = vHotelAddressPars.Flat;
		vFlatType = "КВАРТИРА";
		If IsBlankString(vFlat) And ValueIsFilled(pRef.Room) Then
			vFlatType = "ГОСТИНИЧНЫЙ НОМЕР";
			vFlat = TrimAll(pRef.Room);
		EndIf;
		vFlat = StrReplace(vFlat, "/", "");
		pPage2.Parameters.mStayAddressPlaceType = "";
 		pPage3.Parameters.mStayAddressPlaceType = "";
		pPage2.Parameters.mStayAddressFlat = "";
 		pPage3.Parameters.mStayAddressFlat = "";
		If Not IsBlankString(vFlat) Then
			pPage2.Parameters.mStayAddressPlaceType = vFlatType;
	 		pPage3.Parameters.mStayAddressPlaceType = vFlatType;
			pPage2.Parameters.mStayAddressFlat = vFlat;
	 		pPage3.Parameters.mStayAddressFlat = vFlat;
		EndIf;
	Else
		SetAttributeParameters(pPage2, "mStayAddressRegion", StringToArray("", 31), 31);
		SetAttributeParameters(pPage3, "mStayAddressRegion", StringToArray("", 31), 31);
		SetAttributeParameters(pPage2, "mStayAddressArea", StringToArray("", 31), 31);
		SetAttributeParameters(pPage3, "mStayAddressArea", StringToArray("", 31), 31);
		SetAttributeParameters(pPage2, "mStayAddressCity", StringToArray("", 31), 31);
		SetAttributeParameters(pPage3, "mStayAddressCity", StringToArray("", 31), 31);
		SetAttributeParameters(pPage2, "mStayAddressStreet", StringToArray("", 31), 31);
		SetAttributeParameters(pPage3, "mStayAddressStreet", StringToArray("", 31), 31);

       	pPage2.Parameters.mStayAddressHouseType = "";
       	pPage2.Parameters.mStayAddressHouse = "";
       	pPage2.Parameters.mStayAddressBuilding = "";
		pPage3.Parameters.mStayAddressHouseType = "";
		pPage3.Parameters.mStayAddressHouse = "";
		pPage3.Parameters.mStayAddressBuilding = "";
		pPage2.Parameters.mStayAddressPlaceType = "";
 		pPage3.Parameters.mStayAddressPlaceType = "";
		pPage2.Parameters.mStayAddressFlat = "";
 		pPage3.Parameters.mStayAddressFlat = "";
	EndIf;

	// Hotel phone
	vHotelPhoneStr = "";
	If ValueIsFilled(pRef.Hotel) Then
		vHotelPhoneStr = RemoveDelimeters(TrimAll(pRef.Hotel.Phones));
		If Left(vHotelPhoneStr, 1) = "7" And StrLen(vHotelPhoneStr) > 10 Then
			vHotelPhoneStr = Mid(vHotelPhoneStr, 2);
		EndIf;
		SetAttributeParameters(pPage4, "mHotelPhone", StringToArray(vHotelPhoneStr, 10), 10);
	Else
		SetAttributeParameters(pPage4, "mHotelPhone", StringToArray("", 10), 10);
	EndIf;
	
	// Check out date
	If ValueIsFilled(pRef.CheckOutDate) Then
		vCheckOutDate = StringToArray(DateToString(pRef.CheckOutDate), 8);
		SetAttributeParameters(pPage1, "mCheckOutDate", vCheckOutDate, 8);
		SetAttributeParameters(pPage3, "mCheckOutDate", vCheckOutDate, 8);
	Else
		SetAttributeParameters(pPage1, "mCheckOutDate", StringToArray("", 8), 8);
		SetAttributeParameters(pPage3, "mCheckOutDate", StringToArray("", 8), 8);
	EndIf;

	// Employee that signes notification
	If ValueIsFilled(pEmployee) Then
		// Employee name
		vEmployeeLastName = StringToArray(pEmployee.LastName, 28);
		vEmployeeFirstName = StringToArray(pEmployee.FirstName, 28);
		vEmployeeSecondName = StringToArray(pEmployee.SecondName, 23);
		
		SetAttributeParameters(pPage3, "mEmployeeLastName", vEmployeeLastName, 28);
		SetAttributeParameters(pPage3, "mEmployeeFirstName", vEmployeeFirstName, 28);
		SetAttributeParameters(pPage3, "mEmployeeSecondName", vEmployeeSecondName, 23);
		SetAttributeParameters(pPage4, "mEmployeeLastName", vEmployeeLastName, 28);
		SetAttributeParameters(pPage4, "mEmployeeFirstName", vEmployeeFirstName, 28);
		SetAttributeParameters(pPage4, "mEmployeeSecondName", vEmployeeSecondName, 23);
		
		// Employee living address
		If Not IsBlankString(pEmployee.Address) Then
			vEmployeeAddressStr = pEmployee.Address;
		Else
			vEmployeeAddressStr = vHotelAddressStr;
		EndIf; 
		vEmployeeAddressPars = cmParseAddress(vEmployeeAddressStr);
		
		vEmployeeAddressRegion = StringToArray(vEmployeeAddressPars.Region, 31);
		SetAttributeParameters(pPage3, "mEmployeeAddressRegion", vEmployeeAddressRegion, 31);

		vEmployeeAddressArea = StringToArray(vEmployeeAddressPars.Area, 31);
		SetAttributeParameters(pPage3, "mEmployeeAddressArea", vEmployeeAddressArea, 31);
		
		vEmployeeAddressCity = StringToArray(vEmployeeAddressPars.City, 31);
		SetAttributeParameters(pPage3, "mEmployeeAddressCity", vEmployeeAddressCity, 31);
		
		vEmployeeAddressStreet = StringToArray(vEmployeeAddressPars.Street, 31);
		SetAttributeParameters(pPage3, "mEmployeeAddressStreet", vEmployeeAddressStreet, 31);

		vHouse = TrimAll(vEmployeeAddressPars.House);
		vBuilding = "";
		ParseHouseAndBuilding(vHouse, vBuilding);
		pPage3.Parameters.mEmployeeAddressHouseType = "";
		pPage3.Parameters.mEmployeeAddressHouse = "";
		If Not IsBlankString(vHouse) Then
			pPage3.Parameters.mEmployeeAddressHouseType = "ДОМ";
			pPage3.Parameters.mEmployeeAddressHouse = vHouse;
		EndIf;
		pPage3.Parameters.mEmployeeAddressBuilding = vBuilding;
		
		vFlat = vEmployeeAddressPars.Flat;
		vFlat = StrReplace(vFlat, "/", "");
 		pPage3.Parameters.mEmployeeAddressFlatType = "";
 		pPage3.Parameters.mEmployeeAddressFlat = "";
		If Not IsBlankString(vFlat) Then
	 		pPage3.Parameters.mEmployeeAddressFlatType = "КВАРТИРА";
	 		pPage3.Parameters.mEmployeeAddressFlat = vFlat;
		EndIf;

		// Employee identification document
		If Find(Upper(TrimAll(pEmployee.IdentityDocumentType)), "ПАСПОРТ") > 0 Then
			vEmployeeIDType = StringToArray("ПАСПОРТ", 10);
		Else
			vEmployeeIDType = StringToArray(pEmployee.IdentityDocumentType, 10);
		EndIf;
		SetAttributeParameters(pPage3, "mEmployeeIDType", vEmployeeIDType, 10);
		
		vEmployeeIDSeries = StringToArray(TrimAll(StrReplace(pEmployee.IdentityDocumentSeries, " ", "")), 4);
		SetAttributeParameters(pPage3, "mEmployeeIDSeries", vEmployeeIDSeries, 4);
		
		vEmployeeIDNumber = StringToArray(TrimAll(pEmployee.IdentityDocumentNumber), 12);
		SetAttributeParameters(pPage3, "mEmployeeIDNumber", vEmployeeIDNumber, 12);
		
		vEmployeeIDIssuedDate = StringToArray(DateToString(pEmployee.IdentityDocumentIssueDate), 8);
		SetAttributeParameters(pPage3, "mEmployeeIDIssuedDate", vEmployeeIDIssuedDate, 8);
		
		vEmployeeIDValidToDate = StringToArray(DateToString(pEmployee.IdentityDocumentValidToDate), 8);
		SetAttributeParameters(pPage3, "mEmployeeIDValidToDate", vEmployeeIDValidToDate, 8);
	Else // Employee is not selected, so fill all employee data with blanks except address and phone
		// Employee name
		SetAttributeParameters(pPage3, "mEmployeeLastName", StringToArray("", 28), 28);
		SetAttributeParameters(pPage3, "mEmployeeFirstName", StringToArray("", 28), 28);
		SetAttributeParameters(pPage3, "mEmployeeSecondName", StringToArray("", 23), 23);
		SetAttributeParameters(pPage4, "mEmployeeLastName", StringToArray("", 28), 28);
		SetAttributeParameters(pPage4, "mEmployeeFirstName", StringToArray("", 28), 28);
		SetAttributeParameters(pPage4, "mEmployeeSecondName", StringToArray("", 23), 23);
		
		//SetAttributeParameters(pPage3, "mEmployeeAddress", StringToArray("", 124), 124);
		SetAttributeParameters(pPage3, "mEmployeeAddressRegion", StringToArray("", 31), 31);
		SetAttributeParameters(pPage3, "mEmployeeAddressArea", StringToArray("", 31), 31);
		SetAttributeParameters(pPage3, "mEmployeeAddressCity", StringToArray("", 31), 31);
		SetAttributeParameters(pPage3, "mEmployeeAddressStreet", StringToArray("", 31), 31);
	
		pPage3.Parameters.mEmployeeAddressHouseType = "";
		pPage3.Parameters.mEmployeeAddressHouse = "";
		pPage3.Parameters.mEmployeeAddressBuilding = "";
 		pPage3.Parameters.mEmployeeAddressFlatType = "";
 		pPage3.Parameters.mEmployeeAddressFlat = "";
		
		// Employee identification document
		SetAttributeParameters(pPage3, "mEmployeeIDType", StringToArray("", 10), 10);
		SetAttributeParameters(pPage3, "mEmployeeIDSeries", StringToArray("", 4), 4);
		SetAttributeParameters(pPage3, "mEmployeeIDNumber", StringToArray("", 12), 12);
		SetAttributeParameters(pPage3, "mEmployeeIDIssuedDate", StringToArray("", 8), 8);
		SetAttributeParameters(pPage3, "mEmployeeIDValidToDate", StringToArray("", 8), 8);
	EndIf;
	
	// Hotel address 
	vCompanyAddressPars = cmParseAddress(vCompanyAddressStr);
	vCompanyAddressRegion = StringToArray(vCompanyAddressPars.Region, 31);
	SetAttributeParameters(pPage4, "mHotelAddressRegion", vCompanyAddressRegion, 31);

	vCompanyAddressArea = StringToArray(vCompanyAddressPars.Area, 31);
	SetAttributeParameters(pPage4, "mHotelAddressArea", vCompanyAddressArea, 31);
	
	vCompanyAddressCity = StringToArray(vCompanyAddressPars.City, 31);
	SetAttributeParameters(pPage4, "mHotelAddressCity", vCompanyAddressCity, 31);
	
	vCompanyAddressStreet = StringToArray(vCompanyAddressPars.Street, 31);
	SetAttributeParameters(pPage4, "mHotelAddressStreet", vCompanyAddressStreet, 31);
	
	vHouse = TrimAll(vCompanyAddressPars.House);
	vBuilding = "";
	ParseHouseAndBuilding(vHouse, vBuilding);
	pPage4.Parameters.mHotelAddressHouseType = "";
	pPage4.Parameters.mHotelAddressHouse = "";
	If Not IsBlankString(vHouse) Then
		pPage4.Parameters.mHotelAddressHouseType = "ДОМ";
		pPage4.Parameters.mHotelAddressHouse = vHouse;
	EndIf;
	pPage4.Parameters.mHotelAddressBuilding = vBuilding;
	
	vFlat = vCompanyAddressPars.Flat;
	vFlat = StrReplace(vFlat, "/", "");
	pPage4.Parameters.mHotelAddressFlatType = "";
	pPage4.Parameters.mHotelAddressFlat = "";
	If Not IsBlankString(vFlat) Then
		pPage4.Parameters.mHotelAddressFlat = "КВАРТИРА";
		pPage4.Parameters.mHotelAddressFlat = vFlat;
	EndIf;
	
	// Migration office number
	pPage2.Parameters.mMigrationOfficeNumber = "";
	pPage4.Parameters.mMigrationOfficeNumber = "";
	pPage2.Parameters.mCheckInDate = '00010101';
	pPage4.Parameters.mCheckInDate = '00010101';
	If ValueIsFilled(pRef.Hotel) Then
		If Not IsBlankString(pRef.Hotel.MigrationOfficeNumber) Then
			pPage2.Parameters.mMigrationOfficeNumber = TrimAll(pRef.Hotel.MigrationOfficeNumber);
			pPage4.Parameters.mMigrationOfficeNumber = TrimAll(pRef.Hotel.MigrationOfficeNumber);
			
			pPage2.Parameters.mCheckInDate = pRef.CheckInDate;
			pPage4.Parameters.mCheckInDate = pRef.CheckInDate;
		EndIf;
	EndIf;
EndProcedure // SetParametersNotificationForPages20250205

// -----------------------------------------------------------------------------
Procedure SetParametersNotificationForPages20230101(pPage1, pPage2, pPage3, pPage4, pRef, pEmployee) Export
	Var vVisaSeries;
	Var vVisaNumber;
	Var vMigrationCardSeries;
	Var vMigrationCardNumber;
	
	// Check char
	vX = "Х";
	
	// Try to fill guest data	
	If ValueIsFilled(pRef.Guest) Then
		// Guest name
		If IsBlankString(pRef.LastName) Then
			vGuestLastName = StringToArray(pRef.Guest.LastName, 27);
			vGuestFirstName = StringToArray(pRef.Guest.FirstName, 27);
			vGuestSecondName = StringToArray(pRef.Guest.SecondName, 24);
		Else
			vGuestLastName = StringToArray(pRef.LastName, 27);
			vGuestFirstName = StringToArray(pRef.FirstName, 27);
			vGuestSecondName = StringToArray(pRef.SecondName, 24);
		EndIf;
		
		SetAttributeParameters(pPage1, "mGuestLastName", vGuestLastName, 27);
		SetAttributeParameters(pPage1, "mGuestFirstName", vGuestFirstName, 27);
		SetAttributeParameters(pPage1, "mGuestSecondName", vGuestSecondName, 24);
		
		SetAttributeParameters(pPage3, "mGuestLastName", vGuestLastName, 27);
		SetAttributeParameters(pPage3, "mGuestFirstName", vGuestFirstName, 27);
		SetAttributeParameters(pPage3, "mGuestSecondName", vGuestSecondName, 22);
		
		// Guest citizenship
		vGuestCitizenship = StringToArray(TrimAll(pRef.Citizenship), 26);
		SetAttributeParameters(pPage1, "mGuestCitizenship", vGuestCitizenship, 25);
		SetAttributeParameters(pPage3, "mGuestCitizenship", vGuestCitizenship, 26);
		
		// Guest date of birth
		vGuestDateOfBirth = StringToArray(DateToString(pRef.DateOfBirth), 8);
		SetAttributeParameters(pPage1, "mGuestBirthDate", vGuestDateOfBirth, 8);
		SetAttributeParameters(pPage3, "mGuestBirthDate", vGuestDateOfBirth, 8);
		
		// Guest place of birth
		vGuestPlaceOfBirth = cmParseAddress(pRef.PlaceOfBirth);
		
		vGuestPlaceOfBirthCountry = StringToArray(vGuestPlaceOfBirth.Country, 24);
		SetAttributeParameters(pPage1, "mGuestBirthPlaceCountry", vGuestPlaceOfBirthCountry, 24);
		SetAttributeParameters(pPage3, "mGuestBirthPlaceCountry", vGuestPlaceOfBirthCountry, 24);
		
		vGuestPlaceOfBirthCity = StringToArray(vGuestPlaceOfBirth.City, 48);
		SetAttributeParameters(pPage1, "mGuestBirthPlaceCity", vGuestPlaceOfBirthCity, 48);
		SetAttributeParameters(pPage3, "mGuestBirthPlaceCity", vGuestPlaceOfBirthCity, 48);
		
		// Guest sex
		If pRef.Sex = Enums.Sex.Male Then
			pPage1.Parameters.mGuestSexMale = vX;
			pPage1.Parameters.mGuestSexFemale = "";
			pPage3.Parameters.mGuestSexMale = vX;
			pPage3.Parameters.mGuestSexFemale = "";
		ElsIf pRef.Sex = Enums.Sex.Female Then
			pPage1.Parameters.mGuestSexMale = "";
			pPage1.Parameters.mGuestSexFemale = vX;
			pPage3.Parameters.mGuestSexMale = "";
			pPage3.Parameters.mGuestSexFemale = vX;
		Else
			pPage1.Parameters.mGuestSexMale = "";
			pPage1.Parameters.mGuestSexFemale = "";
			pPage3.Parameters.mGuestSexMale = "";
			pPage3.Parameters.mGuestSexFemale = "";
		EndIf;
		
		// Guest phone
		If IsBlankString(pRef.Guest.Phone) Then
			SetAttributeParameters(pPage1, "mGuestPhone", StringToArray("", 10), 10);
		Else
			vGuestPhone = TrimAll(pRef.Guest.Phone);
			If Left(vGuestPhone, 1) = "7" And StrLen(vGuestPhone) > 10 Then
				vGuestPhone = Mid(vGuestPhone, 2);
			EndIf;
			SetAttributeParameters(pPage1, "mGuestPhone", StringToArray(vGuestPhone, 10), 10);
		EndIf;
		
		// Guest identification document
		If Find(Upper(TrimAll(pRef.IdentityDocumentType)), "ПАСПОРТ") > 0 Then
			vGuestIDType = StringToArray("ПАСПОРТ", 11);
		Else
			vGuestIDType = StringToArray(pRef.IdentityDocumentType, 11);
		EndIf;
		SetAttributeParameters(pPage1, "mGuestIDType", vGuestIDType, 10);
		SetAttributeParameters(pPage3, "mGuestIDType", vGuestIDType, 11);
		
		vGuestIDSeries = StringToArray(TrimAll(StrReplace(pRef.IdentityDocumentSeries, " ", "")), 4);
		SetAttributeParameters(pPage1, "mGuestIDSeries", vGuestIDSeries, 4);
		SetAttributeParameters(pPage3, "mGuestIDSeries", vGuestIDSeries, 4);
		
		vGuestIDNumber = StringToArray(TrimAll(pRef.IdentityDocumentNumber), 11);
		SetAttributeParameters(pPage1, "mGuestIDNumber", vGuestIDNumber, 11);
		SetAttributeParameters(pPage3, "mGuestIDNumber", vGuestIDNumber, 11);
		
		vGuestIDIssuedDate = StringToArray(DateToString(pRef.IdentityDocumentIssueDate), 8);
		SetAttributeParameters(pPage1, "mGuestIDIssuedDate", vGuestIDIssuedDate, 8);
		SetAttributeParameters(pPage3, "mGuestIDIssuedDate", vGuestIDIssuedDate, 8);
		
		vGuestIDValidToDate = StringToArray(DateToString(pRef.IdentityDocumentValidToDate), 8);
		SetAttributeParameters(pPage1, "mGuestIDValidToDate", vGuestIDValidToDate, 8);
		SetAttributeParameters(pPage3, "mGuestIDValidToDate", vGuestIDValidToDate, 8);
	Else // Guest is not selected, so fill all guest data with blanks
		// Guest name
		SetAttributeParameters(pPage1, "mGuestLastName", StringToArray("", 27), 27);
		SetAttributeParameters(pPage1, "mGuestFirstName", StringToArray("", 27), 27);
		SetAttributeParameters(pPage1, "mGuestSecondName", StringToArray("", 24), 24);
		
		SetAttributeParameters(pPage3, "mGuestLastName", StringToArray("", 27), 27);
		SetAttributeParameters(pPage3, "mGuestFirstName", StringToArray("", 27), 27);
		SetAttributeParameters(pPage3, "mGuestSecondName", StringToArray("", 22), 22);
		
		// Guest citizenship
		SetAttributeParameters(pPage1, "mGuestCitizenship", StringToArray("", 25), 25);
		SetAttributeParameters(pPage3, "mGuestCitizenship", StringToArray("", 26), 26);
		
		// Guest date of birth
		SetAttributeParameters(pPage1, "mGuestBirthDate", StringToArray("", 8), 8);
		SetAttributeParameters(pPage3, "mGuestBirthDate", StringToArray("", 8), 8);
		
		// Guest place of birth
		SetAttributeParameters(pPage1, "mGuestBirthPlaceCountry", StringToArray("", 24), 24);
		SetAttributeParameters(pPage1, "mGuestBirthPlaceCity", StringToArray("", 48), 48);
		SetAttributeParameters(pPage3, "mGuestBirthPlaceCountry", StringToArray("", 24), 24);
		SetAttributeParameters(pPage3, "mGuestBirthPlaceCity", StringToArray("", 48), 48);
		
		// Guest sex
		pPage1.Parameters.mGuestSexMale = "";
		pPage1.Parameters.mGuestSexFemale = "";
		pPage3.Parameters.mGuestSexMale = "";
		pPage3.Parameters.mGuestSexFemale = "";
		
		// Guest phone
		SetAttributeParameters(pPage1, "mGuestPhone", StringToArray("", 10), 10);
		
		// Guest identification document
		SetAttributeParameters(pPage1, "mGuestIDType", StringToArray("", 11), 11);
		SetAttributeParameters(pPage3, "mGuestIDType", StringToArray("", 11), 11);
		SetAttributeParameters(pPage1, "mGuestIDSeries", StringToArray("", 4), 4);
		SetAttributeParameters(pPage3, "mGuestIDSeries", StringToArray("", 4), 4);
		SetAttributeParameters(pPage1, "mGuestIDNumber", StringToArray("", 11), 11);
		SetAttributeParameters(pPage3, "mGuestIDNumber", StringToArray("", 11), 11);
		SetAttributeParameters(pPage1, "mGuestIDIssuedDate", StringToArray("", 8), 8);
		SetAttributeParameters(pPage3, "mGuestIDIssuedDate", StringToArray("", 8), 8);
		SetAttributeParameters(pPage1, "mGuestIDValidToDate", StringToArray("", 8), 8);
		SetAttributeParameters(pPage3, "mGuestIDValidToDate", StringToArray("", 8), 8);
	EndIf;
	
	// Guest profession and standing
	vGuestProfession = StringToArray(TrimAll(pRef.Profession), 26);
	SetAttributeParameters(pPage1, "mGuestProfession", vGuestProfession, 26);
	
	// Legal representatives
	If Not IsBlankString(pRef.LegalRepresentativeLastName) Then
		vLegalRepresentativeName = TrimAll(TrimAll(pRef.LegalRepresentativeLastName) + " " + TrimAll(pRef.LegalRepresentativeFirstName) + " " + TrimAll(pRef.LegalRepresentativeSecondName));
		vLegalRepresentative = pRef.LegalRepresentative;
		If ValueIsFilled(vLegalRepresentative) Then
			vLegalRepresentatives = StringToArray(vLegalRepresentativeName + 
			                        ?(ValueIsFilled(vLegalRepresentative.DateOfBirth), ", " + Format(vLegalRepresentative.DateOfBirth, "DF=dd.MM.yyyy"), "") +
			                        ?(ValueIsFilled(vLegalRepresentative.Sex), ", " + TrimAll(vLegalRepresentative.Sex), "") + 
									?(Not IsBlankString(vLegalRepresentative.IdentityDocumentNumber), ", №" + TrimAll(TrimAll(vLegalRepresentative.IdentityDocumentSeries) + " " + TrimAll(vLegalRepresentative.IdentityDocumentNumber)), ""), 75);
		Else
			vLegalRepresentatives = StringToArray(vLegalRepresentativeName, 75);
		EndIf;
	ElsIf ValueIsFilled(pRef.LegalRepresentative) Then
		vLegalRepresentative = pRef.LegalRepresentative;
		vLegalRepresentatives = StringToArray(TrimAll(TrimAll(vLegalRepresentative.LastName) + " " + TrimAll(vLegalRepresentative.FirstName) + " " + TrimAll(vLegalRepresentative.SecondName)) + 
		                        ?(ValueIsFilled(vLegalRepresentative.DateOfBirth), ", " + Format(vLegalRepresentative.DateOfBirth, "DF=dd.MM.yyyy"), "") +
		                        ?(ValueIsFilled(vLegalRepresentative.Sex), ", " + TrimAll(vLegalRepresentative.Sex), "") + 
								?(Not IsBlankString(vLegalRepresentative.IdentityDocumentNumber), ", №" + TrimAll(TrimAll(vLegalRepresentative.IdentityDocumentSeries) + " " + TrimAll(vLegalRepresentative.IdentityDocumentNumber)), ""), 75);
	ElsIf Not IsBlankString(pRef.LegalRepresentatives) Then
		vLegalRepresentatives = StringToArray(TrimAll(pRef.LegalRepresentatives), 75);
	Else
		vLegalRepresentatives = StringToArray("", 75);
	EndIf;
	SetAttributeParameters(pPage1, "mLegalRepresentatives", vLegalRepresentatives, 75);
	
	// Previous place of stay
	vPreviousPlaceOfStay = StringToArray(TrimAll(pRef.PreviousPlaceOfStay), 102);
	SetAttributeParameters(pPage2, "mPreviousStayAddress", vPreviousPlaceOfStay, 102);
	
	// Visa
	If Not IsBlankString(pRef.VisaNumber) Then
		pPage1.Parameters.mVisa = vX;
		
		SeriesAndNumberToArray(pRef.VisaNumber, 4, 15, vVisaSeries, vVisaNumber);
		SetAttributeParameters(pPage1, "mVisaSeries", vVisaSeries, 4);
		SetAttributeParameters(pPage1, "mVisaNumber", vVisaNumber, 15);
		
		vVisaIssuedDate = StringToArray(DateToString(pRef.VisaIssuedDate), 8);
		SetAttributeParameters(pPage1, "mVisaIssuedDate", vVisaIssuedDate, 8);
		
		vVisaValidToDate = StringToArray(DateToString(pRef.VisaToDate), 8);
		SetAttributeParameters(pPage1, "mVisaValidToDate", vVisaValidToDate, 8);
	Else
		pPage1.Parameters.mVisa = "";
		
		SetAttributeParameters(pPage1, "mVisaSeries", StringToArray("", 4), 4);
		SetAttributeParameters(pPage1, "mVisaNumber", StringToArray("", 15), 15);
		
		SetAttributeParameters(pPage1, "mVisaIssuedDate", StringToArray("", 8), 8);
		
		SetAttributeParameters(pPage1, "mVisaValidToDate", StringToArray("", 8), 8);
	EndIf;
	
	pPage1.Parameters.mResidencePermit = "";
	pPage1.Parameters.mTempResidencePermit = "";
	pPage1.Parameters.mTempResidencePermitForEducation = "";
	If ValueIsFilled(pRef.ResidencePermitDocument) And pRef.ResidencePermitDocument = Enums.ConfirmingDocuments.PermResidencePermit Or 
	   ValueIsFilled(pRef.VisaType) And TrimAll(pRef.VisaType.Code) = "ВЖ" Then
		pPage1.Parameters.mVisa = "";
		pPage1.Parameters.mResidencePermit = vX;
		
		SeriesAndNumberToArray(pRef.VisaNumber, 4, 15, vVisaSeries, vVisaNumber);
		SetAttributeParameters(pPage1, "mVisaSeries", vVisaSeries, 4);
		SetAttributeParameters(pPage1, "mVisaNumber", vVisaNumber, 15);
		
		vVisaFromDate = StringToArray(DateToString(pRef.VisaFromDate), 8);
		SetAttributeParameters(pPage1, "mVisaIssuedDate", vVisaFromDate, 8);
		
		vVisaValidToDate = StringToArray(DateToString(pRef.VisaToDate), 8);
		SetAttributeParameters(pPage1, "mVisaValidToDate", vVisaValidToDate, 8);
	ElsIf ValueIsFilled(pRef.ResidencePermitDocument) And pRef.ResidencePermitDocument = Enums.ConfirmingDocuments.TempResidencePermit Or 
	      ValueIsFilled(pRef.VisaType) And TrimAll(pRef.VisaType.Code) = "ВР" Then
		pPage1.Parameters.mVisa = "";
		If pRef.ForEducationPurposes Then
			pPage1.Parameters.mTempResidencePermitForEducation = vX;
		Else
			pPage1.Parameters.mTempResidencePermit = vX;
		EndIf;
		
		SeriesAndNumberToArray(pRef.VisaIdentifier, 4, 15, vVisaSeries, vVisaNumber);
		SetAttributeParameters(pPage1, "mVisaSeries", vVisaSeries, 4);
		SetAttributeParameters(pPage1, "mVisaNumber", vVisaNumber, 15);
		
		vVisaIssuedDate = StringToArray(DateToString(pRef.VisaIssuedDate), 8);
		SetAttributeParameters(pPage1, "mVisaIssuedDate", vVisaIssuedDate, 8);
		
		vVisaValidToDate = StringToArray(DateToString(pRef.VisaToDate), 8);
		SetAttributeParameters(pPage1, "mVisaValidToDate", vVisaValidToDate, 8);
	ElsIf ValueIsFilled(pRef.IdentityDocumentType) And TrimAll(pRef.IdentityDocumentType.Code) = "12" Or
	      ValueIsFilled(pRef.IdentityDocumentType) And TrimAll(pRef.IdentityDocumentType.Code) = "19" Or
	      ValueIsFilled(pRef.IdentityDocumentType) And TrimAll(pRef.IdentityDocumentType.Code) = "20" Then
		pPage1.Parameters.mVisa = "";
		pPage1.Parameters.mResidencePermit = vX;
		
		SeriesAndNumberToArray(pRef.VisaNumber, 4, 15, vVisaSeries, vVisaNumber);
		SetAttributeParameters(pPage1, "mVisaSeries", vVisaSeries, 4);
		SetAttributeParameters(pPage1, "mVisaNumber", vVisaNumber, 15);
		
		vVisaFromDate = StringToArray(DateToString(pRef.VisaFromDate), 8);
		SetAttributeParameters(pPage1, "mVisaIssuedDate", vVisaFromDate, 8);
		
		vVisaValidToDate = StringToArray(DateToString(pRef.VisaToDate), 8);
		SetAttributeParameters(pPage1, "mVisaValidToDate", vVisaValidToDate, 8);
	ElsIf ValueIsFilled(pRef.IdentityDocumentType) And TrimAll(pRef.IdentityDocumentType.Code) = "101" Or
	      ValueIsFilled(pRef.IdentityDocumentType) And TrimAll(pRef.IdentityDocumentType.Code) = "101a" Then
		pPage1.Parameters.mVisa = "";
		pPage1.Parameters.mTempResidencePermit = vX;
		
		SeriesAndNumberToArray(pRef.VisaIdentifier, 4, 15, vVisaSeries, vVisaNumber);
		SetAttributeParameters(pPage1, "mVisaSeries", vVisaSeries, 4);
		SetAttributeParameters(pPage1, "mVisaNumber", vVisaNumber, 15);
		
		vVisaIssuedDate = StringToArray(DateToString(pRef.VisaIssuedDate), 8);
		SetAttributeParameters(pPage1, "mVisaIssuedDate", vVisaIssuedDate, 8);
		
		vVisaValidToDate = StringToArray(DateToString(pRef.VisaToDate), 8);
		SetAttributeParameters(pPage1, "mVisaValidToDate", vVisaValidToDate, 8);
	EndIf;

	// Migration card
	If Not IsBlankString(pRef.MigrationCardNumber) Then
		vSeriesLength = 4;
		vBlankPos = Find(TrimAll(pRef.MigrationCardNumber), " ");
		If vBlankPos > 4 Then
			vSeriesLength = vBlankPos - 1;
		EndIf;
		If StrLen(TrimAll(pRef.MigrationCardNumber)) >= 14 Then
			SeriesAndNumberToArray(pRef.MigrationCardNumber, vSeriesLength, 11, vMigrationCardSeries, vMigrationCardNumber);
		Else
			vMigrationCardSeries = StringToArray(Left(TrimAll(pRef.MigrationCardNumber), vSeriesLength), vSeriesLength);
			vMigrationCardNumber = StringToArray(Right(TrimAll(pRef.MigrationCardNumber), StrLen(TrimAll(pRef.MigrationCardNumber)) - vSeriesLength), 11);
		EndIf;
		SetAttributeParameters(pPage1, "mMigrationCardSeries", vMigrationCardSeries, 4);
		SetAttributeParameters(pPage1, "mMigrationCardNumber", vMigrationCardNumber, 11);
	EndIf;

	vBorderCrossingDate = StringToArray(DateToString(pRef.BorderCrossingDate), 8);
	SetAttributeParameters(pPage1, "mBorderCrossingDate", vBorderCrossingDate, 8);
	
	// Guest trip purpose
	pPage1.Parameters.mTripPurposeOfficial = "";
	pPage1.Parameters.mTripPurposeTourism = "";
	pPage1.Parameters.mTripPurposeBusiness = "";
	pPage1.Parameters.mTripPurposeStudying = "";
	pPage1.Parameters.mTripPurposeWork = "";
	pPage1.Parameters.mTripPurposePrivate = "";
	pPage1.Parameters.mTripPurposeTransit = "";
	pPage1.Parameters.mTripPurposeHumanitarian = "";
	pPage1.Parameters.mTripPurposeOther = "";
	
	If pRef.TripPurpose = Catalogs.TripPurposes.Official Or 
	   pRef.TripPurpose = Catalogs.TripPurposes.Commerce Then
		pPage1.Parameters.mTripPurposeOfficial = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Tourism Then
		pPage1.Parameters.mTripPurposeTourism = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Business Then
		pPage1.Parameters.mTripPurposeBusiness = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Study Or
	      pRef.TripPurpose = Catalogs.TripPurposes.Scientific Then
		pPage1.Parameters.mTripPurposeStudying = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Work Then
		pPage1.Parameters.mTripPurposeWork = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Private Then
		pPage1.Parameters.mTripPurposePrivate = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Transit Or 
		  pRef.TripPurpose = Catalogs.TripPurposes.Crewman Then
		pPage1.Parameters.mTripPurposeTransit = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Humanitarian Then
		pPage1.Parameters.mTripPurposeHumanitarian = vX;
	Else
		pPage1.Parameters.mTripPurposeOther = vX;
	EndIf;
	
	// Company name and TIN
	vCompany = Undefined;
	If ValueIsFilled(pRef.Hotel) And ValueIsFilled(pRef.Hotel.CompanyRegisteredInUFMS) Then
		vCompany = pRef.Hotel.CompanyRegisteredInUFMS;
	Else 
		If ValueIsFilled(pRef.ParentDoc) And ValueIsFilled(pRef.ParentDoc.Company) Then
			vCompany = pRef.ParentDoc.Company;
		Else
			vCompany = pRef.Hotel.Company;
		EndIf;
	EndIf;
	vCompanyAddressStr = "";
	If ValueIsFilled(vCompany) Then
		vCompanyAddressStr = TrimAll(vCompany.PostAddress);
		
		vCompanyName = StringToArray(StrReplace(TrimAll(vCompany.LegacyName),"""",""), 42);
		SetAttributeParameters(pPage4, "mCompanyName", vCompanyName, 42);
		
		vCompanyTIN = StringToArray(vCompany.TIN, 11);
		SetAttributeParameters(pPage4, "mCompanyTIN", vCompanyTIN, 11);
		
		SetAttributeParameters(pPage2, "mCompanyDocumentGivingRightToProvidePremises1Row", StringToArray("", 21), 21);
		SetAttributeParameters(pPage2, "mCompanyDocumentGivingRightToProvidePremises2Row", StringToArray("", 21), 21);
		SetAttributeParameters(pPage2, "mCompanyDocumentGivingRightToProvidePremises3Row", StringToArray("", 21), 21);
	
		vCompanyDocumentGivingRightToProvidePremisesArray = cmGetTextLinesArray(TrimAll(vCompany.DocumentGivingRightToProvidePremises));
		i = 0;
		While i < vCompanyDocumentGivingRightToProvidePremisesArray.Count() Do
			If i = 0 Then
				vCharsArray = StringToArray(vCompanyDocumentGivingRightToProvidePremisesArray.Get(i), 21);
				SetAttributeParameters(pPage2, "mCompanyDocumentGivingRightToProvidePremises1Row", vCharsArray, 21);
			ElsIf i = 1 Then
				vCharsArray = StringToArray(vCompanyDocumentGivingRightToProvidePremisesArray.Get(i), 21);
				SetAttributeParameters(pPage2, "mCompanyDocumentGivingRightToProvidePremises2Row", vCharsArray, 21);
			ElsIf i = 2 Then
				vCharsArray = StringToArray(vCompanyDocumentGivingRightToProvidePremisesArray.Get(i), 21);
				SetAttributeParameters(pPage2, "mCompanyDocumentGivingRightToProvidePremises3Row", vCharsArray, 21);
			Else
				Break;
			EndIf;
			i = i + 1;
		EndDo;
	Else
		SetAttributeParameters(pPage4, "mCompanyName", StringToArray("", 42), 42);
		
		SetAttributeParameters(pPage4, "mCompanyTIN", StringToArray("", 11), 11);
		
		SetAttributeParameters(pPage2, "mCompanyDocumentGivingRightToProvidePremises1Row", StringToArray("", 21), 21);
		SetAttributeParameters(pPage2, "mCompanyDocumentGivingRightToProvidePremises2Row", StringToArray("", 21), 21);
		SetAttributeParameters(pPage2, "mCompanyDocumentGivingRightToProvidePremises3Row", StringToArray("", 21), 21);
	EndIf;
		
	// Hotel address
	vHotelAddressStr = "";
	If ValueIsFilled(pRef.Hotel) Then
		vHotelAddressStr = pRef.Hotel.PostAddress;
		vAddress = cmParseAddress(vHotelAddressStr);
		
		vAddressRegion = StringToArray(vAddress.Region, 50);
		SetAttributeParameters(pPage2, "mAddressRegion", vAddressRegion, 50);
		SetAttributeParameters(pPage3, "mAddressRegion", vAddressRegion, 48);
		
		vAddressArea = StringToArray(vAddress.Area, 25);
		SetAttributeParameters(pPage2, "mAddressArea", vAddressArea, 25);
		SetAttributeParameters(pPage3, "mAddressArea", vAddressArea, 25);
		
		vAddressCity = StringToArray(vAddress.City, 25);
		SetAttributeParameters(pPage2, "mAddressCity", vAddressCity, 24);
		SetAttributeParameters(pPage3, "mAddressCity", vAddressCity, 24);
		
		vAddressStreet = StringToArray(vAddress.Street, 26);
		SetAttributeParameters(pPage2, "mAddressStreet", vAddressStreet, 25);
		SetAttributeParameters(pPage3, "mAddressStreet", vAddressStreet, 25);
		
		vHouse = TrimAll(vAddress.House);
		vBuilding = "";
		vHouseBuilding = "";
		ParseHouseNumber(vHouse, vBuilding, vHouseBuilding);
		
		vAddressHouse = StringToArray(TrimAll(vHouse), 8);
		SetAttributeParameters(pPage2, "mAddressHouse", vAddressHouse, 8);
		SetAttributeParameters(pPage3, "mAddressHouse", vAddressHouse, 8);
		
		If Not IsBlankString(vBuilding) Then
			vAddressBuilding = StringToArray(vBuilding, 5);
		Else
			vAddressBuilding = StringToArray("", 5);
		EndIf;
		SetAttributeParameters(pPage2, "mAddressBuilding", vAddressBuilding, 5);
		SetAttributeParameters(pPage3, "mAddressBuilding", vAddressBuilding, 5);
		
		If Not IsBlankString(vHouseBuilding) Then
			vAddressHouseBuilding = StringToArray(vHouseBuilding, 4);
		Else
			vAddressHouseBuilding = StringToArray("", 4);
		EndIf;
		SetAttributeParameters(pPage2, "mAddressHouseBuilding", vAddressHouseBuilding, 4);
		SetAttributeParameters(pPage3, "mAddressHouseBuilding", vAddressHouseBuilding, 4);
		
		vFlat = vAddress.Flat;
		If IsBlankString(vFlat) And ValueIsFilled(pRef.Room) Then
			vFlat = TrimAll(pRef.Room);
		EndIf;
		vFlat = StrReplace(vFlat, "/", "");
		vAddressFlat = StringToArray(vFlat, 5);
		SetAttributeParameters(pPage2, "mAddressFlat", vAddressFlat, 5);
		SetAttributeParameters(pPage3, "mAddressFlat", vAddressFlat, 5);
	Else
		SetAttributeParameters(pPage2, "mAddressRegion", StringToArray("", 50), 50);
		SetAttributeParameters(pPage3, "mAddressRegion", StringToArray("", 48), 48);
		
		SetAttributeParameters(pPage2, "mAddressArea", StringToArray("", 25), 25);
		SetAttributeParameters(pPage3, "mAddressArea", StringToArray("", 25), 25);
		
		SetAttributeParameters(pPage2, "mAddressCity", StringToArray("", 24), 24);
		SetAttributeParameters(pPage3, "mAddressCity", StringToArray("", 24), 24);
		
		SetAttributeParameters(pPage2, "mAddressStreet", StringToArray("", 25), 25);
		SetAttributeParameters(pPage3, "mAddressStreet", StringToArray("", 25), 25);
		
		SetAttributeParameters(pPage2, "mAddressHouse", StringToArray("", 8), 8);
		SetAttributeParameters(pPage3, "mAddressHouse", StringToArray("", 8), 8);
		
		SetAttributeParameters(pPage2, "mAddressBuilding", StringToArray("", 5), 5);
		SetAttributeParameters(pPage3, "mAddressBuilding", StringToArray("", 5), 5);
		
		SetAttributeParameters(pPage2, "mAddressHouseBuilding", StringToArray("", 4), 4);
		SetAttributeParameters(pPage3, "mAddressHouseBuilding", StringToArray("", 4), 4);
		
		SetAttributeParameters(pPage2, "mAddressFlat", StringToArray("", 5), 5);
		SetAttributeParameters(pPage3, "mAddressFlat", StringToArray("", 5), 5);
	EndIf;

	// Hotel phone
	vHotelPhoneStr = "";
	If ValueIsFilled(pRef.Hotel) Then
		vHotelPhoneStr = RemoveDelimeters(TrimAll(pRef.Hotel.Phones));
		If Left(vHotelPhoneStr, 1) = "7" And StrLen(vHotelPhoneStr) > 10 Then
			vHotelPhoneStr = Mid(vHotelPhoneStr, 2);
		EndIf;
		SetAttributeParameters(pPage4, "mHotelPhone", StringToArray(vHotelPhoneStr, 10), 10);
	Else
		SetAttributeParameters(pPage4, "mHotelPhone", StringToArray("", 10), 10);
	EndIf;
	
	// Check out date
	If ValueIsFilled(pRef.CheckOutDate) Then
		If ValueIsFilled(pRef.MigrationCardDateTo) Then
			vCheckOutDate = StringToArray(DateToString(pRef.MigrationCardDateTo), 8);
		Else
			vCheckOutDate = StringToArray(DateToString(pRef.CheckOutDate), 8);
		EndIf;
		SetAttributeParameters(pPage1, "mCheckOutDate", vCheckOutDate, 8);
		SetAttributeParameters(pPage3, "mCheckOutDate", vCheckOutDate, 8);
	Else
		SetAttributeParameters(pPage1, "mCheckOutDate", StringToArray("", 8), 8);
		SetAttributeParameters(pPage3, "mCheckOutDate", StringToArray("", 8), 8);
	EndIf;

	// Employee that signes notification
	If ValueIsFilled(pEmployee) Then
		// Employee name
		vEmployeeLastName = StringToArray(pEmployee.LastName, 28);
		vEmployeeFirstName = StringToArray(pEmployee.FirstName, 28);
		vEmployeeSecondName = StringToArray(pEmployee.SecondName, 25);
		
		SetAttributeParameters(pPage3, "mEmployeeLastName", vEmployeeLastName, 27);
		SetAttributeParameters(pPage3, "mEmployeeFirstName", vEmployeeFirstName, 27);
		SetAttributeParameters(pPage3, "mEmployeeSecondName", vEmployeeSecondName, 22);
		SetAttributeParameters(pPage4, "mEmployeeLastName", vEmployeeLastName, 27);
		SetAttributeParameters(pPage4, "mEmployeeFirstName", vEmployeeFirstName, 27);
		SetAttributeParameters(pPage4, "mEmployeeSecondName", vEmployeeSecondName, 24);
		
		// Employee living address
		If Not IsBlankString(pEmployee.Address) Then
			vEmployeeAddress = cmParseAddress(pEmployee.Address);
		Else
			vEmployeeAddress = cmParseAddress(vHotelAddressStr);
		EndIf;
		
		vEmployeeAddressRegion = StringToArray(vEmployeeAddress.Region, 48);
		SetAttributeParameters(pPage3, "mEmployeeAddressRegion", vEmployeeAddressRegion, 48);
		
		vEmployeeAddressArea = StringToArray(vEmployeeAddress.Area, 25);
		SetAttributeParameters(pPage3, "mEmployeeAddressArea", vEmployeeAddressArea, 25);
		
		vEmployeeAddressCity = StringToArray(vEmployeeAddress.City, 23);
		SetAttributeParameters(pPage3, "mEmployeeAddressCity", vEmployeeAddressCity, 23);
		
		vEmployeeAddressStreet = StringToArray(vEmployeeAddress.Street, 25);
		SetAttributeParameters(pPage3, "mEmployeeAddressStreet", vEmployeeAddressStreet, 25);
		
		vHouse = TrimAll(vEmployeeAddress.House);
		vBuilding = "";
		vHouseBuilding = "";
		ParseHouseNumber(vHouse, vBuilding, vHouseBuilding);
		
		vEmployeeAddressHouse = StringToArray(vHouse, 4);
		SetAttributeParameters(pPage3, "mEmployeeAddressHouse", vEmployeeAddressHouse, 4);
		
		If Not IsBlankString(vBuilding) Then
			vEmployeeAddressBuilding = StringToArray(vBuilding, 5);
		Else
			vEmployeeAddressBuilding = StringToArray("", 5);
		EndIf;
		SetAttributeParameters(pPage3, "mEmployeeAddressBuilding", vEmployeeAddressBuilding, 5);
		
		If Not IsBlankString(vHouseBuilding) Then
			vEmployeeAddressHouseBuilding = StringToArray(vHouseBuilding, 4);
		Else
			vEmployeeAddressHouseBuilding = StringToArray("", 4);
		EndIf;
		SetAttributeParameters(pPage3, "mEmployeeAddressHouseBuilding", vEmployeeAddressHouseBuilding, 4);
		
		vEmployeeAddressFlat = StringToArray(vEmployeeAddress.Flat, 4);
		SetAttributeParameters(pPage3, "mEmployeeAddressFlat", vEmployeeAddressFlat, 4);
		
		// Employee identification document
		If Find(Upper(TrimAll(pEmployee.IdentityDocumentType)), "ПАСПОРТ") > 0 Then
			vEmployeeIDType = StringToArray("ПАСПОРТ", 11);
		Else
			vEmployeeIDType = StringToArray(pEmployee.IdentityDocumentType, 11);
		EndIf;
		SetAttributeParameters(pPage3, "mEmployeeIDType", vEmployeeIDType, 11);
		
		vEmployeeIDSeries = StringToArray(TrimAll(StrReplace(pEmployee.IdentityDocumentSeries, " ", "")), 4);
		SetAttributeParameters(pPage3, "mEmployeeIDSeries", vEmployeeIDSeries, 4);
		
		vEmployeeIDNumber = StringToArray(TrimAll(pEmployee.IdentityDocumentNumber), 11);
		SetAttributeParameters(pPage3, "mEmployeeIDNumber", vEmployeeIDNumber, 11);
		
		vEmployeeIDIssuedDate = StringToArray(DateToString(pEmployee.IdentityDocumentIssueDate), 8);
		SetAttributeParameters(pPage3, "mEmployeeIDIssuedDate", vEmployeeIDIssuedDate, 8);
		
		vEmployeeIDValidToDate = StringToArray(DateToString(pEmployee.IdentityDocumentValidToDate), 8);
		SetAttributeParameters(pPage3, "mEmployeeIDValidToDate", vEmployeeIDValidToDate, 8);
	Else // Employee is not selected, so fill all employee data with blanks except address and phone
		// Employee name
		SetAttributeParameters(pPage3, "mEmployeeLastName", StringToArray("", 27), 27);
		SetAttributeParameters(pPage3, "mEmployeeFirstName", StringToArray("", 27), 27);
		SetAttributeParameters(pPage3, "mEmployeeSecondName", StringToArray("", 22), 22);
		SetAttributeParameters(pPage4, "mEmployeeLastName", StringToArray("", 27), 27);
		SetAttributeParameters(pPage4, "mEmployeeFirstName", StringToArray("", 27), 27);
		SetAttributeParameters(pPage4, "mEmployeeSecondName", StringToArray("", 24), 24);
		
		// Employee living address
		vEmployeeAddress = cmParseAddress(vHotelAddressStr);
		
		vEmployeeAddressRegion = StringToArray(vEmployeeAddress.Region, 48);
		SetAttributeParameters(pPage3, "mEmployeeAddressRegion", vEmployeeAddressRegion, 48);
		
		vEmployeeAddressArea = StringToArray(vEmployeeAddress.Area, 25);
		SetAttributeParameters(pPage3, "mEmployeeAddressArea", vEmployeeAddressArea, 25);
		
		vEmployeeAddressCity = StringToArray(vEmployeeAddress.City, 23);
		SetAttributeParameters(pPage3, "mEmployeeAddressCity", vEmployeeAddressCity, 23);
		
		vEmployeeAddressStreet = StringToArray(vEmployeeAddress.Street, 25);
		SetAttributeParameters(pPage3, "mEmployeeAddressStreet", vEmployeeAddressStreet, 25);
		
		vHouse = TrimAll(vEmployeeAddress.House);
		vBuilding = "";
		vHouseBuilding = "";
		ParseHouseNumber(vHouse, vBuilding, vHouseBuilding);
		
		vEmployeeAddressHouse = StringToArray(vHouse, 4);
		SetAttributeParameters(pPage3, "mEmployeeAddressHouse", vEmployeeAddressHouse, 4);
		
		If Not IsBlankString(vBuilding) Then
			vEmployeeAddressBuilding = StringToArray(vBuilding, 5);
		Else
			vEmployeeAddressBuilding = StringToArray("", 5);
		EndIf;
		SetAttributeParameters(pPage3, "mEmployeeAddressBuilding", vEmployeeAddressBuilding, 5);
		
		If Not IsBlankString(vHouseBuilding) Then
			vEmployeeAddressHouseBuilding = StringToArray(vHouseBuilding, 4);
		Else
			vEmployeeAddressHouseBuilding = StringToArray("", 4);
		EndIf;
		SetAttributeParameters(pPage3, "mEmployeeAddressHouseBuilding", vEmployeeAddressHouseBuilding, 4);
		
		vEmployeeAddressFlat = StringToArray(vEmployeeAddress.Flat, 4);
		SetAttributeParameters(pPage3, "mEmployeeAddressFlat", vEmployeeAddressFlat, 4);
		
		// Employee identification document
		SetAttributeParameters(pPage3, "mEmployeeIDType", StringToArray("", 11), 11);
		
		SetAttributeParameters(pPage3, "mEmployeeIDSeries", StringToArray("", 4), 4);
		
		SetAttributeParameters(pPage3, "mEmployeeIDNumber", StringToArray("", 11), 11);
		
		SetAttributeParameters(pPage3, "mEmployeeIDIssuedDate", StringToArray("", 8), 8);
		
		SetAttributeParameters(pPage3, "mEmployeeIDValidToDate", StringToArray("", 8), 8);
	EndIf;
	
	// Hotel address
	vCompanyAddress = StringToArray(cmGetAddressPresentation(vCompanyAddressStr), 84);
	SetAttributeParameters(pPage4, "mHotelAddress", vCompanyAddress, 84);
	
	// Migration office number
	pPage2.Parameters.mMigrationOfficeNumber = "";
	pPage4.Parameters.mMigrationOfficeNumber = "";
	pPage2.Parameters.mCheckInDate = '00010101';
	pPage4.Parameters.mCheckInDate = '00010101';
	If ValueIsFilled(pRef.Hotel) Then
		If Not IsBlankString(pRef.Hotel.MigrationOfficeNumber) Then
			pPage2.Parameters.mMigrationOfficeNumber = TrimAll(pRef.Hotel.MigrationOfficeNumber);
			pPage4.Parameters.mMigrationOfficeNumber = TrimAll(pRef.Hotel.MigrationOfficeNumber);
			
			pPage2.Parameters.mCheckInDate = pRef.CheckInDate;
			pPage4.Parameters.mCheckInDate = pRef.CheckInDate;
		EndIf;
	EndIf;
EndProcedure // SetParametersNotificationForPages20230101

// -----------------------------------------------------------------------------
Procedure SetParametersNotificationForPages20210223(pPage1, pPage2, pPage3, pPage4, pRef, pEmployee) Export
	Var vVisaSeries;
	Var vVisaNumber;
	Var vMigrationCardSeries;
	Var vMigrationCardNumber;
	
	// Check char
	vX = "Х";
	
	// Try to fill guest data	
	If ValueIsFilled(pRef.Guest) Then
		// Guest name
		If IsBlankString(pRef.LastName) Then
			vGuestLastName = StringToArray(pRef.Guest.LastName, 28);
			vGuestFirstName = StringToArray(pRef.Guest.FirstName, 28);
			vGuestSecondName = StringToArray(pRef.Guest.SecondName, 25);
		Else
			vGuestLastName = StringToArray(pRef.LastName, 28);
			vGuestFirstName = StringToArray(pRef.FirstName, 28);
			vGuestSecondName = StringToArray(pRef.SecondName, 25);
		EndIf;
		
		SetAttributeParameters(pPage1, "mGuestLastName", vGuestLastName, 28);
		SetAttributeParameters(pPage1, "mGuestFirstName", vGuestFirstName, 28);
		SetAttributeParameters(pPage1, "mGuestSecondName", vGuestSecondName, 25);
		
		SetAttributeParameters(pPage3, "mGuestLastName", vGuestLastName, 28);
		SetAttributeParameters(pPage3, "mGuestFirstName", vGuestFirstName, 28);
		SetAttributeParameters(pPage3, "mGuestSecondName", vGuestSecondName, 23);
		
		// Guest citizenship
		vGuestCitizenship = StringToArray(TrimAll(pRef.Citizenship), 26);
		SetAttributeParameters(pPage1, "mGuestCitizenship", vGuestCitizenship, 26);
		SetAttributeParameters(pPage3, "mGuestCitizenship", vGuestCitizenship, 26);
		
		// Guest date of birth
		vGuestDateOfBirth = StringToArray(DateToString(pRef.DateOfBirth), 8);
		SetAttributeParameters(pPage1, "mGuestBirthDate", vGuestDateOfBirth, 8);
		SetAttributeParameters(pPage3, "mGuestBirthDate", vGuestDateOfBirth, 8);
		
		// Guest place of birth
		vGuestPlaceOfBirth = cmParseAddress(pRef.PlaceOfBirth);
		
		vGuestPlaceOfBirthCountry = StringToArray(vGuestPlaceOfBirth.Country, 25);
		SetAttributeParameters(pPage1, "mGuestBirthPlaceCountry", vGuestPlaceOfBirthCountry, 25);
		SetAttributeParameters(pPage3, "mGuestBirthPlaceCountry", vGuestPlaceOfBirthCountry, 25);
		
		vGuestPlaceOfBirthCity = StringToArray(vGuestPlaceOfBirth.City, 50);
		SetAttributeParameters(pPage1, "mGuestBirthPlaceCity", vGuestPlaceOfBirthCity, 50);
		SetAttributeParameters(pPage3, "mGuestBirthPlaceCity", vGuestPlaceOfBirthCity, 50);
		
		// Guest sex
		If pRef.Sex = Enums.Sex.Male Then
			pPage1.Parameters.mGuestSexMale = vX;
			pPage1.Parameters.mGuestSexFemale = "";
			pPage3.Parameters.mGuestSexMale = vX;
			pPage3.Parameters.mGuestSexFemale = "";
		ElsIf pRef.Sex = Enums.Sex.Female Then
			pPage1.Parameters.mGuestSexMale = "";
			pPage1.Parameters.mGuestSexFemale = vX;
			pPage3.Parameters.mGuestSexMale = "";
			pPage3.Parameters.mGuestSexFemale = vX;
		Else
			pPage1.Parameters.mGuestSexMale = "";
			pPage1.Parameters.mGuestSexFemale = "";
			pPage3.Parameters.mGuestSexMale = "";
			pPage3.Parameters.mGuestSexFemale = "";
		EndIf;
		
		// Guest phone
		If IsBlankString(pRef.Guest.Phone) Then
			SetAttributeParameters(pPage1, "mGuestPhone", StringToArray("", 10), 10);
		Else
			SetAttributeParameters(pPage1, "mGuestPhone", StringToArray(TrimAll(pRef.Guest.Phone), 10), 10);
		EndIf;
		
		// Guest identification document
		If Find(Upper(TrimAll(pRef.IdentityDocumentType)), "ПАСПОРТ") > 0 Then
			vGuestIDType = StringToArray("ПАСПОРТ", 11);
		Else
			vGuestIDType = StringToArray(pRef.IdentityDocumentType, 11);
		EndIf;
		SetAttributeParameters(pPage1, "mGuestIDType", vGuestIDType, 10);
		SetAttributeParameters(pPage3, "mGuestIDType", vGuestIDType, 11);
		
		vGuestIDSeries = StringToArray(TrimAll(StrReplace(pRef.IdentityDocumentSeries, " ", "")), 4);
		SetAttributeParameters(pPage1, "mGuestIDSeries", vGuestIDSeries, 4);
		SetAttributeParameters(pPage3, "mGuestIDSeries", vGuestIDSeries, 4);
		
		vGuestIDNumber = StringToArray(TrimAll(pRef.IdentityDocumentNumber), 11);
		SetAttributeParameters(pPage1, "mGuestIDNumber", vGuestIDNumber, 11);
		SetAttributeParameters(pPage3, "mGuestIDNumber", vGuestIDNumber, 11);
		
		vGuestIDIssuedDate = StringToArray(DateToString(pRef.IdentityDocumentIssueDate), 8);
		SetAttributeParameters(pPage1, "mGuestIDIssuedDate", vGuestIDIssuedDate, 8);
		SetAttributeParameters(pPage3, "mGuestIDIssuedDate", vGuestIDIssuedDate, 8);
		
		vGuestIDValidToDate = StringToArray(DateToString(pRef.IdentityDocumentValidToDate), 8);
		SetAttributeParameters(pPage1, "mGuestIDValidToDate", vGuestIDValidToDate, 8);
		SetAttributeParameters(pPage3, "mGuestIDValidToDate", vGuestIDValidToDate, 8);
	Else // Guest is not selected, so fill all guest data with blanks
		// Guest name
		SetAttributeParameters(pPage1, "mGuestLastName", StringToArray("", 28), 28);
		SetAttributeParameters(pPage1, "mGuestFirstName", StringToArray("", 28), 28);
		SetAttributeParameters(pPage1, "mGuestSecondName", StringToArray("", 25), 25);
		
		SetAttributeParameters(pPage3, "mGuestLastName", StringToArray("", 28), 28);
		SetAttributeParameters(pPage3, "mGuestFirstName", StringToArray("", 28), 28);
		SetAttributeParameters(pPage3, "mGuestSecondName", StringToArray("", 23), 23);
		
		// Guest citizenship
		SetAttributeParameters(pPage1, "mGuestCitizenship", StringToArray("", 26), 26);
		SetAttributeParameters(pPage3, "mGuestCitizenship", StringToArray("", 27), 27);
		
		// Guest date of birth
		SetAttributeParameters(pPage1, "mGuestBirthDate", StringToArray("", 8), 8);
		SetAttributeParameters(pPage3, "mGuestBirthDate", StringToArray("", 8), 8);
		
		// Guest place of birth
		SetAttributeParameters(pPage1, "mGuestBirthPlaceCountry", StringToArray("", 25), 25);
		SetAttributeParameters(pPage1, "mGuestBirthPlaceCity", StringToArray("", 50), 50);
		SetAttributeParameters(pPage3, "mGuestBirthPlaceCountry", StringToArray("", 25), 25);
		SetAttributeParameters(pPage3, "mGuestBirthPlaceCity", StringToArray("", 50), 50);
		
		// Guest sex
		pPage1.Parameters.mGuestSexMale = "";
		pPage1.Parameters.mGuestSexFemale = "";
		pPage3.Parameters.mGuestSexMale = "";
		pPage3.Parameters.mGuestSexFemale = "";
		
		// Guest phone
		SetAttributeParameters(pPage1, "mGuestPhone", StringToArray("", 10), 10);
		
		// Guest identification document
		SetAttributeParameters(pPage1, "mGuestIDType", StringToArray("", 11), 11);
		SetAttributeParameters(pPage3, "mGuestIDType", StringToArray("", 11), 11);
		SetAttributeParameters(pPage1, "mGuestIDSeries", StringToArray("", 4), 4);
		SetAttributeParameters(pPage3, "mGuestIDSeries", StringToArray("", 4), 4);
		SetAttributeParameters(pPage1, "mGuestIDNumber", StringToArray("", 11), 11);
		SetAttributeParameters(pPage3, "mGuestIDNumber", StringToArray("", 11), 11);
		SetAttributeParameters(pPage1, "mGuestIDIssuedDate", StringToArray("", 8), 8);
		SetAttributeParameters(pPage3, "mGuestIDIssuedDate", StringToArray("", 8), 8);
		SetAttributeParameters(pPage1, "mGuestIDValidToDate", StringToArray("", 8), 8);
		SetAttributeParameters(pPage3, "mGuestIDValidToDate", StringToArray("", 8), 8);
	EndIf;
	
	// Guest profession and standing
	vGuestProfession = StringToArray(TrimAll(pRef.Profession), 26);
	SetAttributeParameters(pPage1, "mGuestProfession", vGuestProfession, 26);
	
	// Legal representatives
	If Not IsBlankString(pRef.LegalRepresentativeLastName) Then
		vLegalRepresentativeName = TrimAll(TrimAll(pRef.LegalRepresentativeLastName) + " " + TrimAll(pRef.LegalRepresentativeFirstName) + " " + TrimAll(pRef.LegalRepresentativeSecondName));
		vLegalRepresentative = pRef.LegalRepresentative;
		If ValueIsFilled(vLegalRepresentative) Then
			vLegalRepresentatives = StringToArray(vLegalRepresentativeName + 
			                        ?(ValueIsFilled(vLegalRepresentative.DateOfBirth), ", " + Format(vLegalRepresentative.DateOfBirth, "DF=dd.MM.yyyy"), "") +
			                        ?(ValueIsFilled(vLegalRepresentative.Sex), ", " + TrimAll(vLegalRepresentative.Sex), "") + 
									?(Not IsBlankString(vLegalRepresentative.IdentityDocumentNumber), ", №" + TrimAll(TrimAll(vLegalRepresentative.IdentityDocumentSeries) + " " + TrimAll(vLegalRepresentative.IdentityDocumentNumber)), ""), 78);
		Else
			vLegalRepresentatives = StringToArray(vLegalRepresentativeName, 78);
		EndIf;
	ElsIf ValueIsFilled(pRef.LegalRepresentative) Then
		vLegalRepresentative = pRef.LegalRepresentative;
		vLegalRepresentatives = StringToArray(TrimAll(TrimAll(vLegalRepresentative.LastName) + " " + TrimAll(vLegalRepresentative.FirstName) + " " + TrimAll(vLegalRepresentative.SecondName)) + 
		                        ?(ValueIsFilled(vLegalRepresentative.DateOfBirth), ", " + Format(vLegalRepresentative.DateOfBirth, "DF=dd.MM.yyyy"), "") +
		                        ?(ValueIsFilled(vLegalRepresentative.Sex), ", " + TrimAll(vLegalRepresentative.Sex), "") + 
								?(Not IsBlankString(vLegalRepresentative.IdentityDocumentNumber), ", №" + TrimAll(TrimAll(vLegalRepresentative.IdentityDocumentSeries) + " " + TrimAll(vLegalRepresentative.IdentityDocumentNumber)), ""), 78);
	ElsIf Not IsBlankString(pRef.LegalRepresentatives) Then
		vLegalRepresentatives = StringToArray(TrimAll(pRef.LegalRepresentatives), 78);
	Else
		vLegalRepresentatives = StringToArray("", 78);
	EndIf;
	SetAttributeParameters(pPage1, "mLegalRepresentatives", vLegalRepresentatives, 78);
	
	// Previous place of stay
	vPreviousPlaceOfStay = StringToArray(TrimAll(pRef.PreviousPlaceOfStay), 106);
	SetAttributeParameters(pPage2, "mPreviousStayAddress", vPreviousPlaceOfStay, 106);
	
	// Visa
	If Not IsBlankString(pRef.VisaNumber) Then
		pPage1.Parameters.mVisa = vX;
		
		SeriesAndNumberToArray(pRef.VisaNumber, 4, 15, vVisaSeries, vVisaNumber);
		SetAttributeParameters(pPage1, "mVisaSeries", vVisaSeries, 4);
		SetAttributeParameters(pPage1, "mVisaNumber", vVisaNumber, 15);
		
		vVisaIssuedDate = StringToArray(DateToString(pRef.VisaIssuedDate), 8);
		SetAttributeParameters(pPage1, "mVisaIssuedDate", vVisaIssuedDate, 8);
		
		vVisaValidToDate = StringToArray(DateToString(pRef.VisaToDate), 8);
		SetAttributeParameters(pPage1, "mVisaValidToDate", vVisaValidToDate, 8);
	Else
		pPage1.Parameters.mVisa = "";
		
		SetAttributeParameters(pPage1, "mVisaSeries", StringToArray("", 4), 4);
		SetAttributeParameters(pPage1, "mVisaNumber", StringToArray("", 15), 15);
		
		SetAttributeParameters(pPage1, "mVisaIssuedDate", StringToArray("", 8), 8);
		
		SetAttributeParameters(pPage1, "mVisaValidToDate", StringToArray("", 8), 8);
	EndIf;
	
	pPage1.Parameters.mResidencePermit = "";
	pPage1.Parameters.mTimeResolution = "";
	If ValueIsFilled(pRef.ResidencePermitDocument) And pRef.ResidencePermitDocument = Enums.ConfirmingDocuments.PermResidencePermit Or 
	   ValueIsFilled(pRef.VisaType) And TrimAll(pRef.VisaType.Code) = "ВЖ" Then
		pPage1.Parameters.mVisa = "";
		pPage1.Parameters.mResidencePermit = vX;
		
		SeriesAndNumberToArray(pRef.VisaNumber, 4, 15, vVisaSeries, vVisaNumber);
		SetAttributeParameters(pPage1, "mVisaSeries", vVisaSeries, 4);
		SetAttributeParameters(pPage1, "mVisaNumber", vVisaNumber, 15);
		
		vVisaFromDate = StringToArray(DateToString(pRef.VisaFromDate), 8);
		SetAttributeParameters(pPage1, "mVisaIssuedDate", vVisaFromDate, 8);
		
		vVisaValidToDate = StringToArray(DateToString(pRef.VisaToDate), 8);
		SetAttributeParameters(pPage1, "mVisaValidToDate", vVisaValidToDate, 8);
	ElsIf ValueIsFilled(pRef.ResidencePermitDocument) And pRef.ResidencePermitDocument = Enums.ConfirmingDocuments.TempResidencePermit Or 
	      ValueIsFilled(pRef.VisaType) And TrimAll(pRef.VisaType.Code) = "ВР" Then
		pPage1.Parameters.mVisa = "";
		pPage1.Parameters.mTimeResolution = vX;
		
		SeriesAndNumberToArray(pRef.VisaIdentifier, 4, 15, vVisaSeries, vVisaNumber);
		SetAttributeParameters(pPage1, "mVisaSeries", vVisaSeries, 4);
		SetAttributeParameters(pPage1, "mVisaNumber", vVisaNumber, 15);
		
		vVisaIssuedDate = StringToArray(DateToString(pRef.VisaIssuedDate), 8);
		SetAttributeParameters(pPage1, "mVisaIssuedDate", vVisaIssuedDate, 8);
		
		vVisaValidToDate = StringToArray(DateToString(pRef.VisaToDate), 8);
		SetAttributeParameters(pPage1, "mVisaValidToDate", vVisaValidToDate, 8);
	ElsIf ValueIsFilled(pRef.IdentityDocumentType) And TrimAll(pRef.IdentityDocumentType.Code) = "12" Or
	      ValueIsFilled(pRef.IdentityDocumentType) And TrimAll(pRef.IdentityDocumentType.Code) = "19" Or
	      ValueIsFilled(pRef.IdentityDocumentType) And TrimAll(pRef.IdentityDocumentType.Code) = "20" Then
		pPage1.Parameters.mVisa = "";
		pPage1.Parameters.mResidencePermit = vX;
		
		SeriesAndNumberToArray(pRef.VisaNumber, 4, 15, vVisaSeries, vVisaNumber);
		SetAttributeParameters(pPage1, "mVisaSeries", vVisaSeries, 4);
		SetAttributeParameters(pPage1, "mVisaNumber", vVisaNumber, 15);
		
		vVisaFromDate = StringToArray(DateToString(pRef.VisaFromDate), 8);
		SetAttributeParameters(pPage1, "mVisaIssuedDate", vVisaFromDate, 8);
		
		vVisaValidToDate = StringToArray(DateToString(pRef.VisaToDate), 8);
		SetAttributeParameters(pPage1, "mVisaValidToDate", vVisaValidToDate, 8);
	ElsIf ValueIsFilled(pRef.IdentityDocumentType) And TrimAll(pRef.IdentityDocumentType.Code) = "101" Or
	      ValueIsFilled(pRef.IdentityDocumentType) And TrimAll(pRef.IdentityDocumentType.Code) = "101a" Then
		pPage1.Parameters.mVisa = "";
		pPage1.Parameters.mTimeResolution = vX;
		
		SeriesAndNumberToArray(pRef.VisaIdentifier, 4, 15, vVisaSeries, vVisaNumber);
		SetAttributeParameters(pPage1, "mVisaSeries", vVisaSeries, 4);
		SetAttributeParameters(pPage1, "mVisaNumber", vVisaNumber, 15);
		
		vVisaIssuedDate = StringToArray(DateToString(pRef.VisaIssuedDate), 8);
		SetAttributeParameters(pPage1, "mVisaIssuedDate", vVisaIssuedDate, 8);
		
		vVisaValidToDate = StringToArray(DateToString(pRef.VisaToDate), 8);
		SetAttributeParameters(pPage1, "mVisaValidToDate", vVisaValidToDate, 8);
	EndIf;

	// Migration card
	If Not IsBlankString(pRef.MigrationCardNumber) Then
		vSeriesLength = 4;
		vBlankPos = Find(TrimAll(pRef.MigrationCardNumber), " ");
		If vBlankPos > 4 Then
			vSeriesLength = vBlankPos - 1;
		EndIf;
		If StrLen(TrimAll(pRef.MigrationCardNumber)) >= 14 Then
			SeriesAndNumberToArray(pRef.MigrationCardNumber, vSeriesLength, 11, vMigrationCardSeries, vMigrationCardNumber);
		Else
			vMigrationCardSeries = StringToArray(Left(TrimAll(pRef.MigrationCardNumber), vSeriesLength), vSeriesLength);
			vMigrationCardNumber = StringToArray(Right(TrimAll(pRef.MigrationCardNumber), StrLen(TrimAll(pRef.MigrationCardNumber)) - vSeriesLength), 11);
		EndIf;
		SetAttributeParameters(pPage1, "mMigrationCardSeries", vMigrationCardSeries, 4);
		SetAttributeParameters(pPage1, "mMigrationCardNumber", vMigrationCardNumber, 11);
	EndIf;

	vBorderCrossingDate = StringToArray(DateToString(pRef.BorderCrossingDate), 8);
	SetAttributeParameters(pPage1, "mBorderCrossingDate", vBorderCrossingDate, 8);
	
	// Guest trip purpose
	pPage1.Parameters.mTripPurposeOfficial = "";
	pPage1.Parameters.mTripPurposeTourism = "";
	pPage1.Parameters.mTripPurposeBusiness = "";
	pPage1.Parameters.mTripPurposeStudying = "";
	pPage1.Parameters.mTripPurposeWork = "";
	pPage1.Parameters.mTripPurposePrivate = "";
	pPage1.Parameters.mTripPurposeTransit = "";
	pPage1.Parameters.mTripPurposeHumanitarian = "";
	pPage1.Parameters.mTripPurposeOther = "";
	
	If pRef.TripPurpose = Catalogs.TripPurposes.Official Or 
	   pRef.TripPurpose = Catalogs.TripPurposes.Commerce Then
		pPage1.Parameters.mTripPurposeOfficial = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Tourism Then
		pPage1.Parameters.mTripPurposeTourism = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Business Then
		pPage1.Parameters.mTripPurposeBusiness = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Study Or
	      pRef.TripPurpose = Catalogs.TripPurposes.Scientific Then
		pPage1.Parameters.mTripPurposeStudying = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Work Then
		pPage1.Parameters.mTripPurposeWork = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Private Then
		pPage1.Parameters.mTripPurposePrivate = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Transit Or 
		  pRef.TripPurpose = Catalogs.TripPurposes.Crewman Then
		pPage1.Parameters.mTripPurposeTransit = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Humanitarian Then
		pPage1.Parameters.mTripPurposeHumanitarian = vX;
	Else
		pPage1.Parameters.mTripPurposeOther = vX;
	EndIf;
	
	// Company name and TIN
	vCompany = Undefined;
	If ValueIsFilled(pRef.Hotel) And ValueIsFilled(pRef.Hotel.CompanyRegisteredInUFMS) Then
		vCompany = pRef.Hotel.CompanyRegisteredInUFMS;
	Else 
		If ValueIsFilled(pRef.ParentDoc) And ValueIsFilled(pRef.ParentDoc.Company) Then
			vCompany = pRef.ParentDoc.Company;
		Else
			vCompany = pRef.Hotel.Company;
		EndIf;
	EndIf;
	vCompanyAddressStr = "";
	If ValueIsFilled(vCompany) Then
		vCompanyAddressStr = TrimAll(vCompany.PostAddress);
		
		vCompanyName = StringToArray(StrReplace(TrimAll(vCompany.LegacyName),"""",""), 43);
		SetAttributeParameters(pPage4, "mCompanyName", vCompanyName, 43);
		
		vCompanyTIN = StringToArray(vCompany.TIN, 12);
		SetAttributeParameters(pPage4, "mCompanyTIN", vCompanyTIN, 12);
		
		SetAttributeParameters(pPage2, "mCompanyDocumentGivingRightToProvidePremises1Row", StringToArray("", 22), 22);
		SetAttributeParameters(pPage2, "mCompanyDocumentGivingRightToProvidePremises2Row", StringToArray("", 22), 22);
		SetAttributeParameters(pPage2, "mCompanyDocumentGivingRightToProvidePremises3Row", StringToArray("", 22), 22);
	
		vCompanyDocumentGivingRightToProvidePremisesArray = cmGetTextLinesArray(TrimAll(vCompany.DocumentGivingRightToProvidePremises));
		i = 0;
		While i < vCompanyDocumentGivingRightToProvidePremisesArray.Count() Do
			If i = 0 Then
				vCharsArray = StringToArray(vCompanyDocumentGivingRightToProvidePremisesArray.Get(i), 22);
				SetAttributeParameters(pPage2, "mCompanyDocumentGivingRightToProvidePremises1Row", vCharsArray, 22);
			ElsIf i = 1 Then
				vCharsArray = StringToArray(vCompanyDocumentGivingRightToProvidePremisesArray.Get(i), 22);
				SetAttributeParameters(pPage2, "mCompanyDocumentGivingRightToProvidePremises2Row", vCharsArray, 22);
			ElsIf i = 2 Then
				vCharsArray = StringToArray(vCompanyDocumentGivingRightToProvidePremisesArray.Get(i), 22);
				SetAttributeParameters(pPage2, "mCompanyDocumentGivingRightToProvidePremises3Row", vCharsArray, 22);
			Else
				Break;
			EndIf;
			i = i + 1;
		EndDo;
	Else
		SetAttributeParameters(pPage4, "mCompanyName", StringToArray("", 43), 43);
		
		SetAttributeParameters(pPage4, "mCompanyTIN", StringToArray("", 12), 12);
		
		SetAttributeParameters(pPage2, "mCompanyDocumentGivingRightToProvidePremises1Row", StringToArray("", 22), 22);
		SetAttributeParameters(pPage2, "mCompanyDocumentGivingRightToProvidePremises2Row", StringToArray("", 22), 22);
		SetAttributeParameters(pPage2, "mCompanyDocumentGivingRightToProvidePremises3Row", StringToArray("", 22), 22);
	EndIf;
		
	// Hotel address
	vHotelAddressStr = "";
	If ValueIsFilled(pRef.Hotel) Then
		vHotelAddressStr = pRef.Hotel.PostAddress;
		vAddress = cmParseAddress(vHotelAddressStr);
		
		vAddressRegion = StringToArray(vAddress.Region, 52);
		SetAttributeParameters(pPage2, "mAddressRegion", vAddressRegion, 52);
		SetAttributeParameters(pPage3, "mAddressRegion", vAddressRegion, 50);
		
		vAddressArea = StringToArray(vAddress.Area, 35);
		SetAttributeParameters(pPage2, "mAddressArea", vAddressArea, 26);
		SetAttributeParameters(pPage3, "mAddressArea", vAddressArea, 26);
		
		vAddressCity = StringToArray(vAddress.City, 25);
		SetAttributeParameters(pPage2, "mAddressCity", vAddressCity, 25);
		SetAttributeParameters(pPage3, "mAddressCity", vAddressCity, 25);
		
		vAddressStreet = StringToArray(vAddress.Street, 26);
		SetAttributeParameters(pPage2, "mAddressStreet", vAddressStreet, 26);
		SetAttributeParameters(pPage3, "mAddressStreet", vAddressStreet, 26);
		
		vHouse = TrimAll(vAddress.House);
		vBuilding = "";
		vHouseBuilding = "";
		ParseHouseNumber(vHouse, vBuilding, vHouseBuilding);
		
		vAddressHouse = StringToArray(TrimAll(vHouse), 8);
		SetAttributeParameters(pPage2, "mAddressHouse", vAddressHouse, 8);
		SetAttributeParameters(pPage3, "mAddressHouse", vAddressHouse, 8);
		
		If Not IsBlankString(vBuilding) Then
			vAddressBuilding = StringToArray(vBuilding, 5);
		Else
			vAddressBuilding = StringToArray("", 5);
		EndIf;
		SetAttributeParameters(pPage2, "mAddressBuilding", vAddressBuilding, 5);
		SetAttributeParameters(pPage3, "mAddressBuilding", vAddressBuilding, 5);
		
		If Not IsBlankString(vHouseBuilding) Then
			vAddressHouseBuilding = StringToArray(vHouseBuilding, 4);
		Else
			vAddressHouseBuilding = StringToArray("", 4);
		EndIf;
		SetAttributeParameters(pPage2, "mAddressHouseBuilding", vAddressHouseBuilding, 4);
		SetAttributeParameters(pPage3, "mAddressHouseBuilding", vAddressHouseBuilding, 4);
		
		vFlat = vAddress.Flat;
		If IsBlankString(vFlat) And ValueIsFilled(pRef.Room) Then
			vFlat = TrimAll(pRef.Room);
		EndIf;
		vFlat = StrReplace(vFlat, "/", "");
		vAddressFlat = StringToArray(vFlat, 5);
		SetAttributeParameters(pPage2, "mAddressFlat", vAddressFlat, 5);
		SetAttributeParameters(pPage3, "mAddressFlat", vAddressFlat, 5);
	Else
		SetAttributeParameters(pPage2, "mAddressRegion", StringToArray("", 30), 30);
		SetAttributeParameters(pPage3, "mAddressRegion", StringToArray("", 30), 30);
		
		SetAttributeParameters(pPage2, "mAddressArea", StringToArray("", 35), 35);
		SetAttributeParameters(pPage3, "mAddressArea", StringToArray("", 35), 35);
		
		SetAttributeParameters(pPage2, "mAddressCity", StringToArray("", 33), 33);
		SetAttributeParameters(pPage3, "mAddressCity", StringToArray("", 33), 33);
		
		SetAttributeParameters(pPage2, "mAddressStreet", StringToArray("", 35), 35);
		SetAttributeParameters(pPage3, "mAddressStreet", StringToArray("", 35), 35);
		
		SetAttributeParameters(pPage2, "mAddressHouse", StringToArray("", 8), 8);
		SetAttributeParameters(pPage3, "mAddressHouse", StringToArray("", 8), 8);
		
		SetAttributeParameters(pPage2, "mAddressBuilding", StringToArray("", 5), 5);
		SetAttributeParameters(pPage3, "mAddressBuilding", StringToArray("", 5), 5);
		
		SetAttributeParameters(pPage2, "mAddressHouseBuilding", StringToArray("", 4), 4);
		SetAttributeParameters(pPage3, "mAddressHouseBuilding", StringToArray("", 4), 4);
		
		SetAttributeParameters(pPage2, "mAddressFlat", StringToArray("", 5), 5);
		SetAttributeParameters(pPage3, "mAddressFlat", StringToArray("", 5), 5);
	EndIf;

	// Hotel phone
	vHotelPhoneStr = "";
	If ValueIsFilled(pRef.Hotel) Then
		vHotelPhoneStr = RemoveDelimeters(TrimAll(pRef.Hotel.Phones));
		vHotelPhone = StringToArray(vHotelPhoneStr, 11);
		SetAttributeParameters(pPage4, "mHotelPhone", vHotelPhone, 11);
	Else
		SetAttributeParameters(pPage4, "mHotelPhone", StringToArray("", 11), 11);
	EndIf;
	
	// Check out date
	If ValueIsFilled(pRef.CheckOutDate) Then
		If ValueIsFilled(pRef.MigrationCardDateTo) Then
			vCheckOutDate = StringToArray(DateToString(pRef.MigrationCardDateTo), 8);
		Else
			vCheckOutDate = StringToArray(DateToString(pRef.CheckOutDate), 8);
		EndIf;
		SetAttributeParameters(pPage1, "mCheckOutDate", vCheckOutDate, 8);
		SetAttributeParameters(pPage3, "mCheckOutDate", vCheckOutDate, 8);
	Else
		SetAttributeParameters(pPage1, "mCheckOutDate", StringToArray("", 8), 8);
		SetAttributeParameters(pPage3, "mCheckOutDate", StringToArray("", 8), 8);
	EndIf;

	// Employee that signes notification
	If ValueIsFilled(pEmployee) Then
		// Employee name
		vEmployeeLastName = StringToArray(pEmployee.LastName, 28);
		vEmployeeFirstName = StringToArray(pEmployee.FirstName, 28);
		vEmployeeSecondName = StringToArray(pEmployee.SecondName, 25);
		
		SetAttributeParameters(pPage3, "mEmployeeLastName", vEmployeeLastName, 28);
		SetAttributeParameters(pPage3, "mEmployeeFirstName", vEmployeeFirstName, 28);
		SetAttributeParameters(pPage3, "mEmployeeSecondName", vEmployeeSecondName, 23);
		SetAttributeParameters(pPage4, "mEmployeeLastName", vEmployeeLastName, 28);
		SetAttributeParameters(pPage4, "mEmployeeFirstName", vEmployeeFirstName, 28);
		SetAttributeParameters(pPage4, "mEmployeeSecondName", vEmployeeSecondName, 25);
		
		// Employee living address
		If Not IsBlankString(pEmployee.Address) Then
			vEmployeeAddress = cmParseAddress(pEmployee.Address);
		Else
			vEmployeeAddress = cmParseAddress(vHotelAddressStr);
		EndIf;
		
		vEmployeeAddressRegion = StringToArray(vEmployeeAddress.Region, 50);
		SetAttributeParameters(pPage3, "mEmployeeAddressRegion", vEmployeeAddressRegion, 50);
		
		vEmployeeAddressArea = StringToArray(vEmployeeAddress.Area, 26);
		SetAttributeParameters(pPage3, "mEmployeeAddressArea", vEmployeeAddressArea, 26);
		
		vEmployeeAddressCity = StringToArray(vEmployeeAddress.City, 24);
		SetAttributeParameters(pPage3, "mEmployeeAddressCity", vEmployeeAddressCity, 24);
		
		vEmployeeAddressStreet = StringToArray(vEmployeeAddress.Street, 26);
		SetAttributeParameters(pPage3, "mEmployeeAddressStreet", vEmployeeAddressStreet, 26);
		
		vHouse = TrimAll(vEmployeeAddress.House);
		vBuilding = "";
		vHouseBuilding = "";
		ParseHouseNumber(vHouse, vBuilding, vHouseBuilding);
		
		vEmployeeAddressHouse = StringToArray(vHouse, 4);
		SetAttributeParameters(pPage3, "mEmployeeAddressHouse", vEmployeeAddressHouse, 4);
		
		If Not IsBlankString(vBuilding) Then
			vEmployeeAddressBuilding = StringToArray(vBuilding, 5);
		Else
			vEmployeeAddressBuilding = StringToArray("", 5);
		EndIf;
		SetAttributeParameters(pPage3, "mEmployeeAddressBuilding", vEmployeeAddressBuilding, 5);
		
		If Not IsBlankString(vHouseBuilding) Then
			vEmployeeAddressHouseBuilding = StringToArray(vHouseBuilding, 4);
		Else
			vEmployeeAddressHouseBuilding = StringToArray("", 4);
		EndIf;
		SetAttributeParameters(pPage3, "mEmployeeAddressHouseBuilding", vEmployeeAddressHouseBuilding, 4);
		
		vEmployeeAddressFlat = StringToArray(vEmployeeAddress.Flat, 4);
		SetAttributeParameters(pPage3, "mEmployeeAddressFlat", vEmployeeAddressFlat, 4);
		
		// Employee identification document
		If Find(Upper(TrimAll(pEmployee.IdentityDocumentType)), "ПАСПОРТ") > 0 Then
			vEmployeeIDType = StringToArray("ПАСПОРТ", 11);
		Else
			vEmployeeIDType = StringToArray(pEmployee.IdentityDocumentType, 11);
		EndIf;
		SetAttributeParameters(pPage3, "mEmployeeIDType", vEmployeeIDType, 11);
		
		vEmployeeIDSeries = StringToArray(TrimAll(StrReplace(pEmployee.IdentityDocumentSeries, " ", "")), 4);
		SetAttributeParameters(pPage3, "mEmployeeIDSeries", vEmployeeIDSeries, 4);
		
		vEmployeeIDNumber = StringToArray(TrimAll(pEmployee.IdentityDocumentNumber), 11);
		SetAttributeParameters(pPage3, "mEmployeeIDNumber", vEmployeeIDNumber, 11);
		
		vEmployeeIDIssuedDate = StringToArray(DateToString(pEmployee.IdentityDocumentIssueDate), 8);
		SetAttributeParameters(pPage3, "mEmployeeIDIssuedDate", vEmployeeIDIssuedDate, 8);
		
		vEmployeeIDValidToDate = StringToArray(DateToString(pEmployee.IdentityDocumentValidToDate), 8);
		SetAttributeParameters(pPage3, "mEmployeeIDValidToDate", vEmployeeIDValidToDate, 8);
	Else // Employee is not selected, so fill all employee data with blanks except address and phone
		// Employee name
		SetAttributeParameters(pPage3, "mEmployeeLastName", StringToArray("", 28), 28);
		SetAttributeParameters(pPage3, "mEmployeeFirstName", StringToArray("", 28), 28);
		SetAttributeParameters(pPage3, "mEmployeeSecondName", StringToArray("", 23), 23);
		SetAttributeParameters(pPage4, "mEmployeeLastName", StringToArray("", 28), 28);
		SetAttributeParameters(pPage4, "mEmployeeFirstName", StringToArray("", 28), 28);
		SetAttributeParameters(pPage4, "mEmployeeSecondName", StringToArray("", 25), 25);
		
		// Employee living address
		vEmployeeAddress = cmParseAddress(vHotelAddressStr);
		
		vEmployeeAddressRegion = StringToArray(vEmployeeAddress.Region, 50);
		SetAttributeParameters(pPage3, "mEmployeeAddressRegion", vEmployeeAddressRegion, 50);
		
		vEmployeeAddressArea = StringToArray(vEmployeeAddress.Area, 26);
		SetAttributeParameters(pPage3, "mEmployeeAddressArea", vEmployeeAddressArea, 26);
		
		vEmployeeAddressCity = StringToArray(vEmployeeAddress.City, 24);
		SetAttributeParameters(pPage3, "mEmployeeAddressCity", vEmployeeAddressCity, 24);
		
		vEmployeeAddressStreet = StringToArray(vEmployeeAddress.Street, 26);
		SetAttributeParameters(pPage3, "mEmployeeAddressStreet", vEmployeeAddressStreet, 26);
		
		vHouse = TrimAll(vEmployeeAddress.House);
		vBuilding = "";
		vHouseBuilding = "";
		ParseHouseNumber(vHouse, vBuilding, vHouseBuilding);
		
		vEmployeeAddressHouse = StringToArray(vHouse, 4);
		SetAttributeParameters(pPage3, "mEmployeeAddressHouse", vEmployeeAddressHouse, 4);
		
		If Not IsBlankString(vBuilding) Then
			vEmployeeAddressBuilding = StringToArray(vBuilding, 5);
		Else
			vEmployeeAddressBuilding = StringToArray("", 5);
		EndIf;
		SetAttributeParameters(pPage3, "mEmployeeAddressBuilding", vEmployeeAddressBuilding, 5);
		
		If Not IsBlankString(vHouseBuilding) Then
			vEmployeeAddressHouseBuilding = StringToArray(vHouseBuilding, 4);
		Else
			vEmployeeAddressHouseBuilding = StringToArray("", 4);
		EndIf;
		SetAttributeParameters(pPage3, "mEmployeeAddressHouseBuilding", vEmployeeAddressHouseBuilding, 4);
		
		vEmployeeAddressFlat = StringToArray(vEmployeeAddress.Flat, 4);
		SetAttributeParameters(pPage3, "mEmployeeAddressFlat", vEmployeeAddressFlat, 4);
		
		// Employee identification document
		SetAttributeParameters(pPage3, "mEmployeeIDType", StringToArray("", 11), 11);
		
		SetAttributeParameters(pPage3, "mEmployeeIDSeries", StringToArray("", 4), 4);
		
		SetAttributeParameters(pPage3, "mEmployeeIDNumber", StringToArray("", 11), 11);
		
		SetAttributeParameters(pPage3, "mEmployeeIDIssuedDate", StringToArray("", 8), 8);
		
		SetAttributeParameters(pPage3, "mEmployeeIDValidToDate", StringToArray("", 8), 8);
	EndIf;
	
	// Hotel address
	vCompanyAddress = StringToArray(cmGetAddressPresentation(vCompanyAddressStr), 87);
	SetAttributeParameters(pPage4, "mHotelAddress", vCompanyAddress, 87);
	
	// Migration office number
	pPage2.Parameters.mMigrationOfficeNumber = "";
	pPage4.Parameters.mMigrationOfficeNumber = "";
	pPage2.Parameters.mCheckInDate = '00010101';
	pPage4.Parameters.mCheckInDate = '00010101';
	If ValueIsFilled(pRef.Hotel) Then
		If Not IsBlankString(pRef.Hotel.MigrationOfficeNumber) Then
			pPage2.Parameters.mMigrationOfficeNumber = TrimAll(pRef.Hotel.MigrationOfficeNumber);
			pPage4.Parameters.mMigrationOfficeNumber = TrimAll(pRef.Hotel.MigrationOfficeNumber);
			
			pPage2.Parameters.mCheckInDate = pRef.CheckInDate;
			pPage4.Parameters.mCheckInDate = pRef.CheckInDate;
		EndIf;
	EndIf;
EndProcedure // SetParametersNotificationForPages20210223

// -----------------------------------------------------------------------------
Procedure SetParametersNotificationForPages20200914(pPage1, pPage2, pRef, pEmployee) Export
	Var vVisaSeries;
	Var vVisaNumber;
	Var vMigrationCardSeries;
	Var vMigrationCardNumber;
	
	// Check char
	vX = "Х";
	
	// Try to fill guest data	
	If ValueIsFilled(pRef.Guest) Then
		// Guest name
		If IsBlankString(pRef.LastName) Then
			vGuestLastName = StringToArray(pRef.Guest.LastName, 35);
			SetAttributeParameters(pPage1, "mGuestLastName", vGuestLastName, 35);
			vGuestName = StringToArray(TrimAll(pRef.Guest.FirstName) + " " + 
			                           TrimAll(pRef.Guest.SecondName), 32);
			SetAttributeParameters(pPage1, "mGuestName", vGuestName, 32);
		Else
			vGuestLastName = StringToArray(pRef.LastName, 35);
			SetAttributeParameters(pPage1, "mGuestLastName", vGuestLastName, 35);
			vGuestName = StringToArray(TrimAll(pRef.FirstName) + " " + 
			                           TrimAll(pRef.SecondName), 32);
			SetAttributeParameters(pPage1, "mGuestName", vGuestName, 32);
		EndIf;
		
		// Guest citizenship
		vGuestCitizenship = StringToArray(TrimAll(pRef.Citizenship),34);
		SetAttributeParameters(pPage1, "mGuestCitizenship", vGuestCitizenship, 34);
		
		// Guest date of birth
		vGuestDateOfBirth = StringToArray(DateToString(pRef.DateOfBirth), 8);
		SetAttributeParameters(pPage1, "mGuestBirthDate", vGuestDateOfBirth, 8);
		
		// Guest place of birth
		vGuestPlaceOfBirth = cmParseAddress(pRef.PlaceOfBirth);
		
		vGuestPlaceOfBirthCountry = StringToArray(vGuestPlaceOfBirth.Country, 33);
		SetAttributeParameters(pPage1, "mGuestBirthPlaceCountry", vGuestPlaceOfBirthCountry, 33);
		
		vGuestPlaceOfBirthCity = StringToArray(vGuestPlaceOfBirth.City, 33);
		SetAttributeParameters(pPage1, "mGuestBirthPlaceCity", vGuestPlaceOfBirthCity, 33);
		
		// Guest sex
		If pRef.Sex = Enums.Sex.Male Then
			pPage1.Parameters.mGuestSexMale = vX;
			pPage1.Parameters.mGuestSexFemale = "";
		ElsIf pRef.Sex = Enums.Sex.Female Then
			pPage1.Parameters.mGuestSexMale = "";
			pPage1.Parameters.mGuestSexFemale = vX;
		Else
			pPage1.Parameters.mGuestSexMale = "";
			pPage1.Parameters.mGuestSexFemale = "";
		EndIf;
		
		// Guest phone
		If IsBlankString(pRef.Guest.Phone) Then
			SetAttributeParameters(pPage1, "mGuestPhone", StringToArray("", 10), 10);
		Else
			SetAttributeParameters(pPage1, "mGuestPhone", StringToArray(TrimAll(pRef.Guest.Phone), 10), 10);
		EndIf;
		
		// Guest identification document
		If Find(Upper(TrimAll(pRef.IdentityDocumentType)), "ПАСПОРТ") > 0 Then
			vGuestIDType = StringToArray("ПАСПОРТ", 11);
		Else
			vGuestIDType = StringToArray(pRef.IdentityDocumentType, 11);
		EndIf;
		SetAttributeParameters(pPage1, "mGuestIDType", vGuestIDType, 11);
		
		vGuestIDSeries = StringToArray(TrimAll(StrReplace(pRef.IdentityDocumentSeries, " ", "")), 4);
		SetAttributeParameters(pPage1, "mGuestIDSeries", vGuestIDSeries, 4);
		
		vGuestIDNumber = StringToArray(TrimAll(pRef.IdentityDocumentNumber), 10);
		SetAttributeParameters(pPage1, "mGuestIDNumber", vGuestIDNumber, 10);
		
		vGuestIDIssuedDate = StringToArray(DateToString(pRef.IdentityDocumentIssueDate), 8);
		SetAttributeParameters(pPage1, "mGuestIDIssuedDate", vGuestIDIssuedDate, 8);
		
		vGuestIDValidToDate = StringToArray(DateToString(pRef.IdentityDocumentValidToDate), 8);
		SetAttributeParameters(pPage1, "mGuestIDValidToDate", vGuestIDValidToDate, 8);
	Else // Guest is not selected, so fill all guest data with blanks
		// Guest name
		SetAttributeParameters(pPage1, "mGuestLastName", StringToArray("", 35), 35);
		SetAttributeParameters(pPage1, "mGuestName", StringToArray("", 32), 32);
		
		// Guest citizenship
		SetAttributeParameters(pPage1, "mGuestCitizenship", StringToArray("", 34), 34);
		
		// Guest date of birth
		SetAttributeParameters(pPage1, "mGuestBirthDate", StringToArray("", 8), 8);
		
		// Guest place of birth
		SetAttributeParameters(pPage1, "mGuestBirthPlaceCountry", StringToArray("", 33), 33);
		SetAttributeParameters(pPage1, "mGuestBirthPlaceCity", StringToArray("", 33), 33);
		
		// Guest sex
		pPage1.Parameters.mGuestSexMale = "";
		pPage1.Parameters.mGuestSexFemale = "";
		
		// Guest phone
		SetAttributeParameters(pPage1, "mGuestPhone", StringToArray("", 10), 10);
		
		// Guest identification document
		SetAttributeParameters(pPage1, "mGuestIDType", StringToArray("", 11), 11);
		SetAttributeParameters(pPage1, "mGuestIDSeries", StringToArray("", 4), 4);
		SetAttributeParameters(pPage1, "mGuestIDNumber", StringToArray("", 10), 10);
		SetAttributeParameters(pPage1, "mGuestIDIssuedDate", StringToArray("", 8), 8);
		SetAttributeParameters(pPage1, "mGuestIDValidToDate", StringToArray("", 8), 8);
	EndIf;
	
	// Guest profession and standing
	vGuestProfession = StringToArray(TrimAll(pRef.Profession), 23);
	SetAttributeParameters(pPage1, "mGuestProfession", vGuestProfession, 23);
	
	vGuestStanding = StringToArray(TrimAll(pRef.Standing), 2);
	// Standing was removed from this form
	
	// Legal representatives
	If Not IsBlankString(pRef.LegalRepresentativeLastName) Then
		vLegalRepresentativeName = TrimAll(TrimAll(pRef.LegalRepresentativeLastName) + " " + TrimAll(pRef.LegalRepresentativeFirstName) + " " + TrimAll(pRef.LegalRepresentativeSecondName));
		vLegalRepresentative = pRef.LegalRepresentative;
		If ValueIsFilled(vLegalRepresentative) Then
			vLegalRepresentatives = StringToArray(vLegalRepresentativeName + 
			                        ?(ValueIsFilled(vLegalRepresentative.DateOfBirth), ", " + Format(vLegalRepresentative.DateOfBirth, "DF=dd.MM.yyyy"), "") +
			                        ?(ValueIsFilled(vLegalRepresentative.Sex), ", " + TrimAll(vLegalRepresentative.Sex), "") + 
									?(Not IsBlankString(vLegalRepresentative.IdentityDocumentNumber), ", №" + TrimAll(TrimAll(vLegalRepresentative.IdentityDocumentSeries) + " " + TrimAll(vLegalRepresentative.IdentityDocumentNumber)), ""), 57);
		Else
			vLegalRepresentatives = StringToArray(vLegalRepresentativeName, 57);
		EndIf;
	ElsIf ValueIsFilled(pRef.LegalRepresentative) Then
		vLegalRepresentative = pRef.LegalRepresentative;
		vLegalRepresentatives = StringToArray(TrimAll(TrimAll(vLegalRepresentative.LastName) + " " + TrimAll(vLegalRepresentative.FirstName) + " " + TrimAll(vLegalRepresentative.SecondName)) + 
		                        ?(ValueIsFilled(vLegalRepresentative.DateOfBirth), ", " + Format(vLegalRepresentative.DateOfBirth, "DF=dd.MM.yyyy"), "") +
		                        ?(ValueIsFilled(vLegalRepresentative.Sex), ", " + TrimAll(vLegalRepresentative.Sex), "") + 
								?(Not IsBlankString(vLegalRepresentative.IdentityDocumentNumber), ", №" + TrimAll(TrimAll(vLegalRepresentative.IdentityDocumentSeries) + " " + TrimAll(vLegalRepresentative.IdentityDocumentNumber)), ""), 57);
	ElsIf Not IsBlankString(pRef.LegalRepresentatives) Then
		vLegalRepresentatives = StringToArray(TrimAll(pRef.LegalRepresentatives), 57);
	Else
		vLegalRepresentatives = StringToArray("", 57);
	EndIf;
	SetAttributeParameters(pPage1, "mLegalRepresentatives", vLegalRepresentatives, 57);
	
	// Previous place of stay
	vPreviousPlaceOfStay = StringToArray(TrimAll(pRef.PreviousPlaceOfStay), 76);
	SetAttributeParameters(pPage1, "mPreviousStayAddress", vPreviousPlaceOfStay, 76);
	
	// Visa
	If Not IsBlankString(pRef.VisaNumber) Then
		pPage1.Parameters.mVisa = vX;
		
		SeriesAndNumberToArray(pRef.VisaNumber, 4, 10, vVisaSeries, vVisaNumber);
		SetAttributeParameters(pPage1, "mVisaSeries", vVisaSeries, 4);
		SetAttributeParameters(pPage1, "mVisaNumber", vVisaNumber, 10);
		
		vVisaIssuedDate = StringToArray(DateToString(pRef.VisaIssuedDate), 8);
		SetAttributeParameters(pPage1, "mVisaIssuedDate", vVisaIssuedDate, 8);
		
		vVisaValidToDate = StringToArray(DateToString(pRef.VisaToDate), 8);
		SetAttributeParameters(pPage1, "mVisaValidToDate", vVisaValidToDate, 8);
	Else
		pPage1.Parameters.mVisa = "";
		
		SetAttributeParameters(pPage1, "mVisaSeries", StringToArray("", 4), 4);
		SetAttributeParameters(pPage1, "mVisaNumber", StringToArray("", 10), 10);
		
		SetAttributeParameters(pPage1, "mVisaIssuedDate", StringToArray("", 8), 8);
		
		SetAttributeParameters(pPage1, "mVisaValidToDate", StringToArray("", 8), 8);
	EndIf;
	
	pPage1.Parameters.mResidencePermit = "";
	pPage1.Parameters.mTimeResolution = "";
	If ValueIsFilled(pRef.ResidencePermitDocument) And pRef.ResidencePermitDocument = Enums.ConfirmingDocuments.PermResidencePermit Or 
	   ValueIsFilled(pRef.VisaType) And TrimAll(pRef.VisaType.Code) = "ВЖ" Then
		pPage1.Parameters.mVisa = "";
		pPage1.Parameters.mResidencePermit = vX;
		
		SeriesAndNumberToArray(pRef.VisaNumber, 4, 10, vVisaSeries, vVisaNumber);
		SetAttributeParameters(pPage1, "mVisaSeries", vVisaSeries, 4);
		SetAttributeParameters(pPage1, "mVisaNumber", vVisaNumber, 10);
		
		vVisaFromDate = StringToArray(DateToString(pRef.VisaFromDate), 8);
		SetAttributeParameters(pPage1, "mVisaIssuedDate", vVisaFromDate, 8);
		
		vVisaValidToDate = StringToArray(DateToString(pRef.VisaToDate), 8);
		SetAttributeParameters(pPage1, "mVisaValidToDate", vVisaValidToDate, 8);
	ElsIf ValueIsFilled(pRef.ResidencePermitDocument) And pRef.ResidencePermitDocument = Enums.ConfirmingDocuments.TempResidencePermit Or 
	      ValueIsFilled(pRef.VisaType) And TrimAll(pRef.VisaType.Code) = "ВР" Then
		pPage1.Parameters.mVisa = "";
		pPage1.Parameters.mTimeResolution = vX;
		
		SeriesAndNumberToArray(pRef.VisaIdentifier, 4, 10, vVisaSeries, vVisaNumber);
		SetAttributeParameters(pPage1, "mVisaSeries", vVisaSeries, 4);
		SetAttributeParameters(pPage1, "mVisaNumber", vVisaNumber, 10);
		
		vVisaIssuedDate = StringToArray(DateToString(pRef.VisaIssuedDate), 8);
		SetAttributeParameters(pPage1, "mVisaIssuedDate", vVisaIssuedDate, 8);
		
		vVisaValidToDate = StringToArray(DateToString(pRef.VisaToDate), 8);
		SetAttributeParameters(pPage1, "mVisaValidToDate", vVisaValidToDate, 8);
	ElsIf ValueIsFilled(pRef.IdentityDocumentType) And TrimAll(pRef.IdentityDocumentType.Code) = "12" Or
	      ValueIsFilled(pRef.IdentityDocumentType) And TrimAll(pRef.IdentityDocumentType.Code) = "19" Or
	      ValueIsFilled(pRef.IdentityDocumentType) And TrimAll(pRef.IdentityDocumentType.Code) = "20" Then
		pPage1.Parameters.mVisa = "";
		pPage1.Parameters.mResidencePermit = vX;
		
		SeriesAndNumberToArray(pRef.VisaNumber, 4, 10, vVisaSeries, vVisaNumber);
		SetAttributeParameters(pPage1, "mVisaSeries", vVisaSeries, 4);
		SetAttributeParameters(pPage1, "mVisaNumber", vVisaNumber, 10);
		
		vVisaFromDate = StringToArray(DateToString(pRef.VisaFromDate), 8);
		SetAttributeParameters(pPage1, "mVisaIssuedDate", vVisaFromDate, 8);
		
		vVisaValidToDate = StringToArray(DateToString(pRef.VisaToDate), 8);
		SetAttributeParameters(pPage1, "mVisaValidToDate", vVisaValidToDate, 8);
	ElsIf ValueIsFilled(pRef.IdentityDocumentType) And TrimAll(pRef.IdentityDocumentType.Code) = "101" Or
	      ValueIsFilled(pRef.IdentityDocumentType) And TrimAll(pRef.IdentityDocumentType.Code) = "101a" Then
		pPage1.Parameters.mVisa = "";
		pPage1.Parameters.mTimeResolution = vX;
		
		SeriesAndNumberToArray(pRef.VisaIdentifier, 4, 10, vVisaSeries, vVisaNumber);
		SetAttributeParameters(pPage1, "mVisaSeries", vVisaSeries, 4);
		SetAttributeParameters(pPage1, "mVisaNumber", vVisaNumber, 10);
		
		vVisaIssuedDate = StringToArray(DateToString(pRef.VisaIssuedDate), 8);
		SetAttributeParameters(pPage1, "mVisaIssuedDate", vVisaIssuedDate, 8);
		
		vVisaValidToDate = StringToArray(DateToString(pRef.VisaToDate), 8);
		SetAttributeParameters(pPage1, "mVisaValidToDate", vVisaValidToDate, 8);
	EndIf;

	// Migration card
	If Not IsBlankString(pRef.MigrationCardNumber) Then
		vSeriesLength = 4;
		vBlankPos = Find(TrimAll(pRef.MigrationCardNumber), " ");
		If vBlankPos > 4 Then
			vSeriesLength = vBlankPos - 1;
		EndIf;
		If StrLen(TrimAll(pRef.MigrationCardNumber)) >= 14 Then
			SeriesAndNumberToArray(pRef.MigrationCardNumber, vSeriesLength, 10, vMigrationCardSeries, vMigrationCardNumber);
		Else
			vMigrationCardSeries = StringToArray(Left(TrimAll(pRef.MigrationCardNumber), vSeriesLength), vSeriesLength);
			vMigrationCardNumber = StringToArray(Right(TrimAll(pRef.MigrationCardNumber), StrLen(TrimAll(pRef.MigrationCardNumber)) - vSeriesLength), 10);
		EndIf;
		SetAttributeParameters(pPage1, "mMigrationCardSeries", vMigrationCardSeries, 4);
		SetAttributeParameters(pPage1, "mMigrationCardNumber", vMigrationCardNumber, 10);
	EndIf;

	vBorderCrossingDate = StringToArray(DateToString(pRef.BorderCrossingDate), 8);
	SetAttributeParameters(pPage1, "mBorderCrossingDate", vBorderCrossingDate, 8);
	
	// Border check point number (КПП)
	pPage1.Parameters.mKPP = "";
	If Not IsBlankString(pRef.CheckPointNumber) Then
		pPage1.Parameters.mKPP = "КПП: " + TrimAll(pRef.CheckPointNumber);
	EndIf;
	
	// Guest trip purpose
	pPage1.Parameters.mTripPurposeOfficial = "";
	pPage1.Parameters.mTripPurposeTourism = "";
	pPage1.Parameters.mTripPurposeBusiness = "";
	pPage1.Parameters.mTripPurposeStudying = "";
	pPage1.Parameters.mTripPurposeWork = "";
	pPage1.Parameters.mTripPurposePrivate = "";
	pPage1.Parameters.mTripPurposeTransit = "";
	pPage1.Parameters.mTripPurposeHumanitarian = "";
	pPage1.Parameters.mTripPurposeOther = "";
	
	If pRef.TripPurpose = Catalogs.TripPurposes.Official Or 
	   pRef.TripPurpose = Catalogs.TripPurposes.Commerce Then
		pPage1.Parameters.mTripPurposeOfficial = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Tourism Then
		pPage1.Parameters.mTripPurposeTourism = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Business Then
		pPage1.Parameters.mTripPurposeBusiness = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Study Or
	      pRef.TripPurpose = Catalogs.TripPurposes.Scientific Then
		pPage1.Parameters.mTripPurposeStudying = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Work Then
		pPage1.Parameters.mTripPurposeWork = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Private Then
		pPage1.Parameters.mTripPurposePrivate = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Transit Or 
		  pRef.TripPurpose = Catalogs.TripPurposes.Crewman Then
		pPage1.Parameters.mTripPurposeTransit = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Humanitarian Then
		pPage1.Parameters.mTripPurposeHumanitarian = vX;
	Else
		pPage1.Parameters.mTripPurposeOther = vX;
	EndIf;
	
	// Company name and TIN
	vCompany = Undefined;
	If ValueIsFilled(pRef.Hotel) And ValueIsFilled(pRef.Hotel.CompanyRegisteredInUFMS) Then
		vCompany = pRef.Hotel.CompanyRegisteredInUFMS;
	Else 
		If ValueIsFilled(pRef.ParentDoc) And ValueIsFilled(pRef.ParentDoc.Company) Then
			vCompany = pRef.ParentDoc.Company;
		Else
			vCompany = pRef.Hotel.Company;
		EndIf;
	EndIf;
	vCompanyAddressStr = "";
	If ValueIsFilled(vCompany) Then
		vCompanyAddressStr = TrimAll(vCompany.PostAddress);
		
		vCompanyName = StringToArray(StrReplace(TrimAll(vCompany.LegacyName),"""",""), 57);
		SetAttributeParameters(pPage2, "mCompanyName", vCompanyName, 57);
		
		vCompanyTIN = StringToArray(vCompany.TIN, 12);
		SetAttributeParameters(pPage2, "mCompanyTIN", vCompanyTIN, 12);
		
		pPage2.Parameters.mCompanyDocumentGivingRightToProvidePremises1 = "";
		pPage2.Parameters.mCompanyDocumentGivingRightToProvidePremises2 = "";
		pPage2.Parameters.mCompanyDocumentGivingRightToProvidePremises3 = "";
	
		vCompanyDocumentGivingRightToProvidePremisesArray = cmGetTextLinesArray(TrimAll(vCompany.DocumentGivingRightToProvidePremises));
		i = 0;
		While i < vCompanyDocumentGivingRightToProvidePremisesArray.Count() Do
			If i = 0 Then
				pPage2.Parameters.mCompanyDocumentGivingRightToProvidePremises1 = vCompanyDocumentGivingRightToProvidePremisesArray.Get(i);
			ElsIf i = 1 Then
				pPage2.Parameters.mCompanyDocumentGivingRightToProvidePremises2 = vCompanyDocumentGivingRightToProvidePremisesArray.Get(i);
			ElsIf i = 2 Then
				pPage2.Parameters.mCompanyDocumentGivingRightToProvidePremises3 = vCompanyDocumentGivingRightToProvidePremisesArray.Get(i);
			Else
				Break;
			EndIf;
			i = i + 1;
		EndDo;
	Else
		SetAttributeParameters(pPage2, "mCompanyName", StringToArray("", 57), 57);
		
		SetAttributeParameters(pPage2, "mCompanyTIN", StringToArray("", 12), 12);
		
		pPage2.Parameters.mCompanyDocumentGivingRightToProvidePremises1 = "";
		pPage2.Parameters.mCompanyDocumentGivingRightToProvidePremises2 = "";
		pPage2.Parameters.mCompanyDocumentGivingRightToProvidePremises3 = "";
	EndIf;
		
	// Hotel address
	vHotelAddressStr = "";
	If ValueIsFilled(pRef.Hotel) Then
		vHotelAddressStr = pRef.Hotel.PostAddress;
		vAddress = cmParseAddress(vHotelAddressStr);
		
		vAddressRegion = StringToArray(vAddress.Region, 33);
		SetAttributeParameters(pPage1, "mAddressRegion", vAddressRegion, 30);
		SetAttributeParameters(pPage2, "mAddressRegion", vAddressRegion, 30);
		
		vAddressArea = StringToArray(vAddress.Area, 35);
		SetAttributeParameters(pPage1, "mAddressArea", vAddressArea, 35);
		SetAttributeParameters(pPage2, "mAddressArea", vAddressArea, 35);
		
		vAddressCity = StringToArray(vAddress.City, 33);
		SetAttributeParameters(pPage1, "mAddressCity", vAddressCity, 33);
		SetAttributeParameters(pPage2, "mAddressCity", vAddressCity, 33);
		
		vAddressStreet = StringToArray(vAddress.Street, 35);
		SetAttributeParameters(pPage1, "mAddressStreet", vAddressStreet, 35);
		SetAttributeParameters(pPage2, "mAddressStreet", vAddressStreet, 35);
		
		vHouse = TrimAll(vAddress.House);
		vBuilding = "";
		vHouseBuilding = "";
		ParseHouseNumber(vHouse, vBuilding, vHouseBuilding);
		
		vAddressHouse = StringToArray(TrimAll(vHouse), 8);
		SetAttributeParameters(pPage1, "mAddressHouse", vAddressHouse, 8);
		SetAttributeParameters(pPage2, "mAddressHouse", vAddressHouse, 8);
		
		If Not IsBlankString(vBuilding) Then
			vAddressBuilding = StringToArray(vBuilding, 2);
		Else
			vAddressBuilding = StringToArray("", 2);
		EndIf;
		SetAttributeParameters(pPage1, "mAddressBuilding", vAddressBuilding, 2);
		SetAttributeParameters(pPage2, "mAddressBuilding", vAddressBuilding, 2);
		
		If Not IsBlankString(vHouseBuilding) Then
			vAddressHouseBuilding = StringToArray(vHouseBuilding, 4);
		Else
			vAddressHouseBuilding = StringToArray("", 4);
		EndIf;
		SetAttributeParameters(pPage1, "mAddressHouseBuilding", vAddressHouseBuilding, 4);
		SetAttributeParameters(pPage2, "mAddressHouseBuilding", vAddressHouseBuilding, 4);
		
		vFlat = vAddress.Flat;
		If IsBlankString(vFlat) And ValueIsFilled(pRef.Room) Then
			vFlat = TrimAll(pRef.Room);
		EndIf;
		vFlat = StrReplace(vFlat, "/", "");
		vAddressFlat = StringToArray(vFlat, 5);
		SetAttributeParameters(pPage1, "mAddressFlat", vAddressFlat, 5);
		SetAttributeParameters(pPage2, "mAddressFlat", vAddressFlat, 5);
	Else
		SetAttributeParameters(pPage1, "mAddressRegion", StringToArray("", 30), 30);
		SetAttributeParameters(pPage2, "mAddressRegion", StringToArray("", 30), 30);
		
		SetAttributeParameters(pPage1, "mAddressArea", StringToArray("", 35), 35);
		SetAttributeParameters(pPage2, "mAddressArea", StringToArray("", 35), 35);
		
		SetAttributeParameters(pPage1, "mAddressCity", StringToArray("", 33), 33);
		SetAttributeParameters(pPage2, "mAddressCity", StringToArray("", 33), 33);
		
		SetAttributeParameters(pPage1, "mAddressStreet", StringToArray("", 35), 35);
		SetAttributeParameters(pPage2, "mAddressStreet", StringToArray("", 35), 35);
		
		SetAttributeParameters(pPage1, "mAddressHouse", StringToArray("", 8), 8);
		SetAttributeParameters(pPage2, "mAddressHouse", StringToArray("", 8), 8);
		
		SetAttributeParameters(pPage1, "mAddressBuilding", StringToArray("", 2), 2);
		SetAttributeParameters(pPage2, "mAddressBuilding", StringToArray("", 2), 2);
		
		SetAttributeParameters(pPage1, "mAddressHouseBuilding", StringToArray("", 4), 4);
		SetAttributeParameters(pPage2, "mAddressHouseBuilding", StringToArray("", 4), 4);
		
		SetAttributeParameters(pPage1, "mAddressFlat", StringToArray("", 5), 5);
		SetAttributeParameters(pPage2, "mAddressFlat", StringToArray("", 5), 5);
	EndIf;

	// Hotel phone
	vHotelPhoneStr = "";
	If ValueIsFilled(pRef.Hotel) Then
		vHotelPhoneStr = RemoveDelimeters(TrimAll(pRef.Hotel.Phones));
		vHotelPhone = StringToArray(vHotelPhoneStr, 10);
	EndIf;
	
	// Check out date
	If ValueIsFilled(pRef.CheckOutDate) Then
		vCheckOutDate = StringToArray(DateToString(pRef.CheckOutDate), 8);
		SetAttributeParameters(pPage1, "mCheckOutDate", vCheckOutDate, 8);
		
		// Date when guest leaves the hotel
		If cmCheckUserPermissions("HavePermissionToPrintCheckOutDateInTheForeignerNotificationFormFooter") Then
			vDateTo = StringToArray(DateToString(pRef.CheckOutDate), 8);
		EndIf;
	Else
		SetAttributeParameters(pPage1, "mCheckOutDate", StringToArray("", 8), 8);
	EndIf;

	// Employee that signes notification
	If ValueIsFilled(pEmployee) Then
		// Employee name
		vEmployeeLastName = StringToArray(pEmployee.LastName, 35);
		SetAttributeParameters(pPage2, "mEmployeeLastName", vEmployeeLastName, 35);
		vEmployeeName = StringToArray(TrimAll(pEmployee.FirstName) + " " + 
								      TrimAll(pEmployee.SecondName), 32);
		SetAttributeParameters(pPage2, "mEmployeeName", vEmployeeName, 32);
		
		// Employee date of birth
		vEmployeeDateOfBirth = StringToArray(DateToString(pEmployee.DateOfBirth), 8);
		SetAttributeParameters(pPage2, "mEmployeeBirthDate", vEmployeeDateOfBirth, 8);
		
		// Employee living address
		If Not IsBlankString(pEmployee.Address) Then
			vEmployeeAddress = cmParseAddress(pEmployee.Address);
		Else
			vEmployeeAddress = cmParseAddress(vHotelAddressStr);
		EndIf;
		
		vEmployeeAddressRegion = StringToArray(vEmployeeAddress.Region, 30);
		SetAttributeParameters(pPage2, "mEmployeeAddressRegion", vEmployeeAddressRegion, 30);
		
		vEmployeeAddressArea = StringToArray(vEmployeeAddress.Area, 35);
		SetAttributeParameters(pPage2, "mEmployeeAddressArea", vEmployeeAddressArea, 35);
		
		vEmployeeAddressCity = StringToArray(vEmployeeAddress.City, 33);
		SetAttributeParameters(pPage2, "mEmployeeAddressCity", vEmployeeAddressCity, 33);
		
		vEmployeeAddressStreet = StringToArray(vEmployeeAddress.Street, 35);
		SetAttributeParameters(pPage2, "mEmployeeAddressStreet", vEmployeeAddressStreet, 35);
		
		vHouse = TrimAll(vEmployeeAddress.House);
		vBuilding = "";
		vHouseBuilding = "";
		ParseHouseNumber(vHouse, vBuilding, vHouseBuilding);
		
		vEmployeeAddressHouse = StringToArray(vHouse, 4);
		SetAttributeParameters(pPage2, "mEmployeeAddressHouse", vEmployeeAddressHouse, 4);
		
		If Not IsBlankString(vBuilding) Then
			vEmployeeAddressBuilding = StringToArray(vBuilding, 4);
		Else
			vEmployeeAddressBuilding = StringToArray("", 4);
		EndIf;
		SetAttributeParameters(pPage2, "mEmployeeAddressBuilding", vEmployeeAddressBuilding, 2);
		
		If Not IsBlankString(vHouseBuilding) Then
			vEmployeeAddressHouseBuilding = StringToArray(vHouseBuilding, 4);
		Else
			vEmployeeAddressHouseBuilding = StringToArray("", 4);
		EndIf;
		SetAttributeParameters(pPage2, "mEmployeeAddressHouseBuilding", vEmployeeAddressHouseBuilding, 4);
		
		vEmployeeAddressFlat = StringToArray(vEmployeeAddress.Flat, 4);
		SetAttributeParameters(pPage2, "mEmployeeAddressFlat", vEmployeeAddressFlat, 4);
		
		// Employee identification document
		If Find(Upper(TrimAll(pEmployee.IdentityDocumentType)), "ПАСПОРТ") > 0 Then
			vEmployeeIDType = StringToArray("ПАСПОРТ", 11);
		Else
			vEmployeeIDType = StringToArray(pEmployee.IdentityDocumentType, 11);
		EndIf;
		SetAttributeParameters(pPage2, "mEmployeeIDType", vEmployeeIDType, 11);
		
		vEmployeeIDSeries = StringToArray(TrimAll(StrReplace(pEmployee.IdentityDocumentSeries, " ", "")), 4);
		SetAttributeParameters(pPage2, "mEmployeeIDSeries", vEmployeeIDSeries, 4);
		
		vEmployeeIDNumber = StringToArray(TrimAll(pEmployee.IdentityDocumentNumber), 9);
		SetAttributeParameters(pPage2, "mEmployeeIDNumber", vEmployeeIDNumber, 9);
		
		vEmployeeIDIssuedDate = StringToArray(DateToString(pEmployee.IdentityDocumentIssueDate), 8);
		SetAttributeParameters(pPage2, "mEmployeeIDIssuedDate", vEmployeeIDIssuedDate, 8);
		
		vEmployeeIDValidToDate = StringToArray(DateToString(pEmployee.IdentityDocumentValidToDate), 8);
		SetAttributeParameters(pPage2, "mEmployeeIDValidToDate", vEmployeeIDValidToDate, 8);
		
		// Employee phone
		If Not IsBlankString(pEmployee.Phones) Then
			vEmployeePhone = StringToArray(RemoveDelimeters(TrimAll(pEmployee.Phones)), 10);
		Else
			vEmployeePhone = StringToArray(vHotelPhoneStr, 10);
		EndIf;
		SetAttributeParameters(pPage2, "mEmployeePhone", vEmployeePhone, 10);
	Else // Employee is not selected, so fill all employee data with blanks except address and phone
		// Employee name
		SetAttributeParameters(pPage2, "mEmployeeLastName", StringToArray("", 32), 32);
		SetAttributeParameters(pPage2, "mEmployeeName", StringToArray("", 32), 32);
		
		// Employee date of birth
		SetAttributeParameters(pPage2, "mEmployeeBirthDate", StringToArray("", 8), 8);
		
		// Employee living address
		vEmployeeAddress = cmParseAddress(vHotelAddressStr);
		
		vEmployeeAddressRegion = StringToArray(vEmployeeAddress.Region, 30);
		SetAttributeParameters(pPage2, "mEmployeeAddressRegion", vEmployeeAddressRegion, 30);
		
		vEmployeeAddressArea = StringToArray(vEmployeeAddress.Area, 35);
		SetAttributeParameters(pPage2, "mEmployeeAddressArea", vEmployeeAddressArea, 35);
		
		vEmployeeAddressCity = StringToArray(vEmployeeAddress.City, 33);
		SetAttributeParameters(pPage2, "mEmployeeAddressCity", vEmployeeAddressCity, 33);
		
		vEmployeeAddressStreet = StringToArray(vEmployeeAddress.Street, 35);
		SetAttributeParameters(pPage2, "mEmployeeAddressStreet", vEmployeeAddressStreet, 35);
		
		vHouse = TrimAll(vEmployeeAddress.House);
		vBuilding = "";
		vHouseBuilding = "";
		ParseHouseNumber(vHouse, vBuilding, vHouseBuilding);
		
		vEmployeeAddressHouse = StringToArray(vHouse, 4);
		SetAttributeParameters(pPage2, "mEmployeeAddressHouse", vEmployeeAddressHouse, 4);
		
		If Not IsBlankString(vBuilding) Then
			vEmployeeAddressBuilding = StringToArray(vBuilding, 4);
		Else
			vEmployeeAddressBuilding = StringToArray("", 4);
		EndIf;
		SetAttributeParameters(pPage2, "mEmployeeAddressBuilding", vEmployeeAddressBuilding, 2);
		
		If Not IsBlankString(vHouseBuilding) Then
			vEmployeeAddressHouseBuilding = StringToArray(vHouseBuilding, 4);
		Else
			vEmployeeAddressHouseBuilding = StringToArray("", 4);
		EndIf;
		SetAttributeParameters(pPage2, "mEmployeeAddressHouseBuilding", vEmployeeAddressHouseBuilding, 4);
		
		vEmployeeAddressFlat = StringToArray(vEmployeeAddress.Flat, 4);
		SetAttributeParameters(pPage2, "mEmployeeAddressFlat", vEmployeeAddressFlat, 4);
		
		// Employee identification document
		SetAttributeParameters(pPage2, "mEmployeeIDType", StringToArray("", 11), 11);
		
		SetAttributeParameters(pPage2, "mEmployeeIDSeries", StringToArray("", 4), 4);
		
		SetAttributeParameters(pPage2, "mEmployeeIDNumber", StringToArray("", 9), 9);
		
		SetAttributeParameters(pPage2, "mEmployeeIDIssuedDate", StringToArray("", 8), 8);
		
		SetAttributeParameters(pPage2, "mEmployeeIDValidToDate", StringToArray("", 8), 8);
		
		// Employee phone
		vEmployeePhone = StringToArray(vHotelPhoneStr, 10);
		SetAttributeParameters(pPage2, "mEmployeePhone", vEmployeePhone, 10);
	EndIf;
	
	// Hotel address
	vCompanyAddress = StringToArray(cmGetAddressPresentation(vCompanyAddressStr), 92);
	SetAttributeParameters(pPage2, "mHotelAddress", vCompanyAddress, 92);
	
	// Migration office number
	pPage1.Parameters.mMigrationOfficeNumber = "";
	pPage2.Parameters.mMigrationOfficeNumber = "";
	pPage1.Parameters.mCheckInDate = '00010101';
	pPage2.Parameters.mCheckInDate = '00010101';
	If ValueIsFilled(pRef.Hotel) Then
		If Not IsBlankString(pRef.Hotel.MigrationOfficeNumber) Then
			pPage1.Parameters.mMigrationOfficeNumber = TrimAll(pRef.Hotel.MigrationOfficeNumber);
			pPage2.Parameters.mMigrationOfficeNumber = TrimAll(pRef.Hotel.MigrationOfficeNumber);
			
			pPage1.Parameters.mCheckInDate = pRef.CheckInDate;
			pPage2.Parameters.mCheckInDate = pRef.CheckInDate;
		EndIf;
	EndIf;
EndProcedure // SetParametersNotificationForPages20200914

// -----------------------------------------------------------------------------
Procedure SetParametersNotificationForPages20171123(pPage1, pPage2, pRef, pEmployee) Export
	Var vVisaSeries;
	Var vVisaNumber;
	Var vMigrationCardSeries;
	Var vMigrationCardNumber;
	
	// Check char
	vX = "Х";
	
	// Try to fill guest data	
	If ValueIsFilled(pRef.Guest) Then
		// Guest name
		If IsBlankString(pRef.LastName) Then
			vGuestLastName = StringToArray(pRef.Guest.LastName, 35);
			SetAttributeParameters(pPage1, "mGuestLastName", vGuestLastName, 35);
			vGuestName = StringToArray(TrimAll(pRef.Guest.FirstName) + " " + 
			                           TrimAll(pRef.Guest.SecondName), 35);
			SetAttributeParameters(pPage1, "mGuestName", vGuestName, 35);
		Else
			vGuestLastName = StringToArray(pRef.LastName, 35);
			SetAttributeParameters(pPage1, "mGuestLastName", vGuestLastName, 35);
			vGuestName = StringToArray(TrimAll(pRef.FirstName) + " " + 
			                           TrimAll(pRef.SecondName), 35);
			SetAttributeParameters(pPage1, "mGuestName", vGuestName, 35);
		EndIf;
		
		// Guest citizenship
		vGuestCitizenship = StringToArray(TrimAll(pRef.Citizenship),34);
		SetAttributeParameters(pPage1, "mGuestCitizenship", vGuestCitizenship, 34);
		
		// Guest date of birth
		vGuestDateOfBirth = StringToArray(DateToString(pRef.DateOfBirth), 8);
		SetAttributeParameters(pPage1, "mGuestBirthDate", vGuestDateOfBirth, 8);
		
		// Guest place of birth
		vGuestPlaceOfBirth = cmParseAddress(pRef.PlaceOfBirth);
		
		vGuestPlaceOfBirthCountry = StringToArray(vGuestPlaceOfBirth.Country, 33);
		SetAttributeParameters(pPage1, "mGuestBirthPlaceCountry", vGuestPlaceOfBirthCountry, 33);
		
		vGuestPlaceOfBirthCity = StringToArray(vGuestPlaceOfBirth.City, 33);
		SetAttributeParameters(pPage1, "mGuestBirthPlaceCity", vGuestPlaceOfBirthCity, 33);
		
		// Guest sex
		If pRef.Sex = Enums.Sex.Male Then
			pPage1.Parameters.mGuestSexMale = vX;
			pPage1.Parameters.mGuestSexFemale = "";
		ElsIf pRef.Sex = Enums.Sex.Female Then
			pPage1.Parameters.mGuestSexMale = "";
			pPage1.Parameters.mGuestSexFemale = vX;
		Else
			pPage1.Parameters.mGuestSexMale = "";
			pPage1.Parameters.mGuestSexFemale = "";
		EndIf;
		
		// Guest identification document
		If Find(Upper(TrimAll(pRef.IdentityDocumentType)), "ПАСПОРТ") > 0 Then
			vGuestIDType = StringToArray("ПАСПОРТ", 11);
		Else
			vGuestIDType = StringToArray(pRef.IdentityDocumentType, 11);
		EndIf;
		SetAttributeParameters(pPage1, "mGuestIDType", vGuestIDType, 11);
		
		vGuestIDSeries = StringToArray(TrimAll(StrReplace(pRef.IdentityDocumentSeries, " ", "")), 4);
		SetAttributeParameters(pPage1, "mGuestIDSeries", vGuestIDSeries, 4);
		
		vGuestIDNumber = StringToArray(TrimAll(pRef.IdentityDocumentNumber), 10);
		SetAttributeParameters(pPage1, "mGuestIDNumber", vGuestIDNumber, 10);
		
		vGuestIDIssuedDate = StringToArray(DateToString(pRef.IdentityDocumentIssueDate), 8);
		SetAttributeParameters(pPage1, "mGuestIDIssuedDate", vGuestIDIssuedDate, 8);
		
		vGuestIDValidToDate = StringToArray(DateToString(pRef.IdentityDocumentValidToDate), 8);
		SetAttributeParameters(pPage1, "mGuestIDValidToDate", vGuestIDValidToDate, 8);
	Else // Guest is not selected, so fill all guest data with blanks
		// Guest name
		SetAttributeParameters(pPage1, "mGuestLastName", StringToArray("", 35), 35);
		SetAttributeParameters(pPage1, "mGuestName", StringToArray("", 35), 35);
		
		// Guest citizenship
		SetAttributeParameters(pPage1, "mGuestCitizenship", StringToArray("", 34), 34);
		
		// Guest date of birth
		SetAttributeParameters(pPage1, "mGuestBirthDate", StringToArray("", 8), 8);
		
		// Guest place of birth
		SetAttributeParameters(pPage1, "mGuestBirthPlaceCountry", StringToArray("", 33), 33);
		SetAttributeParameters(pPage1, "mGuestBirthPlaceCity", StringToArray("", 33), 33);
		
		// Guest sex
		pPage1.Parameters.mGuestSexMale = "";
		pPage1.Parameters.mGuestSexFemale = "";
		
		// Guest identification document
		SetAttributeParameters(pPage1, "mGuestIDType", StringToArray("", 11), 11);
		SetAttributeParameters(pPage1, "mGuestIDSeries", StringToArray("", 4), 4);
		SetAttributeParameters(pPage1, "mGuestIDNumber", StringToArray("", 10), 10);
		SetAttributeParameters(pPage1, "mGuestIDIssuedDate", StringToArray("", 8), 8);
		SetAttributeParameters(pPage1, "mGuestIDValidToDate", StringToArray("", 8), 8);
	EndIf;
	
	// Guest profession and standing
	vGuestProfession = StringToArray(TrimAll(pRef.Profession), 23);
	SetAttributeParameters(pPage1, "mGuestProfession", vGuestProfession, 23);
	
	vGuestStanding = StringToArray(TrimAll(pRef.Standing), 2);
	// Standing was removed from this form
	
	// Legal representatives
	If Not IsBlankString(pRef.LegalRepresentativeLastName) Then
		vLegalRepresentativeName = TrimAll(TrimAll(pRef.LegalRepresentativeLastName) + " " + TrimAll(pRef.LegalRepresentativeFirstName) + " " + TrimAll(pRef.LegalRepresentativeSecondName));
		vLegalRepresentative = pRef.LegalRepresentative;
		If ValueIsFilled(vLegalRepresentative) Then
			vLegalRepresentatives = StringToArray(vLegalRepresentativeName + 
			                        ?(ValueIsFilled(vLegalRepresentative.DateOfBirth), ", " + Format(vLegalRepresentative.DateOfBirth, "DF=dd.MM.yyyy"), "") +
			                        ?(ValueIsFilled(vLegalRepresentative.Sex), ", " + TrimAll(vLegalRepresentative.Sex), "") + 
									?(Not IsBlankString(vLegalRepresentative.IdentityDocumentNumber), ", №" + TrimAll(TrimAll(vLegalRepresentative.IdentityDocumentSeries) + " " + TrimAll(vLegalRepresentative.IdentityDocumentNumber)), ""), 38);
		Else
			vLegalRepresentatives = StringToArray(vLegalRepresentativeName, 38);
		EndIf;
	ElsIf ValueIsFilled(pRef.LegalRepresentative) Then
		vLegalRepresentative = pRef.LegalRepresentative;
		vLegalRepresentatives = StringToArray(TrimAll(TrimAll(vLegalRepresentative.LastName) + " " + TrimAll(vLegalRepresentative.FirstName) + " " + TrimAll(vLegalRepresentative.SecondName)) + 
		                        ?(ValueIsFilled(vLegalRepresentative.DateOfBirth), ", " + Format(vLegalRepresentative.DateOfBirth, "DF=dd.MM.yyyy"), "") +
		                        ?(ValueIsFilled(vLegalRepresentative.Sex), ", " + TrimAll(vLegalRepresentative.Sex), "") + 
								?(Not IsBlankString(vLegalRepresentative.IdentityDocumentNumber), ", №" + TrimAll(TrimAll(vLegalRepresentative.IdentityDocumentSeries) + " " + TrimAll(vLegalRepresentative.IdentityDocumentNumber)), ""), 38);
	ElsIf Not IsBlankString(pRef.LegalRepresentatives) Then
		vLegalRepresentatives = StringToArray(TrimAll(pRef.LegalRepresentatives), 38);
	Else
		vLegalRepresentatives = StringToArray("", 38);
	EndIf;
	SetAttributeParameters(pPage1, "mLegalRepresentatives", vLegalRepresentatives, 38);
	
	// Previous place of stay
	vPreviousPlaceOfStay = StringToArray(TrimAll(pRef.PreviousPlaceOfStay), 57);
	SetAttributeParameters(pPage1, "mPreviousStayAddress", vPreviousPlaceOfStay, 57);
	
	// Visa
	If Not IsBlankString(pRef.VisaNumber) Then
		pPage1.Parameters.mVisa = vX;
		
		SeriesAndNumberToArray(pRef.VisaNumber, 4, 10, vVisaSeries, vVisaNumber);
		SetAttributeParameters(pPage1, "mVisaSeries", vVisaSeries, 4);
		SetAttributeParameters(pPage1, "mVisaNumber", vVisaNumber, 10);
		
		vVisaIssuedDate = StringToArray(DateToString(pRef.VisaIssuedDate), 8);
		SetAttributeParameters(pPage1, "mVisaIssuedDate", vVisaIssuedDate, 8);
		
		vVisaValidToDate = StringToArray(DateToString(pRef.VisaToDate), 8);
		SetAttributeParameters(pPage1, "mVisaValidToDate", vVisaValidToDate, 8);
	Else
		pPage1.Parameters.mVisa = "";
		
		SetAttributeParameters(pPage1, "mVisaSeries", StringToArray("", 4), 4);
		SetAttributeParameters(pPage1, "mVisaNumber", StringToArray("", 10), 10);
		
		SetAttributeParameters(pPage1, "mVisaIssuedDate", StringToArray("", 8), 8);
		
		SetAttributeParameters(pPage1, "mVisaValidToDate", StringToArray("", 8), 8);
	EndIf;
	
	pPage1.Parameters.mResidencePermit = "";
	pPage1.Parameters.mTimeResolution = "";
	If ValueIsFilled(pRef.ResidencePermitDocument) And pRef.ResidencePermitDocument = Enums.ConfirmingDocuments.PermResidencePermit Or 
	   ValueIsFilled(pRef.VisaType) And TrimAll(pRef.VisaType.Code) = "ВЖ" Then
		pPage1.Parameters.mVisa = "";
		pPage1.Parameters.mResidencePermit = vX;
		
		SeriesAndNumberToArray(pRef.VisaNumber, 4, 10, vVisaSeries, vVisaNumber);
		SetAttributeParameters(pPage1, "mVisaSeries", vVisaSeries, 4);
		SetAttributeParameters(pPage1, "mVisaNumber", vVisaNumber, 10);
		
		vVisaFromDate = StringToArray(DateToString(pRef.VisaFromDate), 8);
		SetAttributeParameters(pPage1, "mVisaIssuedDate", vVisaFromDate, 8);
		
		vVisaValidToDate = StringToArray(DateToString(pRef.VisaToDate), 8);
		SetAttributeParameters(pPage1, "mVisaValidToDate", vVisaValidToDate, 8);
	ElsIf ValueIsFilled(pRef.ResidencePermitDocument) And pRef.ResidencePermitDocument = Enums.ConfirmingDocuments.TempResidencePermit Or 
	      ValueIsFilled(pRef.VisaType) And TrimAll(pRef.VisaType.Code) = "ВР" Then
		pPage1.Parameters.mVisa = "";
		pPage1.Parameters.mTimeResolution = vX;
		
		SeriesAndNumberToArray(pRef.VisaIdentifier, 4, 10, vVisaSeries, vVisaNumber);
		SetAttributeParameters(pPage1, "mVisaSeries", vVisaSeries, 4);
		SetAttributeParameters(pPage1, "mVisaNumber", vVisaNumber, 10);
		
		vVisaIssuedDate = StringToArray(DateToString(pRef.VisaIssuedDate), 8);
		SetAttributeParameters(pPage1, "mVisaIssuedDate", vVisaIssuedDate, 8);
		
		vVisaValidToDate = StringToArray(DateToString(pRef.VisaToDate), 8);
		SetAttributeParameters(pPage1, "mVisaValidToDate", vVisaValidToDate, 8);
	ElsIf ValueIsFilled(pRef.IdentityDocumentType) And TrimAll(pRef.IdentityDocumentType.Code) = "12" Or
	      ValueIsFilled(pRef.IdentityDocumentType) And TrimAll(pRef.IdentityDocumentType.Code) = "19" Or
	      ValueIsFilled(pRef.IdentityDocumentType) And TrimAll(pRef.IdentityDocumentType.Code) = "20" Then
		pPage1.Parameters.mVisa = "";
		pPage1.Parameters.mResidencePermit = vX;
		
		SeriesAndNumberToArray(pRef.VisaNumber, 4, 10, vVisaSeries, vVisaNumber);
		SetAttributeParameters(pPage1, "mVisaSeries", vVisaSeries, 4);
		SetAttributeParameters(pPage1, "mVisaNumber", vVisaNumber, 10);
		
		vVisaFromDate = StringToArray(DateToString(pRef.VisaFromDate), 8);
		SetAttributeParameters(pPage1, "mVisaIssuedDate", vVisaFromDate, 8);
		
		vVisaValidToDate = StringToArray(DateToString(pRef.VisaToDate), 8);
		SetAttributeParameters(pPage1, "mVisaValidToDate", vVisaValidToDate, 8);
	ElsIf ValueIsFilled(pRef.IdentityDocumentType) And TrimAll(pRef.IdentityDocumentType.Code) = "101" Or
	      ValueIsFilled(pRef.IdentityDocumentType) And TrimAll(pRef.IdentityDocumentType.Code) = "101a" Then
		pPage1.Parameters.mVisa = "";
		pPage1.Parameters.mTimeResolution = vX;
		
		SeriesAndNumberToArray(pRef.VisaIdentifier, 4, 10, vVisaSeries, vVisaNumber);
		SetAttributeParameters(pPage1, "mVisaSeries", vVisaSeries, 4);
		SetAttributeParameters(pPage1, "mVisaNumber", vVisaNumber, 10);
		
		vVisaIssuedDate = StringToArray(DateToString(pRef.VisaIssuedDate), 8);
		SetAttributeParameters(pPage1, "mVisaIssuedDate", vVisaIssuedDate, 8);
		
		vVisaValidToDate = StringToArray(DateToString(pRef.VisaToDate), 8);
		SetAttributeParameters(pPage1, "mVisaValidToDate", vVisaValidToDate, 8);
	EndIf;

	// Migration card
	If Not IsBlankString(pRef.MigrationCardNumber) Then
		vSeriesLength = 4;
		vBlankPos = Find(TrimAll(pRef.MigrationCardNumber), " ");
		If vBlankPos > 4 Then
			vSeriesLength = vBlankPos - 1;
		EndIf;
		If StrLen(TrimAll(pRef.MigrationCardNumber)) >= 14 Then
			SeriesAndNumberToArray(pRef.MigrationCardNumber, vSeriesLength, 10, vMigrationCardSeries, vMigrationCardNumber);
		Else
			vMigrationCardSeries = StringToArray(Left(TrimAll(pRef.MigrationCardNumber), vSeriesLength), vSeriesLength);
			vMigrationCardNumber = StringToArray(Right(TrimAll(pRef.MigrationCardNumber), StrLen(TrimAll(pRef.MigrationCardNumber)) - vSeriesLength), 10);
		EndIf;
		SetAttributeParameters(pPage1, "mMigrationCardSeries", vMigrationCardSeries, 4);
		SetAttributeParameters(pPage1, "mMigrationCardNumber", vMigrationCardNumber, 10);
	EndIf;

	vBorderCrossingDate = StringToArray(DateToString(pRef.BorderCrossingDate), 8);
	SetAttributeParameters(pPage1, "mBorderCrossingDate", vBorderCrossingDate, 8);
	
	// Border check point number (КПП)
	pPage1.Parameters.mKPP = "";
	If Not IsBlankString(pRef.CheckPointNumber) Then
		pPage1.Parameters.mKPP = "КПП: " + TrimAll(pRef.CheckPointNumber);
	EndIf;
	
	// Guest trip purpose
	pPage1.Parameters.mTripPurposeOfficial = "";
	pPage1.Parameters.mTripPurposeTourism = "";
	pPage1.Parameters.mTripPurposeBusiness = "";
	pPage1.Parameters.mTripPurposeStudying = "";
	pPage1.Parameters.mTripPurposeWork = "";
	pPage1.Parameters.mTripPurposePrivate = "";
	pPage1.Parameters.mTripPurposeTransit = "";
	pPage1.Parameters.mTripPurposeHumanitarian = "";
	pPage1.Parameters.mTripPurposeOther = "";
	
	If pRef.TripPurpose = Catalogs.TripPurposes.Official Or 
	   pRef.TripPurpose = Catalogs.TripPurposes.Commerce Then
		pPage1.Parameters.mTripPurposeOfficial = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Tourism Then
		pPage1.Parameters.mTripPurposeTourism = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Business Then
		pPage1.Parameters.mTripPurposeBusiness = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Study Or
	      pRef.TripPurpose = Catalogs.TripPurposes.Scientific Then
		pPage1.Parameters.mTripPurposeStudying = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Work Then
		pPage1.Parameters.mTripPurposeWork = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Private Then
		pPage1.Parameters.mTripPurposePrivate = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Transit Or 
		  pRef.TripPurpose = Catalogs.TripPurposes.Crewman Then
		pPage1.Parameters.mTripPurposeTransit = vX;
	ElsIf pRef.TripPurpose = Catalogs.TripPurposes.Humanitarian Then
		pPage1.Parameters.mTripPurposeHumanitarian = vX;
	Else
		pPage1.Parameters.mTripPurposeOther = vX;
	EndIf;
	
	// Company name and TIN
	vCompany = Undefined;
	If ValueIsFilled(pRef.Hotel) And ValueIsFilled(pRef.Hotel.CompanyRegisteredInUFMS) Then
		vCompany = pRef.Hotel.CompanyRegisteredInUFMS;
	Else 
		If ValueIsFilled(pRef.ParentDoc) And ValueIsFilled(pRef.ParentDoc.Company) Then
			vCompany = pRef.ParentDoc.Company;
		Else
			vCompany = pRef.Hotel.Company;
		EndIf;
	EndIf;
	vCompanyAddressStr = "";
	If ValueIsFilled(vCompany) Then
		vCompanyAddressStr = TrimAll(vCompany.PostAddress);
		
		vCompanyName = StringToArray(StrReplace(TrimAll(vCompany.LegacyName),"""",""), 52);
		SetAttributeParameters(pPage2, "mCompanyName", vCompanyName, 52);
		
		vCompanyTIN = StringToArray(vCompany.TIN, 12);
		SetAttributeParameters(pPage2, "mCompanyTIN", vCompanyTIN, 12);
	Else
		SetAttributeParameters(pPage2, "mCompanyName", StringToArray("", 52), 52);
		
		SetAttributeParameters(pPage2, "mCompanyTIN", StringToArray("", 12), 12);
	EndIf;
		
	// Hotel address
	vHotelAddressStr = "";
	If ValueIsFilled(pRef.Hotel) Then
		vHotelAddressStr = pRef.Hotel.PostAddress;
		vAddress = cmParseAddress(vHotelAddressStr);
		
		vAddressRegion = StringToArray(vAddress.Region, 33);
		SetAttributeParameters(pPage1, "mAddressRegion", vAddressRegion, 33);
		SetAttributeParameters(pPage2, "mAddressRegion", vAddressRegion, 33);
		
		vAddressArea = StringToArray(vAddress.Area, 35);
		SetAttributeParameters(pPage1, "mAddressArea", vAddressArea, 35);
		SetAttributeParameters(pPage2, "mAddressArea", vAddressArea, 35);
		
		vAddressCity = StringToArray(vAddress.City, 33);
		SetAttributeParameters(pPage1, "mAddressCity", vAddressCity, 33);
		SetAttributeParameters(pPage2, "mAddressCity", vAddressCity, 33);
		
		vAddressStreet = StringToArray(vAddress.Street, 35);
		SetAttributeParameters(pPage1, "mAddressStreet", vAddressStreet, 35);
		SetAttributeParameters(pPage2, "mAddressStreet", vAddressStreet, 35);
		
		vHouse = TrimAll(vAddress.House);
		vBuilding = "";
		vHouseBuilding = "";
		ParseHouseNumber(vHouse, vBuilding, vHouseBuilding);
		
		vAddressHouse = StringToArray(TrimAll(vHouse), 4);
		SetAttributeParameters(pPage1, "mAddressHouse", vAddressHouse, 4);
		SetAttributeParameters(pPage2, "mAddressHouse", vAddressHouse, 4);
		
		If Not IsBlankString(vBuilding) Then
			vAddressBuilding = StringToArray(vBuilding, 4);
		Else
			vAddressBuilding = StringToArray("", 4);
		EndIf;
		SetAttributeParameters(pPage1, "mAddressBuilding", vAddressBuilding, 4);
		SetAttributeParameters(pPage2, "mAddressBuilding", vAddressBuilding, 4);
		
		If Not IsBlankString(vHouseBuilding) Then
			vAddressHouseBuilding = StringToArray(vHouseBuilding, 4);
		Else
			vAddressHouseBuilding = StringToArray("", 4);
		EndIf;
		SetAttributeParameters(pPage1, "mAddressHouseBuilding", vAddressHouseBuilding, 4);
		SetAttributeParameters(pPage2, "mAddressHouseBuilding", vAddressHouseBuilding, 4);
		
		vFlat = vAddress.Flat;
		If IsBlankString(vFlat) And ValueIsFilled(pRef.Room) Then
			vFlat = TrimAll(pRef.Room);
		EndIf;
		vFlat = StrReplace(vFlat, "/", "");
		vAddressFlat = StringToArray(vFlat, 5);
		SetAttributeParameters(pPage1, "mAddressFlat", vAddressFlat, 5);
		SetAttributeParameters(pPage2, "mAddressFlat", vAddressFlat, 5);
	Else
		SetAttributeParameters(pPage1, "mAddressRegion", StringToArray("", 33), 33);
		SetAttributeParameters(pPage2, "mAddressRegion", StringToArray("", 33), 33);
		
		SetAttributeParameters(pPage1, "mAddressArea", StringToArray("", 35), 35);
		SetAttributeParameters(pPage2, "mAddressArea", StringToArray("", 35), 35);
		
		SetAttributeParameters(pPage1, "mAddressCity", StringToArray("", 33), 33);
		SetAttributeParameters(pPage2, "mAddressCity", StringToArray("", 33), 33);
		
		SetAttributeParameters(pPage1, "mAddressStreet", StringToArray("", 35), 35);
		SetAttributeParameters(pPage2, "mAddressStreet", StringToArray("", 35), 35);
		
		SetAttributeParameters(pPage1, "mAddressHouse", StringToArray("", 4), 4);
		SetAttributeParameters(pPage2, "mAddressHouse", StringToArray("", 4), 4);
		
		SetAttributeParameters(pPage1, "mAddressBuilding", StringToArray("", 4), 4);
		SetAttributeParameters(pPage2, "mAddressBuilding", StringToArray("", 4), 4);
		
		SetAttributeParameters(pPage1, "mAddressHouseBuilding", StringToArray("", 4), 4);
		SetAttributeParameters(pPage2, "mAddressHouseBuilding", StringToArray("", 4), 4);
		
		SetAttributeParameters(pPage1, "mAddressFlat", StringToArray("", 5), 5);
		SetAttributeParameters(pPage2, "mAddressFlat", StringToArray("", 5), 5);
	EndIf;

	// Hotel phone
	vHotelPhoneStr = "";
	If ValueIsFilled(pRef.Hotel) Then
		vHotelPhoneStr = RemoveDelimeters(TrimAll(pRef.Hotel.Phones));
		vHotelPhone = StringToArray(vHotelPhoneStr, 10);
		SetAttributeParameters(pPage2, "mHotelPhone", vHotelPhone, 10);
	Else
		SetAttributeParameters(pPage2, "mHotelPhone", StringToArray("", 10), 10);
	EndIf;
	
	// Check out date
	If ValueIsFilled(pRef.CheckOutDate) Then
		If ValueIsFilled(pRef.MigrationCardDateTo) Then
			vCheckOutDate = StringToArray(DateToString(pRef.MigrationCardDateTo), 8);
		Else
			vCheckOutDate = StringToArray(DateToString(pRef.CheckOutDate), 8);
		EndIf;
		SetAttributeParameters(pPage1, "mCheckOutDate", vCheckOutDate, 8);
		
		// Date when guest leaves the hotel
		If cmCheckUserPermissions("HavePermissionToPrintCheckOutDateInTheForeignerNotificationFormFooter") Then
			vDateTo = StringToArray(DateToString(pRef.CheckOutDate), 8);
			SetAttributeParameters(pPage2, "mDateTo", vDateTo, 8);
		Else
			SetAttributeParameters(pPage2, "mDateTo", StringToArray("", 8), 8);
		EndIf;
	Else
		SetAttributeParameters(pPage1, "mCheckOutDate", StringToArray("", 8), 8);
		SetAttributeParameters(pPage2, "mDateTo", StringToArray("", 8), 8);
	EndIf;

	// Employee that signes notification
	If ValueIsFilled(pEmployee) Then
		// Employee name
		vEmployeeLastName = StringToArray(pEmployee.LastName, 35);
		SetAttributeParameters(pPage2, "mEmployeeLastName", vEmployeeLastName, 35);
		vEmployeeName = StringToArray(TrimAll(pEmployee.FirstName) + " " + 
								      TrimAll(pEmployee.SecondName), 35);
		SetAttributeParameters(pPage2, "mEmployeeName", vEmployeeName, 35);
		
		// Employee date of birth
		vEmployeeDateOfBirth = StringToArray(DateToString(pEmployee.DateOfBirth), 8);
		SetAttributeParameters(pPage2, "mEmployeeBirthDate", vEmployeeDateOfBirth, 8);
		
		// Employee living address
		If Not IsBlankString(pEmployee.Address) Then
			vEmployeeAddress = cmParseAddress(pEmployee.Address);
		Else
			vEmployeeAddress = cmParseAddress(vHotelAddressStr);
		EndIf;
		
		vEmployeeAddressRegion = StringToArray(vEmployeeAddress.Region, 33);
		SetAttributeParameters(pPage2, "mEmployeeAddressRegion", vEmployeeAddressRegion, 33);
		
		vEmployeeAddressArea = StringToArray(vEmployeeAddress.Area, 35);
		SetAttributeParameters(pPage2, "mEmployeeAddressArea", vEmployeeAddressArea, 35);
		
		vEmployeeAddressCity = StringToArray(vEmployeeAddress.City, 33);
		SetAttributeParameters(pPage2, "mEmployeeAddressCity", vEmployeeAddressCity, 33);
		
		vEmployeeAddressStreet = StringToArray(vEmployeeAddress.Street, 35);
		SetAttributeParameters(pPage2, "mEmployeeAddressStreet", vEmployeeAddressStreet, 35);
		
		vHouse = TrimAll(vEmployeeAddress.House);
		vBuilding = "";
		vHouseBuilding = "";
		ParseHouseNumber(vHouse, vBuilding, vHouseBuilding);
		
		vEmployeeAddressHouse = StringToArray(vHouse, 4);
		SetAttributeParameters(pPage2, "mEmployeeAddressHouse", vEmployeeAddressHouse, 4);
		
		If Not IsBlankString(vBuilding) Then
			vEmployeeAddressBuilding = StringToArray(vBuilding, 4);
		Else
			vEmployeeAddressBuilding = StringToArray("", 4);
		EndIf;
		SetAttributeParameters(pPage2, "mEmployeeAddressBuilding", vEmployeeAddressBuilding, 4);
		
		If Not IsBlankString(vHouseBuilding) Then
			vEmployeeAddressHouseBuilding = StringToArray(vHouseBuilding, 4);
		Else
			vEmployeeAddressHouseBuilding = StringToArray("", 4);
		EndIf;
		SetAttributeParameters(pPage2, "mEmployeeAddressHouseBuilding", vEmployeeAddressHouseBuilding, 4);
		
		vEmployeeAddressFlat = StringToArray(vEmployeeAddress.Flat, 4);
		SetAttributeParameters(pPage2, "mEmployeeAddressFlat", vEmployeeAddressFlat, 4);
		
		// Employee identification document
		If Find(Upper(TrimAll(pEmployee.IdentityDocumentType)), "ПАСПОРТ") > 0 Then
			vEmployeeIDType = StringToArray("ПАСПОРТ", 11);
		Else
			vEmployeeIDType = StringToArray(pEmployee.IdentityDocumentType, 11);
		EndIf;
		SetAttributeParameters(pPage2, "mEmployeeIDType", vEmployeeIDType, 11);
		
		vEmployeeIDSeries = StringToArray(TrimAll(StrReplace(pEmployee.IdentityDocumentSeries, " ", "")), 4);
		SetAttributeParameters(pPage2, "mEmployeeIDSeries", vEmployeeIDSeries, 4);
		
		vEmployeeIDNumber = StringToArray(TrimAll(pEmployee.IdentityDocumentNumber), 9);
		SetAttributeParameters(pPage2, "mEmployeeIDNumber", vEmployeeIDNumber, 9);
		
		vEmployeeIDIssuedDate = StringToArray(DateToString(pEmployee.IdentityDocumentIssueDate), 8);
		SetAttributeParameters(pPage2, "mEmployeeIDIssuedDate", vEmployeeIDIssuedDate, 8);
		
		vEmployeeIDValidToDate = StringToArray(DateToString(pEmployee.IdentityDocumentValidToDate), 8);
		SetAttributeParameters(pPage2, "mEmployeeIDValidToDate", vEmployeeIDValidToDate, 8);
		
		// Employee phone
		If Not IsBlankString(pEmployee.Phones) Then
			vEmployeePhone = StringToArray(RemoveDelimeters(TrimAll(pEmployee.Phones)), 10);
		Else
			vEmployeePhone = StringToArray(vHotelPhoneStr, 10);
		EndIf;
		SetAttributeParameters(pPage2, "mEmployeePhone", vEmployeePhone, 10);
	Else // Employee is not selected, so fill all employee data with blanks except address and phone
		// Employee name
		SetAttributeParameters(pPage2, "mEmployeeLastName", StringToArray("", 35), 35);
		SetAttributeParameters(pPage2, "mEmployeeName", StringToArray("", 35), 35);
		
		// Employee date of birth
		SetAttributeParameters(pPage2, "mEmployeeBirthDate", StringToArray("", 8), 8);
		
		// Employee living address
		vEmployeeAddress = cmParseAddress(vHotelAddressStr);
		
		vEmployeeAddressRegion = StringToArray(vEmployeeAddress.Region, 33);
		SetAttributeParameters(pPage2, "mEmployeeAddressRegion", vEmployeeAddressRegion, 33);
		
		vEmployeeAddressArea = StringToArray(vEmployeeAddress.Area, 35);
		SetAttributeParameters(pPage2, "mEmployeeAddressArea", vEmployeeAddressArea, 35);
		
		vEmployeeAddressCity = StringToArray(vEmployeeAddress.City, 33);
		SetAttributeParameters(pPage2, "mEmployeeAddressCity", vEmployeeAddressCity, 33);
		
		vEmployeeAddressStreet = StringToArray(vEmployeeAddress.Street, 35);
		SetAttributeParameters(pPage2, "mEmployeeAddressStreet", vEmployeeAddressStreet, 35);
		
		vHouse = TrimAll(vEmployeeAddress.House);
		vBuilding = "";
		vHouseBuilding = "";
		ParseHouseNumber(vHouse, vBuilding, vHouseBuilding);
		
		vEmployeeAddressHouse = StringToArray(vHouse, 4);
		SetAttributeParameters(pPage2, "mEmployeeAddressHouse", vEmployeeAddressHouse, 4);
		
		If Not IsBlankString(vBuilding) Then
			vEmployeeAddressBuilding = StringToArray(vBuilding, 4);
		Else
			vEmployeeAddressBuilding = StringToArray("", 4);
		EndIf;
		SetAttributeParameters(pPage2, "mEmployeeAddressBuilding", vEmployeeAddressBuilding, 4);
		
		If Not IsBlankString(vHouseBuilding) Then
			vEmployeeAddressHouseBuilding = StringToArray(vHouseBuilding, 4);
		Else
			vEmployeeAddressHouseBuilding = StringToArray("", 4);
		EndIf;
		SetAttributeParameters(pPage2, "mEmployeeAddressHouseBuilding", vEmployeeAddressHouseBuilding, 4);
		
		vEmployeeAddressFlat = StringToArray(vEmployeeAddress.Flat, 4);
		SetAttributeParameters(pPage2, "mEmployeeAddressFlat", vEmployeeAddressFlat, 4);
		
		// Employee identification document
		SetAttributeParameters(pPage2, "mEmployeeIDType", StringToArray("", 11), 11);
		
		SetAttributeParameters(pPage2, "mEmployeeIDSeries", StringToArray("", 4), 4);
		
		SetAttributeParameters(pPage2, "mEmployeeIDNumber", StringToArray("", 9), 9);
		
		SetAttributeParameters(pPage2, "mEmployeeIDIssuedDate", StringToArray("", 8), 8);
		
		SetAttributeParameters(pPage2, "mEmployeeIDValidToDate", StringToArray("", 8), 8);
		
		// Employee phone
		vEmployeePhone = StringToArray(vHotelPhoneStr, 10);
		SetAttributeParameters(pPage2, "mEmployeePhone", vEmployeePhone, 10);
	EndIf;
	
	// Hotel address
	vCompanyAddress = StringToArray(cmGetAddressPresentation(vCompanyAddressStr), 52);
	SetAttributeParameters(pPage2, "mHotelAddress", vCompanyAddress, 52);
	
	// Migration office number
	pPage1.Parameters.mMigrationOfficeNumber = "";
	pPage2.Parameters.mMigrationOfficeNumber = "";
	pPage1.Parameters.mCheckInDate = '00010101';
	pPage2.Parameters.mCheckInDate = '00010101';
	If ValueIsFilled(pRef.Hotel) Then
		If Not IsBlankString(pRef.Hotel.MigrationOfficeNumber) Then
			pPage1.Parameters.mMigrationOfficeNumber = TrimAll(pRef.Hotel.MigrationOfficeNumber);
			pPage2.Parameters.mMigrationOfficeNumber = TrimAll(pRef.Hotel.MigrationOfficeNumber);
			
			pPage1.Parameters.mCheckInDate = pRef.CheckInDate;
			pPage2.Parameters.mCheckInDate = pRef.CheckInDate;
		EndIf;
	EndIf;
EndProcedure // SetParametersNotificationForPages20171123

// -----------------------------------------------------------------------------
Procedure SetParametersAddressSheetForPages(pPage11, pPage12, pPage2, pRef) Export
	// Try to fill guest data	
	If ValueIsFilled(pRef.Guest) Then
		// Guest name
		If IsBlankString(pRef.LastName) Then
			pPage11.Parameters.mGuestLastName = Upper(TrimAll(pRef.Guest.LastName));
			pPage11.Parameters.mGuestFirstName = Upper(TrimAll(pRef.Guest.FirstName));
			pPage11.Parameters.mGuestSecondName = Upper(TrimAll(pRef.Guest.SecondName));
		Else
			pPage11.Parameters.mGuestLastName = Upper(TrimAll(pRef.LastName));
			pPage11.Parameters.mGuestFirstName = Upper(TrimAll(pRef.FirstName));
			pPage11.Parameters.mGuestSecondName = Upper(TrimAll(pRef.SecondName));
		EndIf;
	Else // Guest is not selected, so fill all guest data with blanks
		// Guest name
		pPage11.Parameters.mGuestLastName = "";
		pPage11.Parameters.mGuestFirstName = "";
		pPage11.Parameters.mGuestSecondName = "";
	EndIf;
	
	// Guest citizenship
	pPage11.Parameters.mGuestCitizenship = Upper(TrimAll(pRef.Citizenship));
	
	// Guest date of birth
	vGuestDateOfBirth = DateToFormattedString(pRef.DateOfBirth);
	pPage11.Parameters.mGuestDayOfBirth = GetDay(vGuestDateOfBirth);
	pPage11.Parameters.mGuestMonthAndYearOfBirth = GetMonthYear(vGuestDateOfBirth);
	
	// Guest place of birth
	vGuestPlaceOfBirth = cmParseAddress(pRef.PlaceOfBirth);
	pPage11.Parameters.mGuestBirthPlaceCountry = Upper(vGuestPlaceOfBirth.Country);
	pPage11.Parameters.mGuestBirthPlaceRegion = Upper(vGuestPlaceOfBirth.Region);
	pPage11.Parameters.mGuestBirthPlaceArea = Upper(vGuestPlaceOfBirth.Area);
	vGuestBirthPlaceCity = TrimAll(vGuestPlaceOfBirth.City);
	If Find(Upper(vGuestBirthPlaceCity), "Г.") > 0 Then
		pPage11.Parameters.mGuestBirthPlaceCity = vGuestBirthPlaceCity;
		pPage11.Parameters.mGuestBirthPlaceTown = "";
	ElsIf Right(Upper(vGuestBirthPlaceCity), 2) = " Г" Then
		pPage11.Parameters.mGuestBirthPlaceCity = vGuestBirthPlaceCity;
		pPage11.Parameters.mGuestBirthPlaceTown = "";
	ElsIf Left(Upper(vGuestBirthPlaceCity), 2) = "Г " Then
		pPage11.Parameters.mGuestBirthPlaceCity = vGuestBirthPlaceCity;
		pPage11.Parameters.mGuestBirthPlaceTown = "";
	Else
		pPage11.Parameters.mGuestBirthPlaceCity = "";
		pPage11.Parameters.mGuestBirthPlaceTown = vGuestBirthPlaceCity;
	EndIf;
	
	// Guest check out date
	vCheckOutDate = DateToFormattedString(pRef.CheckOutDate);
	pPage12.Parameters.mCheckOutDay = GetDay(vCheckOutDate);
	pPage12.Parameters.mCheckOutMonth = GetMonth(vCheckOutDate);
	pPage12.Parameters.mCheckOutYear = GetYear(vCheckOutDate);
	
	// Hotel name and address
	If ValueIsFilled(pRef.Hotel) Then
		vHotel = pRef.Hotel;
		pPage12.Parameters.mHotelName = TrimAll(vHotel.PrintName);
		
		vAddress = cmParseAddress(vHotel.PostAddress);
		pPage12.Parameters.mAddressCountry = vAddress.Country;
		pPage12.Parameters.mAddressRegion = vAddress.Region;
		pPage12.Parameters.mAddressArea = vAddress.Area;
		vAddressCity = TrimAll(vAddress.City);
		If Find(Upper(vAddressCity), "Г.") > 0 Then
			pPage12.Parameters.mAddressCity = vAddressCity;
			pPage12.Parameters.mAddressTown = "";
		ElsIf Right(Upper(vAddressCity), 2) = " Г" Then
			pPage12.Parameters.mAddressCity = vAddressCity;
			pPage12.Parameters.mAddressTown = "";
		ElsIf Left(Upper(vAddressCity), 2) = "Г " Then
			pPage12.Parameters.mAddressCity = vAddressCity;
			pPage12.Parameters.mAddressTown = "";
		Else
			pPage12.Parameters.mAddressCity = "";
			pPage12.Parameters.mAddressTown = vAddressCity;
		EndIf;
		pPage12.Parameters.mAddressStreet = vAddress.Street;
		pPage12.Parameters.mAddressHouse = vAddress.House;
		pPage12.Parameters.mAddressBuilding = "";
		pPage12.Parameters.mAddressFlat = vAddress.Flat;
	Else
		pPage12.Parameters.mHotelName = "";
		
		pPage12.Parameters.mAddressCountry = "";
		pPage12.Parameters.mAddressRegion = "";
		pPage12.Parameters.mAddressArea = "";
		pPage12.Parameters.mAddressCity = "";
		pPage12.Parameters.mAddressTown = "";
		pPage12.Parameters.mAddressStreet = "";
		pPage12.Parameters.mAddressHouse = "";
		pPage12.Parameters.mAddressBuilding = "";
		pPage12.Parameters.mAddressFlat = "";
	EndIf;
	
	// Guest identification document
	If Find(Upper(TrimAll(pRef.IdentityDocumentType)), "ПАСПОРТ") > 0 Then
		vGuestIDType = "ПАСПОРТ РФ";
	Else
		vGuestIDType = Upper(TrimAll(pRef.IdentityDocumentType));
	EndIf;
	pPage12.Parameters.mGuestIDType = vGuestIDType;
	pPage12.Parameters.mGuestIDSeries = TrimAll(pRef.IdentityDocumentSeries);
	pPage12.Parameters.mGuestIDNumber = TrimAll(pRef.IdentityDocumentNumber);
	vGuestIDIssuedBy = TrimAll(pRef.IdentityDocumentIssuedBy);
	If StrLen(vGuestIDIssuedBy) > 18 Then
		pPage12.Parameters.mGuestIDIssuedBy1 = TrimAll(Left(vGuestIDIssuedBy, 18));
		pPage12.Parameters.mGuestIDIssuedBy2 = TrimAll(Mid(vGuestIDIssuedBy, 19));
	Else
		pPage12.Parameters.mGuestIDIssuedBy1 = vGuestIDIssuedBy;
		pPage12.Parameters.mGuestIDIssuedBy2 = "";
	EndIf;
	vGuestIDIssuedDate = DateToFormattedString(pRef.IdentityDocumentIssueDate);
	pPage12.Parameters.mGuestIDIssueDay = GetDay(vGuestIDIssuedDate);
	pPage12.Parameters.mGuestIDIssueMonth = GetMonth(vGuestIDIssuedDate);
	pPage12.Parameters.mGuestIDIssueYear = GetYear(vGuestIDIssuedDate);
	
	
	// Guest check in date
	vCheckInDate = DateToFormattedString(pRef.CheckInDate);
	pPage2.Parameters.mCheckInDay = GetDay(vCheckInDate);
	pPage2.Parameters.mCheckInMonth = GetMonth(vCheckInDate);
	pPage2.Parameters.mCheckInYear = GetYear(vCheckInDate);
	
	// Arrived from address
	vArrivedFromAddress = cmParseAddress(TrimAll(pRef.ArrivedFrom));
	pPage2.Parameters.mArrivedFromCountry = vArrivedFromAddress.Country;
	pPage2.Parameters.mArrivedFromRegion = vArrivedFromAddress.Region;
	pPage2.Parameters.mArrivedFromArea = vArrivedFromAddress.Area;
	vArrivedFromCity = TrimAll(vArrivedFromAddress.City);
	If Find(Upper(vArrivedFromCity), "Г.") > 0 Then
		pPage2.Parameters.mArrivedFromCity = vArrivedFromCity;
		pPage2.Parameters.mArrivedFromTown = "";
	ElsIf Right(Upper(vArrivedFromCity), 2) = " Г" Then
		pPage2.Parameters.mArrivedFromCity = vArrivedFromCity;
		pPage2.Parameters.mArrivedFromTown = "";
	ElsIf Left(Upper(vArrivedFromCity), 2) = "Г " Then
		pPage2.Parameters.mArrivedFromCity = vArrivedFromCity;
		pPage2.Parameters.mArrivedFromTown = "";
	Else
		pPage2.Parameters.mArrivedFromCity = "";
		pPage2.Parameters.mArrivedFromTown = vArrivedFromCity;
	EndIf;
	pPage2.Parameters.mArrivedFromStreet = vArrivedFromAddress.Street;
	pPage2.Parameters.mArrivedFromHouse = vArrivedFromAddress.House;
	pPage2.Parameters.mArrivedFromBuilding = "";
	pPage2.Parameters.mArrivedFromFlat = vArrivedFromAddress.Flat;
EndProcedure // SetParametersForPages

// -----------------------------------------------------------------------------
Function pmGetImageCatalogName(pDocRef) Export
	If Not ValueIsFilled(pDocRef.Hotel) Then
		Raise NStr("en='Hotel is not filled! ';ru='У документа не заполнена гостиница! ';de='Bei dem Dokument ist das Hotel nicht eingetragen! '") + pDocRef;
	EndIf;
	vBLOBRootFolder = TrimAll(pDocRef.Hotel.BLOBRootFolder);
	vNonReplicatingAttributes = pDocRef.Hotel.GetObject().pmGetNonReplicatingAttributes();
	If vNonReplicatingAttributes.Count() > 0 Then
		vBLOBRootFolder = TrimAll(vNonReplicatingAttributes.Get(0).BLOBRootFolder);
	EndIf;
	vDelimeter = "\";
	If Find(vBLOBRootFolder, "/") > 0 Then
		vDelimeter = "/";
	EndIf;
	If Right(vBLOBRootFolder, 1) <> vDelimeter Then
		vBLOBRootFolder = vBLOBRootFolder + vDelimeter;
	EndIf;
	rCatalogName = vBLOBRootFolder + "ClientDataScans" + vDelimeter + TrimAll(pDocRef.Number) + "_" + Format(pDocRef.Date, "DF=yyyy-MM-dd") + vDelimeter;
	Return rCatalogName;
EndFunction // pmGetImageCatalogName

// -----------------------------------------------------------------------------
Function pmGetClientDataScansDocument(pDocRef) Export
	vDoc = Undefined;
	// Run query to check whether client data scans were already created
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ClientDataScans.Ref AS Ref
	|FROM
	|	Document.ClientDataScans AS ClientDataScans
	|WHERE
	|	ClientDataScans.Posted
	|	AND ClientDataScans.ParentDoc = &qParentDoc";
	vQry.SetParameter("qParentDoc", pDocRef.ParentDoc);
	vDocs = vQry.Execute().Unload();
	If vDocs.Count() > 0 Then
		vDoc = vDocs.Get(0).Ref;
	ElsIf ValueIsFilled(pDocRef.Guest) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT TOP 1
		|	ClientDataScans.Ref AS Ref
		|FROM
		|	Document.ClientDataScans AS ClientDataScans
		|WHERE
		|	ClientDataScans.Posted
		|	AND ClientDataScans.Guest = &qClient
		|
		|ORDER BY
		|	ClientDataScans.Date DESC";
		vQry.SetParameter("qClient", pDocRef.Guest);
		vDocs = vQry.Execute().Unload();
		If vDocs.Count() > 0 Then
			vDoc = vDocs.Get(0).Ref;
		EndIf;
	EndIf;
	Return vDoc;
EndFunction // pmGetClientDataScansDocument

#EndRegion       

#Region Private

// -----------------------------------------------------------------------------
Function GetDay(pDateStr)
	If pDateStr <> "" Then
		Return Left(pDateStr, 2);
	Else
		Return "";
	EndIf;	
EndFunction // GetDay

// -----------------------------------------------------------------------------
Function GetMonth(pDateStr)
	If pDateStr <> "" Then
		Return Mid(pDateStr, 4, StrLen(pDateStr) - 11);
	Else
		Return "";
	EndIf;	
EndFunction // GetMonth

// -----------------------------------------------------------------------------
Function GetMonthYear(pDateStr)
	If pDateStr <> "" Then
		Return Mid(pDateStr, 4, StrLen(pDateStr) - 6);
	Else
		Return "";
	EndIf;	
EndFunction // GetMonthYear

// -----------------------------------------------------------------------------
Function GetYear(pDateStr)
	If pDateStr <> "" Then
		Return Left(Right(pDateStr, 7), 4);
	Else
		Return "";
	EndIf;	
EndFunction // GetYear

// -----------------------------------------------------------------------------
Function DateToFormattedString(pDate)
	If Not ValueIsFilled(pDate) Then
		Return "";
	Else
		vDate = Format(pDate, "L=ru_RU; DLF=DD");
		If Day(pDate) < 10 Then
			vDate = "0" + vDate;
		EndIf;
		Return vDate;
	EndIf;
EndFunction // DateToFormattedString

// -----------------------------------------------------------------------------
Function DateToString(pDate)
	If Not ValueIsFilled(pDate) Then
		Return "";
	Else
		Return Format(pDate, "DF=ddMMyyyy");
	EndIf;
EndFunction // DateToString

// -----------------------------------------------------------------------------
Procedure SetAttributeParameters(pPage1, pAttrName, pArray, pMaxChars)
	For i = 1 To pMaxChars Do
		pPage1.Parameters[pAttrName + String(i)] = pArray[i - 1];
	EndDo;
EndProcedure // SetAttributeParameters

// -----------------------------------------------------------------------------
Procedure SetParameters(pPage,pRef)
	// Hotel name and address
	If ValueIsFilled(pRef.Hotel) Then
		vHotel = pRef.Hotel;
		pPage.Parameters.mHotelName = cmNStr(vHotel.PrintName, Catalogs.Languages.RU);
	Else
		pPage.Parameters.mHotelName = "";
	EndIf;
	
	// Try to fill guest data	
	If ValueIsFilled(pRef.Guest) Then
		pPage.Parameters.mGuestFullName = TrimAll(TrimAll(pRef.LastName) + " " + TrimAll(pRef.FirstName) + " " + TrimAll(pRef.SecondName));
	Else // Guest is not selected, so fill all guest data with blanks
		pPage.Parameters.mGuestFullName = "";
	EndIf;
	
	// Guest date of birth
	If ValueIsFilled(pRef.DateOfBirth) Then
		pPage.Parameters.mDateOfBirth = Format(pRef.DateOfBirth, "DF=dd.MM.yyyy");
	Else
		pPage.Parameters.mDateOfBirth = "";
	EndIf;
	
	// Guest citizenship
	pPage.Parameters.mCitizenship = TrimAll(pRef.Citizenship);
	
	// Guest identification document
	pPage.Parameters.mGuestID = TrimAll(TrimAll(pRef.IdentityDocumentSeries) + " " + TrimAll(pRef.IdentityDocumentNumber));
	
	// Arrived from
	pPage.Parameters.mArrivedFrom = TrimAll(pRef.ArrivedFrom);
	
	// Check point number
	pPage.Parameters.mCheckPointNumber = TrimAll(pRef.CheckPointNumber);
	
	// Border crossing date
	If ValueIsFilled(pRef.BorderCrossingDate) Then
		pPage.Parameters.mBorderCrossingDate = Format(pRef.BorderCrossingDate, "DF=dd.MM.yyyy");
	Else
		pPage.Parameters.mBorderCrossingDate = "";
	EndIf;
	
	// Receiving party
	pPage.Parameters.mReceivingParty1 = Left(TrimAll(pRef.ReceivingParty), 40);
	pPage.Parameters.mReceivingParty2 = Mid(TrimAll(pRef.ReceivingParty), 41);
	
	// Visa
	If Not IsBlankString(pRef.VisaNumber) Then
		pPage.Parameters.mVisaData1 = TrimAll(TrimAll(pRef.VisaType) + " №" + TrimAll(pRef.VisaNumber) + ", действует до " + 
		                              ?(ValueIsFilled(pRef.VisaToDate), Format(pRef.VisaToDate, "DF=dd.MM.yyyy"), ""));
		pPage.Parameters.mVisaData2 = "";
	Else
		pPage.Parameters.mVisaData1 = "";
		pPage.Parameters.mVisaData2 = "";
	EndIf;
	
	// Route
	pPage.Parameters.mRoute = TrimAll(pRef.Route);

	// Period of stay
	If ValueIsFilled(pRef.CheckInDate) And ValueIsFilled(pRef.CheckOutDate) Then
		pPage.Parameters.mPeriodOfStay = Format(pRef.CheckInDate, "DF=dd.MM.yyyy") + " по " + Format(pRef.CheckOutDate, "DF=dd.MM.yyyy");
	Else
		pPage.Parameters.mPeriodOfStay = "";
	EndIf;

	// Room
	If ValueIsFilled(pRef.Room) Then
		pPage.Parameters.mRoom = TrimAll(pRef.Room);
	Else
		pPage.Parameters.mRoom = "";
	EndIf;
	
	// Guest check out date
	pPage.Parameters.mCheckOutDate = "";

	// Remarks
	If Not IsBlankString(pRef.Remarks) Then
		pPage.Parameters.mRemarks1 = TrimAll(pRef.Remarks);
		pPage.Parameters.mRemarks2 = "";
		pPage.Parameters.mRemarks3 = "";
	Else
		pPage.Parameters.mRemarks1 = "";
		pPage.Parameters.mRemarks2 = "";
		pPage.Parameters.mRemarks3 = "";
	EndIf;
EndProcedure // SetParameters

// -----------------------------------------------------------------------------
Function StringToArray(pStr, pMaxChars = 35)
	vArray = New Array;
	vStr = Upper(TrimAll(pStr));
	i = 0;
	While i < StrLen(vStr) Do
		i = i + 1;		
		vArray.Add(Mid(vStr, i, 1));
	EndDo;
	// Fill array to the pMaxChars elements with blanks
	While i < pMaxChars Do
		i = i + 1;
		vArray.Add("");
	EndDo;
	Return vArray;
EndFunction // StringToArray

// -----------------------------------------------------------------------------
Procedure SeriesAndNumberToArray(pStr, pMaxCharsSeries = 4, pMaxCharsNumber = 35, rSeriesArray, rNumberArray)
	rSeriesArray = StringToArray("", pMaxCharsSeries);
	rNumberArray = StringToArray("", pMaxCharsNumber);
	vNumber = Upper(TrimAll(pStr));
	vNumberLen = StrLen(vNumber);
	i = 1;
	j = 1;
	vIsSeries = False;
	If Find(vNumber, " ") > 0 Then
		vIsSeries = True;
	EndIf;
	While i <= vNumberLen Do
		vChar = Mid(vNumber, i, 1);
		If vChar = " " Then
			If vIsSeries Then
				vIsSeries = False;
			EndIf;
			i = i + 1;
			Continue;
		EndIf;
		If vIsSeries Then
			If i <= pMaxCharsSeries Then
				rSeriesArray[i-1] = vChar;
			EndIf;
		Else
			If j <= pMaxCharsNumber Then
				rNumberArray[j-1] = vChar;
			EndIf;
			j = j + 1;
		EndIf;
		i = i + 1;
	EndDo;
EndProcedure // SeriesAndNumberToArray

// -----------------------------------------------------------------------------
Procedure ParseHouseNumber(vHouse, vBuilding, vHouseBuilding)
	vHouseStr = TrimAll(vHouse);
	vHouse = TrimAll(vHouse);
	vBuilding = "";
	vHouseBuilding = "";
	vBlankPos = Find(vHouse, " ");
	If vBlankPos > 0 Then
		vHouse = TrimAll(Left(vHouseStr, vBlankPos - 1));
		vBuilding = TrimAll(Mid(vHouseStr, vBlankPos + 1));
		If Not IsBlankString(vBuilding) Then
			vBuilding = StrReplace(vBuilding, "корп.", "");
			vBuilding = StrReplace(vBuilding, "Корп.", "");
			vBuilding = StrReplace(vBuilding, "корп", "");
			vBuilding = StrReplace(vBuilding, "Корп", "");
			vBuilding = StrReplace(vBuilding, "кор", "");
			vBuilding = StrReplace(vBuilding, "Кор", "");
			vBuilding = StrReplace(vBuilding, "к", "");
			vBuilding = StrReplace(vBuilding, "К", "");
			vBuilding = StrReplace(vBuilding, "b", "");
			vBuilding = StrReplace(vBuilding, "B", "");
			vBuilding = TrimAll(vBuilding);
			vBlankPos = Find(vBuilding, " ");
			If vBlankPos > 0 Then
				vBuildingStr = vBuilding;
				vBuilding = TrimAll(Left(vBuildingStr, vBlankPos - 1));
				vHouseBuilding = TrimAll(Mid(vBuildingStr, vBlankPos + 1));
				If Not IsBlankString(vHouseBuilding) Then
					vHouseBuilding = StrReplace(vHouseBuilding, "стр.", "");
					vHouseBuilding = StrReplace(vHouseBuilding, "Стр.", "");
					vHouseBuilding = StrReplace(vHouseBuilding, "стр", "");
					vHouseBuilding = StrReplace(vHouseBuilding, "Стр", "");
					vHouseBuilding = StrReplace(vHouseBuilding, "с", "");
					vHouseBuilding = StrReplace(vHouseBuilding, "С", "");
					vHouseBuilding = TrimAll(vHouseBuilding);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ParseHouseNumber

// -----------------------------------------------------------------------------
Procedure ParseHouseAndBuilding(vHouse, vBuilding)
	vHouseStr = TrimAll(vHouse);
	vHouseStr = StrReplace(vHouseStr, "д. ", "");
	vHouseStr = StrReplace(vHouseStr, "д.", "");
	vHouseStr = StrReplace(vHouseStr, "д ", ""); 
	vHouseStr = StrReplace(vHouseStr, "д", "");
	vHouseStr = StrReplace(vHouseStr, "Д. ", "");
	vHouseStr = StrReplace(vHouseStr, "Д.", "");
	vHouseStr = StrReplace(vHouseStr, "Д ", "");
	vHouseStr = StrReplace(vHouseStr, "Д", ""); 
	vHouseStr = StrReplace(vHouseStr, "Дом ", "");
	vHouseStr = StrReplace(vHouseStr, "Дом", "");  
	vHouseStr = StrReplace(vHouseStr, "дом ", "");
	vHouseStr = StrReplace(vHouseStr, "дом", "");

	vBuilding = "";
	vBlankPos = Find(vHouseStr, " ");
	If vBlankPos > 0 Then
		vHouse = TrimAll(Left(vHouseStr, vBlankPos - 1));
		vBuilding = TrimAll(Mid(vHouseStr, vBlankPos + 1));
	EndIf;
EndProcedure // ParseHouseAndBuilding

// -----------------------------------------------------------------------------
Function RemoveDelimeters(pStr)
	vStr = StrReplace(pStr, " ", "");
	vStr = StrReplace(vStr, " ", "");
	vStr = StrReplace(vStr, "8 (", "");
	vStr = StrReplace(vStr, "8(", "");
	vStr = StrReplace(vStr, "+7", "");
	vStr = StrReplace(vStr, "+", "");
	vStr = StrReplace(vStr, "(", "");
	vStr = StrReplace(vStr, ")", "");
	vStr = StrReplace(vStr, "-", "");
	vStr = StrReplace(vStr, ",", "");
	vStr = StrReplace(vStr, ".", "");
	Return vStr;
EndFunction // RemoveDelimeters

// -----------------------------------------------------------------------------
Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	vRef = Data.Ref;
	If ValueIsFilled(vRef) and ValueIsFilled(vRef.Guest) Then
		Presentation = NStr("en = 'Notification'; ru = 'Уведомление'; de = 'Mitteilung'") + 
		?(ValueIsFilled(vRef.Guest), " " + Trimall(vRef.Guest.FullName), "") + 
		NStr("en = ' from '; ru = ' c '; de = ' ab '") + Format(vRef.CheckInDate, "DF=dd.MM.yyyy") + 
		?(ValueIsFilled(vRef.Room), " " + TrimAll(vRef.Room), "") + 
		" №" + TrimAll(Data.Number);
		StandardProcessing = False;
	EndIf;
EndProcedure

#EndRegion
