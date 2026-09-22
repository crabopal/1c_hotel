
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	// Set parameters
	RoomBlocks.Parameters.SetParameterValue("qRoom", Object.Ref);
	// Check user rights to edit room blocks
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToSetRoomBlocks") Then
		Items.RoomBlocks.ReadOnly = True;
	EndIf;
	// Check user permission to change room statuses
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToChangeRoomStatuses") Then
		Items.RoomStatus.ReadOnly = True;
	EndIf;
	// Check user permissions to stop sale room
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToStopSaleRooms") Then
		Items.StopSalePeriods.ReadOnly = True;
	EndIf;
	// Picture
	vObj = FormAttributeToValue("Object");
	vPhotoPicture1 = vObj.Photo1.Get();
	If vPhotoPicture1 <> Undefined And TypeOf(vPhotoPicture1) = Type("Picture") Then
		vPhotoBinaryData1 = vPhotoPicture1.GetBinaryData();
		Photo1 = PutToTempStorage(vPhotoBinaryData1, UUID);
	Else
		Photo1 = "";
	EndIf;
	vPhotoPicture2 = vObj.Photo2.Get();
	If vPhotoPicture2 <> Undefined And TypeOf(vPhotoPicture2) = Type("Picture") Then
		vPhotoBinaryData2 = vPhotoPicture2.GetBinaryData();
		Photo2 = PutToTempStorage(vPhotoBinaryData2, UUID);
	Else
		Photo2 = "";
	EndIf;
	If Object.RoomType.ConnectedRoomTypes.Count() > 0 Then
		Items.GroupConnectedRooms.Visible = True;
		vSelConnectedRooms = New ValueTable();
		vSelConnectedRooms.Columns.Add("RoomType", New TypeDescription("CatalogRef.RoomTypes"));
		vSelConnectedRooms.Columns.Add("Room", New TypeDescription("CatalogRef.Rooms"));
		For Each vConnectedRoom In Object.ConnectedRooms Do
			vNewRow = vSelConnectedRooms.Add();
			vNewRow.Room = vConnectedRoom.Room;
			vNewRow.RoomType = vConnectedRoom.RoomType;
		EndDo;
		For Each vConnectedRoomType In Object.RoomType.ConnectedRoomTypes Do
			vFindRows = vSelConnectedRooms.FindRows(New Structure("RoomType", vConnectedRoomType.RoomType));
			If vFindRows.Count() > 0 Then
				vSelConnectedRooms.Delete(vFindRows[0]);
			Else
				vNewRow = Object.ConnectedRooms.Add();
				vNewRow.RoomType = vConnectedRoomType.RoomType;
			EndIf;
		EndDo;
		If Modified Then
			Object.ConnectedRooms.Sort("RoomType");
		EndIf;
	Else
		Items.GroupConnectedRooms.Visible = False;
		If Object.ConnectedRooms.Count() > 0 Then
			Object.ConnectedRooms.Clear();
			Write();
		EndIf;
	EndIf;
	// Beds setup
	FillBedsSetupChoiceList();
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	// Save current room status
	SavRoomStatus = Object.RoomStatus;
	SavBedsSetup = Object.BedsSetup;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "Document.SetRoomBlock.Write" Then
		If ValueIsFilled(pParameter) And tcOnServer.cmGetAttributeByRef(pParameter, "Room") = Object.Ref Then
			Read();
			Modified = False;
			// Set parameters
			RoomBlocks.Parameters.SetParameterValue("qRoom", Object.Ref);
			// Has room blocks flag
			RoomBlocksTableOnChange(Items.RoomBlocks);
		EndIf;
	ElsIf pEventName = "RoomProperties.Changed" Then
		If ValueIsFilled(pParameter) And pParameter = Object.Ref Then
			Read();
			Modified = False;
		EndIf;
	ElsIf pEventName = "RoomProperties.Deleted" Then
		Read();
		Modified = False;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	If Not ValueIsFilled(Object.RoomStatus) Then  
		vMsg = NStr("en = 'Room status cannot be empty'; de = 'Der Zimmerstatus darf nicht leer sein'; ru = 'Статус номера не может быть пустым'");
		tcCommonFunctionOnClientServer.UserMessage(vMsg, , "Object.RoomStatus");
		pCancel = True;
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	Notify("Catalog.Rooms.Write", Object.Ref, ThisObject);
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	If Not pCurrentObject.DeletionMark Then
		If SavRoomStatus <> pCurrentObject.RoomStatus Then
			pCurrentObject.pmWriteToRoomStatusChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser, "");
			SavRoomStatus = pCurrentObject.RoomStatus;
		EndIf;
		If SavBedsSetup <> pCurrentObject.BedsSetup Then
			pCurrentObject.pmWriteToRoomChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			SavBedsSetup = pCurrentObject.BedsSetup;
		EndIf;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	If IsBlankString(Photo1) Then
		pCurrentObject.Photo1 = Undefined;
	Else
		vPhotoBinaryData = GetFromTempStorage(Photo1);
		If vPhotoBinaryData <> Undefined And TypeOf(vPhotoBinaryData) = Type("BinaryData") Then
			vPhotoPicture = New Picture(vPhotoBinaryData);
			pCurrentObject.Photo1 = New ValueStorage(vPhotoPicture);
		EndIf;
	EndIf;
	If IsBlankString(Photo2) Then
		pCurrentObject.Photo2 = Undefined;
	Else
		vPhotoBinaryData = GetFromTempStorage(Photo2);
		If vPhotoBinaryData <> Undefined And TypeOf(vPhotoBinaryData) = Type("BinaryData") Then
			vPhotoPicture = New Picture(vPhotoBinaryData);
			pCurrentObject.Photo2 = New ValueStorage(vPhotoPicture);
		EndIf;
	EndIf;
