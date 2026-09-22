#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	RefreshFrom();	
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ExchangePlanDeliveryTypeOnChange(pItem)
	RefreshFrom();
EndProcedure // ExchangePlanDeliveryTypeOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure OnlineSyncIsActiveOnChange(pItem)
	RefreshFrom();
EndProcedure // OnlineSyncIsActiveOnChange

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure RefreshFrom()
	Items.GroupSendSettingsPages.Visible = True;
	If Object.ExchangePlanDeliveryType = Enums.ExchangePlanDeliveryTypes.Local Then
		Items.GroupSendSettingsPages.CurrentPage = Items.GroupLocal;	
	ElsIf Object.ExchangePlanDeliveryType = Enums.ExchangePlanDeliveryTypes.FTP Then
		Items.GroupSendSettingsPages.CurrentPage = Items.GroupFTP;	
	ElsIf Object.ExchangePlanDeliveryType = Enums.ExchangePlanDeliveryTypes.WebService Then
		Items.GroupSendSettingsPages.CurrentPage = Items.GroupWebService;
	ElsIf Object.ExchangePlanDeliveryType = Enums.ExchangePlanDeliveryTypes.HTTP Then
		Items.GroupSendSettingsPages.CurrentPage = Items.GroupHTTP; 
	Else
		Items.GroupSendSettingsPages.Visible = False;	
	EndIf;           
	Items.GroupSettingsPages.ReadOnly = Not Object.OnlineSyncIsActive; 
	Items.GroupCheck.ReadOnly = Not Object.OnlineSyncIsActive;
EndProcedure // RefreshFrom

#EndRegion