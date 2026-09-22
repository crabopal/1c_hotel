

#Region Public

// -----------------------------------------------------------------------------
Function pmGetCashBalancesAndTurnovers() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CashInCashRegistersBalanceAndTurnovers.CashRegister,
	|	CashInCashRegistersBalanceAndTurnovers.Currency,
	|	SUM(CashInCashRegistersBalanceAndTurnovers.SumOpeningBalance) AS SumOpeningBalance,
	|	SUM(CashInCashRegistersBalanceAndTurnovers.SumClosingBalance) AS SumClosingBalance,
	|	SUM(CashInCashRegistersBalanceAndTurnovers.SumTurnover) AS SumTurnover,
	|	SUM(CashInCashRegistersBalanceAndTurnovers.SumReceipt) AS SumReceipt,
	|	SUM(CashInCashRegistersBalanceAndTurnovers.SumExpense) AS SumExpense
	|FROM
	|	AccumulationRegister.CashInCashRegisters.BalanceAndTurnovers(
	|		&qDateFrom,
	|		&qDateTo,
	|		Period,
	|		,
	|		CashRegister = &qCashRegister) AS CashInCashRegistersBalanceAndTurnovers
	|GROUP BY
	|	CashInCashRegistersBalanceAndTurnovers.Currency,
	|	CashInCashRegistersBalanceAndTurnovers.CashRegister
	|ORDER BY
	|	CashInCashRegistersBalanceAndTurnovers.Currency.SortCode";
	vQry.SetParameter("qCashRegister", CashRegister);
	vQry.SetParameter("qDateFrom", New Boundary(DateFrom, BoundaryType.Excluding));
	vQry.SetParameter("qDateTo", ?(ValueIsFilled(CloseOfCashRegisterDay), New Boundary(CloseOfCashRegisterDay.PointInTime(), BoundaryType.Excluding), DateTo));
	vCashTotals = vQry.Execute().Unload();
	Return vCashTotals;
EndFunction // pmGetCashBalancesAndTurnovers

// -----------------------------------------------------------------------------
Function pmGetCashRegisterDayCurrencyTotals() Export
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CashRegisterDailyOperations.CashRegister AS CashRegister,
	|	CashRegisterDailyOperations.CashRegister.SortCode AS CashRegisterSortCode,
	|	CashRegisterDailyOperations.Currency AS Currency,
	|	CashRegisterDailyOperations.Currency.SortCode AS CurrencySortCode,
	|	SUM(CashRegisterDailyOperations.SumReceipt) AS Sum,
	|	SUM(CashRegisterDailyOperations.VATSumReceipt) AS VATSum,
	|	SUM(CashRegisterDailyOperations.PaymentSumReceipt) AS PaymentSum,
	|	SUM(CashRegisterDailyOperations.VATPaymentSumReceipt) AS VATPaymentSum,
	|	SUM(CashRegisterDailyOperations.ReturnSumReceipt) AS ReturnSum,
	|	SUM(CashRegisterDailyOperations.VATReturnSumReceipt) AS VATReturnSum,
	|	SUM(CashRegisterDailyOperations.CashInSum) AS CashInSum,
	|	SUM(CashRegisterDailyOperations.CashOutSum) AS CashOutSum
	|FROM
	|	(SELECT
	|		CashRegisterDailyReceiptsTurnovers.CashRegister AS CashRegister,
	|		CashRegisterDailyReceiptsTurnovers.Currency AS Currency,
	|		CashRegisterDailyReceiptsTurnovers.SumReceipt AS SumReceipt,
	|		CashRegisterDailyReceiptsTurnovers.VATSumReceipt AS VATSumReceipt,
	|		CashRegisterDailyReceiptsTurnovers.PaymentSumReceipt AS PaymentSumReceipt,
	|		CashRegisterDailyReceiptsTurnovers.VATPaymentSumReceipt AS VATPaymentSumReceipt,
	|		CashRegisterDailyReceiptsTurnovers.ReturnSumReceipt AS ReturnSumReceipt,
	|		CashRegisterDailyReceiptsTurnovers.VATReturnSumReceipt AS VATReturnSumReceipt,
	|		0 AS CashInSum,
	|		0 AS CashOutSum
	|	FROM
	|		AccumulationRegister.CashRegisterDailyReceipts.Turnovers(&qDateFrom, &qDateTo, Period, CashRegister = &qCashRegister) AS CashRegisterDailyReceiptsTurnovers
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CashInCashRegistersIncome.CashRegister,
	|		CashInCashRegistersIncome.Currency,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		CashInCashRegistersIncome.Sum,
	|		0
	|	FROM
	|		AccumulationRegister.CashInCashRegisters AS CashInCashRegistersIncome
	|	WHERE
	|		CashInCashRegistersIncome.Period >= &qDateFrom
	|		AND CashInCashRegistersIncome.Period < &qDateTo
	|		AND CashInCashRegistersIncome.CashRegister = &qCashRegister
	|		AND CashInCashRegistersIncome.Recorder REFS Document.CashIncome
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CashInCashRegistersOutcome.CashRegister,
	|		CashInCashRegistersOutcome.Currency,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		CashInCashRegistersOutcome.Sum
	|	FROM
	|		AccumulationRegister.CashInCashRegisters AS CashInCashRegistersOutcome
	|	WHERE
	|		CashInCashRegistersOutcome.Period >= &qDateFrom
	|		AND CashInCashRegistersOutcome.Period < &qDateTo
	|		AND CashInCashRegistersOutcome.CashRegister = &qCashRegister
	|		AND CashInCashRegistersOutcome.Recorder REFS Document.CashOutcome
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CashRegisterDailyReceipts.CashRegister,
	|		CashRegisterDailyReceipts.Currency,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0
	|	FROM
	|		AccumulationRegister.CashRegisterDailyReceipts AS CashRegisterDailyReceipts
	|	WHERE
	|		CashRegisterDailyReceipts.Period > &qDateFrom
	|		AND CashRegisterDailyReceipts.Period <= &qDateTo
	|		AND CashRegisterDailyReceipts.CashRegister = &qCashRegister
	|		AND CashRegisterDailyReceipts.PaymentMethod = VALUE(Catalog.PaymentMethods.AdvanceSettlement)) AS CashRegisterDailyOperations
	|
	|GROUP BY
	|	CashRegisterDailyOperations.CashRegister,
	|	CashRegisterDailyOperations.Currency,
	|	CashRegisterDailyOperations.CashRegister.SortCode,
	|	CashRegisterDailyOperations.Currency.SortCode
	|
	|ORDER BY
	|	CashRegisterSortCode,
	|	CurrencySortCode";
	vQry.SetParameter("qCashRegister", CashRegister);
	vQry.SetParameter("qDateFrom", DateFrom);
	vQry.SetParameter("qDateTo", DateTo);
	vTotals = vQry.Execute().Unload();
	Return vTotals;
EndFunction // pmGetCashRegisterDayCurrencyTotals

// -----------------------------------------------------------------------------
Function pmGetCashRegisterDayPaymentMethodTotals() Export
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CashRegisterDailyReceiptsTurnovers.CashRegister,
	|	CashRegisterDailyReceiptsTurnovers.Currency AS Currency,
	|	CashRegisterDailyReceiptsTurnovers.PaymentMethod AS PaymentMethod,
	|	SUM(CashRegisterDailyReceiptsTurnovers.SumReceipt) AS Sum,
	|	SUM(CashRegisterDailyReceiptsTurnovers.VATSumReceipt) AS VATSum,
	|	SUM(CashRegisterDailyReceiptsTurnovers.PaymentSumReceipt) AS PaymentSum,
	|	SUM(CashRegisterDailyReceiptsTurnovers.VATPaymentSumReceipt) AS VATPaymentSum,
	|	SUM(CashRegisterDailyReceiptsTurnovers.ReturnSumReceipt) AS ReturnSum,
	|	SUM(CashRegisterDailyReceiptsTurnovers.VATReturnSumReceipt) AS VATReturnSum
	|FROM
	|	AccumulationRegister.CashRegisterDailyReceipts.Turnovers(
	|			&qDateFrom,
	|			&qDateTo,
	|			Period,
	|			CashRegister = &qCashRegister) AS CashRegisterDailyReceiptsTurnovers
	|
	|GROUP BY
	|	CashRegisterDailyReceiptsTurnovers.CashRegister,
	|	CashRegisterDailyReceiptsTurnovers.Currency,
	|	CashRegisterDailyReceiptsTurnovers.PaymentMethod
	|
	|ORDER BY
	|	CashRegisterDailyReceiptsTurnovers.Currency.SortCode,
	|	CashRegisterDailyReceiptsTurnovers.PaymentMethod.SortCode";
	vQry.SetParameter("qCashRegister", CashRegister);
	vQry.SetParameter("qDateFrom", DateFrom);
	vQry.SetParameter("qDateTo", DateTo);
	vTotals = vQry.Execute().Unload();
	Return vTotals;
EndFunction // pmGetCashRegisterDayPaymentMethodTotals

// -----------------------------------------------------------------------------
Function pmGetCashRegisterDayPaymentSectionTotals() Export
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CashRegisterDailyReceiptsTurnovers.CashRegister,
	|	CashRegisterDailyReceiptsTurnovers.Currency AS Currency,
	|	CashRegisterDailyReceiptsTurnovers.PaymentSection AS PaymentSection,
	|	SUM(CashRegisterDailyReceiptsTurnovers.SumReceipt) AS Sum,
	|	SUM(CashRegisterDailyReceiptsTurnovers.VATSumReceipt) AS VATSum,
	|	SUM(CashRegisterDailyReceiptsTurnovers.PaymentSumReceipt) AS PaymentSum,
	|	SUM(CashRegisterDailyReceiptsTurnovers.VATPaymentSumReceipt) AS VATPaymentSum,
	|	SUM(CashRegisterDailyReceiptsTurnovers.ReturnSumReceipt) AS ReturnSum,
	|	SUM(CashRegisterDailyReceiptsTurnovers.VATReturnSumReceipt) AS VATReturnSum
	|FROM
	|	AccumulationRegister.CashRegisterDailyReceipts.Turnovers(
	|			&qDateFrom,
	|			&qDateTo,
	|			Period,
	|			CashRegister = &qCashRegister) AS CashRegisterDailyReceiptsTurnovers
	|
	|GROUP BY
	|	CashRegisterDailyReceiptsTurnovers.CashRegister,
	|	CashRegisterDailyReceiptsTurnovers.Currency,
	|	CashRegisterDailyReceiptsTurnovers.PaymentSection
	|
	|ORDER BY
	|	CashRegisterDailyReceiptsTurnovers.Currency.SortCode,
	|	CashRegisterDailyReceiptsTurnovers.PaymentSection.Code";
	vQry.SetParameter("qCashRegister", CashRegister);
	vQry.SetParameter("qDateFrom", DateFrom);
	vQry.SetParameter("qDateTo", DateTo);
	vTotals = vQry.Execute().Unload();
	Return vTotals;
EndFunction // pmGetCashRegisterDayPaymentSectionTotals

