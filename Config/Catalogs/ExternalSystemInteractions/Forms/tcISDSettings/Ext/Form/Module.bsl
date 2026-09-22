
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnReadAtServer(CurrentObject)
	LoadWorkstationsTable();
	LoadMappingTariffs();
	LoadMappingPermissionGroups();  
	LoadPermissionGroupsSetMapping();
	LoadSkiPassTable(); 
	LoadBonusRatesTable();
	LoadBonusesCardTypesTable();
	GetISDTariffs(); 
	
	Items.EarlyCheckInRoomRates.Enabled = UseAccommodationRules = False;
	If UseAccommodationRules Then
		Items.GroupUseAccommodationRules.BackColor = tcCommonFunctionOnClientServer.ColorConstructor(251, 212, 212);  
	Else
		Items.GroupUseAccommodationRules.BackColor = tcCommonFunctionOnClientServer.ColorConstructor();
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure OnWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	SaveWorkstationsTable();
	SaveTariffs();
	SaveSkiPass();   
	SaveBonusesCardTypesTable();
	SaveBonusRatesTable();
	SaveMappingPermissionGroups(); 
	SavePermissionGroupsSetMapping();
EndProcedure // OnWriteAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure UseAccommodationRulesOnChange(Item)
	Items.EarlyCheckInRoomRates.Enabled = UseAccommodationRules = False;
	If UseAccommodationRules = False Then
		Items.GroupUseAccommodationRules.BackColor = tcCommonFunctionOnClientServer.ColorConstructor();  
	Else
		Items.GroupUseAccommodationRules.BackColor = tcCommonFunctionOnClientServer.ColorConstructor(251, 212, 212);
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomRatesISDDescriptionChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	If Not pSelectedValue = Undefined Then
		pStandardProcessing = False;
		vRow = Items.RoomRates.CurrentData;
		If Not vRow = Undefined Then
			vRow.ISDCode = pSelectedValue.RoomRatesISDCode;
			vRow.ISDDescription = pSelectedValue.RoomRatesISDDescription;
		EndIf;	
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomRatesISDParkingDescriptionChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	If Not pSelectedValue = Undefined Then
		pStandardProcessing = False;
		vRow = Items.RoomRates.CurrentData;
		If Not vRow = Undefined Then
			vRow.ISDParkingCode = pSelectedValue.ParkingISDCode;
			vRow.ISDParkingDescription = pSelectedValue.ParkingISDDescription;
		EndIf;	
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure EarlyCheckInRoomRatesISDDescriptionChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	If Not pSelectedValue = Undefined Then
		pStandardProcessing = False;
		vRow = Items.EarlyCheckInRoomRates.CurrentData;
		If Not vRow = Undefined Then
			vRow.ISDCode = pSelectedValue.RoomRatesISDCode;
			vRow.ISDDescription = pSelectedValue.RoomRatesISDDescription;
		EndIf;	
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure EarlyCheckInRoomRatesISDParkingDescriptionChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	If Not pSelectedValue = Undefined Then
		pStandardProcessing = False;
		vRow = Items.EarlyCheckInRoomRates.CurrentData;
		If Not vRow = Undefined Then
			vRow.ISDParkingCode = pSelectedValue.ParkingISDCode;
			vRow.ISDParkingDescription = pSelectedValue.ParkingISDDescription;
		EndIf;	
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure GetTariffs(Command)
	GetTariffsFromExtSystem(Object.Ref);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure GetParkingTariffs(Command)
	GetParkingTariffsAtServer(Object.Ref);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure Save(Command)
	SaveWorkstationsTable();
	SaveTariffs();
	SaveSkiPass();
	SaveMappingPermissionGroups();
EndProcedure // Save

#EndRegion 

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure LoadWorkstationsTable()
	vWorkstations = InformationRegisters.ExternalSystemIntegrationData.GetDataList(Object.Ref, "Workstation", "ID");
	If vWorkstations.Count() > 0 Then			
		For each vWorkstationsRow In vWorkstations Do
			vNewRow = Workstations.Add();
			vNewRow.Workstation = vWorkstationsRow.RefKey1;
			vNewRow.ISDWorkstationID = vWorkstationsRow.ExternalSystemDataCode;
		EndDo;
	EndIf;
