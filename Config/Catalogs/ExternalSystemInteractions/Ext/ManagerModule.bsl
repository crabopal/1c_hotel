
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pExternalSystemInteractions	 - CatalogRef.ExternalSystemInteractions - Ref on catalog
//  pRequestHeaders				 - Array								 - 
//  pRequestURL					 - String								 - 
//  pMethod						 - String								 - 
//  pMethodAction				 - String								 - 
//  pRequestBody				 - String								 - 
//  pContentType				 - String								 - 
//  pUseServerLogin				 - String								 - 
//  pRequestParameters			 - String								 - 
//  pMaxLogLength				 - String								 - 
//  pHTTPConnection				 - Undefined, HTTPConnection			 - 
//  pHTTPRequest				 - Undefined, HTTPRequest				 - 
//  pGetRaw						 - Boolean								 - 
//  pHTTPServer					 - String								 - 
//  pAddHostHeader				 - Boolean								 - 
//  pFunctionName				 - String								 - 
// 
// Returns:
//  Structure - Query params
//
Function SendHTTPRequest(pExternalSystemInteractions, pRequestHeaders = Undefined, pRequestURL = Undefined, pMethod, pMethodAction = Undefined, pRequestBody = Undefined, 
						pContentType = Undefined, pUseServerLogin = False, pRequestParameters = Undefined, pMaxLogLength = 250000, pHTTPConnection = Undefined, pHTTPRequest = Undefined, 
						pGetRaw = False, pHTTPServer = Undefined, pAddHostHeader = true, pFunctionName = "") Export
	
	vResult = New Structure("StatusCode, Body, Error, Raw");
	
	Try
		// Get callback connection parameters
		If pHTTPServer = Undefined Then
			vHTTPServer = TrimAll(pExternalSystemInteractions.HTTPServer);
			If NOT ValueIsFilled(vHTTPServer) Then
				vHTTPServer = TrimAll(pExternalSystemInteractions.WSHost);	
			EndIf;
			vPort = pExternalSystemInteractions.HttpPort;
			If vPort <> 80 And vPort <> 0 Then
				vHTTPServer = vHTTPServer + ":" + Format(vPort, "NFD=0; NG=");
			EndIf;
		Else
			vHTTPServer	= pHTTPServer;
		EndIf;
		vUseSSL 	= pExternalSystemInteractions.HTTPUseSSL;
		
		If pUseServerLogin = True Then
			vHTTPUser 	= TrimAll(pExternalSystemInteractions.Login);
			vHTTPPwd 	= TrimAll(pExternalSystemInteractions.Password);
		Else
			vHTTPUser 	= Undefined;
			vHTTPPwd 	= Undefined;	
		EndIf;
		
		If NOT ValueIsFilled(pRequestURL) Then
			vRequestURL = TrimAll(pExternalSystemInteractions.HttpAddress);
		Else
			vRequestURL = pRequestURL;
		EndIf;

		// HTTP header
		vHTTPHeader = New Map;
		If pAddHostHeader Then
			vHTTPHeader.Insert("Host", vHTTPServer);
		EndIf;
		
		If pMethod = "POST" Then
			If pMethodAction <> Undefined Then
				vHTTPHeader.Insert("POST", pMethodAction);
			EndIf;
		EndIf;
		
		If pRequestBody <> Undefined Then
			If StrFind(Upper(pContentType), "application/json") > 0 Or pContentType = "JSON" Then
				vHTTPHeader.Insert("Content-Type", "application/json;charset=utf-8");
			ElsIf StrFind(Upper(pContentType), "application/xml") > 0 Or pContentType = "XML" Then
				vHTTPHeader.Insert("Content-Type", "application/xml;charset=utf-8");
			Else
				vHTTPHeader.Insert("Content-Type", pContentType);	
			EndIf;
		EndIf;

		If pRequestHeaders <> Undefined Then
			For each vHeader in pRequestHeaders Do
				vHTTPHeader.Insert(vHeader.Key, vHeader.Value);	
			EndDo;
		EndIf;

		// HTTP connection
		vSSL = Undefined;
		If vUseSSL Then
			vSSL = New OpenSSLSecureConnection(Undefined, Undefined);       	
		EndIf;
		
		If pHTTPConnection = Undefined Then
			vHTTPConnection = New HTTPConnection(vHTTPServer, , vHTTPUser, vHTTPPwd, , , vSSL);
		Else
			vHTTPConnection = pHTTPConnection;	
		EndIf;
		
		If pRequestParameters <> Undefined Then
			vFirst = True;
			For Each vKeyAndValue In pRequestParameters Do
				If vFirst Then
					vRequestURL = vRequestURL + "?" + vKeyAndValue.Key + "=" + vKeyAndValue.Value; 
				Else
					vRequestURL = vRequestURL + "&" + vKeyAndValue.Key + "=" + vKeyAndValue.Value;
				EndIf;			
				vFirst 		= False;
			EndDo;
		EndIf;
		
		vRequestBody = "";
		// Send data
		If pHTTPRequest = Undefined Then
			vHTTPRequest = New HTTPRequest(vRequestURL, vHTTPHeader);
		Else
			vHTTPRequest 	= pHTTPRequest;
			vRequestBody	= vHTTPRequest.GetBodyAsString();
		EndIf;
		
		If pRequestBody <> Undefined Then
			If TypeOf(pRequestBody) = Type("BinaryData") Then
				vHTTPRequest.SetBodyFromBinaryData(pRequestBody);
			Else
				vHTTPRequest.SetBodyFromString(pRequestBody);				
			EndIf;
			vRequestBody = pRequestBody;
		EndIf;
		
		If pMethod = "POST" Then
			vRs = vHTTPConnection.Post(vHTTPRequest);
		ElsIf pMethod = "PATCH" Then
			vRs = vHTTPConnection.CallHTTPMethod("PATCH",vHTTPRequest);
		ElsIf pMethod = "GET" Then
			vRs = vHTTPConnection.Get(vHTTPRequest);
		ElsIf pMethod = "DELETE" Then
			vRs = vHTTPConnection.Delete(vHTTPRequest);
		ElsIf pMethod = "PUT" Then
			vRs = vHTTPConnection.Put(vHTTPRequest);
		EndIf;
		
		vResult.StatusCode	= vRs.StatusCode;
		vResult.Body 		= vRs.GetBodyAsString();
		
		If pGetRaw Then
			vResult.Raw = vRs;
		EndIf;
	Except
		vError = String(pExternalSystemInteractions) + " - "
				 + NStr("en = 'Failed to send request!';
				 		|de = 'Anfrage konnte nicht gesendet werden!';
						|ru = 'Не удалось отправить запрос!'") 
				 + " " + ErrorDescription();
		WriteLogEvent("SendHTTPRequest", EventLogLevel.Warning, ,CurrentSessionDate(), "" + vError);
		vResult.Error = vError;
		vLogEventType = Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pExternalSystemInteractions, "SendHTTPRequest", vLogEventType, , , vError);	
	EndTry;
	
	If pExternalSystemInteractions.DebugMode Then
		
		vLogStructure = New Structure;
		vLogStructure.Insert("Action", 						"SendHTTPRequest");
		vLogStructure.Insert("ExternalSystemInteractions", 	String(pExternalSystemInteractions));
		vLogStructure.Insert("RequestURL", 					vRequestURL);
		vLogStructure.Insert("FunctionName", 				pFunctionName);
		If StrLen(vRequestURL) > 100 Or StrFind(vRequestURL, "?") > 0 Then
			vMap = New Map;
			vMap.Insert("RequestURL", 	vRequestURL);
			vMap.Insert("RequestBody", 	vRequestBody);
			vRequestBody = Catalogs.DataConvertationRules.MapToJSON(vMap);
		EndIf;
		vLogStructure.Insert("RequestBody", 				vRequestBody);
		vLogStructure.Insert("ResponseStatus", 				vResult.StatusCode);
		vLogStructure.Insert("ResponseBody", 				vResult.Body);
		vLogStructure.Insert("Error", 						vResult.Error);

		WriteLog(pExternalSystemInteractions, vLogStructure, pMaxLogLength);
	EndIf;
	
	Return vResult;	
	
