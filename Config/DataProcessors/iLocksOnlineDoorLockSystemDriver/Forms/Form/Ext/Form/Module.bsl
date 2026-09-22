
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
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
		Obj.ExternalInteraction = vInteractionParameters;
	EndIf;
	Obj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(Obj,"Object");
	
	If ParametersLock.Property("ParametersKeyCard") And TypeOf(ParametersLock.ParametersKeyCard) = Type("Structure") Then
		FillPropertyValues(Object, ParametersLock.ParametersKeyCard);
	EndIf; 
	
	ShowStatusMessage(NStr("en='Choose action';ru='Выберите действие';de='Wählen Sie die Aktion'"));
	
	Items.GroupKeyCard.Visible = True;
	
	vRoom = Object.Room;
	If ValueIsFilled(vRoom) Then
		Items.GroupPassCode.Visible = vRoom.UsePassCode;
	EndIf;
	
	vAllowDynamicAuthorizations = tcOnServer.cmGetAttributeByRef(Object.DoorLockSystemParameters, "AllowDynamicAuthorizations");
	Items.DoorLockSystemAuthorization.Enabled = False;
	Items.DoorLockSystemAuthorization.Visible = False;
	If vAllowDynamicAuthorizations Then
		If tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToSetDoorLockSystemAuthorizations") Then
			Items.DoorLockSystemAuthorization.Visible = True;
			Items.DoorLockSystemAuthorization.Enabled = True;
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	UniqueKey = UUID;
EndProcedure // OnOpen

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure NewPassCode(pCommand)
	ShowStatusMessage(NStr("en = 'Generate PIN code'; de = 'PIN-Code-Generierung'; ru = 'Генерация PIN-кода'"));
	NewKeyAtServer(False, False);
EndProcedure // NewKey

// --------------------------------------------------------------------------------
&AtClient
Procedure ActionRoomInfo(pCommand)
	Items.RoomInfo.Visible = False;
	Items.HelpMessage1.Visible = True;
	ShowStatusMessage(NStr("en = 'Getting a PIN code'; de = 'Empfang eines PIN-Codes'; ru = 'Получение PIN-кода'"));
	ActionRoomInfoAtServer();
EndProcedure // Verify

// --------------------------------------------------------------------------------
&AtClient
Procedure NewKeyCard(pCommand)
	ShowStatusMessage(NStr("ru='Приложите ключ для гостя'; en='Put a key for the guest'; de='Legte einen schlüssel für den Gast'"));
	NewKeyAtServer(True, False);
EndProcedure // NewKeyCard

// --------------------------------------------------------------------------------
&AtClient
Procedure AddKeyCard(pCommand)
	ShowStatusMessage(NStr("ru='Приложите ключ для гостя'; en='Put a key for the guest'; de='Legte einen schlüssel für den Gast'"));
	NewKeyAtServer(True, True);
EndProcedure // AddKeyCard

// --------------------------------------------------------------------------------
&AtClient
Procedure VerifyKeyCard(pCommand)
	Items.RoomInfo.Visible = False;
	Items.HelpMessage1.Visible = True;
	ShowStatusMessage(NStr("ru='Приложите ключ для гостя'; en='Put a key for the guest'; de='Legte einen schlüssel für den Gast'"));
	VerifyKeyAtServer();
EndProcedure // VerifyKeyCard

// --------------------------------------------------------------------------------
&AtClient
Procedure ClearKeyCard(pCommand)
	Items.RoomInfo.Visible = False;
	Items.HelpMessage1.Visible = True;
	ShowStatusMessage(NStr("ru='Приложите ключ'; en='Put a key'; de='Legte einen schlüssel'"));
	ClearKeyCardAtServer();
EndProcedure // ClearKeyCard

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure ShowStatusMessage(pMsg = "", pAttention = False)
	HelpMessage = pMsg;
	If pAttention Then
		Items.HelpMessage.TextColor = WebColors.Red;
		Items.HelpMessage1.TextColor = WebColors.Red;
	Else
		Items.HelpMessage.TextColor = WebColors.Black;
		Items.HelpMessage1.TextColor = WebColors.Black;
	EndIf;
EndProcedure // ShowStatusMessage 

