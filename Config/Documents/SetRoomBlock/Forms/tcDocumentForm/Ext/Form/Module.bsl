
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;

	vObj = FormAttributeToValue("Object");

	// User rights to open item
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToSetRoomBlocks") Then
		If vObj.IsNew() Then
			Message(NStr("en='You do not have rights to set room blocks!';ru='Нет прав на установку блокировок номеров!';de='Sie haben keine Rechte, Zimmerblockierungen einzurichten!'"));
			pCancel = True;
			Return;
		Else
			ReadOnly = True;
		EndIf;
	EndIf;
	
	// Actions for the new document
	If vObj.IsNew() Then
		// Use current time by default
		vObj.SetTime(AutoTimeMode.CurrentOrLast);
		// Fill attributes with default values
		If Not ValueIsFilled(vObj.Author) Then
			vObj.pmFillAttributesWithDefaultValues();
		Else
			vObj.pmFillAuthorAndDate();
		EndIf;
	Else
		If Not IsInRole("RightsToChooseHotel") Then
			If ValueIsFilled(vObj.Hotel) And SessionParameters.CurrentHotel <> vObj.Hotel Then
				pCancel = True;
				Return;
			EndIf;
		EndIf;	
	EndIf;

	// Check edit prohibited date
	If ValueIsFilled(vObj.Hotel) Then
		If ValueIsFilled(vObj.Hotel.EditProhibitedDate) And ValueIsFilled(vObj.DateTo) And 
		   BegOfDay(vObj.Hotel.EditProhibitedDate) >= BegOfDay(vObj.DateTo) Then
			ReadOnly = True;
		EndIf;
	EndIf;

	OldDate = vObj.Date;

	// Process parameters
	If Parameters.Property("Room") Then
		If ValueIsFilled(Parameters.Room) Then
			vObj.Room = Parameters.Room;
			vHotel = Parameters.Room.Owner;
			If vHotel <> vObj.Hotel Then
				vObj.Hotel = vHotel;
				vObj.SetNewNumber();
			EndIf;
		Endif;
	EndIf;
	If Parameters.Property("SelListRoom") Then
		If TypeOf(Parameters.SelListRoom) = Type("ValueList") Then
			SelListRoom = Parameters.SelListRoom;
			If SelListRoom.Count() > 0 Then
				For Each vListRoomItem In SelListRoom Do
					If vListRoomItem.Check Then
						ListOfSelectedRooms.Add(vListRoomItem.Value);
					EndIf;
				EndDo;
				If ListOfSelectedRooms.Count() > 0 Then
					vHotel = ListOfSelectedRooms.Get(0).Value.Owner;
					If vHotel <> vObj.Hotel Then
						vObj.Hotel = vHotel;
						vObj.SetNewNumber();
					EndIf;
				Endif;
			EndIf;
		EndIf;
	EndIf;
	
	ValueToFormAttribute(vObj, "Object");
	
	If SelListRoom.Count() > 0 Then
		Items.ListOfSelectedRooms.Visible = True;
		Items.Room.Visible = False;
	Else
		Items.ListOfSelectedRooms.Visible = False;
		Items.Room.Visible = True;
	EndIf;

	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	If Items.Room.Visible And Not Items.ListOfSelectedRooms.Visible Then 
		vMessage = "";
		If CheckDocumentAttributes(vMessage) Then
			pCancel = True;
			tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), , , , NStr(vMessage));
			tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage));
				Return;
			EndIf;
		
		// Check if there are accommodations or reservations for the period choosen
		If Not Object.IsFinished And ValueIsFilled(Object.Room) And ValueIsFilled(Object.DateFrom) Then
			If Not CheckRoomBlockPeriod() Then
				pCancel = True;
				Return;
			EndIf;
		EndIf;
	Else
		WriteListRoom();
		Notify("Document.SetRoomBlock.WriteListRoom");
		pCancel = True;
		If ListOfSelectedRooms.Count() = 0 Then
			Modified = False;
			Close();
		EndIf;	
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(WriteParameters)
	// Notify changes
	Notify("Document.SetRoomBlock.Write", Object.Ref, ThisObject);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure DurationOnChange(pItem)
	DurationOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DateToOnChange(pItem)
	DateToOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DateFromOnChange(pItem)
	DateFromOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure IsFinishedOnChange(pItem)
	IsFinishedOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DateOnChange(pItem)
	DateOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ListOfSelectedRoomsStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	SelListRoom.ShowCheckItems(New NotifyDescription("ListRoomStartChoice_AfterInput", ThisObject, New Structure()), NStr("en='Checkmark rooms to block...'; ru='Отметьте номера для блокировки...'; de='Zu blockierende Zimmeren markieren...'"));
