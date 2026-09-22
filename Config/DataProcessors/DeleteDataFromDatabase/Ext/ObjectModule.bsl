// -----------------------------------------------------------------------------
// Data processors framework start
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

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
	If Not ValueIsFilled(Company) And ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Company) Then
		Company = SessionParameters.CurrentUser.Company;
	EndIf;
	If Not ValueIsFilled(PeriodFrom) Then
		PeriodFrom = BegOfYear(BegOfYear(CurrentSessionDate()) - 1); // For previous year
		PeriodTo = EndOfYear(PeriodFrom);
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Function pmRun(pParameter = Undefined, pIsInteractive = False) Export
	// Если указана фирма, то удаляем только те виды документов, которые имеют отношение к фирме
	
	// Try to switch to exclusive mode
	Try
		SetExclusiveMode(True);
	Except
	EndTry;
	
	// Switch off totals recalculation for all registers
	If ExclusiveMode() Then
		tcCommonFunctionOnClientServer.TextMessage("Disabling accumulation registers totals...");
		For Each vRegister In Metadata.AccumulationRegisters Do
			AccumulationRegisters[vRegister.Name].SetTotalsUsing(False);
		EndDo;
	EndIf;
	
	Try
		// Формируем список гостей для удаления
		vGuestsToDeleteList = New ValueList();
		
		// Порядок удаления документов
		// 1.	Акты (Settlement)
		DeleteSettlementDocuments();
		// 2.	Возвраты (Return)
		DeleteReturnDocuments();
		// 3.	Переносы депозитов (DepositTransfer)
		DeleteDepositTransferDocuments();
		// 4.	Преавторизации (Preauthorisation)
		DeletePreauthorisationDocuments();
		// 5.	Платежи (Payment)
		DeletePaymentDocuments();
		// 6.	Платежи контрагентов (CustomerPayment)
		DeleteCustomerPaymentDocuments();
		// 7.	Распределение авансов между счетами-требованиями (CustomerAdvanceDistribution)
		DeleteCustomerAdvanceDistributionDocuments();
		// 8.	Внесение выплата денег в ККМ (CashIncome and CashOutcome)
		DeleteCashIncomeDocuments();
		DeleteCashOutcomeDocuments();
		// 9.	Закрытие кассовых смен (CloseOfCashRegisterDay)
		DeleteCloseOfCashRegisterDayDocuments();
		// 10.	Регистрация услуг (ServiceRegistration)
		DeleteServiceRegistrationDocuments();
		// 11.	Переносы начислений (ChargeTransfer)
		DeleteChargeTransferDocuments();
		// 12.	Сторно (Storno)
		DeleteStornoDocuments();
		// 13.	Начисления (Charge)
		DeleteChargeDocuments();
		// 14.	Телефонные разговоры (RecordPhoneCall)
		DeleteRecordPhoneCallDocuments();
		// 15.	Доп. услуги из номеров (RecordRoomService)
		DeleteRecordRoomServiceDocuments();
		// 16.	Закрытия периодов (CloseOfPeriod)
		DeleteCloseOfPeriodDocuments();
		// 17.	Счета-требования (Invoice)
		DeleteInvoiceDocuments();
		// 18.	Сообщения (Message)
		// 19.	Сканы данных клиентов (ClientDataScans)
		DeleteClientDataScansDocuments();
		// 20.	Записи в журнал регистрации иностранцев (ForeignerRegistryRecord)
		DeleteForeignerRegistryRecordDocuments();
		// 21.	Статусы доп. услуг номеров (RoomInterfaceStatus)
		DeleteRoomInterfaceStatusDocuments();
		// 22.	Размещения (Accommodation)
		DeleteAccommodationDocuments(vGuestsToDeleteList);
		// 23.	Бронирование (Reservation)
		DeleteReservationDocuments(vGuestsToDeleteList);
		// 24.	Бронирование ресурсов (ResourceReservation)
		DeleteResourceReservationDocuments(vGuestsToDeleteList);
		// 25.	Изменение квот номеров (SetRoomQuota)
		// 26.	Установка блокировок номеров (SetRoomBlock)
		// 27.	Изменение параметров номеров (ChangeRoom)
		// 28.	Добавление номеров в номерной фонд (AddRoom)
		// 29.	Лицевые счета (после удаления нужно проверить, что не удалены лицевые счета указанные на закладках «Правила начисления» в карточке гостиницы, карточках контрагентов и договоров (Folio)
		DeleteFolioDocuments(vGuestsToDeleteList);
		// 30.	Работы сотрудников (EmployeeOperation)
		If Not ValueIsFilled(Company) Then
			DeleteEmployeeOperationDocuments();
		EndIf;
		// 31.	Планы выполнения работ в номерах (OperationSchedule)
		If Not ValueIsFilled(Company) Then
			DeleteOperationScheduleDocuments();
		EndIf;
		// 32.	Установка цен тарифов (SetRoomRatePrices)
		// 33.	Установка диапазонов (SetPriceTagRanges)
		// 34.	Накладная на отгрузку путевок (IssueHotelProducts)
		DeleteIssueHotelProductsDocuments();
		// 35.	Ввод нач. остатков по накопительным скидкам (InputAccumulatingDiscountBalances)
		If Not ValueIsFilled(Company) Then
			DeleteInputAccumulatingDiscountBalancesDocuments();
		EndIf;
		// 36.	Рассылка СМС (SMSDelivery) только те строки, которые ссылаются на удаленные документы
		DeleteSMSDeliveryDocuments();
		
		// Удаляем тех гостей, у которых не осталось ссылок
		If DoDeleteClients Then
			DeleteClients(vGuestsToDeleteList);
		EndIf;
	Except
		vErrorDescription = cmGetRootErrorDescription(ErrorInfo());
		tcCommonFunctionOnClientServer.TextMessage(vErrorDescription, MessageStatus.Attention);
		
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
	EndTry;
	
	// Switch off exclusive mode
	If ExclusiveMode() Then
		// Switch on totals recalculation for all registers
		If ExclusiveMode() Then
			tcCommonFunctionOnClientServer.TextMessage("Restoring accumulation registers totals...");
			For Each vRegister In Metadata.AccumulationRegisters Do
				AccumulationRegisters[vRegister.Name].SetTotalsUsing(True);
			EndDo;
		EndIf;
		
		SetExclusiveMode(False);
	EndIf;
	
	If Not IsBlankString(vErrorDescription) Then
		Raise vErrorDescription;
	EndIf;
	
	Return True;
