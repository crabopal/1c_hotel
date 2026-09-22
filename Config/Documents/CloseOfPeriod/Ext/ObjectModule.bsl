
#Region Public

// -----------------------------------------------------------------------------
Function pmGetCloseOfDaySettlements() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Settlement.Ref AS Settlement
	|FROM
	|	Document.Settlement AS Settlement
	|WHERE
	|	Settlement.CloseOfPeriod = &qCloseOfPeriod
	|	AND Settlement.Posted = TRUE";
	vQry.SetParameter("qCloseOfPeriod", Ref);
	Return vQry.Execute().Unload();
EndFunction // pmGetCloseOfDaySettlements

// -----------------------------------------------------------------------------
Function pmCheckDocumentAttributes(pMessage, pAttributeInErr) Export
	vHasErrors = False;
	pMessage = "";
	pAttributeInErr = "";
	vMsgTextRu = "";
	vMsgTextEn = "";
	vMsgTextDe = "";
	If Not ValueIsFilled(Date) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Дата закрытия периода> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Close of period date> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Close of period date> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Date", pAttributeInErr);
	EndIf;
	If vHasErrors Then
		pMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // CheckDocumentAttributes

// -----------------------------------------------------------------------------
Procedure pmFillAuthorAndDate() Export
	Author = SessionParameters.CurrentUser;
	If (EndOfDay(CurrentSessionDate()) - CurrentSessionDate()) < (6*3600) Then
		Date = EndOfDay(CurrentSessionDate()); // End of this calendar day
	Else
		Date = EndOfDay(CurrentSessionDate()) - 24*3600; // End of previous calendar day
	EndIf;
EndProcedure // pmFillAuthorAndDate

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill author and document date
	pmFillAuthorAndDate();
	// Fill from session parameters
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
		CloseServiceRegistration = Hotel.CloseServiceRegistration;
	EndIf;
	If ValueIsFilled(Hotel) Then
		Company = Hotel.Company;
		If ValueIsFilled(Company) Then
			pmFillByCompany(Company);
		EndIf;
	Else
		CloseServiceRegistration = True;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Procedure pmFillByCompany(pCompany) Export
	If Not ValueIsFilled(pCompany) Then
		Return;
	EndIf;
	Company = pCompany;
	// Check company accounting policy
	ProcessClosedFoliosOnly = False;
	DoNotCloseIndividuals = False;
	If ValueIsFilled(Company.CompanyAccountingPolicyType) Then
		If Company.CompanyAccountingPolicyType = Enums.CompanyAccountingPolicyTypes.ByCheckedOutGuestsServices Or
		   Company.CompanyAccountingPolicyType = Enums.CompanyAccountingPolicyTypes.ByCheckedOutGuestGroupsServices Then
			If Not ValueIsFilled(Company.TaxAccountingPeriodType) Or Company.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.Month Then
				If Company.CloseMonthAtDayBeforeTheLastMonthDay Then
					If EndOfDay(Date) <> (EndOfMonth(Date) - 24*3600) Then
						ProcessClosedFoliosOnly = True;
						If Company.CloseIndividualsAtAccountingPeriodEndOnly Then
							DoNotCloseIndividuals = True;
						EndIf;
					EndIf;
				Else
					If EndOfDay(Date) <> EndOfMonth(Date) Then
						ProcessClosedFoliosOnly = True;
						If Company.CloseIndividualsAtAccountingPeriodEndOnly Then
							DoNotCloseIndividuals = True;
						EndIf;
					EndIf;
				EndIf;
			ElsIf Company.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.Quarter Then
				If EndOfDay(Date) <> EndOfQuarter(Date) Then
					ProcessClosedFoliosOnly = True;
					If Company.CloseIndividualsAtAccountingPeriodEndOnly Then
						DoNotCloseIndividuals = True;
					EndIf;
				EndIf;
			ElsIf Company.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.HalfYear Then
				If EndOfDay(Date) <> AddMonth(EndOfYear(Date), -6) Then
					ProcessClosedFoliosOnly = True;
					If Company.CloseIndividualsAtAccountingPeriodEndOnly Then
						DoNotCloseIndividuals = True;
					EndIf;
				EndIf;
			ElsIf Company.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.Year Then
				If EndOfDay(Date) <> EndOfYear(Date) Then
					ProcessClosedFoliosOnly = True;
					If Company.CloseIndividualsAtAccountingPeriodEndOnly Then
						DoNotCloseIndividuals = True;
					EndIf;
				EndIf;
			ElsIf Company.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.Decade Then
				vDay = Day(Date);
				If vDay < 10 Then
					ProcessClosedFoliosOnly = True;
					If Company.CloseIndividualsAtAccountingPeriodEndOnly Then
						DoNotCloseIndividuals = True;
					EndIf;
				ElsIf vDay < 20 And vDay > 10 Then
					ProcessClosedFoliosOnly = True;
					If Company.CloseIndividualsAtAccountingPeriodEndOnly Then
						DoNotCloseIndividuals = True;
					EndIf;
				Else
					If Company.CloseMonthAtDayBeforeTheLastMonthDay Then
						If vDay <> Day(EndOfMonth(Date) - 24*3600) Then
							ProcessClosedFoliosOnly = True;
							If Company.CloseIndividualsAtAccountingPeriodEndOnly Then
								DoNotCloseIndividuals = True;
							EndIf;
						EndIf;
					Else
						If vDay <> Day(EndOfMonth(Date)) Then
							ProcessClosedFoliosOnly = True;
							If Company.CloseIndividualsAtAccountingPeriodEndOnly Then
								DoNotCloseIndividuals = True;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			ElsIf Company.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.None Then
				ProcessClosedFoliosOnly = True;
			EndIf;
		EndIf;
	EndIf;
	OneSettlementPerCustomerGuestGroups = Company.OneSettlementPerCustomerGuestGroups;
	OneSettlementPerIndividualsCustomerGuestGroups = Company.OneSettlementPerIndividualsCustomerGuestGroups;
	SplitSettllementsByVATRate = Company.SplitSettllementsByVATRate;
	SplitSettllementsByPaymentSections = Company.SplitSettllementsByPaymentSections;
EndProcedure // pmFillByCompany

#EndRegion

#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure Filling(pBase)
	// Fill attributes with default values
	pmFillAttributesWithDefaultValues();
	// Fill from the base
	If ValueIsFilled(pBase) Then
		If TypeOf(pBase) = Type("CatalogRef.Companies") Then
			pmFillByCompany(pBase);
		EndIf;
	EndIf;
EndProcedure // Filling

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pWriteMode, pPostingMode)
	Var vMessage, vAttributeInErr;
	If DataExchange.Load Then
		Return;
	EndIf;
	If pWriteMode = DocumentWriteMode.Posting Then
		pCancel	= pmCheckDocumentAttributes(vMessage, vAttributeInErr);
		If pCancel Then
			WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
			tcCommonFunctionOnClientServer.UserMessage(NStr(vMessage));
			Raise NStr(vMessage);
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure OnSetNewNumber(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(Hotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(Hotel);
	ElsIf ValueIsFilled(SessionParameters.CurrentHotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(SessionParameters.CurrentHotel);
	EndIf;
	If vPrefix <> "" Then
		pPrefix = vPrefix;
	EndIf;
EndProcedure // OnSetNewNumber

// -----------------------------------------------------------------------------
// Document will:
// 1. Create settlements to close balances in Current Accounts Receivable
// 2. Do payments distribution to services charged
// -----------------------------------------------------------------------------
Procedure Posting(pCancel, pPostingMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// Check if daocument was already posted
	vIsPosted = CheckIfDocumentIsAlreadyPosted();
	
	// Add data locks
	If ValueIsFilled(Company) Then
		vDataLock = New DataLock();
		vCmpItem = vDataLock.Add("Catalog.Companies");
		vCmpItem.Mode = DataLockMode.Exclusive;
		vCmpItem.SetValue("Ref", Company);
		vDataLock.Lock();
	EndIf;
	
	// 00. Process user exit algorithm if any
	vUserExitProc0 = Catalogs.ExternalDataProcessors.CloseOfPeriodBeforeStart;
	If ValueIsFilled(vUserExitProc0) Then
		If vUserExitProc0.ExternalProcessingType = Enums.ExternalProcessingTypes.Algorithm Then
			If Not IsBlankString(vUserExitProc0.Algorithm) Then     
				vKeyOperation = "CloseOfPeriod.BeforeStart.UserExitProcedure";
				vTimeFrom = APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, New UUID);
	
				// Log start of user external algorithm
				WriteLogEvent(NStr("en='CloseOfPeriod.BeforeStart.UserExitProcedure';ru='ЗакрытиеПериода.ПередВыполнением.АлгоритмПользователя';de='CloseOfPeriod.BeforeStart.UserExitProcedure'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='Start of user exit procedure before start...';ru='Начато выполнение пользовательского алгоритма перед началом закрытия дня...';de='Die Ausführung des Nutzeralgorithmus wurde gestartet vor Beginn des Tagesabschlusses…'"), EventLogEntryTransactionMode.Independent);
				SetSafeMode(True);
				Execute(TrimAll(vUserExitProc0.Algorithm));
				SetSafeMode(False);
				WriteLogEvent(NStr("en='CloseOfPeriod.BeforeStart.UserExitProcedure';ru='ЗакрытиеПериода.ПередВыполнением.АлгоритмПользователя';de='CloseOfPeriod.BeforeStart.UserExitProcedure'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='End of user exit procedure';ru='Закончено выполнение пользовательского алгоритма';de='Die Ausführung des Nutzeralgorithmus ist abgeschlossen'"), EventLogEntryTransactionMode.Independent);
				APDEXPerformanceSystemOnClientServer.FinishTimeIntervalMeasurement(vKeyOperation, vTimeFrom);
			EndIf;
		EndIf;
	EndIf;
	
	// 01. Update VAT rates from history
	// APDEX
	vKeyOperation = "CloseOfPeriod.UpdateVATRateIfChanged";
	vTimeFrom = APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, New UUID);
	// Update vat rate planned changes
	UpdateVATRateIfChanged();
	// Do planned company VAT rate change
	UpdateCompanyVATRateIfChanged();
	// Do planned payment section VAT rate change
	UpdatePaymentSectionVATRateIfChanged();
	// Check if "No VAT" VAT rate exists. Create it if not
	CheckNoVATVATRate();
	APDEXPerformanceSystemOnClientServer.FinishTimeIntervalMeasurement(vKeyOperation, vTimeFrom);

	// 02. Repost charges already existed for the closed day    
	vKeyOperation = "CloseOfPeriod.RepostClosedDayInPriceCharges";
	vTimeFrom = APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, New UUID);
	RepostClosedDayInPriceCharges(vIsPosted);
	APDEXPerformanceSystemOnClientServer.FinishTimeIntervalMeasurement(vKeyOperation, vTimeFrom);
	
	// 03. Apply expected room moves     
	vKeyOperation = "CloseOfPeriod.AcceptExpectedRoomMoves";
	vTimeFrom = APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, New UUID);
	AcceptExpectedRoomMoves(vIsPosted);     
	APDEXPerformanceSystemOnClientServer.FinishTimeIntervalMeasurement(vKeyOperation, vTimeFrom);
	
	// 04. Create charges for the closed date   
	vKeyOperation = "CloseOfPeriod.CreateChargesForTheClosedDay";
	vTimeFrom = APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, New UUID);
	CreateChargesForTheClosedDay(vIsPosted);
	APDEXPerformanceSystemOnClientServer.FinishTimeIntervalMeasurement(vKeyOperation, vTimeFrom);
	
	// 05. Clear business-block sales forecast for the closed date
	vKeyOperation = "CloseOfPeriod.ClearSalesForecastForBusinessBlocks";
	vTimeFrom = APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, New UUID);
	ClearSalesForecastForBusinessBlocks(pCancel, pPostingMode);
	APDEXPerformanceSystemOnClientServer.FinishTimeIntervalMeasurement(vKeyOperation, vTimeFrom);
	
	// 06. Charge commitment allotments
	If EndOfDay(Date) = EndOfMonth(Date) Then    
		vKeyOperation = "CloseOfPeriod.ChargeCommitmentAllotments";
		vTimeFrom = APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, New UUID);
		ChargeCommitmentAllotments(pCancel, pPostingMode);      
		APDEXPerformanceSystemOnClientServer.FinishTimeIntervalMeasurement(vKeyOperation, vTimeFrom);
	EndIf;
	
	// 07. Move hotel accounting date
	If Not AdditionalProperties.Property("SkipChangingDate") 
		Or AdditionalProperties.Property("SkipChangingDate") And Not AdditionalProperties.SkipChangingDate Then     
		
		vKeyOperation = "CloseOfPeriod.MoveHotelAccountingDate";
		vTimeFrom = APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, New UUID);
		
		vNewAccountingDate = BegOfDay(EndOfDay(Date) + 1);
		vHotelsList = New ValueList();
		If ValueIsFilled(Hotel) Then
			vHotelsList.Add(Hotel);
		Else
			vAllHotels = cmGetAllHotels();
			vHotelsList.LoadValues(vAllHotels.UnloadColumn("Hotel"));
		EndIf;
		For Each vHotelsItem In vHotelsList Do
			vHotel = vHotelsItem.Value;
			If ValueIsFilled(vHotel) And ValueIsFilled(vHotel.AccountingDate) Then
				If vHotel.AccountingDate < vNewAccountingDate Then
					vHotelObj = vHotel.GetObject();
					vHotelObj.AccountingDate = vNewAccountingDate;
					vHotelObj.Write();
				EndIf;
			EndIf;
		EndDo;    
		APDEXPerformanceSystemOnClientServer.FinishTimeIntervalMeasurement(vKeyOperation, vTimeFrom);
	EndIf;
	
	// 08. Close folios with empty parent document but with "period to" filled and 
	//     less or equal close period date or with deleted parent document
	If ValueIsFilled(Company) Then   
		vKeyOperation = "CloseOfPeriod.CloseOrphanFolios";
		vTimeFrom = APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, New UUID);

		CloseOrphanFolios(vIsPosted);        
		
		APDEXPerformanceSystemOnClientServer.FinishTimeIntervalMeasurement(vKeyOperation, vTimeFrom);
	EndIf;
	
	// 09. Close cash register section folio balances  
	vKeyOperation = "CloseOfPeriod.CloseCashRegisterFolioBalances";
	vTimeFrom = APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, New UUID);
	CloseCashRegisterFolioBalances(vIsPosted);
	APDEXPerformanceSystemOnClientServer.FinishTimeIntervalMeasurement(vKeyOperation, vTimeFrom);
	
	// 10. Update reporting currency exchange rates for the charges on the closing date  
	vKeyOperation = "CloseOfPeriod.UpdateReportingCurrencyExchangeRates";
	vTimeFrom = APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, New UUID);
	UpdateReportingCurrencyExchangeRates(Date, vIsPosted);
	// And date after closing (because we are loading rates for tomorrow today by common scenario)
	UpdateReportingCurrencyExchangeRates(Date + 24 * 3600, vIsPosted);
	APDEXPerformanceSystemOnClientServer.FinishTimeIntervalMeasurement(vKeyOperation, vTimeFrom);
	
	// 11. Delete services that should be charged externally
	vKeyOperation = "CloseOfPeriod.DeleteServicesThatShouldBeChargedExternally";
	vTimeFrom = APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, New UUID);
	DeleteServicesThatShouldBeChargedExternally(vIsPosted);
	APDEXPerformanceSystemOnClientServer.FinishTimeIntervalMeasurement(vKeyOperation, vTimeFrom);
	
	//
	// Invoice generation - start
	//
	
	vUseStandardCode = True;
	vUserExitProc1 = Catalogs.ExternalDataProcessors.CloseOfPeriodCreateInvoices;
	If ValueIsFilled(vUserExitProc1) Then
		If vUserExitProc1.ExternalProcessingType = Enums.ExternalProcessingTypes.Algorithm Then
			If Not IsBlankString(vUserExitProc1.Algorithm) Then
				vUseStandardCode = False;
				vKeyOperation = "CloseOfPeriod.UserExitProcedure_CloseOfPeriodCreateInvoices";
				vTimeFrom = APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, New UUID);
	
				// Log start of user external algorithm
				WriteLogEvent(NStr("en='CloseOfPeriod.UserExitProcedure.CreateInvoices';ru='ЗакрытиеПериода.АлгоритмПользователя.СозданиеАктов';de='CloseOfPeriod.UserExitProcedure.CreateInvoices'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='Start of user exit procedure...';ru='Начато выполнение пользовательского алгоритма...';de='Die Ausführung des Nutzeralgorithmus wurde gestartet…'"), EventLogEntryTransactionMode.Independent);
				SetSafeMode(True);
				Execute(TrimAll(vUserExitProc1.Algorithm));
				SetSafeMode(False);
				WriteLogEvent(NStr("en='CloseOfPeriod.UserExitProcedure.CreateInvoices';ru='ЗакрытиеПериода.АлгоритмПользователя.СозданиеАктов';de='CloseOfPeriod.UserExitProcedure.CreateInvoices'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='End of user exit procedure';ru='Закончено выполнение пользовательского алгоритма';de='Die Ausführung des Nutzeralgorithmus ist abgeschlossen'"), EventLogEntryTransactionMode.Independent);
				APDEXPerformanceSystemOnClientServer.FinishTimeIntervalMeasurement(vKeyOperation, vTimeFrom);
			EndIf;
		EndIf;
	EndIf;
	
	If vUseStandardCode And ValueIsFilled(Company) And Company.DoNotGenerateInvoicesAutomaticallyAtEndOfPeriod Then
		vUseStandardCode = False;
	EndIf;
	
	If vUseStandardCode Then
		// 12. Get guest groups with corrections       
		vKeyOperation = "CloseOfPeriod.SearchingGuestGroupsWithCorrections";
		vTimeFrom = APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, New UUID);
		WriteLogEvent(NStr("en='CloseOfPeriod.SearchingGuestGroupsWithCorrections';ru='ЗакрытиеПериода.ПоискГруппГостейСКорректировками';de='CloseOfPeriod.SearchingGuestGroupsWithCorrections'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='Start of searching guest groups with corrections...';ru='Начата операция получения списка групп гостей, по которым были корректировки...';de='Das Abrufen der Gästegruppenliste wurde gestartet, zu denen es Korrekturen gab…'"), EventLogEntryTransactionMode.Independent);
		vGuestGroupsWithCorrections = GetGuestGroupsWithCorrections(vIsPosted);
		WriteLogEvent(NStr("en='CloseOfPeriod.SearchingGuestGroupsWithCorrections';ru='ЗакрытиеПериода.ПоискГруппГостейСКорректировками';de='CloseOfPeriod.SearchingGuestGroupsWithCorrections'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='Number of guest groups with corrections found is ';ru='Найдено групп гостей, по которым были корректировки: ';de='Es wurden Gästegruppen gefunden, zu denen es Korrekturen gab:'") + vGuestGroupsWithCorrections.Count(), EventLogEntryTransactionMode.Independent);
		APDEXPerformanceSystemOnClientServer.FinishTimeIntervalMeasurement(vKeyOperation, vTimeFrom);
		
		// 13. Close hotel products waiting for the hotel product number to be entered
		vKeyOperation = "CloseOfPeriod.CloseHotelProducts";
		vTimeFrom = APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, New UUID);
		CloseHotelProducts(pCancel, pPostingMode, vIsPosted, vGuestGroupsWithCorrections, True);
		APDEXPerformanceSystemOnClientServer.FinishTimeIntervalMeasurement(vKeyOperation, vTimeFrom);
		
		// 14. Close current accounts receivable
		vKeyOperation = "CloseOfPeriod.CloseCurrentAccountsReceivable";
		vTimeFrom = APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, New UUID);
		CloseCurrentAccountsReceivable(pCancel, pPostingMode, vIsPosted, vGuestGroupsWithCorrections, True);

		If Not ProcessClosedFoliosOnly Then
			// Close hotel products waiting for the hotel product number to be entered
			CloseHotelProducts(pCancel, pPostingMode, vIsPosted, vGuestGroupsWithCorrections, False);
			
			// Close current accounts receivable
			CloseCurrentAccountsReceivable(pCancel, pPostingMode, vIsPosted, vGuestGroupsWithCorrections, False);
		EndIf;  
		APDEXPerformanceSystemOnClientServer.FinishTimeIntervalMeasurement(vKeyOperation, vTimeFrom);
	EndIf;
	
	// Invoice generation - end
	
	// 15. Do payments distribution to services charged
	vKeyOperation = "CloseOfPeriod.DoPaymentsDistributionToServices";
	vTimeFrom = APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, New UUID);
	DoPaymentsDistributionToServices(pCancel, pPostingMode);
	APDEXPerformanceSystemOnClientServer.FinishTimeIntervalMeasurement(vKeyOperation, vTimeFrom);

	// 16. Close service registrations
	If CloseServiceRegistration Then
		vKeyOperation = "CloseOfPeriod.CloseServiceRegistration";
		vTimeFrom = APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, New UUID);
		CloseServiceRegistration();         
		APDEXPerformanceSystemOnClientServer.FinishTimeIntervalMeasurement(vKeyOperation, vTimeFrom);
	EndIf;
	
	// 17. Archive not used preauthorisations
	vKeyOperation = "CloseOfPeriod.ArchivePreauthorisations";
	vTimeFrom = APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, New UUID);
	ArchivePreauthorisations(vIsPosted);         
	APDEXPerformanceSystemOnClientServer.FinishTimeIntervalMeasurement(vKeyOperation, vTimeFrom);
	
	// 18. Process user exit algorithm if any
	vUserExitProc2 = Catalogs.ExternalDataProcessors.CloseOfPeriod;
	If ValueIsFilled(vUserExitProc2) Then
		If vUserExitProc2.ExternalProcessingType = Enums.ExternalProcessingTypes.Algorithm Then
			If Not IsBlankString(vUserExitProc2.Algorithm) Then     
				vKeyOperation = "CloseOfPeriod.UserExitProcedure";
				vTimeFrom = APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, New UUID);
	
				// Log start of user external algorithm
				WriteLogEvent(NStr("en='CloseOfPeriod.UserExitProcedure';ru='ЗакрытиеПериода.АлгоритмПользователя';de='CloseOfPeriod.UserExitProcedure'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='Start of user exit procedure...';ru='Начато выполнение пользовательского алгоритма...';de='Die Ausführung des Nutzeralgorithmus wurde gestartet…'"), EventLogEntryTransactionMode.Independent);
				SetSafeMode(True);
				Execute(TrimAll(vUserExitProc2.Algorithm));
				SetSafeMode(False);
				WriteLogEvent(NStr("en='CloseOfPeriod.UserExitProcedure';ru='ЗакрытиеПериода.АлгоритмПользователя';de='CloseOfPeriod.UserExitProcedure'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='End of user exit procedure';ru='Закончено выполнение пользовательского алгоритма';de='Die Ausführung des Nutzeralgorithmus ist abgeschlossen'"), EventLogEntryTransactionMode.Independent);
				APDEXPerformanceSystemOnClientServer.FinishTimeIntervalMeasurement(vKeyOperation, vTimeFrom);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // Posting

// -----------------------------------------------------------------------------
Procedure UndoPosting(pCancel)
	// Delete all charges of this document
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Docs.Ref,
	|	Docs.PointInTime
	|FROM
	|	(SELECT
	|		Charge.Ref AS Ref,
	|		Charge.PointInTime AS PointInTime
	|	FROM
	|		Document.Charge AS Charge
	|	WHERE
	|		Charge.Posted
	|		AND Charge.ParentDoc = &qParentDoc
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ChargeTransfer.Ref,
	|		ChargeTransfer.PointInTime
	|	FROM
	|		Document.ChargeTransfer AS ChargeTransfer
	|	WHERE
	|		ChargeTransfer.Posted
	|		AND ChargeTransfer.ParentDoc = &qParentDoc
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Storno.Ref,
	|		Storno.PointInTime
	|	FROM
	|		Document.Storno AS Storno
	|	WHERE
	|		Storno.Posted
	|		AND Storno.ParentDoc = &qParentDoc) AS Docs
	|
	|ORDER BY
	|	Docs.PointInTime DESC";
	vQry.SetParameter("qParentDoc", Ref);
	vDocs = vQry.Execute().Unload();
	For Each vDocsRow In vDocs Do
		vDocObj = vDocsRow.Ref.GetObject();
		vDocObj.SetDeletionMark(True);
	EndDo;
EndProcedure // UndoPosting

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function CheckIfDocumentIsAlreadyPosted()
	vIsPosted = False;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Settlement.Ref
	|FROM
	|	Document.Settlement AS Settlement
	|WHERE
	|	Settlement.CloseOfPeriod = &qCloseOfPeriod
	|	AND Settlement.Posted
	|
	|ORDER BY
	|	Settlement.PointInTime";
	vQry.SetParameter("qCloseOfPeriod", Ref);
	vQryRes = vQry.Execute();
	If Not vQryRes.IsEmpty() Then
		vIsPosted = True;
	EndIf;
	Return vIsPosted; 
EndFunction // CheckIfDocumentIsAlreadyPosted

// -----------------------------------------------------------------------------
Function GetOpenFoliosCountForGuestGroup(pGuestGroup)
	vQry = New Query();
	vQry.Text =
	"SELECT
	|	Folios.Ref AS Folio
	|FROM
	|	Document.Folio AS Folios
	|WHERE
	|	Folios.GuestGroup = &qGuestGroup
	|	AND (NOT Folios.IsClosed)
	|	AND (NOT Folios.DeletionMark)";
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vQryRes = vQry.Execute().Unload();
	// Remove folios where parent document is not accommodation
	i = 0;
	While i < vQryRes.Count() Do
		vRow = vQryRes.Get(i);
		If Not vRow.Folio.IsMaster Then
			If ValueIsFilled(vRow.Folio.ParentDoc) Then
				If TypeOf(vRow.Folio.ParentDoc) <> Type("DocumentRef.Accommodation") And 
				   TypeOf(vRow.Folio.ParentDoc) <> Type("DocumentRef.Reservation") Then
					vQryRes.Delete(vRow);
					Continue;
				Else
					If Not vRow.Folio.ParentDoc.Posted Then
						vQryRes.Delete(vRow);
						Continue;
					EndIf;
				EndIf;
			Else
				vQryRes.Delete(vRow);
				Continue;
			EndIf;
		EndIf;
		i = i + 1;
	EndDo;
	// Return folios count
	Return vQryRes.Count();
EndFunction // GetOpenFoliosCountForGuestGroup

// -----------------------------------------------------------------------------
Function GetOpenFoliosCountForEvent(pEvent, pHotel)
	vQry = New Query();
	vQry.Text =
	"SELECT
	|	Folios.Ref AS Folio
	|FROM
	|	Document.Folio AS Folios
	|WHERE
	|	Folios.Hotel = &qHotel
	|	AND Folios.GuestGroup.Event = &qEvent
	|	AND NOT Folios.IsClosed
	|	AND NOT Folios.DeletionMark";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qEvent", pEvent);
	vQryRes = vQry.Execute().Unload();
	// Remove folios where parent document is not accommodation
	i = 0;
	While i < vQryRes.Count() Do
		vRow = vQryRes.Get(i);
		If Not vRow.Folio.IsMaster Then
			If ValueIsFilled(vRow.Folio.ParentDoc) Then
				If TypeOf(vRow.Folio.ParentDoc) <> Type("DocumentRef.Accommodation") And 
				   TypeOf(vRow.Folio.ParentDoc) <> Type("DocumentRef.Reservation") Then
					vQryRes.Delete(vRow);
					Continue;
				Else
					If Not vRow.Folio.ParentDoc.Posted Then
						vQryRes.Delete(vRow);
						Continue;
					EndIf;
				EndIf;
			Else
				vQryRes.Delete(vRow);
				Continue;
			EndIf;
		EndIf;
		i = i + 1;
	EndDo;
	// Return folios count
	Return vQryRes.Count();
EndFunction // GetOpenFoliosCountForEvent

