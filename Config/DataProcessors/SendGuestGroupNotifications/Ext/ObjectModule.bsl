
#Region Public

// -----------------------------------------------------------------------------
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	// Release room allotments
	pmSend(pIsInteractive);
EndProcedure // pmRun

// -----------------------------------------------------------------------------
Procedure pmSend(pIsInteractive = False) Export
	WriteLogEvent(NStr("en='DataProcessor.SendGuestGroupNotifications';ru='Обработка.ОтправкаУведомленийПоГруппамГостей';de='DataProcessor.SendGuestGroupNotifications'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'"));
	// Get list of notifications to process
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	GuestGroupAttachments.Period AS Period,
	|	GuestGroupAttachments.GuestGroup AS GuestGroup,
	|	GuestGroupAttachments.EMail AS EMail,
	|	GuestGroupAttachments.Fax AS Fax,
	|	GuestGroupAttachments.AttachmentType AS AttachmentType,
	|	GuestGroupAttachments.AttachmentStatus AS AttachmentStatus,
	|	GuestGroupAttachments.DocumentText AS DocumentText,
	|	GuestGroupAttachments.FileName AS FileName,
	|	GuestGroupAttachments.ExtFile AS ExtFile,
	|	GuestGroupAttachments.Remarks AS Remarks,
	|	GuestGroupAttachments.SMSTemplates AS SMSTemplates,
	|	GuestGroupAttachments.ParentDoc AS ParentDoc,
	|	GuestGroupAttachments.Client AS Client,
	|	GuestGroupAttachments.AmountStr AS AmountStr,
	|	GuestGroupAttachments.DiscountCard AS DiscountCard
	|FROM
	|	InformationRegister.GuestGroupAttachments AS GuestGroupAttachments
	|WHERE
	|	NOT GuestGroupAttachments.IsIncoming
	|	AND (GuestGroupAttachments.GuestGroup.Owner IN HIERARCHY (&qHotel)
	|			OR &qHotelIsEmpty)
	|	AND (GuestGroupAttachments.AttachmentStatus = &qReady
	|			OR GuestGroupAttachments.AttachmentStatus = &qError
	|				AND GuestGroupAttachments.GuestGroup.CheckInDate >= &qPeriodFrom)
	|	AND GuestGroupAttachments.AttachmentType = &qTypeEMail
	|	AND GuestGroupAttachments.EMail <> &qEmptyString
	|
	|ORDER BY
	|	GuestGroupAttachments.Period";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qReady", Enums.AttachmentStatuses.Ready);
	vQry.SetParameter("qError", Enums.AttachmentStatuses.Error);
	vQry.SetParameter("qPeriodFrom", BegOfDay(CurrentSessionDate()));
	vQry.SetParameter("qTypeEMail", Enums.AttachmentTypes.EMail);
	vQry.SetParameter("qEmptyString", "");
	vNotifications = vQry.Execute().Unload();
	// Check notification transport type
	For Each vNotificationsRow In vNotifications Do
		Try
			If vNotificationsRow.AttachmentType = Enums.AttachmentTypes.EMail Then
				If Not IsBlankString(vNotificationsRow.EMail) Then  
					SendByEMail(vNotificationsRow); 
				Else
					// Skip partially set up notifications
					vMessage = NStr("en='Notification was not sent because E-Mail is not filled: ';ru='Уведомление не отправлено т.к. не указан E-Mail: ';de='Benachrichtigung wurde nicht abgeschickt, weil die E-Mail nicht angegeben ist: '") + 
							   Format(vNotificationsRow.GuestGroup.Code, "ND=12; NFD=0; NG=") + ", " + 
							   Format(vNotificationsRow.Period, "DF='dd.MM.yyyy HH:mm'") + " - " + 
							   TrimAll(vNotificationsRow.Remarks); 
					If pIsInteractive Then
						tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
					EndIf;
					Continue;
				EndIf;
			Else
				// Skip not supported rows
				Continue;
			EndIf;
			// Update current attachment status
			InformationRegisters.GuestGroupAttachments.UpdateDataByPeriodAndGuestGroup(vNotificationsRow.Period, vNotificationsRow.GuestGroup,,,,,,,,, Enums.AttachmentStatuses.Sent, vNotificationsRow.DocumentText,,,,,,,, vNotificationsRow.Remarks);
			
			// Log current state
			vMessage = NStr("en='Notification sent: ';ru='Отправлено уведомление: ';de='Benachrichtigung versandt: '") + 
			           GetLocalizedAttachmentType(vNotificationsRow.AttachmentType) + " " + GetTarget(vNotificationsRow) + ", " + 
					   Format(vNotificationsRow.GuestGroup.Code, "ND=12; NFD=0; NG=") + ", " + 
					   Format(vNotificationsRow.Period, "DF='dd.MM.yyyy HH:mm'") + " - " + 
					   TrimAll(vNotificationsRow.Remarks); 
			WriteLogEvent(NStr("en='DataProcessor.SendGuestGroupNotifications';ru='Обработка.ОтправкаУведомленийПоГруппамГостей';de='DataProcessor.SendGuestGroupNotifications'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, vMessage);
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
			EndIf;
		Except
			vErrDescription = ErrorDescription();
			vMessage = GetLocalizedAttachmentType(vNotificationsRow.AttachmentType) + " " + GetTarget(vNotificationsRow) + ", " + 
					   Format(vNotificationsRow.GuestGroup.Code, "ND=12; NFD=0; NG=") + ", " + 
					   Format(vNotificationsRow.Period, "DF='dd.MM.yyyy HH:mm'") + " - " + 
					   TrimAll(vNotificationsRow.Remarks) + Chars.LF +  
			           vErrDescription;
			WriteLogEvent(NStr("en='DataProcessor.SendGuestGroupNotifications';ru='Обработка.ОтправкаУведомленийПоГруппамГостей';de='DataProcessor.SendGuestGroupNotifications'"), EventLogLevel.Warning, ThisObject.Metadata(), Undefined, vMessage);
			// Update current attachment status
			If StrFind(vErrDescription, "554 5.5.1") > 0 Or StrFind(vErrDescription, "no valid recipients") > 0 Then
				vError = Enums.AttachmentStatuses.InvalidAddress;
			Else
				vError = Enums.AttachmentStatuses.Error;
			EndIf;
			InformationRegisters.GuestGroupAttachments.UpdateDataByPeriodAndGuestGroup(vNotificationsRow.Period, vNotificationsRow.GuestGroup, , , , , , , , , vError, vNotificationsRow.DocumentText, , , , , , , , vNotificationsRow.Remarks);
			// Exit
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			EndIf;
		EndTry;
	EndDo;
	WriteLogEvent(NStr("en='DataProcessor.SendGuestGroupNotifications';ru='Обработка.ОтправкаУведомленийПоГруппамГостей';de='DataProcessor.SendGuestGroupNotifications'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'"));
EndProcedure // pmSend

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure SendByEMail(pNotificationRow)
	// Get current employee settings
	vCurEmployee = SessionParameters.CurrentUser;
	If Not ValueIsFilled(vCurEmployee) Then
		vError = NStr("ru = 'Невозможно отправить сообщение " + TrimAll(pNotificationRow.Remarks) + " по электронной почте на адрес " + TrimAll(pNotificationRow.EMail) + "! Не определен текущий пользователь!'; 
		              |de = 'Unable to send notification " + TrimAll(pNotificationRow.Remarks) + " by e-mail to " + TrimAll(pNotificationRow.EMail) + "! Current user is not defined!'; 
		              |en = 'Unable to send notification " + TrimAll(pNotificationRow.Remarks) + " by e-mail to " + TrimAll(pNotificationRow.EMail) + "! Current user is not defined!'");
		Raise vError;
	EndIf;
	
	// Addresses and names
	vSenderName = vCurEmployee.GetObject().pmGetEmployeeDescription(SessionParameters.CurrentLanguage);
	vFrom = TrimAll(vCurEmployee.EMail);
	
	vReplyToEMail = New Array;
	If Not IsBlankString(vCurEmployee.ReplyToEMail) Then
		vEMailsList = cmParseEMailAddress(TrimAll(vCurEmployee.ReplyToEMail));
		For Each vEMailItem In vEMailsList Do
			vReplyToEMail.Add(vEMailItem.Value);
		EndDo;
	EndIf;               
	vToEMail = New Array;
	// Add to address
	vEMailsList = cmParseEMailAddress(TrimAll(pNotificationRow.EMail));
	For Each vEMailItem In vEMailsList Do
		vToEMail.Add(vEMailItem.Value);  
	EndDo; 
	vBCCEMail = New Array;
	// Add Bcc address
	If Not IsBlankString(vCurEmployee.BccEMail) Then
		vEMailsList = cmParseEMailAddress(vCurEmployee.BccEMail);
		For Each vEMailItem In vEMailsList Do
			vBCCEMail.Add(vEMailItem.Value);
		EndDo;
	EndIf;
	
	vAttachments = New Map;
	// Add file as attachement
	If Not IsBlankString(pNotificationRow.FileName) Then
		// Save file to the temp directory 
		vFileName = cmGetValidFileName(pNotificationRow.FileName);
		vFullFileName = TempFilesDir() + vFileName;
		vAttachments.Insert(vFileName, vFullFileName); 
		vBinary = pNotificationRow.ExtFile.Get();
		vBinary.Write(vFullFileName);
	EndIf;
	
	EMail.Send(vCurEmployee, vSenderName, vFrom, pNotificationRow.Remarks, pNotificationRow.DocumentText, pNotificationRow.SMSTemplates, pNotificationRow.ParentDoc, pNotificationRow.Client, pNotificationRow.AmountStr, pNotificationRow.DiscountCard, , vAttachments, vToEMail, vReplyToEMail, , vBCCEMail);
EndProcedure // SendByEMail

// -----------------------------------------------------------------------------
Function GetLocalizedAttachmentType(pAttachmentType)
	If pAttachmentType = Enums.AttachmentTypes.EMail Then
		Return NStr("en='E-Mail'; de='E-Mail'; ru='E-Mail'");
	ElsIf pAttachmentType = Enums.AttachmentTypes.Fax Then
		Return NStr("en='Fax';ru='Факс';de='Fax'");
	Else
		Return "<?>";
	EndIf;
EndFunction // GetLocalizedAttachmentType

// -----------------------------------------------------------------------------
Function GetTarget(pNotificationsRow)
	If pNotificationsRow.AttachmentType = Enums.AttachmentTypes.EMail Then
		Return TrimAll(pNotificationsRow.EMail);
	ElsIf pNotificationsRow.AttachmentType = Enums.AttachmentTypes.Fax Then
		Return TrimAll(pNotificationsRow.Fax);
	EndIf;
	Return "";
EndFunction // GetTarget

#EndRegion
