
#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pObj						 - DocumentObject	 - Object payment
//  pObjRef						 - DocumentRef		 - Ref payment document
//  pIsCorrection				 - Boolean			 - Is correction or not
//  pCorrectionType				 - EnumRef.CorrectionChequeTypes - Ref
//  pCorrectionDescription		 - String						 - Correction description
//  pCorrectionDocumentNumber	 - Number						 - Correction document number
//  pCorrectionDocumentDate		 - Date							 - Correction document date
// 
// Returns:
//  Structure - Cheque attributes
//
Function InitializeChequeAttributes(Val pObj, pObjRef = Undefined, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate) Export
	vChequeAttrs = New Structure("Hotel, Payment, CashDay, CashDayChequeNumber, ChequeAccountingType, BuyerAddress, PaymentMethod, TaxationSystem, CashierName,
									|FiscalStorageFactoryNumber, ChequeFiscalNumber, ChequeSequenceNumber, ChequeDateTime, Sum,
									|VATRate1, VATSum1, VATRate2, VATSum2, VATRate3, VATSum3, VATRate4, VATSum4, VATRate5, VATSum5, VATRate6, VATSum6,
									|IsCorrection, CorrectionType, CorrectionDescription, CorrectionDocumentNumber, CorrectionDocumentDate, FDFVersion, CashRegister, ExternalCode, ReceiptUrl, UUID, Remarks",
									Undefined, Undefined, 0, 0, Undefined, "", "", Undefined, "",
									"", "", "", '00010101', 0,
									Undefined, 0, Undefined, 0, Undefined, 0, Undefined, 0, Undefined, 0, Undefined, 0,
									False, Undefined, "", "", '00010101', "", Undefined, "", "", Undefined, "");
	If pObjRef = Undefined Then
		If ValueIsFilled(pObj.Ref) Then
			vChequeAttrs.Payment = pObj.Ref;
		Else
			vChequeAttrs.Payment = pObj.GetNewObjectRef();
		EndIf;
	Else
		vChequeAttrs.Payment = pObjRef;
	EndIf;
	vChequeAttrs.Hotel = pObj.Hotel;
	vChequeAttrs.PaymentMethod = TrimAll(pObj.PaymentMethod.Description);
	vChequeAttrs.CashierName = TrimAll(pObj.Author.Description);
	vChequeAttrs.Sum = pObj.Sum;
	vChequeAttrs.ChequeDateTime = CurrentSessionDate();
	vChequeAttrs.IsCorrection = pIsCorrection;
	vChequeAttrs.CorrectionType = pCorrectionType;
	vChequeAttrs.CorrectionDescription = pCorrectionDescription;
	vChequeAttrs.CorrectionDocumentNumber = pCorrectionDocumentNumber;
	vChequeAttrs.CorrectionDocumentDate = pCorrectionDocumentDate;
	vChequeAttrs.UUID = New UUID();
	vChequeAttrs.FDFVersion = "1.2";
	If ValueIsFilled(pObj.CashRegister) Then
		vCashRegister = pObj.CashRegister;
		If vCashRegister.FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_0_5 Then
			vChequeAttrs.FDFVersion = "1.05";
		ElsIf vCashRegister.FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_1 Then
			vChequeAttrs.FDFVersion = "1.1";
		EndIf;
		vChequeAttrs.CashRegister = vCashRegister;
	EndIf;
	Return vChequeAttrs;
EndFunction // InitializeChequeAttributes 

