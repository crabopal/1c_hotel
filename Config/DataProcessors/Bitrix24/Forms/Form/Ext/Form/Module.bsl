
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Load DP parameters
	Obj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If ThisForm.Parameters.Property("DataProcessor", vDataProcessor) Then
		Obj.DataProcessor = vDataProcessor;
	Else
		vDataProcessor = Catalogs.DataProcessors.FindByAttribute("Processing","Bitrix24");
		If vDataProcessor = Catalogs.DataProcessors.EmptyRef() Then
			vNewDP 				= Catalogs.DataProcessors.CreateItem();
			vNewDP.Description 	= "Bitrix24";
			vNewDP.Key 			= "Bitrix24";
			vNewDP.Processing 	= "Bitrix24";
			vNewDP.Write();
			vDataProcessor = vNewDP.Ref;
		EndIf;
		
		Obj.DataProcessor = vDataProcessor;
	EndIf;

	vInteractionParameters = Catalogs.ExternalSystemInteractions.EmptyRef();
	If Parameters.Property("InteractionParameters", vInteractionParameters) Then
		Obj.InteractionParameters = vInteractionParameters;
	EndIf;
	Obj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(Obj,"Object");
	
	LoadInteractionParameters();
	LoadData();
		
	If Not ValueIsFilled(HTTPServer) Then
		HttpPort 			= 443;
		HTTPUseSSL 			= True;
		Object.EventsMode 	= "offline";
	EndIf;
	
	EventsModeOnChange_AtServer();
	
	If IsInRoleAtServer("Administrator") And vDataProcessor <> Undefined Then
		If IsBlankString(vDataProcessor.Key) Then
			dpObj = vDataProcessor.GetObject();
			dpObj.Key = "Bitrix24";
			dpObj.Write();
		EndIf;	
		SetupBackgroundJobSchedule_AtServer(True);
		
		If UseBackgroundJob Then
			Items.Text_BackgroundJobInfo.Title = NStr("en='Background job is configured and started'; ru='Фоновое задание настроено и запущено'; de='Ein Hintergrundjob ist konfiguriert und läuft'");
		Else 
			Items.Text_BackgroundJobInfo.Title = NStr("en='Background job not started'; ru='Фоновое задание не запущено'; de='Ein Hintergrundjob nicht läuft'");
		EndIf;
	Else
		Items.MainPages_BackgroundJob.Visible = False;
		tcCommonFunctionOnClientServer.TextMessage("en='You do not have rights to configure background job!'; ru='Нет прав для настройки фонового задания!'; de='Einen Hintergrundjob Einstellung ist nicht zulässig!'");
	EndIf;      	
	vBitrix24ExtraSetting = Catalogs.DataProcessors.Bitrix24ExtraSetting;
	If ValueIsFilled(vBitrix24ExtraSetting) And Not vBitrix24ExtraSetting.DeletionMark And ValueIsFilled(vBitrix24ExtraSetting.Processing) Then
		Items.FormExtraSetting.Visible = True;	
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure FillCheckProcessingAtServer(pCancel, pCheckedAttributes)
	If Object.EventsMode = "online" Then
		pCheckedAttributes.Add("WebhookURL");
	Else
		vFound = pCheckedAttributes.Find("WebhookURL");
		If vFound <> Undefined Then
			pCheckedAttributes.Delete(vFound);
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure DebugOnChange(pItem)
	If Debug Then
		Active = True;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ActiveOnChange(pItem)
	If Not Active Then
		Debug = False;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure UseBackgroundJobOnChange(pItem)
	If ValueIsFilled(Employee) Then
		If Object.Schedule <> Undefined Then
			If UseBackgroundJob Then
				If Not IsInRoleAtServer("Administrator") Then
					Raise(NStr("en='A background job should be configured by administrator only!';ru='Фоновое задание может настроить только системный администратор!';de='Ein Hintergrundjob kann der Administrator konfigurieren!'"));
				EndIf;
				Items.Text_BackgroundJobInfo.Title = NStr("en='Background job is configured and started'; ru='Фоновое задание настроено и запущено'; de='Ein Hintergrundjob ist konfiguriert und läuft'");
			Else 
				Items.Text_BackgroundJobInfo.Title = NStr("en='Background job is configured but not started'; ru='Фоновое задание настроено, но не запущено'; de='Ein Hintergrundjob ist konfiguriert, aber nicht läuft'");
			EndIf;
			If Not Object.Schedule = Undefined Then
				If Save_AtServer() Then
					If Not EventsBounded Then
						BoundEventsForClients();
						EventsBounded = True;
					EndIf;
					SetupBackgroundJobSchedule_AtServer();
				EndIf;
			EndIf;
		Else
			UseBackgroundJob = False;
			Raise(NStr("en='Schedule not setuped!';ru='Не настроено расписание!';"));
		EndIf;
	Else 
		UseBackgroundJob = False;
		Raise(NStr("en='User is not selected!';ru='Не выбран пользователь!';de='Nicht Benutzer sind gewählt!'"));
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure EventsModeOnChange(pItem)
	EventsModeOnChange_AtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure WebhookURLOnChange(pItem)
	EventsBounded = False;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure WSHostStartChoice(pItem, pChoiceData, pStandardProcessing)
	WSHost = GetInfoBaseURL(); 
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure DealsStatusesNameStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vCurData = Items.DealsStatuses.CurrentData;
	If DealsStatusesList.Count() > 0 And vCurData <> Undefined And TypeOf(vCurData.Status) <> Type("String") Then
		ShowChooseFromList(New NotifyDescription("AfterDealsStatusesNameStartChoice", ThisForm, vCurData), DealsStatusesList, pItem, DealsStatusesList.FindByValue(vCurData.id));
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure AfterDealsStatusesNameStartChoice(pItem, pCurData) Export 
	If pItem <> Undefined Then
		pCurData.id = pItem.Value;
		pCurData.Name = pItem.Presentation;
		pCurData.Check = False;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure DealsStatusesNameClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
	vCurData = Items.DealsStatuses.CurrentData;
	If vCurData <> Undefined Then
		vCurData.id = "";
		vCurData.Name = "";
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure DealsStatusesSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	vCurData = Items.DealsStatuses.CurrentData;
	If vCurData = Undefined Then
		pStandardProcessing = False;
	Else
		If TypeOf(vCurData.Status) = Type("String") Then
			pStandardProcessing = False;
		EndIf;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure GroupTypeOnChange(pItem)
	DealsStatuses.GetItems().Clear();
	FillDealsStatuses();
	GetDealStatusesAtServer();
	LoadDealStatusesTable();
	For Each vLoadedDealStatusParentRow In DealsStatuses.GetItems() Do
		Items.DealsStatuses.Expand(vLoadedDealStatusParentRow.GetID());
	EndDo;
	FillDoNotUnloadGroupType();
EndProcedure // GroupTypeOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure DealCategoryOnChange(pItem)
	DealsStatuses.GetItems().Clear();
	FillDealsStatuses();
	GetDealStatusesAtServer();
	LoadDealStatusesTable(DealCategory);
	For Each vLoadedDealStatusParentRow In DealsStatuses.GetItems() Do
		Items.DealsStatuses.Expand(vLoadedDealStatusParentRow.GetID());
	EndDo;
