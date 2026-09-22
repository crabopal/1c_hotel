
#Region Public

// -----------------------------------------------------------------------------
Function pmPrintCheque(Val pSum, Val pVATSum, pObj, pObjRef, rMessage, pPasswordKKM="", pServices = Undefined, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101', pSendPayerContactsToOFD = 0, pEmailToSendToOFD = "", pPhoneToSendToOFD = "") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pObj.CashRegister);
	vArrPaymentMethod = tcOnServer.cmGetAtributeAsArray(pObj.PaymentMethod);
	vIsPrepayment = False;
	// Try to connect
	vFR = Connect(rMessage, vArrCashRegister);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Close open cheque if any
			CloseOpenCheque(vFR, pPasswordKKM, vArrCashRegister.DoNotOpenNewSessionAfterZReport, vArrCashRegister.IgnoreEndOfPaperError);
			
			If Not FillAdditionalAttributes(vFR, pObj, vArrCashRegister) Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			
			// Print slip if payment was made by credit card
			If vArrCashRegister.PrintSlipInCheque Then
				If ValueIsFilled(pObj.SlipText) Then
					If Not PrintSlipLines(vFR, tcOnServer.GetTextLinesArray(pObj.SlipText), vArrCashRegister, rMessage) Then
						Return False;
					EndIf;
				EndIf;
			EndIf;
			
			vVersion = vFR.version();
			
			// Initialize cheque attributes used to send online cheque by sms or e-mail
			vChequeAttributes = tcCashRegisters.InitializeChequeAttributes(pObj, pObjRef, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate);
			
			// Extra functions for extensions
			vTLVArray = New Array;
			If Not pmPrintCheque_BeforeOpenChequeTLV(vFR, vArrCashRegister, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD, vTLVArray) Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			
			vCorrectionInfo = Undefined;
			If pIsCorrection Then
				vCorrectionDocumentDate = ?(ValueIsFilled(pCorrectionDocumentDate), BegOfDay(pCorrectionDocumentDate), ?(pObj.CorrectionOfIncorrectCheque And ValueIsFilled(pObj.Payment), tcOnServer.cmGetAttributeByRef(pObj.Payment, "Date"), '00010101'));
				If ValueIsFilled(vCorrectionDocumentDate) Then
					vFR.setParam(1178, vCorrectionDocumentDate - '19700101');
					vChequeAttributes.CorrectionDocumentDate = vCorrectionDocumentDate;
				Else
					rMessage = NStr("en='The date of the corrected payment is not specified (the date when the wrong cheque was posted)!'; 
					|ru='Не указана дата совершения корректируемого расчета (дата, когда пробит неверный чек)!'; 
					|de='Das Datum der korrigierten Zahlung ist nicht angegeben (das Datum, an dem der falsche Scheck gebucht wurde)!'");
					Return False;
				EndIf;
				
				vCorrectionDocumentNumber = TrimAll(TrimAll(pCorrectionDescription) + ?(IsBlankString(pCorrectionDocumentNumber), "", " №" + TrimAll(pCorrectionDocumentNumber)));
				vFR.setParam(1179, Right(vCorrectionDocumentNumber, 32));
				vChequeAttributes.CorrectionDocumentNumber = vCorrectionDocumentNumber;
				
				vFR.utilFormTlv();
				vCorrectionInfo = vFR.getParamByteArray(vFR.LIBFPTR_PARAM_TAG_VALUE);
			EndIf;
			
			// Payer name and TIN
			vPayerInfo = Undefined;
			If vArrCashRegister.FiscalDataFormatVersions = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2") Then
				vPayerName = "";
				vPayerTIN = "";
				tcOnServer.GetPayerNameAndTIN(pObj.AccountingCustomer, vPayerName, vPayerTIN);
				If ValueIsFilled(vPayerTIN) And ValueIsFilled(vPayerName) Then
					vFR.setParam(1227, vPayerName);
					vFR.setParam(1228, ?(StrLen(vPayerTIN) = 10, vPayerTIN + "  ", vPayerTIN));
					vFR.utilFormTlv();
					vPayerInfo = vFR.getParamByteArray(vFR.LIBFPTR_PARAM_TAG_VALUE); 
				EndIf;
			EndIf;
			
			// Set cashier name
			vCashier = pObj.Author;
			If ValueIsFilled(vCashier) Then
				vCashierName = tcCashRegisters.GetCashierName(vCashier);
				If Not IsBlankString(vCashierName) Then
					vFR.setParam(1021, vCashierName);
					vChequeAttributes.CashierName = vCashierName;
					
					// Set TIN
					vEmployeeTIN = TrimAll(tcOnServer.cmGetAttributeByRef(vCashier, "TIN"));
					If Not IsBlankString(vEmployeeTIN) Then
						vFR.setParam(1203, vEmployeeTIN);
					EndIf;
				EndIf;
			EndIf;
			vFR.operatorLogin();
			
			vIsPayment = False;
			
			// Open cheque
			If Not pIsCorrection Then
				If pSum < 0 Or pSum = 0 And TypeOf(pObjRef) = Type("DocumentRef.Return") Then
					vFR.setParam(vFR.LIBFPTR_PARAM_RECEIPT_TYPE, vFR.LIBFPTR_RT_SELL_RETURN);
				Else
					vFR.setParam(vFR.LIBFPTR_PARAM_RECEIPT_TYPE, vFR.LIBFPTR_RT_SELL);
					vIsPayment = True;
				EndIf;
			Else
				If pSum < 0 Or pSum = 0 And TypeOf(pObjRef) = Type("DocumentRef.Return") Then
					vFR.setParam(vFR.LIBFPTR_PARAM_RECEIPT_TYPE, vFR.LIBFPTR_RT_SELL_RETURN_CORRECTION);
				Else
					vFR.setParam(vFR.LIBFPTR_PARAM_RECEIPT_TYPE, vFR.LIBFPTR_RT_SELL_CORRECTION);
					vIsPayment = True;
				EndIf;
			EndIf;
			If ValueIsFilled(pObj.PaymentMethod) And tcOnServer.cmGetAttributeByRef(pObj.PaymentMethod, "ElectronicChequeOnly") Then
				vFR.setParam(vFR.LIBFPTR_PARAM_RECEIPT_ELECTRONICALLY, True);
			Else
				vFR.setParam(vFR.LIBFPTR_PARAM_RECEIPT_ELECTRONICALLY, False);
			EndIf;
			
			// Set correction type
			vChequeAttributes.IsCorrection = pIsCorrection;
			If pIsCorrection Then
				vFR.setParam(1173, ?(pCorrectionType = PredefinedValue("Enum.CorrectionChequeTypes.ByOrder"), 1, 0));
				vChequeAttributes.CorrectionType = pCorrectionType;
				If vCorrectionInfo <> Undefined Then
					vFR.setParam(1174, vCorrectionInfo);
				EndIf;
			EndIf;
			
			// Print FPD of the base cheque if return
			If pObj.CorrectionOfIncorrectCheque Then
				vPayment = pObj.Payment;
				If ValueIsFilled(vPayment) Then
					// Get payment cheque attributes
					vPaymentAttrs = tcCashRegisters.GetChequeAttributes(vPayment);
					If vPaymentAttrs <> Undefined And Not IsBlankString(vPaymentAttrs.ChequeFiscalNumber) Then
						vFR.setParam(1192, TrimAll(vPaymentAttrs.ChequeFiscalNumber));
					EndIf;
				EndIf;
			EndIf;
			
			// Set taxation system
			vTaxSystem = Undefined;
			vTaxSystemName = GetTaxationSystemCode(pObj, vTaxSystem);
			If ValueIsFilled(vTaxSystemName) Then
				vTaxSystemCode = Undefined;
				Execute("vTaxSystemCode = vFR." + TrimAll(vTaxSystemName) + ";");
				If vTaxSystemCode <> Undefined Then 
					vFR.setParam(1055, vTaxSystemCode);
					vChequeAttributes.TaxationSystem = vTaxSystem;
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
					EndIf;
					If ValueIsFilled(vPayer) Then
						If TypeOf(vPayer) = Type("CatalogRef.Clients") Or TypeOf(vPayer) = Type("CatalogRef.Customers") Then
							vEMail = TrimAll(tcOnServer.cmGetAttributeByRef(vPayer, "EMail"));
						EndIf;
					EndIf;
				EndIf;
				If ValueIsFilled(vEMail) And tcCommonFunctionOnClientServer.CheckEmail(vEMail, , False) And tcCashRegisters.CheckEMailsBlackList(vEMail) Then
					vFR.setParam(1008, vEMail);
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
					EndIf;
					If ValueIsFilled(vPayer) Then
						If TypeOf(vPayer) = Type("CatalogRef.Clients") Or TypeOf(vPayer) = Type("CatalogRef.Customers") Then
							vPhone = TrimAll(tcOnServer.cmGetAttributeByRef(vPayer, "Phone"));
						EndIf;
					EndIf;
				EndIf;
				vPhone = TrimAll(SMS.GetValidPhoneNumber(vPhone));
				If ValueIsFilled(vPhone) Then
					vFR.setParam(1008, SMS.GetPhoneNumberWithCountryCode(vPhone));
				EndIf;	
			EndIf;
			
			If vArrCashRegister.FiscalDataFormatVersions = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2") Then
				If vPayerInfo <> Undefined Then
					vFR.setParam(1256, vPayerInfo);	
				EndIf;
			Else
				// Payer name and TIN
				vPayerName = "";
				vPayerTIN = "";
				tcOnServer.GetPayerNameAndTIN(pObj.AccountingCustomer, vPayerName, vPayerTIN);
				If ValueIsFilled(vPayerTIN) And ValueIsFilled(vPayerName) Then
					vFR.setParam(1227, vPayerName);
					vFR.setParam(1228, ?(StrLen(vPayerTIN) = 10, vPayerTIN + "  ", vPayerTIN));
				EndIf;
			EndIf;
			
			If vVersion >= "10.10.7.0" Then
				If vArrPaymentMethod.IsViaInternetAcquiring Then
					vFR.setParam(1125, True);
					
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
					
					vFR.setParam(1187, vHotelSite);
				Else
					vFR.setParam(1125, False);
				EndIf;
			EndIf;
			
			For Each vTLVRow In vTLVArray Do
				vFR.setParam(vTLVRow.Tag, vTLVRow.Value);
			EndDo;
			
			// Extra functions for extensions
			If Not pmPrintCheque_BeforeOpenCheque(vFR, vArrCashRegister, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD) Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			
			If vFR.openReceipt() <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			
			vChargesWithMarkingCode = tcCashRegisters.GetChargesWithMarkingCode(pObj.Folio);
			vContainsMarkingCodes = False;
			
			// Extra functions for extensions
			vTLVArray = New Array;
			If Not pmPrintCheque_AfterOpenChequeTLV(vFR, vArrCashRegister, vChargesWithMarkingCode, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD, vTLVArray) Then
				CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			
			If vArrCashRegister.FiscalDataFormatVersions = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2") Then
				vFR.cancelMarkingCodeValidation();
				vFR.clearMarkingCodeValidationResult();
			EndIf;
			
			// Cheque folio header
			If vArrCashRegister.PrintFolioHeader Then
				PrintFolioHeader(vFR, pObj, vArrCashRegister);
			EndIf;
			
			For Each vTLVRow In vTLVArray Do
				vFR.setParam(vTLVRow.Tag, vTLVRow.Value);
			EndDo;
			
			// Extra functions for extensions
			If Not pmPrintCheque_AfterOpenCheque(vFR, vArrCashRegister, vChargesWithMarkingCode, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD) Then
				CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			
			// Print services
			If Not pIsCorrection Or pIsCorrection And vArrCashRegister.FiscalDataFormatVersions <> PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_0_5") Then
				If Not vArrCashRegister.DoNotPrintKioskServices AND pServices <> Undefined And pServices.Count() > 0 Then
					// No advances if services came from kiosk
					For Each vSrvRow In pServices Do
						// Begin format 1.05 item 
						// Commissioner mark
						
						// Extra functions for extensions
						vTLVArray = New Array;
						If Not pmPrintCheque_BeforeChequePositionRegistrationTLV(vFR, vArrCashRegister, vChargesWithMarkingCode, vSrvRow, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD, vTLVArray) Then
							CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
							Return False;
						EndIf;
						
						vPaymentModeTypeValue = tcCashRegisters.GetChequePaymentModeTypeValue(tcCashRegisters.GetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection));
						If ValueIsFilled(vSrvRow.Service) Then
							vIsHonestMark = False;
							If Not IsBlankString(vSrvRow.MarkingCode) Then
								vIsHonestMark = tcCashRegisters.CheckMarkingCodeByType(vSrvRow.Service, PredefinedValue("Enum.MarkingCodeTypes.HonestMark"));
							EndIf;
							
							vIndustryInfo = Undefined;
							If Not IsBlankString(vSrvRow.MarkingCode) And vIsHonestMark Then
								vIndustryInfo = GetIndustryInfo(vFR, vIsPayment, vPaymentModeTypeValue, vChargesWithMarkingCode, vSrvRow.MarkingCode);
							EndIf;
							
							vMKStatus = Undefined;
							vValidationResult = Undefined;
							If Not IsBlankString(vSrvRow.MarkingCode) And vIsHonestMark Then
								vValidationResult = CheckMarkingCode(vFR, TypeOf(pObj.Ref) = Type("DocumentRef.Payment"), vSrvRow.Service, vSrvRow.MarkingCode, vMKStatus, vArrCashRegister.CancelReceiptPrintingWhenMarkingCheckError, vArrCashRegister.MarkingCodeVerificationTimeout, rMessage);
								If vValidationResult = Undefined Then
									OnlyCancelCheque(vFR);
									Return False;
								EndIf;
							EndIf;
							
							vIsAgentService = tcOnServer.cmGetAttributeByRef(vSrvRow.Service, "IsAgentService");
							If vIsAgentService Then
								// Principal
								vPrincipal = tcOnServer.cmGetAttributeByRef(vSrvRow.Service, "Principal");
								If ValueIsFilled(vPrincipal) Then
									vPrincipalTIN = TrimAll(tcOnServer.cmGetAttributeByRef(vPrincipal, "TIN"));
									vPrincipalName = TrimAll(tcOnServer.cmGetAttributeByRef(vPrincipal, "LegacyName"));
									vPrincipalPhone = TrimAll(tcOnServer.cmGetAttributeByRef(vPrincipal, "Phone"));
									vSuplierInfo = Undefined;
									If ValueIsFilled(vPrincipalName) And ValueIsFilled(vPrincipalPhone) Then
										vFR.setParam(1225, vPrincipalName);
										vFR.setParam(1171, SMS.GetPhoneNumberWithCountryCode(vPrincipalPhone));
										vFR.utilFormTlv();
										vSuplierInfo = vFR.getParamByteArray(vFR.LIBFPTR_PARAM_TAG_VALUE);
									EndIf;
									If ValueIsFilled(vPrincipalTIN) Then
										vFR.setParam(1226, ?(StrLen(vPrincipalTIN) = 10, vPrincipalTIN + "  ", vPrincipalTIN));
									EndIf;
									If vSuplierInfo <> Undefined Then 
										vFR.setParam(1224, vSuplierInfo);
									EndIf;
								EndIf;
								// Commissioner attribute
								If tcOnServer.cmGetAttributeByRef(vSrvRow.Service, "PrincipalType") = 1 Then
									vFR.setParam(1222, vFR.LIBFPTR_AT_ANOTHER); // Other agent
								Else
									vFR.setParam(1222, vFR.LIBFPTR_AT_COMMISSION_AGENT); // Commission agent
								EndIf;
							EndIf;
							If vValidationResult <> Undefined And vMKStatus <> Undefined Then
								vContainsMarkingCodes = True;
								If vIndustryInfo <> Undefined Then
									vFR.setParam(1260, vIndustryInfo);
								EndIf;
								vFR.setParam(vFR.LIBFPTR_PARAM_MARKING_CODE, GetStringFromBinaryData(Base64Value(vSrvRow.MarkingCode)));
								vFR.setParam(vFR.LIBFPTR_PARAM_MARKING_CODE_STATUS, vMKStatus);
								vFR.setParam(vFR.LIBFPTR_PARAM_MARKING_CODE_ONLINE_VALIDATION_RESULT, vValidationResult);
								vFR.setParam(vFR.LIBFPTR_PARAM_MARKING_PROCESSING_MODE, 0);
							Else
								// Item code
								vCashRegisterItemCode = TrimAll(tcOnServer.cmGetAttributeByRef(vSrvRow.Service, "CashRegisterItemCode"));
								If Not IsBlankString(vCashRegisterItemCode) Then  
									If vArrCashRegister.FiscalDataFormatVersions = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2") Then
										vFR.setParam(vFR.LIBFPTR_PARAM_PRODUCT_CODE, vCashRegisterItemCode);	
									Else
										vFR.setParamStrHex(1162, tcCashRegisters.GetHexItemCode(vCashRegisterItemCode));
									EndIf;
								EndIf;
							EndIf;
						EndIf;
						vFR.setParam(vFR.LIBFPTR_PARAM_CHECK_SUM, False);
						vFR.setParam(vFR.LIBFPTR_PARAM_TAX_MODE, vFR.LIBFPTR_TM_POSITION);
						// Fill item attributes
						vPaymentSection = Undefined;
						vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, 0);
						vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, "");
						If ValueIsFilled(vSrvRow.Service) Then
							vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, GetString(tcOnServer.cmGetServiceDescription(vSrvRow.Service), vArrCashRegister));
							vPaymentSection = tcOnServer.cmGetAttributeByRef(vSrvRow.Service, "PaymentSection");
							If ValueIsFilled(vPaymentSection) Then
								vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, tcOnServer.cmGetAttributeByRef(vPaymentSection, "Code"));
							EndIf;
						EndIf;
						vFR.setParam(vFR.LIBFPTR_PARAM_POSITION_SUM, vSrvRow.Amount);
						vItemPrice = vSrvRow.Price;
						vItemQuantity = vSrvRow.Quantity;
						tcCashRegisters.ChequeItemAttributesCorrection(vSrvRow.Amount, vItemQuantity, 3, vItemPrice, vItemQuantity);
						vFR.setParam(vFR.LIBFPTR_PARAM_PRICE, vItemPrice);
						vFR.setParam(vFR.LIBFPTR_PARAM_QUANTITY, vItemQuantity);
						
						// Add tax
						vVATRate = Undefined;
						If ValueIsFilled(vPaymentSection) Then
							Execute("vFR.setParam(vFR.LIBFPTR_PARAM_TAX_TYPE, vFR." + GetTaxGroup(vPaymentSection, vVATRate, vSrvRow.VATRate, pObj) + ");");
						Else
							Execute("vFR.setParam(vFR.LIBFPTR_PARAM_TAX_TYPE, vFR." + GetTaxGroup(pObj, vVATRate, vSrvRow.VATRate, pObj) + ");");
						EndIf;
						tcCashRegisters.SetChequeVATAmount(vChequeAttributes, vVATRAte, vSrvRow.VATSum);
						// Fill format 1.05 and later attributes and end item
						v1212 = tcCashRegisters.GetChequeItemTypeValue(tcCashRegisters.GetChequeItemType(pObj, vSrvRow.Service, vSrvRow.PaymentSection));
						vFR.setParam(1212, v1212);
						If v1212 = 2 Or v1212 = 30 Or v1212 = 31 Then
							// Fill excise value
							vFR.setParam(1229, tcCashRegisters.GetChequeItemExciseValue(tcOnServer.cmGetAttributeByRef(vSrvRow.Service, "ExciseDutyType"), pObj.Date, tcOnServer.cmGetAttributeByRef(vSrvRow.Service, "Volume"), vItemQuantity));
						EndIf;
						vFR.setParam(1214, vPaymentModeTypeValue);
						If vArrCashRegister.FiscalDataFormatVersions = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2") Then
							vFR.setParam(2108, GetUnitPiece(vSrvRow.Service));	
						EndIf;
						
						For Each vTLVRow In vTLVArray Do
							vFR.setParam(vTLVRow.Tag, vTLVRow.Value);
						EndDo;
						
						// Extra functions for extensions
						If Not pmPrintCheque_BeforeChequePositionRegistration(vFR, vArrCashRegister, vChargesWithMarkingCode, vSrvRow, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD) Then
							CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
							Return False;
						EndIf;
						
						If vFR.registration() <> 0 Then
							CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
							Return False;
						EndIf;
						
						// Extra functions for extensions
						vTLVArray = New Array;
						If Not pmPrintCheque_AfterChequePositionRegistrationTLV(vFR, vArrCashRegister, vChargesWithMarkingCode, vSrvRow, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD, vTLVArray) Then
							CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
							Return False;
						EndIf;
						
						For Each vTLVRow In vTLVArray Do
							vFR.setParam(vTLVRow.Tag, vTLVRow.Value);
						EndDo;
						
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
							vFR.setParam(vFR.LIBFPTR_PARAM_TEXT, TrimAll("#" + TrimAll(pObj.Number))); 
							If vFR.printText() <> 0 Then
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
								vSectionVATAmount = vPSRow.VATSum;
								If TypeOf(pObj.Ref) = Type("DocumentRef.Return") Then
									vSectionAmount = -vSectionAmount;
									vSectionVATAmount = -vSectionVATAmount;
								EndIf;
								
								// Begin format item 
								// Print name, price and quantity
								
								// Extra functions for extensions
								vTLVArray = New Array;
								If Not pmPrintCheque_BeforeChequePositionRegistrationTLV(vFR, vArrCashRegister, vChargesWithMarkingCode, vPSRow, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD, vTLVArray) Then
									CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
									Return False;
								EndIf;
								
								vItemQuantity = 1;
								vPaymentModeTypeValue = tcCashRegisters.GetChequePaymentModeTypeValue(tcCashRegisters.GetChequePaymentMode(pObj.PaymentMethod, ?(ValueIsFilled(pObj.PaymentSection), pObj.PaymentSection, vPSRow.PaymentSection), vIsPrepayment));
								If ValueIsFilled(vPSRow.ChequeService) Then
									vIsHonestMark = False;
									If Not IsBlankString(vPSRow.MarkingCode) Then
										vIsHonestMark = tcCashRegisters.CheckMarkingCodeByType(vPSRow.ChequeService, PredefinedValue("Enum.MarkingCodeTypes.HonestMark"));
									EndIf;
									
									vIndustryInfo = Undefined;
									If Not IsBlankString(vPSRow.MarkingCode) And vIsHonestMark Then
										vIndustryInfo = GetIndustryInfo(vFR, vIsPayment, vPaymentModeTypeValue, vChargesWithMarkingCode, vPSRow.MarkingCode);
									EndIf;
									
									vMKStatus = Undefined;
									vValidationResult = Undefined;
									If Not IsBlankString(vPSRow.MarkingCode) And vIsHonestMark Then
										vValidationResult = CheckMarkingCode(vFR, TypeOf(pObj.Ref) = Type("DocumentRef.Payment"), vPSRow.ChequeService, vPSRow.MarkingCode, vMKStatus, vArrCashRegister.CancelReceiptPrintingWhenMarkingCheckError, vArrCashRegister.MarkingCodeVerificationTimeout, rMessage);
										If vValidationResult = Undefined Then
											OnlyCancelCheque(vFR);
											Return False;
										EndIf;
									EndIf;
									
									// Commissioner mark
									vIsAgentService = tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "IsAgentService");
									If vIsAgentService Then
										// Principal
										vPrincipal = tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "Principal");
										If ValueIsFilled(vPrincipal) Then
											vPrincipalTIN = TrimAll(tcOnServer.cmGetAttributeByRef(vPrincipal, "TIN"));
											vPrincipalName = TrimAll(tcOnServer.cmGetAttributeByRef(vPrincipal, "LegacyName"));
											vPrincipalPhone = TrimAll(tcOnServer.cmGetAttributeByRef(vPrincipal, "Phone"));
											vSuplierInfo = Undefined;
											If ValueIsFilled(vPrincipalName) And ValueIsFilled(vPrincipalPhone) Then
												vFR.setParam(1225, vPrincipalName);
												vFR.setParam(1171, SMS.GetPhoneNumberWithCountryCode(vPrincipalPhone));
												vFR.utilFormTlv();
												vSuplierInfo = vFR.getParamByteArray(vFR.LIBFPTR_PARAM_TAG_VALUE);
											EndIf;
											If ValueIsFilled(vPrincipalTIN) Then
												vFR.setParam(1226, ?(StrLen(vPrincipalTIN) = 10, vPrincipalTIN + "  ", vPrincipalTIN));
											EndIf;
											If vSuplierInfo <> Undefined Then 
												vFR.setParam(1224, vSuplierInfo);
											EndIf;
										EndIf;
										// Commissioner attribute
										If tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "PrincipalType") = 1 Then
											vFR.setParam(1222, vFR.LIBFPTR_AT_ANOTHER); // Other agent
										Else
											vFR.setParam(1222, vFR.LIBFPTR_AT_COMMISSION_AGENT); // Commission agent
										EndIf;
									EndIf;
									If vValidationResult <> Undefined And vMKStatus <> Undefined Then
										vContainsMarkingCodes = True;
										If vIndustryInfo <> Undefined Then
											vFR.setParam(1260, vIndustryInfo);
										EndIf;
										vFR.setParam(vFR.LIBFPTR_PARAM_MARKING_CODE, GetStringFromBinaryData(Base64Value(vPSRow.MarkingCode)));
										vFR.setParam(vFR.LIBFPTR_PARAM_MARKING_CODE_STATUS, vMKStatus);
										vFR.setParam(vFR.LIBFPTR_PARAM_MARKING_CODE_ONLINE_VALIDATION_RESULT, vValidationResult);
										vFR.setParam(vFR.LIBFPTR_PARAM_MARKING_PROCESSING_MODE, 0);	
									Else
										// Item code
										vCashRegisterItemCode = TrimAll(tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "CashRegisterItemCode"));
										If Not IsBlankString(vCashRegisterItemCode) Then
											If vArrCashRegister.FiscalDataFormatVersions = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2") Then
												vFR.setParam(vFR.LIBFPTR_PARAM_PRODUCT_CODE, vCashRegisterItemCode);	
											Else
												vFR.setParamStrHex(1162, tcCashRegisters.GetHexItemCode(vCashRegisterItemCode));
											EndIf;
										EndIf;
									EndIf;
									// Item main attributes
									If ValueIsFilled(vPSRow.PaymentSection) Then
										vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, tcOnServer.cmGetAttributeByRef(vPSRow.PaymentSection, "Code"));
									Else
										vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, 0);
									EndIf;
									If ValueIsFilled(vPSRow.Item) Then
										vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, GetString(tcOnServer.cmGetOrderItemDescription(vPSRow.Item), vArrCashRegister));
									Else
										vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, GetString(tcOnServer.cmGetServiceDescription(vPSRow.ChequeService), vArrCashRegister));
									EndIf;
									vFR.setParam(vFR.LIBFPTR_PARAM_POSITION_SUM, ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount));
									vItemPrice = ?(vPSRow.ChequeServicePrice = 0, ?(vSectionAmount >=0, vSectionAmount, -vSectionAmount), vPSRow.ChequeServicePrice);
									vItemQuantity = ?(vPSRow.ChequeServiceQuantity <> 0, vPSRow.ChequeServiceQuantity, 1);
									vItemQuantity = ?(vItemQuantity < 0, -vItemQuantity, vItemQuantity);
									tcCashRegisters.ChequeItemAttributesCorrection(?(vSectionAmount < 0, -vSectionAmount, vSectionAmount), vItemQuantity, 3, vItemPrice, vItemQuantity);
									vFR.setParam(vFR.LIBFPTR_PARAM_PRICE, vItemPrice);
									vFR.setParam(vFR.LIBFPTR_PARAM_QUANTITY, vItemQuantity);
								ElsIf ValueIsFilled(vPSRow.PaymentSection) Then
									vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, tcOnServer.cmGetAttributeByRef(vPSRow.PaymentSection, "Code"));
									vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, GetString(tcOnServer.cmGetPaymentSectionDescription(vPSRow.PaymentSection), vArrCashRegister));
									vFR.setParam(vFR.LIBFPTR_PARAM_POSITION_SUM, ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount));
									vFR.setParam(vFR.LIBFPTR_PARAM_PRICE, ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount));
									vFR.setParam(vFR.LIBFPTR_PARAM_QUANTITY, 1);
								Else
									vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, 0);
									If vSectionAmount >=0 Then
										vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, NStr("en='Hotel services'; de='Hoteldienstleistungen'; ru='Гостиничные услуги'"));
									Else
										vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, NStr("en='Refund for hotel services'; de='Rückreise für Hoteldienstleistungen'; ru='Возврат за гостиничные услуги'"));
									EndIf;
									vFR.setParam(vFR.LIBFPTR_PARAM_POSITION_SUM, ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount));
									vFR.setParam(vFR.LIBFPTR_PARAM_PRICE, ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount));
									vFR.setParam(vFR.LIBFPTR_PARAM_QUANTITY, 1); 
								EndIf;
								vFR.setParam(vFR.LIBFPTR_PARAM_CHECK_SUM, False);
								vFR.setParam(vFR.LIBFPTR_PARAM_TAX_MODE, vFR.LIBFPTR_TM_POSITION);
								// Add tax
								vVATRate = Undefined;
								If ValueIsFilled(vPSRow.PaymentSection) Then
									Execute("vFR.setParam(vFR.LIBFPTR_PARAM_TAX_TYPE, vFR." + GetTaxGroup(vPSRow.PaymentSection, vVATRate, vPSRow.VATRate, pObj) + ");");
								Else
									Execute("vFR.setParam(vFR.LIBFPTR_PARAM_TAX_TYPE, vFR." + GetTaxGroup(pObj, vVATRate, vPSRow.VATRate, pObj) + ");");
								EndIf;
								tcCashRegisters.SetChequeVATAmount(vChequeAttributes, vVATRate, vPSRow.VATSum);
								// Fill format 1.05 attributes and end item
								v1212 = tcCashRegisters.GetChequeItemTypeValue(tcCashRegisters.GetChequeItemType(pObj, vPSRow.ChequeService, vPSRow.PaymentSection, vIsPrepayment));
								vFR.setParam(1212, v1212);
								If v1212 = 2 Or v1212 = 30 Or v1212 = 31 Then
									// Fill excise value
									If ValueIsFilled(vPSRow.ChequeService) Then
										vFR.setParam(1229, tcCashRegisters.GetChequeItemExciseValue(tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "ExciseDutyType"), pObj.Date, tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "Volume"), vItemQuantity));
									EndIf;
								EndIf;
								vFR.setParam(1214, vPaymentModeTypeValue);
								If vArrCashRegister.FiscalDataFormatVersions = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2") Then
									vFR.setParam(2108, GetUnitPiece(vPSRow.ChequeService));	
								EndIf;
								
								For Each vTLVRow In vTLVArray Do
									vFR.setParam(vTLVRow.Tag, vTLVRow.Value);
								EndDo;
								
								// Extra functions for extensions
								If Not pmPrintCheque_BeforeChequePositionRegistration(vFR, vArrCashRegister, vChargesWithMarkingCode, vPSRow, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD) Then
									CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
									Return False;
								EndIf;
								
								If vFR.registration() <> 0 Then
									CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
									Return False;
								EndIf;
								
								// Extra functions for extensions
								vTLVArray = New Array;
								If Not pmPrintCheque_AfterChequePositionRegistrationTLV(vFR, vArrCashRegister, vChargesWithMarkingCode, vPSRow, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD, vTLVArray) Then
									CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
									Return False;
								EndIf;
								
								For Each vTLVRow In vTLVArray Do
									vFR.setParam(vTLVRow.Tag, vTLVRow.Value);
								EndDo;
								
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
								vSectionVATAmount = vPSRow.VATSum;
								If TypeOf(pObj.Ref) = Type("DocumentRef.Return") Then
									vSectionAmount = -vSectionAmount;
									vSectionVATAmount = -vSectionVATAmount;
								EndIf;
								// Begin format 1.05 item 
								// Print name, price and quantity
								
								// Extra functions for extensions
								vTLVArray = New Array;
								If Not pmPrintCheque_BeforeChequePositionRegistrationTLV(vFR, vArrCashRegister, vChargesWithMarkingCode, vPSRow, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD, vTLVArray) Then
									CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
									Return False;
								EndIf;
								
								vItemQuantity = 1;
								vPaymentModeTypeValue = tcCashRegisters.GetChequePaymentModeTypeValue(tcCashRegisters.GetChequePaymentMode(pObj.PaymentMethod, ?(ValueIsFilled(pObj.PaymentSection), pObj.PaymentSection, vPSRow.PaymentSection), vIsPrepayment));
								If ValueIsFilled(vPSRow.ChequeService) Then
									vIsHonestMark = False;
									If Not IsBlankString(vPSRow.MarkingCode) Then
										vIsHonestMark = tcCashRegisters.CheckMarkingCodeByType(vPSRow.ChequeService, PredefinedValue("Enum.MarkingCodeTypes.HonestMark"));
									EndIf;
									
									vIndustryInfo = Undefined;
									If Not IsBlankString(vPSRow.MarkingCode) And vIsHonestMark Then
										vIndustryInfo = GetIndustryInfo(vFR, vIsPayment, vPaymentModeTypeValue, vChargesWithMarkingCode, vPSRow.MarkingCode);
									EndIf;
									
									vMKStatus = Undefined;
									vValidationResult = Undefined;
									If Not IsBlankString(vPSRow.MarkingCode) And vIsHonestMark Then
										vValidationResult = CheckMarkingCode(vFR, TypeOf(pObj.Ref) = Type("DocumentRef.Payment"), vPSRow.ChequeService, vPSRow.MarkingCode, vMKStatus, vArrCashRegister.CancelReceiptPrintingWhenMarkingCheckError, vArrCashRegister.MarkingCodeVerificationTimeout, rMessage);
										If vValidationResult = Undefined Then
											OnlyCancelCheque(vFR);
											Return False;
										EndIf;
									EndIf;
									
									// Commissioner mark
									vIsAgentService = tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "IsAgentService");
									If vIsAgentService Then
										// Principal
										vPrincipal = tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "Principal");
										If ValueIsFilled(vPrincipal) Then
											vPrincipalTIN = TrimAll(tcOnServer.cmGetAttributeByRef(vPrincipal, "TIN"));
											vPrincipalName = TrimAll(tcOnServer.cmGetAttributeByRef(vPrincipal, "LegacyName"));
											vPrincipalPhone = TrimAll(tcOnServer.cmGetAttributeByRef(vPrincipal, "Phone"));
											vSuplierInfo = Undefined;
											If ValueIsFilled(vPrincipalName) And ValueIsFilled(vPrincipalPhone) Then
												vFR.setParam(1225, vPrincipalName);
												vFR.setParam(1171, SMS.GetPhoneNumberWithCountryCode(vPrincipalPhone));
												vFR.utilFormTlv();
												vSuplierInfo = vFR.getParamByteArray(vFR.LIBFPTR_PARAM_TAG_VALUE);
											EndIf;
											If ValueIsFilled(vPrincipalTIN) Then
												vFR.setParam(1226, ?(StrLen(vPrincipalTIN) = 10, vPrincipalTIN + "  ", vPrincipalTIN));
											EndIf;
											If vSuplierInfo <> Undefined Then 
												vFR.setParam(1224, vSuplierInfo);
											EndIf;
										EndIf;
										// Commissioner attribute
										If tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "PrincipalType") = 1 Then
											vFR.setParam(1222, vFR.LIBFPTR_AT_ANOTHER); // Other agent
										Else
											vFR.setParam(1222, vFR.LIBFPTR_AT_COMMISSION_AGENT); // Commission agent
										EndIf;
									EndIf; 
									If vValidationResult <> Undefined And vMKStatus <> Undefined Then
										vContainsMarkingCodes = True;
										If vIndustryInfo <> Undefined Then
											vFR.setParam(1260, vIndustryInfo);
										EndIf;
										vFR.setParam(vFR.LIBFPTR_PARAM_MARKING_CODE, GetStringFromBinaryData(Base64Value(vPSRow.MarkingCode))); 
										vFR.setParam(vFR.LIBFPTR_PARAM_MARKING_CODE_STATUS, vMKStatus);
										vFR.setParam(vFR.LIBFPTR_PARAM_MARKING_CODE_ONLINE_VALIDATION_RESULT, vValidationResult);
										vFR.setParam(vFR.LIBFPTR_PARAM_MARKING_PROCESSING_MODE, 0);	
									Else
										// Item code
										vCashRegisterItemCode = TrimAll(tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "CashRegisterItemCode"));
										If Not IsBlankString(vCashRegisterItemCode) Then
											If vArrCashRegister.FiscalDataFormatVersions = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2") Then
												vFR.setParam(vFR.LIBFPTR_PARAM_PRODUCT_CODE, vCashRegisterItemCode);	
											Else
												vFR.setParamStrHex(1162, tcCashRegisters.GetHexItemCode(vCashRegisterItemCode));
											EndIf;
										EndIf;  
									EndIf;
									// Item main attributes
									If ValueIsFilled(vPSRow.PaymentSection) Then
										vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, tcOnServer.cmGetAttributeByRef(vPSRow.PaymentSection, "Code"));
									Else
										vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, 0);
									EndIf;
									If ValueIsFilled(vPSRow.Item) Then
										vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, GetString(tcOnServer.cmGetOrderItemDescription(vPSRow.Item), vArrCashRegister));
									Else
										vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, GetString(tcOnServer.cmGetServiceDescription(vPSRow.ChequeService), vArrCashRegister));
									EndIf;
									vFR.setParam(vFR.LIBFPTR_PARAM_POSITION_SUM, ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount));
									vItemPrice = ?(vPSRow.ChequeServicePrice = 0, ?(vSectionAmount >=0, vSectionAmount, -vSectionAmount), vPSRow.ChequeServicePrice);
									vItemQuantity = ?(vPSRow.ChequeServiceQuantity <> 0, vPSRow.ChequeServiceQuantity, 1);
									vItemQuantity = ?(vItemQuantity < 0, -vItemQuantity, vItemQuantity);
									tcCashRegisters.ChequeItemAttributesCorrection(?(vSectionAmount < 0, -vSectionAmount, vSectionAmount), vItemQuantity, 3, vItemPrice, vItemQuantity);
									vFR.setParam(vFR.LIBFPTR_PARAM_PRICE, vItemPrice);
									vFR.setParam(vFR.LIBFPTR_PARAM_QUANTITY, vItemQuantity);
								ElsIf ValueIsFilled(vPSRow.PaymentSection) Then
									vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, tcOnServer.cmGetAttributeByRef(vPSRow.PaymentSection, "Code"));
									vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, GetString(tcOnServer.cmGetPaymentSectionDescription(vPSRow.PaymentSection), vArrCashRegister));
									vFR.setParam(vFR.LIBFPTR_PARAM_POSITION_SUM, ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount));
									vFR.setParam(vFR.LIBFPTR_PARAM_PRICE, ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount));
									vFR.setParam(vFR.LIBFPTR_PARAM_QUANTITY, 1);
								Else
									vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, 0);
									If vSectionAmount >=0 Then
										vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, NStr("en='Hotel services'; de='Hoteldienstleistungen'; ru='Гостиничные услуги'"));
									Else
										vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, NStr("en='Refund for hotel services'; de='Rückreise für Hoteldienstleistungen'; ru='Возврат за гостиничные услуги'"));
									EndIf;
									vFR.setParam(vFR.LIBFPTR_PARAM_POSITION_SUM, ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount));
									vFR.setParam(vFR.LIBFPTR_PARAM_PRICE, ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount));
									vFR.setParam(vFR.LIBFPTR_PARAM_QUANTITY, 1);
								EndIf;
								vFR.setParam(vFR.LIBFPTR_PARAM_CHECK_SUM, False);
								vFR.setParam(vFR.LIBFPTR_PARAM_TAX_MODE, vFR.LIBFPTR_TM_POSITION);
								// Add tax
								vVATRate = Undefined;
								If ValueIsFilled(vPSRow.PaymentSection) Then
									Execute("vFR.setParam(vFR.LIBFPTR_PARAM_TAX_TYPE, vFR." + GetTaxGroup(vPSRow.PaymentSection, vVATRate, vPSRow.VATRate, pObj) + ");");
								Else
									Execute("vFR.setParam(vFR.LIBFPTR_PARAM_TAX_TYPE, vFR." + GetTaxGroup(pObj, vVATRate, vPSRow.VATRate, pObj) + ");");
								EndIf;
								tcCashRegisters.SetChequeVATAmount(vChequeAttributes, vVATRate, vPSRow.VATSum);
								// Fill format 1.05 attributes and end item
								v1212 = tcCashRegisters.GetChequeItemTypeValue(tcCashRegisters.GetChequeItemType(pObj, vPSRow.ChequeService, vPSRow.PaymentSection, vIsPrepayment));
								vFR.setParam(1212, v1212);
								If v1212 = 2 Or v1212 = 30 Or v1212 = 31 Then
									// Fill excise value
									If ValueIsFilled(vPSRow.ChequeService) Then
										vFR.setParam(1229, tcCashRegisters.GetChequeItemExciseValue(tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "ExciseDutyType"), pObj.Date, tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "Volume"), vItemQuantity));
									EndIf;
								EndIf;
								vFR.setParam(1214, vPaymentModeTypeValue);
								If vArrCashRegister.FiscalDataFormatVersions = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2") Then
									vFR.setParam(2108, GetUnitPiece(vPSRow.ChequeService));	
								EndIf;
								
								For Each vTLVRow In vTLVArray Do
									vFR.setParam(vTLVRow.Tag, vTLVRow.Value);
								EndDo;
								
								// Extra functions for extensions
								If Not pmPrintCheque_BeforeChequePositionRegistration(vFR, vArrCashRegister, vChargesWithMarkingCode, vPSRow, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD) Then
									CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
									Return False;
								EndIf;
								
								If vFR.registration() <> 0 Then
									CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
									Return False;
								EndIf;
								
								// Extra functions for extensions
								vTLVArray = New Array;
								If Not pmPrintCheque_AfterChequePositionRegistrationTLV(vFR, vArrCashRegister, vChargesWithMarkingCode, vPSRow, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD, vTLVArray) Then
									CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
									Return False;
								EndIf;
								
								For Each vTLVRow In vTLVArray Do
									vFR.setParam(vTLVRow.Tag, vTLVRow.Value);
								EndDo;
								
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
									vVATAmount = vVATAmount - vPSRow.VATSum;
								Else
									vAmount = vAmount + vPSRow.Sum;
									vVATAmount = vVATAmount + vPSRow.VATSum;
								EndIf;
							EndDo;
							// Begin format 1.05 item 
							// Print name, price and quantity
							
							// Extra functions for extensions
							vTLVArray = New Array;
							If Not pmPrintCheque_BeforeChequePositionRegistrationTLV(vFR, vArrCashRegister, vChargesWithMarkingCode, Undefined, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD, vTLVArray) Then
								CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
								Return False;
							EndIf;
							
							vFR.setParam(vFR.LIBFPTR_PARAM_CHECK_SUM, False);
							vFR.setParam(vFR.LIBFPTR_PARAM_TAX_MODE, vFR.LIBFPTR_TM_POSITION);
							vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, 0);
							vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, NStr("en='Hotel services';ru='Гостиничные услуги';de='Hotel Dienstleistungen'"));
							vFR.setParam(vFR.LIBFPTR_PARAM_POSITION_SUM, ?(vAmount < 0, -vAmount, vAmount)); 
							vFR.setParam(vFR.LIBFPTR_PARAM_PRICE, ?(vAmount < 0, -vAmount, vAmount));
							vFR.setParam(vFR.LIBFPTR_PARAM_QUANTITY, 1); // Add tax
							vVATRate = Undefined;
							Execute("vFR.setParam(vFR.LIBFPTR_PARAM_TAX_TYPE, vFR." + GetTaxGroup(pObj, vVATRate, , pObj) + ");");
							tcCashRegisters.SetChequeVATAmount(vChequeAttributes, vVATRate, ?(vVATAmount >=0, vVATAmount, -vVATAmount));
							// Fill format 1.05 attributes and end item
							vFR.setParam(1212, tcCashRegisters.GetChequeItemTypeValue(tcCashRegisters.GetChequeItemType(pObj, Undefined, Undefined)));
							vFR.setParam(1214, tcCashRegisters.GetChequePaymentModeTypeValue(tcCashRegisters.GetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection)));
							If vArrCashRegister.FiscalDataFormatVersions = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2") Then
								vFR.setParam(2108, GetUnitPiece(Undefined));	
							EndIf;
							
							For Each vTLVRow In vTLVArray Do
								vFR.setParam(vTLVRow.Tag, vTLVRow.Value);
							EndDo;
							
							// Extra functions for extensions
							If Not pmPrintCheque_BeforeChequePositionRegistration(vFR, vArrCashRegister, vChargesWithMarkingCode, Undefined, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD) Then
								CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
								Return False;
							EndIf;
							
							If vFR.registration() <> 0 Then
								CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
								Return False;
							EndIf;
							
							// Extra functions for extensions
							vTLVArray = New Array;
							If Not pmPrintCheque_AfterChequePositionRegistrationTLV(vFR, vArrCashRegister, vChargesWithMarkingCode, Undefined, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD, vTLVArray) Then
								CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
								Return False;
							EndIf;
							
							For Each vTLVRow In vTLVArray Do
								vFR.setParam(vTLVRow.Tag, vTLVRow.Value);
							EndDo;
							
							// Extra functions for extensions
							If Not pmPrintCheque_AfterChequePositionRegistration(vFR, vArrCashRegister, vChargesWithMarkingCode, Undefined, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD) Then
								CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
								Return False;
							EndIf;
						EndIf;
					Else
						vVATAmount = pObj.VATSum;
						If TypeOf(pObj.Ref) = Type("DocumentRef.Return") Then
							vVATAmount = -vVATAmount;
						EndIf;
						// Begin format 1.05 item 
						// Print name, price and quantity
						
						// Extra functions for extensions
						vTLVArray = New Array;
						If Not pmPrintCheque_BeforeChequePositionRegistrationTLV(vFR, vArrCashRegister, vChargesWithMarkingCode, Undefined, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD, vTLVArray) Then
							CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
							Return False;
						EndIf;
						
						vFR.setParam(vFR.LIBFPTR_PARAM_CHECK_SUM, False);
						vFR.setParam(vFR.LIBFPTR_PARAM_TAX_MODE, vFR.LIBFPTR_TM_POSITION);
						vCommodityName = NStr("en='Hotel services';ru='Гостиничные услуги';de='Hotel Dienstleistungen'");
						If Not vArrCashRegister.PrintFolioHeader Then
							vCommodityName = "#" + TrimAll(pObj.Number);
						EndIf;
						vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, 0);
						If ValueIsFilled(pObj.PaymentSection) Then
							vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, tcOnServer.cmGetAttributeByRef(pObj.PaymentSection, "Code"));
							If vArrCashRegister.PrintPaymentSectionNamesInCheques Then
								If vArrCashRegister.PrintFolioHeader Then
									vCommodityName = GetString(tcOnServer.cmGetPaymentSectionDescription(pObj.PaymentSection), vArrCashRegister);
								Else
									vCommodityName = GetString(TrimR(vCommodityName) + " - " + tcOnServer.cmGetPaymentSectionDescription(pObj.PaymentSection), vArrCashRegister);
								EndIf;
							EndIf;
						EndIf;
						vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, vCommodityName);
						vFR.setParam(vFR.LIBFPTR_PARAM_QUANTITY, 1);
						vFR.setParam(vFR.LIBFPTR_PARAM_POSITION_SUM, ?(pSum < 0, -pSum, pSum));
						vFR.setParam(vFR.LIBFPTR_PARAM_PRICE, ?(pSum < 0, -pSum, pSum));
						// Add tax
						vVATRate = Undefined;
						Execute("vFR.setParam(vFR.LIBFPTR_PARAM_TAX_TYPE, vFR." + GetTaxGroup(pObj, vVATRate, , pObj) + ");");
						tcCashRegisters.SetChequeVATAmount(vChequeAttributes, vVATRate, ?(vVATAmount >= 0, vVATAmount, -vVATAmount));
						// Fill format 1.05 attributes and end item
						vFR.setParam(1212, tcCashRegisters.GetChequeItemTypeValue(tcCashRegisters.GetChequeItemType(pObj, Undefined, Undefined)));
						vFR.setParam(1214, tcCashRegisters.GetChequePaymentModeTypeValue(tcCashRegisters.GetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection)));
						If vArrCashRegister.FiscalDataFormatVersions = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2") Then
							vFR.setParam(2108, GetUnitPiece(Undefined));
						EndIf;
						
						For Each vTLVRow In vTLVArray Do
							vFR.setParam(vTLVRow.Tag, vTLVRow.Value);
						EndDo;
						
						// Extra functions for extensions
						If Not pmPrintCheque_BeforeChequePositionRegistration(vFR, vArrCashRegister, vChargesWithMarkingCode, Undefined, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD) Then
							CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
							Return False;
						EndIf;
						
						If vFR.registration() <> 0 Then
							CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
							Return False;
						EndIf;
						
						// Extra functions for extensions
						vTLVArray = New Array;
						If Not pmPrintCheque_AfterChequePositionRegistrationTLV(vFR, vArrCashRegister, vChargesWithMarkingCode, Undefined, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD, vTLVArray) Then
							CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
							Return False;
						EndIf;
						
						For Each vTLVRow In vTLVArray Do
							vFR.setParam(vTLVRow.Tag, vTLVRow.Value);
						EndDo;
						
						// Extra functions for extensions
						If Not pmPrintCheque_AfterChequePositionRegistration(vFR, vArrCashRegister, vChargesWithMarkingCode, Undefined, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD) Then
							CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
							Return False;
						EndIf;
					EndIf;
				EndIf;
				
				If vVersion >= "10.10.7.0" And vArrCashRegister.FiscalDataFormatVersions = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2") And vContainsMarkingCodes And vArrCashRegister.TimeZone > 0 Then
					vFR.setParam(1011, vArrCashRegister.TimeZone);
					If vFR.writeSalesNotice() <> 0 Then
						CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
						Return False;
					EndIf;
				EndIf;
				
				// Print VAT sum if neccessary
				If vArrCashRegister.PrintVATSumInCheques And pVATSum > 0 Then
					vNoVAT = ?(ValueIsFilled(pObj.VATRate), tcOnServer.cmGetAttributeByRef(pObj.VATRate, "NoVAT"), False);
					If vNoVAT Then
						vFR.setParam(vFR.LIBFPTR_PARAM_TEXT, GetString(NStr("en='No VAT';ru='Без НДС';de='Ohne MwSt.'"), vArrCashRegister));
					Else
						vFR.setParam(vFR.LIBFPTR_PARAM_TEXT, GetString(NStr("ru='В т.ч. НДС '; en='Incl. VAT '; de='Inkl. MwSt. '") + Format(pVATSum, "ND=17; NFD=2; NZ="), vArrCashRegister));
					EndIf;
					If vFR.printText() <> 0 Then
						CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
						Return False;
					EndIf;
				ElsIf vArrCashRegister.PrintInclVATStrInCheques And pVATSum > 0 Then
					vFR.setParam(vFR.LIBFPTR_PARAM_TEXT, GetString(NStr("ru='НДС включён в сумму'; en='Amount includes VAT'; de='Betrag inkl. MwSt.'"), vArrCashRegister));	
					If vFR.printText() <> 0 Then
						CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
						Return False;
					EndIf;
				EndIf;
			Else // Correction cheque
				vVATAmount = pObj.VATSum;
				If TypeOf(pObj.Ref) = Type("DocumentRef.Return") Then
					vVATAmount = -vVATAmount;
				EndIf;
				// Begin format 1.05 item 
				// Print name, price and quantity
				
				// Extra functions for extensions
				vTLVArray = New Array;
				If Not pmPrintCheque_BeforeChequePositionRegistrationTLV(vFR, vArrCashRegister, vChargesWithMarkingCode, Undefined, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD, vTLVArray) Then
					CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
					Return False;
				EndIf;
				
				vFR.setParam(vFR.LIBFPTR_PARAM_CHECK_SUM, False);
				vFR.setParam(vFR.LIBFPTR_PARAM_TAX_MODE, vFR.LIBFPTR_TM_POSITION);
				vCommodityName = NStr("en='Hotel services';ru='Гостиничные услуги';de='Hotel Dienstleistungen'");
				If Not vArrCashRegister.PrintFolioHeader Then
					vCommodityName = "#" + TrimAll(pObj.Number);
				EndIf;
				vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, 0);
				If ValueIsFilled(pObj.PaymentSection) Then
					vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, tcOnServer.cmGetAttributeByRef(pObj.PaymentSection, "Code"));
					If vArrCashRegister.PrintPaymentSectionNamesInCheques Then
						If vArrCashRegister.PrintFolioHeader Then
							vCommodityName = GetString(tcOnServer.cmGetPaymentSectionDescription(pObj.PaymentSection), vArrCashRegister);
						Else
							vCommodityName = GetString(TrimR(vCommodityName) + " - " + tcOnServer.cmGetPaymentSectionDescription(pObj.PaymentSection), vArrCashRegister);
						EndIf;
					EndIf;
				EndIf;
				vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, vCommodityName);
				vFR.setParam(vFR.LIBFPTR_PARAM_QUANTITY, 1);
				vFR.setParam(vFR.LIBFPTR_PARAM_POSITION_SUM, ?(pSum < 0, -pSum, pSum));
				vFR.setParam(vFR.LIBFPTR_PARAM_PRICE, ?(pSum < 0, -pSum, pSum));
				// Add tax
				vVATRate = Undefined;
				Execute("vFR.setParam(vFR.LIBFPTR_PARAM_TAX_TYPE, vFR." + GetTaxGroup(pObj, vVATRate, , pObj) + ");");
				tcCashRegisters.SetChequeVATAmount(vChequeAttributes, vVATRate, ?(vVATAmount >= 0, vVATAmount, -vVATAmount));
				// Fill format 1.05 attributes and end item
				vFR.setParam(1212, tcCashRegisters.GetChequeItemTypeValue(tcCashRegisters.GetChequeItemType(pObj, Undefined, Undefined)));
				vFR.setParam(1214, tcCashRegisters.GetChequePaymentModeTypeValue(tcCashRegisters.GetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection, vIsPrepayment)));
				If vArrCashRegister.FiscalDataFormatVersions = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2") Then
					vFR.setParam(2108, GetUnitPiece(Undefined));	
				EndIf;
				
				For Each vTLVRow In vTLVArray Do
					vFR.setParam(vTLVRow.Tag, vTLVRow.Value);
				EndDo;
				
				// Extra functions for extensions
				If Not pmPrintCheque_BeforeChequePositionRegistration(vFR, vArrCashRegister, vChargesWithMarkingCode, Undefined, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD) Then
					CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
					Return False;
				EndIf;
				
				If vFR.registration() <> 0 Then
					CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
					Return False;
				EndIf;
				
				// Extra functions for extensions
				vTLVArray = New Array;
				If Not pmPrintCheque_AfterChequePositionRegistrationTLV(vFR, vArrCashRegister, vChargesWithMarkingCode, Undefined, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD, vTLVArray) Then
					CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
					Return False;
				EndIf;
				
				For Each vTLVRow In vTLVArray Do
					vFR.setParam(vTLVRow.Tag, vTLVRow.Value);
				EndDo;
				
				// Extra functions for extensions
				If Not pmPrintCheque_AfterChequePositionRegistration(vFR, vArrCashRegister, vChargesWithMarkingCode, Undefined, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD) Then
					CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
					Return False;
				EndIf;
			EndIf;
			
			vOpenDrawer = False;
			// Close cheque
			If ValueIsFilled(pObj.PaymentMethod) Then
				If pObj.PaymentMethod = PredefinedValue("Catalog.PaymentMethods.AdvanceSettlement") Then
					vFR.setParam(vFR.LIBFPTR_PARAM_PAYMENT_TYPE, vFR.LIBFPTR_PT_PREPAID);
				ElsIf vArrPaymentMethod.IsByCash Then
					vFR.setParam(vFR.LIBFPTR_PARAM_PAYMENT_TYPE, vFR.LIBFPTR_PT_CASH);
					vOpenDrawer = True;
				ElsIf vArrPaymentMethod.IsByCreditCard Or vArrPaymentMethod.IsByBankTransfer Or vArrPaymentMethod.IsViaInternetAcquiring Then
					vFR.setParam(vFR.LIBFPTR_PARAM_PAYMENT_TYPE, vFR.LIBFPTR_PT_ELECTRONICALLY);
				Else
					Execute("vFR.setParam(vFR.LIBFPTR_PARAM_PAYMENT_TYPE, vFR." + GetOtherTypeClose(vArrPaymentMethod.CashRegisterChequeCloseType, vOpenDrawer) + ");");
				EndIf;
			Else
				vFR.setParam(vFR.LIBFPTR_PARAM_PAYMENT_TYPE, vFR.LIBFPTR_PT_CASH);
				vOpenDrawer = True;
			EndIf;
			vFR.setParam(vFR.LIBFPTR_PARAM_PAYMENT_SUM, ?(pSum > 0, pSum, -pSum));
			If vFR.payment() <> 0 Then
				CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			
			// Extra functions for extensions
			vTLVArray = New Array;
			If Not pmPrintCheque_BeforeCloseChequeTLV(vFR, vArrCashRegister, vChargesWithMarkingCode, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD, vTLVArray) Then
				CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			
			For Each vTLVRow In vTLVArray Do
				vFR.setParam(vTLVRow.Tag, vTLVRow.Value);
			EndDo;
			
			// Extra functions for extensions
			If Not pmPrintCheque_BeforeCloseCheque(vFR, vArrCashRegister, vChargesWithMarkingCode, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD) Then
				CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			
			If vFR.closeReceipt() <> 0 Then
				CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			
			// Extra functions for extensions
			vTLVArray = New Array;
			pmPrintCheque_AfterCloseChequeTLV(vFR, vArrCashRegister, vChargesWithMarkingCode, vOpenDrawer, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD, vTLVArray);
			
			For Each vTLVRow In vTLVArray Do
				vFR.setParam(vTLVRow.Tag, vTLVRow.Value);
			EndDo;
			
			// Extra functions for extensions
			pmPrintCheque_AfterCloseCheque(vFR, vArrCashRegister, vChargesWithMarkingCode, vOpenDrawer, pSum, pVATSum, pObj, pObjRef, rMessage, pPasswordKKM, pServices, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pSendPayerContactsToOFD, pEmailToSendToOFD, pPhoneToSendToOFD);
			
			// Get current cheque attributes
			If pSum < 0 Or pSum = 0 And TypeOf(pObjRef) = Type("DocumentRef.Return") Then
				vChequeAttributes.ChequeAccountingType = PredefinedValue("Enum.ChequeAccountingTypes.ReceiptReturn");
			Else
				vChequeAttributes.ChequeAccountingType = PredefinedValue("Enum.ChequeAccountingTypes.Receipt");
			EndIf;
			
			vFR.setParam(vFR.LIBFPTR_PARAM_FN_DATA_TYPE, vFR.LIBFPTR_FNDT_DOCUMENTS_COUNT_IN_SHIFT);
			vFR.fnQueryData();
			vChequeAttributes.CashDayChequeNumber = vFR.getParamInt(vFR.LIBFPTR_PARAM_DOCUMENTS_COUNT);
			
			vFR.setParam(vFR.LIBFPTR_PARAM_FN_DATA_TYPE, vFR.LIBFPTR_FNDT_FN_INFO);
			vFR.fnQueryData();
			vChequeAttributes.FiscalStorageFactoryNumber = vFR.getParamString(vFR.LIBFPTR_PARAM_SERIAL_NUMBER);
			
			vFR.setParam(vFR.LIBFPTR_PARAM_FN_DATA_TYPE, vFR.LIBFPTR_FNDT_LAST_DOCUMENT);
			vFR.fnQueryData();
			vChequeAttributes.ChequeSequenceNumber = vFR.getParamInt(vFR.LIBFPTR_PARAM_DOCUMENT_NUMBER);
			vChequeAttributes.ChequeFiscalNumber = vFR.getParamString(vFR.LIBFPTR_PARAM_FISCAL_SIGN);
			vChequeAttributes.ChequeDateTime = vFR.getParamDateTime(vFR.LIBFPTR_PARAM_DATE_TIME);
			
			vFR.setParam(vFR.LIBFPTR_PARAM_FN_DATA_TYPE, vFR.LIBFPTR_FNDT_SHIFT);
			vFR.fnQueryData();
			vChequeAttributes.CashDay = vFR.getParamInt(vFR.LIBFPTR_PARAM_SHIFT_NUMBER);	
			
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
					vFR.openDrawer();
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
		// Close open cheque if any
		CloseOpenCheque(vFR, pPasswordKKM, vArrCashRegister.DoNotOpenNewSessionAfterZReport, vArrCashRegister.IgnoreEndOfPaperError);
		
		vVersion = vFR.version();
		
		// Print slip if payment was made by credit card
		If vArrCashRegister.PrintSlipInCheque Then
			If ValueIsFilled(pObj.SlipText) Then
				If Not PrintSlipLines(vFR, tcOnServer.GetTextLinesArray(pObj.SlipText), vArrCashRegister, rMessage) Then
					Return False;
				EndIf;
			EndIf;
		EndIf;
		
		// Initialize cheque attributes used to send online cheque by sms or e-mail
		vChequeAttributes = tcCashRegisters.InitializeChequeAttributes(pObj, pObjRef, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate);
		
		vCorrectionInfo = Undefined;
		If pIsCorrection Then
			vCorrectionDocumentDate = ?(ValueIsFilled(pCorrectionDocumentDate), BegOfDay(pCorrectionDocumentDate), ?(pObj.CorrectionOfIncorrectCheque And ValueIsFilled(pObj.Payment), tcOnServer.cmGetAttributeByRef(pObj.Payment, "Date"), '00010101'));
			If ValueIsFilled(vCorrectionDocumentDate) Then
				vFR.setParam(1178, vCorrectionDocumentDate - '19700101');
				vChequeAttributes.CorrectionDocumentDate = vCorrectionDocumentDate;
			Else
				rMessage = NStr("en='The date of the corrected payment is not specified (the date when the wrong cheque was posted)!'; 
				|ru='Не указана дата совершения корректируемого расчета (дата, когда пробит неверный чек)!'; 
				|de='Das Datum der korrigierten Zahlung ist nicht angegeben (das Datum, an dem der falsche Scheck gebucht wurde)!'");
				Return False;
			EndIf;
			
			vCorrectionDocumentNumber = TrimAll(TrimAll(pCorrectionDescription) + ?(IsBlankString(pCorrectionDocumentNumber), "", " №" + TrimAll(pCorrectionDocumentNumber)));
			vFR.setParam(1179, Right(vCorrectionDocumentNumber, 32));
			vChequeAttributes.CorrectionDocumentNumber = vCorrectionDocumentNumber;
			
			vFR.utilFormTlv();
			vCorrectionInfo = vFR.getParamByteArray(vFR.LIBFPTR_PARAM_TAG_VALUE);
		EndIf;
		
		// Payer name and TIN
		vPayerInfo = Undefined;
		If vArrCashRegister.FiscalDataFormatVersions = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2") Then
			vPayerName = "";
			vPayerTIN = "";
			tcOnServer.GetPayerNameAndTIN(pObj.AccountingCustomer, vPayerName, vPayerTIN);
			If ValueIsFilled(vPayerTIN) And ValueIsFilled(vPayerName) Then
				vFR.setParam(1227, vPayerName);
				vFR.setParam(1228, ?(StrLen(vPayerTIN) = 10, vPayerTIN + "  ", vPayerTIN));
				vFR.utilFormTlv();
				vPayerInfo = vFR.getParamByteArray(vFR.LIBFPTR_PARAM_TAG_VALUE); 
			EndIf;
		EndIf;
		
		// Set cashier name
		vCashier = pObj.Author;
		If ValueIsFilled(vCashier) Then
			vCashierName = tcCashRegisters.GetCashierName(vCashier);
			If Not IsBlankString(vCashierName) Then
				vFR.setParam(1021, vCashierName);
				vChequeAttributes.CashierName = vCashierName;
				
				// Set TIN
				vEmployeeTIN = TrimAll(tcOnServer.cmGetAttributeByRef(vCashier, "TIN"));
				If Not IsBlankString(vEmployeeTIN) Then
					vFR.setParam(1203, vEmployeeTIN);
				EndIf;
			EndIf;
		EndIf;
		vFR.operatorLogin();
		
		vIsPayment = False;
		
		// Open cheque
		If Not pIsCorrection Then
			If pSum < 0 Then
				vFR.setParam(vFR.LIBFPTR_PARAM_RECEIPT_TYPE, vFR.LIBFPTR_RT_SELL_RETURN);
			Else
				vFR.setParam(vFR.LIBFPTR_PARAM_RECEIPT_TYPE, vFR.LIBFPTR_RT_SELL);
				vIsPayment = True;
			EndIf;
		Else
			If pSum < 0 Then
				vFR.setParam(vFR.LIBFPTR_PARAM_RECEIPT_TYPE, vFR.LIBFPTR_RT_SELL_RETURN_CORRECTION);
			Else
				vFR.setParam(vFR.LIBFPTR_PARAM_RECEIPT_TYPE, vFR.LIBFPTR_RT_SELL_CORRECTION);
				vIsPayment = True;
			EndIf;
		EndIf;
		If ValueIsFilled(pObj.PaymentMethod) And tcOnServer.cmGetAttributeByRef(pObj.PaymentMethod, "ElectronicChequeOnly") Then
			vFR.setParam(vFR.LIBFPTR_PARAM_RECEIPT_ELECTRONICALLY, True);
		Else
			vFR.setParam(vFR.LIBFPTR_PARAM_RECEIPT_ELECTRONICALLY, False);
		EndIf;
		
		// Set correction type
		vChequeAttributes.IsCorrection = pIsCorrection;
		If pIsCorrection Then
			vFR.setParam(1173, ?(pCorrectionType = PredefinedValue("Enum.CorrectionChequeTypes.ByOrder"), 1, 0));
			vChequeAttributes.CorrectionType = pCorrectionType;
			If vCorrectionInfo <> Undefined Then
				vFR.setParam(1174, vCorrectionInfo);
			EndIf;
		EndIf;
		
		// Set taxation system
		vTaxSystem = Undefined;
		vTaxSystemName = GetTaxationSystemCode(pObj, vTaxSystem);
		If ValueIsFilled(vTaxSystemName) Then
			vTaxSystemCode = Undefined;
			Execute("vTaxSystemCode = vFR." + TrimAll(vTaxSystemName) + ";");
			If vTaxSystemCode <> Undefined Then 
				vFR.setParam(1055, vTaxSystemCode);
				vChequeAttributes.TaxationSystem = vTaxSystem;
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
				vFR.setParam(1008, vEMail);
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
			If ValueIsFilled(vPhone) Then
				vFR.setParam(1008, SMS.GetPhoneNumberWithCountryCode(vPhone));
			EndIf;	
		EndIf;
		
		If vArrCashRegister.FiscalDataFormatVersions = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2") Then
			If vPayerInfo <> Undefined Then
				vFR.setParam(1256, vPayerInfo);
			EndIf;
		Else
			// Payer name and TIN
			vPayerName = "";
			vPayerTIN = "";
			tcOnServer.GetPayerNameAndTIN(pObj.AccountingCustomer, vPayerName, vPayerTIN);
			If ValueIsFilled(vPayerTIN) And ValueIsFilled(vPayerName) Then
				vFR.setParam(1227, vPayerName);
				vFR.setParam(1228, ?(StrLen(vPayerTIN) = 10, vPayerTIN + "  ", vPayerTIN));
			EndIf;
		EndIf;
		
		If vVersion >= "10.10.7.0" Then
			If vArrPaymentMethod.IsViaInternetAcquiring Then
				vFR.setParam(1125, True);
				
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
				
				vFR.setParam(1187, vHotelSite);
			Else
				vFR.setParam(1125, False);
			EndIf;
		EndIf;
		
		If vFR.openReceipt() <> 0 Then
			ProcessResultCode(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
			Return False;
		EndIf;
		
		If vArrCashRegister.FiscalDataFormatVersions = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2") Then
			vFR.cancelMarkingCodeValidation();
			vFR.clearMarkingCodeValidationResult();
		EndIf;
		
		// Begin format 1.05 item
		// Print payment number and section
		vVATAmount = pObj.VATSum;
		If vVATAmount < 0 Then
			vVATAmount = -vVATAmount;
		EndIf;
		
		vFR.setParam(vFR.LIBFPTR_PARAM_CHECK_SUM, False);
		vFR.setParam(vFR.LIBFPTR_PARAM_TAX_MODE, vFR.LIBFPTR_TM_POSITION);
		vCommodityName = NStr("en='Hotel services';ru='Гостиничные услуги';de='Hotel Dienstleistungen'");
		If Not vArrCashRegister.PrintFolioHeader Then
			vCommodityName = "#" + TrimAll(pObj.Number);
		EndIf;
		vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, 0);
		If ValueIsFilled(pObj.PaymentSection) Then
			vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, tcOnServer.cmGetAttributeByRef(pObj.PaymentSection, "Code"));
			If vArrCashRegister.PrintPaymentSectionNamesInCheques Then
				If vArrCashRegister.PrintFolioHeader Then
					vCommodityName = GetString(tcOnServer.cmGetPaymentSectionDescription(pObj.PaymentSection), vArrCashRegister);
				Else
					vCommodityName = GetString(TrimR(vCommodityName) + " - " + tcOnServer.cmGetPaymentSectionDescription(pObj.PaymentSection), vArrCashRegister);
				EndIf;
			EndIf;
		EndIf;
		vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, vCommodityName);
		vFR.setParam(vFR.LIBFPTR_PARAM_QUANTITY, 1);
		vFR.setParam(vFR.LIBFPTR_PARAM_POSITION_SUM, ?(pSum < 0, -pSum, pSum));
		vFR.setParam(vFR.LIBFPTR_PARAM_PRICE, ?(pSum < 0, -pSum, pSum));
		// Add tax
		vVATRate = Undefined;
		If ValueIsFilled(pObj.PaymentSection) Then
			Execute("vFR.setParam(vFR.LIBFPTR_PARAM_TAX_TYPE, vFR." + GetTaxGroup(pObj.PaymentSection, vVATRate, , pObj) + ");");
		Else
			Execute("vFR.setParam(vFR.LIBFPTR_PARAM_TAX_TYPE, vFR." + GetTaxGroup(pObj, vVATRate, , pObj) + ");");
		EndIf;
		tcCashRegisters.SetChequeVATAmount(vChequeAttributes, vVATRate, ?(vVATAmount >= 0, vVATAmount, -vVATAmount));
		
		// Fill format 1.05 attributes and end item
		vFR.setParam(1212, tcCashRegisters.GetChequeItemTypeValue(tcCashRegisters.GetChequeItemType(pObj, Undefined, Undefined)));
		vFR.setParam(1214, tcCashRegisters.GetChequePaymentModeTypeValue(tcCashRegisters.GetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection)));
		If vArrCashRegister.FiscalDataFormatVersions = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2") Then
			vFR.setParam(2108, GetUnitPiece(Undefined));
		EndIf;
		If vFR.registration() <> 0 Then
			CancelCheque(vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
			Return False;
		EndIf;	
		
		// Print VAT sum if neccessary
		If vArrCashRegister.PrintVATSumInCheques And pVATSum > 0 Then
			vNoVAT = ?(ValueIsFilled(pObj.VATRate), pObj.VATRate.NoVAT, False);
			If vNoVAT Then
				vFR.setParam(vFR.LIBFPTR_PARAM_TEXT, GetString(NStr("en='No VAT';ru='Без НДС';de='Ohne MwSt.'"), vArrCashRegister));
			Else
				vFR.setParam(vFR.LIBFPTR_PARAM_TEXT, GetString(NStr("ru='В т.ч. НДС '; en='Incl. VAT '; de='Inkl. MwSt. '") + Format(pVATSum, "ND=17; NFD=2; NZ="), vArrCashRegister));
			EndIf;
			If vFR.printText() <> 0 Then
				CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
		ElsIf vArrCashRegister.PrintInclVATStrInCheques And pVATSum > 0 Then
			vFR.setParam(vFR.LIBFPTR_PARAM_TEXT, GetString(NStr("ru='НДС включён в сумму'; en='Amount includes VAT'; de='Betrag inkl. MwSt.'"), vArrCashRegister));
			If vFR.printText() <> 0 Then
				CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
		EndIf;
		
		vOpenDrawer = False;
		// Close cheque
		If ValueIsFilled(pObj.PaymentMethod) Then
			If vArrPaymentMethod = PredefinedValue("Catalog.PaymentMethods.AdvanceSettlement") Then
				vFR.setParam(vFR.LIBFPTR_PARAM_PAYMENT_TYPE, vFR.LIBFPTR_PT_PREPAID);
			ElsIf vArrPaymentMethod.IsByCash Then
				vFR.setParam(vFR.LIBFPTR_PARAM_PAYMENT_TYPE, vFR.LIBFPTR_PT_CASH);
				vOpenDrawer = True;
			ElsIf vArrPaymentMethod.IsByCreditCard Or vArrPaymentMethod.IsByBankTransfer Or vArrPaymentMethod.IsViaInternetAcquiring Then
				vFR.setParam(vFR.LIBFPTR_PARAM_PAYMENT_TYPE, vFR.LIBFPTR_PT_ELECTRONICALLY);
			Else
				Execute("vFR.setParam(vFR.LIBFPTR_PARAM_PAYMENT_TYPE, vFR." + GetOtherTypeClose(vArrPaymentMethod.CashRegisterChequeCloseType, vOpenDrawer) + ");");
			EndIf;
		Else
			vFR.setParam(vFR.LIBFPTR_PARAM_PAYMENT_TYPE, vFR.LIBFPTR_PT_CASH);
			vOpenDrawer = True;
		EndIf;
		vFR.setParam(vFR.LIBFPTR_PARAM_PAYMENT_SUM, ?(pSum > 0, pSum, -pSum));
		If vFR.payment() <> 0 Then
			CancelCheque(vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
			Return False;
		EndIf;
		If vFR.closeReceipt() <> 0 Then
			CancelCheque(vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
			Return False;
		EndIf;			
		// Get current cheque attributes
		If pSum >= 0 Then
			vChequeAttributes.ChequeAccountingType = PredefinedValue("Enum.ChequeAccountingTypes.Receipt");
		Else
			vChequeAttributes.ChequeAccountingType = PredefinedValue("Enum.ChequeAccountingTypes.ReceiptReturn");
		EndIf;
		vFR.setParam(vFR.LIBFPTR_PARAM_FN_DATA_TYPE, vFR.LIBFPTR_FNDT_DOCUMENTS_COUNT_IN_SHIFT);
		vFR.fnQueryData();
		vChequeAttributes.CashDayChequeNumber = vFR.getParamInt(vFR.LIBFPTR_PARAM_DOCUMENTS_COUNT);
		
		vFR.setParam(vFR.LIBFPTR_PARAM_FN_DATA_TYPE, vFR.LIBFPTR_FNDT_FN_INFO);
		vFR.fnQueryData();
		vChequeAttributes.FiscalStorageFactoryNumber = vFR.getParamString(vFR.LIBFPTR_PARAM_SERIAL_NUMBER);
		
		vFR.setParam(vFR.LIBFPTR_PARAM_FN_DATA_TYPE, vFR.LIBFPTR_FNDT_LAST_DOCUMENT);
		vFR.fnQueryData();
		vChequeAttributes.ChequeSequenceNumber = vFR.getParamInt(vFR.LIBFPTR_PARAM_DOCUMENT_NUMBER);
		vChequeAttributes.ChequeFiscalNumber = vFR.getParamString(vFR.LIBFPTR_PARAM_FISCAL_SIGN);
		vChequeAttributes.ChequeDateTime = vFR.getParamDateTime(vFR.LIBFPTR_PARAM_DATE_TIME);
		
		vFR.setParam(vFR.LIBFPTR_PARAM_FN_DATA_TYPE, vFR.LIBFPTR_FNDT_SHIFT);
		vFR.fnQueryData();
		vChequeAttributes.CashDay = vFR.getParamInt(vFR.LIBFPTR_PARAM_SHIFT_NUMBER);
		
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
				vFR.openDrawer();
			EndIf;
		Except
		EndTry;
		
		// Disconnect
		Disconnect(vFR);
		Return True;
	Except
		rMessage = ErrorDescription();
		ProcessException(vFR, NStr("en='CashRegister.PrintCustomerCheque'; de='CashRegister.PrintCustomerCheque'; ru='ККМ.ПечатьЧекаКонтрагента'"), rMessage);
		Return False;
	EndTry;
EndFunction // pmPrintCustomerCheque

// -----------------------------------------------------------------------------
Function pmIsReadyToPrint(rMessage, pSkip24HoursLimitWarning = False, pCashRegister) Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pCashRegister);
	// Try to connect
	vFR = Connect(rMessage, vArrCashRegister);
	If vFR = Undefined Then
		Return False;
	Else // Cash register was connected
		// Retrieve cash register state
		vFR.setParam(vFR.LIBFPTR_PARAM_DATA_TYPE, vFR.LIBFPTR_DT_STATUS);
		If vFR.queryData() = 0 Then
			If vFR.getParamInt(vFR.LIBFPTR_PARAM_SHIFT_STATE) = vFR.LIBFPTR_SS_EXPIRED Then
				If Not pSkip24HoursLimitWarning Then
					rMessage = NStr("ru='Смена превысила 24 часа!'; en='24 hours open session limit exceeded!'; de='24 hours open session limit exceeded!'");
					Disconnect(vFR);
					Return False;
				EndIf;
			EndIf;
			// Check paper
			If Not vFR.getParamBool(vFR.LIBFPTR_PARAM_RECEIPT_PAPER_PRESENT) And Not vArrCashRegister.IgnoreEndOfPaperError Then
				rMessage = NStr("ru='В ККМ закончилась чековая лента!'; en='Cash register is out of paper!'; de='Cash register is out of paper!'");
				Disconnect(vFR);
				Return False;
			EndIf;
			//Check cheque printer
			If vFR.getParamBool(vFR.LIBFPTR_PARAM_PRINTER_CONNECTION_LOST) Then
				rMessage = NStr("ru='ККМ не может установить связь с принтером чеков!'; en='Cash register failes to connect to the cheque printer!'; de='Cash register failes to connect to the cheque printer!'");
				Disconnect(vFR);
				Return False;
			EndIf;
			If vFR.getParamBool(vFR.LIBFPTR_PARAM_PRINTER_ERROR) Then
				rMessage = NStr("ru='Ошибка принтера чеков!'; en='Cheque printer error!'; de='Cheque printer error!'");
				Disconnect(vFR);
				Return False;
			EndIf;
			If vFR.getParamBool(vFR.LIBFPTR_PARAM_PRINTER_OVERHEAT) Then
				rMessage = NStr("ru='Перегрев принтера чеков! Повторите попытку позже.'; en='Cheque printer overheated! Wait a while and try again.'; de='Cheque printer overheated! Wait a while and try again.'");
				Disconnect(vFR);
				Return False;
			EndIf;
		Else
			rMessage = NStr("ru='Ошибка получения состояния ККМ!'; en='Failed to check cash register state!'; de='Failed to check cash register state!'");
			Disconnect(vFR);
			Return False;
		EndIf;
	EndIf;
	// Disconnect
	Disconnect(vFR);
	Return True;
EndFunction // pmIsReadyToPrint

// -----------------------------------------------------------------------------
Function pmPrintNonFiscalCheque(pSum, pVATSum, pObj, pChequeTemplate, rMessage, pPasswordKKM="") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pObj.CashRegister);
	// Try to connect
	vFR = Connect(rMessage, vArrCashRegister);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Close open cheque if any
			CloseOpenCheque(vFR, pPasswordKKM, False, vArrCashRegister.IgnoreEndOfPaperError);
			
			If vFR.beginNonfiscalDocument() = 0 Then
				vChequeType = ?(pSum >= 0, "ПРИХОД", "ВОЗВРАТ ПРИХОДА");
				
				// Convert cheque template to the array of strings
				vTextArr = tcCashRegisters.GetTextLinesArray(pChequeTemplate);
				
				// Print all strings in the array
				vDoPrintClicheAtEnd = False;
				
				// Print first slip for the hotel
				vNum = 0;
				For Each vStr In vTextArr Do
					vNum = vNum + 1;
					If vStr = "&Cliche" And vNum = 1 Then
						If vFR.printCliche() <> 0 Then
							ProcessResultCode(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
							Return False;
						EndIf;
					ElsIf vStr = "&Cliche" And vNum = vTextArr.Count() Then
						vDoPrintClicheAtEnd = True;
						Continue;
					ElsIf vStr = "&FolioHeader" Then
						Try
							PrintFolioHeader(vFR, pObj, vArrCashRegister);
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
						vStr = GetString(vStr, vArrCashRegister); 
						vFR.setParam(vFR.LIBFPTR_PARAM_TEXT, vStr);
						vFR.setParam(vFR.LIBFPTR_PARAM_TEXT_WRAP, vFR.LIBFPTR_TW_NONE);
						If vFR.printText() <> 0 Then
							ProcessResultCode(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
							Return False;
						EndIf;
					EndIf;
				EndDo;
				
				// Print cliche
				If vDoPrintClicheAtEnd Then
					If vFR.printCliche() <> 0 Then
						ProcessResultCode(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
						Return False;
					EndIf;
				Else
					For s = 0 To 5 Do
						vFR.printText();
					EndDo;
				EndIf;
				
				// Cut off cheque
				vFR.setParam(vFR.LIBFPTR_PARAM_PRINT_FOOTER, False);
				vFR.endNonfiscalDocument();
				// Disconnect
				Disconnect(vFR);
				Return True;		
			Else
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);	
			EndIf;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintNonFiscalCheque

// -----------------------------------------------------------------------------
Function pmPrintZReport(rMessage, pObj, pPasswordKKM = "") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pObj.CashRegister);
	// Try to connect
	vFR = Connect(rMessage,vArrCashRegister);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Check if the session is already closed
			vAlreadyClosed = False;
			vFR.setParam(vFR.LIBFPTR_PARAM_DATA_TYPE, vFR.LIBFPTR_DT_STATUS);
			If vFR.queryData() <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), rMessage);
				Return False;
			EndIf;
			If vFR.getParamInt(vFR.LIBFPTR_PARAM_SHIFT_STATE) = vFR.LIBFPTR_SS_CLOSED Then
				//session is closed
				rMessage = NStr("ru = 'На ККМ смена уже закрыта!'; en = 'Session is already closed at device!'; de = 'Ist die Schicht bereits geschlossen!'");
				tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
				tcOnServer.cmWriteLogEventAtServer(NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"),,,,rMessage);
				vAlreadyClosed = True;
			EndIf;
			If Not vAlreadyClosed Then 
				// Close open cheque if any
				CloseOpenCheque(vFR, , , vArrCashRegister.IgnoreEndOfPaperError);
				// Set cashier name
				vCashier = tcOnServer.cmGetCurrentUserAttribute();
				If ValueIsFilled(vCashier) Then
					vCashierName = tcCashRegisters.GetCashierName(vCashier);
					If Not IsBlankString(vCashierName) Then
						vFR.setParam(1021, vCashierName);
						// Set TIN
						vEmployeeTIN = TrimAll(tcOnServer.cmGetAttributeByRef(vCashier, "TIN"));
						If Not IsBlankString(vEmployeeTIN) Then
							vFR.setParam(1203, vEmployeeTIN);
						EndIf;
					EndIf;
				EndIf;
				
				// Close session
				vFR.operatorLogin();
				vFR.setParam(vFR.LIBFPTR_PARAM_REPORT_TYPE, vFR.LIBFPTR_RT_CLOSE_SHIFT);
				If vFR.report() <> 0 Then
					ProcessResultCode(vFR, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), rMessage);
					Return False;
				EndIf;
				// Log cash register operation
				tcOnServer.cmWriteLogEventAtServer(NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), , , , rMessage);
				// Open drawer
				Try
					vFR.openDrawer();
				Except
				EndTry;
			EndIf;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), rMessage);
			Return False;
		EndTry;
		Try
			vBreakOpenNewSession = False;
			// Check time difference between workstation and cash register and correct 
			// device time if difference is more then 5 minutes
			If Not CheckTimeDifference(vFR, rMessage) Then
				#IF THINCLIENT THEN
					ShowUserNotification(NStr("en = 'Time setting error in cash register'; de = 'Zeiteinstellungsfehler in der Registrierkassen'; ru = 'Ошибка установки времени в ККМ'"), , rMessage, PictureLib.InformationMedium, UserNotificationStatus.Important, pObj.Ref); 	
				#ENDIF
				vBreakOpenNewSession = True;
			EndIf;
			// Open new session
			If Not vArrCashRegister.DoNotOpenNewSessionAfterZReport And Not vBreakOpenNewSession Then
				// Set cashier name
				If ValueIsFilled(vCashier) Then
					If Not IsBlankString(vCashierName) Then
						vFR.setParam(1021, vCashierName);					
						// Set TIN
						If Not IsBlankString(vEmployeeTIN) Then
							vFR.setParam(1203, vEmployeeTIN);
						EndIf;
					EndIf;
				EndIf;
				// Open session
				vFR.operatorLogin();
				vFR.openShift();
			EndIf;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), rMessage);
		EndTry;
	EndIf;
	// Disconnect
	Disconnect(vFR);
	Return True;