EndProcedure // LoadWorkstationsTable

// --------------------------------------------------------------------------------
&AtServer
Procedure LoadMappingTariffs()
	// For accommodations
	vTariffs = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.Ref, "Tariffs");
	For Each vRow In vTariffs Do
		vNewRow = RoomRates.Add();   
		vCardType = Undefined;
		If Not IsBlankString(vRow.CardType) Then
			vCardType = Catalogs.IdentificationCardTypes.GetRef(New UUID(vRow.CardType));	
		EndIf;	
		vNewRow.RoomRate 		= vRow.RoomRate;
		vNewRow.UUID 			= vRow.RefKey1;
		vNewRow.CardType 		= vCardType;
		vNewRow.Hotel 			= vRow.Hotel;
		vNewRow.ISDCode 		= vRow.ISDCode;
		vNewRow.ISDDescription 	= vRow.ISDDescription;
		vNewRow.ISDParkingCode 	= vRow.ISDParkingCode;
		vNewRow.ISDParkingDescription = vRow.ISDParkingDescription;
		If Not IsBlankString(vRow.Packages) Then
			vPackages = StrSplit(vRow.Packages, "_", True);
			For Each vPkg In vPackages Do
				vNewRow.Packages.Add(Catalogs.ServicePackages.GetRef(New UUID(vPkg)), , True);
			EndDo;
		EndIf;
		RoomRates.Sort("ISDDescription, RoomRate");
	EndDo;  
	// Fill packages codes
	For Each vRow In RoomRates Do 
		vPackages = vRow.Packages;
		vRow.Codes = GetCodesAsString(vPackages); 
	EndDo;
	// For reservations
	vTariffs = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.Ref, "EarlyCheckInRoomRates");
	For Each vRow In vTariffs Do    
		If Not ValueIsFilled(vRow.CardType) Then
			Continue;
		EndIf;	 
		vCardType = Undefined;
		If Not IsBlankString(vRow.CardType) Then
			vCardType = Catalogs.IdentificationCardTypes.GetRef(New UUID(vRow.CardType));	
		EndIf;
		vNewRow = EarlyCheckInRoomRates.Add();
		vNewRow.RoomRate 		= vRow.RoomRate;
		vNewRow.UUID 			= vRow.RefKey1;
		vNewRow.CardType 		= vCardType;
		vNewRow.Hotel 			= vRow.Hotel;
		vNewRow.ISDCode 		= vRow.ISDCode;
		vNewRow.ISDDescription 	= vRow.ISDDescription;
		vNewRow.ISDParkingCode 	= vRow.ISDParkingCode;
		vNewRow.ISDParkingDescription = vRow.ISDParkingDescription;
		vNewRow.IsDefault = vRow.IsDefault;
		If Not IsBlankString(vRow.Packages) Then
			vPackages = StrSplit(vRow.Packages, "_", True);
			For Each vPkg In vPackages Do
				vNewRow.Packages.Add(Catalogs.ServicePackages.GetRef(New UUID(vPkg)), , True);
			EndDo;
		EndIf;
		EarlyCheckInRoomRates.Sort("ISDDescription, RoomRate");
	EndDo;   
	// Fill packages codes
	For Each vRow In EarlyCheckInRoomRates Do  
		vPackages = vRow.Packages;
		vRow.Codes = GetCodesAsString(vPackages);
	EndDo;
	
	vUseAccommodationRules = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.Ref, "EarlyCheckInRoomRates", "UseAccommodationRules");
	If vUseAccommodationRules.Count() > 0 Then
		UseAccommodationRules = vUseAccommodationRules[0].UseAccommodationRules;
	EndIf;
EndProcedure

&AtServer
Function GetCodesAsString(Val vPackages)
	vCodes = New Array;   
	For Each vPkgRow In vPackages Do
		If ValueIsFilled(vPkgRow.Value) Then   
			vCode = TrimAll(vPkgRow.Value.Code);
			If vCodes.Find(vCode) = Undefined Then
				vCodes.Add(vCode);
			EndIf;	
		EndIf;	
	EndDo;  
	vPres = StrConcat(vCodes, ";");
	Return vPres;
