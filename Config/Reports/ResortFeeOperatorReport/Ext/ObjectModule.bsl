
#Region Public

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
		PeriodFrom = BegOfQuarter(BegOfQuarter(CurrentSessionDate())-1);;
		PeriodTo = EndOfQuarter(PeriodFrom);
	EndIf;
	If Not ValueIsFilled(PeriodTo) Then
		PeriodTo = EndOfQuarter(PeriodFrom);
	EndIf;
	If IsBlankString(SupplementText) Then
		SupplementText = "Министерство курортов, туризма и олимпийского наследия Краснодарского края";
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
		                     Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm'") + 
		                     ";" + Chars.LF;
	ElsIf Not ValueIsFilled(PeriodFrom) And ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период по '; en = 'Period to '; de = 'Periode zu '") + 
		                     Format(PeriodTo, "DF='dd.MM.yyyy HH:mm'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom = PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период на '; en = 'Period on '; de = 'Periode '") + 
		                     Format(PeriodFrom, "DF='dd.MM.yyyy HH:mm'") + 
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
	If IsBlankString(RegionOfPrintForm) Then
		Return;
	EndIf;	
	vTemplateName = "Template"+RegionOfPrintForm;
	vTemplate = ThisObject.GetTemplate(vTemplateName);
	
	//Fill spreadsheet document
	If RegionOfPrintForm = "AK" Then // Алтайский край
		PrintReportForAK(vTemplate, pSpreadsheet);
	ElsIf RegionOfPrintForm = "KK" Then // Краснодарский край - рай)
		PrintReportForKK(vTemplate, pSpreadsheet);
	ElsIf RegionOfPrintForm = "SPB" Then // Saint - Petersburg)
		PrintReportForSPB(vTemplate, pSpreadsheet);
	Else
		PrintReportForKK(vTemplate, pSpreadsheet);
	EndIf;		
		
	// Setup default attributes
	cmSetDefaultPrintFormSettings(pSpreadsheet, PageOrientation.Landscape, True);
	// Check authorities
	cmSetSpreadsheetProtection(pSpreadsheet);	
