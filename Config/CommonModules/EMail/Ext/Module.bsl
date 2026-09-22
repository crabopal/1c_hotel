
#Region Public

// --------------------------------------------------------------------------------
Procedure Send(pEmployee, pSenderName, pFromEMail, rSubject, rTexts, pSMSTemplates = Undefined, pParentDoc = Undefined, pClient = Undefined, pAmountStr = Undefined, pDiscountCard = Undefined, 
			  pTextAttachments = Undefined, pAttachments = Undefined, pToEMail = Undefined, pReplyToEMail = Undefined,  pCCEMail = Undefined, pBCCEMail = Undefined, pExternalSystem = Undefined, 
			  pExternalTemplateID = Undefined, rSMTPConnection = Undefined, pLogoff = Undefined, DoNotSearchExternalSystem = False) Export
			  
	vExternalSystem = pExternalSystem;  
	If Not ValueIsFilled(vExternalSystem) And Not DoNotSearchExternalSystem Then
		If pSMSTemplates <> Undefined And ValueIsFilled(pSMSTemplates) Then 
			vExternalSystem = InformationRegisters.ExternalSystemIntegrationData.GetExternalSystem("SMSTemplates", "SMSTemplates", pSMSTemplates);
		EndIf; 
	EndIf;
		
	If Not ValueIsFilled(vExternalSystem) Then 
		rSubject = StrReplace(TrimAll(rSubject), "&amp;", "&");
		rTexts = StrReplace(TrimAll(rTexts), "&amp;", "&");   
		vEMailParameters = GetEMailParameters(pParentDoc, pClient, pAmountStr, pDiscountCard);   
		For Each vEMailParameter In vEMailParameters Do 
			SetParameter(rSubject, vEMailParameter); 
			SetParameter(rTexts, vEMailParameter);	
		EndDo;
		SendInternetMail(pEmployee, pSenderName, pFromEMail, rSubject, rTexts, pTextAttachments, pAttachments, pToEMail, pReplyToEMail, pCCEMail, pBCCEMail, rSMTPConnection, pLogoff);
	Else
		vDP = vExternalSystem.DataProcessor;
	
		If Not ValueIsFilled(vDP) Then
			Raise Nstr("en = 'Interaction has no service handling specified'; de = 'Für die Interaktion ist keine Servicebehandlung angegeben'; ru = 'У взаимодействия не указана обработка обслуживания'");
		EndIf;

		vDPO = Catalogs.DataProcessors.CreateDataProcessorByProcessing(vDP, True);

		If vDPO = Undefined Then
			Raise Nstr("en = 'Failed to initialize processing'; de = 'Fehler beim Initialisieren der Verarbeitung'; ru = 'Не удалось инициализировать обработку'");			
		EndIf;
		
		vExternalTemplateID = pExternalTemplateID;
		If Not ValueIsFilled(vExternalTemplateID) And ValueIsFilled(pSMSTemplates) Then
			vDataList = InformationRegisters.ExternalSystemIntegrationData.GetData(vExternalSystem, "SMSTemplates", "SMSTemplates", pSMSTemplates); 
			If vDataList.Count() > 0 Then
				vExternalTemplateID = vDataList[0].ExternalSystemDataCode;
			EndIf; 
		EndIf;     
		
		vArrayParameters = New Array;
		If ValueIsFilled(pSMSTemplates) Then
			vDataList = InformationRegisters.ExternalSystemIntegrationData.GetData(vExternalSystem, "String", "Parameter", pSMSTemplates); 
			If vDataList.Count() > 0 Then
				vArrayParameters = vDataList.UnloadColumn("RefKey2");
			EndIf;
		EndIf;
		
		vEMailParameters = GetEMailParameters(pParentDoc, pClient, pAmountStr, pDiscountCard, vArrayParameters);   
		
		vMessage = "";
		If Not vDPO.Send(pSenderName, pFromEMail, rSubject, rTexts, vEMailParameters, pTextAttachments, pAttachments, pToEMail, pReplyToEMail, vExternalTemplateID, vMessage) Then
			Raise vMessage;
		EndIf;
	EndIf;
EndProcedure // SendEMail

