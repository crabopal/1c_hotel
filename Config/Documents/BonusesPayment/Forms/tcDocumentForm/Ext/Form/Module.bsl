
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)   
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	If Object.Ref.IsEmpty() Then
		Object.Hotel = SessionParameters.CurrentHotel;
		If Not ValueIsFilled(Object.Source) Then
			Object.Source = Catalogs.BonusOperationSources.EmptyRef();
		EndIf;
	EndIf;
	If TypeOf(Object.Source) = Type("String") Or TypeOf(Object.Source) = Type("CatalogRef.BonusOperationSources") Then
		Items.Source.ChooseType = False;
	Else
		Items.Source.ChooseType = True;
	EndIf;

	// User rights to edit document	
	If Not Object.Ref.IsEmpty() Then
		If Not IsInRole("Administrator") Or Not cmCheckUserPermissions("HavePermissionToEditPostedFolioTransactions") Then
			ReadOnly = True;
			Items.FormSetDeletionMarkAction.Visible = False;
		Else
			If Object.Folio.IsClosed Then
				ReadOnly = True;
				Items.FormSetDeletionMarkAction.Visible = False;
			EndIf;
		EndIf;
	Else
		Items.FormSetDeletionMarkAction.Visible = False;
		
		// Fill discount card by folio client
		If Not ValueIsFilled(Object.Payment) Then
			vDiscountCard = Object.Card;
			If Not ValueIsFilled(vDiscountCard) Then 
				vClient = Object.Guest;
				If Not ValueIsFilled(vClient) And ValueIsFilled(Object.Folio) Then
					vClient = Object.Folio.Client;
					If ValueIsFilled(vClient) Then
						Object.Guest = vClient;
					EndIf;
					vParentDoc = Object.Folio.ParentDoc;
					If ValueIsFilled(vParentDoc) Then
						vDiscountCard = vParentDoc.DiscountCard;
						If ValueIsFilled(vDiscountCard) And 
						  (vDiscountCard.LoyaltyType = Enums.LoyaltyType.Bonuses Or 
						   vDiscountCard.LoyaltyType = Enums.LoyaltyType.Certificate) Then
							Object.Card = vDiscountCard;
						EndIf;
					EndIf;
					If Not ValueIsFilled(Object.Card) And ValueIsFilled(vClient) Then
						Object.Card = Catalogs.DiscountCards.GetBonusesCardByClient(vClient);
					EndIf;
					If ValueIsFilled(Object.Card) And ValueIsFilled(Object.Card.Client) Then
						Object.Guest = Object.Card.Client;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	// Fill link to the bonuses external system
	If ValueIsFilled(Object.Card) Then
		vDiscountType = Object.Card.DiscountType;
		If ValueIsFilled(vDiscountType) And ValueIsFilled(vDiscountType.ExternalInteraction) Then
			ExternalSystem = vDiscountType.ExternalInteraction;
		EndIf;
	EndIf;
	
	// Initialize some attributes not available in previous versions
	If Not ValueIsFilled(Object.ExchangeRateDate) Then
		Object.ExchangeRateDate = Object.Date;
	EndIf;
	If Not ValueIsFilled(Object.Currency) Then
		If ValueIsFilled(Object.Payment) Then
			If TypeOf(Object.Payment) = Type("DocumentRef.DepositTransfer") Then
				Object.Currency = Object.Payment.FolioTo.FolioCurrency;
			Else
				Object.Currency = Object.Payment.PaymentCurrency;
			EndIf;
		ElsIf ValueIsFilled(Object.Folio) Then
			Object.Currency = Object.Folio.FolioCurrency;
		ElsIf ValueIsFilled(Object.Hotel) Then
			Object.Currency = Object.Hotel.FolioCurrency;
		EndIf;
	EndIf;
	If Object.BonusRate = 0 Then
		vObj = FormAttributeToValue("Object");
		vObj.BonusRate = vObj.pmGetBonusRate();
		ValueToFormAttribute(vObj, "Object");
	EndIf;
	If Object.BonusRate <> 0 Then
		If Object.BonusesAmount <> 0 And Object.BonusesQuantity = 0 Then
			Object.BonusesQuantity = Round(Object.BonusesAmount * Object.BonusRate, 2);
		ElsIf Object.BonusesAmount = 0 And Object.BonusesQuantity <> 0 Then
			Object.BonusesAmount = Round(Object.BonusesQuantity / Object.BonusRate, 2);
		EndIf;
		If Object.AmountAvailable = 0 And Object.BonusesAvailable <> 0 Then
			Object.AmountAvailable = Round(Object.BonusesAvailable / Object.BonusRate, 2);
		EndIf;
	EndIf;

	// Fill bonuses available	
	If Object.Ref.IsEmpty() And ValueIsFilled(Object.Card) And ValueIsFilled(Object.Currency) And Object.BonusesAvailable = 0 Then
		// Fill balance by discount card or certificate
		FillBalanceByCard();
	EndIf;
	
	// Fill charges
	If Object.Ref.IsEmpty() Then
		// Fill by list of charges transferred
		If Parameters.Property("SelectedChargesList") And Parameters.SelectedChargesList.Count() > 0 And ValueIsFilled(Object.Hotel) Then
			vObj = FormAttributeToValue("Object");
			vObj.IsByCharges = True;
			vObj.ChargesPaidByBonuses.Clear();
			vCharges = vObj.ChargesPaidByBonuses.UnloadColumns();
			vChargesRow = Undefined;
			For Each vChargeItem In Parameters.SelectedChargesList Do
				vChargeRef = vChargeItem.Value;
				If vChargeRef.IsMergedToRoomRevenue And ValueIsFilled(vChargeRef.RoomRevenueCharge) And 
				   vChargeRef.RoomRevenueCharge <> vChargeRef And vChargesRow <> Undefined And 
				   vChargesRow.Service = vChargeRef.RoomRevenueCharge.Service Then
					vChargesRow.Sum = vChargesRow.Sum + vChargeRef.Sum - vChargeRef.DiscountSum;
					vChargesRow.Price = Round(vChargesRow.Sum/vChargesRow.Quantity, 2);
				Else
					vChargesRow = vCharges.Add();
					If ValueIsFilled(vChargeRef.CorrectedCharge) Then
						vCorrectedCharge = vChargeRef.CorrectedCharge;
						
						vChargesRow.AccountingDate = BegOfDay(?(ValueIsFilled(vCorrectedCharge.ServiceDate), vCorrectedCharge.ServiceDate, vCorrectedCharge.Date));
						vChargesRow.Service = vCorrectedCharge.Service;
						vChargesRow.Unit = vCorrectedCharge.Unit;
						vChargesRow.Quantity = 0;
						vChargesRow.Sum = vChargeRef.Sum - vChargeRef.DiscountSum;
						vChargesRow.Price = Round((vCorrectedCharge.Sum - vCorrectedCharge.DiscountSum)/?(vCorrectedCharge.Quantity = 0, 1, vCorrectedCharge.Quantity), 2);
						vChargesRow.Charge = vCorrectedCharge;
					Else
						vChargesRow.AccountingDate = BegOfDay(?(ValueIsFilled(vChargeRef.ServiceDate), vChargeRef.ServiceDate, vChargeRef.Date));
						vChargesRow.Service = vChargeRef.Service;
						vChargesRow.Unit = vChargeRef.Unit;
						vChargesRow.Quantity = ?(vChargeRef.Quantity = 0, 1, vChargeRef.Quantity);
						vChargesRow.Sum = vChargeRef.Sum - vChargeRef.DiscountSum;
						vChargesRow.Price = Round(vChargesRow.Sum/vChargesRow.Quantity, 2);
						vChargesRow.Charge = vChargeRef;
					EndIf;
				EndIf;
			EndDo;
			vCharges.GroupBy("AccountingDate, Service, Unit, Price, Charge, ShouldBeSkipped", "Quantity, Sum, BonusesQuantity, BonusesAmount");
			// Recalculate effective price
			For Each vChargesRow In vCharges Do
				vChargesRow.Price = Round(vChargesRow.Sum/?(vChargesRow.Quantity = 0, 1, vChargesRow.Quantity), 2);
			EndDo;
			// Remove negative corrections
			i = 0;
			While i < vCharges.Count() Do
				vChargesRow = vCharges.Get(i);
				If vChargesRow.Sum < 0 Then
					vCharges.Delete(i);
				Else
					i = i + 1;
				EndIf;
			EndDo;
			// Remove rows with services not in the card discount type services group
			If ValueIsFilled(vObj.Card) And ValueIsFilled(vObj.Card.DiscountType) Then
				vDiscountType = vObj.Card.DiscountType;
				If ValueIsFilled(vDiscountType.DiscountServiceGroup) Then
					i = 0;
					While i < vCharges.Count() Do
						vChargesRow = vCharges.Get(i);
						If Not cmIsServiceInServiceGroup(vChargesRow.Service, vDiscountType.DiscountServiceGroup) Then
							vChargesRow.ShouldBeSkipped = True;
							vChargesRow.BonusesAmount = 0;
							vChargesRow.BonusesQuantity = 0;
						Else
							vChargesRow.ShouldBeSkipped = False;
						EndIf;
						i = i + 1;
					EndDo;
				EndIf;
			EndIf;
			// Load table to the document charges
			vObj.ChargesPaidByBonuses.Load(vCharges);
			ValueToFormAttribute(vObj, "Object");
		EndIf;
	EndIf;		
	
	// Charges appearance
	If Not Object.IsByCharges Then
		Items.ChargesPaidByBonuses.Visible = False;
		Items.PaymentLabel.Visible = True;
	Else
		Items.ChargesPaidByBonuses.Visible = True;
		Items.PaymentLabel.Visible = False;

		Items.ChargesPaidByBonusesBonusesAmount.Title = NStr("en='Bonuses amount'; ru='Сумма бонусами'; de='Bonusbetrag'") + " (" + TrimAll(Object.Currency) + ")";
		Items.ChargesPaidByBonusesSum.Title = NStr("en='Charge amount'; ru='Сумма начисления'; de='Gebührenbetrag'") + " (" + TrimAll(Object.Currency) + ")";
	EndIf;

	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Reverse operation command
	If Object.Ref.IsEmpty() Then
		Items.FormFillOnBasis.Visible = False;
		Items.FormFillOnBasis.Enabled = False;
	EndIf;
	
	// Amount available
	Object.AmountAvailable = CalculateBonusesAmount(Object.BonusesAvailable, Object.BonusRate);
	
	// Form appearance
	If Object.BonusRate = 1 Then
		Items.BonusesQuantity.Visible = False;
		Items.BonusesAvailable.Visible = False;
		Items.ChargesPaidByBonusesBonusesQuantity.Visible = False;
	Else
		Items.BonusesQuantity.Visible = True;
		Items.BonusesAvailable.Visible = True;
		Items.ChargesPaidByBonusesBonusesQuantity.Visible = True;
	EndIf;
	
	// User rights
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	EndIf;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	If pWriteParameters.WriteMode = DocumentWriteMode.Posting Then
		pCurrentObject.AdditionalProperties.Insert("DoCheckBalance", True);
	EndIf;
