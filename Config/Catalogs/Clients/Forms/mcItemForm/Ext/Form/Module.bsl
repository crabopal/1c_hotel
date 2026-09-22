
#Region Variables

&AtServer
Var ClientTypeIsDisabled;

#EndRegion

#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	vFormDataStructure = Undefined;
	If Parameters.Property("FormData", vFormDataStructure) Then
		If vFormDataStructure <> Undefined Then
			Object.LastName = vFormDataStructure.LastName;
			Object.FirstName = vFormDataStructure.FirstName;
			Object.SecondName = vFormDataStructure.SecondName;
			Object.DateOfBirth = vFormDataStructure.DateOfBirth;
			Object.IdentityDocumentSeries = vFormDataStructure.IdentityDocumentSeries;
			Object.IdentityDocumentNumber = vFormDataStructure.IdentityDocumentNumber;
			Object.IdentityDocumentIssueDate = vFormDataStructure.IdentityDocumentIssueDate;
			Object.EMail = vFormDataStructure.EMail;
			Object.Phone = vFormDataStructure.Phone;
		EndIf;
	EndIf;
	If Parameters.Property("FillingText") And Not IsBlankString(Parameters.FillingText) And Not ValueIsFilled(Object.Ref) Then
		vNames = StrSplit(TrimAll(Parameters.FillingText), " ", False);
		For i = 1 To vNames.Count() Do
			vName = Title(vNames.Get(i - 1));
			If i = 1 Then
				Object.LastName = vName;
			ElsIf i = 2 Then
				Object.FirstName = vName;
			ElsIf i = 3 Then
				Object.SecondName = vName;
			Else
				Object.SecondName = TrimAll(Object.SecondName) + " " + vName;
			EndIf;
		EndDo;
		If Not ValueIsFilled(Object.Sex) Then
			Object.Sex = fmGetSexByName();
		EndIf;
	EndIf;
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	ClientTypeColorAtServer();
	// Fill fan id data
	WasNew = False;
	If ValueIsFilled(Object.Ref) Then
		FillFanIDData();
	Else
		WasNew = True;
		Items.FanID.Enabled = False;
		Items.FanIDNumber.Enabled = False;
	EndIf;
	// Relationship
	FillRelationshipsListAtServer();
	// Do actions for the new client
	If Not ValueIsFilled(Object.Ref) Then
		// Filter discount cards
		Items.CreditCardsGroup.Visible = False;
		Items.DiscountCardsGroup.Visible = False;
		
		// Fill attributes from the template client
		If Parameters.Property("TemplateGuest") Then
			vTemplateGuest = Parameters.TemplateGuest;
			If ValueIsFilled(vTemplateGuest) And Not IsBlankString(vTemplateGuest.Address) Then
				vPermissionGroup = cmGetEmployeePermissionGroup(SessionParameters.CurrentUser);
				If ValueIsFilled(vPermissionGroup) And Not vPermissionGroup.DoNotCopyGroupClientsAddresses Then
					Object.Address = vTemplateGuest.Address;
				EndIf;
			EndIf;
		EndIf;
	Else
		If ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
			Items.CreditCardsGroup.Visible = False;
		Else
			Items.CreditCardsGroup.Visible = True;
		EndIf;
		Items.DiscountCardsGroup.Visible = True;
		If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
			Items.TableBoxDiscountCards.ChangeRowSet = False;
		EndIf;
		// Apply filter by current client
		vNewFilter 					= TableBoxDiscountCards.SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
		vNewFilter.LeftValue		= New DataCompositionField("Client");
		vNewFilter.ComparisonType	= DataCompositionComparisonType.Equal;
		vNewFilter.RightValue		= Object.Ref;
		vNewFilter.Use				= True;
		vNewFilter.ViewMode 		= DataCompositionSettingsItemViewMode.Inaccessible;
	EndIf;
	// Customer
	DisableFieldsByCustomer();
	// Fill tags
	FillClientTags();
	// Fill document tasks presentation
	FillTasksPresentation();
	NotificationUUID = New UUID();
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	// Other processing
	OnOpenForm();
	// Client presentation
	FillPresentation();
	
	vTasksStructure = GetTasksStructure();
	
	For Each vTasks In vTasksStructure Do
		If	vTasks.Value.PopUp Then
			tcCommonFunctionOnClientServer.TextMessage(vTasks.Value.Remarks);
		EndIf;
	EndDo;
	Title = Items.Pages.CurrentPage.Title;
EndProcedure // OnOpen

 // -----------------------------------------------------------------------------
&AtClient
Procedure ChoiceProcessing(pSelectedValue, pChoiceSource)
	If pChoiceSource.FormName = "Catalog.Tags.Form.tcChoiceForm" And Not pSelectedValue = Undefined Then
		For Each vTag In pSelectedValue Do
			EnableTag(Object.Ref, vTag);
		EndDo; 
		FillClientTags();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "Catalog.DiscountCards.Changed" Then
		If pParameter = Object.Ref Then
			Read();
			ClientTypeColorAtServer();
		EndIf;
	ElsIf pEventName = "MessageWrite" Then
		FillTasksPresentation();
	ElsIf pEventName = "CreditCard.Write" And ValueIsFilled(pParameter) And tcOnServer.cmGetAttributeByRef(pParameter, "CardOwner") = Object.Ref Then
		vCurData = Items.TableBoxCreditCards.CurrentData;
		If vCurData <> Undefined Then
			If ValueIsFilled(pParameter) Then
				vCurData.CreditCard = pParameter;
				vCurData.Author = tcOnServer.cmGetAttributeByRef(pParameter, "Author");
				vCurData.CreateDate = tcOnServer.cmGetAttributeByRef(pParameter, "CreateDate");
			EndIf;
		EndIf;
	EndIf;
EndProcedure // NotificationProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	vMessage = CheckPermissionsAtServer(pCancel, pWriteParameters);
	If Not IsBlankString(vMessage) Then
		tcCommonFunctionOnClientServer.TextMessage(vMessage);
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	// Check client data
	SetObjectAndFormAttributeConformity(pCurrentObject, "Object");
	If Not cmCheckUserPermissions("HavePermissionToDoCheckInWithEmptyGuest") Then
		If Not ValueIsFilled(pCurrentObject.Sex) Then
			vUM = New UserMessage();
			vUM.SetData(pCurrentObject);
			vUM.Field = "Sex";
			vUM.Text = NStr("en='Please fill client sex!';ru='Пожалуйста, укажите пол клиента!';de='Bitte geben Sie das Geschlecht des Kunden an!'");
			vUM.Message();
			pCancel = True;
		EndIf;
		If Not ValueIsFilled(pCurrentObject.Citizenship) Then
			vUM = New UserMessage();
			vUM.SetData(pCurrentObject);
			vUM.Field = "Citizenship";
			vUM.Text = NStr("en='Please fill client citizenship!';ru='Пожалуйста, укажите страну гражданства клиента!';de='Bitte geben Sie das Land des Kunden an!'");
			vUM.Message();
			pCancel = True;
		EndIf;
		If Not cmCheckUserPermissions("HavePermissionToSkipInputOfGuestIdentificationDocumentData") Then
			If IsBlankString(pCurrentObject.IdentityDocumentNumber) Then
				vUM = New UserMessage();
				vUM.SetData(pCurrentObject);
				vUM.Field = "IdentityDocumentNumber";
				vUM.Text = NStr("en='Please fill client identity document data!';ru='Пожалуйста, укажите данные документа удостоверяющего личность клиента!';de='Bitte geben Sie die Personalausweisdaten des Kunden an!'");
				vUM.Message();
				pCancel = True;
			EndIf;
		EndIf;
		If Not cmCheckUserPermissions("HavePermissionToSkipInputOfGuestAddress") Then
			If ValueIsFilled(SessionParameters.CurrentHotel) Then
				If pCurrentObject.Citizenship = SessionParameters.CurrentHotel.Citizenship Then
					If IsBlankString(pCurrentObject.Address) Then
						vUM = New UserMessage();
						vUM.SetData(pCurrentObject);
						vUM.Field = "Address";
						vUM.Text = NStr("en='Please fill client address!';ru='Пожалуйста, укажите адрес прописки клиента!';de='Bitte geben Sie die Meldeanschrift des Kunden an!'");
						vUM.Message();
						pCancel = True;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(pCurrentObject.Citizenship) And pCurrentObject.Citizenship.Code = 643 Then
			If Not IsBlankString(pCurrentObject.SocialSecurityNumber) And Not cmCheckRussianSocialSecurityNumber(TrimR(pCurrentObject.SocialSecurityNumber)) Then
				vUM = New UserMessage();
				vUM.SetData(pCurrentObject);
				vUM.Field = "SocialSecurityNumber";
				vUM.Text = NStr("en='Social security number id wrong!';ru='СНИЛС клиента указан с ошибкой!';de='Sozialversicherungsnummer ist falsch!'");
				vUM.Message();
				pCancel = True;
			EndIf;
		EndIf;
	EndIf;
	// Check Russian passport data
	If ValueIsFilled(pCurrentObject.IdentityDocumentType) And TrimAll(pCurrentObject.IdentityDocumentType.Code) = "21" Then
		If Not IsBlankString(pCurrentObject.IdentityDocumentSeries) Then
			vIdentityDocumentSeries = StrReplace(TrimAll(pCurrentObject.IdentityDocumentSeries), " ", "");
			If StrLen(vIdentityDocumentSeries) <> 4 Then
				vUM = New UserMessage();
				vUM.SetData(pCurrentObject);
				vUM.Field = "IdentityDocumentSeries";
				vUM.Text = NStr("en='Client identity document series amount of digits should be equal to 4!';ru='Количество цифр в серии паспорта должно быть равно 4!';de='Anzahl von Zahlen in der Passserie muss gleich 4 sein!'");
				vUM.Message();
				pCancel = True;
			EndIf;
			If Not cmIsNumber(vIdentityDocumentSeries) Then
				vUM = New UserMessage();
				vUM.SetData(pCurrentObject);
				vUM.Field = "IdentityDocumentSeries";
				vUM.Text = NStr("en='Digits are allowed for client identity document series only!';ru='В серии паспорта разрешены только цифры!';de='In der Passseriennummer sind nur Zahlen erlaubt!'");
				vUM.Message();
				pCancel = True;
			EndIf;
		EndIf;
		If Not IsBlankString(pCurrentObject.IdentityDocumentNumber) Then
			vIdentityDocumentNumber = TrimAll(pCurrentObject.IdentityDocumentNumber);
			If StrLen(vIdentityDocumentNumber) <> 6 Then
				vUM = New UserMessage();
				vUM.SetData(pCurrentObject);
				vUM.Field = "IdentityDocumentNumber";
				vUM.Text = NStr("en='Client identity document number amount of digits should be equal to 6!';ru='Количество цифр в номере паспорта должно быть равно 6!';de='Anzahl von Zahlen in der Passnummer muss gleich 6 sein!'");
				vUM.Message();
				pCancel = True;
			EndIf;
			If Not cmIsNumber(vIdentityDocumentNumber) Then
				vUM = New UserMessage();
				vUM.SetData(pCurrentObject);
				vUM.Field = "IdentityDocumentNumber";
				vUM.Text = NStr("en='Digits are allowed for client identity document number only!';ru='В номере паспорта разрешены только цифры!';de='In der Passnummer sind nur Zahlen erlaubt!'");
				vUM.Message();
				pCancel = True;
			EndIf;
		EndIf;
		If IsBlankString(pCurrentObject.IdentityDocumentSeries) And Not IsBlankString(pCurrentObject.IdentityDocumentNumber) Then
			vUM = New UserMessage();
			vUM.SetData(pCurrentObject);
			vUM.Field = "IdentityDocumentSeries";
			vUM.Text = NStr("en='Client identity document series is missing!';ru='Номер паспорта указан без серии!';de='Die Passnummer ist ohne Seriennummer angegeben!'");
			vUM.Message();
			pCancel = True;
		EndIf;
		If IsBlankString(pCurrentObject.IdentityDocumentNumber) And Not IsBlankString(pCurrentObject.IdentityDocumentSeries) Then
			vUM = New UserMessage();
			vUM.SetData(pCurrentObject);
			vUM.Field = "IdentityDocumentNumber";
			vUM.Text = NStr("en='Client identity document number is missing!';ru='Серия паспорта указана без номера!';de='Die Serie des Ausweises ist ohne Nummer angegeben!'");
			vUM.Message();
			pCancel = True;
		EndIf;
		If Not IsBlankString(pCurrentObject.IdentityDocumentNumber) And IsBlankString(pCurrentObject.IdentityDocumentUnitCode) Then
			vUM = New UserMessage();
			vUM.SetData(pCurrentObject);
			vUM.Field = "IdentityDocumentUnitCode";
			vUM.Text = NStr("en='Client identity document unit code is missing!';ru='Не указан код подразделения кем выдан паспорт!';de='Des Ausweises ist ohne Unterteilung Code angegeben!'");
			vUM.Message();
			pCancel = True;
		EndIf;
		If Not IsBlankString(pCurrentObject.IdentityDocumentNumber) And IsBlankString(pCurrentObject.IdentityDocumentIssuedBy) Then
			vUM = New UserMessage();
			vUM.SetData(pCurrentObject);
			vUM.Field = "IdentityDocumentIssuedBy";
			vUM.Text = NStr("en='Client identity document issued by is missing!';ru='Не указано кем выдан паспорт!';de='Des Ausweises ist ohne Ausgestellt durch angegeben!'");
			vUM.Message();
			pCancel = True;
		EndIf;
	EndIf;
	If ValueIsFilled(pCurrentObject.IdentityDocumentIssueDate) And ValueIsFilled(pCurrentObject.IdentityDocumentValidToDate) And BegOfDay(pCurrentObject.IdentityDocumentValidToDate) < BegOfDay(pCurrentObject.IdentityDocumentIssueDate) Then
		vUM = New UserMessage();
		vUM.SetData(pCurrentObject);
		vUM.Field = "IdentityDocumentValidToDate";
		vUM.Text = NStr("en='Client identity document valid to date is less the document issue date!';ru='Дата окончания периода действия документа удостоверяющего личность указана ранее даты его выдачи!';de='Enddatum des Personalausweises angegeben früher als das Datum der Ausstellung!'");
		vUM.Message();
		pCancel = True;
	EndIf;
	// Check client identity document in the list of forbidden identity documents
	vIDRemarks = "";
	If cmIsClientIdentityDocumentInForbiddenList(pCurrentObject.IdentityDocumentType, pCurrentObject.IdentityDocumentSeries, pCurrentObject.IdentityDocumentNumber, vIDRemarks) Then
		vMessage = pCurrentObject.pmGetFullName() + Chars.LF + NStr("en='Client identity document data found in the forbidden list!';ru='ДУЛ клиента найден в запрещенном списке!';de='PA des Kunden wurde in der Sperrliste gefunden!'") + Chars.LF + vIDRemarks;
		vUM = New UserMessage();
		vUM.SetData(pCurrentObject);
		vUM.Field = "IdentityDocumentNumber";
		vUM.Text = vMessage;
		vUM.Message();
		pCancel = False;
		WriteLogEvent(NStr("en='Client.IdentityDocumentIsForbidden';ru='Клиент.ДУЛВЗапрещенномСписке';de='Client.IdentityDocumentIsForbidden'"), EventLogLevel.Warning, , pCurrentObject.Ref, vMessage); 
	EndIf;
