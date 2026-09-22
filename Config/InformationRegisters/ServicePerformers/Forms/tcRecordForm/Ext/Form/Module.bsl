
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		ThisForm.ReadOnly = True;
	EndIf;
	If Not ValueIsFilled(Record.Hotel) And Not ValueIsFilled(Record.Service) And IsBlankString(Record.Employee) Then
		Record.Hotel = SessionParameters.CurrentHotel;
	EndIf;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	SetObjectAndFormAttributeConformity(pCurrentObject, "Record");
	If Not ValueIsFilled(pCurrentObject.Service) Then
		pCancel = True;
		vUM = New UserMessage();
		vUM.SetData(pCurrentObject);
		vUM.Field = "Service";
		vUM.Text = NStr("en='Please fill service!'; ru='Укажите услугу!'; de='Geben Sie einen Dienst!'");
		vUM.Message();
	EndIf;
	If Not ValueIsFilled(pCurrentObject.Employee) Then
		pCancel = True;
		vUM = New UserMessage();
		vUM.SetData(pCurrentObject);
		vUM.Field = "Employee";
		vUM.Text = NStr("en='Please fill employee!'; ru='Укажите сотрудника!'; de='Geben Sie einen Mitarbeiters!'");
		vUM.Message();
	EndIf;
EndProcedure // BeforeWriteAtServer

#EndRegion
