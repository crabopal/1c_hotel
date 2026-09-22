
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure Posting(pCancel, pMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	// Clear register records
	RegisterRecords.RoomBlocks.Clear();
	RegisterRecords.RoomInventory.Clear();
	
	vRoomsToProcess = New ValueList();
	If ValueIsFilled(Room) Then
		vRoomsToProcess.Add(Room);
		If Room.ConnectedRooms.Count() > 0 Then
			For Each vConnectedRoomsRow In Room.ConnectedRooms Do
				If ValueIsFilled(vConnectedRoomsRow.Room) And vRoomsToProcess.FindByValue(vConnectedRoomsRow.Room) = Undefined Then
					vRoomsToProcess.Add(vConnectedRoomsRow.Room);
				EndIf;
			EndDo;
		Else 
			// Check if current room belongs to some connected room
			vConnectedRoom = GetConnectedRoom();
			If ValueIsFilled(vConnectedRoom) And vRoomsToProcess.FindByValue(vConnectedRoom) = Undefined Then
				vRoomsToProcess.Add(vConnectedRoom);
			EndIf;
		EndIf;
	EndIf;
		
	For Each vRoomsToProcessItem In vRoomsToProcess Do
		vRoom = vRoomsToProcessItem.Value;
		
		// Lock room
		vDataLock = New DataLock();
		vRItem = vDataLock.Add("Catalog.Rooms");
		vRItem.Mode = DataLockMode.Exclusive;
		vRItem.SetValue("Ref", vRoom);
		vDataLock.Lock();
		
		// Get number of rooms to write off
		vRoomsToWriteOff = 0;
		If Room <> vRoom Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	MIN(RoomInventoryBalanceAndTurnovers.RoomsVacantClosingBalance) AS VacantRooms
			|FROM
			|	AccumulationRegister.RoomInventory.BalanceAndTurnovers(&qPeriodFrom, &qPeriodTo, Minute, RegisterRecordsAndPeriodBoundaries, Room = &qRoom) AS RoomInventoryBalanceAndTurnovers";
			vQry.SetParameter("qRoom", vRoom);
			vQry.SetParameter("qPeriodFrom", DateFrom);
			vQry.SetParameter("qPeriodTo", ?(ValueIsFilled(DateTo), DateTo, '39991231235959'));
			vRcds = vQry.Execute().Unload();
			If vRcds.Count() > 0 Then
				vRcdsRow = vRcds.Get(0);
				If vRcdsRow.VacantRooms <> Null And vRcdsRow.VacantRooms > 0 Then
					vRoomsToWriteOff = 1;
				EndIf;
			EndIf;
		Else
			vRoomsToWriteOff = 1;
		EndIf;
		If vRoomsToWriteOff < 1 Then
			Continue;
		EndIf;
		
		// Get room attributes on set room block date from
		vRoomObj = vRoom.GetObject();
		vRoomAttrs = vRoomObj.pmGetRoomAttributes(DateFrom);
		For Each vRoomAttrsRow In vRoomAttrs Do
			// 1. Add movements to the room inventory register
			
			// Add room block start movement
			vStartBlock = RegisterRecords.RoomInventory.AddExpense();
			
			vStartBlock.Period = cm1SecondShift(DateFrom);
			vStartBlock.PeriodFrom = vStartBlock.Period;
			vStartBlock.PeriodTo = DateTo;
			
			FillPropertyValues(vStartBlock, ThisObject);
			vStartBlock.Room = vRoom;
			vStartBlock.RoomType = vRoomAttrsRow.RoomType;
			
			vStartBlock.CheckInDate = DateFrom;
			vStartBlock.CheckOutDate = DateTo;
			vStartBlock.CheckInAccountingDate = BegOfDay(DateFrom);
			vStartBlock.CheckOutAccountingDate = BegOfDay(DateTo);
			
			If Not RoomBlockType.DoNotSubtractRoomsBlockedFromTotalRoomsForRoomsRentedPercentCalculation Then
				vStartBlock.BedsBlocked = vRoomAttrsRow.NumberOfBedsPerRoom;
				vStartBlock.RoomsBlocked = vRoomsToWriteOff;
			Else
				vStartBlock.BedsBlocked = 0;
				vStartBlock.RoomsBlocked = 0;
			EndIf;
			
			vStartBlock.BedsVacant = vRoomAttrsRow.NumberOfBedsPerRoom;
			vStartBlock.RoomsVacant = vRoomsToWriteOff;
			
			vStartBlock.NumberOfBeds = vRoomAttrsRow.NumberOfBedsPerRoom;
			vStartBlock.NumberOfRooms = vRoomsToWriteOff;
			vStartBlock.NumberOfBedsPerRoom = vRoomAttrsRow.NumberOfBedsPerRoom;
			vStartBlock.NumberOfPersonsPerRoom = vRoomAttrsRow.NumberOfPersonsPerRoom;
			
			vStartBlock.IsBlocking = True;
			
			vStartBlock.Timestamp = CurrentSessionDate();
			
			// Add room block end movement
			If ValueIsFilled(DateTo) Then
				vEndBlock = RegisterRecords.RoomInventory.AddReceipt();
			
				vEndBlock.Period = cm0SecondShift(DateTo);
				vEndBlock.PeriodFrom = cm1SecondShift(DateFrom);
				vEndBlock.PeriodTo = DateTo;
				
				FillPropertyValues(vEndBlock, ThisObject);
				vEndBlock.Room = vRoom;
				vEndBlock.RoomType = vRoomAttrsRow.RoomType;
				
				vEndBlock.CheckInDate = DateFrom;
				vEndBlock.CheckOutDate = DateTo;
				vEndBlock.CheckInAccountingDate = BegOfDay(DateFrom);
				vEndBlock.CheckOutAccountingDate = BegOfDay(DateTo);
				
				If Not RoomBlockType.DoNotSubtractRoomsBlockedFromTotalRoomsForRoomsRentedPercentCalculation Then
					vEndBlock.BedsBlocked = vRoomAttrsRow.NumberOfBedsPerRoom;
					vEndBlock.RoomsBlocked = vRoomsToWriteOff;
				Else
					vEndBlock.BedsBlocked = 0;
					vEndBlock.RoomsBlocked = 0;
				EndIf;
				
				vEndBlock.BedsVacant = vRoomAttrsRow.NumberOfBedsPerRoom;
				vEndBlock.RoomsVacant = vRoomsToWriteOff;
				
				vEndBlock.NumberOfBeds = vRoomAttrsRow.NumberOfBedsPerRoom;
				vEndBlock.NumberOfRooms = vRoomsToWriteOff;
				vEndBlock.NumberOfBedsPerRoom = vRoomAttrsRow.NumberOfBedsPerRoom;
				vEndBlock.NumberOfPersonsPerRoom = vRoomAttrsRow.NumberOfPersonsPerRoom;
			
				vEndBlock.IsBlocking = True;
			
				vEndBlock.Timestamp = CurrentSessionDate();
				
				// Write end room block markup record	
				vMarkupEndBlock = RegisterRecords.RoomInventory.AddReceipt();
			
				vMarkupEndBlock.Period = cm0SecondShift(DateTo) - 1;
				vMarkupEndBlock.Hotel = Hotel;
				vMarkupEndBlock.RoomType = vRoomAttrsRow.RoomType;
				vMarkupEndBlock.Room = Catalogs.Rooms.EmptyRef();
				
				vMarkupEndBlock.TotalRooms = 0;
				vMarkupEndBlock.TotalBeds = 0;
				vMarkupEndBlock.TotalGuests = 0;
				vMarkupEndBlock.RoomsVacant = 0;
				vMarkupEndBlock.BedsVacant = 0;
				vMarkupEndBlock.GuestsVacant = 0;
				
				vMarkupEndBlock.Counter = 1;
				
				vMarkupEndBlock.ParentDoc = Ref;
				vMarkupEndBlock.NumberOfBedsPerRoom = 0;
				vMarkupEndBlock.NumberOfPersonsPerRoom = 0;
				vMarkupEndBlock.Remarks = "";
				vMarkupEndBlock.Author = Catalogs.Employees.EmptyRef();
				
				vMarkupEndBlock.IsRoomInventory = False;
				vMarkupEndBlock.IsBlocking = False;
				
				vMarkupEndBlock.Timestamp = CurrentSessionDate();
			EndIf;
			
			// Write movements to the Room Inventory register
			RegisterRecords.RoomInventory.Write();
			
			// 2. Add movements to the room blocks register
			
			// Add room block start movement
			vStartBlock = RegisterRecords.RoomBlocks.AddReceipt();
			
			vStartBlock.Period = cm1SecondShift(DateFrom);
			
			FillPropertyValues(vStartBlock, ThisObject);
			vStartBlock.Room = vRoom;
			vStartBlock.RoomType = vRoomAttrsRow.RoomType;
			
			vStartBlock.BedsBlocked = vRoomAttrsRow.NumberOfBedsPerRoom;
			vStartBlock.RoomsBlocked = vRoomsToWriteOff;
			
			// Add room block end movement
			If ValueIsFilled(DateTo) Then
				vEndBlock = RegisterRecords.RoomBlocks.AddExpense();
			
				vEndBlock.Period = cm0SecondShift(DateTo);
				
				FillPropertyValues(vEndBlock, ThisObject);
				vEndBlock.Room = vRoom;
				vEndBlock.RoomType = vRoomAttrsRow.RoomType;
				
				vEndBlock.BedsBlocked = vRoomAttrsRow.NumberOfBedsPerRoom;
				vEndBlock.RoomsBlocked = vRoomsToWriteOff;
			EndIf;
			
			// Write movements to the Room blocks register
			RegisterRecords.RoomBlocks.Write();
		EndDo;
		
		// 3. Try to update room has blocks status
		vDoUpdate = True;
		If IsFinished Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	SetRoomBlock.Ref
			|FROM
			|	Document.SetRoomBlock AS SetRoomBlock
			|WHERE
			|	SetRoomBlock.IsFinished = FALSE AND 
			|	SetRoomBlock.Posted = TRUE AND 
			|	SetRoomBlock.Room = &qRoom";
			vQry.SetParameter("qRoom", vRoom);
			vBlocks = vQry.Execute().Unload();
			If vBlocks.Count() > 0 Then
				vDoUpdate = False;
			Else
				If Not vRoom.HasRoomBlocks Then
					vDoUpdate = False;
				EndIf;
			EndIf;
		Else
			If vRoom.HasRoomBlocks Then
				vDoUpdate = False;
			EndIf;
		EndIf;
		If vDoUpdate Then
			vRoomObj = vRoom.GetObject();
			vRoomObj.HasRoomBlocks = Not IsFinished;
			vRoomObj.Write();
		EndIf;
		
		// Change room status
		ChangeRoomStatus(vRoom, pCancel, pMode);
	EndDo;
EndProcedure // Posting

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pWriteMode, pPostingMode)
	Var vMessage, vAttributeInErr;
	If DataExchange.Load Then
		Return;
	EndIf;
	If pWriteMode = DocumentWriteMode.Posting Then
		pCancel	= pmCheckDocumentAttributes(vMessage, vAttributeInErr);
		If pCancel Then
			WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
			tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
			Raise NStr(vMessage);
		EndIf;
	Else
		If Not cmCheckUserPermissions("HavePermissionToSetDeletionMarkForSetRoomBlocks") Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to mark room block for deletion! Change block end time instead.';ru='Нет прав на пометку блокировки номера на удаление! Вместо удаления измените время окончания периода блокировки.';de='Sie haben keine Rechte, Zimmer block für Löschung zu markieren! Ändern Sie stattdessen blockendzeit.'"), MessageStatus.Attention);
			Return;
		Else
			If Not IsNew() And DeletionMark And Ref.Posted Then
				AdditionalProperties.Insert("DeletionMarkMode", True);
			EndIf;
		EndIf;
	EndIf;
	If IsFinished And ValueIsFilled(DateTo) And pWriteMode = DocumentWriteMode.Posting Or DeletionMark Then
		If Not ValueIsFilled(DateWhenFinished) Then
			DateWhenFinished = CurrentSessionDate();
			FinishedByAuthor = SessionParameters.CurrentUser;
		EndIf;
	Else
		If ValueIsFilled(DateWhenFinished) Then
			DateWhenFinished = '00010101';
			FinishedByAuthor = Catalogs.Employees.EmptyRef();
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
Procedure Filling(pBase)
	pmFillAttributesWithDefaultValues();
	If TypeOf(pBase) = Type("CatalogRef.RoomBlockTypes") Then
		RoomBlockType = pBase.Ref;
	ElsIf TypeOf(pBase) = Type("CatalogRef.Rooms") Then
		Hotel = pBase.Owner;
		Room = pBase.Ref;
	EndIf;
