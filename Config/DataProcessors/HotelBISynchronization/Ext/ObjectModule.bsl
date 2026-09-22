
#Region Public

// -----------------------------------------------------------------------------
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	If IsBlankString(HotelBIWebservicesAddress) Then
		HotelBIWebservicesAddress = "http://xxx.xxx.xxx.xxx/xxxxxx/ws/1CHotelBIDataExchangeInterfaces.1cws?wsdl";
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False, pSendLogs = False) Export
	// Check parameters
	If Not ValueIsFilled(Hotel) Then
		Raise NStr("en = 'Hotel is not filled!'; de = 'Hotel nicht gefüllt!'; ru = 'Не указана гостиница!'");
	EndIf;
	If IsBlankString(HotelBIWebservicesAddress) Then
		Raise NStr("en = '1C:Hotel BI system web-services address is not filled!'; de = '1C:Hotel BI-System web-services address nicht gefüllt!'; ru = 'Не указан адрес подключения к web-службам системы 1С:Отель BI!'");
	EndIf;
	
	// Get period to export data from
	vCurrentSyncDate = CurrentSessionDate();
	vLastSyncDate = '00010101';
	If Not ValueIsFilled(FullSyncStartDate) Then
		FullSyncStartDate = '20100101';
	EndIf;
	If FullSync Then
		vLastSyncDate = FullSyncStartDate;
		SendLogs(NStr("en = 'Data exchange start...'; de = 'Datenaustausch starten...'; ru = 'Начинаем полную синхронизацию данных...'"), pSendLogs);
	Else
		vLastSyncDate = LastSyncDate;
		SendLogs(NStr("en='Data exchange start from " + vLastSyncDate + "...'; ru='Начинаем синхронизацию данных с " + vLastSyncDate + " числа...'; de='Datenaustausch starten von " + vLastSyncDate + "...'"), pSendLogs);
	EndIf;
	If Not ValueIsFilled(vLastSyncDate) Then
		vLastSyncDate = FullSyncStartDate;
	EndIf;
	
	// Connection
	If Not IsBlankString(User) Then
		vHotelBIWSDef = New WSDefinitions(StrReplace(TrimAll(HotelBIWebservicesAddress), "\", "/"), User, Password);
		vHotelBIProxy = New WSProxy(vHotelBIWSDef, "http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "DataExchangeInterfaces", "DataExchangeInterfacesSoap", , 300);
		vHotelBIProxy.User = User;
		vHotelBIProxy.Password = Password;
	Else
		vHotelBIWSDef = New WSDefinitions(StrReplace(TrimAll(HotelBIWebservicesAddress), "\", "/"));
		vHotelBIProxy = New WSProxy(vHotelBIWSDef, "http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "DataExchangeInterfaces", "DataExchangeInterfacesSoap", , 300);
	EndIf;
	
	// Start data exchange
	vHotelBIProxy.DataExchangeStart(TrimAll(Hotel.Code));
	
	Try
		If Not SyncDealsOnly Then
			// Send catalogs
			SendLogs(NStr("en = 'Exporting catalogs...'; de = 'Kataloge exportieren...'; ru = 'Выгружаем каталоги...'"), pSendLogs);
			SendCatalogs(vHotelBIProxy, pSendLogs);
				
			// Get changes from 1C:Hotel BI
			vNewItems     = New Structure("NewClients, NewCustomers, NewDiscountCards", New ValueList, New ValueList, New ValueList);
			vChangedItems = New Structure("ChangedClients, ChangedCustomers, ChangedDiscountCards", New ValueList, New ValueList, New ValueList);
			
			If Not OnlyExport Then	
				// Get client types
				SendLogs(NStr("en = 'Get client information types from BI...'; de = 'Client-Informationstypen von BI abrufen...'; ru = 'Получаем типы информации по клиентам из BI...'"), pSendLogs);
				GetClientInformationTypesFromBI(vHotelBIProxy,?(FullSync, '00010101', vLastSyncDate));
				
				// Get new items created in other hotels
				SendLogs(NStr("en = 'Get new items from BI...'; de = 'Ausholen neue Elemente aus BI...'; ru = 'Получаем новые данные из BI...'"), pSendLogs);
				GetNewItems(vHotelBIProxy, vNewItems);
				
				If Not FullSync And ValueIsFilled(LastSyncDate) Then
					// Get changed items
					SendLogs(NStr("en = 'Get changed items from BI...'; de = 'Erhalten geänderte Artikel von BI...'; ru = 'Получаем измененные данные из BI...'"), pSendLogs);
					GetChangedItems(vHotelBIProxy, vLastSyncDate, vCurrentSyncDate, vChangedItems);
					// Get merged items
					SendLogs(NStr("en='Merge identical items...'; ru='Начинаем объединять одинаковые карточки...'; de='Gleiche Artikel zusammenfügen...'"), pSendLogs);
					GetMergedItems(vHotelBIProxy, vLastSyncDate, vCurrentSyncDate);
				EndIf;
			EndIf;

			// Send sales
			vLastDateInSales = GetLastDateInSales();
			If TypeOf(vLastDateInSales) = Type("Date") Then
				If BegOfDay(vLastDateInSales) > BegOfDay(vCurrentSyncDate) Then	
					SendSales(vHotelBIProxy, vLastSyncDate, vLastDateInSales, vCurrentSyncDate, vNewItems, vChangedItems);
				Else
					SendSales(vHotelBIProxy, vLastSyncDate, vCurrentSyncDate, vCurrentSyncDate, vNewItems, vChangedItems);
				EndIf;
			EndIf;
			
			// Get client informations
			SendLogs(NStr("en='Get client extra information...'; ru='Получаем информацию по клиентам...'; de='Erhalten zusätzliche Informationen für den Kunden...'"), pSendLogs);
			GetClientInformationsFromBI(vHotelBIProxy, vLastSyncDate);		
			
			// Send client informations
			SendLogs(NStr("en='Export client extra information...'; ru='Выгружаем информацию по клиентам...'; de='Exportieren Sie zusätzliche Informationen...'"), pSendLogs);
			SendClientInformation(vHotelBIProxy, vLastSyncDate);
			// Sync deals
			If SyncDeals Then
				SendLogs(NStr("en = 'Export deals information...'; de = 'Exportinformationen ...'; ru = 'Выгружаем информацию по сделкам...'"), pSendLogs);
				SendDeals(vHotelBIProxy, vLastSyncDate);
			EndIf;	
		Else
			// Sync only deals
			SendLogs(NStr("en = 'Export deals information...'; de = 'Exportinformationen ...'; ru = 'Выгружаем информацию по сделкам...'"), pSendLogs);
			SendDeals(vHotelBIProxy, vLastSyncDate);
		EndIf;
		// Stop data exchange
		vHotelBIProxy.DataExchangeEnd(TrimAll(Hotel.Code), True, "");
		
		// Save data processor settings
		LastSyncDate = vCurrentSyncDate;
		pmSaveDataProcessorAttributes();
		SendLogs(NStr("en='Data exchange end'; ru='Завершение обмена'; de='Datenaustausch endet'"), pSendLogs);
	Except
		vErrorDescription = ErrorDescription();
		
		// Start data exchange
		vHotelBIProxy.DataExchangeEnd(TrimAll(Hotel.Code), False, vErrorDescription);
		
		Raise ErrorDescription();
	EndTry;
EndProcedure // pmRun

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure SendLogs(pLogText, pSendLogs)
	If pSendLogs Then 
		tcCommonFunctionOnClientServer.TextMessage("[" + CurrentSessionDate() + "] " + pLogText);	
	EndIf;
EndProcedure // SendLogs

// -----------------------------------------------------------------------------
Function GetLastDateInSales()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	MAX(SalesRecords.Period) AS MaxPeriod
	|FROM
	|	AccumulationRegister.Sales AS SalesRecords";
	vQryRes = vQry.Execute().Unload();
	If vQryRes.Count() > 0 Then
		Return vQryRes.Get(0).MaxPeriod;
	Else
		Return '00010101';
	EndIf;
EndFunction // GetLastDateInSales

// -----------------------------------------------------------------------------
Function GetClientByCode(pCode)
	vClient = Catalogs.Clients.FindByCode(pCode, False);
	Return vClient;
EndFunction // GetClientByCode

// -----------------------------------------------------------------------------
Function GetClientByFullNameAndDateOfBirth(pFullName, pDateOfBirth)
	vClient = Catalogs.Clients.EmptyRef();
	// Try to find client by name and date of birth
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Clients.Ref AS Ref
	|FROM
	|	Catalog.Clients AS Clients
	|WHERE
	|	Clients.FullName = &qFullName
	|	AND Clients.DateOfBirth = &qDateOfBirth
	|	AND NOT Clients.DeletionMark
	|	AND NOT Clients.IsFolder
	|
	|ORDER BY
	|	Clients.CreateDate DESC";
	vQry.SetParameter("qFullName", TrimAll(pFullName));
	vQry.SetParameter("qDateOfBirth", pDateOfBirth);
	vClients = vQry.Execute().Unload();
	If vClients.Count() > 0 Then
		vClient = vClients.Get(0).Ref;
	EndIf;
	Return vClient;
EndFunction // GetClientByFullNameAndDateOfBirth

// -----------------------------------------------------------------------------
Function GetClientByFullNameAndPhone(pFullName, pPhone)
	vClient = Catalogs.Clients.EmptyRef();
	// Try to find client by name and phone
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Clients.Ref AS Ref
	|FROM
	|	Catalog.Clients AS Clients
	|WHERE
	|	Clients.FullName = &qFullName
	|	AND Clients.Phone = &qPhone
	|	AND NOT Clients.DeletionMark
	|	AND NOT Clients.IsFolder
	|
	|ORDER BY
	|	Clients.CreateDate DESC";
	vQry.SetParameter("qFullName", TrimAll(pFullName));
	vQry.SetParameter("qPhone", TrimAll(pPhone));
	vClients = vQry.Execute().Unload();
	If vClients.Count() > 0 Then
		vClient = vClients.Get(0).Ref;
	EndIf;
	Return vClient;
EndFunction // GetClientByFullNameAndPhone

// -----------------------------------------------------------------------------
Function GetClientByFullNameAndEMail(pFullName, pEMail)
	vClient = Catalogs.Clients.EmptyRef();
	// Try to find client by name and e-mail
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Clients.Ref AS Ref
	|FROM
	|	Catalog.Clients AS Clients
	|WHERE
	|	Clients.FullName = &qFullName
	|	AND Clients.EMail = &qEMail
	|	AND NOT Clients.DeletionMark
	|	AND NOT Clients.IsFolder
	|
	|ORDER BY
	|	Clients.CreateDate DESC";
	vQry.SetParameter("qFullName", TrimAll(pFullName));
	vQry.SetParameter("qEMail", TrimAll(pEMail));
	vClients = vQry.Execute().Unload();
	If vClients.Count() > 0 Then
		vClient = vClients.Get(0).Ref;
	EndIf;
	Return vClient;
EndFunction // GetClientByFullNameAndEMail

// -----------------------------------------------------------------------------
Function GetCustomerByCode(pCode)
	vCustomer = Catalogs.Customers.FindByCode(pCode, False);
	Return vCustomer;
EndFunction // GetCustomerByCode
	
// -----------------------------------------------------------------------------
Function GetCustomerByDescriptionAndBirthDate(pDescription, pDateOfBirth)
	vCustomer = Catalogs.Customers.EmptyRef();
	// Try to find customer by name and date of birth
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Customers.Ref AS Ref
	|FROM
	|	Catalog.Customers AS Customers
	|WHERE
	|	Customers.Description = &qDescription
	|	AND Customers.DateOfBirth = &qDateOfBirth
	|	AND NOT Customers.DeletionMark
	|	AND NOT Customers.IsFolder
	|
	|ORDER BY
	|	Customers.CreateDate DESC";
	vQry.SetParameter("qDescription", TrimAll(pDescription));
	vQry.SetParameter("qDateOfBirth", pDateOfBirth);
	vCustomers = vQry.Execute().Unload();
	If vCustomers.Count() > 0 Then
		vCustomer = vCustomers.Get(0).Ref;
	EndIf;
	Return vCustomer;
EndFunction // GetCustomerByDescriptionAndBirthDate
	
// -----------------------------------------------------------------------------
Function GetCustomerByDescriptionAndEMail(pDescription, pEMail)
	vCustomer = Catalogs.Customers.EmptyRef();
	// Try to find customer by name and e-mail
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Customers.Ref AS Ref
	|FROM
	|	Catalog.Customers AS Customers
	|WHERE
	|	Customers.Description = &qDescription
	|	AND Customers.EMail = &qEMail
	|	AND NOT Customers.DeletionMark
	|	AND NOT Customers.IsFolder
	|
	|ORDER BY
	|	Customers.CreateDate DESC";
	vQry.SetParameter("qDescription", TrimAll(pDescription));
	vQry.SetParameter("qEmail", TrimAll(pEmail));
	vCustomers = vQry.Execute().Unload();
	If vCustomers.Count() > 0 Then
		vCustomer = vCustomers.Get(0).Ref;
	EndIf;
	Return vCustomer;
EndFunction // GetCustomerByDescriptionAndEMail
	
// -----------------------------------------------------------------------------
Function GetCustomerByDescriptionAndPhone(pDescription, pPhone)
	vCustomer = Catalogs.Customers.EmptyRef();
	// Try to find customer by name and phone
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Customers.Ref AS Ref
	|FROM
	|	Catalog.Customers AS Customers
	|WHERE
	|	Customers.Description = &qDescription
	|	AND Customers.Phone = &qPhone
	|	AND NOT Customers.DeletionMark
	|	AND NOT Customers.IsFolder
	|
	|ORDER BY
	|	Customers.CreateDate DESC";
	vQry.SetParameter("qDescription", TrimAll(pDescription));
	vQry.SetParameter("qPhone", TrimAll(pPhone));
	vCustomers = vQry.Execute().Unload();
	If vCustomers.Count() > 0 Then
		vCustomer = vCustomers.Get(0).Ref;
	EndIf;
	Return vCustomer;
EndFunction // GetCustomerByDescriptionAndPhone
	
// -----------------------------------------------------------------------------
Function GetCustomerByTINAndKPP(pTIN, pKPP)
	vCustomer = Catalogs.Customers.EmptyRef();
	// Try to find customer by TIN and KPP
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Customers.Ref AS Ref
	|FROM
	|	Catalog.Customers AS Customers
	|WHERE
	|	Customers.TIN = &qTIN
	|	AND Customers.KPP = &qKPP
	|	AND NOT Customers.DeletionMark
	|	AND NOT Customers.IsFolder
	|
	|ORDER BY
	|	Customers.CreateDate DESC";
	vQry.SetParameter("qTIN", TrimAll(pTIN));
	vQry.SetParameter("qKPP", TrimAll(pKPP));
	vCustomers = vQry.Execute().Unload();
	If vCustomers.Count() > 0 Then
		vCustomer = vCustomers.Get(0).Ref;
	EndIf;
	Return vCustomer;
EndFunction // GetCustomerByTINAndKPP

// -----------------------------------------------------------------------------
Function GetDiscountCardByCode(pCode)
	vDiscountCard = Catalogs.DiscountCards.FindByCode(pCode, False);
	Return vDiscountCard;
EndFunction // GetDiscountCardByCode

// -----------------------------------------------------------------------------
Function GetDiscountCardByIdentifier(pIdentifier)
	vDiscountCard = Catalogs.DiscountCards.EmptyRef();
	// Try to find discount card by identifier
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	DiscountCards.Ref AS Ref
	|FROM
	|	Catalog.DiscountCards AS DiscountCards
	|WHERE
	|	DiscountCards.Identifier = &qIdentifier
	|	AND NOT DiscountCards.DeletionMark
	|
	|ORDER BY
	|	DiscountCards.Code DESC";
	vQry.SetParameter("qIdentifier", TrimAll(pIdentifier));
	vDiscountCards = vQry.Execute().Unload();
	If vDiscountCards.Count() > 0 Then
		vDiscountCard = vDiscountCards.Get(0).Ref;
	EndIf;
	Return vDiscountCard;
EndFunction // GetDiscountCardByIdentifier

// -----------------------------------------------------------------------------
Procedure GetNewItems(pHotelBIProxy, pNewItems)
	While True Do
		WriteLogEvent(NStr("en = 'Get new items from 1C:Hotel BI'; de = 'Neue Objekte Lesen von 1C:Hotel BI'; ru = 'Получение новых элементов из системы 1С:Отель BI'"), EventLogLevel.Information, , , "Start");
		
		vBINewItemsXDTO = pHotelBIProxy.ReadNewItems(TrimAll(Hotel.Code));
		
		vThereAreNewClients = False;
		If vBINewItemsXDTO.Clients.Client <> Undefined And vBINewItemsXDTO.Clients.Client.Count() > 0 Then
			vThereAreNewClients = True;
		EndIf;
		
		vThereAreNewCustomers = False;
		If vBINewItemsXDTO.Customers.Customer <> Undefined And vBINewItemsXDTO.Customers.Customer.Count() > 0 Then
			vThereAreNewCustomers = True;
		EndIf;
		
		vThereAreNewDiscountCards = False;
		If Not DoNotSyncDiscountCards Then
			If vBINewItemsXDTO.DiscountCards.DiscountCard <> Undefined And vBINewItemsXDTO.DiscountCards.DiscountCard.Count() > 0 Then
				vThereAreNewDiscountCards = True;
			EndIf;
		EndIf;
		
		If Not vThereAreNewClients And Not vThereAreNewCustomers And Not vThereAreNewDiscountCards Then 
			Break;
		EndIf;
		
		// Process clients
		vClientCodeMappingsXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "CodeMappings"));
		For Each vClientXDTO In vBINewItemsXDTO.Clients.Client Do
			vClientRef = Undefined;
			If Not ValueIsFilled(vClientRef) And Not IsBlankString(vClientXDTO.FullName) And ValueIsFilled(vClientXDTO.DateOfBirth) Then
				vClientRef = GetClientByFullNameAndDateOfBirth(vClientXDTO.FullName, vClientXDTO.DateOfBirth);
			EndIf;
			If Not ValueIsFilled(vClientRef) And Not IsBlankString(vClientXDTO.FullName) And Not IsBlankString(vClientXDTO.EMail) Then
				vClientRef = GetClientByFullNameAndEMail(vClientXDTO.FullName, vClientXDTO.EMail);
			EndIf;
			If Not ValueIsFilled(vClientRef) And Not IsBlankString(vClientXDTO.FullName) And Not IsBlankString(vClientXDTO.Phone) Then
				vClientRef = GetClientByFullNameAndPhone(vClientXDTO.FullName, vClientXDTO.Phone);
			EndIf;
			If ValueIsFilled(vClientRef) Then
				vClientObj = vClientRef.GetObject();
			Else
				vClientObj = Catalogs.Clients.CreateItem();
				vClientObj.pmFillAttributesWithDefaultValues();
			EndIf;
			FillPropertyValues(vClientObj, vClientXDTO, , "Code, Author, CreateDate, Sex, Citizenship, IdentityDocumentType, MilitaryRank, Salutation, Photo, Signature, ExternalCode, RoomRate, RoomRateServiceGroup, B24ContactID");
			vClientObj.FullName = vClientObj.pmGetFullName();
			If Not IsBlankString(vClientXDTO.Sex) Then 
				If Upper(Left(vClientXDTO.Sex, 1)) = "M" Or Upper(Left(vClientXDTO.Sex, 1)) = "М" Then
					vClientObj.Sex = Enums.Sex.Male;
				Else
					vClientObj.Sex = Enums.Sex.Female;
				EndIf;
			EndIf;
			If Not IsBlankString(vClientXDTO.Citizenship) Then
				vCitizenship = Catalogs.Countries.FindByDescription(vClientXDTO.Citizenship, True);
				If ValueIsFilled(vCitizenship) Then
					vClientObj.Citizenship = vCitizenship;
				EndIf;
			EndIf;
			If Not IsBlankString(vClientXDTO.IdentityDocumentType) Then
				vIdentityDocumentType = Catalogs.IdentityDocumentTypes.FindByDescription(vClientXDTO.IdentityDocumentType, True);
				If ValueIsFilled(vIdentityDocumentType) Then
					vClientObj.IdentityDocumentType = vIdentityDocumentType;
				EndIf;
			EndIf;
			If Not IsBlankString(vClientXDTO.MilitaryRank) Then
				vMilitaryRank = Catalogs.MilitaryRanks.FindByDescription(vClientXDTO.MilitaryRank, True);
				If ValueIsFilled(vMilitaryRank) Then
					vClientObj.MilitaryRank = vMilitaryRank;
				EndIf;
			EndIf;
			If Not IsBlankString(vClientXDTO.Salutation) Then
				vSalutation = Catalogs.Salutations.FindByDescription(vClientXDTO.Salutation, True);
				If ValueIsFilled(vSalutation) Then
					vClientObj.Salutation = vSalutation;
				EndIf;
			EndIf;
			If Not IsBlankString(vClientXDTO.LanguageCode) Then
				vLanguage = Catalogs.Languages.FindByCode(vClientXDTO.LanguageCode, False);
				If vClientObj.Language <> vLanguage Then
					vClientObj.Language = vLanguage;
				EndIf;
			EndIf;
			If Not IsBlankString(vClientXDTO.DiscountTypeCode) Then
				vDiscountType = Catalogs.DiscountTypes.FindByCode(vClientXDTO.DiscountTypeCode, False);
				If vClientObj.DiscountType <> vDiscountType Then
					vClientObj.DiscountType = vDiscountType;
				EndIf;
			Else
				If ValueIsFilled(vClientObj.DiscountType) Then
					vClientObj.DiscountType = Catalogs.DiscountTypes.EmptyRef();
				EndIf;
			EndIf;
			If Not IsBlankString(vClientXDTO.DiscountCardIdentifier) Then
				vDiscountCard = cmGetDiscountCardById(vClientXDTO.DiscountCardIdentifier, False);
				If vClientObj.DiscountCard <> vDiscountCard Then
					vClientObj.DiscountCard = vDiscountCard;
				EndIf;
			Else
				If ValueIsFilled(vClientObj.DiscountCard) Then
					vClientObj.DiscountCard = Catalogs.DiscountCards.EmptyRef();
				EndIf;
			EndIf;
			If Not IsBlankString(vClientXDTO.ClientTypeCode) Then
				vClientType = Catalogs.ClientTypes.FindByCode(vClientXDTO.ClientTypeCode, False);
				If vClientObj.ClientType <> vClientType Then
					vClientObj.ClientType = vClientType;
				EndIf;
			Else
				If ValueIsFilled(vClientObj.ClientType) Then
					vClientObj.ClientType = Catalogs.ClientTypes.EmptyRef();
				EndIf;
			EndIf;
			If Not IsBlankString(vClientXDTO.MarketingCodeCode) Then
				vMarketingCode = Catalogs.MarketingCodes.FindByCode(vClientXDTO.MarketingCodeCode, False);
				If vClientObj.MarketingCode <> vMarketingCode Then
					vClientObj.MarketingCode = vMarketingCode;
				EndIf;
			Else
				If ValueIsFilled(vClientObj.MarketingCode) Then
					vClientObj.MarketingCode = Catalogs.MarketingCodes.EmptyRef();
				EndIf;
			EndIf;
			If Not IsBlankString(vClientXDTO.SourceOfBusinessCode) Then
				vSourceOfBusiness = Catalogs.SourcesOfBusiness.FindByCode(vClientXDTO.SourceOfBusinessCode, False);
				If vClientObj.SourceOfBusiness <> vSourceOfBusiness Then
					vClientObj.SourceOfBusiness = vSourceOfBusiness;
				EndIf;
			Else
				If ValueIsFilled(vClientObj.SourceOfBusiness) Then
					vClientObj.SourceOfBusiness = Catalogs.SourcesOfBusiness.EmptyRef();
				EndIf;
			EndIf;
			If Not IsBlankString(vClientXDTO.Photo) Then
				vPhoto = New Picture(Base64Value(vClientXDTO.Photo));
				If vPhoto <> Undefined And TypeOf(vPhoto) = Type("Picture") Then
					vClientObj.Photo = New ValueStorage(vPhoto);
				EndIf;
			EndIf;
			If Not IsBlankString(vClientXDTO.Signature) Then
				vSignature = New Picture(Base64Value(vClientXDTO.Signature));
				If vSignature <> Undefined And TypeOf(vSignature) = Type("Picture") Then
					vClientObj.Signature = New ValueStorage(vSignature);
				EndIf;
			EndIf;
			If vClientObj.Modified() Then
				vClientObj.Write();
				vClientObj.pmWriteToClientChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				
				vCodeMappingXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "CodeMapping"));
				vCodeMappingXDTO.Code = vClientXDTO.Code;
				vCodeMappingXDTO.CodeInHotel = TrimAll(vClientObj.Code);
				
				vClientCodeMappingsXDTO.CodeMapping.Add(vCodeMappingXDTO);
				
				pNewItems.NewClients.Add(vClientObj.Ref);
			EndIf;
		EndDo;
		
		// Save new client mappings
		If vThereAreNewClients Then
			pHotelBIProxy.SaveClientMappings(TrimAll(Hotel.Code), vClientCodeMappingsXDTO);
		EndIf;
			
		// Process customers
		vCustomerCodeMappingsXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "CodeMappings"));
		For Each vCustomerXDTO In vBINewItemsXDTO.Customers.Customer Do
			vCustomerRef = Undefined;
			If Not ValueIsFilled(vCustomerRef) And Not IsBlankString(vCustomerXDTO.TIN) Then
				vCustomerRef = GetCustomerByTINAndKPP(vCustomerXDTO.TIN, vCustomerXDTO.KPP);
			EndIf;
			If Not ValueIsFilled(vCustomerRef) And Not IsBlankString(vCustomerXDTO.Description) And Not IsBlankString(vCustomerXDTO.EMail) Then
				vCustomerRef = GetCustomerByDescriptionAndEMail(vCustomerXDTO.Description, vCustomerXDTO.EMail);
			EndIf;
			If Not ValueIsFilled(vCustomerRef) And Not IsBlankString(vCustomerXDTO.Description) And Not IsBlankString(vCustomerXDTO.Phone) Then
				vCustomerRef = GetCustomerByDescriptionAndPhone(vCustomerXDTO.Description, vCustomerXDTO.Phone);
			EndIf;
			If Not ValueIsFilled(vCustomerRef) And Not IsBlankString(vCustomerXDTO.Description) And ValueIsFilled(vCustomerXDTO.DateOfBirth) Then
				vCustomerRef = GetCustomerByDescriptionAndBirthDate(vCustomerXDTO.Description, vCustomerXDTO.DateOfBirth);
			EndIf;
			If ValueIsFilled(vCustomerRef) Then
				vCustomerObj = vCustomerRef.GetObject();
			Else
				vCustomerObj = Catalogs.Customers.CreateItem();
				vCustomerObj.pmFillAttributesWithDefaultValues();
			EndIf;
			FillPropertyValues(vCustomerObj, vCustomerXDTO, , "Code, Author, CreateDate, RoomRate, RoomRateServiceGroup, CustomerType, PlannedPaymentMethod, AgentCommissionType, AgentCommissionServiceGroup, Contract, AgentCommissionContract, BankAccount, FeeTerms, ExternalCode, Color, IdentityDocumentType, B24CustomerID, B24ContactID");
			If Not IsBlankString(vCustomerXDTO.AccountingCurrencyCode) Then
				vCurrency = Catalogs.Currencies.FindByCode(vCustomerXDTO.AccountingCurrencyCode, False);
				If ValueIsFilled(vCurrency) Then
					vCustomerObj.AccountingCurrency = vCurrency;
				EndIf;
			EndIf;
			If Not IsBlankString(vCustomerXDTO.ParentOrganizationCode) Then
				vParentOrganization = Catalogs.Customers.FindByCode(vCustomerXDTO.ParentOrganizationCode, False);
				If ValueIsFilled(vParentOrganization) Then
					vCustomerObj.ParentOrganization = vParentOrganization;
				EndIf;
			EndIf;
			If Not IsBlankString(vCustomerXDTO.CustomerType) Then
				vCustomerType = Catalogs.CustomerTypes.FindByDescription(vCustomerXDTO.CustomerType, True);
				If ValueIsFilled(vCustomerType) Then
					vCustomerObj.CustomerType = vCustomerType;
				EndIf;
			EndIf;
			If Not IsBlankString(vCustomerXDTO.PlannedPaymentMethod) Then
				vPlannedPaymentMethod = Catalogs.PaymentMethods.FindByDescription(vCustomerXDTO.PlannedPaymentMethod, True);
				If ValueIsFilled(vPlannedPaymentMethod) Then
					vCustomerObj.PlannedPaymentMethod = vPlannedPaymentMethod;
				EndIf;
			EndIf;
			If Not IsBlankString(vCustomerXDTO.AgentCode) Then
				vAgent = Catalogs.Customers.FindByCode(vCustomerXDTO.AgentCode, False);
				If ValueIsFilled(vAgent) Then
					vCustomerObj.Agent = vAgent;
				EndIf;
			EndIf;
			If Not IsBlankString(vCustomerXDTO.AgentCommissionType) Then
				If TrimAll(Enums.AgentCommissionTypes.FirstDayPercent) = vCustomerXDTO.AgentCommissionType Then
					vCustomerObj.AgentCommissionType = Enums.AgentCommissionTypes.FirstDayPercent;
				ElsIf TrimAll(Enums.AgentCommissionTypes.AmountPerCheckInPerRoom) = vCustomerXDTO.AgentCommissionType Then
					vCustomerObj.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerCheckInPerRoom;
				ElsIf TrimAll(Enums.AgentCommissionTypes.AmountPerDayPerRoom) = vCustomerXDTO.AgentCommissionType Then
					vCustomerObj.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerDayPerRoom;
				ElsIf TrimAll(Enums.AgentCommissionTypes.AmountPerCheckInPerClient) = vCustomerXDTO.AgentCommissionType Then
					vCustomerObj.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerCheckInPerClient;
				ElsIf TrimAll(Enums.AgentCommissionTypes.AmountPerDayPerClient) = vCustomerXDTO.AgentCommissionType Then
					vCustomerObj.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerDayPerClient;
				Else
					vCustomerObj.AgentCommissionType = Enums.AgentCommissionTypes.Percent;
				EndIf;
			EndIf;
			If Not IsBlankString(vCustomerXDTO.AgentCommissionServiceGroup) Then
				vAgentCommissionServiceGroup = Catalogs.ServiceGroups.FindByDescription(vCustomerXDTO.AgentCommissionServiceGroup, True);
				If ValueIsFilled(vAgentCommissionServiceGroup) Then
					vCustomerObj.AgentCommissionServiceGroup = vAgentCommissionServiceGroup;
				EndIf;
			EndIf;
			If Not IsBlankString(vCustomerXDTO.BankAccount) Then
				vBankAccount = Catalogs.BankAccounts.FindByDescription(vCustomerXDTO.BankAccount, True);
				If ValueIsFilled(vBankAccount) Then
					vCustomerObj.BankAccount = vBankAccount;
				EndIf;
			EndIf;
			If Not IsBlankString(vCustomerXDTO.FeeTerms) Then
				vFeeTerms = Catalogs.FeeTerms.FindByDescription(vCustomerXDTO.FeeTerms, True);
				If ValueIsFilled(vFeeTerms) Then
					vCustomerObj.FeeTerms = vFeeTerms;
				EndIf;
			EndIf;
			If Not IsBlankString(vCustomerXDTO.ClientTypeCode) Then
				vClientType = Catalogs.ClientTypes.FindByCode(vCustomerXDTO.ClientTypeCode, False);
				If vCustomerObj.ClientType <> vClientType Then
					vCustomerObj.ClientType = vClientType;
				EndIf;
			Else
				If ValueIsFilled(vCustomerObj.ClientType) Then
					vCustomerObj.ClientType = Catalogs.ClientTypes.EmptyRef();
				EndIf;
			EndIf;
			If Not IsBlankString(vCustomerXDTO.DiscountTypeCode) Then
				vDiscountType = Catalogs.DiscountTypes.FindByCode(vCustomerXDTO.DiscountTypeCode, False);
				If vCustomerObj.DiscountType <> vDiscountType Then
					vCustomerObj.DiscountType = vDiscountType;
				EndIf;
			Else
				If ValueIsFilled(vCustomerObj.DiscountType) Then
					vCustomerObj.DiscountType = Catalogs.DiscountTypes.EmptyRef();
				EndIf;
			EndIf;
			If Not IsBlankString(vCustomerXDTO.MarketingCodeCode) Then
				vMarketingCode = Catalogs.MarketingCodes.FindByCode(vCustomerXDTO.MarketingCodeCode, False);
				If vCustomerObj.MarketingCode <> vMarketingCode Then
					vCustomerObj.MarketingCode = vMarketingCode;
				EndIf;
			Else
				If ValueIsFilled(vCustomerObj.MarketingCode) Then
					vCustomerObj.MarketingCode = Catalogs.MarketingCodes.EmptyRef();
				EndIf;
			EndIf;
			If Not IsBlankString(vCustomerXDTO.SourceOfBusinessCode) Then
				vSourceOfBusiness = Catalogs.SourcesOfBusiness.FindByCode(vCustomerXDTO.SourceOfBusinessCode, False);
				If vCustomerObj.SourceOfBusiness <> vSourceOfBusiness Then
					vCustomerObj.SourceOfBusiness = vSourceOfBusiness;
				EndIf;
			Else
				If ValueIsFilled(vCustomerObj.SourceOfBusiness) Then
					vCustomerObj.SourceOfBusiness = Catalogs.SourcesOfBusiness.EmptyRef();
				EndIf;
			EndIf;
			If vCustomerObj.Modified() Then
				vCustomerObj.Write();
				vCustomerObj.pmWriteToCustomerChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				
				vCodeMappingXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "CodeMapping"));
				vCodeMappingXDTO.Code = vCustomerXDTO.Code;
				vCodeMappingXDTO.CodeInHotel = TrimAll(vCustomerObj.Code);
				
				vCustomerCodeMappingsXDTO.CodeMapping.Add(vCodeMappingXDTO);
				
				pNewItems.NewCustomers.Add(vCustomerObj.Ref);
			EndIf;
		EndDo;
		
		// Save new customer mappings
		If vThereAreNewCustomers Then
			pHotelBIProxy.SaveCustomerMappings(TrimAll(Hotel.Code), vCustomerCodeMappingsXDTO);
		EndIf;
		
		// Process discount cards
		If Not DoNotSyncDiscountCards Then
			vDiscountCardCodeMappingsXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "CodeMappings"));
			For Each vDiscountCardXDTO In vBINewItemsXDTO.DiscountCards.DiscountCard Do
				vDiscountCardRef = Undefined;
				If Not IsBlankString(vDiscountCardXDTO.Identifier) Then
					vDiscountCardRef = GetDiscountCardByIdentifier(vDiscountCardXDTO.Identifier);
				EndIf;
				If ValueIsFilled(vDiscountCardRef) Then
					vDiscountCardObj = vDiscountCardRef.GetObject();
				Else
					vDiscountCardObj = Catalogs.DiscountCards.CreateItem();
					vDiscountCardObj.Identifier = vDiscountCardXDTO.Identifier;
				EndIf;
				FillPropertyValues(vDiscountCardObj, vDiscountCardXDTO, , "Code, Identifier"); 
				If Not IsBlankString(vDiscountCardXDTO.ClientCode) Then
					vDiscountCardClient = GetClientByCode(TrimAll(vDiscountCardXDTO.ClientCode));
					If ValueIsFilled(vDiscountCardClient) And vDiscountCardClient <> vDiscountCardObj.Client Then
						vDiscountCardObj.Client = vDiscountCardClient;
					EndIf;
				EndIf;
				If Not IsBlankString(vDiscountCardXDTO.ClientTypeCode) Then
					vClientType = Catalogs.ClientTypes.FindByCode(vDiscountCardXDTO.ClientTypeCode, False);
					If vDiscountCardObj.ClientType <> vClientType Then
						vDiscountCardObj.ClientType = vClientType;
					EndIf;
				Else
					If ValueIsFilled(vDiscountCardObj.ClientType) Then
						vDiscountCardObj.ClientType = Catalogs.ClientTypes.EmptyRef();
					EndIf;
				EndIf;
				If Not IsBlankString(vDiscountCardXDTO.DiscountTypeCode) Then
					vDiscountType = Catalogs.DiscountTypes.FindByCode(vDiscountCardXDTO.DiscountTypeCode, False);
					If vDiscountCardObj.DiscountType <> vDiscountType Then
						vDiscountCardObj.DiscountType = vDiscountType;
					EndIf;
				Else
					If ValueIsFilled(vDiscountCardObj.DiscountType) Then
						vDiscountCardObj.DiscountType = Catalogs.DiscountTypes.EmptyRef();
					EndIf;
				EndIf;
				If vDiscountCardObj.Modified() Then
					vDiscountCardObj.Write();
					
					vCodeMappingXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "CodeMapping"));
					vCodeMappingXDTO.Code = vDiscountCardXDTO.Code;
					vCodeMappingXDTO.CodeInHotel = TrimAll(vDiscountCardObj.Code);
					
					vDiscountCardCodeMappingsXDTO.CodeMapping.Add(vCodeMappingXDTO);
				
					pNewItems.NewDiscountCards.Add(vDiscountCardObj.Ref);
				EndIf;
			EndDo;
			
			// Save new discount card mappings
			If vThereAreNewDiscountCards Then
				pHotelBIProxy.SaveDiscountCardMappings(TrimAll(Hotel.Code), vDiscountCardCodeMappingsXDTO);
			EndIf;
		EndIf;
	EndDo;
	
	WriteLogEvent(NStr("en = 'Get new items from 1C:Hotel BI'; de = 'Neue Objekte Lesen von 1C:Hotel BI'; ru = 'Получение новых элементов из системы 1С:Отель BI'"), EventLogLevel.Information, , , "End");
