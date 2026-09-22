
#Region Public

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
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(AccountingDate) Then
		If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.AccountingDate) Then
			AccountingDate = Hotel.AccountingDate;
		Else
			AccountingDate = BegOfDay(CurrentSessionDate()) - 24*3600;
		EndIf;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	pmDoNightAuditPrecheck(pIsInteractive);
EndProcedure // pmRun

// -----------------------------------------------------------------------------
Procedure pmDoNightAuditPrecheck(pIsInteractive = False, pSpreadsheet = Undefined) Export    
	vFuncName = NStr("en='DataProcessor.DoNightAuditPrecheck';ru='Обработка.ПодготовкаКНочномуАудиту';de='DataProcessor.DoNightAuditPrecheck'");
	
	WriteLogEvent(vFuncName, EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'"));
	
	// Check attributes
	If Not ValueIsFilled(Hotel) Then
		Raise NStr("en='Hotel should be filled!';ru='Не указана гостиница!';de='Das Hotel ist nicht angegeben!'");
	EndIf;
	If Not ValueIsFilled(AccountingDate) Then
		Raise NStr("en='Accounting date should be filled!';ru='Не указана дата!';de='Das Datum ist nicht angegeben!'");
	EndIf;
	
	// Get and fill workstation print form settings
	vShowThisForm = False;
	If pIsInteractive Then
		vShowThisForm = True;
	EndIf;
	
	// Get spreadsheet document
	vFrm = Undefined;
	vSpreadsheet = Undefined;
	If pSpreadsheet = Undefined Then
		vSpreadsheet = New SpreadsheetDocument();
		#IF CLIENT THEN
			If vShowThisForm Then
				vFrm = GetForm("DataProcessor.DoNightAuditPrecheck.Form.tcForm");
				vSpreadsheet = vFrm.Spreadsheet;
			EndIf;
		#ENDIF
	Else
		vSpreadsheet = pSpreadsheet; 
	EndIf;
	
	// Do some initialization
	vTemplate = GetTemplate("Template");
	
	// Print report header
	vHeader = vTemplate.GetArea("Header");
	vHeader.Parameters.mAccountingDate = Format(AccountingDate, "DF=dd.MM.yyyy");
	vHeader.Parameters.mHotel = Hotel;
	vSpreadsheet.Put(vHeader);
	
	// 1. Check room rates
	If CompareCheckInAndReservationRoomRates Then
		WriteLogEvent(vFuncName, EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Check if accommodation and reservation room rates are the same...';ru='Проверяем совпадение тарифов в брони и размещении...';de='Wir überprüfen die Übereinstimmung der Tarife in der Buchung und der Belegung...'"));
		vDocs = GetCompareCheckInAndReservationRoomRates();
		OutputCompareCheckInAndReservationRoomRates(vSpreadsheet, vTemplate, vDocs);
	Else
		OutputCompareCheckInAndReservationRoomRates(vSpreadsheet, vTemplate, Undefined);
	EndIf;
	
	// 2. Check room revenue services
	If CheckRoomRevenueServices Then
		WriteLogEvent(vFuncName, EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Check room revenue services for in-house guests...';ru='Проверяем наличие услуг проживания у всех гостей...';de='Wir überprüfen das Vorhandensein von Aufenthaltsleistungen bei allen Gästen...'"));
		vDocs = GetAccommodationsWithoutRoomRevenueServices();
		OutputAccommodationsWithoutRoomRevenueServices(vSpreadsheet, vTemplate, vDocs);
	Else
		OutputAccommodationsWithoutRoomRevenueServices(vSpreadsheet, vTemplate, Undefined);
	EndIf;
	
	// 3. Check accommodation templates
	If CheckAccommodationTemplates Then
		WriteLogEvent(vFuncName, EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Check if in-house guests confirm to accommodation templates allowed...';ru='Проверяем проживающих гостей на разрешенные шаблоны размещения...';de='Wir überprüfen Hotelgäste auf erlaubte Vorlagen der Unterbringungen...'"));
		vDocs = GetRoomsWithoutAccommodationTemplates();
		OutputRoomsWithoutAccommodationTemplates(vSpreadsheet, vTemplate, vDocs);
	Else
		OutputRoomsWithoutAccommodationTemplates(vSpreadsheet, vTemplate, Undefined);
	EndIf;
	
	// 4. Check operation times
	If CheckAccommodationOperationTimes Then
		WriteLogEvent(vFuncName, EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Check if check-in and check-out operations were done in time...';ru='Проверяем заезды и выезды на своевременность проведения операций с гостями...';de='Wir überprüfen die Ein- und Auszuge auf Rechtzeitigkeit der Durchführung der Aktion mit den Gästen...'"));
		vDocs = GetNotInTimeOperations();
		OutputNotInTimeOperations(vSpreadsheet, vTemplate, vDocs);
	Else
		OutputNotInTimeOperations(vSpreadsheet, vTemplate, Undefined);
	EndIf;
	
	// 5. Check expected check-out guests
	If CheckGuestsWithExpectedCheckOut Then
		WriteLogEvent(NStr("en='DataProcessor.DoNightAuditPrecheck';ru='Обработка.ПодготовкаКНочномуАудиту';de='DataProcessor.DoNightAuditPrecheck'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Check if all expected for check-out guests were checked-out...';ru='Проверяем наличие не выселенных и не продленных гостей...';de='Wir überprüfen das Vorhandensein von Gästen, die nicht ausgezogen sind und nichtverlängerten Gästen...'"));
		vDocs = GetGuestsWithExpectedCheckOut();
		OutputGuestsWithExpectedCheckOut(vSpreadsheet, vTemplate, vDocs);
	Else
		OutputGuestsWithExpectedCheckOut(vSpreadsheet, vTemplate, Undefined);
	EndIf;
	
	// 6. Check no-show reservations
	If CheckNoShowReservations Then
		WriteLogEvent(vFuncName, EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Check if no show reservations do exist...';ru='Проверяем наличие незаехавшей брони...';de='Wir überprüfen das Vorhandensein der nichtangereisten Buchung...'"));
		vDocs = GetNoShowReservations();
		OutputNoShowReservations(vSpreadsheet, vTemplate, vDocs);
	Else
		OutputNoShowReservations(vSpreadsheet, vTemplate, Undefined);
	EndIf;
	
	// 7. Check foreigners without registry records
	If CheckForeignerRegistryRecords Then
		WriteLogEvent(NStr("en='DataProcessor.DoNightAuditPrecheck';ru='Обработка.ПодготовкаКНочномуАудиту';de='DataProcessor.DoNightAuditPrecheck'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Check if registry records were added for foreigner guests...';ru='Проверяем наличие у иностранных гостей записей в журнал регистрации иностранцев...';de='Wir überprüfen das Vorhandensein von Einträgen ins Registrierungsheft bei Ausländern...'"));
		vDocs = GetForeignerGuestsWithoutRegistryRecords();
		OutputForeignerGuestsWithoutRegistryRecords(vSpreadsheet, vTemplate, vDocs);
	Else
		OutputForeignerGuestsWithoutRegistryRecords(vSpreadsheet, vTemplate, Undefined);
	EndIf;
	
	// 8. Check client identification document scans availability 
	If CheckClientIdentificationDocumentScans Then
		WriteLogEvent(vFuncName, EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Check if guest identification document scans are available...';ru='Проверяем наличие у гостей отсканированных документов удостоверяющих личность...';de='Wir überprüfen das Vorhandensein von gescannten Identitätsnachweisen bei den Gästen...'"));
		vDocs = GetGuestsWithoutScans();
		OutputGuestsWithoutScans(vSpreadsheet, vTemplate, vDocs);
	Else
		OutputGuestsWithoutScans(vSpreadsheet, vTemplate, Undefined);
	EndIf;
	
	// Print report footer
	vFooter = vTemplate.GetArea("Footer");
	vFooter.Parameters.mEmployee = SessionParameters.CurrentUser;
	vFooter.Parameters.mDate = Format(CurrentSessionDate(), "DF='dd.MM.yyyy HH:mm'");
	vSpreadsheet.Put(vFooter);
	
	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Landscape);
	// Check authorities
	cmSetSpreadsheetProtection(vSpreadsheet);
	// Set report header and footer
	cmApplyReportFooter(vSpreadsheet);
	
	vFileName = NStr("en='Night_audit_preparation_checks';ru='Подготовка_к_ночному_аудиту_';de='Vorbereitung_auf_das_Nachtaudit_'") + Format(AccountingDate, "DF=yyyyMMdd") + ".pdf";
	
	// Send report by e-mail
	If Not IsBlankString(EMail) Then
		vSubject = NStr("en='Night audit preparation checks at ';ru='Подготовка к ночному аудиту от ';de='Vorbereitung auf das Nacht-Audit '") + Format(AccountingDate, "DF=dd.MM.yyyy");
		vFullFileName = cmGetFullFileName(vFileName, TempFilesDir());
		vFileType = SpreadsheetDocumentFileType.PDF;
		vSpreadsheet.Write(vFullFileName, vFileType);
		vFilesMap = New Map;
		vFilesMap.Insert(vFileName, vFullFileName);
		JobsScheduled.cmSendFilesByEMail(vSubject, vSubject, TrimAll(EMail), vFilesMap, , Not pIsInteractive);		
		DeleteFiles(vFullFileName);
	EndIf;
	
	#IF CLIENT THEN
		If vShowThisForm And vFrm <> Undefined Then
			ValueToFormData(ThisObject, vFrm.Object);
			vFrm.Open();
		EndIf;
	#ENDIF

	WriteLogEvent(vFuncName, EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'"));
EndProcedure // pmDoNightAuditPrecheck

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetCompareCheckInAndReservationRoomRates()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.Hotel = &qHotel
	|	AND Accommodation.CheckInDate >= &qPeriodFrom
	|	AND Accommodation.CheckInDate <= &qPeriodTo
	|	AND Accommodation.IsByReservation
	|	AND (Accommodation.Reservation.RoomRate <> Accommodation.RoomRate OR
	|		 Accommodation.Reservation.Discount <> Accommodation.Discount OR
	|		 Accommodation.Reservation.ClientType <> Accommodation.ClientType)
	|
	|ORDER BY
	|	Accommodation.GuestGroup.Code,
	|	Accommodation.Room.SortCode,
	|	Accommodation.CheckInDate,
	|	Accommodation.AccommodationType.SortCode,
	|	Accommodation.Guest.Description";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qPeriodFrom", BegOfDay(AccountingDate));
	vQry.SetParameter("qPeriodTo", EndOfDay(AccountingDate));
	vDocs = vQry.Execute().Unload();
	Return vDocs;
EndFunction // GetCompareCheckInAndReservationRoomRates 

// -----------------------------------------------------------------------------
Procedure OutputCompareCheckInAndReservationRoomRates(pSpreadsheet, pTemplate, pDocs)
	// Get areas
	vHeader = pTemplate.GetArea("CompareCheckInAndReservationRoomRatesHeader");
	vRow = pTemplate.GetArea("CompareCheckInAndReservationRoomRatesRow");
	vFooter = pTemplate.GetArea("CompareCheckInAndReservationRoomRatesFooter");
	vNothingFoundFooter = pTemplate.GetArea("CompareCheckInAndReservationRoomRatesNothingFoundFooter");
	vSkippedFooter = pTemplate.GetArea("CompareCheckInAndReservationRoomRatesSkippedFooter");
	
	// Print header
	pSpreadsheet.Put(vHeader);
	
	// Check docs found
	If pDocs <> Undefined Then
		If pDocs.Count() > 0 Then
			// Print each document found
			For Each vDocsRow In pDocs Do
				vDocRef = vDocsRow.Ref;
				
				vRow.Parameters.mIndex = Format(pDocs.IndexOf(vDocsRow) + 1, "ND=10; NFD=0; NG=");
				vRow.Parameters.mGuestGroup = vDocRef.GuestGroup;
				vRow.Parameters.mCustomer = vDocRef.Customer;
				vRow.Parameters.mRoom = vDocRef.Room;
				vRow.Parameters.mGuest = vDocRef.Guest;
				vRow.Parameters.mRoomType = TrimAll(vDocRef.RoomType.Code);
				vRow.Parameters.mAccommodationType = vDocRef.AccommodationType;
				vRow.Parameters.mCheckInDate = Format(vDocRef.CheckInDate, "DF='dd.MM.yyyy HH:mm'");
				vRow.Parameters.mCheckOutDate = Format(vDocRef.CheckOutDate, "DF='dd.MM.yyyy HH:mm'");
				vRow.Parameters.mRemarks = "";
				If vDocRef.Reservation.RoomRate <> vDocRef.RoomRate Then
					vRow.Parameters.mRemarks = vRow.Parameters.mRemarks + NStr("en='Room rate ';ru='Тариф ';de='Tarif '") + TrimAll(vDocRef.Reservation.RoomRate) + " -> " + TrimAll(vDocRef.RoomRate) + Chars.LF;
				EndIf;
				If vDocRef.Reservation.Discount <> vDocRef.Discount Then
					vRow.Parameters.mRemarks = vRow.Parameters.mRemarks + NStr("en='Discount ';ru='Скидка ';de='Preisnachlass '") + TrimAll(vDocRef.Reservation.Discount) + "% -> " + TrimAll(vDocRef.Discount) + "%" + Chars.LF;
				EndIf;
				If vDocRef.Reservation.ClientType <> vDocRef.ClientType Then
					vRow.Parameters.mRemarks = vRow.Parameters.mRemarks + NStr("en='Client type ';ru='Тип клиента ';de='Kundentyp '") + TrimAll(vDocRef.Reservation.ClientType) + " -> " + TrimAll(vDocRef.ClientType) + Chars.LF;
				EndIf;
				vRow.Parameters.mRemarks = vRow.Parameters.mRemarks + TrimAll(vDocRef.Remarks);
				vRow.Parameters.mRemarks = TrimAll(vRow.Parameters.mRemarks);
				vRow.Parameters.mDoc = vDocRef;
				
				// Print row
				pSpreadsheet.Put(vRow);
			EndDo;
			
			// Print footer
			vFooter.Parameters.mCount = Format(pDocs.Count(), "ND=10; NFD=0; NZ=; NG=");
			pSpreadsheet.Put(vFooter);
		Else
			// Print nothing found footer
			pSpreadsheet.Put(vNothingFoundFooter);
		EndIf;
	Else
		// Print check was skipped footer
		pSpreadsheet.Put(vSkippedFooter);
	EndIf;
EndProcedure // OutputCompareCheckInAndReservationRoomRates

// -----------------------------------------------------------------------------
Function GetAccommodationsWithoutRoomRevenueServices()
	// Get in-house accommodations without room revenue services
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref AS Ref,
	|	SalesMovements.Recorder AS Charge
	|FROM
	|	Document.Accommodation AS Accommodation
	|		LEFT JOIN AccumulationRegister.Sales AS SalesMovements
	|		ON Accommodation.Ref = SalesMovements.ParentDoc
	|			AND (SalesMovements.AccountingDate = &qPeriodFrom)
	|			AND (SalesMovements.Recorder.IsRoomRevenue)
	|			AND (SalesMovements.Recorder.IsInPrice)
	|WHERE
	|	Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.Hotel = &qHotel
	|	AND Accommodation.CheckInDate < &qPeriodTo
	|	AND Accommodation.CheckOutDate > &qPeriodTo
	|	AND (Accommodation.RoomRate.RateChargeDirection <> VALUE(Enum.RateChargeDirections.MergeToTheMainRoomGuest)
	|			OR Accommodation.RoomRate.RateChargeDirection = VALUE(Enum.RateChargeDirections.MergeToTheMainRoomGuest)
	|				AND Accommodation.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef))
	|	AND NOT Accommodation.RoomType.IsVirtual
	|	AND NOT Accommodation.Room.IsVirtual
	|	AND SalesMovements.Recorder IS NULL
	|
	|ORDER BY
	|	Accommodation.GuestGroup.Code,
	|	Accommodation.Room.SortCode,
	|	Accommodation.CheckInDate,
	|	Accommodation.AccommodationType.SortCode,
	|	Accommodation.Guest.Description";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qPeriodFrom", BegOfDay(AccountingDate));
	vQry.SetParameter("qPeriodTo", EndOfDay(AccountingDate));
	vDocs = vQry.Execute().Unload();
	Return vDocs;
EndFunction // GetAccommodationsWithoutRoomRevenueServices 

// -----------------------------------------------------------------------------
Procedure OutputAccommodationsWithoutRoomRevenueServices(pSpreadsheet, pTemplate, pDocs)
	// Get areas
	vHeader = pTemplate.GetArea("CheckRoomRevenueServicesHeader");
	vRow = pTemplate.GetArea("CheckRoomRevenueServicesRow");
	vFooter = pTemplate.GetArea("CheckRoomRevenueServicesFooter");
	vNothingFoundFooter = pTemplate.GetArea("CheckRoomRevenueServicesNothingFoundFooter");
	vSkippedFooter = pTemplate.GetArea("CheckRoomRevenueServicesSkippedFooter");
	
	// Print header
	pSpreadsheet.Put(vHeader);
	
	// Check docs found
	If pDocs <> Undefined Then
		If pDocs.Count() > 0 Then
			// Print each document found
			For Each vDocsRow In pDocs Do
				vDocRef = vDocsRow.Ref;
				
				vRow.Parameters.mIndex = Format(pDocs.IndexOf(vDocsRow) + 1, "ND=10; NFD=0; NG=");
				vRow.Parameters.mGuestGroup = vDocRef.GuestGroup;
				vRow.Parameters.mCustomer = vDocRef.Customer;
				vRow.Parameters.mRoom = vDocRef.Room;
				vRow.Parameters.mGuest = vDocRef.Guest;
				vRow.Parameters.mRoomType = TrimAll(vDocRef.RoomType.Code);
				vRow.Parameters.mAccommodationType = vDocRef.AccommodationType;
				vRow.Parameters.mCheckInDate = Format(vDocRef.CheckInDate, "DF='dd.MM.yyyy HH:mm'");
				vRow.Parameters.mCheckOutDate = Format(vDocRef.CheckOutDate, "DF='dd.MM.yyyy HH:mm'");
				vRow.Parameters.mRemarks = TrimAll(TrimAll(vDocRef.RoomRate) + Chars.LF + TrimAll(vDocRef.Remarks));
				vRow.Parameters.mDoc = vDocRef;
				
				// Print row
				pSpreadsheet.Put(vRow);
			EndDo;
			
			// Print footer
			vFooter.Parameters.mCount = Format(pDocs.Count(), "ND=10; NFD=0; NZ=; NG=");
			pSpreadsheet.Put(vFooter);
		Else
			// Print nothing found footer
			pSpreadsheet.Put(vNothingFoundFooter);
		EndIf;
	Else
		// Print check was skipped footer
		pSpreadsheet.Put(vSkippedFooter);
	EndIf;
EndProcedure // OutputAccommodationsWithoutRoomRevenueServices

// -----------------------------------------------------------------------------
Function DoAccommodationTemplateCheck(pOneRoomDocs, pRoomType)
	vAccTemplates = cmGetAccommodationTemplatesValidForRoomType(pRoomType);
	If vAccTemplates.Count() > 0 Then
		vFittedTemplate = Undefined;
		vProbeAccTypesList = New ValueList();
		For Each vOneRoomDocsItem In pOneRoomDocs Do
			vProbeAccTypesList.Add(vOneRoomDocsItem.Value.AccommodationType);
		EndDo;
		For Each vAccTemplatesItem In vAccTemplates Do
			vFitted = True;
			vTemplate = vAccTemplatesItem.Value;
			vTemplateAccTypes = vTemplate.AccommodationTypes;
			If vTemplate.AccommodationTypes.Count() <> vProbeAccTypesList.Count() Then
				vFitted = False;
				Continue;
			EndIf;
			For Each vAccTypeItem In vProbeAccTypesList Do
				If vTemplateAccTypes.Find(vAccTypeItem.Value, "AccommodationType") = Undefined Then
					vFitted = False;
					Break;
				EndIf; 
			EndDo;
			If vFitted Then
				vFittedTemplate = vTemplate;
			 	Break;
			EndIf;
		EndDo;
		Return ValueIsFilled(vFittedTemplate);
	Else
		Return True;
	EndIf;
EndFunction // DoAccommodationTemplateCheck

// -----------------------------------------------------------------------------
Function GetRoomsWithoutAccommodationTemplates()
	// Get in-house accommodations
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref,
	|	Accommodation.Room
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.AccommodationStatus.IsInHouse
	|	AND Accommodation.Hotel = &qHotel
	|	AND Accommodation.CheckInDate < &qPeriodTo
	|	AND Accommodation.CheckOutDate > &qPeriodFrom
	|	AND NOT Accommodation.RoomType.IsVirtual
	|	AND NOT Accommodation.Room.IsVirtual
	|
	|ORDER BY
	|	Accommodation.Room.SortCode,
	|	Accommodation.CheckInDate,
	|	Accommodation.AccommodationType.SortCode,
	|	Accommodation.Guest.Description";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qPeriodFrom", BegOfDay(AccountingDate));
	vQry.SetParameter("qPeriodTo", EndOfDay(AccountingDate));
	vInHouseDocs = vQry.Execute().Unload();
	vDocs = vInHouseDocs.Copy();
	vDocs.Clear();
	// Check rooms
	vCurRoom = Undefined;
	vOneRoomDocs = New ValueList();
	For Each vInHouseDocsRow In vInHouseDocs Do
		If vCurRoom <> vInHouseDocsRow.Room Then
			If vOneRoomDocs.Count() > 0 And vCurRoom <> Undefined Then
				// Do check
				vOK = DoAccommodationTemplateCheck(vOneRoomDocs, vCurRoom.RoomType);
				If Not vOK Then
					For Each vOneRoomDocsItem In vOneRoomDocs Do
						vDocsRow = vDocs.Add();
						vDocsRow.Ref = vOneRoomDocsItem.Value;
					EndDo;
				EndIf;
			EndIf;
			vCurRoom = vInHouseDocsRow.Room;
			vOneRoomDocs.Clear();
		EndIf;
		vOneRoomDocs.Add(vInHouseDocsRow.Ref);
	EndDo;
	If vOneRoomDocs.Count() > 0 And vCurRoom <> Undefined Then
		// Do check
		vOK = DoAccommodationTemplateCheck(vOneRoomDocs, vCurRoom.RoomType);
		If Not vOK Then
			For Each vOneRoomDocsItem In vOneRoomDocs Do
				vDocsRow = vDocs.Add();
				vDocsRow.Ref = vOneRoomDocsItem.Value;
			EndDo;
		EndIf;
	EndIf;
	Return vDocs;
EndFunction // GetRoomsWithoutAccommodationTemplates

// -----------------------------------------------------------------------------
Procedure OutputRoomsWithoutAccommodationTemplates(pSpreadsheet, pTemplate, pDocs)
	// Get areas
	vHeader = pTemplate.GetArea("CheckAccommodationTemplatesHeader");
	vRow = pTemplate.GetArea("CheckAccommodationTemplatesRow");
	vFooter = pTemplate.GetArea("CheckAccommodationTemplatesFooter");
	vNothingFoundFooter = pTemplate.GetArea("CheckAccommodationTemplatesNothingFoundFooter");
	vSkippedFooter = pTemplate.GetArea("CheckAccommodationTemplatesSkippedFooter");
	
	// Print header
	pSpreadsheet.Put(vHeader);
	
	// Check docs found
	If pDocs <> Undefined Then
		If pDocs.Count() > 0 Then
			// Print each document found
			For Each vDocsRow In pDocs Do
				vDocRef = vDocsRow.Ref;
				
				vRow.Parameters.mIndex = Format(pDocs.IndexOf(vDocsRow) + 1, "ND=10; NFD=0; NG=");
				vRow.Parameters.mGuestGroup = vDocRef.GuestGroup;
				vRow.Parameters.mCustomer = vDocRef.Customer;
				vRow.Parameters.mRoom = vDocRef.Room;
				vRow.Parameters.mGuest = vDocRef.Guest;
				vRow.Parameters.mRoomType = TrimAll(vDocRef.RoomType.Code);
				vRow.Parameters.mAccommodationType = vDocRef.AccommodationType;
				vRow.Parameters.mCheckInDate = Format(vDocRef.CheckInDate, "DF='dd.MM.yyyy HH:mm'");
				vRow.Parameters.mCheckOutDate = Format(vDocRef.CheckOutDate, "DF='dd.MM.yyyy HH:mm'");
				vRow.Parameters.mRemarks = TrimAll(vDocRef.Remarks);
				vRow.Parameters.mDoc = vDocRef;
				
				// Print row
				pSpreadsheet.Put(vRow);
			EndDo;
			
			// Print footer
			vFooter.Parameters.mCount = Format(pDocs.Count(), "ND=10; NFD=0; NZ=; NG=");
			pSpreadsheet.Put(vFooter);
		Else
			// Print nothing found footer
			pSpreadsheet.Put(vNothingFoundFooter);
		EndIf;
	Else
		// Print check was skipped footer
		pSpreadsheet.Put(vSkippedFooter);
	EndIf;
EndProcedure // OutputRoomsWithoutAccommodationTemplates

// -----------------------------------------------------------------------------
Function CheckIfOperationWasDoneInTime(pDocRef, rOperation, rEmployee, rOperationTime)
	vOK = True;
	rOperation = "";
	rEmployee = Undefined;
	rOperationTime = '00010101';
	// Get document change history records
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	AccommodationChangeHistory.Period AS Period,
	|	AccommodationChangeHistory.User,
	|	AccommodationChangeHistory.Accommodation,
	|	AccommodationChangeHistory.AccommodationStatus,
	|	AccommodationChangeHistory.CheckInDate,
	|	AccommodationChangeHistory.CheckOutDate,
	|	AccommodationChangeHistory.Room
	|FROM
	|	InformationRegister.AccommodationChangeHistory AS AccommodationChangeHistory
	|WHERE
	|	AccommodationChangeHistory.Accommodation = &qAccommodation
	|	AND AccommodationChangeHistory.Period >= &qPeriodFrom
	|	AND AccommodationChangeHistory.AccommodationStatus = &qAccommodationStatus
	|	AND AccommodationChangeHistory.Room = &qRoom
	|	AND AccommodationChangeHistory.CheckInDate = &qCheckInDate
	|	AND AccommodationChangeHistory.CheckOutDate = &qCheckOutDate
	|
	|ORDER BY
	|	Period";
	vQry.SetParameter("qAccommodation", pDocRef);
	vQry.SetParameter("qPeriodFrom", BegOfDay(AccountingDate));
	vQry.SetParameter("qAccommodationStatus", pDocRef.AccommodationStatus);
	vQry.SetParameter("qRoom", pDocRef.Room);
	vQry.SetParameter("qAccommodationType", pDocRef.AccommodationType);
	vQry.SetParameter("qCheckInDate", pDocRef.CheckInDate);
	vQry.SetParameter("qCheckOutDate", pDocRef.CheckOutDate);
	vHistoryRecords = vQry.Execute().Unload();
	For Each vHistoryRecordsRow In vHistoryRecords Do
		rEmployee = vHistoryRecordsRow.User;
		rOperationTime = vHistoryRecordsRow.Period;
		If ValueIsFilled(pDocRef.AccommodationStatus) And pDocRef.AccommodationStatus.IsCheckOut And 
			pDocRef.CheckOutDate >= BegOfDay(AccountingDate) And pDocRef.CheckOutDate <= EndOfDay(AccountingDate) Then
			rOperation = NStr("de='Abreise';en='Check-out';ru='Выселение'");
			vDelay = rOperationTime - pDocRef.CheckOutDate;
			vDelay = ?(vDelay < 0, -vDelay, vDelay);
			If vDelay > 3600 Then
				vOK = False;
			EndIf;
		ElsIf ValueIsFilled(pDocRef.AccommodationStatus) And pDocRef.AccommodationStatus.IsCheckIn And 
		      pDocRef.CheckInDate >= BegOfDay(AccountingDate) And pDocRef.CheckInDate <= EndOfDay(AccountingDate) Then
			rOperation = NStr("en='Check-in';ru='Заезд';de='Anreise'");
			vDelay = rOperationTime - pDocRef.CheckInDate;
			vDelay = ?(vDelay < 0, -vDelay, vDelay);
			If vDelay > 3600 Then
				vOK = False;
			EndIf;
		EndIf;
		Break;
	EndDo;
	Return vOK;
EndFunction // CheckIfOperationWasDoneInTime

// -----------------------------------------------------------------------------
Function GetNotInTimeOperations()
	// Get check-in or check-out accommodations
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref,
	|	&qEmptyString AS Operation,
	|	&qEmptyDate AS OperationTime,
	|	&qEmptyEmployee AS Employee
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.Hotel = &qHotel
	|	AND (Accommodation.CheckInDate >= &qPeriodFrom
	|				AND Accommodation.CheckInDate <= &qPeriodTo
	|				AND Accommodation.AccommodationStatus.IsInHouse
	|				AND Accommodation.AccommodationStatus.IsCheckIn
	|			OR Accommodation.CheckOutDate >= &qPeriodFrom
	|				AND Accommodation.CheckOutDate <= &qPeriodTo
	|				AND Accommodation.AccommodationStatus.IsCheckOut)
	|	AND NOT Accommodation.RoomType.IsVirtual
	|	AND NOT Accommodation.Room.IsVirtual
	|
	|ORDER BY
	|	Accommodation.Room.SortCode,
	|	Accommodation.CheckInDate,
	|	Accommodation.AccommodationType.SortCode,
	|	Accommodation.Guest.Description";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qPeriodFrom", BegOfDay(AccountingDate));
	vQry.SetParameter("qPeriodTo", EndOfDay(AccountingDate));
	vQry.SetParameter("qEmptyString", "                    ");
	vQry.SetParameter("qEmptyEmployee", Catalogs.Employees.EmptyRef());
	vQry.SetParameter("qEmptyDate", '00010101');
	vOperations = vQry.Execute().Unload();
	vDocs = vOperations.Copy();
	vDocs.Clear();
	// Check operation times
	For Each vOperationsRow In vOperations Do
		// Do check
		vOperation = "";
		vEmployee = Undefined;
		vOperationTime = '00010101';
		vOK = CheckIfOperationWasDoneInTime(vOperationsRow.Ref, vOperation, vEmployee, vOperationTime);
		If Not vOK Then
			vDocsRow = vDocs.Add();
			vDocsRow.Ref = vOperationsRow.Ref;
			vDocsRow.Operation = vOperation;
			vDocsRow.Employee = vEmployee;
			vDocsRow.OperationTime = vOperationTime;
		EndIf;
	EndDo;
	Return vDocs;
EndFunction // GetNotInTimeOperations

// -----------------------------------------------------------------------------
Procedure OutputNotInTimeOperations(pSpreadsheet, pTemplate, pDocs)
	// Get areas
	vHeader = pTemplate.GetArea("CheckNotInTimeOperationsHeader");
	vRow = pTemplate.GetArea("CheckNotInTimeOperationsRow");
	vFooter = pTemplate.GetArea("CheckNotInTimeOperationsFooter");
	vNothingFoundFooter = pTemplate.GetArea("CheckNotInTimeOperationsNothingFoundFooter");
	vSkippedFooter = pTemplate.GetArea("CheckNotInTimeOperationsSkippedFooter");
	
	// Print header
	pSpreadsheet.Put(vHeader);
	
	// Check docs found
	If pDocs <> Undefined Then
		If pDocs.Count() > 0 Then
			// Print each document found
			For Each vDocsRow In pDocs Do
				vDocRef = vDocsRow.Ref;
				
				vRow.Parameters.mIndex = Format(pDocs.IndexOf(vDocsRow) + 1, "ND=10; NFD=0; NG=");
				vRow.Parameters.mGuestGroup = vDocRef.GuestGroup;
				vRow.Parameters.mCustomer = vDocRef.Customer;
				vRow.Parameters.mRoom = vDocRef.Room;
				vRow.Parameters.mGuest = vDocRef.Guest;
				vRow.Parameters.mRoomType = TrimAll(vDocRef.RoomType.Code);
				vRow.Parameters.mAccommodationType = vDocRef.AccommodationType;
				vRow.Parameters.mCheckInDate = Format(vDocRef.CheckInDate, "DF='dd.MM.yyyy HH:mm'");
				vRow.Parameters.mCheckOutDate = Format(vDocRef.CheckOutDate, "DF='dd.MM.yyyy HH:mm'");
				vRow.Parameters.mRemarks = TrimAll(vDocsRow.Operation) + " " + Format(vDocsRow.OperationTime, "DF='dd.MM.yyyy HH:mm'") + " " + TrimAll(vDocsRow.Employee);
				vRow.Parameters.mDoc = vDocRef;
				
				// Print row
				pSpreadsheet.Put(vRow);
			EndDo;
			
			// Print footer
			vFooter.Parameters.mCount = Format(pDocs.Count(), "ND=10; NFD=0; NZ=; NG=");
			pSpreadsheet.Put(vFooter);
		Else
			// Print nothing found footer
			pSpreadsheet.Put(vNothingFoundFooter);
		EndIf;
	Else
		// Print check was skipped footer
		pSpreadsheet.Put(vSkippedFooter);
	EndIf;
EndProcedure // OutputNotInTimeOperations

// -----------------------------------------------------------------------------
Function GetGuestsWithExpectedCheckOut()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.AccommodationStatus.IsInHouse
	|	AND Accommodation.Hotel = &qHotel
	|	AND Accommodation.CheckOutDate <= &qPeriodTo
	|
	|ORDER BY
	|	Accommodation.GuestGroup.Code,
	|	Accommodation.Room.SortCode,
	|	Accommodation.CheckInDate,
	|	Accommodation.AccommodationType.SortCode,
	|	Accommodation.Guest.Description";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qPeriodFrom", BegOfDay(AccountingDate));
	vQry.SetParameter("qPeriodTo", EndOfDay(AccountingDate));
	vDocs = vQry.Execute().Unload();
	Return vDocs;
EndFunction // GetGuestsWithExpectedCheckOut 

// -----------------------------------------------------------------------------
Procedure OutputGuestsWithExpectedCheckOut(pSpreadsheet, pTemplate, pDocs)
	// Get areas
	vHeader = pTemplate.GetArea("CheckGuestsWithExpectedCheckOutHeader");
	vRow = pTemplate.GetArea("CheckGuestsWithExpectedCheckOutRow");
	vFooter = pTemplate.GetArea("CheckGuestsWithExpectedCheckOutFooter");
	vNothingFoundFooter = pTemplate.GetArea("CheckGuestsWithExpectedCheckOutNothingFoundFooter");
	vSkippedFooter = pTemplate.GetArea("CheckGuestsWithExpectedCheckOutSkippedFooter");
	
	// Print header
	pSpreadsheet.Put(vHeader);
	
	// Check docs found
	If pDocs <> Undefined Then
		If pDocs.Count() > 0 Then
			// Print each document found
			For Each vDocsRow In pDocs Do
				vDocRef = vDocsRow.Ref;
				
				vRow.Parameters.mIndex = Format(pDocs.IndexOf(vDocsRow) + 1, "ND=10; NFD=0; NG=");
				vRow.Parameters.mGuestGroup = vDocRef.GuestGroup;
				vRow.Parameters.mCustomer = vDocRef.Customer;
				vRow.Parameters.mRoom = vDocRef.Room;
				vRow.Parameters.mGuest = vDocRef.Guest;
				vRow.Parameters.mRoomType = TrimAll(vDocRef.RoomType.Code);
				vRow.Parameters.mAccommodationType = vDocRef.AccommodationType;
				vRow.Parameters.mCheckInDate = Format(vDocRef.CheckInDate, "DF='dd.MM.yyyy HH:mm'");
				vRow.Parameters.mCheckOutDate = Format(vDocRef.CheckOutDate, "DF='dd.MM.yyyy HH:mm'");
				vRow.Parameters.mRemarks = TrimAll(vDocRef.Remarks);
				vRow.Parameters.mDoc = vDocRef;
				
				// Print row
				pSpreadsheet.Put(vRow);
			EndDo;
			
			// Print footer
			vFooter.Parameters.mCount = Format(pDocs.Count(), "ND=10; NFD=0; NZ=; NG=");
			pSpreadsheet.Put(vFooter);
		Else
			// Print nothing found footer
			pSpreadsheet.Put(vNothingFoundFooter);
		EndIf;
	Else
		// Print check was skipped footer
		pSpreadsheet.Put(vSkippedFooter);
	EndIf;
EndProcedure // OutputGuestsWithExpectedCheckOut

// -----------------------------------------------------------------------------
Function GetNoShowReservations()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservation.Ref
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.Posted
	|	AND (Reservation.ReservationStatus.IsActive
	|			OR Reservation.ReservationStatus.IsPreliminary)
	|	AND Reservation.Hotel = &qHotel
	|	AND Reservation.CheckInDate <= &qPeriodTo
	|	AND (Reservation.WaitTillDate = &qEmptyDate
	|			OR Reservation.WaitTillDate <> &qEmptyDate
	|				AND Reservation.WaitTillDate <= &qPeriodTo)
	|
	|ORDER BY
	|	Reservation.GuestGroup.Code,
	|	Reservation.Room.SortCode,
	|	Reservation.Number,
	|	Reservation.CheckInDate,
	|	Reservation.AccommodationType.SortCode,
	|	Reservation.Guest.Description";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qPeriodTo", EndOfDay(AccountingDate));
	vQry.SetParameter("qEmptyDate", '00010101');
	vDocs = vQry.Execute().Unload();
	Return vDocs;
