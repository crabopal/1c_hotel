
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Initialize hotel
	tcOnServer.cmInitHotel(Object);
	
	// Check user rights to use item
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		If Not ValueIsFilled(Object.Ref) Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights for services and prices management!';ru='Нет прав на управление услугами и ценами!';de='Sie haben keine Rechte, Dienstleistungen und Preise zu verwalten!'"));
		Else
			ThisForm.ReadOnly = True;
		EndIf;
	Else
		If Not ValueIsFilled(Object.Ref) Then
			// Fill attributes with default values
			vObj = FormAttributeToValue("Object");
			vObj.pmFillAttributesWithDefaultValues();
			ValueToFormAttribute(vObj, "Object");
		EndIf;
    EndIf;
    If (Object.LoyaltyType = Enums.LoyaltyType.Bonuses Or Object.LoyaltyType = Enums.LoyaltyType.Certificate) And Not ValueIsFilled(Object.AccumulatingDiscountDimension) Then
        Object.AccumulatingDiscountDimension = Enums.AccumulatingDiscountDimensions.DiscountCard;
        ThisObject.Modified = True;
    EndIf; 
	Items.BonusCalculationFactor.Enabled = Not Object.DifferentBonusCalculationFactorsForServiceGroupsAllowed;
	
	// Color
	vColor = GetColor();
	If vColor <> Undefined Then
		ItemColor = vColor;
		ItemColorIsSet = True;
		ThisForm.Items.FormSetColor.BackColor = vColor;
	Else
		ItemColor = Undefined;
		ItemColorIsSet = False;
	EndIf;
	
	// Set form appearance
	SetFormAppearance();
EndProcedure // OnCreateAtServer

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	If ItemColorIsSet Then
		pCurrentObject.ColorHexString = tcOnServer.ColorToHex(ItemColor);
		pCurrentObject.Color = New ValueStorage(tcOnServer.HexToColor(pCurrentObject.ColorHexString));
	Else
		pCurrentObject.ColorHexString = "";
		pCurrentObject.Color = Undefined;
	EndIf;
EndProcedure // BeforeWriteAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure IsAccumulatingDiscountOnChange(pItem)
	SetFormAppearance();
EndProcedure // IsAccumulatingDiscountOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure AccumulatingDiscountTypeOnChange(pItem)
	SetFormAppearance();
EndProcedure // AccumulatingDiscountTypeOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure LoyaltyTypeOnChange(Item)
	Object.VerifyClientBySMS = False;
	SetFormAppearance();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure DifferentBonusCalculationFactorsForServiceGroupsAllowedOnChange(pItem)
	Items.BonusCalculationFactor.Enabled = Not Object.DifferentBonusCalculationFactorsForServiceGroupsAllowed;
EndProcedure // DifferentBonusCalculationFactorsForServiceGroupsAllowedOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure InformClientWhenChargingOnChange(Item)
    SetFormAppearance();
EndProcedure

&AtClient
Procedure InformClientWhenCreationCardOnChange(Item)
    SetFormAppearance();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure PromoCodeOnChange(pItem)
	If Not IsBlankString(Object.PromoCode) Then
		Object.PromoCode = Upper(TrimAll(Object.PromoCode));
	EndIf;
