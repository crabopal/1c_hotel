
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	For Each vSrvRow In Services Do
		If Not ValueIsFilled(vSrvRow.Period) Then
			vSrvRow.Period = '20000101';
		EndIf;
	EndDo;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
// Write to the service package records register
// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;	
	
	// Build value table with services
	vServices = Services.Unload();
	vServices.Clear();
	For Each vSrvRow In Services Do
		vClientTypes = GetClientTypesList(vSrvRow.ClientType, Hotel);
		vAccommodationTypes = GetAccommodationTypesList(vSrvRow.AccommodationType, vSrvRow.AccommodationTypeExcluding, Hotel, vSrvRow.Service);
		vRoomTypes = GetRoomTypesList(vSrvRow.RoomClass, vSrvRow.RoomClassExcluding, vSrvRow.RoomType, vSrvRow.RoomTypeExcluding, Hotel);
		For Each vClientTypesItem In vClientTypes Do
			For Each vRoomTypesItem In vRoomTypes Do
				For Each vAccommodationTypesItem In vAccommodationTypes Do
					// Cycle by day types
					vDayTypes = GetDayTypesList(vSrvRow.CalendarDayType, Hotel);
					For Each vDayTypesItem In vDayTypes Do
						vRow = vServices.Add();
						FillPropertyValues(vRow, vSrvRow);
						vRow.ClientType = vClientTypesItem.Value;
						vRow.RoomType = vRoomTypesItem.Value;
						vRow.AccommodationType = vAccommodationTypesItem.Value;
						vRow.CalendarDayType = vDayTypesItem.Value;
					EndDo;
				EndDo;
			EndDo;
		EndDo;
	EndDo;
	// Write value table with services to the information register
	vRcdSet = InformationRegisters.ServicePackageRecords.CreateRecordSet();
	vServicePackageFlt = vRcdSet.Filter.ServicePackage;
	vServicePackageFlt.ComparisonType = ComparisonType.Equal;
	vServicePackageFlt.Value = Ref;
	vServicePackageFlt.Use = True;
	For Each vSrvRow In vServices Do
		vRcdSetRow = vRcdSet.Add();
		vRcdSetRow.ServicePackage = Ref;
		FillPropertyValues(vRcdSetRow, vSrvRow);
		vRcdSetRow.RowNumber = vServices.IndexOf(vSrvRow) + 1;
	EndDo;
	vRcdSet.Write(True);  
EndProcedure // OnWrite

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetClientTypesList(pClientType, pHotel)
	vClientTypesList = New ValueList();
	If Not ValueIsFilled(pClientType) Then
		vClientTypesList.Add(Catalogs.ClientTypes.EmptyRef());
	Else
		If pClientType.IsFolder Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	ClientTypes.Ref AS Ref
			|FROM
			|	Catalog.ClientTypes AS ClientTypes
			|WHERE
			|	NOT ClientTypes.DeletionMark
			|	AND NOT ClientTypes.IsFolder
			|	AND (&qHotelIsEmpty
			|			OR NOT &qHotelIsEmpty
			|				AND (ClientTypes.Hotel = &qHotel
			|					OR ClientTypes.Hotel = &qEmptyHotel))
			|	AND ClientTypes.Ref IN HIERARCHY(&qClientType)
			|
			|ORDER BY
			|	ClientTypes.SortCode,
			|	ClientTypes.Description";
			vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(pHotel));
			vQry.SetParameter("qHotel", pHotel);
			vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
			vQry.SetParameter("qClientType", pClientType);
			vQryRes = vQry.Execute().Unload();
			If vQryRes.Count() > 0 Then
				vClientTypesList.LoadValues(vQryRes.UnloadColumn("Ref"));
			EndIf;
		Else
			vClientTypesList.Add(pClientType);
		EndIf;
	EndIf;
	Return vClientTypesList;
EndFunction // GetClientTypesList