EndProcedure // GetNewItems

// -----------------------------------------------------------------------------
Procedure GetChangedItems(pHotelBIProxy, Val pLastSyncDate, Val pCurrentSyncDate, pChangedItems)
	vReadChangesFromDate = pLastSyncDate;
	
	While True Do
		WriteLogEvent(NStr("en = 'Read changes from 1C:Hotel BI'; de = 'Änderungen Lesen von 1C:Hotel BI'; ru = 'Чтение изменений из системы 1С:Отель BI'"), EventLogLevel.Information, , , "Start from date " + vReadChangesFromDate + " to " + pCurrentSyncDate);
		
		vBIChangesXDTO = pHotelBIProxy.ReadChangedItems(TrimAll(Hotel.Code), vReadChangesFromDate, pCurrentSyncDate);
		
		// Process clients
		vThereAreChangedClients = False;
		For Each vClientXDTO In vBIChangesXDTO.Clients.Client Do
			vThereAreChangedClients = True;
			vClientRef = Undefined;
			If Not IsBlankString(vClientXDTO.ClientCodeInHotel) Then
				vClientRef = GetClientByCode(vClientXDTO.ClientCodeInHotel);
			EndIf;
			If ValueIsFilled(vClientRef) Then
				If pChangedItems.ChangedClients.FindByValue(vClientRef) = Undefined Then
					vClientObj = vClientRef.GetObject();
					If Not IsBlankString(vClientXDTO.LastName) Then
						vClientObj.LastName = vClientXDTO.LastName;
					EndIf;
					If Not IsBlankString(vClientXDTO.FirstName) Then
						vClientObj.FirstName = vClientXDTO.FirstName;
					EndIf;
					If Not IsBlankString(vClientXDTO.SecondName) Then
						vClientObj.SecondName = vClientXDTO.SecondName;
					EndIf;
					vClientObj.FullName = vClientObj.pmGetFullName();
					If ValueIsFilled(vClientXDTO.DateOfBirth) Then
						vClientObj.DateOfBirth = vClientXDTO.DateOfBirth;
					EndIf;
					If Not IsBlankString(vClientXDTO.Phone) Then
						vClientObj.Phone = vClientXDTO.Phone;
					EndIf;
					If Not IsBlankString(vClientXDTO.EMail) Then
						vClientObj.EMail = vClientXDTO.EMail;
					EndIf;
					If Not IsBlankString(vClientXDTO.Remarks) Then
						vClientObj.Remarks = vClientXDTO.Remarks;
					EndIf;
					vClientTypeHasChanged = False;
					If Not IsBlankString(vClientXDTO.ClientTypeCode) Then
						vClientType = Catalogs.ClientTypes.FindByCode(vClientXDTO.ClientTypeCode, False);
						If vClientObj.ClientType <> vClientType Then
							vClientObj.ClientType = vClientType;
							vClientTypeHasChanged = True;
						EndIf;
					Else
						If ValueIsFilled(vClientObj.ClientType) Then
							vClientObj.ClientType = Catalogs.ClientTypes.EmptyRef();
							vClientTypeHasChanged = True;
						EndIf;
					EndIf;
					vDiscountTypeHasChanged = False;
					If Not IsBlankString(vClientXDTO.DiscountTypeCode) Then
						vDiscountType = Catalogs.DiscountTypes.FindByCode(vClientXDTO.DiscountTypeCode, False);
						If vClientObj.DiscountType <> vDiscountType Then
							vClientObj.DiscountType = vDiscountType;
							vDiscountTypeHasChanged = True;
						EndIf;
					Else
						If ValueIsFilled(vClientObj.DiscountType) Then
							vClientObj.DiscountType = Catalogs.DiscountTypes.EmptyRef();
							vDiscountTypeHasChanged = True;
						EndIf;
					EndIf;
					vMarketingCodeHasChanged = False;
					If Not IsBlankString(vClientXDTO.MarketingCodeCode) Then
						vMarketingCode = Catalogs.MarketingCodes.FindByCode(vClientXDTO.MarketingCodeCode, False);
						If vClientObj.MarketingCode <> vMarketingCode Then
							vClientObj.MarketingCode = vMarketingCode;
							vMarketingCodeHasChanged = True;
						EndIf;
					Else
						If ValueIsFilled(vClientObj.MarketingCode) Then
							vClientObj.MarketingCode = Catalogs.MarketingCodes.EmptyRef();
							vMarketingCodeHasChanged = True;
						EndIf;
					EndIf;
					vSourceOfBusinessHasChanged = False;
					If Not IsBlankString(vClientXDTO.SourceOfBusinessCode) Then
						vSourceOfBusiness = Catalogs.SourcesOfBusiness.FindByCode(vClientXDTO.SourceOfBusinessCode, False);
						If vClientObj.SourceOfBusiness <> vSourceOfBusiness Then
							vClientObj.SourceOfBusiness = vSourceOfBusiness;
							vSourceOfBusinessHasChanged = True;
						EndIf;
					Else
						If ValueIsFilled(vClientObj.SourceOfBusiness) Then
							vClientObj.SourceOfBusiness = Catalogs.SourcesOfBusiness.EmptyRef();
							vSourceOfBusinessHasChanged = True;
						EndIf;
					EndIf;
					If Not IsBlankString(vClientXDTO.Photo) Then
						vPhoto = New Picture(Base64Value(vClientXDTO.Photo));
						If vPhoto <> Undefined And TypeOf(vPhoto) = Type("Picture") Then
							vClientObj.Photo = New ValueStorage(vPhoto);
						EndIf;
					EndIf;
					If Not IsBlankString(vClientXDTO.Signature) Then
						vSignature = New Picture(Base64Value(vClientXDTO.Signature));
						If vSignature <> Undefined And TypeOf(vSignature) = Type("Picture") Then
							vClientObj.Signature = New ValueStorage(vSignature);
						EndIf;
					EndIf;
					If vClientObj.Modified() Then
						vClientObj.Write();
						vClientObj.pmWriteToClientChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
						
						pChangedItems.ChangedClients.Add(vClientObj.Ref);
						
						// Update guest active reservations if client parameters has changed
						If vClientTypeHasChanged Or vDiscountTypeHasChanged Or vMarketingCodeHasChanged Or vSourceOfBusinessHasChanged Then
							vUpdateOneRoomGuests = True;
							If vClientTypeHasChanged Then
								If ValueIsFilled(vClientObj.ClientType) And vClientObj.ClientType.Mode = Enums.ClientTypeModes.PerClient Then
									vUpdateOneRoomGuests = False;
								EndIf;
							EndIf;
							If vDiscountTypeHasChanged Then
								If ValueIsFilled(vClientObj.DiscountType) And vClientObj.DiscountType.IsPersonalDiscount Then
									vUpdateOneRoomGuests = False;
								EndIf;
							EndIf;
							If vMarketingCodeHasChanged Then
								If ValueIsFilled(vClientObj.MarketingCode) And ValueIsFilled(vClientObj.MarketingCode.DiscountType) And vClientObj.MarketingCode.DiscountType.IsPersonalDiscount Then
									vUpdateOneRoomGuests = False;
								EndIf;
							EndIf;
							vClientDocs = GetGuestActiveReservations(vClientObj.Ref);
							For Each vDocRow In vClientDocs Do
								If Not vUpdateOneRoomGuests And vDocRow.Guest <> vClientObj.Ref Then
									Continue;
								EndIf;
								vDocObj = vDocRow.Ref.GetObject();
								If vClientTypeHasChanged Then
									vDocObj.ClientType = vClientObj.ClientType;
								EndIf;
								If vDiscountTypeHasChanged Then
									vDocObj.DiscountType = vClientObj.DiscountType;
								EndIf;
								If vMarketingCodeHasChanged Then
									vDocObj.MarketingCode = vClientObj.MarketingCode;
								EndIf;
								If vSourceOfBusinessHasChanged Then
									vDocObj.SourceOfBusiness = vClientObj.SourceOfBusiness;
								EndIf;
								vDocObj.pmSetDiscounts();
								vDocObj.Write(DocumentWriteMode.Posting);
								If TypeOf(vDocObj) = Type("DocumentObject.Reservation") Then
									vDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
								Else
									vDocObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
								EndIf;
							EndDo;								
						EndIf;
					EndIf;
				EndIf;
			Else
				vCustomerRef = Undefined;
				If Not IsBlankString(vClientXDTO.ClientCodeInHotel) Then
					vCustomerRef = GetCustomerByCode(vClientXDTO.ClientCodeInHotel);
				EndIf;
				If ValueIsFilled(vCustomerRef) And Lower(TrimAll(vCustomerRef.Description)) = Lower(TrimAll(vClientXDTO.FullName)) Then
					If pChangedItems.ChangedCustomers.FindByValue(vCustomerRef) = Undefined Then
						vCustomerObj = vCustomerRef.GetObject();
						If ValueIsFilled(vClientXDTO.DateOfBirth) Then
							vCustomerObj.DateOfBirth = vClientXDTO.DateOfBirth;
						EndIf;
						If Not IsBlankString(vClientXDTO.Phone) Then
							vCustomerObj.Phone = vClientXDTO.Phone;
						EndIf;
						If Not IsBlankString(vClientXDTO.EMail) Then
							vCustomerObj.EMail = vClientXDTO.EMail;
						EndIf;
						If Not IsBlankString(vClientXDTO.Remarks) Then
							vCustomerObj.Remarks = vClientXDTO.Remarks;
						EndIf;
						vClientTypeHasChanged = False;
						If Not IsBlankString(vClientXDTO.ClientTypeCode) Then
							vClientType = Catalogs.ClientTypes.FindByCode(vClientXDTO.ClientTypeCode, False);
							If vCustomerObj.ClientType <> vClientType Then
								vCustomerObj.ClientType = vClientType;
								vClientTypeHasChanged = True;
							EndIf;
						Else
							If ValueIsFilled(vCustomerObj.ClientType) Then
								vCustomerObj.ClientType = Catalogs.ClientTypes.EmptyRef();
								vClientTypeHasChanged = True;
							EndIf;
						EndIf;
						vDiscountTypeHasChanged = False;
						If Not IsBlankString(vClientXDTO.DiscountTypeCode) Then
							vDiscountType = Catalogs.DiscountTypes.FindByCode(vClientXDTO.DiscountTypeCode, False);
							If vCustomerObj.DiscountType <> vDiscountType Then
								vCustomerObj.DiscountType = vDiscountType;
								vDiscountTypeHasChanged = True;
							EndIf;
						Else
							If ValueIsFilled(vCustomerObj.DiscountType) Then
								vCustomerObj.DiscountType = Catalogs.DiscountTypes.EmptyRef();
								vDiscountTypeHasChanged = True;
							EndIf;
						EndIf;
						vMarketingCodeHasChanged = False;
						If Not IsBlankString(vClientXDTO.MarketingCodeCode) Then
							vMarketingCode = Catalogs.MarketingCodes.FindByCode(vClientXDTO.MarketingCodeCode, False);
							If vCustomerObj.MarketingCode <> vMarketingCode Then
								vCustomerObj.MarketingCode = vMarketingCode;
								vMarketingCodeHasChanged = True;
							EndIf;
						Else
							If ValueIsFilled(vCustomerObj.MarketingCode) Then
								vCustomerObj.MarketingCode = Catalogs.MarketingCodes.EmptyRef();
								vMarketingCodeHasChanged = True;
							EndIf;
						EndIf;
						vSourceOfBusinessHasChanged = False;
						If Not IsBlankString(vClientXDTO.SourceOfBusinessCode) Then
							vSourceOfBusiness = Catalogs.SourcesOfBusiness.FindByCode(vClientXDTO.SourceOfBusinessCode, False);
							If vCustomerObj.SourceOfBusiness <> vSourceOfBusiness Then
								vCustomerObj.SourceOfBusiness = vSourceOfBusiness;
								vSourceOfBusinessHasChanged = True;
							EndIf;
						Else
							If ValueIsFilled(vCustomerObj.SourceOfBusiness) Then
								vCustomerObj.SourceOfBusiness = Catalogs.SourcesOfBusiness.EmptyRef();
								vSourceOfBusinessHasChanged = True;
							EndIf;
						EndIf;
						If vCustomerObj.Modified() Then
							vCustomerObj.Write();
							vCustomerObj.pmWriteToCustomerChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
							
							pChangedItems.ChangedCustomers.Add(vCustomerObj.Ref);
							
							// Update payer active reservations if customer parameters has changed
							If vClientTypeHasChanged Or vDiscountTypeHasChanged Or vMarketingCodeHasChanged Or vSourceOfBusinessHasChanged Then
								vCustomerDocs = GetCustomerActiveReservations(vCustomerObj.Ref);
								For Each vDocRow In vCustomerDocs Do
									vDocObj = vDocRow.Ref.GetObject();
									If vClientTypeHasChanged Then
										vDocObj.ClientType = vCustomerObj.ClientType;
									EndIf;
									If vDiscountTypeHasChanged Then
										vDocObj.DiscountType = vCustomerObj.DiscountType;
									EndIf;
									If vMarketingCodeHasChanged Then
										vDocObj.MarketingCode = vCustomerObj.MarketingCode;
									EndIf;
									If vSourceOfBusinessHasChanged Then
										vDocObj.SourceOfBusiness = vCustomerObj.SourceOfBusiness;
									EndIf;
									vDocObj.pmSetDiscounts();
									vDocObj.Write(DocumentWriteMode.Posting);
									If TypeOf(vDocObj) = Type("DocumentObject.Reservation") Then
										vDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
									Else
										vDocObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
									EndIf;
								EndDo;								
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
			
		// Process customers
		vThereAreChangedCustomers = False;
		For Each vCustomerXDTO In vBIChangesXDTO.Customers.Customer Do
			vThereAreChangedCustomers = True;
			vCustomerRef = Undefined;
			If Not IsBlankString(vCustomerXDTO.CustomerCodeInHotel) Then
				vCustomerRef = GetCustomerByCode(vCustomerXDTO.CustomerCodeInHotel);
			EndIf;
			If ValueIsFilled(vCustomerRef) Then
				If pChangedItems.ChangedCustomers.FindByValue(vCustomerRef) = Undefined Then
					vCustomerObj = vCustomerRef.GetObject();
					If Not IsBlankString(vCustomerXDTO.Remarks) Then
						vCustomerObj.Remarks = vCustomerXDTO.Remarks;
					EndIf;
					vClientTypeHasChanged = False;
					If Not IsBlankString(vCustomerXDTO.ClientTypeCode) Then
						vClientType = Catalogs.ClientTypes.FindByCode(vCustomerXDTO.ClientTypeCode, False);
						If vCustomerObj.ClientType <> vClientType Then
							vCustomerObj.ClientType = vClientType;
							vClientTypeHasChanged = True;
						EndIf;
					Else
						If ValueIsFilled(vCustomerObj.ClientType) Then
							vCustomerObj.ClientType = Catalogs.ClientTypes.EmptyRef();
							vClientTypeHasChanged = True;
						EndIf;
					EndIf;
					vDiscountTypeHasChanged = False;
					If Not IsBlankString(vCustomerXDTO.DiscountTypeCode) Then
						vDiscountType = Catalogs.DiscountTypes.FindByCode(vCustomerXDTO.DiscountTypeCode, False);
						If vCustomerObj.DiscountType <> vDiscountType Then
							vCustomerObj.DiscountType = vDiscountType;
							vDiscountTypeHasChanged = True;
						EndIf;
					Else
						If ValueIsFilled(vCustomerObj.DiscountType) Then
							vCustomerObj.DiscountType = Catalogs.DiscountTypes.EmptyRef();
							vDiscountTypeHasChanged = True;
						EndIf;
					EndIf;
					vMarketingCodeHasChanged = False;
					If Not IsBlankString(vCustomerXDTO.MarketingCodeCode) Then
						vMarketingCode = Catalogs.MarketingCodes.FindByCode(vCustomerXDTO.MarketingCodeCode, False);
						If vCustomerObj.MarketingCode <> vMarketingCode Then
							vCustomerObj.MarketingCode = vMarketingCode;
							vMarketingCodeHasChanged = True;
						EndIf;
					Else
						If ValueIsFilled(vCustomerObj.MarketingCode) Then
							vCustomerObj.MarketingCode = Catalogs.MarketingCodes.EmptyRef();
							vMarketingCodeHasChanged = True;
						EndIf;
					EndIf;
					vSourceOfBusinessHasChanged = False;
					If Not IsBlankString(vCustomerXDTO.SourceOfBusinessCode) Then
						vSourceOfBusiness = Catalogs.SourcesOfBusiness.FindByCode(vCustomerXDTO.SourceOfBusinessCode, False);
						If vCustomerObj.SourceOfBusiness <> vSourceOfBusiness Then
							vCustomerObj.SourceOfBusiness = vSourceOfBusiness;
							vSourceOfBusinessHasChanged = True;
						EndIf;
					Else
						If ValueIsFilled(vCustomerObj.SourceOfBusiness) Then
							vCustomerObj.SourceOfBusiness = Catalogs.SourcesOfBusiness.EmptyRef();
							vSourceOfBusinessHasChanged = True;
						EndIf;
					EndIf;
					If vCustomerObj.Modified() Then
						vCustomerObj.Write();
						vCustomerObj.pmWriteToCustomerChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
							
						pChangedItems.ChangedCustomers.Add(vCustomerObj.Ref);
							
						// Update payer active reservations if customer parameters has changed
						If vClientTypeHasChanged Or vDiscountTypeHasChanged Or vMarketingCodeHasChanged Or vSourceOfBusinessHasChanged Then
							vCustomerDocs = GetCustomerActiveReservations(vCustomerObj.Ref);
							For Each vDocRow In vCustomerDocs Do
								vDocObj = vDocRow.Ref.GetObject();
								If vClientTypeHasChanged Then
									vDocObj.ClientType = vCustomerObj.ClientType;
								EndIf;
								If vDiscountTypeHasChanged Then
									vDocObj.DiscountType = vCustomerObj.DiscountType;
								EndIf;
								If vMarketingCodeHasChanged Then
									vDocObj.MarketingCode = vCustomerObj.MarketingCode;
								EndIf;
								If vSourceOfBusinessHasChanged Then
									vDocObj.SourceOfBusiness = vCustomerObj.SourceOfBusiness;
								EndIf;
								vDocObj.pmSetDiscounts();
								vDocObj.Write(DocumentWriteMode.Posting);
								If TypeOf(vDocObj) = Type("DocumentObject.Reservation") Then
									vDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
								Else
									vDocObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
								EndIf;
							EndDo;								
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		
		// Process discount cards
		vThereAreChangedDiscountCards = False;
		If Not DoNotSyncDiscountCards Then
			For Each vDiscountCardXDTO In vBIChangesXDTO.DiscountCards.DiscountCard Do
				vThereAreChangedDiscountCards = True;
				vDiscountCardRef = Undefined;
				If Not IsBlankString(vDiscountCardXDTO.Identifier) Then
					vDiscountCardRef = GetDiscountCardByIdentifier(vDiscountCardXDTO.Identifier);
				EndIf;
				If Not ValueIsFilled(vDiscountCardRef) And Not IsBlankString(vDiscountCardXDTO.DiscountCardCodeInHotel) Then
					vDiscountCardRef = GetDiscountCardByCode(vDiscountCardXDTO.DiscountCardCodeInHotel);
				EndIf;
				If ValueIsFilled(vDiscountCardRef) Then
					If pChangedItems.ChangedDiscountCards.FindByValue(vDiscountCardRef) = Undefined Then
						vDiscountCardObj = vDiscountCardRef.GetObject();
						If Not IsBlankString(vDiscountCardXDTO.ClientCode) Then
							vDiscountCardClient = GetClientByCode(TrimAll(vDiscountCardXDTO.ClientCode));
							If ValueIsFilled(vDiscountCardClient) And vDiscountCardClient <> vDiscountCardObj.Client Then
								vDiscountCardObj.Client = vDiscountCardClient;
							EndIf;
						EndIf;
						vClientTypeHasChanged = False;
						If Not IsBlankString(vDiscountCardXDTO.ClientTypeCode) Then
							vClientType = Catalogs.ClientTypes.FindByCode(vDiscountCardXDTO.ClientTypeCode, False);
							If vDiscountCardObj.ClientType <> vClientType Then
								vDiscountCardObj.ClientType = vClientType;
								vClientTypeHasChanged = True;
							EndIf;
						Else
							If ValueIsFilled(vDiscountCardObj.ClientType) Then
								vDiscountCardObj.ClientType = Catalogs.ClientTypes.EmptyRef();
								vClientTypeHasChanged = True;
							EndIf;
						EndIf;
						vDiscountTypeHasChanged = False;
						If Not IsBlankString(vDiscountCardXDTO.DiscountTypeCode) Then
							vDiscountType = Catalogs.DiscountTypes.FindByCode(vDiscountCardXDTO.DiscountTypeCode, False);
							If vDiscountCardObj.DiscountType <> vDiscountType Then
								vDiscountCardObj.DiscountType = vDiscountType;
								vDiscountTypeHasChanged = True;
							EndIf;
						Else
							If ValueIsFilled(vDiscountCardObj.DiscountType) Then
								vDiscountCardObj.DiscountType = Catalogs.DiscountTypes.EmptyRef();
								vDiscountTypeHasChanged = True;
							EndIf;
						EndIf;
						If vDiscountCardObj.Modified() Then
							vDiscountCardObj.Write();
							
							pChangedItems.ChangedDiscountCards.Add(vDiscountCardObj.Ref);
							
							If vClientTypeHasChanged Or vDiscountTypeHasChanged Then
								vUpdateOneRoomGuests = True;
								If vClientTypeHasChanged Then
									If ValueIsFilled(vDiscountCardObj.ClientType) And vDiscountCardObj.ClientType.Mode = Enums.ClientTypeModes.PerClient Then
										vUpdateOneRoomGuests = False;
									EndIf;
								EndIf;
								If ValueIsFilled(vDiscountCardObj.Client) Then
									vClientDocs = GetGuestActiveReservations(vDiscountCardObj.Client);
									For Each vDocRow In vClientDocs Do
										If Not vUpdateOneRoomGuests And vDocRow.Guest <> vDiscountCardObj.Client Then
											Continue;
										EndIf;
										vDocObj = vDocRow.Ref.GetObject();
										If vClientTypeHasChanged Then
											vDocObj.ClientType = vDiscountCardObj.ClientType;
										EndIf;
										If vDiscountTypeHasChanged Then
											vDocObj.DiscountType = vDiscountCardObj.DiscountType;
										EndIf;
										vDocObj.pmSetDiscounts();
										vDocObj.Write(DocumentWriteMode.Posting);
										If TypeOf(vDocObj) = Type("DocumentObject.Reservation") Then
											vDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
										Else
											vDocObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
										EndIf;
									EndDo;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		
		// Client information types
		If vBIChangesXDTO.ClientInformationTypes <> Undefined Then
			For Each vClientInformationTypesXDTO In vBIChangesXDTO.ClientInformationTypes.ClientInformationType Do			
				vClientInformationTypeRef = Catalogs.ClientInformationTypes.FindByCode(vClientInformationTypesXDTO.Code, False);		
				If Not ValueIsFilled(vClientInformationTypeRef) Then
					If vClientInformationTypesXDTO.IsFolder Then 			
						vClientInformationTypeObj = Catalogs.ClientInformationTypes.CreateFolder();					
					Else
						vClientInformationTypeObj = Catalogs.ClientInformationTypes.CreateItem();
					EndIf;
					vClientInformationTypeObj.Code = vClientInformationTypesXDTO.Code;
				Else
					vClientInformationTypeObj = vClientInformationTypeRef.GetObject();
				EndIf;
				vClientInformationTypeObj.Description = vClientInformationTypesXDTO.Description;
				If ValueIsFilled(vClientInformationTypesXDTO.ParentID) Then
					VParent = Catalogs.ClientInformationTypes.FindByCode(vClientInformationTypesXDTO.ParentID, False);
					If ValueIsFilled(VParent) Then
						vClientInformationTypeObj.Parent = VParent;
					EndIf;
				EndIf;
				For Each vChoiceValuesRow In vClientInformationTypesXDTO.ChoiceValues Do
					vClientInformationTypeObj.ChoiceValues.Clear();
					vNewChoiceValuesRow = vClientInformationTypeObj.ChoiceValues.Add();
					vNewChoiceValuesRow.ChoiceValue = vChoiceValuesRow;
				EndDo;
				vClientInformationTypeObj.Write();
			EndDo;
		EndIf;
		
		If Not vThereAreChangedClients And Not vThereAreChangedCustomers And Not vThereAreChangedDiscountCards Then
			Break;
		Else
			If vBIChangesXDTO.LastChangeDate <> Undefined And TypeOf(vBIChangesXDTO.LastChangeDate) = Type("Date") And 
			   vBIChangesXDTO.LastChangeDate > vReadChangesFromDate And vBIChangesXDTO.LastChangeDate <= pCurrentSyncDate Then
				vReadChangesFromDate = vBIChangesXDTO.LastChangeDate;
			Else
				Break;
			EndIf;
		EndIf;
	EndDo;
	
	WriteLogEvent(NStr("en = 'Read changes from 1C:Hotel BI'; de = 'Änderungen Lesen von 1C:Hotel BI'; ru = 'Чтение изменений из системы 1С:Отель BI'"), EventLogLevel.Information, , , "End");
