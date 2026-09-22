
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Check user rights to edit item
	If Not cmCheckUserPermissions("HavePermissionToManageHousekeeping") Then
		If Not ValueIsFilled(Object.Ref) Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to edit housekeeping settings!';ru='Нет прав на управление службой горничных!';de='Sie haben keine Rechte, die Einstellungen des Reinigungsdienstes zu verwalten!'"));
			Return;
		Else
			ThisForm.ReadOnly = True;
		EndIf;
	EndIf;
	// Initialize hotel
	tcOnServer.cmInitHotel(Object);
	// Fill rooms table
	RefreshTable();
EndProcedure // OnCreateAtServer
 
// -----------------------------------------------------------------------------
&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	vMessage = "";
	Rooms.Sort("SortCode");
	
	
	For Each vRow In Rooms Do
		If vRow.Room.RoomSection <> pCurrentObject.Ref Then
			If ValueIsFilled(vRow.Room) Then
				vOldRS = vRow.Room.RoomSection;
				vRoomObject = vRow.Room.GetObject();
				vRoomObject.RoomSection = pCurrentObject.Ref;
				vRoomObject.Write();
				If ValueIsFilled(vOldRS) Then
					vMessage = vMessage + NStr("en = 'Room '; ru = 'Номер '; de = 'Zimmer '") + vRow.Room + ": " +  pCurrentObject.Ref + " --> " + vOldRS + Chars.LF; 
				EndIf;
			EndIf;			
		EndIf;
	EndDo;	
	If ValueIsFilled(vMessage) Then 
		tcCommonFunctionOnClientServer.TextMessage(vMessage);
	EndIf;
EndProcedure // AfterWriteAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomsRoomChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	vResult = FillInGroup(pSelectedValue);
	If vResult = Undefined then
		pStandardProcessing = False;
	EndIf;
	Rooms.Sort("SortCode");
EndProcedure // RoomsRoomChoiceProcessing

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Function FillInGroup(pRoom)
	If ValueIsFilled(pRoom.isFolder) Then
		vQuery = New Query;
		vQuery.Text = 
		"SELECT
		|	Rooms.Ref AS Room,
		|	Rooms.SortCode
		|FROM
		|	Catalog.Rooms AS Rooms
		|WHERE
		|	Rooms.Ref IN HIERARCHY(&qParent)
		|	AND NOT Rooms.DeletionMark
		|	AND NOT Rooms.IsFolder";		
		vQuery.SetParameter("qParent", pRoom);
		vQueryResult = vQuery.Execute();		
		vResult      = vQueryResult.Unload();
		vFirst       = True;
		vRoom        = Undefined;
		For Each vRow In vResult Do
			vRows = Rooms.FindRows(New Structure("Room",vRow.Room));
			If vRows.Count() = 0 Then				
				If vFirst Then
					vRoom            = vRow.Room;
					vFirst           = False;
				Else	
					vNewRow          = Rooms.Add();
					vNewRow.Room     = vRow.Room;
					vNewRow.SortCode = vRow.SortCode;
				EndIf;
			EndIf;
		EndDo;		
		Return vRoom;
	Else
		vRows = Rooms.FindRows(New Structure("Room",pRoom));
		If vRows.Count() = 0 Then	
			Return pRoom;
		Else
			Return Undefined;
		EndIf;		
	EndIf;
EndFunction // FillInGroup

// -----------------------------------------------------------------------------
&AtServer
Procedure RefreshTable()
	If ValueIsFilled(Object.Ref) Then
		vQuery = New Query;
		vQuery.Text = 
		"SELECT
		|	Rooms.Ref AS Room,
		|	Rooms.SortCode
		|FROM
		|	Catalog.Rooms AS Rooms
		|WHERE
		|	Rooms.RoomSection = &qRoomSection";		
		vQuery.SetParameter("qRoomSection", Object.Ref);		
		vQueryResult = vQuery.Execute();		
		Rooms.Load(vQueryResult.Unload());
		Rooms.Sort("SortCode");
	EndIf;
EndProcedure // RefreshTable

#EndRegion
