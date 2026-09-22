#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pParameter	 - Structure - Parameter
//
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// --------------------------------------------------------------------------------
//
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// --------------------------------------------------------------------------------
//
Procedure pmFillAttributesWithDefaultValues() Export
	
EndProcedure // pmFillAttributesWithDefaultValues

// --------------------------------------------------------------------------------
//  Fills the database
//
// Parameters:
//  pParameter		 - Structure - Parameter
//  pIsInteractive	 - Boolean	 - IsInteractive
//
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	
	vSucces = False;
	BeginTransaction();
	Try
		RefreshObjectsNumbering();
		vProgress = 0;
		LanguageCode = Language.Code;
			
		If LanguageCode = "RU" Then
			// Update UMMS catalogs
			// Identity Document Types
			ClearObj("IdentityDocumentTypes");
			Catalogs.IdentityDocumentTypes.mmLoadFromDictionary();
			
			// TripPurposes
			ClearObj("TripPurposes");
			Catalogs.TripPurposes.mmLoadFromDictionary();
			
			// VisaTypes
			ClearObj("VisaTypes");
			Catalogs.VisaTypes.mmLoadFromDictionary();
			
			// EntryGoals
			ClearObj("EntryGoals");
			Catalogs.EntryGoals.mmLoadFromDictionary();
			
			// CheckPoints
			ClearObj("CheckPoints");
			Catalogs.CheckPoints.mmLoadFromDictionary();
		EndIf;
		// Progress 20
		SendProgressMessage(vProgress);
		
		CreateAgeRanges();
		CreateAccommodationStatuses();
		CreateAccommodationTypes();
		// Progress 40
		SendProgressMessage(vProgress);
		CreateReservationStatuses();
		CreateRoomStatuses();
		CreateFirstClient();
		// Progress 60
		SendProgressMessage(vProgress);
		CreateCompany();
		CreateHotel();
		CreatePermissionGroups();
		// Progress 80
		SendProgressMessage(vProgress);
		vObjects = New Structure("ExternalDataProcessor, Report,
								 |DataProcessor, ObjectFormAction, ObjectPrintingForm");
		For Each vObject In vObjects Do
			CreateFromTemplate(vObject.Key);
		EndDo;
		
		vSucces = True;
		CommitTransaction();
	Except
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		vErrorDescription = ErrorDescription();
		tcCommonFunctionOnClientServer.UserMessage("en = 'The initial filling could not be completed! ';
												   |de = 'Die Erstbefüllung konnte nicht abgeschlossen werden! ';
												   |ru = 'Не удалось выполнить первоначальное заполнение! '"
												   + vErrorDescription);
	EndTry;

	If vSucces Then
		CheckUsers();
		// Progress 100
		SendProgressMessage(vProgress);
	EndIf;
		
EndProcedure // pmRun

// --------------------------------------------------------------------------------
//  Runs VATRates and Currencies creation and units renaiming for the selected language
//
Procedure pmRunBeforeFormOpen() Export

	ClearObj("VATRates");
	CreateVATRates();
	
	ClearObj("Currencies");
	CreateCurrencies();
	
	RenameUnits();
	
EndProcedure // pmRunBeforeFormOpen

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
Procedure SendProgressMessage(pProgress)

	pProgress = pProgress + 20;
	pProgressMessage = "<progress>" + pProgress + "</progress>";
	tcCommonFunctionOnClientServer.UserMessage(pProgressMessage);

EndProcedure // SendProgressMessage

// --------------------------------------------------------------------------------
Procedure ClearObj(pObjName)

	vQuery = New Query;
	vQuery.Text = StrTemplate(
	"SELECT
	|	%1.Ref AS Ref
	|FROM
	|	Catalog.%1 AS %1
	|WHERE
	|	NOT %1.Predefined", pObjName);
	
	vQueryResult = vQuery.Execute();
	
	vSelectionDetailRecords = vQueryResult.Select();
	
	While vSelectionDetailRecords.Next() Do
		vVRObj = vSelectionDetailRecords.Ref.GetObject();
		vVRObj.DataExchange.Load = True;
		vVRObj.Write();
		vVRObj.Delete();
	EndDo;	

EndProcedure // ClearObj

#Region CreateAdmin

// --------------------------------------------------------------------------------
Procedure CheckUsers()
	
	If InfoBaseUsers.GetUsers().Count() = 0 Then
		// Add sys admin user 
		CreateAdmin();
	EndIf;	

EndProcedure

// --------------------------------------------------------------------------------
Procedure CreateAdmin()
	
	vInfoBaseUser = InfoBaseUsers.CreateUser();
	vDescription = FNStr("en = 'Administrator';
						 |de = 'Administrator';
						 |ru = 'Администратор'");
	vInfoBaseUser.Name = vDescription;
	vInfoBaseUser.FullName = vDescription;
	vInfoBaseUser.RunMode = ClientRunMode.ManagedApplication;
	vInfoBaseUser.StandardAuthentication = True;
	vInfoBaseUser.ShowInList = True;
	If Language = Catalogs.Languages.RU Then
		vInfoBaseUser.Language = Metadata.Languages.Russian;
	ElsIf Language = Catalogs.Languages.DE Then
		vInfoBaseUser.Language = Metadata.Languages.German;
	Else
		vInfoBaseUser.Language = Metadata.Languages.English;
	EndIf;
	vInfoBaseUser.Roles.Add(Metadata.Roles.Administrator);
	
	vInfoBaseUser.Write();
	
EndProcedure // CreateAdmin

#EndRegion

// --------------------------------------------------------------------------------
Procedure CreateVATRates()
	// Without VAT
	vNoVAT = Catalogs.VATRates.CreateItem();
	vNoVAT.Description = FNStr("en = 'Without VAT'; de = 'Ohne Mehrwertsteuer'; ru = 'Без НДС'");
	vNoVAT.TaxRate = 0;
	vNoVAT.NoVAT = True;
	vNoVAT.Write();
	
	// 0%
	v18VAT = Catalogs.VATRates.CreateItem();
	v18VAT.Description = "0%";
	v18VAT.TaxRate = 0;
	v18VAT.Write();
	
	// 5%
	v5VAT = Catalogs.VATRates.CreateItem();
	v5VAT.Description = "5%";
	v5VAT.TaxRate = 5;
	v5VAT.Write();
	
	// 7%
	v7VAT = Catalogs.VATRates.CreateItem();
	v7VAT.Description = "7%";
	v7VAT.TaxRate = 7;
	v7VAT.Write();
	
	// 10%
	v18VAT = Catalogs.VATRates.CreateItem();
	v18VAT.Description = "10%";
	v18VAT.TaxRate = 10;
	v18VAT.Write();
	
	// 18%
	v18VAT = Catalogs.VATRates.CreateItem();
	v18VAT.Description = "18%";
	v18VAT.TaxRate = 18;
	v18VAT.Write();
	
	// 20%
	v20VAT = Catalogs.VATRates.CreateItem();
	v20VAT.Description = "20%";
	v20VAT.TaxRate = 20;
	v20VAT.Write();
	
	// 22%
	v22VAT = Catalogs.VATRates.CreateItem();
	v22VAT.Description = "22%";
	v22VAT.TaxRate = 22;
	v22VAT.Write();
EndProcedure // CreateVATRates

// --------------------------------------------------------------------------------
//
// Parameters:
//  pString	 - String	 - localization string
// 
// Returns:
//  String - localized string
//
Function FNStr(pString)

	Return NStr(pString, LanguageCode);

EndFunction // FNStr

// -----------------------------------------------------------------------------
Procedure CreateAgeRanges()
	
	ClearObj("AgeRanges");
	
	vAgeRangeObj = Catalogs.AgeRanges.CreateItem();
	vAgeRangeObj.Code = "CHLD";
	vAgeRangeObj.Description = FNStr("en = 'Kid'; de = 'Kind'; ru = 'Ребенок'");
	vAgeRangeObj.FromAge = 1;
	vAgeRangeObj.ToAge = 14;
	vAgeRangeObj.Write();
	
	vAgeRangeObj = Catalogs.AgeRanges.CreateItem();
	vAgeRangeObj.Code = "TEEN";
	vAgeRangeObj.Description = FNStr("en = 'Teenager'; de = 'Teenager'; ru = 'Тинейджер'");
	vAgeRangeObj.FromAge = 15;
	vAgeRangeObj.ToAge = 21;
	vAgeRangeObj.Write();
	
	vAgeRangeObj = Catalogs.AgeRanges.CreateItem();
	vAgeRangeObj.Code = "22-29";
	vAgeRangeObj.Description = FNStr("en = 'From 22 to 29'; de = 'Von 22 bis 29'; ru = 'От 22 до 29'");
	vAgeRangeObj.FromAge = 22;
	vAgeRangeObj.ToAge = 29;
	vAgeRangeObj.Write();
	
	vAgeRangeObj = Catalogs.AgeRanges.CreateItem();
	vAgeRangeObj.Code = "30-39";
	vAgeRangeObj.Description = FNStr("en = 'From 30 to 39'; de = 'Von 30 bis 39'; ru = 'От 30 до 39'");
	vAgeRangeObj.FromAge = 30;
	vAgeRangeObj.ToAge = 39;
	vAgeRangeObj.Write();
	
	vAgeRangeObj = Catalogs.AgeRanges.CreateItem();
	vAgeRangeObj.Code = "40-49";
	vAgeRangeObj.Description = FNStr("en = 'From 40 to 49'; de = 'Von 40 bis 49'; ru = 'От 40 до 49'");
	vAgeRangeObj.FromAge = 40;
	vAgeRangeObj.ToAge = 49;
	vAgeRangeObj.Write();
	
	vAgeRangeObj = Catalogs.AgeRanges.CreateItem();
	vAgeRangeObj.Code = "50-59";
	vAgeRangeObj.Description = FNStr("en = 'From 50 to 59'; de = 'Von 50 bis 59'; ru = 'От 50 до 59'");
	vAgeRangeObj.FromAge = 50;
	vAgeRangeObj.ToAge = 59;
	vAgeRangeObj.Write();
	
	vAgeRangeObj = Catalogs.AgeRanges.CreateItem();
	vAgeRangeObj.Code = "60";
	vAgeRangeObj.Description = FNStr("en = 'Over 60'; de = 'Über 60'; ru = 'Старше 60'");
	vAgeRangeObj.FromAge = 60;
	vAgeRangeObj.ToAge = 150;
	vAgeRangeObj.Write();
	
EndProcedure // CreateAgeRanges

// --------------------------------------------------------------------------------
Procedure CreateCompany()

	ClearObj("Companies");
	
	vCompany = Catalogs.Companies.CreateItem();
	vCompany.Description = CompanyDescription;
	vCompany.LegacyName = CompanyLegacyDescription;
	vCompany.RKOSupplement = FNStr("ru = 'Заявление'");
	vCompany.CompanyAccountingPolicyType = Enums.CompanyAccountingPolicyTypes.ByCheckedOutGuestGroupsServices;
	vCompany.VATRate = VATRate; // CreateVATRates();
	vCompany.TaxAccountingPeriodType = Enums.TaxAccountingPeriodTypes.Month;
	vCompany.TaxationSystem = TaxationSystem;
	vCompany.Write();
	
	CompanyRef = vCompany.Ref;
	
EndProcedure // CreateCompany

// --------------------------------------------------------------------------------
Procedure CreateHotel()

	ClearObj("Hotels");
	
	vHotel = Catalogs.Hotels.CreateItem();
	
	vHotel.Code = "001";
	vHotel.SortCode = 1;
	// Contacts
	vHotel.Description = HotelDescription;
	
	// Get ref
	vHotel.Write();
	vHotelRef = vHotel.Ref;	
	
	vHotel.LegacyName = HotelLegacyDescription;
	vHotel.PrintName = HotelLegacyDescription;
	// Accounting
	vHotel.Company = CompanyRef;
	vHotel.IndividualsCustomer = CreateCustomer();
	vHotel.PlannedPaymentMethod  			= Catalogs.PaymentMethods.FindByCode(FNStr("en = 'CASH';
																					   |de = 'CASH';
																					   |ru = 'НЛ'"));
	vHotel.PaymentMethodForCustomerPayments = Catalogs.PaymentMethods.FindByCode(FNStr("en = 'BT';
																					   |de = 'BT';
																					   |ru = 'БН'"));
	vHotel.OneCustomerPerGuestGroup = True;
	vHotel.CloseServiceRegistration = True;
	vHotel.ShowSalesInReportsWithVAT = True;
	vHotel.SwitchOffAutoCorrections = True;
	vHotel.DoNotEditSettledDocs = True;
	// Prefixes
	vHotel.Prefix = Prefix;
	// Pricing
	vHotel.RoomRate = CreateRoomRate(vHotelRef);
	vHotel.FolioCurrency = Currency;
	vHotel.BaseCurrency = Currency;
	vHotel.ReportingCurrency = Currency;
	// Reservation
	vHotel.NewReservationStatus = Catalogs.ReservationStatuses.FindByCode("10");
	vHotel.NoShowReservationStatus = Catalogs.ReservationStatuses.FindByCode("30");
	vHotel.CheckInReservationStatus = Catalogs.ReservationStatuses.FindByCode("40");
	vHotel.Duration = 1;
	vHotel.PeriodToKeepReservations = 12;
	vHotel.DaysAfterReservation = 5;
	// Accommodation
	vHotel.CheckInAccommodationStatus = Catalogs.AccommodationStatuses.FindByCode("10");
	vHotel.CheckOutAccommodationStatus = Catalogs.AccommodationStatuses.FindByCode("20");
	vHotel.CheckInAndMoveAccommodationStatus = Catalogs.AccommodationStatuses.FindByCode("50");
	vHotel.MoveAccommodationStatus = Catalogs.AccommodationStatuses.FindByCode("40");
	vHotel.ChangeRoomAccommodationStatus = Catalogs.AccommodationStatuses.FindByCode("30");
	vHotel.MoveAndCheckOutAccommodationStatus = Catalogs.AccommodationStatuses.FindByCode("60");
	// Resource reservation
	vHotel.NewResourceReservationStatus = CreateResourceReservationStatuses();
	// Clients
	vHotel.Language = Language;
	vHotel.Citizenship = Citizenship;
	If Citizenship = Catalogs.Countries.FindByCode(643) Then
		vHotel.IdentityDocumentType = Catalogs.IdentityDocumentTypes.FindByCode("21");
		vHotel.IdentityDocumentTypeForForeigners = Catalogs.IdentityDocumentTypes.FindByCode("ИП");
	EndIf;
	// Housekeeping
	vDirtyStatus = Catalogs.RoomStatuses.FindByCode("40");
	vHotel.RoomStatusAfterCheckOut = vDirtyStatus;
	vHotel.OutOfOrderRoomStatus = Catalogs.RoomStatuses.FindByCode("50");
	vHotel.OccupiedRoomStatus = Catalogs.RoomStatuses.FindByCode("10");
	vHotel.RoomStatusAfterRoomBlock = vDirtyStatus;
	vHotel.VacantRoomStatus = Catalogs.RoomStatuses.FindByCode("30");
	
	vHotel.RegularOperationGroup = CreateOperations();
	vFieldCleaning = Catalogs.Operations.FindByAttribute("SortCode", 10);
	vHotel.CheckOutCleaning = vFieldCleaning;
	vHotel.RegularCleaning = Catalogs.Operations.FindByAttribute("SortCode", 20);
	vHotel.VacantRoomCleaning = Catalogs.Operations.FindByAttribute("SortCode", 30);
	vHotel.RepairEndCleaning = vFieldCleaning;
	// Charging rules
	vCustomerChargingRuleRow = vHotel.CustomerChargingRules.Add();
	vCustomerChargingRuleRow.ChargingRule = Enums.ChargingRuleTypes.InRate;
	vCustomerChargingRuleRow.ChargingFolio = CreateFolio(vHotelRef);
	// Interaction with ext. systems
	vHotel.CateringService = CreateServices(vHotelRef);
	vHotel.PhoneCallService = Catalogs.Services.FindByCode("800");
	// Functionality
	vHotel.ShowCurrentAccountsReceivable = True;
	
	vHotel.Write();
	
EndProcedure // CreateHotel

// --------------------------------------------------------------------------------
// 
// Returns:
//  CatalogRef.Customers - customer reference
//
Function CreateCustomer()

	vCustomer = Catalogs.Customers.CreateItem();
	vCustomer.SetNewCode(Prefix);
	vCustomer.Description = FNStr("en = 'Individuals'; de = 'Einzelnen'; ru = 'ФИЗ. ЛИЦА'");
	vCustomer.LegacyName = FNStr("en = 'Individuals'; de = 'Einzelnen'; ru = 'Физические лица'");
	vCustomer.Language = Language;
	vCustomer.IsIndividual = True;
	vCustomer.PlannedPaymentMethod = CreatePaymentMethods();
	vCustomer.Write();
	
	Return vCustomer.Ref;

EndFunction // CreateCustomer

// --------------------------------------------------------------------------------
// 
// Returns:
//  CatalogRef.PaymentMethods - payment method by cash reference
//
Function CreatePaymentMethods()
	
	ClearObj("PaymentMethods");
	
	// Cash
	vCashMethod = Catalogs.PaymentMethods.CreateItem();
	vCashMethod.Code = FNStr("en = 'CASH'; de = 'CASH'; ru = 'НЛ'");
	vCashMethod.SortCode = 10;
	vDescription = "en = 'Cash'; de = 'Bargeld'; ru = 'Наличные'";
	vCashMethod.Description = FNStr(vDescription);
	vCashMethod.DescriptionTranslations = vDescription;
	vCashMethod.IsByCash = True;
	vCashMethod.BookByCashRegister = True;
	vCashMethod.PrintCheque = True;
	vCashMethod.CashRegisterChequeCloseType = 0;
	vCashMethod.Write();
	
	// Credit card
	vCreditCardMethod = Catalogs.PaymentMethods.CreateItem();
	vCreditCardMethod.Code = FNStr("en = 'CC'; de = 'CC'; ru = 'КК'");
	vCreditCardMethod.SortCode = 20;
	vDescription = "en = 'Credit card'; de = 'Kreditkarte'; ru = 'Кредитная карта'";
	vCreditCardMethod.Description = FNStr(vDescription);
	vCreditCardMethod.DescriptionTranslations = vDescription;
	vCreditCardMethod.BookByCashRegister = True;
	vCreditCardMethod.PrintCheque = True;
	vCreditCardMethod.CashRegisterChequeCloseType = 2;
	vCreditCardMethod.IsByCreditCard = True;
	vCreditCardMethod.Write();
	
	// Return
	vReturnMethod = Catalogs.PaymentMethods.CreateItem();
	vReturnMethod.Code = FNStr("en = 'RET'; de = 'RET'; ru = 'ВЗ'");
	vReturnMethod.SortCode = 30;
	vDescription = "en = 'Return'; de = 'Zurückgeben'; ru = 'Возврат'";
	vReturnMethod.Description = FNStr(vDescription);
	vReturnMethod.DescriptionTranslations = vDescription;
	vReturnMethod.IsByCash = True;
	vReturnMethod.BookByCashRegister = True;
	vReturnMethod.CashRegisterChequeCloseType = 0;
	vReturnMethod.IsForReturnOnly = True;
	vReturnMethod.Write();
	
	// Return by credit card
	vReturnByCreditCardMethod = Catalogs.PaymentMethods.CreateItem();
	vReturnByCreditCardMethod.Code = FNStr("en = 'RETC'; de = 'RETC'; ru = 'ВК'");
	vReturnByCreditCardMethod.SortCode = 40;
	vDescription = "en = 'Return by credit card';
				   |de = 'Rückgabe per Kreditkarte';
				   |ru = 'Возврат по кред. карте'";
	vReturnByCreditCardMethod.Description = FNStr(vDescription);
	vReturnByCreditCardMethod.DescriptionTranslations = vDescription;
	vReturnByCreditCardMethod.BookByCashRegister = True;
	vReturnByCreditCardMethod.CashRegisterChequeCloseType = 2;
	vReturnByCreditCardMethod.IsByCreditCard = True;
	vReturnByCreditCardMethod.IsForReturnOnly = True;
	vReturnByCreditCardMethod.Write();
	
	// Bank transfer
	vBankTransfer = Catalogs.PaymentMethods.CreateItem();
	vBankTransfer.Code = FNStr("en = 'BT'; de = 'BT'; ru = 'БН'");
	vBankTransfer.SortCode = 50;
	vDescription = "en = 'Bank transfer'; de = 'Banküberweisung'; ru = 'На расчетный счет'";
	vBankTransfer.Description = FNStr(vDescription);
	vBankTransfer.DescriptionTranslations = vDescription;
	vBankTransfer.IsByBankTransfer = True;
	vBankTransfer.Write();
	
	Return vCashMethod.Ref;

EndFunction // CreatePaymentMethods

// --------------------------------------------------------------------------------
Procedure CreateCurrencies()

	ClearObj("Currencies");
	
	// RUB
	vRUB = Catalogs.Currencies.CreateItem();
	vRUB.Code = 643;
	vRUB.SortCode = 10;
	vDescription = "en = 'RUB'; de = 'RUB'; ru = 'Руб.'"; 
	vRUB.Description = FNStr(vDescription);
	vRUB.DescriptionTranslations = vDescription;
	vRUB.CurrencySymbol = "р";
	// ru
	vRUSumInWords = vRUB.SumInWordsAttributes.Add();
	vRUSumInWords.Language = Catalogs.Languages.RU;
	vRUSumInWords.NumberInWordsAttributes = "рубль, рубля, рублей, м, копейка, копейки, копеек, ж, 2";
	// en
	vENSumInWords = vRUB.SumInWordsAttributes.Add();
	vENSumInWords.Language = Catalogs.Languages.EN;
	vENSumInWords.NumberInWordsAttributes = "ruble, rubles, copeck, copecks, 2";
	vRUB.Write();
	
	// USD
	vUSD = Catalogs.Currencies.CreateItem();
	vUSD.Code = 840;
	vUSD.SortCode = 20;
	vDescription = "en = 'USD'; de = 'USD'; ru = 'USD'"; 
	vUSD.Description = FNStr(vDescription);
	vUSD.DescriptionTranslations = vDescription;
	vUSD.CurrencySymbol = "$";
	// ru
	vRUSumInWords = vUSD.SumInWordsAttributes.Add();
	vRUSumInWords.Language = Catalogs.Languages.RU;
	vRUSumInWords.NumberInWordsAttributes = "доллар, доллара, долларов, м, цент, цента, центов,м,  2";
	// en
	vENSumInWords = vUSD.SumInWordsAttributes.Add();
	vENSumInWords.Language = Catalogs.Languages.EN;
	vENSumInWords.NumberInWordsAttributes = "dollar, dollars, cent, cents, 2";
	vUSD.Write();
	
	// EUR
	vEUR = Catalogs.Currencies.CreateItem();
	vEUR.Code = 978;
	vEUR.SortCode = 30;
	vDescription = "en = 'EUR'; de = 'EUR'; ru = 'EUR'"; 
	vEUR.Description = FNStr(vDescription);
	vEUR.DescriptionTranslations = vDescription;
	vEUR.CurrencySymbol = "€";
	// ru
	vRUSumInWords = vEUR.SumInWordsAttributes.Add();
	vRUSumInWords.Language = Catalogs.Languages.RU;
	vRUSumInWords.NumberInWordsAttributes = "евро,евро,евро,м,цент,цента,центов,ж,2";
	// en
	vENSumInWords = vEUR.SumInWordsAttributes.Add();
	vENSumInWords.Language = Catalogs.Languages.EN;
	vENSumInWords.NumberInWordsAttributes = "euro,euro,cent,cents,2";
	vEUR.Write();
	
EndProcedure // CreateCurrencies

// --------------------------------------------------------------------------------
//
// Parameters:
//  pHotelRef	 - CatalogRef.Hotels - hotel for which the room rate is created
// 
// Returns:
//  CatalogRef.RoomRates - room rate reference
//
Function CreateRoomRate(pHotelRef)

	ClearObj("RoomRates");
	
	vRoomRate = Catalogs.RoomRates.CreateItem();
	vRoomRate.Code = FNStr("en = 'RR'; de = 'RR'; ru = 'БАЗ'");
	vRoomRate.SortCode = 10;
	vRoomRate.Hotel = pHotelRef;
	vRoomRate.Description = FNStr("en = 'Rack rate'; de = 'Rack-Rate'; ru = 'Базовый'");
	vRoomRate.Calendar = CreateCalendar();
	vRoomRate.IsRackRate = True;
	vRoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour;
	vRoomRate.PeriodInHours = 24;
	vRoomRate.ReferenceHour = 12;
	vRoomRate.Write();
	
	Return vRoomRate.Ref;

EndFunction // CreateRoomRate

// --------------------------------------------------------------------------------
// 
// Returns:
//  CatalogRef.Calendars - calendar reference
//
Function CreateCalendar()

	ClearObj("Calendars");
	
	vCalendar = Catalogs.Calendars.CreateItem();
	vCalendar.Code = FNStr("en = 'Main'; de = 'WICH'; ru = 'ОСН'");
	vCalendar.SortCode = 10;
	vCalendar.Description = FNStr("en = 'Main'; de = 'Wichtigsten'; ru = 'Основной'");
	vCalendar.Write();
	
	Return vCalendar.Ref;

EndFunction // CreateCalendar

// --------------------------------------------------------------------------------
Procedure CreateReservationStatuses()
	
	ClearObj("ReservationStatuses");
	
	// Reservation
	vReservation = Catalogs.ReservationStatuses.CreateItem();
	vReservation.Code = "10";
	vReservation.SortCode = 10;
	vReservation.Description = FNStr("en = 'Reservation'; de = 'Reservierung'; ru = 'Бронь'");
	vReservation.IsActive = True;
	vReservation.ShowInClientsSearchForm = True;
	vReservation.Remarks = FNStr("en = 'Active reservation'; de = 'Aktive Reservierung'; ru = 'Действующая бронь'");
	vReservation.Write();
	
	// Refusal
	vRefusal= Catalogs.ReservationStatuses.CreateItem();
	vRefusal.Code = "20";
	vRefusal.SortCode = 20;
	vRefusal.Description = FNStr("en = 'Refusal'; de = 'Ablehnung'; ru = 'Отказ'");
	vRefusal.Remarks = FNStr("en = 'Refusal to stay within the terms established by the contract';
							 |de = 'Weigerung, innerhalb der vertraglich festgelegten Bedingungen zu bleiben';
							 |ru = 'Отказ от проживания в установленные договором сроки'");
	vRefusal.Write();
	
	// No-show
	vNoShow = Catalogs.ReservationStatuses.CreateItem();
	vNoShow.Code = "30";
	vNoShow.SortCode = 30;
	vNoShow.Description = FNStr("en = 'No-show'; de = 'Nichterscheinen'; ru = 'Незаезд'");
	vNoShow.DoCharging = True;
	vNoShow.DoNoShowCharging = True;
	vNoShow.Remarks = FNStr("en = 'No check-in by booking on time';
						    |de = 'Kein Check-in bei rechtzeitiger Buchung';
						    |ru = 'Незаезд по брони в установленные сроки'");
	vNoShow.Write();
	
	// Check-in
	vCheckIn = Catalogs.ReservationStatuses.CreateItem();
	vCheckIn.Code = "40";
	vCheckIn.SortCode = 40;
	vCheckIn.Description = FNStr("en = 'Check-in'; de = 'Einchecken'; ru = 'Заезд'");
	vCheckIn.IsCheckIn = True;
	vCheckIn.Remarks = FNStr("en = 'It is set automatically upon arrival of the guest by reservation';
						     |de = 'Es wird automatisch bei Ankunft des Gastes bei Reservierung eingestellt';
						     |ru = 'Устанавливается автоматически при заезде гостя по брони'");
	vCheckIn.Write();
	
	// Annulation
	vAnnulation = Catalogs.ReservationStatuses.CreateItem();
	vAnnulation.Code = "90";
	vAnnulation.SortCode = 90;
	vAnnulation.Description = FNStr("en = 'Annulation'; de = 'Annullierung'; ru = 'Аннуляция'");
	vAnnulation.Remarks = FNStr("en = 'Cancellation of a wrongly created reservation';
						        |de = 'Stornierung einer falsch erstellten Reservierung';
						        |ru = 'Аннуляция ошибочно созданной брони'");
	vAnnulation.Write();

EndProcedure // CreateReservationStatuses

// --------------------------------------------------------------------------------
Procedure CreateAccommodationStatuses()
	
	ClearObj("AccommodationStatuses");
	
	// Checked-in
	vCheckedIn = Catalogs.AccommodationStatuses.CreateItem();
	vCheckedIn.Code = "10";
	vCheckedIn.SortCode = 10;
	vCheckedIn.Description = FNStr("en = 'Checked-in'; de = 'Einchecken'; ru = 'Заезд'");
	vCheckedIn.IsActive = True;
	vCheckedIn.IsInHouse = True;
	vCheckedIn.IsCheckIn = True;
	vCheckedIn.IsCheckOut = True;
	vCheckedIn.Write();
	
	// Checked-out
	vCheckedOut = Catalogs.AccommodationStatuses.CreateItem();
	vCheckedOut.Code = "20";
	vCheckedOut.SortCode = 20;
	vCheckedOut.Description = FNStr("en = 'Checked-out'; de = 'Auschecken'; ru = 'Выезд'");
	vCheckedOut.IsActive = True;
	vCheckedOut.IsCheckIn = True;
	vCheckedOut.IsCheckOut = True;
	vCheckedOut.Write();
	
	// Room changed
	vRoomChanged = Catalogs.AccommodationStatuses.CreateItem();
	vRoomChanged.Code = "30";
	vRoomChanged.SortCode = 30;
	vRoomChanged.Description = FNStr("en = 'Room changed'; de = 'Zimmer gewechselt'; ru = 'Переселение'");
	vRoomChanged.Remarks = FNStr("en = 'Room changed'; de = 'Zimmer gewechselt'; ru = 'Переселение в другой номер'");
	vRoomChanged.IsActive = True;
	vRoomChanged.IsInHouse = True;
	vRoomChanged.IsRoomChange = True;
	vRoomChanged.IsCheckOut = True;
	vRoomChanged.Write();
	
	// Another room changed
	vAnotherRoomChanged = Catalogs.AccommodationStatuses.CreateItem();
	vAnotherRoomChanged.Code = "40";
	vAnotherRoomChanged.SortCode = 40;
	vAnotherRoomChanged.Description = FNStr("en = 'Another room changed';
										    |de = 'Ein anderes Zimmer hat sich verändert';
										    |ru = 'Переселение'");
	vAnotherRoomChanged.Remarks = FNStr("en = 'Second or more room change';
									    |de = 'Zweiter oder mehr Zimmerwechsel';
									    |ru = 'Переселение, после которого есть повторное переселение'");
	vAnotherRoomChanged.IsActive = True;
	vAnotherRoomChanged.IsRoomChange = True;
	vAnotherRoomChanged.Write();
	
	// Checked-in and change room 
	vCheckedInAndChange = Catalogs.AccommodationStatuses.CreateItem();
	vCheckedInAndChange.Code = "50";
	vCheckedInAndChange.SortCode = 50;
	vCheckedInAndChange.Description = FNStr("en = 'Checked-in and change room';
										   |de = 'Check-in und Umkleideraum';
										   |ru = 'Заезд и переселение'");
	vCheckedInAndChange.Remarks = FNStr("en = 'Check-in with room change later';
									   |de = 'Check-in mit späterem Zimmerwechsel';
								 	   |ru = 'Заезд, после которого есть переселение'");
	vCheckedInAndChange.IsActive = True;
	vCheckedInAndChange.IsCheckIn = True;
	vCheckedInAndChange.Write();
	
	// Room changed and checked-out
	vChangedAndCheckedOut = Catalogs.AccommodationStatuses.CreateItem();
	vChangedAndCheckedOut.Code = "60";
	vChangedAndCheckedOut.SortCode = 60;
	vChangedAndCheckedOut.Description = FNStr("en = 'Room changed and checked-out';
											  |de = 'Zimmer gewechselt und ausgecheckt';
											  |ru = 'Переселение и выезд'");
	vChangedAndCheckedOut.Remarks = FNStr("en = 'Room changed and then checked-out';
									      |de = 'Zimmer gewechselt und dann ausgecheckt';
								 	      |ru = 'Переселение и выезд'");
	vChangedAndCheckedOut.IsActive = True;
	vChangedAndCheckedOut.IsRoomChange = True;
	vChangedAndCheckedOut.IsCheckOut = True;
	vChangedAndCheckedOut.Write();
	
	// Annulation
	vAnnulation = Catalogs.AccommodationStatuses.CreateItem();
	vAnnulation.Code = "99";
	vAnnulation.SortCode = 99;
	vAnnulation.Description = FNStr("en = 'Annulation'; de = 'Annullierung'; ru = 'Аннуляция'");
	vAnnulation.Remarks = FNStr("en = 'Annulation accommodation with errors';
							    |de = 'Annullierungsunterkunft mit Fehlern';
							    |ru = 'Отмена ошибочно созданного размещения'");
	vAnnulation.IsInHouse = True;
	vAnnulation.Write();

EndProcedure // CreateAccommodationStatuses

// --------------------------------------------------------------------------------
// 
// Returns:
//  CatalogRef.ResourceReservationStatuses - reservation resource reservation statuse reference
//
Function CreateResourceReservationStatuses()

	ClearObj("ResourceReservationStatuses");
	
	// Reservation
	vReservation = Catalogs.ResourceReservationStatuses.CreateItem();
	vReservation.DataExchange.Load = True;
	vReservation.Code = FNStr("en = 'RS'; de = 'RS'; ru = 'БР'");
	vReservation.SortCode = 10;
	vReservation.Description = FNStr("en = 'Reservation'; de = 'Reservierung'; ru = 'Бронь'");
	vReservation.IsActive = True;
	vReservation.Write();
	
	// Guaranteed
	vGuaranteed = Catalogs.ResourceReservationStatuses.CreateItem();
	vGuaranteed.DataExchange.Load = True;
	vGuaranteed.Code = FNStr("en = 'GR'; de = 'GA'; ru = 'ГР'");
	vGuaranteed.SortCode = 20;
	vGuaranteed.Description = FNStr("en = 'Guaranteed'; de = 'Garantierte'; ru = 'Гарантированная'");
	vGuaranteed.IsActive = True;
	vGuaranteed.IsGuaranteed = True;
	vGuaranteed.Write();
	
	// Rendered
	vRendered = Catalogs.ResourceReservationStatuses.CreateItem();
	vRendered.DataExchange.Load = True;
	vRendered.Code = FNStr("en = 'RN'; de = 'GE'; ru = 'ГР'");
	vRendered.SortCode = 30;
	vRendered.Description = FNStr("en = 'Rendered'; de = 'Gerenderten'; ru = 'Оказано'");
	vRendered.IsActive = True;
	vRendered.IsGuaranteed = True;
	vRendered.ServicesAreDelivered = True;
	vRendered.Write();
	
	// Refusal
	vRefusal = Catalogs.ResourceReservationStatuses.CreateItem();
	vRefusal.DataExchange.Load = True;
	vRefusal.Code = FNStr("en = 'RF'; de = 'AB'; ru = 'ОТ'");
	vRefusal.SortCode = 40;
	vRefusal.Description = FNStr("en = 'Refusal'; de = 'Ablehnung'; ru = 'Отказ'");
	vRefusal.Write();
	
	// Annulation
	vAnnulation = Catalogs.ResourceReservationStatuses.CreateItem();
	vAnnulation.DataExchange.Load = True;
	vAnnulation.Code = FNStr("en = 'AN'; de = 'AN'; ru = 'АН'");
	vAnnulation.SortCode = 90;
	vAnnulation.Description = FNStr("en = 'Annulation'; de = 'Annullierung'; ru = 'Аннуляция'");
	vAnnulation.Write();
	
	Return vReservation.Ref;

EndFunction // CreateResourceReservationStatuses

// --------------------------------------------------------------------------------
Procedure CreateRoomStatuses()
	
	ClearObj("RoomStatuses");
	
	// Occupied
	vOccupied = Catalogs.RoomStatuses.CreateItem();
	vOccupied.DataExchange.Load = True;
	vOccupied.Code = "10";
	vOccupied.SortCode = 10;
	vOccupied.RoomStatusIcon = Enums.RoomStatusesIcons.Occupied;
	vOccupied.IconIndex = 2;
	vOccupied.Description = FNStr("en = 'Occupied'; de = 'Besetzt'; ru = 'Занят'");
	vOccupied.Remarks = FNStr("en = 'It is set automatically for occupied rooms.
							  |It is removed automatically when at least one guest leaves the room';
							  |de = 'Es wird automatisch für belegte Räume eingestellt.
							  |Es wird automatisch entfernt, wenn mindestens ein Gast das Zimmer verlässt';
							  |ru = 'Устанавливается автоматически у занятых номеров.
							  |Снимается автоматически при выезде хотя бы одного гостя из номера'");
	vOccupied.Write();
	
	// Occupied dirty
	vOccupiedDirty = Catalogs.RoomStatuses.CreateItem();
	vOccupiedDirty.DataExchange.Load = True;
	vOccupiedDirty.Code = "20";
	vOccupiedDirty.SortCode = 20;
	vOccupiedDirty.RoomStatusIcon = Enums.RoomStatusesIcons.TidyingUp;
	vOccupiedDirty.IconIndex = 0;
	vOccupiedDirty.Description = FNStr("en = 'Occupied dirty'; de = 'Besetzt schmutzig'; ru = 'Занят грязный'");
	vOccupiedDirty.Remarks = FNStr("en = 'It is set every morning at the occupied rooms
								   |automatically by a special scheduled procedure';
								   |de = 'Es wird jeden Morgen in den belegten Räumen
								   |automatisch durch ein spezielles geplantes Verfahren eingestellt';
								   |ru = 'Устанавливается каждое утро у занятых номеров
								   |автоматически специальной регламентной процедурой '");
	vOccupiedDirty.Write();
	
	// Clean
	vClean = Catalogs.RoomStatuses.CreateItem();
	vClean.DataExchange.Load = True;
	vClean.Code = "30";
	vClean.SortCode = 30;
	vClean.RoomStatusIcon = Enums.RoomStatusesIcons.Vacant;
	vClean.IconIndex = 4;
	vClean.Description = FNStr("en = 'Clean'; de = 'Sauber'; ru = 'Чистый'");
	vClean.Remarks = FNStr("en = 'The status of a free, ready-to-move room';
						   |de = 'Der Status eines freien, bezugsfertigen Zimmers';
						   |ru = 'Статус свободного, готового к заселению номера'");
	vClean.Write();
	
	// Dirty
	vDirty = Catalogs.RoomStatuses.CreateItem();
	vDirty.DataExchange.Load = True;
	vDirty.Code = "40";
	vDirty.SortCode = 40;
	vDirty.RoomStatusIcon = Enums.RoomStatusesIcons.CheckOut;
	vDirty.IconIndex = 3;
	vDirty.Description = FNStr("en = 'Dirty'; de = 'Schmutzig'; ru = 'Грязный'");
	vDirty.Remarks = FNStr("en = 'The status of the room after the guest''s departure';
						   |de = 'Der Status des Zimmers nach der Abreise des Gastes';
						   |ru = 'Статус номера после выезда гостя'");
	vDirty.Write();
	
	// Under repair
	vUnderRepair = Catalogs.RoomStatuses.CreateItem();
	vUnderRepair.DataExchange.Load = True;
	vUnderRepair.Code = "50";
	vUnderRepair.SortCode = 50;
	vUnderRepair.RoomStatusIcon = Enums.RoomStatusesIcons.Waiting;
	vUnderRepair.IconIndex = 1;
	vUnderRepair.Description = FNStr("en = 'Out of order'; de = 'Außer Betrieb'; ru = 'На ремонте'");
	vUnderRepair.Remarks = FNStr("en = 'The status of the room set for repair by blocking';
								 |de = 'Der Status des Raums, der durch Sperren repariert werden soll';
								 |ru = 'Статус номера поставленного на ремонт блокировкой'");
	vUnderRepair.Write();
	
	// Stuff in the room
	vStuffInTheRoom = Catalogs.RoomStatuses.CreateItem();
	vStuffInTheRoom.DataExchange.Load = True;
	vStuffInTheRoom.Code = "60";
	vStuffInTheRoom.SortCode = 60;
	vStuffInTheRoom.RoomStatusIcon = Enums.RoomStatusesIcons.Luggage;
	vStuffInTheRoom.IconIndex = 9;
	vStuffInTheRoom.Description = FNStr("en = 'Stuff in the room'; de = 'Sachen im Zimmer'; ru = 'Вещи в комнате'");
	vStuffInTheRoom.Remarks = FNStr("en = 'The status is set by the maids in cases when the receptionist believes that the
								    |guest has left, but in fact the guest''s belongings are in the room';
								    |de = 'Der Status wird von den Zimmermädchen festgelegt, wenn die Rezeptionistin glaubt,
								    |dass der Gast gegangen ist, aber tatsächlich die Sachen des Gastes im Zimmer sind';
								    |ru = 'Статус устанавливается горничными в случаях, когда портье считают что гость уехал,
								    |а по факту в номере находятся вещи гостя'");
	vStuffInTheRoom.Write();

EndProcedure // CreateRoomStatuses

// --------------------------------------------------------------------------------
// 
// Returns:
//  CatalogRef.RegularOperationGroups - change of linen regular operation group reference
//
Function CreateOperations()

	ClearObj("Operations");
	
	// Field cleaning
	vFieldCleaning = Catalogs.Operations.CreateItem();
	vFieldCleaning.DataExchange.Load = True;
	vFieldCleaning.Code = FNStr("en = 'CHOUT'; de = 'AUSCH'; ru = 'ВЫЕЗД'");
	vFieldCleaning.SortCode = 10;
	vFieldCleaning.Description = FNStr("en = 'Field cleaning'; de = 'Feldreinigung'; ru = 'Выездная уборка'");
	vFieldCleaning.IsCheckOutCleaning = True;
	vFieldCleaning.Write();
	
	// Regular cleaning
	vRegularCleaning = Catalogs.Operations.CreateItem();
	vRegularCleaning.DataExchange.Load = True;
	vRegularCleaning.Code = FNStr("en = 'RCL'; de = 'RER'; ru = 'ТЕК'");
	vRegularCleaning.SortCode = 20;
	vRegularCleaning.Description = FNStr("en = 'Regular cleaning'; de = 'Regelmäßige Reinigung'; ru = 'Текущая уборка'");
	vRegularCleaning.IsRegularCleaning = True;
	vRegularCleaning.Write();
	
	// Cosmetic cleaning
	vCosmeticCleaning = Catalogs.Operations.CreateItem();
	vCosmeticCleaning.DataExchange.Load = True;
	vCosmeticCleaning.Code = FNStr("en = 'VAC'; de = 'VAK'; ru = 'СВОБ'");
	vCosmeticCleaning.SortCode = 30;
	vCosmeticCleaning.Description = FNStr("en = 'Cosmetic cleaning';
										  |de = 'Kosmetische Reinigung';
										  |ru = 'Косметическая уборка'");
	vCosmeticCleaning.IsVacantRoomCleaning = True;
	vCosmeticCleaning.Write();
	
	// Change of linen
	vChangeOfLinen = Catalogs.Operations.CreateItem();
	vChangeOfLinen.DataExchange.Load = True;
	vChangeOfLinen.Code = FNStr("en = 'LINEN'; de = 'WÄSCH'; ru = 'СМБ'");
	vChangeOfLinen.SortCode = 110;
	vChangeOfLinen.Description = FNStr("en = 'Change of linen'; de = 'Wäschewechsel'; ru = 'Смена белья'");
	vChangeOfLinen.IsPerGuest = True;
	vChangeOfLinen.Write();
	
	Return CreateRegularOperationsGroup(vChangeOfLinen.Ref);
	
EndFunction // CreateOperations

// --------------------------------------------------------------------------------
//
// Parameters:
//  pChangeOfLinen	 - CatalogRef.Operations - change of linen operation reference
// 
// Returns:
//  CatalogRef.RegularOperationGroups - change of linen regular operation group reference
//
Function CreateRegularOperationsGroup(pChangeOfLinen)

	ClearObj("RegularOperationGroups");
	
	// Change of linen
	vChangeOfLinen = Catalogs.RegularOperationGroups.CreateItem();
	vChangeOfLinen.Code = FNStr("en = 'LINEN'; de = 'WÄSCH'; ru = 'СМБ'");
	vChangeOfLinen.Description = FNStr("en = 'Change of linen'; de = 'Wäschewechsel'; ru = 'Смена белья'");
	// Tabular section rows 
	vRegOpRow = vChangeOfLinen.RegularOperations.Add();
	vRegOpRow.RegularOperation = pChangeOfLinen;
	vRegOpRow.RegularOperationFrequency = 3;
	vRegOpRow.PerformWhenRoomIsBusy = True;
	vRegOpRow.IsPerGuest = True;
	
	vChangeOfLinen.Write();
	
	Return vChangeOfLinen.Ref;

EndFunction // CreateRegularOperationsGroup

// --------------------------------------------------------------------------------
//
// Parameters:
//  pHotelRef	 - CatalogRef.Hotels - hotel for which the folio is created
// 
// Returns:
//  DocumentRef.Folio - folio reference
//
Function CreateFolio(pHotelRef)

	vFolio = Documents.Folio.CreateDocument();
	vFolio.DataExchange.Load = True;
	vFolio.SetNewNumber(Prefix);
	vFolio.Date = BegOfYear(CurrentSessionDate());
	vFolio.FolioCurrency = Currency;
	vFolio.PaymentMethod = Catalogs.PaymentMethods.FindByAttribute("SortCode", 50);
	vFolio.Company = CompanyRef;
	vFolio.Hotel = pHotelRef;
	vFolio.Write(DocumentWriteMode.Write);
	
	Return vFolio.Ref;
	
EndFunction // CreateFolio

// --------------------------------------------------------------------------------
//
// Parameters:
//  pHotelRef	 - CatalogRef.Hotels - hotel for which the service prices are created
// 
// Returns:
//  CatalogRef.Services - restaurant service reference
//
Function CreateServices(pHotelRef)

	ClearObj("Services");
	
	vVAT18 = Catalogs.VATRates.FindByAttribute("TaxRate", 18);
	vNightUnit = Catalogs.Units.Night;
	
	// Accommodation
	vAccommodation = Catalogs.Services.CreateItem();
	vAccommodation.DataExchange.Load = True;
	vAccommodation.Code = "100";
	vAccommodation.SortCode = 10;
	vDescription = "en = 'Room rate'; de = 'Zimmerpreis'; ru = 'Проживание'";
	vAccommodation.Description = FNStr(vDescription);
	vAccommodation.DescriptionTranslations = vDescription;
	vAccommodation.GroupByDescriptionTranslations = vDescription;
	vAccommodation.Unit = vNightUnit.Description;
	vNigtUnitTranslations = "en = 'night'; de = 'Nacht'; ru = 'сут.'";
	vAccommodation.GetUnitFromRule = True;
	vAccommodation.UnitTranslations = vNigtUnitTranslations;
	vAccommodation.IsRoomRevenue = True;
	vAccommodation.IsInPrice = True;
	vAccommodation.Write();
	// Accommodation price
	CreateServicePrice(pHotelRef, vAccommodation.Ref, vVAT18);
	
	// Extra charge
	vExtraCharge = Catalogs.Services.CreateItem();
	vExtraCharge.DataExchange.Load = True;
	vExtraCharge.Code = "105";
	vExtraCharge.SortCode = 15;
	vDescription = "en = 'Extra charge'; de = 'Aufpreis'; ru = 'Доначисление'";
	vExtraCharge.Description = FNStr(vDescription);
	vExtraCharge.DescriptionTranslations = vDescription;
	vExtraCharge.Unit = vNightUnit.Description;
	vExtraCharge.UnitTranslations = vNigtUnitTranslations;
	vExtraCharge.AllowChangePrice = True;
	vExtraCharge.Write();
	// Extra charge price
	CreateServicePrice(pHotelRef, vExtraCharge.Ref, vVAT18);
	
	// Breakfast
	vBreakfast = Catalogs.Services.CreateItem();
	vBreakfast.DataExchange.Load = True;
	vBreakfast.Code = "400";
	vBreakfast.SortCode = 400;
	vDescription = "en = 'Breakfast'; de = 'Breakfast'; ru = 'Завтрак'";
	vBreakfast.Description = FNStr(vDescription);
	vBreakfast.DescriptionTranslations = vDescription;
	vBreakfast.IsInPrice = True;
	vBreakfast.Write();
	// Breakfast price
	CreateServicePrice(pHotelRef, vBreakfast.Ref, vVAT18);
	
	// Restaurant
	vRestaurant = Catalogs.Services.CreateItem();
	vRestaurant.DataExchange.Load = True;
	vRestaurant.Code = "410";
	vRestaurant.SortCode = 410;
	vDescription = "en = 'Restaurant'; de = 'Restaurant'; ru = 'Заказ ресторана'";
	vRestaurant.Description = FNStr(vDescription);
	vRestaurant.DescriptionTranslations = vDescription;
	vRestaurant.IsInPrice = True;
	vRestaurant.Write();
	// Restaurant price
	CreateServicePrice(pHotelRef, vRestaurant.Ref, vVAT18);
	
	// Phone calls
	vPhoneCalls = Catalogs.Services.CreateItem();
	vPhoneCalls.DataExchange.Load = True;
	vPhoneCalls.Code = "800";
	vPhoneCalls.SortCode = 80;
	vDescription = "en = 'Phone calls'; de = 'Anruf'; ru = 'Телефонные разговоры'";
	vPhoneCalls.Description = FNStr(vDescription);
	vPhoneCalls.DescriptionTranslations = vDescription;
	vPhoneCalls.Unit = Catalogs.Units.Minute.Description;
	vPhoneCalls.UnitTranslations = "en = 'min.'; de = 'min.'; ru = 'мин.'";
	vPhoneCalls.AllowChangePrice = True;
	vPhoneCalls.SplitToSeparateSettlements = True;
	vPhoneCalls.Write();
	// Phone calls price
	CreateServicePrice(pHotelRef, vPhoneCalls.Ref, vVAT18);
	
	Return vRestaurant.Ref;
	
EndFunction // CreateServices

// --------------------------------------------------------------------------------
Procedure CreateServicePrice(pHotelRef, pService, pVATRate)

	vServicePrice = InformationRegisters.ServicePrices.CreateRecordManager();
	vServicePrice.Hotel = pHotelRef;
	vServicePrice.Period = BegOfYear(CurrentSessionDate());
	vServicePrice.Service = pService;
	vServicePrice.Price = 0;
	vServicePrice.Currency = Currency;
	vServicePrice.VATRate = pVATRate;
	vServicePrice.Write();

EndProcedure // CreateServicePrice

// --------------------------------------------------------------------------------
Procedure RenameUnits()

	// Mililitre
	vRef = Catalogs.Units.Mililitre;
	vUnit = vRef.GetObject();
	vUnit.Description = FNStr("en = 'ml'; de = 'ml'; ru = 'мл'");
	vUnit.Write();
	
	// Litre
	vRef = Catalogs.Units.Litre;
	vUnit = vRef.GetObject();
	vUnit.Description = FNStr("en = 'l'; de = 'l'; ru = 'л.'");
	vUnit.Write();
	
	// Gram
	vRef = Catalogs.Units.Gram;
	vUnit = vRef.GetObject();
	vUnit.Description = FNStr("en = 'g.'; de = 'g.'; ru = 'г.'");
	vUnit.Write();
	
	// Kilogram
	vRef = Catalogs.Units.Kilogram;
	vUnit = vRef.GetObject();
	vUnit.Description = FNStr("en = 'kg'; de = 'kg'; ru = 'кг.'");
	vUnit.Write();
	
	// Megabyte
	vRef = Catalogs.Units.Megabyte;
	vUnit = vRef.GetObject();
	vUnit.Description = FNStr("en = 'mb'; de = 'Mb'; ru = 'мбайт.'");
	vUnit.Write();
	
	// Minute
	vRef = Catalogs.Units.Minute;
	vUnit = vRef.GetObject();
	vUnit.Description = FNStr("en = 'min.'; de = 'min.'; ru = 'мин.'");
	vUnit.Write();
	
	// Hour
	vRef = Catalogs.Units.Hour;
	vUnit = vRef.GetObject();
	vUnit.Description = FNStr("en = 'hour'; de = 'hour'; ru = 'ч.'");
	vUnit.Write();
	
	// Night
	vRef = Catalogs.Units.Night;
	vUnit = vRef.GetObject();
	vUnit.Description = FNStr("en = 'night'; de = 'Nacht'; ru = 'сут.'");
	vUnit.Write();
	
	// Day
	vRef = Catalogs.Units.ManDay;
	vUnit = vRef.GetObject();
	vUnit.Description = FNStr("en = 'day'; de = 'Tag'; ru = 'чел. дн.'");
	vUnit.Write();
	
	// Pack
	vRef = Catalogs.Units.Pack;
	vUnit = vRef.GetObject();
	vUnit.Description = FNStr("en = 'pack'; de = 'Pack'; ru = 'упак.'");
	vUnit.Write();
	
	// Man
	vRef = Catalogs.Units.Man;
	vUnit = vRef.GetObject();
	vUnit.Description = FNStr("en = 'pers'; de = 'Pers'; ru = 'чел.'");
	vUnit.Write();
	
	// Piece
	vRef = Catalogs.Units.Piece;
	vUnit = vRef.GetObject();
	vUnit.Description = FNStr("en = 'pcs'; de = 'St'; ru = 'шт.'");
	vUnit.Write();
	
EndProcedure // RenameUnits

// --------------------------------------------------------------------------------
Procedure CreateAccommodationTypes()
	
	ClearObj("AccommodationTypes");
	
	// Room
	vRoom = Catalogs.AccommodationTypes.CreateItem();
	vRoom.DataExchange.Load = True;
	vRoom.Code = "10";
	vRoom.SortCode = 10;
	vDescription = "en = 'Room'; de = 'Zimmer'; ru = 'Номер'";
	vRoom.Description = FNStr(vDescription);
	vRoom.DescriptionTranslations = vDescription;
	vRoom.Type = Enums.AccomodationTypes.Room;
	vRoom.NumberOfRooms = 1;
	vRoom.NumberOfPersons = 1;
	vRoom.Write();
	
	// Bed
	vBed = Catalogs.AccommodationTypes.CreateItem();
	vBed.DataExchange.Load = True;
	vBed.Code = "20";
	vBed.SortCode = 20;
	vDescription = "en = 'Bed'; de = 'Bett'; ru = 'Место'";
	vBed.Description = FNStr(vDescription);
	vBed.DescriptionTranslations = vDescription;
	vBed.Type = Enums.AccomodationTypes.Beds;
	vBed.NumberOfBeds = 1;
	vBed.NumberOfPersons = 1;
	vBed.Write();

	// Accompany
	vAccompany = Catalogs.AccommodationTypes.CreateItem();
	vAccompany.DataExchange.Load = True;
	vAccompany.Code = "30";
	vAccompany.SortCode = 30;
	vDescription = "en = 'Accompany'; de = 'Begleiten'; ru = 'Подселение'";
	vAccompany.Description = FNStr(vDescription);
	vAccompany.DescriptionTranslations = vDescription;
	vAccompany.Type = Enums.AccomodationTypes.Together;
	vAccompany.NumberOfPersons = 1;
	vAccompany.Write();
	
	// Additional bed
	vAddBed = Catalogs.AccommodationTypes.CreateItem();
	vAddBed.DataExchange.Load = True;
	vAddBed.Code = "40";
	vAddBed.SortCode = 40;
	vDescription = "en = 'Additional bed'; de = 'Extrabett'; ru = 'Доп. место'";
	vAddBed.Description = FNStr(vDescription);
	vAddBed.DescriptionTranslations = vDescription;
	vAddBed.Type = Enums.AccomodationTypes.AdditionalBed;
	vAddBed.NumberOfPersons = 1;
	vAddBed.Write();
	
EndProcedure // CreateAccommodationTypes

// --------------------------------------------------------------------------------
Procedure CreateFirstClient()

	ClearObj("Clients");
	
	vClient = Catalogs.Clients.CreateItem();
	If ValueIsFilled(Prefix) Then
		vClient.SetNewCode(Prefix);
	Else
		vClient.Code = "000000000001";
	EndIf;
	vClient.LastName = "Test";
	vClient.Write();

EndProcedure // CreateFirstClient

// --------------------------------------------------------------------------------
Procedure CreatePermissionGroups()
	
	ClearObj("PermissionGroups");
	
	vExceptArray = New Array;

	// Get roles
	vRolesStructure = New Map;
	For Each vRole In Metadata.Roles Do
		vRolesStructure.Insert(vRole.Name, vRole);
	EndDo;
	
	// ----ADMINISTRATOR-----
	vAdm = Catalogs.PermissionGroups.CreateItem();
	vAdm.Code = FNStr("en = 'ADM'; de = 'ADM'; ru = 'АДМ'");
	vAdm.Description = FNStr("en = 'System Administrator'; de = 'Systemadministrator'; ru = 'Системный администратор'");
	// Add payment methods and room statuses
	AddPaymentMethodsToPermissionGroup(vAdm.PaymentMethodsAllowed);
	AddRoomStatusesToPermissionGroup(vAdm.RoomStatusesAllowed);
	
	vAdm.AllowedAnnulationDelayTime = 15;
	// Set roles
	vActiveRoles = New Array;
	vActiveRoles.Add(vRolesStructure.Get("Administrator"));
	vActiveRoles.Add(vRolesStructure.Get("RightsToChooseHotel"));
	vActiveRoles.Add(vRolesStructure.Get("RightsToMergeCatalogItemsAndChangeHistory"));
	vActiveRoles.Add(vRolesStructure.Get("RightsToOpenExternalReportsAndDataProcessorsInteractively"));

	AddActiveRolesToPermissionGroup(vAdm.InfobaseUserRoles, vActiveRoles);
	
	vAdm.HavePermissionToAddManualDiscounts = True;
	vAdm.HavePermissionToAddManualPrices = True;
	vAdm.HavePermissionToAnnulateCashRegisterCheques = True;
	vAdm.HavePermissionToChangeCheckOutDateInDoorLockSystem = True;
	vAdm.HavePermissionToChangeFolioInFolioTransactions = True;
	vAdm.HavePermissionToChangeRoomStatuses = True;
	vAdm.HavePermissionToCheckCurrencyRatesActuality = True;
	vAdm.HavePermissionToCheckInBasedOnInactiveReservations = True;
	vAdm.HavePermissionToCheckOutAccommodationsWithClientDebts = True;
	vAdm.HavePermissionToCheckOutAccommodationsWithCustomerDebts = True;
	vAdm.HavePermissionToChooseWorkstationOnProgramStartUp = False;
	vAdm.HavePermissionToDeleteForeignerLogRecords = True;
	vAdm.HavePermissionToDoCashAndCreditCardPaymentsWithoutCashRegister = True;
	vAdm.HavePermissionToDoCheckInWithEmptyGuest = True;
	vAdm.HavePermissionToDoOverbooking = True;
	vAdm.HavePermissionToDoRoomQuotaOverbooking = True;
	vAdm.HavePermissionToDoRoomQuotaOversales = True;
	vAdm.HavePermissionToEditAccommodationDocumentNumberAndDate = True;
	vAdm.HavePermissionToEditClosedFolios = True;
	vAdm.HavePermissionToEditCheckedOutAccommodations = True;
	vAdm.HavePermissionToEditCheckInDateTimeInPast = True;
	vAdm.HavePermissionToUseReferenceHourAsDefaultCheckOutTime = True;
	vAdm.HavePermissionToEditCheckOutDateTime = True;
	vAdm.HavePermissionToSetCheckOutDateInThePast = True;
	vAdm.HavePermissionToEditClosedForEditDocuments = True;
	vAdm.HavePermissionToEditCloseOfCashRegisterDayDate = True;
	vAdm.HavePermissionToEditCustomer = True;
	vAdm.HavePermissionToEditGuestGroup = True;
	vAdm.HavePermissionToEditPostedCashIncomeOutcomeTransactions = True;
	vAdm.HavePermissionToEditPostedCloseOfCashRegisterDayDocuments = True;
	vAdm.HavePermissionToEditPostedFolioTransactions = True;
	vAdm.HavePermissionToStornoFolioCharges = True;
	vAdm.HavePermissionToReturnPayments = True;
	vAdm.HavePermissionToReturnBasedOnFolio = True;
	vAdm.HavePermissionToReturnCashDirectlyFromCashBox = True;
	vAdm.HavePermissionToEditPrintForms = True;
	vAdm.HavePermissionToEditReservationDocumentNumberAndDate = True;
	vAdm.HavePermissionToEditReservations = True;
	vAdm.HavePermissionToSetDeletionMarkForReservations = True;
	vAdm.HavePermissionToEditRoomRateServices = True;
	vAdm.HavePermissionToEditServicePrices = True;
	vAdm.HavePermissionToIgnoreBlackListLimitations = True;
	vAdm.HavePermissionToIgnoreNumberOfGuestsPerRoomLimits = True;
	vAdm.HavePermissionToManuallySetCheckedOutAccommodationStatus = True;
	vAdm.HavePermissionToPrintCashRegisterXReport = True;
	vAdm.HavePermissionToPrintCashRegisterZReport = True;
	vAdm.HavePermissionToPrintCheckOutDateInTheForeignerNotificationFormFooter = True;
	vAdm.HavePermissionToRunAllDataProcessors = True;
	vAdm.HavePermissionToRunAllReports = True;
	vAdm.HavePermissionToSaveCreditCards = True;
	vAdm.HavePermissionToSignForeignerNotificationForm = True;
	vAdm.HavePermissionToSkipInputOfGuestAddress = True;
	vAdm.HavePermissionToSkipInputOfGuestIdentificationDocumentData = True;
	vAdm.HavePermissionToSkipInputOfGuestTripPurpose = True;
	vAdm.HavePermissionToTextEditClientAddresses = True;
	vAdm.HavePermissionToTransferDepositsBetweenGuestGroups = True;
	vAdm.HavePermissionToTransferDepositsBetweenGuestsOfOneGuestGroup = True;
	vAdm.HavePermissionToUseOccupiedRooms = True;
	vAdm.HavePermissionToViewAllCashRegisters = True;
	vAdm.HavePermissionToViewCreditCardsData = True;
	vAdm.HavePermissionToViewHotelOccupationStatistics = True;
	vAdm.HavePermissionToViewCustomerOperationalBalance = True;
	vAdm.HavePermissionToSetDeletionMarkForAccommodations = True;
	vAdm.HavePermissionToSetDeletionMarkForSetRoomBlocks = True;
	vAdm.HavePermissionToSetRoomBlocks = True;
	vAdm.HavePermissionToEditAccommodationCheckInDate = True;
	vAdm.HavePermissionToCheckInToRoomsWithForbiddenStatus = True;
	vAdm.HavePermissionToSetDoorLockSystemAuthorizations = True;
	vAdm.HavePermissionToCreateNewReservations = True;
	vAdm.HavePermissionToCreateNewAccommodations = True;
	vAdm.HavePermissionToEditAccommodations = True;
	vAdm.HavePermissionToIssueKeyCardsBasedOnReservations = True;
	vAdm.HavePermissionToCloseNewReservationWithoutSave = True;
	vAdm.HavePermissionToChangeCustomerInDocuments = True;
	vAdm.HavePermissionToEditCustomerFolioTransactions = True;
	vAdm.HavePermissionToSkipInputOfAccommodationMarketingCode = True;
	vAdm.HavePermissionToSkipInputOfAccommodationSourceOfBusiness = True;
	vAdm.HavePermissionToEditChargingRules = True;
	vAdm.HavePermissionToUseOccupiedResources = True;
	vAdm.HavePermissionToCreateNewResourceReservations = True;
	vAdm.HavePermissionToEditResourceReservationDocumentNumberAndDate = True;
	vAdm.HavePermissionToEditResourceReservations = True;
	vAdm.HavePermissionToSetDeletionMarkForResourceReservations = True;
	vAdm.HavePermissionToIssueKeyCardsForGuestsWithDebtsOnKeyValidToDate = True;
	vAdm.HavePermissionToSetZeroManualPriceForAccommodation = True;
	vAdm.HavePermissionToIssueHotelProducts = True;
	vAdm.HavePermissionToSetFixedPeriodForTheHotelProduct = True;
	vAdm.HavePermissionToSetFixedCostForTheHotelProduct = True;
	vAdm.HavePermissionToCheckOutOnExpectedCheckOutTime = False;
	vAdm.HavePermissionToStopSaleRoomTypes = True;
	vAdm.HavePermissionToIgnoreStopSaleLimitations = True;
	vAdm.HavePermissionToManageRoomInventory = True;
	vAdm.HavePermissionToManageResources = True;
	vAdm.HavePermissionToManagePrices = True;
	vAdm.HavePermissionToPostPaymentsWithEmptyPaymentSections = True;
	vAdm.HavePermissionToUseVirtualRooms = True;
	vAdm.HavePermissionToAddCheckPointNumbersToTheCatalog = True;
	vAdm.HavePermissionToEditFolioDocumentForm = True;
	vAdm.HavePermissionToSkipInputOfClientType = True;
	vAdm.HavePermissionToStopSaleRooms = True;
	vAdm.HavePermissionToChargeIgnoringChargingRules = True;
	vAdm.HavePermissionToSeeAllMessages = True;
	vAdm.HavePermissionToSkipInputOfReservationTripPurpose = True;
	vAdm.HavePermissionToSkipInputOfReservationMarketingCode = True;
	vAdm.HavePermissionToSkipInputOfReservationSourceOfBusiness = True;
	vAdm.HavePermissionToSeePricesDifferentFromRoomRackRates = True;
	vAdm.HavePermissionToManageReportColumns = True;
	vAdm.HavePermissionToTakeFolioDebtDecisions = True;
	vAdm.HavePermissionToDoRoomTypeUpgrade = True;
	vAdm.HavePermissionToUseAnyRoomTypeForUpgrade = True;
	vAdm.HavePermissionToSkipInputOfReservationContactPerson = True;
	vAdm.HavePermissionToDoBookingWithoutRooms = True;
	vAdm.HavePermissionToManageHousekeeping = True;
	vAdm.HavePermissionToUsePreauthorisation = True;
	vAdm.HavePermissionToTransferPreauthorisations = True;
	vAdm.HavePermissionToCancelAccommodations = True;
	vAdm.HavePermissionToEditFoliosCreditLimit = True;
	vAdm.HavePermissionToEditExportedSettlements = True;
	vAdm.HavePermissionToChooseClientTypeManually = True;
	vAdm.HavePermissionToEditCustomerAndGuestGroupManagers = True;
	vAdm.HavePermissionToCreateReservationsWithoutContactClientAndCustomerData = True;
	vAdm.HavePermissionToManageAllotments = True;
	vAdm.HavePermissionToIgnoreGuestAgeLimitations = True;
	vAdm.HavePermissionToIgnoreAccommodationTemplates = True;
	vAdm.HavePermissionToApproveRoomRates = True;
	vAdm.HavePermissionToMessagesDelivery = True;
	vAdm.HavePermissionToRecalculateInvoicesBeingAlreadyPaid = True;
	vAdm.HavePermissionToDoBookingWithoutCustomerContactData = True;
	vAdm.HavePermissionToCreateCustomersWithoutTIN = True;
	vAdm.HavePermissionToEditInactiveReservations = True;
	vAdm.HavePermissionToSkipBoardPlaceSetting = True;
	vAdm.HavePermissionToEditCompletedResourceReservations = False;
	vAdm.HavePermissionToInputDiscountCardNumberManually = False;
	vAdm.HavePermissionToUseClientDiscountCardWithAnyOtherClientHavingIt = False;
	vAdm.HavePermissionToChargeExtraServicesOnCredit = True;
	vAdm.HavePermissionToSeeDataForAllCompanies = False;
	vAdm.HavePermissionToTransferMoneyFromFoliosWithDebts = False;
	vAdm.HavePermissionToChangeActivatedCards = False;
	vAdm.HavePermissionToUseCityLedgerPaymentMethodForIndividualsFolios = False;
	vAdm.HavePermissionToEditAllMessages = False;
	vAdm.HavePermissionToCheckIfAdvancesClearingIsDone = False;
	vAdm.HavePermissionToCreateReservationsInThePast = False;
	vAdm.HavePermissionToEditInvoicesCreatedInTheCurrentAccountingPeriod = False;
	vAdm.HavePermissionToEditInvoicesCreatedInThePastAccountingPeriods = False;
	vAdm.HavePermissionToForbiddenCheckInForGuestsWithActiveAccommodation = False;
	vAdm.HavePermissionToCloseOpenTasks = False;
	vAdm.HavePermissionToUseDoNotChangeAvailabilityFlag = False;
	vAdm.HavePermissionToAddManualBonusesOperation = False;
	vAdm.HavePermissionToManageBusinessBlocks = True;
	vAdm.HavePermissionToSetDeletionMarkForBusinessBlocks = True;
	
	vAdm.Write();
	
	// ----RECEPTIONIST-----
	vRec = Catalogs.PermissionGroups.CreateItem();
	vRec.Code = FNStr("en = 'REC'; de = 'EMP'; ru = 'ПРТ'");
	vRec.Description = FNStr("en = 'Receptionist'; de = 'Empfangsdame'; ru = 'Портье'");
	// Add payment methods and room statuses
	vExceptArray.Clear();
	vExceptArray.Add(50);
	AddPaymentMethodsToPermissionGroup(vRec.PaymentMethodsAllowed, vExceptArray);
	vExceptArray.Clear();
	vExceptArray.Add(50);
	vExceptArray.Add(60);
	AddRoomStatusesToPermissionGroup(vRec.RoomStatusesAllowed);
	
	vRec.AllowedAnnulationDelayTime = 15;
	// Set roles
	vActiveRoles = New Array;
	vActiveRoles.Add(vRolesStructure.Get("General"));
	vActiveRoles.Add(vRolesStructure.Get("SubsystemFrontOffice"));
	vActiveRoles.Add(vRolesStructure.Get("SubsystemHouseKeeping"));
	vActiveRoles.Add(vRolesStructure.Get("SubsystemOrders"));
	vActiveRoles.Add(vRolesStructure.Get("SubsystemTasks"));
	AddActiveRolesToPermissionGroup(vRec.InfobaseUserRoles, vActiveRoles);
	
	vRec.HavePermissionToAddManualDiscounts = False;
	vRec.HavePermissionToAddManualPrices = False;
	vRec.HavePermissionToAnnulateCashRegisterCheques = True;
	vRec.HavePermissionToChangeCheckOutDateInDoorLockSystem = False;
	vRec.HavePermissionToChangeFolioInFolioTransactions = False;
	vRec.HavePermissionToChangeRoomStatuses = True;
	vRec.HavePermissionToCheckCurrencyRatesActuality = False;
	vRec.HavePermissionToCheckInBasedOnInactiveReservations = False;
	vRec.HavePermissionToCheckOutAccommodationsWithClientDebts = True;
	vRec.HavePermissionToCheckOutAccommodationsWithCustomerDebts = True;
	vRec.HavePermissionToChooseWorkstationOnProgramStartUp = False;
	vRec.HavePermissionToDeleteForeignerLogRecords = False;
	vRec.HavePermissionToDoCashAndCreditCardPaymentsWithoutCashRegister = False;
	vRec.HavePermissionToDoCheckInWithEmptyGuest = False;
	vRec.HavePermissionToDoOverbooking = False;
	vRec.HavePermissionToDoRoomQuotaOverbooking = False;
	vRec.HavePermissionToDoRoomQuotaOversales = False;
	vRec.HavePermissionToEditAccommodationDocumentNumberAndDate = False;
	vRec.HavePermissionToEditClosedFolios = False;
	vRec.HavePermissionToEditCheckedOutAccommodations = False;
	vRec.HavePermissionToEditCheckInDateTimeInPast = False;
	vRec.HavePermissionToUseReferenceHourAsDefaultCheckOutTime = False;
	vRec.HavePermissionToEditCheckOutDateTime = True; // 
	vRec.HavePermissionToSetCheckOutDateInThePast = False;
	vRec.HavePermissionToEditClosedForEditDocuments = False;
	vRec.HavePermissionToEditCloseOfCashRegisterDayDate = False;
	vRec.HavePermissionToEditCustomer = True; //
	vRec.HavePermissionToEditGuestGroup = False;
	vRec.HavePermissionToEditPostedCashIncomeOutcomeTransactions = False;
	vRec.HavePermissionToEditPostedCloseOfCashRegisterDayDocuments = False;
	vRec.HavePermissionToEditPostedFolioTransactions = False;
	vRec.HavePermissionToStornoFolioCharges = True; //
	vRec.HavePermissionToReturnPayments = True; //
	vRec.HavePermissionToReturnBasedOnFolio = False;
	vRec.HavePermissionToReturnCashDirectlyFromCashBox = False;
	vRec.HavePermissionToEditPrintForms = False;
	vRec.HavePermissionToEditReservationDocumentNumberAndDate = False;
	vRec.HavePermissionToEditReservations = True; //
	vRec.HavePermissionToSetDeletionMarkForReservations = False;
	vRec.HavePermissionToEditRoomRateServices = False;
	vRec.HavePermissionToEditServicePrices = False;
	vRec.HavePermissionToIgnoreBlackListLimitations = False;
	vRec.HavePermissionToIgnoreNumberOfGuestsPerRoomLimits = True; //
	vRec.HavePermissionToManuallySetCheckedOutAccommodationStatus = False;
	vRec.HavePermissionToPrintCashRegisterXReport = True; // 
	vRec.HavePermissionToPrintCashRegisterZReport = True; // 
	vRec.HavePermissionToPrintCheckOutDateInTheForeignerNotificationFormFooter = False;
	vRec.HavePermissionToRunAllDataProcessors = False;
	vRec.HavePermissionToRunAllReports = True; //
	vRec.HavePermissionToSaveCreditCards = False;
	vRec.HavePermissionToSignForeignerNotificationForm = True; //
	vRec.HavePermissionToSkipInputOfGuestAddress = True; //
	vRec.HavePermissionToSkipInputOfGuestIdentificationDocumentData = True; //
	vRec.HavePermissionToSkipInputOfGuestTripPurpose = True; //
	vRec.HavePermissionToTextEditClientAddresses = False;
	vRec.HavePermissionToTransferDepositsBetweenGuestGroups = False;
	vRec.HavePermissionToTransferDepositsBetweenGuestsOfOneGuestGroup = True; //
	vRec.HavePermissionToUseOccupiedRooms = False;
	vRec.HavePermissionToViewAllCashRegisters = False;
	vRec.HavePermissionToViewCreditCardsData = False;
	vRec.HavePermissionToViewHotelOccupationStatistics = True; //
	vRec.HavePermissionToViewCustomerOperationalBalance = False;
	vRec.HavePermissionToSetDeletionMarkForAccommodations = False;
	vRec.HavePermissionToSetDeletionMarkForSetRoomBlocks = False;
	vRec.HavePermissionToSetRoomBlocks = True; //
	vRec.HavePermissionToEditAccommodationCheckInDate = False;
	vRec.HavePermissionToCheckInToRoomsWithForbiddenStatus = False;
	vRec.HavePermissionToSetDoorLockSystemAuthorizations = False;
	vRec.HavePermissionToCreateNewReservations = True; //
	vRec.HavePermissionToCreateNewAccommodations = True; //
	vRec.HavePermissionToEditAccommodations = True; //
	vRec.HavePermissionToIssueKeyCardsBasedOnReservations = False;
	vRec.HavePermissionToCloseNewReservationWithoutSave = True; //
	vRec.HavePermissionToChangeCustomerInDocuments = True; //
	vRec.HavePermissionToEditCustomerFolioTransactions = True; //
	vRec.HavePermissionToSkipInputOfAccommodationMarketingCode = True; //
	vRec.HavePermissionToSkipInputOfAccommodationSourceOfBusiness = True; //
	vRec.HavePermissionToEditChargingRules = True; //
	vRec.HavePermissionToUseOccupiedResources = False; 
	vRec.HavePermissionToCreateNewResourceReservations = True; //
	vRec.HavePermissionToEditResourceReservationDocumentNumberAndDate = False;
	vRec.HavePermissionToEditResourceReservations = True; //
	vRec.HavePermissionToSetDeletionMarkForResourceReservations = False;
	vRec.HavePermissionToIssueKeyCardsForGuestsWithDebtsOnKeyValidToDate = False;
	vRec.HavePermissionToSetZeroManualPriceForAccommodation = False;
	vRec.HavePermissionToIssueHotelProducts = True; //
	vRec.HavePermissionToSetFixedPeriodForTheHotelProduct = False;
	vRec.HavePermissionToSetFixedCostForTheHotelProduct = True; //
	vRec.HavePermissionToCheckOutOnExpectedCheckOutTime = False;
	vRec.HavePermissionToStopSaleRoomTypes = False;
	vRec.HavePermissionToIgnoreStopSaleLimitations = False;
	vRec.HavePermissionToManageRoomInventory = False;
	vRec.HavePermissionToManageResources = False;
	vRec.HavePermissionToManagePrices = False;
	vRec.HavePermissionToPostPaymentsWithEmptyPaymentSections = True; //
	vRec.HavePermissionToUseVirtualRooms = True; //
	vRec.HavePermissionToAddCheckPointNumbersToTheCatalog = True; //
	vRec.HavePermissionToEditFolioDocumentForm = True; //
	vRec.HavePermissionToSkipInputOfClientType = True; //
	vRec.HavePermissionToStopSaleRooms = False;
	vRec.HavePermissionToChargeIgnoringChargingRules = True; //
	vRec.HavePermissionToSeeAllMessages = False;
	vRec.HavePermissionToSkipInputOfReservationTripPurpose = True; //
	vRec.HavePermissionToSkipInputOfReservationMarketingCode = True; //
	vRec.HavePermissionToSkipInputOfReservationSourceOfBusiness = True; //
	vRec.HavePermissionToSeePricesDifferentFromRoomRackRates = True; //
	vRec.HavePermissionToManageReportColumns = False;
	vRec.HavePermissionToTakeFolioDebtDecisions = False;
	vRec.HavePermissionToDoRoomTypeUpgrade = True; //
	vRec.HavePermissionToUseAnyRoomTypeForUpgrade = False;
	vRec.HavePermissionToSkipInputOfReservationContactPerson = True; //
	vRec.HavePermissionToDoBookingWithoutRooms = True; //
	vRec.HavePermissionToManageHousekeeping = False;
	vRec.HavePermissionToUsePreauthorisation = True; //
	vRec.HavePermissionToTransferPreauthorisations = True; //
	vRec.HavePermissionToCancelAccommodations = True; //
	vRec.HavePermissionToEditFoliosCreditLimit = True; //
	vRec.HavePermissionToEditExportedSettlements = False;
	vRec.HavePermissionToChooseClientTypeManually = True; //
	vRec.HavePermissionToEditCustomerAndGuestGroupManagers = False;
	vRec.HavePermissionToCreateReservationsWithoutContactClientAndCustomerData = False;
	vRec.HavePermissionToManageAllotments = False;
	vRec.HavePermissionToIgnoreGuestAgeLimitations = True; //
	vRec.HavePermissionToIgnoreAccommodationTemplates = True; //
	vRec.HavePermissionToApproveRoomRates = False;
	vRec.HavePermissionToMessagesDelivery = False;
	vRec.HavePermissionToRecalculateInvoicesBeingAlreadyPaid = False;
	vRec.HavePermissionToDoBookingWithoutCustomerContactData = True; //
	vRec.HavePermissionToCreateCustomersWithoutTIN = True; //
	vRec.HavePermissionToEditInactiveReservations = False;
	vRec.HavePermissionToSkipBoardPlaceSetting = True; //
	vRec.HavePermissionToEditCompletedResourceReservations = False;
	vRec.HavePermissionToInputDiscountCardNumberManually = False;
	vRec.HavePermissionToUseClientDiscountCardWithAnyOtherClientHavingIt = False;
	vRec.HavePermissionToChargeExtraServicesOnCredit = True; //
	vRec.HavePermissionToSeeDataForAllCompanies = False;
	vRec.HavePermissionToTransferMoneyFromFoliosWithDebts = False;
	vRec.HavePermissionToChangeActivatedCards = False;
	vRec.HavePermissionToUseCityLedgerPaymentMethodForIndividualsFolios = False;
	vRec.HavePermissionToEditAllMessages = False;
	vRec.HavePermissionToCheckIfAdvancesClearingIsDone = False;
	vRec.HavePermissionToCreateReservationsInThePast = False;
	vRec.HavePermissionToEditInvoicesCreatedInTheCurrentAccountingPeriod = False;
	vRec.HavePermissionToEditInvoicesCreatedInThePastAccountingPeriods = False;
	vRec.HavePermissionToForbiddenCheckInForGuestsWithActiveAccommodation = False;
	vRec.HavePermissionToCloseOpenTasks = False;
	vRec.HavePermissionToUseDoNotChangeAvailabilityFlag = False;
	vRec.HavePermissionToAddManualBonusesOperation = False;
	vAdm.HavePermissionToManageBusinessBlocks = False;
	vAdm.HavePermissionToSetDeletionMarkForBusinessBlocks = False;
	
	vRec.Write();
	
	// ----HEAD OF THE PLACEMENT SERVICE-----
	vHPS = Catalogs.PermissionGroups.CreateItem();
	vHPS.Code = FNStr("en = 'HPS'; de = 'LDV'; ru = 'НСР'");
	vHPS.Description = FNStr("en = 'Head of the Placement Serv.';
							 |de = 'Leiterin des Vermittlungsdienstes';
							 |ru = 'Нач. службы размещения'");
	// Add payment methods and room statuses
	AddPaymentMethodsToPermissionGroup(vHPS.PaymentMethodsAllowed, vExceptArray);
	AddRoomStatusesToPermissionGroup(vHPS.RoomStatusesAllowed);
	
	vHPS.AllowedAnnulationDelayTime = 15;
	// Set roles
	vActiveRoles = New Array;
	vActiveRoles.Add(vRolesStructure.Get("General"));
	vActiveRoles.Add(vRolesStructure.Get("RightsToMergeCatalogItemsAndChangeHistory"));
	vActiveRoles.Add(vRolesStructure.Get("RightsToOpenExternalReportsAndDataProcessorsInteractively"));
	vActiveRoles.Add(vRolesStructure.Get("SubsystemCRM"));
	vActiveRoles.Add(vRolesStructure.Get("SubsystemDesktopAccess"));
	vActiveRoles.Add(vRolesStructure.Get("SubsystemFrontOffice"));
	vActiveRoles.Add(vRolesStructure.Get("SubsystemHouseKeeping"));
	vActiveRoles.Add(vRolesStructure.Get("SubsystemIntegration"));
	vActiveRoles.Add(vRolesStructure.Get("SubsystemInvoices"));
	vActiveRoles.Add(vRolesStructure.Get("SubsystemOrders"));
	vActiveRoles.Add(vRolesStructure.Get("SubsystemRatesAndServices"));
	vActiveRoles.Add(vRolesStructure.Get("SubsystemResources"));
	vActiveRoles.Add(vRolesStructure.Get("SubsystemRestaurant"));
	vActiveRoles.Add(vRolesStructure.Get("SubsystemTasks"));
	AddActiveRolesToPermissionGroup(vHPS.InfobaseUserRoles, vActiveRoles);
	
	vHPS.HavePermissionToAddManualDiscounts = True;
	vHPS.HavePermissionToAddManualPrices = True;
	vHPS.HavePermissionToAnnulateCashRegisterCheques = True;
	vHPS.HavePermissionToChangeCheckOutDateInDoorLockSystem = True;
	vHPS.HavePermissionToChangeFolioInFolioTransactions = True;
	vHPS.HavePermissionToChangeRoomStatuses = True;
	vHPS.HavePermissionToCheckCurrencyRatesActuality = False; //
	vHPS.HavePermissionToCheckInBasedOnInactiveReservations = True;
	vHPS.HavePermissionToCheckOutAccommodationsWithClientDebts = True;
	vHPS.HavePermissionToCheckOutAccommodationsWithCustomerDebts = True;
	vHPS.HavePermissionToChooseWorkstationOnProgramStartUp = False; //
	vHPS.HavePermissionToDeleteForeignerLogRecords = True;
	vHPS.HavePermissionToDoCashAndCreditCardPaymentsWithoutCashRegister = True;
	vHPS.HavePermissionToDoCheckInWithEmptyGuest = True;
	vHPS.HavePermissionToDoOverbooking = True;
	vHPS.HavePermissionToDoRoomQuotaOverbooking = True;
	vHPS.HavePermissionToDoRoomQuotaOversales = True;
	vHPS.HavePermissionToEditAccommodationDocumentNumberAndDate = True;
	vHPS.HavePermissionToEditClosedFolios = True;
	vHPS.HavePermissionToEditCheckedOutAccommodations = True;
	vHPS.HavePermissionToEditCheckInDateTimeInPast = True;
	vHPS.HavePermissionToUseReferenceHourAsDefaultCheckOutTime = True;
	vHPS.HavePermissionToEditCheckOutDateTime = True;
	vHPS.HavePermissionToSetCheckOutDateInThePast = True;
	vHPS.HavePermissionToEditClosedForEditDocuments = True;
	vHPS.HavePermissionToEditCloseOfCashRegisterDayDate = True;
	vHPS.HavePermissionToEditCustomer = True;
	vHPS.HavePermissionToEditGuestGroup = True;
	vHPS.HavePermissionToEditPostedCashIncomeOutcomeTransactions = True;
	vHPS.HavePermissionToEditPostedCloseOfCashRegisterDayDocuments = True;
	vHPS.HavePermissionToEditPostedFolioTransactions = True;
	vHPS.HavePermissionToStornoFolioCharges = True;
	vHPS.HavePermissionToReturnPayments = True;
	vHPS.HavePermissionToReturnBasedOnFolio = True;
	vHPS.HavePermissionToReturnCashDirectlyFromCashBox = True;
	vHPS.HavePermissionToEditPrintForms = False; //
	vHPS.HavePermissionToEditReservationDocumentNumberAndDate = True;
	vHPS.HavePermissionToEditReservations = True;
	vHPS.HavePermissionToSetDeletionMarkForReservations = True;
	vHPS.HavePermissionToEditRoomRateServices = True;
	vHPS.HavePermissionToEditServicePrices = True;
	vHPS.HavePermissionToIgnoreBlackListLimitations = True;
	vHPS.HavePermissionToIgnoreNumberOfGuestsPerRoomLimits = True;
	vHPS.HavePermissionToManuallySetCheckedOutAccommodationStatus = True;
	vHPS.HavePermissionToPrintCashRegisterXReport = True;
	vHPS.HavePermissionToPrintCashRegisterZReport = True;
	vHPS.HavePermissionToPrintCheckOutDateInTheForeignerNotificationFormFooter = True;
	vHPS.HavePermissionToRunAllDataProcessors = True;
	vHPS.HavePermissionToRunAllReports = True;
	vHPS.HavePermissionToSaveCreditCards = True;
	vHPS.HavePermissionToSignForeignerNotificationForm = True;
	vHPS.HavePermissionToSkipInputOfGuestAddress = True;
	vHPS.HavePermissionToSkipInputOfGuestIdentificationDocumentData = True;
	vHPS.HavePermissionToSkipInputOfGuestTripPurpose = True;
	vHPS.HavePermissionToTextEditClientAddresses = False; //
	vHPS.HavePermissionToTransferDepositsBetweenGuestGroups = False; //
	vHPS.HavePermissionToTransferDepositsBetweenGuestsOfOneGuestGroup = True;
	vHPS.HavePermissionToUseOccupiedRooms = True;
	vHPS.HavePermissionToViewAllCashRegisters = True;
	vHPS.HavePermissionToViewCreditCardsData = True;
	vHPS.HavePermissionToViewHotelOccupationStatistics = True;
	vHPS.HavePermissionToViewCustomerOperationalBalance = True;
	vHPS.HavePermissionToSetDeletionMarkForAccommodations = True;
	vHPS.HavePermissionToSetDeletionMarkForSetRoomBlocks = True;
	vHPS.HavePermissionToSetRoomBlocks = True;
	vHPS.HavePermissionToEditAccommodationCheckInDate = True;
	vHPS.HavePermissionToCheckInToRoomsWithForbiddenStatus = True;
	vHPS.HavePermissionToSetDoorLockSystemAuthorizations = True;
	vHPS.HavePermissionToCreateNewReservations = True;
	vHPS.HavePermissionToCreateNewAccommodations = True;
	vHPS.HavePermissionToEditAccommodations = True;
	vHPS.HavePermissionToIssueKeyCardsBasedOnReservations = True;
	vHPS.HavePermissionToCloseNewReservationWithoutSave = True;
	vHPS.HavePermissionToChangeCustomerInDocuments = True;
	vHPS.HavePermissionToEditCustomerFolioTransactions = True;
	vHPS.HavePermissionToSkipInputOfAccommodationMarketingCode = True;
	vHPS.HavePermissionToSkipInputOfAccommodationSourceOfBusiness = True;
	vHPS.HavePermissionToEditChargingRules = True;
	vHPS.HavePermissionToUseOccupiedResources = True;
	vHPS.HavePermissionToCreateNewResourceReservations = True;
	vHPS.HavePermissionToEditResourceReservationDocumentNumberAndDate = True;
	vHPS.HavePermissionToEditResourceReservations = True;
	vHPS.HavePermissionToSetDeletionMarkForResourceReservations = True;
	vHPS.HavePermissionToIssueKeyCardsForGuestsWithDebtsOnKeyValidToDate = True;
	vHPS.HavePermissionToSetZeroManualPriceForAccommodation = True;
	vHPS.HavePermissionToIssueHotelProducts = True;
	vHPS.HavePermissionToSetFixedPeriodForTheHotelProduct = True;
	vHPS.HavePermissionToSetFixedCostForTheHotelProduct = True;
	vHPS.HavePermissionToCheckOutOnExpectedCheckOutTime = False; //
	vHPS.HavePermissionToStopSaleRoomTypes = True;
	vHPS.HavePermissionToIgnoreStopSaleLimitations = True;
	vHPS.HavePermissionToManageRoomInventory = True;
	vHPS.HavePermissionToManageResources = True;
	vHPS.HavePermissionToManagePrices = True;
	vHPS.HavePermissionToPostPaymentsWithEmptyPaymentSections = True;
	vHPS.HavePermissionToUseVirtualRooms = True;
	vHPS.HavePermissionToAddCheckPointNumbersToTheCatalog = True;
	vHPS.HavePermissionToEditFolioDocumentForm = True;
	vHPS.HavePermissionToSkipInputOfClientType = True;
	vHPS.HavePermissionToStopSaleRooms = True;
	vHPS.HavePermissionToChargeIgnoringChargingRules = True;
	vHPS.HavePermissionToSeeAllMessages = True;
	vHPS.HavePermissionToSkipInputOfReservationTripPurpose = True;
	vHPS.HavePermissionToSkipInputOfReservationMarketingCode = True;
	vHPS.HavePermissionToSkipInputOfReservationSourceOfBusiness = True;
	vHPS.HavePermissionToSeePricesDifferentFromRoomRackRates = True;
	vHPS.HavePermissionToManageReportColumns = True;
	vHPS.HavePermissionToTakeFolioDebtDecisions = True;
	vHPS.HavePermissionToDoRoomTypeUpgrade = True;
	vHPS.HavePermissionToUseAnyRoomTypeForUpgrade = True;
	vHPS.HavePermissionToSkipInputOfReservationContactPerson = True;
	vHPS.HavePermissionToDoBookingWithoutRooms = True;
	vHPS.HavePermissionToManageHousekeeping = True;
	vHPS.HavePermissionToUsePreauthorisation = True;
	vHPS.HavePermissionToTransferPreauthorisations = True;
	vHPS.HavePermissionToCancelAccommodations = True;
	vHPS.HavePermissionToEditFoliosCreditLimit = True;
	vHPS.HavePermissionToEditExportedSettlements = False; //
	vHPS.HavePermissionToChooseClientTypeManually = True;
	vHPS.HavePermissionToEditCustomerAndGuestGroupManagers = True;
	vHPS.HavePermissionToCreateReservationsWithoutContactClientAndCustomerData = True;
	vHPS.HavePermissionToManageAllotments = True;
	vHPS.HavePermissionToIgnoreGuestAgeLimitations = True;
	vHPS.HavePermissionToIgnoreAccommodationTemplates = True;
	vHPS.HavePermissionToApproveRoomRates = True;
	vHPS.HavePermissionToMessagesDelivery = True;
	vHPS.HavePermissionToRecalculateInvoicesBeingAlreadyPaid = True;
	vHPS.HavePermissionToDoBookingWithoutCustomerContactData = True;
	vHPS.HavePermissionToCreateCustomersWithoutTIN = True;
	vHPS.HavePermissionToEditInactiveReservations = True;
	vHPS.HavePermissionToSkipBoardPlaceSetting = True;
	vHPS.HavePermissionToEditCompletedResourceReservations = False; //
	vHPS.HavePermissionToInputDiscountCardNumberManually = False; //
	vHPS.HavePermissionToUseClientDiscountCardWithAnyOtherClientHavingIt = False; //
	vHPS.HavePermissionToChargeExtraServicesOnCredit = True;
	vHPS.HavePermissionToSeeDataForAllCompanies = False; //
	vHPS.HavePermissionToTransferMoneyFromFoliosWithDebts = False; //
	vHPS.HavePermissionToChangeActivatedCards = False; //
	vHPS.HavePermissionToUseCityLedgerPaymentMethodForIndividualsFolios = False; //
	vHPS.HavePermissionToEditAllMessages = False; //
	vHPS.HavePermissionToCheckIfAdvancesClearingIsDone = False; //
	vHPS.HavePermissionToCreateReservationsInThePast = False; //
	vHPS.HavePermissionToEditInvoicesCreatedInTheCurrentAccountingPeriod = False; //
	vHPS.HavePermissionToEditInvoicesCreatedInThePastAccountingPeriods = False; //
	vHPS.HavePermissionToForbiddenCheckInForGuestsWithActiveAccommodation = False; //
	vHPS.HavePermissionToCloseOpenTasks = False; //
	vHPS.HavePermissionToUseDoNotChangeAvailabilityFlag = False; //
	vHPS.HavePermissionToAddManualBonusesOperation = False; //
	vHPS.HavePermissionToManageBusinessBlocks = True;
	vHPS.HavePermissionToSetDeletionMarkForBusinessBlocks = True;
	
	vHPS.Write();
	
	// ----ACCOUNTANT-----
	vAcc = Catalogs.PermissionGroups.CreateItem();
	vAcc.Code = FNStr("en = 'ACC'; de = 'BUC'; ru = 'БУХ'");
	vAcc.Description = FNStr("en = 'Accountant'; de = 'Buchhalter'; ru = 'Бухгалтер'");
	// Add payment methods and room statuses
	AddPaymentMethodsToPermissionGroup(vAcc.PaymentMethodsAllowed);
	
	vAcc.AllowedAnnulationDelayTime = 15;
	// Set roles
	vActiveRoles = New Array;
	vActiveRoles.Add(vRolesStructure.Get("Accountant"));
	vActiveRoles.Add(vRolesStructure.Get("RightsToOpenExternalReportsAndDataProcessorsInteractively"));
	vActiveRoles.Add(vRolesStructure.Get("SubsystemCRM"));
	vActiveRoles.Add(vRolesStructure.Get("SubsystemDesktopAccess"));
	vActiveRoles.Add(vRolesStructure.Get("SubsystemFrontOffice"));
	vActiveRoles.Add(vRolesStructure.Get("SubsystemInvoices"));
	vActiveRoles.Add(vRolesStructure.Get("SubsystemRatesAndServices"));
	vActiveRoles.Add(vRolesStructure.Get("SubsystemResources"));
	vActiveRoles.Add(vRolesStructure.Get("SubsystemTasks"));
	AddActiveRolesToPermissionGroup(vAcc.InfobaseUserRoles, vActiveRoles);
	
	vAcc.HavePermissionToAddManualDiscounts = False;
	vAcc.HavePermissionToAddManualPrices = False;
	vAcc.HavePermissionToAnnulateCashRegisterCheques = False;
	vAcc.HavePermissionToChangeCheckOutDateInDoorLockSystem = False;
	vAcc.HavePermissionToChangeFolioInFolioTransactions = False;
	vAcc.HavePermissionToChangeRoomStatuses = False;
	vAcc.HavePermissionToCheckCurrencyRatesActuality = False;
	vAcc.HavePermissionToCheckInBasedOnInactiveReservations = False;
	vAcc.HavePermissionToCheckOutAccommodationsWithClientDebts = False;
	vAcc.HavePermissionToCheckOutAccommodationsWithCustomerDebts = False;
	vAcc.HavePermissionToChooseWorkstationOnProgramStartUp = False;
	vAcc.HavePermissionToDeleteForeignerLogRecords = False;
	vAcc.HavePermissionToDoCashAndCreditCardPaymentsWithoutCashRegister = False;
	vAcc.HavePermissionToDoCheckInWithEmptyGuest = False;
	vAcc.HavePermissionToDoOverbooking = False;
	vAcc.HavePermissionToDoRoomQuotaOverbooking = False;
	vAcc.HavePermissionToDoRoomQuotaOversales = False;
	vAcc.HavePermissionToEditAccommodationDocumentNumberAndDate = False;
	vAcc.HavePermissionToEditClosedFolios = False;
	vAcc.HavePermissionToEditCheckedOutAccommodations = False;
	vAcc.HavePermissionToEditCheckInDateTimeInPast = False;
	vAcc.HavePermissionToUseReferenceHourAsDefaultCheckOutTime = False;
	vAcc.HavePermissionToEditCheckOutDateTime = False;
	vAcc.HavePermissionToSetCheckOutDateInThePast = False;
	vAcc.HavePermissionToEditClosedForEditDocuments = False;
	vAcc.HavePermissionToEditCloseOfCashRegisterDayDate = False;
	vAcc.HavePermissionToEditCustomer = False;
	vAcc.HavePermissionToEditGuestGroup = False;
	vAcc.HavePermissionToEditPostedCashIncomeOutcomeTransactions = False;
	vAcc.HavePermissionToEditPostedCloseOfCashRegisterDayDocuments = False;
	vAcc.HavePermissionToEditPostedFolioTransactions = False;
	vAcc.HavePermissionToStornoFolioCharges = False;
	vAcc.HavePermissionToReturnPayments = False;
	vAcc.HavePermissionToReturnBasedOnFolio = False;
	vAcc.HavePermissionToReturnCashDirectlyFromCashBox = False;
	vAcc.HavePermissionToEditPrintForms = False;
	vAcc.HavePermissionToEditReservationDocumentNumberAndDate = False;
	vAcc.HavePermissionToEditReservations = False;
	vAcc.HavePermissionToSetDeletionMarkForReservations = False;
	vAcc.HavePermissionToEditRoomRateServices = False;
	vAcc.HavePermissionToEditServicePrices = False;
	vAcc.HavePermissionToIgnoreBlackListLimitations = False;
	vAcc.HavePermissionToIgnoreNumberOfGuestsPerRoomLimits = False;
	vAcc.HavePermissionToManuallySetCheckedOutAccommodationStatus = False;
	vAcc.HavePermissionToPrintCashRegisterXReport = True; //
	vAcc.HavePermissionToPrintCashRegisterZReport = True; //
	vAcc.HavePermissionToPrintCheckOutDateInTheForeignerNotificationFormFooter = False;
	vAcc.HavePermissionToRunAllDataProcessors = False;
	vAcc.HavePermissionToRunAllReports = True; //
	vAcc.HavePermissionToSaveCreditCards = False;
	vAcc.HavePermissionToSignForeignerNotificationForm = False;
	vAcc.HavePermissionToSkipInputOfGuestAddress = False;
	vAcc.HavePermissionToSkipInputOfGuestIdentificationDocumentData = False;
	vAcc.HavePermissionToSkipInputOfGuestTripPurpose = False;
	vAcc.HavePermissionToTextEditClientAddresses = False;
	vAcc.HavePermissionToTransferDepositsBetweenGuestGroups = False;
	vAcc.HavePermissionToTransferDepositsBetweenGuestsOfOneGuestGroup = False;
	vAcc.HavePermissionToUseOccupiedRooms = False;
	vAcc.HavePermissionToViewAllCashRegisters = True; //
	vAcc.HavePermissionToViewCreditCardsData = False;
	vAcc.HavePermissionToViewHotelOccupationStatistics = False;
	vAcc.HavePermissionToViewCustomerOperationalBalance = True; //
	vAcc.HavePermissionToSetDeletionMarkForAccommodations = False;
	vAcc.HavePermissionToSetDeletionMarkForSetRoomBlocks = False;
	vAcc.HavePermissionToSetRoomBlocks = False;
	vAcc.HavePermissionToEditAccommodationCheckInDate = False;
	vAcc.HavePermissionToCheckInToRoomsWithForbiddenStatus = False;
	vAcc.HavePermissionToSetDoorLockSystemAuthorizations = False;
	vAcc.HavePermissionToCreateNewReservations = False;
	vAcc.HavePermissionToCreateNewAccommodations = False;
	vAcc.HavePermissionToEditAccommodations = False;
	vAcc.HavePermissionToIssueKeyCardsBasedOnReservations = False;
	vAcc.HavePermissionToCloseNewReservationWithoutSave = False;
	vAcc.HavePermissionToChangeCustomerInDocuments = False;
	vAcc.HavePermissionToEditCustomerFolioTransactions = False;
	vAcc.HavePermissionToSkipInputOfAccommodationMarketingCode = False;
	vAcc.HavePermissionToSkipInputOfAccommodationSourceOfBusiness = False;
	vAcc.HavePermissionToEditChargingRules = False;
	vAcc.HavePermissionToUseOccupiedResources = False;
	vAcc.HavePermissionToCreateNewResourceReservations = False;
	vAcc.HavePermissionToEditResourceReservationDocumentNumberAndDate = False;
	vAcc.HavePermissionToEditResourceReservations = False;
	vAcc.HavePermissionToSetDeletionMarkForResourceReservations = False;
	vAcc.HavePermissionToIssueKeyCardsForGuestsWithDebtsOnKeyValidToDate = False;
	vAcc.HavePermissionToSetZeroManualPriceForAccommodation = False;
	vAcc.HavePermissionToIssueHotelProducts = False;
	vAcc.HavePermissionToSetFixedPeriodForTheHotelProduct = False;
	vAcc.HavePermissionToSetFixedCostForTheHotelProduct = False;
	vAcc.HavePermissionToCheckOutOnExpectedCheckOutTime = False;
	vAcc.HavePermissionToStopSaleRoomTypes = False;
	vAcc.HavePermissionToIgnoreStopSaleLimitations = False;
	vAcc.HavePermissionToManageRoomInventory = False;
	vAcc.HavePermissionToManageResources = False;
	vAcc.HavePermissionToManagePrices = False;
	vAcc.HavePermissionToPostPaymentsWithEmptyPaymentSections = False;
	vAcc.HavePermissionToUseVirtualRooms = False;
	vAcc.HavePermissionToAddCheckPointNumbersToTheCatalog = False;
	vAcc.HavePermissionToEditFolioDocumentForm = False;
	vAcc.HavePermissionToSkipInputOfClientType = False;
	vAcc.HavePermissionToStopSaleRooms = False;
	vAcc.HavePermissionToChargeIgnoringChargingRules = False;
	vAcc.HavePermissionToSeeAllMessages = False;
	vAcc.HavePermissionToSkipInputOfReservationTripPurpose = False;
	vAcc.HavePermissionToSkipInputOfReservationMarketingCode = False;
	vAcc.HavePermissionToSkipInputOfReservationSourceOfBusiness = False;
	vAcc.HavePermissionToSeePricesDifferentFromRoomRackRates = False;
	vAcc.HavePermissionToManageReportColumns = False;
	vAcc.HavePermissionToTakeFolioDebtDecisions = True; //
	vAcc.HavePermissionToDoRoomTypeUpgrade = False;
	vAcc.HavePermissionToUseAnyRoomTypeForUpgrade = False;
	vAcc.HavePermissionToSkipInputOfReservationContactPerson = False;
	vAcc.HavePermissionToDoBookingWithoutRooms = False;
	vAcc.HavePermissionToManageHousekeeping = False;
	vAcc.HavePermissionToUsePreauthorisation = False;
	vAcc.HavePermissionToTransferPreauthorisations = False;
	vAcc.HavePermissionToCancelAccommodations = False;
	vAcc.HavePermissionToEditFoliosCreditLimit = True; //
	vAcc.HavePermissionToEditExportedSettlements = False;
	vAcc.HavePermissionToChooseClientTypeManually = True; //
	vAcc.HavePermissionToEditCustomerAndGuestGroupManagers = False;
	vAcc.HavePermissionToCreateReservationsWithoutContactClientAndCustomerData = False;
	vAcc.HavePermissionToManageAllotments = False;
	vAcc.HavePermissionToIgnoreGuestAgeLimitations = False;
	vAcc.HavePermissionToIgnoreAccommodationTemplates = True; //
	vAcc.HavePermissionToApproveRoomRates = True; //
	vAcc.HavePermissionToMessagesDelivery = False;
	vAcc.HavePermissionToRecalculateInvoicesBeingAlreadyPaid = True; //
	vAcc.HavePermissionToDoBookingWithoutCustomerContactData = False;
	vAcc.HavePermissionToCreateCustomersWithoutTIN = True; //
	vAcc.HavePermissionToEditInactiveReservations = False;
	vAcc.HavePermissionToSkipBoardPlaceSetting = True; //
	vAcc.HavePermissionToEditCompletedResourceReservations = False;
	vAcc.HavePermissionToInputDiscountCardNumberManually = False;
	vAcc.HavePermissionToUseClientDiscountCardWithAnyOtherClientHavingIt = False;
	vAcc.HavePermissionToChargeExtraServicesOnCredit = True; //
	vAcc.HavePermissionToSeeDataForAllCompanies = False;
	vAcc.HavePermissionToTransferMoneyFromFoliosWithDebts = False;
	vAcc.HavePermissionToChangeActivatedCards = False;
	vAcc.HavePermissionToUseCityLedgerPaymentMethodForIndividualsFolios = False;
	vAcc.HavePermissionToEditAllMessages = False;
	vAcc.HavePermissionToCheckIfAdvancesClearingIsDone = False;
	vAcc.HavePermissionToCreateReservationsInThePast = False;
	vAcc.HavePermissionToEditInvoicesCreatedInTheCurrentAccountingPeriod = False;
	vAcc.HavePermissionToEditInvoicesCreatedInThePastAccountingPeriods = False;
	vAcc.HavePermissionToForbiddenCheckInForGuestsWithActiveAccommodation = False;
	vAcc.HavePermissionToCloseOpenTasks = False;
	vAcc.HavePermissionToUseDoNotChangeAvailabilityFlag = False;
	vAcc.HavePermissionToAddManualBonusesOperation = False;
	vAcc.HavePermissionToManageBusinessBlocks = False;
	vAcc.HavePermissionToSetDeletionMarkForBusinessBlocks = False;
	
	vAcc.Write();
	
	// ----RESERVATION-----
	vReserv = Catalogs.PermissionGroups.CreateItem();
	vReserv.Code = FNStr("en = 'RES'; de = 'RES'; ru = 'БРН'");
	vReserv.Description = FNStr("en = 'Reservation'; de = 'Reservierung'; ru = 'Бронирование'");
	// Add payment methods
	vExceptArray.Clear();
	vExceptArray.Add(30);
	vExceptArray.Add(40);
	vExceptArray.Add(50);
	AddPaymentMethodsToPermissionGroup(vReserv.PaymentMethodsAllowed);
	
	vReserv.AllowedAnnulationDelayTime = 15;
	// Set roles
	vActiveRoles = New Array;
	vActiveRoles.Add(vRolesStructure.Get("General"));
	vActiveRoles.Add(vRolesStructure.Get("RightsToMergeCatalogItemsAndChangeHistory"));
	vActiveRoles.Add(vRolesStructure.Get("RightsToOpenExternalReportsAndDataProcessorsInteractively"));
	vActiveRoles.Add(vRolesStructure.Get("SubsystemFrontOffice"));
	vActiveRoles.Add(vRolesStructure.Get("SubsystemInvoices"));
	vActiveRoles.Add(vRolesStructure.Get("SubsystemTasks"));
	AddActiveRolesToPermissionGroup(vReserv.InfobaseUserRoles, vActiveRoles);
	
	vReserv.HavePermissionToAddManualDiscounts = False;
	vReserv.HavePermissionToAddManualPrices = False;
	vReserv.HavePermissionToAnnulateCashRegisterCheques = False;
	vReserv.HavePermissionToChangeCheckOutDateInDoorLockSystem = False;
	vReserv.HavePermissionToChangeFolioInFolioTransactions = False;
	vReserv.HavePermissionToChangeRoomStatuses = False;
	vReserv.HavePermissionToCheckCurrencyRatesActuality = False;
	vReserv.HavePermissionToCheckInBasedOnInactiveReservations = False;
	vReserv.HavePermissionToCheckOutAccommodationsWithClientDebts = False;
	vReserv.HavePermissionToCheckOutAccommodationsWithCustomerDebts = False;
	vReserv.HavePermissionToChooseWorkstationOnProgramStartUp = False;
	vReserv.HavePermissionToDeleteForeignerLogRecords = False;
	vReserv.HavePermissionToDoCashAndCreditCardPaymentsWithoutCashRegister = False;
	vReserv.HavePermissionToDoCheckInWithEmptyGuest = False;
	vReserv.HavePermissionToDoOverbooking = False;
	vReserv.HavePermissionToDoRoomQuotaOverbooking = False;
	vReserv.HavePermissionToDoRoomQuotaOversales = False;
	vReserv.HavePermissionToEditAccommodationDocumentNumberAndDate = False;
	vReserv.HavePermissionToEditClosedFolios = False;
	vReserv.HavePermissionToEditCheckedOutAccommodations = False;
	vReserv.HavePermissionToEditCheckInDateTimeInPast = False;
	vReserv.HavePermissionToUseReferenceHourAsDefaultCheckOutTime = False;
	vReserv.HavePermissionToEditCheckOutDateTime = False;
	vReserv.HavePermissionToSetCheckOutDateInThePast = False;
	vReserv.HavePermissionToEditClosedForEditDocuments = False;
	vReserv.HavePermissionToEditCloseOfCashRegisterDayDate = False;
	vReserv.HavePermissionToEditCustomer = True; //
	vReserv.HavePermissionToEditGuestGroup = True; //
	vReserv.HavePermissionToEditPostedCashIncomeOutcomeTransactions = False;
	vReserv.HavePermissionToEditPostedCloseOfCashRegisterDayDocuments = False;
	vReserv.HavePermissionToEditPostedFolioTransactions = False;
	vReserv.HavePermissionToStornoFolioCharges = True; //
	vReserv.HavePermissionToReturnPayments = False;
	vReserv.HavePermissionToReturnBasedOnFolio = False;
	vReserv.HavePermissionToReturnCashDirectlyFromCashBox = False;
	vReserv.HavePermissionToEditPrintForms = False;
	vReserv.HavePermissionToEditReservationDocumentNumberAndDate = False;
	vReserv.HavePermissionToEditReservations = True; //
	vReserv.HavePermissionToSetDeletionMarkForReservations = False;
	vReserv.HavePermissionToEditRoomRateServices = False;
	vReserv.HavePermissionToEditServicePrices = False;
	vReserv.HavePermissionToIgnoreBlackListLimitations = False;
	vReserv.HavePermissionToIgnoreNumberOfGuestsPerRoomLimits = True; //
	vReserv.HavePermissionToManuallySetCheckedOutAccommodationStatus = False;
	vReserv.HavePermissionToPrintCashRegisterXReport = False;
	vReserv.HavePermissionToPrintCashRegisterZReport = False;
	vReserv.HavePermissionToPrintCheckOutDateInTheForeignerNotificationFormFooter = False;
	vReserv.HavePermissionToRunAllDataProcessors = False;
	vReserv.HavePermissionToRunAllReports = True; //
	vReserv.HavePermissionToSaveCreditCards = False;
	vReserv.HavePermissionToSignForeignerNotificationForm = False;
	vReserv.HavePermissionToSkipInputOfGuestAddress = True; //
	vReserv.HavePermissionToSkipInputOfGuestIdentificationDocumentData = True; //
	vReserv.HavePermissionToSkipInputOfGuestTripPurpose = True; //
	vReserv.HavePermissionToTextEditClientAddresses = False;
	vReserv.HavePermissionToTransferDepositsBetweenGuestGroups = False;
	vReserv.HavePermissionToTransferDepositsBetweenGuestsOfOneGuestGroup = True; //
	vReserv.HavePermissionToUseOccupiedRooms = False;
	vReserv.HavePermissionToViewAllCashRegisters = False;
	vReserv.HavePermissionToViewCreditCardsData = False;
	vReserv.HavePermissionToViewHotelOccupationStatistics = True; //
	vReserv.HavePermissionToViewCustomerOperationalBalance = True; //
	vReserv.HavePermissionToSetDeletionMarkForAccommodations = False;
	vReserv.HavePermissionToSetDeletionMarkForSetRoomBlocks = False;
	vReserv.HavePermissionToSetRoomBlocks = False;
	vReserv.HavePermissionToEditAccommodationCheckInDate = False;
	vReserv.HavePermissionToCheckInToRoomsWithForbiddenStatus = False;
	vReserv.HavePermissionToSetDoorLockSystemAuthorizations = False;
	vReserv.HavePermissionToCreateNewReservations = True; //
	vReserv.HavePermissionToCreateNewAccommodations = False;
	vReserv.HavePermissionToEditAccommodations = False;
	vReserv.HavePermissionToIssueKeyCardsBasedOnReservations = False;
	vReserv.HavePermissionToCloseNewReservationWithoutSave = True; //
	vReserv.HavePermissionToChangeCustomerInDocuments = True; //
	vReserv.HavePermissionToEditCustomerFolioTransactions = True; //
	vReserv.HavePermissionToSkipInputOfAccommodationMarketingCode = True; //
	vReserv.HavePermissionToSkipInputOfAccommodationSourceOfBusiness = True; //
	vReserv.HavePermissionToEditChargingRules = True; //
	vReserv.HavePermissionToUseOccupiedResources = False;
	vReserv.HavePermissionToCreateNewResourceReservations = True; //
	vReserv.HavePermissionToEditResourceReservationDocumentNumberAndDate = False;
	vReserv.HavePermissionToEditResourceReservations = True; //
	vReserv.HavePermissionToSetDeletionMarkForResourceReservations = False;
	vReserv.HavePermissionToIssueKeyCardsForGuestsWithDebtsOnKeyValidToDate = False;
	vReserv.HavePermissionToSetZeroManualPriceForAccommodation = False;
	vReserv.HavePermissionToIssueHotelProducts = True; //
	vReserv.HavePermissionToSetFixedPeriodForTheHotelProduct = False;
	vReserv.HavePermissionToSetFixedCostForTheHotelProduct = True; //
	vReserv.HavePermissionToCheckOutOnExpectedCheckOutTime = False;
	vReserv.HavePermissionToStopSaleRoomTypes = False;
	vReserv.HavePermissionToIgnoreStopSaleLimitations = False;
	vReserv.HavePermissionToManageRoomInventory = False;
	vReserv.HavePermissionToManageResources = False;
	vReserv.HavePermissionToManagePrices = False;
	vReserv.HavePermissionToPostPaymentsWithEmptyPaymentSections = True; //
	vReserv.HavePermissionToUseVirtualRooms = True; //
	vReserv.HavePermissionToAddCheckPointNumbersToTheCatalog = True; //
	vReserv.HavePermissionToEditFolioDocumentForm = False;
	vReserv.HavePermissionToSkipInputOfClientType = True; //
	vReserv.HavePermissionToStopSaleRooms = False;
	vReserv.HavePermissionToChargeIgnoringChargingRules = True; //
	vReserv.HavePermissionToSeeAllMessages = False;
	vReserv.HavePermissionToSkipInputOfReservationTripPurpose = True; //
	vReserv.HavePermissionToSkipInputOfReservationMarketingCode = True; //
	vReserv.HavePermissionToSkipInputOfReservationSourceOfBusiness = True; //
	vReserv.HavePermissionToSeePricesDifferentFromRoomRackRates = True; //
	vReserv.HavePermissionToManageReportColumns = True; //
	vReserv.HavePermissionToTakeFolioDebtDecisions = False;
	vReserv.HavePermissionToDoRoomTypeUpgrade = True; //
	vReserv.HavePermissionToUseAnyRoomTypeForUpgrade = False;
	vReserv.HavePermissionToSkipInputOfReservationContactPerson = True; //
	vReserv.HavePermissionToDoBookingWithoutRooms = True; // 
	vReserv.HavePermissionToManageHousekeeping = False;
	vReserv.HavePermissionToUsePreauthorisation = True; //
	vReserv.HavePermissionToTransferPreauthorisations = True; //
	vReserv.HavePermissionToCancelAccommodations = False;
	vReserv.HavePermissionToEditFoliosCreditLimit = False;
	vReserv.HavePermissionToEditExportedSettlements = False;
	vReserv.HavePermissionToChooseClientTypeManually = True; //
	vReserv.HavePermissionToEditCustomerAndGuestGroupManagers = False;
	vReserv.HavePermissionToCreateReservationsWithoutContactClientAndCustomerData = False;
	vReserv.HavePermissionToManageAllotments = False;
	vReserv.HavePermissionToIgnoreGuestAgeLimitations = False;
	vReserv.HavePermissionToIgnoreAccommodationTemplates = True; //
	vReserv.HavePermissionToApproveRoomRates = False;
	vReserv.HavePermissionToMessagesDelivery = False;
	vReserv.HavePermissionToRecalculateInvoicesBeingAlreadyPaid = False;
	vReserv.HavePermissionToDoBookingWithoutCustomerContactData = True; //
	vReserv.HavePermissionToCreateCustomersWithoutTIN = True; //
	vReserv.HavePermissionToEditInactiveReservations = True; //
	vReserv.HavePermissionToSkipBoardPlaceSetting = True; //
	vReserv.HavePermissionToEditCompletedResourceReservations = False;
	vReserv.HavePermissionToInputDiscountCardNumberManually = False;
	vReserv.HavePermissionToUseClientDiscountCardWithAnyOtherClientHavingIt = False;
	vReserv.HavePermissionToChargeExtraServicesOnCredit = True; //
	vReserv.HavePermissionToSeeDataForAllCompanies = False;
	vReserv.HavePermissionToTransferMoneyFromFoliosWithDebts = False;
	vReserv.HavePermissionToChangeActivatedCards = False;
	vReserv.HavePermissionToUseCityLedgerPaymentMethodForIndividualsFolios = False;
	vReserv.HavePermissionToEditAllMessages = False;
	vReserv.HavePermissionToCheckIfAdvancesClearingIsDone = False;
	vReserv.HavePermissionToCreateReservationsInThePast = False;
	vReserv.HavePermissionToEditInvoicesCreatedInTheCurrentAccountingPeriod = False;
	vReserv.HavePermissionToEditInvoicesCreatedInThePastAccountingPeriods = False;
	vReserv.HavePermissionToForbiddenCheckInForGuestsWithActiveAccommodation = False;
	vReserv.HavePermissionToCloseOpenTasks = False;
	vReserv.HavePermissionToUseDoNotChangeAvailabilityFlag = False;
	vReserv.HavePermissionToAddManualBonusesOperation = False;
	vReserv.HavePermissionToManageBusinessBlocks = True;
	vReserv.HavePermissionToSetDeletionMarkForBusinessBlocks = False;
	
	vReserv.Write();
	
	// -----SUPERVIZOR OF THE ROOM FUND-----
	vSup = Catalogs.PermissionGroups.CreateItem();
	vSup.Code = FNStr("en = 'SRF'; de = 'BDZ'; ru = 'СНФ'");
	vSup.Description = FNStr("en = 'Supervisor of the room fund';
							 |de = 'Betreuer des Zimmerfonds';
							 |ru = 'Супервайзер номерного фонда'");
	// Add room statuses
	AddRoomStatusesToPermissionGroup(vSup.RoomStatusesAllowed);
	
	vSup.AllowedAnnulationDelayTime = 15;
	// Set roles
	vActiveRoles = New Array;
	vActiveRoles.Add(vRolesStructure.Get("General"));
	vActiveRoles.Add(vRolesStructure.Get("SubsystemHousekeeping"));
	vActiveRoles.Add(vRolesStructure.Get("SubsystemTasks"));
	AddActiveRolesToPermissionGroup(vSup.InfobaseUserRoles, vActiveRoles);
	
	vSup.HavePermissionToAddManualDiscounts = False;
	vSup.HavePermissionToAddManualPrices = False;
	vSup.HavePermissionToAnnulateCashRegisterCheques = False;
	vSup.HavePermissionToChangeCheckOutDateInDoorLockSystem = False;
	vSup.HavePermissionToChangeFolioInFolioTransactions = False;
	vSup.HavePermissionToChangeRoomStatuses = True; //
	vSup.HavePermissionToCheckCurrencyRatesActuality = False;
	vSup.HavePermissionToCheckInBasedOnInactiveReservations = False;
	vSup.HavePermissionToCheckOutAccommodationsWithClientDebts = False;
	vSup.HavePermissionToCheckOutAccommodationsWithCustomerDebts = False;
	vSup.HavePermissionToChooseWorkstationOnProgramStartUp = False;
	vSup.HavePermissionToDeleteForeignerLogRecords = False;
	vSup.HavePermissionToDoCashAndCreditCardPaymentsWithoutCashRegister = False;
	vSup.HavePermissionToDoCheckInWithEmptyGuest = False;
	vSup.HavePermissionToDoOverbooking = False;
	vSup.HavePermissionToDoRoomQuotaOverbooking = False;
	vSup.HavePermissionToDoRoomQuotaOversales = False;
	vSup.HavePermissionToEditAccommodationDocumentNumberAndDate = False;
	vSup.HavePermissionToEditClosedFolios = False;
	vSup.HavePermissionToEditCheckedOutAccommodations = False;
	vSup.HavePermissionToEditCheckInDateTimeInPast = False;
	vSup.HavePermissionToUseReferenceHourAsDefaultCheckOutTime = False;
	vSup.HavePermissionToEditCheckOutDateTime = False;
	vSup.HavePermissionToSetCheckOutDateInThePast = False;
	vSup.HavePermissionToEditClosedForEditDocuments = False;
	vSup.HavePermissionToEditCloseOfCashRegisterDayDate = False;
	vSup.HavePermissionToEditCustomer = False;
	vSup.HavePermissionToEditGuestGroup = False;
	vSup.HavePermissionToEditPostedCashIncomeOutcomeTransactions = False;
	vSup.HavePermissionToEditPostedCloseOfCashRegisterDayDocuments = False;
	vSup.HavePermissionToEditPostedFolioTransactions = False;
	vSup.HavePermissionToStornoFolioCharges = False;
	vSup.HavePermissionToReturnPayments = False;
	vSup.HavePermissionToReturnBasedOnFolio = False;
	vSup.HavePermissionToReturnCashDirectlyFromCashBox = False;
	vSup.HavePermissionToEditPrintForms = False;
	vSup.HavePermissionToEditReservationDocumentNumberAndDate = False;
	vSup.HavePermissionToEditReservations = False;
	vSup.HavePermissionToSetDeletionMarkForReservations = False;
	vSup.HavePermissionToEditRoomRateServices = False;
	vSup.HavePermissionToEditServicePrices = False;
	vSup.HavePermissionToIgnoreBlackListLimitations = False;
	vSup.HavePermissionToIgnoreNumberOfGuestsPerRoomLimits = False;
	vSup.HavePermissionToManuallySetCheckedOutAccommodationStatus = False;
	vSup.HavePermissionToPrintCashRegisterXReport = False;
	vSup.HavePermissionToPrintCashRegisterZReport = False;
	vSup.HavePermissionToPrintCheckOutDateInTheForeignerNotificationFormFooter = False;
	vSup.HavePermissionToRunAllDataProcessors = False;
	vSup.HavePermissionToRunAllReports = True; //
	vSup.HavePermissionToSaveCreditCards = False;
	vSup.HavePermissionToSignForeignerNotificationForm = False;
	vSup.HavePermissionToSkipInputOfGuestAddress = False;
	vSup.HavePermissionToSkipInputOfGuestIdentificationDocumentData = False;
	vSup.HavePermissionToSkipInputOfGuestTripPurpose = False;
	vSup.HavePermissionToTextEditClientAddresses = False;
	vSup.HavePermissionToTransferDepositsBetweenGuestGroups = False;
	vSup.HavePermissionToTransferDepositsBetweenGuestsOfOneGuestGroup = False;
	vSup.HavePermissionToUseOccupiedRooms = False;
	vSup.HavePermissionToViewAllCashRegisters = False;
	vSup.HavePermissionToViewCreditCardsData = False;
	vSup.HavePermissionToViewHotelOccupationStatistics = False;
	vSup.HavePermissionToViewCustomerOperationalBalance = False;
	vSup.HavePermissionToSetDeletionMarkForAccommodations = False;
	vSup.HavePermissionToSetDeletionMarkForSetRoomBlocks = True; //
	vSup.HavePermissionToSetRoomBlocks = True; //
	vSup.HavePermissionToEditAccommodationCheckInDate = False;
	vSup.HavePermissionToCheckInToRoomsWithForbiddenStatus = False;
	vSup.HavePermissionToSetDoorLockSystemAuthorizations = False;
	vSup.HavePermissionToCreateNewReservations = False;
	vSup.HavePermissionToCreateNewAccommodations = False;
	vSup.HavePermissionToEditAccommodations = False;
	vSup.HavePermissionToIssueKeyCardsBasedOnReservations = False;
	vSup.HavePermissionToCloseNewReservationWithoutSave = False;
	vSup.HavePermissionToChangeCustomerInDocuments = False;
	vSup.HavePermissionToEditCustomerFolioTransactions = False;
	vSup.HavePermissionToSkipInputOfAccommodationMarketingCode = False;
	vSup.HavePermissionToSkipInputOfAccommodationSourceOfBusiness = False;
	vSup.HavePermissionToEditChargingRules = False;
	vSup.HavePermissionToUseOccupiedResources = False;
	vSup.HavePermissionToCreateNewResourceReservations = False;
	vSup.HavePermissionToEditResourceReservationDocumentNumberAndDate = False;
	vSup.HavePermissionToEditResourceReservations = False;
	vSup.HavePermissionToSetDeletionMarkForResourceReservations = False;
	vSup.HavePermissionToIssueKeyCardsForGuestsWithDebtsOnKeyValidToDate = False;
	vSup.HavePermissionToSetZeroManualPriceForAccommodation = False;
	vSup.HavePermissionToIssueHotelProducts = False;
	vSup.HavePermissionToSetFixedPeriodForTheHotelProduct = False;
	vSup.HavePermissionToSetFixedCostForTheHotelProduct = False;
	vSup.HavePermissionToCheckOutOnExpectedCheckOutTime = False;
	vSup.HavePermissionToStopSaleRoomTypes = False;
	vSup.HavePermissionToIgnoreStopSaleLimitations = False;
	vSup.HavePermissionToManageRoomInventory = False;
	vSup.HavePermissionToManageResources = False;
	vSup.HavePermissionToManagePrices = False;
	vSup.HavePermissionToPostPaymentsWithEmptyPaymentSections = False;
	vSup.HavePermissionToUseVirtualRooms = False;
	vSup.HavePermissionToAddCheckPointNumbersToTheCatalog = False;
	vSup.HavePermissionToEditFolioDocumentForm = False;
	vSup.HavePermissionToSkipInputOfClientType = False;
	vSup.HavePermissionToStopSaleRooms = False;
	vSup.HavePermissionToChargeIgnoringChargingRules = False;
	vSup.HavePermissionToSeeAllMessages = False;
	vSup.HavePermissionToSkipInputOfReservationTripPurpose = False;
	vSup.HavePermissionToSkipInputOfReservationMarketingCode = False;
	vSup.HavePermissionToSkipInputOfReservationSourceOfBusiness = False;
	vSup.HavePermissionToSeePricesDifferentFromRoomRackRates = False;
	vSup.HavePermissionToManageReportColumns = False;
	vSup.HavePermissionToTakeFolioDebtDecisions = False;
	vSup.HavePermissionToDoRoomTypeUpgrade = False;
	vSup.HavePermissionToUseAnyRoomTypeForUpgrade = False;
	vSup.HavePermissionToSkipInputOfReservationContactPerson = False;
	vSup.HavePermissionToDoBookingWithoutRooms = False;
	vSup.HavePermissionToManageHousekeeping = False;
	vSup.HavePermissionToUsePreauthorisation = False;
	vSup.HavePermissionToTransferPreauthorisations = False;
	vSup.HavePermissionToCancelAccommodations = False;
	vSup.HavePermissionToEditFoliosCreditLimit = False;
	vSup.HavePermissionToEditExportedSettlements = False;
	vSup.HavePermissionToChooseClientTypeManually = False;
	vSup.HavePermissionToEditCustomerAndGuestGroupManagers = False;
	vSup.HavePermissionToCreateReservationsWithoutContactClientAndCustomerData = False;
	vSup.HavePermissionToManageAllotments = False;
	vSup.HavePermissionToIgnoreGuestAgeLimitations = False;
	vSup.HavePermissionToIgnoreAccommodationTemplates = True; //
	vSup.HavePermissionToApproveRoomRates = False;
	vSup.HavePermissionToMessagesDelivery = False;
	vSup.HavePermissionToRecalculateInvoicesBeingAlreadyPaid = False;
	vSup.HavePermissionToDoBookingWithoutCustomerContactData = False;
	vSup.HavePermissionToCreateCustomersWithoutTIN = False;
	vSup.HavePermissionToEditInactiveReservations = False;
	vSup.HavePermissionToSkipBoardPlaceSetting = True; //
	vSup.HavePermissionToEditCompletedResourceReservations = False;
	vSup.HavePermissionToInputDiscountCardNumberManually = False;
	vSup.HavePermissionToUseClientDiscountCardWithAnyOtherClientHavingIt = False;
	vSup.HavePermissionToChargeExtraServicesOnCredit = True; //
	vSup.HavePermissionToSeeDataForAllCompanies = False;
	vSup.HavePermissionToTransferMoneyFromFoliosWithDebts = False;
	vSup.HavePermissionToChangeActivatedCards = False;
	vSup.HavePermissionToUseCityLedgerPaymentMethodForIndividualsFolios = False;
	vSup.HavePermissionToEditAllMessages = False;
	vSup.HavePermissionToCheckIfAdvancesClearingIsDone = False;
	vSup.HavePermissionToCreateReservationsInThePast = False;
	vSup.HavePermissionToEditInvoicesCreatedInTheCurrentAccountingPeriod = False;
	vSup.HavePermissionToEditInvoicesCreatedInThePastAccountingPeriods = False;
	vSup.HavePermissionToForbiddenCheckInForGuestsWithActiveAccommodation = False;
	vSup.HavePermissionToCloseOpenTasks = False;
	vSup.HavePermissionToUseDoNotChangeAvailabilityFlag = False;
	vSup.HavePermissionToAddManualBonusesOperation = False;
	vSup.HavePermissionToManageBusinessBlocks = False;
	vSup.HavePermissionToSetDeletionMarkForBusinessBlocks = False;
	
	vSup.Write();
	
EndProcedure // CreatePermissionGroups

// --------------------------------------------------------------------------------
Procedure AddPaymentMethodsToPermissionGroup(pPaymentMethodsAllowed, pExceptArray = Undefined)

	If pExceptArray = Undefined Then
		vExceptArray = New Array;
	Else
		vExceptArray = pExceptArray;
	EndIf;
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	PaymentMethods.Ref AS Ref
		|FROM
		|	Catalog.PaymentMethods AS PaymentMethods
		|WHERE
		|	PaymentMethods.PredefinedDataName = """"
		|	AND NOT PaymentMethods.SortCode IN (&qExceptArray)";
	
	vQuery.SetParameter("qExceptArray", vExceptArray);
	vQueryResult = vQuery.Execute();
	
	vSelectionDetailRecords = vQueryResult.Select();
	
	While vSelectionDetailRecords.Next() Do
		vNewRow = pPaymentMethodsAllowed.Add();
		vNewRow.PaymentMethod = vSelectionDetailRecords.Ref;
	EndDo;
	
EndProcedure // AddPaymentMethodsToPermissionGroup

// --------------------------------------------------------------------------------
Procedure AddRoomStatusesToPermissionGroup(pRoomStatusesAllowed)
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	RoomStatuses.Ref AS Ref
		|FROM
		|	Catalog.RoomStatuses AS RoomStatuses";
	
	vQueryResult = vQuery.Execute();
	
	vSelectionDetailRecords = vQueryResult.Select();
	
	While vSelectionDetailRecords.Next() Do
		vNewRow = pRoomStatusesAllowed.Add();
		vNewRow.RoomStatus = vSelectionDetailRecords.Ref;
	EndDo;
	
EndProcedure // AddRoomStatusesToPermissionGroup

// --------------------------------------------------------------------------------
Procedure AddActiveRolesToPermissionGroup(pInfobaseUserRoles, pActiveRoles)
	
	For Each vRole In pActiveRoles Do
		If vRole <> Undefined Then
			vNewRow = pInfobaseUserRoles.Add();
			vNewRow.Role = vRole.Name;
		EndIf;
	EndDo;

EndProcedure // AddActiveRolesToPermissionGroup

// --------------------------------------------------------------------------------
Procedure CreateFromTemplate(pObjectName)
	
	BeginTransaction();
	Try
		vCatalogName = pObjectName + "s";
		
		vTempFileName = GetTempFileName("xml");
		vBinaryData = ThisObject.GetTemplate(vCatalogName + "XML");
		vBinaryData.Write(vTempFileName);
		
		vQry = New Query();
		vQry.Text = StrTemplate( 
					"SELECT
					|	%1.Ref AS Ref
					|FROM
					|	Catalog.%1 AS %1
					|
					|ORDER BY
					|	%1.IsFolder DESC,
					|	%1.Code", vCatalogName);
		vResult = vQry.Execute().Unload();
		For Each vRow In vResult Do
			vObj = vRow.Ref.GetObject();
			If vObj <> Undefined Then
				vObj.Delete();
			EndIf;
		EndDo;
		
		vXMLReader = New XMLReader();
		vXMLReader.OpenFile(vTempFileName);
		While vXMLReader.Read() Do
			If vXMLReader.NodeType = XMLNodeType.StartElement Then
				If vXMLReader.Name = "htl:" + pObjectName + "Object" Then
					vLanguageCode = "";
					If pObjectName = "ObjectFormAction" Or pObjectName = "ObjectPrintingForm" Then
						While vXMLReader.ReadAttribute() Do
							If vXMLReader.Name = "htl:languageCode" Then
								vLanguageCode = vXMLReader.Value;
								Break;
							EndIf;
						EndDo;
					EndIf;
					vXMLReader.Read();
					vObj = ReadXML(vXMLReader);
					If ValueIsFilled(vLanguageCode) Then
						vObj.Language = Catalogs.Languages.FindByCode(vLanguageCode);
					EndIf;
					vObj.Write();
				EndIf;
			EndIf;
		EndDo;
		vXMLReader.Close();
		DeleteFiles(vTempFileName);

		CommitTransaction();
	Except
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		vErrorInfo = ErrorInfo();
		
		Raise cmGetRootErrorDescription(vErrorInfo);
	EndTry;

EndProcedure // CreateFromTemplate

#EndRegion