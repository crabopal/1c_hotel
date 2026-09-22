
#Region Public

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
	// Check attributes
	If Not ValueIsFilled(Hotel) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Гостиница> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Hotel> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Hotel> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Hotel", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(Client) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Клиент> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Client> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Kunde> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Client", pAttributeInErr);
	EndIf;
	If vHasErrors Then
		pMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // pmCheckDocumentAttributes

// -----------------------------------------------------------------------------
Procedure pmFillAuthorAndDate() Export
	Date = CurrentSessionDate();
	CreateDate = CurrentSessionDate();
	Author = SessionParameters.CurrentUser;
EndProcedure // pmFillAuthorAndDate

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill author and document date
	If Not ValueIsFilled(Author) Then
		pmFillAuthorAndDate();
	EndIf;
	// Fill from session parameters
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	// Method of refusal
	If Not ValueIsFilled(MethodOfRefusal) Then
		MethodOfRefusal = Enums.ProcessingOfPersonalDataTypesOfRefusal.Personally;
	EndIf;
	// What to clear
	If Not ClearNames And Not ClearPassport And Not ClearAddresses And Not ClearContacts Then
		ClearContacts = True;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

#EndRegion

#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pWriteMode, pPostingMode)
	Var vMessage, vAttributeInErr;
	If DataExchange.Load Then
		Return;
	EndIf;
	If pWriteMode = DocumentWriteMode.Write And Not DeletionMark Then
		vMessage = "";
		vAttributeInErr = "";
		If pmCheckDocumentAttributes(vMessage, vAttributeInErr) Then
			pCancel = True;
			vUM = New UserMessage();
			vUM.Text = NStr(vMessage);
			vUM.Field = vAttributeInErr;
			vUM.Message();
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;      
EndProcedure // OnWrite

// -----------------------------------------------------------------------------
Procedure OnSetNewNumber(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(Hotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(Hotel);
	Else
		If ValueIsFilled(SessionParameters.CurrentHotel) Then
			vPrefix = Catalogs.Hotels.pmGetPrefix(SessionParameters.CurrentHotel);
		EndIf;
	EndIf;
	If vPrefix <> "" Then
		pPrefix = vPrefix;
	EndIf;
EndProcedure // OnSetNewNumber

// -----------------------------------------------------------------------------
Procedure Filling(pFillingData, pFillingText, pStandardProcessing)
	If ValueIsFilled(pFillingData) Then
		pmFillAttributesWithDefaultValues();
		IsProcessed = False;
		ProcessingDate = '00010101';
		If TypeOf(pFillingData) = Type("DocumentRef.PersonalDataProcessingConsent") Then
			Client = pFillingData.Client;
			If ValueIsFilled(Hotel) Then
				If Hotel <> pFillingData.Hotel Then
					Hotel = pFillingData.Hotel;
					SetNewNumber();
				EndIf;
			Else
				Hotel = pFillingData.Hotel;
			EndIf;
		ElsIf TypeOf(pFillingData) = Type("CatalogRef.Clients") Then
			Client = pFillingData;
		EndIf;
	EndIf;
EndProcedure // Filling

// -----------------------------------------------------------------------------
Procedure OnCopy(pCopiedObject)
	pmFillAuthorAndDate();
	IsProcessed = False;
	ProcessingDate = '00010101';
EndProcedure

#EndRegion
   