EndProcedure // PromoCodeOnChange

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure SetFormAppearance()
	vTitle = ThisForm.Title;
	If Not Object.Ref.IsEmpty() And ExistDiscountCards(Object.Ref) Then
		Items.LoyaltyType.Enabled = False;
		Items.GroupDecorationMessage.Visible = True;
	EndIf;	
	Items.PageBonuses.Visible = False;
	Items.PageCertificate.Visible = False;
	Items.PageDiscount.Visible = False;
	If Object.LoyaltyType = Enums.LoyaltyType.Bonuses Then
		Items.Pages.CurrentPage = Items.PageBonuses;
		Items.PageBonuses.Visible = True;
		Items.PageCertificate.Visible = False;
		Items.PageDiscount.Visible = True;
		vTitle = NStr("en = 'Bonus accrual and withdrawal rules'; de = 'Bonus-Abgrenzungs- und Auszahlungsregeln'; ru = 'Правила начисления и списания бонусов'");
	ElsIf Object.LoyaltyType = Enums.LoyaltyType.Certificate Then	
		Items.Pages.CurrentPage = Items.PageCertificate;
		Items.PageBonuses.Visible = False;
		Items.PageCertificate.Visible = True;
		Items.PageDiscount.Visible = True;
		vTitle = NStr("en = 'Certificate Accounting Rules'; de = 'Zertifikatabrechnungsregeln'; ru = 'Правила учета сертификатов'");
	ElsIf Object.LoyaltyType = Enums.LoyaltyType.Discount Then		
		Items.Pages.CurrentPage = Items.PageDiscount;
		Items.PageBonuses.Visible = False;
		Items.PageCertificate.Visible = False;
		Items.PageDiscount.Visible = True;
		vTitle = NStr("en = 'Types of discounts and margins'; de = 'Arten von Rabatten und Gewinnspannen'; ru = 'Типы скидок и наценок'");
		If Object.IsAccumulatingDiscount Then
			Items.GroupAccummulatingDiscount.Visible = True;
			If Object.IsAmountDiscount Then
				Object.IsAmountDiscount = False;
			EndIf;
			Items.IsAmountDiscount.Enabled = False;
		Else
			Items.GroupAccummulatingDiscount.Visible = False;
			Items.IsAmountDiscount.Enabled = True;
		EndIf;
		If Object.AccumulatingDiscountType = Enums.AccumulatingDiscountTypes.External Then
			Items.ExternalAlgorithm.Enabled = True;
		Else
			Items.ExternalAlgorithm.Enabled = False;
		EndIf;
    EndIf;	
    // Inform the client when charging or adjusting
    Items.GroupSMSTemplate.Enabled = Object.InformClientWhenChargingOrStorno;
    Items.GroupSMSTemplateCertificate.Enabled = Object.InformClientWhenChargingOrStorno;
    Items.GroupSMSTemplateInformClientWhenCreationCard.Enabled = Object.InformClientWhenCreationCard;
    Items.GroupSMSTemplateInformClientWhenCreationCardCertificate.Enabled = Object.InformClientWhenCreationCard;
	
	If ValueIsFilled(Object.Hotel) Then
		vSplitFolioBalanceByServicesAndPrices = Object.Hotel.SplitFolioBalanceByServicesAndPrices;
		If vSplitFolioBalanceByServicesAndPrices = False Then
			Object.CalculateBonusesByPayments = False;
			Items.CalculateBonusesByPayments.Enabled = False;
		EndIf;	
	Else
		If ValueIsFilled(Object.Hotel) Then
			vSplitFolioBalanceByServicesAndPrices = Object.Hotel.SplitFolioBalanceByServicesAndPrices;
			If vSplitFolioBalanceByServicesAndPrices = False Then
				Object.CalculateBonusesByPayments = False;
				Items.CalculateBonusesByPayments.Enabled = False;
			EndIf;	
		Else
			vHotel = SessionParameters.CurrentHotel;
			If ValueIsFilled(vHotel) Then
				vSplitFolioBalanceByServicesAndPrices = vHotel.SplitFolioBalanceByServicesAndPrices;
				If vSplitFolioBalanceByServicesAndPrices = False Then
					Object.CalculateBonusesByPayments = False;
					Items.CalculateBonusesByPayments.Enabled = False;
				EndIf;	
			Else
				Object.CalculateBonusesByPayments = False;
				Items.CalculateBonusesByPayments.Enabled = False;
			EndIf;	
		EndIf;	
	EndIf;	
    // Title description
    ThisForm.Title = vTitle + " ("+Object.Description+")";
EndProcedure // SetFormAppearance