EndProcedure // GetChangedItems

// -----------------------------------------------------------------------------
Procedure GetClientInformationTypesFromBI(pHotelBIProxy, Val pLastSyncDate)
	vReadChangesFromDate = pLastSyncDate;
	vClientInformationTypesXDTO = pHotelBIProxy.GetClientInformationTypes(TrimAll(Hotel.Code), vReadChangesFromDate);
	// Client information types
	If vClientInformationTypesXDTO <> Undefined Then
		For Each vClientInformationTypesXDTO In vClientInformationTypesXDTO.ClientInformationType Do
			vClientInformationTypeRef = Catalogs.ClientInformationTypes.FindByCode(vClientInformationTypesXDTO.Code, False);		
			If Not ValueIsFilled(vClientInformationTypeRef) Then
				If vClientInformationTypesXDTO.IsFolder Then 			
					vClientInformationTypeObj = Catalogs.ClientInformationTypes.CreateFolder();					
				Else
					vClientInformationTypeObj = Catalogs.ClientInformationTypes.CreateItem();
				EndIf;
				vClientInformationTypeObj.Code = vClientInformationTypesXDTO.Code;
			Else
				vClientInformationTypeObj = vClientInformationTypeRef.GetObject();
			EndIf;
			vClientInformationTypeObj.Description = vClientInformationTypesXDTO.Description;
			If ValueIsFilled(vClientInformationTypesXDTO.ParentID) Then
				VParent = Catalogs.ClientInformationTypes.FindByCode(vClientInformationTypesXDTO.ParentID, False);
				If ValueIsFilled(VParent) Then
					vClientInformationTypeObj.Parent = VParent;
				EndIf;
			EndIf;
			For Each vChoiceValuesRow In vClientInformationTypesXDTO.ChoiceValues Do
				vClientInformationTypeObj.ChoiceValues.Clear();
				vNewChoiceValuesRow = vClientInformationTypeObj.ChoiceValues.Add();
				vNewChoiceValuesRow.ChoiceValue = vChoiceValuesRow;
			EndDo;
			vClientInformationTypeObj.Write();
		EndDo;
	EndIf;
	WriteLogEvent(NStr("en = 'Read changes from 1C:Hotel BI'; de = 'Änderungen Lesen von 1C:Hotel BI'; ru = 'Чтение изменений из системы 1С:Отель BI'"), EventLogLevel.Information, , , "End");
EndProcedure // GetClientInformationTypesFromBI

// -----------------------------------------------------------------------------
Procedure GetMergedItems(pHotelBIProxy, Val pLastSyncDate, Val pCurrentSyncDate)
	WriteLogEvent(NStr("en = 'Get merged items from 1C:Hotel BI'; de = 'Zusammengeführte Elementen erhalten von 1C:Hotel BI'; ru = 'Получение объединенных элементов из системы 1С:Отель BI'"), EventLogLevel.Information, , , "Start read merge operations from " + pLastSyncDate + " to " + pCurrentSyncDate);
	
	vBIMergedClientsXDTO = pHotelBIProxy.ReadMergedItems(TrimAll(Hotel.Code), pLastSyncDate, pCurrentSyncDate);
	
	// Process merged clients
	For Each vMergedClientsPairXDTO In vBIMergedClientsXDTO.MergedClients.MergedClientsPair Do
		If vMergedClientsPairXDTO.MergedClient <> Undefined And vMergedClientsPairXDTO.Client <> Undefined Then
			vClientRef = Undefined;
			vMergedClientRef = Undefined;
			If Not IsBlankString(vMergedClientsPairXDTO.Client.ClientCodeInHotel) Then
				vClientRef = GetClientByCode(vMergedClientsPairXDTO.Client.ClientCodeInHotel);
				If Not ValueIsFilled(vClientRef) Then
					WriteLogEvent(NStr("en = 'Merge clients'; de = 'Zusammengeführte Kunden'; ru = 'Объединение клиентов'"), EventLogLevel.Warning, , , TrimAll(vMergedClientsPairXDTO.Client.FullName) + " (" + TrimAll(vMergedClientsPairXDTO.Client.Code) + ") - " + NStr("en='client not found in hotel by code '; ru='клиент не найден в отеле по коду '; de='client not found in hotel by code '") + TrimAll(vMergedClientsPairXDTO.Client.ClientCodeInHotel));
				EndIf;
			Else
				WriteLogEvent(NStr("en = 'Merge clients'; de = 'Zusammengeführte Kunden'; ru = 'Объединение клиентов'"), EventLogLevel.Warning, , , TrimAll(vMergedClientsPairXDTO.Client.FullName) + " (" + TrimAll(vMergedClientsPairXDTO.Client.Code) + ") - " + NStr("en='client hotel code is empty!'; ru='у клиента не указан код в отеле!'; de='client hotel code is empty!'"));
			EndIf;
			If Not IsBlankString(vMergedClientsPairXDTO.MergedClient.ClientCodeInHotel) Then
				vMergedClientRef = GetClientByCode(vMergedClientsPairXDTO.MergedClient.ClientCodeInHotel);
				If Not ValueIsFilled(vMergedClientRef) Then
					WriteLogEvent(NStr("en = 'Merge clients'; de = 'Zusammengeführte Kunden'; ru = 'Объединение клиентов'"), EventLogLevel.Warning, , , TrimAll(vMergedClientsPairXDTO.MergedClient.FullName) + " (" + TrimAll(vMergedClientsPairXDTO.MergedClient.Code) + ") - " + NStr("en='client not found in hotel by code '; ru='клиент не найден в отеле по коду '; de='client not found in hotel by code '") + TrimAll(vMergedClientsPairXDTO.MergedClient.ClientCodeInHotel));
				EndIf;
			Else
				WriteLogEvent(NStr("en = 'Merge clients'; de = 'Zusammengeführte Kunden'; ru = 'Объединение клиентов'"), EventLogLevel.Warning, , , TrimAll(vMergedClientsPairXDTO.MergedClient.FullName) + " (" + TrimAll(vMergedClientsPairXDTO.MergedClient.Code) + ") - " + NStr("en='client hotel code is empty!'; ru='у клиента не указан код в отеле!'; de='client hotel code is empty!'"));
			EndIf;
			If ValueIsFilled(vClientRef) And ValueIsFilled(vMergedClientRef) And vClientRef <> vMergedClientRef Then
				WriteLogEvent(NStr("en = 'Merge clients'; de = 'Zusammengeführte Kunden'; ru = 'Объединение клиентов'"), EventLogLevel.Information, , , TrimAll(vMergedClientRef.FullName) + " (" + TrimAll(vMergedClientRef.Code) + ") -> " + TrimAll(vClientRef.FullName) + " (" + TrimAll(vClientRef.Code) + ")");
				Try
					cmMergeClients(vClientRef, vMergedClientRef);
				Except
					vErrorDescription = ErrorDescription();
					WriteLogEvent(NStr("en = 'Merge clients'; de = 'Zusammengeführte Kunden'; ru = 'Объединение клиентов'"), EventLogLevel.Error, , , vErrorDescription);
				EndTry;
			EndIf;
		EndIf;
	EndDo;
	
	WriteLogEvent(NStr("en = 'Get merged items from 1C:Hotel BI'; de = 'Zusammengeführte Elementen erhalten von 1C:Hotel BI'; ru = 'Получение объединенных элементов из системы 1С:Отель BI'"), EventLogLevel.Information, , , "End");
