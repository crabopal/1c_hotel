#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	// Load DP parameters
	Obj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If ThisObject.Parameters.Property("DataProcessor", vDataProcessor) Then
		Obj.DataProcessor = vDataProcessor;
	EndIf;
	vInteractionParameters = Catalogs.ExternalSystemInteractions.EmptyRef();
	If Parameters.Property("InteractionParameters", vInteractionParameters) Then
		Obj.InteractionParameters = vInteractionParameters;
	EndIf;
	Obj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(Obj,"Object");
	
	LoadInteractionParameters();
	
	FillObjectTypeName();
	
	If  IsInRoleAtServer("Administrator") And Not(vDataProcessor = Undefined) Then
		
		SetupBackgroundJobSchedule_AtServer(True);
		
		If UseBackgroundJob Then
			Items.Text_BackgroundJobInfo.Title = NStr("en='Background job is configured and started'; ru='Фоновое задание настроено и запущено'; de='Ein Hintergrundjob ist konfiguriert und läuft'");
		Else 
			Items.Text_BackgroundJobInfo.Title = NStr("en='Background job not started'; ru='Фоновое задание не запущено'; de='Ein Hintergrundjob nicht läuft'");
		EndIf;
	Else
		Items.Group_Page_BackgroundJob.Visible = False;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to configure background job!'; ru='Нет прав для настройки фонового задания!'; de='Einen Hintergrundjob Einstellung ist nicht zulässig!'"));
	EndIf; 
	RefreshDisplay();
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	SetParameters(?(Items.ObjectTypeName.CurrentData <> Undefined, Items.ObjectTypeName.CurrentData.Value, ""));
EndProcedure // OnOpen

&AtServer
Procedure FillCheckProcessingAtServer(pCancel, pCheckedAttributes)
	If Object.UseBus Then 
		If Not ValueIsFilled(Object.OrderType) Then
			pCancel = True;
			tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Order type is not filled'; de = 'Auftragstyp ist nicht gefüllt'; ru = 'Тип заказа не заполнен'"), Object.OrderType, "Object.OrderType",, True);
		EndIf;	
	EndIf; 
	If Object.UseWebService Then
		pCheckedAttributes.Add("OAuth_ClientID");
		pCheckedAttributes.Add("OAuth_ClientSecret");
		pCheckedAttributes.Add("OrderType");
	EndIf;
	If Object.UseMedicalRecordHistory Then  
		If Not ValueIsFilled(Object.MedicalRecordHistoryImportCatalog) Then
			pCancel = True;
			tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Data exchange file is not filled'; de = 'Datenaustauschdatei ist nicht gefüllt'; ru = 'Файл обмена данными не заполнен'"), Object.MedicalRecordHistoryImportCatalog, "Object.MedicalRecordHistoryImportCatalog",, True); 
		EndIf;
	EndIf; 
	If Object.UseStatisticsRenderedAndPaidServices Then
		If Not ValueIsFilled(Object.RenderedServicesImportCatalog) Then
			pCancel = True;
			tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Data exchange file is not filled'; de = 'Datenaustauschdatei ist nicht gefüllt'; ru = 'Файл обмена данными не заполнен'"), Object.RenderedServicesImportCatalog, "Object.RenderedServicesImportCatalog",, True); 
		EndIf;
		If Not ValueIsFilled(Object.PaymentsImportCatalog) Then
			pCancel = True;
			tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Data exchange file is not filled'; de = 'Datenaustauschdatei ist nicht gefüllt'; ru = 'Файл обмена данными не заполнен'"), Object.PaymentsImportCatalog, "Object.PaymentsImportCatalog",, True); 
		EndIf; 
		If Not ValueIsFilled(Object.StatisticsOrderType) Then
			pCancel = True;
			tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Order type is not filled'; de = 'Auftragstyp ist nicht gefüllt'; ru = 'Тип заказа не заполнен'"), Object.StatisticsOrderType, "Object.StatisticsOrderType",, True);
		EndIf;
	EndIf;	 
	If Object.UseStatisticsRenderedAndPaidServices Or Object.UseMedicalRecordHistory Then
		If Not ValueIsFilled(Object.HistoryCatalog) Then
			pCancel = True;
			tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'History catalog is not filled'; de = 'Historienkatalog ist nicht gefüllt'; ru = 'Каталог истории не заполнен'"), Object.HistoryCatalog, "Object.HistoryCatalog",, True);	
		EndIf; 
	EndIf;
