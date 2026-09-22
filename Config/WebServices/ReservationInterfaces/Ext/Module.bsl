
#Region EventHandlers

// -----------------------------------------------------------------------------
Function CancelGroupReservation(pGuestGroupCode, pHotel, pExternalSystemCode, pLanguageCode = "RU", pReason = "", pExtReservationCode = "")
	Return cmCancelGroupReservation(pGuestGroupCode, pHotel, pExternalSystemCode, pLanguageCode, pReason, pExtReservationCode);
EndFunction // CancelGroupReservation

// -----------------------------------------------------------------------------
Function CheckInGroupReservation(pEMail, pPhone, pLogin, pGuestGroupCode, pReservationCode, pExtraCheckInData, pHotel, pExternalSystemCode, pLanguageCode)
	Return cmCheckInGroupReservation(pEMail, pPhone, pLogin, pGuestGroupCode, pReservationCode, pExtraCheckInData, pHotel, pExternalSystemCode, pLanguageCode);
EndFunction // CheckInGroupReservation

// -----------------------------------------------------------------------------
Function CheckOutGroupReservation(pEMail, pPhone, pLogin, pGuestGroupCode, pReservationCode, pExtraCheckOutData, pHotel, pExternalSystemCode, pLanguageCode)
	Return cmCheckOutGroupReservation(pEMail, pPhone, pLogin, pGuestGroupCode, pReservationCode, pExtraCheckOutData, pHotel, pExternalSystemCode, pLanguageCode);
EndFunction // CheckOutGroupReservation

// -----------------------------------------------------------------------------
Function CreateOrder(pExternalSystemCode, pHotel, pExternalOrderCode, pType, pDepartment, pOrderTime, pGuestGroup, pParentDocNumber, pGuestName, pRemarks, // Main parametr 
					pPickupFrom, pDestination, pPassengersNumber, pChildSeatsNumber, pCarType,  // Transfer parametr 
					pRentTime, pRentResourcesId,  // Rent parametr 
					pItems, pSum) // Room services parametr 
	vHotel = SessionParameters.CurrentHotel;
	If Not IsBlankString(pHotel) Then
		vHotel = cmGetHotelByCode(pHotel, pExternalSystemCode);
	EndIf;
	// Get department
	vDepartment = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "Departments", pDepartment);
	// Get type
	vType = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "Ordertypes",pType);
	
	If ValueIsFilled(vType) Then
		
		vParentDoc = Orders.GetParentDoc(vHotel, pGuestGroup, pParentDocNumber);
		If ValueIsFilled(vParentDoc) Then
			If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Then	
				vClient = vParentDoc.Guest;		
			ElsIf TypeOf(vParentDoc) = Type("DocumentRef.ResourceReservation") or TypeOf(vParentDoc) = Type("DocumentRef.Folio") Then
				vClient  = vParentDoc.Client;
			EndIf;			
		Else
			vClient = Catalogs.Clients.FindByAttribute("FullName",pGuestName);
			If not ValueIsFilled(vClient) Then
				Return NStr("en='Client not found!'; ru='Клиент не найден!'; de='Client nicht gefunden!'");				
			EndIf;				
		EndIf;
		
		If vType.PredefinedDataName = "Rent" Then
			If not ValueIsFilled(pRentTime) Then
				Return NStr("en='Rental resource lease time is not filled!'; ru='Не заполнено время аренды объекта'; de='Mietdauer ist nicht belegt!'");
			EndIf;
			
			vRentResources = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "Resources", pRentResourcesId);
			If not ValueIsFilled(vRentResources) Then
				Return NStr("en='Error determining rental resource!'; ru='Ошибка определения арендуемого ресурса!'; de='Fehler beim Bestimmen der Mietressource!'");
			EndIf;
			
			Orders.CreateOrderFromObjects(pExternalSystemCode, vHotel, pExternalOrderCode, vType, vDepartment, pOrderTime, vClient,, , pRemarks,pSum,,,,,,pRentTime,vRentResources,,vParentDoc,pGuestGroup);			
			
		ElsIf vType.PredefinedDataName = "RoomService" Then
			
			If pItems.OrderItem.Count() = 0 Then
				Return NStr("en='The table of order items is not filled!'; ru='Не заполнена таблица позиций заказа!'; de='Die Tabelle der Auftragspositionen ist nicht gefüllt!'");
			EndIf;
			
			vOrderItems = New ValueTable;
			vOrderItems.Columns.Add("Item");
			vOrderItems.Columns.Add("Count");
			vOrderItems.Columns.Add("Price");
			
			For Each ItemRow In pItems.OrderItem Do
				
				vItem = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "OrderItems", ItemRow.ItemId);
				If not ValueIsFilled(vItem) Then 
					OrderItem = Catalogs.OrderItems.CreateItem();
					OrderItem.Description = ItemRow.ItemName;
					OrderItem.Price	      = ItemRow.Price;
					OrderItem.Code        = ItemRow.ItemId;
					OrderItem.Write();
					vItem = OrderItem.Ref;	
				EndIf;
				
				vNewRow = vOrderItems.Add();
				vNewRow.Item  = vItem;
				vNewRow.Count = ItemRow.Count; 
				vNewRow.Price = ItemRow.Price;				
				
			EndDo;
			Orders.CreateOrderFromObjects(pExternalSystemCode, vHotel, pExternalOrderCode, vType, vDepartment, pOrderTime, vClient, , , pRemarks, pSum, , , , , , , , vOrderItems,vParentDoc,pGuestGroup);
		ElsIf vType.PredefinedDataName = "Transfer" Then
			Orders.CreateOrderFromObjects(pExternalSystemCode, vHotel, pExternalOrderCode, vType, vDepartment, pOrderTime, vClient, , , pRemarks, pSum, pPickupFrom, pDestination, pPassengersNumber, pChildSeatsNumber, pCarType,,,,vParentDoc,pGuestGroup);
		EndIf;
		Return "";
	Else
		Return NStr("en='Order type not found!'; ru='Тип заказа не существует!'; de='Bestelltyp nicht gefunden!'");
	EndIf;
EndFunction // CreateOrder

// -----------------------------------------------------------------------------
Function GetActiveGroupsList(pLogin, pHotel, pExternalSystemCode, pLanguageCode)
	Return cmGetActiveGroupsList(pLogin, pHotel, pExternalSystemCode, pLanguageCode);
EndFunction // GetActiveGroupsList

// -----------------------------------------------------------------------------
Function GetActiveReservations(pHotel, pGuestName, pGuestGroup, pExternalSystemCode, pLanguageCode)
	Return cmGetActiveReservations(pHotel, pGuestName, pGuestGroup, pExternalSystemCode, pLanguageCode);    	
EndFunction // GetActiveReservations

// -----------------------------------------------------------------------------
Function GetAgentDetails(pHotelCode, pEMail, pExternalSystemCode)
	WriteLogEvent(NStr("en='Get agent details';ru='Получить данные агента';de='Erstellen Sie neue Mittel'"), EventLogLevel.Information, , , 
					NStr("en='Hotel code: ';ru='Код гостиницы: ';de='Code Hotel: '") + pHotelCode + Chars.LF 
					+ NStr("en='External system code: ';ru='Код внешней системы: ';de='Code des externen Systems: '") + pExternalSystemCode + Chars.LF 
					+ NStr("en='E-Mail: '; ru='E-Mail: '") + pEMail);
	vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "ContractInfo"));
	If ValueIsFilled(pHotelCode) Then
		// Try to find hotel by name or code
		vHotelRef = cmGetHotelByCode(pHotelCode, pExternalSystemCode);
	Else
		vHotelRef = SessionParameters.CurrentHotel;
	EndIf;
	
	// Try to update existing mapping or create new one
	vFilter = New Structure();
	vFilter.Insert("Hotel", vHotelRef);
	vFilter.Insert("ExternalSystemCode", pExternalSystemCode);
	vFilter.Insert("ObjectTypeName", "Contracts");
	vFilter.Insert("ObjectExternalCode", TrimAll(pEMail));
	vResStruc = InformationRegisters.ExternalSystemsObjectCodesMappings.Get(vFilter);
	vContractRef = Catalogs.Contracts.EmptyRef();
	If ValueIsFilled(vResStruc) Then
		vContractRef = vResStruc.ObjectRef;
	EndIf;
	If ValueIsFilled(vContractRef) Then
		WriteLogEvent(NStr("en='Get agent details';ru='Получить данные агента';de='Erstellen Sie neue Mittel'"), EventLogLevel.Information, , vContractRef, 
		NStr("en='Contract';ru='Договор';de='Contract'"));
		If ValueIsFilled(vContractRef.Owner) Then
			WriteLogEvent(NStr("en='Get agent details';ru='Получить данные агента';de='Erstellen Sie neue Mittel'"), EventLogLevel.Information, , vContractRef.Owner, 
			NStr("en='Customer';ru='Контрагент';de='Kunden'"));
			vRetXDTO.ContractCode = TrimAll(vContractRef.Code);
			vRetXDTO.CustomerDescription = TrimAll(vContractRef.Owner.Description);
			vRetXDTO.LegacyAddress = TrimAll(vContractRef.Owner.LegacyAddress);
			vRetXDTO.PostAddress = TrimAll(vContractRef.Owner.PostAddress);
			vRetXDTO.Phone = SMS.GetValidPhoneNumber(vContractRef.Owner.Phone);
			vRetXDTO.EMail = TrimAll(vContractRef.Owner.EMail);
			vRetXDTO.TIN = TrimAll(vContractRef.Owner.TIN);
			vRetXDTO.KPP = TrimAll(vContractRef.Owner.KPP);
			vRetXDTO.ContactPerson = TrimAll(vContractRef.Owner.ContactPerson);
		Else
			vRetXDTO.ErrorDescription = NStr("ru='Ошибка поиска\создания контрагента'; en='Customer is not created'; de='Kunde wird nicht erstellt'");
		EndIf;
	Else
		vRetXDTO.ErrorDescription = NStr("ru='Ошибка поиска\создания договора'; en='Contract is not created'; de='Vertrag wird nicht erstellt'");
	EndIf;
	Return vRetXDTO;
EndFunction // GetAgentDetails

// -----------------------------------------------------------------------------
Function GetAgentGroupsList(pLogin, pHotel, pExternalSystemCode, pPeriodFrom, pPeriodTo, pLanguageCode)
	Return cmGetAgentGroupsList(pLogin, pHotel, pExternalSystemCode, pPeriodFrom, pPeriodTo, pLanguageCode);
EndFunction // GetActiveGroupsList