EndProcedure // BeforeWriteAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(WriteParameters)
	Notify("BonusesChanged");
EndProcedure //  AfterWrite

// -----------------------------------------------------------------------------
&AtServer
Procedure FillCheckProcessingAtServer(pCancel, pCheckedAttributes)
	vObj = FormAttributeToValue("Object");
	pCancel = tcOnServer.cmFillCheckProcessingForm(pCheckedAttributes, CheckedAttributesManual, vObj);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "BonusesChanged" Then
		If Not ThisObject.Modified Then
			ThisObject.Read();
		EndIf;
	EndIf;
EndProcedure // NotificationProcessing

#EndRegion   

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure SourceOnChange(pItem)
	SourceOnChangeAtServer();
EndProcedure //  SourceOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure SourceClearing(pItem, pStandardProcessing)
	Object.Source = Undefined;
EndProcedure // SourceClearing

// --------------------------------------------------------------------------------
&AtClient
Procedure ClientStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // ClientStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure ClientClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // ClientClearing

// --------------------------------------------------------------------------------
&AtClient
Procedure AmountAvailableClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // AmountAvailableClearing

// --------------------------------------------------------------------------------
&AtClient
Procedure CardOnChange(pItem)
	CardOnChangeAtServer();
EndProcedure // CardOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure BonusesQuantityOnChange(pItem)
	BonusesQuantityOnChangeAtServer();
