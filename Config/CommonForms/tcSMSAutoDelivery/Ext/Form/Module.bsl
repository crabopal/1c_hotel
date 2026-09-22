
// -------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	LoadFormAppearanceAtServer();
	SetFormAppearance();
EndProcedure

// -------------------------------------------------------------------------
&AtServer
Procedure LoadFormAppearanceAtServer()
	Hotel = SessionParameters.CurrentHotel;
	Employee = SessionParameters.CurrentUser;
	// Read SMS auto delivery settings
	vSettings = Constants.SMSAutoDeliverySettings.Get().Get();
	vDeliveryFiltersAreDefined = False;
	If vSettings <> Undefined And TypeOf(vSettings) = Type("ValueTable") Then
		vFilterCol = vSettings.Columns.Find("DeliveryFilter");
		vFilterNumberOfDays = vSettings.Columns.Find("NumberOfDays") <> Undefined;
		vFilterImportantDateType = vSettings.Columns.Find("ImportantDateType") <> Undefined;

		If vFilterCol <> Undefined Then
			vDeliveryFiltersAreDefined = True;
		EndIf;
		vRows = vSettings.FindRows(New Structure("Hotel, DeliveryTemplate", Hotel, Enums.AutoDeliveryTemplates.CheckedInGuestsNotification));
		If vRows <> Undefined And vRows.Count() > 0 Then
			vSettingsRow = vRows.Get(0);
			CheckedInGuestsNotification = vSettingsRow.Flag;
			CheckedInGuestsNotificationDeliveryType = vSettingsRow.DeliveryType;
			CheckedInGuestsNotificationMessageTemplate = vSettingsRow.MessageTemplate;
			If vDeliveryFiltersAreDefined Then
				CheckedInGuestsNotificationDeliveryFilter = TrimAll(vSettingsRow.DeliveryFilter);
			Else
				CheckedInGuestsNotificationDeliveryFilter = "";
			EndIf;
		EndIf;
		
		vRows = vSettings.FindRows(New Structure("Hotel, DeliveryTemplate", Hotel, Enums.AutoDeliveryTemplates.CheckedOutGuestsNotification));
		If vRows <> Undefined And vRows.Count() > 0 Then
			vSettingsRow = vRows.Get(0);
			CheckedOutGuestsNotification = vSettingsRow.Flag;
			CheckedOutGuestsNotificationDeliveryType = vSettingsRow.DeliveryType;
			CheckedOutGuestsNotificationMessageTemplate = vSettingsRow.MessageTemplate;
			If vDeliveryFiltersAreDefined Then
				CheckedOutGuestsNotificationDeliveryFilter = TrimAll(vSettingsRow.DeliveryFilter);
			Else
				CheckedOutGuestsNotificationDeliveryFilter = "";
			EndIf;
		EndIf;
	
		vRows = vSettings.FindRows(New Structure("Hotel, DeliveryTemplate", Hotel, Enums.AutoDeliveryTemplates.ExpectedCheckInGuestsNotification));
		If vRows <> Undefined And vRows.Count() > 0 Then
			vSettingsRow = vRows.Get(0);
			ExpectedCheckInGuestsNotification = vSettingsRow.Flag;
			ExpectedCheckInGuestsNotificationDeliveryType = vSettingsRow.DeliveryType;
			ExpectedCheckInGuestsNotificationMessageTemplate = vSettingsRow.MessageTemplate;
			If vDeliveryFiltersAreDefined Then
				ExpectedCheckInGuestsNotificationDeliveryFilter = TrimAll(vSettingsRow.DeliveryFilter);
			Else
				ExpectedCheckInGuestsNotificationDeliveryFilter = "";
			EndIf;
		EndIf;
	
		vRows = vSettings.FindRows(New Structure("Hotel, DeliveryTemplate", Hotel, Enums.AutoDeliveryTemplates.ExpectedCheckOutGuestsFolioBalanceNotification));
		If vRows <> Undefined And vRows.Count() > 0 Then
			vSettingsRow = vRows.Get(0);
			ExpectedCheckOutGuestsFolioBalanceNotification = vSettingsRow.Flag;
			ExpectedCheckOutGuestsFolioBalanceNotificationDeliveryType = vSettingsRow.DeliveryType;
			ExpectedCheckOutGuestsFolioBalanceNotificationMessageTemplate = vSettingsRow.MessageTemplate;
			If vDeliveryFiltersAreDefined Then
				ExpectedCheckOutGuestsFolioBalanceNotificationDeliveryFilter = TrimAll(vSettingsRow.DeliveryFilter);
			Else
				ExpectedCheckOutGuestsFolioBalanceNotificationDeliveryFilter = "";
			EndIf;
		EndIf;
	
		vRows = vSettings.FindRows(New Structure("Hotel, DeliveryTemplate", Hotel, Enums.AutoDeliveryTemplates.ExpectedCheckOutGuestsNotification));
		If vRows <> Undefined And vRows.Count() > 0 Then
			vSettingsRow = vRows.Get(0);
			ExpectedCheckOutGuestsNotification = vSettingsRow.Flag;
			ExpectedCheckOutGuestsNotificationDeliveryType = vSettingsRow.DeliveryType;
			ExpectedCheckOutGuestsNotificationMessageTemplate = vSettingsRow.MessageTemplate;
			If vDeliveryFiltersAreDefined Then
				ExpectedCheckOutGuestsNotificationDeliveryFilter = TrimAll(vSettingsRow.DeliveryFilter);
			Else
				ExpectedCheckOutGuestsNotificationDeliveryFilter = "";
			EndIf;
		EndIf;
	
		vRows = vSettings.FindRows(New Structure("Hotel, DeliveryTemplate", Hotel, Enums.AutoDeliveryTemplates.ExpiredInvoicesNotification));
		If vRows <> Undefined And vRows.Count() > 0 Then
			vSettingsRow = vRows.Get(0);
			ExpiredInvoicesNotification = vSettingsRow.Flag;
			ExpiredInvoicesNotificationDeliveryType = vSettingsRow.DeliveryType;
			ExpiredInvoicesNotificationMessageTemplate = vSettingsRow.MessageTemplate;
			If vDeliveryFiltersAreDefined Then
				ExpiredInvoicesNotificationDeliveryFilter = TrimAll(vSettingsRow.DeliveryFilter);
			Else
				ExpiredInvoicesNotificationDeliveryFilter = "";
			EndIf;
		EndIf;
	
		vRows = vSettings.FindRows(New Structure("Hotel, DeliveryTemplate", Hotel, Enums.AutoDeliveryTemplates.InHouseGuestsBirthdayCongratulation));
		If vRows <> Undefined And vRows.Count() > 0 Then
			vSettingsRow = vRows.Get(0);
			InHouseGuestsBirthdayCongratulation = vSettingsRow.Flag;
			InHouseGuestsBirthdayCongratulationDeliveryType = vSettingsRow.DeliveryType;
			InHouseGuestsBirthdayCongratulationMessageTemplate = vSettingsRow.MessageTemplate;
			If vDeliveryFiltersAreDefined Then
				InHouseGuestsBirthdayCongratulationDeliveryFilter = TrimAll(vSettingsRow.DeliveryFilter);
			Else
				InHouseGuestsBirthdayCongratulationDeliveryFilter = "";
			EndIf;
		EndIf;
	
		vRows = vSettings.FindRows(New Structure("Hotel, DeliveryTemplate", Hotel, Enums.AutoDeliveryTemplates.InHouseGuestsFolioBalanceNotification));
		If vRows <> Undefined And vRows.Count() > 0 Then
			vSettingsRow = vRows.Get(0);
			InHouseGuestsFolioBalanceNotification = vSettingsRow.Flag;
			InHouseGuestsFolioBalanceNotificationDeliveryType = vSettingsRow.DeliveryType;
			InHouseGuestsFolioBalanceNotificationMessageTemplate = vSettingsRow.MessageTemplate;
			If vDeliveryFiltersAreDefined Then
				InHouseGuestsFolioBalanceNotificationDeliveryFilter = TrimAll(vSettingsRow.DeliveryFilter);
			Else
				InHouseGuestsFolioBalanceNotificationDeliveryFilter = "";
			EndIf;
		EndIf;
	
		vRows = vSettings.FindRows(New Structure("Hotel, DeliveryTemplate", Hotel, Enums.AutoDeliveryTemplates.InHouseGuestsNotification));
		If vRows <> Undefined And vRows.Count() > 0 Then
			vSettingsRow = vRows.Get(0);
			InHouseGuestsNotification = vSettingsRow.Flag;
			InHouseGuestsNotificationDeliveryType = vSettingsRow.DeliveryType;
			InHouseGuestsNotificationMessageTemplate = vSettingsRow.MessageTemplate;
			If vDeliveryFiltersAreDefined Then
				InHouseGuestsNotificationDeliveryFilter = TrimAll(vSettingsRow.DeliveryFilter);
			Else
				InHouseGuestsNotificationDeliveryFilter = "";
			EndIf;
		EndIf;
		
		vRows = vSettings.FindRows(New Structure("Hotel, DeliveryTemplate", Hotel, Enums.AutoDeliveryTemplates.AfterCheckOutGuestsNotification));
		If vRows <> Undefined And vRows.Count() > 0 Then
			vSettingsRow = vRows.Get(0);
			AfterCheckOutGuestsNotification = vSettingsRow.Flag;
			AfterCheckOutGuestsNotificationDeliveryType = vSettingsRow.DeliveryType;
			AfterCheckOutGuestsNotificationMessageTemplate = vSettingsRow.MessageTemplate;
			If vDeliveryFiltersAreDefined Then
				AfterCheckOutGuestsNotificationDeliveryFilter = TrimAll(vSettingsRow.DeliveryFilter);
			Else
				AfterCheckOutGuestsNotificationDeliveryFilter = "";
			EndIf;
			If vFilterNumberOfDays Then
				AfterCheckOutGuestsNotificationNumberOfDays = vSettingsRow.NumberOfDays;	
			Else
				AfterCheckOutGuestsNotificationNumberOfDays = 0;	
			EndIf;
		EndIf;
		
		vRows = vSettings.FindRows(New Structure("Hotel, DeliveryTemplate", Hotel, Enums.AutoDeliveryTemplates.BeforeCheckInGuestsNotification));
		If vRows <> Undefined And vRows.Count() > 0 Then
			vSettingsRow = vRows.Get(0);
			BeforeCheckInGuestsNotification = vSettingsRow.Flag;
			BeforeCheckInGuestsNotificationDeliveryType = vSettingsRow.DeliveryType;
			BeforeCheckInGuestsNotificationMessageTemplate = vSettingsRow.MessageTemplate;
			If vDeliveryFiltersAreDefined Then
				BeforeCheckInGuestsNotificationDeliveryFilter = TrimAll(vSettingsRow.DeliveryFilter);
			Else
				BeforeCheckInGuestsNotificationDeliveryFilter = "";
			EndIf;
			If vFilterNumberOfDays Then
				BeforeCheckInGuestsNotificationNumberOfDays = vSettingsRow.NumberOfDays;	
			Else
				BeforeCheckInGuestsNotificationNumberOfDays = 0;	
			EndIf;
		EndIf;
			
		vRows = vSettings.FindRows(New Structure("Hotel, DeliveryTemplate", Hotel, Enums.AutoDeliveryTemplates.AllClientsBirthdayCongratulation));
		If vRows <> Undefined And vRows.Count() > 0 Then
			vSettingsRow = vRows.Get(0);
			AllClientsBirthdayCongratulation = vSettingsRow.Flag;
			AllClientsBirthdayCongratulationDeliveryType = vSettingsRow.DeliveryType;
			AllClientsBirthdayCongratulationMessageTemplate = vSettingsRow.MessageTemplate;
			If vDeliveryFiltersAreDefined Then
				AllClientsBirthdayCongratulationDeliveryFilter = TrimAll(vSettingsRow.DeliveryFilter);
			Else
				AllClientsBirthdayCongratulationDeliveryFilter = "";
			EndIf;
		EndIf; 
		
		vRows = vSettings.FindRows(New Structure("Hotel, DeliveryTemplate", Hotel, Enums.AutoDeliveryTemplates.AllClientsImportantDatesCongratulation));
		If vRows <> Undefined And vRows.Count() > 0 Then
			vSettingsRow = vRows.Get(0);
			AllClientsImportantDateCongratulation1 = vSettingsRow.Flag;
			AllClientsImportantDateCongratulationDeliveryType1 = vSettingsRow.DeliveryType;
			If vDeliveryFiltersAreDefined Then
				AllClientsImportantDateCongratulationDeliveryFilter1 = TrimAll(vSettingsRow.DeliveryFilter);
			Else
				AllClientsImportantDateCongratulationDeliveryFilter1 = "";
			EndIf;
			If vFilterImportantDateType Then
				AllClientsImportantDateCongratulationImportantDateType1 = vSettingsRow.ImportantDateType;	
			Else
				AllClientsImportantDateCongratulationImportantDateType1 = Undefined; 	
			EndIf;
		EndIf;
	EndIf;
