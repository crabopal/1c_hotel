
#Region Variables

&AtClient
Var CurrentDataRef;

#EndRegion

#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	List.Parameters.SetParameterValue("qClientSex", Enums.Sex.Male);
	List.Parameters.SetParameterValue("qSexMale", 26);
	List.Parameters.SetParameterValue("qSexFemale", 27);
	
	If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
		List.Parameters.SetParameterValue("qAuthor", SessionParameters.CurrentUser);
	Else
		List.Parameters.SetParameterValue("qAuthor", Catalogs.Employees.EmptyRef());
	EndIf;
	
	If Parameters.Property("SelLastName") Then
		SelLastName = Parameters.SelLastName;
	Else
		If Parameters.Property("CurrentRow") Then
			If TypeOf(Parameters.CurrentRow) = Type("CatalogRef.Clients") Then
				vClient = Parameters.CurrentRow;
				SelLastName = TrimR(vClient.LastName);
				SelFirstName = TrimR(vClient.FirstName);
				SelSecondName = TrimR(vClient.SecondName);
				SelDateOfBirth = vClient.DateOfBirth;
				SelIdentityDocumentNumber = TrimR(vClient.IdentityDocumentNumber);
				SelIdentityDocumentSeries = TrimR(vClient.IdentityDocumentSeries);
				SelIdentityDocumentIssueDate = vClient.IdentityDocumentIssueDate;
				SelPhone = TrimR(vClient.Phone);
				SelEMail = TrimR(vClient.EMail);
			EndIf;
		EndIf;
	EndIf;
	If Parameters.Property("SelFirstName") Then
		SelFirstName = Parameters.SelFirstName;
	EndIf;
	If Parameters.Property("SelSecondName") Then
		SelSecondName = Parameters.SelSecondName;
	EndIf;
	If Parameters.Property("SelDateOfBirth") Then
		SelDateOfBirth = Parameters.SelDateOfBirth;
	EndIf;
	If Parameters.Property("SelIdentityDocumentNumber") Then
		SelIdentityDocumentNumber = Parameters.SelIdentityDocumentNumber;
	EndIf;
	If Parameters.Property("SelIdentityDocumentSeries") Then
		SelIdentityDocumentSeries = Parameters.SelIdentityDocumentSeries;
	EndIf;
	If Parameters.Property("SelIdentityDocumentIssueDate") Then
		SelIdentityDocumentIssueDate = Parameters.SelIdentityDocumentIssueDate;
	EndIf;
	If Parameters.Property("SelPhone") Then
		SelPhone = Parameters.SelPhone;
	EndIf;
	If Parameters.Property("SelTag") Then
		SelTag = Parameters.SelTag;
	EndIf;
	If Parameters.Property("SelClientType") Then
		SelClientType = Parameters.SelClientType;
	EndIf;
	vChoiceMode = False;
	If Parameters.Property("ChoiceMode", vChoiceMode) Then
		If vChoiceMode <> Undefined Then
			Items.List.ChoiceMode = vChoiceMode;
		EndIf;
	EndIf;
	vMultipleChoiceMode = False;
	If Parameters.Property("MultipleChoice", vMultipleChoiceMode) Then
		If vMultipleChoiceMode <> Undefined Then
			Items.List.MultipleChoice = vMultipleChoiceMode;
		EndIf;
	EndIf;
	List.Parameters.SetParameterValue("qTag", SelTag);
	List.Parameters.SetParameterValue("qTagIsFilled", ValueIsFilled(SelTag));
	List.Parameters.SetParameterValue("qClientType", SelClientType);
	List.Parameters.SetParameterValue("qClientTypeIsFilled", ValueIsFilled(SelClientType));

	ShowDeleted = False;
	vShowDeleted = SystemSettingsStorage.Load("Catalog.Clients.tcListForm", "ShowDeleted");
	If vShowDeleted <> Undefined Then
		ShowDeleted = vShowDeleted;
	EndIf;
	List.Parameters.SetParameterValue("qShowDeleted", ShowDeleted);
	Items.ListShowDeleted.Check = ShowDeleted;
	
	// Check user rights to see data from different hotels
    vCheckUserRightsForHotel = False;
	vAllowedHotels = New ValueList();
	If Not IsInRole("RightsToChooseHotel") Then
	    vCheckUserRightsForHotel = True;
		vAllowedHotels.Add(SessionParameters.CurrentHotel);
	ElsIf ValueIsFilled(SessionParameters.CurrentUser) Then
		vPermissionGroup = SessionParameters.CurrentUser.PermissionGroup;
		vNonReplAttrs = CachedSettings.сmGetEmployeeNonReplicatingAttributes(SessionParameters.CurrentUser);
		If vNonReplAttrs.Count() > 0 Then
			If ValueIsFilled(vNonReplAttrs.Get(0).PermissionGroup) Then
				vPermissionGroup = vNonReplAttrs.Get(0).PermissionGroup;
			EndIf;
		EndIf;
		If ValueIsFilled(vPermissionGroup) Then
			If vPermissionGroup.HotelAllowed.Count() > 0 Then
			    vCheckUserRightsForHotel = True;
				If ValueIsFilled(SessionParameters.CurrentHotel) Then
					If vAllowedHotels.FindByValue(SessionParameters.CurrentHotel) = Undefined Then
						vAllowedHotels.Add(SessionParameters.CurrentHotel);
					EndIf;
				EndIf;
				For Each vHotelAllowedRow In vPermissionGroup.HotelAllowed Do
					If ValueIsFilled(vHotelAllowedRow.Hotel) Then
						If vAllowedHotels.FindByValue(vHotelAllowedRow.Hotel) = Undefined Then
							vAllowedHotels.Add(vHotelAllowedRow.Hotel);
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		Else
		    vCheckUserRightsForHotel = True;
		EndIf;
	Else
	    vCheckUserRightsForHotel = True;
	EndIf;
	AdvanceList.Parameters.SetParameterValue("qCheckUserRightsForHotel", vCheckUserRightsForHotel);
	AdvanceList.Parameters.SetParameterValue("qAllowedHotels", vAllowedHotels);
	AdvanceList.Parameters.SetParameterValue("qClient", Undefined);
	
	FilterSame();
	
	// Dynamic appearance
	AddListDynamicConditionalAppearance();
	
	// Check rights to print list of all clients
	If Not tcOnServer.CheckIfHotelCouldBeCleared() Then
		Items.ListOutputList.Enabled = False;
		Items.ListOutputList.Visible = False;
	EndIf;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If FormOwner <> Undefined And TypeOf(FormOwner) = Type("FormField") Then
		If  ValueIsFilled(FormOwner.EditText) And Not GuestNameFieldsIsFilled() Then
			SelLastName = tcOnServer.cmGetCatalogItemRefByDescription("Clients", FormOwner.EditText, False, "LastName");
			SelFirstName = tcOnServer.cmGetCatalogItemRefByDescription("Clients", FormOwner.EditText, False, "FirstName");	
			SelSecondName = tcOnServer.cmGetCatalogItemRefByDescription("Clients", FormOwner.EditText, False, "SecondName");
		EndIf;
	EndIf;
	If ValueIsFilled(SelLastName) Then
		SelLastName = Title(SelLastName);
		AddNewFilter("SelLastName", SelLastName);
	EndIf;
	If ValueIsFilled(SelFirstName) Then
		SelFirstName = Title(SelFirstName);
		AddNewFilter("SelFirstName", SelFirstName);
	EndIf;
	If ValueIsFilled(SelSecondName) Then
		SelSecondName = Title(SelSecondName);
		AddNewFilter("SelSecondName", SelSecondName);
	EndIf;
	If ValueIsFilled(SelDateOfBirth) Then
		AddNewFilter("SelDateOfBirth", SelDateOfBirth, True);
	EndIf;
	If ValueIsFilled(SelIdentityDocumentNumber) Then
		AddNewFilter("SelIdentityDocumentNumber", SelIdentityDocumentNumber, True);
	EndIf;
	If ValueIsFilled(SelIdentityDocumentSeries) Then
		AddNewFilter("SelIdentityDocumentSeries", SelIdentityDocumentSeries, True);
	EndIf;
	If ValueIsFilled(SelIdentityDocumentIssueDate) Then
		AddNewFilter("SelIdentityDocumentIssueDate", SelIdentityDocumentIssueDate, True);
	EndIf;
	If ValueIsFilled(SelPhone) Then
		AddNewFilter("SelPhone", SelPhone, , True);
	EndIf;
	If ValueIsFilled(SelEMail) Then
		AddNewFilter("SelEMail", SelEMail, , True);
	EndIf;
	If ValueIsFilled(SelClientType) Then
		AddNewFilter("SelClientType", SelClientType, True);
	EndIf;
	If ValueIsFilled(SelTag) Then
		AddNewFilter("SelTag", SelTag);
	EndIf;
