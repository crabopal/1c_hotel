
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	ClientType = Catalogs.ClientTypes.EmptyRef();
	If Parameters.Property("ClientType") And ValueIsFilled(Parameters.ClientType) And Not Parameters.ClientType.IsFolder Then
		ClientType = Parameters.ClientType;
	EndIf;
	Hotel = SessionParameters.CurrentHotel;
	If Parameters.Property("Hotel") And ValueIsFilled(Parameters.Hotel) And Not Parameters.Hotel.IsFolder Then
		Hotel = Parameters.Hotel;
	EndIf;
	AccountingDate = CurrentSessionDate();
	If Parameters.Property("AccountingDate") And ValueIsFilled(Parameters.AccountingDate) Then
		AccountingDate = Parameters.AccountingDate;
	EndIf;
	UseForecast = True;
	If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.AccountingDate) Then
		If BegOfDay(AccountingDate) < Hotel.AccountingDate Then
			UseForecast = False;
		EndIf;
	Else
		If BegOfDay(AccountingDate) < BegOfDay(CurrentSessionDate()) Then
			UseForecast = False;
		EndIf;
	EndIf;
	Parent = Catalogs.Services.EmptyRef();
	If Parameters.Property("Parent") And ValueIsFilled(Parameters.Parent) And Parameters.Parent.IsFolder Then
		Parent = Parameters.Parent;
	EndIf;
	If Parameters.Property("UseMarking") And Parameters.UseMarking Then
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "Ref.UseMarking", True, DataCompositionComparisonType.Equal, , True, DataCompositionSettingsItemViewMode.Inaccessible);
	EndIf;
	If ValueIsFilled(AccountingDate) Then
		Items.Quantity.Title = Items.Quantity.Title + " (" + Format(AccountingDate, "DF=dd.MM.yyyy") + ")";
	EndIf;
	SetDynamicParameters();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientTypeOnChange(pItem)
	SetDynamicParameters();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure TreeSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	SetDynamicParameters();
EndProcedure // TreeSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure TreeBeforeRowChange(pItem, pCancel)
	pCancel = True;
	SetDynamicParameters();
EndProcedure // TreeBeforeRowChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ListSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	If pItem.CurrentData <> Undefined Then
		NotifyChoice(pItem.CurrentData.Ref);
	EndIf;
EndProcedure // ListSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure ListValueChoice(pItem, pValue, pStandardProcessing)
	pStandardProcessing = False;
	If pItem.CurrentData <> Undefined Then
		NotifyChoice(pItem.CurrentData.Ref);
	EndIf;
EndProcedure // ListValueChoice

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure SetDynamicParameters()
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(Hotel, "BackgroundColorImportant");
	
	vParent = Parent;
	vTreeRow = Items.TreeServices.CurrentRow;
	If Not vTreeRow = Undefined Then
		vParent = vTreeRow;
	EndIf;
	
	List.Parameters.SetParameterValue("qHotel", Hotel);
	List.Parameters.SetParameterValue("qHotelIsFilled", ValueIsFilled(Hotel)); 
	List.Parameters.SetParameterValue("qParent", vParent);
	List.Parameters.SetParameterValue("qAccountingDate", AccountingDate);
	List.Parameters.SetParameterValue("qBegOfAccountingDate", BegOfDay(AccountingDate));
	List.Parameters.SetParameterValue("qClientType", ClientType); 
	List.Parameters.SetParameterValue("qClientTypeIsFilled", ValueIsFilled(ClientType)); 
	List.Parameters.SetParameterValue("qUseForecast", UseForecast);
	
	vUseServicesList = False;
	vServicesList = New ValueList();
	vPermGrp = cmGetEmployeePermissionGroup(SessionParameters.CurrentUser);
	If ValueIsFilled(vPermGrp) And ValueIsFilled(vPermGrp.ServicesServiceGroup) Then
		vUseServicesList = True;
		vTopLevelParent = Undefined;
		vServicesList = cmGetServiceGroupServices(vPermGrp.ServicesServiceGroup, vTopLevelParent);
		If vTopLevelParent <> Undefined Then
			Items.List.TopLevelParent = vTopLevelParent;
			Items.TreeServices.TopLevelParent = vTopLevelParent;
		EndIf;
	EndIf;
	List.Parameters.SetParameterValue("qUseServicesList", vUseServicesList);
	List.Parameters.SetParameterValue("qServicesList", vServicesList);
	
	vHotelsList = New ValueList();
	vHotelsList.Add(Catalogs.Hotels.EmptyRef());
	If ValueIsFilled(Hotel) Then
		vHotelsList.Add(Hotel);
	EndIf;
	vNewFilter = TreeServices.SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	vNewFilter.LeftValue = New DataCompositionField("Hotel");
	vNewFilter.ComparisonType = DataCompositionComparisonType.InList;
	vNewFilter.RightValue = vHotelsList;
	vNewFilter.Use = True;
	vNewFilter.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
EndProcedure

#EndRegion