EndFunction // SendQuery

// --------------------------------------------------------------------------------
//
// Parameters:
//  pExternalSystemInteractions	 - CatalogRef.ExternalSystemInteractions - Ref on catalog 
//  pLogStructure				 - Structure - Parametres for write log
//  pMaxLogLength				 - Number - Max log length
//
Procedure WriteLog(pExternalSystemInteractions, pLogStructure, pMaxLogLength = 2000) Export
	
	If pExternalSystemInteractions = Undefined or pLogStructure = Undefined Then
		Return;
	EndIf;
	
	Try
		If ValueIsFilled(pLogStructure.Error) Then
			vLogEventType = Enums.ExternalSystemEventTypes.Error;
		Else
			vLogEventType = Enums.ExternalSystemEventTypes.Success;	
		EndIf;
		vFunctionName = "";
		If pLogStructure.Property("FunctionName") And ValueIsFilled(pLogStructure.FunctionName) Then
			vFunctionName = TrimAll(pLogStructure.FunctionName);
		Else
			vFunctionName = pLogStructure.RequestURL;
		EndIf;	
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pExternalSystemInteractions, vFunctionName, vLogEventType, pLogStructure.RequestBody, pLogStructure.ResponseBody, pLogStructure.Error, pMaxLogLength);	
		
		If ValueIsFilled(pExternalSystemInteractions.LogFolder) Then
			vFullFileName = pExternalSystemInteractions.LogFolder + "\" + cmGetValidFileName(pExternalSystemInteractions.InteractionID + "_" + Format(CurrentSessionDate(),"DF=dd.MM.yyyy_HH_mm_ss") + ".log");
			vNewTextWriter = New TextWriter(vFullFileName);
			For each vLogRow in pLogStructure Do
				vNewTextWriter.WriteLine(vLogRow.Key + ":" + vLogRow.Value);	
			EndDo;
			vNewTextWriter.Close();
		EndIf;
	Except
		vError = ErrorDescription();
		WriteLogEvent(pExternalSystemInteractions.InteractionID + "_WriteLog", EventLogLevel.Error,,CurrentSessionDate(), "Failed to write log. " + vError);
	EndTry;
	
