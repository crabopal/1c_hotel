
#Region Public

// -----------------------------------------------------------------------------
Function pmPrintCheque(Val pSum, Val pVATSum, pObj, pObjRef, rMessage, pPasswordKKM="", pServices = Undefined, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101', pSendPayerContactsToOFD = 0, pEmailToSendToOFD = "", pPhoneToSendToOFD = "") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pObj.CashRegister);
	vArrPaymentMethod = tcOnServer.cmGetAtributeAsArray(pObj.PaymentMethod);
	vIsPrepayment = False;
	
	// Try to connect
	vFR = Connect(rMessage,vArrCashRegister,pPasswordKKM);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Check if paper is present
			If Not CheckPaper(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage) Then
				Disconnect(vFR);
				Return False;
			EndIf;
			
			// Close open cheque if any
			CloseOpenCheque(vFR, vArrCashRegister);
			
			If Not FillAdditionalAttributes(vFR, pObj, vArrCashRegister) Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			
			// Open session if is closed
			If vArrCashRegister.DoNotOpenNewSessionAfterZReport Then
				If vFR.ECRMode = 4 Then
					SetTimeZone(vFR, vArrCashRegister);
					vFR.FNBeginOpenSession();
					// Set cashier name
					vCashier = tcOnServer.cmGetCurrentUserAttribute();
					If ValueIsFilled(vCashier) Then
						vCashierName = tcCashRegisters.GetCashierName(vCashier);
						If Not IsBlankString(vCashierName) Then
							vFR.TagNumber = 1021;
							vFR.TagType = 7;
							vFR.TagValueStr = vCashierName;
							vFR.FNSendTag();
							
							// Set TIN
							vEmployeeTIN = TrimAll(tcOnServer.cmGetAttributeByRef(vCashier, "TIN"));
							If Not IsBlankString(vEmployeeTIN) Then
								vFR.TagNumber = 1203;
								vFR.TagType = 7;
								vFR.TagValueStr	= vEmployeeTIN;
								vFR.FNSendTag();
							EndIf;
						EndIf;
					EndIf;
					// Open session
					vFR.OpenSession();
					If Not CheckResultCode(vFR.ResultCode) Then
						ProcessResultCode(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
						Return False;
					Else
						tcOnServer.Wait(5);
					EndIf;
				EndIf;
			EndIf;
			
			vIsPayment = False;
			
			// Extra functions for extensions
			If Not pmPrintCheque_BeforeOpenCheque(vFR, vArrCashRegister, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD) Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			
			// Open cheque
			If pIsCorrection And vArrCashRegister.FiscalDataFormatVersions <> PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2") Then
				If TypeOf(pObjRef) = Type("DocumentRef.Return") Then
					vFR.CalculationSign = 3;
				Else
					vFR.CalculationSign = 1;
					vIsPayment = True;
				EndIf;
				vFR.FNBeginCorrectionReceipt();
			Else
				If TypeOf(pObjRef) = Type("DocumentRef.Return") Then
					vFR.CheckType = 2;
				Else
					vFR.CheckType = 0;
					vIsPayment = True;
				EndIf;
				If ValueIsFilled(pObj.PaymentMethod) And tcOnServer.cmGetAttributeByRef(pObj.PaymentMethod, "ElectronicChequeOnly") Then
					// Do not print cheque on paper
					vFR.TableNumber			= 17;
					vFR.FieldNumber			= 7;
					vFR.ValueOfFieldInteger = 1;
					vFR.WriteTable();
				EndIf;
				
				If pIsCorrection Then
					vFR.FNOpenCheckCorrection();
				Else
					vFR.OpenCheck();
				EndIf;
			EndIf;
			
			// Initialize cheque attributes used to send online cheque by sms or e-mail
			vChequeAttributes = tcCashRegisters.InitializeChequeAttributes(pObj, pObjRef, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate);
			
			// Set correction type
			vChequeAttributes.IsCorrection = pIsCorrection;
			If pIsCorrection Then
				// Correction type
				If pCorrectionType = PredefinedValue("Enum.CorrectionChequeTypes.ByOrder") Then
					vFR.CorrectionType = 1;
				Else
					vFR.CorrectionType = 0;
				EndIf;
				vChequeAttributes.CorrectionType = pCorrectionType;
				
				// Fill remarks, order date and number
				vCorrectionDocumentDate = ?(ValueIsFilled(pCorrectionDocumentDate), BegOfDay(pCorrectionDocumentDate), ?(pObj.CorrectionOfIncorrectCheque And ValueIsFilled(pObj.Payment), tcOnServer.cmGetAttributeByRef(pObj.Payment, "Date"), '00010101'));
				If ValueIsFilled(vCorrectionDocumentDate) Then
					vFR.TagNumber = 1178;
					vFR.TagType = 6;
					vFR.TagValueDateTime = vCorrectionDocumentDate;
					vFR.FNSendTag();
					vChequeAttributes.CorrectionDocumentDate = vCorrectionDocumentDate;
				Else
					rMessage = NStr("en='The date of the corrected payment is not specified (the date when the wrong cheque was posted)!'; 
					|ru='Не указана дата совершения корректируемого расчета (дата, когда пробит неверный чек)!'; 
					|de='Das Datum der korrigierten Zahlung ist nicht angegeben (das Datum, an dem der falsche Scheck gebucht wurde)!'");
					Return False;
				EndIf;
				
				vCorrectionDocumentNumber = TrimAll(TrimAll(pCorrectionDescription) + ?(IsBlankString(pCorrectionDocumentNumber), "", " №" + TrimAll(pCorrectionDocumentNumber)));
				vFR.TagNumber = 1179;
				vFR.TagType = 7;
				vFR.TagValueStr = vCorrectionDocumentNumber;
				vFR.FNSendTag();
				vChequeAttributes.CorrectionDocumentNumber = vCorrectionDocumentNumber;
			EndIf;
			
			// Print FPD of the base cheque if return
			If pObj.CorrectionOfIncorrectCheque Then
				vPayment = pObj.Payment;
				If ValueIsFilled(vPayment) Then
					// Get payment cheque attributes
					vPaymentAttrs = tcCashRegisters.GetChequeAttributes(vPayment);
					If vPaymentAttrs <> Undefined And Not IsBlankString(vPaymentAttrs.ChequeFiscalNumber) Then
						vFR.TagNumber = 1192;
						vFR.TagType = 7;
						vFR.TagValueStr = TrimAll(vPaymentAttrs.ChequeFiscalNumber);
						vFR.FNSendTag();
					EndIf;
				EndIf;
			EndIf;
			
			If vFR.ECRSoftDate > Date(2025, 8, 1) Then
				If vArrPaymentMethod.IsViaInternetAcquiring Then
					vFR.TagNumber = 1125;
					vFR.TagType = 0;
					vFR.TagValueInt = 1;
					vFR.FNSendTag();
					
					vHotelSite = "";
					If Not IsBlankString(vArrCashRegister.PaymentAddress) Then
						vHotelSite = TrimAll(vArrCashRegister.PaymentAddress);
					EndIf;
					
					If IsBlankString(vHotelSite) And ValueIsFilled(pObj.Hotel) Then
						vHotelSite = tcOnServer.cmGetAttributeByRef(pObj.Hotel, "Site");
					EndIf;
					
					If IsBlankString(vHotelSite) Then
						rMessage = NStr("en = 'The hotel website is not specified in the hotel settings (required to specify the payment location in the check)'; de = 'Die Hotelwebsite ist in den Hoteleinstellungen nicht angegeben (erforderlich, um den Zahlungsort im Scheck anzugeben)'; ru = 'В настройка гостинцы не указан сайт отеля (требуется для указания места расчёта в чеке)'");
						Disconnect(vFR);
						Return False;
					EndIf;
					
					vFR.TagNumber = 1187;
					vFR.TagType = 7;
					vFR.TagValueStr = vHotelSite;
					vFR.FNSendTag();
				Else
					vFR.TagNumber = 1125;
					vFR.TagType = 0;
					vFR.TagValueInt = 0;
					vFR.FNSendTag();
				EndIf;
			EndIf;
			
			If pSendPayerContactsToOFD = 0 Then
				// Transfer client e-mail
				vEMail = "";
				If ValueIsFilled(TrimAll(pEmailToSendToOFD)) Then
					vEMail = TrimAll(pEmailToSendToOFD);	
				Else
					vPayer = Undefined;
					If (TypeOf(pObj.Ref) = Type("DocumentRef.Payment") Or TypeOf(pObj.Ref) = Type("DocumentRef.Return")) Then
						If ValueIsFilled(pObj.Payer) Then
							vPayer = pObj.Payer;
						EndIf;
					ElsIf TypeOf(pObj.Ref) = Type("DocumentRef.CustomerPayment") Then
						If ValueIsFilled(pObj.AccountingCustomer) Then
							vPayer = pObj.AccountingCustomer;
						EndIf;	
					EndIf;
					If ValueIsFilled(vPayer) Then
						If TypeOf(vPayer) = Type("CatalogRef.Clients") Or TypeOf(vPayer) = Type("CatalogRef.Customers") Then
							vEMail = TrimAll(tcOnServer.cmGetAttributeByRef(vPayer, "EMail"));
						EndIf;
					EndIf;
				EndIf;
				If ValueIsFilled(vEMail) And tcCommonFunctionOnClientServer.CheckEmail(vEMail, , False) And tcCashRegisters.CheckEMailsBlackList(vEMail) Then
					vFR.CustomerEmail = vEMail;
					vFR.FNSendCustomerEmail();
					vChequeAttributes.BuyerAddress = vEMail;
				EndIf;
			ElsIf pSendPayerContactsToOFD = 1 Then
				// Transfer client Phone
				vPhone = "";
				If ValueIsFilled(TrimAll(pPhoneToSendToOFD)) Then
					vPhone = TrimAll(pPhoneToSendToOFD);
				Else
					vPayer = Undefined;
					If (TypeOf(pObj.Ref) = Type("DocumentRef.Payment") Or TypeOf(pObj.Ref) = Type("DocumentRef.Return")) Then
						If ValueIsFilled(pObj.Payer) Then
							vPayer = pObj.Payer;
						EndIf;
					ElsIf TypeOf(pObj.Ref) = Type("DocumentRef.CustomerPayment") Then
						If ValueIsFilled(pObj.AccountingCustomer) Then
							vPayer = pObj.AccountingCustomer;
						EndIf;	
					EndIf;
					If ValueIsFilled(vPayer) Then
						If TypeOf(vPayer) = Type("CatalogRef.Clients") Or TypeOf(vPayer) = Type("CatalogRef.Customers") Then
							vPhone = TrimAll(tcOnServer.cmGetAttributeByRef(vPayer, "Phone"));
						EndIf;
					EndIf;
				EndIf;
				vPhone = TrimAll(SMS.GetValidPhoneNumber(vPhone));
				If Left(vPhone, 1) <> "+" Then
					vPhone = "+" + vPhone;	
				EndIf;
				If ValueIsFilled(vPhone) Then
					vFR.CustomerEmail = SMS.GetPhoneNumberWithCountryCode(vPhone);
					vFR.FNSendCustomerEmail();
					vChequeAttributes.BuyerAddress = vPhone;
				EndIf;
			EndIf;
			
			// Set taxation system
			vTaxSystem = Undefined;
			vTaxSystemCode = GetTaxationSystemCode(pObj, vTaxSystem);
			If vTaxSystemCode > 0 Then
				vFR.TaxType = vTaxSystemCode;
				vChequeAttributes.TaxationSystem = vTaxSystem;
			EndIf;
			
			// Set cashier name
			vCashier = pObj.Author;
			If ValueIsFilled(vCashier) Then
				vCashierName = tcCashRegisters.GetCashierName(vCashier);
				If Not IsBlankString(vCashierName) Then
					vFR.TagNumber = 1021;
					vFR.TagType = 7;
					vFR.TagValueStr = vCashierName;
					vFR.FNSendTag();
					vChequeAttributes.CashierName = vCashierName;
					
					// Set TIN
					vEmployeeTIN = TrimAll(tcOnServer.cmGetAttributeByRef(vCashier, "TIN"));
					If Not IsBlankString(vEmployeeTIN) Then
						vFR.TagNumber = 1203;
						vFR.TagType = 7;
						vFR.TagValueStr = vEmployeeTIN;
						vFR.FNSendTag();
					EndIf;
				EndIf;
			EndIf;
			
			// Payer name and TIN
			vPayerName = "";
			vPayerTIN = "";
			tcOnServer.GetPayerNameAndTIN(pObj.AccountingCustomer, vPayerName, vPayerTIN);
			If Not IsBlankString(vPayerTIN) And Not IsBlankString(vPayerName) Then
				If vArrCashRegister.FiscalDataFormatVersions = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2") Then
					vFR.TagNumber = 1256;
					vFR.FNBeginSTLVTag();
					vTagID = vFR.TagID;
					
					vFR.TagID = vTagID;
					vFR.TagNumber = 1227;
					vFR.TagType = 7;
					vFR.TagValueStr = vPayerName;
					vFR.FNAddTag();
					
					vFR.TagID = vTagID;
					vFR.TagNumber = 1228;
					vFR.TagType = 7;
					vFR.TagValueStr = vPayerTIN;
					vFR.FNAddTag(); 
					
					vFR.FNSendSTLVTag();
				Else
					vFR.TagNumber = 1227;
					vFR.TagType = 7;
					vFR.TagValueStr = vPayerName;
					vFR.FNSendTag();
					
					vFR.TagNumber = 1228;
					vFR.TagType = 7;
					vFR.TagValueStr = vPayerTIN;
					vFR.FNSendTag();
				EndIf;
			EndIf;
			
			// Print cheque
			vFR.UseJournalRibbon = 1;
			vFR.UseReceiptRibbon = 1;
			
			vFR.Tax1 = 0; vFR.Tax2 = 0; vFR.Tax3 = 0; vFR.Tax4 = 0;
			vFR.Summ1 = 0; vFR.Summ2 = 0; vFR.Summ3 = 0; vFR.Summ4 = 0; vFR.Summ5 = 0; vFR.Summ6 = 0; vFR.Summ7 = 0; vFR.Summ8 = 0; vFR.Summ9 = 0; vFR.Summ10 = 0; vFR.Summ11 = 0; vFR.Summ12 = 0; vFR.Summ13 = 0; vFR.Summ14 = 0; vFR.Summ15 = 0; vFR.Summ16 = 0;
			
			// Print slip if payment was made by credit card
			If vArrCashRegister.PrintSlipInCheque Then
				If Not IsBlankString(pObj.SlipText) Then
					PrintSlipLines(vFR, tcOnServer.GetTextLinesArray(pObj.SlipText), vArrCashRegister);
					// Print cheque header
					vFR.PrintHeader();
					If Not CheckResultCode(vFR.ResultCode) Then
						ProcessResultCode(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
						Return False;
					EndIf;
				EndIf;
			EndIf;
			
			// Cheque folio header
			If vArrCashRegister.PrintFolioHeader Then
				PrintFolioHeader(vFR, pObj, vArrCashRegister);
			EndIf;
			
			vChargesWithMarkingCode = tcCashRegisters.GetChargesWithMarkingCode(pObj.Folio);
			
			// Extra functions for extensions
			If Not pmPrintCheque_AfterOpenCheque(vFR, vArrCashRegister, vChargesWithMarkingCode, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD) Then
				CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			
			// Print services
			If Not pIsCorrection Or pIsCorrection And vArrCashRegister.FiscalDataFormatVersions <> PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_0_5") Then
				If Not vArrCashRegister.DoNotPrintKioskServices AND pServices <> Undefined And pServices.Count() > 0 Then
					For Each vSrvRow In pServices Do
						// Operation type
						vFR.CheckType = 1;
						
						// Department and cheque postion
						vPaymentSection = Undefined;
						vFR.Department = 0;
						vFR.StringForPrinting = "";
						If ValueIsFilled(vSrvRow.Service) Then
							vService = vSrvRow.Service;
							vFR.StringForPrinting = GetString(tcOnServer.cmGetServiceDescription(vService), vArrCashRegister);
							vPaymentSection = tcOnServer.cmGetAttributeByRef(vService, "PaymentSection");
							If ValueIsFilled(vPaymentSection) Then
								vFR.Department = tcOnServer.cmGetAttributeByRef(vPaymentSection, "Code");
							EndIf;
						EndIf;
						
						// Cheque position extra attributes
						// Payment item sign
						vItemTypeRef = tcCashRegisters.GetChequeItemType(pObj, vSrvRow.Service, vPaymentSection);
						vItemType = tcCashRegisters.GetChequeItemTypeValue(vItemTypeRef);
						vFR.PaymentItemSign = vItemType;
						
						// Payment type sign
						vPaymentModeRef = tcCashRegisters.GetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection);
						vPaymentMode = tcCashRegisters.GetChequePaymentModeTypeValue(vPaymentModeRef);
						vFR.PaymentTypeSign = vPaymentMode;
						
						// Add tax
						vVATRate = Undefined;
						If ValueIsFilled(vPaymentSection) And ValueIsFilled(tcOnServer.cmGetAttributeByRef(vPaymentSection, "VATRate")) Then
							vFR.Tax1 = GetTaxGroup(vPaymentSection, vVATRate, vSrvRow.VATRate, pObj);
						Else
							vFR.Tax1 = GetTaxGroup(pObj, vVATRate, vSrvRow.VATRate, pObj);
						EndIf;
						If TypeOf(pObj.Ref) = Type("DocumentRef.Return") Then
							vVATSum = tcOnServer.CalculateVATSum(vVATRAte, vSrvRow.Amount, ?(ValueIsFilled(pObj.Payment), tcOnServer.cmGetAttributeByRef(pObj.Payment, "Date"), pObj.Date));
						Else
							vVATSum = tcOnServer.CalculateVATSum(vVATRAte, vSrvRow.Amount, pObj.Date);
						EndIf;
						vFR.TaxValue = vVATSum;
						vFR["TaxValue"+vFR.Tax1] = vVATSum;
						vFR.TaxValueEnabled = True;
						tcCashRegisters.SetChequeVATAmount(vChequeAttributes, vVATRAte, vVATSum);
						
						// Do sale
						vFR.Summ1 = vSrvRow.Amount;
						vFR.Summ1Enabled = True;
						vItemPrice = vSrvRow.Price;
						vItemQuantity = vSrvRow.Quantity;
						tcCashRegisters.ChequeItemAttributesCorrection(vFR.Summ1, vItemQuantity, 6, vItemPrice, vItemQuantity);
						vFR.Price = vItemPrice;
						vFR.Quantity = vItemQuantity;
						If vArrCashRegister.FiscalDataFormatVersions = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2") Then
							vFR.MeasureUnit = GetUnitPiece(vSrvRow.Service);
						EndIf;
						
						// Extra functions for extensions
						If Not pmPrintCheque_BeforeChequePositionRegistration(vFR, vArrCashRegister, vChargesWithMarkingCode, vSrvRow, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD) Then
							CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
							Return False;
						EndIf;
						
						vFR.FNOperation();
						If Not CheckResultCode(vFR.ResultCode) Then
							CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
							Return False;
						EndIf;
						
						If ValueIsFilled(vSrvRow.Service) Then
							vChequeServiceAttr = tcOnServer.cmGetAtributeAsArray(vSrvRow.Service);
							// Commissioner mark
							vPrincipal = vChequeServiceAttr.Principal;
							vIsAgentService = vChequeServiceAttr.IsAgentService;
							If vIsAgentService Then
								// Commissioner attribute
								vFR.TagNumber = 1222;
								vFR.TagType = 0; // Int
								If vChequeServiceAttr.PrincipalType = 1 Then
									vFR.TagValueInt = 64; // 64 - other agent
								Else
									vFR.TagValueInt = 32; // 32 - Commission agent
								EndIf;
								vFR.FNSendTagOperation();
								// Principal
								If ValueIsFilled(vPrincipal) Then
									vPrincipalAttr = tcOnServer.cmGetAtributeAsArray(vPrincipal);
									vPrincipalTIN = TrimAll(vPrincipalAttr.TIN);
									vPrincipalName = TrimAll(vPrincipalAttr.LegacyName);
									vPrincipalPhone = TrimAll(vPrincipalAttr.Phone);
									// STLV 1223
									vFR.TagID = 0;
									vFR.TagNumber = 1223;
									vFR.FNBeginSTLVTag();
									vFR.FNSendSTLVTagOperation();
									// Commissioner TIN
									If Not IsBlankString(vPrincipalTIN) Then
										vFR.TagNumber = 1226;
										vFR.TagType = 7;
										vFR.TagValueStr = vPrincipalTIN;
										vFR.FNSendTagOperation();
										vFR.StringForPrinting = "";
									EndIf;
									If Not IsBlankString(vPrincipalName) And Not IsBlankString(vPrincipalPhone) Then
										vFR.TagID = 0;
										vFR.TagNumber = 1224;
										vFR.FNBeginSTLVTag();
										// Principal phone
										vFR.TagNumber = 1171;
										vFR.TagType = 7;
										vFR.TagValueStr = SMS.GetPhoneNumberWithCountryCode(vPrincipalPhone);
										vFR.FNAddTag();
										// Principal name
										vFR.TagNumber = 1225;
										vFR.TagType = 7;
										vFR.TagValueStr = vPrincipalName;
										vFR.FNAddTag();
										// Send STLV tag
										vFR.FNSendSTLVTagOperation();
									EndIf;
								EndIf;
							EndIf;
							vIsHonestMark = tcCashRegisters.CheckMarkingCodeByType(vSrvRow.Service, PredefinedValue("Enum.MarkingCodeTypes.HonestMark"));
							// Labeled goods
							If Not IsBlankString(vSrvRow.MarkingCode) And vIsHonestMark Then
								SetIndustryInfo(vFR, vIsPayment, vPaymentMode, vChargesWithMarkingCode, vSrvRow.MarkingCode);
								If Not CheckMarkingCode(vFR, TypeOf(pObj.Ref) = Type("DocumentRef.Payment"), vSrvRow.Service, vSrvRow.MarkingCode, vArrCashRegister.CancelReceiptPrintingWhenMarkingCheckError, rMessage) Then
									CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
									Return False;
								EndIf;
								
								vFR.BarCode = GetStringFromBinaryData(Base64Value(vSrvRow.MarkingCode));
								vFR.FNSendItemBarcode();
							Else
								// Item code
								vCashRegisterItemCode = TrimAll(vChequeServiceAttr.CashRegisterItemCode);
								If Not IsBlankString(vCashRegisterItemCode) Then
									If vArrCashRegister.FiscalDataFormatVersions = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2") Then
										vFR.BarCode = vCashRegisterItemCode;
										vFR.FNSendItemBarcode();
									Else
										vFR.MarkingType = 17677; //EAN-13
										vFR.BarCode = vCashRegisterItemCode;
										vFR.FNSendItemCodeData(); 
									EndIf;
								EndIf;  
							EndIf;
							// Excise
							If vItemType = 2 Or vItemType = 30 Or vItemType = 31 Then
								vExciseAmount = tcCashRegisters.GetChequeItemExciseValue(vChequeServiceAttr.ExciseDutyType, pObj.Date, vChequeServiceAttr.Volume, vItemQuantity);
								If vExciseAmount <> 0 Then
									vFR.TagNumber = 1229;
									vFR.TagType = 3;
									vFR.TagValueLength = 6;
									vFR.TagValueVLN = Format(vExciseAmount * 100, "NFD=0; NZ=; NG=");
									vFR.FNSendTagOperation();
								EndIf;
							EndIf;
						EndIf;
						
						// Extra functions for extensions
						If Not pmPrintCheque_AfterChequePositionRegistration(vFR, vArrCashRegister, vChargesWithMarkingCode, vSrvRow, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD) Then
							CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
							Return False;
						EndIf;
					EndDo;
				Else
					// Print number and sections
					If pObj.PaymentSections.Count() > 0 Then
						If Not vArrCashRegister.PrintFolioHeader Then
							vFR.StringForPrinting = "#" + TrimAll(pObj.Number);
							vFR.PrintString();
							If Not CheckResultCode(vFR.ResultCode) Then
								CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
								Return False;
							EndIf;
						EndIf;
						
						vPSRows = tcCashRegisters.GetPrintableChequePositions(pObj, vIsPrepayment, vArrCashRegister.AlwaysUseAveragePrice);
						
						If vArrCashRegister.PrintPaymentSectionNamesInCheques Then
							pSum = 0;
							For Each vPSRow In vPSRows Do
								If vPSRow.Sum = 0 Then
									Continue;
								ElsIf vPSRow.Sum < 0 Then
									Continue;
								Else
									pSum = pSum + vPSRow.Sum;
								EndIf;
								vSectionAmount = vPSRow.Sum;
								If TypeOf(pObj.Ref) = Type("DocumentRef.Return") Then
									vSectionAmount = -vSectionAmount;
								EndIf;
								
								// Operation type
								If vSectionAmount < 0 Then
									vFR.CheckType = 2;
								Else
									vFR.CheckType = 1;
								EndIf;
								
								// Department and cheque postion
								vFR.Department = 0;
								vPaymentSection = Undefined;
								vFR.StringForPrinting = NStr("en='Hotel services'; de='Hotel Dienstleistungen'; ru='Гостиничные услуги'");
								If ValueIsFilled(vPSRow.Item) Then
									vPaymentSection = vPSRow.PaymentSection;
									If ValueIsFilled(vPaymentSection) Then
										vFR.Department = tcOnServer.cmGetAttributeByRef(vPaymentSection, "Code");
									EndIf;
									vFR.StringForPrinting = GetString(tcOnServer.cmGetOrderItemDescription(vPSRow.Item), vArrCashRegister);
								ElsIf ValueIsFilled(vPSRow.ChequeService) Then
									vPaymentSection = vPSRow.PaymentSection;
									If ValueIsFilled(vPaymentSection) Then
										vFR.Department = tcOnServer.cmGetAttributeByRef(vPaymentSection, "Code");
									EndIf;
									vFR.StringForPrinting = GetString(tcOnServer.cmGetServiceDescription(vPSRow.ChequeService), vArrCashRegister);
								ElsIf ValueIsFilled(vPSRow.PaymentSection) Then
									vPaymentSection = vPSRow.PaymentSection;
									vFR.Department = tcOnServer.cmGetAttributeByRef(vPaymentSection, "Code");
									vFR.StringForPrinting = GetString(tcOnServer.cmGetPaymentSectionDescription(vPaymentSection), vArrCashRegister);
								Else
									If vSectionAmount >=0 Then
										vFR.StringForPrinting = GetString(NStr("en='Hotel services'; de='Hoteldienstleistungen'; ru='Гостиничные услуги'"), vArrCashRegister);
									Else
										vFR.StringForPrinting = GetString(NStr("en='Refund for hotel services'; de='Rückreise für Hoteldienstleistungen'; ru='Возврат за гостиничные услуги'"), vArrCashRegister);
									EndIf;
								EndIf;
								
								// Cheque position extra attributes
								// Payment item sign
								vItemTypeRef = tcCashRegisters.GetChequeItemType(pObj, vPSRow.ChequeService, vPaymentSection, vIsPrepayment);
								vItemType = tcCashRegisters.GetChequeItemTypeValue(vItemTypeRef);
								vFR.PaymentItemSign = vItemType;
								
								// Payment type sign
								vPaymentModeRef = tcCashRegisters.GetChequePaymentMode(pObj.PaymentMethod, ?(ValueIsFilled(pObj.PaymentSection), pObj.PaymentSection, vPaymentSection), vIsPrepayment);
								vPaymentMode = tcCashRegisters.GetChequePaymentModeTypeValue(vPaymentModeRef);
								vFR.PaymentTypeSign = vPaymentMode;
								
								// Add tax
								vVATRate = Undefined;
								vVATSum = 0;
								If ValueIsFilled(vPaymentSection) And ValueIsFilled(tcOnServer.cmGetAttributeByRef(vPaymentSection, "VATRate")) Then
									vFR.Tax1 = GetTaxGroup(vPaymentSection, vVATRate, vPSRow.VATRate, pObj);
								Else
									vFR.Tax1 = GetTaxGroup(pObj, vVATRate, vPSRow.VATRate, pObj);
								EndIf;
								vVATSum = vPSRow.VATSum;
								vFR.TaxValue = vVATSum;
								vFR["TaxValue"+vFR.Tax1] = vVATSum;
								vFR.TaxValueEnabled = True;
								tcCashRegisters.SetChequeVATAmount(vChequeAttributes, vVATRAte, vVATSum);
								
								// Do sale
								If vSectionAmount >= 0 Then
									vFR.Summ1 = vSectionAmount;
								Else
									vFR.Summ1 = -vSectionAmount;
								EndIf;
								vFR.Summ1Enabled = True;
								vItemPrice = 0;
								vItemQuantity = 0;
								If ValueIsFilled(vPSRow.ChequeService) Then
									If vPSRow.ChequeServiceQuantity <> 0 Then
										vItemQuantity = vPSRow.ChequeServiceQuantity;
										vItemQuantity = ?(vItemQuantity < 0, -vItemQuantity, vItemQuantity);
									Else
										vItemQuantity = 1;
									EndIf;
									vItemPrice = Round(vFR.Summ1 / vItemQuantity, 2);
								Else
									vItemQuantity = 1;
									vItemPrice = vFR.Summ1;
								EndIf;
								tcCashRegisters.ChequeItemAttributesCorrection(vFR.Summ1, vItemQuantity, 6, vItemPrice, vItemQuantity);
								vFR.Price = vItemPrice;
								vFR.Quantity = vItemQuantity; 
								If vArrCashRegister.FiscalDataFormatVersions = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2") Then
									vFR.MeasureUnit = GetUnitPiece(vPSRow.ChequeService);
								EndIf;
								
								// Extra functions for extensions
								If Not pmPrintCheque_BeforeChequePositionRegistration(vFR, vArrCashRegister, vChargesWithMarkingCode, vPSRow, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD) Then
									CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
									Return False;
								EndIf;
								
								vFR.FNOperation();
								If Not CheckResultCode(vFR.ResultCode) Then
									CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
									Return False;
								EndIf;	
								
								If ValueIsFilled(vPSRow.ChequeService) Then
									vChequeServiceAttr = tcOnServer.cmGetAtributeAsArray(vPSRow.ChequeService);
									// Commissioner mark
									vIsAgentService = vChequeServiceAttr.IsAgentService;
									If vIsAgentService Then
										// Commissioner attribute
										vFR.TagNumber = 1222;
										vFR.TagType = 0; // Int
										If vChequeServiceAttr.PrincipalType = 1 Then
											vFR.TagValueInt = 64; // 64 - other agent
										Else
											vFR.TagValueInt = 32; // 32 - Commission agent
										EndIf;
										vFR.FNSendTagOperation();
										// Principal
										vPrincipal = vChequeServiceAttr.Principal;
										If ValueIsFilled(vPrincipal) Then
											vPrincipalAttr = tcOnServer.cmGetAtributeAsArray(vPrincipal);
											vPrincipalTIN = TrimAll(vPrincipalAttr.TIN);
											vPrincipalName = TrimAll(vPrincipalAttr.LegacyName);
											vPrincipalPhone = TrimAll(vPrincipalAttr.Phone);
											// STLV 1223
											vFR.TagID = 0;
											vFR.TagNumber = 1223;
											vFR.FNBeginSTLVTag();
											vFR.FNSendSTLVTagOperation();
											// Commissioner TIN
											If Not IsBlankString(vPrincipalTIN) Then
												vFR.TagNumber = 1226;
												vFR.TagType = 7;
												vFR.TagValueStr = vPrincipalTIN;
												vFR.FNSendTagOperation();
											EndIf;
											If Not IsBlankString(vPrincipalName) And Not IsBlankString(vPrincipalPhone) Then
												vFR.TagID = 0;
												vFR.TagNumber = 1224;
												vFR.FNBeginSTLVTag();
												// Principal name
												vFR.TagNumber = 1225;
												vFR.TagType = 7;
												vFR.TagValueStr = vPrincipalName;
												vFR.FNAddTag();
												// Principal phone
												vFR.TagNumber = 1171;
												vFR.TagType = 7;
												vFR.TagValueStr = SMS.GetPhoneNumberWithCountryCode(vPrincipalPhone);
												vFR.FNAddTag();
												// Send STLV tag
												vFR.FNSendSTLVTagOperation();
											EndIf;
										EndIf;
									EndIf;
									vIsHonestMark = tcCashRegisters.CheckMarkingCodeByType(vPSRow.ChequeService, PredefinedValue("Enum.MarkingCodeTypes.HonestMark"));
									// Labeled goods
									If Not IsBlankString(vPSRow.MarkingCode) And vIsHonestMark Then
										SetIndustryInfo(vFR, vIsPayment, vPaymentMode, vChargesWithMarkingCode, vPSRow.MarkingCode);
										If Not CheckMarkingCode(vFR, TypeOf(pObj.Ref) = Type("DocumentRef.Payment"), vPSRow.ChequeService, vPSRow.MarkingCode, vArrCashRegister.CancelReceiptPrintingWhenMarkingCheckError, rMessage) Then
											CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
											Return False;
										EndIf;
										
										vFR.BarCode = GetStringFromBinaryData(Base64Value(vPSRow.MarkingCode));
										vFR.FNSendItemBarcode();
									Else
										// Item code
										vCashRegisterItemCode = TrimAll(vChequeServiceAttr.CashRegisterItemCode);
										If Not IsBlankString(vCashRegisterItemCode) Then 
											If vArrCashRegister.FiscalDataFormatVersions = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2") Then
												vFR.BarCode = vCashRegisterItemCode;
												vFR.FNSendItemBarcode();
											Else
												vFR.MarkingType = 17677; //EAN-13
												vFR.BarCode = vCashRegisterItemCode;
												vFR.FNSendItemCodeData(); 
											EndIf;
										EndIf;
									EndIf;
									// Excise
									If vItemType = 2 Or vItemType = 30 Or vItemType = 31 Then
										vExciseAmount = tcCashRegisters.GetChequeItemExciseValue(vChequeServiceAttr.ExciseDutyType, pObj.Date, vChequeServiceAttr.Volume, vItemQuantity);
										If vExciseAmount <> 0 Then
											vFR.TagNumber = 1229;
											vFR.TagType = 3;
											vFR.TagValueLength = 6;
											vFR.TagValueVLN = Format(vExciseAmount * 100, "NFD=0; NZ=; NG=");
											vFR.FNSendTagOperation();
										EndIf;
									EndIf;
								EndIf;
								
								// Extra functions for extensions
								If Not pmPrintCheque_AfterChequePositionRegistration(vFR, vArrCashRegister, vChargesWithMarkingCode, vPSRow, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD) Then
									CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
									Return False;
								EndIf;
							EndDo;
						ElsIf Not vArrCashRegister.DoNotPrintPaymentSections Then
							pSum = 0;
							For Each vPSRow In vPSRows Do
								If vPSRow.Sum = 0 Then
									Continue;
								ElsIf vPSRow.Sum < 0 Then
									Continue;
								Else
									pSum = pSum + vPSRow.Sum;
								EndIf;
								vSectionAmount = vPSRow.Sum;
								If TypeOf(pObj.Ref) = Type("DocumentRef.Return") Then
									vSectionAmount = -vSectionAmount;
								EndIf;
								
								// Operation type
								If vSectionAmount < 0 Then
									vFR.CheckType = 2;
								Else
									vFR.CheckType = 1;
								EndIf;
								
								// Department and cheque postion
								vPaymentSection = vPSRow.PaymentSection;
								vFR.Department = 0;
								vFR.StringForPrinting = "";
								If ValueIsFilled(vPSRow.Item) Then
									vPaymentSection = vPSRow.PaymentSection;
									If ValueIsFilled(vPaymentSection) Then
										vFR.Department = tcOnServer.cmGetAttributeByRef(vPaymentSection, "Code");
									EndIf;
									vFR.StringForPrinting = GetString(tcOnServer.cmGetOrderItemDescription(vPSRow.Item), vArrCashRegister);
								ElsIf ValueIsFilled(vPSRow.ChequeService) Then
									vPaymentSection = vPSRow.PaymentSection;
									If ValueIsFilled(vPaymentSection) Then
										vFR.Department = tcOnServer.cmGetAttributeByRef(vPaymentSection, "Code");
									EndIf;
									vFR.StringForPrinting = GetString(tcOnServer.cmGetServiceDescription(vPSRow.ChequeService), vArrCashRegister);
								ElsIf ValueIsFilled(vPaymentSection) Then
									vFR.Department = tcOnServer.cmGetAttributeByRef(vPaymentSection, "Code");
									vFR.StringForPrinting = GetString(TrimAll(vFR.Department), vArrCashRegister);
								Else
									If vSectionAmount >=0 Then
										vFR.StringForPrinting = GetString(NStr("en='Hotel services'; de='Hoteldienstleistungen'; ru='Гостиничные услуги'"), vArrCashRegister);
									Else
										vFR.StringForPrinting = GetString(NStr("en='Refund for hotel services'; de='Rückreise für Hoteldienstleistungen'; ru='Возврат за гостиничные услуги'"), vArrCashRegister);
									EndIf;
								EndIf;
								
								// Cheque position extra attributes
								// Payment item sign
								vItemTypeRef = tcCashRegisters.GetChequeItemType(pObj, vPSRow.ChequeService, vPaymentSection, vIsPrepayment);
								vItemType = tcCashRegisters.GetChequeItemTypeValue(vItemTypeRef);
								vFR.PaymentItemSign = vItemType;
								
								// Payment type sign
								vPaymentModeRef = tcCashRegisters.GetChequePaymentMode(pObj.PaymentMethod, ?(ValueIsFilled(pObj.PaymentSection), pObj.PaymentSection, vPaymentSection), vIsPrepayment);
								vPaymentMode = tcCashRegisters.GetChequePaymentModeTypeValue(vPaymentModeRef);
								vFR.PaymentTypeSign = vPaymentMode;
								
								// Add tax
								vVATRate = Undefined;
								vVATSum = 0;
								If ValueIsFilled(vPaymentSection) And ValueIsFilled(tcOnServer.cmGetAttributeByRef(vPaymentSection, "VATRate")) Then
									vFR.Tax1 = GetTaxGroup(vPaymentSection, vVATRate, vPSRow.VATRate, pObj);
								Else
									vFR.Tax1 = GetTaxGroup(pObj, vVATRate, vPSRow.VATRate, pObj);
								EndIf;
								vVATSum = vPSRow.VATSum;
								vFR.TaxValue = vVATSum;
								vFR["TaxValue"+vFR.Tax1] = vVATSum;
								vFR.TaxValueEnabled = True;
								tcCashRegisters.SetChequeVATAmount(vChequeAttributes, vVATRAte, vVATSum);
								
								// Do sale
								If vSectionAmount >= 0 Then
									vFR.Summ1 = vSectionAmount;
								Else
									vFR.Summ1 = -vSectionAmount;
								EndIf;
								vFR.Summ1Enabled = True;
								vItemPrice = 0;
								vItemQuantity = 0;
								If ValueIsFilled(vPSRow.ChequeService) Then
									If vPSRow.ChequeServiceQuantity <> 0 Then
										vItemQuantity = vPSRow.ChequeServiceQuantity;
										vItemQuantity = ?(vItemQuantity < 0, -vItemQuantity, vItemQuantity);
									Else
										vItemQuantity = 1;
									EndIf;
									vItemPrice = Round(vFR.Summ1 / vItemQuantity, 2);
								Else
									vItemQuantity = 1;
									vItemPrice = vFR.Summ1;
								EndIf;
								tcCashRegisters.ChequeItemAttributesCorrection(vFR.Summ1, vItemQuantity, 6, vItemPrice, vItemQuantity);
								vFR.Price = vItemPrice;
								vFR.Quantity = vItemQuantity;  
								If vArrCashRegister.FiscalDataFormatVersions = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2") Then
									vFR.MeasureUnit = GetUnitPiece(vPSRow.ChequeService);
								EndIf;
								
								// Extra functions for extensions
								If Not pmPrintCheque_BeforeChequePositionRegistration(vFR, vArrCashRegister, vChargesWithMarkingCode, vPSRow, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD) Then
									CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
									Return False;
								EndIf;
								
								vFR.FNOperation();
								If Not CheckResultCode(vFR.ResultCode) Then
									CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
									Return False;
								EndIf;
								
								If ValueIsFilled(vPSRow.ChequeService) Then
									vChequeServiceAttr = tcOnServer.cmGetAtributeAsArray(vPSRow.ChequeService);
									// Commissioner mark
									vIsAgentService = vChequeServiceAttr.IsAgentService;
									If vIsAgentService Then
										// Commissioner attribute
										vFR.TagNumber = 1222;
										vFR.TagType = 0; // Int
										If vChequeServiceAttr.PrincipalType = 1 Then
											vFR.TagValueInt = 64; // 64 - other agent
										Else
											vFR.TagValueInt = 32; // 32 - Commission agent
										EndIf;
										vFR.FNSendTagOperation();
										// Principal
										vPrincipal = vChequeServiceAttr.Principal;
										If ValueIsFilled(vPrincipal) Then
											vPrincipalAttr = tcOnServer.cmGetAtributeAsArray(vPrincipal);
											vPrincipalTIN = TrimAll(vPrincipalAttr.TIN);
											vPrincipalName = TrimAll(vPrincipalAttr.LegacyName);
											vPrincipalPhone = TrimAll(vPrincipalAttr.Phone);
											// STLV 1223
											vFR.TagID = 0;
											vFR.TagNumber = 1223;
											vFR.FNBeginSTLVTag();
											vFR.FNSendSTLVTagOperation();
											// Commissioner TIN
											If Not IsBlankString(vPrincipalTIN) Then
												vFR.TagNumber = 1226;
												vFR.TagType = 7;
												vFR.TagValueStr = vPrincipalTIN;
												vFR.FNSendTagOperation();
											EndIf;
											If Not IsBlankString(vPrincipalName) And Not IsBlankString(vPrincipalPhone) Then
												vFR.TagID = 0;
												vFR.TagNumber = 1224;
												vFR.FNBeginSTLVTag();
												// Principal name
												vFR.TagNumber = 1225;
												vFR.TagType = 7;
												vFR.TagValueStr = vPrincipalName;
												vFR.FNAddTag();
												// Principal phone
												vFR.TagNumber = 1171;
												vFR.TagType = 7;
												vFR.TagValueStr = SMS.GetPhoneNumberWithCountryCode(vPrincipalPhone);
												vFR.FNAddTag();
												// Send STLV tag
												vFR.FNSendSTLVTagOperation();
											EndIf;
										EndIf;
									EndIf;
									vIsHonestMark = tcCashRegisters.CheckMarkingCodeByType(vPSRow.ChequeService, PredefinedValue("Enum.MarkingCodeTypes.HonestMark"));
									// Labeled goods
									If Not IsBlankString(vPSRow.MarkingCode) And vIsHonestMark Then
										SetIndustryInfo(vFR, vIsPayment, vPaymentMode, vChargesWithMarkingCode, vPSRow.MarkingCode);
										If Not CheckMarkingCode(vFR, TypeOf(pObj.Ref) = Type("DocumentRef.Payment"), vPSRow.ChequeService, vPSRow.MarkingCode, vArrCashRegister.CancelReceiptPrintingWhenMarkingCheckError, rMessage) Then
											CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
											Return False;
										EndIf;
										
										vFR.BarCode = GetStringFromBinaryData(Base64Value(vPSRow.MarkingCode));
										vFR.FNSendItemBarcode();
									Else
										// Item code
										vCashRegisterItemCode = TrimAll(vChequeServiceAttr.CashRegisterItemCode);
										If Not IsBlankString(vCashRegisterItemCode) Then 
											If vArrCashRegister.FiscalDataFormatVersions = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2") Then
												vFR.BarCode = vCashRegisterItemCode;
												vFR.FNSendItemBarcode();
											Else
												vFR.MarkingType = 17677; //EAN-13
												vFR.BarCode = vCashRegisterItemCode;
												vFR.FNSendItemCodeData(); 
											EndIf;
										EndIf;
									EndIf;
									// Excise
									If vItemType = 2 Or vItemType = 30 Or vItemType = 31 Then
										vExciseAmount = tcCashRegisters.GetChequeItemExciseValue(vChequeServiceAttr.ExciseDutyType, pObj.Date, vChequeServiceAttr.Volume, vItemQuantity);
										If vExciseAmount <> 0 Then
											vFR.TagNumber = 1229;
											vFR.TagType = 3;
											vFR.TagValueLength = 6;
											vFR.TagValueVLN = Format(vExciseAmount * 100, "NFD=0; NZ=; NG=");
											vFR.FNSendTagOperation();
										EndIf;
									EndIf;
								EndIf;
								
								// Extra functions for extensions
								If Not pmPrintCheque_AfterChequePositionRegistration(vFR, vArrCashRegister, vChargesWithMarkingCode, vPSRow, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD) Then
									CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
									Return False;
								EndIf;
							EndDo;
						Else
							vAmount = 0;
							vVATAmount = 0;
							pSum = 0;
							For Each vPSRow In vPSRows Do
								If vPSRow.Sum = 0 Then
									Continue;
								ElsIf vPSRow.Sum < 0 Then
									Continue;
								Else
									pSum = pSum + vPSRow.Sum;
								EndIf;
								If TypeOf(pObj.Ref) = Type("DocumentRef.Return") Then
									vAmount = vAmount - vPSRow.Sum;
								Else
									vAmount = vAmount + vPSRow.Sum;
								EndIf;
								vVATAmount = vVATAmount + vPSRow.VATSum;
							EndDo;
							
							// Operation type
							If vAmount < 0 Then
								vFR.CheckType = 2;
							Else
								vFR.CheckType = 1;
							EndIf;
							
							// Department and cheque postion
							vFR.Department = 0;
							vFR.StringForPrinting = NStr("en='Hotel services';ru='Услуги гостиницы';de='Hotel Dienstleistungen'");
							
							// Cheque position extra attributes
							// Payment item sign
							vItemType = tcCashRegisters.GetChequeItemTypeValue(tcCashRegisters.GetChequeItemType(pObj, Undefined, Undefined));
							vFR.PaymentItemSign = vItemType;
							
							// Payment type sign
							vPaymentModeRef = tcCashRegisters.GetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection);
							vPaymentMode = tcCashRegisters.GetChequePaymentModeTypeValue(vPaymentModeRef);
							vFR.PaymentTypeSign = vPaymentMode;
							
							// Add tax
							vVATRate = Undefined;
							vFR.Tax1 = GetTaxGroup(pObj, vVATRate, , pObj);
							vFR.TaxValue = vVATAmount;
							vFR["TaxValue"+vFR.Tax1] = vVATAmount;
							vFR.TaxValueEnabled = True;
							tcCashRegisters.SetChequeVATAmount(vChequeAttributes, vVATRAte, vVATAmount);
							
							// Do sale
							vFR.Quantity = 1;
							If vAmount >= 0 Then
								vFR.Summ1 = vAmount;
							Else
								vFR.Summ1 = -vAmount;
							EndIf;
							vFR.Price = vFR.Summ1;
							vFR.Summ1Enabled = True;
							If vArrCashRegister.FiscalDataFormatVersions = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2") Then
								vFR.MeasureUnit = GetUnitPiece(Undefined);
							EndIf;
							
							// Extra functions for extensions
							If Not pmPrintCheque_BeforeChequePositionRegistration(vFR, vArrCashRegister, vChargesWithMarkingCode, Undefined, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD) Then
								CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
								Return False;
							EndIf;
							
							vFR.FNOperation();
							If Not CheckResultCode(vFR.ResultCode) Then
								CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
								Return False;
							EndIf;
							
							// Extra functions for extensions
							If Not pmPrintCheque_AfterChequePositionRegistration(vFR, vArrCashRegister, vChargesWithMarkingCode, Undefined, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD) Then
								CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
								Return False;
							EndIf;
						EndIf;
					Else
						vFR.StringForPrinting = NStr("en='Hotel services';ru='Услуги гостиницы';de='Hotel Dienstleistungen'");
						If Not vArrCashRegister.PrintFolioHeader Then
							vFR.StringForPrinting = "#" + TrimAll(pObj.Number);
						EndIf;
						
						// Operation type
						If TypeOf(pObjRef) = Type("DocumentRef.Return") Then
							vFR.CheckType = 2;
						Else
							vFR.CheckType = 1;
						EndIf;
						
						// Department and cheque postion
						vPaymentSection = Undefined;
						vFR.Department = 0;
						If ValueIsFilled(pObj.PaymentSection) Then
							vPaymentSection = pObj.PaymentSection;
							vFR.Department = tcOnServer.cmGetAttributeByRef(vPaymentSection, "Code");
							If vArrCashRegister.PrintPaymentSectionNamesInCheques Then
								If vArrCashRegister.PrintFolioHeader Then
									vFR.StringForPrinting = GetString(TrimR(vFR.StringForPrinting) + " - " + tcOnServer.cmGetPaymentSectionDescription(vPaymentSection), vArrCashRegister);
								Else
									vFR.StringForPrinting = GetString(tcOnServer.cmGetPaymentSectionDescription(vPaymentSection), vArrCashRegister);
								EndIf;
							EndIf;
						EndIf;
						
						// Cheque position extra attributes
						// Payment item sign
						vItemTypeRef = tcCashRegisters.GetChequeItemType(pObj, Undefined, vPaymentSection);
						vItemType = tcCashRegisters.GetChequeItemTypeValue(vItemTypeRef);
						vFR.PaymentItemSign = vItemType;
						
						// Payment type sign
						vPaymentModeRef = tcCashRegisters.GetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection);
						vPaymentMode = tcCashRegisters.GetChequePaymentModeTypeValue(vPaymentModeRef);
						vFR.PaymentTypeSign = vPaymentMode;
						
						// Add tax
						vVATRate = Undefined;
						If ValueIsFilled(pObj.PaymentSection) And ValueIsFilled(tcOnServer.cmGetAttributeByRef(pObj.PaymentSection, "VATRate")) Then
							vFR.Tax1 = GetTaxGroup(pObj.PaymentSection, vVATRate, , pObj);
						Else
							vFR.Tax1 = GetTaxGroup(pObj, vVATRate, , pObj);
						EndIf;
						vFR.TaxValue = pObj.VATSum;
						vFR["TaxValue"+vFR.Tax1] = vFR.TaxValue;
						vFR.TaxValueEnabled = True;
						tcCashRegisters.SetChequeVATAmount(vChequeAttributes, vVATRAte, pObj.VATSum);
						
						// Do sale
						vFR.Quantity = 1;
						If pSum >= 0 Then
							vFR.Summ1 = pSum;
						Else
							vFR.Summ1 = -pSum;
						EndIf;
						vFR.Price = vFR.Summ1;
						vFR.Summ1Enabled = True;
						If vArrCashRegister.FiscalDataFormatVersions = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2") Then
							vFR.MeasureUnit = GetUnitPiece(Undefined);
						EndIf;
						
						// Extra functions for extensions
						If Not pmPrintCheque_BeforeChequePositionRegistration(vFR, vArrCashRegister, vChargesWithMarkingCode, Undefined, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD) Then
							CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
							Return False;
						EndIf;
						
						vFR.FNOperation();
						If Not CheckResultCode(vFR.ResultCode) Then
							CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
							Return False;
						EndIf;
						
						// Extra functions for extensions
						If Not pmPrintCheque_AfterChequePositionRegistration(vFR, vArrCashRegister, vChargesWithMarkingCode, Undefined, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD) Then
							CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
							Return False;
						EndIf;
					EndIf;
				EndIf;
				
				// Print VAT sum if neccessary
				If vArrCashRegister.PrintVATSumInCheques And pVATSum > 0 Then
					vNoVAT = ?(ValueIsFilled(pObj.VATRate), tcOnServer.cmGetAttributeByRef(pObj.VATRate, "NoVAT"), False);
					If vNoVAT Then
						vFR.StringForPrinting = GetString(NStr("en='No VAT';ru='Без НДС';de='Ohne MwSt.'"), vArrCashRegister);
					Else
						vFR.StringForPrinting = GetString(NStr("ru='В т.ч. НДС '; en='Incl. VAT '; de='Inkl. MwSt. '") + Format(pVATSum, "ND=17; NFD=2; NZ="), vArrCashRegister);
					EndIf;
					vFR.PrintString();
					If Not CheckResultCode(vFR.ResultCode) Then
						CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
						Return False;
					EndIf;
				ElsIf vArrCashRegister.PrintInclVATStrInCheques And pVATSum > 0 Then
					vFR.StringForPrinting = GetString(NStr("ru='НДС включён в сумму'; en='Amount includes VAT'; de='Betrag inkl. MwSt.'"), vArrCashRegister);
					vFR.PrintString();
					If Not CheckResultCode(vFR.ResultCode) Then
						CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
						Return False;
					EndIf;
				EndIf;
			EndIf;
			
			// Close cheque
			vTypeClose = 0;
			If ValueIsFilled(pObj.PaymentMethod) Then
				vTypeClose = vArrPaymentMethod.CashRegisterChequeCloseType;
			EndIf;
			vCloseSum = pSum;
			If pSum < 0 Then
				vCloseSum = -pSum;
			EndIf;
			
			vOpenDrawer = False;
			vFR.StringForPrinting = "";
			
			vFR.Summ1 = 0; vFR.Summ2 = 0; vFR.Summ3 = 0; vFR.Summ4 = 0; vFR.Summ5 = 0; vFR.Summ6 = 0; vFR.Summ7 = 0; vFR.Summ8 = 0; vFR.Summ9 = 0; vFR.Summ10 = 0; vFR.Summ11 = 0; vFR.Summ12 = 0; vFR.Summ13 = 0; vFR.Summ14 = 0; vFR.Summ15 = 0; vFR.Summ16 = 0;
			
			If pObj.PaymentMethod = PredefinedValue("Catalog.PaymentMethods.AdvanceSettlement") Then
				vFR.Summ14 = vCloseSum;
				vChequeAttributes.Sum = vCloseSum;
			Else
				If vTypeClose = 16 Then
					vFR.Summ16 = vCloseSum;
				ElsIf vTypeClose = 6 Then
					vFR.Summ6 = vCloseSum;
				ElsIf vTypeClose = 5 Then
					vFR.Summ5 = vCloseSum;
				ElsIf vTypeClose = 4 Then
					vFR.Summ4 = vCloseSum;
				ElsIf vTypeClose = 3 Then
					vFR.Summ3 = vCloseSum;
				ElsIf vTypeClose = 2 Then
					vFR.Summ2 = vCloseSum;
				Else
					vOpenDrawer = True;
					vFR.Summ1 = vCloseSum;
				EndIf;
			EndIf;
			
			// Extra functions for extensions
			If Not pmPrintCheque_BeforeCloseCheque(vFR, vArrCashRegister, vChargesWithMarkingCode, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD) Then
				CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			
			If Not pIsCorrection Or (pIsCorrection And vArrCashRegister.FiscalDataFormatVersions = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2")) Then
				vFR.FNCloseCheckEx();
			Else
				// Fill VAT in FFD 1.0.5
				If vArrCashRegister.FiscalDataFormatVersions = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_0_5") Then
					If pObj.PaymentSections.Count() > 0 Then
						For Each vPSRow In pObj.PaymentSections Do
							If vPSRow.Sum <> 0 Then
								If ValueIsFilled(vPSRow.VATRate) And tcOnServer.cmGetAttributeByRef(vPSRow.VATRate, "TaxRate") = 18 Then
									vFR.Summ7 = vFR.Summ7 + vPSRow.VATSum;
								ElsIf ValueIsFilled(vPSRow.VATRate) And tcOnServer.cmGetAttributeByRef(vPSRow.VATRate, "TaxRate") = 20 Then
									vFR.Summ7 = vFR.Summ7 + vPSRow.VATSum;
								ElsIf ValueIsFilled(vPSRow.VATRate) And tcOnServer.cmGetAttributeByRef(vPSRow.VATRate, "TaxRate") = 10 Then
									vFR.Summ8 = vFR.Summ8 + vPSRow.VATSum;
								ElsIf ValueIsFilled(vPSRow.VATRate) And tcOnServer.cmGetAttributeByRef(vPSRow.VATRate, "NoVAT") Then
									vFR.Summ10 = vFR.Summ10 + vPSRow.VATSum;
								ElsIf ValueIsFilled(vPSRow.VATRate) And tcOnServer.cmGetAttributeByRef(vPSRow.VATRate, "TaxRate") = 0 Then
									vFR.Summ9 = vFR.Summ9 + vPSRow.VATSum;
								Else
									vFR.Summ11 = vFR.Summ11 + vPSRow.VATSum;
								EndIf;
							EndIf;
						EndDo;
					ElsIf ValueIsFilled(pObj.VATRate) Then
						If tcOnServer.cmGetAttributeByRef(pObj.VATRate, "TaxRate") = 18 Then
							vFR.Summ7 = pObj.VATSum;
						ElsIf tcOnServer.cmGetAttributeByRef(pObj.VATRate, "TaxRate") = 20 Then
							vFR.Summ7 = pObj.VATSum;
						ElsIf tcOnServer.cmGetAttributeByRef(pObj.VATRate, "TaxRate") = 10 Then
							vFR.Summ8 = pObj.VATSum;
						ElsIf tcOnServer.cmGetAttributeByRef(pObj.VATRate, "NoVAT") Then
							vFR.Summ10 = pObj.VATSum;
						ElsIf tcOnServer.cmGetAttributeByRef(pObj.VATRate, "TaxRate") = 0 Then
							vFR.Summ9 = pObj.VATSum;
						Else
							vFR.Summ11 = pObj.VATSum;
						EndIf;
					EndIf;
				EndIf;
				vFR.FNBuildCorrectionReceipt2();
			EndIf;
			If Not CheckResultCode(vFR.ResultCode) Then
				CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			
			// Extra functions for extensions
			pmPrintCheque_AfterCloseCheque(vFR, vArrCashRegister, vChargesWithMarkingCode, vOpenDrawer, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD);
			
			// Get current cheque attributes
			If TypeOf(pObjRef) = Type("DocumentRef.Return") Then
				vChequeAttributes.ChequeAccountingType = PredefinedValue("Enum.ChequeAccountingTypes.ReceiptReturn");
			Else
				vChequeAttributes.ChequeAccountingType = PredefinedValue("Enum.ChequeAccountingTypes.Receipt");
			EndIf;
			vFR.FNGetStatus();
			vChequeAttributes.ChequeSequenceNumber = vFR.DocumentNumber;
			vChequeAttributes.ChequeDateTime = vFR.Date + (vFR.Time - BegOfDay(vFR.Time));
			vChequeAttributes.FiscalStorageFactoryNumber = vFR.SerialNumber;
			vChequeAttributes.ChequeFiscalNumber = vFR.FiscalSignAsString;
			vFR.FNGetCurrentSessionParams();
			vChequeAttributes.CashDayChequeNumber = vFR.ReceiptNumber;
			vChequeAttributes.CashDay = vFR.SessionNumber;
			
			// Log cash register operation
			vMessage = NStr("ru = 'По платежу №'; en = 'For payment N'; de = 'For payment N'") + TrimAll(pObj.Number) + 
			NStr("en=' with sum ';ru=' на сумму ';de=' für einen Betrag von '") + Format(pObj.Sum, "ND=17; NFD=2") + 
			NStr("ru = ' по ККМ '; en = ' by cash register '; de = ' by cash register '") + TrimAll(tcOnServer.cmGetAttributeByRef(pObj.CashRegister, "Description")) + 
			NStr("ru = ' пробит кассовый чек'; en = ' cheque was issued'; de = ' cheque was issued'");
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"),,,,vMessage);
			tcCashRegisters.WriteChequeAttributes(vChequeAttributes);
			
			// Open drawer
			Try
				If vOpenDrawer Then
					vFR.OpenDrawer();
				EndIf;
			Except
			EndTry;
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintCheque

// -----------------------------------------------------------------------------
Function pmPrintCustomerCheque(Val pSum, Val pVATSum, pObj, pObjRef, rMessage, pPasswordKKM="", pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101', pSendPayerContactsToOFD = 0, pEmailToSendToOFD = "", pPhoneToSendToOFD = "") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pObj.CashRegister);
	vArrPaymentMethod = tcOnServer.cmGetAtributeAsArray(pObj.PaymentMethod);
	
	vFR = Connect(rMessage, vArrCashRegister);
	If vFR = Undefined Then
		Return False
	EndIf;
	
	Try
		// Check if paper is present
		If Not CheckPaper(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage) Then
			Disconnect(vFR);
			Return False;
		EndIf;		
		
		// Close open cheque if any
		CloseOpenCheque(vFR, vArrCashRegister);
		
		// Open session if is closed
		If vArrCashRegister.DoNotOpenNewSessionAfterZReport Then
			If vFR.ECRMode = 4 Then
				SetTimeZone(vFR, vArrCashRegister);
				vFR.FNBeginOpenSession();
				// Set cashier name
				vCashier = tcOnServer.cmGetCurrentUserAttribute();
				If ValueIsFilled(vCashier) Then
					vCashierName = tcCashRegisters.GetCashierName(vCashier);
					If Not IsBlankString(vCashierName) Then
						vFR.TagNumber = 1021;
						vFR.TagType = 7;
						vFR.TagValueStr = vCashierName;
						vFR.FNSendTag();
						
						// Set TIN
						vEmployeeTIN = TrimAll(tcOnServer.cmGetAttributeByRef(vCashier, "TIN"));
						If Not IsBlankString(vEmployeeTIN) Then
							vFR.TagNumber = 1203;
							vFR.TagType = 7;
							vFR.TagValueStr	= vEmployeeTIN;
							vFR.FNSendTag();
						EndIf;
					EndIf;
				EndIf;
				// Open session
				vFR.OpenSession();
				If Not CheckResultCode(vFR.ResultCode) Then
					ProcessResultCode(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
					Return False;
				Else
					tcOnServer.Wait(5);
				EndIf;
			EndIf;
		EndIf;
		
		vIsPayment = False;
		
		// Open cheque
		If pIsCorrection And vArrCashRegister.FiscalDataFormatVersions <> PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2") Then
			If pSum < 0 Then
				vFR.CalculationSign = 3;
			Else
				vFR.CalculationSign = 1;
				vIsPayment = True;
			EndIf;
			vFR.FNBeginCorrectionReceipt();
		Else
			If pSum < 0 Then
				vFR.CheckType = 2;
			Else
				vFR.CheckType = 0;
				vIsPayment = True;
			EndIf;
			If ValueIsFilled(pObj.PaymentMethod) And tcOnServer.cmGetAttributeByRef(pObj.PaymentMethod, "ElectronicChequeOnly") Then
				// Do not print cheque on paper
				vFR.TableNumber			= 17;
				vFR.FieldNumber			= 7;
				vFR.ValueOfFieldInteger = 1;
				vFR.WriteTable();
			EndIf;
			
			If pIsCorrection Then
				vFR.FNOpenCheckCorrection();
			Else
				vFR.OpenCheck();
			EndIf;
		EndIf;
		
		// Initialize cheque attributes used to send online cheque by sms or e-mail
		vChequeAttributes = tcCashRegisters.InitializeChequeAttributes(pObj, pObjRef, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate);
		
		// Set correction type
		vChequeAttributes.IsCorrection = pIsCorrection;
		If pIsCorrection Then
			// Correction type
			If pCorrectionType = PredefinedValue("Enum.CorrectionChequeTypes.ByOrder") Then
				vFR.CorrectionType = 1;
			Else
				vFR.CorrectionType = 0;
			EndIf;
			vChequeAttributes.CorrectionType = pCorrectionType;
			
			// Fill remarks, order date and number
			vCorrectionDocumentDate = ?(ValueIsFilled(pCorrectionDocumentDate), BegOfDay(pCorrectionDocumentDate), ?(pObj.CorrectionOfIncorrectCheque And ValueIsFilled(pObj.Payment), tcOnServer.cmGetAttributeByRef(pObj.Payment, "Date"), '00010101'));
			If ValueIsFilled(vCorrectionDocumentDate) Then
				vFR.TagNumber = 1178;
				vFR.TagType = 6;
				vFR.TagValueDateTime = vCorrectionDocumentDate;
				vFR.FNSendTag();
				vChequeAttributes.CorrectionDocumentDate = vCorrectionDocumentDate;
			Else
				rMessage = NStr("en='The date of the corrected payment is not specified (the date when the wrong cheque was posted)!'; 
				|ru='Не указана дата совершения корректируемого расчета (дата, когда пробит неверный чек)!'; 
				|de='Das Datum der korrigierten Zahlung ist nicht angegeben (das Datum, an dem der falsche Scheck gebucht wurde)!'");
				Return False;
			EndIf;
			
			vCorrectionDocumentNumber = TrimAll(TrimAll(pCorrectionDescription) + ?(IsBlankString(pCorrectionDocumentNumber), "", " №" + TrimAll(pCorrectionDocumentNumber)));
			vFR.TagNumber = 1179;
			vFR.TagType = 7;
			vFR.TagValueStr = vCorrectionDocumentNumber;
			vFR.FNSendTag();
			vChequeAttributes.CorrectionDocumentNumber = vCorrectionDocumentNumber;
		EndIf;
		
		If vFR.ECRSoftDate > Date(2025, 8, 1) Then
			If vArrPaymentMethod.IsViaInternetAcquiring Then
				vFR.TagNumber = 1125;
				vFR.TagType = 0;
				vFR.TagValueInt = 1;
				vFR.FNSendTag();
				
				vHotelSite = "";
				If Not IsBlankString(vArrCashRegister.PaymentAddress) Then
					vHotelSite = TrimAll(vArrCashRegister.PaymentAddress);
				EndIf;
				
				If IsBlankString(vHotelSite) And ValueIsFilled(pObj.Hotel) Then
					vHotelSite = tcOnServer.cmGetAttributeByRef(pObj.Hotel, "Site");
				EndIf;
				
				If IsBlankString(vHotelSite) Then
					rMessage = NStr("en = 'The hotel website is not specified in the hotel settings (required to specify the payment location in the check)'; de = 'Die Hotelwebsite ist in den Hoteleinstellungen nicht angegeben (erforderlich, um den Zahlungsort im Scheck anzugeben)'; ru = 'В настройка гостинцы не указан сайт отеля (требуется для указания места расчёта в чеке)'");
					Disconnect(vFR);
					Return False;
				EndIf;
				
				vFR.TagNumber = 1187;
				vFR.TagType = 7;
				vFR.TagValueStr = vHotelSite;
				vFR.FNSendTag();
			Else
				vFR.TagNumber = 1125;
				vFR.TagType = 0;
				vFR.TagValueInt = 0;
				vFR.FNSendTag();
			EndIf;
		EndIf;
		
		If pSendPayerContactsToOFD = 0 Then
			// Transfer client e-mail
			vEMail = "";
			If ValueIsFilled(TrimAll(pEmailToSendToOFD)) Then
				vEMail = TrimAll(pEmailToSendToOFD);
			Else
				vPayer = Undefined;
				If TypeOf(pObj.Ref) = Type("DocumentRef.CustomerPayment") Then
					If ValueIsFilled(pObj.AccountingCustomer) Then
						vPayer = pObj.AccountingCustomer;
					EndIf;	
				EndIf;
				If ValueIsFilled(vPayer) Then
					If TypeOf(vPayer) = Type("CatalogRef.Clients") Or TypeOf(vPayer) = Type("CatalogRef.Customers") Then
						vEMail = TrimAll(tcOnServer.cmGetAttributeByRef(vPayer, "EMail"));
					EndIf;
				EndIf;
			EndIf;
			If ValueIsFilled(vEMail) And tcCommonFunctionOnClientServer.CheckEmail(vEMail, , False) And tcCashRegisters.CheckEMailsBlackList(vEMail) Then
				vFR.CustomerEmail = vEMail;
				vFR.FNSendCustomerEmail();
				vChequeAttributes.BuyerAddress = vEMail;
			EndIf;
		ElsIf pSendPayerContactsToOFD = 1 Then
			// Transfer client Phone
			vPhone = "";
			If ValueIsFilled(TrimAll(pPhoneToSendToOFD)) Then
				vPhone = TrimAll(pPhoneToSendToOFD);	
			Else
				vPayer = Undefined;
				If TypeOf(pObj.Ref) = Type("DocumentRef.CustomerPayment") Then
					If ValueIsFilled(pObj.AccountingCustomer) Then
						vPayer = pObj.AccountingCustomer;
					EndIf;	
				EndIf;
				If ValueIsFilled(vPayer) Then
					If TypeOf(vPayer) = Type("CatalogRef.Clients") Or TypeOf(vPayer) = Type("CatalogRef.Customers") Then
						vPhone = TrimAll(tcOnServer.cmGetAttributeByRef(vPayer, "Phone"));
					EndIf;
				EndIf;
			EndIf;
			vPhone = TrimAll(SMS.GetValidPhoneNumber(vPhone));
			If Left(vPhone, 1) <> "+" Then
				vPhone = "+" + vPhone;	
			EndIf;
			If ValueIsFilled(vPhone) Then
				vFR.CustomerEmail = SMS.GetPhoneNumberWithCountryCode(vPhone);
				vFR.FNSendCustomerEmail();
				vChequeAttributes.BuyerAddress = vPhone;
			EndIf;	
		EndIf;
		
		// Set taxation system
		vTaxSystem = Undefined;
		vTaxSystemCode = GetTaxationSystemCode(pObj, vTaxSystem);
		If vTaxSystemCode > 0 Then
			vFR.TaxType = vTaxSystemCode;
			vChequeAttributes.TaxationSystem = vTaxSystem;
		EndIf;
		
		// Set cashier name
		vCashier = pObj.Author;
		If ValueIsFilled(vCashier) Then
			vCashierName = tcCashRegisters.GetCashierName(vCashier);
			If Not IsBlankString(vCashierName) Then
				vFR.TagNumber = 1021;
				vFR.TagType = 7;
				vFR.TagValueStr = vCashierName;
				vFR.FNSendTag();
				vChequeAttributes.CashierName = vCashierName;
				
				// Set TIN
				vEmployeeTIN = TrimAll(tcOnServer.cmGetAttributeByRef(vCashier, "TIN"));
				If Not IsBlankString(vEmployeeTIN) Then
					vFR.TagNumber = 1203;
					vFR.TagType = 7;
					vFR.TagValueStr	= vEmployeeTIN;
					vFR.FNSendTag();
				EndIf;
			EndIf;
		EndIf;
		
		// Payer name and TIN
		vPayerName = "";
		vPayerTIN = "";
		tcOnServer.GetPayerNameAndTIN(pObj.AccountingCustomer, vPayerName, vPayerTIN);
		If Not IsBlankString(vPayerTIN) And Not IsBlankString(vPayerName) Then
			If vArrCashRegister.FiscalDataFormatVersions = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2") Then
				vFR.TagNumber = 1256;
				vFR.FNBeginSTLVTag();
				vTagID = vFR.TagID;
				
				vFR.TagID = vTagID;
				vFR.TagNumber = 1227;
				vFR.TagType = 7;
				vFR.TagValueStr = vPayerName;
				vFR.FNAddTag();
				
				vFR.TagID = vTagID;
				vFR.TagNumber = 1228;
				vFR.TagType = 7;
				vFR.TagValueStr = vPayerTIN;
				vFR.FNAddTag(); 
				
				vFR.FNSendSTLVTag();
			Else
				vFR.TagNumber = 1227;
				vFR.TagType = 7;
				vFR.TagValueStr = vPayerName;
				vFR.FNSendTag();
				
				vFR.TagNumber = 1228;
				vFR.TagType = 7;
				vFR.TagValueStr = vPayerTIN;
				vFR.FNSendTag();
			EndIf;
		EndIf;
		
		// Print cheque
		vFR.UseJournalRibbon = 1;
		vFR.UseReceiptRibbon = 1;
		
		vFR.Tax1 = 0; vFR.Tax2 = 0; vFR.Tax3 = 0; vFR.Tax4 = 0;
		vFR.Summ1 = 0; vFR.Summ2 = 0; vFR.Summ3 = 0; vFR.Summ4 = 0; vFR.Summ5 = 0; vFR.Summ6 = 0; vFR.Summ7 = 0; vFR.Summ8 = 0; vFR.Summ9 = 0; vFR.Summ10 = 0; vFR.Summ11 = 0; vFR.Summ12 = 0; vFR.Summ13 = 0; vFR.Summ14 = 0; vFR.Summ15 = 0; vFR.Summ16 = 0;
		
		// Print slip if payment was made by credit card
		If vArrCashRegister.PrintSlipInCheque Then
			If Not IsBlankString(pObj.SlipText) Then
				PrintSlipLines(vFR, tcOnServer.GetTextLinesArray(pObj.SlipText), vArrCashRegister);
				// Print cheque header
				vFR.PrintHeader();
				If Not CheckResultCode(vFR.ResultCode) Then
					ProcessResultCode(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
					Return False;
				EndIf;
			EndIf;
		EndIf;
		
		// Print number and section
		If Not pIsCorrection Or pIsCorrection And vArrCashRegister.FiscalDataFormatVersions <> PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_0_5") Then
			vFR.StringForPrinting = "#" + TrimAll(pObj.Number);
			
			// Operation type
			If pSum < 0 Then
				vFR.CheckType = 2;
			Else
				vFR.CheckType = 1;
			EndIf;
			
			// Department and cheque postion
			vPaymentSection = Undefined;
			vFR.Department = 0;
			If Not vArrCashRegister.DoNotPrintPaymentSections And ValueIsFilled(pObj.PaymentSection) Then
				vPaymentSection = pObj.PaymentSection;
				vFR.Department = tcOnServer.cmGetAttributeByRef(vPaymentSection, "Code");
				If vArrCashRegister.PrintPaymentSectionNamesInCheques Then
					If vArrCashRegister.PrintFolioHeader Then
						vFR.StringForPrinting = GetString(TrimR(vFR.StringForPrinting) + " - " + tcOnServer.cmGetPaymentSectionDescription(vPaymentSection), vArrCashRegister);
					Else
						vFR.StringForPrinting = GetString(tcOnServer.cmGetPaymentSectionDescription(vPaymentSection), vArrCashRegister);
					EndIf;
				EndIf;
			EndIf;
			
			// Cheque position extra attributes
			// Payment item sign
			vItemTypeRef = tcCashRegisters.GetChequeItemType(pObj, Undefined, pObj.PaymentSection);
			vItemType = tcCashRegisters.GetChequeItemTypeValue(vItemTypeRef);
			vFR.PaymentItemSign = vItemType;
			
			// Payment type sign
			vPaymentModeRef = tcCashRegisters.GetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection);
			vPaymentMode = tcCashRegisters.GetChequePaymentModeTypeValue(vPaymentModeRef);
			vFR.PaymentTypeSign = vPaymentMode;
			If pObj.PaymentMethod = PredefinedValue("Catalog.PaymentMethods.AdvanceSettlement") Then
				// This is advance settlement
				Raise NStr("en='Advance settlements are not supported for customer payments!'; ru='Зачет аванса в платежах контрагента не поддерживается!'; de='Nicht unterstützt'");
			EndIf;
			
			// Add tax
			vVATRate = Undefined;
			If ValueIsFilled(pObj.PaymentSection) And ValueIsFilled(tcOnServer.cmGetAttributeByRef(pObj.PaymentSection, "VATRate")) Then
				vFR.Tax1 = GetTaxGroup(pObj.PaymentSection, vVATRate, , pObj);
			Else
				vFR.Tax1 = GetTaxGroup(pObj, vVATRate, , pObj);
			EndIf;
			vFR.TaxValue = ?(pObj.VATSum < 0, -pObj.VATSum, pObj.VATSum);
			vFR["TaxValue"+vFR.Tax1] = vFR.TaxValue;
			vFR.TaxValueEnabled = True;
			tcCashRegisters.SetChequeVATAmount(vChequeAttributes, vVATRAte, ?(pObj.VATSum < 0, -pObj.VATSum, pObj.VATSum));
			
			vFR.Price = ?(pSum < 0, -pSum, pSum);
			vFR.Quantity = 1;
			vFR.Summ1 = vFR.Price;
			vFR.Summ1Enabled = True;  
			If vArrCashRegister.FiscalDataFormatVersions = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2") Then
				vFR.MeasureUnit = GetUnitPiece(Undefined);
			EndIf;
			vFR.FNOperation(); 
			If Not CheckResultCode(vFR.ResultCode) Then
				CancelCheque(vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
				Return False;
			EndIf;	
			
			// Print VAT sum if neccessary
			If vArrCashRegister.PrintVATSumInCheques And pVATSum > 0 Then
				vNoVAT = ?(ValueIsFilled(pObj.VATRate), tcOnServer.cmGetAttributeByRef(pObj.VATRate, "NoVAT"), False);
				If vNoVAT Then
					vFR.StringForPrinting = GetString(NStr("en='No VAT';ru='Без НДС';de='Ohne MwSt.'"), vArrCashRegister);
				Else
					vFR.StringForPrinting = GetString(NStr("ru = 'В т.ч. НДС '; en = 'Incl. VAT '; de = 'Inkl. MwSt. '") + Format(pVATSum, "ND=17; NFD=2; NZ="), vArrCashRegister);
				EndIf;
				vFR.PrintString();
			ElsIf vArrCashRegister.PrintInclVATStrInCheques And pVATSum > 0 Then
				vFR.StringForPrinting = GetString(NStr("ru = 'НДС включён в сумму'; en = 'Amount includes VAT'; de = 'Betrag ist mit MwSt.'"), vArrCashRegister);
				vFR.PrintString();
			EndIf;
		EndIf;
		
		// Close cheque
		vTypeClose = 0;
		If ValueIsFilled(pObj.PaymentMethod) Then
			vTypeClose = vArrPaymentMethod.CashRegisterChequeCloseType;
		EndIf;
		vCloseSum = pSum;
		If pSum < 0 Then
			vCloseSum = -pSum;
		EndIf;
		
		vOpenDrawer = False;
		vFR.StringForPrinting = "";
		
		vFR.Summ1 = 0; vFR.Summ2 = 0; vFR.Summ3 = 0; vFR.Summ4 = 0; vFR.Summ5 = 0; vFR.Summ6 = 0; vFR.Summ7 = 0; vFR.Summ8 = 0; vFR.Summ9 = 0; vFR.Summ10 = 0; vFR.Summ11 = 0; vFR.Summ12 = 0; vFR.Summ13 = 0; vFR.Summ14 = 0; vFR.Summ15 = 0; vFR.Summ16 = 0;
		
		If vTypeClose = 16 Then
			vFR.Summ16 = vCloseSum;
		ElsIf vTypeClose = 6 Then
			vFR.Summ6 = vCloseSum;
		ElsIf vTypeClose = 5 Then
			vFR.Summ5 = vCloseSum;
		ElsIf vTypeClose = 4 Then
			vFR.Summ4 = vCloseSum;
		ElsIf vTypeClose = 3 Then
			vFR.Summ3 = vCloseSum;
		ElsIf vTypeClose = 2 Then
			vFR.Summ2 = vCloseSum;
		Else
			vOpenDrawer = True;
			vFR.Summ1 = vCloseSum;
		EndIf;
		
		If Not pIsCorrection Then
			vFR.FNCloseCheckEx();
		Else
			If vArrCashRegister.FiscalDataFormatVersions = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_0_5") Then
				If ValueIsFilled(pObj.VATRate) Then
					If tcOnServer.cmGetAttributeByRef(pObj.VATRate, "TaxRate") = 18 Then
						vFR.Summ7 = ?(pObj.VATSum < 0, -pObj.VATSum, pObj.VATSum);
					ElsIf tcOnServer.cmGetAttributeByRef(pObj.VATRate, "TaxRate") = 20 Then
						vFR.Summ7 = ?(pObj.VATSum < 0, -pObj.VATSum, pObj.VATSum);
					ElsIf tcOnServer.cmGetAttributeByRef(pObj.VATRate, "TaxRate") = 10 Then
						vFR.Summ8 = ?(pObj.VATSum < 0, -pObj.VATSum, pObj.VATSum);
					ElsIf tcOnServer.cmGetAttributeByRef(pObj.VATRate, "NoVAT") Then
						vFR.Summ10 = ?(pObj.VATSum < 0, -pObj.VATSum, pObj.VATSum);
					ElsIf tcOnServer.cmGetAttributeByRef(pObj.VATRate, "TaxRate") = 0 Then
						vFR.Summ9 = ?(pObj.VATSum < 0, -pObj.VATSum, pObj.VATSum);
					Else
						vFR.Summ11 = ?(pObj.VATSum < 0, -pObj.VATSum, pObj.VATSum);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		If Not CheckResultCode(vFR.ResultCode) Then
			CancelCheque(vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
			Return False;
		EndIf;
		
		// Get current cheque attributes
		If pSum < 0 Then
			vChequeAttributes.ChequeAccountingType = PredefinedValue("Enum.ChequeAccountingTypes.ReceiptReturn");
		Else
			vChequeAttributes.ChequeAccountingType = PredefinedValue("Enum.ChequeAccountingTypes.Receipt");
		EndIf;
		vFR.FNGetStatus();
		vChequeAttributes.ChequeSequenceNumber = vFR.DocumentNumber;
		vChequeAttributes.ChequeDateTime = vFR.Date + (vFR.Time - BegOfDay(vFR.Time));
		vChequeAttributes.FiscalStorageFactoryNumber = vFR.SerialNumber;
		vChequeAttributes.ChequeFiscalNumber = Format(Number(vFR.FiscalSignAsString), "ND=10; NFD=; NLZ=; NG=");
		vFR.FNGetCurrentSessionParams();
		vChequeAttributes.CashDayChequeNumber = vFR.ReceiptNumber;
		vChequeAttributes.CashDay = vFR.SessionNumber;
		
		// Log cash register operation
		vMessage = NStr("ru = 'По платежу №'; en = 'For payment N'; de = 'For payment N'") + TrimAll(pObj.Number) + 
		NStr("en=' with sum ';ru=' на сумму ';de=' für einen Betrag von '") + Format(pObj.Sum, "ND=17; NFD=2") + 
		NStr("ru = ' по ККМ '; en = ' by cash register '; de = ' by cash register '") + TrimAll(tcOnServer.cmGetAttributeByRef(pObj.CashRegister, "Description")) + 
		NStr("ru = ' пробит кассовый чек'; en = ' cheque was issued'; de = ' cheque was issued'");
		tcOnServer.cmWriteLogEventAtServer(NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"),,,,vMessage);
		tcCashRegisters.WriteChequeAttributes(vChequeAttributes);
		
		// Open drawer
		Try
			If vOpenDrawer Then
				vFR.OpenDrawer();
			EndIf;
		Except
		EndTry;
		
		// Disconnect
		Disconnect(vFR);
		Return True;
	Except
		rMessage = ErrorDescription();
		ProcessException(vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
		Return False;
	EndTry;
EndFunction // PrintCustomerCheque

// -----------------------------------------------------------------------------
Function pmIsReadyToPrint(rMessage, pSkip24HoursLimitWarning = False, pCashRegister, pPasswordKKM = "") Export
	// Cash register parameters
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pCashRegister);
	// Cash register password
	vPasswordKKM = TrimAll(pPasswordKKM);
	If IsBlankString(vPasswordKKM) Then
		vPasswordKKM = tcOnServer.cmGetUserPasswordKKM(, pCashRegister);
		If IsBlankString(vPasswordKKM) Then
			vPasswordKKM = TrimAll(vArrCashRegister.AccessPassword);
		EndIf;
	EndIf;
	// Try to connect
	vFR = Connect(rMessage, vArrCashRegister, vPasswordKKM);
	If vFR = Undefined Then
		Return False;
	Else // Cash register was connected
		// Retrieve cash register state
		vFR.GetECRStatus();
		If vFR.ECRMode = 3 Then // Open session, 24 hours finished
			If Not pSkip24HoursLimitWarning Then
				rMessage = NStr("ru='Смена превысила 24 часа!'; en='24 hours open session limit exceeded!'; de='24 hours open session limit exceeded!'");
				Disconnect(vFR);
				Return False;
			EndIf;
		ElsIf Not CheckResultCode(vFR.ResultCode) Then
			rMessage = NStr("ru='Ошибка получения состояния ККМ!'; en='Failed to check cash register state!'; de='Failed to check cash register state!'");
			Disconnect(vFR);
			Return False;
		EndIf;
		// Check paper
		If vFR.ReceiptRibbonIsPresent = 0 And Not vArrCashRegister.IgnoreEndOfPaperError Then
			rMessage = NStr("ru = 'В ККМ закончилась чековая лента!'; en = 'Cash register is out of paper!'; de = 'Cash register is out of paper!'");
			Disconnect(vFR);
			Return False;
		EndIf;
	EndIf;
	// Disconnect
	Disconnect(vFR);
	Return True;
EndFunction // pmIsReadyToPrint

// -----------------------------------------------------------------------------
Function pmPrintZReport(rMessage, pObj, pPasswordKKM = "") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pObj.CashRegister);
	// Try to connect
	vFR = Connect(rMessage,vArrCashRegister,pPasswordKKM);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Check if paper is present
			If Not CheckPaper(vFR, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), rMessage) Then
				Disconnect(vFR);
				Return False;
			EndIf;		
			// Check if the session is already closed
			vAlreadyClosed = False;
			If vFR.ECRMode = 4 Then
				//session is closed
				rMessage = NStr("ru = 'На ККМ смена уже закрыта!'; en = 'Session is already closed at device!'; de = 'Ist die Schicht bereits geschlossen!'");
				tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
				tcOnServer.cmWriteLogEventAtServer(NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"),,,,rMessage);
				vAlreadyClosed = True;
			EndIf;
			If Not vAlreadyClosed Then
				// Close open cheque if any
				CloseOpenCheque(vFR, vArrCashRegister);
				// Start close session
				vFR.FNBeginCloseSession();
				// Set cashier name
				vCashier = tcOnServer.cmGetCurrentUserAttribute();
				If ValueIsFilled(vCashier) Then
					vCashierName = tcCashRegisters.GetCashierName(vCashier);
					If Not IsBlankString(vCashierName) Then
						vFR.TagNumber = 1021;
						vFR.TagType = 7;
						vFR.TagValueStr = vCashierName;
						vFR.FNSendTag();
						
						// Set TIN
						vEmployeeTIN = TrimAll(tcOnServer.cmGetAttributeByRef(vCashier, "TIN"));
						If Not IsBlankString(vEmployeeTIN) Then
							vFR.TagNumber = 1203;
							vFR.TagType = 7;
							vFR.TagValueStr	= vEmployeeTIN;
							vFR.FNSendTag();
						EndIf;
					EndIf;
				EndIf;
				// Print report
				vFR.PrintReportWithCleaning();
				If Not CheckResultCode(vFR.ResultCode) Then
					ProcessResultCode(vFR, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), rMessage);
					Return False;
				EndIf;	
				// Open drawer
				Try
					vFR.OpenDrawer();
				Except
				EndTry;
			EndIf;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), rMessage);
			Return False;
		EndTry;
		Try			
			// Check time difference between workstation and cash register and correct 
			// device time if difference is more then 5 minutes
			vBreakOpenNewSession = False;
			If Not CheckTimeDifference(vFR, rMessage) Then
				#IF THINCLIENT THEN
					ShowUserNotification(NStr("en = 'Time setting error in cash register'; de = 'Zeiteinstellungsfehler in der Registrierkassen'; ru = 'Ошибка установки времени в ККМ'"), , rMessage, PictureLib.InformationMedium, UserNotificationStatus.Important, pObj.Ref); 	
				#ENDIF
				vBreakOpenNewSession = True;
			EndIf;
			
			// Open new session
			If Not vArrCashRegister.DoNotOpenNewSessionAfterZReport And Not vBreakOpenNewSession Then
				vFR.GetECRStatus();
				If CheckResultCode(vFR.ResultCode) Then
					If vFR.ECRAdvancedMode = 5 Then
						tcOnServer.Wait(5);	
					EndIf;
				Else
					ProcessResultCode(vFR, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), rMessage);
					#IF THINCLIENT THEN
						ShowUserNotification(NStr("en = 'Error opening shift in cash register'; de = 'Fehler beim Öffnen der Schicht in der Registrierkasse'; ru = 'Ошибка открытия смены в ККМ'"), , rMessage, PictureLib.InformationMedium, UserNotificationStatus.Important, pObj.Ref); 	
					#ENDIF
					vBreakOpenNewSession = True;	
				EndIf;
				If Not vBreakOpenNewSession Then
					SetTimeZone(vFR, vArrCashRegister);
					vFR.FNBeginOpenSession();
					// Set cashier name
					If ValueIsFilled(vCashier) Then
						If Not IsBlankString(vCashierName) Then
							vFR.TagNumber = 1021;
							vFR.TagType = 7;
							vFR.TagValueStr = vCashierName;
							vFR.FNSendTag();
							
							// Set TIN
							If Not IsBlankString(vEmployeeTIN) Then
								vFR.TagNumber = 1203;
								vFR.TagType = 7;
								vFR.TagValueStr	= vEmployeeTIN;
								vFR.FNSendTag();
							EndIf;
						EndIf;
					EndIf;
					// Open session
					vFR.OpenSession();
					If Not CheckResultCode(vFR.ResultCode) Then
						ProcessResultCode(vFR, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), rMessage);
						#IF THINCLIENT THEN
							ShowUserNotification(NStr("en = 'Error opening shift in cash register'; de = 'Fehler beim Öffnen der Schicht in der Registrierkasse'; ru = 'Ошибка открытия смены в ККМ'"), , rMessage, PictureLib.InformationMedium, UserNotificationStatus.Important, pObj.Ref); 	
						#ENDIF
					EndIf;
				EndIf;
			EndIf;			
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), rMessage);
		EndTry
	EndIf;
	// Disconnect
	Disconnect(vFR);
	Return True;
