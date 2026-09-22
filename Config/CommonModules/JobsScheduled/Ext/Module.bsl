
#Region Public

// --------------------------------------------------------------------------------
Function cmCreateCloseOfPeriodJob(pCompany, pHotel, pDescription, pUserName) Export
	vJob = ScheduledJobs.CreateScheduledJob(Metadata.ScheduledJobs.CloseOfPeriodJob);
	vJob.Use = True;
	vJob.Description = TrimAll(pDescription);
	vJob.UserName = TrimAll(pUserName);
	vJobParameters = New Array();
	vJobParameters.Add(pCompany);
	vJobParameters.Add(pHotel);
	vJob.Parameters = vJobParameters;
	vJob.Write();
	Return vJob.UUID;
EndFunction // cmCreateCloseOfPeriodJob

// --------------------------------------------------------------------------------
Procedure cmUpdateCloseOfPeriodJob(pJobUUID, pCompany, pHotel, pDescription, pUserName) Export
	vJob = ScheduledJobs.FindByUUID(New UUID(pJobUUID));
	If vJob <> Undefined Then
		vJob.Description = TrimAll(pDescription);
		vJob.UserName = TrimAll(pUserName);
		vJobParameters = New Array();
		vJobParameters.Add(pCompany);
		vJobParameters.Add(pHotel);
		vJob.Parameters = vJobParameters;
		vJob.Write();
	EndIf;
EndProcedure // cmUpdateCloseOfPeriodJob

// --------------------------------------------------------------------------------
Procedure cmDeleteCloseOfPeriodJob(pJobUUID) Export
	vJob = ScheduledJobs.FindByUUID(New UUID(pJobUUID));
	If vJob <> Undefined Then
		vJob.Delete();
	EndIf;
EndProcedure // cmDeleteCloseOfPeriodJob

// --------------------------------------------------------------------------------
Function cmGetCloseOfPeriodJob(pJobUUID) Export
	vJob = ScheduledJobs.FindByUUID(New UUID(pJobUUID));
	Return vJob;
EndFunction // cmGetCloseOfPeriodJob
                                         
// --------------------------------------------------------------------------------
Procedure cmProcessCloseOfPeriodJob(pCompany, pHotel) Export
	If ValueIsFilled(pCompany) Then
		If ValueIsFilled(pHotel) Then
			vCloseOfPeriodObj = Documents.CloseOfPeriod.CreateDocument();
			vCloseOfPeriodObj.Fill(pCompany);
			vCloseOfPeriodObj.Hotel = pHotel;
			vCloseOfPeriodObj.Write(DocumentWriteMode.Posting);
		Else
			vError = "";
			// Get hotels that work with this company
			vQry = New Query();
			vQry.Text = 
			"SELECT DISTINCT
			|	Charge.Hotel AS Hotel,
			|	Charge.Hotel.SortCode AS SortCode,
			|	Charge.Hotel.Code AS Code
			|FROM
			|	Document.Charge AS Charge
			|WHERE
			|	Charge.Company = &qCompany
			|	AND Charge.Posted
			|
			|ORDER BY
			|	SortCode,
			|	Code";
			vQry.SetParameter("qCompany", pCompany);
			vHotels = vQry.Execute().Unload();
			For Each vHotelsRow In vHotels Do
				Try
					vCloseOfPeriodObj = Documents.CloseOfPeriod.CreateDocument();
					vCloseOfPeriodObj.Fill(pCompany);
					vCloseOfPeriodObj.Hotel = vHotelsRow.Hotel;
					vCloseOfPeriodObj.Write(DocumentWriteMode.Posting);
				Except
					vError = ?(IsBlankString(vError), "", Chars.LF + Chars.LF) + cmGetRootErrorDescription(ErrorInfo());
				EndTry;
			EndDo;
			If Not IsBlankString(vError) Then
				Raise vError;
			EndIf;
		EndIf;
	Else
		Raise NStr("en='Company should be specified for close of period to run!'; ru='Для выполнения закрытия периода должна быть указана фирма!'; de='Eine Firma muss angegeben werden, um die Periode schließen zu erfüllen!'");
	EndIf;
EndProcedure // cmProcessCloseOfPeriodJob 

// --------------------------------------------------------------------------------
Function cmCreateSMSAutoDeliveryJob(pHotel, pUser, pDeliveryTemplate, pDeliveryType, pDeliveryFilter, pMessageTemplate, pSender, pDescription, pNumberOfDays = 0, pFlag = Undefined, pImportantDateType = Undefined) Export
	vJob = ScheduledJobs.CreateScheduledJob(Metadata.ScheduledJobs.SMSAutoDelivery);
	vJob.Use = pFlag;
	vJob.Description = TrimAll(pDescription);
	If ValueIsFilled(pUser) Then                
		vUserUUIDs = cmGetUserUUIDsByEmployee(pUser);
		For Each vUserUUID In vUserUUIDs Do  	          
			Try
				vInfoBaseUser = InfoBaseUsers.FindByUUID(New UUID(TrimAll(vUserUUID.UserUUID)));
				If vInfoBaseUser <> Undefined Then
					vJob.UserName = TrimAll(vInfoBaseUser.Name);
					Break;      
				EndIf
			Except
				Continue;
			EndTry;
		EndDo;
	EndIf;
	vJobParameters = New Array();
	vJobParameters.Add(pHotel);
	vJobParameters.Add(pSender);
	vJobParameters.Add(pDeliveryTemplate);
	vJobParameters.Add(pMessageTemplate);
	vJobParameters.Add(pDeliveryType);
	vJobParameters.Add(pDeliveryFilter);
	vJobParameters.Add(pNumberOfDays);
	vJobParameters.Add(pImportantDateType);
	vJob.Parameters = vJobParameters;
	vJob.Write();
	Return vJob.UUID;
