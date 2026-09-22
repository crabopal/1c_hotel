
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	If Object.SplitFolioBalanceByPaymentSections Then
		SplitFolioBalanceBy = 1;
	ElsIf Object.SplitFolioBalanceByServicesAndPrices Then
		SplitFolioBalanceBy = 2;
	Else
		SplitFolioBalanceBy = 0;
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Get pictures
	If Not Object.Ref.IsEmpty() Then
		// Get logo
		Logo = PutToTempStorage(tcOnServer.cmGetBinaryDataByRef(Object.Ref, "Logo"), UUID);	
		// Load signatures
		DirectorSignature = PutToTempStorage(tcOnServer.cmGetBinaryDataByRef(Object.Ref, "DirectorSignature"), UUID);
		AccountantGeneralSignature = PutToTempStorage(tcOnServer.cmGetBinaryDataByRef(Object.Ref, "AccountantGeneralSignature"), UUID);
		// Color
		vColor = StyleColors.BackgroundColorImportant;
		Items.FormSetColor.BackColor = Items.FormClearColor.BackColor;
		If Not IsBlankString(Object.ColorString) Then
			Try
				vColor = XDTOSerializer.XMLValue(Type("Color"), TrimAll(Object.ColorString));
				Items.FormSetColor.BackColor = vColor;
			Except
				vColor = StyleColors.BackgroundColorImportant;
			EndTry;			
		EndIf;		
		Items.GroupHotel.BackColor = vColor;
	EndIf; 

	// Fill time zones list
	vZonesArray = GetAvailableTimeZones();
	For Each vTimeZone In vZonesArray Do
		vTimeZonePresentation = TimeZonePresentation(vTimeZone);    
		vTimeZonePresentationPrint = "";
		If Not IsBlankString(vTimeZonePresentation) Then
			vTimeZonePresentationPrint = " - " + vTimeZonePresentation;
		EndIf;	
		Items.HotelTimeZone.ChoiceList.Add(TrimAll(vTimeZone), TrimAll(vTimeZone) + vTimeZonePresentationPrint);
	EndDo;
	
	// Proforma invoice fill mode conversion
	If Object.ProformaInvoicesFillServicesInDetail And 
	   Object.FillProformaInvoiceMode <> Enums.FillProformaInvoiceModes.InDetails Then
		Object.FillProformaInvoiceMode = Enums.FillProformaInvoiceModes.InDetails;
	EndIf;
	
	Items.GroupTouristTaxParameters.Enabled = Object.TouristTaxIsUsed;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(Cancel)
	LoadColors();
	Items.PaymentSectionForAdvance.Enabled = Not Object.SplitFolioBalanceByServicesAndPrices;
	Items.DoPaymentsDistributionToServices.Enabled = Not Object.SplitFolioBalanceByServicesAndPrices;  
	
	FillPresentation();
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	pCurrentObject.CheckInColor 				= New ValueStorage(CheckInColor);
	pCurrentObject.CheckOutColor 				= New ValueStorage(CheckOutColor);
	pCurrentObject.AccommodationWithDebtColor 	= New ValueStorage(AccommodationWithDebtColor);
	pCurrentObject.ReservationColor 			= New ValueStorage(ReservationColor);
	pCurrentObject.ReservationWithDebtColor 	= New ValueStorage(ReservationWithDebtColor);
	pCurrentObject.GuaranteedReservationColor 	= New ValueStorage(GuaranteedReservationColor);
	pCurrentObject.CheckOutTodayRoomBackColor 	= New ValueStorage(CheckOutTodayRoomBackColor);
	pCurrentObject.DraftReservationBackColor 	= New ValueStorage(DraftReservationBackColor);
	If Not IsBlankString(Logo) Then 
		vLogo = GetFromTempStorage(Logo);
		If Not TypeOf(vLogo) = Type("Picture") Then
		    vLogo = New Picture(vLogo);
		EndIf; 
		pCurrentObject.Logo = New ValueStorage(vLogo);
	Else
		pCurrentObject.Logo = Undefined;
	EndIf;
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	RefreshReusableValues();
	If ValueIsFilled(Object.Ref) Then
		If tcOnServer.cmGetSessionParametersAttribute("CurrentHotel") = Object.Ref Then
			// Set form functional option parameters
			SetFormFunctionalOptionParameters(New Structure("Hotel", Object.Ref));
			// Refresh user interface
			RefreshInterface();
		EndIf;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ExternalEvent(pSource, pEvent, pData)
	If Not IsInputAvailable() Then
		Return;
	EndIf;
	
	vEventData = tcConnectionHardwareAtClient.cmGetExternalEventResultInputDevice(pSource, pEvent, pData);
	If IsBlankString(vEventData.DeviceData) Then
		Return;
	EndIf;
	
	If vEventData.DeviceType = "MagneticStripeCardReader" Then
		Object.SelfServiceTerminalManagementIDСard = vEventData.DeviceData;
		Modified = True;
	EndIf;
