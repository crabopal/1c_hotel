Var TCPIP;
Var CSWSOCK6_LICENSE_KEY;
Var CSWSOCK10_LICENSE_KEY;
Var ActiveGuestMessages;

// -----------------------------------------------------------------------------
Var ACK;
Var NAK;
Var STX;
Var ETX;

// -----------------------------------------------------------------------------
Var TRID;

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
	If EclipsePort = 0 Then
		EclipsePort = 9891;
	EndIf;
	If IsBlankString(EclipseAddress) Then
		EclipseAddress = "127.0.0.1";
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	// Start interface client
	pmRunInterfaceClient(pIsInteractive);
EndProcedure // pmRun

// -----------------------------------------------------------------------------
// Data processors framework end
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure pmRunInterfaceClient(pIsInteractive = False) Export
	If Not IsBlankString(EclipseAddress) And EclipsePort <> 0 Then
		If IsRunning And (tcOnServer.cmGetServerCurrentSessionDate() - Timestamp) < 120 Then
			Return;
		EndIf;
		IsRunning = True;
		StopInterface = False;
		Timestamp = tcOnServer.cmGetServerCurrentSessionDate();
		pmSaveDataProcessorAttributes();
		// Create client ActiveX object
		Try
		    TCPIP = New COMObject("SocketTools.SocketWrench.10");
			// Load license
			vErrorCode = TCPIP.Initialize(CSWSOCK10_LICENSE_KEY);
		Except
			TCPIP = New COMObject("SocketTools.SocketWrench.6");
			// Load license
			vErrorCode = TCPIP.Initialize(CSWSOCK6_LICENSE_KEY);
		EndTry;
		// Initialize parameters
		TCPIP.Blocking = True;
		TCPIP.Timeout = 10; // 10 seconds blocking read timeout by default
		vErrorCode = TCPIP.Connect(StrReplace(EclipseAddress, " ", ""), EclipsePort);
		If vErrorCode <> 0 Then
			DoMessage(NStr("ru = 'Не найден сервер системы Eclipse: '; en = 'Eclipse system server was not found: '") + vErrorCode + " - " + TCPIP.LastErrorString);
			TCPIP = Undefined;
			IsRunning = False;
			StopInterface = False;
			Timestamp = Undefined;
			pmSaveDataProcessorAttributes();
			Return;
		Else
			If DebugMode Then
				DoMessage("PMS -> Locatel Eclipse. Connection successfull");
			EndIf;
		EndIf;     
		vData = "";
		If TCPIP.Read(vData, 1024) <> -1 Then
			vBreak = ProcessEventsFromEclipse(vData);
			If Not vBreak Then
				DoMessage("Locatel Eclipse -> PMS. Reply to CONNECT. Unexpected data received: " + GetDataPresentation(vData), MessageStatus.Attention);
				TCPIP.Disconnect();
				TCPIP = Undefined;
				IsRunning = False;
				StopInterface = False;
				Timestamp = Undefined;
				pmSaveDataProcessorAttributes();
				Return;
			EndIf;
		Else
			If DebugMode Then
				DoMessage("Locatel Eclipse -> PMS. Reply to CONNECT. Data NOT received!");
			EndIf;
		EndIf;
		// Send STRT
		vData = GetSTRTMessage();
		If DebugMode Then
			DoMessage("PMS -> Locatel Eclipse. STRT message. Data going to be written: " + GetDataPresentation(vData));
		EndIf;
		If TCPIP.Write(vData, StrLen(vData)) <> -1 Then
			vData = "";
			If TCPIP.Read(vData, 1024) <> -1 Then
				If Find(vData, "VER ") > 0 Then
					If DebugMode Then
						DoMessage("Locatel Eclipse -> PMS. Reply to STRT. Data received: " + GetDataPresentation(vData));
					EndIf;
					// Send HELO
					vData = GetHELOMessage();
					If DebugMode Then
						DoMessage("PMS -> Locatel Eclipse. HELO message. Data going to be written: " + GetDataPresentation(vData));
					EndIf;
					If TCPIP.Write(vData, StrLen(vData)) <> -1 Then
						vData = "";
						If TCPIP.Read(vData, 1024) <> -1 Then
							If Find(vData, "VER ") > 0 Then
								If DebugMode Then
									DoMessage("Locatel Eclipse -> PMS. Reply to HELO. Data received: " + GetDataPresentation(vData));
								EndIf;
								// Go to main processing cycle
								While DoMainProcessingCycle() Do
									pmLoadDataProcessorAttributes();
									If StopInterface Then
										Break;
									EndIf;
									#IF CLIENT THEN
										IsRunning = False;
										pmSaveDataProcessorAttributes();
										UserInterruptProcessing();
									#ENDIF
								EndDo;
							Else
								DoMessage("Locatel Eclipse -> PMS. Reply to HELO. Data received: " + GetDataPresentation(vData), MessageStatus.Attention);
							EndIf;
						Else
							DoMessage("Locatel Eclipse -> PMS. Reply to HELO. Data received: " + GetDataPresentation(vData), MessageStatus.Attention);
						EndIf;
					Else
						DoMessage("PMS -> Locatel Eclipse. Send HELO. Data NOT written!", MessageStatus.Attention);
					EndIf;	
				Else
					DoMessage("Locatel Eclipse -> PMS. Reply to STRT. Data received: " + GetDataPresentation(vData), MessageStatus.Attention);
				EndIf;
			Else
				DoMessage("Locatel Eclipse -> PMS. Reply to STRT. Data NOT received!", MessageStatus.Attention);
			EndIf;
		Else
			DoMessage("PMS -> Locatel Eclipse. Send STRT. Data NOT written!", MessageStatus.Attention);
		EndIf;
		vErrorCode = TCPIP.Disconnect();
		If vErrorCode <> 0 Then
			DoMessage(NStr("ru = 'Ошибка отключения от сервера Eclipse: '; en = 'Eclipse server disconnect error: '") + vErrorCode, MessageStatus.Attention);
		EndIf;  
		IsRunning = False;
		StopInterface = False;
		Timestamp = Undefined;
		pmSaveDataProcessorAttributes();
	Else
		DoMessage(NStr("en='Server connection parameters are missing...'; ru='Не указаны параметры подключения к серверу Eclipse...'; de='Server-Verbindung Parameter fehlen...'"));
	EndIf;
EndProcedure // pmRunInterfaceClient

// -----------------------------------------------------------------------------
Function GetDataPresentation(pData) 
	Return StrReplace(StrReplace(pData, STX, "[STX]"), ETX, "[ETX]");
EndFunction // GetDataPresentation

// -----------------------------------------------------------------------------
Function Transliterate(pStr)
	If Not DoTransliterate Then
		Return pStr;
	EndIf;
	vStr = pStr;
	vStr = StrReplace(vStr, "А", "A");
	vStr = StrReplace(vStr, "Б", "B");
	vStr = StrReplace(vStr, "В", "V");
	vStr = StrReplace(vStr, "Г", "G");
	vStr = StrReplace(vStr, "Д", "D");
	vStr = StrReplace(vStr, "Е", "E");
	vStr = StrReplace(vStr, "Ё", "E");
	vStr = StrReplace(vStr, "Ж", "Zh");
	vStr = StrReplace(vStr, "З", "Z");
	vStr = StrReplace(vStr, "И", "I");
	vStr = StrReplace(vStr, "Й", "Y");
	vStr = StrReplace(vStr, "К", "K");
	vStr = StrReplace(vStr, "Л", "L");
	vStr = StrReplace(vStr, "М", "M");
	vStr = StrReplace(vStr, "Н", "N");
	vStr = StrReplace(vStr, "О", "O");
	vStr = StrReplace(vStr, "П", "P");
	vStr = StrReplace(vStr, "Р", "R");
	vStr = StrReplace(vStr, "С", "S");
	vStr = StrReplace(vStr, "Т", "T");
	vStr = StrReplace(vStr, "У", "U");
	vStr = StrReplace(vStr, "Ф", "F");
	vStr = StrReplace(vStr, "Х", "H");
	vStr = StrReplace(vStr, "Ц", "C");
	vStr = StrReplace(vStr, "Ч", "Ch");
	vStr = StrReplace(vStr, "Ш", "Sh");
	vStr = StrReplace(vStr, "Щ", "Sch");
	vStr = StrReplace(vStr, "Ь", "'");
	vStr = StrReplace(vStr, "Ы", "Yi");
	vStr = StrReplace(vStr, "Ъ", "");
	vStr = StrReplace(vStr, "Э", "E");
	vStr = StrReplace(vStr, "Ю", "Yu");
	vStr = StrReplace(vStr, "Я", "Ya");
	vStr = StrReplace(vStr, "а", "a");
	vStr = StrReplace(vStr, "б", "b");
	vStr = StrReplace(vStr, "в", "v");
	vStr = StrReplace(vStr, "г", "g");
	vStr = StrReplace(vStr, "д", "d");
	vStr = StrReplace(vStr, "е", "e");
	vStr = StrReplace(vStr, "ё", "e");
	vStr = StrReplace(vStr, "ж", "zh");
	vStr = StrReplace(vStr, "з", "z");
	vStr = StrReplace(vStr, "и", "i");
	vStr = StrReplace(vStr, "й", "y");
	vStr = StrReplace(vStr, "к", "k");
	vStr = StrReplace(vStr, "л", "l");
	vStr = StrReplace(vStr, "м", "m");
	vStr = StrReplace(vStr, "н", "n");
	vStr = StrReplace(vStr, "о", "o");
	vStr = StrReplace(vStr, "п", "p");
	vStr = StrReplace(vStr, "р", "r");
	vStr = StrReplace(vStr, "с", "s");
	vStr = StrReplace(vStr, "т", "t");
	vStr = StrReplace(vStr, "у", "u");
	vStr = StrReplace(vStr, "ф", "f");
	vStr = StrReplace(vStr, "х", "h");
	vStr = StrReplace(vStr, "ц", "c");
	vStr = StrReplace(vStr, "ч", "ch");
	vStr = StrReplace(vStr, "ш", "sh");
	vStr = StrReplace(vStr, "щ", "sch");
	vStr = StrReplace(vStr, "ь", "'");
	vStr = StrReplace(vStr, "ы", "yi");
	vStr = StrReplace(vStr, "ъ", "");
	vStr = StrReplace(vStr, "э", "e");
	vStr = StrReplace(vStr, "ю", "yu");
	vStr = StrReplace(vStr, "я", "ya");
	Return vStr;