EndProcedure // GetMergedItems

// -----------------------------------------------------------------------------
Function GetAllDiscountTypes() 
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	*
	|FROM
	|	Catalog.DiscountTypes AS DiscountTypes
	|WHERE
	|	(NOT DiscountTypes.DeletionMark
	|				AND NOT DiscountTypes.IsFolder
	|				AND NOT &qHotelIsEmptyRef
	|				AND (DiscountTypes.Hotel = &qHotel
	|					OR DiscountTypes.Hotel = &qEmptyHotel)
	|			OR &qHotelIsEmptyRef)
	|
	|ORDER BY
	|	DiscountTypes.SortCode,
	|	DiscountTypes.Description";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmptyRef", ?(Hotel = Catalogs.Hotels.EmptyRef(), True, False));
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vElements = vQry.Execute().Unload();
	Return vElements;
EndFunction // GetAllDiscountTypes

// -----------------------------------------------------------------------------
Function GetAllInformationsClientTypes() 
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ClientInformationTypes.IsFolder AS IsFolder,
	|	ClientInformationTypes.Code AS Code,
	|	ClientInformationTypes.Description AS Description,
	|	ClientInformationTypes.Parent.Code AS ParentCode,
	|	ClientInformationTypes.ChoiceValues.(
	|		ChoiceValue AS ChoiceValue
	|	) AS ChoiceValues
	|FROM
	|	Catalog.ClientInformationTypes AS ClientInformationTypes
	|
	|ORDER BY
	|	ClientInformationTypes.Ref HIERARCHY";
	vElements = vQry.Execute().Unload();
	Return vElements;
EndFunction // GetAllDiscountTypes

// -----------------------------------------------------------------------------
Function GetClientInformations(pPeriod) 
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ClientsInformation.Period AS Period,
	|	ClientsInformation.Remarks AS Remarks,
	|	ClientsInformation.RemarksAuthor AS RemarksAuthor,
	|	ClientsInformation.ActionTaken AS ActionTaken,
	|	ClientsInformation.ActionAuthor AS ActionAuthor,
	|	ClientsInformation.ActionDate AS ActionDate,
	|	ClientsInformation.Client.Code AS ClientCode,
	|	ClientsInformation.InformationType.Code AS InformationTypeCode,
	|	ClientsInformation.Hotel.Code AS HotelCode
	|FROM
	|	InformationRegister.ClientsInformation AS ClientsInformation
	|WHERE
	|	ClientsInformation.Period >= &qPeriod";
	vQry.SetParameter("qPeriod", pPeriod);
	
	vElements = vQry.Execute().Unload();
	Return vElements;
EndFunction 

// -----------------------------------------------------------------------------
Procedure GetClientInformationsFromBI(pHotelBIProxy, Val pLastSyncDate)
	vReadChangesFromDate = pLastSyncDate;
	
	vClientInformationXDTO = pHotelBIProxy.GetClientInformations(TrimAll(Hotel.Code), vReadChangesFromDate);
	For Each vClientInformation In vClientInformationXDTO.ClientInformation Do
		vRecordMan = InformationRegisters.ClientsInformation.CreateRecordManager();
		FillPropertyValues(vRecordMan, vClientInformation);		
		vRecordMan.Client          = Catalogs.Clients.FindByCode(vClientInformation.ClientId);
		vRecordMan.Hotel           = Catalogs.Hotels.FindByCode(vClientInformation.HotelID);
		vRecordMan.InformationType = Catalogs.ClientInformationTypes.FindByCode(vClientInformation.InformationTypeId);
		If ValueIsFilled(vRecordMan.Client) Then
			vRecordMan.Write();
		EndIf;	
	EndDo;
	
	WriteLogEvent(NStr("en = 'Read changes from 1C:Hotel BI'; de = 'Änderungen Lesen von 1C:Hotel BI'; ru = 'Чтение изменений из системы 1С:Отель BI'"), EventLogLevel.Information, , , "End");
EndProcedure// GetClientInformationsFromBI

// -----------------------------------------------------------------------------
Function GetAllClientTypes() 
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	*
	|FROM
	|	Catalog.ClientTypes AS ClientTypes
	|WHERE
	|	NOT ClientTypes.DeletionMark
	|	AND NOT ClientTypes.IsFolder
	|	AND NOT &qHotelIsEmptyRef AND (ClientTypes.Hotel = &qHotel
	|			OR ClientTypes.Hotel = &qEmptyHotel) OR &qHotelIsEmptyRef
	|
	|ORDER BY
	|	SortCode,
	|	Description";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmptyRef", ?(Hotel = Catalogs.Hotels.EmptyRef(), True, False));
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vElements = vQry.Execute().Unload();
	Return vElements;
EndFunction // GetAllClientTypes

// -----------------------------------------------------------------------------
Function GetAllMarketingCodes() 
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	*
	|FROM
	|	Catalog.MarketingCodes AS MarketingCodes
	|WHERE
	|	(NOT MarketingCodes.DeletionMark
	|				AND NOT MarketingCodes.IsFolder
	|				AND NOT &qHotelIsEmptyRef
	|				AND (MarketingCodes.Hotel = &qHotel
	|					OR MarketingCodes.Hotel = &qEmptyHotel)
	|			OR &qHotelIsEmptyRef)
	|
	|ORDER BY
	|	MarketingCodes.SortCode,
	|	MarketingCodes.Description";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmptyRef", ?(Hotel = Catalogs.Hotels.EmptyRef(), True, False));
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vElements = vQry.Execute().Unload();
	Return vElements;
EndFunction // GetAllMarketingCodes

// -----------------------------------------------------------------------------
Function GetAllSourcesOfBusiness() 
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	*
	|FROM
	|	Catalog.SourcesOfBusiness AS SourcesOfBusiness
	|WHERE
	|	NOT SourcesOfBusiness.DeletionMark
	|	AND NOT SourcesOfBusiness.IsFolder
	|
	|ORDER BY
	|	SourcesOfBusiness.SortCode,
	|	SourcesOfBusiness.Description";
	vElements = vQry.Execute().Unload();
	Return vElements;
EndFunction // GetAllSourcesOfBusiness

// -----------------------------------------------------------------------------
Function GetAllLanguages() 
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	*
	|FROM
	|	Catalog.Languages AS Languages
	|WHERE
	|	NOT Languages.DeletionMark
	|
	|ORDER BY
	|	Languages.Code,
	|	Languages.Description";
	vElements = vQry.Execute().Unload();
	Return vElements;
EndFunction // GetAllLanguages

// -----------------------------------------------------------------------------
Function GetAllCurrencies() 
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	*
	|FROM
	|	Catalog.Currencies AS Currencies
	|WHERE
	|	NOT Currencies.DeletionMark
	|
	|ORDER BY
	|	Currencies.Code,
	|	Currencies.Description";
	vElements = vQry.Execute().Unload();
	Return vElements;
EndFunction // GetAllCurrencies

// -----------------------------------------------------------------------------
Procedure SendCatalogs(vHotelBIProxy, pSendLogs)
	WriteLogEvent(NStr("en='Catalogs synchronization with 1C:Hotel BI';ru='Синхронизация справочников с системой 1С:Отель BI';de='Der Katalogen Synchronisation mit 1C:Hotel BI'"), EventLogLevel.Information, , , "Start");
	
	// Hotel
	vHotelXDTO = vHotelBIProxy.XDTOFactory.Create(vHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "Hotel"));
	FillPropertyValues(vHotelXDTO, Hotel);
	// Catalogs
	vCatalogsXDTO = vHotelBIProxy.XDTOFactory.Create(vHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "Catalogs"));
	
	// Discount types
	vDiscountTypesXDTO = vHotelBIProxy.XDTOFactory.Create(vHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "DiscountTypes"));
	vDiscountTypes = GetAllDiscountTypes();
	SendLogs(NStr("en='	Exporting ""Discount types"" - '; ru='	Выгружаем ""Типы скидок"" - '; de='	Exporting ""Discount types"" - '") + vDiscountTypes.Count(), pSendLogs);
	For Each vDiscountTypesRow In vDiscountTypes Do
		vDiscountTypeXDTO = vHotelBIProxy.XDTOFactory.Create(vHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "DiscountType"));
		FillPropertyValues(vDiscountTypeXDTO, vDiscountTypesRow, , "DiscountServiceGroup, RoundPriceType, AccumulatingDiscountType, ExternalAlgorithm, AccumulatingDiscountDimension");
		vDiscountTypeXDTO.DiscountServiceGroup = TrimAll(vDiscountTypesRow.DiscountServiceGroup);
		vDiscountTypeXDTO.RoundPriceType = TrimAll(vDiscountTypesRow.RoundPriceType);
		vDiscountTypeXDTO.AccumulatingDiscountType = TrimAll(vDiscountTypesRow.AccumulatingDiscountType);
		vDiscountTypeXDTO.ExternalAlgorithm = TrimAll(vDiscountTypesRow.ExternalAlgorithm);
		vDiscountTypeXDTO.AccumulatingDiscountDimension = TrimAll(vDiscountTypesRow.AccumulatingDiscountDimension);
		If ValueIsFilled(vDiscountTypesRow.Hotel) Then
			vDiscountTypeXDTO.HotelCode = TrimAll(vDiscountTypesRow.Hotel.Code);
		Else
			vDiscountTypeXDTO.HotelCode = "";
		EndIf;
		vDiscountTypesXDTO.DiscountType.Add(vDiscountTypeXDTO);
	EndDo;
	
	// Client types
	vClientTypesXDTO = vHotelBIProxy.XDTOFactory.Create(vHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "ClientTypes"));
	vClientTypes = GetAllClientTypes();
	SendLogs(NStr("en='	Exporting ""Client types"" - '; ru='	Выгружаем ""Типы клиентов"" - '; de='	Exporting ""Client types"" - '") + vClientTypes.Count(), pSendLogs);
	For Each vClientTypesRow In vClientTypes Do
		vClientTypeXDTO = vHotelBIProxy.XDTOFactory.Create(vHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "ClientType"));
		FillPropertyValues(vClientTypeXDTO, vClientTypesRow, , "PaymentSection, Mode, Color");
		vClientTypeXDTO.PaymentSection = TrimAll(vClientTypesRow.PaymentSection);
		vClientTypeXDTO.Mode = TrimAll(vClientTypesRow.Mode);
		If ValueIsFilled(vClientTypesRow.DiscountType) Then
			vClientTypeXDTO.DiscountTypeCode = TrimAll(vClientTypesRow.DiscountType.Code);
		Else
			vClientTypeXDTO.DiscountTypeCode = "";
		EndIf;
		If ValueIsFilled(vClientTypesRow.Hotel) Then
			vClientTypeXDTO.HotelCode = TrimAll(vClientTypesRow.Hotel.Code);
		Else
			vClientTypeXDTO.HotelCode = "";
		EndIf;
		If vClientTypesRow.Color <> Undefined Then
			vColor = vClientTypesRow.Color.Get();
			If vColor <> Undefined And TypeOf(vColor) = Type("Color") Then
				vClientTypeXDTO.Color = ValueToStringInternal(vColor);
			Else
				vClientTypeXDTO.Color = "";
			EndIf;
		Else
			vClientTypeXDTO.Color = "";
		EndIf;
		vClientTypesXDTO.ClientType.Add(vClientTypeXDTO);
	EndDo;
	
	// Marketing codes
	vMarketingCodesXDTO = vHotelBIProxy.XDTOFactory.Create(vHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "MarketingCodes"));
	vMarketingCodes = GetAllMarketingCodes();
	SendLogs(NStr("en='	Exporting ""Marketing codes"" - '; ru='	Выгружаем ""Направления маркетинга"" - '; de='	Exporting ""Marketing codes"" - '") + vMarketingCodes.Count(), pSendLogs);
	For Each vMarketingCodesRow In vMarketingCodes Do
		vMarketingCodeXDTO = vHotelBIProxy.XDTOFactory.Create(vHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "MarketingCode"));
		FillPropertyValues(vMarketingCodeXDTO, vMarketingCodesRow);
		If ValueIsFilled(vMarketingCodesRow.DiscountType) Then
			vMarketingCodeXDTO.DiscountTypeCode = TrimAll(vMarketingCodesRow.DiscountType.Code);
		Else
			vMarketingCodeXDTO.DiscountTypeCode = "";
		EndIf;
		If ValueIsFilled(vMarketingCodesRow.Hotel) Then
			vMarketingCodeXDTO.HotelCode = TrimAll(vMarketingCodesRow.Hotel.Code);
		Else
			vMarketingCodeXDTO.HotelCode = "";
		EndIf;
		vMarketingCodesXDTO.MarketingCode.Add(vMarketingCodeXDTO);
	EndDo;
	
	// Sources of business
	vSourcesOfBusinessXDTO = vHotelBIProxy.XDTOFactory.Create(vHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "SourcesOfBusiness"));
	vSourcesOfBusiness = GetAllSourcesOfBusiness();
	SendLogs(NStr("en='	Exporting ""Sources of business"" - '; ru='	Выгружаем ""Источники информации о гостинице"" - '; de='	Exporting ""Sources of business"" - '") + vSourcesOfBusiness.Count(), pSendLogs);
	For Each vSourcesOfBusinessRow In vSourcesOfBusiness Do
		vSourceOfBusinessXDTO = vHotelBIProxy.XDTOFactory.Create(vHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "SourceOfBusiness"));
		FillPropertyValues(vSourceOfBusinessXDTO, vSourcesOfBusinessRow);
		vSourcesOfBusinessXDTO.SourceOfBusiness.Add(vSourceOfBusinessXDTO);
	EndDo;
	
	// Languages
	vLanguagesXDTO = vHotelBIProxy.XDTOFactory.Create(vHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "Languages"));
	vLanguages = GetAllLanguages();
	SendLogs(NStr("en='	Exporting ""Languages"" - '; ru='	Выгружаем ""Языки"" - '; de='	Exporting ""Languages"" - '") + vLanguages.Count(), pSendLogs);
	For Each vLanguagesRow In vLanguages Do
		vLanguageXDTO = vHotelBIProxy.XDTOFactory.Create(vHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "Language"));
		FillPropertyValues(vLanguageXDTO, vLanguagesRow);
		vLanguagesXDTO.Language.Add(vLanguageXDTO);
	EndDo;
	
	// Currencies
	vCurrenciesXDTO = vHotelBIProxy.XDTOFactory.Create(vHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "Currencies"));
	vCurrencies = GetAllCurrencies();
	SendLogs(NStr("en='	Exporting ""Currencies"" - '; ru='	Выгружаем ""Валюты"" - '; de='	Exporting ""Currencies"" - '") + vCurrencies.Count(), pSendLogs);
	For Each vCurrenciesRow In vCurrencies Do
		vCurrencyXDTO = vHotelBIProxy.XDTOFactory.Create(vHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "Currency"));
		FillPropertyValues(vCurrencyXDTO, vCurrenciesRow, , "SumInWordsAttributes");
		vSumInWordsAttributesXDTO = vHotelBIProxy.XDTOFactory.Create(vHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "SumInWordsAttributes"));
		For Each vSumInWordAttrRow In vCurrenciesRow.Ref.SumInWordsAttributes Do 
			vSumInWordsAttributeXDTO = vHotelBIProxy.XDTOFactory.Create(vHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "SumInWordsAttribute"));
			FillPropertyValues(vSumInWordsAttributeXDTO, vSumInWordAttrRow);
			If ValueIsFilled(vSumInWordAttrRow.Language) Then
				vSumInWordsAttributeXDTO.LanguageCode = TrimAll(vSumInWordAttrRow.Language.Code);
			Else
				vSumInWordsAttributeXDTO.LanguageCode = "";
			EndIf;
			vSumInWordsAttributesXDTO.SumInWordsAttribute.Add(vSumInWordsAttributeXDTO);
		EndDo;
		vCurrencyXDTO.SumInWordsAttributes = vSumInWordsAttributesXDTO;
		vCurrenciesXDTO.Currency.Add(vCurrencyXDTO);
	EndDo;
	
	// Client information types
	vClientInformationTypesXDTO = vHotelBIProxy.XDTOFactory.Create(vHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "ClientInformationTypes"));
	vClientInformationTypes = GetAllInformationsClientTypes();
	SendLogs(NStr("en='	Exporting ""Client information types"" - '; ru='	Выгружаем ""Типы информации по клиентам"" - '; de='	Exporting ""Client information types"" - '") + vClientInformationTypes.Count(), pSendLogs);
	For Each vClientInformationTypesRow In vClientInformationTypes Do
		vClientInformationTypeXDTO = vHotelBIProxy.XDTOFactory.Create(vHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "ClientInformationType"));
		vClientInformationTypeXDTO.Code        = vClientInformationTypesRow.Code;
		vClientInformationTypeXDTO.IsFolder    = vClientInformationTypesRow.IsFolder;
		vClientInformationTypeXDTO.Description = vClientInformationTypesRow.Description;
		If ValueIsFilled(vClientInformationTypesRow.ParentCode) Then
			vClientInformationTypeXDTO.ParentID    = vClientInformationTypesRow.ParentCode;
		EndIf;
		For Each vChoiceValues In vClientInformationTypesRow.ChoiceValues Do
			vClientInformationTypeXDTO.ChoiceValues.Add(vChoiceValues.ChoiceValue);
		EndDo;
		vClientInformationTypesXDTO.ClientInformationType.Add(vClientInformationTypeXDTO);
	EndDo;
	
	// Fill XDTO
	vCatalogsXDTO.DiscountTypes           = vDiscountTypesXDTO;
	vCatalogsXDTO.ClientTypes             = vClientTypesXDTO;
	vCatalogsXDTO.MarketingCodes          = vMarketingCodesXDTO;
	vCatalogsXDTO.SourcesOfBusiness       = vSourcesOfBusinessXDTO;
	vCatalogsXDTO.Languages               = vLanguagesXDTO;
	vCatalogsXDTO.Currencies              = vCurrenciesXDTO;
	vCatalogsXDTO.ClientInformationTypes  = vClientInformationTypesXDTO;
	
	// Call web-service
	vResult = vHotelBIProxy.CatalogsSync(vHotelXDTO, vCatalogsXDTO);
	
	WriteLogEvent(NStr("en='Catalogs synchronization with 1C:Hotel BI';ru='Синхронизация справочников с системой 1С:Отель BI';de='Der Katalogen Synchronisation mit 1C:Hotel BI'"), EventLogLevel.Information, , , "End");
EndProcedure // SendCatalogs

// -----------------------------------------------------------------------------
Procedure SendClientInformation(pHotelBIProxy, pPeriod)
	WriteLogEvent(NStr("en='Catalogs synchronization with 1C:Hotel BI';ru='Синхронизация справочников с системой 1С:Отель BI';de='Der Katalogen Synchronisation mit 1C:Hotel BI'"), EventLogLevel.Information, , , "Start");
	
	// Hotel
	vHotelXDTO = Hotel.Code;
	
	// Catalogs
	vClientInformationsXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "ClientInformations"));
	vClientInformations = GetClientInformations(pPeriod);
	
	For Each vClientInformation In vClientInformations Do
		vClientInformationXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "ClientInformation"));
		vClientInformationXDTO.Period              = vClientInformation.Period;
		vClientInformationXDTO.HotelId             = String(vClientInformation.HotelCode);
		vClientInformationXDTO.ClientId            = String(vClientInformation.ClientCode);
		vClientInformationXDTO.InformationTypeID   = String(vClientInformation.InformationTypeCode);	
		vClientInformationXDTO.Remarks		       = vClientInformation.Remarks;
		vClientInformationXDTO.RemarksAuthor	   = vClientInformation.RemarksAuthor;		
		vClientInformationXDTO.ActionTaken         = vClientInformation.ActionTaken;
		vClientInformationXDTO.ActionAuthor        = vClientInformation.ActionAuthor;
		vClientInformationXDTO.ActionDate		   = vClientInformation.ActionDate;
		
		vClientInformationsXDTO.ClientInformation.Add(vClientInformationXDTO);
	EndDo;
		
	// Call web-service
	vResult = pHotelBIProxy.ClientInformationSync(vHotelXDTO, vClientInformationsXDTO);
	
	WriteLogEvent(NStr("en='Catalogs synchronization with 1C:Hotel BI';ru='Синхронизация справочников с системой 1С:Отель BI';de='Der Katalogen Synchronisation mit 1C:Hotel BI'"), EventLogLevel.Information, , , "End");
EndProcedure // SendClientInformation

