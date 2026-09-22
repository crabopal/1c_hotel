#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If IsBlankString(Object.InteractionID) Then
		Object.InteractionID = "r_keeper";
	EndIf;
	LoadFieldsDadata();
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	SaveFieldsDadata();
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveMapping(pHotelRef, pExternalSystemCode, pObjectTypeName, pObjectRef, pExtObjectCode)
	// Try to find object ref by code
	If ValueIsFilled(pObjectRef) Then
		// Try to update existing mapping or create new one
		vMgrObj = InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
		vMgrObj.Hotel = pHotelRef;
		vMgrObj.ExternalSystemCode = TrimR(pExternalSystemCode);
		vMgrObj.ObjectTypeName = TrimR(pObjectTypeName);
		vMgrObj.ObjectExternalCode = TrimR(pExtObjectCode);
		vMgrObj.ObjectRef = pObjectRef;
		vMgrObj.Write(True);
	EndIf;
EndProcedure // SaveExternalSystemObjectMapping

// --------------------------------------------------------------------------------
&AtServer
Procedure ClearRecordSet(pObjectTypeName)
	vSet = InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordSet();
	vSet.Filter.ExternalSystemCode.Set(Object.InteractionID);
	vSet.Filter.ObjectTypeName.Set(pObjectTypeName);
	vSet.Write();	
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveFieldsDadata()
	
	// clear hotels
	ClearRecordSet("Hotels");
	For Each row In ThisForm.Hotels Do
		If ValueIsFilled(row.Hotel) AND Not IsBlankString(row.id) Then
			SaveMapping(Catalogs.Hotels.EmptyRef(),Object.InteractionID,"Hotels",row.Hotel,TrimAll(row.id));
		EndIF;
	EndDo;
	
	// clear PaymentMethods
	ClearRecordSet("PaymentMethods");
	// save new records
	For Each row In ThisForm.PaymentMethods Do
		If ValueIsFilled(row.PaymentMethod) AND Not IsBlankString(row.id) Then
			SaveMapping(row.Hotel,Object.InteractionID,"PaymentMethods",row.PaymentMethod,TrimAll(row.id));
		EndIF;
	EndDo;
	
	// clear PaymentMethods
	ClearRecordSet("CashRegisters");
	ClearRecordSet("Customers");
	// save new records
	For Each row In ThisForm.CashRegisters Do
		If Not IsBlankString(row.id) Then
			If ValueIsFilled(row.CashRegister) Then
				SaveMapping(row.Hotel, Object.InteractionID, "CashRegisters", row.CashRegister, TrimAll(row.id));
			EndIf;
			If ValueIsFilled(row.Customer) Then
				SaveMapping(row.Hotel, Object.InteractionID, "Customers", row.Customer, TrimAll(row.id));
			EndIf;
		EndIf;
	EndDo;
	
	// clear PaymentMethods
	ClearRecordSet("Services");

	For Each row In ThisForm.Services Do
		If ValueIsFilled(row.Service) AND Not IsBlankString(row.CashServerName) Then
			SaveMapping(row.Hotel,Object.InteractionID,"Services",row.Service,TrimAll(row.CashServerName));
		EndIF;
	EndDo;
	
	
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure LoadFieldsDadata()
	
	vQ = New Query("SELECT
	               |	ExternalSystemsObjectCodesMappings.Hotel AS Hotel,
	               |	ExternalSystemsObjectCodesMappings.ExternalSystemCode AS ExternalSystemCode,
	               |	ExternalSystemsObjectCodesMappings.ObjectTypeName AS ObjectTypeName,
	               |	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode,
	               |	ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef,
	               |	ExternalSystemsObjectCodesMappings.ObjectDescription AS ObjectDescription,
	               |	ExternalSystemsObjectCodesMappings.ObjectDataPath AS ObjectDataPath,
	               |	ExternalSystemsObjectCodesMappings.Type AS Type
	               |FROM
	               |	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
	               |WHERE
	               |	ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode");
	
	vQ.SetParameter("qExternalSystemCode",Object.InteractionID);
	qRes = vQ.Execute().Select();
	
	ThisForm.Hotels.Clear();
	ThisForm.PaymentMethods.Clear(); 
	ThisForm.CashRegisters.Clear();
	ThisForm.Services.Clear();
	
	While qRes.Next() Do
		
		If qRes.ObjectTypeName = "Hotels" Then
			row = ThisForm.Hotels.Add();
			row.id = qRes.ObjectExternalCode;
			row.Hotel = qRes.ObjectRef;		
		Elsif qRes.ObjectTypeName = "PaymentMethods" Then
			row = ThisForm.PaymentMethods.Add();
			row.id = qRes.ObjectExternalCode;
			row.PaymentMethod = qRes.ObjectRef;
			row.Hotel = qRes.Hotel; 
		Elsif qRes.ObjectTypeName = "CashRegisters" Then
			row = ThisForm.CashRegisters.Add();
			row.id = qRes.ObjectExternalCode;
			row.CashRegister = qRes.ObjectRef;
			row.Hotel = qRes.Hotel;
			
			row.Customer = cmGetObjectRefByExternalSystemCode(row.Hotel, Object.InteractionID, "Customers", row.id, False);
		Elsif qRes.ObjectTypeName = "Services" Then
			row = ThisForm.Services.Add();
			row.CashServerName = qRes.ObjectExternalCode;
			row.Service = qRes.ObjectRef;
			row.Hotel = qRes.Hotel;
		EndIf;			
	EndDo;

EndProcedure	

#EndRegion