EndFunction // Transliterate

// -----------------------------------------------------------------------------
// Description: Returns value table with folio transactions for accommodations or reservations. 
// Parameters: Value list with documents to return transactions for, Hotel
// Return value: Value table
// -----------------------------------------------------------------------------
Function GetDocumentListTransactions(pDocList, pHotel)
	// Build and run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accounts.Period,
	|	Accounts.TransactionItem,
	|	Accounts.Amount,
	|	Accounts.IsPayment,
	|	Accounts.IsClientItem,
	|	Accounts.FolioCurrency,
	|	Accounts.FolioParentDoc
	|FROM
	|	(SELECT
	|		ClientAccounts.Period AS Period,
	|		CASE
	|			WHEN ClientAccounts.RecordType = &qExpense
	|				THEN ClientAccounts.PaymentMethod
	|			ELSE ClientAccounts.Service
	|		END AS TransactionItem,
	|		ClientAccounts.FolioCurrency AS FolioCurrency,
	|		ClientAccounts.Folio.ParentDoc AS FolioParentDoc,
	|		CASE
	|			WHEN ClientAccounts.RecordType = &qExpense
	|				THEN -ClientAccounts.Sum
	|			ELSE ClientAccounts.Sum
	|		END AS Amount,
	|		CASE
	|			WHEN ClientAccounts.RecordType = &qExpense
	|				THEN TRUE
	|			ELSE FALSE
	|		END AS IsPayment,
	|		TRUE AS IsClientItem
	|	FROM
	|		AccumulationRegister.Accounts AS ClientAccounts
	|	WHERE
	|		ClientAccounts.Period < &qBalancesPeriod
	|		AND (ClientAccounts.Folio.Customer = &qEmptyCustomer
	|				OR ClientAccounts.Folio.Customer <> &qEmptyCustomer AND ClientAccounts.Folio.Customer.IsIndividual)
	|		AND ClientAccounts.Folio.ParentDoc IN(&qDocList)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CustomerAccounts.Period,
	|		CASE
	|			WHEN CustomerAccounts.RecordType = &qExpense
	|				THEN CustomerAccounts.PaymentMethod
	|			ELSE CustomerAccounts.Service
	|		END,
	|		CustomerAccounts.FolioCurrency,
	|		CustomerAccounts.Folio.ParentDoc,
	|		CASE
	|			WHEN CustomerAccounts.RecordType = &qExpense
	|				THEN -CustomerAccounts.Sum
	|			ELSE CustomerAccounts.Sum
	|		END,
	|		CASE
	|			WHEN CustomerAccounts.RecordType = &qExpense
	|				THEN TRUE
	|			ELSE FALSE
	|		END,
	|		FALSE
	|	FROM
	|		AccumulationRegister.Accounts AS CustomerAccounts
	|	WHERE
	|		CustomerAccounts.Period < &qBalancesPeriod
	|		AND CustomerAccounts.Folio.Customer <> &qEmptyCustomer
	|		AND NOT CustomerAccounts.Folio.Customer.IsIndividual
	|		AND CustomerAccounts.Folio.ParentDoc IN(&qDocList)) AS Accounts
	|
	|ORDER BY
	|	Accounts.Period";
	vQry.SetParameter("qBalancesPeriod", ?(ValueIsFilled(pHotel), ?(pHotel.ShowDebtsOnCurrentDate, CurrentSessionDate(), '39991231235959'), '39991231235959'));
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	vQry.SetParameter("qDocList", pDocList);
	vQry.SetParameter("qExpense", AccumulationRecordType.Expense);
	Return vQry.Execute().Unload();
EndFunction // GetDocumentListTransactions

// -----------------------------------------------------------------------------
Function GetRoomTransactions(pAccDocRef)
	vOneRoomAccommodations = cmGetOneRoomAccommodations(pAccDocRef.Room, pAccDocRef.GuestGroup, pAccDocRef.CheckInDate, pAccDocRef.CheckOutDate);
	vItems = GetDocumentListTransactions(vOneRoomAccommodations, pAccDocRef.Hotel);
	Return vItems;
EndFunction // GetRoomTransactions

// -----------------------------------------------------------------------------
Function GetNextTRID()
	vTRID = TRID + 1;
	If vTRID > 999 Then
		vTRID = 0;
	EndIf;
	TRID = vTRID;
	Return vTRID;
EndFunction // GetNextTRID
 
// -----------------------------------------------------------------------------
Function GetSTRTMessage()
	vTRID = GetNextTRID();
	vData = "X" + Format(vTRID, "ND=3; NFD=0; NZ=; NLZ=; NG=") + "9999" + "STRT" + ETX;
	vData = STX + vData + cmCharLRC(vData, False);
	Return vData;
EndFunction // GetSTRTMessage
 
// -----------------------------------------------------------------------------
Function GetHELOMessage()
	vTRID = GetNextTRID();
	vData = "X" + Format(vTRID, "ND=3; NFD=0; NZ=; NLZ=; NG=") + "9999" + "HELO" + "1CHOTEL8" + "2232" + "YNNNNNNNNYYN2                                        " + ETX;
	vData = STX + vData + cmCharLRC(vData, False);
	Return vData;
EndFunction // GetHELOMessage
 
// -----------------------------------------------------------------------------
Function GetCHKIMessage(pEventRow)
	vTRID = GetNextTRID();
	vData = "X" + Format(vTRID, "ND=3; NFD=0; NZ=; NLZ=; NG=") + "9999" + "CHKI" + cmAppendBlanks(Left(TrimAll(pEventRow.Room), 6), 6) + ETX;
	vData = STX + vData + cmCharLRC(vData, False);
	Return vData;
EndFunction // GetCHKIMessage

// -----------------------------------------------------------------------------
Function GetGuestLanguageCode(pAccDocRef)
	vLangCode = " ";
	If ValueIsFilled(pAccDocRef) And ValueIsFilled(pAccDocRef.Guest) And ValueIsFilled(pAccDocRef.Guest.Language) Then
		vLanguage = pAccDocRef.Guest.Language;
		If vLanguage = Catalogs.Languages.RU Then
			vLangCode = "R";
		ElsIf vLanguage = Catalogs.Languages.EN Then
			vLangCode = "E";
		//ElsIf vLanguage = Catalogs.Languages.DE Then
		//	vLangCode = "G";
		EndIf;
	EndIf;
	Return vLangCode;
EndFunction // GetGuestLanguageCode

// -----------------------------------------------------------------------------
Function GetINFOMessage(pTRID, pAccDocRef)
	vData = pTRID + "9999" + "INFO" + 
	        cmAppendBlanks(Left(TrimAll(pAccDocRef.Room), 6), 6) + 
	        Format(Number(cmGetDocumentNumberPresentation(pAccDocRef.ChargingRules.Get(pAccDocRef.ChargingRules.Count() - 1).ChargingFolio.Number)), "ND=6; NFD=0; NZ=; NLZ=; NG=") + 
			?(ValueIsFilled(pAccDocRef.Guest), cmAppendBlanks(Left(Transliterate(TrimAll(TrimAll(pAccDocRef.Guest.FirstName) + " " + TrimAll(pAccDocRef.Guest.SecondName))), 20), 20), "                    ") + 
			"N" +     // Message waiting indicator
			"     " + // Group name
			" " +     // Bill view indicator
			" " +     // Check-out indicator
			GetGuestLanguageCode(pAccDocRef) + // Language indicator
			" " +     // Welcome indicator
			"   " +   // Rights ID indicator
			ETX;
	vData = STX + vData + cmCharLRC(vData, False);
	Return vData;
EndFunction // GetINFOMessage
 
