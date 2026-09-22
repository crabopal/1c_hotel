#Region EventHandlers

// -----------------------------------------------------------------------------
Function GetCloseOfCashRegisterDay(qPeriodFrom, qPeriodTo)
	Return cmGetCloseOfCashRegisterDay(qPeriodFrom, qPeriodTo);	
EndFunction // GetCloseOfCashRegisterDay

// -----------------------------------------------------------------------------
Function GetCloseOfCashRegisterDayPaymentList(qPeriodFrom, qPeriodTo, pCompanyCode)
	Return cmGetCloseOfCashRegisterDayPaymentList(qPeriodFrom, qPeriodTo, pCompanyCode);
EndFunction // GetCloseOfCashRegisterDayPaymentList

// -----------------------------------------------------------------------------
Function GetCompany(qPeriodFrom, qPeriodTo)
	Return cmGetCompany(qPeriodFrom, qPeriodTo);	
EndFunction // GetCompany

// -----------------------------------------------------------------------------
Function GetCustomers(qPeriodFrom, qPeriodTo, qCompanyCode)
	Return cmGetCustomers(qPeriodFrom, qPeriodTo, qCompanyCode);
EndFunction // GetCustomers

// -----------------------------------------------------------------------------
Function GetHotelServices(qPeriodFrom, qPeriodTo, qCompanyCode, qHotelCode) 
	Return  cmGetHotelServices(qPeriodFrom, qPeriodTo, qCompanyCode, qHotelCode);
EndFunction // GetHotelServices

// -----------------------------------------------------------------------------
Function GetIncome(pExternalSystemCode, pHotelCode, pCompanyCode, pAccountingDate)
	WriteLogEvent(NStr("en='Get hotel income';ru='Получить доход гостиницы';de='Hoteleinkommen holen'"), EventLogLevel.Information, , , 
	              NStr("en='External system code: ';ru='Код внешней системы: ';de='Externen System Code: '") + pExternalSystemCode + Chars.LF + 
	              NStr("en='Hotel code: ';ru='Код гостиницы: ';de='Hotel Code: '") + pHotelCode + Chars.LF + 
	              NStr("en='Company code: ';ru='Код организации: ';de='Kompanie Code: '") + pCompanyCode + Chars.LF + 
	              NStr("en='Date: ';ru='Дата: ';de='Datum: '") + pAccountingDate);
	// Try to find hotel by name or code
	vHotel = cmGetHotelByCode(pHotelCode, pExternalSystemCode);
	If Not ValueIsFilled(vHotel) Then
		Raise NStr("en='Failed to get hotel by code '; ru='Не удалось найти гостиницу по коду '; de='Hotel konnte nicht nach Code gefunden werden '") + pHotelCode + "/" + pExternalSystemCode;
	EndIf;
	// Try to find company by name or code
	vCompany = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "Companies", pCompanyCode);
	// Use last closed date if date is not specified
	vAccountingDate = pAccountingDate;
	If Not ValueIsFilled(vAccountingDate) Then
		If ValueIsFilled(vHotel.AccountingDate) Then
			vAccountingDate = vHotel.AccountingDate - 24*3600;
		Else
			Raise NStr("en='Failed to get date!'; ru='Не удалось определить дату!'; de='Datum konnte nicht ermittelt werden!'");
		EndIf;
	EndIf;
	
	// Build return XDTO object
	vIncomeXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "Income"));
	
	// Check what table to use to get income
	vUsePostingsFO = cmUseFOPostingsForIncome(vHotel);
	
	// Fill it with VAT data
	If vUsePostingsFO Then
		vIncomeVATXDTO = GetIncomeVATFromFOPostings(vHotel, vCompany, vAccountingDate, pExternalSystemCode);
	Else
		vIncomeVATXDTO = GetIncomeVAT(vHotel, vCompany, vAccountingDate, pExternalSystemCode);
	EndIf;
	vIncomeXDTO.VAT = vIncomeVATXDTO;
	
	// Fill it with services income data
	If vUsePostingsFO Then
		vIncomeServicesXDTO = GetIncomeServicesFromFOPostings(vHotel, vCompany, vAccountingDate, pExternalSystemCode);
	Else
		vIncomeServicesXDTO = GetIncomeServices(vHotel, vCompany, vAccountingDate, pExternalSystemCode);
	EndIf;
	vIncomeXDTO.Services = vIncomeServicesXDTO;
	
	// Fill it with payments data
	vIncomePaymentsXDTO = GetIncomePayments(vHotel, vCompany, vAccountingDate, pExternalSystemCode, vUsePostingsFO);
	vIncomeXDTO.Payments = vIncomePaymentsXDTO;
	
	// Fill it with invoices data
	vIncomeInvoicesXDTO = GetIncomeInvoices(vHotel, vCompany, vAccountingDate, pExternalSystemCode, vUsePostingsFO);
	vIncomeXDTO.Invoices = vIncomeInvoicesXDTO;
	
	// Fill it with proforma invoices data
	vIncomeProformaInvoicesXDTO = GetIncomeProformaInvoices(vHotel, vCompany, vAccountingDate, pExternalSystemCode, vUsePostingsFO);
	vIncomeXDTO.ProformaInvoices = vIncomeProformaInvoicesXDTO;
	
	Return vIncomeXDTO;
EndFunction // GetIncome

// -----------------------------------------------------------------------------
Function GetInvoiceList(qPeriodFrom, qPeriodTo, qCompanyCode)
	Return cmGetInvoiceList(qPeriodFrom, qPeriodTo, qCompanyCode);	
EndFunction // GetInvoiceList

// -----------------------------------------------------------------------------
Function GetPaymentList(qPeriodFrom, qPeriodTo, qDocNumber, qCashRegisterCode)
	Return cmGetPaymentList(qPeriodFrom, qPeriodTo, qDocNumber, qCashRegisterCode);	
EndFunction // GetPaymentList

// -----------------------------------------------------------------------------
Function GetPaymentMethods(qPeriodFrom, qPeriodTo)
	Return cmGetPaymentMethods(qPeriodFrom, qPeriodTo);
EndFunction // GetPaymentMethods

// -----------------------------------------------------------------------------
Function GetPaymentSections(qPeriodFrom, qPeriodTo, qCompanyCode)
	Return 	cmGetPaymentSections(qPeriodFrom, qPeriodTo, qCompanyCode)
EndFunction // GetPaymentSections

// -----------------------------------------------------------------------------
Function GetProgramVersion()
	Return cmGetProgramVersionAsDateString();
EndFunction // GetProgramVersion

// -----------------------------------------------------------------------------
Function GetServices(qPeriodFrom, qPeriodTo, qCompanyCode) 
	Return  cmGetServices(qPeriodFrom, qPeriodTo, qCompanyCode);
EndFunction // GetServices

// -----------------------------------------------------------------------------
Function GetSettlement(qCompanyCode, qPeriodFrom, qPeriodTo)
	Return cmGetSettlement(qCompanyCode, qPeriodFrom, qPeriodTo);
EndFunction // GetSettlement

// -----------------------------------------------------------------------------
Function GetSettlementTable(qDocNumber, qPeriodFrom, qPeriodTo)
	Return cmGetSettlementTable(qDocNumber, qPeriodFrom, qPeriodTo);	
EndFunction // GetSettlementTable

// -----------------------------------------------------------------------------
Function WriteCashRegisterExtCode(Number, ExternalCode, qPeriodFrom, qPeriodTo)
	Return cmWriteCashRegisterExtCode(Number, ExternalCode, qPeriodFrom, qPeriodTo);
EndFunction // WriteCashRegisterExtCode

// -----------------------------------------------------------------------------
Function WriteCloseOfCashRegisterDayExtCode(pGUID, pExternalCode)
	Return cmWriteCloseOfCashRegisterDayExtCode(pGUID, pExternalCode); 
EndFunction // WriteCloseOfCashRegisterDayExtCode

// -----------------------------------------------------------------------------
Function WriteCloseOfCashRegisterDayPaymentListExtCode(pGUID, pExternalCode, pAccountingCustomerCode, pAccountingCurrencyCode, pPaymentMethodCode, pIsPayment)
	Return cmWriteCloseOfCashRegisterDayPaymentListExtCode(pGUID, pExternalCode, pAccountingCustomerCode, pAccountingCurrencyCode, pPaymentMethodCode, pIsPayment);
EndFunction // WriteCloseOfCashRegisterDayPaymentListExtCode

// -----------------------------------------------------------------------------
Function WriteCompanyExtCode(pCode, pExternalCode)
	Return cmWriteCompanyExtCode(pCode, pExternalCode);
EndFunction // WriteCompanyExtCode

// -----------------------------------------------------------------------------
Function WriteCustomerExtCode(pCode, pExternalCode)
	Return cmWriteCustomerExtCode(pCode, pExternalCode);
EndFunction // WriteCustomerExtCode

// -----------------------------------------------------------------------------
Function WriteInvoiceExtCode(pNumber, pExternalCode, qPeriodFrom, qPeriodTo)
	Return	cmWriteInvoiceExtCode(pNumber, pExternalCode, qPeriodFrom, qPeriodTo);
EndFunction // WriteInvoiceExtCode

// -----------------------------------------------------------------------------
Function WriteInvoicePayment(pHotelCode = Undefined, pCompanyCode = Undefined, pPaymentExternalCode, pPaymentDate, pPaymentNumber, pCustomer, pIsPosted, pIsMarkedDeleted, pPaymentDetails, pRemarks, pExtSystemCode = Undefined, pAccountingCurrencyCode)	
	cmWriteInvoicePayment(pHotelCode, pCompanyCode, pPaymentExternalCode, pPaymentDate, pPaymentNumber, pCustomer, pIsPosted, pIsMarkedDeleted, pPaymentDetails, pRemarks, pExtSystemCode, pAccountingCurrencyCode);
EndFunction // WriteInvoicePayment

// -----------------------------------------------------------------------------
Function WritePaymentMethodsExtCode(pCode, pExternalCode)
	Return cmWritePaymentMethodsExtCode(pCode, pExternalCode);
EndFunction // WritePaymentMethodsExtCode

// -----------------------------------------------------------------------------
Function WritePaymentSectionsExtCode(pCode, pExternalCode)
	 Return cmWritePaymentSectionsExtCode(pCode, pExternalCode);
EndFunction // WritePaymentSectionsExtCode

// -----------------------------------------------------------------------------
Function WriteServicesExtCode(pCode, pExternalCode)
	Return cmWriteServicesExtCode(pCode, pExternalCode);
EndFunction // WriteServicesExtCode

// -----------------------------------------------------------------------------
Function WriteSettlementExtCode(pNumber, pExternalCode, qPeriodFrom, qPeriodTo)
	Return cmWriteSettlementExtCode(pNumber, pExternalCode, qPeriodFrom, qPeriodTo);
EndFunction // WriteSettlementExtCode

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure FillAnalysisItems(pAccountDt, pAccountCr, pIncomeDataXDTO)
	// Analysis items
	vAnalysisItemsDtXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "AnalysisItems"));
	vAnalysisItem1DtXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "AnalysisItem"));
	vAnalysisItem2DtXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "AnalysisItem"));
	If ValueIsFilled(pAccountDt) And ValueIsFilled(pAccountDt.AnalysisItem1) Then
		vAnalysisItem1DtXDTO.Code = TrimAll(pAccountDt.AnalysisItem1.Code);
		vAnalysisItem1DtXDTO.Description = TrimAll(pAccountDt.AnalysisItem1.Description);
	Else
		vAnalysisItem1DtXDTO.Code = "";
		vAnalysisItem1DtXDTO.Description = "";
	EndIf;
	If ValueIsFilled(pAccountDt) And ValueIsFilled(pAccountDt.AnalysisItem2) Then
		vAnalysisItem2DtXDTO.Code = TrimAll(pAccountDt.AnalysisItem2.Code);
		vAnalysisItem2DtXDTO.Description = TrimAll(pAccountDt.AnalysisItem2.Description);
	Else
		vAnalysisItem2DtXDTO.Code = "";
		vAnalysisItem2DtXDTO.Description = "";
	EndIf;
	vAnalysisItemsDtXDTO.AnalysisItem1 = vAnalysisItem1DtXDTO;
	vAnalysisItemsDtXDTO.AnalysisItem2 = vAnalysisItem2DtXDTO;
	pIncomeDataXDTO.AnalysisItemsDt = vAnalysisItemsDtXDTO;

	vAnalysisItemsCrXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "AnalysisItems"));
	vAnalysisItem1CrXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "AnalysisItem"));
	vAnalysisItem2CrXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "AnalysisItem"));
	If ValueIsFilled(pAccountCr) And ValueIsFilled(pAccountCr.AnalysisItem1) Then
		vAnalysisItem1CrXDTO.Code = TrimAll(pAccountCr.AnalysisItem1.Code);
		vAnalysisItem1CrXDTO.Description = TrimAll(pAccountCr.AnalysisItem1.Description);
	Else
		vAnalysisItem1CrXDTO.Code = "";
		vAnalysisItem1CrXDTO.Description = "";
	EndIf;
	If ValueIsFilled(pAccountCr) And ValueIsFilled(pAccountCr.AnalysisItem2) Then
		vAnalysisItem2CrXDTO.Code = TrimAll(pAccountCr.AnalysisItem2.Code);
		vAnalysisItem2CrXDTO.Description = TrimAll(pAccountCr.AnalysisItem2.Description);
	Else
		vAnalysisItem2CrXDTO.Code = "";
		vAnalysisItem2CrXDTO.Description = "";
	EndIf;
	vAnalysisItemsCrXDTO.AnalysisItem1 = vAnalysisItem1CrXDTO;
	vAnalysisItemsCrXDTO.AnalysisItem2 = vAnalysisItem2CrXDTO;
	pIncomeDataXDTO.AnalysisItemsCr = vAnalysisItemsCrXDTO;
EndProcedure // FillAnalysisItems

// -----------------------------------------------------------------------------
Procedure FillAnalysisItem(pAccount, pIncomeDataXDTO)
	// Analysis item
	vAnalysisItemsXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "AnalysisItems"));
	vAnalysisItem1XDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "AnalysisItem"));
	vAnalysisItem2XDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "AnalysisItem"));
	If ValueIsFilled(pAccount) And ValueIsFilled(pAccount.AnalysisItem1) Then
		vAnalysisItem1XDTO.Code = TrimAll(pAccount.AnalysisItem1.Code);
		vAnalysisItem1XDTO.Description = TrimAll(pAccount.AnalysisItem1.Description);
	Else
		vAnalysisItem1XDTO.Code = "";
		vAnalysisItem1XDTO.Description = "";
	EndIf;
	If ValueIsFilled(pAccount) And ValueIsFilled(pAccount.AnalysisItem2) Then
		vAnalysisItem2XDTO.Code = TrimAll(pAccount.AnalysisItem2.Code);
		vAnalysisItem2XDTO.Description = TrimAll(pAccount.AnalysisItem2.Description);
	Else
		vAnalysisItem2XDTO.Code = "";
		vAnalysisItem2XDTO.Description = "";
	EndIf;
	vAnalysisItemsXDTO.AnalysisItem1 = vAnalysisItem1XDTO;
	vAnalysisItemsXDTO.AnalysisItem2 = vAnalysisItem2XDTO;
	pIncomeDataXDTO.AnalysisItems = vAnalysisItemsXDTO;
EndProcedure // FillAnalysisItem

// -----------------------------------------------------------------------------
Function GetIncomeVAT(pHotel, pCompany, pAccountingDate, pExternalSystemCode)
	vIncomeVATXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomeVAT"));
	
	// Run query to get data
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SalesMovements.AccountingDate AS AccountingDate,
	|	SalesMovements.VATRate AS VATRate,
	|	SalesMovements.VATRate.Description AS VATRateDescription,
	|	ISNULL(VATRatesHistory.TaxRate, SalesMovements.VATRate.TaxRate) AS TaxRate,
	|	ISNULL(SalesMovements.VATRate.NoVAT, FALSE) AS NoVAT,
	|	SUM(SalesMovements.VATSum) AS VATSum
	|FROM
	|	AccumulationRegister.Sales AS SalesMovements
	|		LEFT JOIN InformationRegister.VATRatesHistory.SliceLast(&qAccountingDate, ) AS VATRatesHistory
	|		ON SalesMovements.VATRate = VATRatesHistory.VATRate
	|WHERE
	|	SalesMovements.AccountingDate = &qAccountingDate
	|	AND SalesMovements.Hotel = &qHotel
	|	AND (&qCompanyIsEmpty
	|			OR NOT &qCompanyIsEmpty
	|				AND SalesMovements.Company = &qCompany)
	|
	|GROUP BY
	|	SalesMovements.AccountingDate,
	|	SalesMovements.VATRate,
	|	SalesMovements.VATRate.Description,
	|	ISNULL(VATRatesHistory.TaxRate, SalesMovements.VATRate.TaxRate),
	|	ISNULL(SalesMovements.VATRate.NoVAT, FALSE)
	|
	|ORDER BY
	|	TaxRate";
	vQry.SetParameter("qAccountingDate", pAccountingDate);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qCompany", pCompany);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(pCompany));
	
	vTotals = vQry.Execute().Unload();
	
	For Each vRow In vTotals Do
		vAccountCode = "";
		vAccountStruct = cmGetAccountCodeForVATRate(pHotel, pCompany, vRow.VATRate);
		vAccount = vAccountStruct.Account;
		If Not IsBlankString(vAccountStruct.Code) Then
			vAccountCode = TrimAll(vAccountStruct.Code);
		ElsIf ValueIsFilled(vAccount) And Not IsBlankString(vAccount.CodeBO) Then
			vAccountCode = TrimAll(vAccount.CodeBO);
		EndIf;
		If IsBlankString(vAccountCode) Then
			Raise NStr("en='Failed to get account code for the VAT rate: '; ru='Ошибка получения номера счета бухгалтерии для ставки НДС: '; de='Fehler beim Abrufen des Kontocodes für den Mehrwertsteuersatz: '") + vRow.VATRateDescription + ", " + pHotel + ", " + pCompany;
		EndIf;
		
		vIncomeVATRateXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomeVATRate"));
		
		vIncomeVATRateXDTO.AccountingDate = vRow.AccountingDate;
		vIncomeVATRateXDTO.VATRateName = vRow.VATRateDescription;
		vIncomeVATRateXDTO.VATTaxRate = ?(vRow.NoVAT, -1, vRow.TaxRate);
		vIncomeVATRateXDTO.Amount = vRow.VATSum;
		vIncomeVATRateXDTO.AccountCode = vAccountCode;
		
		vIncomeVATXDTO.IncomeVATRate.Add(vIncomeVATRateXDTO);
	EndDo;
	
	Return vIncomeVATXDTO;
EndFunction // GetIncomeVAT

// -----------------------------------------------------------------------------
Function GetIncomeVATFromFOPostings(pHotel, pCompany, pAccountingDate, pExternalSystemCode)
	vIncomeVATXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomeVAT"));
	
	// Run query to get data
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	BEGINOFPERIOD(SalesMovements.Period, DAY) AS AccountingDate,
	|	SalesMovements.Account AS Account,
	|	SalesMovements.VATRate AS VATRate,
	|	SalesMovements.VATRate.Description AS VATRateDescription,
	|	ISNULL(VATRatesHistory.TaxRate, SalesMovements.VATRate.TaxRate) AS TaxRate,
	|	ISNULL(SalesMovements.VATRate.NoVAT, FALSE) AS NoVAT,
	|	SUM(CASE
	|			WHEN SalesMovements.RecordType = VALUE(AccountingRecordType.Credit)
	|				THEN SalesMovements.Amount
	|			ELSE -SalesMovements.Amount
	|		END) AS VATSum
	|FROM
	|	AccountingRegister.PostingsFO AS SalesMovements
	|		LEFT JOIN InformationRegister.VATRatesHistory.SliceLast(&qAccountingDate, ) AS VATRatesHistory
	|		ON SalesMovements.VATRate = VATRatesHistory.VATRate
	|WHERE
	|	BEGINOFPERIOD(SalesMovements.Period, DAY) = &qAccountingDate
	|	AND SalesMovements.Account.IsVATAccount
	|	AND SalesMovements.Hotel = &qHotel
	|	AND (&qCompanyIsEmpty
	|			OR NOT &qCompanyIsEmpty
	|				AND SalesMovements.Company = &qCompany)
	|
	|GROUP BY
	|	BEGINOFPERIOD(SalesMovements.Period, DAY),
	|	SalesMovements.Account,
	|	SalesMovements.VATRate,
	|	SalesMovements.VATRate.Description,
	|	ISNULL(VATRatesHistory.TaxRate, SalesMovements.VATRate.TaxRate),
	|	ISNULL(SalesMovements.VATRate.NoVAT, FALSE)
	|
	|ORDER BY
	|	TaxRate";
	vQry.SetParameter("qAccountingDate", pAccountingDate);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qCompany", pCompany);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(pCompany));
	
	vTotals = vQry.Execute().Unload();
	
	For Each vRow In vTotals Do
		vAccountCode = "";
		vAccount = vRow.Account;
		If Not IsBlankString(vAccount.CodeBO) Then
			vAccountCode = TrimAll(vAccount.CodeBO);
		Else
			vAccountCode = TrimAll(vAccount.Code);
		EndIf;
		If IsBlankString(vAccountCode) Then
			Raise NStr("en='Failed to get account code for the VAT rate: '; ru='Ошибка получения номера счета бухгалтерии для ставки НДС: '; de='Fehler beim Abrufen des Kontocodes für den Mehrwertsteuersatz: '") + vRow.VATRateDescription + ", " + pHotel + ", " + pCompany;
		EndIf;
		
		vIncomeVATRateXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomeVATRate"));
		
		vIncomeVATRateXDTO.AccountingDate = vRow.AccountingDate;
		vIncomeVATRateXDTO.VATRateName = vRow.VATRateDescription;
		vIncomeVATRateXDTO.VATTaxRate = ?(vRow.NoVAT, -1, vRow.TaxRate);
		vIncomeVATRateXDTO.Amount = vRow.VATSum;
		vIncomeVATRateXDTO.AccountCode = vAccountCode;
		
		// Analysis items
		FillAnalysisItem(vAccount, vIncomeVATRateXDTO);
		
		vIncomeVATXDTO.IncomeVATRate.Add(vIncomeVATRateXDTO);
	EndDo;
	
	Return vIncomeVATXDTO;
EndFunction // GetIncomeVATFromFOPostings

