
#Region Public

// --------------------------------------------------------------------------------
Procedure mmLoadFromDictionary() Export
	vCode = "";
	vDescription = "";
	vID = "";
	Try
		BeginTransaction(DataLockControlMode.Managed);
		vIDList = Catalogs.TripPurposes.GetTemplate("TripPurposesRu");
		vCount = vIDList.TableHeight - 1;
		For vInd = 2 To (vCount + 1) Do
			vCode = TrimAll(vIDList.Area(vInd, 1, vInd, 1).Text);
			If IsBlankString(vCode) Then
				Break;
			EndIf;
			vDescription = TrimAll(vIDList.Area(vInd, 2, vInd, 2).Text);
			vID = TrimAll(vIDList.Area(vInd, 3, vInd, 3).Text);
			
			vRef = Catalogs.TripPurposes.FindByCode(vCode);
			If ValueIsFilled(vRef) Then
				vObj = vRef.GetObject();
			Else
				vObj = Catalogs.TripPurposes.CreateItem();
				vObj.Code = vCode;
			EndIf;
			
			vObj.Description = vDescription;
			vObj.ExternalCode = vID;
			
			vObj.Write();
		EndDo;
		CommitTransaction();
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Trip purposes have been processed';ru='Обновлена информация о целях поездок';de='Informationen wurden aktualisiert'"), MessageStatus.Information);
	Except
		vErrorDescription = vCode + ", " + vDescription + ", " + vID + " - " + cmGetRootErrorDescription(ErrorInfo());
		RollbackTransaction();
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
