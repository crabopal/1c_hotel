
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	IsNewRecord = False;
	If Not ValueIsFilled(Record.Author) And Not ValueIsFilled(Record.CreateDate) Then
		IsNewRecord = True;
		Record.Author = SessionParameters.CurrentUser;
		Record.CreateDate = CurrentSessionDate();
		If Not ValueIsFilled(Record.Hotel) Then
			Record.Hotel = SessionParameters.CurrentHotel;
		EndIf;
		If Record.Code = 0 Then
			Record.Code = GetNextCode(Record.Hotel);
		EndIf;
		If Not ValueIsFilled(Record.Room) Then
			Record.Room = "";
		EndIf;
		If Not ValueIsFilled(Record.FoundBy) Then
			Record.FoundBy = "";
		EndIf;
		If Not ValueIsFilled(Record.DateWhenFound) Then
			Record.DateWhenFound = BegOfDay(CurrentSessionDate());
		EndIf;
		If Not ValueIsFilled(Record.DeliveredTo) Then
			Record.DeliveredTo = "";
		EndIf;
		If Not ValueIsFilled(Record.ReturnedBy) Then
			Record.ReturnedBy = "";
		EndIf;
		If Not ValueIsFilled(Record.DisposedBy) Then
			Record.DisposedBy = "";
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure OnReadAtServer(pCurrentObject)
	If cmCheckUserPermissions("HavePermissionToForbiddenChangeLostAndFound") Then
		ReadOnly = True;	
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	If IsNewRecord Then
		vNewCode = GetNextCode(pCurrentObject.Hotel);
		If pCurrentObject.Code <> vNewCode Then
			pCurrentObject.Code = vNewCode;
		EndIf;
		If Not ValueIsFilled(pCurrentObject.DateWhenFound) Then
			pCurrentObject.DateWhenFound = BegOfDay(CurrentSessionDate());
		EndIf;
		If Not ValueIsFilled(pCurrentObject.FoundBy) Then
			pCurrentObject.FoundBy = SessionParameters.CurrentUser;
		EndIf;
	EndIf;
	If pCurrentObject.IsReturned Then
		If Not ValueIsFilled(pCurrentObject.DateWhenReturned) Then
			pCurrentObject.DateWhenReturned = BegOfDay(CurrentSessionDate());
		EndIf;
		If Not ValueIsFilled(pCurrentObject.ReturnedBy) Then
			pCurrentObject.ReturnedBy = tcOnServer.cmGetCurrentUserAttribute();
		EndIf;
	EndIf;
	If pCurrentObject.IsDisposaled Then
		If Not ValueIsFilled(pCurrentObject.DisposedDate) Then
			pCurrentObject.DisposedDate = BegOfDay(CurrentSessionDate());
		EndIf;
		If Not ValueIsFilled(pCurrentObject.DisposedBy) Then
			pCurrentObject.DisposedBy = tcOnServer.cmGetCurrentUserAttribute();
		EndIf;
	EndIf;
EndProcedure // BeforeWriteAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	If IsNewRecord Then
		IsNewRecord = False;
	EndIf;
EndProcedure // AfterWriteAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure HasMessageOnChange(pItem)
	If Record.HasMessage Then
		If Not ValueIsFilled(Record.Guest) Then
			ShowMessageBox(, NStr("en = 'Please choose guest!'; de = 'Kein Gast ausgewählt!'; ru = 'Не выбран гость!'"));
			Record.HasMessage = False;
			Return;
		EndIf;
		If IsBlankString(Record.Remarks) Then
			ShowMessageBox(, NStr("en = 'Please fill remarks!'; de = 'Anmerkungen sind nicht angegeben!'; ru = 'Не указаны примечания!'"));
			Record.HasMessage = False;
			Return;
		EndIf;
		vMessage = HasMessageOnChangeAtServer();
		Items.HasMessage.ReadOnly = True;
		ShowMessageBox(, NStr("en = 'Message was sent!'; de = 'Die Mitteilung wurde abgeschickt!'; ru = 'Сообщение отправлено!'") + Chars.LF + Chars.LF + vMessage);
	EndIf;
EndProcedure // HasMessageOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure IsReturnedOnChange(pItem)
	If Record.IsReturned Then
		If Not ValueIsFilled(Record.DateWhenReturned) Then
			Record.DateWhenReturned = CurrentDate();
		EndIf;
	EndIf;
EndProcedure // IsReturnedOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomOnChange(pItem)
	RoomOnChangeAtServer();
