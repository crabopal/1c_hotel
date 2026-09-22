
#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  rMessage - String	 - Return result message
// 
// Returns:
//  ComObject - ComObject images scanner
//
Function pmConnect(rMessage = "") Export 
	#If WebClient Then
		ShowMessageBox(, NStr("en = 'Image scanning not supported in Web client'; 
		|de = 'Das Scannen von Bildern wird im Web-Client nicht unterstützt'; 
		|ru = 'Сканирование изображений не поддерживается в Web клиенте'"));
		Return Undefined;
	#EndIf
	rMessage = "";
	
	vScObj = Undefined;
	#If Not MobileClient Then
		Try
			If amImageScannerInstance = Undefined Then
				// Create Regula object
				vScObj = New COMObject("READERDEMO.regulaReader");
				
				// Connect to Regula
				If Not vScObj.Connected Then
					vScObj.Connect();
				EndIf;
				
				If Not vScObj.Connected Then
					rMessage = NStr("en='Failed to connect to Regula device! '; 
					|ru='Ошибка подключения к Regula! '; 
					|de='Fehler bei Regula verbinden! '")
				EndIf;
				
				amImageScannerInstance = vScObj;
			Else
				vScObj = amImageScannerInstance;
			Endif;
		Except
			rMessage = NStr("en='Failed to connect to Regula device! '; 
			|ru='Ошибка подключения к Regula! '; 
			|de='Fehler bei Regula verbinden! '") + Chars.LF + BriefErrorDescription(ErrorInfo());
			tcOnServer.cmWriteLogEventAtServer("AutoRecognition", , , , ErrorDescription());
			
			vScObj = Undefined;
		EndTry;
	#EndIf
	
	Return vScObj;
EndFunction // pmConnect

// -----------------------------------------------------------------------------
// Disconnect images scanner
//
// Parameters:
//  pScObj	 - ComObject - ComObject images scanner
// -----------------------------------------------------------------------------
Procedure pmDisconnect(pScObj) Export
	#If WebClient Then
		Return;
	#EndIf
	Try
		pScObj = Undefined;
	Except
	EndTry;
EndProcedure // pmDisconnect

// -----------------------------------------------------------------------------
//
// Parameters:
//  pScObj	 - ComObject - ComObject images scanner 
//
Procedure ScanDocument(pScObj) Export
	pScObj.GetImages();
EndProcedure // ScanDocument

// -----------------------------------------------------------------------------
//
// Parameters:
//  pScObj	 - ComObject - ComObject images scanner 
//
Procedure ClearResults(pScObj) Export
	pScObj.ClearResults();
EndProcedure // ScanDocument

// -----------------------------------------------------------------------------
//
// Parameters:
//  pScObj				 - ComObject					 - ComObject images scanner
//  pScanConfigurations	 - CatalogRef.ScanConfigurations - Scan configurations
//  pDocumentPages		 - ValueTable					 - Document pages
//  pStorageUUID		 - UUID							 - Storage UUID
//  pIsForeigner		 - Boolean						 - Is foreigner
// 
// Returns:
//  Structure - Result
//
Function GetScannedData(pScObj, pScanConfigurations, pDocumentPages, pStorageUUID, pIsForeigner) Export
	vResult = New Structure;
	
	If pScObj.PagesCount = 1 Then
		pDocumentPages.Clear();
	EndIf;
	
	#If WebClient Then
		Return vResult;
	#EndIf
	
	For vInd = 0 To pScObj.PagesCount - 1 Do
		
		vDocumentTypesCandidateJSON = pScObj.CheckReaderResultJSON(9, vInd, 0);
		vType = "";
		vID = "";
		vDescription = "";
		vCitizenship = "";
		
		If ValueIsFilled(vDocumentTypesCandidateJSON) Then
			vDocumentTypesCandidateMap = JSONtoMap(vDocumentTypesCandidateJSON);
			If vDocumentTypesCandidateMap["OneCandidate"] <> Undefined And TypeOf(vDocumentTypesCandidateMap["OneCandidate"]) = Type("Map") Then
				vOneCandidate = vDocumentTypesCandidateMap["OneCandidate"];
				If vOneCandidate["ID"] <> Undefined Then
					vID = Format(vOneCandidate["ID"], "NG="); 	
				EndIf; 
				If vOneCandidate["DocumentName"] <> Undefined Then
					vDescription = TrimAll(vOneCandidate["DocumentName"]); 	
				EndIf;
				If vOneCandidate["FDSIDList"] <> Undefined And TypeOf(vOneCandidate["FDSIDList"]) = Type("Map") Then 
					vFDSIDList = vOneCandidate["FDSIDList"]; 
					If vFDSIDList["dType"] <> Undefined Then
						vType = Format(vFDSIDList["dType"], "NG="); 	
					EndIf;	
					If vFDSIDList["dCountryName"] <> Undefined Then
						vCitizenship = TrimAll(vFDSIDList["dCountryName"]); 	
					EndIf;
				EndIf; 
			EndIf;
			
			vDocPageArr = pDocumentPages.FindRows(New Structure("ID, Type", vID, vType));
			
			If vDocPageArr.Count() > 0 Then
				vRow = vDocPageArr[0]; 	
			Else
				vRow = pDocumentPages.Add();
				vRow.ID = vID;
				vRow.Type = vType;
				vRow.IsProcessed = False;
				vRow.Description = vDescription;
				vRow.ScanConfiguration = GetScanConfigurationByIDOrType(vID, vType, pIsForeigner);
				
				If ValueIsFilled(vRow.ScanConfiguration) Then
					vIsForeigner = tcOnServer.cmGetAttributeByRef(vRow.ScanConfiguration, "IsForeigner");
					If vIsForeigner Then
						pIsForeigner = 1;
					Else 
						pIsForeigner = 0;
					EndIf;
				EndIf;
			EndIf;
		Else
			vRow = pDocumentPages.Add(); 
			vRow.IsProcessed = False;
			If ?(pIsForeigner = 0, False, True) Then 
				vRow.ScanConfiguration = PredefinedValue("Catalog.ScanConfigurations.OtherDocumentsForeigners");
			Else
				vRow.ScanConfiguration = PredefinedValue("Catalog.ScanConfigurations.OtherDocuments");
			EndIf;
		EndIf;
		
		vScanConfiguration = tcOnServer.cmGetAtributeAsArray(vRow.ScanConfiguration);
		If vInd = 0 Then
			vResult.Insert("IdentityDocumentType", vScanConfiguration.IdentityDocumentType);	
		EndIf;
		
		If vScanConfiguration.RecognitionIsAvailable Then
			vDocumentTextJSON = pScObj.CheckReaderResultJSON(36, vInd, 0);		
			If ValueIsFilled(vDocumentTextJSON) Then
				vDocumentTextMap = JSONtoMap(vDocumentTextJSON);
				If vDocumentTextMap["Text"] <> Undefined And TypeOf(vDocumentTextMap["Text"]) = Type("Map") Then
					vTextMap = vDocumentTextMap["Text"];
					If vTextMap["fieldList"] <> Undefined And TypeOf(vTextMap["fieldList"]) = Type("Array") Then 
						FillByTextField(vResult, vTextMap["fieldList"], vType, vScanConfiguration.LanguageID, vDescription, vID, vTextMap["dateFormat"]);
						If (Not vResult.Property("Citizenship") Or IsBlankString(vResult.Citizenship)) And Not IsBlankString(vCitizenship) Then
							vResult.Insert("Citizenship", vCitizenship);	
						EndIf;
					EndIf;
				EndIf;	
			EndIf;
			
			If StrFind(lower(vDescription), "passport") > 0 Or StrFind(lower(vDescription), "id card") > 0 
				Or StrFind(lower(vDescription), "registration stamp") Then
				vGraphicsJSON = pScObj.CheckReaderResultJSON(6, vInd, 0);
				If ValueIsFilled(vGraphicsJSON) Then
					vGraphicsMAP = JSONtoMAP(vGraphicsJSON);
					If vGraphicsMAP["DocGraphicsInfo"] <> Undefined And TypeOf(vGraphicsMAP["DocGraphicsInfo"]) = Type("Map") Then
						vDocGraphicsInfo = vGraphicsMAP["DocGraphicsInfo"]; 
						If vDocGraphicsInfo["pArrayFields"] <> Undefined And TypeOf(vDocGraphicsInfo["pArrayFields"]) = Type("Array") Then
							FillByImgFieldType(vResult, vDocGraphicsInfo["pArrayFields"], pStorageUUID); 
						EndIf;
					EndIf;	
				EndIf;
			EndIf;
		EndIf;
		
		vFileImageJSON = pScObj.CheckReaderResultJSON(2, vInd, 0);
		If ValueIsFilled(vFileImageJSON) Then
			vFileImageMAP = JSONtoMAP(vFileImageJSON);
			vPictureStorage = "";
			If vFileImageMAP["FileImageData"] <> Undefined And ValueIsFilled(vFileImageMAP["FileImageData"]) Then
				Try
					vPictureStorage = PutToTempStorage(GetImgByBase64(vFileImageMAP["FileImageData"]), pStorageUUID);
				Except
					vPictureStorage = "";
				EndTry;
			EndIf;
			vRow.PictureStorage = vPictureStorage; 
		EndIf;
	EndDo;
	
	Return vResult;
EndFunction // GetScannedData

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function FormatAddressRegistrationData(pDateString)
	vResult = Undefined;
	
	If ValueIsFilled(pDateString) Then
		Try
			vYear = Right(pDateString, 4);
			vDay = Left(pDateString, 2);
			
			vTextMonthProc = StrReplace(pDateString, vYear, "");
			vTextMonth = TrimAll(StrReplace(vTextMonthProc, vDay, ""));
			
			vMonthNumber = "";
			
			If vTextMonth = "ЯНВАРЯ" Then
				vMonthNumber = "01";
			ElsIf vTextMonth = "ФЕВРАЛЯ" Then
				vMonthNumber = "02";
			ElsIf vTextMonth = "МАРТА" Then
				vMonthNumber = "03";
			ElsIf vTextMonth = "АПРЕЛЯ" Then
				vMonthNumber = "04";
			ElsIf vTextMonth = "МАЯ" Then
				vMonthNumber = "05";
			ElsIf vTextMonth = "ИЮНЯ" Then
				vMonthNumber = "06";
			ElsIf vTextMonth = "ИЮЛЯ" Then
				vMonthNumber = "07";
			ElsIf vTextMonth = "АВГУСТА" Then
				vMonthNumber = "08";
			ElsIf vTextMonth = "СЕНТЯБРЯ" Then
				vMonthNumber = "09";
			ElsIf vTextMonth = "ОКТЯБРЯ" Then
				vMonthNumber = "10";
			ElsIf vTextMonth = "НОЯБРЯ" Then
				vMonthNumber = "11";
			ElsIf vTextMonth = "ДЕКАБРЯ" Then
				vMonthNumber = "12";
			EndIf;
			
			vResult = Date(TrimAll(vYear + vMonthNumber + vDay));
		Except
			vResult = Undefined;
		EndTry;
	EndIf;
	
	Return vResult;
EndFunction // FormatAddressRegistrationData

// -----------------------------------------------------------------------------
Function GetScanConfigurationByIDOrType(Val pID, Val pType, pIsForeigner)
	vScanConfRef = Undefined;
	
	If Not IsBlankString(pID) Then
		vScanConfRef = tcDevicesConnection.GetScanConfigurationByExternalCode(pID);
	EndIf;
	
	If Not ValueIsFilled(vScanConfRef) Then
		vScanConfRef = tcDevicesConnection.GetScanConfigurationByExternalCode(pType);
	EndIf;
	
	If Not ValueIsFilled(vScanConfRef) Then
		If ?(pIsForeigner = 0, False, True) Then 
			vScanConfRef = PredefinedValue("Catalog.ScanConfigurations.OtherDocumentsForeigners");
		Else
			vScanConfRef = PredefinedValue("Catalog.ScanConfigurations.OtherDocuments");
		EndIf;
	EndIf;
	
	Return vScanConfRef;
EndFunction // GetScanConfigurationByIDOrType

// -----------------------------------------------------------------------------
// Converts JSON to map
// 
// Parameters:
//  pJSONString	 - JSON formatted string  
// 
// Returns:
//   - Map - Based on JSON
// -----------------------------------------------------------------------------
Function JSONtoMap(pJSONString)
	vResult = Undefined;
	
	#If WebClient Then
		Return vResult;
	#Else	
		If Not IsBlankString(pJSONString) Then
			vJSONReader = New JSONReader;
			vJSONReader.SetString(pJSONString);
			vResult = ReadJSON(vJSONReader, True);
		EndIf;
		
		Return vResult;
	#EndIf
EndFunction

// -----------------------------------------------------------------------------
Function GetClientSex(pSexStr)
	vSex = Undefined;
	If Not IsBlankString(pSexStr) Then
		vL = Upper(Left(TrimAll(pSexStr), 1));
		If vL = "Ж" Or vL = "F" Then
			vSex = PredefinedValue("Enum.Sex.Female");
		Else
			vSex = PredefinedValue("Enum.Sex.Male");
		EndIf;
	EndIf;
	Return vSex;
EndFunction // GetClientSex

// -----------------------------------------------------------------------------
Procedure FillByTextField(pResult, pFieldList, pType, pLanguageID, pDescription, pID, pDateFormat)
	// Fill Passport information
	// Fill Visa information
	If pType = "178" Then
		For Each vField In pFieldList Do 
			If vField["lcid"] <> 9999 Then 
				
				pResult.Insert("ConfirmingDocumentType", pType);
				
				If vField["fieldType"] <> Undefined And vField["value"] <> Undefined And ValueIsFilled(vField["value"]) Then
					If vField["fieldType"] = 1 Then
						If vField["lcid"] = pLanguageID Or (Not pResult.Property("VisaIssuedBy") Or Not ValueIsFilled(pResult.VisaIssuedBy)) Then
							pResult.Insert("VisaIssuedBy", FormatString(vField["value"])); 
						EndIf;
					ElsIf vField["fieldType"] = 3 Then
						If vField["lcid"] = pLanguageID Or (Not pResult.Property("VisaToDate") Or Not ValueIsFilled(pResult.VisaToDate)) Then
							pResult.Insert("VisaToDate", tcCommonFunctionOnClientServer.StringToDateByFormat(pDateFormat, vField["value"]));
						EndIf;
					ElsIf vField["fieldType"] = 4 Then
						If vField["lcid"] = pLanguageID Or (Not pResult.Property("VisaIssuedDate") Or Not ValueIsFilled(pResult.VisaIssuedDate)) Then
							pResult.Insert("VisaIssuedDate", tcCommonFunctionOnClientServer.StringToDateByFormat(pDateFormat, vField["value"]));
						EndIf;
					ElsIf vField["fieldType"] = 26 Then
						If vField["lcid"] = 0 Or (Not pResult.Property("Citizenship") Or Not ValueIsFilled(pResult.Citizenship)) Then
							pResult.Insert("Citizenship", vField["value"]);
						EndIf;
					ElsIf vField["fieldType"] = 29 Then
						If vField["lcid"] = pLanguageID Or (Not pResult.Property("VisaIdentifier") Or Not ValueIsFilled(pResult.VisaIdentifier)) Then
							pResult.Insert("VisaIdentifier", vField["value"]);
						EndIf;
					ElsIf vField["fieldType"] = 29 Then
						If vField["lcid"] = pLanguageID Or (Not pResult.Property("VisaIdentifier") Or Not ValueIsFilled(pResult.VisaIdentifier)) Then
							pResult.Insert("VisaIdentifier", vField["value"]);
						EndIf;
					ElsIf vField["fieldType"] = 100 Then
						If vField["lcid"] = pLanguageID Or (Not pResult.Property("VisaType") Or Not ValueIsFilled(pResult.VisaType)) Then
							pResult.Insert("VisaType", FormatString(vField["value"]));
							// Rewrite VisaEntryGoal element to the structure so that the VisaEntryGoal element comes after the VisaType element
							If pResult.Property("VisaEntryGoal") Then
								vEntryGoal = pResult.VisaEntryGoal;
								pResult.Delete("VisaEntryGoal");	
								pResult.Insert("VisaEntryGoal", vEntryGoal);
							EndIf;
						EndIf;
					ElsIf vField["fieldType"] = 101 Then
						If vField["lcid"] = pLanguageID Or (Not pResult.Property("VisaFromDate") Or Not ValueIsFilled(pResult.VisaFromDate)) Then
							pResult.Insert("VisaFromDate", tcCommonFunctionOnClientServer.StringToDateByFormat(pDateFormat, vField["value"]));
						EndIf;
					ElsIf vField["fieldType"] = 103 Then
						If vField["lcid"] = pLanguageID Or (Not pResult.Property("VisaDays") Or Not ValueIsFilled(pResult.VisaDays)) Then
							pResult.Insert("VisaDays", vField["value"]);
						EndIf;
					ElsIf vField["fieldType"] = 104 Then
						If vField["lcid"] = pLanguageID Or (Not pResult.Property("VisaMultiplicity") Or Not ValueIsFilled(pResult.VisaMultiplicity)) Then
							pResult.Insert("VisaMultiplicity", FormatString(vField["value"])); 
						EndIf;
					ElsIf vField["fieldType"] = 196 Then
						If vField["lcid"] = pLanguageID Or (Not pResult.Property("VisaNumber") Or Not ValueIsFilled(pResult.VisaNumber)) Then
							pResult.Insert("VisaNumber", FormatString(vField["value"])); 
						EndIf;
					ElsIf vField["fieldType"] = 452 Then
						If vField["lcid"] = pLanguageID Or (Not pResult.Property("VisaEntryGoal") Or Not ValueIsFilled(pResult.VisaEntryGoal)) Then
							pResult.Insert("VisaEntryGoal", FormatString(vField["value"])); 
						EndIf;
					EndIf;
				EndIf; 
			EndIf;
		EndDo; 
		// Fill Permanent Residence Permit information
	ElsIf StrFind(pDescription, "Identity Card for Residence") > 0 Then
		For Each vField In pFieldList Do 
			If vField["lcid"] <> 9999 Then 
				If vField["fieldType"] <> Undefined And vField["value"] <> Undefined And ValueIsFilled(vField["value"]) Then
					
					pResult.Insert("ConfirmingDocumentType", pType);
					
					If vField["fieldType"] = 2 Then
						If vField["lcid"] = pLanguageID Or (Not pResult.Property("VisaNumber") Or Not ValueIsFilled(pResult.VisaNumber)) Then
							pResult.Insert("VisaNumber", vField["value"]); 
						EndIf;
					ElsIf vField["fieldType"] = 3 Then
						If vField["lcid"] = 0 Or (Not pResult.Property("VisaToDate") Or Not ValueIsFilled(pResult.VisaToDate)) Then
							pResult.Insert("VisaToDate", tcCommonFunctionOnClientServer.StringToDateByFormat(pDateFormat, vField["value"]));
						EndIf;
					ElsIf vField["fieldType"] = 4 Then
						If vField["lcid"] = 0 Or (Not pResult.Property("VisaFromDate") Or Not ValueIsFilled(pResult.VisaFromDate)) Then
							pResult.Insert("VisaFromDate", tcCommonFunctionOnClientServer.StringToDateByFormat(pDateFormat, vField["value"]));
						EndIf;
					ElsIf vField["fieldType"] = 11 Then
						If vField["lcid"] = pLanguageID Or (Not pResult.Property("Citizenship") Or Not ValueIsFilled(pResult.Citizenship)) Then
							pResult.Insert("Citizenship", FormatString(vField["value"])); 
						EndIf;
					ElsIf vField["fieldType"] = 24 Then
						If vField["lcid"] = pLanguageID Or (Not pResult.Property("VisaIssuedBy") Or Not ValueIsFilled(pResult.VisaIssuedBy)) Then
							pResult.Insert("VisaIssuedBy", FormatString(vField["value"])); 
						EndIf;
						
					ElsIf vField["fieldType"] = 57 Then
						If vField["lcid"] = pLanguageID Or (Not pResult.Property("VisaIdentifier") Or Not ValueIsFilled(pResult.VisaIdentifier)) Then
							pResult.Insert("VisaIdentifier", vField["value"]); 
						EndIf;
					ElsIf vField["fieldType"] = 70 Then
						If vField["lcid"] = 0 Or (Not pResult.Property("VisaIssuedDate") Or Not ValueIsFilled(pResult.VisaIssuedDate)) Then
							pResult.Insert("VisaIssuedDate", tcCommonFunctionOnClientServer.StringToDateByFormat(pDateFormat, vField["value"])); 
						EndIf;
					EndIf;
				EndIf; 
			EndIf;
		EndDo;
		// Fill Temporary Residence Permit information
	ElsIf pType = "215" Then
		For Each vField In pFieldList Do 
			If vField["lcid"] <> 9999 Then 
				If vField["fieldType"] <> Undefined And vField["value"] <> Undefined And ValueIsFilled(vField["value"]) Then
					
					pResult.Insert("ConfirmingDocumentType", pType);
					
					If vField["fieldType"] = 2 Then
						If vField["lcid"] = pLanguageID Or (Not pResult.Property("VisaIdentifier") Or Not ValueIsFilled(pResult.VisaIdentifier)) Then
							pResult.Insert("VisaIdentifier", vField["value"]); 
						EndIf;
					ElsIf vField["fieldType"] = 3 Then
						If vField["lcid"] = 0 Or (Not pResult.Property("VisaToDate") Or Not ValueIsFilled(pResult.VisaToDate)) Then
							pResult.Insert("VisaToDate", tcCommonFunctionOnClientServer.StringToDateByFormat(pDateFormat, vField["value"])); 
						EndIf;
					ElsIf vField["fieldType"] = 4 Then
						If vField["lcid"] = 0 Or (Not pResult.Property("VisaIssuedDate") Or Not ValueIsFilled(pResult.VisaIssuedDate)) Then
							pResult.Insert("VisaIssuedDate", tcCommonFunctionOnClientServer.StringToDateByFormat(pDateFormat, vField["value"]));
						EndIf;
					ElsIf vField["fieldType"] = 11 Then
						If vField["lcid"] = pLanguageID Or (Not pResult.Property("Citizenship") Or Not ValueIsFilled(pResult.Citizenship)) Then
							pResult.Insert("Citizenship", FormatString(vField["value"])); 
						EndIf;
					ElsIf vField["fieldType"] = 24 Then
						If vField["lcid"] = pLanguageID Or (Not pResult.Property("VisaIssuedBy") Or Not ValueIsFilled(pResult.VisaIssuedBy)) Then
							pResult.Insert("VisaIssuedBy", FormatString(vField["value"])); 
						EndIf;
					EndIf;
				EndIf; 
			EndIf;
		EndDo;
	ElsIf pID = "353160962" Then
		vAddrElements = New Structure("Country, PostCode, Region, Area, City, Street, House, Flat", PredefinedValue("Catalog.Countries.EmptyRef"), "", "", "", "", "", "", "");
		For Each vField In pFieldList Do
			If vField["lcid"] <> 9999 Then
				If vField["fieldType"] <> Undefined And vField["value"] <> Undefined And ValueIsFilled(vField["value"]) Then
					If vField["fieldType"] = 70 Then
						If vField["lcid"] = pLanguageID Or (Not pResult.Property("AddressRegistrationDate") Or Not ValueIsFilled(pResult.AddressRegistrationDate)) Then
							pResult.Insert("AddressRegistrationDate", FormatAddressRegistrationData(vField["value"])); 
						EndIf;
					ElsIf vField["fieldType"] = 1 Then
						If vField["lcid"] = pLanguageID Or (Not vAddrElements.Property("Country") Or Not ValueIsFilled(vAddrElements.Country)) Then
							vAddrElements.Insert("Country", tcOnServer.GetCountryByCode(vField["value"])); 
						EndIf; 
					ElsIf vField["fieldType"] = 79 Then
						If vField["lcid"] = pLanguageID Or (Not vAddrElements.Property("PostCode") Or Not ValueIsFilled(vAddrElements.PostCode)) Then
							vAddrElements.Insert("PostCode", vField["value"]); 
						EndIf;
					ElsIf vField["fieldType"] = 65 Then
						If vField["lcid"] = pLanguageID Or (Not vAddrElements.Property("Region") Or Not ValueIsFilled(vAddrElements.Region)) Then
							vAddrElements.Insert("Region", vField["value"]); 
						EndIf; 
					ElsIf vField["fieldType"] = 76 Then
						If vField["lcid"] = pLanguageID Or (Not vAddrElements.Property("Street") Or Not ValueIsFilled(vAddrElements.Street)) Then
							vAddrElements.Insert("Street", vField["value"]); 
						EndIf;
					ElsIf vField["fieldType"] = 77 Then
						If vField["lcid"] = pLanguageID Or (Not vAddrElements.Property("City") Or Not ValueIsFilled(vAddrElements.City)) Then
							vValueArr = StrSplit(vField["value"], ",", False);
							vAddrElements.Insert("City", TrimAll(vValueArr[0]));
						EndIf;
					ElsIf vField["fieldType"] = 67 Then
						If vField["lcid"] = pLanguageID Or (Not vAddrElements.Property("House") Or Not ValueIsFilled(vAddrElements.House)) Then
							vAddrElements.Insert("House", vField["value"]); 
						EndIf;
					ElsIf vField["fieldType"] = 68 Then
						If vField["lcid"] = pLanguageID Or (Not vAddrElements.Property("Flat") Or Not ValueIsFilled(vAddrElements.Flat)) Then
							vAddrElements.Insert("Flat", vField["value"]); 
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		pResult.Insert("Address", tcOnServer.BuildAddress(vAddrElements.Country, vAddrElements.PostCode, vAddrElements.Region, vAddrElements.Area, vAddrElements.City, vAddrElements.Street, vAddrElements.House, vAddrElements.Flat)); 
	Else
		For Each vField In pFieldList Do 
			If vField["lcid"] <> 9999 Then 
				If vField["fieldType"] <> Undefined And vField["value"] <> Undefined And ValueIsFilled(vField["value"]) Then
					If (pType <> "12" And vField["fieldType"] = 2) Or (pType <> "12" And vField["fieldType"] = 142) Then
						If vField["lcid"] = pLanguageID Or (Not pResult.Property("IdentityDocumentNumber") Or Not ValueIsFilled(pResult.IdentityDocumentNumber)) Then 
							pResult.Insert("IdentityDocumentNumber", vField["value"]);
						EndIf;
					ElsIf vField["fieldType"] = 3 Then
						If vField["lcid"] = pLanguageID Or (Not pResult.Property("IdentityDocumentValidToDate") Or Not ValueIsFilled(pResult.IdentityDocumentValidToDate)) Then
							pResult.Insert("IdentityDocumentValidToDate", tcCommonFunctionOnClientServer.StringToDateByFormat(pDateFormat, vField["value"])); 
						EndIf;
					ElsIf vField["fieldType"] = 4 Then
						If vField["lcid"] = pLanguageID Or (Not pResult.Property("IdentityDocumentIssueDate") Or Not ValueIsFilled(pResult.IdentityDocumentIssueDate)) Then
							pResult.Insert("IdentityDocumentIssueDate", tcCommonFunctionOnClientServer.StringToDateByFormat(pDateFormat, vField["value"]));
						EndIf;
					ElsIf vField["fieldType"] = 5 Then
						If vField["lcid"] = pLanguageID Or (Not pResult.Property("DateOfBirth") Or Not ValueIsFilled(pResult.DateOfBirth)) Then
							pResult.Insert("DateOfBirth", tcCommonFunctionOnClientServer.StringToDateByFormat(pDateFormat, vField["value"]));
						EndIf;
					ElsIf vField["fieldType"] = 6 Then
						If vField["lcid"] = pLanguageID Or (Not pResult.Property("PlaceOfBirth") Or Not ValueIsFilled(pResult.PlaceOfBirth)) Then
							pResult.Insert("PlaceOfBirth", FormatString(vField["value"])); 
						EndIf;
					ElsIf vField["fieldType"] = 8 Then
						If vField["lcid"] = pLanguageID Or (Not pResult.Property("LastName") Or Not ValueIsFilled(pResult.LastName)) Then
							pResult.Insert("LastName", FormatString(Title(TrimAll(vField["value"]))));   
						EndIf;
					ElsIf vField["fieldType"] = 9 Then
						If vField["lcid"] = pLanguageID Or (Not pResult.Property("FirstName") Or Not ValueIsFilled(pResult.FirstName)) Then
							pResult.Insert("FirstName", FormatString(Title(TrimAll(vField["value"])))); 
						EndIf;
					ElsIf vField["fieldType"] = 12 Then
						If vField["lcid"] = pLanguageID Or (Not pResult.Property("Sex") Or Not ValueIsFilled(pResult.Sex)) Then
							pResult.Insert("Sex", GetClientSex(vField["value"]));
						EndIf;
					ElsIf vField["fieldType"] = 17 Then
						If vField["lcid"] = pLanguageID Or (Not pResult.Property("Address") Or Not ValueIsFilled(pResult.Address)) Then
							pResult.Insert("Address", FormatString(vField["value"])); 
						EndIf;
					ElsIf vField["fieldType"] = 24 And Not pType = "227" Then
						If vField["lcid"] = pLanguageID Or (Not pResult.Property("IdentityDocumentIssuedBy") Or Not ValueIsFilled(pResult.IdentityDocumentIssuedBy)) Then
							pResult.Insert("IdentityDocumentIssuedBy", FormatString(vField["value"])); 
						EndIf;
					ElsIf vField["fieldType"] = 26 Then
						If (vField["lcid"] = 0 Or (Not pResult.Property("Citizenship") Or Not ValueIsFilled(pResult.Citizenship))) And StrLen(vField["value"]) >= 2 Then
							pResult.Insert("Citizenship", vField["value"]);
						EndIf;
					ElsIf vField["fieldType"] = 56 Then
						If vField["lcid"] = pLanguageID Or (Not pResult.Property("IdentityDocumentSeries") Or Not ValueIsFilled(pResult.IdentityDocumentSeries)) Then
							pResult.Insert("IdentityDocumentSeries", vField["value"]);
						EndIf;
					ElsIf vField["fieldType"] = 70 Then
						If vField["lcid"] = pLanguageID Or (Not pResult.Property("AddressRegistrationDate") Or Not ValueIsFilled(pResult.AddressRegistrationDate)) Then
							pResult.Insert("AddressRegistrationDate", FormatAddressRegistrationData(vField["value"])); 
						EndIf;
					ElsIf vField["fieldType"] = 73 Then
						If vField["lcid"] = pLanguageID Or (Not pResult.Property("IdentityDocumentUnitCode") Or Not ValueIsFilled(pResult.IdentityDocumentUnitCode)) Then
							pResult.Insert("IdentityDocumentUnitCode", vField["value"]);
						EndIf;
					ElsIf vField["fieldType"] = 129 Then
						If vField["lcid"] = pLanguageID Or (Not pResult.Property("SecondName") Or Not ValueIsFilled(pResult.SecondName)) Then
							pResult.Insert("SecondName", FormatString(Title(TrimAll(vField["value"]))));
						EndIf;
					EndIf;
				EndIf; 
			EndIf;
		EndDo; 
		If pResult.Property("IdentityDocumentNumber") And pResult.Property("IdentityDocumentSeries") Then
			If ValueIsFilled(pResult.IdentityDocumentSeries) And pResult.IdentityDocumentSeries = Left(pResult.IdentityDocumentNumber, 4) Then
				pResult.IdentityDocumentNumber = Right(pResult.IdentityDocumentNumber, StrLen(pResult.IdentityDocumentNumber) - 4);	
			EndIf;
		EndIf;
		If pResult.Property("IdentityDocumentUnitCode") And ValueIsFilled(pResult.IdentityDocumentUnitCode) And 
			StrLen(pResult.IdentityDocumentUnitCode) = 6 And StrFind(pResult.IdentityDocumentUnitCode, "-") = 0 Then
			pResult.IdentityDocumentUnitCode = Left(pResult.IdentityDocumentUnitCode, 3) + "-" + Right(pResult.IdentityDocumentUnitCode, 3);
		EndIf;
	EndIf;
EndProcedure // FillByTextField

// -----------------------------------------------------------------------------
Function FormatString(pStr)
	vStr = StrReplace(pStr, "^", " ");
	vStr = StrReplace(vStr, Chars.LF, " ");
	vStr = StrReplace(vStr, Chars.CR, " ");
	vStr = StrReplace(vStr, "  ", " ");
	vStr = StrReplace(vStr, "  ", " ");
	Return vStr; 
EndFunction // StringFormat

// -----------------------------------------------------------------------------
Procedure FillByImgFieldType(pResult, Val pFieldList, Val pStorageUUID)
	For Each vField In pFieldList Do 
		If vField["FieldType"] <> Undefined And vField["image"] <> Undefined Then
			vImageM = vField["image"];
			If vImageM["image"] <> Undefined And ValueIsFilled(vImageM["image"]) Then
				If vField["FieldType"] = 201 Then
					pResult.Insert("Photo", PutToTempStorage(GetImgByBase64(vImageM["image"]), pStorageUUID));
				ElsIf vField["FieldType"] = 204 Then
					pResult.Insert("Signature", PutToTempStorage(GetImgByBase64(vImageM["image"]), pStorageUUID));
				EndIf; 
			EndIf;
		EndIf;
	EndDo;
EndProcedure // FillByImgFieldType

// -----------------------------------------------------------------------------
Function GetImgByBase64(pBase64)
	vResult = New Picture();
	If ValueIsFilled(pBase64) Then
		Try
			vResult = New Picture(Base64Value(pBase64));
		Except
			vResult = New Picture();
		EndTry;	
	EndIf;
	Return vResult;
EndFunction // GetImgByBase64

#EndRegion