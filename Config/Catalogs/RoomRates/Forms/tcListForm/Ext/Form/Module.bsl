
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	SelHotel = SessionParameters.CurrentHotel;
	If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
		pCancel = True;
	Else
		List.Parameters.SetParameterValue("qHotel", SessionParameters.CurrentHotel);
		List.Parameters.SetParameterValue("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	EndIf;
	
	vHotelList = New Array;
	vHotelList.Add(SessionParameters.CurrentHotel);
	vHotelList.Add(Catalogs.Hotels.EmptyRef());
	
	vNewFilter = Tree.SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	vNewFilter.LeftValue = New DataCompositionField("Hotel");
	vNewFilter.ComparisonType = DataCompositionComparisonType.InList;
	vNewFilter.RightValue = vHotelList;
	vNewFilter.Use = True;
	vNewFilter.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
EndProcedure

#EndRegion

#Region FormTableListItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ListBeforeDeleteRow(pItem, pCancel)
	If Not HasPermissionToManagePrices() Then
		pCancel = True;
		ShowMessageBox(, NStr("en='You do not have rights for services and prices management!';
		                      |ru='Нет прав на управление услугами и ценами!';
							  |de='Sie haben keine Rechte, Dienstleistungen und Preise zu verwalten!'"));
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ListDragEnd(pItem, pDragParameters, pStandardProcessing)
	If Not HasPermissionToManagePrices() Then
		pStandardProcessing = False;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights for services and prices management!';
		                                                |ru='Нет прав на управление услугами и ценами!';
							                            |de='Sie haben keine Rechte, Dienstleistungen und Preise zu verwalten!'"),
		                                           MessageStatus.Attention);
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CommandCopy(Command)
	If Items.List.CurrentRow <> Undefined Then
		vParams = New Structure("BaseRate",Items.List.CurrentRow);
		OpenForm("Catalog.RoomRates.Form.CopyAssistant",vParams);
	EndIf;
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServerNoContext
Function HasPermissionToManagePrices()
	Return cmCheckUserPermissions("HavePermissionToManagePrices");
EndFunction

#EndRegion