// -----------------------------------------------------------------------------
//
// Parameters:
//  pObj			 - DocumentObject	 - Object payment
//  rIsPrepayment	 - Boolean			 - IsPrepayment
//  pUseAveragePrice - Boolean			 - UseAveragePrice
// 
// Returns:
//  Array - PrintableChequePositions
//
Function GetPrintableChequePositions(Val pObj, rIsPrepayment = False, pUseAveragePrice = False) Export
	vFolioObj = Undefined;
	vAdvanceBalance = 0;
	vAdvanceSettlementMode = False;
	vAdvancePaymentSection = Undefined;
	vAdvanceSettlementAmount = 0;
	vPaymentAmount = 0;
	vUseFolioDetailedTransactions = False;
	vCashRegister = Undefined;
	If Not pUseAveragePrice Then
		If (TypeOf(pObj) = Type("DocumentObject.Payment") Or TypeOf(pObj) = Type("DocumentObject.Return") 
			Or TypeOf(pObj) = Type("DocumentRef.Payment") Or TypeOf(pObj) = Type("DocumentRef.Return") 
			Or TypeOf(pObj) = Type("FormDataStructure") And pObj.Property("Folio") And pObj.Property("SumInFolioCurrency")) 
			And ValueIsFilled(pObj.Folio) And ValueIsFilled(pObj.PaymentMethod) Then
			vIsReturn = False;
			vCashRegister = pObj.CashRegister;
			vPaymentRef = pObj.Ref;
			If TypeOf(pObj) = Type("DocumentObject.Return") Or TypeOf(pObj) = Type("DocumentRef.Return") Or 
				TypeOf(pObj) = Type("FormDataStructure") And pObj.Property("Payment") And Not pObj.Property("Preauthorisation") Then
				vIsReturn = True;
				If ValueIsFilled(pObj.Payment) Then
					vPaymentRef = pObj.Payment;
				EndIf;
			EndIf;
			If pObj.PaymentMethod = Catalogs.PaymentMethods.AdvanceSettlement Then
				// Check if this payment is the only one in the folio
				vDocs = GetFolioAdvanceSettlementPayments(pObj.Folio, vPaymentRef);
				If vDocs.Count() = 0 Then
					vFolioObj = pObj.Folio.GetObject();
					// Check if advance settlement amount is equal to the folio balance
					For Each vPSRow In pObj.PaymentSections Do
						If ValueIsFilled(vPSRow.PaymentSection) And vPSRow.PaymentSection.ChequeItemType = Enums.ChequeItemTypes.Payment Then
							vAdvanceSettlementAmount = vAdvanceSettlementAmount - vPSRow.SumInFolioCurrency;
							If Not ValueIsFilled(vAdvancePaymentSection) Then
								vAdvancePaymentSection = vPSRow.PaymentSection;
							EndIf;
						EndIf;
					EndDo;
					If ValueIsFilled(vAdvancePaymentSection) Then
						vAdvanceBalance = vFolioObj.pmGetBalance(Undefined, pObj.Hotel, vAdvancePaymentSection);
						If Not vIsReturn Then
							If (pObj.Posted And vAdvanceBalance = 0) Or 
								(Not pObj.Posted And vAdvanceBalance <> 0 And vAdvanceBalance <= vAdvanceSettlementAmount) Then
								vUseFolioDetailedTransactions = True;
								vAdvanceSettlementMode = True;
							EndIf;
						Else
							If (Not pObj.Posted And vAdvanceBalance = 0) Or 
								(pObj.Posted And vAdvanceBalance <> 0 And vAdvanceBalance <= vAdvanceSettlementAmount) Then
								vUseFolioDetailedTransactions = True;
								vAdvanceSettlementMode = True;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			ElsIf Not ValueIsFilled(pObj.PaymentSection) Or ValueIsFilled(pObj.PaymentSection) And pObj.PaymentSection.ChequeItemType <> Enums.ChequeItemTypes.Payment Then
				// Check if this payment is the only one in the folio
				vDocs = GetFolioPayments(pObj.Folio, vPaymentRef);
				If vDocs.Count() = 0 Then
					// Check if advance settlement amount is equal to the folio balance
					For Each vPSRow In pObj.PaymentSections Do
						vPaymentAmount = vPaymentAmount + vPSRow.SumInFolioCurrency;
					EndDo;
					// Check if payment amount is equal to the folio balance
					vFolioObj = pObj.Folio.GetObject();
					vFolioBalance = vFolioObj.pmGetBalance(Undefined, pObj.Hotel);
					If Not vIsReturn Then
						If (pObj.Posted And vFolioBalance = 0) Or 
							(Not pObj.Posted And vFolioBalance <> 0 And vFolioBalance = vPaymentAmount) Then
							vUseFolioDetailedTransactions = True;
						EndIf;
					Else
						If (Not pObj.Posted And vFolioBalance = 0) Or 
							(pObj.Posted And vFolioBalance <> 0 And vFolioBalance = vPaymentAmount) Then
							vUseFolioDetailedTransactions = True;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	vPaymentSections = New ValueTable();
	vPaymentSections.Columns.Add("AccountingDate", cmGetDateTypeDescription());
	vPaymentSections.Columns.Add("PaymentSection", cmGetCatalogTypeDescription("PaymentSections"));
	vPaymentSections.Columns.Add("ChequeService", cmGetCatalogTypeDescription("Services"));
	vPaymentSections.Columns.Add("ChequeServiceCode", cmGetStringTypeDescription(11));
	vPaymentSections.Columns.Add("ChequeServiceSortCode", cmGetNumberTypeDescription(6, 0));
	vPaymentSections.Columns.Add("VATRate", cmGetCatalogTypeDescription("VATRates"));
	vPaymentSections.Columns.Add("ChequeServicePrice", cmGetSumTypeDescription());
	vPaymentSections.Columns.Add("ChequeServiceQuantity", cmGetQuantityTypeDescription());
	vPaymentSections.Columns.Add("Sum", cmGetSumTypeDescription());
	vPaymentSections.Columns.Add("VATSum", cmGetSumTypeDescription());
	vPaymentSections.Columns.Add("SumInFolioCurrency", cmGetSumTypeDescription());
	vPaymentSections.Columns.Add("VATSumInFolioCurrency", cmGetSumTypeDescription());
	vPaymentSections.Columns.Add("MarkingCode", cmGetStringTypeDescription(300));
	vPaymentSections.Columns.Add("Item", cmGetCatalogTypeDescription("OrderItems"));
	vPaymentSections.Columns.Add("ItemCode", cmGetStringTypeDescription(9));
	vPaymentSections.Columns.Add("ItemDescription", cmGetStringTypeDescription(100));
	vPaymentSections.Columns.Add("ParentDocNumber", cmGetStringTypeDescription(12));
	
	vAllFolioTransactions = Undefined;
	vAllFolioTransactionsAmount = 0;
	If vUseFolioDetailedTransactions And vFolioObj <> Undefined Then
		vAllFolioTransactions = vFolioObj.pmGetAllFolioTransactions(, True, , False, True);
		For Each vTrRow In vAllFolioTransactions Do
			If vTrRow.RecordType = AccumulationRecordType.Receipt And ValueIsFilled(vTrRow.Service) Then
				vAllFolioTransactionsAmount = vAllFolioTransactionsAmount + vTrRow.Sum;
			EndIf;
		EndDo;
	EndIf;		
	If vFolioObj <> Undefined And vUseFolioDetailedTransactions And 
		(vAdvanceSettlementMode And vAllFolioTransactionsAmount = vAdvanceSettlementAmount Or
		Not vAdvanceSettlementMode And vAllFolioTransactionsAmount = vPaymentAmount) Then
		For Each vTrRow In vAllFolioTransactions Do
			If vTrRow.RecordType = AccumulationRecordType.Receipt And ValueIsFilled(vTrRow.Service) Then
				vPaymentSectionsRow = vPaymentSections.Add();
				vPaymentSectionsRow.AccountingDate = ?(vTrRow.IsInPrice Or ValueIsFilled(vTrRow.Service.HideIntoServiceOnPrint), vTrRow.CorrectedServiceDate, '00010101');
				vPaymentSectionsRow.PaymentSection = Undefined;
				vPaymentSectionsRow.ChequeService = vTrRow.Service;
				vPaymentSectionsRow.ChequeServiceCode = vTrRow.ServiceCode;
				vPaymentSectionsRow.ChequeServiceSortCode = vTrRow.ServiceSortCode;
				vPaymentSectionsRow.VATRate = vTrRow.VATRate;
				vPaymentSectionsRow.ChequeServiceQuantity = ?(vTrRow.Quantity = 0, 1, vTrRow.Quantity);
				vPaymentSectionsRow.SumInFolioCurrency = vTrRow.Sum;
				vPaymentSectionsRow.VATSumInFolioCurrency = vTrRow.VATSum;
				vPaymentSectionsRow.Sum = cmConvertCurrencies(vPaymentSectionsRow.SumInFolioCurrency, vFolioObj.FolioCurrency, , pObj.PaymentCurrency, , pObj.ExchangeRateDate, pObj.Hotel);
				vPaymentSectionsRow.VATSum = cmConvertCurrencies(vPaymentSectionsRow.VATSumInFolioCurrency, vFolioObj.FolioCurrency, , pObj.PaymentCurrency, , pObj.ExchangeRateDate, pObj.Hotel);
				vPaymentSectionsRow.ChequeServicePrice = Round(vPaymentSectionsRow.Sum / vPaymentSectionsRow.ChequeServiceQuantity, 2);
				vPaymentSectionsRow.MarkingCode = vTrRow.MarkingCode; 
				vPaymentSectionsRow.Item = vTrRow.Item; 
				vPaymentSectionsRow.ItemCode = vTrRow.ItemCode; 
				vPaymentSectionsRow.ItemDescription = vTrRow.ItemDescription; 
				vPaymentSectionsRow.ParentDocNumber = ?(ValueIsFilled(vTrRow.ChargeParentDoc), TrimAll(vTrRow.ChargeParentDoc.Number), ""); 
				If vPaymentSectionsRow.Sum < 0 Or vPaymentSectionsRow.ChequeServiceQuantity < 0 Or vPaymentSectionsRow.ChequeServicePrice < 0 Then
					Return GetPrintableChequePositions(pObj, rIsPrepayment, True);
				EndIf;
				
				If ValueIsFilled(vPaymentSectionsRow.AccountingDate) Then
					vChequeService = vPaymentSectionsRow.ChequeService;
					If ValueIsFilled(vChequeService) Then
						vChequeServiceType = vChequeService.ServiceType;
						If ValueIsFilled(vChequeServiceType) And vChequeServiceType.RevenueSegment = Enums.RevenueSegments.Transport Then
							If BegOfDay(vPaymentSectionsRow.AccountingDate) <= BegOfDay(vFolioObj.DateTimeFrom) Then
								vPaymentSectionsRow.AccountingDate = BegOfDay(vFolioObj.DateTimeFrom);
							EndIf;
							If ValueIsFilled(vTrRow.RoomRate) And vTrRow.RoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour Then
								If BegOfDay(vPaymentSectionsRow.AccountingDate) >= BegOfDay(vFolioObj.DateTimeTo) Then
									vPaymentSectionsRow.AccountingDate = BegOfDay(vFolioObj.DateTimeTo) - 24*3600;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		vPaymentSections.GroupBy("AccountingDate, PaymentSection, ChequeService, ChequeServiceSortCode, ChequeServiceCode, ChequeServicePrice, VATRate, MarkingCode, Item, ItemCode, ItemDescription, ParentDocNumber", "ChequeServiceQuantity, Sum, VATSum, SumInFolioCurrency, VATSumInFolioCurrency");
		vPaymentSections.Sort("AccountingDate, ChequeServiceSortCode, ChequeServiceCode, ItemCode, ItemDescription");
		// Check prepayment mode
		vPrepaymentPaymentSection = Undefined;
		vPrepaymentPaymentSections = cmGetAdvancePaymentSections(vFolioObj.Hotel);
		For Each vPSRow In pObj.PaymentSections Do
			If ValueIsFilled(vPSRow.ChequeService) Then
				If ValueIsFilled(vPSRow.PaymentSection) And vPSRow.PaymentSection.ChequeItemType = Enums.ChequeItemTypes.Payment Then
					vPrepaymentPaymentSection = vPSRow.PaymentSection;
					rIsPrepayment = True;
					Break;
				EndIf;
			Else
				Break;
			EndIf;
		EndDo;
		// Fill payment section
		For Each vPaymentSectionsRow In vPaymentSections Do
			If Not vAdvanceSettlementMode Then
				If rIsPrepayment Then
					If ValueIsFilled(vPrepaymentPaymentSection) Then
						If vPrepaymentPaymentSections.Count() = 1 Then
							vPaymentSectionsRow.PaymentSection = vPrepaymentPaymentSection;
						ElsIf vPrepaymentPaymentSections.Count() > 1 Then
							vPrepaymentPaymentSectionsArr = vPrepaymentPaymentSections.FindRows(New Structure("VATRate", vPaymentSectionsRow.VATRate));
							If vPrepaymentPaymentSectionsArr.Count() > 0 Then
								vPaymentSectionsRow.PaymentSection = vPrepaymentPaymentSectionsArr[0].Ref;
							EndIf;
						EndIf;
					EndIf;
				Else
					If ValueIsFilled(vPaymentSectionsRow.ChequeService) And ValueIsFilled(vPaymentSectionsRow.ChequeService.PaymentSection) Then
						vPaymentSectionsRow.PaymentSection = vPaymentSectionsRow.ChequeService.PaymentSection;
					EndIf;
				EndIf;
			Else
				If ValueIsFilled(vPaymentSectionsRow.ChequeService) And ValueIsFilled(vPaymentSectionsRow.ChequeService.PaymentSection) Then
					vPaymentSectionsRow.PaymentSection = vPaymentSectionsRow.ChequeService.PaymentSection;
				EndIf;
			EndIf;
		EndDo;
	Else
		If pObj.PaymentMethod = Catalogs.PaymentMethods.AdvanceSettlement And pObj.Sum = 0 Then
			For Each vPSRow In pObj.PaymentSections Do
				If Not ValueIsFilled(vPSRow.PaymentSection) Or 
					(ValueIsFilled(vPSRow.PaymentSection) And vPSRow.PaymentSection.ChequeItemType <> Enums.ChequeItemTypes.Payment) Then
					vPaymentSectionsRow = vPaymentSections.Add();
					FillPropertyValues(vPaymentSectionsRow, vPSRow);
					vPaymentSectionsRow.ChequeServiceSortCode = ?(ValueIsFilled(vPaymentSectionsRow.ChequeService), vPaymentSectionsRow.ChequeService.SortCode, 0);
					vPaymentSectionsRow.ChequeServiceCode = ?(ValueIsFilled(vPaymentSectionsRow.ChequeService), vPaymentSectionsRow.ChequeService.Code, "");
					vPaymentSectionsRow.ItemCode = ?(ValueIsFilled(vPaymentSectionsRow.Item), vPaymentSectionsRow.Item.Code, "");
					vPaymentSectionsRow.ItemDescription = ?(ValueIsFilled(vPaymentSectionsRow.Item), vPaymentSectionsRow.Item.Description, "");
				EndIf;
			EndDo;
		Else
			For Each vPSRow In pObj.PaymentSections Do
				vPaymentSectionsRow = vPaymentSections.Add();
				FillPropertyValues(vPaymentSectionsRow, vPSRow);
				vPaymentSectionsRow.ChequeServiceSortCode = ?(ValueIsFilled(vPaymentSectionsRow.ChequeService), vPaymentSectionsRow.ChequeService.SortCode, 0);
				vPaymentSectionsRow.ChequeServiceCode = ?(ValueIsFilled(vPaymentSectionsRow.ChequeService), vPaymentSectionsRow.ChequeService.Code, "");
				vPaymentSectionsRow.ItemCode = ?(ValueIsFilled(vPaymentSectionsRow.Item), vPaymentSectionsRow.Item.Code, "");
				vPaymentSectionsRow.ItemDescription = ?(ValueIsFilled(vPaymentSectionsRow.Item), vPaymentSectionsRow.Item.Description, "");
			EndDo;
		EndIf;
	EndIf;
	
	If pUseAveragePrice Then
		vDoGroupBy = False;
		vRoomRateServiceToPrint = Undefined;
		vFirstRoomRateService = Undefined;
		vFirstRoomRateServiceVATRate = Undefined;
		vFirstRoomRateServiceIsFound = False;
		vFirstReplacedService = Undefined;
		For Each vPSRow In vPaymentSections Do
			If ValueIsFilled(vPSRow.ChequeService) Then
				vService = vPSRow.ChequeService;
				vServiceToPrint = vService.HideIntoServiceOnPrint;
				vDoGroupBy = True;
				vZeroRowQuantity = False;
				If vService.IsRoomRevenue And vService.IsInPrice And Not vService.RoomRevenueAmountsOnly Then
					If Not ValueIsFilled(vRoomRateServiceToPrint) And ValueIsFilled(vServiceToPrint) Then
						vRoomRateServiceToPrint = vServiceToPrint;
					EndIf;
					If Not vFirstRoomRateServiceIsFound Then
						vFirstRoomRateService = vService;
						vFirstRoomRateServiceVATRate = vPSRow.VATRate;
						vFirstRoomRateServiceIsFound = True;
					Else
						If vFirstRoomRateService <> vService And ValueIsFilled(vServiceToPrint) Then
							vZeroRowQuantity = True;
						EndIf;
					EndIf;
				ElsIf Not vService.DoNotGroupIntoRoomRateOnPrint And ValueIsFilled(vServiceToPrint) Then
					If ValueIsFilled(vRoomRateServiceToPrint) And vServiceToPrint <> vRoomRateServiceToPrint Or Not ValueIsFilled(vRoomRateServiceToPrint) Then
						If Not ValueIsFilled(vFirstReplacedService) Then
							vFirstReplacedService = vService;
						Else
							If vService <> vFirstReplacedService Then
								vZeroRowQuantity = True;
							EndIf;
						EndIf;
					Else
						vZeroRowQuantity = True;
					EndIf;
				EndIf;
				If ValueIsFilled(vServiceToPrint) Then
					vPrintPSRow = vPaymentSections.Find(vServiceToPrint, "ChequeService");
					If vPrintPSRow <> Undefined And 
					  (vPrintPSRow.VATRate = vPSRow.VATRate Or ValueIsFilled(vCashRegister) And vCashRegister.IgnoreVATRateOnGrouping) Then
						vPSRow.ChequeService = vServiceToPrint;
						vPSRow.ChequeServicePrice = 0;
						If vZeroRowQuantity Then
							vPSRow.ChequeServiceQuantity = 0;
						EndIf;
						vPSRow.VATRate = vPrintPSRow.VATRate;
						vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, pObj.ExchangeRateDate);
						vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, pObj.ExchangeRateDate);
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		If vDoGroupBy Then
			vPaymentSections.GroupBy("AccountingDate, PaymentSection, ChequeService, VATRate, MarkingCode, Item, ItemCode, ItemDescription, ParentDocNumber", "ChequeServiceQuantity, Sum, VATSum, SumInFolioCurrency, VATSumInFolioCurrency");
			vPaymentSections.Columns.Add("ChequeServicePrice", cmGetSumTypeDescription());
			For Each vPSRow In vPaymentSections Do
				If vPSRow.ChequeServiceQuantity = 0 Then
					vPSRow.ChequeServiceQuantity = 1;
				EndIf;
				vPSRow.ChequeServicePrice = Round(vPSRow.Sum / vPSRow.ChequeServiceQuantity, 2);
			EndDo;
		EndIf;
	Else
		// Group in prices services into accommodation service by default only in detailed accounts transactions mode
		vHotel = Undefined;
		vRoomRatePackagesServicesAreNotShownInFolios = False;
		If (TypeOf(pObj) = Type("DocumentObject.Payment") Or TypeOf(pObj) = Type("DocumentObject.Return") Or  
			TypeOf(pObj) = Type("DocumentRef.Payment") Or TypeOf(pObj) = Type("DocumentRef.Return") Or 
			TypeOf(pObj) = Type("FormDataStructure") And pObj.Property("Hotel")) And ValueIsFilled(pObj.Hotel) Then
			vHotel = pObj.Hotel;
			vRoomRatePackagesServicesAreNotShownInFolios = vHotel.RoomRatePackagesServicesAreNotShownInFolios;
		EndIf;
		// Preprocessing
		vTotalSum = 0;
		vUseAveragePrice = False;
		vUseDailyPrice = False;
		vDoGroupBy = False;
		vFirstRoomRateService = Undefined;
		vFirstRoomRateServiceVATRate = Undefined;
		vFirstRoomRateServiceIsFound = False;
		For Each vPSRow In vPaymentSections Do
			If ValueIsFilled(vPSRow.ChequeService) Then
				vService = vPSRow.ChequeService;
				If vService.IsRoomRevenue And vService.IsInPrice And Not vService.RoomRevenueAmountsOnly Then
					If Not vRoomRatePackagesServicesAreNotShownInFolios Then
						If Not vFirstRoomRateServiceIsFound Then
							vFirstRoomRateService = vService;
							vFirstRoomRateServiceVATRate = vPSRow.VATRate;
							vFirstRoomRateServiceIsFound = True;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			vTotalSum = vTotalSum + vPSRow.Sum;
		EndDo;
		For Each vPSRow In vPaymentSections Do
			If ValueIsFilled(vPSRow.ChequeService) Then
				vService = vPSRow.ChequeService;
				vServiceToPrint = vService.HideIntoServiceOnPrint;  
				If ValueIsFilled(vServiceToPrint) And vServiceToPrint <> vService Then
					vPrintPSRow = vPaymentSections.Find(vServiceToPrint, "ChequeService");
					If vPrintPSRow <> Undefined And 
					  (vPrintPSRow.VATRate = vPSRow.VATRate Or ValueIsFilled(vCashRegister) And vCashRegister.IgnoreVATRateOnGrouping) Then
						vPSRow.ChequeService = vServiceToPrint;
						If Not vService.DoNotGroupIntoRoomRateOnPrint Then
							vPSRow.ChequeServiceQuantity = 0;
							vDoGroupBy = True;
						EndIf;
						vPSRow.VATRate = vPrintPSRow.VATRate;
						vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, pObj.ExchangeRateDate);
						vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, pObj.ExchangeRateDate);
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		If vDoGroupBy Then
			vPaymentSections.GroupBy("AccountingDate, PaymentSection, ChequeService, VATRate, MarkingCode, Item, ItemCode, ItemDescription, ParentDocNumber", "ChequeServiceQuantity, Sum, VATSum, SumInFolioCurrency, VATSumInFolioCurrency");
			vPaymentSections.Columns.Add("ChequeServicePrice", cmGetSumTypeDescription());
			For Each vPSRow In vPaymentSections Do
				If vPSRow.ChequeServiceQuantity = 0 Then
					vPSRow.ChequeServiceQuantity = 1;
				EndIf;
				vPSRow.ChequeServicePrice = Round(vPSRow.Sum / vPSRow.ChequeServiceQuantity, 2);
			EndDo;
		EndIf;
		// Main algorithm
		vInd = 0;
		While vInd < vPaymentSections.Count() Do
			vPSRow = vPaymentSections.Get(vInd);
			If ValueIsFilled(vPSRow.ChequeService) Then
				vService = vPSRow.ChequeService;
				If Not vService.IsRoomRevenue And vService.IsInPrice And ValueIsFilled(vFirstRoomRateService) Then
					If Not vService.DoNotGroupIntoRoomRateOnPrint Then
						vTotalBaseQuantity = 0;
						If ValueIsFilled(vPSRow.AccountingDate) Then
							vBasePSRows = vPaymentSections.FindRows(New Structure("ChequeService, AccountingDate, VATRate, ParentDocNumber", vFirstRoomRateService, vPSRow.AccountingDate, vPSRow.VATRate, vPSRow.ParentDocNumber));
						Else
							vBasePSRows = vPaymentSections.FindRows(New Structure("ChequeService, VATRate", vFirstRoomRateService, vPSRow.VATRate));
						EndIf;
						For Each vBasePSRow In vBasePSRows Do
							vTotalBaseQuantity = vTotalBaseQuantity + vBasePSRow.ChequeServiceQuantity;
						EndDo;
						If vTotalBaseQuantity = 0 Then
							If vPSRow.VATRate = vFirstRoomRateServiceVATRate Then
								If ValueIsFilled(vPSRow.AccountingDate) Then
									vInd = vInd + 1;
									Continue;
								Else
									vUseAveragePrice = True;
									Break;
								EndIf;
							Else
								vInd = vInd + 1;
								Continue;
							EndIf;
						Else
							vK = vPSRow.ChequeServiceQuantity / vTotalBaseQuantity;
							If ValueIsFilled(vPSRow.AccountingDate) Or vK = Int(vK) Then
								vUseDailyPrice = False;
							ElsIf vK <> Int(vK) And Int(vPSRow.ChequeServiceQuantity) = vPSRow.ChequeServiceQuantity And vPSRow.ChequeServiceQuantity > 0 Then
								vUseDailyPrice = True;
							Else
								vUseAveragePrice = True;
								Break;
							EndIf;
						EndIf;
						If vUseDailyPrice Then
							// Split base rows to rows with 1 quantity
							For Each vBasePSRow In vBasePSRows Do
								vBasePSRowQuantity = vBasePSRow.ChequeServiceQuantity;
								If Int(vBasePSRowQuantity) = vBasePSRowQuantity Then
									If vBasePSRowQuantity > 1 Then
										j = vPaymentSections.IndexOf(vBasePSRow);
										vBasePSRow.ChequeServiceQuantity = 1;
										vBasePSRow.Sum = vBasePSRow.ChequeServicePrice;
										vBasePSRow.SumInFolioCurrency = Round(vBasePSRow.SumInFolioCurrency / vBasePSRowQuantity, 2);
										vBasePSRow.VATSum = cmCalculateVATSum(vBasePSRow.VATRate, vBasePSRow.Sum, pObj.ExchangeRateDate);
										vBasePSRow.VATSumInFolioCurrency = cmCalculateVATSum(vBasePSRow.VATRate, vBasePSRow.SumInFolioCurrency, pObj.ExchangeRateDate);
										For q = 2 To vBasePSRowQuantity Do
											p = j + q - 1;
											vNewPSRow = vPaymentSections.Insert(p);
											FillPropertyValues(vNewPSRow, vBasePSRow);
										EndDo;
									EndIf;
								Else
									vUseAveragePrice = True;
									Break;
								EndIf;
							EndDo;
							// Split current row to rows with 1 quantity
							vSplittedPSRows = New Array();
							vPSRowQuantity = vPSRow.ChequeServiceQuantity;
							If Int(vPSRowQuantity) = vPSRowQuantity Then
								If vPSRowQuantity > 1 Then
									k = vPaymentSections.IndexOf(vPSRow);
									vPSRow.ChequeServiceQuantity = 1;
									vPSRow.Sum = vPSRow.ChequeServicePrice;
									vPSRow.SumInFolioCurrency = Round(vPSRow.SumInFolioCurrency / vPSRowQuantity, 2);
									vPSRow.VATSum = cmCalculateVATSum(vPSRow.VATRate, vPSRow.Sum, pObj.ExchangeRateDate);
									vPSRow.VATSumInFolioCurrency = cmCalculateVATSum(vPSRow.VATRate, vPSRow.SumInFolioCurrency, pObj.ExchangeRateDate);
									vSplittedPSRows.Add(vPSRow);
									For q = 2 To vPSRowQuantity Do
										p = k + q - 1;
										vNewPSRow = vPaymentSections.Insert(p);
										FillPropertyValues(vNewPSRow, vPSRow);
										vSplittedPSRows.Add(vNewPSRow);
									EndDo;
								Else
									vSplittedPSRows.Add(vPSRow);
								EndIf;
							Else
								vUseAveragePrice = True;
								Break;
							EndIf;
							// Add splitted rows to splitted base rows 1 by 1
							l = 0;
							vUseLast = True;
							vDeleted = False;
							If ValueIsFilled(vPSRow.AccountingDate) Then
								vBasePSRows = vPaymentSections.FindRows(New Structure("ChequeService, AccountingDate, VATRate, ParentDocNumber", vFirstRoomRateService, vPSRow.AccountingDate, vPSRow.VATRate, vPSRow.ParentDocNumber));
							Else
								vBasePSRows = vPaymentSections.FindRows(New Structure("ChequeService, VATRate", vFirstRoomRateService, vPSRow.VATRate));
							EndIf;
							For Each vSplittedPSRow In vSplittedPSRows Do
								vFIFO = True;
								If ValueIsFilled(vSplittedPSRow.ChequeService) And ValueIsFilled(vSplittedPSRow.ChequeService.ServiceType) And vSplittedPSRow.ChequeService.ServiceType.RevenueSegment = Enums.RevenueSegments.Transport Then
									vFIFO = False;
									vUseLast = Not vUseLast;
								EndIf;
								vSplittedBasePSRow = Undefined;
								If vFIFO Then
									vSplittedBasePSRow = vBasePSRows.Get(l);
								Else
									If vUseLast Then
										vSplittedBasePSRow = vBasePSRows.Get(vBasePSRows.Count() - 1);
									Else
										vSplittedBasePSRow = vBasePSRows.Get(0);
									EndIf;
								EndIf;
								If vSplittedBasePSRow <> Undefined And vSplittedBasePSRow.ChequeServiceQuantity = 1 Then
									vSplittedBasePSRow.Sum = vSplittedBasePSRow.Sum + vSplittedPSRow.Sum;
									vSplittedBasePSRow.SumInFolioCurrency = vSplittedBasePSRow.SumInFolioCurrency + vSplittedPSRow.SumInFolioCurrency;
									vSplittedBasePSRow.VATSum = cmCalculateVATSum(vSplittedBasePSRow.VATRate, vSplittedBasePSRow.Sum, pObj.ExchangeRateDate);
									vSplittedBasePSRow.VATSumInFolioCurrency = cmCalculateVATSum(vSplittedBasePSRow.VATRate, vSplittedBasePSRow.SumInFolioCurrency, pObj.ExchangeRateDate);
									vSplittedBasePSRow.ChequeServicePrice = vSplittedBasePSRow.Sum;
									
									vPaymentSections.Delete(vSplittedPSRow);
									vDeleted = True;
								EndIf;
								l = l + 1;
								If l >= vBasePSRows.Count() Then
									l = 0;
								EndIf;
							EndDo;
							If vDeleted Then
								vInd = 0;
							EndIf;
						Else
							For Each vBasePSRow In vBasePSRows Do
								If Not ValueIsFilled(vPSRow.AccountingDate) Then
									vCorrectionSum = vPSRow.ChequeServicePrice * vBasePSRow.ChequeServiceQuantity * vK;
									vCorrectionSumInFolioCurrency = Round(vPSRow.SumInFolioCurrency / ?(vPSRow.ChequeServiceQuantity = 0, 1, vPSRow.ChequeServiceQuantity), 2) * vBasePSRow.ChequeServiceQuantity * vK;
								Else
									vCorrectionSum = vPSRow.Sum;
									vCorrectionSumInFolioCurrency = vPSRow.SumInFolioCurrency;
								EndIf;
								vBasePSRow.Sum = vBasePSRow.Sum + vCorrectionSum;
								vBasePSRow.SumInFolioCurrency = vBasePSRow.SumInFolioCurrency + vCorrectionSumInFolioCurrency;
								vBasePSRow.VATSum = cmCalculateVATSum(vBasePSRow.VATRate, vBasePSRow.Sum, pObj.ExchangeRateDate);
								vBasePSRow.VATSumInFolioCurrency = cmCalculateVATSum(vBasePSRow.VATRate, vBasePSRow.SumInFolioCurrency, pObj.ExchangeRateDate);
								vBasePSRow.ChequeServicePrice = Round(vBasePSRow.Sum / ?(vBasePSRow.ChequeServiceQuantity = 0, 1, vBasePSRow.ChequeServiceQuantity), 2);
								If ValueIsFilled(vPSRow.AccountingDate) Then
									Break;
								EndIf;
							EndDo;
							vPaymentSections.Delete(vInd);
							Continue;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			vInd = vInd + 1;
		EndDo;
		If Not vUseAveragePrice Then
			vPaymentSections.GroupBy("PaymentSection, ChequeService, VATRate, ChequeServicePrice, MarkingCode, Item, ItemCode, ItemDescription, ParentDocNumber", "ChequeServiceQuantity, Sum, VATSum, SumInFolioCurrency, VATSumInFolioCurrency");
			vNewTotalSum = 0;
			For Each vPSRow In vPaymentSections Do
				vNewTotalSum = vNewTotalSum + vPSRow.Sum;
			EndDo;
			If vTotalSum <> vNewTotalSum Then
				vUseAveragePrice = True;
			EndIf;
		EndIf;
		If vUseAveragePrice Then
			Return GetPrintableChequePositions(pObj, rIsPrepayment, True);
		Else
			// Remove zero rows
			i = 0;
			While i < vPaymentSections.Count() Do
				vPSRow = vPaymentSections.Get(i);
				If vPSRow.Sum = 0 Then
					vPaymentSections.Delete(i);
				Else
					i = i + 1;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	vArray = New Array();
	For Each vPSRow In vPaymentSections Do
		If vPSRow.ChequeServiceQuantity = 0 Then
			vPSRow.ChequeServiceQuantity = 1;
		EndIf;
		vPSRow.ChequeServicePrice = Round(vPSRow.Sum / vPSRow.ChequeServiceQuantity, 2);
		vStruct = New Structure("PaymentSection, ChequeService, VATRate, ChequeServicePrice, ChequeServiceQuantity, Sum, VATSum, SumInFolioCurrency, VATSumInFolioCurrency, MarkingCode, Item, ItemCode, ItemDescription", vPSRow.PaymentSection, vPSRow.ChequeService, vPSRow.VATRate, vPSRow.ChequeServicePrice, vPSRow.ChequeServiceQuantity, vPSRow.Sum, vPSRow.VATSum, vPSRow.SumInFolioCurrency, vPSRow.VATSumInFolioCurrency, vPSRow.MarkingCode, vPSRow.Item, vPSRow.ItemCode, vPSRow.ItemDescription);
		vArray.Add(vStruct);
	EndDo;
	For Each vPSRow In vArray Do
		If ValueIsFilled(vPSRow.ChequeService) Then
			If ValueIsFilled(vPSRow.PaymentSection) And vPSRow.PaymentSection.ChequeItemType = Enums.ChequeItemTypes.Payment Then
				rIsPrepayment = True;
				Break;
			EndIf;
		Else
			Break;
		EndIf;
	EndDo;
	Return vArray;
