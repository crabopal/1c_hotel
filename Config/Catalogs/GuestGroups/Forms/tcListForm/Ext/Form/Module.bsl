
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	vHotel = Catalogs.Hotels.EmptyRef();
	If Parameters.Filter.Property("Owner") And ValueIsFilled(Parameters.Filter.Owner) Then
		vHotel = Parameters.Filter.Owner;
	ElsIf Parameters.Property("Hotel") And ValueIsFilled(Parameters.Hotel) Then
		vHotel = Parameters.Hotel;
	Else
		vHotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(vHotel) Then
		SelHotel = vHotel;
		AttributeChangeAtServer("Owner", SelHotel);
	EndIf;
	SelGroupType.Clear();
	FillGroupTypesList();
	If Parameters.Property("FilledGroupType") And Parameters.FilledGroupType Then
		For Each vGroupTypesListItem In GroupTypesList Do
			vGT = vGroupTypesListItem.Value;
			If ValueIsFilled(vGT) Then
				SelGroupType.Add(vGroupTypesListItem.Value, vGroupTypesListItem.Presentation);
			EndIf;
		EndDo;
	ElsIf Parameters.Property("ShowRooms") Then
		For Each vGroupTypesListItem In GroupTypesList Do
			vGT = vGroupTypesListItem.Value;
			If ValueIsFilled(vGT) Then
				If vGT = Catalogs.GroupTypes.Rooms Or vGT = Catalogs.GroupTypes.RoomsAndResources Or vGT.IsForRooms Then
					SelGroupType.Add(vGroupTypesListItem.Value, vGroupTypesListItem.Presentation);
				EndIf;
			EndIf;
		EndDo;
	ElsIf Parameters.Property("ShowEvents") Then
		SelGroupType.Clear();
		For Each vGroupTypesListItem In GroupTypesList Do
			vGT = vGroupTypesListItem.Value;
			If ValueIsFilled(vGT) Then
				If vGT = Catalogs.GroupTypes.Resources Or vGT = Catalogs.GroupTypes.RoomsAndResources Or vGT.IsForEvents Then
					SelGroupType.Add(vGroupTypesListItem.Value, vGroupTypesListItem.Presentation);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	If SelGroupType.Count() > 0 Then
		AttributeChangeAtServer("GroupType", SelGroupType, DataCompositionComparisonType.InList);
		Items.SelGroupType.InputHint = "";
	Else
		ClearingAttributeAtServer("GroupType");
		Items.SelGroupType.InputHint = NStr("en='<All groups>'; ru='<Все группы>'; de='<Alle Gruppen>'");
	ENdIf;
	List.Parameters.SetParameterValue("qToday", BegOfDay(CurrentSessionDate()));   
	List.Parameters.SetParameterValue("qEmptyDate", '00010101'); 
	List.Parameters.SetParameterValue("qIsDueOnly", SelShowIsDueOnly);   
	List.Parameters.SetParameterValue("qStatus", SelStatus);   
	// Set hotel color
	If ValueIsFilled(SelHotel) And Not SelHotel.IsFolder Then
		Items.Owner.Visible = False;
		Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
	Else
		Items.Owner.Visible = True;
		Items.GroupHotel.BackColor = Items.GroupFilter.BackColor;
	EndIf;
EndProcedure //OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If (pEventName = "Document.Reservation.Write" Or pEventName = "Document.Reservation.WriteNew" Or 
		pEventName = "Document.Accommodation.Write" Or pEventName = "Document.Accommodation.WriteNew" Or 
		pEventName = "Document.ResourceReservation.Write" Or pEventName = "Document.ResourceReservation.WriteNew" Or 
		pEventName = "Catalog.GuestGroups.Changed") Then
		Items.List.Refresh();
	EndIf;
