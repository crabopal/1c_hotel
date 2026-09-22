
#Region FormEventHandlers

// --------------------------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("SMSText") Then
		SMSText = Parameters.SMSText;
		Items.SMSText.Title = NStr("en='Text (';ru='Текст (';de='Text ('") + String(StrLen(SMSText))+NStr("en=' ch., ';ru=' симв., ';de=' Symb., '")+String(SMS.GetNumberOfSegments(SMSText))+NStr("en=' segm.)';ru=' сегм.)';de=' Segm.)'");
	EndIf;
	
	If Parameters.Property("ReadOnlyReciever") Then
		Items.Reciever.ReadOnly = Parameters.ReadOnlyReciever;
		If Items.Reciever.ReadOnly Then
			Items.Reciever.ChoiceButton = False;
			Items.Reciever.OpenButton = False;
		EndIf;
	EndIf;
	
	If Parameters.Property("Reciever") Then
		Reciever = Parameters.Reciever; 		
	EndIf;
	
	If ValueIsFilled(Reciever) Then
		If TypeOf(Reciever) = Type("CatalogRef.Employees") Then
			vPhones = TrimAll(Reciever.Phones);
			If ValueIsFilled(vPhones) Then
				vCommaPosition = Find(vPhones, ",");
				If vCommaPosition=0 Then
					Phone = SMS.GetValidPhoneNumber(vPhones);
				Else
					Phone = SMS.GetValidPhoneNumber(Left(vPhones, vCommaPosition-1));
				EndIf;
			EndIf;
		ElsIf TypeOf(Reciever) = Type("CatalogRef.Clients") Then
			vPhone = TrimAll(Reciever.Phone);
			If ValueIsFilled(vPhone) Then
				Phone = SMS.GetValidPhoneNumber(vPhone);
			EndIf;	
		ElsIf TypeOf(Reciever) = Type("DocumentRef.Reservation") Or TypeOf(Reciever) = Type("DocumentRef.Accommodation") Then
			vPhone = "";
			If ValueIsFilled(Reciever.Phone) Then
				vPhone = TrimAll(Reciever.Phone); 	
			ElsIf ValueIsFilled(Reciever.Guest) And ValueIsFilled(Reciever.Guest.Phone) Then
				vPhone = TrimAll(Reciever.Guest.Phone); 	
			EndIf;
			If ValueIsFilled(vPhone) Then
				Phone = SMS.GetValidPhoneNumber(vPhone);
			EndIf;
		ElsIf TypeOf(Reciever) = Type("DocumentRef.ResourceReservation") Then
			If ValueIsFilled(Reciever.Phone) Then
				vPhone = TrimAll(Reciever.Phone); 	
			ElsIf ValueIsFilled(Reciever.Client) And ValueIsFilled(Reciever.Client.Phone) Then
				vPhone = TrimAll(Reciever.Client.Phone); 	
			EndIf;
			If ValueIsFilled(vPhone) Then
				Phone = SMS.GetValidPhoneNumber(vPhone);
			EndIf;
		ElsIf TypeOf(Reciever) = Type("DocumentRef.Folio") Then
			If ValueIsFilled(Reciever.Client) And ValueIsFilled(Reciever.Client.Phone) Then
				vPhone = TrimAll(Reciever.Client.Phone); 	
			EndIf;
			If ValueIsFilled(vPhone) Then
				Phone = SMS.GetValidPhoneNumber(vPhone);
			EndIf;
		ElsIf TypeOf(Reciever) = Type("DocumentRef.ProformaInvoice") Then
			If Not IsBlankString(Reciever.Phone) Then
				Phone = SMS.GetValidPhoneNumber(Reciever.Phone);
			EndIf;
		EndIf;	
	EndIf;
	
	If Parameters.Property("Phone") AND Not IsBlankString(Parameters.Phone) Then
		Phone = Parameters.Phone; 		
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure PhoneOnChange(pItem)
	Phone = SMS.GetValidPhoneNumber(Phone);
EndProcedure // PhoneOnChange

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure SMSTextOnChange(pItem)
	pItem.Title = NStr("en='Text (';ru='Текст (';de='Text ('") + String(StrLen(SMSText))+NStr("en=' ch., ';ru=' симв., ';de=' Symb., '")+String(SMS.GetNumberOfSegments(SMSText))+NStr("en=' segm.)';ru=' сегм.)';de=' Segm.)'");
