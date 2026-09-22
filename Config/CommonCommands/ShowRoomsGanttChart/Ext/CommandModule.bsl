
#Region EventHandlers

// ----------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	If amPersistentObjects.Property("IsLockApplication") Then
		If amPersistentObjects.IsLockApplication Then
			Return;	
		EndIf;	
	EndIf;	
	vShowFilters = True;
	If Not CheckUserPermission(vShowFilters) Then
		Raise NStr("en='You do not have rights to this function!';ru='Нет прав на эту функцию!';de='Sie haben keine Rechte für diese Funktion!'");
	EndIf;
	If vShowFilters Then
		// Open filters for gantt chart form
		OpenForm("CommonForm.tcRoomsFolderAndRoomTypeChoiceForm", , pCommandExecuteParameters.Source, pCommandExecuteParameters.Uniqueness, pCommandExecuteParameters.Window);
	Else
		// APDEX
		vKeyOperation = "CommonForm.tcRoomsGanttChart.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

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
			OpenForm("CommonForm.tcRoomsGanttChart");
		Else
			OpenForm("CommonForm.tcRoomsGanttChartHTML");
		EndIf;
	EndIf;
EndProcedure // CommandProcessing

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
// 
// Returns:
//  Boolean - have user permission
//
&AtServer
Function CheckUserPermission(rShowFilters)
	rShowFilters = True;
	If ValueIsFilled(SessionParameters.CurrentHotel) Then
		rShowFilters = SessionParameters.CurrentHotel.ShowFiltersPageForGanttChart;
	EndIf;
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		If Not ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
			Return True;
		EndIf;
	EndIf;
	Return False;
EndFunction // CheckUserPermission

#EndRegion             