EndFunction // LoadTariffs

// --------------------------------------------------------------------------------
&AtServer
Procedure LoadMappingPermissionGroups()
	vPermissionGroups = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.Ref, "PermissionGroups");
	For Each vRow In vPermissionGroups Do
		PermissionGroupsPrintLateCheckOut.Add().PermissionGroup	= vRow.RefKey1;
	EndDo;
EndProcedure // LoadMappingPermissionGroups

// --------------------------------------------------------------------------------
&AtServer
Procedure LoadPermissionGroupsSetMapping()
	vPermissionGroups = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.Ref, "PermissionGroupsSetMapping");
	For Each vRow In vPermissionGroups Do
		PermissionGroupsSetMapping.Add().PermissionGroup = vRow.RefKey1;
	EndDo;
EndProcedure // LoadPermissionGroupsSetMapping      

// --------------------------------------------------------------------------------
&AtServer
Procedure LoadSkiPassTable()    
	vExtType = "SkiPass";
	vSkiPassTable = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.Ref, vExtType);
	For Each vRow In vSkiPassTable Do
		vService =  Undefined;  
		If Not IsBlankString(vRow.Service) Then
			 vService = Catalogs.Services.GetRef(New UUID(vRow.Service));
		 EndIf;
		 vCardType = Undefined;
		 If Not IsBlankString(vRow.CardType) Then
			 vCardType = Catalogs.IdentificationCardTypes.GetRef(New UUID(vRow.CardType));	
		 EndIf;
		If ValueIsFilled(vService) Then
			vNewRow = SkiPass.Add();
			vNewRow.Service 		= vService;
			vNewRow.UUID 			= vRow.RefKey1;
			vNewRow.CardType 		= vCardType;
			vNewRow.Hotel 			= vRow.Hotel;
			vNewRow.ISDCode 		= vRow.ISDCode;
			vNewRow.ISDDescription 	= vRow.ISDDescription;
			vNewRow.WithCardOnly 	= vRow.WithCardOnly;
			vNewRow.IsBarCode 		= vRow.IsBarCode;
			vNewRow.ISDCodeAdditional = vRow.ISDCodeAdditional;
			vNewRow.ISDAddDescription = vRow.ISDAddDescription;
		EndIf;
	EndDo;
	SkiPass.Sort("ISDDescription, Service");
	vSkiPassTableCards = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.Ref, vExtType, "CardService");
	If vSkiPassTableCards.Count() > 0 Then
		CardService = ?(IsBlankString(vSkiPassTableCards[0].CardService), Undefined, Catalogs.Services.GetRef(New UUID(vSkiPassTableCards[0].CardService)));
	EndIf;
	vSkiPassTableCards = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.Ref, vExtType, "GroupService");
	If vSkiPassTableCards.Count() > 0 Then
		GroupService = ?(IsBlankString(vSkiPassTableCards[0].GroupService), Undefined, Catalogs.Services.GetRef(New UUID(vSkiPassTableCards[0].GroupService)));
	EndIf;
EndProcedure // LoadSkiPassTable

// --------------------------------------------------------------------------------
&AtServer
Procedure LoadBonusesCardTypesTable()
	vBonusesCardTypesTable = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.Ref, "BonusesCardTypes");
	For Each vRow In vBonusesCardTypesTable Do
		vNewRow = BonusesCardTypes.Add();   
		vNewRow.UUID 			= vRow.RefKey1;
		vNewRow.DiscountType 	= ?(IsBlankString(vRow.DiscountType), Undefined, Catalogs.DiscountTypes.GetRef(New UUID(vRow.DiscountType)));
		vNewRow.Hotel 			= vRow.Hotel;
		vNewRow.ISDCode 		= vRow.ISDCode;
		vNewRow.ISDDescription 	= vRow.ISDDescription;
	EndDo;
EndProcedure // LoadBonusesCardTypesTable

