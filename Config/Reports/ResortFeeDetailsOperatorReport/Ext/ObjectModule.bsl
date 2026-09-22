// -----------------------------------------------------------------------------
// Reports framework start
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure pmSaveReportAttributes(pGenerateOnly = False) Export
	cmSaveReportAttributes(ThisObject, , pGenerateOnly);
EndProcedure // pmSaveReportAttributes

// -----------------------------------------------------------------------------
Procedure pmLoadReportAttributes(pParameter = Undefined) Export
	cmLoadReportAttributes(ThisObject, pParameter);
EndProcedure // pmLoadReportAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill parameters with default values
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(Company) Then
		If ValueIsFilled(Hotel) Then
			Company = Hotel.Company;
		EndIf;
	EndIf;
	If Not ValueIsFilled(PeriodFrom) Then
		PeriodFrom = BegOfMonth(BegOfMonth(CurrentSessionDate()) - 1);
		PeriodTo = EndOfMonth(PeriodFrom);
	EndIf;
	If IsBlankString(SupplementText) Then
		SupplementText = "Министру курортов, туризма и олимпийского наследия Краснодарского края <ФИО>";
	EndIf;
	If IsBlankString(OperatorName) And Not IsBlankString(Company) Then
		OperatorName = Company.GetObject().pmGetCompanyPrintName(Catalogs.Languages.RU);
	EndIf;
	If IsBlankString(ObjectName) And Not IsBlankString(Hotel) Then
		ObjectName = Hotel.GetObject().pmGetHotelPrintName(Catalogs.Languages.RU);
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If Not ValueIsFilled(PeriodFrom) And Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("en='Report period is not set';ru='Период отчета не установлен';de='Berichtszeitraum nicht festgelegt'") + 
		                     ";" + Chars.LF;
	ElsIf ValueIsFilled(PeriodFrom) And Not ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период c '; en = 'Period from '; de = 'Periode von '") + 
		                     Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm:ss'") + 
		                     ";" + Chars.LF;
	ElsIf Not ValueIsFilled(PeriodFrom) And ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период по '; en = 'Period to '; de = 'Periode zu '") + 
		                     Format(PeriodTo, "DF='dd.MM.yyyy HH:mm:ss'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom = PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период на '; en = 'Period on '; de = 'Periode '") + 
		                     Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm:ss'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom < PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период '; en = 'Period '; de = 'Periode '") + PeriodPresentation(BegOfDay(PeriodFrom), EndOfDay(PeriodTo), cmLocalizationCode()) + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("en='Period is wrong!';ru='Неправильно задан период!';de='Der Zeitraum wurde falsch eingetragen!'") + 
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(Company) Then
		vParamPresentation = vParamPresentation + NStr("en='Company ';ru='Фирма ';de='Kompanie '") + 
		                     TrimAll(Company.Description) + 
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(RoomsFolder) Then
		If ExcludingRoomsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Rooms not in ';ru='Номера не из ';de='Zimmern nicht aus '") + 
			                     TrimAll(RoomsFolder) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Rooms in ';ru='Номера из ';de='Zimmern aus '") + 
			                     TrimAll(RoomsFolder) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If Not Hotel.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Hotel ';ru='Гостиница ';de='Hotel '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц ';de='Hotelsgruppe '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	Return vParamPresentation;
EndFunction // pmGetReportParametersPresentation

