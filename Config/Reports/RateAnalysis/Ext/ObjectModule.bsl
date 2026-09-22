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
	If Not ValueIsFilled(AccountingDate) Then
		AccountingDate = BegOfDay(BegOfDay(CurrentSessionDate()) - 1);
	EndIf;
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If Not ValueIsFilled(AccountingDate) Then
		vParamPresentation = vParamPresentation + NStr("en='Report period is not set';ru='Период отчета не установлен';de='Berichtszeitraum nicht festgelegt'") + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("ru = 'Дата '; en = 'Date '; de = 'Datum '") + 
		                     Format(AccountingDate, "DF='dd.MM.yyyy'") + 
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(Company) Then
		If Not Company.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Фирма '; en = 'Company '; de = 'Kompanie '") + 
			                     TrimAll(Company.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа фирм '; en = 'Companies folder '; de = 'Kompaniegruppe '") + 
			                     TrimAll(Company.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If Not Hotel.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Hotel ';ru='Гостиница ';de='Hotel '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц ';de='Hotelgruppe '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     TrimAll(Hotel.Description) + ";" + Chars.LF;
		EndIf;
	EndIf;
	Return vParamPresentation;
EndFunction // pmGetReportParametersPresentation

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure pmGenerate(pSpreadsheet) Export
	// Clear output spreadsheet
	pSpreadsheet.Clear();
	
	// Get table of guests
	vQry = New Query();
	If UsePostingsFOData Then
		vQry.Text = 
		"SELECT
		|	CASE
		|		WHEN SalesMovements.Recorder REFS Document.Storno
		|			THEN SalesMovements.Recorder.ParentCharge
		|		ELSE SalesMovements.Recorder
		|	END AS Recorder,
		|	SUM(SalesMovements.Amount) AS Sum,
		|	SUM(ISNULL(SalesMovements.Recorder.Quantity, 0)) AS Quantity
		|INTO CanceledTransactions
		|FROM
		|	AccountingRegister.PostingsFO AS SalesMovements
		|WHERE
		|	SalesMovements.Period = &qAccountingDate
		|	AND SalesMovements.Hotel IN HIERARCHY (&qHotel)
		|	AND (&qCompanyIsEmpty
		|			OR NOT &qCompanyIsEmpty
		|				AND SalesMovements.Company = &qCompany)
		|	AND SalesMovements.Recorder.IsRoomRevenue
		|	AND SalesMovements.Recorder.IsInPrice
		|
		|GROUP BY
		|	CASE
		|		WHEN SalesMovements.Recorder REFS Document.Storno
		|			THEN SalesMovements.Recorder.ParentCharge
		|		ELSE SalesMovements.Recorder
		|	END
		|
		|HAVING
		|	SUM(SalesMovements.Amount) = 0 AND
		|	SUM(ISNULL(SalesMovements.Recorder.Quantity, 0)) = 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SalesMovements.Account AS Account,
		|	SalesMovements.Recorder.Service AS RecorderService,
		|	SalesMovements.Recorder.ParentDoc.CheckInDate AS CheckInDate,
		|	SalesMovements.Recorder.ParentDoc.CheckOutDate AS CheckOutDate,
		|	ISNULL(SalesMovements.Recorder.ParentDoc.NumberOfAdults, 0) + ISNULL(SalesMovements.Recorder.ParentDoc.NumberOfTeenagers, 0) + ISNULL(SalesMovements.Recorder.ParentDoc.NumberOfChildren, 0) + ISNULL(SalesMovements.Recorder.ParentDoc.NumberOfInfants, 0) AS NumberOfPersons,
		|	SalesMovements.Recorder.Room AS Room,
		|	SalesMovements.Recorder.ParentDoc.Guest.FullName AS ClientFullName,
		|	SalesMovements.Recorder.Service AS Service,
		|	SalesMovements.Recorder.Service.SortCode AS ServiceSortCode,
		|	SalesMovements.Recorder.Service.Code AS ServiceCode,
		|	SalesMovements.Account.ServiceType AS ServiceServiceType,
		|	ISNULL(SalesMovements.Account.ServiceType.SortCode, 0) AS ServiceServiceTypeSortCode,
		|	ISNULL(SalesMovements.Account.ServiceType.Code, """") AS ServiceServiceTypeCode,
		|	SalesMovements.Recorder.VATRate AS VATRate,
		|	SUM(CASE
		|			WHEN SalesMovements.RecordType = VALUE(AccountingRecordType.Credit)
		|				THEN SalesMovements.GrosAmount
		|			ELSE -SalesMovements.GrosAmount
		|		END) AS Sum,
		|	SUM(CASE
		|			WHEN SalesMovements.RecordType = VALUE(AccountingRecordType.Credit)
		|				THEN SalesMovements.Amount
		|			ELSE -SalesMovements.Amount
		|		END) AS SumWithoutVAT,
		|	SUM(CASE
		|			WHEN SalesMovements.RecordType = VALUE(AccountingRecordType.Credit)
		|				THEN SalesMovements.VATAmount
		|			ELSE -SalesMovements.VATAmount
		|		END) AS VATSum
		|FROM
		|	AccountingRegister.PostingsFO AS SalesMovements
		|WHERE
		|	SalesMovements.Period = &qAccountingDate
		|	AND SalesMovements.Hotel IN HIERARCHY (&qHotel)
		|	AND (&qCompanyIsEmpty
		|			OR NOT &qCompanyIsEmpty
		|				AND SalesMovements.Company = &qCompany)
		|	AND SalesMovements.Recorder.IsRoomRevenue
		|	AND SalesMovements.Recorder.IsInPrice
		|	AND NOT CASE
		|				WHEN SalesMovements.Recorder REFS Document.Storno
		|					THEN SalesMovements.Recorder.ParentCharge
		|				ELSE SalesMovements.Recorder
		|			END IN
		|				(SELECT
		|					CanceledTransactions.Recorder
		|				FROM
		|					CanceledTransactions AS CanceledTransactions)
		|
		|GROUP BY
		|	SalesMovements.Account,
		|	SalesMovements.Recorder.Service,
		|	SalesMovements.Recorder.ParentDoc.CheckInDate,
		|	SalesMovements.Recorder.ParentDoc.CheckOutDate,
		|	ISNULL(SalesMovements.Recorder.ParentDoc.NumberOfAdults, 0) + ISNULL(SalesMovements.Recorder.ParentDoc.NumberOfTeenagers, 0) + ISNULL(SalesMovements.Recorder.ParentDoc.NumberOfChildren, 0) + ISNULL(SalesMovements.Recorder.ParentDoc.NumberOfInfants, 0),
		|	SalesMovements.Recorder.Room,
		|	SalesMovements.Recorder.ParentDoc.Guest.FullName,
		|	SalesMovements.Recorder.Service.SortCode,
		|	SalesMovements.Recorder.Service.Code,
		|	SalesMovements.Account.ServiceType,
		|	ISNULL(SalesMovements.Account.ServiceType.SortCode, 0),
		|	ISNULL(SalesMovements.Account.ServiceType.Code, """"),
		|	SalesMovements.Recorder.VATRate,
		|	SalesMovements.Recorder.Service
		|
		|ORDER BY
		|	SalesMovements.Recorder.Room.SortCode,
		|	SalesMovements.Recorder.ParentDoc.Guest.FullName,
		|	ServiceServiceTypeSortCode,
		|	ServiceServiceTypeCode,
		|	ServiceSortCode,
		|	ServiceCode";
	Else
		vQry.Text = 
		"SELECT
		|	CASE
		|		WHEN SalesMovements.Recorder REFS Document.Storno
		|			THEN SalesMovements.Recorder.ParentCharge
		|		ELSE SalesMovements.Recorder
		|	END AS Recorder,
		|	SUM(SalesMovements.Sales) AS Sum,
		|	SUM(SalesMovements.Quantity) AS Quantity
		|INTO CanceledTransactions
		|FROM
		|	AccumulationRegister.Sales AS SalesMovements
		|WHERE
		|	SalesMovements.AccountingDate = &qAccountingDate
		|	AND SalesMovements.Hotel IN HIERARCHY (&qHotel)
		|	AND (&qCompanyIsEmpty
		|			OR NOT &qCompanyIsEmpty
		|				AND SalesMovements.Company = &qCompany)
		|	AND SalesMovements.Recorder.IsRoomRevenue
		|	AND SalesMovements.Recorder.IsInPrice
		|
		|GROUP BY
		|	CASE
		|		WHEN SalesMovements.Recorder REFS Document.Storno
		|			THEN SalesMovements.Recorder.ParentCharge
		|		ELSE SalesMovements.Recorder
		|	END
		|
		|HAVING
		|	SUM(SalesMovements.Sales) = 0 AND
		|	SUM(SalesMovements.Quantity) = 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SalesMovements.Recorder.Service AS RecorderService,
		|	SalesMovements.Recorder.ParentDoc.CheckInDate AS CheckInDate,
		|	SalesMovements.Recorder.ParentDoc.CheckOutDate AS CheckOutDate,
		|	ISNULL(SalesMovements.Recorder.ParentDoc.NumberOfAdults, 0) + ISNULL(SalesMovements.Recorder.ParentDoc.NumberOfTeenagers, 0) + ISNULL(SalesMovements.Recorder.ParentDoc.NumberOfChildren, 0) + ISNULL(SalesMovements.Recorder.ParentDoc.NumberOfInfants, 0) AS NumberOfPersons,
		|	SalesMovements.Room AS Room,
		|	SalesMovements.Client.FullName AS ClientFullName,
		|	SalesMovements.Service AS Service,
		|	SalesMovements.Service.SortCode AS ServiceSortCode,
		|	SalesMovements.Service.Code AS ServiceCode,
		|	SalesMovements.Service.ServiceType AS ServiceServiceType,
		|	ISNULL(SalesMovements.Service.ServiceType.SortCode, 0) AS ServiceServiceTypeSortCode,
		|	ISNULL(SalesMovements.Service.ServiceType.Code, """") AS ServiceServiceTypeCode,
		|	SalesMovements.VATRate AS VATRate,
		|	SUM(SalesMovements.Sales) AS Sum,
		|	SUM(SalesMovements.SalesWithoutVAT) AS SumWithoutVAT,
		|	SUM(SalesMovements.VATSum) AS VATSum
		|FROM
		|	AccumulationRegister.Sales AS SalesMovements
		|WHERE
		|	SalesMovements.AccountingDate = &qAccountingDate
		|	AND SalesMovements.Hotel IN HIERARCHY (&qHotel)
		|	AND (&qCompanyIsEmpty
		|			OR NOT &qCompanyIsEmpty
		|				AND SalesMovements.Company = &qCompany)
		|	AND SalesMovements.Recorder.IsRoomRevenue
		|	AND SalesMovements.Recorder.IsInPrice
		|	AND NOT CASE
		|				WHEN SalesMovements.Recorder REFS Document.Storno
		|					THEN SalesMovements.Recorder.ParentCharge
		|				ELSE SalesMovements.Recorder
		|			END IN
		|				(SELECT
		|					CanceledTransactions.Recorder
		|				FROM
		|					CanceledTransactions AS CanceledTransactions)
		|
		|GROUP BY
		|	SalesMovements.Recorder.Service,
		|	SalesMovements.Recorder.ParentDoc.CheckInDate,
		|	SalesMovements.Recorder.ParentDoc.CheckOutDate,
		|	ISNULL(SalesMovements.Recorder.ParentDoc.NumberOfAdults, 0) + ISNULL(SalesMovements.Recorder.ParentDoc.NumberOfTeenagers, 0) + ISNULL(SalesMovements.Recorder.ParentDoc.NumberOfChildren, 0) + ISNULL(SalesMovements.Recorder.ParentDoc.NumberOfInfants, 0),
		|	SalesMovements.Room,
		|	SalesMovements.Client.FullName,
		|	SalesMovements.Service,
		|	SalesMovements.Service.SortCode,
		|	SalesMovements.Service.Code,
		|	SalesMovements.Service.ServiceType,
		|	ISNULL(SalesMovements.Service.ServiceType.SortCode, 0),
		|	ISNULL(SalesMovements.Service.ServiceType.Code, """"),
		|	SalesMovements.VATRate
		|
		|HAVING
		|	SUM(SalesMovements.Sales) <> 0
		|
		|ORDER BY
		|	SalesMovements.Room.SortCode,
		|	SalesMovements.Client.FullName,
		|	ServiceServiceTypeSortCode,
		|	ServiceServiceTypeCode,
		|	ServiceSortCode,
		|	ServiceCode";
	EndIf;
	vQry.SetParameter("qAccountingDate", AccountingDate);
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vGuests = vQry.Execute().Unload();
	
	// Initialize list of breakdown list items that has to be printed
	vBreakdownItems = New ValueTable();
	vBreakdownItems.Columns.Add("Item");
	vBreakdownItems.Columns.Add("ServiceTypeSortCode", cmGetNumberTypeDescription(12, 0));
	vBreakdownItems.Columns.Add("ServiceTypeCode", cmGetStringTypeDescription(50));
	vBreakdownItems.Columns.Add("ServiceSortCode", cmGetNumberTypeDescription(12, 0));
	vBreakdownItems.Columns.Add("ServiceCode", cmGetStringTypeDescription(50));
	vBreakdownItems.Columns.Add("Sum", cmGetSumTypeDescription());
	
	// Initialize list of breakdown list items that has to be printed
	vTotals = New ValueTable();
	vTotals.Columns.Add("Item");
	vTotals.Columns.Add("Service");
	vTotals.Columns.Add("VATRate");
	vTotals.Columns.Add("Sum", cmGetSumTypeDescription());
	
	// Initialize list of breakdown list items that has to be printed
	vVATTotals = New ValueTable();
	vVATTotals.Columns.Add("VATRate");
	vVATTotals.Columns.Add("VATSum", cmGetSumTypeDescription());
	
	// Fill items and totals
	For Each vGuestsRow In vGuests Do
		vItem = vGuestsRow.Service;
		If ValueIsFilled(vGuestsRow.ServiceServiceType) Then
			vItem = vGuestsRow.ServiceServiceType;
		EndIf;
		
		If Not UsePostingsFOData And vGuestsRow.Service <> vGuestsRow.RecorderService Or 
		   UsePostingsFOData Then
			vBreakdownItemsRow = vBreakdownItems.Find(vItem, "Item");
			If vBreakdownItemsRow = Undefined Then
				vBreakdownItemsRow = vBreakdownItems.Add();
				vBreakdownItemsRow.Item = vItem;
				vBreakdownItemsRow.ServiceTypeSortCode = vGuestsRow.ServiceServiceTypeSortCode;
				vBreakdownItemsRow.ServiceTypeCode = vGuestsRow.ServiceServiceTypeCode;
				vBreakdownItemsRow.ServiceSortCode = vGuestsRow.ServiceSortCode;
				vBreakdownItemsRow.ServiceCode = vGuestsRow.ServiceCode;
				vBreakdownItemsRow.Sum = vGuestsRow.SumWithoutVAT;
			Else
				vBreakdownItemsRow.Sum = vBreakdownItemsRow.Sum + vGuestsRow.SumWithoutVAT;
			EndIf;
		EndIf;
		
		vTotalsRow = vTotals.Add();
		vTotalsRow.Item = vItem;
		If ValueIsFilled(vGuestsRow.ServiceServiceType) Then
			If UsePostingsFOData Then
				vTotalsRow.Service = vGuestsRow.Account;
			Else
				vTotalsRow.Service = vGuestsRow.Service;
			EndIf;
		Else
			vTotalsRow.Service = Undefined;
		EndIf;
		vTotalsRow.VATRate = vGuestsRow.VATRate;
		vTotalsRow.Sum = vGuestsRow.SumWithoutVAT;
		
		If ValueIsFilled(vGuestsRow.VATRate) Then
			vVATTotalsRow = vVATTotals.Add();
			vVATTotalsRow.VATRate = vGuestsRow.VATRate;
			vVATTotalsRow.VATSum = vGuestsRow.VATSum;
		EndIf;
	EndDo;
	vBreakdownItems.Sort("ServiceTypeSortCode, ServiceTypeCode, ServiceSortCode, ServiceCode");
	vTotals.GroupBy("Item, Service, VATRate", "Sum");
	vTotals.Sort("Item, Service, VATRate");
	vVATTotals.GroupBy("VATRate", "VATSum");
	
	// Choose template
	vTemplate = ThisObject.GetTemplate("Report");
	
	// Report header
	vHeaderArea = vTemplate.GetArea("Header");
	vHeaderArea.Parameters.mCurrentTime = CurrentSessionDate();
	vHeaderArea.Parameters.mCurrentUser = SessionParameters.CurrentUser;
	vHeaderArea.Parameters.mCurrentComputer = SessionParameters.CurrentWorkstation;
	vHeaderArea.Parameters.mAccountingDate = AccountingDate;
	vHeaderArea.Parameters.mHotelName = ?(IsBlankString(Hotel.PrintName), TrimAll(Hotel.Description), TrimAll(Hotel.PrintName));
	pSpreadsheet.Put(vHeaderArea);
	
	// Table header
	vTableHeaderGuestArea = vTemplate.GetArea("TableHeader|Rate");
	vTableHeaderRoomAndVATArea = vTemplate.GetArea("TableHeader|RoomAndVAT");
	pSpreadsheet.Put(vTableHeaderGuestArea);
	If Not UsePostingsFOData Then
		pSpreadsheet.Join(vTableHeaderRoomAndVATArea);
	EndIf;
	vTableHeaderBreakDownArea = vTemplate.GetArea("TableHeader|Item");
	For Each vItemRow In vBreakdownItems Do
		If Not UsePostingsFOData Or UsePostingsFOData And TypeOf(vItemRow.Item) = Type("CatalogRef.ServiceTypes") Then
			vTableHeaderBreakDownArea.Parameters.mItemName = TrimAll(vItemRow.Item);
			pSpreadsheet.Join(vTableHeaderBreakDownArea);
		EndIf;
	EndDo;
	
	// Table of guests
	vGuestArea = vTemplate.GetArea("Guest|Rate");
	vRoomAndVATArea = vTemplate.GetArea("Guest|RoomAndVAT");
	vBreakDownArea = vTemplate.GetArea("Guest|Item");
	
	vRoomsList = New ValueList();
	
	vTotalNumberOfRooms = 0;
	vTotalNumberOfPersons = 0;
	vTotalRateAmount = 0;
	vTotalRoomAmount = 0;
	vTotalVATAmount = 0;
	
	vCurRoom = Undefined;
	vCurClientFullName = Undefined;
	vCurTerm = Undefined;
	vCurCheckInDate = Undefined;
	vCurCheckOutDate = Undefined;
	vCurNumberOfPersons = 0;
	
	vCurRateAmount = 0;
	vCurRoomAmount = 0;
	vCurVATAmount = 0;
	
	vCurBreakDownItems = vBreakdownItems.Copy();
	vCurBreakDownItems.FillValues(0, "Sum");
	
	For Each vGuestsRow In vGuests Do
		If vCurRoom <> Undefined And (vCurRoom <> vGuestsRow.Room Or vCurClientFullName <> vGuestsRow.ClientFullName Or 
		   vCurTerm <> vGuestsRow.RecorderService Or vCurCheckInDate <> vGuestsRow.CheckInDate Or vCurCheckOutDate <> vGuestsRow.CheckOutDate Or 
		   vCurNumberOfPersons <> vGuestsRow.NumberOfPersons) Then
			// Fill room area parameters
			vGuestArea.Parameters.mRoom = vCurRoom;
			vGuestArea.Parameters.mGuestFullName = vCurClientFullName;
			vGuestArea.Parameters.mTerm = vCurTerm;
			vGuestArea.Parameters.mCheckInDate = vCurCheckInDate;
			vGuestArea.Parameters.mCheckOutDate = vCurCheckOutDate;
			vGuestArea.Parameters.mNumberOfPersons = vCurNumberOfPersons;
			
			vGuestArea.Parameters.mRateAmount = vCurRateAmount;
			
			If vRoomsList.FindByValue(vCurRoom) = Undefined Then
				vTotalNumberOfRooms = vTotalNumberOfRooms + 1;
				vRoomsList.Add(vCurRoom);
			EndIf;
			
			vTotalNumberOfPersons = vTotalNumberOfPersons + vCurNumberOfPersons;
			vTotalRateAmount = vTotalRateAmount + vCurRateAmount;
		
			// Put room area
			pSpreadsheet.Put(vGuestArea);
			If Not UsePostingsFOData Then
				vRoomAndVATArea.Parameters.mRoomAmount = vCurRoomAmount;
				vRoomAndVATArea.Parameters.mVATAmount = vCurVATAmount;
				pSpreadsheet.Join(vRoomAndVATArea);
				
				vTotalRoomAmount = vTotalRoomAmount + vCurRoomAmount;
				vTotalVATAmount = vTotalVATAmount + vCurVATAmount;
			EndIf;
			
			// Join service types
			For Each vCurBreakdownItemsRow In vCurBreakDownItems Do
				If Not UsePostingsFOData Or UsePostingsFOData And TypeOf(vCurBreakdownItemsRow.Item) = Type("CatalogRef.ServiceTypes") Then
					vBreakDownArea.Parameters.mItemAmount = vCurBreakdownItemsRow.Sum;
					pSpreadsheet.Join(vBreakDownArea);
				EndIf;
			EndDo;
			
			// Reset all variables
			vCurRateAmount = 0;
			vCurVATAmount = 0;
			vCurRoomAmount = 0;
			
			vCurBreakDownItems = vBreakdownItems.Copy();
			vCurBreakDownItems.FillValues(0, "Sum");
		EndIf;
		
		vCurRoom = vGuestsRow.Room;
		vCurClientFullName = vGuestsRow.ClientFullName;
		vCurTerm = vGuestsRow.RecorderService;
		vCurCheckInDate = vGuestsRow.CheckInDate;
		vCurCheckOutDate = vGuestsRow.CheckOutDate;
		vCurNumberOfPersons = vGuestsRow.NumberOfPersons;
		
		vCurRateAmount = vCurRateAmount + vGuestsRow.Sum;
		vCurVATAmount = vCurVATAmount + vGuestsRow.VATSum;
		
		If Not UsePostingsFOData Then
			If vGuestsRow.Service = vGuestsRow.RecorderService Then
				vCurRoomAmount = vGuestsRow.SumWithoutVAT;
				Continue;
			EndIf;
		EndIf;
		
		vItem = vGuestsRow.Service;
		If ValueIsFilled(vGuestsRow.ServiceServiceType) Then
			vItem = vGuestsRow.ServiceServiceType;
		EndIf;
		vCurBreakdownItemsRow = vCurBreakdownItems.Find(vItem, "Item");
		If vCurBreakdownItemsRow <> Undefined Then
			vCurBreakdownItemsRow.Sum = vCurBreakdownItemsRow.Sum + vGuestsRow.SumWithoutVAT;
		Else
			Raise "Breakdown list item is missing!";
		EndIf;
	EndDo;
	If vCurRoom <> Undefined Then
		// Fill room area parameters
		vGuestArea.Parameters.mRoom = vCurRoom;
		vGuestArea.Parameters.mGuestFullName = vCurClientFullName;
		vGuestArea.Parameters.mTerm = vCurTerm;
		vGuestArea.Parameters.mCheckInDate = vCurCheckInDate;
		vGuestArea.Parameters.mCheckOutDate = vCurCheckOutDate;
		vGuestArea.Parameters.mNumberOfPersons = vCurNumberOfPersons;
		
		vGuestArea.Parameters.mRateAmount = vCurRateAmount;
		
		If vRoomsList.FindByValue(vCurRoom) = Undefined Then
			vTotalNumberOfRooms = vTotalNumberOfRooms + 1;
			vRoomsList.Add(vCurRoom);
		EndIf;
		
		vTotalNumberOfPersons = vTotalNumberOfPersons + vCurNumberOfPersons;
		vTotalRateAmount = vTotalRateAmount + vCurRateAmount;
	
		// Put room area
		pSpreadsheet.Put(vGuestArea);
		If Not UsePostingsFOData Then
			vRoomAndVATArea.Parameters.mRoomAmount = vCurRoomAmount;
			vRoomAndVATArea.Parameters.mVATAmount = vCurVATAmount;
			pSpreadsheet.Join(vRoomAndVATArea);
			
			vTotalRoomAmount = vTotalRoomAmount + vCurRoomAmount;
			vTotalVATAmount = vTotalVATAmount + vCurVATAmount;
		EndIf;
		
		// Join service types
		For Each vCurBreakdownItemsRow In vCurBreakDownItems Do
			If Not UsePostingsFOData Or UsePostingsFOData And TypeOf(vCurBreakdownItemsRow.Item) = Type("CatalogRef.ServiceTypes") Then
				vBreakDownArea.Parameters.mItemAmount = vCurBreakdownItemsRow.Sum;
				pSpreadsheet.Join(vBreakDownArea);
			EndIf;
		EndDo;
	EndIf;
	
	// Report table footer
	vTableFooterArea = vTemplate.GetArea("TableFooter|Rate");
	vTableFooterArea.Parameters.mTotalNumberOfRooms = vTotalNumberOfRooms;
	vTableFooterArea.Parameters.mTotalNumberOfPersons = vTotalNumberOfPersons;
	vTableFooterArea.Parameters.mTotalRateAmount = vTotalRateAmount;
	pSpreadsheet.Put(vTableFooterArea);
	
	If Not UsePostingsFOData Then
		vTableFooterRoomAndVATArea = vTemplate.GetArea("TableFooter|RoomAndVAT");
		vTableFooterRoomAndVATArea.Parameters.mTotalRoomAmount = vTotalRoomAmount;
		vTableFooterRoomAndVATArea.Parameters.mTotalVATAmount = vTotalVATAmount;
		pSpreadsheet.Join(vTableFooterRoomAndVATArea);
	EndIf;
	
	vTableFooterItemArea = vTemplate.GetArea("TableFooter|Item");
	For Each vItemRow In vBreakdownItems Do
		If Not UsePostingsFOData Or UsePostingsFOData And TypeOf(vItemRow.Item) = Type("CatalogRef.ServiceTypes") Then
			vTableFooterItemArea.Parameters.mItemTotalAmount = vItemRow.Sum;
			pSpreadsheet.Join(vTableFooterItemArea);
		EndIf;
	EndDo;
	
	vTotalVATAmount = vVATTotals.Total("VATSum");
	
	// Choose totals template
	vTotalsTemplate = ThisObject.GetTemplate("ReportTotals");
	
	If Not UsePostingsFOData Then
		vVATHeaderArea = vTotalsTemplate.GetArea("VATHeader");
		vVATHeaderArea.Parameters.mVATTotal = vTotalVATAmount;
		vVATRateArea = vTotalsTemplate.GetArea("VATRate");
	Else
		vVATHeaderArea = vTotalsTemplate.GetArea("VATHeader|Items");
		vVATRateArea = vTotalsTemplate.GetArea("VATRate|Items");
	EndIf;
	vVATHeaderArea.Parameters.mRateTotal = vTotalRateAmount;
	pSpreadsheet.Put(vVATHeaderArea);
	If Not UsePostingsFOData Then
		For Each vVATTotalsRow In vVATTotals Do
			vAccountCode = "";
			vAccountStruct = cmGetAccountCodeForVATRate(Hotel, Company, vVATTotalsRow.VATRate);
			If Not IsBlankString(vAccountStruct.Code) Then
				vAccountCode = TrimAll(vAccountStruct.Code);
			ElsIf ValueIsFilled(vAccountStruct.Account) And Not IsBlankString(vAccountStruct.Account.CodeBO) Then
				vAccountCode = TrimAll(vAccountStruct.Account.CodeBO);
			EndIf;
			vVATRateArea.Parameters.mVATAccount = vAccountCode;
			vVATRateArea.Parameters.mVATTaxRate = ?(ValueIsFilled(vVATTotalsRow.VATRate), TrimAll(vVATTotalsRow.VATRate.TaxRate) + " %", "");
			vVATRateArea.Parameters.mVATRateTotal = vVATTotalsRow.VATSum;
			pSpreadsheet.Put(vVATRateArea);
		EndDo;
	EndIf;
	If Not UsePostingsFOData Then
		vVATFooterArea = vTotalsTemplate.GetArea("VATFooter");
	Else
		vVATFooterArea = vTotalsTemplate.GetArea("VATFooter|Items");
	EndIf;
	pSpreadsheet.Put(vVATFooterArea);
	
	// Breakdown list items
	vItemHeaderArea = vTotalsTemplate.GetArea("ItemHeader");
	vItemServiceArea = vTotalsTemplate.GetArea("ItemService");
	vItemFooterArea = vTotalsTemplate.GetArea("ItemFooter");
	
	vCurItem = Undefined;
	For Each vTotalsRow In vTotals Do
		If vCurItem <> vTotalsRow.Item Then
			If vCurItem <> Undefined Then
				pSpreadsheet.Put(vItemFooterArea);
			EndIf;
			
			vCurItem = vTotalsRow.Item;
			
			vItemTotal = 0;
			vItemHeaderArea.Parameters.mItem = vCurItem;
			vItemTotalsRows = vTotals.FindRows(New Structure("Item", vCurItem));
			For Each vItemTotalsRow In vItemTotalsRows Do
				vItemTotal = vItemTotal + vItemTotalsRow.Sum;
			EndDo;
			vItemHeaderArea.Parameters.mItemTotal = vItemTotal;
			
			pSpreadsheet.Put(vItemHeaderArea);
		EndIf;
		
		vItemService = vTotalsRow.Service;
		If Not ValueIsFilled(vItemService) Then
			vItemService = vCurItem;
		EndIf;
		vItemServiceArea.Parameters.mService = vItemService;
		If UsePostingsFOData Then
			If ValueIsFilled(vTotalsRow.Service) Then
				vItemServiceArea.Parameters.mService = TrimAll(vTotalsRow.Service.Description);
			EndIf;
		EndIf;
		
		vAccountCode = "";
		If UsePostingsFOData Then
			If ValueIsFilled(vTotalsRow.Service) Then
				vAccountCode = TrimAll(vTotalsRow.Service.Code);
			EndIf;		
		Else
			vAccountStruct = cmGetAccountCodeForService(Hotel, Company, vItemService, vTotalsRow.VATRate, AccountingDate);
			If Not IsBlankString(vAccountStruct.Code) Then
				vAccountCode = TrimAll(vAccountStruct.Code);
			ElsIf ValueIsFilled(vAccountStruct.Account) And Not IsBlankString(vAccountStruct.Account.CodeBO) Then
				vAccountCode = TrimAll(vAccountStruct.Account.CodeBO);
			EndIf;
		EndIf;
		vItemServiceArea.Parameters.mServiceAccount = vAccountCode;
		
		If ValueIsFilled(vTotalsRow.Service) Then
			vItemServiceArea.Parameters.mServiceVATTaxRate = ?(ValueIsFilled(vTotalsRow.VATRate), TrimAll(vTotalsRow.VATRate.TaxRate) + " %", "");
		Else
			vItemServiceArea.Parameters.mServiceVATTaxRate = "";
		EndIf;
		vItemServiceArea.Parameters.mServiceTotal = vTotalsRow.Sum;
		pSpreadsheet.Put(vItemServiceArea);
	EndDo;
	If vCurItem <> Undefined Then
		pSpreadsheet.Put(vItemFooterArea);
	EndIf;
	
	// Report header and footer
	cmApplyReportHeader(pSpreadsheet);
	cmApplyReportFooter(pSpreadsheet);
EndProcedure // pmGenerate
