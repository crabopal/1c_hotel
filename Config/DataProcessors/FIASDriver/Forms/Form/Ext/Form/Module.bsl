 
#Region FormEventHandlers
 
 // --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	ParametersLock = New Structure("CloseOnChoice, CloseOnOwnerClose, DataProcessor, FunctionalOptionsParameters, InteractionParameters, ParametersKeyCard, ParametersOneGuestMode, PurposeUseKey, ReadOnly");
    FillPropertyValues(ParametersLock, Parameters);
	// Load DP parameters
	Obj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If ParametersLock.Property("DataProcessor", vDataProcessor) Then
		Obj.DataProcessor = vDataProcessor;
	EndIf;
	vInteractionParameters = Catalogs.ExternalSystemInteractions.EmptyRef();
	If ParametersLock.Property("InteractionParameters", vInteractionParameters) Then
		Obj.InteractionParameters = vInteractionParameters;
	EndIf;
	Obj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(Obj, "Object");
	
	If ParametersLock.Property("ParametersKeyCard") And TypeOf(ParametersLock.ParametersKeyCard) = Type("Structure") Then
		FillPropertyValues(ThisForm, ParametersLock.ParametersKeyCard);
		If ValueIsFilled(DoorLockSystemParameters) Then
			DoorLockSystemConnectionParameters = DoorLockSystemParameters.DoorLockSystemConnectionParameters.Get();
		EndIf;
	EndIf; 
	
	If Not Object.IsRunning And Object.StopInterface Then
		ShowStatusMessage(New FormattedString(Nstr("en = 'Door lock system is not configurated properly for the current workstation!'; de = 'Das System für elektronische Schlösser ist auf diesem Arbeitsplatz nicht eingestellt!'; ru = 'Система электронных замков на данном рабочем месте не настроена!'"), New Font(, 18, False)), True);
		ReadOnly = True;
		Return;
	EndIf;   
	
	If Not ValueIsFilled(ParentDoc.Room) Then
		ShowStatusMessage(New FormattedString(NStr("en='Room has no key card door lock!';ru='В номере нет электронного замка!';de='Im Zimmer ist kein elektronisches Schloss vorhanden!'"), New Font(, 18, False)), True);
		ReadOnly = True;
		Return;	
	EndIf;

	
	If TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") Then
		vDocuments = cmGetOneRoomAccommodations(ParentDoc.Room, ParentDoc.GuestGroup, ParentDoc.CheckInDate, ParentDoc.CheckOutDate, ParentDoc.Number);  
	Else
		vDocuments = cmGetOneRoomReservations(ParentDoc.Number, ParentDoc.GuestGroup, ParentDoc.CheckInDate, ParentDoc.CheckOutDate); 	
	EndIf;

	vGuestIndexInRoom = 1;
	DocumentList.Clear();
	For Each vRow In vDocuments Do
		vNewRow = DocumentList.Add();
		vNewRow.Ref = vRow.Ref;
		vNewRow.GuestIndexInRoom = vGuestIndexInRoom;
		vGuestIndexInRoom = vGuestIndexInRoom + 1;
	EndDo;  
	
	DocumentCount = DocumentList.Count(); 
	
	If DocumentCount = 0 Then
		ShowStatusMessage(New FormattedString(NStr("en = 'There are no guests in the room!'; de = 'Es gibt keine Gäste im Zimmer!'; ru = 'В номере нет гостей!'"), New Font(, 18, False)), True);
		ReadOnly = True;
		Return;		
	EndIf;
	
	NumberOfKeys = DocumentCount;      
	
	UseOnlyLastName = Object.LinkRecords.FindRows(New Structure("LinkRecordCommand, LinkRecordParameter", "GI", "GF")).Count() > 0;
	 	
	vIssueKey = Object.LinkRecords.FindRows(New Structure("LinkRecordCommand", "KR")).Count() > 0;
	vReadKey = Object.LinkRecords.FindRows(New Structure("LinkRecordCommand", "KZ")).Count() > 0; 
	
	Items.FormAddKey.Visible = vIssueKey; 
	Items.FormNewKey.Visible = vIssueKey;  
	Items.ReadKeyCard.Visible = vReadKey; 
	
	RoomInterfaceType = GetRoomInterfaceTypeForCheckIn(Object.InteractionParameters);
	
	If Not vIssueKey And Not vReadKey Then
		ShowStatusMessage(New FormattedString(Nstr("en = 'This integration does not support working with a door lock system.'; de = 'Diese Integration unterstützt nicht das Arbeiten mit einem Türschlosssystem.'; ru = 'Данная интеграция не поддерживает работу с замковой системой.'"), New Font(, 18, False)), True);
		ReadOnly = True;
	Else
		ShowStatusMessage(New FormattedString(NStr("en='Choose action';ru='Выберите действие';de='Wählen Sie die Aktion'"), New Font(, 18, False)));	
	EndIf; 