EndFunction // GetPrintableChequePositions

// -----------------------------------------------------------------------------
//
// Parameters:
//  pChequeAttributes	 - Structure - Cheque attributes
//  pVATRate			 - CatalogRef.VATRates	 - Ref
//  pVATSum				 - Number				 - VATSum
//
Procedure SetChequeVATAmount(pChequeAttributes, pVATRate, pVATSum) Export
	If ValueIsFilled(pVATRate) Then
		If pChequeAttributes.VATRate1 = pVATRate Then
			pChequeAttributes.VATSum1 = pChequeAttributes.VATSum1 + pVATSum;
		ElsIf pChequeAttributes.VATRate2 = pVATRate Then
			pChequeAttributes.VATSum2 = pChequeAttributes.VATSum2 + pVATSum;
		ElsIf pChequeAttributes.VATRate3 = pVATRate Then
			pChequeAttributes.VATSum3 = pChequeAttributes.VATSum3 + pVATSum;
		ElsIf pChequeAttributes.VATRate4 = pVATRate Then
			pChequeAttributes.VATSum4 = pChequeAttributes.VATSum4 + pVATSum;
		ElsIf pChequeAttributes.VATRate5 = pVATRate Then
			pChequeAttributes.VATSum5 = pChequeAttributes.VATSum5 + pVATSum;
		ElsIf pChequeAttributes.VATRate6 = pVATRate Then
			pChequeAttributes.VATSum6 = pChequeAttributes.VATSum6 + pVATSum;
		ElsIf Not ValueIsFilled(pChequeAttributes.VATRate1) Then
			pChequeAttributes.VATRate1 = pVATRate;
			pChequeAttributes.VATSum1 = pChequeAttributes.VATSum1 + pVATSum;
		ElsIf Not ValueIsFilled(pChequeAttributes.VATRate2) Then
			pChequeAttributes.VATRate2 = pVATRate;
			pChequeAttributes.VATSum2 = pChequeAttributes.VATSum2 + pVATSum;
		ElsIf Not ValueIsFilled(pChequeAttributes.VATRate3) Then
			pChequeAttributes.VATRate3 = pVATRate;
			pChequeAttributes.VATSum3 = pChequeAttributes.VATSum3 + pVATSum;
		ElsIf Not ValueIsFilled(pChequeAttributes.VATRate4) Then
			pChequeAttributes.VATRate4 = pVATRate;
			pChequeAttributes.VATSum4 = pChequeAttributes.VATSum4 + pVATSum;
		ElsIf Not ValueIsFilled(pChequeAttributes.VATRate5) Then
			pChequeAttributes.VATRate5 = pVATRate;
			pChequeAttributes.VATSum5 = pChequeAttributes.VATSum5 + pVATSum;
		ElsIf Not ValueIsFilled(pChequeAttributes.VATRate6) Then
			pChequeAttributes.VATRate6 = pVATRate;
			pChequeAttributes.VATSum6 = pChequeAttributes.VATSum6 + pVATSum;
		EndIf;
	EndIf;
