
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	// Load DP parameters
	Obj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If ThisForm.Parameters.Property("DataProcessor", vDataProcessor) Then
		Obj.DataProcessor = vDataProcessor;
	Else
		vDataProcessor = Catalogs.DataProcessors.FindByAttribute("Processing","SiteminderWizard");
		If vDataProcessor = Catalogs.DataProcessors.EmptyRef() Then
			newDP = Catalogs.DataProcessors.CreateItem();
			newDP.Description = "Siteminder";
			newDP.Key = "Siteminder";
			newDP.Processing = "SiteminderWizard";
			newDP.Write();
			vDataProcessor = newDP.Ref;
		EndIf;
	EndIf;
	vInteractionParameters = Catalogs.ExternalSystemInteractions.EmptyRef();
	If Parameters.Property("InteractionParameters", vInteractionParameters) Then
		Obj.InteractionParameters = vInteractionParameters;
	EndIf;
	Obj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(Obj,"Object");
	
	If Not ValueIsFilled(Object.InteractionParameters) Then
		Object.InteractionParameters = ChannelManagers.GetInteractionParameters(Object.Hotel, Object.Allotment, Siteminder.GetSettings());
	EndIf;
	SetSettings();
	InteractionParametersOnChangeAtServer();
	
	If  IsInRoleAtServer("Administrator") And Not(vDataProcessor = Undefined) Then
		If IsBlankString(vDataProcessor.Key) Then
			dpObj = vDataProcessor.GetObject();
			dpObj.Key = "Siteminder";
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
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to configure background job!'; ru='Нет прав для настройки фонового задания!'; de='Einen Hintergrundjob Einstellung ist nicht zulässig!'"));
	EndIf;
	
	ManualSyncPeriod = 400;
	
	If Object.SyncPeriod <= 0 Then
		Object.SyncPeriod = 400;
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(Cancel)
	FillTables();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AllotmentOnChange(Item)
	AllotmentOnChangeAtServer();
	InteractionParametersOnChangeAtServer();
EndProcedure

&AtClient
Procedure HotelOnChange(Item)
	HotelOnChangeAtServer();
	InteractionParametersOnChangeAtServer();
EndProcedure

&AtClient
Procedure InteractionParametersOnChange(Item)
	InteractionParametersOnChangeAtServer();
EndProcedure

&AtClient
Procedure TablesBeforeDeleteRow(Item, Cancel)
	If ValueIsFilled(Object.InteractionParameters) Then
		vCode			= "";
		vFillingField	= "";
		vObjectTypeName	= Undefined;
		If 		Item.Name = "Currencies" Then
			vCode			= Item.CurrentData.Code;
			vFillingField	= Item.CurrentData.Currency;
			vObjectTypeName	= "Currencies";
		ElsIf	Item.Name = "RoomRates" Then
			vCode			= Item.CurrentData.Code;
			vFillingField	= Item.CurrentData.RoomRate;
			vObjectTypeName	= "RoomRates";
		ElsIf	Item.Name = "RoomTypes" Then
			vCode			= Item.CurrentData.Code;
			vFillingField	= Item.CurrentData.RoomType;
			vObjectTypeName	= "RoomTypes";
		ElsIf	Item.Name = "Services" Then
			vCode			= Item.CurrentData.Code;
			vFillingField	= Item.CurrentData.Service;
			vObjectTypeName	= "Services";
		ElsIf	Item.Name = "Statuses" Then
			vCode			= Item.CurrentData.Code;
			vFillingField	= Item.CurrentData.Status;
			vObjectTypeName	= "ReservationStatuses";
		ElsIf	Item.Name = "Agents" Then
			vCode			= Item.CurrentData.Code;
			vFillingField	= Item.CurrentData.Agent;
			vObjectTypeName	= "Customers";
		ElsIf	Item.Name = "PaymentMethods" Then
			vCode			= Item.CurrentData.Code;
			vFillingField	= Item.CurrentData.PaymentMethod;
			vObjectTypeName	= "PaymentMethods";
		ElsIf	Item.Name = "GuaranteeTypes" Then
			vCode			= Item.CurrentData.Code;
			vFillingField	= Item.CurrentData.GuaranteeType;
			vObjectTypeName	= "GuaranteeTypes";
		ElsIf Item.Name = "RoomMappingRoomType" Then
			vCode			= Item.Parent.CurrentData.RoomTypeCode;
			vFillingField	= Item.Parent.CurrentData.RoomType;
			vObjectTypeName	= "RoomTypes";	
		ElsIf Item.Name = "RoomMappingRoomRate" Then
			vCode			= Item.Parent.CurrentData.RoomRateCode;
			vFillingField	= Item.Parent.CurrentData.RoomRate;
			vObjectTypeName	= "RoomRates";
		EndIf;		
		DeleteExternalSystemRow(vCode, vFillingField, vObjectTypeName, Object.Hotel, Object.InteractionParameters);
	EndIf;
EndProcedure

&AtClient
Procedure CodeTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	If ValueIsFilled(Object.InteractionParameters) Then
		vOldCode			= "";
		vOldFillingField	= "";
		vCode				= Text;
		vFillingField		= "";
		vObjectTypeName	= Undefined;
		If 		Item.Parent.Name = "Currencies" Then
			vOldCode			= Item.Parent.CurrentData.Code;
			vOldFillingField	= Item.Parent.CurrentData.Currency;
			vObjectTypeName	= "Currencies";
		ElsIf	Item.Parent.Name = "RoomRates" Then
			vOldCode			= Item.Parent.CurrentData.Code;
			vOldFillingField	= Item.Parent.CurrentData.RoomRate;
			vObjectTypeName	= "RoomRates";
		ElsIf	Item.Parent.Name = "RoomTypes" Then
			vOldCode			= Item.Parent.CurrentData.Code;
			vOldFillingField	= Item.Parent.CurrentData.RoomType;
			vObjectTypeName	= "RoomTypes";
		ElsIf	Item.Parent.Name = "Services" Then
			vOldCode			= Item.Parent.CurrentData.Code;
			vOldFillingField	= Item.Parent.CurrentData.Service;
			vObjectTypeName	= "Services";
		ElsIf	Item.Parent.Name = "Statuses" Then
			vOldCode			= Item.Parent.CurrentData.Code;
			vOldFillingField	= Item.Parent.CurrentData.Status;
			vObjectTypeName	= "ReservationStatuses";
		ElsIf	Item.Parent.Name = "Agents" Then
			vOldCode			= Item.Parent.CurrentData.Code;
			vOldFillingField	= Item.Parent.CurrentData.Agent;
			vObjectTypeName	= "Customers";
		ElsIf	Item.Parent.Name = "PaymentMethods" Then
			vOldCode			= Item.Parent.CurrentData.Code;
			vOldFillingField	= Item.Parent.CurrentData.PaymentMethod;
			vObjectTypeName	= "PaymentMethods";
		ElsIf	Item.Parent.Name = "GuaranteeTypes" Then
			vOldCode			= Item.Parent.CurrentData.Code;
			vOldFillingField	= Item.Parent.CurrentData.GuaranteeType;
			vObjectTypeName	= "GuaranteeTypes";
		ElsIf Item.Name = "RoomMappingRoomType" Then
			vOldCode			= Item.Parent.CurrentData.RoomTypeCode;
			vOldFillingField	= Item.Parent.CurrentData.RoomType;
			vObjectTypeName	= "RoomTypes";	
		ElsIf Item.Name = "RoomMappingRoomRate" Then
			vOldCode			= Item.Parent.CurrentData.RoomRateCode;
			vOldFillingField	= Item.Parent.CurrentData.RoomRate;
			vObjectTypeName	= "RoomRates";
		EndIf;		
		ChangeExternalSystemRow(vOldCode, vOldFillingField, vCode, vOldFillingField, vObjectTypeName, Object.Hotel, Object.InteractionParameters);
	EndIf;