// -----------------------------------------------------------------------------
Function pmGetCashRegisterDayServiceTotals() Export
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Docs.CashRegister,
	|	Docs.Currency AS Currency,
	|	Docs.PaymentMethod AS PaymentMethod,
	|	Docs.Service AS Service,
	|	Docs.Price AS Price,
	|	SUM(Docs.Quantity) AS Quantity,
	|	SUM(Docs.Sum) AS Sum,
	|	SUM(Docs.VATSum) AS VATSum,
	|	SUM(Docs.PaymentSum) AS PaymentSum,
	|	SUM(Docs.VATPaymentSum) AS VATPaymentSum,
	|	SUM(Docs.ReturnSum) AS ReturnSum,
	|	SUM(Docs.VATReturnSum) AS VATReturnSum
	|FROM
	|	(SELECT
	|		Payments.Ref.CashRegister AS CashRegister,
	|		Payments.Ref.PaymentCurrency AS Currency,
	|		Payments.Ref.PaymentMethod AS PaymentMethod,
	|		Payments.ChequeService AS Service,
	|		Payments.ChequeServicePrice AS Price,
	|		Payments.ChequeServiceQuantity AS Quantity,
	|		Payments.Sum AS Sum,
	|		Payments.VATSum AS VATSum,
	|		Payments.Sum AS PaymentSum,
	|		Payments.VATSum AS VATPaymentSum,
	|		0 AS ReturnSum,
	|		0 AS VATReturnSum
	|	FROM
	|		Document.Payment.PaymentSections AS Payments
	|	WHERE
	|		Payments.Ref.Posted
	|		AND Payments.Ref.Date >= &qDateFrom
	|		AND Payments.Ref.Date < &qDateTo
	|		AND Payments.Ref.CashRegister = &qCashRegister
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Returns.Ref.CashRegister,
	|		Returns.Ref.PaymentCurrency,
	|		Returns.Ref.PaymentMethod,
	|		Returns.ChequeService,
	|		Returns.ChequeServicePrice,
	|		-Returns.ChequeServiceQuantity,
	|		-Returns.Sum,
	|		-Returns.VATSum,
	|		0,
	|		0,
	|		Returns.Sum,
	|		Returns.VATSum
	|	FROM
	|		Document.Return.PaymentSections AS Returns
	|	WHERE
	|		Returns.Ref.Posted
	|		AND Returns.Ref.Date >= &qDateFrom
	|		AND Returns.Ref.Date < &qDateTo
	|		AND Returns.Ref.CashRegister = &qCashRegister
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CustomerPayments.CashRegister,
	|		CustomerPayments.PaymentCurrency,
	|		CustomerPayments.PaymentMethod,
	|		&qEmptyService,
	|		CustomerPayments.Sum,
	|		1,
	|		CustomerPayments.Sum,
	|		CustomerPayments.VATSum,
	|		CustomerPayments.Sum,
	|		CustomerPayments.VATSum,
	|		0,
	|		0
	|	FROM
	|		Document.CustomerPayment AS CustomerPayments
	|	WHERE
	|		CustomerPayments.Posted
	|		AND CustomerPayments.Date >= &qDateFrom
	|		AND CustomerPayments.Date < &qDateTo
	|		AND CustomerPayments.CashRegister = &qCashRegister) AS Docs
	|
	|GROUP BY
	|	Docs.CashRegister,
	|	Docs.Currency,
	|	Docs.PaymentMethod,
	|	Docs.Service,
	|	Docs.Price
	|
	|ORDER BY
	|	Docs.Currency.SortCode,
	|	Docs.Currency.Code,
	|	Docs.PaymentMethod.SortCode,
	|	Docs.PaymentMethod.Code,
	|	Docs.Service.SortCode,
	|	Docs.Service.Description";
	vQry.SetParameter("qCashRegister", CashRegister);
	vQry.SetParameter("qEmptyService", Catalogs.Services.EmptyRef());
	vQry.SetParameter("qDateFrom", DateFrom);
	vQry.SetParameter("qDateTo", DateTo);
	vTotals = vQry.Execute().Unload();
	Return vTotals;
EndFunction // pmGetCashRegisterDayServiceTotals

// -----------------------------------------------------------------------------
Function pmGetCashRegisterDayPaymentMethodAndSectionTotals() Export
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CashRegisterDailyReceiptsTurnovers.CashRegister,
	|	CashRegisterDailyReceiptsTurnovers.Currency AS Currency,
	|	CashRegisterDailyReceiptsTurnovers.PaymentMethod AS PaymentMethod,
	|	CashRegisterDailyReceiptsTurnovers.PaymentSection AS PaymentSection,
	|	SUM(CashRegisterDailyReceiptsTurnovers.SumReceipt) AS Sum,
	|	SUM(CashRegisterDailyReceiptsTurnovers.VATSumReceipt) AS VATSum,
	|	SUM(CashRegisterDailyReceiptsTurnovers.PaymentSumReceipt) AS PaymentSum,
	|	SUM(CashRegisterDailyReceiptsTurnovers.VATPaymentSumReceipt) AS VATPaymentSum,
	|	SUM(CashRegisterDailyReceiptsTurnovers.ReturnSumReceipt) AS ReturnSum,
	|	SUM(CashRegisterDailyReceiptsTurnovers.VATReturnSumReceipt) AS VATReturnSum
	|FROM
	|	AccumulationRegister.CashRegisterDailyReceipts.Turnovers(
	|			&qDateFrom,
	|			&qDateTo,
	|			Period,
	|			CashRegister = &qCashRegister) AS CashRegisterDailyReceiptsTurnovers
	|
	|GROUP BY
	|	CashRegisterDailyReceiptsTurnovers.CashRegister,
	|	CashRegisterDailyReceiptsTurnovers.Currency,
	|	CashRegisterDailyReceiptsTurnovers.PaymentMethod,
	|	CashRegisterDailyReceiptsTurnovers.PaymentSection
	|
	|ORDER BY
	|	CashRegisterDailyReceiptsTurnovers.Currency.SortCode,
	|	CashRegisterDailyReceiptsTurnovers.PaymentMethod.SortCode,
	|	CashRegisterDailyReceiptsTurnovers.PaymentSection.Code";
	vQry.SetParameter("qCashRegister", CashRegister);
	vQry.SetParameter("qDateFrom", DateFrom);
	vQry.SetParameter("qDateTo", DateTo);
	vTotals = vQry.Execute().Unload();
	Return vTotals;
EndFunction // pmGetCashRegisterDayPaymentMethodAndSectionTotals

// -----------------------------------------------------------------------------
Function pmGetCashRegisterDayAccountingTotals() Export
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CashRegisterDailyReceiptsTurnovers.CashRegister,
	|	CashRegisterDailyReceiptsTurnovers.Currency AS Currency,
	|	CashRegisterDailyReceiptsTurnovers.PaymentMethod AS PaymentMethod,
	|	CashRegisterDailyReceiptsTurnovers.PaymentSection AS PaymentSection,
	|	CashRegisterDailyReceiptsTurnovers.Customer,
	|	CashRegisterDailyReceiptsTurnovers.Contract,
	|	CashRegisterDailyReceiptsTurnovers.GuestGroup,
	|	SUM(CashRegisterDailyReceiptsTurnovers.SumReceipt) AS Sum,
	|	SUM(CashRegisterDailyReceiptsTurnovers.VATSumReceipt) AS VATSum,
	|	SUM(CashRegisterDailyReceiptsTurnovers.PaymentSumReceipt) AS PaymentSum,
	|	SUM(CashRegisterDailyReceiptsTurnovers.VATPaymentSumReceipt) AS VATPaymentSum,
	|	SUM(CashRegisterDailyReceiptsTurnovers.ReturnSumReceipt) AS ReturnSum,
	|	SUM(CashRegisterDailyReceiptsTurnovers.VATReturnSumReceipt) AS VATReturnSum
	|FROM
	|	AccumulationRegister.CashRegisterDailyReceipts.Turnovers(
	|			&qDateFrom,
	|			&qDateTo,
	|			Period,
	|			CashRegister = &qCashRegister) AS CashRegisterDailyReceiptsTurnovers
	|
	|GROUP BY
	|	CashRegisterDailyReceiptsTurnovers.CashRegister,
	|	CashRegisterDailyReceiptsTurnovers.Currency,
	|	CashRegisterDailyReceiptsTurnovers.PaymentMethod,
	|	CashRegisterDailyReceiptsTurnovers.PaymentSection,
	|	CashRegisterDailyReceiptsTurnovers.Customer,
	|	CashRegisterDailyReceiptsTurnovers.Contract,
	|	CashRegisterDailyReceiptsTurnovers.GuestGroup
	|
	|ORDER BY
	|	CashRegisterDailyReceiptsTurnovers.CashRegister.Presentation,
	|	CashRegisterDailyReceiptsTurnovers.Currency.SortCode,
	|	CashRegisterDailyReceiptsTurnovers.PaymentMethod.SortCode,
	|	CashRegisterDailyReceiptsTurnovers.PaymentSection.Code,
	|	CashRegisterDailyReceiptsTurnovers.Customer.Description,
	|	CashRegisterDailyReceiptsTurnovers.Contract.Description,
	|	CashRegisterDailyReceiptsTurnovers.GuestGroup.Code";
	vQry.SetParameter("qCashRegister", CashRegister);
	vQry.SetParameter("qDateFrom", DateFrom);
	vQry.SetParameter("qDateTo", DateTo);
	vTotals = vQry.Execute().Unload();
	Return vTotals;
EndFunction // pmGetCashRegisterDayAccountingTotals

// -----------------------------------------------------------------------------
Function pmGetCashRegisterDayAccountingContractTotals() Export
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CashRegisterDailyReceiptsTurnovers.CashRegister,
	|	CashRegisterDailyReceiptsTurnovers.Currency AS Currency,
	|	CashRegisterDailyReceiptsTurnovers.PaymentMethod AS PaymentMethod,
	|	CashRegisterDailyReceiptsTurnovers.PaymentSection AS PaymentSection,
	|	CashRegisterDailyReceiptsTurnovers.Customer,
	|	CashRegisterDailyReceiptsTurnovers.Contract,
	|	SUM(CashRegisterDailyReceiptsTurnovers.SumReceipt) AS Sum,
	|	SUM(CashRegisterDailyReceiptsTurnovers.VATSumReceipt) AS VATSum,
	|	SUM(CashRegisterDailyReceiptsTurnovers.PaymentSumReceipt) AS PaymentSum,
	|	SUM(CashRegisterDailyReceiptsTurnovers.VATPaymentSumReceipt) AS VATPaymentSum,
	|	SUM(CashRegisterDailyReceiptsTurnovers.ReturnSumReceipt) AS ReturnSum,
	|	SUM(CashRegisterDailyReceiptsTurnovers.VATReturnSumReceipt) AS VATReturnSum
	|FROM
	|	AccumulationRegister.CashRegisterDailyReceipts.Turnovers(
	|			&qDateFrom,
	|			&qDateTo,
	|			Period,
	|			CashRegister = &qCashRegister) AS CashRegisterDailyReceiptsTurnovers
	|
	|GROUP BY
	|	CashRegisterDailyReceiptsTurnovers.CashRegister,
	|	CashRegisterDailyReceiptsTurnovers.Currency,
	|	CashRegisterDailyReceiptsTurnovers.PaymentMethod,
	|	CashRegisterDailyReceiptsTurnovers.PaymentSection,
	|	CashRegisterDailyReceiptsTurnovers.Customer,
	|	CashRegisterDailyReceiptsTurnovers.Contract
	|
	|ORDER BY
	|	CashRegisterDailyReceiptsTurnovers.CashRegister.Presentation,
	|	CashRegisterDailyReceiptsTurnovers.Currency.SortCode,
	|	CashRegisterDailyReceiptsTurnovers.PaymentMethod.SortCode,
	|	CashRegisterDailyReceiptsTurnovers.PaymentSection.Code,
	|	CashRegisterDailyReceiptsTurnovers.Customer.Description,
	|	CashRegisterDailyReceiptsTurnovers.Contract.Description";
	vQry.SetParameter("qCashRegister", CashRegister);
	vQry.SetParameter("qDateFrom", DateFrom);
	vQry.SetParameter("qDateTo", DateTo);
	vTotals = vQry.Execute().Unload();
	Return vTotals;
EndFunction // pmGetCashRegisterDayAccountingContractTotals

// -----------------------------------------------------------------------------
Function pmGetCashRegisterDayTransactions() Export
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CashRegisterDailyReceipts.Period,
	|	CashRegisterDailyReceipts.Recorder,
	|	CashRegisterDailyReceipts.LineNumber,
	|	CashRegisterDailyReceipts.Active,
	|	CashRegisterDailyReceipts.RecordType,
	|	CashRegisterDailyReceipts.CashRegister,
	|	CashRegisterDailyReceipts.Currency,
	|	CashRegisterDailyReceipts.PaymentSection,
	|	CashRegisterDailyReceipts.PaymentMethod,
	|	CashRegisterDailyReceipts.Customer,
	|	CashRegisterDailyReceipts.Contract,
	|	CashRegisterDailyReceipts.GuestGroup,
	|	CashRegisterDailyReceipts.Payment,
	|	CashRegisterDailyReceipts.VATRate,
	|	CashRegisterDailyReceipts.Sum,
	|	CashRegisterDailyReceipts.VATSum,
	|	CashRegisterDailyReceipts.PaymentSum,
	|	CashRegisterDailyReceipts.VATPaymentSum,
	|	CashRegisterDailyReceipts.ReturnSum,
	|	CashRegisterDailyReceipts.VATReturnSum,
	|	CashRegisterDailyReceipts.Payer,
	|	CashRegisterDailyReceipts.Folio
	|FROM
	|	AccumulationRegister.CashRegisterDailyReceipts AS CashRegisterDailyReceipts
	|WHERE
	|	CashRegisterDailyReceipts.RecordType = &qReceipt
	|	AND CashRegisterDailyReceipts.CashRegister = &qCashRegister
	|	AND CashRegisterDailyReceipts.Period >= &qDateFrom
	|	AND CashRegisterDailyReceipts.Period < &qDateTo
	|
	|ORDER BY
	|	CashRegisterDailyReceipts.PointInTime";	
	vQry.SetParameter("qReceipt", AccumulationRecordType.Receipt);
	vQry.SetParameter("qCashRegister", CashRegister);
	vQry.SetParameter("qDateFrom", DateFrom);
	vQry.SetParameter("qDateTo", DateTo);
	vTrans = vQry.Execute().Unload();
	Return vTrans;