// -----------------------------------------------------------------------------
Function GetAgentReport(pLogin, pHotel, pExternalSystemCode, pLanguageCode, pDateFrom, pDateTo)
	WriteLogEvent(NStr("en='Get agent report'; de='Get agent report'; ru='Получить отчет агента'"), EventLogLevel.Information, , , 
					NStr("en='External system code: ';ru='Код внешней системы: ';de='Code des externen Systems:'") + pExternalSystemCode + Chars.LF 
					+ NStr("en='Hotel code: ';ru='Код гостиницы: ';de='Code des Hotels: '") + pHotel + Chars.LF 
					+ NStr("en='Login: '; de='Login: '; ru='Логин: '") + pLogin + Chars.LF 
					+ NStr("en='Date from: '; de='Date from: '; ru='Дата заезда: '") + pDateFrom + Chars.LF 
					+ NStr("en='Date to: '; de='Date to: '; ru='Дата выезда: '") + pDateTo + Chars.LF 
					+ NStr("en='Language code: ';ru='Код языка: ';de='Sprachencode: '") + pLanguageCode);
	vHotel = cmGetHotelByCode(pHotel, pExternalSystemCode);
	vCustomerStruct = cmGetCustomerByLogin(vHotel, pExternalSystemCode, pLogin);
	If vCustomerStruct <> Undefined Then
		If Not ValueIsFilled(vCustomerStruct.Customer) Then
			vError = NStr("en='You have specified wrong login!'; de='You have specified wrong login!'; ru='Указан неверный логин!'");
			WriteLogEvent(NStr("en='Get agent report'; de='Get agent report'; ru='Получить отчет агента'"), EventLogLevel.Error, , , vError);
			Return vError;
		EndIf;
	Else
		vError = NStr("en='You have specified wrong login!'; de='You have specified wrong login!'; ru='Указан неверный логин!'");
		WriteLogEvent(NStr("en='Get agent report'; de='Get agent report'; ru='Получить отчет агента'"), EventLogLevel.Error, , , vError);
		Return vError;
	EndIf;
	If Not IsBlankString(pLanguageCode) Then
		vLanguage = cmGetLanguageByCode(pLanguageCode);
	EndIf;
	
	// Create report object
	vAgentReportObj = Reports.CustomerGuests.Create();
	vAgentReportObj.Report = Catalogs.Reports.CustomerGuests;
	vAgentReportObj.pmLoadReportAttributes();
	vAgentReportObj.Customer = vCustomerStruct.Customer;
	vAgentReportObj.Contract = vCustomerStruct.Contract;
	vAgentReportObj.PeriodFrom = BegOfDay(pDateFrom);
	vAgentReportObj.PeriodTo = EndOfDay(pDateTo);
	vAgentReportObj.Hotel = vHotel;
	vAgentReportObj.PeriodCheckType = Enums.PeriodCheckTypes.StartsInPeriod;
	If Not ValueIsFilled(vLanguage) Then
		vLanguage = vAgentReportObj.Customer.Language;
	EndIf;
	
	// Create spreadsheet
	vSpreadsheet = New SpreadsheetDocument();
	
	// Set report builder attributes
	cmSetReportBuilderAttributes(vAgentReportObj, cmGetReportBuilderAttributesStructure());
	
	// Fill spreadsheet
	vAgentReportObj.pmGenerate(vSpreadsheet);
	
	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Landscape, True);
	
	// Check authorities
	cmSetSpreadsheetProtection(vSpreadsheet);
	
	// Get file and save catalog names
	vFileName = cmNStr(TrimAll(vAgentReportObj.Report.Description), vLanguage) + " " + TrimAll(vAgentReportObj.Customer.Description) + " " + Format(vAgentReportObj.PeriodFrom, "DF=dd.MM.yyyy") + " - " + Format(vAgentReportObj.PeriodTo, "DF=dd.MM.yyyy"); 
	vFileSaveCatalog = TempFilesDir();
	
	// Send report as pdf by e-mail
	If Not IsBlankString(vAgentReportObj.Customer.EMail) Then
		vFullFileName = cmGetFullFileName(vFileName + ".pdf", vFileSaveCatalog);
		vSpreadsheet.Write(vFullFileName, SpreadsheetDocumentFileType.PDF);
		vSenderName = ?(ValueIsFilled(vHotel), Catalogs.Hotels.pmGetHotelPrintName(vHotel, vLanguage), "");
		vSubject = vFileName;
		vMessage = cmNStr("ru = 'Рассылка отчетов агента: '; 
		|de = 'Agent report delivery: ';
		|en = 'Agent report delivery: '", vLanguage) + Chars.LF + Chars.LF + 
		vFileName + Chars.LF + Chars.LF + 
		cmNStr("ru='C уважением, ';
		|de='Hochachtungsvoll, ';
		|en='Best regards, '", vLanguage) + Chars.LF + 
		cmNStr(SessionParameters.ConfigurationName, vLanguage);
		vFilesMap = New Map;
		vFilesMap.Insert(vFileName, vFullFileName);
		If JobsScheduled.cmSendFilesByEMail(vSubject, vMessage, TrimAll(vAgentReportObj.Customer.EMail), vFilesMap, vLanguage, True, Undefined, vSenderName) Then
			WriteLogEvent(NStr("en='Get agent report'; de='Get agent report'; ru='Получить отчет агента'"), EventLogLevel.Information, , , NStr("ru='Электронное письмо было успешно отправлено!';de='Die E-Mail wurde erfolgreich verschickt!';en='E-Mail was successfully sent!'"));
		Else
			WriteLogEvent(NStr("en='Get agent report'; de='Get agent report'; ru='Получить отчет агента'"), EventLogLevel.Error, , , NStr("ru='Отправить электронное письмо не удалось!';de='Die E-Mail konnte nicht geöffnet werden!';en='Failed to send E-Mail!'"));
		EndIf;
		DeleteFiles(vFullFileName);
	EndIf;
	
	// Return report as base64 string
	vFullFileName = cmGetFullFileName(vFileName + ".pdf", vFileSaveCatalog);
	vSpreadsheet.Write(vFullFileName, SpreadsheetDocumentFileType.PDF);
	vBD = New BinaryData(vFullFileName);
	vString64 = Base64String(vBD);
	DeleteFiles(vFullFileName);
	
	Return "Base64"+vString64;
EndFunction // GetAgentReport

// -----------------------------------------------------------------------------
Function GetAllReservationsWithTransactions(pHotel, pGuestGroup, pPeriodFrom, pPeriodTo, pExternalSystemCode)
	Return cmGetAllReservationsWithTransactions(pHotel, pGuestGroup, pPeriodFrom, pPeriodTo, pExternalSystemCode);
EndFunction // GetAllReservationsWithTransactions

// -----------------------------------------------------------------------------
Function GetAvailableRoomsWithDailyPrices(pHotel, pRoomType, pRoomQuota, pPeriodFrom, pPeriodTo, pClientType, pRoomRates, pGuestsQuantity, pClientIsAuthorized = False, pExternalSystemCode, pLanguageCode, pExtraParameters)
	vRoomRateCodesArray = New Array();
	For Each vRoomRateCode In pRoomRates.RoomRate Do
		vRoomRateCodesArray.Add(vRoomRateCode);
	EndDo;
	vNumberOfAdults = pGuestsQuantity.Adults.Quantity;
	vNumberOfKids = pGuestsQuantity.Kids.Quantity;
	vKidsAgeArray = New Array();
	For Each vKidAge In pGuestsQuantity.Kids.Age Do
		vKidsAgeArray.Add(vKidAge);
	EndDo;
	Return cmGetAvailableRoomsWithDailyPrices(pHotel, pRoomType, pRoomQuota, pPeriodFrom, pPeriodTo, pClientType, vRoomRateCodesArray, vNumberOfAdults, vNumberOfKids, vKidsAgeArray, pClientIsAuthorized, pExternalSystemCode, pLanguageCode, pExtraParameters);
EndFunction // GetAvailableRoomsWithDailyPrices

// -----------------------------------------------------------------------------
Function GetAvailableRoomTypes(pHotel, pRoomRate, pClientType, pRoomType, pRoomQuota, pPeriodFrom, pPeriodTo, pExternalSystemCode, pLanguageCode, pGuestsQuantity, pEMail, pPhone, pLogin, pPromoCode)
	Return cmGetAvailableRoomTypes(pHotel, pRoomRate, pClientType, pRoomType, pRoomQuota, pPeriodFrom, pPeriodTo, pExternalSystemCode, pLanguageCode, pGuestsQuantity, pEMail, pPhone, pLogin, pPromoCode, "XDTO");
EndFunction // GetAvailableRoomTypes

// -----------------------------------------------------------------------------
Function GetAvailableRoomTypesExt(pHotel, pRoomRate, pClientType, pRoomType, pRoomQuota, pPeriodFrom, pPeriodTo, pExternalSystemCode, pLanguageCode, pGuestsQuantity, pEMail, pPhone, pLogin, pPromoCode, pExtraParams)
	Return cmGetAvailableRoomTypes(pHotel, pRoomRate, pClientType, pRoomType, pRoomQuota, pPeriodFrom, pPeriodTo, pExternalSystemCode, pLanguageCode, pGuestsQuantity, pEMail, pPhone, pLogin, pPromoCode, "XDTO", pExtraParams);
EndFunction // GetAvailableRoomTypesExt

// -----------------------------------------------------------------------------
Function GetAvailableRoomTypesWithPrices(pHotel, pRoomRate, pClientType, pRoomType, pRoomQuota, pPeriodFrom, pPeriodTo, pExternalSystemCode, pLanguageCode)
	Return cmGetAvailableRoomTypesWithPrices(pHotel, pRoomRate, pClientType, pRoomType, pRoomQuota, pPeriodFrom, pPeriodTo, pExternalSystemCode, pLanguageCode, "XDTO");
EndFunction // GetAvailableRoomTypesWithPrices

// -----------------------------------------------------------------------------
Function GetClientByPhoneAndEMail(pPhone, pEMail)
	WriteLogEvent(NStr("en='Get client by phone and e-mail';ru='Получить клиента по телефону и E-Mail';de='Holen Kunde per Telefon und E-Mail'"), EventLogLevel.Information, , , 
					NStr("en='Phone: '; de='Telefon: '; ru='Телефон: '") + pPhone + Chars.LF 
					+ NStr("en='E-Mail: '; de='E-Mail: '; ru='E-Mail: '") + pEMail);
	vClientRef = cmGetClientByPhoneAndEMail(pPhone, pEMail);
	If ValueIsFilled(vClientRef) Then
		vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
		vRetXDTO.ClientLastName = TrimAll(vClientRef.LastName);
		vRetXDTO.ClientFirstName = TrimAll(vClientRef.FirstName);
		vRetXDTO.ClientSecondName = TrimAll(vClientRef.SecondName);
		vRetXDTO.ClientSex = Left(TrimAll(String(vClientRef.Sex)), 1);
		vRetXDTO.ClientCitizenship = TrimAll(vClientRef.Citizenship.ISOCode);
		vRetXDTO.ClientBirthDate = vClientRef.DateOfBirth;
		vRetXDTO.ClientPhone = TrimAll(vClientRef.Phone);
		vRetXDTO.ClientEMail = TrimAll(vClientRef.EMail);
		vRetXDTO.ClientSendSMS = Not vClientRef.NoSMSDelivery;
		vRetXDTO.ClientCode = vClientRef.Code;
		WriteLogEvent(NStr("en='Get client by phone and e-mail';ru='Получить клиента по телефону и E-Mail';de='Holen Kunde per Telefon und E-Mail'"), EventLogLevel.Information, , , 
		NStr("en='Client last name: ';ru='Фамилия гостя: ';de='Familienname des Gastes: '") + vRetXDTO.ClientLastName + Chars.LF 
		+ NStr("en='Client first name: ';ru='Имя гостя: ';de='Name des Gastes: '") + vRetXDTO.ClientFirstName + Chars.LF 
		+ NStr("en='Client second name: ';ru='Отчество гостя: ';de='Vatersname des Gastes: '") + vRetXDTO.ClientSecondName + Chars.LF 
		+ NStr("en='Client sex code: ';ru='Код пола гостя: ';de='Code des Geschlechts des Gastes: '") + vRetXDTO.ClientSex + Chars.LF 
		+ NStr("en='Client citizenship code: ';ru='Код гражданства гостя: ';de='Code der Stadtbürgerschaft des Gastes: '") + vRetXDTO.ClientCitizenship + Chars.LF 
		+ NStr("en='Client birth date: ';ru='Дата рождения гостя: ';de='Geburtsdatum des Gastes: '") + vRetXDTO.ClientBirthDate + Chars.LF 
		+ NStr("en='Client phone: ';ru='Телефон гостя: ';de='Telefon des Gastes: '") + vRetXDTO.ClientPhone + Chars.LF 
		+ NStr("en='Client E-Mail: ';ru='E-Mail гостя: ';de='E-Mail-Adresse des Gastes: '") + vRetXDTO.ClientEMail);
	Else
		WriteLogEvent(NStr("en='Client not found!';ru='Клиент не найден!';de='Kunde nicht gefunden!'"), EventLogLevel.Information);
		vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
		vRetXDTO.ClientLastName = "";
		vRetXDTO.ClientFirstName = "";
		vRetXDTO.ClientSecondName = "";
		vRetXDTO.ClientSex = "";
		vRetXDTO.ClientCitizenship = "";
		vRetXDTO.ClientBirthDate = '00010101';
		vRetXDTO.ClientPhone = "";
		vRetXDTO.ClientEMail = "";
		vRetXDTO.ClientSendSMS = false;		
		vRetXDTO.ClientCode = "";
	EndIf;
	Return vRetXDTO;
EndFunction // GetClientByPhoneAndEMail

// -----------------------------------------------------------------------------
Function GetClientByPromoCode(pPromoCode)
	WriteLogEvent(NStr("en='Get promo code';ru='Получить клиента по промо коду';de='Holen Kunde per Promo Code'"), EventLogLevel.Information, , , 
					NStr("en='Promo code: ';de='Promo Code: ';ru='Промо код: '") + pPromoCode);
	vClientRef = cmGetClientByPromoCode(pPromoCode);
	If ValueIsFilled(vClientRef) Then
		vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
		vRetXDTO.ClientLastName = TrimAll(vClientRef.LastName);
		vRetXDTO.ClientFirstName = TrimAll(vClientRef.FirstName);
		vRetXDTO.ClientSecondName = TrimAll(vClientRef.SecondName);
		vRetXDTO.ClientSex = Left(TrimAll(String(vClientRef.Sex)), 1);
		vRetXDTO.ClientCitizenship = TrimAll(vClientRef.Citizenship.ISOCode);
		vRetXDTO.ClientBirthDate = vClientRef.DateOfBirth;
		vRetXDTO.ClientPhone = TrimAll(vClientRef.Phone);
		vRetXDTO.ClientEMail = TrimAll(vClientRef.EMail);
		vRetXDTO.ClientSendSMS = Not vClientRef.NoSMSDelivery;
		vRetXDTO.ClientCode = vClientRef.Code;
		WriteLogEvent(NStr("en='Get promo code';ru='Получить клиента по промо коду';de='Holen Kunde per Promo Code'"), EventLogLevel.Information, , , 
		NStr("en='Client last name: ';ru='Фамилия гостя: ';de='Familienname des Gastes: '") + vRetXDTO.ClientLastName + Chars.LF + 
		NStr("en='Client first name: ';ru='Имя гостя: ';de='Name des Gastes: '") + vRetXDTO.ClientFirstName + Chars.LF + 
		NStr("en='Client second name: ';ru='Отчество гостя: ';de='Vatersname des Gastes: '") + vRetXDTO.ClientSecondName + Chars.LF + 
		NStr("en='Client sex code: ';ru='Код пола гостя: ';de='Code des Geschlechts des Gastes: '") + vRetXDTO.ClientSex + Chars.LF + 
		NStr("en='Client citizenship code: ';ru='Код гражданства гостя: ';de='Code der Stadtbürgerschaft des Gastes: '") + vRetXDTO.ClientCitizenship + Chars.LF + 
		NStr("en='Client birth date: ';ru='Дата рождения гостя: ';de='Geburtsdatum des Gastes: '") + vRetXDTO.ClientBirthDate + Chars.LF + 
		NStr("en='Client phone: ';ru='Телефон гостя: ';de='Telefon des Gastes: '") + vRetXDTO.ClientPhone + Chars.LF + 
		NStr("en='Client E-Mail: ';ru='E-Mail гостя: ';de='E-Mail-Adresse des Gastes: '") + vRetXDTO.ClientEMail);
	Else
		WriteLogEvent(NStr("en='Client not found!';ru='Клиент не найден!';de='Kunde nicht gefunden!'"), EventLogLevel.Information);
		vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
		vRetXDTO.ClientLastName = "";
		vRetXDTO.ClientFirstName = "";
		vRetXDTO.ClientSecondName = "";
		vRetXDTO.ClientSex = "";
		vRetXDTO.ClientCitizenship = "";
		vRetXDTO.ClientBirthDate = '00010101';
		vRetXDTO.ClientPhone = "";
		vRetXDTO.ClientEMail = "";
		vRetXDTO.ClientSendSMS = false;		
		vRetXDTO.ClientCode = "";
	EndIf;
	Return vRetXDTO;
EndFunction // GetClientByPromoCode

// -----------------------------------------------------------------------------
Function GetClientGuestGroupsList(pClientCode, pHotel, pExternalSystemCode, pPeriodFrom, pPeriodTo, pLanguageCode, pStatusFilter)
	Return cmGetCientGuestGroupsList(pClientCode, pHotel, pExternalSystemCode, pPeriodFrom, pPeriodTo, pLanguageCode, pStatusFilter);
EndFunction // GetClientGuestGroupsList

// -----------------------------------------------------------------------------
Function GetExternalGroupReservationStatus(pGuestGroupCode, pHotel, pExternalSystemCode, pLanguageCode)
	Return cmGetExternalGroupReservationStatus(pGuestGroupCode, pHotel, pExternalSystemCode, pLanguageCode, "XDTO");
EndFunction // GetExternalGroupReservationStatus

// -----------------------------------------------------------------------------
Function GetExternalReservationStatus(pReservationCode, pHotel, pExternalSystemCode, pLanguageCode)
	Return cmGetExternalReservationStatus(pReservationCode, pHotel, pExternalSystemCode, pLanguageCode, "XDTO");
EndFunction // GetExternalReservationStatus

// -----------------------------------------------------------------------------
Function GetExtraServices(pHotel, pServiceType, pClientType, pExternalSystemCode, pLanguageCode)
	Return cmGetExtraServices(pHotel, pServiceType, pClientType, pExternalSystemCode, pLanguageCode);
EndFunction // GetExtraServices

// -----------------------------------------------------------------------------
Function GetGroupReservationDetails(pEMail, pPhone, pLogin, pGuestGroupCode, pHotel, pExternalSystemCode, pLanguageCode)
	Return cmGetGroupReservationDetails(pEMail, pPhone, pLogin, pGuestGroupCode, pHotel, pExternalSystemCode, pLanguageCode, "XDTO");
EndFunction // GetGroupReservationDetails

// -----------------------------------------------------------------------------
Function GetHotelParameters(pHotel, pExternalSystemCode, pLanguageCode, pRoomRate)
	Return cmGetHotelParameters(pHotel, pExternalSystemCode, pLanguageCode, "XDTO", pRoomRate);
EndFunction // GetHotelParameters

// -----------------------------------------------------------------------------
Function GetHotelsList(pExternalSystemCode, pLanguageCode)
	Return cmGetHotelsList(pExternalSystemCode, pLanguageCode);
EndFunction // GetHotelsList

// -----------------------------------------------------------------------------
Function GetIdentityDocumentsList()
	Return cmGetIdentityDocumentsList();
EndFunction // GetIdentityDocumentsList

// -----------------------------------------------------------------------------
Function GetPDF(pDocumentPrintingForm, pExternalSystemCode, pHotelCode)
	Return cmGetObjectPrintingFormPDF(pDocumentPrintingForm, pExternalSystemCode, pHotelCode); 
EndFunction // GetPDF

// -----------------------------------------------------------------------------
Function GetRoomInventoryBalance(pHotel, pRoomType, pCustomer, pContract, pAgent, pRoomQuota, 
									pPeriodFrom, pPeriodTo, pRoomRate, pClientType, 
									pOutputRoomsVacant, pOutputBedsVacant, pOutputRoomsRemains, pOutputBedsRemains, 
									pOutputRoomsInQuota, pOutputBedsInQuota, pOutputRoomsChargedInQuota, pOutputBedsChargedInQuota, 
									pOutputRoomsReserved, pOutputBedsReserved, pOutputInHouseRooms, pOutputInHouseBeds, 
									pExternalSystemCode, pLanguageCode)
	// Initialize parameters default values							 
	pOutputRoomsVacant = ?(pOutputRoomsVacant = Undefined, True, pOutputRoomsVacant);
	pOutputBedsVacant = ?(pOutputBedsVacant = Undefined, False, pOutputRoomsVacant);
	pOutputRoomsRemains = ?(pOutputRoomsRemains = Undefined, False, pOutputRoomsRemains);
	pOutputBedsRemains = ?(pOutputBedsRemains = Undefined, False, pOutputBedsRemains);
	pOutputRoomsInQuota = ?(pOutputRoomsInQuota = Undefined, False, pOutputRoomsInQuota);
	pOutputBedsInQuota = ?(pOutputBedsInQuota = Undefined, False, pOutputBedsInQuota);
	pOutputRoomsChargedInQuota = ?(pOutputRoomsChargedInQuota = Undefined, False, pOutputRoomsChargedInQuota);
	pOutputBedsChargedInQuota = ?(pOutputBedsChargedInQuota = Undefined, False, pOutputBedsChargedInQuota);
	pOutputRoomsReserved = ?(pOutputRoomsReserved = Undefined, False, pOutputRoomsReserved);
	pOutputBedsReserved = ?(pOutputBedsReserved = Undefined, False, pOutputBedsReserved);
	pOutputInHouseRooms = ?(pOutputInHouseRooms = Undefined, False, pOutputInHouseRooms);
	pOutputInHouseBeds = ?(pOutputInHouseBeds = Undefined, False, pOutputInHouseBeds);
	// Call API							 
	Return cmGetRoomInventoryBalance(pHotel, pRoomType, pCustomer, pContract, pAgent, pRoomQuota, 
										pPeriodFrom, pPeriodTo, pRoomRate, pClientType, 
										pOutputRoomsVacant, pOutputBedsVacant, pOutputRoomsRemains, pOutputBedsRemains, 
										pOutputRoomsInQuota, pOutputBedsInQuota, pOutputRoomsChargedInQuota, pOutputBedsChargedInQuota, 
										pOutputRoomsReserved, pOutputBedsReserved, pOutputInHouseRooms, pOutputInHouseBeds, 
										pExternalSystemCode, pLanguageCode, "XDTO");
EndFunction // GetRoomInventoryBalance

// -----------------------------------------------------------------------------
Function GetVacantCheckInPeriods(pHotel, pRoomRate, pRoomType, pCustomer, pContract, pAgent, pRoomQuota,  
									pPeriodFrom, pPeriodTo, 
									pExternalSystemCode, pLanguageCode)
	// Call API							 
	Return cmGetVacantCheckInPeriods(pHotel, pRoomRate, pRoomType, pCustomer, pContract, pAgent, pRoomQuota,  
										pPeriodFrom, pPeriodTo, 
										pExternalSystemCode, pLanguageCode, "XDTO");
EndFunction // GetVacantCheckInPeriods

// -----------------------------------------------------------------------------
Function RequestCode(pPhone, pExternalSystemCode, pHotel, pLanguageCode)
	Return cmRequestCode(pPhone, pExternalSystemCode, pHotel, pLanguageCode);	
EndFunction // RequestCode

// -----------------------------------------------------------------------------
Function SendExpressCheckInMessage(pHotelCode, pGroupCode, pExpressCheckInPath, pQRCodePath, pQRCodeFileName, pIsExpress, pExtHotelID)
	WriteLogEvent(NStr("en='Send Express Check-In Messages'; de='Send Express Check-In Messages'; ru='Отправка сообщений модуля Експресс Заезда'"), EventLogLevel.Information, , , "ERROR!");
	Return cmSendExpressCheckInMessage(pHotelCode, pGroupCode, pExpressCheckInPath, pQRCodePath, pQRCodeFileName, pIsExpress, pExtHotelID);
EndFunction // SendExpressCheckInMessage

// -----------------------------------------------------------------------------
Function SendInvoice(pLogin, pHotel, pGuestGroup, pCustomerInfo = Undefined, pExternalSystemCode, pLanguageCode, pReservationStatusCode, pIsChangeStatus = False)
	vInputParameters = NStr("en='Login: ';ru='Логин: ';de='Login: '") + pLogin + Chars.LF + 
						NStr("en='Hotel code: ';ru='Код гостиницы: ';de='Code Hotel: '") + pHotel + Chars.LF + 
						NStr("en='Guest group code: ';ru='Номер группы гостей: ';de='Nummer der Gästegruppe: '") + pGuestGroup + Chars.LF + 
						NStr("en='External system code: ';ru='Код внешней системы: ';de='Code des externen Systems: '") + pExternalSystemCode + Chars.LF + 
						NStr("en='Reservation status code: ';ru='Код статуса брони: ';de='Reservierung Status-Code: '") + pReservationStatusCode + Chars.LF + 
						NStr("en='Change status: ';ru='Изменить статус: ';de='Statusänderung: '") + pIsChangeStatus + Chars.LF + 
						NStr("en='Language code: ';ru='Код языка: ';de='Sprachencode: '") + pLanguageCode; 
	If pCustomerInfo <> Undefined Then
		vInputParameters = vInputParameters  + Chars.LF + cmGetXMLStringFromXDTO(pCustomerInfo);
	EndIf;  
	// Get language
	vLanguage = cmGetLanguageByCode(pLanguageCode);
	// Try to find hotel by name or code
	vHotel = cmGetHotelByCode(pHotel, pExternalSystemCode);
	// Get reservation status by code
	vReservationStatus = Catalogs.ReservationStatuses.EmptyRef();
	If Not IsBlankString(pReservationStatusCode) Then
		vReservationStatus = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "ReservationStatuses", pReservationStatusCode);
	EndIf;
	If Not ValueIsFilled(vReservationStatus) And ValueIsFilled(vHotel) Then
		vReservationStatus = vHotel.NewReservationStatus;
	EndIf;      
	vWriteDebug = False;
	vInteraction = Undefined;
	If Not IsBlankString(pExternalSystemCode) Then
		vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(pExternalSystemCode, vHotel);
		If ValueIsFilled(vInteraction) Then
			vWriteDebug = vInteraction.DebugMode;
		EndIf;	
	EndIf; 
	vFuncLog = NStr("en='Send invoice (external)';ru='Отправить счет (внешний)';de='Senden Rechnung (extern)'");
	If vWriteDebug Then
		vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, vInputParameters, , vMsg); 
	Else 
		WriteLogEvent(vFuncLog, EventLogLevel.Information, , , vInputParameters);
	EndIf;  
	// Get guest group by code
	vGuestGroup = cmGetGuestGroupByExternalCode(vHotel, pGuestGroup, "", "", False);
	vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "SendInvoiceResponse"));
	If Not ValueIsFilled(vGuestGroup) Then
		vError = cmNStr("en='Guest group was not found!';ru='Группа не найдена!';de='Gruppe nicht gefunden!'", vLanguage);
		vRetXDTO.Base64 = "";
		vRetXDTO.ErrorDescription = vError;  
		If ValueIsFilled(vInteraction) Then    
			vExtraXML = cmGetXMLStringFromXDTO(vRetXDTO);
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Error, , vExtraXML, vError);	 
		Else
			WriteLogEvent(vFuncLog, EventLogLevel.Error, , , vError);
		EndIf;	
		Return vRetXDTO;
	EndIf;
	vGGObj = vGuestGroup.GetObject();
	vReservations = vGGObj.pmGetReservations(True, True);
	vCustomer = Catalogs.Customers.EmptyRef();  
	If ValueIsFilled(vInteraction) And ValueIsFilled(pLogin) Then
		vRes = InformationRegisters.ExternalSystemIntegrationData.GetData(vInteraction, "Agent", , , , TrimAll(pLogin));
		If vRes.Count() > 0 Then
			vContract = vRes[0].RefKey1; 
			vCustomer = vContract.Owner;  
			vMsg = NStr("ru='Контрагент найден по логину: '; en='Customer found by login: '; de='Customer found  by login: '") + String(vCustomer);
			If vWriteDebug Then
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, , , vMsg);	
			Else	
				WriteLogEvent(vFuncLog, EventLogLevel.Information, , vCustomer,	vMsg);  
			EndIf; 
		Else
			vMsg = NStr("ru='Контрагент найден по логину: '; en='Customer found by login: '; de='Customer found  by login: '") + TrimAll(pLogin);
			If vWriteDebug Then
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Warning, , , vMsg);	
			Else	
				WriteLogEvent(vFuncLog, EventLogLevel.Warning, , vCustomer,	vMsg);  
			EndIf; 
		EndIf;
	EndIf;
	If pCustomerInfo <> Undefined Or ValueIsFilled(vCustomer) Then
		If ValueIsFilled(pCustomerInfo.CustomerName) And ((ValueIsFilled(pCustomerInfo.CustomerTIN) And ValueIsFilled(pCustomerInfo.CustomerKPP)) OR pCustomerInfo.IsIndividual = True) Or ValueIsFilled(vCustomer) Then
			If Not ValueIsFilled(vCustomer) Then
				If pCustomerInfo.IsIndividual <> True Then
					vCustomer = cmGetCustomerByTIN(TrimAll(pCustomerInfo.CustomerTIN), TrimAll(pCustomerInfo.CustomerKPP), "", False);
				Else
					vPhone = "";
					If ValueIsFilled(pCustomerInfo.CustomerPhone) Then
						vPhone = pCustomerInfo.CustomerPhone;
					EndIf;
					vCustomer = GetCustomerByNamePhone(pCustomerInfo.CustomerName, vPhone, False, True);
				EndIf;     
				vMsg = NStr("ru='Контрагент найден: '; en='Customer found: '; de='Customer found: '") + String(vCustomer);
				If vWriteDebug Then
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, , , vMsg);	
				Else	
					WriteLogEvent(vFuncLog, EventLogLevel.Information, , vCustomer,	vMsg);  
				EndIf;
			EndIf;
			If Not ValueIsFilled(vCustomer) Then
				Try
					// Create new customer
					vCustomerObj = Catalogs.Customers.CreateItem();
					If pCustomerInfo.IsIndividual Then
						vIndividualsFolder = Constants.IndividualsFolder.Get();
						If Not ValueIsFilled(vIndividualsFolder) Then
							vIndividualsFolder = Catalogs.Customers.IndividualsFolder;
						EndIf;
						vCustomerObj.Parent = vIndividualsFolder;
					EndIf;
					vCustomerObj.Description = TrimAll(pCustomerInfo.CustomerName);
					vCustomerObj.LegacyName = TrimAll(vCustomerObj.Description);
					vCustomerObj.TIN = TrimAll(pCustomerInfo.CustomerTIN);
					vCustomerObj.KPP = TrimAll(pCustomerInfo.CustomerKPP);
					vCustomerObj.EMail = TrimAll(pCustomerInfo.CustomerEMail);
					vCustomerObj.Fax = TrimAll(pCustomerInfo.CustomerFax);
					vCustomerObj.Phone = SMS.GetValidPhoneNumber(TrimAll(pCustomerInfo.CustomerPhone));
					vCustomerObj.LegacyAddress = TrimAll(pCustomerInfo.CustomerAddress);
					vCustomerObj.pmFillAttributesWithDefaultValues(vHotel);
					If ValueIsFilled(vHotel) And ValueIsFilled(vHotel.PaymentMethodForCustomerPayments) Then
						vCustomerObj.PlannedPaymentMethod = vHotel.PaymentMethodForCustomerPayments;
					EndIf;
					vCustomerObj.Write();
					// Save data to the customer change history
					vCustomerObj.pmWriteToCustomerChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
					// Fill reference
					vCustomer = vCustomerObj.Ref;
				Except
					vError = ErrorDescription();
					vRetXDTO.Base64 = "";
					vRetXDTO.ErrorDescription = vError; 
					If ValueIsFilled(vInteraction) Then    
						vExtraXML = cmGetXMLStringFromXDTO(vRetXDTO);
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Error, , vExtraXML, vError);	
					Else
						WriteLogEvent(vFuncLog, EventLogLevel.Error, , , vError);
					EndIf;
					Return vRetXDTO;
				EndTry;
				vMsg = NStr("ru='Контрагент создан: '; en='Customer created: '; de='Customer created: '") + String(vCustomer);
				If vWriteDebug Then
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, , , vMsg);	
				Else	
					WriteLogEvent(vFuncLog, EventLogLevel.Information, , vCustomer,	vMsg);  
				EndIf;
			Else
				If pCustomerInfo <> Undefined And TrimAll(vCustomer.Email) <> TrimAll(pCustomerInfo.CustomerEMail) And ValueIsFilled(pCustomerInfo.CustomerEMail) Then
					Try 
						// Update customer E-Mail
						vCustomerObj = vCustomer.GetObject();
						vCustomerObj.Email = TrimAll(vCustomer.Email);
						vCustomerObj.Write();
						// Save data to the customer change history
						vCustomerObj.pmWriteToCustomerChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
						// Fill reference
						vCustomer = vCustomerObj.Ref;
					Except
						vError = ErrorDescription();
						vRetXDTO.Base64 = "";
						vRetXDTO.ErrorDescription = vError; 
						If ValueIsFilled(vInteraction) Then    
							vExtraXML = cmGetXMLStringFromXDTO(vRetXDTO);
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Error, , vExtraXML, vError);	
						Else
							WriteLogEvent(vFuncLog, EventLogLevel.Error, , , vError);
						EndIf;
						Return vRetXDTO;
					EndTry;
				EndIf;
			EndIf;
			If ValueIsFilled(vCustomer) Then
				// Set customer to group
				vGGObj.Customer = vCustomer;
				vGGObj.Write();
				
				// Set customer to all reservations in group
				For Each vReservationRow in vReservations Do
					vReservObj = vReservationRow.Reservation.GetObject();
					vReservObj.Customer = vCustomer;
					// Planned payment method
					If Not ValueIsFilled(vReservObj.ParentDoc) Then
						If ValueIsFilled(vReservObj.Customer.PlannedPaymentMethod) Then
							vReservObj.PlannedPaymentMethod = vReservObj.Customer.PlannedPaymentMethod;
						EndIf;
					EndIf;
					vReservObj.pmLoadChargingRules(?(ValueIsFilled(vReservObj.Contract), vReservObj.Contract, vReservObj.Customer));
					vReservObj.pmCalculateServices();
					vReservObj.Write(DocumentWriteMode.Posting);
					vReservObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				EndDo;
			EndIf;
		Else
			vError = cmNStr("en='Do not pass the required parameters: Customer name, TIN, KKP and E-mail!';ru='Не переданы обязательные параметры: Наименование организации, ИНН, КПП и электронная почта!';de='Verpassen Sie nicht die erforderlichen Parameter: Kundenname, TIN, KKP und E-Mail!'", vLanguage);
			vRetXDTO.Base64 = "";
			vRetXDTO.ErrorDescription = vError;  
			If ValueIsFilled(vInteraction) Then    
				vExtraXML = cmGetXMLStringFromXDTO(vRetXDTO);
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Error, , vExtraXML, vError);	
			Else
				WriteLogEvent(vFuncLog, EventLogLevel.Error, , , vError);
			EndIf;
			Return vRetXDTO;
		EndIf;
	EndIf;
	If Not ValueIsFilled(vCustomer) And ValueIsFilled(vGuestGroup) And ValueIsFilled(vGuestGroup.Customer) Then
		vCustomer = vGuestGroup.Customer;
	EndIf;
	If Not ValueIsFilled(vCustomer) Then
		vError = cmNStr("en='The customer can not be found (not tied to a guests group)!';ru='Контрагент не найден (Не привязан к группе гостей)!';de='Der Kunde kann nicht gefunden werden (nicht auf ein Gäste Gruppe gebunden)!'", vLanguage);
		vRetXDTO.Base64 = "";
		vRetXDTO.ErrorDescription = vError; 
		If ValueIsFilled(vInteraction) Then    
			vExtraXML = cmGetXMLStringFromXDTO(vRetXDTO);
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Error, , vExtraXML, vError);	
		Else
			WriteLogEvent(vFuncLog, EventLogLevel.Error, , , vError);
		EndIf;
		Return vRetXDTO;
	EndIf;
	// Send invoice by E-Mail
	vBase64Text = "";
	If ValueIsFilled(vGuestGroup.ClientDoc) Then
		vClientDocObj = vGuestGroup.ClientDoc.GetObject();
		If TypeOf(vClientDocObj) = Type("DocumentObject.Reservation") Then
			If ValueIsFilled(vGuestGroup.ClientDoc.Customer) And ValueIsFilled(vGuestGroup.ClientDoc.PlannedPaymentMethod) And vGuestGroup.ClientDoc.PlannedPaymentMethod.IsByBankTransfer Then		
				vBase64Text = cmWriteReservationInvoiceGuestGroupAttachment(vClientDocObj);   
				vMsg = NStr("ru='Отправка сообщения'; en='Sending message'; de='Sending message'");
				If vWriteDebug Then    
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, , , vMsg);	
				Else
					WriteLogEvent(vFuncLog, EventLogLevel.Information, , , vMsg);
				EndIf;
				If ValueIsFilled(vBase64Text) Then
					// Set status to all reservations in group
					If pIsChangeStatus And ValueIsFilled(vReservationStatus) Then
						For each vReservationRow in vReservations Do
							If vReservationRow.Reservation.ReservationStatus <> vReservationStatus Then
								vReservObj = vReservationRow.Reservation.GetObject();
								vReservObj.ReservationStatus = vReservationStatus;
								If Not ValueIsFilled(vReservObj.GuaranteeType) And vReservObj.ReservationStatus.IsGuaranteed And ValueIsFilled(vReservObj.ReservationStatus.GuaranteeType) Then
									vReservObj.GuaranteeType = vReservObj.ReservationStatus.GuaranteeType;
								EndIf;
								vReservObj.pmSetDoCharging();
								vReservObj.Write(DocumentWriteMode.Posting);
								vReservObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
							EndIf;
						EndDo;
					EndIf;
				EndIf;
			Else
				vError = cmNStr("en='Customer's E-mail not filled!';ru='У контрагента не заполнен E-mail!';de='Kunden-E-Mail ist nicht gefüllt!'", vLanguage);
				vRetXDTO.Base64 = "";
				vRetXDTO.ErrorDescription = vError;  
				If ValueIsFilled(vInteraction) Then    
					vExtraXML = cmGetXMLStringFromXDTO(vRetXDTO);
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Error, , vExtraXML, vError);	
				Else
					WriteLogEvent(vFuncLog, EventLogLevel.Error, , , vError);
				EndIf;
				Return vRetXDTO;
			EndIf;
		Else
			vError = cmNStr("en='Client document is not reservation!';ru='Документ клиента не бронь!';de='Client Dokument ist keine Reservierung!'", vLanguage);
			vRetXDTO.Base64 = "";
			vRetXDTO.ErrorDescription = vError; 
			If ValueIsFilled(vInteraction) Then    
				vExtraXML = cmGetXMLStringFromXDTO(vRetXDTO);
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Error, , vExtraXML, vError);	
			Else
				WriteLogEvent(vFuncLog, EventLogLevel.Error, , , vError);
			EndIf;
			Return vRetXDTO;
		EndIf;
	Else
		vError = cmNStr("en='Client document is not filled in the guests group!';ru='Документ клиента не заполнен у группы гостей!';de='Client-Dokument ist nicht im Gäste Gruppe gefüllt!'", vLanguage);
		vRetXDTO.Base64 = "";
		vRetXDTO.ErrorDescription = vError; 
		If ValueIsFilled(vInteraction) Then    
			vExtraXML = cmGetXMLStringFromXDTO(vRetXDTO);
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Error, , vExtraXML, vError);	
		Else
			WriteLogEvent(vFuncLog, EventLogLevel.Error, , , vError);
		EndIf;
		Return vRetXDTO;
	EndIf;        
	vMsg = NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'");
	vRetXDTO.Base64 = vBase64Text;
	vRetXDTO.ErrorDescription = "";   
	If vWriteDebug Then    
		vExtraXML = cmGetXMLStringFromXDTO(vRetXDTO);
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, , vExtraXML, vMsg);	
	Else
		WriteLogEvent(vFuncLog, EventLogLevel.Information, , , vMsg);
	EndIf;
	Return vRetXDTO;
