 
#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

// -----------------------------------------------------------------------------
Procedure OnSetNewCode(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(SessionParameters.CurrentHotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(SessionParameters.CurrentHotel);
	EndIf;
	If vPrefix <> "" Then
		pPrefix = vPrefix;
	EndIf;
EndProcedure // OnSetNewCode

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Current hotel
	Owner = SessionParameters.CurrentHotel;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmCheckPhoneNumberAttributes(pMessage, pAttributeInErr) Export
	vHasErrors = False;
	pMessage = "";
	pAttributeInErr = "";
	vMsgTextRu = "";
	vMsgTextEn = "";
	If Not ValueIsFilled(Owner) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Гостиница> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Hotel> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Owner", pAttributeInErr);
	EndIf;
	If IsBlankString(PhoneNumber) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Номер телефона> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Phone number> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "PhoneNumber", pAttributeInErr);
	EndIf;
	If IsBlankString(Description) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Наименование> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Description> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Description", pAttributeInErr);
	EndIf;
	If vHasErrors Then
		pMessage = "ru = '" + TrimAll(vMsgTextRu) + "';" + "en = '" + TrimAll(vMsgTextEn) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // pmCheckPhoneNumberAttributes

#EndRegion
