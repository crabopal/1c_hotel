#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Load DP parameters
	Obj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If ThisForm.Parameters.Property("DataProcessor", vDataProcessor) Then
		Obj.DataProcessor = vDataProcessor;
	EndIf;
	vInteractionParameters = Catalogs.ExternalSystemInteractions.EmptyRef();
	If Parameters.Property("InteractionParameters", vInteractionParameters) Then
		Obj.InteractionParameters = vInteractionParameters;
	EndIf;
	Obj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(Obj,"Object");
			
	If  IsInRoleAtServer("Administrator") And Not(vDataProcessor = Undefined) Then
		
		SetupBackgroundJobSchedule_AtServer(True);
		
		If UseBackgroundJob Then
			Items.Text_BackgroundJobInfo.Title = NStr("en='Background job is configured and started'; ru='Фоновое задание настроено и запущено'; de='Ein Hintergrundjob ist konfiguriert und läuft'");
		Else 
			Items.Text_BackgroundJobInfo.Title = NStr("en='Background job not started'; ru='Фоновое задание не запущено'; de='Ein Hintergrundjob nicht läuft'");
		EndIf;
	Else
		Items.Group_Page_BackgroundJob.Visible = False;
		tcCommonFunctionOnClientServer.TextMessage("en='You do not have rights to configure background job!'; ru='Нет прав для настройки фонового задания!'; de='Einen Hintergrundjob Einstellung ist nicht zulässig!'");
	EndIf;
	
	If NOT ValueIsFilled(Object.Hotel) Then
		Object.Hotel = SessionParameters.CurrentHotel;
	EndIf;
	
	If NOT ValueIsFilled(Object.InteractionParameters) Then
		vSettings = Hoteza.GetSettings();
		Object.InteractionParameters = ChannelManagers.GetInteractionParameters(Object.Hotel, Undefined, vSettings, vSettings.ExternalSystemCode);
		If ValueIsFilled(Object.InteractionParameters) Then
			If ValueIsFilled(Object.InteractionParameters.IntegrationType) Or Object.InteractionParameters.IntegrationType <> Enums.Integrations.Hoteza Then
				vObj = Object.InteractionParameters.GetObject();
				vObj.IntegrationType = Enums.Integrations.Hoteza;
				vObj.Write();	
			EndIf;
			If ValueIsFilled(Object.DataProcessor) Then
				If Not ValueIsFilled(Object.InteractionParameters.DataProcessor) Then
					vObj = Object.InteractionParameters.GetObject();
					vObj.DataProcessor = Object.DataProcessor;
					vObj.Write();
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	LoadInteractionParameters();
	FillDefaultInteractionParameters();
	
	ExspressCheckOutStatus = cmGetObjectRefByExternalSystemCode(Object.Hotel, "Hoteza", "AccommodationStatuses", "Hoteza");
	FillRoomStatusesTable();
	FillPaymentMethodsTable();
	FillRoomsTable();
	FillServicesTable();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
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
				Save_AtServer();
				SetupBackgroundJobSchedule_AtServer();
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

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelOnChange(pItem)
	vSettings = Hoteza.GetSettings();
	Object.InteractionParameters = ChannelManagers.GetInteractionParameters(Object.Hotel, Undefined, vSettings, vSettings.ExternalSystemCode); 
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelIDTextEditEnd(pItem, pText, pChoiceData, pDataGetParameters, pStandardProcessing)
	pStandardProcessing = False;
	ChangeExternalSystemRow(Object.HotelID, Object.Hotel, pText, Object.Hotel, "Hotels", Object.Hotel, Object.InteractionParameters, False);
	Object.HotelID 		= pText;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ExspressCheckOutStatusClearing(pItem, pStandardProcessing)
	DeleteExternalSystemRow("Hoteza", ExspressCheckOutStatus, "AccommodationStatuses", Object.Hotel, Object.InteractionParameters);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ExspressCheckOutStatusChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	ChangeExternalSystemRow("Hoteza", ExspressCheckOutStatus, "Hoteza", pSelectedValue, "AccommodationStatuses", Object.Hotel, Object.InteractionParameters, False);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomStatusesBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	pCancel = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomStatusesBeforeDeleteRow(pItem, pCancel)
	pCancel = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentMethodsBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	pCancel = True;
	If ValueIsFilled(Object.InteractionParameters) Then
		vPaymentMethodsList = GetPaymentMethods();
		If vPaymentMethodsList.Count() > 0 Then
			vParams = New Structure("MultipleChoice, Title, ValueList", False, NStr("en='Select payment method...'; ru='Выберите cпособ оплаты...'; de='Wählen Sie einen Zahlungsmethod aus...'"), vPaymentMethodsList);
			OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID, , , New NotifyDescription("AfterChoicePaymentMethods", ThisForm));
		EndIf;
	EndIf;
