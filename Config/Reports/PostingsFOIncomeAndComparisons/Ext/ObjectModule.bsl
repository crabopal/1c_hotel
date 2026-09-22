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
	If Not ValueIsFilled(Currency) Then
		If ValueIsFilled(Hotel) Then
			Currency = Hotel.BaseCurrency;
		EndIf;
	EndIf;
	If Not ValueIsFilled(PeriodTo) Then
		If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.AccountingDate) Then
			PeriodTo = BegOfDay(Hotel.AccountingDate) - 24*3600;
		Else
			PeriodTo = BegOfDay(CurrentSessionDate()) - 24*3600;
		EndIf;
	EndIf;
	If Not ValueIsFilled(PeriodTo) Then
		PeriodTo = EndOfDay(PeriodTo);
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure pmGenerate(pSpreadsheet) Export
	// Choose template
	vTemplate = ThisObject.GetTemplate("Report");
	
	// Clear output spreadsheet
	pSpreadsheet.Clear();
	
	// Initialize totals
	vTotals = GetTotalsStructure();
	
	// Calculate date from previous year
	vPeriodToPrevYear = AddMonth(PeriodTo, -12);
	
	// Get main report data
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accounts.Ref AS Account,
	|	Accounts.Code AS mAccount,
	|	Accounts.Description AS mName,
	|	Accounts.Type AS Type,
	|	Accounts.AccountGroup AS AccountGroup,
	|	Accounts.AccountType AS AccountType,
	|	ISNULL(DayPostings.DayAmount, 0) AS mTodayYear1,
	|	ISNULL(MonthPostings.MonthAmount, 0) AS mMTDYear1,
	|	ISNULL(YearPostings.YearAmount, 0) AS mYTDYear1,
	|	ISNULL(DayPostingsPrevYear.DayAmountPrevYear, 0) AS mTodayYear2,
	|	ISNULL(MonthPostingsPrevYear.MonthAmountPrevYear, 0) AS mMTDYear2,
	|	ISNULL(YearPostingsPrevYear.YearAmountPrevYear, 0) AS mYTDYear2,
	|	ISNULL(DayPostings.DayAmount, 0) - ISNULL(DayPostingsPrevYear.DayAmountPrevYear, 0) AS mTodayDiff,
	|	ISNULL(MonthPostings.MonthAmount, 0) - ISNULL(MonthPostingsPrevYear.MonthAmountPrevYear, 0) AS mMTDDiff,
	|	ISNULL(YearPostings.YearAmount, 0) - ISNULL(YearPostingsPrevYear.YearAmountPrevYear, 0) AS mYTDDiff,
	|	CASE
	|		WHEN ISNULL(DayPostingsPrevYear.DayAmountPrevYear, 0) > 0
	|				AND ISNULL(DayPostings.DayAmount, 0) > 0
	|			THEN ISNULL(DayPostingsPrevYear.DayAmountPrevYear, 0) / 100 * ISNULL(DayPostings.DayAmount, 0) - 100
	|		ELSE 0
	|	END AS mTodayPercentDiff,
	|	CASE
	|		WHEN ISNULL(MonthPostingsPrevYear.MonthAmountPrevYear, 0) > 0
	|				AND ISNULL(MonthPostings.MonthAmount, 0) > 0
	|			THEN ISNULL(MonthPostingsPrevYear.MonthAmountPrevYear, 0) / 100 * ISNULL(MonthPostings.MonthAmount, 0) - 100
	|		ELSE 0
	|	END AS mMTDPercentDiff,
	|	CASE
	|		WHEN ISNULL(YearPostingsPrevYear.YearAmountPrevYear, 0) > 0
	|				AND ISNULL(YearPostings.YearAmount, 0) > 0
	|			THEN ISNULL(YearPostingsPrevYear.YearAmountPrevYear, 0) / 100 * ISNULL(YearPostings.YearAmount, 0) - 100
	|		ELSE 0
	|	END AS mYTDPercentDiff
	|FROM
	|	ChartOfAccounts.ChartOfAccountsFO AS Accounts
	|		LEFT JOIN (SELECT
	|			DayPostings.Account AS Account,
	|			SUM(CASE
	|					WHEN DayPostings.RecordType = VALUE(AccountingRecordType.Credit)
	|							AND DayPostings.Account.Type = VALUE(AccountType.Passive)
	|						THEN DayPostings.Amount
	|					WHEN DayPostings.RecordType = VALUE(AccountingRecordType.Debit)
	|							AND DayPostings.Account.Type = VALUE(AccountType.Active)
	|						THEN DayPostings.Amount
	|					ELSE -DayPostings.Amount
	|				END) AS DayAmount
	|		FROM
	|			AccountingRegister.PostingsFO AS DayPostings
	|		WHERE
	|			DayPostings.Period >= &qBegOfDay
	|			AND DayPostings.Period <= &qEndOfDay
	|			AND (&qHotelIsEmpty
	|					OR NOT &qHotelIsEmpty
	|						AND DayPostings.Hotel IN HIERARCHY (&qHotel))
	|			AND (&qCompanyIsEmpty
	|					OR NOT &qCompanyIsEmpty
	|						AND DayPostings.Company IN HIERARCHY (&qCompany))
	|			AND DayPostings.Currency = &qCurrency
	|		
	|		GROUP BY
	|			DayPostings.Account) AS DayPostings
	|		ON Accounts.Ref = DayPostings.Account
	|		LEFT JOIN (SELECT
	|			MonthPostings.Account AS Account,
	|			SUM(CASE
	|					WHEN MonthPostings.RecordType = VALUE(AccountingRecordType.Credit)
	|							AND MonthPostings.Account.Type = VALUE(AccountType.Passive)
	|						THEN MonthPostings.Amount
	|					WHEN MonthPostings.RecordType = VALUE(AccountingRecordType.Debit)
	|							AND MonthPostings.Account.Type = VALUE(AccountType.Active)
	|						THEN MonthPostings.Amount
	|					ELSE -MonthPostings.Amount
	|				END) AS MonthAmount
	|		FROM
	|			AccountingRegister.PostingsFO AS MonthPostings
	|		WHERE
	|			MonthPostings.Period >= &qBegOfMonth
	|			AND MonthPostings.Period <= &qEndOfDay
	|			AND (&qHotelIsEmpty
	|					OR NOT &qHotelIsEmpty
	|						AND MonthPostings.Hotel IN HIERARCHY (&qHotel))
	|			AND (&qCompanyIsEmpty
	|					OR NOT &qCompanyIsEmpty
	|						AND MonthPostings.Company IN HIERARCHY (&qCompany))
	|			AND MonthPostings.Currency = &qCurrency
	|		
	|		GROUP BY
	|			MonthPostings.Account) AS MonthPostings
	|		ON Accounts.Ref = MonthPostings.Account
	|		LEFT JOIN (SELECT
	|			YearPostings.Account AS Account,
	|			SUM(CASE
	|					WHEN YearPostings.RecordType = VALUE(AccountingRecordType.Credit)
	|							AND YearPostings.Account.Type = VALUE(AccountType.Passive)
	|						THEN YearPostings.Amount
	|					WHEN YearPostings.RecordType = VALUE(AccountingRecordType.Debit)
	|							AND YearPostings.Account.Type = VALUE(AccountType.Active)
	|						THEN YearPostings.Amount
	|					ELSE -YearPostings.Amount
	|				END) AS YearAmount
	|		FROM
	|			AccountingRegister.PostingsFO AS YearPostings
	|		WHERE
	|			YearPostings.Period >= &qBegOfYear
	|			AND YearPostings.Period <= &qEndOfDay
	|			AND (&qHotelIsEmpty
	|					OR NOT &qHotelIsEmpty
	|						AND YearPostings.Hotel IN HIERARCHY (&qHotel))
	|			AND (&qCompanyIsEmpty
	|					OR NOT &qCompanyIsEmpty
	|						AND YearPostings.Company IN HIERARCHY (&qCompany))
	|			AND YearPostings.Currency = &qCurrency
	|		
	|		GROUP BY
	|			YearPostings.Account) AS YearPostings
	|		ON Accounts.Ref = YearPostings.Account
	|		LEFT JOIN (SELECT
	|			DayPostingsPrevYear.Account AS Account,
	|			SUM(CASE
	|					WHEN DayPostingsPrevYear.RecordType = VALUE(AccountingRecordType.Credit)
	|							AND DayPostingsPrevYear.Account.Type = VALUE(AccountType.Passive)
	|						THEN DayPostingsPrevYear.Amount
	|					WHEN DayPostingsPrevYear.RecordType = VALUE(AccountingRecordType.Debit)
	|							AND DayPostingsPrevYear.Account.Type = VALUE(AccountType.Active)
	|						THEN DayPostingsPrevYear.Amount
	|					ELSE -DayPostingsPrevYear.Amount
	|				END) AS DayAmountPrevYear
	|		FROM
	|			AccountingRegister.PostingsFO AS DayPostingsPrevYear
	|		WHERE
	|			DayPostingsPrevYear.Period >= &qBegOfDayPrevYear
	|			AND DayPostingsPrevYear.Period <= &qEndOfDayPrevYear
	|			AND (&qHotelIsEmpty
	|					OR NOT &qHotelIsEmpty
	|						AND DayPostingsPrevYear.Hotel IN HIERARCHY (&qHotel))
	|			AND (&qCompanyIsEmpty
	|					OR NOT &qCompanyIsEmpty
	|						AND DayPostingsPrevYear.Company IN HIERARCHY (&qCompany))
	|			AND DayPostingsPrevYear.Currency = &qCurrency
	|		
	|		GROUP BY
	|			DayPostingsPrevYear.Account) AS DayPostingsPrevYear
	|		ON Accounts.Ref = DayPostingsPrevYear.Account
	|		LEFT JOIN (SELECT
	|			MonthPostingsPrevYear.Account AS Account,
	|			SUM(CASE
	|					WHEN MonthPostingsPrevYear.RecordType = VALUE(AccountingRecordType.Credit)
	|							AND MonthPostingsPrevYear.Account.Type = VALUE(AccountType.Passive)
	|						THEN MonthPostingsPrevYear.Amount
	|					WHEN MonthPostingsPrevYear.RecordType = VALUE(AccountingRecordType.Debit)
	|							AND MonthPostingsPrevYear.Account.Type = VALUE(AccountType.Active)
	|						THEN MonthPostingsPrevYear.Amount
	|					ELSE -MonthPostingsPrevYear.Amount
	|				END) AS MonthAmountPrevYear
	|		FROM
	|			AccountingRegister.PostingsFO AS MonthPostingsPrevYear
	|		WHERE
	|			MonthPostingsPrevYear.Period >= &qBegOfMonthPrevYear
	|			AND MonthPostingsPrevYear.Period <= &qEndOfDayPrevYear
	|			AND (&qHotelIsEmpty
	|					OR NOT &qHotelIsEmpty
	|						AND MonthPostingsPrevYear.Hotel IN HIERARCHY (&qHotel))
	|			AND (&qCompanyIsEmpty
	|					OR NOT &qCompanyIsEmpty
	|						AND MonthPostingsPrevYear.Company IN HIERARCHY (&qCompany))
	|			AND MonthPostingsPrevYear.Currency = &qCurrency
	|		
	|		GROUP BY
	|			MonthPostingsPrevYear.Account) AS MonthPostingsPrevYear
	|		ON Accounts.Ref = MonthPostingsPrevYear.Account
	|		LEFT JOIN (SELECT
	|			YearPostingsPrevYear.Account AS Account,
	|			SUM(CASE
	|					WHEN YearPostingsPrevYear.RecordType = VALUE(AccountingRecordType.Credit)
	|							AND YearPostingsPrevYear.Account.Type = VALUE(AccountType.Passive)
	|						THEN YearPostingsPrevYear.Amount
	|					WHEN YearPostingsPrevYear.RecordType = VALUE(AccountingRecordType.Debit)
	|							AND YearPostingsPrevYear.Account.Type = VALUE(AccountType.Active)
	|						THEN YearPostingsPrevYear.Amount
	|					ELSE -YearPostingsPrevYear.Amount
	|				END) AS YearAmountPrevYear
	|		FROM
	|			AccountingRegister.PostingsFO AS YearPostingsPrevYear
	|		WHERE
	|			YearPostingsPrevYear.Period >= &qBegOfYearPrevYear
	|			AND YearPostingsPrevYear.Period <= &qEndOfDayPrevYear
	|			AND (&qHotelIsEmpty
	|					OR NOT &qHotelIsEmpty
	|						AND YearPostingsPrevYear.Hotel IN HIERARCHY (&qHotel))
	|			AND (&qCompanyIsEmpty
	|					OR NOT &qCompanyIsEmpty
	|						AND YearPostingsPrevYear.Company IN HIERARCHY (&qCompany))
	|			AND YearPostingsPrevYear.Currency = &qCurrency
	|		
	|		GROUP BY
	|			YearPostingsPrevYear.Account) AS YearPostingsPrevYear
	|		ON Accounts.Ref = YearPostingsPrevYear.Account
	|
	|ORDER BY
	|	Accounts.Type,
	|	Accounts.AccountGroup.Code,
	|	Accounts.AccountType.Code";
	vQry.SetParameter("qBegOfDay", BegOfDay(PeriodTo));
	vQry.SetParameter("qEndOfDay", EndOfDay(PeriodTo));
	vQry.SetParameter("qBegOfMonth", BegOfMonth(PeriodTo));
	vQry.SetParameter("qBegOfYear", BegOfYear(PeriodTo));
	vQry.SetParameter("qBegOfDayPrevYear", BegOfDay(vPeriodToPrevYear));
	vQry.SetParameter("qEndOfDayPrevYear", EndOfDay(vPeriodToPrevYear));
	vQry.SetParameter("qBegOfMonthPrevYear", BegOfMonth(vPeriodToPrevYear));
	vQry.SetParameter("qBegOfYearPrevYear", BegOfYear(vPeriodToPrevYear));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQry.SetParameter("qCurrency", Currency);
	vRepData = vQry.Execute().Unload();
	
	// Report header
	vHeaderArea = vTemplate.GetArea("Header");
	vHeaderArea.Parameters.mPeriodStr 	= PeriodPresentation(BegOfDay(PeriodTo), EndOfDay(PeriodTo), cmLocalizationCode());
	vHeaderArea.Parameters.mHotelName 	= TrimAll(Hotel.PrintName);
	vHeaderArea.Parameters.mYear1 		= Format(PeriodTo,"DF=yyyy");
	vHeaderArea.Parameters.mYear2 		= Format(vPeriodToPrevYear,"DF=yyyy");

	pSpreadsheet.Put(vHeaderArea);
	
	// Table of data
	vRowArea = vTemplate.GetArea("Row");
	vTotalsExcludePropertiesArray = New Array;
	vTotalsExcludePropertiesArray.Add("mTodayPercentDiff_Total");
	vTotalsExcludePropertiesArray.Add("mMTDPercentDiff_Total");
	vTotalsExcludePropertiesArray.Add("mYTDPercentDiff_Total");
	
	vTotalsByGroup 	= GetTotalsStructure();
	vTotalsByType	= GetTotalsStructure();
	vCurrentGroup	= Undefined;
	vCurrentType	= Undefined;
	For Each vRow In vRepData Do
		
		If vCurrentGroup <> vRow.AccountGroup Then
			If vCurrentGroup <> Undefined Then
				// Report table footer
				vFooterArea = vTemplate.GetArea("Footer");
				vFooterArea.Parameters.mTotalsDescription = vCurrentGroup.Description + " " + NStr("en = 'total'; de = 'summenzeile'; ru = 'итого'");				
				PutAndResetTotals(pSpreadsheet, vFooterArea, vHeaderArea, vTotalsByGroup);				
			EndIf;
		EndIf;
		
		If vCurrentType <> vRow.AccountType Then
			If vCurrentType <> Undefined Then
				// Report table footer
				vFooterArea = vTemplate.GetArea("Footer");
				vFooterArea.Parameters.mTotalsDescription = vCurrentType.Description + " " + NStr("en = 'total'; de = 'summenzeile'; ru = 'итого'");
				PutAndResetTotals(pSpreadsheet, vFooterArea, vHeaderArea, vTotalsByGroup);				
			EndIf;
		EndIf;

		// Fill area parameters
		FillPropertyValues(vRowArea.Parameters, vRow);
		
		// Calculate totals
		CalculateTotals(vTotals, 		vRow, vTotalsExcludePropertiesArray);
		CalculateTotals(vTotalsByGroup, vRow, vTotalsExcludePropertiesArray);
		CalculateTotals(vTotalsByType, 	vRow, vTotalsExcludePropertiesArray);
		
		// Put row area
		SpreadsheetPutWithAreaCheck(pSpreadsheet, vRowArea, vHeaderArea); 
		
		vCurrentGroup 	= vRow.AccountGroup;
		vCurrentType 	= vRow.AccountType;
	EndDo;
	
	// Report table footer
	
	If vCurrentGroup <> Undefined Then		
		vFooterArea = vTemplate.GetArea("Footer");
		vFooterArea.Parameters.mTotalsDescription = vCurrentGroup.Description + " " + NStr("en = 'total'; de = 'summenzeile'; ru = 'итого'");				
		PutAndResetTotals(pSpreadsheet, vFooterArea, vHeaderArea, vTotalsByGroup);
	EndIf;
	
	If vCurrentType <> Undefined Then		
		vFooterArea = vTemplate.GetArea("Footer");
		vFooterArea.Parameters.mTotalsDescription = vCurrentType.Description + " " + NStr("en = 'total'; de = 'summenzeile'; ru = 'итого'");
		PutAndResetTotals(pSpreadsheet, vFooterArea, vHeaderArea, vTotalsByGroup);
	EndIf;

	vFooterArea = vTemplate.GetArea("Footer");
	
	vTotals.mTodayPercentDiff_Total = CalculatePercents(vTotals.mTodayYear2_Total, vTotals.mTodayYear1_Total);
	vTotals.mMTDPercentDiff_Total 	= CalculatePercents(vTotals.mMTDYear2_Total, vTotals.mMTDYear1_Total);
	vTotals.mYTDPercentDiff_Total 	= CalculatePercents(vTotals.mYTDYear2_Total, vTotals.mYTDYear1_Total);
	
	vFooterArea.Parameters.mTotalsDescription = NStr("en = 'Debits total'; de = 'Summenzeile'; ru = 'Итого'");
	FillPropertyValues(vFooterArea.Parameters, vTotals);
	
	pSpreadsheet.Put(vFooterArea);
	
	
	// Report header and footer
	cmApplyReportHeader(pSpreadsheet);
	cmApplyReportFooter(pSpreadsheet);