// -----------------------------------------------------------------------------
Function GetSales(pPeriodFrom, pPeriodTo, pLastSyncDate, pCurrentSyncDate)
	vQry = New Query();
	If FullSync Then
		vQry.Text = 
		"SELECT
		|	SalesBI.Period AS Period,
		|	SalesBI.Recorder AS Recorder,
		|	SalesBI.LineNumber AS LineNumber,
		|	SalesBI.Active AS Active,
		|	SalesBI.AccountingDate AS AccountingDate,
		|	SalesBI.GuestGroup AS GuestGroup,
		|	SalesBI.Customer AS Customer,
		|	SalesBI.Contract AS Contract,
		|	SalesBI.Agent AS Agent,
		|	SalesBI.Client AS Client,
		|	SalesBI.Service AS Service,
		|	SalesBI.RoomRate AS RoomRate,
		|	SalesBI.Room AS Room,
		|	SalesBI.RoomType AS RoomType,
		|	SalesBI.Resource AS Resource,
		|	SalesBI.Company AS Company,
		|	SalesBI.Hotel AS Hotel,
		|	SalesBI.Folio AS Folio,
		|	SalesBI.ParentDoc AS ParentDoc,
		|	ISNULL(SalesBI.ParentDoc.Date, &qEmptyDate) AS ParentDocDate,
		|	SalesBI.ParentDoc.Reservation AS Reservation,
		|	ISNULL(SalesBI.ParentDoc.Reservation.Date, &qEmptyDate) AS ReservationDate,
		|	CASE
		|		WHEN SalesBI.ParentDoc.CheckInDate IS NULL
		|			THEN SalesBI.ParentDoc.DateTimeFrom
		|		ELSE SalesBI.ParentDoc.CheckInDate
		|	END AS CheckInDate,
		|	ISNULL(SalesBI.ParentDoc.Duration, 0) AS Duration,
		|	CASE
		|		WHEN SalesBI.ParentDoc.CheckOutDate IS NULL
		|			THEN SalesBI.ParentDoc.DateTimeTo
		|		ELSE SalesBI.ParentDoc.CheckOutDate
		|	END AS CheckOutDate,
		|	CASE
		|		WHEN NOT SalesBI.ParentDoc.ReservationStatus IS NULL
		|			THEN SalesBI.ParentDoc.ReservationStatus
		|		WHEN NOT SalesBI.ParentDoc.ResourceReservationStatus IS NULL
		|			THEN SalesBI.ParentDoc.ResourceReservationStatus
		|		ELSE SalesBI.ParentDoc.AccommodationStatus
		|	END AS ReservationStatus,
		|	SalesBI.ParentDoc.RoomQuota AS RoomQuota,
		|	SalesBI.Price AS Price,
		|	SalesBI.ResourceType AS ResourceType,
		|	SalesBI.AccommodationType AS AccommodationType,
		|	SalesBI.ClientType AS ClientType,
		|	SalesBI.TripPurpose AS TripPurpose,
		|	SalesBI.MarketingCode AS MarketingCode,
		|	SalesBI.SourceOfBusiness AS SourceOfBusiness,
		|	SalesBI.CalendarDayType AS CalendarDayType,
		|	SalesBI.PriceTag AS PriceTag,
		|	SalesBI.HotelProduct AS HotelProduct,
		|	SalesBI.Author AS Author,
		|	SalesBI.Discount AS Discount,
		|	SalesBI.DiscountType AS DiscountType,
		|	SalesBI.DiscountCard AS DiscountCard,
		|	SalesBI.AgentCommission AS AgentCommission,
		|	SalesBI.AgentCommissionType AS AgentCommissionType,
		|	SalesBI.PaymentMethod AS PaymentMethod,
		|	SalesBI.VATRate AS VATRate,
		|	ISNULL(SalesBI.VATRate.TaxRate, 0) AS TaxRate,
		|	SalesBI.ReportingCurrency AS ReportingCurrency,
		|	SalesBI.Sales AS Sales,
		|	SalesBI.SalesWithoutVAT AS SalesWithoutVAT,
		|	SalesBI.RoomRevenue AS RoomRevenue,
		|	SalesBI.RoomRevenueWithoutVAT AS RoomRevenueWithoutVAT,
		|	SalesBI.ExtraBedRevenue AS ExtraBedRevenue,
		|	SalesBI.ExtraBedRevenueWithoutVAT AS ExtraBedRevenueWithoutVAT,
		|	SalesBI.CommissionSum AS CommissionSum,
		|	SalesBI.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
		|	SalesBI.DiscountSum AS DiscountSum,
		|	SalesBI.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
		|	SalesBI.RoomsRented AS RoomsRented,
		|	SalesBI.BedsRented AS BedsRented,
		|	SalesBI.AdditionalBedsRented AS AdditionalBedsRented,
		|	SalesBI.GuestDays AS GuestDays,
		|	SalesBI.GuestsCheckedIn AS GuestsCheckedIn,
		|	SalesBI.RoomsCheckedIn AS RoomsCheckedIn,
		|	SalesBI.BedsCheckedIn AS BedsCheckedIn,
		|	SalesBI.AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn,
		|	SalesBI.BookingWindow AS BookingWindow,
		|	SalesBI.ResourceRevenue AS ResourceRevenue,
		|	SalesBI.ResourceRevenueWithoutVAT AS ResourceRevenueWithoutVAT,
		|	SalesBI.HoursRented AS HoursRented,
		|	SalesBI.Quantity AS Quantity,
		|	SalesBI.VATSum AS VATSum,
		|	SalesBI.IsStorno AS IsStorno,
		|	SalesBI.RateSum AS RateSum,
		|	SalesBI.NumberOfBedsPerRoom AS NumberOfBedsPerRoom,
		|	SalesBI.NumberOfPersonsPerRoom AS NumberOfPersonsPerRoom,
		|	SalesBI.NumberOfAdditionalBeds AS NumberOfAdditionalBeds,
		|	SalesBI.NumberOfBeds AS NumberOfBeds,
		|	SalesBI.NumberOfPersons AS NumberOfPersons,
		|	SalesBI.NumberOfRooms AS NumberOfRooms,
		|	SalesBI.RoomRateType AS RoomRateType,
		|	SalesBI.TimeFrom AS TimeFrom,
		|	SalesBI.TimeTo AS TimeTo,
		|	ISNULL(SalesBI.Recorder.Remarks, &qEmptyString) AS Remarks,
		|	ISNULL(SalesBI.Recorder.Details, &qEmptyString) AS Details,
		|	SalesBI.PointInTime AS PointInTime
		|FROM
		|	AccumulationRegister.Sales AS SalesBI
		|WHERE
		|	SalesBI.Hotel = &qHotel
		|	AND SalesBI.Period >= &qPeriodFrom
		|	AND SalesBI.Period <= &qPeriodTo
		|
		|ORDER BY
		|	PointInTime";
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qPeriodFrom", pPeriodFrom);
		vQry.SetParameter("qPeriodTo", pPeriodTo);
		vQry.SetParameter("qEmptyString", "");
		vQry.SetParameter("qEmptyDate", '00010101');
	Else
		vQry.Text = 
		"SELECT DISTINCT
		|	ChangedAccommodations.Accommodation AS Accommodation
		|INTO ChangedAccommodations
		|FROM
		|	InformationRegister.AccommodationChangeHistory AS ChangedAccommodations
		|WHERE
		|	ChangedAccommodations.Period >= &qLastSyncDate
		|	AND ChangedAccommodations.Period < &qCurrentSyncDate
		|	AND ChangedAccommodations.Hotel = &qHotel
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	ChangedReservations.Reservation AS Reservation
		|INTO ChangedReservations
		|FROM
		|	InformationRegister.ReservationChangeHistory AS ChangedReservations
		|WHERE
		|	ChangedReservations.Period >= &qLastSyncDate
		|	AND ChangedReservations.Period < &qCurrentSyncDate
		|	AND ChangedReservations.Hotel = &qHotel
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	ChangedResourceReservations.ResourceReservation AS ResourceReservation
		|INTO ChangedResourceReservations
		|FROM
		|	InformationRegister.ResourceReservationChangeHistory AS ChangedResourceReservations
		|WHERE
		|	ChangedResourceReservations.Period >= &qLastSyncDate
		|	AND ChangedResourceReservations.Period < &qCurrentSyncDate
		|	AND ChangedResourceReservations.Hotel = &qHotel
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SalesBI.Period AS Period,
		|	SalesBI.Recorder AS Recorder,
		|	SalesBI.LineNumber AS LineNumber,
		|	SalesBI.Active AS Active,
		|	SalesBI.AccountingDate AS AccountingDate,
		|	SalesBI.GuestGroup AS GuestGroup,
		|	SalesBI.Customer AS Customer,
		|	SalesBI.Contract AS Contract,
		|	SalesBI.Agent AS Agent,
		|	SalesBI.Client AS Client,
		|	SalesBI.Service AS Service,
		|	SalesBI.RoomRate AS RoomRate,
		|	SalesBI.Room AS Room,
		|	SalesBI.RoomType AS RoomType,
		|	SalesBI.Resource AS Resource,
		|	SalesBI.Company AS Company,
		|	SalesBI.Hotel AS Hotel,
		|	SalesBI.Folio AS Folio,
		|	SalesBI.ParentDoc AS ParentDoc,
		|	ISNULL(SalesBI.ParentDoc.Date, &qEmptyDate) AS ParentDocDate,
		|	SalesBI.ParentDoc.Reservation AS Reservation,
		|	ISNULL(SalesBI.ParentDoc.Reservation.Date, &qEmptyDate) AS ReservationDate,
		|	CASE
		|		WHEN SalesBI.ParentDoc.CheckInDate IS NULL
		|			THEN SalesBI.ParentDoc.DateTimeFrom
		|		ELSE SalesBI.ParentDoc.CheckInDate
		|	END AS CheckInDate,
		|	ISNULL(SalesBI.ParentDoc.Duration, 0) AS Duration,
		|	CASE
		|		WHEN SalesBI.ParentDoc.CheckOutDate IS NULL
		|			THEN SalesBI.ParentDoc.DateTimeTo
		|		ELSE SalesBI.ParentDoc.CheckOutDate
		|	END AS CheckOutDate,
		|	CASE
		|		WHEN NOT SalesBI.ParentDoc.ReservationStatus IS NULL
		|			THEN SalesBI.ParentDoc.ReservationStatus
		|		WHEN NOT SalesBI.ParentDoc.ResourceReservationStatus IS NULL
		|			THEN SalesBI.ParentDoc.ResourceReservationStatus
		|		ELSE SalesBI.ParentDoc.AccommodationStatus
		|	END AS ReservationStatus,
		|	SalesBI.ParentDoc.RoomQuota AS RoomQuota,
		|	SalesBI.Price AS Price,
		|	SalesBI.ResourceType AS ResourceType,
		|	SalesBI.AccommodationType AS AccommodationType,
		|	SalesBI.ClientType AS ClientType,
		|	SalesBI.TripPurpose AS TripPurpose,
		|	SalesBI.MarketingCode AS MarketingCode,
		|	SalesBI.SourceOfBusiness AS SourceOfBusiness,
		|	SalesBI.CalendarDayType AS CalendarDayType,
		|	SalesBI.PriceTag AS PriceTag,
		|	SalesBI.HotelProduct AS HotelProduct,
		|	SalesBI.Author AS Author,
		|	SalesBI.Discount AS Discount,
		|	SalesBI.DiscountType AS DiscountType,
		|	SalesBI.DiscountCard AS DiscountCard,
		|	SalesBI.AgentCommission AS AgentCommission,
		|	SalesBI.AgentCommissionType AS AgentCommissionType,
		|	SalesBI.PaymentMethod AS PaymentMethod,
		|	SalesBI.VATRate AS VATRate,
		|	ISNULL(SalesBI.VATRate.TaxRate, 0) AS TaxRate,
		|	SalesBI.ReportingCurrency AS ReportingCurrency,
		|	SalesBI.Sales AS Sales,
		|	SalesBI.SalesWithoutVAT AS SalesWithoutVAT,
		|	SalesBI.RoomRevenue AS RoomRevenue,
		|	SalesBI.RoomRevenueWithoutVAT AS RoomRevenueWithoutVAT,
		|	SalesBI.ExtraBedRevenue AS ExtraBedRevenue,
		|	SalesBI.ExtraBedRevenueWithoutVAT AS ExtraBedRevenueWithoutVAT,
		|	SalesBI.CommissionSum AS CommissionSum,
		|	SalesBI.CommissionSumWithoutVAT AS CommissionSumWithoutVAT,
		|	SalesBI.DiscountSum AS DiscountSum,
		|	SalesBI.DiscountSumWithoutVAT AS DiscountSumWithoutVAT,
		|	SalesBI.RoomsRented AS RoomsRented,
		|	SalesBI.BedsRented AS BedsRented,
		|	SalesBI.AdditionalBedsRented AS AdditionalBedsRented,
		|	SalesBI.GuestDays AS GuestDays,
		|	SalesBI.GuestsCheckedIn AS GuestsCheckedIn,
		|	SalesBI.RoomsCheckedIn AS RoomsCheckedIn,
		|	SalesBI.BedsCheckedIn AS BedsCheckedIn,
		|	SalesBI.AdditionalBedsCheckedIn AS AdditionalBedsCheckedIn,
		|	SalesBI.BookingWindow AS BookingWindow,
		|	SalesBI.ResourceRevenue AS ResourceRevenue,
		|	SalesBI.ResourceRevenueWithoutVAT AS ResourceRevenueWithoutVAT,
		|	SalesBI.HoursRented AS HoursRented,
		|	SalesBI.Quantity AS Quantity,
		|	SalesBI.VATSum AS VATSum,
		|	SalesBI.IsStorno AS IsStorno,
		|	SalesBI.RateSum AS RateSum,
		|	SalesBI.NumberOfBedsPerRoom AS NumberOfBedsPerRoom,
		|	SalesBI.NumberOfPersonsPerRoom AS NumberOfPersonsPerRoom,
		|	SalesBI.NumberOfAdditionalBeds AS NumberOfAdditionalBeds,
		|	SalesBI.NumberOfBeds AS NumberOfBeds,
		|	SalesBI.NumberOfPersons AS NumberOfPersons,
		|	SalesBI.NumberOfRooms AS NumberOfRooms,
		|	SalesBI.RoomRateType AS RoomRateType,
		|	SalesBI.TimeFrom AS TimeFrom,
		|	SalesBI.TimeTo AS TimeTo,
		|	ISNULL(SalesBI.Recorder.Remarks, &qEmptyString) AS Remarks,
		|	ISNULL(SalesBI.Recorder.Details, &qEmptyString) AS Details,
		|	SalesBI.PointInTime AS PointInTime
		|FROM
		|	AccumulationRegister.Sales AS SalesBI
		|WHERE
		|	SalesBI.Hotel = &qHotel
		|	AND SalesBI.Period >= &qPeriodFrom
		|	AND SalesBI.Period <= &qPeriodTo
		|	AND (SalesBI.ParentDoc REFS Document.Accommodation
		|				AND SalesBI.ParentDoc IN
		|					(SELECT
		|						ChangedAccommodations.Accommodation
		|					FROM
		|						ChangedAccommodations AS ChangedAccommodations)
		|			OR SalesBI.ParentDoc REFS Document.Reservation
		|				AND SalesBI.ParentDoc IN
		|					(SELECT
		|						ChangedReservations.Reservation
		|					FROM
		|						ChangedReservations AS ChangedReservations)
		|			OR SalesBI.ParentDoc REFS Document.ResourceReservation
		|				AND SalesBI.ParentDoc IN
		|					(SELECT
		|						ChangedResourceReservations.ResourceReservation
		|					FROM
		|						ChangedResourceReservations AS ChangedResourceReservations)
		|			OR NOT SalesBI.ParentDoc REFS Document.Accommodation
		|				AND NOT SalesBI.ParentDoc REFS Document.Reservation
		|				AND NOT SalesBI.ParentDoc REFS Document.ResourceReservation)
		|
		|ORDER BY
		|	PointInTime";
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qPeriodFrom", pPeriodFrom);
		vQry.SetParameter("qPeriodTo", pPeriodTo);
		vQry.SetParameter("qLastSyncDate", pLastSyncDate);
		vQry.SetParameter("qCurrentSyncDate", pCurrentSyncDate);
		vQry.SetParameter("qEmptyString", "");
		vQry.SetParameter("qEmptyDate", '00010101');
	EndIf;
	vSales = vQry.Execute().Unload();
	Return vSales;
EndFunction // GetSales

// -----------------------------------------------------------------------------
Function GetDeletedSales(pPeriodFrom, pPeriodTo)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Charges.Date AS Period,
	|	Charges.Ref AS Recorder,
	|	1 AS LineNumber,
	|	Charges.Hotel AS Hotel,
	|	Charges.PointInTime AS PointInTime
	|FROM
	|	Document.Charge AS Charges
	|WHERE
	|	Charges.Hotel = &qHotel
	|	AND Charges.Date >= &qPeriodFrom
	|	AND Charges.Date <= &qPeriodTo
	|	AND NOT Charges.Posted
	|
	|UNION ALL
	|
	|SELECT
	|	Stornos.Date,
	|	Stornos.Ref,
	|	1,
	|	Stornos.Hotel,
	|	Stornos.PointInTime
	|FROM
	|	Document.Storno AS Stornos
	|WHERE
	|	Stornos.Hotel = &qHotel
	|	AND Stornos.Date >= &qPeriodFrom
	|	AND Stornos.Date <= &qPeriodTo
	|	AND NOT Stornos.Posted
	|
	|ORDER BY
	|	PointInTime";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qPeriodFrom", pPeriodFrom);
	vQry.SetParameter("qPeriodTo", pPeriodTo);
	vDeletedSales = vQry.Execute().Unload();
	Return vDeletedSales;
EndFunction // GetDeletedSales

// -----------------------------------------------------------------------------
Function GetCustomerClient(pCustomer)
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	SalesRecords.Customer AS Customer,
	|	SalesRecords.Client AS Client
	|FROM
	|	AccumulationRegister.Sales AS SalesRecords
	|WHERE
	|	SalesRecords.Customer = &qCustomer
	|	AND SalesRecords.Client <> &qEmptyClient
	|	AND SalesRecords.Client.FullName = SalesRecords.Customer.Description
	|	AND (SalesRecords.Client.DateOfBirth <> &qEmptyDate
	|			OR SalesRecords.Client.Phone <> &qEmptyString
	|			OR SalesRecords.Client.EMail <> &qEmptyString)
	|
	|ORDER BY
	|	SalesRecords.Client.Code DESC";
	vQry.SetParameter("qCustomer", pCustomer);
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qEmptyString", "");
	vClients = vQry.Execute().Unload();
	For Each vClientsRow In vClients Do
		Return vClientsRow.Client;
	EndDo;
	Return Undefined;
EndFunction // GetCustomerClient

// -----------------------------------------------------------------------------
Procedure AddChangedCustomers(pCustomersList, pPeriodFrom, pPeriodTo, pNewCustomers, pChangedCustomers)
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	CustomerChangeHistory.Customer AS Customer,
	|	CustomerChangeHistory.Code AS Code
	|FROM
	|	InformationRegister.CustomerChangeHistory AS CustomerChangeHistory
	|WHERE
	|	CustomerChangeHistory.Period >= &qPeriodFrom
	|	AND CustomerChangeHistory.Period <= &qPeriodTo
	|	AND NOT CustomerChangeHistory.Customer IN (&qNewCustomers)
	|	AND NOT CustomerChangeHistory.Customer IN (&qChangedCustomers)
	|
	|ORDER BY
	|	CustomerChangeHistory.Code";
	vQry.SetParameter("qPeriodFrom", pPeriodFrom);
	vQry.SetParameter("qPeriodTo", pPeriodTo);
	vQry.SetParameter("qNewCustomers", pNewCustomers);
	vQry.SetParameter("qChangedCustomers", pChangedCustomers);
	vChangedItems = vQry.Execute().Unload();
	For Each vChangedItemsRow In vChangedItems Do
		If pCustomersList.FindByValue(vChangedItemsRow.Customer) = Undefined Then
			pCustomersList.Add(vChangedItemsRow.Customer);
		EndIf;
	EndDo;
EndProcedure // AddChangedCustomers

// -----------------------------------------------------------------------------
Procedure AddChangedClients(pClientsList, pPeriodFrom, pPeriodTo, pNewClients, pChangedClients)
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	ClientChangeHistory.Client AS Client,
	|	ClientChangeHistory.Code AS Code
	|FROM
	|	InformationRegister.ClientChangeHistory AS ClientChangeHistory
	|WHERE
	|	ClientChangeHistory.Period >= &qPeriodFrom
	|	AND ClientChangeHistory.Period <= &qPeriodTo
	|	AND NOT ClientChangeHistory.Client IN (&qNewClients)
	|	AND NOT ClientChangeHistory.Client IN (&qChangedClients)
	|
	|ORDER BY
	|	ClientChangeHistory.Code";
	vQry.SetParameter("qPeriodFrom", pPeriodFrom);
	vQry.SetParameter("qPeriodTo", pPeriodTo);
	vQry.SetParameter("qNewClients", pNewClients);
	vQry.SetParameter("qChangedClients", pChangedClients);
	vChangedItems = vQry.Execute().Unload();
	For Each vChangedItemsRow In vChangedItems Do
		If pClientsList.FindByValue(vChangedItemsRow.Client) = Undefined Then
			pClientsList.Add(vChangedItemsRow.Client);
		EndIf;
	EndDo;
EndProcedure // AddChangedClients

// -----------------------------------------------------------------------------
Procedure AddChangedDiscountCards(pDiscountCardsList, pPeriodFrom, pPeriodTo, pNewDiscountCards, pChangedDiscountCards)
	// Nothing to do so far
EndProcedure // AddChangedDiscountCards

