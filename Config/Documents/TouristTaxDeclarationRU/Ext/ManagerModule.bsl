
#Region Public

// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Hotel, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

// --------------------------------------------------------------------------------
Procedure PrintDeclaration(pSpreadsheet, pDeclaration, pLanguage, pPrintForm, pTaxAgency, pByLocationOfAccounting,
                           pDistrictName, pDistrictType, pSettlementName, pSettlementType, pCityName,pCityType,pPlanName, pPlanType,  pNetName , pNetType,
                           pLandNum, pHouse1Name, pHouse1Type, pHouse2Name, pHouse2Type, pHouse3Name, pHouse3Type, pRoomName, pRoomType) Export
	// Clear form
	pSpreadsheet.Clear();

	// Basic checks
	If Not ValueIsFilled(pDeclaration) Then 
		Raise NStr("en='No declaration to print selected!'; ru='Не выбрана декларация для печати!'; de='Keine Deklaration zum Drucken ausgewählt!'"); 
	EndIf;
	If Not ValueIsFilled(pPrintForm) Then
		Raise NStr("en='No declaration print form selected!'; ru='Не выбрана печатная форма объекта декларации!'; de='Die gedruckte Form des Deklarationsobjekts ist nicht ausgewählt!'"); 
	EndIf;
	vHotel = pDeclaration.Hotel;
	If Not ValueIsFilled(vHotel) Then
		Raise NStr("en='Failed to get declaration hotel!'; ru='Не удалось определить гостиницу декларации!'; de='Hotel-Deklaration konnte nicht ermittelt werden!'"); 
	EndIf;
	vCompany = pDeclaration.Company;
	If Not ValueIsFilled(vCompany) Then
		Raise NStr("en='Failed to get declaration company!'; ru='Не удалось определить юридическое лицо гостиницы!'; de='Die juristische Person des Hotels konnte nicht ermittelt werden!'"); 
	EndIf;
	vLanguage = pLanguage;
	If Not ValueIsFilled(vLanguage) Then
		vLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	
	// Choose template
	vDeclarationObject = pDeclaration.GetObject();
	vTemplate = vDeclarationObject.GetTemplate("Declaration");
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(pPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;
	
	// ------------------------ Section 0 
	vSection0 = vTemplate.GetArea("Section0");
	
	vCompanyTIN = StringToArray(TrimAll(vCompany.TIN), 12);
	SetAttributeParameters(vSection0, "mCompanyTIN", vCompanyTIN, 12);
	
	vCompanyKPP = StringToArray(TrimAll(vCompany.KPP), 9);
	SetAttributeParameters(vSection0, "mCompanyKPP", vCompanyKPP, 9);  
	
	If BegOfQuarter(pDeclaration.DateFrom) = BegOfQuarter(pDeclaration.DateTo) Then
		vTaxPeriod = Month(EndOfQuarter(pDeclaration.DateFrom))/3;
		vTaxPeriodStr = StringToArray("2"+String(vTaxPeriod), 2);
		SetAttributeParameters(vSection0, "mTaxPeriod", vTaxPeriodStr, 2); 
	EndIf;
	
	vCorrectionNumber = StringToArray(TrimAll(Format(pDeclaration.CorrectionNumber, "ND=3; NFD=0; NG=0")), 3);
	SetAttributeParameters(vSection0, "mCorrectionNumber", vCorrectionNumber, 3);   
	
	vAccountingYear = StringToArray(TrimAll(Format(Year(pDeclaration.DateTo),"NG=0")), 4);
	SetAttributeParameters(vSection0, "mAccountingYear", vAccountingYear, 4);   
	
	vTaxAgencyStr = StringToArray(TrimAll(pTaxAgency), 4);
	SetAttributeParameters(vSection0, "mTaxAgency", vTaxAgencyStr, 4);  

	vByLocationOfAccountingStr = StringToArray(TrimAll(pByLocationOfAccounting), 3);
	SetAttributeParameters(vSection0, "mByLocationOfAccounting", vByLocationOfAccountingStr, 3);  
	
	vCompanyPrintName = StringToArray(StrReplace(TrimAll(vCompany.LegacyName),"""",""), 160);
	SetAttributeParameters(vSection0, "mCompanyPrintName", vCompanyPrintName, 160);   
	
    vCompanyPhone = StringToArray(TrimAll(vCompany.Phones), 20);
	SetAttributeParameters(vSection0, "mCompanyPhone", vCompanyPhone, 20);      

	vCompanyDirector = cmNStr(vCompany.Director, pLanguage);
    vCompanyDirectorStr = StringToArray(TrimAll(vCompanyDirector), 60);
	SetAttributeParameters(vSection0, "mFullNameTaxpayer", vCompanyDirectorStr, 60); 
	
	vDate = StringToArray(DateToString(CurrentSessionDate()), 8);
	SetAttributeParameters(vSection0, "mDate", vDate, 8);

	
	// ------------------------ Section 1 
	vSection1 = vTemplate.GetArea("Section1");

	SetAttributeParameters(vSection1, "mCompanyTIN", vCompanyTIN, 12);
	SetAttributeParameters(vSection1, "mCompanyKPP", vCompanyKPP, 9);   
	
	vKBK = StringToArray(TrimAll(vCompany.KBK), 20);
	SetAttributeParameters(vSection1, "mKBKCode", vKBK, 20);  
	
	vOKTMO = StringToArray(TrimAll(vCompany.OKTMO), 11);
	SetAttributeParameters(vSection1, "mOKTMOcode", vOKTMO, 11);  

	vSection1.Parameters.mCurrentDate = Format(CurrentSessionDate(), "DF=dd.MM.yyyy");
	
	
	vSection2Page2Array = New Array(); 
	
	// Get all combinations of tax rate and minimum tax amount. 
	// For each combination we will print separate page
	vPageDimensions = vDeclarationObject.Reservations.Unload(, "TouristTaxRate, MinAmountPerDay");
	vPageDimensions.GroupBy("TouristTaxRate, MinAmountPerDay", );
	
	
	// ------------------------ Section 2 - page 1 
	vSection2Page1 = vTemplate.GetArea("Section2Page1");

	SetAttributeParameters(vSection2Page1, "mCompanyTIN", vCompanyTIN, 12);
	SetAttributeParameters(vSection2Page1, "mCompanyKPP", vCompanyKPP, 9);  
	
	vRegistryNumber = StringToArray(TrimAll(vHotel.RegistryNumber), 13);
	SetAttributeParameters(vSection2Page1, "mRegistryNumber", vRegistryNumber, 13);

	vHotelPrintName = Catalogs.Hotels.pmGetHotelPrintName(vHotel, pLanguage);
	vHotelPrintNameStr = StringToArray(TrimAll(vHotelPrintName), 64);
	SetAttributeParameters(vSection2Page1, "mHotelPrintName", vHotelPrintNameStr, 64);

	vRegionCode = "";
	If ValueIsFilled(vHotel.Region) Then
		vRegionCode = vHotel.Region.Code;
	EndIf;
	vRegionStr = StringToArray(TrimAll(vRegionCode), 2);
	SetAttributeParameters(vSection2Page1, "mRegion", vRegionStr, 2);   
	
	vDistrictName = StringToArray(TrimAll(pDistrictName), 57);
	SetAttributeParameters(vSection2Page1, "mDistrictName", vDistrictName, 57);
	
	vDistrictType = StringToArray(TrimAll(pDistrictType), 1);
	SetAttributeParameters(vSection2Page1, "mDistrictType", vDistrictType, 1);
	
	vSettlementName = StringToArray(TrimAll(pSettlementName), 57);
	SetAttributeParameters(vSection2Page1, "mSettlementName", vSettlementName, 57);
	
	vSettlementType = StringToArray(TrimAll(pSettlementType), 1);
	SetAttributeParameters(vSection2Page1, "mSettlementType", vSettlementType, 1);

	vCityName = StringToArray(TrimAll(pCityName), 50);
	SetAttributeParameters(vSection2Page1, "mCityName", vCityName, 50);
	
	vCityType = StringToArray(TrimAll(pCityType), 10);
	SetAttributeParameters(vSection2Page1, "mCityType", vCityType, 10);

	vPlanName = StringToArray(TrimAll(pPlanName), 97);
	SetAttributeParameters(vSection2Page1, "mPlanName", vPlanName, 97);
	
	vPlanType = StringToArray(TrimAll(pPlanType), 10);
	SetAttributeParameters(vSection2Page1, "mPlanType", vPlanType, 10);

	vNetName = StringToArray(TrimAll(pNetName), 97);
	SetAttributeParameters(vSection2Page1, "mNetName", vNetName, 97);
	
	vNetType = StringToArray(TrimAll(pNetType), 10);
	SetAttributeParameters(vSection2Page1, "mNetType", vNetType, 10);

	vLandNum = StringToArray(TrimAll(pLandNum), 17);
	SetAttributeParameters(vSection2Page1, "mLandNum", vLandNum, 17);
	
	vHouse1Name = StringToArray(TrimAll(pHouse1Name), 17);
	SetAttributeParameters(vSection2Page1, "mHouse1Name", vHouse1Name, 17);

	vHouse1Type = StringToArray(TrimAll(pHouse1Type), 11);
	SetAttributeParameters(vSection2Page1, "mHouse1Type", vHouse1Type, 11);
	
	vHouse2Name = StringToArray(TrimAll(pHouse2Name), 17);
	SetAttributeParameters(vSection2Page1, "mHouse2Name", vHouse2Name, 17);

	vHouse2Type = StringToArray(TrimAll(pHouse2Type), 11);
	SetAttributeParameters(vSection2Page1, "mHouse2Type", vHouse2Type, 11);
	
	vHouse3Name = StringToArray(TrimAll(pHouse3Name), 17);
	SetAttributeParameters(vSection2Page1, "mHouse3Name", vHouse3Name, 17);

	vHouse3Type = StringToArray(TrimAll(pHouse3Type), 11);
	SetAttributeParameters(vSection2Page1, "mHouse3Type", vHouse3Type, 11);

	vRoomName = StringToArray(TrimAll(pRoomName), 17);
	SetAttributeParameters(vSection2Page1, "mRoomName", vRoomName, 17);
	
	vRoomType = StringToArray(TrimAll(pRoomType), 11);
	SetAttributeParameters(vSection2Page1, "mRoomType", vRoomType, 11);
	
	vCategory = "";
	If ValueIsFilled(vHotel.Category) Then 
		If vHotel.Category = Enums.HotelCategory.OneStar Then
			vCategory = "1";
		ElsIf vHotel.Category = Enums.HotelCategory.TwoStar Then
			vCategory = "2";
		ElsIf vHotel.Category = Enums.HotelCategory.ThreeStars Then
			vCategory = "3";
		ElsIf vHotel.Category = Enums.HotelCategory.FourStars Then
			vCategory = "4";
		ElsIf vHotel.Category = Enums.HotelCategory.FiveStars Then
			vCategory = "5";
		Else
			vCategory = "";
        EndIf;
	EndIf;
	vCategoryStr = StringToArray(TrimAll(vCategory), 1);
	SetAttributeParameters(vSection2Page1, "mCategory", vCategoryStr, 1);    
	
	SetAttributeParameters(vSection2Page1, "mKBKCode", vKBK, 20);  
	SetAttributeParameters(vSection2Page1, "mOKTMOcode", vOKTMO, 11);  

	vSection2Page1.Parameters.mCurrentDate = Format(CurrentSessionDate(), "DF=dd.MM.yyyy");


	vPageCount = 3;

	// Do for each combination found
	vTaxAmountAll = 0;  
    vPageNumber = 0;

	For Each vPageDimensionsRow In vPageDimensions Do
		// ------------------------ Section 2 - page 2
		vSection2Page2 = vTemplate.GetArea("Section2Page2");
		
		vPageNumber = vPageNumber + 1;   

		vSection2Page2.PutHorizontalPageBreak();

		SetAttributeParameters(vSection2Page2, "mCompanyTIN", vCompanyTIN, 12);
		SetAttributeParameters(vSection2Page2, "mCompanyKPP", vCompanyKPP, 9);  
    	SetAttributeParameters(vSection2Page1, "mRegistryNumber", vRegistryNumber, 13);

		vPage2Number = StringToArray(TrimAll(Format(vPageNumber + vPageCount, "ND=3; NFD=0; NZ=; NLZ=; NG=")), 3);
		SetAttributeParameters(vSection2Page2, "mPage2Number", vPage2Number, 3);

		vTaxRateFormat = StrReplace(TrimAll(Format(vPageDimensionsRow.TouristTaxRate, "NFD=2; NDS=.; NZ=; NG=")), ".", "");
		vTaxRate = StringToArray(vTaxRateFormat, 3);
		SetAttributeParameters(vSection2Page2, "mTaxRate", vTaxRate, 3);   
		
		vSection2Page2.Parameters.mCurrentDate = Format(CurrentSessionDate(), "DF=dd.MM.yyyy");

		vTotalAmount = 0;
		vExemptionAmount = 0;
		vExemptionGuests = 0;
		vExemptionRegionalAmount = 0;
		vExemptionRegionalGuests = 0;
		vMinRateAmount = 0;
		vTaxRateBaseAmount = 0;
		vTaxAmountByRate = 0;
		vTaxAmountMin = 0;
		vTaxAmountExemption = 0;
		vPaidTaxAmount = 0;
		vTaxAmount = 0;

		// Select deccalration rows for the given combination of minimum amount per day and tax rate
		vPageRows = vDeclarationObject.Reservations.FindRows(New Structure("TouristTaxRate, MinAmountPerDay", vPageDimensionsRow.TouristTaxRate, vPageDimensionsRow.MinAmountPerDay));
		vGuestsCount = vPageRows.Count();
		For Each vPageRow In vPageRows Do
			vRowTaxBaseAmount = vPageRow.TaxBaseAmount;

			vTotalAmount = vTotalAmount + vRowTaxBaseAmount;
			
			If ValueIsFilled(vPageRow.TouristicTaxExemptionReason) Then
				If vPageRow.TouristicTaxExemptionReason.IsRegionLevelReason Then
					vExemptionRegionalAmount = vExemptionRegionalAmount + vRowTaxBaseAmount;
					vExemptionRegionalGuests = vExemptionRegionalGuests + 1;    
				Else			
					vExemptionAmount = vExemptionAmount + vRowTaxBaseAmount;
					vExemptionGuests = vExemptionGuests + 1;  
				EndIf; 
				vTaxAmountExemption = vTaxAmountExemption + vPageRow.TaxAmount;
			Else
				If vPageRow.TouristicTaxIsByMinAmount Then
					vMinRateAmount = vMinRateAmount + vRowTaxBaseAmount;
					vTaxAmountMin = vTaxAmountMin + vPageRow.TaxAmount;
				Else
					vTaxRateBaseAmount = vTaxRateBaseAmount + vRowTaxBaseAmount;
					vTaxAmountByRate = vTaxAmountByRate + vPageRow.TaxAmount;
				EndIf;
            EndIf;
			
			vPaidTaxAmount = vPaidTaxAmount + vPageRow.PaidTaxAmount;
		EndDo;
		vTaxAmountByRate = Round(vTaxRateBaseAmount * vPageDimensionsRow.TouristTaxRate / 100, 0, 1);
		vTaxAmount = vTaxAmountByRate + Round(vTaxAmountMin, 0, 1) - Round(vPaidTaxAmount, 0, 1);
		
		// ------------------------ Section 2 - page 2
		SetAttributeParameters(vSection2Page2, "mRegistryNumber", vRegistryNumber, 13);

		vTotalAmountStr = SumToArray(TrimAll(Format(Round(vTotalAmount,0,1), "NZ=; NG=")), 15);
		SetAttributeParameters(vSection2Page2, "mTotalAmount", vTotalAmountStr, 15);      
		
		vGuestCountStr = SumToArray(TrimAll(Format(vGuestsCount, "NFD=0; NZ=; NG=")), 15);
		SetAttributeParameters(vSection2Page2, "mGuestCount", vGuestCountStr, 15); 
		
		vExemptionAmountStr = SumToArray(TrimAll(Format(Round(vExemptionAmount,0,1), "NZ=; NG=")), 15);
		SetAttributeParameters(vSection2Page2, "mExemptionAmount", vExemptionAmountStr, 15);

		vExemptionGuestsStr = SumToArray(TrimAll(Format(vExemptionGuests, "NFD=0; NZ=; NG=")), 6);
		SetAttributeParameters(vSection2Page2, "mExemptionGuests", vExemptionGuestsStr, 6);
		
		vExemptionRegionalAmountStr = SumToArray(TrimAll(Format(Round(vExemptionRegionalAmount,0,1), "NZ=; NG=")), 15);
		SetAttributeParameters(vSection2Page2, "mExemptionRegionalAmount", vExemptionRegionalAmountStr, 15);

		vExemptionRegionalGuestsStr = SumToArray(TrimAll(Format(vExemptionRegionalGuests, "NFD=0; NZ=; NG=")), 6);
		SetAttributeParameters(vSection2Page2, "mExemptionRegionalGuests", vExemptionRegionalGuestsStr, 6); 
		
		vMinRateAmountStr = SumToArray(TrimAll(Format(Round(vMinRateAmount,0,1), "NZ=; NG=")), 15);
		SetAttributeParameters(vSection2Page2, "mMinRateAmount", vMinRateAmountStr, 15);    
		
		vTaxRateBaseAmountStr = SumToArray(TrimAll(Format(Round(vTaxRateBaseAmount,0,1), "NZ=; NG=")), 15);
		SetAttributeParameters(vSection2Page2, "mTaxRateBaseAmount", vTaxRateBaseAmountStr, 15); 
		
		vTaxAmountByRateStr = SumToArray(TrimAll(Format(Round(vTaxAmountByRate,0,1), "NZ=; NG=")), 15);
		SetAttributeParameters(vSection2Page2, "mTaxAmountByRate", vTaxAmountByRateStr, 15); 
		
		vTaxAmountMinStr = SumToArray(TrimAll(Format(Round(vTaxAmountMin,0,1), "NZ=; NG=")), 15);
		SetAttributeParameters(vSection2Page2, "mTaxAmountMin", vTaxAmountMinStr, 15);
		
		vTaxAmountExemptionStr = SumToArray(TrimAll(Format(Round(vPaidTaxAmount,0,1), "NZ=; NG=")), 15);
		SetAttributeParameters(vSection2Page2, "mTaxAmountExemption", vTaxAmountExemptionStr, 15);
		
		vTaxAmountStr = SumToArray(TrimAll(Format(Round(vTaxAmount, 0, 1), "NZ=; NG=")), 15);
		SetAttributeParameters(vSection2Page2, "mTaxAmount", vTaxAmountStr, 15); 
		
		vTaxAmountAll = vTaxAmountAll + vTaxAmount;
		
		vSection2Page2Array.Add(vSection2Page2);
	EndDo;
	
	vPageCountStr = SumToArray(TrimAll(Format(vPageCount + vPageNumber, "NFD=0; NG=")), 3);
	SetAttributeParameters(vSection0, "mPageCount", vPageCountStr, 3); 

	pSpreadsheet.Put(vSection0);
	pSpreadsheet.PutHorizontalPageBreak();

	// ------------------------ Section 1 
	vTaxAmountAllStr = SumToArray(TrimAll(Format(Round(vTaxAmountAll,0,1), "NZ=; NG=")), 15);
	SetAttributeParameters(vSection1, "mTaxAmount", vTaxAmountAllStr, 15); 

	pSpreadsheet.Put(vSection1);  
	pSpreadsheet.PutHorizontalPageBreak();

	pSpreadsheet.Put(vSection2Page1);  
	pSpreadsheet.PutHorizontalPageBreak();  
	
	For Each vArea In vSection2Page2Array Do
		pSpreadsheet.Put(vArea);
	EndDo;

	cmSetDefaultPrintFormSettings(pSpreadsheet, PageOrientation.Portrait, True, , True);  
	pSpreadsheet.TopMargin = 5; 
	pSpreadsheet.LeftMargin = 5;
	pSpreadsheet.RightMargin = 5;
	pSpreadsheet.BottomMargin = 0;

	cmSetSpreadsheetProtection(pSpreadsheet);
EndProcedure // pmPrintDeclaration

// --------------------------------------------------------------------------------
Procedure PrintDetailingDeclaration(pSpreadsheet, pDeclaration, pLanguage, pPrintForm) Export
	// Clear form
	pSpreadsheet.Clear();

	// Basic checks
	If Not ValueIsFilled(pDeclaration) Then 
		Raise NStr("en='No declaration to print selected!'; ru='Не выбрана декларация для печати!'; de='Keine Deklaration zum Drucken ausgewählt!'"); 
	EndIf;
	If Not ValueIsFilled(pPrintForm) Then
		Raise NStr("en='No declaration print form selected!'; ru='Не выбрана печатная форма объекта декларации!'; de='Die gedruckte Form des Deklarationsobjekts ist nicht ausgewählt!'"); 
	EndIf;
	vHotel = pDeclaration.Hotel;
	If Not ValueIsFilled(vHotel) Then
		Raise NStr("en='Failed to get declaration hotel!'; ru='Не удалось определить гостиницу декларации!'; de='Hotel-Deklaration konnte nicht ermittelt werden!'"); 
	EndIf;
	vCompany = pDeclaration.Company;
	If Not ValueIsFilled(vCompany) Then
		Raise NStr("en='Failed to get declaration company!'; ru='Не удалось определить юридическое лицо гостиницы!'; de='Die juristische Person des Hotels konnte nicht ermittelt werden!'"); 
	EndIf;
	vLanguage = pLanguage;
	If Not ValueIsFilled(vLanguage) Then
		vLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	
	// Choose template
	vDeclarationObject = pDeclaration.GetObject();
	vTemplate = vDeclarationObject.GetTemplate("DetailingDeclarationRU");
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(pPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;

	vTop = vTemplate.GetArea("Top");   
	vTop.Parameters.mFilters = GetReportParametersPresentation(pDeclaration); 
	pSpreadsheet.Put(vTop);
	
	vRes = pDeclaration.Reservations;
	
	vTaxAmountToBePaidAll = 0;
	i = 0;
	For Each vResRow In vRes Do
        i = i + 1;

		vRow = vTemplate.GetArea("Row");   
		vRow.Parameters.mNum = i;
		vRow.Parameters.mGuestGroup = vResRow.GuestGroup;  
		If ValueIsFilled(vResRow.GuestGroup) Then
			vRow.Parameters.mGuestGroupRef = vResRow.GuestGroup.Ref;
        EndIf;
		vRow.Parameters.mTouristicTaxDate = Format(vResRow.TouristicTaxDate, "DF=dd.MM.yyyy");
		If ValueIsFilled(vResRow.Reservation) Then
			vRow.Parameters.mReservationNumber = vResRow.Reservation.Number;
			vRow.Parameters.mReservationRef = vResRow.Reservation.Ref;
			If ValueIsFilled(vResRow.Reservation.Guest) Then
				vRow.Parameters.mReservationGuest = vResRow.Reservation.Guest.FullName;
			EndIf;
		EndIf;
		vRow.Parameters.mCheckInDate = Format(vResRow.CheckInDate, "DF=dd.MM.yyyy");	
		vRow.Parameters.mDurationInDays = vResRow.DurationInDays;	
		vRow.Parameters.mCheckOutDate = Format(vResRow.CheckOutDate, "DF=dd.MM.yyyy");	
		vRow.Parameters.mRateAmount = Format(vResRow.RateAmount, "NFD=2; NZ=0,00");	
		vRow.Parameters.mTaxBaseAmount =  Format(vResRow.TaxBaseAmount, "NFD=2; NZ=0,00");  	
		vRow.Parameters.mTouristicTaxExemptionReason = vResRow.TouristicTaxExemptionReason;	
		vRow.Parameters.mTaxAmount =  Format(vResRow.TaxAmount, "NFD=2; NZ=0,00");  	
		vRow.Parameters.mPaidTaxAmount = Format(vResRow.PaidTaxAmount, "NFD=2; NZ=0,00"); 	
		vRow.Parameters.mTaxAmountToBePaid = Format(vResRow.TaxAmountToBePaid, "NFD=2; NZ=0,00");  	
		vTaxAmountToBePaidAll = vTaxAmountToBePaidAll + vResRow.TaxAmountToBePaid; 
		vRow.Parameters.mTouristTaxRate =  Format(vResRow.TouristTaxRate, "NFD=2; NZ=0,00");
		vRow.Parameters.mMinAmountPerDay = Format(vResRow.MinAmountPerDay, "NFD=2; NZ=0,00");	
		vRow.Parameters.mTouristicTaxIsByMinAmount = vResRow.TouristicTaxIsByMinAmount;

		pSpreadsheet.Put(vRow);
	EndDo;

	vBottom = vTemplate.GetArea("Bottom"); 
	vBottom.Parameters.mTaxAmountToBePaid = Format(vTaxAmountToBePaidAll, "NFD=2; NZ=0,00");  	
	pSpreadsheet.Put(vBottom);
	
	cmSetDefaultPrintFormSettings(pSpreadsheet, PageOrientation.Landscape, True, , True);  
	pSpreadsheet.TopMargin = 10; 
	pSpreadsheet.LeftMargin = 10;
	pSpreadsheet.RightMargin = 5;
	pSpreadsheet.BottomMargin = 5;

	cmSetSpreadsheetProtection(pSpreadsheet);
EndProcedure // pmPrintDeclaration

// -----------------------------------------------------------------------------
Function GetReportParametersPresentation(pDeclaration)
	vParamPresentation = "";
	If Not ValueIsFilled(pDeclaration.DateFrom) And Not ValueIsFilled(pDeclaration.DateTo) Then
		vParamPresentation = vParamPresentation + NStr("en='Report period is not set';ru='Период отчета не установлен';de='Berichtszeitraum nicht festgelegt'") + 
		                     ";" + Chars.LF;
	ElsIf ValueIsFilled(pDeclaration.DateFrom) And Not ValueIsFilled(pDeclaration.DateTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период c '; en = 'Period from '; de = 'Periode von '") + 
		                     Format(pDeclaration.DateFrom, "DF=dd.MM.yyyy") + 
		                     ";" + Chars.LF;
	ElsIf Not ValueIsFilled(pDeclaration.DateFrom) And ValueIsFilled(pDeclaration.DateTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период по '; en = 'Period to '; de = 'Periode zu '") + 
		                     Format(pDeclaration.DateTo, "DF=dd.MM.yyyy") + 
		                     ";" + Chars.LF;
	ElsIf pDeclaration.DateFrom = pDeclaration.DateTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период на '; en = 'Period on '; de = 'Periode '") + 
		                     Format(pDeclaration.DateFrom, "DF=dd.MM.yyyy") + 
		                     ";" + Chars.LF;
	ElsIf pDeclaration.DateFrom < pDeclaration.DateTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период '; en = 'Period '; de = 'Periode '") + Format(pDeclaration.DateFrom, "DF=dd.MM.yyyy") + "-"+Format(pDeclaration.DateTo, "DF=dd.MM.yyyy") +
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("en='Period is wrong!';ru='Неправильно задан период!';de='Der Zeitraum wurde falsch eingetragen!'") + 
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(pDeclaration.Hotel) Then
		If Not pDeclaration.Hotel.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Hotel ';ru='Гостиница ';de='Hotel '") + 
			                     pDeclaration.Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц ';de='Hotelsgruppe '") + 
			                     pDeclaration.Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     TrimAll(pDeclaration.Hotel.Description) + ";" + Chars.LF;
		EndIf;
	EndIf;
	Return vParamPresentation;
EndFunction //GetReportParametersPresentation

// -----------------------------------------------------------------------------
Procedure SetAttributeParameters(pPage1, pAttrName, pArray, pMaxChars)
	For i = 1 To pMaxChars Do
		pPage1.Parameters[pAttrName+String(i)] = pArray[i-1];
	EndDo;
EndProcedure // SetAttributeParameters

// -----------------------------------------------------------------------------
Function DateToString(pDate)
	If Not ValueIsFilled(pDate) Then
		Return "";
	Else
		Return Format(pDate, "DF=ddMMyyyy");
	EndIf;
EndFunction // DateToString

// -----------------------------------------------------------------------------
Function StringToArray(pStr, pMaxChars=40)
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
		vArray.Add(" ");
	EndDo;
	Return vArray;
EndFunction // StringToArray

// -----------------------------------------------------------------------------
Function SumToArray(pStr, pMaxChars=40)
	vArray = New Array;
	vStr = Upper(TrimAll(pStr));  
	vEmpty = pMaxChars - StrLen(vStr); 
	// Fill array to the pMaxChars elements with blanks
	i = 0;
	While i < vEmpty Do
		i = i + 1;
		vArray.Add(" ");
	EndDo;

	While i < pMaxChars Do
		i = i + 1;		
		vArray.Add(Mid(vStr, i - vEmpty, 1));
	EndDo;
	Return vArray;
EndFunction // StringToArray

// --------------------------------------------------------------------------------
Procedure RecalculateTouristTax(pStartDate = '20250101', pEndDate = '39991231', pHotel = Undefined, pCompany = Undefined) Export
	// Table of edit prohibited dates to restore
	vHotels = New ValueTable();
	vHotels.Columns.Add("Hotel", cmGetCatalogTypeDescription("Hotels"));
	vHotels.Columns.Add("EditProhibitedDate", cmGetDateTypeDescription());
	
	// List of hotels to skip
	vHotelsToSkip = New ValueList();
	
	// Get documents to process
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodations.Ref AS Ref,
	|	Accommodations.GuestGroup.Code AS GuestGroupCode,
	|	Accommodations.Number AS DocumentNumber,
	|	Accommodations.AccommodationType.SortCode AS AccommodationTypeSortCode
	|FROM
	|	Document.Accommodation AS Accommodations
	|WHERE
	|	Accommodations.Posted
	|	AND (Accommodations.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (Accommodations.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|	AND Accommodations.AccommodationStatus.IsActive
	|	AND (Accommodations.CheckOutDate > &qStartDate
	|				AND Accommodations.CheckInDate < &qEndDate
	|			OR Accommodations.TouristicTaxAccountingDate >= &qStartDate
	|				AND Accommodations.TouristicTaxAccountingDate <= &qEndDate)
	|
	|UNION ALL
	|
	|SELECT
	|	Reservations.Ref,
	|	Reservations.GuestGroup.Code,
	|	Reservations.Number,
	|	Reservations.AccommodationType.SortCode
	|FROM
	|	Document.Reservation AS Reservations
	|WHERE
	|	Reservations.Posted
	|	AND (Reservations.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (Reservations.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|	AND (Reservations.ReservationStatus.IsActive
	|			OR Reservations.ReservationStatus.IsPreliminary)
	|	AND (Reservations.CheckOutDate > &qStartDate
	|				AND Reservations.CheckInDate < &qEndDate
	|			OR Reservations.TouristicTaxAccountingDate >= &qStartDate
	|				AND Reservations.TouristicTaxAccountingDate <= &qEndDate)
	|
	|ORDER BY
	|	GuestGroupCode,
	|	DocumentNumber,
	|	AccommodationTypeSortCode DESC";
	vQry.SetParameter("qStartDate", BegOfDay(pStartDate));
	vQry.SetParameter("qEndDate", EndOfDay(pEndDate));
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(pHotel));
	vQry.SetParameter("qCompany", pCompany);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(pCompany));
	vDocs = vQry.Execute().Unload();
	For Each vDocsRow In vDocs Do
		vDocObj = vDocsRow.Ref.GetObject();

		vHotel = vDocObj.Hotel;
		// Check if tourist tax was setup earlier
		If vHotelsToSkip.FindByValue(vHotel) <> Undefined Then
			Continue;
		EndIf;
		vTouristicTaxAccountingDate = vDocObj.TouristicTaxAccountingDate;
		If Not ValueIsFilled(vTouristicTaxAccountingDate) Then
			vTouristicTaxAccountingDate = BegOfDay(vDocObj.CheckOutDate);
		EndIf;
		vTTSettings = cmGetTouristTaxSettings(vHotel, vTouristicTaxAccountingDate); 
		If vTTSettings.Count() = 0 Then
			vHotelsToSkip.Add(vHotel);
			Continue;
		EndIf;
		// Reset hotel edit is prohibited date
		If ValueIsFilled(vHotel.EditProhibitedDate) Then
			If vHotels.Find(vHotel, "Hotel") = Undefined Then
				vHotelsRow = vHotels.Add();
				vHotelsRow.Hotel = vHotel;
				vHotelsRow.EditProhibitedDate = vHotel.EditProhibitedDate;
				
				vHotelObj = vHotel.GetObject();
				vHotelObj.EditProhibitedDate = '00010101';
				vHotelObj.Write();
			EndIf;
		EndIf;
		
		// Fill tourist tax date
		If Not ValueIsFilled(vDocObj.TouristicTaxAccountingDate) Then
			vDocObj.TouristicTaxAccountingDate = vTouristicTaxAccountingDate;
		EndIf;
		// Check tourist tax settings
		If ValueIsFilled(vHotel.TouristTaxService) Or 
		   ValueIsFilled(vDocObj.RoomRate) And ValueIsFilled(vDocObj.RoomRate.TouristTaxService) Then
			// Recalculate services
			vDocObj.pmCalculateServices();
		Else
			// Calculate room rate amount in base currency and duration in days
			vDocObj.pmCalculateRateAmountAndDurationInDays();
			// Process tourist tax if neccessary
			vDocObj.pmCalculateTouristTax();
		EndIf;
		// Post document
		vDocObj.AdditionalProperties.Insert("InfoBaseUpdateMode", True);
		vDocObj.Write(DocumentWriteMode.Posting);
		If TypeOf(vDocObj) = Type("DocumentObject.Accommodation") Then
			vDocObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		Else
			vDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		EndIf;
	EndDo;
	
	// Restore eddit prohibited date
	For Each vHotelsRow In vHotels Do
		vHotelObj = vHotelsRow.Hotel.GetObject();
		vHotelObj.EditProhibitedDate = vHotelsRow.EditProhibitedDate;
		vHotelObj.Write();
	EndDo;
EndProcedure // RecalculateTouristTax

#EndRegion