EndProcedure // OnCreateAtServer

#EndRegion
 
#Region FormCommandsEventHandlers
 
 // --------------------------------------------------------------------------------
&AtClient
Procedure NewKey(pCommand)
	DocumentIndex = 0;
	Command = "KR";
	ExtraParms = "N";
	AttachIdleHandler("ProcessEvents", 0.1, True);
EndProcedure // NewKey    

// --------------------------------------------------------------------------------
&AtClient
Procedure AddKey(pCommand)
	DocumentIndex = 0;
	Command = "KR";
	ExtraParms = "D";
	AttachIdleHandler("ProcessEvents", 0.1, True);
EndProcedure // AddKey

// --------------------------------------------------------------------------------
&AtClient
Procedure ReadKeyCard(pCommand)
	DocumentIndex = 0;
	Command = "KZ";
	AttachIdleHandler("ProcessEvents", 0.1, True);
EndProcedure // ReadKeyCard
 
#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtClient
Procedure WaitingForResults() Export
	If WaitingForResultsAtServer() Then
		DetachIdleHandler("WaitingForResults");
		If Not RequestCheckIn Then
			DocumentIndex = DocumentIndex + 1;   
		EndIf;
		If IsError Or DocumentIndex = NumberOfKeys Or RequestCheckIn Then
			AttachIdleHandler("ProcessEvents", 0.1, True);	
		Else
			AttachIdleHandler("ProcessEvents", 5, True);
		EndIf;
	Else
		AttachIdleHandler("WaitingForResults", 2, True);
	EndIf;
EndProcedure // WaitingForResults 

// --------------------------------------------------------------------------------
&AtClient
Procedure ProcessEvents() Export
	RequestCheckIn = False;
	vRoomInterfaceStatus = Undefined;
	If Not IsError And ValueIsFilled(RoomInterfaceType) Then  
		If DocumentIndex < DocumentCount And Command = "KR" And ExtraParms = "N" Then 
			RequestCheckIn = CheckExistenceDocumentCheckIn(DocumentList[DocumentIndex].Ref, RoomInterfaceType, vRoomInterfaceStatus);
		EndIf;
	EndIf;
	
	If ProcessEventsAtServer(vRoomInterfaceStatus) Then
		If Object.UseHTTP And RequestCheckIn Then  
			AttachIdleHandler("ProcessEvents", 0.1, True);	
		Else                 
			AttachIdleHandler("WaitingForResults", 0.1, True);
		EndIf;
	EndIf;
EndProcedure // ProcessEvents

// -----------------------------------------------------------------------------
&AtServer
Function GetRoomByCode(pRoomCode)
	// Find room by code
	vRoom = Catalogs.Rooms.EmptyRef();
	If ValueIsFilled(pRoomCode) Then  
		vRoom = GetObjectRefByExternalSystemCode("Rooms", TrimR(pRoomCode));
		If Not ValueIsFilled(vRoom) Then 
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	Rooms.Ref
			|FROM
			|	Catalog.Rooms AS Rooms
			|WHERE
			|	Rooms.Description = &qRoomCode
			|	AND (NOT Rooms.DeletionMark)
			|	AND (NOT Rooms.IsFolder)
			|	AND Rooms.Owner = &qHotel";
			vQry.SetParameter("qRoomCode", pRoomCode);
			vQry.SetParameter("qHotel", Object.InteractionParameters.Hotel);
			vRooms = vQry.Execute().Unload();
			If vRooms.Count() > 0 Then
				vRoom = vRooms.Get(0).Ref;
			EndIf;
		EndIf;
	EndIf;
	Return vRoom;
