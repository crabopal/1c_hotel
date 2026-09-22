
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
	If Not ValueIsFilled(AgreementText) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Текст соглашения> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Agreement text> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Abkommenstext> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "AgreementText", pAttributeInErr);
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
	// Agreement text
	If ValueIsFilled(Hotel) And AgreementText <> Hotel.AgreementText Then
		pmFillAuthorAndDate();
		AgreementText = Hotel.AgreementText;
	EndIf;
	// Method of consent
	If Not ValueIsFilled(MethodOfConsent) Then
		MethodOfConsent = Enums.ProcessingOfPersonalDataTypesOfConsent.PaperAgreementSignature;
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
		Else
			// Automatically fill consent renewal request date
			If Not ValueIsFilled(RequestForConsentRenewalDate) And ValueIsFilled(Date) And ValueIsFilled(Client) And 
			   ValueIsFilled(AgreementText) And AgreementText.ConsentDuration > 0 And 
			   AgreementText.AskForConsentRenewalWhenExpired Then
				RequestForConsentRenewalDate = BegOfDay(AddMonth(Date, AgreementText.ConsentDuration));
			EndIf;
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	// Automatically create refusal if necessary
	If ValueIsFilled(Date) And ValueIsFilled(Client) And Not DeletionMark And
	   ValueIsFilled(AgreementText) And AgreementText.ConsentDuration > 0 And
	   Not ValueIsFilled(RequestForConsentRenewalDate) Then
		vRefusalDate = EndOfDay(AddMonth(Date, AgreementText.ConsentDuration));
		
		// Try to find and update existing refusal
		vRefusalRef = Undefined;
		vRefusalIsManuallyDeleted = False;
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	PersonalDataProcessingRefusal.Ref AS Ref
		|FROM
		|	Document.PersonalDataProcessingRefusal AS PersonalDataProcessingRefusal
		|WHERE
		|	PersonalDataProcessingRefusal.Client = &qClient
		|	AND NOT PersonalDataProcessingRefusal.IsProcessed
		|	AND NOT PersonalDataProcessingRefusal.DeletionMark
		|
		|ORDER BY
		|	PersonalDataProcessingRefusal.PointInTime DESC";
		vQry.SetParameter("qClient", Client);
		vRefusals = vQry.Execute().Unload();
		For Each vRefusalsRow In vRefusals Do
			vRefusalRef = vRefusalsRow.Ref;
			vRefusalObj = vRefusalRef.GetObject();
			vRefusalObj.Date = vRefusalDate;
			vRefusalObj.ClearNames = AgreementText.ClearNames;
			vRefusalObj.ClearPassport = AgreementText.ClearPassport;
			vRefusalObj.ClearAddresses = AgreementText.ClearAddresses;
			vRefusalObj.ClearContacts = AgreementText.ClearContacts;
			vRefusalObj.Write(DocumentWriteMode.Write);
		EndDo;
		If Not ValueIsFilled(vRefusalRef) Then
			vRefusalObj = Documents.PersonalDataProcessingRefusal.CreateDocument();
			vRefusalObj.Fill(Ref);
			vRefusalObj.MethodOfRefusal = Enums.ProcessingOfPersonalDataTypesOfRefusal.Automatically;
			vRefusalObj.Date = vRefusalDate;
			vRefusalObj.ClearNames = AgreementText.ClearNames;
			vRefusalObj.ClearPassport = AgreementText.ClearPassport;
			vRefusalObj.ClearAddresses = AgreementText.ClearAddresses;
			vRefusalObj.ClearContacts = AgreementText.ClearContacts;
			vRefusalObj.Write(DocumentWriteMode.Write);
		EndIf;
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
		RequestForConsentRenewalDate = '00010101';
		ConsentRenewalDate = '00010101';
		If TypeOf(pFillingData) = Type("CatalogRef.Clients") Then
			Client = pFillingData;
		EndIf;
	EndIf;
EndProcedure // Filling

// -----------------------------------------------------------------------------
Procedure OnCopy(pCopiedObject)
	pmFillAuthorAndDate();
	AgreementForm = Undefined;
	RequestForConsentRenewalDate = '00010101';
	ConsentRenewalDate = '00010101';
EndProcedure // OnCopy

#EndRegion

