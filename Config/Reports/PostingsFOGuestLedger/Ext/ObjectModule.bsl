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
	If Not ValueIsFilled(PeriodTo) Then
		PeriodTo = EndOfDay(CurrentSessionDate());
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If ValueIsFilled(PeriodTo) Then
		vParamPresentation = vParamPresentation + NStr("ru = 'Дата '; en = 'Date '; de = 'Datum '") + 
		                     Format(PeriodTo, "DF='dd.MM.yyyy'") + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("en='Period is wrong!';ru='Неправильно задан период!';de='Der Zeitraum wurde falsch eingetragen!'") + 
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(Customer) Then
		If Not Customer.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Customer ';ru='Контрагент ';de='Firma '") + 
			                     TrimAll(Customer) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Customers folder ';ru='Папка контрагентов ';de='Firmen Ordner '") + 
			                     TrimAll(Customer) + 
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
	ReportBuilder.Parameters.Insert("qPeriodTo", EndOfDay(PeriodTo));
	ReportBuilder.Parameters.Insert("qCustomer", Customer);
	ReportBuilder.Parameters.Insert("qCustomerIsEmpty", Not ValueIsFilled(Customer));
	ReportBuilder.Parameters.Insert("qGuestLedger", ChartsOfAccounts.ChartOfAccountsFO.GuestLedger);
	ReportBuilder.Parameters.Insert("qPart1ExtrasForTOCustomers", NStr("en='Part I:  Extras accounts balances for T.O. customers'; ru='Часть I: остатки на счетах доп. услуг клиентов TО'; de='Teil I: Extras-Konten-Salden für T.O. Kunden'"));
	ReportBuilder.Parameters.Insert("qPart2IndividualAndComplimentaryClients", NStr("en='Part II: Individual and Complimentary clients balances'; ru='Часть II: Балансы индивидуальных и бесплатных клиентов'; de='Teil II: Individuelle und Kostenlose kunden bilanzen'"));
	ReportBuilder.Parameters.Insert("qPart3AccommodationForCreditCustomers", NStr("en='Part III: Accommodation for Credit customers'; ru='Часть III: Размещение клиентов от контрагентов'; de='Teil III: Unterkunft für Kreditkunden'"));
	ReportBuilder.Parameters.Insert("qPart4ExternalAccounts", NStr("en='Part IV:  External Accounts balances'; ru='Часть IV: Остатки по финансовым счетам и счетам сторонних посетителей'; de='Teil IV: Salden der Außenkonten'"));
	
	// Execute report builder query
	ReportBuilder.Execute();
	
	// Apply appearance settings to the report template
	vTemplateAttributes = cmApplyReportTemplateAppearance(ThisObject);
	
	// Output report to the spreadsheet
	ReportBuilder.Put(pSpreadsheet);
	//ReportBuilder.Template.Show(); // For debug purpose

	// Apply appearance settings to the report spreadsheet
	cmApplyReportAppearance(ThisObject, pSpreadsheet, vTemplateAttributes);
EndProcedure // pmGenerate
	
