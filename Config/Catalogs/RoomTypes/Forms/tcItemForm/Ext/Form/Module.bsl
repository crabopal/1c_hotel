
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	// User rights to open item
	If Not IsInRole("RightsToChooseHotel") Then
		If ValueIsFilled(Object.Owner) And SessionParameters.CurrentHotel <> Object.Owner Then
			pCancel = True;
		EndIf;
	EndIf;	
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(Object.Owner, "BackgroundColorImportant");
	If not ValueIsFilled(Object.Ref) Then
		If Not cmCheckUserPermissions("HavePermissionToManageRoomInventory") Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights for room inventory management!';ru='Нет прав на управление номерным фондом!';de='Sie haben keine Rechte, den Zimmerfond zu verwalten!'"));
		EndIf;		
		// Fill attributes with default values
		If Not ValueIsFilled(Object.Owner) Then
			vObj = FormAttributeToValue("Object",Type("CatalogObject.RoomTypes"));
			vObj.pmFillAttributesWithDefaultValues();
			vObj.Write();
			ValueToFormAttribute(vObj,"Object");
		EndIf;
	EndIf;
	// Check user rights to edit room type
	If Not cmCheckUserPermissions("HavePermissionToManageRoomInventory") Then
		ReadOnly = True;
	EndIf;
	// Check user permissions to stop sale room type
	If Not cmCheckUserPermissions("HavePermissionToStopSaleRoomTypes") Then
		Items.StopSale.Enabled = False;
		Items.StopSalePeriods.Enabled = False;
	EndIf;
	// Appearance for virtual rooms
	If Object.IsVirtual Then
		Items.NumberOfBedsPerRoom.Enabled = False;
		Items.GroupGuestsAmounts.Enabled = False;
		Items.BaseRoomType.Enabled = False;
	EndIf;
	// Beds setups availability
	If ValueIsFilled(Object.Owner) Then
		If Not Object.Owner.BedsSetups Then
			Items.GroupAllowedBedsSetups.Visible = False;
		Else
			Items.GroupAllowedBedsSetups.Visible = True;
		EndIf;
	Else
		Items.GroupAllowedBedsSetups.Visible = False;
	EndIf;
	// Room pictures
    Images.Parameters.SetParameterValue("qDimension", Object.Ref);
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	// Beds setups availability
	If ValueIsFilled(pCurrentObject.Owner) Then
		If Not pCurrentObject.Owner.BedsSetups Then
			Items.GroupAllowedBedsSetups.Visible = False;
		Else
			Items.GroupAllowedBedsSetups.Visible = True;
		EndIf;
	Else
		Items.GroupAllowedBedsSetups.Visible = False;
	EndIf;
	// Room attributes
	If pWriteParameters.Property("UpdateRoomAttributes") And pWriteParameters.UpdateRoomAttributes = True Then
		// Run background procedure to repost all add room and change room documents of this room type
		vParameters = New Array();
		vParameters.Add(pCurrentObject.Ref);
		vParameters.Add(SessionParameters.CurrentUser);
		
		AsyncCalls.StartBackgroundJobWithRecordInRegister(pCurrentObject.Owner, "UpdateRoomAttributes-" + TrimAll(pCurrentObject.Code), "ProlongedOperations.RoomType_UpdateRoomAttributes", vParameters);
	EndIf;
EndProcedure // AfterWriteAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
    //If IsBlankString(Photo) Then
    //	pCurrentObject.Photo = Undefined;
    //Else
    //	vPhotoBinaryData = GetFromTempStorage(Photo);
    //	If vPhotoBinaryData <> Undefined And TypeOf(vPhotoBinaryData) = Type("BinaryData") Then
    //		vPhotoPicture = New Picture(vPhotoBinaryData);
    //		pCurrentObject.Photo = New ValueStorage(vPhotoPicture);
    //	EndIf;
    //EndIf;
	If Not Object.DeletionMark And ValueIsFilled(Object.Ref) Then
		If Object.Ref.NumberOfBedsPerRoom <> Object.NumberOfBedsPerRoom Or Object.Ref.NumberOfPersonsPerRoom <> Object.NumberOfPersonsPerRoom Then
			pWriteParameters.Insert("UpdateRoomAttributes", True);
		EndIf;
	EndIf;
EndProcedure // BeforeWriteAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure DescriptionTranslationsOpening(pItem, pStandardProcessing)
	pStandardProcessing = false;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", Object.DescriptionTranslations), pItem);
EndProcedure // DescriptionTranslationsOpening