EndProcedure // SetChequeVATAmount

// -----------------------------------------------------------------------------
//
// Parameters:
//  pChequeAttributes	 - Structure - Cheque attributes 
//
Procedure WriteChequeAttributes(pChequeAttributes) Export
	vChequeAttributes = InformationRegisters.ChequeAttributes.CreateRecordManager();
	FillPropertyValues(vChequeAttributes, pChequeAttributes);
	vChequeAttributes.Write();
EndProcedure // WriteChequeAttributes 

// -----------------------------------------------------------------------------
//
// Parameters:
//  pObj			 - DocumentObject	 - Object payment 
//  pService		 - CatalogRef.Services	 - Ref
//  pPaymentSection	 - CatalogRef.PaymentSections	 - Ref
//  pIsPrepayment	 - Boolean	 -  IsPrepayment
// 
// Returns:
//  EnumRef.ChequeItemTypes - Ref
//
Function GetChequeItemType(Val pObj, pService = Undefined, pPaymentSection = Undefined, pIsPrepayment = False) Export
	vItemType = Undefined;
	If pService <> Undefined Then
		If ValueIsFilled(pService) Then
			If ValueIsFilled(pService.ChequeItemType) Then
				vItemType = pService.ChequeItemType;
			ElsIf ValueIsFilled(pService.Parent) And ValueIsFilled(pService.Parent.ChequeItemType) Then
				vItemType = pService.Parent.ChequeItemType;
			EndIf;
		EndIf;
	EndIf;
	If Not ValueIsFilled(vItemType) Then
		If pPaymentSection <> Undefined Then
			If ValueIsFilled(pPaymentSection.ChequeItemType) Then
				If Not (pPaymentSection.ChequeItemType = Enums.ChequeItemTypes.Payment And pIsPrepayment) Then
					vItemType = pPaymentSection.ChequeItemType;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If Not ValueIsFilled(vItemType) Then
		If ValueIsFilled(pObj.PaymentSection) Then
			vPaymentSection = pObj.PaymentSection;
			If ValueIsFilled(vPaymentSection.ChequeItemType) Then
				If Not (vPaymentSection.ChequeItemType = Enums.ChequeItemTypes.Payment And pIsPrepayment) Then
					vItemType = vPaymentSection.ChequeItemType;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	Return vItemType;
EndFunction // GetChequeItemType

// -----------------------------------------------------------------------------
//
// Parameters:
//  pPaymentMethod	 - CatalogRef.PaymentMethods - Ref
//  pPaymentSection	 - CatalogRef.PaymentSections	 - Ref
//  pIsPrepayment	 - Boolean						 - IsPrepayment
// 
// Returns:
//  EnumRef.ChequePaymentModes - Ref Or Undefined
//
Function GetChequePaymentMode(pPaymentMethod, pPaymentSection = Undefined, pIsPrepayment = False) Export
	vPaymentMode = Undefined;
	If pPaymentMethod <> Undefined Then
		If ValueIsFilled(pPaymentMethod.ChequePaymentMode) Then
			vPaymentMode = pPaymentMethod.ChequePaymentMode;
		EndIf;
	EndIf;
	If Not ValueIsFilled(vPaymentMode) And ValueIsFilled(pPaymentSection) Then
		If pPaymentSection.ChequeItemType = Enums.ChequeItemTypes.Payment Then
			If pIsPrepayment Then
				vPaymentMode = Enums.ChequePaymentModes.Prepayment;
			Else
				vPaymentMode = Enums.ChequePaymentModes.Advance;
			EndIf;
		EndIf;
	EndIf;
	Return vPaymentMode;
EndFunction // GetChequePaymentMode

// -----------------------------------------------------------------------------
//  Returns int value for the given cheque calculation method type
//
// Parameters:
//  pCMTValue	 - EnumRef.ChequePaymentModes	 - Ref
// 
// Returns:
//  Number - Value for the given cheque calculation method type
//
Function GetChequePaymentModeTypeValue(pCMTValue) Export   
	vCMTValueNumber = 0;
	If pCMTValue = Enums.ChequePaymentModes.Prepayment100 Then
		vCMTValueNumber = 1;
	ElsIf pCMTValue = Enums.ChequePaymentModes.Prepayment Then
		vCMTValueNumber = 2;
	ElsIf pCMTValue = Enums.ChequePaymentModes.Advance Then
		vCMTValueNumber = 3;
	ElsIf pCMTValue = Enums.ChequePaymentModes.FullSettlement Then
		vCMTValueNumber = 4;
	ElsIf pCMTValue = Enums.ChequePaymentModes.PartialSettlementAndCredit Then
		vCMTValueNumber = 5;
	ElsIf pCMTValue = Enums.ChequePaymentModes.TransferToCredit Then
		vCMTValueNumber = 6;
	ElsIf pCMTValue = Enums.ChequePaymentModes.PaymentOfCredit Then
		vCMTValueNumber = 7;
	Else
		vCMTValueNumber = 4; // Full settlement by default
	EndIf;
	Return vCMTValueNumber;
EndFunction // GetChequePaymentModeTypeValue

// -----------------------------------------------------------------------------
//  Returns int value for the given cheque position type
//
// Parameters:
//  pPTValue - EnumRef.ChequeItemTypes	 - Ref
// 
// Returns:
//  Number - Value for the given cheque position type
//
Function GetChequeItemTypeValue(pPTValue) Export
	vPTValueNumber = 0;
	If pPTValue = Enums.ChequeItemTypes.Goods Then
		vPTValueNumber = 1;
	ElsIf pPTValue = Enums.ChequeItemTypes.ExcisableGoods Then
		vPTValueNumber = 2;
	ElsIf pPTValue = Enums.ChequeItemTypes.Work Then
		vPTValueNumber = 3;
	ElsIf pPTValue = Enums.ChequeItemTypes.Service Then
		vPTValueNumber = 4;
	ElsIf pPTValue = Enums.ChequeItemTypes.Bet Then
		vPTValueNumber = 5;
	ElsIf pPTValue = Enums.ChequeItemTypes.GamingPrize Then
		vPTValueNumber = 6;
	ElsIf pPTValue = Enums.ChequeItemTypes.LotteryTicket Then
		vPTValueNumber = 7;
	ElsIf pPTValue = Enums.ChequeItemTypes.LotteryWinning Then
		vPTValueNumber = 8;
	ElsIf pPTValue = Enums.ChequeItemTypes.IntellectualProperty Then
		vPTValueNumber = 9;
	ElsIf pPTValue = Enums.ChequeItemTypes.Payment Then
		vPTValueNumber = 10;
	ElsIf pPTValue = Enums.ChequeItemTypes.CompositeSubject Then
		vPTValueNumber = 11;
	ElsIf pPTValue = Enums.ChequeItemTypes.OtherSubject Then
		vPTValueNumber = 12;
	ElsIf pPTValue = Enums.ChequeItemTypes.ResortFee Then
		vPTValueNumber = 18;
	ElsIf pPTValue = Enums.ChequeItemTypes.ExciseWithoutMarking Then 
		vPTValueNumber = 30;
	ElsIf pPTValue = Enums.ChequeItemTypes.ExciseWithMarking Then 
		vPTValueNumber = 31;
	ElsIf pPTValue = Enums.ChequeItemTypes.CommodityWithoutMarking Then 
		vPTValueNumber = 32;
	ElsIf pPTValue = Enums.ChequeItemTypes.CommodityWithMarking Then 
		vPTValueNumber = 33;
	Else
		vPTValueNumber = 4; // Service by default
	EndIf;
	Return vPTValueNumber;
