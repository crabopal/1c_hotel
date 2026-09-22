
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Check user rights to use item
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		ReadOnly = True;
	EndIf;
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	// Initialization
	If Not ValueIsFilled(Record.Service) Then
		Record.Period = CurrentSessionDate();
		Record.Hotel = SessionParameters.CurrentHotel;
		If ValueIsFilled(Record.Hotel) Then 
			Record.Currency = Record.Hotel.BaseCurrency;
			If ValueIsFilled(Record.Hotel.Company) And ValueIsFilled(Record.Hotel.Company.VATRate) Then
				Record.VATRate = Record.Hotel.Company.VATRate;
			EndIf;
		EndIf;
	EndIf;
	If Not Record.IsPricePerHour And Not Record.IsPricePerMinute And Not Record.IsPricePerDay Then
		Record.IsPricePerHour = True;
	EndIf;
	// Fill client types choice list
	vClientTypesList = GetClientTypes();
	If vClientTypesList.FindByValue(Record.ClientType) = Undefined Then
		vClientTypesList.Add(Record.ClientType);
	EndIf;
	Items.ClientType.ChoiceList.Clear();
	For Each vClientTypesListItem In vClientTypesList Do
		Items.ClientType.ChoiceList.Add(vClientTypesListItem.Value, vClientTypesListItem.Presentation);
	EndDo;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ServiceOnChange(pItem)
	ServiceOnChangeAtServer();
EndProcedure // ServiceOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure ResourceOnChange(pItem)
	If ValueIsFilled(Record.Resource) Then
		Record.ResourceType = tcOnServer.cmGetAttributeByRef(Record.Resource, "Owner");
	EndIf;
EndProcedure // ResourceOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure IsPricePerHourOnChange(Item)
	If Not Record.IsPricePerHour And Not Record.IsPricePerMinute And Not Record.IsPricePerDay Then
		Record.IsPricePerHour = True;
	EndIf;
	If Record.IsPricePerHour Then
		Record.IsPricePerMinute = False;
		Record.IsPricePerDay = False;
	EndIf;
EndProcedure // IsPricePerHourOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure IsPricePerMinuteOnChange(pItem)
	If Not Record.IsPricePerHour And Not Record.IsPricePerMinute And Not Record.IsPricePerDay Then
		Record.IsPricePerMinute = True;
	EndIf;
	If Record.IsPricePerMinute Then
		Record.IsPricePerHour = False;
		Record.IsPricePerDay = False;
	EndIf;
EndProcedure // IsPricePerMinuteOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure IsPricePerDayOnChange(pItem)
	If Not Record.IsPricePerHour And Not Record.IsPricePerMinute And Not Record.IsPricePerDay Then
		Record.IsPricePerDay = True;
	EndIf;
	If Record.IsPricePerDay Then
		Record.IsPricePerHour = False;
		Record.IsPricePerMinute = False;
	EndIf;
EndProcedure // IsPricePerDayOnChange

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure ServiceOnChangeAtServer()
	If ValueIsFilled(Record.Service) Then
		vService = Record.Service;
		Record.IsResourceRevenue = vService.IsResourceRevenue;
		Record.IsPricePerPerson = vService.ChargePerPerson;
		Record.IsPricePerMinute = vService.IsPricePerMinute;
		If Record.IsPricePerMinute Then
			Record.IsPricePerHour = False;
			Record.IsPricePerDay = False;
		EndIf;
		vServiceObj = vService.GetObject();
		vAttributes = vServiceObj.pmGetServicePrices(Record.Hotel, Record.Period, Record.ClientType);
		If vAttributes.Count() > 0 Then
			vAttributesRow = vAttributes.Get(0);
			Record.Currency = vAttributesRow.Currency;
			Record.VATRate = vAttributesRow.VATRate;
		EndIf;
	EndIf;
EndProcedure // ServiceOnChangeAtServer

// --------------------------------------------------------------------------------
&AtServer
Function GetClientTypes()
	vClientTypesList = New ValueList();
	vClientTypesList.Add(Catalogs.ClientTypes.EmptyRef(), NStr("en='<Empty client type>'; ru='<Пустой тип клиента>'; de='<Leerer Clienttyp>'"));
	// Read first level client types only
	vHotel = ?(ValueIsFilled(Record.Hotel), Record.Hotel, SessionParameters.CurrentHotel);
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ClientTypes.Ref AS ClientType,
	|	ClientTypes.IsFolder AS IsFolder,
	|	ClientTypes.Code AS Code,
	|	ClientTypes.Description AS Description,
	|	ClientTypes.SortCode AS SortCode
	|FROM
	|	Catalog.ClientTypes AS ClientTypes
	|WHERE
	|	ClientTypes.DeletionMark = FALSE
	|	AND ClientTypes.Parent = &qEmptyClientType
	|	AND (NOT &qHotelIsEmptyRef
	|				AND ClientTypes.Hotel = &qHotel
	|			OR ClientTypes.Hotel = &qEmptyHotel
	|			OR &qHotelIsEmptyRef)
	|
	|ORDER BY
	|	SortCode,
	|	Description";
	vQry.SetParameter("qHotel", vHotel);
	vQry.SetParameter("qHotelIsEmptyRef", Not ValueIsFilled(vHotel));
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qEmptyClientType", Catalogs.ClientTypes.EmptyRef());
	vElements = vQry.Execute().Unload();
	// Check user permissions
	vPermissionGroup = cmGetEmployeePermissionGroup(SessionParameters.CurrentUser);
	If ValueIsFilled(vPermissionGroup) Then
		If vPermissionGroup.ClientTypesAllowed.Count() > 0 Then
			vInt = 0;
			While vInt < vElements.Count() Do
				vRow = vElements.Get(vInt);
				If Not vRow.IsFolder And vPermissionGroup.ClientTypesAllowed.Find(vRow.ClientType, "ClientType") = Undefined Then
					vElements.Delete(vInt);
				Else
					vInt = vInt + 1;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	For Each vElementsRow in vElements Do
		vClientTypesList.Add(vElementsRow.ClientType);
	EndDo;
	Return vClientTypesList;
EndFunction // GetClientTypes 

#EndRegion
