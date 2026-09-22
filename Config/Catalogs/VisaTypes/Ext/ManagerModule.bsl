
#Region Public

// --------------------------------------------------------------------------------
Procedure mmLoadFromDictionary() Export
	BeginTransaction(DataLockControlMode.Managed);
	Try
		vIDList = Catalogs.VisaTypes.GetTemplate("VisaCategoriesRu");
		vCount = vIDList.TableHeight - 1;
		For vInd = 2 To (vCount + 1) Do
			vCode = TrimAll(vIDList.Area(vInd, 1, vInd, 1).Text);
			If IsBlankString(vCode) Then
				Break;
			EndIf;
			vDescription = TrimAll(vIDList.Area(vInd, 2, vInd, 2).Text);
			
			vRef = Catalogs.VisaTypes.FindByCode(vCode);
			If ValueIsFilled(vRef) Then
				vObj = vRef.GetObject();
			Else
				vObj = Catalogs.VisaTypes.CreateItem();
				vObj.Code = vCode;
			EndIf;
			
			vObj.Description = vDescription;
			
			vObj.Write();
		EndDo;
		// Delete old visa types
		vRef = Catalogs.VisaTypes.FindByCode("ОК");
		If ValueIsFilled(vRef) And Not vRef.DeletionMark Then
			vObj = vRef.GetObject();
			vObj.DeletionMark = True;
			vObj.Description = "** УДАЛЕНО **" + TrimAll(vObj.Description);
			vObj.Write();
		EndIf;
		vRef = Catalogs.VisaTypes.FindByCode("2К");
		If ValueIsFilled(vRef) And Not vRef.DeletionMark Then
			vObj = vRef.GetObject();
			vObj.DeletionMark = True;
			vObj.Description = "** УДАЛЕНО **" + TrimAll(vObj.Description);
			vObj.Write();
		EndIf;
		vRef = Catalogs.VisaTypes.FindByCode("МН");
		If ValueIsFilled(vRef) And Not vRef.DeletionMark Then
			vObj = vRef.GetObject();
			vObj.DeletionMark = True;
			vObj.Description = "** УДАЛЕНО **" + TrimAll(vObj.Description);
			vObj.Write();
		EndIf;
		vRef = Catalogs.VisaTypes.FindByCode("ТЗ");
		If ValueIsFilled(vRef) And Not vRef.DeletionMark Then
			vObj = vRef.GetObject();
			vObj.DeletionMark = True;
			vObj.Description = "** УДАЛЕНО **" + TrimAll(vObj.Description);
			vObj.Write();
		EndIf;
		vRef = Catalogs.VisaTypes.FindByCode("3К");
		If ValueIsFilled(vRef) And Not vRef.DeletionMark Then
			vObj = vRef.GetObject();
			vObj.DeletionMark = True;
			vObj.Description = "** УДАЛЕНО **" + TrimAll(vObj.Description);
			vObj.Write();
		EndIf;
		vRef = Catalogs.VisaTypes.FindByCode("ТУР");
		If ValueIsFilled(vRef) And Not vRef.DeletionMark Then
			vObj = vRef.GetObject();
			vObj.DeletionMark = True;
			vObj.Description = "** УДАЛЕНО **" + TrimAll(vObj.Description);
			vObj.Write();
		EndIf;
		vRef = Catalogs.VisaTypes.FindByCode("ДИП");
		If ValueIsFilled(vRef) And Not vRef.DeletionMark Then
			vObj = vRef.GetObject();
			vObj.DeletionMark = True;
			vObj.Description = "** УДАЛЕНО **" + TrimAll(vObj.Description);
			vObj.Write();
		EndIf;      
		vMsg = NStr("en='Visa types have been processed';ru='Обновлена информация о типах виз';de='Informationen wurden aktualisiert'");
		tcCommonFunctionOnClientServer.TextMessage(vMsg, MessageStatus.Information);
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
