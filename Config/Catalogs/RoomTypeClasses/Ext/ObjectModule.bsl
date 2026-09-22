

#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure BeforeWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	// Check that sort code is unique
	If SortCode <> 0 Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	RoomTypeClasses.Ref AS Ref
		|FROM
		|	Catalog.RoomTypeClasses AS RoomTypeClasses
		|WHERE
		|	RoomTypeClasses.SortCode = &qSortCode
		|	AND RoomTypeClasses.Owner = &qHotel
		|	AND RoomTypeClasses.Ref <> &qThisRef
		|
		|ORDER BY
		|	RoomTypeClasses.SortCode,
		|	RoomTypeClasses.Code";
		vQry.SetParameter("qSortCode", SortCode);
		vQry.SetParameter("qHotel", Owner);
		vQry.SetParameter("qThisRef", Ref);
		vRCs = vQry.Execute().Unload();
		If vRCs.Count() > 0 Then
			vRC = vRCs.Get(0).Ref;
			vError = NStr("en = 'There is another room class (%1) with the same sort code %2! Set unique sort code please.'; 
						  |de = 'Fand eine andere Zimmerklasse (%1) mit dem gleichen Sortiercode %2! Geben Sie einen eindeutigen Sortiercode ein.'; 
						  |ru = 'Найден другой класс номера (%1) с тем же кодом сортировки %2! Укажите уникальный код сортировки.'");
			Raise StrTemplate(vError, TrimAll(vRC), Format(SortCode, "NFD=0; NG="));
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel)  
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

#EndRegion
