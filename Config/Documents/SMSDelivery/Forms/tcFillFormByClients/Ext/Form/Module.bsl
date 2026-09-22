// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("SelHotel") Then
		SelHotel = Parameters.SelHotel;
	Else
		SelHotel = SessionParameters.CurrentHotel;
	EndIf;
	If Parameters.Property("SelSMSDeliveryObject") Then
		CopyFormData(Parameters.SelSMSDeliveryObject,SelSMSDeliveryObject);
	EndIf;
	If Parameters.Property("SelReportingCurrency") Then
		SelReportingCurrency = Parameters.SelReportingCurrency;
	EndIf;
	If Parameters.Property("SelCountry") Then
		SelCountry = Parameters.SelCountry;
	EndIf;
	SelTags = cmGetAllTagsList();
	If SelTags.Count() = 0 Then
		Items.GroupTags.Visible = False;
	Else
		Items.GroupTags.Visible = True;
	EndIf;
	// Check rights to select clients by create date
	If Not tcOnServer.CheckIfHotelCouldBeCleared() Then
		Items.SelPeriodType.ChoiceList.Delete(3);
	EndIf;
	RefreshDisplay();
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure TagsStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	SelTags.ShowCheckItems(New NotifyDescription("ClientTagsAfterBeingChecked", ThisForm), NStr("en='Check tags...'; ru='Отметьте теги...'; de='Tags Markierungen...'"));
EndProcedure // TagsStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientTagsAfterBeingChecked(pList, pExtraParams) Export 
	If pList <> Undefined Then	
		Tags.Clear();
		For Each vListItem In pList Do
			If vListItem.Check Then
				Tags.Add(vListItem.Value, vListItem.Presentation);
			EndIf;
		EndDo;	
	EndIf;
EndProcedure // ClientTagsAfterBeingChecked

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

&AtClient
Procedure ButtonChooseSalesPeriod(pCommand)
	vChoosePeriodDialog = New StandardPeriodEditDialog();
	vChoosePeriodDialog.Period.StartDate = SelSalesPeriodFrom;
	vChoosePeriodDialog.Period.EndDate = SelSalesPeriodTo;
	vChoosePeriodDialog.Period.Variant = StandardPeriodVariant.Custom;
	vChoosePeriodDialog.Show(New NotifyDescription("ChooseSalesPeriodAfterChoice", ThisForm));
EndProcedure // ButtonChooseSalesPeriod

// -----------------------------------------------------------------------------
&AtClient
Procedure ChooseSalesPeriodAfterChoice(pPeriod, pExtraParams) Export
	If pPeriod <> Undefined Then
		SelSalesPeriodFrom = pPeriod.StartDate;
		SelSalesPeriodTo = pPeriod.EndDate;
	EndIf;
EndProcedure // ChoosePeriodAfterChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure SelInHouseOnlyOnChange(pItem)
	If SelInHouseOnly Then
		SelCheckedOutOnly = False;
		SelExpectedOnly = False;
	EndIf;
	RefreshDisplay();
EndProcedure // SelInHouseOnlyOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelCheckedOutOnlyOnChange(pItem)
	If SelCheckedOutOnly Then
		SelInHouseOnly = False;
		SelExpectedOnly = False;
	EndIf;
	RefreshDisplay();
EndProcedure // SelCheckedOutOnlyOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelExpectedOnlyOnChange(pItem)
	If SelExpectedOnly Then
		SelCheckedOutOnly = False;
		SelInHouseOnly = False;
	EndIf;
	RefreshDisplay();
EndProcedure // SelExpectedOnlyOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure RefreshDisplay()
	If SelPeriodType = 3 Then
		If SelByReservation Then
			SelByReservation = False;
		EndIf;
		Items.SelByReservation.Enabled = False;
		If SelNoReservation Then
			SelNoReservation = False;
		EndIf;
		Items.SelNoReservation.Enabled = False;
		If SelNoCustomer Then
			SelNoCustomer = False;
		EndIf;
		Items.SelNoCustomer.Enabled = False;
		If SelInHouseOnly Then
			SelInHouseOnly = False;
		EndIf;
		Items.SelInHouseOnly.Enabled = False;
		If SelCheckedOutOnly Then
			SelCheckedOutOnly = False;
		EndIf;
		Items.SelCheckedOutOnly.Enabled = False;
		If SelExpectedOnly Then
			SelExpectedOnly = False;
		EndIf;
		Items.SelExpectedOnly.Enabled = False;
		If SelNotInHouseAndWithoutActiveReservationOnly Then
			SelNotInHouseAndWithoutActiveReservationOnly = False;
		EndIf;
		Items.SelNotInHouseAndWithoutActiveReservationOnly.Enabled = False;
		Items.SelCustomer.Enabled = False;
		Items.SelContract.Enabled = False;
		Items.SelEvent.Enabled = False;
		Items.SelGuestGroup.Enabled = False;
		Items.SelCustomerType.Enabled = False;
		Items.SelRoom.Enabled = False;
		Items.SelRoomType.Enabled = False;
		Items.SelTripPurpose.Enabled = False;
	Else
		Items.SelByReservation.Enabled = True;
		Items.SelNoReservation.Enabled = True;
		Items.SelNoCustomer.Enabled = True;
		Items.SelInHouseOnly.Enabled = True;
		Items.SelCheckedOutOnly.Enabled = True;
		Items.SelExpectedOnly.Enabled = True;
		Items.SelNotInHouseAndWithoutActiveReservationOnly.Enabled = True;
		Items.SelCustomer.Enabled = True;
		Items.SelContract.Enabled = True;
		Items.SelEvent.Enabled = True;
		Items.SelGuestGroup.Enabled = True;
		Items.SelCustomerType.Enabled = True;
		Items.SelRoom.Enabled = True;
		Items.SelRoomType.Enabled = True;
		Items.SelTripPurpose.Enabled = True;
	EndIf;
EndProcedure // RefreshDisplay

// -----------------------------------------------------------------------------
&AtClient
Procedure SelPeriodTypeOnChange(pItem)
	RefreshDisplay();
EndProcedure // SelPeriodTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelByReservationOnChange(pItem)
	RefreshDisplay();
EndProcedure // SelByReservationOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelNoReservationOnChange(pItem)
	RefreshDisplay();
EndProcedure // SelNoReservationOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelNoCustomerOnChange(pItem)
	RefreshDisplay();
EndProcedure // SelNoCustomerOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelNotInHouseAndWithoutActiveReservationOnlyOnChange(pItem)
	RefreshDisplay();
EndProcedure // SelNotInHouseAndWithoutActiveReservationOnlyOnChange

&AtClient
Procedure ActionLoadSettings(Command)
	vListSettings = ListSettings ();
	If vListSettings.Count() > 0 Then
		vListSettings.ShowChooseItem(New NotifyDescription("LoadSettings", ThisForm), NStr("en='';ru='';de=''"),vListSettings);
	EndIf;
EndProcedure

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
	vQry.SetParameter("qCode", "USC");
	vList = vQry.Execute().Unload();
	vListSettings = new ValueList();
	For Each vListSettingsRow In vList Do
		vListSettings.Add(vListSettingsRow.Ref, vListSettingsRow.Description);
	EndDo;
	Return vListSettings; 
EndFunction // ListSettings

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionSaveSettings(pCommand)
	// Ask user to give name to the current settings
	vSettingName = "";
	ShowInputString(New NotifyDescription("ActionSaveSettingsAfterSettingNameInput", ThisForm), vSettingName, NStr("en='Please give name to your settings!';ru='Пожалуйста укажите название новой настройки!';de='Bitte geben Sie den Namen der neuen Einstellung ein!'"), 150, False);
EndProcedure // ActionSaveSettings

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
	vSettingObj.Code = "USC";
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
		If SelPeriodType = 0 Then
			vSearchDescription = NStr("en='Search guests with period of stay including dates from ';ru='Поиск гостей с периодом проживания попадающим в период с ';de='Suche nach Gästen mit dem Unterbringungszeitraum, der im Zeitraum liegt ab '") + Format(SelPeriodFrom, "DF=dd.MM.yyyy") + NStr("en=' to ';ru=' по ';de=' bis '") + Format(SelPeriodTo, "DF=dd.MM.yyyy");
		ElsIf SelPeriodType = 1 Then
			vSearchDescription = NStr("en='Search guests with check-in date between ';ru='Поиск гостей с датой заезда в периоде с ';de='Suche nach Gästen mit der Anreise im Zeitraum ab '") + Format(SelPeriodFrom, "DF=dd.MM.yyyy") + NStr("en=' and ';ru=' по ';de=' bis '") + Format(SelPeriodTo, "DF=dd.MM.yyyy");
		ElsIf SelPeriodType = 2 Then
			vSearchDescription = NStr("en='Search guests with check-out date between ';ru='Поиск гостей с датой выезда в периоде с ';de='Suche nach Gästen mit der Abreise im Zeitraum ab '") + Format(SelPeriodFrom, "DF=dd.MM.yyyy") + NStr("en=' and ';ru=' по ';de=' bis '") + Format(SelPeriodTo, "DF=dd.MM.yyyy");
		ElsIf SelPeriodType = 3 Then
			vSearchDescription = NStr("en='Search guests with creation date between ';ru='Поиск гостей с датой регистрации в периоде с ';de='Suche nach Gästen mit der Registrierung im Zeitraum ab '") + Format(SelPeriodFrom, "DF=dd.MM.yyyy") + NStr("en=' and ';ru=' по ';de=' bis '") + Format(SelPeriodTo, "DF=dd.MM.yyyy");
		EndIf;
	EndIf;
	If ValueIsFilled(SelCustomer) Then
		vSearchDescription = vSearchDescription + Chars.LF + NStr("en='by customer ';ru='по контрагенту ';de='nach Partner '") + TrimAll(SelCustomer);
	EndIf;
	If ValueIsFilled(SelContract) Then
		vSearchDescription = vSearchDescription + Chars.LF + NStr("en='by contract ';ru='по договору ';de='nach Vertrag '") + TrimAll(SelContract);
	EndIf;
	If ValueIsFilled(SelEvent) Then
		vSearchDescription = vSearchDescription + Chars.LF + NStr("en='by event ';ru='по мероприятию ';de='nach Veranstaltung '") + TrimAll(SelEvent);
	EndIf;
	If ValueIsFilled(SelGuestGroup) Then
		vSearchDescription = vSearchDescription + Chars.LF + NStr("en='by guest group ';ru='по группе гостей ';de='nach Gästegruppe '") + TrimAll(SelGuestGroup);
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
	If ValueIsFilled(SelTripPurpose) Then
		vSearchDescription = vSearchDescription + Chars.LF + NStr("en='by trip purpose ';ru='по цели визита ';de='nach Besuchsziel '") + TrimAll(SelTripPurpose);
	EndIf;
	If ValueIsFilled(SelRoomRateType) Then
		vSearchDescription = vSearchDescription + Chars.LF + NStr("en='by room rate type ';ru='по типу тарифа ';de='nach Tariftyp '") + TrimAll(SelRoomRateType);
	EndIf;
	If ValueIsFilled(SelRoomRate) Then
		vSearchDescription = vSearchDescription + Chars.LF + NStr("en='by room rate ';ru='по тарифу ';de='nach Tarif '") + TrimAll(SelRoomRate);
	EndIf;
	If ValueIsFilled(SelRoomType) Then
		vSearchDescription = vSearchDescription + Chars.LF + NStr("en='by room type ';ru='по типу номера ';de='nach Zimmertyp '") + TrimAll(SelRoomType);
	EndIf;
	If ValueIsFilled(SelRoom) Then
		vSearchDescription = vSearchDescription + Chars.LF + NStr("en='by room ';ru='по номерам ';de='nach Zimmern '") + TrimAll(SelRoom);
	EndIf;
	If ValueIsFilled(SelCountry) Then
		vSearchDescription = vSearchDescription + Chars.LF + NStr("en='by country ';ru='по стране ';de='nach Land '") + TrimAll(SelCountry);
	EndIf;
	If Not IsBlankString(SelRegion) Then
		vSearchDescription = vSearchDescription + Chars.LF + NStr("en='by region/city ';ru='по региону/городу ';de='nach Region/Stadt '") + TrimAll(SelRegion);
	EndIf;
	If ValueIsFilled(SelAgeRange) Then
		vSearchDescription = vSearchDescription + Chars.LF + NStr("en='by age range ';ru='по возрастной группе ';de='nach Altersgruppe '") + TrimAll(SelAgeRange);
	EndIf;
	If SelAgeFrom > 0 Or SelAgeTo > 0 Then
		vSearchDescription = vSearchDescription + Chars.LF + NStr("en='by age starting from ';ru='по возрасту от ';de='nach Alter ab '") + Format(SelAgeFrom, "ND=3; NFD=0; NZ=; NG=") + NStr("en=' to ';ru=' до ';de=' bis '") + Format(?(SelAgeTo = 0, 999, SelAgeTo), "ND=3; NFD=0; NZ=; NG=");
	EndIf;
	If ValueIsFilled(SelBirthDayPeriodFrom) And ValueIsFilled(SelBirthDayPeriodTo) Then
		vSearchDescription = vSearchDescription + Chars.LF + NStr("en='with birth day between ';ru='с днем рождения попадающим в период с ';de='mit Geburtstag im Zeitraum ab '") + Format(SelBirthDayPeriodFrom, "DF=dd.MM") + NStr("en=' and ';ru=' по ';de=' bis '") + Format(SelBirthDayPeriodTo, "DF=dd.MM");
	EndIf;
	If SelNumberOfCheckIns > 0 Then
		vSearchDescription = vSearchDescription + Chars.LF + NStr("en='by number of check-ins from ';ru='по кол-ву заездов от ';de='nach Anzahl von Anreisen von '") + Format(SelNumberOfCheckIns, "ND=10; NFD=0; NZ=; NG=");
	EndIf;
	If SelNumberOfGuestDays > 0 Then
		vSearchDescription = vSearchDescription + Chars.LF + NStr("en='by number of guest days from ';ru='по кол-ву ночей от ';de='nach Anzahl der Nächte von '") + Format(SelNumberOfGuestDays, "ND=10; NFD=0; NZ=; NG=");
	EndIf;
	If SelSalesAmount > 0 Then
		vSearchDescription = vSearchDescription + Chars.LF + NStr("en='by sales amount from ';ru='по сумме оказанных услуг от ';de='nach Summer erbrachter Dienstleistungen von '") + cmFormatSum(SelSalesAmount, SelReportingCurrency) + NStr("en=' by service group ';ru=' по набору услуг ';de=' nach Dienstleistungen '") + TrimAll(SelServiceGroup) + NStr("en=' by period ';ru=' за период ';de=' für den Zeitraum '") + Format(SelSalesPeriodFrom, "DF=dd.MM.yyyy") + NStr("en=' to ';ru=' по ';de=' bis '") + Format(SelSalesPeriodTo, "DF=dd.MM.yyyy");
	EndIf;
	If SelWithBalance Then
		vSearchDescription = vSearchDescription + Chars.LF + NStr("en='with debt greater then ';ru='с долгом больше ';de='mit Verbindlichkeiten höher als '") + cmFormatSum(SelDebtAmount, SelReportingCurrency, "NZ=");
	EndIf;
	If ValueIsFilled(SelHotel) Then
		vSearchDescription = vSearchDescription + Chars.LF + NStr("en='by hotel ';ru='по гостинице ';de='nach Hotel '") + TrimAll(SelHotel);
	EndIf;
	Return vSearchDescription;