EndFunction // SendInvoice

// -----------------------------------------------------------------------------
Function UpdateClientInfo(pClientInfo, pHotelCode, pGroupCode, pExternalSystemCode, pLanguageCode, pQRCodePath, pQRCodeFileName)
	Return cmUpdateClientInfo(pClientInfo, pHotelCode, pGroupCode, pExternalSystemCode, pLanguageCode, pQRCodePath, pQRCodeFileName);
EndFunction // UpdateClientInfo

// -----------------------------------------------------------------------------
Function VerifyClient(pPhone, pCode, pExternalSystemCode, pHotel, pLanguageCode)
	Return cmVerifyClient(pPhone, pCode, pExternalSystemCode, pHotel, pLanguageCode);
EndFunction // VerifyClient

// -----------------------------------------------------------------------------
Function WriteExternalClient(pClientCode, pReservationCode, 
								pClientLastName, pClientFirstName, pClientSecondName, 
								pClientSex, pClientCitizenship, pClientBirthDate, 
								pClientPhone, pClientFax, pClientEMail, pClientRemarks, pClientSendSMS, 
								pHotel, pExternalSystemCode)
	Return cmWriteExternalClient(pClientCode, pReservationCode, 
									pClientLastName, pClientFirstName, pClientSecondName, 
									pClientSex, pClientCitizenship, pClientBirthDate, 
									pClientPhone, pClientFax, pClientEMail, 
									pClientRemarks, pClientSendSMS, pHotel, pExternalSystemCode, Catalogs.Clients.ReservedGuests.Code, , , , , , , , , , , , "XDTO");
