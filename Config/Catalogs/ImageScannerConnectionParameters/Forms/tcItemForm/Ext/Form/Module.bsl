
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	vId = 0;
	While vId < CurrentObject.ScanConfigurations.Count() Do
		vPMRow = CurrentObject.ScanConfigurations.Get(vId);
		If Not ValueIsFilled(vPMRow.ScanConfiguration) Then
			CurrentObject.ScanConfigurations.Delete(vId);
		Else
			vId = vId + 1;
		EndIf;
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(Cancel)
	SetVisible();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ScanComponentInstallationPathStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	tcOnClient.cmGetChooseDirectory(Object.ScanComponentInstallationPath, ThisObject, "SaveFilePathStartChoice_AfterInput");
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ImageScannerDriverOnChange(Item)
	SetVisible();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure TwainDeviceNameStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	If Not ValueIsFilled(Object.ImageScannerDriver) Then
		ShowMessageBox(,NStr("en='Please choose driver type first!';ru='Сначала укажите тип драйвера!';de='Zuerst den Treibertyp angeben!'"));
		Return;
	EndIf;
	If Object.Ref.IsEmpty() Then
		If Not Write() Then
			Return;
		EndIf;	
	EndIf;	
	vMsg = "";
	If amImageScanner = Undefined Then
		// Load driver to get list of TWAIN devices
		vModuleName = tcDevicesConnection.cmGetImagesScannerDriverModule(vMsg, Object.Ref);
		If Not IsBlankString(vMsg) Then
			ShowMessageBox(,vMsg);
			Return;
		Else
			If Not vModuleName = Undefined Then
				amImageScanner  = tcCommonFunctions.cmGetCommonModule(vModuleName);
			EndIf; 
		EndIf; 
	EndIf;
	If amImageScanner = Undefined Then
		ShowMessageBox(,NStr("en = 'Could not connect to image scanner!'; de = 'Verbindung zum Bildscanner konnte nicht hergestellt werden!'; ru = 'Не удалось подключиться к сканеру изображений!'"));
		Return;
	EndIf;
	vError = "";
	vList = amImageScanner.pmGetListOfTWAINDevices(vError);
	If IsBlankString(vError) Then
		If vList.Count() > 0 Then
			ShowChooseFromList(New NotifyDescription("AfterTWAINDeviceNameChoice", ThisObject), vList, Items.TwainDeviceName, vList.FindByValue(TrimAll(Object.TwainDeviceName)));
		Else
			ShowMessageBox(, NStr("en='No TWAIN scanners found in this system!'; ru='В системе не найдены TWAIN сканеры!'; de='Es wurden keine TWAIN-Scanner im System gefunden!'"));
		EndIf;
	Else	
		ShowMessageBox(, vError);
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SetScanConfigurations(pCommand)
	RegulaCreateScanConfigurations(StrReplace(pCommand.Name, "SetScanConfigurationsFor", ""));
EndProcedure // SetScanConfigurations

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterTWAINDeviceNameChoice(vListItem, pExtraParams) Export
	If vListItem <> Undefined Then
		Object.TwainDeviceName = vListItem.Value;
	EndIf;
EndProcedure // AfterTWAINDeviceNameChoice

