
// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		ThisForm.ReadOnly = True;
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
	If Not ValueIsFilled(pCurrentObject.ServicePackage) Then
		pCancel = True;
		vUM = New UserMessage();
		vUM.SetData(pCurrentObject);
		vUM.Field = "ServicePackage";
		vUM.Text = NStr("en='Please fill service package!'; ru='Укажите пакет услуг!'; de='Geben Sie einen Paket von Dienstleistungen!'");
		vUM.Message();
	EndIf; 
EndProcedure // BeforeWriteAtServer 