EndFunction // GetChequeItemTypeValue

// -----------------------------------------------------------------------------
//  Returns int value for the given cheque position type
//
// Parameters:
//  pPTValue - EnumRef.ChequeItemTypes	 - Ref
// 
// Returns:
//  Number - Value for the given cheque position type
//
Function GetChequeItemExciseValue(pExciseType, pDate, pVolume, pQuantity) Export
	vExciseValue = 0;
	If ValueIsFilled(pExciseType) And ValueIsFilled(pDate) And pVolume <> 0 And pQuantity <> 0 Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	ExciseDutyRatesSliceLast.ExciseDutyType AS ExciseDutyType,
		|	ExciseDutyRatesSliceLast.Period AS Period,
		|	ExciseDutyRatesSliceLast.Rate AS Rate,
		|	ExciseDutyRatesSliceLast.RateDescription AS RateDescription
		|FROM
		|	InformationRegister.ExciseDutyRates.SliceLast(&qPeriod, ExciseDutyType = &qExciseType) AS ExciseDutyRatesSliceLast
		|
		|ORDER BY
		|	Period";
		vQry.SetParameter("qExciseType", pExciseType);
		vQry.SetParameter("qPeriod", pDate);
		vRecords = vQry.Execute().Unload();
		For Each vRecordsRow In vRecords Do
			vExciseValue = Round(pVolume * vRecordsRow.Rate * pQuantity, 2);
			Break;
		EndDo;
	EndIf;
	Return vExciseValue;
EndFunction // GetChequeItemExciseValue

// -----------------------------------------------------------------------------
//  Function builds online cheque text based on its attributes
//
// Parameters:
//  pPayment					 - DocumentRef.Payment	 - Ref
//  rPayerAddress				 - String				 - PayerAddress
//  rFiscalStorageFactoryNumber	 - String				 - FiscalStorageFactoryNumber
//  rChequeFiscalNumber			 - String				 - ChequeFiscalNumber
//  rChequeVerificationAddress	 - String				 - ChequeVerificationAddress
// 
// Returns:
//  String - ChequeText
//
Function BuildOnlineChequeText(pPayment, rPayerAddress, rFiscalStorageFactoryNumber, rChequeFiscalNumber, rChequeVerificationAddress, rChequeSequenceNumber = "", rCashDayChequeNumber = "") Export
	rPayerAddress = "";
	rFiscalStorageFactoryNumber = "";
	rChequeFiscalNumber = "";
	rChequeVerificationAddress = "";
	rCashDayChequeNumber = "";
	rChequeSequenceNumber = "";
	
	vLanguage = pPayment.Hotel.Language;
	If ValueIsFilled(pPayment.Payer) And ValueIsFilled(pPayment.Payer.Language) Then
		vLanguage = pPayment.Payer.Language;
	EndIf;
	
	vCompany = pPayment.CashRegister.Owner;
	
	vChequeAttributes = cmGetChequeAttributes(?(ValueIsFilled(pPayment.Ref), pPayment.Ref, pPayment.GetNewObjectRef()));
	If vChequeAttributes = Undefined Then
		Raise NStr("en='No cheque was processed by POS!'; ru='Чек не пробивался по ККМ!'; de='Kein Kassenbon wurde von POS verarbeitet!'");
	EndIf;
	
	rPayerAddress = TrimAll(vChequeAttributes.BuyerAddress);
	rFiscalStorageFactoryNumber = TrimAll(vChequeAttributes.FiscalStorageFactoryNumber);
	rChequeFiscalNumber = TrimAll(vChequeAttributes.ChequeFiscalNumber);
	rCashDayChequeNumber = TrimAll(vChequeAttributes.CashDayChequeNumber);
	rChequeSequenceNumber = TrimAll(vChequeAttributes.ChequeSequenceNumber);
	
	rChequeVerificationAddress = TrimAll(pPayment.CashRegister.ChequeVerificationInternetAddress);
	rChequeVerificationAddress = StrReplace(rChequeVerificationAddress, "%ChequeFiscalNumber%", rChequeFiscalNumber);
	rChequeVerificationAddress = StrReplace(rChequeVerificationAddress, "%FiscalStorageFactoryNumber%", rFiscalStorageFactoryNumber);
	rChequeVerificationAddress = StrReplace(rChequeVerificationAddress, "%CashDayChequeNumber%", rCashDayChequeNumber);
	rChequeVerificationAddress = StrReplace(rChequeVerificationAddress, "%ChequeSequenceNumber%", rChequeSequenceNumber);
	rChequeVerificationAddress = StrReplace(rChequeVerificationAddress, "%ChequeAmount%", Format(vChequeAttributes.Sum, "NFD=2; NDS=.; NG="));
	
	vChequeText = "";
	
	vChequeText = vChequeText + cmNStr("en='CASH RECEIPT'; ru='КАССОВЫЙ ЧЕК'; de='KASSENBON'", vLanguage) + Chars.LF + Chars.LF;
	vChequeText = vChequeText + cmNStr("en='Cash day: '; ru='Номер смены: '; de='Kassentag: '", vLanguage) + Format(vChequeAttributes.CashDay, "NFD=; NG=") +  Chars.LF;
	vChequeText = vChequeText + cmNStr("en='Cash day cheque number: '; ru='Номер чека за смену: '; de='Kassentag Bon Nummer: '", vLanguage) + Format(vChequeAttributes.CashDayChequeNumber, "NFD=; NG=") + Chars.LF;
	vChequeText = vChequeText + cmNStr("en='Accounting type: '; ru='Признак расчета: '; de='Buchhaltungsart: '", vLanguage) + String(vChequeAttributes.ChequeAccountingType) + Chars.LF;
	vChequeText = vChequeText + cmNStr("en='Buyer address: '; ru='Адрес покупателя: '; de='Käufer Adresse: '", vLanguage) + TrimAll(vChequeAttributes.BuyerAddress) + Chars.LF + Chars.LF;
	
	vChequeText = vChequeText + cmNStr("en='NAME OF GOODS/SERVICES (REQUISITES)'; ru='НАИМЕНОВАНИЯ ТОВАРОВ/УСЛУГ (РЕКВИЗИТЫ)'; de='ARTIKELNAME (DETAILS)'", vLanguage) + Chars.LF + Chars.LF;
	
	If pPayment.PaymentSections.Count() > 0 Then
		For Each vPSRow In pPayment.PaymentSections Do
			If ValueIsFilled(vPSRow.ChequeService) Then
				vChequeText = vChequeText + cmNStr("en='Description: '; ru='Наименование: '; de='Artikelname: '", vLanguage) + TrimAll(vPSRow.ChequeService.Description) + Chars.LF;
				vChequeText = vChequeText + Chars.Tab + cmNStr("en='Price: '; ru='Цена за единицу: '; de='Preis: '", vLanguage) + cmFormatSum(vPSRow.ChequeServicePrice, pPayment.PaymentCurrency) + " x ";
				vChequeText = vChequeText + Chars.Tab + cmNStr("en='Quantity: '; ru='Количество: '; de='Anzhal: '", vLanguage) + Format(vPSRow.ChequeServiceQuantity, "NFD=3; NG=") + Chars.LF;
				vChequeText = vChequeText + Chars.Tab + Chars.Tab + " = " + cmNStr("en='Total amount: '; ru='Общая стоимость позиции с учетом скидок и наценок: '; de='Total Summe: '", vLanguage) + cmFormatSum(vPSRow.Sum, pPayment.PaymentCurrency) + Chars.LF;
			ElsIf ValueIsFilled(vPSRow.PaymentSection) Then
				vChequeText = vChequeText + cmNStr("en='Description: '; ru='Наименование: '; de='Artikelname: '", vLanguage) + TrimAll(vPSRow.PaymentSection.Description) + Chars.LF;
				vChequeText = vChequeText + Chars.Tab + cmNStr("en='Price: '; ru='Цена за единицу: '; de='Preis: '", vLanguage) + cmFormatSum(vPSRow.Sum, pPayment.PaymentCurrency) + " x ";
				vChequeText = vChequeText + Chars.Tab + cmNStr("en='Quantity: '; ru='Количество: '; de='Anzhal: '", vLanguage) + Format(1, "NFD=3; NG=") + Chars.LF;
				vChequeText = vChequeText + Chars.Tab + Chars.Tab + " = " + cmNStr("en='Total amount: '; ru='Общая стоимость позиции с учетом скидок и наценок: '; de='Total Summe: '", vLanguage) + cmFormatSum(vPSRow.Sum, pPayment.PaymentCurrency) + Chars.LF;
			Else
				vChequeText = vChequeText + cmNStr("en='Description: Advance'; ru='Наименование: Аванс'; de='Artikelname: Vorschuss'", vLanguage) + Chars.LF;
				vChequeText = vChequeText + Chars.Tab + cmNStr("en='Price: '; ru='Цена за единицу: '; de='Preis: '", vLanguage) + cmFormatSum(vPSRow.Sum, pPayment.PaymentCurrency) + " x ";
				vChequeText = vChequeText + Chars.Tab + cmNStr("en='Quantity: '; ru='Количество: '; de='Anzhal: '", vLanguage) + Format(1, "NFD=3; NG=") + Chars.LF;
				vChequeText = vChequeText + Chars.Tab + Chars.Tab + " = " + cmNStr("en='Total amount: '; ru='Общая стоимость позиции с учетом скидок и наценок: '; de='Total Summe: '", vLanguage) + cmFormatSum(vPSRow.Sum, pPayment.PaymentCurrency) + Chars.LF;
			EndIf;
			vChequeText = vChequeText + Chars.Tab + Chars.Tab + Chars.Tab + cmNStr("en='Item type: '; ru='Наименование предмета расчета: '; de='Itemtyp: '", vLanguage) + TrimAll(cmGetChequeItemType(pPayment, vPSRow.ChequeService, vPSRow.PaymentSection)) + Chars.LF;
			
			vChequeText = vChequeText + Chars.LF;
		EndDo;
	Else
		If ValueIsFilled(pPayment.PaymentSection) Then
			vChequeText = vChequeText + cmNStr("en='Description: '; ru='Наименование: '; de='Artikelname: '", vLanguage) + TrimAll(pPayment.PaymentSection.Description) + Chars.LF;
			vChequeText = vChequeText + Chars.Tab + cmNStr("en='Price: '; ru='Цена за единицу: '; de='Preis: '", vLanguage) + cmFormatSum(vChequeAttributes.Sum, pPayment.PaymentCurrency) + " x ";
			vChequeText = vChequeText + Chars.Tab + cmNStr("en='Quantity: '; ru='Количество: '; de='Anzhal: '", vLanguage) + Format(1, "NFD=3; NG=") + Chars.LF;
			vChequeText = vChequeText + Chars.Tab + Chars.Tab + " = " + cmNStr("en='Total amount: '; ru='Общая стоимость позиции с учетом скидок и наценок: '; de='Total Summe: '", vLanguage) + cmFormatSum(vChequeAttributes.Sum, pPayment.PaymentCurrency) + Chars.LF;
		Else
			vChequeText = vChequeText + cmNStr("en='Description: Hotel services'; ru='Наименование: Услуги гостиницы'; de='Artikelname: Hotel Dienstleistungen'", vLanguage) + Chars.LF;
			vChequeText = vChequeText + Chars.Tab + cmNStr("en='Price: '; ru='Цена за единицу: '; de='Preis: '", vLanguage) + cmFormatSum(vChequeAttributes.Sum, pPayment.PaymentCurrency) + " x ";
			vChequeText = vChequeText + Chars.Tab + cmNStr("en='Quantity: '; ru='Количество: '; de='Anzhal: '", vLanguage) + Format(1, "NFD=3; NG=") + Chars.LF;
			vChequeText = vChequeText + Chars.Tab + Chars.Tab + " = " + cmNStr("en='Total amount: '; ru='Общая стоимость позиции с учетом скидок и наценок: '; de='Total Summe: '", vLanguage) + cmFormatSum(vChequeAttributes.Sum, pPayment.PaymentCurrency) + Chars.LF;
		EndIf;
		
		vChequeText = vChequeText + Chars.LF;
	EndIf;
	
	vChequeText = vChequeText + cmNStr("en='CASHIER'; ru='КАССИР'; de='KASSIERER'", vLanguage) + Chars.LF + Chars.LF;
	
	vChequeText = vChequeText + cmNStr("en='Fiscal storage factory number: '; ru='Заводской номер фискального накопителя: '; de='Fiscal Speicher fabrik Nummer: '", vLanguage) + TrimAll(rFiscalStorageFactoryNumber) + Chars.LF;
	vChequeText = vChequeText + cmNStr("en='Cheque fiscal number: '; ru='Фискальный признак документа: '; de='Kassenbon fiscal Nummer: '", vLanguage) + TrimAll(rChequeFiscalNumber) + Chars.LF;
	vChequeText = vChequeText + cmNStr("en='Cheque sequence number: '; ru='Порядковый номер фискального документа: '; de='Kassenbon Sequenznummer: '", vLanguage) + TrimAll(vChequeAttributes.ChequeSequenceNumber) + Chars.LF;
	vChequeText = vChequeText + cmNStr("en='Cash register registration number: '; ru='Регистрационный номер ККТ: '; de='Kassen Registriernummer: '", vLanguage) + TrimAll(pPayment.CashRegister.RegistrationNumber) + Chars.LF;
	vChequeText = vChequeText + cmNStr("en='Payment method: '; ru='Форма расчета: '; de='Zahlungsmethode: '", vLanguage) + TrimAll(vChequeAttributes.PaymentMethod) + ": " + cmFormatSum(vChequeAttributes.Sum, pPayment.PaymentCurrency) + Chars.LF;
	vChequeText = vChequeText + cmNStr("en='Payment mode: '; ru='Способ расчета: '; de='Zahlungtyp: '", vLanguage) + TrimAll(cmGetChequePaymentMode(pPayment.PaymentMethod)) + Chars.LF;
	vChequeText = vChequeText + cmNStr("en='System of taxation: '; ru='Применяемая система налогообложения: '; de='Steuersystem: '", vLanguage) + TrimAll(vChequeAttributes.TaxationSystem) + Chars.LF;
	vChequeText = vChequeText + cmNStr("en='Cashier: '; ru='Кассир: '; de='Kassierer: '", vLanguage) + TrimAll(vChequeAttributes.CashierName) + Chars.LF;
	vChequeText = vChequeText + cmNStr("en='User TIN: '; ru='ИНН пользователя: '; de='Benutzer SIN: '", vLanguage) + TrimAll(vCompany.TIN) + Chars.LF;
	vChequeText = vChequeText + cmNStr("en='User name: '; ru='Наименование пользователя: '; de='Benutzer Name: '", vLanguage) + vCompany.GetObject().pmGetCompanyPrintName(vLanguage) + Chars.LF;
	vChequeText = vChequeText + cmNStr("en='User address: '; ru='Адрес расчетов: '; de='Benutzer Address: '", vLanguage) + vCompany.GetObject().pmGetCompanyPostAddressPresentation(vLanguage) + Chars.LF;
	vChequeText = vChequeText + cmNStr("en='User internet address: '; ru='Интернет адрес пользователя: '; de='Benutzer Internet-Address: '", vLanguage) + TrimAll(vCompany.WebAddress) + Chars.LF;
	vChequeText = vChequeText + cmNStr("en='Date, time: '; ru='Дата, время: '; de='Datum und Uhrzeit: '", vLanguage) + Format(vChequeAttributes.ChequeDateTime, "DF='dd.MM.yyyy HH:mm'") + Chars.LF;
	vChequeText = vChequeText + cmNStr("en='FDF Version: '; ru='Версия ФФД: '; de='FDF Version: '", vLanguage) + TrimAll(vChequeAttributes.FDFVersion) + Chars.LF + Chars.LF;
	
	If vChequeAttributes.VATSum1 <> 0 And ValueIsFilled(vChequeAttributes.VATRate1) Then
		vChequeText = vChequeText + cmNStr("en='Cheque VAT total for VAT rate '; ru='НДС итога чека с рассчитанной ставкой '; de='Kassenbon Summe für Mehrwertsteuersatz '", vLanguage) + TrimAll(vChequeAttributes.VATRate1) + ": " + cmFormatSum(vChequeAttributes.VATSum1, pPayment.PaymentCurrency) + Chars.LF;
	EndIf;
	If vChequeAttributes.VATSum2 <> 0 And ValueIsFilled(vChequeAttributes.VATRate2) Then
		vChequeText = vChequeText + cmNStr("en='Cheque VAT total for VAT rate '; ru='НДС итога чека с рассчитанной ставкой '; de='Kassenbon Summe für Mehrwertsteuersatz '", vLanguage) + TrimAll(vChequeAttributes.VATRate2) + ": " + cmFormatSum(vChequeAttributes.VATSum2, pPayment.PaymentCurrency) + Chars.LF;
	EndIf;
	If vChequeAttributes.VATSum3 <> 0 And ValueIsFilled(vChequeAttributes.VATRate3) Then
		vChequeText = vChequeText + cmNStr("en='Cheque VAT total for VAT rate '; ru='НДС итога чека с рассчитанной ставкой '; de='Kassenbon Summe für Mehrwertsteuersatz '", vLanguage) + TrimAll(vChequeAttributes.VATRate3) + ": " + cmFormatSum(vChequeAttributes.VATSum3, pPayment.PaymentCurrency) + Chars.LF;
	EndIf;
	If vChequeAttributes.VATSum4 <> 0 And ValueIsFilled(vChequeAttributes.VATRate4) Then
		vChequeText = vChequeText + cmNStr("en='Cheque VAT total for VAT rate '; ru='НДС итога чека с рассчитанной ставкой '; de='Kassenbon Summe für Mehrwertsteuersatz '", vLanguage) + TrimAll(vChequeAttributes.VATRate4) + ": " + cmFormatSum(vChequeAttributes.VATSum4, pPayment.PaymentCurrency) + Chars.LF;
	EndIf;
	If vChequeAttributes.VATSum5 <> 0 And ValueIsFilled(vChequeAttributes.VATRate5) Then
		vChequeText = vChequeText + cmNStr("en='Cheque VAT total for VAT rate '; ru='НДС итога чека с рассчитанной ставкой '; de='Kassenbon Summe für Mehrwertsteuersatz '", vLanguage) + TrimAll(vChequeAttributes.VATRate5) + ": " + cmFormatSum(vChequeAttributes.VATSum5, pPayment.PaymentCurrency) + Chars.LF;
	EndIf;
	If vChequeAttributes.VATSum6 <> 0 And ValueIsFilled(vChequeAttributes.VATRate6) Then
		vChequeText = vChequeText + cmNStr("en='Cheque VAT total for VAT rate '; ru='НДС итога чека с рассчитанной ставкой '; de='Kassenbon Summe für Mehrwertsteuersatz '", vLanguage) + TrimAll(vChequeAttributes.VATRate6) + ": " + cmFormatSum(vChequeAttributes.VATSum6, pPayment.PaymentCurrency) + Chars.LF;
	EndIf;
	
	vChequeText = vChequeText + Chars.LF + cmNStr("en='TOTAL: '; ru='ИТОГ: '; de='TOTAL: '", vLanguage) + cmFormatSum(vChequeAttributes.Sum, pPayment.PaymentCurrency) + Chars.LF;
	
	vChequeText = vChequeText + Chars.LF + cmNStr("en='Internet address for cheque verification: '; ru='Интернет-адрес для проверки чека: '; de='Die Internet-Adresse für die Kassenbon Überprüfung: '", vLanguage) + rChequeVerificationAddress;
	
	Return vChequeText;
