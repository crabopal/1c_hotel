
#Region FormEventHandlers

// -------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Access rights
	If Not AccessRight("View", Metadata.CommonCommands.MainMenuSummaryIndexesCommand) Then
		Items.SummaryIndexesGroup_New.Visible 	= False;
	EndIf;
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		If ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
			Items.InHouseGroup.Visible = False;
			Items.CheckOutGroup.Visible = False;
		EndIf;
	Else
		Items.InHouseGroup.Visible = False;
		Items.CheckOutGroup.Visible = False;
	EndIf;
	
	vHotelName = "";
	CurrentHotel = SessionParameters.CurrentHotel;  
	If ValueIsFilled(CurrentHotel) Then
		vHotelName = TrimAll(CurrentHotel.LegacyName);
		If IsBlankString(vHotelName) Then
			vHotelName = TrimAll(CurrentHotel.Description);
		EndIf;
	EndIf;
	If ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
		Title = NStr("en = 'Hotel agent remote workplace'; de = 'Gelöschter Arbeitsplatz des Agenten'; ru = 'Удаленное рабочее место агента'") + " " + vHotelName;
	Else
		Title = vHotelName;
	EndIf;
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(CurrentHotel, "BackgroundColorImportant");
	CurrentDateField = FillSessionDate();
EndProcedure //  OnCreateAtServer

// -------------------------------------------------------------------------
&AtClient
Procedure OnOpen(Cancel)
	Items.SummaryIndexesGroup_Row_1.Visible = False;
	Items.InHouse_Rooms_Value.Visible 		= False;
	Items.InHouse_Adults_Value.Visible 		= False;
	Items.InHouse_Children_Value.Visible 	= False;
	Items.CheckIn_Rooms_Value.Visible 		= False;
	Items.CheckIn_Adults_Value.Visible 		= False;
	Items.CheckIn_Children_Value.Visible 	= False;
	Items.CheckOut_Rooms_Value.Visible 		= False;
	Items.CheckOut_Adults_Value.Visible 	= False;
	Items.CheckOut_Children_Value.Visible 	= False;
	Items.RoomsTable.Visible 				= False;
	StartProlongedOperations();
	AttachIdleHandler("Attachable_CheckPopupMessages", 10, True);
EndProcedure //  OnOpen

// -------------------------------------------------------------------------
&AtClient
Procedure ChoiceProcessing(pSelectedValue, pChoiceSource)
	If ValueIsFilled(pSelectedValue) And TypeOf(pSelectedValue) = Type("CatalogRef.Hotels") Then
		If CurrentHotel <> pSelectedValue Then
			CurrentHotel = pSelectedValue;
			// Set hotel color          
			Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(CurrentHotel, "BackgroundColorImportant");
			// Change current form title
			Title = tcOnServer.ChangeCurrentHotel(pSelectedValue);
			// Refresh form data
			Refresh(Commands.Refresh);
		EndIf;
	EndIf;
EndProcedure //  ChoiceProcessing

// -------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "Desktop.Refresh" Then
		Refresh(Commands.Refresh);
	EndIf;
	If pEventName = "System.Hotel.Changed" And pParameter <> CurrentHotel And pSource <> ThisObject Then
		pSelectedValue = pParameter;
		If CurrentHotel <> pSelectedValue Then
			CurrentHotel = pSelectedValue;
			Title = TrimAll(tcOnServer.cmGetAttributeByRef(pSelectedValue, "LegacyName"));
			If IsBlankString(Title) Then
				Title = TrimAll(tcOnServer.cmGetAttributeByRef(pSelectedValue, "Description"));
			EndIf;
			Refresh(Commands.Refresh);
		EndIf;
	EndIf;
EndProcedure //  NotificationProcessing

// -------------------------------------------------------------------------
&AtClient
Procedure ExternalEvent(pSource, pEvent, pData)
	If Not IsInputAvailable() Then
		Return;
	EndIf;
	
	vEventData = tcConnectionHardwareAtClient.cmGetExternalEventResultInputDevice(pSource, pEvent, pData);
	If IsBlankString(vEventData.DeviceData) Then
		Return;
	EndIf;
	
	If StrFind(vEventData.DeviceData, "mos.ru") <> 0 Or StrFind(vEventData.DeviceData, "gosuslugi.ru") <> 0 Then
		BeginRunningApplication(New NotifyDescription, vEventData.DeviceData);
	EndIf;
