#Region FormEventHandlers

// ----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Load DP parameters
	Obj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If ThisForm.Parameters.Property("DataProcessor", vDataProcessor) Then
		Obj.DataProcessor = vDataProcessor;
	Else
		vDataProcessor = Catalogs.DataProcessors.FindByAttribute("Processing","WubookWizard");
		If vDataProcessor = Catalogs.DataProcessors.EmptyRef() Then
			newDP = Catalogs.DataProcessors.CreateItem();
			newDP.Description = "Wubook Connection";
			newDP.Key = "WubookConnect";
			newDP.Processing = "WubookWizard";
			newDP.Write();
			vDataProcessor = newDP.Ref;
		EndIf;
	EndIf;
	
	vInteractionParameters = Catalogs.ExternalSystemInteractions.EmptyRef();
	If Parameters.Property("InteractionParameters",vInteractionParameters) Then
		Obj.InteractionParameters = vInteractionParameters;
	EndIf;
	Obj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(Obj,"Object");
	
	
	If  IsInRoleAtServer("Administrator") And Not(vDataProcessor = Undefined) Then
		If IsBlankString(vDataProcessor.Key) Then
			dpObj = vDataProcessor.GetObject();
			dpObj.Key = "WubookConnect";
			dpObj.Write();
		EndIf;	
		SetupBackgroundJobSchedule_AtServer(True);
		
		If UseBackgroundJob Then
			Items.Text_BackgroundJobInfo.Title = NStr("en='Background job is configured and started'; ru='Фоновое задание настроено и запущено'; de='Ein Hintergrundjob ist konfiguriert und läuft'");
		Else 
			Items.Text_BackgroundJobInfo.Title = NStr("en='Background job not started'; ru='Фоновое задание не запущено'; de='Ein Hintergrundjob nicht läuft'");
		EndIf;
	Else
		Items.MainPage_BackgroundJob.Visible = False;
		Items.Page_ConnectionSettings.ReadOnly = True;
	EndIf;
	
	ManualSyncPeriod = 400;
	
	If Object.SyncPeriod <= 0 Then
		Object.SyncPeriod = 400;
	EndIf;
		
	If ValueIsFilled(vInteractionParameters) Then
		Object.InteractionParameters = vInteractionParameters;
	Else
		Object.InteractionParameters = ChannelManagers.GetInteractionParameters(Object.Hotel, Object.Allotment, WuBook.GetSettings());
	EndIf;
	
	
	TablesLoaded = False;
	If ValueIsFilled(Object.InteractionParameters) Then
		ActivateInteractionParameters = Object.InteractionParameters.IsActive;
		Debug = Object.InteractionParameters.DebugMode;
		HTTPUseSSL = Object.InteractionParameters.HttpUseSsl;
	EndIf;
	
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// ----------------------------------------------------------------------------
&AtClient
Procedure UsePushOnChange(pItem)
	If ValueIsFilled(Object.WuBookPushNotificationUrl) Then
		UsePush = True;
	Else
		UsePush = False;
		tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Fill Push notification url'; ru = 'Заполните cсылку для push-уведомлений'; de = 'Füllen Sie die Push-Benachrichtigungs-URL aus'"));
	EndIf;
EndProcedure // UsePushOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure PeriodSyncOnChange(pItem)
	If PeriodSync.StartDate < BegOfDay(CurrentDate()) Then
		PeriodSync.StartDate = BegOfDay(CurrentDate());
		tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Start date cannot be less than current date! Start date was changed to current date.'; ru = 'Начало периода не может быть меньше текущей даты! Начало периода было изменено на текущую дату.'"));
	EndIf;
	If (BegOfDay(PeriodSync.EndDate) - BegOfDay(PeriodSync.StartDate)) / (24*60*60) > 400 Then
		PeriodSync.EndDate = BegOfDay(PeriodSync.StartDate) + 24*60*60*399;
		tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'WuBook max accepts 400 days! End date was changed'; ru = 'WuBook принимает данные только на ближайшие 400 дней! Конец периода был изменён'"));
	EndIf;
EndProcedure // PeriodSyncOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure FullSyncPeriodOnChange(pItem)
	If Object.FullSyncPeriod > 24 Then
		Object.FullSyncPeriod = 24;
	EndIf;	
EndProcedure // FullSyncPeriodOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure InteractionParametersOnChange(pItem)
	InteractionParametersOnChangeAtServer();
EndProcedure // InteractionParametersOnChange

// ----------------------------------------------------------------------------
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

// ----------------------------------------------------------------------------
&AtClient
Procedure ManualSyncPeriodOnChange(pItem)
	If ManualSyncPeriod > 400 Then
		ManualSyncPeriod = 400;
		tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'WuBook max accepts 400 days!'; ru = 'WuBook принимает данные только на ближайшие 400 дней!'"));
	ElsIf ManualSyncPeriod <= 0 Then
		ManualSyncPeriod = 1;	
	EndIf;
EndProcedure // ManualSyncPeriodOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure SyncPeriodOnChange(pItem)
	If Object.SyncPeriod > 400 Then
		Object.SyncPeriod = 400;
		tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'WuBook max accepts 400 days!'; ru = 'WuBook принимает данные только на ближайшие 400 дней!'"));
	ElsIf Object.SyncPeriod <= 0 Then
		Object.SyncPeriod = 1;	
	EndIf;
EndProcedure // SyncPeriodOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure Group_PagesOnCurrentPageChange(pItem, pCurrentPage)
	If pCurrentPage.Name <> "Page_ConnectionSettings" Then
		If ValueIsFilled(Object.Login) and ValueIsFilled(Object.Password) and ValueIsFilled(Object.HotelCode) Then
			If Not TablesLoaded Then
				TablesLoaded = True;
				UpdateTables();
			EndIf;
		Else
			Items.Group_Pages.pCurrentPage = Items.Page_ConnectionSettings;
			tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Fill all connection settings!'; ru = 'Заполните все настройки подключения!'")); //#Translate
		EndIf;
	EndIf;
EndProcedure // Group_PagesOnCurrentPageChange

// ----------------------------------------------------------------------------
&AtClient
Procedure Group_Main_PagesOnCurrentPageChange(pItem, pCurrentPage)
	If pCurrentPage.Name <> "MainPage_Settings" Then
		If ValueIsFilled(Object.Login) and ValueIsFilled(Object.Password) and ValueIsFilled(Object.HotelCode) Then
			If Not TablesLoaded Then
				TablesLoaded = True;
				UpdateTables();
			EndIf;
		Else
			tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Fill all connection settings!'; ru = 'Заполните все настройки подключения!'")); //#Translate
		EndIf;
	EndIf;
EndProcedure // Group_Main_PagesOnCurrentPageChange

// ----------------------------------------------------------------------------
&AtClient
Procedure HotelOnChange(pItem)
	HotelOnChangeAtServer();
	InteractionParametersOnChangeAtServer();
EndProcedure // HotelOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure AllotmentOnChange(pItem)
	AllotmentOnChangeAtServer();
	InteractionParametersOnChangeAtServer();
EndProcedure // AllotmentOnChange

#EndRegion

#Region FormTableItemsEventHandlers