// -----------------------------------------------------------------------------
Function GetNAMEMessage(pTRID, pSeqID, pAccDocRef)
	vData = pTRID + Format(pSeqID, "ND=4; NFD=0; NZ=; NLZ=; NG=") + "NAME" + 
	        cmAppendBlanks(Left(TrimAll(pAccDocRef.Room), 6), 6) + 
	        Format(Number(cmGetDocumentNumberPresentation(pAccDocRef.ChargingRules.Get(pAccDocRef.ChargingRules.Count() - 1).ChargingFolio.Number)), "ND=6; NFD=0; NZ=; NLZ=; NG=") + 
			?(ValueIsFilled(pAccDocRef.Guest), cmAppendBlanks(Left(Transliterate(TrimAll(TrimAll(pAccDocRef.Guest.FirstName) + " " + TrimAll(pAccDocRef.Guest.SecondName))), 20), 20), "                    ") + 
			"N" +     // Message waiting indicator
			ETX;
	vData = STX + vData + cmCharLRC(vData, False);
	Return vData;
EndFunction // GetNAMEMessage

// -----------------------------------------------------------------------------
Function GetITEMMessage(pTRID, pSeqID, pItemsRow, pAccDocRef)
	vLanguage = pAccDocRef.Hotel.Language;
	If ValueIsFilled(pAccDocRef.Guest) And ValueIsFilled(pAccDocRef.Guest.Language) Then
		vLanguage = pAccDocRef.Guest.Language;
	EndIf;
	If Not ValueIsFilled(vLanguage) Then
		vLanguage = Catalogs.Languages.RU;
	EndIf;
	If pItemsRow.IsPayment Then
		vItemDescription = cmGetObjectExternalSystemCodeByRef(pAccDocRef.Hotel, "ECLIPSE", "PaymentMethods", pItemsRow.TransactionItem, True);
		If IsBlankString(vItemDescription) Then
			vItemDescription = Left(Transliterate(TrimAll(pItemsRow.TransactionItem.GetObject().pmGetPaymentMethodDescription(vLanguage))), 12);
		EndIf;
	Else
		vItemDescription = cmGetObjectExternalSystemCodeByRef(pAccDocRef.Hotel, "ECLIPSE", "Services", pItemsRow.TransactionItem, True);
		If IsBlankString(vItemDescription) Then
			vItemDescription = Left(Transliterate(TrimAll(pItemsRow.TransactionItem.GetObject().pmGetServiceDescription(vLanguage))), 12);
		EndIf;
	EndIf;
	vItemDescription = cmAppendBlanks(Upper(vItemDescription), 12);
	vData = pTRID + Format(pSeqID, "ND=4; NFD=0; NZ=; NLZ=; NG=") + "ITEM" + 
	        Format(pItemsRow.Period, "DF=MMdd") + 
	        vItemDescription + 
			?(pItemsRow.IsPayment, "CR", "  ") + 
	        StrReplace(StrReplace(Format(pItemsRow.Amount, "ND=7; NFD=2; NS=0; NDS=,; NZ=; NLZ=; NG="), ",", ""), "-", "") + 
			ETX;
	vData = STX + vData + cmCharLRC(vData, False);
	Return vData;
EndFunction // GetITEMMessage
 
// -----------------------------------------------------------------------------
Function GetBALMessage(pTRID, pAccDocRef)
	vOneRoomAccommodations = cmGetOneRoomAccommodations(pAccDocRef.Room, pAccDocRef.GuestGroup, pAccDocRef.CheckInDate, pAccDocRef.CheckOutDate);
	vBalances = cmGetDocumentListBalances(vOneRoomAccommodations, pAccDocRef.Hotel);
	vBalanceAmount = 0;
	vFolioCurrency = Undefined;
	For Each vBalancesRow In vBalances Do
		If vFolioCurrency <> Undefined And vBalancesRow.FolioCurrency <> vFolioCurrency Then
			Raise "Balance in different currencies found!";
		EndIf;
		vFolioCurrency = vBalancesRow.FolioCurrency;
		vBalanceAmount = vBalanceAmount + vBalancesRow.ClientSumBalance - vBalancesRow.ClientLimitBalance;
	EndDo;
	If vBalanceAmount < 0 Then
		vBalanceAmount = 0;
	EndIf;
	vData = pTRID + "9999" + "BAL " + 
	        StrReplace(Format(vBalanceAmount, "ND=8; NFD=2; NS=0; NDS=,; NZ=; NLZ=; NG="), ",", "") + 
			ETX;
	vData = STX + vData + cmCharLRC(vData, False);
	Return vData;
EndFunction // GetBALMessage
 
// -----------------------------------------------------------------------------
Function GetMHDRMessage(pTRID, pSeq, pMsgNumber, pEventRow, pAccDocRef)
	vMessageDateTime = pEventRow.MessageDateTime;
	If Not ValueIsFilled(vMessageDateTime) Then
		vMessageDateTime = CurrentSessionDate();
	EndIf;
	vData = pTRID + Format(pSeq, "ND=4; NFD=0; NZ=; NLZ=; NG=") + "MHDR" + 
	        Format(Number(cmGetDocumentNumberPresentation(pAccDocRef.ChargingRules.Get(pAccDocRef.ChargingRules.Count() - 1).ChargingFolio.Number)), "ND=6; NFD=0; NZ=; NLZ=; NG=") + 
	        Format(pMsgNumber, "ND=6; NFD=0; NZ=; NLZ=; NG=") + 
	        Format(vMessageDateTime, "DF=MMddyyHHmmss") + 
			?(ValueIsFilled(pAccDocRef.Guest), cmAppendBlanks(Left(Transliterate(TrimAll(TrimAll(pAccDocRef.Guest.FirstName) + " " + TrimAll(pAccDocRef.Guest.SecondName))), 24), 24), "                        ") + 
			"NNNNNY" +     // Message flags
			ETX;
	vData = STX + vData + cmCharLRC(vData, False);
	Return vData;
EndFunction // GetMHDRMessage
 
// -----------------------------------------------------------------------------
Function GetMTX2Message(pTRID, pSeq, pMsgNumber, pMessageLineText)
	vData = pTRID + Format(pSeq, "ND=4; NFD=0; NZ=; NLZ=; NG=") + "MTX2" + 
			//Format(pMsgNumber, "ND=6; NFD=0; NZ=; NLZ=; NG=") + 
	        cmAppendBlanks(Left(pMessageLineText, 64), 64) + 
			ETX;
	vData = STX + vData + cmCharLRC(vData, False);
	Return vData;
EndFunction // GetMTX2Message
 
// -----------------------------------------------------------------------------
Function GetCHKOMessage(pEventRow)
	vTRID = GetNextTRID();
	vData = "X" + Format(vTRID, "ND=3; NFD=0; NZ=; NLZ=; NG=") + "9999" + "CHKO" + cmAppendBlanks(Left(TrimAll(pEventRow.Room), 6), 6) + ETX;
	vData = STX + vData + cmCharLRC(vData, False);
	Return vData;
EndFunction // GetCHKOMessage
 
// -----------------------------------------------------------------------------
Function GetWKODMessage(pEventRow)
	vTRID = GetNextTRID();
	vData = "X" + Format(vTRID, "ND=3; NFD=0; NZ=; NLZ=; NG=") + "9999" + "WKOD" + 
	        cmAppendBlanks(Left(TrimAll(pEventRow.Room), 6), 6) + 
	        Format(pEventRow.MessageDateTime, "DF=HHmmMMddyy") + 
			?(pEventRow.IsCanceled, "C", "O") + 
			ETX;
	vData = STX + vData + cmCharLRC(vData, False);
	Return vData;
EndFunction // GetWKODMessage
 
// -----------------------------------------------------------------------------
Function GetMSGWMessage(pEventRow)
	vTRID = GetNextTRID();
	vData = "X" + Format(vTRID, "ND=3; NFD=0; NZ=; NLZ=; NG=") + "9999" + "MSGW" + 
	        cmAppendBlanks(Left(TrimAll(pEventRow.Room), 6), 6) + 
			?(pEventRow.IsCanceled, "N", "Y") + 
			ETX;
	vData = STX + vData + cmCharLRC(vData, False);
	Return vData;
EndFunction // GetMSGWMessage

// -----------------------------------------------------------------------------
Procedure DoMessage(pMsg, pMsgStatus = Undefined)
	vMsgStatus = MessageStatus.Information;
	If pMsgStatus <> Undefined Then
		vMsgStatus = pMsgStatus;
	EndIf;
	tcCommonFunctionOnClientServer.TextMessage(TrimAll(CurrentSessionDate()) + " " + pMsg, vMsgStatus);
	WriteLogEvent("Locatel.Eclipse", ?(vMsgStatus = MessageStatus.Attention, EventLogLevel.Error, EventLogLevel.Information), , , pMsg);
EndProcedure // DoMessage

