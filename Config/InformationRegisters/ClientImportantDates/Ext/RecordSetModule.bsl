
#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel, pReplacing)
	If DataExchange.Load Then
		Return;
	EndIf;
	// Log change of client important date
	vImportantDate = '00010101';
	For Each vRcdRow In ThisObject Do
		If vRcdRow.Guest = Filter.Guest.Value Then
			vImportantDate = vRcdRow.Date;
			Break;
		EndIf;
	EndDo;
	If ValueIsFilled(Filter.Guest.Value) And ValueIsFilled(Filter.ImportantDateType.Value) Then
		vDelete = ?(ThisObject.Count() = 0, True, False);
		WriteToChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser, Filter.Guest.Value, Filter.ImportantDateType.Value, vImportantDate, vDelete);
	EndIf;
EndProcedure // OnWrite

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure WriteToChangeHistory(pPeriod, pUser, pClient, pImportantDateType, pImportantDate, pDelete)
	// Get changes description
	vCChgRec = InformationRegisters.ClientChangeHistory.CreateRecordManager();
	While FindRecord(pClient, pPeriod) Do
		pPeriod = pPeriod + 1; 	
	EndDo;
	
	vClientObj = pClient.GetObject();
	vChanges = cmGetObjectChanges(vClientObj);
	vClientObj.FillCChgAttributes(vCChgRec, pPeriod, pUser);
	vCChgRec.Changes = TrimAll(vChanges + Chars.LF + Chars.LF + ?(pDelete, NStr("en='Clearing an important date: ';ru='Очистка важной даты: ';de='Ein wichtiges Datum löschen: '") + TrimAll(pImportantDateType), NStr("en='Changing an important date: ';ru='Изменение важной даты: ';de='Ändern eines wichtigen Datums: '") + TrimAll(pImportantDateType) + ?(ValueIsFilled(pImportantDate), " = " + Format(pImportantDate, "DF=dd.MM.yyyy"), "")));
	
	// Write record
	vCChgRec.Write(False);
EndProcedure // WriteToChangeHistory

// -----------------------------------------------------------------------------
Function FindRecord(pClient, pPeriod)
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	ClientsChangeHistory.Period AS Period
	|FROM
	|	InformationRegister.ClientChangeHistory AS ClientsChangeHistory
	|WHERE
	|	ClientsChangeHistory.Period = &qPeriod
	|	AND ClientsChangeHistory.Client = &qClient";
	vQuery.SetParameter("qClient", pClient);
	vQuery.SetParameter("qPeriod", pPeriod);
	
	vQueryResult = vQuery.Execute();
	
	vSelectionDetailRecords = vQueryResult.Select();
	
	vResult = vSelectionDetailRecords.Next();	
	Return vResult; 
EndFunction // FindRecord

#EndRegion
