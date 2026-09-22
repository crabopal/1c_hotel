
#Region Public

// --------------------------------------------------------------------------------
Procedure UpdateClassifier(pTemplateName, pStartRow) Export
	vTable = Catalogs.ICD10.GetTemplate(pTemplateName);
	
	// Process categories
	For vLvl = 0 To 2 Do
		For vInt = pStartRow To 65535 Do
			vCode = TrimAll(vTable.Area(vInt, 1, vInt, 1).Text);
			vDescription = TrimAll(vTable.Area(vInt, 2, vInt, 2).Text);
			vParentCode = TrimAll(vTable.Area(vInt, 3, vInt, 3).Text);
			
			If IsBlankString(vCode) Then
				Break;
			EndIf;
			
			If vLvl = 0 And vParentCode = "NULL" Then
				vFldObj = Undefined;
				vFldRef = Catalogs.ICD10.FindByCode(vCode);
				If ValueIsFilled(vFldRef) And vFldRef.IsFolder Then
					vFldObj = vFldRef.GetObject();
				Else
					vFldObj = Catalogs.ICD10.CreateFolder();
				EndIf;
				vFldObj.Code = TrimAll(vCode); 
				vFldObj.Description = TrimAll(vDescription);
				vFldObj.Write();
			Else
				vParentRef = Catalogs.ICD10.FindByCode(vParentCode);
				If ValueIsFilled(vParentRef) Then
					vPointPos = StrFind(vCode, ".");
					If vPointPos > 0 Then
						vItemRef = Catalogs.ICD10.FindByCode(vCode);
						If ValueIsFilled(vItemRef) And Not vItemRef.IsFolder Then
							vItemObj = vItemRef.GetObject();
						Else
							vItemObj = Catalogs.ICD10.CreateItem();
						EndIf;
						vItemObj.Code = TrimAll(vCode); 
						vItemObj.Description = TrimAll(vDescription);
						vItemObj.Parent = vParentRef;
						vItemObj.Write();
					Else
						vFldRef = Catalogs.ICD10.FindByCode(vCode);
						If ValueIsFilled(vFldRef) And vFldRef.IsFolder Then
							vFldObj = vFldRef.GetObject();
						Else
							vFldObj = Catalogs.ICD10.CreateFolder();
						EndIf;
						vFldObj.Code = TrimAll(vCode); 
						vFldObj.Description = TrimAll(vDescription);
						vFldObj.Parent = vParentRef;
						vFldObj.Write();
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndDo;	
EndProcedure //UpdateClassifier

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
