
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Object.Ref.IsEmpty() Then
		Object.IsActive = True;
	EndIf;
	ClearExternalTemplate = False;
	TypeDescription = cmGetObjectTypeDescription(Object.ObjectType);
	Items.ObjectType.AvailableTypes = cmGetObjectsTypeDescription();
	Items.ObjectType.TypeDomainEnabled = False;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	If ClearExternalTemplate Then
		pCurrentObject.ExternalTemplate = Undefined;
	ElsIf ValueIsFilled(FileTempStorage) Then
		vFileBinaryData = GetFromTempStorage(FileTempStorage);
		pCurrentObject.ExternalTemplate = New ValueStorage(vFileBinaryData);
	EndIf;
EndProcedure // BeforeWriteAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	ClearExternalTemplate = False;
	FileTempStorage = "";
EndProcedure // AfterWriteAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ObjectTypeOnChange(pItem)
	Object.ObjectType = TypeDescription.AdjustValue();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ParameterStartChoice(Item, ChoiceData, StandardProcessing)
	vParameter = Object.Parameter;
	vListItems = New ValueList();
	If TypeOf(Object.ObjectType) = Type("DocumentRef.Reservation") Then
		vListItems.Add("ALL", NStr("en='ALL - Hide all reservation services into the room price'; ru='ALL - Прятать все услуги брони в стоимость проживания'; de='ALL - Verbergen alle Reservierungsdienste in den Zimmerpreis'"), ?(StrFind(vParameter, "ALL") > 0, True, False));
		vListItems.Add("DETAILED", NStr("en='DETAILED - Print all in-price services separately'; ru='DETAILED - Печатать все услуги из тарифа отдельными строками'; de='DETAILED - Drucken alle Leistungen des Tarifs in getrennten Leitungen'"), ?(StrFind(vParameter, "DETAILED") > 0, True, False));
		vListItems.Add("NO_ROOM", NStr("en='NO_ROOM - Do not print room name in the confirmation form'; ru='NO_ROOM - Не печатать в подтверждении брони номер комнаты'; de='NO_ROOM - Auf Ihrer Buchungsbestätigung der Zimmer nicht drucken'"), ?(StrFind(vParameter, "NO_ROOM") > 0, True, False));
		vListItems.Add("SHOW_AGENT_COMMISSION_PERCENT", NStr("en='SHOW_AGENT_COMMISSION_PERCENT - Show agent commission percent in reservation confirmation form'; ru='SHOW_AGENT_COMMISSION_PERCENT - Показывать агентский процент комиссии в форме подтверждения брони'; de='SHOW_AGENT_COMMISSION_PERCENT - Zeigen den Anteil der Vermittlungsprovision in Form von Bestätigung'"), ?(StrFind(vParameter, "SHOW_AGENT_COMMISSION_PERCENT") > 0, True, False));
		vListItems.Add("NO_COMMISSION", NStr("en='NO_COMMISSION - Do not show commission percent and amount'; ru='NO_COMMISSION - Не показывать в подтверждении брони сумму и процент комисии'; de='NO_COMMISSION - Nicht die Summe und der Provisionprozent in der Buchungsbestätigung aufzeigen'"), ?(StrFind(vParameter, "NO_COMMISSION") > 0, True, False));
		vListItems.Add("JOIN_IN_PRICE_SERVICES_TO_MAIN_ROOM_GUEST", NStr("en='JOIN_IN_PRICE_SERVICES_TO_MAIN_ROOM_GUEST - Hide all in-price services to main room guest price'; ru='JOIN_IN_PRICE_SERVICES_TO_MAIN_ROOM_GUEST - Прятать суммы услуг по тарифам в цену проживания главного гостя в номере'; de='JOIN_IN_PRICE_SERVICES_TO_MAIN_ROOM_GUEST - Alle in-Preis Service für Hauptraum Gäste Preis verstecken'"), ?(StrFind(vParameter, "JOIN_IN_PRICE_SERVICES_TO_MAIN_ROOM_GUEST") > 0, True, False));
		vListItems.Add("DO_NOT_SEND_RESERVATION_CONFIRMATION_TO_AGENT", NStr("en='DO_NOT_SEND_RESERVATION_CONFIRMATION_TO_AGENT - Do not send reservation confirmation to an agent e-mail'; ru='DO_NOT_SEND_RESERVATION_CONFIRMATION_TO_AGENT - Не отправлять подтверждение брони на e-mail агента'; de='DO_NOT_SEND_RESERVATION_CONFIRMATION_TO_AGENT - Senden Sie keine Reservierungsbestätigung an eine Agent E-Mail'"), ?(StrFind(vParameter, "DO_NOT_SEND_RESERVATION_CONFIRMATION_TO_AGENT") > 0, True, False));
		vListItems.Add("DO_NOT_SEND_RESERVATION_CONFIRMATION_TO_CLIENT", NStr("en='DO_NOT_SEND_RESERVATION_CONFIRMATION_TO_CLIENT - Do not send reservation confirmation to the client e-mail'; ru='DO_NOT_SEND_RESERVATION_CONFIRMATION_TO_CLIENT - Не отправлять подтверждение брони на e-mail клиента'; de='DO_NOT_SEND_RESERVATION_CONFIRMATION_TO_CLIENT - Senden Sie keine Reservierungsbestätigung an eine Gast E-Mail'"), ?(StrFind(vParameter, "DO_NOT_SEND_RESERVATION_CONFIRMATION_TO_CLIENT") > 0, True, False));
		vListItems.Add("SHOW_PAYMENT_LINK", NStr("en='SHOW_PAYMENT_LINK - Show payment link in on-line booking module'; ru='SHOW_PAYMENT_LINK - Показывать ссылку на оплату в модуле on-line бронирования'; de='SHOW_PAYMENT_LINK - Link zur Zahlung im Online-Buchungsmodul anzeigen'"), ?(StrFind(vParameter, "SHOW_PAYMENT_LINK") > 0, True, False));
		vListItems.Add("USE_INDIVIDUAL_RESERVATION_NUMBER_FOR_FILE", NStr("en = 'USE_INDIVIDUAL_RESERVATION_NUMBER_FOR_FILE - Use reservation document number for file attachment'; de = 'USE_INDIVIDUAL_RESERVATION_NUMBER_FOR_FILE - Reservierung Dokument-Nummer für die Datei-Anhang'; ru = 'USE_INDIVIDUAL_RESERVATION_NUMBER_FOR_FILE - Использовать индивидуальный номер документа при сохранении файла.'"), ?(StrFind(vParameter, "USE_INDIVIDUAL_RESERVATION_NUMBER_FOR_FILE") > 0, True, False));
		vListItems.Add("PRINT_MAIN_ROOM_GUESTS_ONLY", NStr("en='PRINT_MAIN_ROOM_GUESTS_ONLY - Print main room guests only'; ru='PRINT_MAIN_ROOM_GUESTS_ONLY - Печатать только основных гостей номера'; de='PRINT_MAIN_ROOM_GUESTS_ONLY - Nur hauptgäste drucken'"), ?(StrFind(vParameter, "PRINT_MAIN_ROOM_GUESTS_ONLY") > 0, True, False));
		vListItems.Add("SHOW_QRCODE", NStr("en='SHOW_QRCODE - print QR-code'; ru='SHOW_QRCODE - Печатать QR-code'; de='SHOW_QRCODE - QR-Code drucken'"), ?(StrFind(vParameter, "SHOW_QRCODE") > 0, True, False));
		vListItems.Add("SHOW_DAILY_PRICES", NStr("en='SHOW_DAILY_PRICES - Show daily prices table in rich text reservation confirmation'; ru='SHOW_DAILY_PRICES - Показывать таблицу с ценами по дням в форме расширенного подтверждения брони'; de='SHOW_DAILY_PRICES - Tagespreistabelle im Rich Text Reservierungsbestätigung anzeigen'"), ?(StrFind(vParameter, "SHOW_DAILY_PRICES") > 0, True, False));
		vListItems.Add("DONT_SHOW_GUESTS_LIST", NStr("en='DONT_SHOW_GUESTS_LIST - Do not show guests list in rich text reservation confirmation'; ru='DONT_SHOW_GUESTS_LIST - Не показывать список гостей в форме расширенного подтверждения брони'; de='DONT_SHOW_GUESTS_LIST - Gästeliste nicht in Rich-Text-Reservierungsbestätigung anzeigen'"), ?(StrFind(vParameter, "DONT_SHOW_GUESTS_LIST") > 0, True, False));
		vListItems.Add("SHOW_CHILDREN_AGES", NStr("en='SHOW_CHILDREN_AGES - Show children ages'; ru='SHOW_CHILDREN_AGES - Показывать возраст детей'; de='SHOW_CHILDREN_AGES - Alter der Kinder anzeigen'"), ?(StrFind(vParameter, "SHOW_CHILDREN_AGES") > 0, True, False));
		vListItems.Add("SHOW_TOTAL_PAID_AMOUNT", NStr("en='SHOW_TOTAL_PAID_AMOUNT - Show total amount paid in footer'; ru='SHOW_TOTAL_PAID_AMOUNT - Показывать в итогах сумму оплат по брони'; de='SHOW_TOTAL_PAID_AMOUNT - Gezahlter Betrag in Fußzeile anzeigen'"), ?(StrFind(vParameter, "SHOW_TOTAL_PAID_AMOUNT") > 0, True, False));
	ElsIf TypeOf(Object.ObjectType) = Type("DocumentRef.Folio") Then
		vListItems.Add("FOLIO_CUSTOMER", NStr("en='FOLIO_CUSTOMER - Do not print customer in client folio'; ru='FOLIO_CUSTOMER - Не печатать контрагента в лицевом счете клиента'; de='FOLIO_CUSTOMER - Firma in dem Konto des Kunden nicht drucken'"), ?(StrFind(vParameter, "FOLIO_CUSTOMER") > 0, True, False));
		vListItems.Add("ACCOMMODATION_TYPE", NStr("en='ACCOMMODATION_TYPE - Print guest accommodation type name in the folio'; ru='ACCOMMODATION_TYPE - Печатать в лицевом счете клиента название вида размещения'; de='ACCOMMODATION_TYPE - Print-Unterkunft Typnamen im Folio'"), ?(StrFind(vParameter, "ACCOMMODATION_TYPE") > 0, True, False));
		vListItems.Add("GROUP_BY_PRICE", NStr("en='GROUP_BY_PRICE - Do not merge the same services with different prices'; ru='GROUP_BY_PRICE - Услуги с разными ценами печатать отдельными строками'; de='GROUP_BY_PRICE - Dienstleistungen mit unterschiedlichen Preisen in getrennten Zeilen gedruckt'"), ?(StrFind(vParameter, "GROUP_BY_PRICE") > 0, True, False));
		vListItems.Add("SHOW_QRCODE", NStr("en='SHOW_QRCODE - print QR-code'; ru='SHOW_QRCODE - Печатать QR-code'; de='SHOW_QRCODE - QR-Code drucken'"), ?(StrFind(vParameter, "SHOW_QRCODE") > 0, True, False));
		vListItems.Add("IGNORE_VATRATE_ON_GROUPING", NStr("en='IGNORE_VATRATE_ON_GROUPING - Ignore VAT rate while grouping in-rate services to accommodation'; ru='IGNORE_VATRATE_ON_GROUPING - Не учитывать ставку НДС при группировке услуг в проживание'; de='IGNORE_VATRATE_ON_GROUPING - Berücksichtigen Sie den Mehrwertsteuersatz nicht, wenn Sie Dienstleistungen in Unterkünfte gruppieren'"), ?(StrFind(vParameter, "IGNORE_VATRATE_ON_GROUPING") > 0, True, False));
		vListItems.Add("DO_NOT_SHOW_PAYMENT_REMARKS", NStr("en='DO_NOT_SHOW_PAYMENT_REMARKS - Do not show payment remarks in folio printing forms'; ru='DO_NOT_SHOW_PAYMENT_REMARKS - Не показывать примечания платежей при печати лицевых счетов'; de='DO_NOT_SHOW_PAYMENT_REMARKS - Zahlungsvermerke in Folio-Druckformularen nicht anzeigen'"), ?(StrFind(vParameter, "DO_NOT_SHOW_PAYMENT_REMARKS") > 0, True, False));
		vListItems.Add("DO_NOT_SHOW_CHARGE_REMARKS", NStr("en='DO_NOT_SHOW_CHARGE_REMARKS - Do not show payment remarks in folio printing forms'; ru='DO_NOT_SHOW_CHARGE_REMARKS - Не показывать примечания начислений при печати лицевых счетов'; de='DO_NOT_SHOW_CHARGE_REMARKS - Abrechnungsnotizen in Folio-Druckformularen nicht anzeigen'"), ?(StrFind(vParameter, "DO_NOT_SHOW_CHARGE_REMARKS") > 0, True, False));
		vListItems.Add("DO_NOT_SHOW_PAYMENTS", NStr("en='DO_NOT_SHOW_PAYMENTS - Do not show payment transactions in folio printing forms'; ru='DO_NOT_SHOW_PAYMENTS - Не показывать транзакции оплаты при печати лицевых счетов'; de='DO_NOT_SHOW_PAYMENTS - Zahlungen in Folio-Druckformularen nicht anzeigen'"), ?(StrFind(vParameter, "DO_NOT_SHOW_PAYMENTS") > 0, True, False));
		vListItems.Add("CALCULATE_VAT_AMOUNT_BY_VAT_RATE_TOTALS", NStr("en='CALCULATE_VAT_AMOUNT_BY_VAT_RATE_TOTALS - Calculate VAT amount in folio printing forms by VAT rate totals'; ru='CALCULATE_VAT_AMOUNT_BY_VAT_RATE_TOTALS - При печати лицевых счетов рассчитывать суммы НДС от итогов по ставкам НДС'; de='CALCULATE_VAT_AMOUNT_BY_VAT_RATE_TOTALS - Den MwSt.-Betrag in Folio-Druckformularen nach MwSt-Gesamtsummen berechnen'"), ?(StrFind(vParameter, "CALCULATE_VAT_AMOUNT_BY_VAT_RATE_TOTALS") > 0, True, False));
		vListItems.Add("SHOW_BONUSES_BALANCE", NStr("en = 'SHOW_BONUSES_BALANCE - print bonuses balance'; de = 'SHOW_BONUSES_BALANCE - bonusguthaben drucken'; ru = 'SHOW_BONUSES_BALANCE - выводить баланс по бонусам'"), ?(StrFind(vParameter, "SHOW_BONUSES_BALANCE") > 0, True, False));
		vListItems.Add("NO_MANAGER_IN_FOOTER", NStr("en = 'NO_MANAGER_IN_FOOTER - do not print managers data in print form footer'; de = 'NO_MANAGER_IN_FOOTER - Managerdaten nicht in der Fußzeile des Druckformulars drucken'; ru = 'NO_MANAGER_IN_FOOTER - не выводить данные менеджера в подвале печатной формы'"), ?(StrFind(vParameter, "NO_MANAGER_IN_FOOTER") > 0, True, False));
		vListItems.Add("InPricePerDay", NStr("en = 'InPricePerDay - group room rate services to the accommodation by dates'; de = 'InPricePerDay - zimmerpreis Dienstleistungen für die Unterkunft nach Datum gruppen'; ru = 'InPricePerDay - свернуть услуги которые входят в цену номера в услугу проживания по дням'"), ?(StrFind(vParameter, "InPricePerDay") > 0, True, False));
		vListItems.Add("InPrice", NStr("en = 'InPrice - group room rate services to the accommodation'; de = 'InPrice - zimmerpreis Dienstleistungen für die Unterkunft gruppen'; ru = 'InPrice - свернуть услуги которые входят в цену номера в услугу проживания'"), ?(StrFind(vParameter, "InPrice") > 0, True, False));
		vListItems.Add("AllPerDay", NStr("en = 'AllPerDay - group all services to the accommodation by dates'; de = 'AllPerDay - alle Dienstleistungen für die Unterkunft nach Datum gruppen'; ru = 'AllPerDay - свернуть все услуги в услугу проживания по дням'"), ?(StrFind(vParameter, "AllPerDay") > 0, True, False));
		vListItems.Add("All", NStr("en = 'All - group all services to the accommodation'; de = 'All - alle Dienstleistungen für die Unterkunft gruppen'; ru = 'All - свернуть все услуги в услугу проживания'"), ?(StrFind(vParameter, "All") > 0, True, False));
		vListItems.Add("ByService", NStr("en = 'ByService - group all services'; de = 'ByService - alle Dienstleistungen gruppen'; ru = 'ByService - сгруппировать все услуги'"), ?(StrFind(vParameter, "ByService") > 0, True, False));
	ElsIf TypeOf(Object.ObjectType) = Type("DocumentRef.ProformaInvoice") Then
		vListItems.Add("SHOW_ACCOMMODATION_PERIOD", NStr("en='SHOW_ACCOMMODATION_PERIOD - Display guest period of stay'; ru='SHOW_ACCOMMODATION_PERIOD - Выводить период проживания гостя'; de='SHOW_ACCOMMODATION_PERIOD - Aufenthaltsdauer des Gastes anzeigen'"), ?(StrFind(vParameter, "SHOW_ACCOMMODATION_PERIOD") > 0, True, False));
		vListItems.Add("SHOW_ACCOMMODATION_TYPE", NStr("en='SHOW_ACCOMMODATION_TYPE - Display guest accommodation type'; ru='SHOW_ACCOMMODATION_TYPE - Выводить вид размещения гостя'; de='SHOW_ACCOMMODATION_TYPE - Typ der Gastunterkunft anzeigen'"), ?(StrFind(vParameter, "SHOW_ACCOMMODATION_TYPE") > 0, True, False));
		vListItems.Add("NO_ROOM", NStr("en='NO_ROOM - Do not print room name'; ru='NO_ROOM - Не печатать номер комнаты'; de='NO_ROOM - Keine Zimmer drucken'"), ?(StrFind(vParameter, "NO_ROOM") > 0, True, False));
		vListItems.Add("NO_RTYPE", NStr("en='NO_RTYPE - Do not print room type name'; ru='NO_RTYPE - Не печатать тип номера'; de='NO_RTYPE - Keine Zimmertyp drucken'"), ?(StrFind(vParameter, "NO_RTYPE") > 0, True, False));
		vListItems.Add("NO_RESOURCE", NStr("en='NO_RESOURCE - Do not print resource name'; ru='NO_RESOURCE - Не печатать название ресурса'; de='NO_RESOURCE - Keine resource drucken'"), ?(StrFind(vParameter, "NO_RESOURCE") > 0, True, False));
		vListItems.Add("SHOW_DISCOUNT", NStr("en='SHOW_DISCOUNT - Show amount and prices without discount'; ru='SHOW_DISCOUNT - Показывать цены и суммы без скидки, сумму скидки выводить отдельным итогом'; de='SHOW_DISCOUNT - Preise und Beträge ohne Rabatt Show, Rabattbetrag als separater Line-Ausgang'"), ?(StrFind(vParameter, "SHOW_DISCOUNT") > 0, True, False));
		vListItems.Add("DO_NOT_SEND_INVOICE_TO_AGENT", NStr("en='DO_NOT_SEND_INVOICE_TO_AGENT - Do not invoice to an agent e-mail'; ru='DO_NOT_SEND_INVOICE_TO_AGENT - Не отправлять счет на оплату на e-mail агента'; de='DO_NOT_SEND_INVOICE_TO_AGENT - Senden Sie keine Proformarechnung an eine Agent E-Mail'"), ?(StrFind(vParameter, "DO_NOT_SEND_INVOICE_TO_AGENT") > 0, True, False));
		vListItems.Add("DO_NOT_USE_SECTION_VAT", NStr("en='DO_NOT_USE_SECTION_VAT - Do not use VAT rate from the service payment section'; ru='DO_NOT_USE_SECTION_VAT - Не использовать ставку НДС из платежной секции услуги'; de='DO_NOT_USE_SECTION_VAT - Verwenden Sie den Mehrwertsteuersatz nicht im Abschnitt Servicezahlung'"), ?(StrFind(vParameter, "DO_NOT_USE_SECTION_VAT") > 0, True, False));
		vListItems.Add("SHOW_QRCODE", NStr("en='SHOW_QRCODE - print QR-code'; ru='SHOW_QRCODE - Печатать QR-code'; de='SHOW_QRCODE - QR-Code drucken'"), ?(StrFind(vParameter, "SHOW_QRCODE") > 0, True, False));
		vListItems.Add("SHOW_PAX", NStr("en='SHOW_PAX - print accommodation template'; ru='SHOW_PAX - Печатать шаблон размещения'; de='SHOW_PAX - Vorlage für Unterkünfte drucken'"), ?(StrFind(vParameter, "SHOW_PAX") > 0, True, False));
		vListItems.Add("IGNORE_VATRATE_ON_GROUPING", NStr("en='IGNORE_VATRATE_ON_GROUPING - ignore VAT rate while grouping in-rate services to accommodation'; ru='IGNORE_VATRATE_ON_GROUPING - Не учитывать ставку НДС при группировке услуг в проживание'; de='IGNORE_VATRATE_ON_GROUPING - Berücksichtigen Sie den Mehrwertsteuersatz nicht, wenn Sie Dienstleistungen in Unterkünfte gruppieren'"), ?(StrFind(vParameter, "IGNORE_VATRATE_ON_GROUPING") > 0, True, False));
		vListItems.Add("DO_NOT_SHOW_PAY_DUE_DATE", NStr("en='DO_NOT_SHOW_PAY_DUE_DATE - Do not show pay due date'; ru='DO_NOT_SHOW_PAY_DUE_DATE - Не показывать дату проверки оплаты'; de='DO_NOT_SHOW_PAY_DUE_DATE - Datum der Zahlungsüberprüfung nicht anzeigen'"), ?(StrFind(vParameter, "DO_NOT_SHOW_PAY_DUE_DATE") > 0, True, False));
	ElsIf TypeOf(Object.ObjectType) = Type("DocumentRef.Settlement") Then
		vListItems.Add("SHOWZEROES", NStr("en='SHOWZEROES - Print services with zero amount'; ru='SHOWZEROES - Печатать услуги с нулевыми суммами'; de='SHOWZEROES - Print Services mit Nullsummen'"), ?(StrFind(vParameter, "SHOWZEROES") > 0, True, False));
		vListItems.Add("DO_NOT_SHOW_PAY_DUE_DATE", NStr("en='DO_NOT_SHOW_PAY_DUE_DATE - Do not show pay due date'; ru='DO_NOT_SHOW_PAY_DUE_DATE - Не показывать дату проверки оплаты'; de='DO_NOT_SHOW_PAY_DUE_DATE - Datum der Zahlungsüberprüfung nicht anzeigen'"), ?(StrFind(vParameter, "DO_NOT_SHOW_PAY_DUE_DATE") > 0, True, False));
		vListItems.Add("SHOW_CONTRACT", NStr("en='SHOW_CONTRACT - Show contract description right to the customer name'; ru='SHOW_CONTRACT - Показывать наименование договора справа от названия заказчика'; de='SHOW_CONTRACT - Den Namen des Vertrags rechts neben dem Namen des Firma anzeigen'"), ?(Find(vParameter, "SHOW_CONTRACT") > 0, True, False));
		vListItems.Add("DO_NOT_SHOW_CLIENT_CITIZENSHIP", NStr("en='DO_NOT_SHOW_CLIENT_CITIZENSHIP - Do not display the country of citizenship of the guest'; ru='DO_NOT_SHOW_CLIENT_CITIZENSHIP - Не выводить страну гражданства гостя'; de='DO_NOT_SHOW_CLIENT_CITIZENSHIP - Das Land der Staatsbürgerschaft des Gastes nicht ableiten'"), ?(StrFind(vParameter, "DO_NOT_SHOW_CLIENT_CITIZENSHIP") > 0, True, False));
		vListItems.Add("SHOW_PRICES_ROOM_TYPE", NStr("en='SHOW_PRICES_ROOM_TYPE - Display the prices room type additionally in the room description'; ru='SHOW_PRICES_ROOM_TYPE - В описании к номеру дополнительно выводить тип номера цены'; de='SHOW_PRICES_ROOM_TYPE - Die Preise des Zimmertyps zusätzlich in der Zimmerbeschreibung anzeigen'"), ?(StrFind(vParameter, "SHOW_PRICES_ROOM_TYPE") > 0, True, False));
	ElsIf TypeOf(Object.ObjectType) = Type("DocumentRef.ResourceReservation") Then
		vListItems.Add("DO_NOT_GROUP_BY_RESOURCE_TYPE", NStr("en='DO_NOT_GROUP_BY_RESOURCE_TYPE - Do not group services by resource type'; ru='DO_NOT_GROUP_BY_RESOURCE_TYPE - Не группировать услуги по типам ресурсов'; de='DO_NOT_GROUP_BY_RESOURCE_TYPE - Nicht sortieren Leistungen nach Ressourcentyp'"), ?(StrFind(vParameter, "DO_NOT_GROUP_BY_RESOURCE_TYPE") > 0, True, False));
		vListItems.Add("SHOW_PLANNED_PAYMENT_METHOD", NStr("en='SHOW_PLANNED_PAYMENT_METHOD - Show planned payment method'; ru='SHOW_PLANNED_PAYMENT_METHOD - Показывать планируемый способ оплаты'; de='SHOW_PLANNED_PAYMENT_METHOD - Geplante Zahlungsmethode anzeigen'"), ?(StrFind(vParameter, "SHOW_PLANNED_PAYMENT_METHOD") > 0, True, False));
		vListItems.Add("SHOW_ARRANGEMENT", NStr("en = 'SHOW_ARRANGEMENT - ыhow the arrangement'; de = 'SHOW_ARRANGEMENT - Anordnung anzeigen'; ru = 'SHOW_ARRANGEMENT - показывать расстановку'"), ?(StrFind(vParameter, "SHOW_ARRANGEMENT") > 0, True, False));
	ElsIf TypeOf(Object.ObjectType) = Type("DocumentRef.OperationSchedule") Then
		vListItems.Add("SHOW_ONE_GUEST_PER_ROOM_ONLY", NStr("en='SHOW_ONE_GUEST_PER_ROOM_ONLY - Show only main room guest name'; ru='SHOW_ONE_GUEST_PER_ROOM_ONLY - Показывать данные только одного (главного) гостя в номере'; de='SHOW_ONE_GUEST_PER_ROOM_ONLY - Zeigen Sie die Daten nur eine (Haupt) Zimmergäste'"), ?(StrFind(vParameter, "SHOW_ONE_GUEST_PER_ROOM_ONLY") > 0, True, False));
		vListItems.Add("SHOW_GUEST_DATE_OF_BIRTH", NStr("en='SHOW_GUEST_DATE_OF_BIRTH - Show guest birth date'; ru='SHOW_GUEST_DATE_OF_BIRTH - Показывать дату рождения гостей'; de='SHOW_GUEST_DATE_OF_BIRTH - Gäste Geburtstag Datum anzeigen'"), ?(StrFind(vParameter, "SHOW_GUEST_DATE_OF_BIRTH") > 0, True, False));
		vListItems.Add("SHOW_REMARKS", NStr("en='SHOW_REMARKS - Show housekeeping remarks and tasks'; ru='SHOW_REMARKS - Показывать примечания горничных и задачи'; de='SHOW_REMARKS - Hausmädchen Notizen und Aufgaben anzeigen'"), ?(StrFind(vParameter, "SHOW_REMARKS") > 0, True, False));
		vListItems.Add("GROUP_BY_ROOM", NStr("en = 'GROUP_BY_ROOM - Group operations by room'; de = 'GROUP_BY_ROOM - Gruppieren von Vorgängen nach Räumen'; ru = 'GROUP_BY_ROOM - Группировать работы по комнате'"), ?(StrFind(vParameter, "GROUP_BY_ROOM") > 0, True, False));
		vListItems.Add("GROUP_BY_PARENT", NStr("en = 'GROUP_BY_PARENT - Group jobs by parent group'; de = 'GROUP_BY_PARENT - Gruppieren von Aufträgen nach übergeordneter Gruppe'; ru = 'GROUP_BY_PARENT - Группировать работы по родительской группе'"), ?(StrFind(vParameter, "GROUP_BY_PARENT") > 0, True, False));
		vListItems.Add("USE_COLOR_ROOM_STATUS", NStr("en = 'USE_COLOR_ROOM_STATUS - Color the status column with the status color'; de = 'USE_COLOR_ROOM_STATUS - Färben Sie die Statusspalte mit der Statusfarbe'; ru = 'USE_COLOR_ROOM_STATUS - Закрашивать колонку статусов цветом статус'"), ?(StrFind(vParameter, "USE_COLOR_ROOM_STATUS") > 0, True, False));
		vListItems.Add("SHOW_DISCOUNT_TYPE", NStr("en = 'SHOW_DISCOUNT_TYPE - Display discount card type instead of client type'; de = 'SHOW_DISCOUNT_TYPE - Rabattkartentyp anstelle Kundentyp anzeigen'; ru = 'SHOW_DISCOUNT_TYPE - Выводить тип дисконтной карты вместо типа клиента'"), ?(StrFind(vParameter, "USE_COLOR_ROOM_STATUS") > 0, True, False));

	EndIf;
	If vListItems.Count() > 0 Then
		vNotify = New NotifyDescription("AfterSelectParameter", ThisObject);
		vListItems.ShowCheckItems(vNotify, NStr("en='Check parameters needed'; ru='Отметьте нужные параметры'; de='Markieren Sie die gewünschten Optionen'"));
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure RemarksOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", Object.Remarks), pItem);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFile(pCommand)
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromFileAttachingFileSystemExtensionResult", ThisObject));
EndProcedure // LoadFile

