
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
		pCancel = True;
		Return;
	EndIf;
	If Parameters.Property("ChoiceMode") And Parameters.ChoiceMode Then
		Items.List.ChoiceMode = Parameters.ChoiceMode;
	Else
		Items.List.ChoiceMode = False;
	EndIf;
	SetParametersDynamicList();
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	// Check rights
	If Not cmCheckUserPermissions("HavePermissionToManageRoomInventory") Then
		Items.Tree.EnableStartDrag = False;
		Items.Tree.EnableDrag = False;
		Items.List.EnableStartDrag = False;
		Items.List.EnableDrag = False;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "System.Hotel.Changed" And pParameter <> SelHotel Then
		SetParametersDynamicList();
	ElsIf pEventName = "Subsystem.Rooms.Changed" Then
		Items.List.Refresh();
	EndIf;
EndProcedure

#EndRegion

#Region FormTableListItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ListSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	vCurData = Items.List.CurrentData;
	If vCurData <> Undefined Then
		If Not vCurData.IsFolder And Not Items.List.ChoiceMode Then
			pStandardProcessing = False;
			OpenForm("Catalog.Rooms.Form.tcItemForm", New Structure("Key", vCurData.Ref));
		EndIf;
	EndIf;
EndProcedure // ListSelection

// --------------------------------------------------------------------------------
&AtClient
Procedure ListBeforeRowChange(pItem, pCancel)
	vCurData = Items.List.CurrentData;
	If vCurData <> Undefined Then
		If Not vCurData.IsFolder And Not Items.List.ChoiceMode Then
			pCancel = True;
			OpenForm("Catalog.Rooms.Form.tcItemForm", New Structure("Key", vCurData.Ref));
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure AddRoom(pCommand)
	OpenForm("Document.AddRoom.Form.tcDocumentForm", New Structure("RoomGroup", Items.Tree.CurrentRow));
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure EditRoom(pCommand)	
	If not Items.List.CurrentData.IsFolder Then
		OpenForm("Document.ChangeRoom.Form.tcDocumentForm", New Structure("Basis", Items.List.CurrentRow));
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure CopyRoom(pCommand)
	OpenForm("Document.AddRoom.Form.tcDocumentForm", New Structure("Basis", Items.List.CurrentRow));
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure SetParametersDynamicList()
	If Not (Parameters.Property("Filter") And Parameters.Filter.Property("Owner") And ValueIsFilled(Parameters.Filter.Owner)) Then
		SelHotel = SessionParameters.CurrentHotel;
	Else
		SelHotel = Parameters.Filter.Owner;
	EndIf;
	If ValueIsFilled(SelHotel) Then 
		// Filter for List
		Parameters.Filter.Insert("Owner", SelHotel);
		// Filter for Tree
		tcCommonFunctionOnClientServer.cmChangeFilterItems(Tree.SettingsComposer.Settings.Filter, "Owner", , SelHotel, , True);
	EndIf;	
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
EndProcedure // SetParametersDynamicList	

#EndRegion