EndProcedure // pmPrint

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure PrintReportForKK(pTemplate, pSpreadsheet)
	vReport = pTemplate.GetArea("Report");

	vPrintStruct = New Structure();
	vPrintStruct.Insert("INN", TrimAll(Company.TIN));
	vPrintStruct.Insert("OperatorName", TrimAll(OperatorName));	
	vPrintStruct.Insert("ObjectName", TrimAll(ObjectName));
	vPrintStruct.Insert("TerritoryMO", TrimAll(TerritoryMO)); 
	vPrintStruct.Insert("mPeriod", PeriodPresentation(BegOfDay(PeriodFrom), EndOfDay(PeriodTo), cmLocalizationCode()));
	vPrintStruct.Insert("OperatorNameAndINN", TrimAll(Company.TIN) + ", " + TrimAll(ThisObject.OperatorName));
	vPrintStruct.Insert("SupplementText", TrimAll(SupplementText));
	vPrintStruct.Insert("Role", TrimAll(Nstr(Company.DirectorPosition)));
	vPrintStruct.Insert("FullName", Nstr(Company.Director));
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	Guests.Remarks AS Remarks,
	|	SUM(Guests.NumberOfGuests) AS NumberOfGuests,
	|	SUM(Guests.Sales) AS Sales
	|FROM
	|	(SELECT
	|		CAST(SalesMovements.Recorder.Remarks AS STRING(1024)) AS Remarks,
	|		SalesMovements.ParentDoc AS ParentDoc,
	|		MAX(SalesMovements.NumberOfPersons) AS NumberOfGuests,
	|		SUM(SalesMovements.Sales) AS Sales
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
	|		AND (&qRoomsFromFolder
	|					AND SalesMovements.Room IN HIERARCHY (&qRoomsFolder)
	|				OR &qExcludingRoomsFromFolder
	|					AND NOT SalesMovements.Room IN HIERARCHY (&qRoomsFolder)
	|				OR NOT &qRoomsFromFolder
	|					AND NOT &qExcludingRoomsFromFolder)
	|	
	|	GROUP BY
	|		CAST(SalesMovements.Recorder.Remarks AS STRING(1024)),
	|		SalesMovements.ParentDoc) AS Guests
	|
	|GROUP BY
	|	Guests.Remarks";
	vQuery.SetParameter("qEmptyDate", Date(1, 1, 1));
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
	vUnload = vQueryResult.Unload();
	
	vAll = 0;
	vGuestPay = 0;	
	vGuestNotPay = 0;	
	vAllowedNotPay = 0;	  
	For Each vRow In vUnload Do
		vAll = vAll + vRow.NumberOfGuests; 
		If vRow.Remarks = "" Then
			vGuestPay = vGuestPay + vRow.NumberOfGuests;
			vPrintStruct.Insert("AllPaymentGuest", vRow.NumberOfGuests);
		ElsIf vRow.Remarks = "Лицо не достигшее 18 лет" Or vRow.Remarks = "Срок проживания менее суток" Then
			If vPrintStruct.Property("pAge18") Then
				vPrintStruct.pAge18 = vPrintStruct.pAge18 + vRow.NumberOfGuests;
			Else
				vPrintStruct.Insert("pAge18", vRow.NumberOfGuests);	
			EndIf;
		ElsIf vRow.Remarks = "Отказ от уплаты курортного сбора" Then
			vGuestNotPay = vGuestNotPay + vRow.NumberOfGuests; 
		ElsIf vRow.Remarks = "17. Проживающий в домашнем регионе" Then	
			vAllowedNotPay = vAllowedNotPay + vRow.NumberOfGuests; 
			If vPrintStruct.Property("p20") Then
				vPrintStruct.p20 = vPrintStruct.p20 + vRow.NumberOfGuests;	
			Else
				vPrintStruct.Insert("p20", vRow.NumberOfGuests);    
			EndIf;
		Else
			vAllowedNotPay = vAllowedNotPay + vRow.NumberOfGuests;  
			vNumber = "p" + Left(vRow.Remarks, StrFind(vRow.Remarks, ".") - 1);  
			vNumber = StrReplace(vNumber, " ", "");
			If vPrintStruct.Property(vNumber) Then
				vPrintStruct[vNumber] = vPrintStruct[vNumber] + vRow.NumberOfGuests;	
			Else	
				vPrintStruct.Insert(vNumber, vRow.NumberOfGuests);
			EndIf;
		EndIf;
	EndDo;           
	
	vPrintStruct.Insert("AllGuest", vAll);
	vPrintStruct.Insert("AllPaymentGuest", vGuestPay);
	vPrintStruct.Insert("Amount", Format(vUnload.Total("Sales"), "NFD=2"));	
	vPrintStruct.Insert("GuestNotPay", vGuestNotPay);
	vPrintStruct.Insert("AllowedNotPay", vAllowedNotPay);	
	
	FillPropertyValues(vReport.Parameters, vPrintStruct);
	
	pSpreadsheet.Put(vReport);
	
EndProcedure