EndFunction // cmCreateSMSAutoDeliveryJob

// --------------------------------------------------------------------------------
Procedure cmUpdateSMSAutoDeliveryJob(pJobUUID, pHotel, pUser, pDeliveryTemplate, pDeliveryType, pDeliveryFilter, pMessageTemplate, pSender, pDescription, pNumberOfDays = 0, pFlag = Undefined, pImportantDateType = Undefined) Export
	vJob = ScheduledJobs.FindByUUID(New UUID(pJobUUID));
	If vJob <> Undefined Then
		If pFlag <> Undefined Then
			vJob.Use = vJob;	
		EndIf;
		vJob.Description = TrimAll(pDescription);
		vJob.UserName = TrimAll(pUser);
		vJobParameters = New Array();
		vJobParameters.Add(pHotel);
		vJobParameters.Add(pSender);
		vJobParameters.Add(pDeliveryTemplate);
		vJobParameters.Add(pMessageTemplate);
		vJobParameters.Add(pDeliveryType);
		vJobParameters.Add(pDeliveryFilter); 
		vJobParameters.Add(pNumberOfDays);
		vJobParameters.Add(pImportantDateType);
		vJob.Parameters = vJobParameters;
		vJob.Write();
	EndIf;
EndProcedure // cmUpdateSMSAutoDeliveryJob

// --------------------------------------------------------------------------------
Procedure cmDeleteSMSAutoDeliveryJob(pJobUUID) Export
	vJob = ScheduledJobs.FindByUUID(New UUID(pJobUUID));
	If vJob <> Undefined Then
		vJob.Delete();
	EndIf;
EndProcedure // cmDeleteSMSAutoDeliveryJob

// --------------------------------------------------------------------------------
Function cmGetSMSAutoDeliveryJob(pJobUUID) Export
	vJob = ScheduledJobs.FindByUUID(New UUID(pJobUUID));
	Return vJob;
EndFunction // cmGetSMSAutoDeliveryJob

// --------------------------------------------------------------------------------
Procedure cmLoadCurrencyRatesForTomorrow() Export
	// Reference to the appropriate data processor catalog item object
	vDPRef = Catalogs.DataProcessors.LoadCurrencyRatesForTomorrow;
	// Call load rates procedure for every hotel defined
	vHotels = cmGetAllHotels();
	For Each vHotelsRow In vHotels Do
		// Run data processor
		cmRunDataProcessor(vDPRef, vHotelsRow.Hotel);
	EndDo;
EndProcedure // cmLoadCurrencyRatesForTomorrow

// --------------------------------------------------------------------------------
// Description: Runs "Disable no-show reservations" data processor for the all 
//              hotels defined
// Parameters: None
// Return value: None
// --------------------------------------------------------------------------------
Procedure cmDisableNoShowReservationsForToday() Export
	// Reference to the appropriate data processor catalog item object
	vDPRef = Catalogs.DataProcessors.DisableNoShowReservations;
	// Call disable no show reservations data processor for every hotel defined
	vHotels = cmGetAllHotels();
	For Each vHotelsRow In vHotels Do
		// Run data processor
		cmRunDataProcessor(vDPRef, vHotelsRow.Hotel);
	EndDo;
EndProcedure // cmDisableNoShowReservationsForToday

// --------------------------------------------------------------------------------
// Description: Runs "Release expired room allotments" data processor for the all 
//              hotels defined
// Parameters: None
// Return value: None
// --------------------------------------------------------------------------------
Procedure cmReleaseExpiredRoomAllotments() Export
	// Reference to the appropriate data processor catalog item object
	vDPRef = Catalogs.DataProcessors.ReleaseExpiredRoomAllotments;
	// Call release expired room allotments data processor for every hotel defined
	vHotels = cmGetAllHotels();
	For Each vHotelsRow In vHotels Do
		// Run data processor
		cmRunDataProcessor(vDPRef, vHotelsRow.Hotel);
	EndDo;
EndProcedure // cmReleaseExpiredRoomAllotments

// --------------------------------------------------------------------------------
// Description: Runs "Process finished resource reservations" data processor for the all 
//              hotels defined
// Parameters: None
// Return value: None
// --------------------------------------------------------------------------------
Procedure cmProcessFinishedResourceReservations() Export
	// Reference to the appropriate data processor catalog item object
	vDPRef = Catalogs.DataProcessors.ProcessFinishedResourceReservations;
	// Call data processor for every hotel defined
	vHotels = cmGetAllHotels();
	For Each vHotelsRow In vHotels Do
		// Run data processor
		cmRunDataProcessor(vDPRef, vHotelsRow.Hotel);
	EndDo;
EndProcedure // cmProcessFinishedResourceReservations

// --------------------------------------------------------------------------------
// Description: Runs "Manage Has room blocks flag" data processor for the all 
//              hotels defined
// Parameters: None
// Return value: None
// --------------------------------------------------------------------------------
Procedure cmManageHasRoomBlocks(pKey = "") Export
	// Reference to the appropriate data processor catalog item object
	vDPRef = Catalogs.DataProcessors.ManageHasRoomBlocks;
	// Call data processor for every hotel defined
	vHotels = cmGetAllHotels();
	For Each vHotelsRow In vHotels Do
		// Run data processor
		cmRunDataProcessor(vDPRef, vHotelsRow.Hotel);
	EndDo;
