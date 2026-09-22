// -----------------------------------------------------------------------------
Procedure pmExecute() Export
	If RoomProperties.Count() > 0 Then
		For Each vRow In RoomProperties Do
			If ValueIsFilled(vRow.RoomProperty) Then
				// Remove property from all rooms
				vProps = InformationRegisters.RoomProperties.CreateRecordSet();
				vProps.Filter.RoomProperty.Set(vRow.RoomProperty);
				vProps.Clear();
				vProps.Write(True);

				For Each vRoomsRow In Rooms Do
					If ValueIsFilled(vRoomsRow.Room) Then
						vPropsRec = vProps.Add();
						vPropsRec.Room = vRoomsRow.Room;
						vPropsRec.RoomProperty = vRow.RoomProperty;
						vPropsRec.Remarks = vRow.RoomProperty.Remarks;
						vPropsRec.Author = SessionParameters.CurrentUser;
					EndIf;
				EndDo;
				vProps.Write(True);
			EndIf;
		EndDo;
	Else
		For Each vRoomsRow In Rooms Do
			If ValueIsFilled(vRoomsRow.Room) Then
				vProps = InformationRegisters.RoomProperties.CreateRecordSet();
				vProps.Filter.Room.Set(vRoomsRow.Room);
				vProps.Clear();
				vProps.Write(True);
			EndIf;
		EndDo;
	EndIf;
EndProcedure // pmExecute