EndProcedure

// --------------------------------------------------------------------------------
//
// Parameters:
//  pInteractionID	 - String	 -  Token
//  pHotel			 - CatalogRef.Hotel, Undefined - Ref hotel
// 
// Returns:
//  ExternalSystemInteraction - CatalogRef.ExternalSystemInteractions 
//
Function GetExternalSystemInteractionsByInteractionID(pInteractionID, pHotel = Undefined) Export
	vHotel = SessionParameters.CurrentHotel;
	If ValueIsFilled(pHotel) Then
		vHotel = pHotel;
	EndIf;	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ExternalSystemInteractions.Ref AS Ref
		|FROM
		|	Catalog.ExternalSystemInteractions AS ExternalSystemInteractions
		|WHERE
		|	ExternalSystemInteractions.IsActive
		|	AND (ExternalSystemInteractions.Hotel = &qHotel
		|			OR ExternalSystemInteractions.Hotel = &qEmptyHotel)
		|	AND NOT ExternalSystemInteractions.DeletionMark
		|	AND ExternalSystemInteractions.InteractionID = &qInteractionID";
	
	vQuery.SetParameter("qInteractionID", pInteractionID);
	vQuery.SetParameter("qHotel", vHotel);
	vQuery.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	
	vQueryResult = vQuery.Execute().Unload();
	For each vRow in vQueryResult Do
		Return vRow.Ref;
	EndDo;
	
	Return Undefined;
	
EndFunction

// --------------------------------------------------------------------------------
//
// Parameters:
//  pToken	 - String - Token
// 
// Returns:
//  CatalogRef.ExternalSystemInteractions - Ref on catalog 
//
Function GetExternalSystemInteractionsByExternalToken(pToken) Export
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ExternalSystemInteractions.Ref AS Ref
		|FROM
		|	Catalog.ExternalSystemInteractions AS ExternalSystemInteractions
		|WHERE
		|	ExternalSystemInteractions.IsActive
		|	AND NOT ExternalSystemInteractions.DeletionMark
		|	AND ExternalSystemInteractions.OAuth_AccessToken = &qToken";
	
	vQuery.SetParameter("qToken", pToken);
	
	vQueryResult = vQuery.Execute().Unload();
	For each vRow in vQueryResult Do
		Return vRow.Ref;
	EndDo;
	
	Return Undefined;
	
EndFunction

// --------------------------------------------------------------------------------
//
// Parameters:
//  pParameters	 - Structure - Params
// 
// Returns:
//   CatalogRef.ExternalSystemInteractions - Ref on catalog  
//
Function GetExternalSystemInteractionsByParameters(pParameters) Export
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ExternalSystemInteractions.Ref AS Ref
		|FROM
		|	Catalog.ExternalSystemInteractions AS ExternalSystemInteractions
		|WHERE
		|	ExternalSystemInteractions.IsActive
		|	AND NOT ExternalSystemInteractions.DeletionMark"; 
	
	If TypeOf(pParameters) = Type("Array") Then
		For Each vRow In pParameters Do 
			vQuery.Text = vQuery.Text + Chars.LF + ?(vRow.OR, "OR", "AND") + " ExternalSystemInteractions." + TrimAll(vRow.Name) + " = &q" + TrimAll(vRow.Name); 
			vQuery.SetParameter("q" + TrimAll(vRow.Name), vRow.Value);
		EndDo;
	EndIf;
	
	vQueryResult = vQuery.Execute().Unload();
	For each vRow in vQueryResult Do
		Return vRow.Ref;
	EndDo;
	
	Return Undefined;
	
EndFunction

// --------------------------------------------------------------------------------
//
// Parameters:
//  pToken				 - String - Token
//  pProtocol			 - String - Protocol
//  pSOAP_XDTOFactory	 - XDTOFactory, Undefined - 
// 
// Returns:
//  XDTOFactory - Error description 
//
Function GetAuthError(pToken, pProtocol = "REST", pSOAP_XDTOFactory = Undefined) Export
	If pProtocol = "REST" Then
		
	ElsIf  pProtocol = "SOAP" Then
		pSOAP_XDTOFactory.Code 			= 403;
		pSOAP_XDTOFactory.Description 	= "Failed to authenticate system by token in 1C:Hotel!";
		Return pSOAP_XDTOFactory;
	EndIf;
	
EndFunction

// --------------------------------------------------------------------------------
//
// Parameters:
//  pExternalSystemInteractions	 - CatalogRef.ExternalSystemInteractions - Ref on catalog  
//  pParameterName				 - String - Parameter description
// 
// Returns:
//  Undefined, String - Static parameters
//
Function GetStaticParametersFromDP(pExternalSystemInteractions, pParameterName = "") Export 
	vResult = Undefined;
	If ValueIsFilled(pExternalSystemInteractions) Then
		vDataProcessor = pExternalSystemInteractions.DataProcessor;
		If  ValueIsFilled(vDataProcessor) Then
			If ValueIsFilled(pParameterName) Then
				vStaticParameters = vDataProcessor.StaticParameters.Get(); 
				If vStaticParameters <> Undefined Then
					If vStaticParameters.Property(pParameterName) Then
						vResult = vStaticParameters[pParameterName]; 	
					EndIf;
				EndIf;
			Else
				vResult = vDataProcessor.StaticParameters.Get();	
			EndIf
		EndIf;
	EndIf;
	Return vResult
