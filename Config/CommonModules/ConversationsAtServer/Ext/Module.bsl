
#Region Public

// Function - Structure to JSON
//
// Parameters:
//  pStructure	 - Structure - Parameters to convertation
// 
// Returns:
//  String - Json string
//
Function StructureToJSON(pStructure) Export
	Return Catalogs.DataConvertationRules.MapToJSON(pStructure);
EndFunction

// Function - JSONTo structure
//
// Parameters:
//  pJSON	 - String	 - Json string
// 
// Returns:
//  Structure - Params from Json
//
Function JSONToStructure(pJSON) Export
	Return Catalogs.DataConvertationRules.JSONtoStructure(pJSON);
EndFunction

#EndRegion
