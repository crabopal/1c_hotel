
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Save current user
	CurrentUser = SessionParameters.CurrentUser;
	IsRoomRatePosting = False;
	
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	vFormTitle = "";
	If ValueIsFilled(Object.Ref) Then
		vFormTitle = " - " + TrimAll(Object.Author);
		If ValueIsFilled(Object.Folio) And ValueIsFilled(Object.Folio.Client) Then
			vFormTitle = vFormTitle + " - " + TrimAll(TrimAll(Object.Room) + " " + TrimAll(Object.Folio.Client));
		EndIf;
		If Not IsBlankString(vFormTitle) Then
			AutoTitle = False;
			Title = TrimAll(Object.Ref) + vFormTitle;
		EndIf;
	ElsIf ValueIsFilled(Object.Folio) And ValueIsFilled(Object.Folio.Client) Then
		vFormTitle = TrimAll(Object.Folio.Client);
		If Not IsBlankString(vFormTitle) Then
			Title = vFormTitle;
		EndIf;
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Form open parameters
	If Not ValueIsFilled(Object.ServiceDate) And ValueIsFilled(Object.Date) Then
		Object.ServiceDate = BegOfDay(Object.Date);
	EndIf;
	If Parameters.Property("AdditionalParameters") Then
		vAdditionalParameters = Parameters.AdditionalParameters;
		If vAdditionalParameters.Property("Service") Then
			Object.Service = vAdditionalParameters.Service;
			Object.Price = vAdditionalParameters.Price;
			Object.Quantity = 1;
			CalculateSum();
			OldQuantity = Object.Quantity;
		EndIf;	
	EndIf;
	
	If ValueIsFilled(Object.Folio) And Object.Folio.IsClosed Then
		If ValueIsFilled(Object.Ref) Then
			ReadOnly = True;
			Items.FormSetDeletionMarkAction.Visible = False;
		Else
			pCancel = True;
			Return;
		EndIf;
	EndIf;
	
	// Actions for the existing document
	If ValueIsFilled(Object.Ref) Then
		Items.IsRoomRatePosting.Visible = False;
		Items.Duration.Visible = False;
		Items.DateTo.Visible = False;
		If Not Object.IsAdditional And Object.Posted Then
			ReadOnly = True;
			Items.FormSetDeletionMarkAction.Visible = False;
		EndIf;
		// Set document number and date appearances
		If Not cmCheckUserPermissions("HavePermissionToEditPostedFolioTransactions") Then
			Items.Number.ReadOnly = True;
			Items.Number.Enabled = False;
		EndIf;
		// Set view only mode
		If Object.Posted Then
			Items.PaymentMethod.Visible = False;
			If Not cmCheckUserPermissions("HavePermissionToEditPostedFolioTransactions") Then
				vAccountingDate = tcOnServer.GetForecastStartDate(Object.Hotel);
				If BegOfDay(vAccountingDate) > BegOfDay(Object.Date) Or Object.Author <> SessionParameters.CurrentUser Then
					ReadOnly = True;
					Items.FormSetDeletionMarkAction.Visible = False;
				EndIf;
			EndIf;
			// Check if this charge is closed to edit
			If ValueIsFilled(Object.Hotel) Then
				vHotel = Object.Hotel;
				If vHotel.DoNotEditSettledDocs And 
				  (Object.Sum <> 0 Or Object.Quantity <> 0) And ValueIsFilled(Object.Folio) And Object.Folio.IsClosed Then
					vChargeBalanceIsZero = False;
					vChargeBalancesRow = cmGetChargeCurrentAccountsReceivableBalance(Object.Ref);
					If vChargeBalancesRow <> Undefined Then
						If vChargeBalancesRow.SumBalance = 0 And vChargeBalancesRow.QuantityBalance = 0 Then
							vChargeBalanceIsZero = True;
						EndIf;
					Else
						vChargeBalanceIsZero = True;
					EndIf;
					If vChargeBalanceIsZero Then
						ReadOnly = True;
						Items.FormSetDeletionMarkAction.Visible = False;
					EndIf;
				ElsIf vHotel.DoNotEditClosedDateDocs And ValueIsFilled(vHotel.AccountingDate) Then
					vChargeIsInClosedDay = cmIfChargeIsInClosedDay(Object.Ref);
					If Not vChargeIsInClosedDay And ValueIsFilled(Object.RoomRevenueCharge) Then
						vChargeIsInClosedDay = cmIfChargeIsInClosedDay(Object.RoomRevenueCharge);
					EndIf;
					If vChargeIsInClosedDay Then
						ReadOnly = True;
						Items.FormSetDeletionMarkAction.Visible = False;
					Endif;
				EndIf;
			EndIf;
			// Check bound storno
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	Storno.Ref AS Ref
			|FROM
			|	Document.Storno AS Storno
			|WHERE
			|	Storno.Posted
			|	AND Storno.ParentCharge = &qCharge";
			vQry.SetParameter("qCharge", Object.Ref);
			vStornos = vQry.Execute().Unload();
			If vStornos.Count() > 0 Then
				ReadOnly = True;
				Items.FormSetDeletionMarkAction.Visible = False;
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'This charge is canceled! Charge is read only.'; 
																|de = 'Anrechnung abgebrochen! Die Bearbeitung einer solchen Abrechnung ist verboten.'; 
																|ru = 'Начисление отменено! Редактирование такого начисления запрещено.'"));
			EndIf;     
			If ValueIsFilled(Object.Service) And Object.Service.UseMarking And Not IsBlankString(Object.MarkingCode) Then
				ReadOnly = True;    
				If vStornos.Count() = 0 And AccumulationRegisters.LabeledGoods.LabeledGoodPaid(Object.MarkingCode, Object.Hotel) Then
					Items.FormSetDeletionMarkAction.Visible = False;
					tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'This charge is paid! Charge is read only.'; 
																	|de = 'Anrechnung bezahlt! Die Bearbeitung einer solchen Abrechnung ist verboten.'; 
																	|ru = 'Начисление оплачено! Редактирование такого начисления запрещено.'"));	
				EndIf;
			EndIf;	
		Else
			Items.FormSetDeletionMarkAction.Visible = False;
		EndIf;
	Else
		Items.IsRoomRatePosting.Visible = True;
		Items.FormSetDeletionMarkAction.Visible = False;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToAddManualDiscounts") Then
		Items.DiscountCard.Enabled = False;
		Items.DiscountType.Enabled = False;
		Items.Discount.Enabled = False;
		Items.DiscountServiceGroup.Enabled = False;
		Items.DiscountServiceGroup1.Enabled = False;
		Items.DiscountSum.Enabled = False;
		Items.DiscountSum1.Enabled = False;
		Items.VATDiscountSum.Enabled = False;
		Items.DiscountConfirmationText.Enabled = False;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToInputDiscountCardNumberManually") Then
		Items.DiscountCard.TextEdit = False;
		Items.DiscountCard.ChoiceButton = False;
	Else
		Items.DiscountCard.TextEdit = True;
		Items.DiscountCard.ChoiceButton = True;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToChooseClientTypeManually") Then
		Items.ClientType.Enabled = False;
		Items.ClientTypeConfirmationText.Enabled = False;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToSkipInputOfAccommodationMarketingCode") Then
		Items.MarketingCode.AutoChoiceIncomplete = True;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToSkipInputOfAccommodationSourceOfBusiness") Then
		Items.SourceOfBusiness.AutoChoiceIncomplete = True;
	EndIf;
	
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	EndIf;

	// Revenue statistics
	Items.GroupRoomNightsStatistics.Visible = (ValueIsFilled(Object.Service) And Object.Service.IsRoomRevenue);
	
	// Fill list of payment methods
	FillListOfPaymentMethods();
	
	// Fill list of cash registers allowed for the current user
	FillListOfCashRegisters();
	
	// Correction flag visibility
	If Not Object.IsCorrection Then
		Items.GroupCorrection.Visible = False;
	EndIf;
	
	// Discount type
	IsAmountDiscount = ?(ValueIsFilled(Object.DiscountType), Object.DiscountType.IsAmountDiscount, False);
	
	// Marking code
	vUseMarking = (ValueIsFilled(Object.Service) And Object.Service.UseMarking);
	Items.GroupMarkingCode.Visible = vUseMarking;   
	Items.GroupPrices.ReadOnly = vUseMarking;
	
	// Charged amount
	Amount = Object.Sum - Object.DiscountSum;
	OldQuantity = Object.Quantity;
	If IsRoomRatePosting Then
		Items.GroupRatePostingMode.Visible = True;
	Else
		Items.GroupRatePostingMode.Visible = False;
	EndIf;
	
	// Vaucher
	vUseHotelProducts = GetVauchersFunctionalOption();
	Items.HotelProduct.Visible = vUseHotelProducts;
	
	// Total room rate
	Items.GroupRoomRateRevenue.Visible = False;
	RateAmount = 0;
	PackagesAmount = 0;
	PackagesDiscountAmount = 0;
	If Object.IsInPrice And Object.IsRoomRevenue And Not Object.IsSplit And Not Object.RoomRevenueAmountsOnly Then
		If Object.RateSum <> 0 And Object.IsMergedToRoomRevenue Then
			Items.GroupRoomRateRevenue.Visible = True;
			RateAmount = Object.RateSum - Object.RateDiscountSum;
			PackagesAmount = Object.RateSum - Object.Sum;
			PackagesDiscountAmount = Object.RateDiscountSum - Object.DiscountSum;
		EndIf;
	EndIf;
	
	// Correction
	If Object.IsCorrection And ValueIsFilled(Object.CorrectedCharge) And Object.Quantity = 0 Then
		Items.Price.ReadOnly = True;
		Items.Quantity.ReadOnly = True;
	EndIf;
	
	// VAT sum
	VATSum = cmCalculateVATSum(Object.VATRate, Object.Sum - Object.DiscountSum, Object.Date);
	
	// Planner
	CheckResourceFilled();
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If Object.Service.IsEmpty() Then
		Activate();
		// APDEX
		vKeyOperation = "Catalog.Services.Form.tcChoiceForm.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);
		
		OpenForm("Catalog.Services.ChoiceForm", New Structure("Hotel, ClientType, AccountingDate, MultipleChoice", Object.Hotel, Object.ClientType, Object.Date, False), Items.Service, , , , , FormWindowOpeningMode.LockWholeInterface);
	EndIf;
    CheckResourceFilled();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	If pWriteParameters.WriteMode = DocumentWriteMode.Posting Then
		// Operation total
		vTotalAmount = pCurrentObject.Sum - pCurrentObject.DiscountSum;
		vTotalQuantity = pCurrentObject.Quantity;
		
		If IsRoomRatePosting And ValueIsFilled(Object.RoomRate) And ValueIsFilled(Object.RoomType) And ValueIsFilled(Object.AccommodationTemplate) Then
			vObjectSave = FormAttributeToValue("Object");
			
			// Create charges to the other dates in the period choosen
			vDuration = Duration;
			If vDuration = 0 Then
				vDuration = 1;
			EndIf;
			vCurrentObject = pCurrentObject;
			
			vIsMergedToRoomRevenue = Object.Hotel.RoomRatePackagesServicesAreNotShownInFolios;
			
			vCurDuration = 0;
			While vCurDuration < vDuration Do
				If vCurDuration > 0 Then
					vCurrentObjectDate = vCurrentObject.Date;
					
					vCurrentObject = vCurrentObject.Copy();
					vCurrentObject.ServiceDate = vCurrentObject.ServiceDate + 24 * 3600;
					vCurrentObject.pmFillAuthorAndDate();
					If BegOfDay(vCurrentObjectDate) <> BegOfDay(vCurrentObject.Date) Then
						vCurrentObject.Date = vCurrentObjectDate + 24 * 3600;
						vCurrentObject.SetTime(AutoTimeMode.DontUse);
					EndIf;

					GetRoomRatePrice(vCurrentObject);
					RecalculateRateServices(vCurrentObject);
					If vCurrentObject.Quantity = 0 Then
						vCurrentObject.Quantity = 1;
						OldQuantity = 1;
					EndIf;
					vCurrentObject.Sum = Round(vCurrentObject.Price * vCurrentObject.Quantity, 2);
					SumOnChangeAtServer(vCurrentObject);
					vCurrentObject.Write(DocumentWriteMode.Write);
					
					// Operation total
					vTotalAmount = vTotalAmount + vCurrentObject.Sum - vCurrentObject.DiscountSum;
					vTotalQuantity = vTotalQuantity + vCurrentObject.Quantity;
				EndIf;
				
				// Create charges for all services that has to be charged by room rate
				vExtraSum = 0;
				vExtraVATSum = 0;
				vExtraDiscountSum = 0;
				vExtraVATDiscountSum = 0;
				vExtraCommissionSum = 0;
				vExtraVATCommissionSum = 0;
				
				For Each vRateServicesTableRow In RateServicesTable Do
					If RateServicesTable.IndexOf(vRateServicesTableRow) > 0 Then
						vCurrentObjectDate = vCurrentObject.Date;
						
						vNewObj = vCurrentObject.Copy();
						vNewObj.pmFillAuthorAndDate();
						If BegOfDay(vCurrentObjectDate) <> BegOfDay(vNewObj.Date) Then
							vNewObj.Date = vCurrentObjectDate;
							vNewObj.SetTime(AutoTimeMode.DontUse);
						EndIf;
						FillPropertyValues(vNewObj, vRateServicesTableRow);
						If vNewObj.IsInPrice And vNewObj.IsRoomRevenue And Not vNewObj.IsSplit Then
							vNewObj.RoomRevenueAmountsOnly = True;
						EndIf;
						vNewObj.ServiceDate = vRateServicesTableRow.AccountingDate;
						If vRateServicesTableRow.IsInPrice And ValueIsFilled(vRateServicesTableRow.Service.QuantityCalculationRule) Then
							vAccountingDateMove = cmGetAccountingDateMove(vRateServicesTableRow.Service.QuantityCalculationRule, Object.IsManual, Object.ParentDoc, ?(TypeOf(Object.ParentDoc) = Type("DocumentRef.Accommodation"), True, False));
							If vAccountingDateMove > 0 Then
								vNewObj.ServiceDate = vNewObj.ServiceDate + 24 * 3600;
							EndIf;
						EndIf;
						If vNewObj.IsInPrice Then
							vNewObj.RoomRevenueCharge = vCurrentObject.Ref;
							vNewObj.IsMergedToRoomRevenue = vIsMergedToRoomRevenue;
						Else
							vNewObj.RoomRevenueCharge = Undefined;
							vNewObj.IsMergedToRoomRevenue = False;
						EndIf;
						
						vNewObj.Write(DocumentWriteMode.Posting);
						
						// Extras total
						vExtraSum = vExtraSum + vRateServicesTableRow.Sum;
						vExtraVATSum = vExtraVATSum + vRateServicesTableRow.VATSum;
						vExtraDiscountSum = vExtraDiscountSum + vRateServicesTableRow.DiscountSum;
						vExtraVATDiscountSum = vExtraVATDiscountSum + vRateServicesTableRow.VATDiscountSum;
						vExtraCommissionSum = vExtraCommissionSum + vRateServicesTableRow.CommissionSum;
						vExtraVATCommissionSum = vExtraVATCommissionSum + vRateServicesTableRow.VATCommissionSum;
					EndIf;
				EndDo;
				
				// Update first charge amount
				vCurrentObject.Sum = vCurrentObject.Sum - vExtraSum;
				vCurrentObject.Price = Round(vCurrentObject.Sum / ?(vCurrentObject.Quantity = 0, ?(vCurrentObject.Sum < 0, -1, 1), vCurrentObject.Quantity), 2);
				vCurrentObject.VATSum = cmCalculateVATSum(vCurrentObject.VATRate, vCurrentObject.Sum, vCurrentObject.Date);
				vCurrentObject.DiscountSum = vCurrentObject.DiscountSum - vExtraDiscountSum;
				vCurrentObject.VATDiscountSum = cmCalculateVATSum(vCurrentObject.VATRate, vCurrentObject.DiscountSum, vCurrentObject.Date);
				vCurrentObject.CommissionSum = vCurrentObject.CommissionSum - vExtraCommissionSum;
				vCurrentObject.VATCommissionSum = cmCalculateVATSum(vCurrentObject.VATRate, vCurrentObject.CommissionSum, vCurrentObject.Date);
				vCurrentObject.Write(DocumentWriteMode.Posting);
				
				vCurDuration = vCurDuration + 1;
			EndDo;
			
			ValueToFormAttribute(vObjectSave, "Object");
		Else
			// Create charges to the other dates in the period choosen
			If Items.DateTo.Visible And ValueIsFilled(DateTo) And Duration > 0 Then
				For i = 2 To Duration Do
					vCurrentObjectDate = pCurrentObject.Date;
					
					vNewObj = pCurrentObject.Copy();
					vNewObj.pmFillAuthorAndDate();
					If BegOfDay(vCurrentObjectDate) <> BegOfDay(vNewObj.Date) Then
						vNewObj.Date = vCurrentObjectDate;
						vNewObj.SetTime(AutoTimeMode.DontUse);
					EndIf;
					vNewObj.ServiceDate = pCurrentObject.ServiceDate + (i - 1) * 24 * 3600;
					vNewObj.Write(DocumentWriteMode.Posting);
					
					// Operation total
					vTotalAmount = vTotalAmount + vNewObj.Sum - vNewObj.DiscountSum;
					vTotalQuantity = vTotalQuantity + vNewObj.Quantity;
				EndDo;
			EndIf;
		EndIf;
		
		// Create payment if necessary
		If vTotalAmount <> 0 Then
			If ValueIsFilled(PaymentMethod) And Items.PaymentMethod.Visible And 
			   Not PaymentMethod.IsCloseToTheFolio And Not PaymentMethod.IsCloseToTheRoom And 
			   Not PaymentMethod.PrintCheque Then
				If vTotalAmount > 0 Then
					vObj = Documents.Payment.CreateDocument();
				Else
					vObj = Documents.Return.CreateDocument();
				EndIf;
				vObj.Fill(pCurrentObject.Folio);
				vObj.SumInFolioCurrency = vTotalAmount;
				vObj.PaymentMethod = PaymentMethod;
				vObj.Sum = vObj.SumInFolioCurrency;
				vObj.PaymentCurrency = vObj.FolioCurrency;
				vObj.PaymentCurrencyExchangeRate = vObj.FolioCurrencyExchangeRate;
				vObj.CashRegister = CashRegister;
				If vObj.Hotel.SplitFolioBalanceByPaymentSections Then
					vObj.PaymentSections.Clear();
					vPSRow = vObj.PaymentSections.Add();
					vPSRow.PaymentSection = Object.Service.PaymentSection;
					vPSRow.Sum = vObj.Sum;
					vPSRow.SumInFolioCurrency = vObj.SumInFolioCurrency;
					vPSRow.VATRate = ?(ValueIsFilled(vPSRow.PaymentSection) And ValueIsFilled(vPSRow.PaymentSection.VATRate), vPSRow.PaymentSection.VATRate, vObj.VATRate);
					vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, vObj.Date);
					vPSRow.VATSumInFolioCurrency = vPSRow.VATSum;
				ElsIf vObj.Hotel.SplitFolioBalanceByServicesAndPrices Then
					vObj.PaymentSections.Clear();
					vPSRow = vObj.PaymentSections.Add();
					vPSRow.PaymentSection = Object.Service.PaymentSection;
					vPSRow.ChequeService = Object.Service;
					vPSRow.ChequeServiceQuantity = ?(vTotalQuantity <> 0, vTotalQuantity, 1);
					vPSRow.Sum = vObj.Sum;
					vPSRow.SumInFolioCurrency = vObj.SumInFolioCurrency;
					vPSRow.ChequeServicePrice = ?(vTotalQuantity <> 0, Round(vPSRow.Sum/vTotalQuantity, 2), vPSRow.Sum);
					vPSRow.VATRate = ?(ValueIsFilled(vPSRow.PaymentSection) And ValueIsFilled(vPSRow.PaymentSection.VATRate), vPSRow.PaymentSection.VATRate, vObj.VATRate);
					vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, vObj.Date);
					vPSRow.VATSumInFolioCurrency = vPSRow.VATSum;
				EndIf;
				vObj.Write(DocumentWriteMode.Posting);
			EndIf;
		EndIf;
	EndIf;