EndProcedure // OnOpen

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "MergeAnyRefs.Change" Then
		CurrentDataRef = Undefined;
		Items.List.Refresh();
		ListOnActivateRow(Items.List);
	ElsIf pEventName = "SearchSameClients.Result" And pSource = ThisObject Then
		If TypeOf(pParameter) = Type("ValueList") Then
			SelClientsList.LoadValues(pParameter.UnloadValues());
			FilterSame();
		EndIf;
	EndIf;
EndProcedure // NotificationProcessing

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SelLastNameOnChange(pItem)
	If IsBlankString(SelLastName) Then
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "LastName", , , , False);
	Else
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "LastName", pItem.EditText, DataCompositionComparisonType.BeginsWith, , True);
	EndIf;
EndProcedure // SelLastNameOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelFirstNameOnChange(pItem)
	If IsBlankString(SelFirstName) Then
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "FirstName", , , , False);
	Else
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "FirstName", pItem.EditText, DataCompositionComparisonType.BeginsWith, , True);
	EndIf;
EndProcedure // SelFirstNameOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelSecondNameOnChange(pItem)
	If IsBlankString(SelSecondName) Then
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "SecondName", , , , False);
	Else
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "SecondName", pItem.EditText, DataCompositionComparisonType.BeginsWith, , True);
	EndIf;