EndProcedure // SMSTextOnChange

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure Send(pCommand)
	If ValueIsFilled(Phone) Then
		If ValueIsFilled(SMSText) Then
			vSegments = SMS.GetNumberOfSegments(SMSText);
			If vSegments > 1 Then
				ShowQueryBox(New NotifyDescription("SendEnd", ThisObject), NStr("en='SMS contained ';ru='СМС содержит ';de='SMS enthält '")+String(vSegments)+NStr("en=' segm. Send SMS?';ru=' сегм. Выполнить отправку СМС?';de=' Segm. SMS Versand ausführen?'"), QuestionDialogMode.YesNo);
                Return;
			EndIf;
			SendPart();
		Else
			ShowMessageBox(,NStr("en='The message is blank!';ru='Пустое сообщение!';de='Leere Mitteilung!'"),,NStr("en='Empty field';ru='Пустое поле';de='Leeres Feld'"));
		EndIf;
	Else
		ShowMessageBox(,NStr("en='Phone field is not filled!';ru='Номер телефона не заполнен!';de='Die Telefonnummer ist nicht ausgefüllt!'"),,NStr("en='Empty field';ru='Пустое поле';de='Leeres Feld'"));
	EndIf;
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure RecieverChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	If TypeOf(pSelectedValue) = Type("CatalogRef.Employees") Then
		vPhones = TrimAll(tcOnServer.cmGetAttributeByRef(pSelectedValue, "Phones"));
		If ValueIsFilled(vPhones) Then
			vCommaPosition = Find(vPhones, ",");
			If vCommaPosition=0 Then
				Phone = SMS.GetValidPhoneNumber(vPhones);
			Else
				Phone = SMS.GetValidPhoneNumber(Left(vPhones, vCommaPosition-1));
			EndIf;
		EndIf;
	ElsIf TypeOf(pSelectedValue) = Type("CatalogRef.Clients") Then
		vPhone = TrimAll(tcOnServer.cmGetAttributeByRef(pSelectedValue, "Phone"));
		If ValueIsFilled(vPhone) Then
			Phone = SMS.GetValidPhoneNumber(vPhone);
		EndIf;
	ElsIf TypeOf(pSelectedValue) = Type("DocumentRef.Reservation") Then
		vPhone = "";
		If ValueIsFilled(pSelectedValue.Phone) Then
			vPhone = TrimAll(pSelectedValue.Phone); 	
		ElsIf ValueIsFilled(pSelectedValue.Guest) And ValueIsFilled(pSelectedValue.Guest.Phone) Then
			vPhone = TrimAll(pSelectedValue.Guest.Phone); 	
		EndIf;
		If ValueIsFilled(vPhone) Then
			Phone = SMS.GetValidPhoneNumber(vPhone);
		EndIf;
	ElsIf TypeOf(pSelectedValue) = Type("DocumentRef.ProformaInvoice") Then
		If Not IsBlankString(pSelectedValue.Phone) Then
			Phone = SMS.GetValidPhoneNumber(pSelectedValue.Phone);
		EndIf;
	EndIf;
EndProcedure // RecieverChoiceProcessing

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure SendEnd(QuestionResult, AdditionalParameters) Export
	vQuestion = QuestionResult;
	If vQuestion = DialogReturnCode.No Then
		Return;
	EndIf;
	SendPart();
EndProcedure

// --------------------------------------------------------------------------------------------------
&AtClient
Procedure SendPart()
	Var vClient, vEmployee, vError;
	vClient = Undefined;
	vEmployee = Undefined;
	vClientDoc = Undefined;
	If ValueIsFilled(Reciever) Then
		If TypeOf(Reciever) = Type("CatalogRef.Employees") Then
			vEmployee = Reciever;
		ElsIf TypeOf(Reciever) = Type("CatalogRef.Clients") Then
			vClient = Reciever;
		ElsIf TypeOf(Reciever) = Type("DocumentRef.Reservation") Or TypeOf(Reciever) = Type("DocumentRef.Accommodation") Then
			vClient = tcOnServer.cmGetAttributeByRef(Reciever, "Guest");
			vEmployee = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
			vClientDoc = Reciever; 
		ElsIf TypeOf(Reciever) = Type("DocumentRef.Folio") Or TypeOf(Reciever) = Type("DocumentRef.ResourceReservation") Then
        	vClient = tcOnServer.cmGetAttributeByRef(Reciever, "Client");
			vEmployee = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
			vClientDoc = Reciever;
		ElsIf TypeOf(Reciever) = Type("DocumentRef.ProformaInvoice") Then
			vClientDoc = tcOnServer.cmGetAttributeByRef(Reciever, "ParentDoc");
			If ValueIsFilled(vClientDoc) Then
				If TypeOf(vClientDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vClientDoc) = Type("DocumentRef.Reservation") Then
					vClient = tcOnServer.cmGetAttributeByRef(vClientDoc, "Guest");
				ElsIf TypeOf(vClientDoc) = Type("DocumentRef.ResourceReservation") Or TypeOf(vClientDoc) = Type("DocumentRef.Folio") Then
					vClient = tcOnServer.cmGetAttributeByRef(vClientDoc, "Client");
				EndIf;
			EndIf;
			vEmployee = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
		EndIf;
	EndIf;
	vError = "";
	If Not SMS.SendMessage(SMSText, SMS.GetValidPhoneNumber(Phone), , ,vClient, vClientDoc, vEmployee, , vError) Then
		Items.ErrorMessage.Visible = True;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to send SMS: ';ru='Ошибка при отправке СМС: ';de='Fehler beim Versenden der SMS: '") + vError);
	Else
		Notify("CommonForm.tcSMSSending.Send", SMS.GetValidPhoneNumber(Phone), Reciever);
		Items.ErrorMessage.Visible = False;
		Items.Send.Visible = False;
		Items.SuccessMessage.Visible = True;
	EndIf;
EndProcedure // Send

#EndRegion