EndProcedure // BeforeWriteAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

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
	StopSalePeriodsOnEditEndAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure StopSalePeriodsAfterDeleteRow(Item)
	StopSalePeriodsAfterDeleteRowAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomBlocksTableOnChange(Item)
	If Not CheckActiveRoomBlocks(Object.Ref) Then
		If Object.HasRoomBlocks Then
			Object.HasRoomBlocks = False;
			Modified = True;
		EndIf;
	Else
		If Not Object.HasRoomBlocks Then
			Object.HasRoomBlocks = True;
			Modified = True;
		EndIf;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure StopSalePeriodsOnStartEdit(Item, NewRow, Clone)
	If NewRow Then
		Items.StopSalePeriods.CurrentData.StopSale = True;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomBlocksTableBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	OpenForm("Document.SetRoomBlock.Form.tcDocumentForm", New Structure("Room", Object.Ref), ThisObject, Object.Ref);
	Cancel = True;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ConnectedRoomsRoomsStartChoice(pItem, pChoiceData, pStandardProcessing)
	Items.ConnectedRoomsRooms.ChoiceList.Clear();
	vSelect = Items.ConnectedRooms.CurrentData;
	If vSelect <> Undefined Then
		vListConnectedRooms = GetListRooms(vSelect.RoomType);
		For Each vConnectedRoom In vListConnectedRooms Do
			Items.ConnectedRoomsRooms.ChoiceList.Add(vConnectedRoom.Value);
		EndDo;
	EndIf;
EndProcedure // ConnectedRoomsRoomsStartChoice

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadPhoto1(pCommand)
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromFileAttachingFileSystemExtensionResult", ThisObject, "Photo1"));
EndProcedure // LoadPhoto1

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadPhoto2(pCommand)
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromFileAttachingFileSystemExtensionResult", ThisObject, "Photo2"));
EndProcedure // LoadPhoto2

// --------------------------------------------------------------------------------
&AtClient
Procedure ClearPhoto1(pCommand)
	ClearPhoto1AtServer();
EndProcedure                                                                           

// --------------------------------------------------------------------------------
&AtClient
Procedure ClearPhoto2(pCommand)
	ClearPhoto2AtServer();
EndProcedure                                                                           

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer	
Procedure StopSalePeriodsOnEditEndAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.pmSetStopSaleFlag();
	ValueToFormAttribute(vObj, "Object");
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure StopSalePeriodsAfterDeleteRowAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.pmSetStopSaleFlag();
	ValueToFormAttribute(vObj, "Object");
