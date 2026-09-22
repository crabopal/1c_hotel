
#Region EventHandlers 

// -----------------------------------------------------------------------------
Function GetRoomsWithStatuses(pExtSystemCode, pLanguageCode, pHotelCode, pRoomSectionCode, pRoomStatusCode, pRoomTypeCode)
	vHotel = Undefined;
	If Not IsBlankString(pHotelCode) Then
		vHotel = cmGetHotelByCode(pHotelCode, pExtSystemCode);
	EndIf;
	vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(pExtSystemCode, vHotel);
	If Not ValueIsFilled(vInteraction) Then
		vErrorXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/housekeeping/", "Error"));
		Return Catalogs.ExternalSystemInteractions.GetAuthError(pExtSystemCode, "SOAP", vErrorXDTO);
	EndIf;
	
	Return cmGetRoomsWithStatuses(?(IsBlankString(vInteraction.InteractionID), TrimR(vInteraction.Code), TrimR(vInteraction.InteractionID)), pLanguageCode, pHotelCode, pRoomSectionCode, pRoomStatusCode, pRoomTypeCode, "XDTO", True);
EndFunction // GetRoomsWithStatuses

// -----------------------------------------------------------------------------
Function GetRoomStatuses(pExtSystemCode, pLanguageCode, pEmployeeCode, pHotelCode)
	vHotel = Undefined;
	If Not IsBlankString(pHotelCode) Then
		vHotel = cmGetHotelByCode(pHotelCode, pExtSystemCode);
	EndIf;
	vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(pExtSystemCode, vHotel);
	If Not ValueIsFilled(vInteraction) Then
		vErrorXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/housekeeping/", "Error"));
		Return Catalogs.ExternalSystemInteractions.GetAuthError(pExtSystemCode, "SOAP", vErrorXDTO);
	EndIf;
	
	Return cmGetRoomStatuses(?(IsBlankString(vInteraction.InteractionID), TrimR(vInteraction.Code), TrimR(vInteraction.InteractionID)), pLanguageCode, pEmployeeCode, "XDTO", pHotelCode);
EndFunction // GetRoomStatuses

// -----------------------------------------------------------------------------
Function ChangeRoomStatus(pExtSystemCode, pLanguageCode, pHotelCode, pRoomCode, pCurrentRoomStatusCode, pNewRoomStatusCode, pEmployeeCode)
	vHotel = Undefined;
	If Not IsBlankString(pHotelCode) Then
		vHotel = cmGetHotelByCode(pHotelCode, pExtSystemCode);
	EndIf;
	vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(pExtSystemCode, vHotel);
	If Not ValueIsFilled(vInteraction) Then
		vErrorXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/housekeeping/", "Error"));
		Return Catalogs.ExternalSystemInteractions.GetAuthError(pExtSystemCode, "SOAP", vErrorXDTO);
	EndIf;

	Return cmChangeRoomStatus(?(IsBlankString(vInteraction.InteractionID), TrimR(vInteraction.Code), TrimR(vInteraction.InteractionID)), pLanguageCode, pHotelCode, pRoomCode, pCurrentRoomStatusCode, pNewRoomStatusCode, pEmployeeCode, "XDTO");
EndFunction // ChangeRoomStatus

// -----------------------------------------------------------------------------
Function ActionProcessing(pExtSystemCode, pMainCode, pActionCode, pTimestamp, pLanguage = "RU")
	// Recognizing the action
	vDataStructure = cmGetDataByActionCode(pActionCode);
	vHotel = Undefined;
	If vDataStructure <> Undefined Then
		vHotel = vDataStructure.Hotel;
	EndIf;	
	vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(pExtSystemCode, vHotel);
	If Not ValueIsFilled(vInteraction) Then
		vErrorXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/housekeeping/", "Error"));
		Return Catalogs.ExternalSystemInteractions.GetAuthError(pExtSystemCode, "SOAP", vErrorXDTO);
	EndIf;
	
	Return cmActionProcessing(pMainCode, pActionCode, pTimestamp, pLanguage, ?(IsBlankString(vInteraction.InteractionID), TrimR(vInteraction.Code), TrimR(vInteraction.InteractionID)));
EndFunction // ActionProcessing

// -----------------------------------------------------------------------------
Function ChangeMiniBarStatus(pExtSystemCode, pRoomCode, pHotelCode, pLanguage)
	vHotel = Undefined;
	If Not IsBlankString(pHotelCode) Then
		vHotel = cmGetHotelByCode(pHotelCode, pExtSystemCode);
	EndIf;
	vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(pExtSystemCode, vHotel);
	If Not ValueIsFilled(vInteraction) Then
		vErrorXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/housekeeping/", "Error"));
		Return Catalogs.ExternalSystemInteractions.GetAuthError(pExtSystemCode, "SOAP", vErrorXDTO);
	EndIf;
	
	Return cmChangeMiniBarStatus(pRoomCode, pHotelCode, pLanguage, ?(IsBlankString(vInteraction.InteractionID), TrimR(vInteraction.Code), TrimR(vInteraction.InteractionID)));
EndFunction // ChangeMiniBarStatus

// -----------------------------------------------------------------------------
Function RegisterRoomTag(pActionCode, pRoomCode, pHotelCode, pLanguage)
	Return cmRegisterRoomTag(pActionCode, pRoomCode, pHotelCode, pLanguage);
EndFunction // RegisterRoomTag

// -----------------------------------------------------------------------------
Function RegisterEmployeeTag(pActionCode, pEmployeeCode, pHotelCode, pLanguage)
	Return cmRegisterEmployeeTag(pActionCode, pEmployeeCode, pHotelCode, pLanguage);
EndFunction // RegisterEmployeeTag

// -----------------------------------------------------------------------------
Function RegisterMinibarTag(pActionCode, pRoomCode, pHotelCode, pLanguage)
	Return cmRegisterMinibarTag(pActionCode, pRoomCode, pHotelCode, pLanguage);
EndFunction // RegisterMinibarTag

// -----------------------------------------------------------------------------
Function AddNewTask(pExtSystemCode, pActionCode, pHotelCode, pLanguageCode, pRemarks, pRoomCode, pTaskType, pPhoto)
	vHotel = Undefined;
	If Not IsBlankString(pHotelCode) Then
		vHotel = cmGetHotelByCode(pHotelCode, pExtSystemCode);
	EndIf;
	vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(pExtSystemCode, vHotel);
	If Not ValueIsFilled(vInteraction) Then
		vErrorXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/housekeeping/", "Error"));
		Return Catalogs.ExternalSystemInteractions.GetAuthError(pExtSystemCode, "SOAP", vErrorXDTO);
	EndIf;
	
	Return cmAddNewTask(pActionCode, pHotelCode, pLanguageCode, pRemarks, pRoomCode, pTaskType, pPhoto, ?(IsBlankString(vInteraction.InteractionID), TrimR(vInteraction.Code), TrimR(vInteraction.InteractionID)));
EndFunction // AddNewTask

#EndRegion