EndProcedure //NotificationProcessing

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelOnChange(pItem)
	If ValueIsFilled(SelHotel) Then
		AttributeChangeAtServer("Owner", SelHotel, DataCompositionComparisonType.InHierarchy);
	Else
		ClearingAttributeAtServer("Owner");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelClientOnChange(pItem)
	If ValueIsFilled(SelClient) Then
		AttributeChangeAtServer("Client", SelClient);
	Else
		ClearingAttributeAtServer("Client");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelCustomerOnChange(pItem)
	If ValueIsFilled(SelCustomer) Then
		AttributeChangeAtServer("Customer", SelCustomer);
	Else
		ClearingAttributeAtServer("Customer");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelContractOnChange(pItem)
	If ValueIsFilled(SelContract) Then
		AttributeChangeAtServer("Contract", SelContract);
	Else
		ClearingAttributeAtServer("Contract");
	EndIf;
EndProcedure // SelContractOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelAllotmentOnChange(pItem)
	If ValueIsFilled(SelAllotment) Then
		AttributeChangeAtServer("Allotment", SelAllotment);
	Else
		ClearingAttributeAtServer("Allotment");
	EndIf;
EndProcedure // SelAllotmentOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelEventOnChange(pItem)
	If ValueIsFilled(SelEvent) Then
		AttributeChangeAtServer("Event", SelEvent);
	Else
		ClearingAttributeAtServer("Event");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelCheckInDateOnChange(pItem)
	If ValueIsFilled(SelCheckInDate) Then
		AttributeChangeAtServer("CheckInDate.BeginDates.BegOfDay", SelCheckInDate);
	Else
		ClearingAttributeAtServer("CheckInDate.BeginDates.BegOfDay");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelCheckOutDateOnChange(pItem)
	If ValueIsFilled(SelCheckOutDate) Then
		AttributeChangeAtServer("CheckOutDate.BeginDates.BegOfDay", SelCheckOutDate);
	Else
		ClearingAttributeAtServer("CheckOutDate.BeginDates.BegOfDay");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelAuthorOnChange(pItem)
	If ValueIsFilled(SelAuthor) Then
		AttributeChangeAtServer("Author", SelAuthor);
	Else
		ClearingAttributeAtServer("Author");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelGuestGroupCodeOnChange(pItem)
	If ValueIsFilled(SelGuestGroupCode) Then
		AttributeChangeAtServer("Code", SelGuestGroupCode);
	Else
		ClearingAttributeAtServer("Code");
	EndIf;
EndProcedure // SelGuestGroupCodeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelGroupTypeOnChange(pItem)
	If SelGroupType.Count() > 0 Then
		AttributeChangeAtServer("GroupType", SelGroupType, DataCompositionComparisonType.InList);
		Items.SelGroupType.InputHint = "";
	Else
		ClearingAttributeAtServer("GroupType");
		Items.SelGroupType.InputHint = NStr("en='<All groups>'; ru='<Все группы>'; de='<Alle Gruppen>'");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelGroupTypeStartChoice(pItem, pChoiceData, pChoiceByAdding, pStandardProcessing)
	pStandardProcessing = False;
	For Each vGTItem In GroupTypesList Do
		vGTItem.Check = False;
		If SelGroupType.FindByValue(vGTItem.Value) <> Undefined Then
			vGTItem.Check = True;
		EndIf;
	EndDo;
	OpenForm("CommonForm.mcChoiceValueList", New Structure("Title, ValueList, MultipleChoice", NStr("en='Check types'; ru='Отметьте типы'; de='Typen markieren'"), GroupTypesList, True), Items.SelGroupType, , , , New NotifyDescription("GroupTypesChoiceCompleted", ThisObject), FormWindowOpeningMode.LockWholeInterface);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure GroupTypesChoiceCompleted(pUC, pExtraParams) Export
	If pUC <> Undefined Then
		SelGroupType.Clear();
		For Each vUCItem In pUC Do
			If vUCItem.Check Then
				SelGroupType.Add(vUCItem.Value, vUCItem.Presentation);
			EndIf;
		EndDo;
		SelGroupTypeOnChange(Items.SelGroupType);
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SelShowIsDueOnlyOnChange(pItem)
	SelShowIsDueOnlyOnChangeAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SelStatusOnChange(pItem)
	SelStatusOnChangeAtServer();