EndFunction // pmGetCashRegisterDayTransactions

// -----------------------------------------------------------------------------
Function pmGetCashInOutTransactions() Export
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CashIncome.Ref AS Document,
	|	CashIncome.Number AS Number,
	|	CashIncome.Date AS Date,
	|	CashIncome.CashRegister AS CashRegister,
	|	CashIncome.CashRegister.SortCode AS CashRegisterSortCode,
	|	CashIncome.Currency AS Currency,
	|	CashIncome.Currency.SortCode AS CurrencySortCode,
	|	CashIncome.Author,
	|	CashIncome.Remarks,
	|	CashIncome.Sum,
	|	CashIncome.Sum AS CashInSum,
	|	0 AS CashOutSum
	|FROM
	|	Document.CashIncome AS CashIncome
	|WHERE
	|	CashIncome.Posted
	|	AND CashIncome.CashRegister = &qCashRegister
	|	AND CashIncome.Date >= &qDateFrom
	|	AND CashIncome.Date < &qDateTo
	|
	|UNION ALL
	|
	|SELECT
	|	CashOutcome.Ref,
	|	CashOutcome.Number,
	|	CashOutcome.Date,
	|	CashOutcome.CashRegister,
	|	CashOutcome.CashRegister.SortCode,
	|	CashOutcome.Currency,
	|	CashOutcome.Currency.SortCode,
	|	CashOutcome.Author,
	|	CashOutcome.Remarks,
	|	-CashOutcome.Sum,
	|	0,
	|	CashOutcome.Sum
	|FROM
	|	Document.CashOutcome AS CashOutcome
	|WHERE
	|	CashOutcome.Posted
	|	AND CashOutcome.CashRegister = &qCashRegister
	|	AND CashOutcome.Date >= &qDateFrom
	|	AND CashOutcome.Date < &qDateTo
	|
	|ORDER BY
	|	CashRegisterSortCode,
	|	CurrencySortCode,
	|	Date,
	|	Number";	
	vQry.SetParameter("qCashRegister", CashRegister);
	vQry.SetParameter("qDateFrom", DateFrom);
	vQry.SetParameter("qDateTo", DateTo);
	vTrans = vQry.Execute().Unload();
	Return vTrans;
EndFunction // pmGetCashInOutTransactions

// -----------------------------------------------------------------------------
Function pmCalculateDateFrom(pDate = Undefined) Export
	vDateFrom = Undefined;
	// Check parameters
	If Not ValueIsFilled(pDate) Then
		pDate = DateTo;
	EndIf;
	If Not ValueIsFilled(pDate) Then
		pDate = CurrentSessionDate();
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
Procedure pmGenerateXReport(pSpreadsheet, pTemplate = Undefined) Export
	// Clear output spreadsheet
	pSpreadsheet.Clear();
	
	// Choose template
	If Not Company.DoNotPrintVATAmountsInShiftReports Then
		vTemplate = GetTemplate("CashRegisterReport");
	Else
		vTemplate = GetTemplate("CashRegisterReportNoVAT");
	EndIf;
	If pTemplate <> Undefined Then
		vTemplate = pTemplate;
	EndIf;
	
	// Retrieve list of currencies
	vCurrencies = pmGetCashRegisterDayCurrencyTotals();
	
	// Get cash-ins and cash-outs
	vCashInOuts = pmGetCashInOutTransactions();
	vCashInOutsTotals = vCashInOuts.Copy();
	vCashInOutsTotals.GroupBy("CashRegister, CashRegisterSortCode, Currency, CurrencySortCode", "Sum, CashInSum, CashOutSum");
	
	// Retrieve cash balances and turnovers
	vCashData = pmGetCashBalancesAndTurnovers();
	
	// Retreive payment method totals
	vPMData = pmGetCashRegisterDayPaymentMethodTotals();
	
	// Retreive payment method and payment section totals
	vPMSData = pmGetCashRegisterDayPaymentMethodAndSectionTotals();
	
	// Retreive payment sections totals
	vPSData = pmGetCashRegisterDayPaymentSectionTotals();
	
	// Retreive services totals
	vSrvData = pmGetCashRegisterDayServiceTotals();
	
	vAccData = Undefined;
	vTranData = Undefined;
	If XReportType = Enums.XReportTypes.Totals Then
		// Retreive accounting totals
		vAccData = pmGetCashRegisterDayAccountingTotals();
	ElsIf XReportType = Enums.XReportTypes.Transactions Then
		// Retrieve detailed transactions list
		vTranData = pmGetCashRegisterDayTransactions();
	ElsIf XReportType = Enums.XReportTypes.TransactionsGroupedBySections Then
		// Retrieve detailed transactions list
		vTranData = pmGetCashRegisterDayTransactions();
	EndIf;
	
	// Print separate reports for each currency
	If vCurrencies.Count() > 0 Then
		For Each vCurrenciesRow In vCurrencies Do
			vCurrency = vCurrenciesRow.Currency;
		
			// Print report header
			PrintReportHeader(vTemplate, pSpreadsheet, vCurrency, True);
			
			// Print payment method totals
			PrintPaymentMethodTotals(vTemplate, pSpreadsheet, vCurrency, vPMData, vPMSData);
			
			// Print payment section totals
			PrintPaymentSectionTotals(vTemplate, pSpreadsheet, vCurrency, vPSData);
			
			// Print cash in cash register totals
			PrintCashInCashRegisterTotals(vTemplate, pSpreadsheet, vCurrency, vCashData, vCashInOutsTotals);
			
			If XReportType = Enums.XReportTypes.Totals Then
				// Print services totals
				PrintServiceTotals(vTemplate, pSpreadsheet, vCurrency, vSrvData);

				// Print accounting totals
				PrintAccountingTotals(vTemplate, pSpreadsheet, vCurrency, vAccData, vPMSData);
			ElsIf XReportType = Enums.XReportTypes.Transactions Then
				// Print transactions
				PrintTransactions(vTemplate, pSpreadsheet, vCurrency, vTranData, vPMData, False, False);
			ElsIf XReportType = Enums.XReportTypes.TransactionsGroupedBySections Then
				// Print transactions
				PrintTransactions(vTemplate, pSpreadsheet, vCurrency, vTranData, vPMSData, False, True);
			EndIf;

			// Print cash-in/outs
			PrintCashInOuts(vTemplate, pSpreadsheet, vCurrency, vCashInOuts, False);
			
			// Put page break at the end of the report
			pSpreadsheet.PutHorizontalPageBreak();
		EndDo;
	Else
		// Print report header with empty currency
		PrintReportHeader(vTemplate, pSpreadsheet, Undefined, True);
		
		// Print no income words
		vNoIncome = vTemplate.GetArea("NoIncome");
		pSpreadsheet.Put(vNoIncome);
	EndIf;
EndProcedure // pmGenerateXReport