// --------------------------------------------------------------------------------
//  Function  returns structure witn Subject, Text and Sender Name for e-mail
//  Can be overriden by configuration extention or code from ExternatDataProcessors catalog
//
// Parameters:
//  pContext - Structure - Params
//  	* Hotel - not mandatory, will be taken from Reservation
//  	* Reservation ref - mandatory parameter
//  	* User - used to form the footer with signatures
//  	* Language - mandatory, the massage is compiled for this lang
//  	* GuestGroup - not mandatory, if not set will be taken from Reservation attribute
//  pUseFormattedString	 - Boolean	 - Use formatted string																 -
// 
// Returns:
//  Structure - Message parameters
//
Function GetReservationConfirmationSubjectAndText(pContext, pUseFormattedString = True) Export
	vMessage = New Structure("MessageSubject, MessageText, SenderName, SMSTemplates", "", "", "", Catalogs.SMSTemplates.EmptyRef());
	
	vHotel = SessionParameters.CurrentHotel;
	If pContext.Property("Hotel") Then
		vHotel = pContext.Hotel; // Will be used only if reservation ref is not set
	EndIf;
	
	vReservation = Documents.Reservation.EmptyRef();
	If pContext.Property("Reservation") Then
		vReservation = pContext.Reservation;
		vHotel = vReservation.Hotel;
	EndIf;
	
	vUser = SessionParameters.CurrentUser;
	If pContext.Property("User") Then
		vUser = pContext.User;
	EndIf;
	
	vLang = SessionParameters.CurrentLanguage; // Session language - use if nothing else is set
	If pContext.Property("Language") Then
		vLang = pContext.Language;
	EndIf;
	
	vHotelPrintName = "";
	If ValueIsFilled(vHotel) Then
		vHotelPrintName = Catalogs.Hotels.pmGetHotelPrintName(vHotel, vLang);
	EndIf;

	vGuestGroup	= Catalogs.GuestGroups.EmptyRef();
	If pContext.Property("GuestGroup") Then
		vGuestGroup = pContext.GuestGroup;
	Else
		vGuestGroup = vReservation.GuestGroup;
	EndIf;
	
	vMsgTemplate = Catalogs.SMSTemplates.SendReservationConfirmation;
	
	// Initialize message texts
	
	// Subject
	MessageSubject = cmNStr(vMsgTemplate.Description,vLang);
	
	If IsBlankString(MessageSubject) Then
		MessageSubject = StrTemplate(cmNStr("en = '%1 Reservation confirmation N%2'; 
											|de = '%1 Reservierungsbestätigung N%2'; 
											|ru = '%1 Подтверждение бронирования №%2'", vLang), 
		                             vHotelPrintName,
									 Format(vGuestGroup.Code, "ND=12; NFD=0; NG="));
	EndIf;
	
	// Body
	MessageText = SMS.GetHTMLTextByLanguage(vMsgTemplate, vLang);
	If IsBlankString(MessageText) Then
		MessageText = SMS.GetSMSTextByLanguage(vMsgTemplate, vLang);
	EndIf;
	
	If IsBlankString(MessageText) Then						
		EmailTextArray = New Array;
		
		// Employee signature
		vEmployeeSignature = TrimAll(cmNStr(vUser.Position, vLang) + " " + Catalogs.Employees.pmGetEmployeeDescription(vUser, vLang));
		
		MessageText = cmNStr("en='Dear Guest,
							|
							|Thank you for selecting &HotelName for your stay. We are delighted to share your reservation details.
							|
							|Please find the confirmation letter attached. Your reservation number is &GuestGroup.
							|'; 
							
							|de='Lieber Gast,
							|
							|Vielen Dank für die Wahl den &HotelName für Ihren Aufenthalt.
							|
							|Die Buchungsbestätigung ist beigefügt. Ihre Reservierungsnummer ist &GuestGroup.
							|';
							
							|ru='Дорогой гость,
							|
							|Благодарим за выбор &HotelName.
							|
							|Во вложении ваше подтверждение. Номер вашего бронирования &GuestGroup.
							|'",
		vLang);
		EmailTextArray.Add(MessageText);
		
		// Add wallet link
		vIntegration = Catalogs.ExternalSystemInteractions.GetWalletSystem(vHotel);
		If ValueIsFilled(vIntegration) Then
			wURL = Wallet.GetWalletURL(vIntegration, vReservation);
			If Not IsBlankString(wURL) Then
				MessageText = MessageText + cmNStr("en = 'Add to the wallet.                                                       
		                                                |'; 
													|de = 'Hinzufügen zu Wallet.
		                                                |'; 
													|ru = 'Добавить в Wallet.
		                                                |'", vLang);
				MessageText = MessageText + SMS.GetShortLink(wURL, vIntegration.URLShortener);
				MessageText = MessageText + Chars.LF;
				
				EmailTextArray.Add(Chars.LF); // Add some space
				EmailTextArray.Add(New FormattedString(cmNStr("en = 'Add to the wallet.'; de = 'Hinzufügen zu Wallet.'; ru = 'Добавить в Wallet.'", vLang), , , , wURL));
				EmailTextArray.Add(Chars.LF); // Add some space
			EndIf;
		EndIf;
		
		// Add reservation link
		vGuestURL = Catalogs.ExternalSystemInteractions.GetReservationGuestURL(vReservation);
		If Not IsBlankString(vGuestURL) Then
			
			vResURLText = cmNStr("en = '
								|You can enter guest details and pay for your stay to get express check-in.
								|'; 
								|de = '
								|Sie können die Daten des Gastes eingeben und die Unterkunft bezahlen, um den Express-Check-in bei der Ankunft zu erhalten.
								|'; 
								|ru = '
								|Вы можете ввести данные гостя и оплатить проживание, чтобы получить экспресс-регистрацию заезда по прибытии.
								|'", vLang);
			MessageText = MessageText + Chars.LF; 
			MessageText = MessageText + cmNStr("en = 'Access to your reservation online:'; de = 'Zugriff auf Ihre Online-Buchung:'; ru = 'Доступ к онлайн-бронированию:'", vLang);
			MessageText = MessageText + Chars.LF; 
			MessageText = MessageText + vGuestURL;
	
			EmailTextArray.Add(vResURLText);
			EmailTextArray.Add(New FormattedString(cmNStr("en = 'Access to your reservation online'; de = 'Zugriff auf Ihre Online-Buchung'; ru = 'Доступ к онлайн-бронированию'", vLang), , , , vGuestURL));
		EndIf;
		
		// Add signature
		MessageText = MessageText + Chars.LF + Chars.LF 
					  + cmNStr("en='Best regards,'; 
		                       |de='Best regards,'; 
		                       |ru='С уважением,'",
		                     vLang) + Chars.LF 
							 + vEmployeeSignature + Chars.LF 
					  		 + vHotelPrintName + Chars.LF 
							 + cmNStr(SessionParameters.ConfigurationName, vLang);
		
		EmailTextArray.Add(Chars.LF); // Add some space	
		EmailTextArray.Add(Chars.LF); // Add some space
		EmailTextArray.Add(Chars.LF); // Add some space
		
		EmailTextArray.Add(cmNStr("en = 'Best regards,'; de = 'Best regards,'; ru = 'С уважением,'", vLang));
		EmailTextArray.Add(Chars.LF);
		EmailTextArray.Add(vEmployeeSignature);
		EmailTextArray.Add(Chars.LF);
		EmailTextArray.Add(vHotelPrintName);
		
		EmailTextArray.Add(Chars.LF);
		EmailTextArray.Add(Chars.LF);
		EmailTextArray.Add(New FormattedString(cmNStr(SessionParameters.ConfigurationName, vLang), tcCommonFunctionOnClientServer.FontConstructor(, 7)));
		
		If pUseFormattedString Then
			vMessage.MessageText = New FormattedString(EmailTextArray);
		Else
			vMessage.MessageText = MessageText;
		Endif;
	Else
		vMessage.MessageText = MessageText;
	EndIf;
	vMessage.MessageSubject = MessageSubject;
	vMessage.SMSTemplates = Catalogs.SMSTemplates.SendReservationConfirmation;
	
	Return vMessage;
EndFunction //  GetReservationConfirmationSubjectAndText

// --------------------------------------------------------------------------------
Function GetEMailParameters(Val pDocRef, Val pClientRef = Undefined,  Val pAmountStr = "", Val pDiscountCard = Undefined, pArrayParameters = Undefined) Export 
	vParameters = New Map;  
	vHotel = Undefined;
	If ValueIsFilled(pDocRef) Then    
		vHotel = pDocRef.Hotel;
		vLanguage = vHotel.Language;
		If ValueIsFilled(pClientRef) Then
			vLanguage = pClientRef.Language;
		Else
            If TypeOf(pDocRef) = Type("DocumentRef.Accommodation") Or TypeOf(pDocRef) = Type("DocumentRef.Reservation") 
                Or TypeOf(pDocRef) = Type("DocumentRef.BonusesOperation") Then
				If ValueIsFilled(pDocRef.Guest) And ValueIsFilled(pDocRef.Guest.Language) Then
					vLanguage = pDocRef.Guest.Language;
				EndIf;
			EndIf;
		EndIf;  			
		If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("Dear") <> Undefined) Then
			vParameters.Insert("Dear", TrimAll(cmNStr("en = 'dear'; de = 'Sehr geehrte(r)'; ru = 'уважаемый(ая)'", vLanguage)));  
		EndIf;
		If ValueIsFilled(pClientRef) Then
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("Dear") <> Undefined) Then
				If ValueIsFilled(pClientRef.Sex) Then 
					If pClientRef.Sex = Enums.Sex.Male Then
						vParameters.Insert("Dear", TrimAll(cmNStr("en = 'dear'; de = 'Sehr geehrter'; ru = 'уважаемый'", vLanguage)));
					Else
						vParameters.Insert("Dear", TrimAll(cmNStr("en = 'dear'; de = 'Sehr geehrte'; ru = 'уважаемая'", vLanguage)));
					EndIf;
				EndIf;
			EndIf;
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("FirstName") <> Undefined) Then
				vParameters.Insert("FirstName", TrimAll(pClientRef.FirstName));
			EndIf;   
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("LastName") <> Undefined) Then
				vParameters.Insert("LastName", TrimAll(pClientRef.LastName));
			EndIf;
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("SecondName") <> Undefined) Then
				vParameters.Insert("SecondName", TrimAll(pClientRef.SecondName));
			EndIf;
		ElsIf (TypeOf(pDocRef) = Type("DocumentRef.Accommodation") Or TypeOf(pDocRef) = Type("DocumentRef.Reservation")) And ValueIsFilled(pDocRef.Guest) Then
			vGuestRef = pDocRef.Guest;
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("Dear") <> Undefined) Then
				If ValueIsFilled(vGuestRef.Sex) Then
					If vGuestRef.Sex = Enums.Sex.Male Then
						vParameters.Insert("Dear", TrimAll(cmNStr("en='dear';ru='уважаемый';de='Sehr geehrter'", vLanguage)));
					Else
						vParameters.Insert("Dear", TrimAll(cmNStr("en='dear';ru='уважаемая';de='Sehr geehrte'", vLanguage)));
					EndIf;     
				EndIf;  
			EndIf;
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("FirstName") <> Undefined) Then
				vParameters.Insert("FirstName", TrimAll(vGuestRef.FirstName));
			EndIf;
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("LastName") <> Undefined) Then
				vParameters.Insert("LastName", TrimAll(vGuestRef.LastName));
			EndIf;
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("SecondName") <> Undefined) Then
				vParameters.Insert("SecondName", TrimAll(vGuestRef.SecondName));
			EndIf;
		EndIf;
		If TypeOf(pDocRef) = Type("DocumentRef.Accommodation") Or TypeOf(pDocRef) = Type("DocumentRef.Reservation") Then 
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("CheckInDate") <> Undefined) Then
				vParameters.Insert("CheckInDate", Format(pDocRef.CheckInDate, "DF='dd.MM.yyyy'"));
			EndIf;
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("CheckInTime") <> Undefined) Then
				vParameters.Insert("CheckInTime", Format(pDocRef.CheckInDate, "DF='HH:mm'")); 
			EndIf;
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("CheckOutDate") <> Undefined) Then
				vParameters.Insert("CheckOutDate", Format(pDocRef.CheckOutDate, "DF='dd.MM.yyyy'"));
			EndIf;
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("CheckOutTime") <> Undefined) Then
				vParameters.Insert("CheckOutTime", Format(pDocRef.CheckOutDate, "DF='HH:mm'"));
			EndIf;
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("Duration") <> Undefined) Then
				vParameters.Insert("Duration", pDocRef.Duration);
			EndIf;
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("RoomType") <> Undefined) Then
				vParameters.Insert("RoomType", pDocRef.RoomType.GetObject().pmGetRoomTypeDescription(vLanguage)); 
			EndIf;
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("RoomClass") <> Undefined) Then
				vParameters.Insert("RoomClass", TrimAll(pDocRef.RoomType.RoomClass));
			EndIf;
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("Room") <> Undefined) Then
				vParameters.Insert("Room", TrimAll(pDocRef.Room));
			EndIf;
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("WindowView") <> Undefined) Then
				vParameters.Insert("WindowView", TrimAll(pDocRef.RoomType.WindowView));
			EndIf;
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("NumberOfPersons") <> Undefined) Then
				vParameters.Insert("NumberOfPersons", pDocRef.NumberOfAdults + pDocRef.NumberOfTeenagers + pDocRef.NumberOfChildren + pDocRef.NumberOfInfants);
			EndIf;
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("NumberOfAdults") <> Undefined) Then
				vParameters.Insert("NumberOfAdults", pDocRef.NumberOfAdults);
			EndIf;
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("NumberOfTeenagers") <> Undefined) Then
				vParameters.Insert("NumberOfTeenagers", pDocRef.NumberOfTeenagers);
			EndIf;
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("NumberOfChildren") <> Undefined) Then
				vParameters.Insert("NumberOfChildren", pDocRef.NumberOfChildren);
			EndIf;
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("NumberOfInfants") <> Undefined) Then
				vParameters.Insert("NumberOfInfants", pDocRef.NumberOfInfants);
			EndIf;
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("TotalChildren") <> Undefined) Then
				vParameters.Insert("TotalChildren", pDocRef.NumberOfTeenagers + pDocRef.NumberOfChildren + pDocRef.NumberOfInfants);
			EndIf; 
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("ServicesIncludedDescription") <> Undefined) Then 
				vRoomRate = pDocRef.RoomRate; 
				If ValueIsFilled(vRoomRate) Then
					vParameters.Insert("ServicesIncludedDescription", vRoomRate.ServicesIncludedDescription);
				EndIf;
			EndIf;
		ElsIf TypeOf(pDocRef) = Type("DocumentRef.ResourceReservation") Then
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("DateTimeFrom") <> Undefined) Then
				vParameters.Insert("DateTimeFrom", Format(pDocRef.DateTimeFrom, "DF='dd.MM.yyyy HH:mm'"));
			EndIf;
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("DateTimeTo") <> Undefined) Then
				vParameters.Insert("DateTimeTo", Format(pDocRef.DateTimeTo, "DF='dd.MM.yyyy HH:mm'"));
			EndIf;
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("Duration") <> Undefined) Then
				vParameters.Insert("Duration", pDocRef.Duration);
			EndIf;
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("Resource") <> Undefined) Then
				vParameters.Insert("Resource", TrimAll(pDocRef.Resource)); 
			EndIf;
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("ResourceType") <> Undefined) Then
				vParameters.Insert("ResourceType", TrimAll(pDocRef.ResourceType));
			EndIf;
		EndIf;
		If TypeOf(pDocRef) = Type("DocumentRef.Reservation") Then
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("ReservationUUID") <> Undefined) Then
				vParameters.Insert("ReservationUUID", TrimAll(pDocRef.UUID()));
			EndIf;
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("GuestReservationLink") <> Undefined) Then
				vParameters.Insert("GuestReservationLink", Catalogs.ExternalSystemInteractions.GetReservationGuestURL(pDocRef));
			EndIf;  
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("GuestRegistrationLink") <> Undefined) Then
				vParameters.Insert("GuestRegistrationLink", Catalogs.ExternalSystemInteractions.GetRegistrationGuestURL(pDocRef));
			EndIf;
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("GuestGroupReservationLink") <> Undefined) Then
				vParameters.Insert("GuestGroupReservationLink", Catalogs.ExternalSystemInteractions.GetGuestGroupURL(pDocRef.GuestGroup));
			EndIf;
		ElsIf TypeOf(pDocRef) = Type("DocumentRef.ProformaInvoice") Then
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("ProformaInvoiceLink") <> Undefined) Then
				vParameters.Insert("ProformaInvoiceLink", Catalogs.ExternalSystemInteractions.GetProformaInvoiceURL(pDocRef));
			EndIf;
		EndIf;
		If TypeOf(pDocRef) = Type("DocumentRef.Charge") Then
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("Service") <> Undefined) Then
				vService =  pDocRef.Service;
				vParameters.Insert("Service", TrimAll(?(IsBlankString(vService.DescriptionTranslations),vService.Description, Nstr(vService.DescriptionTranslations))));
			EndIf;
				If ValueIsFilled(pDocRef.Folio.GuestGroup) And pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("GuestGroup") <> Undefined) Then
					vParameters.Insert("GuestGroup", Format(pDocRef.Folio.GuestGroup.Code, "ND=12; NFD=0; NZ=; NG="));
				EndIf; 
			If ValueIsFilled(pDocRef.ParentDoc) And pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("ReservationNumber") <> Undefined) 
				And (TypeOf(pDocRef.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(pDocRef.ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(pDocRef.ParentDoc) = Type("DocumentRef.ResourceReservation")) Then
				vParameters.Insert("ReservationNumber", cmGetDocumentNumberPresentation(pDocRef.ParentDoc.Number));
			EndIf; 
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("GuestUUID") <> Undefined) Then
				If ValueIsFilled(pClientRef) Then
					vGuestUUID = SMS.GetMyFolioGuestIdByClient(pClientRef);
				Else	
					vGuestUUID = SMS.GetMyFolioGuestIdByClient(pDocRef.Folio.Client);
				EndIf;
				vParameters.Insert("GuestUUID", vGuestUUID); 
			EndIf;
		Else          
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("Service") <> Undefined) Then
				vParameters.Insert("Service", ""); 
			EndIf;
			If ValueIsFilled(pDocRef.GuestGroup) And pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("GuestGroup") <> Undefined) Then
				vParameters.Insert("GuestGroup", Format(pDocRef.GuestGroup.Code, "ND=12; NFD=0; NZ=; NG="));
			EndIf;
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("ReservationNumber") <> Undefined) Then
				If ValueIsFilled(pDocRef) Then
					If TypeOf(pDocRef) = Type("DocumentRef.Accommodation") Or TypeOf(pDocRef) = Type("DocumentRef.Reservation") Or TypeOf(pDocRef) = Type("DocumentRef.ResourceReservation") Then
						vParameters.Insert("ReservationNumber", cmGetDocumentNumberPresentation(pDocRef.Number));
					ElsIf TypeOf(pDocRef) = Type("DocumentRef.Folio") And ValueIsFilled(pDocRef.ParentDoc) Then
						If TypeOf(pDocRef.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(pDocRef.ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(pDocRef.ParentDoc) = Type("DocumentRef.ResourceReservation") Then
							vParameters.Insert("ReservationNumber", cmGetDocumentNumberPresentation(pDocRef.ParentDoc.Number));
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("GuestUUID") <> Undefined) Then
				vParameters.Insert("GuestUUID", SMS.GetMyFolioGuestId(pDocRef));
			EndIf;
		EndIf;   
		
		// Get hotel365 link
		If TypeOf(pDocRef) = Type("DocumentRef.Accommodation") Or TypeOf(pDocRef) = Type("DocumentRef.Reservation") Or TypeOf(pDocRef) = Type("DocumentRef.Folio") Or TypeOf(pDocRef) = Type("DocumentRef.ResourceReservation") Then
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("GuestHotel365Link") <> Undefined) Then
				vParameters.Insert("GuestHotel365Link", Catalogs.ExternalSystemInteractions.GetHotel365URL(pDocRef));
			EndIf; 
		EndIf;
		
		vHotelPrintName = "";
		If ValueIsFilled(vHotel) Then
			vHotelPrintName = Catalogs.Hotels.pmGetHotelPrintName(vHotel, vLanguage);
		EndIf;
		If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("HotelDesc") <> Undefined) Then
			vParameters.Insert("HotelDesc", vHotelPrintName);
		EndIf;
		If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("PaymentAmount") <> Undefined) Then
			vParameters.Insert("PaymentAmount", TrimAll(pAmountStr));
		EndIf;
		If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("HotelName") <> Undefined) Then
			vParameters.Insert("HotelName", vHotelPrintName);
		EndIf;
		
		If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("FolioBalance") <> Undefined) Then
			vGuestBalanceIsReceived = False;
			vDocuments = New ValueList();
			vDocuments.Add(pDocRef);
			vBalances = cmGetDocumentListBalances(vDocuments, vHotel);
			vGuestBalance = "0";
			For Each vBalancesRow In vBalances Do
				vGuestBalanceNum = vBalancesRow.ClientSumBalance;
				vGuestBalancePrefix = "";
				If vGuestBalanceNum < 0 Then
					vGuestBalancePrefix = cmNStr("en = 'deposit '; de = 'Guthaben '; ru = 'депозит '", vLanguage);
					vGuestBalanceNum = -vGuestBalanceNum;
				ElsIf vGuestBalanceNum > 0 Then
					vGuestBalancePrefix = cmNStr("en = 'debt '; de = 'Verschuldung '; ru = 'задолженность '", vLanguage);
				EndIf;
				If Not vGuestBalanceIsReceived Then
					vGuestBalanceIsReceived = True;
					vGuestBalance = vGuestBalancePrefix + TrimAll(vGuestBalanceNum);
				Else
					vGuestBalance = ", " + vGuestBalancePrefix + TrimAll(vGuestBalanceNum);
				EndIf;
			EndDo;
			vParameters.Insert("FolioBalance", vGuestBalance); 
		EndIf;
		
		vCheckGroupTotalAmount = ?(pArrayParameters <> Undefined, pArrayParameters.Find("GroupTotalAmount"), 0);
		vCheckGroupTotalPaymentsAmount = ?(pArrayParameters <> Undefined, pArrayParameters.Find("GroupTotalPaymentsAmount"), 0);
		vCheckAmountDue = ?(pArrayParameters <> Undefined, pArrayParameters.Find("AmountDue"), 0);
		
		If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And (vCheckGroupTotalAmount <> Undefined Or vCheckGroupTotalPaymentsAmount <> Undefined Or vCheckAmountDue <> Undefined)) Then
			If ValueIsFilled(pDocRef.GuestGroup) Then
				vGroupTotalAmount = 0;
				If vCheckGroupTotalAmount <> Undefined Or vCheckAmountDue <> Undefined Then  
					vGroupTotalSales = pDocRef.GuestGroup.GetObject().pmGetSalesTotals();		
					vGroupTotalSales.GroupBy("Currency", "Sales, SalesForecast, ExpectedSales");
					
					For Each vGroupTotalSalesRow In vGroupTotalSales Do
						vGroupTotalAmount = vGroupTotalAmount + Round(cmConvertCurrencies(vGroupTotalSalesRow.Sales + vGroupTotalSalesRow.SalesForecast, vGroupTotalSalesRow.Currency, , vHotel.BaseCurrency, , CurrentSessionDate(), vHotel), 2);
					EndDo; 
					If vCheckGroupTotalAmount <> Undefined Then
						vParameters.Insert("GroupTotalAmount", vGroupTotalAmount);
					EndIf;
				EndIf;
				
				vGroupTotalPaymentsAmount = 0;
				If vCheckGroupTotalPaymentsAmount <> Undefined Or vCheckAmountDue <> Undefined Then 
					vGroupTotalPayments = pDocRef.GuestGroup.GetObject().pmGetPaymentsTotals();
					vGroupTotalPayments.GroupBy("Currency", "Sum");
					For Each vGroupTotalPaymentsRow In vGroupTotalPayments Do
						vGroupTotalPaymentsAmount = vGroupTotalPaymentsAmount + Round(cmConvertCurrencies(vGroupTotalPaymentsRow.Sum, vGroupTotalPaymentsRow.Currency, , vHotel.BaseCurrency, , CurrentSessionDate(), vHotel), 2);
					EndDo;  
					If vCheckGroupTotalPaymentsAmount <> Undefined Then
						vParameters.Insert("GroupTotalPaymentsAmount", vGroupTotalPaymentsAmount);
					EndIf;
				EndIf;
				
				If vCheckAmountDue <> Undefined Then
					vParameters.Insert("AmountDue", vGroupTotalAmount - vGroupTotalPaymentsAmount); 
				EndIf; 
			EndIf;
		EndIf;
				
		vCheckFirstDayAmount = ?(pArrayParameters <> Undefined, pArrayParameters.Find("FirstDayAmount"), 0);
		vCheckHasBBPackage = ?(pArrayParameters <> Undefined, pArrayParameters.Find("HasBBPackage"), 0);
		vCheckHasHBPackage = ?(pArrayParameters <> Undefined, pArrayParameters.Find("HasHBPackage"), 0);
		vCheckHasFBPackage = ?(pArrayParameters <> Undefined, pArrayParameters.Find("HasFBPackage"), 0);
		vCheckHasAIPackage = ?(pArrayParameters <> Undefined, pArrayParameters.Find("HasAIPackage"), 0);
		vCheckHasFCPackage = ?(pArrayParameters <> Undefined, pArrayParameters.Find("HasFCPackage"), 0);
		
		If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And (vCheckFirstDayAmount <> Undefined Or vCheckHasBBPackage <> Undefined Or vCheckHasHBPackage <> Undefined 
			Or vCheckHasFBPackage <> Undefined Or vCheckHasAIPackage <> Undefined Or vCheckHasFCPackage <> Undefined)) Then
			If ValueIsFilled(pDocRef.GuestGroup) Then       
				vHasBBPackage = False;
				vHasHBPackage = False;
				vHasFBPackage = False;
				vHasAIPackage = False;
				vHasFCPackage = False;
						
				vDocs = cmGetGuestGroupDocuments(pDocRef.GuestGroup);
				vFirstDayAmount = 0;
				For Each vDocRef In vDocs Do
					vFirstDaySum = 0;
					vFirstDaySumCurrency = Undefined;
					
					vDocument = vDocRef.Reservation;
					
					If vCheckHasBBPackage <> Undefined Or vCheckHasHBPackage <> Undefined Or vCheckHasFBPackage <> Undefined Or vCheckHasAIPackage <> Undefined Or vCheckHasFCPackage <> Undefined Then
						If Not vHasBBPackage Or Not vHasHBPackage OR Not vHasFBPackage OR Not vHasAIPackage OR Not vHasFCPackage Then
							If ValueIsFilled(vDocument.ServicePackage) Then
								vServicePackage = vDocument.ServicePackage;
								If vServicePackage.IsMealBoardTerm Then
									If vServicePackage.IsBB And Not vHasBBPackage Then
										vHasBBPackage = True;	
									EndIf;
									If vServicePackage.IsHB And Not vHasHBPackage Then
										vHasHBPackage = True;	
									EndIf;
									If vServicePackage.IsFB And Not vHasFBPackage Then
										vHasFBPackage = True;	
									EndIf;
									If vServicePackage.IsAI And Not vHasAIPackage Then
										vHasAIPackage = True;	
									EndIf;
									If vServicePackage.IsFC And Not vHasFCPackage Then
										vHasFCPackage = True;	
									EndIf;
									If vHasBBPackage And vHasHBPackage And vHasFBPackage And vHasAIPackage And vHasFCPackage Then
										Break;	
									EndIf;  
								EndIf; 
							EndIf;
										
							For Each vRow In vDocument.ServicePackages Do  
								vServicePackage = vRow.ServicePackage;
								If vServicePackage.IsMealBoardTerm Then
									If vServicePackage.IsBB And Not vHasBBPackage Then
										vHasBBPackage = True;	
									EndIf;
									If vServicePackage.IsHB And Not vHasHBPackage Then
										vHasHBPackage = True;	
									EndIf;
									If vServicePackage.IsFB And Not vHasFBPackage Then
										vHasFBPackage = True;	
									EndIf;
									If vServicePackage.IsAI And Not vHasAIPackage Then
										vHasAIPackage = True;	
									EndIf;
									If vServicePackage.IsFC And Not vHasFCPackage Then
										vHasFCPackage = True;	
									EndIf;
									If vHasBBPackage And vHasHBPackage And vHasFBPackage And vHasAIPackage And vHasFCPackage Then
										Break;	
									EndIf;  
								EndIf;
							EndDo;				
						EndIf; 
					EndIf;
					
					If vCheckFirstDayAmount <> Undefined Then
						vPrices = vDocument.GetObject().pmGetPrices(True);
						vFirstAccDate = Undefined;
						For Each vPricesRow In vPrices Do
							If Not ValueIsFilled(vFirstAccDate) Then
								vFirstAccDate = vPricesRow.AccountingDate;
								vFirstDaySumCurrency = vPricesRow.FolioCurrency;
							EndIf;
							If vPricesRow.AccountingDate = vFirstAccDate Then
								vFirstDaySum = vFirstDaySum + vPricesRow.Price;
							Else
								Break;
							EndIf;
						EndDo;
						If vFirstDaySum <> 0 Then
							If vFirstDaySumCurrency <> vHotel.BaseCurrency Then
								vFirstDaySum = Round(cmConvertCurrencies(vFirstDaySum, vFirstDaySumCurrency, , vHotel.BaseCurrency, , CurrentSessionDate(), vHotel), 2);
							EndIf;
						EndIf;
						vFirstDayAmount = vFirstDayAmount + vFirstDaySum;
					EndIf;
				EndDo; 
				If vCheckFirstDayAmount <> Undefined Then
					vParameters.Insert("FirstDayAmount", vFirstDayAmount);  
				EndIf;  
				If vCheckHasBBPackage <> Undefined Or vCheckHasHBPackage <> Undefined Or vCheckHasFBPackage <> Undefined Or vCheckHasAIPackage <> Undefined Or vCheckHasFCPackage <> Undefined Then
					vParameters.Insert("HasBBPackage", ?(vHasBBPackage, cmNStr("en = 'Yes'; de = 'Ja'; ru = 'Да'", vLanguage), cmNStr("en = 'Not'; de = 'Nein'; ru = 'Нет'", vLanguage)));
					vParameters.Insert("HasHBPackage", ?(vHasHBPackage, cmNStr("en = 'Yes'; de = 'Ja'; ru = 'Да'", vLanguage), cmNStr("en = 'Not'; de = 'Nein'; ru = 'Нет'", vLanguage)));
					vParameters.Insert("HasFBPackage", ?(vHasFBPackage, cmNStr("en = 'Yes'; de = 'Ja'; ru = 'Да'", vLanguage), cmNStr("en = 'Not'; de = 'Nein'; ru = 'Нет'", vLanguage)));
					vParameters.Insert("HasAIPackage", ?(vHasAIPackage, cmNStr("en = 'Yes'; de = 'Ja'; ru = 'Да'", vLanguage), cmNStr("en = 'Not'; de = 'Nein'; ru = 'Нет'", vLanguage)));
					vParameters.Insert("HasFCPackage", ?(vHasFCPackage, cmNStr("en = 'Yes'; de = 'Ja'; ru = 'Да'", vLanguage), cmNStr("en = 'Not'; de = 'Nein'; ru = 'Нет'", vLanguage)));
				EndIf;  
			EndIf;
		EndIf;
	ElsIf ValueIsFilled(pClientRef) Then
		If TypeOf(pClientRef) = Type("CatalogRef.Clients") Then	
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("Dear") <> Undefined) Then
				If ValueIsFilled(pClientRef.Sex) Then
					If pClientRef.Sex = Enums.Sex.Male Then
						vParameters.Insert("Dear", TrimAll(cmNStr("en='dear';ru='уважаемый';de='Sehr geehrter'", vLanguage)));
					Else
						vParameters.Insert("Dear", TrimAll(cmNStr("en='dear';ru='уважаемая';de='Sehr geehrte'", vLanguage)));
					EndIf; 
				Else
					vParameters.Insert("Dear", TrimAll(cmNStr("en='dear';ru='уважаемый(ая)';de='Sehr geehrte(r)'", vLanguage)));
				EndIf;
			EndIf;
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("FirstName") <> Undefined) Then
				vParameters.Insert("FirstName", TrimAll(pClientRef.FirstName));
			EndIf; 
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("LastName") <> Undefined) Then
				vParameters.Insert("LastName", TrimAll(pClientRef.LastName)); 
			EndIf;
			If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And pArrayParameters.Find("SecondName") <> Undefined) Then
				vParameters.Insert("SecondName", TrimAll(pClientRef.SecondName));
			EndIf;
			If ValueIsFilled(pDiscountCard) Then
				If pArrayParameters = Undefined Or (pArrayParameters <> Undefined And (pArrayParameters.Find("DiscountCardBalance") <> Undefined Or pArrayParameters.Find("CardID") <> Undefined)) Then
	                vCardData = AccumulationRegisters.Bonuses.mmGetBalanceByCard(pDiscountCard);
	                vTotalByCard = Format(vCardData.Balance, "NFD=2; NZ=0.00");
					vParameters.Insert("DiscountCardBalance", vTotalByCard);
					vParameters.Insert("CardID", pDiscountCard.Identifier); 
				EndIf;
            EndIf; 
		EndIf;
	EndIf; 
	
	vEmployee = SessionParameters.CurrentUser;
	vParameters.Insert("EmployeeFirstName", TrimAll(vEmployee.FirstName));
	vParameters.Insert("EmployeeSecondName", TrimAll(vEmployee.SecondName));
	vParameters.Insert("EmployeeLastName", TrimAll(vEmployee.LastName));
	vParameters.Insert("EmployeeFullName", TrimAll(Catalogs.Employees.pmGetEmployeeDescription(vEmployee, vLanguage)));
	vParameters.Insert("EmployeeDepartment", TrimAll(vEmployee.Department.Description));
	vParameters.Insert("EmployeePosition", cmNStr(vEmployee.Position, vLanguage));
	
	Return vParameters;