// -----------------------------------------------------------------------------
Procedure UpdateReportingCurrencyExchangeRates(pDate, pIsPosted = False)
	// Do processing if document is not posted only
	If pIsPosted Then
		Return;
	EndIf;
	// Log start of charge reporting currency exchange rates update
	WriteLogEvent(NStr("en='CloseOfPeriod.ReportingCurrencyExchangeRatesUpdate';ru='ЗакрытиеПериода.ОбновлениеКурсовОтчетнойВалюты';de='CloseOfPeriod.ReportingCurrencyExchangeRatesUpdate'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='Start reporting currency exchange rates update...';ru='Начата операция обновления курсов отчетной валюты...';de='Die Aktualisierung der Berichtswährungskurse wurde gestartet…'"), EventLogEntryTransactionMode.Independent);
	// Initialize value list of charges processed
	vChargesProcessed = New ValueList();
	// Get charges that should be recalculated
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Charge.Ref AS Charge,
	|	ISNULL(CurrencyRates.Rate, 0) AS CurrencyRate,
	|	ISNULL(CurrencyRates.Factor, 0) AS CurrencyFactor
	|FROM
	|	Document.Charge AS Charge
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
	|				&qPeriod,
	|				Hotel IN HIERARCHY (&qHotel)
	|					OR &qHotelIsEmpty) AS CurrencyRates
	|		ON (CurrencyRates.Currency = Charge.ReportingCurrency)
	|WHERE
	|	Charge.Posted
	|	AND Charge.ExchangeRateDate = &qDate
	|	AND Charge.ReportingCurrencyExchangeRate <> (CAST(ISNULL(CurrencyRates.Rate, 0) / ISNULL(CurrencyRates.Factor, 1) AS NUMBER(19, 7)))
	|	AND (Charge.Hotel IN HIERARCHY (&qHotel)
	|			OR &qHotelIsEmpty)
	|	AND (Charge.Company IN HIERARCHY (&qCompany)
	|			OR &qCompanyIsEmpty)";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQry.SetParameter("qPeriod", EndOfDay(pDate));
	vQry.SetParameter("qDate", BegOfDay(pDate));
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		If vQryRes.CurrencyRate > 0 And vQryRes.CurrencyFactor > 0 Then
			vChargeObj = vQryRes.Charge.GetObject();
			If ValueIsFilled(vChargeObj.ReportingCurrency) Then
				vChargeObj.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(vChargeObj.Hotel, vChargeObj.FolioCurrency, vChargeObj.ExchangeRateDate);
				vChargeObj.ReportingCurrencyExchangeRate = cmGetCurrencyExchangeRate(vChargeObj.Hotel, vChargeObj.ReportingCurrency, vChargeObj.ExchangeRateDate);
				vChargeObj.Write(DocumentWriteMode.Posting);
				// Add to charges processed value list
				vChargesProcessed.Add(vQryRes.Charge);
			EndIf;
		EndIf;
	EndDo;
	// Repost storno based on charges processed
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Storno.Ref AS Storno
	|FROM
	|	Document.Storno AS Storno
	|WHERE
	|	Storno.Posted
	|	AND Storno.Ref IN(&qCharges)";
	vQry.SetParameter("qCharges", vChargesProcessed);
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vStornoObj = vQryRes.Storno.GetObject();
		vStornoObj.Write(DocumentWriteMode.Posting);
	EndDo;
	// Log end of charge reporting currency exchange rates update
	WriteLogEvent(NStr("en='CloseOfPeriod.ReportingCurrencyExchangeRatesUpdate';ru='ЗакрытиеПериода.ОбновлениеКурсовОтчетнойВалюты';de='CloseOfPeriod.ReportingCurrencyExchangeRatesUpdate'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='Number of charges where reporting currency exchange rates were updated is ';ru='Обновлены курсы отчетной валюты у начислений: ';de='Die Kurse der Berichtswährung bei Anrechnungen sind aktualisiert: '") + vChargesProcessed.Count(), EventLogEntryTransactionMode.Independent);
EndProcedure // UpdateReportingCurrencyExchangeRates 

// -----------------------------------------------------------------------------
Procedure DeleteServicesThatShouldBeChargedExternally(pIsPosted)
	// Do processing if document is not posted only
	If pIsPosted Then
		Return;
	EndIf;
	// Log start of charge reporting currency exchange rates update
	WriteLogEvent(NStr("en='CloseOfPeriod.DeleteServicesThatShouldBeChargedExternally';de='CloseOfPeriod.DeleteServicesThatShouldBeChargedExternally';ru='ЗакрытиеПериода.УдалениеУслугКоторыеДолжныБытьНачисленыИзВнешнейСистемы'"), EventLogLevel.Information, Metadata(), Ref, NStr("ru = 'Начата операция удаления начислений...';en = 'Start deletion of charges...';de = 'Start deletion of charges...'"), EventLogEntryTransactionMode.Independent);
	// Initialize value list of documents processed
	vDocsProcessed = New ValueList();
	// Get accommodations that should be reposted
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	Accommodation.Ref AS Doc
	|FROM
	|	Document.Accommodation.Services AS Accommodation
	|WHERE
	|	Accommodation.Ref.Posted
	|	AND Accommodation.Ref.AccommodationStatus.IsActive
	|	AND Accommodation.Ref.CheckInDate < &qEndOfDate
	|	AND Accommodation.Ref.CheckOutDate > &qBegOfDate
	|	AND ISNULL(Accommodation.Service.ServiceType.ActualAmountIsChargedExternally, FALSE)
	|	AND (Accommodation.Ref.Hotel IN HIERARCHY (&qHotel)
	|			OR &qHotelIsEmpty)
	|	AND (Accommodation.Folio.Company IN HIERARCHY (&qCompany)
	|			OR &qCompanyIsEmpty)";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQry.SetParameter("qEndOfDate", EndOfDay(Date));
	vQry.SetParameter("qBegOfDate", BegOfDay(Date));
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vAccObj = vQryRes.Doc.GetObject();
		vAccObj.AdditionalProperties.Insert("CloseOfDayMode", True);
		vAccObj.AdditionalProperties.Insert("AccountingDate", BegOfDay(Date));
		vAccObj.Write(DocumentWriteMode.Posting);
		// Add to charges processed value list
		vDocsProcessed.Add(vQryRes.Doc);
	EndDo;
	// Log end of charge reporting currency exchange rates update
	WriteLogEvent(NStr("en='CloseOfPeriod.DeleteServicesThatShouldBeChargedExternally';de='CloseOfPeriod.DeleteServicesThatShouldBeChargedExternally';ru='ЗакрытиеПериода.УдалениеУслугКоторыеДолжныБытьНачисленыИзВнешнейСистемы'"), EventLogLevel.Information, Metadata(), Ref, NStr("ru = 'Кол-во перепроведенных размещений: ';en = 'Number of reposted accommodations is: ';de = 'Number of reposted accommodations is: '") + vDocsProcessed.Count(), EventLogEntryTransactionMode.Independent);
	// Initialize value list of documents processed
	vDocsProcessed = New ValueList();
	// Get resource reservations that should be reposted
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	ResourceReservations.Ref AS Doc
	|FROM
	|	Document.ResourceReservation.Services AS ResourceReservations
	|WHERE
	|	ResourceReservations.Ref.Posted
	|	AND ResourceReservations.Ref.ResourceReservationStatus.IsActive
	|	AND NOT ResourceReservations.Ref.ResourceReservationStatus.DoCharging
	|	AND ResourceReservations.Ref.DateTimeFrom < &qEndOfDate
	|	AND ResourceReservations.Ref.DateTimeTo > &qBegOfDate
	|	AND ISNULL(ResourceReservations.Service.ServiceType.ActualAmountIsChargedExternally, FALSE)
	|	AND (ResourceReservations.Ref.Hotel IN HIERARCHY (&qHotel)
	|			OR &qHotelIsEmpty)
	|	AND (ResourceReservations.Ref.ChargingFolio.Company IN HIERARCHY (&qCompany)
	|			OR &qCompanyIsEmpty)";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQry.SetParameter("qEndOfDate", EndOfDay(Date));
	vQry.SetParameter("qBegOfDate", BegOfDay(Date));
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vRRObj = vQryRes.Doc.GetObject();
		vRRObj.AdditionalProperties.Insert("CloseOfDayMode", True);
		vRRObj.AdditionalProperties.Insert("AccountingDate", BegOfDay(Date) + 24*3600);
		vRRObj.Write(DocumentWriteMode.Posting);
		// Add to charges processed value list
		vDocsProcessed.Add(vQryRes.Doc);
	EndDo;
	// Log end of charge reporting currency exchange rates update
	WriteLogEvent(NStr("en='CloseOfPeriod.DeleteServicesThatShouldBeChargedExternally';de='CloseOfPeriod.DeleteServicesThatShouldBeChargedExternally';ru='ЗакрытиеПериода.УдалениеУслугКоторыеДолжныБытьНачисленыИзВнешнейСистемы'"), EventLogLevel.Information, Metadata(), Ref, NStr("ru = 'Кол-во перепроведенных броней ресурсов: ';en = 'Number of reposted resource reservations is: ';de = 'Number of reposted resource reservations is: '") + vDocsProcessed.Count(), EventLogEntryTransactionMode.Independent);
EndProcedure // DeleteServicesThatShouldBeChargedExternally 

// -----------------------------------------------------------------------------
Function CheckRevenueServicesCount(pDimensionsRow)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN ISNULL(CurrentAccountsReceivable.Charge.IsRoomRevenue, FALSE)
	|				OR ISNULL(CurrentAccountsReceivable.Charge.IsResourceRevenue, FALSE)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS IsRevenue,
	|	ISNULL(CurrentAccountsReceivable.Charge.Folio.IsClosed, FALSE) AS IsClosed,
	|	COUNT(*) AS Count
	|FROM
	|	AccumulationRegister.CurrentAccountsReceivable AS CurrentAccountsReceivable
	|WHERE
	|	CurrentAccountsReceivable.Period >= &qPeriodFrom
	|	AND CurrentAccountsReceivable.Hotel = &qHotel
	|	AND CurrentAccountsReceivable.Company = &qCompany
	|	AND CurrentAccountsReceivable.Customer = &qCustomer
	|	AND CurrentAccountsReceivable.Contract = &qContract
	|	AND CurrentAccountsReceivable.GuestGroup = &qGuestGroup
	|	AND CurrentAccountsReceivable.FolioCurrency = &qFolioCurrency" + 
		?(ValueIsFilled(pDimensionsRow.SeparateAccommodation), " AND Charge.ParentDoc = &qAccommodation", "") + 
		?(ValueIsFilled(pDimensionsRow.SeparateService) AND TypeOf(pDimensionsRow.SeparateService)=Type("CatalogRef.Services"), " AND Charge.Service = &qService", "") + 
		?(ValueIsFilled(pDimensionsRow.SeparateService) AND TypeOf(pDimensionsRow.SeparateService)=Type("String"), " AND Charge.Service.InvoiceGroupingName = &qService", "") + "
	|
	|GROUP BY
	|	CASE
	|		WHEN ISNULL(CurrentAccountsReceivable.Charge.IsRoomRevenue, FALSE)
	|				OR ISNULL(CurrentAccountsReceivable.Charge.IsResourceRevenue, FALSE)
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	ISNULL(CurrentAccountsReceivable.Charge.Folio.IsClosed, FALSE)";
	vQry.SetParameter("qPeriodFrom", Date + 1);
	vQry.SetParameter("qHotel", pDimensionsRow.Hotel);
	vQry.SetParameter("qCompany", pDimensionsRow.Company);
	vQry.SetParameter("qCustomer", pDimensionsRow.Customer);
	vQry.SetParameter("qContract", pDimensionsRow.Contract);
	vQry.SetParameter("qGuestGroup", pDimensionsRow.GuestGroup);
	vQry.SetParameter("qFolioCurrency", pDimensionsRow.FolioCurrency);
	vQry.SetParameter("qAccommodation", pDimensionsRow.SeparateAccommodation);
	vQry.SetParameter("qService", pDimensionsRow.SeparateService);
	vCharges = vQry.Execute().Unload();
	vRevenueServicesFound = False;
	vExtraServicesFound = False;
	vFoliosAreClosed = True;
	For Each vChargesRow In vCharges Do
		If Not vChargesRow.IsClosed Then
			vFoliosAreClosed = False;
		EndIf;
		If Not vChargesRow.IsRevenue Then
			vExtraServicesFound = True;
		Else
			vRevenueServicesFound = True;
		EndIf;
	EndDo;
	If vFoliosAreClosed And vExtraServicesFound And Not vRevenueServicesFound Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // CheckRevenueServicesCount

// -----------------------------------------------------------------------------
Function GetGuestGroupsWithCorrections(pIsPosted = False)
	vGuestGroupsWithCorrections = New ValueList();
	// Do processing if document is not posted only
	If pIsPosted Then
		Return vGuestGroupsWithCorrections;
	EndIf;
	// Date to be used to decide that it is previous period correction
	vDate = EndOfDay(Date) + 1;
	// Run query to get all charges that have already be invoiced but have non zero balance 
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	GroupsWithCorrections.GuestGroup AS GuestGroup,
	|	SUM(GroupsWithCorrections.Amount) AS Amount,
	|	SUM(GroupsWithCorrections.Quantity) AS Quantity
	|FROM
	|	(SELECT
	|		CurrentAccountsReceivableBalance.Hotel AS Hotel,
	|		CurrentAccountsReceivableBalance.Company AS Company,
	|		CurrentAccountsReceivableBalance.Customer AS Customer,
	|		CurrentAccountsReceivableBalance.Contract AS Contract,
	|		CurrentAccountsReceivableBalance.GuestGroup AS GuestGroup,
	|		CurrentAccountsReceivableBalance.FolioCurrency AS FolioCurrency,
	|		CASE
	|			WHEN CurrentAccountsReceivableBalance.Charge.CorrectedCharge.Number IS NULL
	|				THEN CurrentAccountsReceivableBalance.Charge
	|			ELSE CurrentAccountsReceivableBalance.Charge.CorrectedCharge
	|		END AS Charge,
	|		SUM(CurrentAccountsReceivableBalance.SumBalance) AS Amount,
	|		SUM(CurrentAccountsReceivableBalance.QuantityBalance) AS Quantity
	|	FROM
	|		AccumulationRegister.CurrentAccountsReceivable.Balance(&qDate, TRUE" +
			?(ValueIsFilled(Hotel), " AND Hotel IN HIERARCHY(&qHotel)", "") + 
			?(ValueIsFilled(Company), " AND Company IN HIERARCHY(&qCompany)", "") + 
			?(ProcessClosedFoliosOnly, " AND (ISNULL(Charge.Folio.IsClosed, FALSE) AND NOT ISNULL(GuestGroup.IsPending, FALSE) OR Charge.Service.IsStockArticle OR (Charge.Folio.DateTimeTo = &qEmptyDate AND &qIsEndOfAccountingPeriod))", 
			                           ?(Company.CreateSettlementsAtCheckOutDateForCustomers, " AND (ISNULL(Charge.Folio.IsClosed, FALSE) OR NOT ISNULL(Charge.Folio.IsClosed, FALSE) AND ISNULL(Customer.IsIndividual, TRUE) OR Charge.Service.IsStockArticle)", "")) + "
	|		) AS CurrentAccountsReceivableBalance
	|			INNER JOIN Document.Settlement.Services AS InvoiceServices
	|			ON (CASE
	|					WHEN CurrentAccountsReceivableBalance.Charge.CorrectedCharge.Number IS NULL
	|						THEN CurrentAccountsReceivableBalance.Charge
	|					ELSE CurrentAccountsReceivableBalance.Charge.CorrectedCharge
	|				END = InvoiceServices.Charge)
	|				AND (InvoiceServices.Ref.Posted)
	|	
	|	GROUP BY
	|		CurrentAccountsReceivableBalance.Hotel,
	|		CurrentAccountsReceivableBalance.Company,
	|		CurrentAccountsReceivableBalance.Customer,
	|		CurrentAccountsReceivableBalance.Contract,
	|		CurrentAccountsReceivableBalance.GuestGroup,
	|		CurrentAccountsReceivableBalance.FolioCurrency,
	|		CASE
	|			WHEN CurrentAccountsReceivableBalance.Charge.CorrectedCharge.Number IS NULL
	|				THEN CurrentAccountsReceivableBalance.Charge
	|			ELSE CurrentAccountsReceivableBalance.Charge.CorrectedCharge
	|		END
	|	
	|	HAVING
	|		(SUM(CurrentAccountsReceivableBalance.SumBalance) <> 0
	|			OR SUM(CurrentAccountsReceivableBalance.QuantityBalance) <> 0)) AS GroupsWithCorrections
	|
	|GROUP BY
	|	GroupsWithCorrections.GuestGroup"; 
	vQry.SetParameter("qDate", New Boundary(vDate, BoundaryType.Excluding));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyDate", '00010101');
	If ValueIsFilled(Company) Then
		If Company.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.Year Then
			vQry.SetParameter("qIsEndOfAccountingPeriod", ?(EndOfDay(Date) = EndOfYear(Date), True, False));
		ElsIf Company.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.HalfYear Then
			vQry.SetParameter("qIsEndOfAccountingPeriod", ?(EndOfDay(Date) = EndOfMonth(AddMonth(BegOfYear(Date), 6)), True, False));
		ElsIf Company.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.Quarter Then
			vQry.SetParameter("qIsEndOfAccountingPeriod", ?(EndOfDay(Date) = EndOfQuarter(Date), True, False));
		ElsIf Company.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.Month Then
			If Company.CloseMonthAtDayBeforeTheLastMonthDay Then
				vQry.SetParameter("qIsEndOfAccountingPeriod", ?(EndOfDay(Date) = (EndOfMonth(Date) - 24*3600), True, False));
			Else
				vQry.SetParameter("qIsEndOfAccountingPeriod", ?(EndOfDay(Date) = EndOfMonth(Date), True, False));
			EndIf;
		ElsIf Company.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.Decade Then
			vDay = Day(Date);
			If vDay = 10 Then
				vQry.SetParameter("qIsEndOfAccountingPeriod", True);
			ElsIf vDay = 20 Then 
				vQry.SetParameter("qIsEndOfAccountingPeriod", True);
			Else
				If Company.CloseMonthAtDayBeforeTheLastMonthDay Then
					vQry.SetParameter("qIsEndOfAccountingPeriod", ?(EndOfDay(Date) = (EndOfMonth(Date) - 24*3600), True, False));
				Else
					vQry.SetParameter("qIsEndOfAccountingPeriod", ?(EndOfDay(Date) = EndOfMonth(Date), True, False));
				EndIf;
			EndIf;
		Else
			vQry.SetParameter("qIsEndOfAccountingPeriod", False);
		EndIf;
	Else
		vQry.SetParameter("qIsEndOfAccountingPeriod", False);
	EndIf;
	vGroups = vQry.Execute().Unload();
	For Each vGroupsRow In vGroups Do
		If ValueIsFilled(vGroupsRow.GuestGroup) Then
			If vGuestGroupsWithCorrections.FindByValue(vGroupsRow.GuestGroup) = Undefined Then
				vGuestGroupsWithCorrections.Add(vGroupsRow.GuestGroup);
			EndIf;
		EndIf;
	EndDo;
	Return vGuestGroupsWithCorrections;
EndFunction // GetGuestGroupsWithCorrections

// -----------------------------------------------------------------------------
Function GetChargedAllotmentAmountPerDayPerRoomType(pHotel, pCompany, pRoomType, pAllotment, pAccountingDate)
	vPerDayAmount = 0;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ISNULL(SUM(SalesTotals.Sales), 0) AS Sales
	|FROM
	|	AccumulationRegister.Sales AS SalesTotals
	|WHERE
	|	SalesTotals.AccountingDate = &qAccountingDate
	|	AND (ISNULL(SalesTotals.Recorder.IsInPrice, FALSE)
	|			OR ISNULL(SalesTotals.Recorder.ParentCharge.IsInPrice, FALSE))
	|	AND (&qRoomTypeIsEmpty
	|			OR NOT &qRoomTypeIsEmpty
	|				AND SalesTotals.RoomType = &qRoomType)
	|	AND SalesTotals.Company = &qCompany
	|	AND SalesTotals.Hotel = &qHotel
	|	AND ISNULL(SalesTotals.ParentDoc.RoomQuota, &qEmptyAllotment) = &qAllotment";
	vQry.SetParameter("qAccountingDate", pAccountingDate);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qCompany", pCompany);
	vQry.SetParameter("qRoomType", pRoomType);
	vQry.SetParameter("qRoomTypeIsEmpty", Not ValueIsFilled(pRoomType));
	vQry.SetParameter("qAllotment", pAllotment);
	vQry.SetParameter("qEmptyAllotment", Catalogs.RoomQuotas.EmptyRef());
	vRes = vQry.Execute().Unload();
	If vRes.Count() > 0 Then
		vPerDayAmount = vRes.Get(0).Sales;
	EndIf;
	Return vPerDayAmount;
EndFunction // GetChargedAllotmentAmountPerDayPerRoomType

// -----------------------------------------------------------------------------
Function GetPenaltyCharge(pHotel, pAccountingDate, pFolio, pRoomRate, pRoomType, pService)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Charge.Ref AS Ref
	|FROM
	|	Document.Charge AS Charge
	|WHERE
	|	Charge.ServiceDate = &qServiceDate
	|	AND Charge.Hotel = &qHotel
	|	AND Charge.Folio = &qFolio
	|	AND Charge.Service = &qService
	|	AND Charge.RoomRate = &qRoomRate
	|	AND Charge.RoomType = &qRoomType
	|	AND Charge.Posted
	|
	|ORDER BY
	|	Charge.PointInTime";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qServiceDate", pAccountingDate);
	vQry.SetParameter("qFolio", pFolio);
	vQry.SetParameter("qRoomRate", pRoomRate);
	vQry.SetParameter("qRoomType", pRoomType);
	vQry.SetParameter("qService", pService);
	vCharges = vQry.Execute().Unload();
	If vCharges.Count() = 1 Then
		Return vCharges.Get(0).Ref;
	Else
		Return Undefined;
	EndIf;
EndFunction // GetPenaltyCharge

// -----------------------------------------------------------------------------
Procedure ClearSalesForecastForBusinessBlocks(pCancel, pPostingMode)
	WriteLogEvent(NStr("en='CloseOfPeriod.ClearSalesForecastForBusinessBlocks';ru='ЗакрытиеПериода.ОчисткаПрогнозаПродажПоБизнесБлокам';de='CloseOfPeriod.ClearSalesForecastForBusinessBlocks'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='Start of clearing business-blocks sales forecast revenue...';ru='Начата операция очистки прогноза продаж по бизнес-блокам...';de='Start of clearing business-blocks sales forecast revenue...'"), EventLogEntryTransactionMode.Independent);
	
	// Get list of commitment allotments
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SetRoomQuotas.Ref AS Ref
	|FROM
	|	Document.SetRoomQuota AS SetRoomQuotas
	|WHERE
	|	SetRoomQuotas.Posted
	|	AND SetRoomQuotas.RoomQuota.AllotmentBusinessType = VALUE(Enum.AllotmentBusinessTypes.BusinessBlock)
	|	AND (SetRoomQuotas.Hotel = &qHotel
	|			OR &qHotel = &qEmptyHotel)
	|	AND SetRoomQuotas.DateFrom <= &qDate
	|	AND SetRoomQuotas.DateTo > &qBegOfDate
	|
	|ORDER BY
	|	SetRoomQuotas.PointInTime";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qBegOfDate", BegOfDay(Date));
	vQry.SetParameter("qDate", EndOfDay(Date));
	vDocs = vQry.Execute().Unload();
	For Each vDocsRow In vDocs Do
		vDocObj = vDocsRow.Ref.GetObject();
		vDocObj.AdditionalProperties.Insert("CloseOfDayMode", True);
		vDocObj.AdditionalProperties.Insert("AccountingDate", BegOfDay(Date) + 24*3600);
		vDocObj.pmClearSalesForecastInThePast();
	EndDo;
	
	WriteLogEvent(NStr("en='CloseOfPeriod.ClearSalesForecastForBusinessBlocks';ru='ЗакрытиеПериода.ОчисткаПрогнозаПродажПоБизнесБлокам';de='CloseOfPeriod.ClearSalesForecastForBusinessBlocks'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='End of clearing business-blocks sales forecast revenue...';ru='Закончена операция очистки прогноза продаж по бизнес-блокам...';de='End of clearing business-blocks sales forecast revenue...'"), EventLogEntryTransactionMode.Independent);
EndProcedure // ClearSalesForecastForBusinessBlocks
	