EndFunction // WriteExternalClient

// -----------------------------------------------------------------------------
Function WriteExternalClientExt(pClientCode, pReservationCode, 
								pClientLastName, pClientFirstName, pClientSecondName, 
								pClientSex, pClientCitizenship, pClientBirthDate, 
								pClientPhone, pClientFax, pClientEMail, pClientRemarks, pClientSendSMS, 
								pClientIdentityDocumentTypeCode, pClientIdentityDocumentSeries, pClientIdentityDocumentNumber, 
								pClientIdentityDocumentIssueDate, pClientIdentityDocumentValidToDate, 
								pClientIdentityDocumentUnitCode, pClientIdentityDocumentIssuedBy, pClientPlaceOfBirth, pClientAddress, 
								pClientExtraData, 
								pHotel, pExternalSystemCode)
	Return cmWriteExternalClient(pClientCode, pReservationCode, 
									pClientLastName, pClientFirstName, pClientSecondName, 
									pClientSex, pClientCitizenship, pClientBirthDate, 
									pClientPhone, pClientFax, pClientEMail, 
									pClientRemarks, pClientSendSMS, pHotel, pExternalSystemCode, Catalogs.Clients.ReservedGuests.Code,  
									pClientIdentityDocumentTypeCode, pClientIdentityDocumentSeries, pClientIdentityDocumentNumber, 
									pClientIdentityDocumentIssueDate, pClientIdentityDocumentValidToDate, pClientIdentityDocumentUnitCode, pClientIdentityDocumentIssuedBy, 
									pClientPlaceOfBirth, pClientAddress, pClientExtraData, Undefined, "XDTO");