EndProcedure // cmManageHasRoomBlocks

// --------------------------------------------------------------------------------
//  Description: Runs "Clear database" data processor for the all hotels defined
//
// Parameters:
//  pKey - String - Key
//
Procedure cmClearDatabase(pKey = "") Export
	// Reference to the appropriate data processor catalog item object
	vDPRef = Catalogs.DataProcessors.ClearDatabase;
	// Call clear database data processor for every hotel defined
	vHotels = cmGetAllHotels();
	For Each vHotelsRow In vHotels Do
		// Run data processor
		cmRunDataProcessor(vDPRef, vHotelsRow.Hotel);
	EndDo;
EndProcedure // cmClearDatabase

// --------------------------------------------------------------------------------
// Description: Runs data processors found by key string
// Parameters: Key string
// Return value: None
// --------------------------------------------------------------------------------
Procedure cmRunDataProcessorsByKey(pKey) Export
	// Get catalog items by key
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	DataProcessors.Ref AS DataProcessor
	|FROM
	|	Catalog.DataProcessors AS DataProcessors
	|WHERE
	|	DataProcessors.Key = &qKey
	|	AND DataProcessors.DeletionMark = FALSE
	|ORDER BY
	|	DataProcessors.SortCode";
	vQry.SetParameter("qKey", pKey);
	vDPList = vQry.Execute().Unload();
	// Run all retrieved data processors
	For Each vDPRow In vDPList Do
		vDPRef = vDPRow.DataProcessor;
		cmRunDataProcessor(vDPRef);
	EndDo;
EndProcedure // cmRunDataProcessorsByKey

// --------------------------------------------------------------------------------
// Description: Runs reports found by key string
// Parameters: Key string
// Return value: None
// --------------------------------------------------------------------------------
Procedure cmRunReportsByKey(pKey) Export
	// Add record to the information register
	vRecordManager = InformationRegisters.ScheduledReports.CreateRecordManager();
	vRecordManager.ScheduleDateTime = CurrentSessionDate();
	vRecordManager.Key = TrimR(pKey);
	vRecordManager.Write(True);
EndProcedure // cmRunReportsByKey