EndProcedure // Filling

// -----------------------------------------------------------------------------
Procedure OnCopy(pCopiedObject)
	// Fill author and document date
	pmFillAuthorAndDate();
	// Reset some attributes
	DateFrom = cm1SecondShift(CurrentSessionDate());
	Duration = 0;
	DateTo = '00010101';
	IsFinished = False;
	DateWhenFinished = '00010101';
	FinishedByAuthor = Catalogs.Employees.EmptyRef();
EndProcedure // OnCopy

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)   
	If DataExchange.Load Then
		Return;
	EndIf;
	If DeletionMark And AdditionalProperties.Property("DeletionMarkMode") And AdditionalProperties.DeletionMarkMode Then
		If ValueIsFilled(Room) And ValueIsFilled(RoomBlockType) Then
			If (Not ValueIsFilled(DateTo) Or (cm0SecondShift(DateTo + 3600) >= cm0SecondShift(CurrentSessionDate()) And BegOfDay(DateTo) = BegOfDay(CurrentSessionDate()))) Then
				If RoomBlockType.IsRoomRepair And Room.RoomStatus = Hotel.OutOfOrderRoomStatus And ValueIsFilled(Hotel.RoomStatusAfterRoomBlock) Then
					DoChangeRoomStatus(Hotel.RoomStatusAfterRoomBlock, Room, NStr("en='Room block was deleted!'; ru='Блокировка удалена!'; de='Zimmerblock wurde gelöscht!'"));
				ElsIf ValueIsFilled(RoomBlockType.RoomStatusAtBlockEnd) And Room.RoomStatus = RoomBlockType.RoomStatusAtBlockStart Then
					DoChangeRoomStatus(RoomBlockType.RoomStatusAtBlockEnd, Room, NStr("en='Room block was deleted!'; ru='Блокировка удалена!'; de='Zimmerblock wurde gelöscht!'"));
				EndIf;
			EndIf;
		EndIf;
	EndIf;        
