
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
	// NOTHING SO FAR
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	#If Client Then
		OpenForm("DataProcessor.DiscountsAutoAssignment.Form", New Structure("DataProcessor", ThisObject.DataProcessor));
	#Else
		CalculateDiscounts(DiscountDimension, DiscountTypeRules, Hotel, DaysToCount, ClientType, StartDate, CountServiceGroup, CheckedOutOnly, RecipientEmail, CreateDiscountCards);
	#EndIf
EndProcedure // pmRun

// -----------------------------------------------------------------------------
// Data processors framework end
Function CalculateDiscounts(pDiscountDimension, pDiscountTypeRules, pHotel = Undefined, pDaysToCount = 0, pClientType = Undefined, pStartDate = Undefined, pCountServiceGroup = Undefined, pCheckedOutOnly = False, pEmail = Undefined, pCreateDiscountCards = False) Export
	
	vResult = New Structure("Table, SpreadsheetDocument, Error");
	vSpreadsheetDocument	= New SpreadsheetDocument;
	
	vTemplate 				= GetTemplate("AssignmentedDiscounts");
	vHeader					= vTemplate.GetArea("Header");
	vSpreadsheetDocument.Put(vHeader);

	vDiscountResult = New ValueTable;
	vDiscountResult.Columns.Add("DiscountCard");
	vDiscountResult.Columns.Add("Client");
	vDiscountResult.Columns.Add("OldDiscountType");
	vDiscountResult.Columns.Add("NewDiscountType");
	vDiscountResult.Columns.Add("ClientName");
	vDiscountResult.Columns.Add("Amount");
	vDiscountResult.Columns.Add("Nights");
	vDiscountResult.Columns.Add("CheckIns");
	
	vResult.Table 				= vDiscountResult;
	vResult.SpreadsheetDocument = vSpreadsheetDocument;
	vResult.Error				= "";
	// Calculate period
	If pStartDate <> Undefined Then
		vPeriodFrom = pStartDate;
	Else
		vPeriodFrom = Date("00010101");
	EndIf;
	
	vCurrentDate 	= CurrentSessionDate();
	
	If pDaysToCount > 0 Then
		vDaysToCountDate = vCurrentDate - tcCommonFunctionOnClientServer.cmOneDay() * pDaysToCount;
		If vDaysToCountDate > vPeriodFrom Then
			vPeriodFrom = vDaysToCountDate;	
		EndIf;
	EndIf;
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	ServiceGroupsServices.Service AS Service
	|INTO ServicesInGroup
	|FROM
	|	Catalog.ServiceGroups.Services AS ServiceGroupsServices
	|WHERE
	|	ServiceGroupsServices.Ref = &qServiceGroup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN &DiscountDimenstion = VALUE(Enum.AccumulatingDiscountDimensions.DiscountCard)
	|			THEN SalesTurnovers.DiscountCard
	|		ELSE NULL
	|	END AS DiscountCard,
	|	CASE
	|		WHEN &DiscountDimenstion = VALUE(Enum.AccumulatingDiscountDimensions.Client)
	|			THEN SalesTurnovers.Client
	|		ELSE NULL
	|	END AS Client,
	|	SUM(SalesTurnovers.SalesTurnover) AS SalesTurnover,
	|	SUM(SalesTurnovers.GuestDaysTurnover) AS GuestDaysTurnover,
	|	SUM(SalesTurnovers.GuestsCheckedInTurnover) AS GuestsCheckedInTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			,
	|			Period,
	|			CASE
	|					WHEN &qHotelFilled
	|						THEN Hotel = &qHotel
	|					ELSE TRUE
	|				END
	|				AND CASE
	|					WHEN &qClientTypeFilled
	|						THEN ClientType = &qClientType
	|					ELSE TRUE
	|				END
	|				AND CASE
	|					WHEN &qServiceGroupFilled
	|						THEN Service IN
	|								(SELECT
	|									services.Service
	|								FROM
	|									ServicesInGroup AS services)
	|					ELSE TRUE
	|				END
	|				AND CASE
	|					WHEN &DiscountDimenstion = VALUE(Enum.AccumulatingDiscountDimensions.DiscountCard)
	|						THEN DiscountCard <> VALUE(Catalog.DiscountCards.EmptyRef)
	|					ELSE TRUE
	|				END
	|				AND CASE
	|					WHEN &DiscountDimenstion = VALUE(Enum.AccumulatingDiscountDimensions.Client)
	|						THEN Client <> VALUE(Catalog.Clients.EmptyRef)
	|					ELSE TRUE
	|				END
	|				AND (Agent = VALUE(Catalog.Customers.EmptyRef)
	|					OR Agent <> VALUE(Catalog.Customers.EmptyRef)
	|						AND &qCountAgentType <> VALUE(Catalog.CustomerTypes.EmptyRef)
	|						AND Agent.CustomerType = &qCountAgentType)
	|				AND (NOT &qCheckedOutOnly
	|					OR &qCheckedOutOnly
	|						AND Folio.IsClosed
	|						AND AccountingDate < &qToday)) AS SalesTurnovers
	|
	|GROUP BY
	|	CASE
	|		WHEN &DiscountDimenstion = VALUE(Enum.AccumulatingDiscountDimensions.DiscountCard)
	|			THEN SalesTurnovers.DiscountCard
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN &DiscountDimenstion = VALUE(Enum.AccumulatingDiscountDimensions.Client)
	|			THEN SalesTurnovers.Client
	|		ELSE NULL
	|	END";
	
	vQuery.SetParameter("DiscountDimenstion", 	pDiscountDimension);
	vQuery.SetParameter("qCheckedOutOnly", 		pCheckedOutOnly);
	vQuery.SetParameter("qClientType", 			pClientType);
	vQuery.SetParameter("qClientTypeFilled", 	ValueIsFilled(pClientType));
	vQuery.SetParameter("qHotel", 				pHotel);
	vQuery.SetParameter("qHotelFilled", 		ValueIsFilled(pHotel));
	vQuery.SetParameter("qPeriodFrom", 			vPeriodFrom);
	vQuery.SetParameter("qServiceGroup", 		pCountServiceGroup);
	vQuery.SetParameter("qServiceGroupFilled", 	ValueIsFilled(pCountServiceGroup));
	vQuery.SetParameter("qCountAgentType",		CountAgentType);
	vQuery.SetParameter("qToday",				BegOfDay(CurrentSessionDate()));
	
	vQueryResult = vQuery.Execute().Unload();
	
	For Each vQueryResultRow In vQueryResult Do
		If ValueIsFilled(vQueryResultRow.Client) And vDiscountResult.Find(vQueryResultRow.Client, "Client") = Undefined 
			Or ValueIsFilled(vQueryResultRow.DiscountCard) And vDiscountResult.Find(vQueryResultRow.DiscountCard, "DiscountCard") = Undefined Then
			
			vID = pDiscountTypeRules.Count() - 1;
			
			If pDiscountDimension = Enums.AccumulatingDiscountDimensions.Client And pCreateDiscountCards Then
				vClient = vQueryResultRow.Client;
				If ValueIsFilled(vClient) Then
					vQueryResultRow.DiscountCard = vClient.DiscountCard;
				EndIf;
			EndIf;
			
			While vID >= 0 Do 
				vRule 			= pDiscountTypeRules[vID];
				vAmountCheck 	= True;
				vNightsCheck 	= True;
				vCheckInsCheck 	= True;
				
				If Not ValueIsFilled(vRule.DiscountType) Then
					vID = vID - 1;
					Continue;
				EndIf;
				
				If DoNotDowngradeDiscountType Then
					vDiscountCard = vQueryResultRow.DiscountCard;
					If ValueIsFilled(vDiscountCard) And vDiscountCard.DiscountType = vRule.DiscountType Then
						Break;
					EndIf;
					vClient = vQueryResultRow.Client;
					If ValueIsFilled(vClient) And vClient.DiscountType = vRule.DiscountType Then
						Break;
					EndIf;
				EndIf;
				
				If vRule.Amount > 0 Then
					If vQueryResultRow.SalesTurnover >= vRule.Amount Then
						vAmountCheck = True;
					Else
						vAmountCheck = False;
					EndIf;	
				EndIf;
				
				If vRule.Nights > 0 Then
					If vQueryResultRow.GuestDaysTurnover >= vRule.Nights Then
						vNightsCheck = True;
					Else
						vNightsCheck = False;
					EndIf;	
				EndIf;
				
				If vRule.CheckIns > 0 Then
					If vQueryResultRow.GuestsCheckedInTurnover >= vRule.CheckIns Then
						vCheckInsCheck = True;
					Else
						vCheckInsCheck = False;
					EndIf;
				EndIf;
				
				If vAmountCheck And vNightsCheck And vCheckInsCheck Then
					vNewDiscount 					= vDiscountResult.Add();
					If ValueIsFilled(vQueryResultRow.DiscountCard) Then
						vNewDiscount.DiscountCard 		= vQueryResultRow.DiscountCard;
						vNewDiscount.OldDiscountType 	= vQueryResultRow.DiscountCard.DiscountType;
						vNewDiscount.ClientName			= vQueryResultRow.DiscountCard.Client.LastName + " " + vQueryResultRow.DiscountCard.Client.FirstName + " " + vQueryResultRow.DiscountCard.Client.SecondName;
					Else
						vNewDiscount.Client 			= vQueryResultRow.Client;
						vNewDiscount.OldDiscountType 	= vQueryResultRow.Client.DiscountType;
						vNewDiscount.ClientName			= vQueryResultRow.Client.LastName + " " + vQueryResultRow.Client.FirstName + " " + vQueryResultRow.Client.SecondName;
					EndIf;				
					vNewDiscount.Amount 			= vQueryResultRow.SalesTurnover;
					vNewDiscount.Nights 			= vQueryResultRow.GuestDaysTurnover;
					vNewDiscount.CheckIns 			= vQueryResultRow.GuestsCheckedInTurnover;
					vNewDiscount.NewDiscountType 	= vRule.DiscountType;
					Break;
				EndIf;
				vID = vID - 1;
			EndDo;
		EndIf;
	EndDo;
	
	vClearArray = New Array;
	For Each vDiscount In vDiscountResult Do  
		Try
			vIsNewDiscountCard = False;
			If pDiscountDimension = Enums.AccumulatingDiscountDimensions.Client And (Not ValueIsFilled(vDiscount.DiscountCard) Or (ValueIsFilled(vDiscount.DiscountCard) And vDiscount.DiscountCard.LoyaltyType <> vDiscount.NewDiscountType.LoyaltyType)) And pCreateDiscountCards Then
				If IsBlankString(vDiscount.Client.Phone) Then
					vClearArray.Add(vDiscount);
					Continue;
				EndIf;
				vDiscount.DiscountCard = GetDiscountCardByClient(pHotel, vDiscount.Client, vDiscount.NewDiscountType, vIsNewDiscountCard);
				If vIsNewDiscountCard Then
					vDiscount.OldDiscountType = Catalogs.DiscountCards.EmptyRef();
				Else
					vDiscount.OldDiscountType = vDiscount.DiscountCard.DiscountType;
				EndIf;
			EndIf;
			If vIsNewDiscountCard  Then
				Continue;
			EndIf;
			
			If vDiscount.OldDiscountType = vDiscount.NewDiscountType Then
				vClearArray.Add(vDiscount);
				Continue;
			EndIf;
			
			If ValueIsFilled(vDiscount.DiscountCard) Then
				vObj = vDiscount.DiscountCard.GetObject();
			Else
				vObj = vDiscount.Client.GetObject();
			EndIf;
			
			vObj.DiscountType = vDiscount.NewDiscountType;
			vObj.Write();
		Except
			vResult.Error = vResult.Error + Chars.LF + ErrorDescription();
		EndTry;
	EndDo;
			
	For Each vRow In vClearArray Do
		vDiscountResult.Delete(vRow);
	EndDo;
	
	For Each vDiscount In vDiscountResult Do
		vRow = vTemplate.GetArea("Row");
		
		vRow.Parameters.FullName 	= vDiscount.ClientName;
		vRow.Parameters.OldDiscount = vDiscount.OldDiscountType;
		vRow.Parameters.NewDiscount = vDiscount.NewDiscountType;
		vRow.Parameters.Nights 		= vDiscount.Nights;
		vRow.Parameters.CheckIns 	= vDiscount.CheckIns;
		vRow.Parameters.Amount 		= vDiscount.Amount;
		
		vSpreadsheetDocument.Put(vRow);	
	EndDo;
	
	If vDiscountResult.Count() > 0 Then
		SendToEmail(pEmail, vDiscountResult, pHotel);
	EndIf;
	
	vResult.Table 				= vDiscountResult;
	vResult.SpreadsheetDocument = vSpreadsheetDocument;
	
	Return vResult;
	