EndFunction // GetRoomByCode 

// -----------------------------------------------------------------------------
&AtServer
Function GetDateTime(pDate, pTime)
	vDateTime = '00010101';
	Try
		vDateTime = Date(Left(Format(CurrentSessionDate(), "DF=yyyy"), 2) + TrimAll(pDate) + TrimAll(StrReplace(pTime, ":", ""))); 
	Except
		vDateTime = '00010101';	
	EndTry;
	Return vDateTime;
EndFunction // GetDateTime   

// -----------------------------------------------------------------------------
&AtServer
Function GetCodeDescription(pCode)
	vCodeDescription = "";
	If pCode = "AA" Then
		vCodeDescription = "Virtual Number already assigned";	
	ElsIf pCode = "AN" Then
		vCodeDescription = "Virtual Number not found";
	ElsIf pCode = "BM" Then
		vCodeDescription = "Balance mismatch";
	ElsIf pCode = "BY" Then
		vCodeDescription = "Telephone / Encoder Busy";
	ElsIf pCode = "CD" Then
		vCodeDescription = "Check-out date is not today";
	ElsIf pCode = "CO" Then
		vCodeDescription = "Posting denied because overwriting the CreditLimit is not allowed";
	ElsIf pCode = "DE" Then
		vCodeDescription = "Wakeup/Key has been deleted";
	ElsIf pCode = "DM" Then
		vCodeDescription = "Sum of subtotals doesn't match TotalAmount";
	ElsIf pCode = "DN" Then
		vCodeDescription = "Request denied";
	ElsIf pCode = "FX" Then
		vCodeDescription = "Guest  not allowed this feature";
	ElsIf pCode = "IA" Then
		vCodeDescription = "Invalid account";
	ElsIf pCode = "NA" Then
		vCodeDescription = "Night Audit";
	ElsIf pCode = "NF" Then
		vCodeDescription = "Feature not enabled or Check-out process not running";
	ElsIf pCode = "NG" Then
		vCodeDescription = "Guest not found";
	ElsIf pCode = "NM" Then
		vCodeDescription = "Message/Locator not found";
	ElsIf pCode = "NP" Then
		vCodeDescription = "Posting denied for this guest (NoPost flag has been set)";
	ElsIf pCode = "NR" Then
		vCodeDescription = "No Response";
	ElsIf pCode = "OK" Then
		vCodeDescription = "Command or request completed successfully";
	ElsIf pCode = "RF" Then
		vCodeDescription = "Referral";
	ElsIf pCode = "RY" Then
		vCodeDescription = "Retry";
	ElsIf pCode = "SV" Then
		vCodeDescription = "Wakeup has been sent to external system";
	ElsIf pCode = "UR" Then
		vCodeDescription = "Unprocessable request, this request cannot be carried out , no retry";
	ElsIf pCode = "ER" Then
		vCodeDescription = "Sending error";
	EndIf;
	Return vCodeDescription;
EndFunction // GetCodeDescription   