// -----------------------------------------------------------------------------
Procedure pmGenerateZReport(pSpreadsheet, pTemplate = Undefined) Export
	// Clear output spreadsheet
	pSpreadsheet.Clear();
	
	// Choose template
	If Not Company.DoNotPrintVATAmountsInShiftReports Then
		vTemplate = GetTemplate("CashRegisterReport");
	Else
		vTemplate = GetTemplate("CashRegisterReportNoVAT");
	EndIf;
	If pTemplate <> Undefined Then
		vTemplate = pTemplate;
	EndIf;
	
	// Retrieve list of currencies
	vCurrencies = pmGetCashRegisterDayCurrencyTotals();
	
	// Get cash-ins and cash-outs
	vCashInOuts = pmGetCashInOutTransactions();
	vCashInOutsTotals = vCashInOuts.Copy();
	vCashInOutsTotals.GroupBy("CashRegister, CashRegisterSortCode, Currency, CurrencySortCode", "Sum, CashInSum, CashOutSum");
	
	// Retrieve cash balances and turnovers
	vCashData = pmGetCashBalancesAndTurnovers();
	
	// Retreive payment method totals
	vPMData = pmGetCashRegisterDayPaymentMethodTotals();
	
	// Retreive payment method and payment section totals
	vPMSData = pmGetCashRegisterDayPaymentMethodAndSectionTotals();
	
	// Retreive payment sections totals
	vPSData = pmGetCashRegisterDayPaymentSectionTotals();
	
	// Retreive services totals
	vSrvData = pmGetCashRegisterDayServiceTotals();

	vAccData = Undefined;
	vTranData = Undefined;
	If ZReportType = Enums.ZReportTypes.AccountingGuestGroupTotals Then
		// Retreive accounting totals
		vAccData = pmGetCashRegisterDayAccountingTotals();
	ElsIf ZReportType = Enums.ZReportTypes.AccountingContractTotals Then
		// Retreive accounting totals
		vAccData = pmGetCashRegisterDayAccountingContractTotals();
	ElsIf ZReportType = Enums.ZReportTypes.Transactions Or 
		  ZReportType = Enums.ZReportTypes.TransactionsWithServices Or 
		  ZReportType = Enums.ZReportTypes.TransactionsGroupedBySections Then
		// Retrieve detailed transactions list
		vTranData = pmGetCashRegisterDayTransactions();
		// Retreive accounting totals
		vAccData = pmGetCashRegisterDayAccountingContractTotals();
	EndIf;
	
	// Print separate reports for each currency
	vZReportWidth = 0;
	If vCurrencies.Count() > 0 Then
		For Each vCurrenciesRow In vCurrencies Do
			vCurrency = vCurrenciesRow.Currency;
			
			vStartHeight = pSpreadSheet.TableHeight + 1;
			
			// Print report header
			PrintReportHeader(vTemplate, pSpreadsheet, vCurrency, False);
			
			// Print payment method totals
			PrintPaymentMethodTotals(vTemplate, pSpreadsheet, vCurrency, vPMData, vPMSData);
			
			// Print payment section totals
			PrintPaymentSectionTotals(vTemplate, pSpreadsheet, vCurrency, vPSData);
			
			// Print cash in cash register totals
			PrintCashInCashRegisterTotals(vTemplate, pSpreadsheet, vCurrency, vCashData, vCashInOutsTotals);
			
			// Print services totals
			If ZReportType <> Enums.ZReportTypes.Transactions Then
				PrintServiceTotals(vTemplate, pSpreadsheet, vCurrency, vSrvData);
			EndIf;
			
			If ZReportType = Enums.ZReportTypes.AccountingGuestGroupTotals Then
				// Print accounting totals
				PrintAccountingTotals(vTemplate, pSpreadsheet, vCurrency, vAccData, vPMSData);
			ElsIf ZReportType = Enums.ZReportTypes.AccountingContractTotals Then
				// Print accounting contract totals
				PrintAccountingContractTotals(vTemplate, pSpreadsheet, vCurrency, vAccData, vPMSData);
			ElsIf ZReportType = Enums.ZReportTypes.Transactions Or ZReportType = Enums.ZReportTypes.TransactionsWithServices Then
				// Print transactions
				PrintTransactions(vTemplate, pSpreadsheet, vCurrency, vTranData, vPMData, True, False);
				// Print accounting contract totals
				PrintAccountingContractTotals(vTemplate, pSpreadsheet, vCurrency, vAccData, vPMSData);
				// Print cash-in/outs
				PrintCashInOuts(vTemplate, pSpreadsheet, vCurrency, vCashInOuts, False);
			ElsIf ZReportType = Enums.ZReportTypes.TransactionsGroupedBySections Then
				// Print transactions
				PrintTransactions(vTemplate, pSpreadsheet, vCurrency, vTranData, vPMSData, True, True);
				// Print accounting contract totals
				PrintAccountingContractTotals(vTemplate, pSpreadsheet, vCurrency, vAccData, vPMSData);
				// Print cash-in/outs
				PrintCashInOuts(vTemplate, pSpreadsheet, vCurrency, vCashInOuts, False);
			EndIf;
			
			// Print no Z-Report footer with signatures
			PrintZReportFooter(vTemplate, pSpreadsheet);
			
			// Create new rows format and set columns width
			vArea = pSpreadsheet.Area(vStartHeight, , pSpreadsheet.TableHeight);
			vArea.CreateFormatOfRows();
			For i = 1 To vTemplate.TableWidth Do
				pSpreadsheet.Area(vStartHeight, i).ColumnWidth = vTemplate.Area(1, i).ColumnWidth;
			EndDo;
			
			vZReportWidth = Max(vZReportWidth, pSpreadsheet.TableWidth);
			
			// Put page break at the end of the report
			pSpreadsheet.PutHorizontalPageBreak();
			
			// Print KM-6 form if neccessary
			If CashRegister.PrintKM6 And vCurrency.Code = 643 And ValueIsFilled(CloseOfCashRegisterDay) Then // In rubles only
				vStartHeight = pSpreadSheet.TableHeight + 1;
			
				// Choose template
				If Not CashRegister.ShowAdvanceClearingColumnInKM6 Then
					vKM6Template = GetTemplate("KM6");
				Else
					vKM6Template = GetTemplate("KM6WithAdvancesClearing");
				EndIf;
							
				// Fill parameters
				vKM6Header = vKM6Template.GetArea("KM6Header");
				mCashRegister = ?(ValueIsFilled(CashRegister), ?(IsBlankString(CashRegister.Model), TrimAll(CashRegister), TrimAll(CashRegister.Model)), "");
				mCashRegisterManufactureNumber = TrimAll(CashRegister.ManufactureNumber); 
				mCashRegisterRegistrationNumber = TrimAll(CashRegister.RegistrationNumber); 
				mCompanyOKPO = "";
				mCompanyTIN = "";
				mCompanyOKDP = "";
				mCompanyLegacyName = "";
				mCompanyLegacyAddress = "";
				If ValueIsFilled(Company) Then
					mCompanyLegacyName = TrimAll(Company.LegacyName);
					mCompanyLegacyAddress = cmGetAddressPresentation(Company.LegacyAddress);
					mCompanyDivision = "";
					If ValueIsFilled(Company.ParentCompany) Then
						mCompanyLegacyName = TrimAll(Company.ParentCompany.LegacyName);
						mCompanyDivision = TrimAll(Company.LegacyName);
					EndIf;
					mCompanyOKPO = TrimAll(Company.OKPO);
					mCompanyTIN = TrimAll(Company.TIN);
					mCompanyOKDP = TrimAll(Company.OKDP);
				EndIf;
				If Not CashRegister.ShowAdvanceClearingColumnInKM6 Then
					mDate = Format(CloseOfCashRegisterDay.Date, "DF=dd.MM.yyyy");
				Else
					mDate = Format(CloseOfCashRegisterDay.Date, "DF=dd.MM.yy");
				EndIf;
				mNumber = cmGetDocumentNumberPresentation(CloseOfCashRegisterDay.Number);
				
				// Period
				mTimeFrom = "";
				mTimeTo = "";
				If ValueIsFilled(CloseOfCashRegisterDay.DateFrom) Then
					If ValueIsFilled(CloseOfCashRegisterDay.AccountingDate) Then
						If BegOfDay(CloseOfCashRegisterDay.DateFrom) <> BegOfDay(CloseOfCashRegisterDay.AccountingDate) Then
							mTimeFrom = Format(CloseOfCashRegisterDay.DateFrom, "DF='dd.MM HH:mm'");
						Else
							mTimeFrom = Format(CloseOfCashRegisterDay.DateFrom, "DF=HH:mm");
						EndIf;
					Else
						mTimeFrom = Format(CloseOfCashRegisterDay.DateFrom, "DF=HH:mm");
					EndIf;
				EndIf;
				If ValueIsFilled(CloseOfCashRegisterDay.Date) Then
					If ValueIsFilled(CloseOfCashRegisterDay.AccountingDate) Then
						If BegOfDay(CloseOfCashRegisterDay.Date) <> BegOfDay(CloseOfCashRegisterDay.AccountingDate) Then
							mTimeTo = Format(CloseOfCashRegisterDay.Date, "DF='dd.MM HH:mm'");
						Else
							mTimeTo = Format(CloseOfCashRegisterDay.Date, "DF=HH:mm");
						EndIf;
					Else
						mTimeTo = Format(CloseOfCashRegisterDay.Date, "DF=HH:mm");
					EndIf;
				EndIf;
				
				// Set parameters
				vKM6Header.Parameters.mCompanyLegacyName = mCompanyLegacyName;
				vKM6Header.Parameters.mCompanyLegacyAddress = mCompanyLegacyAddress;
				vKM6Header.Parameters.mCompanyDivision = mCompanyDivision;
				vKM6Header.Parameters.mCashRegister = mCashRegister;
				vKM6Header.Parameters.mCompanyOKPO = mCompanyOKPO;
				vKM6Header.Parameters.mCompanyTIN = mCompanyTIN;
				vKM6Header.Parameters.mCompanyOKDP = mCompanyOKDP;
				vKM6Header.Parameters.mDate = mDate;
				vKM6Header.Parameters.mNumber = mNumber;
				vKM6Header.Parameters.mTimeFrom = mTimeFrom;
				vKM6Header.Parameters.mTimeTo = mTimeTo;
				vKM6Header.Parameters.mCashRegisterManufactureNumber = mCashRegisterManufactureNumber;
				vKM6Header.Parameters.mCashRegisterRegistrationNumber = mCashRegisterRegistrationNumber;
				
				// Put KM-6 header
				pSpreadsheet.Put(vKM6Header);
				
				vHeader = vKM6Template.GetArea("Header");
				pSpreadsheet.Put(vHeader);
				
				// Do for each payment method and section code
				vTotalAmount = 0;
				vTotalReturned = 0;
				vTotalCleared = 0;
				
				vPMPS = vKM6Template.GetArea("Row");
				
				mPaymentMethodCode = "";
				mPaymentSectionCode = "0";
				mRowTotal = 0;
				mRowReturned = 0;
				mRowCleared = 0;
				
				For Each vPMPSRow In vPMSData Do
					// Fill parameters
					If ValueIsFilled(vPMPSRow.PaymentMethod) Then
						If Not CashRegister.ShowTotalsForAllPaymentMethodsInKM6 Then
							If Not vPMPSRow.PaymentMethod.IsByCash Then
								Continue;
							Else
								If IsBlankString(mPaymentMethodCode) Then
									mPaymentMethodCode = ?(vPMPSRow.PaymentMethod.CashRegisterCode <> 0, Format(vPMPSRow.PaymentMethod.CashRegisterCode, "ND=2; NFD=0; NZ=; NG="), TrimAll(vPMPSRow.PaymentMethod.Code));
								EndIf;
							EndIf;
						EndIf;
					EndIf;
					If vPMPSRow.PaymentMethod = Catalogs.PaymentMethods.AdvanceSettlement Then
						If Not CashRegister.ShowAdvanceClearingColumnInKM6 Then
							Continue;
						EndIf;
						If ValueIsFilled(vPMPSRow.PaymentSection) Then
							mRowCleared = mRowCleared - vPMPSRow.PaymentSum;
							
							vTotalCleared = vTotalCleared - vPMPSRow.PaymentSum;
						Else
							Continue;
						EndIf;
					Else
						mRowTotal = mRowTotal + vPMPSRow.PaymentSum;
						mRowReturned = mRowReturned + vPMPSRow.ReturnSum;
						
						vTotalAmount = vTotalAmount + vPMPSRow.PaymentSum;
						vTotalReturned = vTotalReturned + vPMPSRow.ReturnSum;
					EndIf;
				EndDo;
				If IsBlankString(mPaymentMethodCode) Then
					mPaymentMethodCode = "0";
				EndIf;
				
				// Set parameters
				vPMPS.Parameters.mPaymentMethodCode = mPaymentMethodCode;
				vPMPS.Parameters.mPaymentSectionCode = mPaymentSectionCode;
				vPMPS.Parameters.mRowTotal = mRowTotal;
				vPMPS.Parameters.mRowReturned = mRowReturned;
				If CashRegister.ShowAdvanceClearingColumnInKM6 Then
					vPMPS.Parameters.mRowCleared = mRowCleared;
				EndIf;
			
				// Put payment method/payment section row
				pSpreadsheet.Put(vPMPS);
				
				vTotal = vKM6Template.GetArea("Total");
				vTotal.Parameters.mTotal = vTotalAmount;
				vTotal.Parameters.mTotalReturned = vTotalReturned;
				vTotal.Parameters.mTotalInWords = cmSumInWords((vTotalAmount - vTotalReturned), vCurrency, Catalogs.Languages.RU);
				If CashRegister.ShowAdvanceClearingColumnInKM6 Then
					vTotal.Parameters.mTotalCleared = vTotalCleared;
				EndIf;
				pSpreadsheet.Put(vTotal);
				
				vFooter = vKM6Template.GetArea("Footer");
				pSpreadsheet.Put(vFooter);
				
				vBackSide = vKM6Template.GetArea("BackSide");
				mDirectorPosition = "Директор";
				mDirector = "";
				If ValueIsFilled(Company) Then
					If Not IsBlankString(Company.DirectorPosition) Then
						mDirectorPosition = cmNStr(TrimAll(Company.DirectorPosition), Catalogs.Languages.RU);
					EndIf;
					mDirector = cmNStr(TrimAll(Company.Director), Catalogs.Languages.RU);
				EndIf;					
				vBackSide.Parameters.mDirectorPosition = mDirectorPosition;
				vBackSide.Parameters.mDirector = mDirector;
				pSpreadsheet.Put(vBackSide);
				
				// Create new rows format and set columns width
				vArea = pSpreadsheet.Area(vStartHeight, , pSpreadsheet.TableHeight);
				vArea.CreateFormatOfRows();
				For i = 1 To vKM6Template.TableWidth Do
					pSpreadsheet.Area(vStartHeight, i).ColumnWidth = vKM6Template.Area(1, i).ColumnWidth;
				EndDo;
			
				// Put page break at the end of the report
				pSpreadsheet.PutHorizontalPageBreak();
			EndIf;
		EndDo;
	Else
		// Print report header with empty currency
		PrintReportHeader(vTemplate, pSpreadsheet, Undefined, False);
		
		// Print no income words
		vNoIncome = vTemplate.GetArea("NoIncome");
		pSpreadsheet.Put(vNoIncome);
		
		// Print no Z-Report footer with signatures
		PrintZReportFooter(vTemplate, pSpreadsheet);
		
		vZReportWidth = Max(vZReportWidth, pSpreadsheet.TableWidth);
		
		// Print KM-6 form if neccessary
		If CashRegister.PrintKM6 And ValueIsFilled(CloseOfCashRegisterDay) Then // In rubles only
			vStartHeight = pSpreadSheet.TableHeight + 1;
		
			// Put page break at the end of the report
			pSpreadsheet.PutHorizontalPageBreak();
		
			// Choose template
			If Not CashRegister.ShowAdvanceClearingColumnInKM6 Then
				vKM6Template = GetTemplate("KM6");
			Else
				vKM6Template = GetTemplate("KM6WithAdvancesClearing");
			EndIf;
						
			// Fill parameters
			vKM6Header = vKM6Template.GetArea("KM6Header");
			mCashRegister = TrimAll(CashRegister.Description);
			mCashRegisterManufactureNumber = TrimAll(CashRegister.ManufactureNumber); 
			mCashRegisterRegistrationNumber = TrimAll(CashRegister.RegistrationNumber); 
			mCompanyOKPO = "";
			mCompanyTIN = "";
			mCompanyOKDP = "";
			mCompanyLegacyName = "";
			If ValueIsFilled(Company) Then
				mCompanyLegacyName = TrimAll(Company.LegacyName);
				mCompanyDivision = "";
				If ValueIsFilled(Company.ParentCompany) Then
					mCompanyLegacyName = TrimAll(Company.ParentCompany.LegacyName);
					mCompanyDivision = TrimAll(Company.LegacyName);
				EndIf;
				mCompanyOKPO = TrimAll(Company.OKPO);
				mCompanyTIN = TrimAll(Company.TIN);
				mCompanyOKDP = TrimAll(Company.OKDP);
			EndIf;
			If Not CashRegister.ShowAdvanceClearingColumnInKM6 Then
				mDate = Format(CloseOfCashRegisterDay.Date, "DF=dd.MM.yyyy");
			Else
				mDate = Format(CloseOfCashRegisterDay.Date, "DF=dd.MM.yy");
			EndIf;
			mNumber = cmGetDocumentNumberPresentation(CloseOfCashRegisterDay.Number);
			
			// Set parameters
			vKM6Header.Parameters.mCompanyLegacyName = mCompanyLegacyName;
			vKM6Header.Parameters.mCompanyDivision = mCompanyDivision;
			vKM6Header.Parameters.mCashRegister = mCashRegister;
			vKM6Header.Parameters.mCompanyOKPO = mCompanyOKPO;
			vKM6Header.Parameters.mCompanyTIN = mCompanyTIN;
			vKM6Header.Parameters.mCompanyOKDP = mCompanyOKDP;
			vKM6Header.Parameters.mDate = mDate;
			vKM6Header.Parameters.mNumber = mNumber;
			vKM6Header.Parameters.mCashRegisterManufactureNumber = mCashRegisterManufactureNumber;
			vKM6Header.Parameters.mCashRegisterRegistrationNumber = mCashRegisterRegistrationNumber;
			
			// Put KM-6 header
			pSpreadsheet.Put(vKM6Header);
			
			vHeader = vKM6Template.GetArea("Header");
			pSpreadsheet.Put(vHeader);
			
			// Do for each payment method and section code
			vTotalAmount = 0;
			vPMPS = vKM6Template.GetArea("Row");
			mPaymentMethodCode = "";
			mPaymentSectionCode = "";
			mRowTotal = 0;
			
			// Set parameters
			vPMPS.Parameters.mPaymentMethodCode = mPaymentMethodCode;
			vPMPS.Parameters.mPaymentSectionCode = mPaymentSectionCode;
			vPMPS.Parameters.mRowTotal = mRowTotal;
		
			// Put payment method/payment section row
			pSpreadsheet.Put(vPMPS);
			
			vTotal = vKM6Template.GetArea("Total");
			vTotal.Parameters.mTotal = vTotalAmount;
			vTotal.Parameters.mTotalInWords = "";
			pSpreadsheet.Put(vTotal);
			
			vFooter = vKM6Template.GetArea("Footer");
			pSpreadsheet.Put(vFooter);
			
			vBackSide = vKM6Template.GetArea("BackSide");
			mDirectorPosition = "Директор";
			mDirector = "";
			If ValueIsFilled(Company) Then
				If Not IsBlankString(Company.DirectorPosition) Then
					mDirectorPosition = cmNStr(TrimAll(Company.DirectorPosition), Catalogs.Languages.RU);
				EndIf;
				mDirector = cmNStr(TrimAll(Company.Director), Catalogs.Languages.RU);
			EndIf;					
			vBackSide.Parameters.mDirectorPosition = mDirectorPosition;
			vBackSide.Parameters.mDirector = mDirector;
			pSpreadsheet.Put(vBackSide);
			
			// Create new rows format and set columns width
			vArea = pSpreadsheet.Area(vStartHeight, , pSpreadsheet.TableHeight);
			vArea.CreateFormatOfRows();
			For i = 1 To vKM6Template.TableWidth Do
				pSpreadsheet.Area(vStartHeight, i).ColumnWidth = vKM6Template.Area(1, i).ColumnWidth;
			EndDo;
		
			// Put page break at the end of the report
			pSpreadsheet.PutHorizontalPageBreak();
		EndIf;
	EndIf;
	
	// Print corrections
	vCorrections = pmGetCashRegisterCorrections();
	If vCorrections.Count() > 0 Then
		vStartHeight = pSpreadSheet.TableHeight + 1;
		
		// Print corrections header
		PrintCorrectionsHeader(vTemplate, pSpreadsheet);
		
		// Print corrections
		PrintCorrections(vTemplate, pSpreadsheet, vCorrections);
		
		// Print corrections footer
		PrintCorrectionsFooter(vTemplate, pSpreadsheet);
		
		// Create new rows format and set columns width
		vArea = pSpreadsheet.Area(vStartHeight, , pSpreadsheet.TableHeight);
		vArea.CreateFormatOfRows();
		For i = 1 To vTemplate.TableWidth Do
			pSpreadsheet.Area(vStartHeight, i).ColumnWidth = vTemplate.Area(1, i).ColumnWidth;
		EndDo;
	EndIf;
	
	// Set print area
	pSpreadsheet.PrintArea = pSpreadsheet.Area(, 1, , vZReportWidth);
	// Send email
	If ValueIsFilled(CashRegister) And Not IsBlankString(TrimAll(CashRegister.EmailList)) Then
		// Get file and save catalog names
		vFileName = "ZReport_N_"+String(CloseOfCashRegisterDay.Number);
		
		mReportName = NStr("en='Cash register Z-Report #';ru='Z-Отчет кассовой смены №';de='Z-Bericht der Kassenschicht Nr.'") + 
		cmGetDocumentNumberPresentation(CloseOfCashRegisterDay.Number) + 
		NStr("en=' at ';ru=' от ';de='vom'") +
		Format(DateTo, "DF='dd.MM.yy HH:mm'");
		
		vFileSaveCatalog = TempFilesDir();
		// Get full file name and save file
		vFileName = vFileName + ".pdf";
		vFullFileName = cmGetFullFileName(vFileName, vFileSaveCatalog);
		pSpreadsheet.Write(vFullFileName, SpreadsheetDocumentFileType.PDF);
		// Check if we have to send file by e-mail
		vSubject = vFileName;
		vMessage = cmNStr("ru='Рассылка печатных форм: '; de='Versand von Druckformen: '; en = 'Print form delivery: '") + Chars.LF + Chars.LF + 
		mReportName + Chars.LF + Chars.LF + 
		cmNStr("ru='C уважением, '; de='Hochachtungsvoll, '; en='Best regards, '") + Chars.LF + 
		cmNStr(SessionParameters.ConfigurationName);
		// Send file in modal mode to get and show result
		vFilesMap = New Map;
		vFilesMap.Insert(vFileName, vFullFileName);
		vResult = JobsScheduled.cmSendFilesByEMail(vSubject, vMessage, TrimAll(CashRegister.EmailList), vFilesMap);
		// Delete temp file
		DeleteFiles(vFullFileName);
	EndIf;	
