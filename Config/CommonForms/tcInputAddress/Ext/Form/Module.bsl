
#Region FormEventHandlers

// ----------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	Address = Parameters.Address;
	If Parameters.Property("Country") Then
		Country = Parameters.Country;
	EndIf;
	If Parameters.Property("AddressType") Then
		AddressType = Parameters.AddressType;
	EndIf;
	CloseOnChoice = False;
	// Set controls appearance
	If TrimAll(AddressType) = "PlaceOfBirth" Then
		Title = Nstr("en = 'Fill in the place of birth'; de = 'Tragen Sie den Geburtsort ein'; ru = 'Укажите место рождения'");
		Items.Street.Enabled = False;
		Items.House.Enabled = False;
		Items.Flat.Enabled = False;
	Else
		Title = Nstr("en = 'Address input'; de = 'Eingabe der Adresse'; ru = 'Ввод адреса'");
		Items.Street.Enabled = True;
		Items.House.Enabled = True;
		Items.Flat.Enabled = True;
		Items.DecorationLivingAddressPartSplitter.Title = "";
	EndIf;
	// Parse address to fields
	vAddressFields = cmParseAddress(Address);
	If ValueIsFilled(vAddressFields.Country) Then
		If Not IsBlankString(vAddressFields.Country.Description) Then
			Country = vAddressFields.Country;
		EndIf;
	EndIf;
	
	// Show or hide validate via dadata button
	vDadataIsUsed = False;
	vHotel = ?(ValueIsFilled(Parameters.Hotel), Parameters.Hotel, SessionParameters.CurrentHotel);
	vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionType(Enums.Integrations.DADATA, vHotel);
	If ValueIsFilled(vInteraction) And vInteraction.IsActive And Not IsBlankString(vInteraction.OAuth_AccessToken) Then
		vIntMapping = InformationRegisters.ExternalSystemIntegrationData.GetData(vInteraction, "Dadata");
		If vIntMapping.Count() > 0 Then 
			vData = vIntMapping[0]; 
			If vData.FillAddress Then
				vDadataIsUsed = True;
				Items.Address.ChoiceButton = True;	    
				vMsg = NStr("en = 'Start typing the address for the DADATA hints'; 
							|de = 'Beginnen Sie mit der Eingabe Ihrer Adresse, um Hinweise von DADATA zu erhalten'; 
							|ru = 'Начните вводить адрес для подсказок из DADATA'");
				Items.Address.InputHint = vMsg;
			EndIf;
		EndIf;
	EndIf;
	If Not vDadataIsUsed Then
		Items.Address.ChoiceButton = False;
		ThisObject.CurrentItem = Items.City;
	Else
		ThisObject.CurrentItem = Items.Address;
	EndIf;
	
	PostCode = vAddressFields.PostCode;
	Region = vAddressFields.Region;
	Area = vAddressFields.Area;
	City = vAddressFields.City;
	Street = vAddressFields.Street;
	House = vAddressFields.House;
	Flat = vAddressFields.Flat;   
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// ----------------------------------------------------------------------------------
&AtClient
Procedure RegionTextEditEnd(pItem, pText, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	If IsBlankString(pText) Then
		pStandardProcessing = True;
		Return;
	EndIf;
	pChoiceData = GetFindedRegion(pText, Country, PostCode);	
EndProcedure //  RegionTextEditEnd

// ----------------------------------------------------------------------------------
&AtClient
Procedure RegionStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;	
	vFrm = GetForm("Catalog.Regions.ChoiceForm",, pItem);	
	vFrm.List.Filter.Items.Clear();
	
	vFilter = vFrm.List.Filter.Items.Add(Type("DataCompositionFilterItem"));
    vFilter.LeftValue = vFrm.List.Filter.FilterAvailableFields.Items.Find("Country").Field;
	vFilter.ComparisonType = DataCompositionComparisonType.Equal;
	vFilter.RightValue = Country;
	vFilter.Use = True;	
	
	vFrm.Open();
EndProcedure //  RegionStartChoice

// ----------------------------------------------------------------------------------
&AtClient
Procedure RegionEditTextChange(pItem, pText, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure //  RegionEditTextChange

// ----------------------------------------------------------------------------------
&AtClient
Procedure AreaStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;	
	vRegionRef = CallOnServerGetRegionByDescription(Region, Country);
	vFrm = GetForm("Catalog.Areas.ChoiceForm", , pItem);
	vFrm.List.Filter.Items.Clear();
	
	vFilter = vFrm.List.Filter.Items.Add(Type("DataCompositionFilterItem"));
	vFilter.LeftValue = vFrm.List.Filter.FilterAvailableFields.Items.Find("Country").Field;
	vFilter.ComparisonType = DataCompositionComparisonType.Equal;
	vFilter.RightValue = Country;
	vFilter.Use = True;
	
	vFilter = vFrm.List.Filter.Items.Add(Type("DataCompositionFilterItem"));
    vFilter.LeftValue = vFrm.List.Filter.FilterAvailableFields.Items.Find("Region").Field;
	vFilter.ComparisonType = DataCompositionComparisonType.Equal;
	vFilter.RightValue = vRegionRef;
	If ValueIsFilled(vRegionRef) Then
		vFilter.Use = True;	
	Else
		vFilter.Use = True;
	EndIf;
	
	vFrm.Open();
EndProcedure //  AreaStartChoice

// ----------------------------------------------------------------------------------
&AtClient
Procedure AreaTextEditEnd(pItem, pText, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	If IsBlankString(pText) Then
		pStandardProcessing = True;
		Return;
	EndIf;
	pChoiceData = GetFindedArea(pText, Country, PostCode, Region);
EndProcedure //  AreaTextEditEnd

// ----------------------------------------------------------------------------------
&AtClient
Procedure AreaChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	If ValueIsFilled(pSelectedValue) And TypeOf(pSelectedValue) <> Type("String") Then
		Region = TrimAll(GetAttributeFromRef(pSelectedValue, "Region"));
	EndIf;
EndProcedure //  AreaChoiceProcessing

// ----------------------------------------------------------------------------------
&AtClient
Procedure AreaEditTextChange(pItem, pText, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure //  AreaEditTextChange

// ----------------------------------------------------------------------------------
&AtClient
Procedure PostCodeChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	If ValueIsFilled(pSelectedValue) And TypeOf(pSelectedValue) = Type("String") Then
		pStandardProcessing = False;
		vAddressStruct = ParseAddressStringAtServer(pSelectedValue);
		PostCode = TrimAll(vAddressStruct.PostCode);
		Region = TrimAll(vAddressStruct.Region);
		Area = TrimAll(vAddressStruct.Area);
		City = TrimAll(vAddressStruct.City);
		If TrimAll(AddressType) <> "PlaceOfBirth" Then
			Street = TrimAll(vAddressStruct.Street);
		EndIf;
	EndIf;
EndProcedure //  PostCodeChoiceProcessing

// ----------------------------------------------------------------------------------
&AtClient
Procedure PostCodeTextEditEnd(pItem, pText, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	If IsBlankString(pText) Then
		pStandardProcessing = True;
		Return;
	EndIf;
	vPostCodes = GetFindedPostCode(pText, Country);
	If vPostCodes.Count() > 0 Then
		pChoiceData = vPostCodes;
	Else
		pStandardProcessing = True;
	EndIf;
EndProcedure //  PostCodeTextEditEnd

// ----------------------------------------------------------------------------------
&AtClient
Procedure PostCodeEditTextChange(pItem, pText, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure //  PostCodeEditTextChange

// ----------------------------------------------------------------------------------
&AtClient
Procedure CityStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vRegionRef = CallOnServerGetRegionByDescription(Region, Country);
	vAreaRef = CallOnServerGetAreaByDescription(Area, Country, vRegionRef);
	vFrm = GetForm("Catalog.Cities.ChoiceForm", , pItem);
	vFrm.List.Filter.Items.Clear();
	
	vFilter = vFrm.List.Filter.Items.Add(Type("DataCompositionFilterItem"));
	vFilter.LeftValue = vFrm.List.Filter.FilterAvailableFields.Items.Find("Country").Field;
	vFilter.ComparisonType = DataCompositionComparisonType.Equal;
	vFilter.RightValue = Country;
	vFilter.Use = True;	
	
	vFilter = vFrm.List.Filter.Items.Add(Type("DataCompositionFilterItem"));
	vFilter.LeftValue = vFrm.List.Filter.FilterAvailableFields.Items.Find("Region").Field;
	vFilter.ComparisonType = DataCompositionComparisonType.Equal;
	vFilter.RightValue = vRegionRef;
	If ValueIsFilled(vRegionRef) Then
		vFilter.Use = True;	
	Else
		vFilter.Use = False;
	EndIf;
	
	vFilter = vFrm.List.Filter.Items.Add(Type("DataCompositionFilterItem"));
	vFilter.LeftValue = vFrm.List.Filter.FilterAvailableFields.Items.Find("Area").Field;
	vFilter.ComparisonType = DataCompositionComparisonType.Equal;
	vFilter.RightValue = vAreaRef;
	If ValueIsFilled(vAreaRef) Then
		vFilter.Use = True;	
	Else
		vFilter.Use = False;
	EndIf;
	
	vFrm.Open();
EndProcedure //  CityStartChoice

// ----------------------------------------------------------------------------------
&AtClient
Procedure CityTextEditEnd(pItem, pText, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	If IsBlankString(pText) Then
		pStandardProcessing = True;
		Return;
	EndIf;
	pChoiceData = GetFindedCity(pText, Country, PostCode, Region, Area);
EndProcedure //  CityTextEditEnd

// ----------------------------------------------------------------------------------
&AtClient
Procedure CityChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	If ValueIsFilled(pSelectedValue) And TypeOf(pSelectedValue) <> Type("String") Then
		Region = TrimAll(GetAttributeFromRef(pSelectedValue, "Region"));
		Area = TrimAll(GetAttributeFromRef(pSelectedValue, "Area"));
		If Not IsBlankString(GetAttributeFromRef(pSelectedValue, "PostCode")) Then
			PostCode = TrimAll(GetAttributeFromRef(pSelectedValue, "PostCode"));
		EndIf;
	EndIf;
EndProcedure //  CityChoiceProcessing

// ----------------------------------------------------------------------------------
&AtClient
Procedure CityEditTextChange(pItem, pText, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure //  CityEditTextChange

// ----------------------------------------------------------------------------------
&AtClient
Procedure StreetTextEditEnd(pItem, pText, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	If IsBlankString(pText) Then
		pStandardProcessing = True;
		Return;
	EndIf;
	pChoiceData = GetFindedStreet(pText, Country, PostCode, Region, Area, City);
EndProcedure //  StreetTextEditEnd

// ----------------------------------------------------------------------------------
&AtClient
Procedure StreetChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	If ValueIsFilled(pSelectedValue) And TypeOf(pSelectedValue) <> Type("String") Then
		Region = TrimAll(GetAttributeFromRef(pSelectedValue, "Region"));
		Area = TrimAll(GetAttributeFromRef(pSelectedValue, "Area"));
		City = TrimAll(GetAttributeFromRef(pSelectedValue, "City"));
		If Not IsBlankString(GetAttributeFromRef(pSelectedValue, "PostCode")) Then
			PostCode = TrimAll(GetAttributeFromRef(pSelectedValue, "PostCode"));
		EndIf;
	EndIf;
EndProcedure //  StreetChoiceProcessing

// ----------------------------------------------------------------------------------
&AtClient
Procedure StreetStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vRegionRef = CallOnServerGetRegionByDescription(Region, Country);
	vAreaRef = CallOnServerGetAreaByDescription(Area, Country, vRegionRef);
	vCityRef = CallOnServerGetCityByDescription(City, Country, vRegionRef, vAreaRef);
	vFrm = GetForm("Catalog.Streets.ChoiceForm", , pItem);
	vFrm.List.Filter.Items.Clear();	

	vFilter = vFrm.List.Filter.Items.Add(Type("DataCompositionFilterItem"));
	vFilter.LeftValue = vFrm.List.Filter.FilterAvailableFields.Items.Find("Country").Field;
	vFilter.ComparisonType = DataCompositionComparisonType.Equal;
	vFilter.RightValue = Country;
	vFilter.Use = True;	
	
	vFilter = vFrm.List.Filter.Items.Add(Type("DataCompositionFilterItem"));
	vFilter.LeftValue = vFrm.List.Filter.FilterAvailableFields.Items.Find("Region").Field;
	vFilter.ComparisonType = DataCompositionComparisonType.Equal;
	vFilter.RightValue = vRegionRef;
	If ValueIsFilled(vRegionRef) Then
		vFilter.Use = True;	
	Else
		vFilter.Use = False;
	EndIf;
	
	vFilter = vFrm.List.Filter.Items.Add(Type("DataCompositionFilterItem"));
	vFilter.LeftValue = vFrm.List.Filter.FilterAvailableFields.Items.Find("Area").Field;
	vFilter.ComparisonType = DataCompositionComparisonType.Equal;
	vFilter.RightValue = vAreaRef;
	If ValueIsFilled(vAreaRef) Then
		vFilter.Use = True;	
	Else
		vFilter.Use = False;
	EndIf;
	
	vFilter = vFrm.List.Filter.Items.Add(Type("DataCompositionFilterItem"));
	vFilter.LeftValue = vFrm.List.Filter.FilterAvailableFields.Items.Find("City").Field;
	vFilter.ComparisonType = DataCompositionComparisonType.Equal;
	vFilter.RightValue = vCityRef;
	If ValueIsFilled(vCityRef) Then
		vFilter.Use = True;	
	Else
		vFilter.Use = False;
	EndIf;
	
	vFrm.Open();
EndProcedure //  StreetStartChoice

// ----------------------------------------------------------------------------------
&AtClient
Procedure StreetEditTextChange(pItem, pText, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure //  StreetEditTextChange

// ----------------------------------------------------------------------------------
&AtClient
Procedure AddressFreeFormOnChange(pItem)
	Items.Address.Visible = AddressFreeForm;
	Items.GroupFieldsAddress.Visible = Not AddressFreeForm;
EndProcedure //  AddressFreeFormOnChange

// ----------------------------------------------------------------------------------
&AtClient
Procedure AddressTextEditEnd(pItem, pText, pChoiceData, pDataGetParameters, pStandardProcessing)
	pStandardProcessing = False;
	#If Not WebClient And Not MobileClient Then
		FillAddresDadata(pText, pChoiceData);
		If pChoiceData = Undefined Or TypeOf(pChoiceData) = Type("ValueList") And pChoiceData.Count() = 0 Then
			pStandardProcessing = True;
			pChoiceData = Undefined;
		EndIf;
	#Else
		pStandardProcessing = True;
		pChoiceData = Undefined;
	#EndIf
	Modified = True;
EndProcedure //  AddressTextEditEnd

// ----------------------------------------------------------------------------------
&AtClient
Procedure AddressAutoComplete(pItem, pText, pChoiceData, pDataGetParameters, pWait, pStandardProcessing)
	pStandardProcessing = False;
	#If Not WebClient And Not MobileClient Then
		FillAddresDadata(pText, pChoiceData);
		If pChoiceData = Undefined Or TypeOf(pChoiceData) = Type("ValueList") And pChoiceData.Count() = 0 Then
			pStandardProcessing = True;
			pChoiceData = Undefined;
		EndIf;
	#Else
		pStandardProcessing = True;
		pChoiceData = Undefined;
	#EndIf
	Modified = True;
EndProcedure //  AddressAutoComplete

// ----------------------------------------------------------------------------------
&AtClient
Procedure AddressChoiceProcessing(pItem, pSelectedValue, pAdditionalData, pStandardProcessing)    
	If pSelectedValue <> Undefined And Not IsBlankString(pSelectedValue) Then
		Try
		    Address = pSelectedValue.Address;
			SaveAddress(pSelectedValue);   
			pSelectedValue = Address;
		Except	
		EndTry;
	EndIf;
EndProcedure //  AddressChoiceProcessing

// ----------------------------------------------------------------------------------
&AtClient
Procedure AddressStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vList = GetAddressListFromDadata(Address);
	vSelectedElem = ChooseFromList(vList, pItem);
	If vSelectedElem <> Undefined Then
		Address = vSelectedElem.Value.Address; 
		SaveAddress(vSelectedElem.Value);
	EndIf;
	Modified = True;
EndProcedure //  AddressStartChoice

#EndRegion

#Region FormCommandsEventHandlers

// ----------------------------------------------------------------------------------
&AtClient
Procedure ClearAddressFields(pCommand)
	FillCountryField();
	Address = "";
	PostCode = "";
	Region = "";
	Area = "";
	City = "";
	Street = "";
	House = "";
	Flat = "";
	CurrentItem = Items.City;
EndProcedure //  ClearAddressFields

// ----------------------------------------------------------------------------------
&AtClient
Procedure ReturnAddress(pCommand)
	If AddressFreeForm Then
		vResult = TrimAll(Address);
	Else
		vResult = BuildAddress(Country, PostCode, Region, Area, City, Street, House, Flat);
	EndIf;
	 
	vParam = New Structure;
	vParam.Insert("Address", vResult);
	vParam.Insert("StreetFiasId", StreetFiasId);  
	
	NotifyChoice(vParam);
	
	Close(vParam);
EndProcedure // ReturnAddress

#EndRegion

#Region Private

// ----------------------------------------------------------------------------------
&AtServerNoContext
Function GetFindedRegion(pText, pCountry, pPostCode)
	// Try to find regions with name like given
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 50
	|	Regions.Ref AS Region
	|FROM
	|	Catalog.Regions AS Regions
	|WHERE
	|	Regions.Country = &qCountry
	|	AND Regions.Description LIKE &qRegion
	|	AND Regions.DeletionMark = FALSE
	|ORDER BY
	|	Regions.Description";
	vQry.SetParameter("qCountry", pCountry);
	vQry.SetParameter("qRegion", TrimAll(pText) + "%");
	vList = vQry.Execute().Unload();
	vChoiceList = New ValueList();
	If vList.Count() > 0 Then
		For Each vListRow In vList Do
			vRegion = vListRow.Region;
			vAddress = cmBuildAddress(pCountry, pPostCode, vRegion);
			vChoiceList.Add(vRegion, vAddress);
		EndDo;
	Else
		vChoiceList.Add(pText);
	EndIf;
	Return vChoiceList;
EndFunction //  GetFindedRegion

// ----------------------------------------------------------------------------------
&AtServerNoContext
Function GetFindedArea(pText, pCountry, pPostCode, pRegion)
	// Try to find areas with name like given
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 50
	|	Areas.Ref AS Area
	|FROM
	|	Catalog.Areas AS Areas
	|WHERE
	|	Areas.Country = &qCountry " + 
		?(ValueIsFilled(pRegion), "AND Areas.Region.Description = &qRegion ", "") + "
	|	AND Areas.Description LIKE &qArea
	|	AND Areas.DeletionMark = FALSE
	|ORDER BY
	|	Areas.Description";
	vQry.SetParameter("qCountry", pCountry);
	vQry.SetParameter("qRegion", TrimAll(pRegion));
	vQry.SetParameter("qArea", TrimAll(pText) + "%");
	vList = vQry.Execute().Unload();
	vChoiceList = New ValueList();
	If vList.Count() > 0 Then
		For Each vListRow In vList Do
			vArea = vListRow.Area;
			vAddress = cmBuildAddress(pCountry, pPostCode, vArea.Region, vArea);
			vChoiceList.Add(vArea, vAddress);
		EndDo;
	Else
		vChoiceList.Add(pText);
	EndIf;
	Return vChoiceList;
EndFunction //  GetFindedArea

// ----------------------------------------------------------------------------------
&AtServerNoContext
Function GetFindedCity(pText, pCountry, pPostCode, pRegion, pArea)
	// Try to find city with name like given
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 50
	|	Cities.Ref AS City,
	|	SUBSTRING(Cities.ExternalCode, 3, 9) AS MidExternalCode
	|FROM
	|	Catalog.Cities AS Cities
	|WHERE
	|	Cities.Country = &qCountry " 
		+ ?(ValueIsFilled(pRegion), "AND Cities.Region.Description = &qRegion ", "") 
		+ ?(ValueIsFilled(pArea), "AND Cities.Area.Description = &qArea ", "") + "
	|	AND Cities.Description LIKE &qCity
	|	AND Cities.DeletionMark = FALSE
	|ORDER BY
	|	MidExternalCode,
	|	Cities.Description";
	vQry.SetParameter("qCountry", pCountry);
	vQry.SetParameter("qRegion", TrimAll(pRegion));
	vQry.SetParameter("qArea", TrimAll(pArea));
	vQry.SetParameter("qCity", TrimAll(pText) + "%");
	vList = vQry.Execute().Unload();
	vChoiceList = New ValueList();
	If vList.Count() > 0 Then
		For Each vListRow In vList Do
			vCity = vListRow.City;
			vAddress = cmBuildAddress(pCountry, pPostCode, vCity.Region, vCity.Area, vCity);
			vChoiceList.Add(vCity, vAddress);
		EndDo;
	Else
		vChoiceList.Add(pText);
	EndIf;	
	Return vChoiceList;
EndFunction //  GetFindedCity

// ----------------------------------------------------------------------------------
&AtServerNoContext
Function GetFindedPostCode(pText, pCountry)
	// Try to find streets with this post code for the given country
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 50
	|	Streets.Ref AS Street
	|FROM
	|	Catalog.Streets AS Streets
	|WHERE
	|	Streets.Country = &qCountry
	|	AND Streets.PostCode = &qPostCode
	|	AND Streets.DeletionMark = FALSE";
	vQry.SetParameter("qCountry", pCountry);
	vQry.SetParameter("qPostCode", TrimAll(pText));
	vList = vQry.Execute().Unload();
	vChoiceList = New ValueList();
	If vList.Count() > 0 Then
		For Each vListRow In vList Do
			vStreet = vListRow.Street;
			vAddress = cmBuildAddress(pCountry, TrimAll(pText), vStreet.Region, vStreet.Area, vStreet.City, vStreet);
			vChoiceList.Add(vAddress);
		EndDo;
	EndIf;
	return vChoiceList;
EndFunction //  GetFindedPostCode

// ----------------------------------------------------------------------------------
&AtServerNoContext
Function GetFindedStreet(pText, pCountry, pPostCode, pRegion, pArea, pCity)
	// Try to find street with name like given
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 50
	|	Streets.Ref AS Street
	|FROM
	|	Catalog.Streets AS Streets
	|WHERE
	|	Streets.Country = &qCountry " + 
		?(ValueIsFilled(pRegion), "AND Streets.Region.Description = &qRegion ", "") 
		+ ?(ValueIsFilled(pArea), "AND Streets.Area.Description = &qArea ", "") 
		+ ?(ValueIsFilled(pCity), "AND Streets.City.Description = &qCity ", "") + "
	|	AND Streets.Description LIKE &qStreet
	|	AND Streets.DeletionMark = FALSE
	|ORDER BY
	|	Streets.Description";
	vQry.SetParameter("qCountry", pCountry);
	vQry.SetParameter("qRegion", TrimAll(pRegion));
	vQry.SetParameter("qArea", TrimAll(pArea));
	vQry.SetParameter("qCity", TrimAll(pCity));
	vQry.SetParameter("qStreet", TrimAll(pText)+"%");
	vList = vQry.Execute().Unload();
	vChoiceList = New ValueList();
	If vList.Count() > 0 Then
		For Each vListRow In vList Do
			vStreet = vListRow.Street;
			vAddress = cmBuildAddress(pCountry, pPostCode, vStreet.Region, vStreet.Area, vStreet.City, vStreet);
			vChoiceList.Add(vStreet, vAddress);
		EndDo;
	Else
		vChoiceList.Add(pText);
	EndIf;
	Return vChoiceList;
EndFunction //  GetFindedStreet

// ----------------------------------------------------------------------------------
&AtServer
Function GetAttributeFromRef(pRef, pAttribute = "")
	If pAttribute = "" Then
		Return pRef.EmptyRef();
	Else
		Return pRef[pAttribute];
	EndIf;
EndFunction //  GetAttributeFromRef

// ----------------------------------------------------------------------------------
&AtServerNoContext
Function ParseAddressStringAtServer(pAddress)
	Return cmParseAddress(pAddress);
EndFunction //  ParseAddressStringAtServer

// ----------------------------------------------------------------------------------
&AtServer
Procedure FillCountryField()
	If Not ValueIsFilled(Country) And ValueIsFilled(SessionParameters.CurrentHotel) Then
		Country = SessionParameters.CurrentHotel.Citizenship;
	EndIf;
EndProcedure //  FillCountryField

// ----------------------------------------------------------------------------------
&AtServer
Function CallOnServerGetRegionByDescription(pRegion, pCountry)
	return cmGetRegionByDescription(pRegion, pCountry);
EndFunction //  CallOnServerGetRegionByDescription

// ----------------------------------------------------------------------------------
&AtServer
Function CallOnServerGetAreaByDescription(pArea, pCountry, pRegion)
	return cmGetAreaByDescription(pArea, pCountry, pRegion);
EndFunction //  CallOnServerGetAreaByDescription

// ----------------------------------------------------------------------------------
&AtServer
Function CallOnServerGetCityByDescription(pCity, pCountry, pRegion, pArea)
	return cmGetCityByDescription(pCity, pCountry, pRegion, pArea);
EndFunction //  CallOnServerGetCityByDescription

// ----------------------------------------------------------------------------------
&AtServer
Function BuildAddress(pCountry, pPostCode, pRegion, pArea, pCity, pStreet, pHouse, pFlat)
	Return cmBuildAddress(pCountry, TrimAll(pPostCode), TrimAll(pRegion), Trimall(pArea), TrimAll(pCity), TrimAll(pStreet), TrimAll(pHouse), TrimAll(pFlat));
EndFunction //  ReturnAddress

// ----------------------------------------------------------------------------------
&AtClient
Procedure FillAddresDadata(Val pText, pList)
	If StrLen(pText) >= 4 Then
		pList = New ValueList();
		vListArr = GetAddressFromDadata(TrimAll(pText));
		For Each vRow In vListArr Do
			vData = vRow.data;
			vAddressArr = New Array;
			
			vCountry = "";
			If Not vData.country = Undefined And Not IsBlankString(vData.country) Then
				vCountry = vData.country;
			EndIf;
			vAddressArr.Add(vCountry);
			
			vPostal_code = "";
			If Not vData.postal_code = Undefined And Not IsBlankString(vData.postal_code) Then
				vPostal_code = vData.postal_code;
			EndIf;
			vAddressArr.Add(vPostal_code);

			vRegion = "";
			If vData.region = vData.city And Not vData.city = Undefined And Not IsBlankString(vData.city) Then
				vRegion = StrTemplate("%1 %2", vData.region, vData.region_type);
			ElsIf Not vData.region_with_type = Undefined And Not IsBlankString(vData.region_with_type) Then
				vRegion = vData.region_with_type;
			EndIf;
			vAddressArr.Add(vRegion);

			vArea = "";
			If Not vData.area_with_type = Undefined And Not IsBlankString(vData.area_with_type) Then
				vArea = vData.area_with_type;
			EndIf;
			vAddressArr.Add(vArea);

			vCity = "";
			If Not vData.settlement_with_type = Undefined And Not IsBlankString(vData.settlement_with_type) Then
				vCity = StrTemplate("%1 %2", vData.settlement, vData.settlement_type_full);
			ElsIf Not vData.city = Undefined And Not IsBlankString(vData.city) Then
				vCity = StrTemplate("%1 %2", vData.city, vData.city_type);
			EndIf;
			vAddressArr.Add(vCity);
			
			If Not TrimAll(AddressType) = "PlaceOfBirth" Then
				vStreet = "";
				If Not vData.street = Undefined And Not IsBlankString(vData.street) Then
					vStreet = vData.street + " " + vData.street_type;
				EndIf;
				vAddressArr.Add(vStreet);
				
				vHouse = "";
				If Not vData.house = Undefined And Not IsBlankString(vData.house) Then
					vHouse = vData.house;
				EndIf;
				
				If Not vData.block = Undefined And Not IsBlankString(vData.block) Then
					vHouse = vHouse + " "+ vData.block_type + vData.block;
				EndIf;	
				vAddressArr.Add(TrimAll(vHouse));
				
				vAddressArr.Add(vData.flat);
			EndIf;
			vAddress = TrimAll(StrConcat(vAddressArr, ", ")); 
			While StrEndsWith(vAddress,",") Or StrEndsWith(vAddress," ") And StrLen(vAddress) > 0 Do
				vAddress = Left(vAddress, StrLen(vAddress) - 1);
			EndDo;	
			vDataRow = vRow.data;
			vDataRow.Insert("Address", vAddress);
			pList.Add(vDataRow, vRow.unrestricted_value); 
		EndDo;
	EndIf;
EndProcedure //  FillAddresDadata

// ----------------------------------------------------------------------------------
&AtServerNoContext
Function GetAddressFromDadata(pText)
	Return cmGetDadataArrayApiV4(TrimAll(pText));
EndFunction //  GetAddressFromDadata

// ----------------------------------------------------------------------------------
&AtServerNoContext
Function GetAddressListFromDadata(pText)
	Return cmGetDataFromDadata(TrimAll(pText));
EndFunction	//  GetAddressListFromDadata

// ----------------------------------------------------------------------------------
&AtServer
Procedure SaveAddress(pDataAddress)
	// Parse address to fields
	vAddressFields = cmParseAddress(pDataAddress.Address);
	If ValueIsFilled(vAddressFields.Country) Then
		If Not IsBlankString(vAddressFields.Country.Description) Then
			Country = vAddressFields.Country;
		EndIf;
	EndIf;
	PostCode = vAddressFields.PostCode;
	Region = vAddressFields.Region;
	Area = vAddressFields.Area;
	City = vAddressFields.City;
	Street = vAddressFields.Street;
	House = vAddressFields.House;
	Flat = vAddressFields.Flat; 
	StreetFiasId = pDataAddress.street_fias_id;
	If IsBlankString(StreetFiasId) Then
		StreetFiasId = pDataAddress.settlement_fias_id;	
	EndIf;	
EndProcedure //  SaveAddress

#EndRegion