EndFunction // pmPrintZReport

// -----------------------------------------------------------------------------
Function pmPrintCurrentStateOfCalculationsReport(rMessage, pObj, pPasswordKKM="") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pObj);
	// Try to connect
	vFR = Connect(rMessage, vArrCashRegister);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Close open cheque if any
			CloseOpenCheque(vFR, , , vArrCashRegister.IgnoreEndOfPaperError);
			// Do report	
			vFR.setParam(vFR.LIBFPTR_PARAM_REPORT_TYPE, vFR.LIBFPTR_RT_OFD_EXCHANGE_STATUS);
			If vFR.report() <> 0 Then
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
Function pmPrintXReport(rMessage,pCashRegister,pPasswordKKM="") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pCashRegister);
	// Try to connect
	vFR = Connect(rMessage,vArrCashRegister);
	
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Close open cheque if any
			CloseOpenCheque(vFR, , , vArrCashRegister.IgnoreEndOfPaperError);
			// Do report
			vFR.setParam(vFR.LIBFPTR_PARAM_REPORT_TYPE, vFR.LIBFPTR_RT_X);
			If vFR.report() <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"), rMessage);
				Return False;
			EndIf;
			// Log cash register operation
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"), , , , rMessage);
			// Open drawer
			Try
				vFR.openDrawer();
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
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pCashRegister);
	// Try to connect
	vFR = Connect(rMessage, vArrCashRegister);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Close open cheque if any
			CloseOpenCheque(vFR, , , vArrCashRegister.IgnoreEndOfPaperError);
			// Do report
			vFR.setParam(vFR.LIBFPTR_PARAM_REPORT_TYPE, vFR.LIBFPTR_RT_HOURS);
			If vFR.report() <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintDeviceHourXReport'; de='CashRegister.PrintDeviceHourXReport'; ru='ККМ.ПечатьПочасовогоХОтчетаПоФР'"), rMessage);
				Return False;
			EndIf;	
			// Log cash register operation
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CashRegister.PrintDeviceHourXReport'; de='CashRegister.PrintDeviceHourXReport'; ru='ККМ.ПечатьПочасовогоХОтчетаПоФР'"),  ,  ,  , rMessage);
			// Open drawer
			Try
				vFR.openDrawer();
			Except
			EndTry;
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintDeviceHourXReport'; de='CashRegister.PrintDeviceHourXReport'; ru='ККМ.ПечатьПочасовогоХОтчетаПоФР'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintHourXReport

// -----------------------------------------------------------------------------
Function pmPrintSlip(pSlipTextArr, pCashRegister, rMessage, pPasswordKKM="", pOneCopyOnly = False) Export
	If TypeOf(pCashRegister) = Type("Structure") Then  
		vArrCashRegister = pCashRegister;
	Else 
		vArrCashRegister =  tcOnServer.cmGetAtributeAsArray(pCashRegister);
	EndIf;
	
	// Try to connect
	vFR = Connect(rMessage, vArrCashRegister);
	
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Close open cheque if any
			CloseOpenCheque(vFR, , , vArrCashRegister.IgnoreEndOfPaperError);
			
			// Print all strings in the array
			If Not PrintSlipLines(vFR, pSlipTextArr, vArrCashRegister, rMessage, pOneCopyOnly) Then
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
Function pmPrintCashIncome(Val pSum, pObj, rMessage, pPasswordKKM="") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pObj.CashRegister);
	// Try to connect
	vFR = Connect(rMessage, vArrCashRegister);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Close open cheque if any
			CloseOpenCheque(vFR, pPasswordKKM, vArrCashRegister.DoNotOpenNewSessionAfterZReport, vArrCashRegister.IgnoreEndOfPaperError);
			
			// Do cash income
			vFR.setParam(vFR.LIBFPTR_PARAM_SUM,  pSum);
			If vFR.cashIncome() <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintCashIncome'; de='CashRegister.PrintCashIncome'; ru='ККМ.ПечатьЧекаВнесенияДенег'"), rMessage);
				Return False;
			EndIf;	
			
			// Open drawer
			Try
				vFR.openDrawer();
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
Function pmPrintCashOutcome(Val pSum, pObj, rMessage, pPasswordKKM="") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pObj.CashRegister);
	// Try to connect
	vFR = Connect(rMessage, vArrCashRegister);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Close open cheque if any
			CloseOpenCheque(vFR, pPasswordKKM, vArrCashRegister.DoNotOpenNewSessionAfterZReport, vArrCashRegister.IgnoreEndOfPaperError);
			
			// Do cash outcome
			vFR.setParam(vFR.LIBFPTR_PARAM_SUM, pSum);
			If vFR.cashOutcome() <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintCashOutcome'; de='CashRegister.PrintCashOutcome'; ru='ККМ.ПечатьЧекаИнкассации'"), rMessage);
				Return False;
			EndIf;	
			
			// Open drawer
			Try
				vFR.openDrawer();
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
	vFR = Connect(rMessage,vArrCashRegister);
	If vFR = Undefined Then
		Return False;
	Else 
		// Open drawer
		Try
			CloseOpenCheque(vFR, , vArrCashRegister.DoNotOpenNewSessionAfterZReport, True);
			
			vFR.openDrawer();
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