EndFunction // WriteExternalClient

// -----------------------------------------------------------------------------
Function WriteExternalGroupReservation(pWriteExternalGroupReservation, pLanguageCode)
	Return cmWriteExternalGroupReservation(pWriteExternalGroupReservation, pLanguageCode);
EndFunction // WriteExternalGroupReservation

// -----------------------------------------------------------------------------
Function WriteExternalReservation(pReservationCode, pGroupCode, pGroupDescription, 
	pGroupCustomer, pGroupClient, pReservationStatus, pPeriodFrom, pPeriodTo, 
	pHotel, pRoomType, pAccommodationType, pClientType, pRoomQuota, 
	pRoomRate, pCustomer, pContract, pAgent, pContactPerson, 
	pNumberOfRooms, pNumberOfPersons, pClientCode, 
	pClientLastName, pClientFirstName, pClientSecondName, 
	pClientSex, pClientCitizenship, pClientBirthDate, 
	pClientPhone, pClientFax, pClientEMail, 
	pClientRemarks, pClientSendSMS, pReservationRemarks, pCar, 
	pPlannedPaymentMethod, pExternalSystemCode, pDoPosting, pPromoCode, pLanguageCode, Login)
	Return cmWriteExternalReservation(pReservationCode, pGroupCode, pGroupDescription, 
	pGroupCustomer, pReservationStatus, pPeriodFrom, pPeriodTo, 
	pHotel, pRoomType, pAccommodationType, pClientType, pRoomQuota, 
	pRoomRate, pCustomer, pContract, pAgent, pContactPerson, 
	pNumberOfRooms, pNumberOfPersons, pClientCode, 
	pClientLastName, pClientFirstName, pClientSecondName, 
	pClientSex, pClientCitizenship, pClientBirthDate, 
	pClientPhone, pClientFax, pClientEMail, 
	pClientRemarks, pClientSendSMS, pReservationRemarks, pCar, 
	pPlannedPaymentMethod, pExternalSystemCode, pDoPosting, pPromoCode, pLanguageCode, "XDTO");
