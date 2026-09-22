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
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If ValueIsFilled(AccountingDate) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период на '; en = 'Period on '; de = 'Periode '") + 
		                     Format(AccountingDate, "DF='dd.MM.yyyy'") + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("en='Period is wrong!';ru='Неправильно задан период!';de='Der Zeitraum wurde falsch eingetragen!'") + 
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(Company) Then
		If Not Company.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Company ';ru='Фирма ';de='Kompanie '") + 
			                     TrimAll(Company) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Companies folder ';ru='Папка фирм ';de='Kompaniesgruppe '") + 
			                     TrimAll(Company) + 
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
	If Not ValueIsFilled(AccountingDate) Then
		If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.AccountingDate) Then
			AccountingDate = BegOfDay(Hotel.AccountingDate) - 24*3600;
		Else
			AccountingDate = BegOfDay(CurrentSessionDate()) - 24*3600;
		EndIf;
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
	
	//
	// Room income part
	//
	
	// Initialize totals
	vTotalAdults = 0;
	vTotalTeenagers = 0;
	vTotalChildren = 0;
	vTotalInfants = 0;
	
	vTotalAmount = 0;
	vTotalRoom = 0;
	vTotalFood = 0;
	
	// Get main report data
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ISNULL(Postings.ParentDoc.ServicePackage, VALUE(Catalog.ServicePackages.EmptyRef)) AS Term,
	|	ISNULL(Postings.ParentDoc.ServicePackage.SortCode, 999999999) AS TermSortCode,
	|	ISNULL(Postings.ParentDoc.ServicePackage.Description, """") AS TermDescription,
	|	SUM(CASE
	|			WHEN Postings.Account.ServiceType.RevenueSegment = VALUE(Enum.RevenueSegments.Room)
	|				THEN ISNULL(Postings.ParentDoc.NumberOfAdults, 0)
	|			ELSE 0
	|		END) AS Adults,
	|	SUM(CASE
	|			WHEN Postings.Account.ServiceType.RevenueSegment = VALUE(Enum.RevenueSegments.Room)
	|				THEN ISNULL(Postings.ParentDoc.NumberOfTeenagers, 0)
	|			ELSE 0
	|		END) AS Teenagers,
	|	SUM(CASE
	|			WHEN Postings.Account.ServiceType.RevenueSegment = VALUE(Enum.RevenueSegments.Room)
	|				THEN ISNULL(Postings.ParentDoc.NumberOfChildren, 0)
	|			ELSE 0
	|		END) AS Children,
	|	SUM(CASE
	|			WHEN Postings.Account.ServiceType.RevenueSegment = VALUE(Enum.RevenueSegments.Room)
	|				THEN ISNULL(Postings.ParentDoc.NumberOfInfants, 0)
	|			ELSE 0
	|		END) AS Infants,
	|	SUM(CASE
	|			WHEN Postings.RecordType = VALUE(AccountingRecordType.Credit)
	|				THEN Postings.Amount
	|			ELSE -Postings.Amount
	|		END) AS Amount,
	|	SUM(CASE
	|			WHEN Postings.Account.ServiceType.RevenueSegment = VALUE(Enum.RevenueSegments.Room)
	|				THEN CASE
	|						WHEN Postings.RecordType = VALUE(AccountingRecordType.Credit)
	|							THEN Postings.Amount
	|						ELSE -Postings.Amount
	|					END
	|			ELSE 0
	|		END) AS RoomAmount,
	|	SUM(CASE
	|			WHEN Postings.Account.ServiceType.RevenueSegment = VALUE(Enum.RevenueSegments.FaB)
	|				THEN CASE
	|						WHEN Postings.RecordType = VALUE(AccountingRecordType.Credit)
	|							THEN Postings.Amount
	|						ELSE -Postings.Amount
	|					END
	|			ELSE 0
	|		END) AS FoodAmount
	|FROM
	|	AccountingRegister.PostingsFO AS Postings
	|WHERE
	|	Postings.Period >= &qPeriodFrom
	|	AND Postings.Period <= &qPeriodTo
	|	AND (&qHotelIsEmpty
	|			OR NOT &qHotelIsEmpty
	|				AND Postings.Hotel IN HIERARCHY (&qHotel))
	|	AND (&qCompanyIsEmpty
	|			OR NOT &qCompanyIsEmpty
	|				AND Postings.Company IN HIERARCHY (&qCompany))
	|	AND Postings.Account.AccountType = &qRoomIncomeAccountType
	|	AND NOT ISNULL(Postings.ParentDoc.RoomRate.IsComplimentary, FALSE)
	|	AND ISNULL(Postings.Recorder.CorrectedCharge, VALUE(Document.Charge.EmptyRef)) = VALUE(Document.Charge.EmptyRef)
	|	AND ISNULL(Postings.Recorder.IsRoomRevenue, FALSE)
	|
	|GROUP BY
	|	ISNULL(Postings.ParentDoc.ServicePackage, VALUE(Catalog.ServicePackages.EmptyRef)),
	|	ISNULL(Postings.ParentDoc.ServicePackage.SortCode, 999999999),
	|	ISNULL(Postings.ParentDoc.ServicePackage.Description, """")
	|
	|ORDER BY
	|	ISNULL(Postings.ParentDoc.ServicePackage.SortCode, 999999999),
	|	ISNULL(Postings.ParentDoc.ServicePackage.Description, """")";
	vQry.SetParameter("qPeriodFrom", BegOfDay(AccountingDate));
	vQry.SetParameter("qPeriodTo", EndOfDay(AccountingDate));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQry.SetParameter("qRoomIncomeAccountType", RoomIncomeAccountType);
	vRepData = vQry.Execute().Unload();
	
	// Report header
	vHeaderArea = vTemplate.GetArea("Header");
	vHeaderArea.Parameters.mPeriodStr = Format(AccountingDate, "DF=dd.MM.yyyy");
	vHeaderArea.Parameters.mHotelName = cmNStr(TrimAll(Hotel.PrintName), SessionParameters.CurrentLanguage);
	pSpreadsheet.Put(vHeaderArea);
	
	// Table header
	vTableHeaderArea = vTemplate.GetArea("TableHeader");
	pSpreadsheet.Put(vTableHeaderArea);
	
	// Table of data
	vRowArea = vTemplate.GetArea("Row");
	
	For Each vRow In vRepData Do
		// Fill area parameters
		vRowArea.Parameters.mTerm = vRow.Term;
		
		vRowArea.Parameters.mAdults = vRow.Adults;
		vRowArea.Parameters.mTeenagers = vRow.Teenagers;
		vRowArea.Parameters.mChildren = vRow.Children;
		vRowArea.Parameters.mInfants = vRow.Infants;
		vRowArea.Parameters.mGuests = vRow.Adults + vRow.Teenagers + vRow.Children + vRow.Infants;
		
		vRowArea.Parameters.mAmount = vRow.Amount;
		vRowArea.Parameters.mRoomAmount = vRow.RoomAmount;
		vRowArea.Parameters.mFoodAmount = vRow.FoodAmount;
		
		// Calculate totals
		vTotalAdults = vTotalAdults + vRow.Adults;
		vTotalTeenagers = vTotalTeenagers + vRow.Teenagers;
		vTotalChildren = vTotalChildren + vRow.Children;
		vTotalInfants = vTotalInfants + vRow.Infants;
		
		vTotalAmount = vTotalAmount + vRow.Amount;
		vTotalRoom = vTotalRoom + vRow.RoomAmount;
		vTotalFood = vTotalFood + vRow.FoodAmount;
		
		// Put row area
		pSpreadsheet.Put(vRowArea);
	EndDo;
	
	// Report table footer
	vFooterArea = vTemplate.GetArea("Footer");
	
	vFooterArea.Parameters.mTotalAdults = vTotalAdults;
	vFooterArea.Parameters.mTotalTeenagers = vTotalTeenagers;
	vFooterArea.Parameters.mTotalChildren = vTotalChildren;
	vFooterArea.Parameters.mTotalInfants = vTotalInfants;
	vFooterArea.Parameters.mTotalGuests = vTotalAdults + vTotalTeenagers + vTotalChildren + vTotalInfants;
	
	vFooterArea.Parameters.mTotalAmount = vTotalAmount;
	vFooterArea.Parameters.mTotalRoomAmount = vTotalRoom;
	vFooterArea.Parameters.mTotalFoodAmount = vTotalFood;
	
	pSpreadsheet.Put(vFooterArea);
	
	// Complimentary guests
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ISNULL(Accommodations.ServicePackage, VALUE(Catalog.ServicePackages.EmptyRef)) AS Term,
	|	ISNULL(Accommodations.ServicePackage.SortCode, 999999999) AS TermSortCode,
	|	ISNULL(Accommodations.ServicePackage.Description, """") AS TermDescription,
	|	SUM(ISNULL(Accommodations.NumberOfAdults, 0)) AS Adults,
	|	SUM(ISNULL(Accommodations.NumberOfTeenagers, 0)) AS Teenagers,
	|	SUM(ISNULL(Accommodations.NumberOfChildren, 0)) AS Children,
	|	SUM(ISNULL(Accommodations.NumberOfInfants, 0)) AS Infants,
	|	0 AS Amount,
	|	0 AS RoomAmount,
	|	0 AS FoodAmount
	|FROM
	|	Document.Accommodation AS Accommodations
	|WHERE
	|	Accommodations.CheckInDate < &qPeriodTo
	|	AND BEGINOFPERIOD(Accommodations.CheckOutDate, DAY) > &qPeriodFrom
	|	AND (&qHotelIsEmpty
	|			OR NOT &qHotelIsEmpty
	|				AND Accommodations.Hotel IN HIERARCHY (&qHotel))
	|	AND (&qCompanyIsEmpty
	|			OR NOT &qCompanyIsEmpty
	|				AND Accommodations.Company IN HIERARCHY (&qCompany))
	|	AND Accommodations.RoomRate.IsComplimentary
	|	AND Accommodations.Posted
	|	AND Accommodations.AccommodationStatus.IsActive
	|
	|GROUP BY
	|	ISNULL(Accommodations.ServicePackage, VALUE(Catalog.ServicePackages.EmptyRef)),
	|	ISNULL(Accommodations.ServicePackage.SortCode, 999999999),
	|	ISNULL(Accommodations.ServicePackage.Description, """")
	|
	|ORDER BY
	|	ISNULL(Accommodations.ServicePackage.SortCode, 999999999),
	|	ISNULL(Accommodations.ServicePackage.Description, """")";
	vQry.SetParameter("qPeriodFrom", BegOfDay(AccountingDate));
	vQry.SetParameter("qPeriodTo", EndOfDay(AccountingDate));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vComplData = vQry.Execute().Unload();
	
	If vComplData.Count() > 0 Then
		// Initialize totals
		vTotalAdults = 0;
		vTotalTeenagers = 0;
		vTotalChildren = 0;
		vTotalInfants = 0;

		vTotalAmount = 0;
		vTotalRoom = 0;
		vTotalFood = 0;
		
		// Complimentary guests header
		vComplHeaderArea = vTemplate.GetArea("ComplHeader");
		pSpreadsheet.Put(vComplHeaderArea);
		
		// Table header
		vTableHeaderArea = vTemplate.GetArea("TableHeader");
		pSpreadsheet.Put(vTableHeaderArea);
		
		For Each vComplRow In vComplData Do
			// Fill area parameters
			vRowArea.Parameters.mTerm = vComplRow.Term;
			
			vRowArea.Parameters.mAdults = vComplRow.Adults;
			vRowArea.Parameters.mTeenagers = vComplRow.Teenagers;
			vRowArea.Parameters.mChildren = vComplRow.Children;
			vRowArea.Parameters.mInfants = vComplRow.Infants;
			vRowArea.Parameters.mGuests = vComplRow.Adults + vComplRow.Teenagers + vComplRow.Children + vComplRow.Infants;
			
			vRowArea.Parameters.mAmount = vComplRow.Amount;
			vRowArea.Parameters.mRoomAmount = vComplRow.RoomAmount;
			vRowArea.Parameters.mFoodAmount = vComplRow.FoodAmount;
			
			// Calculate totals
			vTotalAdults = vTotalAdults + vComplRow.Adults;
			vTotalTeenagers = vTotalTeenagers + vComplRow.Teenagers;
			vTotalChildren = vTotalChildren + vComplRow.Children;
			vTotalInfants = vTotalInfants + vComplRow.Infants;
			
			vTotalAmount = vTotalAmount + vComplRow.Amount;
			vTotalRoom = vTotalRoom + vComplRow.RoomAmount;
			vTotalFood = vTotalFood + vComplRow.FoodAmount;
			
			// Put row area
			pSpreadsheet.Put(vRowArea);
		EndDo;
		
		// Report table footer
		vFooterArea = vTemplate.GetArea("Footer");
		
		vFooterArea.Parameters.mTotalAdults = vTotalAdults;
		vFooterArea.Parameters.mTotalTeenagers = vTotalTeenagers;
		vFooterArea.Parameters.mTotalChildren = vTotalChildren;
		vFooterArea.Parameters.mTotalInfants = vTotalInfants;
		vFooterArea.Parameters.mTotalGuests = vTotalAdults + vTotalTeenagers + vTotalChildren + vTotalInfants;
		
		vFooterArea.Parameters.mTotalAmount = vTotalAmount;
		vFooterArea.Parameters.mTotalRoomAmount = vTotalRoom;
		vFooterArea.Parameters.mTotalFoodAmount = vTotalFood;
		
		pSpreadsheet.Put(vFooterArea);
	EndIf;		
	
	// Get data for breakdown
	vBrQry = New Query();
	vBrQry.Text = 
	"SELECT
	|	PostingRecorders.Recorder AS Recorder
	|INTO RoomIncomeRecorders
	|FROM
	|	AccountingRegister.PostingsFO AS PostingRecorders
	|WHERE
	|	PostingRecorders.Period >= &qPeriodFrom
	|	AND PostingRecorders.Period <= &qPeriodTo
	|	AND (&qHotelIsEmpty
	|			OR NOT &qHotelIsEmpty
	|				AND PostingRecorders.Hotel IN HIERARCHY (&qHotel))
	|	AND (&qCompanyIsEmpty
	|			OR NOT &qCompanyIsEmpty
	|				AND PostingRecorders.Company IN HIERARCHY (&qCompany))
	|	AND PostingRecorders.Account.AccountType = &qRoomIncomeAccountType
	|	AND ISNULL(PostingRecorders.Recorder.IsRoomRevenue, FALSE)
	|
	|GROUP BY
	|	PostingRecorders.Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Postings.Account AS Account,
	|	Postings.Account.Code AS AccountCode,
	|	Postings.Account.Description AS AccountDescription,
	|	SUM(Postings.Amount) AS Amount
	|FROM
	|	AccountingRegister.PostingsFO AS Postings
	|WHERE
	|	Postings.Period >= &qPeriodFrom
	|	AND Postings.Period <= &qPeriodTo
	|	AND (&qHotelIsEmpty
	|			OR NOT &qHotelIsEmpty
	|				AND Postings.Hotel IN HIERARCHY (&qHotel))
	|	AND (&qCompanyIsEmpty
	|			OR NOT &qCompanyIsEmpty
	|				AND Postings.Company IN HIERARCHY (&qCompany))
	|	AND Postings.Recorder IN
	|			(SELECT
	|				RoomIncomeRecorders.Recorder
	|			FROM
	|				RoomIncomeRecorders AS RoomIncomeRecorders)
	|	AND Postings.Account <> VALUE(ChartOfAccounts.ChartOfAccountsFO.GuestLedger)
	|
	|GROUP BY
	|	Postings.Account,
	|	Postings.Account.Code,
	|	Postings.Account.Description
	|
	|ORDER BY
	|	Postings.Account.AccountType.SortCode,
	|	Postings.Account.AccountType.Code,
	|	Postings.Account.Code";
	vBrQry.SetParameter("qPeriodFrom", BegOfDay(AccountingDate));
	vBrQry.SetParameter("qPeriodTo", EndOfDay(AccountingDate));
	vBrQry.SetParameter("qHotel", Hotel);
	vBrQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vBrQry.SetParameter("qCompany", Company);
	vBrQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vBrQry.SetParameter("qRoomIncomeAccountType", RoomIncomeAccountType);
	vBrData = vBrQry.Execute().Unload();
	
	vTotalBrAmount = 0;
	
	// Breakdown header
	vBrHeaderArea = vTemplate.GetArea("BrHeader");
	pSpreadsheet.Put(vBrHeaderArea);
	
	// Table of breakdown data
	vBrRowArea = vTemplate.GetArea("BrRow");
	
	For Each vBrRow In vBrData Do
		// Fill area parameters
		vBrRowArea.Parameters.mBrAccount = vBrRow.AccountDescription;
		vBrRowArea.Parameters.mBrAmount = vBrRow.Amount;
	
		vTotalBrAmount = vTotalBrAmount + vBrRow.Amount;
		
		// Put breakdown area
		pSpreadsheet.Put(vBrRowArea);
	EndDo;
	
	// Breakdown footer
	vBrFooterArea = vTemplate.GetArea("BrFooter");
	vBrFooterArea.Parameters.mBrTotalAmount = vTotalBrAmount;
	pSpreadsheet.Put(vBrFooterArea);
	
	pSpreadsheet.PutHorizontalPageBreak();
		
	//
	// Extras income part
	//
	
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ChartOfAccounts.ComplimentaryIncomeAccount AS Account
	|INTO ComplimantaryAccounts
	|FROM
	|	ChartOfAccounts.ChartOfAccountsFO AS ChartOfAccounts
	|WHERE
	|	ChartOfAccounts.ComplimentaryIncomeAccount <> VALUE(ChartOfAccounts.ChartOfAccountsFO.EmptyRef)
	|	AND NOT ChartOfAccounts.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ChartOfAccounts.DiscountIncomeAccount AS Account
	|INTO DiscountAccounts
	|FROM
	|	ChartOfAccounts.ChartOfAccountsFO AS ChartOfAccounts
	|WHERE
	|	ChartOfAccounts.DiscountIncomeAccount <> VALUE(ChartOfAccounts.ChartOfAccountsFO.EmptyRef)
	|	AND NOT ChartOfAccounts.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ComplimantaryAccounts.Account AS Account
	|INTO SpecialAccounts
	|FROM
	|	ComplimantaryAccounts AS ComplimantaryAccounts
	|
	|UNION ALL
	|
	|SELECT
	|	DiscountAccounts.Account
	|FROM
	|	DiscountAccounts AS DiscountAccounts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExtrasIncomeAccounts.Ref AS Account,
	|	ExtrasIncomeAccounts.Code AS AccountCode,
	|	ExtrasIncomeAccounts.Description AS AccountName,
	|	ExtrasIncomeAccounts.Department AS Department,
	|	ExtrasIncomeAccounts.Department.Description AS DepartmentName,
	|	ISNULL(NetTotals.Amount, 0) AS NetAmount,
	|	ISNULL(ComplimentariesTotals.Amount, 0) AS ComplimentariesAmount,
	|	ISNULL(DiscountTotals.Amount, 0) AS DiscountsAmount,
	|	ISNULL(NetTotals.Amount, 0) + ISNULL(ComplimentariesTotals.Amount, 0) + ISNULL(DiscountTotals.Amount, 0) AS Amount
	|FROM
	|	ChartOfAccounts.ChartOfAccountsFO AS ExtrasIncomeAccounts
	|		LEFT JOIN (SELECT
	|			NetTotals.Account AS Account,
	|			-NetTotals.AmountTurnover AS Amount
	|		FROM
	|			AccountingRegister.PostingsFO.Turnovers(
	|					&qPeriodFrom,
	|					&qPeriodTo,
	|					Period,
	|					Account.AccountGroup = VALUE(Catalog.AccountGroups.Income)
	|						AND Account.AccountType <> &qRoomIncomeAccountType
	|						AND NOT Account IN
	|								(SELECT
	|									SpecialAccounts.Account
	|								FROM
	|									SpecialAccounts),
	|					,
	|					(&qHotelIsEmpty
	|						OR NOT &qHotelIsEmpty
	|							AND Hotel IN HIERARCHY (&qHotel))
	|						AND (&qCompanyIsEmpty
	|							OR NOT &qCompanyIsEmpty
	|								AND Company IN HIERARCHY (&qCompany))) AS NetTotals) AS NetTotals
	|		ON (NetTotals.Account = ExtrasIncomeAccounts.Ref)
	|		LEFT JOIN (SELECT
	|			ComplimentariesTotals.Account AS Account,
	|			-ComplimentariesTotals.AmountTurnover AS Amount
	|		FROM
	|			AccountingRegister.PostingsFO.Turnovers(
	|					&qPeriodFrom,
	|					&qPeriodTo,
	|					Period,
	|					Account.AccountGroup = VALUE(Catalog.AccountGroups.Income)
	|						AND Account.AccountType <> &qRoomIncomeAccountType,
	|					,
	|					(&qHotelIsEmpty
	|						OR NOT &qHotelIsEmpty
	|							AND Hotel IN HIERARCHY (&qHotel))
	|						AND (&qCompanyIsEmpty
	|							OR NOT &qCompanyIsEmpty
	|								AND Company IN HIERARCHY (&qCompany))) AS ComplimentariesTotals) AS ComplimentariesTotals
	|		ON ExtrasIncomeAccounts.ComplimentaryIncomeAccount = ComplimentariesTotals.Account
	|		LEFT JOIN (SELECT
	|			DiscountTotals.Account AS Account,
	|			-DiscountTotals.AmountTurnover AS Amount
	|		FROM
	|			AccountingRegister.PostingsFO.Turnovers(
	|					&qPeriodFrom,
	|					&qPeriodTo,
	|					Period,
	|					Account.AccountGroup = VALUE(Catalog.AccountGroups.Income)
	|						AND Account.AccountType <> &qRoomIncomeAccountType,
	|					,
	|					(&qHotelIsEmpty
	|						OR NOT &qHotelIsEmpty
	|							AND Hotel IN HIERARCHY (&qHotel))
	|						AND (&qCompanyIsEmpty
	|							OR NOT &qCompanyIsEmpty
	|								AND Company IN HIERARCHY (&qCompany))) AS DiscountTotals) AS DiscountTotals
	|		ON ExtrasIncomeAccounts.DiscountIncomeAccount = DiscountTotals.Account
	|WHERE
	|	ExtrasIncomeAccounts.AccountGroup = VALUE(Catalog.AccountGroups.Income)
	|	AND ExtrasIncomeAccounts.AccountType <> &qRoomIncomeAccountType
	|	AND NOT ExtrasIncomeAccounts.Ref IN
	|				(SELECT
	|					SpecialAccounts.Account
	|				FROM
	|					SpecialAccounts)
	|	AND (&qHotelIsEmpty
	|			OR ExtrasIncomeAccounts.Hotel = VALUE(Catalog.Hotels.EmptyRef)
	|			OR NOT &qHotelIsEmpty
	|				AND ExtrasIncomeAccounts.Hotel <> VALUE(Catalog.Hotels.EmptyRef)
	|				AND ExtrasIncomeAccounts.Hotel IN HIERARCHY (&qHotel))
	|	AND NOT ExtrasIncomeAccounts.DeletionMark
	|
	|ORDER BY
	|	ExtrasIncomeAccounts.Department.Code,
	|	ExtrasIncomeAccounts.Code";
	vQry.SetParameter("qPeriodFrom", BegOfDay(AccountingDate));
	vQry.SetParameter("qPeriodTo", EndOfDay(AccountingDate));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQry.SetParameter("qRoomIncomeAccountType", RoomIncomeAccountType);
	vRepData = vQry.Execute().Unload();
	
	// Report header
	vHeaderArea = vTemplate.GetArea("Header1");
	vHeaderArea.Parameters.mPeriodStr = Format(AccountingDate, "DF=dd.MM.yyyy");
	vHeaderArea.Parameters.mHotelName = cmNStr(TrimAll(Hotel.PrintName), SessionParameters.CurrentLanguage);
	pSpreadsheet.Put(vHeaderArea);

	vDepartments = vRepData.Copy(,"Department, DepartmentName");
	vDepartments.GroupBy("Department, DepartmentName");
	
	vTotalAmount = 0;
	vTotalComplimentaries = 0;
	vTotalDiscount = 0;
	vTotalNet = 0;
	For Each vDepartment In vDepartments Do
		vDepartmentArea = vTemplate.GetArea("RowDepartment");
		vDepartmentArea.Parameters.mDepartment = vDepartment.DepartmentName;
		
		pSpreadsheet.Put(vDepartmentArea);
		
		vDepartmentTotalAmount = 0;
		vDepartmentTotalComplimentaries = 0;
		vDepartmentTotalDiscount = 0;
		vDepartmentTotalNet = 0;
		
		For Each vRepDataRow In vRepData Do
			If vRepDataRow.Department = vDepartment.Department Then
				vRowArea = vTemplate.GetArea("Row1");
				
				vRowArea.Parameters.mRowAccount = TrimAll(vRepDataRow.AccountCode);
				vRowArea.Parameters.mRowName = TrimAll(vRepDataRow.AccountName);
				
				vRowArea.Parameters.mRowNet = vRepDataRow.NetAmount;
				vRowArea.Parameters.mRowComplimentaries = vRepDataRow.ComplimentariesAmount;
				vRowArea.Parameters.mRowDiscount = vRepDataRow.DiscountsAmount;
				vRowArea.Parameters.mRowAmount = vRepDataRow.Amount;
				
				pSpreadsheet.Put(vRowArea);
				
				vDepartmentTotalNet = vDepartmentTotalNet + vRepDataRow.NetAmount;
				vDepartmentTotalComplimentaries = vDepartmentTotalComplimentaries + vRepDataRow.ComplimentariesAmount;
				vDepartmentTotalDiscount = vDepartmentTotalDiscount + vRepDataRow.DiscountsAmount;
				vDepartmentTotalAmount = vDepartmentTotalAmount + vRepDataRow.Amount;
			EndIf;
		EndDo;	
		vDepartmentTotalArea = vTemplate.GetArea("RowDepartmentTotal");
		
		vDepartmentTotalArea.Parameters.mDepartmentTotal = TrimAll(vDepartment.DepartmentName) + NStr("en = ' Total'; de = ' Total'; ru = ' Всего'");
		
		vDepartmentTotalArea.Parameters.mDepartmentNetTotal = vDepartmentTotalNet;
		vDepartmentTotalArea.Parameters.mDepartmentComplimentariesTotal = vDepartmentTotalComplimentaries;
		vDepartmentTotalArea.Parameters.mDepartmentDiscountTotal = vDepartmentTotalDiscount;
		vDepartmentTotalArea.Parameters.mDepartmentAmountTotal = vDepartmentTotalAmount;
		
		pSpreadsheet.Put(vDepartmentTotalArea);
		
		vTotalAmount = vTotalAmount + vDepartmentTotalAmount;
		vTotalComplimentaries = vTotalComplimentaries + vDepartmentTotalComplimentaries;
		vTotalDiscount = vTotalDiscount + vDepartmentTotalDiscount;
		vTotalNet = vTotalNet +  vDepartmentTotalNet;		
	EndDo;
	vTotalExtrasArea = vTemplate.GetArea("TotalExtras");
	
	vTotalExtrasArea.Parameters.mNetTotal = vTotalNet;
	vTotalExtrasArea.Parameters.mComplimentariesTotal = vTotalComplimentaries;
	vTotalExtrasArea.Parameters.mDiscountTotal = vTotalDiscount;
	vTotalExtrasArea.Parameters.mAmountTotal = vTotalAmount;
	
	pSpreadsheet.Put(vTotalExtrasArea);

	//
	// Report header and footer
	//
	cmApplyReportHeader(pSpreadsheet);
	cmApplyReportFooter(pSpreadsheet);
EndProcedure // pmGenerate