EndProcedure // DealCategoryOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure SyncCustomersOnChange(pItem)
	BoundEventsForClients();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure InteractionParametersOnChange(pItem)
	LoadInteractionParameters();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure HTTPServerOnChange(pItem)
	
	CheckHTTPAddress();
	
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure FieldsForClientsTableBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)

	Cancel	=	True;

	NewRow	=	FieldsForClientsTable.Add();
	NewRow.IsUserField	=	True;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure FieldsForClientsTableBeforeDeleteRow(Item, Cancel)
	Cancel		=	True;

	curData		=	Items.FieldsForClientsTable.CurrentData;

	If curData = Undefined Then
		Return;
	EndIf;

	If curData.IsUserField Then
		curData.IsDeleted	= Not curData.IsDeleted;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure FieldsForClientsTableFormLabelOnChange(Item)
	curData		=	Items.FieldsForClientsTable.CurrentData;

	If curData = Undefined Then
		Return;
	EndIf;

	curValue	=	curData.FormLabel;
	DescItem	=	Items.FieldsForClientsTableAttribute1C;

	If Not IsBlankString(curValue) And IsBlankString(curData.Attribute1C) And DescItem.ChoiceList.FindByValue(curValue) <> Undefined Then
		curData.Attribute1C	=	curValue;
		FieldsForClientsTableAttribute1COnChange(DescItem);
	EndIf;
	curData.IsModified	=	True;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure FieldsForClientsTableAttribute1COnChange(Item)

	CurrentData	=	Items.FieldsForClientsTable.CurrentData;

	If CurrentData <> Undefined Then

		ListItem	=	Items.FieldsForClientsTableAttribute1C.ChoiceList.FindByValue(CurrentData.Attribute1C);

		If ListItem <> Undefined Then
			CurrentData.DataPath	=	StrSplit(ListItem.Presentation, ".")[0];
		EndIf;
	EndIf;

	// Delete another row.
	For Each SecondRowData In FieldsForClientsTable.FindRows( New Structure("Attribute1C, AttributeB24", CurrentData.Attribute1C, "") ) Do

		If SecondRowData <> CurrentData Then
			FieldsForClientsTable.Delete(SecondRowData);
		EndIf;
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure FieldsForClientsTableTypeOnChange(Item)
	curData		=	Items.FieldsForClientsTable.CurrentData;

	If curData = Undefined Then
		Return;
	EndIf;

	curData.IsModified	=	True;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure FieldsForCustomersTableBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	Cancel	=	True;

	NewRow	=	FieldsForCustomersTable.Add();
	NewRow.IsUserField	=	True;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure FieldsForCustomersTableBeforeDeleteRow(Item, Cancel)
	
	Cancel		=	True;

	curData		=	Items.FieldsForCustomersTable.CurrentData;

	If curData = Undefined Then
		Return;
	EndIf;

	If curData.IsUserField Then
		curData.IsDeleted	=	Not curData.IsDeleted;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure FieldsForCustomersTableFormLabelOnChange(Item)
	
	curData		=	Items.FieldsForCustomersTable.CurrentData;

	If curData = Undefined Then
		Return;
	EndIf;

	curValue	=	curData.FormLabel;
	DescItem	=	Items.FieldsForCustomersTableAttribute1C;

	If Not IsBlankString(curValue) And IsBlankString(curData.Attribute1C) And DescItem.ChoiceList.FindByValue(curValue) <> Undefined Then
		curData.Attribute1C	=	curValue;
		FieldsForCustomersTableAttribute1COnChange(DescItem);
	EndIf;
	curData.IsModified	=	True;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure FieldsForCustomersTableAttribute1COnChange(Item)
	
	CurrentData	=	Items.FieldsForCustomersTable.CurrentData;

	If CurrentData <> Undefined Then
		ListItem	=	Items.FieldsForCustomersTableAttribute1C.ChoiceList.FindByValue(CurrentData.Attribute1C);
		If ListItem <> Undefined Then
			CurrentData.DataPath	=	StrSplit(ListItem.Presentation, ".")[0];
		EndIf;
	EndIf;

	// Delete another row.
	For Each SecondRowData In FieldsForCustomersTable.FindRows( New Structure("Attribute1C, AttributeB24", CurrentData.Attribute1C, "") ) Do
		If SecondRowData <> CurrentData Then
			FieldsForCustomersTable.Delete(SecondRowData);
		EndIf;
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure FieldsForCustomersTableTypeOnChange(Item)
	curData		=	Items.FieldsForCustomersTable.CurrentData;
	If curData = Undefined Then
		Return;
	EndIf;
	curData.IsModified	=	True;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure FieldsForDealsTableBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	Cancel	=	True;

	NewRow	=	FieldsForDealsTable.Add();
	NewRow.IsUserField	=	True;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure FieldsForDealsTableBeforeDeleteRow(Item, Cancel)
	Cancel		=	True;
	curData		=	Items.FieldsForDealsTable.CurrentData;
	If curData = Undefined Then
		Return;
	EndIf;

	If curData.IsUserField Then
		curData.IsDeleted	= Not curData.IsDeleted;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure FieldsForDealsTableFormLabelOnChange(Item)
	
	curData		=	Items.FieldsForDealsTable.CurrentData;

	If curData = Undefined Then
		Return;
	EndIf;

	curValue	=	curData.FormLabel;
	DescItem	=	Items.FieldsForDealsTableAttribute1C;

	If Not IsBlankString(curValue) And IsBlankString(curData.Attribute1C) And DescItem.ChoiceList.FindByValue(curValue) <> Undefined Then
		curData.Attribute1C	=	curValue;
		FieldsForDealsTableAttribute1COnChange(DescItem);
	EndIf;
	curData.IsModified	=	True;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure FieldsForDealsTableAttribute1COnChange(Item)
	
	CurrentData	=	Items.FieldsForDealsTable.CurrentData;

	If CurrentData <> Undefined Then
		ListItem = Items.FieldsForDealsTableAttribute1C.ChoiceList.FindByValue(CurrentData.Attribute1C);
		If ListItem <> Undefined Then
			CurrentData.DataPath = StrSplit(ListItem.Presentation, ".")[0];
		EndIf;
	EndIf;

	// Delete another row.
	For Each SecondRowData In FieldsForDealsTable.FindRows( New Structure("Attribute1C, AttributeB24", CurrentData.Attribute1C, "") ) Do
		If SecondRowData <> CurrentData Then
			FieldsForDealsTable.Delete(SecondRowData);
		EndIf;
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure FieldsForDealsTableTypeOnChange(Item)
	curData	= Items.FieldsForDealsTable.CurrentData;
	If curData = Undefined Then
		Return;
	EndIf;
	curData.IsModified	=	True;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ConnectionTest(pCommand)
	If Save_AtServer() Then
		
		vColors = GetFormItemsColors();
		vConnProps 	= Bitrix24.GetConnectionProps(Object.InteractionParameters);
		vResult 	= Bitrix24.RefreshAccessTokenB24(vConnProps);
		If vResult = True Then
			Items.Username.BackColor 	= vColors.Success;
			Items.Password.BackColor 	= vColors.Success;
			Items.HTTPServer.BackColor 	= vColors.Success;

			vUserMsg 		= New UserMessage;
			vUserMsg.Text 	= NStr("en = 'Successful connection!'; de = 'Erfolgreiche Verbindung!'; ru = 'Успешное подключение!'");
			vUserMsg.Field	= "Ping";
			vUserMsg.Message();	
		Else
			Items.Username.BackColor 	= vColors.Failure;
			Items.Password.BackColor 	= vColors.Failure;				
			Items.HTTPServer.BackColor 	= vColors.Failure;
			
			vMsg = NStr("en = 'Failed to connect to the server'; 
						|de = 'Verbindung zum Server fehlgeschlagen'; 
						|ru = 'Не удалось подключиться к серверу или токен авторизации был просрочен'"); 
			vUserMsg 		= New UserMessage;
			vUserMsg.Text 	= vMsg;
			vUserMsg.Field	= "Ping";
			vUserMsg.Message();
		EndIf;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure Save(pCommand)
	Save_AtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SetupBackgroundJobSchedule(pCommand)
	If ValueIsFilled(Employee)  Then
		If Not IsInRoleAtServer("Administrator") Then
			Raise(NStr("en='A background job can be configured by system administrator only!';
						|ru='Фоновое задание может настроить только системный администратор!';
						|de='Ein Hintergrundjob kann der Administrator konfigurieren!'"));
		Else 				
			vScheduleDlg = New ScheduledJobDialog(Object.Schedule);
			vScheduleDlg.Show(New NotifyDescription("SetupBackgroundJobSchedule_AfterInput", ThisForm, New Structure()));		
		EndIf;
	Else 
		Raise(NStr("en='User is not selected!';ru='Не выбран пользователь!';de='Nicht Benutzer sind gewählt!'"));
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ReloadData(pCommand)
	If Save_AtServer() Then
		LoadData();
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ExportClients(pCommand)
	If Not Save_AtServer() Then
		Return;
	EndIf;
	
	ExportClients_AtServer();
EndProcedure // ExportClients

// --------------------------------------------------------------------------------
&AtClient
Procedure ExportCustomers(pCommand)
	If Not Save_AtServer() Then
		Return;
	EndIf;
	
	ExportCustomers_AtServer();
EndProcedure // ExportCustomers

// --------------------------------------------------------------------------------
&AtClient
Procedure ExportDeals(pCommand)
	If Not Save_AtServer() Then
		Return;
	EndIf;
	
	ExportDeals_AtServer();
EndProcedure // ExportDeals

// --------------------------------------------------------------------------------
&AtClient
Procedure ImportClients(pCommand)
	ImportClients_AtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ImportCustomers(pCommand)
	ImportCustomers_AtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ExportTasks(pCommand)
	ExportTasks_AtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ImportAllClients(pCommand)
	If Save_AtServer() Then
		ClientsFound = Bitrix24.GetClientsCount(Object.InteractionParameters);
		
		Items.ManualSync_Sync.Enabled 		= False;
		Items.ManualSync_Loading.Visible 	= True;
		
		BackgroundJobProgress	= 0;
		ClientsProcessed		= 0;
		StartImportData("Clients");
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ImportAllCustomers(pCommand)
	If Save_AtServer() Then
		ClientsFound = Bitrix24.GetClientsCount(Object.InteractionParameters);
		
		Items.ManualSync_Sync.Enabled 		= False;
		Items.ManualSync_Loading.Visible 	= True;
		
		BackgroundJobProgress	= 0;
		ClientsProcessed		= 0;
		StartImportData("Customers");
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure GetClientsCount(pCommand)
	GetClientsCount_AtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure CreateAndUpdateTags(pCommand)
	CreateAndUpdateTags_AtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure DeleteUnusedTags(pCommand)
	DeleteUnusedTags_AtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ExportDealsFromCheckInDate(pCommand)
	If Not Save_AtServer() Then
		Return;
	EndIf;
	
	If (Not ValueIsFilled(DealsCheckInFrom) And Not ValueIsFilled(DealsCheckInTo)) Or DealsCheckInFrom > DealsCheckInTo Then
		tcCommonFunctionOnClientServer.TextMessage(Nstr("en = 'Fill in the deals check-in period'; de = 'Füllen Sie den Check-in-Zeitraum für die Angebote aus'; ru = 'Заполните период заезда сделок'"));
		Return;
	EndIf;
	
	ExportDealsFromCheckInDate_AtServer();
EndProcedure // ExportDealsFromCheckInDate

// --------------------------------------------------------------------------------
&AtClient
Procedure DealStatusesSave(pCommand)
	SaveDealStatusesTable();
	SaveDoNotUnloadGroupType();
EndProcedure // DealStatusesSave

// --------------------------------------------------------------------------------
&AtClient
Procedure GetDealHotelID(pCommand)
	If Not IsBlankString(DealID) Then
		GetDealHotelID_AtServer();
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Deal ID not specified'; de = 'Deal-ID nicht angegeben'; ru = 'Не указан ID сделки'"), , "DealID");		
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ExtraSetting(pCommand)
	vNameDataProcessor = GetNameDataProcessor();
	If vNameDataProcessor <> Undefined Then
		OpenForm(vNameDataProcessor, New Structure("InteractionParameters", Object.InteractionParameters), ThisObject,,,,, FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure // ExtraSetting

// --------------------------------------------------------------------------------
&AtClient
Procedure CreateClientsExtraFields(pCommand)
	vExtraFields = GetClientsExtraFields();	
	If vExtraFields.Count() > 0 Then
		vNotifyDescription = New NotifyDescription("AfterCheckByClientsExtraFields", ThisForm);
		vParams = New Structure("ValueList, MultipleChoice, Title", vExtraFields, True, NStr("en = 'Select extra fields'; de = 'Wählen Sie zusätzliche Felder aus'; ru = 'Выберите дополнительные поля'"));
		OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID,,, vNotifyDescription, FormWindowOpeningMode.LockOwnerWindow);
	EndIf;	
EndProcedure // CreateClientsExtraFields

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtClient
Procedure AfterCheckByClientsExtraFields(pExtraFields, pExtraParams) Export 
	If pExtraFields <> Undefined Then
		AddClientsExtraFields(pExtraFields);
	EndIf;
EndProcedure // AfterCheckByClientsExtraFields

// --------------------------------------------------------------------------------
&AtServer
Procedure AddClientsExtraFields(pExtraFields) 
	For Each vExtraField In pExtraFields Do
		If vExtraField.Check Then
			vExtraFieldData = vExtraField.Value;
			If vExtraFieldData <> Undefined Then
				vNewRow = FieldsForClientsTable.Add();
				vNewRow.IsUserField = True;
				vNewRow.FormLabel = StrReplace(vExtraFieldData.FIELD_NAME, "UF_CRM_", "");
				vNewRow.Type = vExtraFieldData.USER_TYPE_ID;
				vNewRow.AttributeB24 = vExtraFieldData.FIELD_NAME;
				vNewRow.ID = Bitrix24.UpdateUserFieldForClients(Object.InteractionParameters,,, vExtraFieldData)
			EndIf;
		EndIf;
	EndDo;
	SaveFieldsDataAtServer(Undefined, "Clients");
	FillClientFieldsTable();
	LoadListOfFields(False, "Clients");
EndProcedure // AfterCheckByClientsExtraFields

// -----------------------------------------------------------------------------
&AtServer
Function GetClientsExtraFields()
	Return Bitrix24.GetClientsExtraFields(FieldsForClientsTable);	
EndFunction // GetClientsExtraFields 

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetNameDataProcessor()
	Return Catalogs.DataProcessors.GetNameDataProcessorByProcessing(Catalogs.DataProcessors.Bitrix24ExtraSetting);	
EndFunction //  GetNameDataProcessor

// --------------------------------------------------------------------------------
&AtClient
Procedure SetupBackgroundJobSchedule_AfterInput(pValue, pParametrs) Export
	If pValue <> Undefined Then
		Object.Schedule = pValue;
	EndIf;
	
	SetupBackgroundJobSchedule_AtServer();
	
	If UseBackgroundJob Then
		Items.Text_BackgroundJobInfo.Title = NStr("en='Background job is configured and started'; ru='Фоновое задание настроено и запущено'; de='Ein Hintergrundjob ist konfiguriert und läuft'");
	Else 
		Items.Text_BackgroundJobInfo.Title = NStr("en='Background job is configured but not started'; ru='Фоновое задание настроено, но не запущено'; de='Ein Hintergrundjob ist konfiguriert, aber nicht läuft'");
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure ExportClients_AtServer()
	vEndSessionTime = Undefined;
	If SessionTimeout > 0 Then
		vDurationMiliSeconds = SessionTimeout * 60 * 1000;
		vStartTime = CurrentUniversalDateInMilliseconds();
		vEndSessionTime =vStartTime + vDurationMiliSeconds;
	EndIf;
	
	vResult = Bitrix24.ExportData(Object.InteractionParameters, Undefined, , "Clients", , , vEndSessionTime);
	tcCommonFunctionOnClientServer.TextMessage(vResult);
EndProcedure // ExportClients_AtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure ExportCustomers_AtServer()
	vEndSessionTime = Undefined;
	If SessionTimeout > 0 Then
		vDurationMiliSeconds = SessionTimeout * 60 * 1000;
		vStartTime = CurrentUniversalDateInMilliseconds();
		vEndSessionTime =vStartTime + vDurationMiliSeconds;
	EndIf;
	
	vResult = Bitrix24.ExportData(Object.InteractionParameters, Undefined, , "Customers", , , vEndSessionTime);
	tcCommonFunctionOnClientServer.TextMessage(vResult);
EndProcedure // ExportCustomers_AtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure ExportDeals_AtServer()
	vEndSessionTime = Undefined;
	If SessionTimeout > 0 Then
		vDurationMiliSeconds = SessionTimeout * 60 * 1000;
		vStartTime = CurrentUniversalDateInMilliseconds();
		vEndSessionTime =vStartTime + vDurationMiliSeconds;
	EndIf;
	
	vResult = Bitrix24.ExportData(Object.InteractionParameters, Undefined, , "Deals", , , , vEndSessionTime);
	tcCommonFunctionOnClientServer.TextMessage(vResult);
EndProcedure // ExportDeals_AtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure ImportClients_AtServer()
	If Save_AtServer() Then	
		vResult = Bitrix24.ImportData(Object.InteractionParameters, Undefined,,, "Clients");
		tcCommonFunctionOnClientServer.TextMessage(vResult.Message);
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure ImportCustomers_AtServer()
	If Save_AtServer() Then	
		vResult = Bitrix24.ImportData(Object.InteractionParameters, Undefined,,, "Customers");
		tcCommonFunctionOnClientServer.TextMessage(vResult.Message);	
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure ExportTasks_AtServer()
	If Save_AtServer() Then
		Bitrix24.SyncTasks(Object.InteractionParameters);
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure EventsModeOnChange_AtServer()
	EventsBounded = False;
	If Object.EventsMode = "online" Then
		Items.WebhookURL.Visible = True;
	Else
		Items.WebhookURL.Visible = False;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure GetClientsCount_AtServer()
	If Save_AtServer() Then
		ClientsFound = Bitrix24.GetClientsCount(Object.InteractionParameters);
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure CreateAndUpdateTags_AtServer()
	
	vResult = Bitrix24.CreateAndUpdateTags(Object.InteractionParameters);
	
	If vResult Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Success'; de = 'Erfolgreich'; ru = 'Успешно'"));
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Tag update error'; de = 'Tag-Aktualisierungsfehler'; ru = 'Ошибка обновление тегов'"));	
	EndIf;
	
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure ExportDealsFromCheckInDate_AtServer()
	vEndSessionTime = Undefined;
	If SessionTimeout > 0 Then
		vDurationMiliSeconds = SessionTimeout * 60 * 1000;
		vStartTime = CurrentUniversalDateInMilliseconds();
		vEndSessionTime =vStartTime + vDurationMiliSeconds;
	EndIf;
	
	vResult = Bitrix24.ExportData(Object.InteractionParameters, Undefined, , "Deals", DealsCheckInFrom, DealsCheckInTo, vEndSessionTime, , DealUnmappedOnly);
	tcCommonFunctionOnClientServer.TextMessage(vResult);
EndProcedure // ExportDealsFromCheckInDate_AtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure DeleteUnusedTags_AtServer()
	Bitrix24.ClearUnusedTagsInBitrix(Object.InteractionParameters);
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure GetDealHotelID_AtServer()
	HotelID = Bitrix24.GetBitrix24DealField(Object.InteractionParameters, DealID, HotelFiledInDeals);
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Function Save_AtServer()
	
	If Not  CheckFilling() Then
		Return False;
	EndIf;
	
	CheckHTTPAddress();
	
	BeginTransaction();
	
	Try
		SaveInteractionParameters();
		SaveClientTypeTable();
		SaveCompanyTypesTable();
		SaveCompanyIndustriesTable();
		SaveDealStatusesTable();
		SaveDealHotelsTable();
		SaveDoNotUnloadTransactionsByBusinessBlock();
		
		
		If FieldsForClientsTable.Count() > 0 Then
			SaveFieldsDataAtServer(Undefined, "Clients");
		EndIf;
		
		If FieldsForCustomersTable.Count() > 0 Then
			SaveFieldsDataAtServer(Undefined, "Customers");
		EndIf;

		If FieldsForDealsTable.Count() > 0 Then
			SaveFieldsDataAtServer(Undefined, "Deals");
		EndIf;

		// Save DP parameters
		Obj = FormAttributeToValue("Object");
		Obj.pmSaveDataProcessorAttributes();
	Except
		RollbackTransaction();
		vError = ErrorDescription();
		tcCommonFunctionOnClientServer.TextMessage(vError);
		Return False;
	EndTry;

	CommitTransaction();
	
	Return True;
EndFunction

// --------------------------------------------------------------------------------
&AtServer
Procedure LoadData()
	
	FillClientFieldsTable();
	LoadListOfFields(False, "Clients");
	
	ClientTypes.Clear();
	GetClientTypesAtServer();
	LoadClientTypeTable();
	
	FillCustomerFieldsTable();
	LoadListOfFields(False, "Customers");

	CustomerTypes.Clear();
	GetCompanyTypesAtServer();
	LoadCompanyTypesTable();
	
	CustomerIndustries.Clear();
	GetCompanyIndustriesAtServer();
	LoadCompanyIndustriesTable();
	
	FillDealsFieldsTable();
	LoadListOfFields(False, "Deals");
	DealsStatuses.GetItems().Clear();
	FillDealsStatuses();
	GetDealsCategoryAtServer();
	GetDealStatusesAtServer();
	LoadDealStatusesTable();
	FillDoNotUnloadGroupType();
	LoadDealHotelsTable();
	LoadDoNotUnloadTransactionsByBusinessBlock();
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveFieldsDataAtServer(LogDataContainer, pDataType)

	var ApiConnection, ApiConnectionProps;

	If pDataType = "Customers" Then
		vTable = FieldsForCustomersTable;
	ElsIf  pDataType = "Clients" Then
		vTable = FieldsForClientsTable;
	ElsIf  pDataType = "Deals" Then
		vTable = FieldsForDealsTable;
	Else
		Return;
	EndIf;
		
	// Delete dublicates if exist
	vClearArray = New Array;
	For Each vRow In vTable Do
		vFirstRow = False;
		For Each vSecondRow In vTable Do
			If vRow.AttributeB24 = vSecondRow.AttributeB24 Then
				If vFirstRow Then
					If ValueIsFilled(vRow.Attribute1C) And ValueIsFilled(vRow.DataPath) Then
						If vClearArray.Find(vSecondRow) = Undefined Then
							vClearArray.Add(vSecondRow);
						EndIf;
					Else
						If vClearArray.Find(vRow) = Undefined Then
							vClearArray.Add(vRow);
						EndIf;	
					EndIf;
				Else
					vFirstRow = True;
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	For Each vRow In vClearArray Do
		vTable.Delete(vRow);
	EndDo;
	
	// 01. Get update userfields.
	CountOfFields =	vTable.Count();
	objClient =	Undefined; // Need to get type of attribute;

	For i=1 To CountOfFields Do
		TableRow = vTable[CountOfFields-i];

		If TableRow.IsUserField = False Then
			Continue;
		EndIf;

		// ADD NEW USERFIELD.
		If Not ValueIsFilled(TableRow.ID) And TableRow.IsUserField Then

			If IsBlankString(TableRow.Attribute1C) Then
				Continue;
			EndIf;

			// Init type of new field.
			UserTypeId = TableRow.Type;

			If IsBlankString(UserTypeId) And (StrCompare(TableRow.DataPath, "Clients") = 0 Or StrCompare(TableRow.DataPath, "Customers") Or StrCompare(TableRow.DataPath, "Deals")) Then
				If objClient = Undefined Then
					If pDataType = "Customers" Then
						objClient	=	Catalogs.Customers.CreateItem();	
					ElsIf pDataType = "Clients" Then
						objClient	=	Catalogs.Clients.CreateItem();
					ElsIf pDataType = "Deals" Then
						objClient	=	Catalogs.GuestGroups.CreateItem();
					EndIf;
					objClient.SetNewCode();
				EndIf;

				TypeOfAttr	=	TypeOf(objClient[TableRow.Attribute1C]);

				If TypeOfAttr = Type("Number") Then
					UserTypeId	=	"number";
				ElsIf TypeOfAttr = Type("Date") Then
					UserTypeId	=	"date";
				ElsIf TypeOfAttr = Type("Boolean") Then
					UserTypeId	=	"boolean";
				EndIf;
			EndIf;

			// Add new field.
			UserTypeId	=	?(IsBlankString(UserTypeId), "string", UserTypeId);
			FieldName	=	"UF_CRM_" + Прав(Формат(ТекущаяУниверсальнаяДатаВМиллисекундах(),"ЧГ=0"),13);
			FieldData	=	New Structure("ID, EDIT_FORM_LABEL, FIELD_NAME, USER_TYPE_ID", TableRow.ID, TableRow.FormLabel, FieldName, UserTypeId);

			TableRow.ID	=	Bitrix24.UpdateUserFieldForClients(Object.InteractionParameters, ApiConnection, ApiConnectionProps, FieldData, LogDataContainer);

			If ValueIsFilled(TableRow.ID) Then
				TableRow.AttributeB24	=	FieldName;
			EndIf;
			TableRow.IsModified	=	False;
		EndIf;


		// DELETE USERFIELD OR UNBOUND PREDEFINED.
		If TableRow.IsDeleted = True Then

			If Not ValueIsFilled(TableRow.ID) Or Not TableRow.IsUserfield Then

				TableRow.IsSet			=	False;

				TableRow.Attribute1C	=	"";
				TableRow.DataPath		=	"";

				Continue; 
			ElsIf ValueIsFilled(TableRow.ID) Or Not TableRow.IsUserfield Then
				FieldData = New Structure("ID", TableRow.ID);
				Bitrix24.UpdateUserFieldForClients(Object.InteractionParameters, ApiConnection, ApiConnectionProps, FieldData, LogDataContainer, True);	
			EndIf;
		EndIf;

		// MODIFY USERFIELD.
		If TableRow.IsModified = True And TableRow.IsUserField Then

			FieldData	=	New Structure("ID, EDIT_FORM_LABEL, USER_TYPE_ID", TableRow.ID, TableRow.FormLabel, TableRow.Type);
			Result		=	Bitrix24.UpdateUserFieldForClients(Object.InteractionParameters, ApiConnection, ApiConnectionProps, FieldData, LogDataContainer);

			If Result = True Then
				TableRow.IsModified	=	False;
				TableRow.IsDeleted	=	False;
			EndIf;
		EndIf;
	EndDo;

	// 02. Set isSet item value to save data in Info Reg.
	CheckForSetsAtServer(vTable);
	
	// 03. Write to 1C.
	ApiMethod	=	Bitrix24.GetApiMethod(pDataType, "", "Fields");	
	
	Query		=	New Query;
	Query.Text	=
	"SELECT
	|	vTable.AttributeB24 AS AttributeB24,
	|	vTable.Attribute1C AS Attribute1C,
	|	vTable.DataPath AS DataPath,
	|	vTable.Type AS Type
	|INTO tt_vTable
	|FROM
	|	&vTable AS vTable
	|WHERE
	|	vTable.ID > 0
	|	AND vTable.IsSet = TRUE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CAST(&SystemInfoRef AS Catalog.ExternalSystemInteractions).Hotel AS Hotel,
	|	CAST(&SystemInfoRef AS Catalog.ExternalSystemInteractions).HttpServer AS ExternalSystemCode,
	|	&ObjectTypeName AS ObjectTypeName,
	|	tt_vTable.AttributeB24 AS ObjectExternalCode,
	|	tt_vTable.Attribute1C AS ObjectDescription,
	|	tt_vTable.DataPath AS ObjectDataPath,
	|	tt_vTable.Type AS Type
	|FROM
	|	tt_vTable AS tt_vTable";

	Query.SetParameter("vTable",			vTable.Unload());
	Query.SetParameter("SystemInfoRef",		Object.InteractionParameters);
	Query.SetParameter("ObjectTypeName",	ApiMethod);

	QueryResult		=	Query.Execute();

	ResultTable		=	QueryResult.Unload();
	InfoRegSet		=	InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordSet();
	InfoRegSet.Load(ResultTable);

	If QueryResult.IsEmpty() Then
		InfoRegSet.Filter.Hotel.Set(Object.InteractionParameters.Hotel);
		InfoRegSet.Filter.ExternalSystemCode.Set(Object.InteractionParameters.HttpServer);
		InfoRegSet.Filter.ObjectTypeName.Set(ApiMethod);

	Else
		FirstLine	=	ResultTable[0];

		InfoRegSet.Filter.Hotel.Set(FirstLine.Hotel);
		InfoRegSet.Filter.ExternalSystemCode.Set(FirstLine.ExternalSystemCode);
		InfoRegSet.Filter.ObjectTypeName.Set(FirstLine.ObjectTypeName);
	EndIf;

	InfoRegSet.Write(True);
	RefreshReusableValues();

	// 04. Reload fields data.
	LoadListOfFields(True, pDataType);
EndProcedure //  SaveFieldsDataAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveInteractionParameters()
	
	If Not ValueIsFilled(Object.InteractionParameters) Then
		Return;
	EndIf;
	
	vIntParObj 									= Object.InteractionParameters.GetObject();
	vIntParObj.Login 							= Username;	
	vIntParObj.Password 						= Password;	
	vIntParObj.HttpServer 					= HTTPServer;
	vIntParObj.Hotel 							= Hotel;
	vIntParObj.IsActive 						= Active;
	vIntParObj.DebugMode 					= Debug;
	vIntParObj.HttpAddress 					= HTTPAddress;
	vIntParObj.HttpUseSsl 					= HTTPUseSSL;
	vIntParObj.WSHost 						= WSHost;
	vIntParObj.WebhookURL					= WebhookURL;
	vIntParObj.HttpPort 						= HttpPort;  
	vIntParObj.UseClient    					= UseClient;
	vIntParObj.LastFullSynchronizationTime	= LastFullSynchronizationTime;
	vIntParObj.SessionTimeout				= SessionTimeout;
	vIntParObj.URLShortener					= URLShortener;
	vIntParObj.Write();
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure LoadInteractionParameters()
	If Not ValueIsFilled(Object.InteractionParameters) Then
		Return;
	EndIf;
	
	vInteraction 					= Object.InteractionParameters;
	Username  						= vInteraction.Login;	
	Password  						= vInteraction.Password;	
	HTTPServer  					= vInteraction.HttpServer;
	Hotel  							= vInteraction.Hotel;
	Active  							= vInteraction.IsActive;
	Debug  							= vInteraction.DebugMode;
	HTTPAddress 					= vInteraction.HttpAddress;
	HTTPUseSSL  					= vInteraction.HttpUseSsl;
	WSHost						= vInteraction.WSHost;
	WebhookURL					= vInteraction.WebhookURL;
	HttpPort						= vInteraction.HttpPort;
	UseClient						= vInteraction.UseClient;
	LastFullSynchronizationTime	= vInteraction.LastFullSynchronizationTime;
	SessionTimeout				= vInteraction.SessionTimeout;
	URLShortener					= vInteraction.URLShortener;
EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure StartImportData(pDataType)
	CancelProlongedOperations();
	BackgroundJobsList.Clear();
	
	// Room statuses
	vProcedureParametrs 	= New Array;
	vTempStorageAdress 	 	= PutToTempStorage(Null, ThisForm.UUID);
	vProcedureParametrs.Add(Object.InteractionParameters);
	vProcedureParametrs.Add(True);
	vProcedureParametrs.Add(vTempStorageAdress);
	vProcedureParametrs.Add(pDataType);
	
	vBackgroundJob 		 	= StartBackgroundJob("Bitrix24.LoadAllData", vProcedureParametrs, vTempStorageAdress);
	
	vnewRow 				= BackgroundJobsList.Add();
	vnewRow.Name 		 	= "Bitrix24_LoadAllData_" + pDataType;
	vnewRow.UUID 		 	= vBackgroundJob.UUID;
	vnewRow.ResultAddress 	= vBackgroundJob.TempStorageAddress;
	vnewRow.Status 		 	= "Processing";
		
	AttachIdleHandler("CheckBackgroundJobs_AtClient", 5, False);
EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure CancelProlongedOperations(pName = "")
	DetachIdleHandler("CheckBackgroundJobs");
	For Each Job In BackgroundJobsList Do
		If ValueIsFilled(pName) Then
			If pName = Job.Name Then
				CancelBackgroundJob(Job.UUID);
			EndIf;
		Else
			CancelBackgroundJob(Job.UUID);
		EndIf;			
	EndDo;
EndProcedure

// -------------------------------------------------------------------------
&AtServer
Function StartBackgroundJob(pProcedureName, pProcedureParametrs, pTempStorageAddress = Undefined)
	Return AsyncCalls.StartBackgroundJob(pProcedureName, pProcedureParametrs,,,pTempStorageAddress);	
EndFunction

// -------------------------------------------------------------------------
&AtServer
Function CancelBackgroundJob(pBackgroundJobId)
	Return AsyncCalls.CancelBackgroundJob(pBackgroundJobId);	
EndFunction

// -------------------------------------------------------------------------
&AtClient
Procedure CheckBackgroundJobs_AtClient()
	vProcessing = CheckBackgroundJobs_AtServer();
	
	If Not vProcessing Then
		BackgroundJobsList.Clear();
		DetachIdleHandler("CheckBackgroundJobs_AtClient");
	EndIf;
EndProcedure	

// -------------------------------------------------------------------------
&AtServer
Function CheckBackgroundJobs_AtServer()
	vProcessing = False;
	For Each Job In BackgroundJobsList Do 
		If Job.Status = "Processing" Then
			vProcessing = True;
			vBackgroundJob 	= AsyncCalls.CheckBackgroundJob(Job.UUID, True);
			If vBackgroundJob <> Undefined Then 
				If vBackgroundJob.Status = "Processing" Then 
					Job.Status = "Processing"; 
					If vBackgroundJob.Messages.Count() > 0 Then
						ProcessBackgroundJobMessages(Job, vBackgroundJob.Messages);	
					EndIf;
				ElsIf vBackgroundJob.Status = "Error" Then 
					Job.Status = "Error";
					tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Error in background job: " + Job.Name + "'; ru = 'Ошибка выполнения фонового задания: " + Job.Name + "'"));		//#Translate			
				ElsIf vBackgroundJob.Status = "Canceled" Then 
					Job.Status = "Canceled";
					tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Background job: " + Job.Name + " - canceled.'; ru = 'Фоновое задание: " + Job.Name + " - отменено.'"));   		//#Translate
				ElsIf vBackgroundJob.Status = "Completed" Then 
					Job.Status = "Completed";
					ProcessBackgroundJob(Job);
				EndIf;
			Else
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Error in checking background job: " + Job.Name + "'; ru = 'Ошибка проверки фонового задания: " + Job.Name + "'"));	//#Translate	
			EndIf;
		EndIf;
	EndDo;
	
	Return vProcessing;
EndFunction

// -------------------------------------------------------------------------
&AtServer
Procedure ProcessBackgroundJob(pBackgroundJob)
	If pBackgroundJob.Name = "Bitrix24_LoadAllData_Clients" Then
		Items.ManualSync_Loading.Visible			= False;
		Items.Decoration_ClientsProcessed.Visible 	= True; 
		Items.ManualSync_Sync.Enabled 				= True;
		vResult = GetFromTempStorage(pBackgroundJob.ResultAddress);
		If vResult <> Undefined Then
			vResultStringArray 	=  New Array;
			vResultStringArray.Add(New FormattedString(NStr("en = 'Result:'; de = 'Result:'; ru = 'Результат:'") + Chars.LF, New Font(,12,True)));
			vResultStringArray.Add(NStr("en = 'Created clients:'; de = 'Created clients:'; ru = 'Создано клиентов в базе:      '"));
			vResultStringArray.Add(New FormattedString(String(vResult.Created) + Chars.LF, New Font(,10,True)));
			vResultStringArray.Add(NStr("en = 'Synced clients:'; de = 'Synced clients:'; ru = 'Синхронизировано клиентов: '"));
			vResultStringArray.Add(New FormattedString(String(vResult.Found) + Chars.LF, New Font(,10,True)));
			vResultStringArray.Add(NStr("en = 'Failed to import:'; de = 'Failed to import:'; ru = 'Не удалось импортировать:   '"));
			vResultStringArray.Add(New FormattedString(String(vResult.Failed), New Font(,10,True)));
			Items.Decoration_ClientsProcessed.Title = New FormattedString(vResultStringArray);
		Else
			Items.Decoration_ClientsProcessed.Title = NStr("en = 'Failed to recive result!'; de = 'Failed to recive result!'; ru = 'Не удалось получить результат!'");	
		EndIf;
	ElsIf  pBackgroundJob.Name = "Bitrix24_LoadAllData_Customers" Then 
		Items.ManualSync_Loading.Visible			= False;
		Items.Decoration_ClientsProcessed.Visible 	= True; 
		Items.ManualSync_Sync.Enabled 				= True;
		vResult = GetFromTempStorage(pBackgroundJob.ResultAddress);
		If vResult <> Undefined Then
			vResultStringArray 	=  New Array;
			vResultStringArray.Add(New FormattedString(NStr("en = 'Result:'; de = 'Result:'; ru = 'Результат:'") + Chars.LF, New Font(,12,True)));
			vResultStringArray.Add(NStr("en = 'Created customers:'; de = 'Created customers:'; ru = 'Создано контрагентов в базе:      '"));
			vResultStringArray.Add(New FormattedString(String(vResult.Created) + Chars.LF, New Font(,10,True)));
			vResultStringArray.Add(NStr("en = 'Synced customers:'; de = 'Synced customers:'; ru = 'Синхронизировано контрагентов: '"));
			vResultStringArray.Add(New FormattedString(String(vResult.Found) + Chars.LF, New Font(,10,True)));
			vResultStringArray.Add(NStr("en = 'Failed to import:'; de = 'Failed to import:'; ru = 'Не удалось импортировать:   '"));
			vResultStringArray.Add(New FormattedString(String(vResult.Failed), New Font(,10,True)));
			Items.Decoration_ClientsProcessed.Title = New FormattedString(vResultStringArray);
		Else
			Items.Decoration_ClientsProcessed.Title = NStr("en = 'Failed to recive result!'; de = 'Failed to recive result!'; ru = 'Не удалось получить результат!'");	
		EndIf;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure ProcessBackgroundJobMessages(pBackgroundJob, pMessages)
	
	If pBackgroundJob.Name = "Bitrix24_LoadAllClients" Then
		For Each vMessage In pMessages Do
			Try
				vMessageStructure 		= Catalogs.DataConvertationRules.JSONtoStructure(vMessage); 
				BackgroundJobProgress 	= vMessageStructure.Percent;
				ClientsProcessed 		= vMessageStructure.Count;
			Except
				Continue;
			EndTry;
		EndDo;	
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure CheckHTTPAddress()
	
	If StrFind(HTTPServer, "https://") > 0 Then
		HTTPUseSSL 	= True;
		HttpPort	= 443;
		HTTPServer = StrReplace(HTTPServer, "https://", "");
	ElsIf StrFind(HTTPServer, "http://") > 0 Then
		HTTPUseSSL 	= False;
		HttpPort	= 80;
		HTTPServer = StrReplace(HTTPServer, "http://", "");
	EndIf;
	
	vCharPos = StrFind(HTTPServer, ".ru");
	If vCharPos = 0 Then
		vCharPos = StrFind(HTTPServer, ".com");
	EndIf;
	
	If vCharPos = 0 Then
		Return;
	EndIf;
	 
	HTTPServer = Left(HTTPServer, vCharPos + 2);
EndProcedure

// --------------------------------------------------------------------------------
&AtClientAtServerNoContext
Function GetFormItemsColors()
	
	vResult = New Structure;
	
	vResult.Insert("Success", tcCommonFunctionOnClientServer.ColorConstructor(204, 255, 204));
	vResult.Insert("Failure", tcCommonFunctionOnClientServer.ColorConstructor(255, 204, 204));
                                  	
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
&AtServer
Function IsInRoleAtServer(pRole)
	Return tcOnServer.cmIsInRole(pRole);
EndFunction

// --------------------------------------------------------------------------------
&AtServer
Procedure SetupBackgroundJobSchedule_AtServer(pRead = False)
	If Not pRead Then 
		If Not CheckFilling() Then
			UseBackgroundJob = False;
		EndIf;
	EndIf;
	
	Try
		vSave = False;
		ArrayScheduledJob = ScheduledJobs.GetScheduledJobs(New Structure("Key",Object.DataProcessor.Key));
		
		If ArrayScheduledJob.Count() > 0 Then
			ScheduledJob = ArrayScheduledJob[0];
			
			If pRead Then
				Employee  				= cmGetEmployeeByUserName(ScheduledJob.UserName);
				Object.Schedule  		= ScheduledJob.Schedule;
				UseBackgroundJob  		= ScheduledJob.Use;	
			Else				
				vUserNames = cmGetUserUUIDsByEmployee(Employee);
				If vUserNames.Count() > 0 Then
					vUsrName = vUserNames[0].UserName;
				Else
					vMessage = NStr("en='The user of the information base was not found!';
									|ru='Пользователь информационной базы не найден!';
									|de='Der Benutzer der Informationsbasis wurde nicht gefunden!'");
					tcCommonFunctionOnClientServer.UserMessage(vMessage);
				Endif;
				
				ScheduledJob.UserName 	= vUsrName;
				ScheduledJob.Schedule 	= Object.Schedule;
				ScheduledJob.Use 		= UseBackgroundJob;
				vSave = True;
			EndIf;
			
			If ScheduledJob.Parameters.Count() = 0 Then
				ScheduledJob.Parameters.Add(Object.DataProcessor.Key);
				vSave = True;
			EndIf;
			
		Else 	
			For Each vScheduledJob In Metadata.ScheduledJobs Do   
				If vScheduledJob.Name = "RunDataProcessor" Then
					
					ScheduledJob = ScheduledJobs.CreateScheduledJob(vScheduledJob);
					
				EndIf;
			EndDo;
			
			vUserNames = cmGetUserUUIDsByEmployee(Employee);
			If vUserNames.Count() > 0 Then
				vUsrName = vUserNames[0].UserName;
			Else
				vMessage = NStr("en='The user of the information base was not found!';
								|ru='Пользователь информационной базы не найден!';
								|de='Der Benutzer der Informationsbasis wurde nicht gefunden!'");
				tcCommonFunctionOnClientServer.UserMessage(vMessage);
			Endif;
			
			ScheduledJob.Description 				= Object.DataProcessor.Description;
			ScheduledJob.Key 						= Object.DataProcessor.Key;
			ScheduledJob.Use 						= UseBackgroundJob;
			ScheduledJob.UserName 					= vUsrName;
			ScheduledJob.RestartCountOnFailure 		= 0;
			ScheduledJob.RestartIntervalOnFailure 	= 0;
			
			If Object.Schedule = Undefined Or pRead Then 
				Object.Schedule  					= ScheduledJob.Schedule;
			Else
				ScheduledJob.Schedule   			= Object.Schedule;
			EndIf;
			
			If ScheduledJob.Parameters.Count() = 0 Then
				ScheduledJob.Parameters.Add(Object.DataProcessor.Key);
			EndIf;
			vSave = True;
		EndIf;
		
		If vSave Then
			ScheduledJob.Write();
		EndIf;
	Except	
		tcCommonFunctionOnClientServer.TextMessage(ErrorDescription(), MessageStatus.Attention);	
	EndTry;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure FillClientFieldsTable()
	
	Items.FieldsForClientsTableDataPath.ChoiceList.Clear();
	Items.FieldsForClientsTableAttribute1C.ChoiceList.Clear();
	
	// Attributes liste of choice
	Items.FieldsForClientsTableAttribute1C.ListChoiceMode	=	True;
	Items.FieldsForClientsTableDataPath.ListChoiceMode		=	True;
	
	// Attributes liste of choice
	Items.FieldsForClientsTableDataPath.ChoiceList.Add("AdditionalInfo");
	Items.FieldsForClientsTableAttribute1C.ChoiceList.Add("DiscountCardType", "AdditionalInfo.Clients.DiscountCardType");
	
	Items.FieldsForClientsTableDataPath.ChoiceList.Add("cmGetClientStats()");
	FieldsStructureTemplate	=	cmGetClientStats(Undefined);

	For Each KeyValue In FieldsStructureTemplate Do
		Items.FieldsForClientsTableAttribute1C.ChoiceList.Add(KeyValue.Key, "cmGetClientStats()." + KeyValue.Key);
	EndDo;

	Items.FieldsForClientsTableDataPath.ChoiceList.Add("Clients");
	ListOfClAttr	=	GetClientAttributesAtServerNoContext();

	For Each ListItem In ListOfClAttr Do
		Items.FieldsForClientsTableAttribute1C.ChoiceList.Add(ListItem.Value, "Clients." + ListItem.Value);
	EndDo;

	Items.FieldsForClientsTableAttribute1C.ChoiceList.SortByPresentation();
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure FillCustomerFieldsTable()
	
	Items.FieldsForCustomersTableDataPath.ChoiceList.Clear();
	Items.FieldsForCustomersTableAttribute1C.ChoiceList.Clear();
	
	// Attributes liste of choice
	Items.FieldsForCustomersTableAttribute1C.ListChoiceMode	= True;
	Items.FieldsForCustomersTableDataPath.ListChoiceMode = True;
	
	Items.FieldsForCustomersTableDataPath.ChoiceList.Add("Customers");
	ListOfClAttr	=	GetCustomerAttributesAtServerNoContext();

	For Each ListItem In ListOfClAttr Do
		Items.FieldsForCustomersTableAttribute1C.ChoiceList.Add(ListItem.Value, "Customers." + ListItem.Value);
	EndDo;

	Items.FieldsForCustomersTableAttribute1C.ChoiceList.SortByPresentation();
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure FillDealsFieldsTable()
	
	Items.FieldsForDealsTableDataPath.ChoiceList.Clear();
	Items.FieldsForDealsTableAttribute1C.ChoiceList.Clear();
	
	// Attributes liste of choice
	Items.FieldsForDealsTableAttribute1C.ListChoiceMode	=	True;
	Items.FieldsForDealsTableDataPath.ListChoiceMode		=	True;
	
	Items.FieldsForDealsTableDataPath.ChoiceList.Add("GuestGroups");
	ListOfClAttr	=	GetGuestGroupAttributesAtServerNoContext();
	
	For Each ListItem In ListOfClAttr Do
		Items.FieldsForDealsTableAttribute1C.ChoiceList.Add(ListItem.Value, "GuestGroups." + ListItem.Value);
	EndDo;
	
	Items.FieldsForDealsTableDataPath.ChoiceList.Add("AdditionalInfo");
	Items.FieldsForDealsTableAttribute1C.ChoiceList.Add("ClientsList", 	"AdditionalInfo.ClientsList");
	Items.FieldsForDealsTableAttribute1C.ChoiceList.Add("Title", 		"AdditionalInfo.Title");
	Items.FieldsForDealsTableAttribute1C.ChoiceList.Add("utm_source", 	"AdditionalInfo.utm_source");
	Items.FieldsForDealsTableAttribute1C.ChoiceList.Add("utm_campaign", "AdditionalInfo.utm_campaign");
	Items.FieldsForDealsTableAttribute1C.ChoiceList.Add("utm_medium", 	"AdditionalInfo.utm_medium");
	Items.FieldsForDealsTableAttribute1C.ChoiceList.Add("utm_content", 	"AdditionalInfo.utm_content");
	Items.FieldsForDealsTableAttribute1C.ChoiceList.Add("Hotel","AdditionalInfo.Hotel");
	Items.FieldsForDealsTableAttribute1C.ChoiceList.Add("B24EmployeeID","AdditionalInfo.GuestGroups.B24EmployeeID");
	Items.FieldsForDealsTableAttribute1C.ChoiceList.Add("NumberOfAdults", "AdditionalInfo.GuestGroups.NumberOfAdults");
	Items.FieldsForDealsTableAttribute1C.ChoiceList.Add("NumberOfChildren", "AdditionalInfo.GuestGroups.NumberOfChildren");
	Items.FieldsForDealsTableAttribute1C.ChoiceList.Add("NumberOfTeenagers", "AdditionalInfo.GuestGroups.NumberOfTeenagers");
	Items.FieldsForDealsTableAttribute1C.ChoiceList.Add("NumberOfInfants", "AdditionalInfo.GuestGroups.NumberOfInfants");
	Items.FieldsForDealsTableAttribute1C.ChoiceList.Add("RoomsQuantity", "AdditionalInfo.GuestGroups.RoomsQuantity");
	Items.FieldsForDealsTableAttribute1C.ChoiceList.Add("ExternalRef", "AdditionalInfo.GuestGroups.ExternalRef");
	Items.FieldsForDealsTableAttribute1C.ChoiceList.Add("GuestGroupReservationLink", "AdditionalInfo.GuestGroups.GuestGroupReservationLink");
	Items.FieldsForDealsTableAttribute1C.ChoiceList.Add("GuestGroupBalance", "AdditionalInfo.GuestGroups.Balance");
	Items.FieldsForDealsTableAttribute1C.ChoiceList.Add("GuestGroupPayments", "AdditionalInfo.GuestGroups.Payments");
	Items.FieldsForDealsTableAttribute1C.ChoiceList.Add("GuestGroupReservationInfo", "AdditionalInfo.GuestGroups.ReservationInfo");
	Items.FieldsForDealsTableAttribute1C.ChoiceList.Add("GuestGroupDiscountType", "AdditionalInfo.GuestGroups.DiscountType");
	Items.FieldsForDealsTableAttribute1C.ChoiceList.Add("GuestGroupDiscountCardType", "AdditionalInfo.GuestGroups.DiscountCardType");
	Items.FieldsForDealsTableAttribute1C.ChoiceList.Add("IsCustomerPays", "AdditionalInfo.GuestGroups.IsCustomerPays");
	Items.FieldsForDealsTableAttribute1C.ChoiceList.Add("GuestGroupMarketingCode", "AdditionalInfo.GuestGroups.MarketingCode");
	Items.FieldsForDealsTableAttribute1C.ChoiceList.Add("GuestGroupRoomRate", "AdditionalInfo.GuestGroups.RoomRate");
	
	Items.FieldsForDealsTableAttribute1C.ChoiceList.SortByPresentation();
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure CheckForSetsAtServer(pTable)
	For Each TableRow In pTable Do
		TableRow.IsSet = ValueIsFilled(TableRow.Attribute1C) And ValueIsFilled(TableRow.AttributeB24);
	EndDo;
EndProcedure //  CheckFieldsForClientsTableForSetsAtServer()

// --------------------------------------------------------------------------------
&AtServer
Procedure FillDealsStatuses() 
	vQuery = New Query();
	vQuery.Text =
	"SELECT
	|	ReservationStatuses.Ref AS Status
	|FROM
	|	Catalog.ReservationStatuses AS ReservationStatuses
	|WHERE
	|	NOT ReservationStatuses.DeletionMark
	|	AND NOT ReservationStatuses.IsFolder
	|
	|ORDER BY
	|	ReservationStatuses.SortCode";
	vResult = vQuery.Execute().Unload();
	
	If vResult.Count() > 0 Then
		vNewParent = DealsStatuses.GetItems().Add();
		vNewParent.Status = NStr("en = 'Reservation statuses'; de = 'Status der Reservierung'; ru = 'Статусы брони'");
		
		For Each vRow In vResult Do
			vNewRow = vNewParent.GetItems().Add();
			FillPropertyValues(vNewRow, vRow); 
		EndDo;
	EndIf;
	
	vQuery = New Query();
	vQuery.Text =
	"SELECT
	|	AccommodationStatuses.Ref AS Status
	|FROM
	|	Catalog.AccommodationStatuses AS AccommodationStatuses
	|WHERE
	|	NOT AccommodationStatuses.DeletionMark
	|	AND NOT AccommodationStatuses.IsFolder
	|
	|ORDER BY
	|	AccommodationStatuses.SortCode";
	vResult = vQuery.Execute().Unload();
	
	If vResult.Count() > 0 Then
		vNewParent = DealsStatuses.GetItems().Add();
		vNewParent.Status = NStr("en = 'Accommodation statuses'; de = 'Status der Unterbringung der Gäste in Zimmern'; ru = 'Статусы размещения гостей в номерах'");
		
		For Each vRow In vResult Do
			vNewRow = vNewParent.GetItems().Add();
			FillPropertyValues(vNewRow, vRow); 
		EndDo;
	EndIf;
		
	vQuery = New Query();
	vQuery.Text =
	"SELECT
	|	ResourceReservationStatuses.Ref AS Status
	|FROM
	|	Catalog.ResourceReservationStatuses AS ResourceReservationStatuses
	|WHERE
	|	NOT ResourceReservationStatuses.DeletionMark
	|	AND NOT ResourceReservationStatuses.IsFolder
	|
	|ORDER BY
	|	ResourceReservationStatuses.SortCode";
	vResult = vQuery.Execute().Unload();
	
	If vResult.Count() > 0 Then
		vNewParent = DealsStatuses.GetItems().Add();
		vNewParent.Status = NStr("en = 'Resource reservation statuses'; de = 'Status der Ressourcenreservierung'; ru = 'Статусы брони ресурсов'");
		
		For Each vRow In vResult Do
			vNewRow = vNewParent.GetItems().Add();
			FillPropertyValues(vNewRow, vRow); 
		EndDo;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
//	Description: Imports fields for clients from Bitrix 24 and joins it with mapped codes in 1C.
&AtServer
Procedure LoadListOfFields(OnlyMapped, pDataType)

	var ApiConnection, ApiConnectionProps;

	If pDataType = "Customers" Then
		vTable 			= FieldsForCustomersTable;
		AttributesTable	= Bitrix24.CreateAttributesTableForCustomers(Object.InteractionParameters);
	ElsIf pDataType = "Clients" Then 
		vTable 			= FieldsForClientsTable;
		AttributesTable	= Bitrix24.CreateAttributesTableForClients(Object.InteractionParameters);
	ElsIf pDataType = "Deals" Then 
		vTable 			= FieldsForDealsTable;
		AttributesTable	= Bitrix24.CreateAttributesTableForDeals(Object.InteractionParameters);
	Else
		Return;
	EndIf;
	
	// 01. Get actual fields structure.
	vTable.Clear();
	vTable.Load(AttributesTable);

	// 02. Get Data from Bitrix 24.

	ALlFieldsData =	Bitrix24.GetFieldsForData(False, Object.InteractionParameters, ApiConnection, ApiConnectionProps, Undefined, pDataType);
	For Each SingleUserFieldData In ALlFieldsData Do

		If StrCompare(SingleUserFieldData.fieldName, "ID") = 0 Then
			Continue;
		EndIf;

		AllMatchsInTable	=	vTable.FindRows(New Structure("AttributeB24", SingleUserFieldData.FieldName));

		If AllMatchsInTable.Count() > 0 Then
			RowInTable		=	AllMatchsInTable[0];
		ElsIf OnlyMapped = False Then
			RowInTable				=	vTable.Add();
			RowInTable.AttributeB24	=	SingleUserFieldData.FieldName;
		Else
			Continue;
		EndIf;

		FillPropertyValues(RowInTable, SingleUserFieldData);

		If Not SingleUserFieldData.Property("FormLabel", RowInTable.FormLabel) Then

			strFieldName	=	Title(SingleUserFieldData.fieldName);
			strFieldName	=	StrReplace(strFieldName, "_", " ");

			RowInTable.FormLabel	=	strFieldName;
   		EndIf;
	EndDo;

	If pDataType = "Clients" Then
		MapClientFields();
	ElsIf pDataType = "Customers" Then
		MapCustomersFields();
	ElsIf pDataType = "Deals" Then
		MapDealsFields();	
	EndIf;

	// 03. Sort table.
	vTable.Sort("IsSet Desc, FormLabel");


	// 04. Set IDs for userfields.

	If vTable.FindRows( New Structure("IsUserField", True) ). Count() > 0 Then

		// Get userfields info from Bitrix.
		ApiMethod			= Bitrix24.GetApiMethod(pDataType, "Userfield", "List");

		RequestAnswer		= Bitrix24.ExecuteApiRequest(ApiConnection, ApiConnectionProps, ApiMethod,, Undefined,,, Object.InteractionParameters,,, "");
		ResultProperty		= Bitrix24.GetPropertyOfStructure(RequestAnswer, "result");

		If TypeOf(ResultProperty) = Type("Array") Then
			For Each UserFieldData In ResultProperty Do
				AllRowFound	=	vTable.FindRows( New Structure("AttributeB24", UserFieldData.FIELD_NAME) );
				If AllRowFound.Count() > 0 Then
					AllRowFound[0].ID	=	UserFieldData.ID;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
EndProcedure // LoadListOfFieldsForClientsAtServer()

// --------------------------------------------------------------------------------
//	Description: Gets attributes of Catalog.Clients methadata.
//	Returns: Value list of attributes names and path to it in Presentation property.
&AtServerNoContext
Function GetClientAttributesAtServerNoContext()

	ListOfAttributes	=	New ValueList;

	// Prefefined attaribute.
	ListOfAttributes.Add("Description");
	ListOfAttributes.Add("Code");

	For Each Attribute In Metadata.Catalogs.Clients.Attributes Do

		ListOfAttributes.Add(Attribute.Name);

	EndDo;

	ListOfAttributes.SortByValue();

	Return ListOfAttributes;
EndFunction // GetClientAttributesAtServerNoContext()

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetCustomerAttributesAtServerNoContext()
	ListOfAttributes	=	New ValueList;

	// Prefefined attaribute.
	ListOfAttributes.Add("Description");

	For Each Attribute In Metadata.Catalogs.Customers.Attributes Do
		ListOfAttributes.Add(Attribute.Name);
	EndDo;

	ListOfAttributes.SortByValue();

	Return ListOfAttributes;
EndFunction // GetCustomerAttributesAtServerNoContext()

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetGuestGroupAttributesAtServerNoContext()
	ListOfAttributes	=	New ValueList;

	// Prefefined attaribute.
	ListOfAttributes.Add("Description");
	ListOfAttributes.Add("Code");
	ListOfAttributes.Add("Owner");

	For Each Attribute In Metadata.Catalogs.GuestGroups.Attributes Do

		ListOfAttributes.Add(Attribute.Name);

	EndDo;
	
	ListOfAttributes.SortByValue();

	Return ListOfAttributes;
EndFunction // GetGuestGroupAttributesAtServerNoContext()

// --------------------------------------------------------------------------------
&AtServer
Function GetNewAccessTokenB24(pInteractionParameters, rLogDataContainer = Undefined, pAuthCode = Undefined)
	vConnProps = Bitrix24.GetConnectionProps(pInteractionParameters, rLogDataContainer);
	Return Bitrix24.GetNewAccessTokenB24(vConnProps, rLogDataContainer, pAuthCode);
EndFunction // GetNewAccessTokenB24

// --------------------------------------------------------------------------------
&AtServer
Procedure MapClientFields()
	vMappings = Bitrix24.GetClientsFieldsMapping();
	For Each vRow In FieldsForClientsTable Do
		If Not ValueIsFilled(vRow.Attribute1C) Then
			vMapping = vMappings.Find(vRow.AttributeB24, "Bitrix");
			If vMapping <> Undefined Then
				vRow.Attribute1C 	= vMapping.Hotel;
				vRow.DataPath 		= "Clients";
				vRow.IsSet			= True;
			EndIf;
		EndIf;
	EndDo;
EndProcedure // MapClientFields

// --------------------------------------------------------------------------------
&AtServer
Procedure MapDealsFields()
	vMappings = Bitrix24.GetDealsFieldsMapping();
	For Each vRow In FieldsForDealsTable Do
		If Not ValueIsFilled(vRow.Attribute1C) Then
			vMapping = vMappings.Find(vRow.AttributeB24, "Bitrix");
			If vMapping <> Undefined Then
				vRow.Attribute1C 	= vMapping.Hotel;
				vRow.DataPath 		= vMapping.DataPAth;
				vRow.IsSet			= True;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure MapCustomersFields()
	vMappings = Bitrix24.GetCustomersFieldsMapping();
	For Each vRow In FieldsForCustomersTable Do
		If Not ValueIsFilled(vRow.Attribute1C) Then
			vMapping = vMappings.Find(vRow.AttributeB24, "Bitrix");
			If vMapping <> Undefined Then
				vRow.Attribute1C 	= vMapping.Hotel;
				vRow.DataPath 		= vMapping.DataPAth;
				vRow.IsSet			= True;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure BoundEventsForClients()
	vEventsToBind = Bitrix24.GetEventsListForData(Object.SyncCustomers, True);
	Bitrix24.UpdateBoundEventsForClients(Object.InteractionParameters, vEventsToBind,,, Undefined, Object.EventsMode);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure Auth(pCommand)
	If Save_AtServer() Then
		vAuthURL = Auth_AtServer();
		GotoURL(vAuthURL);
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Function Auth_AtServer()
	Return "https://" + HTTPServer + "/oauth/authorize/?client_id=" + Bitrix24.AppCode();
EndFunction

// --------------------------------------------------------------------------------
&AtClient
Procedure AuthCodeOnChange(pItem)
	If ValueIsFilled(AuthCode) Then
		AuthCodeOnChange_AtServer();
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure AuthCodeOnChange_AtServer()
	
	vColors = GetFormItemsColors();
	vResult = GetNewAccessTokenB24(Object.InteractionParameters, Undefined, AuthCode);
	If vResult = True Then
		Items.Username.BackColor 	= vColors.Success;
		Items.Password.BackColor 	= vColors.Success;
		Items.HTTPServer.BackColor 	= vColors.Success;
		
		vUserMsg 		= New UserMessage;
		vUserMsg.Text 	= NStr("en = 'Successful connection!'; de = 'Erfolgreiche Verbindung!'; ru = 'Успешное подключение!'");
		vUserMsg.Field	= "Ping";
		vUserMsg.Message();
		
		BoundEventsForClients();
	Else
		Items.Username.BackColor 	= vColors.Failure;
		Items.Password.BackColor 	= vColors.Failure;				
		Items.HTTPServer.BackColor 	= vColors.Failure;
		
		vUserMsg 		= New UserMessage;
		vUserMsg.Text 	= NStr("en = 'Failed to connect to the server'; de = 'Verbindung zum Server fehlgeschlagen'; ru = 'Не удалось подключиться к серверу или неверный код приложения'");
		vUserMsg.Field	= "Ping";
		vUserMsg.Message();
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetCurrentHotelName()
	If ValueIsFilled(SessionParameters.CurrentHotel) Then
		Return Left(TrimAll(SessionParameters.CurrentHotel.Description), 100);
	EndIf;
	Return "";
EndFunction

// --------------------------------------------------------------------------------
&AtClient
Procedure NewBirix24PortalClick(Item)
	vHotelName = GetCurrentHotelName();
	BeginRunningApplication(New NotifyDescription, NStr("en = 'https://bitrix24.net/create/?p=608596&user_lang=en&p1='; de = 'https://bitrix24.net/create/?p=608596&user_lang=de&p1='; ru = 'https://bitrix24.net/create/?p=608596&user_lang=ru&p1='")+Bitrix24.EncodeURL(vHotelName));
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure GetClientTypesAtServer()
	vResult = Bitrix24.GetBitrix24Catalog(Object.InteractionParameters, "CONTACT_TYPE");
	
	For Each vRow In vResult Do
		vNewRow = ClientTypes.Add();
		FillPropertyValues(vNewRow, vRow);
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure GetCompanyTypesAtServer()
	vResult = Bitrix24.GetBitrix24Catalog(Object.InteractionParameters, "COMPANY_TYPE");
	
	For Each vRow In vResult Do
		vNewRow = CustomerTypes.Add();
		FillPropertyValues(vNewRow, vRow);
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure GetCompanyIndustriesAtServer()
	vResult = Bitrix24.GetBitrix24Catalog(Object.InteractionParameters, "INDUSTRY");
	
	For Each vRow In vResult Do
		vNewRow = CustomerIndustries.Add();
		FillPropertyValues(vNewRow, vRow);
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure GetDealsCategoryAtServer()
	Items.DealCategory.ChoiceList.Clear();
	Items.DealCategory.ChoiceList.Add("", NStr("en = 'General direction'; de = 'Allgemeine Richtung'; ru = 'Общее направление'"));
	
	vDealCategories = Bitrix24.GetBitrix24DealsCategory(Object.InteractionParameters);

	For Each vRow In vDealCategories Do 
		Items.DealCategory.ChoiceList.Add(vRow.id, vRow.Name); 
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure GetDealStatusesAtServer()
	DealsStatusesList.Clear();
	
	If ValueIsFilled(DealCategory) Then 
		vResult = Bitrix24.GetBitrix24DealsStageList(Object.InteractionParameters, DealCategory);
	Else 
		vResult = Bitrix24.GetBitrix24Catalog(Object.InteractionParameters, "DEAL_STAGE");
	EndIf;
	
	For Each vRow In vResult Do
		DealsStatusesList.Add(vRow.id, vRow.Name); 
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure LoadClientTypeTable()
	vClientTypes = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "ClientTypes");
	
	Try
		If vClientTypes.Count() > 0 Then			
			For Each vClientTypeRow In vClientTypes Do
				For Each vLoadedClientTypeRow In ClientTypes Do
					If vClientTypeRow.id = vLoadedClientTypeRow.id Then 
						vLoadedClientTypeRow.ClientType = vClientTypeRow.RefKey1;
					EndIf;
				EndDo;
			EndDo;
		EndIf;

		ClientTypes.Sort("ClientType DESC, ID");
	Except
		NotifyUserError();
	EndTry;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveClientTypeTable()
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "ClientTypes");
			
	For Each vClientTypeRow In ClientTypes Do
		If ValueIsFilled(vClientTypeRow.ClientType) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "ClientTypes", "ID", 	vClientTypeRow.ClientType, Undefined, vClientTypeRow.ID, 		vClientTypeRow.ID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "ClientTypes", "Name", 	vClientTypeRow.ClientType, Undefined, vClientTypeRow.Name, 		vClientTypeRow.ID);					
		EndIf;
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure LoadCompanyTypesTable()
	
	vCustomerTypes = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "CustomerTypes");
	
	Try
		If vCustomerTypes.Count() > 0 Then			
			For Each vCustomerTypeRow In vCustomerTypes Do
				For Each vLoadedCustomerTypeRow In CustomerTypes Do
					If vCustomerTypeRow.id = vLoadedCustomerTypeRow.id Then 
						vLoadedCustomerTypeRow.CustomerType = vCustomerTypeRow.RefKey1;
					EndIf;
				EndDo;
			EndDo;
		EndIf;

		CustomerTypes.Sort("CustomerType DESC, ID");
	Except
		NotifyUserError();
	EndTry;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveCompanyTypesTable()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "CustomerTypes");
			
	For Each vCustomerTypeRow In CustomerTypes Do
		If ValueIsFilled(vCustomerTypeRow.CustomerType) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "CustomerTypes", "ID", 	vCustomerTypeRow.CustomerType, Undefined, vCustomerTypeRow.ID, 		vCustomerTypeRow.ID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "CustomerTypes", "Name", vCustomerTypeRow.CustomerType, Undefined, vCustomerTypeRow.Name, 	vCustomerTypeRow.ID);					
		EndIf;
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure LoadCompanyIndustriesTable()
	
	vCustomerIndustries = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "CustomerIndustries");
	
	Try
		If vCustomerIndustries.Count() > 0 Then			
			For Each vCustomerIndustryRow In vCustomerIndustries Do
				For Each vLoadedCustomerIndastryRow In CustomerIndustries Do
					If vCustomerIndustryRow.id = vLoadedCustomerIndastryRow.id Then 
						vLoadedCustomerIndastryRow.CustomerIndustry = vCustomerIndustryRow.RefKey1;
					EndIf;
				EndDo;
			EndDo;
		EndIf;

		CustomerIndustries.Sort("CustomerIndustry DESC, ID");
		
	Except    
		NotifyUserError();
	EndTry;
	
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveCompanyIndustriesTable()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "CustomerIndustries");
			
	For Each vCustomerIndastryRow In CustomerIndustries Do
		If ValueIsFilled(vCustomerIndastryRow.CustomerIndustry) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "CustomerIndustries", "ID", 	vCustomerIndastryRow.CustomerIndustry, Undefined, vCustomerIndastryRow.ID, 	vCustomerIndastryRow.ID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "CustomerIndustries", "Name", vCustomerIndastryRow.CustomerIndustry, Undefined, vCustomerIndastryRow.Name, vCustomerIndastryRow.ID);					
		EndIf;
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure LoadDealStatusesTable(pDealCategory = Undefined)
	DealCategory = "";
	vDealStatuses = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "DealStatuses",,, GroupType);
	
	vDealCategory = Undefined;
	If pDealCategory <> Undefined Then
		DealCategory = pDealCategory; 
		vDealCategory = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "DealCategory",,GroupType,, DealCategory);
	EndIf;
	
	Try
		If vDealStatuses.Count() > 0 And (vDealCategory = Undefined Or (vDealCategory.Count() > 0 And vDealCategory.FindRows(New Structure("ID", DealCategory)).Count() > 0)) Then
			For Each vDealStatusRow In vDealStatuses Do
				For Each vLoadedDealStatusParentRow In DealsStatuses.GetItems() Do
					For Each vLoadedDealStatusRow In vLoadedDealStatusParentRow.GetItems() Do 
						If vDealStatusRow.RefKey1 = vLoadedDealStatusRow.Status Then 
							vLoadedDealStatusRow.id = vDealStatusRow.id;
							vLoadedDealStatusRow.Name = vDealStatusRow.Name;
							vLoadedDealStatusRow.Check = Not DealsStatusesList.FindByValue(vDealStatusRow.id) <> Undefined;
							If Not ValueIsFilled(DealCategory) And ValueIsFilled(vDealStatusRow.id) Then
								DealCategory = GetDealCategoryID(vDealStatusRow.id);
							EndIf;
						EndIf;
					EndDo;
				EndDo;
			EndDo;
		EndIf;
		
	Except
		NotifyUserError();
	EndTry;