EndFunction // BuildOnlineChequeText

// -----------------------------------------------------------------------------
//  Function builds online cheque text based on its attributes
//
// Parameters:
//  pPaymentRef	 - DocumentRef.Payment	 - Ref
// 
// Returns:
//  Structure - ChequeAttributes row
//
Function GetChequeAttributes(pPaymentRef) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ChequeAttributes.Hotel AS Hotel,
	|	ChequeAttributes.Payment AS Payment,
	|	ChequeAttributes.CashDay AS CashDay,
	|	ChequeAttributes.CashDayChequeNumber AS CashDayChequeNumber,
	|	ChequeAttributes.ChequeAccountingType AS ChequeAccountingType,
	|	ChequeAttributes.BuyerAddress AS BuyerAddress,
	|	ChequeAttributes.PaymentMethod AS PaymentMethod,
	|	ChequeAttributes.TaxationSystem AS TaxationSystem,
	|	ChequeAttributes.CashierName AS CashierName,
	|	ChequeAttributes.FiscalStorageFactoryNumber AS FiscalStorageFactoryNumber,
	|	ChequeAttributes.ChequeFiscalNumber AS ChequeFiscalNumber,
	|	ChequeAttributes.ChequeSequenceNumber AS ChequeSequenceNumber,
	|	ChequeAttributes.ChequeDateTime AS ChequeDateTime,
	|	ChequeAttributes.Sum AS Sum,
	|	ChequeAttributes.VATRate1 AS VATRate1,
	|	ChequeAttributes.VATSum1 AS VATSum1,
	|	ChequeAttributes.VATRate2 AS VATRate2,
	|	ChequeAttributes.VATSum2 AS VATSum2,
	|	ChequeAttributes.VATRate3 AS VATRate3,
	|	ChequeAttributes.VATSum3 AS VATSum3,
	|	ChequeAttributes.VATRate4 AS VATRate4,
	|	ChequeAttributes.VATSum4 AS VATSum4,
	|	ChequeAttributes.VATRate5 AS VATRate5,
	|	ChequeAttributes.VATSum5 AS VATSum5,
	|	ChequeAttributes.VATRate6 AS VATRate6,
	|	ChequeAttributes.VATSum6 AS VATSum6,
	|	ChequeAttributes.FDFVersion AS FDFVersion,
	|	ChequeAttributes.CorrectionType AS CorrectionType,
	|	ChequeAttributes.CorrectionDescription AS CorrectionDescription,
	|	ChequeAttributes.CorrectionDocumentNumber AS CorrectionDocumentNumber,
	|	ChequeAttributes.CorrectionDocumentDate AS CorrectionDocumentDate,
	|	ChequeAttributes.IsCorrection AS IsCorrection,
	|	ChequeAttributes.CashRegister AS CashRegister,
	|	ChequeAttributes.ExternalCode AS ExternalCode,
	|	ChequeAttributes.ReceiptUrl AS ReceiptUrl,
	|	ChequeAttributes.Remarks AS Remarks,
	|	ChequeAttributes.UUID AS UUID
	|FROM
	|	InformationRegister.ChequeAttributes AS ChequeAttributes
	|WHERE
	|	ChequeAttributes.Payment = &qPayment";
	vQry.SetParameter("qPayment", pPaymentRef);
	vRows = vQry.Execute().Unload();
	If vRows.Count() > 0 Then
		vRow = vRows.Get(0);
		vStruct = New Structure("Hotel, Payment, CashDay, CashDayChequeNumber, ChequeAccountingType, BuyerAddress, PaymentMethod, TaxationSystem, CashierName, FiscalStorageFactoryNumber, ChequeFiscalNumber, ChequeSequenceNumber, ChequeDateTime, 
		|Sum, VATRate1, VATSum1, VATRate2, VATSum2, VATRate3, VATSum3, VATRate4, VATSum4, VATRate5, VATSum5, VATRate6, VATSum6, 
		|FDFVersion, CorrectionType, CorrectionDescription, CorrectionDocumentNumber, CorrectionDocumentDate, IsCorrection, CashRegister, ExternalCode, ReceiptUrl, UUID, Remarks", 
		Undefined, Undefined, 0, 0, Undefined, "", "", Undefined, "", "", "", "", '00010101', 
		0, Undefined, 0, Undefined, 0, Undefined, 0, Undefined, 0, Undefined, 0, Undefined, 0,
		"", Undefined, "", "", '00010101', False, Undefined, "", "", Undefined, "");
		FillPropertyValues(vStruct, vRow);
		Return vStruct;
	Else
		Return Undefined;
	EndIf;
