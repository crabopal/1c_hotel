
#Region Public

// -----------------------------------------------------------------------------
Procedure mmLoadFromDictionary() Export 
	BeginTransaction(DataLockControlMode.Managed);
	Try
		vIDList = Catalogs.EntryGoals.GetTemplate("EntryGoalsRu");
		vCount = vIDList.TableHeight - 1;
		For vInt = 2 To (vCount + 1) Do
			vCode = TrimAll(vIDList.Area(vInt, 1, vInt, 1).Text);
			If IsBlankString(vCode) Then
				Break;
			EndIf;
			vDescription = TrimAll(vIDList.Area(vInt, 2, vInt, 2).Text);
			vVisaTypeID = TrimAll(vIDList.Area(vInt, 3, vInt, 3).Text);
			
			vRef = Catalogs.EntryGoals.FindByCode(vCode);
			If ValueIsFilled(vRef) Then
				vObj = vRef.GetObject();
			Else
				vObj = Catalogs.EntryGoals.CreateItem();
				vObj.Code = vCode;
			EndIf;
			
			vObj.Description = vDescription;
			vObj.VisaType = Catalogs.VisaTypes.FindByCode(vVisaTypeID);
			
			vObj.Write();
		EndDo;    
		vMsg = NStr("en = 'Entry goals have been processed'; 
					|de = 'Informationen wurden aktualisiert'; 
					|ru = 'Обновлена информация о целях въезда'");
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
