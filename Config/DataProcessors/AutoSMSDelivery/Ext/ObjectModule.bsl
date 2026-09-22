
// -----------------------------------------------------------------------------
// Data processors framework start
// -----------------------------------------------------------------------------

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
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(AccountingDate) Then
		AccountingDate = BegOfDay(CurrentSessionDate());
	EndIf;
	If Not ValueIsFilled(DeliveryType) Then
		DeliveryType = Enums.DeliveryTypes.SMS;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	pmDoAutoDelivery(pIsInteractive);
EndProcedure // pmRun

// -----------------------------------------------------------------------------
// Data processors framework end
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure FillTemplateTexts(pSMSDeliveryObject) 
	vUseHTML = False;
	vEmptyHTMLBody1 = 
	"<body>
	|</body>";
	vEmptyHTMLBody2 = 
	"<body>
	|<p><br></p>
	|</body>";
	vTemplate = pSMSDeliveryObject.SMSTemplate;
	If pSMSDeliveryObject.DeliveryType = Enums.DeliveryTypes.EMail And 
	  (Not IsBlankString(vTemplate.HTMLTextRu) And StrFind(vTemplate.HTMLTextRu, vEmptyHTMLBody1) = 0 And StrFind(vTemplate.HTMLTextRu, vEmptyHTMLBody2) = 0 Or 
	   Not IsBlankString(vTemplate.HTMLTextEn) And StrFind(vTemplate.HTMLTextEn, vEmptyHTMLBody1) = 0 And StrFind(vTemplate.HTMLTextEn, vEmptyHTMLBody2) = 0 Or 
	   Not IsBlankString(vTemplate.HTMLTextDe) And StrFind(vTemplate.HTMLTextDe, vEmptyHTMLBody1) = 0 And StrFind(vTemplate.HTMLTextDe, vEmptyHTMLBody2) = 0) Then
		vUseHTML = True;
	EndIf;
	If vUseHTML Then
		pSMSDeliveryObject.TemplateTextRu = TrimR(vTemplate.HTMLTextRu);
		pSMSDeliveryObject.TemplateTextEn = TrimR(vTemplate.HTMLTextEn);
		pSMSDeliveryObject.TemplateTextDe = TrimR(vTemplate.HTMLTextDe);
	Else
		pSMSDeliveryObject.TemplateTextRu = TrimR(vTemplate.SMSTextRu);
		pSMSDeliveryObject.TemplateTextEn = TrimR(vTemplate.SMSTextEn);
		pSMSDeliveryObject.TemplateTextDe = TrimR(vTemplate.SMSTextDe);
	EndIf;
EndProcedure // FillTemplateTexts

// -----------------------------------------------------------------------------
Procedure DoMessagesDelivery(pSMSDeliveryObj)
	// Check document attributes
	vMessages = New ValueList();
	vErrorMessage = "";
	vAttributeInErr = "";
	If pSMSDeliveryObj.pmCheckDocumentAttributes(vErrorMessage, vAttributeInErr) Then
		Raise NStr(vErrorMessage);
	EndIf;
	If pSMSDeliveryObj.Receivers.Count() = 0 Then
		Return;
	EndIf;
	// Write document
	pSMSDeliveryObj.Date = CurrentSessionDate();
	pSMSDeliveryObj.Write(DocumentWriteMode.Write);
	// Do delivery
	vSMTPConnection = Undefined;
	vLogoff = False;
	For Each vRow In pSMSDeliveryObj.Receivers Do
		If vRow.IsSent Then
			Continue;
		EndIf;
		If (DeliveryType = Enums.DeliveryTypes.SMS Or DeliveryType = Enums.DeliveryTypes.Both) And Not IsBlankString(vRow.Phone) Then
			// Call API
			vResult = "";
			vMessageID = "";
			vCost = 0;
			If SMS.SendMessage(TrimR(vRow.SMSText), TrimAll(vRow.Phone), pSMSDeliveryObj.SMSTemplate, pSMSDeliveryObj.Sender, ?(pSMSDeliveryObj.IsByCustomers, vRow.Customer, vRow.Client), vRow.ClientDoc,,, vResult, vMessageID, vCost) Then
				vRow.Result = "";
				vRow.IsSent = True;
				vRow.MessageID = vMessageID;
				vRow.Cost = vCost;
			Else
				vRow.Result = vResult;
				vRow.MessageID = vMessageID;
				vRow.Cost = vCost;
			EndIf;
		EndIf;
		If (DeliveryType = Enums.DeliveryTypes.EMail Or DeliveryType = Enums.DeliveryTypes.Both) And Not IsBlankString(vRow.EMail) Then
			// Call API
			vErrorMessage = "";
			If JobsScheduled.cmSendTextByEMail(cmNStr(TrimAll(pSMSDeliveryObj.SMSTemplate)), TrimR(vRow.SMSText), TrimAll(vRow.EMail), False, vErrorMessage, vSMTPConnection, vLogoff, TrimAll(pSMSDeliveryObj.AttachmentPath), pSMSDeliveryObj.SMSTemplate, vRow.ClientDoc, ?(pSMSDeliveryObj.IsByCustomers, vRow.Customer, vRow.Client)) Then
				vRow.Result = "IsSent";
				vRow.IsSent = True;
				vRow.MessageID = "";
				vRow.Cost = 0;
			Else
				vRow.Result = "UnDeliverable";
				vRow.IsSent = False;
				vRow.MessageID = "";
				vRow.Cost = 0;
				vMessages.Add(vErrorMessage);
			EndIf;
		EndIf;
	EndDo;
	If DeliveryType = Enums.DeliveryTypes.EMail Or DeliveryType = Enums.DeliveryTypes.Both Then
		If vSMTPConnection <> Undefined Then
			vSMTPConnection.Logoff();
		EndIf;
		vSMTPConnection = Undefined;
	EndIf;
	// Write document
	pSMSDeliveryObj.Write(DocumentWriteMode.Write);
EndProcedure // DoMessagesDelivery

