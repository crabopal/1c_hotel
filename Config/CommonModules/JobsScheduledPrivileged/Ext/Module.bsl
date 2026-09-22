
#Region Public

// -----------------------------------------------------------------------------
Procedure cmUpdateHistory() Export
	DataHistory.UpdateHistory();
EndProcedure // cmUpdateHistory

// -----------------------------------------------------------------------------
Procedure cmRefreshFullTextSearchIndex() Export
	If FullTextSearch.GetFullTextSearchMode() = FullTextSearchMode.Enable Then
		If Not FullTextSearch.IndexTrue() Then
			FullTextSearch.UpdateIndex(False, True);
		EndIf;
	EndIf;
EndProcedure // cmRefreshFullTextSearchIndex

// -----------------------------------------------------------------------------
Procedure cmJoinFullTextSearchIndexes() Export
	If FullTextSearch.GetFullTextSearchMode() = FullTextSearchMode.Enable Then
		If Not FullTextSearch.IndexUpdateComplete() Then
			FullTextSearch.UpdateIndex(True, False);
		EndIf;
	EndIf;
EndProcedure // cmJoinFullTextSearchIndexes

#EndRegion