EndFunction // GetParameters

// --------------------------------------------------------------------------------
//
// Parameters:
//  pUsername	 - String - Username
//  pPassword	 - String - Password
// 
// Returns:
// String  - Parameters 
//
Function GetBase64Auth(pUsername, pPassword) Export
	
	vResult 	= "";
	vAuthString = pUsername + ":" + pPassword;
	
	vStream		= New MemoryStream;
	
	vWriter		= New DataWriter(vStream, TextEncoding.UTF8);
	vWriter.WriteChars(vAuthString);
	vWriter.Close();
	
	vBinary 		= vStream.CloseAndGetBinaryData();
	vBase64String 	= GetBase64StringFromBinaryData(vBinary);
	vBase64String	= StrReplace(vBase64String, Chars.LF, "");
	vBase64String	= StrReplace(vBase64String, Chars.CR, "");
	vResult			= "Basic " + vBase64String;
		
	Return vResult;
	
EndFunction

// --------------------------------------------------------------------------------
//  Function - Get objet form
//
// Parameters:
//  pOjectRef		 - CatalogRef.ExternalSystemInteractions - Ref on object
//  pFormName		 - String								 - The name of the form. It is formed as the full path to the metadata object.
//  pCreateObject	 - String								 - 
// 
// Returns:
//  Boolean - TRUE(if found) or FALSE (not found)
//
Function GetObjetForm(pOjectRef, pFormName, pCreateObject = False) Export
	vObjName = "";
	If pOjectRef.IntegrationType = Enums.Integrations.Bitrix24 Then
		pFormName = "DataProcessor.Bitrix24.Form";
		vObjName = "Bitrix24";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.Travelline Then
		pFormName = "DataProcessor.TLConnectWizard.Form.tcWizardForm";
		vObjName = "TLConnectWizard";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.Siteminder Then
		pFormName = "DataProcessor.SiteminderWizard.Form.tcWizard";
		vObjName = "SiteminderWizard";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.Wubook Then
		pFormName = "DataProcessor.WubookWizard.Form.tcWizard";
		vObjName = "WubookWizard";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.HPG Then
		pFormName = "Catalog.ExternalSystemInteractions.Form.tcHPGSettings";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.ISD Then
		pFormName = "Catalog.ExternalSystemInteractions.Form.tcISDSettings";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.SKK Then
		pFormName = "Catalog.ExternalSystemInteractions.Form.tcSKKSettings";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.SKKV2 Then
		pFormName = "Catalog.ExternalSystemInteractions.Form.tcSKKSettingsV2";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.OTAGateway Then
		pFormName = "DataProcessor.OTAGatewayWizard.Form.Form";
		vObjName = "OTAGatewayWizard";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.Hotbot Then
		pFormName = "DataProcessor.HotbotSettings.Form.Form";
		vObjName = "HotbotSettings";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.AleanCRS Then
		pFormName = "DataProcessor.AleanCRSSystemInventorySynchronization3.Form.tcSettingsForm";
		vObjName = "AleanCRSSystemInventorySynchronization3";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.Bonuses Then
		pFormName = "DataProcessor.CalculateBonuses.Form.Form";
		vObjName = "CalculateBonuses";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.Availpro Then
		pFormName = "DataProcessor.AvailproWizard.Form.Form";
		vObjName = "AvailproWizard";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.WebHotelier Then
		pFormName = "DataProcessor.WebHotelierWizard.Form.Form";
		vObjName = "WebHotelierWizard";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.Ordes Then
		pFormName = "DataProcessor.ExportOrdersToExternalSystem.Form.tcSettingsForm";
		vObjName = "ExportOrdersToExternalSystem";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.HotelOnlineBooking Then
		pFormName = "Catalog.ExternalSystemInteractions.Form.tcHotelOnlineBooking";	
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.Guestlink Then
		pFormName = "Catalog.ExternalSystemInteractions.Form.tcGuestlink";	
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.Hotel365 Then
		pFormName = "Catalog.ExternalSystemInteractions.Form.tcHotel365";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.Wallet Then
		pFormName = "Catalog.ExternalSystemInteractions.Form.tcWallet";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.Accounting Then
		pFormName = "Catalog.ExternalSystemInteractions.Form.tcAccounting";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.JSON Then
		pFormName = "DataProcessor.JSONDataExporter.Form.Form";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.GuestJoy Then
		pFormName = "DataProcessor.GuestJoyExport.Form.Form";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.SquirrelPOS Then
		pFormName = "DataProcessor.SquirrelPOS.Form.Form";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.ExternalLoyaltySystem Then
		pFormName = "DataProcessor.ExternalLoyaltySystem.Form";
		vObjName = "ExternalLoyaltySystem";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.Other Then
		pFormName = "Catalog.ExternalSystemInteractions.Form.tcSettings";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.SamsungLYNK Then
		pFormName = "DataProcessor.SamsungLYNK.Form";
		vObjName = "SamsungLYNK";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.Hoteza Then
		pFormName = "DataProcessor.HotezaWizard.Form";
		vObjName = "HotezaWizard";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.FIAS Then
		pFormName = "DataProcessor.FIASDriver.Form.tcSettingsForm";
		vObjName = "FIASDriver";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.DADATA Then
		pFormName = "Catalog.ExternalSystemInteractions.Form.tcDadata";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.rkeeper Then
		pFormName = "Catalog.ExternalSystemInteractions.Form.tcRKeeper";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.Hotellab Then
		pFormName = "DataProcessor.Hotellab.Form";
		vObjName = "Hotellab";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.Roscongress Then
		pFormName = "Catalog.ExternalSystemInteractions.Form.tcRoscongressSettings";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.QRCodePaySberbank Then
		pFormName = "DataProcessor.QRCodePaySberbank.Form";
		vObjName = "QRCodePaySberbank";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.ttLock Then
		pFormName = "DataProcessor.ttLockDoorLockSystemDriver.Form.Settings";
		vObjName = "ttLockDoorLockSystemDriver";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.iLocksOnline Then
		pFormName = "DataProcessor.iLocksOnlineDoorLockSystemDriver.Form.Settings";
		vObjName = "iLocksOnlineDoorLockSystemDriver";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.HAFELE Then
		pFormName = "DataProcessor.HAFELELockDoorLockSystemDriver.Form.Settings";
		vObjName = "HAFELELockDoorLockSystemDriver";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.UnisenderGO Then
		pFormName = "DataProcessor.UnisenderGO.Form";
		vObjName = "UnisenderGO";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.Fitnes1C Then
		pFormName = "DataProcessor.ExportClientsTo1CFitnes.Form";
		vObjName = "ExportClientsTo1CFitnes";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.RTK Then
		pFormName = "DataProcessor.RTK.Form.tcSettingsForm";
		vObjName = "RTK";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.JCCSmart Then
		pFormName = "Catalog.ExternalSystemInteractions.Form.tcJCCSmart";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.YandexTV Then
		pFormName = "DataProcessor.YandexTV.Form.tcSettingsForm";
		vObjName = "YandexTV";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.YandexVision Then
		pFormName = "Catalog.ExternalSystemInteractions.Form.tcYandexVision";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.Sanatorium Then
		pFormName = "DataProcessor.Sanatorium.Form";
		vObjName = "Sanatorium";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.Igloorooms Then
		pFormName = "DataProcessor.Igloorooms.Form.tcSettingsForm";
		vObjName = "Igloorooms";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.UHotels Then
		pFormName = "DataProcessor.UHotelsWizard.Form.tcWizardForm";
		vObjName = "UHotelsWizard";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.PassportBoxREST Then
		pFormName = "Catalog.ExternalSystemInteractions.Form.tcPassportBoxREST";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.BroniruiOnline Then
		pFormName = "DataProcessor.BroniruiOnlineWizard.Form.tcWizardForm";
		vObjName = "BroniruiOnlineWizard";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.ExternalLogSystem Then
		pFormName = "DataProcessor.ExportLogsToExternalDB.Form.tcExternalForm";
		vObjName = "ExportLogsToExternalDB";
	ElsIf pOjectRef.IntegrationType = Enums.Integrations.AtolOnline Then
		pFormName = "DataProcessor.AtolCommonCashRegisterDriverOnline.Form";
		vObjName = "AtolCommonCashRegisterDriverOnline";
	//ElsIf pOjectRef.IntegrationType = Enums.Integrations.HotelAdvisors Then
	//	pFormName = "DataProcessor.HotelAdvisors.Form.tcSettingsForm";
	//	vObjName = "HotelAdvisors";
	Else 
		Return False;
	EndIf;
	If pCreateObject And Not IsBlankString(vObjName) Then
		// Will create only for data processor 
		vDP = DataProcessors[vObjName];
		vMetadataDP = Metadata.FindByType(TypeOf(vDP));
		If Not vMetadataDP = Undefined Then
			// Create DP
			vDPObj 				= Catalogs.DataProcessors.CreateItem();
			vDPObj.Description 	= vMetadataDP.Synonym + " ("+pOjectRef.Description+")";
			vDPObj.Key 			= String(pOjectRef.UUID());
			vDPObj.Processing 	= vObjName;
			vDPObj.IsSystem = True;
			vDPObj.Write();
			
			// Update external system interactions
			vESI = pOjectRef.GetObject();
			vESI.DataProcessor = vDPObj.Ref;
			vESI.Write();
		EndIf;
	EndIf;	
	Return True;