// -----------------------------------------------------------------------------
Function GetActiveRoomInterfaceEvents() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInterfaceStatus.Ref,
	|	RoomInterfaceStatus.Hotel,
	|	RoomInterfaceStatus.Room,
	|	RoomInterfaceStatus.RoomInterfaceType,
	|	RoomInterfaceStatus.Remarks,
	|	RoomInterfaceStatus.IsProcessed,
	|	RoomInterfaceStatus.IsCanceled,
	|	RoomInterfaceStatus.MessageDateTime,
	|	RoomInterfaceStatus.MessageIsDelivered,
	|	RoomInterfaceStatus.MessageDeliveryDateTime,
	|	RoomInterfaceStatus.Number,
	|	RoomInterfaceStatus.Date,
	|	RoomInterfaceStatus.ParentDoc,
	|	RoomInterfaceStatus.Author,
	|	RoomInterfaceStatus.CancellationAuthor,
	|	RoomInterfaceStatus.CancellationDate,
	|	RoomInterfaceStatus.RoomInterfaceType.TurnOnParameters AS TurnOnParameters,
	|	RoomInterfaceStatus.RoomInterfaceType.TurnOffParameters AS TurnOffParameters,
	|	RoomInterfaceStatus.RoomInterfaceType.InterfaceType AS InterfaceType
	|FROM
	|	Document.RoomInterfaceStatus AS RoomInterfaceStatus
	|WHERE
	|	NOT RoomInterfaceStatus.DeletionMark
	|	AND NOT RoomInterfaceStatus.IsProcessed
	|	AND RoomInterfaceStatus.RoomInterfaceType.InterfaceType = &qTV
	|	AND NOT RoomInterfaceStatus.ParentDoc.CheckInDate IS NULL 
	|	AND RoomInterfaceStatus.ParentDoc.CheckInDate <= &qEndOfCurrentDate
	|	AND NOT RoomInterfaceStatus.ParentDoc.CheckOutDate IS NULL 
	|	AND RoomInterfaceStatus.ParentDoc.CheckOutDate >= &qBegOfCurrentDate
	|
	|ORDER BY
	|	RoomInterfaceStatus.PointInTime";
	vQry.SetParameter("qTV", Enums.InterfaceTypes.TV);
	vQry.SetParameter("qEndOfCurrentDate", EndOfDay(CurrentSessionDate()));
	vQry.SetParameter("qBegOfCurrentDate", BegOfDay(CurrentSessionDate()));
	Return vQry.Execute().Unload();
EndFunction // GetActiveRoomInterfaceEvents

// -----------------------------------------------------------------------------
Function GetAccommodationRoomInterfaceEvents(pAccDoc, pMsgType) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInterfaceStatus.Ref,
	|	RoomInterfaceStatus.Hotel,
	|	RoomInterfaceStatus.Room,
	|	RoomInterfaceStatus.RoomInterfaceType,
	|	RoomInterfaceStatus.Remarks,
	|	RoomInterfaceStatus.IsProcessed,
	|	RoomInterfaceStatus.IsCanceled,
	|	RoomInterfaceStatus.MessageDateTime,
	|	RoomInterfaceStatus.MessageIsDelivered,
	|	RoomInterfaceStatus.MessageDeliveryDateTime,
	|	RoomInterfaceStatus.Number,
	|	RoomInterfaceStatus.Date,
	|	RoomInterfaceStatus.ParentDoc,
	|	RoomInterfaceStatus.Author,
	|	RoomInterfaceStatus.CancellationAuthor,
	|	RoomInterfaceStatus.CancellationDate,
	|	RoomInterfaceStatus.RoomInterfaceType.TurnOnParameters AS TurnOnParameters,
	|	RoomInterfaceStatus.RoomInterfaceType.TurnOffParameters AS TurnOffParameters,
	|	RoomInterfaceStatus.RoomInterfaceType.InterfaceType AS InterfaceType
	|FROM
	|	Document.RoomInterfaceStatus AS RoomInterfaceStatus
	|WHERE
	|	NOT RoomInterfaceStatus.DeletionMark
	|	AND NOT RoomInterfaceStatus.IsProcessed
	|	AND RoomInterfaceStatus.RoomInterfaceType.InterfaceType = &qTV
	|	AND RoomInterfaceStatus.ParentDoc = &qParentDoc
	|	AND ((CAST(RoomInterfaceStatus.RoomInterfaceType.TurnOnParameters AS STRING(4))) = &qMsgType
	|			OR (CAST(RoomInterfaceStatus.RoomInterfaceType.TurnOffParameters AS STRING(4))) = &qMsgType)
	|
	|ORDER BY
	|	RoomInterfaceStatus.PointInTime";
	vQry.SetParameter("qTV", Enums.InterfaceTypes.TV);
	vQry.SetParameter("qParentDoc", pAccDoc);
	vQry.SetParameter("qMsgType", pMsgType);
	Return vQry.Execute().Unload();
EndFunction // GetAccommodationRoomInterfaceEvents

// -----------------------------------------------------------------------------
Procedure ProcessCheckInEvents(pActiveEvents)
	For Each vEventRow In pActiveEvents Do
		If vEventRow.InterfaceType = Enums.InterfaceTypes.TV And Not vEventRow.IsCanceled And TrimAll(vEventRow.TurnOnParameters) = "CHKI" Then
			vSuccess = False;
			// Build message for Eclipse
			vData = GetCHKIMessage(vEventRow);
			If DebugMode Then
				DoMessage("PMS -> Locatel Eclipse. CHKI message. Data going to be written: " + GetDataPresentation(vData));
			EndIf;
			If TCPIP.Write(vData, StrLen(vData)) = -1 Then
				DoMessage("PMS -> Locatel Eclipse. Send CHKI. Data NOT written!", MessageStatus.Attention);
			Else
				vSuccess = True;
			EndIf;
			// Set processed status to the interface record
			If vSuccess Then
				vStsObj = vEventRow.Ref.GetObject();
				vStsObj.IsProcessed = True;
				vStsObj.Write(DocumentWriteMode.Write);
			EndIf;
		EndIf;
	EndDo;
EndProcedure // ProcessCheckInEvents

// -----------------------------------------------------------------------------
Procedure ProcessCheckOutEvents(pActiveEvents)
	For Each vEventRow In pActiveEvents Do
		If vEventRow.InterfaceType = Enums.InterfaceTypes.TV And vEventRow.IsCanceled And TrimAll(vEventRow.TurnOffParameters) = "CHKO" Then
			vSuccess = False;
			// Build message for Eclipse
			vData = GetCHKOMessage(vEventRow);
			If DebugMode Then
				DoMessage("PMS -> Locatel Eclipse. CHKO message. Data going to be written: " + GetDataPresentation(vData));
			EndIf;
			If TCPIP.Write(vData, StrLen(vData)) = -1 Then
				DoMessage("PMS -> Locatel Eclipse. Send CHKO. Data NOT written!", MessageStatus.Attention);
			Else
				vSuccess = True;
			EndIf;
			// Set processed status to the interface record
			If vSuccess Then
				vStsObj = vEventRow.Ref.GetObject();
				vStsObj.IsProcessed = True;
				vStsObj.Write(DocumentWriteMode.Write);
			EndIf;
		EndIf;
	EndDo;
EndProcedure // ProcessCheckOutEvents

// -----------------------------------------------------------------------------
Procedure ProcessWakeUpEvents(pActiveEvents)
	For Each vEventRow In pActiveEvents Do
		If vEventRow.InterfaceType = Enums.InterfaceTypes.TV And TrimAll(vEventRow.TurnOnParameters) = "WKOD" Then
			vSuccess = False;
			If ValueIsFilled(vEventRow.MessageDateTime) And vEventRow.MessageDateTime > CurrentSessionDate() Then
				// Build message for Eclipse
				vData = GetWKODMessage(vEventRow);
				If DebugMode Then
					DoMessage("PMS -> Locatel Eclipse. Wake up call ordering event (WKOD) message. Data going to be written: " + GetDataPresentation(vData));
				EndIf;
				If TCPIP.Write(vData, StrLen(vData)) = -1 Then
					DoMessage("PMS -> Locatel Eclipse. Send wake up call ordering event (WKOD). Data NOT written!", MessageStatus.Attention);
				Else
					vSuccess = True;
				EndIf;
			Else
				If Not ValueIsFilled(vEventRow.MessageDateTime) Then
					DoMessage("PMS -> Locatel Eclipse. Wake up call ordering event (WKOD) set with empty wake up time!", MessageStatus.Attention);
				EndIf;
				vSuccess = True;
			EndIf;
			// Set processed status to the interface record
			If vSuccess Then
				vStsObj = vEventRow.Ref.GetObject();
				vStsObj.IsProcessed = True;
				vStsObj.Write(DocumentWriteMode.Write);
			EndIf;
		EndIf;
	EndDo;
EndProcedure // ProcessWakeUpEvents