EndFunction // GetNoShowReservations 

// -----------------------------------------------------------------------------
Procedure OutputNoShowReservations(pSpreadsheet, pTemplate, pDocs)
	// Get areas
	vHeader = pTemplate.GetArea("CheckNoShowReservationsHeader");
	vRow = pTemplate.GetArea("CheckNoShowReservationsRow");
	vFooter = pTemplate.GetArea("CheckNoShowReservationsFooter");
	vNothingFoundFooter = pTemplate.GetArea("CheckNoShowReservationsNothingFoundFooter");
	vSkippedFooter = pTemplate.GetArea("CheckNoShowReservationsSkippedFooter");
	
	// Print header
	pSpreadsheet.Put(vHeader);
	
	// Check docs found
	If pDocs <> Undefined Then
		If pDocs.Count() > 0 Then
			// Print each document found
			For Each vDocsRow In pDocs Do
				vDocRef = vDocsRow.Ref;
				
				vRow.Parameters.mIndex = Format(pDocs.IndexOf(vDocsRow) + 1, "ND=10; NFD=0; NG=");
				vRow.Parameters.mGuestGroup = vDocRef.GuestGroup;
				vRow.Parameters.mCustomer = vDocRef.Customer;
				vRow.Parameters.mRoom = vDocRef.Room;
				vRow.Parameters.mGuest = vDocRef.Guest;
				vRow.Parameters.mRoomType = TrimAll(vDocRef.RoomType.Code);
				vRow.Parameters.mAccommodationType = vDocRef.AccommodationType;
				vRow.Parameters.mCheckInDate = Format(vDocRef.CheckInDate, "DF='dd.MM.yyyy HH:mm'");
				vRow.Parameters.mCheckOutDate = Format(vDocRef.CheckOutDate, "DF='dd.MM.yyyy HH:mm'");
				vRow.Parameters.mRemarks = TrimAll(TrimAll(vDocRef.ReservationStatus) + Chars.LF + TrimAll(vDocRef.Remarks));
				vRow.Parameters.mDoc = vDocRef;
				
				// Print row
				pSpreadsheet.Put(vRow);
			EndDo;
			
			// Print footer
			vFooter.Parameters.mCount = Format(pDocs.Count(), "ND=10; NFD=0; NZ=; NG=");
			pSpreadsheet.Put(vFooter);
		Else
			// Print nothing found footer
			pSpreadsheet.Put(vNothingFoundFooter);
		EndIf;
	Else
		// Print check was skipped footer
		pSpreadsheet.Put(vSkippedFooter);
	EndIf;