EndProcedure // BeforeWriteAtServer

 // -----------------------------------------------------------------------------
&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	// Save changes to the client change history
	pCurrentObject.pmWriteToClientChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
	// Update client attribute for all folios in the charging rules if was new
	If WasNew Then
		pCurrentObject.pmBindClientToItsChargingRules();
	EndIf;
	// Enable fan id data
	Items.FanID.Enabled = True;
	Items.FanIDNumber.Enabled = True;
	// Appearance
	If ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
		Items.CreditCardsGroup.Visible = False;
	Else
		Items.CreditCardsGroup.Visible = True;
	EndIf;
	Items.DiscountCardsGroup.Visible = True;
	// Apply filter by current client
	vNewFilter 					= TableBoxDiscountCards.SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	vNewFilter.LeftValue		= New DataCompositionField("Client");
	vNewFilter.ComparisonType	= DataCompositionComparisonType.Equal;
	vNewFilter.RightValue		= Object.Ref;
	vNewFilter.Use				= True;
	vNewFilter.ViewMode 		= DataCompositionSettingsItemViewMode.Inaccessible;
EndProcedure // AfterWriteAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	// Notify that client was changed or added
	Notify("Client.Change", Object.Ref, FormOwner);
	WasNew = False;
EndProcedure // AfterWrite

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure IdentityDocumentNumberOnChange(pItem)
	vMessage = CheckIdentityDocumentAtServer();
	If Not IsBlankString(vMessage) Then
		tcCommonFunctionOnClientServer.TextMessage(vMessage);
	EndIf;
EndProcedure // IdentityDocumentNumberOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure IdentityDocumentSeriesOnChange(pItem)
	vMessage = CheckIdentityDocumentAtServer();
	If Not IsBlankString(vMessage) Then
		tcCommonFunctionOnClientServer.TextMessage(vMessage);
	EndIf;
EndProcedure // IdentityDocumentSeriesOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure IdentityDocumentTypeOnChange(pItem)
	vMessage = CheckIdentityDocumentAtServer();
	If Not IsBlankString(vMessage) Then
		tcCommonFunctionOnClientServer.TextMessage(vMessage);
	EndIf;
EndProcedure // IdentityDocumentTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FanIDOnChange(pItem)
	FanIDOnChangeAtServer();
	FillPresentation();
EndProcedure // FanIDOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FanIDNumberOnChange(pItem)
	FanIDNumberOnChangeAtServer();
	FillPresentation();
EndProcedure // FanIDNumberOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RelationshipStartChoice(pItem, pChoiceData, pStandardProcessing)
	vNotifyDescription = New NotifyDescription("RelationshipAfterChoice", ThisObject);
	vParams = New Structure("ValueList, MultipleChoice, Title", Items.Relationship.ChoiceList, False);
	OpenForm("CommonForm.mcChoiceValueList", vParams, ThisObject, UUID, , , vNotifyDescription);
EndProcedure // RelationshipStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure RelationshipAfterChoice(pItem, pExtraParams) Export
	If pItem <> Undefined Then
		Object.Relationship = TrimAll(pItem.Value);
	EndIf;
EndProcedure // RelationshipAfterChoice