// -----------------------------------------------------------------------------
Function DoInHouseGuestsBirthdayCongratulationDelivery(pTemplates)
	vSMSDeliveryArr = New Array;
	
	// Run query to find guests
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref,
	|	Accommodation.Guest,
	|	CASE
	|		WHEN Accommodation.Guest.Phone <> &qEmptyString
	|			THEN Accommodation.Guest.Phone
	|		WHEN Accommodation.Phone <> &qEmptyString
	|			THEN Accommodation.Phone
	|		ELSE &qEmptyString
	|	END AS Phone,
	|	CASE
	|		WHEN Accommodation.Guest.EMail <> &qEmptyString
	|			THEN Accommodation.Guest.EMail
	|		WHEN Accommodation.EMail <> &qEmptyString
	|			THEN Accommodation.EMail
	|		ELSE &qEmptyString
	|	END AS EMail,
	|	Accommodation.Guest.FullName AS GuestFullName
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsInHouse
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.Hotel = &qHotel
	|	AND Accommodation.Guest <> &qEmptyGuest
	|	AND (Accommodation.Guest.Phone <> &qEmptyString
	|				AND NOT &qCheckEMail
	|			OR Accommodation.Phone <> &qEmptyString
	|				AND NOT &qCheckEMail
	|			OR Accommodation.Guest.EMail <> &qEmptyString
	|				AND &qCheckEMail
	|			OR Accommodation.EMail <> &qEmptyString
	|				AND &qCheckEMail)
	|	AND NOT Accommodation.Guest.NoSMSDelivery
	|	AND NOT Accommodation.Guest.DeletionMark
	|	AND Accommodation.Guest.DateOfBirth > &qEmptyDate
	|	AND (YEAR(&qBirthDayPeriodTo) = YEAR(&qBirthDayPeriodFrom)
	|						AND MONTH(Accommodation.Guest.DateOfBirth) * 100 + DAY(Accommodation.Guest.DateOfBirth) >= MONTH(&qBirthDayPeriodFrom) * 100 + DAY(&qBirthDayPeriodFrom)
	|						AND MONTH(Accommodation.Guest.DateOfBirth) * 100 + DAY(Accommodation.Guest.DateOfBirth) <= MONTH(&qBirthDayPeriodTo) * 100 + DAY(&qBirthDayPeriodTo)
	|					OR YEAR(&qBirthDayPeriodTo) <> YEAR(&qBirthDayPeriodFrom)
	|						AND (MONTH(Accommodation.Guest.DateOfBirth) * 100 + DAY(Accommodation.Guest.DateOfBirth) >= MONTH(&qBirthDayPeriodFrom) * 100 + DAY(&qBirthDayPeriodFrom)
	|								AND MONTH(Accommodation.Guest.DateOfBirth) * 100 + DAY(Accommodation.Guest.DateOfBirth) <= 1231
	|							OR MONTH(Accommodation.Guest.DateOfBirth) * 100 + DAY(Accommodation.Guest.DateOfBirth) <= MONTH(&qBirthDayPeriodTo) * 100 + DAY(&qBirthDayPeriodTo)
	|								AND MONTH(Accommodation.Guest.DateOfBirth) * 100 + DAY(Accommodation.Guest.DateOfBirth) >= 101))
	|	" + TrimAll(DeliveryFilter) + "
	|ORDER BY
	|	GuestFullName";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qBirthDayPeriodFrom", AccountingDate);
	vQry.SetParameter("qBirthDayPeriodTo", AccountingDate);
	vQry.SetParameter("qEmptyGuest", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qEmptyString", "");
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qCheckEMail", ?(DeliveryType = Enums.DeliveryTypes.EMail, True, ?(DeliveryType = Enums.DeliveryTypes.Both, True, False)));
	vClients = vQry.Execute().Unload();
	WriteLogEvent(NStr("en='DataProcessor.AutoSMSDelivery.DoInHouseGuestsBirthdayCongratulationDelivery';ru='Обработка.АвтоматизированнаяРассылкаСообщений.DoInHouseGuestsBirthdayCongratulationDelivery';de='DataProcessor.AutoSMSDelivery.DoInHouseGuestsBirthdayCongratulationDelivery'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Guests found: ';ru='Найдено гостей: ';de='Guests found: '") + vClients.Count());

	For Each vTemplate In pTemplates Do	
		vUsedPhones = New ValueList();
		vUsedEMails = New ValueList();
		// Build SMS delivery document
		vSMSDeliveryObject = Documents.SMSDelivery.CreateDocument();
		vSMSDeliveryObject.pmFillAttributesWithDefaultValues();
		vSMSDeliveryObject.Hotel = Hotel;
		vSMSDeliveryObject.Sender = Sender;
		vSMSDeliveryObject.DeliveryType = DeliveryType;
		vSMSDeliveryObject.SMSTemplate = vTemplate;
		FillTemplateTexts(vSMSDeliveryObject);
		
		// Iterate thru clients
		For Each vClientsRow In vClients Do
			vPhone = SMS.GetValidPhoneNumber(vClientsRow.Phone);
			// Check if current phone number or e-mail was already processed
			If (DeliveryType = Enums.DeliveryTypes.EMail Or DeliveryType = Enums.DeliveryTypes.Both) And vUsedEMails.FindByValue(TrimAll(vClientsRow.EMail)) = Undefined Or 
			   (DeliveryType = Enums.DeliveryTypes.SMS Or DeliveryType = Enums.DeliveryTypes.Both) And vUsedPhones.FindByValue(vPhone) = Undefined Then
				vUsedPhones.Add(vPhone);
				vUsedEMails.Add(TrimAll(vClientsRow.EMail));
				// Add new SMS message row
				vRow = vSMSDeliveryObject.Receivers.Add();
				vRow.Phone = vPhone;
				vRow.EMail = TrimAll(vClientsRow.EMail);
				vRow.Customer = Undefined;
				vRow.Client = vClientsRow.Guest;
				vRow.ClientDoc = vClientsRow.Ref;
				vTemplateText = "";
				vTemplateLang = Catalogs.Languages.RU;
				If ValueIsFilled(vRow.Client) Then
					vTemplateLang = vRow.Client.Language;
				EndIf;
				If vTemplateLang = Catalogs.Languages.RU Then
					vTemplateText = vSMSDeliveryObject.TemplateTextRu;
				ElsIf vTemplateLang = Catalogs.Languages.EN Then
					vTemplateText = vSMSDeliveryObject.TemplateTextEn;
				ElsIf vTemplateLang = Catalogs.Languages.DE Then
					vTemplateText = vSMSDeliveryObject.TemplateTextDe;
				Else
					vTemplateText = vSMSDeliveryObject.TemplateTextRu;
				EndIf;
				vRow.SMSText = SMS.ReplaceSMSParameters(vTemplateText, vClientsRow.Ref, vClientsRow.Guest);
				vRow.NumberOfSMS = SMS.GetNumberOfSegments(vRow.SMSText);
				vRow.IsSent = False;
				vRow.Result = "";
				vRow.MessageID = "";
			EndIf;
		EndDo;
		// Send messages
		DoMessagesDelivery(vSMSDeliveryObject);
		If ValueIsFilled(vSMSDeliveryObject.Ref) Then
			vSMSDeliveryArr.Add(vSMSDeliveryObject.Ref);	
		EndIf;
	EndDo;
	// Return messages object
	Return vSMSDeliveryArr;
EndFunction // DoInHouseGuestsBirthdayCongratulationDelivery

// -----------------------------------------------------------------------------
Function DoInHouseGuestsFolioBalanceNotificationDelivery(pTemplates)
	vSMSDeliveryArr = New Array;
	
	// Run query to find guests
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref,
	|	Accommodation.Guest,
	|	CASE
	|		WHEN Accommodation.Guest.Phone <> &qEmptyString
	|			THEN Accommodation.Guest.Phone
	|		WHEN Accommodation.Phone <> &qEmptyString
	|			THEN Accommodation.Phone
	|		ELSE &qEmptyString
	|	END AS Phone,
	|	CASE
	|		WHEN Accommodation.Guest.EMail <> &qEmptyString
	|			THEN Accommodation.Guest.EMail
	|		WHEN Accommodation.EMail <> &qEmptyString
	|			THEN Accommodation.EMail
	|		ELSE &qEmptyString
	|	END AS EMail,
	|	Accommodation.Guest.FullName AS GuestFullName,
	|	ISNULL(FolioBalances.FolioCurrency, &qEmptyCurrency) AS Currency,
	|	SUM(ISNULL(FolioBalances.SumBalance, 0)) - SUM(ISNULL(FolioBalances.LimitBalance, 0)) AS BalanceAmount
	|FROM
	|	Document.Accommodation AS Accommodation
	|		LEFT JOIN AccumulationRegister.Accounts.Balance(
	|				&qEndOfTime,
	|				NOT Folio.IsClosed
	|						AND Folio.Customer = &qEmptyCustomer
	|					OR Folio.Customer <> &qEmptyCustomer
	|						AND Folio.Customer.IsIndividual) AS FolioBalances
	|		ON (FolioBalances.Folio.Client = Accommodation.Guest)
	|WHERE
	|	Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsInHouse
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.Hotel = &qHotel
	|	AND Accommodation.Guest <> &qEmptyGuest
	|	AND (Accommodation.Guest.Phone <> &qEmptyString
	|				AND NOT &qCheckEMail
	|			OR Accommodation.Phone <> &qEmptyString
	|				AND NOT &qCheckEMail
	|			OR Accommodation.Guest.EMail <> &qEmptyString
	|				AND &qCheckEMail
	|			OR Accommodation.EMail <> &qEmptyString
	|				AND &qCheckEMail)
	|	AND NOT Accommodation.Guest.NoSMSDelivery
	|	AND NOT Accommodation.Guest.DeletionMark
	| 	" + TrimAll(DeliveryFilter) + "
	|
	|GROUP BY
	|	Accommodation.Ref,
	|	Accommodation.Guest,
	|	CASE
	|		WHEN Accommodation.Guest.Phone <> &qEmptyString
	|			THEN Accommodation.Guest.Phone
	|		WHEN Accommodation.Phone <> &qEmptyString
	|			THEN Accommodation.Phone
	|		ELSE &qEmptyString
	|	END,
	|	CASE
	|		WHEN Accommodation.Guest.EMail <> &qEmptyString
	|			THEN Accommodation.Guest.EMail
	|		WHEN Accommodation.EMail <> &qEmptyString
	|			THEN Accommodation.EMail
	|		ELSE &qEmptyString
	|	END,
	|	Accommodation.Guest.FullName,
	|	ISNULL(FolioBalances.FolioCurrency, &qEmptyCurrency)
	|
	|ORDER BY
	|	GuestFullName";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qEndOfTime", '39991231235959');
	vQry.SetParameter("qEmptyGuest", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qEmptyCurrency", Catalogs.Currencies.EmptyRef());
	vQry.SetParameter("qEmptyString", "");
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	vQry.SetParameter("qCheckEMail", ?(DeliveryType = Enums.DeliveryTypes.EMail, True, ?(DeliveryType = Enums.DeliveryTypes.Both, True, False)));
	vClients = vQry.Execute().Unload();
	
	For Each vTemplate In pTemplates Do
		vUsedPhones = New ValueList();
		vUsedEMails = New ValueList();
		// Build SMS delivery document
		vSMSDeliveryObject = Documents.SMSDelivery.CreateDocument();
		vSMSDeliveryObject.pmFillAttributesWithDefaultValues();
		vSMSDeliveryObject.Hotel = Hotel;
		vSMSDeliveryObject.Sender = Sender;
		vSMSDeliveryObject.DeliveryType = DeliveryType;
		vSMSDeliveryObject.SMSTemplate = vTemplate;
		FillTemplateTexts(vSMSDeliveryObject);
		
		// Iterate thru clients
		For Each vClientsRow In vClients Do
			vPhone = SMS.GetValidPhoneNumber(vClientsRow.Phone);
			// Check if current phone number or e-mail was already processed
			If (DeliveryType = Enums.DeliveryTypes.EMail Or DeliveryType = Enums.DeliveryTypes.Both) And vUsedEMails.FindByValue(TrimAll(vClientsRow.EMail)) = Undefined Or 
			   (DeliveryType = Enums.DeliveryTypes.SMS Or DeliveryType = Enums.DeliveryTypes.Both) And vUsedPhones.FindByValue(vPhone) = Undefined Then
				vUsedPhones.Add(vPhone);
				vUsedEMails.Add(TrimAll(vClientsRow.EMail));
				// Add new SMS message row
				vRow = vSMSDeliveryObject.Receivers.Add();
				vRow.Phone = vPhone;
				vRow.EMail = TrimAll(vClientsRow.EMail);
				vRow.Customer = Undefined;
				vRow.Client = vClientsRow.Guest;
				vRow.ClientDoc = vClientsRow.Ref;
				vTemplateText = "";
				vTemplateLang = Catalogs.Languages.RU;
				If ValueIsFilled(vRow.Client) Then
					vTemplateLang = vRow.Client.Language;
				EndIf;
				If vTemplateLang = Catalogs.Languages.RU Then
					vTemplateText = vSMSDeliveryObject.TemplateTextRu;
				ElsIf vTemplateLang = Catalogs.Languages.EN Then
					vTemplateText = vSMSDeliveryObject.TemplateTextEn;
				ElsIf vTemplateLang = Catalogs.Languages.DE Then
					vTemplateText = vSMSDeliveryObject.TemplateTextDe;
				Else
					vTemplateText = vSMSDeliveryObject.TemplateTextRu;
				EndIf;
				vRow.SMSText = SMS.ReplaceSMSParameters(vTemplateText, vClientsRow.Ref, vClientsRow.Guest);
				vRow.NumberOfSMS = SMS.GetNumberOfSegments(vRow.SMSText);
				vRow.IsSent = False;
				vRow.Result = "";
				vRow.MessageID = "";
			EndIf;
		EndDo;
		// Send messages
		DoMessagesDelivery(vSMSDeliveryObject);
		If ValueIsFilled(vSMSDeliveryObject.Ref) Then
			vSMSDeliveryArr.Add(vSMSDeliveryObject.Ref);	
		EndIf;
	EndDo;
	// Return messages object
	Return vSMSDeliveryArr;
EndFunction // DoInHouseGuestsFolioBalanceNotificationDelivery

// -----------------------------------------------------------------------------
Function DoExpectedCheckOutGuestsFolioBalanceNotificationDelivery(pTemplates)
	vSMSDeliveryArr = New Array;
	
	// Run query to find guests
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref,
	|	Accommodation.Guest,
	|	CASE
	|		WHEN Accommodation.Guest.Phone <> &qEmptyString
	|			THEN Accommodation.Guest.Phone
	|		WHEN Accommodation.Phone <> &qEmptyString
	|			THEN Accommodation.Phone
	|		ELSE &qEmptyString
	|	END AS Phone,
	|	CASE
	|		WHEN Accommodation.Guest.EMail <> &qEmptyString
	|			THEN Accommodation.Guest.EMail
	|		WHEN Accommodation.EMail <> &qEmptyString
	|			THEN Accommodation.EMail
	|		ELSE &qEmptyString
	|	END AS EMail,
	|	Accommodation.Guest.FullName AS GuestFullName,
	|	ISNULL(FolioBalances.FolioCurrency, &qEmptyCurrency) AS Currency,
	|	SUM(ISNULL(FolioBalances.SumBalance, 0)) - SUM(ISNULL(FolioBalances.LimitBalance, 0)) AS BalanceAmount
	|FROM
	|	Document.Accommodation AS Accommodation
	|		LEFT JOIN AccumulationRegister.Accounts.Balance(
	|				&qEndOfTime,
	|				NOT Folio.IsClosed
	|						AND Folio.Customer = &qEmptyCustomer
	|					OR Folio.Customer <> &qEmptyCustomer
	|						AND Folio.Customer.IsIndividual) AS FolioBalances
	|		ON (FolioBalances.Folio.Client = Accommodation.Guest)
	|WHERE
	|	Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsInHouse
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.AccommodationStatus.IsCheckOut
	|	AND Accommodation.Hotel = &qHotel
	|	AND Accommodation.Guest <> &qEmptyGuest
	|	AND (Accommodation.Guest.Phone <> &qEmptyString
	|				AND NOT &qCheckEMail
	|			OR Accommodation.Phone <> &qEmptyString
	|				AND NOT &qCheckEMail
	|			OR Accommodation.Guest.EMail <> &qEmptyString
	|				AND &qCheckEMail
	|			OR Accommodation.EMail <> &qEmptyString
	|				AND &qCheckEMail)
	|	AND NOT Accommodation.Guest.NoSMSDelivery
	|	AND NOT Accommodation.Guest.DeletionMark
	|	AND Accommodation.CheckOutDate >= &qPeriodFrom
	|	AND Accommodation.CheckOutDate <= &qPeriodTo
	| 	" + TrimAll(DeliveryFilter) + "
	|
	|GROUP BY
	|	Accommodation.Ref,
	|	Accommodation.Guest,
	|	CASE
	|		WHEN Accommodation.Guest.Phone <> &qEmptyString
	|			THEN Accommodation.Guest.Phone
	|		WHEN Accommodation.Phone <> &qEmptyString
	|			THEN Accommodation.Phone
	|		ELSE &qEmptyString
	|	END,
	|	CASE
	|		WHEN Accommodation.Guest.EMail <> &qEmptyString
	|			THEN Accommodation.Guest.EMail
	|		WHEN Accommodation.EMail <> &qEmptyString
	|			THEN Accommodation.EMail
	|		ELSE &qEmptyString
	|	END,
	|	Accommodation.Guest.FullName,
	|	ISNULL(FolioBalances.FolioCurrency, &qEmptyCurrency)
	|
	|ORDER BY
	|	GuestFullName";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qPeriodFrom", BegOfDay(AccountingDate));
	vQry.SetParameter("qPeriodTo", EndOfDay(AccountingDate));
	vQry.SetParameter("qEndOfTime", '39991231235959');
	vQry.SetParameter("qEmptyGuest", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qEmptyCurrency", Catalogs.Currencies.EmptyRef());
	vQry.SetParameter("qEmptyString", "");
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	vQry.SetParameter("qCheckEMail", ?(DeliveryType = Enums.DeliveryTypes.EMail, True, ?(DeliveryType = Enums.DeliveryTypes.Both, True, False)));
	vClients = vQry.Execute().Unload();
	
	For Each vTemplate In pTemplates Do
		vUsedPhones = New ValueList();
		vUsedEMails = New ValueList();
		// Build SMS delivery document
		vSMSDeliveryObject = Documents.SMSDelivery.CreateDocument();
		vSMSDeliveryObject.pmFillAttributesWithDefaultValues();
		vSMSDeliveryObject.Hotel = Hotel;
		vSMSDeliveryObject.Sender = Sender;
		vSMSDeliveryObject.DeliveryType = DeliveryType;
		vSMSDeliveryObject.SMSTemplate = vTemplate;
		FillTemplateTexts(vSMSDeliveryObject);
		
		// Iterate thru clients
		For Each vClientsRow In vClients Do
			vPhone = SMS.GetValidPhoneNumber(vClientsRow.Phone);
			// Check if current phone number or e-mail was already processed
			If (DeliveryType = Enums.DeliveryTypes.EMail Or DeliveryType = Enums.DeliveryTypes.Both) And vUsedEMails.FindByValue(TrimAll(vClientsRow.EMail)) = Undefined Or 
			   (DeliveryType = Enums.DeliveryTypes.SMS Or DeliveryType = Enums.DeliveryTypes.Both) And vUsedPhones.FindByValue(vPhone) = Undefined Then
				vUsedPhones.Add(vPhone);
				vUsedEMails.Add(TrimAll(vClientsRow.EMail));
				// Add new SMS message row
				vRow = vSMSDeliveryObject.Receivers.Add();
				vRow.Phone = vPhone;
				vRow.EMail = TrimAll(vClientsRow.EMail);
				vRow.Customer = Undefined;
				vRow.Client = vClientsRow.Guest;
				vRow.ClientDoc = vClientsRow.Ref;
				vTemplateText = "";
				vTemplateLang = Catalogs.Languages.RU;
				If ValueIsFilled(vRow.Client) Then
					vTemplateLang = vRow.Client.Language;
				EndIf;
				If vTemplateLang = Catalogs.Languages.RU Then
					vTemplateText = vSMSDeliveryObject.TemplateTextRu;
				ElsIf vTemplateLang = Catalogs.Languages.EN Then
					vTemplateText = vSMSDeliveryObject.TemplateTextEn;
				ElsIf vTemplateLang = Catalogs.Languages.DE Then
					vTemplateText = vSMSDeliveryObject.TemplateTextDe;
				Else
					vTemplateText = vSMSDeliveryObject.TemplateTextRu;
				EndIf;
				vRow.SMSText = SMS.ReplaceSMSParameters(vTemplateText, vClientsRow.Ref, vClientsRow.Guest);
				vRow.NumberOfSMS = SMS.GetNumberOfSegments(vRow.SMSText);
				vRow.IsSent = False;
				vRow.Result = "";
				vRow.MessageID = "";
			EndIf;
		EndDo;
		// Send messages
		DoMessagesDelivery(vSMSDeliveryObject); 
		If ValueIsFilled(vSMSDeliveryObject.Ref) Then
			vSMSDeliveryArr.Add(vSMSDeliveryObject.Ref);	
		EndIf;
	EndDo;
	// Return messages object
	Return vSMSDeliveryArr;
EndFunction // DoExpectedCheckOutGuestsFolioBalanceNotificationDelivery

// -----------------------------------------------------------------------------
Function DoExpectedCheckInGuestsNotificationDelivery(pTemplates)
	vSMSDeliveryArr = New Array;
	
	// Run query to find guests
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservation.Ref,
	|	Reservation.Guest,
	|	CASE
	|		WHEN Reservation.Guest.Phone <> &qEmptyString
	|			THEN Reservation.Guest.Phone
	|		WHEN Reservation.Phone <> &qEmptyString
	|			THEN Reservation.Phone
	|		ELSE &qEmptyString
	|	END AS Phone,
	|	CASE
	|		WHEN Reservation.Guest.EMail <> &qEmptyString
	|			THEN Reservation.Guest.EMail
	|		WHEN Reservation.EMail <> &qEmptyString
	|			THEN Reservation.EMail
	|		ELSE &qEmptyString
	|	END AS EMail,
	|	Reservation.Guest.FullName AS GuestFullName
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.Posted
	|	AND NOT Reservation.ReservationStatus.IsPreliminary
	|	AND NOT Reservation.ReservationStatus.IsInWaitingList
	|	AND Reservation.ReservationStatus.IsActive
	|	AND NOT Reservation.ReservationStatus.IsCheckIn
	|	AND Reservation.Hotel = &qHotel
	|	AND Reservation.Guest <> &qEmptyGuest
	|	AND (Reservation.Guest.Phone <> &qEmptyString
	|				AND NOT &qCheckEMail
	|			OR Reservation.Phone <> &qEmptyString
	|				AND NOT &qCheckEMail
	|			OR Reservation.Guest.EMail <> &qEmptyString
	|				AND &qCheckEMail
	|			OR Reservation.EMail <> &qEmptyString
	|				AND &qCheckEMail)
	|	AND NOT Reservation.Guest.NoSMSDelivery
	|	AND NOT Reservation.Guest.DeletionMark
	|	AND Reservation.CheckInDate >= &qPeriodFrom
	|	AND Reservation.CheckInDate <= &qPeriodTo
	| 	" + TrimAll(DeliveryFilter) + "
	|
	|GROUP BY
	|	Reservation.Ref,
	|	Reservation.Guest,
	|	CASE
	|		WHEN Reservation.Guest.Phone <> &qEmptyString
	|			THEN Reservation.Guest.Phone
	|		WHEN Reservation.Phone <> &qEmptyString
	|			THEN Reservation.Phone
	|		ELSE &qEmptyString
	|	END,
	|	CASE
	|		WHEN Reservation.Guest.EMail <> &qEmptyString
	|			THEN Reservation.Guest.EMail
	|		WHEN Reservation.EMail <> &qEmptyString
	|			THEN Reservation.EMail
	|		ELSE &qEmptyString
	|	END,
	|	Reservation.Guest.FullName
	|
	|ORDER BY
	|	GuestFullName";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qPeriodFrom", BegOfDay(AccountingDate));
	vQry.SetParameter("qPeriodTo", EndOfDay(AccountingDate));
	vQry.SetParameter("qEmptyGuest", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qEmptyCurrency", Catalogs.Currencies.EmptyRef());
	vQry.SetParameter("qEmptyString", "");
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	vQry.SetParameter("qCheckEMail", ?(DeliveryType = Enums.DeliveryTypes.EMail, True, ?(DeliveryType = Enums.DeliveryTypes.Both, True, False)));
	vClients = vQry.Execute().Unload();
	
	For Each vTemplate In pTemplates Do
		vUsedPhones = New ValueList();
		vUsedEMails = New ValueList();
		// Build SMS delivery document
		vSMSDeliveryObject = Documents.SMSDelivery.CreateDocument();
		vSMSDeliveryObject.pmFillAttributesWithDefaultValues();
		vSMSDeliveryObject.Hotel = Hotel;
		vSMSDeliveryObject.Sender = Sender;
		vSMSDeliveryObject.DeliveryType = DeliveryType;
		vSMSDeliveryObject.SMSTemplate = vTemplate;
		FillTemplateTexts(vSMSDeliveryObject);
		
		// Iterate thru clients
		For Each vClientsRow In vClients Do
			vPhone = SMS.GetValidPhoneNumber(vClientsRow.Phone);
			// Check if current phone number or e-mail was already processed
			If (DeliveryType = Enums.DeliveryTypes.EMail Or DeliveryType = Enums.DeliveryTypes.Both) And vUsedEMails.FindByValue(TrimAll(vClientsRow.EMail)) = Undefined Or 
			   (DeliveryType = Enums.DeliveryTypes.SMS Or DeliveryType = Enums.DeliveryTypes.Both) And vUsedPhones.FindByValue(vPhone) = Undefined Then
				vUsedPhones.Add(vPhone);
				vUsedEMails.Add(TrimAll(vClientsRow.EMail));
				// Add new SMS message row
				vRow = vSMSDeliveryObject.Receivers.Add();
				vRow.Phone = vPhone;
				vRow.EMail = TrimAll(vClientsRow.EMail);
				vRow.Customer = Undefined;
				vRow.Client = vClientsRow.Guest;
				vRow.ClientDoc = vClientsRow.Ref;
				vTemplateText = "";
				vTemplateLang = Catalogs.Languages.RU;
				If ValueIsFilled(vRow.Client) Then
					vTemplateLang = vRow.Client.Language;
				EndIf;
				If vTemplateLang = Catalogs.Languages.RU Then
					vTemplateText = vSMSDeliveryObject.TemplateTextRu;
				ElsIf vTemplateLang = Catalogs.Languages.EN Then
					vTemplateText = vSMSDeliveryObject.TemplateTextEn;
				ElsIf vTemplateLang = Catalogs.Languages.DE Then
					vTemplateText = vSMSDeliveryObject.TemplateTextDe;
				Else
					vTemplateText = vSMSDeliveryObject.TemplateTextRu;
				EndIf;
				vRow.SMSText = SMS.ReplaceSMSParameters(vTemplateText, vClientsRow.Ref, vClientsRow.Guest);
				vRow.NumberOfSMS = SMS.GetNumberOfSegments(vRow.SMSText);
				vRow.IsSent = False;
				vRow.Result = "";
				vRow.MessageID = "";
			EndIf;
		EndDo;
		// Send messages
		DoMessagesDelivery(vSMSDeliveryObject);
		If ValueIsFilled(vSMSDeliveryObject.Ref) Then
			vSMSDeliveryArr.Add(vSMSDeliveryObject.Ref);	
		EndIf;
	EndDo;
	// Return messages object
	Return vSMSDeliveryArr;
EndFunction // DoExpectedCheckInGuestsNotificationDelivery

// -----------------------------------------------------------------------------
Function DoCheckedInGuestsNotificationDelivery(pTemplates)
	vSMSDeliveryArr = New Array;
	
	// Run query to find guests
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref,
	|	Accommodation.Guest,
	|	CASE
	|		WHEN Accommodation.Guest.Phone <> &qEmptyString
	|			THEN Accommodation.Guest.Phone
	|		WHEN Accommodation.Phone <> &qEmptyString
	|			THEN Accommodation.Phone
	|		ELSE &qEmptyString
	|	END AS Phone,
	|	CASE
	|		WHEN Accommodation.Guest.EMail <> &qEmptyString
	|			THEN Accommodation.Guest.EMail
	|		WHEN Accommodation.EMail <> &qEmptyString
	|			THEN Accommodation.EMail
	|		ELSE &qEmptyString
	|	END AS EMail,
	|	Accommodation.Guest.FullName AS GuestFullName
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsInHouse
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.AccommodationStatus.IsCheckIn
	|	AND Accommodation.Hotel = &qHotel
	|	AND Accommodation.Guest <> &qEmptyGuest
	|	AND (Accommodation.Guest.Phone <> &qEmptyString
	|				AND NOT &qCheckEMail
	|			OR Accommodation.Phone <> &qEmptyString
	|				AND NOT &qCheckEMail
	|			OR Accommodation.Guest.EMail <> &qEmptyString
	|				AND &qCheckEMail
	|			OR Accommodation.EMail <> &qEmptyString
	|				AND &qCheckEMail)
	|	AND NOT Accommodation.Guest.NoSMSDelivery
	|	AND NOT Accommodation.Guest.DeletionMark
	|	AND Accommodation.CheckInDate >= &qPeriodFrom
	|	AND Accommodation.CheckInDate <= &qPeriodTo
	| 	" + TrimAll(DeliveryFilter) + "
	|
	|GROUP BY
	|	Accommodation.Ref,
	|	Accommodation.Guest,
	|	CASE
	|		WHEN Accommodation.Guest.Phone <> &qEmptyString
	|			THEN Accommodation.Guest.Phone
	|		WHEN Accommodation.Phone <> &qEmptyString
	|			THEN Accommodation.Phone
	|		ELSE &qEmptyString
	|	END,
	|	CASE
	|		WHEN Accommodation.Guest.EMail <> &qEmptyString
	|			THEN Accommodation.Guest.EMail
	|		WHEN Accommodation.EMail <> &qEmptyString
	|			THEN Accommodation.EMail
	|		ELSE &qEmptyString
	|	END,
	|	Accommodation.Guest.FullName
	|
	|ORDER BY
	|	GuestFullName";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qPeriodFrom", BegOfDay(AccountingDate));
	vQry.SetParameter("qPeriodTo", EndOfDay(AccountingDate));
	vQry.SetParameter("qEmptyGuest", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qEmptyCurrency", Catalogs.Currencies.EmptyRef());
	vQry.SetParameter("qEmptyString", "");
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	vQry.SetParameter("qCheckEMail", ?(DeliveryType = Enums.DeliveryTypes.EMail, True, ?(DeliveryType = Enums.DeliveryTypes.Both, True, False)));
	vClients = vQry.Execute().Unload();
	
	For Each vTemplate In pTemplates Do
		vUsedPhones = New ValueList();
		vUsedEMails = New ValueList();
		// Build SMS delivery document
		vSMSDeliveryObject = Documents.SMSDelivery.CreateDocument();
		vSMSDeliveryObject.pmFillAttributesWithDefaultValues();
		vSMSDeliveryObject.Hotel = Hotel;
		vSMSDeliveryObject.Sender = Sender;
		vSMSDeliveryObject.DeliveryType = DeliveryType;
		vSMSDeliveryObject.SMSTemplate = vTemplate;
		FillTemplateTexts(vSMSDeliveryObject);
		
		// Iterate thru clients
		For Each vClientsRow In vClients Do
			vPhone = SMS.GetValidPhoneNumber(vClientsRow.Phone);
			// Check if current phone number or e-mail was already processed
			If (DeliveryType = Enums.DeliveryTypes.EMail Or DeliveryType = Enums.DeliveryTypes.Both) And vUsedEMails.FindByValue(TrimAll(vClientsRow.EMail)) = Undefined Or 
			   (DeliveryType = Enums.DeliveryTypes.SMS Or DeliveryType = Enums.DeliveryTypes.Both) And vUsedPhones.FindByValue(vPhone) = Undefined Then
				vUsedPhones.Add(vPhone);
				vUsedEMails.Add(TrimAll(vClientsRow.EMail));
				// Add new SMS message row
				vRow = vSMSDeliveryObject.Receivers.Add();
				vRow.Phone = vPhone;
				vRow.EMail = TrimAll(vClientsRow.EMail);
				vRow.Customer = Undefined;
				vRow.Client = vClientsRow.Guest;
				vRow.ClientDoc = vClientsRow.Ref;
				vTemplateText = "";
				vTemplateLang = Catalogs.Languages.RU;
				If ValueIsFilled(vRow.Client) Then
					vTemplateLang = vRow.Client.Language;
				EndIf;
				If vTemplateLang = Catalogs.Languages.RU Then
					vTemplateText = vSMSDeliveryObject.TemplateTextRu;
				ElsIf vTemplateLang = Catalogs.Languages.EN Then
					vTemplateText = vSMSDeliveryObject.TemplateTextEn;
				ElsIf vTemplateLang = Catalogs.Languages.DE Then
					vTemplateText = vSMSDeliveryObject.TemplateTextDe;
				Else
					vTemplateText = vSMSDeliveryObject.TemplateTextRu;
				EndIf;
				vRow.SMSText = SMS.ReplaceSMSParameters(vTemplateText, vClientsRow.Ref, vClientsRow.Guest);
				vRow.NumberOfSMS = SMS.GetNumberOfSegments(vRow.SMSText);
				vRow.IsSent = False;
				vRow.Result = "";
				vRow.MessageID = "";
			EndIf;
		EndDo;
		// Send messages
		DoMessagesDelivery(vSMSDeliveryObject);
		If ValueIsFilled(vSMSDeliveryObject.Ref) Then
			vSMSDeliveryArr.Add(vSMSDeliveryObject.Ref);	
		EndIf;
	EndDo;
	// Return messages object
	Return vSMSDeliveryArr;
EndFunction // DoCheckedInGuestsNotificationDelivery

// -----------------------------------------------------------------------------
Function DoInHouseGuestsNotificationDelivery(pTemplates)
	vSMSDeliveryArr = New Array;
	
	// Run query to find guests
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref,
	|	Accommodation.Guest,
	|	CASE
	|		WHEN Accommodation.Guest.Phone <> &qEmptyString
	|			THEN Accommodation.Guest.Phone
	|		WHEN Accommodation.Phone <> &qEmptyString
	|			THEN Accommodation.Phone
	|		ELSE &qEmptyString
	|	END AS Phone,
	|	CASE
	|		WHEN Accommodation.Guest.EMail <> &qEmptyString
	|			THEN Accommodation.Guest.EMail
	|		WHEN Accommodation.EMail <> &qEmptyString
	|			THEN Accommodation.EMail
	|		ELSE &qEmptyString
	|	END AS EMail,
	|	Accommodation.Guest.FullName AS GuestFullName
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsInHouse
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.Hotel = &qHotel
	|	AND Accommodation.Guest <> &qEmptyGuest
	|	AND (Accommodation.Guest.Phone <> &qEmptyString
	|				AND NOT &qCheckEMail
	|			OR Accommodation.Phone <> &qEmptyString
	|				AND NOT &qCheckEMail
	|			OR Accommodation.Guest.EMail <> &qEmptyString
	|				AND &qCheckEMail
	|			OR Accommodation.EMail <> &qEmptyString
	|				AND &qCheckEMail)
	|	AND NOT Accommodation.Guest.NoSMSDelivery
	|	AND NOT Accommodation.Guest.DeletionMark
	| 	" + TrimAll(DeliveryFilter) + "
	|
	|GROUP BY
	|	Accommodation.Ref,
	|	Accommodation.Guest,
	|	CASE
	|		WHEN Accommodation.Guest.Phone <> &qEmptyString
	|			THEN Accommodation.Guest.Phone
	|		WHEN Accommodation.Phone <> &qEmptyString
	|			THEN Accommodation.Phone
	|		ELSE &qEmptyString
	|	END,
	|	CASE
	|		WHEN Accommodation.Guest.EMail <> &qEmptyString
	|			THEN Accommodation.Guest.EMail
	|		WHEN Accommodation.EMail <> &qEmptyString
	|			THEN Accommodation.EMail
	|		ELSE &qEmptyString
	|	END,
	|	Accommodation.Guest.FullName
	|
	|ORDER BY
	|	GuestFullName";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qEmptyGuest", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qEmptyCurrency", Catalogs.Currencies.EmptyRef());
	vQry.SetParameter("qEmptyString", "");
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	vQry.SetParameter("qCheckEMail", ?(DeliveryType = Enums.DeliveryTypes.EMail, True, ?(DeliveryType = Enums.DeliveryTypes.Both, True, False)));
	vClients = vQry.Execute().Unload();

	For Each vTemplate In pTemplates Do
		vUsedPhones = New ValueList();
		vUsedEMails = New ValueList();
		// Build SMS delivery document
		vSMSDeliveryObject = Documents.SMSDelivery.CreateDocument();
		vSMSDeliveryObject.pmFillAttributesWithDefaultValues();
		vSMSDeliveryObject.Hotel = Hotel;
		vSMSDeliveryObject.Sender = Sender;
		vSMSDeliveryObject.DeliveryType = DeliveryType;
		vSMSDeliveryObject.SMSTemplate = vTemplate;
		FillTemplateTexts(vSMSDeliveryObject);
		
		// Iterate thru clients
		For Each vClientsRow In vClients Do
			vPhone = SMS.GetValidPhoneNumber(vClientsRow.Phone);
			// Check if current phone number or e-mail was already processed
			If (DeliveryType = Enums.DeliveryTypes.EMail Or DeliveryType = Enums.DeliveryTypes.Both) And vUsedEMails.FindByValue(TrimAll(vClientsRow.EMail)) = Undefined Or 
			   (DeliveryType = Enums.DeliveryTypes.SMS Or DeliveryType = Enums.DeliveryTypes.Both) And vUsedPhones.FindByValue(vPhone) = Undefined Then
				vUsedPhones.Add(vPhone);
				vUsedEMails.Add(TrimAll(vClientsRow.EMail));
				// Add new SMS message row
				vRow = vSMSDeliveryObject.Receivers.Add();
				vRow.Phone = vPhone;
				vRow.EMail = TrimAll(vClientsRow.EMail);
				vRow.Customer = Undefined;
				vRow.Client = vClientsRow.Guest;
				vRow.ClientDoc = vClientsRow.Ref;
				vTemplateText = "";
				vTemplateLang = Catalogs.Languages.RU;
				If ValueIsFilled(vRow.Client) Then
					vTemplateLang = vRow.Client.Language;
				EndIf;
				If vTemplateLang = Catalogs.Languages.RU Then
					vTemplateText = vSMSDeliveryObject.TemplateTextRu;
				ElsIf vTemplateLang = Catalogs.Languages.EN Then
					vTemplateText = vSMSDeliveryObject.TemplateTextEn;
				ElsIf vTemplateLang = Catalogs.Languages.DE Then
					vTemplateText = vSMSDeliveryObject.TemplateTextDe;
				Else
					vTemplateText = vSMSDeliveryObject.TemplateTextRu;
				EndIf;
				vRow.SMSText = SMS.ReplaceSMSParameters(vTemplateText, vClientsRow.Ref, vClientsRow.Guest);
				vRow.NumberOfSMS = SMS.GetNumberOfSegments(vRow.SMSText);
				vRow.IsSent = False;
				vRow.Result = "";
				vRow.MessageID = "";
			EndIf;
		EndDo;
		// Send messages
		DoMessagesDelivery(vSMSDeliveryObject);
		If ValueIsFilled(vSMSDeliveryObject.Ref) Then
			vSMSDeliveryArr.Add(vSMSDeliveryObject.Ref);	
		EndIf;
	EndDo;
	// Return messages object
	Return vSMSDeliveryArr;
EndFunction // DoInHouseGuestsNotificationDelivery

// -----------------------------------------------------------------------------
Function DoExpectedCheckOutGuestsNotificationDelivery(pTemplates)
	vSMSDeliveryArr = New Array;
	
	// Run query to find guests
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref,
	|	Accommodation.Guest,
	|	CASE
	|		WHEN Accommodation.Guest.Phone <> &qEmptyString
	|			THEN Accommodation.Guest.Phone
	|		WHEN Accommodation.Phone <> &qEmptyString
	|			THEN Accommodation.Phone
	|		ELSE &qEmptyString
	|	END AS Phone,
	|	CASE
	|		WHEN Accommodation.Guest.EMail <> &qEmptyString
	|			THEN Accommodation.Guest.EMail
	|		WHEN Accommodation.EMail <> &qEmptyString
	|			THEN Accommodation.EMail
	|		ELSE &qEmptyString
	|	END AS EMail,
	|	Accommodation.Guest.FullName AS GuestFullName
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsInHouse
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.AccommodationStatus.IsCheckOut
	|	AND Accommodation.Hotel = &qHotel
	|	AND Accommodation.Guest <> &qEmptyGuest
	|	AND (Accommodation.Guest.Phone <> &qEmptyString
	|				AND NOT &qCheckEMail
	|			OR Accommodation.Phone <> &qEmptyString
	|				AND NOT &qCheckEMail
	|			OR Accommodation.Guest.EMail <> &qEmptyString
	|				AND &qCheckEMail
	|			OR Accommodation.EMail <> &qEmptyString
	|				AND &qCheckEMail)
	|	AND NOT Accommodation.Guest.NoSMSDelivery
	|	AND NOT Accommodation.Guest.DeletionMark
	|	AND Accommodation.CheckOutDate >= &qPeriodFrom
	|	AND Accommodation.CheckOutDate <= &qPeriodTo
	| 	" + TrimAll(DeliveryFilter) + "
	|
	|GROUP BY
	|	Accommodation.Ref,
	|	Accommodation.Guest,
	|	CASE
	|		WHEN Accommodation.Guest.Phone <> &qEmptyString
	|			THEN Accommodation.Guest.Phone
	|		WHEN Accommodation.Phone <> &qEmptyString
	|			THEN Accommodation.Phone
	|		ELSE &qEmptyString
	|	END,
	|	CASE
	|		WHEN Accommodation.Guest.EMail <> &qEmptyString
	|			THEN Accommodation.Guest.EMail
	|		WHEN Accommodation.EMail <> &qEmptyString
	|			THEN Accommodation.EMail
	|		ELSE &qEmptyString
	|	END,
	|	Accommodation.Guest.FullName
	|
	|ORDER BY
	|	GuestFullName";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qPeriodFrom", BegOfDay(AccountingDate));
	vQry.SetParameter("qPeriodTo", EndOfDay(AccountingDate));
	vQry.SetParameter("qEmptyGuest", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qEmptyCurrency", Catalogs.Currencies.EmptyRef());
	vQry.SetParameter("qEmptyString", "");
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	vQry.SetParameter("qCheckEMail", ?(DeliveryType = Enums.DeliveryTypes.EMail, True, ?(DeliveryType = Enums.DeliveryTypes.Both, True, False)));
	vClients = vQry.Execute().Unload();
	
	For Each vTemplate In pTemplates Do
		vUsedPhones = New ValueList();
		vUsedEMails = New ValueList();
		// Build SMS delivery document
		vSMSDeliveryObject = Documents.SMSDelivery.CreateDocument();
		vSMSDeliveryObject.pmFillAttributesWithDefaultValues();
		vSMSDeliveryObject.Hotel = Hotel;
		vSMSDeliveryObject.Sender = Sender;
		vSMSDeliveryObject.DeliveryType = DeliveryType;
		vSMSDeliveryObject.SMSTemplate = vTemplate;
		FillTemplateTexts(vSMSDeliveryObject);
		
		// Iterate thru clients
		For Each vClientsRow In vClients Do
			vPhone = SMS.GetValidPhoneNumber(vClientsRow.Phone);
			// Check if current phone number or e-mail was already processed
			If (DeliveryType = Enums.DeliveryTypes.EMail Or DeliveryType = Enums.DeliveryTypes.Both) And vUsedEMails.FindByValue(TrimAll(vClientsRow.EMail)) = Undefined Or 
			   (DeliveryType = Enums.DeliveryTypes.SMS Or DeliveryType = Enums.DeliveryTypes.Both) And vUsedPhones.FindByValue(vPhone) = Undefined Then
				vUsedPhones.Add(vPhone);
				vUsedEMails.Add(TrimAll(vClientsRow.EMail));
				// Add new SMS message row
				vRow = vSMSDeliveryObject.Receivers.Add();
				vRow.Phone = vPhone;
				vRow.EMail = TrimAll(vClientsRow.EMail);
				vRow.Customer = Undefined;
				vRow.Client = vClientsRow.Guest;
				vRow.ClientDoc = vClientsRow.Ref;
				vTemplateText = "";
				vTemplateLang = Catalogs.Languages.RU;
				If ValueIsFilled(vRow.Client) Then
					vTemplateLang = vRow.Client.Language;
				EndIf;
				If vTemplateLang = Catalogs.Languages.RU Then
					vTemplateText = vSMSDeliveryObject.TemplateTextRu;
				ElsIf vTemplateLang = Catalogs.Languages.EN Then
					vTemplateText = vSMSDeliveryObject.TemplateTextEn;
				ElsIf vTemplateLang = Catalogs.Languages.DE Then
					vTemplateText = vSMSDeliveryObject.TemplateTextDe;
				Else
					vTemplateText = vSMSDeliveryObject.TemplateTextRu;
				EndIf;
				vRow.SMSText = SMS.ReplaceSMSParameters(vTemplateText, vClientsRow.Ref, vClientsRow.Guest);
				vRow.NumberOfSMS = SMS.GetNumberOfSegments(vRow.SMSText);
				vRow.IsSent = False;
				vRow.Result = "";
				vRow.MessageID = "";
			EndIf;
		EndDo;
		// Send messages
		DoMessagesDelivery(vSMSDeliveryObject);
		If ValueIsFilled(vSMSDeliveryObject.Ref) Then
			vSMSDeliveryArr.Add(vSMSDeliveryObject.Ref);	
		EndIf;
	EndDo;
	// Return messages object
	Return vSMSDeliveryArr;
EndFunction // DoExpectedCheckOutGuestsNotificationDelivery

// -----------------------------------------------------------------------------
Function DoCheckedOutGuestsNotificationDelivery(pTemplates)
	vSMSDeliveryArr = New Array;
	
	// Report parameters
	WriteLogEvent(NStr("en='DataProcessor.AutoSMSDelivery.DoCheckedOutGuestsNotificationDelivery';ru='Обработка.АвтоматизированнаяРассылкаСообщений.DoCheckedOutGuestsNotificationDelivery';de='DataProcessor.AutoSMSDelivery.DoCheckedOutGuestsNotificationDelivery'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Hotel: ';ru='Гостиница: ';de='Hotel: '") + TrimAll(Hotel) + NStr("en=', date: ';ru=', дата: ';de=', Datum: '") + AccountingDate + NStr("en=', delivery type: ';ru=', тип доставки: ';de=', delivery type: '") + TrimAll(DeliveryType));
	// Run query to find guests
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref,
	|	Accommodation.Guest,
	|	CASE
	|		WHEN Accommodation.Guest.Phone <> &qEmptyString
	|			THEN Accommodation.Guest.Phone
	|		WHEN Accommodation.Phone <> &qEmptyString
	|			THEN Accommodation.Phone
	|		ELSE &qEmptyString
	|	END AS Phone,
	|	CASE
	|		WHEN Accommodation.Guest.EMail <> &qEmptyString
	|			THEN Accommodation.Guest.EMail
	|		WHEN Accommodation.EMail <> &qEmptyString
	|			THEN Accommodation.EMail
	|		ELSE &qEmptyString
	|	END AS EMail,
	|	Accommodation.Guest.FullName AS GuestFullName
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Posted
	|	AND NOT Accommodation.AccommodationStatus.IsInHouse
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.AccommodationStatus.IsCheckOut
	|	AND Accommodation.Hotel = &qHotel
	|	AND Accommodation.Guest <> &qEmptyGuest
	|	AND (Accommodation.Guest.Phone <> &qEmptyString
	|				AND NOT &qCheckEMail
	|			OR Accommodation.Phone <> &qEmptyString
	|				AND NOT &qCheckEMail
	|			OR Accommodation.Guest.EMail <> &qEmptyString
	|				AND &qCheckEMail
	|			OR Accommodation.EMail <> &qEmptyString
	|				AND &qCheckEMail)
	|	AND NOT Accommodation.Guest.NoSMSDelivery
	|	AND NOT Accommodation.Guest.DeletionMark
	|	AND Accommodation.CheckOutDate >= &qPeriodFrom
	|	AND Accommodation.CheckOutDate <= &qPeriodTo
	| 	" + TrimAll(DeliveryFilter) + "
	|
	|GROUP BY
	|	Accommodation.Ref,
	|	Accommodation.Guest,
	|	CASE
	|		WHEN Accommodation.Guest.Phone <> &qEmptyString
	|			THEN Accommodation.Guest.Phone
	|		WHEN Accommodation.Phone <> &qEmptyString
	|			THEN Accommodation.Phone
	|		ELSE &qEmptyString
	|	END,
	|	CASE
	|		WHEN Accommodation.Guest.EMail <> &qEmptyString
	|			THEN Accommodation.Guest.EMail
	|		WHEN Accommodation.EMail <> &qEmptyString
	|			THEN Accommodation.EMail
	|		ELSE &qEmptyString
	|	END,
	|	Accommodation.Guest.FullName
	|
	|ORDER BY
	|	GuestFullName";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qPeriodFrom", BegOfDay(AccountingDate));
	vQry.SetParameter("qPeriodTo", EndOfDay(AccountingDate));
	vQry.SetParameter("qEmptyGuest", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qEmptyCurrency", Catalogs.Currencies.EmptyRef());
	vQry.SetParameter("qEmptyString", "");
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	vQry.SetParameter("qCheckEMail", ?(DeliveryType = Enums.DeliveryTypes.EMail, True, ?(DeliveryType = Enums.DeliveryTypes.Both, True, False)));
	vClients = vQry.Execute().Unload();
	WriteLogEvent(NStr("en='DataProcessor.AutoSMSDelivery.DoCheckedOutGuestsNotificationDelivery';ru='Обработка.АвтоматизированнаяРассылкаСообщений.DoCheckedOutGuestsNotificationDelivery';de='DataProcessor.AutoSMSDelivery.DoCheckedOutGuestsNotificationDelivery'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Guests found: ';ru='Найдено гостей: ';de='Guests found: '") + vClients.Count());
	
	For Each vTemplate In pTemplates Do
		vUsedPhones = New ValueList();
		vUsedEMails = New ValueList();
		// Build SMS delivery document
		vSMSDeliveryObject = Documents.SMSDelivery.CreateDocument();
		vSMSDeliveryObject.pmFillAttributesWithDefaultValues();
		vSMSDeliveryObject.Hotel = Hotel;
		vSMSDeliveryObject.Sender = Sender;
		vSMSDeliveryObject.DeliveryType = DeliveryType;
		vSMSDeliveryObject.SMSTemplate = vTemplate;
		FillTemplateTexts(vSMSDeliveryObject);
		
		// Iterate thru clients
		For Each vClientsRow In vClients Do
			vPhone = SMS.GetValidPhoneNumber(vClientsRow.Phone);
			// Check if current phone number or e-mail was already processed
			If (DeliveryType = Enums.DeliveryTypes.EMail Or DeliveryType = Enums.DeliveryTypes.Both) And vUsedEMails.FindByValue(TrimAll(vClientsRow.EMail)) = Undefined Or 
			   (DeliveryType = Enums.DeliveryTypes.SMS Or DeliveryType = Enums.DeliveryTypes.Both) And vUsedPhones.FindByValue(vPhone) = Undefined Then
				vUsedPhones.Add(vPhone);
				vUsedEMails.Add(TrimAll(vClientsRow.EMail));
				// Add new SMS message row
				vRow = vSMSDeliveryObject.Receivers.Add();
				vRow.Phone = vPhone;
				vRow.EMail = TrimAll(vClientsRow.EMail);
				vRow.Customer = Undefined;
				vRow.Client = vClientsRow.Guest;
				vRow.ClientDoc = vClientsRow.Ref;
				vTemplateText = "";
				vTemplateLang = Catalogs.Languages.RU;
				If ValueIsFilled(vRow.Client) Then
					vTemplateLang = vRow.Client.Language;
				EndIf;
				If vTemplateLang = Catalogs.Languages.RU Then
					vTemplateText = vSMSDeliveryObject.TemplateTextRu;
				ElsIf vTemplateLang = Catalogs.Languages.EN Then
					vTemplateText = vSMSDeliveryObject.TemplateTextEn;
				ElsIf vTemplateLang = Catalogs.Languages.DE Then
					vTemplateText = vSMSDeliveryObject.TemplateTextDe;
				Else
					vTemplateText = vSMSDeliveryObject.TemplateTextRu;
				EndIf;
				vRow.SMSText = SMS.ReplaceSMSParameters(vTemplateText, vClientsRow.Ref, vClientsRow.Guest);
				vRow.NumberOfSMS = SMS.GetNumberOfSegments(vRow.SMSText);
				vRow.IsSent = False;
				vRow.Result = "";
				vRow.MessageID = "";
			EndIf;
		EndDo;
		// Send messages
		DoMessagesDelivery(vSMSDeliveryObject);
		If ValueIsFilled(vSMSDeliveryObject.Ref) Then
			vSMSDeliveryArr.Add(vSMSDeliveryObject.Ref);	
		EndIf;
	EndDo;
	// Return messages object
	Return vSMSDeliveryArr;
EndFunction // DoCheckedOutGuestsNotificationDelivery

// -----------------------------------------------------------------------------
Function GetReadyToBeExpiredInvoices()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Invoices.Ref,
	|	Invoices.AccountingCustomer AS Customer,
	|	Invoices.EMail,
	|	Invoices.Sum - ISNULL(InvoiceAccountsBalance.SumBalance, 0) AS SumPayed
	|FROM
	|	Document.ProformaInvoice AS Invoices
	|		LEFT JOIN (SELECT
	|			InvoiceAccounts.Invoice AS Invoice,
	|			InvoiceAccounts.SumBalance AS SumBalance
	|		FROM
	|			AccumulationRegister.InvoiceAccounts.Balance(
	|					,
	|					Invoice.Posted
	|						AND Invoice.CheckDate > &qEmptyDate
	|						AND Invoice.CheckDate = &qAfterAccountingDate
	|						AND Hotel = &qHotel) AS InvoiceAccounts) AS InvoiceAccountsBalance
	|		ON Invoices.Ref = InvoiceAccountsBalance.Invoice
	|WHERE
	|	Invoices.Posted
	|	AND Invoices.CheckDate > &qEmptyDate
	|	AND Invoices.CheckDate = &qAfterAccountingDate
	|	AND Invoices.Hotel = &qHotel
	|	AND ISNULL(InvoiceAccountsBalance.SumBalance, 0) = Invoices.Sum
	|	AND Invoices.Sum <> 0
	| 	" + TrimAll(DeliveryFilter) + "
	|
	|ORDER BY
	|	Invoices.Date";
	vQry.SetParameter("qAfterAccountingDate", BegOfDay(AccountingDate) + 24*3600);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qHotel", Hotel);
	vQryRes = vQry.Execute().Unload();
	Return vQryRes;
EndFunction // GetReadyToBeExpiredInvoices

// -----------------------------------------------------------------------------
Procedure DoReadyToBeExpiredInvoicesNotificationDelivery(pIsInteractive, pTemplates)
	// Run query to find invoices
	vInvoices = GetReadyToBeExpiredInvoices();
	For Each vTemplate In pTemplates Do 
		// Iterate thru invoices
		For Each vInvoicesRow In vInvoices Do
			// Check if e-mail is filled
			If Not IsBlankString(vInvoicesRow.EMail) And ValueIsFilled(vInvoicesRow.Customer) And ValueIsFilled(vInvoicesRow.Customer.Language) Then
				vInvoice = vInvoicesRow.Ref;
				vInvoiceObj = vInvoice.GetObject();
				vLanguage = vInvoicesRow.Customer.Language;
				// Get invoice default print form
				vInvoicePrintForm = cmGetDefaultObjectPrintingForm(Documents.ProformaInvoice.EmptyRef(), vLanguage);
				// Print invoice
				vSpreadsheet = Undefined;
				If vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintShortInvoiceGroupInPriceRu Or 
				   vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintShortInvoiceGroupInPriceEn Or
				   vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintShortInvoiceGroupAllRu Or
				   vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintShortInvoiceGroupAllEn Or
				   vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintShortInvoiceGroupByServiceRu Or
				   vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintShortInvoiceGroupByServiceEn Then
					// Get invoice spreadsheet
					vSpreadsheet = New SpreadsheetDocument();
					
					// Get group by parameter
					vSelGroupBy = "";
					If vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintShortInvoiceGroupInPriceRu Or
					   vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintShortInvoiceGroupInPriceEn Then
						vSelGroupBy = "InPrice";
					ElsIf vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintShortInvoiceGroupAllRu Or
					      vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintShortInvoiceGroupAllEn Then
						vSelGroupBy = "All";
					ElsIf vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintShortInvoiceGroupByServiceRu Or
					      vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintShortInvoiceGroupByServiceEn Then
						vSelGroupBy = "ByService";
					EndIf;
					If Not IsBlankString(vInvoicePrintForm.Parameter) Then
						vSelGroupBy = vInvoicePrintForm.Parameter;
					EndIf;
					
					// Call invoice object procedure
					mInvoiceNumber = "";
					vInvoiceObj.pmPrintInvoiceShort(vSpreadsheet, vLanguage, vSelGroupBy, vInvoicePrintForm, mInvoiceNumber);
				ElsIf vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintHotelProductsGroupInPriceRu Or 
				      vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintHotelProductsGroupInPriceEn Or
				      vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintHotelProductsGroupAllRu Or
				      vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintHotelProductsGroupAllEn Or
				      vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintHotelProductsGroupByServiceRu Or
				      vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintHotelProductsGroupByServiceEn Then
					// Get invoice spreadsheet
					vSpreadsheet = New SpreadsheetDocument();
					
					// Get group by parameter
					vSelGroupBy = "";
					If vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintHotelProductsGroupInPriceRu Or
					   vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintHotelProductsGroupInPriceEn Then
						vSelGroupBy = "InPrice";
					ElsIf vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintHotelProductsGroupAllRu Or
					      vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintHotelProductsGroupAllEn Then
						vSelGroupBy = "All";
					ElsIf vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintHotelProductsGroupByServiceRu Or
					      vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintHotelProductsGroupByServiceEn Then
						vSelGroupBy = "ByService";
					EndIf;
					If Not IsBlankString(vInvoicePrintForm.Parameter) Then
						vSelGroupBy = vInvoicePrintForm.Parameter;
					EndIf;
					
					// Call invoice object procedure
					mInvoiceNumber = "";
					vInvoiceObj.pmPrintInvoiceHotelProduct(vSpreadsheet, vLanguage, vSelGroupBy, vInvoicePrintForm, mInvoiceNumber);
				Else
					// Get invoice spreadsheet
					vSpreadsheet = New SpreadsheetDocument();
					
					// Get group by parameter
					vSelGroupBy = "";
					If vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupInPricePerClientPerDayRu Or
					   vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupInPricePerClientPerDayEn Then
						vSelGroupBy = "InPricePerClientPerDay";
					ElsIf vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupInPricePerDayRu Or
					      vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupInPricePerDayEn Then
						vSelGroupBy = "InPricePerDay";
					ElsIf vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupPerClientRu Or
						  vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupPerClientEn Then
						vSelGroupBy = "PerClient";
					ElsIf vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupByServiceRu Or
						  vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupByServiceEn Then
						vSelGroupBy = "ByService";
					ElsIf vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupAllPerClientPerDayRu Or
						  vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupAllPerClientPerDayEn Then
						vSelGroupBy = "AllPerClientPerDay";
					ElsIf vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupAllPerDayRu Or
						  vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupAllPerDayEn Then
						vSelGroupBy = "AllPerDay";
					ElsIf vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupInPricePerClientRu Or
						  vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupInPricePerClientEn Then
						vSelGroupBy = "InPricePerClient";
					ElsIf vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupInPriceRu Or
						  vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupInPriceEn Then
						vSelGroupBy = "InPrice";
					ElsIf vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupAllPerClientRu Or
						  vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupAllPerClientEn Then
						vSelGroupBy = "AllPerClient";
					ElsIf vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupAllRu Or
						  vInvoicePrintForm = Catalogs.ObjectPrintingForms.InvoicePrintInvoiceGroupAllEn Then
						vSelGroupBy = "All";
					EndIf;
					
					// Call invoice object procedure
					mInvoiceNumber = "";
					vInvoiceObj.pmPrintInvoice(vSpreadsheet, vLanguage, vSelGroupBy, vInvoicePrintForm, mInvoiceNumber);
				EndIf;
				If vSpreadsheet <> Undefined Then
					vResult = vInvoiceObj.pmSendInvoiceByEMail(vSpreadsheet, TrimAll(vInvoicesRow.EMail), cmGetDocumentNumberPresentation(vInvoiceObj.Number), vLanguage, ?(ValueIsFilled(vTemplate), TrimAll(vTemplate.SMSText), ""), , vTemplate, EMail.GetEMailParameters(vInvoice));
					If vResult Then
						vMessage = Chars.Tab + NStr("de='Rechnung versendet: ';en='Invoice being sent: ';ru='Счет-требование отправлен: '") + TrimAll(vInvoice) + " -> " + TrimAll(vInvoicesRow.EMail);
						WriteLogEvent(NStr("en='DataProcessor.AutoSMSDelivery';ru='Обработка.АвтоматизированнаяРассылкаСообщений';de='DataProcessor.AutoSMSDelivery'"), EventLogLevel.Information, vInvoice.Metadata(), vInvoice, vMessage);
						If pIsInteractive Then
							tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
						EndIf;
					Else
						vMessage = Chars.Tab + NStr("de='Fehler beim Versenden der Rechnung: ';en='Error sending invoice: ';ru='Ошибка отправки счета-требования: '") + TrimAll(vInvoice) + " -> " + TrimAll(vInvoicesRow.EMail);
						WriteLogEvent(NStr("en='DataProcessor.AutoSMSDelivery';ru='Обработка.АвтоматизированнаяРассылкаСообщений';de='DataProcessor.AutoSMSDelivery'"), EventLogLevel.Warning, vInvoice.Metadata(), vInvoice, vMessage);
						If pIsInteractive Then
							tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndDo;
EndProcedure // DoReadyToBeExpiredInvoicesNotificationDelivery

// -----------------------------------------------------------------------------
Function DoAfterCheckOutGuestsNotificationDelivery(pTemplates)
	vSMSDeliveryArr = New Array;
	
	// Run query to find guests
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref,
	|	Accommodation.Guest,
	|	CASE
	|		WHEN Accommodation.Guest.Phone <> &qEmptyString
	|			THEN Accommodation.Guest.Phone
	|		WHEN Accommodation.Phone <> &qEmptyString
	|			THEN Accommodation.Phone
	|		ELSE &qEmptyString
	|	END AS Phone,
	|	CASE
	|		WHEN Accommodation.Guest.EMail <> &qEmptyString
	|			THEN Accommodation.Guest.EMail
	|		WHEN Accommodation.EMail <> &qEmptyString
	|			THEN Accommodation.EMail
	|		ELSE &qEmptyString
	|	END AS EMail,
	|	Accommodation.Guest.FullName AS GuestFullName
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Posted
	|	AND NOT Accommodation.AccommodationStatus.IsInHouse
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.AccommodationStatus.IsCheckOut
	|	AND Accommodation.Hotel = &qHotel
	|	AND Accommodation.Guest <> &qEmptyGuest
	|	AND (Accommodation.Guest.Phone <> &qEmptyString
	|				AND NOT &qCheckEMail
	|			OR Accommodation.Phone <> &qEmptyString
	|				AND NOT &qCheckEMail
	|			OR Accommodation.Guest.EMail <> &qEmptyString
	|				AND &qCheckEMail
	|			OR Accommodation.EMail <> &qEmptyString
	|				AND &qCheckEMail)
	|	AND NOT Accommodation.Guest.NoSMSDelivery
	|	AND NOT Accommodation.Guest.DeletionMark
	|	AND Accommodation.CheckOutDate >= &qPeriodFrom
	|	AND Accommodation.CheckOutDate <= &qPeriodTo
	| 	" + TrimAll(DeliveryFilter) + "
	|
	|GROUP BY
	|	Accommodation.Ref,
	|	Accommodation.Guest,
	|	CASE
	|		WHEN Accommodation.Guest.Phone <> &qEmptyString
	|			THEN Accommodation.Guest.Phone
	|		WHEN Accommodation.Phone <> &qEmptyString
	|			THEN Accommodation.Phone
	|		ELSE &qEmptyString
	|	END,
	|	CASE
	|		WHEN Accommodation.Guest.EMail <> &qEmptyString
	|			THEN Accommodation.Guest.EMail
	|		WHEN Accommodation.EMail <> &qEmptyString
	|			THEN Accommodation.EMail
	|		ELSE &qEmptyString
	|	END,
	|	Accommodation.Guest.FullName
	|
	|ORDER BY
	|	GuestFullName";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qPeriodFrom", BegOfDay(AccountingDate - NumberOfDays * 24 * 3600));
	vQry.SetParameter("qPeriodTo", EndOfDay(AccountingDate - NumberOfDays * 24 * 3600));
	vQry.SetParameter("qEmptyGuest", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qEmptyCurrency", Catalogs.Currencies.EmptyRef());
	vQry.SetParameter("qEmptyString", "");
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	vQry.SetParameter("qCheckEMail", ?(DeliveryType = Enums.DeliveryTypes.EMail, True, ?(DeliveryType = Enums.DeliveryTypes.Both, True, False)));
	vClients = vQry.Execute().Unload();
	
	For Each vTemplate In pTemplates Do
		vUsedPhones = New ValueList();
		vUsedEMails = New ValueList();
		// Build SMS delivery document
		vSMSDeliveryObject = Documents.SMSDelivery.CreateDocument();
		vSMSDeliveryObject.pmFillAttributesWithDefaultValues();
		vSMSDeliveryObject.Hotel = Hotel;
		vSMSDeliveryObject.Sender = Sender;
		vSMSDeliveryObject.DeliveryType = DeliveryType;
		vSMSDeliveryObject.SMSTemplate = vTemplate;
		FillTemplateTexts(vSMSDeliveryObject);
			
		// Iterate thru clients
		For Each vClientsRow In vClients Do
			vPhone = SMS.GetValidPhoneNumber(vClientsRow.Phone);
			// Check if current phone number or e-mail was already processed
			If (DeliveryType = Enums.DeliveryTypes.EMail Or DeliveryType = Enums.DeliveryTypes.Both) And vUsedEMails.FindByValue(TrimAll(vClientsRow.EMail)) = Undefined Or 
			   (DeliveryType = Enums.DeliveryTypes.SMS Or DeliveryType = Enums.DeliveryTypes.Both) And vUsedPhones.FindByValue(vPhone) = Undefined Then
				vUsedPhones.Add(vPhone);
				vUsedEMails.Add(TrimAll(vClientsRow.EMail));
				// Add new SMS message row
				vRow = vSMSDeliveryObject.Receivers.Add();
				vRow.Phone = vPhone;
				vRow.EMail = TrimAll(vClientsRow.EMail);
				vRow.Customer = Undefined;
				vRow.Client = vClientsRow.Guest;
				vRow.ClientDoc = vClientsRow.Ref;
				vTemplateText = "";
				vTemplateLang = Catalogs.Languages.RU;
				If ValueIsFilled(vRow.Client) Then
					vTemplateLang = vRow.Client.Language;
				EndIf;
				If vTemplateLang = Catalogs.Languages.RU Then
					vTemplateText = vSMSDeliveryObject.TemplateTextRu;
				ElsIf vTemplateLang = Catalogs.Languages.EN Then
					vTemplateText = vSMSDeliveryObject.TemplateTextEn;
				ElsIf vTemplateLang = Catalogs.Languages.DE Then
					vTemplateText = vSMSDeliveryObject.TemplateTextDe;
				Else
					vTemplateText = vSMSDeliveryObject.TemplateTextRu;
				EndIf;
				vRow.SMSText = SMS.ReplaceSMSParameters(vTemplateText, vClientsRow.Ref, vClientsRow.Guest);
				vRow.NumberOfSMS = SMS.GetNumberOfSegments(vRow.SMSText);
				vRow.IsSent = False;
				vRow.Result = "";
				vRow.MessageID = "";
			EndIf;
		EndDo;
		// Send messages
		DoMessagesDelivery(vSMSDeliveryObject);
		If ValueIsFilled(vSMSDeliveryObject.Ref) Then
			vSMSDeliveryArr.Add(vSMSDeliveryObject.Ref);	
		EndIf;
	EndDo;
	// Return messages object
	Return vSMSDeliveryArr;
EndFunction // DoAfterCheckOutGuestsNotificationDelivery

// -----------------------------------------------------------------------------
Function DoBeforeCheckInGuestsNotificationDelivery(pTemplates)
	vSMSDeliveryArr = New Array;
	
	// Run query to find guests
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservation.Ref,
	|	Reservation.Guest,
	|	CASE
	|		WHEN Reservation.Guest.Phone <> &qEmptyString
	|			THEN Reservation.Guest.Phone
	|		WHEN Reservation.Phone <> &qEmptyString
	|			THEN Reservation.Phone
	|		ELSE &qEmptyString
	|	END AS Phone,
	|	CASE
	|		WHEN Reservation.Guest.EMail <> &qEmptyString
	|			THEN Reservation.Guest.EMail
	|		WHEN Reservation.EMail <> &qEmptyString
	|			THEN Reservation.EMail
	|		ELSE &qEmptyString
	|	END AS EMail,
	|	Reservation.Guest.FullName AS GuestFullName
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.Posted
	|	AND Reservation.ReservationStatus.IsActive
	|	AND NOT Reservation.ReservationStatus.IsCheckIn
	|	AND Reservation.Hotel = &qHotel
	|	AND Reservation.Guest <> &qEmptyGuest
	|	AND (Reservation.Guest.Phone <> &qEmptyString
	|				AND NOT &qCheckEMail
	|			OR Reservation.Phone <> &qEmptyString
	|				AND NOT &qCheckEMail
	|			OR Reservation.Guest.EMail <> &qEmptyString
	|				AND &qCheckEMail
	|			OR Reservation.EMail <> &qEmptyString
	|				AND &qCheckEMail)
	|	AND NOT Reservation.Guest.NoSMSDelivery
	|	AND NOT Reservation.Guest.DeletionMark
	|	AND Reservation.CheckInDate >= &qPeriodFrom
	|	AND Reservation.CheckInDate <= &qPeriodTo
	| 	" + TrimAll(DeliveryFilter) + "
	|
	|GROUP BY
	|	Reservation.Ref,
	|	Reservation.Guest,
	|	CASE
	|		WHEN Reservation.Guest.Phone <> &qEmptyString
	|			THEN Reservation.Guest.Phone
	|		WHEN Reservation.Phone <> &qEmptyString
	|			THEN Reservation.Phone
	|		ELSE &qEmptyString
	|	END,
	|	CASE
	|		WHEN Reservation.Guest.EMail <> &qEmptyString
	|			THEN Reservation.Guest.EMail
	|		WHEN Reservation.EMail <> &qEmptyString
	|			THEN Reservation.EMail
	|		ELSE &qEmptyString
	|	END,
	|	Reservation.Guest.FullName
	|
	|ORDER BY
	|	GuestFullName";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qPeriodFrom", BegOfDay(AccountingDate + NumberOfDays * 24 * 3600));
	vQry.SetParameter("qPeriodTo", EndOfDay(AccountingDate + NumberOfDays * 24 * 3600));
	vQry.SetParameter("qEmptyGuest", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qEmptyCurrency", Catalogs.Currencies.EmptyRef());
	vQry.SetParameter("qEmptyString", "");
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	vQry.SetParameter("qCheckEMail", ?(DeliveryType = Enums.DeliveryTypes.EMail, True, ?(DeliveryType = Enums.DeliveryTypes.Both, True, False)));
	vClients = vQry.Execute().Unload();
	
	For Each vTemplate In pTemplates Do
		vUsedPhones = New ValueList();
		vUsedEMails = New ValueList();
		// Build SMS delivery document
		vSMSDeliveryObject = Documents.SMSDelivery.CreateDocument();
		vSMSDeliveryObject.pmFillAttributesWithDefaultValues();
		vSMSDeliveryObject.Hotel = Hotel;
		vSMSDeliveryObject.Sender = Sender;
		vSMSDeliveryObject.DeliveryType = DeliveryType;
		vSMSDeliveryObject.SMSTemplate = vTemplate;
		FillTemplateTexts(vSMSDeliveryObject);
		
		// Iterate thru clients
		For Each vClientsRow In vClients Do
			vPhone = SMS.GetValidPhoneNumber(vClientsRow.Phone);
			// Check if current phone number or e-mail was already processed
			If (DeliveryType = Enums.DeliveryTypes.EMail Or DeliveryType = Enums.DeliveryTypes.Both) And vUsedEMails.FindByValue(TrimAll(vClientsRow.EMail)) = Undefined Or 
			   (DeliveryType = Enums.DeliveryTypes.SMS Or DeliveryType = Enums.DeliveryTypes.Both) And vUsedPhones.FindByValue(vPhone) = Undefined Then
				vUsedPhones.Add(vPhone);
				vUsedEMails.Add(TrimAll(vClientsRow.EMail));
				// Add new SMS message row
				vRow = vSMSDeliveryObject.Receivers.Add();
				vRow.Phone = vPhone;
				vRow.EMail = TrimAll(vClientsRow.EMail);
				vRow.Customer = Undefined;
				vRow.Client = vClientsRow.Guest;
				vRow.ClientDoc = vClientsRow.Ref;
				vTemplateText = "";
				vTemplateLang = Catalogs.Languages.RU;
				If ValueIsFilled(vRow.Client) Then
					vTemplateLang = vRow.Client.Language;
				EndIf;
				If vTemplateLang = Catalogs.Languages.RU Then
					vTemplateText = vSMSDeliveryObject.TemplateTextRu;
				ElsIf vTemplateLang = Catalogs.Languages.EN Then
					vTemplateText = vSMSDeliveryObject.TemplateTextEn;
				ElsIf vTemplateLang = Catalogs.Languages.DE Then
					vTemplateText = vSMSDeliveryObject.TemplateTextDe;
				Else
					vTemplateText = vSMSDeliveryObject.TemplateTextRu;
				EndIf;
				vRow.SMSText = SMS.ReplaceSMSParameters(vTemplateText, vClientsRow.Ref, vClientsRow.Guest);
				vRow.NumberOfSMS = SMS.GetNumberOfSegments(vRow.SMSText);
				vRow.IsSent = False;
				vRow.Result = "";
				vRow.MessageID = "";
			EndIf;
		EndDo;
		// Send messages
		DoMessagesDelivery(vSMSDeliveryObject);
		If ValueIsFilled(vSMSDeliveryObject.Ref) Then
			vSMSDeliveryArr.Add(vSMSDeliveryObject.Ref);	
		EndIf;
	EndDo;
	// Return messages object
	Return vSMSDeliveryArr;
EndFunction // DoBeforeCheckInGuestsNotificationDelivery

// -----------------------------------------------------------------------------
Function DoAllClientsBirthdayCongratulationDelivery(pTemplates)
	vSMSDeliveryArr = New Array;
	
	// Run query to find guests
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Clients.Ref AS Guest,
	|	Clients.Phone AS Phone,
	|	Clients.EMail AS EMail,
	|	Clients.FullName AS GuestFullName
	|FROM
	|	Catalog.Clients AS Clients
	|WHERE
	|	NOT Clients.DeletionMark
	|	AND (Clients.Phone <> &qEmptyString
	|				AND NOT &qCheckEMail
	|			OR Clients.EMail <> &qEmptyString
	|				AND &qCheckEMail)
	|	AND NOT Clients.NoSMSDelivery
	|	AND Clients.DateOfBirth > &qEmptyDate
	|	AND (YEAR(&qBirthDayPeriodTo) = YEAR(&qBirthDayPeriodFrom)
	|				AND MONTH(Clients.DateOfBirth) * 100 + DAY(Clients.DateOfBirth) >= MONTH(&qBirthDayPeriodFrom) * 100 + DAY(&qBirthDayPeriodFrom)
	|				AND MONTH(Clients.DateOfBirth) * 100 + DAY(Clients.DateOfBirth) <= MONTH(&qBirthDayPeriodTo) * 100 + DAY(&qBirthDayPeriodTo)
	|			OR YEAR(&qBirthDayPeriodTo) <> YEAR(&qBirthDayPeriodFrom)
	|				AND (MONTH(Clients.DateOfBirth) * 100 + DAY(Clients.DateOfBirth) >= MONTH(&qBirthDayPeriodFrom) * 100 + DAY(&qBirthDayPeriodFrom)
	|						AND MONTH(Clients.DateOfBirth) * 100 + DAY(Clients.DateOfBirth) <= 1231
	|					OR MONTH(Clients.DateOfBirth) * 100 + DAY(Clients.DateOfBirth) <= MONTH(&qBirthDayPeriodTo) * 100 + DAY(&qBirthDayPeriodTo)
	|						AND MONTH(Clients.DateOfBirth) * 100 + DAY(Clients.DateOfBirth) >= 101))
	| 	" + TrimAll(DeliveryFilter) + "
	|
	|ORDER BY
	|	GuestFullName";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qBirthDayPeriodFrom", AccountingDate + (NumberOfDays * 24 * 3600));
	vQry.SetParameter("qBirthDayPeriodTo", AccountingDate + (NumberOfDays * 24 * 3600));
	vQry.SetParameter("qEmptyString", "");
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qCheckEMail", ?(DeliveryType = Enums.DeliveryTypes.EMail, True, ?(DeliveryType = Enums.DeliveryTypes.Both, True, False)));
	vClients = vQry.Execute().Unload();
	
	For Each vTemplate In pTemplates Do
		vUsedPhones = New ValueList();
		vUsedEMails = New ValueList();
		// Build SMS delivery document
		vSMSDeliveryObject = Documents.SMSDelivery.CreateDocument();
		vSMSDeliveryObject.pmFillAttributesWithDefaultValues();
		vSMSDeliveryObject.Hotel = Hotel;
		vSMSDeliveryObject.Sender = Sender;
		vSMSDeliveryObject.DeliveryType = DeliveryType;
		vSMSDeliveryObject.SMSTemplate = vTemplate;
		FillTemplateTexts(vSMSDeliveryObject);
		
		// Iterate thru clients
		For Each vClientsRow In vClients Do
			vPhone = SMS.GetValidPhoneNumber(vClientsRow.Phone);
			// Check if current phone number or e-mail was already processed
			If (DeliveryType = Enums.DeliveryTypes.EMail Or DeliveryType = Enums.DeliveryTypes.Both) And vUsedEMails.FindByValue(TrimAll(vClientsRow.EMail)) = Undefined Or 
			   (DeliveryType = Enums.DeliveryTypes.SMS Or DeliveryType = Enums.DeliveryTypes.Both) And vUsedPhones.FindByValue(vPhone) = Undefined Then
				vUsedPhones.Add(vPhone);
				vUsedEMails.Add(TrimAll(vClientsRow.EMail));
				// Add new SMS message row
				vRow = vSMSDeliveryObject.Receivers.Add();
				vRow.Phone = vPhone;
				vRow.EMail = TrimAll(vClientsRow.EMail);
				vRow.Customer = Undefined;
				vRow.Client = vClientsRow.Guest;
				vRow.ClientDoc = Undefined;
				vTemplateText = "";
				vTemplateLang = Catalogs.Languages.RU;
				If ValueIsFilled(vRow.Client) Then
					vTemplateLang = vRow.Client.Language;
				EndIf;
				If vTemplateLang = Catalogs.Languages.RU Then
					vTemplateText = vSMSDeliveryObject.TemplateTextRu;
				ElsIf vTemplateLang = Catalogs.Languages.EN Then
					vTemplateText = vSMSDeliveryObject.TemplateTextEn;
				ElsIf vTemplateLang = Catalogs.Languages.DE Then
					vTemplateText = vSMSDeliveryObject.TemplateTextDe;
				Else
					vTemplateText = vSMSDeliveryObject.TemplateTextRu;
				EndIf;
				vRow.SMSText = SMS.ReplaceSMSParameters(vTemplateText, Undefined, vClientsRow.Guest);
				vRow.NumberOfSMS = SMS.GetNumberOfSegments(vRow.SMSText);
				vRow.IsSent = False;
				vRow.Result = "";
				vRow.MessageID = "";
			EndIf;
		EndDo;
		// Send messages
		DoMessagesDelivery(vSMSDeliveryObject);
		If ValueIsFilled(vSMSDeliveryObject.Ref) Then
			vSMSDeliveryArr.Add(vSMSDeliveryObject.Ref);	
		EndIf;
	EndDo;
	// Return messages object
	Return vSMSDeliveryArr;
