
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Initialize hotel
	tcOnServer.cmInitHotel(Object);
	
	// Load User
	Try	
		vUsers = InfoBaseUsers.GetUsers();
	    For Each vUser In vUsers Do
			Items.CloseOfPeriodJobUserName.ChoiceList.Add(vUser.Name, vUser.FullName);
		EndDo;
	Except
	EndTry;
	
	// Load pictures
	vObj = FormAttributeToValue("Object");
	vTempStorage = PutToTempStorage(vObj.Stamp.Get(), UUID);
	Stamp = vTempStorage;
	vTempStorage = PutToTempStorage(vObj.DirectorSignature.Get(), UUID);
	DirectorSignature = vTempStorage;
	vTempStorage = PutToTempStorage(vObj.AccountantGeneralSignature.Get(), UUID);
	AccountantGeneralSignature = vTempStorage;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	vMessage = "";
	vAttributeInErr = "";
	vObject = FormAttributeToValue("Object");
	pCancel = vObject.pmCheckCompanyAttributes(vMessage, vAttributeInErr);
	If pCancel Then
		WriteLogEvent(NStr("en = 'Catalog.Write'; de = 'Catalog.Write'; ru = 'Справочник.Запись'"), EventLogLevel.Warning, vObject.Metadata(), Object.Ref, NStr(vMessage));
		tcCommonFunctionOnClientServer.TextMessage(cmNStr(vMessage));
	EndIf;
EndProcedure // BeforeWriteAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "SetMainBankAccaunt" Then	
		Read();	
	EndIf;
EndProcedure // NotificationProcessing

// --------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(Cancel)
	FillPresentation();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure LegacyAddressTranslationsOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", TrimAll(pItem.EditText)), pItem);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure PrintNameTranslationsOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", TrimAll(pItem.EditText)), pItem);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure PostAddressTranslationsOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", TrimAll(pItem.EditText)), pItem);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure RunCloseOfPeriodJobAutomaticallyOnChange(pItem)
	RunCloseOfPeriodJobAutomaticallyOnChangeAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure CloseOfPeriodJobDescriptionOnChange(pItem)
	UpdateCloseOfPeriodJobParameters();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure CloseOfPeriodJobUserNameOnChange(pItem)
	UpdateCloseOfPeriodJobParameters();
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
Procedure CashierGeneralOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", TrimAll(pItem.EditText)), pItem);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure CashierGeneralPositionOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", TrimAll(pItem.EditText)), pItem);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure FrontOfficeManagerOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", TrimAll(pItem.EditText)), pItem);
EndProcedure

// ----------------------------------------------------------------------------------
&AtClient
Procedure TaxationSystemOnChange(pItem)
	If Not ValueIsFilled(Object.TaxationSystem) Or Object.TaxationSystem = PredefinedValue("Enum.TaxationSystems.Common") Then
		If Object.IsUsingSimpleTaxSystem Then
			Object.IsUsingSimpleTaxSystem = False;
		EndIf;
	Else
		If Not Object.IsUsingSimpleTaxSystem Then
			Object.IsUsingSimpleTaxSystem = True;
		EndIf;
	EndIf;
