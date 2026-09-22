
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	
	// Load DP parameters
	Obj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If ThisForm.Parameters.Property("DataProcessor", vDataProcessor) Then
		Obj.DataProcessor = vDataProcessor;
	Else
		vDataProcessor = Catalogs.DataProcessors.FindByAttribute("Processing","SquirrelPOS");
		If vDataProcessor = Catalogs.DataProcessors.EmptyRef() Then
			vNewDP 				= Catalogs.DataProcessors.CreateItem();
			vNewDP.Description 	= "SquirrelPOS";
			vNewDP.Key 			= "SquirrelPOS";
			vNewDP.Processing 	= "SquirrelPOS";
			vNewDP.Write();
			vDataProcessor = vNewDP.Ref;
		EndIf;
		
		Obj.DataProcessor = vDataProcessor;
	EndIf;
	
	vInteractionParameters = Catalogs.ExternalSystemInteractions.EmptyRef();
	If Parameters.Property("InteractionParameters", vInteractionParameters) Then
		Obj.InteractionParameters = vInteractionParameters;
	EndIf;
	Obj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(Obj,"Object");

	If ValueIsFilled(Object.InteractionParameters) Then
		LoadInteractionParameters();
		LoadServices();
		LoadDepartments();
		LoadPaymentMethodsTable();
	EndIf;
	
EndProcedure

#Region Save_Load

&AtClient
Procedure Save(pCommand)
	
	Save_AtServer();
	
EndProcedure

&AtServer
Function Save_AtServer()
	
	If NOT CheckFilling() Then
		Return False;
	EndIf;
	
	For each vRow in Services Do
		If NOT ValueIsFilled(vRow.Service) Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'All services should be filled!'; de = 'All services should be filled!'; ru = 'Все услуги должны быть заполнены!'"));
			Return False;
		EndIf;
	EndDo;
		
	BeginTransaction();
	
	Try
		SaveInteractionParameters();	
		SaveServices();
		SaveDepartments();
		SavePaymentMethodsTable();
		
		// Save DP parameters
		Obj = FormAttributeToValue("Object");
		Obj.pmSaveDataProcessorAttributes();
	Except
		RollbackTransaction();
		vError = ErrorDescription();
		tcCommonFunctionOnClientServer.TextMessage(vError);
		Return False;
	EndTry;

	CommitTransaction();
	
	Return True;
	
EndFunction


&AtServer
Procedure SaveInteractionParameters()
	
	If NOT ValueIsFilled(Object.InteractionParameters) Then
		Return;
	EndIf;
	
	vIntParObj 						= Object.InteractionParameters.GetObject();
	vIntParObj.OAuth_AccessToken 	= AccessToken;
	vIntParObj.Currency 			= Currency;	
	vIntParObj.Write();
	
EndProcedure

&AtServer
Procedure LoadInteractionParameters()
	
	If NOT ValueIsFilled(Object.InteractionParameters) Then
		Return;
	EndIf;
	
	AccessToken  	= Object.InteractionParameters.OAuth_AccessToken;	
	Currency		= Object.InteractionParameters.Currency;
	
EndProcedure


&AtServer
Procedure SaveServices()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "services");
	
	For each vServiceRow in Services Do
		If ValueIsFilled(vServiceRow.Service) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "services", "id", vServiceRow.Service, Undefined, vServiceRow.id, vServiceRow.id);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure LoadServices()
	
	For i = 1 to 15 Do
		vNewRow 	= Services.Add();
		vNewRow.ID 	= "NetSales" + i;		
	EndDo;
	
	vNewRow 	= Services.Add();
	vNewRow.ID 	= "Tip";

	vNewRow 	= Services.Add();
	vNewRow.ID 	= "Tender";

	vServices = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "services");
	
	If vServices.Count() > 0 Then		
		For each vServiceRow in vServices Do
			For each vLoadedServiceRow in Services Do
				If vServiceRow.id = vLoadedServiceRow.id Then 
					vLoadedServiceRow.Service = vServiceRow.RefKey1;
				EndIf;
			EndDo;
		EndDo;
	EndIf;

EndProcedure


&AtServer
Procedure SaveDepartments()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "departments");
	
	For each vDepartmentRow in Departments Do
		If ValueIsFilled(vDepartmentRow.Service) Then
			vUUID = String(New UUID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "departments", "id", 		vDepartmentRow.Service, vDepartmentRow.CashRegister, vDepartmentRow.id, 		vUUID);
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "departments", "Timezoneid", vDepartmentRow.Service, vDepartmentRow.CashRegister, vDepartmentRow.TimezoneID, vUUID);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure LoadDepartments()
		
	vDepartments = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "departments");
	
	If vDepartments.Count() > 0 Then		
		For each vDepartmentRow in vDepartments Do
			vNewRow 				= Departments.Add();
			vNewRow.ID 				= vDepartmentRow.id;
			vNewRow.TimezoneID 		= vDepartmentRow.Timezoneid;
			vNewRow.Service 		= vDepartmentRow.RefKey1;
			vNewRow.CashRegister 	= vDepartmentRow.RefKey2;
		EndDo;
	EndIf;

EndProcedure


&AtServer
Procedure SavePaymentMethodsTable()
	
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.InteractionParameters, "paymentMethods");
			
	For each vPaymentMethod in PaymentMethods Do
		If ValueIsFilled(vPaymentMethod.PaymentMethod) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.InteractionParameters, "paymentMethods", "id", 	vPaymentMethod.PaymentMethod, vPaymentMethod.Folio, vPaymentMethod.ID, vPaymentMethod.ID);				
		EndIf;
	EndDo;

EndProcedure

&AtServer
Procedure LoadPaymentMethodsTable()
	
	vPaymentMethods = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.InteractionParameters, "paymentMethods");
	
	If vPaymentMethods.Count() > 0 Then			
		For each vPaymentRow in vPaymentMethods Do
			vNewRow 				= PaymentMethods.Add();
			vNewRow.ID 				= vPaymentRow.id;
			vNewRow.PaymentMethod 	= vPaymentRow.RefKey1;
			vNewRow.Folio 			= vPaymentRow.RefKey2;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

&AtClient
Procedure GenerateToken(pCommand)
	
	AccessToken = String(New UUID);
	
EndProcedure

