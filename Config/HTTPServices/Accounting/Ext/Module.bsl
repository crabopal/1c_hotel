
//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//                  			 1C:HOTEL                                   //
//                          ACCOUNTING INTERFACE                            //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
#Region EventHandlers

// -----------------------------------------------------------------------------
Function GetVersionPOST(pRequest)
	vResponseParam = GetEmptyResponceStructure();
	
	Try
		// Initialize params
		vParamsArray = New Array;
		vParamsArray.Add("ExternalCode");
		
		vNonMandatoryParamsArray = New Array;
		vNonMandatoryParamsArray.Add("DBName");
		
		vInputParameters = cmCheckRequestParameters("JSON", vParamsArray, vNonMandatoryParamsArray, pRequest);
		
		If ValueIsFilled(vInputParameters.Error) Then
			vResponseParam.ErrorDescription = vInputParameters.ErrorDescription;
			Return GetResponce(vResponseParam);
		EndIf;
		
		// Get external system interactions
		vInteraction = CheckExternalInteraction(vInputParameters);
		
		// Fill parameters
		vResponseParam.Insert("HotelVersion", Mid(TrimAll(Constants.ProgramVersionNumber.Get()), 1));
		vResponseParam.Insert("HotelVersionString", cmGetProgramVersionAsDateString());
		vResponseParam.Insert("MinVersionACC", "3.0.73.54");
		vResponseParam.Insert("ExternalCode", vInteraction.InteractionID);
		vResponseParam.Success = True;
		
		// Log
		If ValueIsFilled(vInteraction) And vInteraction.DebugMode Then
			vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "GetVersion.Start",
			Enums.ExternalSystemEventTypes.Info, pRequest.GetBodyAsString(), , vMsg, 999999999);
		EndIf;
	Except
		vErrInfo = ErrorInfo();
		WriteLogEvent("AccountingDataExchange.GetVersion", EventLogLevel.Error, , , "Input parameters: " + Chars.LF
		+ pRequest.GetBodyAsString() + Chars.LF + "Error  :" + DetailErrorDescription(vErrInfo));
		vResponseParam.ErrorDescription = BriefErrorDescription(vErrInfo);
	EndTry;
	
	Return GetResponce(vResponseParam, vInteraction, "GetVersion");
EndFunction

// -----------------------------------------------------------------------------
Function GetObjectMappingPOST(pRequest)
	vResponseParam = GetEmptyResponceStructure();
	Try
		vRequestType = pRequest.URLParameters.Get("Source");
		
		// Initialize params
		vParamsArray = New Array;
		vParamsArray.Add("PeriodFrom");
		vParamsArray.Add("PeriodTo");
		
		vNonMandatoryParamsArray = New Array;
		vNonMandatoryParamsArray.Add("ExternalCode");
		vNonMandatoryParamsArray.Add("CompanyCode");
		vNonMandatoryParamsArray.Add("HotelCode");
		vNonMandatoryParamsArray.Add("UseAccountingDate");
		
		vInputParameters = cmCheckRequestParameters("JSON", vParamsArray, vNonMandatoryParamsArray, pRequest);
		If ValueIsFilled(vInputParameters.Error) Then
			vResponseParam.ErrorDescription = vInputParameters.ErrorDescription;
			Return GetResponce(vResponseParam);
		EndIf;
		// Check filling
		If Not CheckFilling(vParamsArray, vInputParameters, vResponseParam.ErrorDescription) Then
			Return GetResponce(vResponseParam);
		EndIf;
		// Convert date
		vInputParameters.PeriodFrom = ReadJSONDate(vInputParameters.PeriodFrom, JSONDateFormat.ISO);
		vInputParameters.PeriodTo = ReadJSONDate(vInputParameters.PeriodTo, JSONDateFormat.ISO);
		// Get interaction
		vInteraction = GetInteraction(vInputParameters.ExternalCode, vResponseParam.ErrorDescription);
		If Not IsBlankString(vResponseParam.ErrorDescription) Then
			Return GetResponce(vResponseParam);
		EndIf;
		// Log
		If vInteraction.DebugMode Then
			vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "GetObjectMapping." + vRequestType
			+ ".Start", Enums.ExternalSystemEventTypes.Info, pRequest.GetBodyAsString(), , vMsg, 999999999);
		EndIf;
		
		// Get object mapping
		If Not IsBlankString(vRequestType) Then
			vObjectMapping = GetObjectMapping(vRequestType, vInteraction, vInputParameters);
			vResponseParam.Success = True;
		Else
			vObjectMapping = New Structure;
			vResponseParam.ErrorDescription = Nstr("en = 'Request  undefined'; de = 'Anfrage undefiniert'; ru = 'Запрос не определен'");
		EndIf;
	Except
		vErr = ErrorInfo();
		vResponseParam.ErrorDescription = BriefErrorDescription(vErr);
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "GetObjectMapping.Error",
		Enums.ExternalSystemEventTypes.Error, , DetailErrorDescription(vErr), "Error", 999999999);
	EndTry;
	
	vResponseParam.Insert("ObjectMapping", vObjectMapping);
	Return GetResponce(vResponseParam, vInteraction, "GetObjectMapping." + vRequestType + ".Finish");
EndFunction //  GetObjectMappingPOST()

// -----------------------------------------------------------------------------
Function GetFullMappingPOST(pRequest)
	vResponseParam = GetEmptyResponceStructure();
	Try
		// Initialize params
		vParamsArray = New Array;
		vParamsArray.Add("ExternalCode");
		
		vNonMandatoryParamsArray = New Array;
		
		vInputParameters = cmCheckRequestParameters("JSON", vParamsArray, vNonMandatoryParamsArray, pRequest);
		If ValueIsFilled(vInputParameters.Error) Then
			vResponseParam.ErrorDescription = vInputParameters.ErrorDescription;
			Return GetResponce(vResponseParam);
		EndIf;
		// Check filling
		If Not CheckFilling(vParamsArray, vInputParameters, vResponseParam.ErrorDescription) Then
			Return GetResponce(vResponseParam);
		EndIf;
		// Get interaction
		vInteraction = GetInteraction(vInputParameters.ExternalCode, vResponseParam.ErrorDescription);
		If Not IsBlankString(vResponseParam.ErrorDescription) Then
			Return GetResponce(vResponseParam);
		EndIf;
		// Log
		If vInteraction.DebugMode Then
			vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "GetFullMapping.Start",
			Enums.ExternalSystemEventTypes.Info, pRequest.GetBodyAsString(), , vMsg, 999999999);
		EndIf;
		// Do  
		vResult = New Structure;
		vResult.Insert("Companies", New Array);
		vResult.Insert("Customers", New Array);
		vResult.Insert("Contracts", New Array);
		vResult.Insert("PaymentMethods", New Array);
		vResult.Insert("PaymentSections", New Array);
		vResult.Insert("Services", New Array);
		vResult.Insert("CashRegisters", New Array);
		vResult.Insert("Hotels", New Array);
		
		vQuery = New Query;
		vQuery.Text = 
		"SELECT
		|	ExternalSystemIntegrationData.RefKey1 AS Ref,
		|	ExternalSystemIntegrationData.ExternalSystemDataCode AS ObjectExternalCode
		|FROM
		|	InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
		|WHERE
		|	ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem
		|
		|GROUP BY
		|	ExternalSystemIntegrationData.ExternalSystemDataCode,
		|	ExternalSystemIntegrationData.RefKey1";
		
		vQuery.SetParameter("qExternalSystem", vInteraction);
		
		vQueryResult = vQuery.Execute();
		
		vRes = vQueryResult.Select();
		
		While vRes.Next() Do
			vRef = vRes.Ref;
			If ValueIsFilled(vRef) Then
				vObjArr = GetCatalogItemEmptyStructure();
				If TypeOf(vRef) = Type("CatalogRef.PaymentMethods") Then
					vObjArr = tcOnServer.cmGetAtributeAsArray(vRef);
					vObjArr.Insert("UUID");
				ElsIf TypeOf(vRef) = Type("CatalogRef.Customers") Then
					vObjArr.Insert("LegacyName");
					vObjArr.Insert("Phone");
					vObjArr.Insert("EMail");
					vObjArr.Insert("TIN");
					vObjArr.Insert("KPP");
					vObjArr.Insert("CustomerType");
					vObjArr.Insert("IsIndividual");
				ElsIf TypeOf(vRef) = Type("CatalogRef.Services") Then
					vObjArr.Insert("Unit");
					vObjArr.Insert("IsRoomRevenue");
					vObjArr.Insert("IsInPrice");
					vObjArr.Insert("IsResourceRevenue");
					vObjArr.Insert("DoNotGroupIntoRoomRateOnPrint");
					vObjArr.Insert("SplitToSeparateSettlements");
					vObjArr.Insert("DoNotExportToTheAccountingSystem");
					vObjArr.Insert("Unit");
					vObjArr.Insert("ServiceType");
					vObjArr.Insert("IsStockArticle");
					vObjArr.Insert("IsAgentService");
					vObjArr.Insert("IsHotelProductService");
					vObjArr.Insert("IsGiftCertificate");
					vObjArr.Insert("BonusPaymentsNotAllowed");
				ElsIf TypeOf(vRef) = Type("CatalogRef.Contracts") Then
					vObjArr.Insert("IsActsHisOwnBehalf", False);
					vObjArr.Insert("Customer");
					vObjArr.Insert("CustomerExternalCode");
				EndIf;
				FillPropertyValues(vObjArr, vRef);
				vObjArr.ExternalCode = vRes.ObjectExternalCode;
				vObjArr.UUID = XMLString(vRef);
				If TypeOf(vRef) = Type("CatalogRef.Contracts") Then
					If ValueIsFilled(vRef.ContractType) Then
						vObjArr.IsActsHisOwnBehalf = vRef.ContractType.TypeAgencyContract = Enums.TypeAgencyContract.ActsHisOwnBehalf;
					EndIf;
					vObjArr.Customer = FillCatalogObject(vRef.Owner, vInteraction);
					vObjArr.CustomerExternalCode = GetObjectExternalSystemCodeByRef(vInteraction, vRef.Owner);
				EndIf;	
				
				vResult[vRef.Metadata().Name].Add(vObjArr);
			EndIf;
		EndDo;
		
		vResponseParam.Insert("ObjectMapping", vResult);
		vResponseParam.Success = True;
	Except
		vErr = ErrorInfo();
		vResponseParam.ErrorDescription = BriefErrorDescription(vErr);
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "GetFullMapping.Error",
		Enums.ExternalSystemEventTypes.Error, , DetailErrorDescription(vErr), "Error", 999999999);
	EndTry;
	
	Return GetResponce(vResponseParam, vInteraction, "GetFullMapping.Finish")
	
EndFunction

// -----------------------------------------------------------------------------
Function GetPaymentListPOST(pRequest)
	vResponseParam = GetEmptyResponceStructure();
	Try
		// Initialize params
		vParamsArray = New Array;
		vParamsArray.Add("PeriodFrom");
		vParamsArray.Add("PeriodTo");
		
		vNonMandatoryParamsArray = New Array;
		vNonMandatoryParamsArray.Add("ExternalCode");
		vNonMandatoryParamsArray.Add("CompanyCode");
		vNonMandatoryParamsArray.Add("HotelCode");
		vNonMandatoryParamsArray.Add("UseAccountingDate");
		
		vInputParameters = cmCheckRequestParameters("JSON", vParamsArray, vNonMandatoryParamsArray, pRequest);
		If ValueIsFilled(vInputParameters.Error) Then
			vResponseParam.ErrorDescription = vInputParameters.ErrorDescription;
			Return GetResponce(vResponseParam);
		EndIf;
		// Check filling
		If Not CheckFilling(vParamsArray, vInputParameters, vResponseParam.ErrorDescription) Then
			Return GetResponce(vResponseParam);
		EndIf;
		// Convert date
		vInputParameters.PeriodFrom = ReadJSONDate(vInputParameters.PeriodFrom, JSONDateFormat.ISO);
		vInputParameters.PeriodTo = ReadJSONDate(vInputParameters.PeriodTo, JSONDateFormat.ISO);
		// Get interaction
		vInteraction = GetInteraction(vInputParameters.ExternalCode, vResponseParam.ErrorDescription);
		If Not IsBlankString(vResponseParam.ErrorDescription) Then
			Return GetResponce(vResponseParam);
		EndIf;
		// Log
		If vInteraction.DebugMode Then
			vMsg = NStr("en = 'Start of processing'; de = 'Anfang der Ausführung'; ru = 'Начало выполнения'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "GetPaymentList.Start",
				Enums.ExternalSystemEventTypes.Info, pRequest.GetBodyAsString(), , vMsg, 999999999);
		EndIf;
		// Get payment list
		vPaymentList = GetPaymentList(vInteraction, vInputParameters);
		vResponseParam.Success = True;
	Except
		vErr = ErrorInfo();
		vResponseParam.ErrorDescription = BriefErrorDescription(vErr);
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "GetPaymentList.Error",
			Enums.ExternalSystemEventTypes.Error, , DetailErrorDescription(vErr), "Error", 999999999);
	EndTry;
	vResponseParam.Insert("PaymentList", vPaymentList);
	Return GetResponce(vResponseParam, vInteraction, "GetPaymentList.Finish")
EndFunction

// -----------------------------------------------------------------------------
Function GetInvoicesListPOST(pRequest)
	vResponseParam = GetEmptyResponceStructure();
	Try
		// Initialize params
		vParamsArray = New Array;
		vParamsArray.Add("PeriodFrom");
		vParamsArray.Add("PeriodTo");
		
		vNonMandatoryParamsArray = New Array;
		vNonMandatoryParamsArray.Add("ExternalCode");
		vNonMandatoryParamsArray.Add("CompanyCode");
		vNonMandatoryParamsArray.Add("HotelCode");
		
		vInputParameters = cmCheckRequestParameters("JSON", vParamsArray, vNonMandatoryParamsArray, pRequest);
		If ValueIsFilled(vInputParameters.Error) Then
			vResponseParam.ErrorDescription = vInputParameters.ErrorDescription;
			Return GetResponce(vResponseParam);
		EndIf;
		// Check filling
		If Not CheckFilling(vParamsArray, vInputParameters, vResponseParam.ErrorDescription) Then
			Return GetResponce(vResponseParam);
		EndIf;
		// Convert date
		vInputParameters.PeriodFrom = ReadJSONDate(vInputParameters.PeriodFrom, JSONDateFormat.ISO);
		vInputParameters.PeriodTo = ReadJSONDate(vInputParameters.PeriodTo, JSONDateFormat.ISO);
		// Get interaction
		vInteraction = GetInteraction(vInputParameters.ExternalCode, vResponseParam.ErrorDescription);
		If Not IsBlankString(vResponseParam.ErrorDescription) Then
			Return GetResponce(vResponseParam);
		EndIf;
		// Log
		If vInteraction.DebugMode Then
			vMsg = NStr("en = 'Start of processing'; de = 'Anfang der Ausführung'; ru = 'Начало выполнения'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "GetInvoicesList.Start",
			Enums.ExternalSystemEventTypes.Info, pRequest.GetBodyAsString(), , vMsg, 999999999);
		EndIf;
		// Get invoices list
		vInvoicesList = GetInvoicesList(vInteraction, vInputParameters);
		vResponseParam.Success = True;
	Except
		vErr = ErrorInfo();
		vResponseParam.ErrorDescription = BriefErrorDescription(vErr);
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "GetInvoicesList.Error",
		Enums.ExternalSystemEventTypes.Error, , DetailErrorDescription(vErr), "Error", 999999999);
	EndTry;
	vResponseParam.Insert("InvoicesList", vInvoicesList);
	Return GetResponce(vResponseParam, vInteraction, "GetInvoicesList.Finish")
EndFunction  //GetInvoicesListPOST	

// -----------------------------------------------------------------------------
Function GetSettlementListPOST(pRequest)
	vResponseParam = GetEmptyResponceStructure();
	Try
		// Initialize params
		vParamsArray = New Array;
		vParamsArray.Add("PeriodFrom");
		vParamsArray.Add("PeriodTo");
		
		vNonMandatoryParamsArray = New Array;
		vNonMandatoryParamsArray.Add("ExternalCode");
		vNonMandatoryParamsArray.Add("CompanyCode");
		vNonMandatoryParamsArray.Add("HotelCode");
		
		vInputParameters = cmCheckRequestParameters("JSON", vParamsArray, vNonMandatoryParamsArray, pRequest);
		If ValueIsFilled(vInputParameters.Error) Then
			vResponseParam.ErrorDescription = vInputParameters.ErrorDescription;
			Return GetResponce(vResponseParam);
		EndIf;
		// Check filling
		If Not CheckFilling(vParamsArray, vInputParameters, vResponseParam.ErrorDescription) Then
			Return GetResponce(vResponseParam);
		EndIf;
		// Convert date
		vInputParameters.PeriodFrom = ReadJSONDate(vInputParameters.PeriodFrom, JSONDateFormat.ISO);
		vInputParameters.PeriodTo = ReadJSONDate(vInputParameters.PeriodTo, JSONDateFormat.ISO);
		// Get interaction
		vInteraction = GetInteraction(vInputParameters.ExternalCode, vResponseParam.ErrorDescription);
		If Not IsBlankString(vResponseParam.ErrorDescription) Then
			Return GetResponce(vResponseParam);
		EndIf;
		// Log
		If vInteraction.DebugMode Then
			vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "GetSettlementList.Start",
			Enums.ExternalSystemEventTypes.Info, pRequest.GetBodyAsString(), , vMsg, 999999999);
		EndIf;
		// Get invoices list
		vSettlementList = GetSettlementList(vInteraction, vInputParameters);
		vResponseParam.Success = True;
	Except
		vErr = ErrorInfo();
		vResponseParam.ErrorDescription = BriefErrorDescription(vErr);
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "GetSettlementList.Error",
		Enums.ExternalSystemEventTypes.Error, , DetailErrorDescription(vErr), "Error", 999999999);
	EndTry;
	vResponseParam.Insert("SettlementList", vSettlementList);
	Return GetResponce(vResponseParam, vInteraction, "GetSettlementList.Finish")