// -----------------------------------------------------------------------------
Procedure pmInitializeReportBuilder() Export
	ReportBuilder = New ReportBuilder();
	
	// Initialize default query text
	QueryText = 
	"SELECT
	|	&qPart1ExtrasForTOCustomers AS DataGroup,
	|	NULL AS AccommodationFolio,
	|	Part1ExtrasForTOCustomers.ExtDimension1 AS ExtrasFolio,
	|	Part1ExtrasForTOCustomers.ExtDimension1.ParentDoc AS ParentDoc,
	|	Part1ExtrasForTOCustomers.ExtDimension1.Client AS Client,
	|	Part1ExtrasForTOCustomers.ExtDimension1.ParentDoc.Customer AS Customer,
	|	Part1ExtrasForTOCustomers.ExtDimension1.ParentDoc.Contract AS Contract,
	|	Part1ExtrasForTOCustomers.ExtDimension1.ParentDoc.GuestGroup AS GuestGroup,
	|	Part1ExtrasForTOCustomers.ExtDimension1.ParentDoc.Room AS Room,
	|	Part1ExtrasForTOCustomers.ExtDimension1.DateTimeFrom AS DateTimeFrom,
	|	Part1ExtrasForTOCustomers.ExtDimension1.DateTimeTo AS DateTimeTo,
	|	Part1ExtrasForTOCustomers.Hotel AS Hotel,
	|	Part1ExtrasForTOCustomers.Company AS Company,
	|	0 AS AccommodationAmount,
	|	Part1ExtrasForTOCustomers.AmountBalance AS ExtrasAmount
	|INTO Part1
	|FROM
	|	AccountingRegister.PostingsFO.Balance(
	|			&qPeriodTo,
	|			Account = &qGuestLedger,
	|			,
	|			(&qCustomerIsEmpty
	|				OR NOT &qCustomerIsEmpty
	|					AND ExtDimension1.ParentDoc.Customer <> NULL
	|					AND ExtDimension1.ParentDoc.Customer <> VALUE(Catalog.Customers.EmptyRef)
	|					AND ExtDimension1.ParentDoc.Customer IN HIERARCHY (&qCustomer))
	|				AND Hotel IN HIERARCHY (&qHotel)
	|				AND ExtDimension1.ParentDoc <> UNDEFINED
	|				AND NOT ISNULL(ExtDimension1.ParentDoc.Customer.IsIndividual, TRUE)
	|				AND ISNULL(ExtDimension1.Customer.IsIndividual, TRUE)) AS Part1ExtrasForTOCustomers
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&qPart2IndividualAndComplimentaryClients AS DataGroup,
	|	CASE
	|		WHEN NOT Part2IndividualAndComplimentaryClients.ExtDimension1.Description LIKE ""%"" + Part2IndividualAndComplimentaryClients.Hotel.AdditionalServicesFolioCondition + ""%""
	|			THEN Part2IndividualAndComplimentaryClients.ExtDimension1
	|		ELSE NULL
	|	END AS AccommodationFolio,
	|	CASE
	|		WHEN Part2IndividualAndComplimentaryClients.ExtDimension1.Description LIKE ""%"" + Part2IndividualAndComplimentaryClients.Hotel.AdditionalServicesFolioCondition + ""%""
	|			THEN Part2IndividualAndComplimentaryClients.ExtDimension1
	|		ELSE NULL
	|	END AS ExtrasFolio,
	|	Part2IndividualAndComplimentaryClients.ExtDimension1.ParentDoc AS ParentDoc,
	|	Part2IndividualAndComplimentaryClients.ExtDimension1.Client AS Client,
	|	Part2IndividualAndComplimentaryClients.ExtDimension1.ParentDoc.Customer AS Customer,
	|	Part2IndividualAndComplimentaryClients.ExtDimension1.ParentDoc.Contract AS Contract,
	|	Part2IndividualAndComplimentaryClients.ExtDimension1.ParentDoc.GuestGroup AS GuestGroup,
	|	Part2IndividualAndComplimentaryClients.ExtDimension1.ParentDoc.Room AS Room,
	|	Part2IndividualAndComplimentaryClients.ExtDimension1.DateTimeFrom AS DateTimeFrom,
	|	Part2IndividualAndComplimentaryClients.ExtDimension1.DateTimeTo AS DateTimeTo,
	|	Part2IndividualAndComplimentaryClients.Hotel AS Hotel,
	|	Part2IndividualAndComplimentaryClients.Company AS Company,
	|	CASE
	|		WHEN NOT Part2IndividualAndComplimentaryClients.ExtDimension1.Description LIKE ""%"" + Part2IndividualAndComplimentaryClients.Hotel.AdditionalServicesFolioCondition + ""%""
	|			THEN Part2IndividualAndComplimentaryClients.AmountBalance
	|		ELSE 0
	|	END AS AccommodationAmount,
	|	CASE
	|		WHEN Part2IndividualAndComplimentaryClients.ExtDimension1.Description LIKE ""%"" + Part2IndividualAndComplimentaryClients.Hotel.AdditionalServicesFolioCondition + ""%""
	|			THEN Part2IndividualAndComplimentaryClients.AmountBalance
	|		ELSE 0
	|	END AS ExtrasAmount
	|INTO Part2
	|FROM
	|	AccountingRegister.PostingsFO.Balance(
	|			&qPeriodTo,
	|			Account = &qGuestLedger,
	|			,
	|			(&qCustomerIsEmpty
	|				OR NOT &qCustomerIsEmpty
	|					AND ExtDimension1.ParentDoc.Customer <> NULL
	|					AND ExtDimension1.ParentDoc.Customer <> VALUE(Catalog.Customers.EmptyRef)
	|					AND ExtDimension1.ParentDoc.Customer IN HIERARCHY (&qCustomer))
	|				AND Hotel IN HIERARCHY (&qHotel)
	|				AND ExtDimension1.ParentDoc <> UNDEFINED
	|				AND ISNULL(ExtDimension1.ParentDoc.Customer.IsIndividual, TRUE)
	|				AND ISNULL(ExtDimension1.Customer.IsIndividual, TRUE)) AS Part2IndividualAndComplimentaryClients
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&qPart3AccommodationForCreditCustomers AS DataGroup,
	|	Part3AccommodationForCreditCustomers.ExtDimension1 AS AccommodationFolio,
	|	NULL AS ExtrasFolio,
	|	Part3AccommodationForCreditCustomers.ExtDimension1.ParentDoc AS ParentDoc,
	|	Part3AccommodationForCreditCustomers.ExtDimension1.Client AS Client,
	|	Part3AccommodationForCreditCustomers.ExtDimension1.ParentDoc.Customer AS Customer,
	|	Part3AccommodationForCreditCustomers.ExtDimension1.ParentDoc.Contract AS Contract,
	|	Part3AccommodationForCreditCustomers.ExtDimension1.ParentDoc.GuestGroup AS GuestGroup,
	|	Part3AccommodationForCreditCustomers.ExtDimension1.ParentDoc.Room AS Room,
	|	Part3AccommodationForCreditCustomers.ExtDimension1.DateTimeFrom AS DateTimeFrom,
	|	Part3AccommodationForCreditCustomers.ExtDimension1.DateTimeTo AS DateTimeTo,
	|	Part3AccommodationForCreditCustomers.Hotel AS Hotel,
	|	Part3AccommodationForCreditCustomers.Company AS Company,
	|	Part3AccommodationForCreditCustomers.AmountBalance AS AccommodationAmount,
	|	0 AS ExtrasAmount
	|INTO Part3
	|FROM
	|	AccountingRegister.PostingsFO.Balance(
	|			&qPeriodTo,
	|			Account = &qGuestLedger,
	|			,
	|			(&qCustomerIsEmpty
	|				OR NOT &qCustomerIsEmpty
	|					AND ExtDimension1.ParentDoc.Customer <> NULL
	|					AND ExtDimension1.ParentDoc.Customer <> VALUE(Catalog.Customers.EmptyRef)
	|					AND ExtDimension1.ParentDoc.Customer IN HIERARCHY (&qCustomer))
	|				AND Hotel IN HIERARCHY (&qHotel)
	|				AND ExtDimension1.ParentDoc <> UNDEFINED
	|				AND NOT ISNULL(ExtDimension1.ParentDoc.Customer.IsIndividual, TRUE)
	|				AND NOT ISNULL(ExtDimension1.Customer.IsIndividual, TRUE)) AS Part3AccommodationForCreditCustomers
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&qPart4ExternalAccounts AS DataGroup,
	|	NULL AS AccommodationFolio,
	|	Part4ExternalAccounts.ExtDimension1 AS ExtrasFolio,
	|	NULL AS ParentDoc,
	|	Part4ExternalAccounts.ExtDimension1.Client AS Client,
	|	Part4ExternalAccounts.ExtDimension1.Customer AS Customer,
	|	Part4ExternalAccounts.ExtDimension1.Contract AS Contract,
	|	Part4ExternalAccounts.ExtDimension1.GuestGroup AS GuestGroup,
	|	Part4ExternalAccounts.ExtDimension1.Room AS Room,
	|	Part4ExternalAccounts.ExtDimension1.DateTimeFrom AS DateTimeFrom,
	|	Part4ExternalAccounts.ExtDimension1.DateTimeTo AS DateTimeTo,
	|	Part4ExternalAccounts.Hotel AS Hotel,
	|	Part4ExternalAccounts.Company AS Company,
	|	0 AS AccommodationAmount,
	|	Part4ExternalAccounts.AmountBalance AS ExtrasAmount
	|INTO Part4
	|FROM
	|	AccountingRegister.PostingsFO.Balance(
	|			&qPeriodTo,
	|			Account = &qGuestLedger,
	|			,
	|			(&qCustomerIsEmpty
	|				OR NOT &qCustomerIsEmpty
	|					AND ExtDimension1.Customer <> NULL
	|					AND ExtDimension1.Customer <> VALUE(Catalog.Customers.EmptyRef)
	|					AND ExtDimension1.Customer IN HIERARCHY (&qCustomer))
	|				AND Hotel IN HIERARCHY (&qHotel)
	|				AND ExtDimension1.ParentDoc = UNDEFINED) AS Part4ExternalAccounts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GuestLedgerBalances.DataGroup AS DataGroup,
	|	GuestLedgerBalances.Room AS Room,
	|	GuestLedgerBalances.Customer AS Customer,
	|	GuestLedgerBalances.AccommodationFolio AS AccommodationFolio,
	|	GuestLedgerBalances.ExtrasFolio AS ExtrasFolio,
	|	GuestLedgerBalances.Client AS Client,
	|	GuestLedgerBalances.DateTimeFrom AS DateTimeFrom,
	|	GuestLedgerBalances.DateTimeTo AS DateTimeTo,
	|	GuestLedgerBalances.AccommodationAmount AS AccommodationAmount,
	|	GuestLedgerBalances.ExtrasAmount AS ExtrasAmount
	|{SELECT
	|	DataGroup AS DataGroup,
	|	Room.* AS Room,
	|	Customer.* AS Customer,
	|	AccommodationFolio.* AS AccommodationFolio,
	|	ExtrasFolio.* AS ExtrasFolio,
	|	Client.* AS Client,
	|	GuestLedgerBalances.Contract.* AS Contract,
	|	GuestLedgerBalances.GuestGroup.* AS GuestGroup,
	|	GuestLedgerBalances.ParentDoc.* AS ParentDoc,
	|	DateTimeFrom AS DateTimeFrom,
	|	DateTimeTo AS DateTimeTo,
	|	GuestLedgerBalances.Hotel.* AS Hotel,
	|	GuestLedgerBalances.Company.* AS Company,
	|	AccommodationAmount AS AccommodationAmount,
	|	ExtrasAmount AS ExtrasAmount}
	|FROM
	|	(SELECT
	|		Part1.DataGroup AS DataGroup,
	|		Part1.AccommodationFolio AS AccommodationFolio,
	|		Part1.ExtrasFolio AS ExtrasFolio,
	|		Part1.ParentDoc AS ParentDoc,
	|		Part1.Client AS Client,
	|		Part1.Customer AS Customer,
	|		Part1.Contract AS Contract,
	|		Part1.GuestGroup AS GuestGroup,
	|		Part1.Room AS Room,
	|		Part1.DateTimeFrom AS DateTimeFrom,
	|		Part1.DateTimeTo AS DateTimeTo,
	|		Part1.Hotel AS Hotel,
	|		Part1.Company AS Company,
	|		Part1.AccommodationAmount AS AccommodationAmount,
	|		Part1.ExtrasAmount AS ExtrasAmount
	|	FROM
	|		Part1 AS Part1
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Part2.DataGroup,
	|		Part2.AccommodationFolio,
	|		Part2.ExtrasFolio,
	|		Part2.ParentDoc,
	|		Part2.Client,
	|		Part2.Customer,
	|		Part2.Contract,
	|		Part2.GuestGroup,
	|		Part2.Room,
	|		Part2.DateTimeFrom,
	|		Part2.DateTimeTo,
	|		Part2.Hotel,
	|		Part2.Company,
	|		Part2.AccommodationAmount,
	|		Part2.ExtrasAmount
	|	FROM
	|		Part2 AS Part2
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Part3.DataGroup,
	|		Part3.AccommodationFolio,
	|		Part3.ExtrasFolio,
	|		Part3.ParentDoc,
	|		Part3.Client,
	|		Part3.Customer,
	|		Part3.Contract,
	|		Part3.GuestGroup,
	|		Part3.Room,
	|		Part3.DateTimeFrom,
	|		Part3.DateTimeTo,
	|		Part3.Hotel,
	|		Part3.Company,
	|		Part3.AccommodationAmount,
	|		Part3.ExtrasAmount
	|	FROM
	|		Part3 AS Part3
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Part4.DataGroup,
	|		Part4.AccommodationFolio,
	|		Part4.ExtrasFolio,
	|		Part4.ParentDoc,
	|		Part4.Client,
	|		Part4.Customer,
	|		Part4.Contract,
	|		Part4.GuestGroup,
	|		Part4.Room,
	|		Part4.DateTimeFrom,
	|		Part4.DateTimeTo,
	|		Part4.Hotel,
	|		Part4.Company,
	|		Part4.AccommodationAmount,
	|		Part4.ExtrasAmount
	|	FROM
	|		Part4 AS Part4) AS GuestLedgerBalances
	|{WHERE
	|	GuestLedgerBalances.DataGroup AS DataGroup,
	|	GuestLedgerBalances.Room.* AS Room,
	|	GuestLedgerBalances.Customer.* AS Customer,
	|	GuestLedgerBalances.AccommodationFolio.* AS AccommodationFolio,
	|	GuestLedgerBalances.ExtrasFolio.* AS ExtrasFolio,
	|	GuestLedgerBalances.Client.* AS Client,
	|	GuestLedgerBalances.Contract.* AS Contract,
	|	GuestLedgerBalances.GuestGroup.* AS GuestGroup,
	|	GuestLedgerBalances.ParentDoc.* AS ParentDoc,
	|	GuestLedgerBalances.DateTimeFrom AS DateTimeFrom,
	|	GuestLedgerBalances.DateTimeTo AS DateTimeTo,
	|	GuestLedgerBalances.AccommodationAmount AS AccommodationAmount,
	|	GuestLedgerBalances.ExtrasAmount AS ExtrasAmount}
	|
	|ORDER BY
	|	GuestLedgerBalances.AccommodationFolio,
	|	GuestLedgerBalances.ExtrasFolio
	|{ORDER BY
	|	DataGroup AS DataGroup,
	|	Room.* AS Room,
	|	Customer.* AS Customer,
	|	AccommodationFolio.* AS AccommodationFolio,
	|	ExtrasFolio.* AS ExtrasFolio,
	|	Client.* AS Client,
	|	GuestLedgerBalances.Contract.* AS Contract,
	|	GuestLedgerBalances.GuestGroup.* AS GuestGroup,
	|	GuestLedgerBalances.ParentDoc.* AS ParentDoc,
	|	DateTimeFrom AS DateTimeFrom,
	|	DateTimeTo AS DateTimeTo,
	|	GuestLedgerBalances.Hotel.* AS Hotel,
	|	GuestLedgerBalances.Company.* AS Company,
	|	AccommodationAmount AS AccommodationAmount,
	|	ExtrasAmount AS ExtrasAmount}
	|TOTALS
	|	SUM(AccommodationAmount),
	|	SUM(ExtrasAmount)
	|BY
	|	OVERALL
	|{TOTALS BY
	|	DataGroup AS DataGroup,
	|	Room.* AS Room,
	|	Customer.* AS Customer,
	|	AccommodationFolio.* AS AccommodationFolio,
	|	ExtrasFolio.* AS ExtrasFolio,
	|	Client.* AS Client,
	|	GuestLedgerBalances.Contract.* AS Contract,
	|	GuestLedgerBalances.GuestGroup.* AS GuestGroup,
	|	GuestLedgerBalances.ParentDoc.* AS ParentDoc,
	|	GuestLedgerBalances.Hotel.* AS Hotel,
	|	GuestLedgerBalances.Company.* AS Company}";
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("en='Guest Ledger balances'; ru='Балансы по счету Guest Ledger'; de='Gästebuch Salden'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

// -----------------------------------------------------------------------------
// Reports framework end
// -----------------------------------------------------------------------------
