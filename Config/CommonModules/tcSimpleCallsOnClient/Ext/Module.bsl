
#Region Public

// --------------------------------------------------------------------------------
// 
// Returns:
//  Number - Status
//
Function  GetState() Export
	Try
		vStatus = amSimpleCallsComponent.connectionState;
	Except
		vStatus = 0;
		ShowMessageBox(, Nstr("en = 'Failed to get status of components simply calls'; ru = 'Не удалось получить состояние компоненты Простые звонки'; de = 'Fehler beim Abrufen von Bauteilen ruft einfach'"));
	EndTry;
	
	Return vStatus;
EndFunction //  GetState

// --------------------------------------------------------------------------------
//
Procedure ConnectComponents() Export
	#If Not MobileClient Then
		Try
			amSimpleCallsComponent = New COMObject("CTIControlX.CTIControlX");
			
			AddHandler amSimpleCallsComponent.OnConnectionState,		OnChangeStatus;
			AddHandler amSimpleCallsComponent.OnTransferRequest,		OnTransferRequest ;
			AddHandler amSimpleCallsComponent.OnCompletedCall,			OnEndCall;
			AddHandler amSimpleCallsComponent.OnTransferredCall,		ProcessingIncomingCall;
			AddHandler amSimpleCallsComponent.OnOutcomingCall,			ProcessingOutgoingCall;
			AddHandler amSimpleCallsComponent.OnOutcomingCallAnswer,	OnOutcomingCallAnswer;
			AddHandler amSimpleCallsComponent.OnTransferredCallAnswer,  OnTransferredCallAnswer;
			
			SetParameters();
			
			If ValueIsFilled(amSimpleCallsParameters.UserPhoneNumber) Then
				Connect();	
			EndIf;
		Except
			ShowMessageBox(, Nstr("en = 'Failed to connect to server ""Simple calls""'; ru = 'Не удалось подключиться к серверу ""Простые звонки""'; de = 'Fehler beim Server zu verbinden ""Einfach telefonieren""'"));
			vMessage = ErrorDescription();
			
			tcOnServer.cmWriteLogEventAtServer(NStr("en='SimpleCalls.Connect'; de='SimpleCalls.Connect'; ru='ПростыеЗвонки.Подключение'"), , , , "Error description: " + vMessage);
			
			tcCommonFunctionOnClientServer.UserMessage(vMessage);
		EndTry;
	#EndIf
EndProcedure //  ConnectComponents

// --------------------------------------------------------------------------------
//
Procedure SetParameters() Export 
	amSimpleCallsParameters = tcSimpleCallsOnServer.GetParameters();
EndProcedure //  SetParameters

// --------------------------------------------------------------------------------
//
Procedure Connect()  Export
	#If Not WebClient Then   
		If amSimpleCallsParameters = Undefined Then
			ConnectComponents();
		Else	
			Try
				vServer		= amSimpleCallsParameters.ServerATC;
				vPass		= amSimpleCallsParameters.Password;
				vGuid		= tcSimpleCallsOnServer.GetIDCurrentWorkstation();
				
				vLog = TempFilesDir() + "SimpleCalls.log";      
				
				amSimpleCallsComponent.PhoneNumber = TrimAll(amSimpleCallsParameters.UserPhoneNumber);
				amSimpleCallsComponent.BroadcastGroup = amSimpleCallsParameters.GUID;
				amSimpleCallsComponent.Connect(vServer, vPass, "1C", vGuid, vLog, 0, 5000);
				SetParameters();
			Except
				ShowMessageBox(, Nstr("en = 'Failed to connect to server ""Simple calls""'; ru = 'Не удалось подключиться к серверу ""Простые звонки""'; de = 'Fehler beim Server zu verbinden ""Einfach telefonieren""'"));
				vMessage = ErrorDescription();
				
				tcOnServer.cmWriteLogEventAtServer(NStr("en='SimpleCalls.Connect'; de='SimpleCalls.Connect'; ru='ПростыеЗвонки.Подключение'"), , , , "Error description: " + vMessage);
				
				tcCommonFunctionOnClientServer.UserMessage(vMessage);
			EndTry;     
		EndIf;
	#EndIf	
EndProcedure //  Connect

// --------------------------------------------------------------------------------
// 
// Returns:
//  String - Version 
//
Function  GetActiveXVersion() Export
	Try
		vVersion = amSimpleCallsComponent.activeXVersion();
	Except
		vVersion = Undefined;
	EndTry;
	
	Return vVersion;