// -----------------------------------------------------------------------------
Procedure ProcessGuestMessages(pActiveEvents)
	For Each vEventRow In pActiveEvents Do
		If vEventRow.InterfaceType = Enums.InterfaceTypes.TV And TrimAll(vEventRow.TurnOnParameters) = "MSGW" Then
			// Check if this message was already buffered
			If ActiveGuestMessages.FindByValue(vEventRow.Ref) <> Undefined Then
				Continue;
			EndIf;
			vSuccess = False;
			If Not vEventRow.IsCanceled Then
				If Not IsBlankString(vEventRow.Remarks) Then
					// Build message for Eclipse
					vData = GetMSGWMessage(vEventRow);
					If DebugMode Then
						DoMessage("PMS -> Locatel Eclipse. Guest message waiting event (MSGW) message. Data going to be written: " + GetDataPresentation(vData));
					EndIf;
					If TCPIP.Write(vData, StrLen(vData)) = -1 Then
						DoMessage("PMS -> Locatel Eclipse. Send guest message waiting event (MSGW). Data NOT written!", MessageStatus.Attention);
					Else
						vSuccess = True;
					EndIf;
				Else
					DoMessage("PMS -> Locatel Eclipse. Guest message waiting event (MSGW) set with empty message text!", MessageStatus.Attention);
					vSuccess = True;
				EndIf;
			Else
				vSuccess = True;
			EndIf;
			// Set processed status to the interface record
			If vSuccess Then
				If vEventRow.IsCanceled Then
					vStsObj = vEventRow.Ref.GetObject();
					vStsObj.IsProcessed = True;
					vStsObj.Write(DocumentWriteMode.Write);
				Else
					If ActiveGuestMessages.FindByValue(vEventRow.Ref) = Undefined Then
						ActiveGuestMessages.Add(vEventRow.Ref);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
EndProcedure // ProcessGuestMessages

// -----------------------------------------------------------------------------
Function GetVERReply(pData, pCmd)
	vData = pData;
	vData = Left(vData, Min(StrLen(vData) - 1, 13));
	vData = StrReplace(vData, pCmd, "VER ");
	vData = Mid(vData, 2) + ETX;
	vData = STX + vData + cmCharLRC(vData, False);
	Return vData;
EndFunction // GetVERReply 

// -----------------------------------------------------------------------------
Function GetERRReply(pData, pCmd, pErrCode)
	vData = pData;
	vData = Left(vData, Min(StrLen(vData) - 1, 13));
	vData = StrReplace(vData, pCmd, "ERR ");
	vData = Mid(vData, 2) + Format(pErrCode, "ND=2; NFD=0; NZ=; NLZ=; NG=") + ETX;
	vData = STX + vData + cmCharLRC(vData, False);
	Return vData;
EndFunction // GetERRReply 

// -----------------------------------------------------------------------------
Function GetMainRoomAccommodation(pRoom, pCheckInDate, pCheckOutDate) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	Docs.Ref,
	|	Docs.Date,
	|	Docs.PointInTime
	|FROM
	|	Document.Accommodation AS Docs
	|WHERE
	|	Docs.Room = &qRoom
	|	AND Docs.Posted
	|	AND Docs.AccommodationStatus.IsInHouse
	|	AND Docs.AccommodationStatus.IsActive
	|	AND Docs.CheckInDate < &qCheckOutDate
	|	AND Docs.CheckOutDate > &qCheckInDate
	|	AND (Docs.AccommodationType.Type = &qRoomAccommodationType
	|			OR Docs.AccommodationType.Type = &qBedsAccommodationType)
	|
	|ORDER BY
	|	Docs.Date,
	|	Docs.PointInTime";
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qCheckInDate", pCheckInDate);
	vQry.SetParameter("qCheckOutDate", pCheckOutDate);
	vQry.SetParameter("qRoomAccommodationType", Enums.AccomodationTypes.Room);
	vQry.SetParameter("qBedsAccommodationType", Enums.AccomodationTypes.Beds);
	vOneRoomDocs = vQry.Execute().Unload();
	If vOneRoomDocs.Count() > 0 Then
		Return vOneRoomDocs.Get(0).Ref;
	Else
		Return Undefined;
	EndIf;
EndFunction // GetMainRoomAccommodation

// -----------------------------------------------------------------------------
Function GetMessagePart(pDataReceived, rStartPos)
	If Not IsBlankString(pDataReceived) Then
		vStartPos = rStartPos;
		If vStartPos = 0 Then
			vStartPos = 1;
		EndIf;
		vSTXPos = Find(Mid(pDataReceived, vStartPos), STX);
		vSTXPos = vSTXPos + vStartPos - 1;
		If vSTXPos > 0 Then
			vETXPos = Find(Mid(pDataReceived, vSTXPos), ETX);
			vETXPos = vETXPos + vStartPos - 1;
			If vETXPos > 0 And vETXPos > vSTXPos Then
				vMessagePart = Mid(pDataReceived, vSTXPos, (vETXPos - vSTXPos + 1));
				If vETXPos > rStartPos Then
					rStartPos = vETXPos + 1;
					If Right(vMessagePart, 1) = ETX Then
						Return vMessagePart + "@";
					Else
						Return vMessagePart;
					EndIf;
				Else
					Return "";
				EndIf;
			Else
				Return "";
			EndIf;
		Else
			Return "";
		EndIf;
	Else
		Return "";
	EndIf;
EndFunction // GetMessagePart

// -----------------------------------------------------------------------------
Function GetMessageLinesArray(pRemarks)
	vMaxLineLength = 37;
	vLinesArray = cmGetTextLinesArray(pRemarks);
	// Check length of each line. It should not be more then vMaxLineLength bytes
	i = 0;
	While i < vLinesArray.Count() Do
		vLine = vLinesArray.Get(i);
		While StrLen(vLine) > vMaxLineLength Do
			vLinesArray.Set(i, Left(vLine, vMaxLineLength));
			vLine = Mid(vLine, (vMaxLineLength + 1));
			If Not IsBlankString(vLine) Then
				i = i + 1;
				vLinesArray.Insert(i, vLine);
			Else
				vLine = "";
			EndIf;
		EndDo;
		i = i + 1;
	EndDo;
	Return vLinesArray;
EndFunction // GetMessageLinesArray

// -----------------------------------------------------------------------------
Function SendGuestMessages(pAccDoc, pTRID, pErrCode)
	vReturn = True;
	vSeq = 0;
	vEvents = GetAccommodationRoomInterfaceEvents(pAccDoc, "MSGW");
	If vEvents.Count() = 0 Then
		// Reply ERR with code 11 (Guest message not found)
		pErrCode = 11;
		Return False;
	Else
		For Each vEventsRow In vEvents Do
			// Send MHDR
			Try
				vData = GetMHDRMessage(pTRID, vSeq, (vEvents.IndexOf(vEventsRow)+1), vEventsRow, pAccDoc);
			Except
				vData = "";
				DoMessage("PMS -> Locatel Eclipse. MHDR message. Error building MHDR message string: " + ErrorDescription(), MessageStatus.Attention);
			EndTry;
			If Not IsBlankString(vData) Then
				If DebugMode Then
					DoMessage("PMS -> Locatel Eclipse. MHDR message. Data going to be written: " + GetDataPresentation(vData));
				EndIf;
				If TCPIP.Write(vData, StrLen(vData)) = -1 Then
					DoMessage("PMS -> Locatel Eclipse. Send MHDR. Data NOT written!", MessageStatus.Attention);
					vReturn = False;
				EndIf;
			EndIf;
			// Next sequence number
			vSeq = vSeq + 1;
			// Send MTX2
			Try
				i = 0;
				vMessageText = Transliterate(TrimAll(vEventsRow.Remarks));
				vMessageLinesArray = GetMessageLinesArray(vMessageText);
				For Each vMessageLineText In vMessageLinesArray Do
					i = i + 1;
					If i > 15 Then
						Break;
					EndIf;
					If vEvents.IndexOf(vEventsRow) = (vEvents.Count() - 1) Then
						If i = 15 Or i = vMessageLinesArray.Count() Then
							vSeq = 9999;
						EndIf;
					EndIf;
					vData = GetMTX2Message(pTRID, vSeq, (vEvents.IndexOf(vEventsRow)+1), vMessageLineText);
					If Not IsBlankString(vData) Then
						If DebugMode Then
							DoMessage("PMS -> Locatel Eclipse. MTX2 message. Data going to be written: " + GetDataPresentation(vData));
						EndIf;
						If TCPIP.Write(vData, StrLen(vData)) = -1 Then
							DoMessage("PMS -> Locatel Eclipse. Send MTX2. Data NOT written!", MessageStatus.Attention);
							vReturn = False;
							Break;
						EndIf;
					EndIf;
					// Next sequence number
					vSeq = vSeq + 1;
				EndDo;
				If Not vReturn Then
					Break;
				EndIf;
			Except
				DoMessage("PMS -> Locatel Eclipse. MTX2 message. Error building or sending MTX2 messages array: " + ErrorDescription(), MessageStatus.Attention);
			EndTry;
			// Set is processed message status
			vStsObj = vEventsRow.Ref.GetObject();
			vStsObj.IsProcessed = True;
			vStsObj.Write(DocumentWriteMode.Write);
			// Remove it from buffer
			vMsgItem = ActiveGuestMessages.FindByValue(vEventsRow.Ref);
			If vMsgItem <> Undefined Then
				ActiveGuestMessages.Delete(vMsgItem);
			EndIf;
			// Next sequence number
			vSeq = vSeq + 1;
		EndDo;
	EndIf;
	Return vReturn;
EndFunction // SendGuestMessages