EndFunction // WriteExternalReservation

// -----------------------------------------------------------------------------
Function WriteGuestGroupPayment(pReservationCode, pGroupCode, pClientCode, pPayerName, pPaymentMethod, pSum, pCurrency, pPaymentSection, pHotel, pExternalSystemCode, pReferenceNumber, pAuthorizationCode, pRemarks)
	Return cmWriteExternalPayment(pReservationCode, pGroupCode, pClientCode, 
									pPayerName, "", "", pPayerName, 
									pPaymentMethod, pSum, pCurrency, pPaymentSection, pHotel, pExternalSystemCode, 
									pReferenceNumber, pAuthorizationCode, pRemarks, "", 
									CurrentSessionDate(), "", "", "XDTO");
EndFunction // WriteGuestGroupPayment

// -----------------------------------------------------------------------------
Function WriteGuestGroupPaymentExt(pReservationCode, pGroupCode, pClientCode, pPayerName, pPaymentMethod, pSum, pCurrency, pPaymentSection, pHotel, pExternalSystemCode, pReferenceNumber, pAuthorizationCode, pRemarks, pExternalPaymentData)
	Return cmWriteExternalPayment(pReservationCode, pGroupCode, pClientCode, 
									pPayerName, "", "", pPayerName, 
									pPaymentMethod, pSum, pCurrency, pPaymentSection, pHotel, pExternalSystemCode, 
									pReferenceNumber, pAuthorizationCode, pRemarks, "", 
									, "", "", "XDTO", pExternalPaymentData);
EndFunction // WriteGuestGroupPaymentExt

// -----------------------------------------------------------------------------
Function WriteGuestGroupPreauthorisation(pReservationCode, pGroupCode, pClientCode, pPayerName, pPaymentMethod, pSum, pCurrency, pHotel, pExternalSystemCode, pReferenceNumber, pAuthorizationCode, pRemarks, pExternalPaymentData)
	Return cmWriteExternalPreauthorisation(pReservationCode, pGroupCode, pClientCode, 
	pPayerName, "", "", pPayerName, 
	pPaymentMethod, pSum, pCurrency, pHotel, pExternalSystemCode, 
	pReferenceNumber, pAuthorizationCode, pRemarks, "", 
	CurrentSessionDate(), "", "", "XDTO", pExternalPaymentData);
EndFunction // WriteGuestGroupPreauthorisation

// -----------------------------------------------------------------------------
Function WriteNewGroup(pNewGroup, pExternalSystemCode)
	// Check if external system is active
	vExtSystem = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(pExternalSystemCode);
	If ValueIsFilled(vExtSystem) AND vExtSystem.DebugMode Then
		// Save request parameters to the log register
		vExtraXML = "";
		vXMLWriter = New XMLWriter; 
		vXMLWriter.SetString();
		XDTOFactory.WriteXML(vXMLWriter, pNewGroup);
		vExtraXML = vXMLWriter.Close();
		vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vExtSystem, "WriteNewGroup", Enums.ExternalSystemEventTypes.Info, vExtraXML, , vMsg, vExtSystem.MaxLogLenght);
	EndIf;
	
	// Create return object
	vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "NewGroupStatus"));
	
	If ValueIsFilled(vExtSystem) AND vExtSystem.IsActive Then
		// Retrieve parameter references based on codes
		vHotel = cmGetHotelByCode(pNewGroup.HotelCode, pExternalSystemCode);
		
		If Not ValueIsFilled(vHotel) Then
			vRetXDTO.ErrorDescription = "Hotel not defined!";
			Return vRetXDTO;
		EndIf;
		
		vGroupType = cmGetObjectRefByExternalSystemCode(vHotel,pExternalSystemCode,"GroupTypes",pNewGroup.Type);
		If ValueIsFilled(vGroupType) AND vGroupType = Catalogs.GroupTypes.Rooms OR vGroupType = Catalogs.GroupTypes.RoomsAndResources Then
			
			vGuestGroup = GetGroupByID(pNewGroup.id, vExtSystem);
			
			If Not ValueIsFilled(vGuestGroup) Then
				// Create group
				vGuestGroup = Catalogs.GuestGroups.CreateItem();
				vGuestGroup.Owner = vHotel;
				vGuestGroup.Description = pNewGroup.GroupDescription;
				vGuestGroup.GroupType = vGroupType;
				vGuestGroup.CheckInDate  = ?(ValueIsFilled(pNewGroup.CheckInDate), cm1SecondShift(pNewGroup.CheckInDate), pNewGroup.CheckInDate);
				vGuestGroup.CheckOutDate = ?(ValueIsFilled(pNewGroup.CheckOutDate), cm0SecondShift(pNewGroup.CheckOutDate), pNewGroup.CheckOutDate);
				vGuestGroup.Duration = Round((BegOfDay(vGuestGroup.CheckOutDate) - BegOfDay(vGuestGroup.CheckInDate)) / (24 * 3600), 0);
				If BegOfDay(vGuestGroup.CheckOutDate) > BegOfDay(vGuestGroup.CheckInDate) Then
					vGuestGroup.Duration = Round((BegOfDay(vGuestGroup.CheckOutDate) - BegOfDay(vGuestGroup.CheckInDate)) / (24 * 3600), 0);
				EndIf;
				
				vUserProp = pNewGroup.Properties().Get("UserID");
				If vUserProp <> Undefined Then
					vGuestGroup.Author = GetAuthor(pNewGroup.UserID, vHotel, pExternalSystemCode);
				EndIf;
				vGuestGroup.Remarks = pNewGroup.Remarks;
				
				vGuestGroupFolder = vHotel.GetObject().pmGetGuestGroupFolder();
				If ValueIsFilled(vGuestGroupFolder) Then
					vGuestGroup.Parent = vGuestGroupFolder;
					vGuestGroup.SetNewCode();
				EndIf;
				vGuestGroup.OneCustomerPerGuestGroup = vHotel.OneCustomerPerGuestGroup;
				
				vGuestGroup.Write();
				
				SaveGroupExtID(vGuestGroup.Ref, pNewGroup.id, vExtSystem);
			EndIf;
			// The group is alredy exists
			vRetXDTO.ErrorDescription = "";
			vRetXDTO.GuestGroup = Format(vGuestGroup.Code,"ND=12; NFD=0; NG=");
			vRetXDTO.URL = GetExtURL(vGuestGroup.Ref, vExtSystem);
			
			Return vRetXDTO;
		ElsIf ValueIsFilled(vGroupType) And vGroupType = Catalogs.GroupTypes.Resources Then
			// Make resource reservation
			vGuestGroup = GetGroupByID(pNewGroup.id, vExtSystem);
			
			If ValueIsFilled(vGuestGroup) Then
				vRetXDTO.ErrorDescription = "";
				vRetXDTO.GuestGroup = Format(vGuestGroup.Code,"ND=12; NFD=0; NG=");
				If ValueIsFilled(vGuestGroup.ClientDoc) Then
					vRetXDTO.URL = GetExtURL(vGuestGroup.ClientDoc.Ref, vExtSystem);
				Else
					vRetXDTO.URL = GetExtURL(vGuestGroup.Ref, vExtSystem);
				EndIf;
				
				Return vRetXDTO;
			EndIf;
			
			vResObj = Documents.ResourceReservation.CreateDocument();
			vResObj.Hotel = vHotel;
			vResObj.pmFillAttributesWithDefaultValues();
			
			vUserProp = pNewGroup.Properties().Get("UserID");
			If vUserProp <> Undefined Then
				vResObj.Author = GetAuthor(pNewGroup.UserID, vHotel, pExternalSystemCode);
			EndIf;
			
			vResObj.DateTimeFrom  = pNewGroup.CheckInDate;
			vResObj.DateTimeTo    = pNewGroup.CheckOutDate;
			vResObj.Remarks = pNewGroup.Remarks;
			vResObj.Write(DocumentWriteMode.Write);
			
			If ValueIsFilled(vResObj.GuestGroup) Then
				vGuestGroupObj = vResObj.GuestGroup.GetObject();
				vGuestGroupObj.ClientDoc = vResObj.Ref;
				vGuestGroupObj.Write();
			EndIf;
			
			vRetXDTO.URL = GetExtURL(vResObj.Ref, vExtSystem);
			
			SaveGroupExtID(vResObj.GuestGroup, pNewGroup.id, vExtSystem);
			
			Return vRetXDTO;
		Else
			// Individual reservation
			vGuestGroup = GetGroupByID(pNewGroup.id, vExtSystem);
			
			If ValueIsFilled(vGuestGroup) Then
				vRetXDTO.ErrorDescription = "";
				vRetXDTO.GuestGroup = Format(vGuestGroup.Code,"ND=12; NFD=0; NG=");
				If ValueIsFilled(vGuestGroup.ClientDoc) Then
					vRetXDTO.URL = GetExtURL(vGuestGroup.ClientDoc.Ref, vExtSystem);
				Else
					vRetXDTO.URL = GetExtURL(vGuestGroup.Ref, vExtSystem);
				EndIf;
				
				Return vRetXDTO;
			EndIf;
			
			vResObj = Documents.Reservation.CreateDocument();
			vResObj.Hotel = vHotel;
			vResObj.pmFillAttributesWithDefaultValues();
			vUserProp = pNewGroup.Properties().Get("UserID");
			If vUserProp <> Undefined Then
				vResObj.Author = GetAuthor(pNewGroup.UserID, vHotel, pExternalSystemCode);
			EndIf;
			vResObj.CheckInDate = cm1SecondShift(BegOfDay(pNewGroup.CheckInDate)+(vResObj.CheckInDate-BegOfDay(vResObj.CheckInDate)));
			vResObj.CheckOutDate = cm0SecondShift(BegOfDay(pNewGroup.CheckOutDate)+(vResObj.CheckOutDate-BegOfDay(vResObj.CheckOutDate)));
			vResObj.Duration = vResObj.pmCalculateDuration();
			vResObj.Remarks = pNewGroup.Remarks;
			vResObj.Write(DocumentWriteMode.Write);
			
			If ValueIsFilled(vResObj.GuestGroup) Then
				vGuestGroupObj = vResObj.GuestGroup.GetObject();
				vGuestGroupObj.ClientDoc = vResObj.Ref;
				vGuestGroupObj.Write();
			EndIf;
			
			vRetXDTO.URL = GetExtURL(vResObj.Ref, vExtSystem);
			
			SaveGroupExtID(vResObj.GuestGroup, pNewGroup.id, vExtSystem);
			
			Return vRetXDTO;
		EndIf;
	Else
		vRetXDTO.ErrorDescription = "Not authorized";
	EndIf;
	
	Return vRetXDTO;