EndProcedure // SelSecondNameOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelDateOfBirthOnChange(pItem)
	If Not ValueIsFilled(SelDateOfBirth) Then
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "DateOfBirth", , , , False);
	Else
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "DateOfBirth", SelDateOfBirth, DataCompositionComparisonType.Equal, , True);
	EndIf;
EndProcedure // SelDateOfBirthOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelIdentityDocumentNumberOnChange(pItem)
	If IsBlankString(SelIdentityDocumentNumber) Then
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "IdentityDocumentNumber", , , , False);
	Else
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "IdentityDocumentNumber", pItem.EditText, DataCompositionComparisonType.Equal, , True);
	EndIf;
EndProcedure // SelIdentityDocumentNumberOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelIdentityDocumentSeriesOnChange(pItem)
	If IsBlankString(SelIdentityDocumentSeries) Then
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "IdentityDocumentSeries", , , , False);
	Else
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "IdentityDocumentSeries", pItem.EditText, DataCompositionComparisonType.Equal, , True);
	EndIf;
EndProcedure // SelIdentityDocumentSeriesOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelIdentityDocumentIssueDateOnChange(pItem)
	If Not ValueIsFilled(SelIdentityDocumentIssueDate) Then
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "IdentityDocumentIssueDate", , , , False);
	Else
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "IdentityDocumentIssueDate", SelIdentityDocumentIssueDate, DataCompositionComparisonType.Equal, , True);
	EndIf;
EndProcedure // SelIdentityDocumentIssueDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelPhoneNumberOnChange(pItem)
	If IsBlankString(SelPhone) Then
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "Phone", , , , False);
	Else
		SelPhone = SMS.GetValidPhoneNumber(SelPhone);
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "Phone", SelPhone, DataCompositionComparisonType.Contains, , True);
	EndIf;	
EndProcedure // SelPhoneNumberOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelEMailOnChange(pItem)
	If IsBlankString(SelEMail) Then
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "EMail", , , , False);
	Else
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "EMail", SelEMail, DataCompositionComparisonType.Contains, , True);
	EndIf;
EndProcedure // SelEMailOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelTagOnChange(pItem)
	AddNewFilter(pItem.Name, SelTag);
EndProcedure // SelTagOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelClientTypeOnChange(pItem)
	AddNewFilter(pItem.Name, SelClientType);
EndProcedure // SelClientTypeOnChange

#EndRegion

#Region FormTableItemsEventHandlers

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure ListOnGetDataAtServer(pItemName, pSettings, pRows)
	// Colors and other appearances
	For Each vRow In pRows Do
		vRowValue = vRow.Value;
		// Set row back color for the reservations according to the discount card discount type colors
		vDCDT = vRowValue.Data["DiscountCardDiscountType"];
		If ValueIsFilled(vDCDT) Then
			vDCDTAppearance = vRowValue.Appearance.Get("DiscountCardDiscountType");
			If vDCDTAppearance <> Undefined Then
				vColor = tcCommonFunctionOnClientServer.cmGetColorFromValueStorage(vDCDT);
				If vColor <> Undefined Then
					vDCDTAppearance.SetParameterValue("BackColor", vColor);
				EndIf;
			EndIf;
		EndIf;
	EndDo;
