// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not Parameters.Filter.Property("Hotel") Then
		Parameters.Filter.Insert("Hotel", SessionParameters.CurrentHotel);
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ListBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	pCancel = Not HaveRightsToManagePrices();
	If pCancel Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to manage prices!'; 
		                                                |ru='У вас нет прав на управление ценами!'; 
														|de='Sie haben keine Rechte zur Preisverwaltung!'"), 
		                                           MessageStatus.Attention);
	EndIf;
EndProcedure // ListBeforeAddRow

// --------------------------------------------------------------------------------
&AtClient
Procedure ListBeforeDeleteRow(pItem, pCancel)
	pCancel = Not HaveRightsToManagePrices();
	If pCancel Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to manage prices!'; 
		                                                |ru='У вас нет прав на управление ценами!'; 
														|de='Sie haben keine Rechte zur Preisverwaltung!'"), 
		                                           MessageStatus.Attention);
	EndIf;
EndProcedure // ListBeforeDeleteRow

// --------------------------------------------------------------------------------
&AtServerNoContext
Function HaveRightsToManagePrices()
	Return cmCheckUserPermissions("HavePermissionToManagePrices");
EndFunction // HaveRightsToManagePrices