// -----------------------------------------------------------------------------
Procedure ChargeCommitmentAllotments(pCancel, pPostingMode)
	WriteLogEvent(NStr("en='CloseOfPeriod.ChargeCommitmentAllotments';ru='ЗакрытиеПериода.НачислениеШтрафовПоЖесткимБлокам';de='CloseOfPeriod.ChargeCommitmentAllotments'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='Start of charging commitment allotment fees...';ru='Начата операция начисления штрафов по <жестким> блокам...';de='Start of charging commitment allotment fees…'"), EventLogEntryTransactionMode.Independent);
	
	// Get list of commitment allotments
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomQuotas.Ref AS Ref
	|FROM
	|	Catalog.RoomQuotas AS RoomQuotas
	|WHERE
	|	NOT RoomQuotas.DeletionMark
	|	AND NOT RoomQuotas.IsFolder
	|	AND RoomQuotas.IsCommitment
	|	AND RoomQuotas.DoCharge
	|	AND NOT RoomQuotas.IsQuotaForRooms
	|	AND (RoomQuotas.Company = &qEmptyCompany
	|			OR RoomQuotas.Company = &qCompany)
	|	AND (RoomQuotas.Hotel = &qEmptyHotel
	|			OR RoomQuotas.Hotel = &qHotel
	|			OR &qHotel = &qEmptyHotel)
	|	AND RoomQuotas.PeriodFrom <= &qEndOfMonth
	|	AND (RoomQuotas.PeriodTo = &qEmptyDate
	|			OR RoomQuotas.PeriodTo > &qBegOfMonth)
	|
	|ORDER BY
	|	RoomQuotas.SortCode,
	|	RoomQuotas.Description";
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCompany", Catalogs.Companies.EmptyRef());
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qBegOfMonth", BegOfMonth(Date));
	vQry.SetParameter("qEndOfMonth", EndOfMonth(Date));
	vQry.SetParameter("qEmptyDate", '00010101');
	vAllotments = vQry.Execute().Unload();
	For Each vAllotmentsRow In vAllotments Do
		vAllotment = vAllotmentsRow.Ref;
		If Not ValueIsFilled(vAllotment.ChargingFolio) Or Not (ValueIsFilled(vAllotment.RoomRate) Or ValueIsFilled(vAllotment.UnderallotmentRoomRate)) Or Not ValueIsFilled(vAllotment.Service) Or vAllotment.PriceNumberOfAdults = 0 Then
			Continue;
		EndIf;
		vFolio = vAllotment.ChargingFolio;
		vFolioCurrency = vFolio.FolioCurrency;
		vRoomRate = vAllotment.RoomRate;
		If ValueIsFilled(vAllotment.UnderAllotmentRoomRate) Then
			vRoomRate = vAllotment.UnderAllotmentRoomRate;
		EndIf;
		vAdults = vAllotment.PriceNumberOfAdults;
		vService = vAllotment.Service;
		vServiceObj = vService.GetObject();
		vVATRate = Company.VATRate;
		vPriceRoomType = vAllotment.FlatRateRoomType;
		
		// Allotment balances for the past month
		vAllotmentBalances = cmGetRoomQuotaBalances(Hotel, Catalogs.RoomTypes.EmptyRef(), vAllotment.Customer, vAllotment.Contract, vAllotment.Agent, vAllotment, BegOfMonth(Date), EndOfMonth(Date));
		If vAllotment.FlatRateIsUsedForUnderallotmentPenaltyCalculation Then
			If Not ValueIsFilled(vPriceRoomType) Then
				For Each vAllotmentBalancesRow In vAllotmentBalances Do
					If vAllotmentBalancesRow.RoomsInQuota > 0 And ValueIsFilled(vAllotmentBalancesRow.RoomType) Then
						vPriceRoomType = vAllotmentBalancesRow.RoomType;
						Break;
					EndIf;
				EndDo;
			EndIf;
			vAllotmentBalances.GroupBy("Hotel, Period", "RoomsInQuota, RemainsRooms");
			vAllotmentBalances.Sort("Period");
			vAllotmentBalances.Columns.Add("RoomType", cmGetCatalogTypeDescription("RoomTypes"));
		EndIf;			
		vRoomAmountPerDay = 0;
		vCurrency = Undefined;
		For Each vAllotmentBalancesRow In vAllotmentBalances Do
			If vAllotmentBalancesRow.RoomsInQuota > 0 And vAllotmentBalancesRow.RemainsRooms > 0 And ValueIsFilled(vAllotmentBalancesRow.Period) Then
				vAccountingDate = BegOfDay(vAllotmentBalancesRow.Period);
				If vAccountingDate > EndOfMonth(Date) Or vAccountingDate < BegOfMonth(Date) Then
					Continue;
				EndIf;
				
				vHotel = vAllotmentBalancesRow.Hotel;
				vRoomType = vAllotmentBalancesRow.RoomType;
				If ValueIsFilled(vRoomType) Then
					vPriceRoomType = vRoomType;
				EndIf;
				
				If Not vAllotment.FlatRateIsUsedForUnderallotmentPenaltyCalculation And Not ValueIsFilled(vRoomType) Then
					Continue;
				EndIf;
				
				vGuestsQuantity = New Structure("Adults, Kids, RequestAttributes", New Structure("Quantity", vAdults), New Structure("Quantity", 0), Undefined);
				vServicePrices = vServiceObj.pmGetServicePrices(vHotel, vAccountingDate, Catalogs.ClientTypes.EmptyRef());
				For Each vServicePricesRow In vServicePrices Do
					vVATRate = vServicePricesRow.VATRate;
					Break;
				EndDo;
				
				// Get total room sales for the date, allotment and room type
				vChargedAmount = 0;
				If Not vAllotment.FlatRateIsUsedForUnderallotmentPenaltyCalculation Then
					vChargedAmount = GetChargedAllotmentAmountPerDayPerRoomType(vHotel, Company, vRoomType, vAllotment, vAccountingDate);
					vChargedAmount = cmConvertCurrencies(vChargedAmount, vHotel.ReportingCurrency, , vFolioCurrency, , vAccountingDate, vHotel);
				EndIf;
				
				// Create charge
				vPrices = cmGetAvailableRoomTypes(TrimAll(vHotel.Code), TrimAll(vRoomRate.Code), "", TrimAll(vPriceRoomType.Code), TrimAll(vAllotment.Code), vAccountingDate + 12*3600, vAccountingDate + 36*3600, "", "", vGuestsQuantity, "", "", "", "", "XDTO");
				If vPrices.AvailableRoomTypesRows <> Undefined Then
					If vPrices.AvailableRoomTypesRows.AvailableRoomTypesRow.Count() > 0 Then
						vRoomAmountPerDay = 0;
						vCurrencyCode = "";
						For Each vPricesRow In vPrices.AvailableRoomTypesRows.AvailableRoomTypesRow Do
							vRoomAmountPerDay = vRoomAmountPerDay + vPricesRow.Amount;
							vCurrencyCode = vPricesRow.CurrencyCode;
						EndDo;
						If vRoomAmountPerDay > 0 And Not IsBlankString(vCurrencyCode) Then
							vCurrency = Catalogs.Currencies.FindByCode(vCurrencyCode, False);
							If ValueIsFilled(vCurrency) Then
								vRoomAmountPerDay = cmConvertCurrencies(vRoomAmountPerDay, vCurrency, , vFolioCurrency, , vAccountingDate, vHotel);
							EndIf;
						EndIf;
					EndIf;
				EndIf;
				If vRoomAmountPerDay > 0 And ValueIsFilled(vCurrency) Then
					// Calculate allotment committed amount
					vCommittedAmount = vRoomAmountPerDay * vAllotmentBalancesRow.RoomsInQuota;
					vUndercommittedAmount = vRoomAmountPerDay * vAllotmentBalancesRow.RemainsRooms; 
			
					// Calculate fee charge amount
					vFeeAmount = 0;
					If Not vAllotment.FlatRateIsUsedForUnderallotmentPenaltyCalculation Then
						vFeeAmount = vCommittedAmount - vChargedAmount;
					Else
						vFeeAmount = vUndercommittedAmount;
					EndIf;
					If vFeeAmount > 0 Then
						vChargeRef = GetPenaltyCharge(vHotel, vAccountingDate, vFolio, vRoomRate, vRoomType, vService);
						If ValueIsFilled(vChargeRef) Then
							vChargeObj = vChargeRef.GetObject();
						Else
							vChargeObj = Documents.Charge.CreateDocument();
						EndIf;
						vChargeObj.Fill(vFolio);
						vChargeObj.Date = Date;
						vChargeObj.SetTime(AutoTimeMode.DontUse);
						vChargeObj.ServiceDate = vAccountingDate;
						vChargeObj.ParentDoc = Ref;
						vChargeObj.Hotel = vHotel;
						vChargeObj.ExchangeRateDate = vAccountingDate;
						vChargeObj.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(vChargeObj.Hotel, vChargeObj.FolioCurrency, vChargeObj.ExchangeRateDate);
						vChargeObj.ReportingCurrencyExchangeRate = cmGetCurrencyExchangeRate(vChargeObj.Hotel, vChargeObj.ReportingCurrency, vChargeObj.ExchangeRateDate);
						vChargeObj.RoomRate = vRoomRate;
						vChargeObj.RoomType = vPriceRoomType;
						vChargeObj.Service = vService;
						vChargeObj.Unit = vService.Unit;
						vChargeObj.Sum = vFeeAmount;
						vChargeObj.Quantity = vAllotmentBalancesRow.RemainsRooms;
						vChargeObj.Price = Round(vChargeObj.Sum/vChargeObj.Quantity, 2);
						vChargeObj.VATRate = vVATRate;
						vChargeObj.VATSum = cmCalculateVATSum(vChargeObj.VATRate, vChargeObj.Sum, vChargeObj.Date);
						vChargeObj.IsRoomRevenue = vServiceObj.IsRoomRevenue;
						vChargeObj.IsInPrice = vServiceObj.IsInPrice;
						vChargeObj.RoomRevenueAmountsOnly = vServiceObj.RoomRevenueAmountsOnly;
						vChargeObj.PaymentSection = vServiceObj.PaymentSection;
						If vChargeObj.IsRoomRevenue And Not vChargeObj.RoomRevenueAmountsOnly Then
							vChargeObj.RoomsRented = vChargeObj.Quantity;
							vChargeObj.BedsRented = vChargeObj.Quantity * vPriceRoomType.NumberOfBedsPerRoom;
							vChargeObj.AdditionalBedsRented = 0;
							vChargeObj.GuestDays = 0;
							vChargeObj.GuestsCheckedIn = 0;
						EndIf;
						vChargeObj.Remarks = Format(vAccountingDate, "DF=dd.MM.yyyy") + " - "  + TrimAll(vPriceRoomType) + " - "  + NStr("en='Allotment '; ru='В квоте '; de='Allotment '") + TrimAll(vAllotment) + NStr("en=' total rooms: '; ru=' всего номеров: '; de=' total Zimmer: '") + vAllotmentBalancesRow.RoomsInQuota + ", " + NStr("en='vacant: '; ru='свободно: '; de='vacant: '") + vAllotmentBalancesRow.RemainsRooms;
						// Check if charge is in closed date
						If cmIfChargeIsInClosedDay(vChargeObj) Then
							vChargeObj.Date = vHotel.AccountingDate;
						EndIf;
						// Post charge
						vChargeObj.Write(DocumentWriteMode.Posting);
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	WriteLogEvent(NStr("en='CloseOfPeriod.ChargeCommitmentAllotments';ru='ЗакрытиеПериода.НачислениеШтрафовПоЖесткимБлокам';de='CloseOfPeriod.ChargeCommitmentAllotments'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='End of charging commitment allotment fees...';ru='Закончена операция начисления штрафов по <жестким> блокам...';de='End of charging commitment allotment fees…'"), EventLogEntryTransactionMode.Independent);
EndProcedure // ChargeCommitmentAllotments

// -----------------------------------------------------------------------------
Procedure CloseHotelProducts(pCancel, pPostingMode, pIsPosted = False, pGuestGroupsWithCorrections, pProcessClosedFoliosOnly)
	// Do processing if document is not posted only
	If pIsPosted Then
		Return;
	EndIf;
	WriteLogEvent(NStr("en='CloseOfPeriod.BuildSettlementsForHotelProducts';ru='ЗакрытиеПериода.ФормированиеАктовПоПутевкам';de='CloseOfPeriod.BuildSettlementsForHotelProducts'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='Start of building hotel product settlements...';ru='Начата операция формирования актов по путевкам...';de='Erstellung von Übergabeprotokollen zu Reiseschecks wurde gestartet…'"), EventLogEntryTransactionMode.Independent);
	// Check if there are any companies waiting for hotel products
	If ValueIsFilled(Company) And Not Company.WaitForHotelProduct Then
		WriteLogEvent(NStr("en='CloseOfPeriod.BuildSettlementsForHotelProducts';ru='ЗакрытиеПериода.ФормированиеАктовПоПутевкам';de='CloseOfPeriod.BuildSettlementsForHotelProducts'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='Hotel products are not used! End of building hotel product settlements';ru='Путевки с ожиданием ввода номеров не используются! Операция формирования актов по путевкам завершена';de='Reisechecks mit erwarteter Eingabe der Nummern werden nicht verwendet! Die Erstellung eines Vorgangs nach Reisechecks ist beendet'"), EventLogEntryTransactionMode.Independent);
		Return;
	Else
		vCompanyQry = New Query();
		vCompanyQry.Text = 
		"SELECT
		|	Companies.Ref
		|FROM
		|	Catalog.Companies AS Companies
		|WHERE
		|	Companies.WaitForHotelProduct
		|	AND NOT Companies.IsFolder
		|	AND NOT Companies.DoNotGenerateInvoicesAutomaticallyAtEndOfPeriod";
		vCompanies = vCompanyQry.Execute().Unload();
		If vCompanies.Count() = 0 Then
			WriteLogEvent(NStr("en='CloseOfPeriod.BuildSettlementsForHotelProducts';ru='ЗакрытиеПериода.ФормированиеАктовПоПутевкам';de='CloseOfPeriod.BuildSettlementsForHotelProducts'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='Hotel products are not used! End of building hotel product settlements';ru='Путевки с ожиданием ввода номеров не используются! Операция формирования актов по путевкам завершена';de='Reisechecks mit erwarteter Eingabe der Nummern werden nicht verwendet! Die Erstellung eines Vorgangs nach Reisechecks ist beendet'"), EventLogEntryTransactionMode.Independent);
			Return;
		EndIf;
	EndIf;
	// Date to be used to retreive balances
	vDate = '39991231235959';
	vPastCloseMode = (BegOfDay(CurrentSessionDate()) - 24*3600) > BegOfDay(Date);
	// Get table with customers, contracts and guest groups with balances in Current Accounts Receivable
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CurrentAccountsReceivableBalance.Hotel AS Hotel,
	|	CurrentAccountsReceivableBalance.Company AS Company,
	|	CurrentAccountsReceivableBalance.Customer AS Customer,
	|	CurrentAccountsReceivableBalance.Contract AS Contract,
	|	CASE
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.GuestGroup.Event.JoinGroupsToOneInvoice, FALSE) THEN
	|			CurrentAccountsReceivableBalance.GuestGroup.Event
	|		ELSE
	|			&qEmptyEvent
	|	END AS Event,
	|	CASE
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.GuestGroup.Event.JoinGroupsToOneInvoice, FALSE) THEN
	|			CurrentAccountsReceivableBalance.GuestGroup.Event.DateFrom
	|		ELSE
	|			&qEmptyDate
	|	END AS EventDateFrom,
	|	CASE
	|		WHEN CurrentAccountsReceivableBalance.GuestGroup IN (&qGuestGroupsWithCorrections) THEN
	|			CurrentAccountsReceivableBalance.GuestGroup 
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Customer.CustomerType.OneSettlementPerCustomerGuestGroups, FALSE) AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE)) THEN
	|			&qEmptyGuestGroup
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Contract.OneSettlementPerCustomerGuestGroups, FALSE) AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE)) THEN
	|			&qEmptyGuestGroup
	|		WHEN &qOneSettlementPerCustomerGuestGroups AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE)) THEN
	|			&qEmptyGuestGroup
	|		WHEN &qOneSettlementPerIndividualsCustomerGuestGroups AND 
	|		     (CurrentAccountsReceivableBalance.Customer = &qEmptyCustomer OR CurrentAccountsReceivableBalance.Customer = CurrentAccountsReceivableBalance.Hotel.IndividualsCustomer) THEN
	|			&qEmptyGuestGroup
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.GuestGroup.Event.JoinGroupsToOneInvoice, FALSE) THEN
	|			&qEmptyGuestGroup
	|		ELSE 
	|			CurrentAccountsReceivableBalance.GuestGroup 
	|	END AS GuestGroup,
	|	CASE
	|		WHEN CurrentAccountsReceivableBalance.GuestGroup IN (&qGuestGroupsWithCorrections) THEN
	|			CurrentAccountsReceivableBalance.GuestGroup.Code 
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Customer.CustomerType.OneSettlementPerCustomerGuestGroups, FALSE) AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE)) THEN
	|			999999999999
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Contract.OneSettlementPerCustomerGuestGroups, FALSE) AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE)) THEN
	|			999999999999
	|		WHEN &qOneSettlementPerCustomerGuestGroups AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE)) THEN
	|			999999999999
	|		WHEN &qOneSettlementPerIndividualsCustomerGuestGroups AND 
	|		     (CurrentAccountsReceivableBalance.Customer = &qEmptyCustomer OR CurrentAccountsReceivableBalance.Customer = CurrentAccountsReceivableBalance.Hotel.IndividualsCustomer) THEN
	|			999999999999
	|		WHEN CurrentAccountsReceivableBalance.GuestGroup = &qEmptyGuestGroup THEN
	|			999999999999
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.GuestGroup.Event.JoinGroupsToOneInvoice, FALSE) THEN
	|			999999999999
	|		ELSE 
	|			CurrentAccountsReceivableBalance.GuestGroup.Code 
	|	END AS GuestGroupCode,
	|	CASE
	|		WHEN CurrentAccountsReceivableBalance.GuestGroup IN (&qGuestGroupsWithCorrections) THEN
	|			0 
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Customer.CustomerType.OneSettlementPerCustomerGuestGroups, FALSE) AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE)) THEN
	|			1
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Contract.OneSettlementPerCustomerGuestGroups, FALSE) AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE)) THEN
	|			1
	|		WHEN &qOneSettlementPerCustomerGuestGroups AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE)) THEN
	|			1
	|		WHEN &qOneSettlementPerIndividualsCustomerGuestGroups AND 
	|		     (CurrentAccountsReceivableBalance.Customer = &qEmptyCustomer OR CurrentAccountsReceivableBalance.Customer = CurrentAccountsReceivableBalance.Hotel.IndividualsCustomer) THEN
	|			1
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.GuestGroup.Event.JoinGroupsToOneInvoice, FALSE) THEN
	|			1
	|		ELSE 
	|			0 
	|	END AS DoNotFilterByGuestGroup,
	|	CurrentAccountsReceivableBalance.FolioCurrency AS FolioCurrency,
	|	CASE
	|		WHEN &qSplitSettllementsByVATRate THEN
	|			CurrentAccountsReceivableBalance.Charge.VATRate
	|		ELSE
	|			&qEmptyVATRate
	|	END AS VATRate,
	|	CASE
	|		WHEN &qSplitSettllementsByPaymentSections THEN
	|			CurrentAccountsReceivableBalance.Charge.PaymentSection
	|		ELSE
	|			&qEmptyPaymentSection
	|	END AS PaymentSection,
	|	CurrentAccountsReceivableBalance.Customer.Description AS CustomerDescription,
	|	CurrentAccountsReceivableBalance.Contract.Description AS ContractDescription,
	|	CASE
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Charge.ParentDoc.HasOfficialLetter, FALSE) THEN
	|			CurrentAccountsReceivableBalance.Charge.ParentDoc
	|		ELSE &qEmptyAccommodation
	|	END AS SeparateAccommodation,
	|	CASE 
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Charge.Service.SplitToSeparateSettlements, FALSE) THEN
	|			CurrentAccountsReceivableBalance.Charge.Service
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Charge.Service.DoNotExportToTheAccountingSystem, FALSE) THEN
	|			CurrentAccountsReceivableBalance.Charge.Service
	|		ELSE &qEmptyService
	|	END AS SeparateService,
	|	ISNULL(CurrentAccountsReceivableBalance.Charge.HotelProduct.Parent, &qEmptyHotelProduct) AS HotelProductParent,
	|	SUM(CurrentAccountsReceivableBalance.SumBalance) AS Sum,
	|	SUM(CurrentAccountsReceivableBalance.VATSumBalance) AS VATSum,
	|	SUM(CurrentAccountsReceivableBalance.QuantityBalance) AS Quantity,
	|	SUM(CurrentAccountsReceivableBalance.CommissionSumBalance) AS CommissionSum
	|FROM
	|	AccumulationRegister.CurrentAccountsReceivable.Balance(
	|		&qDate, 
	|		Charge.Service.IsHotelProductService 
	|		AND Company.WaitForHotelProduct
	|		AND NOT Company.DoNotGenerateInvoicesAutomaticallyAtEndOfPeriod
	|				AND CASE
	|						WHEN NOT Company.CreateSettlementsForNonIndividualsClosingByCityLedgerOnly
	|							THEN TRUE
	|						ELSE
	|							CASE
	|								WHEN ISNULL(Customer.IsIndividual, TRUE)
	|									THEN TRUE
	|								WHEN Charge.Folio.PaymentMethod = VALUE(Catalog.PaymentMethods.Settlement)
	|									THEN TRUE
	|								WHEN ISNULL(Charge.Folio.PaymentMethod.IsByBankTransfer, FALSE)
	|									THEN TRUE
	|								ELSE
	|									FALSE
	|							END
	|						END
	|		AND Charge.HotelProduct <> &qEmptyHotelProduct
	|		" + 
			?(ValueIsFilled(Hotel), " AND Hotel IN HIERARCHY(&qHotel)", "") + 
			?(ValueIsFilled(Company), " AND Company IN HIERARCHY(&qCompany)", "") + 
			?(pProcessClosedFoliosOnly, ?(vPastCloseMode, " AND BEGINOFPERIOD(ISNULL(Charge.Folio.DateTimeTo, &qEmptyDate), DAY) <= &qBegOfPeriodTo", "") + " AND ISNULL(Charge.Folio.IsClosed, FALSE) AND NOT ISNULL(GuestGroup.IsPending, FALSE)", 
			                           ?(ValueIsFilled(Company) And Company.CreateSettlementsAtCheckOutDateForCustomers, " AND (ISNULL(Charge.Folio.IsClosed, FALSE) OR NOT ISNULL(Charge.Folio.IsClosed, FALSE) AND ISNULL(Customer.IsIndividual, TRUE) OR Charge.Service.IsStockArticle)", "")) + "
	|		AND ISNULL(Charge.Folio.DateTimeFrom, &qEmptyDate) <= &qPeriodTo
	|		AND ISNULL(Charge.Date, &qEmptyDate) > Hotel.EditProhibitedDate
	|	) AS CurrentAccountsReceivableBalance
	|
	|GROUP BY
	|	CurrentAccountsReceivableBalance.Hotel,
	|	CurrentAccountsReceivableBalance.Company,
	|	CurrentAccountsReceivableBalance.Customer,
	|	CurrentAccountsReceivableBalance.Contract,
	|	CASE
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.GuestGroup.Event.JoinGroupsToOneInvoice, FALSE) THEN
	|			CurrentAccountsReceivableBalance.GuestGroup.Event
	|		ELSE
	|			&qEmptyEvent
	|	END,
	|	CASE
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.GuestGroup.Event.JoinGroupsToOneInvoice, FALSE) THEN
	|			CurrentAccountsReceivableBalance.GuestGroup.Event.DateFrom
	|		ELSE
	|			&qEmptyDate
	|	END,
	|	CASE
	|		WHEN CurrentAccountsReceivableBalance.GuestGroup IN (&qGuestGroupsWithCorrections) THEN
	|			CurrentAccountsReceivableBalance.GuestGroup 
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Customer.CustomerType.OneSettlementPerCustomerGuestGroups, FALSE) AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE)) THEN
	|			&qEmptyGuestGroup
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Contract.OneSettlementPerCustomerGuestGroups, FALSE) AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE)) THEN
	|			&qEmptyGuestGroup
	|		WHEN &qOneSettlementPerCustomerGuestGroups AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE)) THEN
	|			&qEmptyGuestGroup
	|		WHEN &qOneSettlementPerIndividualsCustomerGuestGroups AND 
	|		     (CurrentAccountsReceivableBalance.Customer = &qEmptyCustomer OR CurrentAccountsReceivableBalance.Customer = CurrentAccountsReceivableBalance.Hotel.IndividualsCustomer) THEN
	|			&qEmptyGuestGroup
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.GuestGroup.Event.JoinGroupsToOneInvoice, FALSE) THEN
	|			&qEmptyGuestGroup
	|		ELSE 
	|			CurrentAccountsReceivableBalance.GuestGroup 
	|	END,
	|	CASE
	|		WHEN CurrentAccountsReceivableBalance.GuestGroup IN (&qGuestGroupsWithCorrections) THEN
	|			CurrentAccountsReceivableBalance.GuestGroup.Code 
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Customer.CustomerType.OneSettlementPerCustomerGuestGroups, FALSE) AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE)) THEN
	|			999999999999
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Contract.OneSettlementPerCustomerGuestGroups, FALSE) AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE)) THEN
	|			999999999999
	|		WHEN &qOneSettlementPerCustomerGuestGroups AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE)) THEN
	|			999999999999
	|		WHEN &qOneSettlementPerIndividualsCustomerGuestGroups AND 
	|		     (CurrentAccountsReceivableBalance.Customer = &qEmptyCustomer OR CurrentAccountsReceivableBalance.Customer = CurrentAccountsReceivableBalance.Hotel.IndividualsCustomer) THEN
	|			999999999999
	|		WHEN CurrentAccountsReceivableBalance.GuestGroup = &qEmptyGuestGroup THEN
	|			999999999999
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.GuestGroup.Event.JoinGroupsToOneInvoice, FALSE) THEN
	|			999999999999
	|		ELSE 
	|			CurrentAccountsReceivableBalance.GuestGroup.Code 
	|	END,
	|	CASE
	|		WHEN CurrentAccountsReceivableBalance.GuestGroup IN (&qGuestGroupsWithCorrections) THEN
	|			0 
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Customer.CustomerType.OneSettlementPerCustomerGuestGroups, FALSE) AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE)) THEN
	|			1
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Contract.OneSettlementPerCustomerGuestGroups, FALSE) AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE)) THEN
	|			1
	|		WHEN &qOneSettlementPerCustomerGuestGroups AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE)) THEN
	|			1
	|		WHEN &qOneSettlementPerIndividualsCustomerGuestGroups AND 
	|		     (CurrentAccountsReceivableBalance.Customer = &qEmptyCustomer OR CurrentAccountsReceivableBalance.Customer = CurrentAccountsReceivableBalance.Hotel.IndividualsCustomer) THEN
	|			1
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.GuestGroup.Event.JoinGroupsToOneInvoice, FALSE) THEN
	|			1
	|		ELSE 
	|			0 
	|	END,
	|	CurrentAccountsReceivableBalance.FolioCurrency,
	|	CASE
	|		WHEN &qSplitSettllementsByVATRate THEN
	|			CurrentAccountsReceivableBalance.Charge.VATRate
	|		ELSE
	|			&qEmptyVATRate
	|	END,
	|	CASE
	|		WHEN &qSplitSettllementsByPaymentSections THEN
	|			CurrentAccountsReceivableBalance.Charge.PaymentSection
	|		ELSE
	|			&qEmptyPaymentSection
	|	END,
	|	CurrentAccountsReceivableBalance.Customer.Description,
	|	CurrentAccountsReceivableBalance.Contract.Description,
	|	CASE
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Charge.ParentDoc.HasOfficialLetter, FALSE) THEN
	|			CurrentAccountsReceivableBalance.Charge.ParentDoc
	|		ELSE &qEmptyAccommodation
	|	END,
	|	CASE 
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Charge.Service.SplitToSeparateSettlements, FALSE) THEN
	|			CurrentAccountsReceivableBalance.Charge.Service
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Charge.Service.DoNotExportToTheAccountingSystem, FALSE) THEN
	|			CurrentAccountsReceivableBalance.Charge.Service
	|		ELSE &qEmptyService
	|	END,
	|	ISNULL(CurrentAccountsReceivableBalance.Charge.HotelProduct.Parent, &qEmptyHotelProduct)
	|HAVING
	|	SUM(CurrentAccountsReceivableBalance.SumBalance) <> 0 OR
	|	SUM(CurrentAccountsReceivableBalance.VATSumBalance) <> 0 OR
	|	SUM(CurrentAccountsReceivableBalance.QuantityBalance) <> 0 OR
	|	SUM(CurrentAccountsReceivableBalance.CommissionSumBalance) <> 0
	|ORDER BY
	|	CustomerDescription,
	|	ContractDescription,
	|	EventDateFrom,
	|	GuestGroupCode,
	|	DoNotFilterByGuestGroup DESC,
	|	FolioCurrency.SortCode,
	|	SeparateAccommodation DESC,
	|	SeparateService DESC";
	vQry.SetParameter("qDate", New Boundary(vDate, BoundaryType.Excluding));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	vQry.SetParameter("qEmptyGuestGroup", Catalogs.GuestGroups.EmptyRef());
	vQry.SetParameter("qEmptyAccommodation", Documents.Accommodation.EmptyRef());
	vQry.SetParameter("qEmptyService", Catalogs.Services.EmptyRef());
	vQry.SetParameter("qOneSettlementPerCustomerGuestGroups", OneSettlementPerCustomerGuestGroups);
	vQry.SetParameter("qOneSettlementPerIndividualsCustomerGuestGroups", OneSettlementPerIndividualsCustomerGuestGroups);
	vQry.SetParameter("qSplitSettllementsByVATRate", SplitSettllementsByVATRate);
	vQry.SetParameter("qEmptyVATRate", Undefined);
	vQry.SetParameter("qSplitSettllementsByPaymentSections", SplitSettllementsByPaymentSections);
	vQry.SetParameter("qEmptyPaymentSection", Undefined);
	vQry.SetParameter("qPeriodTo", Date);
	vQry.SetParameter("qBegOfPeriodTo", BegOfDay(Date));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qEmptyHotelProduct", Catalogs.HotelProducts.EmptyRef());
	vQry.SetParameter("qGuestGroupsWithCorrections", pGuestGroupsWithCorrections);
	vQry.SetParameter("qEmptyEvent", Catalogs.Events.EmptyRef());
	vDimensions = vQry.Execute().Unload();
	// Create settlement for each row in dimensions table
	For Each vDimensionsRow In vDimensions Do
		// If only closed folios should be procesed then check that all 
		// folios of the current guest group are closed
		If pProcessClosedFoliosOnly Then
			If ValueIsFilled(vDimensionsRow.Company) And 
			   ValueIsFilled(vDimensionsRow.Company.CompanyAccountingPolicyType) Then
				If vDimensionsRow.Company.CompanyAccountingPolicyType = Enums.CompanyAccountingPolicyTypes.ByCheckedOutGuestGroupsServices Then
					vHotel = vDimensionsRow.Hotel;
					vEvent = vDimensionsRow.Event;
					vGuestGroup = vDimensionsRow.GuestGroup;
					If ValueIsFilled(vGuestGroup) Then
						vCount = GetOpenFoliosCountForGuestGroup(vGuestGroup);
						If vCount > 0 Then
							Continue;
						EndIf;
					ElsIf ValueIsFilled(vEvent) Then
						vCount = GetOpenFoliosCountForEvent(vEvent, vHotel);
						If vCount > 0 Then
							Continue;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		
		// Fill dimensions and accounting currency
		vAccountingCustomer = Catalogs.Customers.EmptyRef();
		vAccountingContract = Catalogs.Contracts.EmptyRef();
		vLanguage = Undefined;
		If ValueIsFilled(vDimensionsRow.Customer) Then
			vAccountingCustomer = vDimensionsRow.Customer;
			// Get customer language
			If ValueIsFilled(vAccountingCustomer) Then
				vLanguage = vAccountingCustomer.Language;
			EndIf;
		Else
			If ValueIsFilled(vDimensionsRow.Hotel) Then
				vAccountingCustomer = vDimensionsRow.Hotel.IndividualsCustomer;
				vAccountingContract = vDimensionsRow.Hotel.IndividualsContract;
			EndIf;
		EndIf;
		If ValueIsFilled(vDimensionsRow.Contract) Then
			vAccountingContract = vDimensionsRow.Contract;
		EndIf;
		vAccountingCurrency = vDimensionsRow.FolioCurrency;
		
		// Skip individuals if neccessary
		If DoNotCloseIndividuals And ValueIsFilled(vDimensionsRow.Hotel) Then
			If ValueIsFilled(vDimensionsRow.Hotel.IndividualsCustomer) And vAccountingCustomer = vDimensionsRow.Hotel.IndividualsCustomer Then
				Continue;
			EndIf;
		EndIf;
		
		// Check if current guest group is in the corrections list
		vIsCorrection = False;
		If pGuestGroupsWithCorrections.FindByValue(vDimensionsRow.GuestGroup) <> Undefined Then
			vIsCorrection = True;
		EndIf;
		
		// Retrieve all balances for the current dimensions where folio payment method is by bank transfer
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	CurrentAccountsReceivableBalance.Hotel AS Hotel,
		|	CurrentAccountsReceivableBalance.Company AS Company,
		|	CurrentAccountsReceivableBalance.Customer AS Customer,
		|	CurrentAccountsReceivableBalance.Contract AS Contract,
		|	CurrentAccountsReceivableBalance.GuestGroup AS GuestGroup,
		|	CurrentAccountsReceivableBalance.FolioCurrency AS FolioCurrency,
		|	CurrentAccountsReceivableBalance.Charge.Folio AS Folio,
		|	CurrentAccountsReceivableBalance.Charge.ParentDoc AS ParentDoc,
		|	CurrentAccountsReceivableBalance.Charge.HotelProduct AS HotelProduct,
		|	CurrentAccountsReceivableBalance.Charge AS Charge,
		|	CurrentAccountsReceivableBalance.Charge.CorrectedCharge AS CorrectedCharge,
		|	CurrentAccountsReceivableBalance.Charge.VATRate AS VATRate,
		|	CurrentAccountsReceivableBalance.Charge.Discount AS Discount,
		|	CurrentAccountsReceivableBalance.Charge.DiscountSum AS DiscountSum,
		|	CurrentAccountsReceivableBalance.Charge.AgentCommissionType AS AgentCommissionType,
		|	CurrentAccountsReceivableBalance.Charge.AgentCommission AS AgentCommission,
		|	ISNULL(CurrentAccountsReceivableBalance.Charge.HotelProduct.Parent, &qEmptyHotelProduct) AS HotelProductParent,
		|	CurrentAccountsReceivableBalance.CommissionSumBalance AS CommissionSumBalance,
		|	CurrentAccountsReceivableBalance.SumBalance AS SumBalance,
		|	CurrentAccountsReceivableBalance.VATSumBalance AS VATSumBalance,
		|	CurrentAccountsReceivableBalance.QuantityBalance AS QuantityBalance,
		|	CurrentAccountsReceivableBalance.Charge.PointInTime AS ChargePointInTime
		|INTO NotInvoicedCharges
		|FROM
		|	AccumulationRegister.CurrentAccountsReceivable.Balance(
		|			&qDate,
		|			Charge.Service.IsHotelProductService
		|				AND Company.WaitForHotelProduct
		|				AND Charge.HotelProduct <> &qEmptyHotelProduct
		|				AND Hotel = &qHotel
		|				AND Company = &qCompany
		|				AND CASE
		|						WHEN NOT Company.CreateSettlementsForNonIndividualsClosingByCityLedgerOnly
		|							THEN TRUE
		|						ELSE
		|							CASE
		|								WHEN ISNULL(Customer.IsIndividual, TRUE)
		|									THEN TRUE
		|								WHEN Charge.Folio.PaymentMethod = VALUE(Catalog.PaymentMethods.Settlement)
		|									THEN TRUE
		|								WHEN ISNULL(Charge.Folio.PaymentMethod.IsByBankTransfer, FALSE)
		|									THEN TRUE
		|								ELSE
		|									FALSE
		|							END
		|						END
		|				AND Customer = &qCustomer
		|				AND Contract = &qContract" + 
						?(vIsCorrection, "", ?(OneSettlementPerCustomerGuestGroups And Not ValueIsFilled(vDimensionsRow.GuestGroup), "", ?(OneSettlementPerIndividualsCustomerGuestGroups, "", ?(ValueIsFilled(vDimensionsRow.Event), " AND GuestGroup.Event = &qEvent", " AND (GuestGroup = &qGuestGroup OR &qDoNotFilterByGuestGroup)")))) + 
						?(vIsCorrection, "", ?(OneSettlementPerIndividualsCustomerGuestGroups, ?(ValueIsFilled(vDimensionsRow.Event), " AND GuestGroup.Event = &qEvent", " AND (GuestGroup = &qGuestGroup OR &qDoNotFilterByGuestGroup)"), "")) + 
						?(vIsCorrection, " AND GuestGroup = &qGuestGroup", "") + 
						?(SplitSettllementsByVATRate, " AND Charge.VATRate = &qVATRate", "") + 
						?(SplitSettllementsByPaymentSections, " AND Charge.PaymentSection = &qPaymentSection", "") + "
		|				AND ISNULL(Charge.Folio.DateTimeFrom, &qEmptyDate) <= &qPeriodTo
		|				AND ISNULL(Charge.HotelProduct.Parent, &qEmptyHotelProduct) = &qHotelProductParent
		|				AND ISNULL(Charge.Date, &qEmptyDate) > Hotel.EditProhibitedDate
		|				AND FolioCurrency = &qFolioCurrency" + 
						?(pProcessClosedFoliosOnly, ?(vPastCloseMode, " AND BEGINOFPERIOD(ISNULL(Charge.Folio.DateTimeTo, &qEmptyDate), DAY) <= &qBegOfPeriodTo", "") + " AND ISNULL(Charge.Folio.IsClosed, FALSE)", "") + 
						?(ValueIsFilled(vDimensionsRow.SeparateAccommodation), " AND Charge.ParentDoc = &qAccommodation", "") + 
						?(ValueIsFilled(vDimensionsRow.SeparateService) AND TypeOf(vDimensionsRow.SeparateService)=Type("CatalogRef.Services"), " AND Charge.Service = &qService", "") + 
						?(ValueIsFilled(vDimensionsRow.SeparateService) AND TypeOf(vDimensionsRow.SeparateService)=Type("String"), " AND Charge.Service.InvoiceGroupingName = &qService", "") + "
		|	) AS CurrentAccountsReceivableBalance
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ChargeInvoices.Charge AS Charge,
		|	MAX(ChargeInvoices.InvoiceNumber) AS InvoiceNumber
		|INTO ChargeLatestInvoices
		|FROM
		|	(SELECT
		|		InvoiceServices.Charge AS Charge,
		|		InvoiceServices.Ref.Number AS InvoiceNumber
		|	FROM
		|		Document.Settlement.Services AS InvoiceServices
		|			INNER JOIN NotInvoicedCharges AS NotInvoicedCharges
		|			ON (InvoiceServices.Charge = NotInvoicedCharges.Charge
		|					OR InvoiceServices.Charge = NotInvoicedCharges.CorrectedCharge)
		|				AND (InvoiceServices.Ref.Posted)
		|	WHERE
		|		InvoiceServices.Ref.Posted
		|		AND NOT (InvoiceServices.Ref.Sum = 0 AND InvoiceServices.Ref.CommissionSum <> 0)
		|	) AS ChargeInvoices
		|
		|GROUP BY
		|	ChargeInvoices.Charge
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OldInvoices.Ref AS Invoice,
		|	OldInvoices.Charge AS Charge,
		|	OldInvoices.Ref.PointInTime AS PointInTime
		|INTO OldInvoices
		|FROM
		|	Document.Settlement.Services AS OldInvoices
		|		INNER JOIN ChargeLatestInvoices AS ChargeLatestInvoices
		|		ON OldInvoices.Charge = ChargeLatestInvoices.Charge
		|			AND OldInvoices.Ref.Number = ChargeLatestInvoices.InvoiceNumber
		|WHERE
		|	OldInvoices.Ref.Posted
		|	AND NOT (OldInvoices.Ref.Sum = 0 AND OldInvoices.Ref.CommissionSum <> 0)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NotInvoicedCharges.Hotel AS Hotel,
		|	NotInvoicedCharges.Company AS Company,
		|	NotInvoicedCharges.Customer AS Customer,
		|	NotInvoicedCharges.Contract AS Contract,
		|	NotInvoicedCharges.GuestGroup AS GuestGroup,
		|	NotInvoicedCharges.FolioCurrency AS FolioCurrency,
		|	NotInvoicedCharges.Folio AS Folio,
		|	NotInvoicedCharges.ParentDoc AS ParentDoc,
		|	NotInvoicedCharges.HotelProduct AS HotelProduct,
		|	NotInvoicedCharges.Charge AS Charge,
		|	NotInvoicedCharges.Discount AS Discount,
		|	NotInvoicedCharges.DiscountSum AS DiscountSum,
		|	NotInvoicedCharges.AgentCommissionType AS AgentCommissionType,
		|	NotInvoicedCharges.AgentCommission AS AgentCommission,
		|	NotInvoicedCharges.HotelProductParent AS HotelProductParent,
		|	NotInvoicedCharges.VATRate AS VATRate,
		|	NotInvoicedCharges.VATRate.Code AS VATRateCode,
		|	NotInvoicedCharges.CommissionSumBalance AS CommissionSumBalance,
		|	NotInvoicedCharges.SumBalance AS SumBalance,
		|	NotInvoicedCharges.VATSumBalance AS VATSumBalance,
		|	NotInvoicedCharges.QuantityBalance AS QuantityBalance,
		|	NotInvoicedCharges.ChargePointInTime AS ChargePointInTime,
		|	CASE
		|		WHEN OldInvoices.Invoice.Number IS NULL
		|			THEN 0
		|		ELSE 1
		|	END AS ChargeHasInvoice,
		|	CASE
		|		WHEN NotInvoicedCharges.SumBalance < 0
		|			THEN -1
		|		WHEN NotInvoicedCharges.SumBalance > 0
		|			THEN 1
		|		WHEN NotInvoicedCharges.QuantityBalance < 0
		|			THEN -1
		|		WHEN NotInvoicedCharges.VATSumBalance < 0
		|			THEN -1
		|		ELSE 1
		|	END AS ChargeSign,
		|	OldInvoices.Invoice.Number AS InvoiceNumber,
		|	OldInvoices.Invoice AS Invoice
		|FROM
		|	NotInvoicedCharges AS NotInvoicedCharges
		|		LEFT JOIN OldInvoices AS OldInvoices
		|		ON (NotInvoicedCharges.Charge = OldInvoices.Charge
		|				OR NotInvoicedCharges.CorrectedCharge = OldInvoices.Charge)
		|
		|ORDER BY
		|	ChargeHasInvoice,
		|	InvoiceNumber,
		|	VATRateCode,
		|	ChargePointInTime,
		|	ChargeSign";
		vQry.SetParameter("qDate", New Boundary(vDate, BoundaryType.Excluding));
		vQry.SetParameter("qHotel", vDimensionsRow.Hotel);
		vQry.SetParameter("qCompany", vDimensionsRow.Company);
		vQry.SetParameter("qCustomer", vDimensionsRow.Customer);
		vQry.SetParameter("qContract", vDimensionsRow.Contract);
		vQry.SetParameter("qGuestGroup", vDimensionsRow.GuestGroup);
		vQry.SetParameter("qDoNotFilterByGuestGroup", ?(vDimensionsRow.DoNotFilterByGuestGroup = 1, True, False));
		vQry.SetParameter("qEvent", vDimensionsRow.Event);
		vQry.SetParameter("qFolioCurrency", vDimensionsRow.FolioCurrency);
		vQry.SetParameter("qAccommodation", vDimensionsRow.SeparateAccommodation);
		vQry.SetParameter("qService", vDimensionsRow.SeparateService);
		vQry.SetParameter("qVATRate", vDimensionsRow.VATRate);
		vQry.SetParameter("qPaymentSection", vDimensionsRow.PaymentSection);
		vQry.SetParameter("qHotelProductParent", vDimensionsRow.HotelProductParent);
		vQry.SetParameter("qPeriodTo", Date);
		vQry.SetParameter("qBegOfPeriodTo", BegOfDay(Date));
		vQry.SetParameter("qEmptyDate", '00010101');
		vQry.SetParameter("qEmptyHotelProduct", Catalogs.HotelProducts.EmptyRef());
		vCharges = vQry.Execute().Unload();
		If vCharges.Count() > 0 Then
			If vIsCorrection Then
				vCurInvoice = Undefined;
				vCurChargeSign = 0;
				vCurVATRate = Undefined;
				vCurInvoiceCharges = vCharges.Copy();
				vCurInvoiceCharges.Clear();
				For Each vChargesRow In vCharges Do
					If vCurInvoice <> Undefined And 
					  (vCurInvoice <> vChargesRow.Invoice Or vCurVATRate <> vChargesRow.VATRate) Then
						If vCurInvoiceCharges.Count() > 0 Then
							If ValueIsFilled(vCurInvoice) Then
								// Create credit or debit note for this invoice
								CreateAndPostCorrectionNote(vDimensionsRow, vAccountingCustomer, vAccountingContract, vAccountingCurrency, 
								                            vLanguage, vCurInvoiceCharges, vCurInvoice, pProcessClosedFoliosOnly, 1);
							Else
								// Create invoice
								CreateAndPostInvoice(vDimensionsRow, vAccountingCustomer, vAccountingContract, vAccountingCurrency, 
								                     vLanguage, vCurInvoiceCharges, vIsCorrection, pProcessClosedFoliosOnly);
							EndIf;
						EndIf;
						
						vCurInvoiceCharges.Clear();
					EndIf;
					vCurInvoice = vChargesRow.Invoice;
					vCurChargeSign = vChargesRow.ChargeSign;
					vCurVATRate = vChargesRow.VATRate;
					
					vCurInvoiceChargesRow = vCurInvoiceCharges.Add();
					FillPropertyValues(vCurInvoiceChargesRow, vChargesRow);
				EndDo;
				If vCurInvoiceCharges.Count() > 0 Then
					If ValueIsFilled(vCurInvoice) Then
						// Create credit or debit note for this invoice
						CreateAndPostCorrectionNote(vDimensionsRow, vAccountingCustomer, vAccountingContract, vAccountingCurrency, 
						                            vLanguage, vCurInvoiceCharges, vCurInvoice, pProcessClosedFoliosOnly, 1);
					Else
						// Create invoice
						CreateAndPostInvoice(vDimensionsRow, vAccountingCustomer, vAccountingContract, vAccountingCurrency, 
						                     vLanguage, vCurInvoiceCharges, vIsCorrection, pProcessClosedFoliosOnly);
					EndIf;
				EndIf;
			Else
				// Create settlement and fill it's services with charges retrieved
				CreateAndPostInvoice(vDimensionsRow, vAccountingCustomer, vAccountingContract, vAccountingCurrency, 
				                     vLanguage, vCharges, vIsCorrection, pProcessClosedFoliosOnly);
			EndIf;
		EndIf;
	EndDo;
	WriteLogEvent(NStr("en='CloseOfPeriod.BuildSettlementsForHotelProducts';ru='ЗакрытиеПериода.ФормированиеАктовПоПутевкам';de='CloseOfPeriod.BuildSettlementsForHotelProducts'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='End of building hotel product settlements';ru='Закончена операция формирования актов по путевкам';de='Die Erstellung von Übergabeprotokollen zu Reisepapieren ist abgeschlossen'"), EventLogEntryTransactionMode.Independent);