EndFunction	

// --------------------------------------------------------------------------------
//
// Parameters:
//  pHotel	 - CatalogsRef.Hotels - Ref
// 
// Returns:
//  CatalogRef.ExternalSystemInteractions - Ref on catalog 
//
Function GetExternalSystemInteractionsHotelOnlineBooking(pHotel) Export
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ExternalSystemInteractions.Ref AS Ref
		|FROM
		|	Catalog.ExternalSystemInteractions AS ExternalSystemInteractions
		|WHERE
		|	ExternalSystemInteractions.IsActive
		|	AND NOT ExternalSystemInteractions.DeletionMark
		|	AND ExternalSystemInteractions.Hotel = &qHotel
		|	AND ExternalSystemInteractions.IntegrationType = VALUE(Enum.Integrations.HotelOnlineBooking)";
	
	vQuery.SetParameter("qHotel", pHotel);
	
	vQueryResult = vQuery.Execute().Unload();
	For each vRow in vQueryResult Do
		Return vRow.Ref;
	EndDo;
	
	Return Undefined;
	
EndFunction
// --------------------------------------------------------------------------------
//
// Parameters:
//  pHotel	 - CatalogsRef.Hotels - Ref
// 
// Returns:
//  CatalogRef.ExternalSystemInteractions - Ref on catalog 
//
Function GetExternalSystemInteractionsGuestlink(pHotel) Export
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ExternalSystemInteractions.Ref AS Ref
		|FROM
		|	Catalog.ExternalSystemInteractions AS ExternalSystemInteractions
		|WHERE
		|	ExternalSystemInteractions.IsActive
		|	AND NOT ExternalSystemInteractions.DeletionMark
		|	AND ExternalSystemInteractions.Hotel = &qHotel
		|	AND ExternalSystemInteractions.IntegrationType = VALUE(Enum.Integrations.Guestlink)";
	
	vQuery.SetParameter("qHotel", pHotel);
	
	vQueryResult = vQuery.Execute().Unload();
	For each vRow in vQueryResult Do
		Return vRow.Ref;
	EndDo;
	
	Return GetExternalSystemInteractionsHotelOnlineBooking(pHotel);
	