// -----------------------------------------------------------------------------
Function pmGetFDF(rMessage, pCashRegister) Export
	vFDF = Undefined;
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pCashRegister);
	// Try to connect
	vFR = Connect(rMessage,vArrCashRegister);
	If vFR = Undefined Then
		Return Undefined;
	Else 
		// Open drawer
		Try			
			vFR.setParam(vFR.LIBFPTR_PARAM_FN_DATA_TYPE, vFR.LIBFPTR_FNDT_FFD_VERSIONS);
			vFR.fnQueryData();  
			
			If vFR.GetParamInt(vFR.LIBFPTR_PARAM_FFD_VERSION) = vFR.LIBFPTR_FFD_1_2 Then
				vFDF = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2");	
			ElsIf vFR.GetParamInt(vFR.LIBFPTR_PARAM_FFD_VERSION) = vFR.LIBFPTR_FFD_1_1 Then
				vFDF = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_1");					
			Else
				vFDF = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_0_5");	
			EndIf;
		Except
			rMessage = ErrorDescription();
			Disconnect(vFR);
			Return Undefined;
		EndTry;		
	EndIf;
	// Disconnect
	Disconnect(vFR);
	Return vFDF;	
EndFunction // pmGetFDF

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetPort(vFR, pCashRegister)
	vPort = TrimAll(pCashRegister.Port);
	If vPort = "АТОЛ USB" Then
		Return vFR.LIBFPTR_PORT_USB;
	ElsIf vPort = "TCP/IP (клиент)" Then
		Return vFR.LIBFPTR_PORT_TCPIP;
	Else
		Return vFR.LIBFPTR_PORT_COM; 
	EndIf;
