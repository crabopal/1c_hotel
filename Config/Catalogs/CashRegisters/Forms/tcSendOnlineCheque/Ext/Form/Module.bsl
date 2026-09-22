
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	vPayer = Parameters.Payment.Payer;
	If ValueIsFilled(vPayer) Then
		Phone = TrimAll(vPayer.Phone);
		ClientEMail = TrimAll(vPayer.EMail);
	EndIf;
	SetFormAppearance();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure TypeOnChange(pItem)
	SetFormAppearance();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure PhoneOnChange(pItem)
	PhoneOnChangeAtServer();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure Send(pCommand)
	vAddress = FillAddress();
	If IsBlankString(vAddress) Then  
		vErr = NStr("en='Phone is not specified!'; ru='Не указан телефон!'; de='Unbekannt Telefon!'");
		If Type = 0 Then   
			vErr = NStr("en='E-Mail is not specified!'; ru='Не указан E-Mail!'; de='Unbekannt E-Mail!'");
		EndIf;	
		ShowMessageBox(, vErr);
		Return;
	EndIf;
	vMessage = SendAtServer();
	If Not IsBlankString(vMessage) Then
		ShowMessageBox(, NStr("en='Error:'; ru='Ошибка:'; de='Fehler:'") + Chars.LF + vMessage);
	Else
		ShowMessageBox(, NStr("en='Success!'; ru='Успешно!'; de='Erfolg!'"), 3);
		Close();
	EndIf;
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure SetFormAppearance()
	If Type = 0 Then
		Items.EMail.Enabled = True;
		Items.Phone.Enabled = False;
	Else
		Items.EMail.Enabled = False;
		Items.Phone.Enabled = True;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
// 
// Returns:
//  String - Message
//
&AtServer
Function SendAtServer()
	vMessage = "";   
	vAddress = FillAddress();
	cmSendOnlineCheque(Parameters.Payment, vAddress, vMessage);
	Return vMessage;
EndFunction

// --------------------------------------------------------------------------------
// 
// Returns:
//  String - Address to send
//
&AtServer
Function FillAddress()
	vAddress = TrimAll(Phone);
	If Type = 0 Then
		vAddress = TrimAll(ClientEMail);
	EndIf;
	Return vAddress;
EndFunction

// --------------------------------------------------------------------------------
&AtServer
Procedure PhoneOnChangeAtServer()
	Phone = SMS.GetValidPhoneNumber(TrimAll(Phone));
EndProcedure

#EndRegion