// --------------------------------------------------------------------------------
// Description: Sends text by e-mail
// Parameters: Message subject, Message text, E-Mails list, Whether fuction is called in 
//             the application server context
// Return value: True if success, False if not
// --------------------------------------------------------------------------------
Function cmSendTextByEMail(pSubject, pMessage, pEMails, pIsOnServer = False, rErrorMessage, rSMTPConnection = Undefined, pLogoff = Undefined, pAttachmentPath = "", pSMSTemplates = Undefined, pParentDoc = Undefined, pClient = Undefined, pAmountStr = Undefined, pDiscountCard = Undefined) Export
	rErrorMessage = "";
	
	// Get current employee settings
	vCurEmployee = SessionParameters.CurrentUser;
	If Not ValueIsFilled(vCurEmployee) Then
		rErrorMessage = NStr("ru = 'Невозможно отправить E-mail на адрес " + TrimAll(pEMails) + "! Не определен текущий пользователь!'; 
		                     |de = 'Unable to send E-mail to " + TrimAll(pEMails) + "! Current user is not defined!'; 
		                     |en = 'Unable to send E-mail to " + TrimAll(pEMails) + "! Current user is not defined!'");
		WriteLogEvent(NStr("en='InternetMail.SendText';ru='ЭлектроннаяПочта.ОтправитьТекст';de='InternetMail.SendText'"), EventLogLevel.Warning, , , rErrorMessage);
		If pIsOnServer Then
			Raise rErrorMessage;
		EndIf;
		Return False;
	EndIf;
	
	vResult = True;
	Try
		// Addresses and names
		vSenderName = vCurEmployee.GetObject().pmGetEmployeeDescription(SessionParameters.CurrentLanguage);
		vEMailFrom = TrimAll(vCurEmployee.EMail);
		
		// Add reply to address
		vEMailReplyTo = New Array;
		If Not IsBlankString(vCurEmployee.ReplyToEMail) Then
			vEMailsList = cmParseEMailAddress(TrimAll(vCurEmployee.ReplyToEMail));
			For Each vEMailItem In vEMailsList Do
				vEMailReplyTo.Add(TrimAll(vEMailItem.Value));
			EndDo;
		EndIf;   
		
		// Add to address 
		vEMailTo = New Array;
		vEMailsList = cmParseEMailAddress(pEMails);
		For Each vEMailItem In vEMailsList Do
			vEMailTo.Add(TrimAll(vEMailItem.Value));
		EndDo;
		
		// Add Bcc address
		vEMailBcc  = New Array;
		If Not IsBlankString(vCurEmployee.BccEMail) Then
			vEMailsList = cmParseEMailAddress(vCurEmployee.BccEMail);
			For Each vEMailItem In vEMailsList Do
				vEMailBcc.Add(TrimAll(vEMailItem.Value));
			EndDo;
		EndIf;
		
		// Add file as attachement
		vAttachments = New Map;  
		If ValueIsFilled(pAttachmentPath) Then 
			vAttachments.Insert(cmGetFileName(pAttachmentPath), TrimAll(pAttachmentPath));
		EndIf;
		 
		EMail.Send(vCurEmployee, vSenderName, vEMailFrom, TrimAll(pSubject), TrimAll(pMessage), pSMSTemplates, pParentDoc, pClient, pAmountStr, pDiscountCard,, vAttachments, vEMailTo, vEMailReplyTo,, vEMailBcc,,, rSMTPConnection, pLogoff);       
	Except
		rErrorMessage = NStr("ru = 'Невозможно отправить E-Mail на адрес " + TrimAll(pEMails) + "! Описание ошибки: '; 
		                     |de = 'Unable to send E-mail to " + TrimAll(pEMails) + "! Error description: '; 
		                     |en = 'Unable to send E-mail to " + TrimAll(pEMails) + "! Error description: '") + ErrorDescription();
		WriteLogEvent(NStr("en='InternetMail.SendText';ru='ЭлектроннаяПочта.ОтправитьТекст';de='InternetMail.SendText'"), EventLogLevel.Warning, , , rErrorMessage);
		rSMTPConnection = Undefined;
		If pIsOnServer Then
			Raise rErrorMessage;
		EndIf;
		vResult = False;
	EndTry;
	
	// Return result
	If Not vResult Then
		rErrorMessage = StrReplace(rErrorMessage, "{CommonModule.JobsScheduled.Module(281)}: ", "");
		rErrorMessage = StrReplace(rErrorMessage, "{CommonModule.JobsScheduled.Module(283)}: ", "");
		rErrorMessage = StrReplace(rErrorMessage, "{CommonModule.CommonFunctions.Module", "");
	EndIf;
	Return vResult;
EndFunction // cmSendTextByEMail

// --------------------------------------------------------------------------------
// Description: Sends file by e-mail
// Parameters: Message subject, Message text, E-Mails list, File name to attach, 
//             Full file name to attach, Language, Whether fuction is called in 
//             the application server context, Guest group
// Return value: True if success, False if not
// --------------------------------------------------------------------------------
Function cmSendFileByEMail(pSubject, pMessage, pEMails, pFileName, pFullFileName, pLanguage = Undefined, pIsOnServer = False, pGuestGroup = Undefined, pSenderName = "", pSMSTemplates = Undefined, pParentDoc = Undefined, pClient = Undefined, pAmountStr = Undefined, pDiscountCard = Undefined) Export
	vFilesMap = New Map;
	vFilesMap.Insert(pFileName, pFullFileName);
	
	Return cmSendFilesByEMail(pSubject, pMessage, pEMails, vFilesMap, pLanguage, pIsOnServer, pGuestGroup, pSenderName, pSMSTemplates, pParentDoc, pClient, pAmountStr, pDiscountCard);
EndFunction // cmSendFileByEMail

// --------------------------------------------------------------------------------
// Description: Sends file by e-mail
// Parameters: Message subject, Message text, E-Mails list, File name to attach, 
//             Full file name to attach, Language, Whether fuction is called in 
//             the application server context, Guest group
// Return value: True if success, False if not
// --------------------------------------------------------------------------------
Function cmSendFilesByEMail(pSubject, pMessage, pEMails, pAttachments, pLanguage = Undefined, pIsOnServer = False, pGuestGroup = Undefined, pSenderName = "", pSMSTemplates = Undefined, pParentDoc = Undefined, pClient = Undefined, pAmountStr = Undefined, pDiscountCard = Undefined) Export
	vLanguage = pLanguage;
	If Not ValueIsFilled(vLanguage) Then
		vLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	
	// Get current employee settings
	vCurEmployee = SessionParameters.CurrentUser;
	If Not ValueIsFilled(vCurEmployee) Then
		vError = NStr("ru = 'Невозможно отправить файлы по электронной почте на адрес " + TrimAll(pEMails) + "! Не определен текущий пользователь!'; 
		              |de = 'Unable to send files by e-mail to " + TrimAll(pEMails) + "! Current user is not defined!'; 
		              |en = 'Unable to send file by e-mail to " + TrimAll(pEMails) + "! Current user is not defined!'");
		tcCommonFunctionOnClientServer.TextMessage(vError, MessageStatus.Attention);
		WriteLogEvent(NStr("en='InternetMail.SendFile';ru='ЭлектроннаяПочта.ОтправитьФайл';de='InternetMail.SendFile'"), EventLogLevel.Warning, , , vError);
		If pIsOnServer Then
			Raise vError;
		EndIf;
		Return False;
	EndIf;
	
	Try
		// Addresses and names
		vSenderName = pSenderName;
		If Not ValueIsFilled(pSenderName) Then
			vSenderName = vCurEmployee.GetObject().pmGetEmployeeDescription(vLanguage);
		EndIf;
		
		vEMailFrom = TrimAll(vCurEmployee.EMail); 
		
		// Add to addres
		vEMailReplyTo = New Array;
		If Not IsBlankString(vCurEmployee.ReplyToEMail) Then
			vEMailsList = cmParseEMailAddress(TrimAll(vCurEmployee.ReplyToEMail));
			For Each vEMailItem In vEMailsList Do
				vEMailReplyTo.Add(TrimAll(vEMailItem.Value));
			EndDo;
		EndIf; 
		
		// Add to address 
		vEMailTo = New Array;
		vEMailsList = cmParseEMailAddress(pEMails);
		For Each vEMailItem In vEMailsList Do
			vEMailTo.Add(TrimAll(vEMailItem.Value));
		EndDo;   
		
		// Add Bcc address 
		vEMailBcc = New Array;
		If Not IsBlankString(vCurEmployee.BccEMail) Then
			vEMailsList = cmParseEMailAddress(vCurEmployee.BccEMail);
			For Each vEMailItem In vEMailsList Do
				vEMailBcc.Add(TrimAll(vEMailItem.Value));
			EndDo;
		EndIf;
		
		EMail.Send(vCurEmployee, vSenderName, vEMailFrom, TrimAll(pSubject), TrimAll(pMessage), pSMSTemplates, pParentDoc, pClient, pAmountStr, pDiscountCard, , pAttachments, vEMailTo, vEMailReplyTo, , vEMailBcc);
	Except
		vError = NStr("ru = 'Невозможно отправить файлы по электронной почте на адрес " + TrimAll(pEMails) + "! Описание ошибки: '; 
		              |de = 'Unable to send file by e-mail to " + TrimAll(pEMails) + "! Error description: ';
		              |en = 'Unable to send file by e-mail to " + TrimAll(pEMails) + "! Error description: '") + ErrorDescription();
		tcCommonFunctionOnClientServer.TextMessage(vError, MessageStatus.Attention);
		WriteLogEvent(NStr("en='InternetMail.SendFile';ru='ЭлектроннаяПочта.ОтправитьФайл';de='InternetMail.SendFile'"), EventLogLevel.Warning, , , vError);
		If pIsOnServer Then
			Raise vError;
		EndIf;
		Return False;
	EndTry;
	
	// Write trace records to the guest group attachments register
	Try
		If ValueIsFilled(pGuestGroup) Then
			For Each vAttachmentMap In pAttachments Do
				vFullFileName = vAttachmentMap.Value;
				vFileName = vAttachmentMap.Key;
				InformationRegisters.GuestGroupAttachments.WriteData(, pGuestGroup, , pClient, , , , pEMails, pGuestGroup.Client.Fax, Enums.AttachmentTypes.EMail, Enums.AttachmentStatuses.Sent, TrimAll(pMessage), pSMSTemplates, pParentDoc, pDiscountCard, pAmountStr, vFullFileName, vFileName, , TrimAll(pSubject));
			EndDo;
		EndIf;
	Except
		vError = NStr("ru = 'Ошибка регистрации факта отправки сообщения по электронной почте на адрес " + TrimAll(pEMails) + "! Описание ошибки: '; 
		              |de = 'Failed to write guest group attachment for e-mail message to " + TrimAll(pEMails) + "! Error description: ';
		              |en = 'Failed to write guest group attachment for e-mail message to " + TrimAll(pEMails) + "! Error description: '") + 
		         ErrorDescription();
		tcCommonFunctionOnClientServer.TextMessage(vError, MessageStatus.Attention);
		WriteLogEvent(NStr("en='InternetMail.SendFile';ru='ЭлектроннаяПочта.ОтправитьФайл';de='InternetMail.SendFile'"), EventLogLevel.Warning, , , vError);
	EndTry;
	
	// Return success
	Return True;
EndFunction // cmSendFilesByEMail

// --------------------------------------------------------------------------------
// Description: Procedure recalculates totals for accumulation registers 
//              if it is necessary
// Parameters: None
// Return value: None
// --------------------------------------------------------------------------------
Procedure cmRecalculateAccumulationRegistersTotals() Export
	vNotificationStartDay = 5;
	vRecalculateDay = 10;
	
	// Check if it is necessary to recalculate totals
	vRecalculationIsNecessary = True;
	vCurrentDayOfMonth = Day(CurrentSessionDate());	
	If vCurrentDayOfMonth < vNotificationStartDay Then
		vRecalculationIsNecessary = False;
	Else
		If vCurrentDayOfMonth < vRecalculateDay Then
			vThereAreActiveUsers = False;
			Try
				SetExclusiveMode(True);
			Except
				vThereAreActiveUsers = True;
			EndTry;
			If Not vThereAreActiveUsers Then
				SetExclusiveMode(False);
			EndIf;
			vRecalculationIsNecessary = Not vThereAreActiveUsers;
		Else
			vRecalculationIsNecessary = True;
		EndIf;
	EndIf;
	If Not vRecalculationIsNecessary Then
		Return;
	EndIf;
	
	// Build list of registers to recalculate
	vRecalculationDate = BegOfMonth(CurrentSessionDate()) - 1;
	vRegistersList = New ValueList();
	For Each vRegister In AccumulationRegisters Do
		vRegisterMetadata = Metadata.FindByType(TypeOf(vRegister));
		If vRegisterMetadata.RegisterType = Metadata.ObjectProperties.AccumulationRegisterType.Balance Then
			If vRegister.GetTotalsPeriod() < vRecalculationDate Then
				If AccessRight("TotalsControl", vRegisterMetadata) Then
					vRegistersList.Add(vRegister, NStr("en='Accumulation register ';ru='Регистр накопления ';de='Akkumulationsregister '") + vRegisterMetadata.Presentation());
				EndIf;
			EndIf;			
		EndIf;
	EndDo;	
	If vRegistersList.Count() = 0 Then
		Return;
	EndIf;

	// Recalculate registers
	For Each vRegisterItem In vRegistersList Do
		vRegister = vRegisterItem.Value;
		vRegister.SetMaxTotalsPeriod(vRecalculationDate);
		
		// Add record to the system log
		vRegisterMetadata = Metadata.FindByType(TypeOf(vRegister));
		vMessage = NStr("ru = 'Итоги регистра накопления " + vRegisterMetadata.Presentation() + " были рассчитаны по " + Format(vRecalculationDate, "DF=dd.MM.yyyy") + "'; 
		                |de = '" + vRegisterMetadata.Presentation() + " accumulation register totals were recalculated to " + Format(vRecalculationDate, "DF=dd.MM.yyyy") + "'; 
		                |en = '" + vRegisterMetadata.Presentation() + " accumulation register totals were recalculated to " + Format(vRecalculationDate, "DF=dd.MM.yyyy") + "'");
		WriteLogEvent(NStr("en='AccumulationRegisters.TotalsRecalculation';ru='РегистрыНакопления.ПересчетИтогов';de='AccumulationRegisters.TotalsRecalculation'"), EventLogLevel.Information, vRegisterMetadata, , vMessage);
	EndDo;
EndProcedure // cmRecalculateAccumulationRegistersTotals

// --------------------------------------------------------------------------------
Procedure cmCheckSMSStatuses(pKey = "") Export
	vMessage = "";
	SMS.CheckSMSStatuses(vMessage);
	If Not IsBlankString(vMessage) Then
		Raise vMessage;
	EndIf;
EndProcedure // cmCheckSMSStatuses 

// --------------------------------------------------------------------------------
Procedure cmSendDefferedSMS() Export
	SMS.SendDefferedSMS();
EndProcedure // cmSendDefferedSMS

// --------------------------------------------------------------------------------
Procedure cmSMSAutoDelivery(pHotel, pSender, pDeliveryTemplate, pMessageTemplate, pDeliveryType, pDeliveryFilter, pNumberOfDays = 0, pImportantDateType = Undefined) Export
	SMS.AutoDelivery(pHotel, pSender, pDeliveryTemplate, pMessageTemplate, pDeliveryType, pDeliveryFilter, pNumberOfDays, pImportantDateType);
EndProcedure // cmSMSAutoDelivery

// --------------------------------------------------------------------------------
Procedure cmExchangePlanDataProcessing() Export	
	vKey = "cmExchangePlanDataProcessing_ReadingAndWritingToRegister"; 
	If Not CheckingRunningBackgroundJob(vKey) Then
		vBJ = BackgroundJobs.Execute("ExchangePlansProcessing.ReadingAndWritingToRegister", New Array(), vKey, NStr("en = 'Reading and writing to the exchange plan data register'; de = 'Lesen und Schreiben in das Austauschplandatenregister'; ru = 'Чтение и запись в регистр данных плана обмена'")); 
	EndIf;	
		
	vKey = "cmExchangePlanDataProcessing_ReceivingAndSendingMessageChanges";	
	If Not CheckingRunningBackgroundJob(vKey) Then 
		vBJ = BackgroundJobs.Execute("ExchangePlansProcessing.ReceivingAndSendingMessageChanges", New Array(), vKey, NStr("en = 'Receiving And Sending Message Changes'; de = 'Nachrichtenänderungen empfangen und senden'; ru = 'Получение и отправка сообщений об изменениях'"));	
	EndIf;
EndProcedure // ExchangePlanDataProcessing

// --------------------------------------------------------------------------------
Function CheckingRunningBackgroundJob(pKey)
	Return BackgroundJobs.GetBackgroundJobs(New Structure("Key, State", pKey, BackgroundJobState.Active)).Count() > 0;
EndFunction // CheckingRunningBackgroundJob

// --------------------------------------------------------------------------------
Procedure cmExecuteIntegrationServiceProcessing() Export 
	IntegrationServices.ExecuteProcessing();	
EndProcedure // cmExecuteIntegrationServiceProcessing

// --------------------------------------------------------------------------------
Procedure cmFillRoomRatePricesCache(pHotel, pRoomRatesList, pPeriodFrom, pPeriodTo, pRoomTypesList = Undefined) Export
	If pRoomTypesList = Undefined Then
		vRoomTypesList = New ValueList();
		vRoomTypesList.Add(Catalogs.RoomTypes.EmptyRef());
	Else
		vRoomTypesList = pRoomTypesList;
	EndIf;
	vDPObj = DataProcessors.FillRoomRateDailyPrices.Create();
	vDPObj.Hotel = pHotel;
	vDPObj.PeriodFrom = pPeriodFrom;
	vDPObj.PeriodTo = pPeriodTo;
	For Each vRoomRatesListItem In pRoomRatesList Do
		vDPObj.RoomRate = vRoomRatesListItem.Value;
		For Each vRoomTypesListItem In vRoomTypesList Do
			vDPObj.RoomType = vRoomTypesListItem.Value;
			vDPObj.pmDoFill();
		EndDo;
	EndDo;
EndProcedure // cmFillRoomRatePricesCache

// --------------------------------------------------------------------------------
Procedure cmRunChatBot() Export
	While True Do
		vQ = New Query;
		vQ.Text = 
		"SELECT
		|	ChatBots.Ref AS Ref,
		|	ChatBots.BotType AS BotType
		|FROM
		|	Catalog.ChatBots AS ChatBots
		|WHERE
		|	NOT ChatBots.DeletionMark
		|	AND ChatBots.IsActive";
		vBotList = vQ.Execute().Select();
		While vBotList.Next() Do
			vAPI = cmGetChatBotAPI(vBotList.BotType);
			vAPI.getUpdates(vBotList.Ref);
			cmWait(2);
		EndDo;
		
		Catalogs.ChatBots.SendNotification();
	EndDo;
EndProcedure // RunChatBot

// --------------------------------------------------------------------------------
Procedure WaitForBackgroundJobToFinish(pSec, pKey, pName) Export
	Try
		vJob = BackgroundJobs.GetBackgroundJobs(New Structure("Description, Key", pName, pKey))[0];
   		vJob.WaitForExecutionCompletion(pSec);
	Except
	EndTry;
EndProcedure // WaitForBackgroundJobToFinish

// --------------------------------------------------------------------------------
Procedure cmProcessClientPersonalDataProcessingRefusals() Export
	vError = "";
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PersonalDataProcessingRefusal.Ref,
	|	PersonalDataProcessingRefusal.Client,
	|	PersonalDataProcessingRefusal.ClearNames,
	|	PersonalDataProcessingRefusal.ClearPassport,
	|	PersonalDataProcessingRefusal.ClearAddresses,
	|	PersonalDataProcessingRefusal.ClearContacts
	|FROM
	|	Document.PersonalDataProcessingRefusal AS PersonalDataProcessingRefusal
	|WHERE
	|	NOT PersonalDataProcessingRefusal.DeletionMark
	|	AND NOT PersonalDataProcessingRefusal.IsProcessed
	|	AND PersonalDataProcessingRefusal.Date <= &qCurrentDate
	|
	|ORDER BY
	|	PersonalDataProcessingRefusal.PointInTime";
	vQry.SetParameter("qCurrentDate", CurrentSessionDate());
	vDocs = vQry.Execute().Unload();
	If vDocs.Count() > 0 Then
		SetPrivilegedMode(True);
		For Each vDocsRow In vDocs Do
			vDocRef = vDocsRow.Ref;
			vClient = vDocsRow.Client;
			If ValueIsFilled(vClient) Then
				Try
					vDocObj = vDocRef.GetObject();
					vClientObj = vClient.GetObject();
					vDoClientUpdate = False;
					If vDocsRow.ClearNames Then
						vDoClientUpdate = True;
						vClientObj.LastName = TrimAll(vClientObj.Code);
						vClientObj.DateOfBirth = '00010101';
						vClientObj.Photo = Undefined;
						vClientObj.Signature = Undefined;
					EndIf;
					If vDocsRow.ClearPassport Then
						vDoClientUpdate = True;
						vClientObj.IdentityDocumentSeries = "";
						vClientObj.IdentityDocumentNumber = "";
						vClientObj.IdentityDocumentIssueDate = '00010101';
						vClientObj.IdentityDocumentValidToDate = '00010101';
						vClientObj.IdentityDocumentUnitCode = "";
						vClientObj.IdentityDocumentIssuedBy = "";
						vClientObj.Photo = Undefined;
						vClientObj.Signature = Undefined;
					EndIf;
					If vDocsRow.ClearAddresses Then
						vDoClientUpdate = True;
						vClientObj.PlaceOfBirth = "";
						vClientObj.Address = "";
						vClientObj.AddressRegistrationDate = '00010101';
					EndIf;
					If vDocsRow.ClearContacts Then
						vDoClientUpdate = True;
						vClientObj.Phone = "";
						vClientObj.Fax = "";
						vClientObj.EMail = "";
						vClientObj.EMailAdditional = "";
					EndIf;
					BeginTransaction(DataLockControlMode.Managed);
					If vDoClientUpdate Then
						vClientObj.Write();
						vClientObj.pmWriteToClientChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
					EndIf;
					vDocObj.IsProcessed = True;
					vDocObj.ProcessingDate = CurrentSessionDate();
					vDocObj.Write(DocumentWriteMode.Write);
					CommitTransaction();
				Except
					vError = ErrorDescription();
					If TransactionActive() Then
						RollbackTransaction();
					EndIf;
				EndTry;
			EndIf;
		EndDo;
		SetPrivilegedMode(False);
		If Not IsBlankString(vError) Then
			Raise vError;
		EndIf;
	EndIf;
EndProcedure // cmProcessClientPersonalDataProcessingRefusals

// --------------------------------------------------------------------------------
Procedure SyncBitrix24() Export
	vQ = New Query("SELECT
	               |	ExternalSystemInteractions.Ref AS Ref
	               |FROM
	               |	Catalog.ExternalSystemInteractions AS ExternalSystemInteractions
	               |WHERE
	               |	NOT ExternalSystemInteractions.DeletionMark
	               |	AND ExternalSystemInteractions.IsActive
	               |	AND ExternalSystemInteractions.IntegrationType = &qIntegrationType");
	vQ.SetParameter("qIntegrationType", Enums.Integrations.Bitrix24);
	qRes = vQ.Execute().Select();
	While qRes.Next() Do
		Bitrix24.SynchDataWithBitrix24(qRes.Ref);
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------
Procedure cmRefreshRoomRateDailyPrices() Export
	vCurrentUniversalDate = CurrentUniversalDate();
	vInfobaseTimeZone = Constants.InfoBaseTimeZone.Get();
	
	// Fill table with current session dates for each hotel in the system
	vCurrentSessionDates = New ValueTable();
	vCurrentSessionDates.Columns.Add("Hotel", cmGetCatalogTypeDescription("Hotels"));
	vCurrentSessionDates.Columns.Add("CurrentSessionDate", cmGetDateTimeTypeDescription());
	vAllHotels = cmGetAllHotels();
	For Each vAllHotelsRow In vAllHotels Do
		vCurrentSessionDatesRow = vCurrentSessionDates.Add();
		vCurrentSessionDatesRow.Hotel = vAllHotelsRow.Hotel;
		vCurrentSessionDatesRow.CurrentSessionDate = ToLocalTime(vCurrentUniversalDate, ?(ValueIsFilled(vAllHotelsRow.Hotel.HotelTimeZone), TrimAll(vAllHotelsRow.Hotel.HotelTimeZone), ?(ValueIsFilled(vInfobaseTimeZone), TrimAll(vInfobaseTimeZone), Undefined)));
	EndDo;

	// Jobs to run for each hotel
	vJobsToRun = New ValueTable();
	vJobsToRun.Columns.Add("Hotel", cmGetCatalogTypeDescription("Hotels"));
	vJobsToRun.Columns.Add("RoomRatesList");
	vJobsToRun.Columns.Add("DateFrom", cmGetDateTypeDescription());
	vJobsToRun.Columns.Add("DateTo", cmGetDateTypeDescription());
	
	// Get set room rate prices future documents to process
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CurrentSessionDates.Hotel AS Hotel,
	|	CurrentSessionDates.CurrentSessionDate AS CurrentSessionDate
	|INTO CurrentSessionDates
	|FROM
	|	&qCurrentSessionDates AS CurrentSessionDates
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetRoomRatePrices.Hotel AS Hotel,
	|	SetRoomRatePrices.Hotel.Code AS HotelCode,
	|	SetRoomRatePrices.Ref AS DocumentRef,
	|	SetRoomRatePrices.PointInTime AS DocumentPointInTime
	|FROM
	|	Document.SetRoomRatePrices AS SetRoomRatePrices
	|		INNER JOIN CurrentSessionDates AS CurrentSessionDates
	|		ON SetRoomRatePrices.Hotel = CurrentSessionDates.Hotel
	|			AND SetRoomRatePrices.Date <= CurrentSessionDates.CurrentSessionDate
	|WHERE
	|	SetRoomRatePrices.IsInFuture
	|	AND SetRoomRatePrices.Posted
	|	AND SetRoomRatePrices.Hotel.UseRoomRateDailyPrices
	|
	|UNION ALL
	|
	|SELECT
	|	SetPriceTagRanges.Hotel,
	|	SetPriceTagRanges.Hotel.Code,
	|	SetPriceTagRanges.Ref,
	|	SetPriceTagRanges.PointInTime
	|FROM
	|	Document.SetPriceTagRanges AS SetPriceTagRanges
	|		INNER JOIN CurrentSessionDates AS CurrentSessionDates
	|		ON SetPriceTagRanges.Hotel = CurrentSessionDates.Hotel
	|			AND SetPriceTagRanges.Date <= CurrentSessionDates.CurrentSessionDate
	|WHERE
	|	SetPriceTagRanges.IsInFuture
	|	AND SetPriceTagRanges.Posted
	|	AND SetPriceTagRanges.Hotel.UseRoomRateDailyPrices
	|
	|ORDER BY
	|	HotelCode,
	|	DocumentPointInTime";
	vQry.SetParameter("qCurrentSessionDates", vCurrentSessionDates);
	vDataToProcess = vQry.Execute().Unload();
	
	// Fill jobs to run table
	For Each vDataToProcessRow In vDataToProcess Do
		vJobsToRunRow = vJobsToRun.Find(vDataToProcessRow.Hotel, "Hotel");
		If vJobsToRunRow = Undefined Then
			vJobsToRunRow = vJobsToRun.Add();
			vJobsToRunRow.Hotel = vDataToProcessRow.Hotel;
			vJobsToRunRow.RoomRatesList = New ValueList();
		EndIf;
		
		vDocObj = vDataToProcessRow.DocumentRef.GetObject();

		vRates = vDocObj.pmGetListOfActiveRoomRates();
		vRatesList = New ValueList();
		vRatesList.LoadValues(vRates.UnloadColumn("RoomRate"));
		
		vDayTypes = vDocObj.pmGetListOfActiveCalendarDayTypes();
	
		vDateFrom = '39991231';
		vDateTo = '00010101';
		
		cmGetCacheEffectivePeriod(vRatesList, vDayTypes, vDateFrom, vDateTo);
		
		If vDateFrom <= vDateTo Then
			For Each vRatesListItem In vRatesList Do
				// Add room rate to the list of rates to process
				If vJobsToRunRow.RoomRatesList.FindByValue(vRatesListItem.Value) = Undefined Then
					vJobsToRunRow.RoomRatesList.Add(vRatesListItem.Value);
				EndIf;
				
				If Not ValueIsFilled(vJobsToRunRow.DateFrom) Then
					vJobsToRunRow.DateFrom = vDateFrom;
				ElsIf vJobsToRunRow.DateFrom > vDateFrom Then
					vJobsToRunRow.DateFrom = vDateFrom;
				EndIf;
				If Not ValueIsFilled(vJobsToRunRow.DateTo) Then
					vJobsToRunRow.DateTo = vDateTo;
				ElsIf vJobsToRunRow.DateTo < vDateFrom Then
					vJobsToRunRow.DateTo = vDateTo;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	// Run fill room rate daily prices for each hotel
	For Each vJobsToRunRow In vJobsToRun Do
		cmFillRoomRatePricesCache(vJobsToRunRow.Hotel, vJobsToRunRow.RoomRatesList, vJobsToRunRow.DateFrom, vJobsToRunRow.DateTo);
	EndDo;
	
	// Reset future flag in documents
	For Each vDataToProcessRow In vDataToProcess Do
		vDocObj = vDataToProcessRow.DocumentRef.GetObject();
		If vDocObj.IsInFuture Then
			vDocObj.AdditionalProperties.Insert("SystemUpdateMode", True);
			vDocObj.IsInFuture = False;
			vDocObj.Write(DocumentWriteMode.Write);
			If TypeOf(vDocObj) = Type("DocumentObject.SetRoomRatePrices") Then
				vDocObj.pmWriteToSetRoomRatePricesChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			ElsIf TypeOf(vDocObj) = Type("DocumentObject.SetPriceTagRanges") Then
				vDocObj.pmWriteToSetPriceTagRangesChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			EndIf;
		EndIf;
	EndDo;	
EndProcedure // cmRefreshRoomRateDailyPrices

#EndRegion