EndProcedure // pmGenerate

// -----------------------------------------------------------------------------
Procedure CalculateTotals(rTotals, pRow, pExcludePropertiesArray = Undefined, pTotalPrefix = "_Total")
	
	For each vTotal in rTotals Do
		vCalculate = True;
		If pExcludePropertiesArray <> Undefined Then
			If pExcludePropertiesArray.Find(vTotal.Key) <> Undefined Then
				vCalculate = False;
			EndIf;
		EndIf;
		
		If vCalculate Then
			vValueBuff	= vTotal.Value;
			Try
				vKey = StrReplace(vTotal.Key, "_Total", "");
				rTotals[vTotal.Key] = vTotal.Value + pRow[vKey];
			Except
				rTotals[vTotal.Key] = vValueBuff;	
			EndTry;
		EndIf;
	EndDo;
		
EndProcedure // CalculateTotals

// -----------------------------------------------------------------------------
Function CalculatePercents(pFirstValue, pSecondValue)

	vResult = 0;
	
	If pFirstValue > 0 AND pSecondValue > 0 Then
		vResult = (pFirstValue / 100) * pSecondValue - 100; 	
	EndIf;
	
	Return vResult;
	
EndFunction // CalculatePercents

// -----------------------------------------------------------------------------
Procedure SpreadsheetPutWithAreaCheck(pSpreadsheet, pPutArea, pHeaderArea, pFooterArea = Undefined)
	
	vPutAreaArray = New Array;
	vPutAreaArray.Add(pPutArea);
	If pFooterArea <> Undefined Then
		vPutAreaArray.Add(pFooterArea);
	EndIf;
	
	If NOT pSpreadsheet.CheckPut(vPutAreaArray) Then
		If pFooterArea <> Undefined Then
			vPutAreaArray.Add(pFooterArea);
		EndIf;
		pSpreadsheet.PutHorizontalPageBreak();
		pSpreadsheet.Put(pHeaderArea);	
	EndIf;
	
	For each vPutArea in vPutAreaArray Do
		pSpreadsheet.Put(vPutArea);
	EndDo;
	