EndProcedure // OutputNoShowReservations

// -----------------------------------------------------------------------------
Function GetForeignerGuestsWithoutRegistryRecords()
	// Get in-house accommodations without client identification document scan 
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref,
	|	ForeignerRegistryRecords.Ref AS ForeignerRegistryRecord
	|FROM
	|	Document.Accommodation AS Accommodation
	|		LEFT JOIN Document.ForeignerRegistryRecord AS ForeignerRegistryRecords
	|		ON Accommodation.Ref = ForeignerRegistryRecords.ParentDoc
	|			AND (ForeignerRegistryRecords.Posted)
	|WHERE
	|	Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.Hotel = &qHotel
	|	AND Accommodation.Guest <> &qEmptyClient
	|	AND Accommodation.Guest.Citizenship <> Accommodation.Hotel.Citizenship
	|	AND Accommodation.CheckInDate < &qPeriodTo
	|	AND Accommodation.CheckOutDate > &qPeriodFrom
	|	AND ForeignerRegistryRecords.Ref IS NULL 
	|
	|ORDER BY
	|	Accommodation.GuestGroup.Code,
	|	Accommodation.Room.SortCode,
	|	Accommodation.CheckInDate,
	|	Accommodation.AccommodationType.SortCode,
	|	Accommodation.Guest.Description";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qPeriodFrom", BegOfDay(AccountingDate));
	vQry.SetParameter("qPeriodTo", EndOfDay(AccountingDate));
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vDocs = vQry.Execute().Unload();
	Return vDocs;