EndFunction //  GetActiveXVersion

// --------------------------------------------------------------------------------
// 
// Returns:
//  String - Version
//
Function  GetVersionModul() Export
	
	Return "1.1.0.0";
	
EndFunction //  GetVersionModul

// --------------------------------------------------------------------------------
//
// Parameters:
//  pPhoneNumber - String - Parameter
//
Procedure Call(pPhoneNumber) Export
	
	vUserPhoneNumber = amSimpleCallsParameters.UserPhoneNumber;
	
	Try
		amSimpleCallsComponent.Call(vUserPhoneNumber, ConvertPhoneNumber(pPhoneNumber));
	Except
	EndTry;
	
EndProcedure //  Call

// --------------------------------------------------------------------------------
//
Procedure Disconnect() Export
	
	Try
		amSimpleCallsComponent.Disconnect();
	Except
		ShowMessageBox(, Nstr("en = 'Failed to disconnect to server ""Simple calls""'; ru = 'Не удалось отключить компоненту ""Простые звонки""'; de = 'Fehler beim Verbinden mit Server "" Simple Anrufe "" trennen'"));
		
		vMessage = ErrorDescription();
		
		tcOnServer.cmWriteLogEventAtServer(NStr("en='SimpleCalls.Disconnect'; de='SimpleCalls.Disconnect'; ru='ПростыеЗвонки.Отключение'"), , , , "Error description: " + vMessage);
		
		tcCommonFunctionOnClientServer.UserMessage(vMessage);
	EndTry;
	
EndProcedure //  Disconnect

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
//
// Parameters:
//  pStatus	 - Number - Parameter 
//
Procedure OnChangeStatus(pStatus) Export
	
	Notify("SimpleCalls_ChageState", pStatus);
	
EndProcedure //  OnChangeStatus 

// --------------------------------------------------------------------------------
//
// Parameters:
//  pCallID	 - String - Parameter 
//  pFrom	 - String - Parameter
//
Procedure OnTransferRequest(callID, from, line) Export 	

EndProcedure //  OnTransferRequest

// --------------------------------------------------------------------------------
//
// Parameters:
//  callID		 - String - Parameter
//  src			 - String - Parameter 
//  dst			 - String - Parameter
//  duration	 - Number - Parameter 
//  start		 - String - Parameter
//  end			 - String - Parameter
//  direction	 - Number - Parameter
//  record		 - String - Parameter
//
Procedure OnEndCall(callID, src, dst, duration, start, end, direction, record, line) Export 
	
	If ((direction = 0 And TrimAll(dst) <> TrimAll(amSimpleCallsParameters.UserPhoneNumber)) 
		Or (direction = 1 And TrimAll(src) <> TrimAll(amSimpleCallsParameters.UserPhoneNumber))) Then
		Return;
	EndIf;	 
	
	vShowWindowIncomingCall	= amSimpleCallsParameters.ShowWindowIncomingCall;
	vShowWindowOutCall		= amSimpleCallsParameters.ShowWindowOutCall;
	vSaveHistoryCalls		= amSimpleCallsParameters.SaveHistoryCalls;
	
	If vShowWindowIncomingCall = Nstr("en = 'At the end of the conversation'; ru = 'По завершению разговора'; de = 'Am Ende des Gesprächs'") Then
		If direction = 0 Then
			ShowWindow_IncomingCall(src, dst, callID);
		EndIf;
	EndIf;
	
	If vShowWindowOutCall = Nstr("en = 'At the end of the conversation'; ru = 'По завершению разговора'; de = 'Am Ende des Gesprächs'") Then
		If direction = 1 Then
			ShowWindow_OutGoingCall(src, dst);
		EndIf;
	EndIf;
	
	vSaveHistory = False;
	
	If vSaveHistoryCalls = Nstr("en = 'Only incoming'; de = 'Nur eingehende'; ru = 'Только входящие'") Then
		If direction = 0 Then
			vSaveHistory = True;
		EndIf;
	ElsIf  vSaveHistoryCalls = Nstr("en = 'Only outgoing'; de = 'Nur ausgeh'; ru = 'Только исходящие'") Then
		If direction = 1 Then
			vSaveHistory = True;
		EndIf;
	ElsIf vSaveHistoryCalls = Nstr("en = 'Incoming and outgoing'; de = 'Eingehende und ausgehende'; ru = 'Входящие и исходящие'") Then
		vSaveHistory = True;
	EndIf;
	
	If vSaveHistory Then
		Try
			If start <> "" And end <> "" Then
				vDateFrom = Date(1970, 1, 1) + Number(start);
				vDateTo = Date(1970, 1, 1) + Number(end);
			EndIf;

			tcSimpleCallsOnServer.SaveHistoryCalls(src, dst, duration, vDateFrom, vDateTo, direction, record, callID);
		Except
			vMessage = ErrorDescription();
			tcOnServer.cmWriteLogEventAtServer(NStr("en='SimpleCalls.SaveCallHistory'; de='SimpleCalls.SaveCallHistory'; ru='SimpleCalls.SaveCallHistory'"), , , , "Error description: " + vMessage);
		EndTry;
	EndIf;
	
