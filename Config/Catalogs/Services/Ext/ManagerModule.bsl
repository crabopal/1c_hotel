
#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure ChoiceDataGetProcessing(pChoiceData, pParameters, pStandardProcessing)
	If Not pParameters.Filter.Property("Hotel") Then
		vHotelFilter = New Array;
		vHotelFilter.Add(SessionParameters.CurrentHotel);
		vHotelFilter.Add(Catalogs.Hotels.EmptyRef());
		
		pParameters.Filter.Insert("Hotel", vHotelFilter);
	EndIf;
EndProcedure

#EndRegion

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
//
// Parameters:
//  pRef					 - CatalogRef.Services	 - Ref
//  pLang					 - CatalogRef.Languages	 - Ref
//  pUseGroupByDescription	 - Boolean				 - UseGroupByDescription
// 
// Returns:
//  String - service description
//
Function pmGetServiceDescription(pRef, pLang, pUseGroupByDescription = False) Export
	vDescr = "";
	If Not ValueIsFilled(pLang) Then
		vDescr = TrimAll(pRef.Description);
	Else
		If pUseGroupByDescription And Not IsBlankString(pRef.GroupByDescriptionTranslations) Then
			vDescr = TrimAll(cmNStr(pRef.GroupByDescriptionTranslations, pLang));
		Else
			If IsBlankString(pRef.DescriptionTranslations) Then
				vDescr = TrimAll(pRef.Description);
			Else
				vDescr = TrimAll(cmNStr(pRef.DescriptionTranslations, pLang));
			EndIf;
		EndIf;
	EndIf;
	Return vDescr;
EndFunction // pmGetServiceDescription      

// -----------------------------------------------------------------------------
//
// Parameters:
//  pRef	 - CatalogRef.Services	 - Ref
//  pLang	 - CatalogRef.Languages	 - Ref
// 
// Returns:
//  String - Unit description
//
Function pmGetServiceUnitDescription(pRef, pLang) Export
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
EndFunction // pmGetServiceUnitDescription

// -----------------------------------------------------------------------------
//
// Parameters:
//  pRef		 - CatalogRef.Services	 - Ref
//  pQuantity	 - Number				 - Quantity
//  pLang		 - CatalogRef.Languages	 - Ref
// 
// Returns:
//  String - Formated string
//
Function pmGetServiceQuantityPresentation(pRef, pQuantity, pLang) Export
	vQuantityStr = "";   
	vOneMinute = 60;  
	v24Hour = 24;
	If Round(pQuantity, 3) <> pQuantity Then
		vQuantityStr = ?(pQuantity = 0, "", Format(pQuantity, "ND=17; NFD=3"));
	Else
		vQuantityStr = ?(pQuantity = 0, "", String(pQuantity));
	EndIf;
	vQuantityStr = TrimAll(vQuantityStr + " " + pmGetServiceUnitDescription(pRef, pLang));
	If pRef.GetUnitFromRule And ValueIsFilled(pRef.QuantityCalculationRule) Then
		If pRef.QuantityCalculationRule.PeriodInHours = v24Hour Then
			vQuantityInHours = Round(pQuantity * pRef.QuantityCalculationRule.PeriodInHours);
			vQuantityInDays = Int(vQuantityInHours / v24Hour);
			vQuantityInHours = vQuantityInHours - vQuantityInDays * v24Hour;
			If vQuantityInDays <> 0 Then
				vQuantityStr = String(vQuantityInDays) + " " + pmGetServiceUnitDescription(pRef, pLang) + " ";
			Else
				vQuantityStr = "";
			EndIf;
			If vQuantityInHours <> 0 Then
				vQuantityStr = vQuantityStr + String(vQuantityInHours) + cmNStr("en = ' h'; de = ' st'; ru = ' ч'", pLang);
			EndIf;
		EndIf;
	ElsIf pRef.IsResourceRevenue And Not pRef.RoomRevenueAmountsOnly Then
		If pRef.IsPricePerMinute And TrimAll(pRef.Unit) = TrimAll(Catalogs.Units.Minute) Then
			vQuantityStr = String(pQuantity) + cmNStr("en = ' m'; de = ' m'; ru = ' м'", pLang);
		ElsIf TrimAll(pRef.Unit) = TrimAll(Catalogs.Units.Hour) Then
			vQuantityInHours = Int(pQuantity);
			vQuantityInMinutes = Round((pQuantity - Int(pQuantity)) * vOneMinute, 0);
			If vQuantityInHours <> 0 Then
				vQuantityStr = String(vQuantityInHours) + cmNStr("en = ' h'; de = ' st'; ru = ' ч'", pLang) + " ";
			Else
				vQuantityStr = "";
			EndIf;
			If vQuantityInMinutes <> 0 Then
				vQuantityStr = vQuantityStr + String(vQuantityInMinutes) + cmNStr("en = ' m'; de = ' m'; ru = ' м'", pLang);
			EndIf;
		EndIf;
	EndIf;
	Return vQuantityStr;