// -----------------------------------------------------------------------------
&AtServer
Function GetObjectRefByExternalSystemCode(pObjectTypeName, pObjectExternalCode)
	vObjectRef = Undefined;
	If ValueIsFilled(pObjectExternalCode) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef
		|FROM
		|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
		|WHERE
		|	(ExternalSystemsObjectCodesMappings.Hotel = &qHotel
		|			OR ExternalSystemsObjectCodesMappings.Hotel = VALUE(Catalog.Hotels.EmptyRef))
		|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
		|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = &qObjectTypeName
		|	AND ExternalSystemsObjectCodesMappings.ObjectExternalCode = &qObjectExternalCode";
		vQry.SetParameter("qHotel", Object.InteractionParameters.Hotel);
		vQry.SetParameter("qExternalSystemCode", TrimAll(Object.InteractionParameters.InteractionID));
		vQry.SetParameter("qObjectTypeName", TrimAll(pObjectTypeName));
		vQry.SetParameter("qObjectExternalCode", TrimAll(pObjectExternalCode));
		vObjects = vQry.Execute().Unload();
		If vObjects.Count() = 1 Then
			vObjectRef = vObjects.Get(0).ObjectRef;
		EndIf;
	EndIf;
	Return vObjectRef;
EndFunction // GetObjectRefByExternalSystemCode  

// --------------------------------------------------------------------------------
&AtServer
Procedure ShowStatusMessage(pMsg = "", pAttention = False)
	Items.HelpMessage.Title = pMsg;
	If pAttention Then
		Items.HelpMessage.TextColor = WebColors.Red;
	Else
		Items.HelpMessage.TextColor = WebColors.Black;
	EndIf;
EndProcedure // ShowStatusMessage 