// -----------------------------------------------------------------------------
Function GetIncomeServices(pHotel, pCompany, pAccountingDate, pExternalSystemCode)
	vIncomeServicesXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomeServices"));
	
	// Run query to get data
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	IncomePostings.AccountingDate AS AccountingDate,
	|	IncomePostings.Service AS Service,
	|	IncomePostings.Service.Code AS ServiceCode,
	|	IncomePostings.Service.Description AS ServiceDescription,
	|	IncomePostings.VATRate AS VATRate,
	|	ISNULL(IncomePostings.VATRate.Description, """") AS VATRateDescription,
	|	ISNULL(IncomePostings.VATRate.NoVAT, FALSE) AS NoVAT,
	|	ISNULL(VATRatesHistory.TaxRate, IncomePostings.VATRate.TaxRate) AS TaxRate,
	|	SUM(IncomePostings.SumWithoutVAT) AS SumWithoutVAT,
	|	SUM(IncomePostings.VATSum) AS VATSum
	|FROM
	|	(SELECT
	|		SalesMovements.AccountingDate AS AccountingDate,
	|		SalesMovements.ReportingCurrency AS Currency,
	|		SalesMovements.Service AS Service,
	|		SalesMovements.VATRate AS VATRate,
	|		SalesMovements.SalesWithoutVAT AS SumWithoutVAT,
	|		SalesMovements.VATSum AS VATSum
	|	FROM
	|		AccumulationRegister.Sales AS SalesMovements
	|	WHERE
	|		SalesMovements.AccountingDate = &qAccountingDate
	|		AND SalesMovements.Hotel = &qHotel
	|		AND NOT SalesMovements.Service.DoNotExportToTheAccountingSystem
	|		AND (&qCompanyIsEmpty
	|				OR NOT &qCompanyIsEmpty
	|					AND SalesMovements.Company = &qCompany)
	|		AND NOT SalesMovements.IsCorrection) AS IncomePostings
	|		LEFT JOIN InformationRegister.VATRatesHistory.SliceLast(&qAccountingDate, ) AS VATRatesHistory
	|		ON IncomePostings.VATRate = VATRatesHistory.VATRate
	|
	|GROUP BY
	|	IncomePostings.AccountingDate,
	|	IncomePostings.Service,
	|	IncomePostings.VATRate,
	|	IncomePostings.Service.Code,
	|	IncomePostings.Service.Description,
	|	IncomePostings.VATRate.Description,
	|	ISNULL(IncomePostings.VATRate.NoVAT, FALSE),
	|	ISNULL(VATRatesHistory.TaxRate, IncomePostings.VATRate.TaxRate)
	|
	|ORDER BY
	|	ServiceCode,
	|	TaxRate";
	vQry.SetParameter("qAccountingDate", pAccountingDate);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qCompany", pCompany);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(pCompany));
	
	vTotals = vQry.Execute().Unload();
	
	For Each vRow In vTotals Do
		vAccountCode = "";
		vAccountCodeDt = "";
		vAccountCodeCr = "";
		vAccountStruct = cmGetAccountCodeForService(pHotel, pCompany, vRow.Service, vRow.VATRate, pAccountingDate);
		If Not IsBlankString(vAccountStruct.CodeDt) Or Not IsBlankString(vAccountStruct.CodeCr)Then
			vAccountCodeDt = TrimAll(vAccountStruct.CodeDt);
			vAccountCodeCr = TrimAll(vAccountStruct.CodeCr);
		ElsIf Not IsBlankString(vAccountStruct.Code) Then
			vAccountCode = TrimAll(vAccountStruct.Code);
		ElsIf ValueIsFilled(vAccountStruct.Account) And Not IsBlankString(vAccountStruct.Account.CodeBO) Then
			vAccountCode = TrimAll(vAccountStruct.Account.CodeBO);
		EndIf;
		If IsBlankString(vAccountCode) Then
			Raise NStr("en='Failed to get account code for the service / VAT rate: '; ru='Ошибка получения номера счета бухгалтерии для услуги / ставки НДС: '; de='Fehler beim Abrufen des Kontocodes für den Service / Mehrwertsteuersatz: '") + vRow.ServiceDescription + " / " + vRow.VATRateDescription + ", " + pHotel + ", " + pCompany;
		EndIf;
		
		vDepartmentCode = "";
		If ValueIsFilled(vRow.Service) And ValueIsFilled(vRow.Service.DepartmentCode) Then
			vDepartmentCodeRef = vRow.Service.DepartmentCode;
			If Not IsBlankString(vDepartmentCodeRef.CodeBO) Then
				vDepartmentCode = TrimAll(vDepartmentCodeRef.CodeBO);
			Else
				vDepartmentCode = TrimAll(vDepartmentCodeRef.Code);
			EndIf;
		EndIf;
		
		vIncomeServiceXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomeService"));
		
		vIncomeServiceXDTO.AccountingDate = vRow.AccountingDate;
		vIncomeServiceXDTO.ServiceName = vRow.ServiceDescription;
		vIncomeServiceXDTO.VATRateName = vRow.VATRateDescription;
		If vRow.NoVAT Then
			vIncomeServiceXDTO.VATTaxRate = -1;
		Else
			vIncomeServiceXDTO.VATTaxRate = vRow.TaxRate;
		EndIf;
		vIncomeServiceXDTO.Amount = vRow.SumWithoutVAT;
		vIncomeServiceXDTO.VATAmount = vRow.VATSum;
		vIncomeServiceXDTO.AccountCode = vAccountCode;
		vIncomeServiceXDTO.DepartmentCode = vDepartmentCode;
		vIncomeServiceXDTO.AccountCodeDt = vAccountCodeDt;
		vIncomeServiceXDTO.AccountCodeCr = vAccountCodeCr;
		
		vIncomeServicesXDTO.IncomeService.Add(vIncomeServiceXDTO);
	EndDo;
	
	Return vIncomeServicesXDTO;
EndFunction // GetIncomeServices

// -----------------------------------------------------------------------------
Function GetIncomeServicesFromFOPostings(pHotel, pCompany, pAccountingDate, pExternalSystemCode)
	vIncomeServicesXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomeServices"));
	
	// Run query to get data
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	IncomePostings.AccountingDate AS AccountingDate,
	|	IncomePostings.RecordType AS RecordType,
	|	IncomePostings.Account AS Account,
	|	IncomePostings.CorrAccount AS CorrAccount,
	|	IncomePostings.Service AS Service,
	|	IncomePostings.Service.Code AS ServiceCode,
	|	IncomePostings.Service.Description AS ServiceDescription,
	|	IncomePostings.VATRate AS VATRate,
	|	ISNULL(IncomePostings.VATRate.Description, """") AS VATRateDescription,
	|	ISNULL(IncomePostings.VATRate.NoVAT, FALSE) AS NoVAT,
	|	ISNULL(VATRatesHistory.TaxRate, IncomePostings.VATRate.TaxRate) AS TaxRate,
	|	SUM(IncomePostings.SumWithoutVAT) AS SumWithoutVAT,
	|	SUM(IncomePostings.VATSum) AS VATSum
	|FROM
	|	(SELECT
	|		BEGINOFPERIOD(SalesMovements.Period, DAY) AS AccountingDate,
	|		SalesMovements.RecordType AS RecordType,
	|		SalesMovements.Account AS Account,
	|		SalesMovements.CorrAccount AS CorrAccount,
	|		SalesMovements.Currency AS Currency,
	|		SalesMovements.Service AS Service,
	|		SalesMovements.VATRate AS VATRate,
	|		SalesMovements.Amount AS SumWithoutVAT,
	|		SalesMovements.VATAmount AS VATSum
	|	FROM
	|		AccountingRegister.PostingsFO AS SalesMovements
	|	WHERE
	|		BEGINOFPERIOD(SalesMovements.Period, DAY) = &qAccountingDate
	|		AND SalesMovements.Hotel = &qHotel
	|		AND (SalesMovements.Account.AccountGroup = VALUE(Catalog.AccountGroups.Income)
	|				OR SalesMovements.Account.AccountGroup = VALUE(Catalog.AccountGroups.Liabilities))
	|		AND NOT ISNULL(SalesMovements.Service.DoNotExportToTheAccountingSystem, FALSE)
	|		AND SalesMovements.Account <> VALUE(ChartOfAccounts.ChartOfAccountsFO.GuestLedger)
	|		AND (&qCompanyIsEmpty
	|				OR NOT &qCompanyIsEmpty
	|					AND SalesMovements.Company = &qCompany)) AS IncomePostings
	|		LEFT JOIN InformationRegister.VATRatesHistory.SliceLast(&qAccountingDate, ) AS VATRatesHistory
	|		ON IncomePostings.VATRate = VATRatesHistory.VATRate
	|
	|GROUP BY
	|	IncomePostings.AccountingDate,
	|	IncomePostings.RecordType,
	|	IncomePostings.Account,
	|	IncomePostings.CorrAccount,
	|	IncomePostings.Service,
	|	IncomePostings.VATRate,
	|	IncomePostings.Service.Code,
	|	IncomePostings.Service.Description,
	|	ISNULL(IncomePostings.VATRate.NoVAT, FALSE),
	|	ISNULL(VATRatesHistory.TaxRate, IncomePostings.VATRate.TaxRate),
	|	ISNULL(IncomePostings.VATRate.Description, """")
	|
	|ORDER BY
	|	ServiceCode,
	|	TaxRate";
	vQry.SetParameter("qAccountingDate", pAccountingDate);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qCompany", pCompany);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(pCompany));
	
	vTotals = vQry.Execute().Unload();
	
	For Each vRow In vTotals Do
		vAccount = vRow.Account;
		vAccountCode = TrimAll(?(IsBlankString(vAccount.CodeBO), vAccount.Code, vAccount.CodeBO));
		vCorrAccount = vRow.CorrAccount;
		vCorrAccountCode = TrimAll(?(IsBlankString(vCorrAccount.CodeBO), vCorrAccount.Code, vCorrAccount.CodeBO));
		
		vAccountCr = Undefined;
		vAccountDt = Undefined;
		If vRow.RecordType = AccountingRecordType.Credit Then
			vAccountCr = vAccount;
			vAccountDt = vCorrAccount;
			vAccountCodeCr = vAccountCode;
			vAccountCodeDt = vCorrAccountCode;
		Else
			vAccountCr = vCorrAccount;
			vAccountDt = vAccount;
			vAccountCodeCr = vCorrAccountCode;
			vAccountCodeDt = vAccountCode;
		EndIf;
		
		vDepartmentCode = "";
		If ValueIsFilled(vRow.Service) And ValueIsFilled(vRow.Service.DepartmentCode) Then
			vDepartmentCodeRef = vRow.Service.DepartmentCode;
			If Not IsBlankString(vDepartmentCodeRef.CodeBO) Then
				vDepartmentCode = TrimAll(vDepartmentCodeRef.CodeBO);
			Else
				vDepartmentCode = TrimAll(vDepartmentCodeRef.Code);
			EndIf;
		EndIf;
		
		vIncomeServiceXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomeService"));
		
		vIncomeServiceXDTO.AccountingDate = vRow.AccountingDate;
		vIncomeServiceXDTO.ServiceName = vRow.ServiceDescription;
		vIncomeServiceXDTO.VATRateName = vRow.VATRateDescription;
		If vRow.NoVAT Then
			vIncomeServiceXDTO.VATTaxRate = -1;
		Else
			vIncomeServiceXDTO.VATTaxRate = vRow.TaxRate;
		EndIf;
		If vRow.RecordType = AccountingRecordType.Credit Then
			vIncomeServiceXDTO.Amount = vRow.SumWithoutVAT;
			vIncomeServiceXDTO.VATAmount = vRow.VATSum;
		Else
			vIncomeServiceXDTO.Amount = -vRow.SumWithoutVAT;
			vIncomeServiceXDTO.VATAmount = -vRow.VATSum;
		EndIf;
		vIncomeServiceXDTO.AccountCode = vAccountCode;
		vIncomeServiceXDTO.DepartmentCode = vDepartmentCode;
		vIncomeServiceXDTO.AccountCodeDt = vAccountCodeDt;
		vIncomeServiceXDTO.AccountCodeCr = vAccountCodeCr;
		
		// Analysis items
		FillAnalysisItems(vAccountDt, vAccountCr, vIncomeServiceXDTO);
		
		vIncomeServicesXDTO.IncomeService.Add(vIncomeServiceXDTO);
	EndDo;
	
	Return vIncomeServicesXDTO;
EndFunction // GetIncomeServicesFromFOPostings

// -----------------------------------------------------------------------------
Function GetIncomePayments(pHotel, pCompany, pAccountingDate, pExternalSystemCode, pUsePostingsFOData = False)
	vIncomePaymentsXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomePayments"));
	
	// Some initialization
	vClearedPayments = New ValueList(); 
	
	// Run query to get data
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	AllPayments.PaymentRef AS PaymentRef,
	|	AllPayments.Hotel AS Hotel,
	|	AllPayments.Invoice AS Invoice,
	|	AllPayments.Customer AS Customer,
	|	AllPayments.Client AS Client,
	|	AllPayments.PaymentMethod AS PaymentMethod,
	|	AllPayments.PaymentSection AS PaymentSection,
	|	AllPayments.DiscountCard AS DiscountCard,
	|	AllPayments.FinancialAccount AS FinancialAccount
	|INTO AllPayments
	|FROM
	|	(SELECT
	|		Payments.Ref AS PaymentRef,
	|		Payments.Hotel AS Hotel,
	|		Payments.Invoice AS Invoice,
	|		Payments.AccountingCustomer AS Customer,
	|		Payments.Folio.Client AS Client,
	|		Payments.PaymentMethod AS PaymentMethod,
	|		Payments.PaymentSection AS PaymentSection,
	|		Payments.DiscountCard AS DiscountCard,
	|		Payments.Folio.FinancialAccount AS FinancialAccount
	|	FROM
	|		Document.Payment AS Payments
	|	WHERE
	|		Payments.AccountingDate = &qAccountingDate
	|		AND Payments.Hotel = &qHotel
	|		AND Payments.Posted
	|		AND (&qCompanyIsEmpty
	|				OR NOT &qCompanyIsEmpty
	|					AND Payments.Company = &qCompany)
	|		AND NOT ISNULL(Payments.PaymentMethod.DoNotExportToTheAccountingSystem, FALSE)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Returns.Ref,
	|		Returns.Hotel,
	|		Returns.Invoice,
	|		Returns.AccountingCustomer,
	|		Returns.Folio.Client,
	|		Returns.PaymentMethod,
	|		Returns.PaymentSection,
	|		Returns.DiscountCard,
	|		Returns.Folio.FinancialAccount
	|	FROM
	|		Document.Return AS Returns
	|	WHERE
	|		Returns.AccountingDate = &qAccountingDate
	|		AND Returns.Hotel = &qHotel
	|		AND Returns.Posted
	|		AND (&qCompanyIsEmpty
	|				OR NOT &qCompanyIsEmpty
	|					AND Returns.Company = &qCompany)
	|		AND NOT ISNULL(Returns.PaymentMethod.DoNotExportToTheAccountingSystem, FALSE)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CustomerPayments.Ref,
	|		CustomerPayments.Hotel,
	|		CustomerPayments.Invoice,
	|		CustomerPayments.AccountingCustomer,
	|		CustomerPayments.GuestGroup.Client,
	|		CustomerPayments.PaymentMethod,
	|		CustomerPayments.PaymentSection,
	|		VALUE(Catalog.DiscountCards.EmptyRef),
	|		NULL
	|	FROM
	|		Document.CustomerPayment AS CustomerPayments
	|	WHERE
	|		CustomerPayments.AccountingDate = &qAccountingDate
	|		AND CustomerPayments.Hotel = &qHotel
	|		AND CustomerPayments.Posted
	|		AND (&qCompanyIsEmpty
	|				OR NOT &qCompanyIsEmpty
	|					AND CustomerPayments.Company = &qCompany)
	|		AND NOT CustomerPayments.PaymentMethod.DoNotExportToTheAccountingSystem) AS AllPayments
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PrepaymentDocs.PaymentRef AS PaymentRef,
	|	PrepaymentDocs.Invoice AS ProformaInvoice,
	|	PrepaymentDocs.Customer AS Customer,
	|	PrepaymentDocs.Client AS Client,
	|	PrepaymentDocs.PaymentMethod AS PaymentMethod,
	|	PrepaymentDocs.PaymentSection AS PaymentSection,
	|	PrepaymentDocs.DiscountCard AS DiscountCard,
	|	PrepaymentDocs.FinancialAccount AS FinancialAccount
	|INTO PrepaymentDocs
	|FROM
	|	AllPayments AS PrepaymentDocs
	|WHERE
	|	ISNULL(PrepaymentDocs.Hotel.PaymentsGenerateInvoices, FALSE)
	|	AND NOT PrepaymentDocs.Invoice.Number IS NULL
	|	AND PrepaymentDocs.Invoice REFS Document.ProformaInvoice
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PaymentDocs.PaymentRef AS PaymentRef,
	|	PaymentDocs.Invoice AS Invoice,
	|	PaymentDocs.Customer AS Customer,
	|	PaymentDocs.Client AS Client,
	|	PaymentDocs.PaymentMethod AS PaymentMethod,
	|	PaymentDocs.PaymentSection AS PaymentSection,
	|	PaymentDocs.DiscountCard AS DiscountCard,
	|	PaymentDocs.FinancialAccount AS FinancialAccount
	|INTO PaymentDocs
	|FROM
	|	AllPayments AS PaymentDocs
	|WHERE
	|	(NOT ISNULL(PaymentDocs.Hotel.PaymentsGenerateInvoices, FALSE)
	|			OR PaymentDocs.Invoice.Number IS NULL
	|			OR NOT PaymentDocs.Invoice REFS Document.ProformaInvoice)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PrepaymentDocs.PaymentRef AS PaymentRef,
	|	PrepaymentDocs.Customer AS Customer,
	|	PrepaymentDocs.Client AS Client,
	|	PrepaymentDocs.PaymentRef.CashRegister AS CashRegister,
	|	PrepaymentDocs.ProformaInvoice AS ProformaInvoice,
	|	PrepaymentDocs.PaymentMethod AS PaymentMethod,
	|	PrepaymentDocs.PaymentSection AS PaymentSection,
	|	PrepaymentDocs.DiscountCard AS DiscountCard,
	|	PrepaymentDocs.FinancialAccount AS FinancialAccount,
	|	ProformaServices.Service AS Service,
	|	ProformaServices.VATRate AS VATRAte,
	|	ProformaServices.Ref.AccountingCurrency AS Currency,
	|	SUM(ProformaServices.Sum - ProformaServices.VATSum) AS SumWithoutVAT,
	|	SUM(ProformaServices.VATSum) AS VATSum
	|INTO PrepaymentAmounts
	|FROM
	|	Document.ProformaInvoice.Services AS ProformaServices
	|		INNER JOIN PrepaymentDocs AS PrepaymentDocs
	|		ON ProformaServices.Ref = PrepaymentDocs.ProformaInvoice
	|
	|GROUP BY
	|	PrepaymentDocs.PaymentRef,
	|	PrepaymentDocs.Customer,
	|	PrepaymentDocs.Client,
	|	PrepaymentDocs.PaymentRef.CashRegister,
	|	PrepaymentDocs.ProformaInvoice,
	|	PrepaymentDocs.PaymentMethod,
	|	PrepaymentDocs.PaymentSection,
	|	PrepaymentDocs.DiscountCard,
	|	PrepaymentDocs.FinancialAccount,
	|	ProformaServices.Service,
	|	ProformaServices.VATRate,
	|	ProformaServices.Ref.AccountingCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PaymentDocs.PaymentRef AS PaymentRef,
	|	PaymentDocs.Customer AS Customer,
	|	PaymentDocs.Client AS Client,
	|	PaymentDocs.PaymentRef.CashRegister AS CashRegister,
	|	PaymentDocs.Invoice AS Invoice,
	|	PaymentDocs.PaymentMethod AS PaymentMethod,
	|	PaymentDocs.PaymentSection AS PaymentSection,
	|	PaymentDocs.DiscountCard AS DiscountCard,
	|	PaymentDocs.FinancialAccount AS FinancialAccount,
	|	NULL AS Service,
	|	PaymentDocs.PaymentRef.VATRate AS VATRate,
	|	PaymentDocs.PaymentRef.PaymentCurrency AS Currency,
	|	SUM(CASE
	|			WHEN PaymentDocs.PaymentRef REFS Document.Return
	|				THEN -(PaymentDocs.PaymentRef.Sum - PaymentDocs.PaymentRef.VATSum)
	|			ELSE PaymentDocs.PaymentRef.Sum - PaymentDocs.PaymentRef.VATSum
	|		END) AS SumWithoutVAT,
	|	SUM(CASE
	|			WHEN PaymentDocs.PaymentRef REFS Document.Return
	|				THEN -PaymentDocs.PaymentRef.VATSum
	|			ELSE PaymentDocs.PaymentRef.VATSum
	|		END) AS VATSum
	|INTO PaymentAmounts
	|FROM
	|	PaymentDocs AS PaymentDocs
	|
	|GROUP BY
	|	PaymentDocs.PaymentRef,
	|	PaymentDocs.Customer,
	|	PaymentDocs.Client,
	|	PaymentDocs.PaymentRef.CashRegister,
	|	PaymentDocs.Invoice,
	|	PaymentDocs.PaymentMethod,
	|	PaymentDocs.PaymentSection,
	|	PaymentDocs.DiscountCard,
	|	PaymentDocs.FinancialAccount,
	|	PaymentDocs.PaymentRef.VATRate,
	|	PaymentDocs.PaymentRef.PaymentCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&qAccountingDate AS AccountingDate,
	|	ExportPayments.PaymentDocument AS PaymentDoc,
	|	ExportPayments.PaymentDocument.DiscountCard AS DiscountCard,
	|	CASE
	|		WHEN NOT ExportPayments.Customer IS NULL
	|			THEN ExportPayments.Customer
	|		ELSE ExportPayments.Client
	|	END AS Customer,
	|	CASE
	|		WHEN NOT ExportPayments.Customer IS NULL
	|			THEN ISNULL(ExportPayments.Customer.Code, """")
	|		ELSE ISNULL(ExportPayments.Client.Code, """")
	|	END AS CustomerCode,
	|	CASE
	|		WHEN NOT ExportPayments.Customer IS NULL
	|			THEN CAST(ExportPayments.Customer.LegacyName AS STRING(999))
	|		ELSE CAST(ISNULL(ExportPayments.Client.FullName, """") AS STRING(999))
	|	END AS CustomerDescription,
	|	CASE
	|		WHEN NOT ExportPayments.Customer IS NULL
	|			THEN CAST(ExportPayments.Customer.LegacyAddress AS STRING(999))
	|		ELSE CAST(ISNULL(ExportPayments.Client.Address, """") AS STRING(999))
	|	END AS CustomerAddress,
	|	CASE
	|		WHEN NOT ExportPayments.Customer IS NULL
	|			THEN ISNULL(ExportPayments.Customer.Country.Code, 0)
	|		ELSE ISNULL(ExportPayments.Client.Citizenship.Code, 0)
	|	END AS CustomerCountryCode,
	|	CASE
	|		WHEN NOT ExportPayments.Customer IS NULL
	|			THEN ISNULL(ExportPayments.Customer.Country.ISOCode, """")
	|		ELSE ISNULL(ExportPayments.Client.Citizenship.ISOCode, """")
	|	END AS CustomerCountryISOCode,
	|	CASE
	|		WHEN NOT ExportPayments.Customer IS NULL
	|			THEN ISNULL(ExportPayments.Customer.Country.ISOCode3, """")
	|		ELSE ISNULL(ExportPayments.Client.Citizenship.ISOCode3, """")
	|	END AS CustomerCountryISOCode3,
	|	CASE
	|		WHEN NOT ExportPayments.Customer IS NULL
	|			THEN ISNULL(ExportPayments.Customer.Phone, """")
	|		ELSE ISNULL(ExportPayments.Client.Phone, """")
	|	END AS CustomerPhone,
	|	CASE
	|		WHEN NOT ExportPayments.Customer IS NULL
	|			THEN ISNULL(ExportPayments.Customer.EMail, """")
	|		ELSE ISNULL(ExportPayments.Client.EMail, """")
	|	END AS CustomerEMail,
	|	CASE
	|		WHEN NOT ExportPayments.Customer IS NULL
	|			THEN ISNULL(ExportPayments.Customer.TIN, """")
	|		ELSE ISNULL(ExportPayments.Client.TIN, """")
	|	END AS CustomerTIN,
	|	CASE
	|		WHEN NOT ExportPayments.Customer IS NULL
	|			THEN ISNULL(ExportPayments.Customer.VATC, """")
	|		ELSE """"
	|	END AS CustomerVATCode,
	|	CASE
	|		WHEN NOT ExportPayments.Customer IS NULL
	|			THEN ExportPayments.Customer.DateOfBirth
	|		ELSE ExportPayments.Client.DateOfBirth
	|	END AS CustomerDateOfBirth,
	|	CASE
	|		WHEN NOT ExportPayments.Customer IS NULL
	|			THEN ExportPayments.Customer.IsIndividual
	|		ELSE TRUE
	|	END AS CustomerIsIndividual,
	|	ExportPayments.Currency AS Currency,
	|	ExportPayments.PaymentMethod AS PaymentMethod,
	|	ISNULL(ExportPayments.PaymentMethod.SortCode, 0) AS PaymentMethodSortCode,
	|	ISNULL(ExportPayments.PaymentMethod.Description, """") AS PaymentMethodDescription,
	|	ISNULL(ExportPayments.PaymentMethod.IsByGiftCertificate, FALSE) AS IsByGiftCertificate,
	|	ISNULL(ExportPayments.PaymentSection, VALUE(Catalog.PaymentSections.EmptyRef)) AS PaymentSection,
	|	ISNULL(ExportPayments.PaymentSection.Code, 0) AS PaymentSectionCode,
	|	ExportPayments.CashRegister AS CashRegister,
	|	ISNULL(ExportPayments.CashRegister.Code, """") AS CashRegisterCode,
	|	ISNULL(ExportPayments.CashRegister.Description, """") AS CashRegisterDescription,
	|	ExportPayments.FinancialAccount AS FinancialAccount,
	|	ExportPayments.VATRate AS VATRate,
	|	ISNULL(ExportPayments.VATRate.Description, """") AS VATRateDescription,
	|	ISNULL(ExportPayments.VATRate.NoVAT, FALSE) AS NoVAT,
	|	ISNULL(VATRatesHistory.TaxRate, ExportPayments.VATRate.TaxRate) AS VATTaxRate,
	|	ExportPayments.Service AS Service,
	|	ExportPayments.IsPrepayment AS IsPrepayment,
	|	ExportPayments.Invoice AS Invoice,
	|	ExportPayments.SumWithoutVAT AS SumWithoutVAT,
	|	ExportPayments.VATSum AS VATSum
	|FROM
	|	(SELECT
	|		CASE
	|			WHEN Prepayments.Customer <> Prepayments.PaymentRef.Hotel.IndividualsCustomer
	|					AND Prepayments.Customer <> &qEmptyCustomer
	|				THEN Prepayments.Customer
	|			ELSE NULL
	|		END AS Customer,
	|		Prepayments.Client AS Client,
	|		Prepayments.Currency AS Currency,
	|		Prepayments.PaymentRef AS PaymentDocument,
	|		Prepayments.PaymentMethod AS PaymentMethod,
	|		Prepayments.PaymentSection AS PaymentSection,
	|		Prepayments.CashRegister AS CashRegister,
	|		Prepayments.FinancialAccount AS FinancialAccount,
	|		Prepayments.VATRAte AS VATRate,
	|		Prepayments.Service AS Service,
	|		TRUE AS IsPrepayment,
	|		NULL AS Invoice,
	|		Prepayments.SumWithoutVAT AS SumWithoutVAT,
	|		Prepayments.VATSum AS VATSum
	|	FROM
	|		PrepaymentAmounts AS Prepayments
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CASE
	|			WHEN Payments.Customer <> Payments.PaymentRef.Hotel.IndividualsCustomer
	|					AND Payments.Customer <> &qEmptyCustomer
	|				THEN Payments.Customer
	|			ELSE NULL
	|		END,
	|		Payments.Client,
	|		Payments.Currency,
	|		Payments.PaymentRef,
	|		Payments.PaymentMethod,
	|		Payments.PaymentSection,
	|		Payments.CashRegister,
	|		Payments.FinancialAccount,
	|		Payments.VATRate,
	|		NULL,
	|		FALSE,
	|		PaymentInvoices.Invoice,
	|		Payments.SumWithoutVAT,
	|		Payments.VATSum
	|	FROM
	|		PaymentAmounts AS Payments
	|			LEFT JOIN (SELECT DISTINCT
	|				SettlementPaymentDocuments.Ref AS Invoice,
	|				SettlementPaymentDocuments.PaymentDoc AS PaymentDoc
	|			FROM
	|				Document.Settlement.PaymentDocuments AS SettlementPaymentDocuments
	|			WHERE
	|				SettlementPaymentDocuments.Ref.Posted
	|				AND SettlementPaymentDocuments.Ref.Hotel = &qHotel
	|				AND (&qCompanyIsEmpty
	|						OR NOT &qCompanyIsEmpty
	|							AND SettlementPaymentDocuments.Ref.Company = &qCompany)) AS PaymentInvoices
	|			ON (PaymentInvoices.PaymentDoc = Payments.PaymentRef)) AS ExportPayments
	|		LEFT JOIN InformationRegister.VATRatesHistory.SliceLast(&qAccountingDate, ) AS VATRatesHistory
	|		ON ExportPayments.VATRate = VATRatesHistory.VATRate
	|
	|ORDER BY
	|	CashRegisterCode,
	|	PaymentMethodSortCode,
	|	PaymentMethodDescription,
	|	PaymentSectionCode,
	|	CustomerDescription";
	vQry.SetParameter("qAccountingDate", pAccountingDate);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qCompany", pCompany);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(pCompany));
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	
	vTotals = vQry.Execute().Unload();
	
	vDefaultCustomerAccount = Undefined;
	vDefaultCustomerAccountCode = "";
	vCompany = pCompany;
	If Not ValueIsFilled(vCompany) And ValueIsFilled(pHotel) And ValueIsFilled(pHotel.Company) Then
		vCompany = pHotel.Company;
	EndIf;
	If ValueIsFilled(vCompany) And Not IsBlankString(vCompany.InvoicesAccountCode) Then
		vDefaultCustomerAccount = ChartsOfAccounts.ChartOfAccountsFO.FindByCode(TrimAll(vCompany.InvoicesAccountCode));
		vDefaultCustomerAccountCode = TrimAll(vCompany.InvoicesAccountCode);
	EndIf;
	If Not pHotel.PaymentsGenerateInvoices Then
		// Group data
		vTotals.GroupBy("AccountingDate, DiscountCard, Customer, CustomerCode, CustomerDescription, CustomerAddress, CustomerCountryCode, CustomerCountryISOCode, CustomerCountryISOCode3, CustomerPhone, CustomerEMail, CustomerTIN, CustomerVATCode, CustomerDateOfBirth, CustomerIsIndividual, Currency, PaymentMethod, PaymentMethodSortCode, PaymentMethodDescription, PaymentSection, PaymentSectionCode, CashRegister, CashRegisterCode, CashRegisterDescription, FinancialAccount, VATRate, VATRateDescription, NoVAT, VATTaxRate, Service", "SumWithoutVAT, VATSum");
		vTotals.Columns.Add("ParentDoc", cmGetDocumentTypeDescription("Payment"));
		vTotals.Columns.Add("Invoice", cmGetDocumentTypeDescription("Settlement"));
		vTotals.Columns.Add("IsPrepayment", cmGetBooleanTypeDescription());
		vTotals.Columns.Add("IsByGiftCertificate", cmGetBooleanTypeDescription());
	EndIf;
	
	For Each vRow In vTotals Do
		// Skip payments by gift certificates
		If Not vRow.IsPrepayment And vRow.IsByGiftCertificate Then
			Continue;
		EndIf;
		
		vCustAccount = Undefined;
		vCustAccountCode = "";
		If ValueIsFilled(vRow.Customer) Then
			vAccountStruct = cmGetAccountCodeForCustomer(pHotel, pCompany, vRow.Customer);
			vCustAccount = vAccountStruct.Account;
			If Not IsBlankString(vAccountStruct.Code) Then
				vCustAccountCode = TrimAll(vAccountStruct.Code);
			ElsIf ValueIsFilled(vAccountStruct.Account) And Not IsBlankString(vAccountStruct.Account.CodeBO) Then
				vCustAccountCode = TrimAll(vAccountStruct.Account.CodeBO);
			EndIf;
		EndIf;
		If IsBlankString(vCustAccountCode) Then
			vCustAccount = vDefaultCustomerAccount;
			vCustAccountCode = vDefaultCustomerAccountCode;
		EndIf;
			
		vPMAccount = Undefined;
		vPMAccountCode = "";
		vAccountStruct = cmGetAccountCodeForPOSAndPaymentMethod(pHotel, pCompany, vRow.CashRegister, vRow.PaymentMethod, vRow.PaymentSection);
		If Not IsBlankString(vAccountStruct.Code) Then
			vPMAccountCode = TrimAll(vAccountStruct.Code);
		ElsIf ValueIsFilled(vAccountStruct.Account) And Not IsBlankString(vAccountStruct.Account.CodeBO) Then
			vPMAccountCode = TrimAll(vAccountStruct.Account.CodeBO);
		EndIf;
		vPMAccount = vAccountStruct.Account;
		
		vSrvAccount = Undefined;
		vSrvAccountCode = "";
		If ValueIsFilled(vRow.Service) Then
			vService = vRow.Service;
			vServiceVATRate = vRow.VATRate;
			If vRow.IsPrepayment And pHotel.PaymentsGenerateInvoices Then
				vPrepaimentService = cmGetProformaInvoiceService(vRow.PaymentDoc, vServiceVATRate);
				If ValueIsFilled(vPrepaimentService) And vService <> vPrepaimentService Then
					vService = vPrepaimentService;
				EndIf;
			EndIf;
			vAccountStruct = cmGetAccountCodeForService(pHotel, pCompany, vService, vServiceVATRate, pAccountingDate);
			vSrvAccount = vAccountStruct.Account;
			If Not IsBlankString(vAccountStruct.Code) Then
				vSrvAccountCode = TrimAll(vAccountStruct.Code);
			ElsIf ValueIsFilled(vAccountStruct.Account) And Not IsBlankString(vAccountStruct.Account.CodeBO) Then
				vSrvAccountCode = TrimAll(vAccountStruct.Account.CodeBO);
			EndIf;
		EndIf;
		
		vSign = 1;
		If vRow.IsPrepayment Then
			If TypeOf(vRow.PaymentDoc) = Type("DocumentRef.Return") And ValueIsFilled(vRow.PaymentDoc.Invoice) And ValueIsFilled(vRow.PaymentDoc.Payment) And ValueIsFilled(vRow.PaymentDoc.Payment.Invoice) And vRow.PaymentDoc.Payment.Invoice = vRow.PaymentDoc.Invoice Then
				vSign = -1;
			EndIf;
		EndIf;
		
		// Amount
		vPMWithoutVATAmount = vSign * cmConvertCurrencies(vRow.SumWithoutVAT, vRow.Currency, , pHotel.ReportingCurrency, , vRow.AccountingDate, pHotel);
		vPMVATAmount = vSign * cmConvertCurrencies(vRow.VATSum, vRow.Currency, , pHotel.ReportingCurrency, , vRow.AccountingDate, pHotel);
		
		// If this is payment card then check if there are bank commission settings
		vPMBankCommission = 0;
		vPMBankCommissionWithoutVAT = 0;
		If vAccountStruct <> Undefined And vAccountStruct.Property("CommissionAccount") And ValueIsFilled(vAccountStruct.CommissionAccount) Then
			If vAccountStruct.Property("CommissionPercent") And vAccountStruct.CommissionPercent <> 0 Then
				vPMBankCommission = Round((vPMWithoutVATAmount + vPMVATAmount) * vAccountStruct.CommissionPercent / 100, 2);
				vPMBankCommissionWithoutVAT = Round(vPMWithoutVATAmount * vAccountStruct.CommissionPercent / 100, 2);
				
				vAccountDt = vAccountStruct.CommissionAccount;
				vAccountCr = vPMAccount;
				
				vIncomePaymentXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomePayment"));
				
				vIncomePaymentXDTO.AccountingDate = vRow.AccountingDate;
				vIncomePaymentXDTO.POSName = vRow.CashRegisterDescription;
				vIncomePaymentXDTO.PaymentMethodName = vRow.PaymentMethodDescription;
				vIncomePaymentXDTO.AmountWithoutVAT = vPMBankCommission;
				vIncomePaymentXDTO.VATAmount = 0;
				vIncomePaymentXDTO.Amount = vPMBankCommission;
				vIncomePaymentXDTO.VATRateName = vRow.VATRateDescription;
				vIncomePaymentXDTO.VATTaxRate = -1;
				vIncomePaymentXDTO.IsPrepayment = False;
				vIncomePaymentXDTO.AccountCodeDt = ?(IsBlankString(vAccountStruct.CommissionAccount.CodeBO), TrimAll(vAccountStruct.CommissionAccount.Code), TrimAll(vAccountStruct.CommissionAccount.CodeBO));
				vIncomePaymentXDTO.AccountCodeCr = vPMAccountCode;
				vIncomePaymentXDTO.IsPrepaymentClearing = False;
				
				vCustomerXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CustomersItemRow"));
				vCustomerXDTO.IsIndividual = True;
				vCustomerXDTO.Code = "";
				vCustomerXDTO.Description = "";
				vCustomerXDTO.ExternalCode = "";
				vCustomerXDTO.TIN = "";
				vCustomerXDTO.VATCode = "";
				vCustomerXDTO.EMail = "";
				vCustomerXDTO.Phone = "";
				vCustomerXDTO.Address = "";
				vCustomerXDTO.CountryCode = 0;
				vCustomerXDTO.CountryISOCode2 = "";
				vCustomerXDTO.CountryISOCode3 = "";
				vCustomerXDTO.DateOfBirth = '00010101';
				vIncomePaymentXDTO.Customer = vCustomerXDTO;
				
				// Analysis items
				If pUsePostingsFOData Then
					FillAnalysisItems(vAccountDt, vAccountCr, vIncomePaymentXDTO);
				EndIf;
				
				vIncomePaymentsXDTO.IncomePayment.Add(vIncomePaymentXDTO);
			EndIf;
		EndIf;
		
		If vRow.IsPrepayment Then
			If vRow.IsByGiftCertificate Then
				If ValueIsFilled(vRow.FinancialAccount) Then
					vAccountDt = vRow.FinancialAccount;
				Else
					vAccountDt = ChartsOfAccounts.ChartOfAccountsFO.GuestLedger;
				EndIf;
				vAccountCr = vPMAccount;
			Else
				vAccountDt = vPMAccount;
				vAccountCr = vSrvAccount;
			EndIf;
		Else
			vAccountDt = vPMAccount;
			If vRow.CustomerIsIndividual Then
				If ValueIsFilled(vRow.FinancialAccount) Then
					vAccountCr = vRow.FinancialAccount;
				Else
					vAccountCr = ChartsOfAccounts.ChartOfAccountsFO.GuestLedger;
				EndIf;
			Else
				vAccountCr = vCustAccount;
			EndIf;
		EndIf;
		
		vIncomePaymentXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomePayment"));
		
		vIncomePaymentXDTO.AccountingDate = vRow.AccountingDate;
		vIncomePaymentXDTO.POSName = vRow.CashRegisterDescription;
		vIncomePaymentXDTO.PaymentMethodName = vRow.PaymentMethodDescription;
		vIncomePaymentXDTO.AmountWithoutVAT = vPMWithoutVATAmount - vPMBankCommissionWithoutVAT;
		vIncomePaymentXDTO.VATAmount = vPMVATAmount;
		vIncomePaymentXDTO.VATRateName = vRow.VATRateDescription;
		If vRow.NoVAT Then
			vIncomePaymentXDTO.VATTaxRate = -1;
		Else
			vIncomePaymentXDTO.VATTaxRate = vRow.VATTaxRate;
		EndIf;
		If vRow.IsPrepayment Then
			vIncomePaymentXDTO.IsPrepayment = True;
			If vRow.IsByGiftCertificate Then
				If ValueIsFilled(vRow.FinancialAccount) Then
					vIncomePaymentXDTO.AccountCodeDt = ?(Not IsBlankString(vRow.FinancialAccount.CodeBO), TrimAll(vRow.FinancialAccount.CodeBO), TrimAll(vRow.FinancialAccount.Code));
				Else
					vIncomePaymentXDTO.AccountCodeDt = ChartsOfAccounts.ChartOfAccountsFO.GuestLedger.CodeBO;
				EndIf;
				vIncomePaymentXDTO.AccountCodeCr = vSrvAccountCode;
			Else
				vIncomePaymentXDTO.AccountCodeDt = vPMAccountCode;
				vIncomePaymentXDTO.AccountCodeCr = vSrvAccountCode;
			EndIf;
			vIncomePaymentXDTO.Amount = vIncomePaymentXDTO.AmountWithoutVAT;
		Else
			vIncomePaymentXDTO.IsPrepayment = False;
			vIncomePaymentXDTO.AccountCodeDt = vPMAccountCode;
			If vRow.CustomerIsIndividual Then
				If ValueIsFilled(vRow.FinancialAccount) Then
					vIncomePaymentXDTO.AccountCodeCr = ?(Not IsBlankString(vRow.FinancialAccount.CodeBO), TrimAll(vRow.FinancialAccount.CodeBO), TrimAll(vRow.FinancialAccount.Code));
				Else
					vIncomePaymentXDTO.AccountCodeCr = ChartsOfAccounts.ChartOfAccountsFO.GuestLedger.CodeBO;
				EndIf;
			Else
				vIncomePaymentXDTO.AccountCodeCr = vCustAccountCode;
			EndIf;
			vIncomePaymentXDTO.Amount = vPMWithoutVATAmount + vPMVATAmount - vPMBankCommission;
		EndIf;
		vIncomePaymentXDTO.IsPrepaymentClearing = False;
		
		vCustomerXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CustomersItemRow"));
		vCustomerXDTO.IsIndividual = vRow.CustomerIsIndividual;
		vCustomerXDTO.Code = TrimAll(vRow.CustomerCode);
		vCustomerXDTO.Description = TrimAll(vRow.CustomerDescription);
		vCustomerXDTO.ExternalCode = cmGetObjectExternalSystemCodeByRef(pHotel, pExternalSystemCode, "Customers", vRow.Customer, True);
		vCustomerXDTO.TIN = TrimAll(vRow.CustomerTIN);
		vCustomerXDTO.VATCode = TrimAll(vRow.CustomerVATCode);
		vCustomerXDTO.EMail = TrimAll(vRow.CustomerEMail);
		vCustomerXDTO.Phone = TrimAll(vRow.CustomerPhone);
		vCustomerXDTO.Address = TrimAll(vRow.CustomerAddress);
		vCustomerXDTO.CountryCode = ?(vRow.CustomerCountryCode = Null, 0, vRow.CustomerCountryCode);
		vCustomerXDTO.CountryISOCode2 = TrimAll(vRow.CustomerCountryISOCode);
		vCustomerXDTO.CountryISOCode3 = TrimAll(vRow.CustomerCountryISOCode3);
		vCustomerXDTO.DateOfBirth = ?(ValueIsFilled(vRow.CustomerDateOfBirth), vRow.CustomerDateOfBirth, '00010101');
		vIncomePaymentXDTO.Customer = vCustomerXDTO;
		
		// Analysis items
		If pUsePostingsFOData Then
			FillAnalysisItems(vAccountDt, vAccountCr, vIncomePaymentXDTO);
		EndIf;
		
		vIncomePaymentsXDTO.IncomePayment.Add(vIncomePaymentXDTO);
		
		// If this is prepayment then add VAT posting
		If vRow.IsPrepayment And Not vRow.NoVAT Then
			vVATAccountCode = "";
			vVATAccountStruct = cmGetAccountCodeForVATRate(pHotel, pCompany, vRow.VATRate);
			vVATAccount = vVATAccountStruct.Account;
			If Not IsBlankString(vVATAccountStruct.Code) Then
				vVATAccountCode = TrimAll(vVATAccountStruct.Code);
			ElsIf ValueIsFilled(vVATAccountStruct.Account) And Not IsBlankString(vVATAccountStruct.Account.CodeBO) Then
				vVATAccountCode = TrimAll(vVATAccountStruct.Account.CodeBO);
			EndIf;
			If IsBlankString(vVATAccountCode) Then
				Raise NStr("en='Failed to get account code for the VAT rate: '; ru='Ошибка получения номера счета бухгалтерии для ставки НДС: '; de='Fehler beim Abrufen des Kontocodes für den Mehrwertsteuersatz: '") + TrimAll(vRow.VATRate) + ", " + pHotel + ", " + pCompany;
			EndIf;
			
			If vRow.IsByGiftCertificate Then
				If ValueIsFilled(vRow.FinancialAccount) Then
					vAccountDt = vRow.FinancialAccount;
				Else
					If ValueIsFilled(vRow.FinancialAccount) Then
						vAccountDt = vRow.FinancialAccount;
					Else
						vAccountDt = ChartsOfAccounts.ChartOfAccountsFO.GuestLedger;
					EndIf;
				EndIf;
			Else
				vAccountDt = vPMAccount;
			EndIf;
			vAccountCr = vVATAccount;
					
			vIncomePaymentXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomePayment"));
			
			vIncomePaymentXDTO.AccountingDate = vRow.AccountingDate;
			vIncomePaymentXDTO.POSName = vRow.CashRegisterDescription;
			vIncomePaymentXDTO.PaymentMethodName = vRow.PaymentMethodDescription;
			vIncomePaymentXDTO.AmountWithoutVAT = 0;
			vIncomePaymentXDTO.VATAmount = vPMVATAmount;
			vIncomePaymentXDTO.VATRateName = vRow.VATRateDescription;
			vIncomePaymentXDTO.VATTaxRate = vRow.VATTaxRate;
			If vRow.IsByGiftCertificate Then
				If ValueIsFilled(vRow.FinancialAccount) Then
					vIncomePaymentXDTO.AccountCodeDt = ?(Not IsBlankString(vRow.FinancialAccount.CodeBO), TrimAll(vRow.FinancialAccount.CodeBO), TrimAll(vRow.FinancialAccount.Code));
				Else
					vIncomePaymentXDTO.AccountCodeDt = ChartsOfAccounts.ChartOfAccountsFO.GuestLedger.CodeBO;
				EndIf;
			Else
				vIncomePaymentXDTO.AccountCodeDt = vPMAccountCode;
			EndIf;
			vIncomePaymentXDTO.AccountCodeCr = vVATAccountCode;
			vIncomePaymentXDTO.Amount = vIncomePaymentXDTO.VATAmount;
			vIncomePaymentXDTO.IsPrepayment = True;
			vIncomePaymentXDTO.IsPrepaymentClearing = False;
			
			vCustomerXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CustomersItemRow"));
			vCustomerXDTO.IsIndividual = vRow.CustomerIsIndividual;
			vCustomerXDTO.Code = TrimAll(vRow.CustomerCode);
			vCustomerXDTO.Description = TrimAll(vRow.CustomerDescription);
			vCustomerXDTO.ExternalCode = cmGetObjectExternalSystemCodeByRef(pHotel, pExternalSystemCode, "Customers", vRow.Customer, True);
			vCustomerXDTO.TIN = TrimAll(vRow.CustomerTIN);
			vCustomerXDTO.VATCode = TrimAll(vRow.CustomerVATCode);
			vCustomerXDTO.EMail = TrimAll(vRow.CustomerEMail);
			vCustomerXDTO.Phone = TrimAll(vRow.CustomerPhone);
			vCustomerXDTO.Address = TrimAll(vRow.CustomerAddress);
			vCustomerXDTO.CountryCode = ?(vRow.CustomerCountryCode = Null, 0, vRow.CustomerCountryCode);
			vCustomerXDTO.CountryISOCode2 = TrimAll(vRow.CustomerCountryISOCode);
			vCustomerXDTO.CountryISOCode3 = TrimAll(vRow.CustomerCountryISOCode3);
			vCustomerXDTO.DateOfBirth = ?(ValueIsFilled(vRow.CustomerDateOfBirth), vRow.CustomerDateOfBirth, '00010101');
			vIncomePaymentXDTO.Customer = vCustomerXDTO;
			
			// Analysis items
			If pUsePostingsFOData Then
				FillAnalysisItems(vAccountDt, vAccountCr, vIncomePaymentXDTO);
			EndIf;
			
			vIncomePaymentsXDTO.IncomePayment.Add(vIncomePaymentXDTO);
		EndIf;
		
		// If this is payment by invoice then invoice can clear an advance amount
		If pHotel.PaymentsGenerateInvoices Then
			If Not vRow.IsPrepayment And ValueIsFilled(vRow.Invoice) Then
				vInvoice = vRow.Invoice;
				vClearing = New ValueTable();
				vClearing.Columns.Add("Service");
				vClearing.Columns.Add("VATRate");
				vClearing.Columns.Add("SumWithoutVAT");
				vClearing.Columns.Add("VATSum");
				For Each vPDRow In vInvoice.PaymentDocuments Do
					If vPDRow.PaymentDoc <> vRow.PaymentDoc Then
						vProforma = vPDRow.PaymentDoc.Invoice;
						If ValueIsFilled(vProforma) And TypeOf(vProforma) = Type("DocumentRef.ProformaInvoice") Then
							vSign = 1;
							If TypeOf(vPDRow.PaymentDoc) = Type("DocumentRef.Return") Then
								vSign = -1;
							EndIf;
							
							For Each vSrvRow In vProforma.Services Do
								vSrvAccountCode = "";
								vSrvAccount = Undefined;
								If ValueIsFilled(vSrvRow.Service) Then
									vService = vSrvRow.Service;
									vServiceVATRate = vSrvRow.VATRate;
									vPrepaimentService = cmGetProformaInvoiceService(vPDRow.PaymentDoc, vServiceVATRate);
									If ValueIsFilled(vPrepaimentService) And vPrepaimentService <> vService Then
										vService = vPrepaimentService;
									EndIf;
									vAccountStruct = cmGetAccountCodeForService(pHotel, pCompany, vService, vServiceVATRate, pAccountingDate);
									vSrvAccount = vAccountStruct.Account;
									If Not IsBlankString(vAccountStruct.Code) Then
										vSrvAccountCode = TrimAll(vAccountStruct.Code);
									ElsIf ValueIsFilled(vAccountStruct.Account) And Not IsBlankString(vAccountStruct.Account.CodeBO) Then
										vSrvAccountCode = TrimAll(vAccountStruct.Account.CodeBO);
									EndIf;
								EndIf;
								
								vAccountDt = vSrvAccount;
								If ValueIsFilled(vRow.FinancialAccount) Then
									vAccountCr = vRow.FinancialAccount;
								Else
									vAccountCr = ChartsOfAccounts.ChartOfAccountsFO.GuestLedger;
								EndIf;
								
								vIncomePaymentXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomePayment"));
								
								vIncomePaymentXDTO.AccountingDate = vRow.AccountingDate;
								vIncomePaymentXDTO.POSName = "";
								vIncomePaymentXDTO.PaymentMethodName = "";
								vIncomePaymentXDTO.AmountWithoutVAT = vSign * cmConvertCurrencies(vSrvRow.Sum - vSrvRow.VATSum, vProforma.AccountingCurrency, , pHotel.ReportingCurrency, , vRow.AccountingDate, pHotel);
								vIncomePaymentXDTO.VATAmount = vSign * cmConvertCurrencies(vSrvRow.VATSum, vProforma.AccountingCurrency, , pHotel.ReportingCurrency, , vRow.AccountingDate, pHotel);
								vIncomePaymentXDTO.Amount = vIncomePaymentXDTO.AmountWithoutVAT;
								vIncomePaymentXDTO.VATRateName = TrimAll(vSrvRow.VATRate);
								If ValueIsFilled(vSrvRow.VATRate) And vSrvRow.VATRate.NoVAT Then
									vIncomePaymentXDTO.VATTaxRate = -1;
								Else
									vIncomePaymentXDTO.VATTaxRate = CachedAccounts.GetVATTaxRate(vSrvRow.VATRate, pAccountingDate);
								EndIf;
								
								vIncomePaymentXDTO.IsPrepayment = False;
								vIncomePaymentXDTO.IsPrepaymentClearing = True;
								vIncomePaymentXDTO.AccountCodeDt = vSrvAccountCode;
								If ValueIsFilled(vRow.FinancialAccount) Then
									vIncomePaymentXDTO.AccountCodeCr = ?(Not IsBlankString(vRow.FinancialAccount.CodeBO), TrimAll(vRow.FinancialAccount.CodeBO), TrimAll(vRow.FinancialAccount.Code));
								Else
									vIncomePaymentXDTO.AccountCodeCr = ChartsOfAccounts.ChartOfAccountsFO.GuestLedger.CodeBO;
								EndIf;
								
								vCustomerXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CustomersItemRow"));
								vCustomerXDTO.IsIndividual = vRow.CustomerIsIndividual;
								vCustomerXDTO.Code = TrimAll(vRow.CustomerCode);
								vCustomerXDTO.Description = TrimAll(vRow.CustomerDescription);
								vCustomerXDTO.ExternalCode = cmGetObjectExternalSystemCodeByRef(pHotel, pExternalSystemCode, "Customers", vRow.Customer, True);
								vCustomerXDTO.TIN = TrimAll(vRow.CustomerTIN);
								vCustomerXDTO.VATCode = TrimAll(vRow.CustomerVATCode);
								vCustomerXDTO.EMail = TrimAll(vRow.CustomerEMail);
								vCustomerXDTO.Phone = TrimAll(vRow.CustomerPhone);
								vCustomerXDTO.Address = TrimAll(vRow.CustomerAddress);
								vCustomerXDTO.CountryCode = ?(vRow.CustomerCountryCode = Null, 0, vRow.CustomerCountryCode);
								vCustomerXDTO.CountryISOCode2 = TrimAll(vRow.CustomerCountryISOCode);
								vCustomerXDTO.CountryISOCode3 = TrimAll(vRow.CustomerCountryISOCode3);
								vCustomerXDTO.DateOfBirth = ?(ValueIsFilled(vRow.CustomerDateOfBirth), vRow.CustomerDateOfBirth, '00010101');
								vIncomePaymentXDTO.Customer = vCustomerXDTO;
								
								// Analysis items
								If pUsePostingsFOData Then
									FillAnalysisItems(vAccountDt, vAccountCr, vIncomePaymentXDTO);
								EndIf;
								
								vIncomePaymentsXDTO.IncomePayment.Add(vIncomePaymentXDTO);
								
								// Add VAT posting
								If ValueIsFilled(vSrvRow.VATRate) And Not vSrvRow.VATRate.NoVAT Then
									vVATAccountCode = "";
									vVATAccountStruct = cmGetAccountCodeForVATRate(pHotel, pCompany, vSrvRow.VATRate);
									vVATAccount = vVATAccountStruct.Account;
									If Not IsBlankString(vVATAccountStruct.Code) Then
										vVATAccountCode = TrimAll(vVATAccountStruct.Code);
									ElsIf ValueIsFilled(vVATAccountStruct.Account) And Not IsBlankString(vVATAccountStruct.Account.CodeBO) Then
										vVATAccountCode = TrimAll(vVATAccountStruct.Account.CodeBO);
									EndIf;
									If IsBlankString(vVATAccountCode) Then
										Raise NStr("en='Failed to get account code for the VAT rate: '; ru='Ошибка получения номера счета бухгалтерии для ставки НДС: '; de='Fehler beim Abrufen des Kontocodes für den Mehrwertsteuersatz: '") + TrimAll(vSrvRow.VATRate) + ", " + pHotel + ", " + pCompany;
									EndIf;
									
									vAccountDt = vVATAccount;
									If ValueIsFilled(vRow.FinancialAccount) Then
										vAccountCr = vRow.FinancialAccount;
									Else
										vAccountCr = ChartsOfAccounts.ChartOfAccountsFO.GuestLedger;
									EndIf;
											
									vIncomePaymentXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomePayment"));
									
									vIncomePaymentXDTO.AccountingDate = vRow.AccountingDate;
									vIncomePaymentXDTO.POSName = "";
									vIncomePaymentXDTO.PaymentMethodName = "";
									vIncomePaymentXDTO.AmountWithoutVAT = 0;
									vIncomePaymentXDTO.VATAmount = vSign * cmConvertCurrencies(vSrvRow.VATSum, vProforma.AccountingCurrency, , pHotel.ReportingCurrency, , vRow.AccountingDate, pHotel);
									vIncomePaymentXDTO.Amount = vIncomePaymentXDTO.VATAmount;
									vIncomePaymentXDTO.VATRateName = TrimAll(vSrvRow.VATRate);
									vIncomePaymentXDTO.VATTaxRate = CachedAccounts.GetVATTaxRate(vSrvRow.VATRate, pAccountingDate);
									vIncomePaymentXDTO.IsPrepayment = False;
									vIncomePaymentXDTO.IsPrepaymentClearing = True;
									vIncomePaymentXDTO.AccountCodeDt = vVATAccountCode;
									If ValueIsFilled(vRow.FinancialAccount) Then
										vIncomePaymentXDTO.AccountCodeCr = ?(Not IsBlankString(vRow.FinancialAccount.CodeBO), TrimAll(vRow.FinancialAccount.CodeBO), TrimAll(vRow.FinancialAccount.Code));
									Else
										vIncomePaymentXDTO.AccountCodeCr = ChartsOfAccounts.ChartOfAccountsFO.GuestLedger.CodeBO;
									EndIf;
									
									vCustomerXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CustomersItemRow"));
									vCustomerXDTO.IsIndividual = vRow.CustomerIsIndividual;
									vCustomerXDTO.Code = TrimAll(vRow.CustomerCode);
									vCustomerXDTO.Description = TrimAll(vRow.CustomerDescription);
									vCustomerXDTO.ExternalCode = cmGetObjectExternalSystemCodeByRef(pHotel, pExternalSystemCode, "Customers", vRow.Customer, True);
									vCustomerXDTO.TIN = TrimAll(vRow.CustomerTIN);
									vCustomerXDTO.VATCode = TrimAll(vRow.CustomerVATCode);
									vCustomerXDTO.EMail = TrimAll(vRow.CustomerEMail);
									vCustomerXDTO.Phone = TrimAll(vRow.CustomerPhone);
									vCustomerXDTO.Address = TrimAll(vRow.CustomerAddress);
									vCustomerXDTO.CountryCode = ?(vRow.CustomerCountryCode = Null, 0, vRow.CustomerCountryCode);
									vCustomerXDTO.CountryISOCode2 = TrimAll(vRow.CustomerCountryISOCode);
									vCustomerXDTO.CountryISOCode3 = TrimAll(vRow.CustomerCountryISOCode3);
									vCustomerXDTO.DateOfBirth = ?(ValueIsFilled(vRow.CustomerDateOfBirth), vRow.CustomerDateOfBirth, '00010101');
									vIncomePaymentXDTO.Customer = vCustomerXDTO;
									
									// Analysis items
									If pUsePostingsFOData Then
										FillAnalysisItems(vAccountDt, vAccountCr, vIncomePaymentXDTO);
									EndIf;
									
									vIncomePaymentsXDTO.IncomePayment.Add(vIncomePaymentXDTO);
								EndIf;
							EndDo;
								
							// Add to the list of cleared payments
							If vClearedPayments.FindByValue(vPDRow.PaymentDoc) = Undefined Then
								vClearedPayments.Add(vPDRow.PaymentDoc);
							EndIf;
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndDo;
	
	// Payments cleared by invoices
	If pHotel.PaymentsGenerateInvoices Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	SettlementPaymentDocuments.Ref AS Invoice,
		|	SettlementPaymentDocuments.PaymentDoc AS PaymentDoc,
		|	CASE
		|		WHEN SettlementPaymentDocuments.Ref.AccountingCustomer <> SettlementPaymentDocuments.Ref.Hotel.IndividualsCustomer
		|			THEN SettlementPaymentDocuments.Ref.AccountingCustomer
		|		ELSE SettlementPaymentDocuments.Ref.GuestGroup.Client
		|	END AS Customer,
		|	CASE
		|		WHEN SettlementPaymentDocuments.Ref.AccountingCustomer <> SettlementPaymentDocuments.Ref.Hotel.IndividualsCustomer
		|			THEN ISNULL(SettlementPaymentDocuments.Ref.AccountingCustomer.Code, """")
		|		ELSE ISNULL(SettlementPaymentDocuments.Ref.GuestGroup.Client.Code, """")
		|	END AS CustomerCode,
		|	CASE
		|		WHEN SettlementPaymentDocuments.Ref.AccountingCustomer <> SettlementPaymentDocuments.Ref.Hotel.IndividualsCustomer
		|			THEN CAST(SettlementPaymentDocuments.Ref.AccountingCustomer.LegacyName AS STRING(999))
		|		ELSE CAST(ISNULL(SettlementPaymentDocuments.Ref.GuestGroup.Client.FullName, """") AS STRING(999))
		|	END AS CustomerDescription,
		|	CASE
		|		WHEN SettlementPaymentDocuments.Ref.AccountingCustomer <> SettlementPaymentDocuments.Ref.Hotel.IndividualsCustomer
		|			THEN CAST(SettlementPaymentDocuments.Ref.AccountingCustomer.LegacyAddress AS STRING(999))
		|		ELSE CAST(ISNULL(SettlementPaymentDocuments.Ref.GuestGroup.Client.Address, """") AS STRING(999))
		|	END AS CustomerAddress,
		|	CASE
		|		WHEN SettlementPaymentDocuments.Ref.AccountingCustomer <> SettlementPaymentDocuments.Ref.Hotel.IndividualsCustomer
		|			THEN ISNULL(SettlementPaymentDocuments.Ref.AccountingCustomer.Country.Code, 0)
		|		ELSE ISNULL(SettlementPaymentDocuments.Ref.GuestGroup.Client.Citizenship.Code, 0)
		|	END AS CustomerCountryCode,
		|	CASE
		|		WHEN SettlementPaymentDocuments.Ref.AccountingCustomer <> SettlementPaymentDocuments.Ref.Hotel.IndividualsCustomer
		|			THEN ISNULL(SettlementPaymentDocuments.Ref.AccountingCustomer.Country.ISOCode, """")
		|		ELSE ISNULL(SettlementPaymentDocuments.Ref.GuestGroup.Client.Citizenship.ISOCode, """")
		|	END AS CustomerCountryISOCode,
		|	CASE
		|		WHEN SettlementPaymentDocuments.Ref.AccountingCustomer <> SettlementPaymentDocuments.Ref.Hotel.IndividualsCustomer
		|			THEN ISNULL(SettlementPaymentDocuments.Ref.AccountingCustomer.Country.ISOCode3, """")
		|		ELSE ISNULL(SettlementPaymentDocuments.Ref.GuestGroup.Client.Citizenship.ISOCode3, """")
		|	END AS CustomerCountryISOCode3,
		|	CASE
		|		WHEN SettlementPaymentDocuments.Ref.AccountingCustomer <> SettlementPaymentDocuments.Ref.Hotel.IndividualsCustomer
		|			THEN ISNULL(SettlementPaymentDocuments.Ref.AccountingCustomer.Phone, """")
		|		ELSE ISNULL(SettlementPaymentDocuments.Ref.GuestGroup.Client.Phone, """")
		|	END AS CustomerPhone,
		|	CASE
		|		WHEN SettlementPaymentDocuments.Ref.AccountingCustomer <> SettlementPaymentDocuments.Ref.Hotel.IndividualsCustomer
		|			THEN ISNULL(SettlementPaymentDocuments.Ref.AccountingCustomer.EMail, """")
		|		ELSE ISNULL(SettlementPaymentDocuments.Ref.GuestGroup.Client.EMail, """")
		|	END AS CustomerEMail,
		|	CASE
		|		WHEN SettlementPaymentDocuments.Ref.AccountingCustomer <> SettlementPaymentDocuments.Ref.Hotel.IndividualsCustomer
		|			THEN ISNULL(SettlementPaymentDocuments.Ref.AccountingCustomer.TIN, """")
		|		ELSE ISNULL(SettlementPaymentDocuments.Ref.GuestGroup.Client.TIN, """")
		|	END AS CustomerTIN,
		|	CASE
		|		WHEN SettlementPaymentDocuments.Ref.AccountingCustomer <> SettlementPaymentDocuments.Ref.Hotel.IndividualsCustomer
		|			THEN ISNULL(SettlementPaymentDocuments.Ref.AccountingCustomer.VATC, """")
		|		ELSE """"
		|	END AS CustomerVATCode,
		|	CASE
		|		WHEN SettlementPaymentDocuments.Ref.AccountingCustomer <> SettlementPaymentDocuments.Ref.Hotel.IndividualsCustomer
		|			THEN SettlementPaymentDocuments.Ref.AccountingCustomer.DateOfBirth
		|		ELSE SettlementPaymentDocuments.Ref.GuestGroup.Client.DateOfBirth
		|	END AS CustomerDateOfBirth,
		|	CASE
		|		WHEN SettlementPaymentDocuments.Ref.AccountingCustomer <> SettlementPaymentDocuments.Ref.Hotel.IndividualsCustomer
		|			THEN SettlementPaymentDocuments.Ref.AccountingCustomer.IsIndividual
		|		ELSE TRUE
		|	END AS CustomerIsIndividual,
		|	SettlementPaymentDocuments.PaymentDoc.Folio.FinancialAccount AS FinancialAccount
		|FROM
		|	Document.Settlement.PaymentDocuments AS SettlementPaymentDocuments
		|WHERE
		|	BEGINOFPERIOD(SettlementPaymentDocuments.Ref.Date, DAY) = &qAccountingDate
		|	AND SettlementPaymentDocuments.Ref.Hotel = &qHotel
		|	AND (&qCompanyIsEmpty
		|			OR NOT &qCompanyIsEmpty
		|				AND SettlementPaymentDocuments.Ref.Company = &qCompany)
		|	AND ISNULL(SettlementPaymentDocuments.Ref.Hotel.PaymentsGenerateInvoices, FALSE)
		|	AND NOT SettlementPaymentDocuments.PaymentDoc IN (&qClearedPaymentsList)
		|	AND ISNULL(SettlementPaymentDocuments.Ref.IsChecked, FALSE)
		|	AND NOT ISNULL(SettlementPaymentDocuments.Ref.DoNotExportToTheAccountingSystem, FALSE)
		|	AND SettlementPaymentDocuments.PaymentDoc.DiscountCard = VALUE(Catalog.DiscountCards.EmptyRef)
		|	AND SettlementPaymentDocuments.Ref.Posted
		|
		|ORDER BY
		|	SettlementPaymentDocuments.PaymentDoc.Date";
		vQry.SetParameter("qAccountingDate", pAccountingDate);
		vQry.SetParameter("qHotel", pHotel);
		vQry.SetParameter("qCompany", pCompany);
		vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(pCompany));
		vQry.SetParameter("qClearedPaymentsList", vClearedPayments);
		vPayments = vQry.Execute().Unload();
		For Each vPDRow In vPayments Do
			If ValueIsFilled(vPDRow.PaymentDoc) Then
				If vClearedPayments.FindByValue(vPDRow.PaymentDoc) = Undefined Then
					vClearedPayments.Add(vPDRow.PaymentDoc);
					
					vSign = 1;
					If TypeOf(vPDRow.PaymentDoc) = Type("DocumentRef.Return") Then
						vSign = -1;
					EndIf;
					
					vInvoice = vPDRow.Invoice;
					vProforma = vPDRow.PaymentDoc.Invoice;
					If ValueIsFilled(vProforma) And TypeOf(vProforma) = Type("DocumentRef.ProformaInvoice") Then
						For Each vSrvRow In vProforma.Services Do
							vSrvAccountCode = "";
							vSrvAccount = Undefined;
							If ValueIsFilled(vSrvRow.Service) Then
								vService = vSrvRow.Service;
								vServiceVATRate = vSrvRow.VATRate;
								vPrepaimentService = cmGetProformaInvoiceService(vPDRow.PaymentDoc, vServiceVATRate);
								If ValueIsFilled(vPrepaimentService) And vService <> vPrepaimentService Then
									vService = vPrepaimentService;
								EndIf;
								vAccountStruct = cmGetAccountCodeForService(pHotel, pCompany, vService, vServiceVATRate, pAccountingDate);
								vSrvAccount = vAccountStruct.Account;
								If Not IsBlankString(vAccountStruct.Code) Then
									vSrvAccountCode = TrimAll(vAccountStruct.Code);
								ElsIf ValueIsFilled(vAccountStruct.Account) And Not IsBlankString(vAccountStruct.Account.CodeBO) Then
									vSrvAccountCode = TrimAll(vAccountStruct.Account.CodeBO);
								EndIf;
							EndIf;
							
							vAccountDt = vSrvAccount;
							If ValueIsFilled(vPDRow.FinancialAccount) Then
								vAccountCr = vPDRow.FinancialAccount;
							Else
								vAccountCr = ChartsOfAccounts.ChartOfAccountsFO.GuestLedger;
							EndIf;
							
							vIncomePaymentXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomePayment"));
							
							vIncomePaymentXDTO.AccountingDate = pAccountingDate;
							vIncomePaymentXDTO.POSName = "";
							vIncomePaymentXDTO.PaymentMethodName = "";
							vIncomePaymentXDTO.AmountWithoutVAT = vSign * cmConvertCurrencies(vSrvRow.Sum - vSrvRow.VATSum, vProforma.AccountingCurrency, , pHotel.ReportingCurrency, , pAccountingDate, pHotel);
							vIncomePaymentXDTO.VATAmount = vSign * cmConvertCurrencies(vSrvRow.VATSum, vProforma.AccountingCurrency, , pHotel.ReportingCurrency, , pAccountingDate, pHotel);
							vIncomePaymentXDTO.Amount = vIncomePaymentXDTO.AmountWithoutVAT;
							vIncomePaymentXDTO.VATRateName = TrimAll(vSrvRow.VATRate);
							If ValueIsFilled(vSrvRow.VATRate) And vSrvRow.VATRate.NoVAT Then
								vIncomePaymentXDTO.VATTaxRate = -1;
							Else
								vIncomePaymentXDTO.VATTaxRate = CachedAccounts.GetVATTaxRate(vSrvRow.VATRate, pAccountingDate);
							EndIf;
							
							vIncomePaymentXDTO.IsPrepayment = False;
							vIncomePaymentXDTO.IsPrepaymentClearing = True;
							vIncomePaymentXDTO.AccountCodeDt = vSrvAccountCode;
							If ValueIsFilled(vPDRow.FinancialAccount) Then
								vIncomePaymentXDTO.AccountCodeCr = ?(Not IsBlankString(vPDRow.FinancialAccount.CodeBO), TrimAll(vPDRow.FinancialAccount.CodeBO), TrimAll(vPDRow.FinancialAccount.Code));
							Else
								vIncomePaymentXDTO.AccountCodeCr = ChartsOfAccounts.ChartOfAccountsFO.GuestLedger.CodeBO;
							EndIf;
							
							vCustomerXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CustomersItemRow"));
							vCustomerXDTO.IsIndividual = vPDRow.CustomerIsIndividual;
							vCustomerXDTO.Code = TrimAll(vPDRow.CustomerCode);
							vCustomerXDTO.Description = TrimAll(vPDRow.CustomerDescription);
							vCustomerXDTO.ExternalCode = cmGetObjectExternalSystemCodeByRef(pHotel, pExternalSystemCode, "Customers", vPDRow.Customer, True);
							vCustomerXDTO.TIN = TrimAll(vPDRow.CustomerTIN);
							vCustomerXDTO.VATCode = TrimAll(vPDRow.CustomerVATCode);
							vCustomerXDTO.EMail = TrimAll(vPDRow.CustomerEMail);
							vCustomerXDTO.Phone = TrimAll(vPDRow.CustomerPhone);
							vCustomerXDTO.Address = TrimAll(vPDRow.CustomerAddress);
							vCustomerXDTO.CountryCode = ?(vPDRow.CustomerCountryCode = Null, 0, vPDRow.CustomerCountryCode);
							vCustomerXDTO.CountryISOCode2 = TrimAll(vPDRow.CustomerCountryISOCode);
							vCustomerXDTO.CountryISOCode3 = TrimAll(vPDRow.CustomerCountryISOCode3);
							vCustomerXDTO.DateOfBirth = ?(ValueIsFilled(vPDRow.CustomerDateOfBirth), vPDRow.CustomerDateOfBirth, '00010101');
							vIncomePaymentXDTO.Customer = vCustomerXDTO;
							
							// Analysis items
							If pUsePostingsFOData Then
								FillAnalysisItems(vAccountDt, vAccountCr, vIncomePaymentXDTO);
							EndIf;
							
							vIncomePaymentsXDTO.IncomePayment.Add(vIncomePaymentXDTO);
							
							// Add VAT posting
							If ValueIsFilled(vSrvRow.VATRate) And Not vSrvRow.VATRate.NoVAT Then
								vVATAccountCode = "";
								vVATAccountStruct = cmGetAccountCodeForVATRate(pHotel, pCompany, vSrvRow.VATRate);
								vVATAccount = vVATAccountStruct.Account;
								If Not IsBlankString(vVATAccountStruct.Code) Then
									vVATAccountCode = TrimAll(vVATAccountStruct.Code);
								ElsIf ValueIsFilled(vVATAccountStruct.Account) And Not IsBlankString(vVATAccountStruct.Account.CodeBO) Then
									vVATAccountCode = TrimAll(vVATAccountStruct.Account.CodeBO);
								EndIf;
								If IsBlankString(vVATAccountCode) Then
									Raise NStr("en='Failed to get account code for the VAT rate: '; ru='Ошибка получения номера счета бухгалтерии для ставки НДС: '; de='Fehler beim Abrufen des Kontocodes für den Mehrwertsteuersatz: '") + TrimAll(vSrvRow.VATRate) + ", " + pHotel + ", " + pCompany;
								EndIf;
								
								vAccountDt = vVATAccount;
								If ValueIsFilled(vPDRow.FinancialAccount) Then
									vAccountCr = vPDRow.FinancialAccount;
								Else
									vAccountCr = ChartsOfAccounts.ChartOfAccountsFO.GuestLedger;
								EndIf;
										
								vIncomePaymentXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomePayment"));
								
								vIncomePaymentXDTO.AccountingDate = pAccountingDate;
								vIncomePaymentXDTO.POSName = "";
								vIncomePaymentXDTO.PaymentMethodName = "";
								vIncomePaymentXDTO.AmountWithoutVAT = 0;
								vIncomePaymentXDTO.VATAmount = vSign * cmConvertCurrencies(vSrvRow.VATSum, vProforma.AccountingCurrency, , pHotel.ReportingCurrency, , pAccountingDate, pHotel);
								vIncomePaymentXDTO.Amount = vIncomePaymentXDTO.VATAmount;
								vIncomePaymentXDTO.VATRateName = TrimAll(vSrvRow.VATRate);
								vIncomePaymentXDTO.VATTaxRate = CachedAccounts.GetVATTaxRate(vSrvRow.VATRate, pAccountingDate);
								vIncomePaymentXDTO.IsPrepayment = False;
								vIncomePaymentXDTO.IsPrepaymentClearing = True;
								vIncomePaymentXDTO.AccountCodeDt = vVATAccountCode;
								If ValueIsFilled(vPDRow.FinancialAccount) Then
									vIncomePaymentXDTO.AccountCodeCr = ?(Not IsBlankString(vPDRow.FinancialAccount.CodeBO), TrimAll(vPDRow.FinancialAccount.CodeBO), TrimAll(vPDRow.FinancialAccount.Code));
								Else
									vIncomePaymentXDTO.AccountCodeCr = ChartsOfAccounts.ChartOfAccountsFO.GuestLedger.CodeBO;
								EndIf;
									
								vCustomerXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CustomersItemRow"));
								vCustomerXDTO.IsIndividual = vPDRow.CustomerIsIndividual;
								vCustomerXDTO.Code = TrimAll(vPDRow.CustomerCode);
								vCustomerXDTO.Description = TrimAll(vPDRow.CustomerDescription);
								vCustomerXDTO.ExternalCode = cmGetObjectExternalSystemCodeByRef(pHotel, pExternalSystemCode, "Customers", vPDRow.Customer, True);
								vCustomerXDTO.TIN = TrimAll(vPDRow.CustomerTIN);
								vCustomerXDTO.VATCode = TrimAll(vPDRow.CustomerVATCode);
								vCustomerXDTO.EMail = TrimAll(vPDRow.CustomerEMail);
								vCustomerXDTO.Phone = TrimAll(vPDRow.CustomerPhone);
								vCustomerXDTO.Address = TrimAll(vPDRow.CustomerAddress);
								vCustomerXDTO.CountryCode = ?(vPDRow.CustomerCountryCode = Null, 0, vPDRow.CustomerCountryCode);
								vCustomerXDTO.CountryISOCode2 = TrimAll(vPDRow.CustomerCountryISOCode);
								vCustomerXDTO.CountryISOCode3 = TrimAll(vPDRow.CustomerCountryISOCode3);
								vCustomerXDTO.DateOfBirth = ?(ValueIsFilled(vPDRow.CustomerDateOfBirth), vPDRow.CustomerDateOfBirth, '00010101');
								vIncomePaymentXDTO.Customer = vCustomerXDTO;
								
								// Analysis items
								If pUsePostingsFOData Then
									FillAnalysisItems(vAccountDt, vAccountCr, vIncomePaymentXDTO);
								EndIf;
								
								vIncomePaymentsXDTO.IncomePayment.Add(vIncomePaymentXDTO);
							EndIf;
						EndDo;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	// Payments by gift cards
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	GiftCardsPayments.AccountingDate AS AccountingDate,
	|	GiftCardsPayments.Currency AS Currency,
	|	GiftCardsPayments.Service AS Service,
	|	GiftCardsPayments.Service.Code AS ServiceCode,
	|	GiftCardsPayments.Service.Description AS ServiceDescription,
	|	GiftCardsPayments.VATRate AS VATRate,
	|	ISNULL(GiftCardsPayments.VATRate.Description, """") AS VATRateDescription,
	|	ISNULL(GiftCardsPayments.VATRate.NoVAT, FALSE) AS NoVAT,
	|	ISNULL(VATRatesHistory.TaxRate, GiftCardsPayments.VATRate.TaxRate) AS VATTaxRate,
	|	GiftCardsPayments.SumWithoutVAT AS SumWithoutVAT,
	|	GiftCardsPayments.VATSum AS VATSum
	|FROM
	|	(SELECT
	|		CASE
	|			WHEN PaymentsByGiftCard.Payment.AccountingDate IS NULL
	|				THEN BEGINOFPERIOD(PaymentsByGiftCard.Date, DAY)
	|			ELSE PaymentsByGiftCard.Payment.AccountingDate
	|		END AS AccountingDate,
	|		CASE
	|			WHEN PaymentsByGiftCard.Payment.FolioCurrency IS NULL
	|				THEN PaymentsByGiftCard.Hotel.BaseCurrency
	|			ELSE PaymentsByGiftCard.Payment.FolioCurrency
	|		END AS Currency,
	|		PaymentsByGiftCard.Card.DiscountType.ProformaInvoiceService AS Service,
	|		PaymentsByGiftCard.Folio.FinancialAccount AS FinancialAccount,
	|		CASE
	|			WHEN PaymentsByGiftCard.Payment.VATRate IS NULL
	|				THEN PaymentsByGiftCard.Hotel.Company.VATRate
	|			ELSE PaymentsByGiftCard.Payment.VATRate
	|		END AS VATRate,
	|		CASE
	|			WHEN PaymentsByGiftCard.Payment.AccountingDate IS NULL
	|				THEN PaymentsByGiftCard.BonusesAmount - (CAST(PaymentsByGiftCard.BonusesAmount * ISNULL(VATRateTaxRates.TaxRate, PaymentsByGiftCard.Hotel.Company.VATRate.TaxRate) / (100 + ISNULL(VATRateTaxRates.TaxRate, PaymentsByGiftCard.Hotel.Company.VATRate.TaxRate)) AS NUMBER(17, 2)))
	|			ELSE PaymentsByGiftCard.Payment.Sum - PaymentsByGiftCard.Payment.VATSum
	|		END AS SumWithoutVAT,
	|		CASE
	|			WHEN PaymentsByGiftCard.Payment.AccountingDate IS NULL
	|				THEN CAST(PaymentsByGiftCard.BonusesAmount * ISNULL(VATRateTaxRates.TaxRate, PaymentsByGiftCard.Hotel.Company.VATRate.TaxRate) / (100 + ISNULL(VATRateTaxRates.TaxRate, PaymentsByGiftCard.Hotel.Company.VATRate.TaxRate)) AS NUMBER(17, 2))
	|			ELSE PaymentsByGiftCard.Payment.VATSum
	|		END AS VATSum
	|	FROM
	|		Document.BonusesPayment AS PaymentsByGiftCard
	|			LEFT JOIN InformationRegister.VATRatesHistory.SliceLast(&qAccountingDate, ) AS VATRateTaxRates
	|			ON PaymentsByGiftCard.Hotel.Company.VATRate = VATRateTaxRates.VATRate
	|	WHERE
	|		CASE
	|				WHEN PaymentsByGiftCard.Payment.AccountingDate IS NULL
	|					THEN BEGINOFPERIOD(PaymentsByGiftCard.Date, DAY)
	|				ELSE PaymentsByGiftCard.Payment.AccountingDate
	|			END = &qAccountingDate
	|		AND PaymentsByGiftCard.Hotel = &qHotel
	|		AND (&qCompanyIsEmpty
	|				OR NOT &qCompanyIsEmpty
	|					AND PaymentsByGiftCard.Payment.Company = &qCompany)
	|		AND PaymentsByGiftCard.OperationType = VALUE(Enum.BonusesPaymentTypes.Expense)
	|		AND PaymentsByGiftCard.Source = """"
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		BEGINOFPERIOD(GiftCardOperations.Date, DAY),
	|		GiftCardOperations.Card.Folio.FolioCurrency,
	|		GiftCardOperations.Card.DiscountType.ProformaInvoiceService,
	|		GiftCardOperations.Card.Folio.FinancialAccount,
	|		GiftCardOperations.Hotel.Company.VATRate,
	|		CASE
	|			WHEN GiftCardOperations.OperationType = VALUE(Enum.BonusesOperationTypes.Receipt)
	|				THEN GiftCardOperations.BonusesQuantity - (CAST(GiftCardOperations.BonusesQuantity * ISNULL(VATRateTaxRates.TaxRate, GiftCardOperations.Hotel.Company.VATRate.TaxRate) / (100 + ISNULL(VATRateTaxRates.TaxRate, GiftCardOperations.Hotel.Company.VATRate.TaxRate)) AS NUMBER(17, 2)))
	|			ELSE -(GiftCardOperations.BonusesQuantity - (CAST(GiftCardOperations.BonusesQuantity * ISNULL(VATRateTaxRates.TaxRate, GiftCardOperations.Hotel.Company.VATRate.TaxRate) / (100 + ISNULL(VATRateTaxRates.TaxRate, GiftCardOperations.Hotel.Company.VATRate.TaxRate)) AS NUMBER(17, 2))))
	|		END,
	|		CASE
	|			WHEN GiftCardOperations.OperationType = VALUE(Enum.BonusesOperationTypes.Receipt)
	|				THEN CAST(GiftCardOperations.BonusesQuantity * ISNULL(VATRateTaxRates.TaxRate, GiftCardOperations.Hotel.Company.VATRate.TaxRate) / (100 + ISNULL(VATRateTaxRates.TaxRate, GiftCardOperations.Hotel.Company.VATRate.TaxRate)) AS NUMBER(17, 2))
	|			ELSE -(CAST(GiftCardOperations.BonusesQuantity * ISNULL(VATRateTaxRates.TaxRate, GiftCardOperations.Hotel.Company.VATRate.TaxRate) / (100 + ISNULL(VATRateTaxRates.TaxRate, GiftCardOperations.Hotel.Company.VATRate.TaxRate)) AS NUMBER(17, 2)))
	|		END
	|	FROM
	|		Document.BonusesOperation AS GiftCardOperations
	|			LEFT JOIN InformationRegister.VATRatesHistory.SliceLast(&qAccountingDate, ) AS VATRateTaxRates
	|			ON GiftCardOperations.Hotel.Company.VATRate = VATRateTaxRates.VATRate
	|	WHERE
	|		BEGINOFPERIOD(GiftCardOperations.Date, DAY) = &qAccountingDate
	|		AND GiftCardOperations.Hotel = &qHotel
	|		AND (&qCompanyIsEmpty
	|				OR NOT &qCompanyIsEmpty
	|					AND GiftCardOperations.Card.Folio.Company = &qCompany)) AS GiftCardsPayments
	|		LEFT JOIN InformationRegister.VATRatesHistory.SliceLast(&qAccountingDate, ) AS VATRatesHistory
	|		ON GiftCardsPayments.VATRate = VATRatesHistory.VATRate
	|
	|ORDER BY
	|	ServiceCode,
	|	VATTaxRate";
	vQry.SetParameter("qAccountingDate", pAccountingDate);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qCompany", pCompany);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(pCompany));
	
	vGCPayments = vQry.Execute().Unload();
	For Each vRow In vGCPayments Do
		vAccountCode = "";
		vAccountStruct = cmGetAccountCodeForService(pHotel, pCompany, vRow.Service, vRow.VATRate, pAccountingDate);
		vAccount = vAccountStruct.Account;
		If Not IsBlankString(vAccountStruct.Code) Then
			vAccountCode = TrimAll(vAccountStruct.Code);
		ElsIf ValueIsFilled(vAccountStruct.Account) And Not IsBlankString(vAccountStruct.Account.CodeBO) Then
			vAccountCode = TrimAll(vAccountStruct.Account.CodeBO);
		EndIf;
		If IsBlankString(vAccountCode) Then
			Raise NStr("en='Failed to get account code for the service / VAT rate: '; ru='Ошибка получения номера счета бухгалтерии для услуги / ставки НДС: '; de='Fehler beim Abrufen des Kontocodes für den Service / Mehrwertsteuersatz: '") + vRow.ServiceDescription + " / " + vRow.VATRateDescription + ", " + pHotel + ", " + pCompany;
		EndIf;
		
		vDepartmentCode = "";
		If ValueIsFilled(vRow.Service) And ValueIsFilled(vRow.Service.DepartmentCode) Then
			vDepartmentCodeRef = vRow.Service.DepartmentCode;
			If Not IsBlankString(vDepartmentCodeRef.CodeBO) Then
				vDepartmentCode = TrimAll(vDepartmentCodeRef.CodeBO);
			Else
				vDepartmentCode = TrimAll(vDepartmentCodeRef.Code);
			EndIf;
		EndIf;
		
		vAccountDt = vAccount;
		If ValueIsFilled(vRow.FinancialAccount) Then
			vAccountCr = vRow.FinancialAccount;
		Else
			vAccountCr = ChartsOfAccounts.ChartOfAccountsFO.GuestLedger;
		EndIf;
		
		vIncomePaymentXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomePayment"));
		
		vIncomePaymentXDTO.AccountingDate = vRow.AccountingDate;
		vIncomePaymentXDTO.POSName = "";
		vIncomePaymentXDTO.PaymentMethodName = "Payment by gift card";
		vIncomePaymentXDTO.AmountWithoutVAT = cmConvertCurrencies(vRow.SumWithoutVAT, vRow.Currency, , pHotel.ReportingCurrency, , vRow.AccountingDate, pHotel);
		vIncomePaymentXDTO.VATAmount = cmConvertCurrencies(vRow.VATSum, vRow.Currency, , pHotel.ReportingCurrency, , vRow.AccountingDate, pHotel);
		vIncomePaymentXDTO.Amount = vIncomePaymentXDTO.AmountWithoutVAT;
		vIncomePaymentXDTO.VATRateName = vRow.VATRateDescription;
		If vRow.NoVAT Then
			vIncomePaymentXDTO.VATTaxRate = -1;
		Else
			vIncomePaymentXDTO.VATTaxRate = vRow.VATTaxRate;
		EndIf;
		vIncomePaymentXDTO.IsPrepayment = False;
		vIncomePaymentXDTO.IsPrepaymentClearing = False;
		vIncomePaymentXDTO.AccountCodeDt = vAccountCode;
		If ValueIsFilled(vRow.FinancialAccount) Then
			vIncomePaymentXDTO.AccountCodeCr = ?(Not IsBlankString(vRow.FinancialAccount.CodeBO), TrimAll(vRow.FinancialAccount.CodeBO), TrimAll(vRow.FinancialAccount.Code));
		Else
			vIncomePaymentXDTO.AccountCodeCr = TrimAll(ChartsOfAccounts.ChartOfAccountsFO.GuestLedger.CodeBO);
		EndIf;
		
		vCustomerXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CustomersItemRow"));
		vCustomerXDTO.IsIndividual = True;
		vCustomerXDTO.Code = "";
		vCustomerXDTO.Description = "";
		vCustomerXDTO.ExternalCode = "";
		vCustomerXDTO.TIN = "";
		vCustomerXDTO.VATCode = "";
		vCustomerXDTO.EMail = "";
		vCustomerXDTO.Phone = "";
		vCustomerXDTO.Address = "";
		vCustomerXDTO.CountryCode = 0;
		vCustomerXDTO.CountryISOCode2 = "";
		vCustomerXDTO.CountryISOCode3 = "";
		vCustomerXDTO.DateOfBirth = '00010101';
		vIncomePaymentXDTO.Customer = vCustomerXDTO;
		
		// Analysis items
		If pUsePostingsFOData Then
			FillAnalysisItems(vAccountDt, vAccountCr, vIncomePaymentXDTO);
		EndIf;
		
		vIncomePaymentsXDTO.IncomePayment.Add(vIncomePaymentXDTO);
		
		If Not vRow.NoVAT Then
			vVATAccountCode = "";
			vVATAccountStruct = cmGetAccountCodeForVATRate(pHotel, pCompany, vRow.VATRate);
			vVATAccount = vVATAccountStruct.Account;
			If Not IsBlankString(vVATAccountStruct.Code) Then
				vVATAccountCode = TrimAll(vVATAccountStruct.Code);
			ElsIf ValueIsFilled(vVATAccountStruct.Account) And Not IsBlankString(vVATAccountStruct.Account.CodeBO) Then
				vVATAccountCode = TrimAll(vVATAccountStruct.Account.CodeBO);
			EndIf;
			If IsBlankString(vVATAccountCode) Then
				Raise NStr("en='Failed to get account code for the VAT rate: '; ru='Ошибка получения номера счета бухгалтерии для ставки НДС: '; de='Fehler beim Abrufen des Kontocodes für den Mehrwertsteuersatz: '") + TrimAll(vRow.VATRate) + ", " + pHotel + ", " + pCompany;
			EndIf;
			
			vAccountDt = vVATAccount;
			If ValueIsFilled(vRow.FinancialAccount) Then
				vAccountCr = vRow.FinancialAccount;
			Else
				vAccountCr = ChartsOfAccounts.ChartOfAccountsFO.GuestLedger;
			EndIf;
					
			vIncomePaymentXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomePayment"));
			
			vIncomePaymentXDTO.AccountingDate = vRow.AccountingDate;
			vIncomePaymentXDTO.POSName = "";
			vIncomePaymentXDTO.PaymentMethodName = "";
			vIncomePaymentXDTO.AmountWithoutVAT = 0;
			vIncomePaymentXDTO.VATAmount = cmConvertCurrencies(vRow.VATSum, vRow.Currency, , pHotel.ReportingCurrency, , vRow.AccountingDate, pHotel);
			vIncomePaymentXDTO.Amount = vIncomePaymentXDTO.VATAmount;
			vIncomePaymentXDTO.VATRateName = vRow.VATRateDescription;
			vIncomePaymentXDTO.VATTaxRate = vRow.VATTaxRate;
			vIncomePaymentXDTO.IsPrepayment = False;
			vIncomePaymentXDTO.IsPrepaymentClearing = False;
			vIncomePaymentXDTO.AccountCodeDt = vVATAccountCode;
			If ValueIsFilled(vRow.FinancialAccount) Then
				vIncomePaymentXDTO.AccountCodeCr = ?(Not IsBlankString(vRow.FinancialAccount.CodeBO), TrimAll(vRow.FinancialAccount.CodeBO), TrimAll(vRow.FinancialAccount.Code));
			Else
				vIncomePaymentXDTO.AccountCodeCr = TrimAll(ChartsOfAccounts.ChartOfAccountsFO.GuestLedger.CodeBO);
			EndIf;
			
			vCustomerXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CustomersItemRow"));
			vCustomerXDTO.IsIndividual = True;
			vCustomerXDTO.Code = "";
			vCustomerXDTO.Description = "";
			vCustomerXDTO.ExternalCode = "";
			vCustomerXDTO.TIN = "";
			vCustomerXDTO.VATCode = "";
			vCustomerXDTO.EMail = "";
			vCustomerXDTO.Phone = "";
			vCustomerXDTO.Address = "";
			vCustomerXDTO.CountryCode = 0;
			vCustomerXDTO.CountryISOCode2 = "";
			vCustomerXDTO.CountryISOCode3 = "";
			vCustomerXDTO.DateOfBirth = '00010101';
			vIncomePaymentXDTO.Customer = vCustomerXDTO;
			
			// Analysis items
			If pUsePostingsFOData Then
				FillAnalysisItems(vAccountDt, vAccountCr, vIncomePaymentXDTO);
			EndIf;
			
			vIncomePaymentsXDTO.IncomePayment.Add(vIncomePaymentXDTO);
		EndIf;
	EndDo;
	
	// Special postings like POS tips and so on
	vPstQry = New Query();
	vPstQry.Text = 
	"SELECT
	|	CASE
	|		WHEN PostingsFO.Recorder.Folio.Customer <> PostingsFO.Recorder.Hotel.IndividualsCustomer
	|				AND PostingsFO.Recorder.Folio.Customer <> VALUE(Catalog.Customers.EmptyRef)
	|			THEN PostingsFO.Recorder.Folio.Customer
	|		ELSE NULL
	|	END AS Customer,
	|	PostingsFO.Recorder.Folio.Client AS Client,
	|	PostingsFO.Recorder.Folio.Client.Code AS ClientCode,
	|	PostingsFO.Recorder.Folio.Client.FullName AS ClientFullName,
	|	PostingsFO.Recorder.Folio.FolioCurrency AS Currency,
	|	PostingsFO.Recorder AS Recorder,
	|	PostingsFO.Recorder.Service.Description AS ServiceDescription,
	|	PostingsFO.Recorder.Remarks AS RecorderRemarks,
	|	PostingsFO.Account AS Account,
	|	PostingsFO.Account.Code AS AccountCode,
	|	PostingsFO.Account.CodeBO AS AccountCodeBO,
	|	PostingsFO.Account.Description AS AccountDescription,
	|	PostingsFO.CorrAccount AS CorrAccount,
	|	PostingsFO.CorrAccount.Code AS CorrAccountCode,
	|	PostingsFO.CorrAccount.CodeBO AS CorrAccountCodeBO,
	|	PostingsFO.VATRate AS VATRate,
	|	ISNULL(PostingsFO.VATRate.Description, """") AS VATRateDescription,
	|	ISNULL(PostingsFO.VATRate.NoVAT, FALSE) AS NoVAT,
	|	ISNULL(VATRatesHistory.TaxRate, PostingsFO.VATRate.TaxRate) AS VATTaxRate,
	|	PostingsFO.Amount AS Amount,
	|	PostingsFO.VATAmount AS VATAmount
	|FROM
	|	AccountingRegister.PostingsFO AS PostingsFO
	|		LEFT JOIN InformationRegister.VATRatesHistory.SliceLast(&qAccountingDate, ) AS VATRatesHistory
	|		ON PostingsFO.VATRate = VATRatesHistory.VATRate
	|WHERE
	|	BEGINOFPERIOD(PostingsFO.Period, DAY) = &qAccountingDate
	|	AND (PostingsFO.Recorder REFS Document.Charge
	|			OR PostingsFO.Recorder REFS Document.Storno)
	|	AND (&qCompanyIsEmpty
	|			OR NOT &qCompanyIsEmpty
	|				AND PostingsFO.Company = &qCompany)
	|	AND PostingsFO.RecordType = VALUE(AccountingRecordType.Credit)
	|	AND PostingsFO.AccountGroup <> VALUE(Catalog.AccountGroups.Income)
	|	AND PostingsFO.AccountGroup <> VALUE(Catalog.AccountGroups.Expenses)
	|	AND PostingsFO.AccountGroup <> VALUE(Catalog.AccountGroups.Liabilities)
	|	AND PostingsFO.Account <> VALUE(ChartOfAccounts.ChartOfAccountsFO.GuestLedger)";
	vPstQry.SetParameter("qAccountingDate", pAccountingDate);
	vPstQry.SetParameter("qHotel", pHotel);
	vPstQry.SetParameter("qCompany", pCompany);
	vPstQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(pCompany));
	
	vTips = vPstQry.Execute().Unload();
	For Each vTipsRow In vTips Do
		vAccount = vTipsRow.Account;
		vAccountCode = ?(IsBlankString(vTipsRow.AccountCodeBO), TrimAll(vTipsRow.AccountCode), TrimAll(vTipsRow.AccountCodeBO));
		vCorrAccount = vTipsRow.CorrAccount;
		vCorrAccountCode = ?(IsBlankString(vTipsRow.CorrAccountCodeBO), TrimAll(vTipsRow.CorrAccountCode), TrimAll(vTipsRow.CorrAccountCodeBO));
		
		vAccountDt = vCorrAccount;
		vAccountCr = vAccount;
		
		vIncomePaymentXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomePayment"));
		
		vIncomePaymentXDTO.AccountingDate = pAccountingDate;
		vIncomePaymentXDTO.POSName = TrimAll(vTipsRow.ServiceDescription);
		vIncomePaymentXDTO.PaymentMethodName = TrimAll(vTipsRow.AccountDescription);
		vIncomePaymentXDTO.VATAmount = cmConvertCurrencies(vTipsRow.VATAmount, vTipsRow.Currency, , pHotel.ReportingCurrency, , pAccountingDate, pHotel);
		vIncomePaymentXDTO.Amount = cmConvertCurrencies(vTipsRow.Amount, vTipsRow.Currency, , pHotel.ReportingCurrency, , pAccountingDate, pHotel);
		vIncomePaymentXDTO.AmountWithoutVAT = vIncomePaymentXDTO.Amount - vIncomePaymentXDTO.VATAmount;
		vIncomePaymentXDTO.VATRateName = vTipsRow.VATRateDescription;
		If vTipsRow.NoVAT Then
			vIncomePaymentXDTO.VATTaxRate = -1;
		Else
			vIncomePaymentXDTO.VATTaxRate = vTipsRow.VATTaxRate;
		EndIf;
		vIncomePaymentXDTO.IsPrepayment = False;
		vIncomePaymentXDTO.IsPrepaymentClearing = False;
		vIncomePaymentXDTO.AccountCodeDt = vCorrAccountCode;
		vIncomePaymentXDTO.AccountCodeCr = vAccountCode;
		
		vCustomerXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CustomersItemRow"));
		vCustomerXDTO.IsIndividual = True;
		vCustomerXDTO.Code = TrimAll(vTipsRow.RecorderRemarks);
		vCustomerXDTO.Description = TrimAll(vTipsRow.ClientFullName);
		vCustomerXDTO.ExternalCode = "";
		vCustomerXDTO.TIN = "";
		vCustomerXDTO.VATCode = "";
		vCustomerXDTO.EMail = "";
		vCustomerXDTO.Phone = "";
		vCustomerXDTO.Address = "";
		vCustomerXDTO.CountryCode = 0;
		vCustomerXDTO.CountryISOCode2 = "";
		vCustomerXDTO.CountryISOCode3 = "";
		vCustomerXDTO.DateOfBirth = '00010101';
		vIncomePaymentXDTO.Customer = vCustomerXDTO;
		
		// Analysis items
		If pUsePostingsFOData Then
			FillAnalysisItems(vAccountDt, vAccountCr, vIncomePaymentXDTO);
		EndIf;
		
		vIncomePaymentsXDTO.IncomePayment.Add(vIncomePaymentXDTO);
	EndDo;	
	
	Return vIncomePaymentsXDTO;
EndFunction // GetIncomePayments

// -----------------------------------------------------------------------------
Function GetInvoiceCommission(pInvoice)
	vCommissionSum = pInvoice.CommissionSum;
	If pInvoice.PerInvoiceCommissionSum <> 0 Then
		vCommissionSum = vCommissionSum + pInvoice.PerInvoiceCommissionSum;
	EndIf;
	Return vCommissionSum;
EndFunction // GetInvoiceCommission

// -----------------------------------------------------------------------------
Function GetIncomeInvoices(pHotel, pCompany, pAccountingDate, pExternalSystemCode, pUsePostingsFOData = False)
	vIncomeInvoicesXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomeInvoices"));
	
	// Run query to get data
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	BEGINOFPERIOD(CustomerAccountsMovements.Recorder.Date, DAY) AS AccountingDate,
	|	CustomerAccountsMovements.AccountingCustomer AS Customer,
	|	CustomerAccountsMovements.AccountingCustomer.Code AS CustomerCode,
	|	CustomerAccountsMovements.AccountingCustomer.Description AS CustomerDescription,
	|	CustomerAccountsMovements.AccountingCustomer.LegacyName AS CustomerLegacyName,
	|	CAST(CustomerAccountsMovements.AccountingCustomer.LegacyAddress AS STRING(999)) AS CustomerAddress,
	|	CustomerAccountsMovements.AccountingCustomer.Country.Code AS CustomerCountryCode,
	|	CustomerAccountsMovements.AccountingCustomer.Country.ISOCode AS CustomerCountryISOCode,
	|	CustomerAccountsMovements.AccountingCustomer.Country.ISOCode3 AS CustomerCountryISOCode3,
	|	CustomerAccountsMovements.AccountingCustomer.Phone AS CustomerPhone,
	|	CustomerAccountsMovements.AccountingCustomer.EMail AS CustomerEMail,
	|	CustomerAccountsMovements.AccountingCustomer.TIN AS CustomerTIN,
	|	CustomerAccountsMovements.AccountingCustomer.VATC AS CustomerVATCode,
	|	CustomerAccountsMovements.AccountingCustomer.DateOfBirth AS CustomerDateOfBirth,
	|	CustomerAccountsMovements.AccountingCustomer.IsIndividual AS CustomerIsIndividual,
	|	CustomerAccountsMovements.AccountingContract AS Contract,
	|	CustomerAccountsMovements.AccountingContract.Code AS ContractCode,
	|	CustomerAccountsMovements.AccountingContract.Description AS ContractDescription,
	|	CustomerAccountsMovements.AccountingContract.Date AS ContractDate,
	|	CustomerAccountsMovements.AccountingCurrency AS Currency,
	|	CustomerAccountsMovements.Recorder AS Recorder,
	|	CustomerAccountsMovements.Recorder.Number AS RecorderNumber,
	|	CASE
	|		WHEN NOT CustomerAccountsMovements.Recorder.FolioDescription IS NULL
	|			THEN CustomerAccountsMovements.Recorder.FolioDescription
	|		WHEN NOT CustomerAccountsMovements.Recorder.Invoice.FolioDescription IS NULL
	|			THEN CustomerAccountsMovements.Recorder.Invoice.FolioDescription
	|		ELSE """"
	|	END AS FolioDescription,
	|	CustomerAccountsMovements.GuestGroup AS GuestGroup,
	|	CustomerAccountsMovements.GuestGroup.Code AS GuestGroupCode,
	|	CustomerAccountsMovements.GuestGroup.Description AS GuestGroupDescription,
	|	CustomerAccountsMovements.GuestGroup.ID AS GuestGroupRefCode,
	|	CustomerAccountsMovements.GuestGroup.Client AS Client,
	|	CustomerAccountsMovements.GuestGroup.Client.FullName AS ClientFullName,
	|	CustomerAccountsMovements.GuestGroup.Client.Code AS ClientCode,
	|	CAST(CustomerAccountsMovements.GuestGroup.Client.Address AS STRING(999)) AS ClientAddress,
	|	CustomerAccountsMovements.GuestGroup.Client.Citizenship.Code AS ClientCountryCode,
	|	CustomerAccountsMovements.GuestGroup.Client.Citizenship.ISOCode AS ClientCountryISOCode,
	|	CustomerAccountsMovements.GuestGroup.Client.Citizenship.ISOCode3 AS ClientCountryISOCode3,
	|	CustomerAccountsMovements.GuestGroup.Client.Phone AS ClientPhone,
	|	CustomerAccountsMovements.GuestGroup.Client.EMail AS ClientEMail,
	|	CustomerAccountsMovements.GuestGroup.Client.TIN AS ClientTIN,
	|	CustomerAccountsMovements.GuestGroup.Client.DateOfBirth AS ClientDateOfBirth,
	|	CustomerAccountsMovements.GuestGroup.CheckInDate AS CheckInDate,
	|	CustomerAccountsMovements.GuestGroup.CheckOutDate AS CheckOutDate,
	|	ISNULL(CustomerAccountsMovements.GuestGroup.ClientDoc.NumberOfAdults, 0) AS NumberOfAdults,
	|	ISNULL(CustomerAccountsMovements.GuestGroup.ClientDoc.NumberOfTeenagers, 0) AS NumberOfTeenagers,
	|	ISNULL(CustomerAccountsMovements.GuestGroup.ClientDoc.NumberOfChildren, 0) AS NumberOfChildren,
	|	ISNULL(CustomerAccountsMovements.GuestGroup.ClientDoc.NumberOfInfants, 0) AS NumberOfInfants,
	|	CustomerAccountsMovements.Hotel.PaymentsGenerateInvoices AS HotelPaymentsGenerateInvoices,
	|	SUM(CASE
	|			WHEN CustomerAccountsMovements.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -CustomerAccountsMovements.Sum
	|			ELSE CustomerAccountsMovements.Sum
	|		END) AS Sum
	|FROM
	|	AccumulationRegister.CustomerAccounts AS CustomerAccountsMovements
	|WHERE
	|	CASE
	|			WHEN CustomerAccountsMovements.Hotel.PaymentsGenerateInvoices
	|				THEN BEGINOFPERIOD(CustomerAccountsMovements.Recorder.Date, DAY)
	|			ELSE BEGINOFPERIOD(CustomerAccountsMovements.Recorder.ChangeDate, DAY)
	|		END = &qAccountingDate
	|	AND ISNULL(CustomerAccountsMovements.Recorder.IsChecked, FALSE)
	|	AND (CustomerAccountsMovements.Recorder REFS Document.Settlement
	|			OR CustomerAccountsMovements.Recorder REFS Document.DebitNote
	|			OR CustomerAccountsMovements.Recorder REFS Document.CreditNote)
	|	AND CustomerAccountsMovements.Hotel = &qHotel
	|	AND (&qCompanyIsEmpty
	|			OR NOT &qCompanyIsEmpty
	|				AND CustomerAccountsMovements.Company = &qCompany)
	|	AND (CustomerAccountsMovements.Hotel.PaymentsGenerateInvoices
	|				AND CustomerAccountsMovements.AccountingCustomer <> CustomerAccountsMovements.Hotel.IndividualsCustomer
	|			OR NOT CustomerAccountsMovements.Hotel.PaymentsGenerateInvoices)
	|
	|GROUP BY
	|	BEGINOFPERIOD(CustomerAccountsMovements.Recorder.Date, DAY),
	|	CustomerAccountsMovements.AccountingCustomer,
	|	CustomerAccountsMovements.AccountingCustomer.Description,
	|	CustomerAccountsMovements.AccountingCurrency,
	|	CustomerAccountsMovements.Recorder,
	|	CustomerAccountsMovements.Recorder.Number,
	|	CASE
	|		WHEN NOT CustomerAccountsMovements.Recorder.FolioDescription IS NULL
	|			THEN CustomerAccountsMovements.Recorder.FolioDescription
	|		WHEN NOT CustomerAccountsMovements.Recorder.Invoice.FolioDescription IS NULL
	|			THEN CustomerAccountsMovements.Recorder.Invoice.FolioDescription
	|		ELSE """"
	|	END,
	|	CustomerAccountsMovements.GuestGroup,
	|	CustomerAccountsMovements.GuestGroup.Code,
	|	CustomerAccountsMovements.GuestGroup.Description,
	|	CustomerAccountsMovements.GuestGroup.ID,
	|	CustomerAccountsMovements.GuestGroup.Client.FullName,
	|	CustomerAccountsMovements.GuestGroup.CheckInDate,
	|	CustomerAccountsMovements.GuestGroup.CheckOutDate,
	|	ISNULL(CustomerAccountsMovements.GuestGroup.ClientDoc.NumberOfAdults, 0),
	|	ISNULL(CustomerAccountsMovements.GuestGroup.ClientDoc.NumberOfTeenagers, 0),
	|	ISNULL(CustomerAccountsMovements.GuestGroup.ClientDoc.NumberOfChildren, 0),
	|	ISNULL(CustomerAccountsMovements.GuestGroup.ClientDoc.NumberOfInfants, 0),
	|	CustomerAccountsMovements.AccountingCustomer.Code,
	|	CustomerAccountsMovements.AccountingCustomer.LegacyName,
	|	CustomerAccountsMovements.AccountingCustomer.Country.Code,
	|	CustomerAccountsMovements.AccountingCustomer.Country.ISOCode,
	|	CustomerAccountsMovements.AccountingCustomer.Country.ISOCode3,
	|	CustomerAccountsMovements.AccountingCustomer.Phone,
	|	CustomerAccountsMovements.AccountingCustomer.EMail,
	|	CustomerAccountsMovements.AccountingCustomer.TIN,
	|	CustomerAccountsMovements.AccountingCustomer.VATC,
	|	CustomerAccountsMovements.AccountingCustomer.DateOfBirth,
	|	CustomerAccountsMovements.AccountingContract,
	|	CustomerAccountsMovements.AccountingContract.Code,
	|	CustomerAccountsMovements.AccountingContract.Description,
	|	CustomerAccountsMovements.AccountingContract.Date,
	|	CustomerAccountsMovements.GuestGroup.Client.Code,
	|	CustomerAccountsMovements.GuestGroup.Client.Citizenship.Code,
	|	CustomerAccountsMovements.GuestGroup.Client.Citizenship.ISOCode,
	|	CustomerAccountsMovements.GuestGroup.Client.Citizenship.ISOCode3,
	|	CustomerAccountsMovements.GuestGroup.Client.Phone,
	|	CustomerAccountsMovements.GuestGroup.Client.EMail,
	|	CustomerAccountsMovements.GuestGroup.Client.TIN,
	|	CustomerAccountsMovements.GuestGroup.Client.DateOfBirth,
	|	CAST(CustomerAccountsMovements.AccountingCustomer.LegacyAddress AS STRING(999)),
	|	CAST(CustomerAccountsMovements.GuestGroup.Client.Address AS STRING(999)),
	|	CustomerAccountsMovements.GuestGroup.Client,
	|	CustomerAccountsMovements.AccountingCustomer.IsIndividual,
	|	CustomerAccountsMovements.Hotel.PaymentsGenerateInvoices
	|
	|ORDER BY
	|	CustomerDescription,
	|	RecorderNumber";
	vQry.SetParameter("qAccountingDate", pAccountingDate);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qCompany", pCompany);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(pCompany));
	
	vTotals = vQry.Execute().Unload();
	
	vDefaultCustomerAccountCode = "";
	vDefaultCustomerAccount = Undefined;
	vCompany = pCompany;
	If Not ValueIsFilled(vCompany) And ValueIsFilled(pHotel) And ValueIsFilled(pHotel.Company) Then
		vCompany = pHotel.Company;
	EndIf;
	If ValueIsFilled(vCompany) And Not IsBlankString(vCompany.InvoicesAccountCode) Then
		vDefaultCustomerAccountCode = TrimAll(vCompany.InvoicesAccountCode);
		vDefaultCustomerAccount = ChartsOfAccounts.ChartOfAccountsFO.FindByCode(vDefaultCustomerAccountCode);
	EndIf;
	
	For Each vRow In vTotals Do
		vInvoice = vRow.Recorder;
		If vRow.Sum = 0 Then
			Continue;
		EndIf;
		
		vAccountCode = "";
		vAccount = Undefined;
		If ValueIsFilled(vInvoice) And TypeOf(vInvoice) = Type("DocumentRef.Settlement") Then
			If ValueIsFilled(vInvoice.ParentDoc) And TypeOf(vInvoice.ParentDoc) = Type("DocumentRef.Folio") Then
				If ValueIsFilled(vInvoice.ParentDoc.AccountCodeBO) Then
					vAccountCode = vInvoice.ParentDoc.AccountCodeBO;
				EndIf;
			EndIf;
		EndIf;
		If IsBlankString(vAccountCode) Then
			vAccountStruct = cmGetAccountCodeForCustomer(pHotel, pCompany, vRow.Customer, vRow.Contract, vRow.FolioDescription);
			vAccount = vAccountStruct.Account;
			If Not IsBlankString(vAccountStruct.Code) Then
				vAccountCode = TrimAll(vAccountStruct.Code);
			ElsIf ValueIsFilled(vAccountStruct.Account) And Not IsBlankString(vAccountStruct.Account.CodeBO) Then
				vAccountCode = TrimAll(vAccountStruct.Account.CodeBO);
			EndIf;
			If IsBlankString(vAccountCode) And Not IsBlankString(vDefaultCustomerAccountCode) Then
				vAccountCode = vDefaultCustomerAccountCode;
				vAccount = vDefaultCustomerAccount;
			EndIf;
		EndIf;
		
		vIncomeInvoiceXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomeInvoice"));
		
		vIncomeInvoiceXDTO.AccountingDate = vRow.AccountingDate;
		vSumDue = 0;
		vCommissionSum = 0;
		If TypeOf(vInvoice) = Type("DocumentRef.DebitNote") Then
			vIncomeInvoiceXDTO.InvoiceNumber = "DNT-" + vRow.RecorderNumber;
			vSumDue = vInvoice.CorrectionSum;
		ElsIf TypeOf(vInvoice) = Type("DocumentRef.CreditNote") Then
			vIncomeInvoiceXDTO.InvoiceNumber = "CNT-" + vRow.RecorderNumber;
			vSumDue = -vInvoice.CorrectionSum;
		Else
			vIncomeInvoiceXDTO.InvoiceNumber = "INV-" + vRow.RecorderNumber;
			vSumDue = vInvoice.SumDue;
			vCommissionSum = GetInvoiceCommission(vInvoice);
		EndIf;
				
		vIncomeInvoiceXDTO.ReservationNumber = Format(vRow.GuestGroupCode, "NFD=0; NG=") + ?(IsBlankString(vRow.GuestGroupDescription), "", " / " + vRow.GuestGroupDescription);
		vIncomeInvoiceXDTO.ReservationRefCode = TrimAll(vRow.GuestGroupRefCode);
		vIncomeInvoiceXDTO.NumberOfAdults = vRow.NumberOfAdults;
		vIncomeInvoiceXDTO.NumberOfTeenagers = vRow.NumberOfTeenagers;
		vIncomeInvoiceXDTO.NumberOfChildren = vRow.NumberOfChildren;
		vIncomeInvoiceXDTO.NumberOfInfants = vRow.NumberOfInfants;
		vIncomeInvoiceXDTO.GuestDescription = TrimAll(vRow.ClientFullName) + ", " + Format(vRow.CheckInDate, "DF=dd.MM.yyyy") + " - " + Format(vRow.CheckOutDate, "DF=dd.MM.yyyy");
		vIncomeInvoiceXDTO.Amount = vRow.Sum;
		vIncomeInvoiceXDTO.AmountDue = vSumDue;
		vIncomeInvoiceXDTO.AccountCode = vAccountCode;
		vIncomeInvoiceXDTO.CommissionAmount = vCommissionSum;
		
		// Customer
		vCustomerXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CustomersItemRow"));
		If ValueIsFilled(vRow.Customer) And vRow.Customer <> pHotel.IndividualsCustomer Then
			vCustomerXDTO.IsIndividual = vRow.CustomerIsIndividual;
			vCustomerXDTO.Code = TrimAll(vRow.CustomerCode);
			vCustomerXDTO.Description = ?(IsBlankString(TrimAll(vRow.CustomerLegacyName)), TrimAll(vRow.CustomerDescription), TrimAll(vRow.CustomerLegacyName));
			vCustomerXDTO.ExternalCode = cmGetObjectExternalSystemCodeByRef(pHotel, pExternalSystemCode, "Customers", vRow.Customer, True);
			vCustomerXDTO.TIN = TrimAll(vRow.CustomerTIN);
			vCustomerXDTO.VATCode = TrimAll(vRow.CustomerVATCode);
			vCustomerXDTO.EMail = TrimAll(vRow.CustomerEMail);
			vCustomerXDTO.Phone = TrimAll(vRow.CustomerPhone);
			vCustomerXDTO.Address = TrimAll(vRow.CustomerAddress);
			vCustomerXDTO.CountryCode = ?(vRow.CustomerCountryCode = Null, 0, vRow.CustomerCountryCode);
			vCustomerXDTO.CountryISOCode2 = TrimAll(vRow.CustomerCountryISOCode);
			vCustomerXDTO.CountryISOCode3 = TrimAll(vRow.CustomerCountryISOCode3);
			vCustomerXDTO.DateOfBirth = ?(ValueIsFilled(vRow.CustomerDateOfBirth), vRow.CustomerDateOfBirth, '00010101');
		Else
			vCustomerXDTO.IsIndividual = True;
			vCustomerXDTO.Code = TrimAll(vRow.ClientCode);
			vCustomerXDTO.Description = TrimAll(vRow.ClientFullName);
			vCustomerXDTO.ExternalCode = cmGetObjectExternalSystemCodeByRef(pHotel, pExternalSystemCode, "Clients", vRow.Client, True);
			vCustomerXDTO.TIN = TrimAll(vRow.ClientTIN);
			vCustomerXDTO.VATCode = "";
			vCustomerXDTO.EMail = TrimAll(vRow.ClientEMail);
			vCustomerXDTO.Phone = TrimAll(vRow.ClientPhone);
			vCustomerXDTO.Address = TrimAll(vRow.ClientAddress);
			vCustomerXDTO.CountryCode = ?(vRow.ClientCountryCode = Null, 0, vRow.ClientCountryCode);
			vCustomerXDTO.CountryISOCode2 = TrimAll(vRow.ClientCountryISOCode);
			vCustomerXDTO.CountryISOCode3 = TrimAll(vRow.ClientCountryISOCode3);
			vCustomerXDTO.DateOfBirth = ?(ValueIsFilled(vRow.ClientDateOfBirth), vRow.ClientDateOfBirth, '00010101');
		EndIf;
		vIncomeInvoiceXDTO.Customer = vCustomerXDTO;
		
		// Contract
		If ValueIsFilled(vRow.Contract) And vRow.Contract <> pHotel.IndividualsContract Then
			vContractXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "Contract"));
			vContractXDTO.Code = TrimAll(vRow.ContractCode);
			vContractXDTO.Description = TrimAll(vRow.ContractDescription);
			vContractXDTO.Date = vRow.ContractDate;
			vIncomeInvoiceXDTO.Contract = vContractXDTO;
		EndIf;
		
		// Analysis items
		If pUsePostingsFOData Then
			FillAnalysisItem(vAccount, vIncomeInvoiceXDTO);
		EndIf;
		
		// VAT
		vVATXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomeVAT"));
		vVATs = vInvoice.Services.Unload(, "VATRate, VATSum");
		vVATs.GroupBy("VATRate", "VATSum");
		For Each vVATsRow In vVATs Do
			vVATRowXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomeVATRate"));
			
			vVATRowXDTO.AccountingDate = vRow.AccountingDate;
			vVATRowXDTO.VATRateName = TrimAll(vVATsRow.VATRate);
			vVATRowXDTO.VATTaxRate = ?(ValueIsFilled(vVATsRow.VATRate), ?(vVATsRow.VATRate.NoVAT, -1, CachedAccounts.GetVATTaxRate(vVATsRow.VATRate, vRow.AccountingDate)), 0);
			vVATRowXDTO.Amount = vVATsRow.VATSum;
			
			vAccountCode = "";
			vAccountStruct = cmGetAccountCodeForVATRate(pHotel, pCompany, vVATsRow.VATRate);
			vVATAccount = vAccountStruct.Account;
			If Not IsBlankString(vAccountStruct.Code) Then
				vAccountCode = TrimAll(vAccountStruct.Code);
			ElsIf ValueIsFilled(vAccountStruct.Account) And Not IsBlankString(vAccountStruct.Account.CodeBO) Then
				vAccountCode = TrimAll(vAccountStruct.Account.CodeBO);
			EndIf;
			vVATRowXDTO.AccountCode = vAccountCode;
			
			// Analysis items
			If pUsePostingsFOData Then
				FillAnalysisItem(vVATAccount, vVATRowXDTO);
			EndIf;
			
			vVATXDTO.IncomeVATRate.Add(vVATRowXDTO);
		EndDo;
		vIncomeInvoiceXDTO.VATRates = vVATXDTO;
		
		// Cleared proforma invoices
		vClearedProformaInvoicesXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomeProformaInvoices"));
		
		vCPIQry = New Query();
		vCPIQry.Text = 
		"SELECT
		|	PaymentDocuments.PaymentDoc AS PaymentDoc,
		|	PaymentDocuments.PaymentDoc.Invoice AS PaymentDocInvoice,
		|	&qAccountingDate AS AccountingDate
		|INTO PaymentDocuments
		|FROM
		|	Document.Settlement.PaymentDocuments AS PaymentDocuments
		|WHERE
		|	PaymentDocuments.Ref = &qInvoice
		|	AND NOT PaymentDocuments.PaymentDoc.Invoice IS NULL
		|	AND PaymentDocuments.PaymentDoc.Invoice REFS Document.ProformaInvoice
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ProformaInvoices.Ref AS Ref,
		|	PaymentDocuments.AccountingDate AS AccountingDate
		|INTO ProformaInvoices
		|FROM
		|	Document.ProformaInvoice AS ProformaInvoices
		|		INNER JOIN PaymentDocuments AS PaymentDocuments
		|		ON (PaymentDocuments.PaymentDocInvoice = ProformaInvoices.Ref)
		|
		|GROUP BY
		|	ProformaInvoices.Ref,
		|	PaymentDocuments.AccountingDate
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ProformaInvoices.AccountingDate AS AccountingDate,
		|	ProformaInvoices.Ref.AccountingCustomer AS Customer,
		|	ProformaInvoices.Ref.AccountingCustomer.Code AS CustomerCode,
		|	ProformaInvoices.Ref.AccountingCustomer.Description AS CustomerDescription,
		|	ProformaInvoices.Ref.AccountingCustomer.LegacyName AS CustomerLegacyName,
		|	CAST(ProformaInvoices.Ref.AccountingCustomer.LegacyAddress AS STRING(999)) AS CustomerAddress,
		|	ProformaInvoices.Ref.AccountingCustomer.Country.Code AS CustomerCountryCode,
		|	ProformaInvoices.Ref.AccountingCustomer.Country.ISOCode AS CustomerCountryISOCode,
		|	ProformaInvoices.Ref.AccountingCustomer.Country.ISOCode3 AS CustomerCountryISOCode3,
		|	ProformaInvoices.Ref.AccountingCustomer.Phone AS CustomerPhone,
		|	ProformaInvoices.Ref.AccountingCustomer.EMail AS CustomerEMail,
		|	ProformaInvoices.Ref.AccountingCustomer.TIN AS CustomerTIN,
		|	ProformaInvoices.Ref.AccountingCustomer.VATC AS CustomerVATCode,
		|	ProformaInvoices.Ref.AccountingCustomer.DateOfBirth AS CustomerDateOfBirth,
		|	ProformaInvoices.Ref.AccountingCustomer.IsIndividual AS CustomerIsIndividual,
		|	ProformaInvoices.Ref.AccountingContract AS Contract,
		|	ProformaInvoices.Ref.AccountingContract.Code AS ContractCode,
		|	ProformaInvoices.Ref.AccountingContract.Description AS ContractDescription,
		|	ProformaInvoices.Ref.AccountingContract.Date AS ContractDate,
		|	ProformaInvoices.Ref.Sum AS Sum,
		|	ProformaInvoices.Ref.AccountingCurrency AS Currency,
		|	ProformaInvoices.Ref AS Recorder,
		|	ProformaInvoices.Ref.Number AS RecorderNumber,
		|	ProformaInvoices.Ref.GuestGroup AS GuestGroup,
		|	ProformaInvoices.Ref.GuestGroup.Code AS GuestGroupCode,
		|	ProformaInvoices.Ref.GuestGroup.Description AS GuestGroupDescription,
		|	ProformaInvoices.Ref.GuestGroup.ID AS GuestGroupRefCode,
		|	ISNULL(ProformaInvoices.Ref.GuestGroup.ClientDoc.NumberOfAdults, 0) AS NumberOfAdults,
		|	ISNULL(ProformaInvoices.Ref.GuestGroup.ClientDoc.NumberOfTeenagers, 0) AS NumberOfTeenagers,
		|	ISNULL(ProformaInvoices.Ref.GuestGroup.ClientDoc.NumberOfChildren, 0) AS NumberOfChildren,
		|	ISNULL(ProformaInvoices.Ref.GuestGroup.ClientDoc.NumberOfInfants, 0) AS NumberOfInfants,
		|	ProformaInvoices.Ref.GuestGroup.Client AS Client,
		|	ProformaInvoices.Ref.GuestGroup.Client.FullName AS ClientFullName,
		|	ProformaInvoices.Ref.GuestGroup.Client.Code AS ClientCode,
		|	CAST(ProformaInvoices.Ref.GuestGroup.Client.Address AS STRING(999)) AS ClientAddress,
		|	ProformaInvoices.Ref.GuestGroup.Client.Citizenship.Code AS ClientCountryCode,
		|	ProformaInvoices.Ref.GuestGroup.Client.Citizenship.ISOCode AS ClientCountryISOCode,
		|	ProformaInvoices.Ref.GuestGroup.Client.Citizenship.ISOCode3 AS ClientCountryISOCode3,
		|	ProformaInvoices.Ref.GuestGroup.Client.Phone AS ClientPhone,
		|	ProformaInvoices.Ref.GuestGroup.Client.EMail AS ClientEMail,
		|	ProformaInvoices.Ref.GuestGroup.Client.TIN AS ClientTIN,
		|	ProformaInvoices.Ref.GuestGroup.Client.DateOfBirth AS ClientDateOfBirth,
		|	ProformaInvoices.Ref.GuestGroup.CheckInDate AS CheckInDate,
		|	ProformaInvoices.Ref.GuestGroup.CheckOutDate AS CheckOutDate
		|FROM
		|	ProformaInvoices AS ProformaInvoices
		|
		|ORDER BY
		|	CustomerDescription,
		|	RecorderNumber";
		vCPIQry.SetParameter("qInvoice", vInvoice);
		vCPIQry.SetParameter("qAccountingDate", pAccountingDate);
		vClearedProformaInvoices = vCPIQry.Execute().Unload();
		For Each vProfInvRow In vClearedProformaInvoices Do
			vProforma = vProfInvRow.Recorder;
			
			vAccountCode = "";
			vAccountStruct = cmGetAccountCodeForCustomer(pHotel, pCompany, vProfInvRow.Customer);
			vAccount = vAccountStruct.Account;
			If Not IsBlankString(vAccountStruct.Code) Then
				vAccountCode = TrimAll(vAccountStruct.Code);
			ElsIf ValueIsFilled(vAccountStruct.Account) And Not IsBlankString(vAccountStruct.Account.CodeBO) Then
				vAccountCode = TrimAll(vAccountStruct.Account.CodeBO);
			EndIf;
			If IsBlankString(vAccountCode) And Not IsBlankString(vDefaultCustomerAccountCode) Then
				vAccountCode = vDefaultCustomerAccountCode;
			EndIf;
			If IsBlankString(vAccountCode) Then
				Raise NStr("en='Failed to get account code for the customer: '; ru='Ошибка получения номера счета бухгалтерии для контрагента: '; de='Fehler beim Abrufen des Kontocodes für den Firma: '") + vProfInvRow.CustomerDescription + ", " + pHotel + ", " + pCompany;
			EndIf;
			
			vIncomeProformaInvoiceXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomeProformaInvoice"));
			
			vIncomeProformaInvoiceXDTO.AccountingDate = vProfInvRow.AccountingDate;
			vIncomeProformaInvoiceXDTO.InvoiceNumber = vProfInvRow.RecorderNumber;
			vIncomeProformaInvoiceXDTO.ReservationNumber = Format(vProfInvRow.GuestGroupCode, "NFD=0; NG=") + ?(IsBlankString(vProfInvRow.GuestGroupDescription), "", " / " + vProfInvRow.GuestGroupDescription);
			vIncomeProformaInvoiceXDTO.ReservationRefCode = TrimAll(vProfInvRow.GuestGroupRefCode);
			vIncomeProformaInvoiceXDTO.NumberOfAdults = vProfInvRow.NumberOfAdults;
			vIncomeProformaInvoiceXDTO.NumberOfTeenagers = vProfInvRow.NumberOfTeenagers;
			vIncomeProformaInvoiceXDTO.NumberOfChildren = vProfInvRow.NumberOfChildren;
			vIncomeProformaInvoiceXDTO.NumberOfInfants = vProfInvRow.NumberOfInfants;
			vIncomeProformaInvoiceXDTO.GuestDescription = TrimAll(vProfInvRow.ClientFullName) + ", " + Format(vProfInvRow.CheckInDate, "DF=dd.MM.yyyy") + " - " + Format(vProfInvRow.CheckOutDate, "DF=dd.MM.yyyy");
			vIncomeProformaInvoiceXDTO.Amount = vProfInvRow.Sum;
			vIncomeProformaInvoiceXDTO.AccountCode = vAccountCode;
			vIncomeProformaInvoiceXDTO.CommissionAmount = vProforma.Services.Total("CommissionSum");
			
			// Extras
			vCustomerXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CustomersItemRow"));
			If ValueIsFilled(vProfInvRow.Customer) And vProfInvRow.Customer <> pHotel.IndividualsCustomer Then
				vCustomerXDTO.IsIndividual = vProfInvRow.CustomerIsIndividual;
				vCustomerXDTO.Code = TrimAll(vProfInvRow.CustomerCode);
				vCustomerXDTO.Description = ?(IsBlankString(TrimAll(vProfInvRow.CustomerLegacyName)), TrimAll(vProfInvRow.CustomerDescription), TrimAll(vProfInvRow.CustomerLegacyName));
				vCustomerXDTO.ExternalCode = cmGetObjectExternalSystemCodeByRef(pHotel, pExternalSystemCode, "Customers", vProfInvRow.Customer, True);
				vCustomerXDTO.TIN = TrimAll(vProfInvRow.CustomerTIN);
				vCustomerXDTO.VATCode = TrimAll(vProfInvRow.CustomerVATCode);
				vCustomerXDTO.EMail = TrimAll(vProfInvRow.CustomerEMail);
				vCustomerXDTO.Phone = TrimAll(vProfInvRow.CustomerPhone);
				vCustomerXDTO.Address = TrimAll(vProfInvRow.CustomerAddress);
				vCustomerXDTO.CountryCode = ?(vProfInvRow.CustomerCountryCode = Null, 0, vProfInvRow.CustomerCountryCode);
				vCustomerXDTO.CountryISOCode2 = TrimAll(vProfInvRow.CustomerCountryISOCode);
				vCustomerXDTO.CountryISOCode3 = TrimAll(vProfInvRow.CustomerCountryISOCode3);
				vCustomerXDTO.DateOfBirth = ?(ValueIsFilled(vProfInvRow.CustomerDateOfBirth), vProfInvRow.CustomerDateOfBirth, '00010101');
			Else
				vCustomerXDTO.IsIndividual = True;
				vCustomerXDTO.Code = TrimAll(vProfInvRow.ClientCode);
				vCustomerXDTO.Description = TrimAll(vProfInvRow.ClientFullName);
				vCustomerXDTO.ExternalCode = cmGetObjectExternalSystemCodeByRef(pHotel, pExternalSystemCode, "Clients", vProfInvRow.Client, True);
				vCustomerXDTO.TIN = TrimAll(vProfInvRow.ClientTIN);
				vCustomerXDTO.VATCode = "";
				vCustomerXDTO.EMail = TrimAll(vProfInvRow.ClientEMail);
				vCustomerXDTO.Phone = TrimAll(vProfInvRow.ClientPhone);
				vCustomerXDTO.Address = TrimAll(vProfInvRow.ClientAddress);
				vCustomerXDTO.CountryCode = ?(vProfInvRow.ClientCountryCode = Null, 0, vProfInvRow.ClientCountryCode);
				vCustomerXDTO.CountryISOCode2 = TrimAll(vProfInvRow.ClientCountryISOCode);
				vCustomerXDTO.CountryISOCode3 = TrimAll(vProfInvRow.ClientCountryISOCode3);
				vCustomerXDTO.DateOfBirth = ?(ValueIsFilled(vProfInvRow.ClientDateOfBirth), vProfInvRow.ClientDateOfBirth, '00010101');
			EndIf;
			vIncomeProformaInvoiceXDTO.Customer = vCustomerXDTO;
			
			// Contract
			If ValueIsFilled(vProfInvRow.Contract) And vProfInvRow.Contract <> pHotel.IndividualsContract Then
				vContractXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "Contract"));
				vContractXDTO.Code = TrimAll(vProfInvRow.ContractCode);
				vContractXDTO.Description = TrimAll(vProfInvRow.ContractDescription);
				vContractXDTO.Date = vProfInvRow.ContractDate;
				vIncomeProformaInvoiceXDTO.Contract = vContractXDTO;
			EndIf;
			
			// Analysis items
			If pUsePostingsFOData Then
				FillAnalysisItem(vAccount, vIncomeProformaInvoiceXDTO);
			EndIf;
			
			// VAT
			vVATXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomeVAT"));
			vVATs = vProforma.Services.Unload(, "VATRate, VATSum");
			vVATs.GroupBy("VATRate", "VATSum");
			For Each vVATsRow In vVATs Do
				vVATRowXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomeVATRate"));
				
				vVATRowXDTO.AccountingDate = vProfInvRow.AccountingDate;
				vVATRowXDTO.VATRateName = TrimAll(vVATsRow.VATRate);
				vVATRowXDTO.VATTaxRate = ?(ValueIsFilled(vVATsRow.VATRate), ?(vVATsRow.VATRate.NoVAT, -1, CachedAccounts.GetVATTaxRate(vVATsRow.VATRate, vProfInvRow.AccountingDate)), 0);
				vVATRowXDTO.Amount = vVATsRow.VATSum;
				
				vAccountCode = "";
				vAccountStruct = cmGetAccountCodeForVATRate(pHotel, pCompany, vVATsRow.VATRate);
				vVATAccount = vAccountStruct.Account;
				If Not IsBlankString(vAccountStruct.Code) Then
					vAccountCode = TrimAll(vAccountStruct.Code);
				ElsIf ValueIsFilled(vAccountStruct.Account) And Not IsBlankString(vAccountStruct.Account.CodeBO) Then
					vAccountCode = TrimAll(vAccountStruct.Account.CodeBO);
				EndIf;
				vVATRowXDTO.AccountCode = vAccountCode;
				
				// Analysis items
				If pUsePostingsFOData Then
					FillAnalysisItem(vVATAccount, vVATRowXDTO);
				EndIf;
				
				vVATXDTO.IncomeVATRate.Add(vVATRowXDTO);
			EndDo;
			vIncomeProformaInvoiceXDTO.VATRates = vVATXDTO;
			
			// Services
			vServicesXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomeServices"));
			For Each vSrvRow In vProforma.Services Do
				vAccountCode = "";
				vAccountStruct = cmGetAccountCodeForService(pHotel, pCompany, vSrvRow.Service, vSrvRow.VATRate, vProfInvRow.AccountingDate);
				vSrvAccount = vAccountStruct.Account;
				If Not IsBlankString(vAccountStruct.Code) Then
					vAccountCode = TrimAll(vAccountStruct.Code);
				ElsIf ValueIsFilled(vAccountStruct.Account) And Not IsBlankString(vAccountStruct.Account.CodeBO) Then
					vAccountCode = TrimAll(vAccountStruct.Account.CodeBO);
				EndIf;
				If IsBlankString(vAccountCode) Then
					Raise NStr("en='Failed to get account code for the service / VAT rate: '; ru='Ошибка получения номера счета бухгалтерии для услуги / ставки НДС: '; de='Fehler beim Abrufen des Kontocodes für den Service / Mehrwertsteuersatz: '") + TrimAll(vSrvRow.Service) + " / " + TrimAll(vSrvRow.VATRate) + ", " + pHotel + ", " + pCompany;
				EndIf;
				
				vDepartmentCode = "";
				If ValueIsFilled(vSrvRow.Service) And ValueIsFilled(vSrvRow.Service.DepartmentCode) Then
					vDepartmentCodeRef = vSrvRow.Service.DepartmentCode;
					If Not IsBlankString(vDepartmentCodeRef.CodeBO) Then
						vDepartmentCode = TrimAll(vDepartmentCodeRef.CodeBO);
					Else
						vDepartmentCode = TrimAll(vDepartmentCodeRef.Code);
					EndIf;
				EndIf;
				
				vIncomeServiceXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomeService"));
				
				vIncomeServiceXDTO.AccountingDate = vProfInvRow.AccountingDate;
				vIncomeServiceXDTO.ServiceName = TrimAll(vSrvRow.Service.Description);
				vIncomeServiceXDTO.VATRateName = TrimAll(vSrvRow.VATRate);
				vIncomeServiceXDTO.VATTaxRate = ?(ValueIsFilled(vSrvRow.VATRate), ?(vSrvRow.VATRate.NoVAT, -1, CachedAccounts.GetVATTaxRate(vSrvRow.VATRate, vProfInvRow.AccountingDate)), 0);
				vIncomeServiceXDTO.Amount = vSrvRow.Sum;
				vIncomeServiceXDTO.VATAmount = vSrvRow.VATSum;
				vIncomeServiceXDTO.AccountCode = vAccountCode;
				vIncomeServiceXDTO.DepartmentCode = vDepartmentCode;
				
				// Analysis items
				If pUsePostingsFOData Then
					FillAnalysisItem(vSrvAccount, vIncomeServiceXDTO);
				EndIf;
				
				vServicesXDTO.IncomeService.Add(vIncomeServiceXDTO);
			EndDo;
			vIncomeProformaInvoiceXDTO.Services = vServicesXDTO;
			
			vClearedProformaInvoicesXDTO.IncomeProformaInvoice.Add(vIncomeProformaInvoiceXDTO);
		EndDo;
		vIncomeInvoiceXDTO.ClearedProformaInvoices = vClearedProformaInvoicesXDTO;
		
		// Add invoice data structure
		vIncomeInvoicesXDTO.IncomeInvoice.Add(vIncomeInvoiceXDTO);
	EndDo;
	
	Return vIncomeInvoicesXDTO;
EndFunction // GetIncomeInvoices

// -----------------------------------------------------------------------------
Function GetIncomeProformaInvoices(pHotel, pCompany, pAccountingDate, pExternalSystemCode, pUsePostingsFOData = False)
	vIncomeProformaInvoicesXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomeProformaInvoices"));
	
	// Run query to get data
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ProformaInvoices.Ref AS Ref,
	|	ProformaInvoices.AccountingDate AS AccountingDate
	|INTO ProformaInvoices
	|FROM
	|	(SELECT
	|		ProformaInvoicePayments.Ref AS Ref,
	|		Payments.AccountingDate AS AccountingDate
	|	FROM
	|		Document.ProformaInvoice AS ProformaInvoicePayments
	|			INNER JOIN Document.Payment AS Payments
	|			ON (Payments.Invoice = ProformaInvoicePayments.Ref)
	|				AND (Payments.AccountingDate = &qAccountingDate)
	|	WHERE
	|		ProformaInvoicePayments.Hotel = &qHotel
	|		AND (&qCompanyIsEmpty
	|				OR NOT &qCompanyIsEmpty
	|					AND ProformaInvoicePayments.Company = &qCompany)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ProformaInvoiceReturns.Ref,
	|		Returns.AccountingDate
	|	FROM
	|		Document.ProformaInvoice AS ProformaInvoiceReturns
	|			INNER JOIN Document.Return AS Returns
	|			ON (Returns.Invoice = ProformaInvoiceReturns.Ref)
	|				AND (Returns.AccountingDate = &qAccountingDate)
	|	WHERE
	|		ProformaInvoiceReturns.Hotel = &qHotel
	|		AND (&qCompanyIsEmpty
	|				OR NOT &qCompanyIsEmpty
	|					AND ProformaInvoiceReturns.Company = &qCompany)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ProformaInvoiceCustomerPayments.Ref,
	|		CustomerPayments.AccountingDate
	|	FROM
	|		Document.ProformaInvoice AS ProformaInvoiceCustomerPayments
	|			INNER JOIN Document.CustomerPayment AS CustomerPayments
	|			ON (CustomerPayments.Invoice = ProformaInvoiceCustomerPayments.Ref)
	|				AND (CustomerPayments.AccountingDate = &qAccountingDate)
	|	WHERE
	|		ProformaInvoiceCustomerPayments.Hotel = &qHotel
	|		AND (&qCompanyIsEmpty
	|				OR NOT &qCompanyIsEmpty
	|					AND ProformaInvoiceCustomerPayments.Company = &qCompany)) AS ProformaInvoices
	|
	|GROUP BY
	|	ProformaInvoices.Ref,
	|	ProformaInvoices.AccountingDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProformaInvoices.AccountingDate AS AccountingDate,
	|	ProformaInvoices.Ref.AccountingCustomer AS Customer,
	|	ProformaInvoices.Ref.AccountingCustomer.Code AS CustomerCode,
	|	ProformaInvoices.Ref.AccountingCustomer.Description AS CustomerDescription,
	|	ProformaInvoices.Ref.AccountingCustomer.LegacyName AS CustomerLegacyName,
	|	CAST(ProformaInvoices.Ref.AccountingCustomer.LegacyAddress AS STRING(999)) AS CustomerAddress,
	|	ProformaInvoices.Ref.AccountingCustomer.Country.Code AS CustomerCountryCode,
	|	ProformaInvoices.Ref.AccountingCustomer.Country.ISOCode AS CustomerCountryISOCode,
	|	ProformaInvoices.Ref.AccountingCustomer.Country.ISOCode3 AS CustomerCountryISOCode3,
	|	ProformaInvoices.Ref.AccountingCustomer.Phone AS CustomerPhone,
	|	ProformaInvoices.Ref.AccountingCustomer.EMail AS CustomerEMail,
	|	ProformaInvoices.Ref.AccountingCustomer.TIN AS CustomerTIN,
	|	ProformaInvoices.Ref.AccountingCustomer.VATC AS CustomerVATCode,
	|	ProformaInvoices.Ref.AccountingCustomer.DateOfBirth AS CustomerDateOfBirth,
	|	ProformaInvoices.Ref.AccountingCustomer.IsIndividual AS CustomerIsIndividual,
	|	ProformaInvoices.Ref.AccountingContract AS Contract,
	|	ProformaInvoices.Ref.AccountingContract.Code AS ContractCode,
	|	ProformaInvoices.Ref.AccountingContract.Description AS ContractDescription,
	|	ProformaInvoices.Ref.AccountingContract.Date AS ContractDate,
	|	ProformaInvoices.Ref.AccountingCurrency AS Currency,
	|	ProformaInvoices.Ref.Sum AS Sum,
	|	ProformaInvoices.Ref AS Recorder,
	|	ProformaInvoices.Ref.Number AS RecorderNumber,
	|	ProformaInvoices.Ref.GuestGroup AS GuestGroup,
	|	ProformaInvoices.Ref.GuestGroup.Code AS GuestGroupCode,
	|	ProformaInvoices.Ref.GuestGroup.Description AS GuestGroupDescription,
	|	ProformaInvoices.Ref.GuestGroup.ID AS GuestGroupRefCode,
	|	ISNULL(ProformaInvoices.Ref.GuestGroup.ClientDoc.NumberOfAdults, 0) AS NumberOfAdults,
	|	ISNULL(ProformaInvoices.Ref.GuestGroup.ClientDoc.NumberOfTeenagers, 0) AS NumberOfTeenagers,
	|	ISNULL(ProformaInvoices.Ref.GuestGroup.ClientDoc.NumberOfChildren, 0) AS NumberOfChildren,
	|	ISNULL(ProformaInvoices.Ref.GuestGroup.ClientDoc.NumberOfInfants, 0) AS NumberOfInfants,
	|	ProformaInvoices.Ref.GuestGroup.Client AS Client,
	|	ProformaInvoices.Ref.GuestGroup.Client.FullName AS ClientFullName,
	|	ProformaInvoices.Ref.GuestGroup.Client.Code AS ClientCode,
	|	CAST(ProformaInvoices.Ref.GuestGroup.Client.Address AS STRING(999)) AS ClientAddress,
	|	ProformaInvoices.Ref.GuestGroup.Client.Citizenship.Code AS ClientCountryCode,
	|	ProformaInvoices.Ref.GuestGroup.Client.Citizenship.ISOCode AS ClientCountryISOCode,
	|	ProformaInvoices.Ref.GuestGroup.Client.Citizenship.ISOCode3 AS ClientCountryISOCode3,
	|	ProformaInvoices.Ref.GuestGroup.Client.Phone AS ClientPhone,
	|	ProformaInvoices.Ref.GuestGroup.Client.EMail AS ClientEMail,
	|	ProformaInvoices.Ref.GuestGroup.Client.TIN AS ClientTIN,
	|	ProformaInvoices.Ref.GuestGroup.Client.DateOfBirth AS ClientDateOfBirth,
	|	ProformaInvoices.Ref.GuestGroup.CheckInDate AS CheckInDate,
	|	ProformaInvoices.Ref.GuestGroup.CheckOutDate AS CheckOutDate
	|FROM
	|	ProformaInvoices AS ProformaInvoices
	|
	|ORDER BY
	|	CustomerDescription,
	|	RecorderNumber";
	vQry.SetParameter("qAccountingDate", pAccountingDate);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qCompany", pCompany);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(pCompany));
	
	vProformas = vQry.Execute().Unload();
	
	vDefaultCustomerAccountCode = "";
	vCompany = pCompany;
	If Not ValueIsFilled(vCompany) And ValueIsFilled(pHotel) And ValueIsFilled(pHotel.Company) Then
		vCompany = pHotel.Company;
	EndIf;
	If ValueIsFilled(vCompany) And Not IsBlankString(vCompany.InvoicesAccountCode) Then
		vDefaultCustomerAccountCode = TrimAll(vCompany.InvoicesAccountCode);
	EndIf;
	
	For Each vRow In vProformas Do
		vProforma = vRow.Recorder;
		
		vAccountCode = "";
		vAccountStruct = cmGetAccountCodeForCustomer(pHotel, pCompany, vRow.Customer);
		vAccount = vAccountStruct.Account;
		If Not IsBlankString(vAccountStruct.Code) Then
			vAccountCode = TrimAll(vAccountStruct.Code);
		ElsIf ValueIsFilled(vAccountStruct.Account) And Not IsBlankString(vAccountStruct.Account.CodeBO) Then
			vAccountCode = TrimAll(vAccountStruct.Account.CodeBO);
		EndIf;
		If IsBlankString(vAccountCode) And Not IsBlankString(vDefaultCustomerAccountCode) Then
			vAccountCode = vDefaultCustomerAccountCode;
		EndIf;
		If IsBlankString(vAccountCode) Then
			Raise NStr("en='Failed to get account code for the customer: '; ru='Ошибка получения номера счета бухгалтерии для контрагента: '; de='Fehler beim Abrufen des Kontocodes für den Firma: '") + vRow.CustomerDescription + ", " + pHotel + ", " + pCompany;
		EndIf;
		
		vIncomeProformaInvoiceXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomeProformaInvoice"));
		
		vIncomeProformaInvoiceXDTO.AccountingDate = vRow.AccountingDate;
		vIncomeProformaInvoiceXDTO.InvoiceNumber = vRow.RecorderNumber;
		vIncomeProformaInvoiceXDTO.ReservationNumber = Format(vRow.GuestGroupCode, "NFD=0; NG=") + ?(IsBlankString(vRow.GuestGroupDescription), "", " / " + vRow.GuestGroupDescription);
		vIncomeProformaInvoiceXDTO.ReservationRefCode = TrimAll(vRow.GuestGroupRefCode);
		vIncomeProformaInvoiceXDTO.NumberOfAdults = vRow.NumberOfAdults;
		vIncomeProformaInvoiceXDTO.NumberOfTeenagers = vRow.NumberOfTeenagers;
		vIncomeProformaInvoiceXDTO.NumberOfChildren = vRow.NumberOfChildren;
		vIncomeProformaInvoiceXDTO.NumberOfInfants = vRow.NumberOfInfants;
		vIncomeProformaInvoiceXDTO.GuestDescription = TrimAll(vRow.ClientFullName) + ", " + Format(vRow.CheckInDate, "DF=dd.MM.yyyy") + " - " + Format(vRow.CheckOutDate, "DF=dd.MM.yyyy");
		vIncomeProformaInvoiceXDTO.Amount = vRow.Sum;
		vIncomeProformaInvoiceXDTO.AccountCode = vAccountCode;
		vIncomeProformaInvoiceXDTO.CommissionAmount = vProforma.Services.Total("CommissionSum");
		
		// Customer
		vCustomerXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "CustomersItemRow"));
		If ValueIsFilled(vRow.Customer) And vRow.Customer <> pHotel.IndividualsCustomer Then
			vCustomerXDTO.IsIndividual = vRow.CustomerIsIndividual;
			vCustomerXDTO.Code = TrimAll(vRow.CustomerCode);
			vCustomerXDTO.Description = ?(IsBlankString(TrimAll(vRow.CustomerLegacyName)), TrimAll(vRow.CustomerDescription), TrimAll(vRow.CustomerLegacyName));
			vCustomerXDTO.ExternalCode = cmGetObjectExternalSystemCodeByRef(pHotel, pExternalSystemCode, "Customers", vRow.Customer, True);
			vCustomerXDTO.TIN = TrimAll(vRow.CustomerTIN);
			vCustomerXDTO.VATCode = TrimAll(vRow.CustomerVATCode);
			vCustomerXDTO.EMail = TrimAll(vRow.CustomerEMail);
			vCustomerXDTO.Phone = TrimAll(vRow.CustomerPhone);
			vCustomerXDTO.Address = TrimAll(vRow.CustomerAddress);
			vCustomerXDTO.CountryCode = ?(vRow.CustomerCountryCode = Null, 0, vRow.CustomerCountryCode);
			vCustomerXDTO.CountryISOCode2 = TrimAll(vRow.CustomerCountryISOCode);
			vCustomerXDTO.CountryISOCode3 = TrimAll(vRow.CustomerCountryISOCode3);
			vCustomerXDTO.DateOfBirth = ?(ValueIsFilled(vRow.CustomerDateOfBirth), vRow.CustomerDateOfBirth, '00010101');
		Else
			vCustomerXDTO.IsIndividual = True;
			vCustomerXDTO.Code = TrimAll(vRow.ClientCode);
			vCustomerXDTO.Description = TrimAll(vRow.ClientFullName);
			vCustomerXDTO.ExternalCode = cmGetObjectExternalSystemCodeByRef(pHotel, pExternalSystemCode, "Clients", vRow.Client, True);
			vCustomerXDTO.TIN = TrimAll(vRow.ClientTIN);
			vCustomerXDTO.VATCode = "";
			vCustomerXDTO.EMail = TrimAll(vRow.ClientEMail);
			vCustomerXDTO.Phone = TrimAll(vRow.ClientPhone);
			vCustomerXDTO.Address = TrimAll(vRow.ClientAddress);
			vCustomerXDTO.CountryCode = ?(vRow.ClientCountryCode = Null, 0, vRow.ClientCountryCode);
			vCustomerXDTO.CountryISOCode2 = TrimAll(vRow.ClientCountryISOCode);
			vCustomerXDTO.CountryISOCode3 = TrimAll(vRow.ClientCountryISOCode3);
			vCustomerXDTO.DateOfBirth = ?(ValueIsFilled(vRow.ClientDateOfBirth), vRow.ClientDateOfBirth, '00010101');
		EndIf;
		vIncomeProformaInvoiceXDTO.Customer = vCustomerXDTO;
		
		// Contract
		If ValueIsFilled(vRow.Contract) And vRow.Contract <> pHotel.IndividualsContract Then
			vContractXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "Contract"));
			vContractXDTO.Code = TrimAll(vRow.ContractCode);
			vContractXDTO.Description = TrimAll(vRow.ContractDescription);
			vContractXDTO.Date = vRow.ContractDate;
			vIncomeProformaInvoiceXDTO.Contract = vContractXDTO;
		EndIf;
		
		// Analysis items
		If pUsePostingsFOData Then
			FillAnalysisItem(vAccount, vIncomeProformaInvoiceXDTO);
		EndIf;
		
		// VAT
		vVATXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomeVAT"));
		vVATs = vProforma.Services.Unload(, "VATRate, VATSum");
		vVATs.GroupBy("VATRate", "VATSum");
		For Each vVATsRow In vVATs Do
			vVATRowXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomeVATRate"));
			
			vVATRowXDTO.AccountingDate = vRow.AccountingDate;
			vVATRowXDTO.VATRateName = TrimAll(vVATsRow.VATRate);
			vVATRowXDTO.VATTaxRate = ?(ValueIsFilled(vVATsRow.VATRate), ?(vVATsRow.VATRate.NoVAT, -1, CachedAccounts.GetVATTaxRate(vVATsRow.VATRate, pAccountingDate)), 0);
			vVATRowXDTO.Amount = vVATsRow.VATSum;
			
			vAccountCode = "";
			vAccountStruct = cmGetAccountCodeForVATRate(pHotel, pCompany, vVATsRow.VATRate);
			vVATAccount = vAccountStruct.Account;
			If Not IsBlankString(vAccountStruct.Code) Then
				vAccountCode = TrimAll(vAccountStruct.Code);
			ElsIf ValueIsFilled(vAccountStruct.Account) And Not IsBlankString(vAccountStruct.Account.CodeBO) Then
				vAccountCode = TrimAll(vAccountStruct.Account.CodeBO);
			EndIf;
			vVATRowXDTO.AccountCode = vAccountCode;
			
			// Analysis items
			If pUsePostingsFOData Then
				FillAnalysisItem(vVATAccount, vVATRowXDTO);
			EndIf;
			
			vVATXDTO.IncomeVATRate.Add(vVATRowXDTO);
		EndDo;
		vIncomeProformaInvoiceXDTO.VATRates = vVATXDTO;
		
		// Services
		vServicesXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomeServices"));
		For Each vSrvRow In vProforma.Services Do
			vAccountCode = "";
			vAccountStruct = cmGetAccountCodeForService(pHotel, pCompany, vSrvRow.Service, vSrvRow.VATRate, pAccountingDate);
			vSrvAccount = vAccountStruct.Account;
			If Not IsBlankString(vAccountStruct.Code) Then
				vAccountCode = TrimAll(vAccountStruct.Code);
			ElsIf ValueIsFilled(vAccountStruct.Account) And Not IsBlankString(vAccountStruct.Account.CodeBO) Then
				vAccountCode = TrimAll(vAccountStruct.Account.CodeBO);
			EndIf;
			If IsBlankString(vAccountCode) Then
				Raise NStr("en='Failed to get account code for the service / VAT rate: '; ru='Ошибка получения номера счета бухгалтерии для услуги / ставки НДС: '; de='Fehler beim Abrufen des Kontocodes für den Service / Mehrwertsteuersatz: '") + TrimAll(vSrvRow.Service) + " / " + TrimAll(vSrvRow.VATRate) + ", " + pHotel + ", " + pCompany;
			EndIf;
			
			vDepartmentCode = "";
			If ValueIsFilled(vSrvRow.Service) And ValueIsFilled(vSrvRow.Service.DepartmentCode) Then
				vDepartmentCodeRef = vSrvRow.Service.DepartmentCode;
				If Not IsBlankString(vDepartmentCodeRef.CodeBO) Then
					vDepartmentCode = TrimAll(vDepartmentCodeRef.CodeBO);
				Else
					vDepartmentCode = TrimAll(vDepartmentCodeRef.Code);
				EndIf;
			EndIf;
			
			vIncomeServiceXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/accounting/", "IncomeService"));
			
			vIncomeServiceXDTO.AccountingDate = pAccountingDate;
			vIncomeServiceXDTO.ServiceName = TrimAll(vSrvRow.Service.Description);
			vIncomeServiceXDTO.VATRateName = TrimAll(vSrvRow.VATRate);
			vIncomeServiceXDTO.VATTaxRate = ?(ValueIsFilled(vSrvRow.VATRate), ?(vSrvRow.VATRate.NoVAT, -1, CachedAccounts.GetVATTaxRate(vSrvRow.VATRate, pAccountingDate)), 0);
			vIncomeServiceXDTO.Amount = vSrvRow.Sum;
			vIncomeServiceXDTO.VATAmount = vSrvRow.VATSum;
			vIncomeServiceXDTO.AccountCode = vAccountCode;
			vIncomeServiceXDTO.DepartmentCode = vDepartmentCode;
			
			// Analysis items
			If pUsePostingsFOData Then
				FillAnalysisItem(vSrvAccount, vIncomeServiceXDTO);
			EndIf;
			
			vServicesXDTO.IncomeService.Add(vIncomeServiceXDTO);
		EndDo;
		vIncomeProformaInvoiceXDTO.Services = vServicesXDTO;
		
		vIncomeProformaInvoicesXDTO.IncomeProformaInvoice.Add(vIncomeProformaInvoiceXDTO);
	EndDo;
	
	Return vIncomeProformaInvoicesXDTO;
EndFunction // GetIncomeProformaInvoices

#EndRegion