EndProcedure

// --------------------------------------------------------------------------------
&AtServerNoContext
Function CheckActiveRoomBlocks(pRoom) Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	SetRoomBlocks.Ref AS SetRoomBlock
	|FROM
	|	Document.SetRoomBlock AS SetRoomBlocks
	|WHERE
	|	SetRoomBlocks.Posted
	|	AND SetRoomBlocks.Room = &qRoom
	|	AND SetRoomBlocks.DateFrom <= &qCurrentDate
	|	AND (SetRoomBlocks.DateTo > &qCurrentDate
	|			OR SetRoomBlocks.DateTo = &qEmptyDate)
	|
	|ORDER BY
	|	SetRoomBlocks.DateFrom";
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qCurrentDate", CurrentSessionDate());
	vQry.SetParameter("qEmptyDate", '00010101');
	vBlocks = vQry.Execute().Unload();
	If vBlocks.Count() > 0 Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // CheckActiveRoomBlocks

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFromFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		OpenFileDialogToChooseFile(pParam);
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension is being installing on your browser...'; ru='В браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"), MessageStatus.Information);
		BeginInstallFileSystemExtension(New NotifyDescription("LoadFromFileFileSystemExtensionInstallCompleted", ThisObject, pParam));
	EndIf;
EndProcedure // LoadFromFileAttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtServer
Procedure CommandActionLoadFromFileAtServer(pBinaryData, pFileName, pFileLastChangeTime, pPhoto) 
	If pPhoto = "Photo1" Then
		Photo1 = PutToTempStorage(pBinaryData, UUID);
	Else
		Photo2 = PutToTempStorage(pBinaryData, UUID);
	EndIf;
	Modified = True;
EndProcedure // CommandActionLoadFromFileAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure FileDownloadToServerCompletedAtServer(pTransferredFiles, pParams)
	vFileAddress = pTransferredFiles.Get(0).Location;
	vBinaryData = GetFromTempStorage(vFileAddress);
	CommandActionLoadFromFileAtServer(vBinaryData, pParams.File.Name, pParams.File.LastModificationTime, pParams.Photo);
EndProcedure // FileDownloadToServerCompletedAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure FileDownloadToServerCompleted(pTransferredFiles, pParams) Export
	FileDownloadToServerCompletedAtServer(pTransferredFiles, pParams);
EndProcedure // FileDownloadToServerCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFileInWebClient(pFullFileName, pFile, pPhoto)
	vFilesArray = New Array();
	vFileDescription = New TransferableFileDescription(pFullFileName);
	vFilesArray.Add(vFileDescription);
	BeginPuttingFiles(New NotifyDescription("FileDownloadToServerCompleted", ThisObject, New Structure("File, Photo", pFile, pPhoto)), vFilesArray, , False);
EndProcedure // LoadFileInWebClient

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFromFileInstallingFileSystemExtensionResult(pResult, pParam) Export 
	If pResult Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='В браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"), MessageStatus.Information);
		OpenFileDialogToChooseFile(pParam);
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"), MessageStatus.Attention);
	EndIf;
EndProcedure // LoadFromFileInstallingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFromFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromFileInstallingFileSystemExtensionResult", ThisObject, pParam));
EndProcedure // LoadFromFileFileSystemExtensionInstallCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFileGettingModificationTimeCompleted(pModificationTime, pParams) Export
	LoadFileInWebClient(pParams.FullFileName, New Structure("Name, LastModificationTime", pParams.FileName, pModificationTime), pParams.Photo);
