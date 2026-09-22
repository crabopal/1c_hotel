// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("SelSMSDeliveryObject") Then
		CopyFormData(Parameters.SelSMSDeliveryObject, SelSMSDeliveryObject);
	EndIf;
	SelTags = cmGetAllTagsList();
	If SelTags.Count() = 0 Then
		Items.GroupTags.Visible = False;
	Else
		Items.GroupTags.Visible = True;
	EndIf;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure TagsStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	SelTags.ShowCheckItems(New NotifyDescription("CustomerTagsAfterBeingChecked", ThisForm), NStr("en='Check tags...'; ru='Отметьте теги...'; de='Tags Markierungen...'"));
EndProcedure // TagsStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure CustomerTagsAfterBeingChecked(pList, pExtraParams) Export 
	If pList <> Undefined Then	
		Tags.Clear();
		For Each vListItem In pList Do
			If vListItem.Check Then
				Tags.Add(vListItem.Value, vListItem.Presentation);
			EndIf;
		EndDo;	
	EndIf;
EndProcedure // CustomerTagsAfterBeingChecked

// -----------------------------------------------------------------------------
&AtClient
Procedure ButtonChoosePeriod(pCommand)
	vChoosePeriodDialog = New StandardPeriodEditDialog();
	vChoosePeriodDialog.Period.StartDate = SelPeriodFrom;
	vChoosePeriodDialog.Period.EndDate = SelPeriodTo;
	vChoosePeriodDialog.Period.Variant = StandardPeriodVariant.Custom;
	vChoosePeriodDialog.Show(New NotifyDescription("ChoosePeriodAfterChoice", ThisForm));
EndProcedure // ButtonChoosePeriod

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriodAfterChoice(pPeriod, pExtraParams) Export
	If pPeriod <> Undefined Then
		SelPeriodFrom = pPeriod.StartDate;
		SelPeriodTo = pPeriod.EndDate;
	EndIf;
EndProcedure // ChoosePeriodAfterChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionDoSearch(pCommand)
	If FormOwner <> Undefined Then
		// Save phones and e-mails already being used
		vUsedPhones = New ValueList();
		vUsedEMails = New ValueList();
		If Not SelClearReceivers Then
			For Each vRow In FormOwner.Object.Receivers Do
				If Not IsBlankString(vRow.Phone) Then
					vPhone = SMS.GetValidPhoneNumber(vRow.Phone);
					If vUsedPhones.FindByValue(TrimAll(vPhone)) = Undefined Then
						vUsedPhones.Add(TrimAll(vPhone));
					EndIf;
				EndIf;
				If Not IsBlankString(vRow.EMail) Then
					vEMail = lower(TrimAll(vRow.EMail));
					If vUsedEMails.FindByValue(vEMail) = Undefined Then
						vUsedEMails.Add(vEMail);
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		// Run query to get appropriate customers
		vNothingFound = ActionDoSearchAtServer(vUsedPhones, vUsedEMails);
		// Fill owner's list of receivers
		If SelClearReceivers Then
			FormOwner.Object.Receivers.Clear();
		EndIf;
		For Each vRcvRow In Receivers Do
			vRow = FormOwner.Object.Receivers.Add();
			FillPropertyValues(vRow, vRcvRow);
		EndDo;
		// Fill statistics
		FormOwner.fmRefreshStatistics();
		FormOwner.RefreshSMSTextAtChildForm();
		// Nothing found
		If vNothingFound Then
			ShowMessageBox(, NStr("en='No customers found according to your search conditions!';ru='Не найдено контрагентов удовлетворяющих указанным условиям отбора!';de='Vertragspartnern, die den angegebenen Auswahlkriterien entsprechen, wurden nicht gefunden!'"));
		Else
			// Close form
			ThisForm.Close();
		EndIf;
	Else
		// Close form
		ThisForm.Close();
	EndIf;
EndProcedure // ActionDoSearch