EndFunction // GetChequeAttributes

// -----------------------------------------------------------------------------
//  Creates online cheque and sends it to the payer
//
// Parameters:
//  pPaymentRef				 - DocumentRef.Payment	 - Ref
//  pDepartmentToSendError	 - CatalogRef.Departments	 - Ref
//
Procedure CreateAndSendOnlineCheque(pPaymentRef, pDepartmentToSendError = Undefined) Export
	vError = False;
	
	vCancel = False;
	If Not ValueIsFilled(pPaymentRef.PaymentMethod) Then
		vCancel = True;
	EndIf;
	If Not pPaymentRef.PaymentMethod.BookByCashRegister Or Not pPaymentRef.PaymentMethod.PrintCheque Then
		vCancel = True;
	EndIf;
	If Not ValueIsFilled(pPaymentRef.CashRegister) Then
		vCancel = True;
	EndIf;
	If Not pPaymentRef.CashRegister.IsControlledByProgram Then
		vCancel = True;
	EndIf;
	If pPaymentRef.Sum = 0 Then
		vCancel = True;
	EndIf;
	
	If vCancel Then
		Return;
	EndIf;	    
	
	// Get cash register driver data processor object
	vCashRegisterProcessor = cmGetCashRegisterDataProcessor(pPaymentRef.CashRegister);
	
	// Check if it is possible to print cheque
	vMessage = "";   
	vFuncNameLog = NStr("en='Document.Payment';ru='Документ.Платеж';de='Document.Payment'");  
	Try
		If Not vCashRegisterProcessor.pmIsReadyToPrint(vMessage) Then
			vError = True;
			WriteLogEvent(vFuncNameLog, EventLogLevel.Warning, pPaymentRef.Metadata(), pPaymentRef.Ref, vMessage);
		Else
			If Not vCashRegisterProcessor.pmPrintCheque(pPaymentRef.Sum, pPaymentRef.VATSum, pPaymentRef.GetObject(), vMessage) Then
				vError = True;
				WriteLogEvent(vFuncNameLog, EventLogLevel.Warning, pPaymentRef.Metadata(), pPaymentRef.Ref, vMessage);
			EndIf;
		EndIf;
		
		If Not vError Then
			If Not pPaymentRef.CashRegister.DoNotAutomaticallySendChequesByEmail Then
				If Not cmSendOnlineCheque(pPaymentRef, "", vMessage) Then
					vError = True;
					WriteLogEvent(vFuncNameLog, EventLogLevel.Warning, pPaymentRef.Metadata(), pPaymentRef.Ref, vMessage);
				EndIf;
			EndIf;
		EndIf;
		
		If vError And ValueIsFilled(pDepartmentToSendError) And StrFind(Lower(vMessage), " windows") = 0 Then   
			Try
				cmSendMessageToDepartment(pDepartmentToSendError, vMessage, , True, pPaymentRef.GuestGroup, True);
			Except       
				vErrInfo = ErrorInfo();
				WriteLogEvent(vFuncNameLog, EventLogLevel.Error, pPaymentRef.Metadata(), pPaymentRef.Ref, ErrorProcessing.DetailErrorDescription(vErrInfo));
			EndTry;
		EndIf;  
	Except        
		vErrInfo = ErrorInfo();
		WriteLogEvent("CreateAndSendOnlineCheque", EventLogLevel.Error, pPaymentRef.Metadata(), pPaymentRef.Ref, ErrorProcessing.DetailErrorDescription(vErrInfo));
	EndTry;
EndProcedure // CreateAndSendOnlineCheque

// -----------------------------------------------------------------------------
//  Sends online cheque to the payer
//
// Parameters:
//  pPaymentRef		 - DocumentRef.Payment	 - Ref
//  pPayerAddress	 - String				 - PayerAddress
//  rMessage		 - String				 - Error message
// 
// Returns:
//  Boolean - Has errors
//
Function SendOnlineCheque(pPaymentRef, pPayerAddress = "", rMessage) Export
	rMessage = "";
	
	Try
		vLanguage = pPaymentRef.Hotel.Language;
		If ValueIsFilled(pPaymentRef.Payer) And ValueIsFilled(pPaymentRef.Payer.Language) Then
			vLanguage = pPaymentRef.Payer.Language;
		EndIf;
		
		vPayerAddress = "";
		vFiscalStorageFactoryNumber = "";
		vChequeFiscalNumber = "";
		vChequeVerificationAddress = "";
		vChequeSequenceNumber = "";
		vCashDayChequeNumber = "";
		
		// Build cheque text
		vChequeText = cmBuildOnlineChequeText(pPaymentRef, vPayerAddress, vFiscalStorageFactoryNumber, vChequeFiscalNumber, vChequeVerificationAddress, vChequeSequenceNumber, vCashDayChequeNumber);
		
		If Not IsBlankString(pPayerAddress) Then
			vPayerAddress = pPayerAddress;
		EndIf;
		
		// Get payer address
		If StrFind(vPayerAddress, "@") > 0 Then
			vSubject = cmNStr("en = 'Cheque '; de = 'Kassenbon '; ru = 'Кассовый чек '", vLanguage) + vFiscalStorageFactoryNumber + ":" + vChequeFiscalNumber;
			JobsScheduled.cmSendTextByEMail(vSubject, vChequeText, vPayerAddress, Undefined, rMessage, Undefined, True, "");
		ElsIf cmIsNumber(vPayerAddress) Then
			SMS.SendMessage(vChequeVerificationAddress, vPayerAddress, , , pPaymentRef.Payer, pPaymentRef.ParentDoc, SessionParameters.CurrentUser, Undefined, rMessage);
		EndIf;
	Except          
		vErrInfo = ErrorInfo();
		rMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo());  
		WriteLogEvent("SendOnlineCheque", EventLogLevel.Error, , pPaymentRef, ErrorProcessing.DetailErrorDescription(vErrInfo));
	EndTry;
	
	Return IsBlankString(rMessage);
EndFunction // SendOnlineCheque

// -----------------------------------------------------------------------------
//  Checks if input email should be transfered to the OFD. Returns True if Yes and False if Not.
//
// Parameters:
//  pEMail	 - String	 - EMail address
// 
// Returns:
//  Boolean - EMail in blacklist
//
Function CheckEMailsBlackList(pEMail) Export
	Return Not cmCheckIfEMailIsInBlackList(pEMail);
EndFunction // CheckEMailsBlackList

// -----------------------------------------------------------------------------
//
// Parameters:
//  pText	 - String	 - Text
// 
// Returns:
//  Array - Text lines as array
//
Function GetTextLinesArray(pText) Export
	Return cmGetTextLinesArray(pText);
EndFunction // GetTextLinesArray

// -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel	 - CatalogRef.Hotels - Ref
// 
// Returns:
//  String - Hotel description
//
Function GetHotelPrintName(pHotel) Export
	Return Catalogs.Hotels.pmGetHotelPrintName(pHotel, SessionParameters.CurrentLanguage);
EndFunction // GetHotelPrintName

// -----------------------------------------------------------------------------
//
// Parameters:
//  pAmountIn	 - Number	 - Amount
//  pQuantityIn	 - Number	 - QuantityIn
//  pNumDigits	 - Number	 - NumDigits
//  rPriceOut	 - Number	 - PriceOut
//  rQuantityOut - Number	 - QuantityOut
//
Procedure ChequeItemAttributesCorrection(Val pAmountIn, Val pQuantityIn, Val pNumDigits, rPriceOut, rQuantityOut) Export
	If pAmountIn = 0 Or pQuantityIn = 0 Then
		Return;
	EndIf;
	vAttempts = 1;
	vShift = 0.1;
	For vInd = 2 To pNumDigits Do
		vShift = vShift * 0.1;
		vAttempts = vAttempts * 10;
	EndDo;
	rQuantityOut = Round(pQuantityIn, pNumDigits);
	rPriceOut = Round(pAmountIn / rQuantityOut, 2);
	vFactor = 0;
	vQuantityOut = rQuantityOut;
	While Round(rPriceOut * vQuantityOut, 2) <> pAmountIn Do
		vQuantityOut = rQuantityOut + vShift * vFactor;
		vPriceOut = Round(pAmountIn / vQuantityOut, 2);
		If Round(vPriceOut * vQuantityOut, 2) = pAmountIn Then
			rPriceOut = vPriceOut;
			rQuantityOut = vQuantityOut;
			Break;
		EndIf;
		vQuantityOut = rQuantityOut - vShift * vFactor;
		vPriceOut = Round(pAmountIn / vQuantityOut, 2);
		If Round(vPriceOut * vQuantityOut, 2) = pAmountIn Then
			rPriceOut = vPriceOut;
			rQuantityOut = vQuantityOut;
			Break;
		EndIf;
		vFactor = vFactor + 1;
		If vFactor > vAttempts Then
			Break;
		EndIf;
	EndDo;
EndProcedure // ChequeItemAttributesCorrection

// -----------------------------------------------------------------------------
//
// Parameters:
//  pCode	 - String	 - Code
// 
// Returns:
//  Array - Base64ItemCode
//
Function GetBase64ItemCode(pCode) Export
	If IsBlankString(pCode) Then
		Return pCode;
	EndIf;
	vBinaryArray = New Array();
	If cmIsNumber(pCode) And StrLen(pCode) = 8 Then
		// EAN-8 (UPC-E)
		vBinaryArray.Add(GetBinaryDataFromHexString("4508"));
	ElsIf cmIsNumber(pCode) And StrLen(pCode) = 13 Then
		// EAN-13 (UPC-A)
		vBinaryArray.Add(GetBinaryDataFromHexString("450D"));
	ElsIf cmIsNumber(pCode) And StrLen(pCode) = 14 Then
		// ITF-14
		vBinaryArray.Add(GetBinaryDataFromHexString("490E"));
	Else
		// Undecoded
		vBinaryArray.Add(GetBinaryDataFromHexString("0000"));
	EndIf;
	// Add code
	vBinaryArray.Add(GetBinaryDataFromString(pCode));
	// Concatinate binary values and return base64 string from it
	Return Base64String(ConcatBinaryData(vBinaryArray));
EndFunction // GetBase64ItemCode

// -----------------------------------------------------------------------------
//
// Parameters:
//  pCode	 - String	 - Code 
// 
// Returns:
//  String - HexCode
//
Function GetHexItemCode(pCode) Export
	vHexCode = "";
	If cmIsNumber(pCode) And StrLen(pCode) = 8 Then
		// EAN-8 (UPC-E)
		vHexCode = "4508";
	ElsIf cmIsNumber(pCode) And StrLen(pCode) = 13 Then
		// EAN-13 (UPC-A)
		vHexCode = "450D";
	ElsIf cmIsNumber(pCode) And StrLen(pCode) = 14 Then
		// ITF-14
		vHexCode = "490E";
	Else
		// Undecoded
		vHexCode = "0000";
	EndIf;
	// Add code
	vHexCode = vHexCode + GetHexStringFromBinaryData(GetBinaryDataFromString(pCode));
	// Concatinate binary values and return base64 string from it
	Return vHexCode;
EndFunction // GetHexItemCode