EndProcedure //  AfterWriteAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	Notify("Document.Charge.Write", Object.Ref, ThisObject);
	// Open payment form
	If ValueIsFilled(PaymentMethod) And Items.PaymentMethod.Visible Then
		vPaymentMethodArr = tcOnServer.cmGetAtributeAsArray(PaymentMethod);
		If Not vPaymentMethodArr.IsCloseToTheFolio And Not vPaymentMethodArr.IsCloseToTheRoom And vPaymentMethodArr.PrintCheque Then
			vTotalAmount = Object.Sum - Object.DiscountSum;
			vTotalQuantity = Object.Quantity;
			// Create charges to the other dates in the period choosen
			If Items.DateTo.Visible And ValueIsFilled(DateTo) And Duration > 0 Then
				For i = 2 To Duration Do
					// Operation total
					vTotalAmount = vTotalAmount + Object.Sum - Object.DiscountSum;
					vTotalQuantity = vTotalQuantity + Object.Quantity;
				EndDo;
			EndIf;
			// Total is not zero
			If vTotalAmount <> 0 Then
				vParams = New Structure("Basis, Service, Amount, Quantity, PaymentMethod, CashRegister", Object.Folio, Object.Service, vTotalAmount, vTotalQuantity, PaymentMethod, CashRegister);
				If vTotalAmount > 0 Then
					Notify("Document.Payment.OpenForm", vParams, Object.Ref);
				Else
					Notify("Document.Return.OpenForm", vParams, Object.Ref);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure //  AfterWrite

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoiceProcessing(pSelectedValue, pChoiceSource)
	If IsRoomRatePosting And ValueIsFilled(pSelectedValue) Then
		If TypeOf(pSelectedValue) = Type("CatalogRef.RoomRates") Then
			Object.RoomRate = pSelectedValue;
			
			If Not ValueIsFilled(Object.RoomType) Then
				OpenForm("Catalog.RoomTypes.Form.tcChoiceFormDefault", , ThisObject, Object.Folio);
			ElsIf Not ValueIsFilled(Object.AccommodationTemplate) Then
				OpenForm("Catalog.AccommodationTemplates.Form.tcChoiceForm", , ThisObject, Object.Folio);
			Else
				// Get price for room rate and date choosen
				GetRoomRatePrice();
				QuantityOnChange(Items.Quantity);
			EndIf;
		ElsIf TypeOf(pSelectedValue) = Type("CatalogRef.RoomTypes") Then
			Object.RoomType = pSelectedValue;
			
			If Not ValueIsFilled(Object.RoomRate) Then
				OpenForm("Catalog.RoomRates.Form.tcChoiceForm", , ThisObject, Object.Folio);
			ElsIf Not ValueIsFilled(Object.AccommodationTemplate) Then
				OpenForm("Catalog.AccommodationTemplates.Form.tcChoiceForm", , ThisObject, Object.Folio);
			Else
				// Get price for room rate and date choosen
				GetRoomRatePrice();
				QuantityOnChange(Items.Quantity);
			EndIf;
		ElsIf TypeOf(pSelectedValue) = Type("CatalogRef.AccommodationTemplates") Then
			Object.AccommodationTemplate = pSelectedValue;
			
			If Not ValueIsFilled(Object.RoomRate) Then
				OpenForm("Catalog.RoomRates.Form.tcChoiceForm", , ThisObject, Object.Folio);
			ElsIf Not ValueIsFilled(Object.RoomType) Then
				OpenForm("Catalog.RoomTypes.Form.tcChoiceFormDefault", , ThisObject, Object.Folio);
			Else
				// Get price for room rate and date choosen
				GetRoomRatePrice();
				QuantityOnChange(Items.Quantity);
			EndIf;
		EndIf;
	EndIf;
EndProcedure //  ChoiceProcessing

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCloseAtServer()
	If ValueIsFilled(CurrentUser) Then
		SessionParameters.CurrentUser = CurrentUser;
	EndIf;
EndProcedure //  OnCloseAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnClose(pExit)
	If Not pExit Then
		OnCloseAtServer();
	EndIf;
EndProcedure //  OnClose

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "SessionParameters.CurrentUser.Change" Then
		EmployeePINCodeChecked = True;
		If Not ValueIsFilled(Object.Ref) Then
			Object.Author = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
		EndIf;
		If pParameter.ModeAfterCheck = "BeforeWrite" Then
			If Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
				Close();
			EndIf;
		EndIf;
	ElsIf pEventName = "Document.Charge.Write" And pParameter = Object.Ref Then
		ThisObject.Read();
		// Total room rate
		RateAmount = 0;
		PackagesAmount = 0;
		PackagesDiscountAmount = 0;
		If Object.IsInPrice And Object.IsRoomRevenue And Not Object.IsSplit And Not Object.RoomRevenueAmountsOnly Then
			If Object.RateSum <> 0 And Object.IsMergedToRoomRevenue Then
				RateAmount = Object.RateSum - Object.RateDiscountSum;
				PackagesAmount = Object.RateSum - Object.Sum;
				PackagesDiscountAmount = Object.RateDiscountSum - Object.DiscountSum;
			EndIf;
		EndIf;
	EndIf;
