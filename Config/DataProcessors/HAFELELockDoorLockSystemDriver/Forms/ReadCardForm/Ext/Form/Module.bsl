
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("Room") And ValueIsFilled(Parameters.Room) Then
		Room = tcDoorLocksAtServer.GetRoomRefByCode(TrimAll(Parameters.Room));
		If Not ValueIsFilled(Room) Then
			Room = Parameters.Room; 	
		EndIf;
	EndIf;
	If Parameters.Property("CheckOutDate") And ValueIsFilled(Parameters.CheckOutDate) Then
		Object.CheckOutDate = XMLValue(Type("Date"), Parameters.CheckOutDate); 	
	EndIf;
    If Parameters.Property("Guest") And ValueIsFilled(Parameters.Guest) Then
		vHotel = SessionParameters.CurrentHotel;
		vQ = New Query();
		vQ.Text =
		"SELECT
		|	Clients.Ref AS Ref
		|FROM
		|	Catalog.Clients AS Clients
		|WHERE
		|	NOT Clients.IsFolder
		|	AND NOT Clients.DeletionMark
		|	AND Clients.Code = &qCode";
		vQ.SetParameter("qCode", cmGetDocumentNumberFromPresentation(Parameters.Guest, vHotel, vHotel.Company));
		vResult = vQ.Execute().Unload();
		If vResult.Count() > 0 Then
			Object.Guest = vResult[0].Ref; 		
		EndIf;
	EndIf; 
	If Parameters.Property("UUIDCard") And ValueIsFilled(Parameters.UUIDCard) Then
		vIdentificationCard = tcDoorLocksAtServer.GetIdentificationCardsRefByCardID(Parameters.UUIDCard);
		If ValueIsFilled(vIdentificationCard) Then 
			Object.Room = vIdentificationCard.Room; 
			Object.Guest = vIdentificationCard.Client;
			Object.CheckInDate = vIdentificationCard.DateTimeFrom;
			Object.CheckOutDate = vIdentificationCard.DateTimeTo;
			Object.Folio = vIdentificationCard.Folio; 
		EndIf;
	EndIf;	
EndProcedure // OnCreateAtServer

#EndRegion