// -----------------------------------------------------------------------------
Function GetAccommodationTypesList(pAccommodationType, pExcludingAccommodationType = Undefined, pHotel, pService)
	vAccommodationTypesList = New ValueList();
	If Not ValueIsFilled(pAccommodationType) And Not ValueIsFilled(pExcludingAccommodationType) And ValueIsFilled(pService) And Not pService.IsRoomRevenue Then
		vAccommodationTypesList.Add(Catalogs.AccommodationTypes.EmptyRef());
		Return vAccommodationTypesList;
	EndIf;
	vQry = New Query();
	If ValueIsFilled(pAccommodationType) And pAccommodationType.IsFolder And Not ValueIsFilled(pExcludingAccommodationType) Then
		vQry.Text = 
		"SELECT
		|	AccommodationTypes.Ref AS Ref
		|FROM
		|	Catalog.AccommodationTypes AS AccommodationTypes
		|WHERE
		|	NOT AccommodationTypes.DeletionMark
		|	AND NOT AccommodationTypes.IsFolder
		|	AND (&qHotelIsEmpty
		|			OR NOT &qHotelIsEmpty
		|				AND (AccommodationTypes.Hotel = &qHotel
		|					OR AccommodationTypes.Hotel = &qEmptyHotel))
		|	AND AccommodationTypes.Ref IN HIERARCHY(&qAccommodationType)
		|
		|ORDER BY
		|	AccommodationTypes.SortCode,
		|	AccommodationTypes.Description";
	ElsIf ValueIsFilled(pAccommodationType) And Not pAccommodationType.IsFolder And Not ValueIsFilled(pExcludingAccommodationType) Then
		vQry.Text = 
		"SELECT
		|	AccommodationTypes.Ref AS Ref
		|FROM
		|	Catalog.AccommodationTypes AS AccommodationTypes
		|WHERE
		|	NOT AccommodationTypes.DeletionMark
		|	AND NOT AccommodationTypes.IsFolder
		|	AND (&qHotelIsEmpty
		|			OR NOT &qHotelIsEmpty
		|				AND (AccommodationTypes.Hotel = &qHotel
		|					OR AccommodationTypes.Hotel = &qEmptyHotel))
		|	AND AccommodationTypes.Ref = &qAccommodationType
		|
		|ORDER BY
		|	AccommodationTypes.SortCode,
		|	AccommodationTypes.Description";
	ElsIf ValueIsFilled(pAccommodationType) And pAccommodationType.IsFolder And ValueIsFilled(pExcludingAccommodationType) And Not pExcludingAccommodationType.IsFolder Then
		vQry.Text = 
		"SELECT
		|	AccommodationTypes.Ref AS Ref
		|FROM
		|	Catalog.AccommodationTypes AS AccommodationTypes
		|WHERE
		|	NOT AccommodationTypes.DeletionMark
		|	AND NOT AccommodationTypes.IsFolder
		|	AND (&qHotelIsEmpty
		|			OR NOT &qHotelIsEmpty
		|				AND (AccommodationTypes.Hotel = &qHotel
		|					OR AccommodationTypes.Hotel = &qEmptyHotel))
		|	AND AccommodationTypes.Ref IN HIERARCHY(&qAccommodationType)
		|	AND AccommodationTypes.Ref <> &qExcludingAccommodationType
		|
		|ORDER BY
		|	AccommodationTypes.SortCode,
		|	AccommodationTypes.Description";
	ElsIf ValueIsFilled(pAccommodationType) And pAccommodationType.IsFolder And ValueIsFilled(pExcludingAccommodationType) And pExcludingAccommodationType.IsFolder Then
		vQry.Text = 
		"SELECT
		|	AccommodationTypes.Ref AS Ref
		|FROM
		|	Catalog.AccommodationTypes AS AccommodationTypes
		|WHERE
		|	NOT AccommodationTypes.DeletionMark
		|	AND NOT AccommodationTypes.IsFolder
		|	AND (&qHotelIsEmpty
		|			OR NOT &qHotelIsEmpty
		|				AND (AccommodationTypes.Hotel = &qHotel
		|					OR AccommodationTypes.Hotel = &qEmptyHotel))
		|	AND AccommodationTypes.Ref IN HIERARCHY(&qAccommodationType)
		|	AND NOT AccommodationTypes.Ref IN HIERARCHY (&qExcludingAccommodationType)
		|
		|ORDER BY
		|	AccommodationTypes.SortCode,
		|	AccommodationTypes.Description";
	ElsIf ValueIsFilled(pAccommodationType) And Not pAccommodationType.IsFolder And ValueIsFilled(pExcludingAccommodationType) And pExcludingAccommodationType.IsFolder Then
		vQry.Text = 
		"SELECT
		|	AccommodationTypes.Ref AS Ref
		|FROM
		|	Catalog.AccommodationTypes AS AccommodationTypes
		|WHERE
		|	NOT AccommodationTypes.DeletionMark
		|	AND NOT AccommodationTypes.IsFolder
		|	AND (&qHotelIsEmpty
		|			OR NOT &qHotelIsEmpty
		|				AND (AccommodationTypes.Hotel = &qHotel
		|					OR AccommodationTypes.Hotel = &qEmptyHotel))
		|	AND AccommodationTypes.Ref = &qAccommodationType
		|	AND NOT AccommodationTypes.Ref IN HIERARCHY (&qExcludingAccommodationType)
		|
		|ORDER BY
		|	AccommodationTypes.SortCode,
		|	AccommodationTypes.Description";
	ElsIf ValueIsFilled(pAccommodationType) And Not pAccommodationType.IsFolder And ValueIsFilled(pExcludingAccommodationType) And Not pExcludingAccommodationType.IsFolder Then
		vQry.Text = 
		"SELECT
		|	AccommodationTypes.Ref AS Ref
		|FROM
		|	Catalog.AccommodationTypes AS AccommodationTypes
		|WHERE
		|	NOT AccommodationTypes.DeletionMark
		|	AND NOT AccommodationTypes.IsFolder
		|	AND (&qHotelIsEmpty
		|			OR NOT &qHotelIsEmpty
		|				AND (AccommodationTypes.Hotel = &qHotel
		|					OR AccommodationTypes.Hotel = &qEmptyHotel))
		|	AND AccommodationTypes.Ref = &qAccommodationType
		|	AND AccommodationTypes.Ref <> &qExcludingAccommodationType
		|
		|ORDER BY
		|	AccommodationTypes.SortCode,
		|	AccommodationTypes.Description";
	ElsIf Not ValueIsFilled(pAccommodationType) And ValueIsFilled(pExcludingAccommodationType) And pExcludingAccommodationType.IsFolder Then
		vQry.Text = 
		"SELECT
		|	AccommodationTypes.Ref AS Ref
		|FROM
		|	Catalog.AccommodationTypes AS AccommodationTypes
		|WHERE
		|	NOT AccommodationTypes.DeletionMark
		|	AND NOT AccommodationTypes.IsFolder
		|	AND (&qHotelIsEmpty
		|			OR NOT &qHotelIsEmpty
		|				AND (AccommodationTypes.Hotel = &qHotel
		|					OR AccommodationTypes.Hotel = &qEmptyHotel))
		|	AND NOT AccommodationTypes.Ref IN HIERARCHY (&qExcludingAccommodationType)
		|
		|ORDER BY
		|	AccommodationTypes.SortCode,
		|	AccommodationTypes.Description";
	ElsIf Not ValueIsFilled(pAccommodationType) And ValueIsFilled(pExcludingAccommodationType) And Not pExcludingAccommodationType.IsFolder Then
		vQry.Text = 
		"SELECT
		|	AccommodationTypes.Ref AS Ref
		|FROM
		|	Catalog.AccommodationTypes AS AccommodationTypes
		|WHERE
		|	NOT AccommodationTypes.DeletionMark
		|	AND NOT AccommodationTypes.IsFolder
		|	AND (&qHotelIsEmpty
		|			OR NOT &qHotelIsEmpty
		|				AND (AccommodationTypes.Hotel = &qHotel
		|					OR AccommodationTypes.Hotel = &qEmptyHotel))
		|	AND AccommodationTypes.Ref <> &qExcludingAccommodationType
		|
		|ORDER BY
		|	AccommodationTypes.SortCode,
		|	AccommodationTypes.Description";
	ElsIf Not ValueIsFilled(pAccommodationType) And Not ValueIsFilled(pExcludingAccommodationType) Then
		vQry.Text = 
		"SELECT
		|	AccommodationTypes.Ref AS Ref
		|FROM
		|	Catalog.AccommodationTypes AS AccommodationTypes
		|WHERE
		|	NOT AccommodationTypes.DeletionMark
		|	AND NOT AccommodationTypes.IsFolder
		|	AND (&qHotelIsEmpty
		|			OR NOT &qHotelIsEmpty
		|				AND (AccommodationTypes.Hotel = &qHotel
		|					OR AccommodationTypes.Hotel = &qEmptyHotel))
		|
		|ORDER BY
		|	AccommodationTypes.SortCode,
		|	AccommodationTypes.Description";
	EndIf;
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(pHotel));
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qAccommodationType", pAccommodationType);
	vQry.SetParameter("qExcludingAccommodationType", pExcludingAccommodationType);
	vQryRes = vQry.Execute().Unload();
	If vQryRes.Count() > 0 Then
		vAccommodationTypesList.LoadValues(vQryRes.UnloadColumn("Ref"));
	EndIf;
	Return vAccommodationTypesList;