// ----------------------------------------------------------------------------
&AtClient
Procedure TablesBeforeDeleteRow(pItem, pCancel)
	If ValueIsFilled(Object.InteractionParameters) Then
		vCode			= "";
		vFillingField	= "";
		vObjectTypeName	= Undefined;
		If 		pItem.Name = "Currencies" Then
			vCode			= pItem.CurrentData.Code;
			vFillingField	= pItem.CurrentData.Currency;
			vObjectTypeName	= "Currencies";
		ElsIf	pItem.Name = "RoomRates" Then
			vCode			= pItem.CurrentData.Code;
			vFillingField	= pItem.CurrentData.RoomRate;
			vObjectTypeName	= "RoomRates";
		ElsIf	pItem.Name = "RoomTypes" Then
			vCode			= pItem.CurrentData.Code;
			vFillingField	= pItem.CurrentData.RoomType;
			vObjectTypeName	= "RoomTypes";
		ElsIf	pItem.Name = "Services" Then
			vCode			= pItem.CurrentData.Code;
			vFillingField	= pItem.CurrentData.Service;
			vObjectTypeName	= "Services";
		ElsIf	pItem.Name = "Statuses" Then
			vCode			= pItem.CurrentData.Code;
			vFillingField	= pItem.CurrentData.Status;
			vObjectTypeName	= "ReservationStatuses";
		ElsIf	pItem.Name = "Agents" Then
			vCode			= pItem.CurrentData.Code;
			vFillingField	= pItem.CurrentData.Agent;
			vObjectTypeName	= "Customers";
		ElsIf	pItem.Name = "PaymentMethods" Then
			vCode			= pItem.CurrentData.Code;
			vFillingField	= pItem.CurrentData.PaymentMethod;
			vObjectTypeName	= "PaymentMethods";
		ElsIf	pItem.Name = "Restrictions" Then
			vCode			= pItem.CurrentData.Code;
			vFillingField	= pItem.CurrentData.RoomRate;
			vObjectTypeName	= "RestrictionPlan";
		EndIf;		
		DeleteExternalSystemRow(vCode, vFillingField, vObjectTypeName, Object.Hotel, Object.InteractionParameters);
		If	pItem.Name = "RoomTypes" Then
			vCode			= pItem.CurrentData.Code;
			vFillingField	= pItem.CurrentData.Accommodation;
			vObjectTypeName	= "AccommodationTemplates";
			DeleteExternalSystemRow(vCode, vFillingField, vObjectTypeName, Object.Hotel, Object.InteractionParameters);
		EndIf;
	EndIf;
EndProcedure // TablesBeforeDeleteRow

// ----------------------------------------------------------------------------
&AtClient
Procedure CodeTextEditEnd(pItem, pText, pChoiceData, pDataGetParameters, pStandardProcessing)
	If ValueIsFilled(Object.InteractionParameters) Then
		vOldCode			= "";
		vOldFillingField	= "";
		vCode				= pText;
		vFillingField		= "";
		vObjectTypeName	= Undefined;
		vIsVirtual = False;
		If 		pItem.Parent.Name = "Currencies" Then
			vOldCode			= pItem.Parent.CurrentData.Code;
			vOldFillingField	= pItem.Parent.CurrentData.Currency;
			vObjectTypeName	= "Currencies";
		ElsIf	pItem.Parent.Name = "RoomRates" Then
			vOldCode			= pItem.Parent.CurrentData.Code;
			vOldFillingField	= pItem.Parent.CurrentData.RoomRate;
			vIsVirtual			= pItem.Parent.CurrentData.IsVirtual;
			vObjectTypeName	= "RoomRates";
		ElsIf	pItem.Parent.Name = "RoomTypes" Then
			vOldCode			= pItem.Parent.CurrentData.Code;
			vOldFillingField	= pItem.Parent.CurrentData.RoomType;
			vIsVirtual			= pItem.Parent.CurrentData.IsVirtual;
			vObjectTypeName	= "RoomTypes";
		ElsIf	pItem.Parent.Name = "Services" Then
			vOldCode			= pItem.Parent.CurrentData.Code;
			vOldFillingField	= pItem.Parent.CurrentData.Service;
			vObjectTypeName	= "Services";
		ElsIf	pItem.Parent.Name = "Statuses" Then
			vOldCode			= pItem.Parent.CurrentData.Code;
			vOldFillingField	= pItem.Parent.CurrentData.Status;
			vObjectTypeName	= "ReservationStatuses";
		ElsIf	pItem.Parent.Name = "Agents" Then
			vOldCode			= pItem.Parent.CurrentData.Code;
			vOldFillingField	= pItem.Parent.CurrentData.Agent;
			vObjectTypeName	= "Customers";
		ElsIf	pItem.Parent.Name = "PaymentMethods" Then
			vOldCode			= pItem.Parent.CurrentData.Code;
			vOldFillingField	= pItem.Parent.CurrentData.PaymentMethod;
			vObjectTypeName	= "PaymentMethods";
		ElsIf	pItem.Parent.Name = "GuaranteeTypes" Then
			vOldCode			= pItem.Parent.CurrentData.Code;
			vOldFillingField	= pItem.Parent.CurrentData.GuaranteeType;
			vObjectTypeName	= "GuaranteeTypes";
		EndIf;		
		ChangeExternalSystemRow(vOldCode, vOldFillingField, vCode, vOldFillingField, vObjectTypeName, Object.Hotel, Object.InteractionParameters, vIsVirtual);
	EndIf;
EndProcedure // CodeTextEditEnd

// ----------------------------------------------------------------------------
&AtClient
Procedure RoomTypesRoomTypeClearing(pItem, pStandardProcessing)
	DeleteExternalSystemRow(pItem.Parent.CurrentData.Code, pItem.Parent.CurrentData.RoomType, "RoomTypes", Object.Hotel, Object.InteractionParameters);
EndProcedure // RoomTypesRoomTypeClearing

// ----------------------------------------------------------------------------
&AtClient
Procedure RefChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	If ValueIsFilled(Object.InteractionParameters) Then
		vOldCode			= "";
		vOldFillingField	= "";
		vCode				= "";
		vFillingField		= pSelectedValue;
		vObjectTypeName		= Undefined;
		vIsVirtual			= False;
		If 		pItem.Parent.Name = "Currencies" Then
			vOldCode			= pItem.Parent.CurrentData.Code;
			vOldFillingField	= pItem.Parent.CurrentData.Currency;
			vObjectTypeName	= "Currencies";
		ElsIf	pItem.Parent.Name = "RoomRates" Then
			vOldCode			= pItem.Parent.CurrentData.Code;
			vOldFillingField	= pItem.Parent.CurrentData.RoomRate;
			vObjectTypeName		= "RoomRates";
			vIsVirtual			= pItem.Parent.CurrentData.IsVirtual;
		ElsIf	pItem.Parent.Name = "RoomTypes" Then
			If pItem.Name = "RoomTypesAccommodation" Then
				vOldCode			= pItem.Parent.CurrentData.Code;
				vOldFillingField	= pItem.Parent.CurrentData.Accommodation;
				vObjectTypeName		= "AccommodationTemplates";
			Else
				vOldCode			= pItem.Parent.CurrentData.Code;
				vOldFillingField	= pItem.Parent.CurrentData.RoomType;
				vObjectTypeName	= "RoomTypes";
			EndIf;
			vIsVirtual			= pItem.Parent.CurrentData.IsVirtual;
		ElsIf	pItem.Parent.Name = "Services" Then
			vOldCode			= pItem.Parent.CurrentData.Code;
			vOldFillingField	= pItem.Parent.CurrentData.Service;
			vObjectTypeName	= "Services";
		ElsIf	pItem.Parent.Name = "Statuses" Then
			vOldCode			= pItem.Parent.CurrentData.Code;
			vOldFillingField	= pItem.Parent.CurrentData.Status;
			vObjectTypeName	= "ReservationStatuses";
		ElsIf	pItem.Parent.Name = "Agents" Then
			vOldCode			= pItem.Parent.CurrentData.Code;
			vOldFillingField	= pItem.Parent.CurrentData.Agent;
			vObjectTypeName	= "Customers";
		ElsIf	pItem.Parent.Name = "PaymentMethods" Then
			vOldCode			= pItem.Parent.CurrentData.Code;
			vOldFillingField	= pItem.Parent.CurrentData.PaymentMethod;
			vObjectTypeName	= "PaymentMethods";
		ElsIf	pItem.Parent.Name = "Restrictions" Then
			vOldCode			= pItem.Parent.CurrentData.Code;
			vOldFillingField	= pItem.Parent.CurrentData.RoomRate;
			vObjectTypeName	= "RestrictionPlan";
		EndIf;		
		ChangeExternalSystemRow(vOldCode, vOldFillingField, vOldCode, vFillingField, vObjectTypeName, Object.Hotel, Object.InteractionParameters, vIsVirtual);
	EndIf;