EndProcedure // FillCheckProcessingAtServer

#EndRegion          

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Save(pCommand)
	Save_AtServer();
EndProcedure // Save

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionsExecute(pCommand)
	ActionsExecuteAtServer();
	ShowMessageBox(,NStr("en='Processing completed!';ru='Выполнение процедуры закончено!';de='Die Prozedur ist abgeschlossen!'"));
EndProcedure // ActionsExecute

// -----------------------------------------------------------------------------
&AtClient
Procedure GenerateToken(pCommand)
	InteractionID = String(New UUID);
EndProcedure // GenerateToken

// -----------------------------------------------------------------------------
&AtClient
Procedure SetupBackgroundJobSchedule(pCommand)
	If ValueIsFilled(Employee)  Then
		If  Not IsInRoleAtServer("Administrator") Then
			Raise(NStr("en='A background job can be configured by system administrator only!';ru='Фоновое задание может настроить только системный администратор!';de='Ein Hintergrundjob kann der Administrator konfigurieren!'"));
		Else 				
			vScheduleDlg = New ScheduledJobDialog(Object.Schedule);
			
			vScheduleDlg.Show(New NotifyDescription("SetupBackgroundJobSchedule_AfterInput", ThisObject, New Structure()));		
		EndIf;
	Else 
		Raise(NStr("en='User is not selected!';ru='Не выбран пользователь!';de='Nicht Benutzer sind gewählt!'"));
	EndIf;
EndProcedure // SetupBackgroundJobSchedule

// -----------------------------------------------------------------------------
&AtClient
Procedure UpdateAccessToken(pCommand)
	UpdateAccessTokenAtServer();	
EndProcedure // UpdateAccessToken

// -----------------------------------------------------------------------------
&AtClient
Procedure AddDataToMapping(pCommand)
	If Not IsBlankString(Items.ObjectTypeName.CurrentData) And ValueIsFilled(Object.InteractionParameters) Then
		vCurrentData = Items.ObjectTypeName.CurrentData.Value;
		vObjectRefList = GetObjectRefList(vCurrentData, Object.InteractionParameters);
		If vObjectRefList.Count() > 0 Then
			vNotifyDescription = New NotifyDescription("AfterChoiceByObjectTypeName", ThisObject, vCurrentData);
			vParams = New Structure("ValueList, MultipleChoice, Title", vObjectRefList, False, NStr("en = 'Select object reference'; de = 'Objektbezug auswählen'; ru = 'Выберите ссылку на объект'"));
			OpenForm("CommonForm.mcChoiceValueList", vParams, ThisObject, UUID,,, vNotifyDescription, FormWindowOpeningMode.LockOwnerWindow);
		EndIf;
	EndIf;
EndProcedure // AddDataToMapping

// -----------------------------------------------------------------------------
&AtClient
Procedure DeleteDataToMapping(pCommand)
	vCurrentData = Items.ObjectTypeName.CurrentData.Value;
	If vCurrentData <> Undefined Then
		vCurRow = Items.ExternalSystemIntegrationData.CurrentData;
		If vCurRow <> Undefined Then
        	DeleteDataToMappingAtServer(Object.InteractionParameters, vCurrentData, vCurRow.ObjectRef, vCurRow.ExternalSystemDataCode); 
			Items.ExternalSystemIntegrationData.Refresh();
		EndIf;
	EndIf;
EndProcedure // DeleteDataToMapping

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriod(pCommand)
	vChoosePeriodDialog = New StandardPeriodEditDialog();
	vChoosePeriodDialog.Period.StartDate = PeriodFrom;
	vChoosePeriodDialog.Period.EndDate = PeriodTo;
	vChoosePeriodDialog.Period.Variant = StandardPeriodVariant.Custom;
	vChoosePeriodDialog.Show(New NotifyDescription("ChoosePeriodAfterChoice", ThisForm));
EndProcedure // ChoosePeriod

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionsUnload(pCommand)
	ActionsUnloadAtServer();	