// -----------------------------------------------------------------------------
&AtServer
Procedure RegulaCreateScanConfigurations(pCountry)
	If pCountry = "Russia" Then	
		// Russian Federation Passport
		vExistingScanConf = Catalogs.ScanConfigurations.FindByCode("R_PS");
		If Not ValueIsFilled(vExistingScanConf) Then
			vScanConf 							= Catalogs.ScanConfigurations.CreateItem();
			vScanConf.LanguageID 				= 1049; 
			vScanConf.IdentityDocumentType 		= Catalogs.IdentityDocumentTypes.FindByCode("21");
			vScanConf.RecognitionIsAvailable 	= True;
			vScanConf.Code 						= "R_PS";
			vScanConf.SortCode					= "10";
			vScanConf.Description				= "Паспорт гражданина РФ"; 
			vScanConf.IsForeigner				= False;
			
			vExtNamesArr = New Array();
			vExtNamesArr.Add("1171200983");
			vExtNamesArr.Add("1369317533");
			vExtNamesArr.Add("709706995");
			vExtNamesArr.Add("2145766991");
			
			For Each vExtNameVal In vExtNamesArr Do
				vNewRow 				= vScanConf.ExternalNames.Add();
				vNewRow.ExternalName 	= vExtNameVal;
			EndDo;
			
			vScanConf.Write();	
			vScanConfRef = vScanConf.Ref;
		Else
			vScanConfRef = vExistingScanConf;	
		EndIf;
		
		vNewRow 					= Object.ScanConfigurations.Add();
		vNewRow.ScanConfiguration 	= vScanConfRef;
		
		// Russian Federation Passport (registration)
		vExistingScanConf = Catalogs.ScanConfigurations.FindByCode("R_PSA");
		If Not ValueIsFilled(vExistingScanConf) Then
			vScanConf 							= Catalogs.ScanConfigurations.CreateItem();
			vScanConf.LanguageID 				= 1049; 
			vScanConf.IdentityDocumentType 		= Catalogs.IdentityDocumentTypes.FindByCode("21");
			vScanConf.RecognitionIsAvailable 	= True;
			vScanConf.Code 						= "R_PSA";
			vScanConf.SortCode					= "20";
			vScanConf.Description				= "Паспорт гражданина РФ (прописка)"; 
			vScanConf.IsForeigner				= False;
						
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "353160962";
			
			vScanConf.Write();	
			vScanConfRef = vScanConf.Ref;
		Else
			vScanConfRef = vExistingScanConf;	
		EndIf;
		
		vNewRow 					= Object.ScanConfigurations.Add();
		vNewRow.ScanConfiguration 	= vScanConfRef;
		
		// Birth certificate
		vExistingScanConf = Catalogs.ScanConfigurations.FindByCode("R_BC");
		If Not ValueIsFilled(vExistingScanConf) Then
			vScanConf 							= Catalogs.ScanConfigurations.CreateItem();
			vScanConf.LanguageID 				= 1049; 
			vScanConf.IdentityDocumentType 		= Catalogs.IdentityDocumentTypes.FindByCode("03");
			vScanConf.RecognitionIsAvailable 	= False;
			vScanConf.Code 						= "R_BC";
			vScanConf.SortCode					= "30";	
			vScanConf.Description				= "Свидетельство о рождении"; 
			vScanConf.IsForeigner				= False;
									
			vScanConf.Write();	
			vScanConfRef = vScanConf.Ref;
		Else
			vScanConfRef = vExistingScanConf;	
		EndIf;
		
		vNewRow 					= Object.ScanConfigurations.Add();
		vNewRow.ScanConfiguration 	= vScanConfRef;
		
		// International passport
		vExistingScanConf = Catalogs.ScanConfigurations.FindByCode("R_FPS");
		If Not ValueIsFilled(vExistingScanConf) Then
			vScanConf 							= Catalogs.ScanConfigurations.CreateItem();
			vScanConf.LanguageID 				= 1049; 
			vScanConf.IdentityDocumentType 		= Catalogs.IdentityDocumentTypes.FindByCode("22");
			vScanConf.RecognitionIsAvailable 	= True;
			vScanConf.Code 						= "R_FPS";
			vScanConf.SortCode					= "40";	
			vScanConf.Description				= "Загранпаспорт гражданина РФ"; 
			vScanConf.IsForeigner				= False;
			
			vExtNamesArr = New Array();
			vExtNamesArr.Add("1758730563");
			vExtNamesArr.Add("1422701063");
			
			For Each vExtNameVal In vExtNamesArr Do
				vNewRow 				= vScanConf.ExternalNames.Add();
				vNewRow.ExternalName 	= vExtNameVal;
			EndDo;
			
			vScanConf.Write();	
			vScanConfRef = vScanConf.Ref;
		Else
			vScanConfRef = vExistingScanConf;	
		EndIf;
		
		vNewRow 					= Object.ScanConfigurations.Add();
		vNewRow.ScanConfiguration 	= vScanConfRef;
		
		// Migration card
		vExistingScanConf = Catalogs.ScanConfigurations.FindByCode("F_MIG");
		If Not ValueIsFilled(vExistingScanConf) Then
			vScanConf 							= Catalogs.ScanConfigurations.CreateItem();
			vScanConf.LanguageID 				= 0; 
			vScanConf.IsMigrationCard 			= True;
			vScanConf.RecognitionIsAvailable 	= False;
			vScanConf.Code 						= "F_MIG";
			vScanConf.SortCode					= "110";	
			vScanConf.Description				= "Миграционная карта"; 
			vScanConf.IsForeigner				= True;
						
			vScanConf.Write();	
			vScanConfRef = vScanConf.Ref;
		Else
			vScanConfRef = vExistingScanConf;	
		EndIf;
		
		vNewRow 					= Object.ScanConfigurations.Add();
		vNewRow.ScanConfiguration 	= vScanConfRef;
		
		// Visa
		vExistingScanConf = Catalogs.ScanConfigurations.FindByCode("F_VIS");
		If Not ValueIsFilled(vExistingScanConf) Then
			vScanConf 							= Catalogs.ScanConfigurations.CreateItem();
			vScanConf.LanguageID 				= 1049; 
			vScanConf.IsVisa 					= True;
			vScanConf.RecognitionIsAvailable 	= True;
			vScanConf.Code 						= "F_VIS";
			vScanConf.SortCode					= "120";
			vScanConf.Description				= "Виза"; 
			vScanConf.IsForeigner				= True;
			
			vExtNamesArr = New Array();
			vExtNamesArr.Add("1421090647");
			vExtNamesArr.Add("1421127308");
			vExtNamesArr.Add("1641234448");
			
			For Each vExtNameVal In vExtNamesArr Do
				vNewRow 				= vScanConf.ExternalNames.Add();
				vNewRow.ExternalName 	= vExtNameVal;
			EndDo;
			
			vScanConf.Write();	
			vScanConfRef = vScanConf.Ref;
		Else
			vScanConfRef = vExistingScanConf;	
		EndIf;
		
		vNewRow 					= Object.ScanConfigurations.Add();
		vNewRow.ScanConfiguration 	= vScanConfRef;
		
		// Temporary residence permit
		vExistingScanConf = Catalogs.ScanConfigurations.FindByCode("F_TRP");
		If Not ValueIsFilled(vExistingScanConf) Then
			vScanConf 							= Catalogs.ScanConfigurations.CreateItem();
			vScanConf.LanguageID 				= 1049; 
			vScanConf.IdentityDocumentType 		= Catalogs.IdentityDocumentTypes.FindByCode("101a");
			vScanConf.RecognitionIsAvailable 	= True;
			vScanConf.Code 						= "F_TRP";
			vScanConf.SortCode					= "130";
			vScanConf.Description				= "Разрешение на временное проживание (РВП)"; 
			vScanConf.IsForeigner				= True;
			
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "1272387050";
			
			vScanConf.Write();	
			vScanConfRef = vScanConf.Ref;
		Else
			vScanConfRef = vExistingScanConf;	
		EndIf;
		
		vNewRow 					= Object.ScanConfigurations.Add();
		vNewRow.ScanConfiguration 	= vScanConfRef;
		
		// Resident card
		vExistingScanConf = Catalogs.ScanConfigurations.FindByCode("F_RP");
		If Not ValueIsFilled(vExistingScanConf) Then
			vScanConf 							= Catalogs.ScanConfigurations.CreateItem();
			vScanConf.LanguageID 				= 1049; 
			vScanConf.IdentityDocumentType 		= Catalogs.IdentityDocumentTypes.FindByCode("19");
			vScanConf.RecognitionIsAvailable 	= True;
			vScanConf.Code 						= "F_RP";
			vScanConf.SortCode					= "140";
			vScanConf.Description				= "Вид на жительство (ВНЖ)"; 
			vScanConf.IsForeigner				= True;
			
			vExtNamesArr = New Array();
			vExtNamesArr.Add("790943544");
			vExtNamesArr.Add("-1317035017");
			vExtNamesArr.Add("-771942632");
			
			For Each vExtNameVal In vExtNamesArr Do
				vNewRow 				= vScanConf.ExternalNames.Add();
				vNewRow.ExternalName 	= vExtNameVal;
			EndDo;
			
			vScanConf.Write();	
			vScanConfRef = vScanConf.Ref;
		Else
			vScanConfRef = vExistingScanConf;	
		EndIf;
		
		vNewRow 					= Object.ScanConfigurations.Add();
		vNewRow.ScanConfiguration 	= vScanConfRef; 
		
		// Foreigner passport
		vExistingScanConf = Catalogs.ScanConfigurations.FindByCode("F_PS");
		If Not ValueIsFilled(vExistingScanConf) Then
			vScanConf 							= Catalogs.ScanConfigurations.CreateItem();
			vScanConf.LanguageID 				= 0; 
			vScanConf.IdentityDocumentType 		= Catalogs.IdentityDocumentTypes.FindByCode("ИП");
			vScanConf.RecognitionIsAvailable 	= True;
			vScanConf.Code 						= "F_PS";
			vScanConf.SortCode					= "100";
			vScanConf.Description				= "Иностранный паспорт";
			vScanConf.IsForeigner				= True;
			
			// Foreigner
			
			vDocumentTypeList = Catalogs.ScanConfigurations.GetTemplate("RegulaDocumentType");

			For vID = 2 To vDocumentTypeList.TableHeight Do
				Try       
					vNewRow 				= vScanConf.ExternalNames.Add();
					vNewRow.ExternalName 	= TrimAll(vDocumentTypeList.Area(vID, 2, vID, 2).Text);	
				Except
				EndTry;
			EndDo;
					
			vScanConf.Write();
			vScanConfRef = vScanConf.Ref;
		Else
			vScanConfRef = vExistingScanConf;	
		EndIf;
		
		vNewRow 					= Object.ScanConfigurations.Add();
		vNewRow.ScanConfiguration 	= vScanConfRef;
		
		// Other documents
		vExistingScanConf = PredefinedValue("Catalog.ScanConfigurations.OtherDocuments");
		vExistingScanConfObj = vExistingScanConf.GetObject();
		
		vExistingScanConfObj.LanguageID 				= 1049; 
		vExistingScanConfObj.RecognitionIsAvailable 	= False;
		vExistingScanConfObj.SortCode					= "90";
		vExistingScanConfObj.Description				= "Другие документы";
		vExistingScanConfObj.IsForeigner				= False;
		
		vExistingScanConfObj.Write();
		vScanConfRef = vExistingScanConf;	
		
		vNewRow 					= Object.ScanConfigurations.Add();
		vNewRow.ScanConfiguration 	= vScanConfRef;
		
		// Other documents foreigners
		vExistingScanConf = PredefinedValue("Catalog.ScanConfigurations.OtherDocumentsForeigners");;
		vExistingScanConfObj = vExistingScanConf.GetObject();
		
		vExistingScanConfObj.LanguageID 				= 1049; 
		vExistingScanConfObj.RecognitionIsAvailable 	= False;
		vExistingScanConfObj.SortCode					= "190";
		vExistingScanConfObj.Description				= "Другие документы";
		vExistingScanConfObj.IsForeigner				= True;
		
		vExistingScanConfObj.Write();
		vScanConfRef = vExistingScanConf;	
		
		vNewRow 					= Object.ScanConfigurations.Add();
		vNewRow.ScanConfiguration 	= vScanConfRef;
		
	ElsIf pCountry = "Cyprus" Then
		// Cyprus ID
		vExistingScanConf = Catalogs.ScanConfigurations.FindByCode("C_ID");
		If Not ValueIsFilled(vExistingScanConf) Then
			vScanConf 							= Catalogs.ScanConfigurations.CreateItem();
			vScanConf.LanguageID 				= 0; 
			vScanConf.RecognitionIsAvailable 	= True;
			vScanConf.Code 						= "C_ID";
			vScanConf.Description				= "Cyprus Identity Card"; 
			vScanConf.IsForeigner				= False;
			
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "99070800";
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "99083549";
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "-651772825";
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "-651757968";
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "1431328686";
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "1921026452";
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "2024891476";
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "2024914511";
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "1212779972"; 
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "887666658";
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "1038170743";
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "1038188897";
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "1038197007";
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "1038202727";
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "1266283546";
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "1774295489";
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "1774295678";
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "-1871762825";
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "-1871761496";
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "-984538107";
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "-984536360";
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "722010344";
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "952794309";
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "456743028";
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "456743062";
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "1392281158";
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "-869615763";
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "-869601473";
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "727856897";
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "727857485";
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "1425353616";
						
			vScanConf.Write();	
			vScanConfRef = vScanConf.Ref;
		Else
			vScanConfRef = vExistingScanConf;	
		EndIf; 
		
		vNewRow 					= Object.ScanConfigurations.Add();
		vNewRow.ScanConfiguration 	= vScanConfRef;
		
		// Cyprus Passport
		vExistingScanConf = Catalogs.ScanConfigurations.FindByCode("C_PAS");
		If Not ValueIsFilled(vExistingScanConf) Then
			vScanConf 							= Catalogs.ScanConfigurations.CreateItem();
			vScanConf.LanguageID 				= 0; 
			vScanConf.RecognitionIsAvailable 	= True;
			vScanConf.Code 						= "C_PAS";
			vScanConf.Description				= "Cyprus passport";
			vScanConf.IsForeigner				= False;
			
			// Cyprus Passport (Passport)
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "11";
			
			vScanConf.Write();
			vScanConfRef = vScanConf.Ref;
		Else
			vScanConfRef = vExistingScanConf;	
		EndIf;

		vNewRow 					= Object.ScanConfigurations.Add();
		vNewRow.ScanConfiguration 	= vScanConfRef;	 
		
		//Foreigner ID
		vExistingScanConf = Catalogs.ScanConfigurations.FindByCode("F_ID");
		If Not ValueIsFilled(vExistingScanConf) Then
			vScanConf 							= Catalogs.ScanConfigurations.CreateItem();
			vScanConf.LanguageID 				= 0; 
			vScanConf.RecognitionIsAvailable 	= True;
			vScanConf.Code 						= "F_ID";
			vScanConf.Description				= "EU Identity Card";
			vScanConf.IsForeigner				= True;
			
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "12";
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "215";
			
			vScanConf.Write();
			vScanConfRef = vScanConf.Ref;
		Else
			vScanConfRef = vExistingScanConf;	
		EndIf;
		
		vNewRow 					= Object.ScanConfigurations.Add();
		vNewRow.ScanConfiguration 	= vScanConfRef;
		
		//Foreigner
		vExistingScanConf = Catalogs.ScanConfigurations.FindByCode("F_PAS");
		If Not ValueIsFilled(vExistingScanConf) Then
			vScanConf 							= Catalogs.ScanConfigurations.CreateItem();
			vScanConf.LanguageID 				= 0; 
			vScanConf.RecognitionIsAvailable 	= True;
			vScanConf.Code 						= "F_PAS";
			vScanConf.Description				= "Passport of a foreigner";
			vScanConf.IsForeigner				= True;
			
			// Foreigner
			vDocumentTypeList = Catalogs.ScanConfigurations.GetTemplate("RegulaDocumentType");

			For vID = 2 To vDocumentTypeList.TableHeight Do
				Try       
					vNewRow 				= vScanConf.ExternalNames.Add();
					vNewRow.ExternalName 	= TrimAll(vDocumentTypeList.Area(vID, 2, vID, 2).Text);	
				Except
				EndTry;
			EndDo;
					
			vScanConf.Write();
			vScanConfRef = vScanConf.Ref;
		Else
			vScanConfRef = vExistingScanConf;	
		EndIf;
		
		vNewRow 					= Object.ScanConfigurations.Add();
		vNewRow.ScanConfiguration 	= vScanConfRef;	
	Else
		// EU ID
		vExistingScanConf = Catalogs.ScanConfigurations.FindByCode("R_EUID");
		If Not ValueIsFilled(vExistingScanConf) Then
			vScanConf 							= Catalogs.ScanConfigurations.CreateItem();
			vScanConf.LanguageID 				= 0; 
			vScanConf.RecognitionIsAvailable 	= True;
			vScanConf.Code 						= "R_EUID";
			vScanConf.Description				= "Identity Card"; 
			vScanConf.IsForeigner				= False;
			
			// EU ID (Identity Card)
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "12";
			
			// EU ID (Residence Permit)
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "215";
			
			vScanConf.Write();	
			vScanConfRef = vScanConf.Ref;
		Else
			vScanConfRef = vExistingScanConf;	
		EndIf; 
		
		vNewRow 					= Object.ScanConfigurations.Add();
		vNewRow.ScanConfiguration 	= vScanConfRef;
		
		// EU Passport
		vExistingScanConf = Catalogs.ScanConfigurations.FindByCode("R_EUP");
		If Not ValueIsFilled(vExistingScanConf) Then
			vScanConf 							= Catalogs.ScanConfigurations.CreateItem();
			vScanConf.LanguageID 				= 0; 
			vScanConf.RecognitionIsAvailable 	= True;
			vScanConf.Code 						= "R_EUP";
			vScanConf.Description				= "Passport";
			vScanConf.IsForeigner				= False;
			
			// EU Passport (Passport)
			vNewRow 				= vScanConf.ExternalNames.Add();
			vNewRow.ExternalName 	= "11";
			
			vScanConf.Write();
			vScanConfRef = vScanConf.Ref;
		Else
			vScanConfRef = vExistingScanConf;	
		EndIf;

		vNewRow 					= Object.ScanConfigurations.Add();
		vNewRow.ScanConfiguration 	= vScanConfRef;	 
		
		//Foreigner
		vExistingScanConf = Catalogs.ScanConfigurations.FindByCode("R_PFO");
		If Not ValueIsFilled(vExistingScanConf) Then
			vScanConf 							= Catalogs.ScanConfigurations.CreateItem();
			vScanConf.LanguageID 				= 0; 
			vScanConf.RecognitionIsAvailable 	= True;
			vScanConf.Code 						= "R_PFO";
			vScanConf.Description				= "Passport of a foreigner";
			vScanConf.IsForeigner				= True;
			
			// Foreigner
			vDocumentTypeList = Catalogs.ScanConfigurations.GetTemplate("RegulaDocumentType");

			For vID = 2 To vDocumentTypeList.TableHeight Do
				Try       
					vNewRow 				= vScanConf.ExternalNames.Add();
					vNewRow.ExternalName 	= TrimAll(vDocumentTypeList.Area(vID, 2, vID, 2).Text);	
				Except
				EndTry;
			EndDo;
					
			vScanConf.Write();
			vScanConfRef = vScanConf.Ref;
		Else
			vScanConfRef = vExistingScanConf;	
		EndIf;
		
		vNewRow 					= Object.ScanConfigurations.Add();
		vNewRow.ScanConfiguration 	= vScanConfRef;
	EndIf;      
