
#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure Posting(pCancel, pMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// Post to bonuses
	vSourceCard = CheckIsTransfer(pCancel);
	PostBonuses(vSourceCard, pCancel);
	
	// Post as revenue correction
	If ValueIsFilled(Hotel) And ValueIsFilled(Currency) And IsByCharges Then
		PostRevenueCorrection();
	EndIf;
EndProcedure // Posting

// --------------------------------------------------------------------------------
Procedure UndoPosting(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;

	// Select all correction charges created by this document and process them
	vCorrectionCharges = pmGetCorrectionCharges();
	For Each vCorrectionChargesRow In vCorrectionCharges Do
		vChargeObj = vCorrectionChargesRow.Ref.GetObject();
		If Not DeletionMark Then
			vChargeObj.Write(DocumentWriteMode.UndoPosting);
		Else
			vChargeObj.SetDeletionMark(True);
		EndIf;
	EndDo;
EndProcedure // UndoPosting

// --------------------------------------------------------------------------------
Procedure Filling(pFillingData, pFillingText, pStandardProcessing)
	If IsNew() Then
		If Not ValueIsFilled(Author) Then
			Author = SessionParameters.CurrentUser;
		EndIf;
		If Not ValueIsFilled(Date) Then
			Date = CurrentSessionDate();
		EndIf;
		If Not ValueIsFilled(ExchangeRateDate) Then
			ExchangeRateDate = Date;
		EndIf;
		OperationType = Enums.BonusesPaymentTypes.Receipt;
		If Not ValueIsFilled(Hotel) Then
			Hotel = SessionParameters.CurrentHotel;
		EndIf;
		IsByCharges = False;
	EndIf;
	If Not pFillingData = Undefined Then
		If TypeOf(pFillingData) = Type("CatalogRef.DiscountCards") Then
			Card = pFillingData;
			Guest = pFillingData.Client;
			Folio = pFillingData.Folio;
			If ValueIsFilled(Folio) Then
				Currency = Folio.FolioCurrency;
			ElsIf ValueIsFilled(Hotel) Then
				Currency = Hotel.FolioCurrency;
			EndIf;
			If ValueIsFilled(Card.DiscountType) And ValueIsFilled(Card.DiscountType.BonusesValidity) Then
				BonusesValidity = Card.DiscountType.BonusesValidity;
			EndIf;
		ElsIf TypeOf(pFillingData.Ref) = Type("DocumentRef.Payment") Then
			Hotel = pFillingData.Hotel;
			Payment = pFillingData.Ref;
			Currency = pFillingData.PaymentCurrency;
			Folio = pFillingData.Folio;
			If ValueIsFilled(Payment.PaymentMethod) Then
				If Not Payment.PaymentMethod.IsByBonuses And Not Payment.PaymentMethod.IsByGiftCertificate Then
					OperationType = Enums.BonusesPaymentTypes.Receipt;
				Else
					OperationType = Enums.BonusesPaymentTypes.Expense;
				EndIf;
			EndIf;
			// Fill attributes
			Card = pFillingData.DiscountCard;
			If ValueIsFilled(Card) Then
				Guest = Card.Client;
				If ValueIsFilled(Card.DiscountType) And ValueIsFilled(Card.DiscountType.BonusesValidity) Then
					BonusesValidity = Card.DiscountType.BonusesValidity;
				EndIf;
			EndIf;
			BonusesQuantity = 0;
			BonusesAmount = pFillingData.Sum;
			GuestGroup = pFillingData.GuestGroup;
			If ValueIsFilled(pFillingData.ParentDoc) And Not pFillingData.ParentDoc.Metadata().Attributes.Find("Room") = Undefined Then
				Room = pFillingData.ParentDoc.Room;
			EndIf;
		ElsIf TypeOf(pFillingData.Ref) = Type("DocumentRef.Return") Then
			Hotel = pFillingData.Hotel;
			Payment = pFillingData.Ref;
			Currency = pFillingData.PaymentCurrency;
			Folio = pFillingData.Folio;
			If ValueIsFilled(Payment.PaymentMethod) Then
				If Not Payment.PaymentMethod.IsByBonuses And Not Payment.PaymentMethod.IsByGiftCertificate Then
					OperationType = Enums.BonusesPaymentTypes.Expense;
				Else
					OperationType = Enums.BonusesPaymentTypes.Receipt;
				EndIf;
            EndIf;
			// Fill attributes
			Card = pFillingData.DiscountCard;
			If ValueIsFilled(Card) Then
				Guest = Card.Client;
				If ValueIsFilled(Card.DiscountType) And ValueIsFilled(Card.DiscountType.BonusesValidity) Then
					BonusesValidity = Card.DiscountType.BonusesValidity;
				EndIf;
			EndIf;
			BonusesQuantity = 0;
			BonusesAmount = pFillingData.Sum;
			GuestGroup = pFillingData.GuestGroup;
			If ValueIsFilled(pFillingData.ParentDoc) Then
				Room = pFillingData.ParentDoc.Room;
			EndIf;
        ElsIf TypeOf(pFillingData.Ref) = Type("DocumentRef.DepositTransfer") Then  
			OperationType = Enums.BonusesPaymentTypes.Receipt;
            Hotel = pFillingData.Hotel;
			Payment = pFillingData.Ref;
			Currency = pFillingData.FolioToCurrency;
			Folio = pFillingData.FolioTo;
			// Fill attributes
			Card = GetDiscountCardByFolio(Payment.FolioTo);
			If ValueIsFilled(Card) Then
				Guest = Card.Client;
				If ValueIsFilled(Card.DiscountType) And ValueIsFilled(Card.DiscountType.BonusesValidity) Then
					BonusesValidity = Card.DiscountType.BonusesValidity;
				EndIf;
			EndIf;
			BonusesQuantity = 0;
			BonusesAmount = pFillingData.SumInFolioToCurrency;
			If ValueIsFilled(pFillingData.ParentDoc) Then
				Room = pFillingData.ParentDoc.Room;
                GuestGroup = pFillingData.ParentDoc.GuestGroup;
			EndIf;
		ElsIf TypeOf(pFillingData.Ref) = Type("DocumentRef.Folio") Then 
			IsByCharges = True;
			OperationType = Enums.BonusesPaymentTypes.Expense;
            Hotel = pFillingData.Hotel;
			Folio = pFillingData.Ref;
			Currency = Folio.FolioCurrency;
			Guest = Folio.Client;
			Room = Folio.Room;
            GuestGroup = Folio.GuestGroup;
			BonusesQuantity = 0;
			BonusesAmount = 0;
			// Fill attributes 
			vParentDoc = Folio.ParentDoc;
			If ValueIsFilled(vParentDoc) Then
				vDiscountCard = vParentDoc.DiscountCard;
				If ValueIsFilled(vDiscountCard) And 
				  (vDiscountCard.LoyaltyType = Enums.LoyaltyType.Bonuses Or 
				   vDiscountCard.LoyaltyType = Enums.LoyaltyType.Certificate) Then
					Card = vDiscountCard;
				EndIf;
			EndIf;
			If Not ValueIsFilled(Card) And ValueIsFilled(Folio.Client) Then
				Card = GetBonusesCardByClient(Folio.Client);
			EndIf;
			If ValueIsFilled(Card) Then
				If ValueIsFilled(Card.Client) Then
					Guest = Card.Client;
				EndIf;
				If ValueIsFilled(Card.DiscountType) And ValueIsFilled(Card.DiscountType.BonusesValidity) Then
					BonusesValidity = Card.DiscountType.BonusesValidity;
				EndIf;
				vDataCard = AccumulationRegisters.Bonuses.mmGetBalanceByCard(Card, Date, ExchangeRateDate, Hotel);
				BonusesAvailable = cmRoundDown(vDataCard.Balance/?(vDataCard.BonusRate = 0, 1, vDataCard.BonusRate), 2);
			EndIf;
			// Transactions
			vCorrections = New ValueList();
			vChargesToSkip = New ValueList();
			vFolioCharges = Folio.GetObject().pmGetAllFolioCharges();
			For Each vFolioChargesRow In vFolioCharges Do
				vChargeRef = vFolioChargesRow.Document;
				If TypeOf(vChargeRef) = Type("DocumentRef.Storno") Then
					If vChargesToSkip.FindByValue(vChargeRef.ParentCharge) = Undefined Then
						vChargesToSkip.Add(vChargeRef.ParentCharge);
					EndIf;
				Else
					If ValueIsFilled(vChargeRef.CorrectedCharge) Then
						If vCorrections.FindByValue(vChargeRef) = Undefined Then
							vCorrections.Add(vChargeRef);
						EndIf;
					EndIf;
				EndIf;
			EndDo;
			vChargesRow = Undefined;
			For Each vFolioChargesRow In vFolioCharges Do
				vChargeRef = vFolioChargesRow.Document;
				If TypeOf(vChargeRef) = Type("DocumentRef.Charge") Then
					If vChargesToSkip.FindByValue(vChargeRef) = Undefined And vCorrections.FindByValue(vChargeRef) = Undefined Then
						If vChargeRef.IsMergedToRoomRevenue And ValueIsFilled(vChargeRef.RoomRevenueCharge) And 
						   vChargeRef.RoomRevenueCharge <> vChargeRef And vChargesRow <> Undefined And 
						   vChargesRow.Service = vChargeRef.RoomRevenueCharge.Service Then
							vChargesRow.Sum = vChargesRow.Sum + vChargeRef.Sum - vChargeRef.DiscountSum;
							vChargesRow.Price = Round(vChargesRow.Sum/vChargesRow.Quantity, 2);
						Else
							vChargesRow = ChargesPaidByBonuses.Add();
							vChargesRow.AccountingDate = BegOfDay(?(ValueIsFilled(vChargeRef.ServiceDate), vChargeRef.ServiceDate, vChargeRef.Date));
							vChargesRow.Service = vChargeRef.Service;
							vChargesRow.Unit = vChargeRef.Unit;
							vChargesRow.Quantity = ?(vChargeRef.Quantity = 0, 1, vChargeRef.Quantity);
							vChargesRow.Sum = vChargeRef.Sum - vChargeRef.DiscountSum;
							vChargesRow.Price = Round(vChargesRow.Sum/vChargesRow.Quantity, 2);
							vChargesRow.Charge = vChargeRef;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
			For Each vCorrectionsItem In vCorrections Do
				vCorrectionRef = vCorrectionsItem.Value;
				vChargeRef = vCorrectionRef.CorrectedCharge;
				If ValueIsFilled(vChargeRef) Then
					vChargesRow = ChargesPaidByBonuses.Find(vChargeRef, "Charge");
					If vChargesRow <> Undefined Then
						vChargesRow.Sum = vChargesRow.Sum + vCorrectionRef.Sum - vCorrectionRef.DiscountSum;
						vChargesRow.Price = Round(vChargesRow.Sum/?(vChargesRow.Quantity = 0, 1, vChargesRow.Quantity), 2);
					Endif;
				EndIf;
			EndDo;
			// Remove rows with negative amounts
			i = 0;
			While i < ChargesPaidByBonuses.Count() Do
				vChargesRow = ChargesPaidByBonuses.Get(i);
				If vChargesRow.Sum < 0 Then
					ChargesPaidByBonuses.Delete(i);
				Else
					i = i + 1;
				EndIf;
			EndDo;
			// Remove rows with services not in the card discount type services group
			If ValueIsFilled(Card) And ValueIsFilled(Card.DiscountType) Then
				vDiscountType = Card.DiscountType;
				If ValueIsFilled(vDiscountType.DiscountServiceGroup) Then
					i = 0;
					While i < ChargesPaidByBonuses.Count() Do
						vChargesRow = ChargesPaidByBonuses.Get(i);
						If Not cmIsServiceInServiceGroup(vChargesRow.Service, vDiscountType.DiscountServiceGroup) Then
							vChargesRow.ShouldBeSkipped = True;
						Else
							vChargesRow.ShouldBeSkipped = False;
						EndIf;
						i = i + 1;
					EndDo;
				EndIf;
			EndIf;
		ElsIf TypeOf(pFillingData.Ref) = Type("DocumentRef.BonusesPayment") Then
			FillPropertyValues(ThisObject, pFillingData, "IsByCharges, BonusesQuantity, BonusesAmount, Card, Guest, GuestGroup, Hotel, Payment, Remarks, Room, Source, Folio, Currency, ExchangeRateDate, BonusRate");
			If pFillingData.OperationType = Enums.BonusesPaymentTypes.Receipt Then
				OperationType = Enums.BonusesPaymentTypes.Expense;
			Else
				OperationType = Enums.BonusesPaymentTypes.Receipt;
			EndIf;
			For Each vFillingChargesRow In pFillingData.ChargesPaidByBonuses Do
				vChargesRow = ChargesPaidByBonuses.Add();
				FillPropertyValues(vChargesRow, vFillingChargesRow);
			EndDo;
		EndIf;	
		// Check currency
		If Not ValueIsFilled(Currency) And ValueIsFilled(Hotel) Then
			Currency = Hotel.FolioCurrency;
		EndIf;
		// Bonus calculation rate
		BonusRate = pmGetBonusRate();
		If BonusRate <> 0 Then
			If BonusesAmount <> 0 And BonusesQuantity = 0 Then
				BonusesQuantity = Round(BonusesAmount * BonusRate, 2);
			ElsIf BonusesAmount = 0 And BonusesQuantity <> 0 Then
				BonusesAmount = Round(BonusesQuantity / BonusRate, 2);
			EndIf;
		EndIf;
		// Get balance
		If ValueIsFilled(Card) Then
			vDataCard = AccumulationRegisters.Bonuses.mmGetBalanceByCard(Card, Date, ExchangeRateDate, Hotel);
			BonusesAvailable = vDataCard.Balance;
			If BonusRate <> 0 Then
				AmountAvailable = Round(BonusesAvailable / BonusRate, 2);
			EndIf;
		EndIf;
		// Check if operation is possible
		If TypeOf(pFillingData.Ref) = Type("DocumentRef.Payment") Or
		   TypeOf(pFillingData.Ref) = Type("DocumentRef.Return") Or
		   TypeOf(pFillingData.Ref) = Type("DocumentRef.DepositTransfer") Then
		    // Do check
			If OperationType = Enums.BonusesPaymentTypes.Expense And BonusesAmount <> 0 Then
				vErr = "";
				If Not CheckBonusesBalanceAndSections(vErr, pFillingData) Then
					Raise vErr;
				EndIf;	
			EndIf;	
		EndIf;	
	EndIf;
EndProcedure // Filling

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
	ExternalCode = "";
EndProcedure // OnCopy

// -----------------------------------------------------------------------------
Procedure FillCheckProcessing(pCancel, pCheckedAttributes)
	If AdditionalProperties.Property("CheckedAttributes") Then
		For Each vId In AdditionalProperties.CheckedAttributes Do
			pCheckedAttributes.Add(vId);       
		EndDo;	
	EndIf;
EndProcedure // FillCheckProcessing

// -----------------------------------------------------------------------------
Procedure BeforeDelete(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	// User activity history   
	vEventDescription = StrTemplate(NStr("en = 'Document deletion: %1, %2, %3'; 
										 |de = 'Dokument Löschung: %1, %2, %3'; 
										 |ru = 'Непосредственное удаление: %1, %2, %3'"), 
	                                TrimAll(Card), Format(BonusesAmount, "NFD=2; NZ="), TrimAll(Ref));  
	vParentDoc = Ref;
	If ValueIsFilled(Folio) And ValueIsFilled(Folio.ParentDoc) Then
		vParentDoc = Folio.ParentDoc;
	ElsIf ValueIsFilled(Payment) And ValueIsFilled(Payment.ParentDoc) Then
		vParentDoc = Payment.ParentDoc;
	EndIf;	
	InformationRegisters.UserActionsHistory.WriteUserActivityRecord(vParentDoc, vEventDescription, Hotel);
EndProcedure // BeforeDelete

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pWriteMode, pPostingMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	If pWriteMode = DocumentWriteMode.Posting Then
		vErrorMessage = "";
		pCancel = Not pmCheckDocumentAttributes(vErrorMessage);
		If pCancel Then
			tcCommonFunctionOnClientServer.TextMessage(vErrorMessage, MessageStatus.Attention);
		EndIf;
	EndIf;
	// Check if hotel accounting date is closed
	If Not pCancel And ValueIsFilled(Hotel) And Hotel.DoNotEditClosedDateDocs And 
	  (pWriteMode = DocumentWriteMode.Posting Or pWriteMode = DocumentWriteMode.UndoPosting) Then
		If Ref.IsEmpty() Or Not Ref.IsEmpty() And 
	      (Ref.BonusesQuantity <> BonusesQuantity Or Ref.BonusesAmount <> BonusesAmount Or Ref.DeletionMark <> DeletionMark Or Ref.Posted <> Posted) Then
			vDocIsInClosedDay = cmIfChargeIsInClosedDay(ThisObject);
			If vDocIsInClosedDay Then
				pCancel = True;
				If IsNew() Then
					tcCommonFunctionOnClientServer.TextMessage(NStr("en='Document date is closed! You can not post operation to this day.';
					                                                |ru='День закрыт! Нельзя провести операцию этой датой.';
					                                                |de='Der Tag ist geschlossen! Eine Zahlung zu diesem Datum ist nicht möglich.'"), MessageStatus.Attention);
				Else
					tcCommonFunctionOnClientServer.TextMessage(NStr("en='This document is in closed day! Document is read only.';
					                                                |ru='Документ в закрытом дне! Редактирование такого документа запрещено.';
					                                                |de='Dokument am geschlossenen Tag! Die Bearbeitung einer solchen Dokument ist verboten.'"), MessageStatus.Attention);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
Function pmCheckDocumentAttributes(rMessage) Export
	vOk = True;
	rMessage = "";
	If AdditionalProperties.Property("InfoBaseUpdateMode") And AdditionalProperties.InfoBaseUpdateMode Then
		Return vOk;
	EndIf;
	If Not ValueIsFilled(Card) Then
		vOk = False;
		rMessage = rMessage + ?(IsBlankString(rMessage), "", Chars.LF + Chars.LF);
		rMessage = rMessage + NStr("en = 'Card should be filled!'; 
		                           |de = 'Eine Karte angeben müssen!'; 
		                           |ru = 'Карта должна быть указана!'");
	EndIf;
	If Not ValueIsFilled(Card.LoyaltyType) Then
		vOk = False;
		rMessage = rMessage + ?(IsBlankString(rMessage), "", Chars.LF + Chars.LF);
		rMessage = rMessage + NStr("en = 'Card loyalty type should be filled!'; 
		                           |de = 'Der Kartenloyalitätstyp sollte ausgefüllt werden!'; 
		                           |ru = 'У карты должен быть указан вид системы лояльности!'");
	EndIf;
	If Not ValueIsFilled(Card.DiscountType) Then
		vOk = False;
		rMessage = rMessage + ?(IsBlankString(rMessage), "", Chars.LF + Chars.LF);
		rMessage = rMessage + NStr("en = 'Card discount type should be filled!'; 
		                           |de = 'Der Kartenrabatttyp sollte ausgefüllt werden!'; 
		                           |ru = 'У карты должен быть указан тип скидки!'");
	EndIf;
	If BonusesAmount = 0 Then
		vOk = False;
		rMessage = rMessage + ?(IsBlankString(rMessage), "", Chars.LF + Chars.LF);
		rMessage = rMessage + NStr("en = 'The amount must be greater than zero!'; 
		                           |de = 'Der Betrag muss größer als Null sein!'; 
		                           |ru = 'Сумма должна быть больше нуля!'");
	EndIf;
	If Not Posted Then
		If Card.IsBlocked Then
			vOk = False;
			rMessage = rMessage + ?(IsBlankString(rMessage), "", Chars.LF + Chars.LF);
			rMessage = rMessage + NStr("en = 'The card is blocked!'; de = 'Die Karte ist gesperrt!'; ru = 'Карта заблокирована!'");
		EndIf;	
	EndIf;	
	If ValueIsFilled(Card.ValidTo) And EndOfDay(Card.ValidTo) < Date Then
		vOk = False;
		vMsg = NStr("en = 'Card is expired %1'; de = 'Karte ist abgelaufen von %1'; ru = 'Период действия карты истек %1'");
		vMsg = StrTemplate(vMsg, Card.ValidTo);
		rMessage = rMessage + ?(IsBlankString(rMessage), "", Chars.LF + Chars.LF);
		rMessage = rMessage + vMsg;
	EndIf;	
	vIsCertificate = Card.LoyaltyType = Enums.LoyaltyType.Certificate;
	If vIsCertificate And OperationType = Enums.BonusesPaymentTypes.Expense And BonusesQuantity > BonusesAvailable Then
		// Certificate
		vOk = False;
		vMsg = NStr("en='You are trying to write off %1 from certificate from the %2 available!';
					|de='Sie versuchen, %1 -Zertifikat von den verfügbaren %2 -Boni abzuschreiben!';
					|ru='Пытаетесь списать %1 сертификат из имеющихся %2!'");
		vMsg = StrTemplate(vMsg, Format(BonusesQuantity, "ND=17; NFD=0; NZ=0.00; NG="), Format(BonusesAvailable, "ND=17; NFD=0; NZ=0.00; NG="));
		rMessage = rMessage + ?(IsBlankString(rMessage), "", Chars.LF + Chars.LF);
		rMessage = rMessage + vMsg;
	ElsIf Not vIsCertificate And OperationType = Enums.BonusesPaymentTypes.Expense And BonusesQuantity > BonusesAvailable Then
		// Bonuses
		vOk = False;
		vMsg = NStr("en='You are trying to write off %1 bonuses from the %2 available!';
					|de='Sie versuchen, %1 -Boni von den verfügbaren %2 -Boni abzuschreiben!';
					|ru='Пытаетесь списать %1 бонусов из имеющихся %2!'");
		vMsg = StrTemplate(vMsg, Format(BonusesQuantity, "ND=17; NFD=0; NZ=0.00; NG="), Format(BonusesAvailable, "ND=17; NFD=0; NZ=0.00; NG="));
		rMessage = rMessage + ?(IsBlankString(rMessage), "", Chars.LF + Chars.LF);
		rMessage = rMessage + vMsg;
	EndIf;
	If IsByCharges Then
		If BonusesQuantity <> ChargesPaidByBonuses.Total("BonusesQuantity") Or BonusesAmount <> ChargesPaidByBonuses.Total("BonusesAmount") Then
			vOk = False;
			rMessage = rMessage + ?(IsBlankString(rMessage), "", Chars.LF + Chars.LF);
			rMessage = rMessage + NStr("en='Total bonuses in charges table should be equal to the document bonuses attribute!';
			                           |ru='Итог по бонусам из таблицы начислений должен совпадать с бонусами в шапке документа!';
			                           |de='Das Ergebnis für die Boni aus der Abrechnungstabelle muss mit den Boni in der Dokumentenkapsel übereinstimmen!'");
		EndIf;
		If ValueIsFilled(Card) And OperationType = Enums.BonusesPaymentTypes.Expense Then
			vDiscountType = Card.DiscountType;
			If ValueIsFilled(vDiscountType) Then
				vMaxPercentPayment = vDiscountType.MaxPercentPayment;
				If vMaxPercentPayment > 0 Then
					For Each vChargesRow In ChargesPaidByBonuses Do
						If ValueIsFilled(vChargesRow.Charge) Then
							If IfOtherBonusPaymentForChargeExists(vChargesRow.Charge, Ref) Then
								vOk = False;
								rMessage = rMessage + ?(IsBlankString(rMessage), "", Chars.LF + Chars.LF);
								rMessage = rMessage + StrTemplate(NStr("en='You can use bonuses to pay not more then %1 percent of services charged! You have already used bonuses to pay for service in row %2.'; 
								                                       |ru='Сумма списываемых бонусов не может превышать %1 процентов от суммы начислений! Уже использовали бонусы для оплаты услуги в строке %2.'; 
								                                       |de='Die ausstehenden Boni dürfen %1 Prozent des Servicebetrags nicht überschreiten! Sie haben bereits Boni verwendet, um den Service in Zeile %2 zu bezahlen.'"), 
								                                  Format(vMaxPercentPayment, "NFD=1; NZ=; NG="), Format(vChargesRow.LineNumber, "NFD=0; NZ=; NG="));
								Break;
							EndIf;
						EndIf;
					EndDo;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	Return vOK;
EndFunction // pmCheckDocumentAttributes

// --------------------------------------------------------------------------------
Function pmGetBonusRate() Export
	vBonusRate = 1;
	If ValueIsFilled(Card) And ValueIsFilled(Card.DiscountType) And Card.DiscountType.BonusRateMultiplier <> 0 Then
		vBonusRate = Card.DiscountType.BonusRateMultiplier;
	EndIf;
	If ValueIsFilled(Currency) Then
		vRates = InformationRegisters.CurrencyRates.SliceLast(?(ValueIsFilled(ExchangeRateDate), ExchangeRateDate, Date), New Structure("Hotel, Currency", Hotel, Currency));
		If vRates.Count() > 0 Then
			vRatesRow = vRates.Get(0);
			If vRatesRow.BonusRate <> 0 Then
				vBonusRate = Round(vRatesRow.BonusRate * vBonusRate, 4);
			ElsIf vRatesRow.Rate <> 0 Then
				vBonusRate = Round(vRatesRow.Rate / ?(vRatesRow.Factor = 0, 1, vRatesRow.Factor) * vBonusRate, 4);
			EndIf;
		EndIf;
	EndIf;
	Return vBonusRate;
EndFunction // pmGetBonusRate

// --------------------------------------------------------------------------------
Function CheckBonusesBalanceAndSections(rMessage = "", pFillingData)
	vOK = True;
	vPaymentMethod = pFillingData.PaymentMethod;
	// Check
	If OperationType = Enums.BonusesPaymentTypes.Expense Then
		If BonusesAvailable > 0 Then
			If BonusesQuantity <> 0 Then
				If BonusesQuantity > BonusesAvailable Then
					vOK = False;
					rMessage = NStr("en='You are trying to write off " + Format(BonusesQuantity, "ND=17; NFD=0; NG=") + " bonuses from the " + Format(BonusesAvailable, "ND=17; NFD=0; NG=") + " available! Maximum bonuses payment amount is " + cmFormatSum(AmountAvailable, Currency) + "';
					                |de='You are trying to write off " + Format(BonusesQuantity, "ND=17; NFD=0; NG=") + " bonuses from the " + Format(BonusesAvailable, "ND=17; NFD=0; NG=") + " available! Maximum bonuses payment amount is " + cmFormatSum(AmountAvailable, Currency) + "';
					                |ru='Пытаетесь списать " + Format(BonusesQuantity, "ND=17; NFD=0; NG=") + " бонусов из имеющихся " + Format(BonusesAvailable, "ND=17; NFD=0; NG=") + "! Максимальная сумма оплаты бонусами " + cmFormatSum(AmountAvailable, Currency) + "'");
				ElsIf BonusesAvailable < vPaymentMethod.MinimumBonuses Then
					vOK = False;
					rMessage = NStr("en='Minimum amount of bonuses allowed for payment is " + Format(vPaymentMethod.MinimumBonuses, "ND=17; NFD=0; NG=") + "! You have " + Format(BonusesAvailable, "ND=17; NFD=0; NG=") + " bonuses';
					                |de='Minimum amount of bonuses allowed for payment is " + Format(vPaymentMethod.MinimumBonuses, "ND=17; NFD=0; NG=") + "! You have " + Format(BonusesAvailable, "ND=17; NFD=0; NG=") + " bonuses';
					                |ru='Списывать бонусы в счет оплаты услуг можно только при накоплении как минимум " + Format(vPaymentMethod.MinimumBonuses, "ND=17; NFD=0; NG=") + " бонусов! Уже начислено " + Format(BonusesAvailable, "ND=17; NFD=0; NG=") + " бонусов'");
				EndIf;
			EndIf;
			vPaymentSection = pFillingData.PaymentSection;
			// Check sections
			If pFillingData.PaymentSections.Count() > 0 Then
				For Each PaymentSectionsRow In pFillingData.PaymentSections Do
					If ValueIsFilled(PaymentSectionsRow.ChequeService) And PaymentSectionsRow.Sum <> 0 Then
						If PaymentSectionsRow.ChequeService.BonusPaymentsNotAllowed Then
							vOK = False;
							rMessage = NStr("en='Bonus payment is not allowed for the " + TrimAll(PaymentSectionsRow.ChequeService) + " service!'; 
							                |de='Bonus payment is not allowed for the " + TrimAll(PaymentSectionsRow.ChequeService) + " service!'; 
							                |ru='Для услуги " + TrimAll(PaymentSectionsRow.ChequeService) + " оплата бонусами не разрешена!'");
							Break;
						EndIf;
					EndIf;
					If ValueIsFilled(PaymentSectionsRow.PaymentSection) And PaymentSectionsRow.Sum <> 0 Then
						If PaymentSectionsRow.PaymentSection.BonusPaymentsNotAllowed Then
							vOK = False;
							rMessage = NStr("en='Bonus payment is not allowed for the " + TrimAll(PaymentSectionsRow.PaymentSection) + " payment section!'; 
							                |de='Bonus payment is not allowed for the " + TrimAll(PaymentSectionsRow.PaymentSection) + " payment section!'; 
							                |ru='Для секции оплаты " + TrimAll(PaymentSectionsRow.PaymentSection) + " оплата бонусами не разрешена!'");
							Break;
						EndIf;
					EndIf;
				EndDo;
			ElsIf ValueIsFilled(vPaymentSection) Then
				If vPaymentSection.BonusPaymentsNotAllowed Then
					vOK = False;
					rMessage = NStr("en='Bonus payment is not allowed for the " + TrimAll(vPaymentSection) + " payment section!'; 
					                |de='Bonus payment is not allowed for the " + TrimAll(vPaymentSection) + " payment section!'; 
					                |ru='Для секции оплаты " + TrimAll(vPaymentSection) + " оплата бонусами не разрешена!'");
				EndIf;
			EndIf;
		Else
			vOK = False;
			rMessage = NStr("en='Bonuses balance should be greater then zero!';
			                |ru='Баланс бонусов должен быть больше нуля!';
			                |de='Das Bonusguthaben muss größer als Null sein!'");
		EndIf;
	EndIf;
	Return vOK;
EndFunction // CheckBonusesBalanceAndSections

// --------------------------------------------------------------------------------
Procedure PostBonuses(pSourceCard, pCancel)
	RegisterRecords.Bonuses.Write = True;
	
	If ValueIsFilled(Card) And ValueIsFilled(Date) Then
		If OperationType = Enums.BonusesPaymentTypes.Receipt Then
			vRecord = RegisterRecords.Bonuses.Add();
			vRecord.RecordType = AccumulationRecordType.Receipt;
			vRecord.Period = Date;
			vRecord.Card = Card;
			vRecord.ExpiryDate = ?(BonusesValidity > 0, BegOfDay(Date) + BonusesValidity * 24 * 3600, '00010101');
			vRecord.Quantity = BonusesQuantity;
		Else
			If BonusesValidity > 0 And BonusesQuantity > 0 Then
				vBonusesBalances = cmGetBonusesBalancePerExpiryDates(Card, Date);
				vBonusesQuantity = BonusesQuantity;
				
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
				vRecord.ExpiryDate = '00010101';
				vRecord.Quantity = BonusesQuantity;
			EndIf;
		EndIf;

		// Write off from source card	
		If ValueIsFilled(pSourceCard) Then
			If OperationType = Enums.BonusesPaymentTypes.Receipt Then
				If BonusesValidity > 0 And BonusesQuantity > 0 Then
					vBonusesQuantity = BonusesQuantity;
					vBonusesBalances = cmGetBonusesBalancePerExpiryDates(pSourceCard, Date);
					
					For Each vBonusesBalancesRow In vBonusesBalances Do
						If vBonusesBalancesRow.QuantityBalance > 0 Then
							vRecord = RegisterRecords.Bonuses.Add();
							vRecord.RecordType = AccumulationRecordType.Expense;
							vRecord.Period = Date;
							vRecord.Card = pSourceCard;
							vRecord.Quantity = Min(vBonusesBalancesRow.QuantityBalance, vBonusesQuantity);
							vRecord.ExpiryDate = vBonusesBalancesRow.ExpiryDate;
							
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
							                   TrimAll(pSourceCard), 
							                   Format(vBonusesQuantity, "NZ=; NG="));
											   
							vUsrMsg = New UserMessage();
							vUsrMsg.Text = vMsg;
							vUsrMsg.Message();
						Else
							vRecord = RegisterRecords.Bonuses.Add();
							vRecord.RecordType = AccumulationRecordType.Expense;
							vRecord.Period = Date;
							vRecord.Card = pSourceCard;
							vRecord.ExpiryDate = '00010101';
							vRecord.Quantity = vBonusesQuantity;
						EndIf;
					EndIf;
				Else
					vRecord = RegisterRecords.Bonuses.Add();
					vRecord.RecordType = AccumulationRecordType.Expense;
					vRecord.Period = Date;
					vRecord.Card = pSourceCard;
					vRecord.ExpiryDate = '00010101';
					vRecord.Quantity = BonusesQuantity;
				EndIf;
			Else
				vRecord = RegisterRecords.Bonuses.Add();
				vRecord.RecordType = AccumulationRecordType.Receipt;
				vRecord.Period = Date;
				vRecord.Card = pSourceCard;
				vRecord.ExpiryDate = ?(BonusesValidity > 0, BegOfDay(Date) + BonusesValidity * 24 * 3600, '00010101');
				vRecord.Quantity = BonusesQuantity;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PostBonuses

// --------------------------------------------------------------------------------
Procedure PostRevenueCorrection()
	// Read all charges createdd by previous posting
	vCorrectionCharges = pmGetCorrectionCharges();

	// Create correction charges for all rows in the document tabular part
	For Each vChargesPaidByBonusesRow In ChargesPaidByBonuses Do
		vBasisCharge = vChargesPaidByBonusesRow.Charge;
		If Not ValueIsFilled(vBasisCharge) Then
			Continue;
		EndIf;

		// Try to find previously created correction charge. 
		vCorrectionChargesRow = vCorrectionCharges.Find(vBasisCharge, "CorrectedCharge");
		
		// Update or cancel it if found
		If vChargesPaidByBonusesRow.BonusesAmount <> 0 Then
			vDesiredChargeDate = Undefined;
			If vCorrectionChargesRow = Undefined Then
				vCorrectionChargeObj = vBasisCharge.Copy();
				vCorrectionChargeObj.pmFillAuthorAndDate();
				If ValueIsFilled(vCorrectionChargeObj.Hotel) And ValueIsFilled(vCorrectionChargeObj.Hotel.AccountingDate) And 
				   BegOfDay(vCorrectionChargeObj.Date) > BegOfDay(vCorrectionChargeObj.Hotel.AccountingDate) Then
					vDesiredChargeDate = EndOfDay(vCorrectionChargeObj.Hotel.AccountingDate);
					vCorrectionChargeObj.Date = vDesiredChargeDate;
					vCorrectionChargeObj.SetTime(AutoTimeMode.DontUse);
				EndIf;
				If Year(vBasisCharge.Date) <> Year(vCorrectionChargeObj.Date) Then
					vCorrectionChargeObj.SetNewNumber();
				EndIf;
			Else
				vCorrectionChargeObj = vCorrectionChargesRow.Ref.GetObject();
			EndIf;
			
			// Update document
			vCorrectionChargeObj.IsAdditional = True;
			If ValueIsFilled(vBasisCharge.ServiceDate) Then
				vCorrectionChargeObj.ServiceDate = vBasisCharge.ServiceDate;
			Else
				vCorrectionChargeObj.ServiceDate = vBasisCharge.Date;
			EndIf;
			vCorrectionChargeObj.CorrectedCharge = vBasisCharge;
			vCorrectionChargeObj.IsCorrection = True;
			vCorrectionChargeObj.CorrectionDate = vBasisCharge.Date;
			vCorrectionChargeObj.ChargeCorrectionType = Enums.ChargeCorrectionTypes.Correction;
			vCorrectionChargeObj.RoomRevenueCharge = Undefined;
			vCorrectionChargeObj.IsMergedToRoomRevenue = False;
			
			vCorrectionChargeObj.ChargeTransfer = Undefined;
			
			vCorrectionChargeObj.AgentCommission = 0;
			vCorrectionChargeObj.VATCommissionSum = 0;
			vCorrectionChargeObj.AgentCommissionType = Undefined;
			vCorrectionChargeObj.AgentCommissionServiceGroup = Undefined;
			vCorrectionChargeObj.CommissionSum = 0;
			
			vCorrectionChargeObj.DiscountSum = 0;
			vCorrectionChargeObj.VATDiscountSum = 0;
			vCorrectionChargeObj.Discount = 0;
			vCorrectionChargeObj.DiscountCard = Undefined;
			vCorrectionChargeObj.DiscountType = Undefined;
			vCorrectionChargeObj.DiscountServiceGroup = Undefined;
			vCorrectionChargeObj.DiscountConfirmationText = Undefined;
			
			vCorrectionChargeObj.RoomsRented = 0;
			vCorrectionChargeObj.BedsRented = 0;
			vCorrectionChargeObj.AdditionalBedsRented = 0;
			vCorrectionChargeObj.GuestDays = 0;
			vCorrectionChargeObj.GuestsCheckedIn = 0;
			
			vCorrectionChargeObj.RateSum = 0;
			vCorrectionChargeObj.RateDiscountSum = 0;
			vCorrectionChargeObj.RateCommissionSum = 0;
			
			If OperationType = Enums.BonusesPaymentTypes.Expense Then
				vCorrectionChargeObj.Sum = -vChargesPaidByBonusesRow.BonusesAmount;
			Else
				vCorrectionChargeObj.Sum = vChargesPaidByBonusesRow.BonusesAmount;
			EndIf;
			vCorrectionChargeObj.Price = 0;
			vCorrectionChargeObj.Quantity = 0;
			vCorrectionChargeObj.VATSum = cmCalculateVATSum(vCorrectionChargeObj.VATRate, vCorrectionChargeObj.Sum, vCorrectionChargeObj.Date);
			
			vK2 = vCorrectionChargeObj.Sum/(vBasisCharge.Sum - vBasisCharge.DiscountSum);
			vCorrectionChargeObj.CommissionSum = ?(vCorrectionChargeObj.Sum < 0, -1, 1) * Round(vBasisCharge.CommissionSum * vK2, 2);
			vCorrectionChargeObj.VATCommissionSum = cmCalculateVATSum(vCorrectionChargeObj.VATRate, vCorrectionChargeObj.CommissionSum, vCorrectionChargeObj.Date);
			
			vCorrectionChargeObj.BonusesPayment = Ref;
			
			If OperationType = Enums.BonusesPaymentTypes.Expense Then
				vCorrectionChargeObj.Remarks = ?(IsBlankString(Remarks), NStr("en='Bonuses expense '; ru='Списание бонусов '; de='Boniaufwand '") + cmFormatSum(ChargesPaidByBonuses.Total("BonusesAmount"), Currency) + NStr("en=' N'; ru=' №'; de=' Nr.'") + TrimAll(Number) + NStr("en=' from '; ru=' от '; de=' von '") + Format(Date, "DF='dd.MM.yyyy HH:mm:ss'") + ", " + TrimAll(Author), TrimAll(Remarks));
			Else
				vCorrectionChargeObj.Remarks = ?(IsBlankString(Remarks), NStr("en='Bonuses replenishment '; ru='Пополнение бонусов '; de='Boninachschub '") + cmFormatSum(ChargesPaidByBonuses.Total("BonusesAmount"), Currency) + NStr("en=' N'; ru=' №'; de=' Nr.'") + TrimAll(Number) + NStr("en=' from '; ru=' от '; de=' von '") + Format(Date, "DF='dd.MM.yyyy HH:mm:ss'") + ", " + TrimAll(Author), TrimAll(Remarks));
			EndIf;
			
			vCorrectionChargeObj.Write(DocumentWriteMode.Posting);
			If ValueIsFilled(vDesiredChargeDate) And vCorrectionChargeObj.Date <> vDesiredChargeDate Then
				vCorrectionChargeObj.Date = vDesiredChargeDate;
				vCorrectionChargeObj.Write(DocumentWriteMode.Posting);
			EndIf;
		Else
			If vCorrectionChargesRow <> Undefined Then
				vCorrectionChargeObj = vCorrectionChargesRow.Ref.GetObject();
				vCorrectionChargeObj.SetDeletionMark(True);
			EndIf;
		EndIf;
	EndDo;
	
	// Mark old correction charges that are not in the document now as deleted
	For Each vCorrectionChargesRow In vCorrectionCharges Do
		If ChargesPaidByBonuses.Find(vCorrectionChargesRow.CorrectedCharge, "Charge") = Undefined Then
			vCorrectionChargeObj = vCorrectionChargesRow.Ref.GetObject();
			vCorrectionChargeObj.SetDeletionMark(True);
		EndIf;
	EndDo;
EndProcedure // PostRevenueCorrection

// --------------------------------------------------------------------------------
Function CheckIsTransfer(pCancel)
	If ValueIsFilled(Payment) And Not TypeOf(Payment) = Type("DocumentRef.DepositTransfer") Then 
		If ValueIsFilled(Payment.DiscountCard) Then
			If tcOnServer.cmGetAttributeByRef(Payment.DiscountCard, "LoyaltyType") = PredefinedValue("Enum.LoyaltyType.Certificate") Then
				If tcOnServer.cmGetAttributeByRef(Payment.PaymentMethod,"IsByGiftCertificate") Then
					If ValueIsFilled(Payment.Folio) Then
						vSourceCard = GetDiscountCardByFolio(Payment.Folio);
						If ValueIsFilled(vSourceCard) Then
							If vSourceCard <> Payment.DiscountCard Then
								Return vSourceCard;
							Else
								pCancel = True;
								vMsg = Nstr("en = 'Transfer of funds canceled. The cards are identical.'; de = 'Überweisung storniert. Die Karten sind identisch.'; ru = 'Перенос средств отменен. Карты идентичны.'");
								Raise vMsg;	
							EndIf;	
						EndIf;
					EndIf;
				EndIf;	
			EndIf;
		EndIf;
	EndIf;
EndFunction // CheckIsTransfer

// -----------------------------------------------------------------------------
Function GetDiscountCardByFolio(pFolio)
	vDiscountCards = Catalogs.DiscountCards.EmptyRef();
	vQuery = New Query();
	vQuery.Text =
	"SELECT
	|	DiscountCards.Ref AS Ref
	|FROM
	|	Catalog.DiscountCards AS DiscountCards
	|WHERE
	|	NOT DiscountCards.DeletionMark
	|	AND DiscountCards.Folio = &qFolio
	|
	|ORDER BY
	|	DiscountCards.CreateDate DESC";
	vQuery.SetParameter("qFolio", pFolio);
	vResult = vQuery.Execute().Unload();
	If vResult.Count() > 0 Then
		vDiscountCards = vResult.Get(0).Ref;		
	EndIf;
	Return vDiscountCards;
EndFunction // GetDiscountCardByFolio

// -----------------------------------------------------------------------------
Function GetBonusesCardByClient(pClient)
	Return Catalogs.DiscountCards.GetBonusesCardByClient(pClient)
EndFunction // GetBonusesCardByClient

// --------------------------------------------------------------------------------
Function pmGetCorrectionCharges() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Charge.Ref AS Ref,
	|	Charge.CorrectedCharge AS CorrectedCharge
	|FROM
	|	Document.Charge AS Charge
	|WHERE
	|	Charge.BonusesPayment = &qBonusesPayment
	|
	|ORDER BY
	|	Charge.PointInTime";
	vQry.SetParameter("qBonusesPayment", Ref);
	Return vQry.Execute().Unload();
EndFunction // pmGetCorrectionCharges

// --------------------------------------------------------------------------------
Function IfOtherBonusPaymentForChargeExists(pCharge, pBonusesPayment)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Charges.CorrectedCharge AS Charge,
	|	SUM(CASE
	|			WHEN Charges.BonusesPayment.OperationType = VALUE(Enum.BonusesPaymentTypes.Receipt)
	|				THEN 1
	|			ELSE -1
	|		END) AS DocTotal
	|FROM
	|	Document.Charge AS Charges
	|WHERE
	|	Charges.CorrectedCharge = &qCharge
	|	AND Charges.BonusesPayment <> &qBonusesPayment
	|	AND Charges.BonusesPayment.Posted
	|	AND Charges.Posted
	|
	|GROUP BY
	|	Charges.CorrectedCharge";
	vQry.SetParameter("qCharge", pCharge);
	vQry.SetParameter("qBonusesPayment", pBonusesPayment);
	vDocs = vQry.Execute().Unload();
	If vDocs.Count() > 0 Then
		Return ?(vDocs.Get(0).DocTotal >= 0, False, True);
	Else
		Return False;
	EndIf;
EndFunction // IfOtherBonusPaymentForChargeExists

#EndRegion