EndProcedure // ListOnGetDataAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AdvanceListSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	vRowData = Items.AdvanceList.RowData(pSelectedRow);
	If vRowData <> Undefined Then
		If ValueIsFilled(vRowData.Document) Then
			ShowValue(, vRowData.Document);
		EndIf;
	EndIf;
EndProcedure // AdvanceListSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure ListBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	pCancel = True;
	vParameters = New Structure("FormData", 
								New Structure(
										"LastName,   SecondName,    FirstName,    DateOfBirth,    IdentityDocumentSeries,    IdentityDocumentNumber,    IdentityDocumentIssueDate,    EMail,    Phone",
										SelLastName, SelSecondName, SelFirstName, SelDateOfBirth, SelIdentityDocumentSeries, SelIdentityDocumentNumber, SelIdentityDocumentIssueDate, SelEMail, SelPhone)
								);
	OpenForm("Catalog.Clients.Form.tcItemForm", vParameters, ThisObject);
EndProcedure // ListBeforeAddRow

// -----------------------------------------------------------------------------
&AtClient
Procedure ListOnActivateRow(pItem)
	vCurData = pItem.CurrentRow;
	If vCurData = Undefined Then
		Items.GroupClientData.Visible = False;
	Else
		If CurrentDataRef <> vCurData Then
			CurrentDataRef = vCurData;
			Items.GroupClientData.Visible = True;
			AdvanceList.Parameters.SetParameterValue("qClient", vCurData);
			If pItem.CurrentData <> Undefined Then
				AccommodationCount = NStr("en='Acc. ';ru='Разм. ';de='Acc. '") + pItem.CurrentData.AccommodationCount;
				ReservationCount = NStr("en='Res. ';ru='Бронь ';de='Res. '") + pItem.CurrentData.ReservationCount;
			EndIf;
			vIsInBlackList = False;
			vIsInWhiteList = False;
			PictureBoxPhoto = PutAdvanceData(vCurData, vIsInBlackList, vIsInWhiteList, TNumberOfAccommodations, TRemarks);
			// Check if client is in black list
			vRedColor = tcCommonFunctionOnClientServer.ColorConstructor(255, 0, 0);
			vGreenColor = tcCommonFunctionOnClientServer.ColorConstructor(0, 255, 0);
			vBorderDefaultColor = tcCommonFunctionOnClientServer.ColorConstructor(179, 172, 134);
			vTextDefaultColor = tcCommonFunctionOnClientServer.ColorConstructor();
			If vIsInBlackList Then
				TRemarks = NStr("en = 'Is in <black> list!'; de = 'Auf der <schwarzen> Liste!'; ru = 'В <черном> списке!'") + Chars.LF + TRemarks;
				Items.TRemarks.BorderColor = vRedColor;
				Items.TRemarks.TextColor = vRedColor;
			ElsIf vIsInWhiteList Then
				TRemarks = NStr("en = 'Is in <white> list!'; de = 'Au der <weißen> Liste!'; ru = 'В <белом> списке!'") + Chars.LF + TRemarks;
				Items.TRemarks.BorderColor = vGreenColor;
				Items.TRemarks.TextColor = vGreenColor;
			Else
				Items.TRemarks.BorderColor = vBorderDefaultColor;
				Items.TRemarks.TextColor = vTextDefaultColor;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ListOnActivateRow