EndFunction // GetForeignerGuestsWithoutRegistryRecords 

// -----------------------------------------------------------------------------
Procedure OutputForeignerGuestsWithoutRegistryRecords(pSpreadsheet, pTemplate, pDocs)
	// Get areas
	vHeader = pTemplate.GetArea("CheckForeignerRegistryRecordsHeader");
	vRow = pTemplate.GetArea("CheckForeignerRegistryRecordsRow");
	vFooter = pTemplate.GetArea("CheckForeignerRegistryRecordsFooter");
	vNothingFoundFooter = pTemplate.GetArea("CheckForeignerRegistryRecordsNothingFoundFooter");
	vSkippedFooter = pTemplate.GetArea("CheckForeignerRegistryRecordsSkippedFooter");
	
	// Print header
	pSpreadsheet.Put(vHeader);
	
	// Check docs found
	If pDocs <> Undefined Then
		If pDocs.Count() > 0 Then
			// Print each document found
			For Each vDocsRow In pDocs Do
				vDocRef = vDocsRow.Ref;
				
				vRow.Parameters.mIndex = Format(pDocs.IndexOf(vDocsRow) + 1, "ND=10; NFD=0; NG=");
				vRow.Parameters.mGuestGroup = vDocRef.GuestGroup;
				vRow.Parameters.mCustomer = vDocRef.Customer;
				vRow.Parameters.mRoom = vDocRef.Room;
				vRow.Parameters.mGuest = vDocRef.Guest;
				vRow.Parameters.mRoomType = TrimAll(vDocRef.RoomType.Code);
				vRow.Parameters.mAccommodationType = vDocRef.AccommodationType;
				vRow.Parameters.mCheckInDate = Format(vDocRef.CheckInDate, "DF='dd.MM.yyyy HH:mm'");
				vRow.Parameters.mCheckOutDate = Format(vDocRef.CheckOutDate, "DF='dd.MM.yyyy HH:mm'");
				vRow.Parameters.mRemarks = TrimAll(vDocRef.Remarks);
				vRow.Parameters.mDoc = vDocRef;
				
				// Print row
				pSpreadsheet.Put(vRow);
			EndDo;
			
			// Print footer
			vFooter.Parameters.mCount = Format(pDocs.Count(), "ND=10; NFD=0; NZ=; NG=");
			pSpreadsheet.Put(vFooter);
		Else
			// Print nothing found footer
			pSpreadsheet.Put(vNothingFoundFooter);
		EndIf;
	Else
		// Print check was skipped footer
		pSpreadsheet.Put(vSkippedFooter);
	EndIf;
