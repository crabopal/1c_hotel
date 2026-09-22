
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure Posting(pCancel, pMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// Add data locks
	vDataLock = New DataLock();
	vCRItem = vDataLock.Add("Catalog.CashRegisters");
	vCRItem.Mode = DataLockMode.Exclusive;
	vCRItem.SetValue("Ref", CashRegister);
	vDataLock.Lock();
	
	// 1. Fill the cash register day start date
	vDateFrom = pmCalculateDateFrom();
	If ValueIsFilled(vDateFrom) Then
		If DateFrom <> vDateFrom Then
			DateFrom = vDateFrom;
			Write(DocumentWriteMode.Write);
		EndIf;
	EndIf;
	
	// 2. Null the cash totals
	If Not CashRegister.DoNotNullCashTotalsByZReport Then
		// Get totals on document date
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	CashInCashRegistersBalance.Company,
		|	CashInCashRegistersBalance.CashRegister,
		|	CashInCashRegistersBalance.Currency,
		|	SUM(CashInCashRegistersBalance.SumBalance) AS Sum
		|FROM
		|	AccumulationRegister.CashInCashRegisters.Balance(
		|		&qDate,
		|		CashRegister = &qCashRegister) AS CashInCashRegistersBalance
		|GROUP BY
		|	CashInCashRegistersBalance.Company,
		|	CashInCashRegistersBalance.CashRegister,
		|	CashInCashRegistersBalance.Currency
		|ORDER BY
		|	Company.Description, CashRegister.Description, Currency.SortCode";
		vQry.SetParameter("qDate", Date);
		vQry.SetParameter("qCashRegister", CashRegister);
		vTotals = vQry.Execute().Unload();
		// Close all totals
		For Each vTotalsRow In vTotals Do
			Movement = RegisterRecords.CashInCashRegisters.AddExpense();
			
			Movement.Period = Date;
			
			FillPropertyValues(Movement, vTotalsRow);
		EndDo;
		If vTotals.Count() > 0 Then
			RegisterRecords.CashInCashRegisters.Write();
		EndIf;
	EndIf;
	
	// 3. Close cash register balances
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CashRegisterDailyReceiptsBalance.Company AS Company,
	|	CashRegisterDailyReceiptsBalance.CashRegister AS CashRegister,
	|	CashRegisterDailyReceiptsBalance.Currency AS Currency,
	|	CashRegisterDailyReceiptsBalance.PaymentSection AS PaymentSection,
	|	CashRegisterDailyReceiptsBalance.PaymentMethod AS PaymentMethod,
	|	CashRegisterDailyReceiptsBalance.Customer AS Customer,
	|	CashRegisterDailyReceiptsBalance.Contract AS Contract,
	|	CashRegisterDailyReceiptsBalance.GuestGroup AS GuestGroup,
	|	CashRegisterDailyReceiptsBalance.Payment AS Payment,
	|	CashRegisterDailyReceiptsBalance.VATRate AS VATRate,
	|	CashRegisterDailyReceiptsBalance.SumBalance AS Sum,
	|	CashRegisterDailyReceiptsBalance.VATSumBalance AS VATSum,
	|	CashRegisterDailyReceiptsBalance.PaymentSumBalance AS PaymentSum,
	|	CashRegisterDailyReceiptsBalance.VATPaymentSumBalance AS VATPaymentSum,
	|	CashRegisterDailyReceiptsBalance.ReturnSumBalance AS ReturnSum,
	|	CashRegisterDailyReceiptsBalance.VATReturnSumBalance AS VATReturnSum
	|FROM
	|	AccumulationRegister.CashRegisterDailyReceipts.Balance(
	|			&qEndOfTime,
	|			CashRegister = &qCashRegister
	|				AND Payment.Date <= &qDate) AS CashRegisterDailyReceiptsBalance";
	vQry.SetParameter("qEndOfTime", '39991231235959'); // Use end of time balances
	vQry.SetParameter("qDate", Date);
	vQry.SetParameter("qCashRegister", CashRegister);
	vBalances = vQry.Execute().Unload();
	// Close all balances
	For Each vBalancesRow In vBalances Do
		Movement = RegisterRecords.CashRegisterDailyReceipts.AddExpense();
		
		Movement.Period = Date;
		
		FillPropertyValues(Movement, vBalancesRow);
		
		// Fill attributes
		If ValueIsFilled(Movement.Payment) Then
			If TypeOf(Movement.Payment) = Type("DocumentRef.Payment") Then
				Movement.Folio = Movement.Payment.Folio;
				Movement.Payer = Movement.Payment.Payer;
			ElsIf TypeOf(Movement.Payment) = Type("DocumentRef.Return") Then
				Movement.Folio = Movement.Payment.Folio;
				Movement.Payer = Movement.Payment.Payer;
			Else
				Movement.Folio = Documents.Folio.EmptyRef();
				Movement.Payer = Undefined;
			EndIf;
		EndIf;
	EndDo;
	If vBalances.Count() > 0 Then
		RegisterRecords.CashRegisterDailyReceipts.Write();
	EndIf;
	
	// 4. Do payments distribution to services charged
	DoPaymentsDistributionToServices(pCancel, pMode);
	
	// 5. Process user exit algorithm if any
	vUserExitProc = Catalogs.ExternalDataProcessors.CloseOfCashRegisterDay;
	If ValueIsFilled(vUserExitProc) Then
		If vUserExitProc.ExternalProcessingType = Enums.ExternalProcessingTypes.Algorithm Then
			If Not IsBlankString(vUserExitProc.Algorithm) Then
				SetSafeMode(True);
				Execute(TrimAll(vUserExitProc.Algorithm));
				SetSafeMode(False);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // Posting

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pWriteMode, pPostingMode)
	Var vMessage, vAttributeInErr;
	If DataExchange.Load Then
		Return;
	EndIf;
	If pWriteMode = DocumentWriteMode.Posting Then
		pCancel	= pmCheckDocumentAttributes(vMessage, vAttributeInErr);
		If pCancel Then
			WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
			tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
			Raise NStr(vMessage);
		Else
			pmFillAccountingTotals();
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure OnSetNewNumber(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(CashRegister) And Not IsBlankString(CashRegister.CloseOfCashRegisterDayPrefix) Then
		vPrefix = TrimAll(CashRegister.CloseOfCashRegisterDayPrefix);
	ElsIf ValueIsFilled(Company) And Not IsBlankString(Company.Prefix) Then
		vPrefix = TrimAll(Company.Prefix);
	ElsIf ValueIsFilled(SessionParameters.CurrentHotel) Then
		If ValueIsFilled(SessionParameters.CurrentHotel.Company) And Not IsBlankString(SessionParameters.CurrentHotel.Company.Prefix) Then
			vPrefix = TrimAll(SessionParameters.CurrentHotel.Company.Prefix);
		EndIf;
	EndIf;
	If vPrefix <> "" Then
		pPrefix = vPrefix;
	EndIf;
EndProcedure // OnSetNewNumber

// -----------------------------------------------------------------------------
Procedure BeforeDelete(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToEditPostedCloseOfCashRegisterDayDocuments") Then
		pCancel = True;
	EndIf;
EndProcedure // BeforeDelete

// -----------------------------------------------------------------------------
Procedure UndoPosting(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToEditPostedCloseOfCashRegisterDayDocuments") Then
		pCancel = True;
	EndIf;
EndProcedure // UndoPosting

// -----------------------------------------------------------------------------
Procedure Filling(pFillingData, pFillingText, pStandardProcessing)
	If ValueIsFilled(pFillingData) Then
		pmFillAttributesWithDefaultValues();
		If TypeOf(pFillingData) = Type("CatalogRef.CashRegisters") Then
			CashRegister = pFillingData;
			// Fill default Z-Report type
			If ValueIsFilled(CashRegister.ZReportType) Then
				ZReportType = CashRegister.ZReportType;
			EndIf;
			// Fill company
			Company = CashRegister.Owner;
			// Fill accounting date
			If ValueIsFilled(CashRegister) And ValueIsFilled(CashRegister.Hotel) And ValueIsFilled(CashRegister.Hotel.AccountingDate) Then
				AccountingDate = CashRegister.Hotel.AccountingDate;
			Else
				AccountingDate = BegOfDay(Date);
			EndIf;
			// Fill cash register day from date
			vDateFrom = pmCalculateDateFrom(Date);
			If Not ValueIsFilled(vDateFrom) Then
				DateFrom = Date - 24*3600;
			Else
				DateFrom = vDateFrom;
			EndIf;
			// Fill cash register day totals
			pmFillAccountingTotals();
		EndIf;
	EndIf;
EndProcedure // Filling

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf; 
EndProcedure // OnWrite

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
Function pmCheckDocumentAttributes(pMessage, pAttributeInErr) Export
	vHasErrors = False;
	pMessage = "";
	pAttributeInErr = "";
	vMsgTextRu = "";
	vMsgTextEn = "";
	vMsgTextDe = "";
	If AdditionalProperties.Property("InfoBaseUpdateMode") And AdditionalProperties.InfoBaseUpdateMode Then
		Return vHasErrors;
	EndIf;
	If Not ValueIsFilled(Company) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Фирма> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Company> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "Das <Kompanie> -Attribut sollte gefüllt sein!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Company", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(CashRegister) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <ККМ> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "POS should be selected to close shift!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "POS sollte ausgewählt werden, um die Schicht zu schließen!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "CashRegister", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(DateFrom) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Дата начала смены> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "Begin of shift period should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "Schichtbeginn sollte gefüllt sein!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "DateFrom", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(Date) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Дата окончания смены> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "End of shift period should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "Das Ende der Schichtperiode sollte gefüllt sein!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Date", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(ZReportType) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Тип Z-Отчета> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Z-Report type> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "Das <Z-Reporttyp> Attribut sollte gefüllt sein!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "ZReportType", pAttributeInErr);
	EndIf;
	// Try to find another Z with intersecting period
	If Not vHasErrors Then
		vAnotherZ = ThereIsAnotherZWithIntersectingPeriod();
		If ValueIsFilled(vAnotherZ) Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "На указанный период в системе уже есть Z-Отчет! " + TrimAll(vAnotherZ) + Chars.LF;
			vMsgTextEn = vMsgTextEn + "Z-Report already exists for the given period! " + TrimAll(vAnotherZ) + Chars.LF;
			vMsgTextDe = vMsgTextDe + "Für den angegebenen Zeitraum verfügt das System bereits über einen Z-Report! " + TrimAll(vAnotherZ) + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "ZReportType", pAttributeInErr);
		EndIf;
	EndIf;
	If vHasErrors Then
		pMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // pmCheckDocumentAttributes

// -----------------------------------------------------------------------------
Procedure pmFillAuthorAndDate() Export
	Date = CurrentSessionDate();
	Author = SessionParameters.CurrentUser;
EndProcedure // pmFillAuthorAndDate

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill author and document date
	pmFillAuthorAndDate();
	// Fill from session parameters
	If Not ValueIsFilled(Company) Then
		If ValueIsFilled(SessionParameters.CurrentHotel) Then
			If ValueIsFilled(SessionParameters.CurrentHotel.Company) Then
				Company = SessionParameters.CurrentHotel.Company;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmCalculateDateFrom(Val pDate = Undefined) Export
	vDateFrom = Undefined;
	// Check parameters
	If Not ValueIsFilled(pDate) Then
		pDate = Date;
	EndIf;
	// Try to find previous close of cash register day
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	CloseOfCashRegisterDay.Date AS DateTo,
	|	CloseOfCashRegisterDay.Ref AS CloseOfCashRegisterDay,
	|	CloseOfCashRegisterDay.DateFrom
	|FROM
	|	Document.CloseOfCashRegisterDay AS CloseOfCashRegisterDay
	|WHERE
	|	CloseOfCashRegisterDay.CashRegister = &qCashRegister
	|	AND CloseOfCashRegisterDay.Date < &qDateTo
	|	AND CloseOfCashRegisterDay.Posted = TRUE
	|ORDER BY
	|	DateTo DESC";
	vQry.SetParameter("qCashRegister", CashRegister);
	vQry.SetParameter("qDateTo", pDate);
	vDocs = vQry.Execute().Unload();
	For Each vDocsRow In vDocs Do
		vDateFrom = vDocsRow.DateTo;
		Break;
	EndDo;
	Return vDateFrom;
EndFunction // pmCalculateDateFrom

// -----------------------------------------------------------------------------
Function pmGetCashRegisterDayCurrencyTotals() Export
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CashRegisterDailyReceiptsTurnovers.Company,
	|	CashRegisterDailyReceiptsTurnovers.CashRegister,
	|	CashRegisterDailyReceiptsTurnovers.Currency AS Currency,
	|	SUM(CashRegisterDailyReceiptsTurnovers.SumReceipt) AS Sum,
	|	SUM(CashRegisterDailyReceiptsTurnovers.VATSumReceipt) AS VATSum
	|FROM
	|	AccumulationRegister.CashRegisterDailyReceipts.Turnovers(
	|		&qDateFrom,
	|		&qDateTo,
	|		Period,
	|		CashRegister = &qCashRegister) AS CashRegisterDailyReceiptsTurnovers
	|GROUP BY
	|	CashRegisterDailyReceiptsTurnovers.Company,
	|	CashRegisterDailyReceiptsTurnovers.CashRegister,
	|	CashRegisterDailyReceiptsTurnovers.Currency
	|ORDER BY
	|	Currency.SortCode";
	vQry.SetParameter("qCashRegister", CashRegister);
	vQry.SetParameter("qDateFrom", DateFrom);
	vQry.SetParameter("qDateTo", Date);
	vTotals = vQry.Execute().Unload();
	Return vTotals;
EndFunction // pmGetCashRegisterDayCurrencyTotals

// -----------------------------------------------------------------------------
Procedure pmFillAccountingTotals() Export 
	// Get totals
	vTans = GetCashRegisterDayCurrencyAccountingTotals();

	// Check if it is filled document or not
	If AccountingTotals.Count() > 0 Then
		// Clear existing amounts but save external system codes
		vId = 0;
		While vId <= AccountingTotals.Count()-1 Do 
			ind = AccountingTotals[vId];
			// Clear rows with empty external system codes
			If IsBlankString(ind.ExternalCode) Then
				AccountingTotals.Delete(vId); 
				Continue;
			EndIf;

			// For compatibility
			If ind.Sum >= 0 And ind.IsPayment = False Then
				ind.IsPayment = True; 
			EndIf;
			
			ind.Sum = 0;
			vId = vId + 1;
		EndDo;	
		
		// Refill amounts
		For Each ind In vTans Do
			vFilter = New Structure("Currency, PaymentMethod, Customer, IsPayment", ind.Currency, ind.PaymentMethod, ind.Customer, ind.IsPayment);
			vFilterRows = AccountingTotals.FindRows(vFilter);
			If vFilterRows.Count() > 0 Then
				// Update existing row
				vFilterRows[0].Sum = ind.Sum;
			Else
				// Add new row
				vNewRow = AccountingTotals.Add();
				FillPropertyValues(vNewRow, ind);
			EndIf;
		EndDo;
	Else
		// Load totals
		AccountingTotals.Load(vTans);
	EndIf;	
EndProcedure // pmFillAccountingTotals	

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetCashRegisterDayCurrencyAccountingTotals()
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CashRegisterDailyReceiptsBalanceAndTurnovers.CashRegister AS CashRegister,
	|	CashRegisterDailyReceiptsBalanceAndTurnovers.Currency AS Currency,
	|	CashRegisterDailyReceiptsBalanceAndTurnovers.PaymentMethod AS PaymentMethod,
	|	CashRegisterDailyReceiptsBalanceAndTurnovers.Customer AS Customer,
	|	SUM(CashRegisterDailyReceiptsBalanceAndTurnovers.SumReceipt) AS Sum,
	|	SUM(CashRegisterDailyReceiptsBalanceAndTurnovers.VATSumReceipt) AS VATPaymentSum,
	|	CASE
	|		WHEN CashRegisterDailyReceiptsBalanceAndTurnovers.Payment REFS Document.Payment
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS IsPayment
	|FROM
	|	AccumulationRegister.CashRegisterDailyReceipts.BalanceAndTurnovers(&qDateFrom, &qDateTo, Period, , CashRegister = &qCashRegister) AS CashRegisterDailyReceiptsBalanceAndTurnovers
	|WHERE
	|	CashRegisterDailyReceiptsBalanceAndTurnovers.PaymentMethod.DoNotExportToTheAccountingSystem = FALSE
	|
	|GROUP BY
	|	CashRegisterDailyReceiptsBalanceAndTurnovers.Customer,
	|	CashRegisterDailyReceiptsBalanceAndTurnovers.CashRegister,
	|	CashRegisterDailyReceiptsBalanceAndTurnovers.Currency,
	|	CASE
	|		WHEN CashRegisterDailyReceiptsBalanceAndTurnovers.Payment REFS Document.Payment
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	CashRegisterDailyReceiptsBalanceAndTurnovers.PaymentMethod
	|
	|ORDER BY
	|	IsPayment,
	|	CashRegisterDailyReceiptsBalanceAndTurnovers.Currency.SortCode,
	|	CashRegisterDailyReceiptsBalanceAndTurnovers.Currency.Code,
	|	CashRegisterDailyReceiptsBalanceAndTurnovers.Customer.Code,
	|	CashRegisterDailyReceiptsBalanceAndTurnovers.PaymentMethod.SortCode,
	|	CashRegisterDailyReceiptsBalanceAndTurnovers.PaymentMethod.Description";
	vQry.SetParameter("qCashRegister", CashRegister);
	vQry.SetParameter("qDateFrom", DateFrom);
	vQry.SetParameter("qDateTo", Date);
	vTotals = vQry.Execute().Unload();
	Return vTotals;
EndFunction // GetCashRegisterDayCurrencyAccountingTotals

// -----------------------------------------------------------------------------
Procedure DoPaymentsDistributionToServices(pCancel, pPostingMode)
	If ValueIsFilled(CashRegister) And ValueIsFilled(CashRegister.Hotel) And Not CashRegister.Hotel.DoPaymentsDistributionToServices Then
		Return;
	EndIf;
	
	// Get table with returns only
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ReturnServicesBalance.Folio,
	|	ReturnServicesBalance.Payment,
	|	ReturnServicesBalance.SumBalance AS ReturnBalance,
	|	ReturnServicesBalance.PaymentSection
	|FROM
	|	AccumulationRegister.PaymentServices.Balance(
	|			&qDate,
	|			(Folio.Hotel IN HIERARCHY (&qHotel)
	|				OR &qHotelIsEmpty)
	|				AND (Folio.Company IN HIERARCHY (&qCompany)
	|					OR &qCompanyIsEmpty)
	|				AND Folio.Hotel.DoPaymentsDistributionToServices
	|				AND Payment <> UNDEFINED
	|				AND Payment.CashRegister = &qCashRegister
	|				AND Service = &qEmptyService) AS ReturnServicesBalance
	|		INNER JOIN (SELECT
	|			PaymentServicesTurnovers.Folio AS Folio,
	|			PaymentServicesTurnovers.SumTurnover AS SumTurnover
	|		FROM
	|			AccumulationRegister.PaymentServices.Turnovers(
	|					,
	|					,
	|					Period,
	|					(Folio.Hotel IN HIERARCHY (&qHotel)
	|						OR &qHotelIsEmpty)
	|						AND (Folio.Company IN HIERARCHY (&qCompany)
	|							OR &qCompanyIsEmpty)
	|						AND Folio.Hotel.DoPaymentsDistributionToServices
	|						AND Payment = UNDEFINED
	|						AND Service <> &qEmptyService) AS PaymentServicesTurnovers) AS ServicesTurnovers
	|		ON ReturnServicesBalance.Folio = ServicesTurnovers.Folio
	|WHERE
	|	ReturnServicesBalance.SumBalance > 0
	|
	|ORDER BY
	|	ReturnServicesBalance.Folio.PointInTime,
	|	ReturnServicesBalance.Payment.PointInTime DESC";
	vQry.SetParameter("qDate", New Boundary(Date + 1, BoundaryType.Excluding));
	vQry.SetParameter("qHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qHotelIsEmpty", True);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQry.SetParameter("qEmptyService", Catalogs.Services.EmptyRef());
	vQry.SetParameter("qCashRegister", CashRegister);
	vReturns = vQry.Execute().Unload();
	
	// Process returns
	vCurFolio = Undefined;
	vCharges = New ValueTable();
	For Each vReturnsRow In vReturns Do
		// Try to find charges for the current folio
		If vCurFolio <> vReturnsRow.Folio Then
			vCurFolio = vReturnsRow.Folio;
			
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	FolioCharges.Folio,
			|	FolioCharges.Service,
			|	FolioCharges.PaymentSection,
			|	FolioCharges.Payment,
			|	SUM(FolioCharges.Sum) AS Sum
			|FROM
			|	AccumulationRegister.PaymentServices AS FolioCharges
			|WHERE
			|	FolioCharges.Folio = &qFolio
			|	AND FolioCharges.Service <> &qEmptyService
			|	AND FolioCharges.Payment <> UNDEFINED
			|	AND FolioCharges.RecordType = &qExpense
			|	AND FolioCharges.Sum <> 0
			|
			|GROUP BY
			|	FolioCharges.Folio,
			|	FolioCharges.Service,
			|	FolioCharges.PaymentSection,
			|	FolioCharges.Payment
			|
			|HAVING
			|	SUM(FolioCharges.Sum) <> 0
			|
			|ORDER BY
			|	FolioCharges.PaymentSection.Code,
			|	FolioCharges.Service.IsRoomRevenue,
			|	FolioCharges.Service.SortCode DESC";
			vQry.SetParameter("qFolio", vCurFolio);
			vQry.SetParameter("qEmptyService", Catalogs.Services.EmptyRef());
			vQry.SetParameter("qExpense", AccumulationRecordType.Expense);
			vCharges = vQry.Execute().Unload();
		EndIf;
		If vCharges.Count() > 0 Then
			For Each vChargesRow In vCharges Do
				If vReturnsRow.ReturnBalance > 0 Then
					If vReturnsRow.PaymentSection = vChargesRow.PaymentSection Then
						// Sum being undistributed
						vUndistrSum = Min(vReturnsRow.ReturnBalance, vChargesRow.Sum);
						If vUndistrSum <> 0 Then
							// Add charge write off cancellation movement
							Movement = RegisterRecords.PaymentServices.Add();
							Movement.RecordType = AccumulationRecordType.Expense;
							Movement.Period = vReturnsRow.Payment.Date;
							Movement.Folio = vCurFolio;
							Movement.PaymentSection = vChargesRow.PaymentSection;
							Movement.Service = vChargesRow.Service;
							Movement.Payment = Undefined;
							Movement.Sum = -vUndistrSum;

							// Add charge undistribution movement
							Movement = RegisterRecords.PaymentServices.Add();
							Movement.RecordType = AccumulationRecordType.Expense;
							Movement.Period = vReturnsRow.Payment.Date;
							Movement.Folio = vCurFolio;
							Movement.PaymentSection = vChargesRow.PaymentSection;
							Movement.Service = vChargesRow.Service;
							Movement.Payment = vChargesRow.Payment;
							Movement.Sum = -vUndistrSum;
							
							// Add payment write off cancellation movement
							Movement = RegisterRecords.PaymentServices.Add();
							Movement.RecordType = AccumulationRecordType.Expense;
							Movement.Period = vReturnsRow.Payment.Date;
							Movement.Folio = vCurFolio;
							Movement.PaymentSection = vChargesRow.PaymentSection;
							Movement.Service = Catalogs.Services.EmptyRef();
							Movement.Payment = vChargesRow.Payment;
							Movement.Sum = vUndistrSum;
						EndIf;
						
						// Correct working table row
						vReturnsRow.ReturnBalance = vReturnsRow.ReturnBalance - vUndistrSum;
					EndIf;
				Else
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	// Write return movements
	If RegisterRecords.PaymentServices.Count() > 0 Then
		RegisterRecords.PaymentServices.Write();
	EndIf;
	
	// Get table with undistributed service balances
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ServicesBalance.Folio,
	|	ServicesBalance.Service,
	|	ServicesBalance.PaymentSection,
	|	ServicesBalance.SumBalance
	|FROM
	|	AccumulationRegister.PaymentServices.Balance(
	|			&qEndOfTime,
	|			(Folio.Hotel IN HIERARCHY (&qHotel)
	|				OR &qHotelIsEmpty)
	|				AND (Folio.Company IN HIERARCHY (&qCompany)
	|					OR &qCompanyIsEmpty)
	|				AND Folio.Hotel.DoPaymentsDistributionToServices
	|				AND Payment = UNDEFINED
	|				AND Service <> &qEmptyService) AS ServicesBalance
	|		INNER JOIN (SELECT
	|			PaymentsBalance.Folio AS Folio,
	|			PaymentsBalance.PaymentSection AS PaymentSection
	|		FROM
	|			(SELECT
	|				PaymentServicesBalance.Folio AS Folio,
	|				PaymentServicesBalance.Payment AS Payment,
	|				PaymentServicesBalance.PaymentSection AS PaymentSection,
	|				-PaymentServicesBalance.SumBalance AS PaymentBalance
	|			FROM
	|				AccumulationRegister.PaymentServices.Balance(
	|						&qDate,
	|						(Folio.Hotel IN HIERARCHY (&qHotel)
	|							OR &qHotelIsEmpty)
	|							AND (Folio.Company IN HIERARCHY (&qCompany)
	|								OR &qCompanyIsEmpty)
	|							AND Folio.Hotel.DoPaymentsDistributionToServices
	|							AND Payment <> UNDEFINED
	|							AND Payment.CashRegister = &qCashRegister
	|							AND Service = &qEmptyService) AS PaymentServicesBalance
	|			WHERE
	|				PaymentServicesBalance.SumBalance < 0) AS PaymentsBalance
	|		
	|		GROUP BY
	|			PaymentsBalance.Folio,
	|			PaymentsBalance.PaymentSection) AS FoliosWithPayments
	|		ON ServicesBalance.Folio = FoliosWithPayments.Folio
	|			AND ServicesBalance.PaymentSection = FoliosWithPayments.PaymentSection
	|
	|ORDER BY
	|	ServicesBalance.Folio.PointInTime,
	|	ServicesBalance.PaymentSection.Code,
	|	ServicesBalance.Service.IsRoomRevenue DESC,
	|	ServicesBalance.Service.SortCode";
	vQry.SetParameter("qEndOfTime", '39991231235959');
	vQry.SetParameter("qDate", New Boundary(Date + 1, BoundaryType.Excluding));
	vQry.SetParameter("qHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qHotelIsEmpty", True);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQry.SetParameter("qEmptyService", Catalogs.Services.EmptyRef());
	vQry.SetParameter("qCashRegister", CashRegister);
	vServices = vQry.Execute().Unload();
	
	// Get table with undistributed payment balances
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PaymentServicesBalance.Folio,
	|	PaymentServicesBalance.Payment,
	|	PaymentServicesBalance.PaymentSection,
	|	-PaymentServicesBalance.SumBalance AS PaymentBalance
	|FROM
	|	AccumulationRegister.PaymentServices.Balance(
	|			&qDate,
	|			(Folio.Hotel IN HIERARCHY (&qHotel)
	|				OR &qHotelIsEmpty)
	|				AND (Folio.Company IN HIERARCHY (&qCompany)
	|					OR &qCompanyIsEmpty)
	|				AND Folio.Hotel.DoPaymentsDistributionToServices
	|				AND Payment <> UNDEFINED
	|				AND Payment.CashRegister = &qCashRegister
	|				AND Service = &qEmptyService) AS PaymentServicesBalance
	|WHERE
	|	PaymentServicesBalance.SumBalance < 0
	|
	|ORDER BY
	|	PaymentServicesBalance.Folio.PointInTime,
	|	PaymentServicesBalance.PaymentSection.Code,
	|	PaymentServicesBalance.Payment.PointInTime,
	|	PaymentServicesBalance.Service.IsRoomRevenue DESC,
	|	PaymentServicesBalance.Service.SortCode";
	vQry.SetParameter("qDate", New Boundary(Date + 1, BoundaryType.Excluding));
	vQry.SetParameter("qHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qHotelIsEmpty", True);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQry.SetParameter("qEmptyService", Catalogs.Services.EmptyRef());
	vQry.SetParameter("qCashRegister", CashRegister);
	vPayments = vQry.Execute().Unload();
	
	// Process undistributed services with balances
	vCurFolio = Undefined;
	vFolioPayments = New Array;
	For Each vServicesRow In vServices Do
		// Try to find payments for the current folio
		If vCurFolio <> vServicesRow.Folio Then
			vCurFolio = vServicesRow.Folio;
			vFolioPayments = vPayments.FindRows(New Structure("Folio", vCurFolio));
		EndIf;
		If vFolioPayments.Count() > 0 Then
			For Each vPaymentsRow In vFolioPayments Do
				If vPaymentsRow.PaymentBalance > 0 And vPaymentsRow.PaymentSection = vServicesRow.PaymentSection Then
					// Sum being distributed
					vDistrSum = Min(vServicesRow.SumBalance, vPaymentsRow.PaymentBalance);
					If vDistrSum <> 0 Then
						// Add payment distribution movement
						Movement = RegisterRecords.PaymentServices.Add();
						Movement.RecordType = AccumulationRecordType.Expense;
						Movement.Period = vPaymentsRow.Payment.Date;
						Movement.Folio = vCurFolio;
						Movement.PaymentSection = vServicesRow.PaymentSection;
						Movement.Service = vServicesRow.Service;
						Movement.Payment = vPaymentsRow.Payment;
						Movement.Sum = vDistrSum;

						// Add service write off movement
						Movement = RegisterRecords.PaymentServices.Add();
						Movement.RecordType = AccumulationRecordType.Expense;
						Movement.Period = vPaymentsRow.Payment.Date;
						Movement.Folio = vCurFolio;
						Movement.PaymentSection = vServicesRow.PaymentSection;
						Movement.Service = vServicesRow.Service;
						Movement.Payment = Undefined;
						Movement.Sum = vDistrSum;
						
						// Add payment write off movement
						Movement = RegisterRecords.PaymentServices.Add();
						Movement.RecordType = AccumulationRecordType.Expense;
						Movement.Period = vPaymentsRow.Payment.Date;
						Movement.Folio = vCurFolio;
						Movement.PaymentSection = vPaymentsRow.PaymentSection;
						Movement.Service = Catalogs.Services.EmptyRef();
						Movement.Payment = vPaymentsRow.Payment;
						Movement.Sum = -vDistrSum;
					EndIf;
					
					// Change working table row
					vPaymentsRow.PaymentBalance = vPaymentsRow.PaymentBalance - vDistrSum;
					vServicesRow.SumBalance = vServicesRow.SumBalance - vDistrSum;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	// Write all movements
	RegisterRecords.PaymentServices.Write();
EndProcedure // DoPaymentsDistributionToServices

// -----------------------------------------------------------------------------
Function ThereIsAnotherZWithIntersectingPeriod()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CloseOfCashRegisterDay.Ref AS Ref
	|FROM
	|	Document.CloseOfCashRegisterDay AS CloseOfCashRegisterDay
	|WHERE
	|	CloseOfCashRegisterDay.CashRegister = &qCashRegister
	|	AND CloseOfCashRegisterDay.Company = &qCompany
	|	AND CloseOfCashRegisterDay.Posted
	|	AND CloseOfCashRegisterDay.DateFrom < &qPeriodTo
	|	AND CloseOfCashRegisterDay.Date > &qPeriodFrom
	|	AND CloseOfCashRegisterDay.Ref <> &qRef
	|
	|ORDER BY
	|	CloseOfCashRegisterDay.PointInTime";
	vQry.SetParameter("qCashRegister", CashRegister);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qPeriodFrom", DateFrom);
	vQry.SetParameter("qPeriodTo", Date);
	vQry.SetParameter("qRef", Ref);
	vShifts = vQry.Execute().Unload();
	If vShifts.Count() > 0 Then
		Return vShifts.Get(0).Ref;
	Else
		Return Undefined;
	EndIf;
EndFunction // ThereIsAnotherZWithIntersectingPeriod

#EndRegion