EndFunction // GetPortNumber8

// -----------------------------------------------------------------------------
Function GetBaudRate(vFR, pCashRegister)
	vBaudRate = pCashRegister.BaudRate;
	If vBaudRate = 1200 Then
		Return vFR.LIBFPTR_PORT_BR_1200;
	ElsIf vBaudRate = 2400 Then
		Return vFR.LIBFPTR_PORT_BR_2400;
	ElsIf vBaudRate = 4800 Then
		Return vFR.LIBFPTR_PORT_BR_4800;
	ElsIf vBaudRate = 9600 Then
		Return vFR.LIBFPTR_PORT_BR_9600;
	ElsIf vBaudRate = 19200 Then
		Return vFR.LIBFPTR_PORT_BR_19200;
	ElsIf vBaudRate = 38400 Then
		Return vFR.LIBFPTR_PORT_BR_38400;
	ElsIf vBaudRate = 57600 Then
		Return vFR.LIBFPTR_PORT_BR_57600;
	ElsIf vBaudRate = 115200 Then
		Return vFR.LIBFPTR_PORT_BR_115200;
	ElsIf vBaudRate = 230400 Then
		Return vFR.LIBFPTR_PORT_BR_230400;
	ElsIf vBaudRate = 460800 Then
		Return vFR.LIBFPTR_PORT_BR_460800;
	ElsIf vBaudRate = 921600 Then
		Return vFR.LIBFPTR_PORT_BR_921600;
	Else
		Return vFR.LIBFPTR_PORT_BR_9600;	
	EndIf;		