EndProcedure // LoadFormAppearanceAtServer

// -------------------------------------------------------------------------
&AtServer
Function InitializeSettingsTable()
	vSettings = New ValueTable();
	vSettings.Columns.Add("Flag", cmGetBooleanTypeDescription());
	vSettings.Columns.Add("Hotel", cmGetCatalogTypeDescription("Hotels"));
	vSettings.Columns.Add("User", cmGetCatalogTypeDescription("Employees"));
	vSettings.Columns.Add("DeliveryTemplate");
	vSettings.Columns.Add("DeliveryType");
	vSettings.Columns.Add("MessageTemplate", cmGetCatalogTypeDescription("SMSTemplates"));
	vSettings.Columns.Add("DeliveryFilter", cmGetStringTypeDescription()); 
	vSettings.Columns.Add("NumberOfDays", cmGetNumberTypeDescription(3, 0));
	vSettings.Columns.Add("ImportantDateType", cmGetCatalogTypeDescription("ImportantDateTypes"));
	vSettings.Columns.Add("Sender", cmGetStringTypeDescription());
	vSettings.Columns.Add("Description", cmGetStringTypeDescription());
	vSettings.Columns.Add("JobUUID", cmGetStringTypeDescription());
	Return vSettings;
EndFunction // InitializeSettingsTable

// -------------------------------------------------------------------------
&AtServer
Function SetBackgroundJob(pFlag, pDeliveryTemplate, pDeliveryType, pDeliveryFilter, pMessageTemplate, pJobDescription, pNumberOfDays = 0, pImportantDateType = Undefined)
	// Check that hotel is choosen
	If Not ValueIsFilled(Hotel) Then
		pFlag = Not pFlag;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Choose hotel first!';ru='Не указана гостиница!';de='Das Hotel ist nicht angegeben!'"));
		Return False;
	EndIf;
	// Check that employee is choosen
	If Not ValueIsFilled(Employee) Then
		pFlag = Not pFlag;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Choose user name to send messages at!';ru='Не указан пользователь от имени которого должны выполняться рассылки!';de='Der Nutzer, in dessen Namen der Verteiler verschickt werden soll, ist nicht angegeben!'"));
		Return False;
	EndIf;
	// Check that delivery type is choosen
	If Not ValueIsFilled(pDeliveryType) Then
		pFlag = Not pFlag;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Choose messages delivery type (SMS or E-Mail)!';ru='Не указан способ рассылки уведомлений (SMS или E-Mail)!';de='Es ist nicht angegeben, wie die Mitteilungen versendet werden sollen (E-Mail oder SMS)!'"));
		Return False;
	EndIf;                                  
	If pImportantDateType = Undefined Then
		// Check that message template is choosen
		If Not ValueIsFilled(pMessageTemplate) Then
			pFlag = Not pFlag;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Choose messages template!';ru='Не указан шаблон сообщений!';de='Das Mitteilungsmuster ist nicht angegeben!'"));
			Return False;
		EndIf; 
	Else
		If Not ValueIsFilled(pImportantDateType) Then
			pFlag = Not pFlag;
			Return NStr("en='Choose important date type!';ru='Не указан тип важной даты!';de='Wählen Sie einen wichtigen Datumstyp!'");	
		EndIf;	
	EndIf;
	// Read SMS auto delivery settings
	vSettings = Constants.SMSAutoDeliverySettings.Get().Get();
	If vSettings = Undefined Then
		vSettings = InitializeSettingsTable();
	Else
		If vSettings.Columns.Find("DeliveryFilter") = Undefined Then
			vSettings.Columns.Add("DeliveryFilter", cmGetStringTypeDescription());
		EndIf;
		If vSettings.Columns.Find("NumberOfDays") = Undefined Then
			vSettings.Columns.Add("NumberOfDays", cmGetNumberTypeDescription(3, 0));
		EndIf;    
		If vSettings.Columns.Find("ImportantDateType") = Undefined Then
			vSettings.Columns.Add("ImportantDateType", cmGetCatalogTypeDescription("ImportantDateTypes"));
		EndIf;
	EndIf;
	// Try to find settings row for the current user choice
	vRows = vSettings.FindRows(New Structure("Hotel, DeliveryTemplate", Hotel, pDeliveryTemplate));
	If vRows <> Undefined And vRows.Count() > 0 Then
		vSettingsRow = vRows.Get(0);
	Else
		vSettingsRow = vSettings.Add();
		vSettingsRow.Hotel = Hotel;
		vSettingsRow.DeliveryTemplate = pDeliveryTemplate;
	EndIf;
	vSettingsRow.User = Employee;
	If pFlag Then
		// Update settings row
		vSettingsRow.DeliveryType = pDeliveryType;
		vSettingsRow.MessageTemplate = pMessageTemplate;
		vSettingsRow.DeliveryFilter = TrimR(pDeliveryFilter);
		vSettingsRow.NumberOfDays = pNumberOfDays;
		vSettingsRow.ImportantDateType = pImportantDateType;
		vSettingsRow.Sender = "";
		vSettingsRow.Description = TrimAll(Hotel) + " - " + TrimAll(pJobDescription);
		// Call API
		If IsBlankString(vSettingsRow.JobUUID) Then
			vSettingsRow.JobUUID = JobsScheduled.cmCreateSMSAutoDeliveryJob(vSettingsRow.Hotel, vSettingsRow.User, vSettingsRow.DeliveryTemplate, vSettingsRow.DeliveryType, vSettingsRow.DeliveryFilter, vSettingsRow.MessageTemplate, vSettingsRow.Sender, vSettingsRow.Description, vSettingsRow.NumberOfDays, False, vSettingsRow.ImportantDateType);
		Else
			JobsScheduled.cmUpdateSMSAutoDeliveryJob(vSettingsRow.JobUUID, vSettingsRow.Hotel, vSettingsRow.User, vSettingsRow.DeliveryTemplate, vSettingsRow.DeliveryType, vSettingsRow.DeliveryFilter, vSettingsRow.MessageTemplate, vSettingsRow.Sender, vSettingsRow.Description, vSettingsRow.NumberOfDays, False, vSettingsRow.ImportantDateType);
		EndIf;
	Else
		If Not IsBlankString(vSettingsRow.JobUUID) Then
			vJob = JobsScheduled.cmGetSMSAutoDeliveryJob(vSettingsRow.JobUUID);
			If vJob <> Undefined Then
				vJob.Use = False;
				vJob.Write();
			Else
				vSettingsRow.JobUUID = "";
			EndIf;
		EndIf;
	EndIf;
	vSettingsRow.Flag = pFlag;
	// Save settings
	Constants.SMSAutoDeliverySettings.Set(New ValueStorage(vSettings));
	// Return true
	Return True;
EndFunction // SetBackgroundJob

// -------------------------------------------------------------------------
&AtServer
Function ScheduleBackgroundJob(pFlag, pDeliveryTemplate, pDeliveryType, pDeliveryFilter, pMessageTemplate, pNumberOfDays = 0, pImportantDateType = Undefined)
	If Not pFlag Then
		Return NStr("en='Background job is not active!';ru='Фоновое задание выключено!';de='Hintergrundaufgabe ist ausgeschaltet!'");
	EndIf;
	// Check that hotel is choosen
	If Not ValueIsFilled(Hotel) Then
		pFlag = Not pFlag;
		Return NStr("en='Choose hotel first!';ru='Не указана гостиница!';de='Das Hotel ist nicht angegeben!'");
	EndIf;
	// Check that employee is choosen
	If Not ValueIsFilled(Employee) Then
		pFlag = Not pFlag;
		Return NStr("en='Choose user name to send messages at!';ru='Не указан пользователь от имени которого должны выполняться рассылки!';de='Der Nutzer, in dessen Namen der Verteiler verschickt werden soll, ist nicht angegeben!'");
	EndIf;
	// Check that delivery type is choosen
	If Not ValueIsFilled(pDeliveryType) Then
		pFlag = Not pFlag;
		Return NStr("en='Choose messages delivery type (SMS or E-Mail)!';ru='Не указан способ рассылки уведомлений (SMS или E-Mail)!';de='Es ist nicht angegeben, wie die Mitteilungen versendet werden sollen (E-Mail oder SMS)!'");
	EndIf;
	If pImportantDateType = Undefined Then
		// Check that message template is choosen
		If Not ValueIsFilled(pMessageTemplate) Then
			pFlag = Not pFlag;
			Return NStr("en='Choose messages template!';ru='Не указан шаблон сообщений!';de='Das Mitteilungsmuster ist nicht angegeben!'");
		EndIf; 
	Else
		If Not ValueIsFilled(pImportantDateType) Then
			pFlag = Not pFlag;
			Return NStr("en='Choose important date type!';ru='Не указан тип важной даты!';de='Wählen Sie einen wichtigen Datumstyp!'");	
		EndIf;
	EndIf;
	// Read SMS auto delivery settings
	vSettings = Constants.SMSAutoDeliverySettings.Get().Get();
	If vSettings = Undefined Then
		vSettings = InitializeSettingsTable();
	Else
		If vSettings.Columns.Find("DeliveryFilter") = Undefined Then
			vSettings.Columns.Add("DeliveryFilter", cmGetStringTypeDescription());
		EndIf;
		If vSettings.Columns.Find("NumberOfDays") = Undefined Then
			vSettings.Columns.Add("NumberOfDays", cmGetNumberTypeDescription(3, 0));
		EndIf; 
		If vSettings.Columns.Find("ImportantDateType") = Undefined Then
			vSettings.Columns.Add("ImportantDateType", cmGetCatalogTypeDescription("ImportantDateTypes"));
		EndIf;
	EndIf;
	// Try to find settings row for the current user choice
	vRows = vSettings.FindRows(New Structure("Hotel, DeliveryTemplate", Hotel, pDeliveryTemplate));
	If vRows <> Undefined And vRows.Count() > 0 Then
		vSettingsRow = vRows.Get(0);
	Else
		vSettingsRow = vSettings.Add();
		vSettingsRow.Hotel = Hotel;
		vSettingsRow.DeliveryTemplate = pDeliveryTemplate;
	EndIf;
	vSettingsRow.DeliveryFilter = pDeliveryFilter;
	vSettingsRow.User = Employee;
	vSettingsRow.NumberOfDays = pNumberOfDays;
	vSettingsRow.ImportantDateType = pImportantDateType;
	vReturnValue = Undefined;
	If Not IsBlankString(vSettingsRow.JobUUID) Then
		vJob = JobsScheduled.cmGetSMSAutoDeliveryJob(vSettingsRow.JobUUID);
		If vJob <> Undefined Then
			vReturnValue = New Structure("Schedule, JobUUID", vJob.Schedule, vSettingsRow.JobUUID);
		Else
			vSettingsRow.JobUUID = "";
		EndIf;
	Else
		vReturnValue = NStr("en='Background job is not found!';ru='Фоновое задание не найдено!';de='Hintergrundaufgabe wurde nicht gefunden!'");
		pFlag = False;
	EndIf;
	vSettingsRow.Flag = pFlag;
	// Save settings
	Constants.SMSAutoDeliverySettings.Set(New ValueStorage(vSettings));
	Return vReturnValue;
EndFunction // ScheduleBackgroundJob

// -------------------------------------------------------------------------
&AtServer
Procedure UpdateJob(pParStructure, pFlag)
	vJob = JobsScheduled.cmGetSMSAutoDeliveryJob(pParStructure.JobUUID);
	If pFlag = True Then
		vJob.Use = True;
		vJob.Schedule = pParStructure.Schedule;
	Else
		vJob.Use = False;
	EndIf;
	vJob.Write();
EndProcedure // UpdateJob

