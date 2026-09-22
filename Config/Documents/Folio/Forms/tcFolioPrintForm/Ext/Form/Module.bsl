
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	vError = Print();
	If vError = "" Then
		FillEMailList();
	Else
		ShowMessageBox(,vError);
		Close();
	EndIf;
EndProcedure // OnOpen

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	Height = 297;
	Width = 210;
	RadioButtonServicesFilter = 0;
	cmSetSpreadsheetProtection(Items.FolioSpreadsheet);
	vTransactions = Undefined;
	SelTransactionsAddress = "";
	If Parameters.Property("InputParameter") Then
		SelFolio = Parameters.InputParameter;
		SelLanguage = Parameters.ObjectPrintingForm.Language;
		SelObjectPrintForm = Parameters.ObjectPrintingForm;
		If ValueIsFilled(SelObjectPrintForm) And Not IsBlankString(SelObjectPrintForm.Parameter) Then
			SelGroupBy = TrimAll(SelObjectPrintForm.Parameter);
		Else
			If SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintFolioGroupInPricePerDayRu Or
			   SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintFolioGroupInPricePerDayDe Or
			   SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintFolioGroupInPricePerDayEn Then
				SelGroupBy = "InPricePerDay";
			ElsIf SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintFolioGroupAllPerDayRu Or
			      SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintFolioGroupAllPerDayDe Or 
			      SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintFolioGroupAllPerDayEn Then
				SelGroupBy = "AllPerDay";
			ElsIf SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintFolioGroupInPriceRu Or
			      SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintFolioGroupInPriceDe Or 
			      SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintFolioGroupInPriceEn Then
				SelGroupBy = "InPrice";
			ElsIf SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintFolioGroupAllRu Or
			      SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintFolioGroupAllDe Or
			      SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintFolioGroupAllEn Then
				SelGroupBy = "All";
			ElsIf SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintFolioGroupByServiceRu Or
			      SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintFolioGroupByServiceDe Or
			      SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintFolioGroupByServiceEn Then
				SelGroupBy = "ByService";
			ElsIf SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintExternalClientRu Or 
			      SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintExternalClientDe Or
			      SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintExternalClientEn Then
				SelGroupBy = "ExternalClient";
			ElsIf SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintPropertyDamageRu Or 
			      SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintPropertyDamageDe Or
			      SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintPropertyDamageEn Then
				SelGroupBy = "PropertyDamage";
			EndIf;
		EndIf;
		If Parameters.Property("Transactions") Then
			vTrans = Parameters.Transactions;
			If vTrans.Count() = 1 Then
				If SelObjectPrintForm <> Catalogs.ObjectPrintingForms.FolioPrintChargeRu And 
				   SelObjectPrintForm <> Catalogs.ObjectPrintingForms.FolioPrintChargeEn And 
				   SelObjectPrintForm <> Catalogs.ObjectPrintingForms.FolioPrintChargeDe Then
					vTrans.Clear();
				EndIf;
			EndIf;
			If vTrans.Count() > 0 And ValueIsFilled(SelFolio) Then
				vTransactions = Parameters.InputParameter.GetObject().pmGetAllFolioTransactions(vTrans, True);
				vTransactions.GroupBy("Document, Charge, ChargeParentDoc, RecordType, Folio, FolioParentDoc, FolioClient, Service, Price, Period, AccountingDate, ServiceDate, Remarks, PaymentMethod, PaymentSection, RecorderNumber, Payer, IsRoomRevenue, IsInPrice, CalendarDayType, Room, VATRate, Performer", "Sum, PaymentSum, Limit, VATSum, Quantity");
				SelTransactionsAddress = PutToTempStorage(vTransactions, UUID);
			EndIf;
		ElsIf Parameters.Property("Folios") Then
			vFolios = Parameters.Folios;
			If vFolios.Count() > 0 And ValueIsFilled(SelFolio) Then
				vTransactions = GetFoliosTransactions(vFolios);
				vTransactions.GroupBy("Document, Charge, ChargeParentDoc, RecordType, Folio, FolioParentDoc, FolioClient, Service, Price, Period, AccountingDate, ServiceDate, Remarks, PaymentMethod, PaymentSection, RecorderNumber, Payer, IsRoomRevenue, IsInPrice, CalendarDayType, Room, VATRate, Performer", "Sum, PaymentSum, Limit, VATSum, Quantity");
				SelTransactionsAddress = PutToTempStorage(vTransactions, UUID);
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(SelFolio) And vTransactions = Undefined Then
		vTransactions = SelFolio.GetObject().pmGetAllFolioCharges();
	EndIf;
	If vTransactions <> Undefined Then
		vCharges = vTransactions.Copy();
		vCharges.GroupBy("Service, IsRoomRevenue, IsInPrice", );
		For Each vChargesRow In vCharges Do
			If ValueIsFilled(vChargesRow.Service) And 
			   TypeOf(vChargesRow.Service) = Type("CatalogRef.Services") And 
			   Not vChargesRow.IsRoomRevenue And vChargesRow.IsInPrice Then
				If ServicesList.FindByValue(vChargesRow.Service) = Undefined Then
					ServicesList.Add(vChargesRow.Service, , False);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure FolioSpreadsheetOnChangeAreaContent(pItem, pArea)
	If pArea.Name = "Customer" Then
		If Not IsBlankString(pArea.Text) Then
			SaveCustomerDataAtServer(pArea.Text);
		EndIf;
	EndIf;
