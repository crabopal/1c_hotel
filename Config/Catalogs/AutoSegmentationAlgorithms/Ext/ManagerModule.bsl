
#Region Public

// Function - Get predefined query
//
// Parameters:
//  pAlgorithms	 - CatalogRef.AutoSegmentationAlgorithms - Auto segmentation algorithms
// 
// Returns:
//  String - Text query
//
Function GetPredefinedQuery(pAlgorithms) Export
	If pAlgorithms.Predefined Then
		If pAlgorithms.PredefinedDataName = "RoomsRentedByClient" Then 
			Return "SELECT
			       |	SalesMovements.Client AS Client,
			       |	ClientTags.Tag AS Tag,
			       |	CAST(SUM(SalesMovements.RoomsRented) AS NUMBER(17, 0)) AS RoomsRented
			       |FROM
			       |	AccumulationRegister.Sales AS SalesMovements
			       |		LEFT JOIN InformationRegister.ClientTags AS ClientTags
			       |		ON SalesMovements.Client = ClientTags.Client
			       |			AND (ClientTags.Tag = &qTag)
			       |WHERE
			       |	SalesMovements.Client <> VALUE(Catalog.Clients.EmptyRef)
			       |	AND (&qSourceOfBusinessIsEmpty
			       |			OR NOT &qSourceOfBusinessIsEmpty
			       |				AND SalesMovements.SourceOfBusiness IN HIERARCHY (&qSourceOfBusiness))
			       |
			       |GROUP BY
			       |	SalesMovements.Client,
			       |	ClientTags.Tag
			       |
			       |HAVING
			       |	(CAST(SUM(SalesMovements.RoomsRented) AS NUMBER(17, 0))) >= &qRoomNightsFromInclusive AND
			       |	(CAST(SUM(SalesMovements.RoomsRented) AS NUMBER(17, 0))) < &qRoomNightsToExclusive
			       |
			       |ORDER BY
			       |	SalesMovements.Client.FullName";	
		ElsIf pAlgorithms.PredefinedDataName = "NumberOfCheckInsByClient" Then
			Return "SELECT
			       |	SalesMovements.Client AS Client,
			       |	ClientTags.Tag AS Tag,
			       |	CAST(SUM(SalesMovements.GuestsCheckedIn) AS NUMBER(17, 0)) AS GuestsCheckedIn
			       |FROM
			       |	AccumulationRegister.Sales AS SalesMovements
			       |		LEFT JOIN InformationRegister.ClientTags AS ClientTags
			       |		ON SalesMovements.Client = ClientTags.Client
			       |			AND (ClientTags.Tag = &qTag)
			       |WHERE
			       |	SalesMovements.Client <> VALUE(Catalog.Clients.EmptyRef)
			       |	AND (&qSourceOfBusinessIsEmpty
			       |			OR NOT &qSourceOfBusinessIsEmpty
			       |				AND SalesMovements.SourceOfBusiness IN HIERARCHY (&qSourceOfBusiness))
			       |
			       |GROUP BY
			       |	SalesMovements.Client,
			       |	ClientTags.Tag
			       |
			       |HAVING
			       |	(CAST(SUM(SalesMovements.GuestsCheckedIn) AS NUMBER(17, 0))) >= &qCheckInsFromInclusive AND
			       |	(CAST(SUM(SalesMovements.GuestsCheckedIn) AS NUMBER(17, 0))) < &qCheckInsToExclusive
			       |
			       |ORDER BY
			       |	SalesMovements.Client.FullName";
		ElsIf pAlgorithms.PredefinedDataName = "ByClientAddress" Then
			Return "SELECT
			       |	SalesMovements.Client AS Client,
			       |	ClientTags.Tag AS Tag
			       |FROM
			       |	AccumulationRegister.Sales AS SalesMovements
			       |		LEFT JOIN InformationRegister.ClientTags AS ClientTags
			       |		ON SalesMovements.Client = ClientTags.Client
			       |			AND (ClientTags.Tag = &qTag)
			       |WHERE
			       |	SalesMovements.Client <> VALUE(Catalog.Clients.EmptyRef)
			       |	AND (CAST(SalesMovements.Client.Address AS STRING(1000)) LIKE &qAddress
			       |				AND &qAddress <> &qEmptyString
			       |			OR (CAST(SalesMovements.Client.Address AS STRING(1000))) = &qEmptyString
			       |				AND &qAddress = &qEmptyString)
			       |	AND (&qSourceOfBusinessIsEmpty
			       |			OR NOT &qSourceOfBusinessIsEmpty
			       |				AND SalesMovements.SourceOfBusiness IN HIERARCHY (&qSourceOfBusiness))
			       |
			       |GROUP BY
			       |	SalesMovements.Client,
			       |	ClientTags.Tag
			       |
			       |ORDER BY
			       |	SalesMovements.Client.FullName";
		ElsIf pAlgorithms.PredefinedDataName = "ByClientAge" Then
			Return "SELECT
			       |	SalesMovements.Client AS Client,
			       |	ClientTags.Tag AS Tag
			       |FROM
			       |	AccumulationRegister.Sales AS SalesMovements
			       |		LEFT JOIN InformationRegister.ClientTags AS ClientTags
			       |		ON SalesMovements.Client = ClientTags.Client
			       |			AND (ClientTags.Tag = &qTag)
			       |WHERE
			       |	SalesMovements.Client <> VALUE(Catalog.Clients.EmptyRef)
			       |	AND SalesMovements.Client.DateOfBirth <> &qEmptyDate
			       |	AND SalesMovements.Client.Age >= &qAgeFrom
			       |	AND SalesMovements.Client.Age < &qAgeTo
			       |	AND (&qSourceOfBusinessIsEmpty
			       |			OR NOT &qSourceOfBusinessIsEmpty
			       |				AND SalesMovements.SourceOfBusiness IN HIERARCHY (&qSourceOfBusiness))
			       |
			       |GROUP BY
			       |	SalesMovements.Client,
			       |	ClientTags.Tag
			       |
			       |ORDER BY
			       |	SalesMovements.Client.FullName";
		EndIf;		
	EndIf;
EndFunction

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, , pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

#EndRegion 