// -----------------------------------------------------------------------------
Procedure PrintReportForAK(pTemplate, pSpreadsheet)
	vHeadArea = pTemplate.GetArea("Header");
	
	vPrintStruct = New Structure();
	vPrintStruct.Insert("INN", TrimAll(Company.TIN));
	vPrintStruct.Insert("OperatorName", TrimAll(OperatorName));	
	vPrintStruct.Insert("ObjectName", TrimAll(ObjectName));
	vPrintStruct.Insert("TerritoryMO", TrimAll(TerritoryMO)); 
	vPrintStruct.Insert("Month", PeriodPresentation(BegOfDay(PeriodFrom), EndOfDay(PeriodTo), cmLocalizationCode()));
	vPrintStruct.Insert("OperatorNameAndINN", TrimAll(Company.TIN) + ", " + TrimAll(ThisObject.OperatorName));
	vPrintStruct.Insert("SupplementText", TrimAll(SupplementText));
	vPrintStruct.Insert("Role", TrimAll(Nstr(Company.DirectorPosition)));
	vPrintStruct.Insert("FullName", Nstr(Company.Director));
	vPrintStruct.Insert("ObjectAddres", Hotel.PostAddress);
	vPrintStruct.Insert("mQuarter", Format(EndOfQuarter(PeriodTo),"DF=к"));
	vPrintStruct.Insert("mYear", Year(PeriodTo));
	
	FillPropertyValues(vHeadArea.Parameters, vPrintStruct);
	
	pSpreadsheet.Put(vHeadArea);

	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	BEGINOFPERIOD(Guests.Period, MONTH) AS MonthOfPeriod,
	|	Guests.Period AS Period,
	|	Guests.Client AS Guests,
	|	SUM(Guests.NumberOfGuests) AS NumberOfGuests,
	|	SUM(Guests.Sales) AS Sales,
	|	CASE
	|		WHEN ISNULL(Guests.Sales, 0) > 0
	|			THEN 1
	|		ELSE 0
	|	END AS PayGuestsDays,
	|	CASE
	|		WHEN ISNULL(Guests.Sales, 0) = 0
	|			THEN 1
	|		ELSE 0
	|	END AS NoPayGuestsDays,
	|	Guests.Remarks AS Remarks
	|FROM
	|	(SELECT
	|		CAST(SalesMovements.Recorder.Remarks AS STRING(1024)) AS Remarks,
	|		SalesMovements.ParentDoc AS ParentDoc,
	|		MAX(SalesMovements.NumberOfPersons) AS NumberOfGuests,
	|		SUM(SalesMovements.Sales) AS Sales,
	|		SalesMovements.Period AS Period,
	|		SalesMovements.Client AS Client
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
	|		AND (&qRoomsFromFolder
	|					AND SalesMovements.Room IN HIERARCHY (&qRoomsFolder)
	|				OR &qExcludingRoomsFromFolder
	|					AND NOT SalesMovements.Room IN HIERARCHY (&qRoomsFolder)
	|				OR NOT &qRoomsFromFolder
	|					AND NOT &qExcludingRoomsFromFolder)
	|	
	|	GROUP BY
	|		CAST(SalesMovements.Recorder.Remarks AS STRING(1024)),
	|		SalesMovements.ParentDoc,
	|		SalesMovements.Period,
	|		SalesMovements.Client) AS Guests
	|
	|GROUP BY
	|	Guests.Remarks,
	|	Guests.Period,
	|	Guests.Client,
	|	BEGINOFPERIOD(Guests.Period, MONTH),
	|	CASE
	|		WHEN ISNULL(Guests.Sales, 0) > 0
	|			THEN 1
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN ISNULL(Guests.Sales, 0) = 0
	|			THEN 1
	|		ELSE 0
	|	END
	|
	|ORDER BY
	|	MonthOfPeriod DESC
	|TOTALS
	|	COUNT(DISTINCT Guests),
	|	SUM(NumberOfGuests),
	|	SUM(Sales),
	|	SUM(PayGuestsDays),
	|	SUM(NoPayGuestsDays)
	|BY
	|	OVERALL,
	|	MonthOfPeriod,
	|	Remarks";

	vQuery.SetParameter("qEmptyDate", Date(1, 1, 1));
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
	
	vResTotal = vQueryResult.Select(QueryResultIteration.ByGroups);
	
	vAge18Total 	= 0;
	vPayGuestTotal 	= 0;
	vAllowedNotPayTotal = 0;
	vGuestNotPayTotal = 0;
	While vResTotal.Next() Do
		
		vResRowMonth = vResTotal.Select(QueryResultIteration.ByGroups);
		While vResRowMonth.Next() Do
			//Fill by month
			
			vMonthArea = pTemplate.GetArea("Row");
			
			vMonthArea.Parameters.mMonth = vResRowMonth.MonthOfPeriod;
			vMonthArea.Parameters.mAmount = vResRowMonth.Sales;
			vMonthArea.Parameters.mDaysGuestsPaid = vResRowMonth.PayGuestsDays;
			vMonthArea.Parameters.mDaysGuestsNotPay = vResRowMonth.NoPayGuestsDays;
			
			vRow = vResRowMonth.Select(QueryResultIteration.ByGroups);
			
			vGuestPay 		= 0;
			pAge18 			= 0;
			vGuestNotPay 	= 0;
			vAllowedNotPay  = 0;
			
			While vRow.Next() Do
				If vRow.Remarks = "" Then           
					vGuestPay = vGuestPay + vRow.Guests;
				ElsIf vRow.Remarks = "Лицо не достигшее 18 лет" Then
					pAge18 = pAge18 + vRow.Guests;	
				ElsIf vRow.Remarks = "Отказ от уплаты курортного сбора" Then
					vGuestNotPay = vGuestNotPay + vRow.Guests; 
				ElsIf vRow.Remarks <> "Житель домашнего региона" Then
					vAllowedNotPay = vAllowedNotPay + vRow.Guests; 
				EndIf;
			EndDo;
			vMonthArea.Parameters.mAllPaymentGuest = vGuestPay;
			vMonthArea.Parameters.mAge18 = pAge18;
			vMonthArea.Parameters.mGuestNotPay = vGuestNotPay;
			vMonthArea.Parameters.mAllowedNotPay = vAllowedNotPay;
			
			vAge18Total 	= vAge18Total+pAge18;
			vPayGuestTotal 	= vPayGuestTotal+vGuestPay;
			vAllowedNotPayTotal = vAllowedNotPayTotal+vAllowedNotPay;
			vGuestNotPayTotal = vGuestNotPayTotal+vGuestNotPay;
			pSpreadsheet.Put(vMonthArea);
			
			vRow.Reset();
			While vRow.Next() Do
				vRowArea = pTemplate.GetArea("Row");
				//Filing records
				If vRow.Remarks = "Житель домашнего региона" Then	
					vRowArea.Parameters.mAllowedNotPay = vRow.Guests;
					vRowArea.Parameters.mAllowedNotPayCode = "17";
					pSpreadsheet.Put(vRowArea);
				ElsIf vRow.Remarks <> "Житель домашнего региона" And vRow.Remarks <> "Лицо не достигшее 18 лет" 
						And vRow.Remarks <> "" And vRow.Remarks <> "Отказ от уплаты курортного сбора" Then	
					vRowArea.Parameters.mAllowedNotPay = vRow.Guests;
					vRowArea.Parameters.mAllowedNotPayCode = Left(vRow.Remarks, StrFind(vRow.Remarks, ".") - 1);
					vRowArea.Parameters.mDaysGuestsNotPay = vRow.NoPayGuestsDays;
					pSpreadsheet.Put(vRowArea);
				EndIf;
			EndDo;
		EndDo;
		
		//Fill totals
		vFooterArea = pTemplate.GetArea("Footer");
		FillPropertyValues(vFooterArea.Parameters, vPrintStruct);
		vFooterArea.Parameters.mAmountTotal = vResTotal.Sales;
		vFooterArea.Parameters.mAllPaymentGuestTotal = vPayGuestTotal;
		vFooterArea.Parameters.mDaysGuestsPaidTotal = vResTotal.PayGuestsDays;
		vFooterArea.Parameters.mAllowedNotPayTotal = vAllowedNotPayTotal;
		vFooterArea.Parameters.mDaysGuestsNotPayTotal = vResTotal.NoPayGuestsDays;
		vFooterArea.Parameters.mAge18Total = vAge18Total;
		vFooterArea.Parameters.mGuestNotPayTotal = vGuestNotPayTotal;
		pSpreadsheet.Put(vFooterArea);
	EndDo;           
	
