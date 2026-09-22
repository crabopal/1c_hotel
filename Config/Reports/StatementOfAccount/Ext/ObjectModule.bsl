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
		If Not ValueIsFilled(PeriodFrom) Then
			PeriodFrom = BegOfYear(CurrentSessionDate()); // For beg. of year
			PeriodTo = EndOfDay(CurrentSessionDate());
		EndIf;
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
		                     Format(PeriodFrom, "DF='dd.MM.yyyy'") + 
		                     ";" + Chars.LF;
	ElsIf Not ValueIsFilled(PeriodFrom) And ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период по '; en = 'Period to '; de = 'Periode zu '") + 
		                     Format(PeriodTo, "DF='dd.MM.yyyy'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom = PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период на '; en = 'Period on '; de = 'Periode '") + 
		                     Format(PeriodFrom, "DF='dd.MM.yyyy'") + 
		                     ";" + Chars.LF;
	ElsIf PeriodFrom < PeriodTo Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Период с '; en = 'Period from '; de = 'Periode von '") + Format(PeriodFrom, "DF='dd.MM.yyyy'") + NStr("ru = ' по '; en = ' to '; de = ' zu '") + Format(PeriodTo, "DF='dd.MM.yyyy'") + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("en='Period is wrong!';ru='Неправильно задан период!';de='Der Zeitraum wurde falsch eingetragen!'") + 
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If Not Hotel.IsFolder Then
			vHotelObj = Hotel.GetObject();
			vCompany = Company;
			If Not ValueIsFilled(vCompany) Then
				vCompany = Hotel.Company;
			EndIf;
			vCompanyCodes = "";
			If ValueIsFilled(vCompany) Then
				vCompanyTIN = TrimAll(vCompany.TIN);
				vCompanyKPP = TrimAll(vCompany.KPP);
				vCompanyVATC = TrimAll(vCompany.VATC);
				If Not IsBlankString(vCompanyTIN) Then
					vCompanyCodes = cmNStr("en=', TIС ';de=', SIC ';ru=', ИНН '", SessionParameters.CurrentLanguage) + vCompanyTIN + ?(IsBlankString(vCompanyKPP), "", "/" + vCompanyKPP) + ?(IsBlankString(vCompanyVATC), "", cmNStr("en=', VAT Code ';ru=', код НДС ';de=', Mw.St. Code '", SessionParameters.CurrentLanguage) + vCompanyVATC);
				EndIf;
			EndIf;
			vParamPresentation = vParamPresentation + NStr("en='Hotel ';ru='Гостиница ';de='Hotel '") + 
			                     vHotelObj.pmGetHotelPrintName(SessionParameters.CurrentLanguage) + vCompanyCodes + Chars.LF +
								 vHotelObj.pmGetHotelPostAddressPresentation(SessionParameters.CurrentLanguage) + Chars.LF +
								 TrimAll(vHotelObj.Phones) + 
								 ?(IsBlankString(vHotelObj.Fax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", SessionParameters.CurrentLanguage) + TrimAll(vHotelObj.Fax)) + 
			                     ?(IsBlankString(vHotelObj.EMail), "", cmNStr("en=', e-mail ';de=', e-mail ';ru=', e-mail '", SessionParameters.CurrentLanguage) + TrimAll(vHotelObj.EMail)) + 
								 ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц ';de='Hotelsgruppe '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(Company) Then
		If Not Company.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Фирма '; en = 'Company '; de = 'Kompanie '") + 
			                     TrimAll(Company.LegacyName) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа фирм '; en = 'Companies folder '; de = 'Kompaniegruppe '") + 
			                     TrimAll(Company.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(Customer) Then
		If Not Customer.IsFolder Then
			// Name and address
			vCustomerLegacyName = TrimAll(Customer.LegacyName);
			If IsBlankString(vCustomerLegacyName) Then
				vCustomerLegacyName = TrimAll(Customer.Description);
			EndIf;
			vCustomerLegacyAddress = cmGetAddressPresentation(Customer.LegacyAddress);
			vCustomerPostAddress = cmGetAddressPresentation(Customer.PostAddress);
			If vCustomerPostAddress = vCustomerLegacyAddress Then
				vCustomerPostAddress = "";
			EndIf;
			// Customer codes
			vCustomerCodes = "";
			vCustomerTIN = TrimAll(Customer.TIN);
			vCustomerKPP = TrimAll(Customer.KPP);
			vCustomerVATC = TrimAll(Customer.VATC);
			If Not IsBlankString(vCustomerTIN) Then
				vCustomerCodes = cmNStr("en=', TIC ';de=', SIC ';ru=', ИНН '", SessionParameters.CurrentLanguage) + vCustomerTIN + ?(IsBlankString(vCustomerKPP), "", "/" + vCustomerKPP) + 
				                 ?(IsBlankString(vCustomerVATC), "", cmNStr("en=', VAT Code ';ru=', код НДС ';de=', Mw.St. Code '", SessionParameters.CurrentLanguage) + vCustomerVATC);
			EndIf;
			// Phone, Fax and E-Mail
			vCustomerPhones = TrimAll(Customer.Phone);
			vCustomerFax = TrimAll(Customer.Fax);
			vCustomerEMail = TrimAll(Customer.EMail);
			vCustomerPhones = vCustomerPhones + 
			                  ?(IsBlankString(vCustomerFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", SessionParameters.CurrentLanguage) + vCustomerFax) + 
							  ?(IsBlankString(vCustomerEMail), "", cmNStr("en=', e-mail ';de=', e-mail ';ru=', e-mail '", SessionParameters.CurrentLanguage) + vCustomerEMail);
			mCustomer = TrimAll(vCustomerLegacyName + vCustomerTIN + Chars.LF + vCustomerLegacyAddress + ?(IsBlankString(vCustomerPostAddress), "", Chars.LF + vCustomerPostAddress) + Chars.LF + vCustomerPhones);
			vParamPresentation = vParamPresentation + NStr("de='Firma ';en='Customer ';ru='Контрагент '") + 
			                     vCustomerLegacyName + vCustomerCodes + Chars.LF + 
								 vCustomerLegacyAddress + Chars.LF + 
								 ?(IsBlankString(vCustomerPostAddress), "", vCustomerPostAddress + Chars.LF) + 
								 vCustomerPhones + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("de='Firmengruppe ';en='Customers folder ';ru='Группа контрагентов '") + 
			                     TrimAll(Customer.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(Contract) Then
		vParamPresentation = vParamPresentation + NStr("en='Contract ';ru='Договор ';de='Vertrag '") + 
							 TrimAll(Contract.Description) + 
							 ";" + Chars.LF;
	EndIf;							 
	If ValueIsFilled(GuestGroup) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Группа гостей '; en = 'Guest group '; de = 'Gastgruppe '") + 
							 TrimAll(TrimAll(GuestGroup.Code) + " " + TrimAll(GuestGroup.Description)) + 
							 ";" + Chars.LF;
	EndIf;							 
	If ValueIsFilled(Currency) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Валюта '; en = 'Currency '; de = 'Währung '") + 
							 TrimAll(Currency.Description) + 
							 ";" + Chars.LF;
	EndIf;					 
	Return vParamPresentation;
EndFunction // pmGetReportParametersPresentation

// -----------------------------------------------------------------------------
// Runs report
// -----------------------------------------------------------------------------
Procedure pmGenerate(pSpreadsheet) Export
	Var vTemplateAttributes;
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
	
	// Initialize report builder query generator attributes
	ReportBuilder.PresentationAdding = PresentationAdditionType.Add;
	
	// Fill report parameters
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qIsEmptyHotel", Not ValueIsFilled(Hotel));
	ReportBuilder.Parameters.Insert("qPeriodFrom", ?(ValueIsFilled(PeriodFrom), BegOfDay(PeriodFrom), '00010101010101'));
	ReportBuilder.Parameters.Insert("qPeriodTo", ?(ValueIsFilled(PeriodTo), EndOfDay(PeriodTo), '39991231235958'));
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qIsEmptyCustomer", Not ValueIsFilled(Customer));
	ReportBuilder.Parameters.Insert("qContract", Contract);
	ReportBuilder.Parameters.Insert("qIsEmptyContract", Not ValueIsFilled(Contract));
	ReportBuilder.Parameters.Insert("qGuestGroup", GuestGroup);
	ReportBuilder.Parameters.Insert("qIsEmptyGuestGroup", Not ValueIsFilled(GuestGroup));
	ReportBuilder.Parameters.Insert("qCompany", Company);
	ReportBuilder.Parameters.Insert("qIsEmptyCompany", Not ValueIsFilled(Company));
	ReportBuilder.Parameters.Insert("qCurrency", Currency);
	ReportBuilder.Parameters.Insert("qIsEmptyCurrency", Not ValueIsFilled(Currency));
	ReportBuilder.Parameters.Insert("qPrintCreditNoteAs1Row", PrintCreditNoteAs1Row);
	
	// Execute report builder query
	ReportBuilder.Execute();
	
	// Apply appearance settings to the report template
	vTemplateAttributes = cmApplyReportTemplateAppearance(ThisObject);
	
	// Output report to the spreadsheet
	ReportBuilder.Put(pSpreadsheet);
	//ReportBuilder.Template.Show(); // For debug purpose
	
	// Add report opening balance line
	vDateColumnIndex = 2;
	If pSpreadsheet.TableHeight > 6 Then
		// Get indexes for date and remarks columns
		vRemarksColumnIndex = pSpreadsheet.TableWidth - 3;
		i = 1;
		For Each vFld In ReportBuilder.SelectedFields Do
			i = i + 1;
			If lower(vFld.Name) = "recorderremarks" Then
				vRemarksColumnIndex = i;
			ElsIf lower(vFld.Name) = "recorderaccountingdate" Then
				vDateColumnIndex = i;
			EndIf;
		EndDo;
		
		// Opening balance line
		vFirstReportDataRowArea = pSpreadsheet.Area(5, , 5);
		vFooterGapArea = pSpreadsheet.Area(pSpreadsheet.TableHeight - 3, , pSpreadsheet.TableHeight - 3);
		pSpreadsheet.InsertArea(vFooterGapArea, vFirstReportDataRowArea, SpreadsheetDocumentShiftType.Vertical, False);
		vFirstReportDataRowArea = pSpreadsheet.Area(6, , 6);
		vFooterArea = pSpreadsheet.Area(pSpreadsheet.TableHeight - 2, , pSpreadsheet.TableHeight - 2);
		pSpreadsheet.InsertArea(vFooterArea, vFirstReportDataRowArea, SpreadsheetDocumentShiftType.Vertical, False);
		vFirstReportDataRowArea = pSpreadsheet.Area(7, , 7);
		vFooterGapArea = pSpreadsheet.Area(pSpreadsheet.TableHeight - 3, , pSpreadsheet.TableHeight - 3);
		pSpreadsheet.InsertArea(vFooterGapArea, vFirstReportDataRowArea, SpreadsheetDocumentShiftType.Vertical, False);
		
		pSpreadsheet.Area(6, 2).Text = "";
		pSpreadsheet.Area(6, vDateColumnIndex).Text = Format(PeriodFrom, "DF=dd.MM.yyyy");
		pSpreadsheet.Area(6, vRemarksColumnIndex).Text = NStr("en='Balance brought forward'; ru='Переходящий остаток'; de='Übertragungsbilanz'");
		
		vDebitAmount = GetAmount(pSpreadsheet.Area(8, pSpreadsheet.TableWidth - 2).Text);
		vCreditAmount = GetAmount(pSpreadsheet.Area(8, pSpreadsheet.TableWidth - 1).Text);
		vBalanceAmount = GetAmount(pSpreadsheet.Area(8, pSpreadsheet.TableWidth).Text);
		
		vOpeningBalanceAmount = vBalanceAmount - vDebitAmount + vCreditAmount;
		
		pSpreadsheet.Area(6, pSpreadsheet.TableWidth - 2).Text = "";
		pSpreadsheet.Area(6, pSpreadsheet.TableWidth - 1).Text = "";
		pSpreadsheet.Area(6, pSpreadsheet.TableWidth).Text = Format(vOpeningBalanceAmount, "NFD=2; NZ=");
		
		// Closing balance amount in the footer line
		vClosingBalanceAmount = GetAmount(pSpreadsheet.Area(pSpreadsheet.TableHeight - 4, pSpreadsheet.TableWidth).Text);
		
		pSpreadsheet.Area(pSpreadsheet.TableHeight - 2, pSpreadsheet.TableWidth).Text = Format(vClosingBalanceAmount, "NFD=2; NZ=");
		
		// Closing balance line
		vFooterArea = pSpreadsheet.Area(pSpreadsheet.TableHeight - 2, , pSpreadsheet.TableHeight - 2);
		vFooterGapArea = pSpreadsheet.Area(pSpreadsheet.TableHeight - 3, , pSpreadsheet.TableHeight - 3);
		pSpreadsheet.InsertArea(vFooterGapArea, vFooterArea, SpreadsheetDocumentShiftType.Vertical, False);
		
		vFooterGapArea = pSpreadsheet.Area(pSpreadsheet.TableHeight - 3, , pSpreadsheet.TableHeight - 3);
		vFooterArea = pSpreadsheet.Area(pSpreadsheet.TableHeight - 2, , pSpreadsheet.TableHeight - 2);
		pSpreadsheet.InsertArea(vFooterArea, vFooterGapArea, SpreadsheetDocumentShiftType.Vertical, False);
		
		pSpreadsheet.Area(pSpreadsheet.TableHeight - 4, 2).Text = "";
		pSpreadsheet.Area(pSpreadsheet.TableHeight - 4, vDateColumnIndex).Text = Format(PeriodTo, "DF=dd.MM.yyyy");
		pSpreadsheet.Area(pSpreadsheet.TableHeight - 4, vRemarksColumnIndex).Text = NStr("en='Balance carry forward'; ru='Переходящий остаток'; de='Übertragungsbilanz'");
		
		pSpreadsheet.Area(pSpreadsheet.TableHeight - 4, pSpreadsheet.TableWidth - 2).Text = "";
		pSpreadsheet.Area(pSpreadsheet.TableHeight - 4, pSpreadsheet.TableWidth - 1).Text = "";
		pSpreadsheet.Area(pSpreadsheet.TableHeight - 4, pSpreadsheet.TableWidth).Text = Format(vClosingBalanceAmount, "NFD=2; NZ=");
	EndIf;
	
	// Add report year totals line
	If ShowYearTotals Then
		vYearTotals = GetYearTotals();
		If vYearTotals.Count() = 1 Then
			vYTRow = vYearTotals.Get(0);
			
			// Closing balance line
			vFooterArea = pSpreadsheet.Area(pSpreadsheet.TableHeight - 2, , pSpreadsheet.TableHeight - 2);
			vFooterGapArea = pSpreadsheet.Area(pSpreadsheet.TableHeight - 3, , pSpreadsheet.TableHeight - 3);
			pSpreadsheet.InsertArea(vFooterGapArea, vFooterArea, SpreadsheetDocumentShiftType.Vertical, False);
			
			vFooterGapArea = pSpreadsheet.Area(pSpreadsheet.TableHeight - 3, , pSpreadsheet.TableHeight - 3);
			vFooterArea = pSpreadsheet.Area(pSpreadsheet.TableHeight - 2, , pSpreadsheet.TableHeight - 2);
			pSpreadsheet.InsertArea(vFooterArea, vFooterGapArea, SpreadsheetDocumentShiftType.Vertical, False);
			
			pSpreadsheet.Area(pSpreadsheet.TableHeight - 2, 2).Text = "";
			pSpreadsheet.Area(pSpreadsheet.TableHeight - 2, vDateColumnIndex).Text = "";
			pSpreadsheet.Area(pSpreadsheet.TableHeight - 2, vRemarksColumnIndex).Text = NStr("en='Year totals'; ru='Итоги за год'; de='Ergebnisse für das Jahr'");
			
			pSpreadsheet.Area(pSpreadsheet.TableHeight - 2, pSpreadsheet.TableWidth - 2).Text = Format(vYTRow.SumReceipt, "NFD=2; NZ=");
			pSpreadsheet.Area(pSpreadsheet.TableHeight - 2, pSpreadsheet.TableWidth - 1).Text = Format(vYTRow.SumExpense, "NFD=2; NZ=");
			pSpreadsheet.Area(pSpreadsheet.TableHeight - 2, pSpreadsheet.TableWidth).Text = Format(vYTRow.Sum, "NFD=2; NZ=");
		EndIf;
	EndIf;
	
	// Apply appearance settings to the report spreadsheet
	cmApplyReportAppearance(ThisObject, pSpreadsheet, vTemplateAttributes);
	
EndProcedure // pmGenerate

// -----------------------------------------------------------------------------
Function GetAmount(Val pAmountStr)
	vAmount = 0;
	If Not IsBlankString(pAmountStr) Then
		vStrLen = StrLen(pAmountStr);
		vDivider = 1;
		If vStrLen > 3 Then
			If Mid(pAmountStr, vStrLen - 1, 1) = "." Or Mid(pAmountStr, vStrLen - 1, 1) = "," Then
				vDivider = 10;
			ElsIf Mid(pAmountStr, vStrLen - 2, 1) = "." Or Mid(pAmountStr, vStrLen - 2, 1) = "," Then
				vDivider = 100;
			EndIf;
		EndIf;
		pAmountStr = StrReplace(pAmountStr, ".", "");
		pAmountStr = StrReplace(pAmountStr, ",", "");
		pAmountStr = StrReplace(pAmountStr, Mid(Format(9999, "NGS="), 2, 1), "");
		If Not IsBlankString(pAmountStr) And cmIsNumber(pAmountStr) Then
			vAmount = Number(pAmountStr)/vDivider;
		EndIf;
	EndIf;
	Return vAmount;
EndFunction // GetAmount
	
// -----------------------------------------------------------------------------
Procedure pmInitializeReportBuilder() Export
	ReportBuilder = New ReportBuilder();
	
	// Initialize default query text
	QueryText = 
	"SELECT
	|	CustomerAccountsInvoices.Hotel AS Hotel,
	|	CustomerAccountsInvoices.Company AS Company,
	|	CustomerAccountsInvoices.Currency AS Currency,
	|	CustomerAccountsInvoices.Customer AS Customer,
	|	CustomerAccountsInvoices.Contract AS Contract,
	|	CustomerAccountsInvoices.GuestGroup AS GuestGroup,
	|	BEGINOFPERIOD(CustomerAccountsInvoices.Period, DAY) AS RecorderAccountingDate,
	|	ISNULL(CustomerAccountsInvoices.Recorder.Date, BEGINOFPERIOD(CustomerAccountsInvoices.Period, DAY)) AS Period,
	|	CustomerAccountsInvoices.Recorder AS Recorder,
	|	CustomerAccountsInvoices.Recorder.Remarks AS RecorderRemarks,
	|	CustomerAccountsInvoices.SumReceipt AS SumReceipt,
	|	CustomerAccountsInvoices.SumExpense AS SumExpense,
	|	CustomerAccountsInvoices.Sum AS Sum
	|INTO CustomerAccountsInvoices
	|FROM
	|	(SELECT
	|		CustomerAccountsRecords.Hotel AS Hotel,
	|		CustomerAccountsRecords.Company AS Company,
	|		CustomerAccountsRecords.AccountingCurrency AS Currency,
	|		CustomerAccountsRecords.AccountingCustomer AS Customer,
	|		CustomerAccountsRecords.AccountingContract AS Contract,
	|		CustomerAccountsRecords.Recorder.GuestGroup AS GuestGroup,
	|		CustomerAccountsRecords.Period AS Period,
	|		CustomerAccountsRecords.Recorder AS Recorder,
	|		CustomerAccountsRecords.SumClosingBalance AS Sum,
	|		CustomerAccountsRecords.SumReceipt AS SumReceipt,
	|		CustomerAccountsRecords.SumExpense AS SumExpense
	|	FROM
	|		AccumulationRegister.CustomerAccounts.BalanceAndTurnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Recorder,
	|				RegisterRecordsAndPeriodBoundaries,
	|				(Hotel IN HIERARCHY (&qHotel)
	|					OR &qIsEmptyHotel)
	|					AND (Company IN HIERARCHY (&qCompany)
	|						OR &qIsEmptyCompany)
	|					AND (AccountingCustomer IN HIERARCHY (&qCustomer)
	|						OR &qIsEmptyCustomer)
	|					AND (AccountingContract = &qContract
	|						OR &qIsEmptyContract)
	|					AND (GuestGroup = &qGuestGroup
	|						OR &qIsEmptyGuestGroup)
	|					AND (AccountingCurrency = &qCurrency
	|						OR &qIsEmptyCurrency)) AS CustomerAccountsRecords) AS CustomerAccountsInvoices
	|WHERE
	|	CustomerAccountsInvoices.SumReceipt <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomerAccountsPayments.Hotel AS Hotel,
	|	CustomerAccountsPayments.Company AS Company,
	|	CustomerAccountsPayments.Currency AS Currency,
	|	CustomerAccountsPayments.Customer AS Customer,
	|	CustomerAccountsPayments.Contract AS Contract,
	|	CustomerAccountsPayments.GuestGroup AS GuestGroup,
	|	BEGINOFPERIOD(CustomerAccountsPayments.Period, DAY) AS RecorderAccountingDate,
	|	ISNULL(CustomerAccountsPayments.Recorder.Date, BEGINOFPERIOD(CustomerAccountsPayments.Period, DAY)) AS Period,
	|	CustomerAccountsPayments.Recorder AS Recorder,
	|	CustomerAccountsPayments.Recorder.Remarks AS RecorderRemarks,
	|	CustomerAccountsPayments.SumReceipt AS SumReceipt,
	|	CustomerAccountsPayments.SumExpense AS SumExpense,
	|	CustomerAccountsPayments.Sum AS Sum
	|INTO CustomerAccountsPayments
	|FROM
	|	(SELECT
	|		CustomerAccountsRecords.Hotel AS Hotel,
	|		CustomerAccountsRecords.Company AS Company,
	|		CustomerAccountsRecords.AccountingCurrency AS Currency,
	|		CustomerAccountsRecords.AccountingCustomer AS Customer,
	|		CustomerAccountsRecords.AccountingContract AS Contract,
	|		CustomerAccountsRecords.GuestGroup AS GuestGroup,
	|		CustomerAccountsRecords.Period AS Period,
	|		CustomerAccountsRecords.Recorder AS Recorder,
	|		CustomerAccountsRecords.SumClosingBalance AS Sum,
	|		CustomerAccountsRecords.SumReceipt AS SumReceipt,
	|		CustomerAccountsRecords.SumExpense AS SumExpense
	|	FROM
	|		AccumulationRegister.CustomerAccounts.BalanceAndTurnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Record,
	|				RegisterRecordsAndPeriodBoundaries,
	|				NOT &qPrintCreditNoteAs1Row
	|					AND (Hotel IN HIERARCHY (&qHotel)
	|						OR &qIsEmptyHotel)
	|					AND (Company IN HIERARCHY (&qCompany)
	|						OR &qIsEmptyCompany)
	|					AND (AccountingCustomer IN HIERARCHY (&qCustomer)
	|						OR &qIsEmptyCustomer)
	|					AND (AccountingContract = &qContract
	|						OR &qIsEmptyContract)
	|					AND (GuestGroup = &qGuestGroup
	|						OR &qIsEmptyGuestGroup)
	|					AND (AccountingCurrency = &qCurrency
	|						OR &qIsEmptyCurrency)) AS CustomerAccountsRecords
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CustomerAccountsRecords1Row.Hotel,
	|		CustomerAccountsRecords1Row.Company,
	|		CustomerAccountsRecords1Row.AccountingCurrency,
	|		CustomerAccountsRecords1Row.Recorder.AccountingCustomer,
	|		CustomerAccountsRecords1Row.Recorder.AccountingContract,
	|		CustomerAccountsRecords1Row.Recorder.GuestGroup,
	|		CustomerAccountsRecords1Row.Period,
	|		CustomerAccountsRecords1Row.Recorder,
	|		CustomerAccountsRecords1Row.SumClosingBalance,
	|		CustomerAccountsRecords1Row.SumReceipt,
	|		CustomerAccountsRecords1Row.SumExpense
	|	FROM
	|		AccumulationRegister.CustomerAccounts.BalanceAndTurnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Recorder,
	|				RegisterRecordsAndPeriodBoundaries,
	|				&qPrintCreditNoteAs1Row
	|					AND (Hotel IN HIERARCHY (&qHotel)
	|						OR &qIsEmptyHotel)
	|					AND (Company IN HIERARCHY (&qCompany)
	|						OR &qIsEmptyCompany)
	|					AND (AccountingCustomer IN HIERARCHY (&qCustomer)
	|						OR &qIsEmptyCustomer)
	|					AND (AccountingContract = &qContract
	|						OR &qIsEmptyContract)
	|					AND (GuestGroup = &qGuestGroup
	|						OR &qIsEmptyGuestGroup)
	|					AND (AccountingCurrency = &qCurrency
	|						OR &qIsEmptyCurrency)) AS CustomerAccountsRecords1Row) AS CustomerAccountsPayments
	|WHERE
	|	CustomerAccountsPayments.SumExpense <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomerAccounts.Hotel AS Hotel,
	|	CustomerAccounts.Company AS Company,
	|	CustomerAccounts.Currency AS Currency,
	|	CustomerAccounts.Customer AS Customer,
	|	CustomerAccounts.Contract AS Contract,
	|	CustomerAccounts.GuestGroup AS GuestGroup,
	|	CustomerAccounts.RecorderAccountingDate AS RecorderAccountingDate,
	|	CustomerAccounts.Period AS Period,
	|	CustomerAccounts.Recorder.PointInTime AS PointInTime,
	|	CustomerAccounts.Recorder AS Recorder,
	|	CustomerAccounts.RecorderRemarks AS RecorderRemarks,
	|	CustomerAccounts.SumReceipt AS SumReceipt,
	|	CustomerAccounts.SumExpense AS SumExpense,
	|	CustomerAccounts.Sum AS Sum
	|INTO CustomerAccounts
	|FROM
	|	(SELECT
	|		CustomerAccountsInvoices.Hotel AS Hotel,
	|		CustomerAccountsInvoices.Company AS Company,
	|		CustomerAccountsInvoices.Currency AS Currency,
	|		CustomerAccountsInvoices.Customer AS Customer,
	|		CustomerAccountsInvoices.Contract AS Contract,
	|		CustomerAccountsInvoices.GuestGroup AS GuestGroup,
	|		CustomerAccountsInvoices.RecorderAccountingDate AS RecorderAccountingDate,
	|		CustomerAccountsInvoices.Period AS Period,
	|		CustomerAccountsInvoices.Recorder AS Recorder,
	|		CustomerAccountsInvoices.RecorderRemarks AS RecorderRemarks,
	|		CustomerAccountsInvoices.SumReceipt AS SumReceipt,
	|		CustomerAccountsInvoices.SumExpense AS SumExpense,
	|		CustomerAccountsInvoices.Sum AS Sum
	|	FROM
	|		CustomerAccountsInvoices AS CustomerAccountsInvoices
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CustomerAccountsPayments.Hotel,
	|		CustomerAccountsPayments.Company,
	|		CustomerAccountsPayments.Currency,
	|		CustomerAccountsPayments.Customer,
	|		CustomerAccountsPayments.Contract,
	|		CustomerAccountsPayments.GuestGroup,
	|		CustomerAccountsPayments.RecorderAccountingDate,
	|		CustomerAccountsPayments.Period,
	|		CustomerAccountsPayments.Recorder,
	|		CustomerAccountsPayments.RecorderRemarks,
	|		CustomerAccountsPayments.SumReceipt,
	|		CustomerAccountsPayments.SumExpense,
	|		CustomerAccountsPayments.Sum
	|	FROM
	|		CustomerAccountsPayments AS CustomerAccountsPayments) AS CustomerAccounts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomerAccounts.Period,
	|	CustomerAccounts.Currency AS Currency,
	|	CustomerAccounts.Customer AS Customer,
	|	CustomerAccounts.Contract AS Contract,
	|	CustomerAccounts.GuestGroup AS GuestGroup,
	|	CustomerAccounts.RecorderAccountingDate AS RecorderAccountingDate,
	|	CustomerAccounts.PointInTime AS PointInTime,
	|	CustomerAccounts.Recorder AS Recorder,
	|	CustomerAccounts.RecorderRemarks AS RecorderRemarks,
	|	CustomerAccounts.SumReceipt AS SumReceipt,
	|	CustomerAccounts.SumExpense AS SumExpense,
	|	CustomerAccounts.Sum AS Sum
	|{SELECT
	|	CustomerAccounts.Hotel.*,
	|	CustomerAccounts.Company.*,
	|	Currency.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	RecorderAccountingDate,
	|	Period,
	|	Recorder.*,
	|	RecorderRemarks,
	|	SumReceipt,
	|	SumExpense,
	|	Sum}
	|FROM
	|	CustomerAccounts AS CustomerAccounts
	|{WHERE
	|	CustomerAccounts.Hotel.*,
	|	CustomerAccounts.Company.*,
	|	CustomerAccounts.Currency.*,
	|	CustomerAccounts.Customer.*,
	|	CustomerAccounts.Contract.*,
	|	CustomerAccounts.GuestGroup.*,
	|	CustomerAccounts.RecorderAccountingDate AS RecorderAccountingDate,
	|	CustomerAccounts.Recorder.*}
	|
	|ORDER BY
	|	CustomerAccounts.PointInTime
	|{ORDER BY
	|	RecorderAccountingDate,
	|	Period,
	|	PointInTime,
	|	CustomerAccounts.Hotel.*,
	|	CustomerAccounts.Company.*,
	|	Currency.*,
	|	Customer.*,
	|	Contract.*,
	|	GuestGroup.*,
	|	Recorder.*}
	|TOTALS
	|	SUM(SumReceipt),
	|	SUM(SumExpense),
	|	0 AS Sum
	|BY
	|	OVERALL";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("EN='Statement of account';RU='Выписка по взаиморасчетам';de='Kontoauszug'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
Function GetYearTotals()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CustomerAccountsInvoices.Hotel AS Hotel,
	|	CustomerAccountsInvoices.Company AS Company,
	|	CustomerAccountsInvoices.Currency AS Currency,
	|	CustomerAccountsInvoices.SumReceipt AS SumReceipt,
	|	CustomerAccountsInvoices.SumExpense AS SumExpense,
	|	CustomerAccountsInvoices.Sum AS Sum
	|INTO CustomerAccountsInvoices
	|FROM
	|	(SELECT
	|		CustomerAccountsRecords.Hotel AS Hotel,
	|		CustomerAccountsRecords.Company AS Company,
	|		CustomerAccountsRecords.AccountingCurrency AS Currency,
	|		CustomerAccountsRecords.SumClosingBalance AS Sum,
	|		CustomerAccountsRecords.SumReceipt AS SumReceipt,
	|		CustomerAccountsRecords.SumExpense AS SumExpense
	|	FROM
	|		AccumulationRegister.CustomerAccounts.BalanceAndTurnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Recorder,
	|				RegisterRecordsAndPeriodBoundaries,
	|				(Hotel IN HIERARCHY (&qHotel)
	|					OR &qIsEmptyHotel)
	|					AND (Company IN HIERARCHY (&qCompany)
	|						OR &qIsEmptyCompany)
	|					AND (AccountingCustomer IN HIERARCHY (&qCustomer)
	|						OR &qIsEmptyCustomer)
	|					AND (AccountingContract = &qContract
	|						OR &qIsEmptyContract)
	|					AND (GuestGroup = &qGuestGroup
	|						OR &qIsEmptyGuestGroup)
	|					AND (AccountingCurrency = &qCurrency
	|						OR &qIsEmptyCurrency)) AS CustomerAccountsRecords) AS CustomerAccountsInvoices
	|WHERE
	|	CustomerAccountsInvoices.SumReceipt <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomerAccountsPayments.Hotel AS Hotel,
	|	CustomerAccountsPayments.Company AS Company,
	|	CustomerAccountsPayments.Currency AS Currency,
	|	CustomerAccountsPayments.SumReceipt AS SumReceipt,
	|	CustomerAccountsPayments.SumExpense AS SumExpense,
	|	CustomerAccountsPayments.Sum AS Sum
	|INTO CustomerAccountsPayments
	|FROM
	|	(SELECT
	|		CustomerAccountsRecords.Hotel AS Hotel,
	|		CustomerAccountsRecords.Company AS Company,
	|		CustomerAccountsRecords.AccountingCurrency AS Currency,
	|		CustomerAccountsRecords.SumClosingBalance AS Sum,
	|		CustomerAccountsRecords.SumReceipt AS SumReceipt,
	|		CustomerAccountsRecords.SumExpense AS SumExpense
	|	FROM
	|		AccumulationRegister.CustomerAccounts.BalanceAndTurnovers(
	|				&qPeriodFrom,
	|				&qPeriodTo,
	|				Record,
	|				RegisterRecordsAndPeriodBoundaries,
	|				(Hotel IN HIERARCHY (&qHotel)
	|					OR &qIsEmptyHotel)
	|					AND (Company IN HIERARCHY (&qCompany)
	|						OR &qIsEmptyCompany)
	|					AND (AccountingCustomer IN HIERARCHY (&qCustomer)
	|						OR &qIsEmptyCustomer)
	|					AND (AccountingContract = &qContract
	|						OR &qIsEmptyContract)
	|					AND (GuestGroup = &qGuestGroup
	|						OR &qIsEmptyGuestGroup)
	|					AND (AccountingCurrency = &qCurrency
	|						OR &qIsEmptyCurrency)) AS CustomerAccountsRecords) AS CustomerAccountsPayments
	|WHERE
	|	CustomerAccountsPayments.SumExpense <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomerAccounts.Hotel AS Hotel,
	|	CustomerAccounts.Company AS Company,
	|	CustomerAccounts.Currency AS Currency,
	|	SUM(CustomerAccounts.SumReceipt) AS SumReceipt,
	|	SUM(CustomerAccounts.SumExpense) AS SumExpense,
	|	SUM(CustomerAccounts.Sum) AS Sum
	|FROM
	|	(SELECT
	|		CustomerAccountsInvoices.Hotel AS Hotel,
	|		CustomerAccountsInvoices.Company AS Company,
	|		CustomerAccountsInvoices.Currency AS Currency,
	|		CustomerAccountsInvoices.SumReceipt AS SumReceipt,
	|		CustomerAccountsInvoices.SumExpense AS SumExpense,
	|		CustomerAccountsInvoices.Sum AS Sum
	|	FROM
	|		CustomerAccountsInvoices AS CustomerAccountsInvoices
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CustomerAccountsPayments.Hotel,
	|		CustomerAccountsPayments.Company,
	|		CustomerAccountsPayments.Currency,
	|		CustomerAccountsPayments.SumReceipt,
	|		CustomerAccountsPayments.SumExpense,
	|		CustomerAccountsPayments.Sum
	|	FROM
	|		CustomerAccountsPayments AS CustomerAccountsPayments) AS CustomerAccounts
	|
	|GROUP BY
	|	CustomerAccounts.Hotel,
	|	CustomerAccounts.Company,
	|	CustomerAccounts.Currency";
	// Fill query parameters
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qIsEmptyHotel", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qPeriodFrom", ?(ValueIsFilled(PeriodFrom), BegOfYear(PeriodFrom), '00010101010101'));
	vQry.SetParameter("qPeriodTo", ?(ValueIsFilled(PeriodTo), EndOfDay(PeriodTo), '39991231235958'));
	vQry.SetParameter("qCustomer", Customer);
	vQry.SetParameter("qIsEmptyCustomer", Not ValueIsFilled(Customer));
	vQry.SetParameter("qContract", Contract);
	vQry.SetParameter("qIsEmptyContract", Not ValueIsFilled(Contract));
	vQry.SetParameter("qGuestGroup", GuestGroup);
	vQry.SetParameter("qIsEmptyGuestGroup", Not ValueIsFilled(GuestGroup));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qIsEmptyCompany", Not ValueIsFilled(Company));
	vQry.SetParameter("qCurrency", Currency);
	vQry.SetParameter("qIsEmptyCurrency", Not ValueIsFilled(Currency));
	// Execute query
	vTotals = vQry.Execute().Unload();
	Return vTotals;	
EndFunction // GetYearTotals

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
