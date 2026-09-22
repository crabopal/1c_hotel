
#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pReplacing)    
	If DataExchange.Load Then
		Return;
	EndIf;
	vRoomProperty = ThisObject.Filter.RoomProperty.Value;
	If ValueIsFilled(vRoomProperty) And Not ValueIsFilled(ThisObject.Filter.Room.Value) Then
		vPropertyRoomsRow = InformationRegisters.RoomProperties.Select(New Structure("RoomProperty", vRoomProperty));
		While vPropertyRoomsRow.Next() Do
			vRoom = vPropertyRoomsRow.Room;
			If ValueIsFilled(vRoom) And Not vRoom.IsFolder Then
				vRoomObj = vRoom.GetObject();
				vRoomObj.RoomPropertiesCodes = "";
				vRoomObj.RoomPropertiesDescriptions = "";
				vRoomPropertyRow = cmGetRoomPropertiesForRoom(vRoom);
				While vRoomPropertyRow.Next() Do 
					vRoomPropertyRef = vRoomPropertyRow.RoomProperty;
					If ValueIsFilled(vRoomPropertyRef) And vRoomPropertyRef <> vRoomProperty And vRoomPropertyRef.ShowInPropertiesList Then
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
EndProcedure // BeforeWrite

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel, pReplacing)
	If DataExchange.Load Then
		Return;
	EndIf;
	Try
		vRoomsList = New ValueList();
		vRoom = Filter.Room.Value;
		If ValueIsFilled(vRoom) Then
			vRoomsList.Add(vRoom);
		Else
			For Each vRcd In ThisObject Do
				If ValueIsFilled(vRcd.Room) Then
					If vRoomsList.FindByValue(vRcd.Room) = Undefined Then
						vRoomsList.Add(vRcd.Room);
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		For Each vRoomItem In vRoomsList Do
			vRoom = vRoomItem.Value;
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
	Except
	EndTry;
EndProcedure // OnWrite

#EndRegion