EndFunction // GetSMSParameters 

// --------------------------------------------------------------------------------
// 
// Returns:
//  Valuelist - EMail parameters 
//
Function GetEMailParametersList() Export
	vKWList = New Valuelist();
	
	vKWList.Add("FirstName", NStr("en='Client first name'; ru='Имя клиента'; de='Kunde Name'"));
	vKWList.Add("LastName", NStr("en='Client last name'; ru='Фамилия клиента'; de='Kunde Nachname'"));
	vKWList.Add("SecondName", NStr("en='Client second name'; ru='Отчество клиента'; de='Kunde zweiter Vorname'"));
	vKWList.Add("CheckInDate", NStr("en='Check-in date'; ru='Дата заезда'; de='Anreise datum'"));
	vKWList.Add("CheckInTime", NStr("en='Check-in time'; ru='Время заезда'; de='Anreisezeit'"));
	vKWList.Add("CheckOutDate", NStr("en='Check-out date'; ru='Дата выезда'; de='Abreise datum'"));
	vKWList.Add("CheckOutTime", NStr("en='Check-out time'; ru='Время выезда'; de='Abreisezeit'"));	
	vKWList.Add("Duration", NStr("en='Duration of stay'; ru='Продолжительность проживания'; de='Aufenthaltsdauer'"));
	vKWList.Add("Room", NStr("en='Room number'; ru='Номер комнаты'; de='Zimmernummer'"));
	vKWList.Add("RoomType", NStr("en='Room type'; ru='Тип номера'; de='Zimmertyp'"));
	vKWList.Add("RoomClass", NStr("en='Room class'; ru='Класс номера'; de='Zimmerklasse'"));
	vKWList.Add("WindowView", NStr("en='Window view'; ru='Вид из окна'; de='Fensteransicht'"));
	vKWList.Add("Resource", NStr("en='Resource'; ru='Ресурс'; de='Ressource'"));
	vKWList.Add("ResourceType", NStr("en='Resource type'; ru='Тип ресурса'; de='Ressourcetyp'"));
	vKWList.Add("Service", NStr("en='Service'; ru='Услуга'; de='Service'"));
	vKWList.Add("GuestGroup", NStr("en='Guest group number'; ru='Номер группы'; de='Gastgruppennummer'"));
	vKWList.Add("ReservationNumber", NStr("en='Reservation number'; ru='Индивидуальный номер брони'; de='Reservierungsnummer'"));
	vKWList.Add("HotelName", NStr("en='Hotel name'; ru='Наименование отеля'; de='Hotelname'"));
	vKWList.Add("PaymentAmount", NStr("en='Payment amount'; ru='Сумма платежа'; de='Zahlungsbetrag'"));
	vKWList.Add("GuestUUID", NStr("en='Client ID in ""My folio"" system'; ru='ID клиента в системе ""Мой счет""'; de='Kunde ID in ""My Folio"" System'"));
	vKWList.Add("HotelUUID", NStr("en='Hotel ID in ""My folio"" system'; ru='ID отеля в системе ""Мой счет""'; de='Hotel ID in ""My Folio"" System'"));
	vKWList.Add("FolioBalance", NStr("en='Client folios balance'; ru='Баланс по лицевым счетам клиента'; de='Kunde Foliosaldo'"));
	vKWList.Add("GroupTotalAmount", NStr("en='Group total charging amount'; ru='Сумма всех начислений по группе клиента'; de='Total summe für die Kundegruppe'"));
	vKWList.Add("GroupTotalPaymentsAmount", NStr("en='Group total payments amount'; ru='Сумма всех платежей по группе клиента'; de='Gesamtbetrag der Zahlungen für die Gruppe'"));	
	vKWList.Add("ReservationUUID", NStr("en = 'Reservierung ID'; de = 'Reservation ID'; ru = 'ID брони'"));
	vKWList.Add("GuestReservationLink", NStr("en = 'Reservierung link'; de = 'Reservation link for a guest'; ru = 'Ссылка на бронь для гостя'")); 
	vKWList.Add("GuestRegistrationLink", NStr("en = 'Registration link'; de = 'Registration link for a guest'; ru = 'Ссылка на регистрацию для гостя'"));
	vKWList.Add("GuestGroupReservationLink", NStr("en = 'Guest group reservation link'; de = 'Guest group reservation link'; ru = 'Ссылка на бронь для группы гостей'"));
	vKWList.Add("GuestHotel365Link", NStr("en = 'Folio link'; de = 'Folio link for a guest'; ru = 'Ссылка на фолио для гостя'"));
	vKWList.Add("CardID", NStr("en = 'Card ID'; de = 'Ausweiskarte'; ru = 'ID Карты'"));
    vKWList.Add("DiscountCardBalance", NStr("en = 'Discount card balance'; de = 'Rabattkartenguthaben'; ru = 'Баланс дисконтной карты'"));
    vKWList.Add("BonusesOperationAmount", NStr("en = 'Amount of discount card transaction'; de = 'Betrag der Rabattkartentransaktion'; ru = 'Сумма операции дисконтной карты'"));
    vKWList.Add("WalletURL", NStr("en = 'Wallet URL'; de = 'Wallet URL'; ru = 'Wallet URL'"));
	vKWList.Add("ProformaInvoiceLink", NStr("en = 'Proforma-Rechnung zahlung link'; de = 'Proforma invoice payment link'; ru = 'Ссылка на оплату счета'"));
	vKWList.Add("EmployeeFirstName", NStr("en='Employee.FirstName'; ru='Сотрудник.Имя'; de='Employee.FirstName'"));
	vKWList.Add("EmployeeSecondName", NStr("en='Employee.SecondName'; ru='Сотрудник.Отчество'; de='Employee.SecondName'"));
	vKWList.Add("EmployeeLastName", NStr("en='Employee.LastName'; ru='Сотрудник.Фамилия'; de='Employee.LastName'"));
	vKWList.Add("EmployeeFullName", NStr("en='Employee.FullName'; ru='Сотрудник.ФИО'; de='Employee.FullName'"));
	vKWList.Add("EmployeeDepartment", NStr("en='Employee.Department'; ru='Сотрудник.Отдел'; de='Employee.Department'"));
	vKWList.Add("EmployeePosition", NStr("en='Employee.Position'; ru='Сотрудник.Должность'; de='Employee.Position'"));
	vKWList.Add("AgentEmail", NStr("en = 'Agent.Email'; de = 'Agent.Email'; ru = 'Агент.Email'")); 
	vKWList.Add("AgentCode", NStr("en = 'Agent.Token'; de = 'Agent.Zeichen'; ru = 'Агент.Token'"));
	vKWList.Add("AgentContractNumber", NStr("en = 'Agent.Contract number'; de = 'Agent.Vertragsnummer'; ru = 'Агент.Номер договора'"));
	vKWList.Add("AgentContractDesc", NStr("en = 'Agent.Contract description'; de = 'Agent.Name des Vertrags'; ru = 'Агент.Наименование договора'"));
	vKWList.Add("AgentCustomerDesc", NStr("en = 'Agent.Description'; de = 'Agent.Name'; ru = 'Агент.Наименование'"));
	vKWList.Add("AgentRegLink", NStr("en = 'Agent.Registration link'; de = 'Agent.Registrierungslink'; ru = 'Агент.Ссылка на регистрацию'"));
	vKWList.Add("AgentAuthLink", NStr("en = 'Agent.Link for booking'; de = 'Agent.Link zur Buchung'; ru = 'Агент.Ссылка для бронирования'"));	
	vKWList.Add("HotelDesc", NStr("en = 'Hotel name'; de = 'Hotelname'; ru = 'Наименование гостиницы'"));
	vKWList.Add("NumberOfPersons", NStr("en = 'Number of persons'; de = 'Anzahl Personen'; ru = 'Количество человек'"));
	vKWList.Add("NumberOfAdults", NStr("en = 'Number of adults'; de = 'Anzahl Erwachsene'; ru = 'Количество взрослых'"));
    vKWList.Add("NumberOfTeenagers", NStr("en = 'Number of teenagers'; de = 'Anzahl Teenager'; ru = 'Количество подростков'"));
    vKWList.Add("NumberOfChildren", NStr("en = 'Number of children'; de = 'Anzahl der Kinder'; ru = 'Количество детей'"));
	vKWList.Add("NumberOfInfants", NStr("en = 'Number of infants'; de = 'Anzahl der Säuglinge'; ru = 'Количество младенцев'"));
	vKWList.Add("TotalChildren", NStr("en = 'Total children'; de = 'Kinder insgesamt'; ru = 'Всего детей'"));
	vKWList.Add("FirstDayAmount", NStr("en = 'First day amount'; de = 'Erster Tagesbetrag'; ru = 'Сумма за первый день'"));
	vKWList.Add("AmountDue", NStr("en = 'Amount due'; de = 'Fälliger Betrag'; ru = 'Сумма к оплате'"));	
	vKWList.Add("HasBBPackage", NStr("en = 'Bed && Breakfast'; de = 'Bed && Breakfast'; ru = 'Проживание с завтраком'"));
	vKWList.Add("HasHBPackage", NStr("en = 'Halfboard'; de = 'Halfboard'; ru = 'Полупансион'"));
	vKWList.Add("HasFBPackage", NStr("en = 'Fullboard'; de = 'Fullboard'; ru = 'Полный пансион'"));
	vKWList.Add("HasAIPackage", NStr("en = 'All inclusive'; de = 'All inclusive'; ru = 'Всё включено'"));
	vKWList.Add("HasFCPackage", NStr("en = 'Full complimentary'; de = 'Voll kostenlos'; ru = 'Бесплатное питание'"));
	vKWList.Add("ServicesIncludedDescription", NStr("en = 'Services included in the rate'; de = 'Tarif enthaltenen Dienstleistungen'; ru = 'Услуги включенные в тариф'"));
	vKWList.Add("DateTimeFrom", NStr("en = 'Resource reservation start time'; de = 'Startzeit der Ressourcenreservierung'; ru = 'Время начала брони ресурсов'"));
	vKWList.Add("DateTimeTo", NStr("en = 'Resource reservation end time'; de = 'Endzeit der Ressourcenreservierung'; ru = 'Время окончания брони ресурсов'"));
		
	Return vKWList;