// -------------------------------------------------------------------------
&AtServer
Procedure DeleteBackgroundJob(pFlag, pDeliveryTemplate, pDeliveryFilter, pNumberOfDays = 0, pImportantDateType = Undefined)
	// Check that hotel is choosen
	If Not ValueIsFilled(Hotel) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Choose hotel first!';ru='Не указана гостиница!';de='Das Hotel ist nicht angegeben!'"));
		Return;
	EndIf;
	// Check that employee is choosen
	If Not ValueIsFilled(Employee) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Choose user name to send messages at!';ru='Не указан пользователь от имени которого должны выполняться рассылки!';de='Der Nutzer, in dessen Namen der Verteiler verschickt werden soll, ist nicht angegeben!'"));
		Return;
	EndIf;
	// Read SMS auto delivery settings
	vSettings = Constants.SMSAutoDeliverySettings.Get().Get();
	If vSettings = Undefined Then
		vSettings = InitializeSettingsTable();
	Else
		If vSettings.Columns.Find("DeliveryFilter") = Undefined Then
			vSettings.Columns.Add("DeliveryFilter", cmGetStringTypeDescription());
		EndIf;
		If vSettings.Columns.Find("NumberOfDays") = Undefined Then
			vSettings.Columns.Add("NumberOfDays", cmGetNumberTypeDescription(3, 0));
		EndIf;
		If vSettings.Columns.Find("ImportantDateType") = Undefined Then
			vSettings.Columns.Add("ImportantDateType", cmGetCatalogTypeDescription("ImportantDateTypes"));
		EndIf;
	EndIf;
	// Try to find settings row for the current user choice
	vRows = vSettings.FindRows(New Structure("Hotel, DeliveryTemplate", Hotel, pDeliveryTemplate));
	If vRows <> Undefined And vRows.Count() > 0 Then
		vSettingsRow = vRows.Get(0);
	Else
		vSettingsRow = vSettings.Add();
		vSettingsRow.Flag = False;
		vSettingsRow.Hotel = Hotel;
		vSettingsRow.DeliveryTemplate = pDeliveryTemplate;
	EndIf;
	vSettingsRow.DeliveryFilter = pDeliveryFilter;
	vSettingsRow.NumberOfDays = pNumberOfDays; 
	vSettingsRow.ImportantDateType = pImportantDateType;
	vSettingsRow.User = Employee;
	If Not IsBlankString(vSettingsRow.JobUUID) Then
		JobsScheduled.cmDeleteSMSAutoDeliveryJob(vSettingsRow.JobUUID);
		vSettingsRow.JobUUID = "";
		pFlag = False;
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Background job is not found!';ru='Фоновое задание не найдено!';de='Hintergrundaufgabe wurde nicht gefunden!'"));
		pFlag = False;
	EndIf;
	vSettingsRow.Flag = pFlag;
	// Save settings
	Constants.SMSAutoDeliverySettings.Set(New ValueStorage(vSettings));
EndProcedure // DeleteBackgroundJob

// -------------------------------------------------------------------------
&AtServer
Procedure SwitchOffBackgroundJob(pFlag, pDeliveryTemplate, pDeliveryFilter, pNumberOfDays = 0, pImportantDateType = Undefined)
	If pFlag Then
		Return;
	EndIf;
	// Check that hotel is choosen
	If Not ValueIsFilled(Hotel) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Choose hotel first!';ru='Не указана гостиница!';de='Das Hotel ist nicht angegeben!'"));
		Return;
	EndIf;
	// Check that employee is choosen
	If Not ValueIsFilled(Employee) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Choose user name to send messages at!';ru='Не указан пользователь от имени которого должны выполняться рассылки!';de='Der Nutzer, in dessen Namen der Verteiler verschickt werden soll, ist nicht angegeben!'"));
		Return;
	EndIf;
	// Read SMS auto delivery settings
	vSettings = Constants.SMSAutoDeliverySettings.Get().Get();
	If vSettings = Undefined Then
		vSettings = InitializeSettingsTable();
	Else
		If vSettings.Columns.Find("DeliveryFilter") = Undefined Then
			vSettings.Columns.Add("DeliveryFilter", cmGetStringTypeDescription());
		EndIf;
		If vSettings.Columns.Find("NumberOfDays") = Undefined Then
			vSettings.Columns.Add("NumberOfDays", cmGetNumberTypeDescription(3, 0));
		EndIf; 
		If vSettings.Columns.Find("ImportantDateType") = Undefined Then
			vSettings.Columns.Add("ImportantDateType", cmGetCatalogTypeDescription("ImportantDateTypes"));
		EndIf;
	EndIf;
	// Try to find settings row for the current user choice
	vRows = vSettings.FindRows(New Structure("Hotel, DeliveryTemplate", Hotel, pDeliveryTemplate));
	If vRows <> Undefined And vRows.Count() > 0 Then
		vSettingsRow = vRows.Get(0);
	Else
		vSettingsRow = vSettings.Add();
		vSettingsRow.Hotel = Hotel;
		vSettingsRow.DeliveryTemplate = pDeliveryTemplate;
	EndIf;
	vSettingsRow.DeliveryFilter = pDeliveryFilter;
	vSettingsRow.NumberOfDays = pNumberOfDays;
	vSettingsRow.ImportantDateType = pImportantDateType;
	vSettingsRow.User = Employee;
	If Not IsBlankString(vSettingsRow.JobUUID) Then
		vJob = JobsScheduled.cmGetSMSAutoDeliveryJob(vSettingsRow.JobUUID);
		If vJob <> Undefined Then
			vJob.Use = False;
			vJob.Write();
		Else
			vSettingsRow.JobUUID = "";
		EndIf;
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Background job is not found!';ru='Фоновое задание не найдено!';de='Hintergrundaufgabe wurde nicht gefunden!'"));
		pFlag = False;
	EndIf;
	vSettingsRow.Flag = pFlag;
	// Save settings
	Constants.SMSAutoDeliverySettings.Set(New ValueStorage(vSettings));
EndProcedure // SwitchOffBackgroundJob

// -------------------------------------------------------------------------
&AtServer
Procedure SwitchOnBackgroundJob(pFlag, pDeliveryTemplate, pDeliveryFilter, pNumberOfDays = 0, pImportantDateType = Undefined)
	If Not pFlag Then
		Return;
	EndIf;
	// Check that hotel is choosen
	If Not ValueIsFilled(Hotel) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Choose hotel first!';ru='Не указана гостиница!';de='Das Hotel ist nicht angegeben!'"));
		Return;
	EndIf;
	// Check that employee is choosen
	If Not ValueIsFilled(Employee) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Choose user name to send messages at!';ru='Не указан пользователь от имени которого должны выполняться рассылки!';de='Der Nutzer, in dessen Namen der Verteiler verschickt werden soll, ist nicht angegeben!'"));
		Return;
	EndIf;
	// Read SMS auto delivery settings
	vSettings = Constants.SMSAutoDeliverySettings.Get().Get();
	If vSettings = Undefined Then
		vSettings = InitializeSettingsTable();
	Else
		If vSettings.Columns.Find("DeliveryFilter") = Undefined Then
			vSettings.Columns.Add("DeliveryFilter", cmGetStringTypeDescription());
		EndIf;
		If vSettings.Columns.Find("NumberOfDays") = Undefined Then
			vSettings.Columns.Add("NumberOfDays", cmGetNumberTypeDescription(3, 0));
		EndIf;
		If vSettings.Columns.Find("ImportantDateType") = Undefined Then
			vSettings.Columns.Add("ImportantDateType", cmGetCatalogTypeDescription("ImportantDateTypes"));
		EndIf;
	EndIf;
	// Try to find settings row for the current user choice
	vRows = vSettings.FindRows(New Structure("Hotel, DeliveryTemplate", Hotel, pDeliveryTemplate));
	If vRows <> Undefined And vRows.Count() > 0 Then
		vSettingsRow = vRows.Get(0);
	Else
		vSettingsRow = vSettings.Add();
		vSettingsRow.Hotel = Hotel;
		vSettingsRow.DeliveryTemplate = pDeliveryTemplate;
	EndIf;
	vSettingsRow.DeliveryFilter = pDeliveryFilter;
	vSettingsRow.NumberOfDays = pNumberOfDays;
	vSettingsRow.ImportantDateType = pImportantDateType;
	vSettingsRow.User = Employee;
	If Not IsBlankString(vSettingsRow.JobUUID) Then
		vJob = JobsScheduled.cmGetSMSAutoDeliveryJob(vSettingsRow.JobUUID);
		If vJob <> Undefined Then
			vJob.Use = True;
			vJob.Write();
		Else
			vSettingsRow.JobUUID = "";
		EndIf;
	EndIf;
	vSettingsRow.Flag = pFlag;
	// Save settings
	Constants.SMSAutoDeliverySettings.Set(New ValueStorage(vSettings));
EndProcedure // SwitchOnBackgroundJob