EndProcedure // OnWrite

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
//  Check document attributes
//
// Parameters:
//  pMessage		 - String	 - Error string
//  pAttributeInErr	 - String	 - Attributes with error
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
		vMsgTextDe = vMsgTextDe + "Реквизит <Гостиница> должен быть заполнен!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Hotel", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(Room) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Номер> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Room> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "Реквизит <Номер> должен быть заполнен!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Room", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(RoomBlockType) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Тип блокировки> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Room block type> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "Реквизит <Тип блокировки> должен быть заполнен!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "RoomBlockType", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(DateFrom) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Дата начала периода блокировки> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Start of room block period> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "Реквизит <Дата начала периода блокировки> должен быть заполнен!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "DateFrom", pAttributeInErr);
	EndIf;
	If ValueIsFilled(DateFrom) Then
		If ValueIsFilled(DateTo) Then
			If DateFrom > DateTo Then
				vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "Дата окончания периода блокировки должна быть позже даты начала периода блокировки!" + Chars.LF;
				vMsgTextEn = vMsgTextEn + "End of room block period should be after start of room block period!" + Chars.LF;
				vMsgTextDe = vMsgTextDe + "Дата окончания периода блокировки должна быть позже даты начала периода блокировки!" + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "DateTo", pAttributeInErr);
			EndIf;
		EndIf;
		If ValueIsFilled(Room) Then
			vBlocks = cmGetRoomBlocks(Hotel, Undefined, Room, DateFrom, DateTo);
			For Each vBlocksRow In vBlocks Do
				If vBlocksRow.SetRoomBlock <> Ref Then
					vHasErrors = True;
					vMsgTextRu = vMsgTextRu + "У номера " + vBlocksRow.Room + " уже найдена блокировка с типом " + 
											  vBlocksRow.RoomBlockType + " на периоде " + PeriodPresentation(vBlocksRow.DateFrom, vBlocksRow.DateTo, cmLocalizationCode()) + "!" + Chars.LF;
					vMsgTextEn = vMsgTextEn + "Room " + vBlocksRow.Room + " has already block of type " + 
											  vBlocksRow.RoomBlockType + " on period " + PeriodPresentation(vBlocksRow.DateFrom, vBlocksRow.DateTo, cmLocalizationCode()) + "!" + Chars.LF;
					vMsgTextDe = vMsgTextDe + "У номера " + vBlocksRow.Room + " уже найдена блокировка с типом " + 
											  vBlocksRow.RoomBlockType + " на периоде " + PeriodPresentation(vBlocksRow.DateFrom, vBlocksRow.DateTo, cmLocalizationCode()) + "!" + Chars.LF;
					pAttributeInErr = ?(pAttributeInErr = "", "RoomBlockType", pAttributeInErr);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	// Check that there is no change room attributes in the period selected
	If ValueIsFilled(Room) And ValueIsFilled(DateFrom) Then
		vChangeRoomAttrs = cmGetChangeRoomAttributes(Room, DateFrom, DateTo);
		If vChangeRoomAttrs.Count() > 0 Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "В периоде действия блокировки не должно быть изменений параметров выбранного номера!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "There should be no change room attributes in the room block period!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "В периоде действия блокировки не должно быть изменений параметров выбранного номера!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "Room", pAttributeInErr);
		Else
			vRoomAttrs = Room.GetObject().pmGetRoomAttributes(DateFrom);
			If vRoomAttrs.Count() > 0 Then
				vRoomAttrsRow = vRoomAttrs.Get(0);
				If Not cmCheckRoomAvailability(Hotel, Catalogs.RoomQuotas.EmptyRef(), vRoomAttrsRow.RoomType, Room, Ref, Posted, True,
				                               0, 1, vRoomAttrsRow.NumberOfBedsPerRoom, , 
				                               vRoomAttrsRow.NumberOfBedsPerRoom, vRoomAttrsRow.NumberOfPersonsPerRoom, Max(CurrentSessionDate(), DateFrom), ?(ValueIsFilled(DateTo), DateTo, '39991231120000'), 
				                               vMsgTextRu, vMsgTextEn, vMsgTextDe) Then
					vHasErrors = True; 
					pAttributeInErr = ?(pAttributeInErr = "", "DateFrom", pAttributeInErr);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If vHasErrors Then
		pMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // pmCheckDocumentAttributes

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
	If Not ValueIsFilled(DateFrom) Then
		DateFrom = cm1SecondShift(CurrentSessionDate());
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
//  Calculates and returns duration for giving period
//  -----------------------------------------------------------------------------
// 
// Returns:
//  Number - Duration 
//
Function pmCalculateDuration() Export
	vDuration = 0;
	If ValueIsFilled(DateFrom) And
	   ValueIsFilled(DateTo) Then
		vPerInSec = DateTo - DateFrom;
		vDuration = Round(vPerInSec / 24 / 3600, 0);
	EndIf;
	Return vDuration;