EndFunction

// --------------------------------------------------------------------------------
//
// Parameters:
//  rText		 - String	 - Text
//  vParameter	 - Structure - Parameter
//
Procedure SetParameter(rText, pParameter) Export 
	If TrimAll(pParameter.Key) = "Dear" Then
		vDear = "";
		If CheckDear(rText) Then
			vDear = Upper(Left(pParameter.Value, 1)) + Mid(pParameter.Value, 2);	
		Else
			vDear = Lower(pParameter.Value);	
		EndIf; 
		rText = StrReplace(rText, "&" + TrimAll(pParameter.Key), TrimAll(vDear));
	Else
		rText = StrReplace(rText, "&" + TrimAll(pParameter.Key), TrimAll(pParameter.Value));
	EndIf;		
EndProcedure // SetParameter

// -----------------------------------------------------------------------------
//
// Parameters:
//  pSMSText - String	 - Sms text
// 
// Returns:
//  Boolean - True or false
//
Function CheckDear(pSMSText) Export 
	vDearIsFindPos = StrFind(pSMSText, "&Dear");
	If vDearIsFindPos  > 0 Then
		If Upper(Left(pSMSText, 2)) = "RU" Or Upper(Left(pSMSText, 2)) = "EN" Or Upper(Left(pSMSText, 2)) = "DE" Then
			If vDearIsFindPos <= 7 Then
				Return True;
			EndIf;	
		Else
			If vDearIsFindPos = 1 Then
				Return True;
			EndIf;	
		EndIf;
		If StrFind(pSMSText, ". &Dear") > 0 Then
			Return True;	
		EndIf;
		If StrFind(pSMSText, ">&Dear") > 0 Then
			Return True;	
		EndIf;
	EndIf;
	Return False;