EndFunction // CalculateDiscounts_ObjectData

// -----------------------------------------------------------------------------
// Description: Sends file by e-mail
// Parameters: Message subject, Message text, E-Mails list, File name to attach, 
//             Full file name to attach, Language, Whether fuction is called in 
//             the application server context, Guest group
// Return value: True if success, False if not
// -----------------------------------------------------------------------------
Function SendByEMail(pSubject, pMessage, pEMails, pFileName = Undefined, pFullFileName = Undefined, pLanguage = Undefined, pIsOnServer = False, pGuestGroup = Undefined, pSenderName = "") Export
	vLanguage = pLanguage;
	If Not ValueIsFilled(vLanguage) Then
		vLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	
	// Get current employee settings
	vCurEmployee = SessionParameters.CurrentUser; 
	vFuncName = NStr("en = 'InternetMail.SendFile'; de = 'InternetMail.SendFile'; ru = 'ЭлектроннаяПочта.ОтправитьФайл'");
	If Not ValueIsFilled(vCurEmployee) Then
		vError = NStr("ru = 'Невозможно отправить файл " + TrimAll(pFileName) + " по электронной почте на адрес " + TrimAll(pEMails) + "! Не определен текущий пользователь!'; 
		|de = 'Unable to send file " + TrimAll(pFileName) + " by e-mail to " + TrimAll(pEMails) + "! Current user is not defined!'; 
		|en = 'Unable to send file " + TrimAll(pFileName) + " by e-mail to " + TrimAll(pEMails) + "! Current user is not defined!'");
		tcCommonFunctionOnClientServer.TextMessage(vError, MessageStatus.Attention);
		WriteLogEvent(vFuncName, EventLogLevel.Warning, , , vError);
		If pIsOnServer Then
			Raise vError;
		EndIf;
		Return False;
	EndIf;
	vFileName = Undefined;
	If pFileName <> Undefined Then
		// Remove forbidden chars from file name
		vFileName = cmGetValidFileName(pFileName);
	EndIf;
	
	Try
		// Addresses and names 
		vSenderName = "";
		If Not IsBlankString(pSenderName) Then
			vSenderName = pSenderName;
		Else
			vSenderName = vCurEmployee.GetObject().pmGetEmployeeDescription(vLanguage);
		EndIf;
		
		// Add ReplyTo address
		vReplyToEMail = New Array;
		If Not IsBlankString(vCurEmployee.ReplyToEMail) Then
			vEMailsList = cmParseEMailAddress(TrimAll(vCurEmployee.ReplyToEMail));
			For Each vEMailItem In vEMailsList Do
				vReplyToEMail.Add(TrimAll(vEMailItem.Value));
			EndDo;
		EndIf;  
		
		// Add to address
		vToEMail = New Array;
		vEMailsList = cmParseEMailAddress(pEMails);
		For Each vEMailItem In vEMailsList Do
			vToEMail.Add(TrimAll(vEMailItem.Value));
		EndDo; 
		
		// Add Bcc address  
		vBccEMail = New Array;
		If Not IsBlankString(vCurEmployee.BccEMail) Then
			vEMailsList = cmParseEMailAddress(vCurEmployee.BccEMail);
			For Each vEMailItem In vEMailsList Do
				vBccEMail.Add(TrimAll(vEMailItem.Value));
			EndDo;
		EndIf;  
		
		// Add file as attachement
		vAttachments = New Array;
		If vFileName <> Undefined Then
			vAttachment = New Map;
			vAttachment.Insert("FullFileName", pFullFileName);
			vAttachment.Insert("FileName", vFileName);
			vAttachments.Add(vAttachment);
		EndIf;
		
		Email.Send(vCurEmployee, vSenderName, TrimAll(vCurEmployee.EMail), TrimAll(pSubject), TrimAll(pMessage), , , , , , , vAttachments, vToEMail, vReplyToEMail, , vBccEMail);
	Except
		vError = NStr("ru = 'Невозможно отправить файл " + TrimAll(pFileName) + " по электронной почте на адрес " + TrimAll(pEMails) + "! Описание ошибки: '; 
		|de = 'Unable to send file " + TrimAll(pFileName) + " by e-mail to " + TrimAll(pEMails) + "! Error description: ';
		|en = 'Unable to send file " + TrimAll(pFileName) + " by e-mail to " + TrimAll(pEMails) + "! Error description: '") + ErrorDescription();
		tcCommonFunctionOnClientServer.TextMessage(vError, MessageStatus.Attention);
		WriteLogEvent(vFuncName, EventLogLevel.Warning, , , vError);
		If pIsOnServer Then
			Raise vError;
		EndIf;
		Return False;
	EndTry;
	
	// Write guest group attachment that message was sent
	Try
		If ValueIsFilled(pGuestGroup) Then
			vGrpAttachmentsRecMgr = InformationRegisters.GuestGroupAttachments.CreateRecordManager();
			vGrpAttachmentsRecMgr.Period = CurrentSessionDate();
			vGrpAttachmentsRecMgr.GuestGroup = pGuestGroup;
			vGrpAttachmentsRecMgr.EMail = pEMails;
			If ValueIsFilled(pGuestGroup.Client) Then
				vGrpAttachmentsRecMgr.Fax = pGuestGroup.Client.Fax;
			EndIf;
			vGrpAttachmentsRecMgr.AttachmentStatus = Enums.AttachmentStatuses.Sent;
			vGrpAttachmentsRecMgr.AttachmentType = Enums.AttachmentTypes.EMail;
			vLanguage = pGuestGroup.Owner.Language;
			If ValueIsFilled(pGuestGroup.Client) And ValueIsFilled(pGuestGroup.Client.Language) Then
				vLanguage = pGuestGroup.Client.Language;
			EndIf;
			vGrpAttachmentsRecMgr.Remarks = TrimAll(pSubject); 
			vGrpAttachmentsRecMgr.DocumentText = TrimAll(pMessage);
			vFile = New File(pFullFileName);
			If tcCommonFunctionOnClientServer.cmExists(vFile) And vFile.IsFile() Then
				vGrpAttachmentsRecMgr.FileName = vFileName;
				vGrpAttachmentsRecMgr.FileLoadTime = CurrentSessionDate();
				vGrpAttachmentsRecMgr.FileLastChangeTime = vFile.GetModificationTime();
				vBinary = New BinaryData(pFullFileName);
				vGrpAttachmentsRecMgr.ExtFile = New ValueStorage(vBinary);
			EndIf;
			// Write attachment
			vGrpAttachmentsRecMgr.Write();
		EndIf;
	Except
		vError = NStr("ru = 'Ошибка регистрации факта отправки сообщения " + TrimAll(pFileName) + " по электронной почте на адрес " + TrimAll(pEMails) + "! Описание ошибки: '; 
		|de = 'Failed to write guest group attachment for e-mail message " + TrimAll(pFileName) + " to " + TrimAll(pEMails) + "! Error description: ';
		|en = 'Failed to write guest group attachment for e-mail message " + TrimAll(pFileName) + " to " + TrimAll(pEMails) + "! Error description: '") + ErrorDescription();
		tcCommonFunctionOnClientServer.TextMessage(vError, MessageStatus.Attention);
		WriteLogEvent(vFuncName, EventLogLevel.Error, , , vError);
	EndTry;
	
	// Return success
	Return True;
EndFunction // SendByEMail

// -----------------------------------------------------------------------------
Function CalculateDiscounts_ObjectData() Export
	Return CalculateDiscounts(DiscountDimension, DiscountTypeRules, Hotel, DaysToCount, ClientType, StartDate, CountServiceGroup, CheckedOutOnly, RecipientEmail, CreateDiscountCards);
EndFunction // CalculateDiscounts_ObjectData

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function SendToEmail(pEmail, pDiscountResult, pHotel)
	If Not ValueIsFilled(pEmail) Or pDiscountResult = Undefined Then
		Return Undefined;
	EndIf;
	
	vHotelPrintName = ?(ValueIsFilled(pHotel), pHotel.GetObject().pmGetHotelPrintName(Undefined), "1C:Hotel");
	
	// Sender name
	vSenderName = vHotelPrintName;
	// Initialize message texts
	MessageSubject 	= vHotelPrintName + NStr("en = ' Discounts auto assignment'; de = ' Rabatte auto-Zuweisung'; ru = ' Автоназначение скидок'");
	MessageText 	= NStr("en = 'Were established new discounts to customers:'; de = 'Es wurden neue Rabatte für Käufer festgelegt:'; ru = 'Были установлены новые скидки клиентам:'");
	vID = 1;
	For Each vRow In pDiscountResult Do
		vRowText	= String(vID) + ") " + (vRow.ClientName);
		vRowText	= vRowText + NStr("en = ', discount: '; de = ', Rabatt: '; ru = ', скидка: '") + vRow.OldDiscountType + " => " + vRow.NewDiscountType;
		vRowText	= vRowText + NStr("en = ', nights: '; de = ', Nächte: '; ru = ', ночей: '") + vRow.Nights;
		vRowText	= vRowText + NStr("en = ', check-ins: '; de = ', check-ins: '; ru = ', заездов: '") + vRow.CheckIns;
		vRowText	= vRowText + NStr("en = ', amount: '; de = ', amount: '; ru = ', сумма: '") + vRow.Amount;
		MessageText = MessageText + chars.LF + vRowText;
		vID = vID + 1;
	EndDo;
	// Send file in modal mode to get and show result
	vResult = SendByEMail(MessageSubject, MessageText, pEmail, , , , , , vSenderName);
	Return vResult;
EndFunction

// -----------------------------------------------------------------------------
Function GetDiscountCardByClient(pHotel, pClient, pDiscountType, rIsNewDiscountCard)
	vDiscountCard= Catalogs.DiscountCards.EmptyRef();
	
	vClientDiscountCard = pClient.DiscountCard;
	If ValueIsFilled(vClientDiscountCard) And vClientDiscountCard.LoyaltyType = pDiscountType.LoyaltyType Then
		vDiscountCard = vClientDiscountCard;
	EndIf;
	
	If Not ValueIsFilled(vDiscountCard) Then
		vDCObj = Catalogs.DiscountCards.CreateItem();
		
		vDCObj.DiscountType = pDiscountType;
		vDCObj.LoyaltyType = pDiscountType.LoyaltyType;
		If pDiscountType.Validity > 0 Then
			vDCObj.ValidFrom = BegOfDay(CurrentSessionDate());
			vDCObj.ValidTo = vDCObj.ValidFrom + pDiscountType.Validity * 86400;
		EndIf;
		vDCObj.CreateHotel = pHotel;
		vDCObj.Client = pClient;
		// Create discount card folio
		vDCObj.Folio = Catalogs.DiscountCards.CreateFolio(TrimAll(vDCObj.Identifier), vDCObj.LoyaltyType, vDCObj.Client, vDCObj.Customer);
		vDCObj.SetNewCode();
		
		vID = TrimAll(pClient.Phone);
		If IsBlankString(vID) Then
			vID = TrimAll(vDCObj.Code);
		EndIf;
		
		vDCObj.Identifier = TrimAll(vID);
		
		// Save discount card
		vDCObj.Description = Catalogs.DiscountCards.GetCardDescription(vDCObj);
		vDCObj.Write();
		
		vDiscountCard = vDCObj.Ref;
		
		vClientobj = pClient.GetObject();
		vClientobj.DiscountCard = vDiscountCard;
		vClientobj.Write();
		rIsNewDiscountCard = True;
	EndIf;
	
	Return vDiscountCard;
EndFunction // GetDiscountCardByClient

#EndRegion