// --------------------------------------------------------------------------------
&AtServer
Procedure LoadBonusRatesTable()
	vBonusRatesTable = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.Ref, "BonusRates");
	For Each vRow In vBonusRatesTable Do
		vNewRow = BonusRates.Add(); 
		vNewRow.UUID 			= vRow.RefKey1;
		vNewRow.IsDefault 		= vRow.IsDefault;
		vNewRow.Hotel 			= vRow.Hotel;
		vNewRow.ISDCode 		= vRow.ISDCode;   
		vNewRow.ISDCodeOld 		= vRow.ISDCodeOld;
		vNewRow.ISDDescription 	= vRow.ISDDescription;
	EndDo; 
	vCardTemplates = InformationRegisters.ExternalSystemIntegrationData.GetData(Object.Ref, "CardTemplate");
	If vCardTemplates.Count() > 0 Then
		CardTemplate = vCardTemplates[0].CardTemplate;  
		CardTemplateBeginNumber = vCardTemplates[0].CardTemplateBeginNumber;  
	EndIf;
EndProcedure // LoadBonusRatesTable

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveWorkstationsTable()
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.Ref, "Workstation");
	For each vWorkstationsRow In Workstations Do
		If ValueIsFilled(vWorkstationsRow.Workstation) Then
			InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, "Workstation", "ID", vWorkstationsRow.Workstation, Undefined, Undefined, TrimAll(vWorkstationsRow.ISDWorkstationID));
		EndIf;
	EndDo;
EndProcedure // SaveWorkstationsTable

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveTariffs()
	// For accommodations  
	vTariffType = "Tariffs";
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.Ref, vTariffType);
	For Each vRow In RoomRates Do
		vUUID = vRow.UUID;
		If IsBlankString(vUUID) Then
			vUUID = String(New UUID());
		EndIf;
		vRow.Packages.SortByValue();
		vPackagesHash = "";
		For Each vRowPack In vRow.Packages Do
			If IsBlankString(vPackagesHash) Then
				vPackagesHash = XMLString(vRowPack.Value);
			Else	
				vPackagesHash = vPackagesHash + "_" + XMLString(vRowPack.Value);
			EndIf;
		EndDo; 
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vTariffType, "RoomRate", vUUID , Undefined, vRow.RoomRate);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vTariffType, "Packages", vUUID, Undefined, vPackagesHash);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vTariffType, "CardType", vUUID, Undefined, XMLString(vRow.CardType));
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vTariffType, "ISDCode",  vUUID, Undefined, vRow.ISDCode);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vTariffType, "ISDDescription",  vUUID, Undefined, vRow.ISDDescription);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vTariffType, "Hotel",  vUUID, Undefined, vRow.Hotel);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vTariffType, "ISDParkingCode",  vUUID, Undefined, vRow.ISDParkingCode);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vTariffType, "ISDParkingDescription",  vUUID, Undefined, vRow.ISDParkingDescription);
	EndDo;   
	vERRType = "EarlyCheckInRoomRates";
	// For reservations
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.Ref, vERRType);
	For Each vRow In EarlyCheckInRoomRates Do
		vUUID = vRow.UUID;
		If IsBlankString(vUUID) Then
			vUUID = String(New UUID());
		EndIf;
		vRow.Packages.SortByValue();
		vPackagesHash = "";
		For Each vRowPack In vRow.Packages Do
			If IsBlankString(vPackagesHash) Then
				vPackagesHash = XMLString(vRowPack.Value);
			Else	
				vPackagesHash = vPackagesHash + "_" + XMLString(vRowPack.Value);
			EndIf;
		EndDo;     
		
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vERRType, "RoomRate", vUUID , Undefined, vRow.RoomRate);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vERRType, "Packages", vUUID, Undefined, vPackagesHash);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vERRType, "CardType", vUUID, Undefined, XMLString(vRow.CardType));
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vERRType, "ISDCode",  vUUID, Undefined, vRow.ISDCode);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vERRType, "ISDDescription",  vUUID, Undefined, vRow.ISDDescription);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vERRType, "Hotel",  vUUID, Undefined, vRow.Hotel);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vERRType, "ISDParkingCode",  vUUID, Undefined, vRow.ISDParkingCode);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vERRType, "ISDParkingDescription",  vUUID, Undefined, vRow.ISDParkingDescription);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vERRType, "IsDefault",  vUUID, Undefined, vRow.IsDefault);
	EndDo;
	
	InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vERRType, "UseAccommodationRules",  String(New UUID()), Undefined, UseAccommodationRules);
	
