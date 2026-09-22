
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure Filling(pBase)
	// Fill attributes with default values
	pmFillAttributesWithDefaultValues();
	// Fill from the base
	If ValueIsFilled(pBase) Then
		If TypeOf(pBase) = Type("CatalogRef.RoomRates") Then
			If ValueIsFilled(pBase.Hotel) Then
				Hotel = pBase.Hotel;
			EndIf;
			RoomRate = pBase;
			If ValueIsFilled(Hotel) Then
				SetNewNumber(Catalogs.Hotels.pmGetPrefix(Hotel));
			EndIf;
		EndIf;
	EndIf;
EndProcedure // Filling

// -----------------------------------------------------------------------------
Procedure OnSetNewNumber(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(Hotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(Hotel);
	ElsIf ValueIsFilled(SessionParameters.CurrentHotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(SessionParameters.CurrentHotel);
	EndIf;
	If vPrefix <> "" Then
		pPrefix = vPrefix;
	EndIf;
EndProcedure // OnSetNewNumber

// -----------------------------------------------------------------------------
Procedure Posting(pCancel, pMode)
	Var vMessage, vAttributeInErr;
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// Check that posting is possible
	If pmCheckDocumentAttributes(vMessage, vAttributeInErr) Then
		Raise NStr(vMessage);
	EndIf;
	
	// Post document to the room rates information register
	vRec = RegisterRecords.RoomRates.Add();
	vRec.Period = Date;
	vRec.IsFormula = True;
	
	vRec.Hotel = Hotel;
	vRec.RoomRate = RoomRate;
	vRec.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
	vRec.PriceTag = Catalogs.PriceTags.EmptyRef();
	
	vRec.SetRoomRatePrices = Undefined;
	vRec.SetRoomRateFormulas = Ref;
	
	// Get lists of active room rates and calendar day types
	vAllRoomTypesCache = New ValueTable();
	vAllRoomTypesCache.Columns.Add("RoomType", cmGetCatalogTypeDescription("RoomTypes"));
	vAllRoomTypesCache.Columns.Add("RoomClass", cmGetCatalogTypeDescription("RoomTypeClasses"));
	vAllRoomTypesCache.Columns.Add("RoomTypes");
	
	vAllClientTypesCache = New ValueTable();
	vAllClientTypesCache.Columns.Add("ClientType", cmGetCatalogTypeDescription("ClientTypes"));
	vAllClientTypesCache.Columns.Add("ClientTypes");
	
	vAllAccommodationTypesCache = New ValueTable();
	vAllAccommodationTypesCache.Columns.Add("AccommodationType", cmGetCatalogTypeDescription("AccommodationTypes"));
	vAllAccommodationTypesCache.Columns.Add("AccommodationTypes");
	
	vAllCalendarDayTypesCache = New ValueTable();
	vAllCalendarDayTypesCache.Columns.Add("CalendarDayType", cmGetCatalogTypeDescription("CalendarDayTypes"));
	vAllCalendarDayTypesCache.Columns.Add("CalendarDayTypes");
	
	// Build working table with formulas
	vFormulas = Formulas.Unload();
	vFormulas.Columns.Add("IsDiscount", cmGetBooleanTypeDescription());
	If Discount <> 0 Or Formulas.Count() = 0 Then
		vFormulas.Clear();
		vFormulasRow = vFormulas.Add();
		vFormulasRow.IsDiscount = True;
		If Discount = 0 Then
			vFormulasRow.Multiplier = 1;
		Else
			vFormulasRow.Multiplier = Round((100 - Discount)/100, 7);
		EndIf;
	EndIf;
	
	// Post document to the room rate formulas information register
	i = 0;
	For Each vFormulasRow In vFormulas Do
		If vFormulasRow.IsDiscount Then
			// Add detailed record to the register
			i = i + 1;
			
			vFormulasRec = RegisterRecords.RoomRateFormulas.Add();
			vFormulasRec.Period = Date;
			vFormulasRec.Recorder = Ref;
			vFormulasRec.RoomRate = RoomRate;
			vFormulasRec.Hotel = Hotel;
			vFormulasRec.IsFormula = False;
			
			FillPropertyValues(vFormulasRec, vFormulasRow, , "Service, ClientType, RoomType, AccommodationType, CalendarDayType");
		Else
			// Get lists of active room types and accommodation types for this row
			vClientTypes = pmGetListOfActiveClientTypes(vFormulasRow.ClientType, vAllClientTypesCache);
			vRoomTypes = pmGetListOfActiveRoomTypes(vFormulasRow.RoomType, vFormulasRow.RoomClass, vAllRoomTypesCache);
			vAccommodationTypes = pmGetListOfActiveAccommodationTypes(vFormulasRow.AccommodationType, vAllAccommodationTypesCache);
			vCalendarDayTypes = pmGetListOfActiveCalendarDayTypes(vFormulasRow.CalendarDayType, vAllCalendarDayTypesCache);
			For Each vClientTypesRow In vClientTypes Do
				vClientType = vClientTypesRow.ClientType;
				
				For Each vRoomTypesRow In vRoomTypes Do
					vRoomType = vRoomTypesRow.RoomType;
					vRoomClass = vRoomTypesRow.RoomClass;
					
					For Each vAccommodationTypesRow In vAccommodationTypes Do
						vAccommodationType = vAccommodationTypesRow.AccommodationType;
				
						// Check permitted accommodation types for the given room type
						If ValueIsFilled(vRoomType) Then
							If vRoomType.AccommodationTypesAllowed.Count() > 0 Then
								If vRoomType.AccommodationTypesAllowed.Find(vAccommodationType) = Undefined Then
									Continue;
								EndIf;
							EndIf;
						EndIf;
						
						For Each vCalendarDayTypesRow In vCalendarDayTypes Do
							vCalendarDayType = vCalendarDayTypesRow.CalendarDayType;

							// Add detailed record to the register
							i = i + 1;
							
							vFormulasRec = RegisterRecords.RoomRateFormulas.Add();
							vFormulasRec.Period = Date;
							vFormulasRec.Recorder = Ref;
							vFormulasRec.RoomRate = RoomRate;
							vFormulasRec.Hotel = Hotel;
							vFormulasRec.IsFormula = True;
							
							FillPropertyValues(vFormulasRec, vFormulasRow, , "ClientType, RoomType, AccommodationType, CalendarDayType");
							vFormulasRec.ClientType = vClientType;
							vFormulasRec.RoomType = vRoomType;
							vFormulasRec.AccommodationType = vAccommodationType;
							vFormulasRec.CalendarDayType = vCalendarDayType;
						EndDo; // by calendar day types
					EndDo; // by accommodation types
				EndDo; // by room types
			EndDo; // by client types
		EndIf; // is discount
	EndDo; // by formulas rows
	
	// Write register records if necessary
	RegisterRecords.RoomRates.Write();
	RegisterRecords.RoomRates.Write = False;
	If i > 0 Then
		RegisterRecords.RoomRateFormulas.Write();
		RegisterRecords.RoomRateFormulas.Write = False;
	EndIf;
	
	If Modified() Then
		Write(DocumentWriteMode.Write);
	EndIf;
EndProcedure // Posting

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pWriteMode, pPostingMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	vSystemUpdateMode = False;
	If AdditionalProperties.Property("SystemUpdateMode", vSystemUpdateMode) Then
		If TypeOf(vSystemUpdateMode) = Type("Boolean") And vSystemUpdateMode Then
			Return;
		EndIf;
	EndIf;
	If Not SessionParameters.UpdateInProgress Then
		If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
			pCancel = True;
			vMessage = "en='You do not have rights to manage prices!'; de='Sie haben keine Rechte zum Bearbeiten von Preisen!'; ru='Нет прав на управление услугами и ценами!'";
			WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
			tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
		Else
			If RatesManagement.IsRoomRateInUse(Date, RoomRate) Then
				pCancel = True;
				If pWriteMode = DocumentWriteMode.UndoPosting Then
					vMessage = "en = 'You cannot delete the document, because there are already reservations using this room rate with price calculation date later than the document date.'; 
					           |de = 'Sie können das Dokument nicht löschen, da es bereits Reservierungen mit diesem Zimmerpreis gibt, deren Preisberechnungsdatum nach dem Dokumentdatum liegt.'; 
							   |ru = 'Нельзя удалять документ, т.к. уже есть бронирования использующие этот тариф с датой получения цен позже даты документа.'";
				Else
					vMessage = "en = 'It is not possible to save the document with the date %1 because there are reservations dated later. Save the document with the current time.'; 
					           |de = 'Es ist nicht möglich, das Dokument mit dem Datum %1 zu speichern, da später datierte Reservierungen vorliegen. Speichern Sie das Dokument mit der aktuellen Uhrzeit.'; 
							   |ru = 'Нельзя сохранить документ датой %1 т.к. уже есть бронирования позже этой даты. Сохраните документ текущим временем или скопируйте и сохраните изменения текущим временем.'";
					vMessage = StrTemplate(vMessage, Date);
				EndIf;
				WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
				tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure BeforeDelete(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		pCancel = True;
		vMessage = "en='You do not have rights to manage prices!'; de='Sie haben keine Rechte zum Bearbeiten von Preisen!'; ru='Нет прав на управление услугами и ценами!'";
		WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
		tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
		Return;
	EndIf;
	If SessionParameters.UpdateInProgress = False And RatesManagement.IsRoomRateInUse(Date, RoomRate) Then
		pCancel = True;
		vMessage = "en = 'You cannot delete the document, because there are already reservations using this room rate with price calculation date later than the document date.'; de = 'Sie können das Dokument nicht löschen, da es bereits Reservierungen mit diesem Zimmerpreis gibt, deren Preisberechnungsdatum nach dem Dokumentdatum liegt.'; ru = 'Нельзя удалять документ, т.к. уже есть бронирования использующие этот тариф с датой получения цен позже даты документа.'";
		WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
		tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
		Return;
	EndIf;
EndProcedure // BeforeDelete

// -----------------------------------------------------------------------------
Procedure OnCopy(pCopiedObject)
	Author = SessionParameters.CurrentUser;
	RoomRatesApproved = False;
EndProcedure // OnCopy

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel) 
	If DataExchange.Load Then
		Return;
	EndIf; 
EndProcedure // OnWrite

#EndRegion

#Region Public

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
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Procedure pmWriteToSetRoomRateFormulasChangeHistory(pPeriod, pUser) Export
	// Get channges description
	vChanges = cmGetObjectChanges(ThisObject);
	If Not IsBlankString(vChanges) Then
		// Do movement on current date
		vHistoryRec = InformationRegisters.SetRoomRateFormulasChangeHistory.CreateRecordManager();
		
		vHistoryRec.Period = pPeriod;
		vHistoryRec.SetRoomRateFormulas = Ref;
		
		FillPropertyValues(vHistoryRec, ThisObject);
		vHistoryRec.Changes = vChanges;
		
		vHistoryRec.User = pUser;
		
		// Store tabular parts
		vFormulas = New ValueStorage(Formulas.Unload());
		vHistoryRec.Formulas = vFormulas;
		
		// Write record
		vHistoryRec.Write(True);    
		
		// User activity history
		InformationRegisters.UserActionsHistory.WriteUserActivityRecord(Ref, vChanges, Hotel, pUser, pPeriod);
	EndIf;
EndProcedure // pmWriteToSetRoomRateFormulasChangeHistory

// -----------------------------------------------------------------------------
Function pmGetPreviousObjectState(pPeriod) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	*
	|FROM
	|	InformationRegister.SetRoomRateFormulasChangeHistory.SliceLast(&qPeriod, SetRoomRateFormulas = &qDoc) AS SetRoomRateFormulasChangeHistory";
	vQry.SetParameter("qPeriod", pPeriod);
	vQry.SetParameter("qDoc", Ref);
	vStates = vQry.Execute().Unload();
	If vStates.Count() > 0 Then
		Return vStates.Get(0);
	Else
		Return Undefined;
	EndIf;
EndFunction // pmGetPreviousObjectState

// -----------------------------------------------------------------------------
Procedure pmRestoreAttributesFromHistory(pHistoryRec) Export
	FillPropertyValues(ThisObject, pHistoryRec, , "Number, Date, Author");
	If Not IsBlankString(pHistoryRec.Number) Then
		Number = pHistoryRec.Number;
	EndIf;
	If ValueIsFilled(pHistoryRec.Date) Then
		Date = pHistoryRec.Date;
	EndIf;
	If ValueIsFilled(pHistoryRec.Author) Then
		Author = pHistoryRec.Author;
	EndIf;
	// Restore tabular parts
	vFormulas = pHistoryRec.Formulas.Get();
	If vFormulas <> Undefined Then
		Formulas.Load(vFormulas);
	Else
		Formulas.Clear();
	EndIf;
EndProcedure // pmRestoreAttributesFromHistory

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
	If Not ValueIsFilled(Hotel) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Гостиница> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Hotel> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Hotel> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Hotel", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(RoomRate) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Тариф> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Room rate> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Room rate> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "RoomRate", pAttributeInErr);
	EndIf;
	If Formulas.Count() > 0 And Discount = 0 Then
		vFormulas = Formulas.Unload();
		vFormulas.GroupBy("ClientType, CalendarDayType, Service, RoomClass, RoomType, AccommodationType",);
		If Formulas.Count() <> vFormulas.Count() Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "В таблице формул есть дубликаты строк!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "There are duplicate rows in the formulas table!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "Es gibt doppelte Zeilen in der formeltabelle!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "Formulas", pAttributeInErr);
		EndIf;
	EndIf;
	If vHasErrors Then
		pMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // pmCheckDocumentAttributes

// -----------------------------------------------------------------------------
Function pmGetListOfActiveClientTypes(pClientType, pClientTypes) Export
	vClientTypes = New ValueTable();
	vCacheRow = pClientTypes.Find(pClientType, "ClientType");
	If vCacheRow = Undefined Then
		If ValueIsFilled(pClientType) Then
			If pClientType.IsFolder Then
				vClientTypes = cmGetAllClientTypes(Hotel, pClientType);
			Else
				vClientTypes.Columns.Add("ClientType", cmGetCatalogTypeDescription("ClientTypes"));
				vRow = vClientTypes.Add();
				vRow.ClientType = pClientType;
			EndIf;
		Else
			vClientTypes.Columns.Add("ClientType", cmGetCatalogTypeDescription("ClientTypes"));
			vRow = vClientTypes.Add();
			vRow.ClientType = pClientType;
		EndIf;
		vCacheRow = pClientTypes.Add();
		vCacheRow.ClientType = pClientType;
		vCacheRow.ClientTypes = vClientTypes;
	Else
		vClientTypes = vCacheRow.ClientTypes;
	EndIf;
	Return vClientTypes;
EndFunction // pmGetListOfActiveClientTypes

// -----------------------------------------------------------------------------
Function pmGetListOfActiveRoomTypes(pRoomType, pRoomClass, pRoomTypes) Export
	vRoomTypes = New ValueTable();
	vCacheRows = pRoomTypes.FindRows(New Structure("RoomClass, RoomType", pRoomClass, pRoomType));
	If vCacheRows.Count() = 0 Then
		If ValueIsFilled(pRoomType) Then
			If pRoomType.IsFolder Then
				vRoomTypes = cmGetAllRoomTypes(Hotel, pRoomType, pRoomClass);
			Else
				vRoomTypes.Columns.Add("RoomType", cmGetCatalogTypeDescription("RoomTypes"));
				vRoomTypes.Columns.Add("RoomClass", cmGetCatalogTypeDescription("RoomTypeClasses"));
				vRow = vRoomTypes.Add();
				vRow.RoomClass = pRoomType.RoomClass;
				vRow.RoomType = pRoomType;
			EndIf;
		Else
			vRoomTypes = cmGetAllRoomTypes(Hotel, , pRoomClass);
		EndIf;
		vCacheRow = pRoomTypes.Add();
		vCacheRow.RoomClass = pRoomClass;
		vCacheRow.RoomType = pRoomType;
		vCacheRow.RoomTypes = vRoomTypes;
	Else
		vRoomTypes = vCacheRows.Get(0).RoomTypes;
	EndIf;
	Return vRoomTypes;
EndFunction // pmGetListOfActiveRoomTypes

// -----------------------------------------------------------------------------
Function pmGetListOfActiveAccommodationTypes(pAccommodationType, pAccommodationTypes) Export
	vAccommodationTypes = New ValueTable();
	vCacheRow = pAccommodationTypes.Find(pAccommodationType, "AccommodationType");
	If vCacheRow = Undefined Then
		If ValueIsFilled(pAccommodationType) Then
			If pAccommodationType.IsFolder Then
				vAccommodationTypes = cmGetAllAccommodationTypes(pAccommodationType);
			Else
				vAccommodationTypes.Columns.Add("AccommodationType", cmGetCatalogTypeDescription("AccommodationTypes"));
				vRow = vAccommodationTypes.Add();
				vRow.AccommodationType = pAccommodationType;
			EndIf;
		Else
			vAccommodationTypes = cmGetAllAccommodationTypes();
		EndIf;
		vCacheRow = pAccommodationTypes.Add();
		vCacheRow.AccommodationType = pAccommodationType;
		vCacheRow.AccommodationTypes = vAccommodationTypes;
	Else
		vAccommodationTypes = vCacheRow.AccommodationTypes;
	EndIf;
	Return vAccommodationTypes;
EndFunction // pmGetListOfActiveAccommodationTypes

// -----------------------------------------------------------------------------
Function pmGetListOfActiveCalendarDayTypes(pDayType, pDayTypes) Export
	vDayTypes = New ValueTable();
	vCacheRows = pDayTypes.FindRows(New Structure("CalendarDayType", pDayType));
	If vCacheRows.Count() = 0 Then
		If ValueIsFilled(pDayType) Then
			If pDayType.IsFolder Then
				vDayTypes = cmGetAllCalendarDayTypes(pDayType);
			Else
				vDayTypes.Columns.Add("CalendarDayType", cmGetCatalogTypeDescription("CalendarDayTypes"));
				vRow = vDayTypes.Add();
				vRow.CalendarDayType = pDayType;
			EndIf;
		Else
			vDayTypes.Columns.Add("CalendarDayType", cmGetCatalogTypeDescription("CalendarDayTypes"));
			vRow = vDayTypes.Add();
			vRow.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
		EndIf;
		vCacheRow = pDayTypes.Add();
		vCacheRow.CalendarDayType = pDayType;
		vCacheRow.CalendarDayTypes = vDayTypes;
	Else
		vDayTypes = vCacheRows.Get(0).CalendarDayTypes;
	EndIf;
	Return vDayTypes;
EndFunction // pmGetListOfActiveCalendarDayTypes

#EndRegion
