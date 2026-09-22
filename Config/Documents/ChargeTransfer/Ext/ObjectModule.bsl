
#Region EventHandlers

// -----------------------------------------------------------------------------
// Document will change folio in the parent charge/storno document and do posting for it
// -----------------------------------------------------------------------------
Procedure Posting(pCancel, pPostingMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	vCharges = New ValueList();
	If ValueIsFilled(ParentCharge) And ValueIsFilled(Hotel) And 
	   ParentCharge.IsMergedToRoomRevenue And Not ValueIsFilled(ParentCharge.RoomRevenueCharge) Then
		vRoomRateDocs = cmGetRoomRateTransactions(ParentCharge);
		If vRoomRateDocs.Count() = 0 Then
			vCharges.Add(ParentCharge);
		Else
			For Each vRoomRateDocsRow In vRoomRateDocs Do
				If TypeOf(vRoomRateDocsRow.Ref) = Type("DocumentRef.Charge") And 
				   Not cmIfChargeIsCanceled(vRoomRateDocsRow.Ref) Then
					vCharges.Add(vRoomRateDocsRow.Ref);
				EndIf;
			EndDo;
		EndIf;
	Else
		vCharges.Add(ParentCharge);
	EndIf;
	// Change folio in the parent charge document
	For Each vChargesItem In vCharges Do
		vParentCharge = vChargesItem.Value;
		// Process charge
		vVATRateWasChanged = False;
		vParentChargeObj = vParentCharge.GetObject();
		vParentChargeObj.Folio = FolioTo;
		If vParentChargeObj.Hotel <> FolioTo.Hotel And ValueIsFilled(FolioTo.Hotel) Then
			vParentChargeObj.Hotel = FolioTo.Hotel;
			vParentChargeObj.SetNewNumber();
		EndIf;
		If ValueIsFilled(FolioTo.Company) And vParentChargeObj.Company <> FolioTo.Company Then
			vNewCompany = FolioTo.Company;
			vParentChargeObj.Company = vNewCompany;
			If vNewCompany.IsUsingSimpleTaxSystem And vParentChargeObj.VATRate <> vNewCompany.VATRate Then
				vParentChargeObj.VATRate = vNewCompany.VATRate;
				vVATRateWasChanged = True;
			EndIf;
		EndIf;
		If ValueIsFilled(FolioTo.HotelProduct) Then
			vParentChargeObj.HotelProduct = FolioTo.HotelProduct;
		EndIf;
		If vVATRateWasChanged Then
			vParentChargeObj.VATSum = cmCalculateVATSum(vParentChargeObj.VATRate, vParentChargeObj.Sum, vParentChargeObj.Date);
			vParentChargeObj.VATDiscountSum = cmCalculateVATSum(vParentChargeObj.VATRate, vParentChargeObj.DiscountSum, vParentChargeObj.Date);
			vParentChargeObj.VATCommissionSum = cmCalculateVATSum(vParentChargeObj.VATRate, vParentChargeObj.CommissionSum, vParentChargeObj.Date);
		EndIf;
		vParentChargeObj.ChargeTransfer = Ref;
		// Post this changed charge
		vParentChargeObj.Write(DocumentWriteMode.Posting);
		// Repost folio from charges
		If Not vParentChargeObj.IsFixedCharge Then
			If ValueIsFilled(vParentChargeObj.BoundCharge) Or ValueIsFilled(cmGetBoundService(vParentChargeObj.Service)) Then
				vFolioObj = FolioFrom.GetObject();
				vFolioObj.pmRepostAdditionalCharges(vParentCharge);
			EndIf;
		EndIf;
	EndDo;
EndProcedure // Posting

// -----------------------------------------------------------------------------
Procedure Filling(pBase)
	// Fill attributes with default values
	pmFillAttributesWithDefaultValues();
	// Fill from the base
	If ValueIsFilled(pBase) Then
		If TypeOf(pBase) = Type("DocumentRef.Charge") Then
			ParentDoc = pBase.ParentDoc;
			FolioFrom = pBase.Folio;
			ParentCharge = pBase;
			If ValueIsFilled(ParentCharge.Hotel) Then
				If Hotel <> ParentCharge.Hotel Then
					Hotel = ParentCharge.Hotel;
					SetNewNumber(Catalogs.Hotels.pmGetPrefix(Hotel));
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // Filling

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
		// Check if charge was canceled
		If Not Posted And CheckIfChargeWasCanceled() Then
			vMessage = "en='Transfer operation is prohibited for canceled transactions!'; ru='Операция переноса запрещена для отмененных начислений!'; de='Der transfervorgang ist für stornierte Gebühren verboten!'";
			WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
			tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
			Raise NStr(vMessage);
		EndIf;
		If IsNew() Then    
				vEventDescription = StrTemplate(NStr("en = 'Create charge transfer: %1 from %2, %3'; 
													 |de = 'Kostenübernahme erstellen: %1 from %2, %3'; 
													 |ru = 'Создано перемещение начисления: %1 от %2, %3'"), TrimAll(ParentCharge.Service), ParentCharge.ServiceDate, cmFormatSum(ParentCharge.Sum, ParentCharge.FolioCurrency)); 
				AddUserLog(vEventDescription);
		EndIf;
	Else
		// Check if this charge is closed by settlement
		If ValueIsFilled(Hotel) And Hotel.DoNotEditSettledDocs And ValueIsFilled(ParentCharge) And 
		   pWriteMode = DocumentWriteMode.UndoPosting And 
		  (ParentCharge.Sum <> 0 Or ParentCharge.Quantity <> 0) And 
		   ValueIsFilled(FolioFrom) And FolioFrom.IsClosed Then
			vChargeBalanceIsZero = False;
			vChargeBalancesRow = cmGetChargeCurrentAccountsReceivableBalance(ParentCharge);
			If vChargeBalancesRow <> Undefined Then
				If vChargeBalancesRow.SumBalance = 0 And vChargeBalancesRow.QuantityBalance = 0 Then
					vChargeBalanceIsZero = True;
				EndIf;
			Else
				vChargeBalanceIsZero = True;
			EndIf;
			If vChargeBalanceIsZero Then
				pCancel = True;
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='This charge is closed by settlement! Charge is read only.';
				             |ru='Начисление уже закрыто актом об оказании услуг! Редактирование такого начисления запрещено.';
							 |de='Die Anrechnung wurde bereits über ein Übergabeprotokoll über die Erbringung von Dienstleistungen geschlossen! Die Bearbeitung einer solchen Anrechnung ist verboten.'"), MessageStatus.Attention);
				Return;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure OnSetNewNumber(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(SessionParameters.CurrentHotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(SessionParameters.CurrentHotel);
	EndIf;
	If vPrefix <> "" Then
		pPrefix = vPrefix;
	EndIf;
EndProcedure // OnSetNewNumber

// -----------------------------------------------------------------------------
Procedure UndoPosting(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	pmUndoPosting(pCancel);
EndProcedure // UndoPosting

// -----------------------------------------------------------------------------
Procedure BeforeDelete(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	If Posted Then
		// Check if this charge is closed by settlement
		If ValueIsFilled(Hotel) And Hotel.DoNotEditSettledDocs And ValueIsFilled(ParentCharge) And 
		  (ParentCharge.Sum <> 0 Or ParentCharge.Quantity <> 0) And 
		   ValueIsFilled(FolioFrom) And FolioFrom.IsClosed Then
			vChargeBalanceIsZero = False;
			vChargeBalancesRow = cmGetChargeCurrentAccountsReceivableBalance(ParentCharge);
			If vChargeBalancesRow <> Undefined Then
				If vChargeBalancesRow.SumBalance = 0 And vChargeBalancesRow.QuantityBalance = 0 Then
					vChargeBalanceIsZero = True;
				EndIf;
			Else
				vChargeBalanceIsZero = True;
			EndIf;
			If vChargeBalanceIsZero Then
				pCancel = True;
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='This charge is closed by settlement! Charge is read only.';
				             |ru='Начисление уже закрыто актом об оказании услуг! Редактирование такого начисления запрещено.';
							 |de='Die Anrechnung wurde bereits über ein Übergabeprotokoll über die Erbringung von Dienstleistungen geschlossen! Die Bearbeitung einer solchen Anrechnung ist verboten.'"), MessageStatus.Attention);
				Return;
			EndIf;
		EndIf;
		// Check if this transfer is in closed day
		If ValueIsFilled(Hotel) And Hotel.DoNotEditClosedDateDocs Then
			vChargeIsInClosedDay = cmIfChargeIsInClosedDay(Ref);
			If vChargeIsInClosedDay Then
				pCancel = True;
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='This transfer is in closed day! Charge transfer is read only.';
				             |ru='Перемещение в закрытом дне! Редактирование такого перемещения запрещено.';
							 |de='Verschiebung im geschlossenen Tag! Die Editierung einer solchen Verschiebung ist verboten.'"), MessageStatus.Attention);
				Return;
			EndIf;
		EndIf;
		pmUndoPosting(pCancel);    
		
		// User activity history   
		vEventDescription = StrTemplate(NStr("en = 'Document deletion сharge transfer: %1 from %2, %3'; 
											 |de = 'Unmittelbare Löschung Verschiebung der Anrechnung: %1 from %2, %3'; 
											 |ru = 'Непосредственное удаление переноса начисления: %1 от %2, %3'"), TrimAll(ParentCharge.Service), ParentCharge.ServiceDate, cmFormatSum(ParentCharge.Sum, ParentCharge.FolioCurrency));    
		AddUserLog(vEventDescription);
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
	If Not ValueIsFilled(ParentCharge) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Начисление> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Parent charge> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Parent charge> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "ParentCharge", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(FolioFrom) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Лицевой счет источник> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Folio from> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Folio from> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "FolioFrom", pAttributeInErr);
	Else
		If FolioFrom.DeletionMark Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "<Лицевой счет источник> помечен на удаление!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "<Folio from> is marked for deletion!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "<Folio from> is marked for deletion!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "FolioFrom", pAttributeInErr);
		EndIf;
	EndIf;
	If Not ValueIsFilled(FolioTo) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Лицевой счет получатель> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Folio to> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Folio to> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "FolioTo", pAttributeInErr);
	Else
		If FolioTo.DeletionMark Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "<Лицевой счет получатель> помечен на удаление!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "<Folio to> is marked for deletion!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "<Folio to> is marked for deletion!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "FolioTo", pAttributeInErr);
		EndIf;
	EndIf;
	If ValueIsFilled(FolioFrom) And ValueIsFilled(FolioTo) Then
		If FolioFrom = FolioTo Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Лицевые счета должны быть разными!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "Folios should not be the same!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "Folios should not be the same!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "FolioTo", pAttributeInErr);
		EndIf;
	EndIf;
	If ValueIsFilled(FolioFrom) And ValueIsFilled(FolioTo) Then
		If FolioFrom.FolioCurrency <> FolioTo.FolioCurrency Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Перемещать начисление можно только между лицевыми счетами в одной валюте!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "You can transfer charges between folios with the same folio currency only!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "You can transfer charges between folios with the same folio currency only!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "FolioTo", pAttributeInErr);
		EndIf;
	EndIf;
	If Not Posted Then
		// Check user rights to do transfer
		vEmployee = SessionParameters.CurrentUser;
		If ValueIsFilled(vEmployee) And ValueIsFilled(vEmployee.PermissionGroup) And ValueIsFilled(FolioFrom) And ValueIsFilled(FolioTo) Then
			vPermissionGroup = vEmployee.PermissionGroup;
			For Each vPrmRow In vPermissionGroup.FolioOperationsAllowed Do
				If IsBlankString(vPrmRow.FolioType) Or 
				   Not IsBlankString(vPrmRow.FolioType) And TrimR(vPrmRow.FolioType) = Left(TrimR(FolioFrom.Description), StrLen(TrimR(vPrmRow.FolioType))) Then
					If vPrmRow.ChargeTransfersFromFolioForbidden Then
						vHasErrors = True;
						vMsgTextRu = vMsgTextRu + "Нет прав на перемещение начисления из фолио с типом " + TrimAll(FolioFrom.Description) + "!" + Chars.LF;
						vMsgTextEn = vMsgTextEn + "You do not have rights to transfer charges from folio type " + TrimAll(FolioFrom.Description) + "!" + Chars.LF;
						vMsgTextDe = vMsgTextDe + "Sie haben keine Rechte für Transfer von Folio-typ " + TrimAll(FolioFrom.Description) + " nutzen!" + Chars.LF;
						pAttributeInErr = ?(pAttributeInErr = "", "FolioFrom", pAttributeInErr);
					EndIf;
				EndIf;
				If IsBlankString(vPrmRow.FolioType) Or 
				   Not IsBlankString(vPrmRow.FolioType) And TrimR(vPrmRow.FolioType) = Left(TrimR(FolioTo.Description), StrLen(TrimR(vPrmRow.FolioType))) Then
					If vPrmRow.ChargeTransfersToFolioForbidden Then
						vHasErrors = True;
						vMsgTextRu = vMsgTextRu + "Нет прав на перемещение начисления на фолио с типом " + TrimAll(FolioTo.Description) + "!" + Chars.LF;
						vMsgTextEn = vMsgTextEn + "You do not have rights to transfer charges to folio type " + TrimAll(FolioTo.Description) + "!" + Chars.LF;
						vMsgTextDe = vMsgTextDe + "Sie haben keine Rechte für Transfer zum Folio-typ " + TrimAll(FolioTo.Description) + " nutzen!" + Chars.LF;
						pAttributeInErr = ?(pAttributeInErr = "", "FolioTo", pAttributeInErr);
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	If vHasErrors Then
		pMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // CheckDocumentAttributes

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
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function CheckIfChargeWasCanceled()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Storno.Ref
	|FROM
	|	Document.Storno AS Storno
	|WHERE
	|	Storno.Posted
	|	AND Storno.ParentCharge = &qParentCharge";
	vQry.SetParameter("qParentCharge", ParentCharge);
	vQryRes = vQry.Execute().Unload();
	If vQryRes.Count() > 0 Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // CheckIfChargeWasCanceled

// -----------------------------------------------------------------------------
Procedure pmUndoPosting(pCancel)
	// Change folio in the parent charge document back to it's initial value
	If ValueIsFilled(FolioFrom) And ValueIsFilled(ParentCharge) Then
		vCharges = New ValueList();
		If ValueIsFilled(ParentCharge) And ValueIsFilled(Hotel) And 
		   ParentCharge.IsMergedToRoomRevenue And Not ValueIsFilled(ParentCharge.RoomRevenueCharge) Then
			vRoomRateDocs = cmGetRoomRateTransactions(ParentCharge);
			If vRoomRateDocs.Count() = 0 Then
				vCharges.Add(ParentCharge);
			Else
				For Each vRoomRateDocsRow In vRoomRateDocs Do
					If TypeOf(vRoomRateDocsRow.Ref) = Type("DocumentRef.Charge") And 
					   Not cmIfChargeIsCanceled(vRoomRateDocsRow.Ref) Then
						vCharges.Add(vRoomRateDocsRow.Ref);
					EndIf;
				EndDo;
			EndIf;
		Else
			vCharges.Add(ParentCharge);
		EndIf;
		// Change folio in the parent charge document
		For Each vChargesItem In vCharges Do
			vParentCharge = vChargesItem.Value;
			vParentChargeObj = vParentCharge.GetObject();
			vParentChargeObj.Folio = FolioFrom;
			vParentChargeObj.Hotel = vParentChargeObj.Folio.Hotel;
			If ValueIsFilled(vParentChargeObj.Folio.Company) Then
				vParentChargeObj.Company = vParentChargeObj.Folio.Company;
				vParentChargeObj.VATRate = vParentChargeObj.Company.VATRate;
			EndIf;
			vParentChargeObj.FolioCurrency = vParentChargeObj.Folio.FolioCurrency;
			vParentChargeObj.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(vParentChargeObj.Hotel, vParentChargeObj.FolioCurrency, vParentChargeObj.ExchangeRateDate);
			vParentChargeObj.VATSum = cmCalculateVATSum(vParentChargeObj.VATRate, vParentChargeObj.Sum, vParentChargeObj.Date);
			vParentChargeObj.VATDiscountSum = cmCalculateVATSum(vParentChargeObj.VATRate, vParentChargeObj.DiscountSum, vParentChargeObj.Date);
			vParentChargeObj.VATCommissionSum = cmCalculateVATSum(vParentChargeObj.VATRate, vParentChargeObj.CommissionSum, vParentChargeObj.Date);
			vParentChargeObj.ChargeTransfer = Undefined;
			// Post this changed charge
			If Not vParentChargeObj.Posted Then
				vParentChargeObj.Write(DocumentWriteMode.Write);
			Else
				vParentChargeObj.Write(DocumentWriteMode.Posting);
			EndIf;
		EndDo;
	EndIf;
EndProcedure // pmUndoPosting

// -----------------------------------------------------------------------------
Procedure AddUserLog(pEventDescription)  
	vParentDoc = Ref;   
	If ValueIsFilled(ParentDoc) Then
		vParentDoc = ParentDoc; 
	ElsIf Not ValueIsFilled(ParentDoc) And IsNew() Then 
		vParentDoc = Documents.ChargeTransfer.GetRef(New UUID);
		SetNewObjectRef(vParentDoc);	
	EndIf;	
	InformationRegisters.UserActionsHistory.WriteUserActivityRecord(vParentDoc, pEventDescription, Hotel);
EndProcedure // AddUserLog

#EndRegion
