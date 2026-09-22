
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	RowID = -1;
	If Parameters.Property("RowID") Then
		RowID = Parameters.RowID;
		Period = Parameters.Period;
		ClientType = Parameters.ClientType;
		RoomClass = Parameters.RoomClass;
		RoomClassExcluding = Parameters.RoomClassExcluding;
		RoomType = Parameters.RoomType;
		RoomTypeExcluding = Parameters.RoomTypeExcluding;
		AccommodationType = Parameters.AccommodationType;
		AccommodationTypeExcluding = Parameters.AccommodationTypeExcluding;
		Service = Parameters.Service;
		Price = Parameters.Price;
		Currency = Parameters.Currency;
		Quantity = Parameters.Quantity;
		Unit = Parameters.Unit;
		VATRate = Parameters.VATRate;
		Remarks = Parameters.Remarks;
		IsInPrice = Parameters.IsInPrice;
		IsServicePerPerson = Parameters.IsServicePerPerson;
		QuantityCalculationRule = Parameters.QuantityCalculationRule;
		CalendarDayType = Parameters.CalendarDayType;
		AccountingDate = Parameters.AccountingDate;
		AccountingDayNumber = Parameters.AccountingDayNumber;
		PeriodFrom = Parameters.PeriodFrom;
		PeriodTo = Parameters.PeriodTo;
		Hotel = Parameters.Hotel;
		
		Title = NStr("en = 'Row editing'; de = 'Zeile bearbeiten'; ru = 'Редактирование строки'");
	ElsIf Parameters.Property("Period") Then
		Period = Parameters.Period;
		ClientType = Parameters.ClientType;
		Quantity = 1;
		AccountingDayNumber = 1;
		QuantityCalculationRule = Undefined;
		AccountingDate = '00010101';
		
		Title = NStr("en = 'New row'; de = 'Neue Zeile'; ru = 'Новая строка'");
	Else
		Title = NStr("en = 'New row'; de = 'Neue Zeile'; ru = 'Новая строка'");
	EndIf;
	
	If Parameters.Property("ReadOnly") And Parameters.ReadOnly Then
		ReadOnly = True;
	EndIf;

	If AccommodationType.Count() = 0 Then
		Items.AccommodationType.InputHint = NStr("en='<for all>'; ru='<для любых>'; de='<für alle>'");
	Else
		Items.AccommodationType.InputHint = "";
	EndIf;
	If RoomType.Count() = 0 Then
		Items.RoomType.InputHint = NStr("en='<for all>'; ru='<для любых>'; de='<für alle>'");
	Else
		Items.RoomType.InputHint = "";
	EndIf;
	If RoomClass.Count() = 0 Then
		Items.RoomClass.InputHint = NStr("en='<for all>'; ru='<для любых>'; de='<für alle>'");
	Else
		Items.RoomClass.InputHint = "";
	EndIf;                 
	vClientTypes = GetClientTypes();
	Items.ClientType.ChoiceList.Add(Catalogs.ClientTypes.EmptyRef(), NStr("en = '<Empty client type>'; de = '<Leerer Kundentyp!>'; ru = '<Пустой тип клиента>'"), , PictureLib.Adult);	
	For Each vClientTypesRow In vClientTypes Do
		Items.ClientType.ChoiceList.Add(vClientTypesRow.ClientType, TrimAll(vClientTypesRow.Description), , ?(vClientTypesRow.IsFolder, PictureLib.HierarchicalView, PictureLib.Adult));
	EndDo;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ServiceOnChange(pItem)
	ServiceOnChangeAtServer();
EndProcedure 

