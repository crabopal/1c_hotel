
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not ValueIsFilled(Parameters.Client) Then
		pCancel = True;
	EndIf;
	SelClient = Parameters.Client;
	CustomersList.Parameters.SetParameterValue("qClient", SelClient);
EndProcedure

#EndRegion  

#Region FormTableListItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CustomersListSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	vCurData = Items.CustomersList.CurrentData;
	If vCurData <> Undefined Then
		OpenForm("Catalog.Customers.ObjectForm", New Structure("Key", vCurData.Customer), ThisForm, vCurData.Customer, , , , FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure // CustomersListSelection

#EndRegion