EndFunction // GetSettingsRemarks

// -----------------------------------------------------------------------------
&AtServer
Function GetSettingsStructure()
	vSettingsStruct = New Structure();
	vSettingsStruct.Insert("SelTegs", SelTags);
	vSettingsStruct.Insert("Tags", Tags);
	vSettingsStruct.Insert("SelPeriodType", SelPeriodType);
	vSettingsStruct.Insert("SelPeriodFrom", SelPeriodFrom);
	vSettingsStruct.Insert("SelPeriodTo", SelPeriodTo);
	vSettingsStruct.Insert("SelCustomer", SelCustomer);
	vSettingsStruct.Insert("SelCustomerType", SelCustomerType);
	vSettingsStruct.Insert("SelContract", SelContract);
	vSettingsStruct.Insert("SelEvent", SelEvent);
	vSettingsStruct.Insert("SelGuestGroup", SelGuestGroup);
	vSettingsStruct.Insert("SelClientType", SelClientType);
	vSettingsStruct.Insert("SelMarketingCode", SelMarketingCode);
	vSettingsStruct.Insert("SelSourceOfBusiness", SelSourceOfBusiness);
	vSettingsStruct.Insert("SelTripPurpose", SelTripPurpose);
	vSettingsStruct.Insert("SelRoomRate", SelRoomRate);
	vSettingsStruct.Insert("SelRoomRateType", SelRoomRateType);
	vSettingsStruct.Insert("SelRoom", SelRoom);
	vSettingsStruct.Insert("SelRoomType", SelRoomType);
	vSettingsStruct.Insert("SelCountry", SelCountry);
	vSettingsStruct.Insert("SelRegion", SelRegion);
	vSettingsStruct.Insert("SelAgeRange", SelAgeRange);
	vSettingsStruct.Insert("SelAgeFrom", SelAgeFrom);
	vSettingsStruct.Insert("SelAgeTo", SelAgeTo);
	vSettingsStruct.Insert("SelBirthDayPeriodFrom", SelBirthDayPeriodFrom);
	vSettingsStruct.Insert("SelBirthDayPeriodTo", SelBirthDayPeriodTo);
	vSettingsStruct.Insert("SelNumberOfCheckIns", SelNumberOfCheckIns);
	vSettingsStruct.Insert("SelNumberOfGuestDays", SelNumberOfGuestDays);
	vSettingsStruct.Insert("SelSalesAmount", SelSalesAmount);
	vSettingsStruct.Insert("SelServiceGroup", SelServiceGroup);
	vSettingsStruct.Insert("SelSalesPeriodFrom", SelSalesPeriodFrom);
	vSettingsStruct.Insert("SelSalesPeriodTo", SelSalesPeriodTo);
	vSettingsStruct.Insert("SelWithBalance", SelWithBalance);
	vSettingsStruct.Insert("SelDebtAmount", SelDebtAmount);
	vSettingsStruct.Insert("SelReportingCurrency", SelReportingCurrency);
	vSettingsStruct.Insert("SelImportantDateType", SelImportantDateType);
	Return vSettingsStruct;
EndFunction // GetSettingsStructure

