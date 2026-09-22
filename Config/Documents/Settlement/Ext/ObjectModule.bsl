
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf; 
EndProcedure // OnWrite

// -----------------------------------------------------------------------------
Procedure Posting(pCancel, pMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// Check payment section and VAT
	If ValueIsFilled(Company) And Company.SplitSettllementsByPaymentSections Then
		If Not ValueIsFilled(PaymentSection) Then
			If Services.Count() > 0 Then
				vSrvRow = Services.Get(0);
				If ValueIsFilled(vSrvRow.Service) Then
					PaymentSection = vSrvRow.Service.PaymentSection;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(Company) And Company.SplitSettllementsByVATRate Then
		If Not ValueIsFilled(VATRate) Then
			If Services.Count() > 0 Then
				vSrvRow = Services.Get(0);
				VATRate = vSrvRow.VATRate;
			EndIf;
		EndIf;
	EndIf;
	
	// Recalculate settlement totals
	pmCalculateTotals();
	
	// Get table of document services
	vAllFoliosList = New ValueList();
	vNotSortedServices = New ValueTable();
	vInvoiceServices = GetInvoiceServices(vAllFoliosList, vNotSortedServices);
	
	// Update services folio and parent doc
	For Each vServicesRow In Services Do
		vNotSortedServicesRow = vNotSortedServices.Get(Services.IndexOf(vServicesRow));
		If ValueIsFilled(vServicesRow.Charge) And vServicesRow.Charge = vNotSortedServicesRow.Charge Then
			If vServicesRow.Folio <> vNotSortedServicesRow.ChargeFolio Then
				vServicesRow.Folio = vNotSortedServicesRow.ChargeFolio;
			EndIf;
			If vServicesRow.FolioCurrency <> vNotSortedServicesRow.ChargeFolioCurrency Then
				vServicesRow.FolioCurrency = vNotSortedServicesRow.ChargeFolioCurrency;
			EndIf;
			If vServicesRow.ParentDoc <> vNotSortedServicesRow.ChargeParentDoc Then
				vServicesRow.ParentDoc = vNotSortedServicesRow.ChargeParentDoc;
			EndIf;
		EndIf;
	EndDo;
	
	// Save changes if any
	If Modified() Then
		Write(DocumentWriteMode.Write);
	EndIf;
	
	// 1. Post to Accounts and Payments
	vBalancedFoliosList = New ValueList();
	pmPostToAccountsAndPayments(vBalancedFoliosList);
	
	// 2. Post to CurrentAccountsReceivable
	PostToCurrentAccountsReceivable(vInvoiceServices);
	
	// 3. Post to AccountsReceivable
	PostToAccountsReceivable(vInvoiceServices);
	
	// 4. Post to Customer accounts
	PostToCustomerAccounts(vInvoiceServices, vAllFoliosList, vBalancedFoliosList);
	
	// 5. Invoice accounts
	PostToInvoiceAccounts();
	
	// 6. Set wait for payment till date to guest group
	If ValueIsFilled(GuestGroup) And Not ValueIsFilled(GuestGroup.CheckDate) Then
		vCheckDate = Undefined;
		If ValueIsFilled(AccountingContract) And AccountingContract.DaysAfterSettlement <> 0 And ValueIsFilled(Date) Then
			vCheckDate = cmAddWorkingDays(BegOfDay(Date), (AccountingContract.DaysAfterSettlement + 1));
		ElsIf ValueIsFilled(AccountingCustomer) And AccountingCustomer.DaysAfterSettlement <> 0 And ValueIsFilled(Date) Then
			vCheckDate = cmAddWorkingDays(BegOfDay(Date), (AccountingCustomer.DaysAfterSettlement + 1));
		EndIf;
		If ValueIsFilled(vCheckDate) Then
			vGroupObj = GuestGroup.GetObject();
			vGroupObj.CheckDate = vCheckDate;
			vGroupObj.Write();
		EndIf;
	EndIf;
EndProcedure // Posting

// -----------------------------------------------------------------------------
Procedure Filling(pBase)
	// Fill attributes with default values
	pmFillAttributesWithDefaultValues();
	// Fill from the base
	If ValueIsFilled(pBase) Then
		If TypeOf(pBase) = Type("DocumentRef.Folio") Then
			pmFillByFolio(pBase);
		ElsIf TypeOf(pBase) = Type("DocumentRef.Payment") Then
			pmFillByPayment(pBase);
		ElsIf TypeOf(pBase) = Type("DocumentRef.Return") Then
			pmFillByReturn(pBase);
		ElsIf TypeOf(pBase) = Type("DocumentRef.DepositTransfer") Then
			pmFillByDepositTransfer(pBase);
		ElsIf TypeOf(pBase) = Type("DocumentRef.Reservation") Then 
			pmFillByDocument(pBase);
		ElsIf TypeOf(pBase) = Type("DocumentRef.Accommodation") Then 
			pmFillByDocument(pBase);
		ElsIf TypeOf(pBase) = Type("DocumentRef.ResourceReservation") Then 
			pmFillByResourceReservation(pBase);
		ElsIf TypeOf(pBase) = Type("DocumentRef.ProformaInvoice") Then 
			pmFillByInvoice(pBase);
		ElsIf TypeOf(pBase) = Type("CatalogRef.GuestGroups") Then 
			pmFillByGuestGroup(pBase);
		ElsIf TypeOf(pBase) = Type("CatalogRef.Customers") Then
			pmFillByCustomer(pBase);
		ElsIf TypeOf(pBase) = Type("CatalogRef.Contracts") Then
			pmFillByContract(pBase);
		EndIf;
	EndIf;
	PerInvoiceCommission = 0;
	If ValueIsFilled(AccountingContract) And AccountingContract.PerInvoiceCommission <> 0 Then
		PerInvoiceCommission = AccountingContract.PerInvoiceCommission;
		pmCalculateTotals();
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
			WriteLogEvent(NStr("en = 'Document.DataValidation'; de = 'Document.DataValidation'; ru = 'Документ.КонтрольДанных'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
			tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
			Raise NStr(vMessage);
		EndIf;
		If IsBlankString(InvoiceNumber) And Not DoNotExportToTheAccountingSystem And 
		   ValueIsFilled(Company) And Company.AutoAssignVATInvoiceNumbers Then
			vLastInvoiceNumber = cmGetLastUsedVATInvoiceNumber(Company);
			InvoiceNumber = cmGetNextVATInvoiceNumber(vLastInvoiceNumber);
		EndIf;
		If Not Ref.Posted Or 
		   Ref.Hotel <> Hotel Or 
		   Ref.Company <> Company Or 
		   Ref.AccountingCustomer <> AccountingCustomer Or 
		   Ref.AccountingContract <> AccountingContract Or 
		   Ref.GuestGroup <> GuestGroup Or 
		   Ref.AccountingCurrency <> AccountingCurrency Or 
		   Ref.IsChecked <> IsChecked Or 
		   ServicesHasChanged() Then
			If Not ValueIsFilled(ChangeDate) And ValueIsFilled(Date) Then
				ChangeDate = Date;
			Else
				ChangeDate = CurrentSessionDate();
			EndIf;
			ChangeAuthor = SessionParameters.CurrentUser;
		EndIf;
	Else
		If Ref.Posted And pWriteMode = DocumentWriteMode.UndoPosting Or Not Ref.DeletionMark And Ref.Posted And DeletionMark Then
			If ValueIsFilled(Hotel) Then
				If ValueIsFilled(Hotel.EditProhibitedDate) And 
					BegOfDay(Hotel.EditProhibitedDate) >= BegOfDay(Date) Then
					pCancel = True;
				EndIf;
			EndIf;
			If ValueIsFilled(Company) Then
				If ValueIsFilled(Company.EditProhibitedDate) And 
					BegOfDay(Company.EditProhibitedDate) >= BegOfDay(Date) Then
					pCancel = True;
				EndIf;
			EndIf;
			vHasRightsToEditInvoice = cmHasRightsToEditInvoice(Company, Date, ExternalCode);
			If Not vHasRightsToEditInvoice Then
				pCancel = True;
			EndIf;  
			If Not pCancel Then
				ChangeAuthor = SessionParameters.CurrentUser;
				ChangeDate = CurrentSessionDate();
			Else
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'You do not have rights to edit invoice!'; de = 'Sie haben kein Recht, die Rechnung zu ändern!'; ru = 'Нет прав изменять акт!'"), MessageStatus.Attention);
			EndIf;
		EndIf;
		If Not Ref.DeletionMark And DeletionMark Then
			// User activity history   
			vEventDescription = NStr("en = 'Set document deletion mark'; de = 'Erstellung der Löschmarkierung'; ru = 'Установка отметки удаления'");    
			InformationRegisters.UserActionsHistory.WriteUserActivityRecord(Ref, vEventDescription, Hotel);
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure BeforeDelete(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	// User activity history   
	vEventDescription = NStr("en = 'Document deletion'; de = 'Unmittelbare Löschung'; ru = 'Непосредственное удаление'");    
	InformationRegisters.UserActionsHistory.WriteUserActivityRecord(Ref, vEventDescription, Hotel);
EndProcedure // BeforeDelete

// -----------------------------------------------------------------------------
Procedure OnSetNewNumber(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(Company) And Not IsBlankString(Company.Prefix) Then
		vPrefix = TrimAll(Company.Prefix);
	ElsIf ValueIsFilled(Hotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(Hotel);
	ElsIf ValueIsFilled(SessionParameters.CurrentHotel) Then
		If ValueIsFilled(SessionParameters.CurrentHotel.Company) And Not IsBlankString(SessionParameters.CurrentHotel.Company.Prefix) Then
			vPrefix = TrimAll(SessionParameters.CurrentHotel.Company.Prefix);
		Else
			vPrefix = Catalogs.Hotels.pmGetPrefix(SessionParameters.CurrentHotel);
		EndIf;
	EndIf;
	If vPrefix <> "" Then
		pPrefix = vPrefix;
	EndIf;
EndProcedure // OnSetNewNumber

// -----------------------------------------------------------------------------
Procedure OnCopy(pCopiedObject)
	Date = CurrentSessionDate();
	Author = SessionParameters.CurrentUser;
	ChangeAuthor = Undefined;
	ChangeDate = '00010101';
	ExternalCode = "";
	InvoiceNumber = "";
	IsChecked = False;
EndProcedure // OnCopy

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
Function GetInvoiceServices(rFoliosList, rNotSortedServices)
	// All services
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	*,
	|	SettlementServices.Charge.ParentDoc AS ChargeParentDoc,
	|	SettlementServices.Charge.Folio AS ChargeFolio,
	|	SettlementServices.Charge.Folio.GuestGroup AS ChargeFolioGuestGroup,
	|	SettlementServices.Service.PaymentSection AS ServicePaymentSection,
	|	SettlementServices.Agent.DoNotPostCommission AS AgentDoNotPostCommission,
	|	SettlementServices.Agent.AgentCommissionContract AS AgentAgentCommissionContract
	|FROM
	|	Document.Settlement.Services AS SettlementServices
	|WHERE
	|	SettlementServices.Ref = &qInvoice
	|
	|ORDER BY
	|	SettlementServices.Charge.Folio,
	|	SettlementServices.AccountingDate,
	|	SettlementServices.Charge";
	vQry.SetParameter("qInvoice", Ref);
	vServices = vQry.Execute().Unload();
    vServicesFolios = Services.Unload(, "Folio");
	vServicesFolios.GroupBy("Folio", );
	rFoliosList = New ValueList();
	rFoliosList.LoadValues(vServicesFolios.UnloadColumn("Folio"));
	// Not sorted services
	vNSQry = New Query();
	vNSQry.Text = 
	"SELECT
	|	SettlementServices.Charge AS Charge,
	|	SettlementServices.Charge.ParentDoc AS ChargeParentDoc,
	|	SettlementServices.Charge.Folio AS ChargeFolio,
	|	SettlementServices.Charge.Folio.FolioCurrency AS ChargeFolioCurrency
	|FROM
	|	Document.Settlement.Services AS SettlementServices
	|WHERE
	|	SettlementServices.Ref = &qInvoice
	|
	|ORDER BY
	|	SettlementServices.LineNumber";
	vNSQry.SetParameter("qInvoice", Ref);
	rNotSortedServices = vNSQry.Execute().Unload();
	// Return
	Return vServices;
EndFunction // GetInvoiceServices

// -----------------------------------------------------------------------------
Procedure pmPrintSettlement(vSpreadsheet, SelLanguage, SelGroupBy, SelObjectPrintForm, pPageBreak = False) Export
	// Basic checks
	vHotel = Hotel;
	If Not ValueIsFilled(vHotel) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Hotel should be filled!'; de = 'Das Hotel ist nicht angegeben!'; ru = 'Не задана гостиница!'"), MessageStatus.Attention);
		Return;
	EndIf;
	vCompany = Company;
	If Not ValueIsFilled(vCompany) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Company should be filled!'; de = 'Die Firma ist nicht angegeben!'; ru = 'Не задана фирма!'"), MessageStatus.Attention);
		Return;
	EndIf;
	If Not ValueIsFilled(SelLanguage) Then
		SelLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	
	// Fill and check grouping parameter
	vParameter = Upper(TrimAll(SelObjectPrintForm.Parameter));
	vDoNotShowPayDueDate = (Find(vParameter, "DO_NOT_SHOW_PAY_DUE_DATE") > 0);
	
	// Choose template
	vSettlObj = ThisObject;
	If pPageBreak Then
		vSpreadsheet.PutHorizontalPageBreak();
	Else
		vSpreadsheet.Clear();
	EndIf;
	If ValueIsFilled(SelLanguage) Then
		If SelLanguage = Catalogs.Languages.EN Then
			vTemplate = vSettlObj.GetTemplate("SettlementDetailedEn");
			If Not IsBlankString(SelGroupBy) Then
				If SelGroupBy = "InPricePerFolio" Or SelGroupBy = "InPrice" Or SelGroupBy = "AllPerFolio" Or SelGroupBy = "All" Or SelGroupBy = "PerFolio" Or SelGroupBy = "ByService" Then
					vTemplate = vSettlObj.GetTemplate("SettlementShortEn");
				EndIf;
			EndIf;
		ElsIf SelLanguage = Catalogs.Languages.DE Then
			vTemplate = vSettlObj.GetTemplate("SettlementDetailedDe");
			If Not IsBlankString(SelGroupBy) Then
				If SelGroupBy = "InPricePerFolio" Or SelGroupBy = "InPrice" Or SelGroupBy = "AllPerFolio" Or SelGroupBy = "All" Or SelGroupBy = "PerFolio" Or SelGroupBy = "ByService" Then
					vTemplate = vSettlObj.GetTemplate("SettlementShortDe");
				EndIf;
			EndIf;
		ElsIf SelLanguage = Catalogs.Languages.RU Then
			vTemplate = vSettlObj.GetTemplate("SettlementDetailedRu");
			If Not IsBlankString(SelGroupBy) Then
				If SelGroupBy = "InPricePerFolio" Or SelGroupBy = "InPrice" Or SelGroupBy = "AllPerFolio" Or SelGroupBy = "All" Or SelGroupBy = "PerFolio" Or SelGroupBy = "ByService" Then
					vTemplate = vSettlObj.GetTemplate("SettlementShortRu");
				EndIf;
			EndIf;
		Else           
			vErrMsg = StrTemplate(NStr("en = 'No settlement print form template found for the %1 language!'; 
									   |de = 'No settlement print form template found for the %1 language!'; 
									   |ru = 'Не найден шаблон печатной формы акта для языка %1!'"), SelLanguage.Code);
			tcCommonFunctionOnClientServer.TextMessage(vErrMsg, MessageStatus.Attention);
			Return;
		EndIf;
	Else
		vTemplate = vSettlObj.GetTemplate("SettlementDetailedRu");
		If Not IsBlankString(SelGroupBy) Then
			If SelGroupBy = "InPricePerFolio" Or SelGroupBy = "InPrice" Or SelGroupBy = "AllPerFolio" Or SelGroupBy = "All" Or SelGroupBy = "PerFolio" Or SelGroupBy = "ByService" Then
				vTemplate = vSettlObj.GetTemplate("SettlementShortRu");
			EndIf;
		EndIf;
	EndIf;
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(SelObjectPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;
	
	// Load pictures
	vStampIsSet = False;
	vStamp = New Picture;
	If ValueIsFilled(Company) Then
		If Company.Stamp <> Undefined Then
			vStamp = Company.Stamp.Get();
			If vStamp = Undefined Then
				vStamp = New Picture;
			Else
				vStampIsSet = True;
			EndIf;
		EndIf;
	EndIf;
	vDirectorSignatureIsSet = False;
	vDirectorSignature = New Picture;
	If Company.DirectorSignature <> Undefined Then
		vDirectorSignature = Company.DirectorSignature.Get();
		If vDirectorSignature = Undefined Then
			vDirectorSignature = New Picture;
		Else
			vDirectorSignatureIsSet = True;
		EndIf;
	EndIf;
	
	// Header
	vHeader = vTemplate.GetArea("Header");
	// Hotel
	vHotelObj = vHotel.GetObject();
	mHotelPrintName = vHotelObj.pmGetHotelPrintName(SelLanguage);
	mHotelPostAddressPresentation = vHotelObj.pmGetHotelPostAddressPresentation(SelLanguage);
	vHotelPhones = TrimAll(vHotel.Phones);
	vHotelFax = TrimAll(vHotel.Fax);
	vHotelEMail = TrimAll(vHotel.EMail);
	vHotelPhones = vHotelPhones +  
	               ?(IsBlankString(vHotelFax), "", ?(IsBlankString(vHotelPhones), "", ", ") + cmNStr("en = 'fax '; de = 'fax '; ru = 'факс '", SelLanguage) + vHotelFax);
	vHotelPhones = vHotelPhones + 
				   ?(IsBlankString(vHotelEMail), "", ?(IsBlankString(vHotelPhones), "", ", ") + cmNStr("en = 'e-mail '; de = 'e-mail '; ru = 'e-mail '", SelLanguage) + vHotelEMail);
	mHotelPhones = TrimAll(vHotelPhones);
	// Company
	vCompanyCodes = "";
	vCompanyObj = vCompany.GetObject();
	vCompanyLegacyName = vCompanyObj.pmGetCompanyPrintName(SelLanguage);
	vCompanyLegacyAddress = vCompanyObj.pmGetCompanyLegacyAddressPresentation(SelLanguage);
	vCompanyPostAddress = vCompanyObj.pmGetCompanyPostAddressPresentation(SelLanguage);
	If Lower(vCompanyPostAddress) = Lower(vCompanyLegacyAddress) Then
		vCompanyPostAddress = "";
	EndIf;
	vCompanyTIN = TrimAll(vCompany.TIN);
	vCompanyKPP = TrimAll(vCompany.KPP);
	vCompanyVATC = TrimAll(vCompany.VATC);
	If Not IsBlankString(vCompanyTIN) Then
		vCompanyCodes = cmNStr("en = 'Reg. N'; de = 'Reg. N'; ru = 'ИНН'", SelLanguage) + ?(IsBlankString(vCompanyKPP), " ", "/" + cmNStr("en = 'KPP '; de = 'KPP '; ru = 'КПП '", SelLanguage)) + vCompanyTIN + ?(IsBlankString(vCompanyKPP), "", "/" + vCompanyKPP);
	EndIf;
	If Not IsBlankString(vCompanyVATC) Then
		vCompanyCodes = vCompanyCodes + ?(IsBlankString(vCompanyCodes), "", ", ") + cmNStr("en = 'VAT Code '; de = 'Mw.St. Code '; ru = 'код НДС '", SelLanguage) + vCompanyVATC;
	EndIf;
	mCompany = TrimAll(vCompanyLegacyName + ?(IsBlankString(vCompanyCodes), "", ", " + vCompanyCodes) + Chars.LF + vCompanyLegacyAddress + ?(IsBlankString(vCompanyPostAddress), "", Chars.LF + vCompanyPostAddress));
	// Settlement date and number
	mSettlementNumber = ?(vCompany.PrintInvoiceAndSettlementNumbersWithPrefixes, TrimAll(Number), cmGetDocumentNumberPresentation(Number));
	mSettlementDate = cmGetDocumentDatePresentation(Date);
	// Customer
	vCustomer = AccountingCustomer;
	vCustomerCodes = "";
	vCustomerLegacyName = "";
	vCustomerLegacyAddress = "";
	vCustomerPostAddress = "";
	vCustomerTIN = "";
	vCustomerPhones = "";
	If ValueIsFilled(vCustomer) Then
		// Name and address
		vCustomerLegacyName = TrimAll(vCustomer.LegacyName);
		If IsBlankString(vCustomerLegacyName) Then
			vCustomerLegacyName = TrimAll(vCustomer.Description);
		EndIf;
		vCustomerLegacyAddress = cmGetAddressPresentation(vCustomer.LegacyAddress);
		vCustomerPostAddress = cmGetAddressPresentation(vCustomer.PostAddress);
		If vCustomerPostAddress = vCustomerLegacyAddress Then
			vCustomerPostAddress = "";
		EndIf;
		// Customer codes
		vCustomerTIN = TrimAll(vCustomer.TIN);
		vCustomerKPP = TrimAll(vCustomer.KPP);
		vCustomerVATC = TrimAll(vCustomer.VATC);
		If Not IsBlankString(vCustomerTIN) Then
			vCustomerCodes = cmNStr("en = 'Reg. N'; de = 'Reg. N'; ru = 'ИНН'", SelLanguage) + ?(IsBlankString(vCustomerKPP), " ", "/" + cmNStr("en = 'KPP '; de = 'KPP '; ru = 'КПП '", SelLanguage)) + vCustomerTIN + ?(IsBlankString(vCustomerKPP), "", "/" + vCustomerKPP);
		EndIf;
		If Not IsBlankString(vCustomerVATC) Then
			vCustomerCodes = vCustomerCodes + ?(IsBlankString(vCustomerCodes), "", ", ") + cmNStr("en = 'VAT Code '; de = 'Mw.St. Code '; ru = 'код НДС '", SelLanguage) + vCustomerVATC;
		EndIf;
		// Fax and E-Mail
		vCustomerPhones = TrimAll(vCustomer.Phone);
		vCustomerFax = TrimAll(vCustomer.Fax);
		vCustomerEMail = TrimAll(vCustomer.EMail);
		vCustomerPhones = vCustomerPhones + 
		                  ?(IsBlankString(vCustomerFax), "", ?(IsBlankString(vCustomerPhones), "", ", ") + cmNStr("en = 'fax '; de = 'fax '; ru = 'факс '", SelLanguage) + vCustomerFax);
		vCustomerPhones = vCustomerPhones + 
						  ?(IsBlankString(vCustomerEMail), "", ?(IsBlankString(vCustomerPhones), "", ", ") + cmNStr("en = 'e-mail '; de = 'e-mail '; ru = 'e-mail '", SelLanguage) + vCustomerEMail);
	EndIf;
	mCustomer = TrimAll(vCustomerLegacyName + ?(IsBlankString(vCustomerCodes), "", ", " + vCustomerCodes) + Chars.LF + vCustomerLegacyAddress + ?(IsBlankString(vCustomerPostAddress), "", Chars.LF + vCustomerPostAddress) + Chars.LF + vCustomerPhones);
	// Contract
	mContract = "";
	If ValueIsFilled(AccountingContract) Then
		mContract = TrimAll(AccountingContract.Description);
	EndIf;
	// Guest group code
	mGuestGroup = "";
	If ValueIsFilled(GuestGroup) Then
		mGuestGroup = Format(GuestGroup.Code, "ND=12; NFD=0");
		If ValueIsFilled(Hotel) Then
			vHotelPrefix = Catalogs.Hotels.pmGetPrefix(Hotel);
			If Not IsBlankString(vHotelPrefix) And Hotel.ShowHotelPrefixBeforeGroupCode Then
				mGuestGroup = vHotelPrefix + mGuestGroup;
			EndIf;
		EndIf;
		If Not IsBlankString(GuestGroup.ID) Then
			mGuestGroup = mGuestGroup + " - Ref. # " + TrimAll(GuestGroup.ID);
		ElsIf Not IsBlankString(GuestGroup.Description) Then
			mGuestGroup = mGuestGroup + " - " + TrimAll(GuestGroup.Description);
		EndIf;
	EndIf;
	// Currency
	mAccountingCurrency = "";
	If ValueIsFilled(AccountingCurrency) Then
		vCurrencyObj = AccountingCurrency.GetObject();
		mAccountingCurrency = vCurrencyObj.pmGetCurrencyDescription(SelLanguage);
	EndIf;
	// Parent document
	mParentDoc = String(ParentDoc);
	// Set parameters and put report section
	vHeader.Parameters.mHotelPrintName = mHotelPrintName;
	vHeader.Parameters.mHotelPostAddressPresentation = mHotelPostAddressPresentation;
	vHeader.Parameters.mHotelPhones = mHotelPhones;
	vHeader.Parameters.mSettlementNumber = mSettlementNumber;
	vHeader.Parameters.mSettlementDate = mSettlementDate;
	vHeader.Parameters.mCompany = mCompany;
	vHeader.Parameters.mCustomer = mCustomer;
	vHeader.Parameters.mContract = mContract;
	vHeader.Parameters.mGuestGroup = mGuestGroup;
	vHeader.Parameters.mAccountingCurrency = mAccountingCurrency;
	vHeader.Parameters.mParentDoc = mParentDoc;
	vSpreadsheet.Put(vHeader);
	
	// Get template areas
	vFolio = vTemplate.GetArea("Folio");
	vRow = vTemplate.GetArea("Row");
	
	// Get all services
	vServices = Documents.Settlement.MergeCorrections(Services);
	
	// Change accounting dates for breakfast
	If Not IsBlankString(SelGroupBy) And SelGroupBy <> "ByService" Then
		For Each vSrvRow In vServices Do
			If vSrvRow.IsInPrice And ValueIsFilled(vSrvRow.Service.QuantityCalculationRule) And
			   vSrvRow.Service.QuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.Breakfast Then
				If ValueIsFilled(vSrvRow.Folio) And BegOfDay(vSrvRow.AccountingDate) > BegOfDay(vSrvRow.Folio.DateTimeFrom) Then
					vSrvRow.AccountingDate = vSrvRow.AccountingDate - 24 * 3600;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	// Join services according to service parameters
	If Not IsBlankString(SelGroupBy) And SelGroupBy <> "ByService" Then
		// Try to replace accommodation service to the one that should be used for printing
		vChargeParentDoc = Undefined;
		vAccountingDate = '00010101';
		vFirstRoomRateService = Undefined;
		vFirstRoomRateServiceIsFound = False;
		For Each vSrvRow In vServices Do
			vSrvRowService = vSrvRow.Service;
			If ValueIsFilled(vSrvRowService) Then
				If vChargeParentDoc <> vSrvRow.ParentDoc Then
					vChargeParentDoc = vSrvRow.ParentDoc;
					vAccountingDate = '00010101';
					vFirstRoomRateService = Undefined;
					vFirstRoomRateServiceIsFound = False;
				EndIf;
				If vAccountingDate <> BegOfDay(vSrvRow.AccountingDate) Then
					vAccountingDate = BegOfDay(vSrvRow.AccountingDate);
					vFirstRoomRateService = Undefined;
					vFirstRoomRateServiceIsFound = False;
				EndIf;
				If vSrvRowService.IsRoomRevenue And vSrvRowService.IsInPrice And Not vSrvRowService.RoomRevenueAmountsOnly Then
					If ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
						vSrvRow.Service = vSrvRowService.HideIntoServiceOnPrint;
					EndIf;
					If Not vFirstRoomRateServiceIsFound Then
						vFirstRoomRateService = vSrvRowService;
						vFirstRoomRateServiceIsFound = True;
					Else
						If vFirstRoomRateService <> vSrvRowService And ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
							vSrvRow.Quantity = 0;
						EndIf;
					EndIf;
				ElsIf vSrvRowService.DoNotGroupIntoRoomRateOnPrint And ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
					vSrvRow.Service = vSrvRowService.HideIntoServiceOnPrint;
				EndIf;
			EndIf;
		EndDo;
		// Try to merge other services to the accommodation service
		vInt = 0;
		While vInt < vServices.Count() Do
			vSrvRow = vServices.Get(vInt);
			vSrvRowService = vSrvRow.Service;
			If ValueIsFilled(vSrvRowService) And ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
				If Not vSrvRowService.DoNotGroupIntoRoomRateOnPrint Then
					vHideToServices = vServices.FindRows(New Structure("Service, AccountingDate, Folio", vSrvRowService.HideIntoServiceOnPrint, vSrvRow.AccountingDate, vSrvRow.Folio));
					If vHideToServices.Count() = 0 Then
						vHideToServices = vServices.FindRows(New Structure("Service, AccountingDate, Folio", vSrvRowService.HideIntoServiceOnPrint, vSrvRow.AccountingDate - 24 * 3600, vSrvRow.Folio));
					EndIf;
					If vHideToServices.Count() > 0 Then
						vSrv2Hide2 = vHideToServices.Get(0);
						vSrv2Hide2.Sum = vSrv2Hide2.Sum + vSrvRow.Sum;
						vSrv2Hide2.VATSum = vSrv2Hide2.VATSum + vSrvRow.VATSum;
						vSrv2Hide2.Price = cmRecalculatePrice(vSrv2Hide2.Sum, vSrv2Hide2.Quantity);    
						vSrv2Hide2.CommissionSum = vSrv2Hide2.CommissionSum + vSrvRow.CommissionSum;
						// Delete current service
						vServices.Delete(vInt);
						Continue;
					EndIf;
				EndIf;
			EndIf;
			vInt = vInt + 1;
		EndDo;
	EndIf;
	
	// Get accommodation service name
	vAccommodationService = Undefined;	
	vAccommodationServiceRemarks = "";	
	vAccommodationRemarks = "";	
	vAccommodationServiceVATRate = Undefined;
	vInt = 0;
	While vInt < vServices.Count() Do
		vSrvRow = vServices.Get(vInt);
		If SelGroupBy = "InPricePerFolioPerDay" Or SelGroupBy = "InPricePerDay" 
		   Or SelGroupBy = "AllPerFolioPerDay" Or SelGroupBy = "AllPerDay" 
		   Or SelGroupBy = "InPricePerFolio" Or SelGroupBy = "InPrice" 
		   Or SelGroupBy = "AllPerFolio" Or SelGroupBy = "All" Then
			If Find(vParameter, "SHOWZEROES") = 0 Then
				If vSrvRow.Sum = 0 Then
					vServices.Delete(vInt);
					Continue;
				EndIf;
			EndIf;
		EndIf;
		If vAccommodationService = Undefined And ValueIsFilled(vSrvRow.Service) And vSrvRow.IsInPrice And vSrvRow.IsRoomRevenue And Not vSrvRow.Service.RoomRevenueAmountsOnly Then
			vAccommodationService = vSrvRow.Service;
			vAccommodationServiceVATRate = vSrvRow.VATRate;
			vAccommodationServiceObj = vAccommodationService.GetObject();
			vAccommodationServiceRemarks = vAccommodationServiceObj.pmGetServiceDescription(SelLanguage, False);
			vAccommodationRemarks = vAccommodationServiceObj.pmGetServiceDescription(SelLanguage, True);
		EndIf;
		vInt = vInt + 1;
	EndDo;
	
	// Group by services according to the settlement print type
	If Not IsBlankString(SelGroupBy) Then
		If SelGroupBy = "InPricePerFolioPerDay" Or SelGroupBy = "InPricePerDay" Then
			For Each vSrvRow In vServices Do
				// Reset "is in price" flag if necessary
				If ValueIsFilled(vSrvRow.Service) And vSrvRow.Service.DoNotGroupIntoRoomRateOnPrint Then
					vSrvRow.IsInPrice = False;
				EndIf;
				vSrvRow.AccountingDate = BegOfDay(vSrvRow.AccountingDate);
				vSrvRow.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
				vSrvRow.Room = Catalogs.Rooms.EmptyRef();
				If SelGroupBy = "InPricePerDay" Then
					vSrvRow.Folio = Documents.Folio.EmptyRef();
				EndIf;
				If ValueIsFilled(vAccommodationService) And vAccommodationServiceVATRate = vSrvRow.VATRate Then
					If Not vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice Then
						vSrvRow.Service = ?(ValueIsFilled(vAccommodationService), vAccommodationService, vSrvRow.Service);
						If Not IsBlankString(vAccommodationRemarks) Then
							If StrFind(SelGroupBy,  "PerFolio") = 0 Then
								vSrvRow.Remarks = vAccommodationRemarks;
							Else
								vSrvRow.Remarks = StrReplace(TrimAll(vSrvRow.Remarks), vAccommodationServiceRemarks, vAccommodationRemarks);
							EndIf;
						Else
							vSrvRow.Remarks = TrimAll(vSrvRow.Remarks);
						EndIf;
						vSrvRow.Quantity = ?(IsBlankString(vAccommodationRemarks), vSrvRow.Quantity, 0);
						vSrvRow.Price = 0;
					ElsIf vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice Then
						If vSrvRow.Service.RoomRevenueAmountsOnly Or (SelGroupBy = "InPricePerFolioPerDay" And vSrvRow.Client <> vSrvRow.Folio.Client) Then
							vSrvRow.Quantity = 0;
							vSrvRow.Price = 0;
						EndIf;
						vSrvRow.Service = ?(ValueIsFilled(vAccommodationService), vAccommodationService, vSrvRow.Service);
						If Not IsBlankString(vAccommodationRemarks) Then
							If StrFind(SelGroupBy,  "PerFolio") = 0 Then
								vSrvRow.Remarks = vAccommodationRemarks;
							Else
								vSrvRow.Remarks = StrReplace(TrimAll(vSrvRow.Remarks), vAccommodationServiceRemarks, vAccommodationRemarks);
							EndIf;
						Else
							vSrvRow.Remarks = TrimAll(vSrvRow.Remarks);
						EndIf;
					EndIf;
				EndIf;
			EndDo;
		ElsIf SelGroupBy = "AllPerFolioPerDay" Or SelGroupBy = "AllPerDay" Then
			For Each vSrvRow In vServices Do
				vSrvRow.AccountingDate = BegOfDay(vSrvRow.AccountingDate);
				vSrvRow.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
				vSrvRow.Room = Catalogs.Rooms.EmptyRef();
				If SelGroupBy = "AllPerDay" Then
					vSrvRow.Folio = Documents.Folio.EmptyRef();
				EndIf;
				If ValueIsFilled(vAccommodationService) And vAccommodationServiceVATRate = vSrvRow.VATRate Then
					If vSrvRow.Service.RoomRevenueAmountsOnly Or (SelGroupBy = "AllPerFolioPerDay" And vSrvRow.Client <> vSrvRow.Folio.Client) Then
						vSrvRow.Quantity = 0;
						vSrvRow.Price = 0;
					EndIf;
					vSrvRow.Service = ?(ValueIsFilled(vAccommodationService), vAccommodationService, vSrvRow.Service);
					If Not IsBlankString(vAccommodationRemarks) Then
						If StrFind(SelGroupBy,  "PerFolio") = 0 Then
							vSrvRow.Remarks = vAccommodationRemarks;
						Else
							vSrvRow.Remarks = StrReplace(TrimAll(vSrvRow.Remarks), vAccommodationServiceRemarks, vAccommodationRemarks);
						EndIf;
					Else
						vSrvRow.Remarks = TrimAll(vSrvRow.Remarks);
					EndIf;
					If Not vSrvRow.IsRoomRevenue Then
						vSrvRow.Quantity = ?(IsBlankString(vAccommodationRemarks), vSrvRow.Quantity, 0);
						vSrvRow.Price = 0;
					EndIf;
				EndIf;
			EndDo;
		ElsIf SelGroupBy = "PerFolio" Then
			For Each vSrvRow In vServices Do
				vSrvRow.AccountingDate = BegOfDay(Date);
			EndDo;
		ElsIf SelGroupBy = "ByService" Then
			For Each vSrvRow In vServices Do
				vSrvRow.AccountingDate = BegOfDay(Date);
				vSrvRow.Folio = Documents.Folio.EmptyRef();
				vSrvRow.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
				vSrvRow.Room = Catalogs.Rooms.EmptyRef();
				vSrvRow.Resource = Catalogs.Resources.EmptyRef();
			EndDo;
		ElsIf SelGroupBy = "InPricePerFolio" Or SelGroupBy = "InPrice" Then
			For Each vSrvRow In vServices Do
				// Reset "is in price" flag if necessary
				If ValueIsFilled(vSrvRow.Service) And vSrvRow.Service.DoNotGroupIntoRoomRateOnPrint Then
					vSrvRow.IsInPrice = False;
				EndIf;
				vSrvRow.AccountingDate = BegOfDay(Date);
				If SelGroupBy = "InPrice" Then
					vSrvRow.Folio = Documents.Folio.EmptyRef();
					vSrvRow.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
					vSrvRow.Room = Catalogs.Rooms.EmptyRef();
				EndIf;
				If ValueIsFilled(vAccommodationService) And vAccommodationServiceVATRate = vSrvRow.VATRate Then
					If Not vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice Then
						vSrvRow.Service = ?(ValueIsFilled(vAccommodationService), vAccommodationService, vSrvRow.Service);
						vSrvRow.Quantity = ?(IsBlankString(vAccommodationRemarks), vSrvRow.Quantity, 0);
						vSrvRow.Price = 0;
						If Not IsBlankString(vAccommodationRemarks) Then
							If StrFind(SelGroupBy,  "PerFolio") = 0 Then
								vSrvRow.Remarks = vAccommodationRemarks;
							Else
								vSrvRow.Remarks = StrReplace(TrimAll(vSrvRow.Remarks), vAccommodationServiceRemarks, vAccommodationRemarks);
							EndIf;
						Else
							vSrvRow.Remarks = TrimAll(vSrvRow.Remarks);
						EndIf;
					ElsIf vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice Then
						If vSrvRow.Service.RoomRevenueAmountsOnly Or (SelGroupBy = "InPricePerFolio" And vSrvRow.Client <> vSrvRow.Folio.Client) Then
							vSrvRow.Quantity = 0;
							vSrvRow.Price = 0;
						EndIf;
						vSrvRow.Service = ?(ValueIsFilled(vAccommodationService), vAccommodationService, vSrvRow.Service);
						If Not IsBlankString(vAccommodationRemarks) Then
							If StrFind(SelGroupBy,  "PerFolio") = 0 Then
								vSrvRow.Remarks = vAccommodationRemarks;
							Else
								vSrvRow.Remarks = StrReplace(TrimAll(vSrvRow.Remarks), vAccommodationServiceRemarks, vAccommodationRemarks);
							EndIf;
						Else
							vSrvRow.Remarks = TrimAll(vSrvRow.Remarks);
						EndIf;
					EndIf;
				EndIf;
			EndDo;
		ElsIf SelGroupBy = "AllPerFolio" Or SelGroupBy = "All" Then
			For Each vSrvRow In vServices Do
				vSrvRow.AccountingDate = BegOfDay(Date);
				vSrvRow.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
				vSrvRow.Room = Catalogs.Rooms.EmptyRef();
				If SelGroupBy = "All" Then
					vSrvRow.Folio = Documents.Folio.EmptyRef();
				EndIf;
				If ValueIsFilled(vAccommodationService) And vAccommodationServiceVATRate = vSrvRow.VATRate Then
					If vSrvRow.Service.RoomRevenueAmountsOnly Or (SelGroupBy = "AllPerFolio" And vSrvRow.Client <> vSrvRow.Folio.Client) Then
						vSrvRow.Quantity = 0;
						vSrvRow.Price = 0;
					EndIf;
					vSrvRow.Service = ?(ValueIsFilled(vAccommodationService), vAccommodationService, vSrvRow.Service);
					If Not IsBlankString(vAccommodationRemarks) Then
						If StrFind(SelGroupBy,  "PerFolio") = 0 Then
							vSrvRow.Remarks = vAccommodationRemarks;
						Else
							vSrvRow.Remarks = StrReplace(TrimAll(vSrvRow.Remarks), vAccommodationServiceRemarks, vAccommodationRemarks);
						EndIf;
					Else
						vSrvRow.Remarks = TrimAll(vSrvRow.Remarks);
					EndIf;
					If Not vSrvRow.IsRoomRevenue Then
						vSrvRow.Quantity = ?(IsBlankString(vAccommodationRemarks), vSrvRow.Quantity, 0);
						vSrvRow.Price = 0;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		// Group by transactions
		vServices.GroupBy("Folio, AccountingDate, Service, CalendarDayType, Room, Resource, Remarks, VATRate, AgentCommission", "Sum, VATSum, Price, Quantity, CommissionSum");
		// Recalculate price for all services and delete zero sum rows
		vInt = 0;
		While vInt < vServices.Count() Do
			vSrvRow = vServices.Get(vInt);
			If vSrvRow.Sum = 0 And SelGroupBy <> "ByService" And Find(vParameter, "SHOWZEROES") = 0 Then
				vServices.Delete(vInt);
			Else
				vSrvRow.VATSum = cmCalculateVATSum(vSrvRow.VATRate, vSrvRow.Sum, vSrvRow.AccountingDate);
				vSrvRow.Price = cmRecalculatePrice(vSrvRow.Sum, vSrvRow.Quantity);
				vInt = vInt + 1;
			EndIf;
		EndDo;
	EndIf;
	vServices.Sort("Folio, AccountingDate");
	
	// Print services
	vTotalSum = 0;
	vTotalSumNoCommission = 0;
	vTotalVATSum = 0;
	vCurFolio = Documents.Folio.EmptyRef();
	vAgentCommission = 0;
	vTotalCommissionSum = CommissionSum;
	For Each vSrvRow In vServices Do
		// Print folio header if necessary
		If vSrvRow.Folio <> vCurFolio Then
			vCurFolio = vSrvRow.Folio;
			// Fill folio parameters
			mClient = "";
			If ValueIsFilled(vCurFolio.Client) Then
				mClient = TrimAll(TrimAll(vCurFolio.Client.LastName) + " " + TrimAll(vCurFolio.Client.FirstName) + " " + TrimAll(vCurFolio.Client.SecondName));
			ElsIf ValueIsFilled(vCurFolio.Customer) Then
				If Not IsBlankString(vCurFolio.Customer.LegacyName) Then
					mClient = TrimAll(vCurFolio.Customer.LegacyName);
				Else
					mClient = TrimAll(vCurFolio.Customer.Description);
				EndIf;
			EndIf;
			vDateFrom = vCurFolio.DateTimeFrom;
			vDateTo = vCurFolio.DateTimeTo;
			cmGetServicesPeriodByFolio(vCurFolio, Ref, vDateFrom, vDateTo);
			vRStr = "";
			If ValueIsFilled(vCurFolio.Room) Then
				vRStr = TrimAll(vCurFolio.Room.Description);
			ElsIf ValueIsFilled(vSrvRow.Resource) Then
				vRStr = vSrvRow.Resource.GetObject().pmGetResourceDescription(SelLanguage);
			EndIf;
			mClient = mClient + 
			          ?(vCompany.OutputGuestPeriodInVATInvoice, ?(ValueIsFilled(vDateFrom), ", " + cmPeriodPresentation(vDateFrom, vDateTo), ""), "") + 
			          ?(IsBlankString(vRStr), "" , ", " + vRStr);
			// Set folio parameters
			vFolio.Parameters.mClient = mClient;
			// Put folio
			vSpreadsheet.Put(vFolio);
		EndIf;
		// Fill row parameters
		mAccountingDate = Format(vSrvRow.AccountingDate, "DF=dd.MM.yy");
		mPrice = vSrvRow.Price;
		mDescription = cmNStr(vSrvRow.Remarks, SelLanguage);
		mSum = vSrvRow.Sum;
		If Round(vSrvRow.Quantity, 3) <> vSrvRow.Quantity Then
			mQuantity = ?(vSrvRow.Quantity = 0, "", Format(vSrvRow.Quantity, "ND=17; NFD=3"));
		Else
			mQuantity = ?(vSrvRow.Quantity = 0, "", String(vSrvRow.Quantity));
		EndIf;
		If ValueIsFilled(vSrvRow.Service) Then
			If vSrvRow.Quantity <> 0 Then
				vServiceObj = vSrvRow.Service.GetObject();
				mQuantity = vServiceObj.pmGetServiceQuantityPresentation(vSrvRow.Quantity, SelLanguage);
			EndIf;
		EndIf;
		vTotalSum = vTotalSum + vSrvRow.Sum;
		vTotalVATSum = vTotalVATSum + vSrvRow.VATSum;
		// Set parameters
		If SelGroupBy <> "InPrice" And SelGroupBy <> "InPricePerFolio" And SelGroupBy <> "All" And SelGroupBy <> "AllPerFolio" And SelGroupBy <> "PerFolio" And SelGroupBy <> "ByService" Then
			vRow.Parameters.mAccountingDate = mAccountingDate;
		EndIf;
		vRow.Parameters.mPrice = Format(mPrice, "ND=17; NFD=2");
		vRow.Parameters.mQuantity = mQuantity;
		If SelGroupBy = "InPricePerFolio" Or SelGroupBy = "AllPerFolio" Or SelGroupBy = "PerFolio" Then
			vRow.Parameters.mDescription = Chars.Tab + mDescription;
		Else
			vRow.Parameters.mDescription = mDescription;
		EndIf;
		vRow.Parameters.mSum = Format(mSum, "ND=17; NFD=2");
		// Put row
		If Not IsBlankString(mSum) Then
			vSpreadsheet.Put(vRow);
		EndIf;
		
		If vAgentCommission = 0 Then
			vAgentCommission = vSrvRow.AgentCommission;
		EndIf;		
	EndDo;

	// Footer
	vFooter1 = vTemplate.GetArea("Footer1");
	vFooter2 = vTemplate.GetArea("Footer2");
	vFooter3 = vTemplate.GetArea("Footer3");
	
	// Fill parameters
	mTotalSum = cmFormatSum(vTotalSum, AccountingCurrency);
	If ValueIsFilled(vCompany) And vCompany.DoNotPrintVAT Then
		mTotalVATSum = "";
	Else
		If vTotalVATSum <> 0 Then
			mTotalVATSum = cmNStr("en = 'Including VAT '; de = 'Darunter MwSt. '; ru = 'В том числе НДС '", SelLanguage) + cmFormatSum(vTotalVATSum, AccountingCurrency);
		Else
			mTotalVATSum = cmNStr("en = 'No VAT'; de = 'MwSt. wird nicht berechnet'; ru = 'НДС не облагается'", SelLanguage);   
			If vServices.Count() > 0 Then
				vRowVatRate = vServices[0];
				If ValueIsFilled(vServices[0].VATRate) And  vServices[0].VATRate.NoVAT = False And vServices[0].VATRate.TaxRate = 0 Then
					mTotalVATSum = cmNStr("en = 'Including VAT '; de = 'Darunter MwSt. '; ru = 'НДС '", SelLanguage) + Format(vTotalVATSum, "ND=17; NFD=2; NZ=0.00") + " " + AccountingCurrency;
				EndIf;	
			EndIf;
		EndIf;
	EndIf;
	mTotalSumInWords = cmSumInWords(vTotalSum, AccountingCurrency, SelLanguage);
	// Set parameters
	vFooter2.Parameters.mRemarks = TrimAll(RemarksForPrinting);
	If SumDue > 0 And ValueIsFilled(CheckDate) And (ValueIsFilled(GuestGroup) And 
	   ValueIsFilled(GuestGroup.CheckInDate) And BegOfDay(GuestGroup.CheckInDate) >= BegOfDay(CheckDate) Or Not ValueIsFilled(GuestGroup)) Then
		vFooter2.Parameters.mRemarks = vFooter2.Parameters.mRemarks + ?(IsBlankString(vFooter2.Parameters.mRemarks), "", Chars.LF) + 
		                              ?(vDoNotShowPayDueDate, "", cmNStr("en='Payment before '; ru='Оплата до '; de='Zahlung vor '; lv='Apmaksāt līdz '", SelLanguage) + Format(CheckDate, "DF=dd.MM.yyyy"));
	EndIf;
	vFooter1.Parameters.mTotalSum = mTotalSum;
	vFooter1.Parameters.mTotalVATSum = mTotalVATSum;
	vFooter2.Parameters.mTotalSumInWords = mTotalSumInWords;
	
	// Put footer
	vSpreadsheet.Put(vFooter1);

	// Agent commision
	vTotalSumNoCommission = vTotalSum;
	If vTotalCommissionSum <> 0 And ValueIsFilled(AccountingCustomer) And Not AccountingCustomer.DoNotPostCommission Then
		vTotalSumNoCommission = vTotalSumNoCommission - vTotalCommissionSum;
		
		vCommision = vTemplate.GetArea("Commission");
		mAgentCommission = "";
		If vAgentCommission <> 0 Then
			If ValueIsFilled(GuestGroup) Then
				mAgentCommission = "" + GetAgentCommissionDescription(vAgentCommission, GuestGroup.ClientDoc, SelLanguage);
			Else
				mAgentCommission = "" + vAgentCommission + "%";
			EndIf;
		EndIf;
		If PerInvoiceCommission <> 0 Then
			mAgentCommission = mAgentCommission + ?(IsBlankString(mAgentCommission), "", ", ") + cmNStr("en='per invoice '; ru='по акту '; de='per Rechnung '", SelLanguage) + PerInvoiceCommission + "%";
		EndIf;
		mTotalCommissionSum = cmFormatSum(vTotalCommissionSum, AccountingCurrency);
		vCommision.Parameters.mTotalCommissionSum = mTotalCommissionSum;
		vCommision.Parameters.mAgentCommission = mAgentCommission;
		vCommision.Parameters.mTotalSumNoCommission = cmFormatSum(vTotalSumNoCommission, AccountingCurrency);
		// Put commission
		vSpreadsheet.Put(vCommision);
	EndIf;
	
	// Put footer
	vSpreadsheet.Put(vFooter2);
	
	// VAT rates table
	If ValueIsFilled(vCompany) And Not vCompany.IsUsingSimpleTaxSystem Then
		vVATHeaderArea = vTemplate.GetArea("VATHeader");
		vSpreadsheet.Put(vVATHeaderArea);
		vServices.GroupBy("VATRate", "Sum, VATSum");
		vServices.Sort("VATRate");
		vVATRateRowArea = vTemplate.GetArea("VATRateRow");
		For Each vSrvRow In vServices Do
			vVATRateRowArea.Parameters.mVATRate = TrimAll(vSrvRow.VATRate);
			vVATRateRowArea.Parameters.mSumWithoutVAT = Format(vSrvRow.Sum - vSrvRow.VATSum, "ND=17; NFD=2; NZ=");
			vVATRateRowArea.Parameters.mVATSum = Format(vSrvRow.VATSum, "ND=17; NFD=2; NZ=");
			vVATRateRowArea.Parameters.mSumWithVAT = Format(vSrvRow.Sum, "ND=17; NFD=2; NZ=");
			vSpreadsheet.Put(vVATRateRowArea);
		EndDo;
	EndIf;
	
	// Put footer
	vSpreadsheet.Put(vFooter3);
		
	// Simple tax system
	If vCompany.IsUsingSimpleTaxSystem Then
		vSTS = vTemplate.GetArea("SimpleTaxSystem");
		vSpreadsheet.Put(vSTS);
	EndIf;
	
	// Signatures
	vSignatures = vTemplate.GetArea("Signatures");
	// Company stamp and signatures
	If PrintWithCompanyStamp Then
		If vStampIsSet Then
			vSignatures.Drawings.Stamp.Print = True;
			vSignatures.Drawings.Stamp.Picture = vStamp;
		Else
			vSignatures.Drawings.Delete(vSignatures.Drawings.Stamp);
		EndIf;
		If vDirectorSignatureIsSet Then
			vSignatures.Drawings.DirectorSignature.Print = True;
			vSignatures.Drawings.DirectorSignature.Picture = vDirectorSignature;
		Else
			vSignatures.Drawings.Delete(vSignatures.Drawings.DirectorSignature);
		EndIf;
	Else
		vSignatures.Drawings.Delete(vSignatures.Drawings.Stamp);
		vSignatures.Drawings.Delete(vSignatures.Drawings.DirectorSignature);
	EndIf;
	vSpreadsheet.Put(vSignatures);

	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Portrait, True, , True);
	// Check authorities
	cmSetSpreadsheetProtection(vSpreadsheet);
EndProcedure // pmPrintSettlement

// -----------------------------------------------------------------------------
Procedure pmPrintSettlementHotelProducts(vSpreadsheet, SelLanguage, SelGroupBy, SelObjectPrintForm, pPageBreak = False) Export
	// Basic checks
	vHotel = Hotel;
	If Not ValueIsFilled(vHotel) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Hotel should be filled!'; de = 'Das Hotel ist nicht angegeben!'; ru = 'Не задана гостиница!'"), MessageStatus.Attention);
		Return;
	EndIf;
	vCompany = Company;
	If Not ValueIsFilled(vCompany) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Company should be filled!'; de = 'Die Firma ist nicht angegeben!'; ru = 'Не задана фирма!'"), MessageStatus.Attention);
		Return;
	EndIf;
	If Not ValueIsFilled(SelLanguage) Then
		SelLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	
	// Fill and check grouping parameter
	vParameter = Upper(TrimAll(SelObjectPrintForm.Parameter));
	vDoNotShowPayDueDate = (Find(vParameter, "DO_NOT_SHOW_PAY_DUE_DATE") > 0);
	
	// Choose template
	vSettlObj = ThisObject;
	If pPageBreak Then
		vSpreadsheet.PutHorizontalPageBreak();
	Else
		vSpreadsheet.Clear();
	EndIf;
	vTemplate = vSettlObj.GetTemplate("WayBill");
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(SelObjectPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;
	
	// Load pictures
	vStampIsSet = False;
	vStamp = New Picture;
	If ValueIsFilled(Company) Then
		If Company.Stamp <> Undefined Then
			vStamp = Company.Stamp.Get();
			If vStamp = Undefined Then
				vStamp = New Picture;
			Else
				vStampIsSet = True;
			EndIf;
		EndIf;
	EndIf;
	vDirectorSignatureIsSet = False;
	vDirectorSignature = New Picture;
	If Company.DirectorSignature <> Undefined Then
		vDirectorSignature = Company.DirectorSignature.Get();
		If vDirectorSignature = Undefined Then
			vDirectorSignature = New Picture;
		Else
			vDirectorSignatureIsSet = True;
		EndIf;
	EndIf;
	vAccountantGeneralSignatureIsSet = False;
	vAccountantGeneralSignature = New Picture;
	If Company.AccountantGeneralSignature <> Undefined Then
		vAccountantGeneralSignature = Company.AccountantGeneralSignature.Get();
		If vAccountantGeneralSignature = Undefined Then
			vAccountantGeneralSignature = New Picture;
		Else
			vAccountantGeneralSignatureIsSet = True;
		EndIf;
	EndIf;
	
	// Header
	vHeader = vTemplate.GetArea("Header");
	// Hotel
	vHotelObj = vHotel.GetObject();
	mHotelPrintName = vHotelObj.pmGetHotelPrintName(SelLanguage);
	mHotelPostAddressPresentation = vHotelObj.pmGetHotelPostAddressPresentation(SelLanguage);
	vHotelPhones = TrimAll(vHotel.Phones);
	vHotelFax = TrimAll(vHotel.Fax);
	mHotelPhones = vHotelPhones + ?(IsBlankString(vHotelFax), "", cmNStr("en = ', fax '; de = ', fax '; ru = ', факс '", SelLanguage) + vHotelFax);
	// Company
	vCompanyObj = vCompany.GetObject();
	vCompanyLegacyName = vCompanyObj.pmGetCompanyPrintName(SelLanguage);
	vCompanyLegacyAddress = vCompanyObj.pmGetCompanyLegacyAddressPresentation(SelLanguage);
	vCompanyPostAddress = vCompanyObj.pmGetCompanyPostAddressPresentation(SelLanguage);
	If vCompanyPostAddress = vCompanyLegacyAddress Then
		vCompanyPostAddress = "";
	EndIf;
	vCompanyTIN = TrimAll(vCompany.TIN);
	vCompanyKPP = TrimAll(vCompany.KPP);
	vCompanyTIN = cmNStr("en = ', TIN '; de = ', TIN '; ru = ', ИНН '", SelLanguage) + vCompanyTIN + ?(IsBlankString(vCompanyKPP), "", "/" + vCompanyKPP);
	mCompany = TrimAll(vCompanyLegacyName + vCompanyTIN + Chars.LF + vCompanyLegacyAddress + ?(IsBlankString(vCompanyPostAddress), "", Chars.LF + vCompanyPostAddress));
	// Settlement date and number
	mSettlementNumber = ?(vCompany.PrintInvoiceAndSettlementNumbersWithPrefixes, TrimAll(Number), cmGetDocumentNumberPresentation(Number));
	mSettlementDate = cmGetDocumentDatePresentation(Date);
	// Customer
	vCustomer = AccountingCustomer;
	vCustomerLegacyName = "";
	vCustomerLegacyAddress = "";
	vCustomerPostAddress = "";
	vCustomerCodes = "";
	vCustomerPhones = "";
	If ValueIsFilled(vCustomer) Then
		vCustomerLegacyName = TrimAll(vCustomer.LegacyName);
		If IsBlankString(vCustomerLegacyName) Then
			vCustomerLegacyName = TrimAll(vCustomer.Description);
		EndIf;
		vCustomerLegacyAddress = cmGetAddressPresentation(vCustomer.LegacyAddress);
		vCustomerPostAddress = cmGetAddressPresentation(vCustomer.PostAddress);
		If vCustomerPostAddress = vCustomerLegacyAddress Then
			vCustomerPostAddress = "";
		EndIf;
		vCustomerTIN = TrimAll(vCustomer.TIN);
		vCustomerKPP = TrimAll(vCustomer.KPP);
		vCustomerCodes = cmNStr("en='Reg. N';de='Reg. N';ru='ИНН'", SelLanguage) + ?(IsBlankString(vCustomerKPP), " ", cmNStr("en = '/KPP'; de = '/KPP'; ru = '/КПП'", SelLanguage)) + vCustomerTIN + ?(IsBlankString(vCustomerKPP), "", "/" + vCustomerKPP);
		// Fax and E-Mail
		vCustomerPhones = TrimAll(vCustomer.Phone);
		vCustomerFax = TrimAll(vCustomer.Fax);
		vCustomerPhones = vCustomerPhones + ?(IsBlankString(vCustomerFax), "", ?(IsBlankString(vCustomerPhones), "", ", ") + cmNStr("en = 'fax '; de = 'fax '; ru = 'факс '", SelLanguage) + vCustomerFax);
	EndIf;
	mCustomer = TrimAll(vCustomerLegacyName + ?(IsBlankString(vCustomerCodes), "", ", " + vCustomerCodes) + Chars.LF + vCustomerLegacyAddress + ?(IsBlankString(vCustomerPostAddress), "", Chars.LF + vCustomerPostAddress) + Chars.LF + vCustomerPhones);
	// Contract
	mContract = "";
	If ValueIsFilled(AccountingContract) Then
		mContract = TrimAll(AccountingContract.Description);
	EndIf;
	// Guest group code
	mGuestGroup = "";
	If ValueIsFilled(GuestGroup) Then
		mGuestGroup = Format(GuestGroup.Code, "ND=12; NFD=0");
		If ValueIsFilled(Hotel) Then
			vHotelPrefix = Catalogs.Hotels.pmGetPrefix(Hotel);
			If Not IsBlankString(vHotelPrefix) And Hotel.ShowHotelPrefixBeforeGroupCode Then
				mGuestGroup = vHotelPrefix + mGuestGroup;
			EndIf;
		EndIf;
		If Not IsBlankString(GuestGroup.ID) Then
			mGuestGroup = mGuestGroup + " - Ref. # " + TrimAll(GuestGroup.ID);
		ElsIf Not IsBlankString(GuestGroup.Description) Then
			mGuestGroup = mGuestGroup + " - " + TrimAll(GuestGroup.Description);
		EndIf;
	EndIf;
	// Currency
	mAccountingCurrency = "";
	If ValueIsFilled(AccountingCurrency) Then
		vCurrencyObj = AccountingCurrency.GetObject();
		mAccountingCurrency = vCurrencyObj.pmGetCurrencyDescription(SelLanguage);
	EndIf;
	// Parent document
	mParentDoc = String(ParentDoc);
	// Set parameters and put report section
	vHeader.Parameters.mHotelPrintName = mHotelPrintName;
	vHeader.Parameters.mHotelPostAddressPresentation = mHotelPostAddressPresentation;
	vHeader.Parameters.mHotelPhones = mHotelPhones;
	vHeader.Parameters.mSettlementNumber = mSettlementNumber;
	vHeader.Parameters.mSettlementDate = mSettlementDate;
	vHeader.Parameters.mCompany = mCompany;
	vHeader.Parameters.mCustomer = mCustomer;
	vHeader.Parameters.mContract = mContract;
	vHeader.Parameters.mGuestGroup = mGuestGroup;
	vHeader.Parameters.mAccountingCurrency = mAccountingCurrency;
	vHeader.Parameters.mParentDoc = mParentDoc;
	vSpreadsheet.Put(vHeader);
	
	// Get template areas
	vFolio = vTemplate.GetArea("Folio");
	vRow = vTemplate.GetArea("Row");
	
	// Get all services
	vServices = Documents.Settlement.MergeCorrections(Services);
	
	// Change accounting dates for breakfast
	If Not IsBlankString(SelGroupBy) And SelGroupBy <> "ByService" Then
		For Each vSrvRow In vServices Do
			If vSrvRow.IsInPrice And ValueIsFilled(vSrvRow.Service.QuantityCalculationRule) And
			   vSrvRow.Service.QuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.Breakfast Then
				If ValueIsFilled(vSrvRow.Folio) And BegOfDay(vSrvRow.AccountingDate) > BegOfDay(vSrvRow.Folio.DateTimeFrom) Then
					vSrvRow.AccountingDate = vSrvRow.AccountingDate - 24 * 3600;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	// Join services according to service parameters
	If Not IsBlankString(SelGroupBy) And SelGroupBy <> "ByService" Then
		// Try to replace accommodation service to the one that should be used for printing
		vChargeParentDoc = Undefined;
		vAccountingDate = '00010101';
		vFirstRoomRateService = Undefined;
		vFirstRoomRateServiceIsFound = False;
		For Each vSrvRow In vServices Do
			vSrvRowService = vSrvRow.Service;
			If ValueIsFilled(vSrvRowService) Then
				If vChargeParentDoc <> vSrvRow.ParentDoc Then
					vChargeParentDoc = vSrvRow.ParentDoc;
					vAccountingDate = '00010101';
					vFirstRoomRateService = Undefined;
					vFirstRoomRateServiceIsFound = False;
				EndIf;
				If vAccountingDate <> BegOfDay(vSrvRow.AccountingDate) Then
					vAccountingDate = BegOfDay(vSrvRow.AccountingDate);
					vFirstRoomRateService = Undefined;
					vFirstRoomRateServiceIsFound = False;
				EndIf;
				If vSrvRowService.IsRoomRevenue And vSrvRowService.IsInPrice And Not vSrvRowService.RoomRevenueAmountsOnly Then
					If ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
						vSrvRow.Service = vSrvRowService.HideIntoServiceOnPrint;
					EndIf;
					If Not vFirstRoomRateServiceIsFound Then
						vFirstRoomRateService = vSrvRowService;
						vFirstRoomRateServiceIsFound = True;
					Else
						If vFirstRoomRateService <> vSrvRowService And ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
							vSrvRow.Quantity = 0;
						EndIf;
					EndIf;
				ElsIf vSrvRowService.DoNotGroupIntoRoomRateOnPrint And ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
					vSrvRow.Service = vSrvRowService.HideIntoServiceOnPrint;
				EndIf;
			EndIf;
		EndDo;
		// Try to merge other services to the accommodation service
		vInt = 0;
		While vInt < vServices.Count() Do
			vSrvRow = vServices.Get(vInt);
			vSrvRowService = vSrvRow.Service;
			If ValueIsFilled(vSrvRowService) And ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
				If Not vSrvRowService.DoNotGroupIntoRoomRateOnPrint Then
					vHideToServices = vServices.FindRows(New Structure("Service, AccountingDate, Folio", vSrvRowService.HideIntoServiceOnPrint, vSrvRow.AccountingDate, vSrvRow.Folio));
					If vHideToServices.Count() = 0 Then
						vHideToServices = vServices.FindRows(New Structure("Service, AccountingDate, Folio", vSrvRowService.HideIntoServiceOnPrint, vSrvRow.AccountingDate - 24 * 3600, vSrvRow.Folio));
					EndIf;
					If vHideToServices.Count() > 0 Then
						vSrv2Hide2 = vHideToServices.Get(0);
						vSrv2Hide2.Sum = vSrv2Hide2.Sum + vSrvRow.Sum;
						vSrv2Hide2.VATSum = vSrv2Hide2.VATSum + vSrvRow.VATSum;
						vSrv2Hide2.Price = cmRecalculatePrice(vSrv2Hide2.Sum, vSrv2Hide2.Quantity);
						// Delete current service
						vServices.Delete(vInt);
						Continue;
					EndIf;
				EndIf;
			EndIf;
			vInt = vInt + 1;
		EndDo;
	EndIf;
	
	// Get accommodation service name
	vAccommodationService = Undefined;	
	vAccommodationServiceRemarks = "";	
	vAccommodationRemarks = "";	
	vAccommodationServiceVATRate = Undefined;
	vInt = 0;
	While vInt < vServices.Count() Do
		vSrvRow = vServices.Get(vInt);
		If SelGroupBy = "InPricePerFolioPerDay" Or SelGroupBy = "InPricePerDay" 
		   Or SelGroupBy = "AllPerFolioPerDay" Or SelGroupBy = "AllPerDay" 
		   Or SelGroupBy = "InPricePerFolio" Or SelGroupBy = "InPrice" 
		   Or SelGroupBy = "AllPerFolio" Or SelGroupBy = "All" Then
			If vSrvRow.Sum = 0 Then
				vServices.Delete(vInt);
				Continue;
			EndIf;
		EndIf;
		If vAccommodationService = Undefined And ValueIsFilled(vSrvRow.Service) And vSrvRow.IsInPrice And vSrvRow.IsRoomRevenue And Not vSrvRow.Service.RoomRevenueAmountsOnly Then
			vAccommodationService = vSrvRow.Service;
			vAccommodationServiceVATRate = vSrvRow.VATRate;
			vAccommodationServiceObj = vSrvRow.Service.GetObject();
			vAccommodationServiceRemarks = vAccommodationServiceObj.pmGetServiceDescription(SelLanguage, False);
			vAccommodationRemarks = vAccommodationServiceObj.pmGetServiceDescription(SelLanguage, True);
		EndIf;
		vInt = vInt + 1;
	EndDo;
	
	// Fill hotel product from charges
	If vServices.Columns.Find("HotelProduct") = Undefined Then
		vServices.Columns.Add("HotelProduct", cmGetCatalogTypeDescription("HotelProducts"));
	EndIf;
	For Each vServicesRow In vServices Do
		If ValueIsFilled(vServicesRow.Charge) And ValueIsFilled(vServicesRow.Charge.HotelProduct) Then
			vServicesRow.HotelProduct = vServicesRow.Charge.HotelProduct;
		EndIf;
	EndDo;
	
	// Get list of hotel products
	vHotelProducts = vServices.Copy(, "HotelProduct");
	vHotelProducts.GroupBy("HotelProduct", );
	
	// Print service name and hotel product type
	If Not IsBlankString(vAccommodationRemarks) Then
		vRow.Parameters.mDescription = vAccommodationRemarks;
		// Try to get first hotel product type
		For Each vHotelProductsRow In vHotelProducts Do
			vHotelProduct = vHotelProductsRow.HotelProduct;
			If ValueIsFilled(vHotelProduct) Then
				vRow.Parameters.mDescription = vRow.Parameters.mDescription + ?(ValueIsFilled(vHotelProduct.Parent), ", " + TrimAll(vHotelProduct.Parent), "");
				Break;
			EndIf;
		EndDo;
		vSpreadsheet.Put(vRow);
	EndIf;
	
	// Initialize totals
	vTotalSum = 0;
	vTotalVATSum = 0;
	vTotalQuantity = 0;
	
	// Do for each hotel product in the list
	For Each vHotelProductsRow In vHotelProducts Do
		vHotelProduct = vHotelProductsRow.HotelProduct;
		
		// Choose services for this current hotel product
		vHPServicesArray = vServices.FindRows(New Structure("HotelProduct", vHotelProduct));
		If vHPServicesArray.Count() > 0 Then
			vHPServices = vServices.CopyColumns();
			For Each vHPServicesArrayRow In vHPServicesArray Do
				vHPServicesRow = vHPServices.Add();
				FillPropertyValues(vHPServicesRow, vHPServicesArrayRow);
			EndDo;
					
			// Group by all services to the one accommodation service
			For Each vSrvRow In vHPServices Do
				vSrvRow.AccountingDate = BegOfDay(Date);
				vSrvRow.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
				vSrvRow.Room = Catalogs.Rooms.EmptyRef();
				If SelGroupBy = "All" Then
					vSrvRow.Folio = Documents.Folio.EmptyRef();
				EndIf;
				If ValueIsFilled(vAccommodationService) And vAccommodationServiceVATRate = vSrvRow.VATRate Then
					If vSrvRow.Service.RoomRevenueAmountsOnly Then
						vSrvRow.Quantity = 0;
						vSrvRow.Price = 0;
					EndIf;
					vSrvRow.Service = ?(ValueIsFilled(vAccommodationService), vAccommodationService, vSrvRow.Service);
					If Not vSrvRow.IsRoomRevenue Then
						vSrvRow.Quantity = ?(IsBlankString(vAccommodationRemarks), vSrvRow.Quantity, 0);
						vSrvRow.Price = 0;
					EndIf;
					If Not IsBlankString(vAccommodationRemarks) Then
						If StrFind(SelGroupBy,  "PerFolio") = 0 Then
							vSrvRow.Remarks = vAccommodationRemarks;
						Else
							vSrvRow.Remarks = StrReplace(TrimAll(vSrvRow.Remarks), vAccommodationServiceRemarks, vAccommodationRemarks);
						EndIf;
					Else
						vSrvRow.Remarks = TrimAll(vSrvRow.Remarks);
					EndIf;
				EndIf;
			EndDo;
			// Group by transactions
			vHPServices.GroupBy("Folio, AccountingDate, Service, CalendarDayType, Room, Resource, Remarks, VATRate", "Sum, VATSum, Price, Quantity");
			// Recalculate price for all services
			For Each vSrvRow In vHPServices Do
				vSrvRow.Price = cmRecalculatePrice(vSrvRow.Sum, vSrvRow.Quantity);
			EndDo;
			vHPServices.Sort("Folio, AccountingDate");
	
			// Print hotel product
			If ValueIsFilled(vHotelProduct) Then
				// Fill hotel product parameters
				mDescription = Chars.Tab + "№" + TrimAll(vHotelProduct.Description);
				If ValueIsFilled(vHotelProduct.CheckInDate) And ValueIsFilled(vHotelProduct.CheckOutDate) Then
					mDescription = mDescription + Chars.Tab + Chars.Tab + Chars.Tab  
					               + Format(vHotelProduct.CheckInDate, "DF='dd.MM.yy'") + " - " 
					               + Format(vHotelProduct.CheckOutDate, "DF='dd.MM.yy'");
				EndIf;
				mPrice = vHPServices.Total("Sum");
				mSum = mPrice;
				mQuantity = 1;
				vTotalSum = vTotalSum + vSrvRow.Sum;
				vTotalVATSum = vTotalVATSum + cmCalculateVATSum(vSrvRow.VATRate, vSrvRow.Sum, vSrvRow.AccountingDate);
				vTotalQuantity = vTotalQuantity + 1;
				// Set parameters
				vRow.Parameters.mDescription = mDescription;
				vRow.Parameters.mQuantity = mQuantity;
				vRow.Parameters.mPrice = Format(mPrice, "ND=17; NFD=2");
				vRow.Parameters.mSum = Format(mSum, "ND=17; NFD=2");
				// Put row
				If Not IsBlankString(mSum) Then
					vSpreadsheet.Put(vRow);
				EndIf;
				// Print guest names if services are grouped be folio
				If SelGroupBy = "AllPerFolio" Then
					vCurFolio = Documents.Folio.EmptyRef();
					For Each vSrvRow In vHPServices Do
						If vSrvRow.Folio <> vCurFolio Then
							vCurFolio = vSrvRow.Folio;
							// Fill client parameters
							mClient = "";
							If ValueIsFilled(vCurFolio.Client) Then
								mClient = TrimAll(TrimAll(vCurFolio.Client.LastName) + " " + TrimAll(vCurFolio.Client.FirstName) + " " + TrimAll(vCurFolio.Client.SecondName));
							ElsIf ValueIsFilled(vCurFolio.Customer) Then
								If Not IsBlankString(vCurFolio.Customer.LegacyName) Then
									mClient = TrimAll(vCurFolio.Customer.LegacyName);
								Else
									mClient = TrimAll(vCurFolio.Customer.Description);
								EndIf;
							EndIf;
							// Set folio parameters
							vFolio.Parameters.mClient = Chars.Tab + Chars.Tab + mClient;
							// Put folio
							vSpreadsheet.Put(vFolio);
						EndIf;
					EndDo;
				EndIf;
			Else
				vCurFolio = Documents.Folio.EmptyRef();
				For Each vSrvRow In vHPServices Do
					// Print folio header if necessary
					If vSrvRow.Folio <> vCurFolio Then
						vCurFolio = vSrvRow.Folio;
						// Fill folio parameters
						mClient = "";
						If ValueIsFilled(vCurFolio.Client) Then
							mClient = TrimAll(TrimAll(vCurFolio.Client.LastName) + " " + TrimAll(vCurFolio.Client.FirstName) + " " + TrimAll(vCurFolio.Client.SecondName));
						ElsIf ValueIsFilled(vCurFolio.Customer) Then
							If Not IsBlankString(vCurFolio.Customer.LegacyName) Then
								mClient = TrimAll(vCurFolio.Customer.LegacyName);
							Else
								mClient = TrimAll(vCurFolio.Customer.Description);
							EndIf;
						EndIf;
						vDateFrom = vCurFolio.DateTimeFrom;
						vDateTo = vCurFolio.DateTimeTo;
						cmGetServicesPeriodByFolio(vCurFolio, Ref, vDateFrom, vDateTo);
						vRStr = "";
						If ValueIsFilled(vCurFolio.Room) Then
							vRStr = TrimAll(vCurFolio.Room.Description);
						ElsIf ValueIsFilled(vSrvRow.Resource) Then
							vRStr = vSrvRow.Resource.GetObject().pmGetResourceDescription(SelLanguage);
						EndIf;
						mClient = mClient + 
						          ?(vCompany.OutputGuestPeriodInVATInvoice, ?(ValueIsFilled(vDateFrom), ", " + cmPeriodPresentation(vDateFrom, vDateTo), ""), "") + 
						          ?(IsBlankString(vRStr), "" , ", " + vRStr);
						// Set folio parameters
						vFolio.Parameters.mClient = mClient;
						// Put folio
						vSpreadsheet.Put(vFolio);
					EndIf;
					// Fill row parameters
					mPrice = vSrvRow.Price;
					mDescription = cmNStr(vSrvRow.Remarks, SelLanguage);
					mSum = vSrvRow.Sum;
					If Round(vSrvRow.Quantity, 3) <> vSrvRow.Quantity Then
						mQuantity = ?(vSrvRow.Quantity = 0, "", Format(vSrvRow.Quantity, "ND=17; NFD=3"));
					Else
						mQuantity = ?(vSrvRow.Quantity = 0, "", String(vSrvRow.Quantity));
					EndIf;
					If ValueIsFilled(vSrvRow.Service) Then
						If vSrvRow.Quantity <> 0 Then
							vServiceObj = vSrvRow.Service.GetObject();
							mQuantity = vServiceObj.pmGetServiceQuantityPresentation(vSrvRow.Quantity, SelLanguage);
						EndIf;
					EndIf;
					vTotalSum = vTotalSum + vSrvRow.Sum;
					vTotalVATSum = vTotalVATSum + cmCalculateVATSum(vSrvRow.VATRate, vSrvRow.Sum, vSrvRow.AccountingDate);
					// Set parameters
					vRow.Parameters.mPrice = Format(mPrice, "ND=17; NFD=2");
					vRow.Parameters.mQuantity = mQuantity;
					If SelGroupBy = "AllPerFolio" Then
						vRow.Parameters.mDescription = Chars.Tab + mDescription;
					Else
						vRow.Parameters.mDescription = mDescription;
					EndIf;
					vRow.Parameters.mSum = Format(mSum, "ND=17; NFD=2");
					// Put row
					If Not IsBlankString(mSum) Then
						vSpreadsheet.Put(vRow);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndDo;
	
	// Footer
	vFooter = vTemplate.GetArea("Footer");
	// Fill parameters
	mTotalSum = Format(vTotalSum, "ND=17; NFD=2");
	If ValueIsFilled(vCompany) And vCompany.DoNotPrintVAT Then
		mTotalVATSum = "";
	Else
		If vTotalVATSum <> 0 Then
			mTotalVATSum = cmNStr("en = 'Including VAT '; de = 'Darunter MwSt. '; ru = 'В том числе НДС '", SelLanguage) + Format(vTotalVATSum, "ND=17; NFD=2");
		Else
			mTotalVATSum = cmNStr("en = 'No VAT'; de = 'MwSt. wird nicht berechnet'; ru = 'НДС не облагается'", SelLanguage);  
			If vServices.Count() > 0 Then
				vRowVatRate = vServices[0];
				If ValueIsFilled(vServices[0].VATRate) And  vServices[0].VATRate.NoVAT = False And vServices[0].VATRate.TaxRate = 0 Then
					mTotalVATSum = cmNStr("en = 'Including VAT '; de = 'Darunter MwSt. '; ru = 'НДС '", SelLanguage) + Format(vTotalVATSum, "ND=17; NFD=2; NZ=0.00") + " " + AccountingCurrency;
				EndIf;	
			EndIf;

		EndIf;
	EndIf;
	mTotalSumInWords = cmSumInWords(vTotalSum, AccountingCurrency, SelLanguage);
	mTotalQuantity = Format(vTotalQuantity, "ND=17; NFD=0");
	// Set parameters
	vFooter.Parameters.mRemarks = TrimAll(RemarksForPrinting);
	If SumDue > 0 And ValueIsFilled(CheckDate) And (ValueIsFilled(GuestGroup) And 
	   ValueIsFilled(GuestGroup.CheckInDate) And BegOfDay(GuestGroup.CheckInDate) >= BegOfDay(CheckDate) Or Not ValueIsFilled(GuestGroup)) Then
		vFooter.Parameters.mRemarks = vFooter.Parameters.mRemarks + ?(IsBlankString(vFooter.Parameters.mRemarks), "", Chars.LF) + 
		                              ?(vDoNotShowPayDueDate, "", cmNStr("en='Payment before '; ru='Оплата до '; de='Zahlung vor '; lv='Apmaksāt līdz '", SelLanguage) + Format(CheckDate, "DF=dd.MM.yyyy"));
	EndIf;
	vFooter.Parameters.mTotalSum = mTotalSum;
	vFooter.Parameters.mTotalVATSum = mTotalVATSum;
	vFooter.Parameters.mTotalSumInWords = mTotalSumInWords;
	vFooter.Parameters.mTotalQuantity = mTotalQuantity;
	// Put footer
	vSpreadsheet.Put(vFooter);
	
	// VAT rates table
	If ValueIsFilled(vCompany) And Not vCompany.IsUsingSimpleTaxSystem Then
		vVATHeaderArea = vTemplate.GetArea("VATHeader");
		vSpreadsheet.Put(vVATHeaderArea);
		vServices.GroupBy("VATRate", "Sum, VATSum");
		vServices.Sort("VATRate");
		vVATRateRowArea = vTemplate.GetArea("VATRateRow");
		For Each vSrvRow In vServices Do
			vVATRateRowArea.Parameters.mVATRate = TrimAll(vSrvRow.VATRate);
			vVATRateRowArea.Parameters.mSumWithoutVAT = Format(vSrvRow.Sum - vSrvRow.VATSum, "ND=17; NFD=2; NZ=");
			vVATRateRowArea.Parameters.mVATSum = Format(vSrvRow.VATSum, "ND=17; NFD=2; NZ=");
			vVATRateRowArea.Parameters.mSumWithVAT = Format(vSrvRow.Sum, "ND=17; NFD=2; NZ=");
			vSpreadsheet.Put(vVATRateRowArea);
		EndDo;
	EndIf;
	
	// Signatures
	vSignatures = vTemplate.GetArea("Signatures");
	vSignatures.Parameters.mDirectorPosition = cmNStr("en='Director general';ru='Генеральный директор';de='Generaldirektor'", SelLanguage);
	If Not IsBlankString(vCompany.RKODirectorPosition) Then
		vSignatures.Parameters.mDirectorPosition = cmNStr(vCompany.RKODirectorPosition, SelLanguage);
	EndIf;
	vSignatures.Parameters.mDirector = cmNStr(vCompany.Director, SelLanguage);
	vSignatures.Parameters.mAccountant = cmNStr(vCompany.AccountantGeneral, SelLanguage);
	// Company stamp and signatures
	If PrintWithCompanyStamp Then
		If vStampIsSet Then
			vSignatures.Drawings.Stamp.Print = True;
			vSignatures.Drawings.Stamp.Picture = vStamp;
		Else
			vSignatures.Drawings.Delete(vSignatures.Drawings.Stamp);
		EndIf;
		If vDirectorSignatureIsSet Then
			vSignatures.Drawings.DirectorSignature.Print = True;
			vSignatures.Drawings.DirectorSignature.Picture = vDirectorSignature;
		Else
			vSignatures.Drawings.Delete(vSignatures.Drawings.DirectorSignature);
		EndIf;
		If vAccountantGeneralSignatureIsSet Then
			vSignatures.Drawings.AccountantGeneralSignature.Print = True;
			vSignatures.Drawings.AccountantGeneralSignature.Picture = vAccountantGeneralSignature;
		Else
			vSignatures.Drawings.Delete(vSignatures.Drawings.AccountantGeneralSignature);
		EndIf;
	Else
		vSignatures.Drawings.Delete(vSignatures.Drawings.Stamp);
		vSignatures.Drawings.Delete(vSignatures.Drawings.DirectorSignature);
		vSignatures.Drawings.Delete(vSignatures.Drawings.AccountantGeneralSignature);
	EndIf;
	vSpreadsheet.Put(vSignatures);

	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Portrait, True, , True);
	// Check authorities
	cmSetSpreadsheetProtection(vSpreadsheet);
EndProcedure // pmPrintSettlementHotelProducts

// -----------------------------------------------------------------------------
Procedure pmPrintSettlement7G(vSpreadsheet, SelLanguage, SelGroupBy, SelObjectPrintForm, pPageBreak = False) Export
	// Basic checks
	vHotel = Hotel;
	If Not ValueIsFilled(vHotel) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Hotel should be filled!';ru='Не задана гостиница!';de='Das Hotel ist nicht angegeben!'"), MessageStatus.Attention);
		Return;
	EndIf;
	vCompany = Company;
	If Not ValueIsFilled(vCompany) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Company should be filled!';ru='Не задана фирма!';de='Die Firma ist nicht angegeben!'"), MessageStatus.Attention);
		Return;
	EndIf;
	If Not ValueIsFilled(SelLanguage) Then
		SelLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	
	// Fill and check grouping parameter
	vParameter = Upper(TrimAll(SelObjectPrintForm.Parameter));
	
	// Choose template
	vSettlObj = ThisObject;
	If pPageBreak Then
		vSpreadsheet.PutHorizontalPageBreak();
	Else
		vSpreadsheet.Clear();
	EndIf;
	If ValueIsFilled(SelLanguage) Then
		If SelLanguage = Catalogs.Languages.EN Then
			vTemplate = vSettlObj.GetTemplate("Settlement7GEn");
		ElsIf SelLanguage = Catalogs.Languages.RU Then
			vTemplate = vSettlObj.GetTemplate("Settlement7GRu");
		Else  
			vErrMsg = StrTemplate(NStr("en = 'No settlement print form template found for the %1 language!'; 
									   |de = 'No settlement print form template found for the %1 language!'; 
									   |ru = 'Не найден шаблон печатной формы акта для языка %1!'"), SelLanguage.Code);
			tcCommonFunctionOnClientServer.TextMessage(vErrMsg, MessageStatus.Attention);
			Return;
		EndIf;
	Else
		vTemplate = vSettlObj.GetTemplate("Settlement7GRu");
	EndIf;
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(SelObjectPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;
	
	// Load managers signature
	vSignatureIsSet = False;
	vSignature = New Picture;
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		If SessionParameters.CurrentUser.Signature <> Undefined Then
			vSignature = SessionParameters.CurrentUser.Signature.Get();
			If vSignature = Undefined Then
				vSignature = New Picture;
			Else
				vSignatureIsSet = True;
			EndIf;
		EndIf;
	EndIf;
	
	// Basic initialization
	vBegOfMonth = BegOfMonth(Date);
	vEndOfMonth = BegOfDay(EndOfMonth(Date)) + 24 * 3600;
	
	// Header
	// 3G, 9G, 12G Headers
	vHeader = vTemplate.GetArea("Header");
	If SelLanguage = Catalogs.Languages.RU Then
		If vHotel.PrintGHeaders Then
			vHeader = vTemplate.GetArea("GHeader");
		EndIf;
	EndIf;
	// Company
	vCompanyObj = vCompany.GetObject();
	vCompanyLegacyName = vCompanyObj.pmGetCompanyPrintName(SelLanguage);
	vCompanyLegacyAddress = vCompanyObj.pmGetCompanyLegacyAddressPresentation(SelLanguage);
	vCompanyTIN = TrimAll(vCompany.TIN);
	vCompanyKPP = TrimAll(vCompany.KPP);
	// Customer
	vCustomer = AccountingCustomer;
	vCustomerLegacyName = "";
	If ValueIsFilled(vCustomer) Then
		vCustomerLegacyName = TrimAll(vCustomer.LegacyName);
		If IsBlankString(vCustomerLegacyName) Then
			vCustomerLegacyName = TrimAll(vCustomer.Description);
		EndIf;
	EndIf;
	// Guest group
	vGuestGroup = GuestGroup;
	vGuestGroupCode = "";
	vGuestGroupDescription = "";
	vGuestGroupDate = "";
	If ValueIsFilled(vGuestGroup) Then
		vGuestGroupCode = TrimAll(vGuestGroup.Code);
		If ValueIsFilled(Hotel) Then
			vHotelPrefix = Catalogs.Hotels.pmGetPrefix(Hotel);
			If Not IsBlankString(vHotelPrefix) And Hotel.ShowHotelPrefixBeforeGroupCode Then
				vGuestGroupCode = vHotelPrefix + vGuestGroupCode;
			EndIf;
		EndIf;
		vGuestGroupDescription = TrimAll(vGuestGroup.Description);
		// Retrieve guest group date
		vGuestGroupObj = vGuestGroup.GetObject();
		vReservations = vGuestGroupObj.pmGetReservations();
		For Each vReservationsRow In vReservations Do
			vGuestGroupDate = vReservationsRow.Reservation.Date;
			Break;
		EndDo;
	EndIf;
	// Currency
	vAccountingCurrency = "";
	If ValueIsFilled(AccountingCurrency) Then
		vCurrencyObj = AccountingCurrency.GetObject();
		vAccountingCurrency = vCurrencyObj.pmGetCurrencyDescription(SelLanguage);
	EndIf;
	// Set parameters and put report section
	vHeader.Parameters.mCompanyLegacyName = vCompanyLegacyName;
	vHeader.Parameters.mCompanyLegacyAddress = vCompanyLegacyAddress;
	vHeader.Parameters.mCompanyTIN = vCompanyTIN;
	vHeader.Parameters.mCompanyKPP = vCompanyKPP;
	vHeader.Parameters.mGuestGroupCode = vGuestGroupCode;
	vHeader.Parameters.mGuestGroupDescription = vGuestGroupDescription;
	vHeader.Parameters.mGuestGroupDate = Format(vGuestGroupDate, "DF=dd.MM.yyyy");
	vHeader.Parameters.mCustomerLegacyName = vCustomerLegacyName;
	vHeader.Parameters.mAccountingCurrency = vAccountingCurrency;
	// Print header
	vSpreadsheet.Put(vHeader);
	
	// Get template areas
	vClient = vTemplate.GetArea("Client");
	vClientTotal = vTemplate.GetArea("ClientTotal");
	vService = vTemplate.GetArea("Service");
	vRoomRevenueService = vTemplate.GetArea("RoomRevenueService");
	
	// Get all services
	vServices = Documents.Settlement.MergeCorrections(Services);
	
	// Change accounting dates for breakfast
	If Not IsBlankString(SelGroupBy) And SelGroupBy <> "ByService" Then
		For Each vSrvRow In vServices Do
			If vSrvRow.IsInPrice And ValueIsFilled(vSrvRow.Service.QuantityCalculationRule) And
			   vSrvRow.Service.QuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.Breakfast Then
				If ValueIsFilled(vSrvRow.Folio) And BegOfDay(vSrvRow.AccountingDate) > BegOfDay(vSrvRow.Folio.DateTimeFrom) Then
					vSrvRow.AccountingDate = vSrvRow.AccountingDate - 24 * 3600;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	// Join services according to service parameters
	If Not IsBlankString(SelGroupBy) And SelGroupBy <> "ByService" Then
		// Try to replace accommodation service to the one that should be used for printing
		vChargeParentDoc = Undefined;
		vAccountingDate = '00010101';
		vFirstRoomRateService = Undefined;
		vFirstRoomRateServiceIsFound = False;
		For Each vSrvRow In vServices Do
			vSrvRowService = vSrvRow.Service;
			If ValueIsFilled(vSrvRowService) Then
				If vChargeParentDoc <> vSrvRow.ParentDoc Then
					vChargeParentDoc = vSrvRow.ParentDoc;
					vAccountingDate = '00010101';
					vFirstRoomRateService = Undefined;
					vFirstRoomRateServiceIsFound = False;
				EndIf;
				If vAccountingDate <> BegOfDay(vSrvRow.AccountingDate) Then
					vAccountingDate = BegOfDay(vSrvRow.AccountingDate);
					vFirstRoomRateService = Undefined;
					vFirstRoomRateServiceIsFound = False;
				EndIf;
				If vSrvRowService.IsRoomRevenue And vSrvRowService.IsInPrice And Not vSrvRowService.RoomRevenueAmountsOnly Then
					If ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
						vSrvRow.Service = vSrvRowService.HideIntoServiceOnPrint;
					EndIf;
					If Not vFirstRoomRateServiceIsFound Then
						vFirstRoomRateService = vSrvRowService;
						vFirstRoomRateServiceIsFound = True;
					Else
						If vFirstRoomRateService <> vSrvRowService And ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
							vSrvRow.Quantity = 0;
						EndIf;
					EndIf;
				ElsIf vSrvRowService.DoNotGroupIntoRoomRateOnPrint And ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
					vSrvRow.Service = vSrvRowService.HideIntoServiceOnPrint;
				EndIf;
			EndIf;
		EndDo;
		// Try to merge other services to the accommodation service
		vInt = 0;
		While vInt < vServices.Count() Do
			vSrvRow = vServices.Get(vInt);
			vSrvRowService = vSrvRow.Service;
			If ValueIsFilled(vSrvRowService) And ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
				If Not vSrvRowService.DoNotGroupIntoRoomRateOnPrint Then
					vHideToServices = vServices.FindRows(New Structure("Service, AccountingDate, Folio", vSrvRowService.HideIntoServiceOnPrint, vSrvRow.AccountingDate, vSrvRow.Folio));
					If vHideToServices.Count() = 0 Then
						vHideToServices = vServices.FindRows(New Structure("Service, AccountingDate, Folio", vSrvRowService.HideIntoServiceOnPrint, vSrvRow.AccountingDate - 24 * 3600, vSrvRow.Folio));
					EndIf;
					If vHideToServices.Count() > 0 Then
						vSrv2Hide2 = vHideToServices.Get(0);
						vSrv2Hide2.Sum = vSrv2Hide2.Sum + vSrvRow.Sum;
						vSrv2Hide2.VATSum = vSrv2Hide2.VATSum + vSrvRow.VATSum;
						vSrv2Hide2.Price = cmRecalculatePrice(vSrv2Hide2.Sum, vSrv2Hide2.Quantity);
						// Delete current service
						vServices.Delete(vInt);
						Continue;
					EndIf;
				EndIf;
			EndIf;
			vInt = vInt + 1;
		EndDo;
	EndIf;
	
	// Search for min/max accounting dates
	vAllServicesAreInOneMonth = True;
	vMinMaxServices = vServices.Copy();
	vMinMaxServices.Sort("AccountingDate");
	If vMinMaxServices.Count() > 0 Then
		vFirstRow = vMinMaxServices.Get(0);
		vLastRow = vMinMaxServices.Get(vMinMaxServices.Count() - 1);
		If vFirstRow.AccountingDate < vBegOfMonth Or vLastRow.AccountingDate > (vEndOfMonth - 1) Then
			vAllServicesAreInOneMonth = False;
		EndIf;
	EndIf;
	
	// Get accommodation service name
	vRoomRevenueServices = vServices.Copy();
	vAccommodationService = Undefined;	
	vAccommodationServiceRemarks = "";	
	vAccommodationRemarks = "";	
	vAccommodationServiceVATRate = Undefined;
	vInt = 0;
	While vInt < vServices.Count() Do
		vSrvRow = vServices.Get(vInt);
		If SelGroupBy = "InPricePerFolioPerDay" Or SelGroupBy = "InPricePerDay" 
		   Or SelGroupBy = "AllPerFolioPerDay" Or SelGroupBy = "AllPerDay" 
		   Or SelGroupBy = "InPricePerFolio" Or SelGroupBy = "InPrice" 
		   Or SelGroupBy = "AllPerFolio" Or SelGroupBy = "All" Then
			If Find(vParameter, "SHOWZEROES") = 0 Then
				If vSrvRow.Sum = 0 Then
					vServices.Delete(vInt);
					Continue;
				EndIf;
			EndIf;
		EndIf;
		If vAccommodationService = Undefined And vSrvRow.IsInPrice And vSrvRow.IsRoomRevenue And Not vSrvRow.Service.RoomRevenueAmountsOnly Then
			vAccommodationService = vSrvRow.Service;
			vAccommodationServiceVATRate = vSrvRow.VATRate;
			vAccommodationServiceRemarks = vAccommodationService.GetObject().pmGetServiceDescription(SelLanguage, False);
			vAccommodationRemarks = vAccommodationService.GetObject().pmGetServiceDescription(SelLanguage, True);
		EndIf;
		vInt = vInt + 1;
	EndDo;
	
	// Group by services according to the settlement print type
	If Not IsBlankString(SelGroupBy) Then
		If SelGroupBy = "ByServicePerFolio" Then
			For Each vSrvRow In vServices Do
				vSrvRow.AccountingDate = BegOfDay(Date);
			EndDo;
		ElsIf SelGroupBy = "InPricePerFolio" Then
			For Each vSrvRow In vServices Do
				// Reset "is in price" flag if necessary
				If ValueIsFilled(vSrvRow.Service) And vSrvRow.Service.DoNotGroupIntoRoomRateOnPrint Then
					vSrvRow.IsInPrice = False;
				EndIf;
				vSrvRow.AccountingDate = BegOfDay(Date);
				If ValueIsFilled(vAccommodationService) And vAccommodationServiceVATRate = vSrvRow.VATRate Then
					If Not vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice Then
						vSrvRow.Service = vAccommodationService;
						vSrvRow.Quantity = 0;
						vSrvRow.Price = 0;
						If Not IsBlankString(vAccommodationRemarks) Then
							vSrvRow.Remarks = StrReplace(TrimAll(vSrvRow.Remarks), vAccommodationServiceRemarks, vAccommodationRemarks);
						Else
							vSrvRow.Remarks = TrimAll(vSrvRow.Remarks);
						EndIf;
					ElsIf vSrvRow.IsRoomRevenue Then
						If vSrvRow.IsInPrice Then
							If vSrvRow.Service.RoomRevenueAmountsOnly Then
								vSrvRow.Quantity = 0;
								vSrvRow.Price = 0;
							EndIf;
							vSrvRow.Service = vAccommodationService;
							If Not IsBlankString(vAccommodationRemarks) Then
								vSrvRow.Remarks = StrReplace(TrimAll(vSrvRow.Remarks), vAccommodationServiceRemarks, vAccommodationRemarks);
							Else
								vSrvRow.Remarks = TrimAll(vSrvRow.Remarks);
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
		ElsIf SelGroupBy = "AllPerFolio" Then
			For Each vSrvRow In vServices Do
				vSrvRow.AccountingDate = BegOfDay(Date);
				vSrvRow.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
				vSrvRow.Room = Catalogs.Rooms.EmptyRef();
				If ValueIsFilled(vAccommodationService) And vAccommodationServiceVATRate = vSrvRow.VATRate Then
					If vSrvRow.Service.RoomRevenueAmountsOnly Then
						vSrvRow.Quantity = 0;
						vSrvRow.Price = 0;
					EndIf;
					vSrvRow.Service = vAccommodationService;
					If Not vSrvRow.IsRoomRevenue Then
						vSrvRow.Quantity = 0;
						vSrvRow.Price = 0;
					EndIf;
					If Not IsBlankString(vAccommodationRemarks) Then
						vSrvRow.Remarks = StrReplace(TrimAll(vSrvRow.Remarks), vAccommodationServiceRemarks, vAccommodationRemarks);
					Else
						vSrvRow.Remarks = TrimAll(vSrvRow.Remarks);
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		// Group by transactions
		vServices.GroupBy("Folio, Service, CalendarDayType, Room, Remarks, VATRate", "Sum, VATSum, Price, Quantity");
		// Recalculate price for all services
		For Each vSrvRow In vServices Do
			vSrvRow.VATSum = cmCalculateVATSum(vSrvRow.VATRate, vSrvRow.Sum, Date);
			vSrvRow.Price = cmRecalculatePrice(vSrvRow.Sum, vSrvRow.Quantity);
		EndDo;
	EndIf;
	vServices.Sort("Folio");
	
	// Print services
	vTotalSum = 0;
	vTotalVATSum = 0;
	vClientSum = 0;
	vTotalNumberOfPersons = 0;
	
	vCurFolio = Documents.Folio.EmptyRef();
	For Each vSrvRow In vServices Do
		// Print folio header if necessary
		If vSrvRow.Folio <> vCurFolio Then
			// Print previous folio footer
			If ValueIsFilled(vCurFolio) Then
				vClientTotal.Parameters.mClientName = TrimAll(vCurFolio.Client);
				vClientTotal.Parameters.mClientSum = Format(vClientSum, "ND=17; NFD=2");
				// Put client total
				vSpreadsheet.Put(vClientTotal);
				// Count clients
				vTotalNumberOfPersons = vTotalNumberOfPersons + 1;
				// Reset client totals
				vClientSum = 0;
			EndIf;
			// Change current folio
			vCurFolio = vSrvRow.Folio;
			// Fill client parameters
			vClientName = TrimAll(vCurFolio.Client);
			// Cut off dates by settlement month
			vDateTimeFrom = vCurFolio.DateTimeFrom;
			vDateTimeTo = vCurFolio.DateTimeTo;
			If vAllServicesAreInOneMonth Then
				If vDateTimeFrom < vBegOfMonth Then
					vDateTimeFrom = vBegOfMonth;
				EndIf;
				If vDateTimeTo > vEndOfMonth Then
					vDateTimeTo = vEndOfMonth;
				EndIf;
			EndIf;
			vCheckInDate = Format(vDateTimeFrom, "DF='dd.MM.yy HH:mm'");
			vCheckOutDate = Format(vDateTimeTo, "DF='dd.MM.yy HH:mm'");
			vRoom = TrimAll(vCurFolio.Room);
			vRoomType = "";
			vRoomRate = "";
			If ValueIsFilled(vCurFolio.ParentDoc) And TypeOf(vCurFolio.ParentDoc) = Type("DocumentRef.Accommodation") Then
				vRoomType = TrimAll(vCurFolio.ParentDoc.RoomType);
				vRoomRate = TrimAll(vCurFolio.ParentDoc.RoomRate);
			EndIf;
			// Set client parameters
			vClient.Parameters.mRoomType = vRoomType;
			vClient.Parameters.mRoomRate = vRoomRate;
			vClient.Parameters.mClientName = vClientName;
			vClient.Parameters.mCheckInDate = vCheckInDate;
			vClient.Parameters.mCheckOutDate = vCheckOutDate;
			vClient.Parameters.mRoom = vRoom;
			// Put client
			vSpreadsheet.Put(vClient);
		EndIf;
		// Fill row parameters
		vServiceObj = vSrvRow.Service.GetObject();
		vDescription = TrimAll(vSrvRow.Remarks);
		vPrice = vSrvRow.Price;
		vSum = vSrvRow.Sum;
		vUnit = vServiceObj.pmGetServiceUnitDescription(SelLanguage);
		vQuantity = "";
		If vSrvRow.Quantity <> 0 Then
			vQuantity = vServiceObj.pmGetServiceQuantityPresentation(vSrvRow.Quantity, SelLanguage);
		EndIf;
		// Totals
		vTotalSum = vTotalSum + vSrvRow.Sum;
		vClientSum = vClientSum + vSrvRow.Sum;
		vTotalVATSum = vTotalVATSum + vSrvRow.VATSum;
		// Set parameters
		vService.Parameters.mDescription = vDescription;
		vService.Parameters.mPrice = Format(vPrice, "ND=17; NFD=2");
		vService.Parameters.mUnit = vUnit;
		vService.Parameters.mQuantity = vQuantity;
		vService.Parameters.mSum = Format(vSum, "ND=17; NFD=2");
		// Put row
		If vSum <> 0 Then
			vSpreadsheet.Put(vService);
		EndIf;
	EndDo;
	// Print previous folio footer
	If ValueIsFilled(vCurFolio) Then
		vClientTotal.Parameters.mClientName = TrimAll(vCurFolio.Client);
		vClientTotal.Parameters.mClientSum = Format(vClientSum, "ND=17; NFD=2");
		// Put client total
		vSpreadsheet.Put(vClientTotal);
		// Count clients
		vTotalNumberOfPersons = vTotalNumberOfPersons + 1;
	EndIf;
	
	// Footer
	vFooter = vTemplate.GetArea("Footer");
	// Fill parameters
	mTotalSum = Format(vTotalSum, "ND=17; NFD=2");
	mVATHeader = "";
	If ValueIsFilled(vCompany) And vCompany.DoNotPrintVAT Then
		mTotalVATSum = "";
		mTotalVATSumInWords = "";
	Else
		If vTotalVATSum <> 0 Then
			mVATHeader = NStr("en='Including VAT 18%';ru='В том числе НДС 18%';de='Darunter MwSt. 18%'", SelLanguage);
			mTotalVATSum = Format(vTotalVATSum, "ND=17; NFD=2");
		Else
			mVATHeader = NStr("en='No VAT';ru='НДС не облагается';de='MwSt. wird nicht berechnet'", SelLanguage);
			mTotalVATSum = Format(vTotalVATSum, "ND=17; NFD=2");
		EndIf;
		mTotalVATSumInWords = cmNStr("ru=', в т.ч. НДС на сумму: '; en=', including VAT: '", SelLanguage) + cmSumInWords(vTotalVATSum, AccountingCurrency, SelLanguage);
	EndIf;
	mTotalSumInWords = cmSumInWords(vTotalSum, AccountingCurrency, SelLanguage);
	// Set parameters
	vFooter.Parameters.mGuestGroupCode = vGuestGroupCode;
	vFooter.Parameters.mTotalSum = mTotalSum;
	vFooter.Parameters.mTotalVATSum = mTotalVATSum;
	vFooter.Parameters.mVATHeader = mVATHeader;
	vFooter.Parameters.mTotalSumInWords = mTotalSumInWords;
	vFooter.Parameters.mTotalVATSumInWords = mTotalVATSumInWords;
	// Put footer
	vSpreadsheet.Put(vFooter);
	
	// Print room revenue services
	For Each vSrvRow In vRoomRevenueServices Do
		If vSrvRow.IsRoomRevenue Then
			vSrvRow.Service = vAccommodationService;
		ElsIf vSrvRow.IsInPrice Then
			vSrvRow.Service = vAccommodationService;
			vSrvRow.IsRoomRevenue = True;
			vSrvRow.Quantity = 0;
		EndIf;
	EndDo;
	vRoomRevenueServices.GroupBy("Service, IsRoomRevenue, VATRate", "Quantity, Sum");
	For Each vSrvRow In vRoomRevenueServices Do
		If Not ValueIsFilled(vSrvRow.Service) Then
			Continue;
		EndIf;
		If Not vSrvRow.IsRoomRevenue Then
			Continue;
		EndIf;
		If vSrvRow.Sum = 0 Then
			Continue;
		EndIf;
		vServiceObj = vSrvRow.Service.GetObject();
		mRoomRevenueService = vServiceObj.pmGetServiceDescription(SelLanguage, True) + " " + 
		                      Format(Round(vSrvRow.Quantity, 3)) + " " + vServiceObj.pmGetServiceUnitDescription(SelLanguage) + 
							  NStr("en=' sum ';ru=' на сумму ';de=' für einen Betrag von '", SelLanguage) + Format(vSrvRow.Sum, "ND=17; NFD=2");
		vRoomRevenueService.Parameters.mRoomRevenueService = mRoomRevenueService;
		// Put room revenue service
		vSpreadsheet.Put(vRoomRevenueService);
	EndDo;
	
	// Signatures
	vSignatures = vTemplate.GetArea("Signatures");
	vEmployeeName = TrimAll(SessionParameters.CurrentUser);
	vEmployeePosition = NStr("en='Administrator';ru='Дежурный администратор';de='Diensthabender Administrator'", SelLanguage);
	If Not IsBlankString(SessionParameters.CurrentUser.Position) Then
		vEmployeePosition = NStr(TrimAll(SessionParameters.CurrentUser.Position), SelLanguage);
	EndIf;
	vSignatures.Parameters.mEmployeePosition = vEmployeePosition;
	vSignatures.Parameters.mEmployeeName = vEmployeeName;
	vSignatures.Parameters.mTotalNumberOfPersons = Format(vTotalNumberOfPersons, "ND=8; NFD=0; NZ=; NG=");
	// Manager's signature
	If PrintWithCompanyStamp Then
		If vSignatureIsSet Then
			vSignatures.Drawings.Signature.Print = True;
			vSignatures.Drawings.Signature.Picture = vSignature;
		Else
			vSignatures.Drawings.Delete(vSignatures.Drawings.Signature);
		EndIf;
	Else
		vSignatures.Drawings.Delete(vSignatures.Drawings.Signature);
	EndIf;
	vSpreadsheet.Put(vSignatures);

	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Landscape, True, , True);
	// Check authorities
	cmSetSpreadsheetProtection(vSpreadsheet);
EndProcedure // pmPrintSettlement7G

// -----------------------------------------------------------------------------
Procedure pmPrintVATInvoice(vSpreadsheet, SelLanguage, SelGroupBy, SelObjectPrintForm, SelServiceGroup, pPageBreak = False) Export
	// Basic checks
	vCompany = Company;
	If Not ValueIsFilled(vCompany) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Company should be filled!';ru='Не задана фирма!';de='Die Firma ist nicht angegeben!'"), MessageStatus.Attention);
		Return;
	EndIf;
	If Not ValueIsFilled(SelLanguage) Then
		SelLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	
	// Get spreadsheet
	If pPageBreak Then
		vSpreadsheet.PutHorizontalPageBreak();
	Else
		vSpreadsheet.Clear();
	EndIf;
	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Landscape, True, 2, True);
	
	// Choose template
	vSettlObj = ThisObject;
	vTemplate = vSettlObj.GetTemplate("VATInvoice");
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(SelObjectPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;
	
	// Load pictures
	vDirectorSignatureIsSet = False;
	vDirectorSignature = New Picture;
	If Company.DirectorSignature <> Undefined Then
		vDirectorSignature = Company.DirectorSignature.Get();
		If vDirectorSignature = Undefined Then
			vDirectorSignature = New Picture;
		Else
			vDirectorSignatureIsSet = True;
		EndIf;
	EndIf;
	vAccountantGeneralSignatureIsSet = False;
	vAccountantGeneralSignature = New Picture;
	If Company.AccountantGeneralSignature <> Undefined Then
		vAccountantGeneralSignature = Company.AccountantGeneralSignature.Get();
		If vAccountantGeneralSignature = Undefined Then
			vAccountantGeneralSignature = New Picture;
		Else
			vAccountantGeneralSignatureIsSet = True;
		EndIf;
	EndIf;
	
	// Header
	vHeader = vTemplate.GetArea("Header");
	vTableHeader = vTemplate.GetArea("TableHeader");
	// VAT invoice date and number
	mInvoiceNumber = TrimAll(InvoiceNumber);
	mInvoiceDate = cmGetDocumentDatePresentation(Date);
	// Company
	vCompanyObj = vCompany.GetObject();
	If ValueIsFilled(vCompany.ParentCompany) Then
		vCompanyObj = vCompany.ParentCompany.GetObject();
	EndIf;
	mCompanyLegacyName = vCompanyObj.pmGetCompanyPrintName(SelLanguage);
	mCompanyLegacyAddress = vCompanyObj.pmGetCompanyLegacyAddressPresentation(SelLanguage);
	vCompanyTIN = TrimAll(vCompanyObj.TIN);
	vCompanyKPP = TrimAll(vCompanyObj.KPP);
	mCompanyTIN = vCompanyTIN + ?(IsBlankString(vCompanyKPP), "", "/" + vCompanyKPP);
	// Customer
	vCustomer = AccountingCustomer;
	mCustomerLegacyName = "";
	mCustomerLegacyAddress = "";
	mCustomerTIN = "";
	If ValueIsFilled(vCustomer) Then
		mCustomerLegacyName = ?(ValueIsFilled(vCustomer.ParentOrganization), TrimAll(vCustomer.ParentOrganization.LegacyName), TrimAll(vCustomer.LegacyName));
		mCustomerLegacyAddress = ?(ValueIsFilled(vCustomer.ParentOrganization), cmGetAddressPresentation(vCustomer.ParentOrganization.LegacyAddress), cmGetAddressPresentation(vCustomer.LegacyAddress));
		vCustomerTIN = ?(ValueIsFilled(vCustomer.ParentOrganization), TrimAll(vCustomer.ParentOrganization.TIN), TrimAll(vCustomer.TIN));
		vCustomerKPP = ?(ValueIsFilled(vCustomer.ParentOrganization), TrimAll(vCustomer.ParentOrganization.KPP), TrimAll(vCustomer.KPP));
		mCustomerTIN = vCustomerTIN + ?(IsBlankString(vCustomerKPP), "", "/" + vCustomerKPP);
	EndIf;
	// Consignor and consignee
	mConsignor = "----";
	mConsignee = "----";
	If Not vCompany.UseDashForConsignorConsignee Then
		If vCompany.UseIdemForConsignor Then
			mConsignor = "он же";
		Else
			vCompanyObj = vCompany.GetObject();
			mConsignor = vCompanyObj.pmGetCompanyPrintName(SelLanguage) + ?(IsBlankString(vCompany.LegacyAddress), "", ", " + vCompanyObj.pmGetCompanyLegacyAddressPresentation(SelLanguage));
		EndIf;
		mConsignee = TrimAll(vCustomer.LegacyName) + ?(IsBlankString(vCustomer.LegacyAddress), "", ", " + cmGetAddressPresentation(vCustomer.LegacyAddress));
	EndIf;
	If Not IsBlankString(Consignor) Then
		mConsignor = TrimR(Consignor);
	EndIf;
	If Not IsBlankString(Consignee) Then
		mConsignee = TrimR(Consignee);
	EndIf;
	// Currency
	mAccountingCurrency = "";
	If ValueIsFilled(AccountingCurrency) Then
		mAccountingCurrency = TrimAll(AccountingCurrency.Code) + ", " + ?(IsBlankString(AccountingCurrency.Remarks), TrimAll(AccountingCurrency.Description), TrimAll(AccountingCurrency.Remarks));
	EndIf;
	// State contract ID
	mStateContractID = "";
	If ValueIsFilled(AccountingContract) And Not IsBlankString(AccountingContract.StateContractID) Then
		mStateContractID = TrimAll(AccountingContract.StateContractID);
	EndIf;
	// Payment and account document
	mPaymentDocuments = "";
	If PaymentDocuments.Count() > 0 Then
		For Each vRow In PaymentDocuments Do
			If vRow.LineNumber > 1 Then
				mPaymentDocuments = mPaymentDocuments + ", ";
			EndIf;
			mPaymentDocuments = mPaymentDocuments + ?(IsBlankString(vRow.PaymentDocNumber), "_______________", TrimAll(vRow.PaymentDocNumber)) + 
			                    " от " + ?(ValueIsFilled(vRow.PaymentDocDate), Format(vRow.PaymentDocDate, "DF=dd.MM.yyyy"), "_______________");
		EndDo;
	Else
		mPaymentDocuments = "_______________ от _______________";
	EndIf;
	vSettlementDocument =  "_______________" + "№" + TrimAll(Number) + " от " + Format(Date, "DF=dd.MM.yyyy");
	// Set parameters
	vHeader.Parameters.mInvoiceNumber = mInvoiceNumber;
	vHeader.Parameters.mInvoiceDate = mInvoiceDate;
	vHeader.Parameters.mCompanyLegacyName = mCompanyLegacyName;
	vHeader.Parameters.mCompanyLegacyAddress = mCompanyLegacyAddress;
	vHeader.Parameters.mCompanyTIN = mCompanyTIN;
	vHeader.Parameters.mCustomerLegacyName = mCustomerLegacyName;
	vHeader.Parameters.mCustomerLegacyAddress = mCustomerLegacyAddress;
	vHeader.Parameters.mCustomerTIN = mCustomerTIN;
	vHeader.Parameters.mConsignor = mConsignor;
	vHeader.Parameters.mConsignee = mConsignee;
	vHeader.Parameters.mAccountingCurrency = mAccountingCurrency;
	vHeader.Parameters.mStateContractID = mStateContractID;
	vHeader.Parameters.mPaymentDocuments = mPaymentDocuments;
	vHeader.Parameters.mSettlementDocument = vSettlementDocument;
	vSpreadsheet.Put(vHeader);
	vSpreadsheet.Put(vTableHeader);
	
	// Get row template area
	vRow = vTemplate.GetArea("Row");
	
	// Get all services
	vServices = Documents.Settlement.MergeCorrections(Services);
	
	// Change accounting dates for breakfast
	If Not IsBlankString(SelGroupBy) And SelGroupBy <> "ByService" Then
		For Each vSrvRow In vServices Do
			If vSrvRow.IsInPrice And ValueIsFilled(vSrvRow.Service.QuantityCalculationRule) And
			   vSrvRow.Service.QuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.Breakfast Then
				If ValueIsFilled(vSrvRow.Folio) And BegOfDay(vSrvRow.AccountingDate) > BegOfDay(vSrvRow.Folio.DateTimeFrom) Then
					vSrvRow.AccountingDate = vSrvRow.AccountingDate - 24 * 3600;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	// Join services according to service parameters
	If Not IsBlankString(SelGroupBy) And SelGroupBy <> "ByService" Then
		// Try to replace accommodation service to the one that should be used for printing
		vChargeParentDoc = Undefined;
		vAccountingDate = '00010101';
		vFirstRoomRateService = Undefined;
		vFirstRoomRateServiceIsFound = False;
		For Each vSrvRow In vServices Do
			vSrvRowService = vSrvRow.Service;
			If ValueIsFilled(vSrvRowService) Then
				If vChargeParentDoc <> vSrvRow.ParentDoc Then
					vChargeParentDoc = vSrvRow.ParentDoc;
					vAccountingDate = '00010101';
					vFirstRoomRateService = Undefined;
					vFirstRoomRateServiceIsFound = False;
				EndIf;
				If vAccountingDate <> BegOfDay(vSrvRow.AccountingDate) Then
					vAccountingDate = BegOfDay(vSrvRow.AccountingDate);
					vFirstRoomRateService = Undefined;
					vFirstRoomRateServiceIsFound = False;
				EndIf;
				If vSrvRowService.IsRoomRevenue And vSrvRowService.IsInPrice And Not vSrvRowService.RoomRevenueAmountsOnly Then
					If ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
						vSrvRow.Service = vSrvRowService.HideIntoServiceOnPrint;
					EndIf;
					If Not vFirstRoomRateServiceIsFound Then
						vFirstRoomRateService = vSrvRowService;
						vFirstRoomRateServiceIsFound = True;
					Else
						If vFirstRoomRateService <> vSrvRowService And ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
							vSrvRow.Quantity = 0;
						EndIf;
					EndIf;
				ElsIf vSrvRowService.DoNotGroupIntoRoomRateOnPrint And ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
					vSrvRow.Service = vSrvRowService.HideIntoServiceOnPrint;
				EndIf;
			EndIf;
		EndDo;
		// Try to merge other services to the accommodation service
		i = 0;
		While i < vServices.Count() Do
			vSrvRow = vServices.Get(i);
			vSrvRowService = vSrvRow.Service;
			If ValueIsFilled(vSrvRowService) And ValueIsFilled(vSrvRowService.HideIntoServiceOnPrint) Then
				If Not vSrvRowService.DoNotGroupIntoRoomRateOnPrint Then
					vHideToServices = vServices.FindRows(New Structure("Service, AccountingDate, Folio", vSrvRowService.HideIntoServiceOnPrint, vSrvRow.AccountingDate, vSrvRow.Folio));
					If vHideToServices.Count() = 0 Then
						vHideToServices = vServices.FindRows(New Structure("Service, AccountingDate, Folio", vSrvRowService.HideIntoServiceOnPrint, vSrvRow.AccountingDate - 24 * 3600, vSrvRow.Folio));
					EndIf;
					If vHideToServices.Count() > 0 Then
						vSrv2Hide2 = vHideToServices.Get(0);
						vSrv2Hide2.Sum = vSrv2Hide2.Sum + vSrvRow.Sum;
						vSrv2Hide2.VATSum = vSrv2Hide2.VATSum + vSrvRow.VATSum;
						vSrv2Hide2.Price = cmRecalculatePrice(vSrv2Hide2.Sum, vSrv2Hide2.Quantity);
						// Delete current service
						vServices.Delete(i);
						Continue;
					EndIf;
				EndIf;
			EndIf;
			i = i + 1;
		EndDo;
	EndIf;
	
	// Delete services not in service group choosen
	If ValueIsFilled(SelServiceGroup) Then
		i = 0;
		While i < vServices.Count() Do
			vSrvRow = vServices.Get(i);
			If Not cmIsServiceInServiceGroup( vSrvRow.Service, SelServiceGroup) Then
				vServices.Delete(i);
			Else
				i = i + 1;
			EndIf;
		EndDo;
	EndIf;
	
	// Get accommodation service name
	vAccommodationService = Undefined;
	vAccommodationServiceRemarks = "";	
	vAccommodationRemarks = "";	
	vAccommodationUnit = "";	
	vAccommodationServiceVATRate = Undefined;
	i = 0;
	While i < vServices.Count() Do
		vSrvRow = vServices.Get(i);
		If SelGroupBy = "InPricePerFolioPerDay" Or SelGroupBy = "InPricePerDay" Or
		   SelGroupBy = "AllPerFolioPerDay" Or SelGroupBy = "AllPerDay" Or
		   SelGroupBy = "InPricePerFolio" Or SelGroupBy = "InPrice" Or
		   SelGroupBy = "AllPerFolio" Or SelGroupBy = "All" Then
			If vSrvRow.Sum = 0 Then
				vServices.Delete(i);
				Continue;
			EndIf;
		EndIf;
		If vAccommodationService = Undefined And ValueIsFilled(vSrvRow.Service) And vSrvRow.IsInPrice And vSrvRow.IsRoomRevenue And Not vSrvRow.Service.RoomRevenueAmountsOnly Then
			vAccommodationService = vSrvRow.Service;
			vAccommodationServiceVATRate = vSrvRow.VATRate;
			vAccommodationServiceRemarks = vAccommodationService.GetObject().pmGetServiceDescription(SelLanguage, False);
			vAccommodationRemarks = vAccommodationService.GetObject().pmGetServiceDescription(SelLanguage, True);
			vAccommodationUnit = vAccommodationService.GetObject().pmGetServiceUnitDescription(SelLanguage);
		EndIf;
		i = i + 1;
	EndDo;
	
	// Group by services according to the VAT invoice print type
	If Not IsBlankString(SelGroupBy) Then
		If SelGroupBy = "InPricePerFolioPerDay" Or SelGroupBy = "InPricePerDay" Then
			For Each vSrvRow In vServices Do
				// Reset "is in price" flag if necessary
				If ValueIsFilled(vSrvRow.Service) And vSrvRow.Service.DoNotGroupIntoRoomRateOnPrint Then
					vSrvRow.IsInPrice = False;
				EndIf;
				vSrvRow.AccountingDate = BegOfDay(vSrvRow.AccountingDate);
				vSrvRow.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
				vSrvRow.Room = Catalogs.Rooms.EmptyRef();
				If SelGroupBy = "InPricePerDay" Then
					vSrvRow.Folio = Documents.Folio.EmptyRef();
				EndIf;
				If ValueIsFilled(vAccommodationService) And vAccommodationServiceVATRate = vSrvRow.VATRate Then
					If Not vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice Then
						If Not IsBlankString(vAccommodationRemarks) Then
							If StrFind(SelGroupBy,  "PerFolio") = 0 Then
								vSrvRow.Remarks = vAccommodationRemarks;
							Else
								vSrvRow.Remarks = StrReplace(TrimAll(vSrvRow.Remarks), vAccommodationServiceRemarks, vAccommodationRemarks);
							EndIf;
						Else
							vSrvRow.Remarks = TrimAll(vSrvRow.Remarks);
						EndIf;
						vSrvRow.Quantity = ?(IsBlankString(vAccommodationRemarks), vSrvRow.Quantity, 0);
						vSrvRow.Unit = vAccommodationUnit;
						vSrvRow.Price = 0;
					ElsIf vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice Then
						If vSrvRow.Service.RoomRevenueAmountsOnly Then
							vSrvRow.Quantity = 0;
							vSrvRow.Price = 0;
						EndIf;
						If Not IsBlankString(vAccommodationRemarks) Then
							If StrFind(SelGroupBy,  "PerFolio") = 0 Then
								vSrvRow.Remarks = vAccommodationRemarks;
							Else
								vSrvRow.Remarks = StrReplace(TrimAll(vSrvRow.Remarks), vAccommodationServiceRemarks, vAccommodationRemarks);
							EndIf;
						Else
							vSrvRow.Remarks = TrimAll(vSrvRow.Remarks);
						EndIf;
						vSrvRow.Unit = vAccommodationUnit;
					EndIf;
				EndIf;
			EndDo;
		ElsIf SelGroupBy = "AllPerFolioPerDay" Or SelGroupBy = "AllPerDay" Then
			// Change transaction services
			For Each vSrvRow In vServices Do
				vSrvRow.AccountingDate = BegOfDay(vSrvRow.AccountingDate);
				vSrvRow.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
				vSrvRow.Room = Catalogs.Rooms.EmptyRef();
				If SelGroupBy = "AllPerDay" Then
					vSrvRow.Folio = Documents.Folio.EmptyRef();
				EndIf;
				If ValueIsFilled(vAccommodationService) And vAccommodationServiceVATRate = vSrvRow.VATRate Then
					If vSrvRow.Service.RoomRevenueAmountsOnly Then
						vSrvRow.Quantity = 0;
						vSrvRow.Price = 0;
					EndIf;
					If Not IsBlankString(vAccommodationRemarks) Then
						If StrFind(SelGroupBy,  "PerFolio") = 0 Then
							vSrvRow.Remarks = vAccommodationRemarks;
						Else
							vSrvRow.Remarks = StrReplace(TrimAll(vSrvRow.Remarks), vAccommodationServiceRemarks, vAccommodationRemarks);
						EndIf;
					Else
						vSrvRow.Remarks = TrimAll(vSrvRow.Remarks);
					EndIf;
					vSrvRow.Unit = vAccommodationUnit;
					If Not vSrvRow.IsRoomRevenue Then
						vSrvRow.Quantity = ?(IsBlankString(vAccommodationRemarks), vSrvRow.Quantity, 0);
						vSrvRow.Price = 0;
					EndIf;
				EndIf;
			EndDo;
		ElsIf SelGroupBy = "PerFolio" Then
			For Each vSrvRow In vServices Do
				vSrvRow.AccountingDate = BegOfDay(Date);
			EndDo;
		ElsIf SelGroupBy = "ByService" Then
			// Change transaction services
			For Each vSrvRow In vServices Do
				vSrvRow.AccountingDate = BegOfDay(Date);
				vSrvRow.Folio = Documents.Folio.EmptyRef();
				vSrvRow.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
				vSrvRow.Room = Catalogs.Rooms.EmptyRef();
			EndDo;
		ElsIf SelGroupBy = "InPricePerFolio" Or SelGroupBy = "InPrice" Then
			// Change transaction services
			For Each vSrvRow In vServices Do
				// Reset "is in price" flag if necessary
				If ValueIsFilled(vSrvRow.Service) And vSrvRow.Service.DoNotGroupIntoRoomRateOnPrint Then
					vSrvRow.IsInPrice = False;
				EndIf;
				vSrvRow.AccountingDate = BegOfDay(Date);
				If SelGroupBy = "InPrice" Then
					vSrvRow.Folio = Documents.Folio.EmptyRef();
					vSrvRow.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
					vSrvRow.Room = Catalogs.Rooms.EmptyRef();
				EndIf;
				If ValueIsFilled(vAccommodationService) And vAccommodationServiceVATRate = vSrvRow.VATRate Then
					If Not vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice Then
						If Not IsBlankString(vAccommodationRemarks) Then
							If StrFind(SelGroupBy,  "PerFolio") = 0 Then
								vSrvRow.Remarks = vAccommodationRemarks;
							Else
								vSrvRow.Remarks = StrReplace(TrimAll(vSrvRow.Remarks), vAccommodationServiceRemarks, vAccommodationRemarks);
							EndIf;
						Else
							vSrvRow.Remarks = TrimAll(vSrvRow.Remarks);
						EndIf;
						vSrvRow.Unit = vAccommodationUnit;
						vSrvRow.Quantity = ?(IsBlankString(vAccommodationRemarks), vSrvRow.Quantity, 0);
						vSrvRow.Price = 0;
					ElsIf vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice Then
						If vSrvRow.Service.RoomRevenueAmountsOnly Then
							vSrvRow.Quantity = 0;
							vSrvRow.Price = 0;
						EndIf;
						If Not IsBlankString(vAccommodationRemarks) Then
							If StrFind(SelGroupBy,  "PerFolio") = 0 Then
								vSrvRow.Remarks = vAccommodationRemarks;
							Else
								vSrvRow.Remarks = StrReplace(TrimAll(vSrvRow.Remarks), vAccommodationServiceRemarks, vAccommodationRemarks);
							EndIf;
						Else
							vSrvRow.Remarks = TrimAll(vSrvRow.Remarks);
						EndIf;
						vSrvRow.Unit = vAccommodationUnit;
					EndIf;
				EndIf;
			EndDo;
		ElsIf SelGroupBy = "AllPerFolio" Or SelGroupBy = "All" Then
			// Change transaction services
			For Each vSrvRow In vServices Do
				vSrvRow.AccountingDate = BegOfDay(Date);
				vSrvRow.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
				vSrvRow.Room = Catalogs.Rooms.EmptyRef();
				If SelGroupBy = "All" Then
					vSrvRow.Folio = Documents.Folio.EmptyRef();
				EndIf;
				If ValueIsFilled(vAccommodationService) And vAccommodationServiceVATRate = vSrvRow.VATRate Then
					If vSrvRow.Service.RoomRevenueAmountsOnly Then
						vSrvRow.Quantity = 0;
						vSrvRow.Price = 0;
					EndIf;
					If Not IsBlankString(vAccommodationRemarks) Then
						If StrFind(SelGroupBy,  "PerFolio") = 0 Then
							vSrvRow.Remarks = vAccommodationRemarks;
						Else
							vSrvRow.Remarks = StrReplace(TrimAll(vSrvRow.Remarks), vAccommodationServiceRemarks, vAccommodationRemarks);
						EndIf;
					Else
						vSrvRow.Remarks = TrimAll(vSrvRow.Remarks);
					EndIf;
					vSrvRow.Unit = vAccommodationUnit;
					If Not vSrvRow.IsRoomRevenue Then
						vSrvRow.Quantity = ?(IsBlankString(vAccommodationRemarks), vSrvRow.Quantity, 0);
						vSrvRow.Price = 0;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		// Group by transactions
		vServices.GroupBy("Folio, AccountingDate, CalendarDayType, Room, Remarks, Unit, VATRate", "Sum, VATSum, Price, Quantity");
	EndIf;
	// Recalculate price for all services and delete zero sum rows
	i = 0;
	While i < vServices.Count() Do
		vSrvRow = vServices.Get(i);
		If vSrvRow.Sum = 0 And SelGroupBy <> "ByService" And Not IsBlankString(SelGroupBy) Then
			vServices.Delete(i);
		Else
			vSrvRow.VATSum = cmCalculateVATSum(vSrvRow.VATRate, vSrvRow.Sum, vSrvRow.AccountingDate);
			vSrvRow.Price = cmRecalculatePrice(vSrvRow.Sum - vSrvRow.VATSum, vSrvRow.Quantity);
			i = i + 1;
		EndIf;
	EndDo;
	vServices.Sort("Folio, AccountingDate");
	
	// Calculate totals
	vTotalSum = 0;
	vTotalVATSum = 0;
	vTotalSumWithoutVAT = 0;
	For Each vSrvRow In vServices Do
		vTotalSum = vTotalSum + vSrvRow.Sum;
		vVATSum = cmCalculateVATSum(vSrvRow.VATRate, vSrvRow.Sum, vSrvRow.AccountingDate);
		vTotalVATSum = vTotalVATSum + vVATSum;
		vTotalSumWithoutVAT = vTotalSumWithoutVAT + vSrvRow.Sum - vVATSum;
	EndDo;
	
	// Build footer
	vFooterAreas = new Array();
	vFooter = vTemplate.GetArea("Footer");
	// Fill parameters
	mTotalSum = ?(vTotalSum = 0, "-----", Format(vTotalSum, "ND=17; NFD=2"));
	mTotalSumWithoutVAT = ?(vTotalSumWithoutVAT = 0, "-----", Format(vTotalSumWithoutVAT, "ND=17; NFD=2"));
	mTotalVATSum = ?(vTotalVATSum = 0, "-----", Format(vTotalVATSum, "ND=17; NFD=2"));
	mCompanyDirector = ?(ValueIsFilled(vCompany.ParentCompany), TrimAll(cmNStr(vCompany.ParentCompany.Director, SelLanguage)), TrimAll(cmNStr(vCompany.Director, SelLanguage)));
	mCompanyAccountantGeneral = ?(ValueIsFilled(vCompany.ParentCompany), TrimAll(cmNStr(vCompany.ParentCompany.AccountantGeneral, SelLanguage)), TrimAll(cmNStr(vCompany.AccountantGeneral, SelLanguage)));
	// Set parameters
	vFooter.Parameters.mTotalSum = mTotalSum;
	vFooter.Parameters.mTotalSumWithoutVAT = mTotalSumWithoutVAT;
	vFooter.Parameters.mTotalVATSum = mTotalVATSum;
	vFooter.Parameters.mCompanyDirector = mCompanyDirector;
	vFooter.Parameters.mCompanyAccountantGeneral = mCompanyAccountantGeneral;
	// Company stamp and signatures
	If PrintWithCompanyStamp Then
		If vDirectorSignatureIsSet Then
			vFooter.Drawings.DirectorSignature.Print = True;
			vFooter.Drawings.DirectorSignature.Picture = vDirectorSignature;
		Else
			vFooter.Drawings.Delete(vFooter.Drawings.DirectorSignature);
		EndIf;
		If vAccountantGeneralSignatureIsSet Then
			vFooter.Drawings.AccountantGeneralSignature.Print = True;
			vFooter.Drawings.AccountantGeneralSignature.Picture = vAccountantGeneralSignature;
		Else
			vFooter.Drawings.Delete(vFooter.Drawings.AccountantGeneralSignature);
		EndIf;
	Else
		vFooter.Drawings.Delete(vFooter.Drawings.DirectorSignature);
		vFooter.Drawings.Delete(vFooter.Drawings.AccountantGeneralSignature);
	EndIf;
	// Put footer
	vFooterAreas.Add(vFooter);
	
	// Print services
	vCurFolio = Documents.Folio.EmptyRef();
	vRowNumber = 1;
	For Each vSrvRow In vServices Do
		// Fill parameters
		mDescription = "";
		If SelGroupBy <> "InPrice" And SelGroupBy <> "InPricePerFolio" And SelGroupBy <> "All" And SelGroupBy <> "AllPerFolio" And SelGroupBy <> "PerFolio" And SelGroupBy <> "ByService" Then
			mDescription = mDescription + Format(vSrvRow.AccountingDate, "DF=dd.MM.yy") + " ";
		EndIf;
		mDescription = mDescription + cmNStr(vSrvRow.Remarks, SelLanguage);
		// Print folio header if necessary
		If vSrvRow.Folio <> vCurFolio Then
			vCurFolio = vSrvRow.Folio;
			// Fill folio parameters
			mClient = "";
			If ValueIsFilled(vCurFolio.Client) Then
				mClient = TrimAll(TrimAll(vCurFolio.Client.LastName) + " " + TrimAll(vCurFolio.Client.FirstName) + " " + TrimAll(vCurFolio.Client.SecondName));
			ElsIf ValueIsFilled(vCurFolio.Customer) Then
				If Not IsBlankString(vCurFolio.Customer.LegacyName) Then
					mClient = TrimAll(vCurFolio.Customer.LegacyName);
				Else
					mClient = TrimAll(vCurFolio.Customer.Description);
				EndIf;
			EndIf;
			vDateFrom = vCurFolio.DateTimeFrom;
			vDateTo = vCurFolio.DateTimeTo;
			cmGetServicesPeriodByFolio(vCurFolio, Ref, vDateFrom, vDateTo);
			vRoom = "";
			If ValueIsFilled(vCurFolio.Room) Then
				vRoom = TrimAll(vCurFolio.Room.Description);
			EndIf;
			mClient = mClient + 
			          ?(vCompany.OutputGuestPeriodInVATInvoice, ?(ValueIsFilled(vDateFrom), ", " + cmPeriodPresentation(vDateFrom, vDateTo), ""), "") + 
			          ?(IsBlankString(vRoom), "" , ", " + vRoom);
			// Set description
			If Not IsBlankString(mClient) Then
				mDescription = mDescription + " - " + mClient;
			EndIf;
		EndIf;
		mUnit = vSrvRow.Unit;
		mUnitCode = cmGetUnitCode(mUnit);
		mQuantity = vSrvRow.Quantity;
		mPrice = vSrvRow.Price;
		vVATSum = cmCalculateVATSum(vSrvRow.VATRate, vSrvRow.Sum, vSrvRow.AccountingDate);
		mSumWithoutVAT = vSrvRow.Sum - vVATSum;
		mVATRate = vSrvRow.VATRate;
		mVATSum = vVATSum;
		mSum = vSrvRow.Sum;
		// Set parameters
		vRow.Parameters.mRN = vRowNumber;
		vRow.Parameters.mDescription = mDescription;
		vRow.Parameters.mUnit = ?(IsBlankString(mUnit), "---", mUnit);
		vRow.Parameters.mUnitCode = ?(IsBlankString(mUnitCode), "", mUnitCode);
		vRow.Parameters.mQuantity = Format(mQuantity, "ND=10; NFD=3; NZ=");
		vRow.Parameters.mPrice = Format(mPrice, "ND=17; NFD=2");
		vRow.Parameters.mSumWithoutVAT = ?(mSumWithoutVAT = 0, "-----", Format(mSumWithoutVAT, "ND=17; NFD=2"));
		vRow.Parameters.mVATRate = TrimAll(mVATRate);
		vRow.Parameters.mVATSum = ?(mVATSum = 0, "-----", Format(mVATSum, "ND=17; NFD=2"));
		vRow.Parameters.mSum = ?(mSum = 0, "-----", Format(mSum, "ND=17; NFD=2"));
		// Check if we can print footer completely
		If (vServices.IndexOf(vSrvRow) + 1) = vServices.Count() Then
			vFooterAreas.Insert(0, vRow);
			If Not vSpreadsheet.CheckPut(vFooterAreas) Then
				vSpreadsheet.PutHorizontalPageBreak();
				vSpreadsheet.Put(vTableHeader);
			EndIf;
			vFooterAreas.Delete(0);
		Else
			If Not vSpreadsheet.CheckPut(vRow) Then
				vSpreadsheet.PutHorizontalPageBreak();
				vSpreadsheet.Put(vTableHeader);
			EndIf;
		EndIf;
		// Put row
		vSpreadsheet.Put(vRow);
		vRowNumber = vRowNumber + 1;
	EndDo;
	
	// Put footer areas
	For Each vFooterArea In vFooterAreas Do
		vSpreadsheet.Put(vFooterArea);
	EndDo;

	// Check authorities
	cmSetSpreadsheetProtection(vSpreadsheet);
EndProcedure // pmPrintVATInvoice

// -----------------------------------------------------------------------------
Procedure pmPostToAccountsAndPayments(rFolioList = Undefined) Export
	If rFolioList = Undefined Then
		rFolioList = New ValueList();
	EndIf;
	
	// Clear movements
	RegisterRecords.Accounts.Clear();
	RegisterRecords.Accounts.Write();
	RegisterRecords.Payments.Clear();
	RegisterRecords.Payments.Write();
	RegisterRecords.PaymentServices.Clear();
	RegisterRecords.PaymentServices.Write();
	RegisterRecords.PostingsFO.Clear();
	RegisterRecords.PostingsFO.Write();
	
	// Check should we group services by payment sections
	vUsePaymentSections = False;
	vUseChequeServices = False;
	If ValueIsFilled(Hotel) Then
		If Hotel.SplitFolioBalanceByPaymentSections Then
			vUsePaymentSections = True;
		EndIf;
		If Hotel.SplitFolioBalanceByServicesAndPrices Then
			vUseChequeServices = True;
		EndIf;
	EndIf;	
	
	// Check should we write to payment services
	vUsePaymentServices = Hotel.DoPaymentsDistributionToServices;
	
	// Do expense movement for each folio
	vDoWrite2Accounts = False;
	If ValueIsFilled(Company) And Not Company.SettlementsDoNotChangeFolioBalances Then
		
		// Group services by folio
		vServices = New ValueTable();
		If Not vUsePaymentSections And Not vUseChequeServices Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	SettlementServices.Folio AS Folio,
			|	SettlementServices.Folio.PaymentMethod AS FolioPaymentMethod,
			|	SettlementServices.Folio.PaymentMethod.IsByBankTransfer AS FolioPaymentMethodIsByBankTransfer,
			|	SettlementServices.Folio.Customer AS FolioCustomer,
			|	SettlementServices.Folio.Customer.IsIndividual AS FolioCustomerIsIndividual,
			|	SettlementServices.Folio.FinancialAccount AS FolioFinancialAccount,
			|	SettlementServices.Folio.ParentDoc AS FolioParentDoc,
			|	SettlementServices.VATRate AS VATRate,
			|	&qEmptyPaymentSection AS PaymentSection,
			|	SUM(SettlementServices.VATSum) AS VATSum,
			|	SUM(SettlementServices.Sum) AS Sum
			|FROM
			|	(SELECT
			|		SettlementServices1.Charge.Folio AS Folio,
			|		SettlementServices1.VATRate AS VATRate,
			|		ISNULL(Accounts1.VATSum, 0) AS VATSum,
			|		ISNULL(Accounts1.Sum, 0) AS Sum
			|	FROM
			|		Document.Settlement.Services AS SettlementServices1
			|			LEFT JOIN AccumulationRegister.Accounts AS Accounts1
			|			ON SettlementServices1.Charge = Accounts1.Recorder
			|	WHERE
			|		SettlementServices1.Ref = &qRef
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		SettlementServices2.Charge.Folio,
			|		SettlementServices2.VATRate,
			|		ISNULL(Accounts2.VATSum, 0),
			|		ISNULL(Accounts2.Sum, 0)
			|	FROM
			|		Document.Settlement.Services AS SettlementServices2
			|			LEFT JOIN AccumulationRegister.Accounts AS Accounts2
			|			ON SettlementServices2.Charge = Accounts2.Recorder.ParentCharge
			|	WHERE
			|		SettlementServices2.Ref = &qRef) AS SettlementServices
			|
			|GROUP BY
			|	SettlementServices.Folio,
			|	SettlementServices.VATRate,
			|	SettlementServices.Folio.PaymentMethod,
			|	SettlementServices.Folio.PaymentMethod.IsByBankTransfer,
			|	SettlementServices.Folio.Customer,
			|	SettlementServices.Folio.Customer.IsIndividual,
			|	SettlementServices.Folio.FinancialAccount,
			|	SettlementServices.Folio.ParentDoc
			|
			|HAVING
			|	SUM(SettlementServices.Sum) <> 0";
			vQry.SetParameter("qRef", Ref);
			vQry.SetParameter("qEmptyPaymentSection", Catalogs.PaymentSections.EmptyRef());
			vServices = vQry.Execute().Unload();
		ElsIf vUsePaymentSections And Not vUseChequeServices Then 
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	SettlementServices.Folio AS Folio,
			|	SettlementServices.Folio.PaymentMethod AS FolioPaymentMethod,
			|	SettlementServices.Folio.PaymentMethod.IsByBankTransfer AS FolioPaymentMethodIsByBankTransfer,
			|	SettlementServices.Folio.Customer AS FolioCustomer,
			|	SettlementServices.Folio.Customer.IsIndividual AS FolioCustomerIsIndividual,
			|	SettlementServices.Folio.FinancialAccount AS FolioFinancialAccount,
			|	SettlementServices.Folio.ParentDoc AS FolioParentDoc,
			|	SettlementServices.PaymentSection AS PaymentSection,
			|	SettlementServices.VATRate AS VATRate,
			|	SUM(SettlementServices.VATSum) AS VATSum,
			|	SUM(SettlementServices.Sum) AS Sum
			|FROM
			|	(SELECT
			|		SettlementServices1.Charge.Folio AS Folio,
			|		SettlementServices1.Charge.PaymentSection AS PaymentSection,
			|		SettlementServices1.VATRate AS VATRate,
			|		ISNULL(Accounts1.VATSum, 0) AS VATSum,
			|		ISNULL(Accounts1.Sum, 0) AS Sum
			|	FROM
			|		Document.Settlement.Services AS SettlementServices1
			|			LEFT JOIN AccumulationRegister.Accounts AS Accounts1
			|			ON SettlementServices1.Charge = Accounts1.Recorder
			|	WHERE
			|		SettlementServices1.Ref = &qRef
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		SettlementServices2.Charge.Folio,
			|		SettlementServices2.Charge.PaymentSection,
			|		SettlementServices2.VATRate,
			|		ISNULL(Accounts2.VATSum, 0),
			|		ISNULL(Accounts2.Sum, 0)
			|	FROM
			|		Document.Settlement.Services AS SettlementServices2
			|			LEFT JOIN AccumulationRegister.Accounts AS Accounts2
			|			ON SettlementServices2.Charge = Accounts2.Recorder.ParentCharge
			|	WHERE
			|		SettlementServices2.Ref = &qRef) AS SettlementServices
			|
			|GROUP BY
			|	SettlementServices.Folio,
			|	SettlementServices.PaymentSection,
			|	SettlementServices.VATRate,
			|	SettlementServices.Folio.PaymentMethod,
			|	SettlementServices.Folio.PaymentMethod.IsByBankTransfer,
			|	SettlementServices.Folio.Customer,
			|	SettlementServices.Folio.Customer.IsIndividual,
			|	SettlementServices.Folio.FinancialAccount,
			|	SettlementServices.Folio.ParentDoc
			|
			|HAVING
			|	SUM(SettlementServices.Sum) <> 0";
			vQry.SetParameter("qRef", Ref);
			vServices = vQry.Execute().Unload();
		ElsIf vUseChequeServices Then 
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	SettlementServices.Folio AS Folio,
			|	SettlementServices.Folio.PaymentMethod AS FolioPaymentMethod,
			|	SettlementServices.Folio.PaymentMethod.IsByBankTransfer AS FolioPaymentMethodIsByBankTransfer,
			|	SettlementServices.Folio.Customer AS FolioCustomer,
			|	SettlementServices.Folio.Customer.IsIndividual AS FolioCustomerIsIndividual,
			|	SettlementServices.Folio.FinancialAccount AS FolioFinancialAccount,
			|	SettlementServices.Folio.ParentDoc AS FolioParentDoc,
			|	SettlementServices.PaymentSection AS PaymentSection,
			|	SettlementServices.ChequeService AS ChequeService,
			|	SettlementServices.ChequeServicePrice AS ChequeServicePrice,
			|	SettlementServices.ChequeService.PaymentSection AS ChequeServicePaymentSection,
			|	SettlementServices.VATRate AS VATRate,
			|	SUM(SettlementServices.ChequeServiceQuantity) AS ChequeServiceQuantity,
			|	SUM(SettlementServices.VATSum) AS VATSum,
			|	SUM(SettlementServices.Sum) AS Sum
			|FROM
			|	(SELECT
			|		SettlementServices1.Charge.Folio AS Folio,
			|		SettlementServices1.Charge.PaymentSection AS PaymentSection,
			|		SettlementServices1.Service AS ChequeService,
			|		ISNULL(Accounts1.Price, 0) AS ChequeServicePrice,
			|		SettlementServices1.VATRate AS VATRate,
			|		ISNULL(Accounts1.Quantity, 0) AS ChequeServiceQuantity,
			|		ISNULL(Accounts1.VATSum, 0) AS VATSum,
			|		ISNULL(Accounts1.Sum, 0) AS Sum
			|	FROM
			|		Document.Settlement.Services AS SettlementServices1
			|			LEFT JOIN AccumulationRegister.Accounts AS Accounts1
			|			ON SettlementServices1.Charge = Accounts1.Recorder
			|	WHERE
			|		SettlementServices1.Ref = &qRef
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		SettlementServices2.Charge.Folio,
			|		SettlementServices2.Charge.PaymentSection,
			|		SettlementServices2.Service,
			|		ISNULL(Accounts2.Price, 0),
			|		SettlementServices2.VATRate,
			|		ISNULL(Accounts2.Quantity, 0),
			|		ISNULL(Accounts2.VATSum, 0),
			|		ISNULL(Accounts2.Sum, 0)
			|	FROM
			|		Document.Settlement.Services AS SettlementServices2
			|			LEFT JOIN AccumulationRegister.Accounts AS Accounts2
			|			ON SettlementServices2.Charge = Accounts2.Recorder.ParentCharge
			|	WHERE
			|		SettlementServices2.Ref = &qRef) AS SettlementServices
			|
			|GROUP BY
			|	SettlementServices.Folio,
			|	SettlementServices.PaymentSection,
			|	SettlementServices.ChequeService,
			|	SettlementServices.ChequeServicePrice,
			|	SettlementServices.ChequeService.PaymentSection,
			|	SettlementServices.VATRate,
			|	SettlementServices.Folio.PaymentMethod,
			|	SettlementServices.Folio.PaymentMethod.IsByBankTransfer,
			|	SettlementServices.Folio.Customer,
			|	SettlementServices.Folio.Customer.IsIndividual,
			|	SettlementServices.Folio.FinancialAccount,
			|	SettlementServices.Folio.ParentDoc
			|
			|HAVING
			|	SUM(SettlementServices.Sum) <> 0";
			vQry.SetParameter("qRef", Ref);
			vServices = vQry.Execute().Unload();
		EndIf;
		
		// Build value table with folio balances
		vFolios = vServices.Copy(, "Folio");
		vFolios.GroupBy("Folio", );
		vFoliosArray = vFolios.UnloadColumn("Folio");
		vFoliosList = New ValueList();
		vFoliosList.LoadValues(vFoliosArray);
		If Not vUsePaymentSections And Not vUseChequeServices Then
			vBalances = cmGetFoliosBalance('39991231235959', Hotel, Undefined, vFoliosList);
		ElsIf vUsePaymentSections Then
			vBalances = cmGetFoliosBalanceByPaymentSections('39991231235959', Hotel, Undefined, vFoliosList);
		ElsIf vUseChequeServices Then
			vBalances = cmGetFoliosBalanceByServicesAndPrices('39991231235959', Hotel, Undefined, vFoliosList);
		EndIf;
		// Get folio balance
		vFolioBalances = cmGetFoliosBalance('39991231235959', Hotel, Undefined, vFoliosList);
	
		// Do for each folio with balance
		For Each vServicesRow In vServices Do
			// Check folio payment method 
			If ValueIsFilled(vServicesRow.FolioPaymentMethod) And vServicesRow.FolioPaymentMethodIsByBankTransfer And 
			   ValueIsFilled(vServicesRow.FolioCustomer) And Not vServicesRow.FolioCustomerIsIndividual Then
				vChequeServicePrice = 0;
				vServicesRow.VATSum = cmCalculateVATSum(vServicesRow.VATRate, vServicesRow.Sum, Date);
			   
				// Find folio balances row
				vBalancesRow = Undefined;
				vFolioBalancesRow = Undefined;
				If Not vUsePaymentSections And Not vUseChequeServices Then
					vBalancesRows = vBalances.FindRows(New Structure("Folio", vServicesRow.Folio));
					If vBalancesRows.Count() > 0 Then
						vBalancesRow = vBalancesRows.Get(0);
					EndIf;
				ElsIf vUsePaymentSections And Not vUseChequeServices Then
					vBalancesRows = vBalances.FindRows(New Structure("Folio, PaymentSection", vServicesRow.Folio, vServicesRow.PaymentSection));
					If vBalancesRows.Count() > 0 Then
						vBalancesRow = vBalancesRows.Get(0);
					EndIf;
				ElsIf vUseChequeServices Then
					vChequeServicePrice = vServicesRow.ChequeServicePrice;
					If vServicesRow.ChequeServiceQuantity <> 0 Then
						vChequeServicePrice = Round(vServicesRow.Sum / vServicesRow.ChequeServiceQuantity, 2);
					EndIf;
					vBalancesRows = vBalances.FindRows(New Structure("Folio, ChequeService, ChequeServicePrice", vServicesRow.Folio, vServicesRow.ChequeService, vChequeServicePrice));
					If vBalancesRows.Count() > 0 Then
						vBalancesRow = vBalancesRows.Get(0);
					EndIf;
				EndIf;
				vFolioBalancesRows = vFolioBalances.FindRows(New Structure("Folio", vServicesRow.Folio));
				If vFolioBalancesRows.Count() > 0 Then
					vFolioBalancesRow = vFolioBalancesRows.Get(0);
				EndIf;
				If vBalancesRow <> Undefined And vFolioBalancesRow <> Undefined And vFolioBalancesRow.SumBalance <= 0 Then
					vBalancesRow.SumBalance = 0;
				EndIf;
				
				// Stop processing if folio balance is zero
				If vBalancesRow <> Undefined And vBalancesRow.SumBalance <> 0 And 
				   vFolioBalancesRow <> Undefined And vFolioBalancesRow.SumBalance <> 0 Then
					If vBalancesRow.SumBalance >= 0 Then
						If vServicesRow.Sum >= 0 Then
							If vServicesRow.Sum > vBalancesRow.SumBalance Then
								vServicesRow.Sum = vBalancesRow.SumBalance;
							EndIf;
						EndIf;
					Else
						If vServicesRow.Sum < 0 Then
							If vServicesRow.Sum < vBalancesRow.SumBalance Then
								vServicesRow.Sum = vBalancesRow.SumBalance;
							EndIf;
						EndIf;
					EndIf;
					If vFolioBalancesRow <> Undefined Then
						If vFolioBalancesRow.SumBalance >=0 Then
							If vServicesRow.Sum >= 0 Then
								If vServicesRow.Sum > vFolioBalancesRow.SumBalance Then
									vServicesRow.Sum = vFolioBalancesRow.SumBalance;
								EndIf;
							EndIf;
						Else
							If vServicesRow.Sum < 0 Then
								If vServicesRow.Sum < vFolioBalancesRow.SumBalance Then
									vServicesRow.Sum = vFolioBalancesRow.SumBalance;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
					vBalancesRow.SumBalance = vBalancesRow.SumBalance - vServicesRow.Sum;
					
					vFolioBalanceSignBefore = ?(vFolioBalancesRow.SumBalance >= 0, 1, -1);
					vFolioBalancesRow.SumBalance = vFolioBalancesRow.SumBalance - vServicesRow.Sum;
					vFolioBalanceSignAfter = ?(vFolioBalancesRow.SumBalance >= 0, 1, -1);
					
					If vFolioBalanceSignBefore <> vFolioBalanceSignAfter Then
						Break;
					EndIf;
				Else
					Continue;
				EndIf;			

				// Do movement
				Movement = RegisterRecords.Accounts.Add();
				
				Movement.RecordType = AccumulationRecordType.Expense;
				Movement.Period = Date;
				
				FillPropertyValues(Movement, ThisObject);
				FillPropertyValues(Movement, vServicesRow.Folio);
				FillPropertyValues(Movement, vServicesRow);
				
				// Attributes
				Movement.PaymentMethod = PaymentMethod;
				Movement.ParentDoc = ParentDoc;
				
				// Save list of folios closed with settlement
				If rFolioList.FindByValue(Movement.Folio) = Undefined Then
					rFolioList.Add(Movement.Folio);
				EndIf;
				
				// Payment section
				If Not vUsePaymentSections And Not vUseChequeServices Then
					Movement.PaymentSection = Catalogs.PaymentSections.EmptyRef();
					Movement.ChequeService = Catalogs.Services.EmptyRef();
					Movement.ChequeServicePrice = 0;
					Movement.ChequeServiceQuantity = 0;
				ElsIf vUsePaymentSections Then
					Movement.PaymentSection = vServicesRow.PaymentSection;
					Movement.ChequeService = Catalogs.Services.EmptyRef();
					Movement.ChequeServicePrice = 0;
					Movement.ChequeServiceQuantity = 0;
				ElsIf vUseChequeServices Then
					Movement.ChequeService = vServicesRow.ChequeService;
					Movement.PaymentSection = Catalogs.PaymentSections.EmptyRef();
					If ValueIsFilled(Movement.ChequeService) Then
						Movement.PaymentSection = vServicesRow.ChequeServicePaymentSection;
					Endif;
					Movement.ChequeServicePrice = vChequeServicePrice;
					Movement.ChequeServiceQuantity = vServicesRow.ChequeServiceQuantity;
				EndIf;
				
				vDoWrite2Accounts = True;
			EndIf;
		EndDo;
				
		// Group services by payment sections
		vServices.GroupBy("Folio, FolioPaymentMethod, FolioPaymentMethodIsByBankTransfer, FolioCustomer, FolioCustomerIsIndividual, FolioFinancialAccount, FolioParentDoc, PaymentSection, VATRate", "VATSum, Sum");
		
		// Create value table for FO postings
		vFOPostings = vServices.Copy(, "Folio, FolioFinancialAccount, FolioParentDoc, Sum");
		vFOPostings.Clear();
		
		For Each vServicesRow In vServices Do
			// Check folio payment method 
			If ValueIsFilled(vServicesRow.FolioPaymentMethod) And vServicesRow.FolioPaymentMethodIsByBankTransfer And 
			   ValueIsFilled(vServicesRow.FolioCustomer) And Not vServicesRow.FolioCustomerIsIndividual Then
				// Write to payments
				Movement = RegisterRecords.Payments.Add();
				
				Movement.Period = Date;
				
				FillPropertyValues(Movement, ThisObject);
				FillPropertyValues(Movement, vServicesRow);
				
				// Dimensions
				Movement.PaymentCurrency = AccountingCurrency;
				Movement.Payer = AccountingCustomer;
				Movement.AccountingDate = BegOfDay(Date);
				
				// Resources
				If vServicesRow.Sum >= 0 Then
					Movement.SumReceipt = vServicesRow.Sum;
					Movement.VATSumReceipt = vServicesRow.VATSum;
					Movement.SumExpense = 0;
					Movement.VATSumExpense = 0;
				Else
					Movement.SumReceipt = 0;
					Movement.VATSumReceipt = 0;
					Movement.SumExpense = -vServicesRow.Sum;
					Movement.VATSumExpense = -vServicesRow.VATSum;
				EndIf;
				
				// Post to FO chart of accounts
				vFOPostingsRow = vFOPostings.Add();
				vFOPostingsRow.Sum = vServicesRow.Sum;
				vFOPostingsRow.Folio = vServicesRow.Folio;
				
				// Write to payment services
				If vUsePaymentServices Then
					Movement = RegisterRecords.PaymentServices.Add();
					
					Movement.RecordType = AccumulationRecordType.Expense;
					Movement.Period = Date;
					
					Movement.Folio = vServicesRow.Folio;
					Movement.Service = Catalogs.Services.EmptyRef();
					Movement.Payment = Ref;
					
					// Fill resources
					Movement.Sum = vServicesRow.Sum;
				EndIf;
			EndIf;
		EndDo;
		
		// Post to FO chart of accounts
		vFOPostings.GroupBy("Folio, FolioFinancialAccount, FolioParentDoc", "Sum");
		For Each vFOPostingsRow In vFOPostings Do
			WriteGuestLedgerFOPostings(vFOPostingsRow.Sum, vFOPostingsRow.Folio, vFOPostingsRow.FolioFinancialAccount, vFOPostingsRow.FolioParentDoc);
		EndDo;
	EndIf;
	
	// Post to FO chart of accounts to the city ledger account
	WriteCityLedgerFOPostings();
		
	// Write records
	If vDoWrite2Accounts Then
		RegisterRecords.Accounts.Write();
		RegisterRecords.Payments.Write();
		If vUsePaymentServices Then
			RegisterRecords.PaymentServices.Write();
		EndIf;
	EndIf;
	RegisterRecords.PostingsFO.Write();
	
	// Reset auto write mode
	RegisterRecords.Accounts.Write = False;
	RegisterRecords.Payments.Write = False;
	RegisterRecords.PaymentServices.Write = False;
	RegisterRecords.PostingsFO.Write = False;
EndProcedure // pmPostToAccountsAndPayments

// -----------------------------------------------------------------------------
Function pmCheckDocumentAttributes(pMessage, pAttributeInErr) Export
	vHasErrors = False;
	pMessage = "";
	pAttributeInErr = "";
	vMsgTextRu = "";
	vMsgTextEn = "";
	vMsgTextDe = "";
	If AdditionalProperties.Property("InfoBaseUpdateMode") And AdditionalProperties.InfoBaseUpdateMode Then
		Return vHasErrors;
	EndIf;
	If Not ValueIsFilled(Hotel) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Гостиница> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Hotel> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Hotel> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Hotel", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(Company) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Фирма> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Company> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Company> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Company", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(AccountingCustomer) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Контрагент> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Customer> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Customer> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "AccountingCustomer", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(AccountingCurrency) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Валюта акта> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Accounting currency> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Accounting currency> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "AccountingCurrency", pAttributeInErr);
	EndIf;
	If vHasErrors Then
		pMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // pmCheckDocumentAttributes

// -----------------------------------------------------------------------------
Procedure pmFillAuthorAndDate() Export
	If Not ValueIsFilled(Date) Then
		Date = CurrentSessionDate();
	EndIf;
	Author = SessionParameters.CurrentUser;
EndProcedure // pmFillAuthorAndDate

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill author and document date
	pmFillAuthorAndDate();
	// Fill from session parameters
	PaymentMethod = Catalogs.PaymentMethods.Settlement;
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If Not ValueIsFilled(AccountingCurrency) Then
			AccountingCurrency = Hotel.FolioCurrency;
		EndIf;
		If ValueIsFilled(Company) Then
			If Not ValueIsFilled(BankAccount) Then
				If ValueIsFilled(Company.BankAccount) And (Company.BankAccount.Hotel = Hotel Or Company.BankAccount.Hotel = Catalogs.Hotels.EmptyRef()) Then
					BankAccount = Company.BankAccount;
				Else
					vQry = New Query();
					
					vQry.Text = 
					"SELECT TOP 1
					|	BankAccounts.Ref AS Ref
					|FROM
					|	Catalog.BankAccounts AS BankAccounts
					|WHERE
					|	NOT BankAccounts.DeletionMark
					|	AND BankAccounts.Owner = &qOwner
					|	AND (BankAccounts.Hotel = &qHotel
					|			OR BankAccounts.Hotel = VALUE(Catalog.Hotels.EmptyRef))
					|
					|ORDER BY
					|	BankAccounts.Hotel DESC";
					vQry.SetParameter("qHotel", Hotel);
					vQry.SetParameter("qOwner", Company);  
					vRes = vQry.Execute();
					vSel = vRes.Select();
					If vSel.Next() Then
						BankAccount = vSel.Ref;
					EndIf;	
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(Company) Then
			If Not IsBlankString(Company.Consignor) Then
				Consignor = TrimR(Company.Consignor);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Procedure pmFillServices(pCharges, pLanguage = Undefined) Export
	For Each vFolioChargesRow In pCharges Do
		If ValueIsFilled(vFolioChargesRow.Charge) Then
			If vFolioChargesRow.Company <> Company Then
				Continue;
			EndIf;
			If Not IsBlankString(FolioDescription) And 
			   lower(TrimAll(vFolioChargesRow.FolioDescription)) <> lower(TrimAll(FolioDescription)) Then
				Continue;
			EndIf;
			
			vCharge = vFolioChargesRow.Charge;

			// Add service
			vServicesRow = Services.Add();
			If ValueIsFilled(vFolioChargesRow.Folio) Then
				vServicesRow.Client = vFolioChargesRow.Folio.Client;
				vServicesRow.Room = vFolioChargesRow.Folio.Room;
			EndIf;
			vParentDoc = vFolioChargesRow.ParentDoc;
			If ValueIsFilled(vParentDoc) Then
				If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Or 
				   TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Then
					vServicesRow.Client = vParentDoc.Guest;
					vServicesRow.Room = vParentDoc.Room;
					vServicesRow.AccommodationType = vParentDoc.AccommodationType;
					vServicesRow.NumberOfPersons = vParentDoc.NumberOfPersons;
				ElsIf TypeOf(vParentDoc) = Type("DocumentRef.ResourceReservation") Then
					vServicesRow.Client = vParentDoc.Client;
					vServicesRow.Resource = vParentDoc.Resource;
					vServicesRow.NumberOfPersons = vParentDoc.NumberOfPersons;
				EndIf;
			EndIf;
			FillPropertyValues(vServicesRow, vCharge);
			FillPropertyValues(vServicesRow, vFolioChargesRow);
			vServicesRow.AccountingDate = BegOfDay(vCharge.Date);
			vServicesRow.Sum = vFolioChargesRow.SumBalance;
			vServicesRow.VATSum = vFolioChargesRow.VATSumBalance;
			vServicesRow.Quantity = vFolioChargesRow.QuantityBalance;
			vServicesRow.Price = cmRecalculatePrice(vServicesRow.Sum, vServicesRow.Quantity);
			// Commission
			If ValueIsFilled(vFolioChargesRow.Folio) Then
				vServicesRow.Agent = vFolioChargesRow.Folio.Agent;
			EndIf;
			vServicesRow.AgentCommissionType = vCharge.AgentCommissionType;
			vServicesRow.AgentCommission = vCharge.AgentCommission;
			vServicesRow.CommissionSum = vFolioChargesRow.CommissionSumBalance;
			vServicesRow.VATCommissionSum = cmCalculateVATSum(vServicesRow.VATRate, vServicesRow.CommissionSum, vServicesRow.AccountingDate);
			If vServicesRow.CommissionSum = 0 And vServicesRow.VATCommissionSum = 0 And 
			   ValueIsFilled(vServicesRow.AgentCommissionType) Then
				vServicesRow.AgentCommissionType = Undefined;
				vServicesRow.AgentCommission = 0;
			EndIf;				
			// Fill remarks by service description by default
			vServiceDescription = TrimAll(vServicesRow.Service);
			If ValueIsFilled(vServicesRow.Service) Then
				vServiceObj = vServicesRow.Service.GetObject();
				vServiceDescription = vServiceObj.pmGetServiceDescription(pLanguage);
			EndIf;
			vServicesRow.Remarks = vServiceDescription + 
			                       ?(IsBlankString(vServicesRow.Remarks), "", " - " + cmNStr(vServicesRow.Remarks, pLanguage));
		EndIf;
	EndDo;
EndProcedure // pmFillServices	

// -----------------------------------------------------------------------------
// Fill list of payments
// -----------------------------------------------------------------------------
Procedure pmFillListOfPayments() Export
	PaymentDocuments.Clear();
	// Fill from folio payments
	vFolios = Services.Unload(, "Folio");
	vFolios.GroupBy("Folio", );
	For Each vFoliosRow In vFolios Do
		vPayments = vFoliosRow.Folio.GetObject().pmGetAllFolioPayments(True, True);
		// First run selects payments for the invoice guest group only
		If ValueIsFilled(GuestGroup) Then
			For Each vPaymentsRow In vPayments Do
				vRowDocument = vPaymentsRow.Document;
				If ValueIsFilled(vRowDocument) And TypeOf(vRowDocument) <> Type("DocumentRef.Preauthorisation") And 
				   vPaymentsRow.PaymentMethod <> Catalogs.PaymentMethods.Settlement Then
					If TypeOf(vRowDocument) = Type("DocumentRef.Payment") Or TypeOf(vRowDocument) = Type("DocumentRef.Return") Then
						If vRowDocument.GuestGroup <> GuestGroup Then
							Continue;
						EndIf;
					ElsIf TypeOf(vRowDocument) = Type("DocumentRef.DepositTransfer") Then
						If Not ValueIsFilled(vRowDocument.ParentDoc) Then
							Continue;
						ElsIf TypeOf(vRowDocument.ParentDoc) = Type("DocumentRef.Reservation") Or
						      TypeOf(vRowDocument.ParentDoc) = Type("DocumentRef.ResourceReservation") Or
						      TypeOf(vRowDocument.ParentDoc) = Type("DocumentRef.Accommodation") Or
						      TypeOf(vRowDocument.ParentDoc) = Type("DocumentRef.Folio") Then
							If vRowDocument.ParentDoc.GuestGroup <> GuestGroup Then
								Continue;
							EndIf;
						EndIf;
					EndIf;
					// Check if this payment is in some other invoice already
					If PaymentDocuments.Find(vRowDocument, "PaymentDoc") = Undefined Then
						If Not pmPaymentIsInSomeInvoiceAlready(vRowDocument, vPaymentsRow.Sum) Then
							vRow = PaymentDocuments.Insert(0);
							vRow.PaymentDoc = vRowDocument;
							vRow.PaymentDocNumber = cmGetDocumentNumberPresentation(vPaymentsRow.Number);
							vRow.PaymentDocDate = vRowDocument.Date;
							vRow.Sum = Round(cmConvertCurrencies(vPaymentsRow.Sum, vPaymentsRow.FolioCurrency, , AccountingCurrency, , Date, Hotel), 2);

							If Services.Total("Sum") <= PaymentDocuments.Total("Sum") Then
								Break;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		// Second run selects payments for the orders mentioned in invoice
		If Services.Total("Sum") > PaymentDocuments.Total("Sum") Then
			vOrdersList = New ValueList();
			For Each vSrvRow In Services Do
				If ValueIsFilled(vSrvRow.Charge) Then
					vRowCharge = vSrvRow.Charge;
					If vRowCharge.IsAdditional Then
						vChargeOrder = Orders.GetChargeOrder(vRowCharge);
						If ValueIsFilled(vChargeOrder) Then
							If vOrdersList.FindByValue(vChargeOrder) = Undefined Then
								vOrdersList.Add(vChargeOrder);
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
			If vOrdersList.Count() > 0 Then
				For Each vPaymentsRow In vPayments Do
					vRowDocument = vPaymentsRow.Document;
					If ValueIsFilled(vRowDocument) And 
					  (TypeOf(vRowDocument) = Type("DocumentRef.Payment") Or TypeOf(vRowDocument) = Type("DocumentRef.Return")) And 
					   vPaymentsRow.PaymentMethod <> Catalogs.PaymentMethods.Settlement And 
					   ValueIsFilled(vRowDocument.Order) Then
						If vOrdersList.FindByValue(vRowDocument.Order) = Undefined Then
							Continue;
						EndIf;
						// Check if this payment is in some other invoice already
						If PaymentDocuments.Find(vRowDocument, "PaymentDoc") = Undefined Then
							If Not pmPaymentIsInSomeInvoiceAlready(vRowDocument, vPaymentsRow.Sum) Then
								vRow = PaymentDocuments.Insert(0);
								vRow.PaymentDoc = vRowDocument;
								vRow.PaymentDocNumber = cmGetDocumentNumberPresentation(vPaymentsRow.Number);
								vRow.PaymentDocDate = vRowDocument.Date;
								vRow.Sum = Round(cmConvertCurrencies(vPaymentsRow.Sum, vPaymentsRow.FolioCurrency, , AccountingCurrency, , Date, Hotel), 2);

								If Services.Total("Sum") <= PaymentDocuments.Total("Sum") Then
									Break;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		// Third run uses all payments left to get amount of the invoice
		If Services.Total("Sum") > PaymentDocuments.Total("Sum") Then
			For Each vPaymentsRow In vPayments Do
				vRowDocument = vPaymentsRow.Document;
				If ValueIsFilled(vRowDocument) And TypeOf(vRowDocument) <> Type("DocumentRef.Preauthorisation") And 
				   vPaymentsRow.PaymentMethod <> Catalogs.PaymentMethods.Settlement Then
					// Check if this payment is in some other invoice already
					If PaymentDocuments.Find(vRowDocument, "PaymentDoc") = Undefined Then
						If Not pmPaymentIsInSomeInvoiceAlready(vRowDocument, vPaymentsRow.Sum) Then
							vRow = PaymentDocuments.Insert(0);
							vRow.PaymentDoc = vRowDocument;
							vRow.PaymentDocNumber = cmGetDocumentNumberPresentation(vPaymentsRow.Number);
							vRow.PaymentDocDate = vRowDocument.Date;
							vRow.Sum = Round(cmConvertCurrencies(vPaymentsRow.Sum, vPaymentsRow.FolioCurrency, , AccountingCurrency, , Date, Hotel), 2);

							If Services.Total("Sum") <= PaymentDocuments.Total("Sum") Then
								Break;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	// Fill from customer payments
	If Services.Total("Sum") > PaymentDocuments.Total("Sum") Then
		vGroups = Services.Unload(, "GuestGroup");
		vGroups.GroupBy("GuestGroup", );
		For Each vGroupsRow In vGroups Do
			If ValueIsFilled(vGroupsRow.GuestGroup) Then
				vPayments = pmGetAllGuestGroupCustomerPayments(vGroupsRow.GuestGroup);
				For Each vPaymentsRow In vPayments Do
					vRowDocument = vPaymentsRow.Document;
					If ValueIsFilled(vRowDocument) And TypeOf(vRowDocument) <> Type("DocumentRef.Preauthorisation") And 
					   vPaymentsRow.PaymentMethod <> Catalogs.PaymentMethods.Settlement Then
						// Check if this payment is in some other invoice already
						If PaymentDocuments.Find(vRowDocument, "PaymentDoc") = Undefined Then
							If Not pmPaymentIsInSomeInvoiceAlready(vRowDocument) Then
								vRow = PaymentDocuments.Add();
								vRow.PaymentDoc = vRowDocument;
								vRow.PaymentDocNumber = cmGetDocumentNumberPresentation(vPaymentsRow.Number);
								vRow.PaymentDocDate = vPaymentsRow.Date;
								vRow.Sum = Round(cmConvertCurrencies(vPaymentsRow.Sum, vPaymentsRow.PaymentCurrency, , AccountingCurrency, , Date, Hotel), 2);

								If Services.Total("Sum") <= PaymentDocuments.Total("Sum") Then
									Break;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				EndDo;
			EndIf;

			If Services.Total("Sum") <= PaymentDocuments.Total("Sum") Then
				Break;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // pmFillListOfPayments

// -----------------------------------------------------------------------------
Function pmPaymentIsInSomeInvoiceAlready(pPaymentDoc, pSum = 0) Export
	vResult = False;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SettlementPaymentDocuments.Ref,
	|	SettlementPaymentDocuments.Sum
	|FROM
	|	Document.Settlement.PaymentDocuments AS SettlementPaymentDocuments
	|WHERE
	|	SettlementPaymentDocuments.PaymentDoc = &qPaymentDoc
	|	AND SettlementPaymentDocuments.Ref <> &qRef
	|	AND SettlementPaymentDocuments.Ref.Posted";
	vQry.SetParameter("qPaymentDoc", pPaymentDoc);
	vQry.SetParameter("qRef", Ref);
	vOtherInvoices = vQry.Execute().Unload();
	If vOtherInvoices.Count() > 0 Then
		If TypeOf(pPaymentDoc) = Type("DocumentRef.DepositTransfer") Then
			For Each vOtherInvoicesRow In vOtherInvoices Do
				If pSum >= 0 Then
					If vOtherInvoicesRow.Sum >= 0 Then
						vResult = True;
						Break;
					EndIf;
				Else
					If vOtherInvoicesRow.Sum < 0 Then
						vResult = True;
						Break;
					EndIf;
				EndIf;
			EndDo;
		Else
			vResult = True;
		EndIf;
	EndIf;
	Return vResult;
EndFunction // pmPaymentIsInSomeInvoiceAlready

// -----------------------------------------------------------------------------
Function pmGetAllGuestGroupCustomerPayments(pGuestGroup) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CustomerPaymentDocuments.Ref AS Document,
	|	CustomerPaymentDocuments.PaymentMethod AS PaymentMethod,
	|	CustomerPaymentDocuments.Sum AS Sum,
	|	CustomerPaymentDocuments.PaymentCurrency AS PaymentCurrency,
	|	CustomerPaymentDocuments.Number AS Number,
	|	CustomerPaymentDocuments.Date AS Date
	|FROM
	|	Document.CustomerPayment AS CustomerPaymentDocuments
	|WHERE
	|	CustomerPaymentDocuments.GuestGroup = &qGuestGroup
	|	AND CustomerPaymentDocuments.AccountingCustomer = &qAccountingCustomer
	|	AND CustomerPaymentDocuments.AccountingContract = &qAccountingContract
	|	AND CustomerPaymentDocuments.Posted
	|
	|ORDER BY
	|	CustomerPaymentDocuments.PointInTime";
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vQry.SetParameter("qAccountingCustomer", AccountingCustomer);
	vQry.SetParameter("qAccountingContract", AccountingContract);
	vRes = vQry.Execute().Unload();
	Return vRes;
EndFunction // pmGetAllGuestGroupCustomerPayments

// -----------------------------------------------------------------------------
Procedure pmFillByFolio(pFolio) Export
	If Not ValueIsFilled(pFolio) Then
		Return;
	EndIf;
	
	If ValueIsFilled(pFolio.Hotel) Then
		If Hotel <> pFolio.Hotel Then
			Hotel = pFolio.Hotel;
			SetNewNumber(Catalogs.Hotels.pmGetPrefix(Hotel));
		EndIf;
	EndIf;
	
	ParentDoc = pFolio;
	
	// Fill currency
	If Not ValueIsFilled(AccountingCurrency) Or Not AdditionalProperties.Property("DoNotUpdateCurrency") Then
		AccountingCurrency = pFolio.FolioCurrency;
	EndIf;
	
	// Fill company
	If ValueIsFilled(pFolio.Company) Then
		Company = pFolio.Company;
	Else
		If ValueIsFilled(Hotel) Then
			If ValueIsFilled(Hotel.Company) Then
				Company = Hotel.Company;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(Company) And Not ValueIsFilled(BankAccount) Then
		If Not ValueIsFilled(BankAccount) Or ValueIsFilled(BankAccount) And BankAccount.Owner <> Company Then
			BankAccount = Company.BankAccount;
		EndIf;
		If Not IsBlankString(Company.Consignor) Then
			Consignor = TrimR(Company.Consignor);
		EndIf;
	EndIf;
	
	// Fill accounting customer, contract and guest group
	AccountingCustomer = pFolio.Customer;
	AccountingContract = pFolio.Contract;
	GuestGroup = pFolio.GuestGroup;
	If Not ValueIsFilled(AccountingCustomer) Then
		If ValueIsFilled(Hotel) Then
			AccountingCustomer = Hotel.IndividualsCustomer;
			AccountingContract = Hotel.IndividualsContract;
		EndIf;
	EndIf;
	If ValueIsFilled(AccountingCustomer) Then
		If Not IsBlankString(AccountingCustomer.Consignee) Then
			Consignee = TrimR(AccountingCustomer.Consignee);
		EndIf;
	EndIf;
	
	// Get customer language
	vLanguage = Undefined;
	If ValueIsFilled(AccountingCustomer) Then
		vLanguage = AccountingCustomer.Language;
	EndIf;
	
	// Reset totals
	Sum = 0;
	VATSum = 0;
	CommissionSum = 0;
	
	// Clear tabular part Services
	Services.Clear();
	
	// Check folio description
	If IsBlankString(FolioDescription) Or 
	   Not IsBlankString(FolioDescription) And lower(TrimAll(pFolio.Description)) = lower(TrimAll(FolioDescription)) Then
		// Get all folio current accounts receivable services with balances per end of time
		vFolioCharges = pFolio.GetObject().pmGetCurrentAccountsReceivableChargesWithBalances('39991231235959');
		
		// Fill services tabular part
		pmFillServices(vFolioCharges, vLanguage);
		
		// Fill list of payments
		PaymentDocuments.Clear();
		vPayments = pFolio.GetObject().pmGetAllFolioPayments();
		For Each vPaymentsRow In vPayments Do
			If ValueIsFilled(vPaymentsRow.Document) And TypeOf(vPaymentsRow.Document) <> Type("DocumentRef.Preauthorisation") And 
			   vPaymentsRow.PaymentMethod <> Catalogs.PaymentMethods.Settlement Then
				If Not pmPaymentIsInSomeInvoiceAlready(vPaymentsRow.Document, vPaymentsRow.Sum) Then
					vRow = PaymentDocuments.Add();
					vRow.PaymentDoc = vPaymentsRow.Document;
					vRow.PaymentDocNumber = cmGetDocumentNumberPresentation(vPaymentsRow.Number);
					vRow.PaymentDocDate = vPaymentsRow.Document.Date;
					vRow.Sum = Round(cmConvertCurrencies(vPaymentsRow.Sum, vPaymentsRow.FolioCurrency, , AccountingCurrency, , Date, Hotel), 2);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	// Fill totals
	Sum = Services.Total("Sum");
	VATSum = Services.Total("VATSum");
	CommissionSum = Services.Total("CommissionSum");
	SumDue = Sum - PaymentDocuments.Total("Sum");
	If ValueIsFilled(AccountingCustomer) And Not AccountingCustomer.DoNotPostCommission Then
		SumDue = SumDue - CommissionSum;
	EndIf;
	
	// Fill check date
	pmFillCheckDate();
	
	// Set is checked in payments generate invoices mode
	If ValueIsFilled(Hotel) And Hotel.PaymentsGenerateInvoices Then
		IsChecked = True;
	EndIf;
EndProcedure // pmFillByFolio

// -----------------------------------------------------------------------------
Procedure pmFillByDocument(pDoc, pFillCustomer = True) Export
	If Not ValueIsFilled(pDoc) Then
		Return;
	EndIf;
	
	If ValueIsFilled(pDoc.Hotel) Then
		If Hotel <> pDoc.Hotel Then
			Hotel = pDoc.Hotel;
			SetNewNumber(Catalogs.Hotels.pmGetPrefix(Hotel));
		EndIf;
	EndIf;
	
	ParentDoc = pDoc;
	
	// Fill accounting customer, contract and guest group
	If pFillCustomer Then
		vPayer = pDoc.GetObject().pmSetPlannedPaymentMethod();
		If vPayer = Enums.WhoPays.Agent Then
			AccountingCustomer = pDoc.Agent;
			AccountingContract = Catalogs.Contracts.EmptyRef();
		ElsIf ValueIsFilled(pDoc.Customer) Then
			vChargingRules = pDoc.ChargingRules.Unload();
			If TypeOf(pDoc) = Type("DocumentRef.Accommodation") Or TypeOf(pDoc) = Type("DocumentRef.Reservation") Then
				If Not pDoc.IgnoreGroupChargingRules Then
					cmAddGuestGroupChargingRules(vChargingRules, pDoc.GuestGroup);
				EndIf;
			Else
				cmAddGuestGroupChargingRules(vChargingRules, pDoc.GuestGroup);
			EndIf;
			If ValueIsFilled(pDoc.Contract) And vChargingRules.Find(pDoc.Contract, "Owner") <> Undefined Then
				AccountingCustomer = pDoc.Customer;
				AccountingContract = pDoc.Contract;
			ElsIf ValueIsFilled(pDoc.Customer) And vChargingRules.Find(pDoc.Customer, "Owner") <> Undefined Then
				AccountingCustomer = pDoc.Customer;
				AccountingContract = pDoc.Contract;
			Else
				AccountingCustomer = Hotel.IndividualsCustomer;
				AccountingContract = Hotel.IndividualsContract;
			EndIf;
		Else
			AccountingCustomer = Hotel.IndividualsCustomer;
			AccountingContract = Hotel.IndividualsContract;
		EndIf;
		GuestGroup = pDoc.GuestGroup;
		If Not ValueIsFilled(AccountingCustomer) Then
			If ValueIsFilled(Hotel) Then
				AccountingCustomer = Hotel.IndividualsCustomer;
				AccountingContract = Hotel.IndividualsContract;
			EndIf;
		EndIf;
		If ValueIsFilled(AccountingCustomer) Then
			If Not IsBlankString(AccountingCustomer.Consignee) Then
				Consignee = TrimR(AccountingCustomer.Consignee);
			EndIf;
		EndIf;
		
		// Fill currency
		If Not ValueIsFilled(AccountingCurrency) Or Not AdditionalProperties.Property("DoNotUpdateCurrency") Then
			If ValueIsFilled(AccountingContract) Then
				AccountingCurrency = AccountingContract.AccountingCurrency;
			Else
				If ValueIsFilled(AccountingCustomer) Then
					AccountingCurrency = AccountingCustomer.AccountingCurrency;
				EndIf;
			EndIf;
		EndIf;
		
		// Fill company
		If ValueIsFilled(pDoc.Company) Then
			Company = pDoc.Company;
		Else
			If ValueIsFilled(Hotel) Then
				If ValueIsFilled(Hotel.Company) Then
					Company = Hotel.Company;
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(Company) And Not ValueIsFilled(BankAccount)  Then
			If Not ValueIsFilled(BankAccount) Or ValueIsFilled(BankAccount) And BankAccount.Owner <> Company Then
				BankAccount = Company.BankAccount;
			EndIf;
			If Not IsBlankString(Company.Consignor) Then
				Consignor = TrimR(Company.Consignor);
			EndIf;
		EndIf;
	EndIf;	
	
	// Get customer language
	vLanguage = Undefined;
	If ValueIsFilled(AccountingCustomer) Then
		vLanguage = AccountingCustomer.Language;
	EndIf;
	
	// Reset totals
	Sum = 0;
	VATSum = 0;
	CommissionSum = 0;
	
	// Clear tabular part Services
	Services.Clear();
	
	// Get all folio current accounts receivable services with balances per end of time
	vCharges = cmGetCurrentAccountsReceivableChargesWithBalances(?(ValueIsFilled(CloseOfPeriod), New Boundary(CloseOfPeriod.Date + 1, BoundaryType.Excluding), '39991231235959'), AccountingCustomer, AccountingContract, ParentDoc, GuestGroup, AccountingCurrency, Hotel);
	
	// Fill services tabular part
	pmFillServices(vCharges, vLanguage);
	
	// Fill list of payments
	pmFillListOfPayments();
	
	// Fill totals
	Sum = Services.Total("Sum");
	VATSum = Services.Total("VATSum");
	CommissionSum = Services.Total("CommissionSum");
	SumDue = Sum - PaymentDocuments.Total("Sum");
	If ValueIsFilled(AccountingCustomer) And Not AccountingCustomer.DoNotPostCommission Then
		SumDue = SumDue - CommissionSum;
	EndIf;
	
	// Fill check date
	pmFillCheckDate();
	
	// Set is checked in payments generate invoices mode
	If ValueIsFilled(Hotel) And Hotel.PaymentsGenerateInvoices Then
		IsChecked = True;
	EndIf;
EndProcedure // pmFillByDocument

// -----------------------------------------------------------------------------
Procedure pmFillByResourceReservation(pDoc, pFillCustomer = True) Export
	If Not ValueIsFilled(pDoc) Then
		Return;
	EndIf;
	
	If ValueIsFilled(pDoc.Hotel) Then
		If Hotel <> pDoc.Hotel Then
			Hotel = pDoc.Hotel;
			SetNewNumber(Catalogs.Hotels.pmGetPrefix(Hotel));
		EndIf;
	EndIf;
	
	ParentDoc = pDoc;
	
	// Fill accounting customer, contract and guest group
	If pFillCustomer Then
		If ValueIsFilled(pDoc.Owner) Then
			If TypeOf(pDoc.Owner) = Type("CatalogRef.Contracts") Then
				AccountingCustomer = pDoc.Owner.Owner;
				AccountingContract = pDoc.Owner;
			Else
				AccountingCustomer = pDoc.Owner;
				AccountingContract = Catalogs.Contracts.EmptyRef();
			EndIf;
		Else
			If Not ValueIsFilled(pDoc.Customer) Then
				AccountingCustomer = Hotel.IndividualsCustomer;
				AccountingContract = Hotel.IndividualsContract;
			Else
				AccountingCustomer = pDoc.Customer;
				AccountingContract = pDoc.Contract;
			EndIf;
		EndIf;
		GuestGroup = pDoc.GuestGroup;
		If Not ValueIsFilled(AccountingCustomer) Then
			If ValueIsFilled(Hotel) Then
				AccountingCustomer = Hotel.IndividualsCustomer;
				AccountingContract = Hotel.IndividualsContract;
			EndIf;
		EndIf;
		If ValueIsFilled(AccountingCustomer) Then
			If Not IsBlankString(AccountingCustomer.Consignee) Then
				Consignee = TrimR(AccountingCustomer.Consignee);
			EndIf;
		EndIf;
		
		// Fill currency
		If Not ValueIsFilled(AccountingCurrency) Or Not AdditionalProperties.Property("DoNotUpdateCurrency") Then
			If ValueIsFilled(AccountingContract) Then
				AccountingCurrency = AccountingContract.AccountingCurrency;
			Else
				If ValueIsFilled(AccountingCustomer) Then
					AccountingCurrency = AccountingCustomer.AccountingCurrency;
				EndIf;
			EndIf;
		EndIf;
		
		// Fill company
		If ValueIsFilled(pDoc.Company) Then
			Company = pDoc.Company;
		Else
			If ValueIsFilled(Hotel) Then
				If ValueIsFilled(Hotel.Company) Then
					Company = Hotel.Company;
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(Company) And Not ValueIsFilled(BankAccount)  Then
			If Not ValueIsFilled(BankAccount) Or ValueIsFilled(BankAccount) And BankAccount.Owner <> Company Then
				BankAccount = Company.BankAccount;
			EndIf;
			If Not IsBlankString(Company.Consignor) Then
				Consignor = TrimR(Company.Consignor);
			EndIf;
		EndIf;
	EndIf;	
	
	// Get customer language
	vLanguage = Undefined;
	If ValueIsFilled(AccountingCustomer) Then
		vLanguage = AccountingCustomer.Language;
	EndIf;
	
	// Reset totals
	Sum = 0;
	VATSum = 0;
	CommissionSum = 0;
	
	// Clear tabular part Services
	Services.Clear();
	
	// Get all folio current accounts receivable services with balances per end of time
	vCharges = cmGetCurrentAccountsReceivableChargesWithBalances(?(ValueIsFilled(CloseOfPeriod), New Boundary(CloseOfPeriod.Date + 1, BoundaryType.Excluding), '39991231235959'), AccountingCustomer, AccountingContract, ParentDoc, GuestGroup, AccountingCurrency, Hotel);
	
	// Fill services tabular part
	pmFillServices(vCharges, vLanguage);
	
	// Fill list of payments
	pmFillListOfPayments();
	
	// Fill totals
	Sum = Services.Total("Sum");
	VATSum = Services.Total("VATSum");
	CommissionSum = Services.Total("CommissionSum");
	SumDue = Sum - PaymentDocuments.Total("Sum");
	If ValueIsFilled(AccountingCustomer) And Not AccountingCustomer.DoNotPostCommission Then
		SumDue = SumDue - CommissionSum;
	EndIf;
	
	// Fill check date
	pmFillCheckDate();
	
	// Set is checked in payments generate invoices mode
	If ValueIsFilled(Hotel) And Hotel.PaymentsGenerateInvoices Then
		IsChecked = True;
	EndIf;
EndProcedure // pmFillByResourceReservation

// -----------------------------------------------------------------------------
Procedure pmFillByGuestGroup(pGuestGroup) Export
	If Not ValueIsFilled(pGuestGroup) Then
		Return;
	EndIf;
	
	// Accounting customer, contract, hotel, company, currency should be filled before calling Fill() method
	ParentDoc = Undefined;
	GuestGroup = pGuestGroup;
	
	// Get customer language
	vLanguage = Undefined;
	If ValueIsFilled(AccountingCustomer) Then
		vLanguage = AccountingCustomer.Language;
	EndIf;
	
	// Reset totals
	Sum = 0;
	VATSum = 0;
	CommissionSum = 0;
	
	// Clear tabular part Services
	Services.Clear();
	
	// Get all folio current accounts receivable services with balances per end of time
	vCharges = cmGetCurrentAccountsReceivableChargesWithBalances(?(ValueIsFilled(CloseOfPeriod), New Boundary(CloseOfPeriod.Date + 1, BoundaryType.Excluding), '39991231235959'), AccountingCustomer, AccountingContract, , GuestGroup, AccountingCurrency, Hotel);
	
	// Fill services tabular part
	pmFillServices(vCharges, vLanguage);
	
	// Fill list of payments
	pmFillListOfPayments();
	
	// Fill totals
	Sum = Services.Total("Sum");
	VATSum = Services.Total("VATSum");
	CommissionSum = Services.Total("CommissionSum");
	SumDue = Sum - PaymentDocuments.Total("Sum");
	If ValueIsFilled(AccountingCustomer) And Not AccountingCustomer.DoNotPostCommission Then
		SumDue = SumDue - CommissionSum;
	EndIf;
	
	// Fill check date
	pmFillCheckDate();
	
	// Set is checked in payments generate invoices mode
	If ValueIsFilled(Hotel) And Hotel.PaymentsGenerateInvoices Then
		IsChecked = True;
	EndIf;
EndProcedure // pmFillByGuestGroup

// -----------------------------------------------------------------------------
Procedure pmFillByInvoice(pDoc) Export
	If Not ValueIsFilled(pDoc) Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(pDoc.ParentDoc) Then
		FillPropertyValues(ThisObject, pDoc, , "Number, Date, Author, DeletionMark, Posted, ParentDoc");
		If ValueIsFilled(pDoc.GuestGroup) Then
			pmFillByGuestGroup(pDoc.GuestGroup);
		ElsIf ValueIsFilled(pDoc.AccountingContract) Then
			pmFillByContract(pDoc.AccountingContract);
		ElsIf ValueIsFilled(pDoc.AccountingCustomer) Then
			pmFillByCustomer(pDoc.AccountingCustomer);
		EndIf;
	Else
		If TypeOf(pDoc.ParentDoc) = Type("DocumentRef.Folio") Then
			pmFillByFolio(pDoc.ParentDoc);
		ElsIf TypeOf(pDoc.ParentDoc) = Type("DocumentRef.Reservation") Then 
			pmFillByDocument(pDoc.ParentDoc);
		ElsIf TypeOf(pDoc.ParentDoc) = Type("DocumentRef.Accommodation") Then 
			pmFillByDocument(pDoc.ParentDoc);
		ElsIf TypeOf(pDoc.ParentDoc) = Type("DocumentRef.ResourceReservation") Then 
			pmFillByResourceReservation(pDoc.ParentDoc);
		EndIf;
	EndIf;
	ParentDoc = pDoc;
	
	// Set is checked in payments generate invoices mode
	If ValueIsFilled(Hotel) And Hotel.PaymentsGenerateInvoices Then
		IsChecked = True;
	EndIf;
EndProcedure // pmFillByInvoice

// -----------------------------------------------------------------------------
Procedure pmFillByCustomer(pCustomer) Export
	If Not ValueIsFilled(pCustomer) Then
		Return;
	EndIf;
	
	// Accounting customer
	AccountingCustomer = pCustomer;
	If ValueIsFilled(AccountingCustomer.Contract) Then
		AccountingContract = AccountingCustomer.Contract;
	EndIf;
	If ValueIsFilled(AccountingCustomer) Then
		If Not IsBlankString(AccountingCustomer.Consignee) Then
			Consignee = TrimR(AccountingCustomer.Consignee);
		EndIf;
	EndIf;
	
	// Fill currency
	If Not ValueIsFilled(AccountingCurrency) Or Not AdditionalProperties.Property("DoNotUpdateCurrency") Then
		If ValueIsFilled(AccountingContract) Then
			AccountingCurrency = AccountingContract.AccountingCurrency;
		Else
			If ValueIsFilled(AccountingCustomer) Then
				AccountingCurrency = AccountingCustomer.AccountingCurrency;
			EndIf;
		EndIf;
	EndIf;
	
	// Get customer language
	vLanguage = Undefined;
	If ValueIsFilled(AccountingCustomer) Then
		vLanguage = AccountingCustomer.Language;
	EndIf;
	
	// Reset totals
	Sum = 0;
	VATSum = 0;
	CommissionSum = 0;
	
	// Clear tabular part Services
	Services.Clear();
	
	// Get all customer current accounts receivable services with balances per end of time
	vCharges = cmGetCurrentAccountsReceivableChargesWithBalances(?(ValueIsFilled(CloseOfPeriod), New Boundary(CloseOfPeriod.Date + 1, BoundaryType.Excluding), New Boundary(Date + 1, BoundaryType.Excluding)), AccountingCustomer, , , GuestGroup, AccountingCurrency, Hotel);
	
	// Fill services tabular part
	pmFillServices(vCharges, vLanguage);
	
	// Fill totals
	Sum = Services.Total("Sum");
	VATSum = Services.Total("VATSum");
	CommissionSum = Services.Total("CommissionSum");
	SumDue = Sum - PaymentDocuments.Total("Sum");
	If ValueIsFilled(AccountingCustomer) And Not AccountingCustomer.DoNotPostCommission Then
		SumDue = SumDue - CommissionSum;
	EndIf;
	
	// Fill check date
	pmFillCheckDate();
	
	// Set is checked in payments generate invoices mode
	If ValueIsFilled(Hotel) And Hotel.PaymentsGenerateInvoices Then
		IsChecked = True;
	EndIf;
EndProcedure // pmFillByCustomer

// -----------------------------------------------------------------------------
Procedure pmFillByContract(pContract) Export
	If Not ValueIsFilled(pContract) Then
		Return;
	EndIf;
	
	// Accounting customer and contract
	AccountingContract = pContract;
	AccountingCustomer = pContract.Owner;
	If ValueIsFilled(AccountingCustomer) Then
		If Not IsBlankString(AccountingCustomer.Consignee) Then
			Consignee = TrimR(AccountingCustomer.Consignee);
		EndIf;
	EndIf;
	
	// Fill currency
	If Not ValueIsFilled(AccountingCurrency) Or Not AdditionalProperties.Property("DoNotUpdateCurrency") Then
		If ValueIsFilled(AccountingContract) Then
			AccountingCurrency = AccountingContract.AccountingCurrency;
		Else
			If ValueIsFilled(AccountingCustomer) Then
				AccountingCurrency = AccountingCustomer.AccountingCurrency;
			EndIf;
		EndIf;
	EndIf;
	
	// Get customer language
	vLanguage = Undefined;
	If ValueIsFilled(AccountingCustomer) Then
		vLanguage = AccountingCustomer.Language;
	EndIf;
	
	// Reset totals
	Sum = 0;
	VATSum = 0;
	CommissionSum = 0;
	
	// Clear tabular part Services
	Services.Clear();
	
	// Get all contract current accounts receivable services with balances per end of time
	vCharges = cmGetCurrentAccountsReceivableChargesWithBalances(?(ValueIsFilled(CloseOfPeriod), New Boundary(CloseOfPeriod.Date + 1, BoundaryType.Excluding), New Boundary(Date + 1, BoundaryType.Excluding)), AccountingCustomer, AccountingContract, , GuestGroup, AccountingCurrency, Hotel);
	
	// Fill services tabular part
	pmFillServices(vCharges, vLanguage);
	
	// Fill totals
	Sum = Services.Total("Sum");
	VATSum = Services.Total("VATSum");
	CommissionSum = Services.Total("CommissionSum");
	SumDue = Sum - PaymentDocuments.Total("Sum");
	If ValueIsFilled(AccountingCustomer) And Not AccountingCustomer.DoNotPostCommission Then
		SumDue = SumDue - CommissionSum;
	EndIf;
	
	// Fill check date
	pmFillCheckDate();
	
	// Set is checked in payments generate invoices mode
	If ValueIsFilled(Hotel) And Hotel.PaymentsGenerateInvoices Then
		IsChecked = True;
	EndIf;
EndProcedure // pmFillByContract

// -----------------------------------------------------------------------------
Procedure pmCalculateTotals() Export
	vSum = Services.Total("Sum");
	If vSum <> Sum Then
		Sum = vSum;
	EndIf;
	vVATSum = Services.Total("VATSum");
	If vVATSum <> VATSum Then
		VATSum = vVATSum;
	EndIf;
	vCommissionSum = Services.Total("CommissionSum");
	vPerInvoiceCommissionSum = 0;
	vPerInvoiceVATCommissionSum = 0;
	If PerInvoiceCommission <> 0 Then
		vPerInvoiceCommissionSum = Round(vSum * PerInvoiceCommission / 100, 2);
		vPerInvoiceVATCommissionSum = Round(vVATSum * PerInvoiceCommission / 100, 2);
	EndIf;
	vCommissionSum = vCommissionSum + vPerInvoiceCommissionSum;
	If vCommissionSum <> CommissionSum Then
		CommissionSum = vCommissionSum;
	EndIf;
	If vPerInvoiceCommissionSum <> PerInvoiceCommissionSum Then
		PerInvoiceCommissionSum = vPerInvoiceCommissionSum;
	EndIf;
	If vPerInvoiceVATCommissionSum <> PerInvoiceVATCommissionSum Then
		PerInvoiceVATCommissionSum = vPerInvoiceVATCommissionSum;
	EndIf;
	vSumDue = vSum - PaymentDocuments.Total("Sum");
	If ValueIsFilled(AccountingCustomer) And Not AccountingCustomer.DoNotPostCommission Then
		vSumDue = vSumDue - vCommissionSum;
	EndIf;
	If vSumDue <> SumDue Then
		SumDue = vSumDue;
	EndIf;
EndProcedure // pmCalculateTotals

// -----------------------------------------------------------------------------
// Fill invoice check date
// -----------------------------------------------------------------------------
Procedure pmFillCheckDate() Export
	vCheckDate = '00010101';
	vUpdateCheckDate = False;
	If Not ValueIsFilled(CheckDate) And ValueIsFilled(GuestGroup) Then
		If ValueIsFilled(AccountingContract) And AccountingContract.DaysAfterReservation <> 0 Then
			vUpdateCheckDate = True;
			If ValueIsFilled(Date) Then
				vCheckDate = cmAddWorkingDays(BegOfDay(Date), (AccountingContract.DaysAfterReservation + 1));
			EndIf;
		ElsIf ValueIsFilled(AccountingCustomer) And AccountingCustomer.DaysAfterReservation <> 0 Then
			vUpdateCheckDate = True;
			If ValueIsFilled(Date) Then
				vCheckDate = cmAddWorkingDays(BegOfDay(Date), (AccountingCustomer.DaysAfterReservation + 1));
			EndIf;
		ElsIf ValueIsFilled(Hotel) And Hotel.DaysAfterReservation <> 0 Then
			vUpdateCheckDate = True;
			If Hotel.DaysAfterReservation <> 0 And ValueIsFilled(Date) Then
				vCheckDate = cmAddWorkingDays(BegOfDay(Date), (Hotel.DaysAfterReservation + 1));
			EndIf;
		EndIf;
	EndIf;
	If vUpdateCheckDate And ValueIsFilled(vCheckDate) And CheckDate <> vCheckDate Then
		CheckDate = vCheckDate;
	EndIf;
EndProcedure // pmFillCheckDate

// -----------------------------------------------------------------------------
Function pmGetServicesPostedToAccounts() Export
	vServices = New ValueTable();
	If Posted Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	Accounts.Client AS Client,
		|	Accounts.Room AS Room,
		|	Accounts.Charge.AccommodationType AS AccommodationType,
		|	Accounts.Charge.AccommodationTemplate AS AccommodationTemplate,
		|	ISNULL(Accounts.ParentDoc.NumberOfPersons, 0) AS NumberOfPersons,
		|	Accounts.Resource AS Resource,
		|	BEGINOFPERIOD(Accounts.Period, DAY) AS AccountingDate,
		|	Accounts.Service AS Service,
		|	Accounts.Price AS Price,
		|	Accounts.Service.Unit AS Unit,
		|	Accounts.Quantity AS Quantity,
		|	Accounts.Sum AS Sum,
		|	Accounts.VATRate AS VATRate,
		|	Accounts.Charge.VATSum AS VATSum,
		|	Accounts.Remarks AS Remarks,
		|	Accounts.IsInPrice AS IsInPrice,
		|	Accounts.IsRoomRevenue AS IsRoomRevenue,
		|	Accounts.IsResourceRevenue AS IsResourceRevenue,
		|	Accounts.Folio.Customer AS Customer,
		|	Accounts.Folio.Contract AS Contract,
		|	Accounts.Folio.GuestGroup AS GuestGroup,
		|	Accounts.FolioCurrency AS FolioCurrency,
		|	Accounts.Folio AS Folio,
		|	Accounts.ParentDoc AS ParentDoc,
		|	Accounts.Charge AS Charge,
		|	Accounts.CalendarDayType AS CalendarDayType,
		|	Accounts.Folio.Agent AS Agent,
		|	Accounts.Charge.AgentCommission AS AgentCommission,
		|	Accounts.Charge.AgentCommissionType AS AgentCommissionType,
		|	Accounts.Charge.CommissionSum AS CommissionSum,
		|	Accounts.Charge.VATCommissionSum AS VATCommissionSum,
		|	Accounts.Charge.HotelProduct AS HotelProduct,
		|	Accounts.PaymentSection AS PaymentSection
		|FROM
		|	AccumulationRegister.Accounts AS Accounts
		|WHERE
		|	Accounts.Recorder = &qRecorder
		|
		|ORDER BY
		|	Accounts.LineNumber,
		|	Accounts.PointInTime";
		vQry.SetParameter("qRecorder", Ref);
		vServices = vQry.Execute().Unload();
		If vServices.Count() > 0 And Services.Count() > 0 And vServices.Total("Sum") <> Services.Total("Sum") Then
			For Each vSrvRow In vServices Do
				vDocRowToUse = Services.Get(0);
				For Each vDocRow In Services Do
					If ValueIsFilled(vSrvRow.PaymentSection) And ValueIsFilled(vDocRow.Service) And vSrvRow.PaymentSection = vDocRow.Service.PaymentSection Then
						vDocRowToUse = vDocRow;
						Break;
					ElsIf vDocRow.IsRoomRevenue Or vDocRow.IsResourceRevenue Then
						vDocRowToUse = vDocRow;
						Break;
					EndIf;
				EndDo;
				vSrvRow.VATSum = 0;
				If vSrvRow.Quantity = 0 Then
					vSrvRow.Quantity = 1;
				EndIf;
				If vSrvRow.Price = 0 Then
					vSrvRow.Price = vSrvRow.Sum;
				EndIf;
				FillPropertyValues(vSrvRow, vDocRowToUse, , "Quantity, Sum, Price, VATSum, CommissionSum, VATCommissionSum, Charge");
				cmPriceOnChange(vSrvRow.Price, vSrvRow.Quantity, vSrvRow.Sum, vSrvRow.VATRate, vSrvRow.VATSum, vSrvRow.AccountingDate);
				If vSrvRow.AgentCommission <> 0 Then
					vSrvRow.CommissionSum = Round(vSrvRow.Sum * vSrvRow.AgentCommission / 100, 2);
					vSrvRow.VATCommissionSum = cmCalculateVATSum(vSrvRow.VATRate, vSrvRow.CommissionSum, vSrvRow.AccountingDate);
				Else
					vSrvRow.CommissionSum = 0;
					vSrvRow.VATCommissionSum = 0;
				EndIf;
				If ValueIsFilled(GuestGroup) Then
					If ValueIsFilled(GuestGroup.Client) Then
						vSrvRow.Client = GuestGroup.Client;
					EndIf;
					If ValueIsFilled(GuestGroup.ClientDoc) Then
						vClientDoc = GuestGroup.ClientDoc;
						If TypeOf(vClientDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vClientDoc) = Type("DocumentRef.Reservation") Then
							vSrvRow.ParentDoc = vClientDoc;
							vSrvRow.Room = vClientDoc.Room;
							vSrvRow.AccommodationTemplate = vClientDoc.AccommodationTemplate;
							vSrvRow.AccommodationType = vClientDoc.AccommodationType;
							vSrvRow.NumberOfPersons = vClientDoc.NumberOfPersons;
						EndIf;
					EndIf;
					vSrvRow.Remarks = TrimAll(NStr("en='Payment for the group N '; ru='Оплата по группе № '; de='Die Zahlung für die Gruppe Nr. '") + Format(GuestGroup.Code, "ND=12; NFD=0; NZ=; NG=") + ?(IsBlankString(vSrvRow.Remarks), "", ", " + TrimAll(vSrvRow.Remarks)));
				EndIf;
			EndDo;
		Else
			vServices.Clear();
		EndIf;
	EndIf;
	Return vServices;
EndFunction // pmGetServicesPostedToAccounts

// -----------------------------------------------------------------------------
Function pmGetInvoiceBalance(Val pDate = Undefined) Export
	vBalance = 0;
	If Not ValueIsFilled(pDate) Then
		pDate = '39991231235959';
	EndIf;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	InvoiceAccountsBalance.Company,
	|	InvoiceAccountsBalance.Invoice,
	|	InvoiceAccountsBalance.Hotel,
	|	InvoiceAccountsBalance.SumBalance AS Balance
	|FROM
	|	AccumulationRegister.InvoiceAccounts.Balance(
	|		&qPeriod,
	|		Invoice = &qInvoice) AS InvoiceAccountsBalance";
	vQry.SetParameter("qPeriod", pDate);
	vQry.SetParameter("qInvoice", Ref);
	vRes = vQry.Execute().Unload();
	For Each vRow In vRes Do
		vBalance = vBalance + vRow.Balance;
	EndDo;
	Return vBalance;
EndFunction // pmGetInvoiceBalance

// -----------------------------------------------------------------------------
Procedure pmFillByPayment(pPayment) Export
	If ValueIsFilled(pPayment) And ValueIsFilled(pPayment.Folio) Then
		pmFillByFolio(pPayment.Folio);
		// Check that payment is in the payments table
		If ValueIsFilled(pPayment.PaymentMethod) And pPayment.PaymentMethod <> Catalogs.PaymentMethods.Settlement Then
			vPDRow = PaymentDocuments.Find(pPayment, "PaymentDoc");
			If vPDRow = Undefined Then
				vPDRow = PaymentDocuments.Add();
				vPDRow.PaymentDoc = pPayment;
				vPDRow.PaymentDocDate = pPayment.Date;
				vPDRow.PaymentDocNumber = pPayment.Number;
				vPDRow.Sum = cmConvertCurrencies(pPayment.Sum, pPayment.PaymentCurrency, , AccountingCurrency, , Date, Hotel);
				// Recalculate sum due
				SumDue = Sum - PaymentDocuments.Total("Sum");
				If ValueIsFilled(AccountingCustomer) And Not AccountingCustomer.DoNotPostCommission Then
					SumDue = SumDue - CommissionSum;
				EndIf;
			EndIf;
		EndIf;
		// Set is checked in payments generate invoices mode
		If ValueIsFilled(Hotel) And Hotel.PaymentsGenerateInvoices Then
			IsChecked = True;
		EndIf;
	EndIf;
EndProcedure // pmFillByPayment

// -----------------------------------------------------------------------------
Procedure pmFillByReturn(pReturn) Export
	If ValueIsFilled(pReturn) And ValueIsFilled(pReturn.Folio) Then
		pmFillByFolio(pReturn.Folio);
		// Check that payment is in the payments table
		If ValueIsFilled(pReturn.PaymentMethod) And pReturn.PaymentMethod <> Catalogs.PaymentMethods.Settlement Then
			vPDRow = PaymentDocuments.Find(pReturn, "PaymentDoc");
			If vPDRow = Undefined Then
				vPDRow = PaymentDocuments.Add();
				vPDRow.PaymentDoc = pReturn;
				vPDRow.PaymentDocDate = pReturn.Date;
				vPDRow.PaymentDocNumber = pReturn.Number;
				vPDRow.Sum = cmConvertCurrencies(pReturn.Sum, pReturn.PaymentCurrency, , AccountingCurrency, , Date, Hotel);
				// Recalculate sum due
				SumDue = Sum - PaymentDocuments.Total("Sum");
				If ValueIsFilled(AccountingCustomer) And Not AccountingCustomer.DoNotPostCommission Then
					SumDue = SumDue - CommissionSum;
				EndIf;
			EndIf;
		EndIf;
		// Set is checked in payments generate invoices mode
		If ValueIsFilled(Hotel) And Hotel.PaymentsGenerateInvoices Then
			IsChecked = True;
		EndIf;
	EndIf;
EndProcedure // pmFillByReturn

// -----------------------------------------------------------------------------
Procedure pmFillByDepositTransfer(pTransfer) Export
	If ValueIsFilled(pTransfer) And ValueIsFilled(pTransfer.FolioTo) Then
		pmFillByFolio(pTransfer.FolioTo);
		// Check that payment is in the payments table
		vPDRow = PaymentDocuments.Find(pTransfer, "PaymentDoc");
		If vPDRow = Undefined Then
			vPDRow = PaymentDocuments.Add();
			vPDRow.PaymentDoc = pTransfer;
			vPDRow.PaymentDocDate = pTransfer.Date;
			vPDRow.PaymentDocNumber = pTransfer.Number;
			vPDRow.Sum = cmConvertCurrencies(pTransfer.SumInFolioToCurrency, pTransfer.FolioToCurrency, , AccountingCurrency, , Date, Hotel);
			// Recalculate sum due
			SumDue = Sum - PaymentDocuments.Total("Sum");
			If ValueIsFilled(AccountingCustomer) And Not AccountingCustomer.DoNotPostCommission Then
				SumDue = SumDue - CommissionSum;
			EndIf;
		EndIf;
		// Set is checked in payments generate invoices mode
		If ValueIsFilled(Hotel) And Hotel.PaymentsGenerateInvoices Then
			IsChecked = True;
		EndIf;
	EndIf;
EndProcedure // pmFillByDepositTransfer

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure WriteGuestLedgerFOPostings(pPostingAmount, pFolio, pFolioFinancialAccount, pFolioParentDoc)
	// Do nothing if paid amount is zero
	If pPostingAmount = 0 Then
		Return;
	EndIf;
	
	// Get service account
	vAccountStruct = cmGetAccountCodeForPOSAndPaymentMethod(Hotel, Company, Catalogs.CashRegisters.EmptyRef(), ?(ValueIsFilled(PaymentMethod), PaymentMethod, Catalogs.PaymentMethods.Settlement), PaymentSection);
	vPostingAccount = vAccountStruct.Account;
	If Not ValueIsFilled(vPostingAccount) Then
		Return;
	EndIf;
	vCorrespondingAccount = ChartsOfAccounts.ChartOfAccountsFO.GuestLedger;
	If ValueIsFilled(pFolio) And ValueIsFilled(pFolioFinancialAccount) Then
		vCorrespondingAccount = pFolioFinancialAccount;
	EndIf;
	
	// Postings currency
	vAccountCurrency = AccountingCurrency;
	
	vPostingAmount = pPostingAmount;
	
	vReverseSign = False;
	If vPostingAmount < 0 Then
		vReverseSign = True;
		
		vPostingAmount = -vPostingAmount;
	EndIf;
	
	If vPostingAmount <> 0 Then
		// Create movement for this payment
		PostingMovement = Undefined;
		If vPostingAccount.Type = AccountType.Passive Then
			If vReverseSign Then
				PostingMovement = RegisterRecords.PostingsFO.AddDebit();
			Else
				PostingMovement = RegisterRecords.PostingsFO.AddCredit();
			EndIf;
		ElsIf vPostingAccount.Type = AccountType.Active Then
			If vReverseSign Then
				PostingMovement = RegisterRecords.PostingsFO.AddCredit();
			Else
				PostingMovement = RegisterRecords.PostingsFO.AddDebit();
			EndIf;
		Else
			Raise NStr("en='Sign is not defined for account '; ru='Знак не указан в настройках счета '; de='Das buchungszeichen ist in den Konto nicht angegeben '") + vPostingAccount;
		EndIf;
		
		PostingMovement.Active = True;
		
		PostingMovement.Account = vPostingAccount;
		PostingMovement.CorrAccount = vCorrespondingAccount;
		
		PostingMovement.Amount = vPostingAmount;
		PostingMovement.GrosAmount = 0;
		
		PostingMovement.Description = TrimAll(PaymentMethod);
		
		PostingMovement.Period = BegOfDay(Date);
		PostingMovement.FODate = BegOfDay(Date);
		PostingMovement.ServiceDate = '00010101';
		PostingMovement.Days = 0;
					
		PostingMovement.ParentDoc = pFolioParentDoc;
		
		PostingMovement.Room = Undefined;
		PostingMovement.Resource = Undefined;
		
		PostingMovement.Service = Undefined;
		PostingMovement.PaymentMethod = PaymentMethod;
		PostingMovement.AccountingCustomer = AccountingCustomer;
			
		PostingMovement.AccountGroup = vPostingAccount.AccountGroup;
		PostingMovement.AccountType = vPostingAccount.AccountType;
		PostingMovement.Department = vPostingAccount.Department;
		PostingMovement.DiscountType = vPostingAccount.DiscountType;
		PostingMovement.ServiceType = vPostingAccount.ServiceType;
		
		PostingMovement.Hotel = Hotel;
		PostingMovement.Company = Company;
		PostingMovement.Currency = vAccountCurrency;
		
		PostingMovement.Discount = 0;
		PostingMovement.DiscountAmount = 0;
		
		PostingMovement.VATAmount = 0;
		PostingMovement.VATRate = Undefined;
		
		PostingMovement.POSTicket = "";
		PostingMovement.Invoice = Ref;
		
		PostingMovement.Recorder = Ref;
		PostingMovement.Author = ?(ValueIsFilled(ChangeAuthor), ChangeAuthor, Author);
		
		// Create guest ledger debit movement
		If vReverseSign Then
			PostingMovement = RegisterRecords.PostingsFO.AddDebit();
		Else
			PostingMovement = RegisterRecords.PostingsFO.AddCredit();
		EndIf;
					
		PostingMovement.Active = True;
		
		PostingMovement.Account = vCorrespondingAccount;
		If vCorrespondingAccount = ChartsOfAccounts.ChartOfAccountsFO.GuestLedger Then
			PostingMovement.ExtDimensions.Folio = pFolio;
		EndIf;
		PostingMovement.CorrAccount = vPostingAccount;
		
		PostingMovement.Amount = vPostingAmount;
		PostingMovement.GrosAmount = 0;
		
		PostingMovement.Description = TrimAll(PaymentMethod);
		
		PostingMovement.Period = BegOfDay(Date);
		PostingMovement.FODate = BegOfDay(Date);
		PostingMovement.ServiceDate = '00010101';
		PostingMovement.Days = 0;
					
		PostingMovement.ParentDoc = pFolioParentDoc;
		
		PostingMovement.Room = Undefined;
		PostingMovement.Resource = Undefined;
		
		PostingMovement.Service = Undefined;
		PostingMovement.PaymentMethod = PaymentMethod;
		PostingMovement.AccountingCustomer = AccountingCustomer;
			
		PostingMovement.AccountGroup = vCorrespondingAccount.AccountGroup;
		PostingMovement.AccountType = vCorrespondingAccount.AccountType;
		PostingMovement.Department = vCorrespondingAccount.Department;
		PostingMovement.DiscountType = vCorrespondingAccount.DiscountType;
		PostingMovement.ServiceType = vCorrespondingAccount.ServiceType;
		
		PostingMovement.Hotel = Hotel;
		PostingMovement.Company = Company;
		PostingMovement.Currency = vAccountCurrency;
		
		PostingMovement.Discount = 0;
		PostingMovement.DiscountAmount = 0;
		
		PostingMovement.VATAmount = 0;
		PostingMovement.VATRate = Undefined;
		
		PostingMovement.POSTicket = "";
		PostingMovement.Invoice = Ref;
		
		PostingMovement.Recorder = Ref;
		PostingMovement.Author = ?(ValueIsFilled(ChangeAuthor), ChangeAuthor, Author);
	EndIf;
EndProcedure // WriteGuestLedgerFOPostings

// -----------------------------------------------------------------------------
Procedure WriteCityLedgerFOPostings()
	// Do nothing if paid amount is zero
	vPostingAmount = Sum;
	If vPostingAmount = 0 Then
		Return;
	EndIf;
	
	// Get service account
	vAccountStruct = cmGetAccountCodeForPOSAndPaymentMethod(Hotel, Company, Catalogs.CashRegisters.EmptyRef(), ?(ValueIsFilled(PaymentMethod), PaymentMethod, Catalogs.PaymentMethods.Settlement), PaymentSection);
	vPostingAccount = vAccountStruct.Account;
	If Not ValueIsFilled(vPostingAccount) Then
		Return;
	EndIf;
	vCorrespondingAccountStruct = cmGetAccountCodeForCustomer(Hotel, Company, AccountingCustomer, AccountingContract);
	vCorrespondingAccount = vCorrespondingAccountStruct.Account;
	If Not ValueIsFilled(vCorrespondingAccount) Then
		Return;
	EndIf;
	
	// Postings currency
	vAccountCurrency = AccountingCurrency;
	
	vReverseSign = False;
	If vPostingAmount < 0 Then
		vReverseSign = True;
		
		vPostingAmount = -vPostingAmount;
	EndIf;
	
	// Create movement for this invoice
	vDoDebit = False;
	PostingMovement = Undefined;
	If vPostingAccount.Type = AccountType.Passive Then
		If vReverseSign Then
			PostingMovement = RegisterRecords.PostingsFO.AddCredit();
		Else
			PostingMovement = RegisterRecords.PostingsFO.AddDebit();
			vDoDebit = True;
		EndIf;
	ElsIf vPostingAccount.Type = AccountType.Active Then
		If vReverseSign Then
			PostingMovement = RegisterRecords.PostingsFO.AddDebit();
			vDoDebit = True;
		Else
			PostingMovement = RegisterRecords.PostingsFO.AddCredit();
		EndIf;
	Else
		Raise NStr("en='Sign is not defined for account '; ru='Знак не указан в настройках счета '; de='Das buchungszeichen ist in den Konto nicht angegeben '") + vPostingAccount;
	EndIf;
	
	PostingMovement.Active = True;
	
	PostingMovement.Account = vPostingAccount; // City ledger
	PostingMovement.CorrAccount = vCorrespondingAccount;
	
	PostingMovement.Amount = vPostingAmount;
	PostingMovement.GrosAmount = 0;
	
	PostingMovement.Description = TrimAll(Ref);
	
	PostingMovement.Period = BegOfDay(Date);
	PostingMovement.FODate = BegOfDay(Date);
	PostingMovement.ServiceDate = '00010101';
	PostingMovement.Days = 0;
				
	PostingMovement.ParentDoc = Undefined;
	
	PostingMovement.Room = Undefined;
	PostingMovement.Resource = Undefined;
	
	PostingMovement.Service = Undefined;
	PostingMovement.PaymentMethod = PaymentMethod;
	PostingMovement.AccountingCustomer = AccountingCustomer;
		
	PostingMovement.AccountGroup = vPostingAccount.AccountGroup;
	PostingMovement.AccountType = vPostingAccount.AccountType;
	PostingMovement.Department = vPostingAccount.Department;
	PostingMovement.DiscountType = vPostingAccount.DiscountType;
	PostingMovement.ServiceType = vPostingAccount.ServiceType;
	
	PostingMovement.Hotel = Hotel;
	PostingMovement.Company = Company;
	PostingMovement.Currency = vAccountCurrency;
	
	PostingMovement.Discount = 0;
	PostingMovement.DiscountAmount = 0;
	
	PostingMovement.VATAmount = 0;
	PostingMovement.VATRate = Undefined;
	
	PostingMovement.POSTicket = "";
	PostingMovement.Invoice = Ref;
	
	PostingMovement.Recorder = Ref;
	PostingMovement.Author = ?(ValueIsFilled(ChangeAuthor), ChangeAuthor, Author);
	
	// Create customer account credit movement
	If vDoDebit Then
		PostingMovement = RegisterRecords.PostingsFO.AddCredit();
	Else
		PostingMovement = RegisterRecords.PostingsFO.AddDebit();
	EndIf;
				
	PostingMovement.Active = True;
	
	PostingMovement.Account = vCorrespondingAccount; // Customer account
	PostingMovement.CorrAccount = vPostingAccount;
	
	PostingMovement.Amount = vPostingAmount;
	PostingMovement.GrosAmount = 0;
	
	PostingMovement.Description = TrimAll(Ref);
	
	PostingMovement.Period = BegOfDay(Date);
	PostingMovement.FODate = BegOfDay(Date);
	PostingMovement.ServiceDate = '00010101';
	PostingMovement.Days = 0;
				
	PostingMovement.ParentDoc = Undefined;
	
	PostingMovement.Room = Undefined;
	PostingMovement.Resource = Undefined;
	
	PostingMovement.Service = Undefined;
	PostingMovement.PaymentMethod = PaymentMethod;
	PostingMovement.AccountingCustomer = AccountingCustomer;
		
	PostingMovement.AccountGroup = vCorrespondingAccount.AccountGroup;
	PostingMovement.AccountType = vCorrespondingAccount.AccountType;
	PostingMovement.Department = vCorrespondingAccount.Department;
	PostingMovement.DiscountType = vCorrespondingAccount.DiscountType;
	PostingMovement.ServiceType = vCorrespondingAccount.ServiceType;
	
	PostingMovement.Hotel = Hotel;
	PostingMovement.Company = Company;
	PostingMovement.Currency = vAccountCurrency;
	
	PostingMovement.Discount = 0;
	PostingMovement.DiscountAmount = 0;
	
	PostingMovement.VATAmount = 0;
	PostingMovement.VATRate = Undefined;
	
	PostingMovement.POSTicket = "";
	PostingMovement.Invoice = Ref;
	
	PostingMovement.Recorder = Ref;
	PostingMovement.Author = ?(ValueIsFilled(ChangeAuthor), ChangeAuthor, Author);
	
	// Postings to commission expenses account
	If CommissionSum <> 0 And ValueIsFilled(Company) Then
		If ValueIsFilled(AccountingCustomer) And Not AccountingCustomer.DoNotPostCommission Then
			vCommissionAccount = undefined;
			If ValueIsFilled(AccountingContract) And ValueIsFilled(AccountingContract.CommissionAccount) Then
				vCommissionAcount = AccountingContract.CommissionAccount;
			ElsIf ValueIsFilled(AccountingCustomer) And ValueIsFilled(AccountingCustomer.CommissionAccount) Then
				vCommissionAcount = AccountingCustomer.CommissionAccount;
			Else
				vCommissionAcount = Company.CommissionExpensesAccount;
			EndIf;
			If ValueIsFilled(vCommissionAccount) Then
				vAgentCommission = 0;
				vVATCommissionSum = Services.Total("VATCommissionSum");
				For Each vServicesRow In Services Do
					If vAgentCommission = 0 And vServicesRow.AgentCommission <> 0 Then
						vAgentCommission = vServicesRow.AgentCommission;
						Break;
					EndIf;
				EndDo;
				
				vParentDoc = Undefined;
				vCommissionDescription = "";
				If vAgentCommission <> 0 Then
					If ValueIsFilled(GuestGroup) Then
						vParentDoc = GuestGroup.ClientDoc; 
						vCommissionDescription = vCommissionDescription + Documents.Settlement.GetAgentCommissionDescription(vAgentCommission, vParentDoc, SessionParameters.CurrentLanguage);
					Else
						vCommissionDescription = vCommissionDescription + vAgentCommission + "%";
					EndIf;
				EndIf;
				If PerInvoiceCommission <> 0 Then
					vCommissionDescription = vCommissionDescription + ?(IsBlankString(vCommissionDescription), "", ", ") + cmNStr("en='per invoice '; ru='по акту '; de='per Rechnung '", SessionParameters.CurrentLanguage) + PerInvoiceCommission + "%";
				EndIf;
				vCommissionDescription = NStr("en='Commission '; ru='Комиссия '; de='Provision '") + vCommissionDescription;
				
				vPostingAccount = vCorrespondingAccount;
				vCorrespondingAccount = vCommissionAcount;
				
				vGrosAmount = vPostingAmount;
				vPostingAmount = CommissionSum;
				vPostingVATAmount = vVATCommissionSum + PerInvoiceVATCommissionSum;
				If vPostingAmount < 0 Then
					vPostingAmount = -vPostingAmount;
					vPostingVATAmount = -vPostingVATAmount;
					vDoDebit = Not vDoDebit;
				EndIf;
			
				If vDoDebit Then
					PostingMovement = RegisterRecords.PostingsFO.AddDebit();
				Else
					PostingMovement = RegisterRecords.PostingsFO.AddCredit();
				EndIf;
							
				PostingMovement.Active = True;
				
				PostingMovement.Account = vPostingAccount; // Customer account
				PostingMovement.CorrAccount = vCorrespondingAccount;
				
				PostingMovement.Amount = vPostingAmount;
				PostingMovement.GrosAmount = vGrosAmount;
				
				PostingMovement.Description = vCommissionDescription;
				
				PostingMovement.Period = BegOfDay(Date);
				PostingMovement.FODate = BegOfDay(Date);
				PostingMovement.ServiceDate = '00010101';
				PostingMovement.Days = 0;
							
				PostingMovement.ParentDoc = vParentDoc;
				
				PostingMovement.Room = Undefined;
				PostingMovement.Resource = Undefined;
				
				PostingMovement.Service = Undefined;
				PostingMovement.PaymentMethod = PaymentMethod;
				PostingMovement.AccountingCustomer = AccountingCustomer;
					
				PostingMovement.AccountGroup = vPostingAccount.AccountGroup;
				PostingMovement.AccountType = vPostingAccount.AccountType;
				PostingMovement.Department = vPostingAccount.Department;
				PostingMovement.DiscountType = vPostingAccount.DiscountType;
				PostingMovement.ServiceType = vPostingAccount.ServiceType;
				
				PostingMovement.Hotel = Hotel;
				PostingMovement.Company = Company;
				PostingMovement.Currency = vAccountCurrency;
				
				PostingMovement.Discount = 0;
				PostingMovement.DiscountAmount = 0;
				
				PostingMovement.VATAmount = vPostingVATAmount;
				PostingMovement.VATRate = VATRate;
				
				PostingMovement.POSTicket = "";
				PostingMovement.Invoice = Ref;
				
				PostingMovement.Recorder = Ref;
				PostingMovement.Author = ?(ValueIsFilled(ChangeAuthor), ChangeAuthor, Author);
				
				// Add corresponding movement to commission expenses account
				If vDoDebit Then
					PostingMovement = RegisterRecords.PostingsFO.AddCredit();
				Else
					PostingMovement = RegisterRecords.PostingsFO.AddDebit();
				EndIf;
							
				PostingMovement.Active = True;
				
				PostingMovement.Account = vCorrespondingAccount; // Commission expenses account
				PostingMovement.CorrAccount = vPostingAccount;
				
				PostingMovement.Amount = vPostingAmount;
				PostingMovement.GrosAmount = vGrosAmount;
				
				PostingMovement.Description = vCommissionDescription;
				
				PostingMovement.Period = BegOfDay(Date);
				PostingMovement.FODate = BegOfDay(Date);
				PostingMovement.ServiceDate = '00010101';
				PostingMovement.Days = 0;
							
				PostingMovement.ParentDoc = vParentDoc;
				
				PostingMovement.Room = Undefined;
				PostingMovement.Resource = Undefined;
				
				PostingMovement.Service = Undefined;
				PostingMovement.PaymentMethod = PaymentMethod;
				PostingMovement.AccountingCustomer = AccountingCustomer;
					
				PostingMovement.AccountGroup = vCorrespondingAccount.AccountGroup;
				PostingMovement.AccountType = vCorrespondingAccount.AccountType;
				PostingMovement.Department = vCorrespondingAccount.Department;
				PostingMovement.DiscountType = vCorrespondingAccount.DiscountType;
				PostingMovement.ServiceType = vCorrespondingAccount.ServiceType;
				
				PostingMovement.Hotel = Hotel;
				PostingMovement.Company = Company;
				PostingMovement.Currency = vAccountCurrency;
				
				PostingMovement.Discount = 0;
				PostingMovement.DiscountAmount = 0;
				
				PostingMovement.VATAmount = vPostingVATAmount;
				PostingMovement.VATRate = VATRate;
				
				PostingMovement.POSTicket = "";
				PostingMovement.Invoice = Ref;
				
				PostingMovement.Recorder = Ref;
				PostingMovement.Author = ?(ValueIsFilled(ChangeAuthor), ChangeAuthor, Author);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // WriteCityLedgerFOPostings

// -----------------------------------------------------------------------------
Procedure PostToCurrentAccountsReceivable(pServices)
	RegisterRecords.CurrentAccountsReceivable.Clear();
	
	// Write movement for each charge in the services tabular part
	For Each vServicesRow In pServices Do
		Movement = RegisterRecords.CurrentAccountsReceivable.Add();
		
		Movement.RecordType = AccumulationRecordType.Expense;
		Movement.Period = Date;
		
		FillPropertyValues(Movement, vServicesRow);
		
		// Fill individuals customer and customer contract if specified
		If Not ValueIsFilled(Movement.Customer) And ValueIsFilled(Hotel.IndividualsCustomer) And ValueIsFilled(Hotel.IndividualsContract) Then
			Movement.Customer = Hotel.IndividualsCustomer;
			Movement.Contract = Hotel.IndividualsContract;
		EndIf;
		
		Movement.Hotel = Hotel;
		Movement.Company = Company;
	EndDo;

	RegisterRecords.CurrentAccountsReceivable.Write();
	RegisterRecords.CurrentAccountsReceivable.Write = False;
EndProcedure // PostToCurrentAccountsReceivable

// -----------------------------------------------------------------------------
Procedure PostToAccountsReceivable(pServices)
	RegisterRecords.AccountsReceivable.Clear();
	
	// Write movement for each charge in the services tabular part
	For Each vServicesRow In pServices Do
		Movement = RegisterRecords.AccountsReceivable.Add();
		
		Movement.Period = Date;
		
		FillPropertyValues(Movement, ThisObject);
		FillPropertyValues(Movement, vServicesRow);
		Movement.GuestGroup = vServicesRow.ChargeFolioGuestGroup;
		
		Movement.Settlement = Ref;
	EndDo;

	RegisterRecords.AccountsReceivable.Write();
	RegisterRecords.AccountsReceivable.Write = False;
EndProcedure // PostToAccountsReceivable

// -----------------------------------------------------------------------------
Procedure PostToCustomerAccounts(pServices, pAllFoliosList, pBalancedFoliosList)
	RegisterRecords.CustomerAccounts.Clear();
	
	vCurFolio = Undefined;
	vLastPaymentMethod = Undefined;
	
	vPaymentsList = New ValueList();
	vPaymentsList.LoadValues(PaymentDocuments.UnloadColumn("PaymentDoc"));
	
	vPaymentAmounts = New ValueTable();
	vPaymentAmountsNoPriorityAndServices = New ValueTable();
	
	vAllPaymentAmounts = New ValueTable();
	vAllPaymentAmountsNoPriorityAndServices = New ValueTable();
	cmGetPaymentsForInvoiceTransactions(pAllFoliosList, vPaymentsList, Ref, vAllPaymentAmounts, vAllPaymentAmountsNoPriorityAndServices);
	
	vPerInvoiceCommissionSumPerTransactions = 0;
	vPerInvoiceVATCommissionSumPerTransactions = 0;

	For Each vServicesRow In pServices Do
		If vServicesRow.Sum <> 0 Then
			If vCurFolio <> vServicesRow.Folio Then
				vCurFolio = vServicesRow.Folio;
				vPaymentAmountsRows = vAllPaymentAmounts.FindRows(New Structure("Folio", vCurFolio));
				vPaymentAmounts = vAllPaymentAmounts.Copy(vPaymentAmountsRows);
				vPaymentAmountsNoPriorityAndServicesRows = vAllPaymentAmountsNoPriorityAndServices.FindRows(New Structure("Folio", vCurFolio));
				vPaymentAmountsNoPriorityAndServices = vAllPaymentAmountsNoPriorityAndServices.Copy(vPaymentAmountsNoPriorityAndServicesRows);
			EndIf;
		EndIf;
		
		Movement = RegisterRecords.CustomerAccounts.Add();
		
		Movement.RecordType = AccumulationRecordType.Receipt;
		Movement.Period = Date;
		
		FillPropertyValues(Movement, ThisObject);
		FillPropertyValues(Movement, vServicesRow);
		Movement.GuestGroup = vServicesRow.ChargeFolioGuestGroup;
		
		// Attributes
		Movement.PaymentSection = vServicesRow.ServicePaymentSection; 

		// Take per invoice commission into account
		vPerInvoiceCommissionSumPerTransaction = 0;
		vPerInvoiceVATCommissionSumPerTransaction = 0;
		If ValueIsFilled(AccountingCustomer) And Not AccountingCustomer.DoNotPostCommission And
		   PerInvoiceCommission <> 0 And Sum <> 0 Then
			vPerInvoiceCommissionK = Movement.Sum / Sum;

			vPerInvoiceCommissionSumPerTransaction = Round(PerInvoiceCommissionSum * vPerInvoiceCommissionK, 2);
			vPerInvoiceCommissionSumPerTransactions = vPerInvoiceCommissionSumPerTransactions + vPerInvoiceCommissionSumPerTransaction;

			vPerInvoiceVATCommissionSumPerTransaction = Round(PerInvoiceVATCommissionSum * vPerInvoiceCommissionK, 2);
			vPerInvoiceVATCommissionSumPerTransactions = vPerInvoiceVATCommissionSumPerTransactions + vPerInvoiceVATCommissionSumPerTransaction;
			
			If pServices.IndexOf(vServicesRow) = (pServices.Count() - 1) Then
				If vPerInvoiceCommissionSumPerTransactions <> PerInvoiceCommissionSum Then
					vPerInvoiceCommissionSumPerTransaction = vPerInvoiceCommissionSumPerTransaction - (vPerInvoiceCommissionSumPerTransactions - PerInvoiceCommissionSum);
				EndIf;
				If vPerInvoiceVATCommissionSumPerTransactions <> PerInvoiceVATCommissionSum Then
					vPerInvoiceVATCommissionSumPerTransaction = vPerInvoiceVATCommissionSumPerTransaction - (vPerInvoiceVATCommissionSumPerTransactions - PerInvoiceVATCommissionSum);
				EndIf;
			EndIf;
			
			Movement.Sum = Movement.Sum - vPerInvoiceCommissionSumPerTransaction;
			Movement.VATSum = Movement.VATSum - vPerInvoiceVATCommissionSumPerTransaction;
		EndIf;
		
		// Take agent commission into account
		If ValueIsFilled(vServicesRow.Agent) And vServicesRow.Agent = AccountingCustomer And Not vServicesRow.AgentDoNotPostCommission Then 
			Movement.Sum = Movement.Sum - vServicesRow.CommissionSum;
			Movement.VATSum = Movement.VATSum - vServicesRow.VATCommissionSum;
		EndIf;
		
		// Fill payment method
		If Movement.Sum <> 0 Then
			// First run for given service
			For Each vPaymentAmountsRow In vPaymentAmounts Do
				If vPaymentAmountsRow.Service = Movement.Service Then
					FindPaymentMethodForCustomerAccountsMovement(Movement, vPaymentAmountsRow, vLastPaymentMethod, vPaymentAmounts, vPaymentAmountsNoPriorityAndServices);
				EndIf;
				If Movement.PaymentMethod <> PaymentMethod Then
					vLastPaymentMethod = Movement.PaymentMethod;
					Break;
				EndIf;
			EndDo;
			// Second run ignoring service but with priority
			If Movement.PaymentMethod = PaymentMethod Then
				For Each vPaymentAmountsRow In vPaymentAmounts Do
					FindPaymentMethodForCustomerAccountsMovement(Movement, vPaymentAmountsRow, vLastPaymentMethod, vPaymentAmounts, vPaymentAmountsNoPriorityAndServices);
					If Movement.PaymentMethod <> PaymentMethod Then
						vLastPaymentMethod = Movement.PaymentMethod;
						Break;
					EndIf;
				EndDo;
			EndIf;
			// Third run ignoring service and priority
			If Movement.PaymentMethod = PaymentMethod Then
				For Each vPaymentAmountsNoPriorirtyAndServicesRow In vPaymentAmountsNoPriorityAndServices Do
					FindPaymentMethodForCustomerAccountsMovementNoPriorityAndService(Movement, vPaymentAmountsNoPriorirtyAndServicesRow, vLastPaymentMethod, vPaymentAmounts, vPaymentAmountsNoPriorityAndServices);
					If Movement.PaymentMethod <> PaymentMethod Then
						vLastPaymentMethod = Movement.PaymentMethod;
						Break;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		
		// Add movement for agent that differs from the settlement customer
		If ValueIsFilled(vServicesRow.Agent) And vServicesRow.Agent <> AccountingCustomer And 
		   Not vServicesRow.AgentDoNotPostCommission And vServicesRow.CommissionSum <> 0 Then
			Movement = RegisterRecords.CustomerAccounts.Add();
			
			Movement.RecordType = AccumulationRecordType.Receipt;
			Movement.Period = Date;
			
			FillPropertyValues(Movement, ThisObject);
			FillPropertyValues(Movement, vServicesRow);
			
			// Dimensions
			Movement.AccountingCustomer = vServicesRow.Agent;
			Movement.AccountingContract = vServicesRow.AgentAgentCommissionContract;
			Movement.GuestGroup = Catalogs.GuestGroups.EmptyRef();
			
			// Resources
			Movement.Sum = -vServicesRow.CommissionSum - vPerInvoiceCommissionSumPerTransaction;
			Movement.VATSum = -vServicesRow.VATCommissionSum - vPerInvoiceVATCommissionSumPerTransaction;
			
			// Attributes
			Movement.PaymentSection = vServicesRow.ServicePaymentSection;
		EndIf;		
	EndDo;

	RegisterRecords.CustomerAccounts.Write();
	RegisterRecords.CustomerAccounts.Write = False;
EndProcedure // PostToCustomerAccounts

// -----------------------------------------------------------------------------
Procedure FindPaymentMethodForCustomerAccountsMovement(pMovement, pPaymentAmountsRow, pLastPaymentMethod, pPaymentAmounts, pPaymentAmountsNoPriorityAndService)
	If pMovement.Sum > 0 Then
		If pPaymentAmountsRow.Sum >= pMovement.Sum Then
			pMovement.PaymentMethod = pPaymentAmountsRow.PaymentMethod;
			pPaymentAmountsRow.Sum = pPaymentAmountsRow.Sum - pMovement.Sum;
			vPaymentAmountsNoServicesRow = pPaymentAmountsNoPriorityAndService.Find(pPaymentAmountsRow.PaymentMethod, "PaymentMethod");
			If vPaymentAmountsNoServicesRow <> Undefined Then
				vPaymentAmountsNoServicesRow.Sum = vPaymentAmountsNoServicesRow.Sum - pMovement.Sum;
			EndIf;
		EndIf;
	Else
		If ValueIsFilled(pLastPaymentMethod) Then
			pMovement.PaymentMethod = pLastPaymentMethod;
			vLastPMPaymentAmountsRow = pPaymentAmounts.Find(pLastPaymentMethod, "PaymentMethod");
			If vLastPMPaymentAmountsRow <> Undefined Then
				vLastPMPaymentAmountsRow.Sum = vLastPMPaymentAmountsRow.Sum - pMovement.Sum;
			EndIf;
			vPaymentAmountsNoServicesRow = pPaymentAmountsNoPriorityAndService.Find(pLastPaymentMethod, "PaymentMethod");
			If vPaymentAmountsNoServicesRow <> Undefined Then
				vPaymentAmountsNoServicesRow.Sum = vPaymentAmountsNoServicesRow.Sum - pMovement.Sum;
			EndIf;
		Else
			pMovement.PaymentMethod = pPaymentAmountsRow.PaymentMethod;
			pPaymentAmountsRow.Sum = pPaymentAmountsRow.Sum - pMovement.Sum;
			vPaymentAmountsNoServicesRow = pPaymentAmountsNoPriorityAndService.Find(pPaymentAmountsRow.PaymentMethod, "PaymentMethod");
			If vPaymentAmountsNoServicesRow <> Undefined Then
				vPaymentAmountsNoServicesRow.Sum = vPaymentAmountsNoServicesRow.Sum - pMovement.Sum;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // FindPaymentMethodForCustomerAccountsMovement

// -----------------------------------------------------------------------------
Procedure FindPaymentMethodForCustomerAccountsMovementNoPriorityAndService(pMovement, pPaymentAmountsNoPriorityAndServiceRow, pLastPaymentMethod, pPaymentAmounts, pPaymentAmountsNoPriorityAndService)
	vMovementSum = pMovement.Sum;
	If pMovement.Sum > 0 Then
		If pPaymentAmountsNoPriorityAndServiceRow.Sum >= pMovement.Sum Then
			pMovement.PaymentMethod = pPaymentAmountsNoPriorityAndServiceRow.PaymentMethod;
			pPaymentAmountsNoPriorityAndServiceRow.Sum = pPaymentAmountsNoPriorityAndServiceRow.Sum - pMovement.Sum;
			vPaymentAmountsRows = pPaymentAmounts.FindRows(New Structure("PaymentMethod", pPaymentAmountsNoPriorityAndServiceRow.PaymentMethod));
			For Each vPaymentAmountsRow In vPaymentAmountsRows Do
				If vMovementSum > 0 Then
					If vPaymentAmountsRow.Sum > 0 Then
						vCorrectionSum = Min(vPaymentAmountsRow.Sum, vMovementSum);
						vPaymentAmountsRow.Sum = vPaymentAmountsRow.Sum - vCorrectionSum;
						vMovementSum = vMovementSum - vCorrectionSum;
					EndIf;
				Else
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
EndProcedure // FindPaymentMethodForCustomerAccountsMovementNoPriorityAndService

// -----------------------------------------------------------------------------
Procedure PostToInvoiceAccounts()
	RegisterRecords.InvoiceAccounts.Clear();
	
	Movement = RegisterRecords.InvoiceAccounts.Add();
	
	Movement.RecordType = AccumulationRecordType.Receipt;
	Movement.Period = Date;
	Movement.Invoice = Ref;
	
	FillPropertyValues(Movement, ThisObject);
	
	Movement.Sum = SumDue;

	RegisterRecords.InvoiceAccounts.Write();
	RegisterRecords.InvoiceAccounts.Write = False;
EndProcedure // PostToInvoiceAccounts

// -----------------------------------------------------------------------------
Function ServicesHasChanged()
	vOldServices = Ref.Services;
	If Services.Count() <> vOldServices.Count() Then
		Return True;
	ElsIf Services.Total("Sum") <> vOldServices.Total("Sum") Or 
		  Services.Total("VATSum") <> vOldServices.Total("VATSum") Or 
		  Services.Total("CommissionSum") <> vOldServices.Total("CommissionSum") Or 
		  Services.Total("Quantity") <> vOldServices.Total("Quantity") Then
		Return True;
	Else
		vNewServices = Services.Unload();
		vOldServices = vOldServices.Unload();
		vNewServices.GroupBy("Service", "Sum, VATSum, CommissionSum, Quantity");
		vOldServices.GroupBy("Service", "Sum, VATSum, CommissionSum, Quantity");
		For Each vNewServicesRow In vNewServices Do
			vOldServicesRow = vOldServices.Find(vNewServicesRow.Service, "Service");
			If vOldServicesRow = Undefined Then
				Return True;
			ElsIf vOldServicesRow.Sum <> vNewServicesRow.Sum Or 
				  vOldServicesRow.VATSum <> vNewServicesRow.VATSum Or 
				  vOldServicesRow.CommissionSum <> vNewServicesRow.CommissionSum Or 
				  vOldServicesRow.Quantity <> vNewServicesRow.Quantity Then
				Return True;
			EndIf;
		EndDo;
		For Each vOldServicesRow In vOldServices Do
			vNewServicesRow = vNewServices.Find(vOldServicesRow.Service, "Service");
			If vNewServicesRow = Undefined Then
				Return True;
			ElsIf vOldServicesRow.Sum <> vNewServicesRow.Sum Or 
				  vOldServicesRow.VATSum <> vNewServicesRow.VATSum Or 
				  vOldServicesRow.CommissionSum <> vNewServicesRow.CommissionSum Or 
				  vOldServicesRow.Quantity <> vNewServicesRow.Quantity Then
				Return True;
			EndIf;
		EndDo;
	EndIf;
	Return False;
EndFunction // ServicesHasChanged

// -----------------------------------------------------------------------------
Function GetAgentCommissionDescription(pAgentCommission, pDoc, pLanguage)
	vStr = "%";
	If ValueIsFilled(pDoc) And (TypeOf(pDoc) = Type("DocumentRef.Accommodation") Or TypeOf(pDoc) = Type("DocumentRef.Reservation")) Then
		If pDoc.AgentCommissionType = Enums.AgentCommissionTypes.Percent Then
			vStr = TrimAll(pAgentCommission) + cmNStr("en='%';ru='%';de='%'", pLanguage);
		ElsIf pDoc.AgentCommissionType = Enums.AgentCommissionTypes.FirstDayPercent Then
			vStr = TrimAll(pAgentCommission) + cmNStr("en='% for the 1-st day';ru='% за 1-ый день';de='% für den ersten Tag'", pLanguage);
		ElsIf pDoc.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerCheckInPerClient Then
			vStr = cmFormatSum(pAgentCommission, pDoc.Agent.AccountingCurrency) + cmNStr("en=' per guest per check-in';ru=' за гостя за заезд';de=' pro Gast pro Check-in'", pLanguage);
		ElsIf pDoc.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerCheckInPerRoom Then
			vStr = cmFormatSum(pAgentCommission, pDoc.Agent.AccountingCurrency) + cmNStr("en=' per room per check-in';ru=' за номер за заезд';de=' pro Zimmer pro Check-in'", pLanguage);
		ElsIf pDoc.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerDayPerClient Then
			vStr = cmFormatSum(pAgentCommission, pDoc.Agent.AccountingCurrency) + cmNStr("en=' per guest per night';ru=' за гостя за ночь';de=' pro Gast pro Nacht'", pLanguage);
		ElsIf pDoc.AgentCommissionType = Enums.AgentCommissionTypes.AmountPerDayPerRoom Then
			vStr = cmFormatSum(pAgentCommission, pDoc.Agent.AccountingCurrency) + cmNStr("en=' per room per night';ru=' за номер за ночь';de=' pro Zimmer pro Nacht'", pLanguage);
		EndIf;
	EndIf;
	Return vStr;
EndFunction // GetAgentCommissionDescription

#EndRegion 
