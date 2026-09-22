
#Region Variables

&AtClient
Var TCPIP;

&AtClient
Var KeyNumber;

#EndRegion

#Region FormEventHandlers

// ---------------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Load DP parameters
	Obj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If Parameters.Property("DataProcessor", vDataProcessor) Then
		Obj.DataProcessor = vDataProcessor;
	EndIf;
	vInteractionParameters = Catalogs.ExternalSystemInteractions.EmptyRef();
	If Parameters.Property("InteractionParameters", vInteractionParameters) Then
		Obj.ExternalInteraction = vInteractionParameters;
	EndIf;
	Obj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(Obj,"Object");
			
	If Parameters.Property("ParametersKeyCard") And TypeOf(Parameters.ParametersKeyCard) = Type("Structure") Then
		FillPropertyValues(Object, Parameters.ParametersKeyCard);
	EndIf; 
	
	If ValueIsFilled(Object.DoorLockSystemParameters) Then
		Try  
			vParams = Object.DoorLockSystemParameters.DoorLockSystemConnectionParameters.Get();
			vParams.Property("AssignedAuthorizations", AssignedAuthorizations);
			vParams.Property("EncoderNumber", EncoderNumber);
			vParams.Property("Port", Port);
			vParams.Property("ServerName", ServerName);
			vParams.Property("AddMinutes", AddMinutes);
			vParams.Property("SubtractMinutes", SubtractMinutes);
			vParams.Property("AllowDynamicAuthorizations", AllowDynamicAuthorizations);
			vParams.Property("UseRoomLockCodes", UseRoomLockCodes);
			vParams.Property("DefaultRoom", DefaultRoom);	
		Except
			AssignedAuthorizations = Object.DoorLockSystemParameters.AssignedAuthorizations;
			EncoderNumber = Object.DoorLockSystemParameters.EncoderNumber;
			Port = Object.DoorLockSystemParameters.Port;
			ServerName = Object.DoorLockSystemParameters.ServerName;
			AddMinutes = Object.DoorLockSystemParameters.AddMinutes;
			SubtractMinutes = Object.DoorLockSystemParameters.SubtractMinutes;
			AllowDynamicAuthorizations = Object.DoorLockSystemParameters.AllowDynamicAuthorizations;
			UseRoomLockCodes = Object.DoorLockSystemParameters.UseRoomLockCodes;
			DefaultRoom = Object.DoorLockSystemParameters.DefaultRoom;
		EndTry;
	Else
		ShowStatusMessage(NStr("en = 'The parameters for working with the locking system are not specified'; de = 'Die Parameter für das Arbeiten mit der Schließanlage sind nicht vorgegeben'; ru = 'Не указаны параметры работы с замковой системой'"));
		ReadOnly = True;
		Return;
	EndIf;
	
	// Set availability of the door lock system authorizations
	Items.DoorLockSystemAuthorization.Enabled = False;
	Items.DoorLockSystemAuthorization.Visible = False;
	If SessionParameters.CurrentWorkstation.DoorLockSystemParameters.AllowDynamicAuthorizations Then
		If cmCheckUserPermissions("HavePermissionToSetDoorLockSystemAuthorizations") Then
			Items.DoorLockSystemAuthorization.Visible = True;
			Items.DoorLockSystemAuthorization.Enabled = True;
		EndIf;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToChangeCheckOutDateInDoorLockSystem") Then
		Items.CheckOutDate.ReadOnly = True;
	Else
		Items.CheckOutDate.ReadOnly = False;
	EndIf;
	
	ShowStatusMessage(NStr("en='Choose action';ru='Выберите действие';de='Wählen Sie die Aktion'"));
EndProcedure // OnCreateAtServer

