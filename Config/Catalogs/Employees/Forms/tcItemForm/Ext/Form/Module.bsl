
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

	If Not IsInRole("Administrator") Then
		Items.AllowAccessToSystem.ReadOnly = True;
		Items.PermissionGroup.ReadOnly = True;
		Items.InfobaseUserSettings.Enabled = False;
		Items.Hotel.ReadOnly = True;
		Items.Company.ReadOnly = True;
		Items.Customer.ReadOnly = True;
		Items.RoomQuota.ReadOnly = True;
		Items.Workstation.ReadOnly = True;
		Items.RegistrationNumber.ReadOnly = True;
		Items.B24Login.ReadOnly = True;
		Items.B24EmployeeID.ReadOnly = True;
	EndIf;
	
	If ValueIsFilled(Object.EmailAccount) Then
		Items.Email_Addresses.Enabled = False;
		Items.Email_SMTP.Enabled = False;
		Items.Email_Pop3.Enabled = False;
	Else
		Items.Email_Addresses.Enabled = True;
		Items.Email_SMTP.Enabled = True;
		Items.Email_Pop3.Enabled = True;
	EndIf;
	
	vNewFilter = NonReplicatingAttributes.SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	vNewFilter.LeftValue = New DataCompositionField("Employee");
	vNewFilter.ComparisonType = DataCompositionComparisonType.Equal;
	vNewFilter.RightValue = Object.Ref;
	vNewFilter.Use = True;
	vNewFilter.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	vObj = FormAttributeToValue("Object");
	
	// Actions for the new employee
	If vObj.IsNew() Then
		If Not ValueIsFilled(Object.Hotel) Then
			Object.Hotel = SessionParameters.CurrentHotel;
		EndIf;
		// Current user permission group
		vPermGrp = cmGetEmployeePermissionGroup(SessionParameters.CurrentUser);
		If ValueIsFilled(vPermGrp) And ValueIsFilled(vPermGrp.EmployeesFolder) Then
			If Not ValueIsFilled(Object.Parent) Or 
			   ValueIsFilled(Object.Parent) And Not Object.Parent.BelongsToItem(vPermGrp.EmployeesFolder) Then
				Object.Parent = vPermGrp.EmployeesFolder;
			EndIf;
		EndIf;
	EndIf;
	
	vTempStorage = PutToTempStorage(vObj.Signature.Get());
	Signature = vTempStorage;
	
	// Color
	vColor = GetColor(vObj);
	If vColor <> Undefined Then
		ItemColor = vColor;
		ItemColorIsSet = True;
		Items.FormSetColor.BackColor = vColor;
	Else
		ItemColor = Undefined;
		ItemColorIsSet = False;
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	// Save color
	If ItemColorIsSet Then
		pCurrentObject.ColorHexString = tcOnServer.ColorToHex(ItemColor);
		pCurrentObject.Color = New ValueStorage(tcOnServer.HexToColor(pCurrentObject.ColorHexString));
	Else
		pCurrentObject.ColorHexString = "";
		pCurrentObject.Color = Undefined;
	EndIf;
	// Save user attributes
	If AccessRight("Administration", Metadata) Then
		If Not ValueIsFilled(pCurrentObject.PermissionGroup) and pCurrentObject.AllowAccessToSystem Then   
			vMsg = NStr("en = 'To allow access to the system, you need to specify permission group!'; 
						|de = 'Um den Zugriff auf das System zu steuern, müssen Sie eine Reihe von Rechten angeben!'; 
						|ru = 'Для управления доступом к системе требуется указать набор прав!'");
			tcCommonFunctionOnClientServer.TextMessage(vMsg);
			pCancel = True;
		EndIf;
		
		If Not pCancel Then
			// Fill employee ref if empty
			vEmployeeRef = pCurrentObject.Ref;
			If pCurrentObject.IsNew() Then
				If Not ValueIsFilled(NewEmployeeRef) Then
					pCurrentObject.SetNewObjectRef(Catalogs.Employees.GetRef(New UUID));
					NewEmployeeRef = pCurrentObject.GetNewObjectRef();
				Else
					pCurrentObject.SetNewObjectRef(NewEmployeeRef);
				EndIf;
				vEmployeeRef = NewEmployeeRef;
			EndIf;
			// Get user UUIDs for this employee
			vUserUUIDs = cmGetUserUUIDsByEmployee(vEmployeeRef);
			// Check if this employee has an access to the system
			If pCurrentObject.AllowAccessToSystem Then
				If vUserUUIDs.Count() = 0 Then
					// Create infobase user
					vNewUserUUID = Catalogs.Employees.CreateInfoBaseUser(Undefined, pCurrentObject.PermissionGroup, pCurrentObject.LastName, pCurrentObject.FirstName, pCurrentObject.SecondName, pCurrentObject.Description);
					// Create record in the infobase users register
					vUsers = InformationRegisters.InfoBaseUsers.CreateRecordManager();
					vUsers.Employee = vEmployeeRef;
					vUsers.UserUUID = vNewUserUUID;
					vUsers.UserName = TrimR(pCurrentObject.Description);
					vUsers.Write(True);
				Else
					// Update user permissions
					For Each vUserUUIDsRow In vUserUUIDs Do
						If Not IsBlankString(vUserUUIDsRow.UserUUID) Then
							pCancel = Not Catalogs.Employees.ChangeUserRoles(TrimAll(vUserUUIDsRow.UserUUID), pCurrentObject.PermissionGroup); 
						EndIf;
					EndDo;
				EndIf;
			Else
				For Each vUserUUIDsRow In vUserUUIDs Do
					If Not IsBlankString(vUserUUIDsRow.UserUUID) Then
						pCancel = Not Catalogs.Employees.DisableInfoBaseUser(TrimAll(vUserUUIDsRow.UserUUID));	
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "Employees.InfobaseUserSettings.Change" And Object.Ref = pParameter Then
		Read();		
	EndIf;
EndProcedure // NotificationProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	FillPresentation();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers
// --------------------------------------------------------------------------------
&AtClient
Procedure DescriptionTranslationsOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", Object.DescriptionTranslations), pItem);	
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure PositionOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", Object.Position), pItem);	
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure AllowAccessToSystemOnChange(pItem)
	If NOT ValueIsFilled(Object.PermissionGroup) Then
		Object.AllowAccessToSystem = False;  
		vMsg = NStr("en = 'To allow access to the system, you need to specify permission group!'; 
					|de = 'Um den Zugriff auf das System zu steuern, müssen Sie eine Reihe von Rechten angeben!'; 
					|ru = 'Для управления доступом к системе требуется указать набор прав!'");
		tcCommonFunctionOnClientServer.TextMessage(vMsg);
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure IdentityDocumentUnitCodeOnChange(pItem)
	If Not IsBlankString(Object.IdentityDocumentUnitCode) And IsBlankString(Object.IdentityDocumentIssuedBy) Then
		vIssuedByList = GetIssuedByListAtServer(TrimAll(Object.IdentityDocumentUnitCode), True, Object.IdentityDocumentType);
		If vIssuedByList.Count() = 1 Then
			Object.IdentityDocumentIssuedBy = vIssuedByList.Get(0).Value;
		ElsIf vIssuedByList.Count() > 1 Then
			ShowChooseFromList(New NotifyDescription("IdentityDocumentIssuedByIsChoosen", ThisObject), vIssuedByList, Items.IdentityDocumentIssuedBy);
		EndIf;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure DescriptionOnChangeAtServer()
	If Not IsBlankString(Object.Description) Then
		If IsBlankString(Object.LastName) 
			Or Not IsBlankString(Object.LastName) And IsBlankString(Object.SecondName) And IsBlankString(Object.FirstName) Then
			Object.LastName = TrimAll(Object.Description);
		EndIf;
		If IsBlankString(Object.Code) Then
			Object.Code = cmGetEmployeeCode(Object.Description);
		EndIf;
	EndIf;
EndProcedure // DescriptionOnChangeAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure DescriptionOnChange(pItem)
	DescriptionOnChangeAtServer();
EndProcedure // DescriptionOnChange

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure EmailAccountOnChange(pItem)
	If ValueIsFilled(Object.EmailAccount) Then
		Items.Email_Addresses.Enabled = False;
		Items.Email_SMTP.Enabled = False;
		Items.Email_Pop3.Enabled = False;
	Else
		Items.Email_Addresses.Enabled = True;
		Items.Email_SMTP.Enabled = True;
		Items.Email_Pop3.Enabled = True;
	EndIf;
EndProcedure // EmailAccountOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DecorationPlaceOfBirthValueClick(pItem)
	vParameters = New Structure("Country, Address, AddressType", Object.Citizenship, TrimAll(Object.PlaceOfBirth), "PlaceOfBirth");
	OpenForm("CommonForm.tcInputAddress", vParameters, pItem, Object.Ref, , , New NotifyDescription("DecorationPlaceOfBirthValueClickEnd", ThisObject),  FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DecorationAddressValueClick(pItem)
	vParameters = New Structure("Country, Address, AddressType", Object.Citizenship, TrimAll(Object.Address), "Address");
	OpenForm("CommonForm.tcInputAddress", vParameters, pItem, Object.Ref, , , New NotifyDescription("DecorationAddressValueClickEnd", ThisObject),  FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers
// --------------------------------------------------------------------------------
&AtClient
Procedure UploadSignature(pCommand)
	#If WebClient Then
		BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromFileAttachingFileSystemExtensionResult", ThisObject));
	#Else
		OpenFileDialogToChooseFile();
	#EndIf
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ClearSignature(pCommand)
	ClearSignature_AtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure AccommodationOperationsHistory(pCommand)
	If ValueIsFilled(Object.Ref) Then
		vCurrentSessionDate = GetCurrentSessionDate();
		vFilter = New Structure("User", Object.Ref);  
		vParams = New Structure("Filter, PeriodFrom, PeriodTo", vFilter, BegOfDay(vCurrentSessionDate), EndOfDay(vCurrentSessionDate));
		OpenForm("InformationRegister.AccommodationChangeHistory.ListForm", vParams);
	Else    
		vMsg = NStr("en='Please write employee first!';ru='Сотрудник должен быть записан!';de='Mitarbeiter muss eingetragen sein!'");
		tcCommonFunctionOnClientServer.TextMessage(vMsg);
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ReservationOperationHistory(pCommand)
	If ValueIsFilled(Object.Ref) Then
		vCurrentSessionDate = GetCurrentSessionDate();
		vFilter = New Structure("User", Object.Ref);  
		vParams = New Structure("Filter, PeriodFrom, PeriodTo", vFilter, BegOfDay(vCurrentSessionDate), EndOfDay(vCurrentSessionDate));
		OpenForm("InformationRegister.ReservationChangeHistory.ListForm", vParams);
	Else                      
		vMsg = NStr("en = 'Please write employee first!'; de = 'Mitarbeiter muss eingetragen sein!'; ru = 'Сотрудник должен быть записан!'");
		tcCommonFunctionOnClientServer.TextMessage(vMsg);
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ResourceOperationHistory(pCommand)
	If ValueIsFilled(Object.Ref) Then
		vCurrentSessionDate = GetCurrentSessionDate();
		vFilter = New Structure("User", Object.Ref);    
		vParams = New Structure("Filter, PeriodFrom, PeriodTo", vFilter, BegOfDay(vCurrentSessionDate), EndOfDay(vCurrentSessionDate));
		OpenForm("InformationRegister.ResourceReservationChangeHistory.ListForm", vParams);
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Please write employee first!';ru='Сотрудник должен быть записан!';de='Mitarbeiter muss eingetragen sein!'"));
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ClearLastVisitedList(pCommand)
	ClearLastVisitedList_AtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure InfobaseUserSettings(pCommand)
	If Not Modified Then 
		If ValueIsFilled(Object.Ref) Then
			If Object.AllowAccessToSystem Then
				vUserUUID = GetUserUUIDByEmployee(Object.Ref);
				If vUserUUID <> Undefined Then
					OpenForm("Catalog.Employees.Form.InfobaseUserSettings", New Structure("UserUUID, Employee", New UUID(vUserUUID), Object.Ref));
				EndIf;
			Else      
				vMsg = NStr("en = 'The employee must be allowed access to the system!'; 
							|de = 'Der Mitarbeiter muss Zugang zum System haben!'; 
							|ru = 'У сотрудника должен быть разрешен доступ в систему!'");
				tcCommonFunctionOnClientServer.TextMessage(vMsg);
			EndIf;
		Else   
			vMsg = NStr("en='Please write employee first!';ru='Сотрудник должен быть записан!';de='Mitarbeiter muss eingetragen sein!'");
			tcCommonFunctionOnClientServer.TextMessage(vMsg);
		EndIf;
	Else   
		vMsg = NStr("en = 'All changes must be saved before setting up the system user!'; 
					|de = 'Alle Änderungen müssen vor dem Einrichten des Systembenutzers gespeichert werden!'; 
					|ru = 'Все изменения должны быть сохранены перед настройкой пользователя системы!'");
		tcCommonFunctionOnClientServer.TextMessage(vMsg);
	EndIf;
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure SetColor(pCommand)
	// Choose color
	vColorDlg =  New ColorChooseDialog;
	vColorDlg.Color = ItemColor;
	vColorDlg.Show(New NotifyDescription("SetColorAfterUserChoice", ThisObject))
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ClearColor(pCommand)
	// Clear color
	ItemColor = Undefined;
	ItemColorIsSet = False;
	Items.FormSetColor.BackColor = Items.FormClearColor.BackColor;
EndProcedure // ClearColor

#EndRegion

#Region Private     

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetUserUUIDByEmployee(pEmployee)
	vUserUUID = Undefined;
	vUserUUIDs = cmGetUserUUIDsByEmployee(pEmployee);
	If vUserUUIDs.Count() > 0 Then
		vUserUUID = TrimAll(vUserUUIDs.Get(0).UserUUID);
	EndIf;
	Return vUserUUID;
EndFunction // GetUserUUIDByEmployee

// --------------------------------------------------------------------------------
&AtServer
Procedure CommandActionLoadFromFileAtServer(pBinaryData, pFileName, pFileLastChangeTime) 
	vObj = FormAttributeToValue("Object");
	vObj.Signature = New ValueStorage(pBinaryData);
	// Save file name, load time and last modification time
	vTempStorage 	= PutToTempStorage(pBinaryData);
	Signature		= vTempStorage;
	vObj.Write();
	ValueToFormAttribute(vObj, "Object");
	Modified = False;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure FileDownloadToServerCompletedAtServer(pTransferredFiles, pFile)
	vFileAddress = pTransferredFiles.Get(0).Location;
	vBinaryData = GetFromTempStorage(vFileAddress);
	CommandActionLoadFromFileAtServer(vBinaryData, pFile.Name, pFile.LastModificationTime);
EndProcedure // FileDownloadToServerCompletedAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure FileDownloadToServerCompleted(pTransferredFiles, pFile) Export
	FileDownloadToServerCompletedAtServer(pTransferredFiles, pFile);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFileInWebClient(pFullFileName, pFile)
	vFilesArray = New Array();
	vFileDescription = New TransferableFileDescription(pFullFileName);
	vFilesArray.Add(vFileDescription);
	BeginPuttingFiles(New NotifyDescription("FileDownloadToServerCompleted", ThisObject, pFile), vFilesArray, , False);
EndProcedure // LoadFileInWebClient

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFromFileInstallingFileSystemExtensionResult(pResult, pParam) Export 
	If pResult Then   
		vMsg = NStr("en = 'File system extension was successfully installed on your browser!'; 
					|de = 'Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'; 
					|ru = 'В браузер успешно установлено расширение по работе с файлами!'");
		tcCommonFunctionOnClientServer.TextMessage(vMsg, MessageStatus.Information);
		OpenFileDialogToChooseFile();
	Else     
		vMsg = NStr("en = 'Your browser does not support file operations in 1C!'; 
					|de = 'Ihr Browser unterstützt keine Dateioperationen in 1C!'; 
					|ru = 'Браузер не поддерживает работу с файлами в 1С!'");
		tcCommonFunctionOnClientServer.TextMessage(vMsg, MessageStatus.Attention);
	EndIf;
EndProcedure // LoadFromFileInstallingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFromFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromFileInstallingFileSystemExtensionResult", ThisObject));
EndProcedure // LoadFromFileFileSystemExtensionInstallCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFileGettingModificationTimeCompleted(pModificationTime, pParams) Export
	LoadFileInWebClient(pParams.FullFileName, New Structure("Name, LastModificationTime", pParams.FileName, pModificationTime));
EndProcedure // LoadFileGettingModificationTimeCompleted	

// --------------------------------------------------------------------------------
&AtClient
Procedure CommandActionLoadFromFileNotification(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		vFullFileName = pFileArray[0];
		vFile = New File(vFullFileName);
		#If WebClient Or ThinClient Then
			vFile.BeginGettingModificationTime(New NotifyDescription("LoadFileGettingModificationTimeCompleted", ThisObject, New Structure("FileName, FullFileName", vFile.Name, vFullFileName)));
		#Else
			vBinaryData = New BinaryData(vFullFileName);
			CommandActionLoadFromFileAtServer(vBinaryData, vFile.Name, vFile.GetModificationTime());
		#EndIf
	EndIf;
EndProcedure // CommandActionLoadFromFileNotification

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFromFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		OpenFileDialogToChooseFile();
	Else              
		vMsg = NStr("en = 'File system extension is being installing on your browser...'; 
					|de = 'Dateisystemerweiterung wird in Ihrem Browser installiert...'; 
					|ru = 'В браузер устанавливается расширение по работе с файлами...'");
		tcCommonFunctionOnClientServer.TextMessage(vMsg, MessageStatus.Information);
		BeginInstallFileSystemExtension(New NotifyDescription("LoadFromFileFileSystemExtensionInstallCompleted", ThisObject));
	EndIf;
EndProcedure // LoadFromFileAttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient 
Procedure OpenFileDialogToChooseFile()
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
	vFileOpen.Show(New NotifyDescription("CommandActionLoadFromFileNotification", ThisObject));
EndProcedure // OpenFileDialogToChooseFile

// --------------------------------------------------------------------------------
&AtServer
Procedure ClearSignature_AtServer()
	vObj = FormAttributeToValue("Object");
	vObj.Signature      = Undefined;
	vObj.Write();
	Signature			= Undefined;	
	ValueToFormAttribute(vObj, "Object");
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure ClearLastVisitedList_AtServer()
	vObj = FormAttributeToValue("Object");
	vObj.LastVisitedObjects = Undefined;
	ValueToFormAttribute(vObj, "Object");
EndProcedure

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetCurrentSessionDate()
	Return CurrentSessionDate(); 	
EndFunction

// --------------------------------------------------------------------------------
&AtClient
Procedure IdentityDocumentIssuedByIsChoosen(pValue, pAdditionalParameters) Export
	If pValue <> Undefined Then
		Object.IdentityDocumentIssuedBy = pValue.Value;
	EndIf;
EndProcedure // IdentityDocumentIssuedByIsChoosen

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetIssuedByListAtServer(pText, pIsUnitCode = True, pIdentityDocumentType)
	vIssuedByList = New ValueList();
	If ValueIsFilled(pIdentityDocumentType) And TrimAll(pIdentityDocumentType.Code) = "21" Then
		If StrLen(TrimAll(pText)) < 3 Then
			Return vIssuedByList;
		EndIf;
		If pIsUnitCode Then
			vQryRes = cmGetFMSRecord(TrimAll(pText), True).Choose();
		Else
			vQryRes = cmGetFMSRecord(TrimAll(pText), False).Choose();
		EndIf;
	Else
		If StrLen(TrimAll(pText)) < 5 Then
			Return vIssuedByList;
		EndIf;
		If pIsUnitCode Then
			vQryRes = cmGetIssuedByRecord(TrimAll(pText), True).Choose();
		Else
			vQryRes = cmGetIssuedByRecord(TrimAll(pText), False).Choose();
		EndIf;
	EndIf;
	While vQryRes.Next() Do
		vIssuedByList.Add(TrimAll(vQryRes.Description), TrimAll(?(IsBlankString(vQryRes.Code), "", TrimAll(vQryRes.Code) + ", ") + TrimAll(vQryRes.Description)));
	EndDo;
	Return vIssuedByList;
EndFunction // GetIssuedByListAtServer

// ------------------------------------------------------------------------------------------------
&AtServer
Function GetColor(pObj = Undefined)
	vObject = pObj;
	If pObj = Undefined Then
		vObject = Object;
	EndIf;
	vColor = Undefined;
	If Not IsBlankString(vObject.ColorHexString) Then
		vColor = tcOnServer.HexToColor(vObject.ColorHexString);
		If TypeOf(vColor) <> Type("Color") Then
			vColor = Undefined;
		EndIf;
	EndIf;
	Return vColor;
EndFunction // GetColor

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure SetColorAfterUserChoice(pColor, pExtraParams) Export
	If pColor <> Undefined Then
		If pColor.Type = ColorType.WebColor Or pColor.Type = ColorType.Absolute Then
			ItemColor = pColor;
			ItemColorIsSet = True;
			Items.FormSetColor.BackColor = pColor;
		Else              
			vMsg = NStr("en = 'You can choose web or absolute colors only! Style and windows colors are not supported.'; 
						|de = 'Sie dürfen nur absolute Farben wählen (nach Bezeichnung oder nach RGB)! Die Farbenauswahl aus Stilen wird nicht unterstützt.'; 
						|ru = 'Можете выбирать только абсолютные цвета (по названию или по RGB)! Выбор цветов из стилей не поддерживается.'");
			ShowMessageBox(, vMsg);
		EndIf;
	EndIf;
EndProcedure // SetColorAfterUserChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure DecorationPlaceOfBirthValueClickEnd(pResult, pAdditionalParameters) Export
	If Not pResult = Undefined Then
		Object.PlaceOfBirth = pResult.Address;
		FillPresentation();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DecorationAddressValueClickEnd(pResult, pAdditionalParameters) Export
	If Not pResult = Undefined Then
		Object.Address = pResult.Address;   
		Object.StreetFiasId = pResult.StreetFiasId;
		FillPresentation();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillPresentation()
	If Not IsBlankString(Object.Address) Then
		Items.DecorationAddressValue.Title = TrimAll(Object.Address);
	Else 
		Items.DecorationAddressValue.Title = NStr("en = 'Fill'; ru = 'Заполнить'; de = 'Füllen'");
	EndIf;
	
	If Not IsBlankString(Object.PlaceOfBirth) Then
		Items.DecorationPlaceOfBirthValue.Title = TrimAll(Object.PlaceOfBirth);
	Else 
		Items.DecorationPlaceOfBirthValue.Title = NStr("en = 'Fill'; ru = 'Заполнить'; de = 'Füllen'");
	EndIf;
EndProcedure // FillPresentation    

#EndRegion   