EndFunction // GetBaudRate

// -----------------------------------------------------------------------------
Procedure ProcessResultCode(pFR, pFunction, rMessage)
	vErrorMessage = rMessage;
	If pFR.errorCode() <> 0 Then
		rMessage = ?(Not IsBlankString(rMessage), rMessage + Chars.LF, "") + TrimAll(pFR.errorDescription());
		vErrorMessage = "Result code: " + pFR.errorCode() + ", result description: " + rMessage;
	EndIf;
	tcOnServer.cmWriteLogEventAtServer(pFunction, "Error", , , vErrorMessage);
	Disconnect(pFR);
EndProcedure // ProcessResultCode

// -----------------------------------------------------------------------------
Function GetOtherTypeClose(pCashRegisterChequeCloseType, vOpenDrawer) 
	vCloseTypeClose = "LIBFPTR_PT_CASH";
	If pCashRegisterChequeCloseType = 0 Then
		vCloseTypeClose = "LIBFPTR_PT_CASH";
		vOpenDrawer = True;
	ElsIf pCashRegisterChequeCloseType = 1 Then
		vCloseTypeClose = "LIBFPTR_PT_ELECTRONICALLY";	
	ElsIf pCashRegisterChequeCloseType = 2 Then
		vCloseTypeClose = "LIBFPTR_PT_PREPAID";	
	ElsIf pCashRegisterChequeCloseType = 3 Then
		vCloseTypeClose = "LIBFPTR_PT_CREDIT";	
	ElsIf pCashRegisterChequeCloseType = 4 Then
		vCloseTypeClose = "LIBFPTR_PT_OTHER";	
	ElsIf pCashRegisterChequeCloseType = 5 Then
		vCloseTypeClose = "LIBFPTR_PT_6";	
	ElsIf pCashRegisterChequeCloseType = 6 Then
		vCloseTypeClose = "LIBFPTR_PT_7";	
	ElsIf pCashRegisterChequeCloseType = 7 Then
		vCloseTypeClose = "LIBFPTR_PT_8";	
	ElsIf pCashRegisterChequeCloseType = 8 Then
		vCloseTypeClose = "LIBFPTR_PT_9";	
	ElsIf pCashRegisterChequeCloseType = 9 Then
		vCloseTypeClose = "LIBFPTR_PT_10";	
	EndIf;
	Return vCloseTypeClose;
