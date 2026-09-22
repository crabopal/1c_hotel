
#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pFrmWithChanges	 - Form	 - Form for open
// 
// Returns:
//  Boolean - Result update
//
Function pmDoInfobaseUpdate(pFrmWithChanges = Undefined) Export  
	// Set current version BEFORE conversion routines will run to allow users 
	// start working before end of conversion took place (we assume that there 
	// won't be any exclusive and critical conversion routines in the future. 
	// At least it is so far...
	
	// At least it is so far ended in September 2023 
	
	// If need to run up without ExclusiveMode, then before run update set this session parameter(SessionParameters.UpdateInProgress = True) in True  
	tcProtection.StartApplication("InfoBaseUpdate");

	LockDB();
	
	// Old version date
	vOldVersion = cmGetProgramVersionAsDateString();
	vSpreadsheetDocument = New SpreadsheetDocument;
	vMinDate = '00010101';   
	
	vLogMsg = StrTemplate(NStr("en = 'Old: %1 -> New: %2'; de = 'Old: %1 -> New: %2'; ru = 'Предыдущая: %1 -> Текущая: %2'"), vOldVersion, Metadata.Version);
	WriteLogEvent(cmNStr("en='Version.Number'; ru='Версия.Номер'; de='Version.Number'"), EventLogLevel.Note, , , vLogMsg);
	
	// Save and clear hotel and company edit prohibited dates
	vEditProhibitedDates = SaveProhibitedDates();
	
	ExecuteUpdateHandlers(vOldVersion, vMinDate);

	FillDescriptionUpdate(vOldVersion, vSpreadsheetDocument);

	// Restore edit prohibited dates
	RestoreProhibitedDates(vEditProhibitedDates);
	
	// Open form Description Update
	#If Client Then
		If vSpreadsheetDocument.TableHeight > 0 Then
			vFrm = GetForm("DescriptionUpdate");
			vFrm.TemplateDescriptionUpdate = vSpreadsheetDocument;
			pFrmWithChanges = vFrm;
		EndIf;
	#EndIf
	
	// Return info base update status 
	If TrimAll(Metadata.Version) <> TrimAll(Constants.ProgramVersionNumber.Get()) Then
		Constants.PreviousProgramVersionNumber.Set(Constants.ProgramVersionNumber.Get());
	EndIf;
	
	Constants.ProgramVersionNumber.Set(Metadata.Version);
	
	// Unlock IB
	UnlockDB();
	
	// Submit procedure that will convert the rest of calendar days
	If ValueIsFilled(vMinDate) Then
		vParams = New Array();
		vParams.Add('00010101');
		vParams.Add(vMinDate);                     
		vBJDesc = NStr("en = 'Convert history calendar data'; de = 'Konvertierung des Kalenderverlaufs'; ru = 'Конверсия истории календарей'");
		vBJ = BackgroundJobs.Execute("ProlongedOperations.ConvertCalendarsData", vParams, , vBJDesc); 
	EndIf;

	Return True;
