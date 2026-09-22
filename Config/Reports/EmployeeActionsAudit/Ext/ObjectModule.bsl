
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
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(PeriodFrom) Then
		PeriodFrom = BegOfDay(CurrentSessionDate());
	EndIf;
	If Not ValueIsFilled(PeriodTo) Then
		PeriodTo = EndOfDay(PeriodFrom);
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetReportParametersPresentation() Export
	vParamPresentation = "";
	If ValueIsFilled(PeriodFrom) And Not ValueIsFilled(PeriodTo) Then
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
		vParamPresentation = vParamPresentation + NStr("ru = 'Период '; en = 'Period '; de = 'Periode '") + PeriodPresentation(PeriodFrom, PeriodTo, cmLocalizationCode()) + 
		                     ";" + Chars.LF;
	Else
		vParamPresentation = vParamPresentation + NStr("en='Period is wrong!';ru='Неправильно задан период!';de='Der Zeitraum wurde falsch eingetragen!'") + 
		                     ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(Employee) Then
		If Not Employee.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Employee ';ru='Сотрудник ';de='Mitarbeiter '") + 
			                     TrimAll(Employee.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа сотрудников '; en = 'Employees folder '; de = 'Mitarbeiteren folder '") + 
			                     TrimAll(Employee.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(Department) Then
		If Not Department.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("ru = 'Отдел '; en = 'Department '; de = 'Abteilung '") + 
			                     TrimAll(Department.Description) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("ru = 'Группа отделов '; en = 'Departments folder '; de = 'Abteilungen folder '") + 
			                     TrimAll(Department.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;							 
	If ValueIsFilled(Hotel) Then
		If Not Hotel.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Hotel ';ru='Гостиница ';de='Hotel '") + 
			                     Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage) + 
			                     ";" + Chars.LF;
		Else
			vParamPresentation = vParamPresentation + NStr("en='Hotels folder ';ru='Группа гостиниц ';de='Gruppe Hotels '") + 
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
	ReportBuilder.Parameters.Insert("qPeriodFrom", PeriodFrom);
	ReportBuilder.Parameters.Insert("qPeriodTo", ?(ValueIsFilled(PeriodTo), PeriodTo, '39991231235959'));
	ReportBuilder.Parameters.Insert("qHotel", Hotel);
	ReportBuilder.Parameters.Insert("qIsEmptyHotel", Not ValueIsFilled(Hotel));
	ReportBuilder.Parameters.Insert("qEmployee", Employee);
	ReportBuilder.Parameters.Insert("qIsEmptyEmployee", Not ValueIsFilled(Employee));
	ReportBuilder.Parameters.Insert("qDepartment", Department);
	ReportBuilder.Parameters.Insert("qIsEmptyDepartment", Not ValueIsFilled(Department));
	ReportBuilder.Parameters.Insert("qReservationType", NStr("en='Reservation'; ru='Бронирование'; de='Reservierung'"));
	ReportBuilder.Parameters.Insert("qResourceReservationType", NStr("en='Resource reservation'; ru='Бронирование ресурсов'; de='Ressource reservierung'"));
	ReportBuilder.Parameters.Insert("qAccommodationType", NStr("en='Accommodation'; ru='Размещения'; de='Unterkunft'"));
	ReportBuilder.Parameters.Insert("qForeignerRegistryRecordType", NStr("en='Foreigner registry record'; ru='Записи в журнал регистрации иностранцев'; de='Anmeldung für Ausländer'"));
	ReportBuilder.Parameters.Insert("qSetPriceTagRangesType", NStr("en='Set price tag ranges'; ru='Приказы об изменении диапазонов признаков цены'; de='Befehl zur Bearbeitung der Spannweite der Preiseigenschaften'"));
	ReportBuilder.Parameters.Insert("qSetRoomRatePricesType", NStr("en='Set room rate prices'; ru='Приказы об изменении цен тарифа'; de='Befehl zur Bearbeitung der Tarifpreise'"));
	ReportBuilder.Parameters.Insert("qClientType", NStr("en='Clients'; ru='Клиенты'; de='Kunden'"));
	ReportBuilder.Parameters.Insert("qCustomerType", NStr("en='Customers'; ru='Контрагенты'; de='Firmen'"));
	ReportBuilder.Parameters.Insert("qContractType", NStr("en='Contracts'; ru='Договоры'; de='Verträge'"));
	ReportBuilder.Parameters.Insert("qRoomStatusChangeType", NStr("en='Room status changes'; ru='Изменения статусов номеров'; de='Änderung des Status der Zimmer'"));
	ReportBuilder.Parameters.Insert("qSafetySystemEventsType", NStr("en='Safety system events'; ru='События системы безопасности'; de='Sicherheit Events'"));
	ReportBuilder.Parameters.Insert("qChargesType", NStr("en='Extra charges'; ru='Начисления'; de='Anrechnungen'"));
	ReportBuilder.Parameters.Insert("qStornoType", NStr("en='Storno'; ru='Отмены начислений'; de='Storno'"));
	ReportBuilder.Parameters.Insert("qChargeTransfersType", NStr("en='Charge transfers'; ru='Переносы начислений'; de='Verschiebung der Anrechnungen'"));
	ReportBuilder.Parameters.Insert("qPaymentsType", NStr("en='Payments'; ru='Платежи'; de='Zahlungen'"));
	ReportBuilder.Parameters.Insert("qPaymentAnnulationsType", NStr("en='Payment annulations'; ru='Аннуляции платежей'; de='Zahlungen Storno'"));
	ReportBuilder.Parameters.Insert("qPreauthorisationsType", NStr("en='Preauthorisations'; ru='Преавторизации'; de='Vorautorisierungen'"));
	ReportBuilder.Parameters.Insert("qPreauthorisationAnnulationsType", NStr("en='Preauthorisation annulations'; ru='Отмены преавторизаций'; de='Vorautorisierungen Storno'"));
	ReportBuilder.Parameters.Insert("qReturnsType", NStr("en='Returns'; ru='Возвраты'; de='Rückgaben'"));
	ReportBuilder.Parameters.Insert("qDepositTransfersType", NStr("en='Deposit transfers'; ru='Переносы денег'; de='Verschiebung des Deposits'"));
	ReportBuilder.Parameters.Insert("qCustomerPaymentsType", NStr("en='Customer payments'; ru='Платежи контрагентов'; de='Zahlungen vom Firmen'"));
	ReportBuilder.Parameters.Insert("qCustomerPaymentAnnulationsType", NStr("en='Customer payment annulations'; ru='Аннуляции платежей контрагентов'; de='Zahlungen vom Firmen Storno'"));
	ReportBuilder.Parameters.Insert("qCustomerAdvanceDistributionsType", NStr("en='Customer advance distributions'; ru='Распределение авансов контрагентов'; de='Verrechnung des Vorschusses'"));
	ReportBuilder.Parameters.Insert("qSettlementsType", NStr("en='Invoices'; ru='Акты'; de='Rechnungen'"));
	ReportBuilder.Parameters.Insert("qInvoicesType", NStr("en='Pro-forma invoices'; ru='Счета на оплату'; de='Pro-Forma Rechnungen'"));
	ReportBuilder.Parameters.Insert("qCashIncomesType", NStr("en='Cash incomes'; ru='Внесения наличных в ККМ'; de='Bareinzahlung'"));
	ReportBuilder.Parameters.Insert("qCashOutcomesType", NStr("en='Cash outcomes'; ru='Инкассация наличных из ККМ'; de='Inkasso'"));
	ReportBuilder.Parameters.Insert("qClientDataScansType", NStr("en='Client data scans'; ru='Сканирование данных клиентов'; de='Scans mit Daten vom Kunden'"));
	ReportBuilder.Parameters.Insert("qCloseOfCashRegisterDayType", NStr("en='Close of cash register days'; ru='Закрытия кассовых смен'; de='Schließen der Kassenschichten'"));
	ReportBuilder.Parameters.Insert("qInputAccumulatingDiscountBalancesType", NStr("en='Input accumulating discount balances'; ru='Внесение балансов по накопительным скидкам'; de='Eingabe von Anfangsbeständen aus summarischen Preisnachlässen'"));
	ReportBuilder.Parameters.Insert("qRoomInterfaceStatusType", NStr("en='Room interface events'; ru='Управление оборудованием в номерах'; de='Status der zusätzlichen Dienstleistung pro Zimmer'"));
	ReportBuilder.Parameters.Insert("qServiceRegistrationType", NStr("en='Service registrations'; ru='Регистрация фактически оказанных услуг'; de='Registrierung tatsächlich erbrachten Leistungen'"));
	ReportBuilder.Parameters.Insert("qSetRoomBlockType", NStr("en='Set room blocks'; ru='Установка блокировок номеров'; de='Zimmer Blockierung einrichten'"));
	ReportBuilder.Parameters.Insert("qSetRoomQuotaType", NStr("en='Room allotements change'; ru='Изменение квот номеров'; de='Zimmer allotements Wechsel'"));
	ReportBuilder.Parameters.Insert("qIssueHotelProductsType", NStr("en='Issue hotel products'; ru='Отгрузка бланков путевок'; de='Verschicken von Reiseschecks'"));
	ReportBuilder.Parameters.Insert("qSMSDeliveryType", NStr("en='SMS delivery'; ru='Рассылка СМС'; de='SMS-Nachrichten Senden'"));

	// Execute report builder query
	ReportBuilder.Execute();
	
	// Apply appearance settings to the report template
	vTemplateAttributes = cmApplyReportTemplateAppearance(ThisObject);
	
	// Output report to the spreadsheet
	Try
		ReportBuilder.Put(pSpreadsheet);
	Except
		tcCommonFunctionOnClientServer.TextMessage(cmGetRootErrorDescription(ErrorInfo()), MessageStatus.Attention);
	EndTry;
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
	|	Actions.Period AS Period,
	|	Actions.Employee AS Employee,
	|	Actions.Remarks AS Remarks,
	|	1 AS Count,
	|	Actions.Hotel AS Hotel,
	|	Actions.AccountingDate AS AccountingDate,
	|	Actions.Department AS Department,
	|	Actions.Object AS Object,
	|	Actions.Service AS Service,
	|	Actions.CashRegister AS CashRegister,
	|	Actions.GuestGroup AS GuestGroup,
	|	Actions.Guest AS Guest,
	|	Actions.Room AS Room,
	|	Actions.Folio AS Folio
	|{SELECT
	|	Actions.Hotel.* AS Hotel,
	|	Period AS Period,
	|	Actions.AccountingDate AS AccountingDate,
	|	Employee.* AS Employee,
	|	Actions.Department.* AS Department,
	|	Remarks AS Remarks,
	|	Count AS Count,
	|	Object.*}
	|FROM
	|	(SELECT
	|		UserActionsHistory.Hotel AS Hotel,
	|		UserActionsHistory.Period AS Period,
	|		BEGINOFPERIOD(UserActionsHistory.Period, DAY) AS AccountingDate,
	|		UserActionsHistory.User AS Employee,
	|		UserActionsHistory.User.Department AS Department,
	|		UserActionsHistory.Changes AS Remarks,
	|		UserActionsHistory.Object AS Object,
	|		UserActionsHistory.Object.Service AS Service,
	|		UserActionsHistory.Object.CashRegister AS CashRegister,
	|		UserActionsHistory.Object.GuestGroup AS GuestGroup,
	|		UserActionsHistory.Object.Guest AS Guest,
	|		UserActionsHistory.Object.Room AS Room,
	|		UserActionsHistory.Object.Folio AS Folio
	|	FROM
	|		InformationRegister.UserActionsHistory AS UserActionsHistory
	|	WHERE
	|		(UserActionsHistory.User IN HIERARCHY (&qEmployee)
	|					AND NOT &qIsEmptyEmployee
	|				OR &qIsEmptyEmployee)
	|		AND (UserActionsHistory.User.Department IN HIERARCHY (&qDepartment)
	|					AND NOT &qIsEmptyDepartment
	|				OR &qIsEmptyDepartment)
	|		AND (UserActionsHistory.Hotel IN HIERARCHY (&qHotel)
	|					AND NOT &qIsEmptyHotel
	|				OR &qIsEmptyHotel)
	|		AND UserActionsHistory.Period >= &qPeriodFrom
	|		AND UserActionsHistory.Period <= &qPeriodTo) AS Actions
	|{WHERE
	|	Actions.Hotel.* AS Hotel,
	|	Actions.Period AS Period,
	|	Actions.AccountingDate AS AccountingDate,
	|	Actions.Employee.* AS Employee,
	|	Actions.Department.* AS Department,
	|	Actions.Remarks AS Remarks}
	|
	|ORDER BY
	|	Period
	|{ORDER BY
	|	Actions.Hotel.* AS Hotel,
	|	Period AS Period,
	|	Actions.AccountingDate AS AccountingDate,
	|	Employee.* AS Employee,
	|	Actions.Department.* AS Department,
	|	Remarks AS Remarks}
	|TOTALS
	|	SUM(Count)
	|BY
	|	OVERALL
	|{TOTALS BY
	|	Actions.Hotel.* AS Hotel,
	|	Period AS Period,
	|	Actions.AccountingDate AS AccountingDate,
	|	Employee.* AS Employee,
	|	Actions.Department.* AS Department,
	|	Object.*}";
	
	
	ReportBuilder.Text = QueryText;
	ReportBuilder.FillSettings();
	
	// Initialize report builder with default query
	vRB = New ReportBuilder(QueryText);
	vRBSettings = vRB.GetSettings(True, True, True, True, True);
	ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
	
	// Set default report builder header text
	ReportBuilder.HeaderText = NStr("en = 'Employee actions audit'; de = 'Mitarbeiter Aktionen Prüfungs'; ru = 'Аудит действий сотрудников'");
	
	// Fill report builder fields presentations from the report template
	cmFillReportAttributesPresentations(ThisObject);
	
	// Reset report builder template
	ReportBuilder.Template = Undefined;
EndProcedure // pmInitializeReportBuilder

#EndRegion
