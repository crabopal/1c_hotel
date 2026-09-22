
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	vObj = FormAttributeToValue("Object");
	If vObj.IsNew() Then
		vObj.SetTime(AutoTimeMode.DontUse);
		// Fill attributes with default values
		If Not ValueIsFilled(Object.Author) Then
			vObj.pmFillAttributesWithDefaultValues();
		Else
			vObj.pmFillAuthorAndDate();
		EndIf;
	EndIf;
	// Printing
	If ValueIsFilled(Object.Ref) Then
		WasNew = False;
		FillFunctionsButton();
		FillPrintingButton();
	Else
		WasNew = True;
	EndIf;
	// Save current document date
	OldDate = Object.Date;
	// Show message template text attributes  
	vFormatString = "ND=10; NFD=0; NG=";
	TMessageLengthRu = Format(StrLen(Object.TemplateTextRu), vFormatString);
	TNumberOfSMSRu = Format(SMS.GetNumberOfSegments(Object.TemplateTextRu), vFormatString);
	TMessageLengthEn = Format(StrLen(Object.TemplateTextEn), vFormatString);
	TNumberOfSMSEn = Format(SMS.GetNumberOfSegments(Object.TemplateTextEn), vFormatString);
	TMessageLengthDe = Format(StrLen(Object.TemplateTextDe), vFormatString);
	TNumberOfSMSDe = Format(SMS.GetNumberOfSegments(Object.TemplateTextDe), vFormatString);
	// Fill statistics
	fmRefreshStatistics();
	// Reset write in form flag
	WasWriteInForm = False;
	If Not vObj.IsNew() Then
		If Object.DeliveryType = Enums.DeliveryTypes.SMS Or Object.DeliveryType = Enums.DeliveryTypes.Both Then
			Items.TMessageLengthRu.Visible = True;
			Items.TNumberOfSMSRu.Visible = True;
			Items.TMessageLengthEn.Visible = True;
			Items.TNumberOfSMSEn.Visible = True;
			Items.TMessageLengthDe.Visible = True;
			Items.TNumberOfSMSDe.Visible = True;
			DocumentTextRu.SetFormattedString(New FormattedString(Object.TemplateTextRu));
			DocumentTextEn.SetFormattedString(New FormattedString(Object.TemplateTextEn));
			DocumentTextDe.SetFormattedString(New FormattedString(Object.TemplateTextDe));
		ElsIf Not Object.DeliveryType = Enums.DeliveryTypes.Unisender Then
			DocumentTextRu.SetHTML(Object.TemplateTextRu, New Structure());
			DocumentTextEn.SetHTML(Object.TemplateTextEn, New Structure());
			DocumentTextDe.SetHTML(Object.TemplateTextDe, New Structure());
			Items.TMessageLengthRu.Visible = False;
			Items.TNumberOfSMSRu.Visible = False;
			Items.TMessageLengthEn.Visible = False;
			Items.TNumberOfSMSEn.Visible = False;
			Items.TMessageLengthDe.Visible = False;
			Items.TNumberOfSMSDe.Visible = False;
		EndIf;
	EndIf;
	ValueToFormAttribute(vObj, "Object");
	// User rights
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	EndIf;
	RefreshDisplay();
	RefreshSMSTextAtChildForm();
	If ValueIsFilled(Object.SMSTemplate) Then
		SMSTemplateOnChangeAtServer();
		RefreshSMSTextAtServer();
	EndIf;
	CheckReadOnly(Not ValueIsFilled(Object.Ref));
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	Var vMessage, vAttributeInErr;
	If pWriteParameters.WriteMode = DocumentWriteMode.Posting Then
		pCancel = pCurrentObject.pmCheckDocumentAttributes(vMessage, vAttributeInErr);
		If pCancel Then
			SetObjectAndFormAttributeConformity(pCurrentObject, "Object");
			WriteLogEvent(NStr("en = 'Document.Posting'; de = 'Document.Posting'; ru = 'Документ.Проведение'"), EventLogLevel.Warning, , Object.Ref, NStr(vMessage));  
			// Error message
			tcCommonFunctionOnClientServer.UserMessage(NStr(vMessage), , vAttributeInErr, pCurrentObject, True);
			// Reset write in form flag
			WasWriteInForm = False;
		EndIf;
	EndIf;
	
	CheckReadOnly();

	WasModified = Modified;
	WasNew = pCurrentObject.IsNew();
EndProcedure // BeforeWriteAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure DateOnChange(pItem)
	DateOnChangeAtServer();
EndProcedure // DateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SMSTemplateOnChange(pItem)
	SMSTemplateOnChangeAtServer();
	RefreshSMSText(Items.ReceiversRefreshSMSText);
EndProcedure // SMSTemplateOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure TemplateTextRuOnChange(pItem)
	TMessageLengthRu = Format(StrLen(Object.TemplateTextRu), "ND=10; NFD=0; NG=");
	TNumberOfSMSRu = Format(SMS.GetNumberOfSegments(Object.TemplateTextRu), "ND=10; NFD=0; NG=");
EndProcedure // TemplateTextRuOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure TemplateTextDeOnChange(pItem)
	TMessageLengthDe = Format(StrLen(Object.TemplateTextDe), "ND=10; NFD=0; NG=");
	TNumberOfSMSDe = Format(SMS.GetNumberOfSegments(Object.TemplateTextDe), "ND=10; NFD=0; NG=");
EndProcedure // TemplateTextDeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DeliveryTypeOnChange(pItem)
	If Object.DeliveryType = tcOnServer.cmGetEnumItem("DeliveryTypes", "SMS") 
		Or Object.DeliveryType = tcOnServer.cmGetEnumItem("DeliveryTypes", "Both") Then
		Items.TMessageLengthRu.Visible = True;
		Items.TNumberOfSMSRu.Visible = True;
		Items.TMessageLengthEn.Visible = True;
		Items.TNumberOfSMSEn.Visible = True;
		Items.TMessageLengthDe.Visible = True;
		Items.TNumberOfSMSDe.Visible = True;
	Else
		Items.TMessageLengthRu.Visible = False;
		Items.TNumberOfSMSRu.Visible = False;
		Items.TMessageLengthEn.Visible = False;
		Items.TNumberOfSMSEn.Visible = False;
		Items.TMessageLengthDe.Visible = False;
		Items.TNumberOfSMSDe.Visible = False;
	EndIf;
	If ValueIsFilled(Object.SMSTemplate) Then
		SMSTemplateOnChange(Items.SMSTemplate);
	EndIf;
	RefreshDisplay();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure TemplateTextEnOnChange(pItem)
	TMessageLengthEn = Format(StrLen(Object.TemplateTextEn), "ND=10; NFD=0; NG=");
	TNumberOfSMSEn = Format(SMS.GetNumberOfSegments(Object.TemplateTextEn), "ND=10; NFD=0; NG=");
EndProcedure // TemplateTextENOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ReceiversSMSTextOnChange(pItem)
	vRow = Items.Receivers.CurrentData;
	If vRow <> Undefined Then
		vRow.Cost = 0;
	EndIf;
EndProcedure // ReceiversOnStartEdit

