
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
		If vChoiceMode Then
			Items.List.ChoiceMode = vChoiceMode;
		EndIf;
	EndIf;
	List.Parameters.SetParameterValue("qTag", SelTag);
	List.Parameters.SetParameterValue("qTagIsFilled", ValueIsFilled(SelTag));
	List.Parameters.SetParameterValue("qClientType", SelClientType);
	List.Parameters.SetParameterValue("qClientTypeIsFilled", ValueIsFilled(SelClientType));
	vMultipleChoice = False;
	If Parameters.Property("MultipleChoice", vMultipleChoice) Then
		If vMultipleChoice Then
			Items.List.MultipleChoice = vMultipleChoice;
		EndIf;
	EndIf;
	FilterSame();	
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(Cancel)
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
	If pEventName = "SearchSameClients.Result" And pSource = ThisObject Then
		If TypeOf(pParameter) = Type("ValueList") Then
			SelClientsList.LoadValues(pParameter.UnloadValues());
			FilterSame();
		EndIf;
	EndIf;
EndProcedure // NotificationProcessing

#EndRegion

#Region FormHeaderItemsEventHandlers

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
			N=1;
			For Num = 1 to vFilterItems.Count() Do
				If vFilterItems.Get(vFilterItems.Count()-N).LeftValue = vFindedField.Field Then
					vFilterItems.Delete(vFilterItems.Get(vFilterItems.Count()-N));
				Else
					N=N+1;
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

// -----------------------------------------------------------------------------
&AtClient
Procedure SelLastNameOnChange(pItem)
	AddNewFilter(pItem.Name, pItem.EditText);
EndProcedure // SelLastNameOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelFirstNameOnChange(pItem)
	AddNewFilter(pItem.Name, pItem.EditText);
EndProcedure // SelFirstNameOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelSecondNameOnChange(pItem)
	AddNewFilter(pItem.Name, pItem.EditText);
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
	AddNewFilter(pItem.Name, pItem.EditText, True);
EndProcedure // SelIdentityDocumentNumberOnChange

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
Procedure SelIdentityDocumentSeriesOnChange(pItem)
	AddNewFilter(pItem.Name, pItem.EditText, True);
EndProcedure // SelIdentityDocumentSeriesOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelPhoneNumberOnChange(pItem)
	SelPhone = SMS.GetValidPhoneNumber(SelPhone);
	AddNewFilter(pItem.Name, SelPhone, , True);
EndProcedure // SelPhoneNumberOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelEMailOnChange(pItem)
	AddNewFilter(pItem.Name, SelEMail, , True);
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

#Region FormTableLiatItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ListBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	pCancel = True;
	vParameters = New Structure("FormData", 
								New Structure(
										"LastName,   SecondName,    FirstName,    DateOfBirth,     IdentityDocumentSeries,    IdentityDocumentNumber,    IdentityDocumentIssueDate,    EMail,    Phone",
										SelLastName, SelSecondName, SelFirstName, SelDateOfBirth,  SelIdentityDocumentSeries, SelIdentityDocumentNumber, SelIdentityDocumentIssueDate, SelEMail, SelPhone)
								);
	OpenForm("Catalog.Clients.Form.tcItemForm", vParameters, ThisObject);
EndProcedure // ListBeforeAddRowe

// -----------------------------------------------------------------------------
&AtClient
Procedure ListSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	If Items.List.ChoiceMode Then
		pStandardProcessing = False;
		NotifyChoice(pSelectedRow);
	EndIf;
EndProcedure // ListSelection

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionRefillClientsAgeRegionCity(pCommand)
	ActionRefillClientsAgeRegionCityAtServer();
EndProcedure // ActionRefillClientsAgeRegionCity

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionSearchSameClients(pCommand)
	vSearchStruct = New Structure("SelLastName, SelFirstName, SelSecondName, SelDateOfBirth, SelIdentityDocumentSeries, SelIdentityDocumentNumber, SelPhone, SelEMail", 
	                              SelLastName, SelFirstName, SelSecondName, SelDateOfBirth, SelIdentityDocumentSeries, SelIdentityDocumentNumber, SelPhone, SelEMail);
	OpenForm("Catalog.Clients.Form.tcSearchSameClientsSettingsForm", vSearchStruct, ThisObject);
EndProcedure // ActionSearchSameClients

// -----------------------------------------------------------------------------
&AtClient
Procedure Clear(pCommand)
	DeletingAllFilters();
	SelClientsList.Clear();
	FilterSame();
EndProcedure // Clear

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenFolios(pCommand)
	vRef = Items.List.CurrentRow;
	If Not vRef = Undefined Then
		vParametersStructure = New Structure("ObjectRef", vRef);
		OpenForm("CommonForm.tcFoliosForm", New Structure("ParametersStructure", vParametersStructure), ThisObject, UUID);
	EndIf;
EndProcedure // OpenFolios

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowFilterGroup(pCommand)
	Items.FilterGroup.Visible = Not Items.FilterGroup.Visible; 
	Items.ShowFilterGroup.Check = Items.FilterGroup.Visible;
EndProcedure // ShowFilterGroup

#EndRegion

#Region Private

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
	vNum = 0;
	For Each vQryResRow In vQryRes Do
		vNum = vNum + 1;
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
	SelSelIdentityDocumentSeries = "";
	SelSelIdentityDocumentNumber = "";
	SelIdentityDocumentIssueDate = '00010101';
	SelPhoneNumber = "";
	SelEMail = "";
	SelClientType = Undefined;
	SelTag = Undefined;
EndProcedure // DeletingAllFilters

#EndRegion
