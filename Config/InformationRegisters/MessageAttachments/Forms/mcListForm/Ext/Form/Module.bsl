
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	Items.FormAddAttachments.Visible = False;
	Items.PictureListMessage.Visible = True;
	If Parameters.Filter.Property("Message") Then
		SelMessage = Parameters.Filter.Message;
		If ValueIsFilled(SelMessage) Then
			Title = SelMessage;
			Items.PictureListMessage.Visible = False;
			Items.FormAddAttachments.Visible = True;
		EndIf;
	EndIf;
	FillList();
	SelectedAttachment = 0;
	Items.AttachmentPages.CurrentPage = Items.AttachmentPage;
	NotificationUUID = New UUID();
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormTableItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure PictureListBeforeDeleteRow(pItem, pCancel)
	vSelectedRows = Items.PictureList.SelectedRows;
	For Each vRow In vSelectedRows Do 
		vCurData = PictureList.FindByID(vRow);
		If vCurData <> Undefined Then
			PictureListBeforeDeleteRowAtServer(vCurData.Period, vCurData.Message);
		EndIf;
	EndDo;
	FillList();
EndProcedure // PictureListBeforeDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure PictureListSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	vCurRow = pItem.CurrentData; 
	If vCurRow <> Undefined Then   
		vFormParam = New Structure("SelMessage, SelPeriod, SelPicture", vCurRow.Message, vCurRow.Period, vCurRow.Picture);
		OpenForm("InformationRegister.MessageAttachments.Form.mcShowPicture", vFormParam, ThisObject, UUID,,, New NotifyDescription("AfterCloseShowPicture", ThisObject));
	EndIf;
EndProcedure // PictureListSelection

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure AttachmentPagesOnCurrentPageChange(pItem, pCurrentPage)
	vAttachmentsListCount = AttachmentsList.Count();
	If vAttachmentsListCount > 0 Then
		If pCurrentPage.Name = "LeftPage" Then
			If SelectedAttachment > 0 Then
				SelectedAttachment = SelectedAttachment - 1;	
			EndIf;	
		ElsIf pCurrentPage.Name = "RightPage" Then 
			If SelectedAttachment < vAttachmentsListCount - 1 Then
				SelectedAttachment = SelectedAttachment + 1;	
			EndIf;
		EndIf;
		AttachmentsPhoto = MessageAttachments.Get(AttachmentsList.Get(SelectedAttachment).Value).Attachments;
	EndIf;
	Items.AttachmentPages.CurrentPage = Items.AttachmentPage;
	DecorationInfoPhotoRepresentation();
EndProcedure // AttachmentPagesOnCurrentPageChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AddAttachmentsPhotoDelete(pCommand)
	vCurData = MessageAttachments.Get(AttachmentsList.Get(SelectedAttachment).Value);
	If vCurData <> Undefined Then
		vAttachments = vCurData.Attachments;
		If ValueIsFilled(vAttachments) And IsTempStorageURL(vAttachments) Then
			DeleteFromTempStorage(vAttachments);	
		EndIf;
		MessageAttachments.Delete(vCurData);
		ShowUserNotification(NStr("en = 'Photo deleted'; de = 'Foto gelöscht'; ru = 'Фотография удалена'"),,,,UserNotificationStatus.Information, NotificationUUID);
		FillAttachmentsList();
	EndIf;
EndProcedure // AddAttachmentsPhotoDelete

// -----------------------------------------------------------------------------
&AtClient
Procedure AttachmentPageChangePhoto(pCommand)
	Items.AttachmentPageActions.Visible = False;
	Items.AttachmentPageActionsChange.Visible = True;
EndProcedure // AttachmentPageChangePhoto

