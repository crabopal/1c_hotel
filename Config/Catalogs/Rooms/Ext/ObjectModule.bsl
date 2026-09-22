
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	// Mark all room inventory operations as deleted
	If DeletionMark Then
		vDocs = pmGetRoomInventoryDocuments();
		For Each vDocsRow In vDocs Do
			vRIDocObj = vDocsRow.Ref.GetObject();
			vRIDocObj.SetDeletionMark(True);
		EndDo;
	EndIf;         
EndProcedure // OnWrite

// -----------------------------------------------------------------------------
Procedure BeforeDelete(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	// Delete all room inventory documents
	vDocs = pmGetRoomInventoryDocuments(True);
	For Each vDocsRow In vDocs Do
		vRIDocObj = vDocsRow.Ref.GetObject();
		vRIDocObj.Delete();
	EndDo;
EndProcedure // BeforeDelete

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
// Get room attributes valid on specified date
// - pDate is optional. If is not specified, then function gets attributes on current date
// Returns ValueTable 
// -----------------------------------------------------------------------------
Function pmGetRoomAttributes(Val pDate = Undefined) Export
	// Fill parameter default values 
	If Not ValueIsFilled(pDate) Then
		pDate = CurrentSessionDate();
	EndIf;
	
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT 
	|	* 
	|FROM
	|	InformationRegister.RoomChangeHistory.SliceLast(
	|	&qDate, 
	|	Room = &qRoom) AS RoomChangeHistory";
	vQry.SetParameter("qDate", pDate);
	vQry.SetParameter("qRoom", Ref);
	vAttrs = vQry.Execute().Unload();
	
	Return vAttrs;
EndFunction // pmGetRoomAttributes

// -----------------------------------------------------------------------------
// Get room properties
// Returns ValueTable 
// -----------------------------------------------------------------------------
Function pmGetRoomProperties() Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	RoomProperties.Room AS Room,
	|	RoomProperties.RoomProperty AS RoomProperty,
	|	RoomProperties.Remarks AS Remarks,
	|	RoomProperties.Author AS Author,
	|	RoomProperties.RoomProperty.SortCode AS RoomPropertySortCode
	|FROM
	|	InformationRegister.RoomProperties AS RoomProperties
	|WHERE
	|	RoomProperties.Room = &qRoom
	|
	|ORDER BY
	|	RoomPropertySortCode";
	vQry.SetParameter("qRoom", Ref);
	vProperties = vQry.Execute().Unload();
	Return vProperties;
EndFunction // pmGetRoomProperties

// -----------------------------------------------------------------------------
// Get room blocks
// Returns ValueTable 
// -----------------------------------------------------------------------------
Function pmGetRoomBlocks() Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	RoomInventory.Recorder AS SetRoomBlock,
	|	RoomInventory.Hotel AS Hotel,
	|	RoomInventory.RoomType AS RoomType,
	|	RoomInventory.Room AS Room,
	|	RoomInventory.RoomBlockType AS RoomBlockType,
	|	RoomInventory.RoomBlockType.SortCode AS RoomBlockTypeSortCode,
	|	RoomInventory.CheckInDate AS DateFrom,
	|	RoomInventory.Duration AS Duration,
	|	RoomInventory.CheckOutDate AS DateTo,
	|	RoomInventory.RoomsBlocked AS RoomsBlocked,
	|	RoomInventory.BedsBlocked AS BedsBlocked,
	|	RoomInventory.NumberOfBedsPerRoom AS NumberOfBedsPerRoom,
	|	RoomInventory.NumberOfPersonsPerRoom AS NumberOfPersonsPerRoom,
	|	RoomInventory.Author AS Author,
	|	RoomInventory.IsFinished AS IsFinished,
	|	RoomInventory.Remarks AS Remarks
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|WHERE
	|	RoomInventory.Room = &qRoom
	|	AND RoomInventory.IsBlocking = TRUE
	|	AND RoomInventory.IsFinished = FALSE
	|	AND RoomInventory.RecordType = &qExpense
	|
	|ORDER BY
	|	DateFrom,
	|	RoomBlockTypeSortCode";
	vQry.SetParameter("qRoom", Ref);
	vQry.SetParameter("qExpense", AccumulationRecordType.Expense);
	vBlocks = vQry.Execute().Unload();
	Return vBlocks;
EndFunction // pmGetRoomBlocks

// -----------------------------------------------------------------------------
// Get room characteristics
// Returns ValueTable 
// -----------------------------------------------------------------------------
Function pmGetRoomCharacteristics() Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	RoomCharacteristics.Room AS Room,
	|	RoomCharacteristics.RoomCharacteristic AS RoomCharacteristic,
	|	RoomCharacteristics.RoomCharacteristicValue AS RoomCharacteristicValue
	|FROM
	|	InformationRegister.RoomCharacteristics AS RoomCharacteristics
	|WHERE
	|	RoomCharacteristics.Room = &qRoom
	|	AND RoomCharacteristics.RoomCharacteristic.DeletionMark = FALSE
	|
	|ORDER BY
	|	RoomCharacteristics.RoomCharacteristic.Code";
	vQry.SetParameter("qRoom", Ref);
	vChars = vQry.Execute().Unload();
	Return vChars;
EndFunction // pmGetRoomCharacteristics

// -----------------------------------------------------------------------------
// Get room characteristic value
// Returns Value
// -----------------------------------------------------------------------------
Function pmGetRoomCharacteristicValue(pRoomCharacteristic) Export
	vCharValue = Undefined;
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	RoomCharacteristics.RoomCharacteristicValue AS RoomCharacteristicValue
	|FROM
	|	InformationRegister.RoomCharacteristics AS RoomCharacteristics
	|WHERE
	|	RoomCharacteristics.Room = &qRoom
	|	AND RoomCharacteristics.RoomCharacteristic = &qRoomCharacteristic
	|
	|ORDER BY
	|	RoomCharacteristics.RoomCharacteristic.Code";
	vQry.SetParameter("qRoom", Ref);
	vQry.SetParameter("qRoomCharacteristic", pRoomCharacteristic);
	vChars = vQry.Execute().Select();
	While vChars.Next() Do
		vCharValue = vChars.RoomCharacteristicValue;
		Break;
	EndDo;
	Return vCharValue;
EndFunction // pmGetRoomCharacteristicValue

// -----------------------------------------------------------------------------
Procedure pmSaveRoomCharacteristicValue(pRoomCharacteristic, pRoomCharacteristicValue) Export
	vRoomCharsMgr = InformationRegisters.RoomCharacteristics.CreateRecordManager();
	vRoomCharsMgr.Room = Ref;
	vRoomCharsMgr.RoomCharacteristic = pRoomCharacteristic;
	vRoomCharsMgr.Read();
	If vRoomCharsMgr.Selected() Then
		vRoomCharsMgr.Room = Ref;
		vRoomCharsMgr.RoomCharacteristic = pRoomCharacteristic;
		vRoomCharsMgr.RoomCharacteristicValue = pRoomCharacteristicValue;
		vRoomCharsMgr.Write();
	EndIf;
EndProcedure // pmSaveRoomCharacteristicValue

// -----------------------------------------------------------------------------
Function pmCheckRoomAttributes(pMessage, pAttributeInErr) Export
	vHasErrors = False;
	pMessage = "";
	pAttributeInErr = "";
	vMsgTextRu = "";
	vMsgTextEn = "";
	If Not ValueIsFilled(Owner) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Гостиница> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Hotel> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Owner", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(RoomType) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Тип номера> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Room type> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "RoomType", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(OperationStartDate) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Дата ввода номера в эксплуатацию> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Room operation start date> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "OperationStartDate", pAttributeInErr);
	EndIf;
	If vHasErrors Then
		pMessage = "ru = '" + TrimAll(vMsgTextRu) + "';" + "en = '" + TrimAll(vMsgTextEn) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // pmCheckRoomAttributes

// -----------------------------------------------------------------------------
Function pmWriteToRoomStatusChangeHistory(pPeriod, pUser, pRemarks, pForceWrite = False, pDoNotUpdateOperation = False) Export
	vDoWrite = True;
	vPrevStatus = "";
	// Check previous room status
	vPrevStates = pmGetRoomStatusHistoryState(pPeriod);
	If vPrevStates.Count() > 0 Then
		vPrevStatesRow = vPrevStates.Get(0);  
		vPrevStatus = vPrevStatesRow.RoomStatus;
		If vPrevStatus = RoomStatus And Not pForceWrite Then
			vDoWrite = False;
		EndIf;
	EndIf;
	
	// Add record to the room status change history
	If vDoWrite Then
		vRCHRec = InformationRegisters.RoomStatusChangeHistory.CreateRecordManager();
		
		vRCHRec.Room = Ref;
		vRCHRec.Period = pPeriod;
		vRCHRec.User = pUser;
		
		vRCHRec.RoomStatus = RoomStatus;
		vRCHRec.Remarks = pRemarks;
		If pDoNotUpdateOperation Then
			vRCHRec.Remarks = TrimAll(vRCHRec.Remarks + " " + "NO_OP_UPD");
		EndIf;
		
		vRCHRec.Write(True);   
		vMsg = NStr("en = 'The status of the room has changed: %1 -> %2'; de = 'Der Status des Raums hat sich geändert: %1 -> %2'; ru = 'У номера изменен статус: %1 -> %2'");  
		
		vChanges = StrTemplate(vMsg, vPrevStatus, RoomStatus);
		// User activity history
		InformationRegisters.UserActionsHistory.WriteUserActivityRecord(Ref, vChanges, Owner, pUser, pPeriod);
	EndIf;
	
	Return vDoWrite;
EndFunction // pmWriteToRoomStatusChangeHistory

// -----------------------------------------------------------------------------
Procedure pmWriteToRoomChangeHistory(pPeriod, pUser) Export
	// Add record to the room change history
	vRCHRec = InformationRegisters.RoomChangeHistory.CreateRecordManager();
	
	vRCHRec.Room = Ref;
	vRCHRec.Period = pPeriod;
	vRCHRec.User = pUser;

	vRCHRec.Hotel = Owner;
	vRCHRec.RoomGroup = Parent;
	vRCHRec.RoomNumber = Description;
	vRCHRec.DocRecorder = Undefined;
	vRCHRec.Author = Undefined;
	
	FillPropertyValues(vRCHRec, ThisObject);
	
	vRCHRec.Write(True);
EndProcedure // pmWriteToRoomChangeHistory

// -----------------------------------------------------------------------------
Function pmGetRoomStatusHistoryState(pPeriod, pRoomStatus = Undefined) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	*
	|FROM
	|	InformationRegister.RoomStatusChangeHistory.SliceLast(
	|			&qPeriod,
	|			Room = &qRoom" + 
				?(pRoomStatus <> Undefined, " AND RoomStatus <> &qRoomStatus", "") + ") AS RoomStatusChangeHistorySliceLast";
	vQry.SetParameter("qPeriod", New Boundary(pPeriod, BoundaryType.Including));
	vQry.SetParameter("qRoom", Ref);
	vQry.SetParameter("qRoomStatus", pRoomStatus);
	vPrevRoomStatusStates = vQry.Execute().Unload();
	Return vPrevRoomStatusStates;
EndFunction // pmGetRoomStatusHistoryState

// -----------------------------------------------------------------------------
Function pmGetCheckedOutGuest(Val pPeriod = Undefined) Export
	If pPeriod = Undefined Then
		pPeriod = CurrentSessionDate();
	EndIf;
	// Build and run query
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	RoomInventory.Guest AS Guest,
	|	RoomInventory.GuestGroup AS GuestGroup,
	|	RoomInventory.Recorder AS Accommodation
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|WHERE
	|	RoomInventory.Hotel = &qHotel
	|	AND RoomInventory.Room = &qRoom
	|	AND RoomInventory.RecordType = &qReceipt
	|	AND RoomInventory.PeriodTo <= &qPeriod
	|	AND RoomInventory.IsAccommodation
	|	AND RoomInventory.IsCheckOut
	|
	|ORDER BY
	|	RoomInventory.PeriodTo DESC";
	vQry.SetParameter("qHotel", Owner);
	vQry.SetParameter("qRoom", Ref);
	vQry.SetParameter("qReceipt", AccumulationRecordType.Receipt);
	vQry.SetParameter("qPeriod", pPeriod);
	vQryTab = vQry.Execute().Unload();
	Return vQryTab;
EndFunction // pmGetCheckedOutGuest

// -----------------------------------------------------------------------------
Function pmGetInHouseGuests() Export
	// Build and run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventory.Guest AS Guest,
	|	RoomInventory.Recorder AS Accommodation,
	|	RoomInventory.CheckInDate AS CheckInDate
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|WHERE
	|	RoomInventory.Hotel = &qHotel
	|	AND RoomInventory.Room = &qRoom
	|	AND RoomInventory.RecordType = &qExpense
	|	AND RoomInventory.IsAccommodation
	|	AND RoomInventory.IsInHouse
	|	AND RoomInventory.PeriodFrom <= &qCurrentDate
	|	AND RoomInventory.PeriodTo >= &qCurrentDate
	|
	|GROUP BY
	|	RoomInventory.Guest,
	|	RoomInventory.Recorder,
	|	RoomInventory.CheckInDate
	|
	|ORDER BY
	|	RoomInventory.CheckInDate";
	vQry.SetParameter("qHotel", Owner);
	vQry.SetParameter("qRoom", Ref);
	vQry.SetParameter("qCurrentDate", CurrentSessionDate());
	vQry.SetParameter("qExpense", AccumulationRecordType.Expense);
	vQryTab = vQry.Execute().Unload();
	Return vQryTab;
EndFunction // pmGetInHouseGuests

// -----------------------------------------------------------------------------
Function pmGetRoomInventoryDocuments(pAll = False) Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	AddRooms.Ref AS Ref,
	|	AddRooms.PointInTime AS PointInTime
	|FROM
	|	Document.AddRoom AS AddRooms
	|WHERE
	|	AddRooms.Room = &qRoom
	|	AND (AddRooms.Posted
	|			OR &qAll)
	|
	|UNION ALL
	|
	|SELECT
	|	ChangeRooms.Ref,
	|	ChangeRooms.PointInTime
	|FROM
	|	Document.ChangeRoom AS ChangeRooms
	|WHERE
	|	ChangeRooms.Room = &qRoom
	|	AND (ChangeRooms.Posted
	|			OR &qAll)
	|
	|ORDER BY
	|	PointInTime DESC";
	vQry.SetParameter("qRoom", Ref);
	vQry.SetParameter("qAll", pAll);
	vRIDocs = vQry.Execute().Unload();
	Return vRIDocs;
EndFunction // pmGetRoomInventoryDocuments

// -----------------------------------------------------------------------------
Procedure pmSetStopSaleFlag() Export
	vStopSale = False;
	For Each vRow In StopSalePeriods Do
		If vRow.StopSale Then
			If Not ValueIsFilled(vRow.PeriodFrom) And Not ValueIsFilled(vRow.PeriodTo) Then
				vStopSale = True;
				Break;
			ElsIf Not ValueIsFilled(vRow.PeriodFrom) And ValueIsFilled(vRow.PeriodTo) Then
				If vRow.PeriodTo > CurrentSessionDate() Then
					vStopSale = True;
					Break;
				EndIf;
			ElsIf ValueIsFilled(vRow.PeriodFrom) And Not ValueIsFilled(vRow.PeriodTo) Then
				vStopSale = True;
				Break;
			ElsIf ValueIsFilled(vRow.PeriodFrom) And ValueIsFilled(vRow.PeriodTo) Then
				If vRow.PeriodTo > CurrentSessionDate() Then
					vStopSale = True;
					Break;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	If vStopSale <> StopSale Then
		StopSale = vStopSale;
	EndIf;
EndProcedure // pmSetStopSaleFlag

#EndRegion