// -----------------------------------------------------------------------------
Procedure pmGenerate(pSpreadsheet) Export
	// Fill and check grouping parameter
	pSpreadsheet.Clear();
	
	vTemplateName = "Template";
	vTemplate = ThisObject.GetTemplate(vTemplateName);	
	
	vPrintStruct = New Structure();
	vPrintStruct.Insert("INN", TrimAll(Company.TIN));
	vPrintStruct.Insert("OperatorName", TrimAll(OperatorName));	
	vPrintStruct.Insert("ObjectName", TrimAll(ObjectName));
	vPrintStruct.Insert("TerritoryMO", TrimAll(TerritoryMO)); 
	vPrintStruct.Insert("Month", PeriodPresentation(BegOfDay(PeriodFrom), EndOfDay(PeriodTo), cmLocalizationCode()));
	vPrintStruct.Insert("OperatorNameAndINN", TrimAll(Company.TIN) + ", " + TrimAll(ThisObject.OperatorName));
	vPrintStruct.Insert("Role", Nstr(TrimAll(Company.DirectorPosition)));
	
	vHeader = vTemplate.GetArea("Header");
	FillPropertyValues(vHeader.Parameters, vPrintStruct);
	pSpreadsheet.Put(vHeader);

	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	Guests.Remarks AS Remarks,
	|	Guests.Sales AS Sales,
	|	Guests.FirstName AS FirstName,
	|	Guests.SecondName AS SecondName,
	|	Guests.Phone AS Phone,
	|	Guests.DateOfBirth AS DateOfBirth,
	|	Guests.Age AS Age,
	|	Guests.ClientIdentityDocumentSeries AS ClientIdentityDocumentSeries,
	|	Guests.ClientIdentityDocumentNumber AS ClientIdentityDocumentNumber,
	|	Guests.ClientIdentityDocumentIssueDate AS ClientIdentityDocumentIssueDate,
	|	Guests.ClientIdentityDocumentIssuedBy AS ClientIdentityDocumentIssuedBy,
	|	Guests.ClientAddress AS ClientAddress,
	|	Guests.CheckInDate AS CheckInDate,
	|	Guests.CheckOutDate AS CheckOutDate,
	|	Guests.LastName AS LastName
	|FROM
	|	(SELECT
	|		CAST(SalesMovements.Recorder.Remarks AS STRING(1024)) AS Remarks,
	|		SUM(SalesMovements.Sales) AS Sales,
	|		SalesMovements.ParentDoc.Guest.FirstName AS FirstName,
	|		SalesMovements.ParentDoc.Guest.SecondName AS SecondName,
	|		SalesMovements.ParentDoc.Guest.LastName AS LastName,
	|		SalesMovements.ParentDoc.Guest.Phone AS Phone,
	|		ISNULL(SalesMovements.ParentDoc.Guest.DateOfBirth, &qEmptyDate) AS DateOfBirth,
	|		ISNULL(SalesMovements.ParentDoc.Guest.Age, 0) AS Age,
	|		SalesMovements.ParentDoc.Guest.IdentityDocumentSeries AS ClientIdentityDocumentSeries,
	|		SalesMovements.ParentDoc.Guest.IdentityDocumentNumber AS ClientIdentityDocumentNumber,
	|		SalesMovements.ParentDoc.Guest.IdentityDocumentIssueDate AS ClientIdentityDocumentIssueDate,
	|		SalesMovements.ParentDoc.Guest.IdentityDocumentIssuedBy AS ClientIdentityDocumentIssuedBy,
	|		CAST(SalesMovements.ParentDoc.Guest.Address AS STRING(1024)) AS ClientAddress,
	|		SalesMovements.ParentDoc.CheckInDate AS CheckInDate,
	|		SalesMovements.ParentDoc.CheckOutDate AS CheckOutDate
	|	FROM
	|		AccumulationRegister.Sales AS SalesMovements
	|	WHERE
	|		NOT SalesMovements.IsCorrection
	|		AND SalesMovements.Service = &qService
	|		AND (NOT &qHotelIsFilled
	|				OR &qHotelIsFilled
	|					AND SalesMovements.Hotel = &qHotel)
	|		AND (NOT &qCompanyIsFilled
	|				OR &qCompanyIsFilled
	|					AND SalesMovements.Company = &qCompany)
	|		AND (NOT &qAgentIsFilled
	|				OR &qAgentIsFilled
	|					AND SalesMovements.Agent <> &qAgent)
	|		AND ISNULL(SalesMovements.ParentDoc.CheckOutDate, &qEmptyDate) >= &qPeriodFrom
	|		AND ISNULL(SalesMovements.ParentDoc.CheckOutDate, &qEmptyDate) <= &qPeriodTo
	|		AND SalesMovements.Recorder REFS Document.Charge
	|		AND NOT SalesMovements.Recorder IN
	|					(SELECT
	|						Stornos.ParentCharge
	|					FROM
	|						Document.Storno AS Stornos
	|					WHERE
	|						Stornos.Posted)
	|		AND (&qRoomsFromFolder AND SalesMovements.Room IN HIERARCHY(&qRoomsFolder) OR
	|			 &qExcludingRoomsFromFolder AND NOT SalesMovements.Room IN HIERARCHY(&qRoomsFolder) OR
	|			 NOT &qRoomsFromFolder AND NOT &qExcludingRoomsFromFolder)
	|	
	|	GROUP BY
	|		CAST(SalesMovements.Recorder.Remarks AS STRING(1024)),
	|		SalesMovements.ParentDoc.Guest.FirstName,
	|		SalesMovements.ParentDoc.Guest.SecondName,
	|		SalesMovements.ParentDoc.Guest.LastName,
	|		SalesMovements.ParentDoc.Guest.Phone,
	|		ISNULL(SalesMovements.ParentDoc.Guest.DateOfBirth, &qEmptyDate),
	|		ISNULL(SalesMovements.ParentDoc.Guest.Age, 0),
	|		SalesMovements.ParentDoc.Guest.IdentityDocumentSeries,
	|		SalesMovements.ParentDoc.Guest.IdentityDocumentNumber,
	|		SalesMovements.ParentDoc.Guest.IdentityDocumentIssueDate,
	|		SalesMovements.ParentDoc.Guest.IdentityDocumentIssuedBy,
	|		CAST(SalesMovements.ParentDoc.Guest.Address AS STRING(1024)),
	|		SalesMovements.ParentDoc.CheckInDate,
	|		SalesMovements.ParentDoc.CheckOutDate) AS Guests
	|
	|ORDER BY
	|	FirstName,
	|	CheckInDate";
	vQuery.SetParameter("qEmptyDate", Date(1,1,1));
	vQuery.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQuery.SetParameter("qPeriodTo",  EndOfDay(PeriodTo));
	vQuery.SetParameter("qService", Service);
	vQuery.SetParameter("qHotel", Hotel);
	vQuery.SetParameter("qHotelIsFilled", ValueIsFilled(Hotel));
	vQuery.SetParameter("qCompany", Company);
	vQuery.SetParameter("qCompanyIsFilled", ValueIsFilled(Company));
	vQuery.SetParameter("qAgent", Agent);
	vQuery.SetParameter("qAgentIsFilled", ValueIsFilled(Agent));
	vQuery.SetParameter("qRoomsFolder", RoomsFolder);
	vRoomsFromFolder = False;
	vExcludingRoomsFromFolder = False;
	If ValueIsFilled(RoomsFolder) Then
		If ExcludingRoomsFolder Then
			vExcludingRoomsFromFolder = True;
		Else
			vRoomsFromFolder = True;
		EndIf;
	EndIf;
	vQuery.SetParameter("qRoomsFromFolder", vRoomsFromFolder);
	vQuery.SetParameter("qExcludingRoomsFromFolder", vExcludingRoomsFromFolder);
	vQueryResult = vQuery.Execute();
	vTrans = vQueryResult.Select();
	
	While vTrans.Next() Do
		vParamStr = new Structure;
		vParamStr.Insert("mLastName", TrimAll(vTrans.LastName));
		vParamStr.Insert("mSecondName", TrimAll(vTrans.SecondName));
		vParamStr.Insert("mFirstName", TrimAll(vTrans.FirstName));
		vParamStr.Insert("mDateOfBirth", Format(vTrans.DateOfBirth,"DF=dd.MM.yyyy"));
		vParamStr.Insert("mAdress		", "");
		vParamStr.Insert("mIDSeries", TrimAll(vTrans.ClientIdentityDocumentSeries));
		vParamStr.Insert("mIDNumber", TrimAll(vTrans.ClientIdentityDocumentNumber));
		vParamStr.Insert("mIDIssuedBy", TrimAll(vTrans.ClientIdentityDocumentIssuedBy));
		vParamStr.Insert("mIDIssueDate", Format(vTrans.ClientIdentityDocumentIssueDate,"DF=dd.MM.yyyy"));
		vParamStr.Insert("mPhone", TrimAll(vTrans.Phone));
		vParamStr.Insert("mCheckInDate", Format(vTrans.CheckInDate,"DF=dd.MM.yyyy"));
		vParamStr.Insert("mCheckOutDate", Format(vTrans.CheckOutDate,"DF=dd.MM.yyyy"));
		vParamStr.Insert("mSum", Format(vTrans.Sales, "ND=17; NFD=2"));
		vParamStr.Insert("mCategory", "");
		vParamStr.Insert("mIsAdult", ?(vTrans.DateOfBirth <> '00010101' AND vTrans.Age < 18, False, True));
		
		vResertStr = TrimAll(vTrans.Remarks);
		If vResertStr = "Отказ от уплаты курортного сбора" Then
			vParamStr.Insert("mRefusal", "Отказ");
		ElsIf vResertStr = "Житель домашнего региона" Then
			vParamStr.mCategory = "20";
		Else	 
			vParamStr.mCategory = Left(vResertStr, StrFind(vResertStr, ".")-1);
		EndIf;
		
		// Guest address
		vGuestAddress = cmParseAddress(vTrans.ClientAddress);

		vParamStr.mAdress = cmGetAddressPresentation(" " + vGuestAddress.PostCode + ", " + vGuestAddress.Region)+
				cmGetAddressPresentation(", " + vGuestAddress.Area + ", " + vGuestAddress.City + ", " + 
				vGuestAddress.Street + ", " + vGuestAddress.House + ", " + vGuestAddress.Flat);
				
		vStr = vTemplate.GetArea("Str");
		FillPropertyValues(vStr.Parameters, vParamStr);
		pSpreadsheet.Put(vStr);
	EndDo;           
	
	vFooter = vTemplate.GetArea("Footer");
	FillPropertyValues(vFooter.Parameters, vPrintStruct);
	pSpreadsheet.Put(vFooter);

	// Setup default attributes
	cmSetDefaultPrintFormSettings(pSpreadsheet, PageOrientation.Landscape, True);
	// Check authorities
	cmSetSpreadsheetProtection(pSpreadsheet);	
EndProcedure // pmPrint
