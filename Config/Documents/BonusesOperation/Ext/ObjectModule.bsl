
#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure Posting(pCancel, pMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	If Not ValueIsFilled(Card) Then
		pCancel = True;

		vMsg = NStr("en = 'Card should be filled!'; 
					|de = 'Eine Karte angeben müssen!'; 
					|ru = 'Карта должна быть указана!'");
		vUsrMsg = New UserMessage();
		vUsrMsg.Text = vMsg;
		vUsrMsg.Message();
	EndIf;
	If Not ValueIsFilled(Card.LoyaltyType) Then
		pCancel = True;

		vMsg = NStr("en = 'Card loyalty type should be filled!'; 
					|de = 'Der Kartenloyalitätstyp sollte ausgefüllt werden!'; 
					|ru = 'У карты должен быть указан вид системы лояльности!'");

		vUsrMsg = New UserMessage();
		vUsrMsg.Text = vMsg;
		vUsrMsg.Message();
	EndIf;
	If Not ValueIsFilled(Card.DiscountType) Then
		pCancel = True;

		vMsg = NStr("en = 'Card discount type should be filled!'; 
					|de = 'Der Kartenrabatttyp sollte ausgefüllt werden!'; 
					|ru = 'У карты должен быть указан тип скидки!'");

		vUsrMsg = New UserMessage();
		vUsrMsg.Text = vMsg;
		vUsrMsg.Message();
	EndIf;     

	RegisterRecords.Bonuses.Write = True;

	If ValueIsFilled(Date) Then
		If OperationType = Enums.BonusesOperationTypes.Receipt Then
			vRecord = RegisterRecords.Bonuses.Add();
			vRecord.RecordType = AccumulationRecordType.Receipt;
			vRecord.Period = Date;
			vRecord.Card = Card;
			If ValueIsFilled(ExpiryDate) Then
				vRecord.ExpiryDate = ExpiryDate;
			ElsIf BonusesValidity > 0 Then
				vRecord.ExpiryDate = BegOfDay(Date) + BonusesValidity * (24*3600);
			Else
				vRecord.ExpiryDate = '00010101';
			EndIf;
			vRecord.Quantity = BonusesQuantity;
		ElsIf OperationType = Enums.BonusesOperationTypes.Expense Then 	
			If BonusesValidity > 0 And BonusesQuantity > 0 And Not ValueIsFilled(ExpiryDate) Then
				vBonusesQuantity = BonusesQuantity;
				vBonusesBalances = cmGetBonusesBalancePerExpiryDates(Card, Date);
				
				For Each vBonusesBalancesRow In vBonusesBalances Do
					If vBonusesBalancesRow.QuantityBalance > 0 Then
						vRecord = RegisterRecords.Bonuses.Add();
						vRecord.RecordType = AccumulationRecordType.Expense;
						vRecord.Period = Date;
						vRecord.Card = Card;
						vRecord.ExpiryDate = vBonusesBalancesRow.ExpiryDate;
						vRecord.Quantity = Min(vBonusesBalancesRow.QuantityBalance, vBonusesQuantity);
						
						vBonusesQuantity = vBonusesQuantity - vRecord.Quantity;
						If vBonusesQuantity <= 0 Then
							Break;
						EndIf;
					EndIf;
				EndDo;
				
				// Check that all bonuses were written off
				If vBonusesQuantity > 0 Then
					If AdditionalProperties.Property("DoCheckBalance") And AdditionalProperties.DoCheckBalance Then
						pCancel = True;
						
						vMsg = StrTemplate(NStr("en='There are not enough bonuses at the loyalty card %1! Short off %2 bonuses'; 
						                       |ru='На карте лояльности %1 недостаточно бонусов! Не хватает %2 бонусов'; 
								               |de='Es gibt nicht genug Boni auf der Treuekarte %1! Fehlt Boni %2'"),
						                   TrimAll(Card), 
						                   Format(vBonusesQuantity, "NZ=; NG="));
										   
						vUsrMsg = New UserMessage();
						vUsrMsg.Text = vMsg;
						vUsrMsg.Message();
					Else
						vRecord = RegisterRecords.Bonuses.Add();
						vRecord.RecordType = AccumulationRecordType.Expense;
						vRecord.Period = Date;
						vRecord.Card = Card;
						vRecord.ExpiryDate = '00010101';
						vRecord.Quantity = vBonusesQuantity;
					EndIf;
				EndIf;
			Else
				vRecord = RegisterRecords.Bonuses.Add();
				vRecord.RecordType = AccumulationRecordType.Expense;
				vRecord.Period = Date;
				vRecord.Card = Card;
				vRecord.ExpiryDate = ExpiryDate;
				vRecord.Quantity = BonusesQuantity;
			EndIf;
		EndIf;

		// Send sms and email 
	    SendSMS();
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	If Not IsNew() Then
		If Ref.BonusesQuantity <> BonusesQuantity or Ref.Card <> Card Then
			ChangeAuthor = SessionParameters.CurrentUser;
			ChangeDate = CurrentSessionDate();
		EndIf;
	EndIf;
    AdditionalProperties.Insert("IsNew", IsNew());
EndProcedure

// --------------------------------------------------------------------------------
Procedure Filling(FillingData, FillingText, StandardProcessing)
	If IsNew() Then
		Author = SessionParameters.CurrentUser;
		Date = CurrentSessionDate();
		OperationType = Enums.BonusesOperationTypes.Receipt;
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If TypeOf(FillingData) = Type("CatalogRef.DiscountCards") Then
		Card = FillingData;
		Guest = FillingData.Client;
		Hotel = FillingData.CreateHotel;
		If ValueIsFilled(Card) And ValueIsFilled(Card.DiscountType) And ValueIsFilled(Card.DiscountType.BonusesValidity) Then
			BonusesValidity = Card.DiscountType.BonusesValidity;
		EndIf;
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
Procedure OnSetNewNumber(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(Hotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(Hotel);
	EndIf;
	If ValueIsFilled(SessionParameters.CurrentHotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(SessionParameters.CurrentHotel);
	EndIf;
	If vPrefix <> "" Then
		pPrefix = vPrefix;
	EndIf;
EndProcedure // OnSetNewNumber

// -----------------------------------------------------------------------------
Procedure OnCopy(pCopiedObject)
	Author = SessionParameters.CurrentUser;
	ChangeAuthor = Undefined;
	ChangeDate = '00010101';
	ExternalCode = "";
EndProcedure // OnCopy

// -----------------------------------------------------------------------------
Procedure FillCheckProcessing(pCancel, pCheckedAttributes)
	If AdditionalProperties.Property("CheckedAttributes") Then
		For Each vId In AdditionalProperties.CheckedAttributes Do
			pCheckedAttributes.Add(vId);       
		EndDo;	
	EndIf;
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure SendSMS()
    If ValueIsFilled(Card) And ValueIsFilled(Card.DiscountType) And AdditionalProperties.IsNew Then
        vDiscountType = Card.DiscountType;
        If vDiscountType.InformClientWhenChargingOrStorno And ValueIsFilled(vDiscountType.DeliveryType) And ValueIsFilled(vDiscountType.SMSTemplate) Then
            vLanguage = Catalogs.Languages.RU;
            vDeliveryType = vDiscountType.DeliveryType;
            If ValueIsFilled(Guest) Then
                vLanguage = Guest.Language;
            EndIf;
            vSMSTemplate = vDiscountType.SMSTemplate;
            vSMSTemplateText = SMS.GetSMSTextByLanguage(vSMSTemplate, vLanguage);
            vSMSText = SMS.ReplaceSMSParameters(vSMSTemplateText, Ref, Guest);
            vOperationParametrs = New Array;
            vReceiversA = New Array();
            vReceiversA.Add(New Structure("LineNumber, Phone, EMail, Client, Customer, SMSText, Cost, IsSent, Result, MessageID, ClientDoc, ParentDoc, AmountStr, DiscountCard",
                                            1,
                                            Guest.Phone,
                                            Guest.EMail,
                                            Guest,
                                            Undefined,
                                            vSMSText,
                                            0,
                                            False,
                                            "",
                                            "",
                                            Ref,
											Ref, 
											"",
											Catalogs.DiscountCards.EmptyRef()));		
            
            vOperationParametrs.Add(vReceiversA);
            vOperationParametrs.Add(vDiscountType.DeliveryType);
            vOperationParametrs.Add(0);     // DistributionListId
            vOperationParametrs.Add("");    // AttachmentPath
            vOperationParametrs.Add(False); // IsByCustomers
            vOperationParametrs.Add(vSMSTemplate);
            vOperationParametrs.Add(vSMSTemplate.Sender);
            
            AsyncCalls.StartBackgroundJobWithRecordInRegister(Ref, "SMSDelivery_BonusesOperation", "ProlongedOperations.MessagesDeliverySend", vOperationParametrs);          
        EndIf;
    EndIf;

EndProcedure

#EndRegion
