
#Region Public

// -----------------------------------------------------------------------------
//
Procedure mmLoadFromDictionary() Export  
	BeginTransaction(DataLockControlMode.Managed);
	Try
		vListOfActiveCodes = New ValueList();
		vIDList = Catalogs.CheckPoints.GetTemplate("CheckPointsRu");
		vCount = vIDList.TableHeight - 1;
		For vInt = 2 To (vCount + 1) Do
			vCode = TrimAll(vIDList.Area(vInt, 1, vInt, 1).Text);
			If IsBlankString(vCode) Then
				Break;
			EndIf;
			vDescription = TrimAll(vIDList.Area(vInt, 2, vInt, 2).Text);
			
			vRef = Catalogs.CheckPoints.FindByCode(vCode);
			If ValueIsFilled(vRef) Then
				vObj = vRef.GetObject();
			Else
				vObj = Catalogs.CheckPoints.CreateItem();
				vObj.Code = vCode;
			EndIf;
			vObj.Description = vDescription;
			
			vObj.Write();
			
			vListOfActiveCodes.Add(vObj.Ref);
		EndDo;
		// Delete all inactive 
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	CheckPoints.Ref AS Ref
		|FROM
		|	Catalog.CheckPoints AS CheckPoints
		|WHERE
		|	NOT CheckPoints.Ref IN (&qListOfActiveCodes)
		|	AND NOT CheckPoints.DeletionMark
		|
		|ORDER BY
		|	CheckPoints.Code";
		vQry.SetParameter("qListOfActiveCodes", vListOfActiveCodes);
		vRefs = vQry.Execute().Unload();
		For Each vRefsRow In vRefs Do
			vObj = vRefsRow.Ref.GetObject();
			vObj.SetDeletionMark(True);
		EndDo;
		
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Check points have been processed';ru='Обновлена информация о КПП';de='Check Point Informationen wurden aktualisiert'"), MessageStatus.Information);
		CommitTransaction();
	Except       
		RollbackTransaction();
		vErrorDescription = ErrorDescription();
		Raise vErrorDescription;
	EndTry;
EndProcedure // mmLoadFromDictionary

// -----------------------------------------------------------------------------
//
Procedure mmClear() Export
 	BeginTransaction(DataLockControlMode.Managed);
	Try
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	CheckPoints.Ref AS Ref
		|FROM
		|	Catalog.CheckPoints AS CheckPoints";
		vQryRes = vQry.Execute().Select();
		While vQryRes.Next() Do
			vObj = vQryRes.Ref.GetObject();
			vObj.Delete();
		EndDo;
		
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Check points have been cleared';ru='Очищена старая информация о КПП';de='Check Point Informationen wurden klar'"), MessageStatus.Information); 
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