EndFunction

// -----------------------------------------------------------------------------
Function GetSettlementListTablePOST(pRequest)
	vResponseParam = GetEmptyResponceStructure();
	Try
		// Initialize params
		vParamsArray = New Array;
		vParamsArray.Add("SettlementUUID");
		vParamsArray.Add("ExternalCode");
		
		vNonMandatoryParamsArray = New Array;
		
		vInputParameters = cmCheckRequestParameters("JSON", vParamsArray, vNonMandatoryParamsArray, pRequest);
		If ValueIsFilled(vInputParameters.Error) Then
			vResponseParam.ErrorDescription = vInputParameters.ErrorDescription;
			Return GetResponce(vResponseParam);
		EndIf;
		// Check filling
		If Not CheckFilling(vParamsArray, vInputParameters, vResponseParam.ErrorDescription) Then
			Return GetResponce(vResponseParam);
		EndIf;
		// Get interaction
		vInteraction = GetInteraction(vInputParameters.ExternalCode, vResponseParam.ErrorDescription);
		If Not IsBlankString(vResponseParam.ErrorDescription) Then
			Return GetResponce(vResponseParam);
		EndIf;
		// Log
		If vInteraction.DebugMode Then
			vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "GetSettlementListTable.Start",
			Enums.ExternalSystemEventTypes.Info, pRequest.GetBodyAsString(), , vMsg, 999999999);
		EndIf;
		// Do
		vObjectRef = Documents.Settlement.GetRef(New UUID(vInputParameters.SettlementUUID));
		If ValueIsFilled(vObjectRef) And Not vObjectRef.GetObject() = Undefined Then
			vArrayServices = New Array;
			// Fill services by settlement
			vServices = vObjectRef.Services;
			For Each mRow In vServices Do
				vServiceRow = FillSettlementServicesRow(mRow, vInteraction);
				vArrayServices.Add(vServiceRow);
			EndDo;
			vResponseParam.Insert("SettlementListTable", vArrayServices);
			vResponseParam.Success = True;
		Else
			vError = NStr("en = 'The document was not found on the incoming parameters'; ru = 'Документ не найден по входящим параметрам'; de = 'Das Dokument wurde nicht auf die eingehenden Parameter gefunden'");
			vResponseParam.ErrorDescription = vError;
		EndIf;
	Except
		vErr = ErrorInfo();
		vResponseParam.ErrorDescription = BriefErrorDescription(vErr);
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "GetSettlementListTable.Error",
		Enums.ExternalSystemEventTypes.Error, , DetailErrorDescription(vErr), "Error", 999999999);
	EndTry;
	
	Return GetResponce(vResponseParam, vInteraction, "GetSettlementListTable.Finish")
	
EndFunction

// -----------------------------------------------------------------------------
Function GetCustomerPaymentsPOST(pRequest)
	vResponseParam = GetEmptyResponceStructure();
	Try
		// Initialize params
		vParamsArray = New Array;
		vParamsArray.Add("PeriodFrom");
		vParamsArray.Add("PeriodTo");
		
		vNonMandatoryParamsArray = New Array;
		vNonMandatoryParamsArray.Add("ExternalCode");
		vNonMandatoryParamsArray.Add("CompanyCode");
		vNonMandatoryParamsArray.Add("HotelCode");
		vNonMandatoryParamsArray.Add("PaymentType");
		vNonMandatoryParamsArray.Add("CustomersPaymentList");
		
		vInputParameters = cmCheckRequestParameters("JSON", vParamsArray, vNonMandatoryParamsArray, pRequest);
		If ValueIsFilled(vInputParameters.Error) Then
			vResponseParam.ErrorDescription = vInputParameters.ErrorDescription;
			Return GetResponce(vResponseParam);
		EndIf;
		// Check filling
		If Not CheckFilling(vParamsArray, vInputParameters, vResponseParam.ErrorDescription) Then
			Return GetResponce(vResponseParam);
		EndIf;
		// Convert date
		vInputParameters.PeriodFrom = ReadJSONDate(vInputParameters.PeriodFrom, JSONDateFormat.ISO);
		vInputParameters.PeriodTo = ReadJSONDate(vInputParameters.PeriodTo, JSONDateFormat.ISO);
		// Get interaction
		vInteraction = GetInteraction(vInputParameters.ExternalCode, vResponseParam.ErrorDescription);
		If Not IsBlankString(vResponseParam.ErrorDescription) Then
			Return GetResponce(vResponseParam);
		EndIf;
		// Log
		If vInteraction.DebugMode Then
			vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "GetCustomerPayments.Start",
			Enums.ExternalSystemEventTypes.Info, pRequest.GetBodyAsString(), , vMsg, 999999);
		EndIf;
		
		GetCustomerPayments(vInteraction, vInputParameters);
		vResponseParam.Success = True;
	Except
		vErr = ErrorInfo();
		WriteLogEvent("GetCustomerPayments.Error", EventLogLevel.Error, , , DetailErrorDescription(vErr));
		
		vResponseParam.ErrorDescription = BriefErrorDescription(vErr);
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "GetCustomerPayments.Error",
		Enums.ExternalSystemEventTypes.Error, , DetailErrorDescription(vErr), "Error", 999999);
		
	EndTry;
	vResponseParam.Insert("CustomersPaymentList", vInputParameters.CustomersPaymentList);
	Return GetResponce(vResponseParam, vInteraction, "GetCustomerPayments.Finish");
EndFunction

// -----------------------------------------------------------------------------
Function WriteCatalogObjectMappingPOST(pRequest)
	vResponseParam = GetEmptyResponceStructure();
	Try
		// Initialize params
		vParamsArray = New Array;
		vParamsArray.Add("Code");
		vParamsArray.Add("UUID");
		vParamsArray.Add("ObjectType");
		
		vNonMandatoryParamsArray = New Array;
		vNonMandatoryParamsArray.Add("ExternalCode");
		vNonMandatoryParamsArray.Add("Description");
		
		vInputParameters = cmCheckRequestParameters("JSON", vParamsArray, vNonMandatoryParamsArray, pRequest);
		If ValueIsFilled(vInputParameters.Error) Then
			vResponseParam.ErrorDescription = vInputParameters.ErrorDescription;
			Return GetResponce(vResponseParam);
		EndIf;
		// Check filling
		If Not CheckFilling(vParamsArray, vInputParameters, vResponseParam.ErrorDescription) Then
			Return GetResponce(vResponseParam);
		EndIf;
		// Get interaction
		vInteraction = GetInteraction(vInputParameters.ExternalCode, vResponseParam.ErrorDescription);
		If Not IsBlankString(vResponseParam.ErrorDescription) Then
			Return GetResponce(vResponseParam);
		EndIf;
		// Log
		If vInteraction.DebugMode Then
			vMsg = NStr("en = 'Start of processing'; de = 'Anfang der Ausführung'; ru = 'Начало выполнения'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "WriteObjectMapping.Start",
							Enums.ExternalSystemEventTypes.Info, pRequest.GetBodyAsString(), , vMsg);
		EndIf;
		// Write object mapping
		vManagerObject = Catalogs[vInputParameters.ObjectType];
		vObjectRef = vManagerObject.GetRef(New UUID(vInputParameters.UUID));
		
		If ValueIsFilled(vObjectRef) And Not vObjectRef.GetObject() = Undefined Then
			// Clear old rows
			vRecSet 							= InformationRegisters.ExternalSystemIntegrationData.CreateRecordSet();
			vRecSet.Filter.ExternalSystem.Use	= True;
			vRecSet.Filter.ExternalSystem.Value	= vInteraction;
			vRecSet.Filter.RefKey1.Use			= True;
			vRecSet.Filter.RefKey1.Value		= vObjectRef;		
			vRecSet.Read();
			vRecSet.Clear();
			vRecSet.Write(True);
			
			// Try to update existing mapping or create new one
			InformationRegisters.ExternalSystemIntegrationData.WriteData(vInteraction, vObjectRef.Metadata().Name,
			vObjectRef.Metadata().Synonym, vObjectRef, , vInputParameters.Description, vInputParameters.Code);
			vResponseParam.Success = True;
		Else    
			vErrTemlate = Nstr("en = 'Failed to match for ""%3"" Type: %1, CodeACC: %2 '; 
							   |de = 'Nicht übereinstimmend für ""%3"" Type: %1, CodeACC: %2 '; 
							   |ru = 'Не удалось установить соответствие для ""%3"" Тип: %1, КодБП: %2 '");
			vErr = StrTemplate(vErrTemlate, vInputParameters.ObjectType, vInputParameters.Code, vInputParameters.Description);  
			vResponseParam.ErrorDescription = vErr;
		EndIf;
	Except
		vErr = ErrorInfo();
		vResponseParam.ErrorDescription = BriefErrorDescription(vErr);
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "WriteObjectMapping.Error",
						Enums.ExternalSystemEventTypes.Error, , DetailErrorDescription(vErr), "Error");
	EndTry;
	Return GetResponce(vResponseParam, vInteraction, "WriteObjectMapping.Finish");
EndFunction //  WriteCatalogObjectMappingPOST()