EndFunction // pmCalculateDuration

// -----------------------------------------------------------------------------
//  Calculates and returns end of the period date based on giving duration
//  -----------------------------------------------------------------------------
// 
// Returns:
//  Date - Date to 
//
Function pmCalculateDateTo() Export
	vDateTo = cm0SecondShift(DateTo);
	If ValueIsFilled(DateFrom) Then
		If Duration > 0 Then
			vDateTo = cm0SecondShift(DateFrom + Duration * 24 * 3600);
		EndIf;
	EndIf;
	Return vDateTo;
EndFunction // pmCalculateDateTo

#EndRegion

#Region Internal

// -----------------------------------------------------------------------------
Procedure DoChangeRoomStatus(pRoomStatus, pRoom = Undefined, pRemarks = "")
	// Update status for room
	vRoomObj = Undefined;
	If ValueIsFilled(pRoom) Then
		vRoomObj = pRoom.GetObject();
	Else
		vRoomObj = Room.GetObject();
	EndIf;
	If vRoomObj.RoomStatus <> pRoomStatus Then
		vRoomObj.RoomStatus = pRoomStatus;
		vRoomObj.Write();
		
		// Add record to the room status change history
		vRoomObj.pmWriteToRoomStatusChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser, String(Ref) + ?(IsBlankString(pRemarks), "", ", " + TrimAll(pRemarks)));
	EndIf;