// -----------------------------------------------------------------------------
&AtClient
Procedure ReceiversClientOnChange(pItem)
	vRow = Items.Receivers.CurrentData;
	If vRow <> Undefined Then
		If ValueIsFilled(vRow.Client) Then
			If Object.DeliveryType = tcOnServer.cmGetEnumItem("DeliveryTypes", "SMS") 
				Or Object.DeliveryType = tcOnServer.cmGetEnumItem("DeliveryTypes", "Both") Then
				If IsBlankString(vRow.Phone) And Not IsBlankString(tcOnServer.cmGetAttributeByRef(vRow.Client, "Phone")) Then
					vRow.Phone = SMS.GetValidPhoneNumber(tcOnServer.cmGetAttributeByRef(vRow.Client, "Phone"));
				EndIf;
			EndIf;
			If Object.DeliveryType = tcOnServer.cmGetEnumItem("DeliveryTypes", "EMail") 
				Or Object.DeliveryType = tcOnServer.cmGetEnumItem("DeliveryTypes", "Both") Then
				If IsBlankString(vRow.EMail) And Not IsBlankString(tcOnServer.cmGetAttributeByRef(vRow.Client, "EMail")) Then
					vRow.EMail = tcOnServer.cmGetAttributeByRef(vRow.Client, "EMail");
				EndIf;
			EndIf;
			If Object.DeliveryType = tcOnServer.cmGetEnumItem("DeliveryTypes", "Unisender") Then
				If IsBlankString(vRow.Phone) And Not IsBlankString(tcOnServer.cmGetAttributeByRef(vRow.Client, "Phone")) Then
					vRow.Phone = SMS.GetValidPhoneNumber(tcOnServer.cmGetAttributeByRef(vRow.Client, "Phone"));
				EndIf;
				If IsBlankString(vRow.EMail) And Not IsBlankString(tcOnServer.cmGetAttributeByRef(vRow.Client, "EMail")) Then
					vRow.EMail = tcOnServer.cmGetAttributeByRef(vRow.Client, "EMail");
				EndIf;
			EndIf;
			If Not IsBlankString(Object.TemplateTextRu) Or Not IsBlankString(Object.TemplateTextEn) Or Not IsBlankString(Object.TemplateTextDe) Then
				If Not vRow.IsSent Then
					vRow.ClientDoc = Undefined;
					vRow.SMSText = SMS.ReplaceSMSParameters(GetTeplateText(vRow.Client), vRow.ClientDoc, vRow.Client);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ReceiversClientOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ReceiversCustomerOnChange(pItem)
	vRow = Items.Receivers.CurrentData;
	If vRow <> Undefined Then
		If ValueIsFilled(vRow.Customer) Then
			If Object.DeliveryType = tcOnServer.cmGetEnumItem("DeliveryTypes", "SMS") 
				Or Object.DeliveryType = tcOnServer.cmGetEnumItem("DeliveryTypes", "Both") Then
				If IsBlankString(vRow.Phone) And Not IsBlankString(tcOnServer.cmGetAttributeByRef(vRow.Client, "Phone")) Then
					vRow.Phone = SMS.GetValidPhoneNumber(tcOnServer.cmGetAttributeByRef(vRow.Client, "Phone"));
				EndIf;
			EndIf;
			If Object.DeliveryType = tcOnServer.cmGetEnumItem("DeliveryTypes", "EMail") 
				Or Object.DeliveryType = tcOnServer.cmGetEnumItem("DeliveryTypes", "Both") Then
				If IsBlankString(vRow.EMail) And Not IsBlankString(tcOnServer.cmGetAttributeByRef(vRow.Client, "EMail")) Then
					vRow.EMail = tcOnServer.cmGetAttributeByRef(vRow.Client, "EMail");
				EndIf;
			EndIf;
			If Object.DeliveryType = tcOnServer.cmGetEnumItem("DeliveryTypes", "Unisender") Then
				If IsBlankString(vRow.Phone) And Not IsBlankString(tcOnServer.cmGetAttributeByRef(vRow.Client, "Phone")) Then
					vRow.Phone = SMS.GetValidPhoneNumber(tcOnServer.cmGetAttributeByRef(vRow.Client, "Phone"));
				EndIf;
				If IsBlankString(vRow.EMail) And Not IsBlankString(tcOnServer.cmGetAttributeByRef(vRow.Client, "EMail")) Then
					vRow.EMail = tcOnServer.cmGetAttributeByRef(vRow.Client, "EMail");
				EndIf;
			EndIf;
			If Not IsBlankString(Object.TemplateTextRu) Or Not IsBlankString(Object.TemplateTextEn) Or Not IsBlankString(Object.TemplateTextDe) Then
				If Not vRow.IsSent Then
					vRow.ClientDoc = Undefined;
					vRow.SMSText = SMS.ReplaceSMSParameters(GetTeplateText(vRow.Customer), vRow.ClientDoc, vRow.Customer);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ReceiversCustomerOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ReceiversPhoneOnChange(pItem)
	ReceiversPhoneOnChangeAtServer();
EndProcedure // ReceiversPhoneOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ReceiversEMailOnChange(Item)
	ReceiversEMailOnChangeAtServer();
EndProcedure // ReceiversEMailOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure ReceiversAfterDeleteRow(pItem)
	// Fill statistics
	fmRefreshStatistics();
EndProcedure // ReceiversAfterDeleteRow

// --------------------------------------------------------------------------------
&AtClient
Procedure DocumentTextRuOnChange(pItem)
	DocumentTextRuOnChangeAtServer();
EndProcedure // DocumentTextRuOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure DocumentTextEnOnChange(pItem)
	DocumentTextEnOnChangeAtServer();
EndProcedure // DocumentTextEnOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure DocumentTextDeOnChange(pItem)
	DocumentTextDeOnChangeAtServer();
EndProcedure // DocumentTextDeOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure IsByCustomersOnChange(pItem)
	Object.Receivers.Clear();
	RefreshDisplay();
EndProcedure // IsByCustomersOnChange

#EndRegion

