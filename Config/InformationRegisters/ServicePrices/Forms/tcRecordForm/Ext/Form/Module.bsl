
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		ReadOnly = True;
	EndIf;
	// Initialization
	If Not ValueIsFilled(Record.VATRate) Then
		Record.Period = CurrentSessionDate();
		Record.Hotel = SessionParameters.CurrentHotel;
		If ValueIsFilled(Record.Hotel) Then 
			Record.Currency = Record.Hotel.BaseCurrency;
			If ValueIsFilled(Record.Hotel.Company) And ValueIsFilled(Record.Hotel.Company.VATRate) Then
				Record.VATRate = Record.Hotel.Company.VATRate;
			EndIf;
		EndIf;
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

// --------------------------------------------------------------------------------
&AtClient
Procedure OnClose(Exit)
	Notify("System.ServicePrices.Write", , ThisObject);
EndProcedure

#EndRegion

#Region Private

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

&AtServer
Procedure FillCheckProcessingAtServer(pCancel, pCheckedAttributes)
	If Not ValueIsFilled(Record.Hotel) Then   
		vErr = NStr("en = 'The hotel is not filled'; de = 'Das Hotel ist nicht belegt'; ru = 'Не заполнена гостиница'");
		tcCommonFunctionOnClientServer.UserMessage(vErr, Record, "Record.Hotel", , True);
		pCancel = True;
	EndIf;	
EndProcedure

#EndRegion