EndProcedure // ActionsUnload

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelClearing(pItem, pStandardProcessing)
	If Not tcOnServer.cmIsInRole("RightsToChooseHotel") Then
		pStandardProcessing = False;
	EndIf;
EndProcedure // HotelClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure InteractionParametersOnChange(pItem)
	SetParameters(?(Items.ObjectTypeName.CurrentData <> Undefined, Items.ObjectTypeName.CurrentData.Value, ""));
	LoadInteractionParameters();
EndProcedure // InteractionParametersOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ActiveOnChange(pItem)
	If NOT Active Then
		Debug = False;
	EndIf;
EndProcedure // ActiveOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DebugOnChange(pItem)
	If Debug Then
		Active = True;
	EndIf;
EndProcedure // DebugOnChange

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
EndProcedure // UseBackgroundJobOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ObjectTypeNameOnActivateRow(pItem) 
	SetParameters(?(Items.ObjectTypeName.CurrentData <> Undefined, Items.ObjectTypeName.CurrentData.Value, ""));
EndProcedure // ObjectTypeNameOnActivateRow

// -----------------------------------------------------------------------------
&AtClient
Procedure MedicalRecordHistoryImportCatalogStartChoice(pItem, pChoiceData, pStandardProcessing)
	vParams = tcOnClientWorkWithFiles.cmGetEmptyParamsForLoadFiles();
	vParams.NotifyDescription = New NotifyDescription("SetCatalog", ThisObject, "MedicalRecordHistoryImportCatalog");
	vParams.FileDialogMode = FileDialogMode.ChooseDirectory;
	tcOnClientWorkWithFiles.LoadFile(vParams);	
EndProcedure // DataExchangeFileStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure RenderedServicesImportCatalogStartChoice(pItem, pChoiceData, pStandardProcessing)
	vParams = tcOnClientWorkWithFiles.cmGetEmptyParamsForLoadFiles();
	vParams.NotifyDescription = New NotifyDescription("SetCatalog", ThisObject, "RenderedServicesImportCatalog");
	vParams.FileDialogMode = FileDialogMode.ChooseDirectory;
	tcOnClientWorkWithFiles.LoadFile(vParams);	
EndProcedure // RenderedServicesImportCatalogStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentsImportCatalogStartChoice(pItem, pChoiceData, pStandardProcessing)
	vParams = tcOnClientWorkWithFiles.cmGetEmptyParamsForLoadFiles();
	vParams.NotifyDescription = New NotifyDescription("SetCatalog", ThisObject, "PaymentsImportCatalog");
	vParams.FileDialogMode = FileDialogMode.ChooseDirectory;
	tcOnClientWorkWithFiles.LoadFile(vParams);	
EndProcedure // PaymentsImportCatalogStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure HistoryCatalogStartChoice(pItem, pChoiceData, pStandardProcessing)
	vParams = tcOnClientWorkWithFiles.cmGetEmptyParamsForLoadFiles();
	vParams.NotifyDescription = New NotifyDescription("SetHistoryCatalog", ThisObject);
	vParams.FileDialogMode = FileDialogMode.ChooseDirectory;
	tcOnClientWorkWithFiles.LoadFile(vParams);	
EndProcedure // HistoryCatalogStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure UseBusOnChange(pItem)
	RefreshDisplay();
EndProcedure // UseBusOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure UseWebServiceOnChange(pItem)
	RefreshDisplay();
EndProcedure // UseWebServiceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure UseMedicalRecordHistoryOnChange(pItem)
	RefreshDisplay();
EndProcedure // UseMedicalRecordHistoryOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure UnloadTypeOnChange(pItem)
	If UnloadType = 2 Then
		Items.GroupFromPeriod.Visible = False;
		Items.GroupReservationsList.Visible = True;
	Else
		Items.GroupFromPeriod.Visible = True;
		Items.GroupReservationsList.Visible = False;	
	EndIf;
EndProcedure // UnloadTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure UseStatisticsRenderedAndPaidServicesOnChange(pItem)
	RefreshDisplay();	
EndProcedure // UseStatisticsRenderedAndPaidServicesOnChange

#EndRegion 