// -----------------------------------------------------------------------------
Procedure SendSales(pHotelBIProxy, Val pLastSyncDate, Val pStopSyncDate, Val pCurrentSyncDate, pNewItems, pChangedItems)
	WriteLogEvent(NStr("en='Sales synchronization with 1C:Hotel BI';ru='Синхронизация продаж с системой 1С:Отель BI';de='Der Umsatz Synchronisation mit 1C:Hotel BI'"), EventLogLevel.Information, , , "Start");
	
	vHotelCode = TrimAll(Hotel.Code);
	
	vClientsBeingSent = New ValueTable();
	vClientsBeingSent.Columns.Add("Client", cmGetCatalogTypeDescription("Clients"));
	vClientsBeingSent.Indexes.Add("Client");
	
	vCustomersBeingSent = New ValueTable();
	vCustomersBeingSent.Columns.Add("Customer", cmGetCatalogTypeDescription("Customers"));
	vCustomersBeingSent.Indexes.Add("Customer");
	
	// Call sales sync function for each day in period
	vPeriods = New ValueTable();
	vPeriods.Columns.Add("PeriodFrom", cmGetDateTimeTypeDescription());
	vPeriods.Columns.Add("PeriodTo", cmGetDateTimeTypeDescription());
	
	If (pStopSyncDate - pLastSyncDate) <= (24 * 3600) Then
		vPeriodsRow = vPeriods.Add();
		vPeriodsRow.PeriodFrom = BegOfDay(pLastSyncDate);
		vPeriodsRow.PeriodTo = EndOfDay(pStopSyncDate);
	Else
		vCurDate = BegOfDay(pLastSyncDate);
		While vCurDate <= BegOfDay(pStopSyncDate) Do
			vPeriodFrom = BegOfDay(vCurDate);
			If vCurDate = BegOfDay(pLastSyncDate) Then
				vPeriodFrom = pLastSyncDate;
			EndIf;
			vPeriodTo = EndOfDay(vCurDate);
			If vPeriodFrom > pStopSyncDate Then
				vPeriodFrom = pStopSyncDate;
			EndIf;
			
			vPeriodsRow = vPeriods.Add();
			vPeriodsRow.PeriodFrom = BegOfDay(vPeriodFrom);
			vPeriodsRow.PeriodTo = EndOfDay(vPeriodTo);
			
			vCurDate = vCurDate + (24 * 3600);
		EndDo;
	EndIf;
	
	// Do for each period in periods
	For Each vPeriodsRow In vPeriods Do
		WriteLogEvent(NStr("en='Sales synchronization with 1C:Hotel BI';ru='Синхронизация продаж с системой 1С:Отель BI';de='Der Umsatz Synchronisation mit 1C:Hotel BI'"), EventLogLevel.Information, , , PeriodPresentation(vPeriodsRow.PeriodFrom, vPeriodsRow.PeriodTo));
		
		// Get sales
		vSales = GetSales(vPeriodsRow.PeriodFrom, vPeriodsRow.PeriodTo, pLastSyncDate, pCurrentSyncDate);
		
		// Get customers
		If Not SyncSalesOnly Then
			vCustomersCount = 0;
			vCustomers = vSales.Copy(, "Customer");
			vCustomers.GroupBy("Customer");
			vCustomersList = New ValueList();
			vCustomersList.LoadValues(vCustomers.UnloadColumn("Customer"));
			vAgents = vSales.Copy(, "Agent");
			vAgents.GroupBy("Agent");
			For Each vAgentsRow In vAgents Do
				If vCustomersList.FindByValue(vAgentsRow.Agent) = Undefined Then
					vCustomersList.Add(vAgentsRow.Agent);
				EndIf;
			EndDo;
			If Not FullSync Then
				AddChangedCustomers(vCustomersList, vPeriodsRow.PeriodFrom, vPeriodsRow.PeriodTo, pNewItems.NewCustomers, pChangedItems.ChangedCustomers);
			EndIf;
			vCustomersXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "Customers"));
			For Each vCustomersListItem In vCustomersList Do
				vCustomerRef = vCustomersListItem.Value;
				If vCustomersBeingSent.Find(vCustomerRef, "Customer") <> Undefined Then
					Continue;
				Else
					vCustomersBeingSentRow = vCustomersBeingSent.Add();
					vCustomersBeingSentRow.Customer = vCustomerRef;
				EndIf;
				If Not IsBlankString(vCustomerRef.Description) Then
					vCustomerXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "Customer"));
					FillPropertyValues(vCustomerXDTO, vCustomerRef, , "RoomRate, RoomRateServiceGroup, CustomerType, PlannedPaymentMethod, AgentCommissionType, AgentCommissionServiceGroup, Contract, AgentCommissionContract, BankAccount, FeeTerms, Color, IdentityDocumentType, Author");
					vCustomerXDTO.CustomerCodeInHotel = TrimAll(vCustomerRef.Code);
					
					// Try to find client for this customer and get date of birth, phone, e-mail from it
					If Not ValueIsFilled(vCustomerRef.DateOfBirth) Then
						vCustomerClientRef = GetCustomerClient(vCustomerRef);
						If ValueIsFilled(vCustomerClientRef) Then
							vCustomerObj = vCustomerRef.GetObject();
							vDoUpdate = False;
							If ValueIsFilled(vCustomerClientRef.DateOfBirth) And Not ValueIsFilled(vCustomerRef.DateOfBirth) Then
								vDoUpdate = True;
								vCustomerXDTO.DateOfBirth = vCustomerClientRef.DateOfBirth;
							EndIf;
							If Not IsBlankString(vCustomerClientRef.Phone) And IsBlankString(vCustomerRef.Phone) Then
								vDoUpdate = True;
								vCustomerXDTO.Phone = TrimAll(vCustomerClientRef.Phone);
							EndIf;
							If Not IsBlankString(vCustomerClientRef.EMail) And IsBlankString(vCustomerRef.EMail) Then
								vDoUpdate = True;
								vCustomerXDTO.EMail = TrimAll(vCustomerClientRef.EMail);
							EndIf;
							If Not IsBlankString(vCustomerClientRef.Address) And IsBlankString(vCustomerRef.PostAddress) Then
								vDoUpdate = True;
								vCustomerXDTO.PostAddress = TrimAll(vCustomerClientRef.Address);
							EndIf;
							If vDoUpdate Then
								FillPropertyValues(vCustomerObj, vCustomerClientRef, , "Owner, Parent, Code, Description, Author, CreateDate, Remarks, ExternalCode, B24ContactID");
								vCustomerObj.PostAddress = TrimAll(vCustomerClientRef.Address);
								vCustomerObj.Write();
								vCustomerObj.pmWriteToCustomerChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
							EndIf;
						EndIf;
					EndIf;
					
					vCustomerXDTO.RoomRate = TrimAll(vCustomerRef.RoomRate);
					vCustomerXDTO.RoomRateServiceGroup = TrimAll(vCustomerRef.RoomRateServiceGroup);
					vCustomerXDTO.CustomerType = TrimAll(vCustomerRef.CustomerType);
					vCustomerXDTO.PlannedPaymentMethod = TrimAll(vCustomerRef.PlannedPaymentMethod);
					vCustomerXDTO.AgentCommissionType = TrimAll(vCustomerRef.AgentCommissionType);
					vCustomerXDTO.AgentCommissionServiceGroup = TrimAll(vCustomerRef.AgentCommissionServiceGroup);
					vCustomerXDTO.Contract = TrimAll(vCustomerRef.Contract);
					vCustomerXDTO.AgentCommissionContract = TrimAll(vCustomerRef.AgentCommissionContract);
					vCustomerXDTO.BankAccount = TrimAll(vCustomerRef.BankAccount);
					vCustomerXDTO.FeeTerms = TrimAll(vCustomerRef.FeeTerms);
					vCustomerXDTO.IdentityDocumentType = TrimAll(vCustomerRef.IdentityDocumentType);
					vCustomerXDTO.Author = TrimAll(vCustomerRef.Author);
					vCustomerXDTO.IsIndividual = vCustomerRef.IsIndividual;
					
					If ValueIsFilled(vCustomerRef.AccountingCurrency) Then
						vCustomerXDTO.AccountingCurrencyCode = vCustomerRef.AccountingCurrency.Code;
					Else
						vCustomerXDTO.AccountingCurrencyCode = "";
					EndIf;
					
					If ValueIsFilled(vCustomerRef.Language) Then
						vCustomerXDTO.LanguageCode = TrimAll(vCustomerRef.Language.Code);
					Else
						vCustomerXDTO.LanguageCode = "";
					EndIf;
					
					If ValueIsFilled(vCustomerRef.ParentOrganization) Then
						vParentOrganization = vCustomerRef.ParentOrganization;
						vCustomerXDTO.ParentOrganizationCode = TrimAll(vParentOrganization.Code);
						vCustomerXDTO.ParentOrganizationDescription = TrimAll(vParentOrganization.Description);
						vCustomerXDTO.ParentOrganizationDateOfBirth = vParentOrganization.DateOfBirth;
						vCustomerXDTO.ParentOrganizationPhone = TrimAll(vParentOrganization.Phone);
						vCustomerXDTO.ParentOrganizationEMail = TrimAll(vParentOrganization.EMail);
						vCustomerXDTO.ParentOrganizationTIN = TrimAll(vParentOrganization.TIN);
						vCustomerXDTO.ParentOrganizationKPP = TrimAll(vParentOrganization.KPP);
					Else
						vCustomerXDTO.ParentOrganizationCode = "";
						vCustomerXDTO.ParentOrganizationDescription = "";
						vCustomerXDTO.ParentOrganizationDateOfBirth = '00010101';
						vCustomerXDTO.ParentOrganizationPhone = "";
						vCustomerXDTO.ParentOrganizationEMail = "";
						vCustomerXDTO.ParentOrganizationTIN = "";
						vCustomerXDTO.ParentOrganizationKPP = "";
					EndIf;
					
					If ValueIsFilled(vCustomerRef.Agent) Then
						vAgent = vCustomerRef.Agent;
						vCustomerXDTO.AgentCode = TrimAll(vAgent.Code);
						vCustomerXDTO.AgentDescription = TrimAll(vAgent.Description);
						vCustomerXDTO.AgentDateOfBirth = vAgent.DateOfBirth;
						vCustomerXDTO.AgentPhone = TrimAll(vAgent.Phone);
						vCustomerXDTO.AgentEMail = TrimAll(vAgent.EMail);
						vCustomerXDTO.AgentTIN = TrimAll(vAgent.TIN);
						vCustomerXDTO.AgentKPP = TrimAll(vAgent.KPP);
					Else
						vCustomerXDTO.AgentCode = "";
						vCustomerXDTO.AgentDescription = "";
						vCustomerXDTO.AgentDateOfBirth = '00010101';
						vCustomerXDTO.AgentPhone = "";
						vCustomerXDTO.AgentEMail = "";
						vCustomerXDTO.AgentTIN = "";
						vCustomerXDTO.AgentKPP = "";
					EndIf;
					
					If ValueIsFilled(vCustomerRef.DiscountType) Then
						vCustomerXDTO.DiscountTypeCode = TrimAll(vCustomerRef.DiscountType.Code);
					Else
						vCustomerXDTO.DiscountTypeCode = "";
					EndIf;
					
					If ValueIsFilled(vCustomerRef.MarketingCode) Then
						vCustomerXDTO.MarketingCodeCode = TrimAll(vCustomerRef.MarketingCode.Code);
					Else
						vCustomerXDTO.MarketingCodeCode = "";
					EndIf;
					
					If ValueIsFilled(vCustomerRef.SourceOfBusiness) Then
						vCustomerXDTO.SourceOfBusinessCode = TrimAll(vCustomerRef.SourceOfBusiness.Code);
					Else
						vCustomerXDTO.SourceOfBusinessCode = "";
					EndIf;
					
					If ValueIsFilled(vCustomerRef.ClientType) Then
						vCustomerXDTO.ClientTypeCode = TrimAll(vCustomerRef.ClientType.Code);
					Else
						vCustomerXDTO.ClientTypeCode = "";
					EndIf;
					
					If vCustomerRef.Color <> Undefined Then
						vColor = vCustomerRef.Color.Get();
						If vColor <> Undefined And TypeOf(vColor) = Type("Color") Then
							vCustomerXDTO.Color = ValueToStringInternal(vColor);
						Else
							vCustomerXDTO.Color = "";
						EndIf;
					Else
						vCustomerXDTO.Color = "";
					EndIf;
					
					vCustomersXDTO.Customer.Add(vCustomerXDTO);
					vCustomersCount = vCustomersCount + 1;
		
					// Call customers sync proxy
					If Int(vCustomersCount / 50) = vCustomersCount / 50 Then
						WriteLogEvent(NStr("en='Customers synchronization with 1C:Hotel BI';ru='Синхронизация контрагентов с системой 1С:Отель BI';de='Firmen Synchronisation mit 1C:Hotel BI'"), EventLogLevel.Information, , , "Customers: " + vCustomersCount);
						vResult = pHotelBIProxy.CustomersSync(vHotelCode, vCustomersXDTO);
						WriteLogEvent(NStr("en='Customers synchronization with 1C:Hotel BI';ru='Синхронизация контрагентов с системой 1С:Отель BI';de='Firmen Synchronisation mit 1C:Hotel BI'"), EventLogLevel.Information, , , "Customers sync result: " + vResult);
						
						vCustomersXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "Customers"));
						vCustomersCount = 0;
					EndIf;
				EndIf;
			EndDo;
		
			// Call customers sync proxy
			If vCustomersCount > 0 Then
				WriteLogEvent(NStr("en='Customers synchronization with 1C:Hotel BI';ru='Синхронизация контрагентов с системой 1С:Отель BI';de='Firmen Synchronisation mit 1C:Hotel BI'"), EventLogLevel.Information, , , "Customers: " + vCustomersCount);
				vResult = pHotelBIProxy.CustomersSync(vHotelCode, vCustomersXDTO);
				WriteLogEvent(NStr("en='Customers synchronization with 1C:Hotel BI';ru='Синхронизация контрагентов с системой 1С:Отель BI';de='Firmen Synchronisation mit 1C:Hotel BI'"), EventLogLevel.Information, , , "Customers sync result: " + vResult);
			EndIf;
		EndIf;
		
		// Get clients
		If Not SyncSalesOnly Then
			vClientsCount = 0;
			vClients = vSales.Copy(, "Client");
			vClients.GroupBy("Client");
			vClientsList = New ValueList();
			vClientsList.LoadValues(vClients.UnloadColumn("Client"));
			If Not FullSync Then
				AddChangedClients(vClientsList, vPeriodsRow.PeriodFrom, vPeriodsRow.PeriodTo, pNewItems.NewClients, pChangedItems.ChangedClients);
			EndIf;
			vClientsXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "Clients"));
			For Each vClientsListItem In vClientsList Do
				vClientRef = vClientsListItem.Value;
				If vClientsBeingSent.Find(vClientRef, "Client") <> Undefined Then
					Continue;
				Else
					vClientsBeingSentRow = vClientsBeingSent.Add();
					vClientsBeingSentRow.Client = vClientRef;
				EndIf;
				If Not IsBlankString(vClientRef.FullName) Then
					vClientXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "Client"));
					FillPropertyValues(vClientXDTO, vClientRef, , "Sex, Citizenship, IdentityDocumentType, MilitaryRank, Salutation, Photo, Signature, Author, RoomRate, RoomRateServiceGroup, AgeRange");
					vClientXDTO.ClientCodeInHotel = TrimAll(vClientRef.Code);
					
					vClientXDTO.Salutation = TrimAll(vClientRef.Salutation);
					vClientXDTO.Sex = TrimAll(vClientRef.Sex);
					vClientXDTO.Citizenship = TrimAll(vClientRef.Citizenship);
					vClientXDTO.IdentityDocumentType = TrimAll(vClientRef.IdentityDocumentType);
					vClientXDTO.MilitaryRank = TrimAll(vClientRef.MilitaryRank);
					vClientXDTO.Author = TrimAll(vClientRef.Author);
					vClientXDTO.RoomRate = TrimAll(vClientRef.RoomRate);
					vClientXDTO.RoomRateServiceGroup = TrimAll(vClientRef.RoomRateServiceGroup);
					vClientXDTO.AgeRange = TrimAll(vClientRef.AgeRange);
					
					If ValueIsFilled(vClientRef.Language) Then
						vClientXDTO.LanguageCode = TrimAll(vClientRef.Language.Code);
					Else
						vClientXDTO.LanguageCode = "";
					EndIf;
					
					If ValueIsFilled(vClientRef.DiscountType) Then
						vClientXDTO.DiscountTypeCode = TrimAll(vClientRef.DiscountType.Code);
					Else
						vClientXDTO.DiscountTypeCode = "";
					EndIf;
					
					If ValueIsFilled(vClientRef.MarketingCode) Then
						vClientXDTO.MarketingCodeCode = TrimAll(vClientRef.MarketingCode.Code);
					Else
						vClientXDTO.MarketingCodeCode = "";
					EndIf;
					
					If ValueIsFilled(vClientRef.SourceOfBusiness) Then
						vClientXDTO.SourceOfBusinessCode = TrimAll(vClientRef.SourceOfBusiness.Code);
					Else
						vClientXDTO.SourceOfBusinessCode = "";
					EndIf;
					
					If ValueIsFilled(vClientRef.ClientType) Then
						vClientXDTO.ClientTypeCode = TrimAll(vClientRef.ClientType.Code);
					Else
						vClientXDTO.ClientTypeCode = "";
					EndIf;
					
					If ValueIsFilled(vClientRef.DiscountCard) Then
						vClientXDTO.DiscountCardIdentifier = TrimAll(vClientRef.DiscountCard.Identifier);
					Else
						vClientXDTO.DiscountCardIdentifier = "";
					EndIf;
					
					If vClientRef.Photo <> Undefined Then
						vPhoto = vClientRef.Photo.Get();
						If vPhoto <> Undefined And TypeOf(vPhoto) = Type("Picture") Then
							vClientXDTO.Photo = Base64String(vPhoto.GetBinaryData());
						Else
							vClientXDTO.Photo = "";
						EndIf;
					Else
						vClientXDTO.Photo = "";
					EndIf;
					
					If vClientRef.Signature <> Undefined Then
						vSignature = vClientRef.Signature.Get();
						If vSignature <> Undefined And TypeOf(vSignature) = Type("Picture") Then
							vClientXDTO.Signature = Base64String(vSignature.GetBinaryData());
						Else
							vClientXDTO.Signature = "";
						EndIf;
					Else
						vClientXDTO.Signature = "";
					EndIf;
					
					vClientXDTO.RoomPropertiesPresentation = "";
					For Each vRoomPropertiesRow In vClientRef.RoomProperties Do
						vClientXDTO.RoomPropertiesPresentation = vClientXDTO.RoomPropertiesPresentation + 
						                                         ?(IsBlankString(vClientXDTO.RoomPropertiesPresentation), "", ", ") + 
																 TrimAll(vRoomPropertiesRow.RoomProperty);
					EndDo;
					
					vClientsXDTO.Client.Add(vClientXDTO);
					vClientsCount = vClientsCount + 1;
				
					// Call clients sync proxy
					If Int(vClientsCount / 50) = vClientsCount / 50 Then
						WriteLogEvent(NStr("en = 'Clients synchronization with 1C:Hotel BI'; de = 'Kunden Synchronisation mit 1C:Hotel BI'; ru = 'Синхронизация клиентов с системой 1С:Отель BI'"), EventLogLevel.Information, , , "Clients: " + vClientsCount);
						vResult = pHotelBIProxy.ClientsSync(vHotelCode, vClientsXDTO);
						WriteLogEvent(NStr("en = 'Clients synchronization with 1C:Hotel BI'; de = 'Kunden Synchronisation mit 1C:Hotel BI'; ru = 'Синхронизация клиентов с системой 1С:Отель BI'"), EventLogLevel.Information, , , "Clients sync result: " + vResult);
						
						vClientsXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "Clients"));
						vClientsCount = 0;
					EndIf;
				EndIf;
			EndDo;
		
			// Call clients sync proxy
			If vClientsCount > 0 Then
				WriteLogEvent(NStr("en = 'Clients synchronization with 1C:Hotel BI'; de = 'Kunden Synchronisation mit 1C:Hotel BI'; ru = 'Синхронизация клиентов с системой 1С:Отель BI'"), EventLogLevel.Information, , , "Clients: " + vClientsCount);
				vResult = pHotelBIProxy.ClientsSync(vHotelCode, vClientsXDTO);
				WriteLogEvent(NStr("en = 'Clients synchronization with 1C:Hotel BI'; de = 'Kunden Synchronisation mit 1C:Hotel BI'; ru = 'Синхронизация клиентов с системой 1С:Отель BI'"), EventLogLevel.Information, , , "Clients sync result: " + vResult);
			EndIf;
		EndIf;
		
		// Get discount cards
		vDiscountCardsXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "DiscountCards"));
		If Not DoNotSyncDiscountCards And Not SyncSalesOnly Then
			vDiscountCardsCount = 0;
			vDiscountCards = vSales.Copy(, "DiscountCard");
			vDiscountCards.GroupBy("DiscountCard");
			vDiscountCardsList = New ValueList();
			vDiscountCardsList.LoadValues(vDiscountCards.UnloadColumn("DiscountCard"));
			If Not FullSync Then
				AddChangedDiscountCards(vDiscountCardsList, vPeriodsRow.PeriodFrom, vPeriodsRow.PeriodTo, pNewItems.NewDiscountCards, pChangedItems.ChangedDiscountCards);
			EndIf;
			For Each vDiscountCardsListItem In vDiscountCardsList Do
				vDiscountCardRef = vDiscountCardsListItem.Value;
				If Not IsBlankString(vDiscountCardRef.Identifier) Then
					vDiscountCardXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "DiscountCard"));
					FillPropertyValues(vDiscountCardXDTO, vDiscountCardRef);
					vDiscountCardXDTO.DiscountCardCodeInHotel = TrimAll(vDiscountCardRef.Code);
					
					If ValueIsFilled(vDiscountCardRef.DiscountType) Then
						vDiscountCardXDTO.DiscountTypeCode = TrimAll(vDiscountCardRef.DiscountType.Code);
					Else
						vDiscountCardXDTO.DiscountTypeCode = "";
					EndIf;
					
					If ValueIsFilled(vDiscountCardRef.ClientType) Then
						vDiscountCardXDTO.ClientTypeCode = TrimAll(vDiscountCardRef.ClientType.Code);
					Else
						vDiscountCardXDTO.ClientTypeCode = "";
					EndIf;
					
					If ValueIsFilled(vDiscountCardRef.Client) Then
						vClient = vDiscountCardRef.Client;
						vDiscountCardXDTO.ClientCode = TrimAll(vClient.Code);
						vDiscountCardXDTO.ClientFullName = TrimAll(vClient.FullName);
						vDiscountCardXDTO.ClientDateOfBirth = vClient.DateOfBirth;
						vDiscountCardXDTO.ClientPhone = TrimAll(vClient.Phone);
						vDiscountCardXDTO.ClientEMail = TrimAll(vClient.EMail);
					Else
						vDiscountCardXDTO.ClientCode = "";
						vDiscountCardXDTO.ClientFullName = "";
						vDiscountCardXDTO.ClientDateOfBirth = '00010101';
						vDiscountCardXDTO.ClientPhone = "";
						vDiscountCardXDTO.ClientEMail = "";
					EndIf;
					
					vDiscountCardsXDTO.DiscountCard.Add(vDiscountCardXDTO);
					vDiscountCardsCount = vDiscountCardsCount + 1;
				
					// Call discount cards sync proxy
					If Int(vDiscountCardsCount / 50) = vDiscountCardsCount / 50 Then
						WriteLogEvent(NStr("en='Discount cards synchronization with 1C:Hotel BI';ru='Синхронизация дисконтных карт с системой 1С:Отель BI';de='Diskontkarten Synchronisation mit 1C:Hotel BI'"), EventLogLevel.Information, , , "Discount cards: " + vDiscountCardsCount);
						vResult = pHotelBIProxy.DiscountCardsSync(vHotelCode, vDiscountCardsXDTO);
						WriteLogEvent(NStr("en='Discount cards synchronization with 1C:Hotel BI';ru='Синхронизация дисконтных карт с системой 1С:Отель BI';de='Diskontkarten Synchronisation mit 1C:Hotel BI'"), EventLogLevel.Information, , , "Discount cards sync result: " + vResult);
						
						vDiscountCardsXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "DiscountCards"));
						vDiscountCardsCount = 0;
					EndIf;
				EndIf;
			EndDo;
			
			// Call discount cards sync proxy
			If vDiscountCardsCount > 0 Then
				WriteLogEvent(NStr("en='Discount cards synchronization with 1C:Hotel BI';ru='Синхронизация дисконтных карт с системой 1С:Отель BI';de='Diskontkarten Synchronisation mit 1C:Hotel BI'"), EventLogLevel.Information, , , "Discount cards: " + vDiscountCardsCount);
				vResult = pHotelBIProxy.DiscountCardsSync(vHotelCode, vDiscountCardsXDTO);
				WriteLogEvent(NStr("en='Discount cards synchronization with 1C:Hotel BI';ru='Синхронизация дисконтных карт с системой 1С:Отель BI';de='Diskontkarten Synchronisation mit 1C:Hotel BI'"), EventLogLevel.Information, , , "Discount cards sync result: " + vResult);
			EndIf;
		EndIf;
		
		// Deleted sales
		vDeletedSalesSent = False;
		vDeletedSalesCount = 0;
		vDeletedSalesXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "DeletedSales"));
		If Not FullSync Then
			vDeletedSales = GetDeletedSales(vPeriodsRow.PeriodFrom, vPeriodsRow.PeriodTo);
			For Each vDeletedSalesRow In vDeletedSales Do
				vDeletedSalesRowXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "DeletedSalesRow"));
				vDeletedSalesRowXDTO.HotelCode = vHotelCode;
				vDeletedSalesRowXDTO.RecorderUUID = String(vDeletedSalesRow.Recorder.UUID());
				vDeletedSalesRowXDTO.SalesLineNumber = vDeletedSalesRow.LineNumber;
				vDeletedSalesRowXDTO.RecorderDate = vDeletedSalesRow.Period;
				
				vDeletedSalesXDTO.DeletedSalesRow.Add(vDeletedSalesRowXDTO);
				vDeletedSalesCount = vDeletedSalesCount + 1;
			EndDo;
		Else
			// Clear period sales
			vRecordsCleared = 100;
			While vRecordsCleared > 0 Do
				WriteLogEvent(NStr("en='Sales synchronization with 1C:Hotel BI';ru='Синхронизация продаж с системой 1С:Отель BI';de='Der Umsatz Synchronisation mit 1C:Hotel BI'"), EventLogLevel.Information, , , "Clear sales for period: " + vPeriodsRow.PeriodFrom + " - " + vPeriodsRow.PeriodTo);
				vRecordsCleared = pHotelBIProxy.ClearSales(vHotelCode, vPeriodsRow.PeriodFrom, vPeriodsRow.PeriodTo);
				WriteLogEvent(NStr("en='Sales synchronization with 1C:Hotel BI';ru='Синхронизация продаж с системой 1С:Отель BI';de='Der Umsatz Synchronisation mit 1C:Hotel BI'"), EventLogLevel.Information, , , "Records cleared: " + vRecordsCleared);
			EndDo;
		EndIf;
		
		// Send sales
		vSalesCount = 0;
		vSalesXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "Sales"));
		For Each vSalesRow In vSales Do
			vSalesRowXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "SalesRow"));
			FillPropertyValues(vSalesRowXDTO, vSalesRow, , "GuestGroup, Contract, Service, RoomRate, Room, RoomType, Resource, ResourceType, Company, ParentDoc, AccommodationType, PaymentMethod, Author, CalendarDayType, PriceTag, VATRate, AgentCommissionType, RoomQuota, ReservationStatus, CheckInDate, CheckOutDate, Duration, ReservationDate");
			
			vSalesRowXDTO.GuestGroup = TrimAll(vSalesRow.GuestGroup);
			vSalesRowXDTO.Contract = TrimAll(vSalesRow.Contract);
			vSalesRowXDTO.Service = TrimAll(vSalesRow.Service);
			vSalesRowXDTO.ServiceType = TrimAll(vSalesRow.Service.ServiceType);
			vSalesRowXDTO.RoomRate = TrimAll(vSalesRow.RoomRate);
			vSalesRowXDTO.Room = TrimAll(vSalesRow.Room);
			vSalesRowXDTO.RoomType = TrimAll(vSalesRow.RoomType);
			vSalesRowXDTO.Resource = TrimAll(vSalesRow.Resource);
			vSalesRowXDTO.ResourceType = TrimAll(vSalesRow.ResourceType);
			vSalesRowXDTO.Company = TrimAll(vSalesRow.Company);
			vSalesRowXDTO.AccommodationType = TrimAll(vSalesRow.AccommodationType);
			vSalesRowXDTO.PaymentMethod = TrimAll(vSalesRow.PaymentMethod);
			vSalesRowXDTO.Author = TrimAll(vSalesRow.Author);
			vSalesRowXDTO.CalendarDayType = TrimAll(vSalesRow.CalendarDayType);
			vSalesRowXDTO.PriceTag = TrimAll(vSalesRow.PriceTag);
			vSalesRowXDTO.VATRate = TrimAll(vSalesRow.VATRate);
			vSalesRowXDTO.AgentCommissionType = TrimAll(vSalesRow.AgentCommissionType);
			
			vSalesRowXDTO.HotelCode = vHotelCode;
			vSalesRowXDTO.RecorderUUID = String(vSalesRow.Recorder.UUID());
			vSalesRowXDTO.SalesLineNumber = vSalesRow.LineNumber;
			vSalesRowXDTO.RecorderDate = vSalesRow.Period;
			
			If ValueIsFilled(vSalesRow.Customer) Then
				vCustomer = vSalesRow.Customer;
				vSalesRowXDTO.CustomerCode = TrimAll(vCustomer.Code);
				vSalesRowXDTO.CustomerDescription = TrimAll(vCustomer.Description);
				vSalesRowXDTO.CustomerDateOfBirth = vCustomer.DateOfBirth;
				vSalesRowXDTO.CustomerPhone = TrimAll(vCustomer.Phone);
				vSalesRowXDTO.CustomerEMail = TrimAll(vCustomer.EMail);
				vSalesRowXDTO.CustomerTIN = TrimAll(vCustomer.TIN);
				vSalesRowXDTO.CustomerKPP = TrimAll(vCustomer.KPP);
			Else
				vSalesRowXDTO.CustomerCode = "";
				vSalesRowXDTO.CustomerDescription = "";
				vSalesRowXDTO.CustomerDateOfBirth = '00010101';
				vSalesRowXDTO.CustomerPhone = "";
				vSalesRowXDTO.CustomerEMail = "";
				vSalesRowXDTO.CustomerTIN = "";
				vSalesRowXDTO.CustomerKPP = "";
			EndIf;
			
			If ValueIsFilled(vSalesRow.Agent) Then
				vAgent = vSalesRow.Agent;
				vSalesRowXDTO.AgentCode = TrimAll(vAgent.Code);
				vSalesRowXDTO.AgentDescription = TrimAll(vAgent.Description);
				vSalesRowXDTO.AgentDateOfBirth = vAgent.DateOfBirth;
				vSalesRowXDTO.AgentPhone = TrimAll(vAgent.Phone);
				vSalesRowXDTO.AgentEMail = TrimAll(vAgent.EMail);
				vSalesRowXDTO.AgentTIN = TrimAll(vAgent.TIN);
				vSalesRowXDTO.AgentKPP = TrimAll(vAgent.KPP);
			Else
				vSalesRowXDTO.AgentCode = "";
				vSalesRowXDTO.AgentDescription = "";
				vSalesRowXDTO.AgentDateOfBirth = '00010101';
				vSalesRowXDTO.AgentPhone = "";
				vSalesRowXDTO.AgentEMail = "";
				vSalesRowXDTO.AgentTIN = "";
				vSalesRowXDTO.AgentKPP = "";
			EndIf;
			
			If ValueIsFilled(vSalesRow.Client) Then
				vClient = vSalesRow.Client;
				vSalesRowXDTO.ClientCode = TrimAll(vClient.Code);
				vSalesRowXDTO.ClientFullName = TrimAll(vClient.FullName);
				vSalesRowXDTO.ClientDateOfBirth = vClient.DateOfBirth;
				vSalesRowXDTO.ClientPhone = TrimAll(vClient.Phone);
				vSalesRowXDTO.ClientEMail = TrimAll(vClient.EMail);
			Else
				vSalesRowXDTO.ClientCode = "";
				vSalesRowXDTO.ClientFullName = "";
				vSalesRowXDTO.ClientDateOfBirth = '00010101';
				vSalesRowXDTO.ClientPhone = "";
				vSalesRowXDTO.ClientEMail = "";
			EndIf;
			
			// Payer
			vPayer = Undefined;
			vFolio = vSalesRow.Folio;
			If ValueIsFilled(vFolio) Then
				If ValueIsFilled(vFolio.Customer) And vFolio.Customer.IsIndividual Then
					vPayer = vFolio.Customer;
				ElsIf ValueIsFilled(vFolio.Client) And vFolio.Client <> vSalesRow.Client Then
					vPayer = vFolio.Client;
				EndIf;
			EndIf;
			If ValueIsFilled(vPayer) Then
				vSalesRowXDTO.PayerCode = TrimAll(vPayer.Code);
			Else
				vSalesRowXDTO.PayerCode = "";
			EndIf;
				
			If ValueIsFilled(vSalesRow.DiscountType) Then
				vSalesRowXDTO.DiscountTypeCode = TrimAll(vSalesRow.DiscountType.Code);
			Else
				vSalesRowXDTO.DiscountTypeCode = "";
			EndIf;
			
			If ValueIsFilled(vSalesRow.DiscountCard) Then
				vSalesRowXDTO.DiscountCardIdentifier = TrimAll(vSalesRow.DiscountCard.Identifier);
			Else
				vSalesRowXDTO.DiscountCardIdentifier = "";
			EndIf;
			
			If ValueIsFilled(vSalesRow.MarketingCode) Then
				vSalesRowXDTO.MarketingCodeCode = TrimAll(vSalesRow.MarketingCode.Code);
			Else
				vSalesRowXDTO.MarketingCodeCode = "";
			EndIf;
			
			If ValueIsFilled(vSalesRow.SourceOfBusiness) Then
				vSalesRowXDTO.SourceOfBusinessCode = TrimAll(vSalesRow.SourceOfBusiness.Code);
			Else
				vSalesRowXDTO.SourceOfBusinessCode = "";
			EndIf;
			
			If ValueIsFilled(vSalesRow.ClientType) Then
				vSalesRowXDTO.ClientTypeCode = TrimAll(vSalesRow.ClientType.Code);
			Else
				vSalesRowXDTO.ClientTypeCode = "";
			EndIf;
			
			If ValueIsFilled(vSalesRow.ReportingCurrency) Then
				vSalesRowXDTO.ReportingCurrencyCode = vSalesRow.ReportingCurrency.Code;
			Else
				vSalesRowXDTO.ReportingCurrencyCode = "";
			EndIf;
			
			If ValueIsFilled(vSalesRow.ParentDoc) Then
				vParentDoc = vSalesRow.ParentDoc;
				If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Then
					vSalesRowXDTO.ParentDoc = Format(vParentDoc.CheckInDate, "DF='dd.MM.yy HH:mm'") + " - " + Format(vParentDoc.CheckOutDate, "DF='dd.MM.yy HH:mm'") + ", " + vParentDoc.Duration + NStr("en=' d.'; ru=' д.'; de=' t.'") + 
					                          ", " + TrimAll(vParentDoc.Room) + " " + TrimAll(vParentDoc.RoomType.Code) + ", " + TrimAll(vParentDoc.AccommodationType);
					If ValueIsFilled(vSalesRow.Reservation) Then
						vSalesRowXDTO.ReservationDate = vSalesRow.ReservationDate;
					Else
						vSalesRowXDTO.ReservationDate = vSalesRow.ParentDocDate;
					EndIf;
				ElsIf TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Then
					vSalesRowXDTO.ParentDoc = Format(vParentDoc.CheckInDate, "DF='dd.MM.yy HH:mm'") + " - " + Format(vParentDoc.CheckOutDate, "DF='dd.MM.yy HH:mm'") + ", " + vParentDoc.Duration + NStr("en=' d.'; ru=' д.'; de=' t.'") + 
					                          ", " + TrimAll(vParentDoc.Room) + " " + TrimAll(vParentDoc.RoomType.Code) + ", " + TrimAll(vParentDoc.AccommodationType);
					vSalesRowXDTO.ReservationDate = vSalesRow.ParentDocDate;
				ElsIf TypeOf(vParentDoc) = Type("DocumentRef.ResourceReservation") Then
					vSalesRowXDTO.ParentDoc = Format(vParentDoc.DateTimeFrom, "DF='dd.MM.yy HH:mm'") + " - " + Format(vParentDoc.DateTimeTo, "DF='dd.MM.yy HH:mm'") + ", " + vParentDoc.Duration + NStr("en=' h.'; ru=' ч.'; de=' h.'") + 
					                          ", " + TrimAll(vParentDoc.Resource);
					vSalesRowXDTO.ReservationDate = vSalesRow.ParentDocDate;
				Else
					vSalesRowXDTO.ParentDoc = String(vParentDoc);
					vSalesRowXDTO.ReservationDate = '00010101';
				EndIf;
			Else
				vSalesRowXDTO.ParentDoc = "";
				vSalesRowXDTO.ReservationDate = '00010101';
			EndIf;
			
			If ValueIsFilled(vSalesRow.HotelProduct) And ValueIsFilled(vSalesRow.HotelProduct.Parent) Then
				vSalesRowXDTO.HotelProductType = TrimAll(vSalesRow.HotelProduct.Parent);
			Else
				vSalesRowXDTO.HotelProductType = "";
			EndIf;
			
			If ValueIsFilled(vSalesRow.CheckInDate) Then
				vSalesRowXDTO.CheckInDate = vSalesRow.CheckInDate;
			Else
				vSalesRowXDTO.CheckInDate = '00010101';
			EndIf;
			
			If ValueIsFilled(vSalesRow.Duration) Then
				vSalesRowXDTO.Duration = Int(vSalesRow.Duration);
			Else
				vSalesRowXDTO.Duration = 0;
			EndIf;
			
			If ValueIsFilled(vSalesRow.CheckOutDate) Then
				vSalesRowXDTO.CheckOutDate = vSalesRow.CheckOutDate;
			Else
				vSalesRowXDTO.CheckOutDate = '00010101';
			EndIf;
			
			If ValueIsFilled(vSalesRow.ReservationStatus) Then
				vSalesRowXDTO.ReservationStatus = TrimAll(vSalesRow.ReservationStatus);
			Else
				vSalesRowXDTO.ReservationStatus = "";
			EndIf;
			
			If ValueIsFilled(vSalesRow.RoomQuota) Then
				vSalesRowXDTO.RoomQuota = TrimAll(vSalesRow.RoomQuota);
			Else
				vSalesRowXDTO.RoomQuota = "";
			EndIf;
			vSalesRowXDTO.Department = TrimAll(Hotel.Description);
			
			vSalesXDTO.SalesRow.Add(vSalesRowXDTO);
			vSalesCount = vSalesCount + 1;
			
			If Int(vSalesCount / 100) = vSalesCount / 100 Then
				WriteLogEvent(NStr("en='Sales synchronization with 1C:Hotel BI';ru='Синхронизация продаж с системой 1С:Отель BI';de='Der Umsatz Synchronisation mit 1C:Hotel BI'"), EventLogLevel.Information, , , "Sales: " + vSalesCount + ", Deleted sales: " + vDeletedSalesCount);
				vResult = pHotelBIProxy.SalesSync(FullSync, vHotelCode, vPeriodsRow.PeriodFrom, vPeriodsRow.PeriodTo, vSalesXDTO, vDeletedSalesXDTO);
				WriteLogEvent(NStr("en='Sales synchronization with 1C:Hotel BI';ru='Синхронизация продаж с системой 1С:Отель BI';de='Der Umsatz Synchronisation mit 1C:Hotel BI'"), EventLogLevel.Information, , , "Sales sync result: " + vResult);
				
				If Not vDeletedSalesSent Then
					vDeletedSalesSent = True;
					vDeletedSalesXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "DeletedSales"));
				EndIf;
				
				vSalesXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "Sales"));
				vSalesCount = 0;
			EndIf;
		EndDo;
	
		// Call sales sync proxy
		If vSalesCount > 0 Then
			WriteLogEvent(NStr("en='Sales synchronization with 1C:Hotel BI';ru='Синхронизация продаж с системой 1С:Отель BI';de='Der Umsatz Synchronisation mit 1C:Hotel BI'"), EventLogLevel.Information, , , "Sales: " + vSalesCount + ", Deleted sales: " + vDeletedSalesCount);
			vResult = pHotelBIProxy.SalesSync(FullSync, vHotelCode, vPeriodsRow.PeriodFrom, vPeriodsRow.PeriodTo, vSalesXDTO, vDeletedSalesXDTO);
			WriteLogEvent(NStr("en='Sales synchronization with 1C:Hotel BI';ru='Синхронизация продаж с системой 1С:Отель BI';de='Der Umsatz Synchronisation mit 1C:Hotel BI'"), EventLogLevel.Information, , , "Sales sync result: " + vResult);
		EndIf;
	EndDo;
	
	// End
	WriteLogEvent(NStr("en='Sales synchronization with 1C:Hotel BI';ru='Синхронизация продаж с системой 1С:Отель BI';de='Der Umsatz Synchronisation mit 1C:Hotel BI'"), EventLogLevel.Information, , , "End");
