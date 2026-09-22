#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure ChoiceDataGetProcessing(rChoiceData, pParameters, pStandardProcessing)
	vSearchString = TrimAll(pParameters.SearchString);
		
	If Not IsBlankString(vSearchString) Then
		pStandardProcessing = False;
		rChoiceData = New ValueList();

		vHotel = Catalogs.Hotels.EmptyRef();
		If pParameters.Property("AdditionalData") And pParameters.AdditionalData.Property("Hotel") Then
			vHotel = pParameters.AdditionalData.Hotel;
		ElsIf pParameters.Filter.Property("Hotel") And ValueIsFilled(pParameters.Filter.Hotel) Then
			vHotel = pParameters.Filter.Hotel;
		EndIf;
		If Not ValueIsFilled(vHotel) Then
			vHotel = SessionParameters.CurrentHotel;
		EndIf;
		
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	ServiceItems.Ref AS Ref
		|FROM
		|	Catalog.ServiceItems AS ServiceItems
		|WHERE
		|	(ServiceItems.Code = &qCode
		|			OR ServiceItems.Description LIKE &qDescription)
		|	AND (ServiceItems.Hotel = &qHotel
		|			OR ServiceItems.Hotel = VALUE(Catalog.Hotels.EmptyRef))
		|	AND NOT ServiceItems.DeletionMark
		|	AND NOT ServiceItems.IsFolder
		|	AND NOT ServiceItems.IsOutOfSale
		|
		|ORDER BY
		|	ServiceItems.SortCode,
		|	ServiceItems.Description";
		vQry.SetParameter("qCode", ?(cmIsNumber(vSearchString), Number(vSearchString), -1));
		vQry.SetParameter("qDescription", "%" + vSearchString + "%");
		vQry.SetParameter("qHotel", vHotel);
		vSearchResult = vQry.Execute().Select();
		While vSearchResult.Next() Do
			rChoiceData.Add(vSearchResult.Ref);
		EndDo;
	EndIf;
EndProcedure // ChoiceDataGetProcessing

#EndRegion

#Region Public

// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	// NOTHING SO FAR	
EndProcedure // ExchangePlansRecordChanges

// -----------------------------------------------------------------------------
Function pmGetServiceItemDescription(pRef, pLang) Export
	vDescr = "";
	If Not ValueIsFilled(pLang) Then
		vDescr = TrimAll(pRef.Description);
	Else
		If IsBlankString(pRef.DescriptionTranslations) Then
			vDescr = TrimAll(pRef.Description);
		Else
			vDescr = TrimAll(cmNStr(pRef.DescriptionTranslations, pLang));
		EndIf;
	EndIf;
	Return vDescr;
EndFunction // pmGetServiceItemDescription

// -----------------------------------------------------------------------------
Function pmGetServiceItemUnitDescription(pRef, pLang) Export
	vDescr = "";
	If Not ValueIsFilled(pLang) Then
		vDescr = TrimAll(pRef.Unit);
	Else
		If IsBlankString(pRef.UnitTranslations) Then
			vDescr = TrimAll(pRef.Unit);
		Else
			vDescr = TrimAll(cmNStr(pRef.UnitTranslations, pLang));
		EndIf;
	EndIf;
	Return vDescr;
EndFunction // pmGetServiceItemUnitDescription

#EndRegion