// -----------------------------------------------------------------------------
&AtClient
Procedure AddAttachmentsPhotoСhangeGallery(pCommand)
	vCurData = MessageAttachments.Get(AttachmentsList.Get(SelectedAttachment).Value);
	If vCurData <> Undefined Then
		#IF MobileClient THEN
			// ACC:566-off Sync methods support ON. Allows use of platform versions below 8.3.18
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
			If vFileSelection.Choose() Then 
				vBinaryData = New BinaryData(vFileSelection.FullFileName);
				vCurData.Attachments = PutToTempStorage(vBinaryData, ThisObject.UUID);
				vCurData.FileExtention = "jpg"; 
				Items.AttachmentPageActionsChange.Visible = False;
				Items.AddAttachmentsPhotoButtons.Visible = True;
				FillAttachmentsList();
				ShowUserNotification(NStr("en = 'Photo changed'; de = 'Foto geändert'; ru = 'Фотография изменена'"),,,,UserNotificationStatus.Information, NotificationUUID);
			Else	
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'File upload failed'; de = 'Die Datei konnte nicht geladen werden'; ru = 'Не удалось загрузить файл'"));	
			EndIf;
			// ACC:566-on sync methods support OFF
		#ENDIF
	EndIf;
EndProcedure // AddAttachmentsPhotoСhangeGallery

// -----------------------------------------------------------------------------
&AtClient
Procedure AddAttachmentsPhotoСhange(pCommand)
	vCurData = MessageAttachments.Get(AttachmentsList.Get(SelectedAttachment).Value);
	If vCurData <> Undefined Then
		#IF MobileClient THEN
			vResult = Undefined;
			If MultimediaTools.PhotoSupported(DeviceCameraType.Rear) Then
				vResult = MultimediaTools.MakePhoto(DeviceCameraType.Rear);	
			Else
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'This device does not support creating photos'; de = 'Dieses Gerät unterstützt keine fotoerstellung'; ru = 'Данное устройство не поддерживает создание фото'"));
			EndIf;			
			If vResult <> Undefined Then
				vBinaryData = vResult.GetBinaryData();
				vCurData.Attachments = PutToTempStorage(vBinaryData, ThisObject.UUID);
				vCurData.FileExtention = "jpg"; 
				FillAttachmentsList();
				ShowUserNotification(NStr("en = 'Photo changed'; de = 'Foto geändert'; ru = 'Фотография изменена'"),,,,UserNotificationStatus.Information, NotificationUUID);
			Else
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Failed to take a picture'; de = 'Das Bild konnte nicht aufgenommen werden'; ru = 'Не удалось сделать снимок'"));	
			EndIf;
		#ENDIF
	EndIf;
EndProcedure // AddAttachmentsPhotoСhange

// -----------------------------------------------------------------------------
&AtClient
Procedure AddAttachmentsPhotoСhangeCancel(pCommand)
	Items.AttachmentPageActions.Visible = True;
	Items.AttachmentPageActionsChange.Visible = False;	
EndProcedure // AddAttachmentsPhotoСhangeCancel

// -----------------------------------------------------------------------------
&AtClient
Procedure AddAttachmentsPhoto(pCommand)
	Items.GroupPhoto.Visible = True;
	Items.AddAttachmentsPhotoButtons.Visible = False;
EndProcedure // AddAttachmentsPhoto

// -----------------------------------------------------------------------------
&AtClient
Procedure AddAttachmentsPhotoGallery(pCommand)
	#IF MobileClient THEN
		// ACC:566-off Sync methods support ON. Allows use of platform versions below 8.3.18
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
		If vFileSelection.Choose() Then 
			vBinaryData = New BinaryData(vFileSelection.FullFileName);
			vNewAttachments = MessageAttachments.Add();
			vNewAttachments.Attachments = PutToTempStorage(vBinaryData, ThisObject.UUID);
			vNewAttachments.FileExtention = "jpg"; 
			Items.GroupPhoto.Visible = False;
			Items.AddAttachmentsPhotoButtons.Visible = True;
			FillAttachmentsList();
			ShowUserNotification(NStr("en = 'Photo added'; de = 'Foto Hinzugefügt'; ru = 'Фотография добавлена'"),,,,UserNotificationStatus.Information, NotificationUUID);
		Else	
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'File upload failed'; de = 'Die Datei konnte nicht geladen werden'; ru = 'Не удалось загрузить файл'"));	
		EndIf;
		// ACC:566-on sync methods support OFF
	#ENDIF