// -----------------------------------------------------------------------------
//
// Parameters:
//  pAuthor	 - CatalogRef.Employees - Ref
// 
// Returns:
//  String - Cashier name
//
Function GetCashierName(pAuthor) Export 
	vCashierName = "";
	If ValueIsFilled(pAuthor) Then
		vLastName = TrimAll(pAuthor.LastName);
		vDescriptionTranslations = TrimAll(pAuthor.DescriptionTranslations);
		If Not IsBlankString(vLastName) Then
			vFirstName = TrimAll(pAuthor.FirstName);
			vSecondName = TrimAll(pAuthor.SecondName);
			vCashierName = vCashierName + vLastName + ?(Not IsBlankString(vFirstName), " " + Upper(Left(vFirstName, 1)) + ".", "") + ?(Not IsBlankString(vSecondName), " " + Upper(Left(vSecondName, 1)) + ".", "");	
		ElsIf Not IsBlankString(vDescriptionTranslations) Then
			vCashierName = vCashierName + tcOnServer.cmNStrAtServer(vDescriptionTranslations);
		Else
			vCashierName = vCashierName + TrimAll(pAuthor.Description);
		EndIf;
		vCashierPosition = tcOnServer.cmNStrAtServer(pAuthor.Position);
		If Not IsBlankString(vCashierPosition) Then
			vCashierName = vCashierName + ", " + vCashierPosition;
		EndIf;
	EndIf;
	Return Left(vCashierName, 64);
EndFunction // GetCashierName

// --------------------------------------------------------------------------------
Function GetChargesWithMarkingCode(pFolio) Export
	vCharges = New Map;
	vQ = New Query;
	vQ.Text =
	"SELECT
	|	Charge.MarkingCode AS MarkingCode,
	|	Charge.MarkingCodeCheckUUID AS MarkingCodeCheckUUID,
	|	Charge.MarkingCodeCheckDate AS MarkingCodeCheckDate
	|FROM
	|	Document.Charge AS Charge
	|		LEFT JOIN Document.Storno AS Storno
	|		ON Charge.Ref = Storno.ParentCharge
	|WHERE
	|	ISNULL(Storno.DeletionMark, TRUE)
	|	AND Charge.Posted
	|	AND Charge.Folio = &qFolio
	|	AND Charge.MarkingCode <> """"";
	vQ.SetParameter("qFolio", pFolio);
	vSelect = vQ.Execute().Select();
	While vSelect.Next() Do
		vCharge = New Map;
		vCharge.Insert("MarkingCode", vSelect.MarkingCode);
		vCharge.Insert("MarkingCodeCheckUUID", vSelect.MarkingCodeCheckUUID);
		vCharge.Insert("MarkingCodeCheckDate", vSelect.MarkingCodeCheckDate);
		
		vCharges.Insert(vSelect.MarkingCode, vCharge);
	EndDo;
	Return vCharges;
EndFunction // GetChargesWithMarkingCode

// --------------------------------------------------------------------------------
//
// Parameters:
//  pService - CatalogRef.Services	 - Service
// 
// Returns:
//  Boolean - Result
//
Function CheckMarkingCodeByType(pService, pMarkingCodeType) Export
	If Not ValueIsFilled(pService) Then
		Return False;
	EndIf;
	
	If pService.UseMarking And (pService.MarkingCodeType = pMarkingCodeType Or (Not ValueIsFilled(pService.MarkingCodeType) And pMarkingCodeType = Enums.MarkingCodeTypes.HonestMark)) Then
		Return True;
	EndIf;
	
	Return False;
EndFunction // CheckMarkingCodeType

// --------------------------------------------------------------------------------
//
// Parameters:
//  pVATRate - CatalogRef.VATRates	 - VAT rate reference
//  pDate	 - Date					 - VAT rate parameters active for the given date
// 
// Returns:
//  Structure - Structure with TaxRate, TaxGroup, NoVAT, Description properties
//
Function GetVATRateParams(pVATRate, pDate) Export
	vParamsStruct = Undefined;
	If ValueIsFilled(pVATRate) Then
		vParamsStruct = New Structure("TaxRate, TaxGroup, NoVAT, Description", pVATRate.TaxRate, pVATRate.TaxGroup, pVATRate.NoVAT, pVATRate.Description);
		vParams = cmGetVATRateParams(pVATRate, pDate);
		If vParams <> Undefined Then
			FillPropertyValues(vParamsStruct, vParams);
		EndIf;
	EndIf;
	Return vParamsStruct;
EndFunction // GetVATRateParams

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
//
// Parameters:
//  pFolio	 - DocumentRef.Folio - Ref
//  pRef	 - DocumentRef	 -  Ref
// 
// Returns:
//  ValueTable - Settlement payments
//
Function GetFolioAdvanceSettlementPayments(pFolio, pRef = Undefined)
	vQry = New Query();    
	vQry.Text = 
	"SELECT
	|	AdvanceSettlements.PaymentRef AS PaymentRef,
	|	SUM(AdvanceSettlements.Sum) AS Sum
	|FROM
	|	(SELECT
	|		AdvanceSettlementPayments.Ref AS PaymentRef,
	|		1 AS Sum
	|	FROM
	|		Document.Payment AS AdvanceSettlementPayments
	|	WHERE
	|		AdvanceSettlementPayments.Folio = &qFolio
	|		AND AdvanceSettlementPayments.PaymentMethod = &qPaymentMethod
	|		AND AdvanceSettlementPayments.Posted
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AdvanceSettlementReturns.Payment,
	|		-1
	|	FROM
	|		Document.Return AS AdvanceSettlementReturns
	|	WHERE
	|		AdvanceSettlementReturns.Folio = &qFolio
	|		AND AdvanceSettlementReturns.PaymentMethod = &qPaymentMethod
	|		AND AdvanceSettlementReturns.Posted
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		NormalPayments.Ref,
	|		NormalPayments.Sum
	|	FROM
	|		Document.Payment AS NormalPayments
	|	WHERE
	|		NormalPayments.Folio = &qFolio
	|		AND NormalPayments.PaymentMethod <> &qPaymentMethod
	|		AND ISNULL(NormalPayments.PaymentSection.ChequeItemType, VALUE(Enum.ChequeItemTypes.EmptyRef)) <> VALUE(Enum.ChequeItemTypes.Payment)
	|		AND NOT NormalPayments.Hotel.UsePrepaymentsIfPossible
	|		AND NormalPayments.Posted
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		NormalReturns.Payment,
	|		-NormalReturns.Sum
	|	FROM
	|		Document.Return AS NormalReturns
	|	WHERE
	|		NormalReturns.Folio = &qFolio
	|		AND NormalReturns.PaymentMethod <> &qPaymentMethod
	|		AND ISNULL(NormalReturns.PaymentSection.ChequeItemType, VALUE(Enum.ChequeItemTypes.EmptyRef)) <> VALUE(Enum.ChequeItemTypes.Payment)
	|		AND NOT NormalReturns.Hotel.UsePrepaymentsIfPossible
	|		AND NormalReturns.Posted
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		NormalPrepayments.Ref,
	|		NormalPrepayments.Ref.Sum
	|	FROM
	|		Document.Payment.PaymentSections AS NormalPrepayments
	|	WHERE
	|		NormalPrepayments.Ref.Folio = &qFolio
	|		AND NormalPrepayments.Ref.PaymentMethod <> &qPaymentMethod
	|		AND ISNULL(NormalPrepayments.PaymentSection.ChequeItemType, VALUE(Enum.ChequeItemTypes.EmptyRef)) <> VALUE(Enum.ChequeItemTypes.Payment)
	|		AND NormalPrepayments.Ref.Hotel.UsePrepaymentsIfPossible
	|		AND NormalPrepayments.Ref.Posted
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		NormalPerpaymentReturns.Ref.Payment,
	|		-NormalPerpaymentReturns.Ref.Sum
	|	FROM
	|		Document.Return.PaymentSections AS NormalPerpaymentReturns
	|	WHERE
	|		NormalPerpaymentReturns.Ref.Folio = &qFolio
	|		AND NormalPerpaymentReturns.Ref.PaymentMethod <> &qPaymentMethod
	|		AND ISNULL(NormalPerpaymentReturns.PaymentSection.ChequeItemType, VALUE(Enum.ChequeItemTypes.EmptyRef)) <> VALUE(Enum.ChequeItemTypes.Payment)
	|		AND NormalPerpaymentReturns.Ref.Hotel.UsePrepaymentsIfPossible
	|		AND NormalPerpaymentReturns.Ref.Posted
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DepositTransfers.Ref,
	|		DepositTransfers.SumInFolioToCurrency
	|	FROM
	|		Document.DepositTransfer AS DepositTransfers
	|	WHERE
	|		DepositTransfers.FolioTo = &qFolio
	|		AND ISNULL(DepositTransfers.PaymentSection.ChequeItemType, VALUE(Enum.ChequeItemTypes.EmptyRef)) <> VALUE(Enum.ChequeItemTypes.Payment)
	|		AND DepositTransfers.Posted
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DepositTransfers.Ref,
	|		-DepositTransfers.SumInFolioFromCurrency
	|	FROM
	|		Document.DepositTransfer AS DepositTransfers
	|	WHERE
	|		DepositTransfers.FolioFrom = &qFolio
	|		AND ISNULL(DepositTransfers.PaymentSection.ChequeItemType, VALUE(Enum.ChequeItemTypes.EmptyRef)) <> VALUE(Enum.ChequeItemTypes.Payment)
	|		AND DepositTransfers.Posted) AS AdvanceSettlements
	|WHERE
	|	(&qRefIsFilled
	|				AND AdvanceSettlements.PaymentRef <> &qRef
	|			OR NOT &qRefIsFilled)
	|
	|GROUP BY
	|	AdvanceSettlements.PaymentRef
	|
	|HAVING
	|	SUM(AdvanceSettlements.Sum) <> 0";
	vQry.SetParameter("qFolio", pFolio);
	vQry.SetParameter("qRef", pRef);
	vQry.SetParameter("qRefIsFilled", ValueIsFilled(pRef));
	vQry.SetParameter("qPaymentMethod", Catalogs.PaymentMethods.AdvanceSettlement);
	vDocs = vQry.Execute().Unload();
	Return vDocs;
EndFunction // GetFolioAdvanceSettlementPayments

// -----------------------------------------------------------------------------
//
// Parameters:
//  pFolio	 - DocumentRef.Folio - Ref
//  pRef	 - DocumentRef	 -  Ref
// 
// Returns:
//  ValueTable - Folio payments
//
Function GetFolioPayments(pFolio, pRef = Undefined)
	vQry = New Query();    
	vQry.Text = 
	"SELECT
	|	AllPayments.PaymentRef AS PaymentRef,
	|	SUM(AllPayments.Sum) AS Sum
	|FROM
	|	(SELECT
	|		Payments.Ref AS PaymentRef,
	|		Payments.SumInFolioCurrency AS Sum
	|	FROM
	|		Document.Payment AS Payments
	|	WHERE
	|		Payments.Folio = &qFolio
	|		AND Payments.Posted
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Returns.Payment,
	|		-Returns.SumInFolioCurrency
	|	FROM
	|		Document.Return AS Returns
	|	WHERE
	|		Returns.Folio = &qFolio
	|		AND Returns.Posted
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DepositTransfers.Ref,
	|		DepositTransfers.SumInFolioToCurrency
	|	FROM
	|		Document.DepositTransfer AS DepositTransfers
	|	WHERE
	|		DepositTransfers.FolioTo = &qFolio
	|		AND DepositTransfers.Posted
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DepositTransfers.Ref,
	|		-DepositTransfers.SumInFolioFromCurrency
	|	FROM
	|		Document.DepositTransfer AS DepositTransfers
	|	WHERE
	|		DepositTransfers.FolioFrom = &qFolio
	|		AND DepositTransfers.Posted) AS AllPayments
	|WHERE
	|	(&qRefIsFilled
	|				AND AllPayments.PaymentRef <> &qRef
	|			OR NOT &qRefIsFilled)
	|
	|GROUP BY
	|	AllPayments.PaymentRef
	|
	|HAVING
	|	SUM(AllPayments.Sum) <> 0";
	vQry.SetParameter("qFolio", pFolio);
	vQry.SetParameter("qRef", pRef);
	vQry.SetParameter("qRefIsFilled", ValueIsFilled(pRef));
	vDocs = vQry.Execute().Unload();
	Return vDocs;
EndFunction // GetFolioPayments

#EndRegion