EndProcedure // RoomOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure IsDisposaledOnChange(pItem)
	If Record.IsDisposaled And Not ValueIsFilled(Record.DisposedDate) Then
		If Not ValueIsFilled(Record.DisposedDate) Then
			Record.DisposedDate = CurrentDate();
		EndIf;
		If Not ValueIsFilled(Record.DisposedBy) Then
			Record.DisposedBy = tcOnServer.cmGetCurrentUserAttribute();
		EndIf;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure StorePlaceStartChoice(pItem, pChoiceData, pChoiceByAdding, pStandardProcessing)
	pStandardProcessing = False;
	pChoiceData = GetListOfStorePlaces(Record.Hotel);
EndProcedure // StorePlaceStartChoice

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure PrintItemReturnForm(pCommand)
	If Modified Then
		ShowMessageBox(Undefined, NStr("en = 'Save changes first!'; de = 'Speichern Sie die Änderungen zuerst!'; ru = 'Сначала сохраните изменения!'"));
		Return;
	Else
		vParameters = PrintItemsListPart();
		vParameters.Insert("Type", "Return");
		OpenForm("InformationRegister.LostAndFound.Form.tcPrintForm", vParameters, ThisObject, , , , , FormWindowOpeningMode.Independent);
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure PrintItemRegisterForm(pCommand)
	If Modified Then
		ShowMessageBox(Undefined, NStr("en = 'Save changes first!'; de = 'Speichern Sie die Änderungen zuerst!'; ru = 'Сначала сохраните изменения!'"));
		Return;
	Else
		vParameters = PrintItemsListPart();
		vParameters.Insert("Type", "Register");
		OpenForm("InformationRegister.LostAndFound.Form.tcPrintForm", vParameters, ThisObject, , , , , FormWindowOpeningMode.Independent);
	EndIf;
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
// 
// Returns:
//   Structure containing parameters: List with chosen rows and Hotel 
//
&AtServer
Function PrintItemsListPart()  
	vList = New Array;  
	vList.Add(Record.SourceRecordKey);
	vParameters = New Structure("ChosenRows, Owner", vList, Record.Hotel);
	Return vParameters;
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function BuildMessage()
	vMessage = TrimAll(Record.Guest.FullName) + Chars.LF + 
	           Format(Record.DateWhenFound, "DF=dd.MM.yyyy") + NStr("en = ' in room/place '; de = ' im Zimmer/Räume '; ru = ' в номере/месте '") + TrimAll(Record.Room) + Chars.LF 
			   + TrimAll(Record.Remarks) + Chars.LF + NStr("en = 'Store place - '; de = 'Aufbewahrungsort - '; ru = 'Место хранения - '") + TrimAll(Record.StorePlace);
	Return vMessage;
EndFunction // BuildMessage

// -----------------------------------------------------------------------------
&AtServer
Function HasMessageOnChangeAtServer()
	// Create message for the guest choosen
	vMessage = BuildMessage();
	cmSendMessageToObject(Record.Guest, vMessage, , True);
	Return vMessage;
EndFunction // HasMessageOnChangeAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure RoomOnChangeAtServer()
	If ValueIsFilled(Record.Room) And TypeOf(Record.Room) = Type("CatalogRef.Rooms") Then
		vCheckedOutGuests = Record.Room.GetObject().pmGetCheckedOutGuest(Record.DateWhenFound);
		If vCheckedOutGuests.Count() > 0 Then
			vRow = vCheckedOutGuests.Get(0);
			Record.Guest = vRow.Guest;
			Record.GuestGroup = vRow.GuestGroup;
		EndIf;
	EndIf;
EndProcedure // RoomOnChangeAtServer

// --------------------------------------------------------------------------------
&AtServer
Function GetNextCode(pHotel)
	vCode = 1;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	MAX(LostAndFound.Code) AS Code
	|FROM
	|	InformationRegister.LostAndFound AS LostAndFound
	|WHERE
	|	LostAndFound.Hotel = &qHotel";
	vQry.SetParameter("qHotel", pHotel);
	vRcds = vQry.Execute().Unload();
	For Each vRcdsRow In vRcds Do
		If vRcdsRow.Code <> Null Then
			vCode = vRcdsRow.Code + 1;
			Break;
		EndIf;
	EndDo;
	Return vCode;
EndFunction // GetNextCode

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetListOfStorePlaces(pHotel)
	vStorePlacesList = New ValueList();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	LostAndFound.StorePlace AS StorePlace
	|FROM
	|	InformationRegister.LostAndFound AS LostAndFound
	|WHERE
	|	(LostAndFound.Hotel = &qHotel
	|			OR LostAndFound.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|	AND LostAndFound.StorePlace <> """"
	|
	|GROUP BY
	|	LostAndFound.StorePlace
	|
	|ORDER BY
	|	StorePlace";
	vQry.SetParameter("qHotel", pHotel);
	vStorePlaces = vQry.Execute().Unload();
	vStorePlacesList.LoadValues(vStorePlaces.UnloadColumn("StorePlace"));
	Return vStorePlacesList;
EndFunction // GetListOfStorePlaces

#EndRegion