// -----------------------------------------------------------------------------
&AtServer
Function GetTemplateText(pLanguage = Undefined)
	If pLanguage = Undefined Then
		  vLanguage = SessionParameters.CurrentLanguage;
	Else
		 vLanguage = pLanguage; 
	EndIf;
	If vLanguage = Catalogs.Languages.RU Then
		Return SelSMSDeliveryObject.TemplateTextRu;	
	ElsIf vLanguage = Catalogs.Languages.EN Then
		Return SelSMSDeliveryObject.TemplateTextEn; 
	ElsIf vLanguage = Catalogs.Languages.DE Then
		Return SelSMSDeliveryObject.TemplateTextDe;
	EndIf;
EndFunction // GetTemplateText

// -----------------------------------------------------------------------------
&AtServer
Function ActionDoSearchAtServer(pUsedPhones, pUsedEMails)
	vNothingFound = True;
	// Clear receivers
	Receivers.Clear();
	// Get customers
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CustomerTags.Client AS Customer,
	|	COUNT(CustomerTags.Tag) AS TagsCount
	|INTO CustomersWithTags
	|FROM
	|	InformationRegister.ClientTags AS CustomerTags
	|WHERE
	|	CustomerTags.Tag IN(&qTagsList)
	|	AND NOT CustomerTags.Client.DeletionMark
	|	AND CustomerTags.Client.CreateDate >= &qPeriodFrom
	|	AND CustomerTags.Client.CreateDate <= &qPeriodTo
	|	AND CustomerTags.Client REFS Catalog.Customers
	|
	|GROUP BY
	|	CustomerTags.Client
	|
	|HAVING
	|	(NOT &qConditionAND
	|			AND COUNT(CustomerTags.Tag) > 0
	|		OR &qConditionAND
	|			AND COUNT(CustomerTags.Tag) = &qTagsCount)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Contracts.Owner AS Customer
	|INTO ActiveContractCustomers
	|FROM
	|	Catalog.Contracts AS Contracts
	|WHERE
	|	&qShowActiveOnly
	|	AND NOT Contracts.DeletionMark
	|	AND Contracts.ValidFromDate <= &qCurrentDate
	|	AND (Contracts.ValidToDate >= &qCurrentDate
	|			OR Contracts.ValidToDate = &qEmptyDate)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Customers.Ref AS Customer,
	|	Customers.Ref.Language AS Language,
	|	Customers.Phone AS Phone,
	|	Customers.EMail AS EMail,
	|	Customers.Description AS CustomerDescription
	|FROM
	|	Catalog.Customers AS Customers " + 
		?(Tags.Count() > 0, "INNER JOIN CustomersWithTags AS CustomersWithTags ON Customers.Ref = CustomersWithTags.Customer ", "") + "
	|WHERE
	|	NOT Customers.IsFolder
	|	AND NOT Customers.DeletionMark
	|	AND Customers.CreateDate >= &qPeriodFrom
	|	AND Customers.CreateDate <= &qPeriodTo
	|	AND (Customers.Phone <> &qEmptyString
	|				AND NOT &qCheckEMail
	|				AND NOT &qCheckBoth
	|			OR Customers.EMail <> &qEmptyString
	|				AND &qCheckEMail
	|				AND NOT &qCheckBoth
	|			OR &qCheckBoth
	|				AND (Customers.Phone <> &qEmptyString
	|					OR Customers.EMail <> &qEmptyString))
	|	AND (NOT &qCustomerIsEmpty
	|				AND Customers.Ref IN HIERARCHY (&qCustomer)
	|			OR &qCustomerIsEmpty)
	|	AND (NOT &qCustomerTypeIsEmpty
	|				AND Customers.CustomerType <> &qEmptyCustomerType
	|				AND Customers.CustomerType IN HIERARCHY (&qCustomerType)
	|			OR &qCustomerTypeIsEmpty)
	|	AND (NOT &qClientTypeIsEmpty
	|				AND Customers.ClientType <> &qEmptyClientType
	|				AND Customers.ClientType IN HIERARCHY (&qClientType)
	|			OR &qClientTypeIsEmpty)
	|	AND (NOT &qDiscountTypeIsEmpty
	|				AND Customers.DiscountType <> &qEmptyDiscountType
	|				AND Customers.DiscountType IN HIERARCHY (&qDiscountType)
	|			OR &qDiscountTypeIsEmpty)
	|	AND (NOT &qMarketingCodeIsEmpty
	|				AND Customers.MarketingCode <> &qEmptyMarketingCode
	|				AND Customers.MarketingCode IN HIERARCHY (&qMarketingCode)
	|			OR &qMarketingCodeIsEmpty)
	|	AND (NOT &qSourceOfBusinessIsEmpty
	|				AND Customers.SourceOfBusiness <> &qEmptySourceOfBusiness
	|				AND Customers.SourceOfBusiness IN HIERARCHY (&qSourceOfBusiness)
	|			OR &qSourceOfBusinessIsEmpty)
	|	AND (NOT &qRoomRateIsEmpty
	|				AND Customers.RoomRate <> &qEmptyRoomRate
	|				AND Customers.RoomRate IN HIERARCHY (&qRoomRate)
	|			OR &qRoomRateIsEmpty)
	|	AND (NOT &qRoomRateTypeIsEmpty
	|				AND NOT Customers.RoomRate.RoomRateType IS NULL
	|				AND Customers.RoomRate.RoomRateType <> &qEmptyRoomRateType
	|				AND Customers.RoomRate.RoomRateType IN HIERARCHY (&qRoomRateType)
	|			OR &qRoomRateTypeIsEmpty)
	|	AND (Customers.NonResident
	|				AND &qShowNonResident
	|			OR NOT Customers.NonResident
	|				AND &qShowResident
	|			OR NOT &qShowNonResident
	|				AND NOT &qShowResident)
	|	AND (NOT &qShowActiveOnly
	|			OR &qShowActiveOnly
	|				AND Customers.Ref IN
	|					(SELECT
	|						ActiveContractCustomers.Customer
	|					FROM
	|						ActiveContractCustomers))
	|
	|ORDER BY
	|	CustomerDescription";
	vQry.SetParameter("qPeriodFrom", BegOfDay(SelPeriodFrom));
	vQry.SetParameter("qPeriodTo", ?(ValueIsFilled(SelPeriodTo), EndOfDay(SelPeriodTo), '39991231235959'));
	vQry.SetParameter("qCustomer", SelCustomer);
	vQry.SetParameter("qCustomerIsEmpty", Not ValueIsFilled(SelCustomer));
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	vQry.SetParameter("qCustomerType", SelCustomerType);
	vQry.SetParameter("qCustomerTypeIsEmpty", Not ValueIsFilled(SelCustomerType));
	vQry.SetParameter("qEmptyCustomerType", Catalogs.CustomerTypes.EmptyRef());
	vQry.SetParameter("qClientType", SelClientType);
	vQry.SetParameter("qClientTypeIsEmpty", Not ValueIsFilled(SelClientType));
	vQry.SetParameter("qEmptyClientType", Catalogs.ClientTypes.EmptyRef());
	vQry.SetParameter("qDiscountType", SelDiscountType);
	vQry.SetParameter("qDiscountTypeIsEmpty", Not ValueIsFilled(SelDiscountType));
	vQry.SetParameter("qEmptyDiscountType", Catalogs.DiscountTypes.EmptyRef());
	vQry.SetParameter("qMarketingCode", SelMarketingCode);
	vQry.SetParameter("qMarketingCodeIsEmpty", Not ValueIsFilled(SelMarketingCode));
	vQry.SetParameter("qEmptyMarketingCode", Catalogs.MarketingCodes.EmptyRef());
	vQry.SetParameter("qSourceOfBusiness", SelSourceOfBusiness);
	vQry.SetParameter("qSourceOfBusinessIsEmpty", Not ValueIsFilled(SelSourceOfBusiness));
	vQry.SetParameter("qEmptySourceOfBusiness", Catalogs.SourcesOfBusiness.EmptyRef());
	vQry.SetParameter("qRoomRateType", SelRoomRateType);
	vQry.SetParameter("qRoomRateTypeIsEmpty", Not ValueIsFilled(SelRoomRateType));
	vQry.SetParameter("qEmptyRoomRateType", Catalogs.RoomRateTypes.EmptyRef());
	vQry.SetParameter("qRoomRate", SelRoomRate);
	vQry.SetParameter("qRoomRateIsEmpty", Not ValueIsFilled(SelRoomRate));
	vQry.SetParameter("qEmptyRoomRate", Catalogs.RoomRates.EmptyRef());
	vQry.SetParameter("qShowNonResident", SelNonResidentOnly);
	vQry.SetParameter("qShowResident", SelResidentOnly);
	vQry.SetParameter("qEmptyString", "");
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qCurrentDate", BegOfDay(CurrentSessionDate()));
	vQry.SetParameter("qCheckEMail", ?(SelSMSDeliveryObject.DeliveryType = Enums.DeliveryTypes.EMail, True, False));
	vQry.SetParameter("qCheckBoth", ?(SelSMSDeliveryObject.DeliveryType = Enums.DeliveryTypes.Unisender Or SelSMSDeliveryObject.DeliveryType = Enums.DeliveryTypes.Both Or SelSMSDeliveryObject.DeliveryType = Enums.DeliveryTypes.DoNotSend, True, False));
	vQry.SetParameter("qShowActiveOnly", SelWithActiveContractsOnly);
	vQry.SetParameter("qTagsList", Tags);
	vQry.SetParameter("qTagsCount", Tags.Count());
	vQry.SetParameter("qConditionAND", ChecksOrAndTags);
	SelCustomersArray.Load(vQry.Execute().Unload());
	For Each vCustomersRow In SelCustomersArray Do
		vPhone = SMS.GetValidPhoneNumber(vCustomersRow.Phone);
		vEMail = lower(TrimAll(vCustomersRow.EMail));
		// Check if current phone number or e-mail was already processed
		If (SelSMSDeliveryObject.DeliveryType = Enums.DeliveryTypes.EMail Or SelSMSDeliveryObject.DeliveryType = Enums.DeliveryTypes.Both Or SelSMSDeliveryObject.DeliveryType = Enums.DeliveryTypes.Unisender) And pUsedEMails.FindByValue(vEMail) = Undefined Or 
		   (SelSMSDeliveryObject.DeliveryType = Enums.DeliveryTypes.SMS Or SelSMSDeliveryObject.DeliveryType = Enums.DeliveryTypes.Both Or SelSMSDeliveryObject.DeliveryType = Enums.DeliveryTypes.Unisender) And pUsedPhones.FindByValue(vPhone) = Undefined Then
			If Not IsBlankString(vPhone) Then
				pUsedPhones.Add(vPhone);
			EndIf;
			If Not IsBlankString(vEMail) Then
				pUsedEMails.Add(vEMail);
			EndIf;
			vCustomer = vCustomersRow.Customer;
			vLanguage = vCustomersRow.Language;
			// Add new SMS message row
			vNothingFound = False;
			vRow = Receivers.Add();
			vRow.Phone = vPhone;
			vRow.EMail = vEMail;
			vRow.Customer = vCustomersRow.Customer;
			vRow.Client = Undefined;
			vRow.ClientDoc = Undefined;
			vRow.SMSText = SMS.ReplaceSMSParameters(GetTemplateText(vLanguage), , vCustomersRow.Customer, , , vLanguage);
			vRow.NumberOfSMS = Format(SMS.GetNumberOfSegments(vRow.SMSText), "ND=10; NFD=0; NG=");;
			vRow.MessageLength = Format(StrLen(vRow.SMSText), "ND=10; NFD=0; NG=");
			vRow.IsSent = False;
			vRow.Result = "";
			vRow.MessageID = "";
		EndIf;
	EndDo;
	Return vNothingFound;
