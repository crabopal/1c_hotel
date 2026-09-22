
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pWriteMode, pPostingMode)
	Var vMessage, vAttributeInErr;
	If DataExchange.Load Then
		Return;
	EndIf;
	If pWriteMode = DocumentWriteMode.Write Then
		pCancel	= pmCheckDocumentAttributes(vMessage, vAttributeInErr);
		If pCancel Then
			WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
			tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
			Raise NStr(vMessage);
		EndIf;
	EndIf;
	If IsCanceled Then
		If Not ValueIsFilled(CancellationDate) Then
			CancellationDate = CurrentSessionDate();
			CancellationAuthor = SessionParameters.CurrentUser;
		EndIf;
	Else
		If ValueIsFilled(CancellationDate) Then
			CancellationDate = Undefined;
			CancellationAuthor = Catalogs.Employees.EmptyRef();
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

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
Procedure OnCopy(pCopiedObject)
	pmFillAuthorAndDate();
	IsProcessed = False;
	IsCanceled = False;
	Message = "";
	MessageIsDelivered = False;
	MessageDeliveryDateTime = '00010101';
	CancellationAuthor = Catalogs.Employees.EmptyRef();
	CancellationDate = '00010101';
	CancellationMessage = "";
	IsProcessingError = False;
	ErrorMessage = "";
	PeriodOfStayExtensionIsRequested = False;
	GuestNameChangeIsRequested = False;
EndProcedure // OnCopy

// -----------------------------------------------------------------------------
Procedure Filling(pBase)
	// Fill attributes with default values
	pmFillAttributesWithDefaultValues();
	// Fill from the base
	If ValueIsFilled(pBase) Then
		If TypeOf(pBase) = Type("CatalogRef.Rooms") Then
			Room = pBase;
			Hotel = pBase.Owner;
		ElsIf TypeOf(pBase) = Type("DocumentRef.Accommodation") Or TypeOf(pBase) = Type("DocumentRef.Reservation") Then
			ParentDoc = pBase;
			Hotel = pBase.Hotel;
			Room = pBase.Room;
			// Fill guest index
			vIndex = -1;
			vOneRoomGuests = New ValueTable();
			If TypeOf(pBase) = Type("DocumentRef.Accommodation") Then
				vOneRoomGuests = cmGetOneRoomAccommodations(pBase.Room, pBase.GuestGroup, pBase.CheckInDate, pBase.CheckOutDate, pBase.Number);
			Else
				vOneRoomGuests = cmGetOneRoomReservations(pBase.Number, pBase.GuestGroup, pBase.CheckInDate, pBase.CheckOutDate);
			EndIf;
			For Each vOneRoomGuestsRow In vOneRoomGuests Do
				If vOneRoomGuestsRow.Ref = pBase Then
					vIndex = vOneRoomGuests.IndexOf(vOneRoomGuestsRow) + 1;
					Break;
				EndIf;
			EndDo;
			If vIndex = -1 Then
				If vOneRoomGuests.Count() > 0 Then
					vIndex = vOneRoomGuests.Count() + 1;
				Else
					vIndex = 1;
				EndIf;
			EndIf;
			GuestIndexInRoom = vIndex;
		EndIf;
	EndIf;
EndProcedure // Filling

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pMessage		 - String	 - Error messages
//  pAttributeInErr	 - String	 - Attribute in error
// 
// Returns:
//  Boolean - Result of checking
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
		vMsgTextDe = vMsgTextDe + "<Hotel> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Hotel", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(RoomInterfaceType) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Тип доп. услуги> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Interface type> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Interface type> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "RoomInterfaceType", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(Room) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Номер> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Room> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Room> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Room", pAttributeInErr);
	EndIf;
	If vHasErrors Then
		pMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // pmCheckDocumentAttributes

// -----------------------------------------------------------------------------
//
Procedure pmFillAuthorAndDate() Export
	Author = SessionParameters.CurrentUser;
	Date = CurrentSessionDate();
EndProcedure // pmFillAuthorAndDate

// -----------------------------------------------------------------------------
//
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill author and date
	pmFillAuthorAndDate();
	// Fill from session parameters
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	IsProcessed = False;
	IsCanceled = False;
EndProcedure // pmFillAttributesWithDefaultValues

#EndRegion
