
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Hotel, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

// -----------------------------------------------------------------------------
//  Get operation standards for the specified hotel, room and room type
//  -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel		 - CatalogRef.Hotels - Ref
//  pRoomType	 - CatalogRef.Roo,Types	 - Ref
//  pRoom		 - CatalogRef.Rooms	 - Ref
// 
// Returns:
//  ValyeTable - List operations
//
Function GetOperationStandards(Val pOperation, pHotel = Undefined, pRoomType = Undefined, pRoom = Undefined, pEmployee = Undefined) Export
	// Initialize resulting value table
	vStds = New ValueTable();
	
	// Fill parameter default values 
	vHotel = pHotel;
	If Not ValueIsFilled(vHotel) Then
		vHotel = SessionParameters.CurrentHotel;
	EndIf;
	
	// Build and run query to get data for the room
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	AllOperationStandards.Operation AS Operation,
	|	AllOperationStandards.Employee AS Employee,
	|	AllOperationStandards.Priority AS Priority,
	|	AllOperationStandards.Duration AS Duration,
	|	AllOperationStandards.RoomSpace AS RoomSpace,
	|	AllOperationStandards.Price AS Price
	|INTO AllOperationStandards
	|FROM
	|	(SELECT
	|		OperationStandards.Operation AS Operation,
	|		OperationStandards.Employee AS Employee,
	|		1 AS Priority,
	|		SUM(OperationStandards.Duration) AS Duration,
	|		SUM(OperationStandards.RoomSpace) AS RoomSpace,
	|		SUM(OperationStandards.Price) AS Price
	|	FROM
	|		InformationRegister.OperationStandards AS OperationStandards
	|	WHERE
	|		OperationStandards.Operation = &qOperation
	|		AND OperationStandards.Hotel = &qHotel
	|		AND OperationStandards.Room = &qRoom
	|		AND OperationStandards.Room <> VALUE(Catalog.Rooms.EmptyRef)
	|		AND OperationStandards.Hotel <> VALUE(Catalog.Hotels.EmptyRef)
	|	
	|	GROUP BY
	|		OperationStandards.Operation,
	|		OperationStandards.Employee
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		OperationStandards.Operation,
	|		OperationStandards.Employee,
	|		2,
	|		SUM(OperationStandards.Duration),
	|		SUM(OperationStandards.RoomSpace),
	|		SUM(OperationStandards.Price)
	|	FROM
	|		InformationRegister.OperationStandards AS OperationStandards
	|	WHERE
	|		OperationStandards.Operation = &qOperation
	|		AND OperationStandards.Hotel = &qHotel
	|		AND OperationStandards.RoomType = &qRoomType
	|		AND OperationStandards.Room = VALUE(Catalog.Rooms.EmptyRef)
	|		AND OperationStandards.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|		AND OperationStandards.Hotel <> VALUE(Catalog.Hotels.EmptyRef)
	|	
	|	GROUP BY
	|		OperationStandards.Operation,
	|		OperationStandards.Employee
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		OperationStandards.Operation,
	|		OperationStandards.Employee,
	|		3,
	|		SUM(OperationStandards.Duration),
	|		SUM(OperationStandards.RoomSpace),
	|		SUM(OperationStandards.Price)
	|	FROM
	|		InformationRegister.OperationStandards AS OperationStandards
	|	WHERE
	|		OperationStandards.Operation = &qOperation
	|		AND OperationStandards.Hotel = &qHotel
	|		AND OperationStandards.RoomType = VALUE(Catalog.RoomTypes.EmptyRef)
	|		AND OperationStandards.Room = VALUE(Catalog.Rooms.EmptyRef)
	|	
	|	GROUP BY
	|		OperationStandards.Operation,
	|		OperationStandards.Employee
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		OperationStandards.Operation,
	|		OperationStandards.Employee,
	|		4,
	|		SUM(OperationStandards.Duration),
	|		SUM(OperationStandards.RoomSpace),
	|		SUM(OperationStandards.Price)
	|	FROM
	|		InformationRegister.OperationStandards AS OperationStandards
	|	WHERE
	|		OperationStandards.Operation = &qOperation
	|		AND OperationStandards.Hotel = VALUE(Catalog.Hotels.EmptyRef)
	|		AND OperationStandards.RoomType = VALUE(Catalog.RoomTypes.EmptyRef)
	|		AND OperationStandards.Room = VALUE(Catalog.Rooms.EmptyRef)
	|	
	|	GROUP BY
	|		OperationStandards.Operation,
	|		OperationStandards.Employee) AS AllOperationStandards
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OperationStandardsByPriority.Operation AS Operation,
	|	OperationStandardsByPriority.Employee AS Employee,
	|	MIN(OperationStandardsByPriority.Priority) AS Priority
	|INTO OperationStandardsByPriority
	|FROM
	|	AllOperationStandards AS OperationStandardsByPriority
	|
	|GROUP BY
	|	OperationStandardsByPriority.Operation,
	|	OperationStandardsByPriority.Employee
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OperationStandards.Operation AS Operation,
	|	OperationStandards.Employee AS Employee,
	|	OperationStandards.Priority AS Priority,
	|	OperationStandards.Duration AS Duration,
	|	OperationStandards.RoomSpace AS RoomSpace,
	|	OperationStandards.Price AS Price
	|FROM
	|	AllOperationStandards AS OperationStandards
	|		INNER JOIN OperationStandardsByPriority AS OperationStandardsByPriority
	|		ON OperationStandards.Operation = OperationStandardsByPriority.Operation
	|			AND OperationStandards.Employee = OperationStandardsByPriority.Employee
	|			AND OperationStandards.Priority = OperationStandardsByPriority.Priority";
	vQry.SetParameter("qOperation", pOperation);
	vQry.SetParameter("qRoomType", pRoomType);
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qHotel", vHotel);
	vStds = vQry.Execute().Unload();
	
	If ValueIsFilled(pEmployee) Then
		vStdsByEmployee = vStds.FindRows(New Structure("Employee", pEmployee));
		If vStdsByEmployee.Count() > 0 Then
			i = 0;
			While i < vStds.Count() Do
				vStdsRow = vStds.Get(i);
				If vStdsRow.Employee = pEmployee Then
					i = i + 1;
				Else
					vStds.Delete(i);
				EndIf;
			EndDo;
		ElsIf ValueIsFilled(pEmployee.Parent) Then
			vStdsByEmployeeParent = vStds.FindRows(New Structure("Employee", pEmployee.Parent));
			If vStdsByEmployeeParent.Count() > 0 Then
				i = 0;
				While i < vStds.Count() Do
					vStdsRow = vStds.Get(i);
					If vStdsRow.Employee = pEmployee.Parent Then
						i = i + 1;
					Else
						vStds.Delete(i);
					EndIf;
				EndDo;
			Else
				i = 0;
				While i < vStds.Count() Do
					vStdsRow = vStds.Get(i);
					If ValueIsFilled(vStdsRow.Employee) Then
						vStds.Delete(i);
					Else
						i = i + 1;
					EndIf;
				EndDo;
			EndIf;
		Else
			i = 0;
			While i < vStds.Count() Do
				vStdsRow = vStds.Get(i);
				If ValueIsFilled(vStdsRow.Employee) Then
					vStds.Delete(i);
				Else
					i = i + 1;
				EndIf;
			EndDo;
		EndIf;
	Else
		i = 0;
		While i < vStds.Count() Do
			vStdsRow = vStds.Get(i);
			If ValueIsFilled(vStdsRow.Employee) Then
				vStds.Delete(i);
			Else
				i = i + 1;
			EndIf;
		EndDo;
	EndIf;
	
	Return vStds;
EndFunction // GetOperationStandards

#EndRegion
