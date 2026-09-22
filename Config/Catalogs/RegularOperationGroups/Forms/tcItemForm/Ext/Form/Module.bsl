
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Check user rights to edit item
	If Not cmCheckUserPermissions("HavePermissionToManageHousekeeping") Then
		If Not ValueIsFilled(Object.Ref) Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to edit housekeeping settings!';ru='Нет прав на управление службой горничных!';de='Sie haben keine Rechte, die Einstellungen des Reinigungsdienstes zu verwalten!'"));
			Return;
		Else
			ThisForm.ReadOnly = True;
		EndIf;
	EndIf;
	// Initialize hotel
	tcOnServer.cmInitHotel(Object);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	For Each vRow In Object.RegularOperations Do
		If Not ValueIsFilled(vRow.RegularOperation) Then
			ShowMessageBox(, NStr("en='Regular operation is not set in line " + vRow.LineNumber + "!'; de='Der reguläre Betrieb ist nicht in Zeile gesetzt (" + vRow.LineNumber + ")!'; ru='В строке " + vRow.LineNumber + " не указана регламентная работа!'"));
			pCancel = True;
			Return;
		EndIf;
		If vRow.RegularOperationFrequency = 0 Then
			ShowMessageBox(, NStr("en='Regular operation periodicity is not set in line " + vRow.LineNumber + "!'; de='Der reguläre Betrieb Periodizität ist nicht in Zeile gesetzt (" + vRow.LineNumber + ")!'; ru='В строке " + vRow.LineNumber + " не указана периодичность выполнения регламентной работы!'"));
			pCancel = True;
			Return;
		EndIf;
	EndDo;
EndProcedure // BeforeWrite



#EndRegion               

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure RegularOperationsRegularOperationOnChange(pItem)
	vCurRow = Items.RegularOperations.CurrentData;
	If vCurRow <> Undefined Then
		If ValueIsFilled(vCurRow.RegularOperation) Then
			vCurRow.PerformWhenRoomIsBusy = tcOnServer.cmGetAttributeByRef(vCurRow.RegularOperation, "IsRegularCleaning");
			vCurRow.IsPerGuest = tcOnServer.cmGetAttributeByRef(vCurRow.RegularOperation, "IsPerGuest");
		EndIf;
	EndIf;
EndProcedure // RegularOperationsRegularOperationOnChange

#EndRegion