// --------------------------------------------------------------------------------
&AtClient
Procedure IsVirtualOnChange(pItem)
	If Object.IsVirtual Then
		If Object.DoesNotAffectRoomRevenueStatistics Then
			Object.DoesNotAffectRoomRevenueStatistics = False;
		EndIf;
		Items.NumberOfBedsPerRoom.Enabled = False;
		Items.NumberOfPersonsPerRoom.Enabled = True;
		Items.GroupGuestsAmounts.Enabled = True;
		Items.BaseRoomType.Enabled = False;
	Else
		Items.NumberOfBedsPerRoom.Enabled = True;
		Items.NumberOfPersonsPerRoom.Enabled = True;
		Items.GroupGuestsAmounts.Enabled = True;
		Items.BaseRoomType.Enabled = True;
	EndIf;
EndProcedure // IsVirtualOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure DoesNotAffectRoomRevenueStatisticsOnChange(pItem)
	If Object.DoesNotAffectRoomRevenueStatistics Then
		If Object.IsVirtual Then
			Object.IsVirtual = False;
		EndIf;
	EndIf;
	If Object.IsVirtual Then
		Items.NumberOfBedsPerRoom.Enabled = False;
		Items.NumberOfPersonsPerRoom.Enabled = True;
		Items.GroupGuestsAmounts.Enabled = True;
		Items.BaseRoomType.Enabled = False;
	Else
		Items.NumberOfBedsPerRoom.Enabled = True;
		Items.NumberOfPersonsPerRoom.Enabled = True;
		Items.GroupGuestsAmounts.Enabled = True;
		Items.BaseRoomType.Enabled = True;
	EndIf;
EndProcedure // DoesNotAffectRoomRevenueStatisticsOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure NumberOfPersonsPerRoomOnChange(pItem)
	If Object.NumberOfPersonsPerRoom > 0 Then
		Object.NumberOfAdults = Object.NumberOfPersonsPerRoom;
		Object.NumberOfTeenagers = Object.NumberOfPersonsPerRoom - 1;
		Object.NumberOfChildren = Object.NumberOfPersonsPerRoom - 1;
		Object.NumberOfInfants = Object.NumberOfPersonsPerRoom - 1;
	EndIf;
EndProcedure // NumberOfPersonsPerRoomOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure StopSalePeriodsOnChange(pItem)
	StopSalePeriodsOnChangeAtServer();
EndProcedure // StopSalePeriodsOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure StopSalePeriodsOnStartEdit(pItem, pNewRow, pClone)
	If pNewRow Then
		vCurRow = Items.StopSalePeriods.CurrentData;
		If vCurRow <> Undefined Then
			vCurRow.StopSale = True;
		EndIf;
	EndIf;
EndProcedure // StopSalePeriodsOnStartEdit

// --------------------------------------------------------------------------------
&AtServerNoContext
Procedure ImagesOnGetDataAtServer(pItemName, pSettings, pRows)
    For Each vRow In pRows Do
        vRow.Value.Data.Image =  GetURL(vRow.Key, "Image");
    EndDo;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ImagesOnActivateRow(pItem)
    If pItem.CurrentData <> Undefined Then
    	Photo  = pItem.CurrentData.Image;
    Else
        Photo = "";
    EndIf; 
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ImagesSelection(pItem, pSelectedRow, pField, pStandardProcessing)
    pStandardProcessing = False;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure StopSalePeriodsOnEditEnd(pItem, pNewRow, pCancelEdit)
	vCurRow = Items.StopSalePeriods.CurrentData;
	If vCurRow <> Undefined Then
		If pNewRow Then
			vCurRow.CreateDate = CurrentDate();
			vCurRow.Author = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
		EndIf;
	EndIf;
EndProcedure // StopSalePeriodsOnEditEnd

// --------------------------------------------------------------------------------
&AtClient
Procedure ConnectedRoomTypesOnChange(pItem)
	If Object.ConnectedRoomTypes.Count() > 0 Then
		If Not Object.DoesNotAffectRoomRevenueStatistics And Object.IsVirtual Then
			Object.DoesNotAffectRoomRevenueStatistics = True;
		EndIf;
		If Object.IsVirtual Then
			Object.IsVirtual = False;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Connected room type should not be virtual! Flag <Is virtual> was turned off, flag <Does not affect room revenue statistics> was turned on.'; 
			                                                |ru='Тип номера для коннекта не должен быть виртуальным! Флаг <Виртуальный> был выключен, флаг <Не влияет на статистику загрузки НФ> был включен.'; 
			                                                |de='Der verbundene Zimmertyp sollte nicht virtuell sein! Flag <Ist virtuell> wurde deaktiviert, Flag <Keinen Einfluss auf die Statistiken Belegung> wurde aktiviert.'"), 
			                                           MessageStatus.Information);
		EndIf;
	EndIf;
