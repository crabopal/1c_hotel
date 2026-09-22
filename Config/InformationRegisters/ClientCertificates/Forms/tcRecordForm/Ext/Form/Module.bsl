
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("IsNew") Then
		IsNew = Parameters.IsNew;	
	EndIf;
	If Parameters.Property("SelGuest") And Parameters.Property("IsChangeCardOwner") And Parameters.IsChangeCardOwner Then
		IsChangeCardOwner = True;
		SelGuest = Parameters.SelGuest; 
		Items.FormChangeCardOwner.DefaultButton = True;
		Items.FormChangeCardOwner.Visible = True;
		Items.FormChangeCardOwner.Title = NStr("en = 'Change card owner to '; de = 'Karteninhaber ändern in '; ru = 'Измените владельца карты на '") + TrimAll(SelGuest);
		Items.FormUpdateCertificateData.DefaultButton = False;
		Items.FormUpdateCertificateData.Visible = False;
	Else
		IsChangeCardOwner = False;
		Items.FormUpdateCertificateData.DefaultButton = True;
		Items.FormUpdateCertificateData.Visible = True;
		Items.FormChangeCardOwner.DefaultButton = False;
		Items.FormChangeCardOwner.Visible = False;
	EndIf;
	Items.Guest.ReadOnly = Not IsInRole("Administrator");
	Refresh();	
EndProcedure //  OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If IsNew And SelStatus Then
		AttachIdleHandler("AfterShowNewRecord", 5, True);
	ElsIf IsNew And Not SelStatus And ValueIsFilled(Record.LinkToCertificate) Then 
		BeginRunningApplication(New NotifyDescription, Record.LinkToCertificate);	
	EndIf; 
	CurrentItem = Items.FormCommandBar;
EndProcedure //  OnOpen

// -----------------------------------------------------------------------------
&AtClient
Procedure ExternalEvent(pSource, pEvent, pData)
	If Not IsInputAvailable() And ValueIsFilled(Record.Guest) Then
		Return;
	EndIf;
	
	vEventData = tcConnectionHardwareAtClient.cmGetExternalEventResultInputDevice(pSource, pEvent, pData);
	
	If vEventData.DeviceType = "BarCodeScaner" Then
		Try
			If Not IsBlankString(vEventData.DeviceData) Then
				If StrFind(vEventData.DeviceData, "mos.ru") <> 0 Or StrFind(vEventData.DeviceData, "gosuslugi.ru") <> 0 Then 
					If UpdateCertificateDataAtServer(vEventData.DeviceData) Then
						Notify("InformationRegisters.ClientCertificates.Write", Record.Guest);
					EndIf;
				Else
					tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Failed to read QR-Code'; de = 'QR-Code konnte nicht gelesen werden'; ru = 'Не удалось прочитать QR-код'"));
				EndIf;
			Else
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Failed to read QR-Code'; de = 'QR-Code konnte nicht gelesen werden'; ru = 'Не удалось прочитать QR-код'"));
			EndIf;
		Except
			vMsgEror = ErrorDescription();
			tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Failed to read QR-Code: '; de = 'QR-Code konnte nicht gelesen werden: '; ru = 'Не удалось прочитать QR-код: '") + vMsgEror);
		EndTry;
	EndIf;
EndProcedure //  ExternalEvent

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	If ValueIsFilled(QRCode) Then
		pCurrentObject.QRCode = New ValueStorage(GetBinaryDataFromBase64String(QRCode)); 	
	EndIf;
	If pWriteParameters <> Undefined And pWriteParameters.Property("Guest") Then
		If ValueIsFilled(pWriteParameters.Guest) Then
			pCurrentObject.Guest = pWriteParameters.Guest; 		
		Else
			pCancel = True;	
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure QRCodePresentationClick(pItem, pStandardProcessing)
	pStandardProcessing = False;
	If ValueIsFilled(Record.LinkToCertificate) Then
		BeginRunningApplication(New NotifyDescription, Record.LinkToCertificate);	
	EndIf;
EndProcedure //  QRCodePresentationClick

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenURLClick(Item)
	If ValueIsFilled(Record.LinkToCertificate) Then
		BeginRunningApplication(New NotifyDescription, Record.LinkToCertificate);	
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure UpdateCertificateData(pCommand)
	If ValueIsFilled(Record.LinkToCertificate) Then
		If UpdateCertificateDataAtServer() Then
			Notify("InformationRegisters.ClientCertificates.Write", Record.Guest);
		EndIf;
	EndIf;
EndProcedure //  UpdateCertificateData

// -----------------------------------------------------------------------------
&AtClient
Procedure CancelChangeCardOwner(pCommand)
	Close();
EndProcedure //  CancelChangeCardOwner

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeCardOwner(pCommand)
	vOldGuesr = Record.Guest;
	If Write(New Structure("Guest", SelGuest)) Then
		Notify("InformationRegisters.ClientCertificates.Write", vOldGuesr);
		Notify("InformationRegisters.ClientCertificates.Write", Record.Guest);
		Close(True);
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Failed to change the owner of the card.'; de = 'Der Besitzer der Karte konnte nicht geändert werden.'; ru = 'Не удалось изменить владельца карты.'"));
	EndIf;
