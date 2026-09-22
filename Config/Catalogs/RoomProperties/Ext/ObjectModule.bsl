
#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure BeforeWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToManageRoomInventory") Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights for room inventory management!';ru='Нет прав на управление номерным фондом!';de='Sie haben keine Rechte, den Zimmerfond zu verwalten!'"));
		pCancel = True;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel)  
	If DataExchange.Load Then
		Return;
	EndIf;
	If ValueIsFilled(Ref) And Not IsFolder Then
		If DeletionMark Then
			// Remove property from all rooms
			vPropertyRooms = InformationRegisters.RoomProperties.CreateRecordSet();
			vPropertyRooms.Filter.RoomProperty.Set(Ref);
			vPropertyRooms.Clear();
			vPropertyRooms.Write(True);
		Else
			vPropertyRoomsRow = InformationRegisters.RoomProperties.Select(New Structure("RoomProperty", Ref));
			While vPropertyRoomsRow.Next() Do
				vRoom = vPropertyRoomsRow.Room;
				If ValueIsFilled(vRoom) And Not vRoom.IsFolder Then
					vRoomObj = vRoom.GetObject();
					vRoomObj.RoomPropertiesCodes = "";
					vRoomObj.RoomPropertiesDescriptions = "";
					vRoomPropertyRow = cmGetRoomPropertiesForRoom(vRoom);
					While vRoomPropertyRow.Next() Do
						vRoomPropertyRef = vRoomPropertyRow.RoomProperty;
						If ValueIsFilled(vRoomPropertyRef) And vRoomPropertyRef.ShowInPropertiesList Then
							If IsBlankString(vRoomObj.RoomPropertiesCodes) Then
								vRoomObj.RoomPropertiesCodes = TrimAll(vRoomPropertyRef.Code);
								vRoomObj.RoomPropertiesDescriptions = TrimAll(vRoomPropertyRef.Description);
							Else
								vRoomObj.RoomPropertiesCodes = TrimAll(vRoomObj.RoomPropertiesCodes) + Chars.LF + TrimAll(vRoomPropertyRef.Code);
								vRoomObj.RoomPropertiesDescriptions = TrimAll(vRoomObj.RoomPropertiesDescriptions) + Chars.LF + TrimAll(vRoomPropertyRef.Description);
							EndIf;
						EndIf;
					EndDo;
					vRoomObj.Write();
				EndIf;
			EndDo;
		EndIf;
	EndIf;
EndProcedure // OnWrite

#EndRegion
 