// -----------------------------------------------------------------------------
&AtClient
Procedure FilterItemStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	
	vExtraAttrs = New Structure;
	vExtraAttrs.Insert("Name", pItem.Name);
	vOnCloseNotifyDescription = New NotifyDescription("OnListSelectionFormClose", ThisObject, vExtraAttrs);

	vParams = New Structure;
	vParams.Insert("Name", pItem.Name);
	If pItem.Name = "RoomType" Then
		vParams.Insert("List", GetRoomTypes());
	ElsIf pItem.Name = "RoomClass" Then
		vParams.Insert("List", GetRoomClasses());
	ElsIf pItem.Name = "AccommodationType" Then
		vParams.Insert("List", GetAccommodationTypes());
	ElsIf pItem.Name = "RoomClassExcluding" Then
		vParams.Insert("List", GetRoomClasses(True));
	ElsIf pItem.Name = "RoomTypeExcluding" Then
		vParams.Insert("List", GetRoomTypes(True));
	ElsIf pItem.Name = "AccommodationTypeExcluding" Then
		vParams.Insert("List", GetAccommodationTypes(True));
	EndIf;

	OpenForm("Catalog.ServicePackages.Form.tcChooseFromListForm", vParams, ThisObject, , , , vOnCloseNotifyDescription, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // FilterItemStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure QuantityCalculationRuleOnChange(pItem)
	If ValueIsFilled(QuantityCalculationRule) Then
		If AccountingDayNumber <> 0 Then
			AccountingDayNumber = 0;
		EndIf;
		If ValueIsFilled(AccountingDate) Then
			AccountingDate = '00010101';
		EndIf;
	EndIf;
EndProcedure // QuantityCalculationRuleOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AccountingDayNumberOnChange(pItem)
	If AccountingDayNumber <> 0 Then
		If ValueIsFilled(QuantityCalculationRule) Then
			QuantityCalculationRule = Undefined;
		EndIf;
		If ValueIsFilled(AccountingDate) Then
			AccountingDate = '00010101';
		EndIf;
	EndIf;
EndProcedure // AccountingDayNumberOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AccountingDateOnChange(pItem)
	If ValueIsFilled(AccountingDate) Then
		If ValueIsFilled(QuantityCalculationRule) Then
			QuantityCalculationRule = Undefined;
		EndIf;
		If AccountingDayNumber <> 0 Then
			AccountingDayNumber = 0;
		EndIf;
	EndIf;
EndProcedure // AccountingDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AccommodationTypeClearing(pItem, pStandardProcessing)
	pItem.InputHint = NStr("en='<for all>'; ru='<для любых>'; de='<für alle>'");
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypeClearing(pItem, pStandardProcessing)
	pItem.InputHint = NStr("en='<for all>'; ru='<для любых>'; de='<für alle>'");
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomClassClearing(pItem, pStandardProcessing)
	pItem.InputHint = NStr("en='<for all>'; ru='<для любых>'; de='<für alle>'");
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveRowData(pCommand)
	If CheckFormDataAtServer() Then
		Return;
	EndIf;
	
	pParams = New Structure;
	pParams.Insert("RowID", RowID);
	pParams.Insert("Period", Period);
	pParams.Insert("ClientType", ClientType);
	pParams.Insert("RoomClass", RoomClass);
	pParams.Insert("RoomClassExcluding", RoomClassExcluding);
	pParams.Insert("RoomType", RoomType);
	pParams.Insert("RoomTypeExcluding", RoomTypeExcluding);
	pParams.Insert("AccommodationType", AccommodationType);
	pParams.Insert("AccommodationTypeExcluding", AccommodationTypeExcluding);
	pParams.Insert("Service", Service);
	pParams.Insert("Price", Price);
	pParams.Insert("Currency", Currency);
	pParams.Insert("Quantity", Quantity);
	pParams.Insert("Unit", Unit);
	pParams.Insert("VATRate", VATRate);
	pParams.Insert("Remarks", Remarks);
	pParams.Insert("IsInPrice", IsInPrice);
	pParams.Insert("IsServicePerPerson", IsServicePerPerson);
	pParams.Insert("QuantityCalculationRule", QuantityCalculationRule);
	pParams.Insert("CalendarDayType", CalendarDayType);
	pParams.Insert("AccountingDate", AccountingDate);
	pParams.Insert("AccountingDayNumber", AccountingDayNumber);
	pParams.Insert("PeriodFrom", PeriodFrom);
	pParams.Insert("PeriodTo", PeriodTo);

	Close(pParams); 
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure ServiceOnChangeAtServer()
	If ValueIsFilled(Service) Then
		vHotel = ?(ValueIsFilled(Hotel), Hotel,SessionParameters.CurrentHotel);
		vCurPrice = 0;
		vCurUnit = Service.Unit;
		vCurCurrency = Currency;
		vCurVATRate = VATRate;
		vSrvPrices = Service.GetObject().pmGetServicePrices(vHotel, ?(ValueIsFilled(AccountingDate), AccountingDate, CurrentSessionDate()), 
		                                                            Catalogs.ClientTypes.EmptyRef()); 
		For Each vSrvPricesRow In vSrvPrices Do
			vCurPrice = vSrvPricesRow.Price;
			vCurUnit = Service.Unit;
			vCurCurrency = vSrvPricesRow.Currency;
			VCurVATRate = vSrvPricesRow.VATRate;
			Break;
		EndDo;
		Price = vCurPrice;
		Currency = vCurCurrency;
		Unit = vCurUnit;
		VATRate = vCurVATRate;
		IsServicePerPerson = Service.ChargePerPerson;
		IsInPrice = Service.IsInPrice;
		QuantityCalculationRule =Service.QuantityCalculationRule;
		If Quantity = 0 Then
			Quantity = 1;
		EndIf;
		If AccountingDayNumber = 0 And 
		   Not ValueIsFilled(QuantityCalculationRule)  
		   And Not ValueIsFilled(AccountingDate) Then
			AccountingDayNumber = 1;
		ElsIf ValueIsFilled(QuantityCalculationRule) Then
			AccountingDate = '00010101';
			AccountingDayNumber = 0;
		EndIf;
		If Not ValueIsFilled(Currency) And ValueIsFilled(SessionParameters.CurrentHotel) Then
			Currency = SessionParameters.CurrentHotel.BaseCurrency;
		EndIf;
		If Not ValueIsFilled(VATRate) And ValueIsFilled(SessionParameters.CurrentHotel) Then
			If ValueIsFilled(SessionParameters.CurrentHotel.Company) Then
				VATRate = SessionParameters.CurrentHotel.Company.VATRate;
			EndIf;
		EndIf;
		// Fill service composition
		If Not IsBlankString(Service.Composition) Then
			Remarks = TrimAll(Service.Composition);
		EndIf;
	EndIf;
EndProcedure // ServiceOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Function GetRoomTypes(pExcluding = False)
	If pExcluding Then
		vList = RoomTypeExcluding;
	Else
		vList = RoomType;
	EndIf;
	vNewArray = New Array;
	For Each vListItem In vList Do
		vNewArray.Add(vListItem.Value);
	EndDo;
	Return vNewArray;
EndFunction

// -----------------------------------------------------------------------------
&AtClient
Function GetRoomClasses(pExcluding = False)
	If pExcluding Then
		vList = RoomClassExcluding;
	Else
		vList = RoomClass;
	EndIf;
	vNewArray = New Array;
	For Each vListItem In vList Do
		vNewArray.Add(vListItem.Value);
	EndDo;
	Return vNewArray;
EndFunction

// -----------------------------------------------------------------------------
&AtClient
Function GetAccommodationTypes(pExcluding = False)
	If pExcluding Then
		vList = AccommodationTypeExcluding;
	Else
		vList = AccommodationType;
	EndIf;
	vNewArray = New Array;
	For Each vListItem In vList Do
		vNewArray.Add(vListItem.Value);
	EndDo;
	Return vNewArray;
EndFunction

// -----------------------------------------------------------------------------
&AtClient
Procedure OnListSelectionFormClose(pParameter, pExtraAttrs) Export
	If pParameter <> Undefined Then
		If pExtraAttrs.Name = "RoomType" Then 
			RoomType.Clear();
			For Each vRow In pParameter Do
				RoomType.Add(vRow.Value);
			EndDo;
			If ValueIsFilled(RoomType) Then
				RoomClass.Clear();
				RoomTypeExcluding.Clear();
			EndIf;
		ElsIf pExtraAttrs.Name = "RoomClass" Then
			RoomClass.Clear();
			For Each vRow In pParameter Do
				RoomClass.Add(vRow.Value);
			EndDo;
			If ValueIsFilled(RoomClass) Then
				RoomType.Clear();
				RoomClassExcluding.Clear();
			EndIf;
		ElsIf pExtraAttrs.Name = "AccommodationType" Then
			AccommodationType.Clear();
			For Each vRow In pParameter Do
				AccommodationType.Add(vRow.Value);
			EndDo;
			If ValueIsFilled(AccommodationType) Then
				RoomTypeExcluding.Clear();
			EndIf;
		ElsIf pExtraAttrs.Name = "RoomTypeExcluding" Then 
			RoomTypeExcluding.Clear();
			If pParameter.Count() > 1 Then
				RoomType.Clear();
				For Each vRow In pParameter Do
					RoomType.Add(vRow.Value);
				EndDo;
				If ValueIsFilled(RoomType) Then
					RoomClass.Clear();
					RoomTypeExcluding.Clear();
				EndIf;
			Else
				For Each vRow In pParameter Do
					RoomTypeExcluding.Add(vRow.Value);
				EndDo;
				If ValueIsFilled(RoomTypeExcluding) Then 
					RoomClassExcluding.Clear();
					RoomType.Clear();
				EndIf;
			EndIf;
		ElsIf pExtraAttrs.Name = "RoomClassExcluding" Then
			RoomClassExcluding.Clear();
			If pParameter.Count() > 1 Then
				RoomClass.Clear();
				For Each vRow In pParameter Do
					RoomClass.Add(vRow.Value);
				EndDo;
				If ValueIsFilled(RoomClass) Then
					RoomType.Clear();
					RoomClassExcluding.Clear();
				EndIf;
			Else
				For Each vRow In pParameter Do
					RoomClassExcluding.Add(vRow.Value);
				EndDo;
				If ValueIsFilled(RoomClassExcluding) Then
					RoomClass.Clear();
					RoomTypeExcluding.Clear();
				EndIf;
			EndIf;
		ElsIf pExtraAttrs.Name = "AccommodationTypeExcluding" Then
			AccommodationTypeExcluding.Clear();
			If pParameter.Count() > 1 Then
				AccommodationType.Clear();
				For Each vRow In pParameter Do
					AccommodationType.Add(vRow.Value);
				EndDo;
				If ValueIsFilled(AccommodationType) Then
					AccommodationTypeExcluding.Clear();
				EndIf;
			Else
				For Each vRow In pParameter Do
					AccommodationTypeExcluding.Add(vRow.Value);
				EndDo;
				If ValueIsFilled(AccommodationTypeExcluding) Then 
					AccommodationType.Clear();
				EndIf;
			EndIf;
		EndIf;
		If AccommodationType.Count() = 0 Then
			Items.AccommodationType.InputHint = NStr("en='<for all>'; ru='<для любых>'; de='<für alle>'");
		Else
			Items.AccommodationType.InputHint = "";
		EndIf;
		If RoomType.Count() = 0 Then
			Items.RoomType.InputHint = NStr("en='<for all>'; ru='<для любых>'; de='<für alle>'");
		Else
			Items.RoomType.InputHint = "";
		EndIf;
		If RoomClass.Count() = 0 Then
			Items.RoomClass.InputHint = NStr("en='<for all>'; ru='<для любых>'; de='<für alle>'");
		Else
			Items.RoomClass.InputHint = "";
		EndIf;
		Modified = True;
	EndIf;
EndProcedure // OnListSelectionFormClose

// -----------------------------------------------------------------------------
&AtServer
Function CheckFormDataAtServer()
	vRowHasErrors = False;
	If Not ValueIsFilled(Period) Then
		vUM = New UserMessage();
		vUM.Field = "Period";
		vUM.Text = NStr("en = 'Price creation date should be filled!'; de = 'Preiserstellungsdatum sollte ausgefüllt werden!'; ru = 'Дата создания цены должна быть заполнена!'");
		vUM.Message();
		vRowHasErrors = True;
	EndIf;
	If ValueIsFilled(AccountingDate) Then
		If ValueIsFilled(PeriodFrom) Then
			PeriodFrom = '00010101';
		EndIf;
		If ValueIsFilled(PeriodTo) Then
			PeriodTo = '00010101';
		EndIf;
	EndIf;
	If ValueIsFilled(PeriodTo) Then
		If PeriodTo < PeriodFrom Then
			PeriodTo = '00010101';
			vUM = New UserMessage();
			vUM.Field = "PeriodTo";
			vUM.Text = NStr("en = 'Service period was wrong! End of period date was cleared.'; 
							|de = 'Periode war falsch! Das Datum des Periodenendes wurde geklärt.'; 
							|ru = 'Период действия строки был указан неверно! Дата окончания периода действия была очищена.'");
			vUM.Message();
			vRowHasErrors = True;
		EndIf;
	EndIf;
	If Not ValueIsFilled(Service) Then
		vUM = New UserMessage();
		vUM.Field = "Service";
		vUM.Text = NStr("en='Service should be filled!'; ru='Услуга должна быть заполнена!'; de='Dienstleistung sollte ausgefüllt werden!'");
		vUM.Message();
		vRowHasErrors = True;
	EndIf;
	If Not ValueIsFilled(Currency) Then
		vUM = New UserMessage();
		vUM.Field = "Currency";
		vUM.Text = NStr("en='Currency should be filled!'; ru='Валюта должна быть заполнена!'; de='Währung sollte ausgefüllt werden!'");
		vUM.Message();
		vRowHasErrors = True;
	EndIf;
	If Not ValueIsFilled(VATRate) Then
		vUM = New UserMessage();
		vUM.Field = "VATRate";
		vUM.Text = NStr("en='VAT rate should be filled!'; ru='Ставка НДС должна быть заполнена!'; de='Mw.St. sollte ausgefüllt werden!'");
		vUM.Message();
		vRowHasErrors = True;
	EndIf;
	If Quantity <= 0 Then
		Quantity = 0;
		vUM = New UserMessage();
		vUM.Field = "Quantity";
		vUM.Text = NStr("en='Quantity should be greater then 0!'; ru='Количество должно быть больше 0!'; de='Menge sollte größer als 0 sein!'");
		vUM.Message();
		vRowHasErrors = True;
	EndIf;
	Return vRowHasErrors;
EndFunction // CheckFormDataAtServer

// --------------------------------------------------------------------------------
&AtServer
Function GetClientTypes()
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
	vQry.SetParameter("qHotel", ?(Hotel = Catalogs.Hotels.EmptyRef(), SessionParameters.CurrentHotel, Hotel));
	vQry.SetParameter("qHotelIsEmptyRef", ?(Hotel = Catalogs.Hotels.EmptyRef(), True, False));
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
	Return vElements;
EndFunction // GetClientTypes 

#EndRegion   