EndProcedure // CloseHotelProducts

// -----------------------------------------------------------------------------
Procedure CloseCurrentAccountsReceivable(pCancel, pPostingMode, pIsPosted = False, pGuestGroupsWithCorrections, pProcessClosedFoliosOnly)
	// Do processing if document is not posted only
	If pIsPosted Then
		Return;
	EndIf;
	WriteLogEvent(NStr("en='CloseOfPeriod.BuildSettlements';ru='ЗакрытиеПериода.ФормированиеАктов';de='CloseOfPeriod.BuildSettlements'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='Start of building settlements...';ru='Начата операция формирования актов...';de='Erstellung von Übergabeprotokollen wurde gestartet…'"), EventLogEntryTransactionMode.Independent);
	// Check if there are any companies waiting for hotel products
	vNoHotelProducts = False;
	If ValueIsFilled(Company) And Not Company.WaitForHotelProduct Then
		vNoHotelProducts = True;
	Else
		vCompanyQry = New Query();
		vCompanyQry.Text = 
		"SELECT
		|	Companies.Ref
		|FROM
		|	Catalog.Companies AS Companies
		|WHERE
		|	Companies.WaitForHotelProduct
		|	AND NOT Companies.IsFolder";
		vCompanies = vCompanyQry.Execute().Unload();
		If vCompanies.Count() = 0 Then
			vNoHotelProducts = True;
		EndIf;
	EndIf;
	// Date to be used to retreive balances
	vDate = Date + 1;
	If ValueIsFilled(Company) And pProcessClosedFoliosOnly Then
		If Company.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.Year Then
			vDate = EndOfYear(Date) + 1;
		ElsIf Company.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.HalfYear Then
			vDate = EndOfMonth(AddMonth(BegOfYear(Date), 6)) + 1;
		ElsIf Company.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.Quarter Then
			vDate = EndOfQuarter(Date) + 1;
		EndIf;
	EndIf;
	vPastCloseMode = (BegOfDay(CurrentSessionDate()) - 24*3600) > BegOfDay(Date);
	// Get table with customers, contracts and guest groups with balances in Current Accounts Receivable
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CurrentAccountsReceivableBalance.Hotel AS Hotel,
	|	CurrentAccountsReceivableBalance.Company AS Company,
	|	CurrentAccountsReceivableBalance.Customer AS Customer,
	|	CurrentAccountsReceivableBalance.Contract AS Contract,
	|	CASE
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.GuestGroup.Event.JoinGroupsToOneInvoice, FALSE)
	|			THEN CurrentAccountsReceivableBalance.GuestGroup.Event
	|		ELSE &qEmptyEvent
	|	END AS Event,
	|	CASE
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.GuestGroup.Event.JoinGroupsToOneInvoice, FALSE)
	|			THEN CurrentAccountsReceivableBalance.GuestGroup.Event.DateFrom
	|		ELSE &qEmptyDate
	|	END AS EventDateFrom,
	|	CASE
	|		WHEN CurrentAccountsReceivableBalance.GuestGroup IN (&qGuestGroupsWithCorrections)
	|			THEN CurrentAccountsReceivableBalance.GuestGroup
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Customer.CustomerType.OneSettlementPerCustomerGuestGroups, FALSE)
	|				AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE))
	|			THEN &qEmptyGuestGroup
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Contract.OneSettlementPerCustomerGuestGroups, FALSE)
	|				AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE))
	|			THEN &qEmptyGuestGroup
	|		WHEN &qOneSettlementPerCustomerGuestGroups
	|				AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE))
	|			THEN &qEmptyGuestGroup
	|		WHEN &qOneSettlementPerIndividualsCustomerGuestGroups
	|				AND (CurrentAccountsReceivableBalance.Customer = &qEmptyCustomer
	|					OR CurrentAccountsReceivableBalance.Customer = CurrentAccountsReceivableBalance.Hotel.IndividualsCustomer)
	|			THEN &qEmptyGuestGroup
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.GuestGroup.Event.JoinGroupsToOneInvoice, FALSE)
	|			THEN &qEmptyGuestGroup
	|		ELSE CurrentAccountsReceivableBalance.GuestGroup
	|	END AS GuestGroup,
	|	CASE
	|		WHEN CurrentAccountsReceivableBalance.GuestGroup IN (&qGuestGroupsWithCorrections)
	|			THEN CurrentAccountsReceivableBalance.GuestGroup.Code
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Customer.CustomerType.OneSettlementPerCustomerGuestGroups, FALSE)
	|				AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE))
	|			THEN 999999999999
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Contract.OneSettlementPerCustomerGuestGroups, FALSE)
	|				AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE))
	|			THEN 999999999999
	|		WHEN &qOneSettlementPerCustomerGuestGroups
	|				AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE))
	|			THEN 999999999999
	|		WHEN &qOneSettlementPerIndividualsCustomerGuestGroups
	|				AND (CurrentAccountsReceivableBalance.Customer = &qEmptyCustomer
	|					OR CurrentAccountsReceivableBalance.Customer = CurrentAccountsReceivableBalance.Hotel.IndividualsCustomer)
	|			THEN 999999999999
	|		WHEN CurrentAccountsReceivableBalance.GuestGroup = &qEmptyGuestGroup
	|			THEN 999999999999
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.GuestGroup.Event.JoinGroupsToOneInvoice, FALSE)
	|			THEN 999999999999
	|		ELSE CurrentAccountsReceivableBalance.GuestGroup.Code
	|	END AS GuestGroupCode,
	|	CASE
	|		WHEN CurrentAccountsReceivableBalance.GuestGroup IN (&qGuestGroupsWithCorrections)
	|			THEN 0
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Customer.CustomerType.OneSettlementPerCustomerGuestGroups, FALSE)
	|				AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE))
	|			THEN 1
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Contract.OneSettlementPerCustomerGuestGroups, FALSE)
	|				AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE))
	|			THEN 1
	|		WHEN &qOneSettlementPerCustomerGuestGroups
	|				AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE))
	|			THEN 1
	|		WHEN &qOneSettlementPerIndividualsCustomerGuestGroups
	|				AND (CurrentAccountsReceivableBalance.Customer = &qEmptyCustomer
	|					OR CurrentAccountsReceivableBalance.Customer = CurrentAccountsReceivableBalance.Hotel.IndividualsCustomer)
	|			THEN 1
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.GuestGroup.Event.JoinGroupsToOneInvoice, FALSE)
	|			THEN 1
	|		ELSE 0
	|	END AS DoNotFilterByGuestGroup,
	|	CurrentAccountsReceivableBalance.FolioCurrency AS FolioCurrency,
	|	CASE
	|		WHEN &qSplitSettllementsByVATRate
	|			THEN CurrentAccountsReceivableBalance.Charge.VATRate
	|		ELSE &qEmptyVATRate
	|	END AS VATRate,
	|	CASE
	|		WHEN &qSplitSettllementsByPaymentSections
	|			THEN CurrentAccountsReceivableBalance.Charge.PaymentSection
	|		ELSE &qEmptyPaymentSection
	|	END AS PaymentSection,
	|	CurrentAccountsReceivableBalance.Customer.Description AS CustomerDescription,
	|	CurrentAccountsReceivableBalance.Contract.Description AS ContractDescription,
	|	CASE
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Charge.ParentDoc.HasOfficialLetter, FALSE)
	|			THEN CurrentAccountsReceivableBalance.Charge.ParentDoc
	|		ELSE &qEmptyAccommodation
	|	END AS SeparateAccommodation,
	|	CASE
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Charge.Service.SplitToSeparateSettlements, FALSE)
	|				AND CurrentAccountsReceivableBalance.Charge.Service.InvoiceGroupingName <> """"
	|			THEN CurrentAccountsReceivableBalance.Charge.Service.InvoiceGroupingName
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Charge.Service.SplitToSeparateSettlements, FALSE)
	|			THEN CurrentAccountsReceivableBalance.Charge.Service
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Charge.Service.DoNotExportToTheAccountingSystem, FALSE)
	|			THEN CurrentAccountsReceivableBalance.Charge.Service
	|		ELSE &qEmptyService
	|	END AS SeparateService,
	|	CurrentAccountsReceivableBalance.Charge.Service.InvoiceGroupingName AS InvoiceGroupingName,
	|	ISNULL(CurrentAccountsReceivableBalance.Charge.Service.IsStockArticle, FALSE) AS IsStockArticle,
	|	ISNULL(CurrentAccountsReceivableBalance.Charge.HotelProduct.Parent, &qEmptyHotelProduct) AS HotelProductParent,
	|	SUM(CurrentAccountsReceivableBalance.SumBalance) AS Sum,
	|	SUM(CurrentAccountsReceivableBalance.VATSumBalance) AS VATSum,
	|	SUM(CurrentAccountsReceivableBalance.QuantityBalance) AS Quantity,
	|	SUM(CurrentAccountsReceivableBalance.CommissionSumBalance) AS CommissionSum
	|FROM
	|	AccumulationRegister.CurrentAccountsReceivable.Balance(
	|			&qDate,
	|		" + ?(vNoHotelProducts, "TRUE", "(NOT Charge.Service.IsHotelProductService OR Charge.Service.IsHotelProductService AND NOT Company.WaitForHotelProduct)") + 
			?(ValueIsFilled(Hotel), " AND Hotel IN HIERARCHY(&qHotel)", "") + 
			?(ValueIsFilled(Company), " AND Company IN HIERARCHY(&qCompany)", "") + 
			?(pProcessClosedFoliosOnly, ?(vPastCloseMode, " AND BEGINOFPERIOD(ISNULL(Charge.Folio.DateTimeTo, &qEmptyDate), DAY) <= &qBegOfPeriodTo", "") + " AND (ISNULL(Charge.Folio.IsClosed, FALSE) AND NOT ISNULL(GuestGroup.IsPending, FALSE) OR Charge.Service.IsStockArticle OR (Charge.Folio.DateTimeTo = &qEmptyDate AND &qIsEndOfAccountingPeriod) OR (&qIsEndOfDecade AND Contract.TaxAccountingPeriodType = VALUE(Enum.TaxAccountingPeriodTypes.Decade)) OR ((Customer = &qEmptyCustomer OR Customer = Hotel.IndividualsCustomer) AND Company.CloseIndividualsEveryDay))", 
			                           ?(ValueIsFilled(Company) And Company.CreateSettlementsAtCheckOutDateForCustomers, " AND (ISNULL(Charge.Folio.IsClosed, FALSE) OR NOT ISNULL(Charge.Folio.IsClosed, FALSE) AND ISNULL(Customer.IsIndividual, TRUE) OR Charge.Service.IsStockArticle)", "")) + "
	|				AND ISNULL(Charge.Date, &qEmptyDate) <= &qPeriodTo
	|				AND ISNULL(Charge.Date, &qEmptyDate) > Hotel.EditProhibitedDate
	|				AND NOT Company.DoNotGenerateInvoicesAutomaticallyAtEndOfPeriod
	|				AND CASE
	|						WHEN NOT Company.CreateSettlementsForNonIndividualsClosingByCityLedgerOnly
	|							THEN TRUE
	|						ELSE
	|							CASE
	|								WHEN ISNULL(Customer.IsIndividual, TRUE)
	|									THEN TRUE
	|								WHEN Charge.Folio.PaymentMethod = VALUE(Catalog.PaymentMethods.Settlement)
	|									THEN TRUE
	|								WHEN ISNULL(Charge.Folio.PaymentMethod.IsByBankTransfer, FALSE)
	|									THEN TRUE
	|								ELSE
	|									FALSE
	|							END
	|						END
	|				AND (&qIsEndOfAccountingPeriod
	|					OR NOT &qIsEndOfAccountingPeriod
	|						AND (ISNULL(Charge.Service.IsStockArticle, FALSE)
	|							OR (NOT ISNULL(Company.CreateSettlementsAtTheEndOfAccountingPeriodOnly, FALSE)
	|								AND NOT ISNULL(Customer.CustomerType.CreateSettlementsAtTheEndOfAccountingPeriodOnly, FALSE)
	|								AND NOT ISNULL(Contract.CreateSettlementsAtTheEndOfAccountingPeriodOnly, FALSE)))
	|					OR NOT &qIsEndOfAccountingPeriod
	|						AND &qIsEndOfMonth
	|						AND (ISNULL(Charge.Service.IsStockArticle, FALSE)
	|							OR (ISNULL(Company.CreateSettlementsAtTheEndOfAccountingPeriodOnly, FALSE)
	|								OR ISNULL(Customer.CustomerType.CreateSettlementsAtTheEndOfAccountingPeriodOnly, FALSE)
	|								OR ISNULL(Contract.CreateSettlementsAtTheEndOfAccountingPeriodOnly, FALSE))))
	|				) AS CurrentAccountsReceivableBalance
	|
	|GROUP BY
	|	CurrentAccountsReceivableBalance.Hotel,
	|	CurrentAccountsReceivableBalance.Company,
	|	CurrentAccountsReceivableBalance.Customer,
	|	CurrentAccountsReceivableBalance.Contract,
	|	CASE
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.GuestGroup.Event.JoinGroupsToOneInvoice, FALSE)
	|			THEN CurrentAccountsReceivableBalance.GuestGroup.Event
	|		ELSE &qEmptyEvent
	|	END,
	|	CASE
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.GuestGroup.Event.JoinGroupsToOneInvoice, FALSE)
	|			THEN CurrentAccountsReceivableBalance.GuestGroup.Event.DateFrom
	|		ELSE &qEmptyDate
	|	END,
	|	CASE
	|		WHEN CurrentAccountsReceivableBalance.GuestGroup IN (&qGuestGroupsWithCorrections)
	|			THEN CurrentAccountsReceivableBalance.GuestGroup
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Customer.CustomerType.OneSettlementPerCustomerGuestGroups, FALSE)
	|				AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE))
	|			THEN &qEmptyGuestGroup
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Contract.OneSettlementPerCustomerGuestGroups, FALSE)
	|				AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE))
	|			THEN &qEmptyGuestGroup
	|		WHEN &qOneSettlementPerCustomerGuestGroups
	|				AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE))
	|			THEN &qEmptyGuestGroup
	|		WHEN &qOneSettlementPerIndividualsCustomerGuestGroups
	|				AND (CurrentAccountsReceivableBalance.Customer = &qEmptyCustomer
	|					OR CurrentAccountsReceivableBalance.Customer = CurrentAccountsReceivableBalance.Hotel.IndividualsCustomer)
	|			THEN &qEmptyGuestGroup
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.GuestGroup.Event.JoinGroupsToOneInvoice, FALSE)
	|			THEN &qEmptyGuestGroup
	|		ELSE CurrentAccountsReceivableBalance.GuestGroup
	|	END,
	|	CASE
	|		WHEN CurrentAccountsReceivableBalance.GuestGroup IN (&qGuestGroupsWithCorrections)
	|			THEN CurrentAccountsReceivableBalance.GuestGroup.Code
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Customer.CustomerType.OneSettlementPerCustomerGuestGroups, FALSE)
	|				AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE))
	|			THEN 999999999999
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Contract.OneSettlementPerCustomerGuestGroups, FALSE)
	|				AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE))
	|			THEN 999999999999
	|		WHEN &qOneSettlementPerCustomerGuestGroups
	|				AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE))
	|			THEN 999999999999
	|		WHEN &qOneSettlementPerIndividualsCustomerGuestGroups
	|				AND (CurrentAccountsReceivableBalance.Customer = &qEmptyCustomer
	|					OR CurrentAccountsReceivableBalance.Customer = CurrentAccountsReceivableBalance.Hotel.IndividualsCustomer)
	|			THEN 999999999999
	|		WHEN CurrentAccountsReceivableBalance.GuestGroup = &qEmptyGuestGroup
	|			THEN 999999999999
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.GuestGroup.Event.JoinGroupsToOneInvoice, FALSE)
	|			THEN 999999999999
	|		ELSE CurrentAccountsReceivableBalance.GuestGroup.Code
	|	END,
	|	CASE
	|		WHEN CurrentAccountsReceivableBalance.GuestGroup IN (&qGuestGroupsWithCorrections)
	|			THEN 0
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Customer.CustomerType.OneSettlementPerCustomerGuestGroups, FALSE)
	|				AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE))
	|			THEN 1
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Contract.OneSettlementPerCustomerGuestGroups, FALSE)
	|				AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE))
	|			THEN 1
	|		WHEN &qOneSettlementPerCustomerGuestGroups
	|				AND (ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.Code, """") = """" OR ISNULL(CurrentAccountsReceivableBalance.GuestGroup.GroupType.DoNotCreateSeparateInvoices, FALSE))
	|			THEN 1
	|		WHEN &qOneSettlementPerIndividualsCustomerGuestGroups
	|				AND (CurrentAccountsReceivableBalance.Customer = &qEmptyCustomer
	|					OR CurrentAccountsReceivableBalance.Customer = CurrentAccountsReceivableBalance.Hotel.IndividualsCustomer)
	|			THEN 1
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.GuestGroup.Event.JoinGroupsToOneInvoice, FALSE)
	|			THEN 1
	|		ELSE 0
	|	END,
	|	CurrentAccountsReceivableBalance.FolioCurrency,
	|	CASE
	|		WHEN &qSplitSettllementsByVATRate
	|			THEN CurrentAccountsReceivableBalance.Charge.VATRate
	|		ELSE &qEmptyVATRate
	|	END,
	|	CASE
	|		WHEN &qSplitSettllementsByPaymentSections
	|			THEN CurrentAccountsReceivableBalance.Charge.PaymentSection
	|		ELSE &qEmptyPaymentSection
	|	END,
	|	CASE
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Charge.ParentDoc.HasOfficialLetter, FALSE)
	|			THEN CurrentAccountsReceivableBalance.Charge.ParentDoc
	|		ELSE &qEmptyAccommodation
	|	END,
	|	CASE
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Charge.Service.SplitToSeparateSettlements, FALSE)
	|				AND CurrentAccountsReceivableBalance.Charge.Service.InvoiceGroupingName <> """"
	|			THEN CurrentAccountsReceivableBalance.Charge.Service.InvoiceGroupingName
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Charge.Service.SplitToSeparateSettlements, FALSE)
	|			THEN CurrentAccountsReceivableBalance.Charge.Service
	|		WHEN ISNULL(CurrentAccountsReceivableBalance.Charge.Service.DoNotExportToTheAccountingSystem, FALSE)
	|			THEN CurrentAccountsReceivableBalance.Charge.Service
	|		ELSE &qEmptyService
	|	END,
	|	CurrentAccountsReceivableBalance.Charge.Service.InvoiceGroupingName,
	|	ISNULL(CurrentAccountsReceivableBalance.Charge.Service.IsStockArticle, FALSE),
	|	ISNULL(CurrentAccountsReceivableBalance.Charge.HotelProduct.Parent, &qEmptyHotelProduct),
	|	CurrentAccountsReceivableBalance.Customer.Description,
	|	CurrentAccountsReceivableBalance.Contract.Description
	|
	|HAVING
	|	(SUM(CurrentAccountsReceivableBalance.SumBalance) <> 0
	|		OR SUM(CurrentAccountsReceivableBalance.VATSumBalance) <> 0
	|		OR SUM(CurrentAccountsReceivableBalance.QuantityBalance) <> 0
	|		OR SUM(CurrentAccountsReceivableBalance.CommissionSumBalance) <> 0)
	|
	|ORDER BY
	|	CustomerDescription,
	|	ContractDescription,
	|	EventDateFrom,
	|	GuestGroupCode,
	|	DoNotFilterByGuestGroup DESC,
	|	CurrentAccountsReceivableBalance.FolioCurrency.SortCode,
	|	SeparateAccommodation DESC,
	|	InvoiceGroupingName DESC,
	|	SeparateService DESC,
	|	IsStockArticle";
	vQry.SetParameter("qDate", New Boundary(vDate, BoundaryType.Excluding));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	vQry.SetParameter("qEmptyGuestGroup", Catalogs.GuestGroups.EmptyRef());
	vQry.SetParameter("qEmptyAccommodation", Documents.Accommodation.EmptyRef());
	vQry.SetParameter("qEmptyService", Catalogs.Services.EmptyRef());
	vQry.SetParameter("qOneSettlementPerCustomerGuestGroups", OneSettlementPerCustomerGuestGroups);
	vQry.SetParameter("qOneSettlementPerIndividualsCustomerGuestGroups", OneSettlementPerIndividualsCustomerGuestGroups);
	vQry.SetParameter("qSplitSettllementsByVATRate", SplitSettllementsByVATRate);
	vQry.SetParameter("qEmptyVATRate", Undefined);
	vQry.SetParameter("qSplitSettllementsByPaymentSections", SplitSettllementsByPaymentSections);
	vQry.SetParameter("qEmptyPaymentSection", Undefined);
	vQry.SetParameter("qPeriodTo", Date);
	vQry.SetParameter("qBegOfPeriodTo", BegOfDay(Date));
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qEmptyHotelProduct", Catalogs.HotelProducts.EmptyRef());
	If ValueIsFilled(Company) Then
		If Company.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.Year Then
			vQry.SetParameter("qIsEndOfAccountingPeriod", ?(EndOfDay(Date) = EndOfYear(Date), True, False));
		ElsIf Company.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.HalfYear Then
			vQry.SetParameter("qIsEndOfAccountingPeriod", ?(EndOfDay(Date) = EndOfMonth(AddMonth(BegOfYear(Date), 6)), True, False));
		ElsIf Company.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.Quarter Then
			vQry.SetParameter("qIsEndOfAccountingPeriod", ?(EndOfDay(Date) = EndOfQuarter(Date), True, False));
		ElsIf Company.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.Month Then
			If Company.CloseMonthAtDayBeforeTheLastMonthDay Then
				vQry.SetParameter("qIsEndOfAccountingPeriod", ?(EndOfDay(Date) = (EndOfMonth(Date) - 24*3600), True, False));
			Else
				vQry.SetParameter("qIsEndOfAccountingPeriod", ?(EndOfDay(Date) = EndOfMonth(Date), True, False));
			EndIf;
		ElsIf Company.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.Decade Then
			vDay = Day(Date);
			If vDay = 10 Then
				vQry.SetParameter("qIsEndOfAccountingPeriod", True);
			ElsIf vDay = 20 Then 
				vQry.SetParameter("qIsEndOfAccountingPeriod", True);
			Else
				If Company.CloseMonthAtDayBeforeTheLastMonthDay Then
					vQry.SetParameter("qIsEndOfAccountingPeriod", ?(EndOfDay(Date) = (EndOfMonth(Date) - 24*3600), True, False));
				Else
					vQry.SetParameter("qIsEndOfAccountingPeriod", ?(EndOfDay(Date) = EndOfMonth(Date), True, False));
				EndIf;
			EndIf;
		Else
			vQry.SetParameter("qIsEndOfAccountingPeriod", False);
		EndIf;
		If Company.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.None Then
			If Company.CloseMonthAtDayBeforeTheLastMonthDay Then
				vQry.SetParameter("qIsEndOfMonth", ?(EndOfDay(Date) = (EndOfMonth(Date) - 24*3600), True, False));
			Else
				vQry.SetParameter("qIsEndOfMonth", ?(EndOfDay(Date) = EndOfMonth(Date), True, False));
			EndIf;
		Else
			vQry.SetParameter("qIsEndOfMonth", False);
		EndIf;
	Else
		vQry.SetParameter("qIsEndOfAccountingPeriod", False);
		vQry.SetParameter("qIsEndOfMonth", False);
	EndIf;
	vDay = Day(Date);
	If vDay = 10 Then
		vQry.SetParameter("qIsEndOfDecade", True);
	ElsIf vDay = 20 Then 
		vQry.SetParameter("qIsEndOfDecade", True);
	Else
		If Company.CloseMonthAtDayBeforeTheLastMonthDay Then
			vQry.SetParameter("qIsEndOfDecade", ?(EndOfDay(Date) = (EndOfMonth(Date) - 24*3600), True, False));
		Else
			vQry.SetParameter("qIsEndOfDecade", ?(EndOfDay(Date) = EndOfMonth(Date), True, False));
		EndIf;
	EndIf;
	vQry.SetParameter("qGuestGroupsWithCorrections", pGuestGroupsWithCorrections);
	vQry.SetParameter("qEmptyEvent", Catalogs.Events.EmptyRef());
	vDimensions = vQry.Execute().Unload();
	// Create settlement for each row in dimensions table
	For Each vDimensionsRow In vDimensions Do
		// Date to be used to retreive balances
		vDate = Date + 1;
		If ValueIsFilled(vDimensionsRow.Company) And pProcessClosedFoliosOnly Then
			If vDimensionsRow.Company.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.Year Then
				vDate = EndOfYear(Date) + 1;
			EndIf;
		EndIf;
		// If only closed folios should be procesed then check that all 
		// folios of the current guest group are closed
		vJoinFirstDayOfMonthBreakfasts = False;
		vBegOfNextMonthDay = Undefined;
		vEndOfNextMonthDay = Undefined;
		If pProcessClosedFoliosOnly And Not vDimensionsRow.IsStockArticle Then
			If ValueIsFilled(vDimensionsRow.Company) And 
			   ValueIsFilled(vDimensionsRow.Company.CompanyAccountingPolicyType) Then
				If vDimensionsRow.Company.CompanyAccountingPolicyType = Enums.CompanyAccountingPolicyTypes.ByCheckedOutGuestGroupsServices Then
					If Not vDimensionsRow.Company.CloseIndividualsEveryDay Or vDimensionsRow.Company.CloseIndividualsEveryDay And ValueIsFilled(vDimensionsRow.Customer) And ValueIsFilled(vDimensionsRow.Hotel) And vDimensionsRow.Customer <> vDimensionsRow.Hotel.IndividualsCustomer Then
						vHotel = vDimensionsRow.Hotel;
						vGuestGroup = vDimensionsRow.GuestGroup;
						vEvent = vDimensionsRow.Event;
						If ValueIsFilled(vGuestGroup) Then
							vCount = GetOpenFoliosCountForGuestGroup(vGuestGroup);
							If vCount > 0 Then
								Continue;
							EndIf;
						ElsIf ValueIsFilled(vEvent) Then
							vCount = GetOpenFoliosCountForEvent(vEvent, vHotel);
							If vCount > 0 Then
								Continue;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
				If vDimensionsRow.Company.CompanyAccountingPolicyType = Enums.CompanyAccountingPolicyTypes.ByCheckedOutGuestGroupsServices Or 
				   vDimensionsRow.Company.CompanyAccountingPolicyType = Enums.CompanyAccountingPolicyTypes.ByCheckedOutGuestsServices Then
					// Use end of month to catch services that could be in the future to the close of period date
					vDate = EndOfDay(Date) + 1;
					If vDimensionsRow.Company.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.Year Then
						vDate = EndOfYear(Date) + 1;
					EndIf;
				EndIf;
			EndIf;
		ElsIf Not vDimensionsRow.IsStockArticle Then
			// At the end of the accounting period (usually month) we'll try to join breakfasts and other additional services for the guests that checking-out on 1 day of next month to the previous month settlement
			If ValueIsFilled(vDimensionsRow.GuestGroup) Then
				If ValueIsFilled(vDimensionsRow.Company) And 
				   ValueIsFilled(vDimensionsRow.Company.CompanyAccountingPolicyType) Then
					If vDimensionsRow.Company.CompanyAccountingPolicyType = Enums.CompanyAccountingPolicyTypes.ByCheckedOutGuestGroupsServices Or 
					   vDimensionsRow.Company.CompanyAccountingPolicyType = Enums.CompanyAccountingPolicyTypes.ByCheckedOutGuestsServices Then
						If EndOfDay(Date) = EndOfMonth(Date) And Not vDimensionsRow.Company.CloseMonthAtDayBeforeTheLastMonthDay Then
							If CheckRevenueServicesCount(vDimensionsRow) Then
								vDate = '39991231235959';
							Else
								vBegOfNextMonthDay = BegOfDay(EndOfDay(Date) + 1);
								vEndOfNextMonthDay = EndOfDay(EndOfDay(Date) + 1);
								vJoinFirstDayOfMonthBreakfasts = True;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		
		// Fill dimensions and accounting currency
		vAccountingCustomer = Catalogs.Customers.EmptyRef();
		vAccountingContract = Catalogs.Contracts.EmptyRef();
		vLanguage = Undefined;
		If ValueIsFilled(vDimensionsRow.Customer) Then
			vAccountingCustomer = vDimensionsRow.Customer;
			// Get customer language
			If ValueIsFilled(vAccountingCustomer) Then
				vLanguage = vAccountingCustomer.Language;
			EndIf;
		Else
			If ValueIsFilled(vDimensionsRow.Hotel) Then
				vAccountingCustomer = vDimensionsRow.Hotel.IndividualsCustomer;
				vAccountingContract = vDimensionsRow.Hotel.IndividualsContract;
			EndIf;
		EndIf;
		If ValueIsFilled(vDimensionsRow.Contract) Then
			vAccountingContract = vDimensionsRow.Contract;
		EndIf;
		vAccountingCurrency = vDimensionsRow.FolioCurrency;
		
		// Skip individuals if neccessary
		If DoNotCloseIndividuals And ValueIsFilled(vDimensionsRow.Hotel) And Not vDimensionsRow.IsStockArticle Then
			If ValueIsFilled(vDimensionsRow.Hotel.IndividualsCustomer) And vAccountingCustomer = vDimensionsRow.Hotel.IndividualsCustomer Then
				Continue;
			EndIf;
		EndIf;
		
		// Check if current guest group is in the corrections list
		vIsCorrection = False;
		If pGuestGroupsWithCorrections.FindByValue(vDimensionsRow.GuestGroup) <> Undefined Then
			vIsCorrection = True;
		EndIf;
		
		// Retrieve all balances for the current dimensions where folio payment method is by bank transfer
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	CurrentAccountsReceivableBalance.Hotel AS Hotel,
		|	CurrentAccountsReceivableBalance.Company AS Company,
		|	CurrentAccountsReceivableBalance.Customer AS Customer,
		|	CurrentAccountsReceivableBalance.Contract AS Contract,
		|	CurrentAccountsReceivableBalance.GuestGroup.Event AS Event,
		|	CurrentAccountsReceivableBalance.GuestGroup AS GuestGroup,
		|	CurrentAccountsReceivableBalance.FolioCurrency AS FolioCurrency,
		|	CurrentAccountsReceivableBalance.Charge.Folio AS Folio,
		|	CurrentAccountsReceivableBalance.Charge.ParentDoc AS ParentDoc,
		|	CurrentAccountsReceivableBalance.Charge.HotelProduct AS HotelProduct,
		|	CurrentAccountsReceivableBalance.Charge AS Charge,
		|	CurrentAccountsReceivableBalance.Charge.CorrectedCharge AS CorrectedCharge,
		|	CurrentAccountsReceivableBalance.Charge.VATRate AS VATRate,
		|	CurrentAccountsReceivableBalance.Charge.Discount AS Discount,
		|	CurrentAccountsReceivableBalance.Charge.DiscountSum AS DiscountSum,
		|	CurrentAccountsReceivableBalance.Charge.AgentCommissionType AS AgentCommissionType,
		|	CurrentAccountsReceivableBalance.Charge.AgentCommission AS AgentCommission,
		|	ISNULL(CurrentAccountsReceivableBalance.Charge.HotelProduct.Parent, &qEmptyHotelProduct) AS HotelProductParent,
		|	CurrentAccountsReceivableBalance.CommissionSumBalance AS CommissionSumBalance,
		|	CurrentAccountsReceivableBalance.SumBalance AS SumBalance,
		|	CurrentAccountsReceivableBalance.VATSumBalance AS VATSumBalance,
		|	CurrentAccountsReceivableBalance.QuantityBalance AS QuantityBalance,
		|	CurrentAccountsReceivableBalance.Charge.PointInTime AS ChargePointInTime
		|INTO NotInvoicedCharges
		|FROM
		|	AccumulationRegister.CurrentAccountsReceivable.Balance(
		|			&qDate,
		|			TRUE" + 
					?(vNoHotelProducts, "", " AND (NOT Charge.Service.IsHotelProductService OR 
		|		                               Charge.Service.IsHotelProductService AND NOT Company.WaitForHotelProduct)") + "
		|			AND Hotel = &qHotel
		|			AND Company = &qCompany
		|			AND CASE
		|					WHEN NOT Company.CreateSettlementsForNonIndividualsClosingByCityLedgerOnly
		|						THEN TRUE
		|					ELSE
		|						CASE
		|							WHEN ISNULL(Customer.IsIndividual, TRUE)
		|								THEN TRUE
		|							WHEN Charge.Folio.PaymentMethod = VALUE(Catalog.PaymentMethods.Settlement)
		|								THEN TRUE
		|							WHEN ISNULL(Charge.Folio.PaymentMethod.IsByBankTransfer, FALSE)
		|								THEN TRUE
		|							ELSE
		|								FALSE
		|						END
		|					END
		|			AND Customer = &qCustomer
		|			AND Contract = &qContract " + 
					?(vIsCorrection, "", ?(OneSettlementPerCustomerGuestGroups And Not ValueIsFilled(vDimensionsRow.GuestGroup), "", ?(OneSettlementPerIndividualsCustomerGuestGroups, "", ?(ValueIsFilled(vDimensionsRow.Event), " AND GuestGroup.Event = &qEvent", " AND (GuestGroup = &qGuestGroup OR &qDoNotFilterByGuestGroup)")))) + 
					?(vIsCorrection, "", ?(OneSettlementPerIndividualsCustomerGuestGroups, ?(ValueIsFilled(vDimensionsRow.Event), " AND GuestGroup.Event = &qEvent", " AND (GuestGroup = &qGuestGroup OR &qDoNotFilterByGuestGroup)"), "")) + 
					?(vIsCorrection, " AND GuestGroup = &qGuestGroup", "") + 
					?(SplitSettllementsByVATRate, " AND Charge.VATRate = &qVATRate", "") + 
					?(SplitSettllementsByPaymentSections, " AND Charge.PaymentSection = &qPaymentSection", "") + "
		|			AND ISNULL(Charge.Date, &qEmptyDate) <= &qPeriodTo
		|			AND ISNULL(Charge.Date, &qEmptyDate) > Hotel.EditProhibitedDate
		|			AND ISNULL(Charge.HotelProduct.Parent, &qEmptyHotelProduct) = &qHotelProductParent
		|			AND FolioCurrency = &qFolioCurrency" + 
					?(pProcessClosedFoliosOnly, ?(vPastCloseMode, " AND BEGINOFPERIOD(ISNULL(Charge.Folio.DateTimeTo, &qEmptyDate), DAY) <= &qBegOfPeriodTo", "") + " AND (ISNULL(Charge.Folio.IsClosed, FALSE) OR Charge.Service.IsStockArticle OR &qIsEndOfAccountingPeriod OR ((Customer = &qEmptyCustomer OR Customer = Hotel.IndividualsCustomer) AND Company.CloseIndividualsEveryDay))", 
					                           ?(ValueIsFilled(Company) And Company.CreateSettlementsAtCheckOutDateForCustomers, " AND (ISNULL(Charge.Folio.IsClosed, FALSE) OR NOT ISNULL(Charge.Folio.IsClosed, FALSE) AND ISNULL(Customer.IsIndividual, TRUE) OR Charge.Service.IsStockArticle)", "")) + 
					?(ValueIsFilled(vDimensionsRow.SeparateAccommodation), " AND Charge.ParentDoc = &qAccommodation", "") + 
					?(vDimensionsRow.IsStockArticle, " AND Charge.Service.IsStockArticle", " AND NOT Charge.Service.IsStockArticle") + 
					?(ValueIsFilled(vDimensionsRow.SeparateService)  AND TypeOf(vDimensionsRow.SeparateService)=Type("CatalogRef.Services"), " AND Charge.Service = &qService", "") + 
					?(ValueIsFilled(vDimensionsRow.SeparateService)  AND TypeOf(vDimensionsRow.SeparateService)=Type("String"), " AND Charge.Service.InvoiceGroupingName = &qService", "") + "
		|) AS CurrentAccountsReceivableBalance
		|
		|UNION ALL
		|
		|SELECT
		|	CurrentAccountsReceivableNextMonthDayBalance.Hotel,
		|	CurrentAccountsReceivableNextMonthDayBalance.Company,
		|	CurrentAccountsReceivableNextMonthDayBalance.Customer,
		|	CurrentAccountsReceivableNextMonthDayBalance.Contract,
		|	CurrentAccountsReceivableNextMonthDayBalance.GuestGroup.Event,
		|	CurrentAccountsReceivableNextMonthDayBalance.GuestGroup,
		|	CurrentAccountsReceivableNextMonthDayBalance.FolioCurrency,
		|	CurrentAccountsReceivableNextMonthDayBalance.Charge.Folio,
		|	CurrentAccountsReceivableNextMonthDayBalance.Charge.ParentDoc,
		|	CurrentAccountsReceivableNextMonthDayBalance.Charge.HotelProduct,
		|	CurrentAccountsReceivableNextMonthDayBalance.Charge,
		|	CurrentAccountsReceivableNextMonthDayBalance.Charge.CorrectedCharge,
		|	CurrentAccountsReceivableNextMonthDayBalance.Charge.VATRate,
		|	CurrentAccountsReceivableNextMonthDayBalance.Charge.Discount,
		|	CurrentAccountsReceivableNextMonthDayBalance.Charge.DiscountSum,
		|	CurrentAccountsReceivableNextMonthDayBalance.Charge.AgentCommissionType,
		|	CurrentAccountsReceivableNextMonthDayBalance.Charge.AgentCommission,
		|	ISNULL(CurrentAccountsReceivableNextMonthDayBalance.Charge.HotelProduct.Parent, &qEmptyHotelProduct),
		|	CurrentAccountsReceivableNextMonthDayBalance.CommissionSumBalance,
		|	CurrentAccountsReceivableNextMonthDayBalance.SumBalance,
		|	CurrentAccountsReceivableNextMonthDayBalance.VATSumBalance,
		|	CurrentAccountsReceivableNextMonthDayBalance.QuantityBalance,
		|	CurrentAccountsReceivableNextMonthDayBalance.Charge.PointInTime
		|FROM
		|	AccumulationRegister.CurrentAccountsReceivable.Balance(
		|			&qEndOfNextMonthDay,
		|			TRUE
		|			AND &qJoinFirstDayOfMonthBreakfasts " + 
					?(vNoHotelProducts, "", " AND (NOT Charge.Service.IsHotelProductService OR 
		|		         						   Charge.Service.IsHotelProductService AND NOT Company.WaitForHotelProduct)") + "
		|			AND ISNULL(Charge.Date, &qEmptyDate) >= &qBegOfNextMonthDay
		|			AND ISNULL(Charge.Date, &qEmptyDate) <= &qEndOfNextMonthDay
		|			AND ISNULL(Charge.Date, &qEmptyDate) > Hotel.EditProhibitedDate
		|			AND Charge.Service.QuantityCalculationRule.QuantityCalculationRuleType = &qBreakfast
		|			AND ISNULL(Charge.HotelProduct.Parent, &qEmptyHotelProduct) = &qHotelProductParent
		|			AND NOT Charge.Service.IsStockArticle
		|			AND Hotel = &qHotel
		|			AND Company = &qCompany
		|			AND CASE
		|					WHEN NOT Company.CreateSettlementsForNonIndividualsClosingByCityLedgerOnly
		|						THEN TRUE
		|					ELSE
		|						CASE
		|							WHEN ISNULL(Customer.IsIndividual, TRUE)
		|								THEN TRUE
		|							WHEN Charge.Folio.PaymentMethod = VALUE(Catalog.PaymentMethods.Settlement)
		|								THEN TRUE
		|							WHEN ISNULL(Charge.Folio.PaymentMethod.IsByBankTransfer, FALSE)
		|								THEN TRUE
		|							ELSE
		|								FALSE
		|						END
		|					END
		|			AND Customer = &qCustomer
		|			AND Contract = &qContract " + 
					?(vIsCorrection, "", ?(OneSettlementPerCustomerGuestGroups And Not ValueIsFilled(vDimensionsRow.GuestGroup), "", ?(OneSettlementPerIndividualsCustomerGuestGroups, "", ?(ValueIsFilled(vDimensionsRow.Event), " AND GuestGroup.Event = &qEvent", " AND (GuestGroup = &qGuestGroup OR &qDoNotFilterByGuestGroup)")))) + 
					?(vIsCorrection, "", ?(OneSettlementPerIndividualsCustomerGuestGroups, ?(ValueIsFilled(vDimensionsRow.Event), " AND GuestGroup.Event = &qEvent", " AND (GuestGroup = &qGuestGroup OR &qDoNotFilterByGuestGroup)"), "")) + 
					?(vIsCorrection, " AND GuestGroup = &qGuestGroup", "") + 
					?(SplitSettllementsByVATRate, " AND Charge.VATRate = &qVATRate", "") + 
					?(SplitSettllementsByPaymentSections, " AND Charge.PaymentSection = &qPaymentSection", "") + "
		|			AND FolioCurrency = &qFolioCurrency " + 
					?(pProcessClosedFoliosOnly, ?(vPastCloseMode, " AND BEGINOFPERIOD(ISNULL(Charge.Folio.DateTimeTo, &qEmptyDate), DAY) <= &qBegOfPeriodTo", "") + " AND (ISNULL(Charge.Folio.IsClosed, FALSE) OR Charge.Service.IsStockArticle OR &qIsEndOfAccountingPeriod OR ((Customer = &qEmptyCustomer OR Customer = Hotel.IndividualsCustomer) AND Company.CloseIndividualsEveryDay))", 
					                            ?(Company.CreateSettlementsAtCheckOutDateForCustomers, " AND (ISNULL(Charge.Folio.IsClosed, FALSE) OR NOT ISNULL(Charge.Folio.IsClosed, FALSE) AND ISNULL(Customer.IsIndividual, TRUE) OR Charge.Service.IsStockArticle)", "")) + 
					?(ValueIsFilled(vDimensionsRow.SeparateAccommodation), " AND Charge.ParentDoc = &qAccommodation", "") + 
					?(ValueIsFilled(vDimensionsRow.SeparateService) AND TypeOf(vDimensionsRow.SeparateService)=Type("CatalogRef.Services"), " AND Charge.Service = &qService", "") + 
					?(ValueIsFilled(vDimensionsRow.SeparateService) AND TypeOf(vDimensionsRow.SeparateService)=Type("String"), " AND Charge.Service.InvoiceGroupingName = &qService", "") + "
		|			AND (&qIsEndOfAccountingPeriod
		|				OR NOT &qIsEndOfAccountingPeriod
		|					AND (ISNULL(Charge.Service.IsStockArticle, FALSE)
		|						OR (NOT ISNULL(Company.CreateSettlementsAtTheEndOfAccountingPeriodOnly, FALSE)
		|							AND NOT ISNULL(Customer.CustomerType.CreateSettlementsAtTheEndOfAccountingPeriodOnly, FALSE)
		|							AND NOT ISNULL(Contract.CreateSettlementsAtTheEndOfAccountingPeriodOnly, FALSE)))
		|				OR NOT &qIsEndOfAccountingPeriod
		|					AND &qIsEndOfMonth
		|					AND (ISNULL(Charge.Service.IsStockArticle, FALSE)
		|						OR (ISNULL(Company.CreateSettlementsAtTheEndOfAccountingPeriodOnly, FALSE)
		|							OR ISNULL(Customer.CustomerType.CreateSettlementsAtTheEndOfAccountingPeriodOnly, FALSE)
		|							OR ISNULL(Contract.CreateSettlementsAtTheEndOfAccountingPeriodOnly, FALSE))))
		|			) AS CurrentAccountsReceivableNextMonthDayBalance
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ChargeInvoices.Charge AS Charge,
		|	MAX(ChargeInvoices.InvoiceNumber) AS InvoiceNumber
		|INTO ChargeLatestInvoices
		|FROM
		|	(SELECT
		|		InvoiceServices.Charge AS Charge,
		|		InvoiceServices.Ref.Number AS InvoiceNumber
		|	FROM
		|		Document.Settlement.Services AS InvoiceServices
		|			INNER JOIN NotInvoicedCharges AS NotInvoicedCharges
		|			ON (InvoiceServices.Charge = NotInvoicedCharges.Charge 
		|					OR InvoiceServices.Charge = NotInvoicedCharges.CorrectedCharge)
		|				AND (InvoiceServices.Ref.Posted)
		|	WHERE
		|		InvoiceServices.Ref.Posted
		|		AND NOT (InvoiceServices.Ref.Sum = 0 AND InvoiceServices.Ref.CommissionSum <> 0)
		|	) AS ChargeInvoices
		|
		|GROUP BY
		|	ChargeInvoices.Charge
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OldInvoices.Ref AS Invoice,
		|	OldInvoices.Charge AS Charge,
		|	OldInvoices.Ref.PointInTime AS PointInTime
		|INTO OldInvoices
		|FROM
		|	Document.Settlement.Services AS OldInvoices
		|		INNER JOIN ChargeLatestInvoices AS ChargeLatestInvoices
		|		ON OldInvoices.Charge = ChargeLatestInvoices.Charge 
		|			AND OldInvoices.Ref.Number = ChargeLatestInvoices.InvoiceNumber
		|WHERE
		|	OldInvoices.Ref.Posted
		|	AND NOT (OldInvoices.Ref.Sum = 0 AND OldInvoices.Ref.CommissionSum <> 0)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NotInvoicedCharges.Hotel AS Hotel,
		|	NotInvoicedCharges.Company AS Company,
		|	NotInvoicedCharges.Customer AS Customer,
		|	NotInvoicedCharges.Contract AS Contract,
		|	NotInvoicedCharges.Event AS Event,
		|	NotInvoicedCharges.GuestGroup AS GuestGroup,
		|	NotInvoicedCharges.FolioCurrency AS FolioCurrency,
		|	NotInvoicedCharges.Folio AS Folio,
		|	NotInvoicedCharges.ParentDoc AS ParentDoc,
		|	NotInvoicedCharges.HotelProduct AS HotelProduct,
		|	NotInvoicedCharges.Charge AS Charge,
		|	NotInvoicedCharges.Discount AS Discount,
		|	NotInvoicedCharges.DiscountSum AS DiscountSum,
		|	NotInvoicedCharges.AgentCommissionType AS AgentCommissionType,
		|	NotInvoicedCharges.AgentCommission AS AgentCommission,
		|	NotInvoicedCharges.HotelProductParent AS HotelProductParent,
		|	NotInvoicedCharges.VATRate AS VATRate,
		|	NotInvoicedCharges.VATRate.Code AS VATRateCode,
		|	NotInvoicedCharges.CommissionSumBalance AS CommissionSumBalance,
		|	NotInvoicedCharges.SumBalance AS SumBalance,
		|	NotInvoicedCharges.VATSumBalance AS VATSumBalance,
		|	NotInvoicedCharges.QuantityBalance AS QuantityBalance,
		|	NotInvoicedCharges.ChargePointInTime AS ChargePointInTime,
		|	CASE
		|		WHEN OldInvoices.Invoice.Number IS NULL 
		|			THEN 0
		|		ELSE
		|			1
		|	END AS ChargeHasInvoice,
		|	CASE
		|		WHEN NotInvoicedCharges.SumBalance < 0
		|			THEN -1
		|		WHEN NotInvoicedCharges.SumBalance > 0
		|			THEN 1
		|		WHEN NotInvoicedCharges.QuantityBalance < 0
		|			THEN -1
		|		WHEN NotInvoicedCharges.VATSumBalance < 0
		|			THEN -1
		|		ELSE
		|			1
		|	END AS ChargeSign,
		|	OldInvoices.Invoice.Number AS InvoiceNumber,
		|	OldInvoices.Invoice AS Invoice
		|FROM
		|	NotInvoicedCharges AS NotInvoicedCharges
		|		LEFT JOIN OldInvoices AS OldInvoices
		|		ON (NotInvoicedCharges.Charge = OldInvoices.Charge 
		|			OR NotInvoicedCharges.CorrectedCharge = OldInvoices.Charge)
		|
		|ORDER BY
		|	ChargeHasInvoice,
		|	InvoiceNumber,
		|	ChargeSign,
		|	VATRateCode,
		|	ChargePointInTime";
		vQry.SetParameter("qDate", New Boundary(vDate, BoundaryType.Excluding));
		vQry.SetParameter("qBegOfNextMonthDay", vBegOfNextMonthDay);
		vQry.SetParameter("qEndOfNextMonthDay", vEndOfNextMonthDay);
		vQry.SetParameter("qJoinFirstDayOfMonthBreakfasts", vJoinFirstDayOfMonthBreakfasts);
		vQry.SetParameter("qBreakfast", Enums.QuantityCalculationRuleTypes.Breakfast);
		vQry.SetParameter("qHotel", vDimensionsRow.Hotel);
		vQry.SetParameter("qCompany", vDimensionsRow.Company);
		vQry.SetParameter("qCustomer", vDimensionsRow.Customer);
		vQry.SetParameter("qContract", vDimensionsRow.Contract);
		vQry.SetParameter("qGuestGroup", vDimensionsRow.GuestGroup);
		vQry.SetParameter("qDoNotFilterByGuestGroup", ?(vDimensionsRow.DoNotFilterByGuestGroup = 1, True, False));
		vQry.SetParameter("qEvent", vDimensionsRow.Event);
		vQry.SetParameter("qFolioCurrency", vDimensionsRow.FolioCurrency);
		vQry.SetParameter("qAccommodation", vDimensionsRow.SeparateAccommodation);
		vQry.SetParameter("qService", vDimensionsRow.SeparateService);
		vQry.SetParameter("qVATRate", vDimensionsRow.VATRate);
		vQry.SetParameter("qPaymentSection", vDimensionsRow.PaymentSection);
		vQry.SetParameter("qHotelProductParent", vDimensionsRow.HotelProductParent);
		If ValueIsFilled(Company) And Company.CloseMonthAtDayBeforeTheLastMonthDay Then
			vQry.SetParameter("qPeriodTo", Max(vDate - 1, EndOfMonth(Date) - 24*3600));
		Else
			vQry.SetParameter("qPeriodTo", Max(vDate - 1, EndOfMonth(Date)));
		EndIf;
		vQry.SetParameter("qBegOfPeriodTo", BegOfDay(Date));
		vQry.SetParameter("qEmptyDate", '00010101');
		vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
		vQry.SetParameter("qEmptyHotelProduct", Catalogs.HotelProducts.EmptyRef());
		vAccParamsStruct = Company;
		If ValueIsFilled(vAccountingContract) And ValueIsFilled(vAccountingContract.TaxAccountingPeriodType) Then
			vAccParamsStruct = vAccountingContract;
		EndIf;
		If ValueIsFilled(vAccParamsStruct) Then
			If vAccParamsStruct.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.Year Then
				vQry.SetParameter("qIsEndOfAccountingPeriod", ?(EndOfDay(Date) = EndOfYear(Date), True, False));
			ElsIf vAccParamsStruct.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.HalfYear Then
				vQry.SetParameter("qIsEndOfAccountingPeriod", ?(EndOfDay(Date) = EndOfMonth(AddMonth(BegOfYear(Date), 6)), True, False));
			ElsIf vAccParamsStruct.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.Quarter Then
				vQry.SetParameter("qIsEndOfAccountingPeriod", ?(EndOfDay(Date) = EndOfQuarter(Date), True, False));
			ElsIf vAccParamsStruct.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.Month Then
				If Company.CloseMonthAtDayBeforeTheLastMonthDay Then
					vQry.SetParameter("qIsEndOfAccountingPeriod", ?(EndOfDay(Date) = (EndOfMonth(Date) - 24*3600), True, False));
				Else
					vQry.SetParameter("qIsEndOfAccountingPeriod", ?(EndOfDay(Date) = EndOfMonth(Date), True, False));
				EndIf;
			ElsIf vAccParamsStruct.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.Decade Then
				vDay = Day(Date);
				If vDay = 10 Then
					vQry.SetParameter("qIsEndOfAccountingPeriod", True);
				ElsIf vDay = 20 Then 
					vQry.SetParameter("qIsEndOfAccountingPeriod", True);
				Else
					If Company.CloseMonthAtDayBeforeTheLastMonthDay Then
						vQry.SetParameter("qIsEndOfAccountingPeriod", ?(EndOfDay(Date) = (EndOfMonth(Date) - 24*3600), True, False));
					Else
						vQry.SetParameter("qIsEndOfAccountingPeriod", ?(EndOfDay(Date) = EndOfMonth(Date), True, False));
					EndIf;
				EndIf;
			Else
				vQry.SetParameter("qIsEndOfAccountingPeriod", False);
			EndIf;
			If vAccParamsStruct.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.None Then
				If Company.CloseMonthAtDayBeforeTheLastMonthDay Then
					vQry.SetParameter("qIsEndOfMonth", ?(EndOfDay(Date) = (EndOfMonth(Date) - 24*3600), True, False));
				Else
					vQry.SetParameter("qIsEndOfMonth", ?(EndOfDay(Date) = EndOfMonth(Date), True, False));
				EndIf;
			Else
				vQry.SetParameter("qIsEndOfMonth", False);
			EndIf;
		Else
			vQry.SetParameter("qIsEndOfAccountingPeriod", False);
			vQry.SetParameter("qIsEndOfMonth", False);
		EndIf;
		vCharges = vQry.Execute().Unload();
		If vCharges.Count() > 0 Then
			If vIsCorrection Then
				vCurInvoice = Undefined;
				vCurChargeSign = 0;
				vCurVATRate = Undefined;
				vCurInvoiceCharges = vCharges.Copy();
				vCurInvoiceCharges.Clear();
				For Each vChargesRow In vCharges Do
					If vCurInvoice <> Undefined And 
					  (vCurInvoice <> vChargesRow.Invoice Or vCurVATRate <> vChargesRow.VATRate) Then
						If vCurInvoiceCharges.Count() > 0 Then
							If ValueIsFilled(vCurInvoice) Then
								// Create credit or debit note for this invoice
								CreateAndPostCorrectionNote(vDimensionsRow, vAccountingCustomer, vAccountingContract, vAccountingCurrency, 
								                            vLanguage, vCurInvoiceCharges, vCurInvoice, pProcessClosedFoliosOnly, 1);
							Else
								// Create invoice
								CreateAndPostInvoice(vDimensionsRow, vAccountingCustomer, vAccountingContract, vAccountingCurrency, 
								                     vLanguage, vCurInvoiceCharges, vIsCorrection, pProcessClosedFoliosOnly);
							EndIf;
						EndIf;
						
						vCurInvoiceCharges.Clear();
					EndIf;
					vCurInvoice = vChargesRow.Invoice;
					vCurChargeSign = vChargesRow.ChargeSign;
					vCurVATRate = vChargesRow.VATRate;
					
					vCurInvoiceChargesRow = vCurInvoiceCharges.Add();
					FillPropertyValues(vCurInvoiceChargesRow, vChargesRow);
				EndDo;
				If vCurInvoiceCharges.Count() > 0 Then
					If ValueIsFilled(vCurInvoice) Then
						// Create credit or debit note for this invoice
						CreateAndPostCorrectionNote(vDimensionsRow, vAccountingCustomer, vAccountingContract, vAccountingCurrency, 
						                            vLanguage, vCurInvoiceCharges, vCurInvoice, pProcessClosedFoliosOnly, 1);
					Else
						// Create invoice
						CreateAndPostInvoice(vDimensionsRow, vAccountingCustomer, vAccountingContract, vAccountingCurrency, 
						                     vLanguage, vCurInvoiceCharges, vIsCorrection, pProcessClosedFoliosOnly);
					EndIf;
				EndIf;
			Else
				// Create settlement and fill it's services with charges retrieved
				CreateAndPostInvoice(vDimensionsRow, vAccountingCustomer, vAccountingContract, vAccountingCurrency, 
				                     vLanguage, vCharges, vIsCorrection, pProcessClosedFoliosOnly);
			EndIf;
		EndIf;
	EndDo;
	WriteLogEvent(NStr("en='CloseOfPeriod.BuildSettlements';ru='ЗакрытиеПериода.ФормированиеАктов';de='CloseOfPeriod.BuildSettlements'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='End of building settlements';ru='Закончена операция формирования актов';de='Operation der Übergabeprotokollerstellung ist abgeschlossen'"), EventLogEntryTransactionMode.Independent);