// -------------------------------------------------------------------------
&AtClient
Procedure SetFormAppearance()
	Items.InHouseGuestsBirthdayCongratulationDeliveryType.Enabled = InHouseGuestsBirthdayCongratulation;
	Items.InHouseGuestsBirthdayCongratulationDeliveryFilter.Enabled = InHouseGuestsBirthdayCongratulation;
	Items.InHouseGuestsBirthdayCongratulationMessageTemplate.Enabled = InHouseGuestsBirthdayCongratulation;
	Items.InHouseGuestsBirthdayCongratulationAddJobButton.Enabled = InHouseGuestsBirthdayCongratulation;
	Items.InHouseGuestsBirthdayCongratulationDeleteJobButton.Enabled = InHouseGuestsBirthdayCongratulation;
	
	Items.InHouseGuestsFolioBalanceNotificationDeliveryType.Enabled = InHouseGuestsFolioBalanceNotification;
	Items.InHouseGuestsFolioBalanceNotificationDeliveryFilter.Enabled = InHouseGuestsFolioBalanceNotification;
	Items.InHouseGuestsFolioBalanceNotificationMessageTemplate.Enabled = InHouseGuestsFolioBalanceNotification;
	Items.InHouseGuestsFolioBalanceNotificationAddJobButton.Enabled = InHouseGuestsFolioBalanceNotification;
	Items.InHouseGuestsFolioBalanceNotificationDeleteJobButton.Enabled = InHouseGuestsFolioBalanceNotification;
	
	Items.ExpectedCheckOutGuestsFolioBalanceNotificationDeliveryType.Enabled = ExpectedCheckOutGuestsFolioBalanceNotification;
	Items.ExpectedCheckOutGuestsFolioBalanceNotificationDeliveryFilter.Enabled = ExpectedCheckOutGuestsFolioBalanceNotification;
	Items.ExpectedCheckOutGuestsFolioBalanceNotificationMessageTemplate.Enabled = ExpectedCheckOutGuestsFolioBalanceNotification;
	Items.ExpectedCheckOutGuestsFolioBalanceNotificationAddJobButton.Enabled = ExpectedCheckOutGuestsFolioBalanceNotification;
	Items.ExpectedCheckOutGuestsFolioBalanceNotificationDeleteJobButton.Enabled = ExpectedCheckOutGuestsFolioBalanceNotification;
	
	Items.ExpectedCheckInGuestsNotificationDeliveryType.Enabled = ExpectedCheckInGuestsNotification;
	Items.ExpectedCheckInGuestsNotificationDeliveryFilter.Enabled = ExpectedCheckInGuestsNotification;
	Items.ExpectedCheckInGuestsNotificationMessageTemplate.Enabled = ExpectedCheckInGuestsNotification;
	Items.ExpectedCheckInGuestsNotificationAddJobButton.Enabled = ExpectedCheckInGuestsNotification;
	Items.ExpectedCheckInGuestsNotificationDeleteJobButton.Enabled = ExpectedCheckInGuestsNotification;
	
	Items.CheckedInGuestsNotificationDeliveryType.Enabled = CheckedInGuestsNotification;
	Items.CheckedInGuestsNotificationDeliveryFilter.Enabled = CheckedInGuestsNotification;
	Items.CheckedInGuestsNotificationMessageTemplate.Enabled = CheckedInGuestsNotification;
	Items.CheckedInGuestsNotificationAddJobButton.Enabled = CheckedInGuestsNotification;
	Items.CheckedInGuestsNotificationDeleteJobButton.Enabled = CheckedInGuestsNotification;
	
	Items.InHouseGuestsNotificationDeliveryType.Enabled = InHouseGuestsNotification;
	Items.InHouseGuestsNotificationDeliveryFilter.Enabled = InHouseGuestsNotification;
	Items.InHouseGuestsNotificationMessageTemplate.Enabled = InHouseGuestsNotification;
	Items.InHouseGuestsNotificationAddJobButton.Enabled = InHouseGuestsNotification;
	Items.InHouseGuestsNotificationDeleteJobButton.Enabled = InHouseGuestsNotification;
	
	Items.ExpectedCheckOutGuestsNotificationDeliveryType.Enabled = ExpectedCheckOutGuestsNotification;
	Items.ExpectedCheckOutGuestsNotificationDeliveryFilter.Enabled = ExpectedCheckOutGuestsNotification;
	Items.ExpectedCheckOutGuestsNotificationMessageTemplate.Enabled = ExpectedCheckOutGuestsNotification;
	Items.ExpectedCheckOutGuestsNotificationAddJobButton.Enabled = ExpectedCheckOutGuestsNotification;
	Items.ExpectedCheckOutGuestsNotificationDeleteJobButton.Enabled = ExpectedCheckOutGuestsNotification;
	
	Items.CheckedOutGuestsNotificationDeliveryType.Enabled = CheckedOutGuestsNotification;
	Items.CheckedOutGuestsNotificationDeliveryFilter.Enabled = CheckedOutGuestsNotification;
	Items.CheckedOutGuestsNotificationMessageTemplate.Enabled = CheckedOutGuestsNotification;
	Items.CheckedOutGuestsNotificationAddJobButton.Enabled = CheckedOutGuestsNotification;
	Items.CheckedOutGuestsNotificationDeleteJobButton.Enabled = CheckedOutGuestsNotification;
	
	Items.ExpiredInvoicesNotificationDeliveryType.Enabled = ExpiredInvoicesNotification;
	Items.ExpiredInvoicesNotificationDeliveryFilter.Enabled = ExpiredInvoicesNotification;
	Items.ExpiredInvoicesNotificationMessageTemplate.Enabled = ExpiredInvoicesNotification;
	Items.ExpiredInvoicesNotificationAddJobButton.Enabled = ExpiredInvoicesNotification;
	Items.ExpiredInvoicesNotificationDeleteJobButton.Enabled = ExpiredInvoicesNotification;
	
	Items.AfterCheckOutGuestsNotificationDeliveryType.Enabled = AfterCheckOutGuestsNotification;
	Items.AfterCheckOutGuestsNotificationDeliveryFilter.Enabled = AfterCheckOutGuestsNotification;
	Items.AfterCheckOutGuestsNotificationMessageTemplate.Enabled = AfterCheckOutGuestsNotification;
	Items.AfterCheckOutGuestsNotificationAddJobButton.Enabled = AfterCheckOutGuestsNotification;
	Items.AfterCheckOutGuestsNotificationDeleteJobButton.Enabled = AfterCheckOutGuestsNotification; 
	Items.AfterCheckOutGuestsNotificationNumberOfDays.Enabled = AfterCheckOutGuestsNotification;
	
	Items.BeforeCheckInGuestsNotificationDeliveryType.Enabled = BeforeCheckInGuestsNotification;
	Items.BeforeCheckInGuestsNotificationDeliveryFilter.Enabled = BeforeCheckInGuestsNotification;
	Items.BeforeCheckInGuestsNotificationMessageTemplate.Enabled = BeforeCheckInGuestsNotification;
	Items.BeforeCheckInGuestsNotificationAddJobButton.Enabled = BeforeCheckInGuestsNotification;
	Items.BeforeCheckInGuestsNotificationDeleteJobButton.Enabled = BeforeCheckInGuestsNotification; 
	Items.BeforeCheckInGuestsNotificationNumberOfDays.Enabled = BeforeCheckInGuestsNotification;
	
	Items.AllClientsBirthdayCongratulationDeliveryType.Enabled = AllClientsBirthdayCongratulation;
	Items.AllClientsBirthdayCongratulationDeliveryFilter.Enabled = AllClientsBirthdayCongratulation;
	Items.AllClientsBirthdayCongratulationMessageTemplate.Enabled = AllClientsBirthdayCongratulation;
	Items.AllClientsBirthdayCongratulationAddJobButton.Enabled = AllClientsBirthdayCongratulation;
	Items.AllClientsBirthdayCongratulationDeleteJobButton.Enabled = AllClientsBirthdayCongratulation; 
	Items.AllClientsBirthdayCongratulationNumberOfDays.Enabled = AllClientsBirthdayCongratulation;
	
	Items.AllClientsImportantDateCongratulationDeliveryType1.Enabled = AllClientsImportantDateCongratulation1;
	Items.AllClientsImportantDateCongratulationDeliveryFilter1.Enabled = AllClientsImportantDateCongratulation1;
	Items.AllClientsImportantDateCongratulationImportantDateType1.Enabled = AllClientsImportantDateCongratulation1;
	Items.AllClientsImportantDateCongratulationAddJobButton1.Enabled = AllClientsImportantDateCongratulation1;
	Items.AllClientsImportantDateCongratulationDeleteJobButton1.Enabled = AllClientsImportantDateCongratulation1;
	vAllClientsImportantDateCongratulationImportantDateType1 = AllClientsImportantDateCongratulationImportantDateType1;
	vAllClientsImportantDateCongratulationImportantDateNumberOfDays1 = AllClientsImportantDateCongratulationNumberOfDays1;
	If ValueIsFilled(vAllClientsImportantDateCongratulationImportantDateType1) Then
		vNewAllClientsImportantDateCongratulationImportantDateNumberOfDays1 = tcOnServer.cmGetAttributeByRef(vAllClientsImportantDateCongratulationImportantDateType1, "NumberOfDays");
		If vAllClientsImportantDateCongratulationImportantDateNumberOfDays1 <> vNewAllClientsImportantDateCongratulationImportantDateNumberOfDays1 Then
			AllClientsImportantDateCongratulationNumberOfDays1 = vNewAllClientsImportantDateCongratulationImportantDateNumberOfDays1;
		EndIf;
	Else
		AllClientsImportantDateCongratulationNumberOfDays1 = 0;
	EndIf;
	
	Items.AllClientsImportantDateCongratulationDeliveryType2.Enabled = AllClientsImportantDateCongratulation2;
	Items.AllClientsImportantDateCongratulationDeliveryFilter2.Enabled = AllClientsImportantDateCongratulation2;
	Items.AllClientsImportantDateCongratulationImportantDateType2.Enabled = AllClientsImportantDateCongratulation2;
	Items.AllClientsImportantDateCongratulationAddJobButton2.Enabled = AllClientsImportantDateCongratulation2;
	Items.AllClientsImportantDateCongratulationDeleteJobButton2.Enabled = AllClientsImportantDateCongratulation2;
	vAllClientsImportantDateCongratulationImportantDateType2 = AllClientsImportantDateCongratulationImportantDateType2;
	vAllClientsImportantDateCongratulationImportantDateNumberOfDays2 = AllClientsImportantDateCongratulationNumberOfDays2;
	If ValueIsFilled(vAllClientsImportantDateCongratulationImportantDateType2) Then
		vNewAllClientsImportantDateCongratulationImportantDateNumberOfDays2 = tcOnServer.cmGetAttributeByRef(vAllClientsImportantDateCongratulationImportantDateType2, "NumberOfDays");
		If vAllClientsImportantDateCongratulationImportantDateNumberOfDays2 <> vNewAllClientsImportantDateCongratulationImportantDateNumberOfDays2 Then
			AllClientsImportantDateCongratulationNumberOfDays2 = vNewAllClientsImportantDateCongratulationImportantDateNumberOfDays2;
		EndIf;
	Else
		AllClientsImportantDateCongratulationNumberOfDays2 = 0;
	EndIf;
	
	Items.AllClientsImportantDateCongratulationDeliveryType3.Enabled = AllClientsImportantDateCongratulation3;
	Items.AllClientsImportantDateCongratulationDeliveryFilter3.Enabled = AllClientsImportantDateCongratulation3;
	Items.AllClientsImportantDateCongratulationImportantDateType3.Enabled = AllClientsImportantDateCongratulation3;
	Items.AllClientsImportantDateCongratulationAddJobButton3.Enabled = AllClientsImportantDateCongratulation3;
	Items.AllClientsImportantDateCongratulationDeleteJobButton3.Enabled = AllClientsImportantDateCongratulation3;
	vAllClientsImportantDateCongratulationImportantDateType3 = AllClientsImportantDateCongratulationImportantDateType3;
	vAllClientsImportantDateCongratulationImportantDateNumberOfDays3 = AllClientsImportantDateCongratulationNumberOfDays3;
	If ValueIsFilled(vAllClientsImportantDateCongratulationImportantDateType3) Then
		vNewAllClientsImportantDateCongratulationImportantDateNumberOfDays3 = tcOnServer.cmGetAttributeByRef(vAllClientsImportantDateCongratulationImportantDateType3, "NumberOfDays");
		If vAllClientsImportantDateCongratulationImportantDateNumberOfDays3 <> vNewAllClientsImportantDateCongratulationImportantDateNumberOfDays3 Then
			AllClientsImportantDateCongratulationNumberOfDays3 = vNewAllClientsImportantDateCongratulationImportantDateNumberOfDays3;
		EndIf;
	Else
		AllClientsImportantDateCongratulationNumberOfDays3 = 0;
	EndIf;
EndProcedure // SetFormAppearance

// -------------------------------------------------------------------------
&AtClient
Procedure InHouseGuestsBirthdayCongratulationAddJobCommand(pCommand)
	If SetBackgroundJob(InHouseGuestsBirthdayCongratulation, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "InHouseGuestsBirthdayCongratulation"), InHouseGuestsBirthdayCongratulationDeliveryType, InHouseGuestsBirthdayCongratulationDeliveryFilter, InHouseGuestsBirthdayCongratulationMessageTemplate, NStr("en='In-house guests birthday congratulation';ru='Поздравление с днем рождения проживающих гостей';de='Gratulationen zu Geburtstagen untergebrachter Gäste'")) Then
		vResult = ScheduleBackgroundJob(InHouseGuestsBirthdayCongratulation, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "InHouseGuestsBirthdayCongratulation"), InHouseGuestsBirthdayCongratulationDeliveryType, InHouseGuestsBirthdayCongratulationDeliveryFilter, InHouseGuestsBirthdayCongratulationMessageTemplate);
		If TypeOf(vResult) = Type("String") Then
			ShowMessageBox(,vResult);
		ElsIf TypeOf(vResult) = Type("Structure") Then
			vScheduleDlg = New ScheduledJobDialog(vResult.Schedule);
			vScheduleDlg.Show(New NotifyDescription("InHouseGuestsBirthdayCongratulationAddJobCommandEnd", ThisObject, New Structure("vResult, vScheduleDlg", vResult, vScheduleDlg)));
            Return;
		EndIf;
	EndIf;
	InHouseGuestsBirthdayCongratulationAddJobCommandPart();
EndProcedure

&AtClient
Procedure InHouseGuestsBirthdayCongratulationAddJobCommandEnd(Schedule, AdditionalParameters) Export
	
	vResult = AdditionalParameters.vResult;
	vScheduleDlg = AdditionalParameters.vScheduleDlg;
	
	
	If Schedule <> Undefined Then
		vResult.Schedule = vScheduleDlg.Schedule;
		UpdateJob(vResult, True);
	Else
		ShowMessageBox(,NStr("en='User have canceled operation!';ru='Действие отменено пользователем!';de='Aktion vom Nutzer abgebrochen!'"));
		UpdateJob(vResult, False);
		InHouseGuestsBirthdayCongratulation = False;
	EndIf;
	
	InHouseGuestsBirthdayCongratulationAddJobCommandPart();

EndProcedure

&AtClient
Procedure InHouseGuestsBirthdayCongratulationAddJobCommandPart()
	
	SetFormAppearance();

EndProcedure // InHouseGuestsBirthdayCongratulationCommand

// -------------------------------------------------------------------------
&AtClient
Procedure InHouseGuestsFolioBalanceNotificationAddJobCommand(pCommand)
	If SetBackgroundJob(InHouseGuestsFolioBalanceNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "InHouseGuestsFolioBalanceNotification"), InHouseGuestsFolioBalanceNotificationDeliveryType, InHouseGuestsFolioBalanceNotificationDeliveryFilter, InHouseGuestsFolioBalanceNotificationMessageTemplate, NStr("en='In-house guests folio balance notification';ru='Рассылка балансов по лицевым счетам проживающих гостей';de='Versand von Bilanzen nach Personenkonten von Hotelgästen'")) Then
		vResult = ScheduleBackgroundJob(InHouseGuestsFolioBalanceNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "InHouseGuestsFolioBalanceNotification"), InHouseGuestsFolioBalanceNotificationDeliveryType, InHouseGuestsFolioBalanceNotificationDeliveryFilter, InHouseGuestsFolioBalanceNotificationMessageTemplate);
		If TypeOf(vResult) = Type("String") Then
			ShowMessageBox(,vResult);
		ElsIf TypeOf(vResult) = Type("Structure") Then
			vScheduleDlg = New ScheduledJobDialog(vResult.Schedule);
			vScheduleDlg.Show(New NotifyDescription("InHouseGuestsFolioBalanceNotificationAddJobCommandEnd", ThisObject, New Structure("vResult, vScheduleDlg", vResult, vScheduleDlg)));
            Return;
		EndIf;
	EndIf;
	InHouseGuestsFolioBalanceNotificationAddJobCommandPart();