EndProcedure // SpreadsheetPutWithAreaCheck

// -----------------------------------------------------------------------------
Procedure PutAndResetTotals(pSpreadsheet, pFooterArea, pHeaderArea, rTotals)
	
	rTotals.mTodayPercentDiff_Total 	= CalculatePercents(rTotals.mTodayYear2_Total, rTotals.mTodayYear1_Total);
	rTotals.mMTDPercentDiff_Total 		= CalculatePercents(rTotals.mMTDYear2_Total, rTotals.mMTDYear1_Total);
	rTotals.mYTDPercentDiff_Total 		= CalculatePercents(rTotals.mYTDYear2_Total, rTotals.mYTDYear1_Total);
	
	// Report table footer
	FillPropertyValues(pFooterArea.Parameters, rTotals);
	SpreadsheetPutWithAreaCheck(pSpreadsheet, pFooterArea, pHeaderArea);
	
	rTotals = GetTotalsStructure();
	
EndProcedure

// -----------------------------------------------------------------------------
Function GetTotalsStructure()
	
	vResult = New Structure;
	vResult.Insert("mTodayYear1_Total", 		0);
	vResult.Insert("mMTDYear1_Total", 			0);
	vResult.Insert("mYTDYear1_Total", 			0);
	
	vResult.Insert("mTodayYear2_Total", 		0);
	vResult.Insert("mMTDYear2_Total", 			0);
	vResult.Insert("mYTDYear2_Total", 			0);
	
	vResult.Insert("mTodayDiff_Total", 			0);
	vResult.Insert("mTodayPercentDiff_Total", 	0);
	vResult.Insert("mMTDDiff_Total", 			0);
	vResult.Insert("mMTDPercentDiff_Total", 	0);
	vResult.Insert("mYTDDiff_Total", 			0);
	vResult.Insert("mYTDPercentDiff_Total", 	0);
	
	Return vResult;
EndFunction
