
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
	
	vRoomData = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.ExternalInteraction, "rooms", , Object.Room);
	If vRoomData.Count() > 0 Then
		Building = vRoomData[0].Building;
		Floor = vRoomData[0].Floor;
		Mac = vRoomData[0].Mac;
		UsePassCode = vRoomData[0].UsePassCode;
		UseKeyCard = vRoomData[0].UseKeyCard;
	EndIf;
	
	Items.GroupPassCode.Visible = UsePassCode Or (Not UsePassCode And Not UseKeyCard);
	Items.GroupKeyCard.Visible = UseKeyCard And Not IsBlankString(Mac);
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure NewPassCode(Command)
	ShowStatusMessage(NStr("ru='Приложите ключ для гостя №'; en='Put a key for the guest #'; de='Legte einen schlüssel für den Gast #'"));
	NewPassCodeAtServer();
EndProcedure // NewKey

// --------------------------------------------------------------------------------
&AtClient
Procedure VerifyPassCode(pCommand)
	vPINCodeArr = Undefined;
	If VerifyPassCodeAtServer(vPINCodeArr) Then
		vParam = ParametersLock;
		vParam.Insert("PINCodeList", vPINCodeArr);
		OpenForm("DataProcessor.ttLockDoorLockSystemDriver.Form.PINCodeList", vParam, ThisForm, UUID,,,, FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure // Verify

// --------------------------------------------------------------------------------
&AtClient
Async Procedure NewKeyCard(pCommand)
	vLock = Undefined;
	Try
		Object.IdentificationCard = PredefinedValue("Catalog.IdentificationCards.EmptyRef");
		
		ShowStatusMessage(NStr("en = 'Put a key for the guest'; de = 'Legte einen schlüssel für den Gast'; ru = 'Приложите ключ для гостя'"));
		
		vMessage = "";
		vHotelInfo = GetHotelInfo(vMessage);
		If IsBlankString(vHotelInfo) Then
			Raise vMessage;
		EndIf;
		
		vDoorLockSystemConnectionParameters = tcOnServer.cmGetAttributeByRef(Object.DoorLockSystemParameters, "DoorLockSystemConnectionParameters");
		vParams = tcDoorLocksAtServer.GetDoorLockSystemConnectionParameters(vDoorLockSystemConnectionParameters);
		
		vLock = Await ConnectNative(vParams, vHotelInfo);
		If TypeOf(vLock) = Type("String") Then
			Raise vLock;
		EndIf;
		
		vMinutes = 60;
		
		vCheckOutDate = Object.CheckOutDate;
		If vParams.AddMinutes <> 0 Then
			vCheckOutDate = vCheckOutDate + vParams.AddMinutes * vMinutes;
		EndIf;
		
		vInitialTimestamp = '19700101';
		
		vErrorCode = vLock.WriteCard(vHotelInfo, Building, Floor, Mac, ToUniversalTime(vCheckOutDate) - vInitialTimestamp, False);
		If vErrorCode <> 0 Then
			Raise NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + Format(vErrorCode, "NFD=0; NZ=0; NG=") + " - " + vLock.LastErrorDescription;
		EndIf;
		
		vBasis = 16;
		
		vCardID = "";
		If vParams.ReturnCardUID Then
			vCardIDHex = "";
			vErrorCode = vLock.GetCardNo(vCardIDHex);
			If vErrorCode = 0 And Not IsBlankString(vCardIDHex) Then
				If vParams.ConvertCardIDToDec Then
					vCardID = vCardIDHex;
				Else
					vCardID = tcCommonFunctionOnClientServer.DecToBasic(Number(vCardIDHex), vBasis);
				EndIf;
				
				Object.IdentificationCard = tcOnServer.GetClientIdentificationCard(vCardID, tcOnServer.GetClientIdentificationCardById(vCardID), Object.ParentDoc, Object.Folio, Object.Guest, Object.Room, Object.CheckInDate, Object.CheckOutDate, True, vCardID);
			EndIf;
		EndIf;
		tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.KeyIssued';ru='СистемаЭлектронныхЗамков.ВыданКлюч';de='DoorLockSystem.KeyIssued'"), "Information", , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(Object.Room) + ", " + Format(Object.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(Object.CheckOutDate, "DF='dd.MM.yyyy HH:mm'"));
		
		tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("NEW", TrimAll(vCardID), Object.Room, "", Object.CheckInDate, Object.CheckOutDate, Object.ParentDoc, Object.Guest, 1);
	Except
		vError = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		AddError(vError);
		ShowStatusMessage(vError, True);
	EndTry;
	
	DisconnectNative(vLock);
EndProcedure // NewKeyCard

// --------------------------------------------------------------------------------
&AtClient
Async Procedure VerifyKeyCard(pCommand)
	vLock = Undefined;
	Try
		Object.IdentificationCard = PredefinedValue("Catalog.IdentificationCards.EmptyRef");
		
		ShowStatusMessage(NStr("ru='Приложите ключ для гостя №'; en='Put a key for the guest #'; de='Legte einen schlüssel für den Gast #'"));
		
		vMessage = "";
		vHotelInfo = GetHotelInfo(vMessage);
		If IsBlankString(vHotelInfo) Then
			Raise vMessage;
		EndIf;
		
		vDoorLockSystemConnectionParameters = tcOnServer.cmGetAttributeByRef(Object.DoorLockSystemParameters, "DoorLockSystemConnectionParameters");
		vParams = tcDoorLocksAtServer.GetDoorLockSystemConnectionParameters(vDoorLockSystemConnectionParameters);
		
		vLock = Await ConnectNative(vParams, vHotelInfo);
		If TypeOf(vLock) = Type("String") Then
			Raise vLock;
		EndIf;
		
		vHotelArray = "";
		vErrorCode = vLock.ReadCard(vHotelInfo, vHotelArray);
		If vErrorCode <> 0 Then
			Raise NStr("en='Error reading key card: ';ru='Ошибка чтения карты: ';de='Fehler beim Lesen der Karte: '") + Format(vErrorCode, "NFD=0; NZ=0; NG=") + " - " + vLock.LastErrorDescription;
		EndIf;
		
		vBasis = 16;
		
		vCardID = "";
		If vParams.ReturnCardUID Then
			vCardIDHex = "";
			vErrorCode = vLock.GetCardNo(vCardIDHex);
			If vErrorCode = 0 And Not IsBlankString(vCardIDHex) Then
				If vParams.ConvertCardIDToDec Then
					vCardID = vCardIDHex;
				Else
					vCardID = tcCommonFunctionOnClientServer.DecToBasic(Number(vCardIDHex), vBasis);
				EndIf;
				
				Object.IdentificationCard = tcOnServer.GetClientIdentificationCard(vCardID, tcOnServer.GetClientIdentificationCardById(vCardID), Object.ParentDoc, Object.Folio, Object.Guest, Object.Room, Object.CheckInDate, Object.CheckOutDate, True, vCardID);
			EndIf;
		EndIf;
		
		ParseCardDescription(vHotelArray);
	Except
		vError = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		AddError(vError);
		ShowStatusMessage(vError, True);
	EndTry;
	
	DisconnectNative(vLock);
EndProcedure // VerifyKeyCard

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtClient
Procedure ParseCardDescription(pHotelArray)
	vMsg = "";
	
	#If Not WebClient Then
		vJSONReader = New JSONReader();
		vJSONReader.SetString(pHotelArray);
		vMap = ReadJSON(vJSONReader);
		vJSONReader.Close();
		
		For Each vRow In vMap Do
			vMsg = vMsg + vRow.Key + ": " + vRow.Value + Chars.LF;
		EndDo;
	#EndIf
	
	ShowStatusMessage(vMsg, False);
EndProcedure // ParseCardDescription

// --------------------------------------------------------------------------------
&AtClient
Async Function ConnectNative(pParams, pHotelInfo)
	vLock = Undefined;
	
	vSystemName = "TTLock";
	Try
		vTemplate = "DataProcessor.ttLockDoorLockSystemDriver.Template.AddInTTLockNative";
		vIsConnected = Await AttachAddInAsync(vTemplate, "Native", AddInType.Native);
		If Not vIsConnected Then
			Await InstallAddInAsync(vTemplate);
			vIsConnected = Await AttachAddInAsync(vTemplate, "Native", AddInType.Native);
		EndIf;
		
		If Not vIsConnected Then
			Raise "-999" + " - " + NStr("en = 'Native dll connection error'; de = 'Fehler bei der nativen DLL-Verbindung'; ru = 'Ошибка подключения Native dll'");
		EndIf;
		
		vLock = New("AddIn.Native.TTLock");
		
		vErrorCode = vLock.Connect("CardEncoder.dll");
		If vErrorCode <> 0 Then
			Raise Format(vErrorCode, "NFD=0; NZ=0; NG=") + " - " + vLock.LastErrorDescription;
		EndIf;
		
		vErrorCode = vLock.ConnectComm(pParams.Port);
		If vErrorCode <> 0 Then
			Raise Format(vErrorCode, "NFD=0; NZ=0; NG=") + " - " + vLock.LastErrorDescription;
		EndIf;
		
		vErrorCode = vLock.InitCardEncoder(pHotelInfo);
		If vErrorCode <> 0 Then
			Raise Format(vErrorCode, "NFD=0; NZ=0; NG=") + " - " + vLock.LastErrorDescription;
		EndIf;
	Except
		vError = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		Return StrTemplate(NStr("en = '%1 door lock system connection error: %2'; de = '%1 door lock system connection error: %2'; ru = 'Ошибка подключения системы электронных замков %1: %2'"), vSystemName, vError);
	EndTry;
	
	Return vLock;
EndFunction // ConnectNative

// -----------------------------------------------------------------------------
&AtClient
Procedure DisconnectNative(pLock)
	Try
		pLock.DisconnectComm();
		pLock.Disconnect();
		pLock = Undefined;
	Except
		pLock = Undefined;
	EndTry;
EndProcedure // pmDisconnect

// -----------------------------------------------------------------------------
&AtClient
Procedure AddError(pErrorText)
	tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.Error';ru='СистемаЭлектронныхЗамков.Ошибка';de='DoorLockSystem.Error'"), "Warning", , , pErrorText);
EndProcedure // AddError

// -----------------------------------------------------------------------------
&AtServer
Procedure ShowStatusMessage(pMsg = "", pAttention = False)
	HelpMessage = pMsg;
	If pAttention Then
		Items.HelpMessage.TextColor = WebColors.Red;
	Else
		Items.HelpMessage.TextColor = WebColors.Black;
	EndIf;
EndProcedure // ShowStatusMessage 

// -----------------------------------------------------------------------------
&AtServer
Procedure NewPassCodeAtServer()
	Obj = FormAttributeToValue("Object");
	vResponse = Undefined; 
	vErrorMessage = "";
	If Obj.pmNewKey(vResponse, vErrorMessage) Then 
		ShowStatusMessage(NStr("en = 'Pin code: '; de = 'PIN-Code: '; ru = 'Пин-код: '") + vResponse.keyboardPwd);
	Else
		ShowStatusMessage(NStr("en = 'Pin code generation error:'; de = 'Fehler bei der PIN-Code-Generierung:'; ru = 'Ошибка генерации пин-кода:'") + Chars.LF + vErrorMessage, True);
	EndIf;
EndProcedure // NewKeyAtServer

// -----------------------------------------------------------------------------
//
// Parameters:
//  pPINCodeArr	 - Array - Pin code list
// 
// Returns:
//  Boolean - Result
//
&AtServer
Function VerifyPassCodeAtServer(pPINCodeArr)
	vResult = True;
	Obj = FormAttributeToValue("Object");
	vErrorMessage = "";
	pPINCodeArr = Obj.pmVerify(vErrorMessage);
	If ValueIsFilled(vErrorMessage) Then
		ShowStatusMessage(NStr("en = 'Pin code generation error:'; de = 'Fehler bei der PIN-Code-Generierung:'; ru = 'Ошибка генерации пин-кода:'") + Chars.LF + vErrorMessage, True);
		vResult = False;
	EndIf;
	Return vResult;
EndFunction // VerifyAtServer

// -----------------------------------------------------------------------------
//
// Parameters:
//  rMessage - String	 - Message
// 
// Returns:
//  String - Result
//
&AtServer
Function GetHotelInfo(rMessage)
	vObj = FormAttributeToValue("Object");
	Return vObj.GetHotelInfo(rMessage);
EndFunction // NewKeyCardAtServer

#EndRegion
