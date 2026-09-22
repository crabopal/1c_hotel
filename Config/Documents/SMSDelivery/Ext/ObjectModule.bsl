
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure OnSetNewNumber(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(Hotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(Hotel);
	ElsIf ValueIsFilled(SessionParameters.CurrentHotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(SessionParameters.CurrentHotel);
	EndIf;
	If vPrefix <> "" Then
		pPrefix = vPrefix;
	EndIf;
EndProcedure // OnSetNewNumber

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pWriteMode, pPostingMode)
	Var vMessage, vAttributeInErr;
	// Check mode
	If DataExchange.Load Then
		Return;
	EndIf;
	// Check that document is correct
	If pmCheckDocumentAttributes(vMessage, vAttributeInErr) Then
		Raise NStr(vMessage);
	EndIf;
	// Fill document delivery status
	vDeliveryStatus = pmGetDeliveryStatus();
	If vDeliveryStatus <> DeliveryStatus Then
		DeliveryStatus = vDeliveryStatus;
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure BeforeDelete(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // BeforeDelete

// -----------------------------------------------------------------------------
Procedure OnCopy(pCopiedObject)
	DeliveryStatus = Enums.SMSDeliveryStatuses.New;
	For Each vRow In Receivers Do
		vRow.IsSent = False;
		vRow.Result = "";
		vRow.MessageID = "";
		vRow.Cost = 0;
	EndDo;
EndProcedure // OnCopy

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)  
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
Procedure pmFillAuthorAndDate() Export
	Date = BegOfDay(CurrentSessionDate());
	Author = SessionParameters.CurrentUser;
EndProcedure // pmFillAuthorAndDate

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill author and document date
	pmFillAuthorAndDate();
	// Fill from session parameters
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	// Fill delivery type
	If Not ValueIsFilled(DeliveryType) Then
		DeliveryType = Enums.DeliveryTypes.SMS;
	EndIf;
	// Fill document status
	If Not ValueIsFilled(DeliveryStatus) Then
		DeliveryStatus = Enums.SMSDeliveryStatuses.New;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmCheckDocumentAttributes(pMessage, pAttributeInErr) Export
	vHasErrors = False;
	pMessage = "";
	pAttributeInErr = "";
	vMsgTextRu = "";
	vMsgTextEn = "";
	vMsgTextDe = "";
	If AdditionalProperties.Property("InfoBaseUpdateMode") And AdditionalProperties.InfoBaseUpdateMode Then
		Return vHasErrors;
	EndIf;
	If Not ValueIsFilled(DeliveryType) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Вид доставки> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Delivery type> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Delivery type> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "DeliveryType", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(Hotel) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Гостиница> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Hotel> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Hotel> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Hotel", pAttributeInErr);
	EndIf;
	For Each vRow In Receivers Do
		If (DeliveryType = Enums.DeliveryTypes.SMS Or DeliveryType = Enums.DeliveryTypes.Both) And IsBlankString(vRow.Phone) Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "В строке " + Format(vRow.LineNumber, "ND=5; NFD=0; NG=") + " реквизит <Номер телефона> должен быть заполнен!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "<Phone number> attribute in line number " + Format(vRow.LineNumber, "ND=5; NFD=0; NG=") + " should be filled!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "<Phone number> attribute in line number " + Format(vRow.LineNumber, "ND=5; NFD=0; NG=") + " should be filled!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "Receivers", pAttributeInErr);
		EndIf;
		If (DeliveryType = Enums.DeliveryTypes.EMail Or DeliveryType = Enums.DeliveryTypes.Both) And IsBlankString(vRow.EMail) Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "В строке " + Format(vRow.LineNumber, "ND=5; NFD=0; NG=") + " реквизит <E-Mail> должен быть заполнен!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "<E-Mail> attribute in line number " + Format(vRow.LineNumber, "ND=5; NFD=0; NG=") + " should be filled!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "<E-Mail> attribute in line number " + Format(vRow.LineNumber, "ND=5; NFD=0; NG=") + " should be filled!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "Receivers", pAttributeInErr);
		EndIf;
		If DeliveryType = Enums.DeliveryTypes.Unisender And IsBlankString(vRow.Phone) And IsBlankString(vRow.EMail) Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "В строке " + Format(vRow.LineNumber, "ND=5; NFD=0; NG=") + " реквизит <Номер телефона> и/или реквизит <E-Mail> должны быть заполнены!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "<Phone number> and/or <E-Mail> attributes in line number " + Format(vRow.LineNumber, "ND=5; NFD=0; NG=") + " should be filled!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "<Phone number> and/or <E-Mail> attributes in line number " + Format(vRow.LineNumber, "ND=5; NFD=0; NG=") + " should be filled!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "Receivers", pAttributeInErr);
		EndIf;
		If DeliveryType = Enums.DeliveryTypes.Unisender And Not ValueIsFilled(vRow.Client) Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "В строке " + Format(vRow.LineNumber, "ND=5; NFD=0; NG=") + " реквизит <Клиент> должен быть заполнен!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "<Client> attribute in line number " + Format(vRow.LineNumber, "ND=5; NFD=0; NG=") + " should be filled!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "<Client> attribute in line number " + Format(vRow.LineNumber, "ND=5; NFD=0; NG=") + " should be filled!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "Receivers", pAttributeInErr);
		EndIf;
		If IsBlankString(vRow.SMSText) And DeliveryType <> Enums.DeliveryTypes.Unisender And DeliveryType <> Enums.DeliveryTypes.DoNotSend And DeliveryType <> Enums.DeliveryTypes.EMail Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "В строке " + Format(vRow.LineNumber, "ND=5; NFD=0; NG=") + " реквизит <Текст сообщения> должен быть заполнен!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "<Message text> attribute in line number " + Format(vRow.LineNumber, "ND=5; NFD=0; NG=") + " should be filled!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "<Message text> attribute in line number " + Format(vRow.LineNumber, "ND=5; NFD=0; NG=") + " should be filled!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "Receivers", pAttributeInErr);
		EndIf;
	EndDo;
	If vHasErrors Then
		pMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // pmCheckDocumentAttributes

// -----------------------------------------------------------------------------
Function pmGetDeliveryStatus() Export
	vNotSentIsFound = False;
	vSentIsFound = False;
	For Each vRow In Receivers Do
		If vRow.IsSent Then
			vSentIsFound = True;
		Else
			vNotSentIsFound = True;
		EndIf;
	EndDo;
	If vSentIsFound And Not vNotSentIsFound Then
		Return Enums.SMSDeliveryStatuses.Sent;
	ElsIf vSentIsFound And vNotSentIsFound Then
		Return Enums.SMSDeliveryStatuses.PartiallySent;
	ElsIf Not vSentIsFound And vNotSentIsFound Then
		Return Enums.SMSDeliveryStatuses.New;
	Else
		Return Undefined;
	EndIf;
EndFunction // pmGetDeliveryStatus

#EndRegion