// --------------------------------------------------------------------------------
&AtClient
Procedure ClearFile(pCommand)
	ClearFileAtServer();
EndProcedure // ClearFile

// --------------------------------------------------------------------------------
&AtClient
Procedure SaveFile(Command)
	If IsBlankString(FileTempStorage) Then
		GetTemplateTempStorageAddress();
	EndIf;
	If Not IsBlankString(FileTempStorage) Then
		OpenFileDialogToSaveFile();		
	EndIf;
EndProcedure // SaveFile

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFromFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		OpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'File system extension is being installing on your browser...'; 
														|de = 'Dateisystemerweiterung wird in Ihrem Browser installiert...'; 
														|ru = 'В браузер устанавливается расширение по работе с файлами...'"), MessageStatus.Information);
		BeginInstallFileSystemExtension(New NotifyDescription("LoadFromFileFileSystemExtensionInstallCompleted", ThisObject));
	EndIf;
EndProcedure // LoadFromFileAttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFromFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromFileInstallingFileSystemExtensionResult", ThisObject));
EndProcedure // LoadFromFileFileSystemExtensionInstallCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFromFileInstallingFileSystemExtensionResult(pResult, pParam) Export 
	If pResult Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='В браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"), MessageStatus.Information);
		OpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"), MessageStatus.Attention);
	EndIf;