EndProcedure 

// -----------------------------------------------------------------------------
Procedure PrintReportForSPB(pTemplate, pSpreadsheet)
	vReport = pTemplate.GetArea("Report");

	vPrintStruct = New Structure();
	vPrintStruct.Insert("INN", TrimAll(Company.TIN));
	vPrintStruct.Insert("OperatorName", TrimAll(OperatorName));	
	vPrintStruct.Insert("ObjectName", TrimAll(ObjectName));
	vPrintStruct.Insert("TerritoryMO", TrimAll(TerritoryMO)); 
	vPrintStruct.Insert("mPeriod", PeriodPresentation(BegOfDay(PeriodFrom), EndOfDay(PeriodTo), cmLocalizationCode()));
	vPrintStruct.Insert("OperatorNameAndINN", TrimAll(Company.TIN) + ", " + TrimAll(ThisObject.OperatorName));
	vPrintStruct.Insert("SupplementText", TrimAll(SupplementText));
	vPrintStruct.Insert("Role", TrimAll(Nstr(Company.DirectorPosition)));
	vPrintStruct.Insert("FullName", Nstr(Company.Director));
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	Guests.Remarks AS Remarks,
	|	SUM(Guests.NumberOfGuests) AS NumberOfGuests,
	|	SUM(Guests.Sales) AS Sales
	|FROM
	|	(SELECT
	|		CAST(SalesMovements.Recorder.Remarks AS STRING(1024)) AS Remarks,
	|		SalesMovements.ParentDoc AS ParentDoc,
	|		MAX(SalesMovements.NumberOfPersons) AS NumberOfGuests,
	|		SUM(SalesMovements.Sales) AS Sales
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
	|		AND (&qRoomsFromFolder
	|					AND SalesMovements.Room IN HIERARCHY (&qRoomsFolder)
	|				OR &qExcludingRoomsFromFolder
	|					AND NOT SalesMovements.Room IN HIERARCHY (&qRoomsFolder)
	|				OR NOT &qRoomsFromFolder
	|					AND NOT &qExcludingRoomsFromFolder)
	|	
	|	GROUP BY
	|		CAST(SalesMovements.Recorder.Remarks AS STRING(1024)),
	|		SalesMovements.ParentDoc) AS Guests
	|
	|GROUP BY
	|	Guests.Remarks";
	vQuery.SetParameter("qEmptyDate", Date(1, 1, 1));
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
	vUnload = vQueryResult.Unload();
	
	vAll = 0;
	vGuestPay = 0;	
	vGuestNotPay = 0;	
	vAllowedNotPay = 0;	
	For Each vRow In vUnload Do
		vAll = vAll + vRow.NumberOfGuests; 
		If vRow.Remarks = "" Then
			vGuestPay = vGuestPay + vRow.NumberOfGuests;
			vPrintStruct.Insert("AllPaymentGuest", vRow.NumberOfGuests);
		ElsIf vRow.Remarks = "Лицо не достигшее 18 лет" Or vRow.Remarks = "Срок проживания менее суток" Then
			If vPrintStruct.Property("pAge18") Then
				vPrintStruct.pAge18 = vPrintStruct.pAge18 + vRow.NumberOfGuests;
			Else
				vPrintStruct.Insert("pAge18", vRow.NumberOfGuests);	
			EndIf;
		ElsIf vRow.Remarks = "Отказ от уплаты курортного сбора" Then
			vGuestNotPay = vGuestNotPay + vRow.NumberOfGuests; 
		ElsIf vRow.Remarks = "Житель домашнего региона" Then	
			vAllowedNotPay = vAllowedNotPay + vRow.NumberOfGuests;
			vPrintStruct.Insert("p20", vRow.NumberOfGuests);
		Else
			vAllowedNotPay = vAllowedNotPay + vRow.NumberOfGuests;
			vNumber = Left(vRow.Remarks, StrFind(vRow.Remarks, ".") - 1);
			vPrintStruct.Insert("p" + vNumber, vRow.NumberOfGuests);
		EndIf;
	EndDo;           
	
	vPrintStruct.Insert("AllGuest", vAll);
	vPrintStruct.Insert("AllPaymentGuest", vGuestPay);
	vPrintStruct.Insert("Amount", Format(vUnload.Total("Sales"), "NFD=2"));	
	vPrintStruct.Insert("GuestNotPay", vGuestNotPay);
	vPrintStruct.Insert("AllowedNotPay", vAllowedNotPay);	
	
	FillPropertyValues(vReport.Parameters, vPrintStruct);
	
	pSpreadsheet.Put(vReport);
	
EndProcedure

#EndRegion          