EndProcedure // ConnectedRoomTypesOnChange

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadPhoto(Command)
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromFileAttachingFileSystemExtensionResult", ThisObject));
EndProcedure // LoadPhoto

// --------------------------------------------------------------------------------
&AtClient
Procedure ClearPhoto(pCommand)
	ClearPhotoAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SetMain(Command)
    SetMainAtServer();
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure RefreshDisplay()
	vStopSale = False;
	For Each vRow In Object.StopSalePeriods Do
		If vRow.StopSale Or vRow.StopInternetSale Then
			If Not ValueIsFilled(vRow.PeriodFrom) And Not ValueIsFilled(vRow.PeriodTo) Then
				vStopSale = True;
				Break;
			ElsIf Not ValueIsFilled(vRow.PeriodFrom) And ValueIsFilled(vRow.PeriodTo) Then
				If vRow.PeriodTo > CurrentSessionDate() Then
					vStopSale = True;
					Break;
				EndIf;
			ElsIf ValueIsFilled(vRow.PeriodFrom) And Not ValueIsFilled(vRow.PeriodTo) Then
				vStopSale = True;
				Break;
			ElsIf ValueIsFilled(vRow.PeriodFrom) And ValueIsFilled(vRow.PeriodTo) Then
				If vRow.PeriodTo > CurrentSessionDate() Then
					vStopSale = True;
					Break;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	If vStopSale <> Object.StopSale Then
		Object.StopSale = vStopSale;
	EndIf;
EndProcedure // RefreshDisplay

// --------------------------------------------------------------------------------
&AtServer
Procedure FileDownloadToServerCompletedAtServer(pTransferredFiles, pFile)
	vFileAddress = pTransferredFiles.Get(0).Location;
	vBinaryData = GetFromTempStorage(vFileAddress);
    
    vRec =  InformationRegisters.Images.CreateRecordManager();
    vRec.Hotel = Object.Owner;
    vRec.Dimension = Object.Ref;
    vRec.Name =  pFile.Name;
    vPhotoPicture = New Picture(vBinaryData);
    vRec.Image = new ValueStorage(vPhotoPicture);
    vRec.Write(True);
    Items.Images.Refresh();
EndProcedure // FileDownloadToServerCompletedAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure FileDownloadToServerCompleted(pTransferredFiles, pFile) Export
	FileDownloadToServerCompletedAtServer(pTransferredFiles, pFile);
EndProcedure // FileDownloadToServerCompleted

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
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='В браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"), MessageStatus.Information);
		OpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"), MessageStatus.Attention);
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
Procedure OpenFileDialogToChooseFileCompleted(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		vFullFileName = pFileArray[0];
		vFile = New File(vFullFileName);
		vFile.BeginGettingModificationTime(New NotifyDescription("LoadFileGettingModificationTimeCompleted", ThisObject, New Structure("FileName, FullFileName", vFile.Name, vFullFileName)));
	EndIf;
EndProcedure // OpenFileDialogToChooseFileCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFromFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		OpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension is being installing on your browser...'; ru='В браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"), MessageStatus.Information);
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
	vFileOpen.Show(New NotifyDescription("OpenFileDialogToChooseFileCompleted", ThisObject));
EndProcedure // OpenFileDialogToChooseFile

// --------------------------------------------------------------------------------
&AtServer
Procedure ClearPhotoAtServer()
    vCurRow =  Items.Images.CurrentRow;
    If Not vCurRow =  Undefined Then
        vRec =  InformationRegisters.Images.CreateRecordManager();
        FillPropertyValues(vRec,vCurRow);
        vRec.Read();
        vRec.Delete(); 
        Items.Images.Refresh();
    EndIf;  
EndProcedure // ClearPhotoAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure StopSalePeriodsOnChangeAtServer()
	RefreshDisplay();
EndProcedure // StopSalePeriodsOnChangeAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure SetMainAtServer()
   vCurRow =  Items.Images.CurrentRow;
    If Not vCurRow =  Undefined Then
        vRecSet =  InformationRegisters.Images.CreateRecordSet();
        vRecSet.Filter.Hotel.Set(vCurRow.Hotel);
        vRecSet.Filter.Dimension.Set(vCurRow.Dimension);
        vRecSet.Read();
        For Each vRec In vRecSet Do
            If vRec.Name = vCurRow.Name Then
               vRec.IsMain =  True;
            Else	
               vRec.IsMain =  False;
            EndIf; 
        EndDo;
        vRecSet.Write();
        Items.Images.Refresh();
    EndIf;  
EndProcedure

#EndRegion