EndProcedure // LoadFileGettingModificationTimeCompleted	

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileDialogToChooseFileCompleted(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		vFullFileName = pFileArray[0];
		vFile = New File(vFullFileName);
		vFile.BeginGettingModificationTime(New NotifyDescription("LoadFileGettingModificationTimeCompleted", ThisObject, New Structure("FileName, FullFileName, Photo", vFile.Name, vFullFileName, pParam)));
	EndIf;
EndProcedure // OpenFileDialogToChooseFileCompleted

// --------------------------------------------------------------------------------
&AtClient 
Procedure OpenFileDialogToChooseFile(pParam)
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
	vFileOpen.Show(New NotifyDescription("OpenFileDialogToChooseFileCompleted", ThisObject, pParam));
EndProcedure // OpenFileDialogToChooseFile

// --------------------------------------------------------------------------------
&AtServer
Procedure ClearPhoto1AtServer()
	Photo1 = "";
	Modified = True;
EndProcedure // ClearPhotoAtServer

// --------------------------------------------------------------------------------
&AtServer
Function GetListRooms(pRoomType)
	vListRooms = New ValueList();
	
	vQuery = New Query();
	vQuery.Text = 
	"SELECT
	|	ConRooms.Ref AS Ref,
	|	ConRooms.Room AS Room
	|FROM
	|	Catalog.Rooms.ConnectedRooms AS ConRooms
	|WHERE
	|	ConRooms.Ref <> &qRoom
	|	AND NOT ConRooms.Ref.IsFolder
	|	AND NOT ConRooms.Ref.DeletionMark";
	vQuery.SetParameter("qRoom", Object.Ref);
	vResult = vQuery.Execute().Unload();
	vConnectedRooms = New ValueTable();
	vConnectedRooms.Columns.Add("Room", New TypeDescription("CatalogRef.Rooms"));
	For Each vItems In vResult Do
		vNewRow = vConnectedRooms.Add();
		vNewRow.Room = vItems.Room;
		vNewRow = vConnectedRooms.Add();
		vNewRow.Room = vItems.Ref;
	EndDo;
	
	vQuery = New Query();
	vQuery.Text = 
	"SELECT
	|	Rooms.Ref AS Ref
	|FROM
	|	Catalog.Rooms AS Rooms
	|WHERE
	|	NOT Rooms.DeletionMark
	|	AND NOT Rooms.IsFolder
	|	AND NOT Rooms.Ref IN (&qConnectedRooms)
	|	AND Rooms.RoomType = &qRoomType
	|
	|ORDER BY
	|	Rooms.SortCode";
	vQuery.SetParameter("qConnectedRooms", vConnectedRooms);
	vQuery.SetParameter("qRoomType", pRoomType);
	vResult = vQuery.Execute().Unload();
	
	For Each vRoom In vResult Do
		vListRooms.Add(vRoom.Ref);	
	EndDo;
	Return vListRooms; 
EndFunction // GetListConnectedRooms

// --------------------------------------------------------------------------------
&AtServer
Procedure ClearPhoto2AtServer()
	Photo2 = "";
	Modified = True;
EndProcedure // ClearPhotoAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure FillBedsSetupChoiceList()
	vUseBedsSetup = False;
	If ValueIsFilled(Object.Owner) Then
		vUseBedsSetup = Object.Owner.BedsSetups;
	EndIf;
	Items.BedsSetupIsFixed.Visible = vUseBedsSetup;
	Items.BedsSetup.Visible = vUseBedsSetup;
	Items.BedsSetup.ChoiceList.Clear();
	If vUseBedsSetup Then
		If ValueIsFilled(Object.RoomType) Then
			If Object.RoomType.AllowedBedsSetups.Count() > 0 Then
				For Each vRow In Object.RoomType.AllowedBedsSetups Do
					If Items.BedsSetup.ChoiceList.FindByValue(vRow.BedsSetup) = Undefined Then
						If ValueIsFilled(vRow.BedsSetup) Then
							Items.BedsSetup.ChoiceList.Add(vRow.BedsSetup);
						Else
							Items.BedsSetup.ChoiceList.Insert(0, vRow.BedsSetup, NStr("en='<Empty>'; ru='<Пустая>'; de='<Leer>'"));
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		If Items.BedsSetup.ChoiceList.FindByValue(Object.BedsSetup) = Undefined Then
			Items.BedsSetup.ChoiceList.Insert(0, Object.BedsSetup, ?(ValueIsFilled(Object.BedsSetup), TrimAll(Object.BedsSetup), NStr("en='<Empty>'; ru='<Пустая>'; de='<Leer>'")));
		EndIf;
	EndIf;
EndProcedure

#EndRegion