EndProcedure // FolioSpreadsheetOnChangeAreaContent

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintButton(pCommand)
	FolioSpreadsheet.Print();
	Close();
EndProcedure // Print

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePrinter(pCommand)
	FolioSpreadsheet.Print(PrintDialogUseMode.Use);
	Close();
EndProcedure // ChoosePrinter

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveAsPDF(pCommand)
	vFilePath = "";
	If ValueIsFilled(SelFolio) Then
		vFilePath = StrReplace(NStr("en='Folio';ru='Фолио';de='Folio'") + " " + TrimAll(tcOnServer.cmGetAttributeByRef(SelFolio, "Number")), " ", "_");
	EndIf;
	vFileType = SpreadsheetDocumentFileType.PDF;
	tcOnClient.SaveSpreadsheetToFile(vFileType, vFilePath, FolioSpreadsheet);
EndProcedure // SaveAsPDF

// -----------------------------------------------------------------------------
&AtClient
Procedure SendByEMail(pCommand)
	vParams = GenerateParametersFolioByEMail();
	OpenForm("CommonForm.tcSendMail", vParams, ThisObject, UUID);
EndProcedure // SendByEMail

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Function Print()
	// Basic checks
	vHotel = SelFolio.Hotel;
	If Not ValueIsFilled(SelFolio.Hotel) Then
		vHotel = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(vHotel) Then
		Return NStr("ru='Не задана текущая гостиница!';de='Das aktuelle Hotel ist nicht angegeben!';en='Default hotel should be selected!'");
	EndIf;
	vCompany = SelFolio.Company;
	If Not ValueIsFilled(SelFolio.Company) Then
		vCompany = vHotel.Company;
	EndIf;
	If Not ValueIsFilled(vCompany) Then
		Return NStr("ru='У гостиницы должна быть указана фирма по умолчанию!';de='Beim Hotel muss standardmäßig eine Firma festgelegt sein!';en='Default hotel company should be selected!'");
	EndIf;
	SelLanguage = SelObjectPrintForm.Language;
	If Not ValueIsFilled(SelLanguage) Then
		SelLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	
	vTransactions = New ValueTable;
	If SelTransactionsAddress <> "" Then
		vTransactions = GetFromTempStorage(SelTransactionsAddress);
	EndIf;	
	If ValueIsFilled(SelFolio) Then
		SelGroupBy = "";
		If SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintFolioGroupInPricePerDayRu Or
		   SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintFolioGroupInPricePerDayDe Or
		   SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintFolioGroupInPricePerDayEn Then
			SelGroupBy = "InPricePerDay";
		ElsIf SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintFolioGroupAllPerDayRu Or
		      SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintFolioGroupAllPerDayDe Or 
		      SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintFolioGroupAllPerDayEn Then
			SelGroupBy = "AllPerDay";
		ElsIf SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintFolioGroupInPriceRu Or
		      SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintFolioGroupInPriceDe Or 
		      SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintFolioGroupInPriceEn Then
			SelGroupBy = "InPrice";
		ElsIf SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintFolioGroupAllRu Or
		      SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintFolioGroupAllDe Or
		      SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintFolioGroupAllEn Then
			SelGroupBy = "All";
		ElsIf SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintFolioGroupByServiceRu Or
		      SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintFolioGroupByServiceDe Or
		      SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintFolioGroupByServiceEn Then
			SelGroupBy = "ByService";
		ElsIf SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintExternalClientRu Or 
		      SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintExternalClientDe Or
		      SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintExternalClientEn Then
			SelGroupBy = "ExternalClient";
		ElsIf SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintPropertyDamageRu Or 
		      SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintPropertyDamageDe Or
		      SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintPropertyDamageEn Then
			SelGroupBy = "PropertyDamage";
		EndIf;
		// If parameter is filled in object printing form catalog item then use it to override standart group by selection   
		vObjectPrintFormParameters = TrimAll(SelObjectPrintForm.Parameter); 
		If Not IsBlankString(SelObjectPrintForm.Parameter) Then
			If StrFind(vObjectPrintFormParameters, "InPricePerDay") > 0 
				Or StrFind(vObjectPrintFormParameters, "AllPerDay") > 0 
				Or StrFind(vObjectPrintFormParameters, "InPrice") > 0 
				Or StrFind(vObjectPrintFormParameters, "All") > 0 
				Or StrFind(vObjectPrintFormParameters, "ByService")
				Or StrFind(vObjectPrintFormParameters, "ExternalClient") > 0 
				Or StrFind(vObjectPrintFormParameters, "PropertyDamage") > 0 Then
				SelGroupBy = SelObjectPrintForm.Parameter;
			EndIf;
		EndIf;
		vMessage = "";
		If SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintClientListRu Or
		   SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintClientListEn Or 
		   SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintClientListDe Then
			Documents.Folio.PrintFolioByClients(SelFolio, SelFolios, SelGroupBy, SelLanguage, SelObjectPrintForm, vTransactions, FolioSpreadsheet, vMessage, ServicesToMerge);
		ElsIf SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintChargeRu Or
		      SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintChargeEn Or 
		      SelObjectPrintForm = Catalogs.ObjectPrintingForms.FolioPrintChargeDe Then
			Documents.Folio.PrintSelectedCharges(SelFolio, SelFolios, SelGroupBy, SelLanguage, SelObjectPrintForm, vTransactions, FolioSpreadsheet, vMessage);
		Else
			Documents.Folio.PrintFolio(SelFolio, SelFolios, SelGroupBy, SelLanguage, SelObjectPrintForm, vTransactions, FolioSpreadsheet, vMessage, ServicesToMerge);
		EndIf;
		If vMessage = "" Then
			Return "";
		Else
			Return vMessage;
		EndIf;	
	Else
		Return NStr("en='No folio is selected!';ru='Не выбран лицевой счет!';de='Kein Personenkonto ist gewählt!'");
	EndIf;