EndProcedure // LoadFromFileInstallingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient 
Procedure OpenFileDialogToChooseFile()
	vFileOpen = New FileDialog(FileDialogMode.Open);
	vFileOpen.Filter = NStr("ru = 'Макеты 1С (*.mxl)|*.mxl|'; en = '1C templates (*.mxl)|*.mxl|'; de = '1C templates (*.mxl)|*.mxl|'");
	vFileOpen.Multiselect = False;
	vFileOpen.Title = NStr("en='Open file';ru='Открыть файл';de='Datei öffnen'");
	vFileOpen.Preview = True;
	vFileOpen.Show(New NotifyDescription("OpenFileDialogToChooseFileCompleted", ThisObject));
EndProcedure // OpenFileDialogToChooseFile

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileDialogToChooseFileCompleted(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		vFullFileName = pFileArray[0];
		vFile = New File(vFullFileName);
		vFile.BeginGettingModificationTime(New NotifyDescription("LoadFileGettingModificationTimeCompleted", ThisObject, New Structure("FileName, FullFileName", vFile.Name, vFullFileName)));
	EndIf;
EndProcedure // OpenFileDialogToChooseFileCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFileGettingModificationTimeCompleted(pModificationTime, pParams) Export
	LoadFileInWebClient(pParams.FullFileName, New Structure("Name, LastModificationTime", pParams.FileName, pModificationTime));
EndProcedure // LoadFileGettingModificationTimeCompleted	

// --------------------------------------------------------------------------------
&AtServer
Procedure ClearFileAtServer()
	FileTempStorage = "";
	ClearExternalTemplate = True;
	Object.ExternalTemplateFileName = "";
	Object.ExternalTemplateFileLastChangeTime = '00010101';
	Object.ExternalTemplateFileLoadTime = '00010101';
	Modified = True;
EndProcedure // ClearPhotoAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure GetTemplateTempStorageAddress()
	vObj = FormAttributeToValue("Object");
	vBinaryData = vObj.ExternalTemplate.Get();
	If vBinaryData <> Undefined And TypeOf(vBinaryData) = Type("BinaryData") Then
		FileTempStorage = PutToTempStorage(vBinaryData, UUID);
	EndIf;
EndProcedure // GetTemplateTempStorageAddress

// --------------------------------------------------------------------------------
&AtClient 
Procedure OpenFileDialogToSaveFile()
	vFileSave = New FileDialog(FileDialogMode.Save);
	vFileSave.Filter = NStr("ru = 'Шаблон отчета (*.mxl)|*.mxl;|'; 
	                        |de = 'Berichtsvorlage (*.mxl)|*.mxl;|'; 
	                        |en = 'Report template (*.mxl)|*.mxl;|'");
	vFileSave.DefaultExt = "mxl";
	vFileSave.Multiselect = False;
	vFileSave.Title = NStr("en='Save file';ru='Сохранить файл';de='Datei speichern'");
	vFileSave.CheckFileExist = True;
	vFileSave.Show(New NotifyDescription("OpenFileDialogToSaveFileCompleted", ThisObject));
EndProcedure // OpenFileDialogToSaveFile

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileDialogToSaveFileCompleted(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		vFullFileName = pFileArray[0];
		vFileBinaryData = GetFromTempStorage(FileTempStorage);
		If vFileBinaryData <> Undefined And TypeOf(vFileBinaryData) = Type("BinaryData") Then
			vFileBinaryData.BeginWrite(New NotifyDescription("SaveFileAfterWrite", ThisObject), vFullFileName);
		EndIf;
	EndIf;
EndProcedure // OpenFileDialogToSaveFileCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure SaveFileAfterWrite(pExtraParams) Export
	ShowMessageBox(, NStr("en='Success!'; ru='Успешно!'; de='Erfolg!'"), 3);
EndProcedure // SaveFileAfterWrite

// --------------------------------------------------------------------------------
&AtServer
Procedure CommandActionLoadFromFileAtServer(pBinaryData, pFileName, pFileLastChangeTime) 
	FileTempStorage = PutToTempStorage(pBinaryData, UUID);
	If Object.ExternalTemplateFileName <> pFileName Or Not ValueIsFilled(Object.ExternalTemplateFileLoadTime) Then
		Object.ExternalTemplateFileLoadTime = CurrentSessionDate();
	EndIf;
	Object.ExternalTemplateFileName = pFileName;
	Object.ExternalTemplateFileLastChangeTime = pFileLastChangeTime;
	ClearExternalTemplate = False;
	Modified = True;
EndProcedure // CommandActionLoadFromFileAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure FileDownloadToServerCompletedAtServer(pTransferredFiles, pFile)
	vFileAddress = pTransferredFiles.Get(0).Location;
	vBinaryData = GetFromTempStorage(vFileAddress);
	CommandActionLoadFromFileAtServer(vBinaryData, pFile.Name, pFile.LastModificationTime);
EndProcedure // FileDownloadToServerCompletedAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure FileDownloadToServerCompleted(pTransferredFiles, pFile) Export
	FileDownloadToServerCompletedAtServer(pTransferredFiles, pFile);
EndProcedure // FileDownloadToServerCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFileInWebClient(pFullFileName, pFile)
	vFilesArray = New Array();
	vFileDescription = New TransferableFileDescription(pFullFileName);
	vFilesArray.Add(vFileDescription);
	BeginPuttingFiles(New NotifyDescription("FileDownloadToServerCompleted", ThisObject, pFile), vFilesArray, , False);
EndProcedure // LoadFileInWebClient

// --------------------------------------------------------------------------------
&AtClient
Procedure AfterSelectParameter(pResult, pAdditionalParams) Export 
	If Not pResult = Undefined Then
		vParameter = "";
		For Each vListItem In pResult Do
			If vListItem.Check Then
				If IsBlankString(vParameter) Then
					vParameter = vListItem.Value;
				Else
					vParameter = vParameter + ", " + vListItem.Value;
				EndIf;
			EndIf;
		EndDo;
		Object.Parameter = vParameter;
	EndIf;
EndProcedure	

#EndRegion