EndFunction // pmGetServiceQuantityPresentation	

// -----------------------------------------------------------------------------
//  Get service characteristics
//
// Parameters:
//  pRef - CatalogRef.Services	 - Ref
// 
// Returns:
//  ValueTable - List service characteristics
//
Function pmGetServiceCharacteristics(pRef) Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	ServiceCharacteristics.Service AS Service,
	|	ServiceCharacteristics.ServiceCharacteristic AS ServiceCharacteristic,
	|	ServiceCharacteristics.ServiceCharacteristicValue AS ServiceCharacteristicValue
	|FROM
	|	InformationRegister.ServiceCharacteristics AS ServiceCharacteristics
	|WHERE
	|	ServiceCharacteristics.Service = &qService
	|	AND ServiceCharacteristics.ServiceCharacteristic.DeletionMark = FALSE
	|
	|ORDER BY
	|	ServiceCharacteristics.ServiceCharacteristic.Code";
	vQry.SetParameter("qService", pRef);
	vChars = vQry.Execute().Unload();
	Return vChars;
EndFunction // pmGetServiceCharacteristics      

// -----------------------------------------------------------------------------
//  Get service characteristic value
//
// Parameters:
//  pRef					 - CatalogRef.Services										 - Ref
//  pServiceCharacteristic	 - ChartOfCharacteristicTypesRef.ServiceCharacteristicTypes	 - Ref
// 
// Returns:
//  Characteristic.ServiceCharacteristicTypes - Service characteristic value
//
Function pmGetServiceCharacteristicValue(pRef, pServiceCharacteristic) Export
	vCharValue = Undefined;
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	ServiceCharacteristics.ServiceCharacteristicValue AS ServiceCharacteristicValue
	|FROM
	|	InformationRegister.ServiceCharacteristics AS ServiceCharacteristics
	|WHERE
	|	ServiceCharacteristics.Service = &qService
	|	AND ServiceCharacteristics.ServiceCharacteristic = &qServiceCharacteristic
	|
	|ORDER BY
	|	ServiceCharacteristics.ServiceCharacteristic.Code";
	vQry.SetParameter("qService", pRef);
	vQry.SetParameter("qServiceCharacteristic", pServiceCharacteristic);
	vChars = vQry.Execute().Select();
	While vChars.Next() Do
		vCharValue = vChars.ServiceCharacteristicValue;
		Break;
	EndDo;
	Return vCharValue;
EndFunction // pmGetServiceCharacteristicValue  

// -----------------------------------------------------------------------------
//
// Parameters:
//  pRef						 - CatalogRef.Services						 - Ref
//  pServiceCharacteristic		 - 											 - ChartOfCharacteristicTypesRef.ServiceCharacteristicTypes
//  pServiceCharacteristicValue	 - Characteristic.ServiceCharacteristicTypes - Value
//
Procedure pmSaveServiceCharacteristicValue(pRef, pServiceCharacteristic, pServiceCharacteristicValue) Export
	vServiceCharsMgr = InformationRegisters.ServiceCharacteristics.CreateRecordManager();
	vServiceCharsMgr.Service = pRef;
	vServiceCharsMgr.ServiceCharacteristic = pServiceCharacteristic;
	vServiceCharsMgr.Read();
	If vServiceCharsMgr.Selected() Then
		vServiceCharsMgr.Service = pRef;
		vServiceCharsMgr.ServiceCharacteristic = pServiceCharacteristic;
		vServiceCharsMgr.ServiceCharacteristicValue = pServiceCharacteristicValue;
		vServiceCharsMgr.Write();
	EndIf;
EndProcedure // pmSaveServiceCharacteristicValue

#EndRegion