EndFunction // DoAllClientsBirthdayCongratulationDelivery

// -----------------------------------------------------------------------------
Function DoAllClientsImportantDatesCongratulationDelivery()
	vSMSDeliveryArr = New Array;
	
	// Run query to find guests
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ImportantDateTypes.Ref AS Ref,
	|	ImportantDateTypes.SMSTemplate AS SMSTemplate,
	|	ImportantDateTypes.NumberOfDays AS NumberOfDays
	|INTO ImportantDateTypesItems
	|FROM
	|	Catalog.ImportantDateTypes AS ImportantDateTypes
	|WHERE
	|	NOT ImportantDateTypes.IsFolder
	|	AND NOT ImportantDateTypes.DeletionMark
	|	AND ImportantDateTypes.Ref IN HIERARCHY(&qImportantDateTypes)
	|	AND ImportantDateTypes.SMSTemplate <> VALUE(Catalog.ImportantDateTypes.EmptyRef)
	|
	|GROUP BY
	|	ImportantDateTypes.Ref,
	|	ImportantDateTypes.SMSTemplate,
	|	ImportantDateTypes.NumberOfDays
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ImportantDateTypesList.Ref AS Ref,
	|	ImportantDateTypesList.NumberOfDays AS NumberOfDays,
	|	ImportantDateTypesList.SMSTemplate AS SMSTemplate,
	|	BEGINOFPERIOD(&qAccountingDate, DAY) AS CurDate
	|INTO ImportantDateTypesList
	|FROM
	|	ImportantDateTypesItems AS ImportantDateTypesList
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ClientImportantDates.Guest AS Guest,
	|	ImportantDateTypesList.SMSTemplate AS SMSTemplate
	|INTO ImportantDateTypes
	|FROM
	|	InformationRegister.ClientImportantDates AS ClientImportantDates
	|		INNER JOIN ImportantDateTypesList AS ImportantDateTypesList
	|		ON ClientImportantDates.ImportantDateType = ImportantDateTypesList.Ref
	|			AND (DAY(BEGINOFPERIOD(DATEADD(ClientImportantDates.Date, DAY, -ImportantDateTypesList.NumberOfDays), DAY)) = DAY(ImportantDateTypesList.CurDate))
	|			AND (MONTH(BEGINOFPERIOD(DATEADD(ClientImportantDates.Date, DAY, -ImportantDateTypesList.NumberOfDays), DAY)) = MONTH(ImportantDateTypesList.CurDate))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Clients.Ref AS Guest,
	|	Clients.Phone AS Phone,
	|	Clients.EMail AS EMail,
	|	Clients.FullName AS GuestFullName,
	|	ImportantDateTypes.SMSTemplate AS SMSTemplate
	|FROM
	|	ImportantDateTypes AS ImportantDateTypes
	|		INNER JOIN Catalog.Clients AS Clients
	|		ON ImportantDateTypes.Guest = Clients.Ref
	|WHERE
	|	NOT Clients.DeletionMark
	|	AND (Clients.Phone <> &qEmptyString
	|				AND NOT &qCheckEMail
	|			OR Clients.EMail <> &qEmptyString
	|				AND &qCheckEMail)
	|	AND NOT Clients.NoSMSDelivery" + TrimAll(DeliveryFilter) + "
	|
	|ORDER BY
	|	GuestFullName";
	
	vQry.SetParameter("qImportantDateTypes", ImportantDateType); 
	vQry.SetParameter("qAccountingDate", BegOfDay(AccountingDate));
	vQry.SetParameter("qEmptyString", "");
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qCheckEMail", ?(DeliveryType = Enums.DeliveryTypes.EMail, True, ?(DeliveryType = Enums.DeliveryTypes.Both, True, False)));
	vClients = vQry.Execute().Unload();
	
	vImportantDateTypes = vClients.Copy(, "SMSTemplate");
	vImportantDateTypes.GroupBy("SMSTemplate", );
	vTemplates = vImportantDateTypes.UnloadColumn("SMSTemplate");
	
	For Each vTemplate In vTemplates Do
		vUsedPhones = New ValueList();
		vUsedEMails = New ValueList();
		
		// Build SMS delivery document
		vSMSDeliveryObject = Documents.SMSDelivery.CreateDocument();
		vSMSDeliveryObject.pmFillAttributesWithDefaultValues();
		vSMSDeliveryObject.Hotel = Hotel;
		vSMSDeliveryObject.Sender = Sender;
		vSMSDeliveryObject.DeliveryType = DeliveryType;
		vSMSDeliveryObject.SMSTemplate = vTemplate;
		FillTemplateTexts(vSMSDeliveryObject);
		
		vClientsArr = vClients.FindRows(New Structure("SMSTemplate", vTemplate)); 
		
		// Iterate thru clients
		For Each vClientsRow In vClientsArr Do
			vPhone = SMS.GetValidPhoneNumber(vClientsRow.Phone);
			// Check if current phone number or e-mail was already processed
			If (DeliveryType = Enums.DeliveryTypes.EMail Or DeliveryType = Enums.DeliveryTypes.Both) And vUsedEMails.FindByValue(TrimAll(vClientsRow.EMail)) = Undefined Or 
			   (DeliveryType = Enums.DeliveryTypes.SMS Or DeliveryType = Enums.DeliveryTypes.Both) And vUsedPhones.FindByValue(vPhone) = Undefined Then
				vUsedPhones.Add(vPhone);
				vUsedEMails.Add(TrimAll(vClientsRow.EMail));
				// Add new SMS message row
				vRow = vSMSDeliveryObject.Receivers.Add();
				vRow.Phone = vPhone;
				vRow.EMail = TrimAll(vClientsRow.EMail);
				vRow.Customer = Undefined;
				vRow.Client = vClientsRow.Guest;
				vRow.ClientDoc = Undefined;
				vTemplateText = "";
				vTemplateLang = Catalogs.Languages.RU;
				If ValueIsFilled(vRow.Client) Then
					vTemplateLang = vRow.Client.Language;
				EndIf;
				If vTemplateLang = Catalogs.Languages.RU Then
					vTemplateText = vSMSDeliveryObject.TemplateTextRu;
				ElsIf vTemplateLang = Catalogs.Languages.EN Then
					vTemplateText = vSMSDeliveryObject.TemplateTextEn;
				ElsIf vTemplateLang = Catalogs.Languages.DE Then
					vTemplateText = vSMSDeliveryObject.TemplateTextDe;
				Else
					vTemplateText = vSMSDeliveryObject.TemplateTextRu;
				EndIf;
				vRow.SMSText = SMS.ReplaceSMSParameters(vTemplateText, Undefined, vClientsRow.Guest);
				vRow.NumberOfSMS = SMS.GetNumberOfSegments(vRow.SMSText);
				vRow.IsSent = False;
				vRow.Result = "";
				vRow.MessageID = "";
			EndIf;
		EndDo;
		// Send messages
		DoMessagesDelivery(vSMSDeliveryObject);
		If ValueIsFilled(vSMSDeliveryObject.Ref) Then
			vSMSDeliveryArr.Add(vSMSDeliveryObject.Ref);	
		EndIf;
	EndDo;
	// Return messages object
	Return vSMSDeliveryArr;