EndProcedure //  ChangeCardOwner

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterShowNewRecord() Export 
	Close();
EndProcedure //  AfterShowNewRecord

// -----------------------------------------------------------------------------
&AtServer
Procedure Refresh()
	Items.Status.BackColor = WebColors.Red;
	SelStatus = False;
	vGuest = Record.Guest;
	If IsChangeCardOwner Then
		vGuest = SelGuest;	
	EndIf;
	vStatusTitle = "";
	If ValueIsFilled(Record.ValidToDate) And ValueIsFilled(Record.FullName) And ValueIsFilled(Record.DateOfBirth) And ValueIsFilled(Record.CertificateNumber) Then
		If IsChangeCardOwner Then 
			vStatusTitle = TrimAll(vGuest) + ": " 	
		EndIf;
		If Not CheckFullName(vGuest, Record.FullName) Then
			vStatusTitle = ?(ValueIsFilled(vStatusTitle), vStatusTitle + Chars.LF, "") + NStr("en = 'The full name of the guest does not match.'; de = 'Der vollständige Name des Gastes stimmt nicht überein.'; ru = 'Не совпадает ФИО гостя.'");	
		EndIf;
		If Record.DateOfBirth <> vGuest.DateOfBirth Then	
			vStatusTitle = ?(ValueIsFilled(vStatusTitle), vStatusTitle + Chars.LF, "") + NStr("en = 'The date of birth of the guest does not match.'; de = 'Das Geburtsdatum des Gastes stimmt nicht überein.'; ru = 'Не совпадает дата рождения гостя.'");
		EndIf;
		If Record.ValidToDate <= CurrentSessionDate() Then 	
			vStatusTitle = ?(ValueIsFilled(vStatusTitle), vStatusTitle + Chars.LF, "") + NStr("en = 'The certificate has expired.'; de = 'Das Zertifikat ist abgelaufen.'; ru = 'Срок действия сертификата истек.'");
		EndIf;
		If ValueIsFilled(vStatusTitle) Then
			Items.Status.Title = vStatusTitle; 		
		Else
			Items.Status.Title = NStr("en = 'DIGITAL CERTIFICATE '; de = 'DIGITALES ZERTIFIKAT'; ru = 'ЦИФРОВОЙ СЕРТИФИКАТ'");
			Items.Status.BackColor = WebColors.Green;
			SelStatus = True;
		EndIf;
	Else 
		Items.Status.Title = NStr("en = 'Certificate not recognized.'; de = 'Zertifikat nicht anerkannt.'; ru = 'Сертификат не распознан.'");
		Items.Status.BackColor = WebColors.DarkGoldenRod;
	EndIf;
	QRCodePresentation = GetURL(Record.SourceRecordKey, "QRCode");
EndProcedure //  Refresh

// -----------------------------------------------------------------------------
&AtServerNoContext
Function CheckFullName(pClients, pFullName)
	If ValueIsFilled(pFullName) Then
		vFullNameArr = StrSplit(pFullName, " ", False);
		If vFullNameArr.Count() = 3 Then
			If Upper(Left(pClients.LastName, 1)) = Upper(StrReplace(vFullNameArr[0], "*", "")) And Upper(Left(pClients.FirstName, 1)) = Upper(StrReplace(vFullNameArr[1], "*", "")) And Upper(Left(pClients.SecondName, 1)) = Upper(StrReplace(vFullNameArr[2], "*", "")) Then
				Return True	
			Else
				Return False	
			EndIf;
		ElsIf vFullNameArr.Count() = 2 Then
			If Upper(Left(pClients.LastName, 1)) = Upper(StrReplace(vFullNameArr[0], "*", "")) And Upper(Left(pClients.FirstName, 1)) = Upper(StrReplace(vFullNameArr[1], "*", "")) Then
				Return True	
			Else
				Return False	
			EndIf;
		Else
			Return False;	
		EndIf;
	Else
		Return False
	EndIf;
EndFunction //  CheckFullName

// -----------------------------------------------------------------------------
&AtServer
Function UpdateCertificateDataAtServer(pLinkToCertificate = "")
	If ValueIsFilled(pLinkToCertificate) Then
		Record.LinkToCertificate = TrimAll(pLinkToCertificate);
	EndIf;
	vMessage = "";
	If Not InformationRegisters.ClientCertificates.UpdateCertificateData(Record, vMessage, True, QRCode) Then
		tcCommonFunctionOnClientServer.UserMessage(vMessage);
		Return False;
	EndIf;
	If Not Write() Then
		Return False;	
	EndIf;
	Read();
	Refresh();
	tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Completed'; de = 'Fertiggestellt'; ru = 'Выполнено'"));
	Return True;
EndFunction //  UpdateCertificateDataAtServer

#EndRegion