EndFunction // WriteNewGroup

// --------------------------------------------------------------------------------
Function GetClientDiscountCards(pClientCode, pExternalSystemCode)
	vCardRef = Catalogs.IdentificationCards.EmptyRef();
	vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "DiscountCardList"));
	
	vExtSystem = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(pExternalSystemCode);     
	vExtraXML = "Client code: " + pClientCode + Chars.LF + "External system: " + pExternalSystemCode;
	vWriteDebug = False; 
	vHotel = Undefined;
	vFunc = "GetClientDiscountCards";
	vTitle = NStr("en = 'Start of processing'; de = 'Anfang der Ausführung'; ru = 'Начало выполнения'");
	If ValueIsFilled(vExtSystem) Then   
		vHotel = vExtSystem.Hotel;
		vWriteDebug = vExtSystem.DebugMode;
		If vWriteDebug Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vExtSystem, vFunc, Enums.ExternalSystemEventTypes.Info, vExtraXML, , vTitle);	
		Else
			WriteLogEvent(vFunc, EventLogLevel.Information, , , vExtraXML);
		EndIf;	
	Else
		WriteLogEvent(vFunc, EventLogLevel.Information, , , vExtraXML);	
	EndIf;
	// Check external system
	If Not ValueIsFilled(vExtSystem) Or IsBlankString(pExternalSystemCode) Then
		vMsg =  NStr("en = 'Failed to determine interaction from external code: %1'; 
					 |de = 'Interaktion von externem Code konnte nicht bestimmt werden: %1'; 
					 |ru = 'Не удалось определить взаимодействие по внешнему коду: %1'");	
		vRetXDTO.ErrorDescription = StrTemplate(vMsg, pExternalSystemCode);     
		WriteLogEvent(vFunc, EventLogLevel.Error, , , cmGetXMLStringFromXDTO(vRetXDTO));
		Return vRetXDTO; 
	EndIf;
	vQry =  New Query();
	vQry.Text = "SELECT
	            |	DiscountCards.Ref AS Ref,
	            |	DiscountCards.DiscountType AS DiscountType,
	            |	DiscountCards.Identifier AS Identifier,
	            |	DiscountCards.ParentDiscountCard AS ParentDiscountCard,
	            |	DiscountCards.ValidFrom AS ValidFrom,
	            |	DiscountCards.ValidTo AS ValidTo,
	            |	DiscountCards.IsBlocked AS IsBlocked
	            |FROM
	            |	Catalog.DiscountCards AS DiscountCards
	            |WHERE
	            |	DiscountCards.Client.Code = &qClientCode
	            |	AND DiscountCards.DeletionMark = FALSE
	            |
	            |ORDER BY
	            |	DiscountCards.CreateDate DESC,
	            |	DiscountCards.Code DESC";
	vQry.SetParameter("qClientCode", TrimAll(pClientCode));
	vRes = vQry.Execute();
	
	vRetRowType = XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "DiscountCardRaw");
	If Not ValueIsFilled(vHotel) Then
		vHotel = SessionParameters.CurrentHotel;	
	EndIf;	
	If vRes.IsEmpty() Then  
		vRetXDTO.ErrorDescription = NStr("en = 'No dicount cards found'; de = 'No dicount cards found'; ru = 'Не найдено скидочных карт'");	
	Else
		vCards = vRes.Select();
		While vCards.Next() Do
			vRow = vCards;
			vRetRow = XDTOFactory.Create(vRetRowType);
			vRetRow.DiscountCardNum = TrimAll(vRow.Identifier);
			
			vDiscountTypeObj = vRow.DiscountType.GetObject();
			vRetRow.DiscountPercent = vDiscountTypeObj.pmGetDiscount(CurrentSessionDate(), , vHotel);
			vRetRow.DiscountType = TrimAll(vRow.DiscountType);
			vRetRow.IsDefaultCard = Not ValueIsFilled(vRow.ParentDiscountCard);     
			vRetRow.ValidFrom = vRow.ValidFrom;
			vRetRow.ValidTo = vRow.ValidTo;
			vRetRow.IsBlocked = vRow.IsBlocked;
			vRetXDTO.DiscountCardRaw.Add(vRetRow);
		EndDo;
	EndIf;
	vTitle =  NStr("en = 'End of processing'; de = 'Ende des Ausführung'; ru = 'Конец выполнения'");
	vExtraXML = cmGetXMLStringFromXDTO(vRetXDTO);
	If vWriteDebug Then
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vExtSystem, vFunc, Enums.ExternalSystemEventTypes.Info, , vExtraXML, vTitle);	
	Else
		WriteLogEvent(vFunc, EventLogLevel.Information, , , vExtraXML);
	EndIf;	
	
	Return vRetXDTO;
EndFunction

// --------------------------------------------------------------------------------
Function GetDiscountCardPercent(pIdentifier, pExternalSystemCode)
	vCardRef = Catalogs.IdentificationCards.EmptyRef();
	vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "DiscountCardsPercentReturn"));
	
	vExtSystem = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(pExternalSystemCode);     
	vExtraXML = "Identifier: " + pIdentifier + Chars.LF + "External system: " + pExternalSystemCode;
	vWriteDebug = False; 
	vHotel = Undefined;
	vFunc = "GetDiscountCardPercent";
	vTitle = NStr("en = 'Start of processing'; de = 'Anfang der Ausführung'; ru = 'Начало выполнения'");
	If ValueIsFilled(vExtSystem) Then  
		vHotel = vExtSystem.Hotel;
		vWriteDebug = vExtSystem.DebugMode;
		If vWriteDebug Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vExtSystem, vFunc, Enums.ExternalSystemEventTypes.Info, vExtraXML, , vTitle);	
		Else
			WriteLogEvent(vFunc, EventLogLevel.Information, , , vExtraXML);
		EndIf;	
	Else
		WriteLogEvent(vFunc, EventLogLevel.Information, , , vExtraXML);	
	EndIf;
	// Check external system
	If Not ValueIsFilled(vExtSystem) Or IsBlankString(pExternalSystemCode) Then
		vMsg =  NStr("en = 'Failed to determine interaction from external code: %1'; 
					 |de = 'Interaktion von externem Code konnte nicht bestimmt werden: %1'; 
					 |ru = 'Не удалось определить взаимодействие по внешнему коду: %1'");	
		vRetXDTO.ErrorDescription = StrTemplate(vMsg, pExternalSystemCode);     
		WriteLogEvent(vFunc, EventLogLevel.Error, , , cmGetXMLStringFromXDTO(vRetXDTO));
		Return vRetXDTO; 
	EndIf;
	If Not ValueIsFilled(vHotel) Then
		vHotel = SessionParameters.CurrentHotel;	
	EndIf;
	vQry =  New Query();
	vQry.Text = 
	"SELECT
	|	DiscountCards.Ref AS Ref
	|FROM
	|	Catalog.DiscountCards AS DiscountCards
	|WHERE
	|	DiscountCards.Identifier = &qIdentifier
	|	AND DiscountCards.DeletionMark = FALSE
	|
	|ORDER BY
	|	DiscountCards.CreateDate DESC,
	|	DiscountCards.Code DESC";
	vQry.SetParameter("qIdentifier", TrimAll(pIdentifier));
	vCards = vQry.Execute();
	
	If Not vCards.IsEmpty() Then
		vCards = vCards.Unload().Get(0).Ref;
		vDiscountTypeObj = vCards.DiscountType.GetObject();
		vRetXDTO.DiscountPercent = vDiscountTypeObj.pmGetDiscount(CurrentSessionDate(), , vHotel);
		vRetXDTO.DiscountType = TrimAll(vCards.DiscountType);
	Else
		vRetXDTO.ErrorDescription = NStr("en = 'No dicount cards found'; de = 'No dicount cards found'; ru = 'Не найдено скидочных карт'");	
	EndIf;
	
	vExtraXML = cmGetXMLStringFromXDTO(vRetXDTO);       
	
	vTitle =  NStr("en = 'End of processing'; de = 'Ende des Ausführung'; ru = 'Конец выполнения'");
	If vWriteDebug Then
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vExtSystem, vFunc, Enums.ExternalSystemEventTypes.Info, , vExtraXML, vTitle);	
	Else
		WriteLogEvent(vFunc, EventLogLevel.Information, , , vExtraXML);
	EndIf;
	
	Return vRetXDTO;		