EndFunction // pmPrintZReport

// -----------------------------------------------------------------------------
Function pmPrintXReport(rMessage,pCashRegister,pPasswordKKM="") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pCashRegister);
	// Try to connect
	vFR = Connect(rMessage,vArrCashRegister,pPasswordKKM);
	
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Check if paper is present
			If Not CheckPaper(vFR, NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"), rMessage) Then
				Disconnect(vFR);
				Return False;
			EndIf;		
			// Close open cheque if any
			CloseOpenCheque(vFR, vArrCashRegister);
			// Do report
			vFR.PrintReportWithoutCleaning();
			If Not CheckResultCode(vFR.ResultCode) Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"), rMessage);
				Return False;
			EndIf;	
			// Open drawer
			Try
				vFR.OpenDrawer();
			Except
			EndTry;
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintXReport

// -----------------------------------------------------------------------------
Function pmPrintHourXReport(rMessage,pCashRegister,pPasswordKKM="") Export
	rMessage = NStr("ru = 'Печать почасового отчета не поддерживается драйвером!'; en = 'Hourly X Report is not supported by driver!'; de = 'Hourly X Report is not supported by driver!'");
	Return False;
EndFunction // pmPrintHourXReport

// -----------------------------------------------------------------------------
Function pmPrintCurrentStateOfCalculationsReport(rMessage,pCashRegister,pPasswordKKM="") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pCashRegister);
	// Try to connect
	vFR = Connect(rMessage,vArrCashRegister,pPasswordKKM);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Check if paper is present
			If Not CheckPaper(vFR, NStr("en='CashRegister.PrintCurrentStateOfCalculationsReport'; de='CashRegister.PrintCurrentStateOfCalculationsReport'; ru='ККМ.ПечатьОтчетаОТекущемСостоянииРасчетовПоФР'"), rMessage) Then
				Disconnect(vFR);
				Return False;
			EndIf;			
			// Close open cheque if any
			CloseOpenCheque(vFR, vArrCashRegister);
			// Print report
			vFR.FNBuildCalculationStateReport();
			If Not CheckResultCode(vFR.ResultCode) Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintCurrentStateOfCalculationsReport'; de='CashRegister.PrintCurrentStateOfCalculationsReport'; ru='ККМ.ПечатьОтчетаОТекущемСостоянииРасчетовПоФР'"), rMessage);
				Return False;
			EndIf;	
			// Log cash register operation
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CashRegister.PrintCurrentStateOfCalculationsReport'; de='CashRegister.PrintCurrentStateOfCalculationsReport'; ru='ККМ.ПечатьОтчетаОТекущемСостоянииРасчетовПоФР'"), , , , rMessage);
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintCurrentStateOfCalculationsReport'; de='CashRegister.PrintCurrentStateOfCalculationsReport'; ru='ККМ.ПечатьОтчетаОТекущемСостоянииРасчетовПоФР'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintCurrentStateOfCalculationsReport

// -----------------------------------------------------------------------------
Function pmPrintSlip(pSlipTextArr, pCashRegister, rMessage, pPassword, pOneCopyOnly = False) Export
	If TypeOf(pCashRegister) = Type("Structure") Then  
		vArrCashRegister = pCashRegister;
	Else 
		vArrCashRegister =  tcOnServer.cmGetAtributeAsArray(pCashRegister);
	EndIf;
	
	// Try to connect
	vFR = Connect(rMessage,vArrCashRegister,pPassword);
	
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Check if paper is present
			If Not CheckPaper(vFR, NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"), rMessage) Then
				Disconnect(vFR);
				Return False;
			EndIf;				
			
			// Close open cheque if any
			CloseOpenCheque(vFR, vArrCashRegister);
			
			// Open session if is closed
			If vArrCashRegister.DoNotOpenNewSessionAfterZReport Then
				If Not vArrCashRegister.PrintVATSumInCheques And Not vArrCashRegister.PrintInclVATStrInCheques Then
					If vFR.ECRMode = 4 Then
						SetTimeZone(vFR, vArrCashRegister);
						vFR.FNBeginOpenSession();
						// Set cashier name
						vCashier = tcOnServer.cmGetCurrentUserAttribute();
						If ValueIsFilled(vCashier) Then
							vCashierName = tcCashRegisters.GetCashierName(vCashier);
							If Not IsBlankString(vCashierName) Then
								vFR.TagNumber = 1021;
								vFR.TagType = 7;
								vFR.TagValueStr = vCashierName;
								vFR.FNSendTag();
								
								// Set TIN
								vEmployeeTIN = TrimAll(tcOnServer.cmGetAttributeByRef(vCashier, "TIN"));
								If Not IsBlankString(vEmployeeTIN) Then
									vFR.TagNumber = 1203;
									vFR.TagType = 7;
									vFR.TagValueStr	= vEmployeeTIN;
									vFR.FNSendTag();
								EndIf;
							EndIf;
						EndIf;
						// Open session
						vFR.OpenSession();
						If Not CheckResultCode(vFR.ResultCode) Then
							ProcessResultCode(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
							Return False;
						Else
							tcOnServer.Wait(5);
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			
			// Print all strings in the array
			PrintSlipLines(vFR, pSlipTextArr, vArrCashRegister, pOneCopyOnly);
			If Not CheckResultCode(vFR.ResultCode) And vFR.ResultCode <> 126 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintSlip'; de='CashRegister.PrintSlip'; ru='ККМ.ПечатьСлипа'"), rMessage);
				Return False;
			EndIf;
			
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintSlip'; de='CashRegister.PrintSlip'; ru='ККМ.ПечатьСлипа'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintSlip

// -----------------------------------------------------------------------------
Function pmPrintNonFiscalCheque(pSum, pVATSum, pObj, pChequeTemplate, rMessage, pPassword="") Export
	vArrCashRegister =  tcOnServer.cmGetAtributeAsArray(pObj.CashRegister);
	
	// Try to connect
	vFR = Connect(rMessage, vArrCashRegister, pPassword);
	
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Check if paper is present
			If Not CheckPaper(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНефискальногоЧека'"), rMessage) Then
				Disconnect(vFR);
				Return False;
			EndIf;				
			
			// Close open cheque if any
			CloseOpenCheque(vFR, vArrCashRegister);
			
			vChequeType = ?(pSum >= 0, "ПРИХОД", "ВОЗВРАТ ПРИХОДА");
			
			// Convert cheque template to the array of strings
			vTextArr = tcCashRegisters.GetTextLinesArray(pChequeTemplate);
			
			// Print all strings in the array
			vDoPrintClicheAtEnd = False;
			vFR.UseJournalRibbon=0; 
			vFR.UseReceiptRibbon=1;
			
			// Print first slip for the hotel
			i = 0;
			For Each vStr In vTextArr Do
				i = i + 1;
				If vStr = "&Cliche" And i = 1 Then
					vFR.PrintCliche();
					If Not CheckResultCode(vFR.ResultCode) And vFR.ResultCode <> 126 Then
						ProcessResultCode(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
						Return False;
					EndIf;
				ElsIf vStr = "&Cliche" And i = vTextArr.Count() Then
					vDoPrintClicheAtEnd = True;
					Continue;
				ElsIf vStr = "&FolioHeader" Then
					Try
						PrintFolioHeader(vFR, pObj, vArrCashRegister);
						If Not CheckResultCode(vFR.ResultCode) And vFR.ResultCode <> 126 Then
							ProcessResultCode(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
							Return False;
						EndIf;
					Except
					EndTry;
				Else
					vStr = StrReplace(vStr, "&Type", vChequeType);
					vStr = StrReplace(vStr, "&CurrentDate", Format(CurrentDate(), "DF=dd.MM.yyyy"));
					vStr = StrReplace(vStr, "&CurrentTime", Format(CurrentDate(), "DF=HH:mm"));
					Try
						vStr = StrReplace(vStr, "&Document", ?(pSum >= 0, "Предварительный счет", "Возврат по платежу") + " № " + TrimAll(pObj.Number));
					Except
					EndTry;
					Try
						vStr = StrReplace(vStr, "&Hotel", tcCashRegisters.GetHotelPrintName(pObj.Hotel));
					Except
					EndTry;
					Try
						vStr = StrReplace(vStr, "&Currency", TrimAll(pObj.PaymentCurrency));
					Except
					EndTry;
					Try
						vStr = StrReplace(vStr, "&VATRate", TrimAll(pObj.VATRate));
					Except
					EndTry;
					Try
						vStr = StrReplace(vStr, "&Cashier", TrimAll(pObj.Author));
					Except
					EndTry;
					vStr = StrReplace(vStr, "&Amount", Format(?(pSum < 0, -pSum, pSum), "NFD=2"));
					vFR.StringForPrinting = GetString(vStr, vArrCashRegister);
					vFR.PrintString();
					If Not CheckResultCode(vFR.ResultCode) And vFR.ResultCode <> 126 Then
						ProcessResultCode(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
						Return False;
					EndIf;
				EndIf;
			EndDo;
			
			// Print cliche
			If vDoPrintClicheAtEnd Then
				vFR.PrintCliche();
				If Not CheckResultCode(vFR.ResultCode) And vFR.ResultCode <> 126 Then
					ProcessResultCode(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
					Return False;
				EndIf;
			Else
				vFR.StringQuantity = 6 + vArrCashRegister.NumberOfExtraLinesOfPaperRunBeforeCut;
				vFR.FeedDocument();
			EndIf;
			
			// Cut off cheque
			vFR.CutType = True;
			vFR.CutCheck();
			
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintNonFiscalCheque

// -----------------------------------------------------------------------------
Function pmPrintCashIncome(Val pSum, pObj, rMessage, pPassword="") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pObj.CashRegister);
	// Try to connect
	vFR = Connect(rMessage, vArrCashRegister, pPassword);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Check if paper is present
			If Not CheckPaper(vFR, NStr("en='CashRegister.PrintCashIncome'; de='CashRegister.PrintCashIncome'; ru='ККМ.ПечатьЧекаВнесенияДенег'"), rMessage) Then
				Disconnect(vFR);
				Return False;
			EndIf;		
			
			// Close open cheque if any
			CloseOpenCheque(vFR, vArrCashRegister);
			
			// Open session if is closed
			If vArrCashRegister.DoNotOpenNewSessionAfterZReport Then
				If vFR.ECRMode = 4 Then
					SetTimeZone(vFR, vArrCashRegister);
					vFR.FNBeginOpenSession();
					// Set cashier name
					vCashier = tcOnServer.cmGetCurrentUserAttribute();
					If ValueIsFilled(vCashier) Then
						vCashierName = tcCashRegisters.GetCashierName(vCashier);
						If Not IsBlankString(vCashierName) Then
							vFR.TagNumber = 1021;
							vFR.TagType = 7;
							vFR.TagValueStr = vCashierName;
							vFR.FNSendTag();
							
							// Set TIN
							vEmployeeTIN = TrimAll(tcOnServer.cmGetAttributeByRef(vCashier, "TIN"));
							If Not IsBlankString(vEmployeeTIN) Then
								vFR.TagNumber = 1203;
								vFR.TagType = 7;
								vFR.TagValueStr	= vEmployeeTIN;
								vFR.FNSendTag();
							EndIf;
						EndIf;
					EndIf;
					// Open session
					vFR.OpenSession();
					If Not CheckResultCode(vFR.ResultCode) Then
						ProcessResultCode(vFR, NStr("en='CashRegister.PrintCashIncome'; de='CashRegister.PrintCashIncome'; ru='ККМ.ПечатьЧекаВнесенияДенег'"), rMessage);
						Return False;
					Else
						tcOnServer.Wait(5);
					EndIf;
				EndIf;
			EndIf;
			
			// Do cash income
			vFR.Summ1 = pSum;
			vFR.CashIncome();
			If Not CheckResultCode(vFR.ResultCode) Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintCashIncome'; de='CashRegister.PrintCashIncome'; ru='ККМ.ПечатьЧекаВнесенияДенег'"), rMessage);
				Return False;
			EndIf;
			
			// Open drawer
			Try
				vFR.OpenDrawer();
			Except
			EndTry;
			
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintCashIncome'; de='CashRegister.PrintCashIncome'; ru='ККМ.ПечатьЧекаВнесенияДенег'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintCashIncome

// -----------------------------------------------------------------------------
Function pmPrintCashOutcome(Val pSum, pObj, rMessage, pPassword="") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pObj.CashRegister);
	// Try to connect
	vFR = Connect(rMessage, vArrCashRegister, pPassword);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Check if paper is present
			If Not CheckPaper(vFR, NStr("en='CashRegister.PrintCashOutcome'; de='CashRegister.PrintCashOutcome'; ru='ККМ.ПечатьЧекаИнкассации'"), rMessage) Then
				Disconnect(vFR);
				Return False;
			EndIf;		
			
			// Close open cheque if any
			CloseOpenCheque(vFR, vArrCashRegister);
			
			// Open session if is closed
			If vArrCashRegister.DoNotOpenNewSessionAfterZReport Then
				If vFR.ECRMode = 4 Then
					SetTimeZone(vFR, vArrCashRegister);
					vFR.FNBeginOpenSession();
					// Set cashier name
					vCashier = tcOnServer.cmGetCurrentUserAttribute();
					If ValueIsFilled(vCashier) Then
						vCashierName = tcCashRegisters.GetCashierName(vCashier);
						If Not IsBlankString(vCashierName) Then
							vFR.TagNumber = 1021;
							vFR.TagType = 7;
							vFR.TagValueStr = vCashierName;
							vFR.FNSendTag();
							
							// Set TIN
							vEmployeeTIN = TrimAll(tcOnServer.cmGetAttributeByRef(vCashier, "TIN"));
							If Not IsBlankString(vEmployeeTIN) Then
								vFR.TagNumber = 1203;
								vFR.TagType = 7;
								vFR.TagValueStr	= vEmployeeTIN;
								vFR.FNSendTag();
							EndIf;
						EndIf;
					EndIf;
					// Open session
					vFR.OpenSession();
					If Not CheckResultCode(vFR.ResultCode) Then
						ProcessResultCode(vFR, NStr("en='CashRegister.PrintCashOutcome'; de='CashRegister.PrintCashOutcome'; ru='ККМ.ПечатьЧекаИнкассации'"), rMessage);
						Return False;
					Else
						tcOnServer.Wait(5);
					EndIf;
				EndIf;
			EndIf;
			
			// Do cash outcome
			vFR.Summ1 = pSum;
			vFR.CashOutcome();
			If Not CheckResultCode(vFR.ResultCode) Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintCashOutcome'; de='CashRegister.PrintCashOutcome'; ru='ККМ.ПечатьЧекаИнкассации'"), rMessage);
				Return False;
			EndIf;
			
			// Open drawer
			Try
				vFR.OpenDrawer();
			Except
			EndTry;
			
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintCashOutcome'; de='CashRegister.PrintCashOutcome'; ru='ККМ.ПечатьЧекаИнкассации'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintCashOutcome

// -----------------------------------------------------------------------------
Function pmOpenCashDrawer(rMessage, pCashRegister) Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pCashRegister);
	// Try to connect
	vFR = Connect(rMessage, vArrCashRegister);
	If vFR = Undefined Then
		Return False;
	Else 
		// Close open cheque if any
		CloseOpenCheque(vFR, vArrCashRegister);
		// Check demo mode
		If vFR.IsDemo = 1 Then
			rMessage = NStr("ru='Не обнаружен ключ защиты драйвера ККМ фирмы Атол!'; en='Atol cash register driver dongle was not found!'; de='Atol cash register driver dongle was not found!'");
			Disconnect(vFR);
			Return False;
		EndIf;
		// Open drawer
		Try
			vFR.OpenDrawer();
		Except
			rMessage = ErrorDescription();
			Disconnect(vFR);
			Return false;
		EndTry;		
	EndIf;
	// Disconnect
	Disconnect(vFR);
	Return True;
EndFunction // pmOpenCashDrawer

// -----------------------------------------------------------------------------
Function pmSetDeviceTime(rMessage, pCashRegister) Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pCashRegister);
	// Try to connect
	vFR = Connect(rMessage, vArrCashRegister);
	If vFR = Undefined Then
		Return False;
	EndIf;
	// Cash register was connected
	Try
		// Set cash register time to the current one
		If Not SetDeviceTime(vFR, rMessage) Then
			Return False;	
		EndIf;
	Except
		rMessage = ErrorDescription();
		ProcessException(vFR, NStr("en='CashRegister.SetDeviceTime'; de='CashRegister.SetDeviceTime'; ru='ККМ.УстановкаВремени'"), rMessage);
		Return False;
	EndTry;
	// Disconnect
	Disconnect(vFR);
	Return True;
EndFunction // pmSetDeviceTime 

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure SetTimeZone(pFR, pCashRegister)
	If pFR.ECRSoftDate > Date(2025, 8, 1) And pCashRegister.FiscalDataFormatVersions <> PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2") Or pCashRegister.TimeZone <= 0 Then
		Return;
	EndIf;
	
	pFR.TableNumber = 18;
	pFR.RowNumber = 1;
	pFR.FieldNumber = 25;
	pFR.ValueOfFieldInteger = pCashRegister.TimeZone;
	pFR.WriteTable();
EndProcedure // SetTimeZone

// -----------------------------------------------------------------------------
Function IsNumber(pStr)
	Try 
		vNumStr = Number(pStr);
		Return True;
	Except
	EndTry;
	Return False;
EndFunction // IsNumber

// -----------------------------------------------------------------------------
Function GetPortNumber(pCashRegister)
	vPort = TrimAll(pCashRegister.Port);
	If vPort = "" Then
		Return 1; //COM1 by default
	Else
		vPortNumber = 0;
		If Upper(Left(vPort, 3)) = "COM" Then
			vPortNumber = Number(Mid(vPort, 4, StrLen(vPort)-3));
		ElsIf IsNumber(vPort) Then
			vPortNumber = Number(vPort);
		EndIf;
		Return vPortNumber;
	EndIf;
EndFunction // GetPortNumber

// -----------------------------------------------------------------------------
Function GetBaudRate(pCashRegister)
	vBaudRate = pCashRegister.BaudRate;
	If vBaudRate = 2400 Then
		Return 0;
	ElsIf vBaudRate = 4800 Then
		Return 1;
	ElsIf vBaudRate = 9600 Then
		Return 2;
	ElsIf vBaudRate = 19200 Then
		Return 3;
	ElsIf vBaudRate = 38400 Then
		Return 4;
	ElsIf vBaudRate = 57600 Then
		Return 5;
	ElsIf vBaudRate = 115200 Then
		Return 6;
	ElsIf vBaudRate = 0 Then
		Return 6;
	EndIf;
	Return 0;
EndFunction // GetBaudRate

// -----------------------------------------------------------------------------
Function Connect(rMessage,vArrCashRegister,pPassword="")
	// Reset return status
	rMessage = "";
	// Try to load external component
	Try
		vProgID = "AddIn.DrvFR";
		vDriverDLL = "DrvFR.dll";
		If vArrCashRegister.CashRegisterModel = "Addin.KKTDrv" Then
			vProgID = "Addin.KKTDrv";
			vDriverDLL = "KKTDrv.dll";
		EndIf;
		
		Try
			AttachAddIn(vProgID);
			vFR = New(vProgID);
		Except
			LoadAddIn(vDriverDLL);
			vFR = New(vProgID);
		EndTry;
		vFR.UseIPAddress = False;
		
		// Set active logical device
		If vArrCashRegister.UseLogicalDevice And vArrCashRegister.LogicalDeviceNumber > 0 Then
			vFR.LDNumber = vArrCashRegister.LogicalDeviceNumber;
			vFR.SetActiveLD();
		EndIf;
		vFR.Password = pPassword;
		If Not IsBlankString(vArrCashRegister.DriverProtocol) And TrimAll(vArrCashRegister.DriverProtocol) = "1" Then
			vFR.ProtocolType = 1;
		EndIf;
		If Not IsBlankString(vArrCashRegister.ConnectionType) Then
			Try
				vFR.ConnectionType = Number(TrimAll(vArrCashRegister.ConnectionType));
			Except
				vFR.ConnectionType = 0;
			EndTry;
		EndIf;
		vPortNumber = GetPortNumber(vArrCashRegister);
		vBaudRate = GetBaudRate(vArrCashRegister);
		If vPortNumber > 0 Then
			If vFR.ConnectionType = 6 Then
				vFR.TCPPort = vPortNumber;
			Else
				vFR.ComNumber = vPortNumber;
			EndIf;
		EndIf;
		If vBaudRate > 0 Then
			vFR.BaudRate = vBaudRate;
		EndIf;
		If Not IsBlankString(vArrCashRegister.Address) Then
			vAddress = StrSplit(vArrCashRegister.Address, ":", False);
			If vAddress.Count() = 2 Then
				vFR.ComputerName = TrimAll(TrimAll(vAddress[0]));
				vFR.TCPPort = Number(TrimAll(vAddress[1]));
			Else
				vFR.ComputerName = TrimAll(vArrCashRegister.Address);
			EndIf;
			If cmIsIPAddress(vFR.ComputerName) Then
				vFR.UseIpAddress = True;
				vFR.IPAddress = vFR.ComputerName;
				If vAddress.Count() = 1 Then
					vFR.TCPPort = 7778; // Default port number
				EndIf;
			EndIf;
		EndIf;
		If Not IsBlankString(vArrCashRegister.OFDServer) Then
			vFR.OFDServer = TrimAll(vArrCashRegister.OFDServer);
		EndIf;
		If vArrCashRegister.OFDPort <> 0 Then
			vFR.OFDPort = vArrCashRegister.OFDPort;
		EndIf;
		If vArrCashRegister.OFDPollPeriod <> 0 Then
			vFR.OFDPollPeriod = vArrCashRegister.OFDPollPeriod;
		EndIf;
		If vArrCashRegister.Timeout <> 0 Then
			vFR.Timeout = vArrCashRegister.Timeout;
		EndIf;
		// Try to enable device
		vFR.Connect();
		// Check result code
		If Not CheckResultCode(vFR.ResultCode) Then
			// Error connecting to the device
			rMessage = TrimAll(vFR.ResultCodeDescription);
			Return Undefined;
		Else
			vPassword = vFR.Password;
			If ValueIsFilled(vArrCashRegister.CashRegisterPassword) Then
				vFR.Password = TrimR(vArrCashRegister.CashRegisterPassword);
			ElsIf ValueIsFilled(vArrCashRegister.AccessPassword) Then
				vFR.Password = TrimR(vArrCashRegister.AccessPassword);
			EndIf;
			
			vCashier = tcOnServer.cmGetCurrentUserAttribute();
			If ValueIsFilled(vCashier) Then
				vCashierName = tcCashRegisters.GetCashierName(vCashier);
				
				vFR.TableNumber = 2;
				vFR.RowNumber = 30;
				vFR.FieldNumber = 2;
				vFR.ValueOfFieldString = vCashierName;
				vFR.WriteTable();
			EndIf;
			
			vFR.Password = vPassword;
			
			DisableMapping22(vFR, vArrCashRegister);
			
			// OK
			Return vFR;
		EndIf;
	Except
		rMessage = ErrorDescription();
		Return Undefined;
	EndTry;
EndFunction // Connect

// -----------------------------------------------------------------------------
Procedure Disconnect(pFR)
	Try
		pFR.Disconnect();
		pFR = Undefined;
	Except
	EndTry;
EndProcedure // Disconnect

// -----------------------------------------------------------------------------
Function Bin2Dec(pBin)
	vDec = 0;
	vLen = StrLen(pBin);
	For i = 1 To vLen Do
		vDec = vDec + Number(Mid(pBin, i, 1)) * Pow(2, (vLen - i));
	EndDo;
	Return vDec;
EndFunction // Bin2Dec

// -----------------------------------------------------------------------------
Function GetTaxGroup(pObj, rVATRate, pRowVATRate = Undefined, pDocObj = Undefined)
	vTaxGroupCode = 0;
	
	rVATRate = Undefined;
	If ValueIsFilled(pRowVATRate) Then
		rVATRate = pRowVATRate;
	Else
		If TypeOf(pObj) = Type("FormDataStructure") Then
			rVATRate = pObj.VATRate;
		Else
			rVATRate = tcOnServer.cmGetAttributeByRef(pObj, "VATRate");
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(rVATRate) Then
		Return vTaxGroupCode;
	EndIf;
	
	vRateDate = Undefined;
	If TypeOf(pDocObj) = Type("FormDataStructure") And TypeOf(pDocObj.Ref) = Type("DocumentRef.Return") And ValueIsFilled(pDocObj.Payment) Then
		vRateDate = tcOnServer.cmGetAttributeByRef(pDocObj.Payment, "Date");
	EndIf;
	
	vVATRateParams = Undefined;
	If ValueIsFilled(vRateDate) Then
		 vVATRateParams = tcCashRegisters.GetVATRateParams(rVATRate, vRateDate);
	EndIf;
	
	If vVATRateParams <> Undefined Then
		vTaxRate = vVATRateParams.TaxRate;
		vNoVAT = vVATRateParams.NoVAT;
		vTaxGroup = vVATRateParams.TaxGroup;
	Else
		vTaxRate = tcOnServer.cmGetAttributeByRef(rVATRate, "TaxRate");
		vNoVAT = tcOnServer.cmGetAttributeByRef(rVATRate, "NoVAT");
		vTaxGroup = tcOnServer.cmGetAttributeByRef(rVATRate, "TaxGroup");
	EndIf;
	
	If vNoVAT Then
		vTaxGroupCode = 4;
	ElsIf vTaxRate = 0 Then
		vTaxGroupCode = 3;
	ElsIf vTaxRate = 5 Then
		If vTaxGroup > 4 Then
			vTaxGroupCode = 9;
		Else
			vTaxGroupCode = 7;
		EndIf;
	ElsIf vTaxRate = 7 Then
		If vTaxGroup > 4 Then
			vTaxGroupCode = 10;
		Else
			vTaxGroupCode = 8;
		EndIf;
	ElsIf vTaxRate = 10 Then
		If vTaxGroup > 4 Then
			vTaxGroupCode = 6;
		Else
			vTaxGroupCode = 2;
		EndIf;
	ElsIf vTaxRate = 20 Or vTaxRate = 18 Then
		If vTaxGroup > 4 Then
			vTaxGroupCode = 5;
		Else
			vTaxGroupCode = 1;
		EndIf;
	ElsIf vTaxRate = 22 Then
		If vTaxGroup > 4 Then
			vTaxGroupCode = 12;
		Else
			vTaxGroupCode = 11;
		EndIf;
	Else
		vTaxGroupCode = vTaxGroup;
	EndIf;
	Return vTaxGroupCode;
EndFunction // GetTaxGroup

// -----------------------------------------------------------------------------
Function GetTaxationSystemCode(pObj, rTaxSystem = Undefined)
	vTaxSystemDec = 0;
	rTaxSystem = Undefined;
	vPaymentSection = pObj.PaymentSection;
	If ValueIsFilled(vPaymentSection) Then
		rTaxSystem = tcOnServer.cmGetAttributeByRef(vPaymentSection, "TaxationSystem");
	ElsIf TypeOf(pObj.Ref) <> Type("DocumentRef.CustomerPayment") Then
		For Each vPaymentSectionRow In pObj.PaymentSections Do
			vPaymentSection = vPaymentSectionRow.PaymentSection;
			If vPaymentSectionRow.Sum <> 0 And ValueIsFilled(vPaymentSection) Then
				rTaxSystem = tcOnServer.cmGetAttributeByRef(vPaymentSection, "TaxationSystem");
				If ValueIsFilled(rTaxSystem) Then
					Break;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	If Not ValueIsFilled(rTaxSystem) And ValueIsFilled(pObj.Company) Then
		rTaxSystem = tcOnServer.cmGetAttributeByRef(pObj.Company, "TaxationSystem");
	EndIf;
	If ValueIsFilled(rTaxSystem) Then
		vTaxSystemByte = "00000000";
		If rTaxSystem = PredefinedValue("Enum.TaxationSystems.Common") Then
			vTaxSystemByte = "00000001";
		ElsIf rTaxSystem = PredefinedValue("Enum.TaxationSystems.SimplifiedIncome") Then
			vTaxSystemByte = "00000010";
		ElsIf rTaxSystem = PredefinedValue("Enum.TaxationSystems.SimplifiedIncomeMinusOutcome") Then
			vTaxSystemByte = "00000100";
		ElsIf rTaxSystem = PredefinedValue("Enum.TaxationSystems.UnifiedTaxOnImputedIncome") Then
			vTaxSystemByte = "00001000";
		ElsIf rTaxSystem = PredefinedValue("Enum.TaxationSystems.UnifiedAgriculturalTax") Then
			vTaxSystemByte = "00010000";
		ElsIf rTaxSystem = PredefinedValue("Enum.TaxationSystems.PatentTaxationSystem") Then
			vTaxSystemByte = "00100000";
		EndIf;
		vTaxSystemDec = Bin2Dec(vTaxSystemByte);
	EndIf;
	Return vTaxSystemDec;
EndFunction // GetTaxationSystemCode

// -----------------------------------------------------------------------------
Function CheckPaper(pFR, pFunction, rMessage)
	If pFR.ECRAdvancedMode = 0 Then
		Return True;
	ElsIf pFR.ECRAdvancedMode = 3 Then
		pFR.ContinuePrint();
		Return True;
	Else
		rMessage = pFR.ECRAdvancedModeDescription;
		tcOnServer.cmWriteLogEventAtServer(pFunction,  ,  ,  , "Mode: " + pFR.ECRAdvancedMode + ", description: " + rMessage);
		Return false;
	EndIf;
EndFunction // CheckPaper

// -----------------------------------------------------------------------------
Function GetString(pStr, pArrCashRegister)
	vChequeWidth = pArrCashRegister.ChequeWidth;
	If vChequeWidth > 0 Then
		Return Left(pStr, vChequeWidth);
	Else
		Return Left(pStr, 24);
	EndIf;
EndFunction // GetString

// -----------------------------------------------------------------------------
Procedure CloseOpenCheque(pFR, pArrCashRegister)
	If pFR.ECRMode = 8 Then
		// Close cheque with sys admin password
		pFR.ResetECR();
		If pFR.ResultCode = 89 Then
			vPassword = pFR.Password;
			If ValueIsFilled(pArrCashRegister.CashRegisterPassword) Then
				pFR.Password = TrimR(pArrCashRegister.CashRegisterPassword);
			ElsIf ValueIsFilled(pArrCashRegister.AccessPassword) Then
				pFR.Password = TrimR(pArrCashRegister.AccessPassword);
			EndIf;
			pFR.SysAdminCancelCheck();
			pFR.Password = vPassword;
			pFR.ResetECR();
		EndIf;
	EndIf;
EndProcedure // CloseOpenCheque

// -----------------------------------------------------------------------------
Procedure ProcessResultCode(pFR, pFunction, rMessage)
	vErrorMessage = rMessage;
	If pFR.ResultCode <> 0 Then
		rMessage = ?(Not IsBlankString(rMessage), rMessage + Chars.LF, "") + TrimAll(pFR.ResultCodeDescription);
		vErrorMessage = "Result code: " + pFR.ResultCode + ", result description: " + rMessage;
	EndIf;
	tcOnServer.cmWriteLogEventAtServer(pFunction, , , , vErrorMessage);
	Disconnect(pFR);
EndProcedure // ProcessResultCode

// -----------------------------------------------------------------------------
Procedure PrintSlipLines(pFR, pSlipTextArr, pArrCashRegister, pOneCopyOnly = False)
	vArrCashRegister = pArrCashRegister;
	pFR.UseJournalRibbon=0; 
	pFR.UseReceiptRibbon=1;
	// Print first slip for the hotel
	For Each vStr In pSlipTextArr Do
		pFR.StringForPrinting = GetString(vStr, vArrCashRegister);
		pFR.PrintString();
		If pFR.ResultCode <> 0 Then
			Return;
		EndIf;
	EndDo;
	If pOneCopyOnly Then
		pFR.StringQuantity = 4 + vArrCashRegister.NumberOfExtraLinesOfPaperRunBeforeCut;
		pFR.FeedDocument();
		pFR.CutType = True;
		pFR.CutCheck();
		// Print cliche
		pFR.PrintCliche();
		If pFR.ResultCode <> 0 Then
			pFR.StringForPrinting = Left(TrimAll(tcOnServer.cmGetAttributeByRef(vArrCashRegister.Owner, "LegacyName")), ?(vArrCashRegister.ChequeWidth=0, 24, vArrCashRegister.ChequeWidth));
			pFR.PrintString();
			pFR.StringForPrinting = Left(NStr("en='TIN/KPP '; ru='ИНН/КПП '; de='TIN/KPP '") + (TrimAll(tcOnServer.cmGetAttributeByRef(vArrCashRegister.Owner, "TIN")) + "/" + TrimAll(tcOnServer.cmGetAttributeByRef(vArrCashRegister.Owner, "KPP"))), ?(vArrCashRegister.ChequeWidth=0, 24, vArrCashRegister.ChequeWidth));
			pFR.PrintString();
			pFR.StringForPrinting = Left(NStr("en='WELKOME'; ru='ДОБРО ПОЖАЛОВАТЬ'; de='WELKOME'"), ?(vArrCashRegister.ChequeWidth=0, 24, vArrCashRegister.ChequeWidth));
			pFR.PrintString();
			pFR.StringForPrinting = Left("=======================================================================", ?(vArrCashRegister.ChequeWidth=0, 24, vArrCashRegister.ChequeWidth));
			pFR.PrintString();
		EndIf;
		Return;
	EndIf;
	// Print second slip for the client
	pFR.StringForPrinting = " ";
	pFR.PrintString();
	pFR.StringForPrinting = GetString("-8<--------------------------------------------------------------------",vArrCashRegister);
	pFR.PrintString();
	pFR.StringQuantity = 4 + vArrCashRegister.NumberOfExtraLinesOfPaperRunBeforeCut;
	pFR.FeedDocument();
	pFR.CutType = True;
	pFR.CutCheck();
	pFR.StringForPrinting = NStr("ru = 'ДЛЯ КЛИЕНТА'; en = 'FOR THE CLIENT'; de = 'FOR THE CLIENT'");
	pFR.PrintString();
	If pFR.ResultCode <> 0 Then
		Return;
	EndIf;
	// Print cliche
	pFR.PrintCliche();
	If pFR.ResultCode <> 0 Then
		pFR.StringForPrinting = Left(TrimAll(tcOnServer.cmGetAttributeByRef(vArrCashRegister.Owner, "LegacyName")), ?(vArrCashRegister.ChequeWidth=0, 24, vArrCashRegister.ChequeWidth));
		pFR.PrintString();
		pFR.StringForPrinting = Left(NStr("en='TIN/KPP '; ru='ИНН/КПП '; de='TIN/KPP '") + (TrimAll(tcOnServer.cmGetAttributeByRef(vArrCashRegister.Owner, "TIN")) + "/" + TrimAll(tcOnServer.cmGetAttributeByRef(vArrCashRegister.Owner, "KPP"))), ?(vArrCashRegister.ChequeWidth=0, 24, vArrCashRegister.ChequeWidth));
		pFR.PrintString();
		pFR.StringForPrinting = Left(NStr("en='WELKOME'; ru='ДОБРО ПОЖАЛОВАТЬ'; de='WELKOME'"), ?(vArrCashRegister.ChequeWidth=0, 24, vArrCashRegister.ChequeWidth));
		pFR.PrintString();
		pFR.StringForPrinting = Left("=======================================================================", ?(vArrCashRegister.ChequeWidth=0, 24, vArrCashRegister.ChequeWidth));
		pFR.PrintString();
	EndIf;
	For Each vStr In pSlipTextArr Do
		pFR.StringForPrinting = GetString(vStr, vArrCashRegister);
		pFR.PrintString();
		If pFR.ResultCode <> 0 Then
			Return;
		EndIf;
	EndDo;
	pFR.StringQuantity = 4 + vArrCashRegister.NumberOfExtraLinesOfPaperRunBeforeCut;
	pFR.FeedDocument();
	pFR.CutType = True;
	pFR.CutCheck();
	// Print cliche
	pFR.PrintCliche();
	If pFR.ResultCode <> 0 Then
		pFR.StringForPrinting = Left(TrimAll(tcOnServer.cmGetAttributeByRef(vArrCashRegister.Owner, "LegacyName")), ?(vArrCashRegister.ChequeWidth=0, 24, vArrCashRegister.ChequeWidth));
		pFR.PrintString();
		pFR.StringForPrinting = Left(NStr("en='TIN/KPP '; ru='ИНН/КПП '; de='TIN/KPP '") + (TrimAll(tcOnServer.cmGetAttributeByRef(vArrCashRegister.Owner, "TIN")) + "/" + TrimAll(tcOnServer.cmGetAttributeByRef(vArrCashRegister.Owner, "KPP"))), ?(vArrCashRegister.ChequeWidth=0, 24, vArrCashRegister.ChequeWidth));
		pFR.PrintString();
		pFR.StringForPrinting = Left(NStr("en='WELKOME'; ru='ДОБРО ПОЖАЛОВАТЬ'; de='WELKOME'"), ?(vArrCashRegister.ChequeWidth=0, 24, vArrCashRegister.ChequeWidth));
		pFR.PrintString();
		pFR.StringForPrinting = Left("=======================================================================", ?(vArrCashRegister.ChequeWidth=0, 24, vArrCashRegister.ChequeWidth));
		pFR.PrintString();
	EndIf;
EndProcedure // PrintSlipLines

// -----------------------------------------------------------------------------
Procedure PrintFolioHeader(pFR, pObj, pArrCashRegister)
	vArrCashRegister	= pArrCashRegister;
	vArrFolio			= tcOnServer.cmGetAtributeAsArray(pObj.Folio);
	pFR.UseJournalRibbon=0; 
	pFR.UseReceiptRibbon=1;
	// Header start delimeter
	pFR.StringForPrinting = GetString("-----------------------------------------------------------------------",vArrCashRegister);
	pFR.PrintString();
	// Folio #
	pFR.StringForPrinting = GetString(NStr("ru='Фолио № '; en='Folio # '; de='Folio # '") + tcOnServer.GetDocumentNumberPresentation(tcOnServer.cmGetAttributeByRef(pObj.Folio,"Number")),vArrCashRegister);
	pFR.PrintString();
	// Room
	If Not vArrCashRegister.DoNotPrintRoom Then
		pFR.StringForPrinting = GetString(NStr("en='Room  : ';ru='Номер : ';de='Zimmer: '") + TrimAll(vArrFolio.Room),vArrCashRegister); 
		pFR.PrintString();
	EndIf;
	// Guest
	If Not vArrCashRegister.DoNotPrintClient Then
		If (TypeOf(pObj.Ref) = Type("DocumentRef.Payment") Or TypeOf(pObj.Ref) = Type("DocumentRef.Return")) And ValueIsFilled(pObj.Payer) Then
			pFR.StringForPrinting = GetString(NStr("en='Client: ';ru='Клиент: ';de='Kunde : '") + TrimAll(pObj.Payer),vArrCashRegister); 
		Else
			pFR.StringForPrinting = GetString(NStr("en='Client: ';ru='Клиент: ';de='Kunde : '") + TrimAll(vArrFolio.Client),vArrCashRegister);
		EndIf;
		pFR.PrintString();
	EndIf;
	// Guest group
	pFR.StringForPrinting = GetString(NStr("en='Group : ';ru='Группа: ';de='Gruppe: '") + TrimAll(pObj.GuestGroup),vArrCashRegister);  
	pFR.PrintString();
	// Document
	pFR.StringForPrinting = GetString(NStr("ru = 'Док.  № '; en='Doc.  # '; de='Dok.  Nr. '") + tcOnServer.GetDocumentNumberPresentation(TrimAll(pObj.Number)),vArrCashRegister);
	pFR.PrintString();
	// Header end delimeter
	pFR.StringForPrinting = GetString("-----------------------------------------------------------------------",vArrCashRegister); 
	pFR.PrintString();
EndProcedure // PrintFolioHeader

// -----------------------------------------------------------------------------
Procedure CancelCheque(pFR, pFunction, rMessage)
	vErrorMessage = rMessage;
	If pFR.ResultCode <> 0 Then
		rMessage = ?(Not IsBlankString(rMessage), rMessage + Chars.LF, "") + TrimAll(pFR.ResultCodeDescription);
		vErrorMessage = "Result code: " + pFR.ResultCode + ", result description: " + rMessage;
	EndIf;
	tcOnServer.cmWriteLogEventAtServer(pFunction,,,, vErrorMessage);
	Try
		pFR.FNCancelDocument();
	Except
	EndTry;
	Disconnect(pFR);
EndProcedure // CancelCheque

// -----------------------------------------------------------------------------
Procedure ProcessException(pFR, pFunction, rMessage)
	tcOnServer.cmWriteLogEventAtServer(pFunction,,,, "Error description: " + rMessage);
	Disconnect(pFR);
EndProcedure // ProcessException

// -----------------------------------------------------------------------------
Function CheckTimeDifference(pFR, rMessage)
	// Check time difference between workstation and cash register and correct 
	// device time if difference is more then 5 minutes
	pFR.GetECRStatus();
	If CheckResultCode(pFR.ResultCode) Then
		vFRDate = pFR.Date;
		vFRDate = vFRDate + Number(Left(pFR.TimeStr, 2)) * 3600 + Number(Mid(pFR.TimeStr, 4, 2)) * 60 + Number(Mid(pFR.TimeStr, 7, 2));
		If BegOfDay(CurrentDate()) = BegOfDay(vFRDate) Then
			vTimeDiff = CurrentDate() - vFRDate;
			If vTimeDiff < 0 Then 
				vTimeDiff = -vTimeDiff;
			EndIf;
			If vTimeDiff > 300 Then // > 5 minutes
				// Set current time
				Return SetDeviceTime(pFR, rMessage);
			EndIf;
		Else
			// Date is different, need to set correct date manually
			rMessage = NStr("en='Check date in the cash register!'; de='Check date in the cash register!'; ru='Проверьте дату в ККМ!'");
			ProcessException(pFR, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), rMessage);
			Return False;
		EndIf;
	Else
		ProcessResultCode(pFR, NStr("en='CashRegister.CheckTimeDifference'; de='CashRegister.CheckTimeDifference'; ru='ККМ.ПроверкаВремени'"), rMessage);
		Return False;
	EndIf;
	Return True;
EndFunction // CheckTimeDifference

// -----------------------------------------------------------------------------
Function SetDeviceTime(pFR, rMessage)
	pFR.GetECRStatus();
	If CheckResultCode(pFR.ResultCode) Then
		If pFR.ECRAdvancedMode = 5 Then
			tcOnServer.Wait(5);
			pFR.GetECRStatus();
			If CheckResultCode(pFR.ResultCode) Then
				If pFR.ECRAdvancedMode = 5 Then
					tcOnServer.Wait(5);	
				EndIf;
			Else
				ProcessResultCode(pFR, NStr("en='CashRegister.CheckTimeDifference'; de='CashRegister.CheckTimeDifference'; ru='ККМ.ПроверкаВремени'"), rMessage);
				Return False;		
			EndIf;
		EndIf;
	Else
		ProcessResultCode(pFR, NStr("en='CashRegister.CheckTimeDifference'; de='CashRegister.CheckTimeDifference'; ru='ККМ.ПроверкаВремени'"), rMessage);
		Return False;	
	EndIf;
	vCurDate = tcOnServer.cmGetServerCurrentSessionDate();
	
	// Set device date
	pFR.Date = BegOfDay(vCurDate);
	pFR.SetDate();
	If Not CheckResultCode(pFR.ResultCode) Then
		ProcessResultCode(pFR, NStr("en='CashRegister.SetDeviceTime'; de='CashRegister.SetDeviceTime'; ru='ККМ.УстановкаВремени'"), rMessage);
		Return False;
	Else
		// Get ECR mode to check do we need to confirm date change
		pFR.GetShortECRStatus();
		If Not CheckResultCode(pFR.ResultCode) Then
			ProcessResultCode(pFR, NStr("en='CashRegister.SetDeviceTime'; de='CashRegister.SetDeviceTime'; ru='ККМ.УстановкаВремени'"), rMessage);
			Return False;
		Else
			If pFR.ECRMode = 6 Then
				// Confirm date change
				pFR.ConfirmDate();
				If Not CheckResultCode(pFR.ResultCode) Then
					ProcessResultCode(pFR, NStr("en='CashRegister.SetDeviceTime'; de='CashRegister.SetDeviceTime'; ru='ККМ.УстановкаВремени'"), rMessage);
					Return False;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	// Set device time
	pFR.Time = BegOfDay(pFR.Time) + ((Hour(vCurDate) * 3600) + (Minute(vCurDate) * 60) + (Second(vCurDate))); 
	pFR.SetTime();
	If Not CheckResultCode(pFR.ResultCode) Then
		ProcessResultCode(pFR, NStr("en='CashRegister.SetDeviceTime'; de='CashRegister.SetDeviceTime'; ru='ККМ.УстановкаВремени'"), rMessage);
		Return False;
	EndIf;
	Return True;
EndFunction // SetDeviceTime

// -----------------------------------------------------------------------------
Function CheckResultCode(pResultCode)
	If pResultCode <> 0 Then
		Return False;
	Else
		Return True;
	EndIf;
EndFunction // Not CheckResultCode

// -----------------------------------------------------------------------------
Function CheckMarkingCode(pFR, pIsPayment, pService, pMarkingCode, pCancelReceiptPrintingWhenMarkingCheckError, rMessage)
	pFR.BarCode = GetStringFromBinaryData(Base64Value(pMarkingCode)); 
	pFR.ItemStatus = GetMarkingCodeStatus(pFR, pIsPayment, pService); 
	pFR.CheckItemMode = 0;
	pFR.TLVDataHex = "";
	pFR.FNCheckItemBarcode();
	
	If pFR.KMServerCheckingStatus <> 15 And pCancelReceiptPrintingWhenMarkingCheckError Then
		rMessage = StrTemplate(
			NStr("en = 'The marking code did not pass the check:
			|Service: %1
			|Marking Code: %2'; de = 'Der Markierungscode hat die Überprüfung nicht bestanden:
			|Dienst: %1
			|Markierungscode: %2'; ru = 'Код маркировка не прошел проверку:
			|Услуга: %1
			|Код Маркировки: %2'"), 
			TrimAll(pService), 
			pMarkingCode);
		pFR.FNDeclineMarkingCode();
		Return False;
	EndIf;
	
	pFR.FNAcceptMarkingCode();
	Return True;
EndFunction // CheckMarkingCode

// -----------------------------------------------------------------------------
Function GetMarkingCodeStatus(pFR, pIsPayment, pService)
	If pIsPayment Then 
		If CheckUnitPiece(pService) Then
			Return 1;
		Else
			Return 2;
		EndIf;
	Else
		If CheckUnitPiece(pService) Then
			Return 3;
		Else
			Return 4;
		EndIf;
	EndIf;
EndFunction // GetMarkingCodeStatus

// -----------------------------------------------------------------------------
Function CheckUnitPiece(pService)
	vSUnit = tcOnServer.cmGetAttributeByRef(pService, "Unit");
	Return TrimAll(PredefinedValue("Catalog.Units.Piece")) = vSUnit Or IsBlankString(vSUnit);
EndFunction // CheckUnitPiece

// -----------------------------------------------------------------------------
Function GetUnitPiece(pService)
	If ValueIsFilled(pService) Then
		vSUnit = tcOnServer.cmGetAttributeByRef(pService, "Unit");
		If IsBlankString(vSUnit) Or TrimAll(PredefinedValue("Catalog.Units.Piece")) = vSUnit Then
			Return 0;
		ElsIf TrimAll(PredefinedValue("Catalog.Units.Gram")) = vSUnit Then
			Return 10;
		ElsIf TrimAll(PredefinedValue("Catalog.Units.Kilogram")) = vSUnit Then
			Return 11;
		ElsIf TrimAll(PredefinedValue("Catalog.Units.Litre")) = vSUnit Then
			Return 41;
		ElsIf TrimAll(PredefinedValue("Catalog.Units.Mililitre")) = vSUnit Then
			Return 40;
		ElsIf TrimAll(PredefinedValue("Catalog.Units.Night")) = vSUnit Then
			Return 70;
		ElsIf TrimAll(PredefinedValue("Catalog.Units.Minute")) = vSUnit Then
			Return 72;
		ElsIf TrimAll(PredefinedValue("Catalog.Units.Hour")) = vSUnit Then
			Return 71;
		ElsIf TrimAll(PredefinedValue("Catalog.Units.Megabyte")) = vSUnit Then
			Return 81;
		Else
			Return 0;
		EndIf;
	Else
		Return 255;
	EndIf;
EndFunction // GetUnitPiece

// -----------------------------------------------------------------------------
Procedure SetIndustryInfo(pFR, pIsPayment, pPaymentMode, pChargesWithMarkingCode, pMarkingCode)
	vFullSettlement = 4;
	vPartialSettlementAndCredit = 5;
	vTransferToCredit = 6;
	
	If (pPaymentMode <> vFullSettlement And pPaymentMode <> vPartialSettlementAndCredit And pPaymentMode <> vTransferToCredit) Or Not pIsPayment Or IsBlankString(pMarkingCode) Or pChargesWithMarkingCode[pMarkingCode] = Undefined Then
		Return;
	EndIf;
	
	vChargeWithMarkingCode = pChargesWithMarkingCode[pMarkingCode];
	If IsBlankString(vChargeWithMarkingCode["MarkingCodeCheckUUID"]) Or IsBlankString(vChargeWithMarkingCode["MarkingCodeCheckDate"]) Then
		Return;
	EndIf;
	
	pFR.TagNumber = 1262;
	pFR.TagType = 7;
	pFR.TagValueStr = "030";
	pFR.FNSendTagOperation();
	
	pFR.TagNumber = 1263;
	pFR.TagType = 7;
	pFR.TagValueStr = "21.11.2023";
	pFR.FNSendTagOperation();
	
	pFR.TagNumber = 1264;
	pFR.TagType = 7;
	pFR.TagValueStr = "1944";
	pFR.FNSendTagOperation();
	
	pFR.TagNumber = 1265;
	pFR.TagType = 7;
	pFR.TagValueStr = StrTemplate("UUID=%1&Time=%2", TrimAll(vChargeWithMarkingCode["MarkingCodeCheckUUID"]), TrimAll(vChargeWithMarkingCode["MarkingCodeCheckDate"]));
	pFR.FNSendTagOperation();
EndProcedure // SetIndustryInfo

// -----------------------------------------------------------------------------
Procedure DisableMapping22(pFR, pArrCashRegister)
	vPassword = pFR.Password;
	If ValueIsFilled(pArrCashRegister.CashRegisterPassword) Then
		pFR.Password = TrimR(pArrCashRegister.CashRegisterPassword);
	ElsIf ValueIsFilled(pArrCashRegister.AccessPassword) Then
		pFR.Password = TrimR(pArrCashRegister.AccessPassword);
	EndIf;
	
	pFR.TableNumber = 17;
	pFR.RowNumber = 1;
	pFR.FieldNumber = 71;
	pFR.ValueOfFieldInteger = 2;
	pFR.WriteTable();
	
	pFR.Password = vPassword;
EndProcedure // DisableMapping22

// -----------------------------------------------------------------------------
Function pmPrintCheque_BeforeOpenCheque(vFR, vArrCashRegister, Val pSum, Val pVATSum, pObj, pObjRef, rMessage, pPasswordKKM="", pServices = Undefined, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101', pSendPayerContactsToOFD = 0, pEmailToSendToOFD = "", pPhoneToSendToOFD = "")
	// Put code in extension of this function if necessary
	Return True;
EndFunction // pmPrintCheque_BeforeOpenCheque

// -----------------------------------------------------------------------------
Function pmPrintCheque_AfterOpenCheque(vFR, vArrCashRegister, vChargesWithMarkingCode, Val pSum, Val pVATSum, pObj, pObjRef, rMessage, pPasswordKKM="", pServices = Undefined, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101', pSendPayerContactsToOFD = 0, pEmailToSendToOFD = "", pPhoneToSendToOFD = "")
	// Put code in extension of this function if necessary
	Return True;
EndFunction // pmPrintCheque_AfterOpenCheque

// -----------------------------------------------------------------------------
Function pmPrintCheque_BeforeCloseCheque(vFR, vArrCashRegister, vChargesWithMarkingCode, Val pSum, Val pVATSum, pObj, pObjRef, rMessage, pPasswordKKM="", pServices = Undefined, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101', pSendPayerContactsToOFD = 0, pEmailToSendToOFD = "", pPhoneToSendToOFD = "")
	// Put code in extension of this function if necessary
	Return True;
EndFunction // pmPrintCheque_BeforeCloseCheque

// -----------------------------------------------------------------------------
Function pmPrintCheque_AfterCloseCheque(vFR, vArrCashRegister, vChargesWithMarkingCode, vOpenDrawer, Val pSum, Val pVATSum, pObj, pObjRef, rMessage, pPasswordKKM="", pServices = Undefined, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101', pSendPayerContactsToOFD = 0, pEmailToSendToOFD = "", pPhoneToSendToOFD = "")
	// Put code in extension of this function if necessary
	Return True;
EndFunction // pmPrintCheque_AfterCloseCheque

// -----------------------------------------------------------------------------
Function pmPrintCheque_BeforeChequePositionRegistration(vFR, vArrCashRegister, vChargesWithMarkingCode, pRow = Undefined, Val pSum, Val pVATSum, pObj, pObjRef, rMessage, pPasswordKKM="", pServices = Undefined, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101', pSendPayerContactsToOFD = 0, pEmailToSendToOFD = "", pPhoneToSendToOFD = "")
	// Put code in extension of this function if necessary
	Return True;
EndFunction // pmPrintCheque_BeforeChequePositionRegistration

// -----------------------------------------------------------------------------
Function pmPrintCheque_AfterChequePositionRegistration(vFR, vArrCashRegister, vChargesWithMarkingCode, pRow = Undefined, Val pSum, Val pVATSum, pObj, pObjRef, rMessage, pPasswordKKM="", pServices = Undefined, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101', pSendPayerContactsToOFD = 0, pEmailToSendToOFD = "", pPhoneToSendToOFD = "")
	// Put code in extension of this function if necessary
	Return True;
EndFunction // pmPrintCheque_BeforeChequePositionRegistrartion

// --------------------------------------------------------------------------------
Function FillAdditionalAttributes(pFR, pObj, pArrCashRegister)
	vPassword = pFR.Password;
	If ValueIsFilled(pArrCashRegister.CashRegisterPassword) Then
		pFR.Password = TrimR(pArrCashRegister.CashRegisterPassword);
	ElsIf ValueIsFilled(pArrCashRegister.AccessPassword) Then
		pFR.Password = TrimR(pArrCashRegister.AccessPassword);
	EndIf;
	
	If pFR.FNGetStatus() <> 0 Then
		Return False;
	EndIf;
	
	vFiscalStorageFactoryNumber = pFR.SerialNumber;
	vChequeSequenceNumber = pFR.DocumentNumber;
	vChequeSequenceNumber = vChequeSequenceNumber + 1;
	
	If pFR.FNGetCurrentSessionParams() <> 0 Then
		Return False;
	EndIf;
	
	pFR.Password = vPassword;
	
	vCashDay = pFR.SessionNumber;
	
	If pFR.FNSessionState = 0 Then
		vChequeSequenceNumber = vChequeSequenceNumber + 1;
		vCashDay = vCashDay + 1;
	EndIf;
	
	pArrCashRegister.Insert("AddAttribute_FiscalStorageFactoryNumber", vFiscalStorageFactoryNumber);
	pArrCashRegister.Insert("AddAttribute_ChequeSequenceNumber", vChequeSequenceNumber);
	pArrCashRegister.Insert("AddAttribute_CashDay", vCashDay);
	
	Return True;
EndFunction // FillAdditionalAttributes

#EndRegion