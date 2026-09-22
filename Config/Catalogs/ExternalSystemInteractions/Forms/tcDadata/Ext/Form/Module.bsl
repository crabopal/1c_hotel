#Region FormEventHandlers

&AtServer
Procedure OnReadAtServer(pCurrentObject)
	LoadFieldsDadata();
EndProcedure

&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	SaveFieldsDadata();
EndProcedure

#EndRegion

#Region FormItemsEventHandlers

&AtClient
Procedure DecorationRegistrationClick(Item)
	GotoURL("https://dadata.ru/?ref=1470#registration_popup");
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SaveFieldsDadata()
	// Before write delete all records for "DADATA"
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.Ref, "Dadata");
			
	InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, "Dadata", "FillBank", 		Undefined, Undefined, FillBank);					
	InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, "Dadata", "FillCustomers", Undefined, Undefined, FillCustomers);
	InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, "Dadata", "FillAddress", 	Undefined, Undefined, FillAddress);

EndProcedure

&AtServer
Procedure LoadFieldsDadata()
	vDadataFields = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.Ref, "Dadata");

	If vDadataFields.Count() > 0 Then
		vRow =  vDadataFields[0];
		FillBank 		= vRow.FillBank;
		FillCustomers 	= vRow.FillCustomers;
		FillAddress  	= vRow.FillAddress;
	EndIf;
EndProcedure	

#EndRegion