EndFunction // Print 

// -----------------------------------------------------------------------------
&AtClient
Procedure OnReopen()
	vError = Print();
	If vError = "" Then
		FillEMailList();
	Else
		ShowMessageBox(,vError);
		Close();
	EndIf;
EndProcedure // OnReopen

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetFoliosTransactions(pFoliosList)
	i = 0;
	vCurFolio = pFoliosList.Get(i).Value;
	vTransactions = vCurFolio.GetObject().pmGetAllFolioTransactions(, True);
	While i < (pFoliosList.Count() - 1) Do
		i = i + 1;
		vCurFolio = pFoliosList.Get(i).Value;
		vCurTransactions = vCurFolio.GetObject().pmGetAllFolioTransactions(, True);
		For Each vCurTransactionsRow In vCurTransactions Do
			vTransactionsRow = vTransactions.Add();
			FillPropertyValues(vTransactionsRow, vCurTransactionsRow);
		EndDo;
	EndDo;
	Return vTransactions;
EndFunction // GetFoliosTransactionsList

// -----------------------------------------------------------------------------
&AtServer
Function GenerateParametersFolioByEMail()
	// Save current spreadsheet as PDF
	vFileName = StrReplace(NStr("en='Folio';ru='Фолио';de='Folio'") + " " + Format(SelFolio.Number, "ND=12; NFD=0; NG="), " ", "_");
	vFilePath = cmGetFullFileName(vFileName, TempFilesDir()) + ".pdf";
	vFileType = SpreadsheetDocumentFileType.PDF;
	FolioSpreadsheet.Write(vFilePath, vFileType);
	// Initialize message texts
	MessageSubject = ?(ValueIsFilled(SelFolio.Hotel), Catalogs.Hotels.pmGetHotelPrintName(SelFolio.Hotel, SelLanguage), "");
	MessageSubject = ?(IsBlankString(MessageSubject), "", ", ") +  
	                 tcOnServer.cmNStrAtServer("en='Folio N" + TrimAll(SelFolio.Number) + "'; 
					                           |de='Folio N" + TrimAll(SelFolio.Number) + "'; 
	                                           |ru='Фолио №" + TrimAll(SelFolio.Number) + "'", 
	                                           SelLanguage);
	MessageText = "";
	vHotel = SelFolio.Hotel;
	vIsHTML = False;
	vTemplate = Undefined;
	If ValueIsFilled(vHotel) And ValueIsFilled(vHotel.TemplateSendFolioByEMail) Then
		vTemplate = vHotel.TemplateSendFolioByEMail;   
		If ValueIsFilled(vTemplate) Then
			If ValueIsFilled(vTemplate.HTMLTextRu) Or ValueIsFilled(vTemplate.HTMLTextEn) Or ValueIsFilled(vTemplate.HTMLTextDe) Then
				MessageText = SMS.GetHTMLTextByLanguage(vTemplate, SelLanguage);
				If Not IsBlankString(MessageText) Then
					vIsHTML = True;
				EndIf;
			EndIf;
			If IsBlankString(MessageText) Then
				MessageText = SMS.GetSMSTextByLanguage(vTemplate, SelLanguage);
			EndIf;
			If Not IsBlankString(vTemplate.Description) Then
				MessageSubject = cmNStr(vTemplate.Description, SelLanguage);
			EndIf;
		EndIf;
	EndIf;
	If Not IsBlankString(MessageText) Then
	   MessageText = SMS.ReplaceSMSParameters(MessageText, SelFolio, SelFolio.Client);
	EndIf;	
	If Not IsBlankString(MessageSubject) Then
	   MessageSubject = SMS.ReplaceSMSParameters(MessageSubject, SelFolio, SelFolio.Client);
	EndIf;	
	If IsBlankString(MessageText) Then											   
		   MessageText = tcOnServer.cmNStrAtServer("en='Your folio number is " + TrimAll(SelFolio.Number) + "'; 
												   |de='Your folio number is " + TrimAll(SelFolio.Number) + "'; 
												   |ru='Номер вашего счета " + TrimAll(SelFolio.Number) + "'",
												   SelLanguage) + Chars.LF + Chars.LF +
												   tcOnServer.cmNStrAtServer("en='Best regards,'; 
												   |de='Best regards,'; 
												   |ru='С уважением,'",
												   SelLanguage) + Chars.LF + 
												   ?(ValueIsFilled(SelFolio.Hotel), Catalogs.Hotels.pmGetHotelPrintName(SelFolio.Hotel, SelLanguage), "") + Chars.LF 
												   + tcOnServer.cmNStrAtServer(SessionParameters.ConfigurationName, SelLanguage);
	EndIf;				  
	// Call user exit procedure to give possibility to override message subject and message text
	vUserExitProc = Catalogs.ExternalDataProcessors.SendFolioByEMail;
	If ValueIsFilled(vUserExitProc) Then
		If vUserExitProc.ExternalProcessingType = Enums.ExternalProcessingTypes.Algorithm Then
			If Not IsBlankString(vUserExitProc.Algorithm) Then
				SetSafeMode(True);
				Execute(TrimAll(vUserExitProc.Algorithm));
				SetSafeMode(False);
			EndIf;
		EndIf;
	EndIf;
	
	vParams = New Structure();
	vParams.Insert("SelMessageSubject", MessageSubject);
	vParams.Insert("SelMessageText", MessageText);
	vParams.Insert("SelEMails", "");
	vParams.Insert("SelToList", EMailList);
	vFile = New Structure();
	vFile.Insert("FileName", cmGetValidFileName(MessageSubject)+".pdf");
	vFile.Insert("FullFileNameAtClient", "");
	vFile.Insert("FullFileNameAtServer", vFilePath);
	vFile.Insert("CheckRemoveAtClient",  False);
	vFile.Insert("CheckRemoveAtServer", True);
	vParams.Insert("SelFile", vFile);
	vParams.Insert("SelLanguage", SelLanguage);
	vParams.Insert("SelGuestGroup", SelFolio.GuestGroup);
	vParams.Insert("SelSenderName", "");
	vParams.Insert("SelHotel", SelFolio.Hotel);
	vParams.Insert("SelDocument", SelFolio.ParentDoc);
	vParams.Insert("IsHTML", vIsHTML);
	vParams.Insert("SelSMSTemplates", vTemplate);
	Return vParams;