EndProcedure // SendSales

Procedure SyncDealClients(pDealsList, pHotelBIProxy)
	vHotelCode = TrimAll(Hotel.Code);
	vCustomersXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "Customers"));
	vClientsXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "Clients"));
	vCustomersCount = 0;
	vClientsCount = 0;
	For Each vDeal In pDealsList Do
		vCustomerRef = vDeal.GuestGroup.Customer;
		If ValueIsFilled(vCustomerRef) Then
			vCustomerXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "Customer"));
			FillPropertyValues(vCustomerXDTO, vCustomerRef, , "RoomRate, RoomRateServiceGroup, CustomerType, PlannedPaymentMethod, AgentCommissionType, AgentCommissionServiceGroup, Contract, AgentCommissionContract, BankAccount, FeeTerms, Color, IdentityDocumentType, Author");
			vCustomerXDTO.CustomerCodeInHotel = TrimAll(vCustomerRef.Code);
			vCustomerXDTO.RoomRate = TrimAll(vCustomerRef.RoomRate);
			vCustomerXDTO.RoomRateServiceGroup = TrimAll(vCustomerRef.RoomRateServiceGroup);
			vCustomerXDTO.CustomerType = TrimAll(vCustomerRef.CustomerType);
			vCustomerXDTO.PlannedPaymentMethod = TrimAll(vCustomerRef.PlannedPaymentMethod);
			vCustomerXDTO.AgentCommissionType = TrimAll(vCustomerRef.AgentCommissionType);
			vCustomerXDTO.AgentCommissionServiceGroup = TrimAll(vCustomerRef.AgentCommissionServiceGroup);
			vCustomerXDTO.Contract = TrimAll(vCustomerRef.Contract);
			vCustomerXDTO.AgentCommissionContract = TrimAll(vCustomerRef.AgentCommissionContract);
			vCustomerXDTO.BankAccount = TrimAll(vCustomerRef.BankAccount);
			vCustomerXDTO.FeeTerms = TrimAll(vCustomerRef.FeeTerms);
			vCustomerXDTO.IdentityDocumentType = TrimAll(vCustomerRef.IdentityDocumentType);
			vCustomerXDTO.Author = TrimAll(vCustomerRef.Author);
			vCustomerXDTO.IsIndividual = vCustomerRef.IsIndividual;
			
			If ValueIsFilled(vCustomerRef.AccountingCurrency) Then
				vCustomerXDTO.AccountingCurrencyCode = vCustomerRef.AccountingCurrency.Code;
			Else
				vCustomerXDTO.AccountingCurrencyCode = "";
			EndIf;
			
			If ValueIsFilled(vCustomerRef.Language) Then
				vCustomerXDTO.LanguageCode = TrimAll(vCustomerRef.Language.Code);
			Else
				vCustomerXDTO.LanguageCode = "";
			EndIf;
			
			If ValueIsFilled(vCustomerRef.ParentOrganization) Then
				vParentOrganization = vCustomerRef.ParentOrganization;
				vCustomerXDTO.ParentOrganizationCode = TrimAll(vParentOrganization.Code);
				vCustomerXDTO.ParentOrganizationDescription = TrimAll(vParentOrganization.Description);
				vCustomerXDTO.ParentOrganizationDateOfBirth = vParentOrganization.DateOfBirth;
				vCustomerXDTO.ParentOrganizationPhone = TrimAll(vParentOrganization.Phone);
				vCustomerXDTO.ParentOrganizationEMail = TrimAll(vParentOrganization.EMail);
				vCustomerXDTO.ParentOrganizationTIN = TrimAll(vParentOrganization.TIN);
				vCustomerXDTO.ParentOrganizationKPP = TrimAll(vParentOrganization.KPP);
			Else
				vCustomerXDTO.ParentOrganizationCode = "";
				vCustomerXDTO.ParentOrganizationDescription = "";
				vCustomerXDTO.ParentOrganizationDateOfBirth = '00010101';
				vCustomerXDTO.ParentOrganizationPhone = "";
				vCustomerXDTO.ParentOrganizationEMail = "";
				vCustomerXDTO.ParentOrganizationTIN = "";
				vCustomerXDTO.ParentOrganizationKPP = "";
			EndIf;
			
			If ValueIsFilled(vCustomerRef.Agent) Then
				vAgent = vCustomerRef.Agent;
				vCustomerXDTO.AgentCode = TrimAll(vAgent.Code);
				vCustomerXDTO.AgentDescription = TrimAll(vAgent.Description);
				vCustomerXDTO.AgentDateOfBirth = vAgent.DateOfBirth;
				vCustomerXDTO.AgentPhone = TrimAll(vAgent.Phone);
				vCustomerXDTO.AgentEMail = TrimAll(vAgent.EMail);
				vCustomerXDTO.AgentTIN = TrimAll(vAgent.TIN);
				vCustomerXDTO.AgentKPP = TrimAll(vAgent.KPP);
			Else
				vCustomerXDTO.AgentCode = "";
				vCustomerXDTO.AgentDescription = "";
				vCustomerXDTO.AgentDateOfBirth = '00010101';
				vCustomerXDTO.AgentPhone = "";
				vCustomerXDTO.AgentEMail = "";
				vCustomerXDTO.AgentTIN = "";
				vCustomerXDTO.AgentKPP = "";
			EndIf;
			
			If ValueIsFilled(vCustomerRef.DiscountType) Then
				vCustomerXDTO.DiscountTypeCode = TrimAll(vCustomerRef.DiscountType.Code);
			Else
				vCustomerXDTO.DiscountTypeCode = "";
			EndIf;
			
			If ValueIsFilled(vCustomerRef.MarketingCode) Then
				vCustomerXDTO.MarketingCodeCode = TrimAll(vCustomerRef.MarketingCode.Code);
			Else
				vCustomerXDTO.MarketingCodeCode = "";
			EndIf;
			
			If ValueIsFilled(vCustomerRef.SourceOfBusiness) Then
				vCustomerXDTO.SourceOfBusinessCode = TrimAll(vCustomerRef.SourceOfBusiness.Code);
			Else
				vCustomerXDTO.SourceOfBusinessCode = "";
			EndIf;
			
			If ValueIsFilled(vCustomerRef.ClientType) Then
				vCustomerXDTO.ClientTypeCode = TrimAll(vCustomerRef.ClientType.Code);
			Else
				vCustomerXDTO.ClientTypeCode = "";
			EndIf;
			
			If vCustomerRef.Color <> Undefined Then
				vColor = vCustomerRef.Color.Get();
				If vColor <> Undefined And TypeOf(vColor) = Type("Color") Then
					vCustomerXDTO.Color = ValueToStringInternal(vColor);
				Else
					vCustomerXDTO.Color = "";
				EndIf;
			Else
				vCustomerXDTO.Color = "";
			EndIf;
			
			vCustomersXDTO.Customer.Add(vCustomerXDTO);
			vCustomersCount = vCustomersCount + 1;
			
			// Call customers sync proxy
			If Int(vCustomersCount / 50) = vCustomersCount / 50 Then
				WriteLogEvent(NStr("en='Customers synchronization with 1C:Hotel BI';ru='Синхронизация контрагентов с системой 1С:Отель BI';de='Firmen Synchronisation mit 1C:Hotel BI'"), EventLogLevel.Information, , , "Customers: " + vCustomersCount);
				vResult = pHotelBIProxy.CustomersSync(vHotelCode, vCustomersXDTO);
				WriteLogEvent(NStr("en='Customers synchronization with 1C:Hotel BI';ru='Синхронизация контрагентов с системой 1С:Отель BI';de='Firmen Synchronisation mit 1C:Hotel BI'"), EventLogLevel.Information, , , "Customers sync result: " + vResult);
				
				vCustomersXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "Customers"));
				vCustomersCount = 0;
			EndIf;
		EndIf;	
		vGuestList = GetGuestGroupGuests(vDeal.GuestGroup);
		
		While vGuestList.Next() Do
			vClientRef = vGuestList.Guest;
			If Not IsBlankString(vClientRef.FullName) Then
				vClientXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "Client"));
				FillPropertyValues(vClientXDTO, vClientRef, , "Sex, Citizenship, IdentityDocumentType, MilitaryRank, Salutation, Photo, Signature, Author, RoomRate, RoomRateServiceGroup, AgeRange");
				vClientXDTO.ClientCodeInHotel = TrimAll(vClientRef.Code);
				
				vClientXDTO.Salutation = TrimAll(vClientRef.Salutation);
				vClientXDTO.Sex = TrimAll(vClientRef.Sex);
				vClientXDTO.Citizenship = TrimAll(vClientRef.Citizenship);
				vClientXDTO.IdentityDocumentType = TrimAll(vClientRef.IdentityDocumentType);
				vClientXDTO.MilitaryRank = TrimAll(vClientRef.MilitaryRank);
				vClientXDTO.Author = TrimAll(vClientRef.Author);
				vClientXDTO.RoomRate = TrimAll(vClientRef.RoomRate);
				vClientXDTO.RoomRateServiceGroup = TrimAll(vClientRef.RoomRateServiceGroup);
				vClientXDTO.AgeRange = TrimAll(vClientRef.AgeRange);
				
				If ValueIsFilled(vClientRef.Language) Then
					vClientXDTO.LanguageCode = TrimAll(vClientRef.Language.Code);
				Else
					vClientXDTO.LanguageCode = "";
				EndIf;
				
				If ValueIsFilled(vClientRef.DiscountType) Then
					vClientXDTO.DiscountTypeCode = TrimAll(vClientRef.DiscountType.Code);
				Else
					vClientXDTO.DiscountTypeCode = "";
				EndIf;
				
				If ValueIsFilled(vClientRef.MarketingCode) Then
					vClientXDTO.MarketingCodeCode = TrimAll(vClientRef.MarketingCode.Code);
				Else
					vClientXDTO.MarketingCodeCode = "";
				EndIf;
				
				If ValueIsFilled(vClientRef.SourceOfBusiness) Then
					vClientXDTO.SourceOfBusinessCode = TrimAll(vClientRef.SourceOfBusiness.Code);
				Else
					vClientXDTO.SourceOfBusinessCode = "";
				EndIf;
				
				If ValueIsFilled(vClientRef.ClientType) Then
					vClientXDTO.ClientTypeCode = TrimAll(vClientRef.ClientType.Code);
				Else
					vClientXDTO.ClientTypeCode = "";
				EndIf;
				
				If ValueIsFilled(vClientRef.DiscountCard) Then
					vClientXDTO.DiscountCardIdentifier = TrimAll(vClientRef.DiscountCard.Identifier);
				Else
					vClientXDTO.DiscountCardIdentifier = "";
				EndIf;
				
				If vClientRef.Photo <> Undefined Then
					vPhoto = vClientRef.Photo.Get();
					If vPhoto <> Undefined And TypeOf(vPhoto) = Type("Picture") Then
						vClientXDTO.Photo = Base64String(vPhoto.GetBinaryData());
					Else
						vClientXDTO.Photo = "";
					EndIf;
				Else
					vClientXDTO.Photo = "";
				EndIf;
				
				If vClientRef.Signature <> Undefined Then
					vSignature = vClientRef.Signature.Get();
					If vSignature <> Undefined And TypeOf(vSignature) = Type("Picture") Then
						vClientXDTO.Signature = Base64String(vSignature.GetBinaryData());
					Else
						vClientXDTO.Signature = "";
					EndIf;
				Else
					vClientXDTO.Signature = "";
				EndIf;
				
				vClientXDTO.RoomPropertiesPresentation = "";
				For Each vRoomPropertiesRow In vClientRef.RoomProperties Do
					vClientXDTO.RoomPropertiesPresentation = vClientXDTO.RoomPropertiesPresentation + 
					?(IsBlankString(vClientXDTO.RoomPropertiesPresentation), "", ", ") + 
					TrimAll(vRoomPropertiesRow.RoomProperty);
				EndDo;
				
				vClientsXDTO.Client.Add(vClientXDTO);
				vClientsCount = vClientsCount + 1;
				
				// Call clients sync proxy
				If Int(vClientsCount/50) = vClientsCount/50 Then
					WriteLogEvent(NStr("en='Clients synchronization with 1C:Hotel BI';ru='Синхронизация клиентов с системой 1С:Отель BI';de='Kunden Synchronisation mit 1C:Hotel BI'"), EventLogLevel.Information, , , "Clients: " + vClientsCount);
					vResult = pHotelBIProxy.ClientsSync(vHotelCode, vClientsXDTO);
					WriteLogEvent(NStr("en='Clients synchronization with 1C:Hotel BI';ru='Синхронизация клиентов с системой 1С:Отель BI';de='Kunden Synchronisation mit 1C:Hotel BI'"), EventLogLevel.Information, , , "Clients sync result: " + vResult);
					
					vClientsXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "Clients"));
					vClientsCount = 0;
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	// Call customers sync proxy
	If vCustomersCount > 0 Then
		WriteLogEvent(NStr("en='Customers synchronization with 1C:Hotel BI';ru='Синхронизация контрагентов с системой 1С:Отель BI';de='Firmen Synchronisation mit 1C:Hotel BI'"), EventLogLevel.Information, , , "Customers: " + vCustomersCount);
		vResult = pHotelBIProxy.CustomersSync(vHotelCode, vCustomersXDTO);
		WriteLogEvent(NStr("en='Customers synchronization with 1C:Hotel BI';ru='Синхронизация контрагентов с системой 1С:Отель BI';de='Firmen Synchronisation mit 1C:Hotel BI'"), EventLogLevel.Information, , , "Customers sync result: " + vResult);
	EndIf;

	// Call clients sync proxy
	If vClientsCount > 0 Then
		WriteLogEvent(NStr("en='Clients synchronization with 1C:Hotel BI';ru='Синхронизация клиентов с системой 1С:Отель BI';de='Kunden Synchronisation mit 1C:Hotel BI'"), EventLogLevel.Information, , , "Clients: " + vClientsCount);
		vResult = pHotelBIProxy.ClientsSync(vHotelCode, vClientsXDTO);
		WriteLogEvent(NStr("en='Clients synchronization with 1C:Hotel BI';ru='Синхронизация клиентов с системой 1С:Отель BI';de='Kunden Synchronisation mit 1C:Hotel BI'"), EventLogLevel.Information, , , "Clients sync result: " + vResult);
	EndIf;