EndFunction

// --------------------------------------------------------------------------------
//
// Parameters:
//  pHotel	 - CatalogsRef.Hotels - Ref
// 
// Returns:
//  CatalogRef.ExternalSystemInteractions - Ref on catalog 
//
Function GetExternalSystemInteractionsHotel365(pHotel) Export
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ExternalSystemInteractions.Ref AS Ref
		|FROM
		|	Catalog.ExternalSystemInteractions AS ExternalSystemInteractions
		|WHERE
		|	ExternalSystemInteractions.IsActive
		|	AND NOT ExternalSystemInteractions.DeletionMark
		|	AND ExternalSystemInteractions.Hotel = &qHotel
		|	AND ExternalSystemInteractions.IntegrationType = VALUE(Enum.Integrations.Hotel365)";
	
	vQuery.SetParameter("qHotel", pHotel);
	
	vQueryResult = vQuery.Execute().Unload();
	For each vRow in vQueryResult Do
		Return vRow.Ref;
	EndDo;
	
	Return Undefined;
	
EndFunction

// -------------------------------------------------------------------------------- 
//
// Parameters:
//  pHotel	 - CatalogsRef.Hotels - Ref
// 
// Returns:
//  CatalogRef.ExternalSystemInteractions - Ref on catalog 
//
Function GetWalletSystem(pHotel) Export
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ExternalSystemInteractions.Ref AS Ref
		|FROM
		|	Catalog.ExternalSystemInteractions AS ExternalSystemInteractions
		|WHERE
		|	ExternalSystemInteractions.IsActive
		|	AND NOT ExternalSystemInteractions.DeletionMark
		|	AND (ExternalSystemInteractions.Hotel = &qHotel OR ExternalSystemInteractions.Hotel = &qEmptyHotel)
		|	AND ExternalSystemInteractions.IntegrationType = VALUE(Enum.Integrations.Wallet)";
	
	vQuery.SetParameter("qHotel", pHotel);
	vQuery.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	
	vQueryResult = vQuery.Execute().Unload();
	For each vRow in vQueryResult Do
		Return vRow.Ref;
	EndDo;
	
	Return Undefined;
	
EndFunction

// --------------------------------------------------------------------------------
//
// Parameters:
//  pDocRef		 - DocumentRef.Rreservation	 - Ref
//  rIntegration - CatalogRef.ExternalSystemInteractions - Ref on catalog
// 
// Returns:
//  String - the URL for the guest for online booking engine, My reservation page.
//
Function GetReservationGuestURL(pDocRef, rIntegration = Undefined) Export
	If Not ValueIsFilled(pDocRef) Then
		Return "";
	EndIf;
	If TypeOf(pDocRef) = Type("DocumentRef.Reservation") Then
		rIntegration = GetExternalSystemInteractionsGuestlink(pDocRef.Hotel);
		If Not rIntegration = Undefined Then
			vOnlineLink = TrimAll(rIntegration.HttpAddress);
			If IsBlankString(vOnlineLink) Then
				Return "";
			EndIf;
			vRightmostChar = Right(vOnlineLink, 1);
			If vRightmostChar <> "/" And vRightmostChar <> "\" Then
				vOnlineLink = vOnlineLink + "/";
			EndIf;

			vLang = Lower(TrimAll(pDocRef.Hotel.Language));
			If ValueIsFilled(pDocRef.Guest) Then
				vLang = Lower(TrimAll(pDocRef.Guest.Language));
			EndIf;
			
			vID = GetHotelID(rIntegration, pDocRef.Hotel, pDocRef.Company); 
			
			vOnlineLink = vOnlineLink + "my.php?uuid=" + String(pDocRef.UUID()) + "&hotel=" + vID + ?(Not IsBlankString(vLang), "&lang=" + vLang, "");
			Return SMS.GetShortLink(vOnlineLink, rIntegration.URLShortener);
		EndIf;	
	EndIf;
	Return "";