EndProcedure // ExternalEvent

#EndRegion

#Region FormHeaderItemsEventHandlers

// -------------------------------------------------------------------------
&AtClient
Procedure HotelChoiceClick(pItem)
	vNotifyProcessing = New NotifyDescription("HotelChoiceClickAfterConfirmation", ThisObject);
	ShowQueryBox(vNotifyProcessing,
				 NStr("en = 'After the change of the hotel, all forms will be closed, continue?'; 
					  |de = 'Nach dem Wechsel des Hotels werden Formulare geschlossen, weiter?'; 
					  |ru = 'После смены гостиницы будут закрыты все формы, продолжить?'"),
				 QuestionDialogMode.YesNo,,
				 DialogReturnCode.No);
EndProcedure //  HotelChoiceClick

// -------------------------------------------------------------------------
&AtClient
Procedure SummaryIndexes_TextClick(pItem)
	GotoURL("e1cib/navigationpoint/desktop/CommonCommand.MainMenuSummaryIndexesCommand");
EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure CheckIn_Click(pItem)
	#IF NOT MobileClient THEN 
		// APDEX
		vKeyOperation = "Document.Accommodation.Form.tcAccommodationListForm.Arrival.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

		OpenForm("Document.Accommodation.Form.tcAccommodationListForm", New Structure("SelFilterStatus", 2));
	#ELSE
		OpenForm("Document.Accommodation.Form.mcAccommodationListForm", New Structure("SelFilterStatus", 2));	
	#ENDIF
	Notify("Document.Accommodation.ListForm.ExpectedArrival");
EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure CheckOut_Click(pItem)
	#IF NOT MobileClient THEN 
		// APDEX
		vKeyOperation = "Document.Accommodation.Form.tcAccommodationListForm.Departure.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

		OpenForm("Document.Accommodation.Form.tcAccommodationListForm", New Structure("SelFilterStatus", 3));
	#ELSE
		OpenForm("Document.Accommodation.Form.mcAccommodationListForm", New Structure("SelFilterStatus", 3));	
	#ENDIF
	Notify("Document.Accommodation.ListForm.ExpectedDeparture");
EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure InHouse_Click(pItem)
	#IF NOT MobileClient THEN 
		// APDEX
		vKeyOperation = "Document.Accommodation.Form.tcAccommodationListForm.InHouseGuests.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

		OpenForm("Document.Accommodation.Form.tcAccommodationListForm", New Structure("SelFilterStatus", 0));
	#ELSE
		OpenForm("Document.Accommodation.Form.mcAccommodationListForm", New Structure("SelFilterStatus", 0));	
	#ENDIF
	Notify("Document.Accommodation.ListForm.InHouseGuests");
EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure TotalRoomsInHotelValueClick(Item)
	#IF NOT MobileClient THEN  
		// APDEX
		vKeyOperation = "Catalog.Rooms.Form.tcHousekeepingForm.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

		OpenForm("Catalog.Rooms.Form.tcHousekeepingForm");
	#ELSE
		OpenForm("Catalog.Rooms.Form.mcHousekeepingForm");	
	#ENDIF
EndProcedure //  TotalRoomsInHotelValueClick

// -------------------------------------------------------------------------
&AtClient
Procedure RoomsTableSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	vRoomType = PredefinedValue("Catalog.Rooms.EmptyRef"); 
	vCurData = pItem.CurrentData.GetParent();
	If vCurData = Undefined Then
		vCurData = pItem.CurrentData;
	Else
		vRoomType = pItem.CurrentData.RoomStatus; 
	EndIf;
	vParameters = New Structure("FilterStatus, FilterRoomType", GetValidStatusCode(vCurData.RoomStatus), vRoomType);
	#IF NOT MobileClient THEN  
		// APDEX
		vKeyOperation = "Catalog.Rooms.Form.tcHousekeepingForm.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

		OpenForm("Catalog.Rooms.Form.tcHousekeepingForm", vParameters);
	#ELSE
		OpenForm("Catalog.Rooms.Form.mcHousekeepingForm", vParameters);	
	#ENDIF
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -------------------------------------------------------------------------
&AtClient
Procedure Refresh(Command)
	CancelProlongedOperations();
	Items.SummaryIndexesGroup_Row_1.Visible = False;
	Items.InHouse_Rooms_Value.Visible 		= False;
	Items.InHouse_Adults_Value.Visible 		= False;
	Items.InHouse_Children_Value.Visible 	= False;
	Items.CheckIn_Rooms_Value.Visible 		= False;
	Items.CheckIn_Adults_Value.Visible 		= False;
	Items.CheckIn_Children_Value.Visible 	= False;
	Items.CheckOut_Rooms_Value.Visible 		= False;
	Items.CheckOut_Adults_Value.Visible 	= False;
	Items.CheckOut_Children_Value.Visible 	= False;
	Items.RoomsTable.Visible 				= False;
	
	Items.Loading_picture_SummaryIndexes.Visible 		= True;
	Items.Processing_Picture_InHouse_Row_1.Visible 		= True;
	Items.Processing_Picture_CheckIn_Row_2.Visible 		= True;
	Items.Processing_Picture_CheckOut_Row_2.Visible 	= True;
	Items.Loading_picture_RoomsTable.Visible 			= True;
	StartProlongedOperations();
	RefreshSessionDate();
EndProcedure

#EndRegion

#Region Private

// -------------------------------------------------------------------------
&AtClient 
Procedure HotelChoiceClickAfterConfirmation(pResult, pExtraParams) Export 
	If pResult = DialogReturnCode.Yes Then
		OpenForm("Catalog.Hotels.ChoiceForm", New Structure("ChangeSessionParameter", True), ThisObject);
	EndIf;	
EndProcedure	

// -------------------------------------------------------------------------
&AtServerNoContext
Function GetNumberOfPopUpMessagesForEmployee()
	Return cmGetNumberOfPopUpMessagesForEmployee(SessionParameters.CurrentUser);
EndFunction //  GetNumberOfPopUpMessagesForEmployee

// -------------------------------------------------------------------------
&AtServerNoContext
Function GetPopUpMessagesForEmployee()
	vTasksArray = New Array();
	vTasks = cmGetMessagesForObject(SessionParameters.CurrentUser, False, , False, True, False, Enums.MessageTypes.Message);
	For Each vTasksRow In vTasks Do
		vTasksArray.Add(New Structure("Period, Object, Recorder, Remarks, LastComment", vTasksRow.Period, vTasksRow.Object, vTasksRow.Recorder, vTasksRow.Remarks, vTasksRow.LastComment));
	EndDo;
	Return vTasksArray; 
EndFunction //  GetPopUpMessagesForEmployee

// -------------------------------------------------------------------------
&AtClient
Procedure Attachable_CheckPopupMessages() Export
	If IsInputAvailable() Then
		vNumberOfPopUpMessages = GetNumberOfPopUpMessagesForEmployee();
		If vNumberOfPopUpMessages > 0 And vNumberOfPopUpMessages <> LastNumberOfPopUpMessages Then
			LastNumberOfPopUpMessages = vNumberOfPopUpMessages;
			vMessages = GetPopUpMessagesForEmployee();
			For Each vMessagesRow In vMessages Do
				ShowUserNotification(TrimAll(Format(vMessagesRow.Period, "DF='dd.MM.yyyy HH:mm'") + " " + String(vMessagesRow.Object)), GetURL(vMessagesRow.Recorder), vMessagesRow.Remarks, PictureLib.DialogInformation, UserNotificationStatus.Important, String(vMessagesRow.Recorder.UUID()));
			EndDo;
		EndIf;
		AttachIdleHandler("Attachable_CheckPopupMessages", 10, True);
	Else
		AttachIdleHandler("Attachable_CheckPopupMessages", 2, True);
	EndIf;
EndProcedure //  CheckPopupMessages

// -------------------------------------------------------------------------
&AtServer
Function FillSessionDate()
	If ValueIsFilled(CurrentHotel) And ValueIsFilled(CurrentHotel.AccountingDate) Then
		Return Format(CurrentHotel.AccountingDate, "DF=dd.MM.yyyy");
	Else
		Return Format(CurrentSessionDate(), "DF='dd.MM.yyyy HH:mm'");
	EndIf;
EndFunction //  FillSessionDate

// -------------------------------------------------------------------------
&AtServer
Procedure RefreshSessionDate()
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(CurrentHotel, "BackgroundColorImportant");
	CurrentDateField = FillSessionDate();
EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure StartProlongedOperations()
	BackgroundJobsList.Clear();
	
	// Room statuses
	vProcedureParametrs 	= new Array;
	vTempStorageAdress 	 	= PutToTempStorage(Null);
	vProcedureParametrs.Add(vTempStorageAdress);
	vProcedureParametrs.Add(CurrentHotel);
	
	vBackgroundJob 		 	= StartBackgroundJob("ProlongedOperations.tcDesktop_GetRoomStatusesTable", vProcedureParametrs, vTempStorageAdress);
	
	vnewRow 				= BackgroundJobsList.Add();
	vnewRow.Name 		 	= "tcDesktop_GetRoomStatusesTable";
	vnewRow.UUID 		 	= vBackgroundJob.UUID;
	vnewRow.ResultAddress 	= vBackgroundJob.TempStorageAddress;
	vnewRow.Status 		 	= "Processing";
	
	// Summary indexes
	vProcedureParametrs.Clear();
	vTempStorageAdress 	 	= PutToTempStorage(Null);
	vProcedureParametrs.Add(vTempStorageAdress);
	vProcedureParametrs.Add(CurrentHotel);
	
	vBackgroundJob 		 	= StartBackgroundJob("ProlongedOperations.tcDesktop_GetSummaryPercent", vProcedureParametrs, vTempStorageAdress);
	
	vnewRow 				= BackgroundJobsList.Add();
	vnewRow.Name 		 	= "tcDesktop_GetSummaryPercent";
	vnewRow.UUID 		 	= vBackgroundJob.UUID;
	vnewRow.ResultAddress 	= vBackgroundJob.TempStorageAddress;
	vnewRow.Status 		 	= "Processing";
	
	// Check in/out
	vProcedureParametrs.Clear();
	vTempStorageAdress 	 	= PutToTempStorage(Null);
	vProcedureParametrs.Add(vTempStorageAdress);
	vProcedureParametrs.Add(CurrentHotel);
	
	vBackgroundJob 		 	= StartBackgroundJob("ProlongedOperations.tcDesktop_GetCheckInOutCount", vProcedureParametrs, vTempStorageAdress);
	
	vnewRow 				= BackgroundJobsList.Add();
	vnewRow.Name 		 	= "tcDesktop_GetCheckInOutCount";
	vnewRow.UUID 		 	= vBackgroundJob.UUID;
	vnewRow.ResultAddress 	= vBackgroundJob.TempStorageAddress;
	vnewRow.Status 		 	= "Processing";
	
	// In-house
	vProcedureParametrs.Clear();
	vTempStorageAdress 	 	= PutToTempStorage(Null);
	vProcedureParametrs.Add(vTempStorageAdress);
	vProcedureParametrs.Add(CurrentHotel);
	vProcedureParametrs.Add(EndOfDay(CurrentDate()));
	
	vBackgroundJob 		 	= StartBackgroundJob("ProlongedOperations.tcDesktop_GetInHouse", vProcedureParametrs, vTempStorageAdress);
	
	vnewRow 				= BackgroundJobsList.Add();
	vnewRow.Name 		 	= "tcDesktop_GetInHouse";
	vnewRow.UUID 		 	= vBackgroundJob.UUID;
	vnewRow.ResultAddress 	= vBackgroundJob.TempStorageAddress;
	vnewRow.Status 		 	= "Processing";
	
	AttachIdleHandler("CheckBackgroundJobs",1,False);
EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure CancelProlongedOperations()
	DetachIdleHandler("CheckBackgroundJobs");
	For Each Job In BackgroundJobsList Do
		CancelBackgroundJob(Job.UUID);	
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
Procedure CheckBackgroundJobs()
	vProcessing = False;
	For Each Job In BackgroundJobsList Do 
		If Job.Status = "Processing" Then
			vProcessing = True;
			vBackgroundJob 	= CheckBackgroundJobStatus(Job.UUID);
			If vBackgroundJob <> Undefined Then 
				If vBackgroundJob.Status = "Processing" Then 
					Job.Status = "Processing"; 				
				ElsIf vBackgroundJob.Status = "Error" Then 
					Job.Status = "Error"; 
					vMsg = Nstr("en = 'Background job failed: %1'; de = 'Hintergrundjob fehlgeschlagen: %1'; ru = 'Ошибка выполнения фонового задания: %1'");  
					tcCommonFunctionOnClientServer.UserMessage(StrTemplate(vMsg, Job.Name));
				ElsIf vBackgroundJob.Status = "Canceled" Then 
					Job.Status = "Canceled";
					vMsg = Nstr("en = 'Background job: %1 - canceled'; de = 'Hintergrundjob: %1 - abgebrochen'; ru = 'Фоновое задание:  %1 - отменено'");  
					tcCommonFunctionOnClientServer.UserMessage(StrTemplate(vMsg, Job.Name));					
				ElsIf vBackgroundJob.Status = "Completed" Then 
					Job.Status = "Completed";
					ProcessBackgroundJob(Job);
				EndIf;
			Else
				vMsg = Nstr("en = 'Error in checking background job: %1'; de = 'Fehler bei der Überprüfung des Hintergrundjobs: %1'; ru = 'Ошибка проверки фонового задания: %1'");  
				tcCommonFunctionOnClientServer.UserMessage(StrTemplate(vMsg, Job.Name));
			EndIf;
		EndIf;
	EndDo;
	
	If Not vProcessing Then
		BackgroundJobsList.Clear();
		DetachIdleHandler("CheckBackgroundJobs");
	EndIf;
EndProcedure	

// -------------------------------------------------------------------------
&AtServer
Function CheckBackgroundJobStatus(pBackgroundJobId)
	Return AsyncCalls.CheckBackgroundJob(pBackgroundJobId); 
EndFunction

// -------------------------------------------------------------------------
&AtClient
Procedure ProcessBackgroundJob(pBackgroundJob)
	If pBackgroundJob.Name = "tcDesktop_GetRoomStatusesTable" Then
		Try
			UpdateRoomsTable(pBackgroundJob.ResultAddress);
			Items.RoomsTable.Visible 					= True;
			Items.Loading_picture_RoomsTable.Visible 	= False;
		Except
		EndTry;	
	ElsIf pBackgroundJob.Name = "tcDesktop_GetSummaryPercent" Then
		Try
			UpdateSummaryIndexes_Text(pBackgroundJob.ResultAddress);
			Items.SummaryIndexesGroup_Row_1.Visible 		= True;
			Items.Loading_picture_SummaryIndexes.Visible 	= False;
		Except
		EndTry;	
	ElsIf pBackgroundJob.Name = "tcDesktop_GetCheckInOutCount" Then
		Try
			UpdateCheckInOut(pBackgroundJob.ResultAddress);
			Items.CheckIn_Rooms_Value.Visible		= True;
			Items.CheckIn_Adults_Value.Visible		= True;
			Items.CheckIn_Children_Value.Visible	= True;
			Items.CheckOut_Rooms_Value.Visible		= True;
			Items.CheckOut_Adults_Value.Visible		= True;
			Items.CheckOut_Children_Value.Visible	= True;
			
			Items.Processing_Picture_CheckIn_Row_2.Visible 	= False;
			Items.Processing_Picture_CheckOut_Row_2.Visible = False;
		Except
		EndTry;
	ElsIf pBackgroundJob.Name = "tcDesktop_GetInHouse" Then
		Try
			UpdateInHouse(pBackgroundJob.ResultAddress);
			Items.InHouse_Rooms_Value.Visible 		= True;
			Items.InHouse_Adults_Value.Visible 		= True;
			Items.InHouse_Children_Value.Visible 	= True;
			Items.Processing_Picture_InHouse_Row_1.Visible 	= False;
		Except
		EndTry;
	EndIf;
EndProcedure

// -------------------------------------------------------------------------
&AtServer
Procedure UpdateRoomsTable(pResultAddress)
	vResult = GetFromTempStorage(pResultAddress);
	RoomsTable.GetItems().Clear();
	vRoomQuantity = 0;
	For Each vParentRow In vResult.Rows Do
		vNewParentRow = RoomsTable.GetItems().Add();
		vNewParentRow.RoomStatus = vParentRow.RoomStatus; 
		vNewParentRow.RoomQuantity = vParentRow.RoomQuantity;
		vRoomQuantity = vRoomQuantity + vParentRow.RoomQuantity;
		For Each vChildRow In vParentRow.Rows Do  
			vNewChildRow = vNewParentRow.GetItems().Add();
			vNewChildRow.RoomStatus = vChildRow.RoomStatus;
			vNewChildRow.RoomQuantity = vChildRow.RoomQuantity;
		EndDo;
	EndDo;
	Items.TotalRoomsInHotelValue.Title = String(vRoomQuantity)
EndProcedure

// -------------------------------------------------------------------------
&AtClient
Procedure UpdateSummaryIndexes_Text(pResultAddress)
	vResult = GetFromTempStorage(pResultAddress);
	Items.SummaryIndexes_Text.Title = String(vResult) + "%";
	CreateChart_New(Min(vResult, 100));
EndProcedure

// -------------------------------------------------------------------------
&AtServer
Procedure CreateChart_New(pValue)
	// Get monitor template
	vTemplate = GetCommonTemplate("MonitorTemplate");
	// Get diagram
	vDiagramCDE = vTemplate.GetArea("RoomsSold|Last3Column");
	ChartDiagram = vDiagramCDE.Area("RoomsSoldMeter").Object;	
	// Get occupation percent meter
	ChartDiagram.RefreshEnabled = False;
	ChartDiagram.AutoSeriesText = False;
	ChartDiagram.AutoPointText = False;
	ChartDiagram.BorderColor = StyleColors.FormBackColor;
	ChartDiagram.Clear();
	vSeria = ChartDiagram.Series.Add(NStr("en='Occupancy %'; de='Occupancy %'; ru='% Загрузки'"));
	vPoint = ChartDiagram.Points.Add(NStr("en='By rooms sold';ru='По проданным номерам';de='Nach verkauften Zimmern'"));
	ChartDiagram.SetValue(vPoint, vSeria, pValue);
EndProcedure

// -------------------------------------------------------------------------
&AtClient
Function GetShowTeenagers(pTeenagersResource1, pTeenagersResource2 = 0)
	vShowTeenagers = False;
	If ValueIsFilled(CurrentHotel) Then
		If tcOnServer.cmGetAttributeByRef(CurrentHotel, "TeenagersMaxAge") <> 0 Then
			vShowTeenagers = True;
		EndIf;
	ElsIf pTeenagersResource1 <> 0 Or pTeenagersResource2 <> 0 Then
		vShowTeenagers = True;
	EndIf;
	Return vShowTeenagers;
EndFunction //  GetShowTeenagers

// -------------------------------------------------------------------------
&AtClient
Procedure UpdateCheckInOut(pResultAddress)
	vResult = GetFromTempStorage(pResultAddress);
	Items.CheckIn_Rooms_Value.Title = Format(vResult.CheckInRooms, "NFD=0; NZ=; NG=");
	Items.CheckIn_Adults_Value.Title = Format(vResult.CheckInAdults, "NFD=0; NZ=; NG=");
	Items.CheckOut_Rooms_Value.Title = Format(vResult.CheckOutRooms, "NFD=0; NZ=; NG=");
	Items.CheckOut_Adults_Value.Title = Format(vResult.CheckOutAdults, "NFD=0; NZ=; NG=");

	vShowTeenagers = GetShowTeenagers(vResult.CheckInTeenagers, vResult.CheckOutTeenagers);
	If vShowTeenagers Then
		Items.CheckIn_Children_Value.Title = Format(vResult.CheckInTeenagers, "NFD=0; NZ=; NG=") + "/" + Format(vResult.CheckInChildren, "NFD=0; NZ=; NG=") + "/" + Format(vResult.CheckInInfants, "NFD=0; NZ=; NG=");
		Items.CheckOut_Children_Value.Title = Format(vResult.CheckOutTeenagers, "NFD=0; NZ=; NG=") + "/" + Format(vResult.CheckOutChildren, "NFD=0; NZ=; NG=") + "/" + Format(vResult.CheckOutInfants, "NFD=0; NZ=; NG=");
		Items.CheckIn_Children_Value.ToolTip = NStr("en='Teenagers/Children/Infants'; ru='Подростки/Дети/Младенцы'; de='Teenager/Kinder/Kleinkinder'");
		Items.CheckOut_Children_Value.ToolTip = NStr("en='Teenagers/Children/Infants'; ru='Подростки/Дети/Младенцы'; de='Teenager/Kinder/Kleinkinder'");
	Else
		Items.CheckIn_Children_Value.Title = Format(vResult.CheckInTeenagers + vResult.CheckInChildren, "NFD=0; NZ=; NG=") + "/" + Format(vResult.CheckInInfants, "NFD=0; NZ=; NG=");
		Items.CheckOut_Children_Value.Title = Format(vResult.CheckOutTeenagers + vResult.CheckOutChildren, "NFD=0; NZ=; NG=") + "/" + Format(vResult.CheckOutInfants, "NFD=0; NZ=; NG=");
		Items.CheckIn_Children_Value.ToolTip = NStr("en='Children/Infants'; ru='Дети/Младенцы'; de='Kinder/Kleinkinder'");
		Items.CheckOut_Children_Value.ToolTip = NStr("en='Children/Infants'; ru='Дети/Младенцы'; de='Kinder/Kleinkinder'");
	EndIf;
EndProcedure //  UpdateCheckInOut

// -------------------------------------------------------------------------
&AtClient
Procedure UpdateInHouse(pResultAddress)
	vResult = GetFromTempStorage(pResultAddress);
	Items.InHouse_Rooms_Value.Title = Format(vResult.InHouseRooms, "NFD=0; NZ=; NG=");
	Items.InHouse_Adults_Value.Title = Format(vResult.InHouseAdults, "NFD=0; NZ=; NG=");

	vShowTeenagers = GetShowTeenagers(vResult.InHouseTeenagers);
	If vShowTeenagers Then
		Items.InHouse_Children_Value.Title = Format(vResult.InHouseTeenagers, "NFD=0; NZ=; NG=") + "/" + Format(vResult.InHouseChildren, "NFD=0; NZ=; NG=") + "/" + Format(vResult.InHouseInfants, "NFD=0; NZ=; NG=");
		Items.InHouse_Children_Value.ToolTip = NStr("en='Teenagers/Children/Infants'; ru='Подростки/Дети/Младенцы'; de='Teenager/Kinder/Kleinkinder'");
	Else
		Items.InHouse_Children_Value.Title = Format(vResult.InHouseTeenagers + vResult.InHouseChildren, "NFD=0; NZ=; NG=") + "/" + Format(vResult.InHouseInfants, "NFD=0; NZ=; NG=");
		Items.InHouse_Children_Value.ToolTip = NStr("en='Children/Infants'; ru='Дети/Младенцы'; de='Kinder/Kleinkinder'");
	EndIf;
EndProcedure //  UpdateInHouse

// -------------------------------------------------------------------------
&AtServer
Function GetValidStatusCode(pStatus)
	Return cmGetValidName(TrimAll(pStatus.Code));
EndFunction

#EndRegion