EndProcedure // pmGenerateZReport

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure PrintReportHeader(pTemplate, pSpreadsheet, pCurrency, pIsXReport)
	vHeader = pTemplate.GetArea("Header");
	
	// Fill parameters
	mReportName = "";
	If pIsXReport Then
		mReportName = NStr("en='Cash register X-Report';ru='X-Отчет кассовой смены';de='X-Bericht der Kassenschicht'");
	Else
		mReportName = NStr("en='Cash register Z-Report #';ru='Z-Отчет кассовой смены №';de='Z-Bericht der Kassenschicht Nr.'") + 
		              cmGetDocumentNumberPresentation(CloseOfCashRegisterDay.Number) + 
		              NStr("en=' at ';ru=' от ';de='vom'") +
		              Format(DateTo, "DF='dd.MM.yy HH:mm'");
	EndIf;
	mCompanyLegacyName = "";
	If ValueIsFilled(Company) Then
		mCompanyLegacyName = TrimAll(Company.LegacyName);
	EndIf;
	mCashRegister = TrimAll(CashRegister);
	mCurrency = TrimAll(pCurrency);
	mEmployee = TrimAll(Author);
	mDateFrom = Format(DateFrom, "DF='dd.MM.yy HH:mm'");
	mDateTo = Format(DateTo, "DF='dd.MM.yy HH:mm'");
	If ValueIsFilled(CloseOfCashRegisterDay) Then
		mAccountingDate = ?(ValueIsFilled(CloseOfCashRegisterDay.AccountingDate), CloseOfCashRegisterDay.AccountingDate, DateTo);
	ElsIf ValueIsFilled(CashRegister) And ValueIsFilled(CashRegister.Hotel) And ValueIsFilled(CashRegister.Hotel.AccountingDate) Then
		mAccountingDate = CashRegister.Hotel.AccountingDate;
	Else
		mAccountingDate = CurrentDate();
	EndIf;
	
	// Set parameters
	vHeader.Parameters.mReportName = mReportName;
	vHeader.Parameters.mCompanyLegacyName = mCompanyLegacyName;
	vHeader.Parameters.mCashRegister = mCashRegister;
	vHeader.Parameters.mCurrency = mCurrency;
	vHeader.Parameters.mEmployee = mEmployee;
	vHeader.Parameters.mDateFrom = mDateFrom;
	vHeader.Parameters.mDateTo = mDateTo;
	vHeader.Parameters.mAccountingDate = mAccountingDate;
	
	// Put header
	pSpreadsheet.Put(vHeader);
EndProcedure // PrintReportHeader

// -----------------------------------------------------------------------------
Procedure PrintPaymentMethodTotals(pTemplate, pSpreadsheet, pCurrency, pPMData, pPMSData)
	// Check should we print payment section totals
	vShowPaymentSections = False;
	vPaymentSections = cmGetAllPaymentSections(SessionParameters.CurrentHotel);
	If vPaymentSections.Count() > 0 Then
		vShowPaymentSections = True;
	EndIf;
	
	// Header
	vHeader = pTemplate.GetArea("PaymentMethodHeader");
	pSpreadsheet.Put(vHeader);
	
	// Get records for selected currency only
	vPMData = pPMData.FindRows(New Structure("Currency", pCurrency));
	
	// Do for each payment method
	vSumTotal = 0;
	vPaymentSumTotal = 0;
	vReturnSumTotal = 0;
	vVATSumTotal = 0;
	For Each vPMRow In vPMData Do
		vPMArea = pTemplate.GetArea("PaymentMethodRow");
		vPMPSArea = pTemplate.GetArea("PaymentMethodPaymentSectionRow");
		
		// Fill parameters
		mPaymentMethod = TrimAll(vPMRow.PaymentMethod);
		mPaymentSum = Format(vPMRow.PaymentSum, "ND=17; NFD=2");
		mReturnSum = Format(vPMRow.ReturnSum, "ND=17; NFD=2");
		mSum = Format(vPMRow.Sum, "ND=17; NFD=2");
		mVATSum = Format(vPMRow.VATSum, "ND=17; NFD=2");
		
		// Set parameters
		vPMArea.Parameters.mPaymentMethod = mPaymentMethod;
		vPMArea.Parameters.mPaymentSum = mPaymentSum;
		vPMArea.Parameters.mReturnSum = mReturnSum;
		vPMArea.Parameters.mSum = mSum;
		If Not Company.DoNotPrintVATAmountsInShiftReports Then
			vPMArea.Parameters.mVATSum = mVATSum;
		EndIf;
	
		// Put payment method row
		pSpreadsheet.Put(vPMArea);
		
		// Print payment method payment sections
		If vShowPaymentSections Then
			vPMPSData = pPMSData.FindRows(New Structure("Currency, PaymentMethod", pCurrency, vPMRow.PaymentMethod));
			For Each vPMPSRow In vPMPSData Do
				If IsBlankString(TrimAll(vPMPSRow.PaymentSection)) And vPMPSData.Count() = 1 Then
					Break;
				EndIf;
				
				// Fill parameters
				mPaymentSection = TrimAll(vPMPSRow.PaymentSection);
				mPaymentSum = Format(vPMPSRow.PaymentSum, "ND=17; NFD=2");
				mReturnSum = Format(vPMPSRow.ReturnSum, "ND=17; NFD=2");
				mSum = Format(vPMPSRow.Sum, "ND=17; NFD=2");
				mVATSum = Format(vPMPSRow.VATSum, "ND=17; NFD=2");
				
				// Set parameters
				vPMPSArea.Parameters.mPaymentSection = Chars.Tab + mPaymentSection;
				vPMPSArea.Parameters.mPaymentSum = mPaymentSum;
				vPMPSArea.Parameters.mReturnSum = mReturnSum;
				vPMPSArea.Parameters.mSum = mSum;
				If Not Company.DoNotPrintVATAmountsInShiftReports Then
					vPMPSArea.Parameters.mVATSum = mVATSum;
				EndIf;
			
				// Put payment method row
				pSpreadsheet.Put(vPMPSArea);
			EndDo;
		EndIf;
		
		// Fill totals
		vSumTotal = vSumTotal + vPMRow.Sum;
		vPaymentSumTotal = vPaymentSumTotal + vPMRow.PaymentSum;
		vReturnSumTotal = vReturnSumTotal + vPMRow.ReturnSum;
		vVATSumTotal = vVATSumTotal + vPMRow.VATSum;
	EndDo;
	
	// Put footer with cash balances and turnovers
	vFooter = pTemplate.GetArea("PaymentMethodFooter");
	
	// Set parameters
	vFooter.Parameters.mSum = Format(vSumTotal, "ND=17; NFD=2");
	vFooter.Parameters.mPaymentSum = Format(vPaymentSumTotal, "ND=17; NFD=2");
	vFooter.Parameters.mReturnSum = Format(vReturnSumTotal, "ND=17; NFD=2");
	If Not Company.DoNotPrintVATAmountsInShiftReports Then
		vFooter.Parameters.mVATSum = Format(vVATSumTotal, "ND=17; NFD=2");
	EndIf;
	
	pSpreadsheet.Put(vFooter);
