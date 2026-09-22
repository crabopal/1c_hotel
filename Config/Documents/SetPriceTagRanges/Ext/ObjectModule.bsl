
#Region EventHandlers

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
	
	// Sort ranges by start value
	vPriceTagRanges = PriceTagRanges.Unload();
	vPriceTagRanges.Sort("StartValue, EndValue");
	
	// Post document to the room rates information register
	RegisterRecords.PriceTags.Write = True;
	RegisterRecords.PriceTags.Clear();
	vRec = RegisterRecords.PriceTags.Add();
	vRec.Period = BegOfDay(Date);
	vRec.Hotel = Hotel;
	vRec.PriceTagType = PriceTagType;
	vRec.SetPriceTagRanges = Ref;
	
	// Post document to the price tag ranges information register
	RegisterRecords.PriceTagRanges.Write = True;
	RegisterRecords.PriceTagRanges.Clear();
	For Each vPriceTagRangesRow In vPriceTagRanges Do
		vRecord = RegisterRecords.PriceTagRanges.Add();
		vRecord.Period = BegOfDay(Date);
		vRecord.Hotel = Hotel;
		vRecord.PriceTagType = PriceTagType;
		vRecord.SortCode = vPriceTagRanges.IndexOf(vPriceTagRangesRow) + 1;
		vRecord.StartValue = vPriceTagRangesRow.StartValue;
		vRecord.EndValue = vPriceTagRangesRow.EndValue;
		vRecord.PriceTag = vPriceTagRangesRow.PriceTag;
		vRecord.SetPriceTagRanges = Ref;
	EndDo;
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
			vMessage = "en='You do not have rights to manage prices!'; ru='Нет прав на управление услугами и ценами!'; de='Sie haben keine Rechte zum Bearbeiten von Preisen!'";
			WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
			tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
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
		vMessage = "en='You do not have rights to manage prices!'; ru='Нет прав на управление услугами и ценами!'";
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
	Date = BegOfDay(CurrentSessionDate());
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
Procedure pmWriteToSetPriceTagRangesChangeHistory(pPeriod, pUser) Export
	// Get channges description
	vChanges = cmGetObjectChanges(ThisObject);
	If Not IsBlankString(vChanges) Then
		// Do movement on current date
		vHistoryRec = InformationRegisters.SetPriceTagRangesChangeHistory.CreateRecordManager();
		
		vHistoryRec.Period = pPeriod;
		vHistoryRec.SetPriceTagRanges = ThisObject.Ref;
		
		FillPropertyValues(vHistoryRec, ThisObject);
		vHistoryRec.Changes = vChanges;
		
		vHistoryRec.User = pUser;
		
		// Store tabular parts
		vPriceTagRanges = New ValueStorage(PriceTagRanges.Unload());
		vHistoryRec.PriceTagRanges = vPriceTagRanges;
		
		// Write record
		vHistoryRec.Write(True);
	EndIf;
EndProcedure // pmWriteToSetPriceTagRangesChangeHistory

// -----------------------------------------------------------------------------
Function pmGetPreviousObjectState(pPeriod) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	*
	|FROM
	|	InformationRegister.SetPriceTagRangesChangeHistory.SliceLast(&qPeriod, SetPriceTagRanges = &qDoc) AS SetPriceTagRangesChangeHistory";
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
	vPriceTagRanges = pHistoryRec.PriceTagRanges.Get();
	If vPriceTagRanges <> Undefined Then
		PriceTagRanges.Load(vPriceTagRanges);
	Else
		PriceTagRanges.Clear();
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
	If Not ValueIsFilled(PriceTagType) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Тип признака цены> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Price tag type> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Price tag type> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "PriceTagType", pAttributeInErr);
	EndIf;
	For Each vRow In PriceTagRanges Do
		If Not ValueIsFilled(vRow.PriceTag) Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "В строке " + Format(vRow.LineNumber, "ND=5; NFD=0; NG=") + " реквизит <Признак цены> должен быть заполнен!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "<Price tag> attribute in line number " + Format(vRow.LineNumber, "ND=5; NFD=0; NG=") + " should be filled!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "<Price tag> attribute in line number " + Format(vRow.LineNumber, "ND=5; NFD=0; NG=") + " should be filled!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "Prices", pAttributeInErr);
		EndIf;
	EndDo;
	If vHasErrors Then
		pMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // pmCheckDocumentAttributes

// -----------------------------------------------------------------------------
Function pmGetListOfActiveRoomRates() Export
	vRoomRates = New ValueTable();
	vRoomRates.Columns.Add("RoomRate", cmGetCatalogTypeDescription("RoomRates"));
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomRates.Ref AS RoomRate
	|FROM
	|	Catalog.RoomRates AS RoomRates
	|WHERE
	|	RoomRates.PriceTagType = &qPriceTagType
	|	AND (RoomRates.Hotel = &qHotel OR RoomRates.Hotel = &qEmptyHotel)
	|	AND NOT RoomRates.DeletionMark
	|	AND NOT RoomRates.IsFolder
	|	AND RoomRates.DateValidFrom <= &qDate
	|	AND (RoomRates.DateValidTo >= &qDate OR RoomRates.DateValidTo = &qEmptyDate)
	|
	|ORDER BY
	|	RoomRates.SortCode,
	|	RoomRates.Description";
	vQry.SetParameter("qPriceTagType", PriceTagType);
	vQry.SetParameter("qDate", Date);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vRoomRates = vQry.Execute().Unload();
	Return vRoomRates;
EndFunction // pmGetListOfActiveRoomRates

// -----------------------------------------------------------------------------
Function pmGetListOfActiveCalendarDayTypes() Export
	vCalendarDayTypes = cmGetAllCalendarDayTypes();
	vRow = vCalendarDayTypes.Add();
	vRow.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
	Return vCalendarDayTypes;
EndFunction // pmGetListOfActiveCalendarDayTypes

#EndRegion
