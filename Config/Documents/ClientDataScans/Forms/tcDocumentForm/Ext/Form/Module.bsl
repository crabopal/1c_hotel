
#Region FormEventHandlers

// ----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Process parameters
	If Parameters.Property("ParentDoc") And ValueIsFilled(Parameters.ParentDoc) Then
		Object.ParentDoc = Parameters.ParentDoc;
	EndIf;
	If Parameters.Property("GuestGroup") And ValueIsFilled(Parameters.GuestGroup) Then
		Object.GuestGroup = Parameters.GuestGroup;
	EndIf;
	If Parameters.Property("Room") And ValueIsFilled(Parameters.Room) Then
		Object.Room = Parameters.Room;
	EndIf;
	If Parameters.Property("Guest") And ValueIsFilled(Parameters.Guest) Then
		Object.Guest = Parameters.Guest;
	EndIf;
	If Parameters.Property("SelScanConfiguration") And ValueIsFilled(Parameters.SelScanConfiguration) Then
		SelScanConfiguration = Parameters.SelScanConfiguration;
	EndIf;
	
	vObject = FormAttributeToValue("Object");		
	If Not ValueIsFilled(vObject.Ref) Then
		// Use current time
		vObject.SetTime(AutoTimeMode.CurrentOrLast);
		// Fill attributes with default values
		If Not ValueIsFilled(vObject.Author) Then
			vObject.pmFillAttributesWithDefaultValues();
		Else
			vObject.pmFillAuthorAndDate();
		EndIf;
	EndIf;
	
	vPhotoBin = vObject.Photo.Get();
	If vPhotoBin = Undefined And ValueIsFilled(vObject.Guest) Then
		vPhotoBin = vObject.Guest.Photo.Get();
	EndIf;
	Photo = PutToTempStorage(vPhotoBin, UUID);
	
	vSignatureBin = vObject.Signature.Get();
	If vSignatureBin = Undefined And ValueIsFilled(vObject.Guest) Then
		vSignatureBin = vObject.Guest.Signature.Get();
	EndIf;
	Signature = PutToTempStorage(vSignatureBin, UUID);
	
	ValueToFormAttribute(vObject, "Object");
	
	vHomeRegion = NStr("en = 'Home country not specified in hotel settings'; de = 'Heimatland nicht in den Hoteleinstellungen angegeben'; ru = 'Домашняя страна не указана в настройках гостиницы'");
	If ValueIsFilled(Object.Hotel) And ValueIsFilled(Object.Hotel.Citizenship) Then
		vHomeRegion = TrimAll(Object.Hotel.Citizenship.Description);
	EndIf;
	Items.IsForeigner.ChoiceList.Add(0,vHomeRegion);
	Items.IsForeigner.ChoiceList.Add(1,NStr("en = 'Foreigner'; de = 'Ausländer'; ru = 'Иностранец'"));
	
	If ValueIsFilled(Object.Guest.Citizenship) Then
		IsForeigner = ?(vHomeRegion <> TrimAll(Object.Guest.Citizenship.Description), 1, 0);
		If Not ValueIsFilled(Object.Citizenship) Then
			Object.Citizenship = Object.Guest.Citizenship;
		EndIf;
		If Not ValueIsFilled(Object.IdentityDocumentType) Then
			If IsForeigner = 1 Then
				Object.IdentityDocumentType = Catalogs.IdentityDocumentTypes.FindByCode("15");
			Else
				Object.IdentityDocumentType = Catalogs.IdentityDocumentTypes.FindByCode("21");
			EndIf;
		EndIf;
	Else
		IsForeigner = 0; //Home region
		If ValueIsFilled(Object.Hotel) Then
			Object.Citizenship = Object.Hotel.Citizenship;
		EndIf;
	EndIf;
	EditTopGroupHeader();
	VisumDataAppearance();
	
	// Check edit prohibited date
	If ValueIsFilled(Object.Hotel) And ValueIsFilled(Object.ParentDoc) Then
		If ValueIsFilled(Object.Hotel.EditProhibitedDate) And 
			BegOfDay(Object.Hotel.EditProhibitedDate) >= BegOfDay(Object.ParentDoc.CheckOutDate) Then
			ReadOnly = True;
		EndIf;
	EndIf;
	
	// Check user rights to edit addresses
	If Not cmCheckUserPermissions("HavePermissionToTextEditClientAddresses") Then
		Items.PlaceOfBirth.TextEdit = False;
		Items.Address.TextEdit = False;
	Endif; 
	
	DefaultScanConfiguration = Catalogs.ScanConfigurations.OtherDocuments;
	DefaultScanConfigurationForeigners = Catalogs.ScanConfigurations.OtherDocumentsForeigners;
	
	// Show or hide export guest data procedure
	vExportDPRef = GetDataProcessorForExportGuestDataToUFMS();
	If Not ValueIsFilled(vExportDPRef) Then
		Items.FormExportGuestDataToUFMSRu.Visible = False;
	EndIf;
	
	SelVaccinationCertificates = GetFunctionalOption("VaccinationCertificates");
	
	// Show or hide validate via dadata buttons
	vHotel = ?(ValueIsFilled(Object.Hotel), Object.Hotel, SessionParameters.CurrentHotel);
	vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionType(Enums.Integrations.DADATA, vHotel);
	If ValueIsFilled(vInteraction) And vInteraction.IsActive And Not IsBlankString(vInteraction.OAuth_AccessToken) Then
		vIntMapping = InformationRegisters.ExternalSystemIntegrationData.GetData(vInteraction,"Dadata");
		If vIntMapping.Count() > 0 Then 
			vData = vIntMapping[0]; 
			If vData.FillAddress Then
				Items.Address.ChoiceButton = True;	
				Items.PlaceOfBirth.ChoiceButton = True;
			Else
				Items.Address.ChoiceButton = False;
				Items.PlaceOfBirth.ChoiceButton = False;
			EndIf;
		Else
			Items.Address.ChoiceButton = False;
			Items.PlaceOfBirth.ChoiceButton = False;	
		EndIf;
	Else
		Items.Address.ChoiceButton = False;
		Items.PlaceOfBirth.ChoiceButton = False;
	EndIf;
	
	// Generate form
	GetGuestListByRoom();
	FillPresentationGuestList();
	FillScanConfigList();
	CreatePhotoBar(True); 
	FillExtraData();
	RefreshDisplay();
	FillScanConfigurationsData();	
EndProcedure //  OnCreateAtServer

// ----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	vMessage = "";
	
	// Set the current guest as active
	If ValueIsFilled(Object.Guest) Or ValueIsFilled(Object.ParentDoc) Then
		vUUID = "1";
		If ValueIsFilled(Object.ParentDoc) Then
			vUUID = String(Object.ParentDoc.UUID());
		ElsIf ValueIsFilled(Object.Guest) Then
			vUUID = String(Object.Guest.UUID());
		EndIf;
		vUUID = StrReplace(vUUID, "-", "_");
		Items["FormGroupGuests" + vUUID].BackColor = WebColors.LightCyan; 
		Items["FormDecorationTitleFIO_" + vUUID].Font = tcCommonFunctionOnClientServer.FontConstructor(,,True);
		CurrentPageGuest = vUUID;
	EndIf;
	
	// Try to connect to scan device
	If amImageScanner = Undefined Or TypeOf(amImageScanner) <> Type("CommonModule") Then
		// Connection images scaner
		vModuleName = tcDevicesConnection.cmGetImagesScannerDriverModule(vMessage);
		If IsBlankString(vMessage) Then
			If vModuleName <> Undefined Then
				amImageScanner  = tcCommonFunctions.cmGetCommonModule(vModuleName);
			EndIf;
		EndIf;
	EndIf;
	
	If amImageScanner = Undefined And amWebCamera = Undefined Then
		vModuleName = tcDevicesConnection.cmGetWebCamDriverModule(vMessage);
		If IsBlankString(vMessage) Then
			If vModuleName <> Undefined Then
				amWebCamera = tcCommonFunctions.cmGetCommonModule(vModuleName);
				amWebCamera.Connect(vMessage);
			EndIf;
		EndIf;
	EndIf;
	
	// If regula connect to device and attach handler
	Items.FormRecognizeImage.Enabled = True;
	If amImageScanner = Undefined And amWebCamera = Undefined Then
		Items.FormRecognizeImage.Enabled = False;
	ElsIf amImageScanner <> Undefined Then
		If amImageScanner = tcSmartPassportBoxEngine Then
			Items.FormRecognizeImage.Enabled = False;
		ElsIf amImageScanner = tcRegula Then
			Items.FormRecognizeImage.Enabled = False;
			
			If amImageScannerInstance = Undefined Then
				amImageScannerInstance = amImageScanner.pmConnect(vMessage);
			EndIf;
			
			If amImageScannerInstance <> Undefined Then
				AddHandler amImageScannerInstance.OnProcessingFinished, Reader_OnProcessingFinished; 
				amImageScanner.ClearResults(amImageScannerInstance);
			EndIf;
		ElsIf amImageScanner = tcScan1C Then
			vInteractionParameters = tcDevicesConnection.cmGetImagesScannerParameters("InteractionParameters");
			If Not tcDevicesConnection.CheckActiveInteractionYandexVision(vInteractionParameters) Then
				Items.FormRecognizeImage.Enabled = False;
			EndIf;
		EndIf;
	ElsIf amWebCamera <> Undefined Then
		If GetYandexVisionIntegration(Object.Hotel) = Undefined Then
			Items.FormRecognizeImage.Enabled = False;
		EndIf;
	EndIf;
		
	If Not IsBlankString(vMessage) Then
		Picture = "";
		Items.Picture.NonselectedPictureText = vMessage;
		Items.Picture.TextColor = WebColors.Red;
	EndIf;
	If ValueIsFilled(SelScanConfiguration) Then
		vRows = Object.ScanPictures.FindRows(New Structure("ScanConfiguration", SelScanConfiguration));	
		If vRows.Count() > 0 Then
			vCurScanRow = vRows[0];	
			Picture = vCurScanRow.TempStorage;
			Items.Picture.NonselectedPictureText = vCurScanRow.Remarks;
			Items.Picture.TextColor = WebColors.Black;
		EndIf;
	EndIf;
EndProcedure //  OnOpen

// ----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	If pWriteParameters.WriteMode = DocumentWriteMode.Posting Then
		If Not CheckClient() Then
			pCancel = True;
		EndIf;
	EndIf;
EndProcedure //  BeforeWrite

// ----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	If ValueIsFilled(Signature) Then	
		vPic = GetFromTempStorage(Signature);
		If TypeOf(vPic) = Type("BinaryData") Then
			vSignature = New ValueStorage(New Picture(vPic));
		ElsIf TypeOf(vPic) = Type("Picture") Then 	
			vSignature = New ValueStorage(vPic);
		Else
			vSignature = Undefined;
		EndIf; 
		pCurrentObject.Signature = vSignature;
	Else
		pCurrentObject.Signature = Undefined;
	EndIf;
	If ValueIsFilled(Photo) Then
		vPic = GetFromTempStorage(Photo);
		If TypeOf(vPic) = Type("BinaryData") Then
			vPhoto = New ValueStorage(New Picture(vPic));
		ElsIf TypeOf(vPic) = Type("Picture") Then 	
			vPhoto = New ValueStorage(vPic);
		Else
			vPhoto = Undefined;
		EndIf; 
		pCurrentObject.Photo = vPhoto;
	Else
		pCurrentObject.Photo = Undefined;
	EndIf;
	ClearEmptyRow();
	pCurrentObject.ScanPictures.Clear();
	
	For Each vScanPictures In Object.ScanPictures Do
		vNewRow = pCurrentObject.ScanPictures.Add();
		vNewRow.Remarks = vScanPictures.Remarks;
		vNewRow.ScanConfiguration = vScanPictures.ScanConfiguration;
		vPic = GetFromTempStorage(vScanPictures.TempStorage);
		If TypeOf(vPic) = Type("BinaryData") Then
			vScanPicture = New ValueStorage(New Picture(vPic));
		ElsIf TypeOf(vPic) = Type("Picture") Then 	
			vScanPicture = New ValueStorage(vPic);
		Else
			vScanPicture = Undefined;
		EndIf; 
		vNewRow.ScanPicture = vScanPicture; 
	EndDo;
	cmGetImagesScannerDriverDataProcessor();     
	If Object.Status = Enums.ScanStatuses.IsProcessed Then
		Object.RecognitionQuality.Clear();
	EndIf;	
EndProcedure //  BeforeWriteAtServer

// ----------------------------------------------------------------------------
&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	If Modified Then
		WasChanged = True;
	EndIf;
	Read();
	FillScanConfigList();
	CreatePhotoBar(True); 
	If Not IsBlankString(SourcePersonalData) Then
		InformationRegisters.PersonalDataSources.AddRecord(pCurrentObject.Guest, SourcePersonalData);	
		SourcePersonalData = "";	
	EndIf;	
EndProcedure //  AfterWriteAtServer

// ----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	If pWriteParameters.WriteMode = DocumentWriteMode.Posting Then
		If ValueIsFilled(Object.ParentDoc) Then
			If TypeOf(Object.ParentDoc) = Type("DocumentRef.Accommodation") Then
				Notify("Document.Accommodation.Write", Object.ParentDoc, ThisObject);
				vReservation = tcOnServer.cmGetAttributeByRef(Object.ParentDoc, "Reservation");
				If ValueIsFilled(vReservation) Then
					Notify("Document.Reservation.Write", vReservation, ThisObject);
				EndIf;
			Else
				Notify("Document.Reservation.Write", Object.ParentDoc, ThisObject);
			EndIf;
		EndIf;  
		Notify("ClientDataScans.Write", Object.ParentDoc, FormOwner);
	EndIf;
EndProcedure //  AfterWrite

// ----------------------------------------------------------------------------
&AtClient
Procedure OnClose(pExit)
	DisconnectDevice(False);
EndProcedure //  OnClose

// ----------------------------------------------------------------------------
&AtClient
Procedure ExternalEvent(pSource, pEvent, pData)
	If Not IsInputAvailable() Then
		If pSource = "TWAIN" And pEvent = "ImageAcquired" Then
			If Not IsBlankString(pData) Then
				vPic = New Picture(pData);	
				vPhoto = PutToTempStorage(vPic, UUID);
				Picture = vPhoto;
				vRow = Object.ScanPictures.Get(CurrentPage);
				vRow.TempStorage = vPhoto;
			Else
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Failed to scan document!'; 
																|de = 'Dokument konnte nicht gescannt werden!'; 
																|ru = 'Не удалось отсканировать документ!'"));
			Endif;
			Modified = True;
			If IsBlankString(SourcePersonalData) Then
				SourcePersonalData = "Scanner";
			Else
				If StrFind(SourcePersonalData, "Scanner") = 0 Then
					SourcePersonalData = SourcePersonalData + "_" + "Scanner";
				EndIf;	
			EndIf;
		ElsIf pSource = "TWAIN" And pEvent = "EndBatch" And amImageScanner = tcScan1C Then
			DisconnectDevice(False);
		EndIf;
		Return;
	EndIf;
	
	vEventData = tcConnectionHardwareAtClient.cmGetExternalEventResultInputDevice(pSource, pEvent, pData);
	If IsBlankString(vEventData.DeviceData) Then
		Return;
	EndIf;
	
	If vEventData.DeviceType = "BarCodeScaner" Then
		If ValueIsFilled(Object.Guest) And SelVaccinationCertificates Then
			FillClientCertificate(vEventData.DeviceData);
		Else
			// MAX
			FillPersData(vEventData.DeviceData);
		EndIf;
	EndIf;
EndProcedure // ExternalEvent

// ----------------------------------------------------------------------------
&AtClient
Procedure BeforeClose(pCancel, pExit, pMessageText, pStandardProcessing)
	If SilentCloseMode Then
		SilentCloseMode = False;
		pStandardProcessing = False;
	EndIf;
	
	If Not pExit Then
		BeforeCloseAtServer();
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// ----------------------------------------------------------------------------
&AtClient
Procedure GuestNameClick(pItem, pStandardProcessing)
	pStandardProcessing = False;
	TransferAllScans(Commands["TransferAllScans"])
EndProcedure //  GuestNameClick

// ----------------------------------------------------------------------------
&AtClient
Procedure ClickGuest(pItem, pStandardProcessing)
	pStandardProcessing = False;
	
	If Not CurrentPageGuest = pItem.Title Then
		If ThisObject.Modified Then
			If Not Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
				Return;
			EndIf;
		EndIf;
		SourcePersonalData = "";
		// Deselect
		If Not IsBlankString(CurrentPageGuest) Then
			Items["FormGroupGuests" + CurrentPageGuest].BackColor = tcCommonFunctionOnClientServer.ColorConstructor(252, 250, 235);
			Items["FormDecorationTitleFIO_" + CurrentPageGuest].Font = tcCommonFunctionOnClientServer.FontConstructor(,,False);
			Items["FormDecorationTitleFIO_" + CurrentPageGuest].Hyperlink = False;
		EndIf;
		
		// Set is active                                                                        
		Items["FormGroupGuests" + pItem.Title].BackColor = WebColors.LightCyan; 
		Items["FormDecorationTitleFIO_" + pItem.Title].Font = tcCommonFunctionOnClientServer.FontConstructor(,,True);
		Items["FormDecorationTitleFIO_" + pItem.Title].Hyperlink = True;
		CurrentPageGuest = pItem.Title;
		
		vFilter = GuestList.FindRows(New Structure("UID", pItem.Title));
		If vFilter.Count()>0 Then
			vRow = vFilter[0];
			
			ChangeRefAtServer(vRow.ClientDataScanRef);
			Items.Picture.NonselectedPictureText = "";
			Picture = "";
			Object.ParentDoc = vRow.ParentDocument;
			FillScanConfigList();
			CreatePhotoBar(True); 
			RefreshDisplay();
			If amImageScanner = tcRegula Then
				amImageScanner.ClearResults(amImageScannerInstance);		
			EndIf;
		EndIf;	
	EndIf;
EndProcedure // ClickGuest

// ----------------------------------------------------------------------------
&AtClient
Procedure ChangeScanConfiguration(pItem)
	vID = Number(StrReplace(pItem.Name, "FormDecorationTitle",""));
	vScanConfigurationsList = GetScanConfigurations(?(IsForeigner = 1, True, False));
	If vScanConfigurationsList.Count() > 0 Then 
		vParams = New Structure("MultipleChoice, Title, ValueList", False, NStr("en = 'Select a scan configuration'; de = 'Wählen Sie eine Scan-Konfiguration'; ru = 'Выберите конфигурацию сканирования'"), vScanConfigurationsList);
		OpenForm("CommonForm.mcChoiceValueList", vParams, ThisObject, UUID, , , New NotifyDescription("AfterChoiceScanConfiguration", ThisObject, vID)); 
	EndIf;
EndProcedure // ChangeScanConfiguration

// ----------------------------------------------------------------------------
&AtClient
Procedure ClickPhoto(pItem, pStandardProcessing)
	Items.Picture.NonselectedPictureText = "";
	pStandardProcessing = False;
	
	Try
		Items["FormGroupCard" + CurrentPage].BackColor = tcCommonFunctionOnClientServer.ColorConstructor(252, 250, 235);
	Except
	EndTry;
	CurrentPage = Number(pItem.Title); 
	vRow = Object.ScanPictures.Get(CurrentPage);	
	If vRow <> Undefined Then
		Picture = vRow.TempStorage;
		Items.Picture.NonselectedPictureText = vRow.Remarks;
		Items.Picture.TextColor = WebColors.Black;
		
		Items["FormGroupCard" + CurrentPage].BackColor = WebColors.LightCyan; 
		
		If Not ValueIsFilled(vRow.TempStorage) Then
			StartScan(vRow);
		EndIf;
		Vision(vRow.ScanConfiguration);	
		
		Modified = True;
	EndIf;
EndProcedure //  ClickPhoto

// ----------------------------------------------------------------------------
&AtClient
Procedure ClickClientCertificate(pItem, pStandardProcessing)
	pStandardProcessing = False;
	
	vClientCertificateArr = StrSplit(pItem.Title, "_", True);
	If vClientCertificateArr.Count() = 2 Then
		vClientCertificateKey = GetClientCertificateKey(Object.Guest, vClientCertificateArr[0], vClientCertificateArr[1]);
		If ValueIsFilled(vClientCertificateKey) Then
			OpenForm("InformationRegister.ClientCertificates.RecordForm", New Structure("Key", vClientCertificateKey), ThisObject, UUID);
		EndIf;
	EndIf;
EndProcedure //  ClickClientCertificate

// ----------------------------------------------------------------------------
&AtClient
Procedure CitizenshipOnChange(pItem)
	CitizenshipOnChangeAtServer();
	ResetFieldRecognitionQuality(pItem)
EndProcedure //  CitizenshipOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure RoomOnChange(pItem)
	EditTopGroupHeader();
EndProcedure //  RoomOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure GuestOnChange(pItem)
	EditTopGroupHeader();
EndProcedure //  GuestOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupOnChange(pItem)
	EditTopGroupHeader();
EndProcedure //  GuestGroupOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure IsForeignerOnChange(pItem)
	ClearMessages();
	IsForeignerOnChangeAtServer();
EndProcedure //  IsForeignerOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure IdentityDocumentUnitCodeOnChange(pItem)
	If Not IsBlankString(Object.IdentityDocumentUnitCode) Then
		vIssuedByList = GetIssuedByListAtServer(TrimAll(Object.IdentityDocumentUnitCode), True);
		If vIssuedByList.Count() = 1 Then
			Object.IdentityDocumentIssuedBy = vIssuedByList.Get(0).Value;
		ElsIf vIssuedByList.Count() > 1 Then
			ShowChooseFromList(New NotifyDescription("IdentityDocumentIssuedByIsChoosen", ThisObject), vIssuedByList, Items.IdentityDocumentIssuedBy);
		EndIf;
	EndIf;
	ResetFieldRecognitionQuality(pItem);
EndProcedure //  IdentityDocumentUnitCodeOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure AddressStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vList = GetAddressFromDadata(Object.Address);
	vSelectedElem = ChooseFromList(vList, pItem);
	If vSelectedElem <> Undefined Then
		Object.Address = vSelectedElem.Value.Address;  
		Object.StreetFiasId = vSelectedElem.Value.StreetFiasId;
	EndIf;
	Modified = True;
EndProcedure //  AddressStartChoice