EndFunction // GenerateParametersFolioByEMail

// -----------------------------------------------------------------------------
&AtServer
Procedure FillEMailList()
	EMailList.Clear();
	If Not SelFolio.IsEmpty() And ValueIsFilled(SelFolio.ParentDoc) Then
		If ValueIsFilled(SelFolio.ParentDoc.EMail) Then
			EMailList.Add(SelFolio.ParentDoc.EMail);
		EndIf;
		If ValueIsFilled(SelFolio.Customer.EMail) Then
			EMailList.Add(SelFolio.Customer.EMail);
		EndIf;
		If Not IsBlankString(SelFolio.ParentDoc.ContactPerson) Then
			vContactPersonEMail = cmGetContactPersonEMail(SelFolio.ParentDoc.ContactPerson);
			If Not IsBlankString(vContactPersonEMail) Then
				EMailList.Add(vContactPersonEMail);
			EndIf;
		EndIf;
		If ValueIsFilled(SelFolio.Client.EMail) Then
			EMailList.Add(SelFolio.Client.EMail);
		EndIf;
	EndIf;
	If EMailList.Count() > 0 Then
		Items.FormSendByEMail.Enabled = True;
	Else
		Items.FormSendByEMail.Enabled = False;
	EndIf;
EndProcedure // FillEMailList

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveCustomerDataAtServer(pText)
	If ValueIsFilled(SelFolio.Client) And ValueIsFilled(SelFolio.PaymentMethod) And
	   Not SelFolio.PaymentMethod.IsByBankTransfer Then
		vClientObj = SelFolio.Client.GetObject();
		vClientObj.FolioCustomerPresentation = TrimAll(pText);
		vClientObj.Write();
		vClientObj.pmWriteToClientChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
	EndIf;
