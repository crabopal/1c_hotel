#Region EventHandlers

// -----------------------------------------------------------------------------
Function InfoWithoutHotelTemplateGET(pRequest)
	vPhone = TrimAll(pRequest.URLParameters["Phone"]);
	Return hsGetClientByPhone(vPhone);
EndFunction // InfoWithoutHotelTemplateGET

// -----------------------------------------------------------------------------
Function InfoTemplateGET(pRequest)
	vPhone = TrimAll(pRequest.URLParameters["Phone"]);
	vHotelCode = pRequest.URLParameters["Hotel"];
	Return hsGetClientByPhone(vPhone, vHotelCode);
EndFunction // InfoTemplateGET

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function hsGetClientByPhone(pPhone, pHotelCode = Undefined)
	If ValueIsFilled(pHotelCode) Then
		vHotel = cmGetHotelByCode(pHotelCode);
	EndIf;
	vData = tcSimpleCallsOnServer.GetClientsByPhoneNumber(pPhone);

	vTypePhoneNumber 		= "";
	vRegion 				= "";
	tcSimpleCallsOnServer.GetRepresentationNumber(pPhone,vRegion,vTypePhoneNumber);
	
	vResponse = New HTTPServiceResponse(200);
	vRetStr = vRegion + "("+vTypePhoneNumber+")|";	

    If ValueIsFilled(vData.Client) Then
	    vClient = vData.Client;
		vRetStr = vRetStr + vClient.Ref.FullName + "|";
		If ValueIsFilled(vClient.Ref.Remarks) Then
			vRetStr = vRetStr + vClient.Ref.Remarks + "|";
		EndIf;
		vLatestAcc = tcSimpleCallsOnServer.GetLatestCheckIn(vClient); 
		If ValueIsFilled(vLatestAcc) Then
			If vLatestAcc.AccommodationStatus.IsInHouse Then
				vRetStr = vRetStr + vLatestAcc.Room+" Проживает: с " + Format(vLatestAcc.CheckInDate, "DF='dd MMMM'") + "|";
				If NOT IsBlankString(vLatestAcc.Remarks) Then
					vRetStr = vRetStr + vLatestAcc.Remarks+"|";
				EndIf;
			Else
				vRetStr = vRetStr + vLatestAcc.Room+" Выехал : " + Format(vLatestAcc.CheckOutDate, "DF='dd MMMM'") + "|";
			EndIf;
		EndIf;
		vRes = tcSimpleCallsOnServer.GetReservation(vClient); 
		If ValueIsFilled(vRes) Then
			vRetStr = vRetStr + "Бронь: с " + Format(vRes.CheckInDate, "DF='dd MMMM'") + "|";
			If NOT IsBlankString(vRes.Remarks) Then
				vRetStr = vRetStr + vRes.Remarks+"|";
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(vData.Customer) Then
		vRetStr = vRetStr + TrimAll(vData.Customer)+"|";	
		If NOT IsBlankString(vData.Customer.Remarks) Then
			vRetStr = vRetStr + vData.Customer.Remarks+"|";
		EndIf;
	EndIf;
	If ValueIsFilled(vData.Room) Then
		vRetStr = vRetStr + TrimAll(vData.Room)+" "+vData.Room.RoomType.Code+"|";
		vAccList = tcSimpleCallsOnServer.GetAccomodationsByRoom(vData.Room);
		vPrevRemarks = "";
		For Each vAccDoc In vAccList Do
			vAcc = vAccDoc.Document;
			If vAcc <> Undefined Then
				If ValueIsFilled(vAcc.Guest) Then
					vRetStr = vRetStr + vAcc.Guest.FullName+"|";
				EndIf;
				If NOT IsBlankString(vAcc.Remarks) AND vAcc.Remarks <> vPrevRemarks Then
					vRetStr = vRetStr + vAcc.Remarks+"|";
					vPrevRemarks = vAcc.Remarks;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
		
	vResponse.SetBodyFromString(vRetStr);

	Return vResponse;
EndFunction // HsGetClientByPhone  

#EndRegion