EndProcedure // TaxationSystemOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DecorationPostalAddressValueClick(Item)
	vParameters = New Structure("Country, Address, AddressType", , TrimAll(Object.PostAddress), "PostAddress");
	OpenForm("CommonForm.tcInputAddress", vParameters, Object.PostAddress, Object.Ref, , , New NotifyDescription("DecorationPostalAddressValueClickEnd", ThisObject),  FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DecorationAddressValueClick(pItem)
	vParameters = New Structure("Country, Address, AddressType", , TrimAll(Object.LegacyAddress), "LegacyAddress");
	OpenForm("CommonForm.tcInputAddress", vParameters, pItem, Object.Ref, , , New NotifyDescription("DecorationAddressValueClickEnd", ThisObject),  FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure SetCloseOfPeriodJobSchedule(pCommand)
	If Not Object.RunCloseOfPeriodJobAutomatically Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Automatic closing of periods is disabled!';ru='Автоматическое закрытие периодов отключено!';de='Automatische Schließung von Perioden deaktiviert ist!'"));
		Return;
	EndIf;
	If IsBlankString(Object.CloseOfPeriodJobUUID) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Фоновое задание не найдено! Пожалуйста выключите и, затем, включите опять галочку автоматического закрытия периодов';
		             |de='Hintergrundjob nicht gefunden! Bitte schalten Sie und, dann, wieder aktivieren Sie das Häkchen der automatischen Schließung Perioden';
					 |en='Background task not found! Please disable and then re-enable the automatic closing of periods check box'"));
		Return;
	EndIf;
	vJob = FindJobsScheduled();
	If vJob <> Undefined Then
		vScheduleDlg = New ScheduledJobDialog(vJob);
		vScheduleDlg.Show(New NotifyDescription("CloseJobSchedulePeriodSet", ThisObject));
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure DeleteCloseOfPeriodJob(pCommand)
	DeleteCloseOfPeriodJobAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure UploadStamp(Command)
	#If WebClient Or ThinClient Then 
		BeginAttachingFileSystemExtension(New NotifyDescription("StampUploadFromFileAttachingFileSystemExtensionResult", ThisObject));
	#Else
		StampOpenFileDialogToChooseFile();
	#EndIf
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ClearStamp(Command)
	StampStampClearPhotoAtServer();
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

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Procedure DecorationPostalAddressValueClickEnd(pResult, pAdditionalParameters) Export
	If Not pResult = Undefined Then
		Object.PostAddress = pResult.Address;
		FillPresentation();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DecorationAddressValueClickEnd(pResult, pAdditionalParameters) Export
	If Not pResult = Undefined Then
		Object.LegacyAddress = pResult.Address;   
		Object.StreetFiasId = pResult.StreetFiasId;
		FillPresentation();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillPresentation()
	If Not IsBlankString(Object.LegacyAddress) Then
		Items.DecorationAddressValue.Title = TrimAll(Object.LegacyAddress);
	Else 
		Items.DecorationAddressValue.Title = NStr("en = 'Fill'; ru = 'Заполнить'; de = 'Füllen'");
	EndIf;
	
	If Not IsBlankString(Object.PostAddress) Then
		Items.DecorationPostalAddressValue.Title = TrimAll(Object.PostAddress);
	Else 
		Items.DecorationPostalAddressValue.Title = NStr("en = 'Fill'; ru = 'Заполнить'; de = 'Füllen'");
	EndIf;
EndProcedure // FillPresentation

// --------------------------------------------------------------------------------
&AtServer
Procedure RunCloseOfPeriodJobAutomaticallyOnChangeAtServer()
	// Write current company first
	If Modified Then
		If Not ValueIsFilled(Object.Ref) Then
			Object.RunCloseOfPeriodJobAutomatically = Not Object.RunCloseOfPeriodJobAutomatically;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Company should be saved first!';ru='Фирма должна быть записана!';de='Kompanie muss eingetragen sein!'"));
			Return;
		EndIf;
	EndIf;
	// Process run automatic close of period mode change
	Try
		If Object.RunCloseOfPeriodJobAutomatically Then
			// Check that company accounting company type is choosen
			If Not ValueIsFilled(Object.CompanyAccountingPolicyType) Then
				Object.RunCloseOfPeriodJobAutomatically = Not Object.RunCloseOfPeriodJobAutomatically;
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='Choose company accounting policy type first!';ru='Выберите вид учетной политики фирмы!';de='Wählen Sie die Art der Erfassungspolitik der Kompanie!'"));
				Return;
			EndIf;
			// Check that job description is set
			If IsBlankString(Object.CloseOfPeriodJobDescription) Then
				Object.CloseOfPeriodJobDescription = TrimAll(NStr("en='Close of period job';ru='Закрытие периода';de='Schließung des Zeitraums'") + " - " + TrimAll(Object.Description));
			EndIf;
			If IsBlankString(Object.CloseOfPeriodJobUserName) Then
				Object.CloseOfPeriodJobUserName = TrimAll(SessionParameters.CurrentUser);
			EndIf;
			If IsBlankString(Object.CloseOfPeriodJobUUID) Then
				Object.CloseOfPeriodJobUUID = JobsScheduled.cmCreateCloseOfPeriodJob(Object.Ref, Object.CloseOfPeriodHotel, Object.CloseOfPeriodJobDescription, Object.CloseOfPeriodJobUserName);
			Else
				JobsScheduled.cmUpdateCloseOfPeriodJob(Object.CloseOfPeriodJobUUID, Object.Ref, Object.CloseOfPeriodHotel, Object.CloseOfPeriodJobDescription, Object.CloseOfPeriodJobUserName);
			EndIf;
			Write();
		Else
			If Not IsBlankString(Object.CloseOfPeriodJobUUID) Then
				vJob = JobsScheduled.cmGetCloseOfPeriodJob(Object.CloseOfPeriodJobUUID);
				If vJob <> Undefined Then
					vJob.Use = False;
					vJob.Write();
				Else
					Object.CloseOfPeriodJobUUID = "";
				EndIf;
			EndIf;
		EndIf;
	Except
		Object.RunCloseOfPeriodJobAutomatically = Not Object.RunCloseOfPeriodJobAutomatically;
		vErrInfo = ErrorInfo();
		WriteLogEvent(NStr("en='Company.RunCloseOfPeriodJobAutomaticallyOnChange';ru='Фирма.ИзменениеФлагаАвтоматическогоЗакрытияПериодов';de='Company.RunCloseOfPeriodJobAutomaticallyOnChange'"), EventLogLevel.Error, FormAttributeToValue("Object").Metadata(), Object.Ref, cmGetRootErrorDescription(vErrInfo));
		tcCommonFunctionOnClientServer.TextMessage(vErrInfo);
	EndTry;
EndProcedure

// --------------------------------------------------------------------------------    
&AtServer
Procedure UpdateCloseOfPeriodJobParameters()
	If IsBlankString(Object.CloseOfPeriodJobUUID) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Не установлен UUID задания автоматического закрытия периодов.';de='UUID der Aufgabe der automatischen Schließung von Zeiträumen ist nicht festgelegt!';en='Automatic close of period job UUID is not set!'"));
		Return;
	EndIf;
	Try
		JobsScheduled.cmUpdateCloseOfPeriodJob(Object.CloseOfPeriodJobUUID, Object.Ref, Object.CloseOfPeriodHotel, Object.CloseOfPeriodJobDescription, Object.CloseOfPeriodJobUserName);
		Write();
	Except
		vErrInfo = ErrorInfo();
		WriteLogEvent(NStr("en='Company.UpdateCloseOfPeriodJobParameters';ru='Фирма.ИзменениеПараметровРегламентногоЗаданияЗакрытияПериодов';de='Company.UpdateCloseOfPeriodJobParameters'"), EventLogLevel.Error, FormAttributeToValue("Object").Metadata(), Object.Ref, cmGetRootErrorDescription(vErrInfo));
		tcCommonFunctionOnClientServer.TextMessage(vErrInfo);
	EndTry;
EndProcedure // UpdateCloseOfPeriodJobParameters

// --------------------------------------------------------------------------------
&AtServer
Function FindJobsScheduled()
	Try
		Return JobsScheduled.cmGetCloseOfPeriodJob(Object.CloseOfPeriodJobUUID).Schedule;
	Except
		vErrInfo = ErrorInfo();
		WriteLogEvent(NStr("en='Company.SetCloseOfPeriodJobParameters';ru='Фирма.УстановкаПараметровРегламентногоЗаданияЗакрытияПериодов';de='Company.SetCloseOfPeriodJobParameters'"), EventLogLevel.Error, FormAttributeToValue("Object").Metadata(), Object.Ref, cmGetRootErrorDescription(vErrInfo));
		tcCommonFunctionOnClientServer.TextMessage(vErrInfo);    
	EndTry;    
	Return Undefined;
EndFunction

// --------------------------------------------------------------------------------
&AtServer
Procedure SetJobsScheduled(pScheduled)
	Try
		vJob = JobsScheduled.cmGetCloseOfPeriodJob(Object.CloseOfPeriodJobUUID);
		vJob.Schedule = pScheduled;
		vJob.Write();
	Except
		vErrInfo = ErrorInfo();
		WriteLogEvent(NStr("en = 'Company.SetCloseOfPeriodJobParameters'; de = 'Company.SetCloseOfPeriodJobParameters'; ru = 'Фирма.УстановкаПараметровРегламентногоЗаданияЗакрытияПериодов'"), EventLogLevel.Error, FormAttributeToValue("Object").Metadata(), Object.Ref, cmGetRootErrorDescription(vErrInfo));
		tcCommonFunctionOnClientServer.TextMessage(vErrInfo);
	EndTry;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure CloseJobSchedulePeriodSet(pScheduled, pExtraParameters) Export
	If pScheduled <> Undefined Then
		SetJobsScheduled(pScheduled);
	EndIf;
EndProcedure // PostAddressStartChoice

// --------------------------------------------------------------------------------
&AtServer
Procedure DeleteCloseOfPeriodJobAtServer()
		If IsBlankString(Object.CloseOfPeriodJobUUID) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Фоновое задание не найдено!';de='Hintergrundjob nicht gefunden!';en='Background task not found!'"));
		Return;
	EndIf;
	Try
		JobsScheduled.cmDeleteCloseOfPeriodJob(Object.CloseOfPeriodJobUUID);
		Object.CloseOfPeriodJobUUID = "";
		Object.RunCloseOfPeriodJobAutomatically = False;
		Write();
	Except
		CloseOfPeriodJobUUID = "";
		RunCloseOfPeriodJobAutomatically = False;
		vErrInfo = ErrorInfo();
		WriteLogEvent(NStr("en='Company.DeleteCloseOfPeriodJob';ru='Фирма.УдалениеРегламентногоЗаданияЗакрытияПериодов';de='Company.DeleteCloseOfPeriodJob'"), EventLogLevel.Error,  FormAttributeToValue("Object").Metadata(), Object.Ref, cmGetRootErrorDescription(vErrInfo));
		tcCommonFunctionOnClientServer.TextMessage(vErrInfo);
	EndTry;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure StampCommandActionUploadFromFileAtServer(pBinaryData, pFileName, pFileLastChangeTime) 
	vObj = FormAttributeToValue("Object");
	vPicture = New Picture(pBinaryData);
	vObj.Stamp = New ValueStorage(vPicture);
	vObj.Write();
	ValueToFormAttribute(vObj, "Object");
	// Save file name, Upload time and last modification time
	vTempStorage = PutToTempStorage(vPicture, UUID);
	Stamp = vTempStorage;
	Modified = False;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure StampStampFileDownUploadToServerCompletedAtServer(pTransferredFiles, pFile)
	vFileAddress = pTransferredFiles.Get(0).Location;
	vBinaryData = GetFromTempStorage(vFileAddress);
	StampCommandActionUploadFromFileAtServer(vBinaryData, pFile.Name, pFile.LastModificationTime);
EndProcedure // StampStampFileDownUploadToServerCompletedAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure StampFileDownUploadToServerCompleted(pTransferredFiles, pFile) Export
	StampStampFileDownUploadToServerCompletedAtServer(pTransferredFiles, pFile);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure StampUploadFileInWebClient(pFullFileName, pFile)
	vFilesArray = New Array();
	vFileDescription = New TransferableFileDescription(pFullFileName);
	vFilesArray.Add(vFileDescription);
	BeginPuttingFiles(New NotifyDescription("StampFileDownUploadToServerCompleted", ThisObject, pFile), vFilesArray, , False);
EndProcedure // StampUploadFileInWebClient

// --------------------------------------------------------------------------------
&AtClient
Procedure StampUploadFromFileInstallingFileSystemExtensionResult(pResult, pParam) Export 
	If pResult Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='В браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"), MessageStatus.Information);
		StampOpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"), MessageStatus.Attention);
	EndIf;
EndProcedure // StampUploadFromFileInstallingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure StampUploadFromFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("StampUploadFromFileInstallingFileSystemExtensionResult", ThisObject));
EndProcedure // StampUploadFromFileFileSystemExtensionInstallCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure StampUploadFileGettingModificationTimeCompleted(pModificationTime, pParams) Export
	StampUploadFileInWebClient(pParams.FullFileName, New Structure("Name, LastModificationTime", pParams.FileName, pModificationTime));
EndProcedure // StampUploadFileGettingModificationTimeCompleted	

// --------------------------------------------------------------------------------
&AtClient
Procedure StampCommandActionUploadFromFileNotification(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		vFullFileName = pFileArray[0];
		vFile = New File(vFullFileName);
		#If WebClient Or ThinClient Then
			vFile.BeginGettingModificationTime(New NotifyDescription("StampUploadFileGettingModificationTimeCompleted", ThisObject, New Structure("FileName, FullFileName", vFile.Name, vFullFileName)));
		#Else
			vBinaryData = New BinaryData(vFullFileName);
			StampCommandActionUploadFromFileAtServer(vBinaryData, vFile.Name, vFile.GetModificationTime());
		#EndIf
	EndIf;
EndProcedure // StampCommandActionUploadFromFileNotification

// --------------------------------------------------------------------------------
&AtClient
Procedure StampUploadFromFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		StampOpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension is being installing on your browser...'; ru='В браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"), MessageStatus.Information);
		BeginInstallFileSystemExtension(New NotifyDescription("StampUploadFromFileFileSystemExtensionInstallCompleted", ThisObject));
	EndIf;
EndProcedure // StampUploadFromFileAttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient 
Procedure StampOpenFileDialogToChooseFile()
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
	vFileOpen.Show(New NotifyDescription("StampCommandActionUploadFromFileNotification", ThisObject));
EndProcedure // StampOpenFileDialogToChooseFile

// --------------------------------------------------------------------------------
&AtServer
Procedure StampStampClearPhotoAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.Stamp      = Undefined;
	vObj.Write();
	Stamp			= Undefined;	
	ValueToFormAttribute(vObj, "Object");
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
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='В браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"), MessageStatus.Information);
		DirectorSignatureOpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"), MessageStatus.Attention);
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
		#IF WebClient OR ThinClient Then
			vFile.BeginGettingModificationTime(New NotifyDescription("DirectorSignatureUploadFileGettingModificationTimeCompleted", ThisObject, New Structure("FileName, FullFileName", vFile.Name, vFullFileName)));
		#ELSE
			vBinaryData = New BinaryData(vFullFileName);
			DirectorSignatureCommandActionUploadFromFileAtServer(vBinaryData, vFile.Name, vFile.GetModificationTime());
		#ENDIF
	EndIf;
EndProcedure // DirectorSignatureCommandActionUploadFromFileNotification

// --------------------------------------------------------------------------------
&AtClient
Procedure DirectorSignatureUploadFromFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		DirectorSignatureOpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension is being installing on your browser...'; ru='В браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"), MessageStatus.Information);
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
	vObj.DirectorSignature = Undefined;
	vObj.Write();
	DirectorSignature = Undefined;	
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
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='В браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"), MessageStatus.Information);
		AccountantGeneralSignatureOpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"), MessageStatus.Attention);
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
		#If  WebClient Or ThinClient Then
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
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension is being installing on your browser...'; ru='В браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"), MessageStatus.Information);
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
                   
#EndRegion    