EndProcedure // PaymentMethodsBeforeAddRow

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentMethodsBeforeDeleteRow(pItem, pCancel)
	If ValueIsFilled(Object.InteractionParameters) Then
		DeleteExternalSystemRow(pItem.CurrentData.Code, pItem.CurrentData.PaymentMethod, "PaymentMethods", Object.Hotel, Object.InteractionParameters);
	Else
		pCancel = True;
	EndIf;	
EndProcedure // PaymentMethodsBeforeDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	pCancel = True;
	If ValueIsFilled(Object.InteractionParameters) Then
		vServicesList = GetServices();
		If vServicesList.Count() > 0 Then
			vParams = New Structure("MultipleChoice, Title, ValueList", False, NStr("en='Select service...'; ru='Выберите услугу...'; de='Wählen Sie einen Dienstleistung aus...'"), vServicesList);
			OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID, , , New NotifyDescription("AfterChoiceServices", ThisForm));
		EndIf;
	EndIf;	
EndProcedure // ServicesBeforeAddRow

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesBeforeDeleteRow(pItem, pCancel)
	If ValueIsFilled(Object.InteractionParameters) Then
		DeleteExternalSystemRow(pItem.CurrentData.Code, pItem.CurrentData.Service, "Services", Object.Hotel, Object.InteractionParameters);
	Else
		pCancel = True;
	EndIf;	
EndProcedure // ServicesBeforeDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomStatusesRoomStatusClearing(pItem, pStandardProcessing)
	DeleteExternalSystemRow(pItem.Parent.CurrentData.Code, pItem.Parent.CurrentData.RoomStatus, "RoomStatuses", Object.Hotel, Object.InteractionParameters);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomStatusesRoomStatusChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	ChangeExternalSystemRow(pItem.Parent.CurrentData.Code, pItem.Parent.CurrentData.RoomStatus, pItem.Parent.CurrentData.Code, pSelectedValue, "RoomStatuses", Object.Hotel, Object.InteractionParameters, False);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomsBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	pCancel = True;
	If ValueIsFilled(Object.InteractionParameters) Then
		vRoomsList = GetRooms();
		If vRoomsList.Count() > 0 Then
			vParams = New Structure("MultipleChoice, Title, ValueList", False, NStr("en='Select room...'; ru='Выберите номер...'; de='Zimmer auswählen...'"), vRoomsList);
			OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID, , , New NotifyDescription("AfterChoiceRooms", ThisForm));
		EndIf;
	EndIf;	
EndProcedure // RoomsBeforeAddRow

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomsBeforeDeleteRow(pItem, pCancel)
	If ValueIsFilled(Object.InteractionParameters) Then
		DeleteExternalSystemRow(pItem.CurrentData.Code, pItem.CurrentData.Room, "Rooms", Object.Hotel, Object.InteractionParameters);
	Else
		pCancel = True;
	EndIf;	
