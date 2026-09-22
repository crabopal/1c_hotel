
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure Posting(pCancel, pMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	// Write income to the cash register
	Movement = RegisterRecords.CashInCashRegisters.AddReceipt();
	
	Movement.Period = Date;
	
	FillPropertyValues(Movement, ThisObject);
	
	RegisterRecords.CashInCashRegisters.Write();
EndProcedure // Posting

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pWriteMode, pPostingMode)
	Var vMessage, vAttributeInErr;
	If DataExchange.Load Then
		Return;
	EndIf;
	If pWriteMode = DocumentWriteMode.Posting Then
		pCancel	= pmCheckDocumentAttributes(vMessage, vAttributeInErr);
		If pCancel Then
			WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
			tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
			Raise NStr(vMessage);
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure OnSetNewNumber(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(Company) And Not IsBlankString(Company.Prefix) Then
		vPrefix = TrimAll(Company.Prefix);
	ElsIf ValueIsFilled(SessionParameters.CurrentHotel) Then
		If ValueIsFilled(SessionParameters.CurrentHotel.Company) And Not IsBlankString(SessionParameters.CurrentHotel.Company.Prefix) Then
			vPrefix = TrimAll(SessionParameters.CurrentHotel.Company.Prefix);
		EndIf;
	EndIf;
	If vPrefix <> "" Then
		pPrefix = vPrefix;
	EndIf;
EndProcedure // OnSetNewNumber

// -----------------------------------------------------------------------------
Procedure BeforeDelete(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToEditPostedCashIncomeOutcomeTransactions") Then
		pCancel = True;
	EndIf;
EndProcedure // BeforeDelete

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel) 
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

#EndRegion

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
	If Not ValueIsFilled(Company) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Фирма> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Company> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Company> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Company", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(CashRegister) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <ККМ> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Cash register> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Cash register> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "CashRegister", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(Currency) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Валюта> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Currency> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Currency> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Currency", pAttributeInErr);
	EndIf;
	If Sum < 0 Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Для оформления выплаты необходимо использовать документ ""Выплата денег""!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "Use ""Cash outcome"" document to outcome money!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "Use ""Cash outcome"" document to outcome money!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Sum", pAttributeInErr);
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
	pmFillAuthorAndDate();
	// Fill from session parameters
	If Not ValueIsFilled(Company) Then
		If ValueIsFilled(SessionParameters.CurrentHotel) Then
			Currency = SessionParameters.CurrentHotel.BaseCurrency;
			If ValueIsFilled(SessionParameters.CurrentHotel.Company) Then
				Company = SessionParameters.CurrentHotel.Company;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

#EndRegion
