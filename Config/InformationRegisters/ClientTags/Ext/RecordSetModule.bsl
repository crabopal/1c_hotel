
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel, pReplacing)
	If DataExchange.Load Then
		Return;
	EndIf;
	// Update clients tag presentations
	vClients = New ValueList();
	Try
		If ValueIsFilled(Filter.Client.Value) Then
			vClients.Add(Filter.Client.Value);
		EndIf;
	Except
	EndTry;
	For Each vRcdRow In ThisObject Do
		If vClients.FindByValue(vRcdRow.Client) = Undefined Then
			vClients.Add(vRcdRow.Client);
		EndIf;
	EndDo;
	For Each vClientItem In vClients Do
		cmFillClientTagsPresentation(vClientItem.Value);
		If ValueIsFilled(vClientItem.Value) And ValueIsFilled(Filter.Tag.Value) Then
			vDelete = False;
			If ThisObject.Count() = 0 Then
				vDelete = True;
			EndIf; 
			WriteToChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser, vClientItem.Value, Filter.Tag.Value, vDelete);
		EndIf;
	EndDo;
EndProcedure // OnWrite

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure WriteToChangeHistory(pPeriod, pUser, pClient, pTag, pDelete)
	// Get changes description
	If TypeOf(pClient) = Type("CatalogRef.Clients") Then
		vCChgRec = InformationRegisters.ClientChangeHistory.CreateRecordManager();
	ElsIf TypeOf(pClient) = Type("CatalogRef.Customers") Then
		vCChgRec = InformationRegisters.CustomerChangeHistory.CreateRecordManager();
	Else
		Return;
	EndIf;
	
	While FindRecord(pClient, pPeriod) Do
		pPeriod = pPeriod + 1; 	
	EndDo;
	
	vClientObj = pClient.GetObject();
	vChanges = cmGetObjectChanges(vClientObj);
	vClientObj.FillCChgAttributes(vCChgRec, pPeriod, pUser);    
	vMsg = NStr("en = 'Deleting a tag: '; de = 'Das Entfernen der tag: '; ru = 'Удаление тега: '") + pTag;
	If pDelete = False Then
		vMsg = NStr("en = 'Adding a tag: '; de = 'Hinzufügen eines tag: '; ru = 'Добавление тега: '") + pTag;
	EndIf;
	vCChgRec.Changes = TrimAll(vChanges + Chars.LF + Chars.LF + vMsg);
	
	// Write record
	vCChgRec.Write(False);
EndProcedure // WriteToChangeHistory

// -----------------------------------------------------------------------------
//
// Parameters:
//  pClient	 - CtalogRef.Clients - Ref
//  pPeriod	 - Date	 - date
// 
// Returns:
//  QueryResult - data
//
Function FindRecord(pClient, pPeriod)
	vQuery = New Query;
	If TypeOf(pClient) = Type("CatalogRef.Clients") Then
		vQuery.Text = 
		"SELECT
		|	ClientsChangeHistory.Period AS Period
		|FROM
		|	InformationRegister.ClientChangeHistory AS ClientsChangeHistory
		|WHERE
		|	ClientsChangeHistory.Period = &qPeriod
		|	AND ClientsChangeHistory.Client = &qRef";
	ElsIf TypeOf(pClient) = Type("CatalogRef.Customers") Then
		vQuery.Text = 
		"SELECT
		|	CustomersChangeHistory.Period AS Period
		|FROM
		|	InformationRegister.CustomerChangeHistory AS CustomersChangeHistory
		|WHERE
		|	CustomersChangeHistory.Period = &qPeriod
		|	AND CustomersChangeHistory.Customer = &qRef";
	Else
		Return False;
	EndIf;
	vQuery.SetParameter("qRef", pClient);
	vQuery.SetParameter("qPeriod", pPeriod);
	
	vQueryResult = vQuery.Execute();
	
	vSelectionDetailRecords = vQueryResult.Select();
	
	vResult = vSelectionDetailRecords.Next();	
	Return vResult; 
EndFunction // FindRecord

#EndRegion