// --------------------------------------------------------------------------------
&AtServer
Function ProcessEventsAtServer(pRoomInterfaceStatus)  
	vWS = "";
	ReadOnly = True; 
	If Not IsError Then
		If Command = "KR" Then
			If DocumentIndex = NumberOfKeys Then
				ReadOnly = False;
				IsError = False;
				Return False;
			EndIf;
			
			vParentDoc = DocumentList[0].Ref;
			vGuestIndexInRoom = DocumentList[0].GuestIndexInRoom;
			If ExtraParms <> "D" Then
				If DocumentIndex < DocumentCount Then    	 
					vParentDoc = DocumentList[DocumentIndex].Ref;
					vGuestIndexInRoom = DocumentList[DocumentIndex].GuestIndexInRoom;
				Else
					Command = "KR";
					ExtraParms = "D";		
				EndIf;    
			EndIf;
		ElsIf DocumentIndex = 1 Then  
			ReadOnly = False;
			IsError = False;
			Return False;	
		EndIf;
	Else 
		ReadOnly = False;
		IsError = False;
		Return False;	
	ENdIf;
	
	vCurDate = CurrentSessionDate();
	CardType = "";
	vParameters = Undefined;  
	If Not RequestCheckIn Then
		If Not ValueIsFilled(DoorLockSystemConnectionParameters.KeyCoder) Then
			ReadOnly = False;
			IsError = False;
			Raise NStr("en = 'Encoder ID not specified.'; de = 'Encoder-ID nicht angegeben.'; ru = 'Не указан ID энкодера.'");	
		EndIf; 
		If Not ValueIsFilled(DoorLockSystemConnectionParameters.WorkstationID) Then
			ReadOnly = False;
			IsError = False;
			Raise NStr("en = 'Workstation ID not specified.'; de = 'Workstation-ID nicht angegeben.'; ru = 'Не указан ID рабочей станции.'");	
		EndIf;
		
		vWS = Left(DoorLockSystemConnectionParameters.WorkstationID + "-" + Format(vCurDate, "DF=HHmmss"), 16); 
		If Command = "KR" Or Command = "KM" Then
			If Command = "KR" Then 
				If ExtraParms = "N" Then  
					CardType = "NEW";
				Else
					CardType = "ADD";
				EndIf;	
			EndIf;	
			vRoomCode = cmGetObjectExternalSystemCodeByRef(Object.InteractionParameters.Hotel, Object.InteractionParameters.InteractionID, "Rooms", Room, False);
			If Not ValueIsFilled(vRoomCode) Then
				Raise NStr("en='Room has no key card door lock!';ru='В номере нет электронного замка!';de='Im Zimmer ist kein elektronisches Schloss vorhanden!'");	
			EndIf;   
			vCheckInDate = CheckInDate;
			If DoorLockSystemConnectionParameters.SubtractMinutes <> 0 Then
				vCheckInDate = vCheckInDate - DoorLockSystemConnectionParameters.SubtractMinutes*60;
			EndIf;
			vCheckOutDate = CheckOutDate;
			If DoorLockSystemConnectionParameters.AddMinutes <> 0 Then
				vCheckOutDate = vCheckOutDate + DoorLockSystemConnectionParameters.AddMinutes*60;
			EndIf;
			vParameters = DataProcessors.FIASDriver.GetKeyRequest(Object.InteractionParameters, Object.LinkRecords, Object.DoDataTransliteration, DoorLockSystemConnectionParameters, DoorLockSystemAuthorization, ExtraParms, vParentDoc, vGuestIndexInRoom, Room, vCheckInDate, vCheckOutDate, vCurDate, vWS);
		Else
			vParameters = DataProcessors.FIASDriver.GetKeyDataRead(Object.LinkRecords, DoorLockSystemConnectionParameters, vCurDate, vWS);    	
		EndIf;     
	Else
		vEtraParams = DataProcessors.FIASDriver.ParsResponse(RoomInterfaceType.TurnOnParameters);
		vParameters = DataProcessors.FIASDriver.GetGuestCheckIn(Object.InteractionParameters, Object.LinkRecords, Object.DoDataTransliteration, vParentDoc, vGuestIndexInRoom, Room, vCurDate, vEtraParams["MR"], vEtraParams["NP"], vEtraParams["TV"], vEtraParams["VR"], False);	
	EndIf;     
	
	If vParameters <> Undefined Then
		If Object.UseHTTP Then
			If RequestCheckIn Then
				vSuccess = False;
				If vParameters.Count() > 0 Then
					For Each vParametersItem In vParameters Do
						vSuccess = DataProcessors.FIASDriver.SendQuery(Object.InteractionParameters, Char(2) + vParametersItem + Char(3)); 
						If Not vSuccess Then
							Break;	
						EndIf;
					EndDo;
				EndIf;
				
				If vSuccess Then
					If ValueIsFilled(pRoomInterfaceStatus) Then
						vStsObj = pRoomInterfaceStatus.GetObject();
					Else
						vDftRoomInterfaceType = RoomInterfaceType;
						vStsObj = Documents.RoomInterfaceStatus.CreateDocument();
						vStsObj.Fill(DocumentList[DocumentIndex].Ref);
						FillPropertyValues(vStsObj, RoomInterfaceType);
						vStsObj.InterfaceType = vDftRoomInterfaceType.InterfaceType;
						vStsObj.RoomInterfaceType = RoomInterfaceType;  
					EndIf;                                      
					vStsObj.IsProcessed = True;
					vStsObj.Write(DocumentWriteMode.Write);
					Return True;	
				Else  
					ShowStatusMessage(New FormattedString(NStr("en = 'Command send error'; de = 'Fehler beim Senden des Befehls'; ru = 'Ошибка отправки команды'"), New Font(, 18, True)), True);
					ReadOnly = False;
					IsError = False;
					Return False;
				EndIf;
			Else    
				If DataProcessors.FIASDriver.SendQuery(Object.InteractionParameters, Char(2) + vParameters + Char(3)) Then
					CommandUUID = New UUID();
					InformationRegisters.FIASPriorityEvents.AddEvent(CommandUUID, Object.InteractionParameters, Left(DoorLockSystemConnectionParameters.KeyCoder, 8), vWS, vParameters, Command, vCurDate, True);
					Return True;
				Else
					ShowStatusMessage(New FormattedString(NStr("en = 'Command send error'; de = 'Fehler beim Senden des Befehls'; ru = 'Ошибка отправки команды'"), New Font(, 18, True)), True);
					ReadOnly = False;
					IsError = False;
					Return False;	
				EndIf;
			EndIf;
		Else          
			If TypeOf(vParameters) = Type("Array") Then
				For Each vParametersItem In vParameters Do   
					CommandUUID = New UUID();
					InformationRegisters.FIASPriorityEvents.AddEvent(CommandUUID, Object.InteractionParameters, Left(DoorLockSystemConnectionParameters.KeyCoder, 8), vWS, vParametersItem, Command, vCurDate);
				EndDo;
			Else
				CommandUUID = New UUID();
				InformationRegisters.FIASPriorityEvents.AddEvent(CommandUUID, Object.InteractionParameters, Left(DoorLockSystemConnectionParameters.KeyCoder, 8), vWS, vParameters, Command, vCurDate);	
			EndIf;
			Return True;	
		EndIf;
	Else
		ShowStatusMessage(New FormattedString(NStr("en = 'Command send error'; de = 'Fehler beim Senden des Befehls'; ru = 'Ошибка отправки команды'"), New Font(, 18, True)), True);
		ReadOnly = False;
		IsError = False;
		Return False;	
	EndIf;