EndFunction // pmRun

// -----------------------------------------------------------------------------
// Data processors framework end
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure DeleteClients(pClientsList)
	tcCommonFunctionOnClientServer.TextMessage("Deleting clients...");
	// Get list of clients without refs
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Clients.Ref,
	|	Reservations.Guest AS ReservationGuest,
	|	ResourceReservations.Client AS ResourceReservationClient,
	|	Accommodations.Guest AS AccommodationGuest,
	|	Folios.Client AS FolioClient
	|FROM
	|	Catalog.Clients AS Clients
	|		LEFT JOIN Document.Reservation AS Reservations
	|		ON (Reservations.Guest = Clients.Ref)
	|		LEFT JOIN Document.Accommodation AS Accommodations
	|		ON (Accommodations.Guest = Clients.Ref)
	|		LEFT JOIN Document.ResourceReservation AS ResourceReservations
	|		ON (ResourceReservations.Client = Clients.Ref)
	|		LEFT JOIN Document.Folio AS Folios
	|		ON (Folios.Client = Clients.Ref)
	|WHERE
	|	Clients.Ref IN(&qClientsList)
	|	AND Reservations.Guest IS NULL 
	|	AND Accommodations.Guest IS NULL 
	|	AND ResourceReservations.Client IS NULL 
	|	AND Folios.Client IS NULL 
	|
	|ORDER BY
	|	Clients.Code";
	vQry.SetParameter("qClientsList", pClientsList);
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	i = 0;
	BeginTransaction(DataLockControlMode.Managed);
	While vQryRes.Next() Do
		vRef = vQryRes.Ref;
		i = i + 1;
		If i/100 = Int(i/100) Then
			CommitTransaction();
			BeginTransaction(DataLockControlMode.Managed);
		EndIf;
		vCltObj = vRef.GetObject();
		vCltObj.DataExchange.Load = True;
		vCltObj.Delete();
		#IF CLIENT THEN
			UserInterruptProcessing();
		#ENDIF
	EndDo;
	CommitTransaction();
EndProcedure // DeleteClients

// -----------------------------------------------------------------------------
Procedure DeleteDocuments(pQryRes, pGuestsToDelete = Undefined, pFieldName = "Client") 
	// Process documents by 100 pieces in batch
	i = 0;
	vCurDate = '00010101';
	BeginTransaction(DataLockControlMode.Managed);
	While pQryRes.Next() Do
		vRef = pQryRes.Ref;
		If i = 0 Then
			tcCommonFunctionOnClientServer.TextMessage("Processing " + vRef.Metadata().Name + " documents...");
		EndIf;
		If vCurDate <> BegOfDay(vRef.Date) Then
			vCurDate = BegOfDay(vRef.Date);
			#IF CLIENT THEN
				Status("Processing " + vRef.Metadata().Name + " date " + Format(vCurDate, "DF=dd.MM.yyyy") + " ...");
			#ENDIF
		EndIf;
		If pGuestsToDelete <> Undefined And ValueIsFilled(vRef[pFieldName]) Then
			If pGuestsToDelete.FindByValue(vRef[pFieldName]) = Undefined Then
				pGuestsToDelete.Add(vRef[pFieldName]);
			EndIf;
		EndIf;
		i = i + 1;
		If i/100 = Int(i/100) Then
			CommitTransaction();
			BeginTransaction(DataLockControlMode.Managed);
		EndIf;
		vDocObj = vRef.GetObject();
		vDocObj.DataExchange.Load = True;
		vDocObj.Delete();
		#IF CLIENT THEN
			UserInterruptProcessing();
		#ENDIF
	EndDo;
	CommitTransaction();
EndProcedure // DeleteDocuments