// --------------------------------------------------------------------------------
&AtServerNoContext
Function ExistDiscountCards(pDiscountCard)
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	DiscountCards.Ref AS Ref
		|FROM
		|	Catalog.DiscountCards AS DiscountCards
		|WHERE
		|	DiscountCards.DiscountType = &qDiscountType
		|	AND DiscountCards.DeletionMark = FALSE";
	vQuery.SetParameter("qDiscountType", pDiscountCard);
	vRes = vQuery.Execute();
	If vRes.IsEmpty() Then
		Return False;
	Else
		Return True;
	EndIf;	
EndFunction //  ExistDiscountCards ()

#EndRegion

#Region Color

// --------------------------------------------------------------------------------
&AtServer
Function GetColor()
	vColor = Undefined;
	If Not IsBlankString(Object.ColorHexString) Then
		vColor = tcOnServer.HexToColor(Object.ColorHexString);
		If TypeOf(vColor) <> Type("Color") Then
			vColor = Undefined;
		EndIf;
	EndIf;
	Return vColor;
EndFunction // GetColor

// --------------------------------------------------------------------------------
&AtClient
Procedure SetColor(pCommand)
	// Choose color
	vColorDlg =  New ColorChooseDialog;
	vColorDlg.Color = ItemColor;
	vColorDlg.Show(New NotifyDescription("SetColorAfterUserChoice", ThisForm))
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SetColorAfterUserChoice(pColor, pExtraParams) Export
	If pColor <> Undefined Then
		If pColor.Type = ColorType.WebColor Or pColor.Type = ColorType.Absolute Then
			ItemColor = pColor;
			ItemColorIsSet = True;
			ThisForm.Items.FormSetColor.BackColor = pColor;
		Else
			ShowMessageBox(, NStr("en='You can choose web or absolute colors only! Style and windows colors are not supported.';ru='Можете выбирать только абсолютные цвета (по названию или по RGB)! Выбор цветов из стилей не поддерживается.';de='Sie dürfen nur absolute Farben wählen (nach Bezeichnung oder nach RGB)! Die Farbenauswahl aus Stilen wird nicht unterstützt.'"));
		EndIf;
	EndIf;
EndProcedure // SetColorAfterUserChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure ClearColor(pCommand)
	// Clear color
	ItemColor = Undefined;
	ItemColorIsSet = False;
	ThisForm.Items.FormSetColor.BackColor = ThisForm.Items.FormClearColor.BackColor;
EndProcedure // ClearColor

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetDaysOfWeekList(pWeekDays) 
	vWeekDaysList = New ValueList();
	For i = 1 To 7 Do
		vWeekDaysList.Add(i, cmGetDayOfWeekName(i, False), StrFind(pWeekDays, String(i)) > 0);
	EndDo;
	Return vWeekDaysList;
EndFunction // GetDaysOfWeekList

// --------------------------------------------------------------------------------
&AtClient
Procedure WeekDaysStartChoice(pItem, pChoiceData, pStandardProcessing)
	GetDaysOfWeekList(Object.WeekDays).ShowCheckItems(New NotifyDescription("WeekDaysChoiceEnd", ThisForm), NStr("en='Days of week'; ru='Дни недели'; de='Wochentage'"));
EndProcedure // WeekDaysStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure WeekDaysChoiceEnd(pWeekDaysList, pExtraParams) Export
	If pWeekDaysList <> Undefined Then
		Object.WeekDays = "";
		For i = 1 To 7 Do
			If pWeekDaysList.Get(i - 1).Check Then
				Object.WeekDays = TrimAll(Object.WeekDays) + ?(IsBlankString(Object.WeekDays), "", ", ") + String(i);
			EndIf;
		EndDo;
	EndIf;
EndProcedure // WeekDaysChoiceEnd

// --------------------------------------------------------------------------------
&AtClient
Procedure WeekDaysClearing(pItem, pStandardProcessing)
	Object.WeekDays = "";
EndProcedure

#EndRegion