EndProcedure // PrintPaymentMethodTotals

// -----------------------------------------------------------------------------
Procedure PrintPaymentSectionTotals(pTemplate, pSpreadsheet, pCurrency, pPSData)
	// Check if there is data to print
	If pPSData.Count() = 0 Then
		Return;
	ElsIf pPSData.Count() = 1 Then
		vFirstPaymentSectionRow = pPSData.Get(0);
		If Not ValueIsFilled(vFirstPaymentSectionRow.PaymentSection) Then
			Return;
		EndIf;
	EndIf;
	
	// Header
	vHeader = pTemplate.GetArea("PaymentSectionHeader");
	pSpreadsheet.Put(vHeader);
	
	// Get records for selected currency only
	vPSData = pPSData.FindRows(New Structure("Currency", pCurrency));
	
	// Do for each payment method
	For Each vPSRow In vPSData Do
		vPSArea = pTemplate.GetArea("PaymentSectionRow");
		
		// Fill parameters
		mPaymentSection = TrimAll(vPSRow.PaymentSection);
		mPaymentSum = Format(vPSRow.PaymentSum, "ND=17; NFD=2");
		mReturnSum = Format(vPSRow.ReturnSum, "ND=17; NFD=2");
		mSum = Format(vPSRow.Sum, "ND=17; NFD=2");
		mVATSum = Format(vPSRow.VATSum, "ND=17; NFD=2");
		
		// Set parameters
		vPSArea.Parameters.mPaymentSection = mPaymentSection;
		vPSArea.Parameters.mPaymentSum = mPaymentSum;
		vPSArea.Parameters.mReturnSum = mReturnSum;
		vPSArea.Parameters.mSum = mSum;
		If Not Company.DoNotPrintVATAmountsInShiftReports Then
			vPSArea.Parameters.mVATSum = mVATSum;
		EndIf;
	
		// Put payment section row
		pSpreadsheet.Put(vPSArea);
	EndDo;
	
	// Put payment sections footer
	vFooter = pTemplate.GetArea("PaymentSectionFooter");
	pSpreadsheet.Put(vFooter);
EndProcedure // PrintPaymentSectionTotals

// -----------------------------------------------------------------------------
Procedure PrintServiceTotals(pTemplate, pSpreadsheet, pCurrency, pSrvData)
	// Check if there is data to print
	If pSrvData.Count() = 0 Then
		Return;
	ElsIf pSrvData.Count() = 1 Then
		vFirstServiceRow = pSrvData.Get(0);
		If Not ValueIsFilled(vFirstServiceRow.Service) Then
			Return;
		EndIf;
	EndIf;
	
	vPMData = pSrvData.Copy();
	vPMData.GroupBy("PaymentMethod");
	
	// Header
	vHeader = pTemplate.GetArea("ServiceHeader");
	pSpreadsheet.Put(vHeader);
	
	// By payment methods
	For Each vPMRow In vPMData Do
		// Header
		vPMHeader = pTemplate.GetArea("ServicePaymentMethod");
		vPMHeader.Parameters.mPaymentMethod = TrimAll(vPMRow.PaymentMethod);
		pSpreadsheet.Put(vPMHeader);
		
		// Get records for selected currency only
		vSrvData = pSrvData.FindRows(New Structure("Currency, PaymentMethod", pCurrency, vPMRow.PaymentMethod));
		
		// Do for each service
		vSumTotal = 0;
		vVATSumTotal = 0;
		For Each vSrvRow In vSrvData Do
			vSrvArea = pTemplate.GetArea("ServiceRow");
			
			// Fill parameters
			mService = TrimAll(vSrvRow.Service);
			mPrice = Format(vSrvRow.Price, "ND=17; NFD=2");
			mQuantity = Format(vSrvRow.Quantity, "ND=17; NFD=3");
			mPaymentSum = Format(vSrvRow.PaymentSum, "ND=17; NFD=2");
			mReturnSum = Format(vSrvRow.ReturnSum, "ND=17; NFD=2");
			mSum = Format(vSrvRow.Sum, "ND=17; NFD=2");
			mVATSum = Format(vSrvRow.VATSum, "ND=17; NFD=2");
			
			// Set parameters
			vSrvArea.Parameters.mService = mService;
			vSrvArea.Parameters.dService = vSrvRow.Service;
			vSrvArea.Parameters.mPrice = mPrice;
			vSrvArea.Parameters.mQuantity = mQuantity;
			vSrvArea.Parameters.mPaymentSum = mPaymentSum;
			vSrvArea.Parameters.mReturnSum = mReturnSum;
			vSrvArea.Parameters.mSum = mSum;
			If Not Company.DoNotPrintVATAmountsInShiftReports Then
				vSrvArea.Parameters.mVATSum = mVATSum;
			EndIf;
		
			// Put payment section row
			pSpreadsheet.Put(vSrvArea);
			
			vSumTotal = vSumTotal + vSrvRow.Sum;
			vVATSumTotal = vVATSumTotal + vSrvRow.VATSum;
		EndDo;
		
		// Put payment sections footer
		vFooter = pTemplate.GetArea("ServiceFooter");
		vFooter.Parameters.mTotalSum = Format(vSumTotal, "ND=17; NFD=2");
		If Not Company.DoNotPrintVATAmountsInShiftReports Then
			vFooter.Parameters.mTotalVATSum = Format(vVATSumTotal, "ND=17; NFD=2");
		EndIf;
		pSpreadsheet.Put(vFooter);
	EndDo;
EndProcedure // PrintServiceTotals

// -----------------------------------------------------------------------------
Procedure PrintCashInCashRegisterTotals(pTemplate, pSpreadsheet, pCurrency, pCashData, pCashInOutData)
	// Get records for selected currency only
	vCashData = pCashData.FindRows(New Structure("Currency", pCurrency));
	vCashInOutData = pCashInOutData.FindRows(New Structure("Currency", pCurrency));
	
	// Put area with cash balances and turnovers
	vCash = pTemplate.GetArea("CashInCashRegister");
	
	vSumOpeningBalance = 0;
	vSumClosingBalance = 0;
	vSumPayments = 0;
	vSumReturns = 0;
	vSumCashIn = 0;
	vSumCashOut = 0;
	
	// Get cash balance at the end of the cash register day
	If vCashData.Count() > 0 Or vCashInOutData.Count() > 0 Then
		If vCashData.Count() > 0 Then
			vCashDataRow = vCashData.Get(0);
			
			vSumOpeningBalance = vCashDataRow.SumOpeningBalance;
			vSumClosingBalance = vCashDataRow.SumClosingBalance;
			vSumPayments = vCashDataRow.SumReceipt;
			vSumReturns = vCashDataRow.SumExpense;
		EndIf;
		If vCashInOutData.Count() > 0 Then
			vCashInOutDataRow = vCashInOutData.Get(0);
			
			vSumCashIn = vCashInOutDataRow.CashInSum;
			vSumCashOut = vCashInOutDataRow.CashOutSum;
		EndIf;
		vSumPayments = vSumPayments - vSumCashIn;
		vSumReturns = vSumReturns - vSumCashOut;
	EndIf;
	
	// Set parameters
	vCash.Parameters.mCashStartBalance = Format(vSumOpeningBalance, "ND=17; NFD=2");
	vCash.Parameters.mCashEndBalance = Format(vSumClosingBalance, "ND=17; NFD=2");
	vCash.Parameters.mCashIncome = Format(vSumCashIn, "ND=17; NFD=2");
	vCash.Parameters.mCashOutcome = Format(vSumCashOut, "ND=17; NFD=2");
	vCash.Parameters.mCashPayments = Format(vSumPayments, "ND=17; NFD=2");
	vCash.Parameters.mCashReturns = Format(vSumReturns, "ND=17; NFD=2");
	
	pSpreadsheet.Put(vCash);
EndProcedure // PrintCashInCashRegisterTotals

// -----------------------------------------------------------------------------
Procedure PrintAccountingTotals(pTemplate, pSpreadsheet, pCurrency, pAccData, pPMSData)
	// Header
	vHeader = pTemplate.GetArea("CustomerHeader");
	pSpreadsheet.Put(vHeader);
	
	// Get records for selected currency only
	vPMSData = pPMSData.FindRows(New Structure("Currency", pCurrency));
	
	// Do for each payment method
	For Each vPMSRow In vPMSData Do
		vPMSArea = pTemplate.GetArea("CustomerPaymentMethod");
		// Fill parameters
		mPaymentMethod = NStr("en='Payment method: ';ru='Способ оплаты: ';de='Zahlungsmethode:'") + TrimAll(vPMSRow.PaymentMethod);
		mPaymentSection = "";
		If ValueIsFilled(vPMSRow.PaymentSection) Then
			mPaymentSection = NStr("ru = 'Секция: '; en = 'Payment section: '") + TrimAll(vPMSRow.PaymentSection);
		EndIf;
		// Set parameters
		vPMSArea.Parameters.mPaymentMethod = mPaymentMethod;
		vPMSArea.Parameters.mPaymentSection = mPaymentSection;
		// Put payment method row
		pSpreadsheet.Put(vPMSArea);
		
		// Get records for selected currency and payment method
		vAccData = pAccData.FindRows(New Structure("Currency, PaymentMethod, PaymentSection", pCurrency, vPMSRow.PaymentMethod, vPMSRow.PaymentSection));
		
		// Payment method totals
		vPMSTotals = 0;
		vPMSVATTotals = 0;
		
		// Do for each payment method
		For Each vAccRow In vAccData Do
			vAccArea = pTemplate.GetArea("CustomerRow");
			
			// Fill parameters
			mCustomer = "";
			dCustomer = vAccRow.Customer;
			If ValueIsFilled(vAccRow.Customer) Then
				mCustomer = TrimAll(vAccRow.Customer);
			Else
				mCustomer = NStr("en='<Persons>';ru='<Физ. лица>';de='<natürliche Personen>'");
			EndIf;
			mContract = TrimAll(vAccRow.Contract);
			dContract = vAccRow.Contract;
			mGuestGroup = TrimAll(vAccRow.GuestGroup);
			If ValueIsFilled(vAccRow.GuestGroup) And Not IsBlankString(vAccRow.GuestGroup.Description) Then
				mGuestGroup = mGuestGroup + Chars.LF + Left(TrimAll(vAccRow.GuestGroup.Description), 8);
			EndIf;
			mPaymentSum = Format(vAccRow.PaymentSum, "ND=17; NFD=2");
			mReturnSum = Format(vAccRow.ReturnSum, "ND=17; NFD=2");
			mSum = Format(vAccRow.Sum, "ND=17; NFD=2");
			mVATSum = Format(vAccRow.VATSum, "ND=17; NFD=2");
			
			vPMSTotals = vPMSTotals + vAccRow.Sum;
			vPMSVATTotals = vPMSVATTotals + vAccRow.VATSum;
			
			// Set parameters
			vAccArea.Parameters.mCustomer = mCustomer;
			vAccArea.Parameters.dCustomer = dCustomer;
			vAccArea.Parameters.mContract = mContract;
			vAccArea.Parameters.dContract = dContract;
			vAccArea.Parameters.mGuestGroup = mGuestGroup;
			vAccArea.Parameters.mPaymentSum = mPaymentSum;
			vAccArea.Parameters.mReturnSum = mReturnSum;
			vAccArea.Parameters.mSum = mSum;
			If Not Company.DoNotPrintVATAmountsInShiftReports Then
				vAccArea.Parameters.mVATSum = mVATSum;
			EndIf;
		
			// Put payment method row
			pSpreadsheet.Put(vAccArea);
		EndDo;
		
		// Put customer payment method footer
		vFooter = pTemplate.GetArea("CustomerPaymentMethodFooter");
		vFooter.Parameters.mTotalSum = Format(vPMSTotals, "ND=17; NFD=2");
		If Not Company.DoNotPrintVATAmountsInShiftReports Then
			vFooter.Parameters.mTotalVATSum = Format(vPMSVATTotals, "ND=17; NFD=2");
		EndIf;
		pSpreadsheet.Put(vFooter);
	EndDo;
