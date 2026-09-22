
#Region Public

// --------------------------------------------------------------------------------
Procedure pmPrintSMSReceivers(pDocs, pSpreadsheet, pObjectPrintForm, pLanguage, rDoPrint = Undefined) Export
	pSpreadsheet.Clear();
	If pDocs.Count() = 0 Then
		Return;
	EndIf;
	
	// Choose template
	vTemplate = Documents.SMSDelivery.GetTemplate("PrintSMSReceivers");
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(pObjectPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;
	
	For Each vDocsItem In pDocs Do
		// Add page split
		If pDocs.Indexof(vDocsItem) > 0 Then
			pSpreadsheet.PutHorizontalPageBreak();
		EndIf;
		
		SelSMSDelivery = vDocsItem.Value;
			
		// Header
		vHeader = vTemplate.GetArea("Header");	
		// Hotel
		vHotelObj = Catalogs.Hotels.EmptyRef();
		If ValueIsFilled(SessionParameters.CurrentHotel) Then
			vHotelObj = SessionParameters.CurrentHotel.GetObject();
		EndIf;
		mHotelPrintName = vHotelObj.pmGetHotelPrintName(pLanguage);
		If pLanguage = Catalogs.Languages.RU Then
			mTemplateText = TrimAll(SelSMSDelivery.TemplateTextRu);
		ElsIf pLanguage = Catalogs.Languages.EN Then
			mTemplateText = TrimAll(SelSMSDelivery.TemplateTextEn);
		ElsIf pLanguage = Catalogs.Languages.DE Then
			mTemplateText = TrimAll(SelSMSDelivery.TemplateTextDe);
		Else
			mTemplateText = TrimAll(SelSMSDelivery.TemplateTextRu);
		EndIf;
		// Document date
		mDate = Format(SelSMSDelivery.Date, "DF='dd.MM.yyyy'");
		// Document number
		mFormNumber = cmGetDocumentNumberPresentation(SelSMSDelivery.Number);
		// Fill header parameters
		vHeader.Parameters.mHotelPrintName = mHotelPrintName;
		vHeader.Parameters.mFormNumber = mFormNumber;
		vHeader.Parameters.mTemplateText = mTemplateText;
		vHeader.Parameters.mDate = mDate;
		If SelSMSDelivery.IsByCustomers Then
			vHeader.Parameters.mClientHeader = NStr("ru='Контрагент';en='Customer';de='Firma'");
		Else
			vHeader.Parameters.mClientHeader = NStr("en='Client';ru='Клиент';de='Kunde'");
		EndIf;
		pSpreadsheet.Put(vHeader);
		
		// Get row template area
		vSMSRow = vTemplate.GetArea("SMSRow");
		// Print receivers
		For Each vRow In SelSMSDelivery.Receivers Do
			// Fill parameters
			vSMSRow.Parameters.mLineNumber = vRow.LineNumber;
			vSMSRow.Parameters.mPhone = vRow.Phone;
			If SelSMSDelivery.IsByCustomers Then
				vSMSRow.Parameters.mClient = TrimAll(vRow.Customer);
			Else
				vSMSRow.Parameters.mClient = TrimAll(vRow.Client);
			EndIf;
			vSMSRow.Parameters.mIsSent = vRow.IsSent;
			vSMSRow.Parameters.mCost = Format(vRow.Cost, "ND=17; NFD=2; NZ=");
			vSMSRow.Parameters.mResult = SMS.ServerResponseDescription(TrimR(vRow.Result)).Text;
			// Put row
			pSpreadsheet.Put(vSMSRow);
		EndDo;
		
		// Put footer areas
		vFooter = vTemplate.GetArea("Footer");
		vFooter.Parameters.mTotalCost = cmFormatSum(SelSMSDelivery.Receivers.Total("Cost"), Catalogs.Currencies.FindByCode(643));
		mPosition = "";
		mAuthor = "";
		If ValueIsFilled(SelSMSDelivery.Author) Then
			mPosition = ?(Not IsBlankString(SelSMSDelivery.Author.Position), TrimAll(SelSMSDelivery.Author.Position), NStr("en='Manager';ru='Менеджер';de='Manager'"));
			mAuthor = SelSMSDelivery.Author.GetObject().pmGetEmployeeDescription(SessionParameters.CurrentLanguage);
		EndIf;
		vFooter.Parameters.mPosition = mPosition;
		vFooter.Parameters.mAuthor = mAuthor;
		pSpreadsheet.Put(vFooter);
	EndDo; // By documents in list

	// Setup default attributes
	cmSetDefaultPrintFormSettings(pSpreadsheet, PageOrientation.Portrait, True, 1, True);
	// Check authorities
	cmSetSpreadsheetProtection(pSpreadsheet);
	
	// Get and fill workstation print form settings
	If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
		vWorkstationPrintSettings = SessionParameters.CurrentWorkstation.WorkstationPrintSettings;
		If ValueIsFilled(vWorkstationPrintSettings) Then
			// Try to find records for the current object print form
			vFilter = New Structure("ObjectPrintingForm, IsActive", pObjectPrintForm, True); 
			vPrintSettingsSet = vWorkstationPrintSettings.PrintFormsList.FindRows(vFilter);
			If vPrintSettingsSet.Count() > 0 Then
				For Each vPrintSettings In vPrintSettingsSet Do
					// Fill settings
					cmSetSpreadsheetSettings(pSpreadsheet, vPrintSettings);
					// Check printing direction
					If vPrintSettings.PrintDirection <> Enums.PrintDirections.Screen Then
						vName = cmGetPrintFormFileName(vPrintSettings, NStr("en='SMS receivers';ru='Список получателей СМС';de='SMS-Empfängerliste'")) + " " + TrimAll(SelSMSDelivery.Number);
						cmDoSpreadsheetOutput(pSpreadsheet, vPrintSettings, vName, rDoPrint);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // pmPrintSMSReceivers

// --------------------------------------------------------------------------------
Procedure pmPrintEMailReceivers(pDocs, pSpreadsheet, pObjectPrintForm, pLanguage, rDoPrint = Undefined) Export
	pSpreadsheet.Clear();
	If pDocs.Count() = 0 Then
		Return;
	EndIf;
	
	// Choose template
	vTemplate = Documents.SMSDelivery.GetTemplate("PrintEMailReceivers");
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(pObjectPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;
	
	For Each vDocsItem In pDocs Do
		// Add page split
		If pDocs.Indexof(vDocsItem) > 0 Then
			pSpreadsheet.PutHorizontalPageBreak();
		EndIf;
		
		SelSMSDelivery = vDocsItem.Value;
		
		// Header
		vHeader = vTemplate.GetArea("Header");	
		// Hotel
		vHotelObj = Catalogs.Hotels.EmptyRef();
		If ValueIsFilled(SessionParameters.CurrentHotel) Then
			vHotelObj = SessionParameters.CurrentHotel.GetObject();
		EndIf;
		mHotelPrintName = vHotelObj.pmGetHotelPrintName(pLanguage);
		If pLanguage = Catalogs.Languages.RU Then
			mTemplateText = TrimAll(SelSMSDelivery.TemplateTextRu);
		ElsIf pLanguage = Catalogs.Languages.EN Then
			mTemplateText = TrimAll(SelSMSDelivery.TemplateTextEn);
		ElsIf pLanguage = Catalogs.Languages.DE Then
			mTemplateText = TrimAll(SelSMSDelivery.TemplateTextDe);
		Else
			mTemplateText = TrimAll(SelSMSDelivery.TemplateTextRu);
		EndIf;
		// Document date
		mDate = Format(SelSMSDelivery.Date, "DF='dd.MM.yyyy'");
		// Document number
		mFormNumber = cmGetDocumentNumberPresentation(SelSMSDelivery.Number);
		// Fill header parameters
		vHeader.Parameters.mHotelPrintName = mHotelPrintName;
		vHeader.Parameters.mFormNumber = mFormNumber;
		vHeader.Parameters.mTemplateText = mTemplateText;
		vHeader.Parameters.mDate = mDate;
		If SelSMSDelivery.IsByCustomers Then
			vHeader.Parameters.mClientHeader = NStr("ru='Контрагент';en='Customer';de='Firma'");
		Else
			vHeader.Parameters.mClientHeader = NStr("en='Client';ru='Клиент';de='Kunde'");
		EndIf;
		pSpreadsheet.Put(vHeader);
		
		// Get row template area
		vSMSRow = vTemplate.GetArea("SMSRow");
		// Print receivers
		For Each vRow In SelSMSDelivery.Receivers Do
			// Fill parameters
			vSMSRow.Parameters.mLineNumber = vRow.LineNumber;
			vSMSRow.Parameters.mEMail = vRow.EMail;
			If SelSMSDelivery.IsByCustomers Then
				vSMSRow.Parameters.mClient = TrimAll(vRow.Customer);
			Else
				vSMSRow.Parameters.mClient = TrimAll(vRow.Client);
			EndIf;
			vSMSRow.Parameters.mIsSent = vRow.IsSent;
			vSMSRow.Parameters.mResult = SMS.ServerResponseDescription(TrimR(vRow.Result)).Text;
			// Put row
			pSpreadsheet.Put(vSMSRow);
		EndDo;
		
		// Put footer areas
		vFooter = vTemplate.GetArea("Footer");
		mPosition = "";
		mAuthor = "";
		If ValueIsFilled(SelSMSDelivery.Author) Then
			mPosition = ?(Not IsBlankString(SelSMSDelivery.Author.Position), TrimAll(SelSMSDelivery.Author.Position), NStr("en='Manager';ru='Менеджер';de='Manager'"));
			mAuthor = SelSMSDelivery.Author.GetObject().pmGetEmployeeDescription(SessionParameters.CurrentLanguage);
		EndIf;
		vFooter.Parameters.mPosition = mPosition;
		vFooter.Parameters.mAuthor = mAuthor;
		pSpreadsheet.Put(vFooter);
	EndDo; // By documents in list
	// Setup default attributes
	cmSetDefaultPrintFormSettings(pSpreadsheet, PageOrientation.Portrait, True, 1, True);
	// Check authorities
	cmSetSpreadsheetProtection(pSpreadsheet);
	// Get and fill workstation print form settings
	If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
		vWorkstationPrintSettings = SessionParameters.CurrentWorkstation.WorkstationPrintSettings;
		If ValueIsFilled(vWorkstationPrintSettings) Then
			// Try to find records for the current object print form
			vFilter = New Structure("ObjectPrintingForm, IsActive", pObjectPrintForm, True); 
			vPrintSettingsSet = vWorkstationPrintSettings.PrintFormsList.FindRows(vFilter);
			If vPrintSettingsSet.Count() > 0 Then
				For Each vPrintSettings In vPrintSettingsSet Do
					// Fill settings
					cmSetSpreadsheetSettings(pSpreadsheet, vPrintSettings);
					// Check printing direction
					If vPrintSettings.PrintDirection <> Enums.PrintDirections.Screen Then
						vName = cmGetPrintFormFileName(vPrintSettings, NStr("en='E-Mail receivers';ru='Список получателей E-Mail';de='E-Mailempfängerliste'")) + " " + TrimAll(SelSMSDelivery.Number);
						cmDoSpreadsheetOutput(pSpreadsheet, vPrintSettings, vName, , rDoPrint);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Hotel, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

#EndRegion