// -----------------------------------------------------------------------------
Function ProcessEventsFromEclipse(pDataReceived)
	If DebugMode Then
		DoMessage("Locatel Eclipse -> PMS. Data received: " + GetDataPresentation(pDataReceived));
	EndIf;
	// Get message part
	vReturn = True;
	rStartPos = 0;
	vSavStartPos = 0;
	vData = GetMessagePart(pDataReceived, rStartPos);
	While Not IsBlankString(vData) Do
		If DebugMode Then
			DoMessage("Locatel Eclipse -> PMS. Message parsed from pos " + vSavStartPos + ": " + GetDataPresentation(vData));
		EndIf;
		vSavStartPos = rStartPos;
		// Process message
		vOK = False;
		vErrCode = 0; // Unknown error
		vReturn = True;
		vSavData = vData;
		vTRID = Mid(vData, 2, 4);
		If Find(vData, "TEST") > 0 Then
			// Reply VER to TEST
			vData = GetVERReply(vData, "TEST");
			If DebugMode Then
				DoMessage("PMS -> Locatel Eclipse. VER message. Data going to be written: " + GetDataPresentation(vData));
			EndIf;
			If TCPIP.Write(vData, StrLen(vData)) = -1 Then
				vReturn = False;
			EndIf;
		ElsIf Find(vData, "VER ") > 0 Then
			// Nothing to do
		ElsIf Find(vData, "ERR ") > 0 Then
			// Error received, log it
			DoMessage("Locatel Eclipse -> PMS. ERR message. Data received: " + GetDataPresentation(vData));
		ElsIf Find(vData, "STAT") > 0 Then // Get room guest names and folios
			vRoomStr = TrimAll(Mid(vData, 14, 6));
			If Not IsBlankString(vRoomStr) Then
				vRoom = Catalogs.Rooms.FindByDescription(vRoomStr, True, , Hotel);
				If ValueIsFilled(vRoom) Then
					vRoomAcc = GetMainRoomAccommodation(vRoom, CurrentSessionDate(), CurrentSessionDate());
					If ValueIsFilled(vRoomAcc) Then
						// Send guest INFO message
						Try
							vData = GetINFOMessage(vTRID, vRoomAcc);
						Except
							vData = "";
							DoMessage("PMS -> Locatel Eclipse. INFO message. Error building INFO message string: " + ErrorDescription(), MessageStatus.Attention);
						EndTry;
						If Not IsBlankString(vData) Then
							If DebugMode Then
								DoMessage("PMS -> Locatel Eclipse. INFO message. Data going to be written: " + GetDataPresentation(vData));
							EndIf;
							If TCPIP.Write(vData, StrLen(vData)) = -1 Then
								DoMessage("PMS -> Locatel Eclipse. Send INFO. Data NOT written!", MessageStatus.Attention);
								vReturn = False;
							Else
								vOK = True;
							EndIf;
						EndIf;
					Else
						vErrCode = 3; // Room is unoccupied
						DoMessage("Locatel Eclipse -> PMS. Failed to get in-house accommodation by STAT received: " + GetDataPresentation(vData), MessageStatus.Attention);
					EndIf;
				Else
					vErrCode = 2; // Unknown room
					DoMessage("Locatel Eclipse -> PMS. Failed to get Room item by STAT received: " + GetDataPresentation(vData), MessageStatus.Attention);
				EndIf;
			Else
				vErrCode = 2; // Unknown room
				DoMessage("Locatel Eclipse -> PMS. Empty room retrieved from STAT received: " + GetDataPresentation(vData), MessageStatus.Attention);
			EndIf;
			If Not vOK Then
				// Return ERR message
				vData = GetERRReply(vSavData, "STAT", vErrCode);
				If DebugMode Then
					DoMessage("PMS -> Locatel Eclipse. ERR message. Data going to be written: " + GetDataPresentation(vData));
				EndIf;
				If TCPIP.Write(vData, StrLen(vData)) = -1 Then
					DoMessage("PMS -> Locatel Eclipse. Send ERR. Data NOT written!", MessageStatus.Attention);
					vReturn = False;
				EndIf;
			EndIf;
		ElsIf Find(vData, "LOOK") > 0 Then // Get main room guest name
			vRoomStr = TrimAll(Mid(vData, 14, 6));
			If Not IsBlankString(vRoomStr) Then
				vRoom = Catalogs.Rooms.FindByDescription(vRoomStr, True, , Hotel);
				If ValueIsFilled(vRoom) Then
					vRoomAcc = GetMainRoomAccommodation(vRoom, CurrentSessionDate(), CurrentSessionDate());
					If ValueIsFilled(vRoomAcc) Then
						// Answer NAME
						Try
							vData = GetNAMEMessage(vTRID, 9999, vRoomAcc);
						Except
							vData = "";
							DoMessage("PMS -> Locatel Eclipse. NAME message. Error building NAME message string: " + ErrorDescription(), MessageStatus.Attention);
						EndTry;
						If Not IsBlankString(vData) Then
							If DebugMode Then
								DoMessage("PMS -> Locatel Eclipse. NAME message. Data going to be written: " + GetDataPresentation(vData));
							EndIf;
							If TCPIP.Write(vData, StrLen(vData)) = -1 Then
								DoMessage("PMS -> Locatel Eclipse. Send NAME. Data NOT written!", MessageStatus.Attention);
								vReturn = False;
							Else
								vOK = True;
							EndIf;
						EndIf;
					Else
						vErrCode = 3; // Room is unoccupied
						DoMessage("Locatel Eclipse -> PMS. Failed to get in-house accommodation by LOOK received: " + GetDataPresentation(vData), MessageStatus.Attention);
					EndIf;
				Else
					vErrCode = 2; // Unknown room
					DoMessage("Locatel Eclipse -> PMS. Failed to get Room item by LOOK received: " + GetDataPresentation(vData), MessageStatus.Attention);
				EndIf;
			Else
				vErrCode = 2; // Unknown room
				DoMessage("Locatel Eclipse -> PMS. Empty room retrieved from LOOK received: " + GetDataPresentation(vData), MessageStatus.Attention);
			EndIf;
			If Not vOK Then
				// Return ERR message
				vData = GetERRReply(vSavData, "LOOK", vErrCode);
				If DebugMode Then
					DoMessage("PMS -> Locatel Eclipse. ERR message. Data going to be written: " + GetDataPresentation(vData));
				EndIf;
				If TCPIP.Write(vData, StrLen(vData)) = -1 Then
					DoMessage("PMS -> Locatel Eclipse. Send ERR. Data NOT written!", MessageStatus.Attention);
					vReturn = False;
				EndIf;
			EndIf;
		ElsIf Find(vData, "DISP") > 0 Then // Get main room guest balance and folio items
			vRoomStr = TrimAll(Mid(vData, 14, 6));
			If Not IsBlankString(vRoomStr) Then
				vRoom = Catalogs.Rooms.FindByDescription(vRoomStr, True, , Hotel);
				If ValueIsFilled(vRoom) Then
					vRoomAcc = GetMainRoomAccommodation(vRoom, CurrentSessionDate(), CurrentSessionDate());
					If ValueIsFilled(vRoomAcc) Then
						vSeq = 0;
						vErr = False;
						// Answer NAME
						Try
							vData = GetNAMEMessage(vTRID, vSeq, vRoomAcc);
						Except
							vErr = True;
							vData = "";
							DoMessage("PMS -> Locatel Eclipse. NAME message. Error building NAME message string: " + ErrorDescription(), MessageStatus.Attention);
						EndTry;
						If Not IsBlankString(vData) Then
							If DebugMode Then
								DoMessage("PMS -> Locatel Eclipse. NAME message. Data going to be written: " + GetDataPresentation(vData));
							EndIf;
							If TCPIP.Write(vData, StrLen(vData)) = -1 Then
								DoMessage("PMS -> Locatel Eclipse. Send NAME. Data NOT written!", MessageStatus.Attention);
								vErr = True;
								vReturn = False;
							EndIf;
						EndIf;
						// Answer ITEM messages with folio transactions
						If Not vErr Then
							vItems = GetRoomTransactions(vRoomAcc);
							For Each vItemsRow In vItems Do
								If Not vItemsRow.IsClientItem Then
									Continue;
								EndIf;
								If vItemsRow.Amount = 0 Then
									Continue;
								EndIf;
								vSeq = vSeq + 1;
								Try
									vData = GetITEMMessage(vTRID, vSeq, vItemsRow, vRoomAcc);
								Except
									vErr = True;
									vData = "";
									DoMessage("PMS -> Locatel Eclipse. BAL message. Error building ITEM message string: " + ErrorDescription(), MessageStatus.Attention);
								EndTry;
								If Not IsBlankString(vData) Then
									If DebugMode Then
										DoMessage("PMS -> Locatel Eclipse. ITEM message. Data going to be written: " + GetDataPresentation(vData));
									EndIf;
									If TCPIP.Write(vData, StrLen(vData)) = -1 Then
										DoMessage("PMS -> Locatel Eclipse. Send ITEM. Data NOT written!", MessageStatus.Attention);
										vErr = True;
										vReturn = False;
									EndIf;
								EndIf;
							EndDo;
						EndIf;
						// Answer BAL with guest balance
						If Not vErr Then
							Try
								vData = GetBALMessage(vTRID, vRoomAcc);
							Except
								vErr = True;
								vData = "";
								DoMessage("PMS -> Locatel Eclipse. BAL message. Error building BAL message string: " + ErrorDescription(), MessageStatus.Attention);
							EndTry;
							If Not IsBlankString(vData) Then
								If DebugMode Then
									DoMessage("PMS -> Locatel Eclipse. BAL message. Data going to be written: " + GetDataPresentation(vData));
								EndIf;
								If TCPIP.Write(vData, StrLen(vData)) = -1 Then
									DoMessage("PMS -> Locatel Eclipse. Send BAL. Data NOT written!", MessageStatus.Attention);
									vErr = True;
									vReturn = False;
								EndIf;
							EndIf;
						EndIf;
						If Not vErr Then
							vOK = True;
						EndIf;
					Else
						vErrCode = 3; // Room is unoccupied
						DoMessage("Locatel Eclipse -> PMS. Failed to get in-house accommodation by DISP received: " + GetDataPresentation(vData), MessageStatus.Attention);
					EndIf;
				Else
					vErrCode = 2; // Unknown room
					DoMessage("Locatel Eclipse -> PMS. Failed to get Room item by DISP received: " + GetDataPresentation(vData), MessageStatus.Attention);
				EndIf;
			Else
				vErrCode = 2; // Unknown room
				DoMessage("Locatel Eclipse -> PMS. Empty room retrieved from DISP received: " + GetDataPresentation(vData), MessageStatus.Attention);
			EndIf;
			If Not vOK Then
				// Return ERR message
				vData = GetERRReply(vSavData, "DISP", vErrCode);
				If DebugMode Then
					DoMessage("PMS -> Locatel Eclipse. ERR message. Data going to be written: " + GetDataPresentation(vData));
				EndIf;
				If TCPIP.Write(vData, StrLen(vData)) = -1 Then
					DoMessage("PMS -> Locatel Eclipse. Send ERR. Data NOT written!", MessageStatus.Attention);
					vReturn = False;
				EndIf;
			EndIf;
		ElsIf Find(vData, "XCKO") > 0 Then // Express check-out request
			vRoomStr = TrimAll(Mid(vData, 14, 6));
			If Not IsBlankString(vRoomStr) Then
				vRoom = Catalogs.Rooms.FindByDescription(vRoomStr, True, , Hotel);
				If ValueIsFilled(vRoom) Then
					vRoomAcc = GetMainRoomAccommodation(vRoom, CurrentSessionDate(), CurrentSessionDate());
					If ValueIsFilled(vRoomAcc) Then
						// Send program message to the whole reception
						Try
							vXCKOMsgText = NStr("en='Guest &1 from room &2 asks for express check-out!'; ru='Гость &1 из номера &2 запрашивает экспресс выселение!'; de='Die Gast &1 von Zimmer &2 Anfragen Express Check-out!'");
							vXCKOMsgText = StrReplace(vXCKOMsgText, "&1", TrimAll(vRoomAcc.GuestFullName));
							vXCKOMsgText = StrReplace(vXCKOMsgText, "&2", TrimAll(vRoom));
							vXCKOMsgStatus = vRoom.Owner.MessageStatus;
							cmSendMessageToDepartment(ReceptionDepartment, vXCKOMsgText, vXCKOMsgStatus, True, vRoomAcc);
							// Get VER message
							vData = GetVERReply(vData, "XCKO");
						Except
							vData = "";
							DoMessage("PMS -> Locatel Eclipse. XCKO message. Error sending XCKO message to reception department: " + ErrorDescription(), MessageStatus.Attention);
						EndTry;
						If Not IsBlankString(vData) Then
							// Reply VER to XCKO
							If DebugMode Then
								DoMessage("PMS -> Locatel Eclipse. VER message. Data going to be written: " + GetDataPresentation(vData));
							EndIf;
							If TCPIP.Write(vData, StrLen(vData)) = -1 Then
								vReturn = False;
							Else
								vOK = True;
							EndIf;
						EndIf;
					Else
						vErrCode = 3; // Room is unoccupied
						DoMessage("Locatel Eclipse -> PMS. Failed to get in-house accommodation by XCKO received: " + GetDataPresentation(vData), MessageStatus.Attention);
					EndIf;
				Else
					vErrCode = 2; // Unknown room
					DoMessage("Locatel Eclipse -> PMS. Failed to get Room item by XCKO received: " + GetDataPresentation(vData), MessageStatus.Attention);
				EndIf;
			Else
				vErrCode = 2; // Unknown room
				DoMessage("Locatel Eclipse -> PMS. Empty room retrieved from XCKO received: " + GetDataPresentation(vData), MessageStatus.Attention);
			EndIf;
			If Not vOK Then
				// Return ERR message
				vData = GetERRReply(vSavData, "XCKO", vErrCode);
				If DebugMode Then
					DoMessage("PMS -> Locatel Eclipse. ERR message. Data going to be written: " + GetDataPresentation(vData));
				EndIf;
				If TCPIP.Write(vData, StrLen(vData)) = -1 Then
					DoMessage("PMS -> Locatel Eclipse. Send ERR. Data NOT written!", MessageStatus.Attention);
					vReturn = False;
				EndIf;
			EndIf;
		ElsIf Find(vData, "WKDE") > 0 Then // Wake up call delivery status
			vRoomStr = TrimAll(Mid(vData, 14, 6));
			If Not IsBlankString(vRoomStr) Then
				vRoom = Catalogs.Rooms.FindByDescription(vRoomStr, True, , Hotel);
				If ValueIsFilled(vRoom) Then
					vRoomAcc = GetMainRoomAccommodation(vRoom, CurrentSessionDate(), CurrentSessionDate());
					If ValueIsFilled(vRoomAcc) Then
						// Send program message to the whole reception
						Try
							// Get wake up time
							vHHMMmmddyy = TrimAll(Mid(vData, 20, 10));
							vWakeUpTime = Date(2000 + Number(Right(vHHMMmmddyy, 2)), Number(Mid(vHHMMmmddyy, 5, 2)), Number(Mid(vHHMMmmddyy, 7, 2)), Number(Left(vHHMMmmddyy, 2)), Number(Mid(vHHMMmmddyy, 3, 2)), 0);
							vWasDelivered = False;
							vDeliveryStatus = TrimAll(Mid(vData, 30, 1));
							If vDeliveryStatus = "D" Then
								vWasDelivered = True;
							EndIf;
							// Build message text
							If Not vWasDelivered And ValueIsFilled(vWakeUpTime) Then
								vWKDEMsgText = NStr("en='Guest &1 from room &2 did not accept wake up call on &3 from TV!'; ru='Гость &1 из номера &2 не принял побудку в &3 на TV!'; de='Die Gast &1 von Zimmer &2 nicht nehmen Wecken um &3 im TV!'");
								vWKDEMsgText = StrReplace(vWKDEMsgText, "&1", TrimAll(vRoomAcc.GuestFullName));
								vWKDEMsgText = StrReplace(vWKDEMsgText, "&2", TrimAll(vRoom));
								vWKDEMsgText = StrReplace(vWKDEMsgText, "&3", Format(vWakeUpTime, "DF='dd.MM.yyyy HH:mm'"));
								vWKDEMsgStatus = vRoom.Owner.MessageStatus;
								cmSendMessageToDepartment(ReceptionDepartment, vWKDEMsgText, vWKDEMsgStatus, True, vRoomAcc);
							EndIf;
							// Get VER message
							vData = GetVERReply(vData, "WKDE");
						Except
							vData = "";
							DoMessage("PMS -> Locatel Eclipse. Wake up delivery status (WKDE) message. Error sending WKDE message to reception department: " + ErrorDescription(), MessageStatus.Attention);
						EndTry;
						If Not IsBlankString(vData) Then
							// Reply VER to WKDE
							If DebugMode Then
								DoMessage("PMS -> Locatel Eclipse. VER message. Data going to be written: " + GetDataPresentation(vData));
							EndIf;
							If TCPIP.Write(vData, StrLen(vData)) = -1 Then
								vReturn = False;
							Else
								vOK = True;
							EndIf;
						EndIf;
					Else
						vErrCode = 3; // Room is unoccupied
						DoMessage("Locatel Eclipse -> PMS. Failed to get in-house accommodation by XCKO received: " + GetDataPresentation(vData), MessageStatus.Attention);
					EndIf;
				Else
					vErrCode = 2; // Unknown room
					DoMessage("Locatel Eclipse -> PMS. Failed to get Room item by XCKO received: " + GetDataPresentation(vData), MessageStatus.Attention);
				EndIf;
			Else
				vErrCode = 2; // Unknown room
				DoMessage("Locatel Eclipse -> PMS. Empty room retrieved from XCKO received: " + GetDataPresentation(vData), MessageStatus.Attention);
			EndIf;
			If Not vOK Then
				// Return ERR message
				vData = GetERRReply(vSavData, "WKDE", vErrCode);
				If DebugMode Then
					DoMessage("PMS -> Locatel Eclipse. ERR message. Data going to be written: " + GetDataPresentation(vData));
				EndIf;
				If TCPIP.Write(vData, StrLen(vData)) = -1 Then
					DoMessage("PMS -> Locatel Eclipse. Send ERR. Data NOT written!", MessageStatus.Attention);
					vReturn = False;
				EndIf;
			EndIf;
		ElsIf Find(vData, "WKST") > 0 Then // Wake up call delivery status request
			vRoomStr = TrimAll(Mid(vData, 14, 6));
			If Not IsBlankString(vRoomStr) Then
				vRoom = Catalogs.Rooms.FindByDescription(vRoomStr, True, , Hotel);
				If ValueIsFilled(vRoom) Then
					vErrCode = 14; // Nothing pending
				Else
					vErrCode = 2; // Unknown room
					DoMessage("Locatel Eclipse -> PMS. Failed to get Room item by WKST received: " + GetDataPresentation(vData), MessageStatus.Attention);
				EndIf;
			Else
				vErrCode = 2; // Unknown room
				DoMessage("Locatel Eclipse -> PMS. Empty room retrieved from WKST received: " + GetDataPresentation(vData), MessageStatus.Attention);
			EndIf;
			// Return ERR message
			vData = GetERRReply(vSavData, "WKST", vErrCode);
			If DebugMode Then
				DoMessage("PMS -> Locatel Eclipse. ERR message. Data going to be written: " + GetDataPresentation(vData));
			EndIf;
			If TCPIP.Write(vData, StrLen(vData)) = -1 Then
				DoMessage("PMS -> Locatel Eclipse. Send ERR. Data NOT written!", MessageStatus.Attention);
				vReturn = False;
			EndIf;
		ElsIf Find(vData, "MSGR") > 0 Then // Get main room guest messages
			vTrId = TrimAll(Mid(vData, 2, 4));
			vRoomStr = TrimAll(Mid(vData, 14, 6));
			If Not IsBlankString(vRoomStr) Then
				vRoom = Catalogs.Rooms.FindByDescription(vRoomStr, True, , Hotel);
				If ValueIsFilled(vRoom) Then
					vRoomAcc = GetMainRoomAccommodation(vRoom, CurrentSessionDate(), CurrentSessionDate());
					If ValueIsFilled(vRoomAcc) Then
						// Send acoommodation messages
						vErrCode = 0;
						vReturn = SendGuestMessages(vRoomAcc, vTrId, vErrCode);
						If vReturn Then
							vOK = True;
						Else
							If vErrCode = 11 Then
								vReturn = True;
								// Return ERR message
								vData = GetERRReply(vSavData, "MSGR", vErrCode);
								If DebugMode Then
									DoMessage("PMS -> Locatel Eclipse. ERR message. Data going to be written: " + GetDataPresentation(vData));
								EndIf;
								If TCPIP.Write(vData, StrLen(vData)) = -1 Then
									DoMessage("PMS -> Locatel Eclipse. Send ERR. Data NOT written!", MessageStatus.Attention);
									vReturn = False;
								EndIf;
							EndIf;
						EndIf;
					Else
						vErrCode = 3; // Room is unoccupied
						DoMessage("Locatel Eclipse -> PMS. Failed to get in-house accommodation by MSGR received: " + GetDataPresentation(vData), MessageStatus.Attention);
					EndIf;
				Else
					vErrCode = 2; // Unknown room
					DoMessage("Locatel Eclipse -> PMS. Failed to get Room item by MSGR received: " + GetDataPresentation(vData), MessageStatus.Attention);
				EndIf;
			Else
				vErrCode = 2; // Unknown room
				DoMessage("Locatel Eclipse -> PMS. Empty room retrieved from MSGR received: " + GetDataPresentation(vData), MessageStatus.Attention);
			EndIf;
			If Not vOK Then
				// Return ERR message
				vData = GetERRReply(vSavData, "MSGR", vErrCode);
				If DebugMode Then
					DoMessage("PMS -> Locatel Eclipse. ERR message. Data going to be written: " + GetDataPresentation(vData));
				EndIf;
				If TCPIP.Write(vData, StrLen(vData)) = -1 Then
					DoMessage("PMS -> Locatel Eclipse. Send ERR. Data NOT written!", MessageStatus.Attention);
					vReturn = False;
				EndIf;
			EndIf;
		ElsIf Find(vData, "MSGD") > 0 Then
			// Reply VER to MSGD
			vData = GetVERReply(vData, "MSGD");
			If DebugMode Then
				DoMessage("PMS -> Locatel Eclipse. VER message. Data going to be written: " + GetDataPresentation(vData));
			EndIf;
			If TCPIP.Write(vData, StrLen(vData)) = -1 Then
				vReturn = False;
			EndIf;
		ElsIf Find(vData, "POST") > 0 Then // Charge room transaction
			vRoomStr = TrimAll(Mid(vData, 14, 6));
			If Not IsBlankString(vRoomStr) Then
				vRoom = Catalogs.Rooms.FindByDescription(vRoomStr, True, , Hotel);
				If ValueIsFilled(vRoom) Then
					Try
						// Get service
						vServiceCode = TrimAll(Mid(vData, 20, 2));
						// Get charge description
						vChargeDescription = TrimAll(Mid(vData, 22, 12));
						// Amount
						vAmount = Number(TrimAll(Mid(vData, 34, 7)))/100;
						// Call API to charge room service
						vErrorMessage = cmChargeRoomService(vRoomStr, CurrentSessionDate(), vAmount, , , vServiceCode, 1, , vChargeDescription, , TrimAll(Hotel.Code), "ECLIPSE");
						If Not IsBlankString(vErrorMessage) Then
							Raise vErrorMessage;
						EndIf;
						// Everything is OK
						vOK = True;
					Except
						vErrCode = 0; // Unknown error
						DoMessage("PMS -> Locatel Eclipse. POST message. Error processing POST message string: " + ErrorDescription(), MessageStatus.Attention);
					EndTry;
				Else
					vErrCode = 2; // Unknown room
					DoMessage("Locatel Eclipse -> PMS. Failed to get Room item by POST received: " + GetDataPresentation(vData), MessageStatus.Attention);
				EndIf;
			Else
				vErrCode = 2; // Unknown room
				DoMessage("Locatel Eclipse -> PMS. Empty room retrieved from POST received: " + GetDataPresentation(vData), MessageStatus.Attention);
			EndIf;
			If Not vOK Then
				// Return ERR message
				vData = GetERRReply(vSavData, "POST", vErrCode);
				If DebugMode Then
					DoMessage("PMS -> Locatel Eclipse. ERR message. Data going to be written: " + GetDataPresentation(vData));
				EndIf;
				If TCPIP.Write(vData, StrLen(vData)) = -1 Then
					DoMessage("PMS -> Locatel Eclipse. Send ERR. Data NOT written!", MessageStatus.Attention);
					vReturn = False;
				EndIf;
			EndIf;
		ElsIf Find(vData, "ROST") > 0 Then
			// Reply VER to ROST
			vData = GetVERReply(vData, "ROST");
			If DebugMode Then
				DoMessage("PMS -> Locatel Eclipse. VER message. Data going to be written: " + GetDataPresentation(vData));
			EndIf;
			If TCPIP.Write(vData, StrLen(vData)) = -1 Then
				vReturn = False;
			EndIf;
		ElsIf Find(vData, "HSKP") > 0 Then
			// Reply VER to HSKP
			vData = GetVERReply(vData, "HSKP");
			If DebugMode Then
				DoMessage("PMS -> Locatel Eclipse. VER message. Data going to be written: " + GetDataPresentation(vData));
			EndIf;
			If TCPIP.Write(vData, StrLen(vData)) = -1 Then
				vReturn = False;
			EndIf;
		Else
			DoMessage("Locatel Eclipse -> PMS. New command from server! Message data: " + vData, MessageStatus.Important);
		EndIf;
		// Get next message part
		vData = GetMessagePart(pDataReceived, rStartPos);
	EndDo;
	Return vReturn;