EndFunction // ProcessEventsAtServer

// --------------------------------------------------------------------------------
&AtServer
Function WaitingForResultsAtServer()
	vResult = False;    
	IsError = False;
	vRow = InformationRegisters.FIASPriorityEvents.Select(New Structure("CommandUUID", CommandUUID));
	If vRow.Next() Then
		If vRow.IsCommandSent And vRow.IsResponseReceived Then 
			If vRow.AnswerStatus = "OK" Then
				If RequestCheckIn Then 
					vDftRoomInterfaceType = RoomInterfaceType;
					vStsObj = Documents.RoomInterfaceStatus.CreateDocument();
					vStsObj.Fill(DocumentList[DocumentIndex].Ref);
					FillPropertyValues(vStsObj, RoomInterfaceType);
					vStsObj.InterfaceType = vDftRoomInterfaceType.InterfaceType;
					vStsObj.RoomInterfaceType = RoomInterfaceType;  
					vStsObj.IsProcessed = True;
					vStsObj.Write(DocumentWriteMode.Write); 
					vResult = True;
				Else 
					vData = DataProcessors.FIASDriver.ParsResponse(vRow.Response);
					If Not vRow.CommandType = "KZ" Then 
						vParentDoc = DocumentList[0].Ref;
						If DocumentIndex < DocumentCount Then
							vParentDoc = DocumentList[DocumentIndex].Ref;
						EndIf;      
						vCheckInDate = CheckInDate;
						If DoorLockSystemConnectionParameters.SubtractMinutes <> 0 Then
							vCheckInDate = vCheckInDate - DoorLockSystemConnectionParameters.SubtractMinutes*60;
						EndIf;
						vCheckOutDate = CheckOutDate;
						If DoorLockSystemConnectionParameters.AddMinutes <> 0 Then
							vCheckOutDate = vCheckOutDate + DoorLockSystemConnectionParameters.AddMinutes*60;
						EndIf;
						WriteLogEvent(NStr("en='DoorLockSystem.KeyIssued';ru='СистемаЭлектронныхЗамков.ВыданКлюч';de='DoorLockSystem.KeyIssued'"), EventLogLevel.Information,,,NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(Room) + ", " + Format(vCheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(vCheckOutDate, "DF='dd.MM.yyyy HH:mm'"));
						cmWriteKeyCardSecuritySystemEvent(CardType, "", Room, TrimAll(vRow.Request), vCheckInDate, vCheckOutDate, vParentDoc, vParentDoc.Guest, 1);								
						vMsg = NStr("en = 'Success'; de = 'Erfolgreich'; ru = 'Успешно'") + Chars.LF + "(" + (DocumentIndex + 1) + "/" + NumberOfKeys + ")";
						ShowStatusMessage(New FormattedString(vMsg, New Font(, 18, True)));
						vResult = True;
					Else
						vMsg = "";
						vRoom = Catalogs.Rooms.EmptyRef();
						If vData["RN"] <> Undefined Then
							vRoom = GetRoomByCode(vData["RN"]);
						EndIf;
						vMsg = New Array();
						If ValueIsFilled(vRoom) Then 
							vRoomArr = New Array();
							vRoomArr.Add(New FormattedString(NStr("en='Room: '; ru='Номер: '; de='Zimmer: '"), New Font(, 18, True)));
							vRoomArr.Add(New FormattedString(TrimAll(vRoom) + Chars.LF + Chars.LF, New Font(, 18, False),,, GetURL(vRoom)));
							vMsg.Add(New FormattedString(vRoomArr));
						EndIf;  
						vDate = GetDateTime(vData["GD"], vData["DT"]); 
						If ValueIsFilled(vDate) Then
							vDateArr = New Array();
							vDateArr.Add(New FormattedString(NStr("en='Check-out: '; ru='Выезд: '; de='Abreise: '"), New Font(, 18, True)));
							vDateArr.Add(New FormattedString(Format(vDate, "DF='dd.MM.yyyy HH:mm'") + Chars.LF + Chars.LF, New Font(, 18, False)));
							vMsg.Add(New FormattedString(vDateArr));
						EndIf;
						If vData["GN"] <> Undefined Then
							vGuestArr = New Array();
							vGuestArr.Add(New FormattedString(NStr("en='Guest: '; ru='Гость: '; de='Gast: '"), New Font(, 18, True)));
							vGuestArr.Add(New FormattedString(TrimAll(vData["GN"]) + Chars.LF + Chars.LF , New Font(, 18, False)));
							vMsg.Add(New FormattedString(vGuestArr));
						EndIf;
						If vData["G#"] <> Undefined Then 
							vDocNumber = cmGetDocumentNumberFromPresentation(Left(vData["G#"], StrLen(vData["G#"]) - 2), Object.InteractionParameters.Hotel);
							If ValueIsFilled(vDocNumber) Then
								vDoc = Documents.Accommodation.FindByNumber(vDocNumber);
								If vDoc = Undefined Then
									vDoc = Documents.Reservation.FindByNumber(vDocNumber);	
								EndIf;
								If ValueIsFilled(vDoc) Then 
									vDocArr = New Array();
									vDocArr.Add(New FormattedString(TrimAll(vDoc) + Chars.LF, New Font(, 18, False),,, GetURL(vDoc)));  ; 
									vMsg.Add(New FormattedString(vDocArr));
								EndIf;
							EndIf;
						EndIf;
						If vMsg.Count() > 0 Then
							ShowStatusMessage(New FormattedString(vMsg));
						EndIf;
						vResult = True;
					EndIf;  
				EndIf;
			Else
				vMsg = "";
				If Not ValueIsFilled(vRow.ClearText) Then 
					vMsg = GetCodeDescription(vRow.AnswerStatus);
				Else
					vMsg = vRow.ClearText;	
				EndIf;
				ShowStatusMessage(New FormattedString(vMsg, New Font(, 18, True)), True);
				vResult = True;	
				IsError = True;
			EndIf;
		ElsIf vRow.IsCommandSent And Not vRow.IsResponseReceived Then
			If Not vRow.CommandType = "KZ" Then
				ShowStatusMessage(New FormattedString(New FormattedString(PictureLib.LongOperation), New FormattedString(Chars.LF + NStr("en = 'Waiting for an answer'; de = 'Auf eine Antwort warten'; ru = 'Ожидание ответа'") + Chars.LF + "(" + (DocumentIndex + 1) + "/" + NumberOfKeys + ")", New Font(, 18, False))));
			Else
				ShowStatusMessage(New FormattedString(New FormattedString(PictureLib.LongOperation), New FormattedString(Chars.LF + NStr("en = 'Waiting for an answer'; de = 'Auf eine Antwort warten'; ru = 'Ожидание ответа'"), New Font(, 18, False))));	
			EndIf;
		ElsIf Not vRow.IsCommandSent And Not vRow.IsResponseReceived Then
			If Not vRow.CommandType = "KZ" Then
				ShowStatusMessage(New FormattedString(New FormattedString(PictureLib.LongOperation), New FormattedString(Chars.LF + NStr("en = 'Sending command'; de = 'Befehl senden'; ru = 'Отправка команды'") + Chars.LF + "(" + (DocumentIndex + 1) + "/" + NumberOfKeys + ")", New Font(, 18, False))));
			Else
				ShowStatusMessage(New FormattedString(New FormattedString(PictureLib.LongOperation), New FormattedString(Chars.LF + NStr("en = 'Sending command'; de = 'Befehl senden'; ru = 'Отправка команды'"), New Font(, 18, False))));	
			EndIf;
		EndIf;						
	Else
		vMsg = NStr("en = 'Command processing error'; de = 'Fehler bei der Befehlsverarbeitung'; ru = 'Ошибка обработки команды'") + Chars.LF + "(" + (DocumentIndex + 1) + "/" + NumberOfKeys + ")"; 
		ShowStatusMessage(New FormattedString(vMsg, New Font(, 18, True)), True);
		IsError = True;
		vResult = True;	
	EndIf;
	Return vResult;
EndFunction // WaitingForResultsAtServer

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetRoomInterfaceTypeForCheckIn(pInteractionParameters)
	vResult = Catalogs.RoomInterfaceTypes.EmptyRef();
	vQ = New Query();
	vQ.Text =
	"SELECT
	|	ExternalSystemsObjectCodesMappings.ObjectRef AS RoomInterfaceType
	|INTO RoomInterface
	|FROM
	|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
	|WHERE
	|	ExternalSystemsObjectCodesMappings.Hotel = &qHotel
	|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
	|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""RoomInterfaceTypes""
	|	AND VALUETYPE(ExternalSystemsObjectCodesMappings.ObjectRef) = TYPE(Catalog.RoomInterfaceTypes)
	|	AND NOT ExternalSystemsObjectCodesMappings.ObjectRef = VALUE(Catalog.RoomInterfaceTypes.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInterfaceTypes.Ref AS Ref
	|FROM
	|	Catalog.RoomInterfaceTypes AS RoomInterfaceTypes
	|		LEFT JOIN RoomInterface AS RoomInterface
	|		ON RoomInterfaceTypes.Ref = RoomInterface.RoomInterfaceType
	|WHERE
	|	NOT RoomInterfaceTypes.DeletionMark
	|	AND RoomInterfaceTypes.TurnOnParameters LIKE ""GI%""";
	
	vQ.SetParameter("qHotel", pInteractionParameters.Hotel); 
	vQ.SetParameter("qExternalSystemCode", pInteractionParameters.InteractionID);
	
	vQResult = vQ.Execute().Unload();
	
	If vQResult.Count() > 0 Then
		vResult = vQResult[0].Ref;
	EndIf;
	
	Return vResult;
EndFunction // GetRoomInterfaceTypeForCheckIn

// --------------------------------------------------------------------------------
&AtServerNoContext
Function CheckExistenceDocumentCheckIn(pParentDoc, pRoomInterfaceType, rRoomInterfaceStatus);
	vQ = New Query();
	vQ.Text = 
	"SELECT TOP 1
	|	RoomInterfaceStatus.Ref AS Ref,
	|	RoomInterfaceStatus.IsProcessed AS IsProcessed
	|FROM
	|	Document.RoomInterfaceStatus AS RoomInterfaceStatus
	|WHERE
	|	NOT RoomInterfaceStatus.DeletionMark
	|	AND RoomInterfaceStatus.ParentDoc = &qParentDoc
	|	AND NOT RoomInterfaceStatus.IsCanceled
	|	AND RoomInterfaceStatus.RoomInterfaceType = &qRoomInterfaceType
	|
	|ORDER BY
	|	RoomInterfaceStatus.Date DESC"; 
	
	vQ.SetParameter("qParentDoc", pParentDoc); 
	vQ.SetParameter("qRoomInterfaceType", pRoomInterfaceType);
	
	vResult = vQ.Execute().Unload();
	
	For Each vRow In vResult Do
		rRoomInterfaceStatus = vRow.Ref;
		Return Not vRow.IsProcessed; 
	EndDo;
	
	Return True;
EndFunction // CheckExistenceDocumentCheckIn

#EndRegion