EndFunction // GetReservationGuestURL

// --------------------------------------------------------------------------------
//
// Parameters:
//  pDocRef		 - DocumentRef.Rreservation	 - Ref
//  rIntegration - CatalogRef.ExternalSystemInteractions - Ref on catalog
// 
// Returns:
//  String - the URL for the guest for online booking engine, My reservation page.
//
Function GetRegistrationGuestURL(pDocRef, rIntegration = Undefined) Export
	If Not ValueIsFilled(pDocRef) Then
		Return "";
	EndIf;
	If TypeOf(pDocRef) = Type("DocumentRef.Reservation") Then
		rIntegration = GetExternalSystemInteractionsHotelOnlineBooking(pDocRef.Hotel);
		If Not rIntegration = Undefined Then
			vOnlineLink = TrimAll(rIntegration.HttpAddress);
			If IsBlankString(vOnlineLink) Then
				Return "";
			EndIf;
			vRightmostChar = Right(vOnlineLink, 1);
			If vRightmostChar <> "/" And vRightmostChar <> "\" Then
				vOnlineLink = vOnlineLink + "/";
			EndIf;
			
			vID = GetHotelID(rIntegration, pDocRef.Hotel, pDocRef.Company);
			
			vOnlineLink = StrTemplate(vOnlineLink + "online_registration.php?hotel_code=%1&hotel=%1&reservation=%2&data=%3&search=Y&cancel=N", vID, Format(pDocRef.GuestGroup.Code, "ND=12; NFD=0; NZ=; NG="), TrimAll(pDocRef.EMail));
			Return SMS.GetShortLink(vOnlineLink, rIntegration.URLShortener);
		EndIf;	
	EndIf;
	Return "";
EndFunction // GetRegistrationGuestURL

// --------------------------------------------------------------------------------
//
// Parameters:
//  pGuestGroup	 - CatalogRef.GuestGroup - 
//  rIntegration - CatalogRef.ExternalSystemInteractions - Ref on catalog 
// 
// Returns:
//  String - the URL for the guest for online booking engine, My reservation page. 
//
Function GetGuestGroupURL(pGuestGroup, rIntegration = Undefined) Export
	If Not ValueIsFilled(pGuestGroup) Then
		Return "";
	EndIf;    
	vHotel = pGuestGroup.Owner;
	rIntegration = GetExternalSystemInteractionsGuestlink(vHotel);
	If Not rIntegration = Undefined Then
		vOnlineLink = TrimAll(rIntegration.HttpAddress);
		If IsBlankString(vOnlineLink) Then
			Return "";
		EndIf;
		vLang = Lower(TrimAll(vHotel.Language));
		If ValueIsFilled(pGuestGroup.Client) Then
			vLang = Lower(TrimAll(pGuestGroup.Client.Language));
		EndIf;
		
		If ValueIsFilled(pGuestGroup.ClientDoc) Then
			vCompany = pGuestGroup.ClientDoc.Company;
		Else
			vCompany = vHotel.Company;
		EndIf;	
		
		vID = GetHotelID(rIntegration, vHotel, vCompany);
		
		vOnlineLink = vOnlineLink + "my.php?uuid=" + String(pGuestGroup.UUID()) + "&hotel=" + vID + ?(Not IsBlankString(vLang), "&lang=" + vLang, "");
		Return SMS.GetShortLink(vOnlineLink, rIntegration.URLShortener);
	EndIf;	
	Return "";
EndFunction // GetGuestGroupURL

// --------------------------------------------------------------------------------
// Parameters:
//  pDocRef		 - DocumentRef.Rreservation	 - Ref
//  rIntegration - CatalogRef.ExternalSystemInteractions - Ref on catalog
// 
// Returns:
//  String - the URL for the guest for online booking engine, My reservation page.
//
Function GetProformaInvoiceURL(pDocRef, rIntegration = Undefined) Export
	If Not ValueIsFilled(pDocRef) Then
		Return "";
	EndIf;
	If TypeOf(pDocRef) = Type("DocumentRef.ProformaInvoice") Then
		rIntegration = GetExternalSystemInteractionsGuestlink(pDocRef.Hotel);
		If Not rIntegration = Undefined Then
			vOnlineLink = TrimAll(rIntegration.HttpAddress);
			If IsBlankString(vOnlineLink) Then
				Return "";
			EndIf;
			
			vLang = Lower(TrimAll(pDocRef.Hotel.Language));
			If ValueIsFilled(pDocRef.AccountingCustomer) And ValueIsFilled(pDocRef.AccountingCustomer.Language) Then
				vLang = Lower(TrimAll(pDocRef.AccountingCustomer.Language));
			EndIf;
			
			vID = GetHotelID(rIntegration, pDocRef.Hotel, pDocRef.Company);
			
			vOnlineLink = vOnlineLink + "my.php?uuid=" + String(pDocRef.UUID()) + "&hotel=" + vID + ?(Not IsBlankString(vLang), "&lang=" + vLang, "");
			Return SMS.GetShortLink(vOnlineLink, rIntegration.URLShortener);
		EndIf;	
	EndIf;
	Return "";