EndProcedure // RefChoiceProcessing

// ----------------------------------------------------------------------------
&AtClient
Procedure RoomRatesRoomRateClearing(pItem, pStandardProcessing)
	DeleteExternalSystemRow(pItem.Parent.CurrentData.Code, pItem.Parent.CurrentData.RoomRate, "RoomRates", Object.Hotel, Object.InteractionParameters);
EndProcedure // RoomRatesRoomRateClearing

// ----------------------------------------------------------------------------
&AtClient
Procedure RoomTypesAccommodationClearing(pItem, pStandardProcessing)
	DeleteExternalSystemRow(pItem.Parent.CurrentData.Code, pItem.Parent.CurrentData.Accommodation, "AccommodationTemplates", Object.Hotel, Object.InteractionParameters);
EndProcedure // RoomTypesAccommodationClearing

// ----------------------------------------------------------------------------
&AtClient
Procedure AgentsAgentClearing(pItem, pStandardProcessing)
	DeleteExternalSystemRow(pItem.Parent.CurrentData.Code, pItem.Parent.CurrentData.Agent, "Customers", Object.Hotel, Object.InteractionParameters);	
EndProcedure // AgentsAgentClearing

#EndRegion

#Region FormCommandsEventHandlers

// ----------------------------------------------------------------------------
&AtClient
Procedure ChangeLastFullSynchronizationTime(pCommand)
	If ValueIsFilled(LastFullSynchronizationTime) and ValueIsFilled(Object.InteractionParameters) Then
		ChangeLastFullSynchronizationTime_AtServer();
	EndIf;
EndProcedure // ChangeLastFullSynchronizationTime

// ----------------------------------------------------------------------------
&AtClient
Procedure FullSyncInventoryOnly(pCommand)
	vResult = SyncAllForPeriod_AtServer(True, False);
	If vResult <> Undefined THen
		For Each vResultRow In vResult.RoomInventory Do 
			If vResultRow.Success Then 
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Success RoomInventory'; ru = 'Успешно RoomInventory'; de = 'Erfolg Zimmer'")); // #Translate
			Else
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Error:'; ru = 'Ошибка:'; de = 'Error:'")); // #Translate
				tcCommonFunctionOnClientServer.UserMessage(vResultRow.Error);
				tcCommonFunctionOnClientServer.UserMessage(vResultRow.Result);
			EndIf;
		EndDo;
		
		For Each vResultRow In vResult.RoomRates Do
			If vResultRow.Success Then 
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Success RoomRates'; ru = 'Успешно RoomRates'; de = 'Erfolg Zimmerpreise'")); // #Translate
			Else
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Error:'; ru = 'Ошибка:'; de = 'Error:'")); // #Translate
				tcCommonFunctionOnClientServer.UserMessage(vResultRow.Error);
				tcCommonFunctionOnClientServer.UserMessage(vResultRow.Result);
			EndIf;
		EndDo;
		
		For Each vResultRow In vResult.RoomRestrictions Do
			If vResultRow.Success Then 
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Success RoomRestrictions'; ru = 'Успешно RoomRestrictions'; de = 'Erfolg Beschränkungen'")); // #Translate
			Else
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Error:'; ru = 'Ошибка:'; de = 'Error:'")); // #Translate
				tcCommonFunctionOnClientServer.UserMessage(vResultRow.Error);
				tcCommonFunctionOnClientServer.UserMessage(vResultRow.Result);
			EndIf;
		EndDo;	
	EndIf;
EndProcedure // FullSyncInventoryOnly

// ----------------------------------------------------------------------------
&AtClient
Procedure FullSyncRoomRatesOnly(pCommand)
	vResult = SyncAllForPeriod_AtServer(False, True);
	If vResult <> Undefined THen
		For Each vResultRow In vResult.RoomInventory Do 
			If vResultRow.Success Then 
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Success RoomInventory'; ru = 'Успешно RoomInventory'; de = 'Erfolg Zimmer'")); // #Translate
			Else
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Error:'; ru = 'Ошибка:'; de = 'Error:'")); // #Translate
				tcCommonFunctionOnClientServer.UserMessage(vResultRow.Error);
				tcCommonFunctionOnClientServer.UserMessage(vResultRow.Result);
			EndIf;
		EndDo;
		
		For Each vResultRow In vResult.RoomRates Do
			If vResultRow.Success Then 
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Success RoomRates'; ru = 'Успешно RoomRates'; de = 'Erfolg Zimmerpreise'")); // #Translate
			Else
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Error:'; ru = 'Ошибка:'; de = 'Error:'")); // #Translate
				tcCommonFunctionOnClientServer.UserMessage(vResultRow.Error);
				tcCommonFunctionOnClientServer.UserMessage(vResultRow.Result);
			EndIf;
		EndDo;
		
		For Each vResultRow In vResult.RoomRestrictions Do
			If vResultRow.Success Then 
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Success RoomRestrictions'; ru = 'Успешно RoomRestrictions'; de = 'Erfolg Beschränkungen'")); // #Translate
			Else
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Error:'; ru = 'Ошибка:'; de = 'Error:'")); // #Translate
				tcCommonFunctionOnClientServer.UserMessage(vResultRow.Error);
				tcCommonFunctionOnClientServer.UserMessage(vResultRow.Result);
			EndIf;
		EndDo;	
	EndIf;
EndProcedure // FullSyncRoomRatesOnly

// ----------------------------------------------------------------------------
&AtClient
Procedure Update(pCommand)
	Save_AtServer();
	UpdateTables();
EndProcedure // Update

// ----------------------------------------------------------------------------
&AtClient                   
Procedure Ping(pCommand)
	Ping_AtServer();
EndProcedure // Ping

// ----------------------------------------------------------------------------
&AtClient
Procedure Save(pCommand)
	Save_AtServer();
EndProcedure // Save

// ----------------------------------------------------------------------------
&AtClient
Procedure SyncChanges(pCommand)	
	vResult = Sync_AtServer(True, True, True, ManualSyncPeriod, False);
	If vResult <> Undefined THen
		For Each vResultRow In vResult.RoomInventory Do 
			If vResultRow.Success Then 
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Success RoomInventory'; ru = 'Успешно RoomInventory'; de = 'Erfolg Zimmer'")); //#Translate
			Else
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Error:'; ru = 'Ошибка:'; de = 'Error:'")); //#Translate
				tcCommonFunctionOnClientServer.UserMessage(vResultRow.Error);
				tcCommonFunctionOnClientServer.UserMessage(vResultRow.Result);
			EndIf;
		EndDo;
		
		For Each vResultRow In vResult.RoomRates Do
			If vResultRow.Success Then 
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Success RoomRates'; ru = 'Успешно RoomRates'; de = 'Erfolg Zimmerpreise'")); //#Translate
			Else
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Error:'; ru = 'Ошибка:'; de = 'Error:'")); //#Translate
				tcCommonFunctionOnClientServer.UserMessage(vResultRow.Error);
				tcCommonFunctionOnClientServer.UserMessage(vResultRow.Result);
			EndIf;
		EndDo;
		
		For Each vResultRow In vResult.RoomRestrictions Do
			If vResultRow.Success Then 
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Success RoomRestrictions'; ru = 'Успешно RoomRestrictions'; de = 'Erfolg Beschränkungen'")); //#Translate
			Else
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Error:'; ru = 'Ошибка:'; de = 'Error:'")); //#Translate
				tcCommonFunctionOnClientServer.UserMessage(vResultRow.Error);
				tcCommonFunctionOnClientServer.UserMessage(vResultRow.Result);
			EndIf;
		EndDo;		
	EndIf;
EndProcedure // SyncChanges