EndProcedure //  OnEndCall

// --------------------------------------------------------------------------------
//
// Parameters:
//  callID	 - String - Parameter
//  src		 - String - Parameter
//  dst		 - String - Parameter
//
Procedure ProcessingIncomingCall(callID, src, dst, line) Export 
	Try
		tcSimpleCallsOnServer.SaveCall(callID, src, dst);
	Except
		vMessage = ErrorDescription();
		tcOnServer.cmWriteLogEventAtServer(NStr("en='SimpleCalls.SaveCallHistory'; de='SimpleCalls.SaveCallHistory'; ru='SimpleCalls.SaveCallHistory'"), , , , "Error description: " + vMessage);
	EndTry;
	If TrimAll(dst) = TrimAll(amSimpleCallsParameters.UserPhoneNumber) Then
		vShowWindowIncomingCall	= amSimpleCallsParameters.ShowWindowIncomingCall;
		
		If Not ValueIsFilled(vShowWindowIncomingCall) Then
			vShowWindowIncomingCall = NStr("en = 'When a call'; ru = 'При поступлении звонка'; de = 'Wenn ein Anruf'");
		EndIf;
		
		If vShowWindowIncomingCall = NStr("en = 'When a call'; ru = 'При поступлении звонка'; de = 'Wenn ein Anruf'") Then
			ShowWindow_IncomingCall(src, dst, callID);
		EndIf;
	EndIf;	
EndProcedure //  ProcessingIncomingCall

// --------------------------------------------------------------------------------
//
// Parameters:
//  callID	 - String - Parameter
//  src		 - String - Parameter
//  dst		 - String - Parameter
//
Procedure ProcessingOutgoingCall(callID, src, dst) Export 
	If TrimAll(src) = TrimAll(amSimpleCallsParameters.UserPhoneNumber) Then
		If amSimpleCallsParameters.ShowWindowOutCall = Nstr("en = 'At the beginning of the call'; de = 'Zu Beginn des Anrufs'; ru = 'При начале звонка'") Then
			ShowWindow_OutGoingCall(src, dst);
		EndIf;
	EndIf;
EndProcedure //  ProcessingOutgoingCall

// --------------------------------------------------------------------------------
//
// Parameters:
//  callID	 - String - Parameter
//  src		 - String - Parameter
//  dst		 - String - Parameter
//
Procedure OnOutcomingCallAnswer(callID, src, dst) Export 
	If TrimAll(src) = TrimAll(amSimpleCallsParameters.UserPhoneNumber) Then
		vShowWindowOutCall	= amSimpleCallsParameters.ShowWindowOutCall;
		If vShowWindowOutCall = Nstr("en = 'By lifting the handset'; de = 'Durch Abheben des Hörers'; ru = 'По поднятию трубки'") Then
			ShowWindow_OutGoingCall(src, dst);
		EndIf;
	EndIf;
EndProcedure //  OnOutcomingCallAnswer

// --------------------------------------------------------------------------------
//
// Parameters:
//  callID	 - String - Parameter
//  src		 - String - Parameter
//  dst		 - String - Parameter
//
Procedure OnTransferredCallAnswer(callID, src, dst, line) Export 
	Try
		tcSimpleCallsOnServer.SaveCall(callID, src, dst, False);
	Except
		vMessage = ErrorDescription();
		tcOnServer.cmWriteLogEventAtServer(NStr("en='SimpleCalls.SaveCallHistory'; de='SimpleCalls.SaveCallHistory'; ru='SimpleCalls.SaveCallHistory'"), , , , "Error description: " + vMessage);
	EndTry;

	If TrimAll(dst) = TrimAll(amSimpleCallsParameters.UserPhoneNumber) Then
		vShowWindowIncomingCall	= amSimpleCallsParameters.ShowWindowIncomingCall;
		If vShowWindowIncomingCall = Nstr("en = 'By lifting the handset'; de = 'Durch Abheben des Hörers'; ru = 'По поднятию трубки'") Then
			ShowWindow_IncomingCall(src, dst, callID);
		EndIf;
	EndIf;
