
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	// NOTHING SO FAR	
EndProcedure // ExchangePlansRecordChanges

// -------------------------------------------------------------------------
//  Get scan configuration by it's external code
//
// Parameters:
//  pExtCode - String	 - Configuration external code (dType or ID for Regula)
// 
// Returns:
//  CatalogRef.ScanConfigurations, Undefined - Scan configuration or undefined if not found
//
Function GetScanConfigurationByExternalCode(Val pExtCode) Export
	vScanConfRef = Undefined;
	If IsBlankString(pExtCode) Then
		Return vScanConfRef;
	EndIf;
	
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	ScanConfigurationsExternalNames.Ref AS Ref
	|FROM
	|	Catalog.ScanConfigurations.ExternalNames AS ScanConfigurationsExternalNames
	|WHERE
	|	ScanConfigurationsExternalNames.ExternalName = &qExtCode
	|	AND NOT ScanConfigurationsExternalNames.Ref.DeletionMark
	|
	|ORDER BY
	|	ScanConfigurationsExternalNames.Ref.SortCode,
	|	ScanConfigurationsExternalNames.Ref.Code";
	vQry.SetParameter("qExtCode", pExtCode);
	vConfs = vQry.Execute().Unload();
	If vConfs.Count() > 0 Then
		vScanConfRef = vConfs.Get(0).Ref;
	EndIf;
	
	Return vScanConfRef;
EndFunction // GetScanConfigurationByIDOrType

#EndRegion