EndProcedure // AddAttachmentsPhotoGallery

// -----------------------------------------------------------------------------
&AtClient
Procedure AddAttachmentsPhotoTakePictures(pCommand)
	#IF MobileClient THEN
		vResult = Undefined;
		
		If MultimediaTools.PhotoSupported(DeviceCameraType.Rear) Then
			vResult = MultimediaTools.MakePhoto(DeviceCameraType.Rear);	
		Else
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'This device does not support creating photos'; de = 'Dieses Gerät unterstützt keine fotoerstellung'; ru = 'Данное устройство не поддерживает создание фото'"));
		EndIf;
		
		If vResult <> Undefined Then
			vNewAttachments = MessageAttachments.Add();
			vBinaryData = vResult.GetBinaryData();
			vNewAttachments.Attachments = PutToTempStorage(vBinaryData, ThisObject.UUID);
			vNewAttachments.FileExtention = "jpg"; 
			Items.GroupPhoto.Visible = False;
			Items.AddAttachmentsPhotoButtons.Visible = True;
			FillAttachmentsList();
			ShowUserNotification(NStr("en = 'Photo added'; de = 'Foto Hinzugefügt'; ru = 'Фотография добавлена'"),,,,UserNotificationStatus.Information, NotificationUUID);	
		Else
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Failed to take a picture'; de = 'Das Bild konnte nicht aufgenommen werden'; ru = 'Не удалось сделать снимок'"));	
		EndIf;
	#ENDIF
EndProcedure // AddAttachmentsPhotoTakePictures

// -----------------------------------------------------------------------------
&AtClient
Procedure AddAttachmentsPhotoCancel(pCommand)
	Items.GroupPhoto.Visible = False;
	Items.AddAttachmentsPhotoButtons.Visible = True;	
EndProcedure // AddAttachmentsPhotoCancel

// -----------------------------------------------------------------------------
&AtClient
Procedure AddAttachments(pCommand)
	If Not Items.FormAddAttachments.Check And Not ValueIsFilled(SelMessage) Then
		Return;	
	ElsIf Items.FormAddAttachments.Check And MessageAttachments.Count() > 0 Then
		ShowQueryBox(New NotifyDescription("AfterShowQueryBoxByCloseAddAttachments", ThisForm), NStr("en = 'Do you want to save your changes?'; de = 'Willst du deine Änderungen speichern?'; ru = 'Хотите сохранить изменения?'"), QuestionDialogMode.YesNoCancel,,, NStr("en = 'Confirmation'; de = 'Bestätigung'; ru = 'Подтверждение'"));	
		Return;
	EndIf;
	Items.FormAddAttachments.Check = Not Items.FormAddAttachments.Check;
	Items.PictureList.Visible = Not Items.FormAddAttachments.Check;
	Items.GroupAddAttachmentsTask.Visible = Items.FormAddAttachments.Check;
	If Not Items.FormAddAttachments.Check Then
		CurrentItem = Items.PictureList;
	Else
		FillAttachmentsList();
	EndIf;
EndProcedure // AddAttachments

// -----------------------------------------------------------------------------
&AtClient
Procedure AddAttachmentsSave(pCommand)
	// add code to save new task
	vResult = SaveTaskAtServer();
	If vResult Then
		AfterNewTask();
	EndIf;
EndProcedure // AddAttachmentsSave

// -----------------------------------------------------------------------------
&AtClient
Procedure AddAttachmentsCancel(pCommand)
	AfterNewTask();
