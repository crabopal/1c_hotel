#Region Variables

// -----------------------------------------------------------------------------
&AtClient
Var Display;

#EndRegion

#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("SelPayment") Then
		SelDocument = Parameters.SelPayment
	EndIf;
	
	If Not ValueIsFilled(SelDocument) Then
		pCancel = True;
		Return;
	EndIf;
	
	If Parameters.Property("SelExternalSystem") Then
		SelExternalSystem = Parameters.SelExternalSystem;
	EndIf;
	
	If Not ValueIsFilled(Parameters.SelExternalSystem) Then
		pCancel = True;
		Return;
	EndIf;
	
	If TypeOf(SelDocument) = Type("DocumentRef.Payment") Then
		IsPayment = True;
		vWorkstation = SessionParameters.CurrentWorkstation;
		If ValueIsFilled(vWorkstation) Then
			If vWorkstation.HasConnectionToCustomerDisplayParameters And ValueIsFilled(vWorkstation.CustomerDisplayParameters) Then
				SelCustomerDisplayParameters = vWorkstation.CustomerDisplayParameters; 	
			EndIf;
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	Items.Status.Title = NStr("en = 'Checking order status'; de = 'Bestellstatus prüfen'; ru = 'Проверка статуса заказа'");
	
	If ValueIsFilled(SelCustomerDisplayParameters) Then
		ShowQRCode();
	EndIf;
	
	AttachIdleHandler("CheckStatusOrder", 0.2, True);
EndProcedure // OnOpen

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeClose(pCancel, pExit, pMessageText, pStandardProcessing)
	If ValueIsFilled(SelCustomerDisplayParameters) Then
		ClearQRCode();
	EndIf;
EndProcedure // BeforeClose

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Async Procedure CheckStatusOrder() Export
	vStatus = "";
	vIsCompleted = False;
	vMessage = "";
	
	If Not CheckStatusOrderAtServer(vStatus, vIsCompleted, IsPayment, vMessage) Then
		Await DoMessageBoxAsync(vMessage, , NStr("en = 'Error'; de = 'Error'; ru = 'Error'"));
		Close(False);
		Return;
	EndIf;
	
	Items.Status.Title = vStatus;
	If vIsCompleted Then
		Close(True);
		Return;
	EndIf;
	
	AttachIdleHandler("CheckStatusOrder", 5, True);
EndProcedure // CheckStatusOrder

// -----------------------------------------------------------------------------
&AtServer
Function CheckStatusOrderAtServer(rStatus, rIsCompleted, pIsPayment, rMessage)
	vDP = SelExternalSystem.DataProcessor;
	
	If Not ValueIsFilled(vDP) Then
		rMessage = Nstr("en = 'Interaction has no service handling specified'; de = 'Für die Interaktion ist keine Servicebehandlung angegeben'; ru = 'У взаимодействия не указана обработка обслуживания'");
		pCancel = False;
		Return False;
	EndIf;
	
	vDPO = Catalogs.DataProcessors.CreateDataProcessorByProcessing(vDP, True);
	
	If vDPO = Undefined Then
		rMessage = Nstr("en = 'Failed to initialize processing'; de = 'Fehler beim Initialisieren der Verarbeitung'; ru = 'Не удалось инициализировать обработку'");
		pCancel = False;
		Return False;
	EndIf;
		
	Return vDPO.GetStatusExternalPayment(SelDocument, rIsCompleted, pIsPayment, rStatus, rMessage);
EndFunction // CheckStatusOrderAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowQRCode()
	vMessage = "";
	If Display = Undefined Then
		Display = tcOnClient.cmGetModulTO(SelCustomerDisplayParameters);
	EndIf;
	
	If Display = Undefined Then
		tcCommonFunctionOnClientServer.TextMessage(Nstr("en = 'Work with driver this device is not supported'; 
														|de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird'; 
														|ru = 'Работа с драйвером этого устройства не поддерживается'"));
		Return;
	EndIf;
	
	vParams = New Structure("QRCode, Header, Footer", "", "", "");
	vParams.QRCode = tcOnServer.cmGetAttributeByRef(SelDocument, "OrderURL");
	vParentDoc = tcOnServer.cmGetAttributeByRef(SelDocument, "ParentDoc");
	If ValueIsFilled(vParentDoc) Then
		If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Then
			vRoom = tcOnServer.cmGetAttributeByRef(vParentDoc, "Room");
			If ValueIsFilled(vRoom) Then
				vParams.Header = "Room " + TrimAll(vRoom);
			EndIf;
		EndIf;
	EndIf;
	vParams.Footer = Format(tcOnServer.cmGetAttributeByRef(SelDocument, "Sum"), "NFD=2; NZ=0; NG=0");
	
	If Not Display.pmShowQRCode(SelCustomerDisplayParameters, vParams, vMessage) Then
		tcCommonFunctionOnClientServer.TextMessage(vMessage);
	EndIf;
EndProcedure // ShowQRCode

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearQRCode()
	vMessage = "";
	If Display = Undefined Then
		vDisplay = tcOnClient.cmGetModulTO(SelCustomerDisplayParameters);
	EndIf;
	
	If Display = Undefined Then
		Return;
	EndIf;
	
	Display.pmClearQRCode(SelCustomerDisplayParameters, vMessage);
EndProcedure // ShowQRCode

#EndRegion