EndProcedure // CloseCurrentAccountsReceivable

// -----------------------------------------------------------------------------
Procedure DoPaymentsDistributionToServices(pCancel, pPostingMode)
	If ValueIsFilled(Hotel) And Not Hotel.DoPaymentsDistributionToServices Then
		Return;
	EndIf;
	WriteLogEvent(NStr("en='CloseOfPeriod.PaymentsDistributionToServices';ru='ЗакрытиеПериода.РаспределениеПлатежейПоУслугам';de='CloseOfPeriod.PaymentsDistributionToServices'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='Start of payments distribution to services...';ru='Начата операция распределения платежей по услугам...';de='Verteilung von Zahlungen nach Dienstleistungen wurde gestartet…'"), EventLogEntryTransactionMode.Independent);
	// Get table with returns only
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ReturnServicesBalance.Folio,
	|	ReturnServicesBalance.PaymentSection,
	|	ReturnServicesBalance.Payment,
	|	ReturnServicesBalance.SumBalance AS ReturnBalance
	|FROM
	|	AccumulationRegister.PaymentServices.Balance(
	|			&qDate,
	|			(Folio.Hotel IN HIERARCHY (&qHotel)
	|				OR &qHotelIsEmpty)
	|				AND (Folio.Company IN HIERARCHY (&qCompany)
	|					OR &qCompanyIsEmpty)
	|				AND Folio.Hotel.DoPaymentsDistributionToServices
	|				AND Payment <> UNDEFINED
	|				AND Payment.CashRegister = &qEmptyCashRegister
	|				AND Service = &qEmptyService) AS ReturnServicesBalance
	|		INNER JOIN (SELECT
	|			PaymentServicesTurnovers.Folio AS Folio,
	|			PaymentServicesTurnovers.PaymentSection AS PaymentSection,
	|			PaymentServicesTurnovers.SumTurnover AS SumTurnover
	|		FROM
	|			AccumulationRegister.PaymentServices.Turnovers(
	|					,
	|					,
	|					Period,
	|					(Folio.Hotel IN HIERARCHY (&qHotel)
	|						OR &qHotelIsEmpty)
	|						AND (Folio.Company IN HIERARCHY (&qCompany)
	|							OR &qCompanyIsEmpty)
	|						AND Folio.Hotel.DoPaymentsDistributionToServices
	|						AND Payment = UNDEFINED
	|						AND Service <> &qEmptyService) AS PaymentServicesTurnovers) AS ServicesTurnovers
	|		ON ReturnServicesBalance.Folio = ServicesTurnovers.Folio
	|			AND ReturnServicesBalance.PaymentSection = ServicesTurnovers.PaymentSection
	|WHERE
	|	ReturnServicesBalance.SumBalance > 0
	|
	|ORDER BY
	|	ReturnServicesBalance.Folio.PointInTime,
	|	ReturnServicesBalance.PaymentSection.Code,
	|	ReturnServicesBalance.Payment.PointInTime DESC";
	vQry.SetParameter("qDate", New Boundary(Date + 1, BoundaryType.Excluding));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQry.SetParameter("qEmptyService", Catalogs.Services.EmptyRef());
	vQry.SetParameter("qEmptyCashRegister", Catalogs.CashRegisters.EmptyRef());
	vReturns = vQry.Execute().Unload();
	
	// Process returns
	vCurFolio = Undefined;
	vCharges = New ValueTable();
	For Each vReturnsRow In vReturns Do
		// Try to find charges for the current folio
		If vCurFolio <> vReturnsRow.Folio Then
			vCurFolio = vReturnsRow.Folio;
			
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	FolioCharges.Folio,
			|	FolioCharges.Service,
			|	FolioCharges.PaymentSection,
			|	FolioCharges.Payment,
			|	SUM(FolioCharges.Sum) AS Sum
			|FROM
			|	AccumulationRegister.PaymentServices AS FolioCharges
			|WHERE
			|	FolioCharges.Folio = &qFolio
			|	AND FolioCharges.Service <> &qEmptyService
			|	AND FolioCharges.Payment <> UNDEFINED
			|	AND FolioCharges.RecordType = &qExpense
			|	AND FolioCharges.Sum <> 0
			|
			|GROUP BY
			|	FolioCharges.Folio,
			|	FolioCharges.Service,
			|	FolioCharges.PaymentSection,
			|	FolioCharges.Payment
			|
			|HAVING
			|	SUM(FolioCharges.Sum) <> 0
			|
			|ORDER BY
			|	FolioCharges.PaymentSection.Code,
			|	FolioCharges.Service.IsRoomRevenue,
			|	FolioCharges.Service.SortCode DESC";
			vQry.SetParameter("qFolio", vCurFolio);
			vQry.SetParameter("qEmptyService", Catalogs.Services.EmptyRef());
			vQry.SetParameter("qExpense", AccumulationRecordType.Expense);
			vCharges = vQry.Execute().Unload();
		EndIf;
		If vCharges.Count() > 0 Then
			For Each vChargesRow In vCharges Do
				If vReturnsRow.ReturnBalance > 0 Then
					If vReturnsRow.PaymentSection = vChargesRow.PaymentSection Then
						// Sum being undistributed
						vUndistrSum = Min(vReturnsRow.ReturnBalance, vChargesRow.Sum);
						If vUndistrSum <> 0 Then
							// Add charge write off cancellation movement
							Movement = RegisterRecords.PaymentServices.Add();
							Movement.RecordType = AccumulationRecordType.Expense;
							Movement.Period = vReturnsRow.Payment.Date;
							Movement.Folio = vCurFolio;
							Movement.PaymentSection = vChargesRow.PaymentSection;
							Movement.Service = vChargesRow.Service;
							Movement.Payment = Undefined;
							Movement.Sum = -vUndistrSum;

							// Add charge undistribution movement
							Movement = RegisterRecords.PaymentServices.Add();
							Movement.RecordType = AccumulationRecordType.Expense;
							Movement.Period = vReturnsRow.Payment.Date;
							Movement.Folio = vCurFolio;
							Movement.PaymentSection = vChargesRow.PaymentSection;
							Movement.Service = vChargesRow.Service;
							Movement.Payment = vChargesRow.Payment;
							Movement.Sum = -vUndistrSum;
							
							// Add payment write off cancellation movement
							Movement = RegisterRecords.PaymentServices.Add();
							Movement.RecordType = AccumulationRecordType.Expense;
							Movement.Period = vReturnsRow.Payment.Date;
							Movement.Folio = vCurFolio;
							Movement.PaymentSection = vReturnsRow.PaymentSection;
							Movement.Service = Catalogs.Services.EmptyRef();
							Movement.Payment = vChargesRow.Payment;
							Movement.Sum = vUndistrSum;
						EndIf;
						
						// Correct working table row
						vReturnsRow.ReturnBalance = vReturnsRow.ReturnBalance - vUndistrSum;
					EndIf;
				Else
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	// Write return movements
	If RegisterRecords.PaymentServices.Count() > 0 Then
		RegisterRecords.PaymentServices.Write();
	EndIf;
	
	// Get table with undistributed service balances
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ServicesBalance.Folio,
	|	ServicesBalance.PaymentSection,
	|	ServicesBalance.Service,
	|	ServicesBalance.SumBalance
	|FROM
	|	AccumulationRegister.PaymentServices.Balance(
	|			&qEndOfTime,
	|			(Folio.Hotel IN HIERARCHY (&qHotel)
	|				OR &qHotelIsEmpty)
	|				AND (Folio.Company IN HIERARCHY (&qCompany)
	|					OR &qCompanyIsEmpty)
	|				AND Folio.Hotel.DoPaymentsDistributionToServices
	|				AND Payment = UNDEFINED
	|				AND Service <> &qEmptyService) AS ServicesBalance
	|		INNER JOIN (SELECT
	|			PaymentsBalance.Folio AS Folio,
	|			PaymentsBalance.PaymentSection AS PaymentSection
	|		FROM
	|			(SELECT
	|				PaymentServicesBalance.Folio AS Folio,
	|				PaymentServicesBalance.PaymentSection AS PaymentSection,
	|				PaymentServicesBalance.Payment AS Payment,
	|				-PaymentServicesBalance.SumBalance AS PaymentBalance
	|			FROM
	|				AccumulationRegister.PaymentServices.Balance(
	|						&qDate,
	|						(Folio.Hotel IN HIERARCHY (&qHotel)
	|							OR &qHotelIsEmpty)
	|							AND (Folio.Company IN HIERARCHY (&qCompany)
	|								OR &qCompanyIsEmpty)
	|							AND Folio.Hotel.DoPaymentsDistributionToServices
	|							AND Payment <> UNDEFINED
	|							AND Payment.CashRegister = &qEmptyCashRegister
	|							AND Service = &qEmptyService) AS PaymentServicesBalance
	|			WHERE
	|				PaymentServicesBalance.SumBalance < 0) AS PaymentsBalance
	|		
	|		GROUP BY
	|			PaymentsBalance.Folio,
	|			PaymentsBalance.PaymentSection) AS FoliosWithPayments
	|		ON ServicesBalance.Folio = FoliosWithPayments.Folio AND ServicesBalance.PaymentSection = FoliosWithPayments.PaymentSection
	|
	|ORDER BY
	|	ServicesBalance.Folio.PointInTime,
	|	ServicesBalance.PaymentSection.Code,
	|	ServicesBalance.Service.IsRoomRevenue DESC,
	|	ServicesBalance.Service.SortCode";
	vQry.SetParameter("qEndOfTime", '39991231235959');
	vQry.SetParameter("qDate", New Boundary(Date + 1, BoundaryType.Excluding));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQry.SetParameter("qEmptyService", Catalogs.Services.EmptyRef());
	vQry.SetParameter("qEmptyCashRegister", Catalogs.CashRegisters.EmptyRef());
	vServices = vQry.Execute().Unload();
	
	// Get table with undistributed payment balances
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PaymentServicesBalance.Folio,
	|	PaymentServicesBalance.PaymentSection,
	|	PaymentServicesBalance.Payment,
	|	-PaymentServicesBalance.SumBalance AS PaymentBalance
	|FROM
	|	AccumulationRegister.PaymentServices.Balance(
	|			&qDate,
	|			(Folio.Hotel IN HIERARCHY (&qHotel)
	|				OR &qHotelIsEmpty)
	|				AND (Folio.Company IN HIERARCHY (&qCompany)
	|					OR &qCompanyIsEmpty)
	|				AND Folio.Hotel.DoPaymentsDistributionToServices
	|				AND Payment <> UNDEFINED
	|				AND Payment.CashRegister = &qEmptyCashRegister
	|				AND Service = &qEmptyService) AS PaymentServicesBalance
	|WHERE
	|	PaymentServicesBalance.SumBalance < 0
	|
	|ORDER BY
	|	PaymentServicesBalance.Folio.PointInTime,
	|	PaymentServicesBalance.PaymentSection.Code,
	|	PaymentServicesBalance.Payment.PointInTime,
	|	PaymentServicesBalance.Service.IsRoomRevenue DESC,
	|	PaymentServicesBalance.Service.SortCode";
	vQry.SetParameter("qDate", New Boundary(Date + 1, BoundaryType.Excluding));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQry.SetParameter("qEmptyService", Catalogs.Services.EmptyRef());
	vQry.SetParameter("qEmptyCashRegister", Catalogs.CashRegisters.EmptyRef());
	vPayments = vQry.Execute().Unload();
	
	// Process undistributed services with balances
	vCurFolio = Undefined;
	vFolioPayments = New Array;
	For Each vServicesRow In vServices Do
		// Try to find payments for the current folio
		If vCurFolio <> vServicesRow.Folio Then
			vCurFolio = vServicesRow.Folio;
			vFolioPayments = vPayments.FindRows(New Structure("Folio", vCurFolio));
		EndIf;
		If vFolioPayments.Count() > 0 Then
			For Each vPaymentsRow In vFolioPayments Do
				If vPaymentsRow.PaymentBalance > 0 And vPaymentsRow.PaymentSection = vServicesRow.PaymentSection Then
					// Sum being distributed
					vDistrSum = Min(vServicesRow.SumBalance, vPaymentsRow.PaymentBalance);
					If vDistrSum <> 0 Then
						// Add payment distribution movement
						Movement = RegisterRecords.PaymentServices.Add();
						Movement.RecordType = AccumulationRecordType.Expense;
						Movement.Period = vPaymentsRow.Payment.Date;
						Movement.Folio = vCurFolio;
						Movement.PaymentSection = vServicesRow.PaymentSection;
						Movement.Service = vServicesRow.Service;
						Movement.Payment = vPaymentsRow.Payment;
						Movement.Sum = vDistrSum;

						// Add service write off movement
						Movement = RegisterRecords.PaymentServices.Add();
						Movement.RecordType = AccumulationRecordType.Expense;
						Movement.Period = vPaymentsRow.Payment.Date;
						Movement.Folio = vCurFolio;
						Movement.PaymentSection = vServicesRow.PaymentSection;
						Movement.Service = vServicesRow.Service;
						Movement.Payment = Undefined;
						Movement.Sum = vDistrSum;
						
						// Add payment write off movement
						Movement = RegisterRecords.PaymentServices.Add();
						Movement.RecordType = AccumulationRecordType.Expense;
						Movement.Period = vPaymentsRow.Payment.Date;
						Movement.Folio = vCurFolio;
						Movement.PaymentSection = vPaymentsRow.PaymentSection;
						Movement.Service = Catalogs.Services.EmptyRef();
						Movement.Payment = vPaymentsRow.Payment;
						Movement.Sum = -vDistrSum;
					EndIf;
					
					// Correct working table row
					vPaymentsRow.PaymentBalance = vPaymentsRow.PaymentBalance - vDistrSum;
					vServicesRow.SumBalance = vServicesRow.SumBalance - vDistrSum;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	// Write all movements
	RegisterRecords.PaymentServices.Write();
	WriteLogEvent(NStr("en='CloseOfPeriod.PaymentsDistributionToServices';ru='ЗакрытиеПериода.РаспределениеПлатежейПоУслугам';de='CloseOfPeriod.PaymentsDistributionToServices'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='End of payments distribution to services';ru='Закончена операция распределения платежей по услугам';de='Operation der Zahlungsverteilung nach Dienstleistungen ist abgeschlossen'"), EventLogEntryTransactionMode.Independent);