EndProcedure

#EndRegion    

#Region FormCommandsEventHandlers
			  
// -----------------------------------------------------------------------------
&AtClient
Procedure OpenFolios(pCommand)
	vRef = Items.List.CurrentRow;
	If vRef <> Undefined Then
		// APDEX
		vKeyOperation = "CommonForm.tcFoliosForm.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

		vParametersStructure = New Structure("ObjectRef", vRef);
		OpenForm("CommonForm.tcFoliosForm", New Structure("ParametersStructure", vParametersStructure), ThisForm, ThisForm.UUID);
	EndIf;
EndProcedure //OpenFolios  

// -----------------------------------------------------------------------------
&AtClient
Procedure CopyGroup(pCommand)
	vRef = Items.List.CurrentRow;
	If vRef <> Undefined Then
		OpenForm("DataProcessor.CopyGuestGroupReservations.Form.tcFPForm", New Structure("GuestGroupFrom, CheckInDateFrom", vRef, '00010101'), ThisObject, vRef, , , , FormWindowOpeningMode.Independent);
	EndIf;
EndProcedure // CopyGroup
			  
#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure AttributeChangeAtServer(pAttribute, pValue, pComparisonType = Undefined)
	If ValueIsFilled(pValue) Then
		vComparisonType = ?(pComparisonType = Undefined, DataCompositionComparisonType.Equal, pComparisonType);
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, pAttribute, pValue, vComparisonType, , True);
		If pAttribute = "Owner" Then
			If pValue.IsFolder Then
				Items.Owner.Visible = True;
				// Set hotel color          
				Items.GroupHotel.BackColor = Items.GroupFilter.BackColor;
			Else
				Items.Owner.Visible = False;
				// Set hotel color          
				Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(pValue, "BackgroundColorImportant");
			EndIf;
		EndIf;
	EndIf;
EndProcedure //AttributeChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ClearingAttributeAtServer(pAttribute)
	tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, pAttribute, , , , False);
	If pAttribute = "Owner" Then
		Items.Owner.Visible = True;
		// Set hotel color          
		Items.GroupHotel.BackColor = Items.GroupFilter.BackColor;
	EndIf;
EndProcedure //ClearingAttributeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelClearing(pItem, pStandardProcessing)
	If Not IsInRoleAtServer("RightsToChooseHotel") Then
		pStandardProcessing = False;
	EndIf;
EndProcedure //SelHotelClearing

// -----------------------------------------------------------------------------
&AtServer
Function IsInRoleAtServer(pRoleName)
	Return IsInRole(pRoleName);
EndFunction //IsInRoleAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillGroupTypesList()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	GroupTypes.Ref AS Ref
	|FROM
	|	Catalog.GroupTypes AS GroupTypes
	|WHERE
	|	NOT GroupTypes.DeletionMark
	|
	|ORDER BY
	|	GroupTypes.Code,
	|	GroupTypes.Description";
	vQry.SetParameter("", );
	vAllGroupTypes = vQry.Execute().Unload();
	GroupTypesList.LoadValues(vAllGroupTypes.UnloadColumn("Ref"));
	GroupTypesList.Insert(0, Catalogs.GroupTypes.EmptyRef(), NStr("en='<Individuals>'; ru='<Индивидуалы>'; de='<Einzelpersonen>'"));
EndProcedure // FillGroupTypesList

// --------------------------------------------------------------------------------
&AtServer
Procedure SelShowIsDueOnlyOnChangeAtServer()
	List.Parameters.SetParameterValue("qIsDueOnly", SelShowIsDueOnly);   
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure SelStatusOnChangeAtServer()
	List.Parameters.SetParameterValue("qStatus", SelStatus);   
EndProcedure
	
#EndRegion