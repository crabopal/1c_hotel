
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If not Parameters.Filter.Property("Owner") Then		
		Parameters.Filter.Insert("Owner",SessionParameters.CurrentHotel);
	EndIf;	
	Hotel = SessionParameters.CurrentHotel;
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(Hotel, "BackgroundColorImportant");
	// Multiple choice
	If Parameters.Property("MultipleChoice") And Parameters.MultipleChoice <> Undefined And Parameters.MultipleChoice Then
		Items.List.ChoiceMode = True;
		Items.List.MultipleChoice = True;
		ThisForm.CloseOnChoice = False;
	EndIf;
	// Check rights
	If Not cmCheckUserPermissions("HavePermissionToManageRoomInventory") Then
		Items.List.EnableStartDrag = False;
		Items.List.EnableDrag = False;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "tcStopSaleMultipleRooms.Execute" Then
		Items.List.Refresh();
	EndIf;	
EndProcedure // NotificationProcessing

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ActionStopSale(pCommand)
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToStopSaleRoomTypes") Then
		ShowMessageBox(, NStr("en='You do not have rights to stop sale room types!';ru='Нет прав на снятие типов номеров с продажи!';de='Sie haben keine Rechte, Zimmertypen aus dem Verkauf zu nehmen!'"));
		Return;
	EndIf;
	vSelRooms = New ValueList();
	For Each vSelRow In Items.List.SelectedRows Do
		vSelRooms.Add(vSelRow);
	EndDo;
	If vSelRooms.Count() > 0 Then
		OpenForm("CommonForm.tcStopSaleMultipleRooms", New Structure("SelListRef", vSelRooms), ThisForm, UUID);
	EndIf;
EndProcedure // ActionStopSale

#EndRegion