EndProcedure // RegulaCreateScanConfigurations

// -----------------------------------------------------------------------------
&AtClient
Procedure SetVisible()
	If Object.ImageScannerDriver = PredefinedValue("Enum.ImageScannerDrivers.CognitiveScanifyAPI") Then
		Items.SetScanConfigurationsGroup.Enabled = False;
		Items.TwainDeviceName.Enabled = True;
		Items.ScanComponentInstallationPath.Enabled = True;
		Items.ScanContextFile.Enabled = True;
		Items.PaperSize.Enabled = False;
		Items.ColorDepth.Enabled = False;
		Items.Rotation.Enabled = False;
		Items.AutoRecognition.Enabled = True;
		Items.InteractionParameters.Enabled = False;
	ElsIf Object.ImageScannerDriver = PredefinedValue("Enum.ImageScannerDrivers.Scan1C") Or Object.ImageScannerDriver = PredefinedValue("Enum.ImageScannerDrivers.SmartPassportBoxEngineREST") Then 
		Items.SetScanConfigurationsGroup.Enabled = False;
		Items.TwainDeviceName.Enabled = True;
		Items.ScanComponentInstallationPath.Enabled = False;
		Items.ScanContextFile.Enabled = False;
		Items.PaperSize.Enabled = True;
		Items.ColorDepth.Enabled = True;
		Items.Rotation.Enabled = True;
		Items.AutoRecognition.Enabled = False;
		Items.InteractionParameters.Enabled = True;
		If Object.AutoRecognition Then
			Object.AutoRecognition = False;
		EndIf;
	ElsIf Object.ImageScannerDriver = PredefinedValue("Enum.ImageScannerDrivers.AbbyyPassportReaderSDKEngine") Then 
		Items.SetScanConfigurationsGroup.Enabled = False;
		Items.TwainDeviceName.Enabled = True;
		Items.ScanComponentInstallationPath.Enabled = True;
		Items.ScanContextFile.Enabled = False;
		Items.PaperSize.Enabled = True;
		Items.ColorDepth.Enabled = True;
		Items.Rotation.Enabled = True;
		Items.AutoRecognition.Enabled = True;
		Items.InteractionParameters.Enabled = False;
	ElsIf Object.ImageScannerDriver = PredefinedValue("Enum.ImageScannerDrivers.ContentAIPassportReaderSDKEngine") Then 
		Items.SetScanConfigurationsGroup.Enabled = False;
		Items.TwainDeviceName.Enabled = True;
		Items.ScanComponentInstallationPath.Enabled = True;
		Items.ScanContextFile.Enabled = False;
		Items.PaperSize.Enabled = True;
		Items.ColorDepth.Enabled = True;
		Items.Rotation.Enabled = True;
		Items.AutoRecognition.Enabled = True;
		Items.InteractionParameters.Enabled = False;
	ElsIf Object.ImageScannerDriver = PredefinedValue("Enum.ImageScannerDrivers.SmartPassportBoxEngine") Then 
		Items.SetScanConfigurationsGroup.Enabled = False;
		Items.TwainDeviceName.Enabled = False;
		Items.ScanComponentInstallationPath.Enabled = True;
		Items.ScanContextFile.Enabled = False;
		Items.PaperSize.Enabled = False;
		Items.ColorDepth.Enabled = False;
		Items.Rotation.Enabled = False;
		Items.AutoRecognition.Enabled = True;
		Items.TwainDeviceName.Enabled = False;
		Items.InteractionParameters.Enabled = False;
	ElsIf Object.ImageScannerDriver = PredefinedValue("Enum.ImageScannerDrivers.Regula") Then
		Items.SetScanConfigurationsGroup.Enabled = True;
		Items.TwainDeviceName.Enabled = False;
		Items.ScanComponentInstallationPath.Enabled = False;
		Items.ScanContextFile.Enabled = False;
		Items.PaperSize.Enabled = False;
		Items.ColorDepth.Enabled = False;
		Items.Rotation.Enabled = False;
		Items.AutoRecognition.Enabled = True;
		Items.InteractionParameters.Enabled = False;
	Else   
		Items.SetScanConfigurationsGroup.Enabled = False;
		Items.TwainDeviceName.Enabled = False;
		Items.ScanComponentInstallationPath.Enabled = False;
		Items.ScanContextFile.Enabled = False;
		Items.PaperSize.Enabled = False;
		Items.ColorDepth.Enabled = False;
		Items.Rotation.Enabled = False;
		Items.AutoRecognition.Enabled = True;
		Items.InteractionParameters.Enabled = False;
	EndIf;
EndProcedure	

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveFilePathStartChoice_AfterInput(pValue, pParameters) Export
	If pValue = Undefined Then
		Return;
	EndIf;
	Object.ScanComponentInstallationPath = pValue[0];	
EndProcedure

#EndRegion
