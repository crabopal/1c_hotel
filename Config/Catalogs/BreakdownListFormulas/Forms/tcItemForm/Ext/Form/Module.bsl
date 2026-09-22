
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		ReadOnly = True;
	EndIf;
	IsTaxAppearance();
	IsInRoomRevenueAppearance();
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

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

// --------------------------------------------------------------------------------
&AtClient
Procedure IsTaxOnChange(pItem)
	IsTaxAppearance();
EndProcedure // IsTaxOnChange

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure IsTaxAppearance()
	If Object.IsTax Then
		Items.VATRate.Enabled = False;
		If ValueIsFilled(Object.VATRate) Then
			Object.VATRate = Undefined;
		EndIf;
	Else
		Items.VATRate.Enabled = True;
	EndIf;
EndProcedure // IsTaxAppearance

// --------------------------------------------------------------------------------
&AtServer
Procedure IsInRoomRevenueAppearance()
	If Not Object.IsInRoomRevenue Then
		Items.IsNotInForecast.Enabled = False;
		If Object.IsNotInForecast Then
			Object.IsNotInForecast = False;
		EndIf;
	Else
		Items.IsNotInForecast.Enabled = True;
	EndIf;
EndProcedure // IsInRoomRevenueAppearance

#EndRegion