EndProcedure // SaveTariffs

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveSkiPass()
	// For accommodations 
	vSkiPassType = "SkiPass";
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.Ref, vSkiPassType);
	For Each vRow In SkiPass Do
		If Not ValueIsFilled(vRow.Service) Then
			Continue;
		EndIf;	
		vUUID = vRow.UUID;
		If IsBlankString(vUUID) Then
			vUUID = String(New UUID());
		EndIf;
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vSkiPassType, "Service", 		  vUUID, Undefined, XMLString(vRow.Service));
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vSkiPassType, "CardType", 	  vUUID, Undefined, XMLString(vRow.CardType));
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vSkiPassType, "ISDCode",  	  vUUID, Undefined, vRow.ISDCode);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vSkiPassType, "ISDDescription", vUUID, Undefined, vRow.ISDDescription);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vSkiPassType, "ISDCodeAdditional", vUUID, Undefined, vRow.ISDCodeAdditional);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vSkiPassType, "ISDAddDescription", vUUID, Undefined, vRow.ISDAddDescription);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vSkiPassType, "Hotel",  		  vUUID, Undefined, vRow.Hotel);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vSkiPassType, "WithCardOnly",   vUUID, Undefined, vRow.WithCardOnly);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vSkiPassType, "IsBarCode",   	  vUUID, Undefined, vRow.IsBarCode);
	EndDo;
	If ValueIsFilled(CardService) Then
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vSkiPassType, "CardService",  String(New UUID()), Undefined, XMLString(CardService));
	EndIf;
	If ValueIsFilled(GroupService) Then
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vSkiPassType, "GroupService",  String(New UUID()), Undefined, XMLString(GroupService));
	EndIf;
EndProcedure // SaveSkiPass

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveBonusesCardTypesTable()   
	vBonusesCardType = "BonusesCardTypes";
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.Ref, vBonusesCardType);
	For Each vRow In BonusesCardTypes Do
		If Not ValueIsFilled(vRow.ISDCode) Then
			Continue;
		EndIf;	
		vUUID = vRow.UUID;
		If IsBlankString(vUUID) Then
			vUUID = String(New UUID());
		EndIf;
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vBonusesCardType, "DiscountType",   vUUID, Undefined, XMLString(vRow.DiscountType));
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vBonusesCardType, "ISDCode",  	   vUUID, Undefined, vRow.ISDCode);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vBonusesCardType, "ISDDescription", vUUID, Undefined, vRow.ISDDescription);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vBonusesCardType, "Hotel",  		   vUUID, Undefined, vRow.Hotel);
	EndDo; 
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.Ref, "CardTemplate"); 
	vUUID = String(New UUID());
	InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, "CardTemplate", "CardTemplate", vUUID, Undefined, TrimAll(CardTemplate));
	InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, "CardTemplate", "CardTemplateBeginNumber", vUUID, Undefined, CardTemplateBeginNumber);
EndProcedure // SaveBonusesCardTypesTable

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveBonusRatesTable() 
	vBonusRateType = "BonusRates";
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.Ref, vBonusRateType);
	For Each vRow In BonusRates Do
		If Not ValueIsFilled(vRow.ISDCode) Then
			Continue;
		EndIf;	
		vUUID = vRow.UUID;
		If IsBlankString(vUUID) Then
			vUUID = String(New UUID());
		EndIf;
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vBonusRateType, "IsDefault",   	 vUUID, Undefined, vRow.IsDefault);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vBonusRateType, "ISDCode",  	     vUUID, Undefined, vRow.ISDCode);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vBonusRateType, "ISDCodeOld",  	 vUUID, Undefined, vRow.ISDCodeOld);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vBonusRateType, "ISDDescription", vUUID, Undefined, vRow.ISDDescription);
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, vBonusRateType, "Hotel",  		 vUUID, Undefined, vRow.Hotel);
	EndDo;
