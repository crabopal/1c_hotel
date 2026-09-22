
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure Posting(pCancel, pPostingMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	// Lock room
	If ValueIsFilled(Room) Then
		vDataLock = New DataLock();
		vRItem = vDataLock.Add("Catalog.Rooms");
		vRItem.Mode = DataLockMode.Exclusive;
		vRItem.SetValue("Ref", Room);
		vDataLock.Lock();
	EndIf;
	// Change room attributes
	ChangeRoom(pCancel);
	// Write to room inventory
	PostToRegisters(pCancel);
EndProcedure //  Posting

// -----------------------------------------------------------------------------
Procedure UndoPosting(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	// Remove records from the room change history
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomChangeHistory.Period AS Period,
	|	RoomChangeHistory.Room AS Room
	|FROM
	|	InformationRegister.RoomChangeHistory AS RoomChangeHistory
	|WHERE
	|	RoomChangeHistory.DocRecorder = &qDocRecorder";
	vQry.SetParameter("qDocRecorder", Ref);
	vChanges = vQry.Execute().Unload();
	If vChanges.Count() > 0 Then
		vRCHRec = InformationRegisters.RoomChangeHistory.CreateRecordManager();
		For Each vChangesRow In vChanges Do
			vRCHRec.Room = vChangesRow.Room;
			vRCHRec.Period = vChangesRow.Period;
			vRCHRec.Read();
			If vRCHRec.Selected() Then
				vRCHRec.Delete();
			EndIf;
		EndDo;
	EndIf;
EndProcedure //  UndoPosting

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pWriteMode, pPostingMode)
	Var vMessage, vAttributeInErr;
	If DataExchange.Load Then
		Return;
	EndIf;
	If Not (AdditionalProperties.Property("DoNotCheckAttributes") And AdditionalProperties.DoNotCheckAttributes) Then
		If Not cmCheckUserPermissions("HavePermissionToManageRoomInventory") Then
			pCancel = True;
			vMessage = "en='You do not have rights for room inventory management!'; 
			           |de='You do not have rights for room inventory management!'; 
			           |ru='Нет прав на управление номерным фондом!'";
			WriteLogEvent(NStr("en = 'Document.DataValidation'; de = 'Document.DataValidation'; ru = 'Документ.КонтрольДанных'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
			tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
			Return;
		EndIf;
		If pWriteMode = DocumentWriteMode.Posting Then
			pCancel = pmCheckDocumentAttributes(vMessage, vAttributeInErr);
			If pCancel Then
				WriteLogEvent(NStr("en = 'Document.DataValidation'; de = 'Document.DataValidation'; ru = 'Документ.КонтрольДанных'"), EventLogLevel.Warning, Metadata(), Ref, cmNStr(vMessage));
				tcCommonFunctionOnClientServer.TextMessage(cmNStr(vMessage), MessageStatus.Attention);
				Raise cmNStr(vMessage);
			Else
				If Not IsRoomAttributesChange And Not IsRoomOutOfService Then
					IsRoomAttributesChange = True;
					If ValueIsFilled(OperationEndDate) Then
						IsRoomOutOfService = True;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;  
	If IsNew() Then    
		vEventDescription = StrTemplate(NStr("en = 'Create document Change room: %1 from %2, %3'; 
											 |de = 'Zimmer ändern: %1 from %2, %3'; 
											 |ru = 'Создан документ Изменить номер: %1 от %2, %3'"), Room, Date, RoomType); 
		AddUserLog(vEventDescription);
	EndIf;
EndProcedure //  BeforeWrite

// -----------------------------------------------------------------------------
Procedure BeforeDelete(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToManageRoomInventory") Then
		pCancel = True;
		vMessage = "en='You do not have rights for room inventory management!';
		           |de='You do not have rights for room inventory management!';
		           |ru='Нет прав на управление номерным фондом!'";
		WriteLogEvent(NStr("en = 'Document.DataValidation'; de = 'Document.DataValidation'; ru = 'Документ.КонтрольДанных'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
		tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
		Return;
	EndIf;
	If Posted Then
		UndoPosting(pCancel);
	EndIf;  
	// User activity history   
	vEventDescription = StrTemplate(NStr("en = 'Document deletion: %1 from %2, %3'; 
										 |de = 'Unmittelbare Löschung: %1 from %2, %3'; 
										 |ru = 'Непосредственное удаление: %1 от %2, %3'"), TrimAll(Room), Date, RoomType);    
	AddUserLog(vEventDescription);
EndProcedure //  BeforeDelete

// -----------------------------------------------------------------------------
Procedure Filling(pBase)
	If ValueIsFilled(pBase) Then
		If TypeOf(pBase) = Type("CatalogRef.Rooms") Then
			Room = pBase;
			pmFillAttributesWithDefaultValues();
		EndIf;
	EndIf;
EndProcedure // Filling

// -----------------------------------------------------------------------------
Procedure OnSetNewNumber(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(Hotel) Then
		vPrefix = TrimAll(Catalogs.Hotels.pmGetPrefix(Hotel));
	ElsIf ValueIsFilled(SessionParameters.CurrentHotel) Then
		vPrefix = TrimAll(Catalogs.Hotels.pmGetPrefix(SessionParameters.CurrentHotel));
	EndIf;
	If vPrefix <> "" Then
		pPrefix = vPrefix;
	EndIf;
EndProcedure // OnSetNewNumber

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
Procedure pmWriteToRoomChangeHistory() Export
	// Add record to the room change history
	vRCHRec = InformationRegisters.RoomChangeHistory.CreateRecordManager();
	
	vRCHRec.Room = Room;
	vRCHRec.Period = Date;
	vRCHRec.User = Author;
	vRCHRec.DocRecorder = Ref;
	
	FillPropertyValues(vRCHRec, ThisObject);
	
	vRCHRec.OperationStartDate = Room.OperationStartDate;
	
	vRCHRec.Write(True);
EndProcedure // pmWriteToRoomChangeHistory

// -----------------------------------------------------------------------------
Procedure pmRepostChangeRoomDocumentsCreatedLater() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ChangeRooms.Ref AS Ref
	|FROM
	|	Document.ChangeRoom AS ChangeRooms
	|WHERE
	|	ChangeRooms.Room = &qRoom
	|	AND ChangeRooms.PointInTime > &qPointInTime
	|	AND ChangeRooms.Posted
	|
	|ORDER BY
	|	ChangeRooms.PointInTime";
	vQry.SetParameter("qRoom", Room);
	vQry.SetParameter("qPointInTime", PointInTime());
	vChangeRooms = vQry.Execute().Unload();
	For Each vChangeRoomsRow In vChangeRooms Do
		vChangeRoomRef = vChangeRoomsRow.Ref;
		vChangeRoomObj = vChangeRoomRef.GetObject();
		vChangeRoomObj.Write(DocumentWriteMode.Posting);
	EndDo;
EndProcedure //  RepostChangeRoomDocumentsCreatedLater

// -----------------------------------------------------------------------------
//
// Parameters:
//  pMessage		 - String	 - Errors
//  pAttributeInErr	 - String	 - Attribute In Err
// 
// Returns:
//  Boolean - Has errors
//
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
		vMsgTextDe = vMsgTextDe + "<Hotel> Attribut sollte ausgefüllt werden!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Hotel", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(Room) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Номер> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Room> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Zimmer> Attribut sollte gefüllt werden!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Room", pAttributeInErr);
	EndIf;
	If TrimAll(RoomNumber) = "" Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Номер комнаты> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Room number> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Zimmernummer> Attribut sollte gefüllt werden!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "RoomNumber", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(RoomType) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Тип номера> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Room type> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Zimmertyp> Attribut sollte gefüllt werden!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "RoomType", pAttributeInErr);
	EndIf;
	If Not IsVirtual And NumberOfBedsPerRoom = 0 Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Количество мест в номере> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Number of beds per room> attribute should be more than zero!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Anzahl der Betten pro Zimmer> Attribut sollte mehr als null sein!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "NumberOfBedsPerRoom", pAttributeInErr);
	EndIf;
	If Not IsVirtual And NumberOfPersonsPerRoom = 0 Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Количество гостей в номере> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Number of persons per room> attribute should be more than zero!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Anzahl der Personen pro Zimmer> Attribut sollte mehr als null sein!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "NumberOfPersonsPerRoom", pAttributeInErr);
	EndIf;
	If ValueIsFilled(Room) Then
		If Room.OperationStartDate >= Date Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Дата изменения параметров номера должена быть позже даты ввода номера в эксплуатацию!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "Room attributes change date should be after room operation start date!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "Zimmer Attribute ändern Datum sollte nach Zimmer Startdatum sein!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "Date", pAttributeInErr);
		EndIf;
	EndIf;
	// Check that there is no room blocks, reservations or accommodations intersecting with document date or room operation end date
	If IsNew() And ValueIsFilled(Room) Then
		If ValueIsFilled(Date) Then
			vRoomOperations = GetRoomOperations();
			If vRoomOperations.Count() > 0 Then
				vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "На периоде после даты изменения параметров номера есть брони или блокировки!" + Chars.LF + "Ближайший мешающий изменению документ: " + String(vRoomOperations.Get(0).Recorder) +  Chars.LF;
				vMsgTextEn = vMsgTextEn + "There are reservations or room blocks in the period after the date of room parameters change!" + Chars.LF + "The closest document that prevents change: " + String(vRoomOperations.Get(0).Recorder) +  Chars.LF;
				vMsgTextDe = vMsgTextDe + "Es gibt Reservierungen oder Zimmerblöcke im Zeitraum nach dem Datum der Änderung der Zimmerparameter vor!" + Chars.LF + "Das Dokument, das Änderungen am ehesten verhindert: " + String(vRoomOperations.Get(0).Recorder) +  Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "Date", pAttributeInErr);
			EndIf;
		EndIf;
	EndIf;
	If vHasErrors Then
		pMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction //  pmCheckDocumentAttributes

// -----------------------------------------------------------------------------
Procedure pmFillAuthorAndDate() Export
	Date = BegOfDay(CurrentSessionDate());
	Author = SessionParameters.CurrentUser;
EndProcedure //  pmFillAuthorAndDate

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill author and document date
	pmFillAuthorAndDate();
	// Fill room attributes
	If ValueIsFilled(Room) Then
		vRoomObj = Room.GetObject();
		vRoomAttr = vRoomObj.pmGetRoomAttributes(Date);
		For Each vRoomAttrRow In vRoomAttr Do
			Hotel = vRoomAttrRow.Hotel;
			RoomGroup = vRoomAttrRow.RoomGroup;
			RoomNumber = vRoomAttrRow.RoomNumber;
			RoomType = vRoomAttrRow.RoomType;
			NumberOfBedsPerRoom = vRoomAttrRow.NumberOfBedsPerRoom;
			NumberOfPersonsPerRoom = vRoomAttrRow.NumberOfPersonsPerRoom;
			OperationEndDate = vRoomAttrRow.OperationEndDate;
			SortCode = Room.SortCode;
			Remarks = Room.Remarks;
			IsVirtual = vRoomAttrRow.IsVirtual;
		EndDo;
	EndIf;
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
EndProcedure //  pmFillAttributesWithDefaultValues

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure ChangeRoom(pCancel)
	// Room atributes should be changed only if current document is the last one
	vSkipSettingRoomAttributes = False;
	vRoomObj = Room.GetObject();
	vRoomAttr = vRoomObj.pmGetRoomAttributes('39991231235959');
	For Each vRoomAttrRow In vRoomAttr Do
		If ValueIsFilled(vRoomAttrRow.DocRecorder) Then
			If vRoomAttrRow.DocRecorder.Date > Date Then
				vSkipSettingRoomAttributes = True;
			ElsIf vRoomAttrRow.DocRecorder.Date = Date And vRoomAttrRow.DocRecorder <> Ref Then
				If TypeOf(vRoomAttrRow.DocRecorder) = Type("DocumentRef.ChangeRoom") Then
					vPrevChangeRoomObj = vRoomAttrRow.DocRecorder.GetObject();
					vPrevChangeRoomObj.AdditionalProperties.Insert("DoNotCheckAttributes", True);
					vPrevChangeRoomObj.SetDeletionMark(True);
				Else
					Raise NStr("en='There is <Add room> document for the date choosen! Please change date and time of the current document.';
					           |ru='Есть документ <Ввод номера в НФ> с такой же датой и временем! Пожалуйста измените дату и время изменения параметров номера.';
							   |de='Das Dokument <Eingabe des Zimmers im Zimmerbestand> erstellt für einen Zeitpunkt! Bitte ändern Sie das Datum des aktuellen Dokuments.'");
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	If Not vSkipSettingRoomAttributes And Not IsRoomAttributesChange Then
		vSkipSettingRoomAttributes = True;
	EndIf;
	vRoomAttr = vRoomObj.pmGetRoomAttributes(Date + 1);
	For Each vRoomAttrRow In vRoomAttr Do
		If ValueIsFilled(vRoomAttrRow.DocRecorder) Then
			If vRoomAttrRow.DocRecorder.Date = Date And vRoomAttrRow.DocRecorder <> Ref Then
				If TypeOf(vRoomAttrRow.DocRecorder) = Type("DocumentRef.ChangeRoom") Then
					vPrevChangeRoomObj = vRoomAttrRow.DocRecorder.GetObject();
					vPrevChangeRoomObj.AdditionalProperties.Insert("DoNotCheckAttributes", True);
					vPrevChangeRoomObj.SetDeletionMark(True);
				Else
					Raise NStr("en='There is <Add room> document for the date choosen! Please change date and time of the current document.';
					           |ru='Есть документ <Ввод номера в НФ> с такой же датой и временем! Пожалуйста измените дату и время изменения параметров номера.';
							   |de='Das Dokument <Eingabe des Zimmers im Zimmerbestand> erstellt für einen Zeitpunkt! Bitte ändern Sie das Datum des aktuellen Dokuments.'");
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	// Change current room attributes
	If Not vSkipSettingRoomAttributes Then
		vRoomObj.Owner = Hotel;
		vRoomObj.Description = RoomNumber;
		vRoomObj.Parent = RoomGroup;
		vRoomObj.RoomType = RoomType;
		vRoomObj.NumberOfBedsPerRoom = NumberOfBedsPerRoom;
		vRoomObj.NumberOfPersonsPerRoom = NumberOfPersonsPerRoom;
		vRoomObj.OperationEndDate = OperationEndDate;
		vRoomObj.SortCode = SortCode;
		If Not IsBlankString(Remarks) Then
			vRoomObj.Remarks = Remarks;
		EndIf;
		vRoomObj.isVirtual = IsVirtual;
		vRoomObj.Write();
	EndIf;
	
	// Remove records from the room change history
	UndoPosting(pCancel);
	
	// Add record to the room change history
	pmWriteToRoomChangeHistory();
EndProcedure //  ChangeRoom

// -----------------------------------------------------------------------------
Procedure PostToRegisters(pCancel)
	pCancel = tcProtection.cmChangeRoomPosting(ThisObject);
EndProcedure //  PostToRegisters

// -----------------------------------------------------------------------------
Function GetRoomOperations()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventory.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|WHERE
	|	RoomInventory.Hotel = &qHotel
	|	AND RoomInventory.Room = &qRoom
	|	AND (RoomInventory.PeriodFrom < &qPeriodTo
	|			OR &qPeriodToIsEmpty)
	|	AND (RoomInventory.PeriodTo > &qPeriodFrom
	|			OR RoomInventory.PeriodTo = &qEmptyDate
	|				AND RoomInventory.IsBlocking)
	|	AND (RoomInventory.IsBlocking
	|			OR RoomInventory.IsReservation
	|			OR RoomInventory.IsAccommodation
	|			OR RoomInventory.IsRoomQuota)
	|
	|ORDER BY
	|	RoomInventory.Period";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qRoom", Room);
	vQry.SetParameter("qPeriodFrom", Date);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qPeriodTo", OperationEndDate);
	vQry.SetParameter("qPeriodToIsEmpty", Not ValueIsFilled(OperationEndDate));
	Return vQry.Execute().Unload();
EndFunction //  GetRoomOperations

// -----------------------------------------------------------------------------
Procedure AddUserLog(pEventDescription)  
	vCurRef = Ref;   
	If Not ValueIsFilled(vCurRef) And IsNew() Then 
		vCurRef = Documents.ChangeRoom.GetRef(New UUID);
		SetNewObjectRef(vCurRef);	
	EndIf;	
	InformationRegisters.UserActionsHistory.WriteUserActivityRecord(vCurRef, pEventDescription, Hotel);
EndProcedure // AddUserLog 

#EndRegion