#Region Private

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure DeleteDataToMappingAtServer(pInteractionParameters, pDataType, pObjectRef, pExternalSystemDataCode)
	If pDataType = "ReservationStatuses" Or pDataType = "AccommodationStatuses" Then
		InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(pInteractionParameters, pDataType, "Code", pObjectRef,,, pExternalSystemDataCode);  	
	Else
		vRecordSet = InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordSet();
		vRecordSet.Filter.Hotel.Set(pInteractionParameters.Hotel);
		vRecordSet.Filter.ExternalSystemCode.Set(pInteractionParameters.InteractionID);
		vRecordSet.Filter.ObjectTypeName.Set(pDataType);  
		vRecordSet.Filter.ObjectExternalCode.Set(pExternalSystemDataCode);
		vRecordSet.Write(True);	
	EndIf;	
EndProcedure // DeleteDataToMappingAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SetCatalog(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		Object[pParam] = pFileArray[0];
	EndIf;
EndProcedure // SetCatalog

// -----------------------------------------------------------------------------
&AtClient
Procedure SetHistoryCatalog(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		Object.HistoryCatalog = pFileArray[0];
	EndIf;
EndProcedure // SetHistoryCatalog

// -----------------------------------------------------------------------------
&AtServer
Procedure FillObjectTypeName()
	ObjectTypeName.Clear();
	ObjectTypeName.Add("Hotels", NStr("en = 'Hotels'; de = 'Hotels'; ru = 'Гостиницы'"));
	ObjectTypeName.Add("Rooms", NStr("en = 'Rooms'; de = 'Zimmerbestand'; ru = 'Номерной фонд'"));
	ObjectTypeName.Add("RoomTypes", NStr("en = 'Room types'; de = 'Zimmertypen'; ru = 'Типы номеров'"));
	ObjectTypeName.Add("RoomRates", NStr("en = 'Room rates'; de = 'Tarife'; ru = 'Тарифы'"));
	ObjectTypeName.Add("Services", NStr("en = 'Services'; de = 'Dienstleistungen'; ru = 'Услуги'"));
	ObjectTypeName.Add("ServicePackages", NStr("en = 'Service packages'; de = 'Dienstleistungspakete'; ru = 'Пакеты услуг'"));
	ObjectTypeName.Add("DiscountTypes", NStr("en = 'Discount types'; de = 'Preisnachlasstypen'; ru = 'Типы скидок'"));
	ObjectTypeName.Add("ReservationStatuses", NStr("en = 'Reservation statuses'; de = 'Status der Reservierung'; ru = 'Статусы брони'"));
	ObjectTypeName.Add("AccommodationStatuses", NStr("en = 'Accommodation statuses'; de = 'Status der Unterbringung der Gäste in Zimmern'; ru = 'Статусы размещения гостей в номерах'"));
	ObjectTypeName.Add("Currencies", NStr("en = 'Currencies'; de = 'Währungen'; ru = 'Валюты'"));
	ObjectTypeName.Add("IdentityDocumentTypes", NStr("en = 'Identity document types'; de = 'Personalausweistypen'; ru = 'Виды документов удостоверяющих личность'"));
	ObjectTypeName.Add("MilitaryRanks", NStr("en = 'Кanks (military, corporate, etc.)'; de = 'Ränge (Militär, Unternehmen usw.)'; ru = 'Звания (воинские, корпоративные и т.д.)'"));
EndProcedure // FillObjectTypeName

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetObjectRefList(pObjectTypeName, pHotel)
	vQ = New Query();    
	vCondition = "";
	vUseHotel = Metadata.Catalogs[pObjectTypeName].Attributes.Contains(Metadata.Catalogs.Hotels);
	vQ.Text = StrTemplate("SELECT
							|	%1.Ref AS Ref
							|FROM
							|	Catalog.%1 AS %1
							|WHERE
							|	NOT %1.IsFolder
							|	AND NOT %1.DeletionMark
							|	%2", 
							pObjectTypeName, ?(vUseHotel, "AND (%1.Hotel = &qHotel) Or (%1.Hotel = Value(Catalog.Hotel.EmptyRef))", ""));     
	vQ.SetParameter("qHotel", pHotel);
	vObjectRefList = New ValueList;
	vObjectRefList.LoadValues(vQ.Execute().Unload().UnloadColumn("Ref"));
	Return vObjectRefList;
EndFunction // GetObjectRefList

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterChoiceByObjectTypeName(pValue, pExtraParams) Export 
	If pValue <> Undefined And ValueIsFilled(pValue.Value) Then
		vNotifyDescription = New NotifyDescription("AfterInputByObjectTypeName", ThisObject, New Structure("ObjectRef, ObjectTypeName", pValue.Value, pExtraParams));
		ShowInputString(vNotifyDescription, "", NStr("en = 'Specify the object code in the external system'; de = 'Geben Sie den Objektcode im externen System an'; ru = 'Укажите код объекта во внешней системе'"), 0, False);	
	EndIf;
EndProcedure //AfterChoiceByObjectTypeName

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterInputByObjectTypeName(pValue, pExtraParams) Export 
	If pValue <> Undefined And ValueIsFilled(pValue) Then
		CreateExternalSystemsObjectCodesMappings(pValue, pExtraParams.ObjectRef, pExtraParams.ObjectTypeName, Hotel, InteractionID, Object.InteractionParameters);
		Items.ExternalSystemIntegrationData.Refresh();
	EndIf;
EndProcedure //AfterChoiceByObjectTypeName

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure CreateExternalSystemsObjectCodesMappings(pObjectExternalCode, pObjectRef, pObjectTypeName, pHotel, pInteractionID, pInteractionParameters)
	If pObjectTypeName = "ReservationStatuses" Or pObjectTypeName = "AccommodationStatuses" Then
		InformationRegisters.ExternalSystemIntegrationData.WriteData(pInteractionParameters, pObjectTypeName, "Code", pObjectRef,, pObjectExternalCode, pObjectExternalCode);
	Else
		vRecordManager = InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
		vRecordManager.Hotel = pHotel;
		vRecordManager.ExternalSystemCode = pInteractionID;
		vRecordManager.ObjectTypeName = pObjectTypeName;  
		vRecordManager.ObjectExternalCode = pObjectExternalCode;
		vRecordManager.ObjectRef = pObjectRef;
		vRecordManager.Write(True);	
	EndIf;
EndProcedure // CreateExternalSystemsObjectCodesMappings         

// -----------------------------------------------------------------------------
&AtClient
Procedure SetParameters(pObjectTypeName)  
	If ValueIsFilled(Object.InteractionParameters) Then
		ExternalSystemIntegrationData.Parameters.SetParameterValue("qHotel", Hotel);      
		ExternalSystemIntegrationData.Parameters.SetParameterValue("qExternalSystem", Object.InteractionParameters);
		ExternalSystemIntegrationData.Parameters.SetParameterValue("qExternalSystemCode", InteractionID);
		ExternalSystemIntegrationData.Parameters.SetParameterValue("qObjectTypeName", pObjectTypeName);
	Else
		ExternalSystemIntegrationData.Parameters.SetParameterValue("qHotel", PredefinedValue("Catalog.Hotels.EmptyRef"));
		ExternalSystemIntegrationData.Parameters.SetParameterValue("qExternalSystem", Object.InteractionParameters);
		ExternalSystemIntegrationData.Parameters.SetParameterValue("qExternalSystemCode", "");
		ExternalSystemIntegrationData.Parameters.SetParameterValue("qObjectTypeName", pObjectTypeName);	
	EndIf;        
EndProcedure // SetParameters

// -----------------------------------------------------------------------------
&AtServer
Function IsInRoleAtServer(pRole)
	Return IsInRole(pRole);
EndFunction // IsInRoleAtServer

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
	
EndProcedure // SetupBackgroundJobSchedule_AfterInput

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
EndProcedure // SetupBackgroundJobSchedule_AtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure Save_AtServer()
	If CheckFilling() Then
		SaveInteractionParameters();
								
		// Save DP parameters
		Obj = FormAttributeToValue("Object");
		Obj.pmSaveDataProcessorAttributes();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadInteractionParameters()
		
	If Not ValueIsFilled(Object.InteractionParameters) Then
		Return;
	EndIf;
	
	Hotel						= Object.InteractionParameters.Hotel;
	InteractionID				= Object.InteractionParameters.InteractionID;
	Debug   					= Object.InteractionParameters.DebugMode;
	Active 						= Object.InteractionParameters.IsActive;
	MaxLogLenght				= Object.InteractionParameters.MaxLogLenght;
	LastFullSynchronizationTime = Object.InteractionParameters.LastFullSynchronizationTime;
	WSHost						= Object.InteractionParameters.WSHost;
	HttpServer					= Object.InteractionParameters.HttpServer;
	OAuth_ClientID				= Object.InteractionParameters.OAuth_ClientID;
	OAuth_ClientSecret			= Object.InteractionParameters.OAuth_ClientSecret;
	OAuth_AccessToken			= Object.InteractionParameters.OAuth_AccessToken;
	OAuth_RefreshToken			= Object.InteractionParameters.OAuth_RefreshToken;
	ActiveToDate				= Object.InteractionParameters.ActiveToDate; 
	OrderType					= Object.InteractionParameters.OrderType;
EndProcedure // LoadInteractionParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveInteractionParameters()
	
	If Not ValueIsFilled(Object.InteractionParameters) Then
		Return;
	EndIf;
		
	vIntParObj								= Object.InteractionParameters.GetObject();
	vIntParObj.Hotel						= Hotel;
	vIntParObj.InteractionID				= InteractionID;
	vIntParObj.DebugMode					= Debug;  
	vIntParObj.IsActive						= Active;
	vIntParObj.MaxLogLenght					= MaxLogLenght;
	vIntParObj.LastFullSynchronizationTime	= LastFullSynchronizationTime;
	vIntParObj.WSHost						= WSHost;  
	vIntParObj.HttpServer					= HttpServer;
	vIntParObj.OAuth_ClientID				= OAuth_ClientID;
	vIntParObj.OAuth_ClientSecret			= OAuth_ClientSecret;
	vIntParObj.OAuth_AccessToken			= OAuth_AccessToken;
	vIntParObj.OAuth_RefreshToken			= OAuth_RefreshToken;
	vIntParObj.ActiveToDate					= ActiveToDate;
	vIntParObj.OrderType					= OrderType;
	vIntParObj.Write();
EndProcedure // SaveInteractionParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionsExecuteAtServer()	
	vObj = FormAttributeToValue("Object");
	vObj.pmRun();
	ValueToFormAttribute(vObj,"Object");
EndProcedure // ActionsExecuteAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure UpdateAccessTokenAtServer()
	Obj = FormAttributeToValue("Object");
	vMessage = "";
	If Obj.CheckAccessToken(vMessage) Then 
		LoadInteractionParameters(); 
	Else
		tcCommonFunctionOnClientServer.TextMessage(vMessage);
	EndIf;
EndProcedure // UpdateAccessToken

// -----------------------------------------------------------------------------
&AtServer
Procedure RefreshDisplay()
	Items.Group_Settings_WebService.Enabled = Object.UseWebService;
	Items.Group_Settings_MedicalRecordsHistory.Enabled = Object.UseMedicalRecordHistory;
	Items.Group_Settings_Bus.Enabled = Object.UseBus;
	Items.Group_Settings_Rendered_Paid_Services.Enabled = Object.UseStatisticsRenderedAndPaidServices;
EndProcedure // RefreshDisplay

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriodAfterChoice(pPeriod, pExtraParams) Export
	If pPeriod <> Undefined Then
		PeriodFrom = pPeriod.StartDate;
		PeriodTo = EndOfDay(pPeriod.EndDate);
	EndIf;
EndProcedure // ChoosePeriodAfterChoice

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionsUnloadAtServer()
	If CheckFilling() Then
		vObj = FormAttributeToValue("Object");
		vObj.pmRun(New Structure("PeriodFrom, PeriodTo, ReservationsList, UnloadType", PeriodFrom, PeriodTo, ReservationsList, UnloadType), True);
		ValueToFormAttribute(vObj, "Object");
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Processing completed!';ru='Выполнение процедуры закончено!';de='Die Prozedur ist abgeschlossen!'"));
	EndIf;
EndProcedure // ActionsUnloadAtServer

#EndRegion 