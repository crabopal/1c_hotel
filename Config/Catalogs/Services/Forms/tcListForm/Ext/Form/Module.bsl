
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	SelHotel = SessionParameters.CurrentHotel;
	SelClientType = Catalogs.ClientTypes.EmptyRef();
	If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
		pCancel = True;
	Else
		If Not Parameters.Filter.Property("Hotel") Then		
			vArray = New Array;
			vArray.Add(SelHotel);
			vArray.Add(Catalogs.Hotels.EmptyRef());		
			Parameters.Filter.Insert("Hotel", vArray);
		EndIf;	
	EndIf;
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
	// Set list parameters
	List.Parameters.SetParameterValue("qPeriod", CurrentSessionDate());
	List.Parameters.SetParameterValue("qHotel", SelHotel);
	List.Parameters.SetParameterValue("qClientType", SelClientType);
	// Choice mode
	If Parameters.Property("ChoiceMode") And Parameters.ChoiceMode Then
		Items.List.ChoiceMode = True;
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "System.ServicePrices.Write" Or pEventName = "MergeAnyRefs.Change" Then
		Items.List.Refresh();
	EndIf;
EndProcedure // NotificationProcessing

// --------------------------------------------------------------------------------
&AtClient
Procedure SelClientTypeOnChange(pItem)
	SelClientTypeOnChangeAtServer();
EndProcedure // SelClientTypeOnChange

#EndRegion

#Region FormTableListItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ListBeforeDeleteRow(pItem, pCancel)
	If ListBeforeDeleteRowAtServer() Then
		Cancel = True;
		ShowMessageBox(, NStr("en = 'You do not have rights for services and prices management!'; 
							  |de = 'Sie haben keine Rechte, Dienstleistungen und Preise zu verwalten!'; 
							  |ru = 'Нет прав на управление услугами и ценами!'"));
	EndIf;
EndProcedure // ListBeforeDeleteRow

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ActionMergeServices(pCommand)
	vCurRow = Items.List.CurrentRow;
	If vCurRow = Undefined Then
		ShowMessageBox(,NStr("en = 'Choose at least one service first!'; de = 'Wählen Sie zuerst mindestens einen Service!'; ru = 'Выберите как минимум одну услугу!'"));
		Return;
	EndIf;
	If tcOnServer.cmGetAttributeByRef(vCurRow, "IsFolder") Then
		ShowMessageBox(,NStr("en = 'Do not choose service folders!'; de = 'Wählen Sie keine Serviceordner!'; ru = 'Нельзя выбирать группы услуг!'"));
		Return;
	EndIf;
	vParam = New Structure();
	vParam.Insert("SelDefaultTypeDescription", New TypeDescription("CatalogRef.Services"));
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
EndProcedure // ActionMergeServices

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServerNoContext
Function ListBeforeDeleteRowAtServer()
	Return Not cmCheckUserPermissions("HavePermissionToManagePrices");
EndFunction // ListBeforeDeleteRowAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure SelClientTypeOnChangeAtServer()
	List.Parameters.SetParameterValue("qPeriod", CurrentSessionDate());
	List.Parameters.SetParameterValue("qClientType", SelClientType);
EndProcedure

#EndRegion
   