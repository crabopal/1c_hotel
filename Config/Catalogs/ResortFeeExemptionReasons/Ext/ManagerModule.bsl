
#Region Public

 // --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, , pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

// -----------------------------------------------------------------------------
//
Procedure FillResortFeeExemptionReasons() Export 
	vListRF = DefaultResortFeeExemptionReasons();
	For Each vDesc In vListRF Do
		vRef = Catalogs.ResortFeeExemptionReasons.FindByDescription(vDesc, True);	
		If Not ValueIsFilled(vRef) Then    
			SetPrivilegedMode(True);
			vNewObj = Catalogs.ResortFeeExemptionReasons.CreateItem();
			vNewObj.Description = vDesc;
			vNewObj.Write();
			SetPrivilegedMode(False);
		EndIf;	
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
//
Procedure FillTouristTaxExemptionReasons() Export 
	vListRF = DefaultTouristTaxExemptionReasons();
	For Each vDesc In vListRF Do
		vRef = Catalogs.ResortFeeExemptionReasons.FindByDescription(vDesc, True);
		If Not ValueIsFilled(vRef) Then    
			SetPrivilegedMode(True);
			vNewObj = Catalogs.ResortFeeExemptionReasons.CreateItem();
			vNewObj.Description = vDesc;
			vNewObj.IsForTouristTax = True;
			vNewObj.Write();
			SetPrivilegedMode(False);
		EndIf;	
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel	 - CatalogRef.Hotels - Ref
// 
// Returns:
//  ValueList - ResortFeeExemptionReasonsList
//
Function GetResortFeeExemptionReasonsList(pHotel = Undefined) Export 
	vHotel = pHotel;
	If Not ValueIsFilled(vHotel) Then
		vHotel = SessionParameters.CurrentHotel;	
	EndIf;	
	vRegionsList = New Array;
	vRegionsList.Add(Catalogs.Regions.EmptyRef());
	If ValueIsFilled(vHotel) And ValueIsFilled(vHotel.Region) Then
		vRegionsList.Add(vHotel.Region);
	EndIf;
	
	vList = New ValueList;
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ResortFeeExemptionReasons.Description AS Description
		|FROM
		|	Catalog.ResortFeeExemptionReasons AS ResortFeeExemptionReasons
		|WHERE
		|	ResortFeeExemptionReasons.DeletionMark = FALSE
		|	AND ResortFeeExemptionReasons.IsFolder = FALSE
		|	AND ResortFeeExemptionReasons.IsForTouristTax = FALSE
		|	AND ResortFeeExemptionReasons.Region IN(&qRegionsList)";
		
	vQuery.SetParameter("qRegionsList", vRegionsList);
	vQueryResult = vQuery.Execute();
	
	vRes = vQueryResult.Select();
	
	While vRes.Next() Do
		vList.Add(vRes.Description, vRes.Description);
	EndDo;
	If vList.Count() = 0 Then
		FillResortFeeExemptionReasons();	
		vList = GetResortFeeExemptionReasonsList();
	EndIf;
	Return vList;
EndFunction // GetResortFeeExemptionReasonsList()

// -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel	 - CatalogRef.Hotels - Ref
// 
// Returns:
//  ValueList - TouristTaxExemptionReasonsList
//
Function GetTouristTaxExemptionReasonsList(pHotel = Undefined) Export 
	vHotel = pHotel;
	If Not ValueIsFilled(vHotel) Then
		vHotel = SessionParameters.CurrentHotel;	
	EndIf;	
	vRegionsList = New Array;
	vRegionsList.Add(Catalogs.Regions.EmptyRef());
	If ValueIsFilled(vHotel) And ValueIsFilled(vHotel.Region) Then
		vRegionsList.Add(vHotel.Region);
	EndIf;
	
	vList = New ValueList;
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ResortFeeExemptionReasons.Ref AS Ref,
		|	ResortFeeExemptionReasons.Description AS Description
		|FROM
		|	Catalog.ResortFeeExemptionReasons AS ResortFeeExemptionReasons
		|WHERE
		|	ResortFeeExemptionReasons.DeletionMark = FALSE
		|	AND ResortFeeExemptionReasons.IsFolder = FALSE
		|	AND ResortFeeExemptionReasons.IsForTouristTax = TRUE
		|	AND ResortFeeExemptionReasons.Region IN(&qRegionsList)";
		
	vQuery.SetParameter("qRegionsList", vRegionsList);
	vQueryResult = vQuery.Execute();
	
	vRes = vQueryResult.Select();
	
	While vRes.Next() Do
		vList.Add(vRes.Ref, vRes.Description);
	EndDo;
	If vList.Count() = 0 Then
		FillTouristTaxExemptionReasons();	
		vList = GetTouristTaxExemptionReasonsList();
	EndIf;
	Return vList;
EndFunction // GetTouristTaxExemptionReasonsList()

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
// 
// Returns:
//  Array - List DefaultResortFeeExemptionReasons
//
Function DefaultResortFeeExemptionReasons()
    vList = New Array;
	vList.Add("Отказ от уплаты налога / сбора");
	vList.Add("1. Герой РФ (СССР)");
	vList.Add("2. Герой труда РФ (СССР)");
	vList.Add("3. Участник ВОВ");
	vList.Add("4. Ветеран боевых действий");
	vList.Add("5. Житель блокадного Ленинграда");
	vList.Add("6. Лицо, работавшее в период ВОВ");
	vList.Add("7. Инвалид войны");
	vList.Add("8. Член семьи погибших инвалидов войны");
	vList.Add("9. Лицо, подвергшееся воздействию радиации");
	vList.Add("10. Инвалид I или II группы");
	vList.Add("11. Лицо, сопровождающее инвалида");
	vList.Add("12. Малоимущая семья");
	vList.Add("13. Лицо прибывшее за оказанием мед. помощи");
	vList.Add("14. Больной туберкулезом");
	vList.Add("15. Учащийся");
	vList.Add("16. Работающий");
	vList.Add("17. Проживающий в домашнем регионе");
	vList.Add("18. Собственник жилья");
	vList.Add("19. Участник спортивных мероприятий");
	vList.Add("20. Лица на лечении в рамках обязательного мед. страхования");   
	vList.Add("20. Фестиваль молодежи в 2024 году");

	Return vList;
EndFunction // DefaultResortFeeExemptionReasons()

// -----------------------------------------------------------------------------
// 
// Returns:
//  Array - List DefaultTouristTaxExemptionReasons
//
Function DefaultTouristTaxExemptionReasons()
    vList = New Array;
	vList.Add("Герой РФ (СССР) или полный кавалер ордена Славы");
	vList.Add("Герой труда РФ (СССР) или награжден орденом Трудовой славы 3-х степеней");
	vList.Add("Участник ВОВ");
	vList.Add("Инвалид ВОВ");
	vList.Add("Лица, принимающие (принимавшие) участие в СВО");
	vList.Add("Ветеран боевых действий");
	vList.Add("Житель блокадного Ленинграда");
	vList.Add("Житель осажденного Севастополя");
	vList.Add("Житель осажденного Сталинграда");
	vList.Add("Лицо, работавшее в период ВОВ");
	vList.Add("Инвалид I или II группы");
	vList.Add("Инвалид детства");
	vList.Add("Ребенок-инвалид");

	Return vList;
EndFunction // DefaultTouristTaxExemptionReasons

#EndRegion     
