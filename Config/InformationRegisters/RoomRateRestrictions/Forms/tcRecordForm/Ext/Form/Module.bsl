
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Check user rights to use item
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		pCancel = True;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights for services and prices management!';ru='Нет прав на управление услугами и ценами!';de='Sie haben keine Rechte, Dienstleistungen und Preise zu verwalten!'"));
	EndIf;
	If Not ValueIsFilled(Record.Hotel) Then
		Record.Hotel = SessionParameters.CurrentHotel;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	pCurrentObject.Timestamp = CurrentSessionDate();
EndProcedure // BeforeWriteAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	If ValueIsFilled(pCurrentObject.RoomRate) Then
		vRoomRateObj = pCurrentObject.RoomRate.GetObject();
		vRoomRateObj.LimitsLastChangeDate = CurrentSessionDate();
		vRoomRateObj.Write();
		vRoomRateObj.pmWriteToRoomRateChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
	EndIf;
EndProcedure // AfterWriteAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure ClearAllRestrictions(pCommand)
	Record.CTA = False;
	Record.CTD = False;
	Record.StopSale = False;
	Record.MaxDaysBeforeCheckIn = 0;
	Record.MinDaysBeforeCheckIn = 0;
	Record.MaxLOS = 0;
	Record.MLOS = 0;
EndProcedure // ClearAllRestrictions

#EndRegion
