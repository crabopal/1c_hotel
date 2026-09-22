#Region Public

// Function - Use APDEX
// 
// Returns:
//  Boolean - Boolean
//
Function UseAPDEX() Export 
	
	SetPrivilegedMode(True);
	Return Constants.UseAPDEX.Get();
	
EndFunction

// The function returns a reference to the key operation by name.
//
// Parameters:
//  pKeyOperationName	 - String	 - Description key operation
// 
// Returns:
//  Catalogref.APDEXKeyOperations - Key operation
//
Function GetAPDEXKeyOperationByName(pKeyOperationName) Export
	SetPrivilegedMode(True);
	vQuery = New Query;
	vQuery.Текст = "SELECT TOP 1
	               |	APDEXKeyOperations.Ref AS ref
	               |FROM
	               |	Catalog.APDEXKeyOperations AS APDEXKeyOperations
	               |WHERE
	               |	APDEXKeyOperations.Name = &qName
	               |
	               |ORDER BY
	               |	ref";
	
	vQuery.SetParameter("qName", pKeyOperationName);
	vRes = vQuery.Выполнить();
	If vRes.IsEmpty() Then
		vKeyOperationRef = APDEXPerformanceSystemFullRights.AddAPDEXKeyOperation(pKeyOperationName);
	Else
		vResRow = vRes.Select();
		vResRow.Next();
		vKeyOperationRef = vResRow.Ref;
	EndIf;
	
	Return vKeyOperationRef;
EndFunction

#EndRegion