EndProcedure // ExternalEvent

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ColorOnChange(pItem)
	vValue = ThisObject[pItem.Name];
	If Not (vValue.Type = ColorType.WebColor Or vValue.Type = ColorType.Absolute) Then 
		ThisObject[pItem.Name] 	= GetDefaultColor(pItem.Name);
		ShowMessageBox(, NStr("en = 'You can choose web or absolute colors only! Style and windows colors are not supported.'; 
							  |de = 'Sie dürfen nur absolute Farben wählen (nach Bezeichnung oder nach RGB)! Die Farbenauswahl aus Stilen wird nicht unterstützt.'; 
							  |ru = 'Можете выбирать только абсолютные цвета (по названию или по RGB)! Выбор цветов из стилей не поддерживается.'"));
		
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ColorClearing(pItem, pStandardProcessing)
	pStandardProcessing 	= False;
	ThisObject[pItem.Name] 	= GetDefaultColor(pItem.Name);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure PrintNameTranslationsOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", TrimAll(pItem.EditText)), pItem);	
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SalesDivisionContactsTranslationsOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", TrimAll(pItem.EditText)), pItem);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ReservationConditionsOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", TrimAll(pItem.EditText)), pItem);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SplitFolioBalanceByOnChange(Item)
	Modified = True;
	If SplitFolioBalanceBy = 0 Then
		Object.SplitFolioBalanceByServicesAndPrices 	= False;
		Object.SplitFolioBalanceByPaymentSections 		= False;
	ElsIf SplitFolioBalanceBy = 1 Then	
		Object.SplitFolioBalanceByServicesAndPrices 	= False;
		Object.SplitFolioBalanceByPaymentSections 		= True;
		Items.PaymentSectionForAdvance.Enabled 			= True;
		Items.DoPaymentsDistributionToServices.Enabled 	= True;
	ElsIf SplitFolioBalanceBy = 2 Then	
		Object.SplitFolioBalanceByServicesAndPrices 	= True;
		Object.SplitFolioBalanceByPaymentSections 		= False;
		Items.PaymentSectionForAdvance.Enabled 			= False;
		Items.DoPaymentsDistributionToServices.Enabled 	= False;
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure BLOBRootFolderStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	tcOnClient.cmGetChooseDirectory(Object.BLOBRootFolder, ThisObject, "SaveFilePathStartChoice_AfterInput");
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SaveFilePathStartChoice_AfterInput(pValue, pParameters) Export
	If pValue = Undefined Then
		Return;
	EndIf;
	Object.BLOBRootFolder = pValue[0];	
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure DirectorOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", TrimAll(pItem.EditText)), pItem);		
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure DirectorPositionOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", TrimAll(pItem.EditText)), pItem);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure AccountantGeneralOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", TrimAll(pItem.EditText)), pItem);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure AccountantGeneralPositionOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", TrimAll(pItem.EditText)), pItem);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure DoNotEditClosedDateDocsOnChange(pItem)
	If Object.DoNotEditClosedDateDocs Then
		Object.SwitchOffAutoCorrections = True;
	EndIf;
EndProcedure // DoNotEditClosedDateDocsOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure SwitchOffAutoCorrectionsOnChange(pItem)
	If Not Object.SwitchOffAutoCorrections Then
		Object.SwitchOffAutoCorrections = True;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Not supported in this release!'; ru='Не поддерживается в данной версии!'; de='Nicht in dieser Version unterstützt!'"));
	EndIf;
EndProcedure // SwitchOffAutoCorrectionsOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure UseMaximumPriceInPricePresentationOnChange(pItem)
	If Object.UseMaximumPriceInPricePresentation And Object.UseCheckInDatePriceInPricePresentation Then
		Object.UseCheckInDatePriceInPricePresentation = False;
	EndIf;
EndProcedure // UseMaximumPriceInPricePresentationOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure UseCheckInDatePriceInPricePresentationOnChange(pItem)
	If Object.UseCheckInDatePriceInPricePresentation And Object.UseMaximumPriceInPricePresentation Then
		Object.UseMaximumPriceInPricePresentation = False;
	EndIf;