// -----------------------------------------------------------------------------
Function WriteCCRDExternalCodePOST(pRequest)
	vResponseParam = GetEmptyResponceStructure();
	Try
		// Initialize params
		vParamsArray = New Array;
		vParamsArray.Add("CCRD_UUID");
		vParamsArray.Add("PaymentUUID");
		vParamsArray.Add("CustomerCode");
		vParamsArray.Add("CurrencyCode");
		vParamsArray.Add("PaymentMethodCode");
		vParamsArray.Add("IsPayment");
		vParamsArray.Add("ExternalCode");
		
		vNonMandatoryParamsArray = New Array;
		vNonMandatoryParamsArray.Add("PaymentAccountingType");
		vNonMandatoryParamsArray.Add("DocNumber");
		vNonMandatoryParamsArray.Add("Sum");
		
		vInputParameters = cmCheckRequestParameters("JSON", vParamsArray, vNonMandatoryParamsArray, pRequest);
		If ValueIsFilled(vInputParameters.Error) Then
			vResponseParam.ErrorDescription = vInputParameters.ErrorDescription;
			Return GetResponce(vResponseParam);
		EndIf;
		// Check filling
		If Not CheckFilling(vParamsArray, vInputParameters, vResponseParam.ErrorDescription) Then
			Return GetResponce(vResponseParam);
		EndIf;
		// Get interaction
		vInteraction = GetInteraction(vInputParameters.ExternalCode, vResponseParam.ErrorDescription);
		If Not IsBlankString(vResponseParam.ErrorDescription) Then
			Return GetResponce(vResponseParam);
		EndIf;
		// Log
		If vInteraction.DebugMode Then
			vMsg = NStr("en = 'Start of processing'; de = 'Anfang der Ausführung'; ru = 'Начало выполнения'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "WriteCCRDExternalCode.Start",
				Enums.ExternalSystemEventTypes.Info, pRequest.GetBodyAsString(), , vMsg, 999999999);
		EndIf;
		// Write object mapping
		vCustomer = Catalogs.Customers.FindByCode(TrimAll(vInputParameters.CustomerCode));
		vCurrency = Catalogs.Currencies.FindByCode(TrimAll(vInputParameters.CurrencyCode));
		vPaymentMethod = Catalogs.PaymentMethods.FindByCode(TrimAll(vInputParameters.PaymentMethodCode));
		
		vCCRD = Documents.CloseOfCashRegisterDay.GetRef(New UUID(TrimAll(vInputParameters.CCRD_UUID)));
		
		If vCCRD.IsEmpty() Then
			vError = NStr("en = 'According to the document closing cash change input parameters can not be found!'; 
						  |de = 'Nach dem Schließen des Dokuments Geldwechsel kann Eingabeparameter nicht gefunden werden!'; 
						  |ru = 'По входным параметрам документ закрытие кассовой смены не найден!'");
			
			vResponseParam.ErrorDescription = vError;
		Else
			vObj = vCCRD.GetObject();
			vFilter = New Structure("Currency, PaymentMethod, Customer, IsPayment", vCurrency, vPaymentMethod,
			vCustomer, vInputParameters.IsPayment);
			vFilterRows = vObj.AccountingTotals.FindRows(vFilter);
			If vFilterRows.Count() > 0 Then
				// Update ExternalCode
				vFilterRows[0].ExternalCode = vInputParameters.PaymentUUID;
				vObj.Write();
				vResponseParam.Success = True;
			Else
				vError = NStr("en = 'Compliance is not recorded because the corresponding row is not found'; 
							  |de = 'Die Einhaltung wird nicht aufgezeichnet, da wird die entsprechende Zeile nicht gefunden'; 
							  |ru = 'Соответствие не записано, т.к. не найдена соответствующая строка'");
				
				vResponseParam.ErrorDescription = vError;
			EndIf;
		EndIf;
		
	Except
		vErr = ErrorInfo();
		vResponseParam.ErrorDescription = BriefErrorDescription(vErr);
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "WriteCCRDExternalCode.Error",
			Enums.ExternalSystemEventTypes.Error, , DetailErrorDescription(vErr), "Error", 999999999);
	EndTry;
	Return GetResponce(vResponseParam, vInteraction, "WriteCCRDExternalCode.Finish");
EndFunction //  WriteCCRDExternalCodePOST()

// -----------------------------------------------------------------------------
Function WriteSettlementExternalCodePOST(pRequest)
	vResponseParam = GetEmptyResponceStructure();
	Try
		// Initialize params
		vParamsArray = New Array;
		vParamsArray.Add("AccountingDocument_UUID");
		vParamsArray.Add("SettlementUUID");
		vParamsArray.Add("ExternalCode");
		
		vNonMandatoryParamsArray = New Array;
		vNonMandatoryParamsArray.Add("AccountingDocNumber");
		vNonMandatoryParamsArray.Add("SettlementNumber");
		vNonMandatoryParamsArray.Add("Sum");
		
		vInputParameters = cmCheckRequestParameters("JSON", vParamsArray, vNonMandatoryParamsArray, pRequest);
		If ValueIsFilled(vInputParameters.Error) Then
			vResponseParam.ErrorDescription = vInputParameters.ErrorDescription;
			Return GetResponce(vResponseParam);
		EndIf;
		// Check filling
		If Not CheckFilling(vParamsArray, vInputParameters, vResponseParam.ErrorDescription) Then
			Return GetResponce(vResponseParam);
		EndIf;
		// Get interaction
		vInteraction = GetInteraction(vInputParameters.ExternalCode, vResponseParam.ErrorDescription);
		If Not IsBlankString(vResponseParam.ErrorDescription) Then
			Return GetResponce(vResponseParam);
		EndIf;
		// Log
		If vInteraction.DebugMode Then
			vMsg = NStr("en = 'Start of processing'; de = 'Anfang der Ausführung'; ru = 'Начало выполнения'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "WriteSettlementExternalCode.Start",
				Enums.ExternalSystemEventTypes.Info, pRequest.GetBodyAsString(), , vMsg, 999999999);
		EndIf;
		vObjectRef = Documents.Settlement.GetRef(New UUID(vInputParameters.SettlementUUID));
		vObj = vObjectRef.GetObject();
		If ValueIsFilled(vObjectRef) And Not vObj = Undefined Then
			If vObj.ExternalCode <> vInputParameters.AccountingDocument_UUID Then
				vObj.ExternalCode = vInputParameters.AccountingDocument_UUID;
				vObj.Write();
			EndIf;
			vResponseParam.Success = True;
		Else
			vError = NStr("en = 'The document was not found on the incoming parameters'; 
						  |de = 'Das Dokument wurde nicht auf die eingehenden Parameter gefunden'; 
						  |ru = 'Документ не найден по входящим параметрам'");
			Raise vError;
		EndIf;
	Except
		vErr = ErrorInfo();
		vResponseParam.ErrorDescription = BriefErrorDescription(vErr);
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "WriteSettlementExternalCode.Error",
			Enums.ExternalSystemEventTypes.Error, , DetailErrorDescription(vErr), "Error", 999999999);
	EndTry;
	
	Return GetResponce(vResponseParam, vInteraction, "WriteSettlementExternalCode.Finish");
	
EndFunction //  WriteSettlementExternalCodePOST()

// -----------------------------------------------------------------------------
Function WriteInvoicesExternalCodePOST(pRequest)
	vResponseParam = GetEmptyResponceStructure();
	Try
		// Initialize params
		vParamsArray = New Array;
		vParamsArray.Add("AccountingDocument_UUID");
		vParamsArray.Add("InvoiceUUID");
		vParamsArray.Add("ExternalCode");
		
		vNonMandatoryParamsArray = New Array;
		vNonMandatoryParamsArray.Add("AccountingDocNumber");
		vNonMandatoryParamsArray.Add("InvoiceNumber");
		vNonMandatoryParamsArray.Add("Sum");
		
		vInputParameters = cmCheckRequestParameters("JSON", vParamsArray, vNonMandatoryParamsArray, pRequest);
		If ValueIsFilled(vInputParameters.Error) Then
			vResponseParam.ErrorDescription = vInputParameters.ErrorDescription;
			Return GetResponce(vResponseParam);
		EndIf;
		// Check filling
		If Not CheckFilling(vParamsArray, vInputParameters, vResponseParam.ErrorDescription) Then
			Return GetResponce(vResponseParam);
		EndIf;
		// Get interaction
		vInteraction = GetInteraction(vInputParameters.ExternalCode, vResponseParam.ErrorDescription);
		If Not IsBlankString(vResponseParam.ErrorDescription) Then
			Return GetResponce(vResponseParam);
		EndIf;
		// Log
		If vInteraction.DebugMode Then
			vMsg = NStr("en = 'Start of processing'; de = 'Anfang der Ausführung'; ru = 'Начало выполнения'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "WriteInvoicesExternalCode.Start",
				Enums.ExternalSystemEventTypes.Info, pRequest.GetBodyAsString(), , vMsg, 999999999);
		EndIf;
		vObjectRef = Documents.ProformaInvoice.GetRef(New UUID(vInputParameters.InvoiceUUID));
		vObj = vObjectRef.GetObject();
		If ValueIsFilled(vObjectRef) And Not vObj = Undefined Then
			If vObj.ExternalCode <> vInputParameters.AccountingDocument_UUID Then
				vObj.ExternalCode = vInputParameters.AccountingDocument_UUID;
				vObj.Write();
			EndIf;
			vResponseParam.Success = True;
		Else
			vError = NStr("en = 'The document was not found on the incoming parameters'; 
						  |de = 'Das Dokument wurde nicht auf die eingehenden Parameter gefunden'; 
						  |ru = 'Документ не найден по входящим параметрам'");
			Raise vError;
		EndIf;
	Except
		vErr = ErrorInfo();
		vResponseParam.ErrorDescription = BriefErrorDescription(vErr);
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "WriteInvoicesExternalCode.Error",
			Enums.ExternalSystemEventTypes.Error, , DetailErrorDescription(vErr), "Error", 999999999);
	EndTry;
	
	Return GetResponce(vResponseParam, vInteraction, "WriteInvoicesExternalCode.Finish");
EndFunction //  WriteInvoicesExternalCodePOST()

// -----------------------------------------------------------------------------
Function WriteExternalPaymentPOST(pRequest)
	vResponseParam = GetEmptyResponceStructure();
	Try
		// Initialize params
		vInputParameters = Catalogs.DataConvertationRules.JSONtoStructure(pRequest.GetBodyAsString());
		
		// Get interaction
		vInteraction = GetInteraction(vInputParameters.ExternalCode, vResponseParam.ErrorDescription);
		If Not IsBlankString(vResponseParam.ErrorDescription) Then
			Return GetResponce(vResponseParam);
		EndIf;
		// Log
		If vInteraction.DebugMode Then
			vMsg = NStr("en = 'Start of processing'; de = 'Anfang der Ausführung'; ru = 'Начало выполнения'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "WriteExternalPayment.Start",
			Enums.ExternalSystemEventTypes.Info, pRequest.GetBodyAsString(), , vMsg, 999999999);
		EndIf;
		// Try to find payer
		vCustomer = Catalogs.Customers.EmptyRef();
		If Not IsBlankString(vInputParameters.Customer.Code) Then
			// Try to find customer by external code
			vCustomer = cmGetObjectRefByExternalSystemCode(vInteraction.Hotel, vInputParameters.ExternalCode, "Customers", vInputParameters.Customer.Code, , vInteraction);
		EndIf;   
		If Not ValueIsFilled(vCustomer) Then
			vInvoce = Documents.ProformaInvoice.FindByAttribute("ExternalCode", vInputParameters.PaymentDetails[0].ExternalCode);
			If ValueIsFilled(vInvoce) Then
				vCustomer = vInvoce.AccountingCustomer;
			EndIf;
		EndIf;
		// Try to find payment method
		vPaymentMethodCode = vInputParameters.PaymentMethod;
		If ValueIsFilled(vCustomer) And vCustomer.IsIndividual Then
			If vInputParameters.Property("PaymentMethodIndividual") And ValueIsFilled(vInputParameters.PaymentMethodIndividual)Then	 
				vPaymentMethodCode = vInputParameters.PaymentMethodIndividual;	
			EndIf;	
		EndIf;	
		If Not ValueIsFilled(vCustomer) Then  
			vMsg = NStr("en = 'No counterparty was found in the external code: %1'; 
						|de = 'Im externen Code wurde keine Gegenpartei gefunden: %1'; 
						|ru = 'Не найден контрагент по внешнему коду: %1'");
			vErr = StrTemplate(vMsg, vInputParameters.Customer.Code);	
			vResponseParam.ErrorDescription = vErr;
			vResponseParam.Success = False;   
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "WriteExternalPayment.Error",
				Enums.ExternalSystemEventTypes.Error, , vErr, "Error", 999999999);
			Return GetResponce(vResponseParam);
		EndIf;	
		If vInputParameters.PaymentType = "CustomerPayment" Then
			Try
				cmWriteInvoicePayment( , , vInputParameters.AccountingDocument_UUID,  
										ReadJSONDate(vInputParameters.PaymentDate, JSONDateFormat.ISO),
										vInputParameters.PaymentNumber, 
										vInputParameters.Customer, 
										vInputParameters.IsPosted,
										vInputParameters.IsMarkedDeleted, 
										New Structure("PaymentDetailsRow", vInputParameters.PaymentDetails),
										vInputParameters.Remarks, 
										vInputParameters.ExternalCode, 
										vInputParameters.AccountingCurrencyCode, 
										True, 
										vPaymentMethodCode);
										
				vResponseParam.Success = True;
			Except
				vResponseParam.ErrorDescription = ErrorDescription();
				vResponseParam.Success = False;
			EndTry;
		Else
			// Folio payment
			vExternalPaymentData   = New Структура;
			vExternalPaymentData.Insert("CardNumber", "");
			vExternalPaymentData.Insert("LoyaltyCardID", "");
			vExternalPaymentData.Insert("OrderNumber", "");
			vExternalPaymentData.Insert("CardHolder", "");
			vExternalPaymentData.Insert("InvoiceCode", vInputParameters.PaymentDetails[0].ExternalCode);
			vExternalPaymentData.Insert("Date", vInputParameters.PaymentDate);
			vExternalPaymentData.Insert("ExternalPaymentCode", vInputParameters.AccountingDocument_UUID);
			
			vRes = cmWriteExternalPayment("",
										0, 
										"", 
										vInputParameters.Customer.Code, 
										vInputParameters.Customer.TIN,						
										vInputParameters.Customer.KPP, 
										vInputParameters.Customer.Description, 
										vPaymentMethodCode, 
										vInputParameters.Amount, 					
										vInputParameters.AccountingCurrencyCode, 
										"", 
										vInputParameters.HotelCode, 
										vInputParameters.ExternalCode,						
										"", 
										"", 
										vInputParameters.Remarks, 
										"", 
										ReadJSONDate(vInputParameters.PaymentDate, JSONDateFormat.ISO), 
										vInputParameters.CompanyCode, 					
										vInputParameters.AccountingDocument_UUID, 
										"XDTO", 
										vExternalPaymentData);
		If IsBlankString(vRes.ErrorDescription) Then
			vResponseParam.Success = True;
		Else
			vResponseParam.ErrorDescription = vRes.ErrorDescription;
			vResponseParam.Success = False;
		EndIf;	
		EndIf;	
	Except
		vErr = ErrorInfo();
		vResponseParam.ErrorDescription = BriefErrorDescription(vErr);
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "WriteExternalPayment.Error",
			Enums.ExternalSystemEventTypes.Error, , DetailErrorDescription(vErr), "Error");
	EndTry;
	
	Return GetResponce(vResponseParam, vInteraction, "WriteExternalPayment.Finish");
EndFunction

// -----------------------------------------------------------------------------
Function AnyPOST(qRequest)
	vResponse = New HTTPServiceResponse(200);
	vResponse.SetBodyFromString("OK, It`s 1C:Hotel");
	Return vResponse;
EndFunction

// -----------------------------------------------------------------------------
Function AnyGET(qRequest)
	vResponse = New HTTPServiceResponse(200);
	vResponse.SetBodyFromString("OK, It`s 1C:Hotel");
	vResponse.Headers.Insert("Content-type", "Text; charset=utf-8");
	Return vResponse;
EndFunction