EndFunction // ProcessEventsFromEclipse

// -----------------------------------------------------------------------------
Function DoMainProcessingCycle()
	vReturn = True;
	// Update is running state
	pmLoadDataProcessorAttributes();
	If StopInterface Then
		Return False;
	EndIf;
	IsRunning = True;
	Timestamp = tcOnServer.cmGetServerCurrentSessionDate();
	pmSaveDataProcessorAttributes();
	// Get all active room interface events that need to be processed
	vActiveEvents = GetActiveRoomInterfaceEvents();
	// Process check-in events
	ProcessCheckInEvents(vActiveEvents);
	// Process check-out events
	ProcessCheckOutEvents(vActiveEvents);
	// Process check-out events
	ProcessWakeUpEvents(vActiveEvents);
	// Process messages for the guests
	ProcessGuestMessages(vActiveEvents);
	// Read events from Eclipse
	vData = "";
	If TCPIP.Read(vData, 1024) <> -1 Then
		vReturn = ProcessEventsFromEclipse(vData);
	EndIf;
	Return vReturn;
EndFunction // DoMainProcessingCycle

// -----------------------------------------------------------------------------
CSWSOCK6_LICENSE_KEY = cmGetCSWSOCK6LicenseKey();
CSWSOCK10_LICENSE_KEY = cmGetCSWSOCK10LicenseKey();

// -----------------------------------------------------------------------------
ACK = Char(6);
NAK = Char(21);
STX = Char(2);
ETX = Char(3);

// -----------------------------------------------------------------------------
TRID = 0;

// -----------------------------------------------------------------------------
ActiveGuestMessages = New ValueList();