EndProcedure // BonusesQuantityOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure BonusesAmountOnChange(pItem)
	BonusesAmountOnChangeAtServer();
EndProcedure // BonusesAmountOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure AmountAvailableStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	// Fill balance by discount card or certificate
	FillBalanceByCard();
EndProcedure // AmountAvailableStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure FolioOnChange(pItem)
	FolioOnChangeAtServer();
EndProcedure // FolioOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ExchangeRateDateOnChange(pItem)
	ExchangeRateDateOnChangeAtServer();
EndProcedure // ExchangeRateDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CurrencyOnChange(pItem)
	CurrencyOnChangeAtServer();
EndProcedure // CurrencyOnChange

#EndRegion    

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SetDeletionMarkAction(pCommand)
	If Not ValueIsFilled(Object.Ref) Then
		Return;
	EndIf;
	If Modified Then
		Modified = False;
	EndIf;
	SetDeletionMarkAtServer();
	Read();
	Notify("Document.BonusesPayment.Write", Object.Ref, ThisObject);
	Close();
EndProcedure // SetDeletionMarkAction

// -----------------------------------------------------------------------------
&AtClient
Procedure FillOnBasis(pCommand)
	If Object.Posted Then
		If Not ThisObject.Modified Then
			OpenForm("Document.BonusesPayment.ObjectForm", New Structure("Basis", Object.Ref), , Object.Ref);
		Else
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Save document first!'; ru='Сначала сохраните документ!'; de='Speichern Sie das Dokument zuerst!'"), MessageStatus.Information);
		EndIf;
	EndIf;