// -----------------------------------------------------------------------------
Function GetTouristTaxListPOST(pRequest)  
	vResponseParam = GetEmptyResponceStructure();     
	vErr = Nstr("en = 'The module for working with tourist tax declarations is not connected.'; 
				|de = 'Das Modul zur Bearbeitung von Kurtaxenerklärungen ist nicht angebunden.'; 
				|ru = 'Не подключен модуль работы с декларациями по тур. налогу
                 |Обратитесь в службу технической поддержки по e-mail: support@1chotel.ru'");
	vResponseParam.ErrorDescription = vErr;
	vResponse = GetResponce(vResponseParam);
	Return vResponse;
EndFunction

// -----------------------------------------------------------------------------
Function WriteTouristTaxExternalCodePOST(pRequest)
	vResponseParam = GetEmptyResponceStructure();     
	vErr = Nstr("en = 'The module for working with tourist tax declarations is not connected.'; 
				|de = 'Das Modul zur Bearbeitung von Kurtaxenerklärungen ist nicht angebunden.'; 
				|ru = 'Не подключен модуль работы с декларациями по тур. налогу
                 |Обратитесь в службу технической поддержки по e-mail: support@1chotel.ru'");
	vResponseParam.ErrorDescription = vErr;
	vResponse = GetResponce(vResponseParam);
	Return vResponse;
EndFunction

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function CheckFilling(pCheckParams, pSource, pErr = "")
	vCheck = True;
	vMsg = NStr("en = 'Parameter %1 is empty';de = 'Parameter %1 fehlt';ru = 'Параметр %1 не заполнен'");
	For Each vId In pCheckParams Do
		If Not ValueIsFilled(pSource[vId]) Then
			pErr = pErr + Chars.LF + StrTemplate(vMsg, vId);
			vCheck = False;
		EndIf;
	EndDo;
	Return vCheck;
EndFunction

// -----------------------------------------------------------------------------
Function GetEmptyResponceStructure()
	vResponseParam = New Structure;
	vResponseParam.Insert("ErrorDescription", "");
	vResponseParam.Insert("Success", False);
	Return vResponseParam;
EndFunction

// -----------------------------------------------------------------------------
Function GetResponce(pParams, pInteraction = Undefined, pRequestDescription = "AccountingDataExchange")
	// Check result
	If pParams.Success Then
		vResponse = New HTTPServiceResponse(200);
		vEventType = Enums.ExternalSystemEventTypes.Info;
	Else
		vResponse = New HTTPServiceResponse(400);
		vEventType = Enums.ExternalSystemEventTypes.Error;
	EndIf;     
	
	vJson = Catalogs.DataConvertationRules.MapToJSON(pParams);
	// Log
	If Not pInteraction = Undefined And pInteraction.DebugMode Then
		vMsg = NStr("en = 'Response'; de = 'Antwort'; ru = 'Ответ'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteraction, pRequestDescription, vEventType, , vJson, vMsg, , 999999999);
	EndIf;
	vResponse.Headers.Insert("Content-type", "application/JSON; charset=utf-8");	
	// Set response
	vResponse.SetBodyFromString(vJson);
	Return vResponse;
EndFunction //  ErrorResponce()

// -----------------------------------------------------------------------------
Function CheckExternalInteraction(pExternalParameters)
	vExternalCode = pExternalParameters.ExternalCode;
	vExtDBName = "";
	If pExternalParameters.Property("DBName") Then
		vExtDBName = pExternalParameters.DBName;
	EndIf;	
	If vExternalCode = Undefined Or vExternalCode = "" Then
		vExternalCode = String(New UUID);
		AddExternalSystemInteraction(vExternalCode, vExtDBName);
	Else
		vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(vExternalCode);
		If vInteraction = Undefined Then
			AddExternalSystemInteraction(vExternalCode, vExtDBName);
		EndIf;
	EndIf;
	vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(vExternalCode);
	Return vInteraction;
EndFunction

// -----------------------------------------------------------------------------
Function GetInteraction(pExternalCode, pMsg = "")
	vInteraction =  Undefined;
	If pExternalCode = Undefined Or IsBlankString(pExternalCode) Then
		pMsg = NStr(
		"en = 'External system code not set'; de = 'Externer Systemcode nicht festgelegt'; ru = 'Код внешней системы не задан'");
	Else
		vInteractions = cmGetInteractionByID(pExternalCode, True);
		If vInteractions.Count() > 1 Then
			pMsg = NStr(
			"en='More then one interactions found with given interaction ID!'; de='More then one interactions found with given interaction ID!'; ru='В справочнике внешних взаимодействий уже существует более одного взаимодействия с переданным идентификатором!'");
		ElsIf vInteractions.Count() = 1 Then
			vInteraction = vInteractions.Get(0).Ref;
			If Not vInteraction.IsActive Then
				pMsg = NStr(
				"en='Interaction with given interaction ID is not active!'; de='Interaction with given interaction ID is not active!'; ru='Взаимодействие с переданным идентификатором не активно!'");
			EndIf;
		Else
			pMsg = NStr(
			"en='Interaction with given interaction ID is not found!'; de='Interaction with given interaction ID is not found!'; ru='В справочнике внешних взаимодействий не существует взаимодействия с переданным идентификатором!'");
		EndIf;
	EndIf;
	Return vInteraction;
EndFunction //  ErrorResponce()

// -----------------------------------------------------------------------------
Procedure AddExternalSystemInteraction(Val pExternalCode, pExtDBName = "")
	vDBName = NStr("en = 'Accounting'; de = 'Buchhaltung'; ru = 'Бухгалтерия'");
	If Not IsBlankString(pExtDBName) Then
		vDBName = StrTemplate(NStr("en = 'Exchange with %1'; de = 'Austausch mit %1'; ru = 'Обмен с %1'"), pExtDBName);
	EndIf;	
	SetPrivilegedMode(True);
	vObj = Catalogs.ExternalSystemInteractions.CreateItem();
	vObj.Description = vDBName;
	vObj.Code = String(New UUID);
	vObj.InteractionID = pExternalCode;
	vObj.IntegrationType = Enums.Integrations.Accounting;
	vObj.Hotel = SessionParameters.CurrentHotel;
	vObj.WebhookURL =  GetInfoBaseURL();
	vObj.IsActive = True;
	vObj.Write();
	SetPrivilegedMode(False);
EndProcedure

// -----------------------------------------------------------------------------
Function GetCatalogItemEmptyStructure()
	vObj = New Structure("Code, Description, ExternalCode, UUID", "", "", "", "");
	
	Return vObj;
	
EndFunction //  GetCatalogItemEmptyStructure() 

// -----------------------------------------------------------------------------
Function GetDocumentCCRDEmptyStructure()
	
	vStruct = New Structure;
	vStruct.Insert("PeriodFrom", "");
	vStruct.Insert("PeriodTo", "");
	vStruct.Insert("AccountingDate", "");
	vStruct.Insert("Company", "");
	vStruct.Insert("Hotel", "");
	vStruct.Insert("Customer", "");
	vStruct.Insert("ExternalCode", "");
	vStruct.Insert("Currency", "");
	vStruct.Insert("PaymentMethod", "");
	vStruct.Insert("CashRegister", "");
	vStruct.Insert("Sum", 0);
	vStruct.Insert("DocumentNumber", "");
	vStruct.Insert("PaymentsTable", New Array);
	vStruct.Insert("UUID", "");
	vStruct.Insert("Author", "");
	vStruct.Insert("ExternalRef", "");
	Return vStruct;
	
EndFunction //  GetDocumenpCCRDEmptyStructure()

// -----------------------------------------------------------------------------
Function GetDocumentPaymentEmptyStructure()
	
	vStruct = New Structure;
	vStruct.Insert("Period", "");
	vStruct.Insert("DocumentNumber", "");
	vStruct.Insert("Company", "");
	vStruct.Insert("Hotel", "");
	vStruct.Insert("Customer", "");
	vStruct.Insert("Contract", "");
	vStruct.Insert("GuestGroup", "");
	vStruct.Insert("Folio", "");
	vStruct.Insert("Currency", "");
	vStruct.Insert("PaymentMethod", "");
	vStruct.Insert("PaymentSection", "");
	vStruct.Insert("CashRegister", "");
	vStruct.Insert("VatSum", 0);
	vStruct.Insert("VATRate", "");
	vStruct.Insert("Client", "");
	vStruct.Insert("Service", "");
	vStruct.Insert("Quantity", "");
	vStruct.Insert("Sum", 0);
	vStruct.Insert("ExternalCode", "");
	vStruct.Insert("UUID", "");
	
	Return vStruct;
	
EndFunction //  GetDocumentPaymentEmptyStructure()

// -----------------------------------------------------------------------------
Function GetDocumentSettlementEmptyStructure()
	
	vStruct = New Structure;
	vStruct.Insert("Period", "");
	vStruct.Insert("DocumentNumber", "");
	vStruct.Insert("Company", "");
	vStruct.Insert("Hotel", "");
	vStruct.Insert("Customer", ""); 
	vStruct.Insert("Agent", "");
	vStruct.Insert("Contract", "");
	vStruct.Insert("GuestGroup", "");
	vStruct.Insert("Currency", "");
	vStruct.Insert("PaymentSection", "");
	vStruct.Insert("CommissionSum", "");
	vStruct.Insert("VatSum", 0);
	vStruct.Insert("VATRate", "");
	vStruct.Insert("Remarks", "");
	vStruct.Insert("SumDue", "");
	vStruct.Insert("Sum", 0);
	vStruct.Insert("InvoiceNumber", "");
	vStruct.Insert("ExternalCode", "");
	vStruct.Insert("UUID", "");
	vStruct.Insert("Services", New Array);
	vStruct.Insert("ExternalRef", "");
	
	Return vStruct;
	
EndFunction //  GetDocumentInvoiceEmptyStructure()

// -----------------------------------------------------------------------------
Function GetDocumentSettlementServicesEmptyStructure()
	
	vStruct = New Structure;
	vStruct.Insert("AccountingDate", "");
	vStruct.Insert("AccommodationType", "");
	vStruct.Insert("Resource", "");
	vStruct.Insert("NumberOfPersons", 0);
	vStruct.Insert("Client", "");
	vStruct.Insert("Room", "");
	vStruct.Insert("RoomType", "");
	vStruct.Insert("Customer", "");
	vStruct.Insert("Contract", "");
	vStruct.Insert("GuestGroup", "");
	vStruct.Insert("Folio", "");
	vStruct.Insert("Currency", "");
	vStruct.Insert("PaymentMethod", "");
	vStruct.Insert("PaymentSection", "");
	vStruct.Insert("CashRegister", "");
	vStruct.Insert("VatSum", 0);
	vStruct.Insert("VATRate", "");
	vStruct.Insert("Service", "");
	vStruct.Insert("Price", 0);
	vStruct.Insert("Unit", "");
	vStruct.Insert("Quantity", 0);
	vStruct.Insert("Sum", 0);
	vStruct.Insert("Remarks", "");
	vStruct.Insert("IsInPrice", "");
	vStruct.Insert("IsRoomRevenue", "");
	vStruct.Insert("IsResourceRevenue", "");
	vStruct.Insert("Agent", "");
	vStruct.Insert("AgentCommissionType", "");
	vStruct.Insert("AgentCommission", "");
	vStruct.Insert("VATCommissionSum", 0);
	vStruct.Insert("CommissionSum",0);
	vStruct.Insert("HotelProduct", "");
	
	Return vStruct;
	
EndFunction //  GetDocumentPaymentEmptyStructure()

// -----------------------------------------------------------------------------
Function GetDocumentProformaInvoiceEmptyStructure()
	
	vStruct = New Structure;
	vStruct.Insert("Period", "");
	vStruct.Insert("DocumentNumber", "");
	vStruct.Insert("Company", "");
	vStruct.Insert("Hotel", "");
	vStruct.Insert("Customer", "");
	vStruct.Insert("Contract", "");
	vStruct.Insert("GuestGroup", "");
	vStruct.Insert("Currency", "");
	vStruct.Insert("Remarks", "");
	vStruct.Insert("Sum", 0);
	vStruct.Insert("VATSum", 0);
	vStruct.Insert("ExternalCode", "");
	vStruct.Insert("UUID", "");
	vStruct.Insert("Services", New Array);
	vStruct.Insert("ExternalRef", "");
	
	Return vStruct;
	
EndFunction //  GetDocumentInvoiceEmptyStructure()

// -----------------------------------------------------------------------------
Function GetDocumentProformaInvoiceServicesEmptyStructure()
	
	vStruct = New Structure;
	vStruct.Insert("AccountingDate", "");
	vStruct.Insert("AccommodationType", "");
	vStruct.Insert("Resource", "");
	vStruct.Insert("NumberOfPersons", 0);
	vStruct.Insert("Client", "");
	vStruct.Insert("Room", "");
	vStruct.Insert("RoomType", "");
	vStruct.Insert("GuestGroup", "");
	vStruct.Insert("VatSum", 0);
	vStruct.Insert("VATRate", "");
	vStruct.Insert("Service", "");
	vStruct.Insert("Price", 0);
	vStruct.Insert("Unit", "");
	vStruct.Insert("Quantity", 0);
	vStruct.Insert("Sum", 0);
	vStruct.Insert("Discount", "");
	vStruct.Insert("DiscountSum", 0);
	vStruct.Insert("Remarks", "");
	vStruct.Insert("IsInPrice", "");
	vStruct.Insert("IsRoomRevenue", "");
	vStruct.Insert("IsResourceRevenue", "");
	vStruct.Insert("Agent", "");
	vStruct.Insert("AgentCommissionType", "");
	vStruct.Insert("AgentCommission", "");
	vStruct.Insert("VATCommissionSum", 0);
	vStruct.Insert("CommissionSum", 0);
	vStruct.Insert("HotelProduct", "");
	vStruct.Insert("Folio", "");
	
	Return vStruct;
	
EndFunction //  GetDocumentPaymentEmptyStructure()

// -----------------------------------------------------------------------------
Function FillCatalogObject(pRef, pInteraction, pOnce = False)
	vObjArr = GetCatalogItemEmptyStructure();
	If TypeOf(pRef) = Type("CatalogRef.Customers") Then
		vObjArr.Insert("LegacyName");
		vObjArr.Insert("Phone");
		vObjArr.Insert("EMail");
		vObjArr.Insert("TIN");
		vObjArr.Insert("KPP");
		vObjArr.Insert("CustomerType");
		vObjArr.Insert("IsIndividual"); 
		vObjArr.Insert("VATC");
		vObjArr.Insert("Country");
	ElsIf TypeOf(pRef) = Type("CatalogRef.Services") Then
		vObjArr.Insert("Unit");
		vObjArr.Insert("IsRoomRevenue");
		vObjArr.Insert("IsInPrice");
		vObjArr.Insert("IsResourceRevenue");
		vObjArr.Insert("DoNotGroupIntoRoomRateOnPrint");
		vObjArr.Insert("SplitToSeparateSettlements");
		vObjArr.Insert("DoNotExportToTheAccountingSystem");
		vObjArr.Insert("Unit");
		vObjArr.Insert("ServiceType");
		vObjArr.Insert("IsStockArticle");
		vObjArr.Insert("IsAgentService");
		vObjArr.Insert("IsHotelProductService");
		vObjArr.Insert("IsGiftCertificate");
		vObjArr.Insert("BonusPaymentsNotAllowed");
		vObjArr.Insert("BonusPaymentsNotAllowed");
	ElsIf TypeOf(pRef) = Type("CatalogRef.PaymentMethods") Then
		vObjArr.Insert("BookByCashRegister");
		vObjArr.Insert("PrintCheque");
		vObjArr.Insert("PrintNonFiscalCheque");
		vObjArr.Insert("IsByCash");
		vObjArr.Insert("IsByCreditCard");
		vObjArr.Insert("IsByBankTransfer");
		vObjArr.Insert("IsByBonuses");
		vObjArr.Insert("IsByGiftCertificate");
		vObjArr.Insert("IsForReturnOnly");
		vObjArr.Insert("IsForExtraServiceFolioOnly");
		vObjArr.Insert("IsViaInternetAcquiring");
		vObjArr.Insert("IsCloseToTheRoom");
		vObjArr.Insert("IsCloseToTheFolio");
		vObjArr.Insert("ExternalBankTerminalIsUsed");
		vObjArr.Insert("DoNotExportToTheAccountingSystem");
	ElsIf TypeOf(pRef) = Type("CatalogRef.Contracts") Then
		vObjArr.Insert("IsActsHisOwnBehalf", False);
		vObjArr.Insert("Customer");
		vObjArr.Insert("CustomerExternalCode");  
		vObjArr.Insert("Date");
		vObjArr.Insert("ValidFromDate");
		vObjArr.Insert("ValidToDate");
	ElsIf TypeOf(pRef) = Type("CatalogRef.Clients") Then
		vObjArr.Insert("LastName");
		vObjArr.Insert("FirstName");
		vObjArr.Insert("SecondName");
		vObjArr.Insert("FullName");
		vObjArr.Insert("DateOfBirth");  
	ElsIf TypeOf(pRef) = Type("CatalogRef.Countries") Then
		vObjArr.Insert("ISOCode");
		vObjArr.Insert("ISOCode3");
		vObjArr.Insert("IsVisaNecessaryForEntrance");
	EndIf;   
	
	If ValueIsFilled(pRef) Then
		FillPropertyValues(vObjArr, pRef);
		vObjArr.UUID = XMLString(pRef);
		vObjArr.ExternalCode = GetObjectExternalSystemCodeByRef(pInteraction, pRef);
		If TypeOf(pRef) = Type("CatalogRef.Services") And Not pRef.IsFolder And Not pOnce Then
			vObjArr.Insert("HideIntoServiceOnPrint");
			vObjArr.HideIntoServiceOnPrint = FillCatalogObject(pRef.HideIntoServiceOnPrint, pInteraction, True);
		ElsIf TypeOf(pRef) = Type("CatalogRef.Contracts") And ValueIsFilled(pRef.ContractType) Then 	
			vObjArr.IsActsHisOwnBehalf = pRef.ContractType.TypeAgencyContract = Enums.TypeAgencyContract.ActsHisOwnBehalf;
			vObjArr.Customer = FillCatalogObject(pRef.Owner, pInteraction);
			vObjArr.CustomerExternalCode = GetObjectExternalSystemCodeByRef(pInteraction, pRef.Owner);
		ElsIf TypeOf(pRef) = Type("CatalogRef.RoomTypes") Then
			vObjArr.Description = pRef.GetObject().pmGetRoomTypeDescription(SessionParameters.CurrentLanguage);   
		ElsIf TypeOf(pRef) = Type("CatalogRef.Customers") Then	
			vObjArr.Country = FillCatalogObject(pRef.Country, pInteraction);
		EndIf;	 
	EndIf;
	Return vObjArr;
EndFunction //  FillCatalogObject()

// -----------------------------------------------------------------------------
Function FillPayment(Val mRow, Val pInteraction)
	
	vPayment = GetDocumentPaymentEmptyStructure();
	vPayment.Period			= mRow.Period;
	vPayment.DocumentNumber	= mRow.Recorder.Number;
	vPayment.Customer       = FillCatalogObject(mRow.Customer, pInteraction);
	vPayment.Contract       = FillCatalogObject(mRow.Contract, pInteraction);
	vPayment.Currency	    = FillCatalogObject(mRow.Currency, pInteraction);
	vPayment.PaymentMethod 	= FillCatalogObject(mRow.PaymentMethod, pInteraction);
	vPayment.PaymentSection = FillCatalogObject(mRow.PaymentSection, pInteraction);
	vPayment.Company		= FillCatalogObject(mRow.Company, pInteraction);
	vPayment.CashRegister	= FillCatalogObject(mRow.CashRegister, pInteraction);
	vPayment.Hotel	        = FillCatalogObject(mRow.Hotel, pInteraction);
	vPayment.Client	        = FillCatalogObject(mRow.Payer, pInteraction);
	vPayment.GuestGroup     = FillCatalogObject(mRow.GuestGroup, pInteraction);
	vPayment.Folio          = New Structure("DateTimeFrom, DateTimeTo, Number, Description", mRow.Folio.DateTimeFrom,
	mRow.Folio.DateTimeTo, mRow.Folio.Number, mRow.Folio.Description);
	vPayment.VATRate        = New Structure("TaxRate, Description", mRow.VATRate.TaxRate, mRow.VATRate.Description);
	vPayment.Service		= FillCatalogObject(mRow.ChequeService, pInteraction);
	vPayment.Quantity       = mRow.Quantity;
	vPayment.VATSum		    = mRow.VATSum;
	vPayment.Sum 			= mRow.Sum;
	vPayment.ExternalCode	= mRow.ExternalCode;
	vPayment.UUID			= XMLString(mRow.Recorder);
	Return vPayment;
	
EndFunction

// -----------------------------------------------------------------------------
Function FillCCRDHeader(Val pInteraction, Val pTrans)
	
	vDoc = GetDocumentCCRDEmptyStructure();
	
	vDoc.PeriodFrom 	= pTrans.ref.DateFrom;
	vDoc.PeriodTo 		= pTrans.ref.Date;
	vDoc.AccountingDate = pTrans.ref.AccountingDate;
	vDoc.Customer       = FillCatalogObject(pTrans.Customer, pInteraction);
	vDoc.Currency	    = FillCatalogObject(pTrans.Currency, pInteraction);
	vDoc.PaymentMethod 	= FillCatalogObject(pTrans.PaymentMethod, pInteraction);
	vDoc.Company		= FillCatalogObject(pTrans.Company, pInteraction);
	vDoc.CashRegister	= FillCatalogObject(pTrans.CashRegister, pInteraction);
	vDoc.DocumentNumber	= pTrans.ref.Number;
	vDoc.Sum 			= pTrans.Sum;
	vDoc.Author 		= pTrans.ref.Author;
	vDoc.ExternalCode	= pTrans.ExternalCode;
	vDoc.UUID			= XMLString(pTrans.ref);
	vDoc.Hotel			= FillCatalogObject(pTrans.CashRegister.Hotel, pInteraction);
	If Not IsBlankString(pInteraction.WebhookURL) Then
		vDoc.ExternalRef = TrimAll(pInteraction.WebhookURL) + "#" + GetURL(pTrans.ref);
	EndIf;
	
	Return vDoc;
	
EndFunction //  GetBankAndCashMapping()

// -----------------------------------------------------------------------------
Function FillSettlementHeader(Val pInteraction, Val pDocRow)
	
	vDoc = GetDocumentSettlementEmptyStructure();
	
	vGuestGroup = pDocRow.GuestGroup;
	vCustomer = pDocRow.AccountingCustomer; 
	vContract = pDocRow.AccountingContract;
	vAgent = vGuestGroup.Agent; 
	
	If ValueIsFilled(vGuestGroup) And ValueIsFilled(vCustomer) And vCustomer.IsIndividual = False Then  
		If Not ValueIsFilled(vContract) And ValueIsFilled(vGuestGroup.Contract) Then
			vContract = vGuestGroup.Contract;
		EndIf;	
		If vContract.ContractType.TypeAgencyContract = Enums.TypeAgencyContract.ActsHisOwnBehalf And ValueIsFilled(vGuestGroup.Customer) Then	
			vCustomer = vGuestGroup.Customer;
			vAgent = vGuestGroup.Agent;
		EndIf;	
	EndIf;	
	
	vDoc.Period 		= pDocRow.Date;
	vDoc.DocumentNumber	= pDocRow.Number;
	vDoc.Hotel 			= FillCatalogObject(pDocRow.Hotel, pInteraction);
	vDoc.Customer       = FillCatalogObject(vCustomer, pInteraction);
	vDoc.Contract 		= FillCatalogObject(vContract, pInteraction); 
	vDoc.Agent       	= FillCatalogObject(vAgent, pInteraction);
	vDoc.Currency	    = FillCatalogObject(pDocRow.AccountingCurrency, pInteraction);
	vDoc.PaymentSection = FillCatalogObject(pDocRow.Ref.PaymentSection, pInteraction);
	vDoc.Company		= FillCatalogObject(pDocRow.Company, pInteraction);
	vDoc.CommissionSum	= pDocRow.Ref.CommissionSum;
	vDoc.Sum			= pDocRow.Sum;
	vDoc.SumDue			= pDocRow.Ref.SumDue;
	vDoc.GuestGroup     = FillCatalogObject(pDocRow.GuestGroup, pInteraction);
	vDoc.VATRate        = New Structure("TaxRate, Description", pDocRow.Ref.VATRate.TaxRate, pDocRow.Ref.VATRate.Description);
	vDoc.VATSum		    = pDocRow.Ref.VATSum;
	vDoc.InvoiceNumber	= pDocRow.InvoiceNumber;
	vDoc.ExternalCode	= pDocRow.ExternalCode;
	vDoc.UUID			= XMLString(pDocRow.ref);
	If Not IsBlankString(pInteraction.WebhookURL) Then
		vDoc.ExternalRef = TrimAll(pInteraction.WebhookURL) + "#" + GetURL(pDocRow.Ref);
	EndIf;
	
	Return vDoc;
EndFunction //  FillSettlementHeader()

// -----------------------------------------------------------------------------
Function FillSettlementServicesRow(Val pRow, Val pInteraction)
	
	vServiceRow = GetDocumentSettlementServicesEmptyStructure();
	vServiceRow.Client	        	= FillCatalogObject(pRow.Client, pInteraction);
	vServiceRow.Room	        	= FillCatalogObject(pRow.Room, pInteraction);
	vServiceRow.RoomType        	= FillCatalogObject(pRow.Room.RoomType, pInteraction);
	vServiceRow.AccountingDate		= pRow.AccountingDate;
	vServiceRow.AccommodationType	= FillCatalogObject(pRow.AccommodationType, pInteraction);
	vServiceRow.Resource       		= FillCatalogObject(pRow.Resource, pInteraction);
	vServiceRow.NumberOfPersons		= pRow.NumberOfPersons;
	vServiceRow.Service				= FillCatalogObject(pRow.Service, pInteraction);
	vServiceRow.Price 				= pRow.Price;
	vServiceRow.Unit 				= TrimAll(pRow.Unit);
	vServiceRow.Quantity       		= pRow.Quantity;
	vServiceRow.Sum 				= pRow.Sum;
	vServiceRow.VATRate        		= New Structure("TaxRate, Description", pRow.VATRate.TaxRate, pRow.VATRate.Description);
	vServiceRow.VATSum		    	= pRow.VATSum;
	vServiceRow.Remarks 			= TrimAll(pRow.Remarks);
	vServiceRow.IsInPrice		    = pRow.IsInPrice;
	vServiceRow.IsRoomRevenue		= pRow.IsRoomRevenue;
	vServiceRow.IsResourceRevenue	= pRow.IsResourceRevenue;
	vServiceRow.Customer       		= FillCatalogObject(pRow.Customer, pInteraction);
	vServiceRow.Contract       		= FillCatalogObject(pRow.Contract, pInteraction);
	vServiceRow.Currency	    	= FillCatalogObject(pRow.FolioCurrency, pInteraction);
	vServiceRow.GuestGroup     		= FillCatalogObject(pRow.GuestGroup, pInteraction);
	vServiceRow.Folio          		= New Structure("DateTimeFrom, DateTimeTo, Number, Description", pRow.Folio.DateTimeFrom, pRow.Folio.DateTimeTo, pRow.Folio.Number, pRow.Folio.Description);
	vServiceRow.Agent       		= FillCatalogObject(pRow.Agent, pInteraction);
	vServiceRow.AgentCommissionType = String(pRow.AgentCommissionType);
	vServiceRow.AgentCommission 	= pRow.AgentCommission;
	vServiceRow.CommissionSum		= pRow.CommissionSum;
	vServiceRow.VATCommissionSum	= pRow.VATCommissionSum;
	vServiceRow.HotelProduct		= FillCatalogObject(pRow.HotelProduct, pInteraction);
	Return vServiceRow;
	
EndFunction

// -----------------------------------------------------------------------------
Function FillProformaInvoiceHeader(Val pInteraction, Val pDocRow)
	
	vDoc = GetDocumentProformaInvoiceEmptyStructure();
	
	vDoc.Period 		= pDocRow.Date;
	vDoc.DocumentNumber	= pDocRow.Number;
	vDoc.Hotel 			= FillCatalogObject(pDocRow.Hotel, pInteraction);
	vDoc.Customer       = FillCatalogObject(pDocRow.AccountingCustomer, pInteraction);
	vDoc.Contract 		= FillCatalogObject(pDocRow.AccountingContract, pInteraction);
	vDoc.Currency	    = FillCatalogObject(pDocRow.AccountingCurrency, pInteraction);
	vDoc.Company		= FillCatalogObject(pDocRow.Company, pInteraction);
	vDoc.Sum			= pDocRow.Sum;
	vDoc.GuestGroup     = FillCatalogObject(pDocRow.GuestGroup, pInteraction);
	vDoc.VATSum		    = pDocRow.Ref.VATSum;
	vDoc.ExternalCode	= pDocRow.ExternalCode;
	vDoc.Remarks		= pDocRow.Remarks;
	vDoc.UUID			= XMLString(pDocRow.ref);
	
	If Not IsBlankString(pInteraction.WebhookURL) Then
		vDoc.ExternalRef = TrimAll(pInteraction.WebhookURL) + "#" + GetURL(pDocRow.ref);
	EndIf;
	
	Return vDoc;
	
EndFunction //  FillSettlementHeader()

// -----------------------------------------------------------------------------
Function FillProformaInvoiceServicesRow(Val pRow, Val pInteraction)
	
	vServiceRow = GetDocumentProformaInvoiceServicesEmptyStructure();
	vServiceRow.Client = FillCatalogObject(pRow.Client, pInteraction);
	If TypeOf(pRow.Room) = Type("CatalogRef.Rooms") Then
		vServiceRow.Room = FillCatalogObject(pRow.Room, pInteraction);
	ElsIf TypeOf(pRow.Room) = Type("String") Then
		vRoom = FillCatalogObject(Catalogs.Rooms.EmptyRef(), pInteraction);
		vRoom.Description = TrimAll(pRow.Room);
		vServiceRow.Room = vRoom;
	Else	
		vRoom = FillCatalogObject(Catalogs.Rooms.EmptyRef(), pInteraction);
		vRoom.Description = TrimAll(pRow.Room);
	EndIf;
	vServiceRow.AccountingDate		= pRow.AccountingDate;
	vServiceRow.AccommodationType	= FillCatalogObject(pRow.AccommodationType, pInteraction);
	vServiceRow.Resource       		= FillCatalogObject(pRow.Resource, pInteraction);
	vServiceRow.NumberOfPersons		= pRow.NumberOfPersons;
	vServiceRow.Service				= FillCatalogObject(pRow.Service, pInteraction);
	vServiceRow.Price 				= pRow.Price;
	vServiceRow.Unit 				= TrimAll(pRow.Unit);
	vServiceRow.Quantity       		= pRow.Quantity;
	vServiceRow.Sum 				= pRow.Sum;
	vServiceRow.VATRate        		= New Structure("TaxRate, Description", pRow.VATRate.TaxRate, pRow.VATRate.Description);
	vServiceRow.Folio          		= New Structure("DateTimeFrom, DateTimeTo, Number, Description", pRow.DateTimeFrom, pRow.DateTimeTo, "", "");
	vServiceRow.VATSum		    	= pRow.VATSum;
	vServiceRow.Remarks 			= TrimAll(pRow.Remarks);
	vServiceRow.IsInPrice		    = pRow.IsInPrice;
	vServiceRow.IsRoomRevenue		= pRow.IsRoomRevenue;
	vServiceRow.IsResourceRevenue	= pRow.IsResourceRevenue;
	vServiceRow.Discount       		= pRow.Discount;
	vServiceRow.DiscountSum       	= pRow.DiscountSum;
	vServiceRow.GuestGroup     		= FillCatalogObject(pRow.GuestGroup, pInteraction);
	vServiceRow.Agent       		= FillCatalogObject(pRow.Agent, pInteraction);
	vServiceRow.AgentCommissionType = String(pRow.AgentCommissionType);
	vServiceRow.AgentCommission 	= pRow.AgentCommission;
	vServiceRow.CommissionSum		= pRow.CommissionSum;
	vServiceRow.VATCommissionSum	= pRow.VATCommissionSum;
	vServiceRow.HotelProduct		= FillCatalogObject(pRow.HotelProduct, pInteraction);
	Return vServiceRow;
	
EndFunction

// -----------------------------------------------------------------------------
Function GetBankAndCashQueryText()
	vTxtQuery = "SELECT DISTINCT
	|	CCRDAccountingTotals.ExternalCode AS ExternalCode,
	|	CCRDAccountingTotals.Ref AS CCRDRef,
	|	CCRDAccountingTotals.Customer AS Customer,
	|	CCRDAccountingTotals.Currency AS Currency,
	|	CCRDAccountingTotals.PaymentMethod AS PaymentMethod
	|INTO CCRD
	|FROM
	|	Document.CloseOfCashRegisterDay.AccountingTotals AS CCRDAccountingTotals
	|WHERE
	|	CASE
	|			WHEN &qUseAccountingDate
	|					AND NOT CCRDAccountingTotals.Ref.CashRegister.Hotel.AccountingDate IS NULL
	|					AND NOT CCRDAccountingTotals.Ref.CashRegister.Hotel.AccountingDate = DATETIME(1, 1, 1)
	|				THEN CCRDAccountingTotals.Ref.AccountingDate >= &qDateFrom
	|						AND CCRDAccountingTotals.Ref.AccountingDate <= &qDateTo
	|			ELSE CCRDAccountingTotals.Ref.Date >= &qDateFrom
	|					AND CCRDAccountingTotals.Ref.Date <= &qDateTo
	|		END
	|	AND CASE
	|			WHEN &qCompanyIsEmpty = FALSE
	|				THEN CCRDAccountingTotals.Ref.Company IN (&qCompany)
	|			ELSE TRUE
	|		END
	|	AND CCRDAccountingTotals.Ref.DeletionMark = FALSE
	|	AND CCRDAccountingTotals.Ref.Posted
	|	AND CASE
	|			WHEN &qHotelIsEmpty = FALSE
	|				THEN CCRDAccountingTotals.Ref.CashRegister.Hotel In (&qHotel)
	|			ELSE TRUE
	|		END
	|	AND CCRDAccountingTotals.PaymentMethod.DoNotExportToTheAccountingSystem = FALSE
	|
	|GROUP BY
	|	CCRDAccountingTotals.ExternalCode,
	|	CCRDAccountingTotals.Ref,
	|	CCRDAccountingTotals.PaymentMethod,
	|	CCRDAccountingTotals.Customer,
	|	CCRDAccountingTotals.Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CashRegisterDailyReceipts.Payment AS Payment,
	|	CCRD.ExternalCode AS ExternalCode,
	|	CCRD.CCRDRef AS CCRDRef,
	|	CCRD.Customer AS Customer,
	|	CCRD.Currency AS Currency,
	|	CCRD.PaymentMethod AS PaymentMethod
	|INTO PaymentsTab
	|FROM
	|	AccumulationRegister.CashRegisterDailyReceipts AS CashRegisterDailyReceipts
	|		LEFT JOIN CCRD AS CCRD
	|		ON CashRegisterDailyReceipts.Recorder = CCRD.CCRDRef
	|			AND CashRegisterDailyReceipts.Payment.AccountingCustomer = CCRD.Customer
	|			AND CashRegisterDailyReceipts.Currency = CCRD.Currency
	|			AND CashRegisterDailyReceipts.PaymentMethod = CCRD.PaymentMethod
	|WHERE
	|	CashRegisterDailyReceipts.Recorder IN
	|			(SELECT
	|				CCRD.CCRDRef AS CCRDRef
	|			FROM
	|				CCRD AS CCRD)
	|	AND CashRegisterDailyReceipts.Payment.Date >= CCRD.CCRDRef.DateFrom
	|	AND CashRegisterDailyReceipts.Payment.Date <= CCRD.CCRDRef.Date
	|	AND CashRegisterDailyReceipts.PaymentMethod.DoNotExportToTheAccountingSystem = FALSE
	|
	|GROUP BY
	|	CashRegisterDailyReceipts.Payment,
	|	CCRD.ExternalCode,
	|	CCRD.CCRDRef,
	|	CCRD.Customer,
	|	CCRD.Currency,
	|	CCRD.PaymentMethod
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Accounts.Hotel AS Hotel,
	|	Accounts.PaymentSection AS PaymentSection,
	|	Accounts.PaymentMethod AS PaymentMethod,
	|	PaymentsTab.Payment.AccountingCustomer AS Customer,
	|	PaymentsTab.Payment.AccountingContract AS Contract,
	|	Accounts.ChequeService AS ChequeService,
	|	PaymentsTab.CCRDRef.CashRegister AS CCRDRefCashRegister,
	|	PaymentsTab.CCRDRef.Company AS CCRDRefCompany
	|INTO TempCommonTab
	|FROM
	|	PaymentsTab AS PaymentsTab
	|		LEFT JOIN AccumulationRegister.Accounts AS Accounts
	|		ON PaymentsTab.Payment = Accounts.Recorder
	|			AND PaymentsTab.PaymentMethod = Accounts.PaymentMethod
	|			AND PaymentsTab.Currency = Accounts.FolioCurrency
	|			AND PaymentsTab.Customer = Accounts.Recorder.AccountingCustomer
	|WHERE
	|	Accounts.Recorder IN
	|			(SELECT
	|				PaymentsTab.Payment AS Payment
	|			FROM
	|				PaymentsTab AS PaymentsTab)
	|
	|GROUP BY
	|	Accounts.ChequeService,
	|	Accounts.Hotel,
	|	Accounts.PaymentMethod,
	|	Accounts.PaymentSection,
	|	PaymentsTab.Payment.AccountingCustomer,
	|	PaymentsTab.Payment.AccountingContract,
	|	PaymentsTab.CCRDRef.CashRegister,
	|	PaymentsTab.CCRDRef.Company
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TempCommonTab.PaymentSection AS Ref,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """") AS ObjectExternalCode
	|FROM
	|	TempCommonTab AS TempCommonTab
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON TempCommonTab.PaymentSection = ExternalSystemIntegrationData.RefKey1
	|			AND (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem)
	|
	|GROUP BY
	|	TempCommonTab.PaymentSection,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """")
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TempCommonTab.PaymentMethod AS Ref,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """") AS ObjectExternalCode
	|FROM
	|	TempCommonTab AS TempCommonTab
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON TempCommonTab.PaymentMethod = ExternalSystemIntegrationData.RefKey1
	|			AND (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem)
	|
	|GROUP BY
	|	TempCommonTab.PaymentMethod,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """")
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TempCommonTab.Customer AS Ref,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """") AS ObjectExternalCode
	|FROM
	|	TempCommonTab AS TempCommonTab
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON TempCommonTab.Customer = ExternalSystemIntegrationData.RefKey1
	|			AND (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem)
	|
	|GROUP BY
	|	TempCommonTab.Customer,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """")
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TempCommonTab.Contract AS Ref,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """") AS ObjectExternalCode
	|FROM
	|	TempCommonTab AS TempCommonTab
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON TempCommonTab.Contract = ExternalSystemIntegrationData.RefKey1
	|			AND (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem)
	|
	|GROUP BY
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """"),
	|	TempCommonTab.Contract
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TempCommonTab.ChequeService AS Ref,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """") AS ObjectExternalCode
	|FROM
	|	TempCommonTab AS TempCommonTab
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON TempCommonTab.ChequeService = ExternalSystemIntegrationData.RefKey1
	|			AND (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem)
	|
	|GROUP BY
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """"),
	|	TempCommonTab.ChequeService
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TempCommonTab.CCRDRefCashRegister AS Ref,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """") AS ObjectExternalCode
	|FROM
	|	TempCommonTab AS TempCommonTab
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON TempCommonTab.CCRDRefCashRegister = ExternalSystemIntegrationData.RefKey1
	|			AND (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem)
	|
	|GROUP BY
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """"),
	|	TempCommonTab.CCRDRefCashRegister
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TempCommonTab.CCRDRefCompany AS Ref,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """") AS ObjectExternalCode
	|FROM
	|	TempCommonTab AS TempCommonTab
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON TempCommonTab.CCRDRefCompany = ExternalSystemIntegrationData.RefKey1
	|			AND (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem)
	|
	|GROUP BY
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """"),
	|	TempCommonTab.CCRDRefCompany
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TempCommonTab.Hotel AS Ref,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """") AS ObjectExternalCode
	|FROM
	|	TempCommonTab AS TempCommonTab
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON TempCommonTab.Hotel = ExternalSystemIntegrationData.RefKey1
	|			AND (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem)
	|
	|GROUP BY
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """"),
	|	TempCommonTab.Hotel";
	Return vTxtQuery;
EndFunction    

// -----------------------------------------------------------------------------
Function GetSettlementsMappingQueryText()
	vTxtQuery = "SELECT
	|	NULL AS plug
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Settlement.AccountingCustomer AS Customer,
	|	Settlement.AccountingContract AS Contract,
	|	Settlement.PaymentMethod AS PaymentMethod,
	|	Settlement.PaymentSection AS PaymentSection,
	|	Settlement.Company AS Company,
	|	NULL AS Service,
	|	NULL AS CashRegister,
	|	Settlement.Hotel AS Hotel
	|INTO TempTab
	|FROM
	|	Document.Settlement AS Settlement
	|WHERE
	|	Settlement.ChangeDate >= &qDateFrom
	|	AND Settlement.ChangeDate <= &qDateTo
	|	AND CASE
	|			WHEN &qCompanyIsEmpty = FALSE
	|				THEN Settlement.Company IN (&qCompany)
	|			ELSE TRUE
	|		END
	|	AND Settlement.Posted
	|	AND Settlement.DeletionMark = FALSE
	|	AND CASE
	|			WHEN &qHotelIsEmpty = FALSE
	|				THEN Settlement.Hotel In (&qHotel)
	|			ELSE TRUE
	|		END
	|
	|UNION ALL
	|
	|SELECT
	|	SettlementServices.Customer,
	|	SettlementServices.Contract,
	|	NULL,
	|	NULL,
	|	NULL,
	|	SettlementServices.Service,
	|	NULL,
	|	NULL
	|FROM
	|	Document.Settlement.Services AS SettlementServices
	|WHERE
	|	SettlementServices.Ref.Posted
	|	AND SettlementServices.Ref.DeletionMark = FALSE
	|	AND SettlementServices.Ref.ChangeDate >= &qDateFrom
	|	AND SettlementServices.Ref.ChangeDate <= &qDateTo
	|	AND CASE
	|			WHEN &qCompanyIsEmpty = FALSE
	|				THEN SettlementServices.Ref.Company IN (&qCompany)
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN &qHotelIsEmpty = FALSE
	|				THEN SettlementServices.Ref.Hotel In (&qHotel)
	|			ELSE TRUE
	|		END
	|
	|UNION ALL
	|
	|SELECT
	|	SettlementServices.Agent,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL
	|FROM
	|	Document.Settlement.Services AS SettlementServices
	|WHERE
	|	SettlementServices.Ref.Posted
	|	AND SettlementServices.Ref.DeletionMark = FALSE
	|	AND SettlementServices.Ref.ChangeDate >= &qDateFrom
	|	AND SettlementServices.Ref.ChangeDate <= &qDateTo
	|	AND CASE
	|			WHEN &qCompanyIsEmpty = FALSE
	|				THEN SettlementServices.Ref.Company IN (&qCompany)
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN &qHotelIsEmpty = FALSE
	|				THEN SettlementServices.Ref.Hotel In (&qHotel)
	|			ELSE TRUE
	|		END
	|
	|UNION ALL
	|
	|SELECT
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	"""",
	|	NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TempTab.Customer AS Customer,
	|	TempTab.Contract AS Contract,
	|	TempTab.PaymentMethod AS PaymentMethod,
	|	TempTab.PaymentSection AS PaymentSection,
	|	TempTab.Company AS Company,
	|	TempTab.Service AS Service,
	|	TempTab.CashRegister AS CashRegister,
	|	TempTab.Hotel AS Hotel
	|INTO InvoiceData
	|FROM
	|	TempTab AS TempTab
	|
	|GROUP BY
	|	TempTab.Company,
	|	TempTab.PaymentMethod,
	|	TempTab.PaymentSection,
	|	TempTab.Service,
	|	TempTab.Contract,
	|	TempTab.Customer,
	|	TempTab.CashRegister,
	|	TempTab.Hotel
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InvoiceData.Customer AS Ref,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """") AS ObjectExternalCode
	|FROM
	|	InvoiceData AS InvoiceData
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON InvoiceData.Customer = ExternalSystemIntegrationData.RefKey1
	|			AND (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem)
	|WHERE
	|	NOT InvoiceData.Customer IS NULL
	|
	|GROUP BY
	|	InvoiceData.Customer,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """")
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InvoiceData.Contract AS Ref,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """") AS ObjectExternalCode
	|FROM
	|	InvoiceData AS InvoiceData
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON InvoiceData.Contract = ExternalSystemIntegrationData.RefKey1
	|			AND (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem)
	|WHERE
	|	NOT InvoiceData.Contract IS NULL
	|
	|GROUP BY
	|	InvoiceData.Contract,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """")
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InvoiceData.PaymentMethod AS Ref,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """") AS ObjectExternalCode
	|FROM
	|	InvoiceData AS InvoiceData
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON InvoiceData.PaymentMethod = ExternalSystemIntegrationData.RefKey1
	|			AND (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem)
	|WHERE
	|	InvoiceData.PaymentMethod.DoNotExportToTheAccountingSystem = FALSE
	|	AND NOT InvoiceData.PaymentMethod = VALUE(Catalog.PaymentMethods.Settlement)
	|	AND NOT InvoiceData.PaymentMethod IS NULL
	|
	|GROUP BY
	|	InvoiceData.PaymentMethod,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """")
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InvoiceData.PaymentSection AS Ref,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """") AS ObjectExternalCode
	|FROM
	|	InvoiceData AS InvoiceData
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON InvoiceData.PaymentSection = ExternalSystemIntegrationData.RefKey1
	|			AND (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem)
	|WHERE
	|	NOT InvoiceData.PaymentSection IS NULL
	|
	|GROUP BY
	|	InvoiceData.PaymentSection,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """")
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InvoiceData.Company AS Ref,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """") AS ObjectExternalCode
	|FROM
	|	InvoiceData AS InvoiceData
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON InvoiceData.Company = ExternalSystemIntegrationData.RefKey1
	|			AND (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem)
	|WHERE
	|	NOT InvoiceData.Company IS NULL
	|
	|GROUP BY
	|	InvoiceData.Company,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """")
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InvoiceData.Service AS Ref,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """") AS ObjectExternalCode
	|FROM
	|	InvoiceData AS InvoiceData
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON InvoiceData.Service = ExternalSystemIntegrationData.RefKey1
	|			AND (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem)
	|WHERE
	|	NOT InvoiceData.Service IS NULL
	|
	|GROUP BY
	|	InvoiceData.Service,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """")
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InvoiceData.CashRegister AS Ref,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """") AS ObjectExternalCode
	|FROM
	|	InvoiceData AS InvoiceData
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem)
	|			AND InvoiceData.CashRegister = ExternalSystemIntegrationData.RefKey1
	|WHERE
	|	NOT InvoiceData.CashRegister IS NULL
	|
	|GROUP BY
	|	InvoiceData.CashRegister,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """")
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InvoiceData.Hotel AS Ref,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """") AS ObjectExternalCode
	|FROM
	|	InvoiceData AS InvoiceData
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem)
	|			AND InvoiceData.Hotel = ExternalSystemIntegrationData.RefKey1
	|WHERE
	|	NOT InvoiceData.Hotel IS NULL
	|
	|GROUP BY
	|	InvoiceData.Hotel,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """")";
	Return vTxtQuery;
EndFunction    

// -----------------------------------------------------------------------------
Function GetInvoicesMappingQueryText()
	vTxtQuery = "SELECT
	|	NULL AS plug
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Settlement.AccountingCustomer AS Customer,
	|	Settlement.AccountingContract AS Contract,
	|	NULL AS PaymentMethod,
	|	NULL AS PaymentSection,
	|	Settlement.Company AS Company,
	|	NULL AS Service,
	|	NULL AS CashRegister,
	|	Settlement.Hotel AS Hotel
	|INTO TempTab
	|FROM
	|	Document.ProformaInvoice AS Settlement
	|WHERE
	|	Settlement.ChangeDate >= &qDateFrom
	|	AND Settlement.ChangeDate <= &qDateTo
	|	AND CASE
	|			WHEN &qCompanyIsEmpty = FALSE
	|				THEN Settlement.Company In (&qCompany)
	|			ELSE TRUE
	|		END
	|	AND Settlement.Posted
	|	AND Settlement.DeletionMark = FALSE
	|	AND CASE
	|			WHEN &qHotelIsEmpty = FALSE
	|				THEN Settlement.Hotel In (&qHotel)
	|			ELSE TRUE
	|		END
	|
	|UNION ALL
	|
	|SELECT
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	SettlementServices.Service,
	|	NULL,
	|	NULL
	|FROM
	|	Document.ProformaInvoice.Services AS SettlementServices
	|WHERE
	|	SettlementServices.Ref.Posted
	|	AND SettlementServices.Ref.DeletionMark = FALSE
	|	AND SettlementServices.Ref.ChangeDate >= &qDateFrom
	|	AND SettlementServices.Ref.ChangeDate <= &qDateTo
	|	AND CASE
	|			WHEN &qCompanyIsEmpty = FALSE
	|				THEN SettlementServices.Ref.Company In (&qCompany)
	|			ELSE TRUE
	|		END
	|	AND NOT SettlementServices.Ref IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	SettlementServices.Agent,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL
	|FROM
	|	Document.ProformaInvoice.Services AS SettlementServices
	|WHERE
	|	SettlementServices.Ref.Posted
	|	AND SettlementServices.Ref.DeletionMark = FALSE
	|	AND SettlementServices.Ref.ChangeDate >= &qDateFrom
	|	AND SettlementServices.Ref.ChangeDate <= &qDateTo
	|	AND CASE
	|			WHEN &qCompanyIsEmpty = FALSE
	|				THEN SettlementServices.Ref.Company In (&qCompany)
	|			ELSE TRUE
	|		END
	|	AND NOT SettlementServices.Agent IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TempTab.Customer AS Customer,
	|	TempTab.Contract AS Contract,
	|	TempTab.PaymentMethod AS PaymentMethod,
	|	TempTab.PaymentSection AS PaymentSection,
	|	TempTab.Company AS Company,
	|	TempTab.Service AS Service,
	|	TempTab.CashRegister AS CashRegister,
	|	TempTab.Hotel AS Hotel
	|INTO InvoiceData
	|FROM
	|	TempTab AS TempTab
	|
	|GROUP BY
	|	TempTab.Company,
	|	TempTab.PaymentMethod,
	|	TempTab.PaymentSection,
	|	TempTab.Service,
	|	TempTab.Contract,
	|	TempTab.Customer,
	|	TempTab.CashRegister,
	|	TempTab.Hotel
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InvoiceData.Customer AS Ref,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """") AS ObjectExternalCode
	|FROM
	|	InvoiceData AS InvoiceData
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON InvoiceData.Customer = ExternalSystemIntegrationData.RefKey1
	|			AND (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem)
	|WHERE
	|	NOT InvoiceData.Customer = VALUE(Catalog.Customers.EmptyRef)
	|	AND NOT InvoiceData.Customer.Ref IS NULL
	|
	|GROUP BY
	|	InvoiceData.Customer,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """")
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InvoiceData.Contract AS Ref,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """") AS ObjectExternalCode
	|FROM
	|	InvoiceData AS InvoiceData
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON InvoiceData.Contract = ExternalSystemIntegrationData.RefKey1
	|			AND (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem)
	|WHERE
	|	NOT InvoiceData.Contract.Ref IS NULL
	|	AND NOT InvoiceData.Contract = VALUE(Catalog.Contracts.EmptyRef)
	|
	|GROUP BY
	|	InvoiceData.Contract,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """")
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InvoiceData.PaymentMethod AS Ref,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """") AS ObjectExternalCode
	|FROM
	|	InvoiceData AS InvoiceData
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON InvoiceData.PaymentMethod = ExternalSystemIntegrationData.RefKey1
	|			AND (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem)
	|WHERE
	|	NOT InvoiceData.PaymentMethod IS NULL
	|
	|GROUP BY
	|	InvoiceData.PaymentMethod,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """")
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InvoiceData.PaymentSection AS Ref,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """") AS ObjectExternalCode
	|FROM
	|	InvoiceData AS InvoiceData
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON InvoiceData.PaymentSection = ExternalSystemIntegrationData.RefKey1
	|			AND (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem)
	|WHERE
	|	NOT InvoiceData.PaymentSection IS NULL
	|
	|GROUP BY
	|	InvoiceData.PaymentSection,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """")
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InvoiceData.Company AS Ref,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """") AS ObjectExternalCode
	|FROM
	|	InvoiceData AS InvoiceData
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON InvoiceData.Company = ExternalSystemIntegrationData.RefKey1
	|			AND (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem)
	|WHERE
	|	NOT InvoiceData.Company.Ref IS NULL
	|	AND NOT InvoiceData.Company = VALUE(Catalog.Companies.EmptyRef)
	|
	|GROUP BY
	|	InvoiceData.Company,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """")
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InvoiceData.Service AS Ref,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """") AS ObjectExternalCode
	|FROM
	|	InvoiceData AS InvoiceData
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON InvoiceData.Service = ExternalSystemIntegrationData.RefKey1
	|			AND (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem)
	|WHERE
	|	NOT InvoiceData.Service.Ref IS NULL
	|	AND NOT InvoiceData.Service.Ref = VALUE(Catalog.Services.EmptyRef)
	|
	|GROUP BY
	|	InvoiceData.Service,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """")
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InvoiceData.CashRegister AS Ref,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """") AS ObjectExternalCode
	|FROM
	|	InvoiceData AS InvoiceData
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem)
	|			AND InvoiceData.CashRegister = ExternalSystemIntegrationData.RefKey1
	|WHERE
	|	NOT InvoiceData.CashRegister IS NULL
	|
	|GROUP BY
	|	InvoiceData.CashRegister,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """")
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InvoiceData.Hotel AS Ref,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """") AS ObjectExternalCode
	|FROM
	|	InvoiceData AS InvoiceData
	|		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|		ON (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem)
	|			AND InvoiceData.Hotel = ExternalSystemIntegrationData.RefKey1
	|WHERE
	|	NOT InvoiceData.Hotel.Ref IS NULL
	|	AND NOT InvoiceData.Hotel.Ref = VALUE(Catalog.Hotels.EmptyRef)
	|
	|GROUP BY
	|	InvoiceData.Hotel,
	|	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """")";
	Return vTxtQuery;
EndFunction

// -----------------------------------------------------------------------------
Function GetTouristTaxMappingQueryText(pInteraction)
	vTxtQuery = "SELECT
	            |	NULL AS plug
	            |;
	            |
	            |////////////////////////////////////////////////////////////////////////////////
	            |SELECT
	            |	Value(Catalog.Customers.EmptyRef) AS Customer,
	            |	Value(Catalog.Contracts.EmptyRef) AS Contract,
	            |	Value(Catalog.PaymentMethods.EmptyRef) AS PaymentMethod,
	            |	Value(Catalog.PaymentSections.EmptyRef) AS PaymentSection,
	            |	Value(Catalog.Companies.EmptyRef) AS Company,
	            |	Value(Catalog.Services.EmptyRef) AS Service,
	            |	Value(Catalog.CashRegisters.EmptyRef) AS CashRegister,
	            |	Value(Catalog.Hotels.EmptyRef) AS Hotel
	            |INTO TempTab
	            |
	            |UNION ALL
	            |
	            |SELECT
	            |	NULL,
	            |	NULL,
	            |	NULL,
	            |	NULL,
	            |	NULL,
	            |	NULL,
	            |	NULL,
	            |	NULL
	            |
	            |UNION ALL
	            |
	            |SELECT
	            |	NULL,
	            |	NULL,
	            |	NULL,
	            |	NULL,
	            |	NULL,
	            |	NULL,
	            |	NULL,
	            |	NULL
	            |
	            |UNION ALL
	            |
	            |SELECT
	            |	NULL,
	            |	NULL,
	            |	NULL,
	            |	NULL,
	            |	NULL,
	            |	NULL,
	            |	NULL,
	            |	NULL
	            |;
	            |
	            |////////////////////////////////////////////////////////////////////////////////
	            |SELECT
	            |	Customer AS Customer,
	            |	Contract AS Contract,
	            |	PaymentMethod AS PaymentMethod,
	            |	PaymentSection AS PaymentSection,
	            |	Company AS Company,
	            |	Service AS Service,
	            |	CashRegister AS CashRegister,
	            |	Hotel AS Hotel
	            |INTO InvoiceData
	            |FROM
	            |	TempTab AS TempTab
	            |
	            |GROUP BY
	            |	TempTab.Company,
	            |	TempTab.PaymentMethod,
	            |	TempTab.PaymentSection,
	            |	TempTab.Service,
	            |	TempTab.Contract,
	            |	TempTab.Customer,
	            |	TempTab.CashRegister,
	            |	TempTab.Hotel
	            |;
	            |
	            |////////////////////////////////////////////////////////////////////////////////
	            |SELECT
	            |	InvoiceData.Customer AS Ref,
	            |	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """") AS ObjectExternalCode
	            |FROM
	            |	InvoiceData AS InvoiceData
	            |		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	            |		ON InvoiceData.Customer = ExternalSystemIntegrationData.RefKey1
	            |			AND (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem)
	            |WHERE
	            |	NOT InvoiceData.Customer = VALUE(Catalog.Customers.EmptyRef)
	            |	AND NOT InvoiceData.Customer.Ref IS NULL
	            |
	            |GROUP BY
	            |	InvoiceData.Customer,
	            |	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """")
	            |;
	            |
	            |////////////////////////////////////////////////////////////////////////////////
	            |SELECT
	            |	InvoiceData.Contract AS Ref,
	            |	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """") AS ObjectExternalCode
	            |FROM
	            |	InvoiceData AS InvoiceData
	            |		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	            |		ON InvoiceData.Contract = ExternalSystemIntegrationData.RefKey1
	            |			AND (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem)
	            |WHERE
	            |	NOT InvoiceData.Contract.Ref IS NULL
	            |	AND NOT InvoiceData.Contract = VALUE(Catalog.Contracts.EmptyRef)
	            |
	            |GROUP BY
	            |	InvoiceData.Contract,
	            |	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """")
	            |;
	            |
	            |////////////////////////////////////////////////////////////////////////////////
	            |SELECT
	            |	InvoiceData.PaymentMethod AS Ref,
	            |	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """") AS ObjectExternalCode
	            |FROM
	            |	InvoiceData AS InvoiceData
	            |		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	            |		ON InvoiceData.PaymentMethod = ExternalSystemIntegrationData.RefKey1
	            |			AND (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem)
	            |WHERE
	            |	NOT InvoiceData.PaymentMethod IS NULL
	            |
	            |GROUP BY
	            |	InvoiceData.PaymentMethod,
	            |	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """")
	            |;
	            |
	            |////////////////////////////////////////////////////////////////////////////////
	            |SELECT
	            |	InvoiceData.PaymentSection AS Ref,
	            |	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """") AS ObjectExternalCode
	            |FROM
	            |	InvoiceData AS InvoiceData
	            |		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	            |		ON InvoiceData.PaymentSection = ExternalSystemIntegrationData.RefKey1
	            |			AND (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem)
	            |WHERE
	            |	NOT InvoiceData.PaymentSection IS NULL
	            |
	            |GROUP BY
	            |	InvoiceData.PaymentSection,
	            |	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """")
	            |;
	            |
	            |////////////////////////////////////////////////////////////////////////////////
	            |SELECT
	            |	InvoiceData.Company AS Ref,
	            |	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """") AS ObjectExternalCode
	            |FROM
	            |	InvoiceData AS InvoiceData
	            |		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	            |		ON InvoiceData.Company = ExternalSystemIntegrationData.RefKey1
	            |			AND (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem)
	            |WHERE
	            |	NOT InvoiceData.Company.Ref IS NULL
	            |	AND NOT InvoiceData.Company = VALUE(Catalog.Companies.EmptyRef)
	            |
	            |GROUP BY
	            |	InvoiceData.Company,
	            |	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """")
	            |;
	            |
	            |////////////////////////////////////////////////////////////////////////////////
	            |SELECT
	            |	InvoiceData.Service AS Ref,
	            |	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """") AS ObjectExternalCode
	            |FROM
	            |	InvoiceData AS InvoiceData
	            |		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	            |		ON InvoiceData.Service = ExternalSystemIntegrationData.RefKey1
	            |			AND (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem)
	            |WHERE
	            |	NOT InvoiceData.Service.Ref IS NULL
	            |	AND NOT InvoiceData.Service.Ref = VALUE(Catalog.Services.EmptyRef)
	            |
	            |GROUP BY
	            |	InvoiceData.Service,
	            |	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """")
	            |;
	            |
	            |////////////////////////////////////////////////////////////////////////////////
	            |SELECT
	            |	InvoiceData.CashRegister AS Ref,
	            |	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """") AS ObjectExternalCode
	            |FROM
	            |	InvoiceData AS InvoiceData
	            |		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	            |		ON (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem)
	            |			AND InvoiceData.CashRegister = ExternalSystemIntegrationData.RefKey1
	            |WHERE
	            |	NOT InvoiceData.CashRegister IS NULL
	            |
	            |GROUP BY
	            |	InvoiceData.CashRegister,
	            |	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """")
	            |;
	            |
	            |////////////////////////////////////////////////////////////////////////////////
	            |SELECT
	            |	InvoiceData.Hotel AS Ref,
	            |	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """") AS ObjectExternalCode
	            |FROM
	            |	InvoiceData AS InvoiceData
	            |		LEFT JOIN InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	            |		ON (ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem)
	            |			AND InvoiceData.Hotel = ExternalSystemIntegrationData.RefKey1
	            |WHERE
	            |	NOT InvoiceData.Hotel.Ref IS NULL
	            |	AND NOT InvoiceData.Hotel.Ref = VALUE(Catalog.Hotels.EmptyRef)
	            |
	            |GROUP BY
	            |	InvoiceData.Hotel,
	            |	ISNULL(ExternalSystemIntegrationData.ExternalSystemDataCode, """")";
	Return vTxtQuery;
EndFunction

// -----------------------------------------------------------------------------
Function GetPaymentListDetails(pPeriodFrom, pPeriodTo, pCompany, pHotel, pUseAccountingDate = False)
	
	vQry = New Query;
	vQry.Text = "SELECT DISTINCT
	|	CCRDAccountingTotals.ExternalCode AS ExternalCode,
	|	CCRDAccountingTotals.Ref AS CCRDRef,
	|	CCRDAccountingTotals.Customer AS Customer,
	|	CCRDAccountingTotals.Currency AS Currency,
	|	CCRDAccountingTotals.PaymentMethod AS PaymentMethod
	|INTO CCRD
	|FROM
	|	Document.CloseOfCashRegisterDay.AccountingTotals AS CCRDAccountingTotals
	|WHERE
	|	CASE
	|			WHEN &qUseAccountingDate
	|					AND NOT CCRDAccountingTotals.Ref.CashRegister.Hotel.AccountingDate IS NULL
	|					AND NOT CCRDAccountingTotals.Ref.CashRegister.Hotel.AccountingDate = DATETIME(1, 1, 1)
	|				THEN CCRDAccountingTotals.Ref.AccountingDate >= &qDateFrom
	|						AND CCRDAccountingTotals.Ref.AccountingDate <= &qDateTo
	|			ELSE CCRDAccountingTotals.Ref.Date >= &qDateFrom
	|					AND CCRDAccountingTotals.Ref.Date <= &qDateTo
	|		END
	|	AND CASE
	|			WHEN &qCompanyIsEmpty = FALSE
	|				THEN CCRDAccountingTotals.Ref.Company IN (&qCompany)
	|			ELSE TRUE
	|		END
	|	AND CCRDAccountingTotals.Ref.DeletionMark = FALSE
	|	AND CCRDAccountingTotals.Ref.Posted
	|	AND CASE
	|			WHEN &qHotelIsEmpty = FALSE
	|				THEN CCRDAccountingTotals.Ref.CashRegister.Hotel IN (&qHotel)
	|			ELSE TRUE
	|		END
	|
	|GROUP BY
	|	CCRDAccountingTotals.ExternalCode,
	|	CCRDAccountingTotals.Ref,
	|	CCRDAccountingTotals.PaymentMethod,
	|	CCRDAccountingTotals.Customer,
	|	CCRDAccountingTotals.Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CashRegisterDailyReceipts.Payment AS Payment,
	|	CCRD.ExternalCode AS ExternalCode,
	|	CCRD.CCRDRef AS CCRDRef,
	|	CCRD.Customer AS Customer,
	|	CCRD.Currency AS Currency,
	|	CCRD.PaymentMethod AS PaymentMethod
	|INTO PaymentsTab
	|FROM
	|	AccumulationRegister.CashRegisterDailyReceipts AS CashRegisterDailyReceipts
	|		LEFT JOIN CCRD AS CCRD
	|		ON CashRegisterDailyReceipts.Recorder = CCRD.CCRDRef
	|			AND CashRegisterDailyReceipts.Payment.AccountingCustomer = CCRD.Customer
	|			AND CashRegisterDailyReceipts.Currency = CCRD.Currency
	|			AND CashRegisterDailyReceipts.PaymentMethod = CCRD.PaymentMethod
	|WHERE
	|	CashRegisterDailyReceipts.Recorder IN
	|			(SELECT
	|				CCRD.CCRDRef AS CCRDRef
	|			FROM
	|				CCRD AS CCRD)
	|	AND CashRegisterDailyReceipts.Payment.Date >= CCRD.CCRDRef.DateFrom
	|	AND CashRegisterDailyReceipts.Payment.Date <= CCRD.CCRDRef.Date
	|
	|GROUP BY
	|	CashRegisterDailyReceipts.Payment,
	|	CCRD.ExternalCode,
	|	CCRD.CCRDRef,
	|	CCRD.Customer,
	|	CCRD.Currency,
	|	CCRD.PaymentMethod
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Accounts.Period AS Period,
	|	PaymentsTab.Payment AS Recorder,
	|	Accounts.Hotel AS Hotel,
	|	Accounts.FolioCurrency AS Currency,
	|	Accounts.PaymentSection AS PaymentSection,
	|	Accounts.PaymentMethod AS PaymentMethod,
	|	PaymentsTab.Payment.AccountingCustomer AS Customer,
	|	PaymentsTab.Payment.AccountingContract AS Contract,
	|	PaymentsTab.Payment.GuestGroup AS GuestGroup,
	|	PaymentsTab.Payment.Payer AS Payer,
	|	Accounts.Folio AS Folio,
	|	Accounts.VATRate AS VATRate,
	|	Accounts.ChequeService AS ChequeService,
	|	SUM(CASE
	|			WHEN ISNULL(Accounts.ChequeServiceQuantity, 1) = 0
	|				THEN 1
	|			ELSE ISNULL(Accounts.ChequeServiceQuantity, 1)
	|		END) AS Quantity,
	|	Accounts.ChequeServicePrice AS ChequeServicePrice,
	|	Accounts.VATSum AS VATSum,
	|	SUM(Accounts.Sum) AS Sum,
	|	PaymentsTab.CCRDRef AS CCRDRef,
	|	PaymentsTab.ExternalCode AS ExternalCode,
	|	PaymentsTab.CCRDRef.Company AS Company,
	|	PaymentsTab.CCRDRef.CashRegister AS CashRegister,
	|	CASE
	|		WHEN PaymentsTab.Payment REFS Document.Payment
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS IsPayment
	|FROM
	|	PaymentsTab AS PaymentsTab
	|		LEFT JOIN AccumulationRegister.Accounts AS Accounts
	|		ON PaymentsTab.Payment = Accounts.Recorder
	|			AND PaymentsTab.PaymentMethod = Accounts.PaymentMethod
	|			AND PaymentsTab.Currency = Accounts.FolioCurrency
	|			AND PaymentsTab.Customer = Accounts.Recorder.AccountingCustomer
	|WHERE
	|	Accounts.Recorder IN
	|			(SELECT
	|				PaymentsTab.Payment AS Payment
	|			FROM
	|				PaymentsTab AS PaymentsTab)
	|
	|GROUP BY
	|	Accounts.ChequeService,
	|	Accounts.ChequeServicePrice,
	|	Accounts.Period,
	|	Accounts.Hotel,
	|	Accounts.FolioCurrency,
	|	Accounts.VATRate,
	|	Accounts.VATSum,
	|	Accounts.PaymentMethod,
	|	Accounts.PaymentSection,
	|	PaymentsTab.Payment.AccountingCustomer,
	|	PaymentsTab.Payment.AccountingContract,
	|	PaymentsTab.Payment.GuestGroup,
	|	PaymentsTab.Payment.Payer,
	|	PaymentsTab.Payment,
	|	Accounts.Folio,
	|	PaymentsTab.CCRDRef,
	|	PaymentsTab.ExternalCode,
	|	PaymentsTab.CCRDRef.Company,
	|	PaymentsTab.CCRDRef.CashRegister,
	|	CASE
	|		WHEN PaymentsTab.Payment REFS Document.Payment
	|			THEN TRUE
	|		ELSE FALSE
	|	END";
	
	vQry.SetParameter("qDateFrom", pPeriodFrom);
	vQry.SetParameter("qDateTo", pPeriodTo);
	vQry.SetParameter("qCompany", pCompany);
	vQry.SetParameter("qCompanyIsEmpty", pCompany.Count() = 0);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qHotelIsEmpty", pHotel.Count() = 0);
	vQry.SetParameter("qUseAccountingDate", pUseAccountingDate);
	
	Return vQry.Execute().Unload();
	
EndFunction //  GetPaymentListQuery()

// -----------------------------------------------------------------------------
Function GetAccountingTotals(pPeriodFrom, pPeriodTo, pCompany, pHotel, pUseAccountingDate = False)
	
	vQry = New Query;
	vQry.Text = "SELECT
	|	CCRDAccountingTotals.Ref AS Ref,
	|	CCRDAccountingTotals.Currency AS Currency,
	|	CCRDAccountingTotals.PaymentMethod AS PaymentMethod,
	|	CCRDAccountingTotals.Customer AS Customer,
	|	CCRDAccountingTotals.Sum AS Sum,
	|	CCRDAccountingTotals.ExternalCode AS ExternalCode,
	|	CCRDAccountingTotals.Ref.Company AS Company,
	|	CCRDAccountingTotals.Ref.CashRegister AS CashRegister,
	|	CCRDAccountingTotals.IsPayment AS IsPayment
	|FROM
	|	Document.CloseOfCashRegisterDay.AccountingTotals AS CCRDAccountingTotals
	|WHERE
	|	CASE
	|			WHEN &qUseAccountingDate
	|					AND NOT CCRDAccountingTotals.Ref.CashRegister.Hotel.AccountingDate IS NULL
	|					AND NOT CCRDAccountingTotals.Ref.CashRegister.Hotel.AccountingDate = DATETIME(1, 1, 1)
	|				THEN CCRDAccountingTotals.Ref.AccountingDate >= &qDateFrom
	|						AND CCRDAccountingTotals.Ref.AccountingDate <= &qDateTo
	|			ELSE CCRDAccountingTotals.Ref.Date >= &qDateFrom
	|					AND CCRDAccountingTotals.Ref.Date <= &qDateTo
	|		END
	|	AND CASE
	|			WHEN &qCompanyIsEmpty = FALSE
	|				THEN CCRDAccountingTotals.Ref.Company IN (&qCompany)
	|			ELSE TRUE
	|		END
	|	AND CCRDAccountingTotals.Ref.DeletionMark = FALSE
	|	AND CCRDAccountingTotals.Ref.Posted
	|	AND CCRDAccountingTotals.PaymentMethod.DoNotExportToTheAccountingSystem = FALSE
	|	AND CASE
	|			WHEN &qHotelIsEmpty = FALSE
	|				THEN CCRDAccountingTotals.Ref.CashRegister.Hotel IN (&qHotel)
	|			ELSE TRUE
	|		END";
	
	vQry.SetParameter("qDateFrom", pPeriodFrom);
	vQry.SetParameter("qDateTo", pPeriodTo);
	vQry.SetParameter("qCompany", pCompany);
	vQry.SetParameter("qCompanyIsEmpty", pCompany.Count() = 0);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qHotelIsEmpty", pHotel.Count() = 0);
	vQry.SetParameter("qUseAccountingDate", pUseAccountingDate);
	
	Return vQry.Execute();
	
EndFunction //  GetAccountingTotalsQueryText()

// -----------------------------------------------------------------------------
Function GetObjectMapping(pRequestType, pInteraction, pInputParameters)
	// Get company
	vCompanyCode = pInputParameters.CompanyCode;
	If IsBlankString(vCompanyCode) Then
		vCompanyArr = New Array;
	Else
		vCompanyArr = GetObjectRefByExternalSystemCode(pInteraction, "Companies", vCompanyCode, True);
	EndIf;
	// Get hotel
	vHotelCode = pInputParameters.HotelCode;
	If IsBlankString(vHotelCode) Then
		vHotelArr = New Array;;
	Else
		vHotelArr = GetObjectRefByExternalSystemCode(pInteraction, "Hotels", vHotelCode, True);
	EndIf;
	
	vUseAccountingDate = (pInputParameters.Property("UseAccountingDate") And pInputParameters.UseAccountingDate);
	
	vResult = New Structure;
	vResult.Insert("Companies", New Array);
	vResult.Insert("Customers", New Array);
	vResult.Insert("Contracts", New Array);
	vResult.Insert("PaymentMethods", New Array);
	vResult.Insert("PaymentSections", New Array);
	vResult.Insert("Services", New Array);
	vResult.Insert("CashRegisters", New Array);
	vResult.Insert("Hotels", New Array);
	
	If pRequestType = "BankAndCash" Then
		vQryText = GetBankAndCashQueryText();
	ElsIf pRequestType = "Settlements" Then
		vQryText = GetSettlementsMappingQueryText();
	ElsIf pRequestType = "Ivoices" Then
		vQryText = GetInvoicesMappingQueryText();
	ElsIf pRequestType = "TouristTax" Then
		vQryText = GetTouristTaxMappingQueryText(pInteraction);	
	Else
		Raise Nstr("en = 'Request undefined'; de = 'Anfrage undefiniert'; ru = 'Тип запроса не определен'");
	EndIf;
	
	vQry = New Query;
	vQry.Text = vQryText;
	vQry.SetParameter("qDateFrom", pInputParameters.PeriodFrom);
	vQry.SetParameter("qDateTo", pInputParameters.PeriodTo);
	vQry.SetParameter("qCompany", vCompanyArr);
	vQry.SetParameter("qCompanyIsEmpty", vCompanyArr.Count() = 0);
	vQry.SetParameter("qExternalSystem", pInteraction);
	vQry.SetParameter("qHotel", vHotelArr);
	vQry.SetParameter("qHotelIsEmpty", vHotelArr.Count() = 0);
	If pRequestType = "BankAndCash" Then
		vQry.SetParameter("qUseAccountingDate", vUseAccountingDate);
	EndIf;	
	
	vQryRes = vQry.ExecuteBatch();
	
	For i = 3 To 10 Do
		vRes = vQryRes[i].Select();
		While vRes.Next() Do
			vRef = vRes.Ref;
			If ValueIsFilled(vRef) Then
				vObjArr = GetCatalogItemEmptyStructure();
				If TypeOf(vRef) = Type("CatalogRef.PaymentMethods") Then
					vObjArr = tcOnServer.cmGetAtributeAsArray(vRef);
					vObjArr.Insert("UUID");
				ElsIf TypeOf(vRef) = Type("CatalogRef.Customers") Then
					vObjArr.Insert("LegacyName");
					vObjArr.Insert("Phone");
					vObjArr.Insert("EMail");
					vObjArr.Insert("TIN");
					vObjArr.Insert("KPP");
					vObjArr.Insert("CustomerType");
					vObjArr.Insert("IsIndividual");
				ElsIf TypeOf(vRef) = Type("CatalogRef.Services") Then
					vObjArr.Insert("Unit");
					vObjArr.Insert("IsRoomRevenue");
					vObjArr.Insert("IsInPrice");
					vObjArr.Insert("IsResourceRevenue");
					vObjArr.Insert("DoNotGroupIntoRoomRateOnPrint");
					vObjArr.Insert("SplitToSeparateSettlements");
					vObjArr.Insert("DoNotExportToTheAccountingSystem");
					vObjArr.Insert("Unit");
					vObjArr.Insert("ServiceType");
					vObjArr.Insert("IsStockArticle");
					vObjArr.Insert("IsAgentService");
					vObjArr.Insert("IsHotelProductService");
					vObjArr.Insert("IsGiftCertificate");
					vObjArr.Insert("BonusPaymentsNotAllowed");
				ElsIf TypeOf(vRef) = Type("CatalogRef.Contracts") Then
					vObjArr.Insert("IsActsHisOwnBehalf", False);
					vObjArr.Insert("Customer");
					vObjArr.Insert("CustomerExternalCode");
				EndIf;
				FillPropertyValues(vObjArr, vRef);
				vObjArr.ExternalCode = vRes.ObjectExternalCode;
				vObjArr.UUID = XMLString(vRef);
				If TypeOf(vRef) = Type("CatalogRef.Contracts") Then
					If ValueIsFilled(vRef.ContractType) Then
						vObjArr.IsActsHisOwnBehalf = vRef.ContractType.TypeAgencyContract = Enums.TypeAgencyContract.ActsHisOwnBehalf;
					EndIf;
					vObjArr.Customer = FillCatalogObject(vRef.Owner, pInteraction);
					vObjArr.CustomerExternalCode = GetObjectExternalSystemCodeByRef(pInteraction, vRef.Owner);
				EndIf;	
				
				vResult[vRef.Metadata().Name].Add(vObjArr);
			EndIf;
		EndDo;
	EndDo;
	
	Return vResult;
EndFunction //  GetBankAndCashMapping()

// -----------------------------------------------------------------------------
Function GetPaymentList(pInteraction, pInputParameters)
	// Get company
	vCompanyCode = pInputParameters.CompanyCode;
	If IsBlankString(vCompanyCode) Then
		vCompanyArr = New Array;
	Else
		vCompanyArr = GetObjectRefByExternalSystemCode(pInteraction, "Companies", vCompanyCode, True);
	EndIf;
	// Get hotel
	vHotelCode = pInputParameters.HotelCode;
	If IsBlankString(vHotelCode) Then
		vHotelArr = New Array;;
	Else
		vHotelArr = GetObjectRefByExternalSystemCode(pInteraction, "Hotels", vHotelCode, True);
	EndIf;
	
	vDocs = New Array;
	vUseAccountingDate = (pInputParameters.Property("UseAccountingDate") And pInputParameters.UseAccountingDate);
	vAccountingTotals = GetAccountingTotals(pInputParameters.PeriodFrom, pInputParameters.PeriodTo, vCompanyArr, vHotelArr, vUseAccountingDate);
	vPaymentList = GetPaymentListDetails(pInputParameters.PeriodFrom, pInputParameters.PeriodTo, vCompanyArr, vHotelArr, vUseAccountingDate);
	
	If Not  vAccountingTotals.IsEmpty() Then
		vTrans = vAccountingTotals.Select();
		While vTrans.Next() Do
			// Fill close of shift
			vDoc = FillCCRDHeader(pInteraction, vTrans);
			
			vFilter = New Structure;
			vFilter.Insert("Currency", vTrans.Currency);
			vFilter.Insert("PaymentMethod", vTrans.PaymentMethod);
			vFilter.Insert("Customer", vTrans.Customer);
			vFilter.Insert("CCRDRef", vTrans.ref);
			vFilter.Insert("ExternalCode", vTrans.ExternalCode);
			vFilter.Insert("IsPayment", vTrans.IsPayment);
			
			vFilterRows = vPaymentList.FindRows(vFilter);
			
			// Fill payments by close of shift
			For Each mRow In vFilterRows Do
				vPayment = FillPayment(mRow, pInteraction);
				vDoc.PaymentsTable.Add(vPayment);
			EndDo;
			
			vDocs.Add(vDoc);
		EndDo;
	EndIf;
	
	Return vDocs;
EndFunction  // GetPaymentList()

// -----------------------------------------------------------------------------
Function GetSettlementList(pInteraction, pInputParameters)
	// Get company
	vCompanyCode = pInputParameters.CompanyCode;
	If IsBlankString(vCompanyCode) Then
		vCompanyArr = New Array;
	Else
		vCompanyArr = GetObjectRefByExternalSystemCode(pInteraction, "Companies", vCompanyCode, True);
	EndIf;
	
	// Get hotel
	vHotelCode = pInputParameters.HotelCode;
	If IsBlankString(vHotelCode) Then
		vHotelArr = New Array;;
	Else
		vHotelArr = GetObjectRefByExternalSystemCode(pInteraction, "Hotels", vHotelCode, True);
	EndIf;
	
	vDocs = New Array;
	
	vSettlementsList = GetTotalsSettlements(pInputParameters.PeriodFrom, pInputParameters.PeriodTo, vCompanyArr, vHotelArr);
	
	If Not vSettlementsList.IsEmpty() Then
		vTrans = vSettlementsList.Select();
		While vTrans.Next() Do
			// Fill settlement list
			vDoc = FillSettlementHeader(pInteraction, vTrans);
			vDocs.Add(vDoc);
		EndDo;
	EndIf;
	
	Return vDocs;
EndFunction //  GetSettlementList()

// -----------------------------------------------------------------------------
Function GetInvoicesList(pInteraction, pInputParameters)
	// Get company
	vCompanyCode = pInputParameters.CompanyCode;
	If IsBlankString(vCompanyCode) Then
		vCompanyArr = New Array;
	Else
		vCompanyArr = GetObjectRefByExternalSystemCode(pInteraction, "Companies", vCompanyCode, True);
	EndIf;
	// Get hotel
	vHotelCode = pInputParameters.HotelCode;
	If IsBlankString(vHotelCode) Then
		vHotelArr = New Array;;
	Else
		vHotelArr = GetObjectRefByExternalSystemCode(pInteraction, "Hotels", vHotelCode, True);
	EndIf;
	
	vDocs = New Array;
	
	vProformaInvoiceList = GetTotalsInvoices(pInputParameters.PeriodFrom, pInputParameters.PeriodTo, vCompanyArr, vHotelArr);
	
	If Not vProformaInvoiceList.IsEmpty() Then
		vTrans = vProformaInvoiceList.Select();
		While vTrans.Next() Do
			// Fill Proforma-invoice
			vDoc = FillProformaInvoiceHeader(pInteraction, vTrans);
			
			// Fill Proforma-invoice services
			vServices = vTrans.Ref.Services;
			For Each mRow In vServices Do
				vServiceRow = FillProformaInvoiceServicesRow(mRow, pInteraction);
				vDoc.Services.Add(vServiceRow);
			EndDo;
			
			vDocs.Add(vDoc);
		EndDo;
	EndIf;
	
	Return vDocs;
EndFunction //  GetInvoicesList()

// -----------------------------------------------------------------------------
Procedure GetCustomerPayments(pInteraction, pInputParameters)
	For Each vElement In pInputParameters.CustomersPaymentList Do
		vDokManager = Documents[pInputParameters.PaymentType];
		vDok = vDokManager.FindByAttribute("ExternalCode", vElement.AccountingPaymentUID);
		If Not vDok.IsEmpty() And Not vDok.GetObject() = Undefined Then
			vElement.ExternalPaymentUID = String(vDok.UUID());
			vElement.Sum = vDok.Sum;
			vElement.DocumentNumber = vDok.Number;
			If Not IsBlankString(pInteraction.WebhookURL) Then
				vElement.ExternalRef = TrimAll(pInteraction.WebhookURL) + "#" + GetURL(vDok.ref);
			EndIf;
		EndIf;
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
Function GetTotalsSettlements(pPeriodFrom, pPeriodTo, pCompany, pHotel)
	
	vQry = New Query;
	vQry.Text =
	"SELECT
	|	Settlement.CorrectionForSettlement AS Ref
	|INTO CorrectionRefs
	|FROM
	|	Document.Settlement AS Settlement
	|WHERE
	|	Settlement.ChangeDate >= &qDateFrom
	|	AND Settlement.ChangeDate <= &qDateTo
	|	AND CASE
	|			WHEN &qCompanyIsEmpty = TRUE
	|				THEN TRUE
	|			ELSE Settlement.Company IN (&qCompany)
	|		END
	|	AND NOT Settlement.CorrectionForSettlement.Ref IS NULL
	|	AND NOT Settlement.DoNotExportToTheAccountingSystem
	|	AND Settlement.Posted
	|	AND CASE
	|			WHEN &qHotelIsEmpty = TRUE
	|				THEN TRUE
	|			ELSE Settlement.Hotel IN (&qHotel)
	|		END
	|
	|GROUP BY
	|	Settlement.CorrectionForSettlement
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Settlement.Ref AS Ref,
	|	Settlement.Date AS Date,
	|	Settlement.Number AS Number,
	|	Settlement.Posted AS Posted,
	|	Settlement.Hotel AS Hotel,
	|	Settlement.Company AS Company,
	|	Settlement.AccountingCustomer AS AccountingCustomer,
	|	Settlement.AccountingContract AS AccountingContract,
	|	Settlement.GuestGroup AS GuestGroup,
	|	Settlement.Sum AS Sum,
	|	Settlement.AccountingCurrency AS AccountingCurrency,
	|	Settlement.InvoiceNumber AS InvoiceNumber,
	|	Settlement.ExternalCode AS ExternalCode,
	|	Settlement.Remarks AS Remarks,
	|	CASE
	|		WHEN Settlement.CorrectionForSettlement.Ref IS NULL
	|			THEN """"
	|		ELSE Settlement.CorrectionForSettlement.Number
	|	END AS Parent,
	|	Settlement.PaymentSection AS PaymentSection,
	|	Settlement.PaymentMethod AS PaymentMethod
	|FROM
	|	Document.Settlement AS Settlement
	|WHERE
	|	Settlement.ChangeDate >= &qDateFrom
	|	AND Settlement.ChangeDate <= &qDateTo
	|	AND CASE
	|			WHEN &qCompanyIsEmpty = TRUE
	|				THEN TRUE
	|			ELSE Settlement.Company IN (&qCompany)
	|		END
	|	AND NOT Settlement.Ref IN
	|				(SELECT
	|					CorrectionRefs.Ref
	|				FROM
	|					CorrectionRefs AS CorrectionRefs)
	|	AND NOT Settlement.DoNotExportToTheAccountingSystem
	|	AND Settlement.Posted
	|	AND CASE
	|			WHEN &qHotelIsEmpty = TRUE
	|				THEN TRUE
	|			ELSE Settlement.Hotel IN (&qHotel)
	|		END
	|
	|UNION ALL
	|
	|SELECT
	|	SettlementCorrections.Ref,
	|	SettlementCorrections.Date,
	|	SettlementCorrections.Number,
	|	SettlementCorrections.Posted,
	|	SettlementCorrections.Hotel,
	|	SettlementCorrections.Company,
	|	SettlementCorrections.AccountingCustomer,
	|	SettlementCorrections.AccountingContract,
	|	SettlementCorrections.GuestGroup,
	|	SettlementCorrections.Sum,
	|	SettlementCorrections.AccountingCurrency,
	|	SettlementCorrections.InvoiceNumber,
	|	SettlementCorrections.ExternalCode,
	|	SettlementCorrections.Remarks,
	|	CASE
	|		WHEN SettlementCorrections.CorrectionForSettlement.Ref IS NULL
	|			THEN """"
	|		ELSE SettlementCorrections.CorrectionForSettlement.Number
	|	END,
	|	SettlementCorrections.PaymentSection,
	|	SettlementCorrections.PaymentMethod
	|FROM
	|	Document.Settlement AS SettlementCorrections
	|WHERE
	|	SettlementCorrections.Ref IN
	|			(SELECT
	|				CorrectionRefs.Ref
	|			FROM
	|				CorrectionRefs AS CorrectionRefs)
	|	AND NOT SettlementCorrections.DoNotExportToTheAccountingSystem
	|	AND SettlementCorrections.Posted
	|
	|ORDER BY
	|	Parent";
	
	vQry.SetParameter("qDateFrom", pPeriodFrom + 1);
	vQry.SetParameter("qDateTo", pPeriodTo);
	vQry.SetParameter("qCompany", pCompany);
	vQry.SetParameter("qCompanyIsEmpty", pCompany.Count() = 0);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qHotelIsEmpty", pHotel.Count() = 0);
	
	Return vQry.Execute();
	
EndFunction //  GetTotalsSettlements()

// -----------------------------------------------------------------------------
Function GetTotalsInvoices(pPeriodFrom, pPeriodTo, pCompany, pHotel)
	
	vQry = New Query;
	vQry.Text =
	"SELECT
	|	ProformaInvoice.Ref AS Ref,
	|	ProformaInvoice.Date AS Date,
	|	ProformaInvoice.Number AS Number,
	|	ProformaInvoice.Posted AS Posted,
	|	ProformaInvoice.Hotel AS Hotel,
	|	ProformaInvoice.Company AS Company,
	|	ProformaInvoice.AccountingCustomer AS AccountingCustomer,
	|	ProformaInvoice.AccountingContract AS AccountingContract,
	|	ProformaInvoice.GuestGroup AS GuestGroup,
	|	ProformaInvoice.Sum AS Sum,
	|	ProformaInvoice.AccountingCurrency AS AccountingCurrency,
	|	ProformaInvoice.ExternalCode AS ExternalCode,
	|	ProformaInvoice.Remarks AS Remarks
	|FROM
	|	Document.ProformaInvoice AS ProformaInvoice
	|WHERE
	|	ProformaInvoice.ChangeDate >= &qDateFrom
	|	AND ProformaInvoice.ChangeDate <= &qDateTo
	|	AND CASE
	|		WHEN &qCompanyIsEmpty = TRUE
	|			THEN TRUE
	|		ELSE ProformaInvoice.Company In (&qCompany)
	|	END
	|	AND ProformaInvoice.Posted
	|	AND CASE
	|		WHEN &qHotelIsEmpty = TRUE
	|			THEN TRUE
	|		ELSE ProformaInvoice.Hotel IN (&qHotel)
	|	END";
	
	vQry.SetParameter("qDateFrom", pPeriodFrom + 1);
	vQry.SetParameter("qDateTo", pPeriodTo);
	vQry.SetParameter("qCompany", pCompany);
	vQry.SetParameter("qCompanyIsEmpty",  pCompany.Count() = 0);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qHotelIsEmpty", pHotel.Count() = 0);
	
	Return vQry.Execute();
	
EndFunction //  GetTotalsSettlements()

// -----------------------------------------------------------------------------
Function GetObjectExternalSystemCodeByRef(pInteraction, pRef)
	vExtCode = "";
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ExternalSystemIntegrationData.ExternalSystemDataCode
	|FROM
	|	InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|WHERE
	|	ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem
	|	AND ExternalSystemIntegrationData.RefKey1 = &pRef";
	
	Query.SetParameter("qExternalSystem", pInteraction);
	Query.SetParameter("pRef", pRef);
	
	QueryResult = Query.Execute();
	
	vRes = QueryResult.Select();
	
	If vRes.Next() Then
		vExtCode = vRes.ExternalSystemDataCode;
	EndIf;
	
	Return vExtCode;
EndFunction

// -----------------------------------------------------------------------------
Function GetObjectRefByExternalSystemCode(pInteraction, pDataType, pExternalCode, pList = False)
	vRef = Undefined;
	
	vRes = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteraction, pDataType, , , , , pExternalCode);
	
	If pList Then
		vList = New Array;
		For Each vRow In vRes Do
			vRef = vRow.RefKey1;
			If ValueIsFilled(vRef) And vList.Find(vRef) = Undefined Then
				vList.Add(vRef);
			EndIf;
		EndDo;
		Return vList;
	Else	
		If vRes.Count() > 0 Then
			vRef = vRes[0].RefKey1;
		EndIf;
	EndIf;
	
	Return vRef;
EndFunction

#EndRegion