EndFunction // GetAccommodationTypesList

// -----------------------------------------------------------------------------
Function GetDayTypesList(pDayType, pHotel)
	vDayTypesList = New ValueList();
	If Not ValueIsFilled(pDayType) Then
		vDayTypesList.Add(Catalogs.CalendarDayTypes.EmptyRef());
	Else
		If pDayType.IsFolder Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	DayTypes.Ref AS Ref
			|FROM
			|	Catalog.CalendarDayTypes AS DayTypes
			|WHERE
			|	NOT DayTypes.DeletionMark
			|	AND NOT DayTypes.IsFolder
			|	AND (&qHotelIsEmpty
			|			OR NOT &qHotelIsEmpty
			|				AND (DayTypes.Hotel = &qHotel
			|					OR DayTypes.Hotel = &qEmptyHotel))
			|	AND DayTypes.Ref IN HIERARCHY(&qDayType)
			|
			|ORDER BY
			|	DayTypes.SortCode,
			|	DayTypes.Description";
			vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(pHotel));
			vQry.SetParameter("qHotel", pHotel);
			vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
			vQry.SetParameter("qDayType", pDayType);
			vQryRes = vQry.Execute().Unload();
			If vQryRes.Count() > 0 Then
				vDayTypesList.LoadValues(vQryRes.UnloadColumn("Ref"));
			EndIf;
		Else
			vDayTypesList.Add(pDayType);
		EndIf;
	EndIf;
	Return vDayTypesList;