// -----------------------------------------------------------------------------
&AtServer
Procedure NewKeyAtServer(pIsKeyCard, pAddKey)
	vPINCode = "";
	vMessage = "";
	
	vObj = FormAttributeToValue("Object");
	
	vRoomInterfaceStatus = Undefined;
	If CheckExistenceDocumentCheckIn(Object.ParentDoc, Object.RoomInterfaceType, vRoomInterfaceStatus) Then
		vRoomInterfaceType = Object.RoomInterfaceType;
		
		If Not ValueIsFilled(vRoomInterfaceStatus) Then
			vStsObj = Documents.RoomInterfaceStatus.CreateDocument();
			vStsObj.Fill(Object.ParentDoc);
			vStsObj.RoomInterfaceType = vRoomInterfaceType;
			vStsObj.InterfaceType = vRoomInterfaceType.InterfaceType;
			vStsObj.ExtraParameters = vRoomInterfaceType.ExtraParameters; 
			vStsObj.Write(DocumentWriteMode.Write);
			vRoomInterfaceStatus = vStsObj.Ref;
		EndIf;
		
		vRoomInterfaceEvents = vObj.GetActiveRoomInterfaceEvents(Object.CheckInDate, vRoomInterfaceStatus);
		vObj.SendRoomInterfaceEvent(vRoomInterfaceEvents);
	EndIf;
	
	If vObj.pmGenerateKey(vPINCode, pIsKeyCard, pAddKey, vMessage) Then
		If pIsKeyCard Then
			ShowStatusMessage(NStr("en='Success';ru='Успешно';de='Erfolgreich'"));
		Else
			ShowStatusMessage(NStr("en = 'Pin code: '; de = 'PIN-Code: '; ru = 'Пин-код: '") + vPINCode);
		EndIf;
	Else
		If pIsKeyCard Then
			ShowStatusMessage(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + Chars.LF + vMessage, True);
		Else
			ShowStatusMessage(NStr("en = 'Pin code generation error:'; de = 'Fehler bei der PIN-Code-Generierung:'; ru = 'Ошибка генерации пин-кода:'") + Chars.LF + vMessage, True);
		EndIf;
	EndIf;
EndProcedure // NewKeyAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure VerifyKeyAtServer()
	RoomInfo.Clear();
	vMessage = "";
	
	Obj = FormAttributeToValue("Object");
	vCardInfo = Obj.pmReadCart(Object.DoorLockSystemParameters.EncoderNumber, vMessage);
	If vCardInfo = Undefined Then
		ShowStatusMessage(NStr("en = 'Error reading card: '; de = 'Kartenlesefehler: '; ru = 'Ошибка чтение карты: '") + Chars.LF + vMessage, True);
		Return;
	EndIf;
	
	Items.RoomInfo.Visible = True;
	Items.HelpMessage1.Visible = False;
	
	vData = vCardInfo["data"];
	If vData = Undefined Then
		Return;
	EndIf;
	
	vValue = vData["value"];
	If vValue = Undefined Then
		Return;
	EndIf;
	
	If vValue["isEmpty"] Then
		ShowStatusMessage(NStr("en = 'Card is empty'; de = 'Karte ist leer'; ru = 'Карта пуста'"));
		Return;
	EndIf;
	
	vRoomInfoRow = RoomInfo.Add();
	vRoomInfoRow.CheckInDate = XMLValue(Type("Date"), vValue["startDate"]);
	vRoomInfoRow.CheckOutDate = XMLValue(Type("Date"), vValue["endDate"]);
	
	vOwner = vValue["owner"];
	If vOwner = Undefined Then
		Return;
	EndIf;
	vRoomInfoRow.FullName = vOwner["name"];
	
	For Each vRoomRow In vValue["rooms"] Do
		vRoomInfoRow.Room = vRoomRow["name"];
	EndDo;
EndProcedure // NewKeyAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionRoomInfoAtServer()
	RoomInfo.Clear();
	vMessage = "";
	
	vObj = FormAttributeToValue("Object");
	vRoomInfo = vObj.pmGetRoomInfo( , vMessage);
	If vRoomInfo = Undefined Then
		ShowStatusMessage(NStr("en = 'Error reading card: '; de = 'Kartenlesefehler: '; ru = 'Ошибка чтение карты: '") + Chars.LF + vMessage, True);
		Return;
	EndIf;
	
	Items.RoomInfo.Visible = True;
	Items.HelpMessage1.Visible = False;
	
	vData = vRoomInfo["data"];
	If vData = Undefined Then
		Return;
	EndIf;
	
	vValue = vData["value"];
	If vValue = Undefined Then
		Return;
	EndIf;
	
	vRoom = vValue["name"];
	For Each vGuest In vValue["guests"] Do
		vRoomInfoRow = RoomInfo.Add();
		vRoomInfoRow.Room = vRoom;
		vRoomInfoRow.FullName = vGuest["name"];
		vRoomInfoRow.CheckInDate = XMLValue(Type("Date"), vGuest["startDate"]);
		vRoomInfoRow.CheckOutDate = XMLValue(Type("Date"), vGuest["endDate"]);
	EndDo;
EndProcedure // ActionRoomInfo

// -----------------------------------------------------------------------------
&AtServer
Procedure ClearKeyCardAtServer()
	vMessage = "";
	
	vObj = FormAttributeToValue("Object");
	vResult = vObj.pmClearKeyCard(vMessage);
	If vResult = Undefined Then
		ShowStatusMessage(NStr("en = 'Error: '; de = 'Fehler: '; ru = 'Ошибка: '") + Chars.LF + vMessage, True);
		Return;
	EndIf;
	
	Items.RoomInfo.Visible = True;
	Items.HelpMessage1.Visible = False;
EndProcedure // ClearKeyCardAtServer

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