#Region FormTableItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ReceiversBeforeDeleteRow(pItem, pCancel)
	// Remove selection from the messages being already sent
	vSentRowsWereFound = False;
	vInd = 0;
	While vInd < Items.Receivers.SelectedRows.Count() Do
		vRow = Object.Receivers.Get(vInd);
		If vRow.IsSent Then
			Items.Receivers.SelectedRows.Delete(vRow);
			vSentRowsWereFound = True;
		Else
			vInd = vInd + 1;
		EndIf;
	EndDo;
	If vSentRowsWereFound Then  
		pCancel = True;
		vMsg = NStr("en = 'Messages being sent could not be deleted or changed!'; 
					|de = 'Versandte Nachrichten dürfen nicht gelöscht oder bearbeitet werden!'; 
					|ru = 'Отправленные сообщения нельзя удалять или редактировать!'");
		ShowMessageBox(, vMsg);
	EndIf;
EndProcedure // ReceiversBeforeDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure ReceiversBeforeRowChange(pItem, pCancel)
	vRow = Items.Receivers.CurrentData;
	If vRow <> Undefined Then
		If vRow.IsSent Then
			pCancel = True;
		EndIf;
	EndIf;
EndProcedure // ReceiversBeforeRowChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ReceiversOnStartEdit(pItem, pNewRow, pClone)
	vRow = Items.Receivers.CurrentData;
	If vRow <> Undefined Then
		If pNewRow And pClone Then
			vRow.IsSent = False;
			vRow.MessageID = "";
			vRow.Result = "";
		EndIf;
	EndIf;
EndProcedure // ReceiversOnStartEdit

// -----------------------------------------------------------------------------
&AtClient
Procedure AttachmentPathStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromFileAttachingFileSystemExtensionResult", ThisObject));
EndProcedure // AttachmentPathStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure DistributionListStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	
	// Get list of unisender lists
	vList = Unisender.GetLists();
	vList.Insert(0, 0, NStr("en = '<New>'; de = '<Neu>'; ru = '<Новый>'"));
	
	// Ask user to choose from list
	ShowChooseFromMenu(New NotifyDescription("DistributionListAfterItemChoice", ThisObject), vList, pItem);
EndProcedure // DistributionListStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure DistributionListAfterItemChoice(pListItem, pExtraParams) Export
	If pListItem <> Undefined Then
		vListId = pListItem.Value;
		If vListId = 0 Then
			vListName = "";
			ShowInputString(New NotifyDescription("DistributionListAfterNameInput", ThisObject), vListName, NStr("en='Give name to new distribution list'; ru='Дайте название новому списку рассылки'; de='Geben Sie einen Namen für die neue Liste'"), 200, False);
		Else
			Object.DistributionListName = pListItem.Presentation;
			Object.DistributionListId = vListId;
		EndIf;
	EndIf;
EndProcedure // DistributionListAfterItemChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure DistributionListAfterNameInput(pListName, pExtraParams) Export
	If pListName <> Undefined And Not IsBlankString(pListName) Then
		vListId = Unisender.CreateList(pListName);
		If vListId <> 0 Then
			Object.DistributionListName = pListName;
			Object.DistributionListId = vListId;
		EndIf;
	EndIf;
EndProcedure // DistributionListAfterNameInput

// --------------------------------------------------------------------------------
&AtClient
Procedure DistributionListClearing(pItem, pStandardProcessing)
	Object.DistributionListId = 0;
EndProcedure // DistributionListClearing

// --------------------------------------------------------------------------------
&AtClient
Procedure ReceiversOnEditEnd(pItem, pNewRow, pCancelEdit)
	// Fill statistics
	fmRefreshStatistics();
	RefreshSMSTextAtChildForm(pNewRow);
EndProcedure // ReceiversOnEditEnd

// --------------------------------------------------------------------------------
&AtClient
Procedure AttachmentPathOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	If Not IsBlankString(Object.AttachmentPath) Then
		// Run application associated with this file
		BeginRunningApplication(New NotifyDescription, Object.AttachmentPath, TempFilesDir(), False);
	Else
		ShowMessageBox(, NStr("en = 'File is not choosen!'; de = 'Keine Datei ist gewählt!'; ru = 'Не выбран файл!'"));
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure FormMainSend(pCommand)
	vCheck = FormMainSendCheck();
	If Not vCheck.Check Then
		If ValueIsFilled(vCheck.Text) Then
			ShowMessageBox(, vCheck.Text);
		EndIf;
		Return;
	EndIf;
	vOperationParametrs = New Array;
	vReceiversA = New Array();
	For Each vReceiversRow In Object.Receivers Do
		vReceiversA.Add(New Structure("LineNumber, Phone, EMail, Client, Customer, SMSText, Cost, IsSent, Result, MessageID, ClientDoc, ParentDoc, AmountStr, DiscountCard",
									  vReceiversRow.LineNumber,
									  vReceiversRow.Phone,
									  vReceiversRow.EMail,
									  vReceiversRow.Client,
									  vReceiversRow.Customer,
									  vReceiversRow.SMSText,
									  vReceiversRow.Cost,
									  vReceiversRow.IsSent,
									  vReceiversRow.Result,
									  vReceiversRow.MessageID,
									  vReceiversRow.ClientDoc,
									  vReceiversRow.ClientDoc,
									  "",
									  PredefinedValue("Catalog.DiscountCards.EmptyRef")));
	EndDo;
	
	vOperationParametrs.Add(vReceiversA);
	vOperationParametrs.Add(Object.DeliveryType);
	vOperationParametrs.Add(Object.DistributionListId);
	vOperationParametrs.Add(Object.AttachmentPath);
	vOperationParametrs.Add(Object.IsByCustomers);
	vOperationParametrs.Add(Object.SMSTemplate);
	vOperationParametrs.Add(Object.Sender);
	StartProlongedOperation("ProlongedOperations.MessagesDeliverySend", Nstr("en = ''; ru = ''; de = ''"), vOperationParametrs);
EndProcedure // FormMainSend

// -----------------------------------------------------------------------------
&AtClient
Procedure ButtonFill(pCommand)
	If Object.IsByCustomers Then
		ButtonFillByCustomers(Commands.ButtonFillByCustomers);
	Else
		ButtonFillByClients(Commands.ButtonFillByClients);
	EndIf;
EndProcedure // ButtonFill

// -----------------------------------------------------------------------------
&AtClient
Procedure ButtonFillByClients(pCommand)
	If Object.IsByCustomers Then
		Object.IsByCustomers = False;
	EndIf;
	vParam = New Structure();
	vParam.Insert("SelSMSDeliveryObject", Object);
	vParam.Insert("SelHotel", Object.Hotel);
	If ValueIsFilled(Object.Hotel) Then
		vParam.Insert("SelReportingCurrency", tcOnServer.cmGetAttributeByRef(Object.Hotel, "ReportingCurrency"));
		vParam.Insert("SelCountry", tcOnServer.cmGetAttributeByRef(Object.Hotel, "Citizenship"));
	EndIf;
	OpenForm("Document.SMSDelivery.Form.tcFillFormByClients", vParam, ThisObject, Object.Ref);
EndProcedure // ButtonFillByClients

// -----------------------------------------------------------------------------
&AtClient
Procedure ButtonFillByCustomers(pCommand)
	If Not Object.IsByCustomers Then
		Object.IsByCustomers = True;
	EndIf;
	OpenForm("Document.SMSDelivery.Form.tcFillFormByCustomers", New Structure("SelSMSDeliveryObject", Object), ThisObject, UUID);
EndProcedure // ButtonFillByCustomers

// -----------------------------------------------------------------------------
&AtClient
Procedure RefreshSMSText(pCommand)
	If Not IsBlankString(Object.TemplateTextRu) Or Not IsBlankString(Object.TemplateTextEn) Or Not IsBlankString(Object.TemplateTextDe) Then
		RefreshSMSTextAtServer();
	Else
		For Each vRow In Object.Receivers Do
			vRow.SMSText = "";
		EndDo;
		ShowMessageBox(, NStr("en = 'SMS message template text is not filled!'; de = 'Der Mustertext der SMS-Mitteilungen ist nicht angegeben!'; ru = 'Не указан текст шаблона СМС сообщений!'"));
	EndIf;
EndProcedure // RefreshSMSText

// --------------------------------------------------------------------------------
&AtClient
Procedure CheckStatus(pCommand)
	CheckStatusAtServer();
EndProcedure // CheckStatus

// --------------------------------------------------------------------------------
&AtClient
Procedure DetachSpecialOffer(pCommand)
	DetachSpecialOfferAtServer();
	ShowMessageBox(, NStr("en = 'Done!'; de = 'Fertig!'; ru = 'Выполнено!'"));
EndProcedure // DetachSpecialOffer

// --------------------------------------------------------------------------------
&AtClient
Procedure AttachSpecialOffer(pCommand)
	AttachSpecialOfferAtServer();
	ShowMessageBox(, NStr("en = 'Done!'; de = 'Fertig!'; ru = 'Выполнено!'"));
EndProcedure // AttachSpecialOffer

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckReadOnly(IsNew = False)
	vCheck = IsNew;
	For Each vListRow In Object.Receivers Do
		If Not vListRow.IsSent Then
			vCheck = True;
			Break;
		EndIf;
	EndDo;
	
	Items.FormMainSend.Enabled = vCheck;
	Items.ReceiversButtonFill.Enabled = vCheck;
	Items.IsByCustomers.Enabled = vCheck;
	Items.DeliveryType.Enabled = vCheck;
	Items.DistributionList.Enabled = vCheck;
	Items.Sender.Enabled = vCheck;
	Items.SMSTemplate.Enabled = vCheck;
	Items.AttachmentPath.Enabled = vCheck;
	Items.ReceiversRefreshSMSText.Enabled = vCheck;
	Items.Remarks.Enabled = vCheck;
	Items.GroupTemplateTextChanges.Enabled = vCheck;
	Items.ReceiversAdd.Enabled = vCheck;
	Items.ReceiversDelete.Enabled = vCheck;
EndProcedure // CheckReadOnly

// -----------------------------------------------------------------------------
&AtServer
Procedure FillFunctionsButton()
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ObjectFormActions.Ref AS Ref,
	|	ObjectFormActions.Code AS Code,
	|	ObjectFormActions.PredefinedDataName AS PredefinedDataName,
	|	ObjectFormActions.IsDefault AS IsDefault
	|FROM
	|	Catalog.ObjectFormActions AS ObjectFormActions
	|WHERE
	|	NOT ObjectFormActions.DeletionMark
	|	AND ObjectFormActions.ObjectType = &ObjectType
	|	AND ObjectFormActions.IsActive = TRUE
	|
	|ORDER BY
	|	IsDefault DESC,
	|	Code";
	
	Query.SetParameter("ObjectType", Documents.SMSDelivery.EmptyRef());
	QueryResult = Query.Execute();
	vSel = QueryResult.Select();
	Actions.Clear();
	While vSel.Next() Do
		If vSel.PredefinedDataName = "" And TrimAll(vSel.Code) <> "USR" And TrimAll(vSel.Code) <> "USC" Then
			vNewRow = Actions.Add();
			vNewRow.Action = vSel.Ref;
			vNewRow.IsDefault = vSel.IsDefault;
			
			vID = vNewRow.GetID();
			vBtnFunc = "Func"; 
			vCommand = Commands.Add(vBtnFunc + vID);
			vCommand.Action = "FuncButtonClick";
			If vSel.IsDefault Then
				vStructure = New Structure("Title, CommandName",
				TrimAll(vSel.Code) + " " + cmNStr(vSel.Ref), vBtnFunc + vID);
			Else
				vStructure = New Structure("Title, CommandName",
				TrimAll(vSel.Code) + " " + cmNStr(vSel.Ref), vBtnFunc + vID);
			EndIf;
			
			tcOnServer.cmCreateItem(ThisObject, ?( vSel.IsDefault, Items.FormGroupFunctionsDefault, Items.FormGroupFunctionsNotDefault), vBtnFunc + vID, "FormButton", vStructure);
		EndIf;
	EndDo;
EndProcedure // FillFunctionsButton

// -----------------------------------------------------------------------------
&AtServer
Procedure FillPrintingButton()
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ObjectPrintingForms.Ref AS Ref,
	|	ObjectPrintingForms.Code AS Code,
	|	ObjectPrintingForms.PredefinedDataName AS PredefinedDataName,
	|	ObjectPrintingForms.IsDefault AS IsDefault,
	|	ObjectPrintingForms.Language AS Language
	|FROM
	|	Catalog.ObjectPrintingForms AS ObjectPrintingForms
	|WHERE
	|	NOT ObjectPrintingForms.DeletionMark
	|	AND ObjectPrintingForms.IsActive = TRUE
	|	AND ObjectPrintingForms.ObjectType = &ObjectType
	|
	|ORDER BY
	|	IsDefault DESC,
	|	Code
	|TOTALS BY
	|	Language";
	Query.SetParameter("ObjectType", Documents.SMSDelivery.EmptyRef());
	QueryResult = Query.Execute();
	vSel = QueryResult.Select(QueryResultIteration.ByGroups);
	PrintForms.Clear();
	vLang = SessionParameters.CurrentLanguage;  
	vBtnPrint = "Print";
	While vSel.Next() Do
		vSelDetails = vSel.Select(QueryResultIteration.ByGroups);
		
		If vLang = vSel.Language or not ValueIsFilled(vSel.Language) Then
			vParentLang = Items.FormGroupPrintingNotDefaultMain;
		ElsIf Not vLang = vSel.Language Then
			vParentLang = tcOnServer.cmCreateItem(ThisObject, 
												  Items.FormGroupPrintingNotDefaultExtra, 
												  vBtnPrint + vSel.Language, 
												  "FormGroup",
												  New Structure("Type, Title", FormGroupType.Popup, vSel.Language));
		EndIf;
		
		While vSelDetails.Next() Do
			If vSelDetails.PredefinedDataName = "" 
				Or vSelDetails.PredefinedDataName = "SMSDeliveryPrintReceivers" Then 
				vNewRow = PrintForms.Add();
				vNewRow.PrintForm = vSelDetails.Ref;
				vNewRow.IsDefault = vSelDetails.IsDefault;
				
				vID = vNewRow.GetID();
				
				vCommand = Commands.Add(vBtnPrint + vID);
				vCommand.Action = "PrintButtonClick";
				If vSelDetails.IsDefault Then
					vParent = Items.FormGroupPrintingDefault;
				Else
					vParent = vParentLang;
				EndIf;
				vStructure = New Structure("Title, CommandName", TrimAll(vSelDetails.Code) + " " + cmNStr(vSelDetails.ref), vBtnPrint + vID);
				
				tcOnServer.cmCreateItem(ThisObject, vParent, vBtnPrint + vID, "FormButton", vStructure);
			EndIf;
		EndDo;
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintButtonClick()
	If Not ValueIsFilled(Object.Ref) Or Modified Then
		If Not Write(New Structure("WriteMode", DocumentWriteMode.Write)) Then
			Return;
		EndIf;
	EndIf;
	vList = New ValueList();
	vList.Add(Object.Ref);
	If Object.DeliveryType = PredefinedValue("Enum.DeliveryTypes.EMail") Then
		vUseHTML = True;
	Else
		vUseHTML = False;
	EndIf;         
	vParams  = New Structure("DocumentsList, ObjectPrintingForm, UseHTML", vList, PredefinedValue("Catalog.ObjectPrintingForms.SMSDeliveryPrintReceivers"));
	OpenForm("Document.SMSDelivery.Form.tcPrintReceivers", vParams, vUseHTML, ThisObject, UUID);
EndProcedure // PrintButtonClick

// -----------------------------------------------------------------------------
&AtServer
Procedure DateOnChangeAtServer()
	// Automatically assign new document number if year has changed
	If ValueIsFilled(Object.Date) And ValueIsFilled(OldDate) Then
		If Year(OldDate) <> Year(Object.Date) Then
			vObj = FormAttributeToValue("Object");
			vObj.SetNewNumber();
			ValueToFormAttribute(vObj, "Object");
		EndIf;
		OldDate = Object.Date;
	EndIf;
EndProcedure // DateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SMSTemplateOnChangeAtServer ()
	If ValueIsFilled(Object.SMSTemplate) Then
		vUseHTML = False;
		vEmptyHTMLBody1 = 
		"<body>
		|</body>";
		vEmptyHTMLBody2 = 
		"<body>
		|<p><br></p>
		|</body>";
		If Object.DeliveryType = tcOnServer.cmGetEnumItem("DeliveryTypes", "EMail") And 
		  (Not IsBlankString(Object.SMSTemplate.HTMLTextRu) And StrFind(Object.SMSTemplate.HTMLTextRu, vEmptyHTMLBody1) = 0 And StrFind(Object.SMSTemplate.HTMLTextRu, vEmptyHTMLBody2) = 0 Or 
		   Not IsBlankString(Object.SMSTemplate.HTMLTextEn) And StrFind(Object.SMSTemplate.HTMLTextEn, vEmptyHTMLBody1) = 0 And StrFind(Object.SMSTemplate.HTMLTextEn, vEmptyHTMLBody2) = 0 Or 
		   Not IsBlankString(Object.SMSTemplate.HTMLTextDe) And StrFind(Object.SMSTemplate.HTMLTextDe, vEmptyHTMLBody1) = 0 And StrFind(Object.SMSTemplate.HTMLTextDe, vEmptyHTMLBody2) = 0) Then
			vUseHTML = True;
		EndIf;
		If vUseHTML Then
			Object.TemplateTextRu = TrimAll(Object.SMSTemplate.HTMLTextRu);
			Object.TemplateTextEn = TrimAll(Object.SMSTemplate.HTMLTextEn);
			Object.TemplateTextDe = TrimAll(Object.SMSTemplate.HTMLTextDe);
			DocumentTextRu.SetHTML(Object.TemplateTextRu, New Structure);
			DocumentTextRu.SetHTML(Object.TemplateTextRu, New Structure);
			DocumentTextRu.SetHTML(Object.TemplateTextRu, New Structure);
		Else
			Object.TemplateTextRu = TrimAll(Object.SMSTemplate.SMSTextRu);
			Object.TemplateTextEn = TrimAll(Object.SMSTemplate.SMSTextEn);
			Object.TemplateTextDe = TrimAll(Object.SMSTemplate.SMSTextDe);
			DocumentTextRu.SetFormattedString(New FormattedString(Object.TemplateTextRu));
			DocumentTextRu.SetFormattedString(New FormattedString(Object.TemplateTextRu));
			DocumentTextRu.SetFormattedString(New FormattedString(Object.TemplateTextRu));
		EndIf;
		Object.Sender = TrimR(Object.SMSTemplate.Sender);
	EndIf;
	TemplateTextRuOnChange(Items.SMSTemplate);
	TemplateTextEnOnChange(Items.SMSTemplate);
	TemplateTextDeOnChange(Items.SMSTemplate);
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function FormMainSendCheck()
	vObj = FormAttributeToValue("Object");
	vCheck = True;
	vText = "";
	If Modified Or vObj.IsNew() Then
		If Not Write(New Structure("WriteMode", DocumentWriteMode.Write)) Then
			vCheck = False;
		EndIf;
	EndIf;
	// Checks
	If Object.DeliveryType = Enums.DeliveryTypes.Unisender Then
		If Object.DistributionListId = 0 Then
			If Not IsBlankString(Object.DistributionListName) Then
				Object.DistributionListName = "";
			EndIf;
			vText = NStr("en = 'Unisender distribution list should be choosen!'; de = 'Unisender Verteilerliste gewählt werden sollte!'; ru = 'Не указан список рассылки в Unisender!'");
			vCheck = False;
		ElsIf Object.IsByCustomers Then
			vText = NStr("en = 'You can export clients to Unisender only! Export of customers is not supported yet.'; 
						 |de = 'Sie können Kunden zu Unisender exportieren! Export von Firmen wird noch nicht unterstützt.'; 
						 |ru = 'В список рассылки Unisender можно выгружать только клиентов! Выгрузка списка контрагентов не поддерживается.'");
			vCheck = False;
		EndIf;
	EndIf;
	If Object.DeliveryType = Enums.DeliveryTypes.EMail Or Object.DeliveryType = Enums.DeliveryTypes.Both Then
		If ValueIsFilled(Object.SMSTemplate) Then	
			If Not ValueIsFilled(Object.SMSTemplate.Description) Then 
				vText = NStr("en = 'Enter the subject of your message in the message template'; 
							 |de = 'Geben Sie den Betreff Ihrer Nachricht in der Nachrichtenschablone'; 
							 |ru = 'Укажите тему сообщения в шаблоне сообщения'");
				vCheck = False;
			EndIf;
		Else
			vText = NStr("en = 'Specify a template'; de = 'Geben Sie eine Vorlage an'; ru = 'Укажите шаблон'");
			vCheck = False;
		EndIf;
	EndIf;
	vCheckR = New Structure("Check, Text", vCheck, vText);
	Return vCheckR;
EndFunction // FormMainSendCheck

// -----------------------------------------------------------------------------
&AtClient
Procedure StartProlongedOperation(pFunctionName, pOperationName, pOperationParametrs = Undefined)
	BlockForm_ShowProgressBar();
	Items.BackgroundOperationProgress.Title	= NStr("en = 'Background operation in progress, you can continue to work in other forms  - '; ru = 'Выполняется фоновая операция, можете продолжать работать в других формах  - '; de = 'Die Hintergrundoperation läuft, Sie können weiterhin in anderen Formen arbeiten - '") + NStr(pOperationName);
	vBackgroundJob = StartBackgroundJob(pOperationName, pFunctionName, pOperationParametrs);
	CurrentBackgroundJobUUID = vBackgroundJob.UUID;
	AttachIdleHandler("Attachable_CheckBackgroundJobs",1,False);
EndProcedure 

// -----------------------------------------------------------------------------
&AtClient
Procedure BlockForm_ShowProgressBar()
	BackgroundOperationProgress = 0;
	Items.BackgroundOperationProgress.Visible = True;
	ReadOnly = True;
EndProcedure // BlockForm_ShowProgressBar

// -----------------------------------------------------------------------------
&AtClient
Procedure UnlockForm_HideProgressBar()
	BackgroundOperationProgress = 0;
	Items.BackgroundOperationProgress.Visible = False;
	ReadOnly = False;
EndProcedure // UnlockForm_HideProgressBar

// -----------------------------------------------------------------------------
&AtServer
Function StartBackgroundJob(pOperationName, pProcedureName, pProcedureParametrs = Undefined, pTempStorageAddress = Undefined)
	ListOfMessages = New ValueList;
	Return AsyncCalls.StartBackgroundJobWithRecordInRegister(Undefined, pOperationName, pProcedureName, pProcedureParametrs, , , pTempStorageAddress);
EndFunction // StartBackgroundJob

// -----------------------------------------------------------------------------
&AtClient
Procedure Attachable_CheckBackgroundJobs()
	vBackgroundJob 				= CheckBackgroundJobStatus(CurrentBackgroundJobUUID);
	BackgroundOperationProgress = vBackgroundJob.Progress; 
	
	For Each vMsg in vBackgroundJob.Messages Do
		If ListOfMessages.FindByValue(vMsg) = Undefined then
			ListOfMessages.Add(vMsg);
			vNewTexts = StrSplit(vMsg, ";");
			vLineNumber = Undefined;
			For Each vNewText In vNewTexts Do
				If StrFind(vNewText, "LineNumber:") Then
					vLineNumberText = StrReplace(vNewText, "LineNumber:", "");
					If Not ValueIsFilled(vLineNumberText) Then
						Break;
					EndIf;
					vLineNumber = Object.Receivers.Get(Number(vLineNumberText) - 1);
				ElsIf StrFind(vNewText, "Result:") Then
						vLineNumber.Result = TrimAll(StrReplace(vNewText, "Result:", ""));
				ElsIf StrFind(vNewText, "IsSent:") Then
					If StrReplace(vNewText, "IsSent:", "") = "True" Then
						vLineNumber.IsSent = True;
					Else
						vLineNumber.IsSent = False;
					EndIf;
				ElsIf StrFind(vNewText, "MessageID:") Then
					vIdStr = StrReplace(vNewText, "MessageID:", "");
					If ValueIsFilled(vIdStr) Then
						vLineNumber.MessageID = vIdStr;
					EndIf;
				ElsIf StrFind(vNewText, "Cost:") Then
					vCostStr = StrReplace(vNewText, "Cost:", "");
					If ValueIsFilled(vCostStr) Then
						vLineNumber.Cost = Number(vCostStr);
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	vHandler = "Attachable_CheckBackgroundJobs";
	If vBackgroundJob.Status = "Error" Then    
		vErr = NStr("en = 'Error in background job: '; de = 'Fehler beim Ausführen des Hintergrundjobs: '; ru = 'Ошибка выполнения фонового задания: '");
		tcCommonFunctionOnClientServer.TextMessage(vErr + vBackgroundJob.Error);
		DetachIdleHandler(vHandler);
		UnlockForm_HideProgressBar();
	ElsIf vBackgroundJob.Status = "Canceled" Then 
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Background job - canceled.'; de = 'Hintergrundjob - abgebrochen.'; ru = 'Фоновое задание - отменено.'"));
		DetachIdleHandler(vHandler);
		UnlockForm_HideProgressBar();
	ElsIf vBackgroundJob.Status = "Completed" Then
		DetachIdleHandler(vHandler);
		tcOnServer.Wait(1);
		UnlockForm_HideProgressBar();
		fmRefreshStatistics();
		Write(New Structure("WriteMode", DocumentWriteMode.Write));
	EndIf;
EndProcedure // Attachable_CheckBackgroundJobs

// -----------------------------------------------------------------------------
&AtServer
Function CheckBackgroundJobStatus(pBackgroundJobId)
	Return AsyncCalls.CheckBackgroundJob(pBackgroundJobId); 
EndFunction // CheckBackgroundJobStatus

// -----------------------------------------------------------------------------
&AtServer
Procedure ReceiversPhoneOnChangeAtServer()
	vCurRow = Object.Receivers.Get(Items.Receivers.CurrentRow);
	If vCurRow <> Undefined Then
		vCurRow.Phone = SMS.GetValidPhoneNumber(TrimAll(vCurRow.Phone));
		If Not IsBlankString(vCurRow.Phone) Then
			If Not Object.IsByCustomers And ValueIsFilled(vCurRow.Client) Then
				If TrimAll(vCurRow.Client.Phone) <> TrimAll(vCurRow.Phone) Then
					vClientObj = vCurRow.Client.GetObject();
					vClientObj.Phone = vCurRow.Phone;
					vClientObj.Write();
					vClientObj.pmWriteToClientChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				EndIf;
			EndIf;
			If Object.IsByCustomers And ValueIsFilled(vCurRow.Customer) Then
				If TrimAll(vCurRow.Customer.Phone) <> TrimAll(vCurRow.Phone) Then
					vCustomerObj = vCurRow.Customer.GetObject();
					vCustomerObj.Phone = vCurRow.Phone;
					vCustomerObj.Write();
					vCustomerObj.pmWriteToCustomerChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ReceiversPhoneOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ReceiversEMailOnChangeAtServer()
	vCurRow = Object.Receivers.Get(Items.Receivers.CurrentRow);
	If vCurRow <> Undefined Then
		If Not IsBlankString(vCurRow.EMail) Then
			If Not Object.IsByCustomers And ValueIsFilled(vCurRow.Client) Then
				If Lower(TrimAll(vCurRow.Client.EMail)) <> Lower(TrimAll(vCurRow.EMail)) Then
					vClientObj = vCurRow.Client.GetObject();
					vClientObj.EMail = Lower(TrimAll(vCurRow.EMail));
					vClientObj.Write();
					vClientObj.pmWriteToClientChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				EndIf;
			EndIf;
			If Object.IsByCustomers And ValueIsFilled(vCurRow.Customer) Then
				If Lower(TrimAll(vCurRow.Customer.EMail)) <> Lower(TrimAll(vCurRow.EMail)) Then
					vCustomerObj = vCurRow.Customer.GetObject();
					vCustomerObj.EMail = Lower(TrimAll(vCurRow.EMail));
					vCustomerObj.Write();
					vCustomerObj.pmWriteToCustomerChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ReceiversEMailOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure RefreshSMSTextAtServer()
		vStruct = New Structure("Guest");
		For Each vRow In Object.Receivers Do
			If Not vRow.IsSent Then
				If ValueIsFilled(vRow.ClientDoc) And ValueIsFilled(vRow.Client) Then
					vRow.SMSText = SMS.ReplaceSMSParameters(GetTeplateText(vRow.Client), vRow.ClientDoc);
				ElsIf Not Object.IsByCustomers And ValueIsFilled(vRow.Client) 
					Or	Object.IsByCustomers And ValueIsFilled(vRow.Customer) Then
					vRow.SMSText = SMS.ReplaceSMSParameters(GetTeplateText(?(Object.IsByCustomers, vRow.Customer, vRow.Client)), vRow.ClientDoc, ?(Object.IsByCustomers, vRow.Customer, vRow.Client));
				Else
					vRow.SMSText = GetTeplateText();
				EndIf;
			EndIf;
			vRow.MessageLength = Format(StrLen(vRow.SMSText), "ND=10; NFD=0; NG=");
		EndDo;
		// Fill statistics
		fmRefreshStatistics();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function GetTeplateText(pLanguage = Undefined)
	If pLanguage = Undefined Then
		  vLanguage = SessionParameters.CurrentLanguage;
	Else
		 vLanguage = pLanguage.Language; 
	EndIf;
	If vLanguage = Catalogs.Languages.RU Then
		If ValueIsFilled(Object.TemplateTextRu) Then
			Return Object.TemplateTextRu;
		ElsIf ValueIsFilled(Object.TemplateTextEn) Then
			Return Object.TemplateTextEn; 
		Else
			Return Object.TemplateTextDe;
		EndIf;
	ElsIf vLanguage = Catalogs.Languages.EN Then
		If ValueIsFilled(Object.TemplateTextEn) Then
			Return Object.TemplateTextEn;
		ElsIf ValueIsFilled(Object.TemplateTextRu) Then
			Return Object.TemplateTextRu; 
		Else
			Return Object.TemplateTextDe;
		EndIf; 
	ElsIf vLanguage = Catalogs.Languages.DE Then
		If ValueIsFilled(Object.TemplateTextDe) Then
			Return Object.TemplateTextDe;
		ElsIf ValueIsFilled(Object.TemplateTextEn) Then
			Return Object.TemplateTextEn; 
		Else
			Return Object.TemplateTextRu;
		EndIf;
	EndIf;
EndFunction // GetTeplateText

// -----------------------------------------------------------------------------
&AtServer
Procedure RefreshDisplay()
	If Object.DeliveryType = Enums.DeliveryTypes.EMail Then
		Items.ReceiversPhone.Visible = False;
		Items.ReceiversNumberOfSMS.Visible = False;
		Items.ReceiversMessageLength.Visible = True;
		Items.ReceiversCost.Visible = False;
		Items.ReceiversSMSText.Visible = True;
		Items.ReceiversEMail.Visible = True;
		Items.AttachmentPath.Enabled = True;
		Items.SMSTemplate.Enabled = True;
		Items.GroupTemplateTextChanges.Visible = True;
		Items.DocumentTextRu.Enabled = True;
		Items.DocumentTextEn.Enabled = True;
		Items.DocumentTextDe.Enabled = True;
		Items.CommandPanelRu.Visible = True;
		Items.CommandPanelEn.Visible = True;
		Items.CommandPanelDe.Visible = True;
	ElsIf Object.DeliveryType = Enums.DeliveryTypes.SMS Then
		Items.ReceiversPhone.Visible = True;
		Items.ReceiversSMSText.Visible = True;
		Items.ReceiversNumberOfSMS.Visible = True;
		Items.ReceiversMessageLength.Visible = True;
		Items.ReceiversCost.Visible = True;
		Items.GroupTemplateTextChanges.Visible = True;
		Items.ReceiversEMail.Visible = False;
		Items.AttachmentPath.Enabled = False;
		If Not IsBlankString(Object.AttachmentPath) Then
			Object.AttachmentPath = "";
		EndIf;
		Items.SMSTemplate.Enabled = True;
		Items.DocumentTextRu.Enabled = True;
		Items.DocumentTextEn.Enabled = True;
		Items.DocumentTextDe.Enabled = True;
		Items.CommandPanelRu.Visible = False;
		Items.CommandPanelEn.Visible = False;
		Items.CommandPanelDe.Visible = False;
	ElsIf Object.DeliveryType = Enums.DeliveryTypes.Unisender Then
		Items.ReceiversPhone.Visible = True;
		Items.ReceiversEMail.Visible = True;
		Items.ReceiversSMSText.Visible = False;
		Items.ReceiversResult.Visible = False;
		Items.ReceiversNumberOfSMS.Visible = False;
		Items.ReceiversMessageLength.Visible = False;
		Items.GroupTemplateTextChanges.Visible = False;
		Items.ReceiversCost.Visible = False;
		Items.AttachmentPath.Enabled = False;
		If Not IsBlankString(Object.AttachmentPath) Then
			Object.AttachmentPath = "";
		EndIf;
		Items.SMSTemplate.Enabled = False;
		If ValueIsFilled(Object.SMSTemplate) Then
			Object.SMSTemplate = Undefined;
		EndIf;
		Items.DocumentTextRu.Enabled = False;
		Items.DocumentTextEn.Enabled = False;
		Items.DocumentTextDe.Enabled = False;
		If Not IsBlankString(Object.TemplateTextRu) Or Not IsBlankString(Object.TemplateTextEn) 
			Or Not IsBlankString(Object.TemplateTextDe) Then
			Object.TemplateTextRu = "";
			Object.TemplateTextEn = "";
			Object.TemplateTextDe = "";
		EndIf;
	Else
		Items.ReceiversPhone.Visible = True;
		Items.ReceiversSMSText.Visible = True;
		Items.ReceiversNumberOfSMS.Visible = True;
		Items.ReceiversMessageLength.Visible = True;
		Items.ReceiversCost.Visible = True;
		Items.GroupTemplateTextChanges.Visible = True;
		Items.ReceiversEMail.Visible = True;
		Items.AttachmentPath.Enabled = True;
		Items.SMSTemplate.Enabled = True;
		Items.DocumentTextRu.Enabled = True;
		Items.DocumentTextEn.Enabled = True;
		Items.DocumentTextDe.Enabled = True;
	EndIf;
	If Object.DeliveryType = Enums.DeliveryTypes.Both Then
		Items.CommandPanelRu.Visible = False;
		Items.CommandPanelEn.Visible = False;
		Items.CommandPanelDe.Visible = False;
	EndIf;
	
	If Object.DeliveryType = Enums.DeliveryTypes.Unisender Then
		Items.DistributionList.Visible = True;
		Items.Sender.Visible = False;
		Items.AttachmentPath.Enabled = False;
		If Not IsBlankString(Object.AttachmentPath) Then
			Object.AttachmentPath = "";
		EndIf;
		If Object.IsByCustomers Then
			Object.IsByCustomers = False;
		EndIf;
		Items.IsByCustomers.Enabled = False;
	Else
		Items.DistributionList.Visible = False;
		Items.Sender.Visible = True;
		Items.IsByCustomers.Enabled = True;
	EndIf;
	If Object.IsByCustomers Then
		Items.ReceiversClient.Visible = False;
		Items.ReceiversClientDoc.Visible = False;
		Items.ReceiversCustomer.Visible = True;
	Else
		Items.ReceiversClient.Visible = True;
		Items.ReceiversClientDoc.Visible = True;
		Items.ReceiversCustomer.Visible = False;
	EndIf;
	If Object.DeliveryStatus = Enums.SMSDeliveryStatuses.New Then
		Items.DeliveryType.ReadOnly = False;
		Items.Sender.ReadOnly = False;
		Items.DistributionList.ReadOnly = False;
		Items.Hotel.ReadOnly = False;
	ElsIf Object.DeliveryStatus = Enums.SMSDeliveryStatuses.PartiallySent Then
		Items.DeliveryType.ReadOnly = True;
		Items.Sender.ReadOnly = True;
		Items.DistributionList.ReadOnly = True;
		Items.Hotel.ReadOnly = True;
	ElsIf Object.DeliveryStatus = Enums.SMSDeliveryStatuses.Sent Then
		Items.DeliveryType.ReadOnly = True;
		Items.Sender.ReadOnly = True;
		Items.DistributionList.ReadOnly = True;
		Items.Hotel.ReadOnly = True;
	Else
		Items.DeliveryType.ReadOnly = False;
		Items.Sender.ReadOnly = False;
		Items.DistributionList.ReadOnly = False;
		Items.Hotel.ReadOnly = False;
	EndIf;
EndProcedure // RefreshDisplay

// --------------------------------------------------------------------------------
&AtClient 
Procedure OpenFileDialogToChooseFile()  
	vParams = tcOnClientWorkWithFiles.cmGetEmptyParamsForLoadFiles();
	vParams.Form = ThisObject;
	vParams.Item = "AttachmentPath";
	vParams.Filter = tcOnClientWorkWithFiles.cmGetChooseFilterAnyRef();  
	vParams.NotifyDescription = New NotifyDescription("OpenFileDialogToChooseFileCompleted", ThisObject);
	
	tcOnClientWorkWithFiles.LoadFile(vParams);
EndProcedure // OpenFileDialogToChooseFile

// --------------------------------------------------------------------------------
&AtServer
Procedure DocumentTextRuOnChangeAtServer()
	If Object.DeliveryType = Enums.DeliveryTypes.SMS Or Object.DeliveryType = Enums.DeliveryTypes.Both Then
		Object.TemplateTextRu = DocumentTextRu.GetText();
	Else
		vText = "";
		DocumentTextRu.GetHTML(vText, New Structure);
		Object.TemplateTextRu = vText;
	EndIf;
EndProcedure // DocumentTextRuOnChangeAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure DocumentTextEnOnChangeAtServer()
	If Object.DeliveryType = Enums.DeliveryTypes.SMS Or Object.DeliveryType = Enums.DeliveryTypes.Both Then
		Object.TemplateTextEn = DocumentTextRu.GetText();
	Else
		vText = "";
		DocumentTextEn.GetHTML(vText, New Structure);
		Object.TemplateTextEn = vText;
	EndIf;
EndProcedure // DocumentTextEnOnChangeAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure DocumentTextDeOnChangeAtServer()
	If Object.DeliveryType = Enums.DeliveryTypes.SMS Or Object.DeliveryType = Enums.DeliveryTypes.Both Then
		Object.TemplateTextDe = DocumentTextRu.GetText();
	Else
		vText = "";
		DocumentTextDe.GetHTML(vText, New Structure);
		Object.TemplateTextDe = vText;
	EndIf;
EndProcedure // DocumentTextDeOnChangeAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure CheckStatusAtServer()
	vObj = FormAttributeToValue("Object");
	If Modified Or vObj.IsNew() Then
		If Not Write(New Structure("WriteMode", DocumentWriteMode.Write)) Then
			Return;
		EndIf;
	EndIf;
	If Object.DeliveryType = Enums.DeliveryTypes.EMail Then
		// Error message       
		vMsg = NStr("en = 'Check status operation is supported for SMS messages only!'; 
					|de = 'Die Prüfung des Zustellungsstatus wird nur für SMS-Mitteilungen unterstütz!'; 
					|ru = 'Операция проверки статуса доставки поддерживается только для СМС сообщений!'");
		tcCommonFunctionOnClientServer.TextMessage(vMsg);
		Return;
	EndIf;
	vSMSMessagesRecordSet = InformationRegisters.SMSMessages.CreateRecordSet();
	For Each vRow In Object.Receivers Do
	// Call API
		If vRow.IsSent And Not IsBlankString(vRow.MessageID) And vRow.Result <> "Delivered" Then
			vResult = SMS.GetMessageStatus(Format(Number(vRow.MessageID), "NFD=0; NG=0"), vRow.Phone);
			If IsBlankString(vResult.ErrorDescription) Then
				Try
					// Get message being sent
					vMsgData = SMS.GetSentMessageData(vRow.MessageID, vRow.Phone);
					If vMsgData.Count() > 0 Then
						vMessageRow = vMsgData.Get(0);
						// Get message as recordset
						vSMSMessagesRecordSet.Filter.MessageID.Set(vMessageRow.MessageID);
						vSMSMessagesRecordSet.Filter.Period.Set(vMessageRow.Period);
						vSMSMessagesRecordSet.Read();
						If vSMSMessagesRecordSet.Count() > 0 Then
							vSMSMessagesRecordSet[0].Status = vResult.Status;
							// Update message status
							vSMSMessagesRecordSet.Write();
						EndIf;
					EndIf;
					vRow.Result = vResult.Status;
				Except
					tcCommonFunctionOnClientServer.TextMessage(TrimAll(vRow.Phone) + ": " + ErrorDescription(), MessageStatus.Attention);
				EndTry;
			Else
				tcCommonFunctionOnClientServer.TextMessage(vResult.ErrorDescription);
				vRow.Result = ?(IsBlankString(vResult.Result), vResult.Status, vResult.Result);
				Break;
			EndIf;
		EndIf;
	EndDo;
	// Save document
	Write(New Structure("WriteMode", DocumentWriteMode.Write));
	// Fill statistics
	fmRefreshStatistics();
EndProcedure // CheckStatusAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure AttachSpecialOfferAtServer()
	vObject = FormAttributeToValue("Object");
	// Do some checks
	SetObjectAndFormAttributeConformity(vObject, "Object");
	If Not ValueIsFilled(vObject.SpecialOffer) Then  
		vMsg = NStr("en='No special offer is selected!'; ru='Не выбрано спец. предложение!'; de='Keine Sonderangebote ausgewählt!'");
		tcCommonFunctionOnClientServer.UserMessage(vMsg, , "SpecialOffer", vObject, True);
		Return;
	EndIf;
	If Not ValueIsFilled(vObject.SpecialOfferStatus) Then   
		vMsg = NStr("en = 'Special offer status should be specified!'; 
					|de = 'Sonderangebotsstatus sollte angegeben werden!'; 
					|ru = 'Не выбран статус спец. предложения!'");
		tcCommonFunctionOnClientServer.UserMessage(vMsg, , "SpecialOfferStatus", vObject, True);
		Return;
	EndIf;
	// Attach
	For Each vRow In vObject.Receivers Do
		If vObject.SpecialOfferAttachToReservations And ValueIsFilled(vRow.ClientDoc) And TypeOf(vRow.ClientDoc) = Type("DocumentRef.Reservation") Then
			vRcdMgr = InformationRegisters.SpecialOffersForReservations.CreateRecordManager();
			vRcdMgr.SpecialOffer = vObject.SpecialOffer;
			vRcdMgr.OfferStatus = vObject.SpecialOfferStatus;
			vRcdMgr.ParentDoc = vRow.ClientDoc;
			vRcdMgr.Write(True);
		ElsIf Not vObject.SpecialOfferAttachToReservations And (ValueIsFilled(vRow.Client) Or ValueIsFilled(vRow.Customer)) Then
			vRcdMgr = InformationRegisters.SpecialOffersForClients.CreateRecordManager();
			vRcdMgr.SpecialOffer = vObject.SpecialOffer;
			vRcdMgr.OfferStatus = vObject.SpecialOfferStatus;
			If ValueIsFilled(vRow.Client) Then
				vRcdMgr.Client = vRow.Client;
			ElsIf ValueIsFilled(vRow.Customer) Then
				vRcdMgr.Customer = vRow.Customer;
			EndIf;
			vRcdMgr.Write(True);
		EndIf;
	EndDo;
EndProcedure // AttachSpecialOfferAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure DetachSpecialOfferAtServer()
	vObject = FormAttributeToValue("Object");
	// Do some checks
	SetObjectAndFormAttributeConformity(vObject, "Object");
	If Not ValueIsFilled(vObject.SpecialOffer) Then
		vMsg = NStr("en='No special offer is selected!'; ru='Не выбрано спец. предложение!'; de='Keine Sonderangebote ausgewählt!'");
		tcCommonFunctionOnClientServer.UserMessage(vMsg, , "SpecialOffer", vObject, True);
		Return;
	EndIf;
	// Detach
	For Each vRow In vObject.Receivers Do
		If vObject.SpecialOfferAttachToReservations And ValueIsFilled(vRow.ClientDoc) And TypeOf(vRow.ClientDoc) = Type("DocumentRef.Reservation") Then
			vRcdMgr = InformationRegisters.SpecialOffersForReservations.CreateRecordManager();
			vRcdMgr.SpecialOffer = vObject.SpecialOffer;
			vRcdMgr.ParentDoc = vRow.ClientDoc;
			vRcdMgr.Read();
			If vRcdMgr.Selected() Then
				vRcdMgr.Delete();
			EndIf;
		ElsIf Not vObject.SpecialOfferAttachToReservations And (ValueIsFilled(vRow.Client) Or ValueIsFilled(vRow.Customer)) Then
			vRcdMgr = InformationRegisters.SpecialOffersForClients.CreateRecordManager();
			vRcdMgr.SpecialOffer = vObject.SpecialOffer;
			If ValueIsFilled(vRow.Client) Then
				vRcdMgr.Client = vRow.Client;
			ElsIf ValueIsFilled(vRow.Customer) Then
				vRcdMgr.Customer = vRow.Customer;
			EndIf;
			vRcdMgr.Read();
			If vRcdMgr.Selected() Then
				vRcdMgr.Delete();
			EndIf;
		EndIf;
	EndDo;
EndProcedure // DetachSpecialOfferAtServer

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
&AtServer
Procedure fmRefreshStatistics() Export
	TStatistics = "";
	If Object.Receivers.Count() > 0 Then
		vReceiverTotals = New ValueTable();
		vReceiverTotals.Columns.Add("Result", cmGetStringTypeDescription());
		vReceiverTotals.Columns.Add("Count", cmGetNumberTypeDescription(10, 0));
		vReceiverTotals.Columns.Add("IsSent", cmGetBooleanTypeDescription());
		For Each vReceiversRow In Object.Receivers Do
			vReceiverTotalsRows = vReceiverTotals.FindRows(New Structure("Result, IsSent", TrimAll(vReceiversRow.Result), vReceiversRow.IsSent));
			If vReceiverTotalsRows.Count() = 0 Then
				vReceiverTotalsRow = vReceiverTotals.Add();
				vReceiverTotalsRow.Result = TrimAll(vReceiversRow.Result);
				vReceiverTotalsRow.IsSent = vReceiversRow.IsSent;
			Else
				vReceiverTotalsRow = vReceiverTotalsRows.Get(0);
			EndIf;
			vReceiverTotalsRow.Count = vReceiverTotalsRow.Count + 1;
		EndDo;
		For Each vReceiverTotalsRow In vReceiverTotals Do
			vStatusDescription = "";
			If vReceiverTotalsRow.IsSent Then
				vStatusDescription = NStr("en = 'Received by gateway'; de = 'Durch Gateway bearbeitet'; ru = 'Обрабатывается шлюзом'");
			Else
				vStatusDescription = NStr("en = 'Not sent'; de = 'Nicht verschickt'; ru = 'Не отправлено'");
			EndIf;
			If Not IsBlankString(vReceiverTotalsRow.Result) Then
				vStatusDescription = SMS.ServerResponseDescription(TrimAll(vReceiverTotalsRow.Result)).Text;
			EndIf;
			If vReceiverTotals.IndexOf(vReceiverTotalsRow) = 0 Then
				TStatistics = vStatusDescription + ": " + Format(vReceiverTotalsRow.Count, "ND=10; NFD=0; NZ=; NG=");
			Else
				TStatistics = TStatistics + "; " + vStatusDescription + ": " + Format(vReceiverTotalsRow.Count, "ND=10; NFD=0; NZ=; NG=");
			EndIf;
		EndDo;
	EndIf;
EndProcedure // fmRefreshStatistics

// -----------------------------------------------------------------------------
//
// Parameters:
//  pReceiversRow	 - Undefined, TabularSectionRow	 - Base for calculate
//
&AtServer
Procedure RefreshSMSTextAtChildForm(pReceiversRow = Undefined) Export
	If pReceiversRow = Undefined Then
		vReceiversObj = Object.Receivers;
	Else
		vReceiversObj = New Array();
		vReceiversObj.Add(pReceiversRow);
	EndIf;
	
	For Each vRowAppearance In Object.Receivers Do
		vRowAppearance.Result = "";
		vRowAppearance.MessageLength = ""; 
		If Not IsBlankString(vRowAppearance.SMSText) Then
			vRowAppearance.MessageLength = Format(StrLen(TrimR(vRowAppearance.SMSText)), "ND=12; NFD=0; NG=");
			If Object.DeliveryType = Enums.DeliveryTypes.SMS Or Object.DeliveryType = Enums.DeliveryTypes.Both Then
				vNumberOfSMS = SMS.GetNumberOfSegments(TrimR(vRowAppearance.SMSText));
				If vRowAppearance.NumberOfSMS <> vNumberOfSMS Then
					vRowAppearance.NumberOfSMS = vNumberOfSMS;
				EndIf;
			EndIf;
		EndIf;
		// Get message being sent
		Try
			If Object.DeliveryType = Enums.DeliveryTypes.SMS Or Object.DeliveryType = Enums.DeliveryTypes.Both Then
				If vRowAppearance.IsSent Then
					vStatusDescription = NStr("en = 'Received by gateway'; de = 'Durch Gateway bearbeitet'; ru = 'Обрабатывается шлюзом'");
				Else
					vStatusDescription = NStr("en = 'Not sent'; de = 'Nicht verschickt'; ru = 'Не отправлено'");
				EndIf;
				vMsgData = SMS.GetSentMessageData(vRowAppearance.MessageID, vRowAppearance.Phone);
				If vMsgData.Count() > 0 Then
					vMessageRow = vMsgData.Get(0);
					vStatus = TrimR(vMessageRow.Status);
					If TrimR(vRowAppearance.Result) <> vStatus Then
						vRowAppearance.Result = vStatus;
					EndIf;
					vSMSCost = vMessageRow.Cost;
					If vRowAppearance.Cost <> vSMSCost Then
						vRowAppearance.Cost = vSMSCost;
					EndIf;
				EndIf;
			EndIf;
			If Not IsBlankString(vRowAppearance.Result) Then
				vStatusDescription = SMS.ServerResponseDescription(TrimR(vRowAppearance.Result)).Text;
			EndIf;
			vRowAppearance.Result = vStatusDescription;
		Except
			vRowAppearance.Result = ErrorDescription();
		EndTry;
	EndDo;
EndProcedure // RefreshSMSText

// --------------------------------------------------------------------------------
//
// Parameters:
//  pResult	 - Boolean	 - File upload result
//  pParam	 - Structure	 - Additional properties
//
&AtClient
Procedure LoadFromFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		OpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension is being installing on your browser...'; ru='В браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"), MessageStatus.Information);
		BeginInstallFileSystemExtension(New NotifyDescription("LoadFromFileFileSystemExtensionInstallCompleted", ThisObject));
	EndIf;
EndProcedure // LoadFromFileAttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
//
// Parameters:
//  pParam	 - Structure	 - Additional properties
//
&AtClient
Procedure LoadFromFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromFileInstallingFileSystemExtensionResult", ThisObject));
EndProcedure // LoadFromFileFileSystemExtensionInstallCompleted

// -------------------------------------------------------------------------------- 
//
// Parameters:
//  pResult	 - Boolean	 - File upload result
//  pParam	 - Structure	 - Additional properties
//
&AtClient
Procedure LoadFromFileInstallingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='В браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"), MessageStatus.Information);
		OpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"), MessageStatus.Attention);
	EndIf;
EndProcedure // LoadFromFileInstallingFileSystemExtensionResult

// --------------------------------------------------------------------------------
//
// Parameters:
//  pFileArray	 - Array	 - List files
//  pParam		 - Structure	 - Additional properties
//
&AtClient
Procedure OpenFileDialogToChooseFileCompleted(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		Object.AttachmentPath = pFileArray[0];
	EndIf;
EndProcedure // OpenFileDialogToChooseFileCompleted

#EndRegion
     