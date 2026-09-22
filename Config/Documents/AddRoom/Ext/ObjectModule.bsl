
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure Posting(pCancel, pPostingMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	// Create room if necessary
	CreateRoom(pCancel);
	// Write to room inventory
	PostToRegisters(pCancel);
EndProcedure // Posting

// -----------------------------------------------------------------------------
Procedure UndoPosting(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	// Remove records from the room change history
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomChangeHistory.Period,
	|	RoomChangeHistory.Room
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
EndProcedure // UndoPosting

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
			pCancel	= pmCheckDocumentAttributes(vMessage, vAttributeInErr);
			If pCancel Then
				WriteLogEvent(NStr("en = 'Document.DataValidation'; de = 'Document.DataValidation'; ru = 'Документ.КонтрольДанных'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
				tcCommonFunctionOnClientServer.TextMessage(cmNStr(vMessage), MessageStatus.Attention);
				Raise cmNStr(vMessage);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

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
EndProcedure // BeforeDelete

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
Procedure OnCopy(pCopiedObject)
	// Clear room reference
	RoomNumber = "";
	SortCode = 0;
	Room = Catalogs.Rooms.EmptyRef();
EndProcedure // OnCopy

// -----------------------------------------------------------------------------
Procedure Filling(FillingData, FillingText, StandardProcessing)
	// Fill author and document date
	pmFillAuthorAndDate();
	// Fill room attributes
	If ValueIsFilled(FillingData) Then
		vRoomObj = FillingData.GetObject();
		vRoomAttr = vRoomObj.pmGetRoomAttributes(Date);
		For Each vRoomAttrRow In vRoomAttr Do
			Hotel = vRoomAttrRow.Hotel;
			RoomGroup = vRoomAttrRow.RoomGroup;
			RoomNumber = vRoomAttrRow.RoomNumber;
			RoomType = vRoomAttrRow.RoomType;
			NumberOfBedsPerRoom = vRoomAttrRow.NumberOfBedsPerRoom;
			NumberOfPersonsPerRoom = vRoomAttrRow.NumberOfPersonsPerRoom;
			OperationEndDate = vRoomAttrRow.OperationEndDate;
			Date = vRoomAttrRow.OperationStartDate;
			
			SortCode = FillingData.SortCode;
			Remarks = FillingData.Remarks;
			IsVirtual = vRoomAttrRow.IsVirtual;
		EndDo;
	EndIf;
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
EndProcedure

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
	vRCHRec.OperationStartDate = Date;
	
	FillPropertyValues(vRCHRec, ThisObject);
	
	vRCHRec.Write(True);
EndProcedure // pmWriteToRoomChangeHistory

// -----------------------------------------------------------------------------
Function pmCheckDocumentAttributes(pMessage, pAttributeInErr) Export
	vHasErrors = False;
	pMessage = "";
	pAttributeInErr = "";
	vMsgTextRu = "";
	vMsgTextEn = "";
	vMsgTextDe = "";
	If Not ValueIsFilled(Hotel) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Гостиница> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Hotel> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Hotel> Attribut sollte ausgefüllt werden!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Hotel", pAttributeInErr);
	EndIf;
	If TrimAll(RoomNumber) = "" Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Номер комнаты> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Room number> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Zimmernummer> Attribut sollte gefüllt werden!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "RoomNumber", pAttributeInErr);
	Else
		// Check that there is no such room already
		If IsNew() Then
			If ValueIsFilled(Hotel) Then
				vRoomRef = Catalogs.Rooms.FindByDescription(RoomNumber, True, Undefined, Hotel);
				If vRoomRef <> Catalogs.Rooms.EmptyRef() Then
					vHasErrors = True; 
					vMsgTextRu = vMsgTextRu + "Такой номер в гостинице уже есть!" + Chars.LF;
					vMsgTextEn = vMsgTextEn + "The hotel already has a room with this name!" + Chars.LF;
					vMsgTextDe = vMsgTextDe + "Das Hotel hat bereits ein Zimmer mit diesem Namen!" + Chars.LF;
					pAttributeInErr = ?(pAttributeInErr = "", "RoomNumber", pAttributeInErr);
				EndIf;
			EndIf;
		EndIf;
		vRoomRef = Catalogs.Rooms.FindByAttribute("SortCode", SortCode, , Hotel);
		If vRoomRef <> Catalogs.Rooms.EmptyRef() And vRoomRef <> Room Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Не уникальный код сортировки! В гостинице уже есть номер с таким кодом сортировки." + Chars.LF;
			vMsgTextEn = vMsgTextEn + "Not a unique sort code! The hotel already has a room with this sort code." + Chars.LF;
			vMsgTextDe = vMsgTextDe + "Kein eindeutiger sortiercode! Das Hotel hat bereits ein Zimmer mit einem solchen sortiercode." + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "RoomNumber", pAttributeInErr);
		EndIf;
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
	If vHasErrors Then
		pMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // CheckDocumentAttributes

// -----------------------------------------------------------------------------
Procedure pmFillAuthorAndDate() Export
	If Not ValueIsFilled(Date) Then
		Date = BegOfYear(CurrentSessionDate());
	EndIf;
	Author = SessionParameters.CurrentUser;
EndProcedure // pmFillAuthorAndDate

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill author and date
	pmFillAuthorAndDate();
	// Initialize attributes with default values
	SortCode = Number(Right(Number, 8))*100;
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

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

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure FillRoomAttributes(pRoomObj)
	pRoomObj.Owner = Hotel;
	pRoomObj.Description = RoomNumber;
	pRoomObj.Parent = RoomGroup;
	pRoomObj.RoomType = RoomType;
	pRoomObj.NumberOfBedsPerRoom = NumberOfBedsPerRoom;
	pRoomObj.NumberOfPersonsPerRoom = NumberOfPersonsPerRoom;
	pRoomObj.OperationEndDate = OperationEndDate;
	pRoomObj.SortCode = SortCode;
	If Not IsBlankString(Remarks) Then
		pRoomObj.Remarks = Remarks;
	EndIf;
	pRoomObj.IsVirtual = IsVirtual;
EndProcedure // FillRoomAttributes

// -----------------------------------------------------------------------------
Procedure CreateRoom(pCancel)
	// If there's no room with such room number then it will be created. 
	// Otherwise if there is no change room documents after this one then
	// all room attributes will be changed. If this document is not the last
	// one for this room, then only operation start date will be changed.
	vRoomRef = Room;
	If Not ValueIsFilled(vRoomRef) Then
		vRoomRef = Catalogs.Rooms.FindByDescription(RoomNumber, True, Undefined, Hotel);
	EndIf;
	If ValueIsFilled(vRoomRef) Then
		vRoomObj = vRoomRef.GetObject();
		vRoomAttr = vRoomObj.pmGetRoomAttributes('39991231235959');
		For Each vRoomAttrRow In vRoomAttr Do
			If vRoomAttrRow.DocRecorder = Ref Or
			   Not ValueIsFilled(vRoomAttrRow.DocRecorder) Then
				FillRoomAttributes(vRoomObj);
			Else
				If TypeOf(vRoomAttrRow.DocRecorder) = Type("DocumentRef.AddRoom") Then
					Raise NStr("en='There is already one <Add room> document for the room choosen! You can not create more then one <Add room> document for the room. Please change the old one or use <Change room> document instead.';
					           |ru='Для указанного номера уже создан документ <Ввод номера в НФ>! У одного номера может быть только один документ ввода в НФ. Пожалуйста найдите и измените предыдущий документ или используйте документ <Изменить номер>.';
							   |de='Für das angegebene Zimmer wurde bereits das Dokument <Eingabe des Zimmers im Zimmerbestand> erstellt! Für ein Zimmer kann es nur ein Dokument über die Eingabe in den Zimmerbestand geben. Bitte finden Sie und ändern Sie das vorangehende Dokument oder verwenden Sie das Dokument <Zimmer ändern>.'");
				EndIf;
			EndIf;
		EndDo;
	Else
		vRoomObj = Catalogs.Rooms.CreateItem();
		FillRoomAttributes(vRoomObj);
		vRoomObj.RoomStatus = Hotel.VacantRoomStatus;
	EndIf;
		
	vRoomObj.OperationStartDate = Date;
	vRoomObj.Write();
	
	// Remove records from the room change history
	UndoPosting(pCancel);
	
	// Set room document attribute and save it
	Room = vRoomObj.Ref;
	Write(DocumentWriteMode.Write);
	
	// Add record to the room change history
	pmWriteToRoomChangeHistory();
EndProcedure // CreateRoom

// -----------------------------------------------------------------------------
Procedure PostToRegisters(pCancel)
	pCancel = tcProtection.cmAddRoomPosting(ThisObject);	
EndProcedure // PostToRegisters

#EndRegion
