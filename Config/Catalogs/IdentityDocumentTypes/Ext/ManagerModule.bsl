
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure mmLoadFromDictionary() Export 
	BeginTransaction(DataLockControlMode.Managed);
	Try
		vIDDocsList = Catalogs.IdentityDocumentTypes.GetTemplate("UMMSCodesRu");
		vCount = vIDDocsList.TableHeight - 1;
		For vInt = 2 To (vCount + 1) Do
			vDocCode = TrimAll(vIDDocsList.Area(vInt, 3, vInt, 3).Text);
			If IsBlankString(vDocCode) Then
				Break;
			EndIf;
			If vDocCode = "10" Then
				vDocCode = "ИП";
			EndIf;
			If vDocCode = "13" Then
				vDocCode = "УБ";
			EndIf;
			If StrLen(vDocCode) = 1 Then
				vDocCode = "0" + vDocCode;
			EndIf;
			
			vDoLoad = TrimAll(vIDDocsList.Area(vInt, 4, vInt, 4).Text);
			If vDoLoad <> "True" Then
				Continue;
			EndIf;
			
			vDocRef = Catalogs.IdentityDocumentTypes.FindByCode(vDocCode);
			If ValueIsFilled(vDocRef) Then
				vDocObj = vDocRef.GetObject();
				vDocObj.DeletionMark = False;
			Else
				vDocObj = Catalogs.IdentityDocumentTypes.CreateItem();
				vDocObj.Code = vDocCode;
			EndIf;
			
			vDocObj.Description = TrimAll(vIDDocsList.Area(vInt, 2, vInt, 2).Text);
			vDocObj.ExternalCode = TrimAll(vIDDocsList.Area(vInt, 1, vInt, 1).Text);
			
			vDocObj.Write();
		EndDo;
		
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Identity document types have been processed'; 
														|de = 'Informationen wurden aktualisiert'; 
														|ru = 'Обновлена информация о видах документов удостоверяющих личность'"), MessageStatus.Information);
		CommitTransaction();
	Except   
		RollbackTransaction();
		vErrorDescription = ErrorDescription();
		Raise vErrorDescription;
	EndTry;
EndProcedure // mmLoadFromDictionary

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, , pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

#EndRegion