EndProcedure //  OnTransferredCallAnswer

// --------------------------------------------------------------------------------
Procedure ShowWindow_IncomingCall(pPhoneNumberFrom, pPhoneNumberOn, pID)
	vData = tcSimpleCallsOnServer.GetClientsByPhoneNumber(pPhoneNumberFrom);	
	
	vClient 		= vData.Client;
	vCustomer	 	= vData.Customer;
	vRoom 			= vData.Room;
	vWorkstation	= vData.Workstation;
	
	If vWorkstation <> Undefined Then
		Return;
	EndIf;
	
	vInputParam = New Structure();
	vInputParam.Insert("PhoneNumber", pPhoneNumberFrom);
	
	If ValueIsFilled(vClient)  Then
		vFrm = GetForm("CommonForm.tcSimpleCalls_IncomingCall", vInputParam, , New UUID());
		
		// Fill form parameters
		vFrm.Client  = vClient;
		vFrm.Remarks = tcOnServer.cmGetAttributeByRef(vClient, "Remarks");
		
		// Fill  latest checkin
		vLatestAcc = tcSimpleCallsOnServer.GetLatestCheckIn(vClient); 
		If Not vLatestAcc = Undefined Then 
			vGuestGroup  = vLatestAcc.GuestGroup;
			vGuestGroupTotals = tcSimpleCallsOnServer.GetGuestGroupTotals(vGuestGroup);
			
			vFrm.CheckOutGroup  		= vGuestGroup;
			vFrm.CheckOutDate   		= vLatestAcc.CheckOutDate;
			vFrm.CheckOutNumberOfRooms  = vGuestGroupTotals.TotalRooms;
			vFrm.CheckOutSum  			= vGuestGroupTotals.Sales;
		EndIf;
		
		// Fill  closest race
		vRes = tcSimpleCallsOnServer.GetReservation(vClient); 
		If Not vRes = Undefined Then 
			vGuestGroup    = vRes.GuestGroup; 
			vGuestGroupTotals = tcSimpleCallsOnServer.GetGuestGroupTotals(vGuestGroup);

			vFrm.CheckInGroup  			= vGuestGroup;
			vFrm.CheckInDate   			= vRes.CheckInDate;
			vFrm.CheckInNumberOfRooms   = vGuestGroupTotals.TotalRooms;
			vFrm.CheckInSum  			= vGuestGroupTotals.Sales;
		EndIf;
		
		// Visible
		vFrm.Items.GroupCustomer.Visible 	= False;

	ElsIf ValueIsFilled(vCustomer) Then 
		vFrm = GetForm("CommonForm.tcSimpleCalls_IncomingCall", vInputParam, , New UUID());
		
		// Fill form parameters
		vFrm.Customer  = vCustomer;
		
		// Fill  latest checkin
		vLatestAcc = tcSimpleCallsOnServer.GetLatestCheckIn(, vCustomer); 
		If Not vLatestAcc = Undefined Then 
			vGuestGroup  = vLatestAcc.GuestGroup;
			vGuestGroupTotals = tcSimpleCallsOnServer.GetGuestGroupTotals(vGuestGroup);
			
			vFrm.CheckOutGroup  		= vGuestGroup;
			vFrm.CheckOutDate   		= vLatestAcc.CheckOutDate;
			vFrm.CheckOutNumberOfRooms  = vGuestGroupTotals.TotalRooms;
			vFrm.CheckOutSum  			= vGuestGroupTotals.Sales;
		EndIf;
		
		// Fill  closest race
		vRes = tcSimpleCallsOnServer.GetReservation(, vCustomer); 
		If Not vRes = Undefined Then 
			vGuestGroup    = vRes.GuestGroup;
			vGuestGroupTotals = tcSimpleCallsOnServer.GetGuestGroupTotals(vGuestGroup);
			
			vFrm.CheckInGroup  			= vGuestGroup;
			vFrm.CheckInDate   			= vRes.CheckInDate;
			vFrm.CheckInNumberOfRooms  = vGuestGroupTotals.TotalRooms;
			vFrm.CheckInSum  			= vGuestGroupTotals.Sales;
		EndIf;
		
		// Fill  Invoice parameters
		vInvoice = tcSimpleCallsOnServer.GetInvoice(vCustomer);
		
		If Not vInvoice = Undefined Then 
			vFrm.Invoice = vInvoice.Document;
			vFrm.InvoiceSum = vInvoice.Sum;
			vFrm.InvoiceSumPaid = vInvoice.Sum - vInvoice.SumBalance;
			If vInvoice.SumBalance = 0 Then
				vFrm.Items.DecorationStatus.Picture = PictureLib.Paid;
			ElsIf vInvoice.Sum = vInvoice.SumBalance Then 
				vFrm.Items.DecorationStatus.Picture = PictureLib.Unpaid;
			Else	
				vFrm.Items.DecorationStatus.Picture = PictureLib.PartiallyPaid;
			EndIf;
		EndIf;
		
		// Visible
		vFrm.Items.GroupClient.Visible = False;
	ElsIf ValueIsFilled(vRoom) Then
		vInputParam.Insert("Room", vRoom);
		
		vFrm = GetForm("CommonForm.tcSimpleCalls_IncomingCall", vInputParam, , New UUID());
		
		// Fill form parameters  by room
		vCurAcc = tcSimpleCallsOnServer.GetMainAccomodationByRoom(vRoom); 
		
		If Not vCurAcc = Undefined Then 
			vCustomer	 = vCurAcc.Customer;
			vGuestGroup  = vCurAcc.GuestGroup;
			vGuestGroupTotals = tcSimpleCallsOnServer.GetGuestGroupTotals(vGuestGroup);
			
			vFrm.CheckOutGroup  		= vGuestGroup;
			vFrm.CheckOutDate   		= vCurAcc.CheckOutDate;
			vFrm.CheckOutNumberOfRooms  = vGuestGroupTotals.TotalRooms;
			vFrm.CheckOutSum  			= vGuestGroupTotals.Sales;
			vFrm.Customer  				= vCustomer;
			vFrm.Client  				= vCurAcc.Guest;
			
			If ValueIsFilled(vCustomer) Then
				
				// Fill  Invoice parameters
				vInvoice = tcSimpleCallsOnServer.GetInvoice(vCustomer);
				
				If Not vInvoice = Undefined Then 
					vFrm.Invoice = vInvoice.Document;
					vFrm.InvoiceSum = vInvoice.Sum;
					vFrm.InvoiceSumPaid = vInvoice.Sum - vInvoice.SumBalance;
					
					If vInvoice.SumBalance = 0 Then
						vFrm.Items.DecorationStatus.Picture = PictureLib.Paid;
					ElsIf vInvoice.Sum = vInvoice.SumBalance Then 
						vFrm.Items.DecorationStatus.Picture = PictureLib.Unpaid;
					Else	
						vFrm.Items.DecorationStatus.Picture = PictureLib.PartiallyPaid;
					EndIf;
					
				EndIf;
			EndIf;
		EndIf;
	Else
		OpenForm("CommonForm.tcSimpleCalls_NewClient", vInputParam);
	EndIf;
	If Not vFrm = Undefined Then
		vFrm.Title = NStr("en = 'Incoming call'; ru = 'Входящий звонок'; de = 'Eingehenden Anruf'") + ":" + pPhoneNumberFrom;
		vFrm.IDCall = pID;
		vFrm.DoModal();
	EndIf;
EndProcedure //  ShowWindow_IncomingCall

// --------------------------------------------------------------------------------
Procedure ShowWindow_OutGoingCall(pPhoneNumberFrom, pPhoneNumberTo)
		
EndProcedure //  ShowWindow_OutGoingCall

// --------------------------------------------------------------------------------
Function  ConvertPhoneNumber(pPhoneNumber)
	vOnlyNumber = "";
	For  а = 1 To StrLen(pPhoneNumber) Do
		If StrOccurrenceCount("1234567890", Mid(pPhoneNumber, а, 1)) > 0 Then
			vOnlyNumber = vOnlyNumber + Mid(pPhoneNumber, а, 1);
		EndIf;
	EndDo;
	
	Return vOnlyNumber;
EndFunction //  ConvertPhoneNumber

#EndRegion
