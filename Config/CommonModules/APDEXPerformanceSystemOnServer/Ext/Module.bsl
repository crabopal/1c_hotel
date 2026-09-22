
#Region Public

// Fill session parameter APDEXRemarks
// 
// Returns:
//  String - System info in Json
//
Function GetAPDEXRemarks() Export
	
	vAPDEXRemarks = New Map;
	
	vSystemInfo = New SystemInfo();
	vAppVersion = vSystemInfo.AppVersion;
		
	vAPDEXRemarks.Insert("App", vAppVersion);
	vAPDEXRemarks.Insert("Configuration", Metadata.Synonym);
	vAPDEXRemarks.Insert("Version", Metadata.Version);
	
	vJSONWriter = New JSONWriter;
	vJSONWriter.SetString(New JSONWriterSettings(JSONLineBreak.None));
	WriteJSON(vJSONWriter, vAPDEXRemarks);
		
	Return vJSONWriter.Close();
	
EndFunction

// Return a reference to the General Performance item
// 
// Returns:
//  CatalogRef.APDEXKeyOperations - key operation
//
Function GetItemCommonPerformance() Export 
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT TOP 1
	|	APDEXKeyOperations.Ref AS Ref,
	|	2 AS Priority
	|FROM
	|	Catalog.APDEXKeyOperations AS APDEXKeyOperations
	|WHERE
	|	APDEXKeyOperations.Name = ""CommonSystemPerformance""
	|	AND NOT APDEXKeyOperations.DeletionMark
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	VALUE(Справочник.APDEXKeyOperations.EmptyRef),
	|	3
	|
	|ORDER BY
	|	Priority";
	
	If Metadata.Catalogs.APDEXKeyOperations.GetPredefinedNames().Find("CommonSystemPerformance")<>Undefined Then
		vQuery.Text = 
		"SELECT TOP 1
		|	APDEXKeyOperations.Ref AS Ref,
		|	1 AS Priority
		|FROM
		|	Catalog.APDEXKeyOperations AS APDEXKeyOperations
		|WHERE
		|	APDEXKeyOperations.PredefinedDataName = ""CommonSystemPerformance""
		|	AND NOT APDEXKeyOperations.DeletionMark
		|
		|UNION ALL
		
		|" + vQuery.Text;
	EndIf;

	vRes = vQuery.Execute();
	vSel = vRes.Select();
	vSel.Next();
	
	Return vSel.Ref;
	
EndFunction

#EndRegion