EndProcedure // RoomsBeforeDeleteRow

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Save(pCommand)
	Save_AtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SetupBackgroundJobSchedule(pCommand)
	If ValueIsFilled(Employee)  Then
		If  Not IsInRoleAtServer("Administrator") Then
			Raise(NStr("en='A background job can be configured by system administrator only!';ru='Фоновое задание может настроить только системный администратор!';de='Ein Hintergrundjob kann der Administrator konfigurieren!'"));
		Else 				
			vScheduleDlg = New ScheduledJobDialog(Object.Schedule);
			
			vScheduleDlg.Show(New NotifyDescription("SetupBackgroundJobSchedule_AfterInput", ThisForm, New Structure()));		
		EndIf;
	Else 
		Raise(NStr("en='User is not selected!';ru='Не выбран пользователь!';de='Nicht Benutzer sind gewählt!'"));
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CreateRoomInterfaceTypes(pCommand)
	vParametrs = New Structure("DataProcessor, InteractionParameters, ExtraParameters, CreateRoomInterfaceTypes", Object.DataProcessor, Object.InteractionParameters, "", True);
	vNotifyDescription = New NotifyDescription("AfterChangeExtraParameters", ThisForm);
	OpenForm("DataProcessor.HotezaWizard.Form.tcExtraSettingsForm", vParametrs, ThisForm, UUID,,, vNotifyDescription, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // CreateRoomInterfaceTypes

// -----------------------------------------------------------------------------
&AtClient
Procedure ManualSync(pCommand)
	ManualSync_AtServer();		
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
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

// -----------------------------------------------------------------------------
&AtServer
Procedure ManualSync_AtServer()
	Hoteza.Sync(Object.Hotel, Object.HotelID, Object.InteractionParameters);		
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterChangeExtraParameters(pParameters, pExtraParameters) Export 
	If pParameters <> Undefined Then  
		CreateRoomInterfaceTypes_AtServer(pParameters); 		
	EndIf;	
EndProcedure // AfterChangeExtraParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure CreateRoomInterfaceTypes_AtServer(pExtraParameters)
	// Read template with default settings and write it to the Room interface types catalog
	vRITList = DataProcessors.HotezaWizard.GetTemplate("InitializationRecords");
	vCount = vRITList.TableHeight - 1;
	For i = 2 To (vCount + 1) Do
		Try
			vCode = TrimAll(vRITList.Area(i, 1, i, 1).Text);
			vRITRef = Catalogs.RoomInterfaceTypes.FindByCode(vCode, False);
			If ValueIsFilled(vRITRef) Then
				vRITObj = vRITRef.GetObject();
			Else
				vRITObj = Catalogs.RoomInterfaceTypes.CreateItem();
			EndIf;
			vRITObj.Code = vCode;
			vRITObj.Hotel = ?(ValueIsFilled(Object.Hotel), Object.Hotel, SessionParameters.CurrentHotel);
			vRITObj.ExternalSystem = Object.InteractionParameters;
			vRITObj.InterfaceType = Enums.InterfaceTypes.TV;
			vRITObj.Description = NStr(TrimAll(vRITList.Area(i, 2, i, 2).Text));
			vRITObj.Remarks = TrimAll(vRITList.Area(i, 3, i, 3).Text);
			vRITObj.TurnOnParameters = TrimAll(vRITList.Area(i, 4, i, 4).Text);
			vRITObj.TurnOffParameters = TrimAll(vRITList.Area(i, 5, i, 5).Text);
			vRITObj.PeriodOfStayExtentionParameters = TrimAll(vRITList.Area(i, 6, i, 6).Text);
			vRITObj.GuestNameChangeParameters = TrimAll(vRITList.Area(i, 7, i, 7).Text);
			vRITObj.RoomChangeParameters = TrimAll(vRITList.Area(i, 8, i, 8).Text);
			vRITObj.CommandToChangeExtraParameters = TrimAll(vRITList.Area(i, 9, i, 9).Text);
			If vCode = "HCHI" Then	
				vRITObj.ExtraParameters = TrimAll(pExtraParameters["CheckIn"]);
			ElsIf vCode = "HRTV" Then
				vRITObj.ExtraParameters = TrimAll(pExtraParameters["TV"]);	
			ElsIf vCode = "HRMB" Then
				vRITObj.ExtraParameters = TrimAll(pExtraParameters["Minibar"]);	
			EndIf;
			vManualCancelIsForbidden = Upper(TrimAll(vRITList.Area(i, 10, i, 10).Text));
			If vManualCancelIsForbidden = "TRUE" Then
				vRITObj.ManualCancelIsForbidden = True;
			Else
				vRITObj.ManualCancelIsForbidden = False;
			EndIf;
			vRITObj.Write(); 
		Except
			vErrorMsg = ErrorDescription(); 
			tcCommonFunctionOnClientServer.TextMessage(vErrorMsg);
		EndTry;
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadInteractionParameters()
	
	If Not ValueIsFilled(Object.InteractionParameters) Then
		Return;
	EndIf;
	
	WSHost 		   = Object.InteractionParameters.WSHost;
	MultiplyFactor = Object.InteractionParameters.MultiplyFactor; 
	MaxLogLenght   = Object.InteractionParameters.MaxLogLenght; 
EndProcedure // LoadInteractionParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveInteractionParameters()
	
	If Not ValueIsFilled(Object.InteractionParameters) Then
		Return;
	EndIf;
		
	vIntParObj 					= Object.InteractionParameters.GetObject();
	vIntParObj.WSHost   		= WSHost;
	vIntParObj.MultiplyFactor	= MultiplyFactor;
	vIntParObj.MaxLogLenght	 	= MaxLogLenght;

	vIntParObj.Write();
EndProcedure // SaveInteractionParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure FillDefaultInteractionParameters()
	If ValueIsFilled(Object.InteractionParameters) Then
		vSave = False;
		vSettings = Hoteza.GetSettings(); 
		vObj 				= Object.InteractionParameters.GetObject();
		If Not ValueIsFilled(vSettings.ExternalSystemCode) Or vSettings.ExternalSystemCode <> Object.InteractionParameters.InteractionID Then 
			vObj.InteractionID = vSettings.ExternalSystemCode;
			vSave = True;
		EndIf;
		If Not ValueIsFilled(Object.InteractionParameters.WSHost) Then 
			vObj.WSHost = vSettings.WSHost;
			vSave = True;
		EndIf;
		If vSave Then
			vObj.Write();
		EndIf;
	EndIf;
EndProcedure // FillDefaultInteractionParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure FillRoomStatusesTable()
	RoomStatuses.Clear();
	If Not ValueIsFilled(Object.Hotel) Or Not ValueIsFilled(Object.InteractionParameters) Or Not ValueIsFilled(Object.InteractionParameters.InteractionID) Then
		Return;	
	EndIf;
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ExternalSystemsObjectCodesMappings.ObjectExternalCode,
		|	ExternalSystemsObjectCodesMappings.ObjectRef
		|FROM
		|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
		|WHERE
		|	ExternalSystemsObjectCodesMappings.Hotel = &qHotel
		|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
		|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""RoomStatuses""";
	
	vQuery.SetParameter("qExternalSystemCode", Object.InteractionParameters.InteractionID);
	vQuery.SetParameter("qHotel", Object.Hotel);
	
	vQueryResult = vQuery.Execute().Unload();
	
	vNewRow = RoomStatuses.Add();
	vNewRow.Code 		= "1";
	vNewRow.Description = NStr("en = 'Dirty/Vacant'; de = 'Dirty/Vacant'; ru = 'Грязный/Свободный'");
	vRow = vQueryResult.Find("1", "ObjectExternalCode");
	If ValueIsFilled(vRow) Then
		vNewRow.RoomStatus 	= vRow.ObjectRef;
	EndIf;
	
	vNewRow = RoomStatuses.Add();
	vNewRow.Code 		= "2";
	vNewRow.Description = NStr("en = 'Dirty/Occupied'; de = 'Dirty/Occupied'; ru = 'Грязный/Занят'");
	vRow = vQueryResult.Find("2", "ObjectExternalCode");
	If ValueIsFilled(vRow) Then
		vNewRow.RoomStatus 	= vRow.ObjectRef;
	EndIf;

	vNewRow = RoomStatuses.Add();
	vNewRow.Code 		= "3";
	vNewRow.Description = NStr("en = 'Clean/Vacant'; de = 'Clean/Vacant'; ru = 'Чистый/Свободный'");
	vRow = vQueryResult.Find("3", "ObjectExternalCode");
	If ValueIsFilled(vRow) Then
		vNewRow.RoomStatus 	= vRow.ObjectRef;
	EndIf;

	vNewRow = RoomStatuses.Add();
	vNewRow.Code 		= "4";
	vNewRow.Description = NStr("en = 'Clean/Occupied'; de = 'Clean/Occupied'; ru = 'Чистый/Занят'");
	vRow = vQueryResult.Find("4", "ObjectExternalCode");
	If ValueIsFilled(vRow) Then
		vNewRow.RoomStatus 	= vRow.ObjectRef;
	EndIf;

	vNewRow = RoomStatuses.Add();
	vNewRow.Code 		= "5";
	vNewRow.Description = NStr("en = 'Inspected/Vacant'; de = 'Inspected/Vacant'; ru = 'Инспекция/Свободный'");
	vRow = vQueryResult.Find("5", "ObjectExternalCode");
	If ValueIsFilled(vRow) Then
		vNewRow.RoomStatus 	= vRow.ObjectRef;
	EndIf;

	vNewRow = RoomStatuses.Add();
	vNewRow.Code 		= "6";
	vNewRow.Description = NStr("en = 'Inspected/Occupied'; de = 'Inspected/Occupied'; ru = 'Инспекция/Занят'");
	vRow = vQueryResult.Find("6", "ObjectExternalCode");
	If ValueIsFilled(vRow) Then
		vNewRow.RoomStatus 	= vRow.ObjectRef;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillPaymentMethodsTable()
	PaymentMethods.Clear();
	If Not ValueIsFilled(Object.Hotel) Or Not ValueIsFilled(Object.InteractionParameters) Or Not ValueIsFilled(Object.InteractionParameters.InteractionID) Then
		Return;	
	EndIf;
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode,
		|	ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef
		|FROM
		|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
		|WHERE
		|	ExternalSystemsObjectCodesMappings.Hotel = &qHotel
		|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
		|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""PaymentMethods""";
	
	vQuery.SetParameter("qExternalSystemCode", Object.InteractionParameters.InteractionID);
	vQuery.SetParameter("qHotel", Object.Hotel);
	
	vQueryResult = vQuery.Execute().Unload();
	
	For Each vRow In vQueryResult Do
		vNewRow = PaymentMethods.Add();
		vNewRow.Code = vRow.ObjectExternalCode;
		vNewRow.PaymentMethod = vRow.ObjectRef; 
	EndDo;	
EndProcedure // FillPaymentMethodsTable 

// -----------------------------------------------------------------------------
&AtServer
Procedure FillRoomsTable()
	Rooms.Clear();
	If Not ValueIsFilled(Object.Hotel) Or Not ValueIsFilled(Object.InteractionParameters) Or Not ValueIsFilled(Object.InteractionParameters.InteractionID) Then
		Return;	
	EndIf;
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode,
		|	ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef
		|FROM
		|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
		|WHERE
		|	ExternalSystemsObjectCodesMappings.Hotel = &qHotel
		|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
		|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""Rooms""";
	
	vQuery.SetParameter("qExternalSystemCode", Object.InteractionParameters.InteractionID);
	vQuery.SetParameter("qHotel", Object.Hotel);
	
	vQueryResult = vQuery.Execute().Unload();
	
	For Each vRow In vQueryResult Do
		vNewRow = Rooms.Add();
		vNewRow.Code = vRow.ObjectExternalCode;
		vNewRow.Room = vRow.ObjectRef; 
	EndDo;	
EndProcedure // FillRoomsTable

// -----------------------------------------------------------------------------
&AtServer
Procedure FillServicesTable()
	Services.Clear();
	If Not ValueIsFilled(Object.Hotel) Or Not ValueIsFilled(Object.InteractionParameters) Or Not ValueIsFilled(Object.InteractionParameters.InteractionID) Then
		Return;	
	EndIf;
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode,
		|	ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef
		|FROM
		|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
		|WHERE
		|	ExternalSystemsObjectCodesMappings.Hotel = &qHotel
		|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
		|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""Services""";
	
	vQuery.SetParameter("qExternalSystemCode", Object.InteractionParameters.InteractionID);
	vQuery.SetParameter("qHotel", Object.Hotel);
	
	vQueryResult = vQuery.Execute().Unload();
	
	For Each vRow In vQueryResult Do
		vNewRow = Services.Add();
		vNewRow.Code = vRow.ObjectExternalCode;
		vNewRow.Service = vRow.ObjectRef; 
	EndDo;	
EndProcedure // FillServicesTable

// -----------------------------------------------------------------------------
&AtServer
Procedure Save_AtServer()
	If CheckFilling() Then
		SaveInteractionParameters();
		
		vRecordManager 						= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
		vRecordManager.Hotel 				= Object.Hotel;
		vRecordManager.ExternalSystemCode 	= "Hoteza";
		vRecordManager.ObjectTypeName 		= "Hotels";
		vRecordManager.ObjectExternalCode 	= Object.HotelID;
		vRecordManager.ObjectRef 			= Object.Hotel;
		vRecordManager.Read();
		If NOT vRecordManager.Selected() Then
			vRecordManager.Hotel 				= Object.Hotel;
			vRecordManager.ExternalSystemCode 	= "Hoteza";
			vRecordManager.ObjectTypeName 		= "Hotels";
			vRecordManager.ObjectExternalCode 	= Object.HotelID;
			vRecordManager.ObjectRef 			= Object.Hotel;	
			vRecordManager.Write(True);
		EndIf;
		
		For each vRow in RoomStatuses Do
			vRecordManager 						= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
			vRecordManager.Hotel 				= Object.Hotel;
			vRecordManager.ExternalSystemCode 	= Object.InteractionParameters.InteractionID;
			vRecordManager.ObjectTypeName 		= "RoomStatuses";
			vRecordManager.ObjectExternalCode 	= vRow.Code;
			vRecordManager.ObjectRef 			= vRow.RoomStatus;
			vRecordManager.Read();
			
			If NOT vRecordManager.Selected() Then
				vRecordManager.Hotel 				= Object.Hotel;
				vRecordManager.ExternalSystemCode 	= Object.InteractionParameters.InteractionID;
				vRecordManager.ObjectTypeName 		= "RoomStatuses";
				vRecordManager.ObjectExternalCode 	= vRow.Code;
				vRecordManager.ObjectRef 			= vRow.RoomStatus;		
				vRecordManager.Write(True);
			EndIf;
		EndDo;
		
		If ValueIsFilled(ExspressCheckOutStatus) Then
			vRecordManager 						= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
			vRecordManager.Hotel 				= Object.Hotel;
			vRecordManager.ExternalSystemCode 	= "Hoteza";
			vRecordManager.ObjectTypeName 		= "AccommodationStatuses";
			vRecordManager.ObjectExternalCode 	= "Hoteza";
			vRecordManager.ObjectRef 			= ExspressCheckOutStatus;
			vRecordManager.Read();
			If NOT vRecordManager.Selected() Then
				vRecordManager.Hotel 				= Object.Hotel;
				vRecordManager.ExternalSystemCode 	= "Hoteza";
				vRecordManager.ObjectTypeName 		= "AccommodationStatuses";
				vRecordManager.ObjectExternalCode 	= "Hoteza";
				vRecordManager.ObjectRef 			= ExspressCheckOutStatus;			
				vRecordManager.Write(True);
			EndIf;		
		EndIf;
		
		SetupBackgroundJobSchedule_AtServer();
		// Save DP parameters
		Obj = FormAttributeToValue("Object");
		Obj.pmSaveDataProcessorAttributes();
		FillRoomStatusesTable();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SetupBackgroundJobSchedule_AtServer(pRead = False)
	If NOT CheckFilling() Then
		UseBackgroundJob = False;
	EndIf;
	
	Try
		ArrayScheduledJob = ScheduledJobs.GetScheduledJobs(New Structure("Key",Object.DataProcessor.Key));
		
		If ArrayScheduledJob.Count() > 0 Then
			ScheduledJob 			= ArrayScheduledJob[0];
			
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
			EndIf;
			
			If ScheduledJob.Parameters.Count() = 0 Then
				ScheduledJob.Parameters.Add(Object.DataProcessor.Key);
			EndIf;
			
		Else 	
			
			For Each vScheduledJob In Metadata.ScheduledJobs Do   
				If vScheduledJob.Name="RunDataProcessor" Then
					
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
			
			If Object.Schedule = Undefined or pRead Then 
				Object.Schedule  					= ScheduledJob.Schedule;
			Else
				ScheduledJob.Schedule   			= Object.Schedule;
			EndIf;
			
			If ScheduledJob.Parameters.Count() = 0 Then
				ScheduledJob.Parameters.Add(Object.DataProcessor.Key);
			EndIf;
			
		EndIf;
		
		ScheduledJob.Write();
		
	Except	
		tcCommonFunctionOnClientServer.TextMessage(ErrorDescription(), MessageStatus.Attention);	
	EndTry;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function IsInRoleAtServer(pRole)
	Return IsInRole(pRole);
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function GetPaymentMethods()
	vPaymentMethodsList = New ValueList();
	vQuery = New Query();
	vQuery.Text =
	"SELECT
	|	PaymentMethods.Ref AS PaymentMethod
	|FROM
	|	Catalog.PaymentMethods AS PaymentMethods
	|WHERE
	|	NOT PaymentMethods.DeletionMark
	|
	|ORDER BY
	|	PaymentMethods.SortCode,
	|	PaymentMethods.Code";
	vPaymentMethodsList.LoadValues(vQuery.Execute().Unload().UnloadColumn("PaymentMethod")); 
	Return vPaymentMethodsList;
EndFunction // GetPaymentMethods

// -----------------------------------------------------------------------------
&AtServer
Function GetRooms()
	vRoomsList = New ValueList();
	vQuery = New Query();
	vQuery.Text =
	"SELECT
	|	Rooms.Ref AS Room
	|FROM
	|	Catalog.Rooms AS Rooms
	|WHERE
	|	NOT Rooms.DeletionMark
	|	AND NOT Rooms.IsFolder
	|	AND Rooms.Owner = &qHotel
	|
	|ORDER BY
	|	Rooms.SortCode,
	|	Rooms.Description"; 
	vQuery.SetParameter("qHotel", Object.Hotel);
	vRoomsList.LoadValues(vQuery.Execute().Unload().UnloadColumn("Room")); 
	Return vRoomsList;
EndFunction // GetRooms

// -----------------------------------------------------------------------------
&AtServer
Function GetServices()
	vServicesList = New ValueList();
	vQuery = New Query();
	vQuery.Text =
	"SELECT
	|	Services.Ref AS Service
	|FROM
	|	Catalog.Services AS Services
	|WHERE
	|	NOT Services.DeletionMark
	|	AND (Services.Hotel = &qHotel
	|			OR Services.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|	AND NOT Services.IsRoomRevenue
	|	AND NOT Services.IsInPrice
	|	AND NOT Services.IsFolder
	|
	|ORDER BY
	|	Services.SortCode,
	|	Services.Code";
	vQuery.SetParameter("qHotel", Object.Hotel);
	vServicesList.LoadValues(vQuery.Execute().Unload().UnloadColumn("Service")); 
	Return vServicesList;
EndFunction // GetServices

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterChoicePaymentMethods(pItem, pExtraParams) Export 
	If pItem <> Undefined And ValueIsFilled(pItem.Value) Then
		ShowInputString(New NotifyDescription("AfterInputPaymentMethodsCode", ThisForm, pItem.Value),, NStr("en = 'Input payment method code'; de = 'Geben Sie den Zahlungsmethodcode ein'; ru = 'Введите код способа оплаты'"),, False); 
	EndIf;
EndProcedure // AfterChoicePaymentMethods

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterInputPaymentMethodsCode(pText, pExtraParams) Export 
	If pText <> Undefined And ValueIsFilled(pText) And ValueIsFilled(pExtraParams) Then 
		ChangeExternalSystemRow(pText, pExtraParams, pText, pExtraParams, "PaymentMethods", Object.Hotel, Object.InteractionParameters, False);	
		FillPaymentMethodsTable();
	EndIf;
EndProcedure // AfterInputPaymentMethodsCode

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterChoiceRooms(pItem, pExtraParams) Export 
	If pItem <> Undefined And ValueIsFilled(pItem.Value) Then
		ShowInputString(New NotifyDescription("AfterInputRoomsCode", ThisForm, pItem.Value),, NStr("en = 'Input room code'; de = 'Geben Sie den Zimmercode ein'; ru = 'Введите код номера'"),, False); 
	EndIf;
EndProcedure // AfterChoiceRooms

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterInputRoomsCode(pText, pExtraParams) Export 
	If pText <> Undefined And ValueIsFilled(pText) And ValueIsFilled(pExtraParams) Then 
		ChangeExternalSystemRow(pText, pExtraParams, pText, pExtraParams, "Rooms", Object.Hotel, Object.InteractionParameters, False);	
		FillRoomsTable();
	EndIf;
EndProcedure // AfterInputRoomsCode

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterChoiceServices(pItem, pExtraParams) Export 
	If pItem <> Undefined And ValueIsFilled(pItem.Value) Then
		ShowInputString(New NotifyDescription("AfterInputServicesCode", ThisForm, pItem.Value),, NStr("en = 'Input service code'; de = 'Geben Sie den Dienstleistungcode ein'; ru = 'Введите код услуги'"),, False); 
	EndIf;
EndProcedure // AfterChoiceServices

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterInputServicesCode(pText, pExtraParams) Export 
	If pText <> Undefined And ValueIsFilled(pText) And ValueIsFilled(pExtraParams) Then 
		ChangeExternalSystemRow(pText, pExtraParams, pText, pExtraParams, "Services", Object.Hotel, Object.InteractionParameters, False);	
		FillServicesTable();
	EndIf;
EndProcedure // AfterInputServicesCode

// -----------------------------------------------------------------------------
&AtServer
Procedure DeleteExternalSystemRow(pCode, pObjectRef, pObjectTypeName, pHotel, pInteractionParameters)
	If ValueIsFilled(pInteractionParameters) Then
		vRecordManager 						= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
		vRecordManager.Hotel 				= pHotel;
		vRecordManager.ExternalSystemCode 	= pInteractionParameters.InteractionID;
		vRecordManager.ObjectTypeName 		= pObjectTypeName;
		vRecordManager.ObjectExternalCode 	= pCode;
		vRecordManager.ObjectRef 			= pObjectRef;
		vRecordManager.Read();
		
		If  vRecordManager.Selected() Then
			vRecordManager.Delete();
		EndIf;
		
		vRecordManager 						= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
		vRecordManager.Hotel 				= pHotel;
		vRecordManager.ExternalSystemCode 	= pInteractionParameters.InteractionID;
		vRecordManager.ObjectTypeName 		= "Virtual" + pObjectTypeName;
		vRecordManager.ObjectExternalCode 	= pCode;
		vRecordManager.ObjectRef 			= pObjectRef;
		vRecordManager.Read();
		
		If  vRecordManager.Selected() Then
			vRecordManager.Delete();
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure ChangeExternalSystemRow(pOldCode, pOldObjectRef, pCode, pObjectRef, pObjectTypeName, pHotel, pInteractionParameters, pIsVirtual)
	If ValueIsFilled(pInteractionParameters) Then
		vRecordManager 						= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
		vRecordManager.Hotel 				= pHotel;
		vRecordManager.ExternalSystemCode 	= pInteractionParameters.InteractionID;
		vRecordManager.ObjectTypeName 		= pObjectTypeName;
		vRecordManager.ObjectExternalCode 	= pOldCode;
		vRecordManager.ObjectRef 			= pOldObjectRef;
		vRecordManager.Read();
		
		If  vRecordManager.Selected() Then
			vRecordManager.Delete();
		EndIf;
		
		vRecordManager 						= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
		vRecordManager.Hotel 				= pHotel;
		vRecordManager.ExternalSystemCode 	= pInteractionParameters.InteractionID;
		vRecordManager.ObjectTypeName 		= "Virtual" + pObjectTypeName;
		vRecordManager.ObjectExternalCode 	= pOldCode;
		vRecordManager.ObjectRef 			= pOldObjectRef;
		vRecordManager.Read();
		
		If  vRecordManager.Selected() Then
			vRecordManager.Delete();
		EndIf;
		
		vRecordManager 						= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
		vRecordManager.Hotel 				= pHotel;
		vRecordManager.ExternalSystemCode 	= pInteractionParameters.InteractionID;
		If pIsVirtual Then
			vRecordManager.ObjectTypeName 		= "Virtual" + pObjectTypeName;	
		Else
			vRecordManager.ObjectTypeName 		= pObjectTypeName;
		EndIf;
		vRecordManager.ObjectExternalCode 	= pCode;
		vRecordManager.ObjectRef 			= pObjectRef;
		vRecordManager.Write(true);
	EndIf;
EndProcedure

#EndRegion