// -----------------------------------------------------------------------------
&AtServer
Function ActionDoSearchAtServer(pUsedPhones, pUsedEMails)
	vNothingFound = True;
	// Clear receivers
	Receivers.Clear();
	// Fill currency
	If Not ValueIsFilled(SelReportingCurrency) And ValueIsFilled(SelHotel) Then
		SelReportingCurrency = SelHotel.ReportingCurrency;
	EndIf;
	// Fill birth day period
	vSelBirthDayPeriodFrom = Date(2000, Month(SelBirthDayPeriodFrom), Day(SelBirthDayPeriodFrom));
	vSelBirthDayPeriodTo = Date(2000, Month(SelBirthDayPeriodTo), Day(SelBirthDayPeriodTo));
	// Get guests
	vQry = New Query();
	If SelPeriodType = 3 Then
		If Not ChecksOrAndTags Or Not Items.ChecksOrAndTags.Visible Then
			vQry.Text = 
			"SELECT DISTINCT
			|	NULL AS Ref,
			|	NULL AS GuestGroup,
			|	Clients.Ref AS Guest,
			|	Clients.Ref.Language AS Language,
			|	Clients.Phone AS Phone,
			|	Clients.EMail AS EMail,
			|	Clients.FullName AS GuestFullName
			|FROM
			|	Catalog.Clients AS Clients " +
			?(Tags.Count() > 0, 
		    "		INNER JOIN InformationRegister.ClientTags AS ClientTags
			|		ON Clients.Ref = ClientTags.Client
			|			AND (ClientTags.Tag IN (&qTagsList)) ", "") + 
			?(ValueIsFilled(SelImportantDateType), 
		    "		INNER JOIN InformationRegister.ClientImportantDates AS ClientImportantDates
			|		ON Clients.Ref = ClientImportantDates.Guest
			|			AND (ClientImportantDates.ImportantDateType = &qImportantDateType)
			|			AND (ClientImportantDates.Date > &qEmptyDate)
			|			AND (BEGINOFPERIOD(DATEADD(ClientImportantDates.Date, YEAR, -(YEAR(ClientImportantDates.Date) - 1)), DAY) >= &qImportantDateFrom)
			|			AND (BEGINOFPERIOD(DATEADD(ClientImportantDates.Date, YEAR, -(YEAR(ClientImportantDates.Date) - 1)), DAY) <= &qImportantDateTo)", "") + "
			|WHERE
			|	NOT Clients.IsFolder
			|	AND NOT Clients.DeletionMark
			|	AND Clients.CreateDate <= &qPeriodTo
			|	AND Clients.CreateDate >= &qPeriodFrom
			|	AND (Clients.Phone <> &qEmptyString
			|				AND NOT &qCheckEMail
			|				AND NOT &qCheckBoth
			|			OR Clients.EMail <> &qEmptyString
			|				AND &qCheckEMail
			|				AND NOT &qCheckBoth
			|			OR (Clients.Phone <> &qEmptyString
			|				OR Clients.EMail <> &qEmptyString)
			|				AND &qCheckBoth)
			|	AND NOT Clients.NoSMSDelivery
			|	AND (NOT &qClientTypeIsEmpty
			|				AND Clients.ClientType <> &qEmptyClientType
			|				AND Clients.ClientType IN HIERARCHY (&qClientType)
			|			OR &qClientTypeIsEmpty)
			|	AND (NOT &qDiscountTypeIsEmpty
			|				AND Clients.DiscountType <> &qEmptyDiscountType
			|				AND Clients.DiscountType IN HIERARCHY (&qDiscountType)
			|			OR &qDiscountTypeIsEmpty)
			|	AND (NOT &qMarketingCodeIsEmpty
			|				AND Clients.MarketingCode <> &qEmptyMarketingCode
			|				AND Clients.MarketingCode IN HIERARCHY (&qMarketingCode)
			|			OR &qMarketingCodeIsEmpty)
			|	AND (NOT &qSourceOfBusinessIsEmpty
			|				AND Clients.SourceOfBusiness <> &qEmptySourceOfBusiness
			|				AND Clients.SourceOfBusiness IN HIERARCHY (&qSourceOfBusiness)
			|			OR &qSourceOfBusinessIsEmpty)
			|	AND (NOT &qRoomRateIsEmpty
			|				AND Clients.RoomRate <> &qEmptyRoomRate
			|				AND Clients.RoomRate IN HIERARCHY (&qRoomRate)
			|			OR &qRoomRateIsEmpty)
			|	AND (NOT &qRoomRateTypeIsEmpty
			|				AND NOT Clients.RoomRate.RoomRateType IS NULL
			|				AND Clients.RoomRate.RoomRateType <> &qEmptyRoomRateType
			|				AND Clients.RoomRate.RoomRateType IN HIERARCHY (&qRoomRateType)
			|			OR &qRoomRateTypeIsEmpty)
			|	AND (NOT &qCountryIsEmpty
			|				AND Clients.Citizenship <> &qEmptyCountry
			|				AND Clients.Citizenship IN HIERARCHY (&qCountry)
			|			OR &qCountryIsEmpty)
			|	AND (NOT &qAgeRangeIsEmpty
			|				AND Clients.AgeRange = &qAgeRange
			|			OR &qAgeRangeIsEmpty)
			|	AND (NOT &qRegionIsEmpty
			|				AND Clients.Address LIKE &qRegion
			|			OR &qRegionIsEmpty)
			|	AND Clients.Age >= &qAgeFrom
			|	AND Clients.Age <= &qAgeTo
			|	AND (&qClientsWithoutEMailOnly
			|				AND Clients.EMail = &qEmptyString
			|			OR NOT &qClientsWithoutEMailOnly)
			|	AND (NOT &qCheckBirthDay
			|			OR &qCheckBirthDay
			|				AND Clients.DateOfBirth > &qEmptyDate
			|				AND (YEAR(&qBirthDayPeriodTo) = YEAR(&qBirthDayPeriodFrom)
			|						AND MONTH(Clients.DateOfBirth) * 100 + DAY(Clients.DateOfBirth) >= MONTH(&qBirthDayPeriodFrom) * 100 + DAY(&qBirthDayPeriodFrom)
			|						AND MONTH(Clients.DateOfBirth) * 100 + DAY(Clients.DateOfBirth) <= MONTH(&qBirthDayPeriodTo) * 100 + DAY(&qBirthDayPeriodTo)
			|					OR YEAR(&qBirthDayPeriodTo) <> YEAR(&qBirthDayPeriodFrom)
			|						AND (MONTH(Clients.DateOfBirth) * 100 + DAY(Clients.DateOfBirth) >= MONTH(&qBirthDayPeriodFrom) * 100 + DAY(&qBirthDayPeriodFrom)
			|								AND MONTH(Clients.DateOfBirth) * 100 + DAY(Clients.DateOfBirth) <= 1231
			|							OR MONTH(Clients.DateOfBirth) * 100 + DAY(Clients.DateOfBirth) <= MONTH(&qBirthDayPeriodTo) * 100 + DAY(&qBirthDayPeriodTo)
			|								AND MONTH(Clients.DateOfBirth) * 100 + DAY(Clients.DateOfBirth) >= 101)))
			|	AND CASE
			|			WHEN &qEmptySex <> &qSex
			|				THEN Clients.Sex = &qSex
			|			ELSE TRUE
			|		END
			|
			|ORDER BY
			|	GuestFullName";
		Else
			vQry.Text = 
			"SELECT
			|	ClientsWithTags.Ref AS Ref,
			|	ClientsWithTags.Ref.GuestGroup AS GuestGroup,
			|	ClientsWithTags.Guest AS Guest,
			|	ClientsWithTags.Guest.Language AS Language,
			|	ClientsWithTags.Phone AS Phone,
			|	ClientsWithTags.EMail AS EMail,
			|	ClientsWithTags.GuestFullName AS GuestFullName,
			|	SUM(ClientsWithTags.TagCount) AS TagCount
			|FROM
			|	(SELECT
			|		NULL AS Ref,
			|		Clients.Ref AS Guest,
			|		Clients.Phone AS Phone,
			|		Clients.EMail AS EMail,
			|		Clients.FullName AS GuestFullName,
			|		ClientTags.Tag AS Tag,
			|		1 AS TagCount
			|	FROM
			|		Catalog.Clients AS Clients
			|			INNER JOIN InformationRegister.ClientTags AS ClientTags
			|			ON Clients.Ref = ClientTags.Client
			|				AND (ClientTags.Tag IN (&qTagsList))" +
			?(ValueIsFilled(SelImportantDateType), 
		    "		INNER JOIN InformationRegister.ClientImportantDates AS ClientImportantDates
			|		ON Clients.Ref = ClientImportantDates.Guest
			|			AND (ClientImportantDates.ImportantDateType = &qImportantDateType)
			|			AND (ClientImportantDates.Date > &qEmptyDate)
			|			AND (BEGINOFPERIOD(DATEADD(ClientImportantDates.Date, YEAR, -(YEAR(ClientImportantDates.Date) - 1)), DAY) >= &qImportantDateFrom)
			|			AND (BEGINOFPERIOD(DATEADD(ClientImportantDates.Date, YEAR, -(YEAR(ClientImportantDates.Date) - 1)), DAY) <= &qImportantDateTo)", "") + "
			|	WHERE
			|		NOT Clients.IsFolder
			|		AND NOT Clients.DeletionMark
			|		AND Clients.CreateDate <= &qPeriodTo
			|		AND Clients.CreateDate >= &qPeriodFrom
			|		AND (Clients.Phone <> &qEmptyString
			|					AND NOT &qCheckEMail
			|					AND NOT &qCheckBoth
			|				OR Clients.EMail <> &qEmptyString
			|					AND &qCheckEMail
			|					AND NOT &qCheckBoth
			|				OR (Clients.Phone <> &qEmptyString
			|					OR Clients.EMail <> &qEmptyString)
			|					AND &qCheckBoth)
			|		AND NOT Clients.NoSMSDelivery
			|		AND (NOT &qClientTypeIsEmpty
			|					AND Clients.ClientType <> &qEmptyClientType
			|					AND Clients.ClientType IN HIERARCHY (&qClientType)
			|				OR &qClientTypeIsEmpty)
			|		AND (NOT &qDiscountTypeIsEmpty
			|					AND Clients.DiscountType <> &qEmptyDiscountType
			|					AND Clients.DiscountType IN HIERARCHY (&qDiscountType)
			|				OR &qDiscountTypeIsEmpty)
			|		AND (NOT &qMarketingCodeIsEmpty
			|					AND Clients.MarketingCode <> &qEmptyMarketingCode
			|					AND Clients.MarketingCode IN HIERARCHY (&qMarketingCode)
			|				OR &qMarketingCodeIsEmpty)
			|		AND (NOT &qSourceOfBusinessIsEmpty
			|					AND Clients.SourceOfBusiness <> &qEmptySourceOfBusiness
			|					AND Clients.SourceOfBusiness IN HIERARCHY (&qSourceOfBusiness)
			|				OR &qSourceOfBusinessIsEmpty)
			|		AND (NOT &qRoomRateIsEmpty
			|					AND Clients.RoomRate <> &qEmptyRoomRate
			|					AND Clients.RoomRate IN HIERARCHY (&qRoomRate)
			|				OR &qRoomRateIsEmpty)
			|		AND (NOT &qRoomRateTypeIsEmpty
			|					AND NOT Clients.RoomRate.RoomRateType IS NULL
			|					AND Clients.RoomRate.RoomRateType <> &qEmptyRoomRateType
			|					AND Clients.RoomRate.RoomRateType IN HIERARCHY (&qRoomRateType)
			|				OR &qRoomRateTypeIsEmpty)
			|		AND (NOT &qCountryIsEmpty
			|					AND Clients.Citizenship <> &qEmptyCountry
			|					AND Clients.Citizenship IN HIERARCHY (&qCountry)
			|				OR &qCountryIsEmpty)
			|		AND (NOT &qAgeRangeIsEmpty
			|					AND Clients.AgeRange = &qAgeRange
			|				OR &qAgeRangeIsEmpty)
			|		AND (NOT &qRegionIsEmpty
			|					AND Clients.Address LIKE &qRegion
			|				OR &qRegionIsEmpty)
			|		AND Clients.Age >= &qAgeFrom
			|		AND Clients.Age <= &qAgeTo
			|		AND (&qClientsWithoutEMailOnly
			|					AND Clients.EMail = &qEmptyString
			|				OR NOT &qClientsWithoutEMailOnly)
			|		AND (NOT &qCheckBirthDay
			|				OR &qCheckBirthDay
			|					AND Clients.DateOfBirth > &qEmptyDate
			|					AND (YEAR(&qBirthDayPeriodTo) = YEAR(&qBirthDayPeriodFrom)
			|							AND MONTH(Clients.DateOfBirth) * 100 + DAY(Clients.DateOfBirth) >= MONTH(&qBirthDayPeriodFrom) * 100 + DAY(&qBirthDayPeriodFrom)
			|							AND MONTH(Clients.DateOfBirth) * 100 + DAY(Clients.DateOfBirth) <= MONTH(&qBirthDayPeriodTo) * 100 + DAY(&qBirthDayPeriodTo)
			|						OR YEAR(&qBirthDayPeriodTo) <> YEAR(&qBirthDayPeriodFrom)
			|							AND (MONTH(Clients.DateOfBirth) * 100 + DAY(Clients.DateOfBirth) >= MONTH(&qBirthDayPeriodFrom) * 100 + DAY(&qBirthDayPeriodFrom)
			|									AND MONTH(Clients.DateOfBirth) * 100 + DAY(Clients.DateOfBirth) <= 1231
			|								OR MONTH(Clients.DateOfBirth) * 100 + DAY(Clients.DateOfBirth) <= MONTH(&qBirthDayPeriodTo) * 100 + DAY(&qBirthDayPeriodTo)
			|									AND MONTH(Clients.DateOfBirth) * 100 + DAY(Clients.DateOfBirth) >= 101)))
			|		AND CASE
			|				WHEN &qEmptySex <> &qSex
			|					THEN Clients.Sex = &qSex
			|				ELSE TRUE
			|			END) AS ClientsWithTags
			|
			|GROUP BY
			|	ClientsWithTags.Ref,
			|	ClientsWithTags.Ref.GuestGroup,
			|	ClientsWithTags.Guest,
			|	ClientsWithTags.Guest.Language,
			|	ClientsWithTags.Phone,
			|	ClientsWithTags.EMail,
			|	ClientsWithTags.GuestFullName
			|
			|HAVING
			|	SUM(ClientsWithTags.TagCount) = &qTagsCount
			|
			|ORDER BY
			|	ClientsWithTags.GuestFullName";
			vQry.SetParameter("qTagsCount", Tags.Count());
		EndIf;
		vQry.SetParameter("qPeriodFrom", BegOfDay(SelPeriodFrom));
		vQry.SetParameter("qPeriodTo", ?(ValueIsFilled(SelPeriodTo), EndOfDay(SelPeriodTo), '39991231235959'));
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
		vQry.SetParameter("qCountry", SelCountry);
		vQry.SetParameter("qCountryIsEmpty", Not ValueIsFilled(SelCountry));
		vQry.SetParameter("qEmptyCountry", Catalogs.Countries.EmptyRef());
		vQry.SetParameter("qRegion", "%" + TrimAll(SelRegion) + "%");
		vQry.SetParameter("qRegionIsEmpty", IsBlankString(SelRegion));
		vQry.SetParameter("qAgeRange", SelAgeRange);
		vQry.SetParameter("qAgeRangeIsEmpty", Not ValueIsFilled(SelAgeRange));
		vQry.SetParameter("qAgeFrom", SelAgeFrom);
		vQry.SetParameter("qAgeTo", ?(SelAgeTo = 0, 999, SelAgeTo));
		vQry.SetParameter("qCheckBirthDay", ?(ValueIsFilled(SelBirthDayPeriodFrom) And ValueIsFilled(SelBirthDayPeriodTo), True, False));
		vQry.SetParameter("qBirthDayPeriodFrom", vSelBirthDayPeriodFrom);
		vQry.SetParameter("qBirthDayPeriodTo", vSelBirthDayPeriodTo);
		vQry.SetParameter("qEmptyString", "");
		vQry.SetParameter("qEmptyDate", '00010101');
		vQry.SetParameter("qCheckEMail", ?(SelSMSDeliveryObject.DeliveryType = Enums.DeliveryTypes.EMail, True, False));
		vQry.SetParameter("qCheckBoth", ?(SelSMSDeliveryObject.DeliveryType = Enums.DeliveryTypes.Unisender Or SelSMSDeliveryObject.DeliveryType = Enums.DeliveryTypes.Both Or SelSMSDeliveryObject.DeliveryType = Enums.DeliveryTypes.DoNotSend, True, False));
		vQry.SetParameter("qClientsWithoutEMailOnly", SelClientsWithoutEMailOnly);
		vQry.SetParameter("qEmptySex", Enums.Sex.EmptyRef());
		vQry.SetParameter("qSex", SelSex);
		vQry.SetParameter("qTagsList", Tags);  
		If ValueIsFilled(SelImportantDateType) Then
			vQry.SetParameter("qImportantDateType", SelImportantDateType);
			If Year(SelImportantDatePeriodFrom) > 1 Then
				vQry.SetParameter("qImportantDateFrom", AddMonth(BegOfDay(SelImportantDatePeriodFrom), -(Year(SelImportantDatePeriodFrom) - 1)*12));
			Else
				vQry.SetParameter("qImportantDateFrom", BegOfDay(SelImportantDatePeriodFrom));
			EndIf;
			If Year(SelImportantDatePeriodTo) > 1 Then
				vQry.SetParameter("qImportantDateTo", AddMonth(BegOfDay(SelImportantDatePeriodTo), -(Year(SelImportantDatePeriodTo) - 1)*12));
			Else
				vQry.SetParameter("qImportantDateTo", BegOfDay(SelImportantDatePeriodTo));
			EndIf;
		EndIf;
	Else
		If Not ChecksOrAndTags Or Not Items.ChecksOrAndTags.Visible Then
			vQry.Text = 
			"SELECT
			|	ActiveGuests.Guest AS Guest
			|INTO ActiveGuests
			|FROM
			|	(SELECT
			|		InHouseGuests.Guest AS Guest
			|	FROM
			|		Document.Accommodation AS InHouseGuests
			|	WHERE
			|		InHouseGuests.Posted
			|		AND InHouseGuests.AccommodationStatus.IsInHouse
			|		AND InHouseGuests.AccommodationStatus.IsActive
			|		AND InHouseGuests.Hotel = &qHotel
			|		AND InHouseGuests.Guest <> &qEmptyGuest
			|		AND NOT InHouseGuests.Guest.DeletionMark
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		ActiveReservations.Guest
			|	FROM
			|		Document.Reservation AS ActiveReservations
			|	WHERE
			|		ActiveReservations.Posted
			|		AND ActiveReservations.ReservationStatus.IsActive
			|		AND ActiveReservations.Hotel = &qHotel
			|		AND ActiveReservations.Guest <> &qEmptyGuest
			|		AND NOT ActiveReservations.Guest.DeletionMark) AS ActiveGuests
			|
			|GROUP BY
			|	ActiveGuests.Guest
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT DISTINCT
			|	Docs.Ref AS Ref,
			|	Docs.Ref.GuestGroup AS GuestGroup,
			|	Docs.Guest AS Guest,
			|	Docs.Guest.Language AS Language,
			|	Docs.Phone AS Phone,
			|	Docs.EMail AS EMail,
			|	Docs.GuestFullName AS GuestFullName
			|FROM
			|	(SELECT
			|		Accommodation.Ref AS Ref,
			|		Accommodation.Guest AS Guest,
			|		CASE
			|			WHEN Accommodation.Guest.Phone <> &qEmptyString
			|				THEN Accommodation.Guest.Phone
			|			WHEN Accommodation.Phone <> &qEmptyString
			|				THEN Accommodation.Phone
			|			ELSE &qEmptyString
			|		END AS Phone,
			|		CASE
			|			WHEN Accommodation.Guest.EMail <> &qEmptyString
			|				THEN Accommodation.Guest.EMail
			|			WHEN Accommodation.EMail <> &qEmptyString
			|				THEN Accommodation.EMail
			|			ELSE &qEmptyString
			|		END AS EMail,
			|		Accommodation.Guest.FullName AS GuestFullName
			|	FROM
			|		Document.Accommodation AS Accommodation
			|	WHERE
			|		Accommodation.Posted
			|		AND NOT &qExpectedOnly
			|		AND (NOT &qByReservation
			|				OR &qByReservation
			|					AND Accommodation.IsByReservation)
			|		AND (NOT &qNoReservation
			|				OR &qNoReservation
			|					AND NOT Accommodation.IsByReservation)
			|		AND (NOT &qInHouseOnly
			|				OR &qInHouseOnly
			|					AND Accommodation.AccommodationStatus.IsInHouse)
			|		AND (NOT &qCheckedOutOnly
			|				OR &qCheckedOutOnly
			|					AND NOT Accommodation.AccommodationStatus.IsInHouse)
			|		AND (NOT &qNoCustomer
			|				OR &qNoCustomer
			|					AND Accommodation.Customer = &qEmptyCustomer)
			|		AND Accommodation.AccommodationStatus.IsActive
			|		AND (NOT &qNotInHouseAndWithoutActiveReservationOnly
			|				OR &qNotInHouseAndWithoutActiveReservationOnly
			|					AND NOT Accommodation.Guest IN
			|							(SELECT
			|								ActiveGuests.Guest
			|							FROM
			|								ActiveGuests AS ActiveGuests))
			|		AND Accommodation.Hotel = &qHotel
			|		AND (&qCheckIntersection
			|					AND Accommodation.CheckInDate < &qPeriodTo
			|					AND Accommodation.CheckOutDate > &qPeriodFrom
			|				OR &qCheckCheckIn
			|					AND Accommodation.CheckInDate >= &qPeriodFrom
			|					AND Accommodation.CheckInDate < &qPeriodTo
			|				OR &qCheckCheckOut
			|					AND Accommodation.CheckOutDate > &qPeriodFrom
			|					AND Accommodation.CheckOutDate <= &qPeriodTo)
			|		AND Accommodation.Guest <> &qEmptyGuest
			|		AND (Accommodation.Guest.Phone <> &qEmptyString
			|					AND NOT &qCheckEMail
			|					AND NOT &qCheckBoth
			|				OR Accommodation.Phone <> &qEmptyString
			|					AND NOT &qCheckEMail
			|					AND NOT &qCheckBoth
			|				OR Accommodation.Guest.EMail <> &qEmptyString
			|					AND &qCheckEMail
			|					AND NOT &qCheckBoth
			|				OR Accommodation.EMail <> &qEmptyString
			|					AND &qCheckEMail
			|					AND NOT &qCheckBoth
			|				OR &qCheckBoth
			|					AND (Accommodation.Guest.Phone <> &qEmptyString
			|						OR Accommodation.Guest.EMail <> &qEmptyString)
			|				OR &qCheckBoth
			|					AND (Accommodation.Phone <> &qEmptyString
			|						OR Accommodation.EMail <> &qEmptyString))
			|		AND NOT Accommodation.Guest.NoSMSDelivery
			|		AND NOT Accommodation.Guest.DeletionMark
			|		AND (NOT &qCustomerIsEmpty
			|					AND Accommodation.Customer <> &qEmptyCustomer
			|					AND Accommodation.Customer IN HIERARCHY (&qCustomer)
			|				OR &qCustomerIsEmpty)
			|		AND (NOT &qContractIsEmpty
			|					AND Accommodation.Contract = &qContract
			|				OR &qContractIsEmpty)
			|		AND (NOT &qCustomerTypeIsEmpty
			|					AND NOT Accommodation.Customer.CustomerType IS NULL
			|					AND Accommodation.Customer.CustomerType <> &qEmptyCustomerType
			|					AND Accommodation.Customer.CustomerType IN HIERARCHY (&qCustomerType)
			|				OR &qCustomerTypeIsEmpty)
			|		AND (NOT &qEventIsEmpty
			|					AND NOT Accommodation.GuestGroup.Event IS NULL
			|					AND Accommodation.GuestGroup.Event <> &qEmptyEvent
			|					AND Accommodation.GuestGroup.Event IN HIERARCHY (&qEvent)
			|				OR &qEventIsEmpty)
			|		AND (NOT &qGuestGroupIsEmpty
			|					AND Accommodation.GuestGroup = &qGuestGroup
			|				OR &qGuestGroupIsEmpty)
			|		AND (NOT &qClientTypeIsEmpty
			|					AND NOT Accommodation.Guest.ClientType IS NULL
			|					AND Accommodation.Guest.ClientType <> &qEmptyClientType
			|					AND Accommodation.Guest.ClientType IN HIERARCHY (&qClientType)
			|				OR &qClientTypeIsEmpty)
			|		AND (NOT &qDiscountTypeIsEmpty
			|					AND Accommodation.DiscountType <> &qEmptyDiscountType
			|					AND Accommodation.DiscountType IN HIERARCHY (&qDiscountType)
			|				OR NOT &qDiscountTypeIsEmpty
			|					AND NOT Accommodation.Guest.DiscountType IS NULL
			|					AND Accommodation.Guest.DiscountType <> &qEmptyDiscountType
			|					AND Accommodation.Guest.DiscountType IN HIERARCHY (&qDiscountType)
			|				OR &qDiscountTypeIsEmpty)
			|		AND (NOT &qMarketingCodeIsEmpty
			|					AND Accommodation.MarketingCode <> &qEmptyMarketingCode
			|					AND Accommodation.MarketingCode IN HIERARCHY (&qMarketingCode)
			|				OR &qMarketingCodeIsEmpty)
			|		AND (NOT &qSourceOfBusinessIsEmpty
			|					AND Accommodation.SourceOfBusiness <> &qEmptySourceOfBusiness
			|					AND Accommodation.SourceOfBusiness IN HIERARCHY (&qSourceOfBusiness)
			|				OR &qSourceOfBusinessIsEmpty)
			|		AND (NOT &qTripPurposeIsEmpty
			|					AND Accommodation.TripPurpose <> &qEmptyTripPurpose
			|					AND Accommodation.TripPurpose IN HIERARCHY (&qTripPurpose)
			|				OR &qTripPurposeIsEmpty)
			|		AND (NOT &qRoomRateIsEmpty
			|					AND Accommodation.RoomRate <> &qEmptyRoomRate
			|					AND Accommodation.RoomRate IN HIERARCHY (&qRoomRate)
			|				OR &qRoomRateIsEmpty)
			|		AND (NOT &qRoomRateTypeIsEmpty
			|					AND NOT Accommodation.RoomRate.RoomRateType IS NULL
			|					AND Accommodation.RoomRate.RoomRateType <> &qEmptyRoomRateType
			|					AND Accommodation.RoomRate.RoomRateType IN HIERARCHY (&qRoomRateType)
			|				OR &qRoomRateTypeIsEmpty)
			|		AND (NOT &qRoomIsEmpty
			|					AND Accommodation.Room <> &qEmptyRoom
			|					AND Accommodation.Room IN HIERARCHY (&qRoom)
			|				OR &qRoomIsEmpty)
			|		AND (NOT &qRoomTypeIsEmpty
			|					AND Accommodation.RoomType <> &qEmptyRoomType
			|					AND Accommodation.RoomType IN HIERARCHY (&qRoomType)
			|				OR &qRoomTypeIsEmpty)
			|		AND (NOT &qCountryIsEmpty
			|					AND NOT Accommodation.Guest.Citizenship IS NULL
			|					AND Accommodation.Guest.Citizenship <> &qEmptyCountry
			|					AND Accommodation.Guest.Citizenship IN HIERARCHY (&qCountry)
			|				OR &qCountryIsEmpty)
			|		AND (NOT &qAgeRangeIsEmpty
			|					AND Accommodation.Guest.AgeRange = &qAgeRange
			|				OR &qAgeRangeIsEmpty)
			|		AND (NOT &qRegionIsEmpty
			|					AND Accommodation.Guest.Address LIKE &qRegion
			|				OR &qRegionIsEmpty)
			|		AND Accommodation.Guest.Age >= &qAgeFrom
			|		AND Accommodation.Guest.Age <= &qAgeTo
			|		AND (&qClientsWithoutEMailOnly
			|					AND Accommodation.Guest.EMail = &qEmptyString
			|				OR NOT &qClientsWithoutEMailOnly)
			|		AND (NOT &qCheckBirthDay
			|				OR &qCheckBirthDay
			|					AND Accommodation.Guest.DateOfBirth > &qEmptyDate
			|					AND (YEAR(&qBirthDayPeriodTo) = YEAR(&qBirthDayPeriodFrom)
			|							AND MONTH(Accommodation.Guest.DateOfBirth) * 100 + DAY(Accommodation.Guest.DateOfBirth) >= MONTH(&qBirthDayPeriodFrom) * 100 + DAY(&qBirthDayPeriodFrom)
			|							AND MONTH(Accommodation.Guest.DateOfBirth) * 100 + DAY(Accommodation.Guest.DateOfBirth) <= MONTH(&qBirthDayPeriodTo) * 100 + DAY(&qBirthDayPeriodTo)
			|						OR YEAR(&qBirthDayPeriodTo) <> YEAR(&qBirthDayPeriodFrom)
			|							AND (MONTH(Accommodation.Guest.DateOfBirth) * 100 + DAY(Accommodation.Guest.DateOfBirth) >= MONTH(&qBirthDayPeriodFrom) * 100 + DAY(&qBirthDayPeriodFrom)
			|									AND MONTH(Accommodation.Guest.DateOfBirth) * 100 + DAY(Accommodation.Guest.DateOfBirth) <= 1231
			|								OR MONTH(Accommodation.Guest.DateOfBirth) * 100 + DAY(Accommodation.Guest.DateOfBirth) <= MONTH(&qBirthDayPeriodTo) * 100 + DAY(&qBirthDayPeriodTo)
			|									AND MONTH(Accommodation.Guest.DateOfBirth) * 100 + DAY(Accommodation.Guest.DateOfBirth) >= 101)))
			|		AND CASE
			|				WHEN &qEmptySex <> &qSex
			|					THEN Accommodation.Guest.Sex = &qSex
			|				ELSE TRUE
			|			END
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		Reservation.Ref,
			|		Reservation.Guest,
			|		CASE
			|			WHEN Reservation.Guest.Phone <> &qEmptyString
			|				THEN Reservation.Guest.Phone
			|			WHEN Reservation.Phone <> &qEmptyString
			|				THEN Reservation.Phone
			|			ELSE &qEmptyString
			|		END,
			|		CASE
			|			WHEN Reservation.Guest.EMail <> &qEmptyString
			|				THEN Reservation.Guest.EMail
			|			WHEN Reservation.EMail <> &qEmptyString
			|				THEN Reservation.EMail
			|			ELSE &qEmptyString
			|		END,
			|		Reservation.Guest.FullName
			|	FROM
			|		Document.Reservation AS Reservation
			|	WHERE
			|		&qCheckReservations
			|		AND NOT &qInHouseOnly
			|		AND NOT &qCheckedOutOnly
			|		AND NOT &qNoReservation
			|		AND (NOT &qNoCustomer
			|				OR &qNoCustomer
			|					AND Reservation.Customer = &qEmptyCustomer)
			|		AND Reservation.Posted
			|		AND Reservation.ReservationStatus.IsActive
			|		AND Reservation.Hotel = &qHotel
			|		AND (&qCheckIntersection
			|					AND Reservation.CheckInDate < &qPeriodTo
			|					AND Reservation.CheckOutDate > &qPeriodFrom
			|				OR &qCheckCheckIn
			|					AND Reservation.CheckInDate >= &qPeriodFrom
			|					AND Reservation.CheckInDate < &qPeriodTo
			|				OR &qCheckCheckOut
			|					AND Reservation.CheckOutDate > &qPeriodFrom
			|					AND Reservation.CheckOutDate <= &qPeriodTo)
			|		AND (Reservation.Guest.Phone <> &qEmptyString
			|					AND NOT &qCheckEMail
			|					AND NOT &qCheckBoth
			|				OR Reservation.Phone <> &qEmptyString
			|					AND NOT &qCheckEMail
			|					AND NOT &qCheckBoth
			|				OR Reservation.Guest.EMail <> &qEmptyString
			|					AND &qCheckEMail
			|					AND NOT &qCheckBoth
			|				OR Reservation.EMail <> &qEmptyString
			|					AND &qCheckEMail
			|					AND NOT &qCheckBoth
			|				OR &qCheckBoth
			|					AND (Reservation.Guest.Phone <> &qEmptyString
			|						OR Reservation.Guest.EMail <> &qEmptyString)
			|				OR &qCheckBoth
			|					AND (Reservation.Phone <> &qEmptyString
			|						OR Reservation.EMail <> &qEmptyString))
			|		AND NOT Reservation.Guest.NoSMSDelivery
			|		AND NOT Reservation.Guest.DeletionMark
			|		AND (NOT &qCustomerIsEmpty
			|					AND Reservation.Customer <> &qEmptyCustomer
			|					AND Reservation.Customer IN HIERARCHY (&qCustomer)
			|				OR &qCustomerIsEmpty)
			|		AND (NOT &qContractIsEmpty
			|					AND Reservation.Contract = &qContract
			|				OR &qContractIsEmpty)
			|		AND (NOT &qCustomerTypeIsEmpty
			|					AND NOT Reservation.Customer.CustomerType IS NULL
			|					AND Reservation.Customer.CustomerType <> &qEmptyCustomerType
			|					AND Reservation.Customer.CustomerType IN HIERARCHY (&qCustomerType)
			|				OR &qCustomerTypeIsEmpty)
			|		AND (NOT &qEventIsEmpty
			|					AND NOT Reservation.GuestGroup.Event IS NULL
			|					AND Reservation.GuestGroup.Event <> &qEmptyEvent
			|					AND Reservation.GuestGroup.Event IN HIERARCHY (&qEvent)
			|				OR &qEventIsEmpty)
			|		AND (NOT &qGuestGroupIsEmpty
			|					AND Reservation.GuestGroup = &qGuestGroup
			|				OR &qGuestGroupIsEmpty)
			|		AND (NOT &qClientTypeIsEmpty
			|					AND NOT Reservation.Guest.ClientType IS NULL
			|					AND Reservation.Guest.ClientType <> &qEmptyClientType
			|					AND Reservation.Guest.ClientType IN HIERARCHY (&qClientType)
			|				OR &qClientTypeIsEmpty)
			|		AND (NOT &qDiscountTypeIsEmpty
			|					AND Reservation.DiscountType <> &qEmptyDiscountType
			|					AND Reservation.DiscountType IN HIERARCHY (&qDiscountType)
			|				OR NOT &qDiscountTypeIsEmpty
			|					AND NOT Reservation.Guest.DiscountType IS NULL
			|					AND Reservation.Guest.DiscountType <> &qEmptyDiscountType
			|					AND Reservation.Guest.DiscountType IN HIERARCHY (&qDiscountType)
			|				OR &qDiscountTypeIsEmpty)
			|		AND (NOT &qMarketingCodeIsEmpty
			|					AND Reservation.MarketingCode <> &qEmptyMarketingCode
			|					AND Reservation.MarketingCode IN HIERARCHY (&qMarketingCode)
			|				OR &qMarketingCodeIsEmpty)
			|		AND (NOT &qSourceOfBusinessIsEmpty
			|					AND Reservation.SourceOfBusiness <> &qEmptySourceOfBusiness
			|					AND Reservation.SourceOfBusiness IN HIERARCHY (&qSourceOfBusiness)
			|				OR &qSourceOfBusinessIsEmpty)
			|		AND (NOT &qTripPurposeIsEmpty
			|					AND Reservation.TripPurpose <> &qEmptyTripPurpose
			|					AND Reservation.TripPurpose IN HIERARCHY (&qTripPurpose)
			|				OR &qTripPurposeIsEmpty)
			|		AND (NOT &qRoomRateIsEmpty
			|					AND Reservation.RoomRate <> &qEmptyRoomRate
			|					AND Reservation.RoomRate IN HIERARCHY (&qRoomRate)
			|				OR &qRoomRateIsEmpty)
			|		AND (NOT &qRoomRateTypeIsEmpty
			|					AND NOT Reservation.RoomRate.RoomRateType IS NULL
			|					AND Reservation.RoomRate.RoomRateType <> &qEmptyRoomRateType
			|					AND Reservation.RoomRate.RoomRateType IN HIERARCHY (&qRoomRateType)
			|				OR &qRoomRateTypeIsEmpty)
			|		AND (NOT &qRoomIsEmpty
			|					AND Reservation.Room <> &qEmptyRoom
			|					AND Reservation.Room IN HIERARCHY (&qRoom)
			|				OR &qRoomIsEmpty)
			|		AND (NOT &qRoomTypeIsEmpty
			|					AND Reservation.RoomType <> &qEmptyRoomType
			|					AND Reservation.RoomType IN HIERARCHY (&qRoomType)
			|				OR &qRoomTypeIsEmpty)
			|		AND (NOT &qCountryIsEmpty
			|					AND NOT Reservation.Guest.Citizenship IS NULL
			|					AND Reservation.Guest.Citizenship <> &qEmptyCountry
			|					AND Reservation.Guest.Citizenship IN HIERARCHY (&qCountry)
			|				OR &qCountryIsEmpty)
			|		AND (NOT &qAgeRangeIsEmpty
			|					AND Reservation.Guest.AgeRange = &qAgeRange
			|				OR &qAgeRangeIsEmpty)
			|		AND (NOT &qRegionIsEmpty
			|					AND Reservation.Guest.Address LIKE &qRegion
			|				OR &qRegionIsEmpty)
			|		AND NOT &qNotInHouseAndWithoutActiveReservationOnly
			|		AND Reservation.Guest.Age >= &qAgeFrom
			|		AND Reservation.Guest.Age <= &qAgeTo
			|		AND (&qClientsWithoutEMailOnly
			|					AND Reservation.Guest.EMail = &qEmptyString
			|				OR NOT &qClientsWithoutEMailOnly)
			|		AND (NOT &qCheckBirthDay
			|				OR &qCheckBirthDay
			|					AND Reservation.Guest.DateOfBirth > &qEmptyDate
			|					AND (YEAR(&qBirthDayPeriodTo) = YEAR(&qBirthDayPeriodFrom)
			|							AND MONTH(Reservation.Guest.DateOfBirth) * 100 + DAY(Reservation.Guest.DateOfBirth) >= MONTH(&qBirthDayPeriodFrom) * 100 + DAY(&qBirthDayPeriodFrom)
			|							AND MONTH(Reservation.Guest.DateOfBirth) * 100 + DAY(Reservation.Guest.DateOfBirth) <= MONTH(&qBirthDayPeriodTo) * 100 + DAY(&qBirthDayPeriodTo)
			|						OR YEAR(&qBirthDayPeriodTo) <> YEAR(&qBirthDayPeriodFrom)
			|							AND (MONTH(Reservation.Guest.DateOfBirth) * 100 + DAY(Reservation.Guest.DateOfBirth) >= MONTH(&qBirthDayPeriodFrom) * 100 + DAY(&qBirthDayPeriodFrom)
			|									AND MONTH(Reservation.Guest.DateOfBirth) * 100 + DAY(Reservation.Guest.DateOfBirth) <= 1231
			|								OR MONTH(Reservation.Guest.DateOfBirth) * 100 + DAY(Reservation.Guest.DateOfBirth) <= MONTH(&qBirthDayPeriodTo) * 100 + DAY(&qBirthDayPeriodTo)
			|									AND MONTH(Reservation.Guest.DateOfBirth) * 100 + DAY(Reservation.Guest.DateOfBirth) >= 101)))
			|		AND CASE
			|				WHEN &qEmptySex <> &qSex
			|					THEN Reservation.Guest.Sex = &qSex
			|				ELSE TRUE
			|			END) AS Docs " + 
			?(Tags.Count() > 0, 
		    "	INNER JOIN InformationRegister.ClientTags AS ClientTags
			|		ON Docs.Guest = ClientTags.Client
			|			AND (ClientTags.Tag IN (&qTagsList)) ", "") +  
			?(ValueIsFilled(SelImportantDateType), 
		    "		INNER JOIN InformationRegister.ClientImportantDates AS ClientImportantDates
			|		ON Docs.Guest = ClientImportantDates.Guest
			|			AND (ClientImportantDates.ImportantDateType = &qImportantDateType)
			|			AND (ClientImportantDates.Date > &qEmptyDate)
			|			AND (BEGINOFPERIOD(DATEADD(ClientImportantDates.Date, YEAR, -(YEAR(ClientImportantDates.Date) - 1)), DAY) >= &qImportantDateFrom)
			|			AND (BEGINOFPERIOD(DATEADD(ClientImportantDates.Date, YEAR, -(YEAR(ClientImportantDates.Date) - 1)), DAY) <= &qImportantDateTo)", "") + "
			|
			|ORDER BY
			|	Docs.GuestFullName";
		Else
			vQry.Text = 
			"SELECT
			|	ActiveGuests.Guest AS Guest
			|INTO ActiveGuests
			|FROM
			|	(SELECT
			|		InHouseGuests.Guest AS Guest
			|	FROM
			|		Document.Accommodation AS InHouseGuests
			|	WHERE
			|		InHouseGuests.Posted
			|		AND InHouseGuests.AccommodationStatus.IsInHouse
			|		AND InHouseGuests.AccommodationStatus.IsActive
			|		AND InHouseGuests.Hotel = &qHotel
			|		AND InHouseGuests.Guest <> &qEmptyGuest
			|		AND NOT InHouseGuests.Guest.DeletionMark
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		ActiveReservations.Guest
			|	FROM
			|		Document.Reservation AS ActiveReservations
			|	WHERE
			|		ActiveReservations.Posted
			|		AND ActiveReservations.ReservationStatus.IsActive
			|		AND ActiveReservations.Hotel = &qHotel
			|		AND ActiveReservations.Guest <> &qEmptyGuest
			|		AND NOT ActiveReservations.Guest.DeletionMark) AS ActiveGuests
			|
			|GROUP BY
			|	ActiveGuests.Guest
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Docs.Ref AS Ref,
			|	Docs.Ref.GuestGroup AS GuestGroup,
			|	Docs.Guest AS Guest,
			|	Docs.Guest.Language AS Language,
			|	Docs.Phone AS Phone,
			|	Docs.EMail AS EMail,
			|	Docs.GuestFullName AS GuestFullName,
			|	SUM(Docs.TagCount) AS TagCount
			|FROM
			|	(SELECT
			|		DocsWithTags.Ref AS Ref,
			|		DocsWithTags.Guest AS Guest,
			|		DocsWithTags.Phone AS Phone,
			|		DocsWithTags.EMail AS EMail,
			|		DocsWithTags.GuestFullName AS GuestFullName,
			|		ClientTags.Tag AS Tag,
			|		1 AS TagCount
			|	FROM
			|		(SELECT
			|			Accommodation.Ref AS Ref,
			|			Accommodation.Guest AS Guest,
			|			CASE
			|				WHEN Accommodation.Guest.Phone <> &qEmptyString
			|					THEN Accommodation.Guest.Phone
			|				WHEN Accommodation.Phone <> &qEmptyString
			|					THEN Accommodation.Phone
			|				ELSE &qEmptyString
			|			END AS Phone,
			|			CASE
			|				WHEN Accommodation.Guest.EMail <> &qEmptyString
			|					THEN Accommodation.Guest.EMail
			|				WHEN Accommodation.EMail <> &qEmptyString
			|					THEN Accommodation.EMail
			|				ELSE &qEmptyString
			|			END AS EMail,
			|			Accommodation.Guest.FullName AS GuestFullName
			|		FROM
			|			Document.Accommodation AS Accommodation
			|		WHERE
			|			Accommodation.Posted
			|			AND NOT &qExpectedOnly
			|			AND (NOT &qByReservation
			|					OR &qByReservation
			|						AND Accommodation.IsByReservation)
			|			AND (NOT &qNoReservation
			|					OR &qNoReservation
			|						AND NOT Accommodation.IsByReservation)
			|			AND (NOT &qInHouseOnly
			|					OR &qInHouseOnly
			|						AND Accommodation.AccommodationStatus.IsInHouse)
			|			AND (NOT &qCheckedOutOnly
			|					OR &qCheckedOutOnly
			|						AND NOT Accommodation.AccommodationStatus.IsInHouse)
			|			AND (NOT &qNoCustomer
			|					OR &qNoCustomer
			|						AND Accommodation.Customer = &qEmptyCustomer)
			|			AND Accommodation.AccommodationStatus.IsActive
			|			AND (NOT &qNotInHouseAndWithoutActiveReservationOnly
			|					OR &qNotInHouseAndWithoutActiveReservationOnly
			|						AND NOT Accommodation.Guest IN
			|								(SELECT
			|									ActiveGuests.Guest
			|								FROM
			|									ActiveGuests AS ActiveGuests))
			|			AND Accommodation.Hotel = &qHotel
			|			AND (&qCheckIntersection
			|						AND Accommodation.CheckInDate < &qPeriodTo
			|						AND Accommodation.CheckOutDate > &qPeriodFrom
			|					OR &qCheckCheckIn
			|						AND Accommodation.CheckInDate >= &qPeriodFrom
			|						AND Accommodation.CheckInDate < &qPeriodTo
			|					OR &qCheckCheckOut
			|						AND Accommodation.CheckOutDate > &qPeriodFrom
			|						AND Accommodation.CheckOutDate <= &qPeriodTo)
			|			AND Accommodation.Guest <> &qEmptyGuest
			|			AND (Accommodation.Guest.Phone <> &qEmptyString
			|						AND NOT &qCheckEMail
			|						AND NOT &qCheckBoth
			|					OR Accommodation.Phone <> &qEmptyString
			|						AND NOT &qCheckEMail
			|						AND NOT &qCheckBoth
			|					OR Accommodation.Guest.EMail <> &qEmptyString
			|						AND &qCheckEMail
			|						AND NOT &qCheckBoth
			|					OR Accommodation.EMail <> &qEmptyString
			|						AND &qCheckEMail
			|						AND NOT &qCheckBoth
			|					OR &qCheckBoth
			|						AND (Accommodation.Guest.Phone <> &qEmptyString
			|							OR Accommodation.Guest.EMail <> &qEmptyString)
			|					OR &qCheckBoth
			|						AND (Accommodation.Phone <> &qEmptyString
			|							OR Accommodation.EMail <> &qEmptyString))
			|			AND NOT Accommodation.Guest.NoSMSDelivery
			|			AND NOT Accommodation.Guest.DeletionMark
			|			AND (NOT &qCustomerIsEmpty
			|						AND Accommodation.Customer <> &qEmptyCustomer
			|						AND Accommodation.Customer IN HIERARCHY (&qCustomer)
			|					OR &qCustomerIsEmpty)
			|			AND (NOT &qContractIsEmpty
			|						AND Accommodation.Contract = &qContract
			|					OR &qContractIsEmpty)
			|			AND (NOT &qCustomerTypeIsEmpty
			|						AND NOT Accommodation.Customer.CustomerType IS NULL
			|						AND Accommodation.Customer.CustomerType <> &qEmptyCustomerType
			|						AND Accommodation.Customer.CustomerType IN HIERARCHY (&qCustomerType)
			|					OR &qCustomerTypeIsEmpty)
			|			AND (NOT &qEventIsEmpty
			|						AND NOT Accommodation.GuestGroup.Event IS NULL
			|						AND Accommodation.GuestGroup.Event <> &qEmptyEvent
			|						AND Accommodation.GuestGroup.Event IN HIERARCHY (&qEvent)
			|					OR &qEventIsEmpty)
			|			AND (NOT &qGuestGroupIsEmpty
			|						AND Accommodation.GuestGroup = &qGuestGroup
			|					OR &qGuestGroupIsEmpty)
			|			AND (NOT &qClientTypeIsEmpty
			|						AND NOT Accommodation.Guest.ClientType IS NULL
			|						AND Accommodation.Guest.ClientType <> &qEmptyClientType
			|						AND Accommodation.Guest.ClientType IN HIERARCHY (&qClientType)
			|					OR &qClientTypeIsEmpty)
			|			AND (NOT &qDiscountTypeIsEmpty
			|						AND Accommodation.DiscountType <> &qEmptyDiscountType
			|						AND Accommodation.DiscountType IN HIERARCHY (&qDiscountType)
			|					OR NOT &qDiscountTypeIsEmpty
			|						AND NOT Accommodation.Guest.DiscountType IS NULL
			|						AND Accommodation.Guest.DiscountType <> &qEmptyDiscountType
			|						AND Accommodation.Guest.DiscountType IN HIERARCHY (&qDiscountType)
			|					OR &qDiscountTypeIsEmpty)
			|			AND (NOT &qMarketingCodeIsEmpty
			|						AND Accommodation.MarketingCode <> &qEmptyMarketingCode
			|						AND Accommodation.MarketingCode IN HIERARCHY (&qMarketingCode)
			|					OR &qMarketingCodeIsEmpty)
			|			AND (NOT &qSourceOfBusinessIsEmpty
			|						AND Accommodation.SourceOfBusiness <> &qEmptySourceOfBusiness
			|						AND Accommodation.SourceOfBusiness IN HIERARCHY (&qSourceOfBusiness)
			|					OR &qSourceOfBusinessIsEmpty)
			|			AND (NOT &qTripPurposeIsEmpty
			|						AND Accommodation.TripPurpose <> &qEmptyTripPurpose
			|						AND Accommodation.TripPurpose IN HIERARCHY (&qTripPurpose)
			|					OR &qTripPurposeIsEmpty)
			|			AND (NOT &qRoomRateIsEmpty
			|						AND Accommodation.RoomRate <> &qEmptyRoomRate
			|						AND Accommodation.RoomRate IN HIERARCHY (&qRoomRate)
			|					OR &qRoomRateIsEmpty)
			|			AND (NOT &qRoomRateTypeIsEmpty
			|						AND NOT Accommodation.RoomRate.RoomRateType IS NULL
			|						AND Accommodation.RoomRate.RoomRateType <> &qEmptyRoomRateType
			|						AND Accommodation.RoomRate.RoomRateType IN HIERARCHY (&qRoomRateType)
			|					OR &qRoomRateTypeIsEmpty)
			|			AND (NOT &qRoomIsEmpty
			|						AND Accommodation.Room <> &qEmptyRoom
			|						AND Accommodation.Room IN HIERARCHY (&qRoom)
			|					OR &qRoomIsEmpty)
			|			AND (NOT &qRoomTypeIsEmpty
			|						AND Accommodation.RoomType <> &qEmptyRoomType
			|						AND Accommodation.RoomType IN HIERARCHY (&qRoomType)
			|					OR &qRoomTypeIsEmpty)
			|			AND (NOT &qCountryIsEmpty
			|						AND NOT Accommodation.Guest.Citizenship IS NULL
			|						AND Accommodation.Guest.Citizenship <> &qEmptyCountry
			|						AND Accommodation.Guest.Citizenship IN HIERARCHY (&qCountry)
			|					OR &qCountryIsEmpty)
			|			AND (NOT &qAgeRangeIsEmpty
			|						AND Accommodation.Guest.AgeRange = &qAgeRange
			|					OR &qAgeRangeIsEmpty)
			|			AND (NOT &qRegionIsEmpty
			|						AND Accommodation.Guest.Address LIKE &qRegion
			|					OR &qRegionIsEmpty)
			|			AND Accommodation.Guest.Age >= &qAgeFrom
			|			AND Accommodation.Guest.Age <= &qAgeTo
			|			AND (&qClientsWithoutEMailOnly
			|						AND Accommodation.Guest.EMail = &qEmptyString
			|					OR NOT &qClientsWithoutEMailOnly)
			|			AND (NOT &qCheckBirthDay
			|					OR &qCheckBirthDay
			|						AND Accommodation.Guest.DateOfBirth > &qEmptyDate
			|						AND (YEAR(&qBirthDayPeriodTo) = YEAR(&qBirthDayPeriodFrom)
			|								AND MONTH(Accommodation.Guest.DateOfBirth) * 100 + DAY(Accommodation.Guest.DateOfBirth) >= MONTH(&qBirthDayPeriodFrom) * 100 + DAY(&qBirthDayPeriodFrom)
			|								AND MONTH(Accommodation.Guest.DateOfBirth) * 100 + DAY(Accommodation.Guest.DateOfBirth) <= MONTH(&qBirthDayPeriodTo) * 100 + DAY(&qBirthDayPeriodTo)
			|							OR YEAR(&qBirthDayPeriodTo) <> YEAR(&qBirthDayPeriodFrom)
			|								AND (MONTH(Accommodation.Guest.DateOfBirth) * 100 + DAY(Accommodation.Guest.DateOfBirth) >= MONTH(&qBirthDayPeriodFrom) * 100 + DAY(&qBirthDayPeriodFrom)
			|										AND MONTH(Accommodation.Guest.DateOfBirth) * 100 + DAY(Accommodation.Guest.DateOfBirth) <= 1231
			|									OR MONTH(Accommodation.Guest.DateOfBirth) * 100 + DAY(Accommodation.Guest.DateOfBirth) <= MONTH(&qBirthDayPeriodTo) * 100 + DAY(&qBirthDayPeriodTo)
			|										AND MONTH(Accommodation.Guest.DateOfBirth) * 100 + DAY(Accommodation.Guest.DateOfBirth) >= 101)))
			|			AND CASE
			|					WHEN &qEmptySex <> &qSex
			|						THEN Accommodation.Guest.Sex = &qSex
			|					ELSE TRUE
			|				END
			|		
			|		UNION ALL
			|		
			|		SELECT
			|			Reservation.Ref,
			|			Reservation.Guest,
			|			CASE
			|				WHEN Reservation.Guest.Phone <> &qEmptyString
			|					THEN Reservation.Guest.Phone
			|				WHEN Reservation.Phone <> &qEmptyString
			|					THEN Reservation.Phone
			|				ELSE &qEmptyString
			|			END,
			|			CASE
			|				WHEN Reservation.Guest.EMail <> &qEmptyString
			|					THEN Reservation.Guest.EMail
			|				WHEN Reservation.EMail <> &qEmptyString
			|					THEN Reservation.EMail
			|				ELSE &qEmptyString
			|			END,
			|			Reservation.Guest.FullName
			|		FROM
			|			Document.Reservation AS Reservation
			|		WHERE
			|			&qCheckReservations
			|			AND NOT &qInHouseOnly
			|			AND NOT &qCheckedOutOnly
			|			AND NOT &qNoReservation
			|			AND (NOT &qNoCustomer
			|					OR &qNoCustomer
			|						AND Reservation.Customer = &qEmptyCustomer)
			|			AND Reservation.Posted
			|			AND Reservation.ReservationStatus.IsActive
			|			AND Reservation.Hotel = &qHotel
			|			AND (&qCheckIntersection
			|						AND Reservation.CheckInDate < &qPeriodTo
			|						AND Reservation.CheckOutDate > &qPeriodFrom
			|					OR &qCheckCheckIn
			|						AND Reservation.CheckInDate >= &qPeriodFrom
			|						AND Reservation.CheckInDate < &qPeriodTo
			|					OR &qCheckCheckOut
			|						AND Reservation.CheckOutDate > &qPeriodFrom
			|						AND Reservation.CheckOutDate <= &qPeriodTo)
			|			AND (Reservation.Guest.Phone <> &qEmptyString
			|						AND NOT &qCheckEMail
			|						AND NOT &qCheckBoth
			|					OR Reservation.Phone <> &qEmptyString
			|						AND NOT &qCheckEMail
			|						AND NOT &qCheckBoth
			|					OR Reservation.Guest.EMail <> &qEmptyString
			|						AND &qCheckEMail
			|						AND NOT &qCheckBoth
			|					OR Reservation.EMail <> &qEmptyString
			|						AND &qCheckEMail
			|						AND NOT &qCheckBoth
			|					OR &qCheckBoth
			|						AND (Reservation.Guest.Phone <> &qEmptyString
			|							OR Reservation.Guest.EMail <> &qEmptyString)
			|					OR &qCheckBoth
			|						AND (Reservation.Phone <> &qEmptyString
			|							OR Reservation.EMail <> &qEmptyString))
			|			AND NOT Reservation.Guest.NoSMSDelivery
			|			AND NOT Reservation.Guest.DeletionMark
			|			AND (NOT &qCustomerIsEmpty
			|						AND Reservation.Customer <> &qEmptyCustomer
			|						AND Reservation.Customer IN HIERARCHY (&qCustomer)
			|					OR &qCustomerIsEmpty)
			|			AND (NOT &qContractIsEmpty
			|						AND Reservation.Contract = &qContract
			|					OR &qContractIsEmpty)
			|			AND (NOT &qCustomerTypeIsEmpty
			|						AND NOT Reservation.Customer.CustomerType IS NULL
			|						AND Reservation.Customer.CustomerType <> &qEmptyCustomerType
			|						AND Reservation.Customer.CustomerType IN HIERARCHY (&qCustomerType)
			|					OR &qCustomerTypeIsEmpty)
			|			AND (NOT &qEventIsEmpty
			|						AND NOT Reservation.GuestGroup.Event IS NULL
			|						AND Reservation.GuestGroup.Event <> &qEmptyEvent
			|						AND Reservation.GuestGroup.Event IN HIERARCHY (&qEvent)
			|					OR &qEventIsEmpty)
			|			AND (NOT &qGuestGroupIsEmpty
			|						AND Reservation.GuestGroup = &qGuestGroup
			|					OR &qGuestGroupIsEmpty)
			|			AND (NOT &qClientTypeIsEmpty
			|						AND NOT Reservation.Guest.ClientType IS NULL
			|						AND Reservation.Guest.ClientType <> &qEmptyClientType
			|						AND Reservation.Guest.ClientType IN HIERARCHY (&qClientType)
			|					OR &qClientTypeIsEmpty)
			|			AND (NOT &qDiscountTypeIsEmpty
			|						AND Reservation.DiscountType <> &qEmptyDiscountType
			|						AND Reservation.DiscountType IN HIERARCHY (&qDiscountType)
			|					OR NOT &qDiscountTypeIsEmpty
			|						AND NOT Reservation.Guest.DiscountType IS NULL
			|						AND Reservation.Guest.DiscountType <> &qEmptyDiscountType
			|						AND Reservation.Guest.DiscountType IN HIERARCHY (&qDiscountType)
			|					OR &qDiscountTypeIsEmpty)
			|			AND (NOT &qMarketingCodeIsEmpty
			|						AND Reservation.MarketingCode <> &qEmptyMarketingCode
			|						AND Reservation.MarketingCode IN HIERARCHY (&qMarketingCode)
			|					OR &qMarketingCodeIsEmpty)
			|			AND (NOT &qSourceOfBusinessIsEmpty
			|						AND Reservation.SourceOfBusiness <> &qEmptySourceOfBusiness
			|						AND Reservation.SourceOfBusiness IN HIERARCHY (&qSourceOfBusiness)
			|					OR &qSourceOfBusinessIsEmpty)
			|			AND (NOT &qTripPurposeIsEmpty
			|						AND Reservation.TripPurpose <> &qEmptyTripPurpose
			|						AND Reservation.TripPurpose IN HIERARCHY (&qTripPurpose)
			|					OR &qTripPurposeIsEmpty)
			|			AND (NOT &qRoomRateIsEmpty
			|						AND Reservation.RoomRate <> &qEmptyRoomRate
			|						AND Reservation.RoomRate IN HIERARCHY (&qRoomRate)
			|					OR &qRoomRateIsEmpty)
			|			AND (NOT &qRoomRateTypeIsEmpty
			|						AND NOT Reservation.RoomRate.RoomRateType IS NULL
			|						AND Reservation.RoomRate.RoomRateType <> &qEmptyRoomRateType
			|						AND Reservation.RoomRate.RoomRateType IN HIERARCHY (&qRoomRateType)
			|					OR &qRoomRateTypeIsEmpty)
			|			AND (NOT &qRoomIsEmpty
			|						AND Reservation.Room <> &qEmptyRoom
			|						AND Reservation.Room IN HIERARCHY (&qRoom)
			|					OR &qRoomIsEmpty)
			|			AND (NOT &qRoomTypeIsEmpty
			|						AND Reservation.RoomType <> &qEmptyRoomType
			|						AND Reservation.RoomType IN HIERARCHY (&qRoomType)
			|					OR &qRoomTypeIsEmpty)
			|			AND (NOT &qCountryIsEmpty
			|						AND NOT Reservation.Guest.Citizenship IS NULL
			|						AND Reservation.Guest.Citizenship <> &qEmptyCountry
			|						AND Reservation.Guest.Citizenship IN HIERARCHY (&qCountry)
			|					OR &qCountryIsEmpty)
			|			AND (NOT &qAgeRangeIsEmpty
			|						AND Reservation.Guest.AgeRange = &qAgeRange
			|					OR &qAgeRangeIsEmpty)
			|			AND (NOT &qRegionIsEmpty
			|						AND Reservation.Guest.Address LIKE &qRegion
			|					OR &qRegionIsEmpty)
			|			AND NOT &qNotInHouseAndWithoutActiveReservationOnly
			|			AND Reservation.Guest.Age >= &qAgeFrom
			|			AND Reservation.Guest.Age <= &qAgeTo
			|			AND (&qClientsWithoutEMailOnly
			|						AND Reservation.Guest.EMail = &qEmptyString
			|					OR NOT &qClientsWithoutEMailOnly)
			|			AND (NOT &qCheckBirthDay
			|					OR &qCheckBirthDay
			|						AND Reservation.Guest.DateOfBirth > &qEmptyDate
			|						AND (YEAR(&qBirthDayPeriodTo) = YEAR(&qBirthDayPeriodFrom)
			|								AND MONTH(Reservation.Guest.DateOfBirth) * 100 + DAY(Reservation.Guest.DateOfBirth) >= MONTH(&qBirthDayPeriodFrom) * 100 + DAY(&qBirthDayPeriodFrom)
			|								AND MONTH(Reservation.Guest.DateOfBirth) * 100 + DAY(Reservation.Guest.DateOfBirth) <= MONTH(&qBirthDayPeriodTo) * 100 + DAY(&qBirthDayPeriodTo)
			|							OR YEAR(&qBirthDayPeriodTo) <> YEAR(&qBirthDayPeriodFrom)
			|								AND (MONTH(Reservation.Guest.DateOfBirth) * 100 + DAY(Reservation.Guest.DateOfBirth) >= MONTH(&qBirthDayPeriodFrom) * 100 + DAY(&qBirthDayPeriodFrom)
			|										AND MONTH(Reservation.Guest.DateOfBirth) * 100 + DAY(Reservation.Guest.DateOfBirth) <= 1231
			|									OR MONTH(Reservation.Guest.DateOfBirth) * 100 + DAY(Reservation.Guest.DateOfBirth) <= MONTH(&qBirthDayPeriodTo) * 100 + DAY(&qBirthDayPeriodTo)
			|										AND MONTH(Reservation.Guest.DateOfBirth) * 100 + DAY(Reservation.Guest.DateOfBirth) >= 101)))
			|			AND CASE
			|					WHEN &qEmptySex <> &qSex
			|						THEN Reservation.Guest.Sex = &qSex
			|					ELSE TRUE
			|				END) AS DocsWithTags
			|			INNER JOIN InformationRegister.ClientTags AS ClientTags
			|			ON DocsWithTags.Guest = ClientTags.Client
			|				AND (ClientTags.Tag IN (&qTagsList))) AS Docs" + 
			?(ValueIsFilled(SelImportantDateType), 
		    "		INNER JOIN InformationRegister.ClientImportantDates AS ClientImportantDates
			|		ON DocsWithTags.Guest = ClientImportantDates.Guest
			|			AND (ClientImportantDates.ImportantDateType = &qImportantDateType)
			|			AND (ClientImportantDates.Date > &qEmptyDate)
			|			AND (BEGINOFPERIOD(DATEADD(ClientImportantDates.Date, YEAR, -(YEAR(ClientImportantDates.Date) - 1)), DAY) >= &qImportantDateFrom)
			|			AND (BEGINOFPERIOD(DATEADD(ClientImportantDates.Date, YEAR, -(YEAR(ClientImportantDates.Date) - 1)), DAY) <= &qImportantDateTo)", "") + "
			|
			|GROUP BY
			|	Docs.Ref,
			|	Docs.Ref.GuestGroup,
			|	Docs.Guest,
			|	Docs.Guest.Language,
			|	Docs.Phone,
			|	Docs.EMail,
			|	Docs.GuestFullName
			|
			|HAVING
			|	SUM(Docs.TagCount) = &qTagsCount
			|
			|ORDER BY
			|	Docs.GuestFullName";
			vQry.SetParameter("qTagsCount", Tags.Count());
		EndIf;
		vQry.SetParameter("qHotel", SelHotel);
		vQry.SetParameter("qPeriodFrom", BegOfDay(SelPeriodFrom));
		vQry.SetParameter("qPeriodTo", ?(ValueIsFilled(SelPeriodTo), EndOfDay(SelPeriodTo), '39991231235959'));
		vQry.SetParameter("qCheckIntersection", ?(SelPeriodType = 0, True, False));
		vQry.SetParameter("qCheckCheckIn", ?(SelPeriodType = 1, True, False));
		vQry.SetParameter("qCheckCheckOut", ?(SelPeriodType = 2, True, False));
		vQry.SetParameter("qCheckReservations", ?(ValueIsFilled(SelPeriodTo), ?(BegOfDay(SelPeriodTo) >= BegOfDay(CurrentSessionDate()), True, False), True));
		vQry.SetParameter("qCustomer", SelCustomer);
		vQry.SetParameter("qCustomerIsEmpty", Not ValueIsFilled(SelCustomer));
		vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
		vQry.SetParameter("qContract", SelContract);
		vQry.SetParameter("qContractIsEmpty", Not ValueIsFilled(SelContract));
		vQry.SetParameter("qCustomerType", SelCustomerType);
		vQry.SetParameter("qCustomerTypeIsEmpty", Not ValueIsFilled(SelCustomerType));
		vQry.SetParameter("qEmptyCustomerType", Catalogs.CustomerTypes.EmptyRef());
		vQry.SetParameter("qEvent", SelEvent);
		vQry.SetParameter("qEventIsEmpty", Not ValueIsFilled(SelEvent));
		vQry.SetParameter("qEmptyEvent", Catalogs.Events.EmptyRef());
		vQry.SetParameter("qGuestGroup", SelGuestGroup);
		vQry.SetParameter("qGuestGroupIsEmpty", Not ValueIsFilled(SelGuestGroup));
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
		vQry.SetParameter("qTripPurpose", SelTripPurpose);
		vQry.SetParameter("qTripPurposeIsEmpty", Not ValueIsFilled(SelTripPurpose));
		vQry.SetParameter("qEmptyTripPurpose", Catalogs.TripPurposes.EmptyRef());
		vQry.SetParameter("qRoomRateType", SelRoomRateType);
		vQry.SetParameter("qRoomRateTypeIsEmpty", Not ValueIsFilled(SelRoomRateType));
		vQry.SetParameter("qEmptyRoomRateType", Catalogs.RoomRateTypes.EmptyRef());
		vQry.SetParameter("qRoomRate", SelRoomRate);
		vQry.SetParameter("qRoomRateIsEmpty", Not ValueIsFilled(SelRoomRate));
		vQry.SetParameter("qEmptyRoomRate", Catalogs.RoomRates.EmptyRef());
		vQry.SetParameter("qRoomType", SelRoomType);
		vQry.SetParameter("qRoomTypeIsEmpty", Not ValueIsFilled(SelRoomType));
		vQry.SetParameter("qEmptyRoomType", Catalogs.RoomTypes.EmptyRef());
		vQry.SetParameter("qRoom", SelRoom);
		vQry.SetParameter("qRoomIsEmpty", Not ValueIsFilled(SelRoom));
		vQry.SetParameter("qEmptyRoom", Catalogs.Rooms.EmptyRef());
		vQry.SetParameter("qCountry", SelCountry);
		vQry.SetParameter("qCountryIsEmpty", Not ValueIsFilled(SelCountry));
		vQry.SetParameter("qEmptyCountry", Catalogs.Countries.EmptyRef());
		vQry.SetParameter("qRegion", "%" + TrimAll(SelRegion) + "%");
		vQry.SetParameter("qRegionIsEmpty", IsBlankString(SelRegion));
		vQry.SetParameter("qAgeRange", SelAgeRange);
		vQry.SetParameter("qAgeRangeIsEmpty", Not ValueIsFilled(SelAgeRange));
		vQry.SetParameter("qAgeFrom", SelAgeFrom);
		vQry.SetParameter("qAgeTo", ?(SelAgeTo = 0, 999, SelAgeTo));
		vQry.SetParameter("qCheckBirthDay", ?(ValueIsFilled(SelBirthDayPeriodFrom) And ValueIsFilled(SelBirthDayPeriodTo), True, False));
		vQry.SetParameter("qBirthDayPeriodFrom", vSelBirthDayPeriodFrom);
		vQry.SetParameter("qBirthDayPeriodTo", vSelBirthDayPeriodTo);
		vQry.SetParameter("qEmptyGuest", Catalogs.Clients.EmptyRef());
		vQry.SetParameter("qEmptyString", "");
		vQry.SetParameter("qEmptyDate", '00010101');
		vQry.SetParameter("qCheckEMail", ?(SelSMSDeliveryObject.DeliveryType = Enums.DeliveryTypes.EMail, True, False));
		vQry.SetParameter("qCheckBoth", ?(SelSMSDeliveryObject.DeliveryType = Enums.DeliveryTypes.Unisender Or SelSMSDeliveryObject.DeliveryType = Enums.DeliveryTypes.Both Or SelSMSDeliveryObject.DeliveryType = Enums.DeliveryTypes.DoNotSend, True, False));
		vQry.SetParameter("qNoReservation", SelNoReservation);
		vQry.SetParameter("qByReservation", SelByReservation);
		vQry.SetParameter("qNoCustomer", SelNoCustomer);
		vQry.SetParameter("qInHouseOnly", SelInHouseOnly);
		vQry.SetParameter("qCheckedOutOnly", SelCheckedOutOnly);
		vQry.SetParameter("qExpectedOnly", SelExpectedOnly);
		vQry.SetParameter("qNotInHouseAndWithoutActiveReservationOnly", SelNotInHouseAndWithoutActiveReservationOnly);
		vQry.SetParameter("qClientsWithoutEMailOnly", SelClientsWithoutEMailOnly);
		vQry.SetParameter("qEmptySex", Enums.Sex.EmptyRef());
		vQry.SetParameter("qSex", SelSex);
		vQry.SetParameter("qTagsList", Tags);   
		If ValueIsFilled(SelImportantDateType) Then
			vQry.SetParameter("qImportantDateType", SelImportantDateType);
			If Year(SelImportantDatePeriodFrom) > 1 Then
				vQry.SetParameter("qImportantDateFrom", AddMonth(BegOfDay(SelImportantDatePeriodFrom), -(Year(SelImportantDatePeriodFrom) - 1)*12));
			Else
				vQry.SetParameter("qImportantDateFrom", BegOfDay(SelImportantDatePeriodFrom));
			EndIf;
			If Year(SelImportantDatePeriodTo) > 1 Then
				vQry.SetParameter("qImportantDateTo", AddMonth(BegOfDay(SelImportantDatePeriodTo), -(Year(SelImportantDatePeriodTo) - 1)*12));
			Else
				vQry.SetParameter("qImportantDateTo", BegOfDay(SelImportantDatePeriodTo));
			EndIf;
		EndIf;
	EndIf;
	vResult = vQry.Execute().Unload();
	SelClientsArray.Load(vResult);
	vClientsOnly = New ValueTable();
	vClientsOnly = vResult;
	vClientsOnly.GroupBy("Guest");
	ClientsList.LoadValues(vClientsOnly.UnloadColumn("Guest"));
	// Fill value table with client inventory statistics
	InventoryStats.Clear();
	If SelNumberOfCheckIns > 0 Then
		InventoryStats = GetInventoryStats(ClientsList);
	EndIf;
	// Fill value table with client revenue statistics
	RevenueStats.Clear();
	If SelNumberOfGuestDays > 0 Or SelSalesAmount > 0 Then
		RevenueStats = GetRevenueStats(ClientsList);
	EndIf;
	For Each vClientsRow In SelClientsArray Do
		vPhone = SMS.GetValidPhoneNumber(vClientsRow.Phone);
		vEMail = lower(TrimAll(vClientsRow.EMail));
		// Check if current phone number or e-mail was already processed
		If (SelSMSDeliveryObject.DeliveryType = Enums.DeliveryTypes.EMail Or SelSMSDeliveryObject.DeliveryType = Enums.DeliveryTypes.Both Or SelSMSDeliveryObject.DeliveryType = Enums.DeliveryTypes.Unisender) And pUsedEMails.FindByValue(vEMail) = Undefined Or 
		   (SelSMSDeliveryObject.DeliveryType = Enums.DeliveryTypes.SMS Or SelSMSDeliveryObject.DeliveryType = Enums.DeliveryTypes.Both Or SelSMSDeliveryObject.DeliveryType = Enums.DeliveryTypes.Unisender) And pUsedPhones.FindByValue(vPhone) = Undefined Then
			If Not IsBlankString(vPhone) Then
				pUsedPhones.Add(vPhone);
			EndIf;
			If Not IsBlankString(vEMail) Then
				pUsedEMails.Add(vEMail);
			EndIf;
			// Check complex conditions
			If SelWithBalance And Not GuestHasClientBalance(vClientsRow.Ref) Then
				Continue;
			EndIf;
			If SelNumberOfCheckIns > 0 Or SelNumberOfGuestDays > 0 Or SelSalesAmount > 0 Then
				If Not CheckClientStatistics(InventoryStats, RevenueStats, vClientsRow.Guest) Then
					Continue;
				EndIf;
			EndIf;
			vClientRef = vClientsRow.Guest;
			vClientDoc = vClientsRow.Ref;
			vClientLanguage = vClientsRow.Language;
			vClientGuestGroup = vClientsRow.GuestGroup;
			// Add new SMS message row
			vNothingFound = False;
			vRow = Receivers.Add();
			vRow.Phone = vPhone;
			vRow.EMail = vEMail;
			vRow.Customer = Undefined;
			vRow.Client = vClientRef;
			vRow.ClientDoc = vClientsRow.Ref;
			vRow.SMSText = SMS.ReplaceSMSParameters(GetTemplateText(vClientLanguage), vClientDoc, vClientRef, , , vClientLanguage, vClientGuestGroup);
			vRow.NumberOfSMS = SMS.GetNumberOfSegments(vRow.SMSText);
			vRow.MessageLength = Format(StrLen(vRow.SMSText), "ND=10; NFD=0; NG=");
			vRow.IsSent = False;
			vRow.Result = "";
			vRow.MessageID = "";		
		EndIf;
	EndDo;
	Return vNothingFound;
EndFunction

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
		// Run query to get appropriate clients
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
			ShowMessageBox(, NStr("en='No clients found according to your search conditions!';ru='Не найдено клиентов удовлетворяющих указанным условиям отбора!';de='Kunden, die den angegebenen Auswahlkriterien entsprechen, wurden nicht gefunden!'"));
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
Function GetInventoryStats(pClientsList)
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInventory.Guest AS Client,
	|	SUM(ISNULL(RoomInventory.GuestsCheckedIn, 0)) AS GuestsCheckedIn
	|FROM
	|	AccumulationRegister.RoomInventory AS RoomInventory
	|WHERE
	|	RoomInventory.Guest IN(&qClientsList)
	|	AND RoomInventory.IsAccommodation
	|	AND RoomInventory.Period >= &qPeriodFrom
	|	AND RoomInventory.Period <= &qPeriodTo
	|	AND RoomInventory.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND RoomInventory.Period = RoomInventory.PeriodFrom
	|
	|GROUP BY
	|	RoomInventory.Guest";
	vQry.SetParameter("qClientsList", pClientsList);
	vQry.SetParameter("qPeriodFrom", BegOfDay(SelSalesPeriodFrom));
	vQry.SetParameter("qPeriodTo", ?(ValueIsFilled(SelSalesPeriodTo), EndOfDay(SelSalesPeriodTo), '39991231235959'));
	Return vQry.Execute().Unload();
EndFunction // GetInventoryStats

// -----------------------------------------------------------------------------
&AtServer
Function GetRevenueStats(pClientsList)
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SalesTurnovers.Client,
	|	SUM(ISNULL(SalesTurnovers.SalesTurnover, 0)) AS SalesTurnover,
	|	SUM(ISNULL(SalesTurnovers.GuestDaysTurnover, 0)) AS GuestDaysTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(&qPeriodFrom, &qPeriodTo, Period, Client IN (&qClientsList)) AS SalesTurnovers
	|
	|GROUP BY
	|	SalesTurnovers.Client";
	vQry.SetParameter("qClientsList", pClientsList);
	vQry.SetParameter("qPeriodFrom", BegOfDay(SelSalesPeriodFrom));
	vQry.SetParameter("qPeriodTo", ?(ValueIsFilled(SelSalesPeriodTo), EndOfDay(SelSalesPeriodTo), '39991231235959'));
	Return vQry.Execute().Unload();
EndFunction // GetRevenueStats

// -----------------------------------------------------------------------------
&AtServer
Function GuestHasClientBalance(pDocRef)
	vHasClientBalance = False;
	vDocuments = New ValueList();
	vDocuments.Add(pDocRef);
	vBalances = cmGetDocumentListBalances(vDocuments, pDocRef.Hotel);
	For Each vBalancesRow In vBalances Do
		If vBalancesRow.ClientSumBalance > SelDebtAmount Then
			vHasClientBalance = True;
			If SelDebtAmount = 0 Then
				Break;
			EndIf;
		EndIf;
	EndDo;
	Return vHasClientBalance;
EndFunction // GuestHasClientBalance

// -----------------------------------------------------------------------------
&AtServer
Function CheckClientStatistics(pInventoryStats, pRevenueStats, pClient)
	If SelNumberOfCheckIns > 0 Then
		vRow = pInventoryStats.Find(pClient, "Client");
		If vRow <> Undefined Then
			If vRow.GuestsCheckedIn <= SelNumberOfCheckIns Then
				Return False;
			EndIf;
		Else
			Return False;
		EndIf;
	EndIf;
	If SelNumberOfGuestDays > 0 Or SelSalesAmount > 0 Then
		vRow = pRevenueStats.Find(pClient, "Client");
		If vRow <> Undefined Then
			If SelNumberOfGuestDays > 0 Then
				If vRow.GuestDaysTurnover <= SelNumberOfGuestDays Then
					Return False;
				EndIf;
			EndIf;
			If SelSalesAmount > 0 Then
				If vRow.SalesTurnover <= SelSalesAmount Then
					Return False;
				EndIf;
			EndIf;
		Else
			Return False;
		EndIf;
	EndIf;
	Return True;
EndFunction // CheckClientStatistics

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckClearReceivers(pCommand)
	If Items.FormCheckClearReceivers.Check Then
		Items.FormCheckClearReceivers.Check = False;
		SelClearReceivers = False;
		Items.FormCheckClearReceivers.Picture = PictureLib.Delete;
	Else
		Items.FormCheckClearReceivers.Check = True;
		SelClearReceivers = True;
		Items.FormCheckClearReceivers.Picture = PictureLib.CheckMark;		
	EndIf;
EndProcedure // CheckClearReceivers

// -----------------------------------------------------------------------------
&AtClient
Procedure SelBirthDayPeriodFromStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // SelBirthDayPeriodFromStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure SelBirthDayPeriodToStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // SelBirthDayPeriodToStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure SelImportantDatePeriodFromStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // SelImportantDatePeriodFromStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure SelImportantDatePeriodToStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // SelImportantDatePeriodToStartChoice