EndFunction // ActionDoSearchAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionSaveSettings(Command)
	// Ask user to give name to the current settings
	vSettingName = "";
	ShowInputString(New NotifyDescription("ActionSaveSettingsAfterSettingNameInput", ThisForm), vSettingName, NStr("en='Please give name to your settings!';ru='Пожалуйста укажите название новой настройки!';de='Bitte geben Sie den Namen der neuen Einstellung ein!'"), 150, False);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionSaveSettingsAfterSettingNameInput(pSettingName, pExtraParams) Export
	If pSettingName <> Undefined And Not IsBlankString(pSettingName) Then
		ActionSaveSettingsAtServer(pSettingName);
		ShowMessageBox(, NStr("en='Search settings were saved successfully!';ru='Настройки поиска были успешно сохранены!';de='Die Sucheinstellungen wurden erfolgreich gespeichert!'"));
	EndIf;
EndProcedure // ActionSaveSettingsAfterSettingNameInput

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionSaveSettingsAtServer(pSettingName)
	// Create item
	vSettingObj = Catalogs.ObjectFormActions.CreateItem();
	vSettingObj.Code = "USR";
	vSettingObj.Description = pSettingName;
	vSettingObj.Parent = Catalogs.ObjectFormActions.FindByCode("1600");
	vSettingObj.ObjectType = Documents.SMSDelivery.EmptyRef();
	vSettingObj.IsActive = True;
	vSettingObj.Remarks = GetSettingsRemarks();
	vSettingObj.Settings = New ValueStorage(GetSettingsStructure());
	vSettingObj.Write();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function GetSettingsRemarks()
	vSearchDescription = "";
	If ValueIsFilled(SelPeriodFrom) Or ValueIsFilled(SelPeriodTo) Then
		vSearchDescription = NStr("en='Search customers created in period from ';ru='Поиск контрагентов с датой регистрации в периоде с ';de='Suche nach Partnern mit dem Datum der Registrierung im Zeitraum ab '") + Format(SelPeriodFrom, "DF=dd.MM.yyyy") + NStr("en=' to ';ru=' по ';de=' bis '") + Format(SelPeriodTo, "DF=dd.MM.yyyy");
	EndIf;
	If ValueIsFilled(SelCustomer) Then
		vSearchDescription = vSearchDescription + Chars.LF + NStr("en='by customer ';ru='по контрагенту ';de='nach Partner '") + TrimAll(SelCustomer);
	EndIf;
	If ValueIsFilled(SelCustomerType) Then
		vSearchDescription = vSearchDescription + Chars.LF + NStr("en='by customer type ';ru='по типу контрагента ';de='nach Partnertyp '") + TrimAll(SelCustomerType);
	EndIf;
	If ValueIsFilled(SelClientType) Then
		vSearchDescription = vSearchDescription + Chars.LF + NStr("en='by client type ';ru='по типу гостей ';de='nach Gästetyp '") + TrimAll(SelClientType);
	EndIf;
	If ValueIsFilled(SelMarketingCode) Then
		vSearchDescription = vSearchDescription + Chars.LF + NStr("en='by marketing code ';ru='по направлению маркетинга ';de='nach Marketingrichtung '") + TrimAll(SelMarketingCode);
	EndIf;
	If ValueIsFilled(SelSourceOfBusiness) Then
		vSearchDescription = vSearchDescription + Chars.LF + NStr("en='by source of business ';ru='по источнику информации ';de='nach Informationsquelle '") + TrimAll(SelSourceOfBusiness);
	EndIf;
	If ValueIsFilled(SelRoomRateType) Then
		vSearchDescription = vSearchDescription + Chars.LF + NStr("en='by room rate type ';ru='по типу тарифа ';de='nach Tariftyp '") + TrimAll(SelRoomRateType);
	EndIf;
	If ValueIsFilled(SelRoomRate) Then
		vSearchDescription = vSearchDescription + Chars.LF + NStr("en='by room rate ';ru='по тарифу ';de='nach Tarif '") + TrimAll(SelRoomRate);
	EndIf;
	If SelNonResidentOnly Then
		vSearchDescription = vSearchDescription + Chars.LF + NStr("en='non residents only';ru='только нерезиденты';de='nur nichtansässige Personen '");
	EndIf;
	If SelResidentOnly Then
		vSearchDescription = vSearchDescription + Chars.LF + NStr("en='residents only';ru='только резиденты';de='nur ansässige Personen'");
	EndIf;
	If SelWithActiveContractsOnly Then
		vSearchDescription = vSearchDescription + Chars.LF + NStr("en='with active contracts only';ru='только с действующими договорами';de='nur mit laufenden Verträgen'");
	EndIf;
	
	Return vSearchDescription;