EndProcedure // AddAttachmentsCancel

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure FillList()
	PictureList.Clear();
	vQuery = New Query();
	vQuery.Text = 
	"SELECT
	|	MessageAttachments.Period AS Period,
	|	MessageAttachments.ExtFile AS ExtFile,
	|	MessageAttachments.FileName AS FileName,
	|	MessageAttachments.FileLoadTime AS FileLoadTime,
	|	MessageAttachments.Message AS Message
	|FROM
	|	InformationRegister.MessageAttachments AS MessageAttachments
	|WHERE
	|	CASE
	|			WHEN &qMessage <> VALUE(Document.Message.EmptyRef)
	|				THEN MessageAttachments.Message = &qMessage
	|			ELSE TRUE
	|		END
	|
	|ORDER BY
	|	MessageAttachments.Message,
	|	FileLoadTime";
	vQuery.SetParameter("qMessage", SelMessage);
	vList = vQuery.Execute().Unload();
	For Each vRow In vList Do
		If CheckIsPicture(vRow.FileName) Then
			vPicture = vRow.ExtFile.Get();
			If vPicture <> Undefined Then
				vNewRow = PictureList.Add();
				vNewRow.Message = vRow.Message;
				vNewRow.Period = vRow.Period;
				vNewRow.Picture = PutToTempStorage(vPicture, UUID);
			EndIf;
		EndIf;
	EndDo;
EndProcedure // FillList

// -----------------------------------------------------------------------------
&AtServer
Function CheckIsPicture(pName)
	vResult = False;
	vStartPos = StrFind(pName, ".", SearchDirection.FromEnd);
	If vStartPos <> 0 Then
		vFormat = Right(pName, StrLen(pName) - vStartPos + 1);
		If vFormat = ".bmp" Or vFormat = ".dib" Or vFormat = ".rle" Or vFormat = ".jpg" Or vFormat = ".jpeg" Or 
		   vFormat = ".tif" Or vFormat = ".gif" Or vFormat = ".png" Or vFormat = ".ico" Or vFormat = ".wmf" Or vFormat = ".emf" Then
			vResult = True;
		EndIf;
	EndIf;
	Return vResult;
EndFunction // CheckIsPicture

// -----------------------------------------------------------------------------
&AtServer
Procedure PictureListBeforeDeleteRowAtServer(pPeriod, pMessage)
	vRecSet 							= InformationRegisters.MessageAttachments.CreateRecordSet();
	vRecSet.Filter.Message.Use			= True;
	vRecSet.Filter.Message.Value 		= pMessage;
	vRecSet.Filter.Period.Use			= True;
	vRecSet.Filter.Period.Value			= pPeriod;
	vRecSet.Read();
	vRecSet.Clear();
	vRecSet.Write(True);
EndProcedure // PictureListBeforeDeleteRowAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterCloseShowPicture(pValue, pExtraParams) Export 
	If pValue <> Undefined And pValue Then
		FillList();	
	EndIf;
EndProcedure // AfterCloseShowPicture

// -----------------------------------------------------------------------------
&AtClient
Procedure PictureListRefreshRequestProcessing()
	FillList();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterShowQueryBoxByCloseAddAttachments(pResult, pExtraParams) Export 
	If pResult = DialogReturnCode.Yes Then
		AddAttachmentsSave(Commands["AddAttachmentsSave"]);	
	ElsIf pResult = DialogReturnCode.No Then
		AddAttachmentsCancel(Commands["AddAttachmentsCancel"]);	
	EndIf;
EndProcedure // AfterShowQueryBoxByCloseAddAttachments