// ----------------------------------------------------------------------------
&AtClient
Procedure SyncInventory(pCommand)
	vResult = Sync_AtServer(True, False, False, ManualSyncPeriod, False);
	If vResult <> Undefined Then
		For Each vResultRow In vResult.RoomInventory Do 
			If vResultRow.Success Then 
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Success RoomInventory'; ru = 'Успешно RoomInventory'; de = 'Erfolg Zimmer'")); //#Translate
			Else
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Error:'; ru = 'Ошибка:'; de = 'Error:'")); //#Translate
				tcCommonFunctionOnClientServer.UserMessage(vResultRow.Error);
				tcCommonFunctionOnClientServer.UserMessage(vResultRow.Result);
			EndIf;
		EndDo;
	EndIf;
EndProcedure // SyncInventory

// ----------------------------------------------------------------------------
&AtClient
Procedure SyncRoomRates(pCommand)
	vResult = Sync_AtServer(False, True, False, ManualSyncPeriod, False);
	If vResult <> Undefined Then
		For Each vResultRow In vResult.RoomRates Do
			If vResultRow.Success Then 
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Success RoomRates'; ru = 'Успешно RoomRates'; de = 'Erfolg Zimmerpreise'")); //#Translate
			Else
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Error:'; ru = 'Ошибка:'; de = 'Error:'")); //#Translate
				tcCommonFunctionOnClientServer.UserMessage(vResultRow.Error);
				tcCommonFunctionOnClientServer.UserMessage(vResultRow.Result);
			EndIf;
		EndDo;
	EndIf;
EndProcedure // SyncRoomRates

