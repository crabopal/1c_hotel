
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - Object									 - Data
//  pReceiverNode	 - IntegrationServices.DataExchangeInterfaces	 - Data exchange interfaces
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	// NOTHING SO FAR	
EndProcedure // ExchangePlansRecordChanges

// --------------------------------------------------------------------------------
// 
// Returns:
//  Array - Remarks list
//
Function GetLastRemarks() Export
	vQuery = New Query;
	vQuery.Text = "SELECT
	               |	RemarksList.Remarks AS Remarks,
	               |	COUNT(RemarksList.Remarks) AS FrequencyUse
	               |FROM
	               |	(SELECT TOP 1000
	               |		TimeMeasurements.Remarks AS Remarks
	               |	FROM
	               |		InformationRegister.APDEXTimeMeasurements AS TimeMeasurements
	               |	
	               |	ORDER BY
	               |		TimeMeasurements.Date DESC) AS RemarksList
	               |
	               |GROUP BY
	               |	RemarksList.Remarks
	               |
	               |ORDER BY
	               |	COUNT(RemarksList.Remarks) DESC";

	vRes = vQuery.Execute();
	
	vRemarksList = New Array();
	
	vCount = 0;
	vResSel = vRes.Select();
    While vResSel.Next() Do
		vRemarksList.Add(vResSel.Remarks);
		vCount = vCount + 1;
		
		If vCount = 5 Then
			Break;
		EndIf;
	EndDo;
	
	Return vRemarksList;
EndFunction // GetLastRemarks()

#EndRegion