EndProcedure // SaveBonusRatesTable

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveMappingPermissionGroups()
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.Ref, "PermissionGroups");
	For Each vRow In PermissionGroupsPrintLateCheckOut Do
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, "PermissionGroups", "PermissionGroup", vRow.PermissionGroup , Undefined, vRow.PermissionGroup);
	EndDo;
EndProcedure // SaveMappingPermissionGroups  

// --------------------------------------------------------------------------------
&AtServer
Procedure SavePermissionGroupsSetMapping()
	InformationRegisters.ExternalSystemIntegrationData.ClearDataByExternalSystemAndDataType(Object.Ref, "PermissionGroupsSetMapping");
	For Each vRow In PermissionGroupsSetMapping Do
		InformationRegisters.ExternalSystemIntegrationData.WriteData(Object.Ref, "PermissionGroupsSetMapping", "PermissionGroupsSetMapping", vRow.PermissionGroup , Undefined, vRow.PermissionGroup);
	EndDo;
EndProcedure // SavePermissionGroupsSetMapping

// --------------------------------------------------------------------------------
&AtServer
Procedure GetTariffsFromExtSystem(pInteraction)
	If ValueIsFilled(Object.Ref) Then
		vRes = ISD.GetTariffs(Object.Ref);
		If vRes.Success = True Then
			vListTariffs = vRes.MapResponse.get("tariffs");
			For Each vIdRow In vListTariffs Do
				vId = Format(vIdRow[0], "NG=");
				If RoomRates.FindRows(New Structure("ISDCode", String(vId))).Count() = 0 Then 
					vNewRow = RoomRates.Add();
					vNewRow.ISDCode = vId;
					vNewRow.ISDDescription = vIdRow[1];
				EndIf;	
			EndDo;
		Else
			tcCommonFunctionOnClientServer.TextMessage(vRes.StatusDescription);
		EndIf;	
	Else
		tcCommonFunctionOnClientServer.TextMessage(Nstr("en = 'You must first write the integration'; de = 'Sie müssen zuerst die Integration schreiben'; ru = 'Необходимо сначала записать интеграцию'"));
	EndIf;
EndProcedure // GetTariffsFromExtSystem

// --------------------------------------------------------------------------------
&AtServer
Procedure GetParkingTariffsAtServer(pInteraction)
	If ValueIsFilled(Object.Ref) Then
		vRes = ISD.getParking(Object.Ref);
		If vRes.Success = True Then
			vListTariffs = vRes.MapResponse.get("tariffs");
			For Each vIdRow In vListTariffs Do
				vId = Format(vIdRow["tariff_id"], "NZ=0; NG=");
				vISDParkingDescription = TrimAll(vIdRow["descr"]);
				If RoomRates.FindRows(New Structure("ISDParkingCode", String(vId))).Count() = 0 Then 
					vNewRow = RoomRates.Add();
					vNewRow.ISDParkingDescription = vISDParkingDescription;
					vNewRow.ISDParkingCode = vId;
				EndIf;	
			EndDo;
		Else
			tcCommonFunctionOnClientServer.TextMessage(vRes.StatusDescription);
		EndIf;	
	Else
		tcCommonFunctionOnClientServer.TextMessage(Nstr("en = 'You must first write the integration'; de = 'Sie müssen zuerst die Integration schreiben'; ru = 'Необходимо сначала записать интеграцию'"));
	EndIf;
EndProcedure // GetParkingTariffsAtServer

// --------------------------------------------------------------------------------
&AtServerNoContext
Function RoomRatesPackagesStartChoiceAtServer(pRoomRate, pCardType)
	vList = New ValueList;
	// Check card type
	vCardType = pCardType;
	If Not ValueIsFilled(vCardType) And ValueIsFilled(pRoomRate.IdentificationCardType) Then
		vCardType = pRoomRate.IdentificationCardType;
	EndIf;
	// Get service packages
	If ValueIsFilled(vCardType) Then
		Query = New Query;
		Query.Text = 
		"SELECT DISTINCT
		|	ServicePackages.Ref AS Ref
		|FROM
		|	Catalog.ServicePackages AS ServicePackages
		|WHERE
		|	ServicePackages.IdentificationCardType = &qIdentificationCardType
		|	AND Not ServicePackages.DeletionMark";
		
		Query.SetParameter("qIdentificationCardType", vCardType);
		
		vQueryResult = Query.Execute().Unload();
		
		vList.LoadValues(vQueryResult.UnloadColumn("Ref"));
	EndIf;	
	
	Return vList;