EndFunction // GetProformaInvoiceURL

// --------------------------------------------------------------------------------
// Parameters:
//  pDocRef		 - DocumentRef.Rreservation	 - Ref
//  rIntegration - CatalogRef.ExternalSystemInteractions - Ref on catalog
// 
// Returns:
//  String - the URL for the guest for online booking engine, My reservation page.
//
Function GetHotel365URL(pDocRef, rIntegration = Undefined) Export
	If Not ValueIsFilled(pDocRef) Then
		Return "";
	EndIf;
	
	rIntegration = GetExternalSystemInteractionsHotel365(pDocRef.Hotel);
	If Not rIntegration = Undefined Then
		vOnlineLink = TrimAll(rIntegration.HttpAddress);
		If IsBlankString(vOnlineLink) Then
			Return "";
		EndIf;
		vLang = Lower(TrimAll(pDocRef.Hotel.Language));
		
		If TypeOf(pDocRef) = Type("DocumentRef.Accommodation") Or TypeOf(pDocRef) = Type("DocumentRef.Reservation") Then
		
			If ValueIsFilled(pDocRef.Guest) Then
				vLang = Lower(TrimAll(pDocRef.Guest.Language));
			EndIf;
		ElsIf TypeOf(pDocRef) = Type("DocumentRef.Folio") Or TypeOf(pDocRef) = Type("DocumentRef.ResourceReservation") Then
			If ValueIsFilled(pDocRef.Client) Then
				vLang = Lower(TrimAll(pDocRef.Client.Language));
			EndIf;
		EndIf;
		
		vID = GetHotelID(rIntegration, pDocRef.Hotel, pDocRef.Company);
		
		vOnlineLink = vOnlineLink + ?(IsBlankString(rIntegration.SessionID), "" , "?h=" + vID)+ "&id=" + SMS.GetHotel365GuestID(pDocRef) + ?(Not IsBlankString(vLang), "&lang=" + vLang, "");
		Return SMS.GetShortLink(vOnlineLink, rIntegration.URLShortener);
	EndIf;	
	Return "";
EndFunction //  GetHotel365URL

// --------------------------------------------------------------------------------
//  Get integration by type
//
// Parameters:
//  pInteractionType - Enum.Integrations - Type integration
//  pHotel			 - Catalog.Hotels	 - Ref on hotel catalog
// 
// Returns:
//  Ref - or Undefined -
//
Function GetExternalSystemInteractionsByInteractionType(pInteractionType, pHotel = Undefined) Export
	vHotel = SessionParameters.CurrentHotel;
	If ValueIsFilled(pHotel) Then
		vHotel = pHotel;
	EndIf;	
	vExtSystem = Undefined;
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ExternalSystemInteractions.Ref AS Ref
		|FROM
		|	Catalog.ExternalSystemInteractions AS ExternalSystemInteractions
		|WHERE
		|	ExternalSystemInteractions.IsActive
		|	AND NOT ExternalSystemInteractions.DeletionMark
		|	AND (ExternalSystemInteractions.Hotel = &qHotel OR ExternalSystemInteractions.Hotel = &qEmptyHotel)
		|	AND ExternalSystemInteractions.IntegrationType = &qIntegrationType";
	
	vQuery.SetParameter("qHotel", vHotel);
	vQuery.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQuery.SetParameter("qIntegrationType", pInteractionType);
	vQueryResult = vQuery.Execute();
	If Not vQueryResult.IsEmpty() Then
		vRow = vQueryResult.Select();
		vRow.Next();
		vExtSystem = vRow.Ref;
	EndIf;	
	Return vExtSystem;
	
EndFunction

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Hotel, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

// --------------------------------------------------------------------------------
//
// Parameters:
//  pIntegration - CatalogRef.ExternalSystemInteractions - Ref on catalog
//  pHotel		 - CatalogRef.Hotels - Ref on catalog
//  pCompany	 - CatalogRef.Companies - Ref on catalog
// 
// Returns:
//  String - Hotel ID external system
//
Function GetHotelID(pIntegration, pHotel, pCompany) Export 

	vID = cmGetObjectExternalSystemCodeByRef(pHotel, TrimAll(pIntegration.InteractionID), "Companies", pCompany, True);

	If IsBlankString(vID) Then
		vID = TrimAll(pIntegration.SessionID);		
	EndIf;
	
	Return vID;
EndFunction // GetHotelID()

#EndRegion