EndProcedure

&AtClient
Procedure InHouseGuestsFolioBalanceNotificationAddJobCommandEnd(Schedule, AdditionalParameters) Export
	
	vResult = AdditionalParameters.vResult;
	vScheduleDlg = AdditionalParameters.vScheduleDlg;
	
	
	If Schedule <> Undefined Then
		vResult.Schedule = vScheduleDlg.Schedule;
		UpdateJob(vResult, True);
	Else
		ShowMessageBox(,NStr("en='User have canceled operation!';ru='Действие отменено пользователем!';de='Aktion vom Nutzer abgebrochen!'"));
		UpdateJob(vResult, False);
		InHouseGuestsFolioBalanceNotification = False;
	EndIf;
	
	InHouseGuestsFolioBalanceNotificationAddJobCommandPart();

EndProcedure

&AtClient
Procedure InHouseGuestsFolioBalanceNotificationAddJobCommandPart()
	
	SetFormAppearance();

EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure ExpectedCheckOutGuestsFolioBalanceNotificationAddJobCommand(pCommand)
	If SetBackgroundJob(ExpectedCheckOutGuestsFolioBalanceNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "ExpectedCheckOutGuestsFolioBalanceNotification"), ExpectedCheckOutGuestsFolioBalanceNotificationDeliveryType, ExpectedCheckOutGuestsFolioBalanceNotificationDeliveryFilter, ExpectedCheckOutGuestsFolioBalanceNotificationMessageTemplate, NStr("en='Expected check-out guests folio balance notification';ru='Рассылка балансов по лицевым счетам гостей на планируемом выезде';de='Versand der Bilanzen nach Personenkonten von Gästen zur geplanten Abreise'")) Then
		vResult = ScheduleBackgroundJob(ExpectedCheckOutGuestsFolioBalanceNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "ExpectedCheckOutGuestsFolioBalanceNotification"), ExpectedCheckOutGuestsFolioBalanceNotificationDeliveryType, ExpectedCheckOutGuestsFolioBalanceNotificationDeliveryFilter, ExpectedCheckOutGuestsFolioBalanceNotificationMessageTemplate);
		If TypeOf(vResult) = Type("String") Then
			ShowMessageBox(,vResult);
		ElsIf TypeOf(vResult) = Type("Structure") Then
			vScheduleDlg = New ScheduledJobDialog(vResult.Schedule);
			vScheduleDlg.Show(New NotifyDescription("ExpectedCheckOutGuestsFolioBalanceNotificationAddJobCommandEnd", ThisObject, New Structure("vResult, vScheduleDlg", vResult, vScheduleDlg)));
            Return;
		EndIf;
	EndIf;
	ExpectedCheckOutGuestsFolioBalanceNotificationAddJobCommandPart();
EndProcedure

&AtClient
Procedure ExpectedCheckOutGuestsFolioBalanceNotificationAddJobCommandEnd(Schedule, AdditionalParameters) Export
	
	vResult = AdditionalParameters.vResult;
	vScheduleDlg = AdditionalParameters.vScheduleDlg;
	
	
	If Schedule <> Undefined Then
		vResult.Schedule = vScheduleDlg.Schedule;
		UpdateJob(vResult, True);
	Else
		ShowMessageBox(,NStr("en='User have canceled operation!';ru='Действие отменено пользователем!';de='Aktion vom Nutzer abgebrochen!'"));
		UpdateJob(vResult, False);
		ExpectedCheckOutGuestsFolioBalanceNotification = False;
	EndIf;
	
	ExpectedCheckOutGuestsFolioBalanceNotificationAddJobCommandPart();

EndProcedure

&AtClient
Procedure ExpectedCheckOutGuestsFolioBalanceNotificationAddJobCommandPart()
	
	SetFormAppearance();

EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure ExpectedCheckInGuestsNotificationAddJobCommand(pCommand)
	If SetBackgroundJob(ExpectedCheckInGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "ExpectedCheckInGuestsNotification"), ExpectedCheckInGuestsNotificationDeliveryType, ExpectedCheckInGuestsNotificationDeliveryFilter, ExpectedCheckInGuestsNotificationMessageTemplate, NStr("en='Expected check-in guests notification';ru='Уведомление гостей на планируемом заезде';de='Benachrichtigung der Gäste auf der geplanten Abreise'")) Then
		vResult = ScheduleBackgroundJob(ExpectedCheckInGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "ExpectedCheckInGuestsNotification"), ExpectedCheckInGuestsNotificationDeliveryType, ExpectedCheckInGuestsNotificationDeliveryFilter, ExpectedCheckInGuestsNotificationMessageTemplate);
		If TypeOf(vResult) = Type("String") Then
			ShowMessageBox(,vResult);
		ElsIf TypeOf(vResult) = Type("Structure") Then
			vScheduleDlg = New ScheduledJobDialog(vResult.Schedule);
			vScheduleDlg.Show(New NotifyDescription("ExpectedCheckInGuestsNotificationAddJobCommandEnd", ThisObject, New Structure("vResult, vScheduleDlg", vResult, vScheduleDlg)));
            Return;
		EndIf;
	EndIf;
	ExpectedCheckInGuestsNotificationAddJobCommandPart();
EndProcedure

&AtClient
Procedure ExpectedCheckInGuestsNotificationAddJobCommandEnd(Schedule, AdditionalParameters) Export
	
	vResult = AdditionalParameters.vResult;
	vScheduleDlg = AdditionalParameters.vScheduleDlg;
	
	
	If Schedule <> Undefined Then
		vResult.Schedule = vScheduleDlg.Schedule;
		UpdateJob(vResult, True);
	Else
		ShowMessageBox(,NStr("en='User have canceled operation!';ru='Действие отменено пользователем!';de='Aktion vom Nutzer abgebrochen!'"));
		UpdateJob(vResult, False);
		ExpectedCheckInGuestsNotification = False;
	EndIf;
	
	ExpectedCheckInGuestsNotificationAddJobCommandPart();

EndProcedure

&AtClient
Procedure ExpectedCheckInGuestsNotificationAddJobCommandPart()
	
	SetFormAppearance();

EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure CheckedInGuestsNotificationAddJobCommand(pCommand)
	If SetBackgroundJob(CheckedInGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "CheckedInGuestsNotification"), CheckedInGuestsNotificationDeliveryType, CheckedInGuestsNotificationDeliveryFilter, CheckedInGuestsNotificationMessageTemplate, NStr("en='Checked-in guests notification';ru='Уведомление фактически заехавших гостей';de='Benachrichtigung von faktisch angereisten Gästen'")) Then
		vResult = ScheduleBackgroundJob(CheckedInGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "CheckedInGuestsNotification"), CheckedInGuestsNotificationDeliveryType, CheckedInGuestsNotificationDeliveryFilter, CheckedInGuestsNotificationMessageTemplate);
		If TypeOf(vResult) = Type("String") Then
			ShowMessageBox(,vResult);
		ElsIf TypeOf(vResult) = Type("Structure") Then
			vScheduleDlg = New ScheduledJobDialog(vResult.Schedule);
			vScheduleDlg.Show(New NotifyDescription("CheckedInGuestsNotificationAddJobCommandEnd", ThisObject, New Structure("vResult, vScheduleDlg", vResult, vScheduleDlg)));
            Return;
		EndIf;
	EndIf;
	CheckedInGuestsNotificationAddJobCommandPart();
EndProcedure

&AtClient
Procedure CheckedInGuestsNotificationAddJobCommandEnd(Schedule, AdditionalParameters) Export
	
	vResult = AdditionalParameters.vResult;
	vScheduleDlg = AdditionalParameters.vScheduleDlg;
	
	
	If Schedule <> Undefined Then
		vResult.Schedule = vScheduleDlg.Schedule;
		UpdateJob(vResult, True);
	Else
		ShowMessageBox(,NStr("en='User have canceled operation!';ru='Действие отменено пользователем!';de='Aktion vom Nutzer abgebrochen!'"));
		UpdateJob(vResult, False);
		CheckedInGuestsNotification = False;
	EndIf;
	
	CheckedInGuestsNotificationAddJobCommandPart();

EndProcedure

&AtClient
Procedure CheckedInGuestsNotificationAddJobCommandPart()
	
	SetFormAppearance();

EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure InHouseGuestsNotificationAddJobCommand(Command)
	If SetBackgroundJob(InHouseGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "InHouseGuestsNotification"), InHouseGuestsNotificationDeliveryType, InHouseGuestsNotificationDeliveryFilter, InHouseGuestsNotificationMessageTemplate, NStr("en='In-house guests notification';ru='Уведомление проживающих гостей';de='Benachrichtigung von Hotelgästen'")) Then
		vResult = ScheduleBackgroundJob(InHouseGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "InHouseGuestsNotification"), InHouseGuestsNotificationDeliveryType, InHouseGuestsNotificationDeliveryFilter, InHouseGuestsNotificationMessageTemplate);
		If TypeOf(vResult) = Type("String") Then
			ShowMessageBox(,vResult);
		ElsIf TypeOf(vResult) = Type("Structure") Then
			vScheduleDlg = New ScheduledJobDialog(vResult.Schedule);
			vScheduleDlg.Show(New NotifyDescription("InHouseGuestsNotificationAddJobCommandEnd", ThisObject, New Structure("vResult, vScheduleDlg", vResult, vScheduleDlg)));
            Return;
		EndIf;
	EndIf;
	InHouseGuestsNotificationAddJobCommandPart();
EndProcedure

&AtClient
Procedure InHouseGuestsNotificationAddJobCommandEnd(Schedule, AdditionalParameters) Export
	
	vResult = AdditionalParameters.vResult;
	vScheduleDlg = AdditionalParameters.vScheduleDlg;
	
	
	If Schedule <> Undefined Then
		vResult.Schedule = vScheduleDlg.Schedule;
		UpdateJob(vResult, True);
	Else
		ShowMessageBox(,NStr("en='User have canceled operation!';ru='Действие отменено пользователем!';de='Aktion vom Nutzer abgebrochen!'"));
		UpdateJob(vResult, False);
		InHouseGuestsNotification = False;
	EndIf;
	
	InHouseGuestsNotificationAddJobCommandPart();

EndProcedure

&AtClient
Procedure InHouseGuestsNotificationAddJobCommandPart()
	
	SetFormAppearance();

EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure ExpectedCheckOutGuestsNotificationAddJobCommand(pCommand)
	If SetBackgroundJob(ExpectedCheckOutGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "ExpectedCheckOutGuestsNotification"), ExpectedCheckOutGuestsNotificationDeliveryType, ExpectedCheckOutGuestsNotificationDeliveryFilter, ExpectedCheckOutGuestsNotificationMessageTemplate, NStr("en='Expected check-out guests notification';ru='Уведомление гостей на планируемом выезде';de='Benachrichtigung der Gäste auf der geplanten Abreise'")) Then
		vResult = ScheduleBackgroundJob(ExpectedCheckOutGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "ExpectedCheckOutGuestsNotification"), ExpectedCheckOutGuestsNotificationDeliveryType, ExpectedCheckOutGuestsNotificationDeliveryFilter, ExpectedCheckOutGuestsNotificationMessageTemplate);
		If TypeOf(vResult) = Type("String") Then
			ShowMessageBox(,vResult);
		ElsIf TypeOf(vResult) = Type("Structure") Then
			vScheduleDlg = New ScheduledJobDialog(vResult.Schedule);
			vScheduleDlg.Show(New NotifyDescription("ExpectedCheckOutGuestsNotificationAddJobCommandEnd", ThisObject, New Structure("vResult, vScheduleDlg", vResult, vScheduleDlg)));
            Return;
		EndIf;
	EndIf;
	ExpectedCheckOutGuestsNotificationAddJobCommandPart();
EndProcedure

&AtClient
Procedure ExpectedCheckOutGuestsNotificationAddJobCommandEnd(Schedule, AdditionalParameters) Export
	
	vResult = AdditionalParameters.vResult;
	vScheduleDlg = AdditionalParameters.vScheduleDlg;
	
	
	If Schedule <> Undefined Then
		vResult.Schedule = vScheduleDlg.Schedule;
		UpdateJob(vResult, True);
	Else
		ShowMessageBox(,NStr("en='User have canceled operation!';ru='Действие отменено пользователем!';de='Aktion vom Nutzer abgebrochen!'"));
		UpdateJob(vResult, False);
		ExpectedCheckOutGuestsNotification = False;
	EndIf;
	
	ExpectedCheckOutGuestsNotificationAddJobCommandPart();

