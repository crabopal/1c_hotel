

#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	SelHotel = SessionParameters.CurrentHotel;
	If Parameters.Property("Filter") Then
		If Not Parameters.Filter.Property("Hotel") Then
			Parameters.Filter.Insert("Hotel", SelHotel);
		EndIf;
	EndIf;
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure AddRoom(pCommand)
	vRoomsFolder = Undefined;
	vCurRow = Items.List.CurrentRow;
	If vCurRow <> Undefined Then
		vRoom = tcOnServer.cmGetAttributeByRef(vCurRow, "Room");
		If ValueIsFilled(vRoom) Then
			vRoomsFolder = tcOnServer.cmGetAttributeByRef(vRoom, "Parent");
		EndIf;
	EndIf;
	OpenForm("Document.AddRoom.Form.tcDocumentForm", New Structure("RoomGroup", vRoomsFolder));
EndProcedure // AddRoom

// --------------------------------------------------------------------------------
&AtClient
Procedure EditRoom(pCommand)
	vRoom = Undefined;
	For Each vFltItem In ThisForm.List.Filter.Items Do
		If TypeOf(vFltItem.RightValue) = Type("CatalogRef.Rooms") Then
			vRoom = vFltItem.RightValue;
			Break;
		EndIf;
	EndDo;
	If Not ValueIsFilled(vRoom) Then
		vCurRow = Items.List.CurrentRow;
		If vCurRow <> Undefined Then
			vRoom = tcOnServer.cmGetAttributeByRef(vCurRow, "Room");
		EndIf;
	EndIf;
	If ValueIsFilled(vRoom) And Not tcOnServer.cmGetAttributeByRef(vRoom, "IsFolder") Then
		OpenForm("Document.ChangeRoom.Form.tcDocumentForm", New Structure("Basis", vRoom));
	EndIf;
EndProcedure // EditRoom

#EndRegion	