EndProcedure //  NotificationProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	ClearMessages();
	
	vMessage = ""; 
	If pWriteParameters.WriteMode = DocumentWriteMode.Posting Then
		// APDEX
		vKeyOperation = "Document.Charge.Form.tcDocumentForm.Posting";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

		// Check document attributes
		If Not CheckDocumentAttributesAtServer(vMessage) Then
			pCancel = True;
			tcOnServer.cmWriteLogEventAtServer(NStr("en='Document.Posting';ru='Документ.Проведение';de='Document.Posting'"), , , , tcOnServer.cmNStrAtServer(vMessage));
			Return;
		EndIf;
		vMessage = "";
		// Check user PIN if necessary
		If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
			OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "BeforeWrite"), ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
			pCancel = True;
			Return;
		EndIf;
		EmployeePINCodeChecked = False;
		// Do some extra checks
		If Not ComplimentaryFolioIsChecked Then
			If tcOnServer.cmGetAttributeByRef(Object.Folio, "IsComplimentary") Then
				If (Object.Sum - Object.DiscountSum) > 0 Then
					pCancel = True;
					ShowQueryBox(New NotifyDescription("ComplimentaryFolioCheckAfterAnswer", ThisObject, pWriteParameters), 
					             NStr("en='You are going to charge fully complimentary folio with amount that is not zero! Do you want to continue?'; 
								      |ru='Выполнить не нулевое начисление на бесплатный лицевой счет! Продолжить операцию?'; 
									  |de='Sie sind dabei, keine null-Gebühr auf ein kostenloses Konto durchzuführen! Operation fortsetzen?'"), 
								 QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure //  BeforeWrite

// -----------------------------------------------------------------------------
&AtClient
Procedure ExternalEvent(pSource, pEvent, pData)
	If Not IsInputAvailable() Then
		Return;
	EndIf;
	
	vEventData = tcConnectionHardwareAtClient.cmGetExternalEventResultInputDevice(pSource, pEvent, pData);
	If IsBlankString(vEventData.DeviceData) Then
		Return;
	EndIf;
	
	If vEventData.DeviceType = "BarCodeScaner" Then
		ChargeServiceByBarcode(vEventData.DeviceData);
	EndIf;
EndProcedure // ExternalEvent

// -----------------------------------------------------------------------------
&AtServer
Procedure OnWriteAtServer(pCancel, pCurrentObject, pWriteParameters)	
	If ValueIsFilled(pCurrentObject.Resource) And ValueIsFilled(pCurrentObject.TimeFrom) And ValueIsFilled(pCurrentObject.TimeTo) Then
		// Check folio guest group
		If ValueIsFilled(pCurrentObject.Hotel) And ValueIsFilled(pCurrentObject.Folio) And Not ValueIsFilled(pCurrentObject.Folio.GuestGroup) Then
			vGuestGroupObj = Catalogs.GuestGroups.CreateItem();
			vGuestGroupObj.Owner = pCurrentObject.Hotel;
			vGuestGroupFolder = pCurrentObject.Hotel.GetObject().pmGetGuestGroupFolder();
			If ValueIsFilled(vGuestGroupFolder) Then
				vGuestGroupObj.Parent = vGuestGroupFolder;
				vGuestGroupObj.SetNewCode();
			EndIf;
			vGuestGroupObj.OneCustomerPerGuestGroup = pCurrentObject.Hotel.OneCustomerPerGuestGroup;
			vGuestGroupObj.Write();
			// Fill folio attribute
			vFolioObj = pCurrentObject.Folio.GetObject();
			vFolioObj.GuestGroup = vGuestGroupObj.Ref;
			vFolioObj.Write(DocumentWriteMode.Write);
		EndIf;
		// Create resource reservation for the given period
        vDateFirst = Date(Year(Object.ServiceDate), Month(Object.ServiceDate), Day(Object.ServiceDate),
				Hour(Object.TimeFrom), Minute(Object.TimeFrom), Second(Object.TimeFrom));
		vDateSecond = Date(Year(Object.ServiceDate), Month(Object.ServiceDate), Day(Object.ServiceDate),
				Hour(Object.TimeTo), Minute(Object.TimeTo), Second(Object.TimeTo));
				
		pCurrentObject.pmPostResourceReservation(vDateFirst,vDateSecond);				
	EndIf;		
EndProcedure // OnWriteAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure PriceOnChange(pItem)
	CalculateSum();
	// Check available quantity
	CheckAvailableQuantity();
EndProcedure //  PriceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SumOnChange(pItem)
	SumOnChangeAtServer();
	// Check available quantity
	vAvailableQuantity = 0;
	vUsedQuantity = 0;
	vRestQuantity = 0;
	If CheckServiceUsedQuantity(vAvailableQuantity, vUsedQuantity, vRestQuantity) Then
		ShowMessageBox(, TrimAll(Object.Service) + NStr("en=' - There is: '; ru=' - Есть: '; de=' - Es gibt: '") + vAvailableQuantity + NStr("en='; Already used: '; ru='; Уже использовано: '; de='; Gebraucht: '") + vUsedQuantity + NStr("en='; Remainder: '; ru='; Остаток: '; de='; Rest: '") + vRestQuantity);
	EndIf;
EndProcedure //  SumOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServiceOnChange(pItem)
	ServiceOnChangeAtServer();

	If Not ValueIsFilled(Object.Ref) And Object.IsInPrice And Object.IsRoomRevenue And Not Object.RoomRevenueAmountsOnly Then
		Object.AccommodationTemplate = Undefined;
		vRateChargeParameters = FillDefaultRateChargeParameters();
		ShowQueryBox(New NotifyDescription("AfterRateChargeModeSelection", ThisObject, vRateChargeParameters), 
		             NStr("en='Post amount for the room rate?'; 
		                  |ru='Выполнить начисление стоимости проживания по тарифу?'; 
		                  |de='Post Zimmerpreisbetrag für das Tariff?'"), 
		             QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
	EndIf;
	
	// Planner
	CheckResourceFilled();
EndProcedure //  ServiceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure IsRoomRatePostingOnChange(pItem)
	If IsRoomRatePosting Then
		vRateChargeParameters = FillDefaultRateChargeParameters();
		
		Object.RoomRate = vRateChargeParameters.RoomRate;
		Object.RoomType = vRateChargeParameters.RoomType;
		Object.AccommodationTemplate = vRateChargeParameters.AccommodationTemplate;
		
		If Not ValueIsFilled(Object.RoomRate) Then
			OpenForm("Catalog.RoomRates.Form.tcChoiceForm", , ThisObject, Object.Folio);
		ElsIf Not ValueIsFilled(Object.RoomType) Then
			OpenForm("Catalog.RoomTypes.Form.tcChoiceFormDefault", , ThisObject, Object.Folio);
		ElsIf Not ValueIsFilled(Object.AccommodationTemplate) Then
			OpenForm("Catalog.AccommodationTemplates.Form.tcChoiceForm", , ThisObject, Object.Folio);
		Else
			// Get price for room rate and date choosen
			GetRoomRatePrice();
			QuantityOnChange(Items.Quantity);
		EndIf;
	EndIf;
	
	SetRateChargeModeAppearance();
EndProcedure //  IsRoomRatePostingOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServiceStartChoice(pItem, pChoiceData, pStandardProcessing)
	// APDEX
	vKeyOperation = "Catalog.Services.Form.tcChoiceForm.OpenForm";
	APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

	pStandardProcessing = False;
	OpenForm("Catalog.Services.ChoiceForm", New Structure("Hotel, ClientType, AccountingDate, MultipleChoice", Object.Hotel, Object.ClientType, EndOfDay(?(ValueIsFilled(Object.ServiceDate), Object.ServiceDate, Object.Date)), False), pItem, , , , , FormWindowOpeningMode.LockWholeInterface);
	
	// Planner
	CheckResourceFilled();
EndProcedure //  ServiceStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure DateOnChange(pItem)
	vMessage = "";
	DateOnChangeAtServer(vMessage);
	If Not IsBlankString(vMessage) Then
		ShowMessageBox(, vMessage);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ServiceDateOnChange(pItem)
	If ValueIsFilled(Object.ParentDoc) Then
		If Not CheckChargingPeriodAtServer() Then
			Return;
		EndIf;
	EndIf;
	
	vMessage = "";
	ServiceDateOnChangeAtServer(vMessage);
	If Not IsBlankString(vMessage) Then
		ShowMessageBox(, vMessage);
	EndIf;
	
	// Get price for room rate and date choosen
	If IsRoomRatePosting And ValueIsFilled(Object.RoomRate) And ValueIsFilled(Object.RoomType) And ValueIsFilled(Object.AccommodationTemplate) Then
		GetRoomRatePrice();
		QuantityOnChange(Items.Quantity);
	EndIf;
	
	// Planner
	CheckResourceFilled();
EndProcedure //  ServiceDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DurationOnChange(Item)
	RecalculateEndDateAtServer();
	If ValueIsFilled(DateTo) And ValueIsFilled(Object.ParentDoc) Then
		If Not CheckChargingPeriodAtServer() Then
			Return;
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DateToOnChange(Item)
	RecalculateDurationAtServer();
	If ValueIsFilled(DateTo) And ValueIsFilled(Object.ParentDoc) Then
		If Not CheckChargingPeriodAtServer() Then
			Return;
		EndIf;
	EndIf;
EndProcedure //  DateToOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CashRegisterClearing(pItem, pStandardProcessing)
	CashRegisterClearingAtServer(pStandardProcessing);
EndProcedure //  CashRegisterClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure Discount1OnChange(pItem)
	CalculateDiscountSumAtServer();
EndProcedure //  Discount1OnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountServiceGroupOnChange(pItem)
	CalculateDiscountSumAtServer();
EndProcedure //  DiscountServiceGroupOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountTypeOnChange(pItem)
	DiscountTypeOnChangeAtServer();
EndProcedure //  DiscountTypeOnChange

// -----------------------------------------------------------------------------
&AtServer
Function DiscountCardOnChangeAtServer()
	vMessage = "";
	If ValueIsFilled(Object.DiscountCard) Then
		If BegOfDay(Object.Date) < Object.DiscountCard.ValidFrom Or
			BegOfDay(Object.Date) >= ?(ValueIsFilled(Object.DiscountCard.ValidTo), Object.DiscountCard.ValidTo, EndOfDay(Object.Date)) Then
			vMessage = "ru='Дисконтная карта не действует на дату оказания услуги!';en='Discount card is not valid on charging date!';de='Discount card is not valid on charging date!'";
			Object.DiscountCard = Catalogs.DiscountCards.EmptyRef();
		Else
			If ValueIsFilled(Object.Folio) And ValueIsFilled(Object.Folio.Client) And ValueIsFilled(Object.DiscountCard.Client) And Object.Folio.Client <> Object.DiscountCard.Client Then
				If Not cmCheckUserPermissions("HavePermissionToUseClientDiscountCardWithAnyOtherClientHavingIt") Then
					vMessage = NStr("en='This discount card was issued for another client! You do not have rights to use this discount card.';
					                |ru='Дисконтная карта выдана другому клиенту. Нет прав на использование этой дисконтной карты.';
									|de='Die Rabatt-Karte von einem anderen Kunde ausgegeben. Sie sind nicht berechtigt, diese Rabatt-Karte zu verwenden.'");
					Object.DiscountCard = Catalogs.DiscountCards.EmptyRef();
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	// Set discounts
	vObj = FormAttributeToValue("Object");
	vObj.pmSetDiscounts();
	ValueToFormAttribute(vObj, "Object");
	
	// Recalculate amounts
	CalculateDiscountSumAtServer();
	
	// Discount type
	IsAmountDiscount = ?(ValueIsFilled(Object.DiscountType), Object.DiscountType.IsAmountDiscount, False);
EndFunction //  DiscountCardOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountCardOnChange(pItem)
	vMessage = DiscountCardOnChangeAtServer();
	If Not IsBlankString(vMessage) Then
		ShowMessageBox(, vMessage);
	EndIf;
EndProcedure //  DiscountCardOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountOnChange(pItem)
	// Recalculate amounts
	CalculateDiscountSumAtServer();
EndProcedure //  DiscountOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AmountClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure //  AmountClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure AmountStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure //  AmountStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure AmountTuning(pItem, pDirection, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure //  AmountTuning

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientTypeOnChange(pItem)
	ServiceOnChange(Items.Service);
EndProcedure //  ClientTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure VATRateOnChange(pItem)
	SumOnChangeAtServer();
EndProcedure //  VATRateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure MarketingCodeOnChange(pItem)
	MarketingCodeOnChangeAtServer();
EndProcedure //  MarketingCodeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRate1OnChange(pItem)
	// Get price for room rate and date choosen
	If IsRoomRatePosting And ValueIsFilled(Object.RoomRate) And ValueIsFilled(Object.RoomType) And ValueIsFilled(Object.AccommodationTemplate) Then
		GetRoomRatePrice();
		QuantityOnChange(Items.Quantity);
	EndIf;
EndProcedure //  RoomRate1OnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomType1OnChange(pItem)
	// Get price for room rate and date choosen
	If IsRoomRatePosting And ValueIsFilled(Object.RoomRate) And ValueIsFilled(Object.RoomType) And ValueIsFilled(Object.AccommodationTemplate) Then
		GetRoomRatePrice();
		QuantityOnChange(Items.Quantity);
	EndIf;
EndProcedure //  RoomType1OnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AccommodationTemplate1OnChange(pItem)
	// Get price for room rate and date choosen
	If IsRoomRatePosting And ValueIsFilled(Object.RoomRate) And ValueIsFilled(Object.RoomType) And ValueIsFilled(Object.AccommodationTemplate) Then
		GetRoomRatePrice();
		QuantityOnChange(Items.Quantity);
	EndIf;
EndProcedure //  AccommodationTemplate1OnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure Folio1OnChange(pItem)
	If ValueIsFilled(Object.Folio) Then
		FolioOnChangeAtServer();
	EndIf;
EndProcedure //  Folio1OnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PackagesAmountClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // PackagesAmountClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure PackagesDiscountAmountClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // PackagesDiscountAmountClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure RateAmountClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // RateAmountClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure PackagesAmountStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // PackagesAmountStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure RateAmountStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // RateAmountStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure RateSumOnChange(pItem)
	RateAmount = Object.RateSum - Object.RateDiscountSum;
	PackagesAmount = Object.RateSum - Object.Sum;
	PackagesDiscountAmount = Object.RateDiscountSum - Object.DiscountSum;
EndProcedure // RateSumOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RateDiscountSumOnChange(pItem)
	RateAmount = Object.RateSum - Object.RateDiscountSum;
	PackagesAmount = Object.RateSum - Object.Sum;
	PackagesDiscountAmount = Object.RateDiscountSum - Object.DiscountSum;
EndProcedure // RateDiscountSumOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure TimeFrom1StartChoice(pItem, pChoiceData, pChoiceByAdding, pStandardProcessing)
	pStandardProcessing = False;
	vList = New ValueList();
	For Ind=0 to 23 Do
		vList.Add(Ind,Format(Date(2,1,1,Ind,0,0), "DF='HH:mm'"));
	EndDo;
	vDayTime = ChooseFromList(vList, pChoiceData);
	If vDayTime <> Undefined Then
		Object.TimeFrom = Date(2,1,1,vDayTime.Value,0,0);
		TimeFrom1OnChange(pChoiceData);
	EndIf;
EndProcedure //TimeFrom1StartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure TimeFrom1OnChange(pItem)
	CheckResourceFilled();
EndProcedure //TimeFrom1OnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure TimeTo1StartChoice(pItem, pChoiceData, pChoiceByAdding, pStandardProcessing)
	pStandardProcessing = False;
	vList = New ValueList();
	For Ind=0 to 23 Do
		vList.Add(Ind,Format(Date(2,1,1,Ind,0,0), "DF='HH:mm'"));
	EndDo;
	vDayTime = ChooseFromList(vList, pChoiceData);
	If vDayTime <> Undefined Then
		Object.TimeTo = Date(2,1,1,vDayTime.Value,0,0);
		TimeTo1OnChange(pChoiceData);
	EndIf;
EndProcedure //TimeTo1StartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure TimeTo1OnChange(pItem)
	CheckResourceFilled();
EndProcedure //TimeTo1OnChange 

// -----------------------------------------------------------------------------
&AtClient
Procedure ResourceCalendarOnActivate(pItem)
	If CheckDocumentIsNew() Then
		
		vParams = New Structure("DateTimeFrom, DateTimeTo, Hotel, Resource, GuestGroup");
		vParams.DateTimeFrom 	= Date(Year(Object.ServiceDate), Month(Object.ServiceDate), Day(Object.ServiceDate), Hour(Object.TimeFrom), Minute(Object.TimeFrom), Second(Object.TimeFrom));
		vParams.DateTimeTo 		= Date(Year(Object.ServiceDate), Month(Object.ServiceDate), Day(Object.ServiceDate), Hour(Object.TimeTo), Minute(Object.TimeTo), Second(Object.TimeTo));
		vParams.Hotel 			= Object.Hotel;
		vParams.Resource 		= Object.Resource;
		
		OpenForm("Document.ResourceReservation.ObjectForm", vParams, ThisObject);		
		
	EndIf;
EndProcedure // ResourceCalendarOnActivate

// -----------------------------------------------------------------------------
&AtClient
Procedure ResourceQuantityOnChange(pItem)
	CheckResourceFilled();
EndProcedure //ResourceQuantityOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure FillRoomNightsStatistics(pCommand)
	FillRoomNightsStatisticsAtServer();
EndProcedure //  FillRoomNightsStatistics

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
	Notify("Document.Charge.Write", Object.Ref, ThisObject);
	Close();
EndProcedure //  SetDeletionMarkAction

// -----------------------------------------------------------------------------
&AtClient
Procedure ResourceStartDateOnChange(pItem)
	Object.ServiceDate = ResourceStartDate;
	If ValueIsFilled(Object.ParentDoc) Then
		If Not CheckChargingPeriodAtServer() Then
			Return;
		EndIf;
	EndIf;
	vMessage = "";
	ServiceDateOnChangeAtServer(vMessage);
	If Not IsBlankString(vMessage) Then
		ShowMessageBox(, vMessage);
	EndIf;
	// Get price for room rate and date choosen
	If IsRoomRatePosting And ValueIsFilled(Object.RoomRate) And ValueIsFilled(Object.RoomType) And ValueIsFilled(Object.AccommodationTemplate) Then
		GetRoomRatePrice();
		QuantityOnChange(Items.Quantity);
	EndIf;
	CheckResourceFilled();

EndProcedure // ResourceStartDateOnChange

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Function GetVauchersFunctionalOption()
	vUseVauchers = False;
	vHotel = Object.Hotel;
	If Not ValueIsFilled(vHotel) Then
		vHotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(vHotel) Then
		vUseVauchers = GetFunctionalOption("Vauchers", New Structure("Hotel", vHotel));
	EndIf;
	Return vUseVauchers;
EndFunction //  CheckVauchersFunctionalOption

// -----------------------------------------------------------------------------
&AtServer
Procedure FillListOfPaymentMethods()
	vFolioCreditPM = Undefined;
	vFolioCreditPMIsFound = False;
	vPMList = cmGetListOfPaymentMethodsAllowed(SessionParameters.CurrentUser, , CashRegister);
	For Each vPMListItem In vPMList Do
		vPM = vPMListItem.Value;
		If vPM.IsCloseToTheFolio Then
			vFolioCreditPM = vPM;
			vFolioCreditPMIsFound = True;
			Break;
		EndIf;
	EndDo;
	If vFolioCreditPMIsFound Then
		vCLPMItem = vPMList.FindByValue(Catalogs.PaymentMethods.Settlement);
		If vCLPMItem <> Undefined Then
			If ValueIsFilled(Object.Folio) And (Not ValueIsFilled(Object.Folio.Customer) Or ValueIsFilled(Object.Folio.Customer) And Object.Folio.Customer.IsIndividual) Then
				vPMList.Delete(vCLPMItem);
			EndIf;
		EndIf;
		Items.PaymentMethod.ChoiceList.LoadValues(vPMList.UnloadValues());
		PaymentMethod = vPM;
	Else
		Items.PaymentMethod.Visible = False;
	EndIf;
EndProcedure //  FillListOfPaymentMethods

// -----------------------------------------------------------------------------
&AtServer
Procedure FillListOfCashRegisters()
	vCashRegistersList = New ValueList();
	If cmCheckUserPermissions("HavePermissionToViewAllCashRegisters") Then
		vCashRegistersList = cmGetListOfAllCashRegisters(Object.Company);
	Else
		vCashRegistersList = cmGetListOfCashRegistersAllowed(Object.Company, SessionParameters.CurrentWorkstation);
	EndIf;
	// Attach list of cash registers to the form item
	Items.CashRegister.ChoiceList.LoadValues(vCashRegistersList.UnloadValues());
	If vCashRegistersList.Count() > 0 Then
		CashRegister = vCashRegistersList.Get(0).Value;
	Else
		CashRegister = Catalogs.CashRegisters.EmptyRef();
	EndIf;
	Items.CashRegister.Visible = Items.PaymentMethod.Visible;
EndProcedure //  FillListOfCashRegisters

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckAvailableQuantity()
	vAvailableQuantity = 0;
	vUsedQuantity = 0;
	vRestQuantity = 0;
	If CheckServiceUsedQuantity(vAvailableQuantity, vUsedQuantity, vRestQuantity) Then
		vMsg = NStr("en = '%1 - There is: %2 Already Used: %3 Remaining: %4'; de = '%1 - Haben: %2 Bereits verwendet: %3 Verbleibend: %4'; ru = '%1 - Есть: %2 Уже использовано: %3 Остаток: %4'");
		ShowMessageBox(, StrTemplate(vMsg, TrimAll(Object.Service), vAvailableQuantity, vUsedQuantity, vRestQuantity));
	EndIf;
EndProcedure //  CheckAvailableQuantity

// -----------------------------------------------------------------------------
&AtServer
Function CheckServiceUsedQuantity(rAvailableQuantity, rUsedQuantity, rRestQuantity)
	rAvailableQuantity = 0;
	rUsedQuantity = 0;
	rRestQuantity = 0;
	// Check available quantity
	If Object.IsAdditional And ValueIsFilled(Object.Date) And ValueIsFilled(Object.Service) And Object.Service.AvailableQuantity <> 0 Then
		rAvailableQuantity = Object.Service.AvailableQuantity;
		rUsedQuantity = cmGetServiceUsedQuantity(Object.Service, BegOfDay(Object.Date), '00010101', '00010101', Object.Ref);
		rRestQuantity = rAvailableQuantity - rUsedQuantity;
		If rRestQuantity < Object.Quantity Then
			Return True;
		EndIf;
	EndIf;
	Return False;
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Procedure RecalculateRateServices(pObject = Undefined)
	vObject = pObject;
	If pObject = Undefined Then
		vObject = Object;
	EndIf;
	If OldQuantity = 0 Then
		OldQuantity = 1;
	EndIf;
	
	If vObject.Quantity <> 0 Then
		For Each vRateServicesTableRow In RateServicesTable Do
			vRateServicesTableRow.Quantity = vRateServicesTableRow.Quantity / OldQuantity * vObject.Quantity;
			vRateServicesTableRow.Sum = Round(vRateServicesTableRow.Sum / OldQuantity * vObject.Quantity, 2);
			vRateServicesTableRow.VATSum = Round(vRateServicesTableRow.VATSum / OldQuantity * vObject.Quantity, 2);
			vRateServicesTableRow.DiscountSum = Round(vRateServicesTableRow.DiscountSum / OldQuantity * vObject.Quantity, 2);
			vRateServicesTableRow.VATDiscountSum = Round(vRateServicesTableRow.VATDiscountSum / OldQuantity * vObject.Quantity, 2);
			vRateServicesTableRow.CommissionSum = Round(vRateServicesTableRow.CommissionSum / OldQuantity * vObject.Quantity, 2);
			vRateServicesTableRow.VATCommissionSum = Round(vRateServicesTableRow.VATCommissionSum / OldQuantity * vObject.Quantity, 2);
			vRateServicesTableRow.RoomsRented = vRateServicesTableRow.RoomsRented / OldQuantity * vObject.Quantity;
			vRateServicesTableRow.BedsRented = vRateServicesTableRow.BedsRented / OldQuantity * vObject.Quantity;
			vRateServicesTableRow.AdditionalBedsRented = vRateServicesTableRow.AdditionalBedsRented / OldQuantity * vObject.Quantity;
			vRateServicesTableRow.GuestDays = vRateServicesTableRow.GuestDays / OldQuantity * vObject.Quantity;
			vRateServicesTableRow.GuestsCheckedIn = vRateServicesTableRow.GuestsCheckedIn / OldQuantity * vObject.Quantity;
			
			If RateServicesTable.IndexOf(vRateServicesTableRow) = 0 Then
				If vObject.GuestDays <> 0 Then
					vObject.RoomsRented = vRateServicesTableRow.RoomsRented;
					vObject.BedsRented = vRateServicesTableRow.BedsRented;
					vObject.AdditionalBedsRented = vRateServicesTableRow.AdditionalBedsRented;
					vObject.GuestDays = vRateServicesTableRow.GuestDays;
					vObject.GuestsCheckedIn = vRateServicesTableRow.GuestsCheckedIn;
				Else
					vObject.RoomsRented = 0;
					vObject.BedsRented = 0;
					vObject.AdditionalBedsRented = 0;
					vObject.GuestDays = 0;
					vObject.GuestsCheckedIn = 0;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // RecalculateRateServices

// -----------------------------------------------------------------------------
&AtServer
Procedure QuantityOnChangeAtServer()
	RecalculateRateServices();
	CalculateSum();
	OldQuantity = Object.Quantity;
EndProcedure //  QuantityOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure QuantityOnChange(pItem)
	QuantityOnChangeAtServer();
	// Check available quantity
	CheckAvailableQuantity();
EndProcedure //  QuantityOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure SumOnChangeAtServer(pObject = Undefined)
	vObject = pObject;
	If pObject = Undefined Then
		vObject = Object;
	EndIf;
	If vObject.Price = 0 And vObject.Sum <> 0 And vObject.Quantity = 0 Then
		If Not (vObject.IsCorrection And ValueIsFilled(vObject.CorrectedCharge)) Then
			vObject.Quantity = 1;
			OldQuantity = 1;
		EndIf;
	EndIf;
	If Not (vObject.IsCorrection And ValueIsFilled(vObject.CorrectedCharge) And vObject.Quantity = 0) Then
		If ValueIsFilled(vObject.Service) And 
		  (vObject.Service.RecalculatePriceWhenSumChanged Or IsRoomRatePosting Or vObject.Price = 0 And vObject.Sum <> 0 And vObject.Quantity <> 0) Then
			If vObject.Quantity <> 0 Then
				vObject.Price = Round(vObject.Sum / vObject.Quantity, 2);
			Else
				vObject.Quantity = 1;
				vObject.Price = vObject.Sum;
				OldQuantity = 1;
			EndIf;
		Else
			If vObject.Price <> 0 Then
				vObject.Quantity = Round(vObject.Sum / vObject.Price, 7);
			Else
				If vObject.Quantity = 0 Then
					vObject.Quantity = 1;
					OldQuantity = 1;
				EndIf;
				vObject.Price = Round(vObject.Sum / vObject.Quantity, 2);
			EndIf;
		EndIf;
	Else
		If vObject.Price <> 0 Then
			vObject.Price = 0;
		EndIf;
	EndIf;
	CalculateDiscountSumAtServer(pObject);
	CalculateCommissionSumAtServer(pObject);
	CalculateVATSumAtServer(pObject);
	RateAmount = Object.RateSum - Object.RateDiscountSum;
	PackagesAmount = Object.RateSum - Object.Sum;
	PackagesDiscountAmount = Object.RateDiscountSum - Object.DiscountSum;
EndProcedure // SumOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Function FillDefaultRateChargeParameters()
	vDefaultRoomRate = Object.RoomRate;
	vDefaultRoomType = Object.RoomType;
	If Not ValueIsFilled(vDefaultRoomRate) And ValueIsFilled(Object.ParentDoc) And 
	   (TypeOf(Object.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(Object.ParentDoc) = Type("DocumentRef.Reservation")) Then
		vDefaultRoomRate = tcOnServer.cmGetAttributeByRef(Object.ParentDoc, "RoomRate");
		vDefaultRoomType = tcOnServer.cmGetAttributeByRef(Object.ParentDoc, "RoomType");
		vRoomTypeUpgrade = tcOnServer.cmGetAttributeByRef(Object.ParentDoc, "RoomTypeUpgrade");
		If ValueIsFilled(vRoomTypeUpgrade) Then
			vDefaultRoomType = vRoomTypeUpgrade;
		EndIf;
		vDefaultAccommodationTemplate = tcOnServer.cmGetAttributeByRef(Object.ParentDoc, "AccommodationTemplate");
	EndIf;
	Return New Structure("RoomRate, RoomType, AccommodationTemplate", vDefaultRoomRate, vDefaultRoomType, vDefaultAccommodationTemplate);
EndFunction //  FillDefaultRateChargeParameters

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterRateChargeModeSelection(pAnswer, pExtraParams) Export
	IsRoomRatePosting = False;
	If pAnswer = DialogReturnCode.Yes Then
		IsRoomRatePosting = True;
		
		Object.RoomRate = pExtraParams.RoomRate;
		Object.RoomType = pExtraParams.RoomType;
		Object.AccommodationTemplate = pExtraParams.AccommodationTemplate;
	EndIf;		
	
	SetRateChargeModeAppearance();
	
	// Check rate charge parameters
	If IsRoomRatePosting Then
		If Not ValueIsFilled(Object.RoomRate) Then
			OpenForm("Catalog.RoomRates.Form.tcChoiceForm", , ThisObject, Object.Folio);
		ElsIf Not ValueIsFilled(Object.RoomType) Then
			OpenForm("Catalog.RoomTypes.Form.tcChoiceFormDefault", , ThisObject, Object.Folio);
		ElsIf Not ValueIsFilled(Object.AccommodationTemplate) And ValueIsFilled(Object.ParentDoc) And 
		      (TypeOf(Object.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(Object.ParentDoc) = Type("DocumentRef.Reservation")) And 
			  Not tcOnServer.cmGetAttributeByRef(Object.ParentDoc, "IsForFolioSplit") Then
			OpenForm("Catalog.AccommodationTemplates.Form.tcChoiceForm", , ThisObject, Object.Folio);
		Else
			// Get price for room rate and date choosen
			GetRoomRatePrice();
			QuantityOnChange(Items.Quantity);
		EndIf;
	EndIf;
EndProcedure //  AfterRateChargeModeSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure SetRateChargeModeAppearance()
	If IsRoomRatePosting Then
		Items.GroupRatePostingMode.Visible = True;
	Else
		Items.GroupRatePostingMode.Visible = False;
	EndIf;
EndProcedure //  SetRateChargeModeAppearance

// -----------------------------------------------------------------------------
&AtServer
Procedure GetRoomRatePrice(pObject = Undefined)
	vObject = pObject;
	If pObject = Undefined Then
		vObject = Object;
	EndIf;
	
	// Statistics change mode
	vManualRoomRateChargingIsChangingRoomsSoldStatistics = Constants.ManualRoomRateChargingIsChangingRoomsSoldStatistics.Get();
	If Items.FillRoomNightsStatistics.Check Then
		vManualRoomRateChargingIsChangingRoomsSoldStatistics = True;
	EndIf;
	
	// Room types table
	vRoomTypes = New ValueTable();
	vRoomTypes.Columns.Add("RoomType", cmGetCatalogTypeDescription("RoomTypes"));
	vRoomTypes.Columns.Add("RoomsAvailable", cmGetNumberTypeDescription(10, 0));
	vRoomTypes.Columns.Add("BedsAvailable", cmGetNumberTypeDescription(10, 0));
	vRoomTypes.Columns.Add("LastReservationDate", cmGetDateTimeTypeDescription());
	If ValueIsFilled(vObject.RoomType) Then
		vRoomTypesRow = vRoomTypes.Add();
		vRoomTypesRow.RoomType = vObject.RoomType;
	EndIf;
	
	vParentDoc = Undefined;
	vOneRoomDocs = Undefined;
	vIsForFolioSplit = False;
	If ValueIsFilled(vObject.ParentDoc) And (TypeOf(vObject.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vObject.ParentDoc) = Type("DocumentRef.Reservation")) Then
		vParentDoc = vObject.ParentDoc;
		If Not vParentDoc.IsForFolioSplit Then
			If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Then
				vOneRoomDocs = cmGetOneRoomAccommodations(vParentDoc.Room, vParentDoc.GuestGroup, vParentDoc.CheckInDate, vParentDoc.CheckOutDate, vParentDoc.Number);
			ElsIf TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Then
				vOneRoomDocs = cmGetOneRoomReservations(vParentDoc.Number, vParentDoc.GuestGroup, vParentDoc.CheckInDate, vParentDoc.CheckOutDate);
			EndIf;
		Else
			vIsForFolioSplit = True;
		EndIf;
	EndIf;
	
	// Probe document object to calculate prices
	vProbeObj = Documents.Reservation.CreateDocument();
	vProbeObj.Hotel = vObject.Hotel;
	vProbeObj.pmFillAttributesWithDefaultValues(True);
	If ValueIsFilled(vParentDoc) Then
		FillPropertyValues(vProbeObj, vParentDoc, , "Author, Date, PriceCalculationDate, CheckInDate, CheckOutDate, Duration, RoomTypeUpgrade");
	EndIf;
	vProbeObj.RoomQuantity = 1;
	vProbeObj.RoomRate = vObject.RoomRate;
	vProbeObj.RoomType = vObject.RoomType;
	vProbeObj.Room = Catalogs.Rooms.EmptyRef();
	vProbeObj.ClientType = vObject.ClientType;
	vProbeObj.CheckInDate = BegOfDay(vObject.ServiceDate) + (vProbeObj.CheckInDate - BegOfDay(vProbeObj.CheckInDate));
	vProbeObj.Duration = 1;
	vProbeObj.CheckOutDate = BegOfDay(vObject.ServiceDate) + (vProbeObj.CheckOutDate - BegOfDay(vProbeObj.CheckOutDate)) + 24 * 3600 * vProbeObj.Duration;
	vProbeObj.IsForFolioSplit = vIsForFolioSplit;
	If ValueIsFilled(vParentDoc) Then
		vProbeObj.ServicePackage = vParentDoc.ServicePackage;
		For Each vParentDocSPRow In vParentDoc.ServicePackages Do
			vProbeObjSPRow = vProbeObj.ServicePackages.Add();
			FillPropertyValues(vProbeObjSPRow, vParentDocSPRow);
		EndDo;
		For Each vParentDocPriceRow In vParentDoc.Prices Do
			vProbeObjPriceRow = vProbeObj.Prices.Add();
			FillPropertyValues(vProbeObjPriceRow, vParentDocPriceRow);
		EndDo;
		For Each vParentDocOPRow In vParentDoc.OccupationPercents Do
			vProbeObjOPRow = vProbeObj.OccupationPercents.Add();
			FillPropertyValues(vProbeObjOPRow, vParentDocOPRow);
		EndDo;
	EndIf;
	
	vAccommodationTypes = Undefined;
	vKidsAgesArray = New Array();
	If vOneRoomDocs <> Undefined Then
		vAccommodationTypes = New ValueTable();
		vAccommodationTypes.Columns.Add("AccommodationType", cmGetCatalogTypeDescription("AccommodationTypes"));
		For Each vOneRoomDocsRow In vOneRoomDocs Do
			vOneRoomDoc = vOneRoomDocsRow.Ref;
			vAccommodationTypesRow = vAccommodationTypes.Add();
			vAccommodationTypesRow.AccommodationType = vOneRoomDoc.AccommodationType;
		EndDo;
	EndIf;
	
	vRateServicesTable = vProbeObj.Services.Unload();
	vRateServicesTable.Clear();
	
	vNumberOfAdults = 1;
	vNumberOfKids = 0;
	If ValueIsFilled(Object.AccommodationTemplate) Then
		vNumberOfAdults = Object.AccommodationTemplate.NumberOfAdults;
		vNumberOfKids = Object.AccommodationTemplate.NumberOfTeenagers + Object.AccommodationTemplate.NumberOfChildren + Object.AccommodationTemplate.NumberOfInfants;
	EndIf;
	
	// Calculate price and services
	vRoomTypeBalances = cmGetRoomTypeBalancesTable(vRoomTypes, True, vProbeObj.Hotel, vProbeObj.CheckInDate, vProbeObj.CheckOutDate, vProbeObj.ClientType, vProbeObj.Customer, vProbeObj.Contract, vProbeObj.DiscountType, , , , vObject.RoomType, vObject.RoomRate, vAccommodationTypes, vNumberOfAdults, vNumberOfKids, vKidsAgesArray, vProbeObj, False, vProbeObj.ServicePackage, Object.AccommodationTemplate, , vRateServicesTable, True);
	
	vRateServicesTable.GroupBy("AccountingDate, Service, VATRate, Unit, Price, IsRoomRevenue, IsInPrice, CalendarDayType, PriceTag, FolioCurrency, DiscountType, Discount, DiscountServiceGroup, AgentCommissionType, AgentCommission, IsSplit, RoomRevenueAmountsOnly", "Quantity, Sum, VATSum, DiscountSum, VATDiscountSum, CommissionSum, VATCommissionSum, RoomsRented, BedsRented, AdditionalBedsRented, GuestDays, GuestsCheckedIn");
	RateServicesTable.Clear();
	vAccServiceRow = Undefined;
	For Each vRateServicesTableRow In vRateServicesTable Do
		RateServicesTableRow = RateServicesTable.Add();
		FillPropertyValues(RateServicesTableRow, vRateServicesTableRow);
		If RateServicesTableRow.FolioCurrency <> vObject.FolioCurrency Then
			RateServicesTableRow.Sum = Round(cmConvertCurrencies(RateServicesTableRow.Sum, RateServicesTableRow.FolioCurrency, , vObject.FolioCurrency, , vObject.ExchangeRateDate, vObject.Hotel), 2);
			RateServicesTableRow.VATSum = Round(cmConvertCurrencies(RateServicesTableRow.VATSum, RateServicesTableRow.FolioCurrency, , vObject.FolioCurrency, , vObject.ExchangeRateDate, vObject.Hotel), 2);
			RateServicesTableRow.DiscountSum = Round(cmConvertCurrencies(RateServicesTableRow.DiscountSum, RateServicesTableRow.FolioCurrency, , vObject.FolioCurrency, , vObject.ExchangeRateDate, vObject.Hotel), 2);
			RateServicesTableRow.VATDiscountSum = Round(cmConvertCurrencies(RateServicesTableRow.VATDiscountSum, RateServicesTableRow.FolioCurrency, , vObject.FolioCurrency, , vObject.ExchangeRateDate, vObject.Hotel), 2);
			RateServicesTableRow.CommissionSum = Round(cmConvertCurrencies(RateServicesTableRow.CommissionSum, RateServicesTableRow.FolioCurrency, , vObject.FolioCurrency, , vObject.ExchangeRateDate, vObject.Hotel), 2);
			RateServicesTableRow.VATCommissionSum = Round(cmConvertCurrencies(RateServicesTableRow.VATCommissionSum, RateServicesTableRow.FolioCurrency, , vObject.FolioCurrency, , vObject.ExchangeRateDate, vObject.Hotel), 2);
		EndIf;
		If RateServicesTableRow.Quantity = 0 Then
			RateServicesTableRow.Quantity = 1;
		EndIf;
		If RateServicesTableRow.IsRoomRevenue And RateServicesTableRow.IsInPrice And Not RateServicesTableRow.IsSplit And RateServicesTableRow.Service <> vObject.Service Then
			If RateServicesTableRow.Quantity > 1 Then
				RateServicesTableRow.Quantity = 1;
			EndIf;
		EndIf;
		RateServicesTableRow.Price = Round(RateServicesTableRow.Sum / RateServicesTableRow.Quantity, 2);
		If RateServicesTableRow.IsRoomRevenue And RateServicesTableRow.IsInPrice And Not RateServicesTableRow.IsSplit Then
			If vAccServiceRow = Undefined Then
				If RateServicesTableRow.Service <> vObject.Service Then
					vObject.Discount = RateServicesTableRow.Discount;
					vObject.DiscountServiceGroup = RateServicesTableRow.DiscountServiceGroup;
					vObject.DiscountType = RateServicesTableRow.DiscountType;
					vObject.AgentCommission = RateServicesTableRow.AgentCommission;
					vObject.AgentCommissionServiceGroup = Undefined;
					vObject.AgentCommissionType = RateServicesTableRow.AgentCommissionType;
					vObject.Service = RateServicesTableRow.Service;
					vObject.VATRate = RateServicesTableRow.VATRate;
					vObject.Unit = RateServicesTableRow.Unit;
					vObject.PaymentSection = vObject.Service.PaymentSection;
					vObject.IsInPrice = RateServicesTableRow.IsInPrice;
					vObject.IsResourceRevenue = False;
					vObject.Quantity = RateServicesTableRow.Quantity;
					vObject.IsRoomRevenue = RateServicesTableRow.IsRoomRevenue;
					If vManualRoomRateChargingIsChangingRoomsSoldStatistics Then
						vObject.RoomRevenueAmountsOnly = RateServicesTableRow.RoomRevenueAmountsOnly;
						vObject.RoomsRented = RateServicesTableRow.RoomsRented;
						vObject.BedsRented = RateServicesTableRow.BedsRented;
						vObject.AdditionalBedsRented = RateServicesTableRow.AdditionalBedsRented;
						vObject.GuestDays = RateServicesTableRow.GuestDays;
						vObject.GuestsCheckedIn = RateServicesTableRow.GuestsCheckedIn;
					Else
						vObject.RoomRevenueAmountsOnly = ?(vObject.IsRoomRevenue, True, RateServicesTableRow.RoomRevenueAmountsOnly);
						vObject.RoomsRented = 0;
						vObject.BedsRented = 0;
						vObject.AdditionalBedsRented = 0;
						vObject.GuestDays = 0;
						vObject.GuestsCheckedIn = 0;
					EndIf;
					If ValueIsFilled(vObject.Service.Resource) Then
						vObject.Resource = vObject.Service.Resource;
					EndIf;
					// Vaucher
					If ValueIsFilled(vObject.Service) And vObject.Service.IsHotelProductService Then
						If ValueIsFilled(vParentDoc) And ValueIsFilled(vParentDoc.HotelProduct) Then
							vObject.HotelProduct = vParentDoc.HotelProduct;
						EndIf;
					EndIf;
				EndIf;

				vAccServiceRow = RateServicesTableRow;
			EndIf;
		EndIf;
	EndDo;
	
	vObject.Quantity = 1;
	vObject.Price = RateServicesTable.Total("Sum");
	vObject.Sum = vObject.Price;
	vObject.VATSum = RateServicesTable.Total("VATSum");
	vObject.DiscountSum = RateServicesTable.Total("DiscountSum");
	vObject.VATDiscountSum = RateServicesTable.Total("VATDiscountSum");
	vObject.CommissionSum = RateServicesTable.Total("CommissionSum");
	vObject.VATCommissionSum = RateServicesTable.Total("VATCommissionSum");
	
	OldQuantity = 1;

	// Revenue statistics
	Items.GroupRoomNightsStatistics.Visible = (ValueIsFilled(vObject.Service) And vObject.Service.IsRoomRevenue);
	
	// Remove folios created by documents
	If vProbeObj <> Undefined Then
		For Each vCRRow In vProbeObj.ChargingRules Do
			vFolioObj = vCRRow.ChargingFolio.GetObject();
			vFolioObj.Delete();
		EndDo;
		vProbeObj = Undefined;
	EndIf;
	
	// Planner
	CheckResourceFilled();
EndProcedure // GetRoomRatePrice

// -----------------------------------------------------------------------------
&AtClient
Procedure ServiceOnChangeAtClient(pService, pExtraParams) Export
	ServiceOnChangeAtServer(pService, pExtraParams);
EndProcedure //  ServiceOnChangeAtClient

// -----------------------------------------------------------------------------
&AtServer
Procedure RecalculateRoomInventoryStatistics()
	vObject = FormAttributeToValue("Object");
	vObject.pmFillRoomInventoryStatistics();
	ValueToFormAttribute(vObject, "Object");
EndProcedure // RecalculateRoomInventoryStatistics

// -----------------------------------------------------------------------------
&AtServer
Procedure ServiceOnChangeAtServer(pService = Undefined, pExtraParams = Undefined) Export
	vService = Object.Service;
	If ValueIsFilled(pService) Then
		vService = pService;
	EndIf;
	If ValueIsFilled(vService) Then
		Object.Service = vService;
		Object.Unit = vService.Unit;
		Object.PaymentSection = vService.PaymentSection;
		Object.IsRoomRevenue = vService.IsRoomRevenue;
		Object.IsInPrice = vService.IsInPrice;
		Object.IsResourceRevenue = vService.IsResourceRevenue;
		Object.RoomRevenueAmountsOnly = vService.RoomRevenueAmountsOnly;
		// Resource
		Object.Resource = vService.Resource;
		// Revenue statistics
		If Not Object.IsRoomRevenue Or Object.RoomRevenueAmountsOnly Or Object.IsSplit Then
			Object.RoomsRented = 0;
			Object.BedsRented = 0;
			Object.AdditionalBedsRented = 0;
			Object.GuestDays = 0;
			Object.GuestsCheckedIn = 0;
		EndIf;
		// Vaucher
		If vService.IsHotelProductService Then
			If ValueIsFilled(Object.ParentDoc) And 
			  (TypeOf(Object.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(Object.ParentDoc) = Type("DocumentRef.Reservation")) And 
			   ValueIsFilled(Object.ParentDoc.HotelProduct) Then
				Object.HotelProduct = Object.ParentDoc.HotelProduct;
			EndIf;
		EndIf;
	EndIf;
	vPriceStruct = GetServicePrice(Object.Service, EndOfDay(?(ValueIsFilled(Object.ServiceDate), Object.ServiceDate, Object.Date)));
	If vPriceStruct <> Undefined Then
		Object.VATRate = vPriceStruct.VATRate;
		Object.Price = vPriceStruct.Price;
		If Object.Quantity = 0 Then
			Object.Quantity = 1;
			OldQuantity = Object.Quantity;
		EndIf;
		Object.Sum = Round(Object.Price * Object.Quantity, 2);
		Object.VATRate = ?(Object.Company.IsUsingSimpleTaxSystem, Object.Company.VATRate, vPriceStruct.VATRate);
	Else
		Object.VATRate = Object.Company.VATRate;
	EndIf;
	// Set discounts
	vObj = FormAttributeToValue("Object");
	vObj.pmSetDiscounts();
	ValueToFormAttribute(vObj, "Object");
	// Check if user can edit service price
	If Not Object.Service.AllowChangePrice Then
		If Not cmCheckUserPermissions("HavePermissionToEditServicePrices") Then
			Items.Price.ReadOnly = True;
		EndIf;
	EndIf;    
	// Marking code   
	vUseMarking = (ValueIsFilled(vService) And vService.UseMarking);
	Items.GroupMarkingCode.Visible = vUseMarking;   
	Items.GroupPrices.ReadOnly = vUseMarking;

	// Revenue statistics
	Items.GroupRoomNightsStatistics.Visible = (ValueIsFilled(vService) And vService.IsRoomRevenue);
	// Sum on change
	SumOnChangeAtServer();
	// Planner
	CheckResourceFilled();
EndProcedure //  ServiceOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetServicePrice(pService, pDate = Undefined)
	vDate = pDate;
	If pDate = Undefined then
		vDate = EndOfDay(CurrentSessionDate());
	EndIf;
	vPrices = cmGetServicePrice(pService, Object.Hotel, vDate, Object.ClientType);
	If vPrices.Count() > 0 Then
		vPriceStruc = New Structure;
		vPriceStruc.Insert("Price", vPrices[0].Price);
		vPriceStruc.Insert("Currency", vPrices[0].Currency);
		vPriceStruc.Insert("VATRate", vPrices[0].VATRate);
		Return vPriceStruc;
	EndIf;
	Return Undefined;
EndFunction // GetServicePrice

// -----------------------------------------------------------------------------
&AtServer
Procedure VATRateAtServer(pVATRate, pExtraParams) Export 	
	If ValueIsFilled(pVATRate) Then
		Object.VATRate = pVATRate;
		CalculateVATSumAtServer();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure CalculateVATSumAtServer(pObject = Undefined) 
	vObject = pObject;
	If pObject = Undefined Then
		vObject = Object;
	EndIf;
	vObject.VATSum = cmCalculateVATSum(vObject.VATRate, vObject.Sum, vObject.Date);
	vObject.VATDiscountSum = cmCalculateVATSum(vObject.VATRate, vObject.DiscountSum, vObject.Date);
	vObject.VATCommissionSum = cmCalculateVATSum(vObject.VATRate, vObject.CommissionSum, vObject.Date);
	VATSum = cmCalculateVATSum(vObject.VATRate, vObject.Sum - vObject.DiscountSum, vObject.Date);
	If vObject.Sum < 0 Then
		vObject.IsCorrection = True;
	Else
		If ValueIsFilled(vObject.ChargeCorrectionType) Then
			vObject.IsCorrection = True;
		Else
			vObject.IsCorrection = False;
		EndIf;
	EndIf;
EndProcedure //  CalculateVATSumAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure CalculateDiscountSumAtServer(pObject = Undefined)
	vObject = pObject;
	If pObject = Undefined Then
		vObject = Object;
	EndIf;
	vDiscountType = vObject.DiscountType;
	If Not ValueIsFilled(vDiscountType) Or ValueIsFilled(vDiscountType) And Not vDiscountType.IsAmountDiscount Then
		If vObject.Discount > 100 Then
			vObject.Discount = 100;
		EndIf;
	EndIf;
	If ValueIsFilled(vObject.Service) Then
		If cmIsServiceInServiceGroup(vObject.Service, vObject.DiscountServiceGroup) Then
			If Not ValueIsFilled(vDiscountType) Then
				vObject.DiscountSum = Round(vObject.Sum * vObject.Discount / 100, 2);
				vObject.VATDiscountSum = cmCalculateVATSum(vObject.VATRate, vObject.DiscountSum, vObject.Date);
			Else
				If Not vDiscountType.IsForRackRatesOnly Or 
				   vDiscountType.IsForRackRatesOnly And ValueIsFilled(vObject.RoomRate) And vObject.RoomRate.IsRackRate Or 
				   vObject.IsAdditional Or
				   vObject.IsManual Then
					If Not vDiscountType.IsAmountDiscount Then
						vObject.DiscountSum = Round(vObject.Sum * vObject.Discount / 100, 2);
						vObject.VATDiscountSum = cmCalculateVATSum(vObject.VATRate, vObject.DiscountSum, vObject.Date);
					EndIf;
				EndIf;
			EndIf;
		Else
			vObject.DiscountSum = 0;
			vObject.VATDiscountSum = 0;
		EndIf;
	EndIf;
	If ValueIsFilled(vDiscountType) Then
		vWeekDays = vDiscountType.WeekDays;
		If Not IsBlankString(vWeekDays) Then
			If StrFind(vWeekDays, String(WeekDay(?(ValueIsFilled(vObject.ServiceDate), vObject.ServiceDate, vObject.Date)))) = 0 Then
				vObject.DiscountSum = 0;
				vObject.VATDiscountSum = 0;
			EndIf;
		EndIf;
	EndIf;
	VATSum = cmCalculateVATSum(vObject.VATRate, vObject.Sum - vObject.DiscountSum, vObject.Date);
	If pObject = Undefined Then
		Amount = vObject.Sum - vObject.DiscountSum;
	EndIf;
EndProcedure //  CalculateDiscountSumAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure CalculateCommissionSumAtServer(pObject = Undefined)
	vObject = pObject;
	If pObject = Undefined Then
		vObject = FormAttributeToValue("Object");
	EndIf;
	// Commission
	vObject.CommissionSum = 0;
	vObject.VATCommissionSum = 0;
	If ValueIsFilled(vObject.Service) Then
		If cmIsServiceInServiceGroup(vObject.Service, vObject.AgentCommissionServiceGroup) Then
			vObject.pmCommissionCalculationProcedure();
		EndIf;
	EndIf;
	If pObject = Undefined Then
		ValueToFormAttribute(vObject, "Object");
	EndIf;
EndProcedure //  CalculateVATSumAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure CalculateSum()
	If Object.Quantity = 0 Then
		Object.Quantity = 1;
		OldQuantity = Object.Quantity;
	ElsIf Object.Quantity < 0 And Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToStornoFolioCharges") Then
		Object.Quantity = -Object.Quantity;
		OldQuantity = Object.Quantity;
	EndIf;
	Object.Sum = Round(Object.Price * Object.Quantity, 2);
	SumOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure DateOnChangeAtServer(rMessage = "")
	rMessage = "";
	vObj = FormAttributeToValue("Object", Type("DocumentObject.Charge"));
	// Automatically assign new document number if year has changed
	If ValueIsFilled(vObj.Date) And ValueIsFilled(OldDate) Then
		If Year(OldDate) <> Year(vObj.Date) Then
			vObj.SetNewNumber();
		EndIf;
		OldDate = vObj.Date;
	EndIf;
	// Fill form object
	ValueToFormAttribute(vObj, "Object");
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure ServiceDateOnChangeAtServer(rMessage = "")
	rMessage = "";
	vObj = FormAttributeToValue("Object");
	// Change service price
	If ValueIsFilled(vObj.Service) Then
		vCurPrice = vObj.Price;
		vCurCurrency = vObj.FolioCurrency;
		vCurVATRate = vObj.VATRate;
		vServiceObj = vObj.Service.GetObject();
		vPriceStruct = GetServicePrice(vObj.Service, EndOfDay(?(ValueIsFilled(vObj.ServiceDate), vObj.ServiceDate, vObj.Date)));
		If vPriceStruct <> Undefined Then
			vCurPrice = vPriceStruct.Price;
			vCurCurrency = vPriceStruct.Currency;
			vCurVATRate = vPriceStruct.VATRate;
		EndIf;
		If vCurPrice <> 0 And Not vObj.Posted Then
			vObj.Price = Round(cmConvertCurrencies(vCurPrice, vCurCurrency, , vObj.FolioCurrency, vObj.FolioCurrencyExchangeRate, vObj.ExchangeRateDate, vObj.Hotel), 2);
		EndIf;
		If ValueIsFilled(vCurVATRate) Then
			vObj.VATRate = ?(vObj.Company.IsUsingSimpleTaxSystem, vObj.Company.VATRate, vCurVATRate);
		EndIf;
		vObj.Sum = Round(vObj.Price * vObj.Quantity, 2);
	EndIf;
	// Recalculate end date
	RecalculateEndDateAtServer(vObj);
	// Calendar day type
	vObj.pmFillCalendarDayTypeByFolio();
	// Set discounts
	vObj.pmSetDiscounts();
	// Recalculate 
	vObj.pmRecalculateAmounts();
	// Check available quantity
	If vObj.IsAdditional And ValueIsFilled(vObj.ServiceDate) And ValueIsFilled(vObj.Service) And vObj.Service.AvailableQuantity <> 0 Then
		vAvailableQuantity = vObj.Service.AvailableQuantity;
		vUsedQuantity = cmGetServiceUsedQuantity(vObj.Service, BegOfDay(vObj.ServiceDate), vObj.TimeFrom, vObj.TimeTo, vObj.Ref);
		If (vAvailableQuantity - vUsedQuantity) < vObj.Quantity Then
			vRestQuantity = vAvailableQuantity - vUsedQuantity;
			rMessage = TrimAll(vObj.Service) + NStr("en=' - There is: '; ru=' - Есть: '; de=' - Es gibt: '") + vAvailableQuantity + NStr("en='; Already used: '; ru='; Уже использовано: '; de='; Gebraucht: '") + vUsedQuantity + NStr("en='; Remainder: '; ru='; Остаток: '; de='; Rest: '") + vRestQuantity;
		EndIf;
	EndIf;
	// Recalculate room inventory statistics
	If vObj.RoomsRented <> 0 Or vObj.BedsRented <> 0 Or vObj.AdditionalBedsRented <> 0 Or vObj.GuestDays <> 0 Or vObj.GuestsCheckedIn <> 0 Then
		vObj.pmFillRoomInventoryStatistics();
		// Change button appearance
		Items.FillRoomNightsStatistics.Check = True;
		Items.FillRoomNightsStatistics.Title = NStr("en='Clear room-nights statistics'; ru='Очистить статистику по проданным номерам'; de='Statistik der Übernachtungen löschen'");
		Items.FillRoomNightsStatistics.Picture = PictureLib.Clear;
	EndIf;
	// Fill form object
	ValueToFormAttribute(vObj, "Object");
	// Recalculate total amounts
	CalculateSum();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure RecalculateEndDateAtServer(pObj = Undefined)
	vObj = pObj;
	If vObj = Undefined Then
		vObj = Object;
	EndIf;
	If Duration > 1 Then
		DateTo = BegOfDay(vObj.ServiceDate) + (Duration - 1) * 24 * 3600;
	Else
		Duration = 0;
		DateTo = '00010101';
	EndIf;
EndProcedure //  RecalculateEndDateAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure RecalculateDurationAtServer(pObj = Undefined)
	vObj = pObj;
	If vObj = Undefined Then
		vObj = Object;
	EndIf;
	If ValueIsFilled(DateTo) And ValueIsFilled(vObj.ServiceDate) And BegOfDay(DateTo) > BegOfDay(vObj.ServiceDate) Then
		Duration = (BegOfDay(DateTo) - BegOfDay(vObj.ServiceDate)) / (24 * 3600) + 1;
	Else
		Duration = 0;
		DateTo = '00010101';
	EndIf;
EndProcedure //  RecalculateDurationAtServer

// -----------------------------------------------------------------------------
&AtServer
Function CheckChargingPeriodAtServer()
	vResult = True;
	If TypeOf(Object.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(Object.ParentDoc) = Type("DocumentRef.Reservation") Then
		vParentDocCheckInDate = BegOfDay(Object.ParentDoc.CheckInDate);
		If ValueIsFilled(Object.ParentDoc.ParentDoc) And vParentDocCheckInDate > BegOfDay(Object.ParentDoc.ParentDoc.CheckInDate) Then
			vParentDocCheckInDate = BegOfDay(Object.ParentDoc.ParentDoc.CheckInDate);
		EndIf;
		vParentDocCheckOutDate = BegOfDay(Object.ParentDoc.CheckOutDate);
		If ValueIsFilled(Object.ParentDoc.ParentDoc) And vParentDocCheckOutDate < BegOfDay(Object.ParentDoc.ParentDoc.CheckOutDate) Then
			vParentDocCheckOutDate = BegOfDay(Object.ParentDoc.ParentDoc.CheckOutDate);
		EndIf;
		vObject = FormAttributeToValue("Object");
		SetObjectAndFormAttributeConformity(vObject, "Object");
		If ValueIsFilled(DateTo) And ValueIsFilled(Object.ServiceDate) Then
			If BegOfDay(DateTo) <= BegOfDay(Object.ServiceDate) Then
				vResult = False;   
				
				vMsg = NStr("en='End date is wrong!'; ru='Дата окончания указана раньше даты начисления!'; de='Eindedatum ist falsch!'");
				tcCommonFunctionOnClientServer.UserMessage(vMsg, vObject, "Date", , True); 
				
				DateTo = '00010101';
				Duration = 0;
			Else
				If (vParentDocCheckOutDate + 24 * 3600) < BegOfDay(DateTo) Then
					tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'End date is later then check-out date!'; 
																	|de = 'Eindedatum ist später als Abreisedatum!'; 
																	|ru = 'Дата окончания указана позже даты выселения!'"));
					DateTo = vParentDocCheckOutDate;
					RecalculateDurationAtServer();
				EndIf;
			EndIf;
		ElsIf ValueIsFilled(Object.ServiceDate) Then
			If (vParentDocCheckOutDate + 24 * 3600) < BegOfDay(Object.ServiceDate) Then
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Charge date is later then check-out date!'; 
																 |de = 'Datum ist später als Abreisedatum!'; 
																 |ru = 'Дата начисления указана позже даты выселения!'"));
				Object.ServiceDate = vParentDocCheckOutDate;
				DateTo = '00010101';
				Duration = 0;
			EndIf;
			If (vParentDocCheckInDate - 24 * 3600) > BegOfDay(Object.ServiceDate) Then  
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Charge date is earlier then check-in date!'; de = 'Datum ist früher als Anreisedatum!'; ru = 'Дата начисления указана раньше даты заезда!'"));
				Object.ServiceDate = vParentDocCheckInDate;
				DateTo = '00010101';
				Duration = 0;
			EndIf;
		EndIf;
	EndIf;
	Return vResult;
EndFunction //  CheckChargingPeriodAtServer

// -----------------------------------------------------------------------------
&AtServer
Function CheckDocumentAttributesAtServer(rMessage)
	vObj = FormAttributeToValue("Object");	
	SetObjectAndFormAttributeConformity(vObj, "Object");
	// Basic checks
	vAttributeInErr = "";
	If vObj.pmCheckDocumentAttributes(rMessage, vAttributeInErr) Then   
		tcCommonFunctionOnClientServer.UserMessage(NStr(rMessage), vObj, vAttributeInErr, , True); 
		Return False;
	Else
		// Check user rights to charge extra services folio on credit
		If vObj.IsNew() And ValueIsFilled(vObj.Folio) And Not IsBlankString(vObj.Folio.Description) And 
		   ValueIsFilled(vObj.Hotel) And Not IsBlankString(vObj.Hotel.AdditionalServicesFolioCondition) Then
			If Find(Upper(TrimAll(vObj.Folio.Description)), Upper(TrimAll(vObj.Hotel.AdditionalServicesFolioCondition))) > 0 Then
				If ValueIsFilled(vObj.Service) And Not vObj.Service.ChargeOnCreditIsAllowed Then
					If Not cmCheckUserPermissions("HavePermissionToChargeExtraServicesOnCredit") Then
						vFolioBalance = vObj.Folio.GetObject().pmGetBalance() - vObj.Folio.CreditLimit;
						If (vFolioBalance + (vObj.Sum - vObj.DiscountSum)) > 0 Then
							rMessage = "en = 'You are not allowed to charge service on credit!'; 
									   |de = 'Sie sind nicht berechtigt, den Service für Kredit aufladen!'; 
									   |ru = 'Нет прав начислять услугу в кредит!'";
							tcCommonFunctionOnClientServer.UserMessage(NStr(rMessage), vObj, "Sum", , True); 
							Return False;
						EndIf;
					EndIf;
				EndIf;
				If ValueIsFilled(vObj.ParentDoc) And (TypeOf(vObj.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vObj.ParentDoc) = Type("DocumentRef.Reservation")) Then
					If vObj.ParentDoc.NoPost And Not vObj.IsRoomRevenue And Not vObj.IsInPrice And vObj.IsAdditional Then
						rMessage = "ru='На брони выставлен запрет дополнительных начислений (No post)!';
						           |en='Extra charges are prohibited for the reservation (No post)!';
								   |de='Zusätzliche Gebühren sind bei der Reservierung verboten (Keine Post)!'";
						tcCommonFunctionOnClientServer.UserMessage(NStr(rMessage), vObj, "Sum", , True);						
						Return False;
					EndIf;
				EndIf;
			EndIf; 
		EndIf; 
		If vObj.IsNew() And vObj.Service.UseMarking And IsBlankString(vObj.MarkingCode) Then   
			rMessage = NStr("en = 'A tagged item has been selected, but the DataMatrix has not been scanned.
                             |To charge the service, you must scan the marking code.'; de = 'Ein markiertes Element wurde ausgewählt, die DataMatrix wurde jedoch nicht gescannt.
                             |Um den Service in Rechnung zu stellen, müssen Sie den Markierungscode scannen.'; ru = 'Выбран маркированный товар, но DataMatrix не отсканирован.
                             |Для начисления услуги необходимо отсканировать код маркировки.'");
			tcCommonFunctionOnClientServer.UserMessage(rMessage, vObj, "MarkingCode", , True); 
			Return False;	
		EndIf;
		Return True;
	EndIf;	
EndFunction // CheckDocumentAttributesAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	// Check rights for the new document
	If pWriteParameters.WriteMode = DocumentWriteMode.Posting Then
		If Not ValueIsFilled(pCurrentObject.Ref) And ValueIsFilled(pCurrentObject.ParentDoc) Then
			If Not cmCheckUserPermissions("HavePermissionToChargeIgnoringChargingRules") Then
				If TypeOf(pCurrentObject.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(pCurrentObject.ParentDoc) = Type("DocumentRef.Reservation") Then
					vCRTab = pCurrentObject.ParentDoc.ChargingRules.Unload();
					If Not pCurrentObject.ParentDoc.IgnoreGroupChargingRules Then
						cmAddGuestGroupChargingRules(vCRTab, pCurrentObject.ParentDoc.GuestGroup);
					EndIf;
					If vCRTab.Find(pCurrentObject.Folio, "ChargingFolio") <> Undefined Then
						// Set folio according to the current charging rules
						vCRFolio = Undefined;
						For Each vCRRow In vCRTab Do
							// Check if current service fit to the current charging rule
							If cmIsServiceFitToTheChargingRule(vCRRow, pCurrentObject.Service, BegOfDay(pCurrentObject.Date), ?(IsRoomRatePosting, True, Not pCurrentObject.IsAdditional), pCurrentObject.IsRoomRevenue) Then
								vCRFolio = vCRRow.ChargingFolio;
								Break;
							EndIf;
						EndDo;
						If ValueIsFilled(vCRFolio) And vCRFolio <> pCurrentObject.Folio Then
							pCancel = True;
							SetObjectAndFormAttributeConformity(pCurrentObject, "Object");
							vMessage = NStr("en='The selected service should be charged to a different folio according to the charging rules! '; 
							                |ru='Выбранная услуга по правилам начисления должна начисляться в другой лицевой счет! '; 
											|de='Der ausgewählte Dienst nach den Abgrenzungsregeln in einem anderen persönlichen Konto berechnet werden! '") + 
							           NStr("en='Go to folio with number '; ru='Перейдите в лицевой счет с номером '; de='Gehen Sie zur persönlichen Kontonummer '") + cmGetDocumentNumberPresentation(vCRFolio.Number);
							tcCommonFunctionOnClientServer.UserMessage(vMessage, pCurrentObject, "Service", , True);									   
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		If Not pCancel Then
			If RateServicesTable.Count() > 0 Then
				vCurrentObjectRef = pCurrentObject.Ref;
				If Not ValueIsFilled(vCurrentObjectRef) Then
					vCurrentObjectRef = pCurrentObject.GetNewObjectRef();
					If Not ValueIsFilled(vCurrentObjectRef) Then
						pCurrentObject.SetNewObjectRef(Documents.Charge.GetRef());
						vCurrentObjectRef = pCurrentObject.GetNewObjectRef();
					EndIf;
				EndIf;
				vIsMergedToRoomRevenue = Object.Hotel.RoomRatePackagesServicesAreNotShownInFolios;
				pCurrentObject.RoomRevenueCharge = Undefined;
				pCurrentObject.IsMergedToRoomRevenue = False;
				pCurrentObject.RateSum = 0;
				pCurrentObject.RateDiscountSum = 0;
				pCurrentObject.RateCommissionSum = 0;
				For Each vRateServicesTableRow In RateServicesTable Do
					If RateServicesTable.IndexOf(vRateServicesTableRow) = 0 Then
						pCurrentObject.RateSum = pCurrentObject.RateSum + pCurrentObject.Sum;
						pCurrentObject.RateDiscountSum = pCurrentObject.RateDiscountSum + pCurrentObject.DiscountSum;
						pCurrentObject.RateCommissionSum = pCurrentObject.RateCommissionSum + pCurrentObject.CommissionSum;
						If vRateServicesTableRow.IsInPrice And vRateServicesTableRow.IsRoomRevenue And Not vRateServicesTableRow.IsSplit And Not vRateServicesTableRow.RoomRevenueAmountsOnly Then
							pCurrentObject.IsMergedToRoomRevenue = vIsMergedToRoomRevenue;
						EndIf;
					EndIf;
					If vRateServicesTableRow.IsInPrice And Not (vRateServicesTableRow.IsRoomRevenue And Not vRateServicesTableRow.IsSplit And Not vRateServicesTableRow.RoomRevenueAmountsOnly) Then
						vRateServicesTableRow.RoomRevenueCharge = vCurrentObjectRef;
					EndIf;
				EndDo;
				If pCurrentObject.RateSum <> 0 And pCurrentObject.IsMergedToRoomRevenue Then
					Items.GroupRoomRateRevenue.Visible = True;
					RateAmount = pCurrentObject.RateSum - pCurrentObject.RateDiscountSum;
					PackagesAmount = pCurrentObject.RateSum - pCurrentObject.Sum;
					PackagesDiscountAmount = pCurrentObject.RateDiscountSum - pCurrentObject.DiscountSum;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // BeforeWriteAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure CashRegisterClearingAtServer(pStandardProcessing)
	If ValueIsFilled(PaymentMethod) And PaymentMethod.BookByCashRegister Then
		If Items.CashRegister.ChoiceList.Count() > 0 Then
			CashRegister = Items.CashRegister.ChoiceList.Get(0).Value;
		EndIf;
	EndIf;
EndProcedure //  CashRegisterClearingAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SetDeletionMarkAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.Read();
	vObj.SetDeletionMark(True);    
	ValueToFormAttribute(vObj, "Object"); 
	// User activity history   
	vEventDescription = StrTemplate(NStr("en = 'Delete charge: %1, %2'; 
										|de = 'Gebühr löschen: %1, %2'; 
										|ru = 'Удаление начисления: %1, %2'"), TrimAll(Object.Ref), cmFormatSum(Object.Sum, Object.FolioCurrency));  
	If ValueIsFilled(Object.ParentDoc) Then
		vParentDoc = Object.ParentDoc; 
	Else
		vParentDoc = Object.Ref;
	EndIf;	
	InformationRegisters.UserActionsHistory.WriteUserActivityRecord(vParentDoc, vEventDescription, Object.Hotel);
EndProcedure //  SetDeletionMarkAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ComplimentaryFolioCheckAfterAnswer(pUserAnswer, pWriteParameters) Export
	If pUserAnswer = DialogReturnCode.Yes Then
		ComplimentaryFolioIsChecked = True;
		If Write(pWriteParameters) Then
			Close();
		EndIf;
	EndIf;
EndProcedure //  ComplimentaryFolioCheckAfterAnswer

// -----------------------------------------------------------------------------
&AtServer
Procedure DiscountTypeOnChangeAtServer()
	If Not ValueIsFilled(Object.DiscountType) Then
		Object.DiscountServiceGroup = Catalogs.ServiceGroups.EmptyRef();
		Object.Discount = 0;
		Object.DiscountConfirmationText = "";
	Else
		vDiscountType = Object.DiscountType;
		Object.DiscountServiceGroup = vDiscountType.DiscountServiceGroup;
		Object.DiscountConfirmationText = vDiscountType.ConfirmationPattern;
		If vDiscountType.IsAccumulatingDiscount Then
			vObj = FormAttributeToValue("Object");
			vObj.pmCalculateAccumulationDiscount();
			ValueToFormAttribute(vObj, "Object");
		Else	
			vDiscountTypeObj = vDiscountType.GetObject();
			Object.Discount = vDiscountTypeObj.pmGetDiscount(Object.Date, Object.Service, Object.Hotel);
		EndIf;
		vWeekDays = vDiscountType.WeekDays;
		If Not IsBlankString(vWeekDays) Then
			If StrFind(vWeekDays, String(WeekDay(?(ValueIsFilled(Object.ServiceDate), Object.ServiceDate, Object.Date)))) = 0 Then
				Discount = 0;
			EndIf;
		EndIf;
	EndIf;
	
	// Discount type
	IsAmountDiscount = ?(ValueIsFilled(vDiscountType), vDiscountType.IsAmountDiscount, False);
EndProcedure //  DiscountTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure MarketingCodeOnChangeAtServer()
	// Set discounts
	vObj = FormAttributeToValue("Object");
	vObj.pmSetDiscounts();
	ValueToFormAttribute(vObj, "Object");
	// Sum on change
	SumOnChangeAtServer();
EndProcedure //  MarketingCodeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillRoomNightsStatisticsAtServer()
	If Not Items.FillRoomNightsStatistics.Check Then
		Items.FillRoomNightsStatistics.Check = True;
		Items.FillRoomNightsStatistics.Title = NStr("en='Clear room-nights statistics'; ru='Очистить статистику по проданным номерам'; de='Statistik der Übernachtungen löschen'");
		Items.FillRoomNightsStatistics.Picture = PictureLib.Clear;
		// Fill statistics
		RecalculateRoomInventoryStatistics();
	Else
		Items.FillRoomNightsStatistics.Check = False;
		Items.FillRoomNightsStatistics.Title = NStr("en='Fill room-nights statistics'; ru='Заполнить статистику по проданным номерам'; de='Statistik der Übernachtungen ausfüllen'");
		Items.FillRoomNightsStatistics.Picture = PictureLib.Report;
		// Clear statistics
		Object.RoomsRented = 0;
		Object.BedsRented = 0;
		Object.AdditionalBedsRented = 0;
		Object.GuestDays = 0;
		Object.GuestsCheckedIn = 0;
	EndIf;
EndProcedure //  FillRoomNightsStatisticsAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FolioOnChangeAtServer()
	vChargeObj = FormAttributeToValue("Object");
	vNewFolio = vChargeObj.Folio;
	If vNewFolio.Hotel <> vChargeObj.Hotel Then
		vChargeObj.Hotel = vNewFolio.Hotel;
		vChargeObj.SetNewNumber();
	EndIf;
	vChargeObj.ParentDoc = vNewFolio.ParentDoc;
	If ValueIsFilled(vNewFolio.Company) And vChargeObj.Company <> vNewFolio.Company Then
		vNewCompany = vNewFolio.Company;
		vChargeObj.Company = vNewCompany;
		If vNewCompany.IsUsingSimpleTaxSystem And vChargeObj.VATRate <> vNewCompany.VATRate Then
			vChargeObj.VATRate = vNewCompany.VATRate;
		EndIf;
	EndIf;
	If vChargeObj.FolioCurrency <> vNewFolio.FolioCurrency Then
		vChargeObj.FolioCurrency = vNewFolio.FolioCurrency;
		vChargeObj.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(vChargeObj.Hotel, vChargeObj.FolioCurrency, vChargeObj.ExchangeRateDate);
	EndIf;
	vChargeObj.VATSum = cmCalculateVATSum(vChargeObj.VATRate, vChargeObj.Sum, vChargeObj.Date);
	vChargeObj.VATDiscountSum = cmCalculateVATSum(vChargeObj.VATRate, vChargeObj.DiscountSum, vChargeObj.Date);
	vChargeObj.VATCommissionSum = cmCalculateVATSum(vChargeObj.VATRate, vChargeObj.CommissionSum, vChargeObj.Date);
	ValueToFormAttribute(vChargeObj, "Object");
	VATSum = cmCalculateVATSum(Object.VATRate, Object.Sum - Object.DiscountSum, Object.Date);
EndProcedure //  FolioOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargeServiceByBarcode(pMarkingCode)   
	If IsBlankString(pMarkingCode) Then
		Return;
	EndIf;	
	vService = Undefined;   
	vErr = "";  
	vBarcode = ""; 
	vMarkingCode = pMarkingCode;
	If StrLen(pMarkingCode)> 13 Then // It's datamatrix code   
		// Convert string to base64 string	
		vMS = New MemoryStream;
		vTxt = New TextWriter(vMS) ;
		vTxt.Write(pMarkingCode);
		vTxt.Close();
		vBD = vMS.CloseAndGetBinaryData();
		vMarkingCode = Base64String(vBD);   
		
		vUseCharge = CheckMarkingCode(vMarkingCode); 
		If ValueIsFilled(vUseCharge) Then
			ShowMessageBox(, StrTemplate(Nstr("en = 'There is already an accrual with this marking code
			|%1'; de = 'Mit diesem Markierungscode besteht bereits eine Rückstellung
			|%1'; ru = 'Уже есть начисление с таким кодом маркировки 
			|%1'"), vUseCharge), , Nstr("en = 'ERROR'; de = 'ERROR'; ru = 'ОШИБКА'"));	   
			Return;
		EndIf;	
		Object.MarkingCode = vMarkingCode;
	EndIf;
	
EndProcedure // ChargeServiceByBarcode

// -----------------------------------------------------------------------------
&AtServerNoContext
Function CheckMarkingCode(pMarkingCode)
	vQuery = New Query;
	vQuery.Text = "SELECT
	|	Charge.Ref AS Ref,
	|	Storno.Ref AS Storno
	|FROM
	|	Document.Charge AS Charge
	|		LEFT JOIN Document.Storno AS Storno
	|		ON (Storno.ParentCharge = Charge.Ref)
	|WHERE
	|	Charge.MarkingCode = &qMarkingCode
	|	AND Charge.DeletionMark = FALSE
	|	AND Charge.Posted = TRUE
	|	AND Storno.Number IS NULL";
	
	vQuery.SetParameter("qMarkingCode", pMarkingCode);
	
	vQueryResult = vQuery.Execute();
	If vQueryResult.IsEmpty() Then
		Return Undefined;
	Else	
		vRes = vQueryResult.Select();
		vRes.Next();
		Return vRes.Ref;
	EndIf;
EndFunction // CheckMarkingCode

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckResourceFilled()
	vOneHour = 3600;
	
	If ValueIsFilled(Object.Resource) Then
		// Show resource page
		Items.GroupRight.Visible = True;
		
		If Object.Ref.IsEmpty() And ValueIsFilled(Object.ParentDoc) And TypeOf(Object.ParentDoc) = Type("DocumentRef.ResourceReservation") Then
			Object.ParentDoc = Undefined;
		EndIf;
		If ValueIsFilled(Object.ParentDoc) And TypeOf(Object.ParentDoc) = Type("DocumentRef.ResourceReservation") And Object.ParentDoc.Resource = Object.Resource Then
			DateResource = BegOfDay(Object.ParentDoc.DateTimeFrom);
			DateFrom = Object.ParentDoc.DateTimeFrom;
			DateTill = Object.ParentDoc.DateTimeTo;
			Duration = Object.ParentDoc.Duration;
			If Not IsBlankString(Object.Unit) And Catalogs.Units.FindByDescription(TrimAll(Object.Unit)) = Catalogs.Units.Night Then
				Duration = Duration / 24;
			EndIf;	
		Else
			DateResource = BegOfDay(Object.Date);
			DateFrom = BegOfDay(Object.Date) + (Object.TimeFrom - BegOfDay(Object.TimeFrom));
			If ValueIsFilled(Object.TimeTo) Then
				If Not IsBlankString(Object.Unit) And Catalogs.Units.FindByDescription(TrimAll(Object.Unit)) = Catalogs.Units.Night Then
					DateTill = BegOfDay(Object.Date) + (Object.TimeTo - BegOfDay(Object.TimeTo)) + 24 * vOneHour * ?(Duration = 0, 1, Duration);
				Else
					DateTill = BegOfDay(Object.Date) + (Object.TimeTo - BegOfDay(Object.TimeTo));
				EndIf;
			Else
				If Not IsBlankString(Object.Unit) And Catalogs.Units.FindByDescription(TrimAll(Object.Unit)) = Catalogs.Units.Night Then
					DateTill = BegOfDay(Object.Date) + 24 * vOneHour * ?(Duration = 0, 1, Duration);
				Else
					DateTill = BegOfDay(Object.Date) + vOneHour;
				EndIf;
			EndIf;
			Duration = Object.Quantity;
		EndIf;
	Else
		Items.GroupRight.Visible = False;
	EndIf;
	UpdatePeriodOfPlanner();
EndProcedure // CheckResourceFilled

// -----------------------------------------------------------------------------
&AtServer
Procedure UpdatePeriodOfPlanner()
	// vars:
	
	vOneHour = 3600;
	vOneMin = 60;
	
	// Planner 
	
	ResourceCalendar.Items.Clear();
	ResourceCalendar.CurrentRepresentationPeriods.Clear();
	ResourceCalendar.Dimensions.Clear();
	
	ResourceCalendar.ShowCurrentDate = False;
	
	ResourceStartDate = Object.ServiceDate;
	ResourceEndDate = Object.ServiceDate;
	
	// ResourceName = Object.Resource;	
	
	Object.TimeFrom = Date(Year(Object.ServiceDate), Month(Object.ServiceDate), Day(Object.ServiceDate), Hour(Object.TimeFrom), Minute(Object.TimeFrom), Second(Object.TimeFrom)); 
	
	Object.TimeTo = Date(Year(Object.ServiceDate), Month(Object.ServiceDate), Day(Object.ServiceDate), Hour(Object.TimeTo), Minute(Object.TimeTo), Second(Object.TimeTo)); 
	
	vBeginDate = BegOfDay(Object.ServiceDate);
	vEndDate = BegOfDay(Object.ServiceDate) + 24 * vOneHour;		
	ResourceCalendar.CurrentRepresentationPeriods.Add(vBeginDate, vEndDate);
	
	If ResourceQuantity = 0 Then
		ResourceQuantity = 1;
	EndIf;

	// seconds (TimeTo - TimeFrom)
	If Minute(Object.TimeTo) -  Minute(Object.TimeFrom) < 0 Then
		vSecondsFromPeriod = (Hour(Object.TimeTo) - Hour(Object.TimeFrom)) * vOneHour + (vOneMin - Minute(Object.TimeFrom)) * vOneMin; 		
	Else
		vSecondsFromPeriod = (Hour(Object.TimeTo) - Hour(Object.TimeFrom)) * vOneHour + (Minute(Object.TimeTo) -  Minute(Object.TimeFrom))
		 * vOneMin + Second(Object.TimeTo) - Second(Object.TimeFrom);
	EndIf;
	
	// Period * Quantity
	If ResourceQuantity > 1 Then
		vQuaniryPeriod = vSecondsFromPeriod * ResourceQuantity; 
	Else	
		vQuaniryPeriod = 0;
		vSecondsFromPeriod = 0;
	EndIf;
	
	vDem1 = ResourceCalendar.Dimensions.Add(NStr("ru = 'Измерение'; de = 'Messung'; en = 'Measurement'"));
	vDemItem1 = vDem1.Items.Add(NStr("ru = 'Бронируем'; de = 'Buchung'; en = 'Booking'"), NStr("ru = 'Бронируем'; de = 'Buchung'; en = 'Booking'"));
	vDemItem2 = vDem1.Items.Add(NStr("ru = 'Занято'; de = 'Beschäftigt'; en = 'Busy'"), NStr("ru = 'Занято'; de = 'Beschäftigt'; en = 'Busy'"));
	
	vMapForDem = New Map;
	vMapForDem.Insert(NStr("ru = 'Измерение'; de = 'Messung'; en = 'Measurement'"), NStr("ru = 'Бронируем'; de = 'Buchung'; en = 'Booking'")); 
	
	vItemPlanner = ResourceCalendar.Items.Add(Date(Year(Object.ServiceDate), Month(Object.ServiceDate), Day(Object.ServiceDate), Hour(Object.TimeFrom), Minute(Object.TimeFrom),
	Second(Object.TimeFrom)), Date(Year(Object.ServiceDate), Month(Object.ServiceDate), Day(Object.ServiceDate), Hour(Object.TimeTo), Minute(Object.TimeTo), Second(Object.TimeTo)) + vQuaniryPeriod - vSecondsFromPeriod);
	
	vItemPlanner.DimensionValues = New FixedMap(vMapForDem);						
	
	If ValueIsFilled(Object.Service)
		And ValueIsFilled(Object.TimeFrom)
		And ValueIsFilled(Object.TimeTo) Then
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	ResourceReservation.DateTimeTo AS DateTimeTo,
		|	ResourceReservation.DateTimeFrom AS DateTimeFrom,
		|	ResourceReservation.Recorder AS Ref,
		|	ResourceReservation.Client AS Client
		|FROM
		|	InformationRegister.ResourceReservationHistory AS ResourceReservation
		|WHERE
		|	(ResourceReservation.Resource = &qResource
		|			OR ResourceReservation.Resource = &qResourceParent
		|				AND &qResourceParent <> &qEmptyResource)
		|	AND ResourceReservation.DateTimeTo > &qBegOfDay
		|	AND ResourceReservation.DateTimeFrom < &qEndOfDay
		|	AND ResourceReservation.ResourceReservationStatus.IsActive
		|	AND ResourceReservation.Recorder <> &qThisDocument
		|
		|ORDER BY
		|	ResourceReservation.DateTimeFrom";
		
		Query.SetParameter("qResource", Object.Resource);
		Query.SetParameter("qResourceParent", Object.Resource.Parent);
		Query.SetParameter("qEmptyResource", Catalogs.Resources.EmptyRef());
		Query.SetParameter("qBegOfDay", BegOfDay(ResourceStartDate) - vOneHour);
		Query.SetParameter("qEndOfDay", EndOfDay(ResourceStartDate));
		Query.SetParameter("qThisDocument", Object.ParentDoc);
				
		QueryResult = Query.Execute();
		
		SelectionDetailRecords = QueryResult.Select();
		
		While SelectionDetailRecords.Next() Do
			vMapForDem = New Map;
			vMapForDem.Insert(NStr("ru = 'Измерение'; de = 'Messung'; en = 'Measurement'"), NStr("ru = 'Занято'; de = 'Beschäftigt'; en = 'Busy'"));
			
			vItemPlanner = ResourceCalendar.Items.Add(Date(Year(Object.ServiceDate), Month(Object.ServiceDate), Day(Object.ServiceDate),
			Hour(SelectionDetailRecords.DateTimeFrom), Minute(SelectionDetailRecords.DateTimeFrom), Second(SelectionDetailRecords.DateTimeFrom)),
			Date(Year(Object.ServiceDate), Month(Object.ServiceDate), Day(Object.ServiceDate),
			Hour(SelectionDetailRecords.DateTimeTo), Minute(SelectionDetailRecords.DateTimeTo), Second(SelectionDetailRecords.DateTimeTo)));
			
			vItemPlanner.DimensionValues = New FixedMap(vMapForDem);
		EndDo;		
		
	EndIf;
	
	If Object.TimeFrom = Date(0001, 01, 01, 00, 00, 00) Then 
		Object.TimeFrom = CurrentSessionDate();
		Object.TimeTo = CurrentSessionDate() + vOneHour;
	EndIf;
	If ResourceQuantity > 1 Then
		Object.TimeTo = Date(Year(Object.ServiceDate), Month(Object.ServiceDate), Day(Object.ServiceDate), Hour(Object.TimeTo), Minute(Object.TimeTo), Second(Object.TimeTo)) + vQuaniryPeriod - vSecondsFromPeriod;	
	EndIf;
	
EndProcedure // UpdatePeriodOfPlanner

// -----------------------------------------------------------------------------
&AtServer
Function CheckDocumentIsNew()
	
	If Object.Ref = Documents.Charge.EmptyRef() Then
		Return False;
	Else
		Return True;
	EndIf;

EndFunction // CheckDocumentIsNew

#EndRegion