EndProcedure // UseCheckInDatePriceInPricePresentationOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DecorationPostalAddressValueClick(Item)
	vParameters = New Structure("Country, Address, AddressType", , TrimAll(Object.PostAddress), "PostAddress");
	OpenForm("CommonForm.tcInputAddress", vParameters, Object.PostAddress, Object.Ref, , , New NotifyDescription("DecorationPostalAddressValueClickEnd", ThisObject),  FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure TouristTaxIsUsedOnChange(pItem)
	Items.GroupTouristTaxParameters.Enabled = Object.TouristTaxIsUsed;
EndProcedure // TouristTaxIsUsedOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure TouristTaxAddToRateOnChange(pItem)
	If Object.TouristTaxAddToRate Then
		If Object.TouristTaxSubtractFromRateIfExemption Then
			Object.TouristTaxSubtractFromRateIfExemption = False;
		EndIf;
		If ValueIsFilled(Object.TouristTaxService) Then
			Object.TouristTaxService = PredefinedValue("Catalog.Services.EmptyRef");
		EndIf;
	EndIf;
EndProcedure // TouristTaxAddToRateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure TouristTaxSubtractFromRateIfExemptionOnChange(pItem)
	If Object.TouristTaxSubtractFromRateIfExemption Then
		If Object.TouristTaxAddToRate Then
			Object.TouristTaxAddToRate = False;
		EndIf;
		If ValueIsFilled(Object.TouristTaxService) Then
			Object.TouristTaxService = PredefinedValue("Catalog.Services.EmptyRef");
		EndIf;
	EndIf;
EndProcedure // TouristTaxSubtractFromRateIfExemptionOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure TouristTaxServiceOnChange(pItem)
	If ValueIsFilled(Object.TouristTaxService) Then
		If Object.TouristTaxAddToRate Then
			Object.TouristTaxAddToRate = False;
		EndIf;
		If Object.TouristTaxSubtractFromRateIfExemption Then
			Object.TouristTaxSubtractFromRateIfExemption = False;
		EndIf;
	EndIf;
EndProcedure // TouristTaxServiceOnChange

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure AddLogo(Command)
	vParams = tcOnClientWorkWithFiles.cmGetEmptyParamsForLoadFiles();
	vParams.Form = ThisObject;
	vParams.Item = "Logo";
	vParams.Filter = tcOnClientWorkWithFiles.cmGetChooseFilterForAllPictures();
	tcOnClientWorkWithFiles.LoadFile(vParams);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ClearLogo(Command)
	Logo = "";
	Modified = True;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure UploadDirectorSignature(Command)
	#If WebClient Or ThinClient Then
		BeginAttachingFileSystemExtension(New NotifyDescription("DirectorSignatureUploadFromFileAttachingFileSystemExtensionResult", ThisObject));
	#Else 
		DirectorSignatureOpenFileDialogToChooseFile();
	#EndIf
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ClearDirectorSignature(Command)
	DirectorSignatureDirectorSignatureClearPhotoAtServer();
EndProcedure                                                                      

// --------------------------------------------------------------------------------
&AtClient
Procedure UploadAccountantGeneralSignature(Command)
	#If WebClient Or ThinClient Then
		BeginAttachingFileSystemExtension(New NotifyDescription("AccountantGeneralSignatureUploadFromFileAttachingFileSystemExtensionResult", ThisObject));
	#Else
		AccountantGeneralSignatureOpenFileDialogToChooseFile();
	#EndIf
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ClearAccountantGeneralSignature(pCommand)
	AccountantGeneralSignatureAccountantGeneralSignatureClearPhotoAtServer();
EndProcedure                                                                      

// --------------------------------------------------------------------------------
&AtClient
Procedure GenerateSelfServiceTerminalManagementQRCode(pCommand)
	Object.SelfServiceTerminalManagementQRCode = New UUID();
	Modified = True;
EndProcedure // GenerateSelfServiceTerminalManagementQRCode

// --------------------------------------------------------------------------------
&AtClient
Procedure PrintSelfServiceTerminalManagementQRCode(pCommand)
	If Not Modified And ValueIsFilled(Object.Ref) Then 
		vParametersBarcode = New Structure("Barcode, Width, Height, CodeType, TextVisible, FontSize", TrimAll(Object.SelfServiceTerminalManagementQRCode), 50, 50, 16, True, 12);
		vPicture = tcSystemBarcodePrinterDriver.pmGetPictureCode(vParametersBarcode);
		vDoc = New SpreadsheetDocument();
		vNewPicture = vDoc.Drawings.Add(SpreadsheetDocumentDrawingType.Picture);
		vIndex = vDoc.Drawings.IndexOf(vNewPicture);
		vDoc.Drawings[vIndex].Picture = vPicture;
		vDoc.Drawings[vIndex].PictureSize = PictureSize.Stretch;
		vDoc.Drawings[vIndex].Line = New Line(SpreadsheetDocumentDrawingLineType.None); 
		vDoc.Drawings[vIndex].Place(vDoc.Area("R1C1:R12C3"));  
		If pCommand.Name = "PrintSelfServiceTerminalManagementQRCode" Then 
			vDoc.Print(PrintDialogUseMode.DontUse);
		Else
			vDoc.Print(PrintDialogUseMode.Use);	
		EndIf;
	Else
		ShowMessageBox(, NStr("en = 'All changes must be saved!'; de = 'Alle änderungen müssen gespeichert werden!'; ru = 'Все изменения должны быть сохранены!'"));	
	EndIf;
EndProcedure // PrintSelfServiceTerminalManagementQRCode

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure SetColor(pCommand)
	// Choose color
	vColorDlg =  New ColorChooseDialog;
	vColorDlg.Color = Items.FormClearColor.BackColor;
	vColorDlg.Show(New NotifyDescription("SetColorAfterUserChoice", ThisObject));
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ClearColor(pCommand)
	// Clear color
	Object.ColorString = "";
	Items.FormSetColor.BackColor = Items.FormClearColor.BackColor;
	Items.GroupHotel.BackColor = Items.GroupCloseOfPeriod.BackColor;
EndProcedure // ClearColor

// --------------------------------------------------------------------------------
&AtClient
Procedure RecalculateTouristTax(pCommand)
	If ValueIsFilled(SelTTRecalcDateFrom) And ValueIsFilled(SelTTRecalcDateTo) And SelTTRecalcDateFrom <= SelTTRecalcDateTo Then
		RecalculateTouristTaxAtServer();
		ShowMessageBox(, NStr("en='Done!'; ru='Выполнено!'; de='Fertig!'"));
	Else
		ShowMessageBox(, NStr("en='Recalculation period is not filled or wrong!'; ru='Период перерасчета не указан или указан неправильно!'; de='Berechnungszeitraum ist nicht ausgefüllt oder falsch!'"));
	EndIf;
EndProcedure // RecalculateTouristTax

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtClientAtServerNoContext
Function GetDefaultColor(pName)   
	vColor = Undefined;
	If 	pName = "CheckInColor" Then
		vColor = tcCommonFunctionOnClientServer.ColorConstructor(144, 238, 144); 
	ElsIf pName = "CheckOutColor" Then
		vColor = tcCommonFunctionOnClientServer.ColorConstructor(200, 200, 200); 
	ElsIf pName = "AccommodationWithDebtColor" Then
		vColor = tcCommonFunctionOnClientServer.ColorConstructor(0, 150, 0); 
	ElsIf pName = "ReservationColor" Then
		vColor = tcCommonFunctionOnClientServer.ColorConstructor(166, 202, 240); 
	ElsIf pName = "ReservationWithDebtColor" Then
		vColor = tcCommonFunctionOnClientServer.ColorConstructor(65, 105, 225);
	ElsIf pName = "GuaranteedReservationColor" Then
		vColor = tcCommonFunctionOnClientServer.ColorConstructor(254, 228, 181); 
	ElsIf pName = "CheckOutTodayRoomBackColor" Then
		vColor = tcCommonFunctionOnClientServer.ColorConstructor(255, 255, 0); 
	ElsIf pName = "DraftReservationBackColor" Then
		vColor = tcCommonFunctionOnClientServer.ColorConstructor(128, 0, 0);  
	Else
		vColor = Undefined;
	EndIf; 
	Return vColor;
EndFunction

// --------------------------------------------------------------------------------
&AtServer
Procedure LoadColors()
	If ValueIsFilled(Object.Ref) Then 
		vObj 						= Object.Ref.GetObject();
		vCheckInColor				= vObj.CheckInColor.Get();
		vCheckOutColor				= vObj.CheckOutColor.Get();
		vAccommodationWithDebtColor	= vObj.AccommodationWithDebtColor.Get();
		vReservationColor			= vObj.ReservationColor.Get();
		vReservationWithDebtColor	= vObj.ReservationWithDebtColor.Get();
		vGuaranteedReservationColor	= vObj.GuaranteedReservationColor.Get();
		vCheckOutTodayRoomBackColor	= vObj.CheckOutTodayRoomBackColor.Get();
		vDraftReservationBackColor	= vObj.DraftReservationBackColor.Get();
		
		If vCheckInColor <> Undefined Then 
			CheckInColor				= vCheckInColor;
		Else
			CheckInColor 				= GetDefaultColor("CheckInColor");
		EndIf;
		
		If vCheckOutColor <> Undefined Then
			CheckOutColor				= vCheckOutColor;
		Else
			CheckOutColor 				= GetDefaultColor("CheckOutColor");
		EndIf;
		
		If vAccommodationWithDebtColor <> Undefined Then
			AccommodationWithDebtColor	= vAccommodationWithDebtColor;
		Else
			AccommodationWithDebtColor 	= GetDefaultColor("AccommodationWithDebtColor");
		EndIf;
		
		If vReservationColor <> Undefined Then
			ReservationColor			= vReservationColor;
		Else
			ReservationColor 			= GetDefaultColor("ReservationColor");
		EndIf;
		
		If vReservationWithDebtColor <> Undefined Then
			ReservationWithDebtColor	= vReservationWithDebtColor;
		Else
			ReservationWithDebtColor 	= GetDefaultColor("ReservationWithDebtColor");
		EndIf;
		
		If vGuaranteedReservationColor <> Undefined Then
			GuaranteedReservationColor	= vGuaranteedReservationColor;
		Else
			GuaranteedReservationColor 	= GetDefaultColor("GuaranteedReservationColor");
		EndIf;
		
		If vCheckOutTodayRoomBackColor <> Undefined Then
			CheckOutTodayRoomBackColor	= vCheckOutTodayRoomBackColor;
		Else
			CheckOutTodayRoomBackColor 	= GetDefaultColor("CheckOutTodayRoomBackColor");
		EndIf;
		
		If vDraftReservationBackColor <> Undefined Then
			DraftReservationBackColor	= vDraftReservationBackColor;
		Else
			DraftReservationBackColor 	= GetDefaultColor("DraftReservationBackColor");
		EndIf;
	Else
		CheckInColor 				= GetDefaultColor("CheckInColor");
		CheckOutColor 				= GetDefaultColor("CheckOutColor");
		AccommodationWithDebtColor 	= GetDefaultColor("AccommodationWithDebtColor");
		ReservationColor 			= GetDefaultColor("ReservationColor");
		ReservationWithDebtColor 	= GetDefaultColor("ReservationWithDebtColor");
		GuaranteedReservationColor 	= GetDefaultColor("GuaranteedReservationColor");
		CheckOutTodayRoomBackColor 	= GetDefaultColor("CheckOutTodayRoomBackColor");
		DraftReservationBackColor 	= GetDefaultColor("DraftReservationBackColor");
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure DirectorSignatureCommandActionUploadFromFileAtServer(pBinaryData, pFileName, pFileLastChangeTime) 
	vObj = FormAttributeToValue("Object");
	vPicture = New Picture(pBinaryData);
	vObj.DirectorSignature = New ValueStorage(vPicture);
	vObj.Write();
	ValueToFormAttribute(vObj, "Object");
	// Save file name, Upload time and last modification time
	vTempStorage = PutToTempStorage(vPicture, UUID);
	DirectorSignature = vTempStorage;
	Modified = False;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure DirectorSignatureDirectorSignatureFileDownUploadToServerCompletedAtServer(pTransferredFiles, pFile)
	vFileAddress = pTransferredFiles.Get(0).Location;
	vBinaryData = GetFromTempStorage(vFileAddress);
	DirectorSignatureCommandActionUploadFromFileAtServer(vBinaryData, pFile.Name, pFile.LastModificationTime);
EndProcedure // DirectorSignatureDirectorSignatureFileDownUploadToServerCompletedAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure DirectorSignatureFileDownUploadToServerCompleted(pTransferredFiles, pFile) Export
	DirectorSignatureDirectorSignatureFileDownUploadToServerCompletedAtServer(pTransferredFiles, pFile);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure DirectorSignatureUploadFileInWebClient(pFullFileName, pFile)
	vFilesArray = New Array();
	vFileDescription = New TransferableFileDescription(pFullFileName);
	vFilesArray.Add(vFileDescription);
	BeginPuttingFiles(New NotifyDescription("DirectorSignatureFileDownUploadToServerCompleted", ThisObject, pFile), vFilesArray, , False);
EndProcedure // DirectorSignatureUploadFileInWebClient

// --------------------------------------------------------------------------------
&AtClient
Procedure DirectorSignatureUploadFromFileInstallingFileSystemExtensionResult(pResult, pParam) Export 
	If pResult Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'File system extension was successfully installed on your browser!'; 
														|de = 'Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'; 
														|ru = 'В браузер успешно установлено расширение по работе с файлами!'"), MessageStatus.Information);
		DirectorSignatureOpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Your browser does not support file operations in 1C!'; 
														|de = 'Ihr Browser unterstützt keine Dateioperationen in 1C!'; 
														|ru = 'Браузер не поддерживает работу с файлами в 1С!'"), MessageStatus.Attention);
	EndIf;
EndProcedure // DirectorSignatureUploadFromFileInstallingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure DirectorSignatureUploadFromFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("DirectorSignatureUploadFromFileInstallingFileSystemExtensionResult", ThisObject));
EndProcedure // DirectorSignatureUploadFromFileFileSystemExtensionInstallCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure DirectorSignatureUploadFileGettingModificationTimeCompleted(pModificationTime, pParams) Export
	DirectorSignatureUploadFileInWebClient(pParams.FullFileName, New Structure("Name, LastModificationTime", pParams.FileName, pModificationTime));
EndProcedure // DirectorSignatureUploadFileGettingModificationTimeCompleted	

// --------------------------------------------------------------------------------
&AtClient
Procedure DirectorSignatureCommandActionUploadFromFileNotification(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		vFullFileName = pFileArray[0];
		vFile = New File(vFullFileName);
		#If WebClient Or ThinClient Then
			vFile.BeginGettingModificationTime(New NotifyDescription("DirectorSignatureUploadFileGettingModificationTimeCompleted", ThisObject, New Structure("FileName, FullFileName", vFile.Name, vFullFileName)));
		#Else
			vBinaryData = New BinaryData(vFullFileName);
			DirectorSignatureCommandActionUploadFromFileAtServer(vBinaryData, vFile.Name, vFile.GetModificationTime());
		#EndIf
	EndIf;
EndProcedure // DirectorSignatureCommandActionUploadFromFileNotification

// --------------------------------------------------------------------------------
&AtClient
Procedure DirectorSignatureUploadFromFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		DirectorSignatureOpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'File system extension is being installing on your browser...'; 
														|de = 'Dateisystemerweiterung wird in Ihrem Browser installiert...'; 
														|ru = 'В браузер устанавливается расширение по работе с файлами...'"), MessageStatus.Information);
		BeginInstallFileSystemExtension(New NotifyDescription("DirectorSignatureUploadFromFileFileSystemExtensionInstallCompleted", ThisObject));
	EndIf;
EndProcedure // DirectorSignatureUploadFromFileAttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient 
Procedure DirectorSignatureOpenFileDialogToChooseFile()
	vFileOpen = New FileDialog(FileDialogMode.Open);
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
	vFileOpen.Title = NStr("en='Open file';ru='Открыть файл';de='Datei öffnen'");
	vFileOpen.Preview = True;
	vFileOpen.Show(New NotifyDescription("DirectorSignatureCommandActionUploadFromFileNotification", ThisObject));
EndProcedure // DirectorSignatureOpenFileDialogToChooseFile

// --------------------------------------------------------------------------------
&AtServer
Procedure DirectorSignatureDirectorSignatureClearPhotoAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.DirectorSignature      = Undefined;
	vObj.Write();
	DirectorSignature			= Undefined;	
	ValueToFormAttribute(vObj, "Object");
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure AccountantGeneralSignatureCommandActionUploadFromFileAtServer(pBinaryData, pFileName, pFileLastChangeTime) 
	vObj = FormAttributeToValue("Object");
	vPicture = New Picture(pBinaryData);
	vObj.AccountantGeneralSignature = New ValueStorage(vPicture);
	vObj.Write();
	ValueToFormAttribute(vObj, "Object");
	// Save file name, Upload time and last modification time
	vTempStorage = PutToTempStorage(vPicture, UUID);
	AccountantGeneralSignature = vTempStorage;
	Modified = False;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure AccountantGeneralSignatureAccountantGeneralSignatureFileDownUploadToServerCompletedAtServer(pTransferredFiles, pFile)
	vFileAddress = pTransferredFiles.Get(0).Location;
	vBinaryData = GetFromTempStorage(vFileAddress);
	AccountantGeneralSignatureCommandActionUploadFromFileAtServer(vBinaryData, pFile.Name, pFile.LastModificationTime);
EndProcedure // AccountantGeneralSignatureAccountantGeneralSignatureFileDownUploadToServerCompletedAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure AccountantGeneralSignatureFileDownUploadToServerCompleted(pTransferredFiles, pFile) Export
	AccountantGeneralSignatureAccountantGeneralSignatureFileDownUploadToServerCompletedAtServer(pTransferredFiles, pFile);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure AccountantGeneralSignatureUploadFileInWebClient(pFullFileName, pFile)
	vFilesArray = New Array();
	vFileDescription = New TransferableFileDescription(pFullFileName);
	vFilesArray.Add(vFileDescription);
	BeginPuttingFiles(New NotifyDescription("AccountantGeneralSignatureFileDownUploadToServerCompleted", ThisObject, pFile), vFilesArray, , False);
EndProcedure // AccountantGeneralSignatureUploadFileInWebClient

// --------------------------------------------------------------------------------
&AtClient
Procedure AccountantGeneralSignatureUploadFromFileInstallingFileSystemExtensionResult(pResult, pParam) Export 
	If pResult Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'File system extension was successfully installed on your browser!'; 
														|de = 'Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'; 
														|ru = 'В браузер успешно установлено расширение по работе с файлами!'"), MessageStatus.Information);
		AccountantGeneralSignatureOpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Your browser does not support file operations in 1C!'; 
														|de = 'Ihr Browser unterstützt keine Dateioperationen in 1C!'; 
														|ru = 'Браузер не поддерживает работу с файлами в 1С!'"), MessageStatus.Attention);
	EndIf;
EndProcedure // AccountantGeneralSignatureUploadFromFileInstallingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure AccountantGeneralSignatureUploadFromFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("AccountantGeneralSignatureUploadFromFileInstallingFileSystemExtensionResult", ThisObject));
EndProcedure // AccountantGeneralSignatureUploadFromFileFileSystemExtensionInstallCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure AccountantGeneralSignatureUploadFileGettingModificationTimeCompleted(pModificationTime, pParams) Export
	AccountantGeneralSignatureUploadFileInWebClient(pParams.FullFileName, New Structure("Name, LastModificationTime", pParams.FileName, pModificationTime));
EndProcedure // AccountantGeneralSignatureUploadFileGettingModificationTimeCompleted	

// --------------------------------------------------------------------------------
&AtClient
Procedure AccountantGeneralSignatureCommandActionUploadFromFileNotification(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		vFullFileName = pFileArray[0];
		vFile = New File(vFullFileName);
		#If WebClient Or ThinClient Then
			vFile.BeginGettingModificationTime(New NotifyDescription("AccountantGeneralSignatureUploadFileGettingModificationTimeCompleted", ThisObject, New Structure("FileName, FullFileName", vFile.Name, vFullFileName)));
		#Else
			vBinaryData = New BinaryData(vFullFileName);
			AccountantGeneralSignatureCommandActionUploadFromFileAtServer(vBinaryData, vFile.Name, vFile.GetModificationTime());
		#EndIf
	EndIf;
EndProcedure // AccountantGeneralSignatureCommandActionUploadFromFileNotification

// --------------------------------------------------------------------------------
&AtClient
Procedure AccountantGeneralSignatureUploadFromFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		AccountantGeneralSignatureOpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'File system extension is being installing on your browser...'; 
														|de = 'Dateisystemerweiterung wird in Ihrem Browser installiert...'; 
														|ru = 'В браузер устанавливается расширение по работе с файлами...'"), MessageStatus.Information);
		BeginInstallFileSystemExtension(New NotifyDescription("AccountantGeneralSignatureUploadFromFileFileSystemExtensionInstallCompleted", ThisObject));
	EndIf;
EndProcedure // AccountantGeneralSignatureUploadFromFileAttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient 
Procedure AccountantGeneralSignatureOpenFileDialogToChooseFile()
	vFileOpen = New FileDialog(FileDialogMode.Open);
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
	vFileOpen.Title = NStr("en='Open file';ru='Открыть файл';de='Datei öffnen'");
	vFileOpen.Preview = True;
	vFileOpen.Show(New NotifyDescription("AccountantGeneralSignatureCommandActionUploadFromFileNotification", ThisObject));
EndProcedure // AccountantGeneralSignatureOpenFileDialogToChooseFile

// --------------------------------------------------------------------------------
&AtServer
Procedure AccountantGeneralSignatureAccountantGeneralSignatureClearPhotoAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.AccountantGeneralSignature = Undefined;
	vObj.Write();
	AccountantGeneralSignature = "";	
	ValueToFormAttribute(vObj, "Object");
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtServer
Function GetColorString(pColor)
	Return XDTOSerializer.XMLString(pColor);	
EndFunction // GetColorString

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure SetColorAfterUserChoice(pColor, pExtraParams) Export
	If pColor <> Undefined Then
		If pColor.Type = ColorType.WebColor Or pColor.Type = ColorType.Absolute Then
			Items.FormSetColor.BackColor = pColor;
			Items.GroupHotel.BackColor = pColor;
			Object.ColorString = GetColorString(pColor);
		Else
			ShowMessageBox(, NStr("en = 'You can choose web or absolute colors only! Style and windows colors are not supported.'; 
								  |de = 'Sie dürfen nur absolute Farben wählen (nach Bezeichnung oder nach RGB)! Die Farbenauswahl aus Stilen wird nicht unterstützt.'; 
								  |ru = 'Можете выбирать только абсолютные цвета (по названию или по RGB)! Выбор цветов из стилей не поддерживается.'"));
		EndIf;
	EndIf;
EndProcedure // SetColorAfterUserChoice

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure FillProformaInvoiceModeOnChange(pItem)
	If Object.FillProformaInvoiceMode = PredefinedValue("Enum.FillProformaInvoiceModes.InDetails") Or 
	   Object.FillProformaInvoiceMode = PredefinedValue("Enum.FillProformaInvoiceModes.InDetailsWithDates") Then
		Object.ProformaInvoicesFillServicesInDetail = True;
	Else
		Object.ProformaInvoicesFillServicesInDetail = False;
	EndIf;
EndProcedure // FillProformaInvoiceModeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DecorationPostalAddressValueClickEnd(pResult, pAdditionalParameters) Export
	If Not pResult = Undefined Then
		Object.PostAddress = pResult.Address;  
		Object.StreetFiasId = pResult.StreetFiasId;
		FillPresentation();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillPresentation()
	If Not IsBlankString(Object.PostAddress) Then
		Items.DecorationPostalAddressValue.Title = TrimAll(Object.PostAddress);
	Else 
		Items.DecorationPostalAddressValue.Title = NStr("en = 'Fill'; ru = 'Заполнить'; de = 'Füllen'");
	EndIf;
EndProcedure // FillPresentation

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	// Check tourist tax service parameters
	If ValueIsFilled(Object.TouristTaxService) And Not TouristTaxServiceParametersAreFilled(Object.TouristTaxService) Then
		ShowQueryBox(New NotifyDescription("FillTouristTaxServiceParameters", ThisObject), 
		             NStr("en='Selected service is not setup for tourist tax. Turn on <Is tourist tax> check mark and fill <Cheque item type> attribute or answer <Yes> to the next question. Fill tourist tax service parameters automatically?'; 
		                  |ru='Выбранная услуга не настроена для работы с туристическим налогом. Включите в услуге галочку <Это туристический налог> и заполните реквизит <Наименование предмета расчета в чеках> или ответьте <Да> на следующий вопрос. Заполнить параметры услуги сейчас автоматически?'; 
		                  |de='Der ausgewählte Service ist nicht für die Kurtaxe eingerichtet. Aktivieren Sie das Kontrollkästchen <Ist Kurtaxe> und füllen Sie das Attribut <Scheckpostentyp> aus oder beantworten Sie die nächste Frage mit <Ja>. Kurtaxen-Serviceparameter automatisch ausfüllen?'"), 
		             QuestionDialogMode.YesNo);
		pCancel = True;
		Return;
	EndIf;
EndProcedure // BeforeWrite

// --------------------------------------------------------------------------------
&AtServerNoContext
Function TouristTaxServiceParametersAreFilled(pService) 
	If Not pService.IsResortFee Or pService.ChequeItemType <> Enums.ChequeItemTypes.ResortFee Then
		Return False;
	Else
		Return True;
	EndIf;
EndFunction // TouristTaxServiceParametersAreFilled

// --------------------------------------------------------------------------------
&AtClient
Procedure FillTouristTaxServiceParameters(pAnswer, pExtraParams) Export
	If pAnswer = DialogReturnCode.Yes Then
		If ValueIsFilled(Object.TouristTaxService) Then
			FillTouristTaxServiceParametersAtServer(Object.TouristTaxService);
			ShowMessageBox(, NStr("en='Tourist tax service was changed! Save tourist tax setting again'; ru='Параметры услуги туристического налога установлены! Сохраните настройку туристического налога еще раз'; de='Kurtaxenservice wurde geändert! Kurtaxeneinstellung erneut speichern'"));
		EndIf;
	EndIf;
EndProcedure // FillTouristTaxServiceParameters

// --------------------------------------------------------------------------------
&AtServerNoContext
Procedure FillTouristTaxServiceParametersAtServer(pService)
	vServiceObj = pService.GetObject();
	vServiceObj.IsResortFee = True;
	vServiceObj.ChequeItemType = Enums.ChequeItemTypes.ResortFee;
	vServiceObj.Write();
EndProcedure // FillTouristTaxServiceParametersAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure RecalculateTouristTaxAtServer()
	Documents.TouristTaxDeclarationRU.RecalculateTouristTax(SelTTRecalcDateFrom, SelTTRecalcDateTo, Object.Ref, Object.Company);
EndProcedure // RecalculateTouristTaxAtServer

#EndRegion