// -----------------------------------------------------------------------------
&AtServer
Procedure AddNewFilter(pItem, pValue, pStrictMatch = False, pContains = False)
	vFilterItems = List.Filter.Items;
	vItem = ?(Left(pItem, 3)="Sel", Right(pItem, StrLen(pItem)-3), pItem);
	If vItem = "Tag" Then
		List.Parameters.SetParameterValue("qTag", SelTag);
		List.Parameters.SetParameterValue("qTagIsFilled", ValueIsFilled(SelTag));
	ElsIf vItem = "ClientType" Then
		List.Parameters.SetParameterValue("qClientType", SelClientType);
		List.Parameters.SetParameterValue("qClientTypeIsFilled", ValueIsFilled(SelClientType));
	Else
		vFindedField = List.ConditionalAppearance.FilterAvailableFields.Items.Find(vItem);
		If vFindedField <> Undefined Then
			// Deleting old filter
			N = 1;
			For Num = 1 to vFilterItems.Count() Do
				If vFilterItems.Get(vFilterItems.Count() - N).LeftValue = vFindedField.Field Then
					vFilterItems.Delete(vFilterItems.Get(vFilterItems.Count() - N));
				Else
					N = N + 1;
				EndIf;
			EndDo;
			// Add new filter
			If ValueIsFilled(pValue) Then
				vNewFilter = vFilterItems.Add(Type("DataCompositionFilterItem"));
				vNewFilter.LeftValue = vFindedField.Field;
				vNewFilter.RightValue = pValue;
				If pStrictMatch Then
					vNewFilter.ComparisonType = DataCompositionComparisonType.Equal;
				ElsIf pContains Then
					vNewFilter.ComparisonType = DataCompositionComparisonType.Contains;
				Else
					vNewFilter.ComparisonType = DataCompositionComparisonType.BeginsWith;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // AddNewFilter

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Clear(pCommand)
	DeletingAllFilters();
	SelClientsList.Clear();
	FilterSame();
EndProcedure // Clear

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenFolios(Command)
	vRef = Items.List.CurrentRow;
	If Not vRef = Undefined Then
		// APDEX
		vKeyOperation = "CommonForm.tcFoliosForm.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

		vParametersStructure = New Structure("ObjectRef", vRef);
		OpenForm("CommonForm.tcFoliosForm", New Structure("ParametersStructure", vParametersStructure), ThisObject, UUID);
	EndIf;
EndProcedure // OpenFolios

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionSearchSameClients(pCommand)
	vSearchStruct = New Structure("SelLastName, SelFirstName, SelSecondName, SelDateOfBirth, SelIdentityDocumentSeries, SelIdentityDocumentNumber, SelPhone, SelEMail", 
	                              SelLastName, SelFirstName, SelSecondName, SelDateOfBirth, SelIdentityDocumentSeries, SelIdentityDocumentNumber, SelPhone, SelEMail);
	OpenForm("Catalog.Clients.Form.tcSearchSameClientsSettingsForm", vSearchStruct, ThisObject);
EndProcedure // ActionSearchSameClients

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionMergeClients(pCommand)
	vCurRow = Items.List.CurrentRow;
	If vCurRow = Undefined Then
		ShowMessageBox( , NStr("en='Choose at least one client first!';ru='Выберите как минимум одного клиента!';de='Wählen Sie mindestens einen Kunden!'"));
		Return;
	EndIf;
	If tcOnServer.cmGetAttributeByRef(vCurRow, "IsFolder") Then
		ShowMessageBox( , NStr("en='Do not choose client folders!';ru='Нельзя выбирать группы клиентов!';de='Kundengruppen dürfen nicht gewählt werden!'"));
		Return;
	EndIf;
	vParam = new Structure();
	vParam.Insert("SelDefaultTypeDescription", New TypeDescription("CatalogRef.Clients"));
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
EndProcedure // ActionMergeClients

// -----------------------------------------------------------------------------
&AtClient
Procedure RefreshForm(pCommand)
	CurrentDataRef = Undefined;
	Items.List.Refresh();
	ListOnActivateRow(Items.List);
EndProcedure // RefreshForm

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionRefillClientsAgeRegionCity(pCommand)
	ActionRefillClientsAgeRegionCityAtServer();
EndProcedure // ActionRefillClientsAgeRegionCity

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowDeleted(pCommand)
	ShowDeletedAtServer();
EndProcedure // ShowDeleted

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure AddListDynamicConditionalAppearance()
	// Add client types color
	vRefs = cmGetAllClientTypes(SessionParameters.CurrentHotel);
	For Each vRefsRow In vRefs Do
		vColor = tcCommonFunctionOnClientServer.cmGetColorFromValueStorage(vRefsRow.ClientType);
		If vColor <> Undefined Then
			tcCommonFunctionOnClientServer.cmAddBackColorToTheListCell(List, "ClientType", vRefsRow.ClientType, "ClientTypeCode", vColor);
		EndIf;
	EndDo;
EndProcedure // AddListDynamicConditionalAppearance

