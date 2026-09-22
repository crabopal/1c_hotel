
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Fill default values
	vIsNew = False;
	If Not ValueIsFilled(Record.Period) Then
		vIsNew = True;
		Record.Period = CurrentSessionDate();
	EndIf;
	If ValueIsFilled(Record.BlockDate) Then
		If Not ValueIsFilled(Record.BlockAuthor) Then
			Record.BlockAuthor = SessionParameters.CurrentUser;
		EndIf;
	EndIf;
	If vIsNew Then
		If Not ValueIsFilled(Record.Hotel) Then
			vGiftCertificatesArePerHotel = Constants.GiftCertificatesArePerHotel.Get();
			If vGiftCertificatesArePerHotel Then
				Record.Hotel = SessionParameters.CurrentHotel;
			EndIf;
		EndIf;
	EndIf;
	// Check user permissions
	If Not vIsNew Then
		If Not cmCheckUserPermissions("HavePermissionToEditPostedFolioTransactions") Then
			tcCommonFunctionOnClientServer.UserMessage(NStr("en='You do not have rights to edit gift certificate! Form will be opened read only.';ru='Нет прав изменять подарочные сертификаты! Форма будет открыта на просмотр.';de='Sie sind nicht berechtigt, Geschenkgutscheine zu ändern. Das Formular wird zur Ansicht geöffnet.'"));
			ThisForm.ReadOnly = True;
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ExternalEvent(pSource, pEvent, pData)
	If Not IsInputAvailable() Then
		Return;
	EndIf;
	
	vEventData = tcConnectionHardwareAtClient.cmGetExternalEventResultInputDevice(pSource, pEvent, pData);
	If IsBlankString(vEventData.DeviceData) Then
		Return;
	EndIf;
	
	Record.GiftCertificate = vEventData.DeviceData;
	GiftCertificateOnChange(Items.GiftCertificate);
EndProcedure // ExternalEvent

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure GiftCertificateOnChange(pItem)
	GiftCertificateOnChangeAtServer();
EndProcedure // GiftCertificateOnChange

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure GiftCertificateOnChangeAtServer()
	If Not IsBlankString(Record.GiftCertificate) And ValueIsFilled(Record.BlockDate) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	GiftCertificates.Period,
		|	GiftCertificates.GiftCertificate AS GiftCertificate,
		|	GiftCertificates.Hotel,
		|	GiftCertificates.BlockDate,
		|	GiftCertificates.BlockReason,
		|	GiftCertificates.BlockAuthor
		|FROM
		|	InformationRegister.GiftCertificates AS GiftCertificates
		|WHERE
		|	GiftCertificates.GiftCertificate = &qGiftCertificate
		|	AND (&qHotelIsEmpty
		|			OR NOT &qHotelIsEmpty
		|				AND GiftCertificates.Hotel = &qHotel)
		|
		|ORDER BY
		|	GiftCertificate";
		vQry.SetParameter("qGiftCertificate", TrimAll(Record.GiftCertificate));
		vQry.SetParameter("qHotel", Record.Hotel);
		vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Record.Hotel));
		vOldRecords = vQry.Execute().Unload();
		If vOldRecords.Count() > 0 Then
			Record.Period = vOldRecords.Get(0).Period;
		EndIf;
	EndIf;
EndProcedure // GiftCertificateOnChangeAtServer

#EndRegion