EndProcedure

&AtClient
Procedure ExpectedCheckOutGuestsNotificationAddJobCommandPart()
	
	SetFormAppearance();

EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure CheckedOutGuestsNotificationAddJobCommand(pCommand)
	If SetBackgroundJob(CheckedOutGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "CheckedOutGuestsNotification"), CheckedOutGuestsNotificationDeliveryType, CheckedOutGuestsNotificationDeliveryFilter, CheckedOutGuestsNotificationMessageTemplate, NStr("en='Checked-out guests notification';ru='Уведомление фактически выехавших гостей';de='Benachrichtigung von faktisch abgereisten Gästen'")) Then
		vResult = ScheduleBackgroundJob(CheckedOutGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "CheckedOutGuestsNotification"), CheckedOutGuestsNotificationDeliveryType, CheckedOutGuestsNotificationDeliveryFilter, CheckedOutGuestsNotificationMessageTemplate);
		If TypeOf(vResult) = Type("String") Then
			ShowMessageBox(,vResult);
		ElsIf TypeOf(vResult) = Type("Structure") Then
			vScheduleDlg = New ScheduledJobDialog(vResult.Schedule);
			vScheduleDlg.Show(New NotifyDescription("CheckedOutGuestsNotificationAddJobCommandEnd", ThisObject, New Structure("vResult, vScheduleDlg", vResult, vScheduleDlg)));
            Return;
		EndIf;
	EndIf;
	CheckedOutGuestsNotificationAddJobCommandPart();
EndProcedure

&AtClient
Procedure CheckedOutGuestsNotificationAddJobCommandEnd(Schedule, AdditionalParameters) Export
	
	vResult = AdditionalParameters.vResult;
	vScheduleDlg = AdditionalParameters.vScheduleDlg;
	
	
	If Schedule <> Undefined Then
		vResult.Schedule = vScheduleDlg.Schedule;
		UpdateJob(vResult, True);
	Else
		ShowMessageBox(,NStr("en='User have canceled operation!';ru='Действие отменено пользователем!';de='Aktion vom Nutzer abgebrochen!'"));
		UpdateJob(vResult, False);
		CheckedOutGuestsNotification = False;
	EndIf;
	
	CheckedOutGuestsNotificationAddJobCommandPart();

EndProcedure

&AtClient
Procedure CheckedOutGuestsNotificationAddJobCommandPart()
	
	SetFormAppearance();

EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure ExpiredInvoicesNotificationAddJobCommand(pCommand)
	If SetBackgroundJob(ExpiredInvoicesNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "ExpiredInvoicesNotification"), ExpiredInvoicesNotificationDeliveryType, ExpiredInvoicesNotificationDeliveryFilter, ExpiredInvoicesNotificationMessageTemplate, NStr("de='Das Versenden von Rechnungen per E-Mail, die morgen überfällig sein werden';en='Expired invoices E-Mail notification';ru='E-Mail рассылка счетов-требований, которые завтра выйдут на просрочку'")) Then
		vResult = ScheduleBackgroundJob(ExpiredInvoicesNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "ExpiredInvoicesNotification"), ExpiredInvoicesNotificationDeliveryType, ExpiredInvoicesNotificationDeliveryFilter, ExpiredInvoicesNotificationMessageTemplate);
		If TypeOf(vResult) = Type("String") Then
			ShowMessageBox(,vResult);
		ElsIf TypeOf(vResult) = Type("Structure") Then
			vScheduleDlg = New ScheduledJobDialog(vResult.Schedule);
			vScheduleDlg.Show(New NotifyDescription("ExpiredInvoicesNotificationAddJobCommandEnd", ThisObject, New Structure("vResult, vScheduleDlg", vResult, vScheduleDlg)));
            Return;
		EndIf;
	EndIf;
	ExpiredInvoicesNotificationAddJobCommandPart();
EndProcedure

&AtClient
Procedure ExpiredInvoicesNotificationAddJobCommandEnd(Schedule, AdditionalParameters) Export
	
	vResult = AdditionalParameters.vResult;
	vScheduleDlg = AdditionalParameters.vScheduleDlg;
	
	
	If Schedule <> Undefined Then
		vResult.Schedule = vScheduleDlg.Schedule;
		UpdateJob(vResult, True);
	Else
		ShowMessageBox(,NStr("en='User have canceled operation!';ru='Действие отменено пользователем!';de='Aktion vom Nutzer abgebrochen!'"));
		UpdateJob(vResult, False);
		ExpiredInvoicesNotification = False;
	EndIf;
	
	ExpiredInvoicesNotificationAddJobCommandPart();

EndProcedure

&AtClient
Procedure ExpiredInvoicesNotificationAddJobCommandPart()
	
	SetFormAppearance();

EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure AllClientsBirthdayCongratulationAddJobCommand(pCommand)
	If SetBackgroundJob(AllClientsBirthdayCongratulation, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "AllClientsBirthdayCongratulation"), AllClientsBirthdayCongratulationDeliveryType, AllClientsBirthdayCongratulationDeliveryFilter, AllClientsBirthdayCongratulationMessageTemplate, NStr("en='Birthday congratulation for clients in database';ru='Поздравление с днем рождения по всей клиентской базе';de='Gratulationen zu Geburtstagen für alle Kunden'"), AllClientsBirthdayCongratulationNumberOfDays) Then
		vResult = ScheduleBackgroundJob(AllClientsBirthdayCongratulation, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "AllClientsBirthdayCongratulation"), AllClientsBirthdayCongratulationDeliveryType, AllClientsBirthdayCongratulationDeliveryFilter, AllClientsBirthdayCongratulationMessageTemplate, AllClientsBirthdayCongratulationNumberOfDays);
		If TypeOf(vResult) = Type("String") Then
			ShowMessageBox(,vResult);
		ElsIf TypeOf(vResult) = Type("Structure") Then
			vScheduleDlg = New ScheduledJobDialog(vResult.Schedule);
			vScheduleDlg.Show(New NotifyDescription("AllClientsBirthdayCongratulationAddJobCommandEnd", ThisObject, New Structure("vResult, vScheduleDlg", vResult, vScheduleDlg)));
            Return;
		EndIf;
	EndIf;
	AllClientsBirthdayCongratulationAddJobCommandPart();
EndProcedure

&AtClient
Procedure AllClientsBirthdayCongratulationAddJobCommandEnd(Schedule, AdditionalParameters) Export
	
	vResult = AdditionalParameters.vResult;
	vScheduleDlg = AdditionalParameters.vScheduleDlg;
	
	
	If Schedule <> Undefined Then
		vResult.Schedule = vScheduleDlg.Schedule;
		UpdateJob(vResult, True);
	Else
		ShowMessageBox(,NStr("en='User have canceled operation!';ru='Действие отменено пользователем!';de='Aktion vom Nutzer abgebrochen!'"));
		UpdateJob(vResult, False);
		AllClientsBirthdayCongratulation = False;
	EndIf;
	
	AllClientsBirthdayCongratulationAddJobCommandPart();

EndProcedure

&AtClient
Procedure AllClientsBirthdayCongratulationAddJobCommandPart()
	
	SetFormAppearance();

EndProcedure // AllClientsBirthdayCongratulationCommand

// -------------------------------------------------------------------------
&AtClient
Procedure InHouseGuestsBirthdayCongratulationOnChange(pItem)
	If Not InHouseGuestsBirthdayCongratulation Then
		SwitchOffBackgroundJob(InHouseGuestsBirthdayCongratulation, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "InHouseGuestsBirthdayCongratulation"), InHouseGuestsBirthdayCongratulationDeliveryFilter);
	Else
		SwitchOnBackgroundJob(InHouseGuestsBirthdayCongratulation, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "InHouseGuestsBirthdayCongratulation"), InHouseGuestsBirthdayCongratulationDeliveryFilter);
	EndIf;
	SetFormAppearance();
EndProcedure // InHouseGuestsBirthdayCongratulationOnChange

// -------------------------------------------------------------------------
&AtClient
Procedure InHouseGuestsFolioBalanceNotificationOnChange(Item)
	If Not InHouseGuestsFolioBalanceNotification Then
		SwitchOffBackgroundJob(InHouseGuestsFolioBalanceNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "InHouseGuestsFolioBalanceNotification"), InHouseGuestsFolioBalanceNotificationDeliveryFilter);
	Else
		SwitchOnBackgroundJob(InHouseGuestsFolioBalanceNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "InHouseGuestsFolioBalanceNotification"), InHouseGuestsFolioBalanceNotificationDeliveryFilter);
	EndIf;
	SetFormAppearance();
EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure ExpectedCheckOutGuestsFolioBalanceNotificationOnChange(Item)
	If Not ExpectedCheckOutGuestsFolioBalanceNotification Then
		SwitchOffBackgroundJob(ExpectedCheckOutGuestsFolioBalanceNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "ExpectedCheckOutGuestsFolioBalanceNotification"), ExpectedCheckOutGuestsFolioBalanceNotificationDeliveryFilter);
	Else
		SwitchOnBackgroundJob(ExpectedCheckOutGuestsFolioBalanceNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "ExpectedCheckOutGuestsFolioBalanceNotification"), ExpectedCheckOutGuestsFolioBalanceNotificationDeliveryFilter);
	EndIf;
	SetFormAppearance();
EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure ExpectedCheckInGuestsNotificationOnChange(Item)
	If Not ExpectedCheckInGuestsNotification Then
		SwitchOffBackgroundJob(ExpectedCheckInGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "ExpectedCheckInGuestsNotification"), ExpectedCheckInGuestsNotificationDeliveryFilter);
	Else
		SwitchOnBackgroundJob(ExpectedCheckInGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "ExpectedCheckInGuestsNotification"), ExpectedCheckInGuestsNotificationDeliveryFilter);
	EndIf;
	SetFormAppearance();
EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure CheckedInGuestsNotificationOnChange(Item)
	If Not CheckedInGuestsNotification Then
		SwitchOffBackgroundJob(CheckedInGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "CheckedInGuestsNotification"), CheckedInGuestsNotificationDeliveryFilter);
	Else
		SwitchOnBackgroundJob(CheckedInGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "CheckedInGuestsNotification"), CheckedInGuestsNotificationDeliveryFilter);
	EndIf;
	SetFormAppearance();
EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure InHouseGuestsNotificationOnChange(Item)
	If Not InHouseGuestsNotification Then
		SwitchOffBackgroundJob(InHouseGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "InHouseGuestsNotification"), InHouseGuestsNotificationDeliveryFilter);
	Else
		SwitchOnBackgroundJob(InHouseGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "InHouseGuestsNotification"), InHouseGuestsNotificationDeliveryFilter);
	EndIf;
	SetFormAppearance();
EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure ExpectedCheckOutGuestsNotificationOnChange(Item)
	If Not ExpectedCheckOutGuestsNotification Then
		SwitchOffBackgroundJob(ExpectedCheckOutGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "ExpectedCheckOutGuestsNotification"), ExpectedCheckOutGuestsNotificationDeliveryFilter);
	Else
		SwitchOnBackgroundJob(ExpectedCheckOutGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "ExpectedCheckOutGuestsNotification"), ExpectedCheckOutGuestsNotificationDeliveryFilter);
	EndIf;
	SetFormAppearance();
EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure CheckedOutGuestsNotificationOnChange(Item)
	If Not CheckedOutGuestsNotification Then
		SwitchOffBackgroundJob(CheckedOutGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "CheckedOutGuestsNotification"), CheckedOutGuestsNotificationDeliveryFilter);
	Else
		SwitchOnBackgroundJob(CheckedOutGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "CheckedOutGuestsNotification"), CheckedOutGuestsNotificationDeliveryFilter);
	EndIf;
	SetFormAppearance();
EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure ExpiredInvoicesNotificationOnChange(Item)
	ExpiredInvoicesNotificationDeliveryType = tcOnServer.cmGetEnumItem("DeliveryTypes", "EMail");
	If Not ExpiredInvoicesNotification Then
		SwitchOffBackgroundJob(ExpiredInvoicesNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "ExpiredInvoicesNotification"), ExpiredInvoicesNotificationDeliveryFilter);
	Else
		SwitchOnBackgroundJob(ExpiredInvoicesNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "ExpiredInvoicesNotification"), ExpiredInvoicesNotificationDeliveryFilter);
	EndIf;
	SetFormAppearance();
EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure AllClientsBirthdayCongratulationOnChange(pItem)
	If Not AllClientsBirthdayCongratulation Then
		SwitchOffBackgroundJob(AllClientsBirthdayCongratulation, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "AllClientsBirthdayCongratulation"), AllClientsBirthdayCongratulationDeliveryFilter, AllClientsBirthdayCongratulationNumberOfDays);
	Else
		SwitchOnBackgroundJob(AllClientsBirthdayCongratulation, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "AllClientsBirthdayCongratulation"), AllClientsBirthdayCongratulationDeliveryFilter, AllClientsBirthdayCongratulationNumberOfDays);
	EndIf;
	SetFormAppearance();
EndProcedure // AllClientsBirthdayCongratulationOnChange

// -------------------------------------------------------------------------
&AtClient
Procedure CheckedInGuestsNotificationDeleteJobCommand(pCommand)
	DeleteBackgroundJob(CheckedInGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "CheckedInGuestsNotification"), CheckedInGuestsNotificationDeliveryFilter);
	SetFormAppearance();
EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure CheckedOutGuestsNotificationDeleteJobCommand(pCommand)
	DeleteBackgroundJob(CheckedOutGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "CheckedOutGuestsNotification"), CheckedOutGuestsNotificationDeliveryFilter);
	SetFormAppearance();
EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure ExpectedCheckInGuestsNotificationDeleteJobCommand(pCommand)
	DeleteBackgroundJob(ExpectedCheckInGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "ExpectedCheckInGuestsNotification"), ExpectedCheckInGuestsNotificationDeliveryFilter);
	SetFormAppearance();
EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure ExpectedCheckOutGuestsFolioBalanceNotificationDeleteJobCommand(pCommand)
	DeleteBackgroundJob(ExpectedCheckOutGuestsFolioBalanceNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "ExpectedCheckOutGuestsFolioBalanceNotification"), ExpectedCheckOutGuestsFolioBalanceNotificationDeliveryFilter);
	SetFormAppearance();
EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure ExpectedCheckOutGuestsNotificationDeleteJobCommand(pCommand)
	DeleteBackgroundJob(ExpectedCheckOutGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "ExpectedCheckOutGuestsNotification"), ExpectedCheckOutGuestsNotificationDeliveryFilter);
	SetFormAppearance();
EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure ExpiredInvoicesNotificationDeleteJobCommand(pCommand)
	DeleteBackgroundJob(ExpiredInvoicesNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "ExpiredInvoicesNotification"), ExpiredInvoicesNotificationDeliveryFilter);
	SetFormAppearance();
EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure InHouseGuestsBirthdayCongratulationDeleteJobCommand(pCommand)
	DeleteBackgroundJob(InHouseGuestsBirthdayCongratulation, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "InHouseGuestsBirthdayCongratulation"), InHouseGuestsBirthdayCongratulationDeliveryFilter);
	SetFormAppearance();
EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure InHouseGuestsFolioBalanceNotificationDeleteJobCommand(pCommand)
	DeleteBackgroundJob(InHouseGuestsFolioBalanceNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "InHouseGuestsFolioBalanceNotification"), InHouseGuestsFolioBalanceNotificationDeliveryFilter);
	SetFormAppearance();
EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure InHouseGuestsNotificationDeleteJobCommand(pCommand)
	DeleteBackgroundJob(InHouseGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "InHouseGuestsNotification"), InHouseGuestsNotificationDeliveryFilter);
	SetFormAppearance();
EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure AllClientsBirthdayCongratulationDeleteJobCommand(pCommand)
	DeleteBackgroundJob(AllClientsBirthdayCongratulation, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "AllClientsBirthdayCongratulation"), AllClientsBirthdayCongratulationDeliveryFilter, AllClientsBirthdayCongratulationNumberOfDays);
	SetFormAppearance();
EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure AfterCheckOutGuestsNotificationOnChange(pItem)
	If Not AfterCheckOutGuestsNotification Then
		SwitchOffBackgroundJob(AfterCheckOutGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "AfterCheckOutGuestsNotification"), AfterCheckOutGuestsNotificationDeliveryFilter, AfterCheckOutGuestsNotificationNumberOfDays);
	Else
		SwitchOnBackgroundJob(AfterCheckOutGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "AfterCheckOutGuestsNotification"), AfterCheckOutGuestsNotificationDeliveryFilter, AfterCheckOutGuestsNotificationNumberOfDays);
	EndIf;
	SetFormAppearance();
EndProcedure // AfterCheckOutGuestsNotificationOnChange

// -------------------------------------------------------------------------
&AtClient
Procedure AfterCheckOutGuestsNotificationAddJobCommand(pCommand)
	If SetBackgroundJob(AfterCheckOutGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "AfterCheckOutGuestsNotification"), AfterCheckOutGuestsNotificationDeliveryType, AfterCheckOutGuestsNotificationDeliveryFilter, AfterCheckOutGuestsNotificationMessageTemplate, NStr("en = 'After check-out guests notification'; de = 'Benachrichtigung der Gäste nach dem Check-out'; ru = 'Уведомление гостей после выезда'"), AfterCheckOutGuestsNotificationNumberOfDays) Then
		vResult = ScheduleBackgroundJob(AfterCheckOutGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "AfterCheckOutGuestsNotification"), AfterCheckOutGuestsNotificationDeliveryType, AfterCheckOutGuestsNotificationDeliveryFilter, AfterCheckOutGuestsNotificationMessageTemplate, AfterCheckOutGuestsNotificationNumberOfDays);
		If TypeOf(vResult) = Type("String") Then
			ShowMessageBox(,vResult);
		ElsIf TypeOf(vResult) = Type("Structure") Then
			vScheduleDlg = New ScheduledJobDialog(vResult.Schedule);
			vScheduleDlg.Show(New NotifyDescription("AfterCheckOutGuestsNotificationAddJobCommandEnd", ThisObject, New Structure("vResult, vScheduleDlg", vResult, vScheduleDlg)));
            Return;
		EndIf;
	EndIf;
	AfterCheckOutGuestsNotificationAddJobCommandPart();
EndProcedure // AfterCheckOutGuestsNotificationAddJobCommand

// -------------------------------------------------------------------------
&AtClient
Procedure AfterCheckOutGuestsNotificationAddJobCommandEnd(Schedule, AdditionalParameters) Export
	
	vResult = AdditionalParameters.vResult;
	vScheduleDlg = AdditionalParameters.vScheduleDlg;
	
	
	If Schedule <> Undefined Then
		vResult.Schedule = vScheduleDlg.Schedule;
		UpdateJob(vResult, True);
	Else
		ShowMessageBox(,NStr("en='User have canceled operation!';ru='Действие отменено пользователем!';de='Aktion vom Nutzer abgebrochen!'"));
		UpdateJob(vResult, False);
		AfterCheckOutGuestsNotification = False;
	EndIf;
	
	AfterCheckOutGuestsNotificationAddJobCommandPart();

EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure AfterCheckOutGuestsNotificationAddJobCommandPart()
	
	SetFormAppearance();

EndProcedure // AfterCheckOutGuestsNotificationAddJobCommandPart

// -------------------------------------------------------------------------
&AtClient
Procedure AfterCheckOutGuestsNotificationDeleteJobCommand(pCommand)
	DeleteBackgroundJob(AfterCheckOutGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "AfterCheckOutGuestsNotification"), AfterCheckOutGuestsNotificationDeliveryFilter, AfterCheckOutGuestsNotificationNumberOfDays);
	SetFormAppearance();
EndProcedure // AfterCheckOutGuestsNotificationDeleteJobCommand

// -------------------------------------------------------------------------
&AtClient
Procedure BeforeCheckInGuestsNotificationOnChange(pItem)
	If Not BeforeCheckInGuestsNotification Then
		SwitchOffBackgroundJob(BeforeCheckInGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "BeforeCheckInGuestsNotification"), BeforeCheckInGuestsNotificationDeliveryFilter, BeforeCheckInGuestsNotificationNumberOfDays);
	Else
		SwitchOnBackgroundJob(BeforeCheckInGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "BeforeCheckInGuestsNotification"), BeforeCheckInGuestsNotificationDeliveryFilter, BeforeCheckInGuestsNotificationNumberOfDays);
	EndIf;
	SetFormAppearance();	
EndProcedure // BeforeCheckInGuestsNotificationOnChange

// -------------------------------------------------------------------------
&AtClient
Procedure BeforeCheckInGuestsNotificationAddJobCommand(pCommand)
	If SetBackgroundJob(BeforeCheckInGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "BeforeCheckInGuestsNotification"), BeforeCheckInGuestsNotificationDeliveryType, BeforeCheckInGuestsNotificationDeliveryFilter, BeforeCheckInGuestsNotificationMessageTemplate, NStr("en = 'Before check-in guests notification'; de = 'Benachrichtigung der Gäste vor dem Check-in'; ru = 'Уведомление гостей до заезда'"), BeforeCheckInGuestsNotificationNumberOfDays) Then
		vResult = ScheduleBackgroundJob(BeforeCheckInGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "BeforeCheckInGuestsNotification"), BeforeCheckInGuestsNotificationDeliveryType, BeforeCheckInGuestsNotificationDeliveryFilter, BeforeCheckInGuestsNotificationMessageTemplate, BeforeCheckInGuestsNotificationNumberOfDays);
		If TypeOf(vResult) = Type("String") Then
			ShowMessageBox(,vResult);
		ElsIf TypeOf(vResult) = Type("Structure") Then
			vScheduleDlg = New ScheduledJobDialog(vResult.Schedule);
			vScheduleDlg.Show(New NotifyDescription("BeforeCheckInGuestsNotificationAddJobCommandEnd", ThisObject, New Structure("vResult, vScheduleDlg", vResult, vScheduleDlg)));
            Return;
		EndIf;
	EndIf;
	BeforeCheckInGuestsNotificationAddJobCommandPart();
EndProcedure // BeforeCheckInGuestsNotificationAddJobCommand

// -------------------------------------------------------------------------
&AtClient
Procedure BeforeCheckInGuestsNotificationAddJobCommandEnd(Schedule, AdditionalParameters) Export
	
	vResult = AdditionalParameters.vResult;
	vScheduleDlg = AdditionalParameters.vScheduleDlg;
	
	If Schedule <> Undefined Then
		vResult.Schedule = vScheduleDlg.Schedule;
		UpdateJob(vResult, True);
	Else
		ShowMessageBox(,NStr("en='User have canceled operation!';ru='Действие отменено пользователем!';de='Aktion vom Nutzer abgebrochen!'"));
		UpdateJob(vResult, False);
		BeforeCheckInGuestsNotification = False;
	EndIf;
	
	BeforeCheckInGuestsNotificationAddJobCommandPart();

EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure BeforeCheckInGuestsNotificationAddJobCommandPart()
	
	SetFormAppearance();

EndProcedure // AfterCheckOutGuestsNotificationAddJobCommandPart

// -------------------------------------------------------------------------
&AtClient
Procedure BeforeCheckInGuestsNotificationDeleteJobCommand(pCommand)
	DeleteBackgroundJob(BeforeCheckInGuestsNotification, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "BeforeCheckInGuestsNotification"), BeforeCheckInGuestsNotificationDeliveryFilter, BeforeCheckInGuestsNotificationNumberOfDays);
	SetFormAppearance();
EndProcedure // BeforeCheckInGuestsNotificationDeleteJobCommand

// -------------------------------------------------------------------------
&AtClient
Procedure AllClientsImportantDateCongratulationOnChange1(pItem)
	If Not AllClientsImportantDateCongratulation1 Then
		SwitchOffBackgroundJob(AllClientsImportantDateCongratulation1, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "AllClientsImportantDatesCongratulation"), AllClientsImportantDateCongratulationDeliveryFilter1, AllClientsImportantDateCongratulationNumberOfDays1, AllClientsImportantDateCongratulationImportantDateType1);
	Else
		SwitchOnBackgroundJob(AllClientsImportantDateCongratulation1, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "AllClientsImportantDatesCongratulation"), AllClientsImportantDateCongratulationDeliveryFilter1, AllClientsImportantDateCongratulationNumberOfDays1, AllClientsImportantDateCongratulationImportantDateType1);
	EndIf;
	SetFormAppearance();
EndProcedure // AllClientsImportantDatesCongratulationOnChange1

