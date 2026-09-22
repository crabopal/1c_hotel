
#Region Public

// --------------------------------------------------------------------------------
Procedure FillIconIndex() Export 
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	RoomStatuses.Ref AS Ref
		|FROM
		|	Catalog.RoomStatuses AS RoomStatuses";	
	vQueryResult = vQuery.Execute();	
	vSel = vQueryResult.Select();	
	While vSel.Next() Do
		vObject = vSel.Ref.GetObject();
		vRoomStatusIcon = vObject.RoomStatusIcon;
		If ValueIsFilled(vRoomStatusIcon) Then
			If vRoomStatusIcon = Enums.RoomStatusesIcons.None Then
				vObject.IconIndex = 5;
			ElsIf vRoomStatusIcon = Enums.RoomStatusesIcons.Reserved Then
				vObject.IconIndex = 6;
			ElsIf vRoomStatusIcon = Enums.RoomStatusesIcons.Occupied Then
				vObject.IconIndex = 2;
			ElsIf vRoomStatusIcon = Enums.RoomStatusesIcons.OccupiedDirty Then
				vObject.IconIndex = 7;
			ElsIf vRoomStatusIcon = Enums.RoomStatusesIcons.Waiting Then
				vObject.IconIndex = 1;
			ElsIf vRoomStatusIcon = Enums.RoomStatusesIcons.TidyingUp Then
				vObject.IconIndex = 0;
			ElsIf vRoomStatusIcon = Enums.RoomStatusesIcons.CheckOut Then
				vObject.IconIndex = 3;
			ElsIf vRoomStatusIcon = Enums.RoomStatusesIcons.Vacant Then
				vObject.IconIndex = 4;
			ElsIf vRoomStatusIcon = Enums.RoomStatusesIcons.Repair Then
				vObject.IconIndex = 8;
			ElsIf vRoomStatusIcon = Enums.RoomStatusesIcons.Luggage Then
				vObject.IconIndex = 9;			
			ElsIf vRoomStatusIcon = Enums.RoomStatusesIcons.Malfunction Then
				vObject.IconIndex = 10;
			Else
				vObject.IconIndex = 5;			
			EndIf;
		Else
			vObject.IconIndex = 5;
		EndIf; 

		vObject.Write();
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Hotel, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

#EndRegion