EndProcedure // DoPaymentsDistributionToServices

// -----------------------------------------------------------------------------
Procedure AcceptExpectedRoomMoves(pIsPosted = False)
	// Log start of closing orphan folios
	WriteLogEvent(NStr("en='CloseOfPeriod.ApplyExpectedRoomMoves';ru='ЗакрытиеПериода.ПрименитьПланируемыеПереселения';de='CloseOfPeriod.ErwartetenZimmerbewegungenAnwenden'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='Start of applying expected room moves...';ru='Начата операция применения планируемых переселений...';de='Dienst gestartet für der Anwendung der erwarteten Zimmerbewegungen...'"), EventLogEntryTransactionMode.Independent);
	// Run query to get folios to process
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	ExpectedChanges.Ref AS Ref,
	|	ExpectedChanges.Room AS Room,
	|	ExpectedChanges.RoomType AS RoomType,
	|	ExpectedChanges.RoomRate AS RoomRate,
	|	ExpectedChanges.ServicePackage AS ServicePackage,
	|	ExpectedChanges.AccommodationTemplate AS AccommodationTemplate,
	|	ExpectedChanges.AccommodationType AS AccommodationType,
	|	ExpectedChanges.ClientType AS ClientType,
	|	ExpectedChanges.SourceOfBusiness AS SourceOfBusiness,
	|	ExpectedChanges.MarketingCode AS MarketingCode
	|FROM
	|	Document.Accommodation.RoomRates AS ExpectedChanges
	|WHERE
	|	ExpectedChanges.AccountingDate = &qAccountingDate
	|	AND (ExpectedChanges.Room <> ExpectedChanges.Ref.Room
	|				AND ExpectedChanges.Room <> VALUE(Catalog.Rooms.EmptyRef)
	|				AND ExpectedChanges.Ref.Room <> VALUE(Catalog.Rooms.EmptyRef)
	|			OR ExpectedChanges.RoomRate <> ExpectedChanges.Ref.RoomRate
	|				AND ExpectedChanges.RoomRate <> VALUE(Catalog.RoomRates.EmptyRef)
	|				AND ExpectedChanges.Ref.RoomRate <> VALUE(Catalog.RoomRates.EmptyRef)
	|			OR ExpectedChanges.AccommodationType <> ExpectedChanges.Ref.AccommodationType
	|				AND ExpectedChanges.AccommodationType <> VALUE(Catalog.AccommodationTypes.EmptyRef)
	|				AND ExpectedChanges.Ref.AccommodationType <> VALUE(Catalog.AccommodationTypes.EmptyRef)
	|			OR ExpectedChanges.AccommodationTemplate <> ExpectedChanges.Ref.AccommodationTemplate
	|				AND ExpectedChanges.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|				AND ExpectedChanges.Ref.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|			OR ExpectedChanges.ClientType <> ExpectedChanges.Ref.ClientType
	|				AND ExpectedChanges.ClientType <> VALUE(Catalog.ClientTypes.EmptyRef)
	|				AND ExpectedChanges.Ref.ClientType <> VALUE(Catalog.ClientTypes.EmptyRef)
	|			OR ExpectedChanges.SourceOfBusiness <> ExpectedChanges.Ref.SourceOfBusiness
	|				AND ExpectedChanges.SourceOfBusiness <> VALUE(Catalog.SourcesOfBusiness.EmptyRef)
	|				AND ExpectedChanges.Ref.SourceOfBusiness <> VALUE(Catalog.SourcesOfBusiness.EmptyRef)
	|			OR ExpectedChanges.MarketingCode <> ExpectedChanges.Ref.MarketingCode
	|				AND ExpectedChanges.MarketingCode <> VALUE(Catalog.MarketingCodes.EmptyRef)
	|				AND ExpectedChanges.Ref.MarketingCode <> VALUE(Catalog.MarketingCodes.EmptyRef)
	|			OR ExpectedChanges.ServicePackage <> ExpectedChanges.Ref.ServicePackage
	|				AND ExpectedChanges.ServicePackage <> VALUE(Catalog.ServicePackages.EmptyRef)
	|				AND ExpectedChanges.Ref.ServicePackage <> VALUE(Catalog.ServicePackages.EmptyRef))
	|	AND ISNULL(ExpectedChanges.Ref.AccommodationStatus.IsActive, FALSE)
	|	AND ISNULL(ExpectedChanges.Ref.AccommodationStatus.IsInHouse, FALSE)
	|	AND ExpectedChanges.Ref.Posted" + 
		?(ValueIsFilled(Hotel), " AND ExpectedChanges.Ref.Hotel IN HIERARCHY(&qHotel)", "") + 
		?(ValueIsFilled(Company), " AND ExpectedChanges.Ref.Company IN HIERARCHY(&qCompany)", "") + "
	|ORDER BY
	|	ExpectedChanges.Ref.Room.SortCode,
	|	ExpectedChanges.Ref.SortCode,
	|	ExpectedChanges.Ref.PointInTime";
	vQry.SetParameter("qAccountingDate", BegOfDay(Date));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQryRes = vQry.Execute().Unload();
	For Each vQryResRow In vQryRes Do
		vAccommodationObj = vQryResRow.Ref.GetObject();
		vAccommodationObj.AdditionalProperties.Insert("CloseOfDayMode", True);
		vAccommodationObj.AdditionalProperties.Insert("AccountingDate", BegOfDay(Date));
		// Log accommodation reposting
		WriteLogEvent(NStr("en='CloseOfPeriod.ApplyExpectedRoomMoves';ru='ЗакрытиеПериода.ПрименитьПланируемыеПереселения';de='CloseOfPeriod.ErwartetenZimmerbewegungenAnwenden'"), EventLogLevel.Information, vAccommodationObj.Metadata(), vAccommodationObj.Ref, "Start: " + TrimAll(vAccommodationObj.Room) + ", " + TrimAll(vAccommodationObj.GuestFullName) + ", " + TrimAll(vAccommodationObj.GuestGroup), EventLogEntryTransactionMode.Independent);
		// Update document attributes
		If ValueIsFilled(vQryResRow.Room) And vQryResRow.Room <> vAccommodationObj.Room Then
			vAccommodationObj.Room = vQryResRow.Room;
			// Retrieve room resources
			vRoomAttrs = vAccommodationObj.Room.GetObject().pmGetRoomAttributes(Date);
			For Each vRoomAttrsRow In vRoomAttrs Do
				vAccommodationObj.RoomType = vRoomAttrsRow.RoomType;
				Break;
			EndDo;
		EndIf;
		If ValueIsFilled(vQryResRow.RoomRate) And vQryResRow.RoomRate <> vAccommodationObj.RoomRate Then
			vAccommodationObj.RoomRate = vQryResRow.RoomRate;
		EndIf;
		If ValueIsFilled(vQryResRow.ServicePackage) And vQryResRow.ServicePackage <> vAccommodationObj.ServicePackage Then
			vAccommodationObj.ServicePackage = vQryResRow.ServicePackage;
		EndIf;
		If ValueIsFilled(vQryResRow.AccommodationTemplate) And vQryResRow.AccommodationTemplate <> vAccommodationObj.AccommodationTemplate Then
			vAccommodationObj.AccommodationTemplate = vQryResRow.AccommodationTemplate;
		EndIf;
		If ValueIsFilled(vQryResRow.AccommodationType) And vQryResRow.AccommodationType <> vAccommodationObj.AccommodationType Then
			vAccommodationObj.AccommodationType = vQryResRow.AccommodationType;
		EndIf;
		If ValueIsFilled(vQryResRow.ClientType) And vQryResRow.ClientType <> vAccommodationObj.ClientType Then
			vAccommodationObj.ClientType = vQryResRow.ClientType;
		EndIf;
		If ValueIsFilled(vQryResRow.SourceOfBusiness) And vQryResRow.SourceOfBusiness <> vAccommodationObj.SourceOfBusiness Then
			vAccommodationObj.SourceOfBusiness = vQryResRow.SourceOfBusiness;
		EndIf;
		If ValueIsFilled(vQryResRow.MarketingCode) And vQryResRow.MarketingCode <> vAccommodationObj.MarketingCode Then
			vAccommodationObj.MarketingCode = vQryResRow.MarketingCode;
		EndIf;
		// Save changes if document was modified
		If vAccommodationObj.Modified() Then
			// Calculate resources
			vAccommodationObj.pmCalculateResources();
			// Automatic services list calculation
			vAccommodationObj.pmCalculateServices();
			// Repost document
			vAccommodationObj.Write(DocumentWriteMode.Posting);
			// Write to accommodation change history
			vAccommodationObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		EndIf;
	EndDo;
	// Log number of reposted accommodations
	WriteLogEvent(NStr("en='CloseOfPeriod.ApplyExpectedRoomMoves';ru='ЗакрытиеПериода.ПрименитьПланируемыеПереселения';de='CloseOfPeriod.ErwartetenZimmerbewegungenAnwenden'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='Reposted are ';ru='Перепроведено ';de='Reposting '") + vQryRes.Count() + NStr("en=' accommodations';ru=' размещений';de=' in-house Gaste'"), EventLogEntryTransactionMode.Independent);