EndProcedure // DoChangeRoomStatus

// -----------------------------------------------------------------------------
Procedure ChangeRoomStatus(pRoom, pCancel, pPostingMode)
	If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.OutOfOrderRoomStatus) Then
		// Change status of the current room if this is out of order (repair)
		If ValueIsFilled(pRoom) And ValueIsFilled(RoomBlockType) Then
			If RoomBlockType.IsRoomRepair Then
				If IsFinished Then
					If ValueIsFilled(DateTo) And 
					   BegOfDay(DateTo) = BegOfDay(CurrentSessionDate()) And 
					   pRoom.RoomStatus = Hotel.OutOfOrderRoomStatus And 
					   ValueIsFilled(Hotel.RoomStatusAfterRoomBlock) Then
						DoChangeRoomStatus(Hotel.RoomStatusAfterRoomBlock, pRoom, NStr("en='Room block was finished!'; ru='Блокировка номера завершена!'; de='Zimmerblock war fertig!'"));
					EndIf;
				Else
					If ValueIsFilled(DateFrom) And 
					   DateFrom <= CurrentSessionDate() And BegOfDay(DateFrom) = BegOfDay(CurrentSessionDate()) And 
					  (DateTo > CurrentSessionDate() Or Not ValueIsFilled(DateTo)) And 
					   ValueIsFilled(Hotel.OutOfOrderRoomStatus) Then
						DoChangeRoomStatus(Hotel.OutOfOrderRoomStatus, pRoom, NStr("en='Room block started!'; ru='Номер заблокирован!'; de='Zimmerblock gestarted!'"));
					EndIf;
				EndIf;
			Else
				If IsFinished Then
					If ValueIsFilled(DateTo) And 
					   BegOfDay(DateTo) = BegOfDay(CurrentSessionDate()) And 
					   ValueIsFilled(RoomBlockType.RoomStatusAtBlockEnd) And 
					   pRoom.RoomStatus = RoomBlockType.RoomStatusAtBlockStart Then
						DoChangeRoomStatus(RoomBlockType.RoomStatusAtBlockEnd, pRoom, NStr("en='Room block was finished!'; ru='Блокировка номера завершена!'; de='Zimmerblock war fertig!'"));
					EndIf;
				Else
					If ValueIsFilled(DateFrom) And 
					   DateFrom <= CurrentSessionDate() And BegOfDay(DateFrom) = BegOfDay(CurrentSessionDate()) And 
					  (DateTo > CurrentSessionDate() Or Not ValueIsFilled(DateTo)) And
					   ValueIsFilled(RoomBlockType.RoomStatusAtBlockStart) And 
					   pRoom.RoomStatus <> RoomBlockType.RoomStatusAtBlockStart Then
						DoChangeRoomStatus(RoomBlockType.RoomStatusAtBlockStart, pRoom, NStr("en='Room block started!'; ru='Номер заблокирован!'; de='Zimmerblock gestarted!'"));
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ChangeRoomStatus

// -----------------------------------------------------------------------------
Function GetConnectedRoom()
	vConnectedRoom = Catalogs.Rooms.EmptyRef();
	vQuery = New Query();
	vQuery.Text = 
	"SELECT DISTINCT
	|	Rooms.Ref AS Ref
	|FROM
	|	Catalog.Rooms.ConnectedRooms AS Rooms
	|WHERE
	|	NOT Rooms.Ref.DeletionMark
	|	AND NOT Rooms.Ref.IsFolder
	|	AND Rooms.Ref.Owner = &qHotel
	|	AND Rooms.Room = &qRoom";
	vQuery.SetParameter("qHotel", Hotel);
	vQuery.SetParameter("qRoom", Room);
	vResult = vQuery.Execute().Unload();
	If vResult.Count() > 0 Then
		vConnectedRoom = vResult.Get(0).Ref;	
	EndIf;
	Return vConnectedRoom; 
EndFunction // GetConnectedRoom

#EndRegion
