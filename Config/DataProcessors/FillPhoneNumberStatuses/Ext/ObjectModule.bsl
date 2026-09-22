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
	If ValueIsFilled(Hotel) Then
		If Not ValueIsFilled(FolioCurrency) Then
			FolioCurrency = Hotel.FolioCurrency;
		EndIf;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	// Set long distance calls statuses
	pmSetLongDistanceCallsPhoneNumberStatuses(pIsInteractive);
EndProcedure // pmRun

// -----------------------------------------------------------------------------
// Data processors framework end
// -----------------------------------------------------------------------------
	
// -----------------------------------------------------------------------------
Procedure pmSetLongDistanceCallsPhoneNumberStatuses(pIsInteractive = False) Export
	WriteLogEvent(NStr("en='DataProcessor.FillPhoneNumberStatuses';ru='Обработка.УстановкаСтатусовТелефонныхНомеров';de='DataProcessor.FillPhoneNumberStatuses'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'"));
	// Check parameters
	If Not ValueIsFilled(FolioCurrency) Then
		vMessage = NStr("ru='Не указана валюта лицевых счетов!';
		                |de='Die Währung der Personenkonten ist nicht angegeben!';
						|en='Folio currency is not set!'");
		WriteLogEvent(NStr("en='DataProcessor.FillPhoneNumberStatuses';ru='Обработка.УстановкаСтатусовТелефонныхНомеров';de='DataProcessor.FillPhoneNumberStatuses'"), EventLogLevel.Warning, ThisObject.Metadata(), Undefined, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Return;
		Else
			Raise vMessage;
		EndIf;
	EndIf;
	// Do processing
	Try
		// Get room folio balances
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	PhoneNumbers.Ref AS PhoneNumber,
		|	PhoneNumbers.Room AS Room,
		|	ISNULL(Folios.SumBalance, 0) AS SumBalance
		|FROM
		|	Catalog.PhoneNumbers AS PhoneNumbers
		|		LEFT JOIN (SELECT
		|			SUM(AccountsBalance.SumBalance) AS SumBalance,
		|			AccountsBalance.Folio.Room AS Room
		|		FROM
		|			AccumulationRegister.Accounts.Balance(
		|					&qPeriod,
		|					(Hotel IN HIERARCHY (&qHotel)
		|						OR &qIsEmptyHotel)
		|						AND (NOT Folio.DeletionMark)
		|						AND (NOT Folio.IsClosed)
		|						AND (NOT ISNULL(Folio.ParentDoc.DeletionMark, FALSE))
		|						AND FolioCurrency = &qFolioCurrency
		|						AND Folio.Room <> &qEmptyRoom
		|						AND (Folio.PaymentSection = &qPaymentSection OR &qPaymentSectionIsEmpty)
		|						AND (Folio.Description = &qFolioDescription OR &qFolioDescriptionIsEmpty)
		|						AND (NOT ISNULL(Folio.PaymentMethod.IsByBankTransfer, FALSE))) AS AccountsBalance
		|		GROUP BY
		|			AccountsBalance.Folio.Room) AS Folios
		|		ON PhoneNumbers.Room = Folios.Room
		|WHERE
		|	PhoneNumbers.Room <> &qEmptyRoom
		|	AND (NOT PhoneNumbers.Ref.IsFolder)
		|	AND (NOT PhoneNumbers.Ref.DeletionMark)
		|
		|ORDER BY
		|	PhoneNumbers.Room.SortCode";
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qIsEmptyHotel", Not ValueIsFilled(Hotel));
		vQry.SetParameter("qFolioCurrency", FolioCurrency);
		vQry.SetParameter("qFolioDescription", FolioDescription);
		vQry.SetParameter("qFolioDescriptionIsEmpty", IsBlankString(FolioDescription));
		vQry.SetParameter("qPaymentSection", PaymentSection);
		vQry.SetParameter("qPaymentSectionIsEmpty", Not ValueIsFilled(PaymentSection));
		vQry.SetParameter("qEmptyRoom", Catalogs.Rooms.EmptyRef());
		vQry.SetParameter("qPeriod", ?(CheckBalancesOnCurrentDate, CurrentSessionDate(), '39991231235959'));
		vQryRes = vQry.Execute().Unload();
		// For each phone number update record in information register (if necessary)
		vRecordManager = InformationRegisters.CurrentPhoneNumberStatuses.CreateRecordManager();
		For Each vRow In vQryRes Do
			vRecordManager.PhoneNumber = vRow.PhoneNumber;
			vRecordManager.Read();
			// Check do we need to update record
			If vRecordManager.IsManagedManually Then
				Continue;
			EndIf;
			vLongDistanceCallsAreBlocked = True;
			If -vRow.SumBalance > Sum Then
				vLongDistanceCallsAreBlocked = False;
			EndIf;
			If vLongDistanceCallsAreBlocked <> vRecordManager.LongDistanceCallsAreBlocked Then
				// Update record
				vRecordManager.PhoneNumber = vRow.PhoneNumber;
				vRecordManager.LongDistanceCallsAreBlocked = vLongDistanceCallsAreBlocked;
				vRecordManager.IsChanged = True;
				vRecordManager.Remarks = Format(CurrentSessionDate(), "DF='dd.MM.yyyy HH:mm:ss'") + ", " + NStr("en='balance = ';ru='баланс = ';de='Bilanz = '") + Format(vRow.SumBalance, "ND=17; NFD=2; NZ=");
				vRecordManager.Write(True);
				// Build message
				vMessage = NStr("ru = 'Статус блокировки платных телефонных разговоров с тел. номера " + TrimAll(vRow.PhoneNumber.PhoneNumber) + " в комнате " + TrimAll(vRow.Room) + " установлен в " + Format(vLongDistanceCallsAreBlocked, "BF=<Выключено>; BT=<Включено>") + "! Баланс по номеру = " + Format(vRow.SumBalance, "ND=17; NFD=2; NZ=") + "'; 
				                |de = 'Room " + TrimAll(vRow.Room) + " phone number " + TrimAll(vRow.PhoneNumber.PhoneNumber) + " long distance calls block status changed to " + Format(vLongDistanceCallsAreBlocked, "BF=<Turned off>; BT=<Turned on>") + "! Room balance = " + Format(vRow.SumBalance, "ND=17; NFD=2; NZ=") + "'; 
								|en = 'Room " + TrimAll(vRow.Room) + " phone number " + TrimAll(vRow.PhoneNumber.PhoneNumber) + " long distance calls block status changed to " + Format(vLongDistanceCallsAreBlocked, "BF=<Turned off>; BT=<Turned on>") + "! Room balance = " + Format(vRow.SumBalance, "ND=17; NFD=2; NZ=") + "'");
				// Send notification
				WriteLogEvent(NStr("en='DataProcessor.FillPhoneNumberStatuses';ru='Обработка.УстановкаСтатусовТелефонныхНомеров';de='DataProcessor.FillPhoneNumberStatuses'"), EventLogLevel.Information, ThisObject.Metadata(), , vMessage);
				If pIsInteractive Then
					tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
				Endif;
			EndIf;
		EndDo;
	Except
		vMessage = ErrorDescription();
		WriteLogEvent(NStr("en='DataProcessor.FillPhoneNumberStatuses';ru='Обработка.УстановкаСтатусовТелефонныхНомеров';de='DataProcessor.FillPhoneNumberStatuses'"), EventLogLevel.Warning, ThisObject.Metadata(), , vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
		Else
			Raise vMessage;
		EndIf;
	EndTry;
	WriteLogEvent(NStr("en='DataProcessor.FillPhoneNumberStatuses';ru='Обработка.УстановкаСтатусовТелефонныхНомеров';de='DataProcessor.FillPhoneNumberStatuses'"), EventLogLevel.Information, ThisObject.Metadata(), , NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'"));
EndProcedure // pmSetLongDistanceCallsPhoneNumberStatuses