EndFunction // RoomRatesPackagesStartChoiceAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomRatesPackagesStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vCurRow = Items.RoomRates.CurrentData;
	vCurrPackages = vCurRow.Packages;
	// All packages by card type
	vAllListPackages = RoomRatesPackagesStartChoiceAtServer(vCurRow.RoomRate, vCurRow.CardType);
	For Each vRow In vCurrPackages Do
		vCurRowInList = vAllListPackages.FindByValue(vRow.Value);
		If vCurRowInList  = Undefined Then
			vAllListPackages.Add(vRow.Value, , vRow.Check);
		Else
			vCurRowInList.Check  = True;
		EndIf;	
	EndDo;  
	For Each vRow In vAllListPackages Do
		If ValueIsFilled(vRow.Value) Then
			vDesc = TrimAll(tcOnServer.cmGetAttributeByRef(vRow.Value, "Code")) +", " + TrimAll(vRow.Value) +", " + TrimAll(tcOnServer.cmGetAttributeByRef(vRow.Value, "Hotel"));	
			vRow.Presentation = vDesc;
		EndIf;	
	EndDo;	
	If vAllListPackages.Count() > 0 Then
		vNotifyDescription = New NotifyDescription("RoomRatesPackagesStartChoiceEnd", ThisObject);
		vAllListPackages.ShowCheckItems(vNotifyDescription, NStr("en = 'Select packages ...'; de = 'Pakete auswählen ...'; ru = 'Выберите пакеты...'"));
	Else
		vMsg = NStr("en = 'There are no packages to choose from, please indicate the type of card for which there are packages'; 
		|de = 'Es stehen keine Pakete zur Auswahl. Bitte geben Sie den Kartentyp an, für den es Pakete gibt'; 
		|ru = 'Нет пакетов для выбора, укажите тип карты, для которого есть пакеты'");
		
		Message = New UserMessage;
		Message.Text = vMsg;
		Message.Field = "RoomRates[" + RoomRates.IndexOf(vCurRow) + "].CardType";
		Message.Message();
	EndIf;
EndProcedure // RoomRatesPackagesStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure EarlyCheckInRoomRatesPackagesStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vCurRow = Items.EarlyCheckInRoomRates.CurrentData;
	vCurrPackages = vCurRow.Packages;
	// All packages by card type
	vAllListPackages = RoomRatesPackagesStartChoiceAtServer(vCurRow.RoomRate, vCurRow.CardType);
	For Each vRow In vCurrPackages Do
		vCurRowInList = vAllListPackages.FindByValue(vRow.Value);
		If vCurRowInList  = Undefined Then
			vAllListPackages.Add(vRow.Value, , vRow.Check);
		Else
			vCurRowInList.Check  = True;
		EndIf;	
	EndDo; 
	If vAllListPackages.Count() > 0 Then
		vNotifyDescription = New NotifyDescription("EarlyCheckInRoomRatesPackagesStartChoiceEnd", ThisObject);
		vAllListPackages.ShowCheckItems(vNotifyDescription, NStr("en = 'Select packages ...'; de = 'Pakete auswählen ...'; ru = 'Выберите пакеты...'"));
	Else
		vMsg = NStr("en = 'There are no packages to choose from, please indicate the type of card for which there are packages'; 
		|de = 'Es stehen keine Pakete zur Auswahl. Bitte geben Sie den Kartentyp an, für den es Pakete gibt'; 
		|ru = 'Нет пакетов для выбора, укажите тип карты, для которого есть пакеты'");
		
		Message = New UserMessage;
		Message.Text = vMsg;
		Message.Field = "EarlyCheckInRoomRates[" + EarlyCheckInRoomRates.IndexOf(vCurRow) + "].CardType";
		Message.Message();
	EndIf;
	
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomRatesPackagesStartChoiceEnd(pList, pAdditionalParameters) Export
	// Save in row selected rows
	If Not pList = Undefined Then
		vPackages = Items.RoomRates.CurrentData.Packages;
		vPackages.Clear();
		For Each vRow In pList Do
			If vRow.Check Then
				vPackages.Add(vRow.Value, , vRow.Check);
			EndIf;
		EndDo;   
		Items.RoomRates.CurrentData.Codes = GetCodesAsString(vPackages);
	EndIf;
EndProcedure // RoomRatesPackagesStartChoiceEnd

// --------------------------------------------------------------------------------
&AtClient
Procedure EarlyCheckInRoomRatesPackagesStartChoiceEnd(pList, pAdditionalParameters) Export
	// Save in row selected rows
	If Not pList = Undefined Then
		vPackages = Items.EarlyCheckInRoomRates.CurrentData.Packages;
		vPackages.Clear();
		For Each vRow In pList Do
			If vRow.Check Then
				vPackages.Add(vRow.Value, , vRow.Check);
			EndIf;
		EndDo;   
		Items.EarlyCheckInRoomRates.CurrentData.Codes = GetCodesAsString(vPackages);
	EndIf;
EndProcedure // RoomRatesPackagesStartChoiceEnd

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomRatesOnStartEdit(pItem, pNewRow, pClone)
	If pNewRow Then
		vNewRow = Items.RoomRates.CurrentData;
		vNewRow.UUID = "";
		vNewRow.ISDCode = "";
		vNewRow.ISDDescription = "";
		vNewRow.ISDParkingCode = "";
		vNewRow.ISDParkingDescription = "";
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure GetISDTariffs()
	// Fill ISD room rates
	If ValueIsFilled(Object.Ref) Then
		vRes = ISD.GetTariffs(Object.Ref);
		If vRes.Success = True Then
			vListTariffs = vRes.MapResponse.get("tariffs");
			For Each vIdRow In vListTariffs Do
				vId = Format(vIdRow[0], "NZ=0; NG=");
				vRateDescr = TrimAll(vIdRow[1]);
				Items.RoomRatesISDDescription.ChoiceList.Add(New Structure("RoomRatesISDCode, RoomRatesISDDescription", vId, vRateDescr), vRateDescr);
				Items.EarlyCheckInRoomRatesISDDescription.ChoiceList.Add(New Structure("RoomRatesISDCode, RoomRatesISDDescription", vId, vRateDescr), vRateDescr);
			EndDo;
		Else
			tcCommonFunctionOnClientServer.TextMessage(vRes.StatusDescription);
		EndIf;	
	Else
		tcCommonFunctionOnClientServer.TextMessage(Nstr("en = 'You must first write the integration'; de = 'Sie müssen zuerst die Integration schreiben'; ru = 'Необходимо сначала записать интеграцию'"));
	EndIf;
	// Fill ISD parking tariffs
	If ValueIsFilled(Object.Ref) And vRes.Success = True Then
		vRes = ISD.getParking(Object.Ref);
		If vRes.Success = True Then
			vListTariffs = vRes.MapResponse.get("tariffs");
			For Each vIdRow In vListTariffs Do
				vId = Format(vIdRow["tariff_id"], "NZ=0; NG=");
				vISDParkingDescr = TrimAll(vIdRow["descr"]);
				Items.RoomRatesISDParkingDescription.ChoiceList.Add(New Structure("ParkingISDCode, ParkingISDDescription", vId, vISDParkingDescr), vISDParkingDescr);
				Items.EarlyCheckInRoomRatesISDParkingDescription.ChoiceList.Add(New Structure("ParkingISDCode, ParkingISDDescription", vId, vISDParkingDescr), vISDParkingDescr);
			EndDo;
		Else
			tcCommonFunctionOnClientServer.TextMessage(vRes.StatusDescription);
		EndIf;	
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure EarlyCheckInRoomRatesOnStartEdit(pItem, pNewRow, pClone)
	If pNewRow Then
		vNewRow = Items.EarlyCheckInRoomRates.CurrentData;
		vNewRow.UUID = "";
		vNewRow.ISDCode = "";
		vNewRow.ISDDescription = "";
		vNewRow.ISDParkingCode = "";
		vNewRow.ISDParkingDescription = "";
	EndIf;	
EndProcedure

#EndRegion