EndFunction // DoAllClientsImportantDatesCongratulationDelivery

// -----------------------------------------------------------------------------
Function GetTemplates()
	If ValueIsFilled(MessageTemplate) Then
		vQ = New Query();
		vQ.Text =
		"SELECT
		|	SMSTemplates.Ref AS Ref
		|FROM
		|	Catalog.SMSTemplates AS SMSTemplates
		|WHERE
		|	NOT SMSTemplates.IsFolder
		|	AND NOT SMSTemplates.DeletionMark
		|	AND SMSTemplates.Ref IN HIERARCHY(&qMessageTemplate)
		|
		|GROUP BY
		|	SMSTemplates.Ref";
		vQ.SetParameter("qMessageTemplate", MessageTemplate);
		Return vQ.Execute().Unload().UnloadColumn("Ref");
	Else
		Return New Array;	
	EndIf;
EndFunction // GetTemplates

// -----------------------------------------------------------------------------
Procedure pmDoAutoDelivery(pIsInteractive = False) Export
	WriteLogEvent(NStr("en='DataProcessor.AutoSMSDelivery';ru='Обработка.АвтоматизированнаяРассылкаСообщений';de='DataProcessor.AutoSMSDelivery'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'"));
	
	// Check attributes
	If Not ValueIsFilled(Hotel) Then
		Raise NStr("en='Hotel should be filled!';ru='Не указана гостиница!';de='Das Hotel ist nicht angegeben!'");
	EndIf;
	If Not ValueIsFilled(AccountingDate) Then
		Raise NStr("en='Accounting date should be filled!';ru='Не указана дата!';de='Das Datum ist nicht angegeben!'");
	EndIf;
	If Not ValueIsFilled(DeliveryType) Then
		Raise NStr("en='Delivery transport should be filled!';ru='Способ доставки должен быть указан!';de='Lieferungsmethode muss definiert werden!'");
	EndIf;
	If Not ValueIsFilled(DeliveryTemplate) Then
		Raise NStr("en='Delivery template should be filled!';ru='Вид рассылки должен быть указан!';de='Der Verteilertyp muss angegeben sein!'");
	EndIf;  
	If Not ValueIsFilled(ImportantDateType) Then
		If Not ValueIsFilled(MessageTemplate) Then
			Raise NStr("en='Message template should be filled!';ru='Шаблон сообщений должен быть указан!';de='Mitteilungsvorlage muss ausgewiesen sein!'");
		EndIf;  
	EndIf;
	
	vTemplates = GetTemplates();
	
	// Check delivery type
	vSMSDeliveryArr = New Array;
	If DeliveryTemplate = Enums.AutoDeliveryTemplates.InHouseGuestsBirthdayCongratulation Then
		WriteLogEvent(NStr("en='DataProcessor.AutoSMSDelivery';ru='Обработка.АвтоматизированнаяРассылкаСообщений';de='DataProcessor.AutoSMSDelivery'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Send birthday congratulations to the in-house guests';ru='Рассылка поздравлений с днем рождения проживающим гостям';de='Versand von Geburtstagsglückwünschen an Hotelgäste'"));
		vSMSDeliveryArr = DoInHouseGuestsBirthdayCongratulationDelivery(vTemplates);
	ElsIf DeliveryTemplate = Enums.AutoDeliveryTemplates.InHouseGuestsFolioBalanceNotification Then 
		WriteLogEvent(NStr("en='DataProcessor.AutoSMSDelivery';ru='Обработка.АвтоматизированнаяРассылкаСообщений';de='DataProcessor.AutoSMSDelivery'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Send in-house guests folio balances';ru='Рассылка балансов по лицевым счетам проживающим гостям';de='Versand von Bilanzen nach Personenkonten an Hotelgäste'"));
		vSMSDeliveryArr = DoInHouseGuestsFolioBalanceNotificationDelivery(vTemplates);
	ElsIf DeliveryTemplate = Enums.AutoDeliveryTemplates.ExpectedCheckOutGuestsFolioBalanceNotification Then 
		WriteLogEvent(NStr("en='DataProcessor.AutoSMSDelivery';ru='Обработка.АвтоматизированнаяРассылкаСообщений';de='DataProcessor.AutoSMSDelivery'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Send expected check-out guests folio balances';ru='Рассылка балансов по лицевым счетам выезжающих гостей';de='Versand der Bilanzen nach Personenkonten abreisender Gäste'"));
		vSMSDeliveryArr = DoExpectedCheckOutGuestsFolioBalanceNotificationDelivery(vTemplates);
	ElsIf DeliveryTemplate = Enums.AutoDeliveryTemplates.ExpectedCheckInGuestsNotification Then 
		WriteLogEvent(NStr("en='DataProcessor.AutoSMSDelivery';ru='Обработка.АвтоматизированнаяРассылкаСообщений';de='DataProcessor.AutoSMSDelivery'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Send to expected check-in guests';ru='Рассылка заезжающим гостям';de='Versand an anreisende Gäste'"));
		vSMSDeliveryArr = DoExpectedCheckInGuestsNotificationDelivery(vTemplates);
	ElsIf DeliveryTemplate = Enums.AutoDeliveryTemplates.CheckedInGuestsNotification Then 
		WriteLogEvent(NStr("en='DataProcessor.AutoSMSDelivery';ru='Обработка.АвтоматизированнаяРассылкаСообщений';de='DataProcessor.AutoSMSDelivery'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Send to checked-in guests';ru='Рассылка заехавшим гостям';de='Versand an angereiste Gäste'"));
		vSMSDeliveryArr = DoCheckedInGuestsNotificationDelivery(vTemplates);
	ElsIf DeliveryTemplate = Enums.AutoDeliveryTemplates.InHouseGuestsNotification Then 
		WriteLogEvent(NStr("en='DataProcessor.AutoSMSDelivery';ru='Обработка.АвтоматизированнаяРассылкаСообщений';de='DataProcessor.AutoSMSDelivery'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Send to in-house guests';ru='Рассылка проживающим гостям';de='Versand an Hotelgäste'"));
		vSMSDeliveryArr = DoInHouseGuestsNotificationDelivery(vTemplates);
	ElsIf DeliveryTemplate = Enums.AutoDeliveryTemplates.ExpectedCheckOutGuestsNotification Then 
		WriteLogEvent(NStr("en='DataProcessor.AutoSMSDelivery';ru='Обработка.АвтоматизированнаяРассылкаСообщений';de='DataProcessor.AutoSMSDelivery'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Send to expected check-out guests';ru='Рассылка выезжающим гостям';de='Versand an abreisende Gäste'"));
		vSMSDeliveryArr = DoExpectedCheckOutGuestsNotificationDelivery(vTemplates);
	ElsIf DeliveryTemplate = Enums.AutoDeliveryTemplates.CheckedOutGuestsNotification Then 
		WriteLogEvent(NStr("en='DataProcessor.AutoSMSDelivery';ru='Обработка.АвтоматизированнаяРассылкаСообщений';de='DataProcessor.AutoSMSDelivery'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Send to checked-out guests';ru='Рассылка выехавшим гостям';de='Versand an abgereiste Gäste'"));
		vSMSDeliveryArr = DoCheckedOutGuestsNotificationDelivery(vTemplates);
	ElsIf DeliveryTemplate = Enums.AutoDeliveryTemplates.ExpiredInvoicesNotification Then 
		WriteLogEvent(NStr("en='DataProcessor.AutoSMSDelivery';ru='Обработка.АвтоматизированнаяРассылкаСообщений';de='DataProcessor.AutoSMSDelivery'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("de='Versand von Rechnungen einen Tag vor dem Datum der Zahlung';en='Send invoices where payment date is ready to be expired';ru='Рассылка счетов-требований за день до наступления даты просрочки оплаты'"));
		DoReadyToBeExpiredInvoicesNotificationDelivery(pIsInteractive, vTemplates); 
	ElsIf DeliveryTemplate = Enums.AutoDeliveryTemplates.AfterCheckOutGuestsNotification Then
		WriteLogEvent(NStr("en='DataProcessor.AutoSMSDelivery';ru='Обработка.АвтоматизированнаяРассылкаСообщений';de='DataProcessor.AutoSMSDelivery'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Send to after check-out guests';ru='Рассылка после выезда гостей';de='An Gäste nach dem Check-out senden'"));
		vSMSDeliveryArr = DoAfterCheckOutGuestsNotificationDelivery(vTemplates);
	ElsIf DeliveryTemplate = Enums.AutoDeliveryTemplates.BeforeCheckInGuestsNotification Then
		WriteLogEvent(NStr("en='DataProcessor.AutoSMSDelivery';ru='Обработка.АвтоматизированнаяРассылкаСообщений';de='DataProcessor.AutoSMSDelivery'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Send to before check-in guests';ru='Рассылка до заезда гостей';de='Vor dem Check-in an Gäste senden'"));
		vSMSDeliveryArr = DoBeforeCheckInGuestsNotificationDelivery(vTemplates);
	ElsIf DeliveryTemplate = Enums.AutoDeliveryTemplates.AllClientsBirthdayCongratulation Then
		WriteLogEvent(NStr("en='DataProcessor.AutoSMSDelivery';ru='Обработка.АвтоматизированнаяРассылкаСообщений';de='DataProcessor.AutoSMSDelivery'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Send birthday congratulations to the all clients';ru='Рассылка поздравлений с днем рождения по всей клиентской базе';de='Versand von Geburtstagsglückwünschen für alle Kunden'"));
		vSMSDeliveryArr = DoAllClientsBirthdayCongratulationDelivery(vTemplates);
	ElsIf DeliveryTemplate = Enums.AutoDeliveryTemplates.AllClientsImportantDatesCongratulation Then
		WriteLogEvent(NStr("en='DataProcessor.AutoSMSDelivery';ru='Обработка.АвтоматизированнаяРассылкаСообщений';de='DataProcessor.AutoSMSDelivery'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Sending congratulations on important dates to the entire client base';ru='Рассылка поздравлений с важными датами по всей клиентской базе';de='Senden von Glückwünschen zu wichtigen Terminen an den gesamten Kundenstamm'"));
		vSMSDeliveryArr = DoAllClientsImportantDatesCongratulationDelivery();
	EndIf;
	If pIsInteractive And vSMSDeliveryArr <> Undefined Then
		#IF CLIENT THEN
			For Each vRow In vSMSDeliveryArr Do
				vFrm = vRow.GetForm();
				vFrm.Open(); 
			EndDo;
		#ENDIF
	EndIf;
	
	If vSMSDeliveryArr <> Undefined Then
		For Each vSMSDelivery In vSMSDeliveryArr Do 
			WriteLogEvent(NStr("en='DataProcessor.AutoSMSDelivery';ru='Обработка.АвтоматизированнаяРассылкаСообщений';de='DataProcessor.AutoSMSDelivery'"), EventLogLevel.Information, ThisObject.Metadata(), vSMSDelivery, NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'")); 
		EndDo;  
	Else
		WriteLogEvent(NStr("en='DataProcessor.AutoSMSDelivery';ru='Обработка.АвтоматизированнаяРассылкаСообщений';de='DataProcessor.AutoSMSDelivery'"), EventLogLevel.Information, ThisObject.Metadata(), , NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'"));	
	EndIf;
EndProcedure // pmDoAutoDelivery