EndProcedure // ListOfSelectedRoomsStartChoice

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SetDeletionMarkAction(pCommand)
	If Not ValueIsFilled(Object.Ref) Then
		Return;
	EndIf;
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToSetDeletionMarkForSetRoomBlocks") Then
		ShowMessageBox( , NStr("ru='Нет прав на установку пометки удаления у блокировок номеров!';de='Sie haben keine Rechte, den Entfernungsvermerk bei Zimmerblockierungen festzulegen!';en='You do not have rights to set deletion mark for room blocks!'"));
		Return;
	EndIf;
	If Modified Then
		Modified = False;
	EndIf;
	SetDeletionMarkAtServer();
	Read();
	Notify("Document.SetRoomBlock.Write", Object.Ref);
	Close();
EndProcedure // SetDeletionMarkAction

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure DurationOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	// Calculate end of the period
	vObj.DateTo = vObj.pmCalculateDateTo();
	// Set is finished
	If Not ValueIsFilled(vObj.DateTo) Or 
		ValueIsFilled(vObj.DateTo) And vObj.DateTo > cm0SecondShift(CurrentSessionDate()) Then
		IsFinished = False;
	ElsIf ValueIsFilled(vObj.DateTo) And vObj.DateTo <= cm0SecondShift(CurrentSessionDate()) Then
		vObj.IsFinished = True;
	EndIf;
	ValueToFormAttribute(vObj, "Object");	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure DateToOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	// Calculate duration
	vObj.Duration = vObj.pmCalculateDuration();
	// Set is finished
	If Not ValueIsFilled(vObj.DateTo) Or 
	   ValueIsFilled(vObj.DateTo) And vObj.DateTo > cm0SecondShift(CurrentSessionDate()) Then
		vObj.IsFinished = False;
	ElsIf ValueIsFilled(vObj.DateTo) And vObj.DateTo <= cm0SecondShift(CurrentSessionDate()) Then
		vObj.IsFinished = True;
	EndIf;
	ValueToFormAttribute(vObj, "Object");
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure DateFromOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	// Reset seconds
	vObj.DateFrom = cm1SecondShift(vObj.DateFrom);
	// Calculate end of the period
	vObj.DateTo = vObj.pmCalculateDateTo();
	// Set is finished
	If vObj.DateFrom >= cm1SecondShift(CurrentSessionDate()) Then  
		vObj.IsFinished = False;
	Else
		If Not IsInRole("Administrator") Then
			If vObj.IsNew() And BegOfDay(vObj.DateFrom) < BegOfDay(CurrentSessionDate()) Then
				vObj.DateFrom = cm1SecondShift(CurrentSessionDate());
			ElsIf Not vObj.IsNew() And BegOfDay(vObj.DateFrom) < BegOfDay(vObj.Ref.DateFrom) And BegOfDay(vObj.DateFrom) < BegOfDay(CurrentSessionDate()) Then
				vObj.DateFrom = cm1SecondShift(vObj.Ref.DateFrom);
			EndIf;
		EndIf;
		If Not ValueIsFilled(vObj.DateTo) Or 
			ValueIsFilled(vObj.DateTo) And vObj.DateTo > cm0SecondShift(CurrentSessionDate()) Then
			vObj.IsFinished = False;
		ElsIf ValueIsFilled(vObj.DateTo) And vObj.DateTo <= cm0SecondShift(CurrentSessionDate()) Then
			vObj.IsFinished = True;
		EndIf;
	EndIf;
	ValueToFormAttribute(vObj, "Object");
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure IsFinishedOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	If vObj.IsFinished Then
		If Not ValueIsFilled(vObj.DateTo) Or 
			ValueIsFilled(vObj.DateTo) And vObj.DateTo > cm0SecondShift(CurrentSessionDate()) Then
			vObj.DateTo = cm0SecondShift(CurrentSessionDate());
			// Calculate duration
			vObj.Duration = vObj.pmCalculateDuration();
		EndIf;
	Else
		If ValueIsFilled(vObj.DateTo) And vObj.DateTo < cm0SecondShift(CurrentSessionDate()) Then
			vObj.DateTo = Undefined;
			// Calculate duration
			vObj.Duration = 0;
		EndIf;
	EndIf;
	ValueToFormAttribute(vObj, "Object");
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure DateOnChangeAtServer()
	vObj = FormAttributeToValue("Object");	
	// Automatically assign new document number if year has changed
	If ValueIsFilled(vObj.Date) And ValueIsFilled(OldDate) Then
		If Year(OldDate) <> Year(vObj.Date) Then
			vObj.SetNewNumber();
		EndIf;
		OldDate = vObj.Date;
	EndIf;
	ValueToFormAttribute(vObj, "Object");
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure WriteListRoom()	
	ConvertRoomList();
	vListRooms = New ValueList();
	For Each vListRoomIteme In ListOfSelectedRooms Do
		vListRooms.Add(vListRoomIteme.Value);	
	EndDo;
	For Each vListRoomIteme In ListOfSelectedRooms Do
		vNewDoc = FormAttributeToValue("Object");
	 	vNewDoc.Room = vListRoomIteme.Value;
		vMessage = "";
		If vNewDoc.pmCheckDocumentAttributes(vMessage, "") Then
			tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"),,,,NStr(vMessage));
			tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage));
			Continue;
		EndIf;
		// Check if there are accommodations or reservations for the period choosen
		If Not vNewDoc.IsFinished And ValueIsFilled(vNewDoc.Room) And ValueIsFilled(vNewDoc.DateFrom) Then
			If Not CheckRoomBlockPeriod(vListRoomIteme.Value) Then
				Continue;
			EndIf;
		EndIf;
		vNewDoc.Write(DocumentWriteMode.Posting);	
		SelListRoom.FindByValue(vListRoomIteme.Value).Check = False;
		vListRooms.Delete(vListRooms.FindByValue(vListRoomIteme.Value));
	EndDo;
	ListOfSelectedRooms = vListRooms; 