EndFunction // GetDayTypesList

// -----------------------------------------------------------------------------
Function GetRoomTypesList(pRoomClass, pExcludingRoomClass = Undefined, pRoomType, pExcludingRoomType = Undefined, pHotel)
	vRoomTypesList = New ValueList();
	If Not ValueIsFilled(pRoomType) And Not ValueIsFilled(pExcludingRoomType) Then
		vRoomTypesList.Add(Catalogs.RoomTypes.EmptyRef());
		Return vRoomTypesList;
	EndIf;
	vQry = New Query();
	If ValueIsFilled(pRoomType) And pRoomType.IsFolder And Not ValueIsFilled(pExcludingRoomType) Then
		vQry.Text = 
		"SELECT
		|	RoomTypes.Ref AS Ref
		|FROM
		|	Catalog.RoomTypes AS RoomTypes
		|WHERE
		|	NOT RoomTypes.DeletionMark
		|	AND NOT RoomTypes.IsFolder
		|	AND (&qHotelIsEmpty
		|			OR NOT &qHotelIsEmpty
		|				AND RoomTypes.Owner = &qHotel)
		|	AND RoomTypes.Ref IN HIERARCHY(&qRoomType)
		|	AND (&qRoomClassIsEmpty
		|			OR NOT &qRoomClassIsEmpty
		|				AND RoomTypes.RoomClass = &qRoomClass)
		|	AND (&qExcludingRoomClassIsEmpty
		|			OR NOT &qExcludingRoomClassIsEmpty
		|				AND RoomTypes.RoomClass <> &qExcludingRoomClass)
		|
		|ORDER BY
		|	RoomTypes.SortCode,
		|	RoomTypes.Description";
	ElsIf ValueIsFilled(pRoomType) And Not pRoomType.IsFolder And Not ValueIsFilled(pExcludingRoomType) Then
		vQry.Text = 
		"SELECT
		|	RoomTypes.Ref AS Ref
		|FROM
		|	Catalog.RoomTypes AS RoomTypes
		|WHERE
		|	NOT RoomTypes.DeletionMark
		|	AND NOT RoomTypes.IsFolder
		|	AND (&qHotelIsEmpty
		|			OR NOT &qHotelIsEmpty
		|				AND RoomTypes.Owner = &qHotel)
		|	AND RoomTypes.Ref = &qRoomType
		|	AND (&qRoomClassIsEmpty
		|			OR NOT &qRoomClassIsEmpty
		|				AND RoomTypes.RoomClass = &qRoomClass)
		|	AND (&qExcludingRoomClassIsEmpty
		|			OR NOT &qExcludingRoomClassIsEmpty
		|				AND RoomTypes.RoomClass <> &qExcludingRoomClass)
		|
		|ORDER BY
		|	RoomTypes.SortCode,
		|	RoomTypes.Description";
	ElsIf ValueIsFilled(pRoomType) And pRoomType.IsFolder And ValueIsFilled(pExcludingRoomType) And pExcludingRoomType.IsFolder Then
		vQry.Text = 
		"SELECT
		|	RoomTypes.Ref AS Ref
		|FROM
		|	Catalog.RoomTypes AS RoomTypes
		|WHERE
		|	NOT RoomTypes.DeletionMark
		|	AND NOT RoomTypes.IsFolder
		|	AND (&qHotelIsEmpty
		|			OR NOT &qHotelIsEmpty
		|				AND RoomTypes.Owner = &qHotel)
		|	AND RoomTypes.Ref IN HIERARCHY(&qRoomType)
		|	AND NOT RoomTypes.Ref IN HIERARCHY (&qExcludingRoomType)
		|	AND (&qRoomClassIsEmpty
		|			OR NOT &qRoomClassIsEmpty
		|				AND RoomTypes.RoomClass = &qRoomClass)
		|	AND (&qExcludingRoomClassIsEmpty
		|			OR NOT &qExcludingRoomClassIsEmpty
		|				AND RoomTypes.RoomClass <> &qExcludingRoomClass)
		|
		|ORDER BY
		|	RoomTypes.SortCode,
		|	RoomTypes.Description";
	ElsIf ValueIsFilled(pRoomType) And pRoomType.IsFolder And ValueIsFilled(pExcludingRoomType) And Not pExcludingRoomType.IsFolder Then
		vQry.Text = 
		"SELECT
		|	RoomTypes.Ref AS Ref
		|FROM
		|	Catalog.RoomTypes AS RoomTypes
		|WHERE
		|	NOT RoomTypes.DeletionMark
		|	AND NOT RoomTypes.IsFolder
		|	AND (&qHotelIsEmpty
		|			OR NOT &qHotelIsEmpty
		|				AND RoomTypes.Owner = &qHotel)
		|	AND RoomTypes.Ref IN HIERARCHY(&qRoomType)
		|	AND RoomTypes.Ref <> &qExcludingRoomType
		|	AND (&qRoomClassIsEmpty
		|			OR NOT &qRoomClassIsEmpty
		|				AND RoomTypes.RoomClass = &qRoomClass)
		|	AND (&qExcludingRoomClassIsEmpty
		|			OR NOT &qExcludingRoomClassIsEmpty
		|				AND RoomTypes.RoomClass <> &qExcludingRoomClass)
		|
		|ORDER BY
		|	RoomTypes.SortCode,
		|	RoomTypes.Description";
	ElsIf ValueIsFilled(pRoomType) And Not pRoomType.IsFolder And ValueIsFilled(pExcludingRoomType) And pExcludingRoomType.IsFolder Then
		vQry.Text = 
		"SELECT
		|	RoomTypes.Ref AS Ref
		|FROM
		|	Catalog.RoomTypes AS RoomTypes
		|WHERE
		|	NOT RoomTypes.DeletionMark
		|	AND NOT RoomTypes.IsFolder
		|	AND (&qHotelIsEmpty
		|			OR NOT &qHotelIsEmpty
		|				AND RoomTypes.Owner = &qHotel)
		|	AND RoomTypes.Ref = &qRoomType
		|	AND NOT RoomTypes.Ref IN HIERARCHY (&qExcludingRoomType)
		|	AND (&qRoomClassIsEmpty
		|			OR NOT &qRoomClassIsEmpty
		|				AND RoomTypes.RoomClass = &qRoomClass)
		|	AND (&qExcludingRoomClassIsEmpty
		|			OR NOT &qExcludingRoomClassIsEmpty
		|				AND RoomTypes.RoomClass <> &qExcludingRoomClass)
		|
		|ORDER BY
		|	RoomTypes.SortCode,
		|	RoomTypes.Description";
	ElsIf ValueIsFilled(pRoomType) And Not pRoomType.IsFolder And ValueIsFilled(pExcludingRoomType) And Not pExcludingRoomType.IsFolder Then
		vQry.Text = 
		"SELECT
		|	RoomTypes.Ref AS Ref
		|FROM
		|	Catalog.RoomTypes AS RoomTypes
		|WHERE
		|	NOT RoomTypes.DeletionMark
		|	AND NOT RoomTypes.IsFolder
		|	AND (&qHotelIsEmpty
		|			OR NOT &qHotelIsEmpty
		|				AND RoomTypes.Owner = &qHotel)
		|	AND RoomTypes.Ref = &qRoomType
		|	AND RoomTypes.Ref <> &qExcludingRoomType
		|	AND (&qRoomClassIsEmpty
		|			OR NOT &qRoomClassIsEmpty
		|				AND RoomTypes.RoomClass = &qRoomClass)
		|	AND (&qExcludingRoomClassIsEmpty
		|			OR NOT &qExcludingRoomClassIsEmpty
		|				AND RoomTypes.RoomClass <> &qExcludingRoomClass)
		|
		|ORDER BY
		|	RoomTypes.SortCode,
		|	RoomTypes.Description";
	ElsIf Not ValueIsFilled(pRoomType) And ValueIsFilled(pExcludingRoomType) And pExcludingRoomType.IsFolder Then
		vQry.Text = 
		"SELECT
		|	RoomTypes.Ref AS Ref
		|FROM
		|	Catalog.RoomTypes AS RoomTypes
		|WHERE
		|	NOT RoomTypes.DeletionMark
		|	AND NOT RoomTypes.IsFolder
		|	AND (&qHotelIsEmpty
		|			OR NOT &qHotelIsEmpty
		|				AND RoomTypes.Owner = &qHotel)
		|	AND NOT RoomTypes.Ref IN HIERARCHY (&qExcludingRoomType)
		|	AND (&qRoomClassIsEmpty
		|			OR NOT &qRoomClassIsEmpty
		|				AND RoomTypes.RoomClass = &qRoomClass)
		|	AND (&qExcludingRoomClassIsEmpty
		|			OR NOT &qExcludingRoomClassIsEmpty
		|				AND RoomTypes.RoomClass <> &qExcludingRoomClass)
		|
		|ORDER BY
		|	RoomTypes.SortCode,
		|	RoomTypes.Description";
	ElsIf Not ValueIsFilled(pRoomType) And ValueIsFilled(pExcludingRoomType) And Not pExcludingRoomType.IsFolder Then
		vQry.Text = 
		"SELECT
		|	RoomTypes.Ref AS Ref
		|FROM
		|	Catalog.RoomTypes AS RoomTypes
		|WHERE
		|	NOT RoomTypes.DeletionMark
		|	AND NOT RoomTypes.IsFolder
		|	AND (&qHotelIsEmpty
		|			OR NOT &qHotelIsEmpty
		|				AND RoomTypes.Owner = &qHotel)
		|	AND RoomTypes.Ref <> &qExcludingRoomType
		|	AND (&qRoomClassIsEmpty
		|			OR NOT &qRoomClassIsEmpty
		|				AND RoomTypes.RoomClass = &qRoomClass)
		|	AND (&qExcludingRoomClassIsEmpty
		|			OR NOT &qExcludingRoomClassIsEmpty
		|				AND RoomTypes.RoomClass <> &qExcludingRoomClass)
		|
		|ORDER BY
		|	RoomTypes.SortCode,
		|	RoomTypes.Description";
	EndIf;
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(pHotel));
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qRoomClass", pRoomClass);
	vQry.SetParameter("qRoomClassIsEmpty", Not ValueIsFilled(pRoomClass));
	vQry.SetParameter("qExcludingRoomClass", pExcludingRoomClass);
	vQry.SetParameter("qExcludingRoomClassIsEmpty", Not ValueIsFilled(pExcludingRoomClass));
	vQry.SetParameter("qRoomType", pRoomType);
	vQry.SetParameter("qExcludingRoomType", pExcludingRoomType);
	vQryRes = vQry.Execute().Unload();
	If vQryRes.Count() > 0 Then
		vRoomTypesList.LoadValues(vQryRes.UnloadColumn("Ref"));
	EndIf;
	Return vRoomTypesList;
EndFunction // GetRoomTypesList

#EndRegion