EndProcedure

&AtClient
Procedure RefChoiceProcessing(Item, SelectedValue, StandardProcessing)
	If ValueIsFilled(Object.InteractionParameters) Then
		vOldCode			= "";
		vOldFillingField	= "";
		vCode				= "";
		vFillingField		= SelectedValue;
		vObjectTypeName	= Undefined;
		If 		Item.Parent.Name = "Currencies" Then
			vOldCode			= Item.Parent.CurrentData.Code;
			vOldFillingField	= Item.Parent.CurrentData.Currency;
			vObjectTypeName	= "Currencies";
		ElsIf	Item.Parent.Name = "RoomRates" Then
			vOldCode			= Item.Parent.CurrentData.Code;
			vOldFillingField	= Item.Parent.CurrentData.RoomRate;
			vObjectTypeName	= "RoomRates";
		ElsIf	Item.Parent.Name = "RoomTypes" Then
			vOldCode			= Item.Parent.CurrentData.Code;
			vOldFillingField	= Item.Parent.CurrentData.RoomType;
			vObjectTypeName	= "RoomTypes";
		ElsIf	Item.Parent.Name = "Services" Then
			vOldCode			= Item.Parent.CurrentData.Code;
			vOldFillingField	= Item.Parent.CurrentData.Service;
			vObjectTypeName	= "Services";
		ElsIf	Item.Parent.Name = "Statuses" Then
			vOldCode			= Item.Parent.CurrentData.Code;
			vOldFillingField	= Item.Parent.CurrentData.Status;
			vObjectTypeName	= "ReservationStatuses";
		ElsIf	Item.Parent.Name = "Agents" Then
			vOldCode			= Item.Parent.CurrentData.Code;
			vOldFillingField	= Item.Parent.CurrentData.Agent;
			vObjectTypeName	= "Customers";
		ElsIf	Item.Parent.Name = "PaymentMethods" Then
			vOldCode			= Item.Parent.CurrentData.Code;
			vOldFillingField	= Item.Parent.CurrentData.PaymentMethod;
			vObjectTypeName	= "PaymentMethods";
		ElsIf	Item.Parent.Name = "GuaranteeTypes" Then
			vOldCode			= Item.Parent.CurrentData.Code;
			vOldFillingField	= Item.Parent.CurrentData.GuaranteeType;
			vObjectTypeName	= "GuaranteeTypes";
		ElsIf Item.Name = "RoomMappingRoomType" Then
			vOldCode			= Item.Parent.CurrentData.RoomTypeCode;
			vOldFillingField	= Item.Parent.CurrentData.RoomType;
			vObjectTypeName	= "RoomTypes";	
		ElsIf Item.Name = "RoomMappingRoomRate" Then
			vOldCode			= Item.Parent.CurrentData.RoomRateCode;
			vOldFillingField	= Item.Parent.CurrentData.RoomRate;
			vObjectTypeName	= "RoomRates";
		EndIf;		
		ChangeExternalSystemRow(vOldCode, vOldFillingField, vOldCode, vFillingField, vObjectTypeName, Object.Hotel, Object.InteractionParameters);
	EndIf;
EndProcedure

&AtClient
Procedure UseBackgroundJobOnChange(Item)
	If CheckFilling() Then
		If ValueIsFilled(Employee) Then
			If Object.Schedule <> Undefined Then
				If UseBackgroundJob Then
					If Not IsInRoleAtServer("Administrator") Then
						Raise(NStr("en='A background job should be configured by administrator only!';ru='Фоновое задание может настроить только системный администратор!';de='Ein Hintergrundjob kann der Administrator konfigurieren!'"));
					EndIf;
					Items.Text_BackgroundJobInfo.Title = NStr("en='Background job is configured and started'; ru='Фоновое задание настроено и запущено'; de='Ein Hintergrundjob ist konfiguriert und läuft'");
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
	Else
		UseBackgroundJob = False;
	EndIf;
EndProcedure

&AtClient
Procedure ManualSyncPeriodOnChange(Item)
	If ManualSyncPeriod > 400 Then
		ManualSyncPeriod = 400;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'No more than 400 days is allowed to upload for Siteminder!'; de = 'Es dürfen nicht mehr als 400 Tage für Siteminder hochgeladen werden!'; ru = 'Siteminder принимает данные только на ближайшие 400 дней!'"));
	ElsIf ManualSyncPeriod <= 0 Then
		ManualSyncPeriod = 1;	
	EndIf;
EndProcedure

&AtClient
Procedure SyncPeriodOnChange(Item)
	If Object.SyncPeriod > 400 Then
		Object.SyncPeriod = 400;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'No more than 400 days is allowed to upload for Siteminder!'; de = 'Es dürfen nicht mehr als 400 Tage für Siteminder hochgeladen werden!'; ru = 'Siteminder принимает данные только на ближайшие 400 дней!'"));
	ElsIf Object.SyncPeriod <= 0 Then
		Object.SyncPeriod = 1;	
	EndIf;
EndProcedure

&AtClient
Procedure RoomMappingBeforeDeleteRow(Item, Cancel)
	If Item.CurrentData <> Undefined Then
		vHotel 			= Object.Hotel;
		vExternalSystem = Object.InteractionParameters;
		
		If Item.CurrentData.GetParent() = Undefined Then
			vRow1 			= Item.CurrentData;
			vInventoryCode 	= vRow1.RoomTypeCode;
			vRoomType		= vRow1.RoomType;
			
			vRow1_Rows = vRow1.GetItems();
			For each vRow2 in vRow1_Rows Do
				vRateCode 		= vRow2.RoomRateCode;
				vRoomRate 		= vRow2.RoomRate;
				vAccomodation 	= vRow2.AccomodationTemplate;
				vCode			= GetMappingCode(vInventoryCode, vRateCode);
				DeleteExternalSystemRow(vCode, vRoomType, 		"Siteminder_RoomMapping_RT", vHotel, vExternalSystem);
				DeleteExternalSystemRow(vCode, vRoomRate,		"Siteminder_RoomMapping_RR", vHotel, vExternalSystem);
				DeleteExternalSystemRow(vCode, vAccomodation,	"Siteminder_RoomMapping_AT", vHotel, vExternalSystem);
			EndDo;
		Else
			vRow1 			= Item.CurrentData.GetParent();
			vInventoryCode 	= vRow1.RoomTypeCode;
			vRoomType		= vRow1.RoomType;
			
			vRow2 			= Item.CurrentData;
			vRateCode 		= vRow2.RoomRateCode;
			vRoomRate 		= vRow2.RoomRate;
			vAccomodation 	= vRow2.AccomodationTemplate;
			vCode			= GetMappingCode(vInventoryCode, vRateCode);
			DeleteExternalSystemRow(vCode, vRoomType, 		"Siteminder_RoomMapping_RT", vHotel, vExternalSystem);
			DeleteExternalSystemRow(vCode, vRoomRate,		"Siteminder_RoomMapping_RR", vHotel, vExternalSystem);
			DeleteExternalSystemRow(vCode, vAccomodation,	"Siteminder_RoomMapping_AT", vHotel, vExternalSystem);
		EndIf;
		TablesBeforeDeleteRow(Item, Cancel);
	EndIf;