EndFunction // GetSettingsRemarks

// -----------------------------------------------------------------------------
&AtServer
Function GetSettingsStructure()
	vSettingsStruct = New Structure();
	vSettingsStruct.Insert("SelTegs", SelTags);
	vSettingsStruct.Insert("Tags", Tags);
	vSettingsStruct.Insert("SelPeriodFrom", SelPeriodFrom);
	vSettingsStruct.Insert("SelPeriodTo", SelPeriodTo);
	vSettingsStruct.Insert("SelCustomer", SelCustomer);
	vSettingsStruct.Insert("SelCustomerType", SelCustomerType);
	vSettingsStruct.Insert("SelClientType", SelClientType);
	vSettingsStruct.Insert("SelMarketingCode", SelMarketingCode);
	vSettingsStruct.Insert("SelSourceOfBusiness", SelSourceOfBusiness);
	vSettingsStruct.Insert("SelRoomRate", SelRoomRate);
	vSettingsStruct.Insert("SelRoomRateType", SelRoomRateType);
	vSettingsStruct.Insert("SelNonResidentOnly", SelNonResidentOnly);
	vSettingsStruct.Insert("SelResidentOnly", SelResidentOnly);
	vSettingsStruct.Insert("SelWithActiveContractsOnly", SelWithActiveContractsOnly);
	Return vSettingsStruct;