// -----------------------------------------------------------------------------
&AtServer
Function SaveTaskAtServer()
	vResult = False;
	Try
		vNumber = 0;
		For Each vRowItem In MessageAttachments Do
			vBinaryData = Undefined;
			If ValueIsFilled(vRowItem.Attachments) Then
				If IsTempStorageURL(vRowItem.Attachments) Then	
					vBinaryData = GetFromTempStorage(vRowItem.Attachments);	
				EndIf;
			EndIf;
			// Attach photo to this message
			If vBinaryData <> Undefined Then
				vNumber = vNumber + 1;
				// Add record to the message attachments register
				vRcdMgr = InformationRegisters.MessageAttachments.CreateRecordManager();
				vRcdMgr.Period             = CurrentSessionDate() + vNumber;
				vRcdMgr.Message            = SelMessage.Ref;
				vRcdMgr.Author             = SelMessage.Author;
				vRcdMgr.ExtFile            = New ValueStorage(New Picture(vBinaryData, False));
				vRcdMgr.FileName           = "foto_" + TrimAll(SelMessage.ByObject) + "_" + Format(CurrentSessionDate(), "DF=yyyy-MM-dd_HHmm") + "." + TrimAll(vRowItem.FileExtention);
				vRcdMgr.FileLoadTime       = vRcdMgr.Period;
				vRcdMgr.FileLastChangeTime = vRcdMgr.Period;
				vRcdMgr.Write();
			EndIf;
		EndDo;
		vResult = True;
	Except
		vErrorInfo = ErrorInfo();
		tcCommonFunctionOnClientServer.TextMessage(BriefErrorDescription(vErrorInfo));
		WriteLogEvent(NStr("en='Recording a new Task';ru='Запись новой задачи';de='Aufnahme einer neuen Aufgabe'"), EventLogLevel.Error, , , DetailErrorDescription(vErrorInfo));
	EndTry;
	Return vResult;
EndFunction // SaveTaskAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterNewTask() 
	For Each vRowItem In MessageAttachments Do
		If ValueIsFilled(vRowItem.Attachments) Then
			If IsTempStorageURL(vRowItem.Attachments) Then
				DeleteFromTempStorage(vRowItem.Attachments);	
			EndIf;
		EndIf;
	EndDo;
	MessageAttachments.Clear();
	Items.AddAttachmentsPhotoButtons.Visible = True;
	Items.GroupPhoto.Visible = False;
	FillAttachmentsList();
	SelectedAttachment = 0;
	FillList();
	AddAttachments(Commands["AddAttachments"]);
EndProcedure // AfterNewTask

// -----------------------------------------------------------------------------
&AtClient
Procedure DecorationInfoPhotoRepresentation()
	vAttachmentsListCount = AttachmentsList.Count();
	vText = TrimAll(?(vAttachmentsListCount > 0,SelectedAttachment + 1, 0)) + NStr("en = ' of '; de = ' von '; ru = ' из '") + TrimAll(AttachmentsList.Count());
	If vAttachmentsListCount > 1 Then
		vText = vText + Chars.LF;
		If SelectedAttachment = 0 Then
			vText = vText + NStr("en = ' swipe '; de = ' streichen '; ru = ' пролистните '") + Char(10095);		
		ElsIf SelectedAttachment > 0 And SelectedAttachment < vAttachmentsListCount - 1 Then
			vText = vText + Char(10094) + NStr("en = ' swipe '; de = ' streichen '; ru = ' пролистните '") + Char(10095);	
		ElsIf SelectedAttachment = vAttachmentsListCount - 1 Then
			vText = vText + Char(10094) + NStr("en = ' swipe '; de = ' streichen '; ru = ' пролистните '");	
		EndIf;
	EndIf;
	Items.DecorationInfoPhoto.Title = vText;
EndProcedure // DecorationInfoPhotoRepresentation

// -----------------------------------------------------------------------------
&AtClient
Procedure FillAttachmentsList()
	AttachmentsList = New ValueList();
	For Each vRowItem In MessageAttachments Do
		AttachmentsList.Add(MessageAttachments.IndexOf(vRowItem));	
	EndDo;
	If AttachmentsList.Count() > 0 Then
		If SelectedAttachment > AttachmentsList.Count() - 1 Then
			SelectedAttachment = AttachmentsList.Count() - 1;
		EndIf;
		AttachmentsPhoto = MessageAttachments.Get(AttachmentsList.Get(SelectedAttachment).Value).Attachments;
		Items.AttachmentPageActions.Visible = True;
	Else
		AttachmentsPhoto = "";
		Items.AttachmentPageActions.Visible = False;
		SelectedAttachment = 0;
	EndIf;
	DecorationInfoPhotoRepresentation();
EndProcedure // FillAttachmentsList

#EndRegion