EndProcedure // LoadDealStatusesTable

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveDoNotUnloadGroupType()
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "DoNotUnloadGroupType", , GroupType);
	InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "DoNotUnloadGroupType", "Value", GroupType, Undefined, DoNotUnloadGroupType);
EndProcedure // SaveDoNotUnloadGroupType

// --------------------------------------------------------------------------------
&AtServer
Procedure FillDoNotUnloadGroupType()
	DoNotUnloadGroupType = False;
	
	vDoNotUnloadGroupTypes = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "DoNotUnloadGroupType");
	
	vDoNotUnloadGroupTypesArr = vDoNotUnloadGroupTypes.FindRows(New Structure("RefKey1", GroupType));
	For Each vDoNotUnloadGroupTypeRow In vDoNotUnloadGroupTypesArr Do
		DoNotUnloadGroupType = vDoNotUnloadGroupTypeRow.Value;
		Break;
	EndDo;
	
	vDoNotUnloadGroupTypeTitle = NStr("en = 'Do not unload group type (Individuals)'; de = 'Gruppentyp nicht entladen (Einzelpersonen)'; ru = 'Не выгружать тип группы (Индивидуалы)'");
	If ValueIsFilled(GroupType) Then
		vDoNotUnloadGroupTypeTitle = StrTemplate(NStr("en = 'Do not unload group type (%1)'; de = 'Gruppentyp nicht entladen (%1)'; ru = 'Не выгружать тип группы (%1)'"), TrimAll(GroupType));
	EndIf;
	
	Items.DoNotUnloadGroupType.Title = vDoNotUnloadGroupTypeTitle;