&AtClient
Procedure DecorationPlaceOfBirthValueClick(pItem)
	vParameters = New Structure("Country, Address, AddressType", Object.Citizenship, TrimAll(Object.PlaceOfBirth), "PlaceOfBirth");
	OpenForm("CommonForm.tcInputAddress", vParameters, pItem, Object.Ref, , , New NotifyDescription("DecorationPlaceOfBirthValueClickEnd", ThisObject),  FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PersonalNumberOnChange(pItem)
	FillPresentation();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PlaceOfEmploymentOnChange(pItem)
	FillPresentation();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PolicyOfMedicalInsuranceOnChange(pItem)
	FillPresentation();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AmbulatoryCardOnChange(pItem)
	FillPresentation();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DisablementOnChange(pItem)
	FillPresentation();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ChildrenOnChange(pItem)
	FillPresentation();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ParentsOnChange(pItem)
	FillPresentation();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PositionOnChange(pItem)
	FillPresentation();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CertificateOnChange(pItem)
	FillPresentation();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DecorationAddressValueClick(pItem)
	vParameters = New Structure("Country, Address, AddressType", Object.Citizenship, TrimAll(Object.Address), "Address");
	OpenForm("CommonForm.tcInputAddress", vParameters, pItem, Object.Ref, , , New NotifyDescription("DecorationAddressValueClickEnd", ThisObject),  FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DecorationPostalAddressValueClick(pItem)
	vParameters = New Structure("Country, Address, AddressType", Object.Citizenship, TrimAll(Object.PostalAddress), "PostalAddress");
	OpenForm("CommonForm.tcInputAddress", vParameters, Object.PostalAddress, Object.Ref, , , New NotifyDescription("DecorationPostalAddressValueClickEnd", ThisObject),  FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomPropertiesPresentationClearing(pItem, pStandardProcessing)
	RoomProperties.Clear();
	RoomPropertiesPresentation = GetRoomPropertiesPresentation();
	// Save room properties to the document object
	FillDocumentRoomProperties();
	Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomPropertiesPresentationStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vRoomPropertiesList = FillRoomPropertiesList();
	If vRoomPropertiesList.CheckItems(NStr("en='Check room properties...'; ru='Отметьте свойства номеров...'; de='Markieren Zimmereigenschaften...'")) Then
		SaveRoomPropertiesList(vRoomPropertiesList);
	EndIf;
	// Fill presentation
	RoomPropertiesPresentation = GetRoomPropertiesPresentation();
	// Save room properties to the document object
	FillDocumentRoomProperties();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure IdentityDocumentUnitCodeOnChange(pItem)
	If Not IsBlankString(Object.IdentityDocumentUnitCode) Then
		vIssuedByList = GetIssuedByListAtServer(TrimAll(Object.IdentityDocumentUnitCode), True);
		If vIssuedByList.Count() = 1 Then
			Object.IdentityDocumentIssuedBy = vIssuedByList.Get(0).Value;
		ElsIf vIssuedByList.Count() > 1 Then
			vNotifyDescription = New NotifyDescription("IdentityDocumentIssuedByIsChoosen", ThisObject);
			vParams = New Structure("ValueList, MultipleChoice, Title", vIssuedByList, False);
			OpenForm("CommonForm.mcChoiceValueList", vParams, ThisObject, UUID, , , vNotifyDescription);		
		EndIf;
	EndIf;
EndProcedure // IdentityDocumentUnitCodeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientTypeOnChange(pItem)
	ClientTypeConfirmationTextChange();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountCardOnChange(pItem)
	DiscountCardOnChangeAtServer();
EndProcedure // DiscountCardOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SocialSecurityNumberOnChange(pItem)
	SocialSecurityNumberOnChangeAtServer();
EndProcedure // SocialSecurityNumberOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure IdentityDocumentIssuedByStartChoice(pItem, pChoiceData, pStandardProcessing)
	If Not IsBlankString(Object.IdentityDocumentUnitCode) Then
		vIssuedByList = GetIssuedByListAtServer(TrimAll(Object.IdentityDocumentUnitCode), True);
		If vIssuedByList.Count() > 0 Then
			pStandardProcessing = False;
			pChoiceData = New ValueList();
			pChoiceData.LoadValues(vIssuedByList.UnloadValues());
		EndIf;
	EndIf;
EndProcedure // IdentityDocumentIssuedByStartChoice

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure TableBoxCreditCardsCreditCardCreating(pItem, pStandardProcessing)
	If Not ValueIsFilled(Object.Ref) Then
		If Not Write() Then
			pStandardProcessing = False;
			Return;
		EndIf;
	EndIf;
 	OpenForm("Catalog.CreditCards.ObjectForm", New Structure("FillingValues", New Structure("CardOwner, CardNumber", Object.Ref, pItem.EditText)), pItem);
	pStandardProcessing = False;
EndProcedure // TableBoxCreditCardsCreditCardCreating

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure TableBoxCreditCardsCreditCardOnChange(pItem)
	vCurData = Items.TableBoxCreditCards.CurrentData;
	If vCurData <> Undefined Then
		If ValueIsFilled(vCurData.CreditCard) Then
			vCurData.Author = tcOnServer.cmGetAttributeByRef(vCurData.CreditCard, "Author");
			vCurData.CreateDate = tcOnServer.cmGetAttributeByRef(vCurData.CreditCard, "CreateDate");
		Else
			vCurData.Author = Undefined;
			vCurData.CreateDate = Undefined;
		EndIf;
	EndIf;
EndProcedure // TableBoxCreditCardsCreditCardOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PagesOnCurrentPageChange(pItem, pCurrentPage)
	If pCurrentPage.Name = "StatisticsGroup"  And Not StatusOfObject() Then
		BuildClientStatistics();
	EndIf;
	Title = pCurrentPage.Title; 
EndProcedure // PagesOnCurrentPageChange

// -----------------------------------------------------------------------------
&AtClient
Procedure LastNameOnChange(pItem)
	LastNameOnChangeAtServer();
EndProcedure // LastNameOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SecondNameOnChange(pItem)
	SecondNameOnChangeAtServer();
EndProcedure // SecondNameOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FirstNameOnChange(pItem)
	FirstNameOnChangeAtServer()
EndProcedure // FirstNameOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CitizenshipOnChange(pItem)
	CitizenshipOnChangeAtServer();
EndProcedure // CitizenshipOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PhoneOnChange(pItem)
	Object.Phone = SMS.GetValidPhoneNumber(Object.Phone);
EndProcedure // PhoneOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SalutationOnChange(pItem)
	If ValueIsFilled(Object.Salutation) Then
		vSex = tcOnServer.cmGetAttributeByRef(Object.Salutation, "Sex");
		If ValueIsFilled(vSex) Then
			If Object.Sex <> vSex Then
				Object.Sex = vSex;
			EndIf;
		EndIf;
		vTitle = tcOnServer.cmGetAttributeByRef(Object.Salutation, "Title");
		If Not IsBlankString(vTitle) Then
			Object.Title = TrimAll(vTitle);
		EndIf;
	EndIf;
EndProcedure // SalutationOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DecorationTasksClick(pItem)
	Task();
EndProcedure // DecorationVerticalSpacingClick

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomPropertiesPresentationOnChange(pItem)
	Modified = True;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearPhoto(Command)
	ClearPhotoAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SignatureCancel(pCommand)
	Items.GroupNewSignature.Visible = False;
	Items.GroupCreateSignature.Visible = True;
EndProcedure // SignatureCancel

// -----------------------------------------------------------------------------
&AtClient
Procedure CreateSignature(pCommand)
	Items.GroupNewSignature.Visible = True;
	Items.GroupCreateSignature.Visible = False;
EndProcedure // CreateSignature

// -----------------------------------------------------------------------------
&AtClient
Procedure TakeSignature(pCommand)
	Items.GroupNewSignature.Visible = False;
	Items.GroupCreateSignature.Visible = True;	
	#If MobileClient Then
		vResult = Undefined;
		
		If MultimediaTools.PhotoSupported(DeviceCameraType.Rear) Then
			vResult = MultimediaTools.MakePhoto(DeviceCameraType.Rear);	
		Else
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'This device does not support creating photos'; de = 'Dieses Gerät unterstützt keine fotoerstellung'; ru = 'Данное устройство не поддерживает создание фото'"));
		EndIf;
		
		If vResult <> Undefined Then
			vBinaryData = vResult.GetBinaryData();
			LoadSignatureFromFileAtServer(vBinaryData);
			ShowUserNotification(NStr("en = 'Photo added'; de = 'Foto Hinzugefügt'; ru = 'Фотография добавлена'"), , , , UserNotificationStatus.Information, NotificationUUID);
		Else
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Failed to take a picture'; de = 'Das Bild konnte nicht aufgenommen werden'; ru = 'Не удалось сделать снимок'"));	
		EndIf;
	#EndIf
EndProcedure // TakeSignature

// -----------------------------------------------------------------------------
&AtClient
Procedure LoadSignature(pCommand)
	Items.GroupNewSignature.Visible = False;
	Items.GroupCreateSignature.Visible = True;	
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadSignatureFromFileAttachingFileSystemExtensionResult", ThisObject));
EndProcedure // LoadSignature

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearSignature(pCommand)
	ClearSignatureAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AddTag(pCommand)
	If Object.Ref.IsEmpty() Then
		If Not Write() Then
			Return;
		EndIf;	
	EndIf;	
	vParams = New Structure("MultipleChoice", True);
	OpenForm("Catalog.Tags.ChoiceForm", vParams, ThisObject);
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ActionOpenGuestAccommodationHistory(pCommand)
	// Check user rights to view accommodations
	If RightsToOpenTheDocument("Accommodation") Then
		OpenForm("Document.Accommodation.Form.mcAccommodationListForm", New Structure("Client, SelFilterStatus", Object.Ref, 1), ThisObject, UUID);	
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to open accommodations!';ru='Нет прав открывать список размещений!';de='Sie haben keine Rechte, die Unterbringungsliste zu öffnen!'"));	
	EndIf;	
EndProcedure // ActionOpenGuestAccommodationHistory

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ActionOpenGuestReservationHistory(pCommand)
	// Check user rights to view reservations
	If RightsToOpenTheDocument("Reservation") Then
		OpenForm("Document.Reservation.Form.mcReservationListForm", New Structure("SelDocPeriod,SelClient,SelFilterStatus", Date(1, 1, 1), Object.Ref, "&ALL"), ThisObject, UUID);	
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to open reservations!';ru='Нет прав открывать список брони!';de='Sie haben keine Rechte, die Reservierungsliste zu öffnen!'"));	
	EndIf;
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ActionOpenClientResourceReservationHistory(pCommand)
	// Check user rights to view resource reservations
	If RightsToOpenTheDocument("ResourceReservation") Then
		OpenForm("Document.ResourceReservation.Form.tcReservationListForm", New Structure("SelDocPeriod,SelClient,SelFilterStatus", Date(1, 1, 1), Object.Ref, "&ALL"), ThisObject, UUID);
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to open reservations!';ru='Нет прав открывать список брони!';de='Sie haben keine Rechte, die Reservierungsliste zu öffnen!'"));	
	EndIf;
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ClickOnTag(pCommand)
	vActions = New ValueList;
	vActions.Add("ChooseColor", NStr("en = 'Set tag color'; de = 'Legen Sie die Tag-Farbe fest'; ru = 'Задать цвет тега'"), , PictureLib.DataCompositionConditionalAppearance);
	vActions.Add("ClearColor", NStr("en = 'Clear  tag color'; de = 'Markierungsfarbe löschen'; ru = 'Очистить цвет тега'"), , PictureLib.QueryWizardCreateTempTableDropQuery);
	vActions.Add("Delete", NStr("en = 'Delete'; de = 'Löschen'; ru = 'Убрать тег у клиента'"), , PictureLib.Remove);
	vNotifyDescription = New NotifyDescription("ClickOnTagEnd", ThisObject, New Structure("TagItem, CurrentColor", CurrentItem, CurrentItem.BackColor));
	vParams = New Structure("ValueList, MultipleChoice, Title", vActions, False);
	OpenForm("CommonForm.mcChoiceValueList", vParams, ThisObject, UUID, , , vNotifyDescription);
EndProcedure	

// -----------------------------------------------------------------------------
&AtClient
Procedure LoadDefaultChargingRules(pCommand)
	LoadDefaultChargingRulesAtServer();
EndProcedure // LoadDefaultChargingRules

// -----------------------------------------------------------------------------
&AtClient
Procedure NewTask(pCommand)
	If ValueIsFilled(Object.Ref) Then
		stParam = New Structure("SetParamObject", Object.Ref);
		OpenForm("Document.Message.Form.tcDocumentForm", stParam);
	EndIf;
EndProcedure // NewTask

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenFolios(pCommand)
	If ValueIsFilled(Object.Ref) Then
		vParametersStructure = New Structure("IsNew, WasPosted, IsFormModified, ObjectRef", False, False, Modified, Object.Ref);
		OpenForm("CommonForm.tcFoliosForm", New Structure("ParametersStructure", vParametersStructure), ThisObject, UUID);
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Save client first!'; ru='Сначала сохраните клиента!'; de='Speichern Sie den Kunden zuerst!'"));
	EndIf;
EndProcedure // OpenFolios

// -----------------------------------------------------------------------------
&AtClient
Procedure PhotoCancel(pCommand)
	Items.GroupNewPhoto.Visible = False;
	Items.GroupCreatePhoto.Visible = True;
EndProcedure // PhotoCancel

// -----------------------------------------------------------------------------
&AtClient
Procedure CreatePhoto(pCommand)
	Items.GroupNewPhoto.Visible = True;
	Items.GroupCreatePhoto.Visible = False;
EndProcedure // CreatePhoto

// -----------------------------------------------------------------------------
&AtClient
Procedure TakePhoto(pCommand)
	Items.GroupNewPhoto.Visible = False;
	Items.GroupCreatePhoto.Visible = True;
	#If MobileClient Then
		vResult = Undefined;
		
		If MultimediaTools.PhotoSupported(DeviceCameraType.Rear) Then
			vResult = MultimediaTools.MakePhoto(DeviceCameraType.Rear);	
		Else
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'This device does not support creating photos'; de = 'Dieses Gerät unterstützt keine fotoerstellung'; ru = 'Данное устройство не поддерживает создание фото'"));
		EndIf;
		
		If vResult <> Undefined Then
			vBinaryData = vResult.GetBinaryData();
			LoadPhotoFromFileAtServer(vBinaryData);
			ShowUserNotification(NStr("en = 'Photo added'; de = 'Foto Hinzugefügt'; ru = 'Фотография добавлена'"), , , ,UserNotificationStatus.Information, NotificationUUID);
		Else
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Failed to take a picture'; de = 'Das Bild konnte nicht aufgenommen werden'; ru = 'Не удалось сделать снимок'"));	
		EndIf;
	#EndIf
EndProcedure // TakePhoto

// -----------------------------------------------------------------------------
&AtClient
Procedure LoadPhoto(pCommand)
	Items.GroupNewPhoto.Visible = False;
	Items.GroupCreatePhoto.Visible = True;
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadPhotoFromFileAttachingFileSystemExtensionResult", ThisObject));
EndProcedure // LoadPhoto

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ScanDocuments(pCommand)
	vGuestRef = Object.Ref;
	If ValueIsFilled(vGuestRef) Then
		vScanRef = GetClientDataScanDocument(vGuestRef);
		If ValueIsFilled(vScanRef) Then
			OpenForm("Document.ClientDataScans.ObjectForm", New Structure("Key, Guest", vScanRef, vGuestRef), ThisObject, vGuestRef);
		Else
			OpenForm("Document.ClientDataScans.ObjectForm", New Structure("basis", vGuestRef), ThisObject, vGuestRef);
		EndIf;
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Save client first!'; ru='Сначала сохраните клиента!'; de='Speichern Sie den Kunden zuerst!'"));
	EndIf;
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure PlaceOfBirthOnChangeAtServer(pObj = Undefined)
	// Check paramters
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	If Not IsBlankString(vObj.PlaceOfBirth) And IsBlankString(vObj.Address) Then
		If ValueIsFilled(SessionParameters.CurrentUser) Then
			If ValueIsFilled(SessionParameters.CurrentUser.EmployeePreferences) Then
				If SessionParameters.CurrentUser.EmployeePreferences.CopyBirthPlaceToAddress Then
					vObj.Address = vObj.PlaceOfBirth;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PlaceOfBirthOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure BuildClientStatistics(pObj = Undefined)
	// Check parameters
	vUseParameterObject = True;
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;
	// Get type of revenue sums
	vWithVAT = True;
	If ValueIsFilled(SessionParameters.CurrentHotel) Then
		vWithVAT = SessionParameters.CurrentHotel.ShowSalesInReportsWithVAT;
	EndIf;
	// 1. Get client number of check-ins
	vNumberOfCheckIns = vObj.pmCountNumberOfCheckIns();
	// 2. Get client number of nights
	vNumberOfNights = vObj.pmCountNumberOfNights();
	// 3. Get client reservation statistics
	vResStats = vObj.pmGetClientReservationStatistics();
	// 4. Get client revenue statistics
	vRevenues = vObj.pmGetClientRevenueStatistics();
	// 5. Get client last accommodation
	vLastAcc = vObj.pmGetClientLastAccommodation();
	// 6. Get client first accommodation
	vFirstAcc = vObj.pmGetClientFirstAccommodation();
	// Clear statistics table
	TableBoxStatistics.Clear();
	// Client full name
	vRow = TableBoxStatistics.Add();
	vRow.Item = Upper(TrimAll(vObj.FullName)) + ?(ValueIsFilled(vObj.Citizenship), " (" + TrimAll(vObj.Citizenship.ISOCode) + ")", "") + 
	                                ?(ValueIsFilled(vObj.DateOfBirth), NStr("en=', birth ';ru=', род. ';de=', birth '") + Format(vObj.DateOfBirth, "DF=dd.MM.yyyy"), "");
	vRow.IsFirstRow = True;
	vRow.IsHeaderRow = True;
	// Fill statistics table
	vRow = TableBoxStatistics.Add();
	vRow.Item = NStr("en='STATS';ru='СТАТИСТИКА';de='STATISTIK'");
	vRow.IsFirstRow = False;
	vRow.IsHeaderRow = True;
	// Check-ins
	vRow = TableBoxStatistics.Add();
	vRow.Item = NStr("en='  Check-ins';ru='  Заездов';de='  Anreisen'");
	vRow.Value = Format(vNumberOfCheckIns, "ND=10; NFD=0; NZ=; NG=");
	vRow.IsFirstRow = False;
	vRow.IsHeaderRow = False;
	// Nights
	vRow = TableBoxStatistics.Add();
	vRow.Item = NStr("en='  Nights';ru='  Ночей';de='  Nächte'");
	vRow.Value = Format(vNumberOfNights, "ND=10; NFD=0; NZ=; NG=");
	vRow.IsFirstRow = False;
	vRow.IsHeaderRow = False;
	// Reservation statistics
	For Each vResRow In vResStats Do
		vRow = TableBoxStatistics.Add();
		vRow.Item = "  " + TrimAll(vResRow.ReservationStatus);
		vRow.Value = Format(vResRow.Count, "ND=10; NFD=0; NZ=; NG=");
		vRow.IsFirstRow = False;
		vRow.IsHeaderRow = False;
	EndDo;
	// Revenue
	vRow = TableBoxStatistics.Add();
	vRow.Item = NStr("en='REVENUE';ru='ДОХОД';de='ERLÖS'");
	vRow.IsFirstRow = False;
	vRow.IsHeaderRow = True;
	// Revenue statistics
	For Each vRevRow In vRevenues Do
		vRow = TableBoxStatistics.Add();
		vRow.Item = NStr("en='  Total';ru='  Общий';de='  Gesamt'");
		If vWithVAT Then
			vRow.Value = cmFormatSum(vRevRow.SalesTurnover, vRevRow.ReportingCurrency);
		Else
			vRow.Value = cmFormatSum(vRevRow.SalesWithoutVATTurnover, vRevRow.ReportingCurrency);
		EndIf;
		vRow.IsFirstRow = False;
		vRow.IsHeaderRow = False;
	EndDo;
	For Each vRevRow In vRevenues Do
		vRow = TableBoxStatistics.Add();
		vRow.Item = NStr("en='  Room revenue';ru='  За проживание';de='  Für Aufenthalt'");
		If vWithVAT Then
			vRow.Value = cmFormatSum(vRevRow.RoomRevenueTurnover, vRevRow.ReportingCurrency);
		Else
			vRow.Value = cmFormatSum(vRevRow.RoomRevenueWithoutVATTurnover, vRevRow.ReportingCurrency);
		EndIf;
		vRow.IsFirstRow = False;
		vRow.IsHeaderRow = False;
		// ADR
		If vNumberOfNights > 0 Then
			vRow = TableBoxStatistics.Add();
			vRow.Item = NStr("en='  ADR';ru='  Средняя цена за ночь';de='  Durchschnittlicher Tagespreis'");
			If vWithVAT Then
				vRow.Value = cmFormatSum(Round(vRevRow.RoomRevenueTurnover / vNumberOfNights, 2), vRevRow.ReportingCurrency);
			Else
				vRow.Value = cmFormatSum(Round(vRevRow.RoomRevenueWithoutVATTurnover / vNumberOfNights, 2), vRevRow.ReportingCurrency);
			EndIf;
			vRow.IsFirstRow = False;
			vRow.IsHeaderRow = False;
		EndIf;
	EndDo;
	// Accumulating resources
	vAccumulatingResources = "";
	vAccumulatingResourcesStr = FillAccumulatingResources(vAccumulatingResources, vObj);
	If Not IsBlankString(vAccumulatingResourcesStr) Then
		vRow = TableBoxStatistics.Add();
		vRow.Item = "  " + vAccumulatingResources;
		vRow.Value = vAccumulatingResourcesStr;
		vRow.IsFirstRow = False;
		vRow.IsHeaderRow = False;
	EndIf;
	// Bonuses
	vBonusesType = "";
	vBonusesStr = FillBonuses(vBonusesType, vObj);
	If Not IsBlankString(vBonusesStr) Then
		vRow = TableBoxStatistics.Add();
		vRow.Item = "  " + vBonusesType;
		vRow.Value = vBonusesStr;
		vRow.IsFirstRow = False;
		vRow.IsHeaderRow = False;
	EndIf;
	// Last accommodation
	vRow = TableBoxStatistics.Add();
	vRow.Item = NStr("en = 'LAST CHECK-IN'; de = 'LETZTE ANREISE'; ru = 'ПОСЛЕДНИЙ ЗАЕЗД'");
	vRow.IsFirstRow = False;
	vRow.IsHeaderRow = True;
	// Check-in date
	vRow = TableBoxStatistics.Add();
	vRow.Item = NStr("en='  Check-in date';ru='  Дата заезда';de='  Anreisedatum'");
	If ValueIsFilled(vLastAcc) Then
		vRow.Value = Format(vLastAcc.CheckInDate, "DF=dd.MM.yyyy");
	EndIf;
	vRow.IsFirstRow = False;
	vRow.IsHeaderRow = False;
	// Room
	vRow = TableBoxStatistics.Add();
	vRow.Item = NStr("en='  Room';ru='  Номер комнаты';de='  Zimmernummer'");
	If ValueIsFilled(vLastAcc) Then
		vRow.Value = TrimAll(vLastAcc.Room);
	EndIf;
	vRow.IsFirstRow = False;
	vRow.IsHeaderRow = False;
	// Room rate
	vRow = TableBoxStatistics.Add();
	vRow.Item = NStr("en = '  Room rate'; de = '  Tarif'; ru = '  Тариф'");
	If ValueIsFilled(vLastAcc) Then
		vRow.Value = TrimAll(vLastAcc.PricePresentation);
	EndIf;
	vRow.IsFirstRow = False;
	vRow.IsHeaderRow = False;
	// First accommodation
	vRow = TableBoxStatistics.Add();
	vRow.Item = NStr("en = 'FIRST CHECK-IN'; de = 'ERSTE ANREISE'; ru = 'ПЕРВЫЙ ЗАЕЗД'");
	vRow.IsFirstRow = False;
	vRow.IsHeaderRow = True;
	// Check-in date
	vRow = TableBoxStatistics.Add();
	vRow.Item = NStr("en='  Check-in date';ru='  Дата заезда';de='  Anreisedatum'");
	If ValueIsFilled(vFirstAcc) Then
		vRow.Value = Format(vFirstAcc.CheckInDate, "DF=dd.MM.yyyy");
	EndIf;
	vRow.IsFirstRow = False;
	vRow.IsHeaderRow = False;
	If vUseParameterObject = False Then
		// Set object value
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // BuildClientStatistics

// -----------------------------------------------------------------------------
&AtServer
Function FillAccumulatingResources(rAccumulatingResources, pObj = Undefined)
	// Check paramters
	vUseParameterObject = True;
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;
	rAccumulatingResources = "";
	vAccumulatingResourcesDescr = "";
	If Not vObj.IsNew() Then
		vAccTypes = cmGetAccumulatingDiscountTypes();
		For Each vAccTypesRow In vAccTypes Do
			If vAccTypesRow.DiscountType.BonusCalculationFactor <> 0 Then
				Continue;
			EndIf;
			vDiscountTypeObj = vAccTypesRow.DiscountType.GetObject();
			vAccResources = vDiscountTypeObj.pmGetAccumulatingDiscountResources(, , , vObj.Ref);
			For Each vAccResourcesRow In vAccResources Do
				If vAccResourcesRow.Resource <> 0 Then
					vResourcesStr = String(vAccResourcesRow.Resource);
					If IsBlankString(vAccumulatingResourcesDescr) Then
						vAccumulatingResourcesDescr = vResourcesStr;
						rAccumulatingResources = TrimAll(vDiscountTypeObj.Description);
					Else
						vAccumulatingResourcesDescr = vAccumulatingResourcesDescr + Chars.LF + vResourcesStr;
						rAccumulatingResources = rAccumulatingResources + Chars.LF + TrimAll(vDiscountTypeObj.Description);
					EndIf;
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	Return vAccumulatingResourcesDescr;
EndFunction // FillAccumulatingResources

// -----------------------------------------------------------------------------
&AtServer
Function FillBonuses(rBonusesType, pObj = Undefined)
	// Check paramters
	vUseParameterObject = True;
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;
	rBonusesType = "";
	vBonusesDescr = "";
	If Not vObj.IsNew() Then
		vBonusTypes = cmGetBonusDiscountTypes();
		For Each vBonusTypesRow In vBonusTypes Do
			vDiscountTypeObj = vBonusTypesRow.DiscountType.GetObject();
			vBonuses = vDiscountTypeObj.pmGetAccumulatingDiscountResources(, , , vObj.Ref);
			If vBonuses.Count() > 0 Then
				vBonusesRow = vBonuses.Get(0);
				If vBonusesRow.Bonus <> 0 Then
					vBonusesStr = String(vBonusesRow.Bonus);
					If IsBlankString(vBonusesDescr) Then
						vBonusesDescr = vBonusesStr;
						rBonusesType = TrimAll(vDiscountTypeObj.Description);
					Else
						vBonusesDescr = vBonusesDescr + Chars.LF + vBonusesStr;
						rBonusesType = rBonusesType + Chars.LF + TrimAll(vDiscountTypeObj.Description);
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	Return vBonusesDescr;
EndFunction // FillBonuses

// -----------------------------------------------------------------------------
&AtServer
Procedure DisableFieldsByCustomer()
	If ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
		Items.ParametersGroup.Visible = False;
		Items.StatisticsGroup.Visible = False;
	EndIf;
EndProcedure // DisableFieldsByCustomer

// -----------------------------------------------------------------------------
&AtServer
Function  GetTasksStructure()
	vTasksStructure = New Structure();
	If ValueIsFilled(Object.Ref) Then
		vTasks = cmGetMessagesForObject(Object.Ref);
		vNumber = 0;
		For Each vTasksRow In vTasks Do
			vTasksStructure.Insert(TrimAll("Tasks" + vNumber), New Structure("PopUp, Remarks", vTasksRow.PopUp, vTasksRow.Remarks));
			vNumber = vNumber + 1;
		EndDo;
	EndIf;
	Return vTasksStructure;
EndFunction // GetTasksStructure

// -----------------------------------------------------------------------------
&AtServer
Procedure OnOpenForm()
	ClientTypeIsDisabled = False;
	// Get object value
	vObj = FormAttributeToValue("Object");
	RefreshDisplay(vObj);
	If vObj.IsNew() Then
		// Fill attributes with default values
		If Not ValueIsFilled(vObj.Author) Then
			vObj.pmFillAttributesWithDefaultValues();
		EndIf;
		If ValueIsFilled(vObj.LastName) And ValueIsFilled(vObj.Citizenship) Then
			vObj.Sex = fmGetSexByName(vObj);
		EndIf;
	EndIf;
	// Set user rights for some controls
	If Not cmCheckUserPermissions("HavePermissionToIgnoreBlackListLimitations") Then
		Items.DoNotCheckIn.Enabled = False;
		Items.IsInBlackList.Enabled = False;
		Items.IsInWhiteList.Enabled = False;
	EndIf;
	// Check user rights to edit charging rules
	If Not cmCheckUserPermissions("HavePermissionToEditChargingRules") Then
		Items.ChargingRules.ReadOnly = True;
	EndIf;
	// Check user rights to edit discounts
	If Not cmCheckUserPermissions("HavePermissionToAddManualDiscounts") Then
		Items.DiscountType.Enabled = False;
		Items.DiscountConfirmationText.Enabled = False;
	EndIf;
	// Check user rights to edit client type
	If Not cmCheckUserPermissions("HavePermissionToChooseClientTypeManually") Then
		Items.ClientType.Enabled = False;
		Items.ClientTypeConfirmationText.Enabled = False;
		ClientTypeIsDisabled = True;
	EndIf;
	// Load credit cards
	If Not vObj.IsNew() Then
		FillListOfClientCreditCards(vObj);
	EndIf;	
	// Fill room properties
	RoomProperties = GetRoomPropertiesValueList(vObj);
	// Fill room properties presentation
	RoomPropertiesPresentation = GetRoomPropertiesPresentation();
	// Show photo
	vClientPhotoPicture = vObj.Photo.Get();
	If vClientPhotoPicture <> Undefined Then
		vClientPhotoTmpStorageAddr = PutToTempStorage(vClientPhotoPicture, UUID);
		ClientPhoto = vClientPhotoTmpStorageAddr;
	Else
		ClientPhoto = "";
	EndIf;
	// Show signature
	vClientSignaturePicture = vObj.Signature.Get();
	If vClientSignaturePicture <> Undefined Then
		vClientSignatureTmpStorageAddr = PutToTempStorage(vClientSignaturePicture, UUID);
		ClientSignature = vClientSignatureTmpStorageAddr;
	Else
		ClientSignature = "";
	EndIf;
	// SNILS
	If ValueIsFilled(vObj.Citizenship) And vObj.Citizenship.Code = 643 Then
		Items.SocialSecurityNumber.Mask = "999-999-999 99";
	EndIf;
	// Set object value
	ValueToFormAttribute(vObj, "Object");
EndProcedure // OnOpenForm

// -----------------------------------------------------------------------------
&AtServer
Procedure FillListOfClientCreditCards(pObj = Undefined)
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		vObj = pObj;
	EndIf;
	TableBoxCreditCards.Clear();
	vCCList = cmGetListOfPayersCreditCards(vObj.Ref);
	For Each vCCItem In vCCList Do
		vRow = TableBoxCreditCards.Add();
		vRow.CreditCard = vCCItem.Value;
		FillCreditCardRowAttributes(vRow);
	EndDo;
EndProcedure // FillListOfClientCreditCards

// -----------------------------------------------------------------------------
&AtServer
Procedure FillCreditCardRowAttributes(pRow)
	If ValueIsFilled(pRow.CreditCard) Then
		pRow.Author = pRow.CreditCard.Author;
		pRow.CreateDate = pRow.CreditCard.CreateDate;
	Else
		pRow.Author = Catalogs.Employees.EmptyRef();
		pRow.CreateDate = Undefined;
	EndIf;
EndProcedure // FillCreditCardRowAttributes

// -----------------------------------------------------------------------------
&AtServer
Function StatusOfObject(pObj = Undefined)
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
	EndIf;
	Return vObj.IsNew();
EndFunction // StatusOfObject

// -----------------------------------------------------------------------------
&AtServer
Procedure RefreshDisplay(pObj = Undefined)
	// Check parameters
	vUseParameterObject = True;
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;
	vDescription = vObj.pmGetDescription();
	If vDescription <> vObj.Description Then
		vObj.Description = vDescription;
	EndIf;
	TDescription = TrimAll(vObj.Description) + " - " + ?(cmIsNumber(vObj.Code), Format(Number(vObj.Code), "ND=12; NFD=0; NG="), TrimAll(vObj.Code));
	vFullName = vObj.pmGetFullName();
	If vFullName <> vObj.FullName Then
		vObj.FullName = vFullName;
	EndIf;
	// Set client header backgrount and font to red if it is in the "black" list
	RedColor = tcCommonFunctionOnClientServer.ColorConstructor(255, 0, 0);
	GreenColor = tcCommonFunctionOnClientServer.ColorConstructor(0, 255, 0);
	WhiteColor = tcCommonFunctionOnClientServer.ColorConstructor(255, 255, 255);
	AutoColor = tcCommonFunctionOnClientServer.ColorConstructor();
	If vObj.IsInBlackList Then
		Items.TDescription1.TextColor = RedColor;
		Items.TDescription2.TextColor = RedColor;
		Items.TDescription3.TextColor = RedColor;
		Items.TDescription4.TextColor = RedColor;
		Items.TDescription5.TextColor = RedColor;
		Items.TDescription.TextColor = RedColor;
		TDescription = TDescription + NStr("en=' <In black list>';ru=' <В черном списке>';de=' <in der ""schwarzen Liste"">'");
	ElsIf vObj.IsInWhiteList Then
		Items.TDescription1.TextColor = GreenColor;
		Items.TDescription2.TextColor = GreenColor;
		Items.TDescription3.TextColor = GreenColor;
		Items.TDescription4.TextColor = GreenColor;
		Items.TDescription5.TextColor = GreenColor;
		Items.TDescription.TextColor = GreenColor;
		TDescription = TDescription + NStr("en=' <In white list>';ru=' <В белом списке>';de=' <in der ""weißen Liste"">'");
	Else
		Items.TDescription1.TextColor = AutoColor;
		Items.TDescription2.TextColor = AutoColor;
		Items.TDescription3.TextColor = AutoColor;
		Items.TDescription4.TextColor = AutoColor;
		Items.TDescription5.TextColor = AutoColor;
		Items.TDescription.TextColor = AutoColor;
	EndIf;
	// Set client type appearance
	ClientTypesAllowed = cmGetAllClientTypes();
	If Not ClientTypeIsDisabled Then
		If ClientTypesAllowed.Count() > 0 Then
			If ValueIsFilled(vObj.ClientType) Then
				If ClientTypesAllowed.Find(vObj.ClientType, "ClientType") = Undefined Then
					Items.ClientType.Enabled = False;
					Items.ClientTypeConfirmationText.Enabled = False;
				Else
					Items.ClientType.Enabled = True;
					Items.ClientTypeConfirmationText.Enabled = True;
				EndIf;
			Else
				Items.ClientType.Enabled = True;
				Items.ClientTypeConfirmationText.Enabled = True;
			EndIf;
		EndIf;
	EndIf;
	If vUseParameterObject = False Then
		// Set object value
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // RefreshDisplay

// -----------------------------------------------------------------------------
&AtServer
Function fmGetSexByName(pObj = Undefined) 
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	If ValueIsFilled(vObj.Citizenship) Then
		If Not vObj.Citizenship.IsVisaNecessaryForEntrance Then
			If StrLen(TrimAll(vObj.SecondName)) < 2 Then
				vLastCharLastName = Upper(Right(TrimAll(vObj.LastName), 1));
				vLastCharFirstName = Upper(Right(TrimAll(vObj.FirstName), 1));
				If (vLastCharLastName = "А") Or (vLastCharLastName = "Я") Or
				   (vLastCharFirstName = "А") Or (vLastCharFirstName = "Я") Then
					Return Enums.Sex.Female;
				Else
					Return Enums.Sex.Male;
				EndIf;
			Else
				vLastCharSecondName = Upper(Right(TrimAll(vObj.SecondName), 1));
				If vLastCharSecondName = "А" Then
					Return Enums.Sex.Female;
				Else
					Return Enums.Sex.Male;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndFunction // fmGetSexByName

// -----------------------------------------------------------------------------
&AtServer
Procedure LastNameOnChangeAtServer(pObj = Undefined)
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	vObj.LastName = Title(TrimAll(vObj.LastName));
EndProcedure // LastNameOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FirstNameOnChangeAtServer(pObj = Undefined)
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	vObj.FirstName = Title(TrimAll(vObj.FirstName));
	If Not ValueIsFilled(vObj.Sex) Then
		vObj.Sex = fmGetSexByName(vObj);
	EndIf;
EndProcedure // FirstNameOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SecondNameOnChangeAtServer(pObj = Undefined)
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	vObj.SecondName = Title(TrimAll(vObj.SecondName));
	If Not ValueIsFilled(vObj.Sex) Then
		vObj.Sex = fmGetSexByName(vObj);
	EndIf;
EndProcedure // SecondNameOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure CitizenshipOnChangeAtServer(pObj = Undefined)
	// Check parameters
	vUseParameterObject = True;
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;	
	vObj.pmFillIdentityDocumentType();
	// Fill default language
	If ValueIsFilled(vObj.Citizenship) Then
		If ValueIsFilled(vObj.Citizenship.Language) Then
			vObj.Language = vObj.Citizenship.Language;
		EndIf;
	EndIf;
	If vUseParameterObject = False Then
		// Set object value
		ValueToFormAttribute(vObj, "Object");
	EndIf;
	// SNILS
	If ValueIsFilled(Object.Citizenship) And Object.Citizenship.Code = 643 Then
		Items.SocialSecurityNumber.Mask = "999-999-999 99";
	EndIf;
EndProcedure // CitizenshipOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadDefaultChargingRulesAtServer(pObj = Undefined)
	// Check parameters
	vUseParameterObject = True;
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;
	vHotel = SessionParameters.CurrentHotel;
	If ValueIsFilled(vHotel) Then
		vObj.ChargingRules.Clear();
		vObj.pmCreateFolios(vHotel, CurrentSessionDate());
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Default hotel is not filled!';ru='Не выбрана гостиница по умолчанию!';de='Kein Hotel als Standard-Einstellung ist gewählt!'"));
	EndIf;
	If vUseParameterObject = False Then
		// Set object value
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // LoadDefaultChargingRulesAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetFullName()
	// Get object value
	vObj = FormAttributeToValue("Object");
	vFullName = vObj.pmGetFullName();
	Return vFullName;
EndFunction // GetFullName

// -----------------------------------------------------------------------------
&AtServer
Function CheckPermissionsAtServer(pCancel, pWriteParameters)
	vMessage = "";
	// Check client data
	If Not cmCheckUserPermissions("HavePermissionToDoCheckInWithEmptyGuest") Then
		If Not ValueIsFilled(Object.Sex) Then
			pCancel = True;
			vMessage = NStr("en='Please fill client sex!';ru='Пожалуйста, укажите пол клиента!';de='Bitte geben Sie das Geschlecht des Kunden an!'");
			CurrentItem = Items.Sex;
			Return vMessage;
		EndIf;
		If Not ValueIsFilled(Object.Citizenship) Then
			pCancel = True;
			vMessage = NStr("en='Please fill client citizenship!';ru='Пожалуйста, укажите страну гражданства клиента!';de='Bitte geben Sie das Land des Kunden an!'");
			CurrentItem = Items.Citizenship;
			Return vMessage;
		EndIf;
		If Not cmCheckUserPermissions("HavePermissionToSkipInputOfGuestIdentificationDocumentData") Then
			If IsBlankString(Object.IdentityDocumentNumber) Then
				pCancel = True;
				vMessage = NStr("en='Please fill client identity document data!';ru='Пожалуйста, укажите данные документа удостоверяющего личность клиента!';de='Bitte geben Sie die Personalausweisdaten des Kunden an!'");
				CurrentItem = Items.IdentityDocumentNumber;
				Return vMessage;
			Else
				If ValueIsFilled(Object.IdentityDocumentType) And TrimAll(Object.IdentityDocumentType.Code) = "21" Then
					If Not IsBlankString(Object.IdentityDocumentSeries) Then
						vIdentityDocumentSeries = StrReplace(TrimAll(Object.IdentityDocumentSeries), " ", "");
						If StrLen(vIdentityDocumentSeries) <> 4 Then
							pCancel = True;
							vMessage = NStr("en='Client identity document series amount of digits should be equal to 4!';ru='Количество цифр в серии паспорта должно быть равно 4!';de='Anzahl von Zahlen in der Passserie muss gleich 4 sein!'");
							CurrentItem = Items.IdentityDocumentSeries;
							Return vMessage;
						EndIf;
						If Not cmIsNumber(vIdentityDocumentSeries) Then
							pCancel = True;
							vMessage = NStr("en='Digits are allowed for client identity document series only!';ru='В серии паспорта разрешены только цифры!';de='In der Passseriennummer sind nur Zahlen erlaubt!'");
							CurrentItem = Items.IdentityDocumentSeries;
							Return vMessage;
						EndIf;
					EndIf;
					If Not IsBlankString(Object.IdentityDocumentNumber) Then
						vIdentityDocumentNumber = TrimAll(Object.IdentityDocumentNumber);
						If StrLen(vIdentityDocumentNumber) <> 6 Then
							pCancel = True;
							vMessage = NStr("en='Client identity document number amount of digits should be equal to 6!';ru='Количество цифр в номере паспорта должно быть равно 6!';de='Anzahl von Zahlen in der Passnummer muss gleich 6 sein!'");
							CurrentItem = Items.IdentityDocumentNumber;
							Return vMessage;
						EndIf;
						If Not cmIsNumber(vIdentityDocumentNumber) Then
							pCancel = True;
							vMessage = NStr("en='Digits are allowed for client identity document number only!';ru='В номере паспорта разрешены только цифры!';de='In der Passnummer sind nur Zahlen erlaubt!'");
							CurrentItem = Items.IdentityDocumentNumber;
							Return vMessage;
						EndIf;
					EndIf;
					If IsBlankString(Object.IdentityDocumentSeries) Then
						pCancel = True;
						vMessage = NStr("en='Client identity document series is missing!';ru='Номер паспорта указан без серии!';de='Die Passnummer ist ohne Seriennummer angegeben!'");
						CurrentItem = Items.IdentityDocumentSeries;
						Return vMessage;
					EndIf;
					If IsBlankString(Object.IdentityDocumentUnitCode) Then
						pCancel = True;
						vMessage = NStr("en='Client identity document unit code is missing!';ru='Не указан код подразделения кем выдан паспорт!';de='Des Ausweises ist ohne Unterteilung Code angegeben!'");
						CurrentItem = Items.IdentityDocumentUnitCode;
						Return vMessage;
					EndIf;
					If IsBlankString(Object.IdentityDocumentIssuedBy) Then
						pCancel = True;
						vMessage = NStr("en='Client identity document issued by is missing!';ru='Не указано кем выдан паспорт!';de='Des Ausweises ist ohne Ausgestellt durch angegeben!'");
						CurrentItem = Items.IdentityDocumentIssuedBy;
						Return vMessage;
					EndIf;
				EndIf;
			EndIf;
			If ValueIsFilled(Object.IdentityDocumentIssueDate) And ValueIsFilled(Object.IdentityDocumentValidToDate) And BegOfDay(Object.IdentityDocumentValidToDate) < BegOfDay(Object.IdentityDocumentIssueDate) Then
				pCancel = True;
				vMessage = NStr("en='Client identity document valid to date is less the document issue date!';ru='Дата окончания периода действия документа удостоверяющего личность указана ранее даты его выдачи!';de='Enddatum des Personalausweises angegeben früher als das Datum der Ausstellung!'");
				CurrentItem = Items.IdentityDocumentValidToDate;
				Return vMessage;
			EndIf;
		EndIf;
		If Not cmCheckUserPermissions("HavePermissionToSkipInputOfGuestAddress") Then
			If ValueIsFilled(SessionParameters.CurrentHotel) Then
				If Object.Citizenship = SessionParameters.CurrentHotel.Citizenship Then
					If IsBlankString(Object.Address) Then
						pCancel = True;
						vMessage = NStr("en='Please fill client address!';ru='Пожалуйста, укажите адрес прописки клиента!';de='Bitte geben Sie die Meldeanschrift des Kunden an!'");
						CurrentItem = Items.Address;
						Return vMessage;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	Return vMessage;
EndFunction // CheckPermissionsAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillTasksPresentation()
	TTasks = "";
	If ValueIsFilled(Object.Ref) Then
		vTasks = cmGetMessagesForObject(Object.Ref);
		For Each vTasksRow In vTasks Do
			TTasks = TTasks + "• " + TrimAll(vTasksRow.Remarks) + Chars.LF;
			If vTasks.IndexOf(vTasksRow) > 4 Then
				TTasks = TTasks + "• " + "..." + Chars.LF;
				Break;
			EndIf;
		EndDo;
	EndIf;
	TTasks = TrimAll(TTasks);
	Items.DecorationTasks.Title = TTasks;
	If IsBlankString(TTasks) Then
		Items.DecorationTasks.Visible = False;
	Else
		Items.DecorationTasks.Visible = True;
	EndIf;
EndProcedure // FillTasksPresentation

// -----------------------------------------------------------------------------
&AtClient
Procedure Task()
	stParam = New Structure("SetParamObject", Object.Ref);
	OpenForm("DataProcessor.Messages.Form.tcForm", stParam);
	Notify("DataProcessor.Messages.Form.Open", stParam);
EndProcedure // Task

// -----------------------------------------------------------------------------
&AtServer
Procedure FillRelationshipsListAtServer()
	Items.Relationship.ChoiceList.Add(NStr("en='Wife'; ru='Жена'; de='Ehefrau'"));
	Items.Relationship.ChoiceList.Add(NStr("en='Husband'; ru='Муж'; de='Ehemann'"));
	Items.Relationship.ChoiceList.Add(NStr("en='Daughter'; ru='Дочь'; de='Tochter'"));
	Items.Relationship.ChoiceList.Add(NStr("en='Son'; ru='Сын'; de='Sohn'"));
	Items.Relationship.ChoiceList.Add(NStr("en='Mother'; ru='Мать'; de='Mutter'"));
	Items.Relationship.ChoiceList.Add(NStr("en='Father'; ru='Отец'; de='Vater'"));
	Items.Relationship.ChoiceList.Add(NStr("en='Grandmother'; ru='Бабушка'; de='Großmutter'"));
	Items.Relationship.ChoiceList.Add(NStr("en='Grandfather'; ru='Дедушка'; de='Großvater'"));
	Items.Relationship.ChoiceList.Add(NStr("en='Other degree of kinship (adults)'; ru='Другая степень родства (взрослые)'; de='Ander Verwandtschaft-typ (die Erwachsenen)'"));
	Items.Relationship.ChoiceList.Add(NStr("en='Other degree of kinship (children)'; ru='Другая степень родства (дети)'; de='Ander Verwandtschaft-typ (Kinder)'"));
EndProcedure // FillRelationshipsListAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillFanIDData()
	// Fan id
	vRcdMgr = InformationRegisters.LimitsAndSpecialConditions.CreateRecordManager();
	vRcdMgr.Owner = Object.Ref;
	vRcdMgr.Characteristic = ChartsOfCharacteristicTypes.LimitsAndSpecialConditionTypes.FindByAttribute("XMLElementName", "fan_id");
	If ValueIsFilled(vRcdMgr.Characteristic) Then
		vRcdMgr.Read();
		If vRcdMgr.Selected() Then
			FanID = TrimAll(vRcdMgr.CharacteristicValue);
		EndIf;
	EndIf;
	// Fan id number
	vRcdMgr = InformationRegisters.LimitsAndSpecialConditions.CreateRecordManager();
	vRcdMgr.Owner = Object.Ref;
	vRcdMgr.Characteristic = ChartsOfCharacteristicTypes.LimitsAndSpecialConditionTypes.FindByAttribute("XMLElementName", "fan_id_number");
	If ValueIsFilled(vRcdMgr.Characteristic) Then
		vRcdMgr.Read();
		If vRcdMgr.Selected() Then
			FanIDNumber = TrimAll(vRcdMgr.CharacteristicValue);
		EndIf;
	EndIf;
EndProcedure // FillFanIDData

// -----------------------------------------------------------------------------
&AtServer
Function GetRoomPropertiesValueList(pObj = Undefined)
	vObj = Object;
	If pObj <> Undefined Then
		vObj = pObj;
	EndIf;
	vValueList = New ValueList();
	vValueList.LoadValues(vObj.RoomProperties.Unload().UnloadColumn("RoomProperty"));
	Return vValueList;
EndFunction // GetRoomPropertiesValueList

// -----------------------------------------------------------------------------
&AtServer
Function GetRoomPropertiesPresentation()
	// Room properties
	vRPPresentation = "";
	For Each vRPItem In RoomProperties Do
		If ValueIsFilled(vRPItem.Value) Then
			If IsBlankString(vRPPresentation) Then
				vRPPresentation = TrimAll(vRPItem.Value.Description);
			Else
				vRPPresentation = vRPPresentation + ", " + TrimAll(vRPItem.Value.Description);
			EndIf;
		EndIf;
	EndDo;
	Return vRPPresentation;
EndFunction // GetRoomPropertiesPresentation

// -----------------------------------------------------------------------------
&AtServer
Function FillRoomPropertiesList()
	// Get all service packages available for use
	vRoomPropertiesList = cmGetAllRoomProperties(Undefined, Catalogs.Hotels.EmptyRef());
	// Check service packages already being selected
	For Each vRP In RoomProperties Do
		If ValueIsFilled(vRP.Value) Then
			vRPItem = vRoomPropertiesList.FindByValue(vRP.Value);
			If vRPItem <> Undefined Then
				vRPItem.Check = True;
			EndIf;
		EndIf;
	EndDo;
	Return vRoomPropertiesList;
EndFunction // FillRoomPropertiesList

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveRoomPropertiesList(pRoomPropertiesList)
	If RoomProperties.Count() > 0 Then
		RoomProperties.Clear();
	EndIf;
	If pRoomPropertiesList.Count() > 0 Then
		For Each vRPItem In pRoomPropertiesList Do
			If vRPItem.Check Then
				RoomProperties.Add(vRPItem.Value);
			EndIf;
		EndDo;
	EndIf;
EndProcedure // SaveRoomPropertiesList

// -----------------------------------------------------------------------------
&AtServer
Procedure FillDocumentRoomProperties()
	Object.RoomProperties.Clear();
	For Each vRoomPropertiesItem In RoomProperties Do
		vRoomPropertiesRow = Object.RoomProperties.Add();
		vRoomPropertiesRow.RoomProperty = vRoomPropertiesItem.Value;
	EndDo;
EndProcedure // FillDocumentRoomProperties

// -----------------------------------------------------------------------------
&AtClient
Procedure IdentityDocumentIssuedByIsChoosen(pValue, pAdditionalParameters) Export
	If pValue <> Undefined Then
		Object.IdentityDocumentIssuedBy = pValue.Value;
		vPresentation = pValue.Presentation;
		If Left(vPresentation, StrLen(TrimAll(Object.IdentityDocumentUnitCode))) = TrimAll(Object.IdentityDocumentUnitCode) Then
			Object.IdentityDocumentUnitCode = Left(vPresentation, 7);
		EndIf;
	EndIf;
EndProcedure // IdentityDocumentIssuedByIsChoosen

// -----------------------------------------------------------------------------
&AtServer
Function GetIssuedByListAtServer(pText, pIsUnitCode = True)
	vIssuedByList = New ValueList();
	If Left(InfoBaseConnectionString(), 5) = "File=" Then
		Return vIssuedByList;
	EndIf;
	If ValueIsFilled(Object.IdentityDocumentType) And TrimAll(Object.IdentityDocumentType.Code) = "21" Then
		If StrLen(TrimAll(pText)) < 3 Then
			Return vIssuedByList;
		EndIf;
		If pIsUnitCode Then
			vQryRes = cmGetFMSRecord(TrimAll(pText), True, , 15).Choose();
		Else
			vQryRes = cmGetFMSRecord(TrimAll(pText), False).Choose();
		EndIf;
	Else
		If StrLen(TrimAll(pText)) < 5 Then
			Return vIssuedByList;
		EndIf;
		If pIsUnitCode Then
			vQryRes = cmGetIssuedByRecord(TrimAll(pText), True).Choose();
		Else
			vQryRes = cmGetIssuedByRecord(TrimAll(pText), False).Choose();
		EndIf;
	EndIf;
	While vQryRes.Next() Do
		vIssuedByList.Add(TrimAll(vQryRes.Description), TrimAll(?(IsBlankString(vQryRes.Code), "", TrimAll(vQryRes.Code) + ", ") + TrimAll(vQryRes.Description)));
	EndDo;
	Return vIssuedByList;
EndFunction // GetIssuedByListAtServer

// -----------------------------------------------------------------------------
&AtServer
Function CheckIdentityDocumentAtServer()
	vMessage = "";
	// Check client identity document in the list of forbidden identity documents
	vIDRemarks = "";
	If cmIsClientIdentityDocumentInForbiddenList(Object.IdentityDocumentType, Object.IdentityDocumentSeries, Object.IdentityDocumentNumber, vIDRemarks) Then
		vMessage = GetFullName() + Chars.LF + NStr("en='Client identity document data found in the forbidden list!';ru='ДУЛ клиента найден в запрещенном списке!';de='PA des Kunden wurde in der Sperrliste gefunden!'") + Chars.LF + vIDRemarks;
	EndIf;
	Return vMessage;
EndFunction // CheckIdentityDocumentAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FanIDOnChangeAtServer()
	If ValueIsFilled(Object.Ref) Then
		vRcdMgr = InformationRegisters.LimitsAndSpecialConditions.CreateRecordManager();
		vRcdMgr.Characteristic = ChartsOfCharacteristicTypes.LimitsAndSpecialConditionTypes.FindByAttribute("XMLElementName", "fan_id");
		If ValueIsFilled(vRcdMgr.Characteristic) Then
			vRcdMgr.CharacteristicValue = TrimAll(FanID);
			vRcdMgr.Owner = Object.Ref;
			vRcdMgr.Write(True);
		EndIf;
	EndIf;
EndProcedure // FanIDOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FanIDNumberOnChangeAtServer()
	If ValueIsFilled(Object.Ref) Then
		vRcdMgr = InformationRegisters.LimitsAndSpecialConditions.CreateRecordManager();
		vRcdMgr.Characteristic = ChartsOfCharacteristicTypes.LimitsAndSpecialConditionTypes.FindByAttribute("XMLElementName", "fan_id_number");
		If ValueIsFilled(vRcdMgr.Characteristic) Then
			vRcdMgr.CharacteristicValue = TrimAll(FanIDNumber);
			vRcdMgr.Owner = Object.Ref;
			vRcdMgr.Write(True);
		EndIf;
	EndIf;
EndProcedure // FanIDNumberOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure DecorationPlaceOfBirthValueClickEnd(pResult, pAdditionalParameters) Export
	If Not pResult = Undefined Then
		Object.PlaceOfBirth = pResult.Address;
		FillPresentation();
		PlaceOfBirthOnChangeAtServer();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillPresentation()
	If Not IsBlankString(Object.PlaceOfBirth) Then
		Items.DecorationPlaceOfBirthValue.Title = TrimAll(Object.PlaceOfBirth);
	Else 
		Items.DecorationPlaceOfBirthValue.Title = NStr("en = 'Fill'; ru = 'Заполнить'; de = 'Füllen'");
	EndIf;
	
	If Not IsBlankString(Object.Address) Then
		Items.DecorationAddressValue.Title = TrimAll(Object.Address);
	Else 
		Items.DecorationAddressValue.Title = NStr("en = 'Fill'; ru = 'Заполнить'; de = 'Füllen'");
	EndIf;

	If Not IsBlankString(Object.PostalAddress) Then
		Items.DecorationPostalAddressValue.Title = TrimAll(Object.PostalAddress);
	Else 
		Items.DecorationPostalAddressValue.Title = NStr("en = 'Fill'; ru = 'Заполнить'; de = 'Füllen'");
	EndIf;
	Items.AdditionalInfo.CollapsedRepresentationTitle = NStr("en='Additional info';ru='Доп. информация';de='Zusätzliche Information'") + 
	                                                     ?(ValueIsFilled(Object.PersonalNumber), " • " + NStr("en='Personal number: ';ru='Личный номер: ';de='Persönliche Nummer: '") + TrimAll(Object.PersonalNumber), "") + 
														 ?(ValueIsFilled(Object.PolicyOfMedicalInsurance), " • " + NStr("en='Policy N: ';ru='Полис №: ';de='Policy N: '") + TrimAll(Object.PolicyOfMedicalInsurance), "") + 
														 ?(ValueIsFilled(Object.AmbulatoryCard), " • " + NStr("en='Ambulatory card: ';ru='Амбулаторная карта: ';de='Patientenkarte: '") + TrimAll(Object.AmbulatoryCard), "") +  
														 ?(ValueIsFilled(FanID), " • " + NStr("en='Fan ID: ';ru='Fan ID: ';de='Fan ID: '") + TrimAll(FanID), "") +
														 ?(ValueIsFilled(FanIDNumber), " • " + NStr("en='Fan ID Nummer: ';ru='№ бланка: ';de='Fan ID Nummer: '") + TrimAll(FanIDNumber), "") +
														 ?(ValueIsFilled(Object.Relationship), " • " + NStr("en='Relationship: ';ru='Степень родства: ';de='Verwandtschaft: '") + TrimAll(Object.Relationship), "") +
														 ?(ValueIsFilled(Object.Children), " • " + NStr("en='Children: ';ru='Дети: ';de='Kinder: '") + TrimAll(Object.Children), "") +
														 ?(ValueIsFilled(Object.Parents), " • " + NStr("en='Parents: ';ru='Родители: ';de='Eltern: '") + TrimAll(Object.Parents), "") +
														 ?(ValueIsFilled(Object.Disablement), " • " + NStr("en='Disablement: ';ru='Инвалидность: ';de='Behinderung: '") + TrimAll(Object.Disablement), "") +
														 ?(ValueIsFilled(Object.PlaceOfEmployment), " • " + NStr("en='Place of employment: ';ru='Место работы: ';de='Arbeitsort: '") + TrimAll(Object.PlaceOfEmployment), "") +
														 ?(ValueIsFilled(Object.Position), " • " + NStr("en='Position: ';ru='Должность: ';de='Position: '") + TrimAll(Object.Position), "") +
														 ?(ValueIsFilled(Object.Certificate), " • " + NStr("en='Certificate: ';ru='Удостоверение: ';de='Bescheinigung: '") + TrimAll(Object.Certificate), "");
EndProcedure // FillPresentation

// -----------------------------------------------------------------------------
&AtClient
Procedure DecorationAddressValueClickEnd(pResult, pAdditionalParameters) Export
	If Not pResult = Undefined Then
		Object.Address = pResult.Address;   
		Object.StreetFiasId = pResult.StreetFiasId;
		FillPresentation();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DecorationPostalAddressValueClickEnd(pResult, pAdditionalParameters) Export
	If Not pResult = Undefined Then
		Object.PostalAddress = pResult.Address;
		FillPresentation();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure LoadPhotoFromFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		OpenPhotoFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension is being installing on your browser...'; ru='В браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"), MessageStatus.Information);
		BeginInstallFileSystemExtension(New NotifyDescription("LoadPhotoFromFileFileSystemExtensionInstallCompleted", ThisObject));
	EndIf;
EndProcedure // LoadPhotoFromFileAttachingFileSystemExtensionResult

// -----------------------------------------------------------------------------
&AtClient
Procedure LoadPhotoFromFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadPhotoFromFileInstallingFileSystemExtensionResult", ThisObject));
EndProcedure // LoadPhotoFromFileFileSystemExtensionInstallCompleted

// -----------------------------------------------------------------------------
&AtClient
Procedure LoadPhotoFromFileInstallingFileSystemExtensionResult(pResult, pParam) Export 
	If pResult Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='В браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"), MessageStatus.Information);
		OpenPhotoFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"), MessageStatus.Attention);
	EndIf;
EndProcedure // LoadPhotoFromFileInstallingFileSystemExtensionResult

// -----------------------------------------------------------------------------
&AtClient 
Procedure OpenPhotoFileDialogToChooseFile()
	vFileOpen = New FileDialog(FileDialogMode.Open);
	vFileOpen.FullFileName = "";
	vFileOpen.Filter = NStr("ru = 'Картинки (*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf)|*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf|" +
	"bmp (*.bmp;*.dib;*.rle)|*.bmp;*.dib;*.rle|" + 
	"JPEG (*.jpg;*.jpeg)|*.jpg;*.jpeg|" + 
	"TIFF (*.tif)|*.tif|" + 
	"GIF (*.gif)|*.gif|" + 
	"PNG (*.png)|*.png|" + 
	"icon (*.ico)|*.ico|" + 
	"метафайл (*.wmf;*.emf)|*.wmf;*.emf|'; 
	|de = 'Картинки (*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf)|*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf|" +
	"bmp (*.bmp;*.dib;*.rle)|*.bmp;*.dib;*.rle|" + 
	"JPEG (*.jpg;*.jpeg)|*.jpg;*.jpeg|" + 
	"TIFF (*.tif)|*.tif|" + 
	"GIF (*.gif)|*.gif|" + 
	"PNG (*.png)|*.png|" + 
	"icon (*.ico)|*.ico|" + 
	"метафайл (*.wmf;*.emf)|*.wmf;*.emf|'; 
	|en = 'Pictures (*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf)|*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf|" +
	"bmp (*.bmp;*.dib;*.rle)|*.bmp;*.dib;*.rle|" + 
	"JPEG (*.jpg;*.jpeg)|*.jpg;*.jpeg|" + 
	"TIFF (*.tif)|*.tif|" + 
	"GIF (*.gif)|*.gif|" + 
	"PNG (*.png)|*.png|" + 
	"icon (*.ico)|*.ico|" + 
	"metafile (*.wmf;*.emf)|*.wmf;*.emf|'");
	vFileOpen.Multiselect = False;
	vFileOpen.Title = NStr("en='Open picture';ru='Открыть картинку';de='Bild öffnen'");
	vFileOpen.Preview = True;
	vFileOpen.Show(New NotifyDescription("CommandActionLoadPhotoFromFileNotification", ThisObject));
EndProcedure // OpenPhotoFileDialogToChooseFile
	
// -----------------------------------------------------------------------------
&AtClient
Procedure CommandActionLoadPhotoFromFileNotification(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		vFullFileName = pFileArray[0];
		vFile = New File(vFullFileName);
		vFile.BeginGettingModificationTime(New NotifyDescription("LoadPhotoFileGettingModificationTimeCompleted", ThisObject, New Structure("FileName, FullFileName", vFile.Name, vFullFileName)));
	EndIf;
EndProcedure // CommandActionLoadPhotoFromFileNotification

// -----------------------------------------------------------------------------
&AtClient
Procedure LoadPhotoFileGettingModificationTimeCompleted(pModificationTime, pParams) Export
	LoadPhotoFileInWebClient(pParams.FullFileName, New Structure("Name, LastModificationTime", pParams.FileName, pModificationTime));
EndProcedure // LoadPhotoFileGettingModificationTimeCompleted

// -----------------------------------------------------------------------------
&AtClient
Procedure LoadPhotoFileInWebClient(pFullFileName, pFile)
	vFilesArray = New Array();
	vFileDescription = New TransferableFileDescription(pFullFileName);
	vFilesArray.Add(vFileDescription);
	BeginPuttingFiles(New NotifyDescription("PhotoFileDownloadToServerCompleted", ThisObject, pFile), vFilesArray, , False);
EndProcedure // LoadPhotoFileInWebClient

// -----------------------------------------------------------------------------
&AtServer
Procedure PhotoFileDownloadToServerCompletedAtServer(pTransferredFiles)
	vFileAddress = pTransferredFiles.Get(0).Location;
	vBinaryData = GetFromTempStorage(vFileAddress);
	LoadPhotoFromFileAtServer(vBinaryData);
EndProcedure // PhotoFileDownloadToServerCompletedAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure PhotoFileDownloadToServerCompleted(pTransferredFiles, pFile) Export
	PhotoFileDownloadToServerCompletedAtServer(pTransferredFiles);
	ShowUserNotification(NStr("en = 'Photo added'; de = 'Foto Hinzugefügt'; ru = 'Фотография добавлена'"), , , , UserNotificationStatus.Information, NotificationUUID);
EndProcedure // PhotoFileDownloadToServerCompleted

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadPhotoFromFileAtServer(pBinaryData) 
	vObj = FormAttributeToValue("Object");
	vPhotoPicture = New Picture(pBinaryData);
	vObj.Photo = New ValueStorage(vPhotoPicture);
	vObj.Write();
	vObj.pmWriteToClientChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
	ValueToFormAttribute(vObj, "Object");
	ClientPhoto = PutToTempStorage(vPhotoPicture, UUID);
	Modified = False;
EndProcedure // LoadPhotoFromFileAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ClearPhotoAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.Photo = Undefined;
	vObj.Write();
	vObj.pmWriteToClientChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
	ValueToFormAttribute(vObj, "Object");
	ClientPhoto = "";
	Modified = False;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure LoadSignatureFromFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		OpenSignatureFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension is being installing on your browser...'; ru='В браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"), MessageStatus.Information);
		BeginInstallFileSystemExtension(New NotifyDescription("LoadSignatureFromFileFileSystemExtensionInstallCompleted", ThisObject));
	EndIf;
EndProcedure // LoadSignatureFromFileAttachingFileSystemExtensionResult

// -----------------------------------------------------------------------------
&AtClient
Procedure LoadSignatureFromFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadSignatureFromFileInstallingFileSystemExtensionResult", ThisObject));
EndProcedure // LoadSignatureFromFileFileSystemExtensionInstallCompleted

// -----------------------------------------------------------------------------
&AtClient
Procedure LoadSignatureFromFileInstallingFileSystemExtensionResult(pResult, pParam) Export 
	If pResult Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='В браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"), MessageStatus.Information);
		OpenSignatureFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"), MessageStatus.Attention);
	EndIf;
EndProcedure // LoadSignatureFromFileInstallingFileSystemExtensionResult

// -----------------------------------------------------------------------------
&AtClient 
Procedure OpenSignatureFileDialogToChooseFile()
	vFileOpen = New FileDialog(FileDialogMode.Open);
	vFileOpen.FullFileName = "";
	vFileOpen.Filter = NStr("ru = 'Картинки (*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf)|*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf|" +
	"bmp (*.bmp;*.dib;*.rle)|*.bmp;*.dib;*.rle|" + 
	"JPEG (*.jpg;*.jpeg)|*.jpg;*.jpeg|" + 
	"TIFF (*.tif)|*.tif|" + 
	"GIF (*.gif)|*.gif|" + 
	"PNG (*.png)|*.png|" + 
	"icon (*.ico)|*.ico|" + 
	"метафайл (*.wmf;*.emf)|*.wmf;*.emf|'; 
	|de = 'Картинки (*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf)|*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf|" +
	"bmp (*.bmp;*.dib;*.rle)|*.bmp;*.dib;*.rle|" + 
	"JPEG (*.jpg;*.jpeg)|*.jpg;*.jpeg|" + 
	"TIFF (*.tif)|*.tif|" + 
	"GIF (*.gif)|*.gif|" + 
	"PNG (*.png)|*.png|" + 
	"icon (*.ico)|*.ico|" + 
	"метафайл (*.wmf;*.emf)|*.wmf;*.emf|'; 
	|en = 'Pictures (*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf)|*.bmp;*.dib;*.rle;*.jpg;*.jpeg;*.tif;*.gif;*.png;*.ico;*.wmf;*.emf|" +
	"bmp (*.bmp;*.dib;*.rle)|*.bmp;*.dib;*.rle|" + 
	"JPEG (*.jpg;*.jpeg)|*.jpg;*.jpeg|" + 
	"TIFF (*.tif)|*.tif|" + 
	"GIF (*.gif)|*.gif|" + 
	"PNG (*.png)|*.png|" + 
	"icon (*.ico)|*.ico|" + 
	"metafile (*.wmf;*.emf)|*.wmf;*.emf|'");
	vFileOpen.Multiselect = False;
	vFileOpen.Title = NStr("en='Open picture';ru='Открыть картинку';de='Bild öffnen'");
	vFileOpen.Preview = True;
	vFileOpen.Show(New NotifyDescription("CommandActionLoadSignatureFromFileNotification", ThisObject));
EndProcedure // OpenSignatureFileDialogToChooseFile
	
// -----------------------------------------------------------------------------
&AtClient
Procedure CommandActionLoadSignatureFromFileNotification(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		vFullFileName = pFileArray[0];
		vFile = New File(vFullFileName);
		vFile.BeginGettingModificationTime(New NotifyDescription("LoadSignatureFileGettingModificationTimeCompleted", ThisObject, New Structure("FileName, FullFileName", vFile.Name, vFullFileName)));
	EndIf;
EndProcedure // CommandActionLoadSignatureFromFileNotification

// -----------------------------------------------------------------------------
&AtClient
Procedure LoadSignatureFileGettingModificationTimeCompleted(pModificationTime, pParams) Export
	LoadSignatureFileInWebClient(pParams.FullFileName, New Structure("Name, LastModificationTime", pParams.FileName, pModificationTime));
EndProcedure // LoadSignatureFileGettingModificationTimeCompleted

// -----------------------------------------------------------------------------
&AtClient
Procedure LoadSignatureFileInWebClient(pFullFileName, pFile)
	vFilesArray = New Array();
	vFileDescription = New TransferableFileDescription(pFullFileName);
	vFilesArray.Add(vFileDescription);
	BeginPuttingFiles(New NotifyDescription("SignatureFileDownloadToServerCompleted", ThisObject, pFile), vFilesArray, , False);
EndProcedure // LoadSignatureFileInWebClient

// -----------------------------------------------------------------------------
&AtServer
Procedure SignatureFileDownloadToServerCompletedAtServer(pTransferredFiles)
	vFileAddress = pTransferredFiles.Get(0).Location;
	vBinaryData = GetFromTempStorage(vFileAddress);
	LoadSignatureFromFileAtServer(vBinaryData);
EndProcedure // SignatureFileDownloadToServerCompletedAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SignatureFileDownloadToServerCompleted(pTransferredFiles, pFile) Export
	SignatureFileDownloadToServerCompletedAtServer(pTransferredFiles);
EndProcedure // SignatureFileDownloadToServerCompleted

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadSignatureFromFileAtServer(pBinaryData) 
	vObj = FormAttributeToValue("Object");
	vSignaturePicture = New Picture(pBinaryData);
	vObj.Signature = New ValueStorage(vSignaturePicture);
	vObj.Write();
	vObj.pmWriteToClientChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
	ValueToFormAttribute(vObj, "Object");
	ClientSignature = PutToTempStorage(vSignaturePicture, UUID);
	Modified = False;
EndProcedure // LoadSignatureFromFileAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ClearSignatureAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.Signature = Undefined;
	vObj.Write();
	vObj.pmWriteToClientChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
	ValueToFormAttribute(vObj, "Object");
	ClientSignature = "";
	Modified = False;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure ClientTypeColorAtServer()
	If ValueIsFilled(Object.ClientType) Then
		vColor = Object.ClientType.Color.Get();
		If vColor = Undefined Then
			Items.ClientTypeConfText.BackColor = StyleColors.BackgroundColorImportant;
		Else
			Items.ClientTypeConfText.BackColor = vColor;
		EndIf;
	Else
		Items.ClientTypeConfText.BackColor = StyleColors.BackgroundColorImportant;		
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientTypeConfirmationTextChange()
	If ValueIsFilled(Object.ClientType) Then
		If tcOnServer.cmGetAttributeByRef(Object.ClientType, "AskForConfirmation") Then
			Object.ClientTypeConfirmationText = tcOnServer.cmGetAttributeByRef(Object.ClientType, "ConfirmationPattern");
			ShowInputString(New NotifyDescription("AfterClientTypeConfirmationTextChange", ThisObject), 
							Object.ClientTypeConfirmationText,
							NStr("ru='Заполните шаблон строки подтверждения!';
					        |de='Vorlage der Bestätigungszeile ausfüllen!';
	                        |en='Please fill confirmation text pattern!'"),
	                   		100, 
							False); 
		Else
			Object.ClientTypeConfirmationText = "";
			ClientTypeColorAtServer();
		EndIf;
	Else
		Object.ClientTypeConfirmationText = "";
		ClientTypeColorAtServer();
	EndIf;
EndProcedure // ClientTypeConfirmationTextChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterClientTypeConfirmationTextChange(pText, pExtraPerams) Export 
	If pText <> Undefined Then
		Object.ClientTypeConfirmationText = pText;
		If Upper(TrimAll(Object.ClientTypeConfirmationText)) = Upper(TrimAll(tcOnServer.cmGetAttributeByRef(Object.ClientType, "ConfirmationPattern"))) Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Строка подтверждения совпадает с шаблоном! Выбор типа клиента будет отменен.';
			                  |de='Zeile für die Bestätigung stimmt mit Vorlage überein! Die Auswahl des Kundentyps wird zurückgesetzt!'; 
			                  |en='Confirmation text is the same as confirmation pattern! Client type will be cleared.'"));
			Object.ClientType = PredefinedValue("Catalog.ClientTypes.EmptyRef");
			Object.ClientTypeConfirmationText = "";
		ElsIf IsBlankString(Object.ClientTypeConfirmationText) Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Строка подтверждения не введена! Выбор типа клиента будет отменен.';
			                  |de='Die Zeile für die Bestätigung wurde nicht eingefügt! Die Auswahl des Kundentyps wird zurückgesetzt.'; 
							  |en='Confirmation text is not entered! Client type will be cleared.'"));
			Object.ClientType = PredefinedValue("Catalog.ClientTypes.EmptyRef");
			Object.ClientTypeConfirmationText = "";	
		EndIf;
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Строка подтверждения не введена! Выбор типа клиента будет отменен.';
		                  |de='Die Zeile für die Bestätigung wurde nicht eingefügt! Die Auswahl des Kundentyps wird zurückgesetzt.'; 
						  |en='Confirmation text is not entered! Client type will be cleared.'"));
		Object.ClientType = PredefinedValue("Catalog.ClientTypes.EmptyRef");
		Object.ClientTypeConfirmationText = "";
	EndIf;
	ClientTypeColorAtServer();
EndProcedure // AfterClientTypeConfirmationTextChange

// -----------------------------------------------------------------------------
&AtServer
Procedure DiscountCardOnChangeAtServer()
	If ValueIsFilled(Object.DiscountCard) Then
		If ValueIsFilled(Object.DiscountCard.ClientType) Then
			Object.ClientType = Object.DiscountCard.ClientType;
			ClientTypeColorAtServer();
		EndIf;
	EndIf;
EndProcedure // DiscountCardOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SocialSecurityNumberOnChangeAtServer()
	If ValueIsFilled(Object.Citizenship) And Object.Citizenship.Code = 643 Then
		If Not IsBlankString(Object.SocialSecurityNumber) And Not cmCheckRussianSocialSecurityNumber(TrimR(Object.SocialSecurityNumber)) Then
			vUM = New UserMessage();
			vUM.SetData(FormAttributeToValue("Object"));
			vUM.Field = "SocialSecurityNumber";
			vUM.Text = NStr("en='Social security number id wrong!';ru='СНИЛС клиента указан с ошибкой!';de='Sozialversicherungsnummer ist falsch!'");
			vUM.Message();
		EndIf;
	EndIf;
EndProcedure // SocialSecurityNumberOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillClientTags()
	If Not Object.Ref.IsEmpty() Then
		vTags = GetTagList(Object.Ref);
		vNN = 1;
		For Each vTag In vTags Do
			vTitle 			= "#" + vTag.Description;
			vID 			= StrReplace(String(vTag.UUID()), "-", "_");
			vTagName 		= "Tag_" + vID;
			vItem 			= Items.Find("FormButton" + vTagName);
			vBackColor 		= tcCommonFunctionOnClientServer.cmGetColorFromValueStorage(vTag);
			If vBackColor = Undefined Then 
				vBackColor 	= tcCommonFunctionOnClientServer.ColorConstructor();
			EndIf;
			If vItem = Undefined Then
				vParentGroup = Undefined;
				While vParentGroup = Undefined Do
					vNameGroup = "TagRow_" + String(vNN);
					vParentGroup = Items.Find("FormGroup" + vNameGroup);
					If vParentGroup = Undefined Then
						vProperty = New Structure;
						vProperty.Insert("Type", FormGroupType.UsualGroup);
						vProperty.Insert("Title", "TagRow_" + vNN);
						vProperty.Insert("ShowTitle", False);
						vProperty.Insert("Group", ChildFormItemsGroup.AlwaysHorizontal);
						vParentGroup = tcOnServer.cmCreateItem(ThisObject, Items.GroupTagRows, vNameGroup, "FormGroup", vProperty);
					Else
						If vParentGroup.ChildItems.Count() = 6 Then  // CHECK MAX ITEMS
							vNN = vNN + 1;
							vParentGroup = Undefined;
							Continue;
						EndIf;	
					EndIf;
				EndDo;
				// Add item
				vCommand = Commands.Find("ClickTag");
				vParam = New Structure;
				vParam.Insert("Title", 			vTitle);
				vParam.Insert("CommandName", 	"ClickTag");
				vParam.Insert("Type", 			FormButtonType.Hyperlink);
				vParam.Insert("TextColor", 		tcCommonFunctionOnClientServer.ColorConstructor(128, 122, 89));
				vParam.Insert("BackColor", 		vBackColor);
				
				tcOnServer.cmCreateItem(ThisObject, vParentGroup, vTagName, "FormButton", vParam);
			Else
				// Update item
				vItem.Title 		= vTitle;
				vItem.Visible 		= True;
				vItem.BackColor = vBackColor;
			EndIf;
		EndDo;
	EndIf;
	Read();
EndProcedure // FillClientTags()

// -----------------------------------------------------------------------------
// Gets a list of tags by customer
//
// Parameters:
//  pClient  - Catalog.Clients - ref on client
//
&AtServerNoContext
Function GetTagList(pClient)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ClientTags.Tag AS Tag
	|FROM
	|	InformationRegister.ClientTags AS ClientTags
	|WHERE
	|	ClientTags.Client = &qClient
	|
	|GROUP BY
	|	ClientTags.Tag";
	vQry.SetParameter("qClient", pClient);
	vTags = vQry.Execute().Unload().UnloadColumn("Tag");
	Return vTags;
EndFunction //  GetTagList()

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure EnableTag(pClient, pTag)
	vRcdMgr = InformationRegisters.ClientTags.CreateRecordManager();
	vRcdMgr.Client = pClient;
	vRcdMgr.Tag = pTag;
	vRcdMgr.Read();
	If Not vRcdMgr.Selected() Then
		vRcdMgr.Client = pClient;
		vRcdMgr.Tag = pTag;
		vRcdMgr.Write(True);
	EndIf;
EndProcedure //  EnableTag() 

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure ExcludeTag(pClient, pTag)
	vRcdMgr = InformationRegisters.ClientTags.CreateRecordManager();
	vRcdMgr.Client = pClient;
	vRcdMgr.Tag = pTag;
	vRcdMgr.Read();
	If vRcdMgr.Selected() Then
		vRcdMgr.Delete();
	EndIf;
EndProcedure //  ExcludeTag() 

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ClickOnTagEnd(pQuestionResult, pAdditionalParameters) Export
	vTagItem = pAdditionalParameters.TagItem;
	vCurColor = pAdditionalParameters.CurrentColor;
	If Not pQuestionResult = Undefined Then
		vTag = GetTagByName(vTagItem.Name);
		If pQuestionResult.Value = "ChooseColor" Then
			// Choose color
			vColorDlg =  New ColorChooseDialog;
			vColorDlg.Color = vCurColor;
			vColorDlg.Show(New NotifyDescription("SetColorAfterUserChoice", ThisObject, pAdditionalParameters));
		ElsIf pQuestionResult.Value = "ClearColor" Then
			vColor = tcCommonFunctionOnClientServer.ColorConstructor();
			SaveColor(vColor, vTag);
			// Прыжок на месте, не обновляет цвет, пока видимость не изменится, возможно с каким-то 
			// релизом платформы станет неактуальным
			vTagItem.Visible = Not vTagItem.Visible;
			vTagItem.BackColor = vColor;
			vTagItem.Visible = Not vTagItem.Visible;
		ElsIf pQuestionResult.Value = "Delete" Then	
			// Delete tag 
			If Not vTag = Undefined Then
				ExcludeTag(Object.Ref, vTag);
				vTagItem.Visible = False;
				Read();
			Else
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Could not determine tag'; de = 'Tag konnte nicht ermittelt werden'; ru = 'Не удалось определить тег'"));
			EndIf;
		EndIf;	
	EndIf;	
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtServerNoContext
Function GetTagByName(pItemName)
	vTag = Undefined;
	vTagUUID = StrReplace(pItemName, "FormButtonTag_", "");
	vTagUUID = StrReplace(vTagUUID, "_", "-");
	If StrLen(vTagUUID) = 36 Then
		vTag = Catalogs.Tags.GetRef(New UUID(vTagUUID));
	EndIf;
	Return vTag;	
EndFunction	

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure SetColorAfterUserChoice(pColor, pExtraParams) Export
	If pColor <> Undefined Then
		If pColor.Type = ColorType.WebColor Or pColor.Type = ColorType.Absolute Then
			vTag = GetTagByName(pExtraParams.TagItem.Name);
			// Прыжок на месте, не обновляет цвет, пока видимость не изменится, 
			// возможно с каким то релизом платформы станет неактуальным
			pExtraParams.TagItem.Visible = Not pExtraParams.TagItem.Visible;
			pExtraParams.TagItem.BackColor = pColor;
			pExtraParams.TagItem.Visible = Not pExtraParams.TagItem.Visible;
			If Not vTag = Undefined Then
				SaveColor(pColor, vTag);
			Else
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Could not determine tag'; de = 'Tag konnte nicht ermittelt werden'; ru = 'Не удалось определить тег'"));
			EndIf;
		Else
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You can choose web or absolute colors only! Style and windows colors are not supported.';
									|ru='Можете выбирать только абсолютные цвета (по названию или по RGB)! Выбор цветов из стилей не поддерживается.';
									|de='Sie dürfen nur absolute Farben wählen (nach Bezeichnung oder nach RGB)! Die Farbenauswahl aus Stilen wird nicht unterstützt.'"));
		EndIf;
	EndIf;
EndProcedure // SetColorAfterUserChoice

// ------------------------------------------------------------------------------------------------
&AtServerNoContext
Procedure SaveColor(pColor, pTag)
	vTagObj	= pTag.GetObject();
	vTagObj.Color = New ValueStorage(pColor);
	vTagObj.Write();	
EndProcedure	

// -----------------------------------------------------------------------------
&AtServer
Function RightsToOpenTheDocument(pNameDoc)
	If Not AccessRight("View", Metadata.Documents[pNameDoc]) Then
		Return False;
	EndIf;
	Return True;
EndFunction

// ------------------------------------------------------------------------------------------------
&AtServerNoContext
Function GetClientDataScanDocument(pGuest)
	vDoc = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	ClientDataScans.Ref AS Ref
	|FROM
	|	Document.ClientDataScans AS ClientDataScans
	|WHERE
	|	ClientDataScans.Posted
	|	AND ClientDataScans.Guest = &qClient
	|
	|ORDER BY
	|	ClientDataScans.Date DESC";
	vQry.SetParameter("qClient", pGuest);
	vDocs = vQry.Execute().Unload();
	If vDocs.Count() > 0 Then
		vDoc = vDocs.Get(0).Ref;
	EndIf;
	Return vDoc;
EndFunction // GetClientDataScanDocument

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure SexOnChangeAtServer()
	If ValueIsFilled(Object.Sex) Then
		vSalutation = CachedCommonFunctions.cmGetSalutationBySex(Object.Sex);
		If ValueIsFilled(vSalutation) And vSalutation <> Object.Salutation Then
			Object.Salutation = vSalutation;
		EndIf;
	EndIf;
EndProcedure // SexOnChangeAtServer

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure SexOnChange(pItem)
	SexOnChangeAtServer();
EndProcedure // SexOnChange

#EndRegion
