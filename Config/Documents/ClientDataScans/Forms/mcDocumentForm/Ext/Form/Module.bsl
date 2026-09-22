
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
	Photo     = PutToTempStorage(vObject.Photo.Get(), UUID);
	Signature = PutToTempStorage(vObject.Signature.Get(), UUID);
	
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
		IsForeigner = 0; // Home region
	EndIf;
	EditTopGroupHeader();
	VisumDataAppearance();
	
	// Check edit prohibited date
	If ValueIsFilled(Object.Hotel) And ValueIsFilled(Object.ParentDoc) Then
		If ValueIsFilled(Object.Hotel.EditProhibitedDate) And 
			BegOfDay(Object.Hotel.EditProhibitedDate) >= BegOfDay(Object.ParentDoc.CheckOutDate) Then
			ThisObject.ReadOnly = True;
		EndIf;
	EndIf;
	
	// Check user rights to edit addresses
	If Not cmCheckUserPermissions("HavePermissionToTextEditClientAddresses") Then
		Items.PlaceOfBirth.TextEdit = False;
		Items.Address.TextEdit = False;
	Endif; 
	
	// Generate form
	GetGuestListByRoom();
	FillPresentationGuestList();
	FillScanConfigList();
	CreatePhotoBar(True); 
	FillExtraData();
	RefreshDisplay();
EndProcedure //  OnCreateAtServer

// ----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	// Set the current guest as active
	If ValueIsFilled(Object.Guest) Then
		vUUID = String(StrReplace(Object.Guest.UUID(),"-","_"));
		Items["FormGroupGuests"+vUUID].BackColor = WebColors.LightCyan; 
		Items["FormDecorationTitleFIO_"+vUUID].Font = New Font(,,True);
		CurrentPageGuest = vUUID;
	EndIf; 
EndProcedure //  OnOpen

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
EndProcedure // BeforeWriteAtServer

// ----------------------------------------------------------------------------
&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	Read();
	FillScanConfigList();
	CreatePhotoBar(True); 
EndProcedure //  AfterWriteAtServer

// ----------------------------------------------------------------------------
&AtClient
Procedure BeforeClose(pCancel, pExit, pMessageText, pStandardProcessing)
	If SilentCloseMode Then
		SilentCloseMode = False;
		pStandardProcessing = False;
	EndIf;
EndProcedure //  BeforeClose

#EndRegion

#Region FormHeaderItemsEventHandlers

// ----------------------------------------------------------------------------
&AtClient
Procedure VisaTypeOnChange(pItem)
	VisaTypeOnChangeAtServer();
EndProcedure //  VisaTypeOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure ClickGuest(pItem, pStandardProcessing)
	pStandardProcessing = False;
	If Not CurrentPageGuest = pItem.Title Then
		If Modified Then
			If Not Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
			EndIf;
		EndIf;
		
		// Deselect
		If NOT IsBlankString(CurrentPageGuest) Then
			Items["FormGroupGuests"+CurrentPageGuest].BackColor = New Color(252,250,235);
			Items["FormDecorationTitleFIO_"+CurrentPageGuest].Font = New Font(,,False);
		EndIf;
		
		// Set is active                                                                        
		Items["FormGroupGuests"+pItem.Title].BackColor = WebColors.LightCyan; 
		Items["FormDecorationTitleFIO_"+pItem.Title].Font = New Font(,,True);
		CurrentPageGuest = pItem.Title;
		
		vFilter = GuestList.FindRows(New Structure("UID", pItem.Title));
		If vFilter.Count()>0 Then
			vRow = vFilter[0];
			
			ChangeRefAtServer(vRow.ClientDataScanRef);
			Object.ParentDoc = vRow.ParentDocument;
			FillScanConfigList();
			CreatePhotoBar(True); 
			RefreshDisplay();
		EndIf;	
	EndIf;
EndProcedure //  ClickGuest

// ----------------------------------------------------------------------------
&AtServerNoContext
Function GetYandexVisionIntegration(pHotel)
	Return Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionType(Enums.Integrations.YandexVision, pHotel);	
EndFunction // GetYandexVisionIntegration

// ----------------------------------------------------------------------------
&AtClient
Procedure TakePictureClick(pItem, pStandardProcessing)
	pStandardProcessing = False;
	vID = Number(StrReplace(pItem.Name, "FormFieldPhoto", ""));
	vRow = Object.ScanPictures.Get(vID);
	If Not ValueIsFilled(vRow.TempStorage) Then
		#IF MobileClient THEN
			vResult = Undefined;
			If MultimediaTools.PhotoSupported(DeviceCameraType.Rear) Then
				vResult = MultimediaTools.MakePhoto(DeviceCameraType.Rear, New DeviceCameraResolution(1080, 1920), 90, False, , , True);
				If vResult <> Undefined Then
					// Save photo data to the temp storage
					vBinaryData = vResult.GetBinaryData();
					vRow.TempStorage = PutToTempStorage(vBinaryData, ThisObject.UUID);
					Modified = True;
					
					// Try to retrieve data from the photo
					YandexVisionHandler(vBinaryData, vRow);
				Else
					tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Failed to take a picture!'; de = 'Das Bild konnte nicht aufgenommen werden!'; ru = 'Не удалось сделать снимок!'"));	
				EndIf;
			Else
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'This device does not support creating photos!'; de = 'Dieses Gerät unterstützt keine fotoerstellung!'; ru = 'Данное устройство не поддерживает создание фото!'"));
			EndIf;			
		#ENDIF
	EndIf;
EndProcedure

// ----------------------------------------------------------------------------
&AtClient
Procedure YandexVisionHandler(vResult, vRow)
	If (vResult <> Undefined) And (Number(tcOnServer.cmGetAttributeByRef(vRow.ScanConfiguration, "IdentityDocumentType.Code")) = 21) And Boolean(tcOnServer.cmGetAttributeByRef(vRow.ScanConfiguration, "RecognitionIsAvailable")) Then
		vInteractionParameters = GetYandexVisionIntegration(Object.Hotel);
		If vInteractionParameters <> Undefined Then
			// Refresh IAM-token if necessary
			vMessage = "";
			vIAMToken = tcOnServer.cmGetAttributeByRef(vInteractionParameters, "OAuth_RefreshToken");
			vIAMValidThru = tcOnServer.cmGetAttributeByRef(vInteractionParameters, "LastFullSynchronizationTime");
			If ((vIAMValidThru - CurrentDate()) / (60 * 60) < 8) Or Not ValueIsFilled(vIAMToken) Then
				tcYandexVision.ExchangeToken(vInteractionParameters, vMessage);
			EndIf;
			
			vRes = GetSizedPicture(vResult, vInteractionParameters);                                                             
		EndIf;
	EndIf;

EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Function GetSizedPicture(pResult, vInteractionParameters)
	vNewPic = New Picture(pResult);
	vPic = New ProcessingPicture(vNewPic);
	vPic.SetDensity(300, 300);
	vPic.SetSize(1920, 1080);
	vNewPic = vPic.GetPicture();
	vRes = tcYandexVision.RecognizeDocument(vInteractionParameters, GetBase64StringFromBinaryData(vNewPic.GetBinaryData()), "Good", );
	If vRes <> Undefined And vRes <> "" And vRes.Count() <> 0 Then    
		VS = New Structure;
		vRes.Property("Citizenship", Object.Citizenship);
		vRes.Property("DateOfBirth", Object.DateOfBirth);
		vRes.Property("FirstName", Object.FirstName);
		vRes.Property("IdentityDocumentIssueDate", Object.IdentityDocumentIssueDate);
		vRes.Property("IdentityDocumentSeries", Object.IdentityDocumentSeries);
		vRes.Property("IdentityDocumentUnitCode", Object.IdentityDocumentUnitCode);
		vRes.Property("IdentityDocumentValidToDate", Object.IdentityDocumentValidToDate);
		vRes.Property("LastName", Object.LastName);
		vRes.Property("IdentityDocumentIssuedBy", Object.IdentityDocumentIssuedBy);
		vRes.Property("PlaceOfBirth", Object.PlaceOfBirth);
		vRes.Property("SecondName", Object.SecondName);
		vRes.Property("Sex", Object.Sex);
		tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Data from the document has been read and filled in'; de = 'Die Daten aus dem Dokument wurden gelesen und ausgefüllt'; ru = 'Данные с документа были считаны и заполнены'"));
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Error when recognizing document content'; de = 'Fehler beim Erkennen des Dokumentinhalts'; ru = 'Ошибка при распознании содержания документа'"));
	EndIf;
	Return vRes;
	
