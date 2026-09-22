
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		ReadOnly = True;
	EndIf;
	If ValueIsFilled(Record.BreakdownListFormula) Then
		Items.GroupFormulaParameters.Enabled = False;
	Else
		Items.GroupFormulaParameters.Enabled = True;
	EndIf;
	IsTaxAppearance();
	IsInRoomRevenueAppearance();
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	Notify("BreakDownListSettings.Update", , ThisObject);
EndProcedure // AfterWrite

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure PriceOnChange(pItem)
	PriceOnChangeAtServer();
EndProcedure // PriceOnChangeAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure ItemOnChange(pItem)
	ItemOnChangeAtServer();
EndProcedure // ItemOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure BreakdownListFormulaOnChange(pItem)
	BreakdownListFormulaOnChangeAtServer();
EndProcedure // BreakdownListFormulaOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure IsTaxOnChange(pItem)
	IsTaxAppearance();
EndProcedure // IsTaxOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure IsInRoomRevenueOnChange(pItem)
	IsInRoomRevenueAppearance();
EndProcedure // IsInRoomRevenueOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure IsNotInForecastOnChange(pItem)
	IsInRoomRevenueAppearance();
EndProcedure // IsNotInForecastOnChange

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure PriceOnChangeAtServer()
	If Record.Price <> 0 And Not ValueIsFilled(Record.Currency) Then
		If ValueIsFilled(Record.Hotel) Then
			Record.Currency = Record.Hotel.BaseCurrency;
		EndIf;
		If ValueIsFilled(SessionParameters.CurrentHotel) Then
			Record.Currency = SessionParameters.CurrentHotel.BaseCurrency;
		EndIf;
	EndIf;
EndProcedure // PriceOnChangeAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure ItemOnChangeAtServer()
	Items.GroupFormulaParameters.Enabled = False;
	If ValueIsFilled(Record.Item) Then
		If ValueIsFilled(Record.Item.BreakdownListFormula) Then
			Record.BreakdownListFormula = Record.Item.BreakdownListFormula;
		Else
			If Not ValueIsFilled(Record.BreakdownListFormula) Then
				Items.GroupFormulaParameters.Enabled = True;
			EndIf;
		EndIf;
	Else
		If Not ValueIsFilled(Record.BreakdownListFormula) Then
			Items.GroupFormulaParameters.Enabled = True;
		EndIf;
	EndIf;
EndProcedure // ItemOnChangeAtServer()

// --------------------------------------------------------------------------------
&AtServer
Procedure BreakdownListFormulaOnChangeAtServer()
	If ValueIsFilled(Record.BreakdownListFormula) Then
		Items.GroupFormulaParameters.Enabled = False;
	Else
		Items.GroupFormulaParameters.Enabled = True;
	EndIf;
EndProcedure // BreakdownListFormulaOnChangeAtServer()

// --------------------------------------------------------------------------------
&AtServer
Procedure IsTaxAppearance()
	If Record.IsTax Then
		Items.VATRate.Enabled = False;
		If ValueIsFilled(Record.VATRate) Then
			Record.VATRate = Undefined;
		EndIf;
	Else
		Items.VATRate.Enabled = True;
	EndIf;
EndProcedure // IsTaxAppearance

// --------------------------------------------------------------------------------
&AtServer
Procedure IsInRoomRevenueAppearance()
	If Not Record.IsInRoomRevenue Then
		Items.IsNotInForecast.Enabled = False;
		If Record.IsNotInForecast Then
			Record.IsNotInForecast = False;
		EndIf;
	Else
		Items.IsNotInForecast.Enabled = True;
	EndIf;
EndProcedure // IsInRoomRevenueAppearance

#EndRegion    