EndFunction // GetSettingsStructure

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionLoadSettings(pCommand)
	vListSettings = ListSettings ();
	If vListSettings.Count() > 0 Then
		vListSettings.ShowChooseItem(New NotifyDescription("LoadSettings", ThisForm), NStr("en='';ru='';de=''"),vListSettings);
	EndIf;
EndProcedure // ActionLoadSettings

// -----------------------------------------------------------------------------
&AtClient
Procedure LoadSettings(pItem, pExtraParams) Export
	If pItem <> Undefined Then
		LoadSettingsAtServer(pItem.Value);	
	EndIf;
EndProcedure // LoadSettings

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadSettingsAtServer(pRef)
	vSettingsStruct = pRef.Settings.Get();
	FillPropertyValues(ThisForm, vSettingsStruct);	
EndProcedure // LoadSettingsAtServer

// -----------------------------------------------------------------------------
&AtServer
Function ListSettings ()
	vCurObjectType = Documents.SMSDelivery.EmptyRef();
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	ObjectFormActions.Ref AS Ref,
	|	ObjectFormActions.Description AS Description
	|FROM
	|	Catalog.ObjectFormActions AS ObjectFormActions
	|WHERE
	|	NOT ObjectFormActions.DeletionMark
	|	AND NOT ObjectFormActions.IsFolder
	|	AND ObjectFormActions.IsActive
	|	AND ObjectFormActions.ObjectType = &qObjectType
	|	AND ObjectFormActions.Code = &qCode";
	vQry.SetParameter("qObjectType", vCurObjectType);
	vQry.SetParameter("qCode", "USR");
	vList = vQry.Execute().Unload();
	vListSettings = new ValueList();
	For Each vListSettingsRow In vList Do
		vListSettings.Add(vListSettingsRow.Ref, vListSettingsRow.Description);
	EndDo;
	Return vListSettings; 
EndFunction // ListSettings

// -----------------------------------------------------------------------------
&AtClient
Procedure SelNonResidentOnlyOnChange(pItem)
	If SelNonResidentOnly Then
		If SelResidentOnly Then
			SelResidentOnly = False;
		EndIf;
	EndIf;
EndProcedure // SelNonResidentOnlyOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelResidentOnlyOnChange(pItem)
	If SelResidentOnly Then
		If SelNonResidentOnly Then
			SelNonResidentOnly = False;
		EndIf;
	EndIf;
EndProcedure // SelResidentOnlyOnChange

