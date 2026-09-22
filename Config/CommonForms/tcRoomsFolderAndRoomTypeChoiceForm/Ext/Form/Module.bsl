
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	SelHotel = SessionParameters.CurrentHotel;
	vRoom = SystemSettingsStorage.Load("tcRoomsGanttChartSelRoom", SessionParameters.CurrentUser);
	If ValueIsFilled(vRoom) And vRoom.Owner = SelHotel Then
		SelRoom = vRoom;
	Else
		If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Room) Then
			SelRoom = SessionParameters.CurrentUser.Room;
		EndIf;
	EndIf;
	vRoomClass = SystemSettingsStorage.Load("tcRoomsGanttChartSelRoomClass", SessionParameters.CurrentUser);
	If ValueIsFilled(vRoomClass) And vRoomClass.Owner = SelHotel Then
		SelRoomClass = vRoomClass;
	EndIf;
	vRoomType = SystemSettingsStorage.Load("tcRoomsGanttChartSelRoomType", SessionParameters.CurrentUser);
	If ValueIsFilled(vRoomType) And vRoomType.Owner = SelHotel Then
		SelRoomType = vRoomType;
	Else
		If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.RoomType) Then
			SelRoomType = SessionParameters.CurrentUser.RoomType;
		EndIf;
	EndIf;
	SelPeriodFrom = BegOfDay(CurrentSessionDate()) - 1*3600*24;
	vShowBookingsWithoutRooms = SystemSettingsStorage.Load("tcRoomsGanttChartSelShowBookingsWithoutRooms", SessionParameters.CurrentUser);
	If vShowBookingsWithoutRooms <> Undefined Then
		SelShowBookingsWithoutRooms = vShowBookingsWithoutRooms;
	Else
		SelShowBookingsWithoutRooms = False;
	EndIf;
	vShowPreliminary = SystemSettingsStorage.Load("tcRoomsGanttChartSelShowPreliminary", SessionParameters.CurrentUser);
	If vShowPreliminary <> Undefined Then
		SelShowPreliminary = vShowPreliminary;
	Else
		SelShowPreliminary = False;
	EndIf;
	vRoomsPerPage = SystemSettingsStorage.Load("tcRoomsGanttChartRoomsPerPage", SessionParameters.CurrentUser);
	If vRoomsPerPage <> Undefined Then
		SelRoomsPerPage = vRoomsPerPage;
	Else
		SelRoomsPerPage = 30;
	EndIf;
	vShowPageByPageGanttChart = False;
	If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.EmployeePreferences) Then
		vShowPageByPageGanttChart = SessionParameters.CurrentUser.EmployeePreferences.ShowPageByPageGanttChart;
	EndIf;
	Items.SelRoomsPerPage.Visible = vShowPageByPageGanttChart;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ContinueProcessing(pCommand)
	// APDEX
	vKeyOperation = "CommonForm.tcRoomsGanttChart.OpenForm";
	APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);
	// Save current values to user settings
	SaveFormAttributesAtServer();
	// Build structure with values selected
	vStruct = New Structure("SelRoom, SelRoomClass, SelRoomType, SelRoomTypes, SelPeriodFrom, SelShowBookingsWithoutRooms, SelShowPreliminary", SelRoom, SelRoomClass, SelRoomType, SelRoomTypes, SelPeriodFrom, SelShowBookingsWithoutRooms, SelShowPreliminary);
	// Close current form
	ThisForm.Close();
	// Open gantt chart form
	vShowPageByPageGanttChart = False;
	vCurrentUser = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
	If ValueIsFilled(vCurrentUser) Then
		vEmployeePreferences = tcOnServer.cmGetAttributeByRef(vCurrentUser, "EmployeePreferences");
		If ValueIsFilled(vEmployeePreferences) Then
			vShowPageByPageGanttChart = tcOnServer.cmGetAttributeByRef(vEmployeePreferences, "ShowPageByPageGanttChart");
		EndIf;
	EndIf;
	If vShowPageByPageGanttChart Then
		OpenForm("CommonForm.tcRoomsGanttChart", vStruct);
	Else
		OpenForm("CommonForm.tcRoomsGanttChartHTML", vStruct);
	EndIf;
EndProcedure // ContinueProcessing

#EndRegion  

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveFormAttributesAtServer()
	SystemSettingsStorage.Save("tcRoomsGanttChartSelRoom", SessionParameters.CurrentUser, SelRoom);
	SystemSettingsStorage.Save("tcRoomsGanttChartSelRoomClass", SessionParameters.CurrentUser, SelRoomClass);
	SystemSettingsStorage.Save("tcRoomsGanttChartSelRoomType", SessionParameters.CurrentUser, SelRoomType);
	SystemSettingsStorage.Save("tcRoomsGanttChartSelShowBookingsWithoutRooms", SessionParameters.CurrentUser, SelShowBookingsWithoutRooms);
	SystemSettingsStorage.Save("tcRoomsGanttChartSelShowPreliminary", SessionParameters.CurrentUser, SelShowPreliminary);
	SystemSettingsStorage.Save("tcRoomsGanttChartRoomsPerPage", SessionParameters.CurrentUser, SelRoomsPerPage);
EndProcedure // SaveFormAttributesAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetRoomTypesForSelection(pRoomType, pRoomClass, pHotel, pRoomTypesList)
	vRoomTypesList = New ValueList;
	vRoomTypes = cmGetAllRoomTypes(pHotel, pRoomType, pRoomClass);
	For Each vRoomTypesRow In vRoomTypes Do
		vRoomTypesList.Add(vRoomTypesRow.RoomType, , ?(pRoomTypesList.FindByValue(vRoomTypesRow.RoomType) = Undefined, False, True));
	EndDo;
	Return vRoomTypesList;
EndFunction // GetRoomTypesForSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomTypesStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vRoomTypesList = GetRoomTypesForSelection(SelRoomType, SelRoomClass, SelHotel, SelRoomTypes);
	vRoomTypesList.ShowCheckItems(New NotifyDescription("SelRoomTypesEndChoice", ThisForm), NStr("en='Select room types'; ru='Отметьте типы номеров'; de='Zimmertypen auswählen'"));
EndProcedure // SelRoomTypesStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomTypesEndChoice(pRoomTypesList, pExtraParams) Export
	If pRoomTypesList <> Undefined Then
		SelRoomTypes.Clear();
		For Each vRoomTypesListItem In pRoomTypesList Do
			If vRoomTypesListItem.Check Then
				SelRoomTypes.Add(vRoomTypesListItem.Value);
			EndIf;
		EndDo;
	EndIf;
EndProcedure // SelRoomTypesEndChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomTypesClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
	SelRoomTypes.Clear();
EndProcedure // SelRoomTypesClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomsPerPageOnChange(pItem)
	If SelRoomsPerPage < 10 Then
		SelRoomsPerPage = 30;
	EndIf;
EndProcedure // SelRoomsPerPageOnChange

#EndRegion