// -----------------------------------------------------------------------------
Procedure DeleteAccommodationDocuments(pGuestsToDelete)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Documents.Ref
	|FROM
	|	Document.Accommodation AS Documents
	|WHERE
	|	Documents.CheckInDate >= &qPeriodFrom
	|	AND Documents.CheckInDate <= &qPeriodTo
	|	AND (NOT &qHotelIsEmpty
	|				AND Documents.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (NOT &qCompanyIsEmpty
	|				AND Documents.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|
	|ORDER BY
	|	Documents.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	
	// Delete documents being found
	DeleteDocuments(vQryRes, pGuestsToDelete, "Guest");
EndProcedure // DeleteAccommodationDocuments

// -----------------------------------------------------------------------------
Procedure DeleteReservationDocuments(pGuestsToDelete)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Documents.Ref
	|FROM
	|	Document.Reservation AS Documents
	|WHERE
	|	Documents.CheckInDate >= &qPeriodFrom
	|	AND Documents.CheckInDate <= &qPeriodTo
	|	AND (NOT &qHotelIsEmpty
	|				AND Documents.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (NOT &qCompanyIsEmpty
	|				AND Documents.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|
	|ORDER BY
	|	Documents.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	
	// Delete documents being found
	DeleteDocuments(vQryRes, pGuestsToDelete, "Guest");
EndProcedure // DeleteReservationDocuments

// -----------------------------------------------------------------------------
Procedure DeleteResourceReservationDocuments(pGuestsToDelete)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Documents.Ref
	|FROM
	|	Document.ResourceReservation AS Documents
	|WHERE
	|	Documents.DateTimeFrom >= &qPeriodFrom
	|	AND Documents.DateTimeFrom <= &qPeriodTo
	|	AND (NOT &qHotelIsEmpty
	|				AND Documents.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (NOT &qCompanyIsEmpty
	|				AND Documents.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|
	|ORDER BY
	|	Documents.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	
	// Delete documents being found
	DeleteDocuments(vQryRes, pGuestsToDelete, "Client");
EndProcedure // DeleteResourceReservationDocuments

// -----------------------------------------------------------------------------
Procedure DeleteCashIncomeDocuments()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Documents.Ref
	|FROM
	|	Document.CashIncome AS Documents
	|WHERE
	|	Documents.Date >= &qPeriodFrom
	|	AND Documents.Date <= &qPeriodTo
	|	AND (NOT &qHotelIsEmpty
	|				AND (Documents.CashRegister.Hotel = &qHotel
	|					OR Documents.CashRegister.Hotel = &qEmptyHotel)
	|			OR &qHotelIsEmpty)
	|	AND (NOT &qCompanyIsEmpty
	|				AND Documents.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|
	|ORDER BY
	|	Documents.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	
	// Delete documents being found
	DeleteDocuments(vQryRes);
EndProcedure // DeleteCashIncomeDocuments

// -----------------------------------------------------------------------------
Procedure DeleteCashOutcomeDocuments()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Documents.Ref
	|FROM
	|	Document.CashOutcome AS Documents
	|WHERE
	|	Documents.Date >= &qPeriodFrom
	|	AND Documents.Date <= &qPeriodTo
	|	AND (NOT &qHotelIsEmpty
	|				AND (Documents.CashRegister.Hotel = &qHotel
	|					OR Documents.CashRegister.Hotel = &qEmptyHotel)
	|			OR &qHotelIsEmpty)
	|	AND (NOT &qCompanyIsEmpty
	|				AND Documents.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|
	|ORDER BY
	|	Documents.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	
	// Delete documents being found
	DeleteDocuments(vQryRes);
EndProcedure // DeleteCashOutcomeDocuments

// -----------------------------------------------------------------------------
Procedure DeleteChargeDocuments()
	// Get charge folios marked for deletion
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	Documents.Folio
	|FROM
	|	Document.Charge AS Documents
	|WHERE
	|	(ISNULL(Documents.ParentDoc.CheckInDate, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.ParentDoc.CheckInDate, &qEmptyDate) <= &qPeriodTo
	|			OR ISNULL(Documents.ParentDoc.DateTimeFrom, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.ParentDoc.DateTimeFrom, &qEmptyDate) <= &qPeriodTo
	|			OR ISNULL(Documents.Folio.DateTimeFrom, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.Folio.DateTimeFrom, &qEmptyDate) <= &qPeriodTo
	|			OR Documents.Date >= &qPeriodFrom
	|				AND Documents.Date <= &qPeriodTo)
	|	AND (NOT &qHotelIsEmpty
	|				AND Documents.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (NOT &qCompanyIsEmpty
	|				AND Documents.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|	AND Documents.Folio.DeletionMark
	|
	|ORDER BY
	|	Documents.Folio.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	While vQryRes.Next() Do
		vFolioObj = vQryRes.Folio.GetObject();
		vFolioObj.DataExchange.Load = True;
		vFolioObj.SetDeletionMark(False);
	EndDo;
	
	// Get charge documents to be deleted
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Documents.Ref
	|FROM
	|	Document.Charge AS Documents
	|WHERE
	|	(ISNULL(Documents.ParentDoc.CheckInDate, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.ParentDoc.CheckInDate, &qEmptyDate) <= &qPeriodTo
	|			OR ISNULL(Documents.ParentDoc.DateTimeFrom, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.ParentDoc.DateTimeFrom, &qEmptyDate) <= &qPeriodTo
	|			OR ISNULL(Documents.Folio.DateTimeFrom, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.Folio.DateTimeFrom, &qEmptyDate) <= &qPeriodTo
	|			OR Documents.Date >= &qPeriodFrom
	|				AND Documents.Date <= &qPeriodTo)
	|	AND (NOT &qHotelIsEmpty
	|				AND Documents.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (NOT &qCompanyIsEmpty
	|				AND Documents.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|
	|ORDER BY
	|	Documents.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	
	// Delete documents being found
	DeleteDocuments(vQryRes);
EndProcedure // DeleteChargeDocuments

// -----------------------------------------------------------------------------
Procedure DeleteChargeTransferDocuments()
	// Get folios marked for deletion
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	Documents.FolioFrom
	|FROM
	|	Document.ChargeTransfer AS Documents
	|WHERE
	|	(ISNULL(Documents.ParentDoc.CheckInDate, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.ParentDoc.CheckInDate, &qEmptyDate) <= &qPeriodTo
	|			OR ISNULL(Documents.ParentDoc.DateTimeFrom, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.ParentDoc.DateTimeFrom, &qEmptyDate) <= &qPeriodTo
	|			OR ISNULL(Documents.FolioTo.DateTimeFrom, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.FolioTo.DateTimeFrom, &qEmptyDate) <= &qPeriodTo
	|			OR Documents.Date >= &qPeriodFrom
	|				AND Documents.Date <= &qPeriodTo)
	|	AND (NOT &qHotelIsEmpty
	|				AND Documents.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (NOT &qCompanyIsEmpty
	|				AND Documents.ParentCharge.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|	AND Documents.FolioFrom.DeletionMark
	|
	|ORDER BY
	|	Documents.FolioFrom.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	While vQryRes.Next() Do
		vFolioObj = vQryRes.FolioFrom.GetObject();
		vFolioObj.DataExchange.Load = True;
		vFolioObj.SetDeletionMark(False);
	EndDo;
	
	// Get charge transfers
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Documents.Ref
	|FROM
	|	Document.ChargeTransfer AS Documents
	|WHERE
	|	(ISNULL(Documents.ParentDoc.CheckInDate, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.ParentDoc.CheckInDate, &qEmptyDate) <= &qPeriodTo
	|			OR ISNULL(Documents.ParentDoc.DateTimeFrom, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.ParentDoc.DateTimeFrom, &qEmptyDate) <= &qPeriodTo
	|			OR ISNULL(Documents.FolioTo.DateTimeFrom, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.FolioTo.DateTimeFrom, &qEmptyDate) <= &qPeriodTo
	|			OR Documents.Date >= &qPeriodFrom
	|				AND Documents.Date <= &qPeriodTo)
	|	AND (NOT &qHotelIsEmpty
	|				AND Documents.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (NOT &qCompanyIsEmpty
	|				AND Documents.ParentCharge.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|
	|ORDER BY
	|	Documents.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	
	// Delete documents being found
	DeleteDocuments(vQryRes);
EndProcedure // DeleteChargeTransferDocuments

// -----------------------------------------------------------------------------
Procedure DeleteDepositTransferDocuments()
	// Get folios marked for deletion
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	Documents.FolioFrom
	|FROM
	|	Document.DepositTransfer AS Documents
	|WHERE
	|	(ISNULL(Documents.ParentDoc.CheckInDate, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.ParentDoc.CheckInDate, &qEmptyDate) <= &qPeriodTo
	|			OR ISNULL(Documents.ParentDoc.DateTimeFrom, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.ParentDoc.DateTimeFrom, &qEmptyDate) <= &qPeriodTo
	|			OR ISNULL(Documents.FolioTo.DateTimeFrom, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.FolioTo.DateTimeFrom, &qEmptyDate) <= &qPeriodTo
	|			OR Documents.Date >= &qPeriodFrom
	|				AND Documents.Date <= &qPeriodTo)
	|	AND (NOT &qHotelIsEmpty
	|				AND Documents.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (NOT &qCompanyIsEmpty
	|				AND Documents.FolioTo.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|	AND Documents.FolioFrom.DeletionMark
	|
	|ORDER BY
	|	Documents.FolioFrom.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	While vQryRes.Next() Do
		vFolioObj = vQryRes.FolioFrom.GetObject();
		vFolioObj.DataExchange.Load = True;
		vFolioObj.SetDeletionMark(False);
	EndDo;
	
	// Get deposit transfer documents to be processed
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Documents.Ref
	|FROM
	|	Document.DepositTransfer AS Documents
	|WHERE
	|	(ISNULL(Documents.ParentDoc.CheckInDate, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.ParentDoc.CheckInDate, &qEmptyDate) <= &qPeriodTo
	|			OR ISNULL(Documents.ParentDoc.DateTimeFrom, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.ParentDoc.DateTimeFrom, &qEmptyDate) <= &qPeriodTo
	|			OR ISNULL(Documents.FolioTo.DateTimeFrom, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.FolioTo.DateTimeFrom, &qEmptyDate) <= &qPeriodTo
	|			OR Documents.Date >= &qPeriodFrom
	|				AND Documents.Date <= &qPeriodTo)
	|	AND (NOT &qHotelIsEmpty
	|				AND Documents.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (NOT &qCompanyIsEmpty
	|				AND Documents.FolioTo.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|
	|ORDER BY
	|	Documents.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	
	// Delete documents being found
	DeleteDocuments(vQryRes);
EndProcedure // DeleteDepositTransferDocuments

// -----------------------------------------------------------------------------
Procedure DeleteStornoDocuments()
	// Get folios marked for deletion
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	Documents.ParentCharge.Folio AS Folio
	|FROM
	|	Document.Storno AS Documents
	|WHERE
	|	(ISNULL(Documents.ParentDoc.CheckInDate, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.ParentDoc.CheckInDate, &qEmptyDate) <= &qPeriodTo
	|			OR ISNULL(Documents.ParentDoc.DateTimeFrom, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.ParentDoc.DateTimeFrom, &qEmptyDate) <= &qPeriodTo
	|			OR Documents.Date >= &qPeriodFrom
	|				AND Documents.Date <= &qPeriodTo)
	|	AND (NOT &qHotelIsEmpty
	|				AND Documents.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (NOT &qCompanyIsEmpty
	|				AND Documents.ParentCharge.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|	AND Documents.ParentCharge.Folio.DeletionMark
	|
	|ORDER BY
	|	Documents.ParentCharge.Folio.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	While vQryRes.Next() Do
		vFolioObj = vQryRes.Folio.GetObject();
		vFolioObj.DataExchange.Load = True;
		vFolioObj.SetDeletionMark(False);
	EndDo;
	
	// Get storno documents to be deleted
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Documents.Ref
	|FROM
	|	Document.Storno AS Documents
	|WHERE
	|	(ISNULL(Documents.ParentDoc.CheckInDate, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.ParentDoc.CheckInDate, &qEmptyDate) <= &qPeriodTo
	|			OR ISNULL(Documents.ParentDoc.DateTimeFrom, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.ParentDoc.DateTimeFrom, &qEmptyDate) <= &qPeriodTo
	|			OR Documents.Date >= &qPeriodFrom
	|				AND Documents.Date <= &qPeriodTo)
	|	AND (NOT &qHotelIsEmpty
	|				AND Documents.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (NOT &qCompanyIsEmpty
	|				AND Documents.ParentCharge.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|
	|ORDER BY
	|	Documents.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	
	// Delete documents being found
	DeleteDocuments(vQryRes);
EndProcedure // DeleteStornoDocuments

// -----------------------------------------------------------------------------
Procedure DeleteClientDataScansDocuments()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Documents.Ref
	|FROM
	|	Document.ClientDataScans AS Documents
	|WHERE
	|	(ISNULL(Documents.ParentDoc.CheckInDate, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.ParentDoc.CheckInDate, &qEmptyDate) <= &qPeriodTo
	|			OR Documents.Date >= &qPeriodFrom
	|				AND Documents.Date <= &qPeriodTo)
	|	AND (NOT &qHotelIsEmpty
	|				AND Documents.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (NOT &qCompanyIsEmpty
	|				AND Documents.ParentDoc.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|
	|ORDER BY
	|	Documents.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	
	// Delete documents being found
	DeleteDocuments(vQryRes);
EndProcedure // DeleteClientDataScansDocuments

// -----------------------------------------------------------------------------
Procedure DeleteCloseOfCashRegisterDayDocuments()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Documents.Ref
	|FROM
	|	Document.CloseOfCashRegisterDay AS Documents
	|WHERE
	|	Documents.Date >= &qPeriodFrom
	|	AND Documents.Date <= &qPeriodTo
	|	AND (NOT &qHotelIsEmpty
	|				AND (Documents.CashRegister.Hotel = &qHotel
	|					OR Documents.CashRegister.Hotel = &qEmptyHotel)
	|			OR &qHotelIsEmpty)
	|	AND (NOT &qCompanyIsEmpty
	|				AND Documents.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|
	|ORDER BY
	|	Documents.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	
	// Delete documents being found
	DeleteDocuments(vQryRes);
EndProcedure // DeleteCloseOfCashRegisterDayDocuments

// -----------------------------------------------------------------------------
Procedure DeleteCloseOfPeriodDocuments()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Documents.Ref
	|FROM
	|	Document.CloseOfPeriod AS Documents
	|WHERE
	|	Documents.Date >= &qPeriodFrom
	|	AND Documents.Date <= &qPeriodTo
	|	AND (NOT &qHotelIsEmpty
	|				AND Documents.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (NOT &qCompanyIsEmpty
	|				AND Documents.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|
	|ORDER BY
	|	Documents.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	
	// Delete documents being found
	DeleteDocuments(vQryRes);
EndProcedure // DeleteCloseOfPeriodDocuments

// -----------------------------------------------------------------------------
Procedure DeleteCustomerAdvanceDistributionDocuments()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Documents.Ref
	|FROM
	|	Document.CustomerAdvanceDistribution AS Documents
	|WHERE
	|	Documents.Date >= &qPeriodFrom
	|	AND Documents.Date <= &qPeriodTo
	|	AND (NOT &qHotelIsEmpty
	|				AND Documents.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (NOT &qCompanyIsEmpty
	|				AND Documents.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|
	|ORDER BY
	|	Documents.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	
	// Delete documents being found
	DeleteDocuments(vQryRes);
EndProcedure // DeleteCustomerAdvanceDistributionDocuments

// -----------------------------------------------------------------------------
Procedure DeleteCustomerPaymentDocuments()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Documents.Ref
	|FROM
	|	Document.CustomerPayment AS Documents
	|WHERE
	|	Documents.Date >= &qPeriodFrom
	|	AND Documents.Date <= &qPeriodTo
	|	AND (NOT &qHotelIsEmpty
	|				AND Documents.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (NOT &qCompanyIsEmpty
	|				AND Documents.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|
	|ORDER BY
	|	Documents.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	
	// Delete documents being found
	DeleteDocuments(vQryRes);
EndProcedure // DeleteCustomerPaymentDocuments

// -----------------------------------------------------------------------------
Procedure DeleteEmployeeOperationDocuments()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Documents.Ref
	|FROM
	|	Document.EmployeeOperation AS Documents
	|WHERE
	|	Documents.Date >= &qPeriodFrom
	|	AND Documents.Date <= &qPeriodTo
	|	AND (NOT &qHotelIsEmpty
	|				AND Documents.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|
	|ORDER BY
	|	Documents.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	
	// Delete documents being found
	DeleteDocuments(vQryRes);
EndProcedure // DeleteEmployeeOperationDocuments

// -----------------------------------------------------------------------------
Procedure DeleteOperationScheduleDocuments()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Documents.Ref
	|FROM
	|	Document.OperationSchedule AS Documents
	|WHERE
	|	Documents.Date >= &qPeriodFrom
	|	AND Documents.Date <= &qPeriodTo
	|	AND (NOT &qHotelIsEmpty
	|				AND Documents.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|
	|ORDER BY
	|	Documents.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	
	// Delete documents being found
	DeleteDocuments(vQryRes);
EndProcedure // DeleteOperationScheduleDocuments

// -----------------------------------------------------------------------------
Procedure DeleteFolioDocuments(pGuestsToDelete)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Documents.Ref,
	|	CustomerChargingRulesRows.ChargingFolio AS CuatomerChargingFolio,
	|	ContractChargingRulesRows.ChargingFolio AS ContractChargingFolio,
	|	HotelChargingRulesRows.ChargingFolio AS HotelChargingFolio,
	|	HotelCustomerChargingRulesRows.ChargingFolio AS HotelCustomerChargingFolio
	|FROM
	|	Document.Folio AS Documents
	|		LEFT JOIN Catalog.Customers.ChargingRules AS CustomerChargingRulesRows
	|		ON Documents.Ref = CustomerChargingRulesRows.ChargingFolio
	|		LEFT JOIN Catalog.Contracts.ChargingRules AS ContractChargingRulesRows
	|		ON Documents.Ref = ContractChargingRulesRows.ChargingFolio
	|		LEFT JOIN Catalog.Hotels.ChargingRules AS HotelChargingRulesRows
	|		ON Documents.Ref = HotelChargingRulesRows.ChargingFolio
	|		LEFT JOIN Catalog.Hotels.CustomerChargingRules AS HotelCustomerChargingRulesRows
	|		ON Documents.Ref = HotelCustomerChargingRulesRows.ChargingFolio
	|WHERE
	|	(Documents.DateTimeFrom >= &qPeriodFrom
	|				AND Documents.DateTimeFrom <= &qPeriodTo
	|			OR Documents.Date >= &qPeriodFrom
	|				AND Documents.Date <= &qPeriodTo)
	|	AND (NOT &qHotelIsEmpty
	|				AND Documents.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (NOT &qCompanyIsEmpty
	|				AND Documents.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|	AND CustomerChargingRulesRows.ChargingFolio IS NULL 
	|	AND ContractChargingRulesRows.ChargingFolio IS NULL 
	|	AND HotelChargingRulesRows.ChargingFolio IS NULL 
	|	AND HotelCustomerChargingRulesRows.ChargingFolio IS NULL 
	|
	|ORDER BY
	|	Documents.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	
	// Delete documents being found
	DeleteDocuments(vQryRes, pGuestsToDelete, "Client");
EndProcedure // DeleteFolioDocuments

// -----------------------------------------------------------------------------
Procedure DeleteForeignerRegistryRecordDocuments()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Documents.Ref
	|FROM
	|	Document.ForeignerRegistryRecord AS Documents
	|WHERE
	|	(ISNULL(Documents.ParentDoc.CheckInDate, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.ParentDoc.CheckInDate, &qEmptyDate) <= &qPeriodTo
	|			OR Documents.CheckInDate >= &qPeriodFrom
	|				AND Documents.CheckInDate <= &qPeriodTo
	|			OR Documents.Date >= &qPeriodFrom
	|				AND Documents.Date <= &qPeriodTo)
	|	AND (NOT &qHotelIsEmpty
	|				AND Documents.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (NOT &qCompanyIsEmpty
	|				AND Documents.ParentDoc.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|
	|ORDER BY
	|	Documents.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	
	// Delete documents being found
	DeleteDocuments(vQryRes);
EndProcedure // DeleteForeignerRegistryRecordDocuments

// -----------------------------------------------------------------------------
Procedure DeleteInputAccumulatingDiscountBalancesDocuments()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Documents.Ref
	|FROM
	|	Document.InputAccumulatingDiscountBalances AS Documents
	|WHERE
	|	Documents.Date >= &qPeriodFrom
	|	AND Documents.Date <= &qPeriodTo
	|	AND (NOT &qHotelIsEmpty
	|				AND Documents.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|
	|ORDER BY
	|	Documents.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	
	// Delete documents being found
	DeleteDocuments(vQryRes);
EndProcedure // DeleteInputAccumulatingDiscountBalancesDocuments

// -----------------------------------------------------------------------------
Procedure DeleteInvoiceDocuments()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Documents.Ref
	|FROM
	|	Document.ProformaInvoice AS Documents
	|WHERE
	|	Documents.Date >= &qPeriodFrom
	|	AND Documents.Date <= &qPeriodTo
	|	AND (NOT &qHotelIsEmpty
	|				AND Documents.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (NOT &qCompanyIsEmpty
	|				AND Documents.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|
	|ORDER BY
	|	Documents.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	
	// Delete documents being found
	DeleteDocuments(vQryRes);
EndProcedure // DeleteInvoiceDocuments

// -----------------------------------------------------------------------------
Procedure DeleteSettlementDocuments()
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	Documents.Ref
	|FROM
	|	Document.Settlement.Services AS Documents
	|WHERE
	|	(Documents.Ref.Date >= &qPeriodFrom
	|				AND Documents.Ref.Date <= &qPeriodTo
	|			OR ISNULL(Documents.ParentDoc.CheckInDate, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.ParentDoc.CheckInDate, &qEmptyDate) <= &qPeriodTo
	|			OR ISNULL(Documents.ParentDoc.DateTimeFrom, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.ParentDoc.DateTimeFrom, &qEmptyDate) <= &qPeriodTo
	|			OR ISNULL(Documents.Folio.DateTimeFrom, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.Folio.DateTimeFrom, &qEmptyDate) <= &qPeriodTo
	|			OR ISNULL(Documents.Folio.Date, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.Folio.Date, &qEmptyDate) <= &qPeriodTo
	|			OR ISNULL(Documents.Charge.Date, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.Charge.Date, &qEmptyDate) <= &qPeriodTo)
	|	AND (NOT &qHotelIsEmpty
	|				AND Documents.Ref.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (NOT &qCompanyIsEmpty
	|				AND Documents.Ref.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|
	|ORDER BY
	|	Documents.Ref.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	
	// Delete documents being found
	DeleteDocuments(vQryRes);
EndProcedure // DeleteSettlementDocuments

// -----------------------------------------------------------------------------
Procedure DeleteIssueHotelProductsDocuments()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Documents.Ref
	|FROM
	|	Document.IssueHotelProducts AS Documents
	|WHERE
	|	Documents.Date >= &qPeriodFrom
	|	AND Documents.Date <= &qPeriodTo
	|	AND (NOT &qHotelIsEmpty
	|				AND Documents.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (NOT &qCompanyIsEmpty
	|				AND Documents.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|
	|ORDER BY
	|	Documents.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	
	// Delete documents being found
	DeleteDocuments(vQryRes);
EndProcedure // DeleteIssueHotelProductsDocuments

// -----------------------------------------------------------------------------
Procedure DeletePaymentDocuments()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Documents.Ref
	|FROM
	|	Document.Payment AS Documents
	|WHERE
	|	(ISNULL(Documents.ParentDoc.CheckInDate, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.ParentDoc.CheckInDate, &qEmptyDate) <= &qPeriodTo
	|			OR ISNULL(Documents.ParentDoc.DateTimeFrom, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.ParentDoc.DateTimeFrom, &qEmptyDate) <= &qPeriodTo
	|			OR ISNULL(Documents.Folio.DateTimeFrom, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.Folio.DateTimeFrom, &qEmptyDate) <= &qPeriodTo
	|			OR Documents.Date >= &qPeriodFrom
	|				AND Documents.Date <= &qPeriodTo)
	|	AND (NOT &qHotelIsEmpty
	|				AND Documents.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (NOT &qCompanyIsEmpty
	|				AND Documents.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|
	|ORDER BY
	|	Documents.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	
	// Delete documents being found
	DeleteDocuments(vQryRes);
EndProcedure // DeletePaymentDocuments

// -----------------------------------------------------------------------------
Procedure DeleteReturnDocuments()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Documents.Ref
	|FROM
	|	Document.Return AS Documents
	|WHERE
	|	(ISNULL(Documents.ParentDoc.CheckInDate, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.ParentDoc.CheckInDate, &qEmptyDate) <= &qPeriodTo
	|			OR ISNULL(Documents.ParentDoc.DateTimeFrom, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.ParentDoc.DateTimeFrom, &qEmptyDate) <= &qPeriodTo
	|			OR ISNULL(Documents.Folio.DateTimeFrom, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.Folio.DateTimeFrom, &qEmptyDate) <= &qPeriodTo
	|			OR Documents.Date >= &qPeriodFrom
	|				AND Documents.Date <= &qPeriodTo)
	|	AND (NOT &qHotelIsEmpty
	|				AND Documents.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (NOT &qCompanyIsEmpty
	|				AND Documents.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|
	|ORDER BY
	|	Documents.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	
	// Delete documents being found
	DeleteDocuments(vQryRes);
EndProcedure // DeleteReturnDocuments

// -----------------------------------------------------------------------------
Procedure DeletePreauthorisationDocuments()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Documents.Ref
	|FROM
	|	Document.Preauthorisation AS Documents
	|WHERE
	|	(ISNULL(Documents.ParentDoc.CheckInDate, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.ParentDoc.CheckInDate, &qEmptyDate) <= &qPeriodTo
	|			OR ISNULL(Documents.ParentDoc.DateTimeFrom, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.ParentDoc.DateTimeFrom, &qEmptyDate) <= &qPeriodTo
	|			OR ISNULL(Documents.Folio.DateTimeFrom, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.Folio.DateTimeFrom, &qEmptyDate) <= &qPeriodTo
	|			OR Documents.Date >= &qPeriodFrom
	|				AND Documents.Date <= &qPeriodTo)
	|	AND (NOT &qHotelIsEmpty
	|				AND Documents.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (NOT &qCompanyIsEmpty
	|				AND Documents.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|
	|ORDER BY
	|	Documents.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	
	// Delete documents being found
	DeleteDocuments(vQryRes);
EndProcedure // DeletePreauthorisationDocuments

// -----------------------------------------------------------------------------
Procedure DeleteRecordPhoneCallDocuments()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Documents.Ref
	|FROM
	|	Document.RecordPhoneCall AS Documents
	|WHERE
	|	Documents.Date >= &qPeriodFrom
	|	AND Documents.Date <= &qPeriodTo
	|	AND (NOT &qHotelIsEmpty
	|				AND Documents.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (NOT &qCompanyIsEmpty
	|				AND Documents.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|
	|ORDER BY
	|	Documents.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	
	// Delete documents being found
	DeleteDocuments(vQryRes);
EndProcedure // DeleteRecordPhoneCallDocuments

// -----------------------------------------------------------------------------
Procedure DeleteRecordRoomServiceDocuments()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Documents.Ref
	|FROM
	|	Document.RecordRoomService AS Documents
	|WHERE
	|	Documents.Date >= &qPeriodFrom
	|	AND Documents.Date <= &qPeriodTo
	|	AND (NOT &qHotelIsEmpty
	|				AND Documents.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (NOT &qCompanyIsEmpty
	|				AND Documents.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|
	|ORDER BY
	|	Documents.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	
	// Delete documents being found
	DeleteDocuments(vQryRes);
EndProcedure // DeleteRecordRoomServiceDocuments

// -----------------------------------------------------------------------------
Procedure DeleteServiceRegistrationDocuments()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Documents.Ref
	|FROM
	|	Document.ServiceRegistration AS Documents
	|WHERE
	|	Documents.Date >= &qPeriodFrom
	|	AND Documents.Date <= &qPeriodTo
	|	AND (NOT &qHotelIsEmpty
	|				AND Documents.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (NOT &qCompanyIsEmpty
	|				AND (Documents.ParentDoc.Company = &qCompany
	|					OR Documents.Folio.Company = &qCompany)
	|			OR &qCompanyIsEmpty)
	|
	|ORDER BY
	|	Documents.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	
	// Delete documents being found
	DeleteDocuments(vQryRes);
EndProcedure // DeleteServiceRegistrationDocuments

// -----------------------------------------------------------------------------
Procedure DeleteRoomInterfaceStatusDocuments()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Documents.Ref
	|FROM
	|	Document.RoomInterfaceStatus AS Documents
	|WHERE
	|	(Documents.Date >= &qPeriodFrom
	|				AND Documents.Date <= &qPeriodTo
	|			OR ISNULL(Documents.ParentDoc.CheckInDate, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.ParentDoc.CheckInDate, &qEmptyDate) <= &qPeriodTo)
	|	AND (NOT &qHotelIsEmpty
	|				AND Documents.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (NOT &qCompanyIsEmpty
	|				AND Documents.ParentDoc.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|
	|ORDER BY
	|	Documents.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	
	// Delete documents being found
	DeleteDocuments(vQryRes);
EndProcedure // DeleteRoomInterfaceStatusDocuments

// -----------------------------------------------------------------------------
Procedure DeleteSMSDeliveryDocuments()
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	Documents.Ref
	|FROM
	|	Document.SMSDelivery.Receivers AS Documents
	|WHERE
	|	(Documents.Ref.Date >= &qPeriodFrom
	|				AND Documents.Ref.Date <= &qPeriodTo
	|			OR ISNULL(Documents.ClientDoc.CheckInDate, &qEmptyDate) >= &qPeriodFrom
	|				AND ISNULL(Documents.ClientDoc.CheckInDate, &qEmptyDate) <= &qPeriodTo)
	|	AND (NOT &qHotelIsEmpty
	|				AND Documents.Ref.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (NOT &qCompanyIsEmpty
	|				AND Documents.ClientDoc.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|
	|ORDER BY
	|	Documents.Ref.PointInTime";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQryRes = vQry.Execute().Select(QueryResultIteration.Linear);
	
	// Delete documents being found
	DeleteDocuments(vQryRes);
EndProcedure // DeleteSMSDeliveryDocuments