EndFunction // GetOtherTypeClose

// -----------------------------------------------------------------------------
Procedure ProcessException(pFR, pFunction, rMessage)
	tcOnServer.cmWriteLogEventAtServer(pFunction,,,, "Error description: " + rMessage);
	Disconnect(pFR);
EndProcedure // ProcessException

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
Function GetTaxGroup(pObj, rVATRate = Undefined, pRowVATRate = Undefined, pDocObj = Undefined)
	vAtolTaxGroup = "LIBFPTR_TAX_DEPARTMENT";
	
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
		Return vAtolTaxGroup;
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
		vAtolTaxGroup = "LIBFPTR_TAX_NO";
	ElsIf vTaxRate = 0 Then
		vAtolTaxGroup = "LIBFPTR_TAX_VAT0";
	ElsIf vTaxRate = 5 Then
		If vTaxGroup > 4 Then
			vAtolTaxGroup = "LIBFPTR_TAX_VAT105";
		Else
			vAtolTaxGroup = "LIBFPTR_TAX_VAT5";
		EndIf;
	ElsIf vTaxRate = 7 Then
		If vTaxGroup > 4 Then
			vAtolTaxGroup = "LIBFPTR_TAX_VAT107";
		Else
			vAtolTaxGroup = "LIBFPTR_TAX_VAT7";
		EndIf;
	ElsIf vTaxRate = 10 Then
		If vTaxGroup > 4 Then
			vAtolTaxGroup = "LIBFPTR_TAX_VAT110";
		Else
			vAtolTaxGroup = "LIBFPTR_TAX_VAT10";
		EndIf;
	ElsIf vTaxRate = 18 Then 
		vAtolTaxGroup = "LIBFPTR_TAX_VAT18";
	ElsIf vTaxRate = 20 Then
		If vTaxGroup > 4 Then
			vAtolTaxGroup = "LIBFPTR_TAX_VAT120";
		Else
			vAtolTaxGroup = "LIBFPTR_TAX_VAT20";
		EndIf;
	ElsIf vTaxRate = 22 Then
		If vTaxGroup > 4 Then
			vAtolTaxGroup = "LIBFPTR_TAX_VAT122";
		Else
			vAtolTaxGroup = "LIBFPTR_TAX_VAT22";
		EndIf;
	Else
		If vTaxGroup > 4 Then
			vAtolTaxGroup = "LIBFPTR_TAX_VAT1" + Format(vTaxRate, "ND=2; NLZ=; NG=");
		Else
			vAtolTaxGroup = "LIBFPTR_TAX_VAT" + Format(vTaxRate, "ND=2; NLZ=; NG=");
		EndIf;
	EndIf;
	Return vAtolTaxGroup;
EndFunction // GetTaxGroup