EndProcedure // FillDoNotUnloadGroupType

// --------------------------------------------------------------------------------
&AtServer
Procedure NotifyUserError()
	vExc = Nstr("en = 'Failed to load sources mappings'; de = 'Quellenzuordnungen konnten nicht geladen werden'; ru = 'Не удалось загрузить сопоставления источников'");
	tcCommonFunctionOnClientServer.TextMessage(vExc);
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Function GetDealCategoryID(pDealStatusID)
	vResult = "";
	vDealCategory = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "DealCategory",,GroupType);
	If vDealCategory.Count() > 0 Then
		vResult = vDealCategory[0].id; 	
	Else
		For Each vDealCategoryID In Items.DealCategory.ChoiceList Do
			vDealsStageList = Bitrix24.GetBitrix24DealsStageList(Object.InteractionParameters, vDealCategoryID.Value);
			vDealsStageArr = vDealsStageList.FindRows(New Structure("id", pDealStatusID));
			If vDealsStageArr.Count() > 0 Then
				vResult = vDealCategoryID.Value;
				Break;
			EndIf;
		EndDo;
	EndIf;
	Return vResult;
EndFunction // GetDealCategoryID

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveDealStatusesTable()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "DealStatuses",,, GroupType);
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "DealCategory",,GroupType); 
	
	InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "DealCategory", "ID", GroupType, , DealCategory, DealCategory);
	For Each vDealStatusParentRow In DealsStatuses.GetItems() Do
		For Each vDealStatusRow In vDealStatusParentRow.GetItems() Do  
			If ValueIsFilled(vDealStatusRow.id) And ValueIsFilled(vDealStatusRow.Name) Then
				InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "DealStatuses", "ID", 	vDealStatusRow.Status, GroupType, vDealStatusRow.ID, 		vDealStatusRow.ID);
				InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "DealStatuses", "Name", 	vDealStatusRow.Status, GroupType, vDealStatusRow.Name, 		vDealStatusRow.ID);					
			EndIf;
		EndDo;
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveDealHotelsTable()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "Hotels");
			
	For Each vHotelRow In Hotels Do
		If ValueIsFilled(vHotelRow.Hotel) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "Hotels", "Hotels", 	vHotelRow.Hotel, Undefined, vHotelRow.ID, 	vHotelRow.ID);
		EndIf;
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure LoadDealHotelsTable()
	Hotels.Clear();
	vDealHotels = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "Hotels");
	
	For Each vDealHotelsRow In vDealHotels Do
		vNewRow = Hotels.Add();
		vNewRow.Hotel = vDealHotelsRow.RefKey1;
		vNewRow.ID = vDealHotelsRow.ExternalSystemDataCode;
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveDoNotUnloadTransactionsByBusinessBlock()
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "DoNotUnloadTransactionsByBusinessBlock",,, DoNotUnloadTransactionsByBusinessBlock);
	InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "DoNotUnloadTransactionsByBusinessBlock", "Value", Undefined, Undefined, DoNotUnloadTransactionsByBusinessBlock);
EndProcedure // SaveDoNotUnloadTransactionsByBusinessBlock

// --------------------------------------------------------------------------------
&AtServer
Procedure LoadDoNotUnloadTransactionsByBusinessBlock()
	vDoNotUnloadTransactionsByBusinessBlocks = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "DoNotUnloadTransactionsByBusinessBlock");
	
	For Each vDoNotUnloadTransactionsByBusinessBlockRow In vDoNotUnloadTransactionsByBusinessBlocks Do
		DoNotUnloadTransactionsByBusinessBlock = vDoNotUnloadTransactionsByBusinessBlockRow.Value;
	EndDo;
EndProcedure // LoadDoNotUnloadTransactionsByBusinessBlock

#EndRegion