EndProcedure // WriteListRoom

// -----------------------------------------------------------------------------
&AtServer
Procedure ConvertRoomList()
	vNewDoc = FormAttributeToValue("Object");
	For Each vListRoomIteme In ListOfSelectedRooms Do
		vConnectedRooms = vListRoomIteme.Value.ConnectedRooms; 
		If vConnectedRooms.Count() > 0 Then
			For Each vConnectedRoom In vConnectedRooms Do
				SelListRoom.FindByValue(vConnectedRoom.Room).Check = False;
			EndDo;
		EndIf;
	EndDo;
	ListOfSelectedRooms.Clear();
	For Each vListRoomIteme In SelListRoom Do 
		If vListRoomIteme.Check Then
			ListOfSelectedRooms.Add(vListRoomIteme.Value);
		EndIf;
	EndDo;
EndProcedure // ConvertRoomList

// -----------------------------------------------------------------------------
&AtServer
Function CheckDocumentAttributes(pMessage)
	vObj = FormAttributeToValue("Object");	
	Return vObj.pmCheckDocumentAttributes(pMessage, "");
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function CheckRoomBlockPeriod(pRoom = Undefined)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservations.Recorder AS Ref,
	|	Reservations.ReservationStatus AS Status,
	|	Reservations.GuestGroup AS GuestGroup,
	|	Reservations.PeriodFrom AS CheckInDate,
	|	Reservations.PeriodDuration AS Duration,
	|	Reservations.PeriodTo AS CheckOutDate,
	|	Reservations.Guest AS Guest,
	|	Reservations.Customer AS Customer
	|FROM
	|	AccumulationRegister.RoomInventory AS Reservations
	|WHERE
	|	Reservations.IsReservation
	|	AND Reservations.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND Reservations.Room = &qRoom
	|	AND Reservations.PeriodTo > &qPeriodFrom
	|	AND (Reservations.PeriodFrom < &qPeriodTo
	|			OR &qPeriodToIsEmpty)
	|
	|UNION ALL
	|
	|SELECT
	|	Accommodations.Recorder,
	|	Accommodations.AccommodationStatus,
	|	Accommodations.GuestGroup,
	|	Accommodations.PeriodFrom,
	|	Accommodations.PeriodDuration,
	|	Accommodations.PeriodTo,
	|	Accommodations.Guest,
	|	Accommodations.Customer
	|FROM
	|	AccumulationRegister.RoomInventory AS Accommodations
	|WHERE
	|	Accommodations.IsAccommodation
	|	AND Accommodations.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND Accommodations.Room = &qRoom
	|	AND Accommodations.PeriodTo > &qPeriodFrom
	|	AND (Accommodations.PeriodFrom < &qPeriodTo
	|			OR &qPeriodToIsEmpty)
	|
	|ORDER BY
	|	CheckInDate";
	vQry.SetParameter("qRoom", ?(pRoom <> Undefined, pRoom, Object.Room));
	vQry.SetParameter("qPeriodFrom", Object.DateFrom);
	vQry.SetParameter("qPeriodTo", Object.DateTo);
	vQry.SetParameter("qPeriodToIsEmpty", Not ValueIsFilled(Object.DateTo));
	vDocs = vQry.Execute().Unload();
	If vDocs.Count() > 0 Then
		vMessage = NStr("en='ROOM ';ru='НОМЕР ';de='ZIMMER '") + TrimAll(?(pRoom <> Undefined, pRoom, Object.Room)) + NStr("en=' IS RESERVED OR OCCUPIED!';ru=' ЗАБРОНИРОВАН ИЛИ ЗАНЯТ!';de=' GEBUCHT ODER BESETZT!'") + Chars.LF + Chars.LF;
		vMessage = vMessage + NStr("en='You are blocking room with active reservations or accommodations:';ru='Блокируете номер, в котором на периоде блокировки есть действующая бронь или размещения:';de='Sie blockieren ein Zimmer, für welches im Zeitraum der Blockierung eine gültige Reservierung oder Unterbringungen vorliegen:'") + 
		Chars.LF;
		For Each vDocsRow In vDocs Do
			vMessage = vMessage + Chars.LF + 
			NStr("en='Guest group ';ru='Группа ';de='Gruppe '") + TrimAll(vDocsRow.GuestGroup) + ", " + TrimAll(vDocsRow.Status) + " " + 
			Format(vDocsRow.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(vDocsRow.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", " + 
			TrimAll(vDocsRow.Guest);
		EndDo;
		tcCommonFunctionOnClientServer.TextMessage(vMessage);
		WriteLogEvent(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), EventLogLevel.Warning, , Object.Ref, vMessage);
		Return False;
	EndIf;
	Return True;
EndFunction // CheckRoomBlockPeriod

// -----------------------------------------------------------------------------
&AtServer
Procedure SetDeletionMarkAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.Read();
	vObj.SetDeletionMark(True);
	ValueToFormAttribute(vObj, "Object");
EndProcedure // SetDeletionMarkAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ListRoomStartChoice_AfterInput(pValue, pParametrs) Export
	If pValue = Undefined Then
		Return;
	EndIf;
	ListOfSelectedRooms.Clear();
	For Each vListRoomIteme In pValue Do 
		If vListRoomIteme.Check Then
			ListOfSelectedRooms.Add(vListRoomIteme.Value);
		EndIf;
	EndDo;
EndProcedure // ListRoomStartChoice_AfterInput

#EndRegion
