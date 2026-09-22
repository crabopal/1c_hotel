
#Region Public

// --------------------------------------------------------------------------------
// 
// Returns:
// Map  - Result
//
Function CodesByAuthorizationTypes() Export
	vMap = New Map();
	vMap.Insert(PredefinedValue("Enum.AuthorizationTypes.Сard"), 0);
	vMap.Insert(PredefinedValue("Enum.AuthorizationTypes.SBPQR"), 1);
	vMap.Insert(PredefinedValue("Enum.AuthorizationTypes.PayQR"), 2);
	Return vMap;
EndFunction // CodesByAuthorizationTypes

// --------------------------------------------------------------------------------
// 
// Returns:
//  Map - Result
//
Function AuthorizationTypesByCode() Export
	vMap = New Map();
	vMap.Insert(0, PredefinedValue("Enum.AuthorizationTypes.Сard"));
	vMap.Insert(1, PredefinedValue("Enum.AuthorizationTypes.SBPQR"));
	vMap.Insert(2, PredefinedValue("Enum.AuthorizationTypes.PayQR"));
	Return vMap;
EndFunction // AuthorizationTypesByCode

#EndRegion