EndFunction  // pmDoInfobaseUpdate()

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure LockDB()
	If SessionParameters.UpdateInProgress = False Then
		SessionParameters.UpdateInProgress = True;
		Try      
			// Cancel background jobs                                                                             
			vBJList = BackgroundJobs.GetBackgroundJobs(New Structure("State", BackgroundJobState.Active));  
			If vBJList.Count() > 0 Then
				vInt = 1;
				While vInt < 4 Do 
					For Each vBJ In vBJList Do
						vBJ.Cancel();
					EndDo;    
					cmWait(2); 
					vBJList = BackgroundJobs.GetBackgroundJobs(New Structure("State", BackgroundJobState.Active));  
					If vBJList.Count() > 0 Then
						vInt = vInt + 1;
					Else
						Break;
					EndIf;
				EndDo;
            EndIf;
			If Not ExclusiveMode() Then  
				If Metadata.CompatibilityMode = Metadata.ObjectProperties.CompatibilityMode.DontUse And Left(cmGetPlatformVersion(True), 7) = "8.3.18." 
					Or Metadata.CompatibilityMode = Metadata.ObjectProperties.CompatibilityMode.Version8_3_18 Then
					SetExclusiveMode(True);   
				Else
					vCodeToRun = "vIBParams = New ExclusiveModeParameters;
					|vIBParams.Message = Nstr(""en = 'The information base is being updated, logging into the application is prohibited!'; de = 'Die Informationsbasis wird aktualisiert, das Einloggen in die Anwendung ist verboten!'; ru = 'Выполняется обновление информационной базы, вход в приложение запрещен!'"");
					|vIBParams.AllowTerminationAtSessionStart = False; 
					|SetExclusiveMode(True, vIBParams);";
					Execute(vCodeToRun);
				EndIf;
			EndIf;	
		Except
			vErr = ErrorInfo();  
			vMsg = NStr("en = 'It is impossible to update the infobase:
			|- Unable to set exclusive mode
			|- The configuration version does not provide for updating without setting exclusive mode
			|
			|Error details:
			|%1'; 
			|de = 'Es ist nicht möglich, die Infobase zu aktualisieren:
			|- Exklusiver Modus kann nicht eingestellt werden
			|- Die Konfigurationsversion sieht keine Aktualisierung ohne Einstellung des Exklusivmodus vor
			|
			|Fehlerdetails:
			|%1'; 
			|ru = 'Невозможно выполнить обновление информационной базы:
			|- Невозможно установить монопольный режим
			|- Версия конфигурации не предусматривает обновление без установки монопольного режима
			|
			|Подробности ошибки:
			|%1'");
			vMsg = StrTemplate(vMsg, BriefErrorDescription(vErr));
			Raise vMsg;
		EndTry;  
	EndIf;
EndProcedure // LockDB()

// -----------------------------------------------------------------------------
Procedure UnlockDB()
	If SessionParameters.UpdateInProgress = True Then
		SessionParameters.UpdateInProgress = False;
		
		If ExclusiveMode() Then
			While TransactionActive() Do
				RollbackTransaction();  
			EndDo;
			
			SetExclusiveMode(False);
		EndIf;
	EndIf;
EndProcedure // UnlockDB()

// -----------------------------------------------------------------------------
Procedure RestoreProhibitedDates(pEditProhibitedDates)
	For Each vEditProhibitedDatesRow In pEditProhibitedDates Do
		If ValueIsFilled(vEditProhibitedDatesRow.Item) And ValueIsFilled(vEditProhibitedDatesRow.EditProhibitedDate) Then
			vItemObj = vEditProhibitedDatesRow.Item.GetObject();
			vItemObj.EditProhibitedDate = vEditProhibitedDatesRow.EditProhibitedDate;
			If TypeOf(vItemObj) = Type("CatalogObject.Hotels") Then
				vItemObj.AccountingDate = vEditProhibitedDatesRow.AccountingDate;
			EndIf;
			vItemObj.Write();
		EndIf;
	EndDo;
EndProcedure // RestoreProhibitedDates()

// -----------------------------------------------------------------------------
// 
// Returns:
//  ValueTable - Table whith prohibited date
//
Function SaveProhibitedDates()
	vEditProhibitedDates = New ValueTable();
	vEditProhibitedDates.Columns.Add("Item");
	vEditProhibitedDates.Columns.Add("EditProhibitedDate", cmGetDateTypeDescription());
	vEditProhibitedDates.Columns.Add("AccountingDate", cmGetDateTypeDescription());
	vHotels = cmGetAllHotels();
	For Each vHotelsRow In vHotels Do
		If ValueIsFilled(vHotelsRow.Hotel.EditProhibitedDate) Then
			vEditProhibitedDatesRow = vEditProhibitedDates.Add();
			vEditProhibitedDatesRow.Item = vHotelsRow.Hotel;
			vEditProhibitedDatesRow.EditProhibitedDate = vHotelsRow.Hotel.EditProhibitedDate;
			vEditProhibitedDatesRow.AccountingDate = vHotelsRow.Hotel.AccountingDate;
			// Clear date
			vItemObj = vHotelsRow.Hotel.GetObject();
			vItemObj.EditProhibitedDate = '00010101';
			vItemObj.AccountingDate = '00010101';
			vItemObj.Write();
		EndIf;
	EndDo;
	vCompanies = cmGetAllCompanies();
	For Each vCompaniesRow In vCompanies Do
		If ValueIsFilled(vCompaniesRow.Company.EditProhibitedDate) Then
			vEditProhibitedDatesRow = vEditProhibitedDates.Add();
			vEditProhibitedDatesRow.Item = vCompaniesRow.Company;
			vEditProhibitedDatesRow.EditProhibitedDate = vCompaniesRow.Company.EditProhibitedDate;
			vEditProhibitedDatesRow.AccountingDate = '00010101';
			// Clear date
			vItemObj = vCompaniesRow.Company.GetObject();
			vItemObj.EditProhibitedDate = '00010101';
			vItemObj.Write();
		EndIf;
	EndDo;
	Return vEditProhibitedDates;
EndFunction // SaveProhibitedDates()

// -----------------------------------------------------------------------------
Procedure FillDescriptionUpdate(pOldVersion,  pSpreadsheetDocument)
	vTemplate = GetTemplate("DescriptionUpdate");

	// Put update description
	If pOldVersion < "150624" Then
		PutDescriptionUpdate("150624", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "150810" Then
		PutDescriptionUpdate("150810", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "150915" Then
		PutDescriptionUpdate("150915", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "150920" Then
		PutDescriptionUpdate("150920", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "160114" Then
		PutDescriptionUpdate("160114", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "160418" Then
		PutDescriptionUpdate("160418", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "160628" Then
		PutDescriptionUpdate("160628", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "160809" Then
		PutDescriptionUpdate("160809", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "161019" Then
		PutDescriptionUpdate("161019", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "170228" Then
		PutDescriptionUpdate("170228", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "170331" Then
		PutDescriptionUpdate("170331", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "170425" Then
		PutDescriptionUpdate("170425", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "170915" Then
		PutDescriptionUpdate("170915", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "171103" Then
		PutDescriptionUpdate("171103", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "180205" Then
		PutDescriptionUpdate("180205", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "180305" Then
		PutDescriptionUpdate("180305", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "180418" Then
		PutDescriptionUpdate("180418", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "180612" Then
		PutDescriptionUpdate("180612", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "180919" Then
		PutDescriptionUpdate("180919", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "181130" Then
		PutDescriptionUpdate("181130", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "190206" Then
		PutDescriptionUpdate("190206", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "190426" Then
		PutDescriptionUpdate("190426", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "190716" Then
		PutDescriptionUpdate("190716", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "190801" Then
		PutDescriptionUpdate("190801", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "191121" Then
		PutDescriptionUpdate("191121", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "200421" Then
		PutDescriptionUpdate("200421", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "200601" Then
		PutDescriptionUpdate("200601", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "200917" Then
		FillRelationTypeExtCodes();
		PutDescriptionUpdate("200917", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "201007" Then
		PutDescriptionUpdate("201007", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "201025" Then
		PutDescriptionUpdate("201025", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "201126" Then
		PutDescriptionUpdate("201126", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "201221" Then
		PutDescriptionUpdate("201221", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "210206" Then
		PutDescriptionUpdate("210206", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "210309" Then
		PutDescriptionUpdate("210309", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "210423" Then
		PutDescriptionUpdate("210423", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "210622" Then
		PutDescriptionUpdate("210622", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "211004" Then
		PutDescriptionUpdate("211004", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "211203" Then
		PutDescriptionUpdate("211203", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "220209" Then
		PutDescriptionUpdate("220209", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "220516" Then
		PutDescriptionUpdate("220516", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "220712" Then
		PutDescriptionUpdate("220712", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "220818" Then
		PutDescriptionUpdate("220818", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "221004" Then
		PutDescriptionUpdate("221004", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "221027" Then
		PutDescriptionUpdate("221027", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "230111" Then
		PutDescriptionUpdate("230111", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "230125" Then
		PutDescriptionUpdate("230125", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "230201" Then
		PutDescriptionUpdate("230201", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "230405" Then
		PutDescriptionUpdate("230405", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "230425" Then
		PutDescriptionUpdate("230425", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "230526" Then
		PutDescriptionUpdate("230526", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "231129" Then
		PutDescriptionUpdate("231129", pSpreadsheetDocument, vTemplate);
	EndIf;
	If pOldVersion < "240112" Then
		PutDescriptionUpdate("240112", pSpreadsheetDocument, vTemplate);   
	EndIf; 
	If pOldVersion < "240131" Then
		PutDescriptionUpdate("240131", pSpreadsheetDocument, vTemplate);   
	EndIf;
EndProcedure // FillDescriptionUpdate

// -----------------------------------------------------------------------------
Procedure ExecuteUpdateHandlers(Val vOldVersion, pMinDate = '00010101')
	// First of all convert permission rules
	If vOldVersion < "090922" Then
		Fill103106UserPermissions();
	EndIf;
	If vOldVersion < "091111" Then
		Fill107UserPermissions();
	EndIf;
	If vOldVersion < "100202" Then
		Fill109111UserPermissions();
	EndIf;
	If vOldVersion < "100215" Then
		Fill112UserPermission();
	EndIf;
	If vOldVersion < "100413" Then
		Fill095099112UserPermissions();
		Fill113UserPermission();
	EndIf;
	If vOldVersion < "100928" Then
		Fill032033UserPermissions();
	EndIf;
	If vOldVersion < "101026" Then
		Fill116UserPermission();
	EndIf;
	If vOldVersion < "101102" Then
		Fill117UserPermission();
	EndIf;
	If vOldVersion < "111026" Then
		Fill119UserPermission();
	EndIf;
	If vOldVersion < "120325" Then
		Fill121122UserPermission();
	EndIf;
	If vOldVersion < "120418" Then
		Fill124UserPermission();
	EndIf;
	If vOldVersion < "121016" Then
		Fill126UserPermission();
	EndIf;
	If vOldVersion < "121123" Then
		Fill127UserPermission();
		Fill128UserPermission();
		Fill129UserPermission();
	EndIf;
	If vOldVersion < "121129" Then
		Fill130UserPermission();
	EndIf;
	If vOldVersion < "140312" Then
		Fill131UserPermission();
	EndIf;
	If vOldVersion < "150212" Then
		Fill133UserPermission();
		Fill134UserPermission();
	EndIf;
	If vOldVersion < "150615" Then
		Fill135UserPermission();
	EndIf;
	// Call conversion routines
	If vOldVersion < "090209" Then
		FillDefaultDurationCalculationRuleType();
	EndIf;
	If vOldVersion < "090812" Then
		// It is also could be ignored
		FillGuestGroupParameters();
	EndIf;
	If vOldVersion < "091027" Then
		FillCorrectRUBCode();
	EndIf;
	If vOldVersion < "091111" Then
		// Those are recommended but could be postponed or ignored
		RepostActiveReservations();
		RepostInHouseAccommodations();
	EndIf;
	If vOldVersion < "091126" Then
		FillAuditReportsSettings();
	EndIf;
	If vOldVersion < "091201" Then
		FillCustomerOperationalBalancesObjectPrintingForm();
	EndIf;
	If vOldVersion >= "091111" And vOldVersion < "091215" Then
		// This is recommended but could be postponed or ignored
		RepostActiveReservations();
	EndIf;
	If vOldVersion < "091216" Then
		FillCustomerSalesForecastReportSettings();
	EndIf;
	If vOldVersion < "091223" Then
		FillIssuedHotelProductsReportSettings();
	EndIf;
	If vOldVersion < "100202" Then
		FixAccommodationTypes();
	EndIf;
	If vOldVersion < "100209" Then
		FixPaymentMethods();
	EndIf;
	If vOldVersion < "100215" Then
		FillReleaseExpiredRoomAllotmentsDataProcessorSettings();
	EndIf;
	If vOldVersion < "100323" Then
		FillSendGuestGroupNotificationsDataProcessorSettings();
	EndIf;
	If vOldVersion < "100329" Then
		FillCheckReservationWaitingListProcessingSettings();
	EndIf;
	If vOldVersion < "100503" Then
		FillChangedAccommodationsReportSettings();
		FillOccupancyForecastReportSettings();
	EndIf;
	If vOldVersion < "100608" Then
		// This is highly recommended but could be postponed
		FillReservationGuestFullNames();
	EndIf;
	If vOldVersion < "100611" Then
		FillCustomerGuestsPercentsReportSettings();
	EndIf;
	If vOldVersion < "100623" Then
		FillCheckCustomerServicesReportSettings();
	EndIf;
	If vOldVersion < "100624" Then
		FillCopyGuestGroupReservationsObjectFormAction();
		// This is highly recommended but could be postponed
		FillAccommodationGuestFullNames();
		// Repost active reservations
		RepostActiveReservationsInOneRun();
	EndIf;
	If vOldVersion < "100928" Then
		// Repost all payments, returns and customer payments
		RepostPayments();
		RepostReturns();
		RepostCustomerPayments();
		// Repost close of cash register days
		RepostCloseOfCashRegisterDays();
	EndIf;
	If vOldVersion < "101004" Then
		// Fill expected check-in ordered by rooms report settings
		FillExpectedCheckInOrderedByRoomsReportSettings();
		// Fill print group rooms reservation printing form settings
		FillReservationPrintGuestGroupRoomsObjectPrintingFormSetings();
		// Fill safety system events audit report settings
		FillSafetySystemEventsAuditReportSettings();
	EndIf;
	If vOldVersion < "101026" Then
		// Fill print coupons object form actions parameters
		FillPrintCouponsActionSetings();
	EndIf;
	If vOldVersion < "101102" Then
		// Fill client item form action settings
		FillClientObjectFormActionsSettings();
		// Fill client item print form settings
		FillClientObjectPrintFormsSettings();
	EndIf;
	If vOldVersion < "101119" Then
		// Fill changed icons
		FillCheckInCheckOutActionPictures();
		// Fill permission group parameter
		FillAllowedAnnulationDelayTime();
	EndIf;
	If vOldVersion < "101221" Then
		// Clear hotel from charging rule template folios
		ClearHotelFromChargingRuleTemplateFolios();
	EndIf;
	If vOldVersion < "101223" Then
		// Fill new customer guests turnovers report settings
		FillCustomerGuestsTurnoversReportSettings();
	EndIf;
	If vOldVersion < "101224" Then
		FillCheckCustomerGuestsReportSettings();
	EndIf;
	If vOldVersion < "110221" Then
		FillCustomerInitialBalancesActionSettings();
		FillCustomerGuestsWithServicesReportSettings();
		FillLostProfitsReportSettings();
	EndIf;
	If vOldVersion < "110407" Then
		FillIdentificationCardsAuditReportSettings();
	EndIf;
	If vOldVersion < "110420" Then
		FillHotelProductsRegisterReportSettings();
	EndIf;
	If vOldVersion < "110518" Then
		FillReservationCheckInGuestGroupObjectFormActionSettings();
		FillCheckIfReservationsWerePayedInTimeDataProcessorSettings();
	EndIf;
	If vOldVersion < "110604" Then
		FillClientHideNameAndNameHistoryActionSettings();
		FillFolioPrintHotelProductObjectPrintFormsSettings();
	EndIf;
	If vOldVersion < "110615" Then
		ConvertReports();
		FillIssueHotelProductsPrintHotelProductsLogPrintFormSettings();
		FillExpectedGuestGroupsReportSettings();
		FillReservationsNoShowReportSettings();
		FillForeignerRegistryRecordPrintForeignerCardFormObjectPrintFormsSettings();
		FillFolioPrint3GFormObjectPrintFormsSettings();
		FillAgeRanges();
		FillClientsAgeRegionAndCity();
		FillCustomersDoNotPostCommission();
		vFoundHotelProductServices = FillIsHotelProductServiceAttribute();
		FillServiceCommissionAttributes();
		RepostActiveReservations();
		RepostChargesAndStorno(BegOfMonth(BegOfMonth(CurrentSessionDate()) - 1), '39991231');
		RepostChargesAndStorno(BegOfYear(CurrentSessionDate()), '39991231');
		RepostChargesAndStorno('00010101', '39991231');
		If vFoundHotelProductServices Then
			RepostSettlements();
		EndIf;
	EndIf;
	If vOldVersion < "111021" Then
		FillInvoicePrintPaymentOrderObjectPrintFormsSettings();
	EndIf;
	If vOldVersion < "111112" Then
		FillReservationAnnulationsReportSettings();
	EndIf;
	If vOldVersion < "120325" Then
		FillClientScanClientDataActionSettings();
	EndIf;
	If vOldVersion < "120418" Then
		FillCustomerAdvanceDistributionActionSettings();
		FillContractAdvanceDistributionActionSettings();
		FillFolioPrintChargePrintFormsSettings();
	EndIf;
	If vOldVersion < "120515" Then
		FillAccommodationFillInvoiceActionSettings();
		FillGuestsWithBirthDayReportSettings();
	EndIf;
	If vOldVersion < "120525" Then
		FillActiveReservationsSortCode();
		FillInHouseAccommodationsSortCode();
	EndIf;
	If vOldVersion < "121016" Then
		FillSMSDeliveryPrintReceiversObjectPrintFormsSettings();
		FillSMSDeliveryObjectFormActionSettingsFolder();
		FillSMSBeingSentReportSettings();
		Constants.SMSGateway.Set(Enums.SupportedSMSGateways.SMS1CHOTEL);
	EndIf;
	If vOldVersion < "121123" Then
		FillAccommodationPrintArrivalSheetFormObjectPrintingFormSetings();
	EndIf;
	If vOldVersion < "130508" Then
		FillFolioGiftCertificatesActionSettings();
		FillActiveGiftCertificatesReportSettings();
		ChangeNorweqVisionConnectionType();
	EndIf;
	If vOldVersion < "130920" Then
		FillDoNightAuditPrecheckDataProcessorSettings();
	EndIf;
	If vOldVersion < "131206" Then
		FillServicePackageRecordsInformationRegister();
	EndIf;
	If vOldVersion < "131225" Then
		FillReservationPrintGuestFormObjectPrintFormsSettings();
	EndIf;
	If vOldVersion < "140312" Then
		// This is mandatory
		RepostInHouseAccommodations();
		SimpleRepostActiveReservations();
	EndIf;
	If vOldVersion < "140319" Then
		FillGermanPrintingFormsSettings();
	EndIf;
	If vOldVersion < "140415" Then
		ChangeGiftCertificatesReportSettings();
	EndIf;
	If vOldVersion < "140530" Then
		FillReservationExpressCheckInInvitationPrintFormsSettings();
		FixCountriesDescription();
	EndIf;
	If vOldVersion < "140605" Then
		FillFMSCodes();
	EndIf;
	If vOldVersion < "140818" Then
		FillAccommodationMakeIdentificationCardFormActionSetings();
	EndIf;
	If vOldVersion < "140926" Then
		If IsBlankString(Constants.DadataToken.Get()) Then
			Constants.DadataToken.Set("39d56491dac45396522f98c4958f0c16ab61152b");
		EndIf;
		// Update UMMS catalogs
		Catalogs.IdentityDocumentTypes.mmLoadFromDictionary();
		Catalogs.TripPurposes.mmLoadFromDictionary();
		Catalogs.VisaTypes.mmLoadFromDictionary();
		Catalogs.EntryGoals.mmLoadFromDictionary();
		Catalogs.CheckPoints.mmClear();
		Catalogs.CheckPoints.mmLoadFromDictionary();
	EndIf;
	If vOldVersion < "141212" Then
		// Update country phone code for RUSSIA
		vRURef = Catalogs.Countries.FindByCode(643);
		If ValueIsFilled(vRURef) Then
			vRUObj = vRURef.GetObject();
			vRUObj.CountryPhoneCode = 7;
			vRUObj.Write();
		EndIf;
	EndIf;
	If vOldVersion < "150428" Then
		FillEmployeeActionsAuditReportSettings();
	EndIf;
	If vOldVersion < "150810" Then
		FillCustomerSendInvitationToNewAgentActionSettings();
		FillContractSendInvitationToNewAgentActionSettings();
	EndIf;
	If vOldVersion < "160418" Then
		FixAnaliticalReportsSettings();
	EndIf;
	If vOldVersion < "160530" Then
		FillCustomersIsIndividual();
		FixCountriesDescription();
	EndIf;
	If vOldVersion < "160809" Then
		FillAccommodationSendWelcomeSMSActionSetings();
		FillResourceReservationSendWelcomeSMSActionSetings();
		FillChatBotResources();
		FillNoCitizenshipVirtualCountryParams();
	EndIf;
	If vOldVersion < "161019" Then
		FillForeignerRegistryRecordPrintAllClientDataScansObjectPrintingFormSetings();
		FillCashRegisterPrintDeviceCurrentStateOfCalculationsReportActionSettings();
		FillReservationSendWelcomeSMSActionSetings();
	EndIf;
	If vOldVersion < "170425" Then
		FillChatBotResources();
	EndIf;
	If vOldVersion < "170915" Then
		UpdateCashRegisterDriverTypes();
		InitializeOrdersSubsystem();
		RenameWubookSettings();
	EndIf;
	If vOldVersion < "171031" Then
		FillFolioPrintNonFiscalChequeByCharges();
	EndIf;
	If vOldVersion < "171103" Then
		FillInvoiceByEventObjectFormActions();
		ConvertAttributeNameInReports("OccupancyForecast", "IsConfirmedBlock", "IsCommitment");
		ConvertAttributeNameInReports("RoomSalesTurnovers", "IsConfirmedBlock", "IsCommitment");
		ConvertAttributeNameInReports("<EXTERNAL>", "IsConfirmedBlock", "IsCommitment");
		FillOrderActionSetings();
		Documents.Order.InitializeOrdersSubsystem();
	EndIf;
	If vOldVersion < "180205" Then
		ChangeWuBookWSHost();
	EndIf;
	If vOldVersion < "180305" Then
		FillSettlementObjectPrintingFormsForPrintingInvoice();
		FillCustomerAndContractOpenInvoicesListObjectFormActions();
	EndIf;
	If vOldVersion < "180612" Then
		FillFolioPrintPKOByPayment();
		FillPersonalDataProcessingSettings();
		FillCurrencyConversionSettings();
		FillFanIDSettings();
		FillAccommodationFillClientFeedbackActionSetings();
		FillCustomerFillCreditAndDebitNotesObjectFormActions();
		FillAccommodationPrintGuestPersonalDataProcessingConsentObjectPrintingFormSettings();
		FillAccommodationPrintGuestRefusalToPayResortFeeObjectPrintingFormSettings();
		UpdateAccommodationDocumentNumbers();
	EndIf;
	If vOldVersion < "180919" Then
		Catalogs.CheckPoints.mmLoadFromDictionary();
	EndIf;
	If vOldVersion < "181130" Then
		FillVATRateTaxRatesHistory();
	EndIf;
	If vOldVersion < "190801" Then
		FillAccommodationTemplateAndNumberOfPersons();
		FillRestaurantControlListReportSettings();
		SwitchOffAutoCorrectionsOption();
		FillForeignerRegistryRecordPrintDepartureNotificationPrintingFormSetings();
	EndIf;
	If vOldVersion < "200421" Then
		FillLoyaltyType();
		FillGiftCertificatesSalesTurnoversReportSettings();
	EndIf; 
	If vOldVersion < "201025" Then
		FillFMSCodes();
	EndIf;
	If vOldVersion < "201126" Then
		TurnOnLegalRepresentativeFunctionalOption();
		RepostMessages();
	EndIf; 
	If vOldVersion < "210423" Then
		FillHotelForAccommodationTemplateRoomTypes();
	EndIf;
	If vOldVersion < "210622" Then
		ClearZeroSharePercentInDocuments();
		FillDebitAndCreditNoteObjectPrintingForm();
	EndIf;
	If vOldVersion < "211004" Then
		Fill143144UserPermissions();
		FillNegativeCorrectionSumInCreditNotes();
	EndIf;
	If vOldVersion < "211203" Then
		Fill146UserPermissions();
		FillIsNotInvoicedServiceFlag();
		FillSendPaymentLinkSMSFromProformaInvoice();
	EndIf;
	If vOldVersion < "220209" Then
		FillRosstatForm1MainIndicatorsReportSettings();
	EndIf;
	If vOldVersion < "220516" Then
		FillDuplicateClientsSearchReportSettings();
		// It could be ignored
		FillGuestGroupParameters();
	EndIf;
	If vOldVersion < "220712" Then
		ConvertRoomRateFormulas();
	EndIf;
	If vOldVersion < "221004" Then
		ResaveServicePackages();
		FillAccommodationPrintGuestDepartureObjectPrintingForm();
		AddUSSRCountry();
	EndIf;
	If vOldVersion < "221027" Then
		FillVoucherShipmentType();
	EndIf;
	If vOldVersion < "230111" Then
		If SessionParameters.CurrentLanguage = Catalogs.Languages.RU Then
			// Update UMMS catalog
			Try
				Catalogs.TripPurposes.mmLoadFromDictionary();
			Except
			EndTry;
		EndIf;
	EndIf;
	If vOldVersion < "230201" Then
		FillOrderTypesCatalogTypeAttribute();
		FillTimeForPriceCalculationDate();
		pMinDate = ConvertCalendarsData();
		ConvertDataProcessorsFlagIsSystem();
		FillConnectedDevicesInfoRegisterFromObjectAttributes();
		UpdateServicePackagesValidityPeriod();
		FillDirectPostingsPrintChargedTransactionsObjectPrintingFormSettings();
		FillMessagesObjectPrintingFormSetings();
	EndIf;
	If vOldVersion < "230405" Then
		FillReservationRichTextPrintFormsSettings();
	EndIf;
	If vOldVersion < "231129" Then
		FillHotelFillProformaInvoiceMode();
	EndIf;
	If vOldVersion < "240112" Then
		SetRosstatReportsDynamicParameters();
	EndIf;    
	If vOldVersion < "240131" Then
		FillHexWithColor();		
	EndIf;
	If vOldVersion < "240325" Then
		Catalogs.ResortFeeExemptionReasons.FillResortFeeExemptionReasons();		
	EndIf;
	If vOldVersion < "241209" Then
		FillNoVATHistoryFlag();
		CreateTouristTaxBreakdownListFormulaRu();
	EndIf;
	If vOldVersion < "250131" Then
		Fill153154UserPermission();
		CreateAndFillBirthCertificateRecordingIDType();
		CreateTouristTaxDeclarationRuPrintForms();
		UpdateGuestlinkParameters();
	EndIf;
	If vOldVersion < "260209" Then
		CheckAndFixCalendarDays();
	EndIf;
EndProcedure // ExecuteUpdateHandlers

// -----------------------------------------------------------------------------
Procedure FillDefaultDurationCalculationRuleType()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomRates.Ref AS RoomRate
	|FROM
	|	Catalog.RoomRates AS RoomRates
	|WHERE
	|	(NOT RoomRates.DeletionMark)
	|	AND (NOT RoomRates.IsFolder)
	|	AND RoomRates.DurationCalculationRuleType NOT IN (&qList)";
	vList = New ValueList();
	vList.Add(Enums.DurationCalculationRuleTypes.ByDays);
	vList.Add(Enums.DurationCalculationRuleTypes.ByNights);
	vList.Add(Enums.DurationCalculationRuleTypes.ByReferenceHour);
	vList.Add(Enums.DurationCalculationRuleTypes.ByHours);
	vQry.SetParameter("qList", vList);
	vQryRes = vQry.Execute().Unload();
	For Each vQryRow In vQryRes Do
		vRoomRateObj = vQryRow.RoomRate.GetObject();
		vRoomRateObj.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour;
		vRoomRateObj.Write();
	EndDo;
EndProcedure // FillDefaultDurationCalculationRuleType

// -----------------------------------------------------------------------------
Procedure RepostActiveReservations()
#If Client Then 
	Status(NStr("en='Reposting active reservations...'; de='Reposting active reservations...'; ru='Перепроведение действующей брони...'"));
#EndIf
	// Run query to get active reservations
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservation.Ref AS Document,
	|	Reservation.Date AS Date,
	|	Reservation.PointInTime AS PointInTime
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.ReservationStatus.IsActive
	|	AND Reservation.Posted
	|
	|UNION ALL
	|
	|SELECT
	|	ResourceReservation.Ref,
	|	ResourceReservation.Date,
	|	ResourceReservation.PointInTime
	|FROM
	|	Document.ResourceReservation AS ResourceReservation
	|WHERE
	|	ResourceReservation.ResourceReservationStatus.IsActive
	|	AND (NOT ResourceReservation.ResourceReservationStatus.DoCharging)
	|	AND ResourceReservation.Posted
	|
	|ORDER BY
	|	PointInTime";
	vQryRes = vQry.Execute().Unload();
	vCurDate = '00010101';
	// Undo posting active reservations first
	For Each vQryResRow In vQryRes Do
		vCurDocObj = vQryResRow.Document.GetObject();
		Try
			vCurDocObj.Write(DocumentWriteMode.UndoPosting);
		Except
			tcCommonFunctionOnClientServer.TextMessage(String(vCurDocObj) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
		
		#If Client Then
			// Status message
			If BegOfDay(vQryResRow.Date) <> vCurDate Then
				vCurDate = BegOfDay(vQryResRow.Date);
				Status(NStr("en='Undo posting active reservations on " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'; 
							|de='Undo posting active reservations on " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'; 
							|ru='Отмена проведения действующей брони за " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'"));
			EndIf;
			UserInterruptProcessing();
		#EndIf
	EndDo;
	// Repost current reservations	
	vCurDate = '00010101';
	For Each vQryResRow In vQryRes Do
		vCurDocObj = vQryResRow.Document.GetObject();
		Try
			vCurDocObj.AdditionalProperties.Insert("InfoBaseUpdateMode", True);
			vCurDocObj.Write(DocumentWriteMode.Posting);
		Except
			tcCommonFunctionOnClientServer.TextMessage(String(vCurDocObj) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
		
		#If Client Then
			// Status message
			If BegOfDay(vQryResRow.Date) <> vCurDate Then
				vCurDate = BegOfDay(vQryResRow.Date);
				Status(NStr("en='Reposting active reservations on " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'; 
							|de='Reposting active reservations on " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'; 
							|ru='Перепроведение действующей брони за " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'"));
			EndIf;
			UserInterruptProcessing();
		#EndIf
	EndDo;
EndProcedure // RepostActiveReservations

// -----------------------------------------------------------------------------
Procedure RepostInHouseAccommodations()
	#If Client Then
		Status(NStr("en='Reposting in-house accommodations...'; de='Reposting in-house accommodations...'; ru='Перепроведение текущих размещений...'"));
	#EndIf
	// Run query to get in-house accommodations
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref AS Document,
	|	Accommodation.Date AS Date,
	|	Accommodation.PointInTime AS PointInTime
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.AccommodationStatus.IsInHouse
	|	AND Accommodation.Posted
	|
	|ORDER BY
	|	PointInTime";
	vQryRes = vQry.Execute().Select();
	vCurDate = '00010101';
	While vQryRes.Next() Do
		vCurDocObj = vQryRes.Document.GetObject();
		Try
			vCurDocObj.AdditionalProperties.Insert("InfoBaseUpdateMode", True);
			vCurDocObj.Write(DocumentWriteMode.Posting);
		Except
			tcCommonFunctionOnClientServer.TextMessage(String(vCurDocObj) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
		
		#If Client Then
			// Status message
			If BegOfDay(vQryRes.Date) <> vCurDate Then
				vCurDate = BegOfDay(vQryRes.Date);
				Status(NStr("en='Reposting in-house accommodations on " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'; 
						|de='Reposting in-house accommodations on " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'; 
						|ru='Перепроведение текущих размещений за " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'"));
			EndIf;
			UserInterruptProcessing();
		#EndIf
	EndDo;
EndProcedure // RepostInHouseAccommodations

// -----------------------------------------------------------------------------
Procedure FillServiceCommissionAttributes()
#If Client Then
	Status(NStr("en='Processing commissions in reservations and accommodations...'; de='Processing commissions in reservations and accommodations...'; ru='Обработка комиссий в брони и размещениях...'"));
#EndIf
	// Run query to get active reservations
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservation.Ref AS Document,
	|	Reservation.Date AS Date,
	|	Reservation.PointInTime AS PointInTime
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.Posted
	|
	|UNION ALL
	|
	|SELECT
	|	Accommodation.Ref,
	|	Accommodation.Date,
	|	Accommodation.PointInTime
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Posted
	|
	|ORDER BY
	|	PointInTime";
	vQryRes = vQry.Execute().Unload();
	vCurDate = '00010101';
	// Undo posting active reservations first
	For Each vQryResRow In vQryRes Do
		vCurDocObj = vQryResRow.Document.GetObject();
		For Each vSrvRow In vCurDocObj.Services Do
			vSrvRow.AgentCommissionType = vCurDocObj.AgentCommissionType;
			vSrvRow.AgentCommission = vCurDocObj.AgentCommission;
		EndDo;
		Try
			vCurDocObj.Write(DocumentWriteMode.Write);
		Except
			tcCommonFunctionOnClientServer.TextMessage(String(vCurDocObj) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
		
#If Client Then
		// Status message
		If BegOfDay(vQryResRow.Date) <> vCurDate Then
			vCurDate = BegOfDay(vQryResRow.Date);
			Status(NStr("en='Processing commissions in reservations and accommodations on " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'; 
			            |de='Processing commissions in reservations and accommodations on " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'; 
			            |ru='Обработка комиссий в брони и размещениях за " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'"));
		EndIf;
		UserInterruptProcessing();
#EndIf
	EndDo;
EndProcedure // FillServiceCommissionAttributes 

// -----------------------------------------------------------------------------
Procedure FillGuestGroupParameters()
#If Client Then
	Status(NStr("en='Filling guest group parameters...'; de='Filling guest group parameters...'; ru='Заполнение параметров групп гостей...'"));
#EndIf
	// Run query to get active reservations
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	GuestGroups.Ref AS GuestGroup
	|FROM
	|	Catalog.GuestGroups AS GuestGroups
	|WHERE
	|	NOT GuestGroups.DeletionMark
	|	AND NOT GuestGroups.IsFolder
	|	AND ISNULL(GuestGroups.Status.IsActive, FALSE)
	|	AND ISNULL(GuestGroups.Status.IsInHouse, TRUE)
	|
	|ORDER BY
	|	GuestGroups.Code";
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vGroupObj = vQryRes.GuestGroup.GetObject();
		Try
			vUpdateClient = False;
			If Not ValueIsFilled(vGroupObj.Client) Then
				vUpdateClient = True;
			EndIf;
			vUpdatePeriod = False;
			vUpdateGuestsCheckedIn = False;
			vGroupParams = cmGetGroupPeriodAndGuestsCheckedIn(vGroupObj.Ref);
			If vGroupParams.Count() > 0 Then
				vGroupParamsRow = vGroupParams.Get(0);
				If vGroupParamsRow.CheckInDate <> vGroupObj.CheckInDate Or
				   vGroupParamsRow.CheckOutDate <> vGroupObj.CheckOutDate Then
					vUpdatePeriod = True;
				EndIf;
				If vGroupParamsRow.GuestsCheckedIn <> vGroupObj.GuestsCheckedIn Or 
				   vGroupParamsRow.NumberOfAdults <> vGroupObj.NumberOfAdults Or 
				   vGroupParamsRow.NumberOfTeenagers <> vGroupObj.NumberOfTeenagers Or 
				   vGroupParamsRow.NumberOfChildren <> vGroupObj.NumberOfChildren Or 
				   vGroupParamsRow.NumberOfInfants <> vGroupObj.NumberOfInfants Then
					vUpdateGuestsCheckedIn = True;
				EndIf;
			EndIf;
			If vUpdateClient Then
				vClientDoc = Undefined;
				vGroupObj.Client = cmGetHeadOfGroupClient(vGroupObj.Ref, vGroupObj.Client, vClientDoc);
				vGroupObj.ClientDoc = vClientDoc;
			EndIf;
			If vUpdatePeriod Then
				vGroupObj.CheckInDate = vGroupParamsRow.CheckInDate;
				vGroupObj.CheckOutDate = vGroupParamsRow.CheckOutDate;
				If ValueIsFilled(SessionParameters.CurrentHotel) Then
					vGroupObj.Duration = cmCalculateDuration(SessionParameters.CurrentHotel.RoomRate, vGroupObj.CheckInDate, vGroupObj.CheckOutDate);
				EndIf;
			EndIf;
			If vUpdateGuestsCheckedIn Then
				vGroupObj.GuestsCheckedIn = vGroupParamsRow.GuestsCheckedIn;
				vGroupObj.NumberOfAdults = vGroupParamsRow.NumberOfAdults;
				vGroupObj.NumberOfTeenagers = vGroupParamsRow.NumberOfTeenagers;
				vGroupObj.NumberOfChildren = vGroupParamsRow.NumberOfChildren;
				vGroupObj.NumberOfInfants = vGroupParamsRow.NumberOfInfants;
			EndIf;
			vGroupObj.Write();
		Except
			tcCommonFunctionOnClientServer.TextMessage(TrimAll(vGroupObj.Code) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
		
#If Client Then
		// Status message
		Status(NStr("en='Guest group " + TrimAll(vGroupObj.Code) + " processed...'; 
		            |de='Guest group " + TrimAll(vGroupObj.Code) + " processed...'; 
					|ru='Обработана группа " + TrimAll(vGroupObj.Code) + "...'"));
		UserInterruptProcessing();
#EndIf
	EndDo;
EndProcedure // FillGuestGroupParameters

// -----------------------------------------------------------------------------
Procedure Fill032033UserPermissions()
	// Run query to get permission groups
	If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.PermissionGroup) Then
		Try
			vPGObj = SessionParameters.CurrentUser.PermissionGroup.GetObject();
			vPGObj.HavePermissionToStornoFolioCharges = True;
			vPGObj.HavePermissionToReturnPayments = True;
			vPGObj.Write();
		Except
			tcCommonFunctionOnClientServer.TextMessage(TrimAll(vPGObj.Description) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
	EndIf;
EndProcedure // Fill032033UserPermissions

// -----------------------------------------------------------------------------
Procedure Fill095099112UserPermissions()
	// Run query to get permission groups
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PermissionGroups.Ref AS Ref
	|FROM
	|	Catalog.PermissionGroups AS PermissionGroups
	|WHERE
	|	(NOT PermissionGroups.DeletionMark)
	|	AND (NOT PermissionGroups.IsFolder)
	|ORDER BY
	|	PermissionGroups.Code";
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vPGObj = vQryRes.Ref.GetObject();
		Try
			vPGObj.HavePermissionToPostPaymentsWithEmptyPaymentSections = True;
			vPGObj.HavePermissionToSkipInputOfClientType = True;
			vPGObj.HavePermissionToDoBookingWithoutRooms = True;
			vPGObj.Write();
		Except
			tcCommonFunctionOnClientServer.TextMessage(TrimAll(vPGObj.Description) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
	EndDo;
EndProcedure // Fill095099112UserPermissions

// -----------------------------------------------------------------------------
Procedure Fill103106UserPermissions()
	// Run query to get permission groups
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PermissionGroups.Ref AS Ref
	|FROM
	|	Catalog.PermissionGroups AS PermissionGroups
	|WHERE
	|	(NOT PermissionGroups.DeletionMark)
	|	AND (NOT PermissionGroups.IsFolder)
	|ORDER BY
	|	PermissionGroups.Code";
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vPGObj = vQryRes.Ref.GetObject();
		Try
			vPGObj.HavePermissionToSkipInputOfReservationTripPurpose = True;
			vPGObj.HavePermissionToSkipInputOfReservationMarketingCode = True;
			vPGObj.HavePermissionToSkipInputOfReservationSourceOfBusiness = True;
			vPGObj.HavePermissionToSeePricesDifferentFromRoomRackRates = True;
			vPGObj.Write();
		Except
			tcCommonFunctionOnClientServer.TextMessage(TrimAll(vPGObj.Description) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
	EndDo;
EndProcedure // Fill103106UserPermissions

// -----------------------------------------------------------------------------
Procedure Fill107UserPermissions()
	// Run query to get permission groups
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PermissionGroups.Ref AS Ref
	|FROM
	|	Catalog.PermissionGroups AS PermissionGroups
	|WHERE
	|	(NOT PermissionGroups.DeletionMark)
	|	AND (NOT PermissionGroups.IsFolder)
	|ORDER BY
	|	PermissionGroups.Code";
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vPGObj = vQryRes.Ref.GetObject();
		Try
			vPGObj.HavePermissionToManageReportColumns = True;
			vPGObj.FillDefaultRoomPolicy = Enums.FillDefaultRoomPolicies.NoDefaultRoom;
			vPGObj.Write();
		Except
			tcCommonFunctionOnClientServer.TextMessage(TrimAll(vPGObj.Description) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
	EndDo;
EndProcedure // Fill107UserPermissions

// -----------------------------------------------------------------------------
Procedure Fill109111UserPermissions()
	// Run query to get permission groups
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PermissionGroups.Ref AS Ref
	|FROM
	|	Catalog.PermissionGroups AS PermissionGroups
	|WHERE
	|	(NOT PermissionGroups.DeletionMark)
	|	AND (NOT PermissionGroups.IsFolder)
	|ORDER BY
	|	PermissionGroups.Code";
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vPGObj = vQryRes.Ref.GetObject();
		Try
			vPGObj.HavePermissionToDoRoomTypeUpgrade = True;
			vPGObj.HavePermissionToUseAnyRoomTypeForUpgrade = False;
			vPGObj.HavePermissionToSkipInputOfReservationContactPerson = True;
			vPGObj.Write();
		Except
			tcCommonFunctionOnClientServer.TextMessage(TrimAll(vPGObj.Description) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
	EndDo;
EndProcedure // Fill109111UserPermissions

// -----------------------------------------------------------------------------
Procedure Fill113UserPermission()
	// Run query to get permission groups
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PermissionGroups.Ref AS Ref
	|FROM
	|	Catalog.PermissionGroups AS PermissionGroups
	|WHERE
	|	(NOT PermissionGroups.DeletionMark)
	|	AND (NOT PermissionGroups.IsFolder)
	|ORDER BY
	|	PermissionGroups.Code";
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vPGObj = vQryRes.Ref.GetObject();
		Try
			If vPGObj.HavePermissionToManageRoomInventory Then
				vPGObj.HavePermissionToManageHousekeeping = True;
				vPGObj.Write();
			EndIf;
		Except
			tcCommonFunctionOnClientServer.TextMessage(TrimAll(vPGObj.Description) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
	EndDo;
EndProcedure // Fill113UserPermission

// -----------------------------------------------------------------------------
Procedure Fill135UserPermission()
	// Run query to get permission groups
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PermissionGroups.Ref AS Ref
	|FROM
	|	Catalog.PermissionGroups AS PermissionGroups
	|WHERE
	|	(NOT PermissionGroups.DeletionMark)
	|	AND (NOT PermissionGroups.IsFolder)
	|ORDER BY
	|	PermissionGroups.Code";
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vPGObj = vQryRes.Ref.GetObject();
		Try
			vPGObj.HavePermissionToChargeExtraServicesOnCredit = True;
			vPGObj.Write();
		Except
			tcCommonFunctionOnClientServer.TextMessage(TrimAll(vPGObj.Description) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
	EndDo;
EndProcedure // Fill135UserPermission

// -----------------------------------------------------------------------------
Procedure FillCorrectRUBCode()
	vRUBRef = Catalogs.Currencies.FindByCode(810);
	If ValueIsFilled(vRUBRef) Then
		vRUBObj = vRUBref.GetObject();
		vRUBObj.Code = 643;
		vRUBObj.Write();
	EndIf;
EndProcedure // FillCorrectRUBCode

// -----------------------------------------------------------------------------
Procedure FixAccommodationTypes()
	vAllAccTypes = cmGetAllAccommodationTypes();
	For Each vAllAccTypesRow In vAllAccTypes Do
		vAccType = vAllAccTypesRow.AccommodationType;
		If vAccType.Type = Enums.AccomodationTypes.AdditionalBed Then
			If vAccType.NumberOfAdditionalBeds = 0 Then
				vAccTypeObj = vAccType.GetObject();
				vAccTypeObj.NumberOfAdditionalBeds = 1;
				vAccTypeObj.Write();
			EndIf;
		EndIf;
	EndDo;
EndProcedure // FixAccommodationTypes

// -----------------------------------------------------------------------------
Procedure FillAuditReportsSettings()
	// Create audit reports group first
	vAuditReportsFolder = Catalogs.Reports.FindByCode(790, , Catalogs.Reports.EmptyRef());
	If Not ValueIsFilled(vAuditReportsFolder) Then
		vAuditReportsFolderObj = Catalogs.Reports.CreateFolder();
		vAuditReportsFolderObj.Code = 790;
		vAuditReportsFolderObj.Description = "EN='Audit reports'; RU='Аудиторские отчеты'";
		vAuditReportsFolderObj.Write();
		vAuditReportsFolder = vAuditReportsFolderObj.Ref;
	ElsIf Not vAuditReportsFolder.IsFolder Then
		vAuditReportsFolder = Catalogs.Reports.EmptyRef();
	EndIf;
	// Fill report name and report folder for new reports
	vRepRef = Catalogs.Reports.FindByCode(792);
	If ValueIsFilled(vRepRef) And Not ValueIsFilled(vRepRef.Report) Then
		vRepObj = vRepRef.GetObject();
		vRepObj.Report = "AccommodationAnnulations"; 
		vRepObj.Parent = vAuditReportsFolder;
		vRepObj.SortCode = 792;
		vRepObj.DynamicParameters = "REP.PeriodFrom = BegOfMonth(CurrentSessionDate());
		                            |REP.PeriodTo = CurrentSessionDate();";
		vRepObj.Write();
	EndIf;
	vRepRef = Catalogs.Reports.FindByCode(794);
	If ValueIsFilled(vRepRef) And Not ValueIsFilled(vRepRef.Report) Then
		vRepObj = vRepRef.GetObject();
		vRepObj.Report = "PaymentAnnulations"; 
		vRepObj.Parent = vAuditReportsFolder;
		vRepObj.SortCode = 794;
		vRepObj.DynamicParameters = "REP.PeriodFrom = BegOfMonth(CurrentSessionDate());
		                            |REP.PeriodTo = CurrentSessionDate();";
		vRepObj.Write();
	EndIf;
	vRepRef = Catalogs.Reports.FindByCode(796);
	If ValueIsFilled(vRepRef) And Not ValueIsFilled(vRepRef.Report) Then
		vRepObj = vRepRef.GetObject();
		vRepObj.Report = "ChargesStorno"; 
		vRepObj.Parent = vAuditReportsFolder;
		vRepObj.SortCode = 796;
		vRepObj.DynamicParameters = "REP.PeriodFrom = BegOfMonth(CurrentSessionDate());
		                            |REP.PeriodTo = CurrentSessionDate();";
		vRepObj.Write();
	EndIf;
	vRepRef = Catalogs.Reports.FindByCode(798);
	If ValueIsFilled(vRepRef) And Not ValueIsFilled(vRepRef.Report) Then
		vRepObj = vRepRef.GetObject();
		vRepObj.Report = "AccommodationChangeRoomAudit"; 
		vRepObj.Parent = vAuditReportsFolder;
		vRepObj.SortCode = 798;
		vRepObj.DynamicParameters = "REP.PeriodFrom = BegOfMonth(CurrentSessionDate());
		                            |REP.PeriodTo = CurrentSessionDate();";
		vRepObj.Write();
	EndIf;
	vRepRef = Catalogs.Reports.FindByCode(799);
	If ValueIsFilled(vRepRef) And Not ValueIsFilled(vRepRef.Report) Then
		vRepObj = vRepRef.GetObject();
		vRepObj.Report = "GuestsInBlockedRooms"; 
		vRepObj.Parent = vAuditReportsFolder;
		vRepObj.SortCode = 799;
		vRepObj.DynamicParameters = "REP.PeriodFrom = BegOfMonth(CurrentSessionDate());
		                            |REP.PeriodTo = CurrentSessionDate();";
		vRepObj.Write();
	EndIf;
EndProcedure // FillAuditReportsSettings 

// -----------------------------------------------------------------------------
Procedure FillCustomerOperationalBalancesObjectPrintingForm()
	vCustomerFolder = Catalogs.ObjectPrintingForms.FindByCode("1000", False, Catalogs.ObjectPrintingForms.EmptyRef());
	vCustomerOperationalBalanceObj = Catalogs.ObjectPrintingForms.CustomerPrintOperationalBalances.GetObject();
	If ValueIsFilled(vCustomerFolder) And vCustomerFolder.IsFolder Then
		vCustomerOperationalBalanceObj.Parent = vCustomerFolder;
	EndIf;
	vCustomerOperationalBalanceObj.ObjectType = Catalogs.Customers.EmptyRef();
	vCustomerOperationalBalanceObj.IsActive = True;
	vCustomerOperationalBalanceObj.Report = Catalogs.Reports.CustomerAccountsOperational;
	vCustomerOperationalBalanceObj.Write();
EndProcedure // FillCustomerOperationalBalancesObjectPrintingForm

// -----------------------------------------------------------------------------
Procedure FillCustomerSalesForecastReportSettings()
	// Find analitical reports folder
	vAnaliticalReportsFolder = Catalogs.Reports.FindByCode(500, , Catalogs.Reports.EmptyRef());
	// Fill report name and report folder for new report
	vRepRef = Catalogs.Reports.FindByCode(521);
	If ValueIsFilled(vRepRef) And Not ValueIsFilled(vRepRef.Report) Then
		vRepObj = vRepRef.GetObject();
		vRepObj.Report = "CustomerSalesForecast"; 
		If ValueIsFilled(vAnaliticalReportsFolder) And vAnaliticalReportsFolder.IsFolder Then
			vRepObj.Parent = vAnaliticalReportsFolder;
		EndIf;
		vRepObj.SortCode = 521;
		vRepObj.DynamicParameters = "REP.PeriodFrom = BegOfMonth(CurrentSessionDate());
		                            |REP.PeriodTo = EndOfMonth(CurrentSessionDate());";
		vRepObj.Write();
	EndIf;
EndProcedure // FillCustomerSalesForecastReportSettings 

// -----------------------------------------------------------------------------
Procedure FillOccupancyForecastReportSettings()
	// Find analitical reports folder
	vAnaliticalReportsFolder = Catalogs.Reports.FindByCode(500, , Catalogs.Reports.EmptyRef());
	// Fill report name and report folder for new report
	vRepRef = Catalogs.Reports.FindByCode(235);
	If ValueIsFilled(vRepRef) And Not ValueIsFilled(vRepRef.Report) Then
		vRepObj = vRepRef.GetObject();
		vRepObj.Report = "OccupancyForecast"; 
		If ValueIsFilled(vAnaliticalReportsFolder) And vAnaliticalReportsFolder.IsFolder Then
			vRepObj.Parent = vAnaliticalReportsFolder;
		EndIf;
		vRepObj.SortCode = 235;
		vRepObj.DynamicParameters = "REP.PeriodFrom = BegOfMonth(CurrentSessionDate());
		                            |REP.PeriodTo = EndOfMonth(CurrentSessionDate());";
		vRepObj.Write();
	EndIf;
EndProcedure // FillOccupancyForecastReportSettings

// -----------------------------------------------------------------------------
Procedure FillChangedAccommodationsReportSettings()
	// Fill report name and report folder for new report
	vRepRef = Catalogs.Reports.FindByCode(850);
	If ValueIsFilled(vRepRef) And Not ValueIsFilled(vRepRef.Report) Then
		vRepObj = vRepRef.GetObject();
		vRepObj.Report = "ChangedAccommodations"; 
		vRepObj.SortCode = 850;
		vRepObj.DynamicParameters = "REP.PeriodFrom = BegOfDay(CurrentSessionDate()) - 24*3600;
		                            |REP.PeriodTo = CurrentSessionDate();";
		vRepObj.Write();
	EndIf;
EndProcedure // FillChangedAccommodationsReportSettings

// -----------------------------------------------------------------------------
Procedure FillIssuedHotelProductsReportSettings()
	// Fill report name and report folder for new report
	vRepRef = Catalogs.Reports.FindByCode(584);
	If ValueIsFilled(vRepRef) And Not ValueIsFilled(vRepRef.Report) Then
		vRepObj = vRepRef.GetObject();
		vRepObj.Report = "IssuedHotelProducts"; 
		vRepObj.Parent = Catalogs.Reports.EmptyRef();
		vRepObj.SortCode = 584;
		vRepObj.DynamicParameters = "REP.PeriodFrom = BegOfDay(CurrentSessionDate());
		                            |REP.PeriodTo = EndOfDay(CurrentSessionDate());";
		vRepObj.Write();
	EndIf;
EndProcedure // FillIssuedHotelProductsReportSettings 

// -----------------------------------------------------------------------------
Procedure FixPaymentMethods()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PaymentMethods.Ref AS Ref
	|FROM
	|	Catalog.PaymentMethods AS PaymentMethods
	|WHERE
	|	NOT PaymentMethods.DeletionMark
	|	AND PaymentMethods.IsByCreditCard
	|
	|ORDER BY
	|	PaymentMethods.SortCode,
	|	PaymentMethods.Description";
	vPaymentMethods = vQry.Execute().Unload();
	For Each vPaymentMethodsRow In vPaymentMethods Do
		vPMRef = vPaymentMethodsRow.Ref;
		If vPMRef.IsByCreditCard Then
			vPMObj = vPMRef.GetObject();
			vPMObj.AuthorizationCodeIsRequired = True;
			vPMObj.ReferenceCodeIsRequired = True;
			vPMObj.Write();
		EndIf;
	EndDo;
EndProcedure // FixPaymentMethods

// -----------------------------------------------------------------------------
Procedure FillReleaseExpiredRoomAllotmentsDataProcessorSettings()
	// Fill data processor name and dynamic parameters
	vDPRef = Catalogs.DataProcessors.ReleaseExpiredRoomAllotments;
	If ValueIsFilled(vDPRef) And Not ValueIsFilled(vDPRef.Processing) Then
		vDPObj = vDPRef.GetObject();
		vDPObj.Processing = "ReleaseExpiredRoomAllotments"; 
		vDPObj.SortCode = 210;
		vDPObj.DynamicParameters = "If ValueIsFilled(PARM) Then
		                           |	DPO.Hotel = PARM;
		                           |EndIf;";
		vDPObj.Write();
	EndIf;
EndProcedure // FillReleaseExpiredRoomAllotmentsDataProcessorSettings 

// -----------------------------------------------------------------------------
Procedure FillSendGuestGroupNotificationsDataProcessorSettings()
	// Fill data processor name and dynamic parameters
	vDPRef = Catalogs.DataProcessors.SendGuestGroupNotifications;
	If ValueIsFilled(vDPRef) And Not ValueIsFilled(vDPRef.Processing) Then
		vDPObj = vDPRef.GetObject();
		vDPObj.Processing = "SendGuestGroupNotifications"; 
		vDPObj.SortCode = 810;
		vDPObj.Write();
	EndIf;
EndProcedure // FillSendGuestGroupNotificationsDataProcessorSettings 

// -----------------------------------------------------------------------------
Procedure Fill112UserPermission()
	// Run query to get permission groups
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PermissionGroups.Ref AS Ref
	|FROM
	|	Catalog.PermissionGroups AS PermissionGroups
	|WHERE
	|	(NOT PermissionGroups.DeletionMark)
	|	AND (NOT PermissionGroups.IsFolder)
	|ORDER BY
	|	PermissionGroups.Code";
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vPGObj = vQryRes.Ref.GetObject();
		Try
			vPGObj.HavePermissionToDoBookingWithoutRooms = True;
			vPGObj.Write();
		Except
			tcCommonFunctionOnClientServer.TextMessage(TrimAll(vPGObj.Description) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
	EndDo;
EndProcedure // Fill112UserPermission

// -----------------------------------------------------------------------------
Procedure Fill116UserPermission()
	// Run query to get permission groups
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PermissionGroups.Ref AS Ref
	|FROM
	|	Catalog.PermissionGroups AS PermissionGroups
	|WHERE
	|	(NOT PermissionGroups.DeletionMark)
	|	AND (NOT PermissionGroups.IsFolder)
	|ORDER BY
	|	PermissionGroups.Code";
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vPGObj = vQryRes.Ref.GetObject();
		Try
			vPGObj.HavePermissionToCancelAccommodations = True;
			vPGObj.Write();
		Except
			tcCommonFunctionOnClientServer.TextMessage(TrimAll(vPGObj.Description) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
	EndDo;
EndProcedure // Fill116UserPermission

// -----------------------------------------------------------------------------
Procedure Fill117UserPermission()
	// Run query to get permission groups
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PermissionGroups.Ref AS Ref
	|FROM
	|	Catalog.PermissionGroups AS PermissionGroups
	|WHERE
	|	(NOT PermissionGroups.DeletionMark)
	|	AND (NOT PermissionGroups.IsFolder)
	|ORDER BY
	|	PermissionGroups.Code";
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vPGObj = vQryRes.Ref.GetObject();
		Try
			vPGObj.HavePermissionToEditFoliosCreditLimit = True;
			vPGObj.Write();
		Except
			tcCommonFunctionOnClientServer.TextMessage(TrimAll(vPGObj.Description) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
	EndDo;
EndProcedure // Fill117UserPermission

// -----------------------------------------------------------------------------
Procedure Fill119UserPermission()
	// Run query to get permission groups
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PermissionGroups.Ref AS Ref
	|FROM
	|	Catalog.PermissionGroups AS PermissionGroups
	|WHERE
	|	(NOT PermissionGroups.DeletionMark)
	|	AND (NOT PermissionGroups.IsFolder)
	|ORDER BY
	|	PermissionGroups.Code";
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vPGObj = vQryRes.Ref.GetObject();
		Try
			vPGObj.HavePermissionToChooseClientTypeManually = True;
			vPGObj.Write();
		Except
			tcCommonFunctionOnClientServer.TextMessage(TrimAll(vPGObj.Description) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
	EndDo;
EndProcedure // Fill119UserPermission

// -----------------------------------------------------------------------------
Procedure FillCheckReservationWaitingListProcessingSettings()
	// Fill data processor name and dynamic parameters
	vDPRef = Catalogs.DataProcessors.CheckReservationWaitingList;
	If ValueIsFilled(vDPRef) And Not ValueIsFilled(vDPRef.Processing) Then
		vDPObj = vDPRef.GetObject();
		vDPObj.Processing = "CheckReservationWaitingList"; 
		vDPObj.SortCode = 820;
		vDPObj.Write();
	EndIf;
EndProcedure // FillCheckReservationWaitingListProcessingSettings

// -----------------------------------------------------------------------------
Procedure FillReservationGuestFullNames()
#If Client Then
	Status(NStr("en='Updating guest full names in reservations...'; de='Updating guest full names in reservations...'; ru='Заполнение ФИО гостей в брони...'"));
#EndIf
	// Run query to get reservations
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservation.Ref AS Document,
	|	Reservation.Date AS Date,
	|	Reservation.PointInTime AS PointInTime
	|FROM
	|	Document.Reservation AS Reservation
	|ORDER BY
	|	PointInTime";
	vQryRes = vQry.Execute().Unload();
	vCurDate = '00010101';
	// Rewrite documents
	For Each vQryResRow In vQryRes Do
		vCurDocObj = vQryResRow.Document.GetObject();
		Try
			vCurDocObj.Write(DocumentWriteMode.Write);
		Except
			tcCommonFunctionOnClientServer.TextMessage(String(vCurDocObj) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
		
#If Client Then
		// Status message
		If BegOfDay(vQryResRow.Date) <> vCurDate Then
			vCurDate = BegOfDay(vQryResRow.Date);
			Status(NStr("en='Processing reservations dated " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'; 
			            |de='Processing reservations dated " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'; 
			            |ru='Обработка брони за " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'"));
		EndIf;
		UserInterruptProcessing();
#EndIf
	EndDo;
EndProcedure // FillReservationGuestFullNames

// -----------------------------------------------------------------------------
Procedure FillAccommodationGuestFullNames()
#If Client Then
	Status(NStr("en='Updating guest full names in accommodations...'; de='Updating guest full names in accommodations...'; ru='Заполнение ФИО гостей в размещениях...'"));
#EndIf
	// Run query to get reservations
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref AS Document,
	|	Accommodation.Date AS Date,
	|	Accommodation.PointInTime AS PointInTime
	|FROM
	|	Document.Accommodation AS Accommodation
	|ORDER BY
	|	PointInTime";
	vQryRes = vQry.Execute().Unload();
	vCurDate = '00010101';
	// Rewrite documents
	For Each vQryResRow In vQryRes Do
		vCurDocObj = vQryResRow.Document.GetObject();
		Try
			vCurDocObj.Write(DocumentWriteMode.Write);
		Except
			tcCommonFunctionOnClientServer.TextMessage(String(vCurDocObj) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
		
#If Client Then
		// Status message
		If BegOfDay(vQryResRow.Date) <> vCurDate Then
			vCurDate = BegOfDay(vQryResRow.Date);
			Status(NStr("en='Processing accommodations dated " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'; 
			            |de='Processing accommodations dated " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'; 
			            |ru='Обработка размещений за " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'"));
		EndIf;
		UserInterruptProcessing();
#EndIf
	EndDo;
EndProcedure // FillAccommodationGuestFullNames

// -----------------------------------------------------------------------------
Procedure FillCustomerGuestsPercentsReportSettings()
	// Find analitical reports folder
	vAnaliticalReportsFolder = Catalogs.Reports.FindByCode(500, , Catalogs.Reports.EmptyRef());
	// Fill report name and report folder for new report
	vRepRef = Catalogs.Reports.FindByCode(527);
	If ValueIsFilled(vRepRef) And Not ValueIsFilled(vRepRef.Report) Then
		vRepObj = vRepRef.GetObject();
		vRepObj.Report = "CustomerGuestsPercents"; 
		If ValueIsFilled(vAnaliticalReportsFolder) And vAnaliticalReportsFolder.IsFolder Then
			vRepObj.Parent = vAnaliticalReportsFolder;
		EndIf;
		vRepObj.SortCode = 527;
		vRepObj.DynamicParameters = "REP.PeriodFrom = BegOfMonth(CurrentSessionDate());
		                            |REP.PeriodTo = EndOfDay(CurrentSessionDate());";
		vRepObj.Write();
	EndIf;
EndProcedure // FillCustomerGuestsPercentsReportSettings 

// -----------------------------------------------------------------------------
Procedure FillCheckCustomerServicesReportSettings()
	// Fill report name and report folder for new report
	vRepRef = Catalogs.Reports.CheckCustomerServices;
	If ValueIsFilled(vRepRef) And Not ValueIsFilled(vRepRef.Report) Then
		vRepObj = vRepRef.GetObject();
		vRepObj.Report = "CheckCustomerServices"; 
		vRepObj.SortCode = 167;
		vRepObj.DynamicParameters = "REP.PeriodFrom = BegOfDay(CurrentSessionDate());
		                            |REP.PeriodTo = EndOfDay(CurrentSessionDate());";
		vRepObj.Write();
	EndIf;
EndProcedure // FillCheckCustomerServicesReportSettings 

// -----------------------------------------------------------------------------
Procedure FillCheckCustomerGuestsReportSettings()
	// Fill report name and report folder for new report
	vRepRef = Catalogs.Reports.CheckCustomerGuests;
	If ValueIsFilled(vRepRef) And Not ValueIsFilled(vRepRef.Report) Then
		vRepObj = vRepRef.GetObject();
		vRepObj.Report = "CheckCustomerGuests"; 
		vRepObj.SortCode = 168;
		vRepObj.DynamicParameters = "REP.PeriodFrom = BegOfDay(CurrentSessionDate());
		                            |REP.PeriodTo = EndOfDay(CurrentSessionDate());";
		vRepObj.Write();
	EndIf;
EndProcedure // FillCheckCustomerGuestsReportSettings

// -----------------------------------------------------------------------------
Procedure FillCopyGuestGroupReservationsObjectFormAction()
	vObj = Catalogs.ObjectFormActions.ReservationCopyGuestGroupReservations.GetObject();
	vObj.IsActive = True;
	vObj.ObjectType = Documents.Reservation.EmptyRef();
	vObj.Write();
EndProcedure // FillCopyGuestGroupReservationsObjectFormAction

// -----------------------------------------------------------------------------
Procedure RepostActiveReservationsInOneRun()
#If Client Then
	Status(NStr("en='Reposting active reservations...'; de='Reposting active reservations...'; ru='Перепроведение действующей брони...'"));
#EndIf
	// Run query to get active reservations
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservation.Ref AS Document,
	|	Reservation.Date AS Date,
	|	Reservation.PointInTime AS PointInTime
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.ReservationStatus.IsActive
	|	AND Reservation.Posted
	|
	|UNION ALL
	|
	|SELECT
	|	ResourceReservation.Ref,
	|	ResourceReservation.Date,
	|	ResourceReservation.PointInTime
	|FROM
	|	Document.ResourceReservation AS ResourceReservation
	|WHERE
	|	ResourceReservation.ResourceReservationStatus.IsActive
	|	AND (NOT ResourceReservation.ResourceReservationStatus.ServicesAreDelivered)
	|	AND ResourceReservation.Posted
	|
	|ORDER BY
	|	PointInTime";
	vQryRes = vQry.Execute().Unload();
	vCurDate = '00010101';
	// Repost active reservations	
	For Each vQryResRow In vQryRes Do
		vCurDocObj = vQryResRow.Document.GetObject();
		Try
			vCurDocObj.AdditionalProperties.Insert("InfoBaseUpdateMode", True);
			vCurDocObj.Write(DocumentWriteMode.Posting);
		Except
			tcCommonFunctionOnClientServer.TextMessage(String(vCurDocObj) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
		
#If Client Then
		// Status message
		If BegOfDay(vQryResRow.Date) <> vCurDate Then
			vCurDate = BegOfDay(vQryResRow.Date);
			Status(NStr("en='Reposting active reservations on " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'; 
			            |de='Reposting active reservations on " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'; 
			            |ru='Перепроведение действующей брони за " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'"));
		EndIf;
		UserInterruptProcessing();
#EndIf
	EndDo;
EndProcedure // RepostActiveReservationsInOneRun

// -----------------------------------------------------------------------------
Procedure RepostPayments()
#If Client Then
	Status(NStr("en='Reposting payments...';ru='Перепроведение платежей...';de='Neue Durchführung von Zahlungen...'"));
#EndIf
	// Run query to get payments
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Payments.Ref AS Document,
	|	Payments.Date AS Date,
	|	Payments.PointInTime AS PointInTime
	|FROM
	|	Document.Payment AS Payments
	|WHERE
	|	Payments.Posted
	|
	|ORDER BY
	|	PointInTime";
	vQryRes = vQry.Execute().Unload();
	vCurDate = '00010101';
	// Repost payments
	For Each vQryResRow In vQryRes Do
		vCurDocObj = vQryResRow.Document.GetObject();
		Try
			vCurDocObj.AdditionalProperties.Insert("InfoBaseUpdateMode", True);
			vCurDocObj.Write(DocumentWriteMode.Posting);
		Except
			tcCommonFunctionOnClientServer.TextMessage(String(vCurDocObj) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
		
#If Client Then
		// Status message
		If BegOfDay(vQryResRow.Date) <> vCurDate Then
			vCurDate = BegOfDay(vQryResRow.Date);
			Status(NStr("en='Reposting payments on " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'; 
			            |de='Reposting payments on " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'; 
			            |ru='Перепроведение платежей за " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'"));
		EndIf;
		UserInterruptProcessing();
#EndIf
	EndDo;
EndProcedure // RepostPayments

// -----------------------------------------------------------------------------
Procedure RepostReturns()
#If Client Then
	Status(NStr("en='Reposting returns...'; de='Reposting returns...'; ru='Перепроведение возвратов...'"));
#EndIf
	// Run query to get returns
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Return.Ref AS Document,
	|	Return.Date AS Date,
	|	Return.PointInTime AS PointInTime
	|FROM
	|	Document.Return AS Return
	|WHERE
	|	Return.Posted
	|
	|ORDER BY
	|	PointInTime";
	vQryRes = vQry.Execute().Unload();
	vCurDate = '00010101';
	// Repost returns
	For Each vQryResRow In vQryRes Do
		vCurDocObj = vQryResRow.Document.GetObject();
		Try
			vCurDocObj.AdditionalProperties.Insert("InfoBaseUpdateMode", True);
			vCurDocObj.Write(DocumentWriteMode.Posting);
		Except
			tcCommonFunctionOnClientServer.TextMessage(String(vCurDocObj) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
		
#If Client Then
		// Status message
		If BegOfDay(vQryResRow.Date) <> vCurDate Then
			vCurDate = BegOfDay(vQryResRow.Date);
			Status(NStr("en='Reposting returns on " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'; 
			            |de='Reposting returns on " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'; 
			            |ru='Перепроведение возвратов за " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'"));
		EndIf;
		UserInterruptProcessing();
#EndIf
	EndDo;
EndProcedure // RepostReturns

// -----------------------------------------------------------------------------
Procedure RepostCustomerPayments()
#If Client Then
	Status(NStr("en='Reposting customer payments...'; de='Reposting customer payments...'; ru='Перепроведение платежей контрагентов...'"));
#EndIf
	// Run query to get customer payments
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Return.Ref AS Document,
	|	Return.Date AS Date,
	|	Return.PointInTime AS PointInTime
	|FROM
	|	Document.Return AS Return
	|WHERE
	|	Return.Posted
	|
	|ORDER BY
	|	PointInTime";
	vQryRes = vQry.Execute().Unload();
	vCurDate = '00010101';
	// Repost returns
	For Each vQryResRow In vQryRes Do
		vCurDocObj = vQryResRow.Document.GetObject();
		Try
			vCurDocObj.AdditionalProperties.Insert("InfoBaseUpdateMode", True);
			vCurDocObj.Write(DocumentWriteMode.Posting);
		Except
			tcCommonFunctionOnClientServer.TextMessage(String(vCurDocObj) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
		
#If Client Then
		// Status message
		If BegOfDay(vQryResRow.Date) <> vCurDate Then
			vCurDate = BegOfDay(vQryResRow.Date);
			Status(NStr("en='Reposting customer payments on " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'; 
			            |de='Reposting customer payments on " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'; 
			            |ru='Перепроведение платежей контрагентов за " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'"));
		EndIf;
		UserInterruptProcessing();
#EndIf
	EndDo;
EndProcedure // RepostCustomerPayments

// -----------------------------------------------------------------------------
Procedure RepostCloseOfCashRegisterDays()
#If Client Then
	Status(NStr("en='Reposting close of cash register days...'; de='Reposting close of cash register days...'; ru='Перепроведение закрытия кассовых смен...'"));
#EndIf
	// Run query to get close of cash register days
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CloseOfCashRegisterDay.Ref AS Document,
	|	CloseOfCashRegisterDay.Date AS Date,
	|	CloseOfCashRegisterDay.PointInTime AS PointInTime
	|FROM
	|	Document.CloseOfCashRegisterDay AS CloseOfCashRegisterDay
	|WHERE
	|	CloseOfCashRegisterDay.Posted
	|
	|ORDER BY
	|	PointInTime";
	vQryRes = vQry.Execute().Unload();
	vCurDate = '00010101';
	// Repost close of cash register days
	For Each vQryResRow In vQryRes Do
		vCurDocObj = vQryResRow.Document.GetObject();
		Try
			vCurDocObj.AdditionalProperties.Insert("InfoBaseUpdateMode", True);
			vCurDocObj.Write(DocumentWriteMode.Posting);
		Except
			tcCommonFunctionOnClientServer.TextMessage(String(vCurDocObj) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
		
#If Client Then
		// Status message
		If BegOfDay(vQryResRow.Date) <> vCurDate Then
			vCurDate = BegOfDay(vQryResRow.Date);
			Status(NStr("en='Reposting close of cash register days on " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'; 
			            |de='Reposting close of cash register days on " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'; 
			            |ru='Перепроведение закрытия кассовых смен за " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'"));
		EndIf;
		UserInterruptProcessing();
#EndIf
	EndDo;
EndProcedure // RepostCloseOfCashRegisterDays

// -----------------------------------------------------------------------------
Procedure FillExpectedCheckInOrderedByRoomsReportSettings()
	// Find report
	vRepRef = Catalogs.Reports.ExpectedCheckInOrderedByRooms;
	If ValueIsFilled(vRepRef) And Not ValueIsFilled(vRepRef.Report) Then
		vRepObj = vRepRef.GetObject();
		vRepObj.Report = "ExpectedCheckIn"; 
		vRepObj.SortCode = 117;
		vRepObj.StaticParameters = Catalogs.Reports.ExpectedCheckInForToday.StaticParameters;
		vRepObj.DynamicParameters = "REP.PeriodFrom = BegOfDay(CurrentSessionDate());
		                            |REP.PeriodTo = EndOfDay(CurrentSessionDate());";
		vRepObj.Write();
	EndIf;
EndProcedure // FillExpectedCheckInOrderedByRoomsReportSettings

// -----------------------------------------------------------------------------
Procedure FillReservationPrintGuestGroupRoomsObjectPrintingFormSetings()
	If TypeOf(Catalogs.ObjectPrintingForms.ReservationPrintGuestGroupRooms.ObjectType) <> Type("DocumentRef.Reservation") Then
		vReservationFolder = Catalogs.ObjectPrintingForms.FindByCode("200", False, Catalogs.ObjectPrintingForms.EmptyRef());
		vPrtFormObj = Catalogs.ObjectPrintingForms.ReservationPrintGuestGroupRooms.GetObject();
		vPrtFormObj.ObjectType = Documents.Reservation.EmptyRef();
		If ValueIsFilled(vReservationFolder) And vReservationFolder.IsFolder Then
			vPrtFormObj.Parent = vReservationFolder;
		EndIf;
		vPrtFormObj.IsActive = True;
		vPrtFormObj.Remarks = "en='Print list of guest group rooms sorted by rooms sort order'; ru='Распечатать список номеров на брони по группе гостей отсортированный по номерам'";
		vPrtFormObj.Write();
	EndIf;
EndProcedure // FillReservationPrintGuestGroupRoomsObjectPrintingFormSetings

// -----------------------------------------------------------------------------
Procedure FillSafetySystemEventsAuditReportSettings()
	// Create audit reports group first
	vAuditReportsFolder = Catalogs.Reports.FindByCode(790, , Catalogs.Reports.EmptyRef());
	If ValueIsFilled(vAuditReportsFolder) And Not vAuditReportsFolder.IsFolder Then
		vAuditReportsFolder = Catalogs.Reports.EmptyRef();
	EndIf;
	// Fill report name and report folder for new reports
	vRepRef = Catalogs.Reports.SafetySystemEventsAudit;
	If ValueIsFilled(vRepRef) And Not ValueIsFilled(vRepRef.Report) Then
		vRepObj = vRepRef.GetObject();
		vRepObj.Report = "SafetySystemEventsAudit"; 
		vRepObj.Parent = vAuditReportsFolder;
		vRepObj.SortCode = 797;
		vRepObj.DynamicParameters = "REP.PeriodFrom = BegOfDay(CurrentSessionDate()) - 24*3600;
		                            |REP.PeriodTo = EndOfDay(REP.PeriodFrom);";
		vRepObj.Write();
	EndIf;
EndProcedure // FillSafetySystemEventsAuditReportSettings 

// -----------------------------------------------------------------------------
Procedure FillPrintCouponsActionSetings()
	vReservationFolder = Catalogs.ObjectFormActions.FindByCode("200");
	If TypeOf(Catalogs.ObjectFormActions.ReservationPrintCoupons.ObjectType) <> Type("DocumentRef.Reservation") Then
		vFrmActObj = Catalogs.ObjectFormActions.ReservationPrintCoupons.GetObject();
		vFrmActObj.ObjectType = Documents.Reservation.EmptyRef();
		If ValueIsFilled(vReservationFolder) And vReservationFolder.IsFolder Then
			vFrmActObj.Parent = vReservationFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Remarks = "en='Print coupons list for the reservation'; ru='Распечатать список талонов по брони'";
		vFrmActObj.Write();
		
		vFrmActObj = Catalogs.ObjectFormActions.ReservationPrintRoomCoupons.GetObject();
		vFrmActObj.ObjectType = Documents.Reservation.EmptyRef();
		If ValueIsFilled(vReservationFolder) And vReservationFolder.IsFolder Then
			vFrmActObj.Parent = vReservationFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Remarks = "en='Print coupons list for the one room reservations'; ru='Распечатать список талонов по брони в одном номере'";
		vFrmActObj.Write();
		
		vFrmActObj = Catalogs.ObjectFormActions.ReservationPrintGuestGroupCoupons.GetObject();
		vFrmActObj.ObjectType = Documents.Reservation.EmptyRef();
		If ValueIsFilled(vReservationFolder) And vReservationFolder.IsFolder Then
			vFrmActObj.Parent = vReservationFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Remarks = "en='Print coupons list for the guest group reservations'; ru='Распечатать список талонов по брони из одной группы'";
		vFrmActObj.Write();
	EndIf;
	vAccommodationFolder = Catalogs.ObjectFormActions.FindByCode("100");
	If TypeOf(Catalogs.ObjectFormActions.AccommodationPrintCoupons.ObjectType) <> Type("DocumentRef.Accommodation") Then
		vFrmActObj = Catalogs.ObjectFormActions.AccommodationPrintCoupons.GetObject();
		vFrmActObj.ObjectType = Documents.Accommodation.EmptyRef();
		If ValueIsFilled(vAccommodationFolder) And vAccommodationFolder.IsFolder Then
			vFrmActObj.Parent = vAccommodationFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Remarks = "en='Print coupons list for the accommodation'; ru='Распечатать список талонов по размещению'";
		vFrmActObj.Write();
		
		vFrmActObj = Catalogs.ObjectFormActions.AccommodationPrintRoomCoupons.GetObject();
		vFrmActObj.ObjectType = Documents.Accommodation.EmptyRef();
		If ValueIsFilled(vAccommodationFolder) And vAccommodationFolder.IsFolder Then
			vFrmActObj.Parent = vAccommodationFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Remarks = "en='Print coupons list for the one room in-house guests'; ru='Распечатать список талонов по проживающим в одном номере гостям'";
		vFrmActObj.Write();
		
		vFrmActObj = Catalogs.ObjectFormActions.AccommodationPrintGuestGroupCoupons.GetObject();
		vFrmActObj.ObjectType = Documents.Accommodation.EmptyRef();
		If ValueIsFilled(vAccommodationFolder) And vAccommodationFolder.IsFolder Then
			vFrmActObj.Parent = vAccommodationFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Remarks = "en='Print coupons list for the guest group in-house guests'; ru='Распечатать список талонов по проживающим гостям из одной группы'";
		vFrmActObj.Write();
	EndIf;
	vResourceReservationFolder = Catalogs.ObjectFormActions.FindByCode("1300");
	If TypeOf(Catalogs.ObjectFormActions.ResourceReservationPrintCoupons.ObjectType) <> Type("DocumentRef.ResourceReservation") Then
		vFrmActObj = Catalogs.ObjectFormActions.ResourceReservationPrintCoupons.GetObject();
		vFrmActObj.ObjectType = Documents.ResourceReservation.EmptyRef();
		If ValueIsFilled(vResourceReservationFolder) And vResourceReservationFolder.IsFolder Then
			vFrmActObj.Parent = vResourceReservationFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Remarks = "en='Print coupons list for the resource reservation'; ru='Распечатать список талонов по брони ресурсов'";
		vFrmActObj.Write();
		
		vFrmActObj = Catalogs.ObjectFormActions.ResourceReservationPrintGuestGroupCoupons.GetObject();
		vFrmActObj.ObjectType = Documents.ResourceReservation.EmptyRef();
		If ValueIsFilled(vResourceReservationFolder) And vResourceReservationFolder.IsFolder Then
			vFrmActObj.Parent = vResourceReservationFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Remarks = "en='Print coupons list for the guest group resource reservations'; ru='Распечатать список талонов по брони ресурсов из одной группы'";
		vFrmActObj.Write();
	EndIf;
	If TypeOf(Catalogs.ObjectFormActions.FolioPrintCoupons.ObjectType) <> Type("DocumentRef.Folio") Then
		vFolioFolder = Catalogs.ObjectFormActions.FindByCode("500");
		vFrmActObj = Catalogs.ObjectFormActions.FolioPrintCoupons.GetObject();
		vFrmActObj.ObjectType = Documents.Folio.EmptyRef();
		If ValueIsFilled(vFolioFolder) And vFolioFolder.IsFolder Then
			vFrmActObj.Parent = vFolioFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Remarks = "en='Print coupons list for the folio'; ru='Распечатать список талонов по лицевому счету'";
		vFrmActObj.Write();
	EndIf;
EndProcedure // FillPrintCouponsActionSetings

// -----------------------------------------------------------------------------
Procedure FillClientObjectFormActionsSettings()
	vClientFolder = Catalogs.ObjectFormActions.FindByCode("1500");
	If Not ValueIsFilled(vClientFolder) Then
		vClientFolderObj = Catalogs.ObjectFormActions.CreateFolder();
		vClientFolderObj.Code = "1500";
		vClientFolderObj.Description = "en='Client'; ru='Клиент'";
		vClientFolderObj.Write();
		vClientFolder = vClientFolderObj.Ref;
	EndIf;
	If TypeOf(Catalogs.ObjectFormActions.ClientFillReservation.ObjectType) <> Type("CatalogRef.Clients") Then
		vFrmActObj = Catalogs.ObjectFormActions.ClientFillReservation.GetObject();
		vFrmActObj.ObjectType = Catalogs.Clients.EmptyRef();
		If ValueIsFilled(vClientFolder) And vClientFolder.IsFolder Then
			vFrmActObj.Parent = vClientFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Remarks = "en='Fill new reservation for the client'; ru='Создать новую бронь для клиента'";
		vFrmActObj.ObjectFormActionButton = Enums.ObjectFormActionButtons.Button1;
		#If Client Then
			vFrmActObj.ActionIcon = New ValueStorage(PictureLib.ScheduledJobs);
		#EndIf
		vFrmActObj.ButtonCaption = "en='New reservation (F7)'; ru='Новая бронь (F7)'";
		vFrmActObj.ButtonToolTip = "en='Fill new reservation'; ru='Создать новую бронь'";
		vFrmActObj.ButtonShortcut = "F7";
		vFrmActObj.Write();
	EndIf;
	If TypeOf(Catalogs.ObjectFormActions.ClientFillAccommodation.ObjectType) <> Type("CatalogRef.Clients") Then
		vFrmActObj = Catalogs.ObjectFormActions.ClientFillAccommodation.GetObject();
		vFrmActObj.ObjectType = Catalogs.Clients.EmptyRef();
		If ValueIsFilled(vClientFolder) And vClientFolder.IsFolder Then
			vFrmActObj.Parent = vClientFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Remarks = "en='Fill new accommodation for the client'; ru='Создать новое размещение для клиента'";
		vFrmActObj.ObjectFormActionButton = Enums.ObjectFormActionButtons.Button2;
		#If Client Then
			vFrmActObj.ActionIcon = New ValueStorage(PictureLib.CheckIn);
		#EndIf
		vFrmActObj.ButtonCaption = "en='New accommodation (F6)'; ru='Новое размещение (F6)'";
		vFrmActObj.ButtonToolTip = "en='Fill new accommodation'; ru='Создать новое размещение'";
		vFrmActObj.ButtonShortcut = "F6";
		vFrmActObj.Write();
	EndIf;
	If TypeOf(Catalogs.ObjectFormActions.ClientFillResourceReservation.ObjectType) <> Type("CatalogRef.Clients") Then
		vFrmActObj = Catalogs.ObjectFormActions.ClientFillResourceReservation.GetObject();
		vFrmActObj.ObjectType = Catalogs.Clients.EmptyRef();
		If ValueIsFilled(vClientFolder) And vClientFolder.IsFolder Then
			vFrmActObj.Parent = vClientFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Remarks = "en='Fill new resource reservation for the client'; ru='Создать новую бронь ресурсов для клиента'";
		vFrmActObj.ObjectFormActionButton = Enums.ObjectFormActionButtons.Button3;
		#If Client Then
			vFrmActObj.ActionIcon = New ValueStorage(PictureLib.SpreadsheetInsertComment);
		#EndIf
		vFrmActObj.ButtonCaption = "en='New resource reservation (F8)'; ru='Новая бронь ресурсов (F8)'";
		vFrmActObj.ButtonToolTip = "en='Fill new resource reservation'; ru='Создать новую бронь ресурсов'";
		vFrmActObj.ButtonShortcut = "F8";
		vFrmActObj.Write();
	EndIf;
	If TypeOf(Catalogs.ObjectFormActions.ClientShowForeignerRegistryRecords.ObjectType) <> Type("CatalogRef.Clients") Then
		vFrmActObj = Catalogs.ObjectFormActions.ClientShowForeignerRegistryRecords.GetObject();
		vFrmActObj.ObjectType = Catalogs.Clients.EmptyRef();
		If ValueIsFilled(vClientFolder) And vClientFolder.IsFolder Then
			vFrmActObj.Parent = vClientFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Remarks = "en='Show list foreigner registry records for the client'; ru='Показать для клиента список его записей в журнал регистрации иностранцев'";
		#If Client Then
			vFrmActObj.ActionIcon = New ValueStorage(PictureLib.GeographicalSchema);
		#EndIf
		vFrmActObj.Write();
	EndIf;
	vAccommodationFolder = Catalogs.ObjectFormActions.FindByCode("100");
	If TypeOf(Catalogs.ObjectFormActions.AccommodationScanClientData.ObjectType) <> Type("DocumentRef.Accommodation") Then
		vFrmActObj = Catalogs.ObjectFormActions.AccommodationScanClientData.GetObject();
		vFrmActObj.ObjectType = Documents.Accommodation.EmptyRef();
		If ValueIsFilled(vAccommodationFolder) And vAccommodationFolder.IsFolder Then
			vFrmActObj.Parent = vAccommodationFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Remarks = "en='Open client data scans document'; ru='Открыть документ сканирования данных клиента'";
		#If Client Then
			vFrmActObj.ActionIcon = New ValueStorage(PictureLib.Magnifier);
		#EndIf
		vFrmActObj.Write();
	EndIf;
EndProcedure // FillClientObjectFormActionsSettings

// -----------------------------------------------------------------------------
Procedure FillClientObjectPrintFormsSettings()
	vClientFolder = Catalogs.ObjectPrintingForms.FindByCode("1700", False, Catalogs.ObjectPrintingForms.EmptyRef());
	If Not ValueIsFilled(vClientFolder) Then
		vClientFolderObj = Catalogs.ObjectPrintingForms.CreateFolder();
		vClientFolderObj.Code = "1700";
		vClientFolderObj.Description = "en='Client'; ru='Клиент'";
		vClientFolderObj.Write();
		vClientFolder = vClientFolderObj.Ref;
	EndIf;
	If TypeOf(Catalogs.ObjectPrintingForms.ClientPrintGuestAccommodationHistory.ObjectType) <> Type("CatalogRef.Clients") Then
		vFrmPrtObj = Catalogs.ObjectPrintingForms.ClientPrintGuestAccommodationHistory.GetObject();
		vFrmPrtObj.ObjectType = Catalogs.Clients.EmptyRef();
		If ValueIsFilled(vClientFolder) And vClientFolder.IsFolder Then
			vFrmPrtObj.Parent = vClientFolder;
		EndIf;
		vFrmPrtObj.IsActive = True;
		vFrmPrtObj.Remarks = "en='Print client's accommodation history'; ru='Распечатать историю проживаний клиента'";
		vFrmPrtObj.Write();
	EndIf;
EndProcedure // FillClientObjectPrintFormsSettings

// -----------------------------------------------------------------------------
Procedure FillMessagesObjectPrintingFormSetings() 
	vMsgFolder = Catalogs.ObjectPrintingForms.FindByCode("2500", False, Catalogs.ObjectPrintingForms.EmptyRef());
	If Not ValueIsFilled(vMsgFolder) Then
		vMsgFolderObj = Catalogs.ObjectPrintingForms.CreateFolder();
		vMsgFolderObj.Code = "2500";
		vMsgFolderObj.Description = "en='Tasks'; ru='Задачи'";
		vMsgFolderObj.Write();
		vMsgFolder = vMsgFolderObj.Ref;
	EndIf;
	If TypeOf(Catalogs.ObjectPrintingForms.MessagePrintForm.ObjectType) <> Type("DocumentRef.Message") Then
		vFrmPrtObj = Catalogs.ObjectPrintingForms.MessagePrintForm.GetObject();
		vFrmPrtObj.ObjectType = Documents.Message.EmptyRef();
		If ValueIsFilled(vMsgFolder) And vMsgFolder.IsFolder Then
			vFrmPrtObj.Parent = vMsgFolder;
		EndIf;
		vFrmPrtObj.IsActive = True;
		vFrmPrtObj.Remarks = "en='Print tasks and activities';de='Aufgaben und Aktivitäten drucken';ru='Печать задач и действий'";
		vFrmPrtObj.Write();
	EndIf;

EndProcedure // FillReservationPrintGuestGroupRoomsObjectPrintingFormSetings

// -----------------------------------------------------------------------------
Procedure FillCheckInCheckOutActionPictures()
	#If Client Then
		// Reservation check-in action
		vActObj = Catalogs.ObjectFormActions.ReservationFillAccommodation.GetObject();
		vActObj.ActionIcon = New ValueStorage(PictureLib.CheckIn);
		vActObj.Write();
		// Accommodation check-out action
		vActObj = Catalogs.ObjectFormActions.AccommodationCheckOut.GetObject();
		vActObj.ActionIcon = New ValueStorage(PictureLib.CheckOut);
		vActObj.Write();
		// Accommodation group check-out action
		vActObj = Catalogs.ObjectFormActions.AccommodationGuestGroupCheckOut.GetObject();
		vActObj.ActionIcon = New ValueStorage(PictureLib.CheckOut);
		vActObj.Write();
	#EndIf
EndProcedure // FillCheckInCheckOutActionPictures

// -----------------------------------------------------------------------------
Procedure FillAllowedAnnulationDelayTime()
	// Run query to get permission groups
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PermissionGroups.Ref AS Ref
	|FROM
	|	Catalog.PermissionGroups AS PermissionGroups
	|WHERE
	|	(NOT PermissionGroups.DeletionMark)
	|	AND (NOT PermissionGroups.IsFolder)
	|ORDER BY
	|	PermissionGroups.Code";
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vPGObj = vQryRes.Ref.GetObject();
		Try
			vPGObj.AllowedAnnulationDelayTime = 15;
			vPGObj.Write();
		Except
			tcCommonFunctionOnClientServer.TextMessage(TrimAll(vPGObj.Description) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
	EndDo;
EndProcedure // FillAllowedAnnulationDelayTime

// -----------------------------------------------------------------------------
Procedure ClearHotelFromChargingRuleTemplateFolios()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Folios.Folio AS Folio,
	|	Folios.PointInTime AS PointInTime
	|FROM
	|	(SELECT
	|		CustomersChargingRules.ChargingFolio AS Folio,
	|		CustomersChargingRules.ChargingFolio.PointInTime AS PointInTime
	|	FROM
	|		Catalog.Customers.ChargingRules AS CustomersChargingRules
	|	WHERE
	|		CustomersChargingRules.ChargingFolio.Hotel <> &qEmptyHotel
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ContractsChargingRules.ChargingFolio,
	|		ContractsChargingRules.ChargingFolio.PointInTime
	|	FROM
	|		Catalog.Contracts.ChargingRules AS ContractsChargingRules
	|	WHERE
	|		ContractsChargingRules.ChargingFolio.Hotel <> &qEmptyHotel
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ClientsChargingRules.ChargingFolio,
	|		ClientsChargingRules.ChargingFolio.PointInTime
	|	FROM
	|		Catalog.Clients.ChargingRules AS ClientsChargingRules
	|	WHERE
	|		ClientsChargingRules.ChargingFolio.Hotel <> &qEmptyHotel) AS Folios
	|
	|ORDER BY
	|	PointInTime";
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vFolios = vQry.Execute().Unload();
	For Each vFoliosRow In vFolios Do
		vFolioObj = vFoliosRow.Folio.GetObject();
		vFolioObj.Hotel = Catalogs.Hotels.EmptyRef();
		vFolioObj.Write(DocumentWriteMode.Write);
	EndDo;
EndProcedure // ClearHotelFromChargingRuleTemplateFolios

// -----------------------------------------------------------------------------
Procedure FillCustomerGuestsTurnoversReportSettings()
	// Create audit reports group first
	vTotalsReportsFolder = Catalogs.Reports.EmptyRef();
	vQry = New Query();
	vQry.Text = "SELECT
	            |	Reports.Ref
	            |FROM
	            |	Catalog.Reports AS Reports
	            |WHERE
	            |	Reports.Code = &qCode
	            |	AND Reports.IsFolder
	            |	AND (NOT Reports.DeletionMark)";
	vQry.SetParameter("qCode", 500);
	vFolders = vQry.Execute().Unload();
	For Each vFoldersRow In vFolders Do
		vTotalsReportsFolder = vFoldersRow.Ref;
		Break;
	EndDo;
	// Fill report name and report folder for new reports
	vRepRef = Catalogs.Reports.CustomerGuestsTurnovers;
	If ValueIsFilled(vRepRef) And Not ValueIsFilled(vRepRef.Report) Then
		vRepObj = vRepRef.GetObject();
		vRepObj.Report = "CustomerGuestsTurnovers"; 
		vRepObj.Parent = vTotalsReportsFolder;
		vRepObj.SortCode = 522;
		vRepObj.DynamicParameters = "REP.PeriodFrom = BegOfDay(CurrentSessionDate()) - 24*3600;
		                            |REP.PeriodTo = EndOfDay(REP.PeriodFrom);";
		vRepObj.Write();
	EndIf;
EndProcedure // FillCustomerGuestsTurnoversReportSettings

// -----------------------------------------------------------------------------
Procedure FillCustomerInitialBalancesActionSettings()
	vCustomerFolder = Catalogs.ObjectFormActions.FindByCode("1000");
	If TypeOf(Catalogs.ObjectFormActions.CustomerFillCustomerInitialBalances.ObjectType) <> Type("CatalogRef.Customers") Then
		vFrmActObj = Catalogs.ObjectFormActions.CustomerFillCustomerInitialBalances.GetObject();
		vFrmActObj.ObjectType = Catalogs.Customers.EmptyRef();
		If ValueIsFilled(vCustomerFolder) And vCustomerFolder.IsFolder Then
			vFrmActObj.Parent = vCustomerFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Write();
	EndIf;
EndProcedure // FillCustomerInitialBalancesActionSettings

// -----------------------------------------------------------------------------
Procedure FillCustomerGuestsWithServicesReportSettings()
	// Fill report name and report folder for new report
	vRepRef = Catalogs.Reports.CustomerGuestsWithServices;
	If ValueIsFilled(vRepRef) And Not ValueIsFilled(vRepRef.Report) Then
		vRepObj = vRepRef.GetObject();
		vRepObj.Report = "CustomerGuestsWithServices"; 
		vRepObj.SortCode = 159;
		vRepObj.DynamicParameters = "REP.PeriodFrom = BegOfDay(CurrentSessionDate());
		                            |REP.PeriodTo = EndOfDay(CurrentSessionDate());";
		vRepObj.Write();
	EndIf;
EndProcedure // FillCustomerGuestsWithServicesReportSettings 

// -----------------------------------------------------------------------------
Procedure FillLostProfitsReportSettings()
	// Find analysis department reports folder
	vAnalysisDepartmentReportsFolder = Catalogs.Reports.FindByCode(500, , Catalogs.Reports.EmptyRef());
	If ValueIsFilled(vAnalysisDepartmentReportsFolder) And Not vAnalysisDepartmentReportsFolder.IsFolder Then
		vAnalysisDepartmentReportsFolder = Catalogs.Reports.EmptyRef();
	EndIf;
	// Fill report name and report folder for new report
	vRepRef = Catalogs.Reports.LostProfits;
	If ValueIsFilled(vRepRef) And Not ValueIsFilled(vRepRef.Report) Then
		vRepObj = vRepRef.GetObject();
		vRepObj.Parent = vAnalysisDepartmentReportsFolder;
		vRepObj.Report = "LostProfits"; 
		vRepObj.SortCode = 605;
		vRepObj.DynamicParameters = "REP.PeriodFrom = BegOfDay(CurrentSessionDate());
		                            |REP.PeriodTo = EndOfDay(CurrentSessionDate());";
		vRepObj.Write();
	EndIf;
EndProcedure // FillLostProfitsReportSettings 

// -----------------------------------------------------------------------------
Procedure FillIdentificationCardsAuditReportSettings()
	// Find analysis department reports folder
	vAuditReportsFolder = Catalogs.Reports.FindByCode(790, , Catalogs.Reports.EmptyRef());
	If ValueIsFilled(vAuditReportsFolder) And Not vAuditReportsFolder.IsFolder Then
		vAuditReportsFolder = Catalogs.Reports.EmptyRef();
	EndIf;
	// Fill report name and report folder for new report
	vRepRef = Catalogs.Reports.IdentificationCardsAudit;
	If ValueIsFilled(vRepRef) And Not ValueIsFilled(vRepRef.Report) Then
		vRepObj = vRepRef.GetObject();
		vRepObj.Parent = vAuditReportsFolder;
		vRepObj.Report = "IdentificationCardsAudit"; 
		vRepObj.SortCode = 791;
		vRepObj.DynamicParameters = "REP.PeriodFrom = BegOfDay(CurrentSessionDate()) - 24*3600;
		                            |REP.PeriodTo = CurrentSessionDate();";
		vRepObj.Write();
	EndIf;
EndProcedure // FillIdentificationCardsAuditReportSettings

// -----------------------------------------------------------------------------
Procedure FillHotelProductsRegisterReportSettings()
	// Find analysis department reports folder
	vHotelProductsReportsFolder = Catalogs.Reports.FindByCode(1000, , Catalogs.Reports.EmptyRef());
	If ValueIsFilled(vHotelProductsReportsFolder) And Not vHotelProductsReportsFolder.IsFolder Then
		vHotelProductsReportsFolder = Catalogs.Reports.EmptyRef();
	EndIf;
	// Fill report name and report folder for new report
	vRepRef = Catalogs.Reports.HotelProductsRegister;
	If ValueIsFilled(vRepRef) And Not ValueIsFilled(vRepRef.Report) Then
		vRepObj = vRepRef.GetObject();
		vRepObj.Parent = vHotelProductsReportsFolder;
		vRepObj.Report = "HotelProductsRegister"; 
		vRepObj.SortCode = 896;
		vRepObj.DynamicParameters = "REP.PeriodFrom = BegOfMonth(CurrentSessionDate());
		                            |REP.PeriodTo = CurrentSessionDate();";
		vRepObj.Write();
	EndIf;
EndProcedure // FillHotelProductsRegisterReportSettings

// -----------------------------------------------------------------------------
Procedure FillReservationCheckInGuestGroupObjectFormActionSettings()
	vReservationFolder = Catalogs.ObjectFormActions.FindByCode("200");
	If TypeOf(Catalogs.ObjectFormActions.ReservationCheckInGuestGroup.ObjectType) <> Type("DocumentRef.Reservation") Then
		vFrmActObj = Catalogs.ObjectFormActions.ReservationCheckInGuestGroup.GetObject();
		vFrmActObj.ObjectType = Documents.Reservation.EmptyRef();
		If ValueIsFilled(vReservationFolder) And vReservationFolder.IsFolder Then
			vFrmActObj.Parent = vReservationFolder;
		EndIf;
		#If Client Then
			vFrmActObj.ActionIcon = PictureLib.CheckIn;
		#EndIf
		vFrmActObj.Remarks = "en='Start check-in procedure for all guest group guests with check-in date equal to the check-in date of the reservation being opened'; 
		                     |ru='Начать процедуру заселения для всех гостей из группы, у которых дата заезда совпадает с датой заезда открытой брони'";
		vFrmActObj.IsActive = True;
		vFrmActObj.Write();
	EndIf;
EndProcedure // FillReservationCheckInGuestGroupObjectFormActionSettings

// -----------------------------------------------------------------------------
Procedure FillCheckIfReservationsWerePayedInTimeDataProcessorSettings()
	// Fill data processor name and dynamic parameters
	vDPRef = Catalogs.DataProcessors.CheckIfReservationsWerePayedInTime;
	If ValueIsFilled(vDPRef) And Not ValueIsFilled(vDPRef.Processing) Then
		vDPObj = vDPRef.GetObject();
		vDPObj.Processing = "CheckIfReservationsWerePayedInTime"; 
		vDPObj.SortCode = 205;
		vDPObj.DynamicParameters = "If ValueIsFilled(PARM) Then
		                           |	DPO.Hotel = PARM;
		                           |EndIf;";
		vDPObj.Write();
	EndIf;
EndProcedure // FillCheckIfReservationsWerePayedInTimeDataProcessorSettings 

// -----------------------------------------------------------------------------
Procedure FillClientHideNameAndNameHistoryActionSettings()
	vClientFolder = Catalogs.ObjectFormActions.FindByCode("1500");
	If TypeOf(Catalogs.ObjectFormActions.ClientHideNameAndNameHistory.ObjectType) <> Type("CatalogRef.Clients") Then
		vFrmActObj = Catalogs.ObjectFormActions.ClientHideNameAndNameHistory.GetObject();
		vFrmActObj.ObjectType = Catalogs.Clients.EmptyRef();
		If ValueIsFilled(vClientFolder) And vClientFolder.IsFolder Then
			vFrmActObj.Parent = vClientFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Write();
	EndIf;
EndProcedure // FillClientHideNameAndNameHistoryActionSettings

// -----------------------------------------------------------------------------
Procedure FillClientScanClientDataActionSettings()
	vClientFolder = Catalogs.ObjectFormActions.FindByCode("1500");
	If TypeOf(Catalogs.ObjectFormActions.ClientScanClientData.ObjectType) <> Type("CatalogRef.Clients") Then
		vFrmActObj = Catalogs.ObjectFormActions.ClientScanClientData.GetObject();
		vFrmActObj.ObjectType = Catalogs.Clients.EmptyRef();
		If ValueIsFilled(vClientFolder) And vClientFolder.IsFolder Then
			vFrmActObj.Parent = vClientFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.ActionIcon = New ValueStorage(PictureLib.Scaner);
		vFrmActObj.ButtonCaption = NStr("en='Scan passport data'; de='Scan passport data'; ru='Сканировать паспорт'");
		vFrmActObj.ButtonToolTip = NStr("en='Scan client passport data'; de='Scan client passport data'; ru='Сканировать страницы паспорта клиента'");
		vFrmActObj.Write();
		// Update scan accommodation scan client data attributes
		vFrmActObj = Catalogs.ObjectFormActions.AccommodationScanClientData.GetObject();
		vFrmActObj.ActionIcon = New ValueStorage(PictureLib.Scaner);
		vFrmActObj.Write();
	EndIf;
EndProcedure // FillClientScanClientDataActionSettings

// -----------------------------------------------------------------------------
Procedure FillFolioPrintHotelProductObjectPrintFormsSettings()
	vFolioFolder = Catalogs.ObjectPrintingForms.FindByCode("500", False, Catalogs.ObjectPrintingForms.EmptyRef());
	If TypeOf(Catalogs.ObjectPrintingForms.FolioPrintHotelProduct.ObjectType) <> Type("DocumentRef.Folio") Then
		vFrmPrtObj = Catalogs.ObjectPrintingForms.FolioPrintHotelProduct.GetObject();
		vFrmPrtObj.ObjectType = Documents.Folio.EmptyRef();
		If ValueIsFilled(vFolioFolder) And vFolioFolder.IsFolder Then
			vFrmPrtObj.Parent = vFolioFolder;
		EndIf;
		vFrmPrtObj.IsActive = True;
		vFrmPrtObj.Remarks = "en='Print folio hotel product'; ru='Распечатать путевку указанную в лицевом счете'";
		vFrmPrtObj.Write();
	EndIf;
EndProcedure // FillFolioPrintHotelProductObjectPrintFormsSettings

// -----------------------------------------------------------------------------
Procedure FillFolioPrintNonFiscalChequeByCharges()
	vFolioFolder = Catalogs.ObjectPrintingForms.FindByCode("500", False, Catalogs.ObjectPrintingForms.EmptyRef());
	If TypeOf(Catalogs.ObjectPrintingForms.FolioPrintNonFiscalChequeByCharges.ObjectType) <> Type("DocumentRef.Folio") Then
		vFrmPrtObj = Catalogs.ObjectPrintingForms.FolioPrintNonFiscalChequeByCharges.GetObject();
		vFrmPrtObj.ObjectType = Documents.Folio.EmptyRef();
		If ValueIsFilled(vFolioFolder) And vFolioFolder.IsFolder Then
			vFrmPrtObj.Parent = vFolioFolder;
		EndIf;
		vFrmPrtObj.IsActive = True;
		vFrmPrtObj.Remarks = "en='Print charges selected as non fiscal document at cash register'; ru='Распечатать выбранные начисления на ККМ на нефискальном чеке'; de='Ausgewählte dienstleistungen an der Kasse im nonfiscal Kassenbon drucken'";
		vFrmPrtObj.Write();
	EndIf;
EndProcedure // FillFolioPrintNonFiscalChequeByCharges

// -----------------------------------------------------------------------------
Function FillIsHotelProductServiceAttribute()
	vFoundHotelProductServices = False;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	HotelProductSalesTurnovers.Service,
	|	HotelProductSalesTurnovers.SalesTurnover,
	|	HotelProductSalesTurnovers.QuantityTurnover
	|FROM
	|	AccumulationRegister.HotelProductSales.Turnovers AS HotelProductSalesTurnovers
	|
	|ORDER BY
	|	HotelProductSalesTurnovers.Service.SortCode,
	|	HotelProductSalesTurnovers.Service.Description";
	vQryRes = vQry.Execute().Unload();
	For Each vQryResRow In vQryRes Do 
		vSrvObj = vQryResRow.Service.GetObject();
		vSrvObj.IsHotelProductService = True;
		vSrvObj.Write();
		vFoundHotelProductServices = True;
	EndDo;
	Return vFoundHotelProductServices;
EndFunction // FillIsHotelProductServiceAttribute 

// -----------------------------------------------------------------------------
Procedure RepostChargesAndStorno(pPeriodFrom, pPeriodTo)
#If Client Then
	Status(NStr("en='Reposting charges and storno...'; de='Reposting charges and storno...'; ru='Перепроведение начислений и сторно...'"));
#EndIf
	// Run query to get documents
	vStatusMessage = "";
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Charges.Ref AS Document,
	|	Charges.Date AS Date,
	|	Charges.PointInTime AS PointInTime
	|FROM
	|	Document.Charge AS Charges
	|		LEFT JOIN AccumulationRegister.Sales AS SalesMovements
	|		ON Charges.Ref = SalesMovements.Recorder
	|WHERE
	|	Charges.Posted
	|	AND Charges.Date >= &qPeriodFrom
	|	AND Charges.Date <= &qPeriodTo
	|	AND SalesMovements.Recorder IS NULL 
	|
	|UNION ALL
	|
	|SELECT
	|	Storno.Ref,
	|	Storno.Date,
	|	Storno.PointInTime
	|FROM
	|	Document.Storno AS Storno
	|		LEFT JOIN AccumulationRegister.Sales AS SalesMovements
	|		ON Storno.Ref = SalesMovements.Recorder
	|WHERE
	|	Storno.Posted
	|	AND Storno.Date >= &qPeriodFrom
	|	AND Storno.Date <= &qPeriodTo
	|	AND SalesMovements.Recorder IS NULL 
	|
	|ORDER BY
	|	PointInTime";
	vQry.SetParameter("qPeriodFrom", pPeriodFrom);
	vQry.SetParameter("qPeriodTo", pPeriodTo);
	vQryRes = vQry.Execute().Unload();
	vCurDate = '00010101';
	vCount = vQryRes.Count();
	// Repost charges and storno
	vInt = 0;
	For Each vQryResRow In vQryRes Do
		vInt = vInt + 1;
		vCurDocObj = vQryResRow.Document.GetObject();
		Try
			If TypeOf(vCurDocObj.Ref) = Type("DocumentRef.Charge") Then
				If vCurDocObj.Price = 0 And vCurDocObj.Sum <> 0 Then
					If vCurDocObj.Quantity = 0 Then
						vCurDocObj.Quantity = 1;
						vCurDocObj.Price = vCurDocObj.Sum;
					Else
						vCurDocObj.Price = Round(vCurDocObj.Sum/vCurDocObj.Quantity, 2);
					EndIf;
				EndIf;
				If ValueIsFilled(vCurDocObj.Folio) And vCurDocObj.Folio.DeletionMark Then
					vCurDocObj.Folio.GetObject().SetDeletionMark(False);
				EndIf;
			EndIf;
			vCurDocObj.AdditionalProperties.Insert("InfoBaseUpdateMode", True);
			vCurDocObj.Write(DocumentWriteMode.Posting);
		Except
			tcCommonFunctionOnClientServer.TextMessage(String(vCurDocObj) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
		
#If Client Then
		// Status message
		If BegOfDay(vQryResRow.Date) <> vCurDate Then
			vCurDate = BegOfDay(vQryResRow.Date);
			vStatusMessage = NStr("en='Reposting charges and storno at " + Format(vCurDate, "DF=dd.MM.yyyy") + " (" + vInt + " from " + vCount + ") ...'; 
			                      |de='Reposting charges and storno at " + Format(vCurDate, "DF=dd.MM.yyyy") + " (" + vInt + " from " + vCount + ") ...'; 
			                      |ru='Перепроведение начислений и сторно за " + Format(vCurDate, "DF=dd.MM.yyyy") + " (" + vInt + " из " + vCount + ") ...'");
			Status(vStatusMessage);
		EndIf;
		// Wait 2 seconds every 15 charges
		If Int(vInt / 15) = (vInt / 15) Then
			vCurTime = CurrentSessionDate() + 2;
			While vCurTime <= CurrentSessionDate() Do
				Status(NStr("en='Giving 2 seconds to others to work...'; de='Giving 2 seconds to others to work...'; ru='Даем 2 секунды поработать другим...'"));
			EndDo;				
			Status(vStatusMessage);
		EndIf;
		// User interrupt processing
		UserInterruptProcessing();
#EndIf
	EndDo;
EndProcedure // RepostChargesAndStorno

// -----------------------------------------------------------------------------
Procedure RepostSettlements()
#If Client Then
	Status(NStr("en='Reposting settlements...'; de='Reposting settlements...'; ru='Перепроведение актов...'"));
#EndIf
	// Run query to get documents
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Settlements.Ref AS Document,
	|	Settlements.Date AS Date,
	|	Settlements.PointInTime AS PointInTime
	|FROM
	|	Document.Settlement AS Settlements
	|WHERE
	|	Settlements.Posted
	|
	|ORDER BY
	|	Date,
	|	PointInTime";
	vQryRes = vQry.Execute().Unload();
	vCurDate = '00010101';
	vCount = vQryRes.Count();
	// Repost settlements
	i = 0;
	For Each vQryResRow In vQryRes Do
		i = i + 1;
		vCurDocObj = vQryResRow.Document.GetObject();
		For Each vSrvRow In vCurDocObj.Services Do
			If ValueIsFilled(vSrvRow.Charge) Then
				vSrvRow.HotelProduct = vSrvRow.Charge.HotelProduct;
			EndIf;
		EndDo;
		Try
			vCurDocObj.AdditionalProperties.Insert("InfoBaseUpdateMode", True);
			vCurDocObj.Write(DocumentWriteMode.Posting);
		Except
			tcCommonFunctionOnClientServer.TextMessage(String(vCurDocObj) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
		
#If Client Then
		// Status message
		If BegOfDay(vQryResRow.Date) <> vCurDate Then
			vCurDate = BegOfDay(vQryResRow.Date);
			Status(NStr("en='Reposting settlements at " + Format(vCurDate, "DF=dd.MM.yyyy") + " (" + i + " from " + vCount + ") ...'; 
			            |de='Reposting settlements at " + Format(vCurDate, "DF=dd.MM.yyyy") + " (" + i + " from " + vCount + ") ...'; 
			            |ru='Перепроведение актов за " + Format(vCurDate, "DF=dd.MM.yyyy") + " (" + i + " из " + vCount + ") ...'"));
		EndIf;
		UserInterruptProcessing();
#EndIf
	EndDo;
EndProcedure // RepostSettlements

// -----------------------------------------------------------------------------
Procedure ConvertQueryText(vQueryText)
	vQueryText = StrReplace(vQueryText, "AccumulationRegister.CustomerSalesForecast", "AccumulationRegister.SalesForecast");
	vQueryText = StrReplace(vQueryText, "AccumulationRegister.CustomerSales", "AccumulationRegister.Sales");
	vQueryText = StrReplace(vQueryText, "AccumulationRegister.ResourceSalesForecast", "AccumulationRegister.SalesForecast");
	vQueryText = StrReplace(vQueryText, "AccumulationRegister.ResourceSales", "AccumulationRegister.Sales");
	vQueryText = StrReplace(vQueryText, "AccumulationRegister.RoomSalesForecast", "AccumulationRegister.SalesForecast");
	vQueryText = StrReplace(vQueryText, "AccumulationRegister.RoomSales", "AccumulationRegister.Sales");
	vQueryText = StrReplace(vQueryText, "AccumulationRegister.ServiceSalesForecast", "AccumulationRegister.SalesForecast");
	vQueryText = StrReplace(vQueryText, "AccumulationRegister.ServiceSales", "AccumulationRegister.Sales");
	vQueryText = StrReplace(vQueryText, "AccumulationRegister.GeographicSales", "AccumulationRegister.Sales");
	vQueryText = StrReplace(vQueryText, "ResourceSalesForecast.Sum AS", "ResourceSalesForecast.Sales AS");
	vQueryText = StrReplace(vQueryText, "ResourceSalesForecast.SumWithoutVAT AS", "ResourceSalesForecast.SalesWithoutVAT AS");
	vQueryText = StrReplace(vQueryText, "ResourceSales.SumTurnover AS", "ResourceSales.SalesTurnover AS");
	vQueryText = StrReplace(vQueryText, "ResourceSales.SumWithoutVATTurnover AS", "ResourceSales.SalesWithoutVATTurnover AS");
	vQueryText = StrReplace(vQueryText, "ResourceSalesForecastTurnovers.SumTurnover", "ResourceSalesForecastTurnovers.SalesTurnover");
	vQueryText = StrReplace(vQueryText, "ResourceSalesForecastTurnovers.SumWithoutVATTurnover", "ResourceSalesForecastTurnovers.SalesWithoutVATTurnover");
	vQueryText = StrReplace(vQueryText, "ResourceSalesTurnovers.SumTurnover", "ResourceSalesTurnovers.SalesTurnover");
	vQueryText = StrReplace(vQueryText, "ResourceSalesTurnovers.SumWithoutVATTurnover", "ResourceSalesTurnovers.SalesWithoutVATTurnover");
	vQueryText = StrReplace(vQueryText, "ResourceSales.Sum AS", "ResourceSales.Sales AS");
	vQueryText = StrReplace(vQueryText, "ResourceSales.SumWithoutVAT AS", "ResourceSales.SalesWithoutVAT AS");
	vQueryText = StrReplace(vQueryText, "ResourceSalesForecast.Sum,", "ResourceSalesForecast.Sales,");
	vQueryText = StrReplace(vQueryText, "ResourceSalesForecast.SumWithoutVAT,", "ResourceSalesForecast.SalesWithoutVAT,");
	vQueryText = StrReplace(vQueryText, "ResourceSales.Sum,", "ResourceSales.Sales,");
	vQueryText = StrReplace(vQueryText, "ResourceSales.SumWithoutVAT,", "ResourceSales.SalesWithoutVAT,");
	vQueryText = StrReplace(vQueryText, "ServiceSalesForecast.SumTurnover", "ServiceSalesForecast.SalesTurnover");
	vQueryText = StrReplace(vQueryText, "ServiceSalesForecast.SumWithoutVATTurnover", "ServiceSalesForecast.SalesWithoutVATTurnover");
	vQueryText = StrReplace(vQueryText, "ServiceSales.Sum", "ServiceSales.Sales");
	vQueryText = StrReplace(vQueryText, "ServiceSales.SumWithoutVAT", "ServiceSales.SalesWithoutVAT");
	vQueryText = StrReplace(vQueryText, "ServiceSalesForecast.Sum", "ServiceSalesForecast.Sales");
	vQueryText = StrReplace(vQueryText, "ServiceSalesForecast.SumWithoutVAT", "ServiceSalesForecast.SalesWithoutVAT");
	vQueryText = StrReplace(vQueryText, "RoomQuotaSales.Agent", "RoomQuotaSales.RoomQuota.Agent");
	vQueryText = StrReplace(vQueryText, "RoomQuotaSales.Customer", "RoomQuotaSales.RoomQuota.Customer");
	vQueryText = StrReplace(vQueryText, "RoomQuotaSales.Contract", "RoomQuotaSales.RoomQuota.Contract");
	If Find(vQueryText, "AccumulationRegister.RoomQuotaSales.BalanceAndTurnovers(") > 0 Then
		vQueryText = StrReplace(vQueryText, "AND (Agent IN HIERARCHY (&qAgent)", "AND (RoomQuota.Agent IN HIERARCHY (&qAgent)");
		vQueryText = StrReplace(vQueryText, "AND (Customer IN HIERARCHY (&qCustomer)", "AND (RoomQuota.Customer IN HIERARCHY (&qCustomer)");
		vQueryText = StrReplace(vQueryText, "AND (Contract = &qContract", "AND (RoomQuota.Contract = &qContract");
	EndIf;
EndProcedure // ConvertQueryText 

// -----------------------------------------------------------------------------
Procedure ConvertAttributeQueryText(vQueryText, pOldAttributeName, pNewAttributeName)
	vQueryText = StrReplace(vQueryText, pOldAttributeName, pNewAttributeName);
EndProcedure // ConvertAttributeQueryText

// -----------------------------------------------------------------------------
Procedure ConvertReports()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reports.Ref AS Ref
	|FROM
	|	Catalog.Reports AS Reports
	|WHERE
	|	NOT Reports.IsFolder
	|	AND NOT Reports.DeletionMark";
	vQryRes = vQry.Execute().Unload();
	For Each vQryResRow In vQryRes Do
		vRep = vQryResRow.Ref;
		vRB = New ReportBuilder();
		// Process static parameters if are filled
		vStatic = vRep.StaticParameters.Get();
		If vStatic <> Undefined Then
			Try
				vRBS = vStatic.ReportBuilderSettings;
			Except
				Continue;
			EndTry;
			Try
				// Load report builder settings
				If vStatic.ReportBuilderSettings <> Undefined Then
					// Update base query text
					vQueryText = vStatic.QueryText;
					ConvertQueryText(vQueryText);
					vStatic.QueryText = vQueryText;
					vRB.Text = vStatic.QueryText;
					vRB.SetSettings(vStatic.ReportBuilderSettings, True, True, True, True, True);
					vRB.Execute();
					vStatic.Insert("ReportBuilderSettings", vRB.GetSettings(True, True, True, True, True));
				EndIf;
			Except
				vErrorText = ErrorDescription();
				WriteLogEvent("InfoBaseUpdate.ConverReports", EventLogLevel.Warning, , , TrimAll(vRep.Code) + " - " + cmNStr(vRep.Description) + ": " + vErrorText);
				Continue;
			EndTry;
		EndIf;
		// Process dynamic parameters if are filled
		vDynamic = TrimAll(vRep.DynamicParameters);
		If Not IsBlankString(vDynamic) Then
			ConvertQueryText(vDynamic);
		EndIf;
		// Update report
		vRepObj = vRep.GetObject();
		vRepObj.StaticParameters = New ValueStorage(vStatic);
		vRepObj.DynamicParameters = vDynamic;
		vRepObj.Write();
	EndDo;
EndProcedure // ConvertReports

// -----------------------------------------------------------------------------
Procedure ConvertAttributeNameInReports(pReportName, pOldAttributeName, pNewAttributeName)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reports.Ref AS Ref
	|FROM
	|	Catalog.Reports AS Reports
	|WHERE
	|	NOT Reports.IsFolder
	|	AND (Reports.Report = &qReportName
	|				AND &qReportName <> ""<EXTERNAL>""
	|			OR Reports.Report REFS Catalog.ExternalDataProcessors
	|				AND &qReportName = ""<EXTERNAL>"")
	|	AND NOT Reports.DeletionMark";
	vQry.SetParameter("qReportName", pReportName);
	vQryRes = vQry.Execute().Unload();
	For Each vQryResRow In vQryRes Do
		vRep = vQryResRow.Ref;
		vRB = New ReportBuilder();
		// Process static parameters if are filled
		vStatic = vRep.StaticParameters.Get();
		If vStatic <> Undefined Then
			Try
				vRBS = vStatic.ReportBuilderSettings;
			Except
				Continue;
			EndTry;
			Try
				// Load report builder settings
				If vStatic.ReportBuilderSettings <> Undefined Then
					// Update base query text
					vQueryText = vStatic.QueryText;
					ConvertAttributeQueryText(vQueryText, pOldAttributeName, pNewAttributeName);
					vStatic.QueryText = vQueryText;
					vRB.Text = vStatic.QueryText;
					vRB.SetSettings(vStatic.ReportBuilderSettings, True, True, True, True, True);
					vRB.Execute();
					vStatic.Insert("ReportBuilderSettings", vRB.GetSettings(True, True, True, True, True));
				EndIf;
			Except
				vErrorText = ErrorDescription();
				WriteLogEvent("InfoBaseUpdate.ConverReports", EventLogLevel.Warning, , , TrimAll(vRep.Code) + " - " + cmNStr(vRep.Description) + ": " + vErrorText);
				Continue;
			EndTry;
		EndIf;
		// Process dynamic parameters if are filled
		vDynamic = TrimAll(vRep.DynamicParameters);
		If Not IsBlankString(vDynamic) Then
			ConvertAttributeQueryText(vDynamic, pOldAttributeName, pNewAttributeName);
		EndIf;
		// Update report
		vRepObj = vRep.GetObject();
		vRepObj.StaticParameters = New ValueStorage(vStatic);
		vRepObj.DynamicParameters = vDynamic;
		vRepObj.Write();
	EndDo;
EndProcedure // ConvertAttributeNameInReports

// -----------------------------------------------------------------------------
Procedure FillClientsAgeRegionAndCity()
	// Get all client items
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Clients.Ref AS Ref
	|FROM
	|	Catalog.Clients AS Clients
	|WHERE
	|	NOT Clients.DeletionMark
	|	AND NOT Clients.IsFolder
	|
	|ORDER BY
	|	Clients.Code";
	vQryRes = vQry.Execute().Unload();
	vCount = vQryRes.Count();
	i = 0;
	For Each vQryResRow In vQryRes Do
		i = i + 1;
		vCltObj = vQryResRow.Ref.GetObject();
		vCltObj.Write();
		
		
#If Client Then
		// Status message
		Status(NStr("en='Processing clients (" + i + " from " + vCount + ") ...'; 
		            |de='Processing clients (" + i + " from " + vCount + ") ...'; 
					|ru='Обработка клиентов (" + i + " из " + vCount + ") ...'"));
		UserInterruptProcessing();
#EndIf
	EndDo;
EndProcedure // FillClientsAgeRegionAndCity

// -----------------------------------------------------------------------------
Procedure FillForeignerRegistryRecordPrintForeignerCardFormObjectPrintFormsSettings()
	vForeignerFolder = Catalogs.ObjectPrintingForms.FindByCode("300", False, Catalogs.ObjectPrintingForms.EmptyRef());
	If TypeOf(Catalogs.ObjectPrintingForms.ForeignerRegistryRecordPrintForeignerCardForm.ObjectType) <> Type("DocumentRef.ForeignerRegistryRecord") Then
		vFrmPrtObj = Catalogs.ObjectPrintingForms.ForeignerRegistryRecordPrintForeignerCardForm.GetObject();
		vFrmPrtObj.ObjectType = Documents.ForeignerRegistryRecord.EmptyRef();
		If ValueIsFilled(vForeignerFolder) And vForeignerFolder.IsFolder Then
			vFrmPrtObj.Parent = vForeignerFolder;
		EndIf;
		vFrmPrtObj.IsActive = True;
		vFrmPrtObj.Remarks = "";
		vFrmPrtObj.Write();
	EndIf;
EndProcedure // FillForeignerRegistryRecordPrintForeignerCardFormObjectPrintFormsSettings

// -----------------------------------------------------------------------------
Procedure FillFolioPrint3GFormObjectPrintFormsSettings()
	vFolioFolder = Catalogs.ObjectPrintingForms.FindByCode("500", False, Catalogs.ObjectPrintingForms.EmptyRef());
	If TypeOf(Catalogs.ObjectPrintingForms.FolioPrint3GForm.ObjectType) <> Type("DocumentRef.Folio") Then
		vFrmPrtObj = Catalogs.ObjectPrintingForms.FolioPrint3GForm.GetObject();
		vFrmPrtObj.ObjectType = Documents.Folio.EmptyRef();
		If ValueIsFilled(vFolioFolder) And vFolioFolder.IsFolder Then
			vFrmPrtObj.Parent = vFolioFolder;
		EndIf;
		vFrmPrtObj.IsActive = False; // Not to be used by default
		vFrmPrtObj.Remarks = "en='Print current payment 3-G form'; ru='Распечатать выбранный платеж на бланке формы 3-Г'";
		vFrmPrtObj.Write();
	EndIf;
EndProcedure // FillFolioPrint3GFormObjectPrintFormsSettings

// -----------------------------------------------------------------------------
Procedure FillIssueHotelProductsPrintHotelProductsLogPrintFormSettings()
	vFolder = Catalogs.ObjectPrintingForms.FindByCode("1600", False, Catalogs.ObjectPrintingForms.EmptyRef());
	If TypeOf(Catalogs.ObjectPrintingForms.IssueHotelProductsPrintHotelProductsLog.ObjectType) <> Type("DocumentRef.IssueHotelProducts") Then
		vFrmPrtObj = Catalogs.ObjectPrintingForms.IssueHotelProductsPrintHotelProductsLog.GetObject();
		vFrmPrtObj.ObjectType = Documents.IssueHotelProducts.EmptyRef();
		If ValueIsFilled(vFolder) And vFolder.IsFolder Then
			vFrmPrtObj.Parent = vFolder;
		EndIf;
		vFrmPrtObj.IsActive = True;
		vFrmPrtObj.Write();
	EndIf;
EndProcedure // FillIssueHotelProductsPrintHotelProductsLogPrintFormSettings

// -----------------------------------------------------------------------------
Procedure FillExpectedGuestGroupsReportSettings()
	// Fill report name and report folder for new report
	vRepRef = Catalogs.Reports.ExpectedGuestGroups;
	If ValueIsFilled(vRepRef) And Not ValueIsFilled(vRepRef.Report) Then
		vRepObj = vRepRef.GetObject();
		vRepObj.Report = "ExpectedGuestGroups"; 
		vRepObj.SortCode = 240;
		vRepObj.DynamicParameters = "REP.PeriodFrom = BegOfDay(CurrentSessionDate());
		                            |REP.PeriodTo = EndOfMonth(EndOfMonth(CurrentSessionDate()) + 1);";
		vRepObj.DefaultSettings = New ValueStorage(cmReadReportDefaultSettingFromTemplate(vRepObj));
		vRepObj.Write();
	EndIf;
EndProcedure // FillExpectedGuestGroupsReportSettings 

// -----------------------------------------------------------------------------
Procedure FillGiftCertificatesSalesTurnoversReportSettings()
	// Fill report name and report folder for new report
	vRepRef = Catalogs.Reports.GiftCertificatesSalesTurnovers;
	If ValueIsFilled(vRepRef) And Not ValueIsFilled(vRepRef.Report) Then
		vRepObj = vRepRef.GetObject();
		vRepObj.Report = "GiftCertificatesSalesTurnovers"; 
		vRepObj.SortCode = 975;
		vRepObj.DynamicParameters = "REP.PeriodFrom = BegOfDay(CurrentSessionDate());
		                            |REP.PeriodTo = EndOfMonth(EndOfMonth(CurrentSessionDate()) + 1);";
		vRepObj.DefaultSettings = New ValueStorage(cmReadReportDefaultSettingFromTemplate(vRepObj));
		vRepObj.Write();
	EndIf;
EndProcedure // FillExpectedGuestGroupsReportSettings

// -----------------------------------------------------------------------------
Procedure FillRosstatForm1MainIndicatorsReportSettings()
	// Fill report name and report folder for new report
	vRepRef = Catalogs.Reports.RosstatForm1MainIndicators;
	If ValueIsFilled(vRepRef) And Not ValueIsFilled(vRepRef.Report) Then
		vRepObj = vRepRef.GetObject();
		vRepObj.Report = "RosstatForm1MainIndicators"; 
		vRepObj.Parent = Catalogs.Reports.FindByCode(800, , Catalogs.Reports.EmptyRef());
		vRepObj.SortCode = 835;
		vRepObj.DynamicParameters = "REP.PeriodFrom = AddMonth(BegOfMonth(CurrentSessionDate()), -1);
		                            |REP.PeriodTo = EndOfMonth(REP.PeriodFrom);";
		vRepObj.DefaultSettings = New ValueStorage(cmReadReportDefaultSettingFromTemplate(vRepObj));
		vRepObj.Write();
	EndIf;
EndProcedure // FillRosstatForm1MainIndicatorsReportSettings

// -----------------------------------------------------------------------------
Procedure SetRosstatReportsDynamicParameters()
	Try
		vRepRef = Catalogs.Reports.RosstatForm1Year;
		If ValueIsFilled(vRepRef) Then
			vRepObj = vRepRef.GetObject();
			vRepObj.DynamicParameters = "REP.PeriodFrom = AddMonth(BegOfYear(CurrentSessionDate()), -12);
			                            |REP.PeriodTo = EndOfYear(REP.PeriodFrom);";
			vRepObj.Write();
		EndIf;

		vRepRef = Catalogs.Reports.RosstatForm1Quarterly;
		If ValueIsFilled(vRepRef) Then
			vRepObj = vRepRef.GetObject();
			vRepObj.DynamicParameters = "REP.PeriodFrom = AddMonth(BegOfMonth(CurrentSessionDate()), -3);
			                            |REP.PeriodTo = BegOfMonth(CurrentSessionDate()) - 1;";
			vRepObj.Write();
		EndIf;

		vRepRef = Catalogs.Reports.RosstatForm1MainIndicators;
		If ValueIsFilled(vRepRef) Then
			vRepObj = vRepRef.GetObject();
			vRepObj.DynamicParameters = "REP.PeriodFrom = AddMonth(BegOfMonth(CurrentSessionDate()), -1);
			                            |REP.PeriodTo = EndOfMonth(REP.PeriodFrom);";
			vRepObj.Write();
		EndIf;
	Except
	EndTry;
EndProcedure // SetRosstatReportsDynamicParameters

// -----------------------------------------------------------------------------
Procedure FillReservationsNoShowReportSettings()
	// Fill report name and report folder for new report
	vRepRef = Catalogs.Reports.ReservationsNoShow;
	If ValueIsFilled(vRepRef) And Not ValueIsFilled(vRepRef.Report) Then
		vRepObj = vRepRef.GetObject();
		vRepObj.Report = "ReservationsHistory"; 
		vRepObj.SortCode = 227;
		vRepObj.DynamicParameters = "REP.PeriodFrom = BegOfDay(CurrentSessionDate()) - 24*3600;
		                            |REP.PeriodTo = EndOfDay(REP.PeriodFrom);";
		vRepObj.DefaultSettings = New ValueStorage(ThisObject.GetTemplate("ReservationsNoShowReportDefaultSettings"));
		vRepObj.Write();
	EndIf;
EndProcedure // FillReservationsNoShowReportSettings

// -----------------------------------------------------------------------------
Procedure FillReservationAnnulationsReportSettings()
	// Fill report name and report folder for new report
	vRepRef = Catalogs.Reports.ReservationAnnulations;
	vAuditFolder = Catalogs.Reports.FindByCode(790, , Catalogs.Reports.EmptyRef());
	If ValueIsFilled(vRepRef) And Not ValueIsFilled(vRepRef.Report) Then
		vRepObj = vRepRef.GetObject();
		vRepObj.Report = "ReservationAnnulations"; 
		If ValueIsFilled(vAuditFolder) And vAuditFolder.IsFolder Then
			vRepObj.Parent = vAuditFolder;
		EndIf;
		vRepObj.SortCode = 793;
		vRepObj.DynamicParameters = "REP.PeriodFrom = BegOfDay(CurrentSessionDate()) - 24*3600;
		                            |REP.PeriodTo = EndOfDay(REP.PeriodFrom);";
		vRepObj.DefaultSettings = New ValueStorage(ThisObject.GetTemplate("ReservationAnnulationsReportDefaultSettings"));
		vRepObj.Write();
	EndIf;
EndProcedure // FillReservationAnnulationsReportSettings

// -----------------------------------------------------------------------------
Procedure FillAgeRanges()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	AgeRanges.Ref AS Ref
	|FROM
	|	Catalog.AgeRanges AS AgeRanges";
	vQryRes = vQry.Execute().Unload();
	If vQryRes.Count() = 0 Then
		vAgeRangeObj = Catalogs.AgeRanges.CreateItem();
		vAgeRangeObj.Code = "CHLD";
		vAgeRangeObj.Description = "Ребенок";
		vAgeRangeObj.FromAge = 1;
		vAgeRangeObj.ToAge = 14;
		vAgeRangeObj.Write();
		
		vAgeRangeObj = Catalogs.AgeRanges.CreateItem();
		vAgeRangeObj.Code = "TEEN";
		vAgeRangeObj.Description = "Тинейджер";
		vAgeRangeObj.FromAge = 15;
		vAgeRangeObj.ToAge = 21;
		vAgeRangeObj.Write();
		
		vAgeRangeObj = Catalogs.AgeRanges.CreateItem();
		vAgeRangeObj.Code = "22-29";
		vAgeRangeObj.Description = "От 22 до 29";
		vAgeRangeObj.FromAge = 22;
		vAgeRangeObj.ToAge = 29;
		vAgeRangeObj.Write();
		
		vAgeRangeObj = Catalogs.AgeRanges.CreateItem();
		vAgeRangeObj.Code = "30-39";
		vAgeRangeObj.Description = "От 30 до 39";
		vAgeRangeObj.FromAge = 30;
		vAgeRangeObj.ToAge = 39;
		vAgeRangeObj.Write();
		
		vAgeRangeObj = Catalogs.AgeRanges.CreateItem();
		vAgeRangeObj.Code = "40-49";
		vAgeRangeObj.Description = "От 40 до 49";
		vAgeRangeObj.FromAge = 40;
		vAgeRangeObj.ToAge = 49;
		vAgeRangeObj.Write();
		
		vAgeRangeObj = Catalogs.AgeRanges.CreateItem();
		vAgeRangeObj.Code = "50-59";
		vAgeRangeObj.Description = "От 50 до 59";
		vAgeRangeObj.FromAge = 50;
		vAgeRangeObj.ToAge = 59;
		vAgeRangeObj.Write();
		
		vAgeRangeObj = Catalogs.AgeRanges.CreateItem();
		vAgeRangeObj.Code = "60";
		vAgeRangeObj.Description = "Старше 60";
		vAgeRangeObj.FromAge = 60;
		vAgeRangeObj.ToAge = 150;
		vAgeRangeObj.Write();
	EndIf;
EndProcedure // FillAgeRanges

// -----------------------------------------------------------------------------
Procedure FillCustomersDoNotPostCommission()
	// Process hotels
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Hotels.Ref AS Ref,
	|	Hotels.Code AS Code
	|FROM
	|	Catalog.Hotels AS Hotels
	|WHERE
	|	(NOT Hotels.DeletionMark)
	|	AND (NOT Hotels.IsFolder)
	|	AND (NOT Hotels.DoNotPostCommission)
	|
	|ORDER BY
	|	Code";
	vQryRes = vQry.Execute().Unload();
	For Each vQryResRow In vQryRes Do
		vItemObj = vQryResRow.Ref.GetObject();
		vItemObj.DoNotPostCommission = True;
		vItemObj.Write();
	EndDo;
	// Process customers
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Customers.Ref AS Ref,
	|	Customers.CreateDate AS CreateDate,
	|	Customers.Code AS Code
	|FROM
	|	Catalog.Customers AS Customers
	|WHERE
	|	NOT Customers.DeletionMark
	|	AND NOT Customers.IsFolder
	|	AND NOT Customers.DoNotPostCommission
	|
	|ORDER BY
	|	CreateDate,
	|	Code";
	vQry.SetParameter("qEmptyAgentCommissionType", Enums.AgentCommissionTypes.EmptyRef());
	vQryRes = vQry.Execute().Unload();
	vCount = vQryRes.Count();
	For Each vQryResRow In vQryRes Do
		vItemObj = vQryResRow.Ref.GetObject();
		vItemObj.DoNotPostCommission = True;
		vItemObj.Write();
		// Write to the change history
		If TypeOf(vQryResRow.Ref) = Type("CatalogRef.Customers") Then
			vItemObj.pmWriteToCustomerChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		EndIf;
		// Status
		#If Client Then
			Status(NStr("en='Processed ';ru='Обработано ';de='Bearbeitet '") + (vQryRes.IndexOf(vQryResRow)+1) + NStr("en=' from '; de=' von '; ru=' из '") + vCount);
			UserInterruptProcessing();
		#EndIf
	EndDo;
EndProcedure // FillCustomersDoNotPostCommission

// -----------------------------------------------------------------------------
Procedure FillInvoicePrintPaymentOrderObjectPrintFormsSettings()
	vInvoiceFolder = Catalogs.ObjectPrintingForms.FindByCode("800", False, Catalogs.ObjectPrintingForms.EmptyRef());
	If TypeOf(Catalogs.ObjectPrintingForms.InvoicePrintPaymentOrder.ObjectType) <> Type("DocumentRef.ProformaInvoice") Then
		vFrmPrtObj = Catalogs.ObjectPrintingForms.InvoicePrintPaymentOrder.GetObject();
		vFrmPrtObj.ObjectType = Documents.ProformaInvoice.EmptyRef();
		If ValueIsFilled(vInvoiceFolder) And vInvoiceFolder.IsFolder Then
			vFrmPrtObj.Parent = vInvoiceFolder;
		EndIf;
		vFrmPrtObj.IsActive = True;
		vFrmPrtObj.Remarks = "";
		vFrmPrtObj.Write();
	EndIf;
EndProcedure // FillInvoicePrintPaymentOrderObjectPrintFormsSettings

// -----------------------------------------------------------------------------
Procedure Fill121122UserPermission()
	// Run query to get permission groups
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PermissionGroups.Ref AS Ref
	|FROM
	|	Catalog.PermissionGroups AS PermissionGroups
	|WHERE
	|	(NOT PermissionGroups.DeletionMark)
	|	AND (NOT PermissionGroups.IsFolder)
	|ORDER BY
	|	PermissionGroups.Code";
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vPGObj = vQryRes.Ref.GetObject();
		Try
			vPGObj.HavePermissionToCreateReservationsWithoutContactClientAndCustomerData = True;
			If vPGObj.HavePermissionToManageRoomInventory Then
				vPGObj.HavePermissionToManageAllotments = True;
			EndIf;
			vPGObj.Write();
		Except
			tcCommonFunctionOnClientServer.TextMessage(TrimAll(vPGObj.Description) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
	EndDo;
EndProcedure // Fill121122UserPermission

// -----------------------------------------------------------------------------
Procedure FillCustomerAdvanceDistributionActionSettings()
	vCustomerFolder = Catalogs.ObjectFormActions.FindByCode("1000");
	vFrmActObj = Catalogs.ObjectFormActions.CustomerFillCustomerAdvanceDistribution.GetObject();
	vFrmActObj.ObjectType = Catalogs.Customers.EmptyRef();
	If ValueIsFilled(vCustomerFolder) And vCustomerFolder.IsFolder Then
		vFrmActObj.Parent = vCustomerFolder;
	EndIf;
	vFrmActObj.IsActive = True;
	vFrmActObj.ButtonCaption = "EN='Customer advance distribution (Ctrl+F10)'; RU='Распределение аванса (Ctrl+F10)'";
	vFrmActObj.ButtonToolTip = "EN='New customer advance distribution'; RU='Новое распределение аванса контрагента'";
	vFrmActObj.Remarks = "EN='Create new customer advance distribution'; RU='Создать новый документ распределения аванса контрагента'";
	vFrmActObj.Write();
EndProcedure // FillCustomerAdvanceDistributionActionSettings

// -----------------------------------------------------------------------------
Procedure FillContractAdvanceDistributionActionSettings()
	vContractFolder = Catalogs.ObjectFormActions.FindByCode("1100");
	vFrmActObj = Catalogs.ObjectFormActions.ContractFillCustomerAdvanceDistribution.GetObject();
	vFrmActObj.ObjectType = Catalogs.Contracts.EmptyRef();
	If ValueIsFilled(vContractFolder) And vContractFolder.IsFolder Then
		vFrmActObj.Parent = vContractFolder;
	EndIf;
	vFrmActObj.IsActive = True;
	vFrmActObj.ButtonCaption = "EN='Customer advance distribution (Ctrl+F10)'; RU='Распределение аванса (Ctrl+F10)'";
	vFrmActObj.ButtonToolTip = "EN='New customer advance distribution'; RU='Новое распределение аванса контрагента'";
	vFrmActObj.Remarks = "EN='Create new customer advance distribution'; RU='Создать новый документ распределения аванса контрагента'";
	vFrmActObj.Write();
EndProcedure // FillContractAdvanceDistributionActionSettings

// -----------------------------------------------------------------------------
Procedure Fill124UserPermission()
	// Run query to get permission groups
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PermissionGroups.Ref AS Ref
	|FROM
	|	Catalog.PermissionGroups AS PermissionGroups
	|WHERE
	|	(NOT PermissionGroups.DeletionMark)
	|	AND (NOT PermissionGroups.IsFolder)
	|ORDER BY
	|	PermissionGroups.Code";
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vPGObj = vQryRes.Ref.GetObject();
		Try
			vPGObj.HavePermissionToIgnoreAccommodationTemplates = True;
			vPGObj.Write();
		Except
			tcCommonFunctionOnClientServer.TextMessage(TrimAll(vPGObj.Description) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
	EndDo;
EndProcedure // Fill124UserPermission

// -----------------------------------------------------------------------------
Procedure FillFolioPrintChargePrintFormsSettings()
	vFolioFolder = Catalogs.ObjectPrintingForms.FindByCode("500", False, Catalogs.ObjectPrintingForms.EmptyRef());
	If TypeOf(Catalogs.ObjectPrintingForms.FolioPrintChargeRu.ObjectType) <> Type("DocumentRef.Folio") Then
		vFrmPrtObj = Catalogs.ObjectPrintingForms.FolioPrintChargeRu.GetObject();
		vFrmPrtObj.ObjectType = Documents.Folio.EmptyRef();
		If ValueIsFilled(vFolioFolder) And vFolioFolder.IsFolder Then
			vFrmPrtObj.Parent = vFolioFolder;
		EndIf;
		vFrmPrtObj.IsActive = True;
		vFrmPrtObj.Language = Catalogs.Languages.RU;
		vFrmPrtObj.Remarks = "en='Print selected charge details in Russian'; ru='Распечатать детализацию по выбранному в лицевом счете начислению по русски'";
		vFrmPrtObj.Write();
	EndIf;
	If TypeOf(Catalogs.ObjectPrintingForms.FolioPrintChargeEn.ObjectType) <> Type("DocumentRef.Folio") Then
		vFrmPrtObj = Catalogs.ObjectPrintingForms.FolioPrintChargeEn.GetObject();
		vFrmPrtObj.ObjectType = Documents.Folio.EmptyRef();
		If ValueIsFilled(vFolioFolder) And vFolioFolder.IsFolder Then
			vFrmPrtObj.Parent = vFolioFolder;
		EndIf;
		vFrmPrtObj.IsActive = True;
		vFrmPrtObj.Language = Catalogs.Languages.EN;
		vFrmPrtObj.Remarks = "en='Print selected charge details in English'; ru='Распечатать детализацию по выбранному в лицевом счете начислению по английски'";
		vFrmPrtObj.Write();
	EndIf;
EndProcedure // FillFolioPrintChargePrintFormsSettings

// -----------------------------------------------------------------------------
Procedure FillAccommodationFillInvoiceActionSettings()
	vAccommodationFolder = Catalogs.ObjectFormActions.FindByCode("100");
	If TypeOf(Catalogs.ObjectFormActions.AccommodationFillInvoice.ObjectType) <> Type("DocumentRef.Accommodation") Then
		vFrmActObj = Catalogs.ObjectFormActions.AccommodationFillInvoice.GetObject();
		vFrmActObj.ObjectType = Documents.Accommodation.EmptyRef();
		If ValueIsFilled(vAccommodationFolder) And vAccommodationFolder.IsFolder Then
			vFrmActObj.Parent = vAccommodationFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Write();
	EndIf;
	If TypeOf(Catalogs.ObjectFormActions.AccommodationGuestGroupFillInvoice.ObjectType) <> Type("DocumentRef.Accommodation") Then
		vFrmActObj = Catalogs.ObjectFormActions.AccommodationGuestGroupFillInvoice.GetObject();
		vFrmActObj.ObjectType = Documents.Accommodation.EmptyRef();
		If ValueIsFilled(vAccommodationFolder) And vAccommodationFolder.IsFolder Then
			vFrmActObj.Parent = vAccommodationFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Write();
	EndIf;
EndProcedure // FillAccommodationFillInvoiceActionSettings

// -----------------------------------------------------------------------------
Procedure FillGuestsWithBirthDayReportSettings()
	// Fill report parameters
	vRepRef = Catalogs.Reports.FindByCode(103);
	If ValueIsFilled(vRepRef) And vRepRef.Report <> "GuestsWithBirthday" Then
		vRepObj = vRepRef.GetObject();
		vRepObj.Description = "EN='Guests with birthday'; RU='Гости, у которых день рождения'";
		vRepObj.Report = "GuestsWithBirthday"; 
		vRepObj.SortCode = 103;
		vRepObj.DynamicParameters = "REP.PeriodFrom = BegOfDay(CurrentSessionDate());
		                            |REP.PeriodTo = EndOfDay(REP.PeriodFrom);";
		vRepObj.DefaultSettings = New ValueStorage(ThisObject.GetTemplate("GuestsWithBirthdayReportDefaultSettings"));
		vRepObj.Write();
	EndIf;
EndProcedure // FillGuestsWithBirthDayReportSettings

// -----------------------------------------------------------------------------
Procedure FillActiveReservationsSortCode()
#If Client Then
	Status(NStr("en='Fill reservation sort codes...'; de='Fill reservation sort codes...'; ru='Заполнение кода сортировки у действующей брони...'"));
#EndIf
	// Run query to get active reservations
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservation.Ref AS Document,
	|	Reservation.Date AS Date,
	|	Reservation.PointInTime AS PointInTime
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.ReservationStatus.IsActive
	|	AND Reservation.Posted
	|ORDER BY
	|	PointInTime";
	vQryRes = vQry.Execute().Unload();
	vCurDate = '00010101';
	// Write active reservations
	For Each vQryResRow In vQryRes Do
		vCurDocObj = vQryResRow.Document.GetObject();
		Try
			vCurDocObj.Write(DocumentWriteMode.Write);
		Except
			tcCommonFunctionOnClientServer.TextMessage(String(vCurDocObj) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
		
#If Client Then
		// Status message
		If BegOfDay(vQryResRow.Date) <> vCurDate Then
			vCurDate = BegOfDay(vQryResRow.Date);
			Status(NStr("en='Processing reservations on " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'; 
			            |de='Processing reservations on " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'; 
			            |ru='Обработка действующей брони за " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'"));
		EndIf;
		UserInterruptProcessing();
#EndIf
	EndDo;
EndProcedure // FillActiveReservationsSortCode

// -----------------------------------------------------------------------------
Procedure FillInHouseAccommodationsSortCode()
#If Client Then
	Status(NStr("en='Fill in-house accommodations sort code...'; de='Fill in-house accommodations sort code...'; ru='Заполнение кода сортировки у проживающих гостей...'"));
#EndIf
	// Run query to get in-house accommodations
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref AS Document,
	|	Accommodation.Date AS Date,
	|	Accommodation.PointInTime AS PointInTime
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.AccommodationStatus.IsInHouse
	|	AND Accommodation.Posted
	|
	|ORDER BY
	|	PointInTime";
	vQryRes = vQry.Execute().Select();
	vCurDate = '00010101';
	While vQryRes.Next() Do
		vCurDocObj = vQryRes.Document.GetObject();
		Try
			vCurDocObj.Write(DocumentWriteMode.Write);
		Except
			tcCommonFunctionOnClientServer.TextMessage(String(vCurDocObj) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
		
#If Client Then
		// Status message
		If BegOfDay(vQryRes.Date) <> vCurDate Then
			vCurDate = BegOfDay(vQryRes.Date);
			Status(NStr("en='Processing in-house accommodations on " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'; 
			            |de='Processing in-house accommodations on " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'; 
			            |ru='Обработка текущих размещений за " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'"));
		EndIf;
		UserInterruptProcessing();
#EndIf
	EndDo;
EndProcedure // FillInHouseAccommodationsSortCode

// -----------------------------------------------------------------------------
Procedure FillSMSDeliveryPrintReceiversObjectPrintFormsSettings()
	vSMSDeliveryFolder = Catalogs.ObjectPrintingForms.FindByCode("1800", False, Catalogs.ObjectPrintingForms.EmptyRef());
	If Not ValueIsFilled(vSMSDeliveryFolder) Then
		vSMSDeliveryFolderObj = Catalogs.ObjectPrintingForms.CreateFolder();
		vSMSDeliveryFolderObj.Code = "1800";
		vSMSDeliveryFolderObj.Description = NStr("en='Messages delivery';ru='Рассылка сообщений';de='Versand von Mitteilungen'");
		vSMSDeliveryFolderObj.Write();
		vSMSDeliveryFolder = vSMSDeliveryFolderObj.Ref;
	EndIf;
	If TypeOf(Catalogs.ObjectPrintingForms.SMSDeliveryPrintReceivers.ObjectType) <> Type("DocumentRef.SMSDelivery") Then
		vFrmPrtObj = Catalogs.ObjectPrintingForms.SMSDeliveryPrintReceivers.GetObject();
		vFrmPrtObj.ObjectType = Documents.SMSDelivery.EmptyRef();
		If ValueIsFilled(vSMSDeliveryFolder) And vSMSDeliveryFolder.IsFolder Then
			vFrmPrtObj.Parent = vSMSDeliveryFolder;
		EndIf;
		vFrmPrtObj.IsActive = True;
		vFrmPrtObj.IsDefault = True;
		vFrmPrtObj.Remarks = "";
		vFrmPrtObj.Write();
	EndIf;
EndProcedure // FillSMSDeliveryPrintReceiversObjectPrintFormsSettings

// -----------------------------------------------------------------------------
Procedure FillSMSDeliveryObjectFormActionSettingsFolder()
	vSMSDeliveryFolder = Catalogs.ObjectFormActions.FindByCode("1600");
	If Not ValueIsFilled(vSMSDeliveryFolder) Then
		vSMSDeliveryFolderObj = Catalogs.ObjectFormActions.CreateFolder();
		vSMSDeliveryFolderObj.Code = "1600";
		vSMSDeliveryFolderObj.Description = NStr("en='Messages delivery';ru='Рассылка сообщений';de='Versand von Mitteilungen'");
		vSMSDeliveryFolderObj.Write();
	EndIf;
EndProcedure // FillSMSDeliveryObjectFormActionSettingsFolder

// -----------------------------------------------------------------------------
Procedure FillSMSBeingSentReportSettings()
	// Find Other reports folder
	vOtherReportsFolder = Catalogs.Reports.FindByCode(900, , Catalogs.Reports.EmptyRef());
	// Fill report name and report folder for new report
	vRepRef = Catalogs.Reports.SMSBeingSent;
	If ValueIsFilled(vRepRef) And Not ValueIsFilled(vRepRef.Report) Then
		vRepObj = vRepRef.GetObject();
		vRepObj.Report = "SMSBeingSent"; 
		If ValueIsFilled(vOtherReportsFolder) And vOtherReportsFolder.IsFolder Then
			vRepObj.Parent = vOtherReportsFolder;
		EndIf;
		vRepObj.SortCode = 960;
		vRepObj.Write();
	EndIf;
	// Move messages report to the same folder
	If ValueIsFilled(vOtherReportsFolder) And vOtherReportsFolder.IsFolder Then
		vRepRef = Catalogs.Reports.Messages;
		If Not ValueIsFilled(vRepRef.Parent) Then
			vRepObj = vRepRef.GetObject();
			vRepObj.Parent = vOtherReportsFolder;
			vRepObj.Write();
		EndIf;
	EndIf;
EndProcedure // FillSMSBeingSentReportSettings

// -----------------------------------------------------------------------------
Procedure TurnOnLegalRepresentativeFunctionalOption()
	vHotels = cmGetAllHotels();
	For Each vHotelsRow In vHotels Do
		If ValueIsFilled(vHotelsRow.Hotel.Citizenship) And TrimAll(vHotelsRow.Hotel.Citizenship.ISOCode) = "RU" Then
			vHotelObj = vHotelsRow.Hotel.GetObject();
			vHotelObj.LegalRepresentative = True;
			vHotelObj.Write();
		EndIf;
	EndDo;
EndProcedure // TurnOnLegalRepresentativeFunctionalOption

// -----------------------------------------------------------------------------
Procedure RepostMessages()
#If Client Then
	Status(NStr("en='Reposting tasks...';ru='Перепроведение задач...';de='Neue Durchführung von Aufgaben...'"));
#EndIf
	// Run query to get payments
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Tasks.Ref AS Document,
	|	Tasks.Date AS Date,
	|	Tasks.PointInTime AS PointInTime
	|FROM
	|	Document.Message AS Tasks
	|WHERE
	|	Tasks.Posted
	|	AND (Tasks.ForEmployee <> VALUE(Catalog.Employees.EmptyRef)
	|			OR Tasks.ForDepartment <> VALUE(Catalog.Departments.EmptyRef))
	|	AND NOT Tasks.IsClosed
	|
	|ORDER BY
	|	PointInTime";
	vQryRes = vQry.Execute().Unload();
	vCurDate = '00010101';
	// Repost tasks
	For Each vQryResRow In vQryRes Do
		vCurDocObj = vQryResRow.Document.GetObject();
		Try
			vCurDocObj.AdditionalProperties.Insert("InfoBaseUpdateMode", True);
			vCurDocObj.Write(DocumentWriteMode.Posting);
		Except
			tcCommonFunctionOnClientServer.TextMessage(String(vCurDocObj) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
		
#If Client Then
		// Status message
		If BegOfDay(vQryResRow.Date) <> vCurDate Then
			vCurDate = BegOfDay(vQryResRow.Date);
			Status(NStr("en='Reposting tasks on " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'; 
			            |de='Aufgaben reposting für " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'; 
			            |ru='Перепроведение задач за " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'"));
		EndIf;
		UserInterruptProcessing();
#EndIf
	EndDo;
EndProcedure // RepostMessages

// -----------------------------------------------------------------------------
Procedure Fill126UserPermission()
	// Run query to get permission groups
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PermissionGroups.Ref AS Ref
	|FROM
	|	Catalog.PermissionGroups AS PermissionGroups
	|WHERE
	|	(NOT PermissionGroups.DeletionMark)
	|	AND (NOT PermissionGroups.IsFolder)
	|ORDER BY
	|	PermissionGroups.Code";
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vPGObj = vQryRes.Ref.GetObject();
		Try
			If vPGObj.HavePermissionToSeeAllMessages Then
				vPGObj.HavePermissionToMessagesDelivery = True;
				vPGObj.Write();
			EndIf;
		Except
			tcCommonFunctionOnClientServer.TextMessage(TrimAll(vPGObj.Description) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
	EndDo;
EndProcedure // Fill126UserPermission

// -----------------------------------------------------------------------------
Procedure Fill127UserPermission()
	// Run query to get permission groups
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PermissionGroups.Ref AS Ref
	|FROM
	|	Catalog.PermissionGroups AS PermissionGroups
	|WHERE
	|	(NOT PermissionGroups.DeletionMark)
	|	AND (NOT PermissionGroups.IsFolder)
	|ORDER BY
	|	PermissionGroups.Code";
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vPGObj = vQryRes.Ref.GetObject();
		Try
			If vPGObj.HavePermissionToEditExportedSettlements Then
				vPGObj.HavePermissionToRecalculateInvoicesBeingAlreadyPaid = True;
				vPGObj.Write();
			EndIf;
		Except
			tcCommonFunctionOnClientServer.TextMessage(TrimAll(vPGObj.Description) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
	EndDo;
EndProcedure // Fill127UserPermission

// -----------------------------------------------------------------------------
Procedure Fill128UserPermission()
	// Run query to get permission groups
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PermissionGroups.Ref AS Ref
	|FROM
	|	Catalog.PermissionGroups AS PermissionGroups
	|WHERE
	|	(NOT PermissionGroups.DeletionMark)
	|	AND (NOT PermissionGroups.IsFolder)
	|ORDER BY
	|	PermissionGroups.Code";
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vPGObj = vQryRes.Ref.GetObject();
		Try
			vPGObj.HavePermissionToDoBookingWithoutCustomerContactData = True;
			vPGObj.Write();
		Except
			tcCommonFunctionOnClientServer.TextMessage(TrimAll(vPGObj.Description) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
	EndDo;
EndProcedure // Fill128UserPermission

// -----------------------------------------------------------------------------
Procedure Fill129UserPermission()
	// Run query to get permission groups
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PermissionGroups.Ref AS Ref
	|FROM
	|	Catalog.PermissionGroups AS PermissionGroups
	|WHERE
	|	(NOT PermissionGroups.DeletionMark)
	|	AND (NOT PermissionGroups.IsFolder)
	|ORDER BY
	|	PermissionGroups.Code";
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vPGObj = vQryRes.Ref.GetObject();
		Try
			vPGObj.HavePermissionToCreateCustomersWithoutTIN = True;
			vPGObj.Write();
		Except
			tcCommonFunctionOnClientServer.TextMessage(TrimAll(vPGObj.Description) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
	EndDo;
EndProcedure // Fill129UserPermission

// -----------------------------------------------------------------------------
Procedure Fill130UserPermission()
	// Run query to get permission groups
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PermissionGroups.Ref AS Ref
	|FROM
	|	Catalog.PermissionGroups AS PermissionGroups
	|WHERE
	|	(NOT PermissionGroups.DeletionMark)
	|	AND (NOT PermissionGroups.IsFolder)
	|ORDER BY
	|	PermissionGroups.Code";
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vPGObj = vQryRes.Ref.GetObject();
		Try
			vPGObj.HavePermissionToEditInactiveReservations = True;
			vPGObj.Write();
		Except
			tcCommonFunctionOnClientServer.TextMessage(TrimAll(vPGObj.Description) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
	EndDo;
EndProcedure // Fill130UserPermission

// -----------------------------------------------------------------------------
Procedure FillAccommodationPrintArrivalSheetFormObjectPrintingFormSetings()
	If TypeOf(Catalogs.ObjectPrintingForms.AccommodationPrintArrivalSheetForm.ObjectType) <> Type("DocumentRef.Accommodation") Then
		vAccommodationFolder = Catalogs.ObjectPrintingForms.FindByCode("100", False, Catalogs.ObjectPrintingForms.EmptyRef());
		vPrtFormObj = Catalogs.ObjectPrintingForms.AccommodationPrintArrivalSheetForm.GetObject();
		vPrtFormObj.ObjectType = Documents.Accommodation.EmptyRef();
		If ValueIsFilled(vAccommodationFolder) And vAccommodationFolder.IsFolder Then
			vPrtFormObj.Parent = vAccommodationFolder;
		EndIf;
		vPrtFormObj.IsActive = True;
		vPrtFormObj.Remarks = "";
		vPrtFormObj.Write();
	EndIf;
EndProcedure // FillAccommodationPrintArrivalSheetFormObjectPrintingFormSetings

// -----------------------------------------------------------------------------
Procedure FillReservationPrintGuestFormObjectPrintFormsSettings()
	If TypeOf(Catalogs.ObjectPrintingForms.ReservationPrintGuestFormForm5.ObjectType) <> Type("DocumentRef.Reservation") Then
		vReservationFolder = Catalogs.ObjectPrintingForms.FindByCode("200", False, Catalogs.ObjectPrintingForms.EmptyRef());
		
		vPrtFormObj = Catalogs.ObjectPrintingForms.ReservationPrintGuestFormForm5.GetObject();
		vPrtFormObj.ObjectType = Documents.Reservation.EmptyRef();
		If ValueIsFilled(vReservationFolder) And vReservationFolder.IsFolder Then
			vPrtFormObj.Parent = vReservationFolder;
		EndIf;
		vPrtFormObj.IsActive = True;
		vPrtFormObj.Write();
		
		vPrtFormObj = Catalogs.ObjectPrintingForms.ReservationPrintGuestForm2Forms5.GetObject();
		vPrtFormObj.ObjectType = Documents.Reservation.EmptyRef();
		If ValueIsFilled(vReservationFolder) And vReservationFolder.IsFolder Then
			vPrtFormObj.Parent = vReservationFolder;
		EndIf;
		vPrtFormObj.IsActive = True;
		vPrtFormObj.Write();
		
		vPrtFormObj = Catalogs.ObjectPrintingForms.ReservationPrintGuestsFormsForm5.GetObject();
		vPrtFormObj.ObjectType = Documents.Reservation.EmptyRef();
		If ValueIsFilled(vReservationFolder) And vReservationFolder.IsFolder Then
			vPrtFormObj.Parent = vReservationFolder;
		EndIf;
		vPrtFormObj.IsActive = True;
		vPrtFormObj.Write();
		
		vPrtFormObj = Catalogs.ObjectPrintingForms.ReservationPrintGuestsForms2Forms5.GetObject();
		vPrtFormObj.ObjectType = Documents.Reservation.EmptyRef();
		If ValueIsFilled(vReservationFolder) And vReservationFolder.IsFolder Then
			vPrtFormObj.Parent = vReservationFolder;
		EndIf;
		vPrtFormObj.IsActive = True;
		vPrtFormObj.Write();
	EndIf;
EndProcedure // FillReservationPrintGuestFormObjectPrintFormsSettings

// -----------------------------------------------------------------------------
Procedure FillForeignerRegistryRecordPrintAllClientDataScansObjectPrintingFormSetings()
	If TypeOf(Catalogs.ObjectPrintingForms.ForeignerRegistryRecordPrintAllClientDataScans.ObjectType) <> Type("DocumentRef.ForeignerRegistryRecord") Then
		vForeignersFolder = Catalogs.ObjectPrintingForms.FindByCode("300", False, Catalogs.ObjectPrintingForms.EmptyRef());
		vPrtFormObj = Catalogs.ObjectPrintingForms.ForeignerRegistryRecordPrintAllClientDataScans.GetObject();
		vPrtFormObj.ObjectType = Documents.ForeignerRegistryRecord.EmptyRef();
		If ValueIsFilled(vForeignersFolder) And vForeignersFolder.IsFolder Then
			vPrtFormObj.Parent = vForeignersFolder;
		EndIf;
		vPrtFormObj.IsActive = True;
		vPrtFormObj.Remarks = "";
		vPrtFormObj.Write();
	EndIf;
EndProcedure // FillForeignerRegistryRecordPrintAllClientDataScansObjectPrintingFormSetings

// -----------------------------------------------------------------------------
Procedure FillFolioGiftCertificatesActionSettings()
	vFolioFolder = Catalogs.ObjectFormActions.FindByCode("500");
	If TypeOf(Catalogs.ObjectFormActions.FolioBlockGiftCertificate.ObjectType) <> Type("DocumentRef.Folio") Then
		vFrmActObj = Catalogs.ObjectFormActions.FolioBlockGiftCertificate.GetObject();
		vFrmActObj.ObjectType = Documents.Folio.EmptyRef();
		If ValueIsFilled(vFolioFolder) And vFolioFolder.IsFolder Then
			vFrmActObj.Parent = vFolioFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Write();
	EndIf;
	If TypeOf(Catalogs.ObjectFormActions.FolioShowGiftCertificate.ObjectType) <> Type("DocumentRef.Folio") Then
		vFrmActObj = Catalogs.ObjectFormActions.FolioShowGiftCertificate.GetObject();
		vFrmActObj.ObjectType = Documents.Folio.EmptyRef();
		If ValueIsFilled(vFolioFolder) And vFolioFolder.IsFolder Then
			vFrmActObj.Parent = vFolioFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Write();
	EndIf;
	If TypeOf(Catalogs.ObjectFormActions.FolioIssueGiftCertificate.ObjectType) <> Type("DocumentRef.Folio") Then
		vFrmActObj = Catalogs.ObjectFormActions.FolioIssueGiftCertificate.GetObject();
		vFrmActObj.ObjectType = Documents.Folio.EmptyRef();
		If ValueIsFilled(vFolioFolder) And vFolioFolder.IsFolder Then
			vFrmActObj.Parent = vFolioFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Write();
	EndIf;
EndProcedure // FillFolioGiftCertificatesActionSettings

// -----------------------------------------------------------------------------
Procedure FillCustomerSendInvitationToNewAgentActionSettings()
	vCustomerFolder = Catalogs.ObjectFormActions.FindByCode("1000");
	If TypeOf(Catalogs.ObjectFormActions.CustomerSendInvitationToNewAgent.ObjectType) <> Type("CatalogRef.Customers") Then
		vFrmActObj = Catalogs.ObjectFormActions.CustomerSendInvitationToNewAgent.GetObject();
		vFrmActObj.ObjectType = Catalogs.Customers.EmptyRef();
		If ValueIsFilled(vCustomerFolder) And vCustomerFolder.IsFolder Then
			vFrmActObj.Parent = vCustomerFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Write();
	EndIf;
EndProcedure // FillCustomerSendInvitationToNewAgentActionSettings

// -----------------------------------------------------------------------------
Procedure FillContractSendInvitationToNewAgentActionSettings()
	vContractFolder = Catalogs.ObjectFormActions.FindByCode("1100");
	If TypeOf(Catalogs.ObjectFormActions.ContractSendInvitationToNewAgent.ObjectType) <> Type("CatalogRef.Contracts") Then
		vFrmActObj = Catalogs.ObjectFormActions.ContractSendInvitationToNewAgent.GetObject();
		vFrmActObj.ObjectType = Catalogs.Contracts.EmptyRef();
		If ValueIsFilled(vContractFolder) And vContractFolder.IsFolder Then
			vFrmActObj.Parent = vContractFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Write();
	EndIf;
EndProcedure // FillContractSendInvitationToNewAgentActionSettings

// -----------------------------------------------------------------------------
Procedure FillActiveGiftCertificatesReportSettings()
	// Find accounting reports folder
	vAccountingReportsFolder = Catalogs.Reports.FindByCode(500, , Catalogs.Reports.EmptyRef());
	// Fill report parameters
	vRepRef = Catalogs.Reports.GiftCertificates;
	If ValueIsFilled(vRepRef) And vRepRef.Report <> "ActiveGiftCertificates" Then
		vRepObj = vRepRef.GetObject();
		vRepObj.Remarks = "EN='Report shows open, not blocked gift certificates with balances'; RU='Отчет показывает список действующих, не заблокированных подарочных сертификатов, по которым не израсходованы все средства'";
		vRepObj.Report = "ActiveGiftCertificates"; 
		If ValueIsFilled(vAccountingReportsFolder) And vAccountingReportsFolder.IsFolder Then
			vRepObj.Parent = vAccountingReportsFolder;
		EndIf;
		vRepObj.SortCode = 970;
		vRepObj.DynamicParameters = "REP.Period = CurrentSessionDate();";
		vRepObj.DefaultSettings = New ValueStorage(ThisObject.GetTemplate("ActiveGiftCertificatesReportDefaultSettings"));
		vRepObj.Write();
	EndIf;
EndProcedure // FillActiveGiftCertificatesReportSettings

// -----------------------------------------------------------------------------
Procedure ChangeNorweqVisionConnectionType()
	vQry = New Query();
	vQry.Text =
	"SELECT
	|	DoorLockSystemParameters.Ref AS Ref
	|FROM
	|	Catalog.DoorLockSystemParameters AS DoorLockSystemParameters
	|WHERE
	|	NOT DoorLockSystemParameters.IsFolder
	|	AND DoorLockSystemParameters.DoorLockSystemType IN (&qDoorLockSystemTypeList)
	|	AND DoorLockSystemParameters.ConnectionType = &qConnectionType
	|
	|ORDER BY
	|	DoorLockSystemParameters.Code";
	vList = New ValueList();
	vList.Add(Enums.DoorLockSystems.VingCardVision);
	vList.Add(Enums.DoorLockSystems.VingCardDavinci);
	vQry.SetParameter("qDoorLockSystemTypeList", vList);
	vQry.SetParameter("qConnectionType", Enums.ConnectionTypes.TCPIP);
	vSettings = vQry.Execute().Unload();
	For Each vSettingsRow In vSettings Do
		vSettingsObj = vSettingsRow.Ref.GetObject();
		vSettingsObj.ConnectionType = Enums.ConnectionTypes.VisionIntDll;
		vSettingsObj.Write();
	EndDo;
EndProcedure // ChangeNorweqVisionConnectionType

// -----------------------------------------------------------------------------
Procedure FillDoNightAuditPrecheckDataProcessorSettings()
	// Fill data processor name and dynamic parameters
	vDPRef = Catalogs.DataProcessors.DoNightAuditPrecheck;
	If ValueIsFilled(vDPRef) And Not ValueIsFilled(vDPRef.Processing) Then
		vDPObj = vDPRef.GetObject();
		vDPObj.Processing = "DoNightAuditPrecheck"; 
		vDPObj.SortCode = 510;
		vDPObj.DynamicParameters = "If ValueIsFilled(PARM) Then
		                           |	DPO.Hotel = PARM;
		                           |EndIf;";
		vDPObj.Write();
	EndIf;
EndProcedure // FillDoNightAuditPrecheckDataProcessorSettings

// -----------------------------------------------------------------------------
Procedure FillServicePackageRecordsInformationRegister()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ServicePackages.Ref  AS Ref
	|FROM
	|	Catalog.ServicePackages AS ServicePackages
	|WHERE
	|	NOT ServicePackages.IsFolder
	|	AND NOT ServicePackages.DeletionMark
	|
	|ORDER BY
	|	ServicePackages.SortCode,
	|	ServicePackages.Code";
	vServicePackages = vQry.Execute().Unload();
	For Each vServicePackagesRow In vServicePackages Do
		vServicePackageObj = vServicePackagesRow.Ref.GetObject();
		vServicePackageObj.Write();
	EndDo;
EndProcedure // FillServicePackageRecordsInformationRegister

// -----------------------------------------------------------------------------
Procedure SimpleRepostActiveReservations()
#If Client Then
	Status(NStr("en='Reposting active reservations...'; de='Reposting active reservations...'; ru='Перепроведение действующей брони...'"));
#EndIf
	// Run query to get active reservations
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservation.Ref AS Document,
	|	Reservation.CheckInDate AS CheckInDate,
	|	Reservation.PointInTime AS PointInTime
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.ReservationStatus.IsActive
	|	AND Reservation.Posted
	|
	|ORDER BY
	|	CheckInDate,
	|	PointInTime";
	vQryRes = vQry.Execute().Unload();
	vCurDate = '00010101';
	// Undo posting active reservations first
	For Each vQryResRow In vQryRes Do
		vCurDocObj = vQryResRow.Document.GetObject();
		Try
			vCurDocObj.AdditionalProperties.Insert("InfoBaseUpdateMode", True);
			vCurDocObj.Write(DocumentWriteMode.Posting);
		Except
			tcCommonFunctionOnClientServer.TextMessage(String(vCurDocObj) + NStr("en=' - error: '; de=' - Fehler: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
		
#If Client Then
		// Status message
		If BegOfDay(vQryResRow.CheckInDate) <> vCurDate Then
			vCurDate = BegOfDay(vQryResRow.CheckInDate);
			Status(NStr("en='Reposting active reservations on " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'; 
			            |de='Reposting active reservations on " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'; 
			            |ru='Перепроведение действующей брони за " + Format(vCurDate, "DF=dd.MM.yyyy") + "...'"));
		EndIf;
		UserInterruptProcessing();
#EndIf
	EndDo;
EndProcedure // SimpleRepostActiveReservations

// -----------------------------------------------------------------------------
Procedure FillGermanPrintingFormsSettings()
	vInvoiceFolder = Catalogs.ObjectPrintingForms.FindByCode("800", False, Catalogs.ObjectPrintingForms.EmptyRef());
	If ValueIsFilled(vInvoiceFolder) And Not vInvoiceFolder.IsFolder Then
		vInvoiceFolder = Undefined;
	EndIf;
	vFolioFolder = Catalogs.ObjectPrintingForms.FindByCode("500", False, Catalogs.ObjectPrintingForms.EmptyRef());
	If ValueIsFilled(vFolioFolder) And Not vFolioFolder.IsFolder Then
		vFolioFolder = Undefined;
	EndIf;
	vReservationFolder = Catalogs.ObjectPrintingForms.FindByCode("200", False, Catalogs.ObjectPrintingForms.EmptyRef());
	If ValueIsFilled(vReservationFolder) And Not vReservationFolder.IsFolder Then
		vReservationFolder = Undefined;
	EndIf;
	// Get new forms list
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ObjectPrintingForms.Ref AS Ref,
	|	ObjectPrintingForms.Description AS Description
	|FROM
	|	Catalog.ObjectPrintingForms AS ObjectPrintingForms
	|WHERE
	|	ObjectPrintingForms.Parent = &qEmptyParent
	|	AND NOT ObjectPrintingForms.IsFolder
	|	AND NOT ObjectPrintingForms.DeletionMark
	|	AND ObjectPrintingForms.Language = &qEmptyLanguage
	|	AND ObjectPrintingForms.ObjectType = &qUndefined
	|
	|ORDER BY
	|	ObjectPrintingForms.Code";
	vQry.SetParameter("qEmptyParent", Catalogs.ObjectPrintingForms.EmptyRef());
	vQry.SetParameter("qEmptyLanguage", Catalogs.Languages.EmptyRef());
	vQry.SetParameter("qUndefined", Undefined);
	vForms = vQry.Execute().Unload();
	For Each vFormsRow In vForms Do
		If Find(vFormsRow.Description, "en='Invoice") > 0 Or Find(vFormsRow.Description, "en='Detailed invoice") > 0 Or Find(vFormsRow.Description, "en='Short invoice") > 0 Then
			vFormObj = vFormsRow.Ref.GetObject();
			vFormObj.ObjectType = Documents.ProformaInvoice.EmptyRef();
			vFormObj.Language = Catalogs.Languages.DE;
			vFormObj.IsActive = True;
			If ValueIsFilled(vInvoiceFolder) Then
				vFormObj.Parent = vInvoiceFolder;
			EndIf;
			vFormObj.Write();
		EndIf;
		If Find(vFormsRow.Description, "en = 'Print charge details") > 0 Or Find(vFormsRow.Description, "en='Print folio") > 0 Or Find(vFormsRow.Description, "en='Print hotel property damage list") > 0 Or Find(vFormsRow.Description, "en='Print external client folio") > 0 Then
			vFormObj = vFormsRow.Ref.GetObject();
			vFormObj.ObjectType = Documents.Folio.EmptyRef();
			vFormObj.Language = Catalogs.Languages.DE;
			vFormObj.IsActive = True;
			If ValueIsFilled(vFolioFolder) Then
				vFormObj.Parent = vFolioFolder;
			EndIf;
			vFormObj.Write();
		EndIf;
		If Find(vFormsRow.Description, "(DE)") > 0 Then
			vFormObj = vFormsRow.Ref.GetObject();
			vFormObj.ObjectType = Documents.Reservation.EmptyRef();
			vFormObj.Language = Catalogs.Languages.DE;
			vFormObj.IsActive = True;
			If ValueIsFilled(vReservationFolder) Then
				vFormObj.Parent = vReservationFolder;
			EndIf;
			vFormObj.Write();
		EndIf;
	EndDo;
EndProcedure // FillGermanPrintingFormsSettings

// -----------------------------------------------------------------------------
Procedure Fill131UserPermission()
	// Run query to get permission groups
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PermissionGroups.Ref AS Ref
	|FROM
	|	Catalog.PermissionGroups AS PermissionGroups
	|WHERE
	|	(NOT PermissionGroups.DeletionMark)
	|	AND (NOT PermissionGroups.IsFolder)
	|ORDER BY
	|	PermissionGroups.Code";
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vPGObj = vQryRes.Ref.GetObject();
		Try
			vPGObj.HavePermissionToSkipBoardPlaceSetting = True;
			vPGObj.Write();
		Except
			tcCommonFunctionOnClientServer.TextMessage(TrimAll(vPGObj.Description) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
	EndDo;
EndProcedure // Fill131UserPermission

// -----------------------------------------------------------------------------
Procedure ChangeGiftCertificatesReportSettings()
	If Catalogs.Reports.GiftCertificates.Report <> "GiftCertificates" Then
		vSPIRFolder = Catalogs.Reports.FindByCode(100, , Catalogs.Reports.EmptyRef());
		vRepObj = Catalogs.Reports.GiftCertificates.GetObject();
		vRepObj.Report = "GiftCertificates";
		vRepObj.DynamicParameters = "REP.PeriodFrom = AddMonth(BegOfMonth(CurrentSessionDate()), -1);
		                            |REP.PeriodTo = AddMonth(EndOfMonth(CurrentSessionDate()), -1);";
		If ValueIsFilled(vSPIRFolder) And vSPIRFolder.IsFolder Then
			vRepObj.Parent = vSPIRFolder;
		EndIf;
		vRepObj.Remarks = "";
		vRepObj.DefaultSettings = New ValueStorage(cmReadReportDefaultSettingFromTemplate(vRepObj));
		vRepObj.Write();
		// Load this default report settings
		vReportObject = cmBuildReportObject(vRepObj.Ref);
		vReportObject.Report = vRepObj.Ref;
		#If Client Then
			cmLoadDefaultReportSettings(vReportObject);
		#EndIf
		// Save report settings
		vReportObject.pmSaveReportAttributes();
	EndIf;
EndProcedure // ChangeGiftCertificatesReportSettings

// -----------------------------------------------------------------------------
Procedure FillReservationExpressCheckInInvitationPrintFormsSettings()
	vReservationFolder = Catalogs.ObjectPrintingForms.FindByCode("200", False, Catalogs.ObjectPrintingForms.EmptyRef());
	If ValueIsFilled(vReservationFolder) And Not vReservationFolder.IsFolder Then
		vReservationFolder = Undefined;
	EndIf;
	// Get new forms list
	If Catalogs.ObjectPrintingForms.ReservationPrintExpressCheckInInvitationRu.ObjectType = Undefined Then
		vFormObj = Catalogs.ObjectPrintingForms.ReservationPrintExpressCheckInInvitationRu.GetObject();
		vFormObj.ObjectType = Documents.Reservation.EmptyRef();
		vFormObj.Language = Catalogs.Languages.RU;
		vFormObj.IsActive = True;
		If ValueIsFilled(vReservationFolder) Then
			vFormObj.Parent = vReservationFolder;
		EndIf;
		vFormObj.Write();
	EndIf;
	If Catalogs.ObjectPrintingForms.ReservationPrintExpressCheckInInvitationEn.ObjectType = Undefined Then
		vFormObj = Catalogs.ObjectPrintingForms.ReservationPrintExpressCheckInInvitationEn.GetObject();
		vFormObj.ObjectType = Documents.Reservation.EmptyRef();
		vFormObj.Language = Catalogs.Languages.EN;
		vFormObj.IsActive = True;
		If ValueIsFilled(vReservationFolder) Then
			vFormObj.Parent = vReservationFolder;
		EndIf;
		vFormObj.Write();
	EndIf;
	If Catalogs.ObjectPrintingForms.ReservationPrintExpressCheckInInvitationDe.ObjectType = Undefined Then
		vFormObj = Catalogs.ObjectPrintingForms.ReservationPrintExpressCheckInInvitationDe.GetObject();
		vFormObj.ObjectType = Documents.Reservation.EmptyRef();
		vFormObj.Language = Catalogs.Languages.DE;
		vFormObj.IsActive = True;
		If ValueIsFilled(vReservationFolder) Then
			vFormObj.Parent = vReservationFolder;
		EndIf;
		vFormObj.Write();
	EndIf;
EndProcedure // FillReservationExpressCheckInInvitationPrintFormsSettings

// -----------------------------------------------------------------------------
Procedure FixCountriesDescription()
	vC = Catalogs.Countries.Select();
	While vC.Next() Do
		If Find(vC.Description,",") > 0 Then
			vCObj = vC.GetObject();
			vCObj.Description = StrReplace(vCObj.Description,", "," ");
			vCObj.Description = StrReplace(vCObj.Description,","," ");
			vCObj.Write();
		EndIf;
	EndDo;
EndProcedure // FixCountriesDescription

// -----------------------------------------------------------------------------
Procedure FillFMSCodes()
	InformationRegisters.CodesFMS.pmRun();	
EndProcedure // FillFMSCodes

// -----------------------------------------------------------------------------
Procedure FillAccommodationMakeIdentificationCardFormActionSetings()
	If TypeOf(Catalogs.ObjectFormActions.AccommodationMakeIdentificationCard.ObjectType) <> Type("DocumentRef.Accommodation") Then
		vAccommodationFolder = Catalogs.ObjectFormActions.FindByCode("100");
		vFormActObj = Catalogs.ObjectFormActions.AccommodationMakeIdentificationCard.GetObject();
		vFormActObj.ObjectType = Documents.Accommodation.EmptyRef();
		If ValueIsFilled(vAccommodationFolder) And vAccommodationFolder.IsFolder Then
			vFormActObj.Parent = vAccommodationFolder;
		EndIf;
		vFormActObj.IsActive = True;
		vFormActObj.Remarks = "";
		vFormActObj.Write();
	EndIf;
EndProcedure // FillAccommodationMakeIdentificationCardFormActionSetings

// -----------------------------------------------------------------------------
Procedure FillAccommodationSendWelcomeSMSActionSetings()
	If TypeOf(Catalogs.ObjectFormActions.AccommodationSendWelcomeSMS.ObjectType) <> Type("DocumentRef.Accommodation") Then
		vAccommodationFolder = Catalogs.ObjectFormActions.FindByCode("100");
		vFormActObj = Catalogs.ObjectFormActions.AccommodationSendWelcomeSMS.GetObject();
		vFormActObj.ObjectType = Documents.Accommodation.EmptyRef();
		If ValueIsFilled(vAccommodationFolder) And vAccommodationFolder.IsFolder Then
			vFormActObj.Parent = vAccommodationFolder;
		EndIf;
		vFormActObj.IsActive = True;
		vFormActObj.Remarks = "";
		vFormActObj.Write();
	EndIf;
EndProcedure // FillAccommodationSendWelcomeSMSActionSetings

// -----------------------------------------------------------------------------
Procedure FillReservationSendWelcomeSMSActionSetings()
	If TypeOf(Catalogs.ObjectFormActions.ReservationSendMyFolioSMS.ObjectType) <> Type("DocumentRef.Reservation") Then
		vReservationFolder = Catalogs.ObjectFormActions.FindByCode("200");
		vFormActObj = Catalogs.ObjectFormActions.ReservationSendMyFolioSMS.GetObject();
		vFormActObj.ObjectType = Documents.Reservation.EmptyRef();
		If ValueIsFilled(vReservationFolder) And vReservationFolder.IsFolder Then
			vFormActObj.Parent = vReservationFolder;
		EndIf;
		vFormActObj.IsActive = True;
		vFormActObj.Remarks = "";
		vFormActObj.Write();
	EndIf;
EndProcedure // FillReservationSendWelcomeSMSActionSetings

// -----------------------------------------------------------------------------
Procedure FillResourceReservationSendWelcomeSMSActionSetings()
	If TypeOf(Catalogs.ObjectFormActions.ResourceReservationSendMyFolioSMS.ObjectType) <> Type("DocumentRef.ResourceReservation") Then
		vRRFolder = Catalogs.ObjectFormActions.FindByCode("1300");
		vFormActObj = Catalogs.ObjectFormActions.ResourceReservationSendMyFolioSMS.GetObject();
		vFormActObj.ObjectType = Documents.ResourceReservation.EmptyRef();
		If ValueIsFilled(vRRFolder) And vRRFolder.IsFolder Then
			vFormActObj.Parent = vRRFolder;
		EndIf;
		vFormActObj.IsActive = True;
		vFormActObj.Remarks = "";
		vFormActObj.Write();
	EndIf;
EndProcedure // FillResourceReservationSendWelcomeSMSActionSetings

// -----------------------------------------------------------------------------
Procedure FillCashRegisterPrintDeviceCurrentStateOfCalculationsReportActionSettings()
	vCashRegisterFolder = Catalogs.ObjectFormActions.FindByCode("600");
	If TypeOf(Catalogs.ObjectFormActions.CashRegisterPrintDeviceCurrentStateOfCalculationsReport.ObjectType) <> Type("CatalogRef.CashRegisters") Then
		vFrmActObj = Catalogs.ObjectFormActions.CashRegisterPrintDeviceCurrentStateOfCalculationsReport.GetObject();
		vFrmActObj.ObjectType = Catalogs.CashRegisters.EmptyRef();
		If ValueIsFilled(vCashRegisterFolder) And vCashRegisterFolder.IsFolder Then
			vFrmActObj.Parent = vCashRegisterFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Write();
	EndIf;
EndProcedure // FillCashRegisterPrintDeviceCurrentStateOfCalculationsReportActionSettings

// -----------------------------------------------------------------------------
Procedure FillChatBotResources()
	InformationRegisters.ChatCommands.pmInit();
	InformationRegisters.emoji.pmInit();
EndProcedure // FillChatBotResources

// -----------------------------------------------------------------------------
Procedure Fill133UserPermission()
	// Run query to get permission groups
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PermissionGroups.Ref AS Ref
	|FROM
	|	Catalog.PermissionGroups AS PermissionGroups
	|WHERE
	|	(NOT PermissionGroups.DeletionMark)
	|	AND (NOT PermissionGroups.IsFolder)
	|ORDER BY
	|	PermissionGroups.Code";
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vPGObj = vQryRes.Ref.GetObject();
		Try
			vPGObj.HavePermissionToInputDiscountCardNumberManually = True;
			vPGObj.Write();
		Except
			tcCommonFunctionOnClientServer.TextMessage(TrimAll(vPGObj.Description) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
	EndDo;
EndProcedure // Fill133UserPermission

// -----------------------------------------------------------------------------
Procedure Fill134UserPermission()
	// Run query to get permission groups
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PermissionGroups.Ref AS Ref
	|FROM
	|	Catalog.PermissionGroups AS PermissionGroups
	|WHERE
	|	(NOT PermissionGroups.DeletionMark)
	|	AND (NOT PermissionGroups.IsFolder)
	|ORDER BY
	|	PermissionGroups.Code";
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vPGObj = vQryRes.Ref.GetObject();
		Try
			vPGObj.HavePermissionToUseClientDiscountCardWithAnyOtherClientHavingIt = True;
			vPGObj.Write();
		Except
			tcCommonFunctionOnClientServer.TextMessage(TrimAll(vPGObj.Description) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
	EndDo;
EndProcedure // Fill134UserPermission

// -----------------------------------------------------------------------------
Procedure FillEmployeeActionsAuditReportSettings()
	// Create audit reports group first
	vAuditReportsFolder = Catalogs.Reports.FindByCode(790, , Catalogs.Reports.EmptyRef());
	If ValueIsFilled(vAuditReportsFolder) And Not vAuditReportsFolder.IsFolder Then
		vAuditReportsFolder = Catalogs.Reports.EmptyRef();
	EndIf;
	// Fill report name and report folder for new reports
	vRepRef = Catalogs.Reports.EmployeeActionsAudit;
	If ValueIsFilled(vRepRef) And Not ValueIsFilled(vRepRef.Report) Then
		vRepObj = vRepRef.GetObject();
		vRepObj.Report = "EmployeeActionsAudit"; 
		vRepObj.Parent = vAuditReportsFolder;
		vRepObj.SortCode = 971;
		vRepObj.DynamicParameters = "REP.PeriodFrom = BegOfDay(CurrentSessionDate()) - 24*3600;
		                            |REP.PeriodTo = EndOfDay(REP.PeriodFrom);";
		vRepObj.Write();
	EndIf;
EndProcedure // FillEmployeeActionsAuditReportSettings 

// -----------------------------------------------------------------------------
Procedure FixAnaliticalReportSettings(pReportRef)
	// Build report object
	vRepObj = cmBuildReportObject(pReportRef);
	If vRepObj <> Undefined Then
		// Initialize report settings
		Try
			// Fill reference to the report catalog item
			vRepObj.Report = pReportRef;
			// Load report catalog item attributes
			vRepObj.pmLoadReportAttributes(Undefined);
			// Get report data builder
			vRB = vRepObj.ReportBuilder;
			// Get report builder settings
			vSelectedFields = New Array();
			For Each vSelField In vRB.SelectedFields Do
				vSelectedFields.Add(vSelField);
			EndDo;
			vRowDimensions = New Array();
			For Each vRowDim In vRB.RowDimensions Do
				vRowDimensions.Add(vRowDim);
			EndDo;
			vColumnDimensions = New Array();
			For Each vColDim In vRB.ColumnDimensions Do
				vColumnDimensions.Add(vColDim);
			EndDo;
			vOrderFields = New Array();
			For Each vOrderField In vRB.Order Do
				vOrderFields.Add(vOrderField);
			EndDo;
			// Load actual report query text
			vRepObj.pmInitializeReportBuilder();
			vRB = New ReportBuilder(vRepObj.QueryText);
			// Restore settings
			vRB.SelectedFields.Clear();
			For Each vSelField In vSelectedFields Do
				vRB.SelectedFields.Add(vSelField.DataPath, vSelField.Name);
			EndDo;
			vRB.RowDimensions.Clear();
			For Each vRowDim In vRowDimensions Do
				vRB.RowDimensions.Add(vRowDim.DataPath, vRowDim.Name, vRowDim.DimensionType);
			EndDo;
			vRB.ColumnDimensions.Clear();
			For Each vColDim In vColumnDimensions Do
				vRB.ColumnDimensions.Add(vColDim.DataPath, vColDim.Name, vColDim.DimensionType);
			EndDo;
			vRB.Order.Clear();
			For Each vOrderField In vOrderFields Do
				If Left(vOrderField.Name, 1) <> " " Then
					vRB.Order.Add(vOrderField.DataPath, vOrderField.Name, vOrderField.Presentation, vOrderField.Direction);
				EndIf;
			EndDo;
			// Get new report settings
			vRBSettings = vRB.GetSettings(True, True, True, True, True);
			// Set new report builder settings
			vRepObj.ReportBuilder.SetSettings(vRBSettings, True, True, True, True, True);
			// Save report settings
			vRepObj.pmSaveReportAttributes();
		Except
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load report: '; ru='Ошибка загрузки отчета: '; de='Failed to load report: '") + TrimAll(pReportRef.Code) + " - " + TrimAll(pReportRef.Description) + ": " + ErrorDescription(), MessageStatus.Attention);
		EndTry;
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load report: '; ru='Ошибка загрузки отчета: '; de='Failed to load report: '") + TrimAll(pReportRef.Code) + " - " + TrimAll(pReportRef.Description), MessageStatus.Attention);
	EndIf;
EndProcedure // FixAnaliticalReportSettings

// -----------------------------------------------------------------------------
Procedure FixAnaliticalReportsSettings()
	vReportsList = New ValueList();
	vReportsList.Add("CustomerGuestsTurnovers");
	vReportsList.Add("CustomerSalesTurnovers");
	vReportsList.Add("ResourceSalesTurnovers");
	vReportsList.Add("RoomSalesTurnovers");
	vReportsList.Add("ServiceSalesTurnovers");
	vReportsList.Add("RevenueTurnovers");
	// Build list of reports to process
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reports.Ref AS Ref,
	|	Reports.Code AS Code,
	|	Reports.Description AS Description
	|FROM
	|	Catalog.Reports AS Reports
	|WHERE
	|	NOT Reports.IsFolder
	|	AND NOT Reports.DeletionMark
	|	AND Reports.Report IN(&qReportsList)
	|
	|ORDER BY
	|	Reports.Code";
	vQry.SetParameter("qReportsList", vReportsList);
	vReports = vQry.Execute().Unload();
	For Each vReportRow In vReports Do
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Report settings update: '; ru='Обновление настроек отчета: '; de='Berichtseinstellungen Update: '") + TrimAll(vReportRow.Code) + " - " + cmNStr(vReportRow.Description) + "...", MessageStatus.Information);
		FixAnaliticalReportSettings(vReportRow.Ref);
	EndDo;
EndProcedure // FixAnaliticalReportsSettings

// -----------------------------------------------------------------------------
Procedure FillCustomersIsIndividual()
	vC = Catalogs.Customers.Select();
	While vC.Next() Do
		If Not vC.IsFolder And Not vC.DeletionMark Then
			vCObj = vC.GetObject();
			vCObj.Write();
			vCObj.pmWriteToCustomerChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		EndIf;
	EndDo;
EndProcedure // FillCustomersIsIndividual

// -----------------------------------------------------------------------------
Procedure FillNoCitizenshipVirtualCountryParams()
	vLBGCountryRef = Catalogs.Countries.FindByCode(999, False);
	If ValueIsFilled(vLBGCountryRef) And IsBlankString(vLBGCountryRef.ISOCode3) Then
		vLBGCountryObj = vLBGCountryRef.GetObject();
		vLBGCountryObj.ISOCode3 = "L-B-G";
		vLBGCountryObj.Write();
	EndIf;
EndProcedure // FillNoCitizenshipVirtualCountryParams

// -----------------------------------------------------------------------------
Procedure UpdateCashRegisterDriverTypes()
	vIsFromRussia = False;
	vHotels = cmGetAllHotels();
	For Each vHotelsRow In vHotels Do
		If ValueIsFilled(vHotelsRow.Hotel.Citizenship) And TrimAll(vHotelsRow.Hotel.Citizenship.ISOCode) = "RU" Then
			vIsFromRussia = True;
			Break;
		EndIf;
	EndDo;
	If vIsFromRussia Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	CashRegisters.Ref AS Ref,
		|	CashRegisters.CashRegisterDriver AS CashRegisterDriver
		|FROM
		|	Catalog.CashRegisters AS CashRegisters
		|WHERE
		|	CashRegisters.IsControlledByProgram
		|	AND NOT CashRegisters.DeletionMark
		|
		|ORDER BY
		|	CashRegisters.Code";
		vCRs = vQry.Execute().Unload();
		For Each vCRsRow In vCRs Do
			If vCRsRow.CashRegisterDriver = Enums.CashRegisterDrivers.AtolCommonCashRegisterDriver Or vCRsRow.CashRegisterDriver = Enums.CashRegisterDrivers.AtolCommonCashRegisterDriver8 Then
				vCRObj = vCRsRow.Ref.GetObject();
				vCRObj.CashRegisterDriver = Enums.CashRegisterDrivers.AtolCommonCashRegisterDriver54FZ;
				vCRObj.Write();
			ElsIf vCRsRow.CashRegisterDriver = Enums.CashRegisterDrivers.ShtrihMDriverFR Then
				vCRObj = vCRsRow.Ref.GetObject();
				vCRObj.CashRegisterDriver = Enums.CashRegisterDrivers.ShtrihMDriverFR54FZ;
				vCRObj.Write();
			EndIf;
		EndDo;
	EndIf;
EndProcedure // UpdateCashRegisterDriverTypes

// -----------------------------------------------------------------------------
Procedure InitializeOrdersSubsystem()
	Documents.Order.InitializeOrdersSubsystem();
EndProcedure // InitializeOrdersSubsystem

// -----------------------------------------------------------------------------
Procedure RenameWubookSettings()
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	ExternalSystemInteractions.Ref AS Ref,
	|	ExternalSystemInteractions.InteractionID AS InteractionID
	|FROM
	|	Catalog.ExternalSystemInteractions AS ExternalSystemInteractions
	|WHERE
	|	ExternalSystemInteractions.InteractionID LIKE ""%Wubook%""
	|	AND NOT ExternalSystemInteractions.InteractionID LIKE ""%Wubook-%""";
	vQueryResult = vQuery.Execute().Unload();
	For each vRow in vQueryResult Do
		vInteractionID = "WuBook" + "-" + TrimAll(StrReplace(vRow.InteractionID,"Wubook",""));
		
		vRecordSet                   = InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordSet();
		vRecordSet.Filter.ExternalSystemCode.Value   = vRow.InteractionID;
		vRecordSet.Filter.ExternalSystemCode.Use  = True;
		vRecordSet.Read();
		
		vRecordSet2                 = InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordSet();
		vRecordSet2.Load(vRecordSet.Unload());
		
		For each vRecordRow In vRecordSet2 Do
			vRecordRow.ExternalSystemCode = vInteractionID;  
		EndDo;
		vRecordSet.Clear();
		vRecordSet2.Filter.ExternalSystemCode.Value   = vInteractionID;
		vRecordSet2.Filter.ExternalSystemCode.Use    = True;
		vRecordSet2.Write();
		
		vObj        = vRow.Ref.GetObject();
		vObj.InteractionID  = vInteractionID;
		vObj.Write();
	EndDo;
EndProcedure // RenameWubookSettings

// -----------------------------------------------------------------------------
Procedure FillInvoiceByEventObjectFormActions()
	vReservationFolder = Catalogs.ObjectFormActions.FindByCode("200");
	If TypeOf(Catalogs.ObjectFormActions.ReservationEventFillInvoice.ObjectType) <> Type("DocumentRef.Reservation") Then
		vFrmActObj = Catalogs.ObjectFormActions.ReservationEventFillInvoice.GetObject();
		vFrmActObj.ObjectType = Documents.Reservation.EmptyRef();
		If ValueIsFilled(vReservationFolder) And vReservationFolder.IsFolder Then
			vFrmActObj.Parent = vReservationFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Write();
	EndIf;
	vAccommodationFolder = Catalogs.ObjectFormActions.FindByCode("100");
	If TypeOf(Catalogs.ObjectFormActions.AccommodationEventFillInvoice.ObjectType) <> Type("DocumentRef.Accommodation") Then
		vFrmActObj = Catalogs.ObjectFormActions.AccommodationEventFillInvoice.GetObject();
		vFrmActObj.ObjectType = Documents.Accommodation.EmptyRef();
		If ValueIsFilled(vAccommodationFolder) And vAccommodationFolder.IsFolder Then
			vFrmActObj.Parent = vAccommodationFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Write();
	EndIf;
	vResourceReservationFolder = Catalogs.ObjectFormActions.FindByCode("1300");
	If TypeOf(Catalogs.ObjectFormActions.ResourceReservationEventFillInvoice.ObjectType) <> Type("DocumentRef.ResourceReservation") Then
		vFrmActObj = Catalogs.ObjectFormActions.ResourceReservationEventFillInvoice.GetObject();
		vFrmActObj.ObjectType = Documents.ResourceReservation.EmptyRef();
		If ValueIsFilled(vResourceReservationFolder) And vResourceReservationFolder.IsFolder Then
			vFrmActObj.Parent = vResourceReservationFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Write();
	EndIf;
EndProcedure // FillInvoiceByEventObjectFormActions

// -----------------------------------------------------------------------------
Procedure FillOrderActionSetings()
	If TypeOf(Catalogs.ObjectFormActions.ReservationFillOrder.ObjectType) <> Type("DocumentRef.Reservation") Then
		vFolder = Catalogs.ObjectFormActions.FindByCode("200");
		vFormActObj = Catalogs.ObjectFormActions.ReservationFillOrder.GetObject();
		vFormActObj.ObjectType = Documents.Reservation.EmptyRef();
		If ValueIsFilled(vFolder) And vFolder.IsFolder Then
			vFormActObj.Parent = vFolder;
		EndIf;
		vFormActObj.IsActive = True;
		vFormActObj.Remarks = "";
		vFormActObj.Write();
	EndIf;
	If TypeOf(Catalogs.ObjectFormActions.AccommodationFillOrder.ObjectType) <> Type("DocumentRef.Accommodation") Then
		vFolder = Catalogs.ObjectFormActions.FindByCode("100");
		vFormActObj = Catalogs.ObjectFormActions.AccommodationFillOrder.GetObject();
		vFormActObj.ObjectType = Documents.Accommodation.EmptyRef();
		If ValueIsFilled(vFolder) And vFolder.IsFolder Then
			vFormActObj.Parent = vFolder;
		EndIf;
		vFormActObj.IsActive = True;
		vFormActObj.Remarks = "";
		vFormActObj.Write();
	EndIf;
	If TypeOf(Catalogs.ObjectFormActions.ResourceReservationFillOrder.ObjectType) <> Type("DocumentRef.ResourceReservation") Then
		vFolder = Catalogs.ObjectFormActions.FindByCode("1300");
		vFormActObj = Catalogs.ObjectFormActions.ResourceReservationFillOrder.GetObject();
		vFormActObj.ObjectType = Documents.ResourceReservation.EmptyRef();
		If ValueIsFilled(vFolder) And vFolder.IsFolder Then
			vFormActObj.Parent = vFolder;
		EndIf;
		vFormActObj.IsActive = True;
		vFormActObj.Remarks = "";
		vFormActObj.Write();
	EndIf;
	If TypeOf(Catalogs.ObjectFormActions.FolioFillOrder.ObjectType) <> Type("DocumentRef.Folio") Then
		vFolder = Catalogs.ObjectFormActions.FindByCode("500");
		vFormActObj = Catalogs.ObjectFormActions.FolioFillOrder.GetObject();
		vFormActObj.ObjectType = Documents.Folio.EmptyRef();
		If ValueIsFilled(vFolder) And vFolder.IsFolder Then
			vFormActObj.Parent = vFolder;
		EndIf;
		vFormActObj.IsActive = True;
		vFormActObj.Remarks = "";
		vFormActObj.Write();
	EndIf;
EndProcedure // FillOrderActionSetings

// -----------------------------------------------------------------------------
Procedure ChangeWuBookWSHost()
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ExternalSystemInteractions.Ref  AS Ref
		|FROM
		|	Catalog.ExternalSystemInteractions AS ExternalSystemInteractions
		|WHERE
		|	NOT ExternalSystemInteractions.DeletionMark
		|	AND ExternalSystemInteractions.WSHost = ""wubook.net""";
	
	vQueryResult = vQuery.Execute().Unload();
	For each vRow in vQueryResult Do
		vObj = vRow.Ref.GetObject();
		vObj.WSHost = "wired.wubook.net";
		vObj.Write();
	EndDo;	
EndProcedure

// -----------------------------------------------------------------------------
Procedure FillSettlementObjectPrintingFormsForPrintingInvoice()
	vSettlementFolder = Catalogs.ObjectPrintingForms.FindByCode("700", False, Catalogs.ObjectPrintingForms.EmptyRef());
	If TypeOf(Catalogs.ObjectPrintingForms.SettlementPrintInvoiceRu.ObjectType) <> Type("DocumentRef.Settlement") Then
		vFrmPrtObj = Catalogs.ObjectPrintingForms.SettlementPrintInvoiceRu.GetObject();
		vFrmPrtObj.ObjectType = Documents.Settlement.EmptyRef();
		If ValueIsFilled(vSettlementFolder) And vSettlementFolder.IsFolder Then
			vFrmPrtObj.Parent = vSettlementFolder;
		EndIf;
		vFrmPrtObj.IsActive = True;
		vFrmPrtObj.Language = Catalogs.Languages.RU;
		vFrmPrtObj.Remarks = "";
		vFrmPrtObj.Write();
	EndIf;
	If TypeOf(Catalogs.ObjectPrintingForms.SettlementPrintInvoiceEn.ObjectType) <> Type("DocumentRef.Settlement") Then
		vFrmPrtObj = Catalogs.ObjectPrintingForms.SettlementPrintInvoiceEn.GetObject();
		vFrmPrtObj.ObjectType = Documents.Settlement.EmptyRef();
		If ValueIsFilled(vSettlementFolder) And vSettlementFolder.IsFolder Then
			vFrmPrtObj.Parent = vSettlementFolder;
		EndIf;
		vFrmPrtObj.IsActive = True;
		vFrmPrtObj.Language = Catalogs.Languages.EN;
		vFrmPrtObj.Remarks = "";
		vFrmPrtObj.Write();
	EndIf;
	If TypeOf(Catalogs.ObjectPrintingForms.SettlementPrintInvoiceDe.ObjectType) <> Type("DocumentRef.Settlement") Then
		vFrmPrtObj = Catalogs.ObjectPrintingForms.SettlementPrintInvoiceDe.GetObject();
		vFrmPrtObj.ObjectType = Documents.Settlement.EmptyRef();
		If ValueIsFilled(vSettlementFolder) And vSettlementFolder.IsFolder Then
			vFrmPrtObj.Parent = vSettlementFolder;
		EndIf;
		vFrmPrtObj.IsActive = True;
		vFrmPrtObj.Language = Catalogs.Languages.DE;
		vFrmPrtObj.Remarks = "";
		vFrmPrtObj.Write();
	EndIf;
EndProcedure // FillSettlementObjectPrintingFormsForPrintingInvoice

// -----------------------------------------------------------------------------
Procedure FillCustomerAndContractOpenInvoicesListObjectFormActions()
	vCustomerFolder = Catalogs.ObjectFormActions.FindByCode("1000");
	If TypeOf(Catalogs.ObjectFormActions.CustomerOpenInvoicesList.ObjectType) <> Type("CatalogRef.Customers") Then
		vFrmActObj = Catalogs.ObjectFormActions.CustomerOpenInvoicesList.GetObject();
		vFrmActObj.ObjectType = Catalogs.Customers.EmptyRef();
		If ValueIsFilled(vCustomerFolder) And vCustomerFolder.IsFolder Then
			vFrmActObj.Parent = vCustomerFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Write();
	EndIf;
	vContractFolder = Catalogs.ObjectFormActions.FindByCode("1100");
	If TypeOf(Catalogs.ObjectFormActions.ContractOpenInvoicesList.ObjectType) <> Type("CatalogRef.Contracts") Then
		vFrmActObj = Catalogs.ObjectFormActions.ContractOpenInvoicesList.GetObject();
		vFrmActObj.ObjectType = Catalogs.Contracts.EmptyRef();
		If ValueIsFilled(vContractFolder) And vContractFolder.IsFolder Then
			vFrmActObj.Parent = vContractFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Write();
	EndIf;
EndProcedure // FillCustomerAndContractOpenInvoicesListObjectFormActions

// -----------------------------------------------------------------------------
Procedure FillPersonalDataProcessingSettings()
	vClientFolder = Catalogs.ObjectFormActions.FindByCode("1500");
	If TypeOf(Catalogs.ObjectFormActions.ClientPersonalDataProcessingConsent.ObjectType) <> Type("CatalogRef.Clients") Then
		vFrmActObj = Catalogs.ObjectFormActions.ClientPersonalDataProcessingConsent.GetObject();
		vFrmActObj.ObjectType = Catalogs.Clients.EmptyRef();
		If ValueIsFilled(vClientFolder) And vClientFolder.IsFolder Then
			vFrmActObj.Parent = vClientFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Write();
	EndIf;
	If TypeOf(Catalogs.ObjectFormActions.ClientPersonalDataProcessingRefusal.ObjectType) <> Type("CatalogRef.Clients") Then
		vFrmActObj = Catalogs.ObjectFormActions.ClientPersonalDataProcessingRefusal.GetObject();
		vFrmActObj.ObjectType = Catalogs.Clients.EmptyRef();
		If ValueIsFilled(vClientFolder) And vClientFolder.IsFolder Then
			vFrmActObj.Parent = vClientFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Write();
	EndIf;
	vFolder = Catalogs.ObjectPrintingForms.FindByCode("200", False, Catalogs.ObjectPrintingForms.EmptyRef());
	If TypeOf(Catalogs.ObjectPrintingForms.ReservationPrintGuestRegistrationForm.ObjectType) <> Type("DocumentRef.Reservation") Then
		vFrmPrtFrmObj = Catalogs.ObjectPrintingForms.ReservationPrintGuestRegistrationForm.GetObject();
		vFrmPrtFrmObj.ObjectType = Documents.Reservation.EmptyRef();
		If ValueIsFilled(vFolder) And vFolder.IsFolder Then
			vFrmPrtFrmObj.Parent = vFolder;
		EndIf;
		vFrmPrtFrmObj.IsActive = True;
		vFrmPrtFrmObj.Write();
	EndIf;
	If TypeOf(Catalogs.ObjectPrintingForms.ReservationPrintGuestRegistrationForms.ObjectType) <> Type("DocumentRef.Reservation") Then
		vFrmPrtFrmObj = Catalogs.ObjectPrintingForms.ReservationPrintGuestRegistrationForms.GetObject();
		vFrmPrtFrmObj.ObjectType = Documents.Reservation.EmptyRef();
		If ValueIsFilled(vFolder) And vFolder.IsFolder Then
			vFrmPrtFrmObj.Parent = vFolder;
		EndIf;
		vFrmPrtFrmObj.IsActive = True;
		vFrmPrtFrmObj.Write();
	EndIf;
EndProcedure // FillPersonalDataProcessingSettings

// -----------------------------------------------------------------------------
Function GetReportsFolderByCode(pCode)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reports.Ref  AS Ref
	|FROM
	|	Catalog.Reports AS Reports
	|WHERE
	|	Reports.IsFolder
	|	AND NOT Reports.DeletionMark
	|	AND Reports.Code = &qCode";
	vQry.SetParameter("qCode", pCode);
	vFolders = vQry.Execute().Unload();
	If vFolders.Count() > 0 Then
		Return vFolders.Get(0).Ref;
	Else
		Return Undefined;
	EndIf;
EndFunction // GetReportsFolderByCode

// -----------------------------------------------------------------------------
Procedure FillCurrencyConversionSettings()
	vShiftFolder = Catalogs.ObjectFormActions.FindByCode("600");
	If TypeOf(Catalogs.ObjectFormActions.CashRegisterCurrencyConversions.ObjectType) <> Type("CatalogRef.CashRegisters") Then
		vFrmActObj = Catalogs.ObjectFormActions.CashRegisterCurrencyConversions.GetObject();
		vFrmActObj.ObjectType = Catalogs.CashRegisters.EmptyRef();
		If ValueIsFilled(vShiftFolder) And vShiftFolder.IsFolder Then
			vFrmActObj.Parent = vShiftFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Write();
	EndIf;
	// Fill currency conversion report settings
	vRepRef = Catalogs.Reports.ForeignCurrencyExchange;
	vRepFolder = GetReportsFolderByCode(100);
	If ValueIsFilled(vRepRef) And Not ValueIsFilled(vRepRef.Report) Then
		vRepObj = vRepRef.GetObject();
		vRepObj.Report = "ForeignCurrencyExchange";
		If ValueIsFilled(vRepFolder) And vRepFolder.IsFolder Then
			vRepObj.Parent = vRepFolder;
		EndIf;
		vRepObj.SortCode = vRepObj.Code;
		vRepObj.DynamicParameters = "REP.PeriodFrom = BegOfDay(CurrentSessionDate());
		                            |REP.PeriodTo = EndOfDay(REP.PeriodFrom);";
		Try
			vRepObj.Write();
		Except
		EndTry;
	EndIf;
EndProcedure // FillCurrencyConversionSettings

// -----------------------------------------------------------------------------
Procedure FillFanIDSettings()
	vTypesArray = New Array;
	vTypesArray.Add(Type("Number"));
	vTypesArray.Add(Type("Boolean"));
	vTypesArray.Add(Type("Date"));
	Try
		If NOT ValueIsFilled(ChartsOfCharacteristicTypes.LimitsAndSpecialConditionTypes.FindByAttribute("XMLElementName", "fan_id")) Then
			vNewObj = ChartsOfCharacteristicTypes.LimitsAndSpecialConditionTypes.CreateItem(); 
			vNewObj.Description = NStr("en = 'Fan id'; ru = 'Паспорт болельщика (ID)'; de = 'Fan id'");
			vNewObj.XMLElementName = "fan_id";
			vNewObj.ValueType = New TypeDescription(vNewObj.ValueType, , vTypesArray);
			vNewObj.Write();
		EndIf;
	Except
		vError = ErrorDescription();
		tcCommonFunctionOnClientServer.TextMessage("Не удалось создать элемент плана видов характеристик 'Виды лимитов и специальных условий клиентов' 'Паспорт болельщика (ID)': " + vError);
	EndTry;
	
	Try
		If NOT ValueIsFilled(ChartsOfCharacteristicTypes.LimitsAndSpecialConditionTypes.FindByAttribute("XMLElementName", "fan_id_number")) Then
			vNewObj = ChartsOfCharacteristicTypes.LimitsAndSpecialConditionTypes.CreateItem(); 
			vNewObj.Description = NStr("en = 'Fan id seq. number'; ru = 'Паспорт болельщика (Номер бланка)'; de = 'Fan id seq. number'");
			vNewObj.XMLElementName = "fan_id_number";
			vNewObj.ValueType = New TypeDescription(vNewObj.ValueType, , vTypesArray);
			vNewObj.Write();
		EndIf;
	Except
		vError = ErrorDescription();
		tcCommonFunctionOnClientServer.TextMessage("Не удалось создать элемент плана видов характеристик 'Виды лимитов и специальных условий клиентов' 'Паспорт болельщика (Номер бланка)': " + vError);
	EndTry;
	
	Try
		If NOT ValueIsFilled(Catalogs.ScanConfigurations.FindByAttribute("IsFanId", True)) Then
			vNewObj = Catalogs.ScanConfigurations.CreateItem();
			vNewObj.SetNewCode();
			vNewObj.Description = NStr("en = 'Fan id'; ru = 'Паспорт болельщика'; de = 'Fan id'");
			vNewObj.IsFanID = True;
			vNewObj.Write();
		EndIf;
	Except
		vError = ErrorDescription();
		tcCommonFunctionOnClientServer.TextMessage("Не удалось создать элемент справочника 'Конфигурации сканирования' 'Паспорт болельщика': " + vError);
	EndTry;
EndProcedure // FillFanIDSettings

// -----------------------------------------------------------------------------
Procedure FillAccommodationFillClientFeedbackActionSetings()
	If TypeOf(Catalogs.ObjectFormActions.AccommodationFillClientFeedback.ObjectType) <> Type("DocumentRef.Accommodation") Then
		vAccommodationFolder = Catalogs.ObjectFormActions.FindByCode("100");
		vFormActObj = Catalogs.ObjectFormActions.AccommodationFillClientFeedback.GetObject();
		vFormActObj.ObjectType = Documents.Accommodation.EmptyRef();
		If ValueIsFilled(vAccommodationFolder) And vAccommodationFolder.IsFolder Then
			vFormActObj.Parent = vAccommodationFolder;
		EndIf;
		vFormActObj.IsActive = True;
		vFormActObj.Remarks = "";
		vFormActObj.Write();
	EndIf;
EndProcedure // FillAccommodationFillClientFeedbackActionSetings

// -----------------------------------------------------------------------------
Procedure UpdateAccommodationDocumentNumbers()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref AS Ref,
	|	Accommodation.Number AS Number,
	|	Accommodation.Room AS Room,
	|	Accommodation.GuestGroup AS GuestGroup,
	|	Accommodation.Reservation AS Reservation,
	|	Accommodation.Reservation.Number AS ReservationNumber,
	|	Accommodation.AccommodationType.Type AS AccommodationTypeType
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.CheckInDate > &qPeriodFrom
	|
	|ORDER BY
	|	Accommodation.Hotel.Code,
	|	Accommodation.Room.SortCode,
	|	Accommodation.CheckInDate,
	|	Accommodation.GuestGroup.Code,
	|	Accommodation.AccommodationType.SortCode";
	vQry.SetParameter("qPeriodFrom", '20150101');
	vDocs = vQry.Execute().Unload();
	vRoomDoc = Undefined;
	For Each vDocsRow In vDocs Do
		If ValueIsFilled(vDocsRow.Reservation) Then
			If vDocsRow.Number <> vDocsRow.ReservationNumber Then
				vDocObj = vDocsRow.Ref.GetObject();
				vDocObj.Number = vDocsRow.ReservationNumber;
				vDocObj.Write(DocumentWriteMode.Write);
			EndIf;
		Else
			If vDocsRow.AccommodationTypeType = Enums.AccomodationTypes.Room Or vDocsRow.AccommodationTypeType = Enums.AccomodationTypes.Beds Then
				vRoomDoc = vDocsRow.Ref;
			EndIf;
			If ValueIsFilled(vRoomDoc) And vRoomDoc.Room = vDocsRow.Room And vRoomDoc.GuestGroup = vDocsRow.GuestGroup Then
				If vDocsRow.Number <> vRoomDoc.Number Then
					vDocObj = vDocsRow.Ref.GetObject();
					vDocObj.Number = vRoomDoc.Number;
					vDocObj.Write(DocumentWriteMode.Write);
				EndIf;
			EndIf;
		EndIf;
		#If ThickClientOrdinaryApplication Then
			Status(NStr("en='Processed '; ru='Обработано '; de='Processed '") + (vDocs.IndexOf(vDocsRow) + 1) + NStr("en=' accommodations from '; ru=' размещений из '; de=' accommodations from '") + vDocs.Count());
		#EndIf
	EndDo;
EndProcedure // UpdateAccommodationDocumentNumbers

// -----------------------------------------------------------------------------
Procedure FillFolioPrintPKOByPayment()
	vFolioFolder = Catalogs.ObjectPrintingForms.FindByCode("500", False, Catalogs.ObjectPrintingForms.EmptyRef());
	If TypeOf(Catalogs.ObjectPrintingForms.FolioPrintPKOByPayment.ObjectType) <> Type("DocumentRef.Folio") Then
		vFrmPrtObj = Catalogs.ObjectPrintingForms.FolioPrintPKOByPayment.GetObject();
		vFrmPrtObj.ObjectType = Documents.Folio.EmptyRef();
		If ValueIsFilled(vFolioFolder) And vFolioFolder.IsFolder Then
			vFrmPrtObj.Parent = vFolioFolder;
		EndIf;
		vFrmPrtObj.IsActive = True;
		vFrmPrtObj.Remarks = "";
		vFrmPrtObj.Write();
	EndIf;
EndProcedure // FillFolioPrintPKOByPayment

// -----------------------------------------------------------------------------
Procedure FillCustomerFillCreditAndDebitNotesObjectFormActions()
	vCustomerFolder = Catalogs.ObjectFormActions.FindByCode("1000");
	If TypeOf(Catalogs.ObjectFormActions.CustomerFillCreditNote.ObjectType) <> Type("CatalogRef.Customers") Then
		vFrmActObj = Catalogs.ObjectFormActions.CustomerFillCreditNote.GetObject();
		vFrmActObj.ObjectType = Catalogs.Customers.EmptyRef();
		If ValueIsFilled(vCustomerFolder) And vCustomerFolder.IsFolder Then
			vFrmActObj.Parent = vCustomerFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Write();
	EndIf;
	If TypeOf(Catalogs.ObjectFormActions.CustomerFillDebitNote.ObjectType) <> Type("CatalogRef.Customers") Then
		vFrmActObj = Catalogs.ObjectFormActions.CustomerFillDebitNote.GetObject();
		vFrmActObj.ObjectType = Catalogs.Customers.EmptyRef();
		If ValueIsFilled(vCustomerFolder) And vCustomerFolder.IsFolder Then
			vFrmActObj.Parent = vCustomerFolder;
		EndIf;
		vFrmActObj.IsActive = True;
		vFrmActObj.Write();
	EndIf;
EndProcedure // FillCustomerFillCreditAndDebitNotesObjectFormActions

// -----------------------------------------------------------------------------
Procedure FillAccommodationPrintGuestRefusalToPayResortFeeObjectPrintingFormSettings()
	If TypeOf(Catalogs.ObjectPrintingForms.AccommodationPrintGuestRefusalToPayResortFee.ObjectType) <> Type("DocumentRef.Accommodation") Then
		vAccommodationFolder = Catalogs.ObjectPrintingForms.FindByCode("100", False, Catalogs.ObjectPrintingForms.EmptyRef());
		vPrtFormObj = Catalogs.ObjectPrintingForms.AccommodationPrintGuestRefusalToPayResortFee.GetObject();
		vPrtFormObj.ObjectType = Documents.Accommodation.EmptyRef();
		If ValueIsFilled(vAccommodationFolder) And vAccommodationFolder.IsFolder Then
			vPrtFormObj.Parent = vAccommodationFolder;
		EndIf;
		vPrtFormObj.IsActive = True;
		vPrtFormObj.Remarks = "";
		vPrtFormObj.Write();
	EndIf;
EndProcedure // FillAccommodationPrintGuestRefusalToPayResortFeeObjectPrintingFormSettings

// -----------------------------------------------------------------------------
Procedure FillAccommodationPrintGuestPersonalDataProcessingConsentObjectPrintingFormSettings()
	If TypeOf(Catalogs.ObjectPrintingForms.AccommodationPrintGuestPersonalDataProcessingConsent.ObjectType) <> Type("DocumentRef.Accommodation") Then
		vAccommodationFolder = Catalogs.ObjectPrintingForms.FindByCode("100", False, Catalogs.ObjectPrintingForms.EmptyRef());
		vPrtFormObj = Catalogs.ObjectPrintingForms.AccommodationPrintGuestPersonalDataProcessingConsent.GetObject();
		vPrtFormObj.ObjectType = Documents.Accommodation.EmptyRef();
		If ValueIsFilled(vAccommodationFolder) And vAccommodationFolder.IsFolder Then
			vPrtFormObj.Parent = vAccommodationFolder;
		EndIf;
		vPrtFormObj.IsActive = True;
		vPrtFormObj.Remarks = "";
		vPrtFormObj.Write();
	EndIf;
EndProcedure // FillAccommodationPrintGuestPersonalDataProcessingConsentObjectPrintingFormSettings

// -----------------------------------------------------------------------------
Procedure FillDirectPostingsPrintChargedTransactionsObjectPrintingFormSettings()
	vPrtForm = Catalogs.ObjectPrintingForms.DirectPostingsPrintChargedTransactions;
	If ValueIsFilled(vPrtForm) And Not vPrtForm.IsActive Then
		vPrtFormObj = vPrtForm.GetObject();
		vPrtFormObj.ObjectType = Undefined;
		vPrtFormObj.IsActive = True;
		vPrtFormObj.Remarks = "";
		vPrtFormObj.Write();
	EndIf;
EndProcedure // FillDirectPostingsPrintChargedTransactionsObjectPrintingFormSettings

// -----------------------------------------------------------------------------
Function GetAccommodationTemplateAccommodationTypes(pAccommodationTemplate)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	AccommodationTemplatesAccommodationTypes.AccommodationType AS AccommodationType,
	|	AccommodationTemplatesAccommodationTypes.AccommodationType.Code AS AccommodationTypeCode
	|FROM
	|	Catalog.AccommodationTemplates.AccommodationTypes AS AccommodationTemplatesAccommodationTypes
	|WHERE
	|	AccommodationTemplatesAccommodationTypes.Ref = &qAccommodationTemplate
	|
	|ORDER BY
	|	AccommodationTemplatesAccommodationTypes.AccommodationType.SortCode";
	vQry.SetParameter("qAccommodationTemplate", pAccommodationTemplate);
	vAccTypes = vQry.Execute().Unload();
	Return vAccTypes;
EndFunction // GetAccommodationTemplateAccommodationTypes

// -----------------------------------------------------------------------------
Procedure FillAccommodationTemplateAndNumberOfPersons()
	// Fill table with accommodation template hash codes
	vAccTemplateHashes = New ValueTable();
	vAccTemplateHashes.Columns.Add("Hotel");
	vAccTemplateHashes.Columns.Add("AccommodationTemplate");
	vAccTemplateHashes.Columns.Add("Hash");
	vAccTemplateHashes.Columns.Add("RoomTypesList");
	vAllHotels = cmGetAllHotels();
	For Each vAllHotelsRow In vAllHotels Do
		vAllAccTemplates = cmGetAllAccommodationTemplates(vAllHotelsRow.Hotel);
		For Each vAllAccTemplatesRow In vAllAccTemplates Do
			vAccommodationTemplate = vAllAccTemplatesRow.AccommodationTemplate;
			vRoomTypesList = New ValueList();
			vRoomTypesList.LoadValues(vAccommodationTemplate.RoomTypes.UnloadColumn("RoomType"));
			vAccTemplateAccTypes = GetAccommodationTemplateAccommodationTypes(vAccommodationTemplate);
			vHash = "";
			For Each vAccTemplateAccTypesRow In vAccTemplateAccTypes Do
				vHash = vHash + ?(vHash = "", "", ",") + TrimAll(vAccTemplateAccTypesRow.AccommodationTypeCode);
			EndDo;
			
			vAccTemplateHashesRow = vAccTemplateHashes.Add();
			vAccTemplateHashesRow.Hotel = vAllHotelsRow.Hotel;
			vAccTemplateHashesRow.AccommodationTemplate = vAccommodationTemplate;
			vAccTemplateHashesRow.Hash = vHash;
			vAccTemplateHashesRow.RoomTypesList = vRoomTypesList;
		EndDo;
	EndDo;
	
	// Process accommodations
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref AS Ref,
	|	Accommodation.Number AS Number,
	|	Accommodation.Hotel AS Hotel,
	|	Accommodation.Room AS Room,
	|	Accommodation.RoomType AS RoomType,
	|	Accommodation.GuestGroup AS GuestGroup,
	|	Accommodation.CheckInDate AS CheckInDate,
	|	Accommodation.AccommodationType AS AccommodationType,
	|	Accommodation.AccommodationType.Code AS AccommodationTypeCode
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.CheckInDate > &qPeriodFrom
	|	AND Accommodation.AccommodationTemplate = &qEmptyAccommodationTemplate
	|
	|ORDER BY
	|	Accommodation.Hotel.Code,
	|	Accommodation.GuestGroup.Code,
	|	Accommodation.Room.SortCode,
	|	Accommodation.CheckInDate,
	|	Accommodation.AccommodationType.SortCode";
	vQry.SetParameter("qPeriodFrom", '20150101');
	vQry.SetParameter("qEmptyAccommodationTemplate", Catalogs.AccommodationTemplates.EmptyRef());
	vDocs = vQry.Execute().Unload();
	vCurMainRoomDoc = Undefined;
	vCurGuestGroup = Undefined;
	vCurRoom = Undefined;
	vCurCheckInDate = '00010101';
	vCurAccTemplateHash = "";
	For Each vDocsRow In vDocs Do
		If vCurGuestGroup <> vDocsRow.GuestGroup Or vCurRoom <> vDocsRow.Room Or vCurCheckInDate <> BegOfDay(vDocsRow.CheckInDate) Then
			// Process current room
			If vCurMainRoomDoc <> Undefined Then
				vAccTemplate = Undefined;
				vAccTemplateHashesRows = vAccTemplateHashes.FindRows(New Structure("Hotel, Hash", vCurMainRoomDoc.Hotel, vCurAccTemplateHash));
				If vAccTemplateHashesRows.Count() > 0 Then
					For Each vAccTemplateHashesRow In vAccTemplateHashesRows Do
						vRoomTypesList = vAccTemplateHashesRow.RoomTypesList;
						If vRoomTypesList.Count() = 0 Or vRoomTypesList.FindByValue(vCurMainRoomDoc.RoomType) <> Undefined Then
							vAccTemplate = vAccTemplateHashesRow.AccommodationTemplate;
							Break;
						EndIf;
					EndDo;
				EndIf;
				If vAccTemplate <> Undefined Then
					vCurMainRoomDocObj = vCurMainRoomDoc.GetObject();
					vCurMainRoomDocObj.AccommodationTemplate = vAccTemplate;
					vCurMainRoomDocObj.NumberOfAdults = vAccTemplate.NumberOfAdults;
					vCurMainRoomDocObj.NumberOfTeenagers = vAccTemplate.NumberOfTeenagers;
					vCurMainRoomDocObj.NumberOfChildren = vAccTemplate.NumberOfChildren;
					vCurMainRoomDocObj.NumberOfInfants = vAccTemplate.NumberOfInfants;
					vCurMainRoomDocObj.Write(DocumentWriteMode.Write);
				EndIf;
				vCurMainRoomDoc = Undefined;
			EndIf;
			
			// Start new room
			vCurMainRoomDoc = vDocsRow.Ref;
			vCurAccTemplateHash = TrimAll(vDocsRow.AccommodationTypeCode);
			
			vCurGuestGroup = vDocsRow.GuestGroup;
			vCurRoom = vDocsRow.Room;
			vCurCheckInDate = BegOfDay(vDocsRow.CheckInDate);
		Else
			vCurAccTemplateHash = vCurAccTemplateHash + ?(vCurAccTemplateHash = "", "", ",") + TrimAll(vDocsRow.AccommodationTypeCode);
		EndIf;
		#If ThickClientOrdinaryApplication Then
			Status(NStr("en='Processed '; ru='Обработано '; de='Processed '") + (vDocs.IndexOf(vDocsRow) + 1) + NStr("en=' accommodations from '; ru=' размещений из '; de=' accommodations from '") + vDocs.Count());
		#EndIf
	EndDo;
	If vCurMainRoomDoc <> Undefined Then
		vAccTemplate = Undefined;
		vAccTemplateHashesRows = vAccTemplateHashes.FindRows(New Structure("Hotel, Hash", vCurMainRoomDoc.Hotel, vCurAccTemplateHash));
		If vAccTemplateHashesRows.Count() > 0 Then
			For Each vAccTemplateHashesRow In vAccTemplateHashesRows Do
				vRoomTypesList = vAccTemplateHashesRow.RoomTypesList;
				If vRoomTypesList.Count() = 0 Or vRoomTypesList.FindByValue(vCurMainRoomDoc.RoomType) <> Undefined Then
					vAccTemplate = vAccTemplateHashesRow.AccommodationTemplate;
					Break;
				EndIf;
			EndDo;
		EndIf;
		If vAccTemplate <> Undefined Then
			vCurMainRoomDocObj = vCurMainRoomDoc.GetObject();
			vCurMainRoomDocObj.AccommodationTemplate = vAccTemplate;
			vCurMainRoomDocObj.NumberOfAdults = vAccTemplate.NumberOfAdults;
			vCurMainRoomDocObj.NumberOfTeenagers = vAccTemplate.NumberOfTeenagers;
			vCurMainRoomDocObj.NumberOfChildren = vAccTemplate.NumberOfChildren;
			vCurMainRoomDocObj.NumberOfInfants = vAccTemplate.NumberOfInfants;
			vCurMainRoomDocObj.Write(DocumentWriteMode.Write);
		EndIf;
	EndIf;
	
	// Process reservations
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservation.Ref AS Ref,
	|	Reservation.Number AS Number,
	|	Reservation.Hotel AS Hotel,
	|	Reservation.Room AS Room,
	|	Reservation.RoomType AS RoomType,
	|	Reservation.GuestGroup AS GuestGroup,
	|	Reservation.CheckInDate AS CheckInDate,
	|	Reservation.AccommodationType AS AccommodationType,
	|	Reservation.AccommodationType.Code AS AccommodationTypeCode
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.Posted
	|	AND (Reservation.ReservationStatus.IsActive
	|			OR Reservation.ReservationStatus.IsCheckIn
	|			OR Reservation.ReservationStatus.IsPreliminary)
	|	AND Reservation.CheckInDate > &qPeriodFrom
	|	AND Reservation.AccommodationTemplate = &qEmptyAccommodationTemplate
	|
	|ORDER BY
	|	Reservation.Hotel.Code,
	|	Reservation.GuestGroup.Code,
	|	Reservation.Room.SortCode,
	|	Reservation.Number,
	|	Reservation.CheckInDate,
	|	Reservation.AccommodationType.SortCode";
	vQry.SetParameter("qPeriodFrom", '20150101');
	vQry.SetParameter("qEmptyAccommodationTemplate", Catalogs.AccommodationTemplates.EmptyRef());
	vDocs = vQry.Execute().Unload();
	vCurMainRoomDoc = Undefined;
	vCurGuestGroup = Undefined;
	vCurRoom = Undefined;
	vCurNumber = Undefined;
	vCurCheckInDate = '00010101';
	vCurAccTemplateHash = "";
	For Each vDocsRow In vDocs Do
		If vCurGuestGroup <> vDocsRow.GuestGroup Or vCurRoom <> vDocsRow.Room Or vCurNumber <> vDocsRow.Number Or vCurCheckInDate <> BegOfDay(vDocsRow.CheckInDate) Then
			// Process current room
			If vCurMainRoomDoc <> Undefined Then
				vAccTemplate = Undefined;
				vAccTemplateHashesRows = vAccTemplateHashes.FindRows(New Structure("Hotel, Hash", vCurMainRoomDoc.Hotel, vCurAccTemplateHash));
				If vAccTemplateHashesRows.Count() > 0 Then
					For Each vAccTemplateHashesRow In vAccTemplateHashesRows Do
						vRoomTypesList = vAccTemplateHashesRow.RoomTypesList;
						If vRoomTypesList.Count() = 0 Or vRoomTypesList.FindByValue(vCurMainRoomDoc.RoomType) <> Undefined Then
							vAccTemplate = vAccTemplateHashesRow.AccommodationTemplate;
							Break;
						EndIf;
					EndDo;
				EndIf;
				If vAccTemplate <> Undefined Then
					vCurMainRoomDocObj = vCurMainRoomDoc.GetObject();
					vCurMainRoomDocObj.AccommodationTemplate = vAccTemplate;
					vCurMainRoomDocObj.NumberOfAdults = vAccTemplate.NumberOfAdults;
					vCurMainRoomDocObj.NumberOfTeenagers = vAccTemplate.NumberOfTeenagers;
					vCurMainRoomDocObj.NumberOfChildren = vAccTemplate.NumberOfChildren;
					vCurMainRoomDocObj.NumberOfInfants = vAccTemplate.NumberOfInfants;
					vCurMainRoomDocObj.Write(DocumentWriteMode.Write);
				EndIf;
				vCurMainRoomDoc = Undefined;
			EndIf;
			
			// Start new room
			vCurMainRoomDoc = vDocsRow.Ref;
			vCurAccTemplateHash = TrimAll(vDocsRow.AccommodationTypeCode);
			
			vCurGuestGroup = vDocsRow.GuestGroup;
			vCurRoom = vDocsRow.Room;
			vCurNumber = vDocsRow.Number;
			vCurCheckInDate = BegOfDay(vDocsRow.CheckInDate);
		Else
			vCurAccTemplateHash = vCurAccTemplateHash + ?(vCurAccTemplateHash = "", "", ",") + TrimAll(vDocsRow.AccommodationTypeCode);
		EndIf;
		If vCurMainRoomDoc <> Undefined Then
			vAccTemplate = Undefined;
			vAccTemplateHashesRows = vAccTemplateHashes.FindRows(New Structure("Hotel, Hash", vCurMainRoomDoc.Hotel, vCurAccTemplateHash));
			If vAccTemplateHashesRows.Count() > 0 Then
				For Each vAccTemplateHashesRow In vAccTemplateHashesRows Do
					vRoomTypesList = vAccTemplateHashesRow.RoomTypesList;
					If vRoomTypesList.Count() = 0 Or vRoomTypesList.FindByValue(vCurMainRoomDoc.RoomType) <> Undefined Then
						vAccTemplate = vAccTemplateHashesRow.AccommodationTemplate;
						Break;
					EndIf;
				EndDo;
			EndIf;
			If vAccTemplate <> Undefined Then
				vCurMainRoomDocObj = vCurMainRoomDoc.GetObject();
				vCurMainRoomDocObj.AccommodationTemplate = vAccTemplate;
				vCurMainRoomDocObj.NumberOfAdults = vAccTemplate.NumberOfAdults;
				vCurMainRoomDocObj.NumberOfTeenagers = vAccTemplate.NumberOfTeenagers;
				vCurMainRoomDocObj.NumberOfChildren = vAccTemplate.NumberOfChildren;
				vCurMainRoomDocObj.NumberOfInfants = vAccTemplate.NumberOfInfants;
				vCurMainRoomDocObj.Write(DocumentWriteMode.Write);
			EndIf;
		EndIf;
		#If ThickClientOrdinaryApplication Then
			Status(NStr("en='Processed '; ru='Обработано '; de='Processed '") + (vDocs.IndexOf(vDocsRow) + 1) + NStr("en=' reservations from '; ru=' броней из '; de=' reservations from '") + vDocs.Count());
		#EndIf
	EndDo;
EndProcedure // FillAccommodationTemplateAndNumberOfPersons

// -----------------------------------------------------------------------------
Procedure FillVATRateTaxRatesHistory()
	// Get all VAT rates
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	VATRates.Ref AS Ref,
	|	VATRates.TaxRate AS TaxRate
	|FROM
	|	Catalog.VATRates AS VATRates
	|WHERE
	|	NOT VATRates.DeletionMark
	|
	|ORDER BY
	|	VATRates.Code";
	vVATRates = vQry.Execute().Unload();
	// Write history records
	For Each vVATRatesRow In vVATRates Do
		vVATRate = vVATRatesRow.Ref;
		vTaxRate = vVATRatesRow.TaxRate;
		If vTaxRate = 18 Then
			vVATRateObj = vVATRate.GetObject();
			vVATRateObj.Description = "Осн.";
			vVATRateObj.Write();
			
			vMgr = InformationRegisters.VATRatesHistory.CreateRecordManager();
			vMgr.Period = '20040101';
			vMgr.VATRate = vVATRate;
			vMgr.TaxRate = vTaxRate;
			vMgr.Write(True);
			
			vMgr = InformationRegisters.VATRatesHistory.CreateRecordManager();
			vMgr.Period = '20190101';
			vMgr.VATRate = vVATRate;
			vMgr.TaxRate = 20;
			vMgr.Write(True);
		Else
			vMgr = InformationRegisters.VATRatesHistory.CreateRecordManager();
			vMgr.Period = '20040101';
			vMgr.VATRate = vVATRate;
			vMgr.TaxRate = vTaxRate;
			vMgr.Write(True);
		EndIf;
	EndDo;
EndProcedure // FillVATRateTaxRatesHistory

// -----------------------------------------------------------------------------
Procedure SwitchOffAutoCorrectionsOption()
	vAllHotels = cmGetAllHotels();
	For Each vAllHotelsRow In vAllHotels Do
		vHotelObj = vAllHotelsRow.Hotel.GetObject();
		vHotelObj.SwitchOffAutoCorrections = True;
		vHotelObj.Write();
	EndDo;
EndProcedure // SwitchOffAutoCorrectionsOption

// -----------------------------------------------------------------------------
Procedure FillRestaurantControlListReportSettings()
	// Create audit reports group first
	vSPIRFolder = Catalogs.Reports.FindByCode(100, , Catalogs.Reports.EmptyRef());
	If ValueIsFilled(vSPIRFolder) And Not vSPIRFolder.IsFolder Then
		vSPIRFolder = Catalogs.Reports.EmptyRef();
	EndIf;
	// Fill report name and report folder for new reports
	vRepRef = Catalogs.Reports.RestaurantControlList;
	If ValueIsFilled(vRepRef) And Not ValueIsFilled(vRepRef.Report) Then
		vRepObj = vRepRef.GetObject();
		vRepObj.Report = "RestaurantControlList"; 
		vRepObj.Parent = vSPIRFolder;
		vRepObj.SortCode = 973;
		vRepObj.DynamicParameters = "If ValueIsFilled(REP.Hotel) And ValueIsFilled(REP.Hotel.AccountingDate) Then
									|	REP.AccountingDate = REP.Hotel.AccountingDate;
									|Else
									|	REP.AccountingDate = BegOfDay(CurrentSessionDate());
									|EndIf;";
		vRepObj.DefaultSettings = New ValueStorage(cmReadReportDefaultSettingFromTemplate(vRepObj));
		vRepObj.Write();
		// Load this default report settings
		vReportObject = cmBuildReportObject(vRepObj.Ref);
		vReportObject.Report = vRepObj.Ref;
		#If Client Then
			cmLoadDefaultReportSettings(vReportObject);
		#EndIf
		// Save report settings
		vReportObject.pmSaveReportAttributes();
	EndIf;
EndProcedure // FillRestaurantControlListReportSettings 

// -----------------------------------------------------------------------------
Procedure FillForeignerRegistryRecordPrintDepartureNotificationPrintingFormSetings()
	If TypeOf(Catalogs.ObjectPrintingForms.ForeignerRegistryRecordPrintDepartureNotificationForm.ObjectType) <> Type("DocumentRef.ForeignerRegistryRecord") Then
		vForeignersFolder = Catalogs.ObjectPrintingForms.FindByCode("300", False, Catalogs.ObjectPrintingForms.EmptyRef());
		vPrtFormObj = Catalogs.ObjectPrintingForms.ForeignerRegistryRecordPrintDepartureNotificationForm.GetObject();
		vPrtFormObj.ObjectType = Documents.ForeignerRegistryRecord.EmptyRef();
		If ValueIsFilled(vForeignersFolder) And vForeignersFolder.IsFolder Then
			vPrtFormObj.Parent = vForeignersFolder;
		EndIf;
		vPrtFormObj.IsActive = True;
		vPrtFormObj.Remarks = "";
		vPrtFormObj.Write();
	EndIf;
EndProcedure // FillForeignerRegistryRecordPrintDepartureNotificationPrintingFormSetings

// -----------------------------------------------------------------------------
Procedure FillLoyaltyType()
	// Fill discount type
	vDiscountTypes = Catalogs.DiscountTypes.Select();
	While vDiscountTypes.Next() Do
		If Not vDiscountTypes.IsFolder And Not vDiscountTypes.DeletionMark Then
			If Not ValueIsFilled(vDiscountTypes.LoyaltyType) Then
				vObj = vDiscountTypes.GetObject();
				If vObj.BonusCalculationFactor > 0 Or vObj.ExternalBonusSystemIsUsed Then
					vObj.LoyaltyType = Enums.LoyaltyType.Bonuses;
				Else
					vObj.LoyaltyType = Enums.LoyaltyType.Discount;
				EndIf;
				vObj.Write();
			EndIf;
		EndIf;
	EndDo;	
	// Fill discount card
	vDiscountCards = Catalogs.DiscountCards.Select();
	While vDiscountCards.Next() Do
		If Not vDiscountCards.IsFolder And Not vDiscountCards.DeletionMark Then
			If Not ValueIsFilled(vDiscountCards.LoyaltyType) Then
				vObj = vDiscountCards.GetObject();
				If ValueIsFilled(vDiscountCards.DiscountType) And ValueIsFilled(vDiscountCards.DiscountType.LoyaltyType) Then
					Try
						vObj.LoyaltyType = vDiscountCards.DiscountType.LoyaltyType;
						vObj.Write();
					Except
					EndTry;
				EndIf;
			EndIf;
		EndIf;
	EndDo;	
EndProcedure // FillLoyaltyType

// -----------------------------------------------------------------------------
Procedure FillRelationTypeExtCodes()

	vCatalogList = Catalogs.RelationTypes.Select();
	While vCatalogList.Next() Do
		If vCatalogList.Ref = Catalogs.RelationTypes.Father Then
			vObj = vCatalogList.GetObject();
			vObj.ID = "134544";
			vObj.Write();
		ElsIf vCatalogList.Ref = Catalogs.RelationTypes.Mother Then
			vObj = vCatalogList.GetObject();
			vObj.ID = "134543";
	        vObj.Write();
		ElsIf vCatalogList.Ref = Catalogs.RelationTypes.Other Then
			vObj = vCatalogList.GetObject();
			vObj.ID = "134567";
	        vObj.Write();
	    ElsIf vCatalogList.Ref = Catalogs.RelationTypes.Guardian Then
			vObj = vCatalogList.GetObject();
			vObj.ID = "136359";
	        vObj.Write();
		 ElsIf vCatalogList.Ref = Catalogs.RelationTypes.Trustee Then
			vObj = vCatalogList.GetObject();
			vObj.ID = "136360";
	        vObj.Write();
		EndIf;	
	EndDo;	
EndProcedure

// -----------------------------------------------------------------------------
Procedure FillHotelForAccommodationTemplateRoomTypes()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ATs.Ref AS Ref
	|FROM
	|	Catalog.AccommodationTemplates AS ATs
	|WHERE
	|	NOT ATs.DeletionMark
	|
	|ORDER BY
	|	ATs.Code";
	vQryRes = vQry.Execute().Unload();
	For Each vQryResRow In vQryRes Do 
		vATObj = vQryResRow.Ref.GetObject();
		For Each vRRRow In vATObj.RoomTypes Do
			If ValueIsFilled(vRRRow.RoomType) And Not ValueIsFilled(vRRRow.Hotel) Then
				vRRRow.Hotel = vRRRow.RoomType.Owner;
			EndIf;
		EndDo;
		If vATObj.Modified() Then
			vATObj.Write();
		EndIf;
	EndDo;
EndProcedure // FillIsHotelProductServiceAttribute 

// -----------------------------------------------------------------------------
Procedure ClearZeroSharePercentInDocuments()
	// Process accommodations
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref AS Ref
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.AccommodationStatus.IsInHouse
	|	AND Accommodation.SharePercent = ""0""
	|
	|ORDER BY
	|	Accommodation.PointInTime";
	vDocs = vQry.Execute().Unload();
	For Each vDocsRow In vDocs Do
		vDocObj = vDocsRow.Ref.GetObject();
		vDocObj.SharePercent = "";
		vDocObj.Write(DocumentWriteMode.Write);
	EndDo;
	
	// Process reservations
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservation.Ref AS Ref
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.Posted
	|	AND (Reservation.ReservationStatus.IsActive
	|			OR Reservation.ReservationStatus.IsPreliminary)
	|	AND Reservation.SharePercent = ""0""
	|
	|ORDER BY
	|	Reservation.PointInTime";
	vDocs = vQry.Execute().Unload();
	For Each vDocsRow In vDocs Do
		vDocObj = vDocsRow.Ref.GetObject();
		vDocObj.SharePercent = "";
		vDocObj.Write(DocumentWriteMode.Write);
	EndDo;
EndProcedure // ClearZeroSharePercentInDocuments

// -----------------------------------------------------------------------------
Procedure FillDebitAndCreditNoteObjectPrintingForm()
	vNoteFolder = Catalogs.ObjectPrintingForms.FindByCode("1900", False, Catalogs.ObjectPrintingForms.EmptyRef());
	vDebitNoteRuObj = Catalogs.ObjectPrintingForms.DebitNotePrintDebitNoteRu.GetObject();
	vDebitNoteEnObj = Catalogs.ObjectPrintingForms.DebitNotePrintDebitNoteEn.GetObject();
	vDebitNoteDeObj = Catalogs.ObjectPrintingForms.DebitNotePrintDebitNoteDe.GetObject();	
	vCreditNoteRuObj = Catalogs.ObjectPrintingForms.CreditNotePrintCreditNoteRu.GetObject();
	vCreditNoteEnObj = Catalogs.ObjectPrintingForms.CreditNotePrintCreditNoteEn.GetObject();
	vCreditNoteDeObj = Catalogs.ObjectPrintingForms.CreditNotePrintCreditNoteDe.GetObject();	 
	If Not ValueIsFilled(vNoteFolder) Then
		 vNoteFolderObj = Catalogs.ObjectPrintingForms.CreateFolder();
		 vNoteFolderObj.Code = "1900";
		 vNoteFolderObj.Description= "Кред. и дебет. корр";
		 vNoteFolderObj.Write();
		 vNoteFolder =  vNoteFolderObj.Ref;
	EndIf;
	If ValueIsFilled(vNoteFolder) And vNoteFolder.IsFolder Then 		
		vDebitNoteRuObj.Parent = vNoteFolder;
		vDebitNoteEnObj.Parent = vNoteFolder;
		vDebitNoteDeObj.Parent = vNoteFolder; 
		vCreditNoteRuObj.Parent = vNoteFolder;
		vCreditNoteEnObj.Parent = vNoteFolder;
		vCreditNoteDeObj.Parent = vNoteFolder; 
	EndIf;
	vDebitNoteRuObj.ObjectType = Documents.DebitNote.EmptyRef();
	vDebitNoteRuObj.IsActive = True;
	vDebitNoteRuObj.IsDefault = True;
	vDebitNoteRuObj.Language = Catalogs.Languages.RU;
	vDebitNoteRuObj.Write();

	vDebitNoteEnObj.ObjectType = Documents.DebitNote.EmptyRef();
	vDebitNoteEnObj.IsActive = True;
	vDebitNoteEnObj.IsDefault = True;
	vDebitNoteEnObj.Language = Catalogs.Languages.EN;
	vDebitNoteEnObj.Write();

	vDebitNoteDeObj.ObjectType = Documents.DebitNote.EmptyRef();
	vDebitNoteDeObj.IsActive = True;
	vDebitNoteDeObj.IsDefault = True;
	vDebitNoteDeObj.Language = Catalogs.Languages.DE;
	vDebitNoteDeObj.Write();
	
	vCreditNoteRuObj.ObjectType = Documents.CreditNote.EmptyRef();
	vCreditNoteRuObj.IsActive = True;
	vCreditNoteRuObj.IsDefault = True;
	vCreditNoteRuObj.Language = Catalogs.Languages.RU;
	vCreditNoteRuObj.Write();
	
	vCreditNoteEnObj.ObjectType = Documents.CreditNote.EmptyRef();
	vCreditNoteEnObj.IsActive = True;
	vCreditNoteEnObj.IsDefault = True;
	vCreditNoteEnObj.Language = Catalogs.Languages.EN;
	vCreditNoteEnObj.Write();
	
	vCreditNoteDeObj.ObjectType = Documents.CreditNote.EmptyRef(); 
	vCreditNoteDeObj.IsActive = True; 
	vCreditNoteDeObj.IsDefault = True;       
	vCreditNoteDeObj.Language = Catalogs.Languages.DE; 	
	vCreditNoteDeObj.Write();  
EndProcedure // FillDebitAndCreditNoteObjectPrintingForm

// -----------------------------------------------------------------------------
Procedure Fill143144UserPermissions()
	// Run query to get permission groups
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PermissionGroups.Ref AS Ref
	|FROM
	|	Catalog.PermissionGroups AS PermissionGroups
	|WHERE
	|	(NOT PermissionGroups.DeletionMark)
	|	AND (NOT PermissionGroups.IsFolder)
	|	AND PermissionGroups.HavePermissionToEditPostedFolioTransactions
	|ORDER BY
	|	PermissionGroups.Code";
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vPGObj = vQryRes.Ref.GetObject();
		Try
			vPGObj.HavePermissionToEditInvoicesCreatedInTheCurrentAccountingPeriod = True;
			vPGObj.HavePermissionToEditInvoicesCreatedInThePastAccountingPeriods = True;
			vPGObj.Write();
		Except
			tcCommonFunctionOnClientServer.TextMessage(TrimAll(vPGObj.Description) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
	EndDo;
EndProcedure // Fill143144UserPermissions

// -----------------------------------------------------------------------------
Procedure Fill146UserPermissions()
	// Run query to get permission groups
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PermissionGroups.Ref AS Ref
	|FROM
	|	Catalog.PermissionGroups AS PermissionGroups
	|WHERE
	|	(NOT PermissionGroups.DeletionMark)
	|	AND (NOT PermissionGroups.IsFolder)
	|ORDER BY
	|	PermissionGroups.Code";
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vPGObj = vQryRes.Ref.GetObject();
		Try
			vPGObj.HavePermissionToCloseOpenTasks = True;
			vPGObj.Write();
		Except
			tcCommonFunctionOnClientServer.TextMessage(TrimAll(vPGObj.Description) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
	EndDo;
EndProcedure // Fill146UserPermissions

// -----------------------------------------------------------------------------
Procedure FillNegativeCorrectionSumInCreditNotes()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CreditNotes.Ref AS Ref
	|FROM
	|	Document.CreditNote AS CreditNotes
	|WHERE
	|	CreditNotes.Posted
	|	AND CreditNotes.CorrectionSum <> -CreditNotes.NegativeCorrectionSum
	|
	|ORDER BY
	|	CreditNotes.PointInTime";
	vDocs = vQry.Execute().Unload();
	For Each vDocsRow In vDocs Do
		vDocObj = vDocsRow.Ref.GetObject();
		vDocObj.Write(DocumentWriteMode.Write);
	EndDo;
EndProcedure // FillNegativeCorrectionSumInCreditNotes

// -----------------------------------------------------------------------------
Procedure FillIsNotInvoicedServiceFlag()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Services.Ref AS Ref
	|FROM
	|	Catalog.Services AS Services
	|WHERE
	|	NOT Services.DeletionMark
	|	AND NOT Services.IsFolder
	|	AND Services.DoNotExportToTheAccountingSystem
	|
	|ORDER BY
	|	Services.Code";
	vSrvs = vQry.Execute().Unload();
	For Each vSrvsRow In vSrvs Do
		vSrvObj = vSrvsRow.Ref.GetObject();
		vSrvObj.IsNotInvoiced = True;
		vSrvObj.Write();
	EndDo;
EndProcedure // FillIsNotInvoicedServiceFlag

// -----------------------------------------------------------------------------
Procedure FillSendPaymentLinkSMSFromProformaInvoice()
	If ValueIsFilled(Catalogs.ObjectFormActions.ReservationSendPaymentLinkSMS) And 
	   Catalogs.ObjectFormActions.ReservationSendPaymentLinkSMS.IsActive Then
		If ValueIsFilled(Catalogs.ObjectFormActions.ProformaInvoiceSendPaymentLinkSMS) And 
		   Not Catalogs.ObjectFormActions.ProformaInvoiceSendPaymentLinkSMS.IsActive Then
			vObjFrmActObj = Catalogs.ObjectFormActions.ProformaInvoiceSendPaymentLinkSMS.GetObject();
			vObjFrmActObj.IsActive = True;
			vObjFrmActObj.ObjectType = Documents.ProformaInvoice.EmptyRef();
			vObjFrmActObj.Parent = Catalogs.ObjectFormActions.FindByCode("800");
			vObjFrmActObj.Write();
		EndIf;
	EndIf;
EndProcedure // FillSendPaymentLinkSMSFromProformaInvoice()

// -----------------------------------------------------------------------------
Procedure FillDuplicateClientsSearchReportSettings()
	// Fill report name and report folder for new report
	vRepRef = Catalogs.Reports.DuplicateClientsSearch;
	If ValueIsFilled(vRepRef) And Not ValueIsFilled(vRepRef.Report) Then
		// Find Other reports folder
		vOtherReportsFolder = Catalogs.Reports.FindByCode(900, , Catalogs.Reports.EmptyRef());
		// Update predefined report settings
		vRepObj = vRepRef.GetObject();
		vRepObj.Report = "DuplicateClientsSearch"; 
		If ValueIsFilled(vOtherReportsFolder) And vOtherReportsFolder.IsFolder Then
			vRepObj.Parent = vOtherReportsFolder;
		EndIf;
		vRepObj.SortCode = 978;
		vRepObj.Write();
	EndIf;
EndProcedure // FillDuplicateClientsSearchReportSettings

// -----------------------------------------------------------------------------
Procedure ConvertRoomRateFormulas()
	// Process room rates with formulas
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomRatesFormulas.Ref AS RoomRate,
	|	RoomRatesFormulas.Ref.BasedOnRoomRate AS BasedOnRoomRate,
	|	RoomRatesFormulas.LineNumber AS LineNumber,
	|	RoomRatesFormulas.DateValidFrom AS DateValidFrom,
	|	RoomRatesFormulas.Hotel AS Hotel,
	|	RoomRatesFormulas.RoomClass AS RoomClass,
	|	RoomRatesFormulas.RoomType AS RoomType,
	|	RoomRatesFormulas.ClientType AS ClientType,
	|	RoomRatesFormulas.Service AS Service,
	|	RoomRatesFormulas.ReplaceWithService AS ReplaceWithService,
	|	RoomRatesFormulas.AccommodationType AS AccommodationType,
	|	RoomRatesFormulas.Multiplier AS Multiplier,
	|	RoomRatesFormulas.BracketsConstant AS BracketsConstant,
	|	RoomRatesFormulas.Constant AS Constant
	|FROM
	|	Catalog.RoomRates.Formulas AS RoomRatesFormulas
	|WHERE
	|	RoomRatesFormulas.Ref.BasedOnRoomRate <> VALUE(Catalog.RoomRates.EmptyRef)
	|	AND NOT RoomRatesFormulas.Ref.IsFolder
	|	AND NOT RoomRatesFormulas.Ref.DeletionMark
	|	AND NOT RoomRatesFormulas.Ref.Remarks LIKE ""%##Processed##%""
	|
	|ORDER BY
	|	RoomRatesFormulas.Ref.Code,
	|	RoomRatesFormulas.DateValidFrom,
	|	RoomRatesFormulas.LineNumber";
	vRows = vQry.Execute().Unload();
	
	vDocObj = Undefined;
	vCurRoomRate = Undefined;
	vCurDateValidFrom = '00010101';
	For Each vRow In vRows Do
		If vCurRoomRate <> vRow.RoomRate Or vCurDateValidFrom <> vRow.DateValidFrom Then
			If vCurRoomRate <> Undefined And vDocObj <> Undefined And vDocObj.Formulas.Count() > 0 Then
				vDocObj.AdditionalProperties.Insert("InfoBaseUpdateMode", True);
				vDocObj.Write(DocumentWriteMode.Posting);
				vDocObj.pmWriteToSetRoomRateFormulasChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				
				vRoomRateObj = vCurRoomRate.GetObject();
				vRoomRateObj.Formulas.Clear();
				vRoomRateObj.Remarks = vRoomRateObj.Remarks + " ##Processed##";
				vRoomRateObj.Write();
		
				tcCommonFunctionOnClientServer.TextMessage("Room rate " + TrimAll(vCurRoomRate) + " was converted!");
			EndIf;
			
			vCurRoomRate = vRow.RoomRate;
			vCurDateValidFrom = vRow.DateValidFrom;
			
			vDocObj = Documents.SetRoomRateFormulas.CreateDocument();
			vDocObj.Hotel = ?(ValueIsFilled(vRow.Hotel), vRow.Hotel, vCurRoomRate.Hotel);
			vDocObj.pmFillAttributesWithDefaultValues();
			vDocObj.RoomRate = vCurRoomRate;
			vDocObj.Date = ?(ValueIsFilled(vCurDateValidFrom), vCurDateValidFrom, '20100101');
			vDocObj.SetTime(AutoTimeMode.DontUse);
			vDocObj.Remarks = "Automatic update to 9.0.4.1";
		EndIf;
		
		If vDocObj <> Undefined Then
			vFormulasRow = vDocObj.Formulas.Add();
			FillPropertyValues(vFormulasRow, vRow);
		EndIf;
	EndDo;				
	If vCurRoomRate <> Undefined And vDocObj <> Undefined And vDocObj.Formulas.Count() > 0 Then
		vDocObj.AdditionalProperties.Insert("InfoBaseUpdateMode", True);
		vDocObj.Write(DocumentWriteMode.Posting);
		vDocObj.pmWriteToSetRoomRateFormulasChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		
		vRoomRateObj = vCurRoomRate.GetObject();
		vRoomRateObj.Formulas.Clear();
		vRoomRateObj.Remarks = vRoomRateObj.Remarks + " ##Processed##";
		vRoomRateObj.Write();
		
		tcCommonFunctionOnClientServer.TextMessage("Room rate " + TrimAll(vCurRoomRate) + " was converted!");
	EndIf;
	
	// Process room rates with discounts
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomRates.Ref AS RoomRate,
	|	RoomRates.BasedOnRoomRate AS BasedOnRoomRate,
	|	RoomRates.Discount AS Discount
	|FROM
	|	Catalog.RoomRates AS RoomRates
	|WHERE
	|	RoomRates.BasedOnRoomRate <> VALUE(Catalog.RoomRates.EmptyRef)
	|	AND NOT RoomRates.IsFolder
	|	AND NOT RoomRates.DeletionMark
	|	AND NOT RoomRates.Remarks LIKE ""%##Processed##%""
	|
	|ORDER BY
	|	RoomRates.Code";
	vRows = vQry.Execute().Unload();
	
	vDocObj = Undefined;
	vCurRoomRate = Undefined;
	For Each vRow In vRows Do
		If vCurRoomRate <> vRow.RoomRate Then
			If vCurRoomRate <> Undefined And vDocObj <> Undefined Then
				vDocObj.AdditionalProperties.Insert("InfoBaseUpdateMode", True);
				vDocObj.Write(DocumentWriteMode.Posting);
				vDocObj.pmWriteToSetRoomRateFormulasChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				
				vRoomRateObj = vCurRoomRate.GetObject();
				vRoomRateObj.Discount = 0;
				vRoomRateObj.Remarks = vRoomRateObj.Remarks + " ##Processed##";
				vRoomRateObj.Write();
		
				tcCommonFunctionOnClientServer.TextMessage("Room rate " + TrimAll(vCurRoomRate) + " was converted!");
			EndIf;
			
			vCurRoomRate = vRow.RoomRate;
			
			vDocObj = Documents.SetRoomRateFormulas.CreateDocument();
			vDocObj.Hotel = vCurRoomRate.Hotel;
			vDocObj.pmFillAttributesWithDefaultValues();
			vDocObj.RoomRate = vCurRoomRate;
			vDocObj.Date = '20100101';
			vDocObj.SetTime(AutoTimeMode.DontUse);
			vDocObj.Discount = vRow.Discount;
			vDocObj.Remarks = "Automatic update to 9.0.4.1";
		EndIf;
	EndDo;				
	If vCurRoomRate <> Undefined And vDocObj <> Undefined Then
		vDocObj.AdditionalProperties.Insert("InfoBaseUpdateMode", True);
		vDocObj.Write(DocumentWriteMode.Posting);
		vDocObj.pmWriteToSetRoomRateFormulasChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		
		vRoomRateObj = vCurRoomRate.GetObject();
		vRoomRateObj.Discount = 0;
		vRoomRateObj.Remarks = vRoomRateObj.Remarks + " ##Processed##";
		vRoomRateObj.Write();
		
		tcCommonFunctionOnClientServer.TextMessage("Room rate " + TrimAll(vCurRoomRate) + " was converted!");
	EndIf;
EndProcedure // ConvertRoomRateFormulas

// -----------------------------------------------------------------------------
Procedure FillAccommodationPrintGuestDepartureObjectPrintingForm()
	vAccommodationFolder = Catalogs.ObjectPrintingForms.FindByCode("100", False, Catalogs.ObjectPrintingForms.EmptyRef());
	vDepartureSheetObj = Catalogs.ObjectPrintingForms.AccommodationPrintDepartureNotificationForm.GetObject();
	If ValueIsFilled(vAccommodationFolder) And vAccommodationFolder.IsFolder And Not ValueIsFilled(vDepartureSheetObj.Parent) Then
		vDepartureSheetObj.Parent = vAccommodationFolder;
	EndIf;
	vDepartureSheetObj.ObjectType = Documents.Accommodation.EmptyRef();
	vDepartureSheetObj.IsActive = True;
	vDepartureSheetObj.IsDefault = False;
	vDepartureSheetObj.Language = Catalogs.Languages.RU;
	vDepartureSheetObj.Write();
EndProcedure // FillAccommodationPrintGuestDepartureObjectPrintingForm

// -----------------------------------------------------------------------------
Procedure ResaveServicePackages()
	// Process room rates with formulas
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ServicePackages.Ref AS Ref
	|FROM
	|	Catalog.ServicePackages AS ServicePackages
	|WHERE
	|	NOT ServicePackages.IsFolder
	|	AND NOT ServicePackages.DeletionMark
	|
	|ORDER BY
	|	ServicePackages.Code";
	vRows = vQry.Execute().Unload();
	
	For Each vRow In vRows Do
		vSPObj = vRow.Ref.GetObject();
		vSPObj.Write();
	EndDo;
EndProcedure // ResaveServicePackages

// -----------------------------------------------------------------------------
Procedure AddUSSRCountry()
	vUSSR = Catalogs.Countries.FindByCode(810);
	If Not ValueIsFilled(vUSSR) And ValueIsFilled(SessionParameters.CurrentHotel) And 
	   ValueIsFilled(SessionParameters.CurrentHotel.Citizenship) And 
	   SessionParameters.CurrentHotel.Citizenship.Code = 643 Then
		vUSSRObj = Catalogs.Countries.CreateItem();
		vUSSRObj.Code = 810;
		vUSSRObj.CountryPhoneCode = 7;
		vUSSRObj.Description = NStr("en='USSR'; ru='СССР'; de='UdSSR'");
		vUSSRObj.DescriptionTranslations = "en='USSR'; ru='СССР'; de='UdSSR'";
		vUSSRObj.ISOCode = "SU";
		vUSSRObj.ISOCode3 = "SUN";
		vUSSRObj.Language = Catalogs.Languages.RU;
		vUSSRObj.IsVisaNecessaryForEntrance = False;
		vUSSRObj.Write();
	EndIf;
EndProcedure // AddUSSRCountry

// -----------------------------------------------------------------------------
Procedure FillVoucherShipmentType()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	IssueHotelProducts.Ref AS Ref
	|FROM
	|	Document.IssueHotelProducts AS IssueHotelProducts
	|WHERE
	|	IssueHotelProducts.VoucherShipmentType = VALUE(Enum.VoucherShipmentTypes.EmptyRef)
	|	AND IssueHotelProducts.Posted
	|
	|ORDER BY
	|	IssueHotelProducts.PointInTime";
	vDocs = vQry.Execute().Unload();
	For Each vDocsRow In vDocs Do
		vDocObj = vDocsRow.Ref.GetObject();
		If vDocObj.HotelProducts.Count() > 0 Then
			If ValueIsFilled(vDocObj.HotelProducts.Get(0).HotelProduct) Then
				vDocObj.VoucherShipmentType = Enums.VoucherShipmentTypes.RegistrationOfVouchersIssuedInTheHotel;
			EndIf;
		EndIf;
		If Not ValueIsFilled(vDocObj.VoucherShipmentType) Then
			vDocObj.VoucherShipmentType = Enums.VoucherShipmentTypes.RegistrationOfVauchersShippedToTheCounterparty;
		EndIf;
		vDocObj.Write(DocumentWriteMode.Write);
	EndDo;
EndProcedure // FillVoucherShipmentType

// -----------------------------------------------------------------------------
Procedure FillOrderTypesCatalogTypeAttribute()
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	OrderTypes.Ref AS Ref,
		|	OrderTypes.Type AS Type,
		|	OrderTypes.Predefined AS Predefined,
		|	OrderTypes.PredefinedDataName AS PredefinedDataName
		|FROM
		|	Catalog.OrderTypes AS OrderTypes";
	
	vQueryResult = vQuery.Execute();
	
	vSelectionDetailRecords = vQueryResult.Select();
	
	While vSelectionDetailRecords.Next() Do
		// Fill types of predefined elements
		If vSelectionDetailRecords.Predefined = True And Not ValueIsFilled(vSelectionDetailRecords.Type) Then 
			vObj = vSelectionDetailRecords.Ref.GetObject();
			If vSelectionDetailRecords.PredefinedDataName = Catalogs.OrderTypes.AdditionalServices.PredefinedDataName Then
				vObj.Type = Enums.TypesOfOrder.AdditionalServices;	
				vObj.Write();
			ElsIf vSelectionDetailRecords.PredefinedDataName = Catalogs.OrderTypes.Rent.PredefinedDataName Then
				vObj.Type = Enums.TypesOfOrder.Rent;
				vObj.Write();
			ElsIf vSelectionDetailRecords.PredefinedDataName = Catalogs.OrderTypes.RentDaily.PredefinedDataName Then
				vObj.Type = Enums.TypesOfOrder.RentDaily;
				vObj.Write();
			ElsIf  VSelectionDetailRecords.PredefinedDataName = Catalogs.OrderTypes.RoomService.PredefinedDataName Then
				vObj.Type = Enums.TypesOfOrder.RoomService;
				vObj.Write();
			ElsIf VSelectionDetailRecords.PredefinedDataName = Catalogs.OrderTypes.Transfer.PredefinedDataName Then
				vObj.Type = Enums.TypesOfOrder.Transfer;
				vObj.Write();
			EndIf;
		// Fill types of not predefined elements
		ElsIf vSelectionDetailRecords.Predefined = False And Not ValueIsFilled(vSelectionDetailRecords.Type) Then
			vObj = vSelectionDetailRecords.Ref.GetObject();
			vObj.Type = Enums.TypesOfOrder.Other;
			vObj.Write();
		EndIf;
	EndDo;
EndProcedure // FillOrderTypesCatalogTypeAttribute

// -----------------------------------------------------------------------------
Procedure FillTimeForPriceCalculationDate()
	// Main processing
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodations.Ref AS Ref,
	|	Accommodations.PointInTime AS PointInTime
	|FROM
	|	Document.Accommodation AS Accommodations
	|WHERE
	|	Accommodations.PriceCalculationDate > &qEmptyDate
	|	AND Accommodations.PriceCalculationDate = BEGINOFPERIOD(Accommodations.PriceCalculationDate, DAY)
	|	AND Accommodations.Posted
	|	AND ISNULL(Accommodations.AccommodationStatus.IsInHouse, FALSE)
	|	AND ISNULL(Accommodations.AccommodationStatus.IsActive, FALSE)
	|
	|UNION ALL
	|
	|SELECT
	|	Reservations.Ref,
	|	Reservations.PointInTime
	|FROM
	|	Document.Reservation AS Reservations
	|WHERE
	|	Reservations.PriceCalculationDate > &qEmptyDate
	|	AND Reservations.PriceCalculationDate = BEGINOFPERIOD(Reservations.PriceCalculationDate, DAY)
	|	AND Reservations.Posted
	|	AND (ISNULL(Reservations.ReservationStatus.IsActive, FALSE)
	|			OR ISNULL(Reservations.ReservationStatus.IsPreliminary, FALSE))
	|
	|ORDER BY
	|	PointInTime";

	vQry.SetParameter("qEmptyDate", '00010101');
	vDocs = vQry.Execute().Select();
	BeginTransaction(DataLockControlMode.Managed);
	vInt = 0;
	While vDocs.Next() Do
		vDocObj = vDocs.Ref.GetObject();
		vDocObj.PriceCalculationDate = EndOfDay(vDocObj.PriceCalculationDate);
		For Each vRRRow In vDocObj.RoomRates Do
			If ValueIsFilled(vRRRow.PriceCalculationDate) And vRRRow.PriceCalculationDate = BegOfDay(vRRRow.PriceCalculationDate) Then
				vRRRow.PriceCalculationDate = EndOfDay(vRRRow.PriceCalculationDate);
			EndIf;
		EndDo;
		For Each vSrvRow In vDocObj.Services Do
			If Not vSrvRow.IsManual And Not vSrvRow.CalendarDayTypeIsChanged Then
				vSrvRow.CalendarDayTypeIsChanged = True;
			EndIf;
		EndDo;
		vDocObj.Write(DocumentWriteMode.Write);
		If TypeOf(vDocObj) = Type("DocumentObject.Accommodation") Then
			vDocObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		Else
			vDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		EndIf;

		vInt = vInt + 1;
		If Int(vInt / 20) = vInt / 20 Then
			CommitTransaction();
			BeginTransaction(DataLockControlMode.Managed);
		EndIf;
	EndDo;
	CommitTransaction();
	// Additional processing
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	AccommodationRoomRates.Ref AS Ref,
	|	AccommodationRoomRates.Ref.PointInTime AS PointInTime
	|FROM
	|	Document.Accommodation.RoomRates AS AccommodationRoomRates
	|WHERE
	|	AccommodationRoomRates.PriceCalculationDate > &qEmptyDate
	|	AND AccommodationRoomRates.PriceCalculationDate = BEGINOFPERIOD(AccommodationRoomRates.PriceCalculationDate, DAY)
	|	AND AccommodationRoomRates.Ref.Posted
	|	AND ISNULL(AccommodationRoomRates.Ref.AccommodationStatus.IsInHouse, FALSE)
	|	AND ISNULL(AccommodationRoomRates.Ref.AccommodationStatus.IsActive, FALSE)
	|
	|UNION ALL
	|
	|SELECT
	|	ReservationRoomRates.Ref,
	|	ReservationRoomRates.Ref.PointInTime
	|FROM
	|	Document.Reservation.RoomRates AS ReservationRoomRates
	|WHERE
	|	ReservationRoomRates.PriceCalculationDate > &qEmptyDate
	|	AND ReservationRoomRates.PriceCalculationDate = BEGINOFPERIOD(ReservationRoomRates.PriceCalculationDate, DAY)
	|	AND ReservationRoomRates.Ref.Posted
	|	AND (ISNULL(ReservationRoomRates.Ref.ReservationStatus.IsActive, FALSE)
	|			OR ISNULL(ReservationRoomRates.Ref.ReservationStatus.IsPreliminary, FALSE))
	|
	|ORDER BY
	|	PointInTime";
	vQry.SetParameter("qEmptyDate", '00010101');
	vDocs = vQry.Execute().Select();
	vInt = 0;
	BeginTransaction(DataLockControlMode.Managed);
	While vDocs.Next() Do
		vDocObj = vDocs.Ref.GetObject();
		For Each vRRRow In vDocObj.RoomRates Do
			If ValueIsFilled(vRRRow.PriceCalculationDate) And vRRRow.PriceCalculationDate = BegOfDay(vRRRow.PriceCalculationDate) Then
				vRRRow.PriceCalculationDate = EndOfDay(vRRRow.PriceCalculationDate);
			EndIf;
		EndDo;
		vDocObj.Write(DocumentWriteMode.Write);
		If TypeOf(vDocObj) = Type("DocumentObject.Accommodation") Then
			vDocObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		Else
			vDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		EndIf;

		vInt = vInt + 1;
		If Int(vInt / 20) = vInt / 20 Then
			CommitTransaction();
			BeginTransaction(DataLockControlMode.Managed);
		EndIf;
	EndDo;
	CommitTransaction();
EndProcedure // FillTimeForPriceCalculationDate

// -----------------------------------------------------------------------------
Procedure Fill153154UserPermission()
	// Run query to get permission groups
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PermissionGroups.Ref AS Ref
	|FROM
	|	Catalog.PermissionGroups AS PermissionGroups
	|WHERE
	|	(NOT PermissionGroups.DeletionMark)
	|	AND (NOT PermissionGroups.IsFolder)
	|ORDER BY
	|	PermissionGroups.Code";
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		vPGObj = vQryRes.Ref.GetObject();
		Try
			If vPGObj.HavePermissionToManageAllotments Then
				vPGObj.HavePermissionToManageBusinessBlocks = True;
				vPGObj.HavePermissionToSetDeletionMarkForBusinessBlocks = False;
			EndIf;
			vPGObj.Write();
		Except
			tcCommonFunctionOnClientServer.TextMessage(TrimAll(vPGObj.Description) + NStr("en=' - error: '; de=' - error: '; ru=' - ошибка: '") + ErrorDescription());
		EndTry;
	EndDo;
EndProcedure // Fill121122UserPermission  

// -----------------------------------------------------------------------------
// Select all integration with type HotelOnlineBooking and change it to Guestlink in case module url contains "guestlink"
// -----------------------------------------------------------------------------
Procedure UpdateGuestlinkParameters()
	
	vQ = New Query("SELECT
	               |	ExternalSystemInteractions.Ref AS Ref,
	               |	ExternalSystemInteractions.HttpAddress AS HttpAddress,
	               |	ExternalSystemInteractions.IntegrationType AS IntegrationType
	               |FROM
	               |	Catalog.ExternalSystemInteractions AS ExternalSystemInteractions
	               |WHERE
	               |	NOT ExternalSystemInteractions.DeletionMark
	               |	AND ExternalSystemInteractions.IntegrationType = &qIntegrationType");
	vQ.SetParameter("qIntegrationType",Enums.Integrations.HotelOnlineBooking);
	qRes = vQ.Execute().Select();
	While qRes.Next() Do
		If StrFind(qRes.HttpAddress, "guestlink") > 0 Then
			vObj = qRes.Ref.GetObject();
			vObj.IntegrationType = Enums.Integrations.Guestlink;
			vObj.Write();
		EndIf;
	EndDo;
	
EndProcedure  // UpdateGuestlinkParameters    

// -----------------------------------------------------------------------------
Function ConvertCalendarsData()
	vMinDate = BegOfMonth(CurrentSessionDate());

	// Get period that should be converted before users start working
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	MIN(Accommodations.CheckInDate) AS MinCheckInDate
	|FROM
	|	Document.Accommodation AS Accommodations
	|WHERE
	|	Accommodations.Posted
	|	AND Accommodations.AccommodationStatus.IsInHouse
	|	AND Accommodations.AccommodationStatus.IsActive
	|	AND Accommodations.AccommodationType.Type <> VALUE(Enum.AccomodationTypes.Together)
	|	AND Accommodations.AccommodationType.Type <> VALUE(Enum.AccomodationTypes.AdditionalBed)";
	vQryRes = vQry.Execute().Select();
	While vQryRes.Next() Do
		If vQryRes.MinCheckInDate <> Null Then
			vMinDate = BegOfMonth(vQryRes.MinCheckInDate);
		EndIf;
		Break;
	EndDo;
	
	// Run conversion for the period starting from date received and wait for it's completion
	ProlongedOperations.ConvertCalendarsData(vMinDate, '39991231');
	
	Return vMinDate;
EndFunction // ConvertCalendarsData

// -----------------------------------------------------------------------------
Procedure ConvertDataProcessorsFlagIsSystem()
	vQuery = New Query();
	vQuery.Text = 
	"SELECT
	|	DP.Ref AS Ref,
	|	DP.IsFolder AS IsFolder
	|FROM
	|	Catalog.DataProcessors AS DP
	|WHERE
	|	DP.IsFolder = FALSE
	|	AND DP.IsSystem = FALSE";
	vAllDP = vQuery.Execute().Unload();
	
	vListOfDPToSkip = New ValueList();
	vListOfDPToSkip.Add("DoNightAuditPrecheck");
	vListOfDPToSkip.Add("HotezaWizard");
	vListOfDPToSkip.Add("AleanCRSSystemInventorySynchronization3");
	vListOfDPToSkip.Add("WubookWizard");
	vListOfDPToSkip.Add("SKK");
	vListOfDPToSkip.Add("TLConnectWizard");
	vListOfDPToSkip.Add("SiteminderWizard");
	vListOfDPToSkip.Add("OTAGatewayWizard");
	vListOfDPToSkip.Add("AvailproWizard");
	vListOfDPToSkip.Add("AddAmountToTheClientSPAFolio");
	vListOfDPToSkip.Add("AddGroupReservation");
	vListOfDPToSkip.Add("Bitrix24");
	vListOfDPToSkip.Add("ChangeGuestGroupAttributes");
	vListOfDPToSkip.Add("CheckAssistReservationPayments");
	vListOfDPToSkip.Add("ChooseDocumentsFromList");
	vListOfDPToSkip.Add("CopyGuestGroupReservations");
	vListOfDPToSkip.Add("AutoSMSDelivery");
	vListOfDPToSkip.Add("CopyGuestGroupReservations");
	vListOfDPToSkip.Add("CopyReportSettings");
	vListOfDPToSkip.Add("CreateAndSendSettlementProformaInvoices");
	vListOfDPToSkip.Add("EndOfDay");
	vListOfDPToSkip.Add("ExportRoomInventoryBalances");
	vListOfDPToSkip.Add("FullTextSearch");
	vListOfDPToSkip.Add("FillRoomPropertiesWizard");
	vListOfDPToSkip.Add("GroupCharge");
	vListOfDPToSkip.Add("IssueGiftCertificate");
	vListOfDPToSkip.Add("LicenseAgreement");
	vListOfDPToSkip.Add("LoadAddressClassifierRu");
	vListOfDPToSkip.Add("LoadCurrencyRates");
	vListOfDPToSkip.Add("LoadEMailReservations");
	vListOfDPToSkip.Add("LocatelEclipseTVDriver");
	vListOfDPToSkip.Add("Messages");
	vListOfDPToSkip.Add("PanasonicPMSiDriver");
	vListOfDPToSkip.Add("RecognizeNewClientDataScans");
	vListOfDPToSkip.Add("RoscongressWizard");
	vListOfDPToSkip.Add("RunHOISTTVInterface");
	vListOfDPToSkip.Add("SetCurrencyRates"); 
	vListOfDPToSkip.Add("YandexTV");
	vListOfDPToSkip.Add("HotbotSettings");
	vListOfDPToSkip.Add("UnisenderGO"); 
	vListOfDPToSkip.Add("ttLockDoorLockSystemDriver");
	vListOfDPToSkip.Add("QRCodePaySberbank");
	vListOfDPToSkip.Add("SquirrelPOS");
	vListOfDPToSkip.Add("HOISTPayTVDriver");
	vListOfDPToSkip.Add("SamsungLYNK");  
	vListOfDPToSkip.Add("Hotellab");
	vListOfDPToSkip.Add("ExternalLoyaltySystem");
	vListOfDPToSkip.Add("CalculateBonuses");
	vListOfDPToSkip.Add("DoExchangePlanNodeDataExchange");
	
	For Each vDP In vAllDP Do
		If vListOfDPToSkip.FindByValue(vDP.Ref.Processing) <> Undefined Then
			vObject = vDP.Ref.GetObject();
			vObject.IsSystem = True;
			vObject.Write();
		EndIf;
	EndDo;
EndProcedure // ConvertDataProcessors()

// -----------------------------------------------------------------------------
Procedure UpdateServicePackagesValidityPeriod()
	vSrvPackages = cmGetAllServicePackages(, Catalogs.Hotels.EmptyRef());
	For Each vSrvPackagesRow In vSrvPackages Do
		vSrvPackageRef = vSrvPackagesRow.ServicePackage;
		If ValueIsFilled(vSrvPackageRef.DateValidFrom) Or ValueIsFilled(vSrvPackageRef.DateValidTo) Then
			vDateValidFrom = vSrvPackageRef.DateValidFrom;
			vDateValidTo = vSrvPackageRef.DateValidTo;

			vSrvPackageObj = vSrvPackageRef.GetObject();
			For Each vSrvRow In vSrvPackageObj.Services Do
				If Not ValueIsFilled(vSrvRow.PeriodFrom) And ValueIsFilled(vDateValidFrom) Then
					If Not ValueIsFilled(vSrvRow.PeriodTo) Or vSrvRow.PeriodTo >= vDateValidFrom Then
						vSrvRow.PeriodFrom = vDateValidFrom;
					EndIf;
				EndIf;
				If Not ValueIsFilled(vSrvRow.PeriodTo) And ValueIsFilled(vDateValidTo) Then
					If Not ValueIsFilled(vSrvRow.PeriodFrom) Or vSrvRow.PeriodFrom <= vDateValidTo Then
						vSrvRow.PeriodTo = vDateValidTo;
					EndIf;
				EndIf;
			EndDo;
			If vSrvPackageObj.Modified() Then
				vSrvPackageObj.DateValidFrom = '00010101';
				vSrvPackageObj.DateValidTo = '00010101';
				vSrvPackageObj.Write();
			EndIf;
		EndIf;
	EndDo;
EndProcedure // UpdateServicePackagesValidityPeriod

// -----------------------------------------------------------------------------
Procedure FillNoVATHistoryFlag()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	VATRates.Ref AS Ref,
	|	VATRates.Description AS Description,
	|	VATRates.TaxGroup AS TaxGroup,
	|	VATRatesHistory.Period AS Period
	|FROM
	|	Catalog.VATRates AS VATRates
	|		LEFT JOIN InformationRegister.VATRatesHistory.SliceLast(&qPeriod, ) AS VATRatesHistory
	|		ON VATRates.Ref = VATRatesHistory.VATRate
	|			AND (VATRates.NoVAT)
	|			AND (NOT VATRatesHistory.NoVAT)
	|WHERE
	|	VATRates.NoVAT
	|	AND NOT VATRates.DeletionMark
	|	AND NOT VATRatesHistory.Period IS NULL
	|
	|ORDER BY
	|	VATRates.Description";
	vQry.SetParameter("qPeriod", CurrentSessionDate());
	vRates = vQry.Execute().Unload();
	For Each vRatesRow In vRates Do
		vRatesRcdMgr = InformationRegisters.VATRatesHistory.CreateRecordManager();
		vRatesRcdMgr.Period = vRatesRow.Period;
		vRatesRcdMgr.VATRate = vRatesRow.Ref;
		vRatesRcdMgr.Read();
		If vRatesRcdMgr.Selected() Then
			vRatesRcdMgr.NoVAT = True;
			vRatesRcdMgr.Description = vRatesRow.Description;
			vRatesRcdMgr.TaxGroup = vRatesRow.TaxGroup;
			vRatesRcdMgr.Write(True);
		EndIf;
	EndDo;
EndProcedure // FillNoVATHistoryFlag

// -----------------------------------------------------------------------------
Procedure CreateTouristTaxBreakdownListFormulaRu()
	vHtlQry = New Query();
	vHtlQry.Text = 
	"SELECT
	|	Hotels.Ref AS Ref
	|FROM
	|	Catalog.Hotels AS Hotels
	|WHERE
	|	Hotels.Citizenship.Code = &qCodeRussia
	|	AND NOT Hotels.DeletionMark
	|	AND NOT Hotels.IsFolder
	|
	|ORDER BY
	|	Hotels.Code";
	vHtlQry.SetParameter("qCodeRussia", 643);
	vHotelsRU = vHtlQry.Execute().Unload();
	If vHotelsRU.Count() > 0 Then
		vTTRef = Catalogs.BreakdownListFormulas.FindByCode("TTRU", False);
		If Not ValueIsFilled(vTTRef) Then
			vTTObj = Catalogs.BreakdownListFormulas.CreateItem();
			vTTObj.Code = "TTRU";
			vTTObj.Description = "Туристический налог (RU)";
			vTTObj.IsTax = True;
			vTTObj.Price = 0;
			vTTObj.Currency = Undefined;
			vTTObj.PriceCalculationFormula = "[ItemPrice] = [TouristTaxAmountRU];";
			vTTObj.Quantity = 1;
			vTTObj.QuantityCalculationFormula = "";
			vTTObj.Write();
		EndIf;
	EndIf;
EndProcedure // CreateTouristTaxBreakdownListFormulaRu

// -----------------------------------------------------------------------------
Procedure CreateTouristTaxDeclarationRuPrintForms()
	vHtlQry = New Query();
	vHtlQry.Text = 
	"SELECT
	|	Hotels.Ref AS Ref
	|FROM
	|	Catalog.Hotels AS Hotels
	|WHERE
	|	Hotels.Citizenship.Code = &qCodeRussia
	|	AND NOT Hotels.DeletionMark
	|	AND NOT Hotels.IsFolder
	|
	|ORDER BY
	|	Hotels.Code";
	vHtlQry.SetParameter("qCodeRussia", 643);
	vHotelsRU = vHtlQry.Execute().Unload();
	If vHotelsRU.Count() > 0 Then
		If ValueIsFilled(Catalogs.ObjectPrintingForms.TouristTaxDeclarationPrintRU) And Not Catalogs.ObjectPrintingForms.TouristTaxDeclarationPrintRU.IsActive Then
			vPrtFormObj = Catalogs.ObjectPrintingForms.TouristTaxDeclarationPrintRU.GetObject();
			vPrtFormObj.ObjectType = Documents.TouristTaxDeclarationRU.EmptyRef();
			vPrtFormObj.IsActive = True;
			vPrtFormObj.IsDefault = True;
			vPrtFormObj.Write();
		EndIf;
		If ValueIsFilled(Catalogs.ObjectPrintingForms.TouristTaxDetailingDeclarationPrintRU) And Not Catalogs.ObjectPrintingForms.TouristTaxDetailingDeclarationPrintRU.IsActive Then
			vPrtFormObj = Catalogs.ObjectPrintingForms.TouristTaxDetailingDeclarationPrintRU.GetObject();
			vPrtFormObj.ObjectType = Documents.TouristTaxDeclarationRU.EmptyRef();
			vPrtFormObj.IsActive = True;
			vPrtFormObj.IsDefault = False;
			vPrtFormObj.Write();
		EndIf;
		// Delete old printing form
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	PrintingForms.Ref AS Ref
		|FROM
		|	Catalog.ObjectPrintingForms AS PrintingForms
		|WHERE
		|	PrintingForms.ObjectType = VALUE(Catalog.ObjectPrintingForms.EmptyRef)
		|	AND NOT PrintingForms.Code = ""010""
		|	AND NOT PrintingForms.DeletionMark
		|	AND NOT PrintingForms.IsFolder";
		vPrintingForms = vQry.Execute().Unload();
		For Each vPrintingFormsRow In vPrintingForms Do
			vPrtFormObj = vPrintingFormsRow.Ref.GetObject();
			vPrtFormObj.IsActive = False;
			vPrtFormObj.DeletionMark = True;
			vPrtFormObj.Write();
		EndDo;
	EndIf;
EndProcedure // CreateTouristTaxDeclarationRuPrintForms

// -----------------------------------------------------------------------------
Procedure CreateAndFillBirthCertificateRecordingIDType()
	// Create identity document type
	vTypeObj = Undefined;
	vTypeRef = Catalogs.IdentityDocumentTypes.FindByCode("33");
	If ValueIsFilled(vTypeRef) Then
		Return;
	Else
		vTypeObj = Catalogs.IdentityDocumentTypes.CreateItem();
	EndIf;
	vTypeObj.Code = "33";
	vTypeObj.Description = NStr("en='Recording of the birth certificate'; ru='Запись акта о рождении'; de='Aufzeichnung der Geburtsurkunde'");
	vTypeObj.DeletionMark = False;
	vTypeObj.Write();
	
	// Fill hotel parameter
	vRussia = Catalogs.Countries.FindByCode(643);
	If ValueIsFilled(vRussia) Then
		vAllHotels = cmGetAllHotels();
		For Each vAllHotelsRow In vAllHotels Do
			vHotel = vAllHotelsRow.Hotel;
			If vHotel.Citizenship = vRussia And Not ValueIsFilled(vHotel.BirthCertificateRecord) Then
				vHotelObj = vHotel.GetObject();
				vHotelObj.BirthCertificateRecord = vTypeObj.Ref;
				vHotelObj.Write();
			EndIf;
		EndDo;
	EndIf;
EndProcedure // CreateAndFillBirthCertificateRecordingIDType

// -----------------------------------------------------------------------------
Procedure PutDescriptionUpdate(pVersion, pSpreadsheetDocument, pTemplate)
	Try
		pSpreadsheetDocument.Put(pTemplate.GetArea("Head" + pVersion));
		pSpreadsheetDocument.StartRowGroup("Version" + pVersion);
		pSpreadsheetDocument.Put(pTemplate.GetArea("Version" + pVersion));
		pSpreadsheetDocument.EndRowGroup();
		pSpreadsheetDocument.Put(pTemplate.GetArea("Indent"));
	Except
	EndTry;
EndProcedure // PutDescriptionUpdate

// -----------------------------------------------------------------------------
Procedure FillConnectedDevicesInfoRegisterFromObjectAttributes()
	vQry = New Query;
	vQry.Text = "SELECT
	|	Workstations.Ref AS Ref
	|FROM
	|	Catalog.Workstations AS Workstations";
	
	vResult = vQry.Execute().Unload();
	For Each vRow In vResult Do
		vWorkstation = vRow.Ref;
		If ValueIsFilled(vWorkstation.CreditCardsProcessingSystemParameters) Then 
			vRecordManager = InformationRegisters.ConnectedDevices.CreateRecordManager();
			vRecordManager.Workstation = vWorkstation;
			vRecordManager.DeviceSettings = vWorkstation.CreditCardsProcessingSystemParameters;
			vRecordManager.DeviceType = Enums.DeviceTypes.CreditCardsProcessingSystemParameters;
			vRecordManager.IsActive = vWorkstation.HasConnectionToCreditCardsProcessingSystem;
			
			vRecordManager.Write();
		EndIf;
		If ValueIsFilled(vWorkstation.DoorLockSystemParameters) Then 
			vRecordManager = InformationRegisters.ConnectedDevices.CreateRecordManager();
			vRecordManager.Workstation = vWorkstation;
			vRecordManager.DeviceSettings = vWorkstation.DoorLockSystemParameters;
			vRecordManager.DeviceType = Enums.DeviceTypes.DoorLockSystemParameters;
			vRecordManager.IsActive = vWorkstation.HasConnectionToDoorLockSystem;
			
			vRecordManager.Write();
		EndIf;
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
Procedure FillReservationRichTextPrintFormsSettings()
	vReservationFolder = Catalogs.ObjectPrintingForms.FindByCode("200", False, Catalogs.ObjectPrintingForms.EmptyRef());
	If TypeOf(Catalogs.ObjectPrintingForms.ReservationPrintConfirmationRichTextRu.ObjectType) <> Type("DocumentRef.Reservation") Then
		vPrtFormObj = Catalogs.ObjectPrintingForms.ReservationPrintConfirmationRichTextRu.GetObject();
		vPrtFormObj.ObjectType = Documents.Reservation.EmptyRef();
		If ValueIsFilled(vReservationFolder) And vReservationFolder.IsFolder Then
			vPrtFormObj.Parent = vReservationFolder;
		EndIf;
		vPrtFormObj.Language = Catalogs.Languages.RU;
		vPrtFormObj.IsActive = True;
		vPrtFormObj.Remarks = "en = 'Rich text reservation confirmation'; de = 'Rich Text Reservierungsbestätigung'; ru = 'Расширенное текстовое подтверждение бронирования'";
		vPrtFormObj.Write();
	EndIf;
	If TypeOf(Catalogs.ObjectPrintingForms.ReservationPrintConfirmationRichTextEn.ObjectType) <> Type("DocumentRef.Reservation") Then
		vPrtFormObj = Catalogs.ObjectPrintingForms.ReservationPrintConfirmationRichTextEn.GetObject();
		vPrtFormObj.ObjectType = Documents.Reservation.EmptyRef();
		If ValueIsFilled(vReservationFolder) And vReservationFolder.IsFolder Then
			vPrtFormObj.Parent = vReservationFolder;
		EndIf;
		vPrtFormObj.Language = Catalogs.Languages.EN;
		vPrtFormObj.IsActive = True;
		vPrtFormObj.Remarks = "en = 'Rich text reservation confirmation'; de = 'Rich Text Reservierungsbestätigung'; ru = 'Расширенное текстовое подтверждение бронирования'";
		vPrtFormObj.Write();
	EndIf;
	If TypeOf(Catalogs.ObjectPrintingForms.ReservationPrintConfirmationRichTextDe.ObjectType) <> Type("DocumentRef.Reservation") Then
		vPrtFormObj = Catalogs.ObjectPrintingForms.ReservationPrintConfirmationRichTextDe.GetObject();
		vPrtFormObj.ObjectType = Documents.Reservation.EmptyRef();
		If ValueIsFilled(vReservationFolder) And vReservationFolder.IsFolder Then
			vPrtFormObj.Parent = vReservationFolder;
		EndIf;
		vPrtFormObj.Language = Catalogs.Languages.DE;
		vPrtFormObj.IsActive = True;
		vPrtFormObj.Remarks = "en = 'Rich text reservation confirmation'; de = 'Rich Text Reservierungsbestätigung'; ru = 'Расширенное текстовое подтверждение бронирования'";
		vPrtFormObj.Write();
	EndIf;
EndProcedure // FillReservationRichTextPrintFormsSettings

// -----------------------------------------------------------------------------
Procedure FillHotelFillProformaInvoiceMode()
	vHotels = cmGetAllHotels();
	For Each vHotelsRow In vHotels Do
		vHotelObj = vHotelsRow.Hotel.GetObject();
		If vHotelObj.ProformaInvoicesFillServicesInDetail Then
			vHotelObj.FillProformaInvoiceMode = Enums.FillProformaInvoiceModes.InDetails;
			vHotelObj.Write();
		EndIf;
	EndDo;
EndProcedure // FillHotelFillProformaInvoiceMode

// --------------------------------------------------------------------------------
Procedure FillHexWithColor()   
	vArrData = StrSplit("Catalogs,Documents,InformationRegisters", ",", False);    
	
	For Each vRow In vArrData Do	
		For Each vItem in Metadata[vRow] Do
			If vItem.Attributes.Find("Color") <> Undefined Then   
				vSelected = Undefined;
				Execute("vSelected =" + vRow + "." + vItem.Name + ".Select()");
				While vSelected.Next() Do
					If vSelected.Color <> Null Then
						vColor = vSelected.Color.Get();  
						If vColor <> Undefined Then
							vObj = vSelected.GetObject();
							vObj.ColorHexString = tcOnServer.ColorToHex(vColor);
							vObj.Write();   
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
	EndDo;     
EndProcedure 

// --------------------------------------------------------------------------------
Procedure CheckAndFixCalendarDays()
	// Try to find records in CalendarDaysByRoomTypes where there is no records in CalendarDays by AccountingDate and Calendar
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CalendarDaysByRoomTypes.Calendar AS Calendar,
	|	CalendarDaysByRoomTypes.AccountingDate AS AccountingDate,
	|	CalendarDaysByRoomTypes.MinPeriod AS MinPeriod
	|FROM
	|	(SELECT
	|		CalendarDaysByRoomTypesRecords.Calendar AS Calendar,
	|		CalendarDaysByRoomTypesRecords.AccountingDate AS AccountingDate,
	|		MIN(CalendarDaysByRoomTypesRecords.Period) AS MinPeriod
	|	FROM
	|		InformationRegister.CalendarDaysByRoomTypes AS CalendarDaysByRoomTypesRecords
	|	
	|	GROUP BY
	|		CalendarDaysByRoomTypesRecords.Calendar,
	|		CalendarDaysByRoomTypesRecords.AccountingDate) AS CalendarDaysByRoomTypes
	|		LEFT JOIN InformationRegister.CalendarDays AS CalendarDays
	|		ON CalendarDaysByRoomTypes.Calendar = CalendarDays.Calendar
	|			AND CalendarDaysByRoomTypes.AccountingDate = CalendarDays.AccountingDate
	|WHERE
	|	CalendarDays.CalendarDayType IS NULL";
	vProblemDates = vQry.Execute().Unload();
	
	If vProblemDates.Count() > 0 Then
		vInternalTransaction = False;
		If Not TransactionActive() Then
			vInternalTransaction = True;
			BeginTransaction(DataLockControlMode.Managed);
		EndIf;
		For Each vProblemDatesRow In vProblemDates Do
			vRcdMgr = InformationRegisters.CalendarDays.CreateRecordManager();
			vRcdMgr.Calendar = vProblemDatesRow.Calendar;
			vRcdMgr.AccountingDate = vProblemDatesRow.AccountingDate;
			vRcdMgr.Period = ?(ValueIsFilled(vProblemDatesRow.MinPeriod), vProblemDatesRow.MinPeriod, CurrentSessionDate());
			vRcdMgr.Author = SessionParameters.CurrentUser;
			vRcdMgr.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
			vRcdMgr.PriceTag = Catalogs.PriceTags.EmptyRef();
			vRcdMgr.Timetable = Catalogs.Timetables.EmptyRef();
			vRcdMgr.RoomPrice = 0;
			vRcdMgr.RoomPriceCurrency = Catalogs.Currencies.EmptyRef();
			vRcdMgr.Remarks = "";
			vRcdMgr.Write(True);
		EndDo;
		If TransactionActive() And vInternalTransaction Then
			CommitTransaction();
		EndIf;
	EndIf;
EndProcedure // CheckAndFixCalendarDays

#EndRegion