// -------------------------------------------------------------------------
&AtClient
Procedure AllClientsImportantDateCongratulationAddJobButton1(pCommand)
	If SetBackgroundJob(AllClientsImportantDateCongratulation1, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "AllClientsImportantDatesCongratulation"), AllClientsImportantDateCongratulationDeliveryType1, AllClientsImportantDateCongratulationDeliveryFilter1, Undefined, NStr("en='Important date congratulation for clients in database: ';ru='Поздравление с важной датой по всей клиентской базе: ';de='Gratulationen zu einem wichtigen Datum für alle Kunden: '") + TrimAll(AllClientsImportantDateCongratulationImportantDateType1), AllClientsImportantDateCongratulationNumberOfDays1, AllClientsImportantDateCongratulationImportantDateType1) Then
		vResult = ScheduleBackgroundJob(AllClientsImportantDateCongratulation1, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "AllClientsImportantDatesCongratulation"), AllClientsImportantDateCongratulationDeliveryType1, AllClientsImportantDateCongratulationDeliveryFilter1, Undefined, AllClientsImportantDateCongratulationNumberOfDays1, AllClientsImportantDateCongratulationImportantDateType1);
		If TypeOf(vResult) = Type("String") Then
			ShowMessageBox(,vResult);
		ElsIf TypeOf(vResult) = Type("Structure") Then
			vScheduleDlg = New ScheduledJobDialog(vResult.Schedule);
			vScheduleDlg.Show(New NotifyDescription("AllClientsImportantDateCongratulationAddJobCommandEnd1", ThisObject, New Structure("vResult, vScheduleDlg", vResult, vScheduleDlg)));
            Return;
		EndIf;
	EndIf;
	AllClientsImportantDateCongratulationAddJobCommandPart1();
EndProcedure // AllClientsImportantDateCongratulationAddJobButton

// -------------------------------------------------------------------------
&AtClient
Procedure AllClientsImportantDateCongratulationAddJobCommandEnd1(Schedule, AdditionalParameters) Export
	
	vResult = AdditionalParameters.vResult;
	vScheduleDlg = AdditionalParameters.vScheduleDlg;
	
	
	If Schedule <> Undefined Then
		vResult.Schedule = vScheduleDlg.Schedule;
		UpdateJob(vResult, True);
	Else
		ShowMessageBox(,NStr("en='User have canceled operation!';ru='Действие отменено пользователем!';de='Aktion vom Nutzer abgebrochen!'"));
		UpdateJob(vResult, False);
		AllClientsImportantDateCongratulation1 = False;
	EndIf;
	
	AllClientsImportantDateCongratulationAddJobCommandPart1();

EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure AllClientsImportantDateCongratulationAddJobCommandPart1()
	
	SetFormAppearance();

EndProcedure // AllClientsImportantDateCongratulationAddJobCommandPart1

// -------------------------------------------------------------------------
&AtClient
Procedure AllClientsImportantDateCongratulationDeleteJobButton1(pCommand)
	DeleteBackgroundJob(AllClientsImportantDateCongratulation1, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "AllClientsImportantDatesCongratulation"), AllClientsImportantDateCongratulationDeliveryFilter1, AllClientsImportantDateCongratulationNumberOfDays1, AllClientsImportantDateCongratulationImportantDateType1);
	SetFormAppearance();
EndProcedure // AllClientsImportantDateCongratulationDeleteJobButton1

// -------------------------------------------------------------------------
&AtClient
Procedure AllClientsImportantDateCongratulationImportantDateTypeOnChange1(pItem)
	SetFormAppearance();
EndProcedure // AllClientsImportantDateCongratulationImportantDateTypeOnChange1

// -------------------------------------------------------------------------
&AtClient
Procedure AllClientsImportantDateCongratulationOnChange2(pItem)
	If Not AllClientsImportantDateCongratulation2 Then
		SwitchOffBackgroundJob(AllClientsImportantDateCongratulation2, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "AllClientsImportantDatesCongratulation"), AllClientsImportantDateCongratulationDeliveryFilter2, AllClientsImportantDateCongratulationNumberOfDays2, AllClientsImportantDateCongratulationImportantDateType2);
	Else
		SwitchOnBackgroundJob(AllClientsImportantDateCongratulation2, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "AllClientsImportantDatesCongratulation"), AllClientsImportantDateCongratulationDeliveryFilter2, AllClientsImportantDateCongratulationNumberOfDays2, AllClientsImportantDateCongratulationImportantDateType2);
	EndIf;
	SetFormAppearance();
EndProcedure // AllClientsImportantDatesCongratulationOnChange2

// -------------------------------------------------------------------------
&AtClient
Procedure AllClientsImportantDateCongratulationAddJobButton2(pCommand)
	If SetBackgroundJob(AllClientsImportantDateCongratulation2, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "AllClientsImportantDatesCongratulation"), AllClientsImportantDateCongratulationDeliveryType2, AllClientsImportantDateCongratulationDeliveryFilter2, Undefined, NStr("en='Important date congratulation for clients in database: ';ru='Поздравление с важной датой по всей клиентской базе: ';de='Gratulationen zu einem wichtigen Datum für alle Kunden: '") + TrimAll(AllClientsImportantDateCongratulationImportantDateType2), AllClientsImportantDateCongratulationNumberOfDays2, AllClientsImportantDateCongratulationImportantDateType2) Then
		vResult = ScheduleBackgroundJob(AllClientsImportantDateCongratulation2, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "AllClientsImportantDatesCongratulation"), AllClientsImportantDateCongratulationDeliveryType2, AllClientsImportantDateCongratulationDeliveryFilter2, Undefined, AllClientsImportantDateCongratulationNumberOfDays2, AllClientsImportantDateCongratulationImportantDateType2);
		If TypeOf(vResult) = Type("String") Then
			ShowMessageBox(,vResult);
		ElsIf TypeOf(vResult) = Type("Structure") Then
			vScheduleDlg = New ScheduledJobDialog(vResult.Schedule);
			vScheduleDlg.Show(New NotifyDescription("AllClientsImportantDateCongratulationAddJobCommandEnd2", ThisObject, New Structure("vResult, vScheduleDlg", vResult, vScheduleDlg)));
            Return;
		EndIf;
	EndIf;
	AllClientsImportantDateCongratulationAddJobCommandPart2();
EndProcedure // AllClientsImportantDateCongratulationAddJobButton2

// -------------------------------------------------------------------------
&AtClient
Procedure AllClientsImportantDateCongratulationAddJobCommandEnd2(Schedule, AdditionalParameters) Export
	
	vResult = AdditionalParameters.vResult;
	vScheduleDlg = AdditionalParameters.vScheduleDlg;
	
	
	If Schedule <> Undefined Then
		vResult.Schedule = vScheduleDlg.Schedule;
		UpdateJob(vResult, True);
	Else
		ShowMessageBox(,NStr("en='User have canceled operation!';ru='Действие отменено пользователем!';de='Aktion vom Nutzer abgebrochen!'"));
		UpdateJob(vResult, False);
		AllClientsImportantDateCongratulation2 = False;
	EndIf;
	
	AllClientsImportantDateCongratulationAddJobCommandPart2();

EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure AllClientsImportantDateCongratulationAddJobCommandPart2()
	
	SetFormAppearance();

EndProcedure // AllClientsImportantDateCongratulationAddJobCommandPart2

// -------------------------------------------------------------------------
&AtClient
Procedure AllClientsImportantDateCongratulationDeleteJobButton2(pCommand)
	DeleteBackgroundJob(AllClientsImportantDateCongratulation2, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "AllClientsImportantDatesCongratulation"), AllClientsImportantDateCongratulationDeliveryFilter2, AllClientsImportantDateCongratulationNumberOfDays2, AllClientsImportantDateCongratulationImportantDateType2);
	SetFormAppearance();
EndProcedure // AllClientsImportantDateCongratulationDeleteJobButton2

// -------------------------------------------------------------------------
&AtClient
Procedure AllClientsImportantDateCongratulationImportantDateTypeOnChange2(pItem)
	SetFormAppearance();
EndProcedure // AllClientsImportantDateCongratulationImportantDateTypeOnChange2

// -------------------------------------------------------------------------
&AtClient
Procedure AllClientsImportantDateCongratulationOnChange3(pItem)
	If Not AllClientsImportantDateCongratulation3 Then
		SwitchOffBackgroundJob(AllClientsImportantDateCongratulation3, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "AllClientsImportantDatesCongratulation"), AllClientsImportantDateCongratulationDeliveryFilter3, AllClientsImportantDateCongratulationNumberOfDays3, AllClientsImportantDateCongratulationImportantDateType3);
	Else
		SwitchOnBackgroundJob(AllClientsImportantDateCongratulation3, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "AllClientsImportantDatesCongratulation"), AllClientsImportantDateCongratulationDeliveryFilter3, AllClientsImportantDateCongratulationNumberOfDays3, AllClientsImportantDateCongratulationImportantDateType3);
	EndIf;
	SetFormAppearance();
EndProcedure // AllClientsImportantDatesCongratulationOnChange3

// -------------------------------------------------------------------------
&AtClient
Procedure AllClientsImportantDateCongratulationAddJobButton3(pCommand)
	If SetBackgroundJob(AllClientsImportantDateCongratulation3, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "AllClientsImportantDatesCongratulation"), AllClientsImportantDateCongratulationDeliveryType3, AllClientsImportantDateCongratulationDeliveryFilter3, Undefined, NStr("en='Important date congratulation for clients in database: ';ru='Поздравление с важной датой по всей клиентской базе: ';de='Gratulationen zu einem wichtigen Datum für alle Kunden: '") + TrimAll(AllClientsImportantDateCongratulationImportantDateType3), AllClientsImportantDateCongratulationNumberOfDays3, AllClientsImportantDateCongratulationImportantDateType3) Then
		vResult = ScheduleBackgroundJob(AllClientsImportantDateCongratulation3, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "AllClientsImportantDatesCongratulation"), AllClientsImportantDateCongratulationDeliveryType3, AllClientsImportantDateCongratulationDeliveryFilter3, Undefined, AllClientsImportantDateCongratulationNumberOfDays3, AllClientsImportantDateCongratulationImportantDateType3);
		If TypeOf(vResult) = Type("String") Then
			ShowMessageBox(,vResult);
		ElsIf TypeOf(vResult) = Type("Structure") Then
			vScheduleDlg = New ScheduledJobDialog(vResult.Schedule);
			vScheduleDlg.Show(New NotifyDescription("AllClientsImportantDateCongratulationAddJobCommandEnd3", ThisObject, New Structure("vResult, vScheduleDlg", vResult, vScheduleDlg)));
            Return;
		EndIf;
	EndIf;
	AllClientsImportantDateCongratulationAddJobCommandPart3();
EndProcedure // AllClientsImportantDateCongratulationAddJobButton3

// -------------------------------------------------------------------------
&AtClient
Procedure AllClientsImportantDateCongratulationAddJobCommandEnd3(Schedule, AdditionalParameters) Export
	
	vResult = AdditionalParameters.vResult;
	vScheduleDlg = AdditionalParameters.vScheduleDlg;
	
	
	If Schedule <> Undefined Then
		vResult.Schedule = vScheduleDlg.Schedule;
		UpdateJob(vResult, True);
	Else
		ShowMessageBox(,NStr("en='User have canceled operation!';ru='Действие отменено пользователем!';de='Aktion vom Nutzer abgebrochen!'"));
		UpdateJob(vResult, False);
		AllClientsImportantDateCongratulation3 = False;
	EndIf;
	
	AllClientsImportantDateCongratulationAddJobCommandPart3();

EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure AllClientsImportantDateCongratulationAddJobCommandPart3()
	
	SetFormAppearance();

EndProcedure // AllClientsImportantDateCongratulationAddJobCommandPart3

// -------------------------------------------------------------------------
&AtClient
Procedure AllClientsImportantDateCongratulationDeleteJobButton3(pCommand)
	DeleteBackgroundJob(AllClientsImportantDateCongratulation3, tcOnServer.cmGetEnumItem("AutoDeliveryTemplates", "AllClientsImportantDatesCongratulation"), AllClientsImportantDateCongratulationDeliveryFilter3, AllClientsImportantDateCongratulationNumberOfDays3, AllClientsImportantDateCongratulationImportantDateType3);
	SetFormAppearance();
EndProcedure // AllClientsImportantDateCongratulationDeleteJobButton3

// -------------------------------------------------------------------------
&AtClient
Procedure AllClientsImportantDateCongratulationImportantDateTypeOnChange3(pItem)
	SetFormAppearance();
EndProcedure // AllClientsImportantDateCongratulationImportantDateTypeOnChange3