EndProcedure // PrintAccountingTotals

// -----------------------------------------------------------------------------
Procedure PrintAccountingContractTotals(pTemplate, pSpreadsheet, pCurrency, pAccData, pPMSData)
	// Header
	vHeader = pTemplate.GetArea("CustomerHeader");
	pSpreadsheet.Put(vHeader);
	
	// Get records for selected currency only
	vPMSData = pPMSData.FindRows(New Structure("Currency", pCurrency));
	
	// Do for each payment method
	For Each vPMSRow In vPMSData Do
		vPMSArea = pTemplate.GetArea("CustomerContractPaymentMethod");
		// Fill parameters
		mPaymentMethod = NStr("en='Payment method: ';ru='Способ оплаты: ';de='Zahlungsmethode:'") + TrimAll(vPMSRow.PaymentMethod);
		mPaymentSection = "";
		If ValueIsFilled(vPMSRow.PaymentSection) Then
			mPaymentSection = NStr("ru = 'Секция: '; en = 'Payment section: '") + TrimAll(vPMSRow.PaymentSection);
		EndIf;
		// Set parameters
		vPMSArea.Parameters.mPaymentMethod = mPaymentMethod;
		vPMSArea.Parameters.mPaymentSection = mPaymentSection;
		// Put payment method row
		pSpreadsheet.Put(vPMSArea);
		
		// Get records for selected currency and payment method
		vAccData = pAccData.FindRows(New Structure("Currency, PaymentMethod, PaymentSection", pCurrency, vPMSRow.PaymentMethod, vPMSRow.PaymentSection));
		
		// Payment method totals
		vPMSTotals = 0;
		vPMSVATTotals = 0;
		
		// Do for each payment method
		For Each vAccRow In vAccData Do
			vAccArea = pTemplate.GetArea("CustomerContractRow");
			
			// Fill parameters
			mCustomer = "";
			dCustomer = vAccRow.Customer;
			If ValueIsFilled(vAccRow.Customer) Then
				mCustomer = TrimAll(vAccRow.Customer);
			Else
				mCustomer = NStr("en='<Persons>';ru='<Физ. лица>';de='<natürliche Personen>'");
			EndIf;
			mContract = TrimAll(vAccRow.Contract);
			dContract = vAccRow.Contract;
			mPaymentSum = Format(vAccRow.PaymentSum, "ND=17; NFD=2");
			mReturnSum = Format(vAccRow.ReturnSum, "ND=17; NFD=2");
			mSum = Format(vAccRow.Sum, "ND=17; NFD=2");
			mVATSum = Format(vAccRow.VATSum, "ND=17; NFD=2");
			
			vPMSTotals = vPMSTotals + vAccRow.Sum;
			vPMSVATTotals = vPMSVATTotals + vAccRow.VATSum;
			
			// Set parameters
			vAccArea.Parameters.mCustomer = mCustomer;
			vAccArea.Parameters.dCustomer = dCustomer;
			vAccArea.Parameters.mContract = mContract;
			vAccArea.Parameters.dContract = dContract;
			vAccArea.Parameters.mPaymentSum = mPaymentSum;
			vAccArea.Parameters.mReturnSum = mReturnSum;
			vAccArea.Parameters.mSum = mSum;
			If Not Company.DoNotPrintVATAmountsInShiftReports Then
				vAccArea.Parameters.mVATSum = mVATSum;
			EndIf;
		
			// Put payment method row
			pSpreadsheet.Put(vAccArea);
		EndDo;
		
		// Put customer payment method footer
		vFooter = pTemplate.GetArea("CustomerPaymentMethodFooter");
		vFooter.Parameters.mTotalSum = Format(vPMSTotals, "ND=17; NFD=2");
		If Not Company.DoNotPrintVATAmountsInShiftReports Then
			vFooter.Parameters.mTotalVATSum = Format(vPMSVATTotals, "ND=17; NFD=2");
		EndIf;
		pSpreadsheet.Put(vFooter);
	EndDo;
EndProcedure // PrintAccountingContractTotals

// -----------------------------------------------------------------------------
Function GetDocumentServiceDescription(pDocument)
	vStr = "";
	If ValueIsFilled(pDocument) And (TypeOf(pDocument) = Type("DocumentRef.Payment") Or TypeOf(pDocument) = Type("DocumentRef.Return")) Then
		For Each vPSRow In pDocument.PaymentSections Do
			vChequeService = vPSRow.ChequeService;
			If ValueIsFilled(vChequeService) Then
				If vChequeService.IsRoomRevenue Then
					vStr = vChequeService.GetObject().pmGetServiceDescription(SessionParameters.CurrentLanguage);
					Break;
				EndIf;
			EndIf;
		EndDo;
		If IsBlankString(vStr) Then
			For Each vPSRow In pDocument.PaymentSections Do
				vChequeService = vPSRow.ChequeService;
				If ValueIsFilled(vChequeService) Then
					If ValueIsFilled(vChequeService.ServiceType) Then
						vStr = TrimAll(vChequeService.ServiceType);
					Else
						vStr = vChequeService.GetObject().pmGetServiceDescription(SessionParameters.CurrentLanguage);
					EndIf;
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	Return vStr;
EndFunction // GetDocumentServiceDescription

// -----------------------------------------------------------------------------
Procedure PrintTransactions(pTemplate, pSpreadsheet, pCurrency, pTranData, pPMData, pIsZReport, pBySections)
	// Header
	vHeader = pTemplate.GetArea("TransactionsHeader");
	pSpreadsheet.Put(vHeader);
		
	vTranArea = pTemplate.GetArea("TransactionRow");
	
	// Get records for selected currency only
	vPMData = pPMData.FindRows(New Structure("Currency", pCurrency));
	
	// Do for each payment method
	For Each vPMRow In vPMData Do
		If pBySections Then
			vPMArea = pTemplate.GetArea("TransactionsPaymentMethodPaymentSection");
			// Fill parameters
			mPaymentMethod = NStr("en='Payment method: ';ru='Способ оплаты: ';de='Zahlungsmethode:'") + TrimAll(vPMRow.PaymentMethod);
			mPaymentSection = NStr("ru = 'Секция: '; en = 'Section: '") + TrimAll(vPMRow.PaymentSection);
			// Set parameters
			vPMArea.Parameters.mPaymentMethod = mPaymentMethod;
			vPMArea.Parameters.mPaymentSection = mPaymentSection;
		Else
			vPMArea = pTemplate.GetArea("TransactionsPaymentMethod");
			// Fill parameters
			mPaymentMethod = NStr("en='Payment method: ';ru='Способ оплаты: ';de='Zahlungsmethode:'") + TrimAll(vPMRow.PaymentMethod);
			// Set parameters
			vPMArea.Parameters.mPaymentMethod = mPaymentMethod;
		EndIf;
		// Put payment method row
		pSpreadsheet.Put(vPMArea);
		
		// Get records for selected currency and payment method
		If pBySections Then
			vTranData = pTranData.FindRows(New Structure("Currency, PaymentMethod, PaymentSection", pCurrency, vPMRow.PaymentMethod, vPMRow.PaymentSection));
		Else
			vTranData = pTranData.FindRows(New Structure("Currency, PaymentMethod", pCurrency, vPMRow.PaymentMethod));
		EndIf;
		
		// Payment method totals
		vPMTotals = 0;
		vPMVATTotals = 0;
		
		// Do for each transaction
		For Each vTranRow In vTranData Do
			// Fill parameters
			dFolio = vTranRow.Folio;
			mFolioNumber = "";
			mRoom = "";
			If ValueIsFilled(dFolio) Then
				mFolioNumber = cmGetDocumentNumberPresentation(dFolio.Number);
				mRoom = TrimAll(dFolio.Room);
			EndIf;
			If ValueIsFilled(dFolio) And Not IsBlankString(dFolio.Description) Then
				mFolioNumber = mFolioNumber + Chars.LF + Left(TrimAll(dFolio.Description), 8); 
			EndIf;
			dDocument = vTranRow.Recorder;
			mDocument = NStr("en='№'; ru='N '; de='Nr.'") + cmGetDocumentNumberPresentation(dDocument.Number) + NStr("en=' of '; ru=' от '; de=' vom '") + Format(dDocument.Date, "DF='dd.MM HH:mm'") + ", " + TrimAll(dDocument.Author);
			// Try to get room rate service as description
			vDocumentServiceDescription = GetDocumentServiceDescription(dDocument);
			If Not IsBlankString(vDocumentServiceDescription) Then
				mDocument = mDocument + Chars.LF + TrimAll(vDocumentServiceDescription);
			EndIf;
			If Not IsBlankString(dDocument.Remarks) Then
				mDocument = mDocument + Chars.LF + TrimAll(dDocument.Remarks);
			EndIf;
			mPaymentSection = ?(ValueIsFilled(vTranRow.PaymentSection), TrimAll(vTranRow.PaymentSection.Code), "");
			dPayer = vTranRow.Payer;
			mPayer = "";
			If ValueIsFilled(dPayer) Then
				If TypeOf(dPayer) = Type("CatalogRef.Clients") Then
					mPayer = dPayer.GetObject().pmGetFullName();
				Else
					mPayer = TrimAll(dPayer);
				EndIf;
			EndIf;
			If ValueIsFilled(dFolio) And ValueIsFilled(dFolio.ParentDoc) Then
				vParentDoc = dFolio.ParentDoc;
				If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Or 
				   TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Then
					vGuest = vParentDoc.Guest;
					If ValueIsFilled(vGuest) Then
						If lower(TrimAll(vGuest.FullName)) <> lower(TrimAll(mPayer)) Then
							mPayer = mPayer + Chars.LF +
							         NStr("en='Guest: '; de='Gast: '; ru='Гость: '") + TrimAll(vGuest.FullName);
						EndIf;
					EndIf;
				EndIf;				
				If ValueIsFilled(dFolio.HotelProduct) Then
					mPayer = TrimAll(mPayer) + ", " + TrimAll(dFolio.HotelProduct.Code);
				Else
					If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Or 
					   TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Then
						If ValueIsFilled(vParentDoc.HotelProduct) Then
							mPayer = TrimAll(mPayer) + ", " + TrimAll(vParentDoc.HotelProduct.Code);
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			// Add invoice and settlements for the customer payments
			If TypeOf(dDocument) = Type("DocumentRef.CustomerPayment") Then
				vParentDoc = dDocument.ParentDoc;
				While ValueIsFilled(vParentDoc) And 
				      (TypeOf(vParentDoc) = Type("DocumentRef.ProformaInvoice") Or 
				       TypeOf(vParentDoc) = Type("DocumentRef.Settlement")) Do
					mPayer = mPayer + Chars.LF + TrimAll(vParentDoc);   
					// Next parent   
					vParentDoc = vParentDoc.ParentDoc;
				EndDo;
			EndIf;
			dCustomer = vTranRow.Customer;
			mCustomer = TrimAll(vTranRow.Customer);
			If ValueIsFilled(vTranRow.Contract) Then
				mCustomer = mCustomer + Chars.LF + TrimAll(vTranRow.Contract);
			EndIf;
			mGuestGroup = TrimAll(vTranRow.GuestGroup);
			If ValueIsFilled(vTranRow.GuestGroup) And Not IsBlankString(vTranRow.GuestGroup.Description) Then
				mGuestGroup = mGuestGroup + Chars.LF + Left(TrimAll(vTranRow.GuestGroup.Description), 8);
			EndIf;
			mSum = Format(vTranRow.Sum, "ND=17; NFD=2");
			mVATSum = Format(vTranRow.VATSum, "ND=17; NFD=2");
			
			vPMTotals = vPMTotals + vTranRow.Sum;
			vPMVATTotals = vPMVATTotals + vTranRow.VATSum;
			
			// Set parameters
			vTranArea.Parameters.dFolio = dFolio;
			vTranArea.Parameters.mFolioNumber = mFolioNumber;
			vTranArea.Parameters.mPaymentSection = mPaymentSection;
			vTranArea.Parameters.dDocument = dDocument;
			vTranArea.Parameters.mDocument = mDocument;
			vTranArea.Parameters.dPayer = dPayer;
			vTranArea.Parameters.mPayer = mPayer;
			vTranArea.Parameters.dCustomer = dCustomer;
			vTranArea.Parameters.mCustomer = mCustomer;
			vTranArea.Parameters.mGuestGroup = mGuestGroup;
			vTranArea.Parameters.mRoom = mRoom;
			vTranArea.Parameters.mSum = mSum;
			If Not Company.DoNotPrintVATAmountsInShiftReports Then
				vTranArea.Parameters.mVATSum = mVATSum;
			EndIf;
		
			// Put transaction row
			pSpreadsheet.Put(vTranArea);
		EndDo;
		
		// Put customer payment method footer
		vFooter = pTemplate.GetArea("TransactionsPaymentMethodFooter");
		vFooter.Parameters.mTotalSum = Format(vPMTotals, "ND=17; NFD=2");
		If Not Company.DoNotPrintVATAmountsInShiftReports Then
			vFooter.Parameters.mTotalVATSum = Format(vPMVATTotals, "ND=17; NFD=2");
		EndIf;
		pSpreadsheet.Put(vFooter);
	EndDo;
