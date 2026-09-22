#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pHotel			 - CatalogRef.Hotels - Hotel
//  pThisNode		 - ExchangePlanRef	 - The this node
//  pIsUnloadArray	 - Boolean			 - Unload to array
// 
// Returns:
//  QueryResultSelection - Exchange plan nodes list
//
Function GetExchangePlanNodes(pHotel = Undefined, pThisNode = Undefined) Export
	If TypeOf(pHotel) = Type("CatalogObject.Hotels") Then
		Return CachedCommonFunctions.cmGetExchangePlanNodesForReplicationExchangePlan(pHotel.Ref, pThisNode); 
	ElsIf TypeOf(pHotel) = Type("FilterItem") Then
		Return CachedCommonFunctions.cmGetExchangePlanNodesForCentralOfficeExchangePlan(pHotel.Value, pThisNode);
	Else
		Return CachedCommonFunctions.cmGetExchangePlanNodesForReplicationExchangePlan(pHotel, pThisNode); 
	EndIf;
EndFunction // GetExchangePlanNodes

// --------------------------------------------------------------------------------
//
// Parameters:
//  pMetadata	 - MetadataObject	 - Metadata
// 
// Returns:
//  Boolean - Result
//
Function CheckContainsInContent(pMetadata) Export 
	Return Metadata.ExchangePlans.ReplicationExchangePlan.Content.Contains(pMetadata);	
EndFunction // CheckContainsInContent

#EndRegion