EndProcedure

&AtClient
Procedure RoomMappingRoomTypeChoiceProcessing(Item, SelectedValue, StandardProcessing)
	If ValueIsFilled(Object.InteractionParameters) Then
		vRow1 			= Item.Parent.CurrentData;
		vInventoryCode 	= vRow1.RoomTypeCode;
		vRoomType		= vRow1.RoomType;
		
		vRow1_Rows = vRow1.GetItems();
		For each vRow2 in vRow1_Rows Do
			vRateCode 		= vRow2.RoomRateCode;
			vRoomRate 		= vRow2.RoomRate;
			vAccomodation 	= vRow2.AccomodationTemplate;
			vOldCode		= GetMappingCode(vInventoryCode, vRateCode);
			
			vFillingField		= SelectedValue;
			vOldFillingField	= vRoomType;
			
			ChangeExternalSystemRow(vOldCode, vOldFillingField, vOldCode, vFillingField, "Siteminder_RoomMapping_RT", Object.Hotel, Object.InteractionParameters);
		EndDo;
		RefChoiceProcessing(Item, SelectedValue, StandardProcessing);
	EndIf;
EndProcedure

&AtClient
Procedure RoomMappingRoomTypeCodeTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	If ValueIsFilled(Object.InteractionParameters) Then
		vRow1 			= Item.Parent.CurrentData;
		vInventoryCode 	= vRow1.RoomTypeCode;
		vRoomType		= vRow1.RoomType;
		
		vRow1_Rows = vRow1.GetItems();
		For each vRow2 in vRow1_Rows Do
			vRateCode 		= vRow2.RoomRateCode;
			vRoomRate 		= vRow2.RoomRate;
			vAccomodation 	= vRow2.AccomodationTemplate;
			vOldCode		= GetMappingCode(vInventoryCode, vRateCode);
			
			vCode			= GetMappingCode(Text, vRateCode);
			
			vOldFillingField	= vRoomType;
			
			ChangeExternalSystemRow(vOldCode, vRoomType, vCode, vRoomType, "Siteminder_RoomMapping_RT", Object.Hotel, Object.InteractionParameters);
			ChangeExternalSystemRow(vOldCode, vRoomRate, vCode, vRoomRate, "Siteminder_RoomMapping_RR", Object.Hotel, Object.InteractionParameters);
			ChangeExternalSystemRow(vOldCode, vAccomodation, vCode, vAccomodation, "Siteminder_RoomMapping_AT", Object.Hotel, Object.InteractionParameters);
		EndDo;
		CodeTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
		vRow1.RoomTypeCode = Text; 
	EndIf;
EndProcedure

&AtClient
Procedure RoomMappingRoomRateCodeTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	If ValueIsFilled(Object.InteractionParameters) Then
		vRow1 			= Item.Parent.CurrentData.GetParent();
		vInventoryCode 	= vRow1.RoomTypeCode;
		vRoomType		= vRow1.RoomType;
		
		vRow1_Rows = vRow1.GetItems();
		vRow2 = Item.Parent.CurrentData;
		
		vRateCode 		= vRow2.RoomRateCode;
		vRoomRate 		= vRow2.RoomRate;
		vAccomodation 	= vRow2.AccomodationTemplate;
		vOldCode		= GetMappingCode(vInventoryCode, vRateCode);
		
		vCode			= GetMappingCode(vInventoryCode, Text);
		
		vOldFillingField	= vRoomType;
		
		ChangeExternalSystemRow(vOldCode, vRoomType, vCode, vRoomType, "Siteminder_RoomMapping_RT", Object.Hotel, Object.InteractionParameters);
		ChangeExternalSystemRow(vOldCode, vRoomRate, vCode, vRoomRate, "Siteminder_RoomMapping_RR", Object.Hotel, Object.InteractionParameters);
		ChangeExternalSystemRow(vOldCode, vAccomodation, vCode, vAccomodation, "Siteminder_RoomMapping_AT", Object.Hotel, Object.InteractionParameters);
		
		CodeTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
		vRow2.RoomRateCode = Text; 
	EndIf;
	
EndProcedure

&AtClient
Procedure RoomMappingRoomRateChoiceProcessing(Item, SelectedValue, StandardProcessing)
	If ValueIsFilled(Object.InteractionParameters) Then
		vRow1 			= Item.Parent.CurrentData.GetParent();
		vInventoryCode 	= vRow1.RoomTypeCode;
		vRoomType		= vRow1.RoomType;
		
		vRow1_Rows = vRow1.GetItems();
		vRow2 = Item.Parent.CurrentData; 
		vRateCode 		= vRow2.RoomRateCode;
		vRoomRate 		= vRow2.RoomRate;
		vAccomodation 	= vRow2.AccomodationTemplate;
		vOldCode		= GetMappingCode(vInventoryCode, vRateCode);
		
		vFillingField		= SelectedValue;
		vOldFillingField	= vRoomRate;
		
		RefChoiceProcessing(Item, SelectedValue, StandardProcessing);
		ChangeExternalSystemRow(vOldCode, vOldFillingField, vOldCode, vFillingField, "Siteminder_RoomMapping_RR", Object.Hotel, Object.InteractionParameters);
	EndIf;
EndProcedure