// -----------------------------------------------------------------------------
Function PrintSlipLines(pFR, pSlipTextArr, pArrCashRegister, rMessage, pOneCopyOnly = False)
	If pFR.beginNonfiscalDocument() = 0 Then
		vArrCashRegister = pArrCashRegister;
		// Print first slip for the hotel
		For Each vStr In pSlipTextArr Do
			pFR.setParam(pFR.LIBFPTR_PARAM_TEXT_WRAP, pFR.LIBFPTR_TW_NONE);
			pFR.setParam(pFR.LIBFPTR_PARAM_TEXT, vStr);
			If pFR.printText() <> 0 Then
				CancelNonfiscalCheque(pFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
		EndDo;
		pFR.setParam(pFR.LIBFPTR_PARAM_PRINT_FOOTER, False);
		pFR.endNonfiscalDocument();
	Else
		ProcessResultCode(pFR, NStr("en='CashRegister.PrintSlip'; de='CashRegister.PrintSlip'; ru='ККМ.ПечатьСлипа'"), rMessage);
		Return False;
	EndIf;
	If pOneCopyOnly Then
		Return True;
	EndIf;
	If pFR.beginNonfiscalDocument() = 0 Then
		// Print second slip for the client
		pFR.setParam(pFR.LIBFPTR_PARAM_TEXT_WRAP, pFR.LIBFPTR_TW_NONE);
		pFR.setParam(pFR.LIBFPTR_PARAM_TEXT, NStr("ru='ДЛЯ КЛИЕНТА'; en='FOR THE CLIENT'; de='FÜR DEN KUNDEN'"));
		If pFR.printText() <> 0 Then
			CancelNonfiscalCheque(pFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
			Return False;
		EndIf;
		For Each vStr In pSlipTextArr Do
			pFR.setParam(pFR.LIBFPTR_PARAM_TEXT_WRAP, pFR.LIBFPTR_TW_NONE);
			pFR.setParam(pFR.LIBFPTR_PARAM_TEXT, vStr);
			If pFR.printText() <> 0 Then
				CancelNonfiscalCheque(pFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
		EndDo;
		pFR.setParam(pFR.LIBFPTR_PARAM_PRINT_FOOTER, False);
		pFR.endNonfiscalDocument();
	Else
		ProcessResultCode(pFR, NStr("en='CashRegister.PrintSlip'; de='CashRegister.PrintSlip'; ru='ККМ.ПечатьСлипа'"), rMessage);
		Return False;
	EndIf;
	Return True;
EndFunction // PrintSlipLines

// -----------------------------------------------------------------------------
Function CheckTimeDifference(pFR, rMessage)
	pFR.setParam(pFR.LIBFPTR_PARAM_DATA_TYPE, pFR.LIBFPTR_DT_STATUS);
	If pFR.queryData() = 0 Then
		vFRDate = pFR.getParamDateTime(pFR.LIBFPTR_PARAM_DATE_TIME);
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
			rMessage = NStr("en='Check date in the cash register!'; de='Überprüfen Datum im Kasse!'; ru='Проверьте дату в ККМ!'");
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
	vCurDate = tcOnServer.cmGetServerCurrentSessionDate();
	// Connect
	If Not pFR.isOpened() Then
		pFR.open();
	EndIf;
	
	pFR.setParam(pFR.LIBFPTR_PARAM_DATE_TIME, vCurDate);
	If pFR.writeDateTime() <> 0 Then
		ProcessResultCode(pFR, NStr("en='CashRegister.SetDeviceTime'; de='CashRegister.SetDeviceTime'; ru='ККМ.УстановкаВремени'"), rMessage);
		Return False;
	EndIf;
	Return True;
EndFunction // SetDeviceTime

// -----------------------------------------------------------------------------
Function GetTaxationSystemCode(pObj, rTaxSystem = Undefined)
	rTaxSystem = Undefined;
	vTaxSystemChar = "";
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
		If rTaxSystem = PredefinedValue("Enum.TaxationSystems.Common") Then
			vTaxSystemChar = "LIBFPTR_TT_OSN";
		ElsIf rTaxSystem = PredefinedValue("Enum.TaxationSystems.SimplifiedIncome") Then
			vTaxSystemChar = "LIBFPTR_TT_USN_INCOME";
		ElsIf rTaxSystem = PredefinedValue("Enum.TaxationSystems.SimplifiedIncomeMinusOutcome") Then
			vTaxSystemChar = "LIBFPTR_TT_USN_INCOME_OUTCOME";
		ElsIf rTaxSystem = PredefinedValue("Enum.TaxationSystems.UnifiedTaxOnImputedIncome") Then
			vTaxSystemChar = "LIBFPTR_TT_ENVD";
		ElsIf rTaxSystem = PredefinedValue("Enum.TaxationSystems.UnifiedAgriculturalTax") Then
			vTaxSystemChar = "LIBFPTR_TT_ESN";
		ElsIf rTaxSystem = PredefinedValue("Enum.TaxationSystems.PatentTaxationSystem") Then
			vTaxSystemChar = "LIBFPTR_TT_PATENT";
		EndIf;			
	EndIf;
	Return vTaxSystemChar;
EndFunction // GetTaxationSystemCode

// -----------------------------------------------------------------------------
Procedure CancelCheque(pFR, pFunction, rMessage)
	vErrorMessage = rMessage;
	If pFR.errorCode() <> 0 Then
		rMessage = ?(Not IsBlankString(rMessage), rMessage + Chars.LF, "") + TrimAll(pFR.errorDescription());
		vErrorMessage = "Result code: " + pFR.errorCode() + ", result description: " + rMessage;
	EndIf;
	tcOnServer.cmWriteLogEventAtServer(pFunction, , , , vErrorMessage);
	Try
		pFR.cancelReceipt();
	Except
	EndTry;
	Disconnect(pFR);
EndProcedure // CancelCheque

// -----------------------------------------------------------------------------
Procedure OnlyCancelCheque(pFR)
	Try
		pFR.cancelReceipt();
	Except
	EndTry;
	Disconnect(pFR);
EndProcedure // CancelCheque

// -----------------------------------------------------------------------------
Procedure CancelNonfiscalCheque(pFR, pFunction, rMessage)
	rMessage = TrimAll(pFR.errorDescription());
	tcCommonFunctionOnClientServer.TextMessage(rMessage);
	tcOnServer.cmWriteLogEventAtServer(pFunction,,,,"Result code: " + pFR.errorCode() + ", result description: " + rMessage);
	Try
		pFR.endNonfiscalDocument();
	Except
	EndTry;
	Disconnect(pFR);
EndProcedure // CancelCheque

// -----------------------------------------------------------------------------
Function Connect(rMessage, vArrCashRegister)
	// Reset return status
	rMessage = "";
	#IF NOT MobileClient THEN
		// Try to load external component
		Try
			vFR = New COMObject("AddIn.Fptr10");
			
			// Apply connection parameters
			If ValueIsFilled(vArrCashRegister.CashRegisterModel) Then
				vModel = "";
				Execute("vModel = TrimAll(vFR." + TrimAll(vArrCashRegister.CashRegisterModel) + ");");
				If ValueIsFilled(vModel) Then
					vFR.setSingleSetting(vFR.LIBFPTR_SETTING_MODEL, vModel);
				Else
					vFR.setSingleSetting(vFR.LIBFPTR_SETTING_MODEL, TrimAll(vFR.LIBFPTR_MODEL_ATOL_AUTO));	
				EndIf;
			Else
				vFR.setSingleSetting(vFR.LIBFPTR_SETTING_MODEL, TrimAll(vFR.LIBFPTR_MODEL_ATOL_AUTO));
			EndIf;
			If ValueIsFilled(vArrCashRegister.AccessPassword) Then
				vFR.setSingleSetting(vFR.LIBFPTR_SETTING_ACCESS_PASSWORD, TrimAll(vArrCashRegister.AccessPassword));
			EndIf;
			If ValueIsFilled(vArrCashRegister.CashRegisterPassword) Then
				vFR.setSingleSetting(vFR.LIBFPTR_SETTING_USER_PASSWORD, TrimAll(vArrCashRegister.CashRegisterPassword));
			EndIf;
			vFR.setSingleSetting(vFR.LIBFPTR_SETTING_PORT, TrimAll(GetPort(vFR, vArrCashRegister)));
			If TrimAll(vArrCashRegister.Port) = "TCP/IP (клиент)" Then
				If ValueIsFilled(vArrCashRegister.Address) Then
					vAddress = StrSplit(vArrCashRegister.Address, ":", False);
					If vAddress.Count() = 2 Then
						vFR.setSingleSetting(vFR.LIBFPTR_SETTING_IPADDRESS, TrimAll(vAddress[0]));
						vFR.setSingleSetting(vFR.LIBFPTR_SETTING_IPPORT, TrimAll(vAddress[1]));
					Else
						vFR.setSingleSetting(vFR.LIBFPTR_SETTING_IPADDRESS, TrimAll(vArrCashRegister.Address));	
					EndIf;
				EndIf;
			ElsIf TrimAll(vArrCashRegister.Port) <> "АТОЛ USB" Then
				vFR.setSingleSetting(vFR.LIBFPTR_SETTING_COM_FILE, TrimAll(vArrCashRegister.Port));
				vFR.setSingleSetting(vFR.LIBFPTR_SETTING_BAUDRATE, TrimAll(GetBaudRate(vFR, vArrCashRegister)));
			EndIf;
			vFR.applySingleSettings();
			// Check result code
			If vFR.open() = 0 Then
				// OK
				Return vFR;			
			Else
				// Error connecting to the device
				rMessage = TrimAll(vFR.errorDescription());
				Return Undefined;
			EndIf;
		Except
			rMessage = ErrorDescription();
			Return Undefined;
		EndTry;
	#ELSE
		Return Undefined;
	#ENDIF
EndFunction // Connect

// -----------------------------------------------------------------------------
Procedure Disconnect(pFR)
	Try
		If pFR.close() <> 0 Then
			tcCommonFunctionOnClientServer.TextMessage(TrimAll(pFR.errorDescription()));
		EndIf;
		pFR = Undefined;
	Except
	EndTry;
EndProcedure // Disconnect

// -----------------------------------------------------------------------------
Procedure CloseOpenCheque(pFR, pPasswordKKM = "", pOpenSessionIfClosed = False, pIgnoreEndOfPaperError = False)
	// Connect
	If Not pFR.isOpened() Then
		pFR.open();
	EndIf;
	pFR.setParam(pFR.LIBFPTR_PARAM_DATA_TYPE, pFR.LIBFPTR_DT_STATUS);
	// Get advanced mode
	If pFR.queryData() = 0 Then		
		If pFR.getParamInt(pFR.LIBFPTR_PARAM_RECEIPT_TYPE) <> pFR.LIBFPTR_RT_CLOSED  Then
			pFR.cancelReceipt();
		ElsIf Not pFR.getParamBool(pFR.LIBFPTR_PARAM_RECEIPT_PAPER_PRESENT) And Not pIgnoreEndOfPaperError Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Cheque ribbon is almost over!'; de='Scheck Band ist fast vorbei!'; ru='В ККМ заканчивается бумага!'"), MessageStatus.Attention);
		EndIf;
		If pOpenSessionIfClosed Then
			If pFR.getParamInt(pFR.LIBFPTR_PARAM_SHIFT_STATE) = pFR.LIBFPTR_SS_CLOSED Then
				// Set cashier name
				vCashier = tcOnServer.cmGetCurrentUserAttribute();
				If ValueIsFilled(vCashier) Then
					vCashierName = tcCashRegisters.GetCashierName(vCashier);
					If Not IsBlankString(vCashierName) Then
						pFR.setParam(1021, vCashierName);
						
						// Set TIN
						vEmployeeTIN = TrimAll(tcOnServer.cmGetAttributeByRef(vCashier, "TIN"));
						If Not IsBlankString(vEmployeeTIN) Then
							pFR.setParam(1203, vEmployeeTIN);
						EndIf;
					EndIf;
				EndIf;
				// Open session
				pFR.operatorLogin();
				pFR.openShift();
				tcOnServer.Wait(5);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // CloseOpenCheque

// -----------------------------------------------------------------------------
Procedure PrintFolioHeader(pFR, pObj, pArrCashRegister)
	vArrCashRegister= pArrCashRegister;
	// Header start delimeter
	pFR.setParam(pFR.LIBFPTR_PARAM_TEXT, GetString("-----------------------------------------------------------------------",vArrCashRegister));
	pFR.setParam(pFR.LIBFPTR_PARAM_TEXT_WRAP, pFR.LIBFPTR_TW_NONE);
	pFR.printText();
	// Folio #
	vFolioRef = pObj.Folio;
	vFolioNumber = tcOnServer.cmGetAttributeByRef(vFolioRef, "Number");
	pFR.setParam(pFR.LIBFPTR_PARAM_TEXT, GetString(NStr("ru='Фолио № '; en='Folio # '; de='Folio Nr. '") + tcOnServer.GetDocumentNumberPresentation(vFolioNumber), vArrCashRegister));
	pFR.setParam(pFR.LIBFPTR_PARAM_TEXT_WRAP, pFR.LIBFPTR_TW_NONE);
	pFR.printText();
	// Room
	If Not pArrCashRegister.DoNotPrintRoom Then
		pFR.setParam(pFR.LIBFPTR_PARAM_TEXT, GetString(NStr("en='Room  : ';ru='Номер : ';de='Zimmer:'") + TrimAll(tcOnServer.cmGetAttributeByRef(tcOnServer.cmGetAttributeByRef(vFolioRef, "Room"), "Description")), vArrCashRegister)); 
		pFR.setParam(pFR.LIBFPTR_PARAM_TEXT_WRAP, pFR.LIBFPTR_TW_NONE);
		pFR.printText();
	EndIf;
	// Guest
	If Not pArrCashRegister.DoNotPrintClient Then
		If (TypeOf(pObj.Ref) = Type("DocumentRef.Payment") Or TypeOf(pObj.Ref) = Type("DocumentRef.Return")) And ValueIsFilled(pObj.Payer) Then
			pFR.setParam(pFR.LIBFPTR_PARAM_TEXT, GetString(NStr("en='Client: ';ru='Клиент: ';de='Kunde : '") + TrimAll(tcOnServer.cmGetAttributeByRef(pObj.Payer, "Description")), vArrCashRegister));
		Else
			pFR.setParam(pFR.LIBFPTR_PARAM_TEXT, GetString(NStr("en='Client: ';ru='Клиент: ';de='Kunde : '") + TrimAll(tcOnServer.cmGetAttributeByRef(tcOnServer.cmGetAttributeByRef(vFolioRef, "Client"), "Description")), vArrCashRegister));
		EndIf;
		pFR.setParam(pFR.LIBFPTR_PARAM_TEXT_WRAP, pFR.LIBFPTR_TW_NONE);
		pFR.printText();
	EndIf;
	// Guest group
	pFR.setParam(pFR.LIBFPTR_PARAM_TEXT, GetString(NStr("en='Group : ';ru='Группа: ';de='Gruppe: '") + TrimAll(tcOnServer.cmGetAttributeByRef(pObj.GuestGroup, "Code")), vArrCashRegister)); 
	pFR.setParam(pFR.LIBFPTR_PARAM_TEXT_WRAP, pFR.LIBFPTR_TW_NONE);
	pFR.printText();
	// Document
	pFR.setParam(pFR.LIBFPTR_PARAM_TEXT, GetString(NStr("ru = 'Док.  № '; en='Doc.  # '; de='Dok.  Nr. '") + tcOnServer.GetDocumentNumberPresentation(pObj.Number), vArrCashRegister));
	pFR.setParam(pFR.LIBFPTR_PARAM_TEXT_WRAP, pFR.LIBFPTR_TW_NONE);
	pFR.printText();
	// Header end delimeter
	pFR.setParam(pFR.LIBFPTR_PARAM_TEXT, GetString("-----------------------------------------------------------------------", vArrCashRegister)); 
	pFR.setParam(pFR.LIBFPTR_PARAM_TEXT_WRAP, pFR.LIBFPTR_TW_NONE);
	pFR.printText();
EndProcedure // PrintFolioHeader

// -----------------------------------------------------------------------------
Function CheckMarkingCode(pFR, pIsPayment, pService, pMarkingCode, rStatus, pCancelReceiptPrintingWhenMarkingCheckError, pMarkingCodeVerificationTimeout, rMessage)
	rStatus = GetMarkingCodeStatus(pFR, pIsPayment, pService); 
	
	pFR.setParam(pFR.LIBFPTR_PARAM_MARKING_CODE_TYPE, pFR.LIBFPTR_MCT12_AUTO);
	pFR.setParam(pFR.LIBFPTR_PARAM_MARKING_CODE, GetStringFromBinaryData(Base64Value(pMarkingCode)));
	pFR.setParam(pFR.LIBFPTR_PARAM_MARKING_CODE_STATUS, rStatus);
	pFR.setParam(pFR.LIBFPTR_PARAM_MARKING_PROCESSING_MODE, 0);
	pFR.beginMarkingCodeValidation();
	
	tcOnServer.Wait(1);
	
	vMinSeconds = 5;
	vMilliseconds = 1000;
	vMaxDateTime = CurrentUniversalDateInMilliseconds() + (?(pMarkingCodeVerificationTimeout > vMinSeconds, pMarkingCodeVerificationTimeout, vMinSeconds) * vMilliseconds);
	
	While True Do
		pFR.getMarkingCodeValidationStatus();
		If pFR.getParamBool(pFR.LIBFPTR_PARAM_MARKING_CODE_VALIDATION_READY) Then
			Break;
		EndIf;
		
		If CurrentUniversalDateInMilliseconds() > vMaxDateTime Then
			rMessage = NStr("en = 'Maximum time for checking the marking code has been exceeded'; de = 'Maximale Zeit für die Überprüfung des Markierungscodes überschritten'; ru = 'Привышено максимальное время проверки кода маркировки'");
			pFR.cancelMarkingCodeValidation();
			Return Undefined;
		EndIf;
	EndDo;
	
	vValidationResult = pFR.getParamInt(pFR.LIBFPTR_PARAM_MARKING_CODE_ONLINE_VALIDATION_RESULT);
	If vValidationResult <> 15 And pCancelReceiptPrintingWhenMarkingCheckError Then
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
		pFR.declineMarkingCode();
		Return Undefined;
	EndIf;
	
	pFR.acceptMarkingCode();
	
	Return vValidationResult;
EndFunction // CheckMarkingCode

// -----------------------------------------------------------------------------
Function GetMarkingCodeStatus(pFR, pIsPayment, pService)
	If pIsPayment Then 
		If CheckUnitPiece(pFR, pService) Then
			Return pFR.LIBFPTR_MES_PIECE_SOLD;
		Else
			Return pFR.LIBFPTR_MES_DRY_FOR_SALE;
		EndIf;
	Else
		If CheckUnitPiece(pFR, pService) Then
			Return pFR.LIBFPTR_MES_PIECE_RETURN; 
		Else
			Return pFR.LIBFPTR_MES_DRY_RETURN; 
		EndIf;
	EndIf;
EndFunction // GetMarkingCodeStatus

// -----------------------------------------------------------------------------
Function CheckUnitPiece(pFR, pService)
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
EndFunction // CheckUnitPiece

// -----------------------------------------------------------------------------
Function GetIndustryInfo(pFR, pIsPayment, pPaymentModeTypeValue, pChargesWithMarkingCode, pMarkingCode)
	vFullSettlement = 4;
	vPartialSettlementAndCredit = 5;
	vTransferToCredit = 6;
	
	If (pPaymentModeTypeValue <> vFullSettlement And pPaymentModeTypeValue <> vPartialSettlementAndCredit And pPaymentModeTypeValue <> vTransferToCredit) Or Not pIsPayment Or IsBlankString(pMarkingCode) Or pChargesWithMarkingCode[pMarkingCode] = Undefined Then
		Return Undefined;
	EndIf;
	
	vChargeWithMarkingCode = pChargesWithMarkingCode[pMarkingCode];
	If IsBlankString(vChargeWithMarkingCode["MarkingCodeCheckUUID"]) Or IsBlankString(vChargeWithMarkingCode["MarkingCodeCheckDate"]) Then
		Return Undefined;
	EndIf;
	
	pFR.setParam(1262, "030");
	pFR.setParam(1263, "21.11.2023");
	pFR.setParam(1264, "1944");
	pFR.setParam(1265, StrTemplate("UUID=%1&Time=%2", TrimAll(vChargeWithMarkingCode["MarkingCodeCheckUUID"]), TrimAll(vChargeWithMarkingCode["MarkingCodeCheckDate"])));
	pFR.utilFormTlv();
	Return pFR.getParamByteArray(pFR.LIBFPTR_PARAM_TAG_VALUE);
EndFunction // GetIndustryInfo

// -----------------------------------------------------------------------------
Function pmPrintCheque_BeforeOpenCheque(vFR, vArrCashRegister, Val pSum, Val pVATSum, pObj, pObjRef, rMessage, pPasswordKKM="", pServices = Undefined, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101', pSendPayerContactsToOFD = 0, pEmailToSendToOFD = "", pPhoneToSendToOFD = "")
	// Put code in extension of this function if necessary
	Return True;
EndFunction // pmPrintCheque_BeforeOpenCheque

// -----------------------------------------------------------------------------
Function pmPrintCheque_BeforeOpenChequeTLV(vFR, vArrCashRegister, Val pSum, Val pVATSum, pObj, pObjRef, rMessage, pPasswordKKM="", pServices = Undefined, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101', pSendPayerContactsToOFD = 0, pEmailToSendToOFD = "", pPhoneToSendToOFD = "", rTLVArray)
	// Put code in extension of this function if necessary
	Return True;
EndFunction // pmPrintCheque_BeforeOpenChequeTLV

// -----------------------------------------------------------------------------
Function pmPrintCheque_AfterOpenCheque(vFR, vArrCashRegister, vChargesWithMarkingCode, Val pSum, Val pVATSum, pObj, pObjRef, rMessage, pPasswordKKM="", pServices = Undefined, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101', pSendPayerContactsToOFD = 0, pEmailToSendToOFD = "", pPhoneToSendToOFD = "")
	// Put code in extension of this function if necessary
	Return True;
EndFunction // pmPrintCheque_AfterOpenCheque

// -----------------------------------------------------------------------------
Function pmPrintCheque_AfterOpenChequeTLV(vFR, vArrCashRegister, vChargesWithMarkingCode, Val pSum, Val pVATSum, pObj, pObjRef, rMessage, pPasswordKKM="", pServices = Undefined, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101', pSendPayerContactsToOFD = 0, pEmailToSendToOFD = "", pPhoneToSendToOFD = "", rTLVArray)
	// Put code in extension of this function if necessary
	Return True;
EndFunction // pmPrintCheque_AfterOpenChequeTLV

// -----------------------------------------------------------------------------
Function pmPrintCheque_BeforeCloseCheque(vFR, vArrCashRegister, vChargesWithMarkingCode, Val pSum, Val pVATSum, pObj, pObjRef, rMessage, pPasswordKKM="", pServices = Undefined, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101', pSendPayerContactsToOFD = 0, pEmailToSendToOFD = "", pPhoneToSendToOFD = "")
	// Put code in extension of this function if necessary
	Return True;
EndFunction // pmPrintCheque_BeforeCloseCheque

// -----------------------------------------------------------------------------
Function pmPrintCheque_BeforeCloseChequeTLV(vFR, vArrCashRegister, vChargesWithMarkingCode, Val pSum, Val pVATSum, pObj, pObjRef, rMessage, pPasswordKKM="", pServices = Undefined, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101', pSendPayerContactsToOFD = 0, pEmailToSendToOFD = "", pPhoneToSendToOFD = "", rTLVArray)
	// Put code in extension of this function if necessary
	Return True;
EndFunction // pmPrintCheque_BeforeCloseChequeTLV

// -----------------------------------------------------------------------------
Function pmPrintCheque_AfterCloseCheque(vFR, vArrCashRegister, vChargesWithMarkingCode, vOpenDrawer, Val pSum, Val pVATSum, pObj, pObjRef, rMessage, pPasswordKKM="", pServices = Undefined, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101', pSendPayerContactsToOFD = 0, pEmailToSendToOFD = "", pPhoneToSendToOFD = "")
	// Put code in extension of this function if necessary
	Return True;
EndFunction // pmPrintCheque_AfterCloseCheque

// -----------------------------------------------------------------------------
Function pmPrintCheque_AfterCloseChequeTLV(vFR, vArrCashRegister, vChargesWithMarkingCode, vOpenDrawer, Val pSum, Val pVATSum, pObj, pObjRef, rMessage, pPasswordKKM="", pServices = Undefined, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101', pSendPayerContactsToOFD = 0, pEmailToSendToOFD = "", pPhoneToSendToOFD = "", rTLVArray)
	// Put code in extension of this function if necessary
	Return True;
EndFunction // pmPrintCheque_AfterCloseChequeTLV

// -----------------------------------------------------------------------------
Function pmPrintCheque_BeforeChequePositionRegistration(vFR, vArrCashRegister, vChargesWithMarkingCode, pRow = Undefined, Val pSum, Val pVATSum, pObj, pObjRef, rMessage, pPasswordKKM="", pServices = Undefined, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101', pSendPayerContactsToOFD = 0, pEmailToSendToOFD = "", pPhoneToSendToOFD = "")
	// Put code in extension of this function if necessary
	Return True;
EndFunction // pmPrintCheque_BeforeChequePositionRegistrartion

// -----------------------------------------------------------------------------
Function pmPrintCheque_BeforeChequePositionRegistrationTLV(vFR, vArrCashRegister, vChargesWithMarkingCode, pRow = Undefined, Val pSum, Val pVATSum, pObj, pObjRef, rMessage, pPasswordKKM="", pServices = Undefined, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101', pSendPayerContactsToOFD = 0, pEmailToSendToOFD = "", pPhoneToSendToOFD = "", rTLVArray)
	// Put code in extension of this function if necessary
	Return True;
EndFunction // pmPrintCheque_BeforeChequePositionRegistrartionTLV

// -----------------------------------------------------------------------------
Function pmPrintCheque_AfterChequePositionRegistration(vFR, vArrCashRegister, vChargesWithMarkingCode, pRow = Undefined, Val pSum, Val pVATSum, pObj, pObjRef, rMessage, pPasswordKKM="", pServices = Undefined, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101', pSendPayerContactsToOFD = 0, pEmailToSendToOFD = "", pPhoneToSendToOFD = "")
	// Put code in extension of this function if necessary
	Return True;
EndFunction // pmPrintCheque_AfterChequePositionRegistration

// -----------------------------------------------------------------------------
Function pmPrintCheque_AfterChequePositionRegistrationTLV(vFR, vArrCashRegister, vChargesWithMarkingCode, pRow = Undefined, Val pSum, Val pVATSum, pObj, pObjRef, rMessage, pPasswordKKM="", pServices = Undefined, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101', pSendPayerContactsToOFD = 0, pEmailToSendToOFD = "", pPhoneToSendToOFD = "", rTLVArray)
	// Put code in extension of this function if necessary
	Return True;
EndFunction // pmPrintCheque_BeforeChequePositionRegistrartionTLV

// --------------------------------------------------------------------------------
Function FillAdditionalAttributes(pFR, pObj, pArrCashRegister)
	pFR.setParam(pFR.LIBFPTR_PARAM_FN_DATA_TYPE, pFR.LIBFPTR_FNDT_FN_INFO);
	If pFR.fnQueryData() <> 0 Then
		Return False;
	EndIf;
	
	vFiscalStorageFactoryNumber = pFR.getParamString(pFR.LIBFPTR_PARAM_SERIAL_NUMBER);
	
	pFR.setParam(pFR.LIBFPTR_PARAM_FN_DATA_TYPE, pFR.LIBFPTR_FNDT_LAST_DOCUMENT);
	If pFR.fnQueryData() <> 0 Then
		Return False;
	EndIf;
	
	vChequeSequenceNumber = pFR.getParamInt(pFR.LIBFPTR_PARAM_DOCUMENT_NUMBER);
	vChequeSequenceNumber = vChequeSequenceNumber + 1;
	
	pFR.setParam(pFR.LIBFPTR_PARAM_DATA_TYPE, pFR.LIBFPTR_DT_SHIFT_STATE);
	If pFR.queryData() <> 0 Then
		Return False;
	EndIf;
	
	vCashDay = pFR.getParamInt(pFR.LIBFPTR_PARAM_SHIFT_NUMBER);
	
	If pFR.getParamInt(pFR.LIBFPTR_PARAM_SHIFT_STATE) = pFR.LIBFPTR_SS_CLOSED Then
		vChequeSequenceNumber = vChequeSequenceNumber + 1;
		vCashDay = vCashDay + 1;
	EndIf;
	
	pArrCashRegister.Insert("AddAttribute_FiscalStorageFactoryNumber", vFiscalStorageFactoryNumber);
	pArrCashRegister.Insert("AddAttribute_ChequeSequenceNumber", vChequeSequenceNumber);
	pArrCashRegister.Insert("AddAttribute_CashDay", vCashDay);
	
	Return True;
EndFunction // FillAdditionalAttributes

#EndRegion