// ---------------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	// Create client ActiveX object
	#If Not MobileClient Then
		Try
		    TCPIP = New COMObject("SocketTools.SocketWrench.10");
			// Load license
			vErrorCode = TCPIP.Initialize(GetLicenseKey(True));
		Except 
			Try
				TCPIP = New COMObject("SocketTools.SocketWrench.6");
				// Load license
				vErrorCode = TCPIP.Initialize(GetLicenseKey());		
			Except
				vErrorInfo = ErrorInfo();
				ShowStatusMessage(BriefErrorDescription(vErrorInfo), True);
				ReadOnly = True;
				Return;
			EndTry;	
		EndTry;
		If vErrorCode <> 0 Then
			ShowStatusMessage(NStr("en = 'Licensing error: '; de = 'Lizenzierungsfehler: '; ru = 'Ошибка лицензирования: '") + vErrorCode, True);
			ReadOnly = True;
			Return;
		EndIf;
	#EndIf
EndProcedure // OnOpen

// ---------------------------------------------------------------------------------------
&AtClient
Procedure BeforeClose(pCancel, pExit, pMessageText, pStandardProcessing)
	Disconnect(); 
	TCPIP = Undefined;
EndProcedure // BeforeClose

#EndRegion

#Region FormCommandsEventHandlers

// ---------------------------------------------------------------------------------------
&AtClient
Procedure NewKey(pCommand, pIsAdd = False)
	KeyNumber = 1;
	
	vDatazoneDocument = New Map;
	
	OperationCode = "CI";      
	vDatazoneDocument.Insert("OC", OperationCode);
	vDatazoneDocument.Insert("CS", EncoderNumber);
	If pIsAdd Then
		IsNewKey = False;
		vDatazoneDocument.Insert("CA", "2");
	Else  
		IsNewKey = True;
		vDatazoneDocument.Insert("CA", "1");	
	EndIf;  
	
	vCheckOutDate = Object.CheckOutDate;
	If AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + AddMinutes * 60;
	EndIf;
	
	vDatazoneDocument.Insert("DEP", Format(vCheckOutDate, "DF=yyyy-MM-ddTHH:mm:ss"));
	
	vRoomCode = TrimAll(Object.Room);
	If ValueIsFilled(Object.Room) Then
		If UseRoomLockCodes Then
			vLockCode = tcOnServer.cmGetAttributeByRef(Object.Room, "LockCode");
			If ValueIsFilled(vLockCode) Then
				vRoomCode = TrimAll(vLockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) And ValueIsFilled(DefaultRoom) Then
		Object.Room = DefaultRoom;
		vRoomCode = TrimAll(Object.Room);
		If UseRoomLockCodes Then
			vLockCode = tcOnServer.cmGetAttributeByRef(Object.Room, "LockCode");
			If ValueIsFilled(vLockCode) Then
				vRoomCode = TrimAll(vLockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(vRoomCode) Then
		ShowStatusMessage(NStr("en = 'Room has no key card door lock!'; de = 'Im Zimmer ist kein elektronisches Schloss vorhanden!'; ru = 'В номере нет электронного замка!'"), True);
		Return;
	EndIf;
	
	vDatazoneDocument.Insert("RN", vRoomCode); 
	
	// Authorizations
	vCommonDoorsBitMap = "";
	vDoorLockSystemAuthorization = Object.DoorLockSystemAuthorization;
	If Not ValueIsFilled(vDoorLockSystemAuthorization) And ValueIsFilled(Object.Room) Then
		vDoorLockSystemAuthorization = tcOnServer.cmGetAttributeByRef(Object.Room, "DoorLockSystemAuthorization");
	EndIf;
	If ValueIsFilled(vDoorLockSystemAuthorization) Then
		vAssignedAuthorizations = tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "AssignedAuthorizations"); 
		If ValueIsFilled(vAssignedAuthorizations) Then
			vMergeWithDefault = tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "MergeWithDefault"); 
			If vMergeWithDefault Then  
				For vNumber = 1 To 16 Do
					vBit1 = "0";
					vBit2 = "0";
					If StrLen(vAssignedAuthorizations) >= vNumber Then
						vBit1 = Mid(vAssignedAuthorizations, vNumber, 1); 		
					EndIf;
					If StrLen(AssignedAuthorizations) >= vNumber Then
						vBit2 = Mid(AssignedAuthorizations, vNumber, 1); 		
					EndIf;
					If vBit1 = "1" Or vBit2 = "1" Then
						vCommonDoorsBitMap = vCommonDoorsBitMap + "1";	
					Else
						vCommonDoorsBitMap = vCommonDoorsBitMap + "0";	
					EndIf;
				EndDo;
			Else
				vCommonDoorsBitMap = TrimAll(vAssignedAuthorizations);
			EndIf;
		Else
			vCommonDoorsBitMap = TrimAll(AssignedAuthorizations);	
		EndIf;
	Else
		vCommonDoorsBitMap = TrimAll(AssignedAuthorizations);
	EndIf;
	
	While StrLen(vCommonDoorsBitMap) < 16 Do
		vCommonDoorsBitMap = vCommonDoorsBitMap + "0";	
	EndDo;
	
	vDatazoneDocument.Insert("AP", Left(vCommonDoorsBitMap, 16));
	vDatazoneDocument.Insert("NC", Object.NumberOfKeys);
	vDatazoneDocument.Insert("GID", Format(Number(tcOnServer.GetDocumentNumberPresentation(tcOnServer.cmGetAttributeByRef(Object.Guest, "Code"))), "ND=16; NFD=0; NLZ=; NG="));
	vDatazoneDocument.Insert("ORG", TrimAll(tcOnServer.cmGetSessionParametersAttribute("CurrentWorkstation")));
	
	vDataStr = New Map;
	vDataStr.Insert("datazone-document", vDatazoneDocument);
	
	TCPSend(vDataStr);