EndProcedure // FillOnBasis

#EndRegion

#Region FormTableItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargesPaidByBonusesOnEditEnd(pItem, pNewRow, pCancelEdit)
	vCurId = Items.ChargesPaidByBonuses.CurrentRow;
	If vCurId <> Undefined Then
		vCurRow = Object.ChargesPaidByBonuses.FindByID(vCurID);
		If vCurRow <> Undefined Then
			If vCurRow.ShouldBeSkipped Then
				vCurRow.BonusesAmount = 0;
				vCurRow.BonusesQuantity = 0;
			Else
				vCurRow.BonusesQuantity = CalculateBonusesByAmount(vCurRow.BonusesAmount, Object.BonusRate);
				If vCurRow.BonusesAmount > vCurRow.Sum And vCurRow.Sum >= 0 Then
					tcCommonFunctionOnClientServer.UserMessage(NStr("en='The amount of the bonus discount cannot be more than the charge amount!'; 
					                                                |ru='Сумма скидки бонусами не может быть больше суммы начисления!'; 
																	|de='Der Rabattbetrag kann nicht größer als der Guthabenbetrag sein!'"), ,
					                                           "ChargesPaidByBonuses["+Format(vCurRow.LineNumber - 1, "NFD=0; NZ=; NG=") + "].BonusesQuantity", "Object");
					vCurRow.BonusesAmount = vCurRow.Sum;
					vCurRow.BonusesQuantity = CalculateBonusesByAmount(vCurRow.BonusesAmount, Object.BonusRate);
				EndIf;
				// Check maximum percent that could be paid by bonuses
				If Object.OperationType = PredefinedValue("Enum.BonusesPaymentTypes.Expense") Then
					If ValueIsFilled(Object.Card) Then
						vDiscountType = tcOnServer.cmGetAttributeByRef(Object.Card, "DiscountType");
						If ValueIsFilled(vDiscountType) Then
							vMaxPercentPayment = tcOnServer.cmGetAttributeByRef(vDiscountType, "MaxPercentPayment");
							If vMaxPercentPayment > 0 And vCurRow.Sum <> 0 Then
								vRowPercent = vCurRow.BonusesAmount / vCurRow.Sum * 100;
								If vRowPercent > vMaxPercentPayment Then
									tcCommonFunctionOnClientServer.UserMessage(StrTemplate(NStr("en='You can use bonuses to pay not more then %1 percent of services charged!'; 
									                                                            |ru='Сумма списываемых бонусов не может превышать %1 процентов от суммы начислений!'; 
									                                                            |de='Die ausstehenden Boni dürfen %1 Prozent des Servicebetrags nicht überschreiten!'"), 
									                                                       Format(vMaxPercentPayment, "NFD=1; NZ=; NG=")), , 
									                                           "ChargesPaidByBonuses["+Format(vCurRow.LineNumber - 1, "NFD=0; NZ=; NG=") + "].BonusesQuantity", "Object");
									vCurRow.BonusesAmount = Round(vCurRow.Sum * vMaxPercentPayment / 100, 2);
									vCurRow.BonusesQuantity = CalculateBonusesByAmount(vCurRow.BonusesAmount, Object.BonusRate);
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	Object.BonusesQuantity = Object.ChargesPaidByBonuses.Total("BonusesQuantity");
	Object.BonusesAmount = Object.ChargesPaidByBonuses.Total("BonusesAmount");
	BonusesQuantityOnChangeAtServer(True);
EndProcedure // ChargesPaidByBonusesOnEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargesPaidByBonusesAfterDeleteRow(pItem)
	Object.BonusesQuantity = Object.ChargesPaidByBonuses.Total("BonusesQuantity");
	Object.BonusesAmount = Object.ChargesPaidByBonuses.Total("BonusesAmount");
	BonusesQuantityOnChangeAtServer();
EndProcedure // ChargesPaidByBonusesAfterDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargesPaidByBonusesBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	pCancel = True;
EndProcedure // ChargesPaidByBonusesBeforeAddRow

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargesPaidByBonusesBeforeRowChange(pItem, pCancel)
	vChargesRow = Items.ChargesPaidByBonuses.CurrentData;
	If vChargesRow <> Undefined Then
		If vChargesRow.ShouldBeSkipped Then
			pCancel = True;
		EndIf;
	EndIf;
EndProcedure // ChargesPaidByBonusesBeforeRowChange

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure SetDeletionMarkAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.Read();
	vObj.SetDeletionMark(True);
	ValueToFormAttribute(vObj, "Object");
EndProcedure // SetDeletionMarkAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure SourceOnChangeAtServer()
	If TypeOf(Object.Source) = Type("String") Then
		Items.Source.ChooseType = False;
	ElsIf TypeOf(Object.Source) = Type("CatalogRef.BonusOperationSources") Then
		Items.Source.ChooseType = False;
		If ValueIsFilled(Object.Source) And Object.Source.BonusesQuantity <> 0 And Object.BonusesQuantity = 0 Then
			Object.BonusesQuantity = Object.Source.BonusesQuantity;
			If Object.Source.IsPerDay And ValueIsFilled(Object.GuestGroup) And 
			   ValueIsFilled(Object.GuestGroup.CheckInDate) And ValueIsFilled(Object.GuestGroup.CheckOutDate) And 
			   BegOfDay(Object.GuestGroup.CheckOutDate) > BegOfDay(Object.GuestGroup.CheckInDate) Then
				Object.BonusesQuantity = Object.BonusesQuantity * (BegOfDay(Object.GuestGroup.CheckOutDate) - BegOfDay(Object.GuestGroup.CheckInDate)) / (24 * 3600);
			EndIf;
			BonusesQuantityOnChangeAtServer();
		EndIf;
	Else
		Items.Source.ChooseType = True;
	EndIf;
EndProcedure // SourceOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillBalanceByCard()
	vCard = Object.Card;
	If ValueIsFilled(vCard) Then
		If vCard.LoyaltyType = Enums.LoyaltyType.Bonuses Then
			vDataCard = AccumulationRegisters.Bonuses.mmGetBalanceByCard(vCard, Object.Date, Object.ExchangeRateDate, Object.Hotel);
			If Object.BonusesAvailable <> vDataCard.Balance Then
				Object.BonusesAvailable = vDataCard.Balance;
				If Object.BonusRate <> 0 Then
					Object.AmountAvailable = Round(Object.BonusesAvailable / Object.BonusRate, 2);
				EndIf;
				ThisObject.Modified = True;
			EndIf;
		EndIf;
		vWarning = "";
		If ValueIsFilled(vCard.ValidTo) And EndOfDay(vCard.ValidTo) < Object.Date Then
			vWarning = NStr("en='Card is valid till '; ru='Карта действует до '; de='Karte ist gültig bis '") + Format(vCard.ValidTo, "DF=dd.MM.yyyy");
		EndIf;
		If vCard.IsBlocked Then
			vWarning = NStr("en='Card is blocked'; ru='Карта заблокирована'; de='Karte ist blockiert'");
		EndIf;
		If Not IsBlankString(vWarning) Then
			Items.Card.ToolTip = vWarning;
			Items.Card.ToolTipRepresentation = ToolTipRepresentation.ShowBottom;
			Items.Card.TextColor = WebColors.Red;
		Else
			Items.Card.ToolTip = "";
			Items.Card.ToolTipRepresentation = ToolTipRepresentation.None;
			Items.Card.TextColor = Items.Source.TextColor;
		EndIf;
	Else
		If Object.BonusesAvailable <> 0 Then
			Object.BonusesAvailable = 0;
			Object.AmountAvailable = 0;
			ThisObject.Modified = True;
		EndIf;
		Items.Card.ToolTip = "";
		Items.Card.ToolTipRepresentation = ToolTipRepresentation.None;
		Items.Card.TextColor = Items.Source.TextColor;
	EndIf;
EndProcedure // FillBalanceByCard

// -----------------------------------------------------------------------------
&AtServer
Procedure CardOnChangeAtServer()
	// Fill balance by discount card or certificate
	FillBalanceByCard();

	vCard = Object.Card;
	
	// Fill data from card
	Object.BonusesValidity = 0;
	If ValueIsFilled(vCard) Then
		If Object.Guest <> vCard.Client Then
			Object.Guest = vCard.Client;
			ThisObject.Modified = True;
		EndIf;
		
		// Remove rows with services not in the card discount type services group
		vDiscountType = vCard.DiscountType;
		If ValueIsFilled(vDiscountType) Then
			// Fill validity in days
			If vDiscountType.BonusesValidity > 0 Then
				Object.BonusesValidity = vDiscountType.BonusesValidity;
			EndIf;
			// Process charges
			If ValueIsFilled(vDiscountType.DiscountServiceGroup) Then
				i = 0;
				While i < Object.ChargesPaidByBonuses.Count() Do
					vChargesRow = Object.ChargesPaidByBonuses.Get(i);
					If Not cmIsServiceInServiceGroup(vChargesRow.Service, vDiscountType.DiscountServiceGroup) Then
						vChargesRow.ShouldBeSkipped = True;
						vChargesRow.BonusesQuantity = 0;
						vChargesRow.BonusesAmount = 0;
					Else
						vChargesRow.ShouldBeSkipped = False;
					EndIf;
					i = i + 1;
				EndDo;
			EndIf;
		EndIf;
		
		// Recalculate totals
		If Object.BonusesQuantity <> Object.ChargesPaidByBonuses.Total("BonusesQuantity") Then
			Object.BonusesQuantity = Object.ChargesPaidByBonuses.Total("BonusesQuantity");
			Object.BonusesAmount = Object.ChargesPaidByBonuses.Total("BonusesAmount");
			ThisObject.Modified = True;
		EndIf;
	EndIf;
EndProcedure // CardOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure BonusesQuantityOnChangeAtServer(pDoNotRecalculateRows = False)
	Object.BonusesAmount = CalculateBonusesAmount(Object.BonusesQuantity, Object.BonusRate);
	// Check amount
	If Object.OperationType = Enums.BonusesPaymentTypes.Expense Then
		If Object.BonusesQuantity > Object.BonusesAvailable Then
			tcCommonFunctionOnClientServer.UserMessage(NStr("en='Bonuses spent could not be greater then bonuses available!'; 
			                                                |ru='Сумма потраченных бонусов не может быть больше суммы доступных бонусов!'; 
			                                                |de='Der ausgegebene Bonusbetrag darf nicht größer sein als der verfügbare Bonusbetrag!'"), , 
			                                           "BonusesQuantity", "Object");
			If Not pDoNotRecalculateRows Then
				Object.BonusesQuantity = Object.BonusesAvailable;
				Object.BonusesAmount = CalculateBonusesAmount(Object.BonusesQuantity, Object.BonusRate);
			EndIf;
		EndIf;
		// Check maximum percent that could be paid by bonuses
		If ValueIsFilled(Object.Card) Then
			vDiscountType = Object.Card.DiscountType;
			If ValueIsFilled(vDiscountType) Then
				vMaxPercentPayment = vDiscountType.MaxPercentPayment;
				If vMaxPercentPayment > 0 Then
					vTotalSum = Object.ChargesPaidByBonuses.Total("Sum");
					If vTotalSum <> 0 Then
						vTotalPercent = Object.BonusesAmount / vTotalSum * 100;
						If vTotalPercent > vMaxPercentPayment Then
							tcCommonFunctionOnClientServer.UserMessage(StrTemplate(NStr("en='You can use bonuses to pay not more then %1 percent of services charged!'; 
							                                                            |ru='Сумма списываемых бонусов не может превышать %1 процентов от суммы начислений!'; 
							                                                            |de='Die ausstehenden Boni dürfen %1 Prozent des Servicebetrags nicht überschreiten!'"), 
							                                                       Format(vMaxPercentPayment, "NFD=1; NZ=; NG=")), , 
							                                           "BonusesQuantity", "Object");
							Object.BonusesAmount = Round(vTotalSum * vMaxPercentPayment / 100, 2);
							Object.BonusesQuantity = CalculateBonusesByAmount(Object.BonusesAmount, Object.BonusRate);
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	// Recalculate used bonuses per charges
	If Not pDoNotRecalculateRows And Object.ChargesPaidByBonuses.Count() > 0 Then
		vTotalSum = 0;
		For Each vChargesRow In Object.ChargesPaidByBonuses Do
			If Not vChargesRow.ShouldBeSkipped Then
				vTotalSum = vTotalSum + vChargesRow.Sum;
			EndIf;
		EndDo;
		If vTotalSum <> 0 Then
			vK = (Object.BonusesQuantity/Object.BonusRate)/vTotalSum;
			i = -1;
			j = -1;
			For Each vChargesRow In Object.ChargesPaidByBonuses Do
				If Not vChargesRow.ShouldBeSkipped Then
					vChargesRow.BonusesAmount = Round(vChargesRow.Sum*vK, 2);
					If vChargesRow.BonusesAmount > vChargesRow.Sum Then
						vChargesRow.BonusesAmount = vChargesRow.Sum;
					EndIf;
					vChargesRow.BonusesQuantity = Round(vChargesRow.BonusesAmount*Object.BonusRate, 2);
					j = i + 1;
				Else
					vChargesRow.BonusesAmount = 0;
					vChargesRow.BonusesQuantity = 0;
				EndIf;
				i = i + 1;
			EndDo;
			vDiff = Object.BonusesQuantity - Object.ChargesPaidByBonuses.Total("BonusesQuantity");
			If vDiff <> 0 And j >= 0 Then
				vChargesRow = Object.ChargesPaidByBonuses.Get(j);
				vChargesRow.BonusesQuantity = vChargesRow.BonusesQuantity + vDiff;
				vChargesRow.BonusesAmount = Round(vChargesRow.BonusesQuantity*Object.BonusRate, 2);
				If vChargesRow.BonusesAmount > vChargesRow.Sum Then
					vChargesRow.BonusesAmount = vChargesRow.Sum;
					vChargesRow.BonusesQuantity = Round(vChargesRow.BonusesAmount*Object.BonusRate, 2);
				EndIf;
			EndIf;
			Object.BonusesQuantity = Object.ChargesPaidByBonuses.Total("BonusesQuantity");
			Object.BonusesAmount = Object.ChargesPaidByBonuses.Total("BonusesAmount");
		EndIf;
	EndIf;
EndProcedure // BonusesQuantityOnChangeAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure BonusesAmountOnChangeAtServer()
	Object.BonusesQuantity = CalculateBonusesByAmount(Object.BonusesAmount, Object.BonusRate);
	BonusesQuantityOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtServerNoContext
Function CalculateBonusesAmount(pBonuses, pRate)
	vBonusesAmount = Round(pBonuses/pRate, 2);
	Return vBonusesAmount;
EndFunction // CalculateBonusesAmount

// -----------------------------------------------------------------------------
&AtServerNoContext
Function CalculateBonusesByAmount(pAmount, pRate)
	vBonusesQuantity = Round(pAmount*pRate, 2);
	Return vBonusesQuantity;
EndFunction // CalculateBonusesByAmount

// -----------------------------------------------------------------------------
&AtServer
Procedure FolioOnChangeAtServer()
	Object.ChargesPaidByBonuses.Clear();
	If ValueIsFilled(Object.Folio) And ValueIsFilled(Object.Folio.FolioCurrency) Then
		Object.Currency = Object.Folio.FolioCurrency;
		
		vObj = FormAttributeToValue("Object");
		vObj.BonusRate = vObj.pmGetBonusRate();
		ValueToFormAttribute(vObj, "Object");

		// Amount available
		Object.AmountAvailable = CalculateBonusesAmount(Object.BonusesAvailable, Object.BonusRate);
		
		Items.ChargesPaidByBonusesBonusesAmount.Title = NStr("en='Bonuses amount'; ru='Сумма бонусами'; de='Bonusbetrag'") + " (" + TrimAll(Object.Currency) + ")";
		Items.ChargesPaidByBonusesSum.Title = NStr("en='Charge amount'; ru='Сумма начисления'; de='Gebührenbetrag'") + " (" + TrimAll(Object.Currency) + ")";
		
		// Form appearance
		If Object.BonusRate = 1 Then
			Items.BonusesQuantity.Visible = False;
			Items.BonusesAvailable.Visible = False;
			Items.ChargesPaidByBonusesBonusesQuantity.Visible = False;
		Else
			Items.BonusesQuantity.Visible = True;
			Items.BonusesAvailable.Visible = True;
			Items.ChargesPaidByBonusesBonusesQuantity.Visible = True;
		EndIf;
	EndIf;
EndProcedure // FolioOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ExchangeRateDateOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.BonusRate = vObj.pmGetBonusRate();
	ValueToFormAttribute(vObj, "Object");
	
	// Amount available
	Object.AmountAvailable = CalculateBonusesAmount(Object.BonusesAvailable, Object.BonusRate);
		
	// Form appearance
	If Object.BonusRate = 1 Then
		Items.BonusesQuantity.Visible = False;
		Items.BonusesAvailable.Visible = False;
		Items.ChargesPaidByBonusesBonusesQuantity.Visible = False;
	Else
		Items.BonusesQuantity.Visible = True;
		Items.BonusesAvailable.Visible = True;
		Items.ChargesPaidByBonusesBonusesQuantity.Visible = True;
	EndIf;
EndProcedure // ExchangeRateDateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure CurrencyOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.BonusRate = vObj.pmGetBonusRate();
	ValueToFormAttribute(vObj, "Object");
	
	// Amount available
	Object.AmountAvailable = CalculateBonusesAmount(Object.BonusesAvailable, Object.BonusRate);
	
	// Form appearance
	If Object.BonusRate = 1 Then
		Items.BonusesQuantity.Visible = False;
		Items.BonusesAvailable.Visible = False;
		Items.ChargesPaidByBonusesBonusesQuantity.Visible = False;
	Else
		Items.BonusesQuantity.Visible = True;
		Items.BonusesAvailable.Visible = True;
		Items.ChargesPaidByBonusesBonusesQuantity.Visible = True;
	EndIf;
EndProcedure // CurrencyOnChangeAtServer

#EndRegion