EndProcedure // AcceptExpectedRoomMoves

// -----------------------------------------------------------------------------
Procedure CreateChargesForTheClosedDay(pIsPosted = False)
	// Log start of closing orphan folios
	WriteLogEvent(NStr("en='CloseOfPeriod.DoEveryDayCharges';ru='ЗакрытиеПериода.НачислениеУслуг';de='CloseOfPeriod.Berechnungsdienste'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='Start of charging every day services for in-house guests...';ru='Начата операция начисления услуг по проживающим гостям...';de='Dienst gestartet für Hotelgäste Dinstleistungen zurechnen...'"), EventLogEntryTransactionMode.Independent);
	// Run query to get accommodations to process
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodations.Ref AS Ref
	|FROM
	|	Document.Accommodation AS Accommodations
	|WHERE
	|	Accommodations.Posted
	|	AND ISNULL(Accommodations.AccommodationStatus.IsActive, FALSE)
	|	AND ISNULL(Accommodations.AccommodationStatus.IsInHouse, FALSE)
	|	AND (ISNULL(Accommodations.Hotel.CloseOfPeriodDoChargeServices, FALSE)
	|			OR ISNULL(Accommodations.RoomRate.CloseOfPeriodDoChargeServices, FALSE))" + 
		?(ValueIsFilled(Hotel), " AND Accommodations.Hotel IN HIERARCHY(&qHotel)", "") + 
		?(ValueIsFilled(Company), " AND Accommodations.Company IN HIERARCHY(&qCompany)", "") + "
	|ORDER BY
	|	Accommodations.Room.SortCode,
	|	Accommodations.PointInTime";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQryRes = vQry.Execute().Unload();
	For Each vQryResRow In vQryRes Do
		vAccommodationObj = vQryResRow.Ref.GetObject();
		vAccommodationObj.AdditionalProperties.Insert("CloseOfDayMode", True);
		vAccommodationObj.AdditionalProperties.Insert("AccountingDate", BegOfDay(Date));
		// Log accommodation reposting and do charging
		WriteLogEvent(NStr("en='CloseOfPeriod.DoEveryDayCharges';ru='ЗакрытиеПериода.НачислениеУслуг';de='CloseOfPeriod.Berechnungsdienste'"), EventLogLevel.Information, vAccommodationObj.Metadata(), vAccommodationObj.Ref, "Start: " + TrimAll(vAccommodationObj.Room) + ", " + TrimAll(vAccommodationObj.GuestFullName) + ", " + TrimAll(vAccommodationObj.GuestGroup), EventLogEntryTransactionMode.Independent);
		vAccommodationObj.pmChargeServices(False, DocumentPostingMode.Regular);
		// Process forecast records
		WriteLogEvent(NStr("en='CloseOfPeriod.ForecastRecalculation';ru='ЗакрытиеПериода.ПересчетПрогноза';de='CloseOfPeriod.PrognoseNeuberechnung'"), EventLogLevel.Information, vAccommodationObj.Metadata(), vAccommodationObj.Ref, "Start: " + TrimAll(vAccommodationObj.Room) + ", " + TrimAll(vAccommodationObj.GuestFullName) + ", " + TrimAll(vAccommodationObj.GuestGroup), EventLogEntryTransactionMode.Independent);
		If (BegOfDay(Date) + 24*3600) >= BegOfDay(vAccommodationObj.CheckOutDate) Then
			WriteLogEvent(NStr("en='CloseOfPeriod.ClearForecastRecords';ru='ЗакрытиеПериода.ОчисткаПрогнозныхРегистров';de='CloseOfPeriod.PrognosedatensätzeLöschen'"), EventLogLevel.Information, vAccommodationObj.Metadata(), vAccommodationObj.Ref, "Start: " + TrimAll(vAccommodationObj.Room) + ", " + TrimAll(vAccommodationObj.GuestFullName) + ", " + TrimAll(vAccommodationObj.GuestGroup), EventLogEntryTransactionMode.Independent);
			vAccommodationObj.pmClearSalesForecastRegisterRecords();
		Else
			// Post to forecast sales
			vAccommodationObj.pmPostToForecastSales(False);
			// Build value table of accommodation periods taking new movements into account
			vAllPeriods = vAccommodationObj.pmGetAccommodationPeriods(True);
			// Post to business block forecast sales
			If ValueIsFilled(vAccommodationObj.AccommodationStatus) And vAccommodationObj.AccommodationStatus.IsActive And vAccommodationObj.AccommodationStatus.IsInHouse Then
				If ValueIsFilled(vAccommodationObj.RoomQuota) And vAccommodationObj.RoomQuota.AllotmentBusinessType = Enums.AllotmentBusinessTypes.BusinessBlock Then
					If vAccommodationObj.RoomQuota.AllotmentType = Enums.AllotmentTypes.Definite Or 
					   vAccommodationObj.RoomQuota.AllotmentType = Enums.AllotmentTypes.DefiniteNotGuaranteed Or
					   vAccommodationObj.RoomQuota.AllotmentType = Enums.AllotmentTypes.Tentative Then
						vAccommodationObj.pmPostToBusinessBlockForecastSales(vAllPeriods);
					EndIf;
				EndIf;
			EndIf;
			// Write service forecast records
			vAccommodationObj.RegisterRecords.SalesForecast.Write();
		EndIf;
	EndDo;
	// Run query to get resource reservations to process
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	ResourceReservationServices.Ref AS Ref
	|FROM
	|	Document.ResourceReservation.Services AS ResourceReservationServices
	|WHERE
	|	ResourceReservationServices.Ref.Posted
	|	AND ResourceReservationServices.AccountingDate <= &qAccountingDate
	|	AND ResourceReservationServices.AccountingDate > &qAccountingDatePrevMonth
	|	AND ISNULL(ResourceReservationServices.Ref.ResourceReservationStatus.IsActive, FALSE)
	|	AND NOT ISNULL(ResourceReservationServices.Ref.ResourceReservationStatus.ServicesAreDelivered, TRUE)
	|	AND ISNULL(ResourceReservationServices.Ref.Hotel.CloseOfPeriodDoChargeServices, FALSE)" +
		?(ValueIsFilled(Hotel), " AND ResourceReservationServices.Ref.Hotel IN HIERARCHY(&qHotel)", "") + 
		?(ValueIsFilled(Company), " AND ResourceReservationServices.Ref.Company IN HIERARCHY(&qCompany)", "") + "
	|ORDER BY
	|	ResourceReservationServices.Ref.PointInTime";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qAccountingDate", BegOfDay(Date) + 24*3600);
	vQry.SetParameter("qAccountingDatePrevMonth", AddMonth(BegOfDay(Date) + 24*3600, -1));
	vQryRes = vQry.Execute().Unload();
	For Each vQryResRow In vQryRes Do
		vResourceReservationObj = vQryResRow.Ref.GetObject();
		vResourceReservationObj.AdditionalProperties.Insert("CloseOfDayMode", True);
		vResourceReservationObj.AdditionalProperties.Insert("AccountingDate", BegOfDay(Date) + 24*3600);
		// Log accommodation reposting
		WriteLogEvent(NStr("en='CloseOfPeriod.DoEveryDayCharges';ru='ЗакрытиеПериода.НачислениеУслуг';de='CloseOfPeriod.Berechnungsdienste'"), EventLogLevel.Information, vResourceReservationObj.Metadata(), vResourceReservationObj.Ref, "Start: " + TrimAll(vResourceReservationObj.Resource) + ", " + TrimAll(vResourceReservationObj.GuestGroup), EventLogEntryTransactionMode.Independent);
		// Do charging
		vResourceReservationObj.Write(DocumentWriteMode.Posting);
	EndDo;
	// Log number of reposted accommodations
	WriteLogEvent(NStr("en='CloseOfPeriod.DoEveryDayCharges';ru='ЗакрытиеПериода.НачислениеУслуг';de='CloseOfPeriod.Berechnungsdienste'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='Reposted are ';ru='Перепроведено ';de='Reposting '") + vQryRes.Count() + NStr("en=' accommodations';ru=' размещений';de=' in-house Gaste'"), EventLogEntryTransactionMode.Independent);
EndProcedure // CreateChargesForTheClosedDay

// -----------------------------------------------------------------------------
Procedure CloseOrphanFolios(pIsPosted = False)
	// Do processing if document is not posted only
	If pIsPosted Then
		Return;
	EndIf;
	// Log start of closing orphan folios
	WriteLogEvent(NStr("en='CloseOfPeriod.CloseOrphanFolios';ru='ЗакрытиеПериода.ЗакрытиеПросроченныхЛицевыхСчетов';de='CloseOfPeriod.CloseOrphanFolios'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='Start of closing orphan folios...';ru='Начата операция закрытия лицевых счетов с пустым документом основанием...';de='Schließen von Personenkonten mit leerem Begründungdokument wurde gestartet…'"), EventLogEntryTransactionMode.Independent);
	// Run query to get folios to process
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Folio.Ref AS Folio
	|FROM
	|	Document.Folio AS Folio
	|WHERE
	|	NOT Folio.IsClosed
	|	AND NOT Folio.DeletionMark
	|	AND NOT Folio.IsMaster
	|	AND Folio.DateTimeTo <> &qEmptyDate
	|	AND Folio.DateTimeTo <= &qPeriodTo
	|	AND (ISNULL(Folio.ParentDoc.DeletionMark, TRUE) 
	|			OR NOT Folio.ParentDoc.Date IS NULL
	|				AND Folio.DateTimeTo <= &qPrevAccountingPeriodTo
	|				AND &qPrevAccountingPeriodTo < &qPeriodTo)" + 
		?(ValueIsFilled(Hotel), " AND Folio.Hotel IN HIERARCHY(&qHotel)", "") + 
		?(ValueIsFilled(Company), " AND Folio.Company IN HIERARCHY(&qCompany)", "");
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qPeriodTo", Date);
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	// If folio parent doc is filled but folio check-out date is in the previous accounting period then close it
	vQry.SetParameter("qPrevAccountingPeriodTo", '00010101');
	If ValueIsFilled(Company) Then
		If Not ValueIsFilled(Company.TaxAccountingPeriodType) Or 
		   Company.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.Month Or 
		   Company.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.None Then
			If Company.CloseMonthAtDayBeforeTheLastMonthDay Then
				If EndOfDay(Date) = (EndOfMonth(Date) - 24*3600) Then
					vQry.SetParameter("qPrevAccountingPeriodTo", (BegOfMonth(Date) - 1 - 24*3600));
				EndIf;
			Else
				If EndOfDay(Date) = EndOfMonth(Date) Then
					vQry.SetParameter("qPrevAccountingPeriodTo", (BegOfMonth(Date) - 1));
				EndIf;
			EndIf;
		ElsIf Company.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.Quarter Then
			If EndOfDay(Date) = EndOfQuarter(Date) Then
				vQry.SetParameter("qPrevAccountingPeriodTo", (BegOfQuarter(Date) - 1));
			EndIf;
		ElsIf Company.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.HalfYear Then
			If Month(Date) >= 7 Then
				If EndOfDay(Date) = EndOfYear(Date) Then
					vQry.SetParameter("qPrevAccountingPeriodTo", AddMonth((BegOfYear(Date) - 1), 6));
				EndIf;
			Else
				If EndOfDay(Date) = AddMonth((BegOfYear(Date) - 1), 6) Then
					vQry.SetParameter("qPrevAccountingPeriodTo", (BegOfYear(Date) - 1));
				EndIf;
			EndIf;
		ElsIf Company.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.Year Then
			If EndOfDay(Date) = EndOfYear(Date) Then
				vQry.SetParameter("qPrevAccountingPeriodTo", (BegOfYear(Date) - 1));
			EndIf;
		ElsIf Company.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.Decade Then
			vDay = Day(Date);
			If vDay = 10 Then
				If Company.CloseMonthAtDayBeforeTheLastMonthDay Then
					vQry.SetParameter("qPrevAccountingPeriodTo", (BegOfMonth(Date) - 1 - 24*3600));
				Else
					vQry.SetParameter("qPrevAccountingPeriodTo", (BegOfMonth(Date) - 1));
				EndIf;
			ElsIf vDay = 20 Then 
				vQry.SetParameter("qPrevAccountingPeriodTo", (BegOfMonth(Date) + 11*24*3600 - 1));
			Else
				If Company.CloseMonthAtDayBeforeTheLastMonthDay Then
					If vDay = Day(EndOfMonth(Date) - 24*3600) Then
						vQry.SetParameter("qPrevAccountingPeriodTo", (BegOfMonth(Date) + 21*24*3600 - 1));
					EndIf;
				Else
					If vDay = Day(EndOfMonth(Date)) Then
						vQry.SetParameter("qPrevAccountingPeriodTo", (BegOfMonth(Date) + 21*24*3600 - 1));
					EndIf;
				EndIf;
			EndIf;
		EndIf;		
	EndIf;
	vQryRes = vQry.Execute().Unload();
	For Each vQryResRow In vQryRes Do
		vFolioObj = vQryResRow.Folio.GetObject();
		// Check folio balance
		If vFolioObj.pmGetBalance(, Hotel) <> 0 Then
			Continue;
		EndIf;
		// Check hotel edit prohibited date
		vHotelObj = Undefined;
		vSavEditProhibitedDate = Undefined;
		If ValueIsFilled(vFolioObj.Hotel) And ValueIsFilled(vFolioObj.DateTimeTo) And 
		   BegOfDay(vFolioObj.Hotel.EditProhibitedDate) >= BegOfDay(vFolioObj.DateTimeTo) Then
			vHotelObj = vFolioObj.Hotel.GetObject();
			vSavEditProhibitedDate = vHotelObj.EditProhibitedDate;
			vHotelObj.EditProhibitedDate = '00010101';
			vHotelObj.Write();
		EndIf;
		vFolioObj.IsClosed = True;
		If TypeOf(vFolioObj.ParentDoc) = Type("DocumentRef.Accommodation") And cmIsBrokenRef("Document.Accommodation", vFolioObj.ParentDoc) Then
			vFolioObj.ParentDoc = Undefined;
		ElsIf TypeOf(vFolioObj.ParentDoc) = Type("DocumentRef.Reservation") And cmIsBrokenRef("Document.Reservation", vFolioObj.ParentDoc) Then
			vFolioObj.ParentDoc = Undefined;
		ElsIf TypeOf(vFolioObj.ParentDoc) = Type("DocumentRef.ResourceReservation") And cmIsBrokenRef("Document.ResourceReservation", vFolioObj.ParentDoc) Then
			vFolioObj.ParentDoc = Undefined;
		EndIf;
		vFolioObj.Write(DocumentWriteMode.Write);
		If vHotelObj <> Undefined And vSavEditProhibitedDate <> Undefined Then
			vHotelObj.EditProhibitedDate = vSavEditProhibitedDate;
			vHotelObj.Write();
		EndIf;
		// Log close of folio
		WriteLogEvent(NStr("en='CloseOfPeriod.CloseOrphanFolios';ru='ЗакрытиеПериода.ЗакрытиеПросроченныхЛицевыхСчетов';de='CloseOfPeriod.CloseOrphanFolios'"), EventLogLevel.Information, Metadata(), vFolioObj.Ref, TrimAll(Ref), EventLogEntryTransactionMode.Independent);
	EndDo;
	// Log number of closed of folios
	WriteLogEvent(NStr("en='CloseOfPeriod.CloseOrphanFolios';ru='ЗакрытиеПериода.ЗакрытиеПросроченныхЛицевыхСчетов';de='CloseOfPeriod.CloseOrphanFolios'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='Closed are ';ru='Закрыто ';de='Geschlossen '") + vQryRes.Count() + NStr("en=' folios';ru=' лицевых счетов';de=' persönlicher Konten'"), EventLogEntryTransactionMode.Independent);
EndProcedure // CloseOrphanFolios