EndProcedure // OutpuForeignerGuestsWithoutRegistryRecords

// -----------------------------------------------------------------------------
Function GetGuestsWithoutScans()
	// Get in-house accommodations without client identification document scan 
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref AS Ref,
	|	ClientDataScans.Ref AS ClientDataScan
	|FROM
	|	Document.Accommodation AS Accommodation
	|		LEFT JOIN Document.ClientDataScans.ScanPictures AS ClientDataScans
	|		ON Accommodation.Guest = ClientDataScans.Ref.Guest
	|			AND (ClientDataScans.Ref.DeletionMark = FALSE)
	|WHERE
	|	Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.Hotel = &qHotel
	|	AND Accommodation.Guest <> &qEmptyClient
	|	AND Accommodation.CheckInDate < &qPeriodTo
	|	AND Accommodation.CheckOutDate > &qPeriodFrom
	|	AND ClientDataScans.Ref IS NULL
	|
	|ORDER BY
	|	Accommodation.GuestGroup.Code,
	|	Accommodation.Room.SortCode,
	|	Accommodation.CheckInDate,
	|	Accommodation.AccommodationType.SortCode,
	|	Accommodation.Guest.Description";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qPeriodFrom", BegOfDay(AccountingDate));
	vQry.SetParameter("qPeriodTo", EndOfDay(AccountingDate));
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vDocs = vQry.Execute().Unload();
	Return vDocs;