EndFunction // CheckDear

// -----------------------------------------------------------------------------
//
// Parameters:
//  pPicture - Picture	 - Picture
// 
// Returns:
//  String - HTMLString
//
Function GetPictureIsBase64HTMLString(pPicture) Export
	vImageType = GetImageType(pPicture.Format()); 
	If IsBlankString(vImageType) Then
		vImageType = "png";	
	EndIf;	
	Return StrTemplate("data:image/%1;base64,%2", vImageType, StrReplace(Base64String(pPicture.GetBinaryData()), Chars.CR + Chars.LF, ""));	
EndFunction // GetBase64Picture

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure SendInternetMail(Val pEmployee, Val pSenderName, Val pFromEMail, Val pSubject, Val pTexts, pTextAttachments, pAttachments, pToEMail, pReplyToEMail, pCCEMail, pBCCEMail, rSMTPConnection, pLogoff)
	vEmailAccount = pEmployee;
	If ValueIsFilled(pEmployee) And TypeOf(pEmployee) = Type("CatalogRef.Employees") And ValueIsFilled(pEmployee.EmailAccount) Then
		vEmailAccount = pEmployee.EmailAccount;
	EndIf;
	
	// Create E-Mail message
	vEMail = New InternetMailMessage();
	
	// Sender
	If ValueIsFilled(vEmailAccount) And TypeOf(vEmailAccount) = Type("CatalogRef.EmailAccounts") Then
		vEMail.SenderName = TrimAll(vEmailAccount.Description);
	Else
		vEMail.SenderName = TrimAll(pSenderName);
	EndIf;
	// From address
	If ValueIsFilled(pFromEMail) Then
		vEMail.From = TrimAll(pFromEMail); 
	Else
		If ValueIsFilled(vEmailAccount) And TypeOf(vEmailAccount) = Type("CatalogRef.EmailAccounts") Then
			If Not IsBlankString(vEmailAccount.EMail) Then
				vEMail.From = TrimAll(vEmailAccount.EMail);
			EndIf;
		EndIf;
	EndIf;
	// Add to addresses
	If pToEMail <> Undefined Then
		For Each vEMailItem In pToEMail Do
			vEMail.To.Add(TrimAll(vEMailItem));
		EndDo; 
	EndIf;
	// Add reply to addresses
	If pReplyToEMail <> Undefined Then
		For Each vEMailItem In pReplyToEMail Do
			vEMail.ReplyTo.Add(TrimAll(vEMailItem));
		EndDo;
	EndIf;
	If vEMail.ReplyTo.Count() = 0 Then
		If ValueIsFilled(vEmailAccount) And TypeOf(vEmailAccount) = Type("CatalogRef.EmailAccounts") Then
			If Not IsBlankString(vEmailAccount.ReplyToEMail) Then
				vEMailsList = cmParseEMailAddress(TrimAll(vEmailAccount.ReplyToEMail));
				For Each vEMailItem In vEMailsList Do
					vEMail.ReplyTo.Add(TrimAll(vEMailItem.Value));
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	// Add cc addresses
	If pCCEMail <> Undefined Then
		For Each vEMailItem In pCCEMail Do
			vEMail.Cc.Add(TrimAll(vEMailItem));
		EndDo;
	EndIf;
	// Add bcc addresses
	If pBCCEMail <> Undefined Then
		For Each vEMailItem In pBCCEMail Do
			vEMail.Bcc.Add(TrimAll(vEMailItem));
		EndDo;
	EndIf;
	If vEMail.Bcc.Count() = 0 Then
		If ValueIsFilled(vEmailAccount) And TypeOf(vEmailAccount) = Type("CatalogRef.EmailAccounts") Then
			If Not IsBlankString(vEmailAccount.BccEMail) Then
				vEMailsList = cmParseEMailAddress(TrimAll(vEmailAccount.BccEMail));
				For Each vEMailItem In vEMailsList Do
					vEMail.Bcc.Add(TrimAll(vEMailItem.Value));
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	
	// Checks
	If vEMail.To.Count() = 0 And vEMail.Cc.Count() = 0 And vEMail.Bcc.Count() = 0 Then
		Raise NStr("en = 'Letter must have at least one recipient'; de = 'Der Brief muss mindestens einen Empfänger haben'; ru = 'Письмо должно иметь хотя бы одного получателя'");		
	EndIf;
	
	// Add message subject and text
	vTexts = pTexts; 
	If pTextAttachments <> Undefined Then
		For Each vAttachment In pTextAttachments Do
			vAttachmentPicture = vEMail.Attachments.Add(vAttachment.Value.GetBinaryData());
			vAttachmentPicture.CID = vAttachment.Key;
			vTexts = StrReplace(vTexts, vAttachment.Key, "cid:" + vAttachmentPicture.CID);
		EndDo; 
	EndIf;
	vEMail.Subject = TrimAll(pSubject);
	If StrFind(Lower(TrimAll(vTexts)), "<html") = 0 And StrFind(Lower(TrimAll(vTexts)), "<HTML") = 0 Then
		vEMail.Texts.Add(TrimAll(vTexts));
	Else   
		vAttachments = New Structure(); 
		vHTMLDoc = New FormattedDocument;
		vHTMLDoc.SetHTML(TrimAll(vTexts), vAttachments);
		vHTMLDoc.GetHTML(vTexts, vAttachments);
		
		For Each vAttachment In vAttachments Do
			vAttachmentPicture = vEMail.Attachments.Add(vAttachment.Value.GetBinaryData());
			vAttachmentPicture.CID = vAttachment.Key;
			vTexts = StrReplace(vTexts, vAttachment.Key, "cid:" + vAttachmentPicture.CID);
		EndDo;
		
		vEMail.Texts.Add(TrimAll(vTexts), InternetMailTextType.HTML);
		vEMail.ProcessTexts();
	EndIf;
	
	// Attachments
	If pAttachments <> Undefined Then
		For Each vAttachment In pAttachments Do
			vEMail.Attachments.Add(vAttachment.Value, vAttachment.Key);
		EndDo;
	EndIf;
	
	// Create connection to the mail server
	If rSMTPConnection = Undefined Then
		// Create profile to use for connection
		vProfile = New InternetMailProfile();
		vProfile.POP3BeforeSMTP = vEmailAccount.InternetMailPOP3BeforeSMTP;
		If vProfile.POP3BeforeSMTP Then
			vProfile.POP3ServerAddress = vEmailAccount.InternetMailPOP3ServerAddress;
			vProfile.POP3Port = vEmailAccount.InternetMailPOP3Port;
			vProfile.POP3UseSSL = vEmailAccount.InternetMailPOP3UseSSL;
			vProfile.POP3SecureAuthenticationOnly = vEmailAccount.InternetMailPOP3SecureAuthenticationOnly;
			vProfile.POP3Authentication = cmGetPOP3Authentication(vEmailAccount.InternetMailPOP3Authentication);
			vProfile.User = vEmailAccount.InternetMailUser;
			vProfile.Password = vEmailAccount.InternetMailPassword;
		EndIf;
		vProfile.SMTPServerAddress = vEmailAccount.InternetMailSMTPServerAddress;
		vProfile.SMTPPort = vEmailAccount.InternetMailSMTPPort;
		vProfile.SMTPUseSSL = vEmailAccount.InternetMailSMTPUseSSL;
		vProfile.SMTPSecureAuthenticationOnly = vEmailAccount.InternetMailSMTPSecureAuthenticationOnly;
		vProfile.SMTPAuthentication = cmGetSMTPAuthentication(vEmailAccount.InternetMailSMTPAuthentication);
		If Not IsBlankString(vEmailAccount.InternetMailSMTPUser) Then
			vProfile.SMTPUser = vEmailAccount.InternetMailSMTPUser;
			vProfile.SMTPPassword = vEmailAccount.InternetMailSMTPPassword;
		EndIf;
		If vEmailAccount.InternetMailTimeout <> 0 Then
			vProfile.Timeout = vEmailAccount.InternetMailTimeout;
		EndIf;

		rSMTPConnection = New InternetMail;
		rSMTPConnection.Logon(vProfile); 
	EndIf;
	rSMTPConnection.Send(vEMail);
	If pLogoff = Undefined Or pLogoff Then
		rSMTPConnection.Logoff();
	EndIf;	
EndProcedure // SendInternetMail

// -----------------------------------------------------------------------------
//
// Parameters:
//  pFormat	 - PictureFormat - Picture format (Picture.Format)
// 
// Returns:
//  String - Image type
//
Function GetImageType(pFormat)  
	vImageType = "";
	If pFormat = PictureFormat.PNG Then
		vImageType = "png";	
	ElsIf pFormat = PictureFormat.JPEG Then
		vImageType = "jpeg";
	ElsIf pFormat = PictureFormat.SVG Then
		vImageType = "svg+xml";
	ElsIf pFormat = PictureFormat.GIF Then
		vImageType = "gif";
	ElsIf pFormat = PictureFormat.BMP Then
		vImageType = "bmp";
	Else
		vImageType = "";		
	EndIf;     
	
	Return vImageType;
EndFunction // GetImageType

#EndRegion