// ----------------------------------------------------------------------------------
&AtClient
Procedure AddressChoiceProcessing(pItem, pSelectedValue, pAdditionalData, pStandardProcessing)
	If pSelectedValue <> Undefined Then
		Object[pItem.Name] = pSelectedValue.Address;     
		If pItem.Name = "Address" Then
			Object.StreetFiasId = pSelectedValue.StreetFiasId;   
		EndIf;
		pSelectedValue = pSelectedValue.Address;
	EndIf;
EndProcedure

// ----------------------------------------------------------------------------
&AtClient
Procedure PlaceOfBirthStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vList = GetAddressFromDadata(Object.PlaceOfBirth);
	vSelectedElem = ChooseFromList(vList, pItem);
	If vSelectedElem <> Undefined Then
		Object.PlaceOfBirth = vSelectedElem.Value.Address;
	EndIf;
	Modified = True;
EndProcedure //  PlaceOfBirthStartChoice

// ----------------------------------------------------------------------------
&AtClient
Procedure PlaceOfBirthOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	vParameters = New Structure("Country, Address, AddressType, Hotel", Object.Citizenship, TrimAll(Object.PlaceOfBirth), "PlaceOfBirth", Object.Hotel);
	OpenForm("CommonForm.tcInputAddress", vParameters, pItem, Object.Guest, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure //  PlaceOfBirthOpening

// ----------------------------------------------------------------------------
&AtClient
Procedure AddressOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	vParameters = New Structure("Country, Address, AddressType, Hotel", Object.Citizenship, TrimAll(Object.Address), "Address", Object.Hotel);
	OpenForm("CommonForm.tcInputAddress", vParameters, pItem, Object.Guest, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure //  AddressOpening 

// ----------------------------------------------------------------------------
&AtClient
Procedure IdentityDocumentIssuedByStartChoice(pItem, pChoiceData, pStandardProcessing)
	If Not IsBlankString(Object.IdentityDocumentUnitCode) Then
		vIssuedByList = GetIssuedByListAtServer(TrimAll(Object.IdentityDocumentUnitCode), True);
		If vIssuedByList.Count() > 0 Then
			pStandardProcessing = False;
			pChoiceData = New ValueList();
			pChoiceData.LoadValues(vIssuedByList.UnloadValues());
		EndIf;
	EndIf;
EndProcedure //  IdentityDocumentIssuedByStartChoice

// ----------------------------------------------------------------------------
&AtClient
Procedure VisaIssuedDateOnChange(pItem)
	If ValueIsFilled(Object.VisaIssuedDate) And Not ValueIsFilled(Object.VisaFromDate) Then
		Object.VisaFromDate = Object.VisaIssuedDate + 24*3600;
	EndIf;
EndProcedure //  VisaIssuedDateOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure VisaDaysOnChange(pItem)
	If Object.VisaDays > 0 Then
		If ValueIsFilled(Object.VisaFromDate) And Not ValueIsFilled(Object.VisaToDate) Then
			Object.VisaToDate = Object.VisaFromDate + (Object.VisaDays - 1)*24*3600;
		EndIf;
	EndIf;
EndProcedure //  VisaDaysOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure VisaFromDateOnChange(pItem)
	If Object.VisaDays > 0 Then
		If ValueIsFilled(Object.VisaFromDate) And Not ValueIsFilled(Object.VisaToDate) Then
			Object.VisaToDate = Object.VisaFromDate + (Object.VisaDays - 1)*24*3600;
		EndIf;
	EndIf;
EndProcedure //  VisaFromDateOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure ResidencePermitDocumentOnChange(pItem)
	ResidencePermitDocumentOnChangeAtServer();
EndProcedure //  ResidencePermitDocumentOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure VisaTypeOnChange(pItem)
	VisaTypeOnChangeAtServer();
EndProcedure //  VisaTypeOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure AddressAutoComplete(pItem, pText, pChoiceData, pDataGetParameters, pWait, pStandardProcessing)
	pStandardProcessing = False;
	#If Not WebClient And Not MobileClient Then
		FillAddresDadata(pText, pChoiceData);
		If pChoiceData = Undefined Or TypeOf(pChoiceData) = Type("ValueList") And pChoiceData.Count() = 0 Then
			pStandardProcessing = True;
			pChoiceData = Undefined;
		EndIf;	
	#Else
		pStandardProcessing = True;
		pChoiceData = Undefined;
	#EndIf
	Modified = True;
EndProcedure //  AddressAutoComplete

// ----------------------------------------------------------------------------
&AtClient
Procedure AddressTextEditEnd(pItem, pText, pChoiceData, pDataGetParameters, pStandardProcessing)
	pStandardProcessing = False;
	#If Not WebClient And Not MobileClient Then
		FillAddresDadata(pText, pChoiceData);
		If pChoiceData = Undefined Or TypeOf(pChoiceData) = Type("ValueList") And pChoiceData.Count() = 0 Then
			pStandardProcessing = True;
			pChoiceData = Undefined;
		EndIf;	
	#Else
		pStandardProcessing = True;
		pChoiceData = Undefined;
	#EndIf
	Modified = True;
EndProcedure //  AddressTextEditEnd

// ----------------------------------------------------------------------------
&AtClient
Procedure StatusOnChange(pItem)
	If Object.Status = PredefinedValue("Enum.ScanStatuses.IsProcessed") Then
		Object.RecognitionQuality.Clear();
		RefreshDisplay();
	EndIf;
EndProcedure //  StatusOnChange

#EndRegion

#Region FormCommandsEventHandlers

// ----------------------------------------------------------------------------
&AtClient
Procedure RecognizeImage(pCommand)
	If Modified Then
		If Not Write() Then
			Return;
		EndIf;
	EndIf;	
	vMessage = "";
	vIndexWebCam = 0;
	If Not amImageScanner = Undefined Then
		If amImageScanner = tcScan1C Then
			vInteractionParameters = tcDevicesConnection.cmGetImagesScannerParameters("InteractionParameters");
			If tcDevicesConnection.CheckActiveInteractionYandexVision(vInteractionParameters) Then
				// Refresh IAM-token if necessary
				vIAMToken = tcOnServer.cmGetAttributeByRef(vInteractionParameters, "OAuth_RefreshToken");
				vIAMValidThru = tcOnServer.cmGetAttributeByRef(vInteractionParameters, "LastFullSynchronizationTime");
				If ((vIAMValidThru - GetCurrentSessionDate()) / (60 * 60) < 8) Or Not ValueIsFilled(vIAMToken) Then
					tcYandexVision.ExchangeToken(vInteractionParameters, vMessage);
				EndIf;
				// Recognize
				RecognizeYAVision(vInteractionParameters, vMessage);
				CropPhotoYV(vInteractionParameters);
			Else
				vMessage = NStr("en = 'Interaction with Yandex Vision is not active!'; de = 'Die Interaktion mit Yandex Vision ist nicht aktiv!'; ru = 'Взаимодействие с внешней системой Yandex Vision не активно!'");
			EndIf;
		Else
			amImageScanner.RecognizeDocument(ThisObject, vMessage);
		EndIf;
		If Not IsBlankString(vMessage) Then
			Picture = "";
			Items.Picture.NonselectedPictureText = vMessage;
			Items.Picture.TextColor = WebColors.Red;
			Return;
		EndIf; 
		Modified = True;
		RefreshDisplay();
		
	ElsIf amWebCamera <> Undefined Then
		vInteractionParameters = GetYandexVisionIntegration(Object.Hotel);
		If vInteractionParameters <> Undefined And tcOnServer.cmGetAttributeByRef(vInteractionParameters, "IsActive") Then
			// Refresh IAM-token if necessary
			vIAMToken = tcOnServer.cmGetAttributeByRef(vInteractionParameters, "OAuth_RefreshToken");
			vIAMValidThru = tcOnServer.cmGetAttributeByRef(vInteractionParameters, "LastFullSynchronizationTime");
			If ((vIAMValidThru - GetCurrentSessionDate()) / (60 * 60) < 8) Or Not ValueIsFilled(vIAMToken) Then
				tcYandexVision.ExchangeToken(vInteractionParameters, vMessage);
			EndIf;
			// Recognize
			RecognizeYAVision(vInteractionParameters, vMessage);
			CropPhotoYV(vInteractionParameters);
		Else
			vMessage = NStr("en = 'Interaction with Yandex Vision is not active!'; de = 'Die Interaktion mit Yandex Vision ist nicht aktiv!'; ru = 'Взаимодействие с внешней системой Yandex Vision не активно!'");
		EndIf;
	Else
		Picture = "";
		Items.Picture.NonselectedPictureText = NStr("en = 'No image scanner connected'; de = 'Kein Bildscanner angeschlossen'; ru = 'Нет подключенных сканеров изображений'");
		Items.Picture.TextColor = WebColors.Red;
	EndIf; 
EndProcedure //  RecognizeImage

// ----------------------------------------------------------------------------
&AtClient
Procedure TransferAllScans(pCommand)
	vGuestRefList = New ValueList();
	For Each vRowGuest In GuestList Do
		If ValueIsFilled(vRowGuest.ClientDataScanRef) And vRowGuest.ClientDataScanRef <> Object.Ref Then
			vGuestRefList.Add(vRowGuest.ClientDataScanRef, ?(ValueIsFilled(vRowGuest.Guest), vRowGuest.Guest, ""));  	
		EndIf;
	EndDo;
	If vGuestRefList.Count() > 0 Then 
		vParams = New Structure("MultipleChoice, Title, ValueList", False, NStr("en = 'Select a guest'; de = 'Wählen Sie einen Gast aus'; ru = 'Выберите гостя'"), vGuestRefList);
		OpenForm("CommonForm.mcChoiceValueList", vParams, ThisObject, UUID, , , New NotifyDescription("AfterChoiceGuestRef", ThisObject)); 
	EndIf;
EndProcedure //  TransferAllScans

// ----------------------------------------------------------------------------
&AtClient
Procedure CopyButtonClick(pCommand)
	Items.Picture.NonselectedPictureText = "";
	vID = Number(StrReplace(pCommand.Name,"Copy",""));
	vRow = Object.ScanPictures.Get(vID);
	vNewRow = Object.ScanPictures.Add();
	vNewRow.ScanConfiguration = vRow.ScanConfiguration;
	vNewRow.RecognitionIsAvailable = vRow.RecognitionIsAvailable; 	
	vNewRow.Remarks = "";
	CreatePhotoBar();
	ThisObject.Modified = True;
EndProcedure //  CopyButtonClick

// ----------------------------------------------------------------------------
&AtClient
Procedure DeleteButtonClick(pCommand)
	Items.Picture.NonselectedPictureText = "";
	vID = Number(StrReplace(pCommand.Name,"Delete",""));		
	
	vRow = Object.ScanPictures.Get(vID);	
	If Object.ScanPictures.FindRows(New Structure("ScanConfiguration",vRow.ScanConfiguration)).Count() = 1 Then
		Items["FormFieldPhoto" + vID].NonselectedPictureText = NStr("en='Click to scan'; ru='Нажмите для сканирования'; de='Klicken Sie zum Scannen'");
		vRow.TempStorage = "";
		vRow.Remarks = "";
		Picture = "";
	Else
		Object.ScanPictures.Delete(vID);
		CreatePhotoBar();	
	EndIf;
	ThisObject.Modified = True;
EndProcedure //  DeleteButtonClick

// ----------------------------------------------------------------------------
&AtClient
Procedure LoadPictureClick(pCommand)
	Items.Picture.NonselectedPictureText = "";
	vID = Number(StrReplace(pCommand.Name,"LoadPicture",""));		
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadPictureAttachingFileSystemExtensionResult", ThisObject, vID));
EndProcedure //  LoadPictureClick

// ----------------------------------------------------------------------------
&AtClient
Procedure RotateLeft(pCommand)
	#IF NOT WebClient AND NOT MobileClient THEN
		Items.Picture.NonselectedPictureText = "";
		vID = Number(StrReplace(pCommand.Name,"RotateLeft",""));	
		vRow = Object.ScanPictures.Get(vID);
		If vRow <> Undefined And Not IsBlankString(vRow.TempStorage) Then
			vFullFileName = GetTempFileName("jpg");
			vPicture = GetFromTempStorage(vRow.TempStorage);
			If vPicture = Undefined Then
				vMessage = NStr("en='No picture is loaded!';ru='Картинка не загружена!';de='Bild ist nicht geladen!'");
				tcCommonFunctionOnClientServer.UserMessage(vMessage);
				Return;
			EndIf;
			vPicture.Write(vFullFileName);
			// Build active X object to rotate picture
			Try
				vGFLAx = New COMObject("GFLAx.GFLAx");
			Except
				vMessage = NStr("en='GFLAx (ActiveX/ASP component) should be installed first! Go to the current workstation item settings and press <Install GFLAx (ActiveX/ASP component)> button.';ru='ActiveX/ASP библиотека GFLAx не установлена! Для установки откройте карточку настроек рабочего места и нажмите на кнопку <Установить GFLAx (ActiveX/ASP библиотеку)>.';de='Die ActiveX/ASP-Bibliothek GFLAx wurde nicht installiert! Zur Installation öffnen Sie die Arbeitsplatzeinstellungen und wählen Sie <GFLAx (ActiveX/AP-Bibliothek) installieren)>.'");
				tcCommonFunctionOnClientServer.UserMessage(vMessage);
				Return;
			EndTry;
			Try
				vGFLAx.LoadBitmap(vFullFileName);
				vGFLAx.Rotate(90);
				vGFLAx.SaveJPEGQuality = 30;
				vGFLAx.SaveBitmap(vFullFileName);
				vGFLAx = Undefined;
			Except
				vMessage = NStr("en='Unsupported picture format!';ru='Формат картинки не поддерживается!';de='Format des Bilds wird nicht unterstützt!'") + Chars.LF + ErrorDescription();
				tcCommonFunctionOnClientServer.UserMessage(vMessage);
				Return;
			EndTry;
			// Load picture back
			Picture = PutToTempStorage(New Picture(vFullFileName, False), UUID);
			vRow.TempStorage = Picture;
			Try
				DeleteFiles(vFullFileName);
			Except
				tcCommonFunctionOnClientServer.UserMessage(ErrorDescription());
			EndTry;
		Else
			vMessage = NStr("en='Image is not choosen!';ru='Не выбрана картинка!';de='Kein Bild ist gewählt!'");
			tcCommonFunctionOnClientServer.UserMessage(vMessage);
		EndIf;
	#ENDIF
EndProcedure //  RotateLeft

// ----------------------------------------------------------------------------
&AtClient
Procedure RotateRight(pCommand)
	#IF NOT WebClient AND NOT MobileClient THEN
		Items.Picture.NonselectedPictureText = "";
		vID = Number(StrReplace(pCommand.Name,"RotateRight",""));	
		vRow = Object.ScanPictures.Get(vID);
		If vRow <> Undefined And Not IsBlankString(vRow.TempStorage) Then
			vFullFileName = GetTempFileName("jpg");
			vPicture = GetFromTempStorage(vRow.TempStorage);
			If vPicture = Undefined Then
				vMessage = NStr("en='No picture is loaded!';ru='Картинка не загружена!';de='Bild ist nicht geladen!'");
				tcCommonFunctionOnClientServer.UserMessage(vMessage);
				Return;
			EndIf;
			vPicture.Write(vFullFileName);
			// Build active X object to rotate picture
			Try
				vGFLAx = New COMObject("GFLAx.GFLAx");
			Except
				vMessage = NStr("en='GFLAx (ActiveX/ASP component) should be installed first! Go to the current workstation item settings and press <Install GFLAx (ActiveX/ASP component)> button.';ru='ActiveX/ASP библиотека GFLAx не установлена! Для установки откройте карточку настроек рабочего места и нажмите на кнопку <Установить GFLAx (ActiveX/ASP библиотеку)>.';de='Die ActiveX/ASP-Bibliothek GFLAx wurde nicht installiert! Zur Installation öffnen Sie die Arbeitsplatzeinstellungen und wählen Sie <GFLAx (ActiveX/AP-Bibliothek) installieren)>.'");
				tcCommonFunctionOnClientServer.UserMessage(vMessage);
				Return;
			EndTry;
			Try
				vGFLAx.LoadBitmap(vFullFileName);
				vGFLAx.Rotate(-90);
				vGFLAx.SaveJPEGQuality = 30;
				vGFLAx.SaveBitmap(vFullFileName);
				vGFLAx = Undefined;
			Except
				vMessage = NStr("en='Unsupported picture format!';ru='Формат картинки не поддерживается!';de='Format des Bilds wird nicht unterstützt!'") + Chars.LF + ErrorDescription();
				tcCommonFunctionOnClientServer.UserMessage(vMessage);
				Return;
			EndTry;
			// Load picture back
			Picture = PutToTempStorage(New Picture(vFullFileName, False), UUID);
			vRow.TempStorage = Picture;
			Try
				DeleteFiles(vFullFileName);
			Except
				tcCommonFunctionOnClientServer.UserMessage(ErrorDescription());
			EndTry;
		Else
			vMessage = NStr("en='Image is not choosen!';ru='Не выбрана картинка!';de='Kein Bild ist gewählt!'");
			tcCommonFunctionOnClientServer.UserMessage(vMessage);
		EndIf;
	#ENDIF
EndProcedure //  RotateRight

// ----------------------------------------------------------------------------
&AtClient
Procedure Clear(pCommand)
	ClearAtServer();
EndProcedure //  Clear

// ----------------------------------------------------------------------------
&AtClient
Procedure Post(pCommand)
	Write(New Structure("WriteMode", DocumentWriteMode.Posting));
EndProcedure //  Post

// ----------------------------------------------------------------------------
&AtClient
Procedure Copy(pCommand)
	If ValueIsFilled(Object.Ref) Then
		OpenForm("Document.ClientDataScans.ObjectForm", New Structure("CopyingValue, ParentDoc, GuestGroup, Room, Guest", Object.Ref, Object.ParentDoc, Object.GuestGroup, Object.Room, Object.Guest), , Object.Ref);
		SilentCloseMode = True;
		Close();
	Else
		tcCommonFunctionOnClientServer.UserMessage("en='Save document first!'; ru='Сначала сохраните документ!'; de='Speichern Sie das Dokument zuerst!'");
	EndIf;
EndProcedure //  Copy

// ----------------------------------------------------------------------------
&AtClient
Procedure ReconnectDevice(pCommand)
	DisconnectDevice(True);
	OnOpen(False);
EndProcedure //  ReconnectDevice

// ----------------------------------------------------------------------------
&AtClient
Procedure PrintClientScans(pCommand)
	vSpreadsheet = New SpreadsheetDocument;
	PrintClientScansAtServer(vSpreadsheet);
	vSpreadsheet.Show(NStr("en='Scans - '; ru='Сканы - '; de='Scans - '") + TrimAll(Object.Guest));
EndProcedure //  PrintClientScans

// ----------------------------------------------------------------------------
&AtClient
Procedure ExportGuestDataToUFMSRu(pCommand)
	If Object.Ref.IsEmpty() Or Modified Then
		ShowMessageBox(, NStr("ru='Документ должен быть записан!';
		|de='Das Dokument muss aufgezeichnet sein!'; 
		|en='Please write document first!'"));
		Return;
	EndIf;
	vDPRef = GetDataProcessorForExportGuestDataToUFMS();
	If Not ValueIsFilled(vDPRef) Then
		ShowMessageBox(, NStr("en='Data processor for export is not configured!'; ru='Не настроена обработка экспорта!'; de='Exportverarbeitung nicht konfiguriert!'"));
	ElsIf ValueIsFilled(Object.ParentDoc) Then
		OpenForm("DataProcessor.ExportGuestsToUFMSTerritoryApp.Form.tcDPForm", New Structure("DataProcessor, Accommodation, GenerateOnOpen", vDPRef, Object.ParentDoc, True), , Object.ParentDoc);
	EndIf;
EndProcedure //  ExportGuestDataToUFMSRu

// ----------------------------------------------------------------------------
&AtClient
Procedure LoadPhoto(pCommand)
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadPhotoFromFileAttachingFileSystemExtensionResult", ThisObject));
EndProcedure //  LoadPhoto

// ----------------------------------------------------------------------------
&AtClient
Procedure ClearPhoto(pCommand)
	ClearPhotoAtServer();
EndProcedure //  ClearPhoto

// ----------------------------------------------------------------------------
&AtClient
Procedure LoadSignature(pCommand)
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadSignatureFromFileAttachingFileSystemExtensionResult", ThisObject));
EndProcedure //  LoadSignature

// ----------------------------------------------------------------------------
&AtClient
Procedure ClearSignature(pCommand)
	ClearSignatureAtServer();
EndProcedure //  ClearSignature

#EndRegion

#Region Private

// ----------------------------------------------------------------------------
&AtClient
Procedure StartScan(pRow) 
	vMessage = "";
	// Get object driver
	If Not amImageScanner = Undefined And amImageScannerInstance = Undefined And TypeOf(amImageScanner) = Type("CommonModule") Then
		If amImageScanner = tcScan1C Then
			amImageScanner.pmConnect(vMessage);
		Else
			amImageScannerInstance = amImageScanner.pmConnect(vMessage);
		EndIf;
	EndIf;	
	If Not IsBlankString(vMessage) Then
		Picture = "";
		Items.Picture.NonselectedPictureText = vMessage;
		Items.Picture.TextColor = WebColors.Red;
	EndIf;
	If amImageScanner <> Undefined Then  
		If IsBlankString(SourcePersonalData) Then
			SourcePersonalData = "Scanner";
		Else
			If StrFind(SourcePersonalData, "Scanner") = 0 Then
				SourcePersonalData = SourcePersonalData + "_" + "Scanner";
			EndIf;	
		EndIf;	
		If amImageScanner = tcRegula Then
			amImageScanner.ScanDocument(amImageScannerInstance);
		Else
			vOuputParameters = GetEmptyOutputParameters();
			If amImageScanner = tcPassportReaderImageScannerDriver Then
				FillPropertyValues(vOuputParameters, Object, , "RecognitionQuality");
				For Each vQuality In Object.RecognitionQuality Do
					vOuputParameters.RecognitionQuality.Insert(vQuality.Field, vQuality.Quality);
				EndDo;
			EndIf;
			
			vInputParameters = GetInputParameters(vMessage);
			If Not IsBlankString(vMessage) Then
				Picture = "";
				Items.Picture.NonselectedPictureText = vMessage;
				Items.Picture.TextColor = WebColors.Red;
				Return;
			EndIf; 
			
			If pRow.RecognitionIsAvailable = False Then
				vOuputParameters.RussianPassportType = Undefined;
			EndIf;
			amImageScanner.ScanDocument(vInputParameters, vOuputParameters, vMessage);
			If Not IsBlankString(vMessage) Then
				Picture = "";
				Items.Picture.NonselectedPictureText = vMessage;
				Items.Picture.TextColor = WebColors.Red;
				Return;
			EndIf;
			
			FillPassportInfo(vOuputParameters);
			RefreshDisplay();
		EndIf;
	ElsIf amWebCamera <> Undefined Then
		pRow.TempStorage = PutToTempStorage(amWebCamera.MakeAPhoto(CheckWebCam(), GetFocTime()), UUID);
	Else
		Picture = "";
		Items.Picture.NonselectedPictureText = NStr("en = 'No image scanner connected'; de = 'Kein Bildscanner angeschlossen'; ru = 'Нет подключенных сканеров изображений'");
		Items.Picture.TextColor = WebColors.Red;
	EndIf; 
EndProcedure

// --------------------------------------------------------------------------------
// 
// Returns:
//  String - contains the number of currently connected WebCamera 
//
&AtServer
Function CheckWebCam()
	Return SessionParameters.CurrentWorkstation.WEBCamConnectionParameters.TwainDeviceName;
EndFunction //  StartScan 

// --------------------------------------------------------------------------------
// 
// Returns:
// Number  - The number of the frame to make a photo 
//
&AtServer
Function GetFocTime()
	Return SessionParameters.CurrentWorkstation.WEBCamConnectionParameters.FocusTime;
EndFunction 

// ----------------------------------------------------------------------------
&AtClient
Function GetInputParameters(rMessage = "")
	vRow = Object.ScanPictures.Get(CurrentPage);
	
	vStruct = New Structure;
	vStruct.Insert("FormUUID", UUID);
	vStruct.Insert("ScanConfiguration", tcOnServer.cmGetAtributeAsArray(vRow.ScanConfiguration));
	
	If amImageScanner = tcScan1C Then
		vTwainDeviceName = tcDevicesConnection.cmGetImagesScannerParameters("TwainDeviceName");
		vConfColorDepth = tcDevicesConnection.cmGetImagesScannerParameters("ColorDepth");
		vPaperSize = tcDevicesConnection.cmGetImagesScannerParameters("PaperSize");
		vRotation = tcDevicesConnection.cmGetImagesScannerParameters("Rotation");
		
		vStruct.Insert("TwainDeviceName", vTwainDeviceName);
		vStruct.Insert("PaperSize", GetPaperSizeForScan1C(vPaperSize));
		vStruct.Insert("ColorDepth", GetColorDepthForScan1C(vConfColorDepth));
		vStruct.Insert("Rotation", vRotation);
	EndIf;
	
	Return vStruct;
	
EndFunction //  GetInputParameters

// ----------------------------------------------------------------------------
&AtServer
Procedure FillPassportInfo(pData)
	If pData.Property("FillAllItems") And pData.FillAllItems Then
		// Get existing properties
		vProperties = "";
		If pData.Property("RecognitionQuality") And pData.Property("Citizenship") Then
			vProperties = "RecognitionQuality, Citizenship";
		ElsIf pData.Property("RecognitionQuality") Then
			vProperties = "RecognitionQuality";
		ElsIf pData.Property("Citizenship") Then
			vProperties = "Citizenship";
		EndIf;
		// Fill items
		FillPropertyValues(Object, pData, ,vProperties);
		If pData.Property("Citizenship") Then
			If ValueIsFilled(pData.Citizenship) Then
				Object.Citizenship = pData.Citizenship;
			EndIf;
		EndIf;
		// Fill recognition quality
		Object.RecognitionQuality.Clear();
		For Each vInd In pData.RecognitionQuality Do
			vKey = vInd.Key;
			If Not Items.Find(vKey) = Undefined  
				And Not vKey = "Photo" 
				And Not vKey = "Signature"
				And Not vKey = "Picture"
				And Not vInd.Value = "" Then
				
				vStr = Object.RecognitionQuality.Add();
				vStr.Field = vKey;
				vStr.Quality = vInd.Value;
			EndIf; 
		EndDo; 
	EndIf;
	
	If pData.Property("IdentityDocumentPicture") Then
		// Fill picture
		Picture = pData.IdentityDocumentPicture;
		If Not IsBlankString(pData.Photo) Then
			vUUID = "1";
			If ValueIsFilled(Object.ParentDoc) Then
				vUUID = String(Object.ParentDoc.UUID());
			ElsIf ValueIsFilled(Object.Guest) Then
				vUUID = String(Object.Guest.UUID());
			EndIf;
			If ValueIsFilled(Object.ParentDoc) Or ValueIsFilled(Object.Guest) Then
				vUUID = StrReplace(vUUID, "-", "_");
				Photo = pData.Photo;
				ThisObject["Photo" + vUUID] = pData.Photo;
			EndIf;
		EndIf;
		If Not IsBlankString(pData.Signature) Then
			Signature = pData.Signature;
		EndIf;
		vRow = Object.ScanPictures.Get(CurrentPage);
		vRow.TempStorage = Picture;
	EndIf;
EndProcedure //  FillPassportInfo

// ----------------------------------------------------------------------------
//
&AtClient
Procedure Reader_OnProcessingFinished() Export
	
	OldIsForeigner = IsForeigner;
	vResult = tcRegula.GetScannedData(amImageScannerInstance, ScanConfigurationsData, DocumentPages, UUID, IsForeigner);
	Reader_OnProcessingFinished_AtServer(vResult);
	
EndProcedure //  Reader_OnProcessingFinished

// ----------------------------------------------------------------------------
&AtServerNoContext
Function GetUSSR()
	Return Catalogs.Countries.FindByCode(810, False);
EndFunction // GeyUSSR

// ----------------------------------------------------------------------------
&AtClient
Procedure Reader_OnProcessingFinished_AtServer(pResult)
	
	InsertScanPicturesToTable();
	
	FormatCitizenshipAndPlaceOfBirth(pResult);
	
	// Fill Permit Document information
	If pResult.Property("ConfirmingDocumentType") And ValueIsFilled(pResult.ConfirmingDocumentType) Then
		// Save current document type to avoid changing it after substituting the scan configuration
		vCurrDocumentType = Object.IdentityDocumentType;
		
		// Run handler after changing the IsForeigner attribute
		IsForeignerOnChangeAtServer();
		// Choose Permit Document
		Object.ResidencePermitDocument = GetVisaResidencePermitDocument(pResult.ConfirmingDocumentType);
		ResidencePermitDocumentOnChangeAtServer();
		Items.GroupResidencePermitDocument.Show();
		
		// Fill Visa rows
		If pResult.ConfirmingDocumentType = "178" And pResult.Property("VisaIssuedBy") And ValueIsFilled(pResult.VisaIssuedBy) Then
			pResult.VisaIssuedBy = GetCountryByCode(pResult.VisaIssuedBy);			
		EndIf;
		
		If pResult.Property("VisaType") Then
			pResult.VisaType = GetVisaType(pResult.VisaType);
			If ValueIsFilled(pResult.VisaType) And pResult.Property("VisaEntryGoal") Then
				pResult.VisaEntryGoal = GetVisaEntryGoal(pResult.VisaType, pResult.VisaEntryGoal);
			EndIf;
		EndIf;
		
		If pResult.Property("VisaMultiplicity") Then
			pResult.VisaMultiplicity = GetVisaMultiplicityType(pResult.VisaMultiplicity);
		EndIf;
	EndIf;
	
	For Each vKeyAndValue In pResult Do
		If ValueIsFilled(vKeyAndValue.Value) Then
			If Object.Property(vKeyAndValue.Key) Then
				Object[vKeyAndValue.Key] = vKeyAndValue.Value;
			EndIf;
		EndIf;
	EndDo;
	
	// Return previous document type if confirming document was scanned
	If pResult.Property("ConfirmingDocumentType") Then
		Object.IdentityDocumentType = vCurrDocumentType;
	EndIf;		
	
	// Run handler if VisaType item has been changed	
	If pResult.Property("VisaType") And ValueIsFilled(pResult.VisaType) Then
		VisaTypeOnChangeAtServer();
	EndIf;
	
	If ValueIsFilled(pResult.Photo) Then
		vUUID = "1";
		If ValueIsFilled(Object.ParentDoc) Then
			vUUID = String(Object.ParentDoc.UUID());
		ElsIf ValueIsFilled(Object.Guest) Then
			vUUID = String(Object.Guest.UUID());
		EndIf;
		vUUID = StrReplace(vUUID, "-", "_");
		Photo = pResult.Photo;
		ThisObject["Photo" + vUUID] = pResult.Photo;
	EndIf;
	
	Try
		If ValueIsFilled(pResult.Signature) Then
			Signature = pResult.Signature;
		EndIf;
	Except;
	EndTry;
	
	RefreshDisplay();
	ThisObject.Modified = True;
EndProcedure // Reader_OnProcessingFinished_AtServer

// ----------------------------------------------------------------------------
&AtClient
Function GetPlaceOfBirth(pCountry = Undefined, pPostCode = Undefined, pRegion = Undefined, pArea = Undefined, pCity = Undefined)
	vPlaceOfBirth = "";
	If ValueIsFilled(pCountry) Then
		vPlaceOfBirth = vPlaceOfBirth + TrimAll(pCountry);
	EndIf;
	vPlaceOfBirth = vPlaceOfBirth + ", ";
	If ValueIsFilled(pPostCode) Then
		vPlaceOfBirth = vPlaceOfBirth + TrimAll(pPostCode);	
	EndIf;
	vPlaceOfBirth = vPlaceOfBirth + ", ";
	If ValueIsFilled(pRegion) Then
		vPlaceOfBirth = vPlaceOfBirth + TrimAll(pRegion);	
	EndIf;
	vPlaceOfBirth = vPlaceOfBirth + ", ";
	If ValueIsFilled(pArea) Then
		vPlaceOfBirth = vPlaceOfBirth + TrimAll(pArea);	
	EndIf;
	vPlaceOfBirth = vPlaceOfBirth + ", ";
	If ValueIsFilled(pCity) Then
		vPlaceOfBirth = vPlaceOfBirth + TrimAll(pCity);	
	EndIf;
	vPlaceOfBirth = vPlaceOfBirth + ", ";
	Return vPlaceOfBirth;
EndFunction // GetPlaceOfBirth

// ----------------------------------------------------------------------------
&AtClient
Procedure InsertScanPicturesToTable()
	
	vFirstPage 		= True;
	For Each vDocPage In  DocumentPages Do
		If Not vDocPage.IsProcessed Then 
			vFound = False;      
			vScanPicturesArr = Object.ScanPictures.FindRows(New Structure("ScanConfiguration", vDocPage.ScanConfiguration));
			For Each vRow In  vScanPicturesArr Do
				If Not ValueIsFilled(vRow.TempStorage) Or ((vDocPage.Type = "12" Or vDocPage.Type = "215") And vRow.Description = vDocPage.Description) Then
					vFound = True;
					vRow.TempStorage = vDocPage.PictureStorage;				
					Break;
				EndIf;
			EndDo;
			
			If Not vFound Then			
				vRow 					= Object.ScanPictures.Add();
				vRow.ScanConfiguration 	= vDocPage.ScanConfiguration; 
				vRow.TempStorage 		= vDocPage.PictureStorage;
			EndIf;
			vRow.Description			= vDocPage.Description;
			
			If vFirstPage Then
				Picture		= vDocPage.PictureStorage;
				CurrentPage = Object.ScanPictures.IndexOf(vRow);
				vFirstPage 	= False;
			EndIf;
			vDocPage.IsProcessed = True;
		EndIf;	
	EndDo;
	
	If OldIsForeigner <> IsForeigner Then
		ClearEmptyRow();
		FillScanConfigList();	
	EndIf;
	
	CreatePhotoBar();
EndProcedure // InsertScanPicturesToTable

// ----------------------------------------------------------------------------
&AtServer
Procedure ClearEmptyRow()
	i = 0;
	While i <= Object.ScanPictures.Count() - 1 Do
		vRow = Object.ScanPictures.Get(i);
		If not ValueIsFilled(vRow.TempStorage) Then
			Object.ScanPictures.Delete(vRow.LineNumber-1);
		Else
			i = i + 1;	
		EndIf;	
	EndDo;	
	
EndProcedure //  ClearEmptyRow

// ----------------------------------------------------------------------------
&AtServer
Procedure FillScanConfigList()
	vScanConfigurationsList = GetScanConfigurations(?(IsForeigner = 0, False, True));
	For Each vScanConfigurationsListItem In vScanConfigurationsList Do
		vScanConfiguration = vScanConfigurationsListItem.Value;
		If Object.ScanPictures.FindRows(New Structure("ScanConfiguration", vScanConfiguration)).Count() = 0 And DefaultScanConfiguration <> vScanConfiguration AND DefaultScanConfigurationForeigners <> vScanConfiguration Then
			vNewRow = Object.ScanPictures.Add();
			vNewRow.ScanConfiguration = vScanConfiguration;
		EndIf;
	EndDo;
EndProcedure // FillScanConfigList

// ----------------------------------------------------------------------------
&AtServer
Procedure FillTempStorage()
	vObject = FormAttributeToValue("Object");		
	For Each vDocPhoto In vObject.ScanPictures Do
		vPic = vDocPhoto.ScanPicture.Get();
		If vPic <> Undefined And Not ValueIsFilled(Object.ScanPictures.Get(vDocPhoto.LineNumber-1).TempStorage) then
			vRow = Object.ScanPictures.Get(vDocPhoto.LineNumber-1);
			vPicture = vDocPhoto.ScanPicture.Get();
			If TypeOf(vPicture) = Type("String") And ValueIsFilled(Object.Ref) Then  
				vFilePath = GetImageCatalogName(Object.Hotel, Object.Date, Object.Number) + TrimAll(vPicture);
				vPicFile = New File(vFilePath); 
				If vPicFile.Exists() Then
					vPicture = New Picture(vFilePath);
				Else             
					vMsgTemplate = NStr("en = 'No scans found in external storage for configuration %1, guest %2'; 
										|de = 'Im externen Speicher wurden keine Scans für die Konfiguration %1, Gast %2 gefunden.'; 
										|ru = 'Для конфигурации %1, гостя %2, во внешнем хранилище не найдены сканы'");
					tcCommonFunctionOnClientServer.UserMessage(StrTemplate(vMsgTemplate, vDocPhoto.ScanConfiguration, vObject.Guest));	
				EndIf;
			EndIf;
			vRow.TempStorage            = PutToTempStorage(vPicture, UUID);
			vRow.RecognitionIsAvailable = vRow.ScanConfiguration.RecognitionIsAvailable; 
		EndIf;
	EndDo;
EndProcedure //  FillTempStorage

// ----------------------------------------------------------------------------
&AtServerNoContext
Function GetImageCatalogName(pHotel, pDate, pNumber)
	If Not ValueIsFilled(pHotel) Then
		Raise NStr("en='Hotel is not filled! ';ru='У документа не заполнена гостиница! ';de='Bei dem Dokument ist das Hotel nicht eingetragen! '") ;
	EndIf;
	vBLOBRootFolder = TrimAll(pHotel.BLOBRootFolder);
	vNonReplicatingAttributes = pHotel.GetObject().pmGetNonReplicatingAttributes();
	If vNonReplicatingAttributes.Count() > 0 Then
		vBLOBRootFolder = TrimAll(vNonReplicatingAttributes.Get(0).BLOBRootFolder);
	EndIf;
	vDelimeter = "\";
	If Find(vBLOBRootFolder, "/") > 0 Then
		vDelimeter = "/";
	EndIf;
	If Right(vBLOBRootFolder, 1) <> vDelimeter Then
		vBLOBRootFolder = vBLOBRootFolder + vDelimeter;
	EndIf;
	rCatalogName = vBLOBRootFolder + "ClientDataScans" + vDelimeter + TrimAll(pNumber) + "_" + Format(pDate, "DF=yyyy-MM-dd") + vDelimeter;
	Return rCatalogName;
EndFunction //  GetImageCatalogName

// ----------------------------------------------------------------------------
&AtServer
Function CreatePhotoBar(pNew = False)
	While Items.GroupPageList.ChildItems.Count() > 0 Do
		If StrFind(Items.GroupPageList.ChildItems[0].Name, "ClientCertificate") = 0 Then 
			Commands.Delete(Commands["Delete" + StrReplace(Items.GroupPageList.ChildItems[0].Name,"FormGroupCard","")]);
			Commands.Delete(Commands["Copy" + StrReplace(Items.GroupPageList.ChildItems[0].Name,"FormGroupCard","")]);
			Commands.Delete(Commands["RotateRight" + StrReplace(Items.GroupPageList.ChildItems[0].Name,"FormGroupCard","")]);
			Commands.Delete(Commands["RotateLeft" + StrReplace(Items.GroupPageList.ChildItems[0].Name,"FormGroupCard","")]);
			Commands.Delete(Commands["LoadPicture" + StrReplace(Items.GroupPageList.ChildItems[0].Name,"FormGroupCard","")]);
		EndIf;
		
		Items.Delete(Items.GroupPageList.ChildItems[0]);
	EndDo;
	If pNew Then	
		FillTempStorage();	
	EndIf;
	SortScanPictures();
	For Each vDocPhoto In Object.ScanPictures Do	
		CreateCard(vDocPhoto);
	EndDo;
	If SelVaccinationCertificates Then
		vClientCertificates = GetClientCertificates(Object.Guest);
		vID = 0;
		For Each vClientCertificate In vClientCertificates Do	
			CreateClientCertificate(vClientCertificate, vID);
			vID = vID + 1;
		EndDo;
	EndIf;
EndFunction //  CreatePhotoBar

// ----------------------------------------------------------------------------
&AtServerNoContext
Function GetClientCertificates(pClients)
	vQuery = New Query();
	vQuery.Text = 
	"SELECT
	|	ClientCertificates.Guest AS Guest,
	|	ClientCertificates.CertificateNumber AS CertificateNumber,
	|	ClientCertificates.QRCode AS QRCode,
	|	ClientCertificates.ValidToDate AS ValidToDate,
	|	ClientCertificates.DateOfBirth AS DateOfBirth,
	|	ClientCertificates.LinkToCertificate AS LinkToCertificate,
	|	ClientCertificates.FullName AS FullName,
	|	ClientCertificates.RegistrationDay AS RegistrationDay,
	|	ClientCertificates.Remarks AS Remarks
	|FROM
	|	InformationRegister.ClientCertificates AS ClientCertificates
	|WHERE
	|	ClientCertificates.Guest = &qGuest
	|
	|ORDER BY
	|	RegistrationDay";
	vQuery.SetParameter("qGuest", pClients);
	Return vQuery.Execute().Unload();
EndFunction //  GetClientCertificates

// ----------------------------------------------------------------------------
&AtServer
Function CreateClientCertificate(pClientCertificate, pID)
	vClientCertificateGroup = tcOnServer.cmCreateItem(ThisObject, Items.GroupPageList, "ClientCertificate" + pID, "FormGroup",
	New Structure("Type, Title, Width, BackColor, Group, ShowTitle, HorizontalStretch, VerticalStretch",
	FormGroupType.UsualGroup, pClientCertificate.CertificateNumber, 18, GetColorByClientCertificate(pClientCertificate), ChildFormItemsGroup.Vertical, False, False, False));
	
	tcOnServer.cmCreateItem(ThisObject, vClientCertificateGroup, "ClientCertificateLinie" +  pID, "FormDecoration", 
	New Structure("Type, Border, HorizontalStretch, AutoMaxWidth", 
	FormDecorationType.Label, New Border(ControlBorderType.WithoutBorder), True, False));												   
	
	vFormattedString = New Array();
	vFormattedString.Add(New FormattedString(NStr("en = 'Certificate'; de = 'Zertifikat'; ru = 'Сертификат'")));
	vFormattedString.Add(New FormattedString(Chars.LF + pClientCertificate.CertificateNumber, tcCommonFunctionOnClientServer.FontConstructor(,,True)));
	
	tcOnServer.cmCreateItem(ThisObject, vClientCertificateGroup, "ClientCertificateTitle" +  pID, "FormDecoration", 
	New Structure("Type, Title, HorizontalStretch, HorizontalAlign, Height", 
	FormDecorationType.Label, New FormattedString(vFormattedString), True, ItemHorizontalLocation.Center, 2));
	
	Try
		vNewAttributesArr = New Array();
		vNewAttributesArr.Add(New FormAttribute("ClientCertificate_" + pID, New TypeDescription("String",, New StringQualifiers(0))));
		ChangeAttributes(vNewAttributesArr);
	Except
	EndTry;
	
	vClientCertificateKey = InformationRegisters.ClientCertificates.CreateRecordKey(New Structure("Guest, CertificateNumber, RegistrationDay", pClientCertificate.Guest, pClientCertificate.CertificateNumber, pClientCertificate.RegistrationDay));
	ThisObject["ClientCertificate_" + pID] = ?(ValueIsFilled(vClientCertificateKey), GetURL(vClientCertificateKey, "QRCode"), "");
	
	tcOnServer.cmCreateItem(ThisObject, vClientCertificateGroup, "ClientCertificatePhoto" + pID, "FormField",
	New Structure("Type, DataPath, HorizontalStretch, PictureSize, Title, Border, SetActionClick, Hyperlink, TitleLocation, Height, Width, VerticalStretch, HorizontalStretch, NonselectedPictureText",
	FormFieldType.PictureField, "ClientCertificate_" + pID, False, PictureSize.Proportionally, pClientCertificate.CertificateNumber + "_" + Format(pClientCertificate.RegistrationDay, "DF=yyyyMMddhhmmss"), New Border(ControlBorderType.WithoutBorder), "ClickClientCertificate", True, FormItemTitleLocation.None, 7, 0, False, True, ?(IsBlankString(pClientCertificate.Remarks), NStr("en = 'Certificate not recognized.'; de = 'Zertifikat nicht anerkannt.'; ru = 'Сертификат не распознан.'"), TrimAll(pClientCertificate.Remarks))));										  
EndFunction //  CreateClientCertificate

// ----------------------------------------------------------------------------
&AtServer
Function GetColorByClientCertificate(pRecord)
	vColor = tcCommonFunctionOnClientServer.ColorConstructor(229, 255, 204);
	If ValueIsFilled(pRecord.ValidToDate) And ValueIsFilled(pRecord.FullName) And ValueIsFilled(pRecord.DateOfBirth) And ValueIsFilled(pRecord.CertificateNumber) Then
		If Not CheckFullName(pRecord.Guest, pRecord.FullName) And Not CheckFullName(pRecord.Guest, Object.LastName + " " + Object.FirstName + " " + Object.SecondName) Then
			vColor = tcCommonFunctionOnClientServer.ColorConstructor(255, 153, 153);
		ElsIf pRecord.DateOfBirth <> pRecord.Guest.DateOfBirth And pRecord.DateOfBirth <> Object.DateOfBirth Then	
			vColor = tcCommonFunctionOnClientServer.ColorConstructor(255, 153, 153);
		ElsIf pRecord.ValidToDate <= CurrentSessionDate() Then 	
			vColor = tcCommonFunctionOnClientServer.ColorConstructor(255, 153, 153);			
		EndIf;
	Else 
		vColor = tcCommonFunctionOnClientServer.ColorConstructor(184, 134, 11);
	EndIf;	
	Return vColor;
EndFunction //  GetColorByClientCertificate

// ----------------------------------------------------------------------------
&AtServer
Procedure SortScanPictures()
	vScanPicturesCount = Object.ScanPictures.Count();
	For vNumber = 0 To vScanPicturesCount - 1 Do
		vBreak = True;
		For vNumberRow = 0 To vScanPicturesCount - (vNumber + 2) Do
			If Object.ScanPictures[vNumberRow].ScanConfiguration.SortCode > Object.ScanPictures[vNumberRow + 1].ScanConfiguration.SortCode Then
				vBreak = False;
				Object.ScanPictures.Move(vNumberRow, 1);  
			EndIf;
		EndDo;
		If vBreak then
			Break;	
		EndIf;
	EndDo;
EndProcedure //  SortScanPictures

// ----------------------------------------------------------------------------
&AtServer
Procedure GetGuestListByRoom()
	vFirstWasAdded = False;
	If ValueIsFilled(Object.ParentDoc) Then
		vNumber = TrimAll(Object.ParentDoc.Number);
		vGuestGroup = Object.ParentDoc.GuestGroup;
		objGuestGroup = vGuestGroup.GetObject();
		vAccList = objGuestGroup.pmGetAccommodations();
		For Each vAcc In vAccList Do
			If vAcc.Number = vNumber Then
				vGuest = vAcc.Guest;
				If ValueIsFilled(vGuest) Then
					vFilter = GuestList.FindRows(New Structure("Guest", vGuest));
					If vFilter.Count() > 0 Then
						Continue;
					EndIf;
				EndIf;
				vRow = GuestList.Add();
				If vGuest = Object.Guest And Not vFirstWasAdded Then
					If Object.Ref.isEmpty() Then
						ThisObject.Write();
					EndIf;	
					vRow.ClientDataScanRef = Object.Ref;
					vRow.ParentDocument = Object.ParentDoc;
					vRow.Guest = Object.Guest;
					vFirstWasAdded = True;
				Else	
					vRow.ClientDataScanRef = GetClientDataScanDocument(vAcc.Accommodation);
					vRow.ParentDocument = vAcc.Accommodation;
					vRow.Guest = vRow.ClientDataScanRef.Guest;
				EndIf;
				vUUID = "1";
				If ValueIsFilled(vRow.ParentDocument) Then
					vUUID = String(vRow.ParentDocument.UUID());
				ElsIf ValueIsFilled(vRow.Guest) Then
					vUUID = String(vRow.Guest.UUID());
				EndIf;
				vUUID = StrReplace(vUUID, "-", "_");
				vRow.UID = vUUID;
			EndIf;
		EndDo;
		vResList = objGuestGroup.pmGetReservations(True, True);
		For Each vRes In vResList Do
			If vRes.Number = vNumber And Not vRes.Status.IsCheckIn Then
				vGuest = vRes.Guest;
				If ValueIsFilled(vGuest) Then
					vFilter = GuestList.FindRows(New Structure("Guest", vGuest));
					If vFilter.Count() > 0 Then
						Continue;
					EndIf;
				EndIf;
				vRow = GuestList.Add();
				If vGuest = Object.Guest And Not vFirstWasAdded Then
					If Object.Ref.isEmpty() Then
						ThisObject.Write();
					EndIf;	
					vRow.ClientDataScanRef = Object.Ref;
					vRow.ParentDocument = Object.ParentDoc;
					vRow.Guest = Object.Guest;
					vFirstWasAdded = True;
				Else	
					vRow.ClientDataScanRef = GetClientDataScanDocument(vRes.Reservation);
					vRow.ParentDocument = vRes.Reservation;
					vRow.Guest = vRow.ClientDataScanRef.Guest;
				EndIf;
				vUUID = "1";
				If ValueIsFilled(vRow.ParentDocument) Then
					vUUID = String(vRow.ParentDocument.UUID());
				ElsIf ValueIsFilled(vRow.Guest) Then
					vUUID = String(vRow.Guest.UUID());
				EndIf;
				vUUID = StrReplace(vUUID, "-", "_");
				vRow.UID = vUUID;
			EndIf;
		EndDo;
		vFilter = GuestList.FindRows(New Structure("Guest", Object.Guest));
		If vFilter.Count() = 0 Then
			vClientDataScanRef = GetClientDataScanDocument(Object.ParentDoc);
			If ValueIsFilled(vClientDataScanRef) And ValueIsFilled(vClientDataScanRef.Guest) Then
				vFilter = GuestList.FindRows(New Structure("Guest", vClientDataScanRef.Guest));
				If vFilter.Count() = 0 Then
					vRow = GuestList.Add();
					vRow.ClientDataScanRef = vClientDataScanRef;
					vRow.Guest = vClientDataScanRef.Guest;
					vUUID = "1";
					If ValueIsFilled(Object.ParentDoc) Then
						vUUID = String(Object.ParentDoc.UUID());
					ElsIf ValueIsFilled(vRow.Guest) Then
						vUUID = String(vRow.Guest.UUID());
					EndIf;
					vUUID = StrReplace(vUUID, "-", "_");
					vRow.UID = vUUID;
				EndIf;	
			EndIf;	
		EndIf;	
	Else
		If ValueIsFilled(Object.Guest) Then
			vRow = GuestList.Add();
			vRow.ClientDataScanRef = Object.Ref;
			vRow.Guest = Object.Guest;
			vUUID = "1";
			If ValueIsFilled(vRow.Guest) Then
				vUUID = String(vRow.Guest.UUID());
			EndIf;
			vUUID = StrReplace(vUUID, "-", "_");
			vRow.UID = vUUID;
		EndIf;
	EndIf;	
EndProcedure //  GetGuestListByRoom

// ----------------------------------------------------------------------------
&AtServer
Procedure FillPresentationGuestList()
	For Each vRowGuest In GuestList Do
		vID = vRowGuest.UID;
		vCardGroup = tcOnServer.cmCreateItem(ThisObject, Items.GroupGuestPageList, "Guests" + vID, "FormGroup",
		New Structure("Type, Title, Width, BackColor, Group, ShowTitle, HorizontalStretch, VerticalStretch",
		FormGroupType.UsualGroup, vRowGuest.Guest, 18, tcCommonFunctionOnClientServer.ColorConstructor(252,250,235), ChildFormItemsGroup.Vertical, False, False, False));
		
		tcOnServer.cmCreateItem(ThisObject, vCardGroup, "Linie" +  vID, "FormDecoration", 
		New Structure("Type, Border, HorizontalStretch, AutoMaxWidth", 
		FormDecorationType.Label, New Border(ControlBorderType.Overline), True, False));												   
		
		vExtraGroup = tcOnServer.cmCreateItem(ThisObject, vCardGroup, "ExtraGroup" + vID, "FormGroup",
		New Structure("Type, Title, ShowTitle, Width, Group, ShowTitle, HorizontalStretch, VerticalStretch",
		FormGroupType.UsualGroup, "ExtraGroup", False, 0, ChildFormItemsGroup.AlwaysHorizontal, False, True, False));
		
		vPicSex = PictureLib.Empty;
		If ValueIsFilled(vRowGuest.Guest) Then
			vGuestSex = vRowGuest.Guest.Sex;		
			If ValueIsFilled(vGuestSex) Then
				If vGuestSex = Enums.Sex.Female Then
					vPicSex = PictureLib.Female;
				Else
					vPicSex = PictureLib.Male;
				EndIf;
			EndIf;
		EndIf;
		tcOnServer.cmCreateItem(ThisObject, vExtraGroup, "Sex_" +  vID, "FormDecoration", 
		New Structure("Type, Title, Picture", 
		FormDecorationType.Picture, "Sex_" + vID, vPicSex));
		
		vGuestItems = tcOnServer.cmCreateItem(ThisObject, vExtraGroup, "TitleFIO_" +  vID, "FormDecoration", 
		New Structure("Type, Title, HorizontalStretch, HorizontalAlign, Height, SetActionClick", 
		FormDecorationType.Label, vRowGuest.Guest, True, ItemHorizontalLocation.Left, 1, "GuestNameClick"));
		
		If vRowGuest.ClientDataScanRef = Object.Ref Then
			vGuestItems.Hyperlink = True;
		Else
			vGuestItems.Hyperlink = False;	
		EndIf;
		
		tcOnServer.cmCreateItem(ThisObject, vCardGroup, "DateOfBirth_" +  vID, "FormDecoration", 
		New Structure("Type, Title, HorizontalStretch, HorizontalAlign, Height", 
		FormDecorationType.Label, Format(vRowGuest.Guest.DateOfBirth, "DLF=D"), True, ItemHorizontalLocation.Center, 1));
		
		If ValueIsFilled(vRowGuest.ParentDocument) Then
			tcOnServer.cmCreateItem(ThisObject, vCardGroup, "AccommodationType_" +  vID, "FormDecoration", 
			New Structure("Type, Title, HorizontalStretch, HorizontalAlign, Height", 
			FormDecorationType.Label, TrimAll(vRowGuest.ParentDocument.AccommodationType), True, ItemHorizontalLocation.Center, 1));
		EndIf;
		
		vAtrArr = New Array;
		vArrTypes = New Array;
		vArrTypes.Add(Тип("Строка"));
		
		vAtr = New FormAttribute("Photo" + vID, New TypeDescription(vArrTypes), , "Photo", True);
		vAtrArr.Add(vAtr);
		ChangeAttributes(vAtrArr);
		
		vPhotoBin = vRowGuest.ClientDataScanRef.Photo.Get();
		If vPhotoBin = Undefined And ValueIsFilled(vRowGuest.Guest) Then
			vPhotoBin = vRowGuest.Guest.Photo.Get();
		EndIf;
		ThisObject["Photo" + vID] = PutToTempStorage(vPhotoBin, UUID);
		
		tcOnServer.cmCreateItem(ThisObject, vCardGroup, "Photo" + vID, "FormField",
		New Structure("Type, DataPath, HorizontalStretch, PictureSize, Title, SetActionClick, Hyperlink, TitleLocation, Height, Width, VerticalStretch, HorizontalStretch, NonselectedPictureText",
		FormFieldType.PictureField, "Photo" + vID, False, PictureSize.Proportionally, vID, "ClickGuest", True, FormItemTitleLocation.None, 7, 0, False, True, NStr("en='Click to switch to this guest'; ru='Нажмите для переключения на этого гостя'; de='Klicken Sie hier, um zu diesem Gast zu wechseln'")));
	EndDo;
EndProcedure //  FillPresentationGuestList

// ----------------------------------------------------------------------------
//
// Parameters:
//  pItem		 - Items - Item
//  pExtraParams - Null	 - Extra params
//
&AtClient
Procedure AfterChoiceGuestRef(pItem, pExtraParams) Export 
	If pItem <> Undefined Then
		MoveAllScansAtServer(pItem.Value);      
		CreatePhotoBar();
	EndIf;
EndProcedure //  AfterChoiceGuestRef

// ----------------------------------------------------------------------------
&AtServer
Procedure MoveAllScansAtServer(pRef) 
	BeginTransaction(DataLockControlMode.Managed);
	Try
		vObjMain = FormAttributeToValue("Object");
		vObj = pRef.GetObject();
		
		vScanPicturesMain = vObjMain.ScanPictures.Unload();
		vScanPictures = vObj.ScanPictures.Unload();
		
		vObj.ScanPictures.Clear();
		
		For Each vRow In vScanPicturesMain Do
			vNewRow = vObj.ScanPictures.Add();
			vNewRow.ExtraDataForOCR = vRow.ExtraDataForOCR;
			vNewRow.Remarks = vRow.Remarks;
			vNewRow.ScanConfiguration = vRow.ScanConfiguration; 
			vNewRow.ScanPicture = vRow.ScanPicture; 
		EndDo;
		
		vObj.Write(DocumentWriteMode.Posting);
		
		vObjMain.ScanPictures.Clear();
		
		For Each vRow In vScanPictures Do
			vNewRow = vObjMain.ScanPictures.Add();
			vNewRow.ExtraDataForOCR = vRow.ExtraDataForOCR;
			vNewRow.Remarks = vRow.Remarks;
			vNewRow.ScanConfiguration = vRow.ScanConfiguration; 
			vNewRow.ScanPicture = vRow.ScanPicture; 
		EndDo;
		
		vObjMain.Write(DocumentWriteMode.Posting);
		ValueToFormAttribute(vObjMain,"Object");
		FillScanConfigList();
		FillTempStorage();
		CommitTransaction();
	Except
		vError = ErrorDescription();
		tcCommonFunctionOnClientServer.UserMessage(vError);
		RollbackTransaction();
	EndTry;
EndProcedure //  MoveAllScansAtServer

// ----------------------------------------------------------------------------
&AtServer
Procedure VisumDataAppearance()
	If Object.ResidencePermitDocument = Enums.ConfirmingDocuments.WithoutVisa Then
		Items.GroupNoVisum.Visible = True;
		Items.GroupVisum.Visible = False;
		Items.GroupTempResidencePermit.Visible = False;
		Items.GroupPermanentResidencePermit.Visible = False;
	ElsIf Object.ResidencePermitDocument = Enums.ConfirmingDocuments.Visa Or Object.ResidencePermitDocument = Enums.ConfirmingDocuments.ElectronicVisa Then
		Items.GroupNoVisum.Visible = False;
		Items.GroupVisum.Visible = True;
		Items.GroupTempResidencePermit.Visible = False;
		Items.GroupPermanentResidencePermit.Visible = False;
	ElsIf Object.ResidencePermitDocument = Enums.ConfirmingDocuments.TempResidencePermit Then
		Items.GroupNoVisum.Visible = False;
		Items.GroupVisum.Visible = False;
		Items.GroupTempResidencePermit.Visible = True;
		Items.GroupPermanentResidencePermit.Visible = False;
	ElsIf Object.ResidencePermitDocument = Enums.ConfirmingDocuments.PermResidencePermit Then
		Items.GroupNoVisum.Visible = False;
		Items.GroupVisum.Visible = False;
		Items.GroupTempResidencePermit.Visible = False;
		Items.GroupPermanentResidencePermit.Visible = True;
	Else
		Items.GroupNoVisum.Visible = False;
		Items.GroupVisum.Visible = False;
		Items.GroupTempResidencePermit.Visible = False;
		Items.GroupPermanentResidencePermit.Visible = False;
	EndIf;
	VisaTypeOnChangeAtServer();
EndProcedure //  VisumDataAppearance

// ----------------------------------------------------------------------------
&AtServer
Procedure ChangeRefAtServer(pRef)
	vObject = pRef.GetObject();
	ValueToFormAttribute(vObject, "Object");
	If ValueIsFilled(Object.Hotel) Then
		If ValueIsFilled(Object.Citizenship) Then
			IsForeigner = Object.Hotel.Citizenship <> Object.Citizenship;
		Else
			IsForeigner = 0; //Home region
			Object.Citizenship = Object.Hotel.Citizenship;
		EndIf;
	EndIf;
	EditTopGroupHeader();
	VisumDataAppearance();
	
	vPhotoBin = vObject.Photo.Get();
	If vPhotoBin = Undefined And ValueIsFilled(vObject.Guest) Then
		vPhotoBin = vObject.Guest.Photo.Get();
	EndIf;
	Photo = PutToTempStorage(vPhotoBin, UUID);
	
	vSignatureBin = vObject.Signature.Get();
	If vSignatureBin = Undefined And ValueIsFilled(vObject.Guest) Then
		vSignatureBin = vObject.Guest.Signature.Get();
	EndIf;
	Signature = PutToTempStorage(vSignatureBin, UUID);
	
	DuplicatesCheckedClient = Catalogs.Clients.EmptyRef();
EndProcedure //  ChangeRefAtServer

// ----------------------------------------------------------------------------
&AtServer
Function CreateCard(vRow)
	vID = vRow.LineNumber - 1;
	vCardGroup = tcOnServer.cmCreateItem(ThisObject, Items.GroupPageList, "Card" + vID, "FormGroup",
	New Structure("Type, Title, Width, BackColor, Group, ShowTitle, HorizontalStretch, VerticalStretch",
	FormGroupType.UsualGroup, vRow.ScanConfiguration, 18, tcCommonFunctionOnClientServer.ColorConstructor(252, 250, 235), ChildFormItemsGroup.Vertical, False, False, False));
	
	tcOnServer.cmCreateItem(ThisObject, vCardGroup, "Linie" +  vID, "FormDecoration", 
	New Structure("Type, Border, HorizontalStretch, AutoMaxWidth", 
	FormDecorationType.Label, New Border(ControlBorderType.Overline), True, False));												   
	
	tcOnServer.cmCreateItem(ThisObject, vCardGroup, "Title" +  vID, "FormDecoration", 
	New Structure("Type, Title, HorizontalStretch, HorizontalAlign, Height, Hyperlink, SetActionClick", 
	FormDecorationType.Label, ?(ValueIsFilled(vRow.Description), vRow.Description, vRow.ScanConfiguration), True, ItemHorizontalLocation.Center, 2, True, "ChangeScanConfiguration"));
	
	vButtonGroup = tcOnServer.cmCreateItem(ThisObject, vCardGroup, "ButtonGroupRotate" + vID, "FormGroup",
	New Structure("Type, ShowTitle, HorizontalStretch, Group",
	FormGroupType.UsualGroup, False, True, ChildFormItemsGroup.AlwaysHorizontal));
	
	vCommand = Commands.Add("RotateLeft" + vID);
	vCommand.Action = "RotateLeft";
	vStructure = New Structure("Title, CommandName, Type, Picture, Representation, HorizontalAlignInGroup, Width",
	NStr("en='Rotate left'; ru='Повернуть налево'; de='Links drehen'"), "RotateLeft" + vID, FormButtonType.CommandBarButton, PictureLib.FindPrevious, ButtonRepresentation.Picture, ItemHorizontalLocation.Left, 0);
	tcOnServer.cmCreateItem(ThisObject, vButtonGroup, "RotateLeft" + vID, "FormButton", vStructure);
	
	vCommand = Commands.Add("RotateRight" + vID);
	vCommand.Action = "RotateRight";
	vStructure = New Structure("Title, CommandName, Type, Picture, Representation, HorizontalAlignInGroup, Width",
	NStr("en='Rotate right'; ru='Повернуть направо'; de='Rechts drehen'"), "RotateRight" + vID, FormButtonType.CommandBarButton, PictureLib.FindNext, ButtonRepresentation.Picture, ItemHorizontalLocation.Right, 0);
	tcOnServer.cmCreateItem(ThisObject, vButtonGroup, "RotateRight" + vID, "FormButton", vStructure);
	
	tcOnServer.cmCreateItem(ThisObject, vCardGroup, "Photo" + vID, "FormField",
	New Structure("Type, DataPath, HorizontalStretch, PictureSize, Title, SetActionClick, Hyperlink, TitleLocation, Height, Width, VerticalStretch, HorizontalStretch, NonselectedPictureText",
	FormFieldType.PictureField, "Object.ScanPictures[" + vID + "].TempStorage", False, PictureSize.Proportionally, vID, "ClickPhoto", True, FormItemTitleLocation.None, 7, 0, False, True, ?(IsBlankString(vRow.Remarks), NStr("en='Click to scan'; ru='Нажмите для сканирования'; de='Klicken Sie zum Scannen'"), TrimAll(vRow.Remarks))));
	
	vButtonGroup = tcOnServer.cmCreateItem(ThisObject, vCardGroup, "ButtonGroup2" + vID, "FormGroup",
	New Structure("Type, ShowTitle, HorizontalStretch, Group",
	FormGroupType.UsualGroup, False, True, ChildFormItemsGroup.AlwaysHorizontal));
	
	vCommand = Commands.Add("LoadPicture" + vID);
	vCommand.Action = "LoadPictureClick";
	vStructure = New Structure("Title, CommandName, Type, Picture, Representation, HorizontalAlignInGroup, Width",
	NStr("en='Load'; ru='Загрузить'; de='Laden'"), "LoadPicture" + vID, FormButtonType.CommandBarButton, PictureLib.OpenFile, ButtonRepresentation.Picture, ItemHorizontalLocation.Left, 0);
	tcOnServer.cmCreateItem(ThisObject, vButtonGroup, "LoadPicture" + vID, "FormButton", vStructure);
	
	vCommand = Commands.Add("Copy" + vID);
	vCommand.Action = "CopyButtonClick";
	vStructure = New Structure("Title, CommandName, Type, Picture, Representation, HorizontalAlignInGroup, HorizontalStretch, Width",
	NStr("en='Copy'; ru='Копировать'; de='Kopieren'"), "Copy" + vID, FormButtonType.CommandBarButton, PictureLib.CreateListItem, ButtonRepresentation.Picture, ItemHorizontalLocation.Center, True, 0);
	tcOnServer.cmCreateItem(ThisObject, vButtonGroup, "Copy" + vID, "FormButton", vStructure);
	
	vCommand = Commands.Add("Delete" + vID);
	vCommand.Action = "DeleteButtonClick";
	vStructure = New Structure("Title, CommandName, Type, Picture, Representation, HorizontalAlignInGroup, Width",
	NStr("en='Delete'; ru='Удалить'; de='Löschen'"), "Delete" + vID, FormButtonType.CommandBarButton, PictureLib.Close, ButtonRepresentation.Picture, ItemHorizontalLocation.Right, 0);
	tcOnServer.cmCreateItem(ThisObject, vButtonGroup, "Delete" + vID, "FormButton", vStructure);
	
EndFunction //  CreateCard

// ----------------------------------------------------------------------------
&AtServerNoContext
Function GetClientDataScanDocument(pDocRef)
	// Run query to check whether client data scans were already created
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	ClientDataScans.Ref AS Ref
	|FROM
	|	Document.ClientDataScans AS ClientDataScans
	|WHERE
	|	NOT ClientDataScans.DeletionMark
	|	AND ClientDataScans.ParentDoc = &qParentDoc
	|
	|ORDER BY
	|	ClientDataScans.Posted DESC,
	|	ClientDataScans.PointInTime DESC";
	vQry.SetParameter("qParentDoc", pDocRef);
	vDocs = vQry.Execute().Unload();
	If vDocs.Count() > 0 Then
		Return vDocs.Get(0).Ref;
	ElsIf ValueIsFilled(pDocRef.Guest) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT TOP 1
		|	ClientDataScans.Ref AS Ref
		|FROM
		|	Document.ClientDataScans AS ClientDataScans
		|WHERE
		|	NOT ClientDataScans.DeletionMark
		|	AND ClientDataScans.Guest = &qClient
		|
		|ORDER BY
		|	ClientDataScans.Posted DESC,
		|	ClientDataScans.PointInTime DESC";
		vQry.SetParameter("qClient", pDocRef.Guest);
		vDocs = vQry.Execute().Unload();
		If vDocs.Count() > 0 Then
			Return vDocs.Get(0).Ref;
		EndIf;
	EndIf;
	// Document not fount, create new
	objDoc = Documents.ClientDataScans.CreateDocument();
	objDoc.Fill(pDocRef);
	objDoc.ParentDoc = pDocRef;
	objDoc.Write(DocumentWriteMode.Posting);
	Return objDoc.Ref;
EndFunction //  GetClientDataScanDocument

// ----------------------------------------------------------------------------
//
// Parameters:
//  pItem	 - Items - Item
//  pID		 - Number	 - ID
//
&AtClient
Procedure AfterChoiceScanConfiguration(pItem, pID) Export 
	If pItem <> Undefined Then
		vRow = Object.ScanPictures.Get(pID);
		vRow.ScanConfiguration = pItem.Value; 
		CreatePhotoBar();
		ThisObject.Modified = True;
	EndIf;
EndProcedure //  AfterChoiceScanConfiguration

// ----------------------------------------------------------------------------
&AtServerNoContext
Function GetScanConfigurations(pIsForeigner)
	vScanConfigurationsList = New ValueList();
	
	// Fill list of allowed scan configurations
	vAllowedConfigurationsList = New ValueList();
	vWstn = SessionParameters.CurrentWorkstation;
	If ValueIsFilled(vWstn) And ValueIsFilled(vWstn.ImagesScannerConnectionParameters) Then
		For Each vScanConfigurationsRow In vWstn.ImagesScannerConnectionParameters.ScanConfigurations Do
			If ValueIsFilled(vScanConfigurationsRow.ScanConfiguration) Then
				If vAllowedConfigurationsList.FindByValue(vScanConfigurationsRow.ScanConfiguration) = Undefined Then
					vAllowedConfigurationsList.Add(vScanConfigurationsRow.ScanConfiguration);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	// Read configurations from the catalog
	vQuery = New Query();
	vQuery.Text = 
	"SELECT
	|	ScanConfigurations.Ref AS Ref
	|FROM
	|	Catalog.ScanConfigurations AS ScanConfigurations
	|WHERE
	|	NOT ScanConfigurations.DeletionMark
	|	AND ScanConfigurations.IsForeigner = &qIsForeigner
	|	AND (NOT &qAllowedScanConfigurationsListIsEmpty
	|				AND ScanConfigurations.Ref IN (&qAllowedScanConfigurationsList)
	|			OR &qAllowedScanConfigurationsListIsEmpty)
	|
	|ORDER BY
	|	ScanConfigurations.SortCode,
	|	ScanConfigurations.Code";
	vQuery.SetParameter("qIsForeigner", pIsForeigner);
	vQuery.SetParameter("qAllowedScanConfigurationsList", vAllowedConfigurationsList);
	vQuery.SetParameter("qAllowedScanConfigurationsListIsEmpty", ?(vAllowedConfigurationsList.Count() = 0, True, False));
	vResult = vQuery.Execute().Unload();
	For Each vRow In vResult Do
		vScanConfigurationsList.Add(vRow.Ref);	
	EndDo;
	
	Return vScanConfigurationsList;
EndFunction // GetScanConfigurations

// ----------------------------------------------------------------------------
&AtServerNoContext
Function GetClientCertificateKey(pClients, pCertificateNumber, pRegistrationDay)
	Return InformationRegisters.ClientCertificates.CreateRecordKey(New Structure("Guest, CertificateNumber, RegistrationDay", pClients, pCertificateNumber, pRegistrationDay));
EndFunction //  GetClientCertificateKey

// --------------------------------------------------------------------------------
//
// Parameters:
//  pResult	 - Boolean	 - Result
//  pParam	 - String	 - ID
//
&AtClient
Procedure LoadPictureAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		OpenFileDialogToChooseFile(pParam);
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='File system extension is being installing on your browser...'; ru='В браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"));
		BeginInstallFileSystemExtension(New NotifyDescription("LoadPictureFileSystemExtensionInstallCompleted", ThisObject, pParam));
	EndIf;
EndProcedure //  LoadPictureAttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
//
// Parameters:
//  pParam	 - String	 - ID 
//
&AtClient
Procedure LoadPictureFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadPictureInstallingFileSystemExtensionResult", ThisObject, pParam));
EndProcedure //  LoadPictureFileSystemExtensionInstallCompleted

// --------------------------------------------------------------------------------
//
// Parameters:
//  pResult	 - Boolean	 - Result
//  pParam	 - String	 - ID
//
&AtClient
Procedure LoadPictureInstallingFileSystemExtensionResult(pResult, pParam) Export 
	If pResult Then
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='В браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"));
		OpenFileDialogToChooseFile(pParam);
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"));
	EndIf;
EndProcedure //  LoadPictureInstallingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient 
Procedure OpenFileDialogToChooseFile(pParam)
	vFileOpen = New FileDialog(FileDialogMode.Open);
	vFileOpen.Filter = NStr("ru = 'Картинки (*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.pdf;*.ico;*.wmf;*.emf)|*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.pdf;*.ico;*.wmf;*.emf|" +
	"bmp (*.bmp;*.dib;*.rle)|*.bmp;*.dib;*.rle|" + 
	"JPEG (*.jpg;*.jpeg)|*.jpg;*.jpeg|" + 
	"TIFF (*.tif)|*.tif|" + 
	"GIF (*.gif)|*.gif|" + 
	"PNG (*.png)|*.png|" + 
	"PDF (*.pdf)|*.pdf|" + 
	"icon (*.ico)|*.ico|" + 
	"метафайл (*.wmf;*.emf)|*.wmf;*.emf|'; 
	|de = 'Картинки (*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.pdf;*.ico;*.wmf;*.emf)|*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.pdf;*.ico;*.wmf;*.emf|" +
	"bmp (*.bmp;*.dib;*.rle)|*.bmp;*.dib;*.rle|" + 
	"JPEG (*.jpg;*.jpeg)|*.jpg;*.jpeg|" + 
	"TIFF (*.tif)|*.tif|" + 
	"GIF (*.gif)|*.gif|" + 
	"PNG (*.png)|*.png|" + 
	"PDF (*.pdf)|*.pdf|" + 
	"icon (*.ico)|*.ico|" + 
	"метафайл (*.wmf;*.emf)|*.wmf;*.emf|'; 
	|en = 'Pictures (*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.pdf;*.ico;*.wmf;*.emf)|*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.pdf;*.ico;*.wmf;*.emf|" +
	"bmp (*.bmp;*.dib;*.rle)|*.bmp;*.dib;*.rle|" + 
	"JPEG (*.jpg;*.jpeg)|*.jpg;*.jpeg|" + 
	"TIFF (*.tif)|*.tif|" + 
	"GIF (*.gif)|*.gif|" + 
	"PNG (*.png)|*.png|" + 
	"PDF (*.pdf)|*.pdf|" + 
	"icon (*.ico)|*.ico|" + 
	"metafile (*.wmf;*.emf)|*.wmf;*.emf|'");
	vFileOpen.Multiselect = False;
	vFileOpen.Title = NStr("en='Load picture';ru='Загрузить картинку';de='Bild laden'");
	vFileOpen.Preview = True;
	vFileOpen.Show(New NotifyDescription("OpenFileDialogToChooseFileCompleted", ThisObject, pParam));
EndProcedure //  OpenFileDialogToChooseFile

// --------------------------------------------------------------------------------
//
// Parameters:
//  pFileArray	 - Array - File array
//  pParam		 - String	 - ID
//
&AtClient
Procedure OpenFileDialogToChooseFileCompleted(pFileArray, pParam) Export 	
	If ValueIsFilled(pFileArray) Then
		vFileAddressArray = new Array();
		vFileAddressArray.Add(new TransferableFileDescription(pFileArray[0], ""));
		BeginPuttingFiles(new NotifyDescription("AfterPuttingFilesCompletedRegion", ThisObject, pParam), vFileAddressArray, , False, UUID);
	EndIf;
EndProcedure //  OpenFileDialogToChooseFileCompleted

// ----------------------------------------------------------------------------
//
// Parameters:
//  pAddress		 - String	 - Address
//  pExtraOptions	 - String	 - ID
//
&AtClient
Procedure AfterPuttingFilesCompletedRegion(pAddress, pExtraOptions) Export 
	If pAddress <> Undefined Then
		Items["FormFieldPhoto" + pExtraOptions].NonselectedPictureText = pAddress[0].Name;
		vRow = Object.ScanPictures.Get(pExtraOptions);
		vRow.Remarks = TrimAll(pAddress[0].Name);
		If lower(Right(TrimAll(pAddress[0].Name), 3)) = "pdf" Then
			// Convert pdf file to png format
			vAddress = tcOnClientWorkWithFiles.ConvertPDFtoJPG(TrimAll(pAddress[0].FullName), UUID);
			If vAddress <> Undefined Then
				vRow.TempStorage = vAddress;
			Else
				tcCommonFunctionOnClientServer.UserMessage(NStr("en='Error converting pdf file to png picture!'; ru='Ошибка преобразования pdf файла в картинку!'; de='Fehler beim Konvertieren der PDF-Datei in ein Bild!'"));
			EndIf;
		Else
			vRow.TempStorage = pAddress[0].Location;
		EndIf;
		ThisObject.Modified = True;	
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("ru = 'Ошибка загрузки файла'; en = 'File upload error';  de = 'Fehler beim Hochladen der Datei'"));		
	EndIf;
EndProcedure //  AfterPuttingFilesCompletedRegion

// ----------------------------------------------------------------------------
&AtClient
Procedure ResetFieldRecognitionQuality(pField)
	For Each vItem In Object.RecognitionQuality Do
		If vItem.Field = pField.Name  Then
			Object.RecognitionQuality.Delete(Object.RecognitionQuality.IndexOf(vItem));
			Break;
		EndIf; 
	EndDo; 
	RefreshDisplay();
EndProcedure //  ResetFieldRecognitionQuality

// ----------------------------------------------------------------------------
&AtServer
Procedure CitizenshipOnChangeAtServer()
	If ValueIsFilled(Object.Hotel) Then
		If ValueIsFilled(Object.Citizenship) Then
			IsForeigner = Object.Hotel.Citizenship <> Object.Citizenship;
		Else
			IsForeigner = 0; //Home region
			Object.Citizenship = Object.Hotel.Citizenship;
		EndIf;
		ClearEmptyRow();
		FillScanConfigList();
		CreatePhotoBar();
	EndIf;
EndProcedure //  CitizenshipOnChangeAtServer

// ------------------------------------------------------------------------------------------------
&AtServerNoContext
Function CreateClientCertificateAtServer(pClients, pBarCodeData, rClientCertificateRef, pClientInfo) 
	vRegClientCertificates = InformationRegisters.ClientCertificates.CreateRecordManager();
	vRegClientCertificates.LinkToCertificate = TrimAll(pBarCodeData);
	vRegClientCertificates.Guest = pClients;
	vMessage = "";
	If Not InformationRegisters.ClientCertificates.UpdateCertificateData(vRegClientCertificates, vMessage) Then
		tcCommonFunctionOnClientServer.UserMessage(vMessage);
		Return False;
	EndIf;
	vClientCertificatesSelection = InformationRegisters.ClientCertificates.Select(New Structure("CertificateNumber", vRegClientCertificates.CertificateNumber));
	If vClientCertificatesSelection.Next() And vClientCertificatesSelection.Guest <> pClients Then
		vMsgError = "";
		If CheckClientCertificate(pClients, vClientCertificatesSelection, vMsgError, pClientInfo) Then
			vClientCertificatesSelection.GetRecordManager().Delete();		
		Else
			rClientCertificateRef = InformationRegisters.ClientCertificates.CreateRecordKey(New Structure("Guest, CertificateNumber, RegistrationDay", vClientCertificatesSelection.Guest, vClientCertificatesSelection.CertificateNumber, vClientCertificatesSelection.RegistrationDay));
			Return False;
		EndIf;
	EndIf;
	vRegClientCertificates.Write(True);
	rClientCertificateRef = InformationRegisters.ClientCertificates.CreateRecordKey(New Structure("Guest, CertificateNumber, RegistrationDay", pClients, vRegClientCertificates.CertificateNumber, vRegClientCertificates.RegistrationDay));
	Return True;
EndFunction //  CreateClientCertificateAtServer

// ------------------------------------------------------------------------------------------------
&AtServerNoContext
Function CheckClientCertificate(pClients, pClientCertificates, rMsgError, pClientInfo)                 
	vResult = True;
	If Not CheckFullName(pClients, pClientCertificates.FullName) And Not CheckFullName(pClientCertificates.Guest, pClientInfo.LastName + " " + pClientInfo.FirstName + " " + pClientInfo.SecondName) Then
		vResult = False;
		rMsgError = NStr("en = ' - The full name of the guest does not match.'; de = ' - Der vollständige Name des Gastes stimmt nicht überein.'; ru = ' - Не совпадает ФИО гостя.'");
	ElsIf pClientCertificates.DateOfBirth <> pClients.DateOfBirth And pClientCertificates.DateOfBirth <> pClientInfo.DateOfBirth Then	
		vResult = False;
		rMsgError = NStr("en = ' - The date of birth of the guest does not match.'; de = ' - Das Geburtsdatum des Gastes stimmt nicht überein.'; ru = ' - Не совпадает дата рождения гостя.'");
	ElsIf pClientCertificates.ValidToDate <= CurrentSessionDate() Then 	
		vResult =  False;
		rMsgError = NStr("en = ' - The certificate has expired.'; de = ' - Das Zertifikat ist abgelaufen.'; ru = ' - Срок действия сертификата истек.'");
	EndIf;	
	Return vResult;
EndFunction //  CheckClientCertificate

// ------------------------------------------------------------------------------------------------
//
// Parameters:
//  pResult		 - Boolean	 - Result
//  pExtraParams - Null		 - Extra params
//
&AtClient
Procedure AfterChangeCardOwner(pResult, pExtraParams) Export 
	If pResult <> Undefined And pResult Then
		CreatePhotoBar();	
	EndIf;
EndProcedure //  AfterChangeCardOwner

// ------------------------------------------------------------------------------------------------
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

// ----------------------------------------------------------------------------
&AtServer
Procedure EditTopGroupHeader()
	If ValueIsFilled(Object.Guest) Then
		Items.GroupTop.Title = "" + Object.Status + ", " + Object.Guest.FullName + ", " + Nstr("en = 'Room: '; de = 'Zimmernummer: '; ru = 'Номер: '") + Object.Room + ", " + NStr("en = 'Group: '; de = 'Gruppe: '; ru = 'Группа: '") + Object.GuestGroup;
	Else
		Items.GroupTop.Title = "" + Object.Status + ", " + Object.FirstName + ", " + Nstr("en = 'Room: '; de = 'Zimmernummer: '; ru = 'Номер: '") + Object.Room + ", " + NStr("en = 'Group: '; de = 'Gruppe: '; ru = 'Группа: '") + Object.GuestGroup;
	EndIf;
	If Object.Status = Enums.ScanStatuses.IsProcessed Then
		Items.FormPost.Enabled = False;
	Else
		Items.FormPost.Enabled = True;
	EndIf;
EndProcedure //  EditTopGroupHeader

// ----------------------------------------------------------------------------
&AtServer
Procedure RefreshDisplay()
	CtrlBackColor = Items.Number.BackColor;
	vObg = FormAttributeToValue("Object");
	// Reset fields background
	For Each vAttr In vObg.Metadata().Attributes Do
		If Not Items.Find(vAttr.Name) = Undefined And vAttr.Name <> "Photo" And vAttr.Name <> "Signature" Then
			Items[vAttr.Name].BackColor = CtrlBackColor;
		EndIf;
	EndDo;
	
	For Each vRQRow In Object.RecognitionQuality Do
		If Not IsBlankString(vRQRow.Field) Then
			If vRQRow.Field <> "Photo" And vRQRow.Field <> "Signature" Then
				If vRQRow.Quality = 999 Then
					Items[Title(vRQRow.Field)].BackColor = WEBColors.LightCyan;
				ElsIf vRQRow.Quality < 80 And vRQRow.Quality >= 70 Then
					Items[Title(vRQRow.Field)].BackColor = WEBColors.LightGoldenrod; 
				ElsIf vRQRow.Quality < 70 Then
					Items[Title(vRQRow.Field)].BackColor = WEBColors.LightSalmon;	
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	If ValueIsFilled(Object.Guest) Or ValueIsFilled(Object.ParentDoc) Then
		vUUID = "1";
		If ValueIsFilled(Object.ParentDoc) Then
			vUUID = String(Object.ParentDoc.UUID());
		ElsIf ValueIsFilled(Object.Guest) Then
			vUUID = String(Object.Guest.UUID());
		EndIf;
		ThisObject["Photo" + StrReplace(vUUID, "-", "_")] = Photo;
	EndIf;	
EndProcedure // RefreshDisplay

// ----------------------------------------------------------------------------
&AtServerNoContext
Function GetEmptyOutputParameters()
	vOutParams = New Structure;
	vOutParams.Insert("LastName"				,"");
	vOutParams.Insert("FirstName"				,"");
	vOutParams.Insert("SecondName"				,"");
	vOutParams.Insert("Sex"						,Undefined);
	vOutParams.Insert("DateOfBirth"				,'00010101');
	vOutParams.Insert("PlaceOfBirth"			,"");
	vOutParams.Insert("IdentityDocumentType"	,Undefined);
	vOutParams.Insert("IdentityDocumentSeries"	,"");
	vOutParams.Insert("IdentityDocumentNumber"	,"");
	vOutParams.Insert("IdentityDocumentUnitCode","");
	vOutParams.Insert("IdentityDocumentIssuedBy","");
	vOutParams.Insert("IdentityDocumentIssueDate",'00010101');
	vOutParams.Insert("IdentityDocumentValidToDate",'00010101');
	vOutParams.Insert("Photo"					,"");
	vOutParams.Insert("Signature"				,"");
	vOutParams.Insert("Citizenship"				,Catalogs.Countries.EmptyRef());
	vOutParams.Insert("IdentityDocumentPicture"	,"");
	vOutParams.Insert("RussianPassportType"		,Catalogs.IdentityDocumentTypes.FindByCode("21"));
	vOutParams.Insert("RecognitionQuality"		,New Structure());
	vOutParams.Insert("FillAllItems"			,False);
	
	Return vOutParams;                                             
EndFunction //  GetEmptyOutputParameters

// ----------------------------------------------------------------------------
&AtServer
Function Vision(pScanConfig)
	If ValueIsFilled(pScanConfig) Then
		If TrimAll(pScanConfig.IdentityDocumentType.Code) = "21" Then
			Items.GroupIdentityData.Show();
			Items.GroupAdditionalData.Hide();
			Items.GroupMigrationCard.Hide();
			Items.GroupResidencePermitDocument.Hide();
			Items.GroupExtraDocument.Hide();
		ElsIf pScanConfig.IsMigrationCard Then
			Items.GroupIdentityData.Hide(); 
			Items.GroupAdditionalData.Hide();
			Items.GroupMigrationCard.Show();
			Items.GroupResidencePermitDocument.Hide();
			Items.GroupExtraDocument.Hide();
		ElsIf pScanConfig.IsVisa Then
			Items.GroupIdentityData.Hide();
			Items.GroupAdditionalData.Hide();
			Items.GroupMigrationCard.Show();
			Items.GroupResidencePermitDocument.Show();
			Items.GroupExtraDocument.Hide();			
		ElsIf pScanConfig.IsFanId Then	
			Items.GroupIdentityData.Hide();
			Items.GroupAdditionalData.Hide();
			Items.GroupMigrationCard.Show();
			Items.GroupResidencePermitDocument.Hide();
			Items.GroupExtraDocument.Show();
		Else
			Items.GroupIdentityData.Show();
			Items.GroupAdditionalData.Show();
			Items.GroupMigrationCard.Show();
			Items.GroupResidencePermitDocument.Show();
			Items.GroupExtraDocument.Show();	
		EndIf;
	EndIf;
EndFunction //  Vision

// ----------------------------------------------------------------------------
// 
// Returns:
//  ValueTable - Limits and special condition types 
//
&AtServer
Function GetLimitsAndConditions() Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	NestedSelect.Owner,
	|	NestedSelect.Hotel,
	|	LimitsAndSpecialConditionTypes.Ref AS Characteristic,
	|	NestedSelect.CharacteristicValue
	|FROM
	|	ChartOfCharacteristicTypes.LimitsAndSpecialConditionTypes AS LimitsAndSpecialConditionTypes
	|		LEFT JOIN (SELECT
	|			LimitsAndSpecialConditions.Owner AS Owner,
	|			LimitsAndSpecialConditions.Hotel AS Hotel,
	|			LimitsAndSpecialConditions.Characteristic AS Characteristic,
	|			LimitsAndSpecialConditions.CharacteristicValue AS CharacteristicValue
	|		FROM
	|			InformationRegister.LimitsAndSpecialConditions AS LimitsAndSpecialConditions
	|		WHERE
	|			LimitsAndSpecialConditions.Owner = &qClient
	|			AND NOT LimitsAndSpecialConditions.Characteristic.DeletionMark) AS NestedSelect
	|		ON LimitsAndSpecialConditionTypes.Ref = NestedSelect.Characteristic
	|WHERE
	|	NOT LimitsAndSpecialConditionTypes.DeletionMark";
	vQry.SetParameter("qClient", Object.Guest);
	vChars = vQry.Execute().Unload();
	Return vChars;
EndFunction //  GetLimitsAndConditions

// ----------------------------------------------------------------------------
&AtServer
Procedure FillExtraData()
	Characteristics.Load(GetLimitsAndConditions());		
	For Each Characteristic In Characteristics Do  
		vID = Characteristic.GetID();
		vFild = tcOnServer.cmCreateItem(ThisObject, Items.GroupExtraDocument, "Characteristic" + vID, "FormField",
		New Structure("Type,DataPath,Title,TypeRestriction",
		FormFieldType.InputField,"Characteristics[" + vID + "].CharacteristicValue",Characteristic.Characteristic,Characteristic.Characteristic.ValueType));
	EndDo;
EndProcedure //  FillExtraData

// ----------------------------------------------------------------------------
&AtServer
Procedure IsForeignerOnChangeAtServer()
	If IsForeigner = 0 And ValueIsFilled(Object.Hotel) Then
		Object.Citizenship = Object.Hotel.Citizenship;
	ElsIf Not ValueIsFilled(Object.Citizenship) Or IsForeigner = 2 Or ValueIsFilled(Object.Guest) And Not ValueIsFilled(Object.Guest.Citizenship) And IsForeigner = 1 Then
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='Fill out citizenship!'; ru='Заполните гражданство!'; de='Staatsbürgerschaft ausfüllen!'"), Object.Citizenship, "Object.Citizenship",, True);
		Object.Citizenship = Undefined;
	ElsIf ValueIsFilled(Object.Guest) Then
		Object.Citizenship = Object.Guest.Citizenship;
	EndIf;
	ClearEmptyRow();
	FillScanConfigList();
	CreatePhotoBar(); 
	FillScanConfigurationsData();
EndProcedure //  IsForeignerOnChangeAtServer 

// ----------------------------------------------------------------------------
&AtServer
Procedure ClearAtServer()
	Object.RecognitionQuality.Clear();
	ClearPhotoAtServer();
	ClearSignatureAtServer();
	vEmptyDoc = Documents.ClientDataScans.CreateDocument();
	FillPropertyValues(Object, vEmptyDoc, , "Number, Date, Author, Hotel, Status, ParentDoc, GuestGroup, Guest, Room, Remarks, ScanPictures, RecognitionQuality"); 
	FillScanConfigList();
	CreatePhotoBar(); 
	FillExtraData();
	RefreshDisplay();
	Modified = True;
EndProcedure //  ClearAtServer

// ----------------------------------------------------------------------------
&AtClient
Function CheckClient()
	If ValueIsFilled(Object.Guest) And Not ValueIsFilled(DuplicatesCheckedClient) Then
		vGuestAttrs = tcOnServer.cmGetAtributeAsArray(Object.Guest);
		If Lower(TrimAll(Object.LastName)) <> Lower(TrimAll(vGuestAttrs.LastName)) Or
			Lower(TrimAll(Object.FirstName)) <> Lower(TrimAll(vGuestAttrs.FirstName)) Or
			Lower(TrimAll(Object.SecondName)) <> Lower(TrimAll(vGuestAttrs.SecondName)) Or
			Object.DateOfBirth <> vGuestAttrs.DateOfBirth Or
			Lower(TrimAll(Object.IdentityDocumentSeries)) <> Lower(TrimAll(vGuestAttrs.IdentityDocumentSeries)) Or
			Lower(TrimAll(Object.IdentityDocumentNumber)) <> Lower(TrimAll(vGuestAttrs.IdentityDocumentNumber)) Or
			Object.IdentityDocumentIssueDate <> vGuestAttrs.IdentityDocumentIssueDate Then
			vSameClientsByIDQuantity = 0;
			vSameClientsByNameQuantity = CheckClientDuplicatesByName(Object.LastName, Object.FirstName, Object.SecondName, Object.DateOfBirth, Object.Guest);
			If vSameClientsByNameQuantity = 0 Then
				vSameClientsByIDQuantity = CheckClientDuplicatesByID(Object.IdentityDocumentSeries, Object.IdentityDocumentNumber, Object.IdentityDocumentIssueDate, Object.Guest);
			EndIf;
			If vSameClientsByNameQuantity > 0 Then
				DuplicatesCheckedClient = Object.Guest;
				vMessage = NStr("en='" + Format(vSameClientsByNameQuantity, "ND=6; NFD=0; NZ=") + " client(s) found with the same name and birth date!
				|It is recommended to use one of those clients. Please choose existing client from the table that will be shown soon...'; 
				|de='" + Format(vSameClientsByNameQuantity, "ND=6; NFD=0; NZ=") + " Kunde(n) mit den gleichen Name und Geburtsdatum gefunden!
				|Es wird empfohlen, einen dieser Clients zu verwenden. Bitte wählen Sie einen bestehenden Kunden aus der Tabelle aus, die in Kürze angezeigt wird...'; 
				|ru='В базе данных найдено " + Format(vSameClientsByNameQuantity, "ND=6; NFD=0; NZ=") + " клиент(ов) с совпадающими именами и датой рождения!
				|Рекомендуется выбрать одного из таких клиентов из таблицы, которая будет сейчас показана на экране...'");
				ShowMessageBox(New NotifyDescription("OpenClientsListFilteringByName", ThisObject), vMessage);
				Return False;
			EndIf;
			If vSameClientsByIDQuantity > 0 Then
				DuplicatesCheckedClient = Object.Guest;
				vMessage = NStr("en='" + Format(vSameClientsByIDQuantity, "ND=6; NFD=0; NZ=") + " client(s) found with the same passport data!
				|It is recommended to use one of those clients. Please choose existing client from the table that will be shown soon...'; 
				|de='" + Format(vSameClientsByIDQuantity, "ND=6; NFD=0; NZ=") + " Kunde(n) mit den gleichen Passdaten gefunden!
				|Es wird empfohlen, einen dieser Clients zu verwenden. Bitte wählen Sie einen bestehenden Kunden aus der Tabelle aus, die in Kürze angezeigt wird...'; 
				|ru='В базе данных найдено " + Format(vSameClientsByIDQuantity, "ND=6; NFD=0; NZ=") + " клиент(ов) с совпадающими данными документа удостоверяющего личность!
				|Рекомендуется выбрать одного из таких клиентов из таблицы, которая будет сейчас показана на экране...'");
				ShowMessageBox(New NotifyDescription("OpenClientsListFilteringByID", ThisObject), vMessage);
				Return False;
			EndIf;
		EndIf;
	EndIf;
	Return True;
EndFunction //  CheckClient

// ----------------------------------------------------------------------------
//
// Parameters:
//  pExtraParams - Null - Extra params 
//
&AtClient
Procedure OpenClientsListFilteringByName(pExtraParams) Export
	OpenForm("Catalog.Clients.Form.tcListForm", 
	New Structure("ChoiceMode, Hotel, SelLastName, SelFirstName, SelSecondName, SelDateOfBirth", True, Object.Hotel, TrimAll(Object.LastName), TrimAll(Object.FirstName), TrimAll(Object.SecondName), Object.DateOfBirth), 
	ThisObject,
	UUID, , , 
	New NotifyDescription("ContinuePost", ThisObject), 
	FormWindowOpeningMode.LockOwnerWindow);
EndProcedure //  OpenClientsListFilteringByName

// ----------------------------------------------------------------------------
//
// Parameters:
//  pExtraParams - Null - Extra params 
//
&AtClient
Procedure OpenClientsListFilteringByID(pExtraParams) Export
	OpenForm("Catalog.Clients.Form.tcListForm", 
	New Structure("ChoiceMode, Hotel, SelSelIdentityDocumentNumber, SelIdentityDocumentSeries, SelIdentityDocumentIssueDate", True, Object.Hotel, Object.IdentityDocumentNumber, Object.IdentityDocumentSeries, Object.IdentityDocumentIssueDate), 
	ThisObject,
	UUID, , , 
	New NotifyDescription("ContinuePost", ThisObject), 
	FormWindowOpeningMode.LockOwnerWindow);
EndProcedure //  OpenClientsListFilteringByID

// ----------------------------------------------------------------------------
//
// Parameters:
//  pResult		 - CatalogRef.Clients	 - Client
//  pExtraParams - Null					 - Extra params
//
&AtClient
Procedure ContinuePost(pResult, pExtraParams = Undefined) Export
	Object.Status = PredefinedValue("Enum.ScanStatuses.IsProcessed");
	Object.RecognitionQuality.Clear();
	
	If ValueIsFilled(pResult) Then
		Object.Guest = pResult;
	EndIf;
	
	If Write(New Structure("WriteMode",DocumentWriteMode.Posting)) Then
		If ValueIsFilled(Object.ParentDoc) Then
			If TypeOf(Object.ParentDoc) = Type("DocumentRef.Accommodation") Then
				Notify("Document.Accommodation.Write", Object.ParentDoc, ThisObject);
				vReservation = tcOnServer.cmGetAttributeByRef(Object.ParentDoc, "Reservation");
				If ValueIsFilled(vReservation) Then
					Notify("Document.Reservation.Write", vReservation, ThisObject);
				EndIf;
			ElsIf TypeOf(Object.ParentDoc) = Type("DocumentRef.Reservation") Then
				Notify("Document.Reservation.Write", Object.ParentDoc, ThisObject);
			EndIf;	
		EndIf;
		Close();   
	EndIf;
EndProcedure //  ContinuePost

//  ----------------------------------------------------------------------------
//
// Parameters:
//  pLastName		 - String - Last name 
//  pFirstName		 - String - First name 
//  pSecondName		 - String - Second name 
//  pDateOfBirth	 - Date - Date of birth 
//  pClientToSkip	 - CatalogRef.Clients - Clients 
// 
// Returns:
//  Number - Client duplicates
//
&AtServerNoContext
Function CheckClientDuplicatesByName(pLastName, pFirstName, pSecondName, pDateOfBirth, pClientToSkip) Export
	If IsBlankString(pLastName) Then
		Return 0;
	EndIf; 
	
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Clients.Ref AS Ref
	|FROM
	|	Catalog.Clients AS Clients
	|WHERE
	|	Clients.LastName = &qLastName
	|	AND Clients.FirstName = &qFirstName
	|	AND Clients.SecondName = &qSecondName
	|	AND Clients.DateOfBirth = &qDateOfBirth
	|	AND Clients.Ref <> &qClient
	|	AND NOT Clients.DeletionMark
	|	AND NOT Clients.IsFolder
	|
	|ORDER BY
	|	Clients.FullName,
	|	Clients.Code";
	vQry.SetParameter("qLastName", TrimAll(pLastName));
	vQry.SetParameter("qFirstName", TrimAll(pFirstName));
	vQry.SetParameter("qSecondName", TrimAll(pSecondName));
	vQry.SetParameter("qDateOfBirth", pDateOfBirth);
	vQry.SetParameter("qClient", pClientToSkip);
	vQryRes = vQry.Execute().Select();
	Return vQryRes.Count();
EndFunction //  CheckClientDuplicatesByName

// ----------------------------------------------------------------------------
//
// Parameters:
//  pIDSeries		 - String			 - Identity document series
//  pIDNumber		 - String			 - Identity document number
//  pIDIssueDate	 - Date				 - Identity document date
//  pClientToSkip	 - CatalogRef.Clients	 - Clients
// 
// Returns:
//  Number - Client duplicates
//
&AtServerNoContext
Function CheckClientDuplicatesByID(pIDSeries, pIDNumber, pIDIssueDate, pClientToSkip) Export
	If IsBlankString(pIDNumber) Then
		Return 0;
	EndIf; 
	
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Clients.Ref AS Ref
	|FROM
	|	Catalog.Clients AS Clients
	|WHERE
	|	Clients.IdentityDocumentNumber = &qIDNumber
	|	AND Clients.IdentityDocumentSeries = &qIDSeries
	|	AND Clients.IdentityDocumentIssueDate = &qIDIssueDate
	|	AND Clients.Ref <> &qClient
	|	AND NOT Clients.DeletionMark
	|	AND NOT Clients.IsFolder
	|
	|ORDER BY
	|	Clients.FullName,
	|	Clients.Code";
	vQry.SetParameter("qIDNumber", TrimAll(pIDNumber));
	vQry.SetParameter("qIDSeries", TrimAll(pIDSeries));
	vQry.SetParameter("qIDIssueDate", pIDIssueDate);
	vQry.SetParameter("qClient", pClientToSkip);
	vQryRes = vQry.Execute().Select();
	Return vQryRes.Count();
EndFunction //  CheckClientDuplicatesByID

// ----------------------------------------------------------------------------
//
// Parameters:
//  pValue					 - String	 - Identity document issued by
//  pAdditionalParameters	 - Null		 - Extra params
//
&AtClient
Procedure IdentityDocumentIssuedByIsChoosen(pValue, pAdditionalParameters) Export
	If pValue <> Undefined Then
		Object.IdentityDocumentIssuedBy = pValue.Value;
		vPresentation = pValue.Presentation;
		If Left(vPresentation, StrLen(TrimAll(Object.IdentityDocumentUnitCode))) = TrimAll(Object.IdentityDocumentUnitCode) Then
			Object.IdentityDocumentUnitCode = Left(vPresentation, 7);
		EndIf;
	EndIf;
EndProcedure //  IdentityDocumentIssuedByIsChoosen

// ----------------------------------------------------------------------------
&AtServer
Function GetIssuedByListAtServer(pText, pIsUnitCode = True)
	vIssuedByList = New ValueList();
	If ValueIsFilled(Object.IdentityDocumentType) And TrimAll(Object.IdentityDocumentType.Code) = "21" Then
		If StrLen(TrimAll(pText)) < 3 Then
			Return vIssuedByList;
		EndIf;
		If pIsUnitCode Then
			vQryRes = cmGetFMSRecord(TrimAll(pText), True, , 15).Select();
		Else
			vQryRes = cmGetFMSRecord(TrimAll(pText), False).Select();
		EndIf;
	Else
		If StrLen(TrimAll(pText)) < 5 Then
			Return vIssuedByList;
		EndIf;
		If pIsUnitCode Then
			vQryRes = cmGetIssuedByRecord(TrimAll(pText), True).Select();
		Else
			vQryRes = cmGetIssuedByRecord(TrimAll(pText), False).Select();
		EndIf;
	EndIf;
	While vQryRes.Next() Do
		vIssuedByList.Add(TrimAll(vQryRes.Description), TrimAll(?(IsBlankString(vQryRes.Code), "", TrimAll(vQryRes.Code) + ", ") + TrimAll(vQryRes.Description)));
	EndDo;
	Return vIssuedByList;
EndFunction //  GetIssuedByListAtServer

// ----------------------------------------------------------------------------
&AtServer
Procedure ResidencePermitDocumentOnChangeAtServer()
	If Object.ResidencePermitDocument = Enums.ConfirmingDocuments.WithoutVisa Then
		Items.GroupNoVisum.Visible = True;
		Items.GroupVisum.Visible = False;
		Items.GroupTempResidencePermit.Visible = False;
		Items.GroupPermanentResidencePermit.Visible = False;
		// Clear all visa fields
		Object.VisaDays = 0;
		Object.VisaEntryGoal = Undefined;
		Object.VisaFromDate = '00010101';
		Object.VisaIdentifier = "";
		Object.VisaIssuedBy = "";
		Object.VisaIssuedDate = '00010101';
		Object.VisaMultiplicity = Undefined;
		Object.VisaNumber = "";
		Object.VisaToDate = '00010101';
		Object.VisaType = Undefined;
		Object.ForEducationPurposes = False;
	ElsIf Object.ResidencePermitDocument = Enums.ConfirmingDocuments.Visa Or Object.ResidencePermitDocument = Enums.ConfirmingDocuments.ElectronicVisa Then
		Items.GroupNoVisum.Visible = False;
		Items.GroupVisum.Visible = True;
		Items.GroupTempResidencePermit.Visible = False;
		Items.GroupPermanentResidencePermit.Visible = False;
		// Clear fields that are not from Visa
		Object.ForEducationPurposes = False;
	ElsIf Object.ResidencePermitDocument = Enums.ConfirmingDocuments.TempResidencePermit Then
		Items.GroupNoVisum.Visible = False;
		Items.GroupVisum.Visible = False;
		Items.GroupTempResidencePermit.Visible = True;
		Items.GroupPermanentResidencePermit.Visible = False;
		// Clear fields that are not from TRP
		Object.VisaDays = 0;
		Object.VisaEntryGoal = Undefined;
		Object.VisaFromDate = '00010101';
		Object.VisaMultiplicity = Undefined;
		Object.VisaNumber = "";
		Object.VisaType = Undefined;
	ElsIf Object.ResidencePermitDocument = Enums.ConfirmingDocuments.PermResidencePermit Then
		Items.GroupNoVisum.Visible = False;
		Items.GroupVisum.Visible = False;
		Items.GroupTempResidencePermit.Visible = False;
		Items.GroupPermanentResidencePermit.Visible = True;
		// Clear fields that are not from RPD
		Object.VisaDays = 0;
		Object.VisaEntryGoal = Undefined;
		Object.VisaMultiplicity = Undefined;
		Object.VisaType = Undefined;
		Object.ForEducationPurposes = False;
	EndIf;
EndProcedure //  ResidencePermitDocumentOnChangeAtServer

// ----------------------------------------------------------------------------
&AtServer
Procedure VisaTypeOnChangeAtServer()
	If ValueIsFilled(Object.VisaType) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	EntryGoals.Ref
		|FROM
		|	Catalog.EntryGoals AS EntryGoals
		|WHERE
		|	NOT EntryGoals.DeletionMark
		|	AND (EntryGoals.VisaType = &qVisaType
		|			OR EntryGoals.VisaType = &qEmptyVisaType)
		|
		|ORDER BY
		|	EntryGoals.Code";
		vQry.SetParameter("qVisaType", Object.VisaType);
		vQry.SetParameter("qEmptyVisaType", Catalogs.VisaTypes.EmptyRef());
		vEntryGoals = vQry.Execute().Unload();
		Items.VisaEntryGoal.ChoiceList.LoadValues(vEntryGoals.UnloadColumn("Ref"));
	Else
		Items.VisaEntryGoal.ChoiceList.Clear();
	EndIf;
EndProcedure //  VisaTypeOnChangeAtServer

// ----------------------------------------------------------------------------
&AtServer
Procedure FillScanConfigurationsData()
	
	ScanConfigurationsData.Clear();
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	ScanConfigurations.Ref AS Ref,
	|	ScanConfigurations.RecognitionIsAvailable AS RecognitionIsAvailable,
	|	ScanConfigurations.LanguageID AS LanguageID,
	|	ScanConfigurations.ExternalNames.(
	|		ExternalName AS ExternalName
	|	) AS ExternalNames,
	|	ScanConfigurations.IdentityDocumentType AS IdentityDocumentType,
	|	ScanConfigurations.IsForeigner AS IsForeigner
	|FROM
	|	Catalog.ScanConfigurations AS ScanConfigurations
	|WHERE
	|	ScanConfigurations.Ref IN(&qScanConfigurations)";
	
	vQuery.SetParameter("qScanConfigurations", Object.ScanPictures.Unload(, "ScanConfiguration"));
	vResultTable = vQuery.Execute().Unload();
	For each vRow in vResultTable Do
		vNewRow = ScanConfigurationsData.Add();
		FillPropertyValues(vNewRow, vRow, , "ExternalNames");
		For each vExternalName in vRow.ExternalNames Do
			vNewExternalName = vNewRow.ExternalNames.Add();	
			FillPropertyValues(vNewExternalName, vExternalName);
		EndDo;
	EndDo;
	
EndProcedure //  FillScanConfigurationsData

// ----------------------------------------------------------------------------
&AtClient
Procedure DisconnectDevice(pFull = False)
	If amImageScannerInstance <> Undefined Then
		If amImageScanner = tcRegula And Not pFull Then
			RemoveHandler amImageScannerInstance.OnProcessingFinished, Reader_OnProcessingFinished;
		ElsIf amImageScanner = tcScan1C And Not pFull Then
			amImageScanner.pmDisconnect(amImageScannerInstance);
		ElsIf amImageScanner <> tcPassportReaderImageScannerDriver Or pFull Then
			If amImageScanner = tcRegula Then
				RemoveHandler amImageScannerInstance.OnProcessingFinished, Reader_OnProcessingFinished;
			EndIf;
			amImageScanner.pmDisconnect(amImageScannerInstance);
			amImageScanner = Undefined;
		EndIf;
	EndIf;
EndProcedure // DisconnectDevice

// ----------------------------------------------------------------------------
&AtServerNoContext
Function GetCountryByCode(pCountryCode)
	Return cmGetCountryByCode(pCountryCode);
EndFunction //  GetCountryByCode

// ----------------------------------------------------------------------------
&AtServer
Procedure PrintClientScansAtServer(pSpreadsheet)
	vTemplate = Documents.ClientDataScans.GetTemplate("PicturePrintTemplate");
	vObj = FormAttributeToValue("Object");
	For Each vCurRow In vObj.ScanPictures Do
		vPicture = vCurRow.ScanPicture.Get();
		If vPicture = Undefined Then
			Continue;
		ElsIf TypeOf(vPicture) = Type("String") Then
			vPicture = New Picture(vObj.pmGetImageCatalogName(vCurRow) + TrimAll(vPicture));
		EndIf;
		If vObj.ScanPictures.IndexOf(vCurRow) > 0 Then
			pSpreadsheet.PutHorizontalPageBreak();
		EndIf;
		// Put picture there
		vPictureArea = vTemplate.GetArea("Picture");
		vPictureArea.Drawings.ScanPicture.Print = True;
		vPictureArea.Drawings.ScanPicture.Picture = vPicture;
		pSpreadsheet.Put(vPictureArea);
	EndDo;
	pSpreadsheet.ShowGrid = False;
	pSpreadsheet.ShowHeaders = False;
EndProcedure //  PrintClientScansAtServer

// ----------------------------------------------------------------------------
&AtServer
Function GetDataProcessorForExportGuestDataToUFMS()
	Return cmGetDataProcessorForExportGuestDataToUFMS(Object.Hotel);
EndFunction //  GetDataProcessorForExportGuestDataToUFMS

// ----------------------------------------------------------------------------------
&AtClient
Procedure FillAddresDadata(Val pText, pList)
	If StrLen(pText) >= 4 Then
		pList = GetAddressFromDadata(pText);
	EndIf;
EndProcedure //  FillAddresDadata

// ----------------------------------------------------------------------------------
&AtServerNoContext
Function GetAddressFromDadata(pText)
	Return cmGetDataFromDadata(TrimAll(pText));
EndFunction //  GetAddressFromDadata	

// ----------------------------------------------------------------------------
//
// Parameters:
//  pResult	 - Boolean	 - Result
//  pParam	 - Null		 - Extra params
//
&AtClient
Procedure LoadPhotoFromFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		OpenPhotoFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='File system extension is being installing on your browser...'; ru='В браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"));
		BeginInstallFileSystemExtension(New NotifyDescription("LoadPhotoFromFileFileSystemExtensionInstallCompleted", ThisObject));
	EndIf;
EndProcedure //  LoadPhotoFromFileAttachingFileSystemExtensionResult

// ----------------------------------------------------------------------------
//
// Parameters:
//  pParam	 - Null	 - Extra params 
//
&AtClient
Procedure LoadPhotoFromFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadPhotoFromFileInstallingFileSystemExtensionResult", ThisObject));
EndProcedure //  LoadPhotoFromFileFileSystemExtensionInstallCompleted

// ----------------------------------------------------------------------------
//
// Parameters:
//  pResult	 - Boolean	 - Result
//  pParam	 - Null		 - Extra params
//
&AtClient
Procedure LoadPhotoFromFileInstallingFileSystemExtensionResult(pResult, pParam) Export 
	If pResult Then
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='В браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"));
		OpenPhotoFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"));
	EndIf;
EndProcedure //  LoadPhotoFromFileInstallingFileSystemExtensionResult

// ----------------------------------------------------------------------------
&AtClient 
Procedure OpenPhotoFileDialogToChooseFile()
	vFileOpen = New FileDialog(FileDialogMode.Open);
	vFileOpen.FullFileName = "";
	vFileOpen.Filter = NStr("ru = 'Картинки (*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf)|*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf|" +
	"bmp (*.bmp;*.dib;*.rle)|*.bmp;*.dib;*.rle|" + 
	"JPEG (*.jpg;*.jpeg)|*.jpg;*.jpeg|" + 
	"TIFF (*.tif)|*.tif|" + 
	"GIF (*.gif)|*.gif|" + 
	"PNG (*.png)|*.png|" + 
	"icon (*.ico)|*.ico|" + 
	"метафайл (*.wmf;*.emf)|*.wmf;*.emf|'; 
	|de = 'Картинки (*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf)|*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf|" +
	"bmp (*.bmp;*.dib;*.rle)|*.bmp;*.dib;*.rle|" + 
	"JPEG (*.jpg;*.jpeg)|*.jpg;*.jpeg|" + 
	"TIFF (*.tif)|*.tif|" + 
	"GIF (*.gif)|*.gif|" + 
	"PNG (*.png)|*.png|" + 
	"icon (*.ico)|*.ico|" + 
	"метафайл (*.wmf;*.emf)|*.wmf;*.emf|'; 
	|en = 'Pictures (*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf)|*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf|" +
	"bmp (*.bmp;*.dib;*.rle)|*.bmp;*.dib;*.rle|" + 
	"JPEG (*.jpg;*.jpeg)|*.jpg;*.jpeg|" + 
	"TIFF (*.tif)|*.tif|" + 
	"GIF (*.gif)|*.gif|" + 
	"PNG (*.png)|*.png|" + 
	"icon (*.ico)|*.ico|" + 
	"metafile (*.wmf;*.emf)|*.wmf;*.emf|'");
	vFileOpen.Multiselect = False;
	vFileOpen.Title = NStr("en='Open picture';ru='Открыть картинку';de='Bild öffnen'");
	vFileOpen.Preview = True;
	vFileOpen.Show(New NotifyDescription("CommandActionLoadPhotoFromFileNotification", ThisObject));
EndProcedure //  OpenPhotoFileDialogToChooseFile

// ----------------------------------------------------------------------------
//
// Parameters:
//  pFileArray	 - Array - File array
//  pParam		 - Null	 - Extra params
//
&AtClient
Procedure CommandActionLoadPhotoFromFileNotification(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		vFullFileName = pFileArray[0];
		vFile = New File(vFullFileName);
		vFile.BeginGettingModificationTime(New NotifyDescription("LoadPhotoFileGettingModificationTimeCompleted", ThisObject, New Structure("FileName, FullFileName", vFile.Name, vFullFileName)));
	EndIf;
EndProcedure //  CommandActionLoadPhotoFromFileNotification

// ----------------------------------------------------------------------------
//
// Parameters:
//  pModificationTime	 - Date	 - Last modification time
//  pParams				 - Null	 - Extra params
//
&AtClient
Procedure LoadPhotoFileGettingModificationTimeCompleted(pModificationTime, pParams) Export
	LoadPhotoFileInWebClient(pParams.FullFileName, New Structure("Name, LastModificationTime", pParams.FileName, pModificationTime));
EndProcedure //  LoadPhotoFileGettingModificationTimeCompleted

// ----------------------------------------------------------------------------
&AtClient
Procedure LoadPhotoFileInWebClient(pFullFileName, pFile)
	vFilesArray = New Array();
	vFileDescription = New TransferableFileDescription(pFullFileName);
	vFilesArray.Add(vFileDescription);
	BeginPuttingFiles(New NotifyDescription("PhotoFileDownloadToServerCompleted", ThisObject, pFile), vFilesArray, , False);
EndProcedure //  LoadPhotoFileInWebClient

// ----------------------------------------------------------------------------
&AtServer
Procedure PhotoFileDownloadToServerCompletedAtServer(pTransferredFiles, pFile)
	vFileAddress = pTransferredFiles.Get(0).Location;
	vBinaryData = GetFromTempStorage(vFileAddress);
	LoadPhotoFromFileAtServer(vBinaryData, pFile.Name, pFile.LastModificationTime);
EndProcedure //  PhotoFileDownloadToServerCompletedAtServer

// ----------------------------------------------------------------------------
//
// Parameters:
//  pTransferredFiles	 - Array - File array
//  pFile				 - File	 - File info
//
&AtClient
Procedure PhotoFileDownloadToServerCompleted(pTransferredFiles, pFile) Export
	PhotoFileDownloadToServerCompletedAtServer(pTransferredFiles, pFile);
EndProcedure //  PhotoFileDownloadToServerCompleted

// ----------------------------------------------------------------------------
&AtServer
Procedure LoadPhotoFromFileAtServer(pBinaryData, pFileName, pFileLastChangeTime) 
	vPhotoPicture = New Picture(pBinaryData);
	Photo = PutToTempStorage(vPhotoPicture, UUID);
	Modified = True;
	// Update photo in the list of clients
	vUUID = "1";
	If ValueIsFilled(Object.ParentDoc) Then
		vUUID = String(Object.ParentDoc.UUID());
	ElsIf ValueIsFilled(Object.Guest) Then
		vUUID = String(Object.Guest.UUID());
	EndIf;
	vUUID = StrReplace(vUUID, "-", "_");
	ThisObject["Photo" + vUUID] = Photo;
EndProcedure //  LoadPhotoFromFileAtServer

// ----------------------------------------------------------------------------
&AtServer
Procedure ClearPhotoAtServer()
	Photo = "";
	Modified = True;
	// Update photo in the list of clients
	vUUID = "1";
	If ValueIsFilled(Object.ParentDoc) Then
		vUUID = String(Object.ParentDoc.UUID());
	ElsIf ValueIsFilled(Object.Guest) Then
		vUUID = String(Object.Guest.UUID());
	EndIf;
	vUUID = StrReplace(vUUID, "-", "_");
	ThisObject["Photo" + vUUID] = Photo;
EndProcedure //  ClearPhotoAtServer

// ----------------------------------------------------------------------------
//
// Parameters:
//  pResult	 - Boolean	 - Result
//  pParam	 - Null		 - Extra params
//
&AtClient
Procedure LoadSignatureFromFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		OpenSignatureFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='File system extension is being installing on your browser...'; ru='В браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"));
		BeginInstallFileSystemExtension(New NotifyDescription("LoadSignatureFromFileFileSystemExtensionInstallCompleted", ThisObject));
	EndIf;
EndProcedure //  LoadSignatureFromFileAttachingFileSystemExtensionResult

// ----------------------------------------------------------------------------
//
// Parameters:
//  pParam	 - Null	 - Extra params
//
&AtClient
Procedure LoadSignatureFromFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadSignatureFromFileInstallingFileSystemExtensionResult", ThisObject));
EndProcedure //  LoadSignatureFromFileFileSystemExtensionInstallCompleted

// ----------------------------------------------------------------------------
//
// Parameters:
//  pResult	 - Boolean	 - Result
//  pParam	 - Null		 - Extra params
//
&AtClient
Procedure LoadSignatureFromFileInstallingFileSystemExtensionResult(pResult, pParam) Export 
	If pResult Then
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='В браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"));
		OpenSignatureFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"));
	EndIf;
EndProcedure //  LoadSignatureFromFileInstallingFileSystemExtensionResult

// ----------------------------------------------------------------------------
&AtClient 
Procedure OpenSignatureFileDialogToChooseFile()
	vFileOpen = New FileDialog(FileDialogMode.Open);
	vFileOpen.FullFileName = "";
	vFileOpen.Filter = NStr("ru = 'Картинки (*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf)|*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf|" +
	"bmp (*.bmp;*.dib;*.rle)|*.bmp;*.dib;*.rle|" + 
	"JPEG (*.jpg;*.jpeg)|*.jpg;*.jpeg|" + 
	"TIFF (*.tif)|*.tif|" + 
	"GIF (*.gif)|*.gif|" + 
	"PNG (*.png)|*.png|" + 
	"icon (*.ico)|*.ico|" + 
	"метафайл (*.wmf;*.emf)|*.wmf;*.emf|'; 
	|de = 'Картинки (*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf)|*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf|" +
	"bmp (*.bmp;*.dib;*.rle)|*.bmp;*.dib;*.rle|" + 
	"JPEG (*.jpg;*.jpeg)|*.jpg;*.jpeg|" + 
	"TIFF (*.tif)|*.tif|" + 
	"GIF (*.gif)|*.gif|" + 
	"PNG (*.png)|*.png|" + 
	"icon (*.ico)|*.ico|" + 
	"метафайл (*.wmf;*.emf)|*.wmf;*.emf|'; 
	|en = 'Pictures (*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf)|*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf|" +
	"bmp (*.bmp;*.dib;*.rle)|*.bmp;*.dib;*.rle|" + 
	"JPEG (*.jpg;*.jpeg)|*.jpg;*.jpeg|" + 
	"TIFF (*.tif)|*.tif|" + 
	"GIF (*.gif)|*.gif|" + 
	"PNG (*.png)|*.png|" + 
	"icon (*.ico)|*.ico|" + 
	"metafile (*.wmf;*.emf)|*.wmf;*.emf|'");
	vFileOpen.Multiselect = False;
	vFileOpen.Title = NStr("en='Open picture';ru='Открыть картинку';de='Bild öffnen'");
	vFileOpen.Preview = True;
	vFileOpen.Show(New NotifyDescription("CommandActionLoadSignatureFromFileNotification", ThisObject));
EndProcedure //  OpenSignatureFileDialogToChooseFile

// ----------------------------------------------------------------------------
//
// Parameters:
//  pFileArray	 - Array - File array
//  pParam		 - Null	 - Extra params
//
&AtClient
Procedure CommandActionLoadSignatureFromFileNotification(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		vFullFileName = pFileArray[0];
		vFile = New File(vFullFileName);
		vFile.BeginGettingModificationTime(New NotifyDescription("LoadSignatureFileGettingModificationTimeCompleted", ThisObject, New Structure("FileName, FullFileName", vFile.Name, vFullFileName)));
	EndIf;
EndProcedure //  CommandActionLoadSignatureFromFileNotification

// ----------------------------------------------------------------------------
//
// Parameters:
//  pModificationTime	 - Date	 - Last modification time
//  pParams				 - Null	 - Extra params
//
&AtClient
Procedure LoadSignatureFileGettingModificationTimeCompleted(pModificationTime, pParams) Export
	LoadSignatureFileInWebClient(pParams.FullFileName, New Structure("Name, LastModificationTime", pParams.FileName, pModificationTime));
EndProcedure //  LoadSignatureFileGettingModificationTimeCompleted

// ----------------------------------------------------------------------------
&AtClient
Procedure LoadSignatureFileInWebClient(pFullFileName, pFile)
	vFilesArray = New Array();
	vFileDescription = New TransferableFileDescription(pFullFileName);
	vFilesArray.Add(vFileDescription);
	BeginPuttingFiles(New NotifyDescription("SignatureFileDownloadToServerCompleted", ThisObject, pFile), vFilesArray, , False);
EndProcedure //  LoadSignatureFileInWebClient

// ----------------------------------------------------------------------------
&AtServer
Procedure SignatureFileDownloadToServerCompletedAtServer(pTransferredFiles, pFile)
	vFileAddress = pTransferredFiles.Get(0).Location;
	vBinaryData = GetFromTempStorage(vFileAddress);
	LoadSignatureFromFileAtServer(vBinaryData, pFile.Name, pFile.LastModificationTime);
EndProcedure //  SignatureFileDownloadToServerCompletedAtServer

// ----------------------------------------------------------------------------
//
// Parameters:
//  pTransferredFiles	 - Array - File array
//  pFile				 - File	 - File info
//
&AtClient
Procedure SignatureFileDownloadToServerCompleted(pTransferredFiles, pFile) Export
	SignatureFileDownloadToServerCompletedAtServer(pTransferredFiles, pFile);
EndProcedure //  SignatureFileDownloadToServerCompleted

// ----------------------------------------------------------------------------
&AtServer
Procedure LoadSignatureFromFileAtServer(pBinaryData, pFileName, pFileLastChangeTime) 
	vSignaturePicture = New Picture(pBinaryData);
	Signature = PutToTempStorage(vSignaturePicture, UUID);
	Modified = True;
EndProcedure //  LoadSignatureFromFileAtServer

// ----------------------------------------------------------------------------
&AtServer
Procedure ClearSignatureAtServer()
	Signature = "";
	Modified = True;
EndProcedure //  ClearSignatureAtServer

// ----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "" Then
	EndIf;
EndProcedure //  NotificationProcessing

// ----------------------------------------------------------------------------
&AtServerNoContext
Function GetPaperSizeForScan1C(pPaperSize)
	vPSCode = 1;
	If ValueIsFilled(pPaperSize) Then
		If pPaperSize = Enums.PaperSizes.A3 Then
			vPSCode = 11;
		ElsIf pPaperSize = Enums.PaperSizes.A4 Then
			vPSCode = 1;
		ElsIf pPaperSize = Enums.PaperSizes.A5 Then
			vPSCode = 5;
		ElsIf pPaperSize = Enums.PaperSizes.B4 Then
			vPSCode = 6;
		ElsIf pPaperSize = Enums.PaperSizes.B5 Then
			vPSCode = 2;
		ElsIf pPaperSize = Enums.PaperSizes.B6 Then
			vPSCode = 7;
		ElsIf pPaperSize = Enums.PaperSizes.C4 Then
			vPSCode = 14;
		ElsIf pPaperSize = Enums.PaperSizes.C5 Then
			vPSCode = 15;
		ElsIf pPaperSize = Enums.PaperSizes.C6 Then
			vPSCode = 16;
		ElsIf pPaperSize = Enums.PaperSizes.USLET Then
			vPSCode = 3;
		ElsIf pPaperSize = Enums.PaperSizes.USLEG Then
			vPSCode = 4;
		ElsIf pPaperSize = Enums.PaperSizes.USEXECUTIVE Then
			vPSCode = 10;
		ElsIf ValueIsFilled(pPaperSize) Then
			Raise NStr("en='Unsupported paper size (A3, A4, A5, B4, B5, B6, C4, C5, C6, USLET, USLEG, USEXECUTIVE are allowed only)!';ru='Неподдерживаемый размер бумаги (разрешены A3, A4, A5, B4, B5, B6, C4, C5, C6, USLET, USLEG, USEXECUTIVE)!';de='Nicht unterstütztes Papierformat Farbtiefe (erlaubt sind A3, A4, A5, B4, B5, B6, C4, C5, C6, USLET, USLEG, USEXECUTIVE)'")
		EndIf;
	EndIf;
	
	Return vPSCode;
EndFunction //  GetPaperSizeForScan1C

// ----------------------------------------------------------------------------
&AtServerNoContext
Function GetColorDepthForScan1C(pColorDepth)
	vColorDepthCode = 2;
	If ValueIsFilled(pColorDepth) Then
		If pColorDepth = Enums.ColorDepths.RGB Then
			vColorDepthCode = 2;
		ElsIf pColorDepth = PredefinedValue("Enum.ColorDepths.Palette") Then
			Raise NStr("en='Unsupported color depth (24 bits color, Grayscale, Black&white image are allowed only)!';ru='Неподдерживаемая глубина цвета (разрешены 24 битный цвет, Оттенки серого, Черно-белая картинка)!';de='Eine nicht unterstützte Farbtiefe (erlaubt sind 24-Bit-Farben, Grauschattierungen, schwarz-weißes Bild)'");
		ElsIf pColorDepth = Enums.ColorDepths.Gray Then
			vColorDepthCode = 1;
		ElsIf pColorDepth = Enums.ColorDepths.BW Then
			vColorDepthCode = 0;
		EndIf;
	EndIf;
	
	Return vColorDepthCode;
EndFunction //  GetColorDepthForScan1C

// ----------------------------------------------------------------------------
&AtServerNoContext
Function GetVisaResidencePermitDocument(pType)
	// Get Residence Permit Document reference
	vResPermDocs = Enums.ConfirmingDocuments;
	vDoc = Undefined;
	If pType = "178" Then
		vDoc = vResPermDocs["Visa"];
	ElsIf pType = "224" Or pType = "240" Then
		vDoc = vResPermDocs["PermResidencePermit"];	
	ElsIf pType = "215" Then
		vDoc = vResPermDocs["TempResidencePermit"];	
	EndIf;
	
	Return vDoc;
EndFunction // GetVisaResidencePermitDocument

// ----------------------------------------------------------------------------
&AtServerNoContext
Function GetVisaType(pVisaType)
	vCode = "";
	
	If pVisaType = "О" Then
		vCode = "135432";
	ElsIf pVisaType = "ОЧ" Then
		vCode = "2";
	ElsIf pVisaType = "ОД" Then
		vCode = "3";
	ElsIf pVisaType = "ОТ" Then
		vCode = "135436";
	ElsIf pVisaType = "ОТГ" Then
		vCode = "135437";
	ElsIf pVisaType = "ОУ" Then
		vCode = "5";
	ElsIf pVisaType = "ОР" Then
		vCode = "6";
	ElsIf pVisaType = "ОГ" Then
		vCode = "7";
	ElsIf pVisaType = "ОА" Then
		vCode = "8";
	ElsIf pVisaType = "ДП" Then
		vCode = "1";
	ElsIf pVisaType = "СЛ" Then
		vCode = "135433";
	ElsIf pVisaType = "ВП" Then
		vCode = "10";
	ElsIf pVisaType = "ТР1" Then
		vCode = 91;
	ElsIf pVisaType = "ТР2" Then
		vCode = "92";
	EndIf;
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT TOP 1
	|	VisaTypes.Ref AS Ref
	|FROM
	|	Catalog.VisaTypes AS VisaTypes
	|WHERE
	|	STRREPLACE(VisaTypes.Code, "" "", """") = &qCode";
	vQuery.SetParameter("qCode", vCode);	
	vQueryResult = vQuery.Execute().Unload();
	If vQueryResult.Count() > 0 Then
		pVisaType = vQueryResult[0].Ref;
	EndIf;
	
	Return pVisaType;
EndFunction // GetVisaType

// ----------------------------------------------------------------------------
&AtServerNoContext
Function GetVisaEntryGoal(pVisaType, pEntryGoal)
	vQuery = New Query;
	vQuery.Text = 
	"SELECT TOP 1
	|	EntryGoals.Ref AS Ref
	|FROM
	|	Catalog.EntryGoals AS EntryGoals
	|WHERE
	|	NOT EntryGoals.DeletionMark
	|	AND EntryGoals.VisaType = &qVisaType
	|	AND STRFIND(&qEntryGoal, EntryGoals.Description) > 0";
	vQuery.SetParameter("qVisaType", pVisaType);
	vQuery.SetParameter("qEntryGoal", pEntryGoal);
	vQueryResult = vQuery.Execute().Unload();
	If vQueryResult.Count() > 0 Then
		pEntryGoal = vQueryResult[0].Ref;
	EndIf;
	
	Return pEntryGoal;	
EndFunction // GetVisaEntryGoal

// ----------------------------------------------------------------------------
&AtServerNoContext
Function GetVisaMultiplicityType(pMultiplicityType)
	vVisaMultiplicityTypes = Enums.VisaMultiplicityTypes;
	vVisaMultType = vVisaMultiplicityTypes.EmptyRef();
	
	If StrFind(pMultiplicityType, "ОДНОКРАТНАЯ") > 0 Then
		vVisaMultType = vVisaMultiplicityTypes["Single"];
	ElsIf StrFind(pMultiplicityType, "ДВУКРАТНАЯ") > 0 Then
		vVisaMultType = vVisaMultiplicityTypes["TwoTime"];
	ElsIf StrFind(pMultiplicityType, "МНОГОКРАТНАЯ") > 0 Then
		vVisaMultType = vVisaMultiplicityTypes["Multiple"];	
	EndIf;
	Return vVisaMultType;
EndFunction // GetVisaMultiplisityTypes

// ----------------------------------------------------------------------------
&AtClient
Procedure RecognizeYAVision(pInteractionParameters, rMessage="")
	vIsPassportExists = False;
	vImagesArray = New Array();
	For Each vCurRow In Object.ScanPictures Do
		vScanConfiguration = tcOnServer.cmGetAtributeAsArray(vCurRow.ScanConfiguration);
		vIdentityDocumentTypeCode = TrimAll(tcOnServer.cmGetAttributeByRef(vScanConfiguration.IdentityDocumentType, "Code"));
		
		If vIdentityDocumentTypeCode <> "21" Then
			// Skip recognition
			Continue;
		EndIf;
		If Not vCurRow.RecognitionIsAvailable Then
			Continue;
		EndIf;
		If IsBlankString(vCurRow.TempStorage) Then
			Continue;
		EndIf;
		
		vIsPassportExists = True;
		vRussianPassportScanConf = vScanConfiguration;
		
		vPicture = GetFromTempStorage(vCurRow.TempStorage);
		If vPicture = Undefined Then
			Continue;
		EndIf;
		vPicBinary = vPicture.GetBinaryData();
		vPicBase64 = Base64String(vPicBinary);
		vPicture = Undefined;
		
		vImagesArray.Add(vPicBase64);
	EndDo;
	
	If Not vIsPassportExists Then
		rMessage = NStr("en='There is no passport page among the scanned documents!';ru='Среди отсканированных документов отсутствует страница паспорта!';de='Unter den gescannten Dokumenten befindet sich keine Seite des Reisepasses!'");
		Return;	
	EndIf;
	
	pResult = New Structure;
	pData = New Structure;
	
	vRecognitionQuality = New Structure();
	// Initialize recognized fields structure
	vRecognitionQuality.Insert("Citizenship", 0);
	vRecognitionQuality.Insert("IdentityDocumentValidToDate", 0);
	vRecognitionQuality.Insert("Sex", 0);
	vRecognitionQuality.Insert("IdentityDocumentUnitCode", 0);
	vRecognitionQuality.Insert("IdentityDocumentIssueDate", 0);
	vRecognitionQuality.Insert("IdentityDocumentIssuedBy", 0);
	vRecognitionQuality.Insert("LastName", 0);
	vRecognitionQuality.Insert("FirstName", 0);
	vRecognitionQuality.Insert("SecondName", 0);
	vRecognitionQuality.Insert("DateOfBirth", 0);
	vRecognitionQuality.Insert("PlaceOfBirth", 0);
	vRecognitionQuality.Insert("IdentityDocumentSeries", 0);
	vRecognitionQuality.Insert("IdentityDocumentNumber", 0);
	
	// Recognize each valid document picture and merge results in pData structure
	For Each vImage In vImagesArray Do
		If pData.Property("RecognitionQuality") Then
			vRecognitionQuality = pData.RecognitionQuality;
		EndIf;
		pResult = tcYandexVision.RecognizeDocument(pInteractionParameters, vImage, vRecognitionQuality, rMessage);
		If IsBlankString(rMessage) And pResult.Count() > 0 Then
			For Each pResultRow In pResult Do
				If Not pData.Property(pResultRow.Key) And ValueIsFilled(pResultRow.Value) Then
					If pResultRow.Key = "RecognitionQuality" And pData.Property("RecognitionQuality") Then
						vQualityStruct = pResultRow.Value;
						For Each vQualityRow In vQualityStruct Do
							If vQualityRow.Value <> 0 Then
								pData.RecognitionQuality[vQualityRow.Key] = vQualityRow.Value;
							EndIf;
						EndDo;
					Else 
						pData.Insert(pResultRow.Key, pResultRow.Value);
					EndIf;
				EndIf;
			EndDo;
		Else
			Return;
		EndIf;
	EndDo;
	
	FormatCitizenshipAndPlaceOfBirth(pData);
	
	If pData.Property("IdentityDocumentUnitCode") Then
		If ValueIsFilled(pData.IdentityDocumentUnitCode) Then
			If Not pData.Property("IdentityDocumentIssuedBy") Then
				pData.Insert("IdentityDocumentIssuedBy");
			EndIf;
			GetDocumentIssuer(pData);	
		EndIf;
	EndIf;
	
	// Fill form fields with recodnized data
	For Each vKeyAndValue In pData Do
		If ValueIsFilled(vKeyAndValue.Value) Then
			If Object.Property(vKeyAndValue.Key) Then
				If Not vKeyAndValue.Key = "RecognitionQuality" Then
					Object[vKeyAndValue.Key] = vKeyAndValue.Value;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	Object.IdentityDocumentType = vRussianPassportScanConf.IdentityDocumentType;
	Items.Picture.NonselectedPictureText = "";
	
	If pData.Count() > 0 Then
		FillPassportInfo(pData);
		Object.Status = PredefinedValue("Enum.ScanStatuses.IsRecognized");
	EndIf;
EndProcedure //  RecognizeYAVision

// ----------------------------------------------------------------------------
&AtServerNoContext
Procedure GetDocumentIssuer(pData)
	vQryRes = cmGetFMSRecord(TrimAll(pData.IdentityDocumentUnitCode), True, , 1).Select();
	While vQryRes.Next() Do
		If pData.Property("IdentityDocumentIssuedBy") Then
			pData.IdentityDocumentIssuedBy = TrimAll(vQryRes.Description);
			pData.RecognitionQuality.IdentityDocumentIssuedBy = pData.RecognitionQuality.IdentityDocumentUnitCode;
		EndIf;	
	EndDo;
EndProcedure //  GetDocumentIssuer

// ----------------------------------------------------------------------------
&AtClient
Procedure CropPhotoYV(pInteractionParameters)
	#IF NOT WebClient AND NOT MobileClient THEN
		vMessage = "";
		vRow = Object.ScanPictures.Get(CurrentPage);
		If vRow <> Undefined And Not IsBlankString(vRow.TempStorage) Then
			vFullFileName = GetTempFileName("jpg");
			vPicture = GetFromTempStorage(vRow.TempStorage);
			If vPicture = Undefined Then
				vMessage = NStr("en='No picture is loaded!';ru='Картинка не загружена!';de='Bild ist nicht geladen!'");
				tcCommonFunctionOnClientServer.UserMessage(vMessage);
				Return;
			EndIf;
			
			vPicture.Write(vFullFileName);
			
			vPicBinary = vPicture.GetBinaryData();
			vPicBase64 = Base64String(vPicBinary);
			
			vCoordArray = tcYandexVision.FindFaces(pInteractionParameters, vPicBase64);
			
			If TypeOf(vCoordArray) = Type("Array") Then
				If Not vCoordArray.Count() = 4 Then
					Return;
				EndIf;
			Else 
				Return;
			EndIf;
			
			// Build active X object to rotate picture
			Try
				vGFLAx = New COMObject("GFLAx.GFLAx");
			Except
				vMessage = NStr("en='GFLAx (ActiveX/ASP component) should be installed first! Go to the current workstation item settings and press <Install GFLAx (ActiveX/ASP component)> button.';ru='ActiveX/ASP библиотека GFLAx не установлена! Для установки откройте карточку настроек рабочего места и нажмите на кнопку <Установить GFLAx (ActiveX/ASP библиотеку)>.';de='Die ActiveX/ASP-Bibliothek GFLAx wurde nicht installiert! Zur Installation öffnen Sie die Arbeitsplatzeinstellungen und wählen Sie <GFLAx (ActiveX/AP-Bibliothek) installieren)>.'");
				tcCommonFunctionOnClientServer.UserMessage(vMessage);
				Return;
			EndTry;
			Try
				vGFLAx.LoadBitmap(vFullFileName);
				vGFLAx.Crop(vCoordArray[0], vCoordArray[1], vCoordArray[2], vCoordArray[3]);
				vGFLAx.SaveJPEGQuality = 30;
				vGFLAx.SaveBitmap(vFullFileName);
				vGFLAx = Undefined;
			Except
				vMessage = NStr("en='Unsupported picture format!';ru='Формат картинки не поддерживается!';de='Format des Bilds wird nicht unterstützt!'") + Chars.LF + ErrorDescription();
				tcCommonFunctionOnClientServer.UserMessage(vMessage);
				Return;
			EndTry;
			vPhoto = PutToTempStorage(New Picture(vFullFileName, False), UUID);
			Photo = vPhoto;
			Try
				DeleteFiles(vFullFileName);
			Except
				tcCommonFunctionOnClientServer.UserMessage(ErrorDescription());
			EndTry;
		Else
			vMessage = NStr("en='Image is not choosen!';ru='Не выбрана картинка!';de='Kein Bild ist gewählt!'");
			tcCommonFunctionOnClientServer.UserMessage(vMessage);
		EndIf;
	#ENDIF
EndProcedure //  CropPhotoYV

// ----------------------------------------------------------------------------
&AtClient
Procedure FormatCitizenshipAndPlaceOfBirth(pResult)
	If pResult.Property("Citizenship") Then
		Try
			If ValueIsFilled(pResult.Citizenship) Then
				pResult.Citizenship = GetCountryByCode(pResult.Citizenship);
			EndIf;
		Except;
		Endtry;
	EndIf;
	
	If pResult.Property("PlaceOfBirth") Then 
		If IsForeigner = 0 Then
			vBaseCitizenship = tcOnServer.cmGetAttributeByRef(Object.Hotel, "Citizenship");
			If ValueIsFilled(vBaseCitizenship) Then
				If tcOnServer.cmGetAttributeByRef(vBaseCitizenship, "Code") = 643 Then // Russia
					If pResult.Property("DateOfBirth") And Not IsBlankString(pResult.DateOfBirth) Then
						If pResult.DateOfBirth < '19920101' Then	
							vCitizenship = GetUSSR();
							If ValueIsFilled(vCitizenship) Then
								pResult.PlaceOfBirth = GetPlaceOfBirth(vCitizenship, , , , TrimAll(pResult.PlaceOfBirth));	
							Else
								pResult.PlaceOfBirth = GetPlaceOfBirth(vBaseCitizenship, , , , TrimAll(pResult.PlaceOfBirth));
							EndIf;
						Else
							pResult.PlaceOfBirth = GetPlaceOfBirth(vBaseCitizenship, , , , TrimAll(pResult.PlaceOfBirth));
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		Else
			pResult.PlaceOfBirth = GetPlaceOfBirth(?(pResult.Property("Citizenship"), TrimAll(pResult.Citizenship), Undefined), , , , TrimAll(pResult.PlaceOfBirth));	
		EndIf;
	EndIf;
EndProcedure // FormatCitizenshipAndPlaceOfBirth

// ----------------------------------------------------------------------------
&AtServerNoContext
Function GetCurrentSessionDate()
	Return CurrentSessionDate();
EndFunction // GetCurrentSessionDate

// ----------------------------------------------------------------------------
&AtServer
Procedure BeforeCloseAtServer()
	// User log
	If WasChanged Then
		vEventDescription = NStr("en = 'Change document'; de = 'Dokument ändern'; ru = 'Редактирование документа'");
		InformationRegisters.UserActionsHistory.WriteUserActivityRecord(Object.Ref, vEventDescription, Object.Hotel);
	Else	
		vEventDescription = NStr("en = 'View document'; de = 'Ein Dokument anzeigen'; ru = 'Просмотр документа'");
		InformationRegisters.UserActionsHistory.WriteUserActivityRecord(Object.Ref, vEventDescription, Object.Hotel);  
	EndIf;
EndProcedure //  BeforeClose  

// ----------------------------------------------------------------------------
&AtServerNoContext
Function GetYandexVisionIntegration(pHotel)
	Return Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionType(Enums.Integrations.YandexVision, pHotel);	
EndFunction // GetYandexVisionIntegration

// ----------------------------------------------------------------------------
&AtClient
Procedure FillClientCertificate(Val pBarCodeData)
	Try
		If ValueIsFilled(pBarCodeData) Then
			If StrFind(pBarCodeData, "mos.ru") <> 0 Or StrFind(pBarCodeData, "gosuslugi.ru") <> 0 Then
				vClientCertificateRef = Undefined;
				vMessage = "";
				vDataStructure = "";
				If CreateClientCertificateAtServer(Object.Guest, pBarCodeData, vClientCertificateRef, New Structure("DateOfBirth, LastName, FirstName, SecondName", Object.DateOfBirth, Object.LastName, Object.FirstName, Object.SecondName)) Then
					Notify("InformationRegisters.ClientCertificates.Write", Object.Guest);
					CreatePhotoBar();
					If ValueIsFilled(vClientCertificateRef) Then
						ShowUserNotification(NStr("en = 'The certificate is registered.'; de = 'Das Zertifikat ist registriert.'; ru = 'Сертификат зарегистрирован.'"), GetURL(vClientCertificateRef), , , UserNotificationStatus.Information, UUID);	
					EndIf;
				Elsif ValueIsFilled(vClientCertificateRef) Then
					OpenForm("InformationRegister.ClientCertificates.RecordForm", New Structure("Key, SelGuest, IsChangeCardOwner", vClientCertificateRef, Object.Guest, True), ThisObject, UUID, , , New NotifyDescription("AfterChangeCardOwner", ThisObject));
				Else
					BeginRunningApplication(New NotifyDescription, pBarCodeData);
				EndIf;
			Else
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Failed to read QR-Code'; de = 'QR-Code konnte nicht gelesen werden'; ru = 'Не удалось прочитать QR-код'"));
			EndIf;
		Else
			tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Failed to read QR-Code'; de = 'QR-Code konnte nicht gelesen werden'; ru = 'Не удалось прочитать QR-код'"));
		EndIf;
	Except
		tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Failed to read QR-Code'; de = 'QR-Code konnte nicht gelesen werden'; ru = 'Не удалось прочитать QR-код'"));
	EndTry;
EndProcedure // ExternalEvent

// --------------------------------------------------------------------------------
&AtServer
Procedure FillPersData(pFixData)   
	If StrFind(pFixData, "ФИО") > 0 Then
		SourcePersonalData = "MAX";	  
		ClearAtServer();
		
		vDataArr = StrSplit(pFixData, Chars.LF); 
		For Each vRow In vDataArr Do     
			If IsBlankString(vRow) Then
				Continue;
			EndIf;
			If vRow = "Паспорт РФ" Then
				Object.IdentityDocumentType = Catalogs.IdentityDocumentTypes.FindByCode("21");   
				AddRowRecognitionQuality("IdentityDocumentType", 999);
			ElsIf vRow = "Свидетельство о рождении" Then
				Object.IdentityDocumentType = Catalogs.IdentityDocumentTypes.FindByCode("03");  
				AddRowRecognitionQuality("IdentityDocumentType", 999);
			ElsIf vRow = "Водительское удостоверение" Or vRow = "Водительские права" Then
				Object.IdentityDocumentType = Catalogs.IdentityDocumentTypes.FindByCode("150");
				AddRowRecognitionQuality("IdentityDocumentType", 999);
			ElsIf StrFind(vRow, "ФИО") > 0  Then
				vFIO = TrimAll(StrReplace(vRow, "ФИО:", ""));	
				cmParseClientFullName(vFIO, Object.LastName, Object.FirstName, Object.SecondName);  
				AddRowRecognitionQuality("LastName", 999); 
				AddRowRecognitionQuality("FirstName", 999);
				AddRowRecognitionQuality("SecondName", 999);
			ElsIf StrFind(vRow, "Серия и номер:") > 0 Then
				vClearData = TrimAll(StrReplace(vRow, "Серия и номер:", ""));
				vClearDataArr = StrSplit(vClearData, " ");
				If vClearDataArr.Count() = 1 Then 
					Object.IdentityDocumentNumber = vClearData;	    
					AddRowRecognitionQuality("IdentityDocumentNumber", 999);
				ElsIf vClearDataArr.Count() = 2 Then  
					Object.IdentityDocumentSeries = vClearDataArr[0];
					Object.IdentityDocumentNumber = vClearDataArr[1];   
					AddRowRecognitionQuality("IdentityDocumentSeries", 999);
					AddRowRecognitionQuality("IdentityDocumentNumber", 999);
				ElsIf vClearDataArr.Count() = 3 Then  
					Object.IdentityDocumentSeries = vClearDataArr[0] + vClearDataArr[1];
					Object.IdentityDocumentNumber = vClearDataArr[2];	
					AddRowRecognitionQuality("IdentityDocumentSeries", 999);
					AddRowRecognitionQuality("IdentityDocumentNumber", 999);
				EndIf;
			ElsIf StrFind(vRow, "Номер:") > 0 Then
				vClearData = TrimAll(StrReplace(vRow, "Номер:", ""));      
				If vDataArr[0] = "СНИЛС" Then
					 Object.SocialSecurityNumber = vClearData; 
					 AddRowRecognitionQuality("SocialSecurityNumber", 999);
				Else	
					vClearDataArr = StrSplit(vClearData, " ");
					If vClearDataArr.Count() = 1 Then 
						Object.IdentityDocumentNumber = vClearData;	   
						AddRowRecognitionQuality("IdentityDocumentNumber", 999);
					ElsIf vClearDataArr.Count() = 2 Then  
						Object.IdentityDocumentSeries = vClearDataArr[0];
						Object.IdentityDocumentNumber = vClearDataArr[1]; 
						AddRowRecognitionQuality("IdentityDocumentSeries", 999);
						AddRowRecognitionQuality("IdentityDocumentNumber", 999);
					ElsIf vClearDataArr.Count() = 3 Then  
						Object.IdentityDocumentSeries = vClearDataArr[0] + vClearDataArr[1];
						Object.IdentityDocumentNumber = vClearDataArr[2];
						AddRowRecognitionQuality("IdentityDocumentSeries", 999);
						AddRowRecognitionQuality("IdentityDocumentNumber", 999);
					EndIf;	   
				EndIf;
			ElsIf StrFind(vRow, "Кем выдан:") > 0 Then
				vClearData = TrimAll(StrReplace(vRow, "Кем выдан:", ""));
				Object.IdentityDocumentIssuedBy = vClearData;   
				AddRowRecognitionQuality("IdentityDocumentIssuedBy", 999);
			ElsIf StrFind(vRow, "Орган, выдавший документ:") > 0 Then
				vClearData = TrimAll(StrReplace(vRow, "Орган, выдавший документ:", ""));
				Object.IdentityDocumentIssuedBy = vClearData;     
				AddRowRecognitionQuality("IdentityDocumentIssuedBy", 999);
			ElsIf StrFind(vRow, "№ отделения ГИБДД:") > 0 Then
				vClearData = TrimAll(StrReplace(vRow, "№ отделения ГИБДД:", ""));
				Object.IdentityDocumentIssuedBy = vClearData; 
				AddRowRecognitionQuality("IdentityDocumentIssuedBy", 999);
			ElsIf StrFind(vRow, "Дата выдачи:") > 0 Then
				vClearData = TrimAll(StrReplace(vRow, "Дата выдачи:", ""));
				Object.IdentityDocumentIssueDate = tcCommonFunctionOnClientServer.StringToDateByFormat("dd.MM.yyyy", vClearData);    
				AddRowRecognitionQuality("IdentityDocumentIssueDate", 999);
			ElsIf StrFind(vRow, "Дата составления:") > 0 Then
				vClearData = TrimAll(StrReplace(vRow, "Дата составления:", ""));
				Object.IdentityDocumentIssueDate = tcCommonFunctionOnClientServer.StringToDateByFormat("dd.MM.yyyy", vClearData); 
                AddRowRecognitionQuality("IdentityDocumentIssueDate", 999);
			ElsIf StrFind(vRow, "Код подразделения:") > 0 Then
				vClearData = TrimAll(StrReplace(vRow, "Код подразделения:", ""));
				Object.IdentityDocumentUnitCode = Left(vClearData, 3) + "-" + Right(vClearData, 3);	
				AddRowRecognitionQuality("IdentityDocumentUnitCode", 999);
			ElsIf StrFind(vRow, "Дата рождения, регион:") > 0 Then
				vClearData = TrimAll(StrReplace(vRow, "Дата рождения, регион:", ""));    
				vClearDataArr = StrSplit(vClearData, ","); 
				If vClearDataArr.Count() = 2 Then
					Object.DateOfBirth = tcCommonFunctionOnClientServer.StringToDateByFormat("dd.MM.yyyy", vClearDataArr[0]);
					vPlaceOfBirth = vClearDataArr[1];
					vListAddress = cmGetDataFromDadata(vPlaceOfBirth);  
					If TypeOf(vListAddress) = Type("ValueList") And vListAddress.Count() > 0 And Not IsBlankString(vListAddress[0].Value.Address) Then
						vPlaceOfBirth = vListAddress[0].Value.Address;	
					EndIf;
					Object.PlaceOfBirth = vPlaceOfBirth;     
					AddRowRecognitionQuality("DateOfBirth", 999);  
					AddRowRecognitionQuality("PlaceOfBirth", 999);
				EndIf;
			ElsIf StrFind(vRow, "Дата рождения:") > 0 Then
				vClearData = TrimAll(StrReplace(vRow, "Дата рождения:", ""));
				Object.DateOfBirth = tcCommonFunctionOnClientServer.StringToDateByFormat("dd.MM.yyyy", vClearData); 
				AddRowRecognitionQuality("DateOfBirth", 999);
			ElsIf StrFind(vRow, "Место рождения:") > 0  Then
				vPlaceOfBirth = TrimAll(StrReplace(vRow, "Место рождения:", ""));
				vListAddress = cmGetDataFromDadata(vPlaceOfBirth);  
				If TypeOf(vListAddress) = Type("ValueList") And vListAddress.Count() > 0 And Not IsBlankString(vListAddress[0].Value.Address) Then
					vPlaceOfBirth = vListAddress[0].Value.Address;	
				EndIf;
				Object.PlaceOfBirth = vPlaceOfBirth;   
				AddRowRecognitionQuality("PlaceOfBirth", 999);
			ElsIf StrFind(vRow, "Пол:") > 0  Then
				vClearData = TrimAll(StrReplace(vRow, "Пол:", ""));
				If vClearData = "Мужской" Then
					Object.Sex = Enums.Sex.Male; 
					AddRowRecognitionQuality("Sex", 999);
				ElsIf vClearData = "Женский" Then
					Object.Sex = Enums.Sex.Female;	
					AddRowRecognitionQuality("Sex", 999);
				EndIf;     
			ElsIf StrFind(vRow, "Адрес регистрации:") > 0 Then
				vAddress = TrimAll(StrReplace(vRow, "Адрес регистрации:", "")); 
				vListAddress = cmGetDataFromDadata(vAddress);  
				If TypeOf(vListAddress) = Type("ValueList") And vListAddress.Count() > 0 And Not IsBlankString(vListAddress[0].Value.Address) Then
					vAddress = vListAddress[0].Value.Address;	
				EndIf;
				Object.Address = vAddress;
				AddRowRecognitionQuality("Address", 999);
			EndIf;	   
			If Not ValueIsFilled(Object.Citizenship) Then
				Object.Citizenship = Object.Hotel.Citizenship;
				AddRowRecognitionQuality("Citizenship", 999); 
			EndIf;
		EndDo;
		Object.Status = Enums.ScanStatuses.IsProcessed;   
		If IsBlankString(Picture) Then
			Picture = "";
			Items.Picture.NonselectedPictureText = NStr("en = 'Digital ID in the MAX messenger'; de = 'Digitale ID im MAX Messenger'; ru = 'Цифровой ID в мессенджере MAX'");
			Items.Picture.TextColor = WebColors.Blue;
		EndIf;   
		Modified = True;  
		RefreshDisplay();
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure AddRowRecognitionQuality(pFField, pQuality)
	vNewRow = Object.RecognitionQuality.Add();	
	vNewRow.Field = pFField;
	vNewRow.Quality = pQuality;
EndProcedure

#EndRegion
