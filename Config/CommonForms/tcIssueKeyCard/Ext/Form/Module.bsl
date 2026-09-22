
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	DoorLockSystem = Undefined;
	Workstation = SessionParameters.CurrentWorkstation;
	If Parameters.Property("ParametersKeyCard") And TypeOf(Parameters.ParametersKeyCard) = Type("Structure") Then
		FillPropertyValues(ThisObject, Parameters.ParametersKeyCard); // ParametersKeyCard could have DoorLockSystem item inside 
		If ValueIsFilled(Folio) Then
			FolioNumber = Folio.Number;
		EndIf;
	EndIf;
	NumberOfKeys = 1;
	OneGuestMode = False;
	If Parameters.Property("ParametersOneGuestMode") And 
		TypeOf(Parameters.ParametersOneGuestMode) = Type("Boolean") And 
		Parameters.ParametersOneGuestMode Then
		OneGuestMode = True;
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	// Get door lock system attached to this workstation
	If Not ValueIsFilled(DoorLockSystem) Then
		vDoorLockSystemsArray = GetDoorLockSystems(Workstation, Room);
		If vDoorLockSystemsArray.Count() > 1 And ValueIsFilled(ParentDoc) Then
			vParams = New Structure("DoorLockSystemsArray, ParentDoc, ParametersOneGuestMode", vDoorLockSystemsArray, ParentDoc, OneGuestMode);
			OpenForm("CommonForm.tcDoorLockSystemChoiceForm", vParams, FormOwner, Workstation);
			pCancel = True;
			Return;
		ElsIf vDoorLockSystemsArray.Count() = 1 Then 
			DoorLockSystem = vDoorLockSystemsArray[0];
		EndIf;
	EndIf;
	If Not ValueIsFilled(DoorLockSystem) Then
		If ValueIsFilled(Workstation) And tcOnServer.cmGetAttributeByRef(Workstation, "HasConnectionToDoorLockSystem") Then
			DoorLockSystem = tcOnServer.cmGetAttributeByRef(Workstation, "DoorLockSystemParameters");
		EndIf;
	EndIf;
	If ValueIsFilled(DoorLockSystem) Then
		// Check if we have to open special form or use this one
		vInteractionParameters = tcOnServer.cmGetAttributeByRef(DoorLockSystem, "InteractionParameters"); 	
		If ValueIsFilled(vInteractionParameters) Then
			vDataProcessor = tcOnServer.cmGetAttributeByRef(vInteractionParameters, "DataProcessor");
			If ValueIsFilled(vDataProcessor) Then
				vDataProcessorName = GetDataProcessorName(vDataProcessor);
				If vDataProcessorName <> Undefined And ValueIsFilled(ParentDoc) Then
					vParametersKeyCard = tcOnServer.cmFillParametersKeyCard(ParentDoc);
					vParams = New Structure();
					vParams.Insert("ParametersKeyCard", vParametersKeyCard);
					vParams.Insert("ParametersOneGuestMode", OneGuestMode);
					vParams.Insert("DataProcessor", vDataProcessor);
					vParams.Insert("InteractionParameters", vInteractionParameters);
					vParams.ParametersKeyCard.Insert("DoorLockSystemParameters", DoorLockSystem);
					OpenForm(vDataProcessorName, vParams, ThisObject.FormOwner, Workstation, , , , FormWindowOpeningMode.LockOwnerWindow);
					pCancel = True;
					Return;
				EndIf;
			EndIf;
		EndIf;
		// Continue to open this form
		vDoorLockSystemType = tcOnServer.cmGetAttributeByRef(DoorLockSystem, "DoorLockSystemType");
		If vDoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.Orbita5X") Or 
			vDoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.Orbita4X") Then
			Items.AddKey.Visible = False;
			Items.NumberOfKeys.Visible = False;
		ElsIf vDoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.BonwinAutonomous") Or 
			vDoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.iLocks") Or 
			vDoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.proUSB") Then
			Items.NumberOfKeys.Visible = False;	
		Else
			If ValueIsFilled(Folio) Then
				If Not ValueIsFilled(ParentDoc) Then
					ParentDoc = tcOnServer.cmGetAttributeByRef(Folio, "ParentDoc");
				EndIf;
				If Not OneGuestMode Then
					If ValueIsFilled(ParentDoc) Then
						If TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") Or 
							TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Then
							vAccommodationTemplate = tcOnServer.cmGetAttributeByRef(ParentDoc, "AccommodationTemplate");
							If ValueIsFilled(vAccommodationTemplate) Then
								vNumberOfAdults = tcOnServer.cmGetAttributeByRef(vAccommodationTemplate, "NumberOfAdults");
								vNumberOfTeenagers = tcOnServer.cmGetAttributeByRef(vAccommodationTemplate, "NumberOfTeenagers");
								vNumberOfChildren = tcOnServer.cmGetAttributeByRef(vAccommodationTemplate, "NumberOfChildren");
								NumberOfKeys = vNumberOfAdults + vNumberOfTeenagers + vNumberOfChildren;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf; 
		
		If vDoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.Orbita5X")
			Or vDoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.proUSB")
			Or vDoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.NORWEQMF") Then
			Items.DelKey.Visible = True;
			Items.DelKey.Enabled = True;
		EndIf; 
		
		If vDoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.HSU") Or 
			vDoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.OmniTec") Or
			vDoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.Xeeder") Then
			Items.Cancel.Visible = True;
			Items.Cancel.Enabled = True;
		EndIf;
		
		If vDoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.Adel") Or
			vDoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.Bonwin") Or
			vDoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.BonwinAutonomous") Or
			vDoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.iLocks") Or
			vDoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.Locstar") Or
			vDoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.NORWEQMF") Or
			vDoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.Orbita4X") Or
			vDoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.Orbita5X") Or
			vDoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.OZLocks") Or
			vDoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.proUSB") Then
			Items.FormInstall.Visible = True;
			Items.FormInstall.Enabled = True;
		EndIf;	
		
		// Set availability of the door lock system authorizations
		vAllowDynamicAuthorizations = tcOnServer.cmGetAttributeByRef(DoorLockSystem, "AllowDynamicAuthorizations");
		Items.DoorLockSystemAuthorization.Enabled = False;
		Items.DoorLockSystemAuthorization.Visible = False;
		If vAllowDynamicAuthorizations Then
			If tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToSetDoorLockSystemAuthorizations") Then
				Items.DoorLockSystemAuthorization.Visible = True;
				Items.DoorLockSystemAuthorization.Enabled = True;
			EndIf;
		EndIf;
		If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToChangeCheckOutDateInDoorLockSystem") Then
			Items.CheckOutDate.ReadOnly = True;
		Else
			Items.CheckOutDate.ReadOnly = False;
		EndIf;
		// Show status
		ShowStatusMessage(NStr("en='Choose action';ru='Выберите действие';de='Wählen Sie die Aktion'"));
	Else
		// Show status
		ShowStatusMessage(NStr("en='Door lock system connection is not configured for this workstation!';
		|ru='На этом рабочем месте не настроено подключение к замковой системе!';
		|de='Dieser Arbeitsplatz ist nicht für die Verbindung mit der Schließanlage konfiguriert!'"));
	EndIf;
EndProcedure // OnOpen

// --------------------------------------------------------------------------------
&AtClient
Procedure ExternalEvent(pSource, pEvent, pData)
	If Not IsInputAvailable() Then
		Return;
	EndIf;
	
	vEventData = tcConnectionHardwareAtClient.cmGetExternalEventResultInputDevice(pSource, pEvent, pData);
	If IsBlankString(vEventData.DeviceData) Then
		Return;
	EndIf;
	
	If vEventData.DeviceType = "MagneticStripeCardReader" Then
		vDeviceArr = IsReadyToIssueKeyCards();
		If TypeOf(vDeviceArr) <> Type("Structure") Then
			Return;
		EndIf;
		
		vParameters = New Structure("Room, CheckInDate, CheckOutDate, Guest, ParentDoc, Folio, FolioNumber, AccommodationType, DoorLockSystemAuthorization, NumberOfKeys, IdentificationCard", Room, CheckInDate, CheckOutDate, Guest, ParentDoc, Folio, FolioNumber, AccommodationType, DoorLockSystemAuthorization, NumberOfKeys, IdentificationCard);
		vRC = vDeviceArr.Modul.pmRegisterNewCard(vEventData.DeviceData, False, vParameters);
		If ValueIsFilled(vParameters.IdentificationCard) Then
			IdentificationCard = vParameters.IdentificationCard;
			ShowStatusMessage(NStr("en='Input number of keys and choose action';ru='Укажите кол-во карт и выберите действие';de='Geben Sie die Menge der Karten an und wählen Sie eine Aktion aus'"));
		Else
			vErrorDescription = vDeviceArr.Modul.pmGetErrorDescription(vRC, vDeviceArr.SystemName);
			ShowStatusMessage(NStr("en='Error registering identification card! ';ru='Ошибка при регистрации карты идентификации! ';de='Error registering identification card! '") + vErrorDescription, True);
		EndIf;
	EndIf;
EndProcedure // ExternalEvent

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CheckOutDateStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vDate = BegOfDay(CheckOutDate);
	ShowInputDate(New NotifyDescription("AfterEnteringTheDate", ThisForm), vDate, NStr("ru='Введите дату';en='Enter date';de='Datum eingeben'"), DateFractions.Date);
EndProcedure // CheckOutDateStartChoice

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure NewKey(pCommand)
	vDeviceArr = IsReadyToIssueKeyCards();
	If TypeOf(vDeviceArr) = Type("Structure") Then
		If Not CheckPermissionsToIssueKeyCards() Then
			Return;
		EndIf;
		vIndex = 1;
		ShowStatusMessage(NStr("ru='Приложите ключ для гостя №'; en='Put a key for the guest #'; de='Legte einen schlüssel für den Gast #'")+String(vIndex)+" ("+tcOnServer.cmGetAttributeByRef(Guest, "FullName")+")");
		vParameters = New Structure("Room, CheckInDate, CheckOutDate, Guest, ParentDoc, Folio, FolioNumber, AccommodationType, DoorLockSystemAuthorization, NumberOfKeys, IdentificationCard", Room, CheckInDate, CheckOutDate, Guest, ParentDoc, Folio, FolioNumber, AccommodationType, DoorLockSystemAuthorization, NumberOfKeys, IdentificationCard);
		vErrorMessage = "";
		vNumberOfIterations = 1;
		If Items.NumberOfKeys.Visible And NumberOfKeys > 1 Then
			If vDeviceArr.SystemName <> "Kaba Ilco" And 
				vDeviceArr.SystemName <> "Kaba Saflok" And 
				vDeviceArr.SystemName <> "Locstar" And 
				vDeviceArr.SystemName <> "Novilock" And 
				vDeviceArr.SystemName <> "Onity HT22" And 
				vDeviceArr.SystemName <> "Onity HT24" And 
				vDeviceArr.SystemName <> "Onity HT28" And 
				vDeviceArr.SystemName <> "Salto Hotel" And 
				vDeviceArr.SystemName <> "VingCard Vision" And
				vDeviceArr.SystemName <> "Visionline (AssaAbloy)" And 
				vDeviceArr.SystemName <> "TimeLox 2300" Then 
				vNumberOfIterations = NumberOfKeys;
			EndIf;
		EndIf;
		i = 0;
		While i < vNumberOfIterations Do
			If i = 0 Then
				vErrorCode = vDeviceArr.Modul.pmNewKey(vDeviceArr, vParameters, vErrorMessage);
			Else
				vErrorCode = vDeviceArr.Modul.pmAddKey(vDeviceArr, vParameters, vErrorMessage);
			EndIf;
			If vErrorCode <> 0 Then
				If vErrorCode = -1 Then
					ShowStatusMessage(NStr("en='Connection error! ';ru='Ошибка подключения! ';de='Anschlussfehler! '") + vErrorCode + " - " + ?(IsBlankString(vErrorMessage), vDeviceArr.Modul.pmGetErrorDescription(vErrorCode, vDeviceArr.SystemName), vErrorMessage), True);
				Else	
					ShowStatusMessage(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode + " - " + ?(IsBlankString(vErrorMessage), vDeviceArr.Modul.pmGetErrorDescription(vErrorCode, vDeviceArr.SystemName), vErrorMessage), True);
				EndIf;
				Break;
			Else
				i = i + 1;
				If i < vNumberOfIterations Then
					ShowMessageBox(, NStr("en = 'Use the next key card...'; de = 'Verwenden Sie die nächste Schlüsselkarte...'; ru = 'Используйте следующую ключ-карту...'"), 2);
					WaitOnServer(1);
				Else
					If vDeviceArr.SystemName = "TimeLox 2300" Then 
						ShowMessageBox(New NotifyDescription("pmCloseForm", ThisObject), NStr("en = 'Insert the key card into the encoder'; de = 'Setzen Sie die Schlüsselkarte in den Encoder ein'; ru = 'Вставьте ключ-карту в энкодер'"), 4);
					Else
						ShowMessageBox(New NotifyDescription("pmCloseForm", ThisObject), NStr("en='Success';ru='Успешно';de='Erfolgreich'"), 4);
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // NewKey

// --------------------------------------------------------------------------------
&AtClient
Procedure AddKey(pCommand)
	vDeviceArr = IsReadyToIssueKeyCards();
	If TypeOf(vDeviceArr) = Type("Structure") Then
		If Not CheckPermissionsToIssueKeyCards() Then
			Return;
		EndIf;
		vIndex = 1;
		ShowStatusMessage(NStr("ru='Приложите ключ для гостя №'; en='Put a key for the guest #'; de='Legte einen schlüssel für den Gast #'")+String(vIndex)+" ("+tcOnServer.cmGetAttributeByRef(Guest, "FullName")+")");
		vParameters = New Structure("Room, CheckInDate, CheckOutDate, Guest, ParentDoc, Folio, FolioNumber, AccommodationType, DoorLockSystemAuthorization, NumberOfKeys, IdentificationCard", Room, CheckInDate, CheckOutDate, Guest, ParentDoc, Folio, FolioNumber, AccommodationType, DoorLockSystemAuthorization, NumberOfKeys, IdentificationCard);
		vErrorMessage = "";
		vNumberOfIterations = 1;
		If Items.NumberOfKeys.Visible And NumberOfKeys > 1 Then
			If vDeviceArr.SystemName <> "Kaba Ilco" And 
				vDeviceArr.SystemName <> "Kaba Saflok" And 
				vDeviceArr.SystemName <> "Locstar" And 
				vDeviceArr.SystemName <> "Novilock" And 
				vDeviceArr.SystemName <> "Onity HT22" And 
				vDeviceArr.SystemName <> "Onity HT24" And 
				vDeviceArr.SystemName <> "Onity HT28" And 
				vDeviceArr.SystemName <> "Salto Hotel" And 
				vDeviceArr.SystemName <> "VingCard Vision" And
				vDeviceArr.SystemName <> "Visionline (AssaAbloy)" And 
				vDeviceArr.SystemName <> "TimeLox 2300" Then 
				vNumberOfIterations = NumberOfKeys;
			EndIf;
		EndIf;
		i = 0;
		While i < vNumberOfIterations Do
			vErrorCode = vDeviceArr.Modul.pmAddKey(vDeviceArr, vParameters, vErrorMessage);
			If vErrorCode <> 0 Then
				If vErrorCode = -1 Then
					ShowStatusMessage(NStr("en='Connection error! ';ru='Ошибка подключения! ';de='Anschlussfehler! '") + vErrorCode + " - " + ?(IsBlankString(vErrorMessage), vDeviceArr.Modul.pmGetErrorDescription(vErrorCode, vDeviceArr.SystemName), vErrorMessage), True);
				Else	
					ShowStatusMessage(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode + " - " + ?(IsBlankString(vErrorMessage), vDeviceArr.Modul.pmGetErrorDescription(vErrorCode, vDeviceArr.SystemName), vErrorMessage), True);
				EndIf;
				Break;
			Else
				i = i + 1;
				If i < vNumberOfIterations Then
					ShowMessageBox(, NStr("en = 'Use the next key card...'; de = 'Verwenden Sie die nächste Schlüsselkarte...'; ru = 'Используйте следующую ключ-карту...'"), 2);
					WaitOnServer(1);
				Else
					If vDeviceArr.SystemName = "TimeLox 2300" Then 
						ShowMessageBox(New NotifyDescription("pmCloseForm", ThisObject), NStr("en = 'Insert the key card into the encoder'; de = 'Setzen Sie die Schlüsselkarte in den Encoder ein'; ru = 'Вставьте ключ-карту в энкодер'"), 4);
					Else
						ShowMessageBox(New NotifyDescription("pmCloseForm", ThisObject), NStr("en='Success';ru='Успешно';de='Erfolgreich'"), 4);
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // AddKey

// --------------------------------------------------------------------------------
&AtClient
Procedure Install(pCommand)
	vDeviceArr = IsReadyToIssueKeyCards();
	If TypeOf(vDeviceArr) = Type("Structure") Then
		vDeviceArr.Modul.pmInstall();
	EndIf;
EndProcedure // Install

// --------------------------------------------------------------------------------
&AtClient
Procedure Verify(pCommand)
	Var vCardData;
	vDeviceArr = IsReadyToIssueKeyCards();
	If TypeOf(vDeviceArr) = Type("Structure") Then
		vIndex = 1;
		ShowStatusMessage(NStr("ru='Приложите проверяемую карту'; en='Put a card to be checked'; de='Befestigen Sie die zu überprüfende Karte'"));
		vParameters = New Structure("Room, CheckInDate, CheckOutDate, Guest, ParentDoc, Folio, FolioNumber, AccommodationType, DoorLockSystemAuthorization, NumberOfKeys, IdentificationCard", Room, CheckInDate, CheckOutDate, Guest, ParentDoc, Folio, FolioNumber, AccommodationType, DoorLockSystemAuthorization, NumberOfKeys, IdentificationCard);
		vErrorCode = vDeviceArr.Modul.pmVerify(vCardData, vDeviceArr, vParameters);
		If vErrorCode <> 0 Then
			ShowStatusMessage(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode + " - " + vDeviceArr.Modul.pmGetErrorDescription(vErrorCode, vDeviceArr.SystemName), True);
		ElsIf TypeOf(vCardData) = Type("Structure") Then
			If vCardData.ReplyType = "Message" Then
				ShowStatusMessage(vCardData.ReplyDescription, True);
			Else
				vMsg = TrimAll(vCardData.IsCardValidDescription) + Chars.LF + 
				NStr("en='Room: '; ru='Номер: '; de='Zimmer: '") + String(vCardData.CardRoom) + 
				NStr("en=', Guest: '; ru=', Гость: '; de=', Gast: '") + String(vCardData.CardFullName) + Chars.LF + 
				NStr("en='Check-in: '; ru='Заезд: '; de='Anreise: '") + Format(vCardData.CardCheckInDate, "DF='dd.MM.yyyy HH:mm'") + 
				NStr("en=', check-out: '; ru=', выезд: '; de=', abreise: '") + Format(vCardData.CardCheckOutDate, "DF='dd.MM.yyyy HH:mm'");
				ShowStatusMessage(vMsg);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // Verify

// --------------------------------------------------------------------------------
&AtClient
Procedure DelKey(pCommand)
	Var vCardData;
	vDeviceArr = IsReadyToIssueKeyCards();
	If TypeOf(vDeviceArr) = Type("Structure") Then
		vIndex = 1;
		ShowStatusMessage(NStr("ru='Приложите проверяемую карту'; en='Put a card to be checked'; de='Befestigen Sie die zu überprüfende Karte'"));
		vErrorCode = vDeviceArr.Modul.pmDelete(vDeviceArr);
		If vErrorCode <> 0 Then
			ShowStatusMessage(NStr("en='Card deletion error: ';ru='Ошибка удаления карты: ';de='Fehler beim löschen der Karte: '") + vErrorCode + " - " + vDeviceArr.Modul.pmGetErrorDescription(vErrorCode, vDeviceArr.SystemName));
		Else
			ShowStatusMessage(NStr("en='Card deleted';ru='Карта удалена';de='Karte gelöscht'"));	
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure ShowStatusMessage(pMsg = "", pAttention = False)
	HelpMessage = pMsg;
	If pAttention Then
		Items.HelpMessage.TextColor = WebColors.Red;
	Else
		Items.HelpMessage.TextColor = WebColors.Black;
	EndIf;
EndProcedure // ShowStatusMessage

// --------------------------------------------------------------------------------
&AtClient
Function IsReadyToIssueKeyCards()
	vDriver = Undefined;
	vCurWstn = tcOnServer.cmGetSessionParametersAttribute("CurrentWorkstation");
	If ValueIsFilled(vCurWstn) Then
		vCurWstnArr = tcOnServer.cmGetAtributeAsArray(vCurWstn);
		If ValueIsFilled(DoorLockSystem) Then
			vDevice = DoorLockSystem;
		Else	
			ShowMessageBox(,Nstr("en='Door lock system is not configurated properly for the current workstation!';ru='Система электронных замков на данном рабочем месте не настроена!';de='Das System für elektronische Schlösser ist auf diesem Arbeitsplatz nicht eingestellt!'"),,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
			Return False;
		EndIf;
		
		vDriver = tcOnClient.cmGetModulTO(vDevice);
	Else
		ShowMessageBox(,Nstr("en = 'The workstation is not defined'; ru = 'Рабочее место не определено'; de = 'Die Workstation ist nicht definiert'"),,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
		Return  False;
	EndIf;
	If Not vDriver = Undefined Then
		Return vDriver;
	Else
		ShowMessageBox(,Nstr("en = 'Work with this device is not supported'; ru = 'Работа с драйвером этого устройства не поддерживается'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird'"),,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
	EndIf;	
	Return  False;
EndFunction // IsReadyToIssueKeyCards

// --------------------------------------------------------------------------------
&AtServer
Function CheckPermissionsToIssueKeyCards()
	vBalances = cmGetClientRoomBalances(New Boundary(BegOfDay(CheckOutDate), BoundaryType.Excluding), Room, Guest);
	For Each vBalancesRow In vBalances Do
		If (vBalancesRow.ClientSumBalance + vBalancesRow.ClientLimitBalance) > 0 Then
			vMessage = NStr("en='Client has debt on " + Format(CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + " date for the " + TrimAll(Room) + " room!'; 
			|de='Kunde hat Schulden am " + Format(CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + " Datum für das " + TrimAll(Room) + " Zimmer!'; 
			|ru='На дату " + Format(CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + " у гостя в номере " + TrimAll(Room) + " есть задолженность!'");
			If Not cmCheckUserPermissions("HavePermissionToIssueKeyCardsForGuestsWithDebtsOnKeyValidToDate") Then
				WriteLogEvent(NStr("en='DoorLockSystem.Error';ru='СистемаЭлектронныхЗамков.Ошибка';de='DoorLockSystem.Error'"), EventLogLevel.Warning, , Guest, vMessage);
				tcCommonFunctionOnClientServer.UserMessage(vMessage);
				Return False;
			Else
				// User activity history   
				vEventDescription = NStr("en = 'Issue of a key without payment'; de = 'Schlüsselübergabe ohne Bezahlung'; ru = 'Выдача ключа без оплаты'") + Chars.LF + vMessage;
				InformationRegisters.UserActionsHistory.WriteUserActivityRecord(ParentDoc, vEventDescription);
				Break;
			EndIf;
		EndIf;
	EndDo;
	If Not cmCheckUserPermissions("HavePermissionToIssueKeyCardsForGuestsWithDebtsOnKeyValidToDate") Then
		If ValueIsFilled(AccommodationType) Then
			If AccommodationType.Type = Enums.AccomodationTypes.AdditionalBed Or
				AccommodationType.Type = Enums.AccomodationTypes.Together Then
				vMessage = NStr("en='You do not have rights to issue keys to guests with " + TrimAll(AccommodationType) + " accommodation type! Operation will be canceled!'; 
				|de='Sie haben kein Recht, den Schlüssel an Gäste mit der Art der Unterkunft " + TrimAll(AccommodationType) + " auszugeben! Operation wird abgesagt!'; 
				|ru='Нет прав выписывать ключи гостям с видом размещения " + TrimAll(AccommodationType) + "! Операция будет отменена!'");
				WriteLogEvent(NStr("en='DoorLockSystem.Error';ru='СистемаЭлектронныхЗамков.Ошибка';de='DoorLockSystem.Error'"), EventLogLevel.Warning, , Guest, vMessage);
				tcCommonFunctionOnClientServer.UserMessage(vMessage);
				Return False;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(Folio) And Folio.IsClosed Then
		vMessage = TrimAll(Guest) + ", " + TrimAll(Room) + ", " + Format(CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(CheckOutDate, "DF='dd.MM.yyyy HH:mm'");
		// User activity history   
		vEventDescription = NStr("en = 'Request a key for a closed folio'; de = 'Fordern Sie einen Schlüssel für ein geschlossenes Folio an'; ru = 'Запрос на выдачу ключа по закрытому фолио'") + Chars.LF + vMessage;
		InformationRegisters.UserActionsHistory.WriteUserActivityRecord(ParentDoc, vEventDescription);
	EndIf;
	
	Return True;
EndFunction // CheckPermissionsToIssueKeyCards

// --------------------------------------------------------------------------------
&AtClient
Procedure pmCloseForm(pAdditionalParameters) Export
	Close();
EndProcedure // pmCloseForm

// --------------------------------------------------------------------------------
&AtClient
Procedure AfterEnteringTheDate(pDate, pExtra) Export 
	vTime = CheckOutDate;
	ShowInputDate(New NotifyDescription("AfterEnteringTheTime", ThisForm, New Structure("Date", pDate)), vTime, NStr("ru='Введите время';en='Enter time';de='Zeit eingeben'"), DateFractions.Time);
EndProcedure // AfterEnteringTheDate

// --------------------------------------------------------------------------------
&AtClient
Procedure AfterEnteringTheTime(pTime, pExtra) Export 
	vOldCheckOutDate = CheckOutDate; 
	If pTime = Undefined And pExtra.Date = Undefined Then
		Return;
	ElsIf pExtra.Date <> Undefined And pTime <> Undefined Then
		CheckOutDate = BegOfDay(pExtra.Date) + (pTime - BegOfDay(pTime));
	ElsIf pExtra.Date <> Undefined And pTime = Undefined Then
		vTeme = CheckOutDate - BegOfDay(CheckOutDate);  
		CheckOutDate = BegOfDay(pExtra.Date) + vTeme;
	ElsIf pExtra.Date = Undefined And pTime <> Undefined Then
		vDate = BegOfDay(CheckOutDate);
		CheckOutDate = vDate + (pTime - BegOfDay(pTime));
	EndIf;
	If CheckOutDate < CheckInDate Then
		CheckOutDate = vOldCheckOutDate;
		ShowMessageBox(,NStr("ru='Дата выезда не может быть раньше заезда';en='Departure date cannot be earlier than arrival';de='Das Abreisedatum kann nicht vor der Ankunft liegen'"));
	EndIf;
EndProcedure // AfterEnteringTheTime

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetDoorLockSystems(pWorkstation, pRoom)
	vDoorLockSystemsArray = New Array();
	
	vQry = New Query; 
	vQry.Text = "SELECT
	|	ConnectedDevices.DeviceSettings AS DeviceSettings
	|FROM
	|	InformationRegister.ConnectedDevices AS ConnectedDevices
	|WHERE
	|	ConnectedDevices.Workstation = &qCurrentWorkstation
	|	AND ConnectedDevices.DeviceType = &qDeviceType
	|	AND ConnectedDevices.IsActive";
	vQry.SetParameter("qCurrentWorkStation", pWorkstation);
	vQry.SetParameter("qDeviceType", Enums.DeviceTypes.DoorLockSystemParameters);
	vResult = vQry.Execute().Unload();
	For Each vRow In vResult Do
		If ValueIsFilled(pRoom.DoorLockSystemType) Then
			If vRow.DeviceSettings.DoorLockSystemType = pRoom.DoorLockSystemType Then 
				vDoorLockSystemsArray.Add(vRow.DeviceSettings);
			EndIf;
		Else
			vDoorLockSystemsArray.Add(vRow.DeviceSettings);
		EndIf;
	EndDo;
	
	Return vDoorLockSystemsArray;
EndFunction // GetDoorLockSystems

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetDataProcessorName(pDataProcessor)
	Return Catalogs.DataProcessors.GetNameDataProcessorByProcessing(pDataProcessor);
EndFunction // GetDataProcessorName

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure WaitOnServer(pSec) 
	cmWait(pSec);
EndProcedure // WaitOnServer

// -----------------------------------------------------------------------------
&AtClient
Procedure Cancel(pCommand)
	Var vCardData;
	vParameters = New Structure("Room, CheckInDate, CheckOutDate, Guest, ParentDoc, Folio, FolioNumber, AccommodationType, DoorLockSystemAuthorization, NumberOfKeys, IdentificationCard", Room, CheckInDate, CheckOutDate, Guest, ParentDoc, Folio, FolioNumber, AccommodationType, DoorLockSystemAuthorization, NumberOfKeys, IdentificationCard);
	vDeviceArr = IsReadyToIssueKeyCards();
	If TypeOf(vDeviceArr) = Type("Structure") Then
		vIndex = 1;
		ShowStatusMessage(NStr("ru='Приложите проверяемую карту'; en='Put a card to be checked'; de='Befestigen Sie die zu überprüfende Karte'"));
		vErrorCode = vDeviceArr.Modul.pmCancel(vDeviceArr,vParameters);
		If vErrorCode <> 0 Then
			ShowStatusMessage(NStr("en='Card deletion error: ';ru='Ошибка удаления карты: ';de='Fehler beim löschen der Karte: '") + vErrorCode + " - " + vDeviceArr.Modul.pmGetErrorDescription(vErrorCode, vDeviceArr.SystemName));
		Else
			ShowStatusMessage(NStr("en='Card deleted';ru='Карта удалена';de='Karte gelöscht'"));	
		EndIf;
	EndIf;
EndProcedure // Cancel

#EndRegion