EndFunction

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetCustomerByNamePhone(pCustomerName, pPhone = "", pCreate = True, pIsIndividualPerson = False, pPaymentMethod = Undefined) 
	WriteLogEvent(NStr("en='Get customer by name';ru='Поиск контрагента по наименованию';de='Suche nach dem Partner nach Bezeichnung'"), EventLogLevel.Information, , , NStr("en='Input parameters: ';ru='Входные параметры: ';de='Eingangsparameter:'") + Chars.LF +
				  NStr("en='Customer name: ';ru='Наименование контрагента: ';de='Bezeichnung des Partners: '") + pCustomerName + Chars.LF + 
				  NStr("en='Phone: ';ru='Телефон: ';de='Phone: '") + pPhone + Chars.LF + 
				  NStr("en='Is individuals person: ';ru='Частное лицо: ';de='Privatperson: '") + pIsIndividualPerson + Chars.LF + 
				  NStr("en='Payment method: ';ru='Способ оплаты: ';de='Zahlungsmethode: '") + pPaymentMethod + Chars.LF + 
				  NStr("en='Do create new if not found: ';ru='Создавать новую карточку если не найден: ';de='Neue Karte generieren falls nicht gefunden: '") + pCreate);
	vCustomer = Catalogs.Customers.EmptyRef();
	// Try to find customer by description or external code
	If Not IsBlankString(pCustomerName) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	Customers.Ref
		|FROM
		|	Catalog.Customers AS Customers
		|WHERE
		|	(Customers.Description = &qCustomerName
		|			OR Customers.LegacyName = &qCustomerName
		|			OR Customers.ExternalCode = &qCustomerName)
		|	AND NOT Customers.DeletionMark
		|	AND NOT Customers.IsFolder
		|	AND (NOT &qIsIndividual
		|			OR &qIsIndividual
		|				AND Customers.IsIndividual
		|				AND (Customers.Phone = &qPhone
		|					OR &qPhoneEmpty))
		|
		|ORDER BY
		|	Customers.Code DESC";
		vQry.SetParameter("qCustomerName", Upper(TrimAll(pCustomerName)));
		vQry.SetParameter("qIsIndividual", pIsIndividualPerson);
		vQry.SetParameter("qPhone", SMS.GetValidPhoneNumber(pPhone));
		vQry.SetParameter("qPhoneEmpty", Not ValueIsFilled(pPhone));
		vCustomers = vQry.Execute().Unload();
		If vCustomers.Count() > 0 Then
			vCustomer = vCustomers.Get(0).Ref;
			WriteLogEvent(NStr("en = 'Get customer by name'; de = 'Suche nach dem Partner nach Bezeichnung'; ru = 'Поиск контрагента по наименованию'"), EventLogLevel.Information, , , NStr("en='Customer is found: ';ru='Найден контрагент: ';de='Partner gefunden: '") + TrimAll(vCustomer.Description) + " (" + TrimAll(vCustomer.Code) + ")");
		ElsIf pCreate Then
			WriteLogEvent(NStr("en = 'Get customer by name'; de = 'Suche nach dem Partner nach Bezeichnung'; ru = 'Поиск контрагента по наименованию'"), EventLogLevel.Information, , , NStr("en='Customer is not found!';ru='Не найден контрагент!';de='Partner nicht gefunden!'"));
			// Create new customer
			vCustomerObj = Catalogs.Customers.CreateItem();
			If pIsIndividualPerson Then
				vIndividualsFolder = Constants.IndividualsFolder.Get();
				If Not ValueIsFilled(vIndividualsFolder) Then
					vIndividualsFolder = Catalogs.Customers.IndividualsFolder;
				EndIf;
				vCustomerObj.Parent = vIndividualsFolder;
			EndIf;
			vCustomerObj.Description = TrimAll(pCustomerName);
			vCustomerObj.pmFillAttributesWithDefaultValues();
			If ValueIsFilled(pPaymentMethod) Then
				vCustomerObj.PlannedPaymentMethod = pPaymentMethod;
				If vCustomerObj.ChargingRules.Count() > 0 Then
					v1CRRow = vCustomerObj.ChargingRules.Get(0);
					v1CRRowFolioObj = v1CRRow.ChargingFolio.GetObject();
					v1CRRowFolioObj.PaymentMethod = pPaymentMethod;
					v1CRRowFolioObj.Write(DocumentWriteMode.Write);
				EndIf;
			EndIf;
			vCustomerObj.Write();
			// Save data to the customer change history
			vCustomerObj.pmWriteToCustomerChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			// Fill reference
			vCustomer = vCustomerObj.Ref;
		EndIf;
	EndIf;
	Return vCustomer;
EndFunction // GetCustomerByNamePhone 

// -----------------------------------------------------------------------------
Function GetExtURL(pRef, pExtSystem)
	dbURL = "";
	If ValueIsFilled(pExtSystem) And ValueIsFilled(pExtSystem.WSHost) Then
		dbURL = TrimAll(pExtSystem.WSHost) + "#";
	EndIf;
	Return dbURL + GetURL(pRef);	
EndFunction // GetExtURL

// -----------------------------------------------------------------------------
Function GetAuthor(pUserID, pHotel, pExternalSystemCode)
	// 1. try to find user with the requerted user id
	vUserIDint = Number(pUserID);
	vUser = Undefined;
	If vUserIDint > 0 Then
		vQ = New Query("SELECT
		|	Employees.Ref AS Ref
		|FROM
		|	Catalog.Employees AS Employees
		|WHERE
		|	Employees.B24EmployeeID = &qB24EmployeeID
		|	AND (Employees.Hotel = &qHotel
		|			OR Employees.Hotel = &qEmptyHotel)
		|	AND NOT Employees.DeletionMark");
		
		vQ.SetParameter("qB24EmployeeID",vUserIDint);
		vQ.SetParameter("qHotel",pHotel);
		vQ.SetParameter("qEmptyHotel",Catalogs.Employees.EmptyRef());
		qRes = vQ.Execute().Select();
		If qRes.Next() Then
			vUser = qRes.Ref;
		EndIf;		
	EndIf;
	
	If ValueIsFilled(vUser) Then
		Return vUser;
	EndIf;
	// 2. try to find mapped user
	vUser = cmGetObjectRefByExternalSystemCode(pHotel, pExternalSystemCode, "Employees", pUserID, False);
	
	// In case user not foud - use current session user
	If Not ValueIsFilled(vUser) Then
		vUser = SessionParameters.CurrentUser;
	EndIf;
	Return vUser;	
EndFunction // GetAuthor

// -----------------------------------------------------------------------------
Function GetGroupByID(pId, pExtSystem)
	
	If ValueIsFilled(pExtSystem) AND pExtSystem.IntegrationType = Enums.Integrations.Bitrix24 Then
		// Bitrix24 deal ID is stored in special mapping register. Retrieve it.
		vTDeals = InformationRegisters.ExternalSystemIntegrationData.GetData(pExtSystem, "deals", "updatePeriod", Undefined, Undefined, Undefined, pID);
		If ValueIsFilled(vTDeals) And vTDeals.Count() > 0 Then
			Return vTDeals[0].RefKey1;
		EndIf;
	EndIf;
	Return Undefined;
EndFunction // GetGroupByID

// -----------------------------------------------------------------------------
Procedure SaveGroupExtID(pGroupRef, pId, pExtSystem)
	// Save deal ID mapping for bitrix24 in order to export data from 1C-Hotel to Bitrix24 and update the deal	
	If ValueIsFilled(pExtSystem) AND pExtSystem.IntegrationType = Enums.Integrations.Bitrix24 Then
		// Bitrix24 deal ID is stored in special mapping register. Retrieve it.
		InformationRegisters.ExternalSystemIntegrationData.WriteData(pExtSystem, "deals", "updatePeriod", pGroupRef, Undefined, CurrentSessionDate(), pID);
	EndIf;
EndProcedure // SaveGroupExtID

Function VerifyPayment(pExternalSystemCode, pHotelCode, pPaymentID)    
	vInputParameters =  NStr("en='External system code: ';ru='Код внешней системы: ';de='Code des externen Systems: '") + pExternalSystemCode + Chars.LF 
						+ NStr("en='Hotel code: ';ru='Код гостиницы: ';de='Code des Hotels: '") + pHotelCode + Chars.LF 
						+ NStr("en='PaymentID: ';ru='PaymentID: ';de='PaymentID: '") + pPaymentID ;								
				  
	vFuncLogName = NStr("en='VerifyРayment';ru='Проверка платежа';de='VerifyРayment'");			  
	// Try to find hotel by name or code
	vHotel = cmGetHotelByCode(pHotelCode, pExternalSystemCode);
	vWriteDebug = False;
	vInteraction = Undefined;
	If Not IsBlankString(pExternalSystemCode) Then
		vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(pExternalSystemCode, vHotel);
		If ValueIsFilled(vInteraction) Then
			vWriteDebug = vInteraction.DebugMode;
		EndIf;	
	EndIf;
	If vWriteDebug Then
		vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLogName, Enums.ExternalSystemEventTypes.Info, vInputParameters, , vMsg);
	Else
		WriteLogEvent(vFuncLogName, EventLogLevel.Information, , , vInputParameters);
	EndIf;

	vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "VerifyPayment")); 
	Try
		// Fill payments
		vQuery = New Query;
		vQuery.Text = 
		"SELECT DISTINCT
		|	Payments.Recorder AS Recorder,
		|	Payments.Recorder.Number AS Number,
		|	Payments.Recorder.Folio.Number AS FolioNumber,
		|	Payments.Recorder.ExternalCode AS ExternalCode,
		|	Payments.SumExpense AS Sum,
		|	Payments.Recorder.PaymentCurrency.Code AS PaymentCurrencyCode
		|FROM
		|	AccumulationRegister.CustomerAccounts.BalanceAndTurnovers(, , Recorder, RegisterRecordsAndPeriodBoundaries) AS Payments
		|WHERE
		|	Payments.Recorder.ExternalCode = &qExternalCode";
		vQuery.SetParameter("qExternalCode", pPaymentID);
		vPaymentResult = vQuery.Execute();
		vPaymentRow = vPaymentResult.Select();
		
		vPayments = New Array;
		vFolioList = New Array;   
		vSum = 0;
		While vPaymentRow.Next() Do  
			vPaymentNumber = TrimAll(vPaymentRow.Number); 
			vFolioNumber = TrimAll(vPaymentRow.FolioNumber);
			If vPayments.Find(vPaymentNumber) = Undefined Then
				vPayments.Add(vPaymentNumber);
			EndIf;	
			If vFolioList.Find(vFolioNumber) = Undefined Then
				vFolioList.Add(vFolioNumber);
			EndIf;	
			vSum = vSum + vPaymentRow.Sum;
		EndDo; 
		vRetXDTO.PaymentNumber = StrConcat(vPayments, ";");
		vRetXDTO.FolioNumber = StrConcat(vFolioList, ";");   
		vRetXDTO.Sum = vSum;     
		vRetXDTO.ErrorDescription = "";
	Except
		vRetXDTO.ErrorDescription = ErrorDescription();
	EndTry;	    
	
	// Log
	If vWriteDebug Then
		vExtraXML = cmGetXMLStringFromXDTO(vRetXDTO);
		vMsg =  NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLogName, Enums.ExternalSystemEventTypes.Info, , vExtraXML , vMsg);
	EndIf;
	
	Return vRetXDTO;
EndFunction

#EndRegion