EndProcedure // NewKey          

// ---------------------------------------------------------------------------------------
&AtClient
Procedure AddKey(pCommand)
	NewKey(Commands["NewKey"], True);	
EndProcedure // AddKey

// ---------------------------------------------------------------------------------------
&AtClient
Procedure Verify(pCommand)
	vDatazoneDocument = New Map;
	
	OperationCode = "RC";
	vDatazoneDocument.Insert("OC", OperationCode);
	vDatazoneDocument.Insert("CS", EncoderNumber);
	vDatazoneDocument.Insert("ORG", TrimAll(tcOnServer.cmGetSessionParametersAttribute("CurrentWorkstation")));
	
	vDataStr = New Map;
	vDataStr.Insert("datazone-document", vDatazoneDocument);
	
	TCPSend(vDataStr);		
EndProcedure // Verify

// ---------------------------------------------------------------------------------------
&AtClient
Procedure DelKey(pCommand)
	vDatazoneDocument = New Map;
	
	OperationCode = "CO";      
	vDatazoneDocument.Insert("OC", OperationCode);
	vDatazoneDocument.Insert("CA", "0");
	
	vRoomCode = TrimAll(Object.Room);
	If ValueIsFilled(Object.Room) Then
		If UseRoomLockCodes Then
			vLockCode = tcOnServer.cmGetAttributeByRef(Object.Room, "LockCode");
			If ValueIsFilled(vLockCode) Then
				vRoomCode = TrimAll(vLockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) And ValueIsFilled(DefaultRoom) Then
		Object.Room = DefaultRoom;
		vRoomCode = TrimAll(Object.Room);
		If UseRoomLockCodes Then
			vLockCode = tcOnServer.cmGetAttributeByRef(Object.Room, "LockCode");
			If ValueIsFilled(vLockCode) Then
				vRoomCode = TrimAll(vLockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(vRoomCode) Then
		ShowStatusMessage(NStr("en = 'Room has no key card door lock!'; de = 'Im Zimmer ist kein elektronisches Schloss vorhanden!'; ru = 'В номере нет электронного замка!'"), True);
		Return;
	EndIf;
	
	vDatazoneDocument.Insert("RN", vRoomCode);
	vDatazoneDocument.Insert("ORG", TrimAll(tcOnServer.cmGetSessionParametersAttribute("CurrentWorkstation")));
	
	vDataStr = New Map;
	vDataStr.Insert("datazone-document", vDatazoneDocument);
	
	TCPSend(vDataStr);	
EndProcedure // DelKey

#EndRegion

#Region Private

// ---------------------------------------------------------------------------------------
&AtClient
Procedure AddError(pErrorText)
	tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.Error';ru='СистемаЭлектронныхЗамков.Ошибка';de='DoorLockSystem.Error'"), "Warning", , , GetDataPresentation(pErrorText)); 
EndProcedure // AddError

// ---------------------------------------------------------------------------------------
&AtClient
Function GetDataPresentation(Val pStr)
	pStr = StrReplace(pStr, Char(0), "<NUL>");
	pStr = StrReplace(pStr, Char(1), "<SOH>");
	pStr = StrReplace(pStr, Char(2), "<STX>");
	pStr = StrReplace(pStr, Char(3), "<ETX>");
	pStr = StrReplace(pStr, Char(4), "<EOT>");
	pStr = StrReplace(pStr, Char(5), "<ENQ>");
	pStr = StrReplace(pStr, Char(6), "<ACK>");
	pStr = StrReplace(pStr, Char(7), "<BEL>");
	pStr = StrReplace(pStr, Char(8), "<BS>");
	pStr = StrReplace(pStr, Char(9), "<TAB>");
	pStr = StrReplace(pStr, Char(10), "<LF>");
	pStr = StrReplace(pStr, Char(11), "<VT>");
	pStr = StrReplace(pStr, Char(12), "<FF>");
	pStr = StrReplace(pStr, Char(13), "<CR>");
	pStr = StrReplace(pStr, Char(14), "<SO>");
	pStr = StrReplace(pStr, Char(15), "<SI>");
	pStr = StrReplace(pStr, Char(16), "<DLE>");
	pStr = StrReplace(pStr, Char(17), "<DC1>");
	pStr = StrReplace(pStr, Char(18), "<DC2>");
	pStr = StrReplace(pStr, Char(19), "<DC3>");
	pStr = StrReplace(pStr, Char(20), "<DC4>");
	pStr = StrReplace(pStr, Char(21), "<NAK>");
	pStr = StrReplace(pStr, Char(22), "<SYN>");
	pStr = StrReplace(pStr, Char(23), "<ETB>");
	pStr = StrReplace(pStr, Char(24), "<CAN>");
	pStr = StrReplace(pStr, Char(25), "<EM>");
	pStr = StrReplace(pStr, Char(26), "<SUB>");
	pStr = StrReplace(pStr, Char(27), "<ESC>");
	pStr = StrReplace(pStr, Char(28), "<FS>");
	pStr = StrReplace(pStr, Char(29), "<GS>");
	pStr = StrReplace(pStr, Char(30), "<RS>");
	pStr = StrReplace(pStr, Char(31), "<US>");
	pStr = StrReplace(pStr, Char(127), "<Delete>");
	Return pStr;
EndFunction // GetDataPresentation

// ---------------------------------------------------------------------------------------
&AtServer
Function GetLicenseKey(pIsCSWSOCK10 = False)
	If pIsCSWSOCK10 Then
		Return cmGetCSWSOCK10LicenseKey();	
	Else
		Return cmGetCSWSOCK6LicenseKey();	
	EndIf;
EndFunction // GetLicenseKey

// ---------------------------------------------------------------------------------------
&AtServer
Procedure ShowStatusMessage(pMsg = "", pAttention = False)
	HelpMessage = pMsg;
	If pAttention Then
		Items.HelpMessage.TextColor = WebColors.Red;
	Else
		Items.HelpMessage.TextColor = WebColors.Black;
	EndIf;
EndProcedure // ShowStatusMessage

// ---------------------------------------------------------------------------------------
&AtServer
Function GetStructureByXMLString(Val pXMLString)
	vResult = New Map;
	Try
		If ValueIsFilled(pXMLString) Then
			vResult = Catalogs.DataConvertationRules.XMLtoMap(pXMLString);
		EndIf;
	Except
		vResult = Undefined;
	EndTry;
	Return vResult;
EndFunction // GetStructureByXMLString

// ---------------------------------------------------------------------------------------
&AtClient
Function GetXMLStringByStructure(Val pStructure)
	vResponseXML = "";
	Try
 		xmlResponse = New XMLWriter;
		vXMLWriterSettings = New XMLWriterSettings("UTF-8", "1.0", False, False);
		xmlResponse.SetString(vXMLWriterSettings);
		xmlResponse.WriteXMLDeclaration();
		WriterMaptoXML(xmlResponse, pStructure);
		vResponseXML = xmlResponse.Close();
	Except
		vResponseXML = "";
	EndTry;
	Return vResponseXML;
EndFunction // GetXMLStringByStructure

// --------------------------------------------------------------------------------------- 
&AtClient
Procedure WriterMapToXML(pxmlResponse, pStructure)
	For Each vItem In pStructure Do
		If TypeOf(vItem.Value) = Type("Structure") Or TypeOf(vItem.Value) = Type("Map") Then
			pxmlResponse.WriteStartElement(vItem.Key);
			WriterMaptoXML(pxmlResponse, vItem.Value);
			pxmlResponse.WriteEndElement();
		ElsIf TypeOf(vItem.Value) = Type("Array") Then 
			If vItem.Value.Count() > 0 Then
				For Each vRow In vItem.Value Do
					pxmlResponse.WriteStartElement(vItem.Key);
					WriterMaptoXML(pxmlResponse, vRow);
					pxmlResponse.WriteEndElement();
				EndDo;
			EndIf;
		Else
			pxmlResponse.WriteStartElement(vItem.Key);
			pxmlResponse.WriteText(TrimAll(vItem.Value));
			pxmlResponse.WriteEndElement();
		EndIf;
	EndDo;	
EndProcedure // WriterMaptoXML

// ---------------------------------------------------------------------------------------
&AtClient
Function Connect() 
	Try 
		TCPIP.Blocking = True;
		TCPIP.Timeout = 3;
		vErrorCode = TCPIP.Connect(TrimAll(ServerName), Number(TrimAll(Port)));
		If vErrorCode <> 0 Then
			AddError(NStr("ru = 'Не найден сервер системы электронных замков HÄFELE: '; en = 'HÄFELE system server was not found: '; de = 'HÄFELE system server was not found: '") + vErrorCode);
			Return False;
		EndIf;	
	Except
		AddError(NStr("ru = 'Ошибка подключения системы электронных замков HÄFELE: '; 
					  |en = 'HÄFELE door lock system connection error: ';
					  |de = 'HÄFELE door lock system connection error: '") + ErrorDescription());  
		Return False;
	EndTry;
	Return True;
EndFunction // Connect

// ---------------------------------------------------------------------------------------
&AtClient
Procedure Disconnect()
	If TCPIP <> Undefined Then
		If TCPIP.Connected Then
			If TCPIP.Disconnect() <> 0 THEN
				pMessageText = TCPIP.LastErrorString;	
			EndIf;
		EndIf;
	EndIf;	
EndProcedure // Disconnect

// ---------------------------------------------------------------------------------------
&AtServerNoContext
Function GetTransactionNumber(Val pExternalInteraction)
	vTransactionNumber = "1";
	
	vTransactionNumberArr = InformationRegisters.ExternalSystemIntegrationData.GetData(pExternalInteraction, "String", "TransactionNumber");
	If vTransactionNumberArr.Count() > 0  Then
		vTransactionNumber = Format(Number(vTransactionNumberArr[0].RefKey1) + 1, "NFD=0; NZ=0; NG="); 
		InformationRegisters.ExternalSystemIntegrationData.UpdateDataByExternalSystemAndDataType(pExternalInteraction, "String", "TransactionNumber", , vTransactionNumber);	
	Else
		InformationRegisters.ExternalSystemIntegrationData.WriteData(pExternalInteraction, "String", "TransactionNumber", vTransactionNumber, Undefined, Undefined);	
	EndIf;
	
	Return vTransactionNumber;   
EndFunction // GetTransactionNumber

// ---------------------------------------------------------------------------------------
&AtClient
Procedure TCPSend(pDatazoneDocument) 		
	If Not Connect() Then
		ShowStatusMessage(NStr("ru = 'Не удалось установить соединение с системой HÄFELE!'; 
		            		   |de = 'Failed to connect to the door locks system HÄFELE!';       
		            		   |en = 'Failed to connect to the door locks system HÄFELE!'", True));
		Return;	
	EndIf;
	
	pDatazoneDocument["datazone-document"].Insert("TN", GetTransactionNumber(Object.ExternalInteraction));
	
	vDataXML = GetXMLStringByStructure(pDatazoneDocument); 
	
	TCPIP.Flush();
	If TCPIP.Write(vDataXML, StrLen(vDataXML)) = -1 Then
		AddError(NStr("en='Write command error: ';ru='Ошибка отправки команды: ';de='Fehler beim Versenden des Befehls: '") + TCPIP.LastError + " - " + TCPIP.LastErrorString);
		ShowStatusMessage(NStr("en='Write command error: ';ru='Ошибка отправки команды: ';de='Fehler beim Versenden des Befehls: '") + TCPIP.LastError + " - " + TCPIP.LastErrorString, True);
		Disconnect();
		Return;
	EndIf; 
	
	Attachable_TCPRead();
EndProcedure // TCPSEND

// --------------------------------------------------------------------------------------- 
&AtClient
Function ReadString()
	vReply = ""; 
	vChar = "";
	While TCPIP.Read(vChar, 1) > 0 Do
		If vChar = Char(4) Then
			Break;	
		EndIf;
		vReply = vReply + vChar;
	EndDo;
	Return vReply;
EndFunction // ReadString

// ---------------------------------------------------------------------------------------
&AtClient
Procedure Attachable_TCPRead() Export
	vDataXML = ReadString();
	
	If ValueIsFilled(vDataXML) Then
		vDataStr = GetStructureByXMLString(vDataXML);	
		If vDataStr = Undefined Or vDataStr["datazone-document"] = Undefined Or vDataStr["datazone-document"]["OC"] = Undefined Or Not ValueIsFilled(vDataStr["datazone-document"]["OC"]["__TextValue"]) Then
			AddError(NStr("en='Error reading response: ';ru='Ошибка чтения ответа: ';de='Fehler beim Lesen der Antwort: '") + vDataXML);
			ShowStatusMessage(NStr("en='Error reading response';ru='Ошибка чтения ответа';de='Fehler beim Lesen der Antwort'"), True);
			Return;	
		EndIf; 
		
		vDatazoneDocument = vDataStr["datazone-document"];  
		
		If vDatazoneDocument["OC"] <> Undefined And vDatazoneDocument["OC"]["__TextValue"] = "SM" Then  
			If vDatazoneDocument["MSG"] = Undefined Or vDatazoneDocument["MSG"]["__TextValue"] = "" Then 
				If OperationCode <> "RC" Then
					ShowStatusMessage("");	
				EndIf;
				Return;
			Else
				ShowStatusMessage(vDatazoneDocument["MSG"]["__TextValue"]);
				If Not ValueIsFilled(vDatazoneDocument["MSG"]["__TextValue"]) Then
					Return;	
				EndIf;
			EndIf;
		ElsIf vDatazoneDocument["OC"] <> Undefined And vDatazoneDocument["OC"]["__TextValue"] = "ACK" Then
			If vDatazoneDocument["RC"] <> Undefined And vDatazoneDocument["RC"]["__TextValue"] = "0" Then   
				ShowStatusMessage(?(vDatazoneDocument["MSG"] <> Undefined, vDatazoneDocument["MSG"]["__TextValue"], ""));
				DataProcessingByOperationCode(OperationCode, vDatazoneDocument);	
			Else
				ShowStatusMessage(NStr("en = 'Error: '; de = 'Fehler: '; ru = 'Ошибка: '") +  ?(vDatazoneDocument["RC"] <> Undefined, vDatazoneDocument["RC"]["__TextValue"], "") + " - " + ?(vDatazoneDocument["MSG"] <> Undefined, vDatazoneDocument["MSG"]["__TextValue"], ""), True);
			EndIf;
		Else
			Return;		
		EndIf;
	EndIf;
	
	If OperationCode = "CI" Or OperationCode = "RC" Or Not ValueIsFilled(vDataXML) Then
		AttachIdleHandler("Attachable_TCPRead", 1.5, True);	
	EndIf;
EndProcedure // OnRead

// ---------------------------------------------------------------------------------------
&AtClient
Procedure DataProcessingByOperationCode(Val pOperationCode, Val pDatazoneDocument)
	If pOperationCode = "CI" Then
		vIdentificationCard = PredefinedValue("Catalog.IdentificationCards.EmptyRef");
		If ReturnCardUID AND ValueIsFilled(Object.Folio) Then
			If pDatazoneDocument["KC"] <> Undefined And ValueIsFilled(pDatazoneDocument["KC"]["__TextValue"]) Then
				vIdentificationCard = tcOnServer.GetClientIdentificationCard(pDatazoneDocument["KC"]["__TextValue"], tcOnServer.GetClientIdentificationCardById(pDatazoneDocument["KC"]["__TextValue"]), Object.ParentDoc, Object.Folio, Object.Guest, Object.Room, Object.CheckInDate, Object.CheckOutDate, True, pDatazoneDocument["KC"]["__TextValue"]);
 			EndIf;
		EndIf;
		tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.KeyIssued';ru='СистемаЭлектронныхЗамков.ВыданКлюч';de='DoorLockSystem.KeyIssued'"), "Information", , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(Object.Room) + ", " + Format(Object.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(Object.CheckOutDate, "DF='dd.MM.yyyy HH:mm'"));
		If IsNewKey And KeyNumber = 1 Then
			tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("NEW", ?(ValueIsFilled(vIdentificationCard), TrimAll(tcOnServer.cmGetAttributeByRef(vIdentificationCard, "CardUID")), ""), Object.Room, "", CurrentDate(), ?(AddMinutes <> 0, Object.CheckOutDate + AddMinutes * 60, Object.CheckOutDate), Object.ParentDoc, Object.Guest, Object.NumberOfKeys);						
		Else
			tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("ADD", ?(ValueIsFilled(vIdentificationCard), TrimAll(tcOnServer.cmGetAttributeByRef(vIdentificationCard, "CardUID")), ""), Object.Room, "", CurrentDate(), ?(AddMinutes <> 0, Object.CheckOutDate + AddMinutes * 60, Object.CheckOutDate), Object.ParentDoc, Object.Guest, Object.NumberOfKeys);	
		EndIf; 
		KeyNumber = KeyNumber + 1;
	ElsIf pOperationCode = "CO" Then
		tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("CANCEL", "", Object.Room, "", CurrentDate(), ?(AddMinutes <> 0, Object.CheckOutDate + AddMinutes * 60, Object.CheckOutDate), Object.ParentDoc, Object.Guest, Object.NumberOfKeys);		
	ElsIf pOperationCode = "RC" Then
		OpenForm("DataProcessor.HAFELELockDoorLockSystemDriver.Form.ReadCardForm", New Structure("Room, CheckOutDate, Guest, UUIDCard", ?(pDatazoneDocument["RN"] <> Undefined, pDatazoneDocument["RN"]["__TextValue"], ""), ?(pDatazoneDocument["DEP"] <> Undefined, pDatazoneDocument["DEP"]["__TextValue"], ""), ?(pDatazoneDocument["GID"] <> Undefined, pDatazoneDocument["GID"]["__TextValue"], ""), ?(pDatazoneDocument["KC"] <> Undefined, pDatazoneDocument["KC"]["__TextValue"], "")), ThisObject, UUID, , , , FormWindowOpeningMode.LockOwnerWindow);		
	EndIf;
EndProcedure // DataProcessingByOperationCode

#EndRegion