&AtClient
Procedure RoomMappingAccomodationTemplateChoiceProcessing(Item, SelectedValue, StandardProcessing)
	If ValueIsFilled(Object.InteractionParameters) Then
		vRow1 			= Item.Parent.CurrentData.GetParent();
		vInventoryCode 	= vRow1.RoomTypeCode;
		vRoomType		= vRow1.RoomType;
		
		vRow1_Rows = vRow1.GetItems();
		vRow2 = Item.Parent.CurrentData;
		vRateCode 		= vRow2.RoomRateCode;
		vRoomRate 		= vRow2.RoomRate;
		vAccomodation 	= vRow2.AccomodationTemplate;
		vOldCode		= GetMappingCode(vInventoryCode, vRateCode);
		
		vFillingField		= SelectedValue;
		vOldFillingField	= vAccomodation;
		
		ChangeExternalSystemRow(vOldCode, vOldFillingField, vOldCode, vFillingField, "Siteminder_RoomMapping_AT", Object.Hotel, Object.InteractionParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure ServicesServiceClearing(Item, StandardProcessing)
	If ValueIsFilled(Object.InteractionParameters) Then
		vCode			= Item.CurrentData.Code;
		vFillingField	= Item.CurrentData.Service;
		vObjectTypeName	= "Services";
		
		DeleteExternalSystemRow(vCode, vFillingField, vObjectTypeName, Object.Hotel, Object.InteractionParameters);
	EndIf;
EndProcedure

&AtClient
Procedure PeriodSyncOnChange(Item)
	If PeriodSync.StartDate < BegOfDay(CurrentDate()) Then
		PeriodSync.StartDate = BegOfDay(CurrentDate());
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Start date cannot be less than current date!'; de = 'Der Beginn der Periode kann nicht unter dem aktuellen Datum liegen!'; ru = 'Начало периода не может быть меньше текущей даты!'"));
	EndIf;
	
	If PeriodSync.EndDate > BegOfDay(CurrentDate() + 24*60*60*400) Then
		PeriodSync.EndDate = BegOfDay(CurrentDate() + 24*60*60*400);
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'No more than 400 days is allowed to upload for Siteminder!'; de = 'Es dürfen nicht mehr als 400 Tage für Siteminder hochgeladen werden!'; ru = 'Siteminder принимает данные только на ближайшие 400 дней!'"));
	EndIf;
EndProcedure

&AtClient
Procedure GetFromFileOnChange(Item)
	ThisForm.Items.ManualXMLFilePath.Visible = ThisForm.IsLoadFormFile;
EndProcedure

&AtClient
Procedure ManualXMLFilePathStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	vFilter = NStr("en = 'XML file (*.xml)|*.xml|'; de = 'XML datei (*.xml)|*.xml|'; ru = 'XML файл (*.xml)|*.xml|'");
	tcOnClientWorkWithFiles.cmChooseDirectoryOnClient("ManualXMLFilePath", Object, True, vFilter);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient                   
Procedure Ping(Command)
	vResult = Ping_AtServer();
	If vResult <> Undefined Then 
		If vResult.Success Then 
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Success'; ru = 'Успешно'; de = 'Erfolg'")); //#Translate
		Else
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Error:'; ru = 'Ошибка:'; de = 'Error:'")); //#Translate
			i = 1;
			For each vErrorRow in vResult.Errors Do
				tcCommonFunctionOnClientServer.TextMessage("Error #" + i +"
				|Code: " + vErrorRow.Code + "
				|Type: " + vErrorRow.Type + "
				|Description: " + vErrorRow.Description);
				i = i + 1;
			EndDo;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure Save(Command)
	If CheckTree() and CheckFilling() Then
		Save_AtServer();
	EndIf;
EndProcedure

&AtClient
Procedure SyncChanges(Command)	
	vResult = Sync_AtServer(True, True, True, ManualSyncPeriod, False);
	If vResult <> Undefined THen
		For each vResultRow in vResult.RoomInventory Do 
			If vResultRow.Success Then 
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Success RoomInventory'; ru = 'Успешно RoomInventory'; de = 'Erfolg Zimmer'")); //#Translate
			Else
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Error:'; ru = 'Ошибка:'; de = 'Error:'")); //#Translate
				i = 1;
				For each vErrorRow in vResultRow.Errors Do
					tcCommonFunctionOnClientServer.TextMessage("Error #" + i +"
					|Code: " + vErrorRow.Code + "
					|Type: " + vErrorRow.Type + "
					|Description: " + vErrorRow.Description);
					i = i + 1;
				EndDo;
			EndIf;
		EndDo;
		
		For each vResultRow in vResult.RoomRates Do
			If vResultRow.Success Then 
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Success RoomRates'; ru = 'Успешно RoomRates'; de = 'Erfolg Zimmerpreise'")); //#Translate
			Else
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Error:'; ru = 'Ошибка:'; de = 'Error:'")); //#Translate
				i = 1;
				For each vErrorRow in vResultRow.Errors Do
					tcCommonFunctionOnClientServer.TextMessage("Error #" + i +"
					|Code: " + vErrorRow.Code + "
					|Type: " + vErrorRow.Type + "
					|Description: " + vErrorRow.Description);
					i = i + 1;
				EndDo;
			EndIf;
		EndDo;
		
		For each vResultRow in vResult.RoomRestrictions Do
			If vResultRow.Success Then 
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Success RoomRestrictions'; ru = 'Успешно RoomRestrictions'; de = 'Erfolg Beschränkungen'")); //#Translate
			Else
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Error:'; ru = 'Ошибка:'; de = 'Error:'")); //#Translate
				i = 1;
				For each vErrorRow in vResultRow.Errors Do
					tcCommonFunctionOnClientServer.TextMessage("Error #" + i +"
					|Code: " + vErrorRow.Code + "
					|Type: " + vErrorRow.Type + "
					|Description: " + vErrorRow.Description);
					i = i + 1;
				EndDo;
			EndIf;
		EndDo;
		
		For each vResultRow in vResult.Reservations Do
			If vResultRow.Success Then 
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Success Reservations: " + vResultRow.ReservationsCount + "'; ru = 'Успешно Reservations: " + vResultRow.ReservationsCount + "'; de = 'Erfolg Reservierungen " + vResultRow.ReservationsCount + "'")); //#Translate
				If vResultRow.ReservationsCount > 0 Then
					If vResultRow.Loaded Then
						tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Success Reservations Loaded'; ru = 'Успешно  Reservations Loaded'; de = 'Erfolg Reservations Loaded'")); //#Translate
					Else
						tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'FAILED Reservations Loaded'; ru = 'Провалено  Reservations Loaded'; de = 'Gescheitert Reservations Loaded'")); //#Translate
					EndIf;
					
					If vResultRow.Confirmed Then
						tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Success Reservations Confirmed'; ru = 'Успешно  Reservations Confirmed'; de = 'Erfolg Reservations Confirmed'")); //#Translate
					Else
						tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'FAILED Reservations Confirmed'; ru = 'Провалено  Reservations Confirmed'; de = 'Gescheitert Reservations Confirmed'")); //#Translate
					EndIf;				
				EndIf;
			Else
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Error:'; ru = 'Ошибка:'; de = 'Error:'")); //#Translate
				i = 1;
				For each vErrorRow in vResultRow.Errors Do
					tcCommonFunctionOnClientServer.TextMessage("Error #" + i +"
					|Code: " + vErrorRow.Code + "
					|Type: " + vErrorRow.Type + "
					|Description: " + vErrorRow.Description);
					i = i + 1;
				EndDo;
			EndIf;
		EndDo;
	EndIf;
EndProcedure

&AtClient
Procedure SyncInventory(Command)
	vResult = Sync_AtServer(True, False, False, ManualSyncPeriod, False);
	If vResult <> Undefined Then
		For each vResultRow in vResult.RoomInventory Do 
			If vResultRow.Success Then 
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Success RoomInventory'; ru = 'Успешно RoomInventory'; de = 'Erfolg Zimmer'")); //#Translate
			Else
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Error:'; ru = 'Ошибка:'; de = 'Error:'")); //#Translate
				i = 1;
				For each vErrorRow in vResultRow.Errors Do
					tcCommonFunctionOnClientServer.TextMessage("Error #" + i +"
					|Code: " + vErrorRow.Code + "
					|Type: " + vErrorRow.Type + "
					|Description: " + vErrorRow.Description);
					i = i + 1;
				EndDo;
			EndIf;
		EndDo;
	EndIf;
EndProcedure

&AtClient
Procedure SyncRoomRates(Command)
	vResult = Sync_AtServer(False, True, False, ManualSyncPeriod, False);
	If vResult <> Undefined Then
		For each vResultRow in vResult.RoomRates Do
			If vResultRow.Success Then 
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Success RoomRates'; ru = 'Успешно RoomRates'; de = 'Erfolg Zimmerpreise'")); //#Translate
			Else
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Error:'; ru = 'Ошибка:'; de = 'Error:'")); //#Translate
				i = 1;
				For each vErrorRow in vResultRow.Errors Do
					tcCommonFunctionOnClientServer.TextMessage("Error #" + i +"
					|Code: " + vErrorRow.Code + "
					|Type: " + vErrorRow.Type + "
					|Description: " + vErrorRow.Description);
					i = i + 1;
				EndDo;
			EndIf;
		EndDo;
	EndIf;
EndProcedure

&AtClient
Procedure SyncRestrictions(Command)
	vResult = Sync_AtServer(False, False, True, ManualSyncPeriod, False);
	If vResult <> Undefined Then
		For each vResultRow in vResult.RoomRestrictions Do
			If vResultRow.Success Then 
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Success RoomRestrictions'; ru = 'Успешно RoomRestrictions'; de = 'Erfolg Beschränkungen'")); //#Translate
			Else
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Error:'; ru = 'Ошибка:'; de = 'Error:'")); //#Translate
				i = 1;
				For each vErrorRow in vResultRow.Errors Do
					tcCommonFunctionOnClientServer.TextMessage("Error #" + i +"
					|Code: " + vErrorRow.Code + "
					|Type: " + vErrorRow.Type + "
					|Description: " + vErrorRow.Description);
					i = i + 1;
				EndDo;
			EndIf;
		EndDo;
	EndIf;
EndProcedure

&AtClient
Procedure SyncReservations(Command)
	If Not IsLoadFormFile Then
		vResult = Sync_AtServer(False, False, False, ManualSyncPeriod, True);
	Else
		// Get data from file
		If Not IsBlankString(Object.ManualXMLFilePath) Then
			vXMLReader = New TextReader(Object.ManualXMLFilePath);
			vXMLText = vXMLReader.Read();
			vResult = Siteminder.GetReservationsFromFile(vXMLText,Object.InteractionParameters,GetPricesManual, Object.DefaultAccomondationType); 	
		Else
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'File path not set'; de = 'Dateipfad nicht festgelegt'; ru = 'Не указан путь к файлу'")); 
			Return;
		EndIf;
 		
	EndIf;
	If vResult <> Undefined AND vResult.Property("Reservations") Then
		
		For each vResultRow in vResult.Reservations Do
			If vResultRow.Success Then 
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Success Reservations: " + vResultRow.ReservationsCount + "'; ru = 'Успешно Reservations: " + vResultRow.ReservationsCount + "'; de = 'Erfolg Reservierungen " + vResultRow.ReservationsCount + "'")); //#Translate
				If vResultRow.ReservationsCount > 0 Then
					If vResultRow.Loaded Then
						tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Success Reservations Loaded'; ru = 'Успешно  Reservations Loaded'; de = 'Erfolg Reservations Loaded'")); //#Translate
					Else
						tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'FAILED Reservations Loaded'; ru = 'Провалено  Reservations Loaded'; de = 'Gescheitert Reservations Loaded'")); //#Translate
					EndIf;
					
					If vResultRow.Confirmed Then
						tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Success Reservations Confirmed'; ru = 'Успешно  Reservations Confirmed'; de = 'Erfolg Reservations Confirmed'")); //#Translate
					Else
						tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'FAILED Reservations Confirmed'; ru = 'Провалено  Reservations Confirmed'; de = 'Gescheitert Reservations Confirmed'")); //#Translate
					EndIf;
				EndIf;
			EndIf;			
			i = 1;
			For each vErrorRow in vResultRow.Errors Do
				tcCommonFunctionOnClientServer.TextMessage("Error #" + i +"
				|Code: " + vErrorRow.Code + "
				|Type: " + vErrorRow.Type + "
				|Description: " + vErrorRow.Description);
				i = i + 1;
			EndDo;
			
		EndDo;
	EndIf;
EndProcedure

&AtClient
Procedure SyncAllForPeriod(Command)
	vResult = SyncAllForPeriod_AtServer();
	If vResult <> Undefined THen
		For each vResultRow in vResult.RoomInventory Do 
			If vResultRow.Success Then 
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Success RoomInventory'; ru = 'Успешно RoomInventory'; de = 'Erfolg Zimmer'")); //#Translate
			Else
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Error:'; ru = 'Ошибка:'; de = 'Error:'")); //#Translate
				i = 1;
				For each vErrorRow in vResultRow.Errors Do
					tcCommonFunctionOnClientServer.TextMessage("Error #" + i +"
					|Code: " + vErrorRow.Code + "
					|Type: " + vErrorRow.Type + "
					|Description: " + vErrorRow.Description);
					i = i + 1;
				EndDo;
			EndIf;
		EndDo;
		
		For each vResultRow in vResult.RoomRates Do
			If vResultRow.Success Then 
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Success RoomRates'; ru = 'Успешно RoomRates'; de = 'Erfolg Zimmerpreise'")); //#Translate
			Else
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Error:'; ru = 'Ошибка:'; de = 'Error:'")); //#Translate
				i = 1;
				For each vErrorRow in vResultRow.Errors Do
					tcCommonFunctionOnClientServer.TextMessage("Error #" + i +"
					|Code: " + vErrorRow.Code + "
					|Type: " + vErrorRow.Type + "
					|Description: " + vErrorRow.Description);
					i = i + 1;
				EndDo;
			EndIf;
		EndDo;
		
		For each vResultRow in vResult.RoomRestrictions Do
			If vResultRow.Success Then 
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Success RoomRestrictions'; ru = 'Успешно RoomRestrictions'; de = 'Erfolg Beschränkungen'")); //#Translate
			Else
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Error:'; ru = 'Ошибка:'; de = 'Error:'")); //#Translate
				i = 1;
				For each vErrorRow in vResultRow.Errors Do
					tcCommonFunctionOnClientServer.TextMessage("Error #" + i +"
					|Code: " + vErrorRow.Code + "
					|Type: " + vErrorRow.Type + "
					|Description: " + vErrorRow.Description);
					i = i + 1;
				EndDo;
			EndIf;
		EndDo;
		
	EndIf;
EndProcedure

&AtClient
Procedure SetupBackgroundJobSchedule(Command)
	#If NOT MobileClient Then
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
EndProcedure

&AtClient
Procedure AddRoomType(Command)
	vNewRow = RoomMapping.GetItems().Add();
	vNewRow.RowLevel = 1;
EndProcedure

&AtClient
Procedure AddRoomRate(Command)
	If Items.RoomMapping.CurrentData <> Undefined Then
		vCurrentParent = Items.RoomMapping.CurrentData.GetParent(); 
		If vCurrentParent <> Undefined and vCurrentParent.GetParent() = Undefined Then
			vNewRow = vCurrentParent.GetItems().Add();
			vNewRow.RoomTypeCode = vCurrentParent.RoomTypeCode; 
			vNewRow.RowLevel = 2;
			Items.RoomMapping.Expand(vCurrentParent.GetID());
		ElsIf vCurrentParent = Undefined Then
			vNewRow = Items.RoomMapping.CurrentData.GetItems().Add();
			vNewRow.RoomTypeCode = Items.RoomMapping.CurrentData.RoomTypeCode;
			vNewRow.RowLevel = 2;
			Items.RoomMapping.Expand(Items.RoomMapping.CurrentData.GetID());
		EndIf;	
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Choose row with room type for adding room rate!'; ru = 'Выберите строку с типом номера для добавления тарифа!'; de = 'Wählen Sie die Zeile mit der Zimmertypen, um den Zimmerpreis hinzufugen!'"));
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure AllotmentOnChangeAtServer()
	Object.InteractionParameters = ChannelManagers.GetInteractionParameters(Object.Hotel, Object.Allotment, Siteminder.GetSettings());
	SetSettings();
EndProcedure

&AtServer
Procedure HotelOnChangeAtServer()
	Object.InteractionParameters = ChannelManagers.GetInteractionParameters(Object.Hotel, Object.Allotment, Siteminder.GetSettings());
	SetSettings();
	Object.Login 		= "";
	Object.HotelCode 	= "";
	Object.Password		= "";
EndProcedure

&AtServer
Procedure SetSettings()
	If ValueIsFilled(Object.InteractionParameters) And (Not ValueIsFilled(Object.InteractionParameters.WSHost) Or Not ValueIsFilled(Object.InteractionParameters.HttpAddress)) Then
		vSettings = Siteminder.GetSettings();
		vObj = Object.InteractionParameters.GetObject();
		If Not ValueIsFilled(vObj.WSHost) Then
			vObj.WSHost = vSettings.WSHost;
		EndIf;
		If Not ValueIsFilled(vObj.HttpAddress) Then
			vObj.HttpAddress = vSettings.ResourceAddress;
		EndIf;
		vObj.Write();
	EndIf;
EndProcedure // SetSettings

&AtServer
Procedure InteractionParametersOnChangeAtServer()
	If ValueIsFilled(Object.InteractionParameters) Then
		Object.Hotel				  = Object.InteractionParameters.Hotel;
		Object.Allotment 		   	  = Object.InteractionParameters.Allotment;
		Object.Login 			 	  = Object.InteractionParameters.Login; 
		Object.Password 			  = Object.InteractionParameters.Password;
		HttpAddress         		  = Object.InteractionParameters.HttpAddress;
		WSHost         				  = Object.InteractionParameters.WSHost;
		ActivateInteractionParameters = Object.InteractionParameters.IsActive;
		MaxLogLenght				  = Object.InteractionParameters.MaxLogLenght;
	EndIf;
	FillTables();
EndProcedure

&AtServer
Function Ping_AtServer()
	If CheckFilling() Then  
		Return Siteminder.Ping(Object.Login, Object.Password, Object.InteractionParameters.WSHost, Object.InteractionParameters.HttpAddress);
	EndIf;
	Return Undefined;
EndFunction

&AtServer
Procedure Save_AtServer()
	SaveTables();
	
	Try
		vObj = Object.InteractionParameters.GetObject();
		vObj.IsActive = ActivateInteractionParameters;
		vObj.WSHost = WSHost;
		vObj.HttpAddress = HttpAddress;
		vObj.MaxLogLenght = MaxLogLenght;
		vObj.Write();
	Except
	EndTry;
	
	// Save DP parameters
	Obj = FormAttributeToValue("Object");
	Obj.pmSaveDataProcessorAttributes();
EndProcedure

&AtServer
Function Sync_AtServer(pSyncInventory, pSyncRates, pSyncRestrictions, pSyncPeriod, pGetReservations)
	Save_AtServer();
	If CheckFilling() Then		
		Return Siteminder.SyncChanges(Object.Login, Object.Password, Object.InteractionParameters.WSHost, Object.InteractionParameters.HttpAddress, "1CHOTEL", Object.HotelCode, Object.InteractionParameters, pSyncInventory, pSyncRates, pSyncRestrictions, pSyncPeriod, pGetReservations, GetPricesManual, Object.DefaultAccomondationType, Object.GetVacantRoomsAtMidnight); 
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Fill all settings!'; ru = 'Введите все настройки!'; de = 'Füllen Sie alle Einstellungen!'")) //#Translate
	EndIf;
	Return Undefined;	
EndFunction

&AtServer
Function SyncAllForPeriod_AtServer()
	If CheckFilling() Then
		If ValueIsFilled(PeriodSync.StartDate) and ValueIsFilled(PeriodSync.EndDate) Then
			If	(BegOfDay(PeriodSync.EndDate) - BegOfDay(PeriodSync.StartDate)) < 24*60*60*400 Then  				
				Return Siteminder.SyncAllForPeriod(Object.Login, Object.Password, Object.InteractionParameters.WSHost, Object.InteractionParameters.HttpAddress, "1CHOTEL", Object.HotelCode, Object.InteractionParameters, PeriodSync.StartDate, PeriodSync.EndDate, Object.SyncAvailabilityForPeriod, Object.SyncRoomRatesForPeriod, Object.SyncRestrictionsForPeriod, Object.GetVacantRoomsAtMidnight);
			Else
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Max 400 days!'; ru = 'Максимум 400 дней!'; de = 'Max 400 Tage!'")) //#Translate	
			EndIf;
		Else
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Choose period!'; ru = 'Укажите период!'; de = 'Wählen Sie Zeitraum!'")) //#Translate
		EndIf;
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Fill all settings!'; ru = 'Введите все настройки!'; de = 'Füllen Sie alle Einstellungen!'")) //#Translate
	EndIf;
	Return Undefined;
EndFunction

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

&AtServer
Procedure FillTables()
	Currencies.Clear();
	Services.Clear();
	Statuses.Clear();
	Agents.Clear();
	PaymentMethods.Clear();
	GuaranteeTypes.Clear();
	RoomMapping.GetItems().Clear();
	
	// Loading from schemas
	LoadTableFromTemplate(Agents,"Agents");
	LoadTableFromTemplate(Services,"Services");
	LoadTableFromTemplate(Statuses,"Statuses");
	
	vSchemaRow = New Structure("ObjectRef, ObjectExternalCode", Undefined, "ExternalPayment");
	AddFillRow(PaymentMethods, "PaymentMethod", vSchemaRow);
	
	vSchemaRow = New Structure("ObjectRef, ObjectExternalCode", Undefined, "Credit card");
	AddFillRow(GuaranteeTypes, "GuaranteeType", vSchemaRow);

	If ValueIsFilled(Object.InteractionParameters) Then
		vQuery = New Query;
		vQuery.Text = 
		"SELECT
		|	ExternalSystemsObjectCodesMappings.ObjectTypeName AS ObjectTypeName,
		|	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode,
		|	ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef
		|FROM
		|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
		|WHERE
		|	ExternalSystemsObjectCodesMappings.Hotel = &qHotel
		|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode";
		
		vQuery.SetParameter("qExternalSystemCode", Object.InteractionParameters.InteractionID);
		vQuery.SetParameter("qHotel", Object.Hotel);
		
		vQueryResult = vQuery.Execute().Unload();
		
		vTreeTable = vQueryResult.CopyColumns();
		
		For each vCodeMappingRow in vQueryResult Do
			If 		vCodeMappingRow.ObjectTypeName = "Currencies" Then
				AddFillRow(Currencies, "Currency", vCodeMappingRow);	
			ElsIf 	vCodeMappingRow.ObjectTypeName = "Services" or vCodeMappingRow.ObjectTypeName = "ServicePackages" Then
				AddFillRow(Services, "Service", vCodeMappingRow);
			ElsIf 	vCodeMappingRow.ObjectTypeName = "ReservationStatuses" Then
				AddFillRow(Statuses, "Status", vCodeMappingRow);
			ElsIf 	vCodeMappingRow.ObjectTypeName = "Customers" Then
				AddFillRow(Agents, "Agent", vCodeMappingRow);
			ElsIf 	vCodeMappingRow.ObjectTypeName = "PaymentMethods" Then
				AddFillRow(PaymentMethods, "PaymentMethod", vCodeMappingRow);
			ElsIf 	vCodeMappingRow.ObjectTypeName = "GuaranteeTypes" Then
				AddFillRow(GuaranteeTypes, "GuaranteeType", vCodeMappingRow);
			ElsIf 	vCodeMappingRow.ObjectTypeName = "Siteminder_RoomMapping_RT" 
				or 	vCodeMappingRow.ObjectTypeName = "Siteminder_RoomMapping_RR" 
				or 	vCodeMappingRow.ObjectTypeName = "Siteminder_RoomMapping_AT" Then
				vNewRow = vTreeTable.Add();
				FillPropertyValues(vNewRow,vCodeMappingRow);
			EndIf;		
		EndDo;
		LoadMappingTree(vTreeTable);	
	EndIf;
	
	Agents.Sort("Agent DESC, Name");
	Services.Sort("Name");
	
EndProcedure

&AtServer
Procedure LoadTableFromTemplate(pTable, pTemplateName)
	vTemplate = DataProcessors.SiteminderWizard.GetTemplate(pTemplateName);
	For i = 1 to vTemplate.TableHeight Do
		vNewRow 		= pTable.Add();
		vNewRow.Code 	= vTemplate.Area(i,1).Text;
		vNewRow.Name 	= vTemplate.Area(i,2).Text;
	EndDo;
EndProcedure

&AtServer
Procedure AddFillRow(pTable, pFillingField, pExternalRow)
	vExist = false;
	For each vRow in pTable Do
		If vRow.Code = pExternalRow.ObjectExternalCode Then
			vExist 					= True;
			vRow[pFillingField] 	= pExternalRow.ObjectRef;
		EndIf;
	EndDo;
	If NOT vExist Then
		vNewRow 				= pTable.Add();
		vNewRow.Code 			= pExternalRow.ObjectExternalCode;
		vNewRow[pFillingField]	= pExternalRow.ObjectRef;
	EndIf;	
EndProcedure

&AtServer
Procedure SaveTables()
	If ValueIsFilled(Object.InteractionParameters) Then
		vHotel = Object.Hotel;
		vExternalSystemCode = Object.InteractionParameters.InteractionID;
		SaveMappingTree();
		WriteExternalSystemRow(Currencies, 		"Currency", 		"Currencies", 		vHotel, vExternalSystemCode);
		WriteExternalSystemRow(Services, 		"Service",  		"Services", 		vHotel, vExternalSystemCode);
		WriteExternalSystemRow(Statuses, 		"Status", 			"ReservationStatuses",	 	vHotel, vExternalSystemCode);
		WriteExternalSystemRow(Agents, 			"Agent", 			"Customers", 		vHotel, vExternalSystemCode);
		WriteExternalSystemRow(PaymentMethods, 	"PaymentMethod", 	"PaymentMethods", 	vHotel, vExternalSystemCode);
		WriteExternalSystemRow(GuaranteeTypes, 	"GuaranteeType",  	"GuaranteeTypes", 	vHotel, vExternalSystemCode);
		
		vObj 			= Object.InteractionParameters.Ref.GetObject();
		vObj.Login 		= Object.Login;
		vObj.Password 	= Object.Password;
		vObj.Write();
		
	EndIf;
EndProcedure

&AtServer
Procedure WriteExternalSystemRow(pTable, pObjectRef, pObjectTypeName, pHotel, pExternalSystemCode)
	If ValueIsFilled(pExternalSystemCode) Then
		For each vRow in pTable Do
			If ValueIsFilled(vRow[pObjectRef]) Then
				If pObjectRef = "Service" Then
					If TypeOf(vRow[pObjectRef]) = Type("CatalogRef.ServicePackages") Then
						pObjectTypeName = "ServicePackages";
					Else
						pObjectTypeName = "Services";	
					EndIf;
				EndIf;
				vRecordManager 						= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
				vRecordManager.Hotel 				= pHotel;
				vRecordManager.ExternalSystemCode 	= pExternalSystemCode;
				vRecordManager.ObjectTypeName 		= pObjectTypeName;
				vRecordManager.ObjectExternalCode 	= vRow.Code;
				vRecordManager.ObjectRef 			= vRow[pObjectRef];
				vRecordManager.Read();
				
				If NOT vRecordManager.Selected() Then
					vRecordManager.Hotel 				= pHotel;
					vRecordManager.ExternalSystemCode 	= pExternalSystemCode;
					vRecordManager.ObjectTypeName 		= pObjectTypeName;
					vRecordManager.ObjectExternalCode 	= vRow.Code;
					vRecordManager.ObjectRef 			= vRow[pObjectRef];
					vRecordManager.Write(True);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure DeleteExternalSystemRow(pCode, pObjectRef, pObjectTypeName, pHotel, pInteractionParameters)
	If ValueIsFilled(pInteractionParameters) Then
		If pObjectTypeName = "Services" Then
			If TypeOf(pObjectRef) = Type("CatalogRef.ServicePackages") Then
				pObjectTypeName = "ServicePackages"; 	
			EndIf;
		EndIf;

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
	EndIf;
EndProcedure

&AtServer
Procedure ChangeExternalSystemRow(pOldCode, pOldObjectRef, pCode, pObjectRef, pObjectTypeName, pHotel, pInteractionParameters)
	If ValueIsFilled(pInteractionParameters) Then
		If pObjectTypeName = "Services" Then
			vRecordManager 						= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
			vRecordManager.Hotel 				= pHotel;
			vRecordManager.ExternalSystemCode 	= pInteractionParameters.InteractionID;
			vRecordManager.ObjectTypeName 		= "ServicePackages";
			vRecordManager.ObjectExternalCode 	= pOldCode;
			vRecordManager.ObjectRef 			= pOldObjectRef;
			vRecordManager.Read();
			
			If  vRecordManager.Selected() Then
				vRecordManager.Delete();
			EndIf;

		EndIf;

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
		
		If pObjectTypeName = "Services" or pObjectTypeName = "ServicePackages" Then
			If TypeOf(pObjectRef) = Type("CatalogRef.ServicePackages") Then 
				pObjectTypeName = "ServicePackages";
			ElsIf TypeOf(pObjectRef) = Type("CatalogRef.Services") Then
				pObjectTypeName = "Services";
			Else 
				Return;
			EndIf;
		EndIf;

		
		vRecordManager 						= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
		vRecordManager.Hotel 				= pHotel;
		vRecordManager.ExternalSystemCode 	= pInteractionParameters.InteractionID;
		vRecordManager.ObjectTypeName 		= pObjectTypeName;
		vRecordManager.ObjectExternalCode 	= pCode;
		vRecordManager.ObjectRef 			= pObjectRef;
		vRecordManager.Write(true);
	EndIf;
EndProcedure

&AtServer
Procedure SaveMappingTree()
	vHotel 				= Object.Hotel;
	vExternalSystemCode = Object.InteractionParameters.InteractionID;
	
	vRoomMapping = RoomMapping.GetItems();	
	For each vRow1 in vRoomMapping Do
		vInventoryCode 	= vRow1.RoomTypeCode;
		vRoomType		= vRow1.RoomType;
		
		vRow1_Rows = vRow1.GetItems();
		For each vRow2 in vRow1_Rows Do
			vRateCode 		= vRow2.RoomRateCode;
			vRoomRate 		= vRow2.RoomRate;
			vAccomodation 	= vRow2.AccomodationTemplate;
			vCode			= GetMappingCode(vInventoryCode, vRateCode);
			WriteExternalSystemRow_Tree(vRoomType,		"Siteminder_RoomMapping_RT", 				vCode, vHotel, vExternalSystemCode);
			WriteExternalSystemRow_Tree(vRoomRate,		"Siteminder_RoomMapping_RR", 				vCode, vHotel, vExternalSystemCode);
			WriteExternalSystemRow_Tree(vAccomodation,	"Siteminder_RoomMapping_AT", 	vCode, vHotel, vExternalSystemCode);
		EndDo;		
	EndDo;
EndProcedure

&AtServer
Procedure WriteExternalSystemRow_Tree(pObjectRef, pObjectTypeName, pCode, pHotel, pExternalSystemCode)
	If ValueIsFilled(pExternalSystemCode) Then
		If ValueIsFilled(pObjectRef) Then
			vRecordManager 						= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
			vRecordManager.Hotel 				= pHotel;
			vRecordManager.ExternalSystemCode 	= pExternalSystemCode;
			vRecordManager.ObjectTypeName 		= pObjectTypeName;
			vRecordManager.ObjectExternalCode 	= pCode;
			vRecordManager.ObjectRef 			= pObjectRef;
			vRecordManager.Read();
			
			If NOT vRecordManager.Selected() Then
				vRecordManager.Hotel 				= pHotel;
				vRecordManager.ExternalSystemCode 	= pExternalSystemCode;
				vRecordManager.ObjectTypeName 		= pObjectTypeName;
				vRecordManager.ObjectExternalCode 	= pCode;
				vRecordManager.ObjectRef 			= pObjectRef;
				vRecordManager.Write(True);
			EndIf;
		EndIf;		
	EndIf;
EndProcedure

&AtServer
Procedure LoadMappingTree(pTable)
	pTable.Sort("ObjectExternalCode");
	
	vCleanArray = New Array;
	
	vNewTable = new ValueTable();
	vNewTable.Columns.Add("InventoryCode");
	vNewTable.Columns.Add("RoomTypeRef");
	vNewTable.Columns.Add("RoomRateCode");
	vNewTable.Columns.Add("RealCode");
	
	For each vRow in pTable Do
		If vRow.ObjectTypeName = "Siteminder_RoomMapping_RT" Then 
			vStartPosition 	= StrFind(vRow.ObjectExternalCode,"<Inv>") + 5;
			vEndPosition   	= StrFind(vRow.ObjectExternalCode,"</Inv>");
			vInvCode		= Mid(vRow.ObjectExternalCode, vStartPosition, vEndPosition - vStartPosition);
			
			vStartPosition 	= StrFind(vRow.ObjectExternalCode,"<Rate>") + 6;
			vEndPosition   	= StrFind(vRow.ObjectExternalCode,"</Rate>");
			vRateCode		= Mid(vRow.ObjectExternalCode, vStartPosition, vEndPosition - vStartPosition);
			
			vNewRow = vNewTable.Add();
			vNewRow.InventoryCode 	= vInvCode;
			vNewRow.RoomTypeRef 	= vRow.ObjectRef;
			vNewRow.RoomRateCode 	= vRateCode;
			vNewRow.RealCode		= vRow.ObjectExternalCode;
			
			vCleanArray.Add(vRow);
		EndIf;
	EndDo;
	
	For each vRow in vCleanArray Do
		pTable.Delete(vRow);	
	EndDo;
	
	vNewTable.Sort("InventoryCode");
	
	vOldInventoryCode 	= Undefined;
	vAddLvL1Row 		= True;
	vNewRow1			= Undefined;
	For each vRow1 in vNewTable Do
		
		If vOldInventoryCode = Undefined or vOldInventoryCode <> vRow1.InventoryCode Then
			vAddLvL1Row = True;
		EndIf;
		
		If vAddLvL1Row Then
			vNewRow1 				= RoomMapping.GetItems().Add();
			vNewRow1.RoomTypeCode 	= vRow1.InventoryCode;
			vNewRow1.RoomType 		= vRow1.RoomTypeRef;
			vNewRow1.RowLevel = 1;
			vAddLvL1Row = False;
		EndIf;
		
		vFilter		= New Structure("ObjectExternalCode", vRow1.RealCode);
		vFoundRows 	= pTable.FindRows(vFilter);
		vRoomRateRef 				= Undefined;
		vAccomodationTemplateRef 	= Undefined;
		For each vRow2 in vFoundRows Do
			If vRow2.ObjectTypeName = "Siteminder_RoomMapping_RR" Then
				vRoomRateRef 				= vRow2.ObjectRef;
			ElsIf vRow2.ObjectTypeName = "Siteminder_RoomMapping_AT" Then
				vAccomodationTemplateRef 	= vRow2.ObjectRef;
			EndIf;
		EndDo;
		
		If vNewRow1 <> Undefined Then
			vNewRow2 						= vNewRow1.GetItems().Add();
			vNewRow2.RoomTypeCode 			= vRow1.InventoryCode;
			vNewRow2.RoomRateCode 			= vRow1.RoomRateCode;
			vNewRow2.RoomRate 				= vRoomRateRef;
			vNewRow2.AccomodationTemplate 	= vAccomodationTemplateRef;
			vNewRow2.RowLevel = 2;
		EndIf;
		
		vOldInventoryCode = vRow1.InventoryCode; 
	EndDo;
EndProcedure

&AtClient
Function CheckTree()
	vResult = True;
	vTree = RoomMapping.GetItems();
	For each vRow1 in vTree Do
		If NOT ValueIsFilled(vRow1.RoomTypeCode) Then
			vResult = False;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Fill Inventory Code!'; ru = 'Заполните Inventory Code!'; de = 'Füllen Inventory Code!'"));
		EndIf;
		If NOT ValueIsFilled(vRow1.RoomType) Then
			vResult = False;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Fill Room type!'; ru = 'Заполните тип номера!'; de = 'Füllen Zimmertyp!'"));
		EndIf;
		
		vRow1_Rows = vRow1.GetItems();
		
		If vRow1_Rows.Count() = 0 Then
			vResult = False;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Room type must have at least 1 room rate!'; ru = 'Тип номера должен иметь хотя бы 1 тариф!'; de = 'Zimmertyp muss mindestens 1 Zimmerpreis haben!'"));	
		EndIf;
		
		For each vRow2 in vRow1_Rows Do
			If NOT ValueIsFilled(vRow2.RoomRateCode) Then
				vResult = False;
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Fill Rate Code!'; ru = 'Заполните Rate Code!'; de = 'Füllen Rate Code!'"));
			EndIf;
			If NOT ValueIsFilled(vRow2.RoomRate) Then
				vResult = False;
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Fill Room rate!'; ru = 'Заполните тариф!'; de = 'Füllen Zimmerpreis!'"));
			EndIf;
			If NOT ValueIsFilled(vRow2.AccomodationTemplate) Then
				vResult = False;
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Fill accomodation template!'; ru = 'Заполните шаблон размещения!'; de = 'Füllen Vorlagen für die Unterbringung der Gäste!'"));
			EndIf;
		EndDo;
	EndDo;
	Return vResult;
EndFunction

&AtServer
Function IsInRoleAtServer(pRole)
	Return IsInRole(pRole);
EndFunction

&AtClientAtServerNoContext
Function GetMappingCode(pInventoryCode, pRateCode)
	Return "<Inv>" + pInventoryCode + "</Inv><Rate>" + pRateCode + "</Rate>";
EndFunction

#EndRegion