EndProcedure // SaveCustomerDataAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesToMergeStartChoice(pItem, pSelectionData, pStandardProcessing)
	pStandardProcessing = False;           
	vMsg = NStr("en = 'Select services to hide into accommodation'; 
				|de = 'Dienste markieren, die in Unterkunft verstecken müssen'; 
				|ru = 'Отметьте услуги, которые нужно спрятать в проживание'");
	ServicesList.ShowCheckItems(New NotifyDescription("ServicesToMergeAfterChoice", ThisObject), vMsg);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesToMergeAfterChoice(pList, pParameters) Export
	If pList <> Undefined Then
		If ServicesToMerge.Count() > 0 Then
			ServicesToMerge.Clear();
		EndIf;
		For Each vElem In pList Do
			If vElem.Check Then
				ServicesToMerge.Add(vElem.Value);
			EndIf;
		EndDo;
	EndIf;
	ServicesToMergeOnChange(Items.ServicesToMerge);
EndProcedure // ServicesToMergeAfterChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesToMergeOnChange(pItem)
	Print();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesToMergeClearing(pItem, pStandardProcessing)
	For Each vServicesListItem In ServicesList Do
		vServicesListItem.Check = False;
	EndDo;
EndProcedure // ServicesToMergeClearing

#EndRegion