// -----------------------------------------------------------------------------
&AtServer
Procedure DeletingAllFilters()
	vFilterItems = List.Filter.Items;
	// Deleting filters
	For Num = 1 to vFilterItems.Count() Do
		vFilterItems.Delete(vFilterItems.Get(0));
	EndDo;
	List.Parameters.SetParameterValue("qClientType", Undefined);
	List.Parameters.SetParameterValue("qClientTypeIsFilled", False);
	List.Parameters.SetParameterValue("qTag", Undefined);
	List.Parameters.SetParameterValue("qTagIsFilled", False);
	// Clear filter fields
	SelLastName = "";
	SelFirstName = "";
	SelSecondName = "";
	SelDateOfBirth = '00010101';
	SelIdentityDocumentSeries = "";
	SelIdentityDocumentNumber = "";
	SelIdentityDocumentIssueDate = '00010101';
	SelEMail = "";
	SelPhoneNumber = "";
	SelClientType = Undefined;
	SelTag = Undefined;
EndProcedure // DeletingAllFilters

// -----------------------------------------------------------------------------
&AtServer
Function GuestNameFieldsIsFilled()
	If ValueIsFilled(SelLastName) Or
		ValueIsFilled(SelFirstName) Or
		ValueIsFilled(SelSecondName) Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // GuestNameFieldsIsFilled

// -----------------------------------------------------------------------------
&AtServerNoContext
Function PutAdvanceData(pClient, pIsInBlackList, pIsInWhiteList, pNumberOfAccommodations, pRemarks)
	// Accommodation history
	pNumberOfAccommodations = TrimAll(pClient.Description) + NStr("en=' - Accommodations history and reservations';ru=' - История проживаний и бронь';de=' - Aufenthaltshistorie und Buchungen'");
	// Load remarks
	pRemarks = TrimAll(pClient.Remarks);
	// Load client photo
	vPicture = pClient.Photo.Get();
	If vPicture = Undefined Then
		vPictureAddress = PutToTempStorage(PictureLib.Empty);
	Else    
		vPictureAddress = PutToTempStorage(vPicture);
	EndIf;
	// Black and white lists
	pIsInBlackList = pClient.IsInBlackList;
	pIsInWhiteList = pClient.IsInWhiteList;
	Return vPictureAddress;
EndFunction // PutAdvanceData

// -----------------------------------------------------------------------------
&AtServer
Procedure FilterSame()
	If SelClientsList.Count() > 0 Then
		List.Parameters.SetParameterValue("qClientsListIsEmpty", False);
		List.Parameters.SetParameterValue("qClientsList", SelClientsList);
	Else
		List.Parameters.SetParameterValue("qClientsListIsEmpty", True);
		List.Parameters.SetParameterValue("qClientsList", SelClientsList);
	EndIf;
EndProcedure // FilterSame

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionRefillClientsAgeRegionCityAtServer()
	// Fill list of clients being selected
	vSelClientsList = New ValueList();
	If Items.List.SelectedRows.Count() > 1 Then
		For Each vSelRow In Items.List.SelectedRows Do
			If Not vSelRow.Ref.IsFolder And Not vSelRow.Ref.DeletionMark Then
				vSelClientsList.Add(vSelRow.Ref);
			EndIf;
		EndDo;
	EndIf;
	// Get all client items
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Clients.Ref
	|FROM
	|	Catalog.Clients AS Clients
	|WHERE
	|	(NOT Clients.DeletionMark)
	|	AND (NOT Clients.IsFolder) " + 
	?(vSelClientsList.Count() > 0, "AND Clients.Ref IN (&qClientsList) ", "") + " 
	|
	|ORDER BY
	|	Clients.Code";
	vQry.SetParameter("qClientsList", vSelClientsList);
	vQryRes = vQry.Execute().Unload();
	vCount = vQryRes.Count();
	i = 0;
	For Each vQryResRow In vQryRes Do
		i = i + 1;
		vCltObj = vQryResRow.Ref.GetObject();
		If Not IsBlankString(vCltObj.Phone) Then
			vCltObj.Phone = SMS.GetValidPhoneNumber(vCltObj.Phone);
		EndIf;
		If Not IsBlankString(vCltObj.Fax) Then
			vCltObj.Fax = SMS.GetValidPhoneNumber(vCltObj.Fax);
		EndIf;
		vCltObj.Write();		
	EndDo;
EndProcedure // ActionRefillClientsAgeRegionCityAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ShowDeletedAtServer()
	ShowDeleted = Not ShowDeleted;
	Items.ListShowDeleted.Check = ShowDeleted;
	List.Parameters.SetParameterValue("qShowDeleted", ShowDeleted);
	SystemSettingsStorage.Save("Catalog.Clients.tcListForm", "ShowDeleted", ShowDeleted);
EndProcedure // ShowDeleted

#EndRegion
