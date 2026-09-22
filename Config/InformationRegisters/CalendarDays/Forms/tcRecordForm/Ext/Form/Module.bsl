
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		If Not ValueIsFilled(Record.Period) Then
			pCancel = True;
		Else
			ReadOnly = True;
		EndIf;
	EndIf;
	If Not ValueIsFilled(Record.Period) Then
		Record.Period = CurrentSessionDate();
	EndIf;		
	If Not ValueIsFilled(Record.Author) Then
		Record.Author = SessionParameters.CurrentUser;
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	If Not Modified Then
		pCancel = True;
		Close();
	EndIf;	
EndProcedure // BeforeWrite

// --------------------------------------------------------------------------------
&AtServer
Procedure RoomPriceOnChangeAtServer()
	If Not ValueIsFilled(Record.RoomPriceCurrency) And ValueIsFilled(SessionParameters.CurrentHotel) Then
		Record.RoomPriceCurrency = SessionParameters.CurrentHotel.FolioCurrency;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomPriceOnChange(pItem)
	RoomPriceOnChangeAtServer();
EndProcedure

#EndRegion