// ----------------------------------------------------------------------------
&AtClient
Procedure SyncReservations(pCommand)
	vResult = Sync_AtServer(False, False, False, ManualSyncPeriod, True);
	If vResult <> Undefined Then
				
		For Each vResultRow In vResult.Reservations Do
			If vResultRow.Success Then 
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Success Reservations: " + vResultRow.ReservationsCount + "'; ru = 'Успешно Reservations: " + vResultRow.ReservationsCount + "'; de = 'Erfolg Reservierungen " + vResultRow.ReservationsCount + "'")); //#Translate
				If vResultRow.ReservationsCount > 0 Then
					If vResultRow.Loaded Then
						tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Success Reservations Loaded'; ru = 'Успешно  Reservations Loaded'; de = 'Erfolg Reservations Loaded'")); //#Translate
					Else
						tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'FAILED Reservations Loaded'; ru = 'Провалено  Reservations Loaded'; de = 'Gescheitert Reservations Loaded'")); //#Translate
					EndIf;
					
					If vResultRow.Confirmed Then
						tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Success Reservations Confirmed'; ru = 'Успешно  Reservations Confirmed'; de = 'Erfolg Reservations Confirmed'")); //#Translate
					Else
						tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'FAILED Reservations Confirmed'; ru = 'Провалено  Reservations Confirmed'; de = 'Gescheitert Reservations Confirmed'")); //#Translate
					EndIf;
				EndIf;
			Else
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Error:'; ru = 'Ошибка:'; de = 'Error:'")); //#Translate
				i = 1;
				For Each vErrorRow In vResultRow.Errors Do
					tcCommonFunctionOnClientServer.UserMessage("Error #" + i +"
					|Code: " + vErrorRow.Code + "
					|Type: " + vErrorRow.Type + "
					|Description: " + vErrorRow.Description);
					i = i + 1;
				EndDo;
			EndIf;
		EndDo;
	EndIf;

EndProcedure // SyncReservations

// ----------------------------------------------------------------------------
&AtClient
Procedure SyncAllForPeriod(pCommand)
	vResult = SyncAllForPeriod_AtServer(True, True);
	If vResult <> Undefined THen
		For Each vResultRow In vResult.RoomInventory Do 
			If vResultRow.Success Then 
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Success RoomInventory'; ru = 'Успешно RoomInventory'; de = 'Erfolg Zimmer'")); //#Translate
			Else
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Error:'; ru = 'Ошибка:'; de = 'Error:'")); //#Translate
				tcCommonFunctionOnClientServer.UserMessage(vResultRow.Error);
				tcCommonFunctionOnClientServer.UserMessage(vResultRow.Result);
			EndIf;
		EndDo;
		
		For Each vResultRow In vResult.RoomRates Do
			If vResultRow.Success Then 
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Success RoomRates'; ru = 'Успешно RoomRates'; de = 'Erfolg Zimmerpreise'")); //#Translate
			Else
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Error:'; ru = 'Ошибка:'; de = 'Error:'")); //#Translate
				tcCommonFunctionOnClientServer.UserMessage(vResultRow.Error);
				tcCommonFunctionOnClientServer.UserMessage(vResultRow.Result);
			EndIf;
		EndDo;
		
		For Each vResultRow In vResult.RoomRestrictions Do
			If vResultRow.Success Then 
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Success RoomRestrictions'; ru = 'Успешно RoomRestrictions'; de = 'Erfolg Beschränkungen'")); //#Translate
			Else
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Error:'; ru = 'Ошибка:'; de = 'Error:'")); //#Translate
				tcCommonFunctionOnClientServer.UserMessage(vResultRow.Error);
				tcCommonFunctionOnClientServer.UserMessage(vResultRow.Result);
			EndIf;
		EndDo;
		
	EndIf;
EndProcedure // SyncAllForPeriod

// ----------------------------------------------------------------------------
&AtClient
Procedure SetupBackgroundJobSchedule(pCommand)
	#If Not MobileClient Then
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
	#Else
	 	ShowMessageBox(,"Background job cant be configured on mobile client!");
	#EndIf
EndProcedure // SetupBackgroundJobSchedule

// ----------------------------------------------------------------------------
&AtClient
Procedure MarkAllBookings(pCommand)
	MarkAllBookings_AtServer();
EndProcedure // MarkAllBookings

#EndRegion

#Region Private

// ----------------------------------------------------------------------------
&AtServer
Procedure AllotmentOnChangeAtServer()
	Object.InteractionParameters = ChannelManagers.GetInteractionParameters(Object.Hotel, Object.Allotment, WuBook.GetSettings());
EndProcedure // AllotmentOnChangeAtServer

// ----------------------------------------------------------------------------
&AtServer
Procedure HotelOnChangeAtServer()
	Object.InteractionParameters = ChannelManagers.GetInteractionParameters(Object.Hotel, Object.Allotment, WuBook.GetSettings());
	Object.Login 		= "";
	Object.HotelCode 	= "";
	Object.Password		= "";
EndProcedure // HotelOnChangeAtServer

// ----------------------------------------------------------------------------
&AtServer
Procedure InteractionParametersOnChangeAtServer()
	If ValueIsFilled(Object.InteractionParameters) Then
		Object.Hotel		= Object.InteractionParameters.Hotel;
		Object.Allotment 	= Object.InteractionParameters.Allotment;
		Object.Login 		= Object.InteractionParameters.Login; 
		Object.Password 	= Object.InteractionParameters.Password;
		ActivateInteractionParameters = Object.InteractionParameters.IsActive;
	EndIf;
EndProcedure // InteractionParametersOnChangeAtServer

// ----------------------------------------------------------------------------
&AtServer
Function Ping_AtServer()
	Save_AtServer();
	If CheckFilling() Then
		Object.Token = GetToken(True);
		If Object.Token <> Undefined Then
			tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Successfully connected!'; ru = 'Успешно подключено!'; de = 'Erfolgreich verbunden!'"));
		EndIf;
	EndIf;
	
	Return Undefined;
EndFunction // Ping_AtServer

// ----------------------------------------------------------------------------
&AtServer
Procedure Save_AtServer()  
	SetPrivilegedMode(True);
	SaveTables();
	
	Try
		vObj 			= Object.InteractionParameters.GetObject();
		vObj.IsActive 	= ActivateInteractionParameters;
		vObj.DebugMode 	= Debug;
		vObj.HttpUseSsl = HTTPUseSSL;
		vObj.Write();
	Except
	EndTry;
	
	If Object.UsePush Then
		ActivatePush();
	Else
		ActivatePush(True);
	EndIf;

	// Save DP parameters
	Obj = FormAttributeToValue("Object");
	Obj.pmSaveDataProcessorAttributes();
	SetPrivilegedMode(False);
EndProcedure // Save_AtServer

// ----------------------------------------------------------------------------
&AtServer
Function Sync_AtServer(pSyncInventory, pSyncRates, pSyncRestrictions, pSyncPeriod, pGetReservations)
	Save_AtServer();
	If CheckFilling() Then		
		Return WuBook.SyncChanges(Object.Login, Object.Password, Object.InteractionParameters.WSHost, "1CHOTEL", Object.HotelCode, Object.InteractionParameters, pSyncInventory, pSyncRates, pSyncRestrictions, pSyncPeriod, pGetReservations, Object.GetVacantRoomsAtMidnight); 
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Fill all settings!'; ru = 'Введите все настройки!'; de = 'Füllen Sie alle Einstellungen!'")) //#Translate
	EndIf;
	Return Undefined;	
EndFunction // Sync_AtServer

// ----------------------------------------------------------------------------
&AtServer
Function SyncAllForPeriod_AtServer(pSyncInventory, pSyncRates)
	If CheckFilling() Then
		If ValueIsFilled(PeriodSync.StartDate) and ValueIsFilled(PeriodSync.EndDate) Then 				
			Return WuBook.SyncAllForPeriod(Object.Login, Object.Password, Object.InteractionParameters.WSHost, "1CHOTEL", Object.HotelCode, Object.InteractionParameters, PeriodSync.StartDate, PeriodSync.EndDate, pSyncRates, pSyncInventory, Object.GetVacantRoomsAtMidnight);
		Else
			tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Choose period!'; ru = 'Укажите период!'; de = 'Wählen Sie Zeitraum!'")) //#Translate
		EndIf;
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Fill all settings!'; ru = 'Введите все настройки!'; de = 'Füllen Sie alle Einstellungen!'")) //#Translate
	EndIf;
	Return Undefined;
EndFunction // SyncAllForPeriod_AtServer

// ----------------------------------------------------------------------------
&AtServer
Procedure SetupBackgroundJobSchedule_AtServer(pRead = False)
	If Not CheckFilling() Then
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
		tcCommonFunctionOnClientServer.UserMessage(ErrorDescription());	
	EndTry;
EndProcedure // SetupBackgroundJobSchedule_AtServer

// ----------------------------------------------------------------------------
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

// ----------------------------------------------------------------------------
&AtServer
Procedure MarkAllBookings_AtServer()
	If CheckFilling() Then
		WuBook.MarkAllBookings(Object.InteractionParameters, Object.HotelCode); 
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Fill all settings!'; ru = 'Введите все настройки!'; de = 'Füllen Sie alle Einstellungen!'")) //#Translate
	EndIf;
EndProcedure // MarkAllBookings_AtServer

// ----------------------------------------------------------------------------
&AtServer
Function FillMappingTableWithRoomRates()
	vResult = "";
	RoomRates.Clear();
	vRatesStruc = WuBook.GetPricingPlans(Object.InteractionParameters,Object.HotelCode);
	If TypeOf(vRatesStruc) = Type("String") Then
		vResult = vRatesStruc;
	Else
		If vRatesStruc.StatusID <> "0" Then
			vResult = vRatesStruc.Value;
		Else
			vNewRow 		= vRatesStruc.Value.Add();
			vNewRow.ID 		= "0";
			vNewRow.Name 	= NStr("en = 'Main rate'; ru = 'Главный тариф'; de = 'Haupttarif'");
			vNewRow.Daily 	= "1";

			vQuery = New Query;
			vQuery.Text = 
			"SELECT
			|	ExternalSystemsObjectCodesMappings.ObjectExternalCode,
			|	ExternalSystemsObjectCodesMappings.ObjectRef,
			|	CASE
			|		WHEN ExternalSystemsObjectCodesMappings.ObjectTypeName = ""VirtualRoomRates""
			|			THEN TRUE
			|		ELSE FALSE
			|	END AS IsVirtual
			|FROM
			|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
			|WHERE
			|	ExternalSystemsObjectCodesMappings.Hotel = &qHotel
			|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
			|	AND (ExternalSystemsObjectCodesMappings.ObjectTypeName = ""RoomRates""
			|			OR ExternalSystemsObjectCodesMappings.ObjectTypeName = ""VirtualRoomRates"")";
			vQuery.SetParameter("qHotel", Object.Hotel);
			vQuery.SetParameter("qExternalSystemCode", Object.InteractionParameters.InteractionID);
			vQryResult = vQuery.Execute().Unload();
			
			vRatesTable = vRatesStruc.Value;
			
			vClearArray = New Array;
			For Each vRow In vQryResult Do
				If vRatesTable.Find(vRow.ObjectExternalCode, "ID") = Undefined Then
					vClearArray.Add(vRow);
					DeleteExternalSystemRow(vRow.ObjectExternalCode, vRow.ObjectRef, "RoomRates", Object.Hotel, Object.InteractionParameters);
				EndIf;
			EndDo;
			
			For Each vRow In vClearArray Do
				vQryResult.Delete(vRow);
			EndDo;
			
			For Each vRow In vRatesTable Do
				vNewMapRow = RoomRates.Add();
				vNewMapRow.Code = vRow.ID;
				vNewMapRow.Name = TrimAll(vRow.Name);
				vFindedRoomType = vQryResult.Find(vRow.ID, "ObjectExternalCode");
				If vFindedRoomType <> Undefined Then
					vNewMapRow.RoomRate = vFindedRoomType.ObjectRef;
					vNewMapRow.IsVirtual = vFindedRoomType.IsVirtual;
				EndIf;
				If ValueIsFilled(vRow.Vpid) or vRow.Daily = "0" Then
					vNewMapRow.IsVirtual 	= True;
					vNewMapRow.VirtualBlock = True;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	Return vResult;
EndFunction // FillMappingTableWithRoomRates

// ----------------------------------------------------------------------------
&AtServer
Function FillMappingTableWithRoomTypes()
	vResult = "";
	RoomTypes.Clear();	
	vRoomsStruc = WuBook.FetchRooms(Object.InteractionParameters, Object.HotelCode);
	If TypeOf(vRoomsStruc) = Type("String") Then
		vResult = vRoomsStruc;
	Else
		If vRoomsStruc.StatusID <> "0" Then
			vResult = vRoomsStruc.Value;
		Else
			vQuery = New Query;
			vQuery.Text = 
			"SELECT
			|	ExternalSystemsObjectCodesMappings.ObjectExternalCode,
			|	ExternalSystemsObjectCodesMappings.ObjectRef AS RoomType,
			|	AccTemplatesSelect.ObjectRef AS AccommodationTemplate,
			|	CASE
			|		WHEN ExternalSystemsObjectCodesMappings.ObjectTypeName = ""VirtualRoomTypes""
			|			THEN TRUE
			|		ELSE FALSE
			|	END AS IsVirtual
			|FROM
			|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
			|		LEFT JOIN (SELECT
			|			ExternalSystemsObjectCodesMappings.Hotel AS Hotel,
			|			ExternalSystemsObjectCodesMappings.ExternalSystemCode AS ExternalSystemCode,
			|			ExternalSystemsObjectCodesMappings.ObjectTypeName AS ObjectTypeName,
			|			ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode,
			|			ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef
			|		FROM
			|			InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
			|		WHERE
			|			(ExternalSystemsObjectCodesMappings.ObjectTypeName = ""AccommodationTemplates""
			|					OR ExternalSystemsObjectCodesMappings.ObjectTypeName = ""VirtualAccommodationTemplates"")
			|			AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
			|			AND ExternalSystemsObjectCodesMappings.Hotel = &qHotel) AS AccTemplatesSelect
			|		ON ExternalSystemsObjectCodesMappings.Hotel = AccTemplatesSelect.Hotel
			|			AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = AccTemplatesSelect.ExternalSystemCode
			|			AND ExternalSystemsObjectCodesMappings.ObjectExternalCode = AccTemplatesSelect.ObjectExternalCode
			|WHERE
			|	ExternalSystemsObjectCodesMappings.Hotel = &qHotel
			|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
			|	AND (ExternalSystemsObjectCodesMappings.ObjectTypeName = ""RoomTypes""
			|			OR ExternalSystemsObjectCodesMappings.ObjectTypeName = ""VirtualRoomTypes"")";
			vQuery.SetParameter("qHotel", Object.Hotel);
			vQuery.SetParameter("qExternalSystemCode", Object.InteractionParameters.InteractionID);
			vQuery.SetParameter("qObjectTypeName", "RoomTypes");
			vQuery.SetParameter("qObjectTypeName1", "AccommodationTemplates");
			vQryResult = vQuery.Execute().Unload();
	
			vRoomsTable = vRoomsStruc.Value;
			vClearArray = New Array;
			For Each vRow In vQryResult Do
				If vRoomsTable.Find(vRow.ObjectExternalCode, "ID") = Undefined Then
					vClearArray.Add(vRow);
					DeleteExternalSystemRow(vRow.ObjectExternalCode, vRow.RoomType, "RoomTypes", Object.Hotel, Object.InteractionParameters);
					DeleteExternalSystemRow(vRow.ObjectExternalCode, vRow.AccommodationTemplate, "AccommodationTemplates", Object.Hotel, Object.InteractionParameters);
				EndIf;
			EndDo;
			
			For Each vRow In vClearArray Do
				vQryResult.Delete(vRow);
			EndDo;

			SystemSettingsStorage.Save(Object.InteractionParameters.InteractionID, "RoomsTable" + TrimAll(Object.HotelCode), vRoomsTable, , "1СОтель");
			For Each vRow In vRoomsTable Do
				If IsBlankString(vRow.ID) Then
					Continue;
				EndIf;
				vNewMapRow = RoomTypes.Add();
				vNewMapRow.Code 	= vRow.ID;
				vNewMapRow.Name 	= TrimAll(vRow.Shortname)+" - "+TrimAll(vRow.Name);
				vFindedRoomType = vQryResult.Find(vRow.ID, "ObjectExternalCode");
				If vFindedRoomType <> Undefined Then
					vNewMapRow.RoomType 		= vFindedRoomType.RoomType;
					vNewMapRow.Accommodation 	= vFindedRoomType.AccommodationTemplate;
					vNewMapRow.IsVirtual 		= vFindedRoomType.IsVirtual;
				EndIf;
				If vRow.Subroom <> "0" Then
					vNewMapRow.IsVirtual 	= True;
					vNewMapRow.VirtualBlock = True;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	Return vResult;
EndFunction // FillMappingTableWithRoomTypes

// ----------------------------------------------------------------------------
&AtServer
Procedure FillMappingTableWithReservationStatuses()
	Statuses.Clear();
	vReservationStatusesTable = GetReservationStatusesIDTable();
	
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
	|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = &qObjectTypeName";
	vQuery.SetParameter("qHotel", Object.Hotel);
	vQuery.SetParameter("qExternalSystemCode", Object.InteractionParameters.InteractionID);
	vQuery.SetParameter("qObjectTypeName", "ReservationStatuses");
	vQryResult = vQuery.Execute().Unload();

	For Each vStatus In vReservationStatusesTable Do
		vNewMapRow = Statuses.Add();
		vNewMapRow.Code = vStatus.ID;
		vNewMapRow.Name = TrimAll(vStatus.Name);
		vFindedRoomType = vQryResult.Find(TrimAll(String(vStatus.ID)), "ObjectExternalCode");
		If vFindedRoomType <> Undefined Then
			vNewMapRow.Status = vFindedRoomType.ObjectRef;
		Else
			vNewMapRow.Status = GetReservationStatusesByWubookID(vStatus.ID);
		EndIf;
	EndDo;
EndProcedure // FillMappingTableWithReservationStatuses

// ----------------------------------------------------------------------------
&AtServer
Procedure FillMappingTableWithCustomers()
	UseClient = Object.InteractionParameters.UseClient;
	Agents.Clear();
	vCustomersTable = GetChannelSymbols();
	If TypeOf(vCustomersTable) = Type("ValueTable") Then
		vCustomersTable.Sort("Name");
	Else
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
	|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = &qObjectTypeName";
	vQuery.SetParameter("qHotel", Object.Hotel);
	vQuery.SetParameter("qExternalSystemCode", Object.InteractionParameters.InteractionID);
	vQuery.SetParameter("qObjectTypeName", "Customers");
	vQryResult = vQuery.Execute().Unload();
	
	For Each vCustomer In vCustomersTable Do
		vNewMapRow = Agents.Add();
		vNewMapRow.Code = vCustomer.ID;
		vNewMapRow.Name = vCustomer.Name;
		vFindedRoomType = vQryResult.Find(String(vCustomer.ID), "ObjectExternalCode");
		If vFindedRoomType <> Undefined Then
			vNewMapRow.Agent = vFindedRoomType.ObjectRef;
			vNewMapRow.IsAgent = ?(ValueIsFilled(vNewMapRow.Agent.AgentCommissionType), True, False);
		EndIf;
	EndDo;
	Agents.Sort("Agent DESC, Name");
EndProcedure // FillMappingTableWithCustomers

// ----------------------------------------------------------------------------
&AtServer
Procedure SaveTables()
	If ValueIsFilled(Object.InteractionParameters) Then
		vHotel = Object.Hotel;
		vExternalSystemCode = Object.InteractionParameters.InteractionID;
		WriteExternalSystemRow(RoomRates, 		"RoomRate", 		"RoomRates", 		vHotel, vExternalSystemCode);
		WriteExternalSystemRow(RoomTypes, 		"RoomType", 		"RoomTypes", 		vHotel, vExternalSystemCode);
		WriteExternalSystemRow(RoomTypes, 		"Accommodation", 	"AccommodationTemplates", 		vHotel, vExternalSystemCode);
		WriteExternalSystemRow(Statuses, 		"Status", 			"ReservationStatuses",	 	vHotel, vExternalSystemCode);
		WriteExternalSystemRow(Agents, 			"Agent", 			"Customers", 		vHotel, vExternalSystemCode);
		
		For Each vRow In Agents Do
			// Is agent
			If ValueIsFilled(vRow.Agent) Then
				If vRow.IsAgent Then
					If Not ValueIsFilled(vRow.Agent.AgentCommissionType) Then
						vCustObj = vRow.Agent.GetObject();
						vCustObj.AgentCommissionType = Enums.AgentCommissionTypes.Percent;
						vCustObj.Write();
					EndIf;
				Else
					If ValueIsFilled(vRow.Agent.AgentCommissionType) Then
						vCustObj = vRow.Agent.GetObject();
						vCustObj.AgentCommissionType = Undefined;
						vCustObj.Write();
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		
		vObj 			= Object.InteractionParameters.Ref.GetObject();
		vObj.Login 		= Object.Login;
		vObj.Password 	= Object.Password;
		vObj.Write();
	EndIf;
EndProcedure // SaveTables

// ----------------------------------------------------------------------------
&AtServer
Procedure WriteExternalSystemRow(pTable, pObjectRef, pObjectTypeName, pHotel, pExternalSystemCode)
	If ValueIsFilled(pExternalSystemCode) Then
		For Each vRow In pTable Do
			If ValueIsFilled(vRow[pObjectRef]) Then
				vRecordManager 						= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
				vRecordManager.Hotel 				= pHotel;
				vRecordManager.ExternalSystemCode 	= pExternalSystemCode;
				vRecordManager.ObjectTypeName 		= pObjectTypeName;
				vRecordManager.ObjectExternalCode 	= vRow.Code;
				vRecordManager.ObjectRef 			= vRow[pObjectRef];
				vRecordManager.Read();
				
				If Not vRecordManager.Selected() Then
					vRecordManager.Hotel 				= pHotel;
					vRecordManager.ExternalSystemCode 	= pExternalSystemCode;
					vRecordManager.ObjectTypeName 		= pObjectTypeName;
					vRecordManager.ObjectExternalCode 	= vRow.Code;
					vRecordManager.ObjectRef 			= vRow[pObjectRef];
					vRecordManager.Write(True);
				EndIf;
				
				If pObjectRef = "Agent" Then
					// Is agent
					If vRow.IsAgent Then
						If Not ValueIsFilled(vRow[pObjectRef].AgentCommissionType) Then
							vCustObj = vRow[pObjectRef].GetObject();
							vCustObj.AgentCommissionType = Enums.AgentCommissionTypes.Percent;
							vCustObj.Write();
						EndIf;
					Else
						If ValueIsFilled(vRow[pObjectRef].AgentCommissionType) Then
							vCustObj = vRow[pObjectRef].GetObject();
							vCustObj.AgentCommissionType = Undefined;
							vCustObj.Write();
						EndIf;
					EndIf;
				EndIf;
				
				If vRow.Property("IsVirtual") Then
					If vRow.IsVirtual Then
						vRecordManager 						= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
						vRecordManager.Hotel 				= pHotel;
						vRecordManager.ExternalSystemCode 	= pExternalSystemCode;
						vRecordManager.ObjectTypeName 		= pObjectTypeName;
						vRecordManager.ObjectExternalCode 	= vRow.Code;
						vRecordManager.ObjectRef 			= vRow[pObjectRef];
						vRecordManager.Read();
						
						If vRecordManager.Selected() Then
							vRecordManager.Hotel 				= pHotel;
							vRecordManager.ExternalSystemCode 	= pExternalSystemCode;
							vRecordManager.ObjectTypeName 		= pObjectTypeName;
							vRecordManager.ObjectExternalCode 	= vRow.Code;
							vRecordManager.ObjectRef 			= vRow[pObjectRef];
							vRecordManager.Delete();
						EndIf;
						
						vRecordManager 						= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
						vRecordManager.Hotel 				= pHotel;
						vRecordManager.ExternalSystemCode 	= pExternalSystemCode;
						vRecordManager.ObjectTypeName 		= "Virtual" + pObjectTypeName;
						vRecordManager.ObjectExternalCode 	= vRow.Code;
						vRecordManager.ObjectRef 			= vRow[pObjectRef];
						vRecordManager.Read();
						
						If Not vRecordManager.Selected() Then
							vRecordManager.Hotel 				= pHotel;
							vRecordManager.ExternalSystemCode 	= pExternalSystemCode;
							vRecordManager.ObjectTypeName 		= "Virtual" + pObjectTypeName;
							vRecordManager.ObjectExternalCode 	= vRow.Code;
							vRecordManager.ObjectRef 			= vRow[pObjectRef];
							vRecordManager.Write(True);
						EndIf;
					Else
						vRecordManager 						= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
						vRecordManager.Hotel 				= pHotel;
						vRecordManager.ExternalSystemCode 	= pExternalSystemCode;
						vRecordManager.ObjectTypeName 		= "Virtual" + pObjectTypeName;
						vRecordManager.ObjectExternalCode 	= vRow.Code;
						vRecordManager.ObjectRef 			= vRow[pObjectRef];
						vRecordManager.Read();
						
						If vRecordManager.Selected() Then
							vRecordManager.Hotel 				= pHotel;
							vRecordManager.ExternalSystemCode 	= pExternalSystemCode;
							vRecordManager.ObjectTypeName 		= "Virtual" + pObjectTypeName;
							vRecordManager.ObjectExternalCode 	= vRow.Code;
							vRecordManager.ObjectRef 			= vRow[pObjectRef];
							vRecordManager.Delete();
						EndIf;
						
						vRecordManager 						= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
						vRecordManager.Hotel 				= pHotel;
						vRecordManager.ExternalSystemCode 	= pExternalSystemCode;
						vRecordManager.ObjectTypeName 		= pObjectTypeName;
						vRecordManager.ObjectExternalCode 	= vRow.Code;
						vRecordManager.ObjectRef 			= vRow[pObjectRef];
						vRecordManager.Read();
						
						If Not vRecordManager.Selected() Then
							vRecordManager.Hotel 				= pHotel;
							vRecordManager.ExternalSystemCode 	= pExternalSystemCode;
							vRecordManager.ObjectTypeName 		= pObjectTypeName;
							vRecordManager.ObjectExternalCode 	= vRow.Code;
							vRecordManager.ObjectRef 			= vRow[pObjectRef];
							vRecordManager.Write(True);
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // WriteExternalSystemRow

// ----------------------------------------------------------------------------
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
EndProcedure // DeleteExternalSystemRow

// ----------------------------------------------------------------------------
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
EndProcedure // ChangeExternalSystemRow

// ----------------------------------------------------------------------------
&AtServer
Procedure UpdateTables()
	Object.Token = GetToken();
	FillMappingTableWithRoomRates();
	FillMappingTableWithRoomTypes();
	FillMappingTableWithReservationStatuses();
	FillMappingTableWithCustomers();
	// FillMappingTableWithRestrictions();
	Object.Token = GetToken();
EndProcedure // UpdateTables

// ----------------------------------------------------------------------------
&AtServer
Function IsInRoleAtServer(pRole)
	Return IsInRole(pRole);
EndFunction

// ----------------------------------------------------------------------------
&AtServer
Function GetToken(pForceNew = False)
	vResult = WuBook.GetActiveToken(Object.InteractionParameters, pForceNew);
	If Not ValueIsFilled(vResult.Error) Then
		Return vResult.Token;
	Else
		tcCommonFunctionOnClientServer.UserMessage(vResult.Error);
	EndIf;
	Return Undefined;
EndFunction // GetToken

// ----------------------------------------------------------------------------
&AtServer
Function GetChannelSymbols()
	If Not ValueIsFilled(Object.Token) Then
		Return NStr("en='Check parameters';ru='Проверьте правильность ввода данных';de='Überprüfen Sie die Richtigkeit der Dateneingabe'");
	EndIf;
	
	//XML
	vXMLDocument = New XMLWriter;
	vXMLDocument.SetString();
	vXMLDocument.WriteXMLDeclaration();
	vXMLDocument.WriteStartElement("methodCall");
		vXMLDocument.WriteStartElement("methodName");
			vXMLDocument.WriteText("get_channel_symbols");
		vXMLDocument.WriteEndElement();	
		vXMLDocument.WriteStartElement("params");
			vXMLDocument.WriteStartElement("param");
				vXMLDocument.WriteStartElement("value");
			        vXMLDocument.WriteStartElement("string");
			        	vXMLDocument.WriteText(Object.Token);
					vXMLDocument.WriteEndElement();
				vXMLDocument.WriteEndElement();
			vXMLDocument.WriteEndElement();
		vXMLDocument.WriteEndElement();	
	vXMLDocument.WriteEndElement();
	vXML = vXMLDocument.Close();
	
	vRequestHeaders = New Map;
	vRequestHeaders.Insert("Content-Type", "text/xml;charset=utf-8");
	vRequestHeaders.Insert("Content-Lenght", StrLen(vXML));
	
	vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(Object.InteractionParameters, vRequestHeaders, "xrws", "POST", "get_channel_symbols", vXML, "text/xml;charset=utf-8");
	
	// XML Read
	vReadXML = New XMLReader;
	vReadXML.SetString(vResponse.Body);
	
	vDOMBuilder = New DOMBuilder;
	vDOMDocument = vDOMBuilder.Read(vReadXML);
	
	vReturnTable = New ValueTable;
	vReturnTable.Columns.Add("ID");
	vReturnTable.Columns.Add("Name");
	
	vMemberPostion = vDOMDocument.GetElementByTagName("member");
	If vMemberPostion.Count() > 0 Then
		For Each vMember In vMemberPostion Do
			vNewRow = vReturnTable.Add();
			vNewRow.ID = vMember.FirstChild.TextContent;
			If vMember.LastChild <> Undefined And TypeOf(vMember.LastChild) = Type("DOMElement") Then
				vChilds = vMember.LastChild.GetElementByTagName("string");
				If vChilds.Count() > 0 Then
					vNewRow.Name = vChilds[0].TextContent;
				EndIf;
			EndIf;
		EndDo;
	Else
		Return NStr("en='XML is wrong';ru='Неправильное форматирование XML';de='Falsche XML-Formatierung'");
	EndIf;
	
    WuBook.UpdateInteractionParametersSession(Object.InteractionParameters);
	
	// Add WuBook channel
	vWuBookRow = vReturnTable.Add();
	vWuBookRow.ID = "0";
	vWuBookRow.Name = "WuBook";
	
	// Sort
	vReturnTable.Sort("Name"); 
	
	Return vReturnTable;
EndFunction // GetChannelSymbols

// ----------------------------------------------------------------------------
&AtServer
Function GetReservationStatusesIDTable()
	vReservationsStatusesIDTable = New ValueTable;
	vReservationsStatusesIDTable.Columns.Add("ID");
	vReservationsStatusesIDTable.Columns.Add("Name");
	
	// Confirmed
	vNewStatus = vReservationsStatusesIDTable.Add();
	vNewStatus.ID = 1;
	vNewStatus.Name = NStr("en='Confirmed';ru='Подтверждено';de='Bestätigt'");     //is active, is guaranty true true
		
	// Waiting for approval
	vNewStatus = vReservationsStatusesIDTable.Add();
	vNewStatus.ID = 2;
	vNewStatus.Name = NStr("en='Waiting for approval';ru='В ожидании подтверждения';de='Warten auf die Bestätigung'");	 //is active, is guaranty true false
	
	// Refused
	vNewStatus = vReservationsStatusesIDTable.Add();
	vNewStatus.ID = 3;
	vNewStatus.Name = NStr("en='Refused';ru='Отказ';de='Absage'");	   // is annulation true
	
	// Accepted
	vNewStatus = vReservationsStatusesIDTable.Add();
	vNewStatus.ID = 4;
	vNewStatus.Name = NStr("en='Accepted';ru='Принята';de='Angenommen'");	 // is active, is guaranty true false
	
	// Deleted
	vNewStatus = vReservationsStatusesIDTable.Add();
	vNewStatus.ID = 5;
	vNewStatus.Name = NStr("en='Deleted';ru='Удалена';de='Gelöscht'");	 // is active false
	
	// Deleted with penalty
	vNewStatus = vReservationsStatusesIDTable.Add();
	vNewStatus.ID = 6;
	vNewStatus.Name = NStr("en='Deleted with penalty';ru='Удалена со штрафом';de='Mit Vertragsstrafe gelöscht'");  // is no show true,

	Return vReservationsStatusesIDTable;
EndFunction // GetReservationStatusesIDTable

// ----------------------------------------------------------------------------
&AtServer
Function GetReservationStatusesByWubookID(pID)
	vQry = New Query;
	vQry.Text =
	"SELECT
	|	ReservationStatuses.Ref
	|FROM
	|	Catalog.ReservationStatuses AS ReservationStatuses
	|WHERE
	|	NOT ReservationStatuses.DeletionMark
	|	AND NOT ReservationStatuses.IsFolder";
	If pID = 1 Then
		vQry.Text = vQry.Text + " AND ReservationStatuses.IsActive	AND ReservationStatuses.IsGuaranteed";
	ElsIf pID = 2 Then
		vQry.Text = vQry.Text + " AND ReservationStatuses.IsActive	AND NOT ReservationStatuses.IsGuaranteed";
	ElsIf pID = 3 Then
		vQry.Text = vQry.Text + " AND ReservationStatuses.IsAnnulation";
	ElsIf pID = 4 Then
		vQry.Text = vQry.Text + " AND ReservationStatuses.IsActive	AND NOT ReservationStatuses.IsGuaranteed";
	ElsIf pID = 5 Then
		vQry.Text = vQry.Text + " AND NOT ReservationStatuses.IsActive";
	ElsIf pID = 6 Then
		vQry.Text = vQry.Text + " AND ReservationStatuses.IsNoShow";
	EndIf;
	vQryChoice = vQry.Execute().Select();
	While vQryChoice.Next() Do
		Return vQryChoice.Ref;
	EndDo;
	Return Catalogs.ReservationStatuses.EmptyRef();
EndFunction // GetReservationStatusesByWubookID

// ----------------------------------------------------------------------------
&AtServer
Function ActivatePush(pDeActivate = False)
	//XML
	vXMLDocument = New XMLWriter;
	vXMLDocument.SetString();
	vXMLDocument.WriteXMLDeclaration();
	vXMLDocument.WriteStartElement("methodCall");
		vXMLDocument.WriteStartElement("methodName");
			vXMLDocument.WriteText("push_activation");
		vXMLDocument.WriteEndElement();	
		vXMLDocument.WriteStartElement("params");
			vXMLDocument.WriteStartElement("param");
				vXMLDocument.WriteStartElement("value");
			        vXMLDocument.WriteStartElement("string");
			        	vXMLDocument.WriteText(TrimAll(Object.Token));
					vXMLDocument.WriteEndElement();
				vXMLDocument.WriteEndElement();
			vXMLDocument.WriteEndElement();
			vXMLDocument.WriteStartElement("param");
				vXMLDocument.WriteStartElement("value");
			    	vXMLDocument.WriteStartElement("int");
			        	vXMLDocument.WriteText(TrimAll(Object.HotelCode));                                    
					vXMLDocument.WriteEndElement();
				vXMLDocument.WriteEndElement();
			vXMLDocument.WriteEndElement();
			vXMLDocument.WriteStartElement("param");
				vXMLDocument.WriteStartElement("value");
					vXMLDocument.WriteStartElement("string");
					If pDeActivate Then
						vXMLDocument.WriteText("");
					Else
						vXMLDocument.WriteText(TrimAll(Object.WuBookPushNotificationUrl));
					EndIf;
					vXMLDocument.WriteEndElement();
				vXMLDocument.WriteEndElement();
			vXMLDocument.WriteEndElement();
		vXMLDocument.WriteEndElement();	
	vXMLDocument.WriteEndElement();
	vXML = vXMLDocument.Close();
	
	vRequestHeaders = New Map;
	vRequestHeaders.Insert("Content-Type", "text/xml;charset=utf-8");
	vRequestHeaders.Insert("Content-Lenght", StrLen(vXML));
	
	vResponse 	= Catalogs.ExternalSystemInteractions.SendHTTPRequest(Object.InteractionParameters, vRequestHeaders, "xrws", "POST", "push_activation", vXML, "text/xml;charset=utf-8");
	
	// XML Read
	vReadXML = New XMLReader;
	vReadXML.SetString(vResponse.Body);
	
	vDOMBuilder = New DOMBuilder;
	vDOMDocument = vDOMBuilder.Read(vReadXML);
	
	vReturnStructure = New Structure("StatusID, Value");
	
	vStatusIDPostion = vDOMDocument.GetElementByTagName("int");
	If vStatusIDPostion.Count() > 0 Then
		vStatusID = vStatusIDPostion[0].TextContent;
		vReturnStructure.StatusID = vStatusID;
		
		If vStatusID <> "0" Then
			vValuePostion = vDOMDocument.GetElementByTagName("string");
			vValue = vValuePostion[0].TextContent;
			vReturnStructure.Value = vValue;
		Else
			// Return table
			vReturnTable = New ValueTable;
			vReturnStructure.Value = vReturnTable;
		EndIf;
	Else
		Return NStr("en='XML is wrong';ru='Неправильное форматирование XML';de='Falsche XML-Formatierung'");
	EndIf;
	
	Return vReturnStructure;
EndFunction // ActivatePush

// ----------------------------------------------------------------------------
&AtServer
Procedure ChangeLastFullSynchronizationTime_AtServer()
	vInteractionParameters = Object.InteractionParameters.GetObject();
	vInteractionParameters.LastFullSynchronizationTime = LastFullSynchronizationTime;
	vInteractionParameters.Write();
EndProcedure // ChangeLastFullSynchronizationTime_AtServer

#EndRegion