EndProcedure // PrintTransactions

// -----------------------------------------------------------------------------
Procedure PrintCashInOuts(pTemplate, pSpreadsheet, pCurrency, pCashInOuts, pIsZReport)
	// Header
	vHeader = pTemplate.GetArea("CashInOutHeader");
	pSpreadsheet.Put(vHeader);
		
	vCIORowArea = pTemplate.GetArea("CashInOutRow");
	
	// Get records for selected currency only
	vCIOData = pCashInOuts.FindRows(New Structure("Currency", pCurrency));
	
	// Do for each payment method
	vCITotals = 0;
	vCOTotals = 0;
	For Each vCIORow In vCIOData Do
		vCIORowArea.Parameters.dDocument = vCIORow.Document;
		vCIORowArea.Parameters.mDocument = TrimAll(vCIORow.Document);
		vCIORowArea.Parameters.mAuthor = TrimAll(vCIORow.Author);
		vCIORowArea.Parameters.mRemarks = TrimAll(vCIORow.Remarks);
		vCIORowArea.Parameters.mIncomeSum = Format(vCIORow.CashInSum, "ND=17; NFD=2");
		vCIORowArea.Parameters.mOutcomeSum = Format(vCIORow.CashOutSum, "ND=17; NFD=2");
		
		vCITotals = vCITotals + vCIORow.CashInSum;
		vCOTotals = vCOTotals + vCIORow.CashOutSum;
	
		// Put transaction row
		pSpreadsheet.Put(vCIORowArea);
	EndDo;
	
	vCIOFooterArea = pTemplate.GetArea("CashInOutFooter");
	vCIOFooterArea.Parameters.mTotalIncomeSum = Format(vCITotals, "ND=17; NFD=2");
	vCIOFooterArea.Parameters.mTotalOutcomeSum = Format(vCOTotals, "ND=17; NFD=2");
	pSpreadsheet.Put(vCIOFooterArea);
EndProcedure // PrintCashInOuts

// -----------------------------------------------------------------------------
Procedure PrintZReportFooter(pTemplate, pSpreadsheet)
	// Print no Z-Report footer with signatures
	vZReportFooter = pTemplate.GetArea("ZReportFooter");
	vZReportFooter.Parameters.mEmployee = TrimAll(Author);
	pSpreadsheet.Put(vZReportFooter);
EndProcedure // PrintZReportFooter

// -----------------------------------------------------------------------------
Function pmGetCashRegisterCorrections()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CashRegisterDailyReceipts.CashRegister,
	|	CashRegisterDailyReceipts.Currency,
	|	CashRegisterDailyReceipts.PaymentSection,
	|	CashRegisterDailyReceipts.PaymentMethod,
	|	CashRegisterDailyReceipts.Customer,
	|	CashRegisterDailyReceipts.Contract,
	|	CashRegisterDailyReceipts.GuestGroup,
	|	CashRegisterDailyReceipts.Payment,
	|	CashRegisterDailyReceipts.VATRate,
	|	CashRegisterDailyReceipts.Sum AS Sum,
	|	CashRegisterDailyReceipts.VATSum,
	|	CashRegisterDailyReceipts.PaymentSum,
	|	CashRegisterDailyReceipts.VATPaymentSum,
	|	CashRegisterDailyReceipts.ReturnSum,
	|	CashRegisterDailyReceipts.VATReturnSum,
	|	CashRegisterDailyReceipts.Payer,
	|	CashRegisterDailyReceipts.Folio
	|FROM
	|	AccumulationRegister.CashRegisterDailyReceipts AS CashRegisterDailyReceipts
	|WHERE
	|	CashRegisterDailyReceipts.Recorder = &qRecorder
	|	AND CashRegisterDailyReceipts.Payment.Date < &qPeriodFrom
	|	AND CashRegisterDailyReceipts.RecordType = &qExpense
	|
	|ORDER BY
	|	CashRegisterDailyReceipts.Payment.PointInTime,
	|	Sum";
	vQry.SetParameter("qRecorder", CloseOfCashRegisterDay);
	vQry.SetParameter("qPeriodFrom", DateFrom);
	vQry.SetParameter("qExpense", AccumulationRecordType.Expense);
	vCorrections = vQry.Execute().Unload();
	Return vCorrections;
EndFunction // pmGetCashRegisterCorrections

// -----------------------------------------------------------------------------
Procedure PrintCorrectionsHeader(pTemplate, pSpreadsheet)
	vCorrHeader = pTemplate.GetArea("CorrectionsHeader");
	
	// Fill parameters
	mCompanyLegacyName = "";
	If ValueIsFilled(Company) Then
		mCompanyLegacyName = TrimAll(Company.LegacyName);
	EndIf;
	mCashRegister = TrimAll(CashRegister);
	mEmployee = TrimAll(Author);
	mDateFrom = Format(DateFrom, "DF='dd.MM.yy HH:mm'");
	mDateTo = Format(DateTo, "DF='dd.MM.yy HH:mm'");
	
	// Set parameters
	vCorrHeader.Parameters.mCompanyLegacyName = mCompanyLegacyName;
	vCorrHeader.Parameters.mCashRegister = mCashRegister;
	vCorrHeader.Parameters.mEmployee = mEmployee;
	vCorrHeader.Parameters.mDateFrom = mDateFrom;
	vCorrHeader.Parameters.mDateTo = mDateTo;
	
	// Put header
	pSpreadsheet.Put(vCorrHeader);
EndProcedure // PrintCorrectionsHeader

// -----------------------------------------------------------------------------
Procedure PrintCorrectionsFooter(pTemplate, pSpreadsheet)
	// Print no Z-Report footer with signatures
	vCorrFooter = pTemplate.GetArea("CorrectionsFooter");
	vCorrFooter.Parameters.mEmployee = TrimAll(Author);
	pSpreadsheet.Put(vCorrFooter);
EndProcedure // PrintCorrectionsFooter

// -----------------------------------------------------------------------------
Procedure PrintCorrections(pTemplate, pSpreadsheet, pCorrections)
	// Do for each correction
	vCurDocument = Undefined;
	For Each vTranRow In pCorrections Do
		// Fill parameters
		mPaymentMethod = TrimAll(vTranRow.PaymentMethod);
		dFolio = vTranRow.Folio;
		mFolioNumber = "";
		mRoom = "";
		If ValueIsFilled(dFolio) Then
			mFolioNumber = cmGetDocumentNumberPresentation(dFolio.Number);
			mRoom = TrimAll(dFolio.Room);
		EndIf;
		If ValueIsFilled(dFolio) And Not IsBlankString(dFolio.Description) Then
			mFolioNumber = mFolioNumber + Chars.LF + Left(TrimAll(dFolio.Description), 8); 
		EndIf;
		dDocument = vTranRow.Payment;
		mDocument = "";
		If vCurDocument <> dDocument Then
			vCurDocument = dDocument;
			mDocument = TrimAll(dDocument) + " - " + mPaymentMethod;
			vTranArea = pTemplate.GetArea("CorrectionRowForDoc");
		Else
			vTranArea = pTemplate.GetArea("CorrectionRow");
		EndIf;
		mPaymentSection = ?(ValueIsFilled(vTranRow.PaymentSection), TrimAll(vTranRow.PaymentSection.Code), "");
		dPayer = vTranRow.Payer;
		mPayer = "";
		If ValueIsFilled(dPayer) Then
			If TypeOf(dPayer) = Type("CatalogRef.Clients") Then
				mPayer = dPayer.GetObject().pmGetFullName();
			Else
				mPayer = TrimAll(dPayer);
			EndIf;
		EndIf;
		If ValueIsFilled(dFolio) And ValueIsFilled(dFolio.ParentDoc) Then
			If ValueIsFilled(dFolio.HotelProduct) Then
				mPayer = TrimAll(mPayer) + ", " + TrimAll(dFolio.HotelProduct.Code);
			Else
				vParentDoc = dFolio.ParentDoc;
				If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Or 
				   TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Then
					If ValueIsFilled(vParentDoc.HotelProduct) Then
						mPayer = TrimAll(mPayer) + ", " + TrimAll(vParentDoc.HotelProduct.Code);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		// Add invoice and settlements for the customer payments
		If TypeOf(dDocument) = Type("DocumentRef.CustomerPayment") Then
			vParentDoc = dDocument.ParentDoc;
			While ValueIsFilled(vParentDoc) And 
				  (TypeOf(vParentDoc) = Type("DocumentRef.ProformaInvoice") Or 
				   TypeOf(vParentDoc) = Type("DocumentRef.Settlement")) Do
				mPayer = mPayer + Chars.LF + TrimAll(vParentDoc);   
				// Next parent   
				vParentDoc = vParentDoc.ParentDoc;
			EndDo;
		EndIf;
		dCustomer = vTranRow.Customer;
		mCustomer = TrimAll(vTranRow.Customer);
		If ValueIsFilled(vTranRow.Contract) Then
			mCustomer = mCustomer + Chars.LF + TrimAll(vTranRow.Contract);
		EndIf;
		mGuestGroup = TrimAll(vTranRow.GuestGroup);
		If ValueIsFilled(vTranRow.GuestGroup) And Not IsBlankString(vTranRow.GuestGroup.Description) Then
			mGuestGroup = mGuestGroup + Chars.LF + Left(TrimAll(vTranRow.GuestGroup.Description), 8);
		EndIf;
		mSum = Format(vTranRow.Sum, "ND=17; NFD=2");
		mVATSum = Format(vTranRow.VATSum, "ND=17; NFD=2");
		
		// Set parameters
		vTranArea.Parameters.dFolio = dFolio;
		vTranArea.Parameters.mFolioNumber = mFolioNumber;
		vTranArea.Parameters.mPaymentSection = mPaymentSection;
		vTranArea.Parameters.dDocument = dDocument;
		vTranArea.Parameters.mDocument = mDocument;
		vTranArea.Parameters.dPayer = dPayer;
		vTranArea.Parameters.mPayer = mPayer;
		vTranArea.Parameters.dCustomer = dCustomer;
		vTranArea.Parameters.mCustomer = mCustomer;
		vTranArea.Parameters.mGuestGroup = mGuestGroup;
		vTranArea.Parameters.mRoom = mRoom;
		vTranArea.Parameters.mSum = mSum;
		If Not Company.DoNotPrintVATAmountsInShiftReports Then
			vTranArea.Parameters.mVATSum = mVATSum;
		EndIf;
	
		// Put correction row
		pSpreadsheet.Put(vTranArea);
	EndDo;
EndProcedure // PrintCorrections

#EndRegion
