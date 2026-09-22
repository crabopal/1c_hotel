
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	SelHotel = SessionParameters.CurrentHotel;
	vArray = New Array;
	vArray.Add(SelHotel);
	vArray.Add(Catalogs.Hotels.EmptyRef());    
	Parameters.Filter.Insert("Hotel",vArray);
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtServerNoContext
Procedure CheckUserPermissions(pCancel)
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		pCancel = True;
	EndIf;
EndProcedure // CheckUserPermissions

#EndRegion

#Region FormTableItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ListBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	CheckUserPermissions(pCancel);
EndProcedure // ListBeforeAddRowAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure ListBeforeDeleteRow(pItem, pCancel)
	CheckUserPermissions(pCancel);
EndProcedure // ListBeforeDeleteRow

#EndRegion

