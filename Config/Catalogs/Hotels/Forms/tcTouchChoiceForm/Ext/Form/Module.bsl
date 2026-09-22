
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not tcOnServer.cmIsInRole("RightsToChooseHotel") Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You have no rights for this operation!'; ru='Нет прав на это действие!'; de='Sie haben keine Rechte an dieser Aktion!'"));
		pCancel = True;
		Return;
	EndIf;	
	vHotels = Catalogs.Hotels.GetHotelAllowedList();
	If vHotels.Count() > 0 Then
		Parameters.Filter.Insert("Ref", vHotels);
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormTableListItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ListSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	vSelectedValue = Items.List.CurrentRow;
	If Parameters.Property("ChangeSessionParameter") And Parameters.ChangeSessionParameter 
		And ValueIsFilled(vSelectedValue) 
		And Not tcOnServer.cmGetAttributeByRef(vSelectedValue, "IsFolder") Then
		// Do change hotel
		tcOnServer.ChangeCurrentHotel(vSelectedValue);
		// Change application caption
		tcOnClient.ChangeApplicationCaption(vSelectedValue);
		// Close all windows
		If Parameters.Property("DoNotCloseAllWindows") And Not Parameters.DoNotCloseAllWindows Then
			tcCommonFunctionOnClientServer.cmCloseAllWindows();
		Endif;
		// Set functional options hotel parameter
		SetInterfaceFunctionalOptionParameters(New Structure("Hotel", vSelectedValue));
		// Refresh user interface
		RefreshInterface();
		// Notify hotel was changed
	 	Notify("System.Hotel.Changed", vSelectedValue, ThisForm);
	EndIf; 
EndProcedure // ListSelection

#EndRegion