EndFunction // GetSizedPicture

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
Procedure AddressStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vParameters = New Structure("Country, Address, AddressType", Object.Citizenship, TrimAll(Object.Address), "Address");
	OpenForm("CommonForm.tcInputAddress", vParameters, pItem, Object.Guest, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure //  AddressStartChoice

// ----------------------------------------------------------------------------
&AtClient
Procedure PlaceOfBirthStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vParameters = New Structure("Country, Address, AddressType", Object.Citizenship, TrimAll(Object.PlaceOfBirth), "PlaceOfBirth");
	OpenForm("CommonForm.tcInputAddress", vParameters, pItem, Object.Guest, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure //  PlaceOfBirthStartChoice

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
Procedure IdentityDocumentUnitCodeOnChange(pItem)
	If Not IsBlankString(Object.IdentityDocumentUnitCode) Then
		vIssuedByList = GetIssuedByListAtServer(TrimAll(Object.IdentityDocumentUnitCode), True);
		If vIssuedByList.Count() = 1 Then
			Object.IdentityDocumentIssuedBy = vIssuedByList.Get(0).Value;
		ElsIf vIssuedByList.Count() > 1 Then
			vNotifyDescription = New NotifyDescription("IdentityDocumentIssuedByIsChoosen", ThisObject);
			vParams = New Structure("ValueList, MultipleChoice, Title", vIssuedByList, False);
			OpenForm("CommonForm.mcChoiceValueList", vParams, ThisObject, UUID,,,vNotifyDescription);
		EndIf;
	EndIf;
	ResetFieldRecognitionQuality(pItem);
EndProcedure //  IdentityDocumentUnitCodeOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure ResidencePermitDocumentOnChange(pItem)
	ResidencePermitDocumentOnChangeAtServer();
EndProcedure //  ResidencePermitDocumentOnChange

#EndRegion

#Region FormCommandsEventHandlers

// ----------------------------------------------------------------------------
&AtClient
Procedure NewPhotoTakePictures(pCommand)
	#IF MobileClient THEN
		vResult = Undefined;
		If MultimediaTools.PhotoSupported(DeviceCameraType.Rear) Then
			vResult = MultimediaTools.MakePhoto(DeviceCameraType.Rear, New DeviceCameraResolution(480, 640), 90, False, , , True);
			If vResult <> Undefined Then
				vBinaryData = vResult.GetBinaryData();
				Photo = PutToTempStorage(vBinaryData, ThisObject.UUID);
				Modified = True;
			Else
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Failed to take a picture'; de = 'Das Bild konnte nicht aufgenommen werden'; ru = 'Не удалось сделать снимок'"));	
			EndIf;
		Else
			tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'This device does not support creating photos'; de = 'Dieses Gerät unterstützt keine fotoerstellung'; ru = 'Данное устройство не поддерживает создание фото'"));
		EndIf;
	#ENDIF      
EndProcedure // NewPhotoTakePictures

// ----------------------------------------------------------------------------
&AtClient
Procedure NewSignatureTakePictures(pCommand)
	#IF MobileClient THEN
		vResult = Undefined;
		If MultimediaTools.PhotoSupported(DeviceCameraType.Rear) Then
			vResult = MultimediaTools.MakePhoto(DeviceCameraType.Rear, New DeviceCameraResolution(640, 480), 90, False, , , True);
			If vResult <> Undefined Then
				vBinaryData = vResult.GetBinaryData();
				Signature = PutToTempStorage(vBinaryData, ThisObject.UUID);
				Modified = True;
			Else
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Failed to take a picture'; de = 'Das Bild konnte nicht aufgenommen werden'; ru = 'Не удалось сделать снимок'"));	
			EndIf;
		Else
			tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'This device does not support creating photos'; de = 'Dieses Gerät unterstützt keine fotoerstellung'; ru = 'Данное устройство не поддерживает создание фото'"));
		EndIf;
	#ENDIF
EndProcedure // NewSignatureTakePictures

// ----------------------------------------------------------------------------
&AtClient
Procedure NewPhotoClear(pCommand)
	Photo = Undefined;	
EndProcedure //  NewPhotoClear

// ----------------------------------------------------------------------------
&AtClient
Procedure NewSignatureClear(pCommand)
	Signature = Undefined;
EndProcedure //  NewSignatureClear

// ----------------------------------------------------------------------------
&AtClient
Procedure NewSignatureGallery(pCommand)
	#IF MobileClient THEN   
		// ACC:561-off
		vFileSelection = New FileDialog(FileDialogMode.Open);
		vFileSelection.Multiselect = False;
		vFileSelection.Directory = MobileDeviceLibraryDir(MobileDeviceLibraryDirType.Pictures); 
		vFileSelection.Filter = NStr("ru = 'Картинки (*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf)|*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf|" +
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
		vFileSelection.Show(New NotifyDescription("AfterChooseNewSignatureGallery", ThisObject));  
		// ACC:561-on
	#ENDIF
EndProcedure //  NewSignatureGallery

// ----------------------------------------------------------------------------
&AtClient
Procedure ShowGroupGuestPageList(pCommand)
	Items.GroupPageList.Visible = False;
	Items.Pages.Visible = False; 
	Items.GroupGuestPageList.Visible = True;
	Items.Group1.Visible = False;
	Items.FormShowPageList.Visible = True;
	Items.FormShowGuestDetails.Visible = True;
	Items.FormShowGroupGuestPageList.Visible = False;
EndProcedure //  ShowGroupGuestPageList

// ----------------------------------------------------------------------------
&AtClient
Procedure ShowPageList(pCommand)
	Items.GroupPageList.Visible = True;
	Items.Group1.Visible = False;
	Items.Pages.Visible = False;
	Items.GroupGuestPageList.Visible = False;
	Items.FormShowPageList.Visible = False;
	Items.FormShowGuestDetails.Visible = True;
	Items.FormShowGroupGuestPageList.Visible = True;
EndProcedure //  ShowPageList

// ----------------------------------------------------------------------------
&AtClient
Procedure ShowGuestDetails(pCommand)
	Items.Group1.Visible = True;
	Items.GroupPageList.Visible = False;
	Items.Pages.Visible = True;
	Items.GroupGuestPageList.Visible = False;
	Items.FormShowPageList.Visible = True;
	Items.FormShowGuestDetails.Visible = False;
	Items.FormShowGroupGuestPageList.Visible = True;	
EndProcedure //  ShowGuestDetails

// ----------------------------------------------------------------------------
&AtClient
Procedure NewPhotoGallery(pCommand)
	#IF MobileClient THEN      
		// ACC:561-off
		vFileSelection = New FileDialog(FileDialogMode.Open);
		vFileSelection.Multiselect = False;
		vFileSelection.Directory = MobileDeviceLibraryDir(MobileDeviceLibraryDirType.Pictures); 
		vFileSelection.Filter = NStr("ru = 'Картинки (*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf)|*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf|" +
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
		vFileSelection.Show(New NotifyDescription("AfterChooseNewPhotoGallery", ThisObject));  
		// ACC:561-on
	#ENDIF
EndProcedure //  NewPhotoGallery

// ----------------------------------------------------------------------------
&AtClient
Procedure Copy(pCommand)
	If ValueIsFilled(Object.Ref) Then
		OpenForm("Document.ClientDataScans.ObjectForm", New Structure("CopyingValue, ParentDoc, GuestGroup, Room, Guest", Object.Ref, Object.ParentDoc, Object.GuestGroup, Object.Room, Object.Guest), , Object.Ref);
		SilentCloseMode = True;
		ThisObject.Close();
	Else
		tcCommonFunctionOnClientServer.UserMessage("en='Save document first!'; ru='Сначала сохраните документ!'; de='Speichern Sie das Dokument zuerst!'");
	EndIf;
EndProcedure //  Copy

// ----------------------------------------------------------------------------
&AtClient
Procedure Clear(pCommand)
	ClearAtServer();
EndProcedure //  Clear

// ----------------------------------------------------------------------------
&AtClient
Procedure Post(pCommand)
	CheckClient();	
EndProcedure //  Post

// ----------------------------------------------------------------------------
&AtClient
Procedure RotationLeftClick(pCommand)
	pStandardProcessing = False;
	vID = Number(StrReplace(pCommand.Name,"RotationLeft",""));
	vRow = Object.ScanPictures.Get(vID);
	If ValueIsFilled(vRow.TempStorage) Then
		vNewTempStorage = RotationPictures(vRow.TempStorage, 90);
		If ValueIsFilled(vNewTempStorage) Then 
			DeleteFromTempStorage(vRow.TempStorage);
			vRow.TempStorage = vNewTempStorage;
			Modified = True;
		EndIf;
	EndIf;
EndProcedure //  RotationLeftClick

// ----------------------------------------------------------------------------
&AtClient
Procedure RotationRightClick(pCommand)
	pStandardProcessing = False;
	vID = Number(StrReplace(pCommand.Name,"RotationRight",""));
	vRow = Object.ScanPictures.Get(vID);
	If ValueIsFilled(vRow.TempStorage) Then
		vNewTempStorage = RotationPictures(vRow.TempStorage, -90);
		If ValueIsFilled(vNewTempStorage) Then 
			DeleteFromTempStorage(vRow.TempStorage);
			vRow.TempStorage = vNewTempStorage;
			Modified = True;
		EndIf;
	EndIf;
EndProcedure //  RotationRightClick

// ----------------------------------------------------------------------------
&AtClient
Procedure CopyButtonClick(pCommand)
	vID = Number(StrReplace(pCommand.Name,"Copy",""));	
	vRow = Object.ScanPictures.Get(vID);
	vNewRow = Object.ScanPictures.Add();
	vNewRow.ScanConfiguration = vRow.ScanConfiguration;
	vNewRow.RecognitionIsAvailable = vRow.RecognitionIsAvailable; 	
	CreatePhotoBar();
	Modified = True;
EndProcedure //  CopyButtonClick

// ----------------------------------------------------------------------------
&AtClient
Procedure DeleteButtonClick(pCommand)
	vID = Number(StrReplace(pCommand.Name,"Delete",""));		
	vRow = Object.ScanPictures.Get(vID);	
	If Object.ScanPictures.FindRows(New Structure("ScanConfiguration", vRow.ScanConfiguration)).Count() = 1 Then
		vRow.TempStorage = "";
	Else
		Object.ScanPictures.Delete(vID);
		CreatePhotoBar();	
	EndIf;
	Modified = True;
EndProcedure //  DeleteButtonClick

// ----------------------------------------------------------------------------
&AtClient
Procedure LoadPictureClick(pCommand)
	vID = Number(StrReplace(pCommand.Name,"LoadPicture",""));
	#IF MobileClient THEN    
		// ACC:561-off
		vFileSelection = New FileDialog(FileDialogMode.Open);
		vFileSelection.Multiselect = False;
		vFileSelection.Directory = MobileDeviceLibraryDir(MobileDeviceLibraryDirType.Pictures); 
		vFileSelection.Filter = NStr("ru = 'Картинки (*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf)|*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf|" +
		"bmp (*.bmp;*.dib;*.rle)|*.bmp;*.dib;*.rle|" + 
		"JPEG (*.jpg;*.jpeg)|*.jpg;*.jpeg|" + 
		"TIFF (*.tif)|*.tif|" + 
		"GIF (*.gif)|*.gif|" + 
		"PNG (*.png)|*.png|" + 
		"icon (*.ico)|*.ico|" + 
		"метафайл (*.wmf;*.emf)|*.wmf;*.emf|'; 
		|de = 'Bilden (*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf)|*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf|" +
		"bmp (*.bmp;*.dib;*.rle)|*.bmp;*.dib;*.rle|" + 
		"JPEG (*.jpg;*.jpeg)|*.jpg;*.jpeg|" + 
		"TIFF (*.tif)|*.tif|" + 
		"GIF (*.gif)|*.gif|" + 
		"PNG (*.png)|*.png|" + 
		"icon (*.ico)|*.ico|" + 
		"metafile (*.wmf;*.emf)|*.wmf;*.emf|'; 
		|en = 'Pictures (*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf)|*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf|" +
		"bmp (*.bmp;*.dib;*.rle)|*.bmp;*.dib;*.rle|" + 
		"JPEG (*.jpg;*.jpeg)|*.jpg;*.jpeg|" + 
		"TIFF (*.tif)|*.tif|" + 
		"GIF (*.gif)|*.gif|" + 
		"PNG (*.png)|*.png|" + 
		"icon (*.ico)|*.ico|" + 
		"metafile (*.wmf;*.emf)|*.wmf;*.emf|'");
		vFileSelection.Show(New NotifyDescription("AfterChooseLoadPictureClick", ThisObject, vID));
		
		// ACC:561-on
	#ENDIF
EndProcedure //  LoadPictureClick

#EndRegion

#Region Private

// ----------------------------------------------------------------------------
&AtServer
Procedure ClearEmptyRow()
	vNum = 0;
	While vNum <= Object.ScanPictures.Count() - 1 Do
		vRow = Object.ScanPictures.Get(vNum);
		If not ValueIsFilled(vRow.TempStorage) Then
			Object.ScanPictures.Delete(vRow.LineNumber-1);
		Else
			vNum = vNum + 1;	
		EndIf;	
	EndDo;	
EndProcedure //  ClearEmptyRow

// ----------------------------------------------------------------------------
&AtServer
Procedure FillScanConfigList()
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	ScanConfigurations.Ref
	|FROM
	|	Catalog.ScanConfigurations AS ScanConfigurations
	|WHERE
	|	NOT ScanConfigurations.DeletionMark
	|	AND ScanConfigurations.IsForeigner = &IsForeigner";	
	vQuery.SetParameter("IsForeigner", ?(IsForeigner = 0,False, True));	
	QueryResult = vQuery.Execute();	
	SelectionDetailRecords = QueryResult.Select();	
	While SelectionDetailRecords.Next() Do
		If Object.ScanPictures.FindRows(New Structure("ScanConfiguration",SelectionDetailRecords.ref)).Count() = 0 Then
			vNewRow = Object.ScanPictures.Add();
			vNewRow.ScanConfiguration = SelectionDetailRecords.ref;
		EndIf;
	EndDo;
EndProcedure //  FillScanConfigList

// ----------------------------------------------------------------------------
&AtServer
Procedure FillTempStorage()
	vObject = FormAttributeToValue("Object");		
	For Each vDocPhoto In vObject.ScanPictures Do
		vPic = vDocPhoto.ScanPicture.Get();
		If vPic <> Undefined and not ValueIsFilled(Object.ScanPictures.Get(vDocPhoto.LineNumber-1).TempStorage) then
			vRow = Object.ScanPictures.Get(vDocPhoto.LineNumber-1);
			vRow.TempStorage = PutToTempStorage(vDocPhoto.ScanPicture.Get(), ThisObject.UUID);
			vRow.RecognitionIsAvailable = vRow.ScanConfiguration.RecognitionIsAvailable; 
		EndIf;
	EndDo;
EndProcedure //  FillTempStorage

// ----------------------------------------------------------------------------
&AtServer
Function CreatePhotoBar(pNew = False)
	While Items.GroupPageList.ChildItems.Count() > 0 Do
		Commands.Delete(Commands["Delete" + StrReplace(Items.GroupPageList.ChildItems[0].Name,"FormGroupCard","")]);
		Commands.Delete(Commands["Copy" + StrReplace(Items.GroupPageList.ChildItems[0].Name,"FormGroupCard","")]);
		Commands.Delete(Commands["LoadPicture" + StrReplace(Items.GroupPageList.ChildItems[0].Name,"FormGroupCard","")]);
		Commands.Delete(Commands["RotationLeft" + StrReplace(Items.GroupPageList.ChildItems[0].Name,"FormGroupCard","")]);
		Commands.Delete(Commands["RotationRight" + StrReplace(Items.GroupPageList.ChildItems[0].Name,"FormGroupCard","")]);
		
		Items.Delete(Items.GroupPageList.ChildItems[0]);
	EndDo;
	If pNew Then	
		FillTempStorage();
	EndIf;
	For Each vDocPhoto In Object.ScanPictures Do	
		CreateCard(vDocPhoto);
	EndDo;
EndFunction //  CreatePhotoBar

// ----------------------------------------------------------------------------
&AtServer
Procedure GetGuestListByRoom()
	If ValueIsFilled(Object.ParentDoc) Then
		vNumber = TrimAll(Object.ParentDoc.Number);
		vGuestGroup = Object.ParentDoc.GuestGroup;
		objGuestGroup = vGuestGroup.GetObject();
		vAccList = objGuestGroup.pmGetAccommodations();
		For Each vAcc In vAccList Do
			If vAcc.Number = vNumber Then
				vRow = GuestList.Add();
				If vAcc.Guest = Object.Guest Then
					If Object.Ref.isEmpty() Then
						Write();
					EndIf;	
					vRow.ClientDataScanRef = Object.Ref;
					vRow.ParentDocument = Object.ParentDoc;
					vRow.Guest = Object.Guest;
				Else	
					vRow.ClientDataScanRef = GetClientDataScanDocument(vAcc.Accommodation);
					vRow.ParentDocument = vAcc.Accommodation;
					vRow.Guest = vRow.ClientDataScanRef.Guest;
				EndIf;
				vRow.UID = StrReplace(String(?(ValueIsFilled(vRow.Guest), vRow.Guest.UUID(), New UUID())),"-","_");
			EndIf;
		EndDo;
		vResList = objGuestGroup.pmGetReservations(True, True);
		For Each vRes In vResList Do
			If vRes.Number = vNumber And Not vRes.Status.IsCheckIn Then
				vGuest = vRes.Guest;
				vFilter = GuestList.FindRows(New Structure("Guest", vGuest));
				If vFilter.Count() > 0 Then
					Continue;
				EndIf;	
				vRow = GuestList.Add();
				If vGuest = Object.Guest Then
					If Object.Ref.isEmpty() Then
						Write();
					EndIf;	
					vRow.ClientDataScanRef = Object.Ref;
					vRow.ParentDocument = Object.ParentDoc;
					vRow.Guest = Object.Guest;
				Else	
					vRow.ClientDataScanRef = GetClientDataScanDocument(vRes.Reservation);
					vRow.ParentDocument = vRes.Reservation;
					vRow.Guest = vRow.ClientDataScanRef.Guest;
				EndIf;
				vRow.UID = StrReplace(String(?(ValueIsFilled(vRow.Guest), vRow.Guest.UUID(), New UUID())),"-","_");
			EndIf;
		EndDo;
		vFilter = GuestList.FindRows(New Structure("Guest",Object.Guest));
		If vFilter.Count() = 0 Then
			vRow = GuestList.Add();
			vRow.ClientDataScanRef = GetClientDataScanDocument(Object.ParentDoc);
			vRow.Guest = vRow.ClientDataScanRef.Guest;
			vRow.UID = StrReplace(String(?(ValueIsFilled(vRow.Guest), vRow.Guest.UUID(), New UUID())),"-","_");
		EndIf;	
	Else
		If ValueIsFilled(Object.Guest) Then
			vRow = GuestList.Add();
			vRow.Guest = Object.Guest;
			vRow.UID = StrReplace(String(?(ValueIsFilled(vRow.Guest), vRow.Guest.UUID(), New UUID())),"-","_");
			vRow.ClientDataScanRef = Object.Ref;
		EndIf;
	EndIf;	
EndProcedure //  GetGuestListByRoom

// ----------------------------------------------------------------------------
&AtServer
Procedure FillPresentationGuestList()
	For Each vRowGuest In GuestList Do
		vID = vRowGuest.UID;
		vCardGroup = tcOnServer.cmCreateItem(ThisObject, Items.GroupGuestPageList, "Guests" + vID, "FormGroup",
		New Structure("Type, Title, BackColor, Group, ShowTitle, HorizontalStretch, VerticalStretch, ChildItemsVerticalAlign",
		FormGroupType.UsualGroup, vRowGuest.Guest, New Color(252,250,235), ChildFormItemsGroup.AlwaysHorizontal, False, True, False, ItemVerticalAlign.Top));
		
		vAtrArr = New Array;
		vArrTypes = New Array;
		vArrTypes.Add(Тип("Строка"));
		vAtr = New FormAttribute("Photo" + vID, New TypeDescription(vArrTypes), , "Photo", True);
		vAtrArr.Add(vAtr);
		ChangeAttributes(vAtrArr);
		
		ThisObject["Photo" + vID] = PutToTempStorage(vRowGuest.ClientDataScanRef.Photo.Get(), New UUID);
		
		tcOnServer.cmCreateItem(ThisObject, vCardGroup, "Photo" + vID, "FormField",
		New Structure("Type, DataPath, HorizontalStretch, VerticalStretch, PictureSize, Title, SetActionClick, Hyperlink, TitleLocation, VerticalStretch, NonselectedPictureText, VerticalAlignInGroup, HorizontalAlignInGroup",
		FormFieldType.PictureField, "Photo" + vID, False, False, PictureSize.Proportionally, vID, "ClickGuest", True, FormItemTitleLocation.None, False, NStr("en='Click to switch to this guest'; ru='Нажмите для переключения на этого гостя'; de='Klicken Sie hier, um zu diesem Gast zu wechseln'"), ItemVerticalAlign.Bottom, ItemHorizontalLocation.Left));
		
		Items["FormField" + "Photo" + vID].Width = 9;
		
		vExtraGroup = tcOnServer.cmCreateItem(ThisObject, vCardGroup, "ExtraGroup" + vID, "FormGroup",
		New Structure("Type, Title, ShowTitle, Group, ShowTitle, HorizontalStretch, VerticalStretch, ChildItemsVerticalAlign, VerticalAlignInGroup, HorizontalAlignInGroup, ChildItemsHorizontalAlign",
		FormGroupType.UsualGroup, "ExtraGroup", False,  ChildFormItemsGroup.Vertical, False, True, True, ItemVerticalAlign.Top, ItemVerticalAlign.Top, ItemHorizontalLocation.Left, ItemHorizontalLocation.Center));
		
		//vExtraGroup.Width = 20;
		
		vSmallGroup = tcOnServer.cmCreateItem(ThisObject, vExtraGroup, "SmallGroup" + vID, "FormGroup",
		New Structure("Type, Title, ShowTitle, Group, ShowTitle, HorizontalStretch, VerticalStretch, VerticalAlignInGroup, ChildItemsVerticalAlign, ChildItemsHorizontalAlign, HorizontalAlignInGroup, Height",
		FormGroupType.UsualGroup, "SmallGroup", False,  ChildFormItemsGroup.AlwaysHorizontal, False, False, False, ItemVerticalAlign.Top, ItemVerticalAlign.Top, ItemHorizontalLocation.Center, ItemHorizontalLocation.Center, 1));
		
		vPicSex = PictureLib.Empty;
		If ValueIsFilled(vRowGuest.Guest) Then
			vGuestSex = vRowGuest.Guest.Sex;
			If vGuestSex = Enums.Sex.Female Then
				vPicSex = PictureLib.Female;
			Else
				vPicSex = PictureLib.Male;
			EndIf;
		EndIf;
		tcOnServer.cmCreateItem(ThisObject, vSmallGroup, "Sex_" +  vID, "FormDecoration", 
		New Structure("Type, Title, Picture, VerticalAlignInGroup, HorizontalAlignInGroup, Height", 
		FormDecorationType.Picture, "Sex_"+vID, vPicSex, ItemVerticalAlign.Top, ItemHorizontalLocation.Center, 1));
		
		tcOnServer.cmCreateItem(ThisObject, vSmallGroup, "TitleFIO_" +  vID, "FormDecoration", 
		New Structure("Type, Title, HorizontalStretch, HorizontalAlign, Height, VerticalAlignInGroup, HorizontalAlignInGroup", 
		FormDecorationType.Label, vRowGuest.Guest, True, ItemHorizontalLocation.Center, 0, ItemVerticalAlign.Top, ItemHorizontalLocation.Center));
		
		tcOnServer.cmCreateItem(ThisObject, vExtraGroup, "TitleAgeSex_" +  vID, "FormDecoration", 
		New Structure("Type, Title,  HorizontalStretch, HorizontalAlign, Height, VerticalAlignInGroup", 
		FormDecorationType.Label, Format(vRowGuest.Guest.DateOfBirth, "DLF=D"), True, ItemHorizontalLocation.Center, 0, ItemVerticalAlign.Top));
		
		tcOnServer.cmCreateItem(ThisObject, vExtraGroup, "TitleFIOfull" +  vID, "FormDecoration", 
		New Structure("Type, Title,  HorizontalStretch, HorizontalAlign, Height, VerticalAlignInGroup", 
		FormDecorationType.Label, vRowGuest.Guest.LastName + " " + vRowGuest.Guest.FirstName + " " + vRowGuest.Guest.SecondName, True, ItemHorizontalLocation.Center, 0, ItemVerticalAlign.Top)); 
		//
		//tcOnServer.cmCreateItem(ThisObject, vExtraGroup, "Empty" +  vID, "FormDecoration", 
		//New Structure("Type, Title,  HorizontalStretch, HorizontalAlign, Height, VerticalAlignInGroup", 
		//FormDecorationType.Label, " ", True, ItemHorizontalLocation.Center, 2, ItemVerticalAlign.Top));

		
	EndDo;
EndProcedure //  FillPresentationGuestList

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
		IsForeigner = Object.Hotel.Citizenship <> Object.Citizenship;
	EndIf;
	EditTopGroupHeader();
	VisumDataAppearance();
	Photo = PutToTempStorage(vObject.Photo.Get(), New UUID);
	Signature = PutToTempStorage(vObject.Signature.Get(), New UUID);
EndProcedure //  ChangeRefAtServer

// ----------------------------------------------------------------------------
&AtServer
Function CreateCard(pRow)
	vID = Format(pRow.LineNumber - 1, "NZ=; NG=");
	vCardGroup = tcOnServer.cmCreateItem(ThisObject,Items.GroupPageList,"Card" + vID,"FormGroup",
	New Structure("Type, Title, BackColor, Group, ShowTitle, HorizontalStretch, VerticalStretch",
	FormGroupType.UsualGroup, pRow.ScanConfiguration, New Color(252,250,235), ChildFormItemsGroup.Vertical, False, True, True));
	
	tcOnServer.cmCreateItem(ThisObject , vCardGroup, "Title" +  vID, "FormDecoration", 
	New Structure("Type, Title, HorizontalStretch, HorizontalAlign, Height", 
	FormDecorationType.Label, pRow.ScanConfiguration, True,ItemHorizontalLocation.Center, 2));
	
	tcOnServer.cmCreateItem(ThisObject, vCardGroup, "Photo" + vID, "FormField",
	New Structure("Type, DataPath, HorizontalStretch, PictureSize, Title, SetActionClick, Hyperlink, TitleLocation, VerticalStretch, NonselectedPictureText",
	              FormFieldType.PictureField, "Object.ScanPictures[" + vID + "].TempStorage", True, PictureSize.Proportionally, vID, "TakePictureClick", True, FormItemTitleLocation.None, True, NStr("en='Take document page picture'; ru='Нажмите, чтобы сфотографировать страницу документа'; de='Hier klicken, um ein Bild von der Dokumentseite zu machen'")));					  
	Items["FormField" + "Photo" + vID].VerticalStretch = False;
	Items["FormField" + "Photo" + vID].Height = 10; 	
	vButtonGroup = tcOnServer.cmCreateItem(ThisObject,vCardGroup,"ButtonGroupPictureCommands" + vID, "FormGroup",
	New Structure("Type, ShowTitle, HorizontalStretch, Group",
	FormGroupType.UsualGroup, False, True, ChildFormItemsGroup.AlwaysHorizontal));
	
	vCommand = Commands.Add("LoadPicture" + vID);
	vCommand.Action = "LoadPictureClick";
	vStructure = New Structure("Title, CommandName, Type, Picture, Representation, HorizontalAlignInGroup, Width, HorizontalStretch",
	NStr("en='Load from gallery'; ru='Загрузить из галереи'; de='Laden aus der Galerie'"), "LoadPicture" + vID, FormButtonType.CommandBarButton, PictureLib.OpenFile, ButtonRepresentation.Picture, ItemHorizontalLocation.Center, 5, True);
	tcOnServer.cmCreateItem(ThisObject, vButtonGroup, "LoadPicture" + vID, "FormButton", vStructure);
	
	vCommand = Commands.Add("RotationLeft" + vID);
	vCommand.Action = "RotationLeftClick";
	vStructure = New Structure("Title, CommandName, Type, Picture, Representation, HorizontalAlignInGroup, Width, HorizontalStretch",
	NStr("en='Rotation left'; ru='Поворот налево'; de='Drehung Links'"), "RotationLeft" + vID, FormButtonType.CommandBarButton, PictureLib.FindPrevious, ButtonRepresentation.Picture, ItemHorizontalLocation.Center, 5, True);
	tcOnServer.cmCreateItem(ThisObject, vButtonGroup, "RotationLeft" + vID, "FormButton", vStructure);
	
	vCommand = Commands.Add("Copy" + vID);
	vCommand.Action = "CopyButtonClick";
	vStructure = New Structure("Title, CommandName, Type, Picture, Representation, HorizontalAlignInGroup, Width, HorizontalStretch",
	NStr("en='Copy'; ru='Копировать'; de='Kopieren'"), "Copy" + vID, FormButtonType.CommandBarButton, PictureLib.CreateListItem, ButtonRepresentation.Picture, ItemHorizontalLocation.Center, 5, True);
	tcOnServer.cmCreateItem(ThisObject, vButtonGroup, "Copy" + vID, "FormButton", vStructure);
	
	vCommand = Commands.Add("RotationRight" + vID);
	vCommand.Action = "RotationRightClick";
	vStructure = New Structure("Title, CommandName, Type, Picture, Representation, HorizontalAlignInGroup, Width, HorizontalStretch",
	NStr("en='Rotation right'; ru='Поворот вправо'; de='Drehung rechts'"), "RotationRight" + vID, FormButtonType.CommandBarButton, PictureLib.FindNext, ButtonRepresentation.Picture, ItemHorizontalLocation.Center, 5, True);
	tcOnServer.cmCreateItem(ThisObject, vButtonGroup, "RotationRight" + vID, "FormButton", vStructure);
	
	vCommand = Commands.Add("Delete" + vID);
	vCommand.Action = "DeleteButtonClick";
	vStructure = New Structure("Title, CommandName, Type, Picture, Representation, HorizontalAlignInGroup, Width, HorizontalStretch",
	NStr("en='Delete'; ru='Удалить'; de='Löschen'"), "Delete" + vID, FormButtonType.CommandBarButton, PictureLib.Close, ButtonRepresentation.Picture, ItemHorizontalLocation.Center, 5, True);
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
&AtServer
Function RotationPictures(pTempStorage, pAngle)
	vNewTempStorage = "";
	vPic = GetFromTempStorage(pTempStorage);
	If TypeOf(vPic) = Type("BinaryData") Then
		vPicture = New Picture(vPic);
	ElsIf TypeOf(vPic) = Type("Picture") Then 	
		vPicture = vPic;
	EndIf;
	Try
		Execute("vProcessingPicture = New ProcessingPicture(vPicture);
		|vProcessingPicture.Rotate(pAngle);
		|vNewTempStorage = PutToTempStorage(vProcessingPicture.GetPicture(), UUID);");
	Except
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='This function is supported starting from 1C:Enterprise platform version 8.3.14!'; ru='Данная функция поддерживается начиная с платформы 1С: Предприятие версии 8.3.14!'; de='Diese Funktion wird ab 1C: Enterprise Platform Version 8.3.14 unterstützt!'"));
	EndTry;
	Return vNewTempStorage; 
EndFunction //  RotationPictures

// ----------------------------------------------------------------------------
&AtClient
Procedure AfterChooseLoadPictureClick(pFile, pID) Export
	If pFile <> Undefined Then
		vRow = Object.ScanPictures.Get(pID);
		vBinaryData = New BinaryData(pFile[0]);
		vRow.TempStorage = PutToTempStorage(vBinaryData, UUID);
		YandexVisionHandler(vBinaryData, vRow);
		Modified = True;	
	EndIf;
EndProcedure //  AfterChooseLoadPictureClick

// ----------------------------------------------------------------------------
&AtClient
Procedure ResetFieldRecognitionQuality(pField)
	For  Each vItem In Object.RecognitionQuality Do
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
		IsForeigner = Object.Hotel.Citizenship <> Object.Citizenship;
		ClearEmptyRow();
		FillScanConfigList();
		CreatePhotoBar();
	EndIf;
EndProcedure //  CitizenshipOnChangeAtServer

// ----------------------------------------------------------------------------
&AtServer
Procedure EditTopGroupHeader()
	If ValueIsFilled(Object.Guest) Then
		Title = "" + Object.Status + ", " + Object.Guest.FullName + ", " + Nstr("en = 'Room: '; de = 'Zimmernummer: '; ru = 'Номер: '") + Object.Room + ", " + NStr("en = 'Group: '; de = 'Gruppe: '; ru = 'Группа: '") + Object.GuestGroup;
	Else
		Title = "" + Object.Status + ", " + Object.FirstName + ", " + Nstr("en = 'Room: '; de = 'Zimmernummer: '; ru = 'Номер: '") + Object.Room + ", " + NStr("en = 'Group: '; de = 'Gruppe: '; ru = 'Группа: '") + Object.GuestGroup;
	EndIf;
	If Object.Status = Enums.ScanStatuses.IsProcessed Then
		Items.FormWrite.Enabled = False;
	Else
		Items.FormWrite.Enabled = True;
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
				If vRQRow.Quality > 80 Then
					Items[Title(vRQRow.Field)].BackColor = WEBColors.LightGoldenrod; 
				Else
					Items[Title(vRQRow.Field)].BackColor = WEBColors.LightSalmon; 
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	If ValueIsFilled(Object.Guest) Then
		ThisObject["Photo"+ StrReplace(Object.Guest.UUID(),"-","_")] = Photo;
	EndIf;	
EndProcedure //  RefreshDisplay

// ----------------------------------------------------------------------------
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
		New Structure("Type, DataPath, Title, TypeRestriction",
		FormFieldType.InputField, "Characteristics[" + vID + "].CharacteristicValue", Characteristic.Characteristic, Characteristic.Characteristic.ValueType));
	EndDo;
EndProcedure //  FillExtraData

// ----------------------------------------------------------------------------
&AtServer
Procedure IsForeignerOnChangeAtServer()
	If IsForeigner = 0 And ValueIsFilled(Object.Hotel) Then
		Object.Citizenship = Object.Hotel.Citizenship;
	ElsIf Not ValueIsFilled(Object.Citizenship) Or IsForeigner = 2 Or ValueIsFilled(Object.Guest) And Not ValueIsFilled(Object.Guest.Citizenship) And IsForeigner = 1 Then
		tcCommonFunctionOnClientServer.UserMessage("Заполните гражданство", Object.Citizenship, "Object.Citizenship",, True); 
		Object.Citizenship = Undefined;
	ElsIf ValueIsFilled(Object.Guest) Then
		Object.Citizenship = Object.Guest.Citizenship;
	EndIf;
	ClearEmptyRow();
	FillScanConfigList();
	CreatePhotoBar();
EndProcedure //  IsForeignerOnChangeAtServer 

// ----------------------------------------------------------------------------
&AtServer
Procedure ClearAtServer()
	Object.RecognitionQuality.Clear();
	Object.ScanPictures.Clear();
	vEmptyDoc = Documents.ClientDataScans.CreateDocument();
	FillPropertyValues(Object, vEmptyDoc, , "Number, Date, Author, Hotel, Status, ParentDoc, GuestGroup, Guest, Room, Remarks, ScanPictures, RecognitionQuality"); 
	FillScanConfigList();
	CreatePhotoBar(True); 
	FillExtraData();
	RefreshDisplay();
	Modified = True;
EndProcedure //  ClearAtServer

// ----------------------------------------------------------------------------
&AtClient
Procedure CheckClient()
	vClientsDouble = ExistCopyClients(Object.IdentityDocumentSeries, Object.IdentityDocumentNumber, Object.Guest);
	If vClientsDouble > 0 Then
		vMessage = NStr("en='" + Format(vClientsDouble, "ND=6; NFD=0; NZ=") + " client(s) found with the same identity document data!
		|You can use one of those clients by choosing him in the table being shown later...'; 
		|de='" + Format(vClientsDouble, "ND=6; NFD=0; NZ=") + " client(s) found with the same identity document data!
		|You can use one of those clients by choosing him in the table being shown later...'; 
		|ru='В базе данных найдено " + Format(vClientsDouble, "ND=6; NFD=0; NZ=") + " клиент(ов) с совпадающими данными документа удостоверяющего личность!
		|Вы можете использовать одного из этих клиентов, если выберите его в таблице, которая будет сейчас показана на экран...'");
		tcCommonFunctionOnClientServer.UserMessage(vMessage);
		OpenListFormClients();
	Else
		Object.Status = PredefinedValue("Enum.ScanStatuses.IsProcessed");
		Object.RecognitionQuality.Clear();
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
		EndIf;
	EndIf;
EndProcedure //  CheckClient

// ----------------------------------------------------------------------------
&AtClient
Procedure OpenListFormClients()
	OpenForm("Catalog.Clients.Form.mcListForm", 
	New Structure("ChoiceMode, Hotel, SelIdentityDocumentNumber, SelIdentityDocumentSeries", True, Object.Hotel, Object.IdentityDocumentNumber, Object.IdentityDocumentSeries), 
	ThisObject,
	ThisObject.UUID, , , 
	New NotifyDescription("ContinuePost", ThisObject), 
	FormWindowOpeningMode.LockOwnerWindow);
EndProcedure //  OpenListFormClients

// ----------------------------------------------------------------------------
&AtClient
Procedure ContinuePost(Result, AdditionalParameters1 = Undefined) Export
	Object.Status = PredefinedValue("Enum.ScanStatuses.IsProcessed");
	Object.RecognitionQuality.Clear();
	
	If ValueIsFilled(Result) Then
		Object.Guest = Result;
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

// ----------------------------------------------------------------------------
// Description: Returns client's list with given identity document number and series
// Parameters: Identity document series, Identity document number
// Return value: Value list of clients
// ----------------------------------------------------------------------------
&AtServer
Function ExistCopyClients(pIDSeries, pIDNumber, pClientToSkip) 
	If IsBlankString(pIDNumber) Then
		Return 0;
	EndIf; 
	
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Clients.Ref
	|FROM
	|	Catalog.Clients AS Clients
	|WHERE
	|	Clients.IdentityDocumentNumber = &qIDNumber
	|	AND Clients.IdentityDocumentSeries = &qIDSeries
	|	AND Clients.Ref <> &qClient
	|	AND NOT Clients.DeletionMark
	|	AND NOT Clients.IsFolder
	|
	|ORDER BY
	|	Clients.Description";
	vQry.SetParameter("qIDSeries", TrimAll(pIDSeries));
	vQry.SetParameter("qIDNumber", TrimAll(pIDNumber));
	vQry.SetParameter("qClient", pClientToSkip);
	vQryRes = vQry.Execute().Select();
	Return vQryRes.Count();
EndFunction //  ExistCopyClients

// ----------------------------------------------------------------------------
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
	If Left(InfoBaseConnectionString(), 5) = "File=" Then
		Return vIssuedByList;
	EndIf;
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
		Object.ForEducationPurposes = False;
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
&AtClient
Procedure AfterChooseNewPhotoGallery(pFile, pExtaParams) Export
	If pFile <> Undefined Then
		vBinaryData = New BinaryData(pFile[0]);
		Photo = PutToTempStorage(vBinaryData, UUID);
		Modified = True;
	EndIf;
EndProcedure //  AfterChooseNewPhotoGallery

// ----------------------------------------------------------------------------
&AtClient
Procedure AfterChooseNewSignatureGallery(pFile, pExtaParams) Export
	If pFile <> Undefined Then
		vBinaryData = New BinaryData(pFile[0]);
		Signature = PutToTempStorage(vBinaryData, UUID);
		Modified = True;
	EndIf;
EndProcedure //  AfterChooseNewPhotoGallery

#EndRegion