// -----------------------------------------------------------------------------
Procedure CloseServiceRegistration()
	WriteLogEvent(NStr("en='CloseOfPeriod.CloseServiceRegistration';ru='ЗакрытиеПериода.ОбнулениеБалансаПоФактическиОказаннымУслугам';de='CloseOfPeriod.CloseServiceRegistration'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='Start of fixing registered services balances...';ru='Начата операция обнуления балансов по фактически оказанным услугам...';de='Die Nullung von Bilanzen nach tatsächlich erbrachten Dienstleistungen wurde gestartet…'"), EventLogEntryTransactionMode.Independent);
	// Run query to get balances
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ServiceRegistrationBalance.Hotel AS Hotel,
	|	ServiceRegistrationBalance.BoardPlace AS BoardPlace,
	|	ServiceRegistrationBalance.GuestGroup AS GuestGroup,
	|	ServiceRegistrationBalance.Room AS Room,
	|	ServiceRegistrationBalance.Resource AS Resource,
	|	ServiceRegistrationBalance.Client AS Client,
	|	ServiceRegistrationBalance.FolioCurrency AS FolioCurrency,
	|	ServiceRegistrationBalance.Folio AS Folio,
	|	ServiceRegistrationBalance.AccountingDate AS AccountingDate,
	|	ServiceRegistrationBalance.Service AS Service,
	|	ServiceRegistrationBalance.SumBalance AS SumBalance,
	|	ServiceRegistrationBalance.QuantityBalance AS QuantityBalance
	|FROM
	|	AccumulationRegister.ServiceRegistration.Balance(
	|			&qPeriod,
	|			Hotel = &qHotel
	|				OR &qHotelIsEmpty) AS ServiceRegistrationBalance";
	vQry.SetParameter("qPeriod", New Boundary(Date, BoundaryType.Excluding));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vServiceRegistrationBalances = vQry.Execute().Unload();
	// Process balances
	If vServiceRegistrationBalances.Count() > 0 Then
		For Each vSRBRow In vServiceRegistrationBalances Do
			Movement = RegisterRecords.ServiceRegistration.Add();
			
			Movement.RecordType = AccumulationRecordType.Receipt;
			Movement.Period = Date;
			
			// Fill properties
			FillPropertyValues(Movement, vSRBRow);
			
			// Resources
			Movement.Sum = -vSRBRow.SumBalance;
			Movement.Quantity = -vSRBRow.QuantityBalance;
		EndDo;
		
		// Write movements
		RegisterRecords.ServiceRegistration.Write();
	EndIf;
	WriteLogEvent(NStr("en='CloseOfPeriod.CloseServiceRegistration';ru='ЗакрытиеПериода.ОбнулениеБалансаПоФактическиОказаннымУслугам';de='CloseOfPeriod.CloseServiceRegistration'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='Number of fixed charges is ';ru='Обнулены балансы по начислениям в количестве ';de='Bilanzen zu Anrechnungen in Höhe von genullt: '") + vServiceRegistrationBalances.Count(), EventLogEntryTransactionMode.Independent);
EndProcedure // CloseServiceRegistration

// -----------------------------------------------------------------------------
Procedure ArchivePreauthorisations(pIsPosted = False)
	// Do processing if document is not posted only
	If pIsPosted Then
		Return;
	EndIf;
	WriteLogEvent(NStr("en='CloseOfPeriod.ArchivePreauthorisations';ru='ЗакрытиеПериода.АрхивацияПреавторизаций';de='CloseOfPeriod.ArchivePreauthorisations'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='Start of preauthorisation archiving...';ru='Начата операция архивации преавторизаций...';de='Die Archivierung von Vorautorisierungen wurde gestartet…'"), EventLogEntryTransactionMode.Independent);
	// Run query to get preauthorisations based on closed folios
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Preauthorisation.Ref,
	|	Preauthorisation.Folio,
	|	Preauthorisation.GuestGroup
	|FROM
	|	Document.Preauthorisation AS Preauthorisation
	|WHERE
	|	Preauthorisation.Posted
	|	AND Preauthorisation.Date <= &qPeriod
	|	AND Preauthorisation.Folio.IsClosed
	|	AND Preauthorisation.Status = &qAuthorised
	|	AND (Preauthorisation.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|ORDER BY
	|	Preauthorisation.Date";
	vQry.SetParameter("qPeriod", Date);
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qAuthorised", Enums.PreauthorisationStatuses.Authorised);
	vPrs = vQry.Execute().Unload();
	// Process preauthorisations
	If vPrs.Count() > 0 Then
		For Each vPrsRow In vPrs Do
			vOpnCount = 0;
			If ValueIsFilled(vPrsRow.GuestGroup) Then
				// Check if all folios of current guest group are closed
				vOpnCount = GetOpenFoliosCountForGuestGroup(vPrsRow.GuestGroup);
			EndIf;
			If vOpnCount = 0 Then
				vPrsObj = vPrsRow.Ref.GetObject();
				vPrsObj.Status = Enums.PreauthorisationStatuses.Archived;
				vPrsObj.Write(DocumentWriteMode.Posting);
			EndIf;
		EndDo;
	EndIf;
	WriteLogEvent(NStr("en='CloseOfPeriod.ArchivePreauthorisations';ru='ЗакрытиеПериода.АрхивацияПреавторизаций';de='CloseOfPeriod.ArchivePreauthorisations'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='Number of archived preauthorisations is ';ru='Изменен статус у преавторизаций в количестве ';de='Status der Vorautorisierungen geändert in der Zahl: '") + vPrs.Count(), EventLogEntryTransactionMode.Independent);
EndProcedure // ArchivePreauthorisations

// -----------------------------------------------------------------------------
Procedure CloseCashRegisterFolioBalances(pIsPosted = False)
	// Log start of fixing payment section folio balances
	WriteLogEvent(NStr("en='CloseOfPeriod.FixPaymentSectionFolioBalances';ru='ЗакрытиеПериода.ОбнулениеБалансовЛицевыхСчетовПоКассовымСекциям';de='CloseOfPeriod.FixPaymentSectionFolioBalances'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='Start of fixing payment section balances for closed zeroed folios...';ru='Начата операция обнуления балансов по кассовым секциям у закрытых лицевых счетов с общим нулевым балансом...';de='Die Nullung von Bilanzen nach Kassensektionen bei geschlossenen Personenkonten mit allgemeiner Nullbilanz wurde gestartet…'"), EventLogEntryTransactionMode.Independent);
	// Get payment section balances for closed folios with zero total balance
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	FoliosWithBalances.Folio,
	|	FoliosWithBalances.SumBalance
	|INTO FoliosWithBalances
	|FROM
	|	AccumulationRegister.Accounts.Balance(
	|			,
	|			Folio.IsClosed
	|				AND (Folio.Company = &qCompany
	|					OR &qCompanyIsEmpty)
	|				AND (Hotel = &qHotel
	|					OR &qHotelIsEmpty)) AS FoliosWithBalances
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccountsBalance.Hotel,
	|	AccountsBalance.Folio,
	|	AccountsBalance.FolioCurrency,
	|	AccountsBalance.PaymentSection,
	|	AccountsBalance.PaymentSection.ChequeItemType AS ChequeItemType,
	|	AccountsBalance.ChequeService,
	|	AccountsBalance.ChequeServicePrice,
	|	AccountsBalance.SumBalance,
	|	AccountsBalance.ChequeServiceQuantityBalance
	|FROM
	|	AccumulationRegister.Accounts.Balance(
	|			,
	|			Folio.IsClosed
	|				AND (Folio.Company = &qCompany
	|					OR &qCompanyIsEmpty)
	|				AND (Hotel = &qHotel
	|					OR &qHotelIsEmpty)) AS AccountsBalance
	|WHERE
	|	NOT AccountsBalance.Folio IN
	|				(SELECT
	|					FoliosWithBalances.Folio
	|				FROM
	|					FoliosWithBalances AS FoliosWithBalances)";
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vFolios = vQry.Execute().Unload();
	// Process each record received
	vFoliosToSkip = New ValueList();
	For Each vFoliosRow In vFolios Do
		If vFoliosRow.ChequeItemType = Enums.ChequeItemTypes.Payment Then
			If vFoliosToSkip.FindByValue(vFoliosRow.Folio) = Undefined Then
				vFoliosToSkip.Add(vFoliosRow.Folio);
			EndIf;
		EndIf;
	EndDo;
	For Each vFoliosRow In vFolios Do
		If vFoliosToSkip.FindByValue(vFoliosRow.Folio) <> Undefined Then
			Continue;
		EndIf;
		
		Movement = RegisterRecords.Accounts.Add();
		
		Movement.RecordType = AccumulationRecordType.Expense;
		Movement.Period = Date;
		
		// Fill properties
		FillPropertyValues(Movement, vFoliosRow);
		
		// Resources
		Movement.Sum = vFoliosRow.SumBalance;
		Movement.ChequeServiceQuantity = vFoliosRow.ChequeServiceQuantityBalance;
		
		// Attributes
		If ValueIsFilled(Movement.PaymentSection) Then
			Movement.VATRate = Movement.PaymentSection.VATRate;
		ElsIf ValueIsFilled(Movement.Hotel) And ValueIsFilled(Movement.Hotel.Company) Then
			Movement.VATRate = Movement.Hotel.Company.VATRate;
		EndIf;
	EndDo;
	If vFolios.Count() > 0 Then
		// Write movements
		RegisterRecords.Accounts.Write();
	EndIf;
	// Log end of fixing folio payment section balances
	WriteLogEvent(NStr("en='CloseOfPeriod.FixPaymentSectionFolioBalances';ru='ЗакрытиеПериода.ОбнулениеБалансовЛицевыхСчетовПоКассовымСекциям';de='CloseOfPeriod.FixPaymentSectionFolioBalances'"), EventLogLevel.Information, Metadata(), Ref, NStr("en='Payment section balances fixed: ';ru='Обнулено строк балансов: ';de='Bilanzzeilen genullt: '") + vFolios.Count(), EventLogEntryTransactionMode.Independent);
EndProcedure // CloseCashRegisterFolioBalances

// -----------------------------------------------------------------------------
Procedure RepostClosedDayInPriceCharges(pIsPosted = False)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Charges.Ref AS Ref
	|INTO ChargesToBeReposted
	|FROM
	|	Document.Charge AS Charges
	|WHERE
	|	Charges.Date = &qDate
	|	AND (Charges.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (Charges.Company = &qCompany
	|			OR &qCompanyIsEmpty)
	|	AND Charges.IsInPrice
	|	AND Charges.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentsToBeReposted.Ref AS Ref,
	|	DocumentsToBeReposted.Priority AS Priority,
	|	DocumentsToBeReposted.Ref.PointInTime AS RefPointInTime
	|FROM
	|	(SELECT
	|		ChargesToBeReposted.Ref AS Ref,
	|		0 AS Priority
	|	FROM
	|		ChargesToBeReposted AS ChargesToBeReposted
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Stornos.Ref,
	|		1
	|	FROM
	|		Document.Storno AS Stornos
	|			INNER JOIN ChargesToBeReposted AS ChargesToBeReposted
	|			ON Stornos.ParentCharge = ChargesToBeReposted.Ref
	|				AND (Stornos.Posted)) AS DocumentsToBeReposted
	|
	|ORDER BY
	|	Priority,
	|	RefPointInTime";
	vQry.SetParameter("qDate", BegOfDay(Date));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qCompanyIsEmpty", Not ValueIsFilled(Company));
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vDocObj = vQryRes.Ref.GetObject();
		vDocObj.Write(DocumentWriteMode.Posting);
	EndDo;
EndProcedure // RepostClosedDayInPriceCharges

// -----------------------------------------------------------------------------
Procedure CreateAndPostInvoice(pDimensionsRow, pAccountingCustomer, pAccountingContract, pAccountingCurrency, 
                               pLanguage, pCharges, pIsCorrection = False, pProcessClosedFoliosOnly)
	// Create an invoice						   
	vInvoiceObj = Documents.Settlement.CreateDocument();
	
	// Fill invoice attributes
	vInvoiceObj.Date = Date;
	vInvoiceObj.Author = SessionParameters.CurrentUser;
	vInvoiceObj.Hotel = pDimensionsRow.Hotel;
	vInvoiceObj.ParentDoc = pDimensionsRow.SeparateAccommodation;
	vInvoiceObj.Company = pDimensionsRow.Company;
	vInvoiceObj.SetNewNumber();
	vInvoiceObj.AccountingCustomer = pAccountingCustomer;
	vInvoiceObj.AccountingContract = pAccountingContract;
	vInvoiceObj.GuestGroup = pDimensionsRow.GuestGroup;
	vInvoiceObj.AccountingCurrency = pAccountingCurrency;
	vInvoiceObj.HotelProductParent = pDimensionsRow.HotelProductParent;
	vInvoiceObj.Remarks = ?(pProcessClosedFoliosOnly, NStr("en='Checked-out'; ru='Выезд'; de='Abreise'"), "");
	vInvoiceObj.Remarks = vInvoiceObj.Remarks + ?(ValueIsFilled(pDimensionsRow.SeparateService)," "+pDimensionsRow.SeparateService,"");
	If pIsCorrection Then
		vInvoiceObj.Remarks = vInvoiceObj.Remarks + ?(Not IsBlankString(vInvoiceObj.Remarks), ", ", "") + NStr("en='Correction';ru='Корректировка';de='Korrektur'");
	ElsIf ValueIsFilled(pDimensionsRow.Event) Then
		vInvoiceObj.Remarks = vInvoiceObj.Remarks + ?(Not IsBlankString(vInvoiceObj.Remarks), ", ", "") + NStr("en='Event: ';ru='Мероприятие: ';de='Veranstaltung: '") + TrimAll(pDimensionsRow.Event.Description);
	EndIf;
	vInvoiceObj.InvoiceNumber = "";
	vInvoiceObj.CloseOfPeriod = Ref;
	vInvoiceObj.PaymentMethod = Catalogs.PaymentMethods.Settlement;
	// Export to the accounting system flag
	If ValueIsFilled(pDimensionsRow.SeparateService) AND TypeOf(pDimensionsRow.SeparateService) = Type("CatalogRef.Services") Then
		If pDimensionsRow.SeparateService.DoNotExportToTheAccountingSystem Then
			vInvoiceObj.DoNotExportToTheAccountingSystem = True;
		EndIf;
	EndIf;
	// Do not export to the accounting system
	If ValueIsFilled(vInvoiceObj.AccountingCustomer) Then
		If vInvoiceObj.AccountingCustomer.DoNotExportToTheAccountingSystem Then
			vInvoiceObj.DoNotExportToTheAccountingSystem = vInvoiceObj.AccountingCustomer.DoNotExportToTheAccountingSystem;
		EndIf;
	EndIf;
	// Is checked if payments generate invoices mode
	If ValueIsFilled(vInvoiceObj.Hotel) And vInvoiceObj.Hotel.PaymentsGenerateInvoices Then
		vInvoiceObj.IsChecked = True;
	EndIf;
	
	// Fill invoice transactions
	vInvoiceObj.pmFillServices(pCharges, pLanguage);
	If SplitSettllementsByVATRate And vInvoiceObj.Services.Count() > 0 Then
		v1SrvRow = vInvoiceObj.Services.Get(0);
		vInvoiceObj.VATRate = v1SrvRow.VATRate;
	EndIf;		
	If SplitSettllementsByPaymentSections And vInvoiceObj.Services.Count() > 0 Then
		v1SrvRow = vInvoiceObj.Services.Get(0);
		If ValueIsFilled(v1SrvRow.Service) Then
			vInvoiceObj.PaymentSection = v1SrvRow.Service.PaymentSection;
		EndIf;
	EndIf;		
	
	// Fill invoice totals
	vInvoiceSum = 0;
	vInvoiceVATSum = 0;
	vInvoiceCommissionSum = 0;
	For Each vSrvRow In vInvoiceObj.Services Do
		vInvoiceSum = vInvoiceSum + cmConvertCurrencies(vSrvRow.Sum, vSrvRow.FolioCurrency, , vInvoiceObj.AccountingCurrency, , vInvoiceObj.Date, vInvoiceObj.Hotel);
		vInvoiceVATSum = vInvoiceVATSum + cmConvertCurrencies(vSrvRow.VATSum, vSrvRow.FolioCurrency, , vInvoiceObj.AccountingCurrency, , vInvoiceObj.Date, vInvoiceObj.Hotel);
		vInvoiceCommissionSum = vInvoiceCommissionSum + cmConvertCurrencies(vSrvRow.CommissionSum, vSrvRow.FolioCurrency, , vInvoiceObj.AccountingCurrency, , vInvoiceObj.Date, vInvoiceObj.Hotel);
	EndDo;
	vInvoiceObj.Sum = Round(vInvoiceSum, 2);
	vInvoiceObj.VATSum = Round(vInvoiceVATSum, 2);
	vInvoiceObj.CommissionSum = Round(vInvoiceCommissionSum, 2);
	
	// Fill list of payments
	If ValueIsFilled(vInvoiceObj.AccountingCustomer) And ValueIsFilled(vInvoiceObj.Hotel) And vInvoiceObj.Sum <> 0 Then
		vInvoiceObj.pmFillListOfPayments();
	EndIf;
	
	// Write and post invoice
	If vInvoiceObj.Services.Count() > 0 Then
		vInvoiceObj.Write(DocumentWriteMode.Posting);
	EndIf;
EndProcedure // CreateAndPostInvoice 

// -----------------------------------------------------------------------------
Procedure CreateAndPostCorrectionNote(pDimensionsRow, pAccountingCustomer, pAccountingContract, pAccountingCurrency, 
                                      pLanguage, pCharges, pInvoice, pProcessClosedFoliosOnly, pChargesSign)
	// Create correction note
	If pChargesSign < 0 Then
		vCorrectionObj = Documents.CreditNote.CreateDocument();
	Else
		vCorrectionObj = Documents.DebitNote.CreateDocument();
	EndIf;
	
	// Fill correction document attributes
	vCorrectionObj.Date = Date;
	vCorrectionObj.Author = SessionParameters.CurrentUser;
	vCorrectionObj.Hotel = pDimensionsRow.Hotel;
	vCorrectionObj.Company = pDimensionsRow.Company;
	vCorrectionObj.SetNewNumber();
	vCorrectionObj.AccountingCustomer = pAccountingCustomer;
	vCorrectionObj.AccountingContract = pAccountingContract;
	vCorrectionObj.GuestGroup = pDimensionsRow.GuestGroup;
	vCorrectionObj.AccountingCurrency = pAccountingCurrency;
	vCorrectionObj.Remarks = ?(ValueIsFilled(pDimensionsRow.SeparateService), TrimAll(pDimensionsRow.SeparateService), "");
	If ValueIsFilled(pDimensionsRow.Event) Then
		vCorrectionObj.Remarks = vCorrectionObj.Remarks + ?(Not IsBlankString(vCorrectionObj.Remarks), ", ", "") + NStr("en='Event: ';ru='Мероприятие: ';de='Veranstaltung: '") + TrimAll(pDimensionsRow.Event.Description);
	EndIf;
	vCorrectionObj.Invoice = pInvoice;
	vCorrectionObj.CloseOfPeriod = Ref;
	vCorrectionObj.PaymentMethod = Catalogs.PaymentMethods.Settlement;
	// Export to the accounting system flag
	If ValueIsFilled(pDimensionsRow.SeparateService) AND TypeOf(pDimensionsRow.SeparateService) = Type("CatalogRef.Services") Then
		If pDimensionsRow.SeparateService.DoNotExportToTheAccountingSystem Then
			vCorrectionObj.DoNotExportToTheAccountingSystem = True;
		EndIf;
	EndIf;
	// Do not export to the accounting system
	If ValueIsFilled(vCorrectionObj.AccountingCustomer) Then
		If vCorrectionObj.AccountingCustomer.DoNotExportToTheAccountingSystem Then
			vCorrectionObj.DoNotExportToTheAccountingSystem = vCorrectionObj.AccountingCustomer.DoNotExportToTheAccountingSystem;
		EndIf;
	EndIf;
	// Is checked if payments generate invoices mode
	If ValueIsFilled(vCorrectionObj.Hotel) And vCorrectionObj.Hotel.PaymentsGenerateInvoices Then
		vCorrectionObj.IsChecked = True;
	EndIf;
	
	// Fill correction transactions
	vCorrectionObj.pmFillServices(pCharges, pLanguage);
	If vCorrectionObj.Services.Count() > 0 Then
		v1SrvRow = vCorrectionObj.Services.Get(0);
		vCorrectionObj.VATRate = v1SrvRow.VATRate;
	EndIf;		
	If SplitSettllementsByPaymentSections And vCorrectionObj.Services.Count() > 0 Then
		v1SrvRow = vCorrectionObj.Services.Get(0);
		If ValueIsFilled(v1SrvRow.Service) Then
			vCorrectionObj.PaymentSection = v1SrvRow.Service.PaymentSection;
		EndIf;
	EndIf;		
	
	// Fill correction totals
	vInvoiceSum = 0;
	vCorrectionSum = 0;
	vCorrectionVATSum = 0;
	vCorrectionObj.pmFillCorrectionTotals(vInvoiceSum, vCorrectionSum, vCorrectionVATSum);
	
	// Fill table of invoices with 1 row for the given invoice
	vCorrectionObj.Invoices.Clear();
	vInvoicesRow = vCorrectionObj.Invoices.Add();
	vInvoicesRow.Invoice = pInvoice;
	vInvoicesRow.InvoiceSum = vInvoiceSum;
	vInvoicesRow.CorrectionSum = vCorrectionSum;
	vInvoicesRow.CorrectionVATSum = vCorrectionVATSum;
	If TypeOf(vCorrectionObj) = Type("DocumentObject.CreditNote") Then
		vInvoicesRow.Sum = vInvoicesRow.InvoiceSum - vInvoicesRow.CorrectionSum;
	Else
		vInvoicesRow.Sum = vInvoicesRow.InvoiceSum + vInvoicesRow.CorrectionSum;
	Endif;
	If Not ValueIsFilled(vCorrectionObj.VATRate) And ValueIsFilled(vCorrectionObj.Company) Then
		vCorrectionObj.VATRate = vCorrectionObj.Company.VATRate;
	EndIf;
	// Post correction
	If vCorrectionObj.Services.Count() > 0 Then
		vCorrectionObj.Write(DocumentWriteMode.Posting);
	EndIf;
EndProcedure // CreateAndPostCorrectionNote 

// -----------------------------------------------------------------------------
Procedure UpdateVATRateIfChanged()
	SetPrivilegedMode(True);
	vDate = BegOfDay(EndOfDay(Date) + 1);
	If BegOfDay(CurrentSessionDate()) = vDate Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	VATRatesHistorySliceLast.VATRate AS VATRate,
		|	VATRatesHistorySliceLast.TaxRate AS TaxRate,
		|	VATRatesHistorySliceLast.TaxGroup AS TaxGroup,
		|	VATRatesHistorySliceLast.NoVAT AS NoVAT,
		|	VATRatesHistorySliceLast.Description AS Description
		|FROM
		|	InformationRegister.VATRatesHistory.SliceLast(&qPeriod, ) AS VATRatesHistorySliceLast
		|WHERE
		|	NOT VATRatesHistorySliceLast.VATRate.DeletionMark
		|	AND NOT VATRatesHistorySliceLast.TaxRate IS NULL
		|	AND NOT VATRatesHistorySliceLast.VATRate.TaxRate IS NULL
		|	AND (VATRatesHistorySliceLast.VATRate.TaxRate <> VATRatesHistorySliceLast.TaxRate
		|			OR VATRatesHistorySliceLast.VATRate.TaxGroup <> VATRatesHistorySliceLast.TaxGroup
		|				AND VATRatesHistorySliceLast.TaxGroup <> 0
		|			OR VATRatesHistorySliceLast.VATRate.NoVAT <> VATRatesHistorySliceLast.NoVAT
		|			OR VATRatesHistorySliceLast.VATRate.Description <> VATRatesHistorySliceLast.Description
		|				AND VATRatesHistorySliceLast.Description <> """")";
		vQry.SetParameter("qPeriod", vDate);
		vVATRates = vQry.Execute().Unload();
		For Each vVATRatesRow In vVATRates Do
			If cmIsNumber(vVATRatesRow.TaxRate) Then
				vVATRateObj = vVATRatesRow.VATRate.GetObject();
				vVATRateObj.TaxRate = vVATRatesRow.TaxRate;
				vVATRateObj.NoVAT = vVATRatesRow.NoVAT;
				If vVATRatesRow.TaxGroup <> 0 Then
					vVATRateObj.TaxGroup = vVATRatesRow.TaxGroup;
				EndIf;
				If Not IsBlankString(vVATRatesRow.Description) Then
					vVATRateObj.Description = vVATRatesRow.Description;
				EndIf;
				vVATRateObj.Write();
			EndIf;
		EndDo;
	EndIf;
	SetPrivilegedMode(False);
EndProcedure // UpdateVATRateIfChanged

// -----------------------------------------------------------------------------
Procedure UpdateCompanyVATRateIfChanged()
	SetPrivilegedMode(True);
	vDate = BegOfDay(EndOfDay(Date) + 1);
	If BegOfDay(CurrentSessionDate()) = vDate Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	CompanyVATRateHistorySliceLast.Company AS Company,
		|	CompanyVATRateHistorySliceLast.VATRate AS VATRate,
		|	CompanyVATRateHistorySliceLast.IsUsingSimpleTaxSystem AS IsUsingSimpleTaxSystem
		|FROM
		|	InformationRegister.CompanyVATRateHistory.SliceLast(
		|			&qPeriod,
		|			Company.Hotel = &qHotel
		|				OR Company.Hotel = VALUE(Catalog.Hotels.EmptyRef)
		|				OR &qHotel = VALUE(Catalog.Hotels.EmptyRef)) AS CompanyVATRateHistorySliceLast
		|WHERE
		|	NOT CompanyVATRateHistorySliceLast.Company.DeletionMark
		|	AND NOT CompanyVATRateHistorySliceLast.VATRate IS NULL
		|	AND (CompanyVATRateHistorySliceLast.Company.VATRate <> CompanyVATRateHistorySliceLast.VATRate
		|				AND CompanyVATRateHistorySliceLast.VATRate <> VALUE(Catalog.VATRAtes.EmptyRef)
		|			OR CompanyVATRateHistorySliceLast.Company.IsUsingSimpleTaxSystem <> CompanyVATRateHistorySliceLast.IsUsingSimpleTaxSystem)";
		vQry.SetParameter("qPeriod", vDate);
		vQry.SetParameter("qHotel", Hotel);
		vVATRates = vQry.Execute().Unload();
		For Each vVATRatesRow In vVATRates Do
			If ValueIsFilled(vVATRatesRow.Company) Then
				vCompanyObj = vVATRatesRow.Company.GetObject();
				If ValueIsFilled(vVATRatesRow.VATRate) Then
					vCompanyObj.VATRate = vVATRatesRow.VATRate;
				EndIf;
				vCompanyObj.IsUsingSimpleTaxSystem = vVATRatesRow.IsUsingSimpleTaxSystem;
				vCompanyObj.Write();
			EndIf;
		EndDo;
	EndIf;
	SetPrivilegedMode(False);
EndProcedure // UpdateCompanyVATRateIfChanged

// -----------------------------------------------------------------------------
Procedure UpdatePaymentSectionVATRateIfChanged()
	SetPrivilegedMode(True);
	vDate = BegOfDay(EndOfDay(Date) + 1);
	If BegOfDay(CurrentSessionDate()) = vDate Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	PaymentSectionVATRateHistorySliceLast.PaymentSection AS PaymentSection,
		|	PaymentSectionVATRateHistorySliceLast.VATRate AS VATRate
		|FROM
		|	InformationRegister.PaymentSectionVATRateHistory.SliceLast(
		|			&qPeriod,
		|			PaymentSection.Hotel = &qHotel
		|				OR PaymentSection.Hotel = VALUE(Catalog.Hotels.EmptyRef)
		|				OR &qHotel = VALUE(Catalog.Hotels.EmptyRef)) AS PaymentSectionVATRateHistorySliceLast
		|WHERE
		|	NOT PaymentSectionVATRateHistorySliceLast.PaymentSection.DeletionMark
		|	AND NOT PaymentSectionVATRateHistorySliceLast.VATRate IS NULL
		|	AND PaymentSectionVATRateHistorySliceLast.PaymentSection.VATRate <> PaymentSectionVATRateHistorySliceLast.VATRate
		|	AND PaymentSectionVATRateHistorySliceLast.VATRate <> VALUE(Catalog.VATRates.EmptyRef)";
		vQry.SetParameter("qPeriod", vDate);
		vQry.SetParameter("qHotel", Hotel);
		vVATRates = vQry.Execute().Unload();
		For Each vVATRatesRow In vVATRates Do
			If ValueIsFilled(vVATRatesRow.PaymentSection) Then
				vPaymentSectionObj = vVATRatesRow.PaymentSection.GetObject();
				If ValueIsFilled(vVATRatesRow.VATRate) Then
					vPaymentSectionObj.VATRate = vVATRatesRow.VATRate;
				EndIf;
				vPaymentSectionObj.Write();
			EndIf;
		EndDo;
	EndIf;
	SetPrivilegedMode(False);
EndProcedure // UpdatePaymentSectionVATRateIfChanged

// -----------------------------------------------------------------------------
Procedure CheckNoVATVATRate()
	vNoVATVATRate = cmGetNoVATVATRate();
	If Not ValueIsFilled(vNoVATVATRate) Then
		cmCreateNoVATVATRate();
	EndIf;
EndProcedure // CheckNoVATVATRate

#EndRegion
	