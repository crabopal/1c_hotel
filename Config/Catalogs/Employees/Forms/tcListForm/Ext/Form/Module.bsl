
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	vPermGrp = cmGetEmployeePermissionGroup(SessionParameters.CurrentUser);
	If ValueIsFilled(vPermGrp) And ValueIsFilled(vPermGrp.EmployeesFolder) Then
		Parameters.Filter.Insert("Parent", vPermGrp.EmployeesFolder);
		Items.List.TopLevelParent = vPermGrp.EmployeesFolder;
		Items.Tree.TopLevelParent = vPermGrp.EmployeesFolder;
	EndIf;
	If Not IsInRole("Administrator") Then
		vHotels = Catalogs.Hotels.GetHotelAllowedList();
		If IsInRole("RightsToChooseHotel") And vHotels.Count() > 0 Then
			vHotels.Add(Catalogs.Hotels.EmptyRef());
			Parameters.Filter.Insert("Hotel", vHotels);
		Else 
			vArray = New Array;
			vArray.Add(SessionParameters.CurrentHotel);    
			vArray.Add(Catalogs.Hotels.EmptyRef());    
			Parameters.Filter.Insert("Hotel", vArray);
		EndIf;
		If ValueIsFilled(vPermGrp) And Not ValueIsFilled(vPermGrp.EmployeesFolder) Then    
			vErr = NStr("en='No access rights!'; ru='Нет прав доступа!'; de='Keine Zugriffsrechte!'"); 
			Raise vErr;
		EndIf;
	EndIf;
	List.Parameters.SetParameterValue("qCurrUser", SessionParameters.CurrentUser);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "MergeAnyRefs.Change" Then
		Items.List.Refresh();
	EndIf;
EndProcedure // NotificationProcessing

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionMergeEmployee(pCommand)
	vCurRow = Items.List.CurrentRow;
	If vCurRow = Undefined Then
		ShowMessageBox(, NStr("en = 'Choose at least one employee first!'; de = 'Wählen Sie zuerst mindestens einen Mitarbeiter!'; ru = 'Выберите как минимум одного сотрудника!'"));
		Return;
	EndIf;
	If tcOnServer.cmGetAttributeByRef(vCurRow, "IsFolder") Then
		ShowMessageBox(, NStr("en = 'Do not choose employees folders!'; de = 'Wählen Sie keine Mitarbeiterordner!'; ru = 'Нельзя выбирать группы сотрудников!'"));
		Return;
	EndIf;
	vParam = New Structure();
	vParam.Insert("SelDefaultTypeDescription", New TypeDescription("CatalogRef.Employees"));
	vParam.Insert("SelMergedRef", vCurRow);
	If Items.List.SelectedRows.Count() > 1 Then
		vFirstSelRow = Items.List.SelectedRows.Get(0);
		If Not tcOnServer.cmGetAttributeByRef(vFirstSelRow, "IsFolder") Then
			vParam.Insert("SelMergedRef", vFirstSelRow);
		EndIf;
		vLastSelRow = Items.List.SelectedRows.Get(Items.List.SelectedRows.Count() - 1);
		If Not tcOnServer.cmGetAttributeByRef(vLastSelRow, "IsFolder") And vLastSelRow <> vFirstSelRow Then
			vParam.Insert("SelMainRef", vLastSelRow);
		EndIf;
	EndIf;
	OpenForm("DataProcessor.MergeAnyRefs.Form", vParam, ThisObject, UUID);	
EndProcedure // ActionMergeEmployee

#EndRegion