EndProcedure	

// -----------------------------------------------------------------------------
Procedure SendDeals(pHotelBIProxy, Val pLastSyncDate)
	WriteLogEvent(NStr("en = 'Deals synchronization with 1C:Hotel BI'; de = 'Deals Synchronisation mit 1C:Hotel BI'; ru = 'Синхронизация сделок с системой 1С:Отель BI'"), EventLogLevel.Information, , , "Start");
	
	vHotelCode = TrimAll(Hotel.Code);

	vDealsXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "Deals"));
	vDealsList = GetDeals(pLastSyncDate);
	
	SyncDealClients(vDealsList, pHotelBIProxy);
	
	vDealsCount = 0;
	For Each vDeal In vDealsList Do
		vDealXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "Deal"));
		
		vGuestGroup = vDeal.GuestGroup;
		vGuestGroupObj = vGuestGroup.GetObject();
		vPayments = vGuestGroupObj.pmGetPaymentsTotals();
		vIsActive = False;
		If ValueIsFilled(vGuestGroup.Status) And (vGuestGroup.Status.IsActive Or vGuestGroup.Status.IsCheckIn Or vGuestGroup.Status.IsPreliminary) Then
			vIsActive = True;
		EndIf;
		// fill payer
		If ValueIsFilled(vGuestGroup.Customer) And vGuestGroup.Customer.IsIndividual Then
			vDealXDTO.PayerCode			= vGuestGroup.Customer.Code;
			vDealXDTO.PayerDescription	= TrimAll(vGuestGroup.Customer.Description);
		ElsIf ValueIsFilled(vGuestGroup.Client) Then
			vDealXDTO.PayerCode			= vGuestGroup.Client.Code;
			vDealXDTO.PayerDescription	= TrimAll(vGuestGroup.Client.Description);
		Else
			vDealXDTO.PayerCode			= "";
			vDealXDTO.PayerDescription	= "";
		EndIf;	
		vDealXDTO.GuestGroup        = vGuestGroup.Code;
		vDealXDTO.CreateDate        = vGuestGroup.CreateDate;
		vDealXDTO.Description       = TrimAll(vGuestGroup.Description);
		vDealXDTO.Author            = TrimAll(vGuestGroup.Author);
		vDealXDTO.Remarks   		= TrimAll(vGuestGroup.Remarks);	
		vDealXDTO.CustomerCode		= TrimAll(?(ValueIsFilled(vGuestGroup.Customer),vGuestGroup.Customer.Code, ""));
		vDealXDTO.Status 			= String(vGuestGroup.Status);
		vDealXDTO.StatusIsActive 	= vIsActive;
		vDealXDTO.PayCheckDate 		= vGuestGroup.CheckDate;
		vDealXDTO.PaymentsAmount 	= vPayments.Total("Sum");
		vDealXDTO.CheckInDate 		= vGuestGroup.CheckInDate;
		vDealXDTO.CheckOutDate 		= vGuestGroup.CheckOutDate;
		vDealXDTO.NumberOfAdults 	= 0;
		vDealXDTO.NumberOfTeenagers = 0;
		vDealXDTO.NumberOfChildren 	= 0;
		vDealXDTO.NumberOfInfants 	= 0;
		vDealXDTO.Sales				= 0;
		vDealXDTO.B24EmployeeID     = vGuestGroup.Author.B24EmployeeID;
		
		vIntRef = TrimAll(HotelWebservicesAddress);
		If Not IsBlankString(vIntRef) Then
			vDealXDTO.ExternalRef = vIntRef +"#"+GetURL(vGuestGroup);
		Else
			vDealXDTO.ExternalRef = "";
		EndIf;	

		If vIsActive Then 
			// Fill guests
			vGuestList = GetGuestGroupGuests(vGuestGroup);
			
			vDealClientsXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "DealClients"));
			While vGuestList.Next() Do
				vDealClientXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "DealClient"));
				If ValueIsFilled(vGuestList.Guest) Then
					vDealClientXDTO.Code = vGuestList.Guest.Code;
					vDealClientXDTO.Description = TrimAll(vGuestList.Guest.FullName);
				Else
					vDealClientXDTO.Code = "";
					vDealClientXDTO.Description = "";
				EndIf;
				vDealClientsXDTO.DealClient.Add(vDealClientXDTO);
				
				vDealXDTO.NumberOfAdults 	= vDealXDTO.NumberOfAdults + vGuestList.NumberOfAdults;
				vDealXDTO.NumberOfTeenagers = vDealXDTO.NumberOfTeenagers + vGuestList.NumberOfTeenagers;
				vDealXDTO.NumberOfChildren 	= vDealXDTO.NumberOfChildren + vGuestList.NumberOfChildren;
				vDealXDTO.NumberOfInfants 	= vDealXDTO.NumberOfInfants + vGuestList.NumberOfInfants;
			EndDo;
			vDealXDTO.DealClients = vDealClientsXDTO;
			
			// Fill services
			vServices = vGuestGroupObj.pmGetSalesTotals(); 
			
			vDealServicesXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "DealServices"));
			For Each vServiceRow In vServices Do
				vDealServicetXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "DealService"));
				vDealServicetXDTO.ServiceCode = TrimAll(vServiceRow.Service.Code);
				vDealServicetXDTO.ServiceDescription = TrimAll(vServiceRow.Service.Description);
				vDealServicetXDTO.Sum = vServiceRow.Sales;
				
				vDealServicesXDTO.DealService.Add(vDealServicetXDTO);
			EndDo;
			vDealXDTO.DealServices = vDealServicesXDTO;
			vDealXDTO.Sales	= vServices.Total("Sales");
		Else
			// Fill cancelled guests
			vGuestListTab = vGuestGroupObj.pmGetReservations(,,True);
			vDealClientsXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "DealClients"));
			vDealServicesXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "DealServices"));
			For Each vGuestList In vGuestListTab Do
				vDealClientXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "DealClient"));
				If ValueIsFilled(vGuestList.Guest) Then
					vDealClientXDTO.Code = vGuestList.Guest.Code;
					vDealClientXDTO.Description = TrimAll(vGuestList.Guest.FullName);
				Else
					vDealClientXDTO.Code = "";
					vDealClientXDTO.Description = "";
				EndIf;
				vDealClientsXDTO.DealClient.Add(vDealClientXDTO);
				
				vDealXDTO.NumberOfAdults = vDealXDTO.NumberOfAdults + vGuestList.Reservation.NumberOfAdults;
				vDealXDTO.NumberOfTeenagers = vDealXDTO.NumberOfTeenagers + vGuestList.Reservation.NumberOfTeenagers;
				vDealXDTO.NumberOfChildren = vDealXDTO.NumberOfChildren + vGuestList.Reservation.NumberOfChildren;
				vDealXDTO.NumberOfInfants = vDealXDTO.NumberOfInfants + vGuestList.Reservation.NumberOfInfants;
				
				// Fill services
				For Each vServiceRow In vGuestList.Reservation.Services Do
					vDealServicetXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "DealService"));
					vDealServicetXDTO.ServiceCode = TrimAll(vServiceRow.Service.Code);
					vDealServicetXDTO.ServiceDescription = TrimAll(vServiceRow.Service.Description);
					vDealServicetXDTO.Sum = vServiceRow.Sum;
					
					vDealServicesXDTO.DealService.Add(vDealServicetXDTO);
				EndDo;
			EndDo;
			vDealXDTO.DealClients = vDealClientsXDTO;
			vDealXDTO.DealServices = vDealServicesXDTO;
		EndIf;
		vDealsXDTO.Deal.Add(vDealXDTO);
		vDealsCount = vDealsCount +1;
		// Call deals sync proxy
		If Int(vDealsCount / 50) = vDealsCount / 50 Then
			WriteLogEvent(NStr("en = 'Deals synchronization with 1C:Hotel BI'; de = 'Deals Synchronisation mit 1C:Hotel BI'; ru = 'Синхронизация сделок с системой 1С:Отель BI'"), EventLogLevel.Information, , , "Deals: " + vDealsCount);
			vResult = pHotelBIProxy.DealsSync(vHotelCode, vDealsXDTO);
			WriteLogEvent(NStr("en = 'Deals synchronization with 1C:Hotel BI'; de = 'Deals Synchronisation mit 1C:Hotel BI'; ru = 'Синхронизация сделок с системой 1С:Отель BI'"), EventLogLevel.Information, , , "Deals sync result: " + vResult);
			
			vDealsXDTO = pHotelBIProxy.XDTOFactory.Create(pHotelBIProxy.XDTOFactory.Type("http://www.1chotel.ru/bi/ws/interfaces/dataexchange/", "Deals"));
			vDealsCount = 0;
		EndIf;

	EndDo;
	
	// Call deals sync proxy
	If vDealsCount > 0 Then
		WriteLogEvent(NStr("en = 'Deals synchronization with 1C:Hotel BI'; de = 'Deals Synchronisation mit 1C:Hotel BI'; ru = 'Синхронизация сделок с системой 1С:Отель BI'"), EventLogLevel.Information, , , "Deals: " + vDealsCount);
		vResult = pHotelBIProxy.DealsSync(vHotelCode, vDealsXDTO);
		WriteLogEvent(NStr("en = 'Deals synchronization with 1C:Hotel BI'; de = 'Deals Synchronisation mit 1C:Hotel BI'; ru = 'Синхронизация сделок с системой 1С:Отель BI'"), EventLogLevel.Information, , , "Deals sync result: " + vResult);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
Function GetGuestGroupGuests(Val vGuestGroup)
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	Accommodation.Guest AS Guest,
	|	Accommodation.NumberOfAdults AS NumberOfAdults,
	|	Accommodation.NumberOfTeenagers AS NumberOfTeenagers,
	|	Accommodation.NumberOfChildren AS NumberOfChildren,
	|	Accommodation.NumberOfInfants AS NumberOfInfants,
	|	Accommodation.Ref AS Ref
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Posted
	|	AND ISNULL(Accommodation.AccommodationStatus.IsActive, FALSE)
	|	AND Accommodation.GuestGroup = &qGuestGroup
	|
	|UNION ALL
	|
	|SELECT
	|	Reservation.Guest,
	|	Reservation.NumberOfAdults,
	|	Reservation.NumberOfTeenagers,
	|	Reservation.NumberOfChildren,
	|	Reservation.NumberOfInfants,
	|	Reservation.Ref
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.Posted
	|	AND (Reservation.ReservationStatus.IsActive
	|			OR Reservation.ReservationStatus.IsPreliminary)
	|	AND Reservation.GuestGroup = &qGuestGroup";
	
	vQuery.SetParameter("qGuestGroup", vGuestGroup);
	
	QueryResult = vQuery.Execute();
	
	vGuestList = QueryResult.Select();
	Return vGuestList;

EndFunction

// -----------------------------------------------------------------------------
Function GetDeals(pLastSyncDate)
	
	Query = New Query;
	If FullSync Then
		vDateFrom = BegOfDay(CurrentSessionDate());
		If ValueIsFilled(FullSyncStartDate) Then 
			vDateFrom = BegOfDay(FullSyncStartDate);
		EndIf;	
		Query.Text = 
		"SELECT
		|	NestedSelect.GuestGroup AS GuestGroup
		|FROM
		|	(SELECT DISTINCT
		|		Accommodation.GuestGroup AS GuestGroup
		|	FROM
		|		Document.Accommodation AS Accommodation
		|	WHERE
		|		Accommodation.Posted
		|		AND Accommodation.DeletionMark = FALSE
		|		AND Accommodation.CheckInDate >= &qPeriodFrom
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Reservation.GuestGroup
		|	FROM
		|		Document.Reservation AS Reservation
		|	WHERE
		|		Reservation.CheckInDate >= &qPeriodFrom
		|		AND Reservation.DeletionMark = FALSE
		|		AND Reservation.Posted) AS NestedSelect
		|
		|GROUP BY
		|	NestedSelect.GuestGroup";
		
		Query.SetParameter("qPeriodFrom", vDateFrom);

	Else	
		Query.Text = 
		"SELECT DISTINCT
		|	NestedSelect.GuestGroup AS GuestGroup
		|FROM
		|	(SELECT
		|		AccommodationChangeHistorySliceLast.GuestGroup AS GuestGroup,
		|		AccommodationChangeHistorySliceLast.Accommodation.Guest AS Guest,
		|		AccommodationChangeHistorySliceLast.Accommodation.NumberOfAdults AS NumberOfAdults,
		|		AccommodationChangeHistorySliceLast.Accommodation.NumberOfTeenagers AS NumberOfTeenagers,
		|		AccommodationChangeHistorySliceLast.Accommodation.NumberOfChildren AS NumberOfChildren,
		|		AccommodationChangeHistorySliceLast.Accommodation.NumberOfInfants AS NumberOfInfants
		|	FROM
		|		InformationRegister.AccommodationChangeHistory.SliceLast(
		|				,
		|				Period >= &qPeriodFrom
		|					AND Period <= &qPeriodTo
		|					AND BEGINOFPERIOD(CheckInDate, DAY) >= BEGINOFPERIOD(&qPeriodFrom, DAY)) AS AccommodationChangeHistorySliceLast
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ReservationChangeHistorySliceLast.GuestGroup,
		|		ReservationChangeHistorySliceLast.Reservation.Guest,
		|		ReservationChangeHistorySliceLast.Reservation.NumberOfAdults,
		|		ReservationChangeHistorySliceLast.Reservation.NumberOfTeenagers,
		|		ReservationChangeHistorySliceLast.Reservation.NumberOfChildren,
		|		ReservationChangeHistorySliceLast.Reservation.NumberOfInfants
		|	FROM
		|		InformationRegister.ReservationChangeHistory.SliceLast(
		|				,
		|				Period >= &qPeriodFrom
		|					AND Period <= &qPeriodTo
		|					AND BEGINOFPERIOD(CheckInDate, DAY) >= BEGINOFPERIOD(&qPeriodFrom, DAY)) AS ReservationChangeHistorySliceLast) AS NestedSelect
		|
		|GROUP BY
		|	NestedSelect.GuestGroup
		|
		|ORDER BY
		|	NestedSelect.GuestGroup";
		
		Query.SetParameter("qPeriodFrom", pLastSyncDate);
		Query.SetParameter("qPeriodTo", CurrentSessionDate());
	EndIf;
	QueryResult = Query.Execute();
	
	Return QueryResult.Unload();	
EndFunction	
	
// -----------------------------------------------------------------------------
Function GetGuestActiveReservations(pClient)
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	OneRoomGuests.Ref AS Ref,
	|	OneRoomGuests.Guest AS Guest,
	|	OneRoomGuests.PointInTime AS PointInTime
	|FROM
	|	Document.Reservation AS OneRoomGuests
	|		INNER JOIN (SELECT
	|			GuestReservations.Ref AS Ref,
	|			GuestReservations.GuestGroup AS GuestGroup,
	|			GuestReservations.Guest AS Guest,
	|			GuestReservations.Room AS Room,
	|			GuestReservations.Number AS Number
	|		FROM
	|			Document.Reservation AS GuestReservations
	|		WHERE
	|			GuestReservations.Posted
	|			AND GuestReservations.ReservationStatus.IsActive
	|			AND NOT GuestReservations.ReservationStatus.IsCheckIn
	|			AND GuestReservations.Guest = &qGuest) AS ClientReservations
	|		ON OneRoomGuests.GuestGroup = ClientReservations.GuestGroup
	|			AND (OneRoomGuests.Room = ClientReservations.Room
	|					AND OneRoomGuests.Room <> &qEmptyRoom
	|				OR OneRoomGuests.Number = ClientReservations.Number
	|					AND OneRoomGuests.Room = &qEmptyRoom)
	|WHERE
	|	OneRoomGuests.Posted
	|	AND OneRoomGuests.ReservationStatus.IsActive
	|	AND NOT OneRoomGuests.ReservationStatus.IsCheckIn
	|
	|ORDER BY
	|	OneRoomGuests.PointInTime";
	vQry.SetParameter("qEmptyRoom", Catalogs.Rooms.EmptyRef());
	vQry.SetParameter("qGuest", pClient);
	Return vQry.Execute().Unload();
EndFunction // GetGuestActiveReservations

// -----------------------------------------------------------------------------
Function GetCustomerActiveReservations(pCustomer)
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	OneRoomGuests.Ref AS Ref,
	|	OneRoomGuests.Guest AS Guest,
	|	OneRoomGuests.PointInTime AS PointInTime
	|FROM
	|	Document.Reservation AS OneRoomGuests
	|		INNER JOIN (SELECT
	|			GuestReservations.Ref AS Ref,
	|			GuestReservations.GuestGroup AS GuestGroup,
	|			GuestReservations.Guest AS Guest,
	|			GuestReservations.Room AS Room,
	|			GuestReservations.Number AS Number
	|		FROM
	|			Document.Reservation AS GuestReservations
	|		WHERE
	|			GuestReservations.Posted
	|			AND GuestReservations.ReservationStatus.IsActive
	|			AND NOT GuestReservations.ReservationStatus.IsCheckIn
	|			AND GuestReservations.Customer = &qCustomer) AS ClientReservations
	|		ON OneRoomGuests.GuestGroup = ClientReservations.GuestGroup
	|			AND (OneRoomGuests.Room = ClientReservations.Room
	|					AND OneRoomGuests.Room <> &qEmptyRoom
	|				OR OneRoomGuests.Number = ClientReservations.Number
	|					AND OneRoomGuests.Room = &qEmptyRoom)
	|WHERE
	|	OneRoomGuests.Posted
	|	AND OneRoomGuests.ReservationStatus.IsActive
	|	AND NOT OneRoomGuests.ReservationStatus.IsCheckIn
	|
	|ORDER BY
	|	OneRoomGuests.PointInTime";
	vQry.SetParameter("qEmptyRoom", Catalogs.Rooms.EmptyRef());
	vQry.SetParameter("qCustomer", pCustomer);
	Return vQry.Execute().Unload();
EndFunction // GetCustomerActiveReservations

#EndRegion