EndFunction // GetGuestsWithoutScans 

// -----------------------------------------------------------------------------
Procedure OutputGuestsWithoutScans(pSpreadsheet, pTemplate, pDocs)
	// Get areas
	vHeader = pTemplate.GetArea("CheckClientIdentificationDocumentScansHeader");
	vRow = pTemplate.GetArea("CheckClientIdentificationDocumentScansRow");
	vFooter = pTemplate.GetArea("CheckClientIdentificationDocumentScansFooter");
	vNothingFoundFooter = pTemplate.GetArea("CheckClientIdentificationDocumentScansNothingFoundFooter");
	vSkippedFooter = pTemplate.GetArea("CheckClientIdentificationDocumentScansSkippedFooter");
	
	// Print header
	pSpreadsheet.Put(vHeader);
	
	// Check docs found
	If pDocs <> Undefined Then
		If pDocs.Count() > 0 Then
			// Print each document found
			For Each vDocsRow In pDocs Do
				vDocRef = vDocsRow.Ref;
				
				vRow.Parameters.mIndex = Format(pDocs.IndexOf(vDocsRow) + 1, "ND=10; NFD=0; NG=");
				vRow.Parameters.mGuestGroup = vDocRef.GuestGroup;
				vRow.Parameters.mCustomer = vDocRef.Customer;
				vRow.Parameters.mRoom = vDocRef.Room;
				vRow.Parameters.mGuest = vDocRef.Guest;
				vRow.Parameters.mRoomType = TrimAll(vDocRef.RoomType.Code);
				vRow.Parameters.mAccommodationType = vDocRef.AccommodationType;
				vRow.Parameters.mCheckInDate = Format(vDocRef.CheckInDate, "DF='dd.MM.yyyy HH:mm'");
				vRow.Parameters.mCheckOutDate = Format(vDocRef.CheckOutDate, "DF='dd.MM.yyyy HH:mm'");
				vRow.Parameters.mRemarks = TrimAll(vDocRef.Remarks);
				vRow.Parameters.mDoc = vDocRef;
				
				// Print row
				pSpreadsheet.Put(vRow);
			EndDo;
			
			// Print footer
			vFooter.Parameters.mCount = Format(pDocs.Count(), "ND=10; NFD=0; NZ=; NG=");
			pSpreadsheet.Put(vFooter);
		Else
			// Print nothing found footer
			pSpreadsheet.Put(vNothingFoundFooter);
		EndIf;
	Else
		// Print check was skipped footer
		pSpreadsheet.Put(vSkippedFooter);
	EndIf;
EndProcedure // OutputGuestsWithoutScans
	
#EndRegion
