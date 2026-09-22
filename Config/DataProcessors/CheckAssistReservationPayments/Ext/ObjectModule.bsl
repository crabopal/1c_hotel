Var HTTPRequest;

// -----------------------------------------------------------------------------
// Data processors framework start
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(GuaranteedReservationStatus) Then
		If ValueIsFilled(Hotel) Then
			GuaranteedReservationStatus = Hotel.GuaranteedReservationStatus;
		EndIf;
	EndIf;
	If Not ValueIsFilled(PaymentTimeExpiredReservationStatus) Then
		If ValueIsFilled(Hotel) Then
			PaymentTimeExpiredReservationStatus = Hotel.PaymentDateExpiredReservationStatus;
		EndIf;
	EndIf;
	If Not ValueIsFilled(DepartmentToSendNotificationsTo) Then
		If ValueIsFilled(Hotel) Then
			DepartmentToSendNotificationsTo = Hotel.ReservationDepartment;
		EndIf;
	EndIf;
	If TimeToWaitReservationPayment = 0 Then
		TimeToWaitReservationPayment = 60;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	// Check reservations
	pmDoCheck(pIsInteractive);
EndProcedure // pmRun

// -----------------------------------------------------------------------------
// Data processors framework end
// -----------------------------------------------------------------------------
	
// -----------------------------------------------------------------------------
Procedure pmDoCheck(pIsInteractive = False) Export
	WriteLogEvent(NStr("en='DataProcessor.CheckAssistSystemReservationPayments'; de='DataProcessor.CheckAssistSystemReservationPayments'; ru='Обработка.ПроверитьПоступлениеОплатыПоСистемеAssist'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'"));
	// Check HOST parameter
	If Not ValueIsFilled(AssistHost) Then
		AssistHost = "payments.paysecure.ru";
	EndIf;
	vCanceledGuestGroups = New ValueList();
	If ValueIsFilled(NewOnlineReservationStatus) Then
		// Get list of new on-line guest groups
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	RoomInventory.GuestGroup AS GuestGroup
		|FROM
		|	AccumulationRegister.RoomInventory AS RoomInventory
		|WHERE
		|	RoomInventory.ReservationStatus.IsActive
		|	AND RoomInventory.ReservationStatus = &qNewOnlineReservationStatus
		|	AND RoomInventory.Hotel IN HIERARCHY(&qHotel)
		|	AND (RoomInventory.BedsReserved > 0
		|			OR RoomInventory.AdditionalBedsReserved > 0
		|			OR RoomInventory.GuestsReserved > 0)
		|	AND RoomInventory.RecordType = &qExpense
		|
		|GROUP BY
		|	RoomInventory.GuestGroup
		|
		|ORDER BY
		|	RoomInventory.GuestGroup.Code";
		vQry.SetParameter("qNewOnlineReservationStatus", NewOnlineReservationStatus);
		vQry.SetParameter("qPeriodFrom", '00010101');
		vQry.SetParameter("qPeriodTo", '39991231');
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qExpense", AccumulationRecordType.Expense);
		vNewGuestGroups = vQry.Execute().Unload();
		If vNewGuestGroups.Count() = 0 Then
			WriteLogEvent(NStr("en='DataProcessor.CheckAssistSystemReservationPayments'; de='DataProcessor.CheckAssistSystemReservationPayments'; ru='Обработка.ПроверитьПоступлениеОплатыПоСистемеAssist'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("ru = 'Нет новой on-line брони'; en = 'New on-line reservation was not found'; de = 'New on-line reservation was not found'"));
			WriteLogEvent(NStr("en='DataProcessor.CheckAssistSystemReservationPayments'; de='DataProcessor.CheckAssistSystemReservationPayments'; ru='Обработка.ПроверитьПоступлениеОплатыПоСистемеAssist'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'"));
			Return;
		EndIf;
		// Change status of expired reservations
		i = 0;
		While i < vNewGuestGroups.Count() Do
			vGuestGroup = vNewGuestGroups.Get(i).GuestGroup;
			vGuestGroupIsExpired = False;
			If ValueIsFilled(vGuestGroup.CreateDate) Then
				If (CurrentSessionDate() - vGuestGroup.CreateDate)/60 > TimeToWaitReservationPayment Then
					vGuestGroupIsExpired = True;
				EndIf;
			Else
				vGuestGroupIsExpired = True;
			EndIf;
			If vGuestGroupIsExpired Then
				vNewGuestGroups.Delete(i);
				// Send notification
				If ValueIsFilled(DepartmentToSendNotificationsTo) Then
					vMessageStatus = Undefined;
					If ValueIsFilled(vGuestGroup) And ValueIsFilled(vGuestGroup.Owner.MessageStatus) Then
						vMessageStatus = vGuestGroup.Owner.MessageStatus;
					EndIf;
					vMessage = NStr("ru='Просрочена оплата по новой on-line брони группы № " + TrimAll(vGuestGroup) + ", " + TrimAll(vGuestGroup.Client) + ", " + Format(vGuestGroup.CheckInDate, "DF=dd.MM.yyyy") + " - " + Format(vGuestGroup.CheckOutDate, "DF=dd.MM.yyyy") + "! Оплата не поступила до времени " + Format((vGuestGroup.CreateDate + TimeToWaitReservationPayment*60), "DF='dd.MM.yyyy HH:mm'") + "'; 
					                |de='Payment wait time expired for the new on-line group N " + TrimAll(vGuestGroup) + ", " + TrimAll(vGuestGroup.Client) + ", " + Format(vGuestGroup.CheckInDate, "DF=dd.MM.yyyy") + " - " + Format(vGuestGroup.CheckOutDate, "DF=dd.MM.yyyy") + "! Payment was expected before " + Format((vGuestGroup.CreateDate + TimeToWaitReservationPayment*60), "DF='dd.MM.yyyy HH:mm'") + "'; 
					                |en='Payment wait time expired for the new on-line group N " + TrimAll(vGuestGroup) + ", " + TrimAll(vGuestGroup.Client) + ", " + Format(vGuestGroup.CheckInDate, "DF=dd.MM.yyyy") + " - " + Format(vGuestGroup.CheckOutDate, "DF=dd.MM.yyyy") + "! Payment was expected before " + Format((vGuestGroup.CreateDate + TimeToWaitReservationPayment*60), "DF='dd.MM.yyyy HH:mm'") + "'");
					cmSendMessageToDepartment(DepartmentToSendNotificationsTo, vMessage, vMessageStatus, False, vGuestGroup);
				EndIf;
				// Change reservation status to payment wait time is expired
				If ValueIsFilled(PaymentTimeExpiredReservationStatus) Then
					vQry = New Query();
					vQry.Text = 
					"SELECT
					|	Reservations.Ref AS Reservation
					|FROM
					|	Document.Reservation AS Reservations
					|WHERE
					|	Reservations.Posted
					|	AND Reservations.GuestGroup = &qGuestGroup
					|	AND Reservations.ReservationStatus = &qReservationStatus
					|
					|ORDER BY
					|	Reservations.Date,
					|	Reservations.PointInTime";
					vQry.SetParameter("qGuestGroup", vGuestGroup);
					vQry.SetParameter("qReservationStatus", NewOnlineReservationStatus);
					vReservations = vQry.Execute().Unload();
					For Each vReservationsRow In vReservations Do
						Try
							vReservationRef = vReservationsRow.Reservation;
							vReservationObj = vReservationRef.GetObject();
							
							// Set reservation status
							vReservationObj.ReservationStatus = PaymentTimeExpiredReservationStatus;
							vReservationObj.pmSetDoCharging();
							If (PaymentTimeExpiredReservationStatus.DoNoShowCharging Or PaymentTimeExpiredReservationStatus.DoLateAnnulationCharging) Then
								vReservationObj.pmCalculateServices();
							EndIf;
							vReservationObj.Write(DocumentWriteMode.Posting);
							// Save data to the document history
							vReservationObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
							
							// Log current state
							vMessage = StrTemplate(NStr("ru='Обработан документ: %1 - группа № %2, статус установлен в %3'; 
							                |de='Document %1 - group N %2 was processed, status was set to %3'; 
											|en='Document %1 - group N %2 was processed, status was set to %3'"), String(vReservationObj.Ref), TrimAll(vReservationObj.GuestGroup), TrimAll(vReservationObj.ReservationStatus));
							WriteLogEvent(NStr("en='DataProcessor.CheckAssistSystemReservationPayments'; de='DataProcessor.CheckAssistSystemReservationPayments'; ru='Обработка.ПроверитьПоступлениеОплатыПоСистемеAssist'"), EventLogLevel.Information, ThisObject.Metadata(), vReservationObj.Ref, vMessage);
							If pIsInteractive Then
								tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
							EndIf;
							
							// Write guest group attachement
							If ValueIsFilled(ReplyMessageType) Then
								If vCanceledGuestGroups.FindByValue(vGuestGroup) = Undefined Then
									vCanceledGuestGroups.Add(vGuestGroup);
									vHotel = vGuestGroup.Owner;
									vLanguage = vHotel.Language;
									If ValueIsFilled(vGuestGroup.Client) And ValueIsFilled(vGuestGroup.Client.Language) Then
										vLanguage = vGuestGroup.Client.Language;
									EndIf;                 
									vTimeExpiredReservationStatusPrev = Catalogs.ReservationStatuses.pmGetReservationStatusDescription(PaymentTimeExpiredReservationStatus, vLanguage); 
									vHotelPrintName = Catalogs.Hotels.pmGetHotelPrintName(vHotel, vLanguage);   
									vPeriodPrev = Format(vGuestGroup.CheckInDate, "DF=dd.MM.yyyy") + " - " + Format(vGuestGroup.CheckOutDate, "DF=dd.MM.yyyy");  
									vGuestGroupCode = Format(vGuestGroup.Code, "ND=12; NFD=0; NG=");
									// Build message text
									vRemarks = vHotelPrintName  
									           + StrTemplate(cmNStr("en = '. Status of reservation N %1 was changed to %2'; de = '. Status of reservation N %1 was changed to %2'; ru = '. Статус брони № %1 изменен на %2'", vLanguage), 
											   				 vGuestGroupCode, vTimeExpiredReservationStatusPrev);
									vDocumentText = cmNStr("en='Reservation status change notification:'; 
									                       |de='Benachrichtigung über Änderung des Reservierungsstatus:'; 
									                       |ru='Уведомление об изменении статусов брони:'",
									                       vLanguage) + Chars.LF + Chars.LF +
									                ?(ValueIsFilled(vGuestGroup) And ValueIsFilled(vGuestGroup.Client), cmNStr("EN='Client name: ';RU='Клиент: ';de='Kunde: '", vLanguage) + TrimAll(vGuestGroup.Client.FullName) + Chars.LF, "") + 
									                ?(ValueIsFilled(vGuestGroup) And ValueIsFilled(vGuestGroup.CheckInDate) And ValueIsFilled(vGuestGroup.CheckOutDate), cmNStr("EN='Period of stay: ';RU='Период проживания: ';de='Unterbringungszeitraum:'", vLanguage) + Format(vGuestGroup.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - "  + Format(vGuestGroup.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + Chars.LF, "") + 
									                Chars.LF + 
									                StrTemplate(cmNStr("en='Status of reservation N %1 was changed to %2'; 
																       |de='Status of reservation N %1 was changed to %2'; 
												                       |ru='Статус брони № %1 изменен на %2'", vLanguage), vGuestGroupCode, vTimeExpiredReservationStatusPrev) + Chars.LF  
									                + ?(ValueIsFilled(vGuestGroup.Client), cmNStr("en='Guest name is '; de='Guest name is '; ru='Гость '", vLanguage) + TrimAll(vGuestGroup.Client.FullName) + Chars.LF, "")  
									                + cmNStr("en='Reservation period is '; de='Reservation period is '; ru='Период планируемого проживания '", vLanguage) + vPeriodPrev + Chars.LF + Chars.LF  
									                + cmNStr("en='Best regards,'; 
													       	|de='Best regards,'; 
									                       	|ru='С уважением,'", vLanguage) + Chars.LF  
									                + vHotelPrintName  + Chars.LF 
													+ cmNStr(SessionParameters.ConfigurationName, vLanguage);
									// Call user exit procedure to give possibility to override message subject ans message text
									vUserExitProc = Catalogs.ExternalDataProcessors.WriteGuestGroupPaymentWaitTimeIsExpiredNotification;
									If ValueIsFilled(vUserExitProc) Then
										If vUserExitProc.ExternalProcessingType = Enums.ExternalProcessingTypes.Algorithm Then
											If Not IsBlankString(vUserExitProc.Algorithm) Then
												SetSafeMode(True);
												Execute(TrimAll(vUserExitProc.Algorithm));
												SetSafeMode(False);
											EndIf;
										EndIf;
									EndIf;
									// Write attachment 
									vFax = "";
									vEMail = "";
									If ValueIsFilled(vGuestGroup.ClientDoc) And TypeOf(vGuestGroup.ClientDoc) <> Type("DocumentRef.Folio") Then
										vFax = vGuestGroup.ClientDoc.Fax;
										vEMail = vGuestGroup.ClientDoc.EMail;
									ElsIf ValueIsFilled(vGuestGroup.Client) Then
										vFax = vGuestGroup.Client.Fax;
										vEMail = vGuestGroup.Client.EMail;
									ElsIf ValueIsFilled(vGuestGroup.Customer) Then
										vFax = vGuestGroup.Customer.Fax;
										vEMail = vGuestGroup.Customer.EMail;
									EndIf; 
									InformationRegisters.GuestGroupAttachments.WriteData(, vGuestGroup,,,,,, vEMail, vFax, ReplyMessageType, Enums.AttachmentStatuses.Ready, vDocumentText,, vReservationRef,,,,,, vRemarks);
								EndIf;
							EndIf;
						Except
							vMessage = ErrorDescription();
							WriteLogEvent(NStr("en='DataProcessor.CheckAssistSystemReservationPayments'; de='DataProcessor.CheckAssistSystemReservationPayments'; ru='Обработка.ПроверитьПоступлениеОплатыПоСистемеAssist'"), EventLogLevel.Warning, ThisObject.Metadata(), ?(vReservationObj = Undefined, Undefined, vReservationObj.Ref), vMessage);
							If pIsInteractive Then
								tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
							EndIf;
						EndTry;
					EndDo;
				EndIf;
			Else
				i = i + 1;
			EndIf;
		EndDo;
		// Call web-service to check status of each guest group
		If vNewGuestGroups.Count() > 0 Then
			// HTTP connection
			vProxy = cmGetInternetProxy(InternetConnectionSettings, False, TrimAll(AssistHost));
			vHTTPCon = Undefined;
			If vProxy <> Undefined Then
				vHTTPCon = New HTTPConnection(TrimAll(AssistHost), , , , vProxy, , New OpenSSLSecureConnection);
			Else
				vHTTPCon = New HTTPConnection(TrimAll(AssistHost), , , , , , New OpenSSLSecureConnection);
			EndIf;
			// Get Assist system Web-services proxy
			For Each vNewGuestGroupsRow In vNewGuestGroups Do
				vPaymentSectionCode = "";
				If ValueIsFilled(PaymentSection) Then
					vPaymentSectionCode = Format(PaymentSection.Code, "ND=3; NFD=0; NZ=; NG=");
				EndIf;
				vGuestGroup = vNewGuestGroupsRow.GuestGroup;
				vGuestGroupCode = Format(vGuestGroup.Code, "ND=12; NFD=0; NZ=; NG=");
				vGuestGroupClientFullName = "";
				vGuestGroupClientCode = "";
				If ValueIsFilled(vGuestGroup.Client) Then
					vGuestGroupClientFullName = TrimAll(vGuestGroup.Client.FullName);
					vGuestGroupClientCode = TrimR(vGuestGroup.Client.Code);
				EndIf;
				// Build period to search for the order
				vPeriodFrom = CurrentSessionDate() - 3*24*3600;
				vPeriodTo = EndOfDay(CurrentSessionDate());
				// Call web service
				vHTTPRequest = HTTPRequest;
				vHTTPRequest = StrReplace(vHTTPRequest, "$qOrdernumber", vGuestGroupCode);
				vHTTPRequest = StrReplace(vHTTPRequest, "$qMerchant_id", Format(AssistShopId, "ND=6; NFD=0; NZ=; NLZ=; NG="));
				vHTTPRequest = StrReplace(vHTTPRequest, "$qLogin", TrimAll(AssistUser));
				vHTTPRequest = StrReplace(vHTTPRequest, "$qPassword", TrimR(AssistUserPassword));
				vHTTPRequest = StrReplace(vHTTPRequest, "$qStartyear", Format(Year(vPeriodFrom), "ND=4; NFD=0; NZ=; NG="));
				vHTTPRequest = StrReplace(vHTTPRequest, "$qStartmonth", Format(Month(vPeriodFrom), "ND=2; NFD=0; NZ=; NG="));
				vHTTPRequest = StrReplace(vHTTPRequest, "$qStartday", Format(Day(vPeriodFrom), "ND=2; NFD=0; NZ=; NG="));
				vHTTPRequest = StrReplace(vHTTPRequest, "$qStarthour", Format(Hour(vPeriodFrom), "ND=2; NFD=0; NZ=; NG="));
				vHTTPRequest = StrReplace(vHTTPRequest, "$qStartmin", Format(Minute(vPeriodFrom), "ND=2; NFD=0; NZ=; NG="));
				vHTTPRequest = StrReplace(vHTTPRequest, "$qEndyear", Format(Year(vPeriodTo), "ND=4; NFD=0; NZ=; NG="));
				vHTTPRequest = StrReplace(vHTTPRequest, "$qEndmonth", Format(Month(vPeriodTo), "ND=2; NFD=0; NZ=; NG="));
				vHTTPRequest = StrReplace(vHTTPRequest, "$qEndday", Format(Day(vPeriodTo), "ND=2; NFD=0; NZ=; NG="));
				vHTTPRequest = StrReplace(vHTTPRequest, "$qEndhour", Format(Hour(vPeriodTo), "ND=2; NFD=0; NZ=; NG="));
				vHTTPRequest = StrReplace(vHTTPRequest, "$qEndmin", Format(Minute(vPeriodTo), "ND=2; NFD=0; NZ=; NG="));
				// Write request data to the file and initialize response file name
				vRequestFileName = GetTempFileName("xml");
				vResponseFileName = GetTempFileName("xml");
				vRequestFileData = New TextDocument();
				vRequestFileData.SetText(vHTTPRequest);
				vRequestFileData.Write(vRequestFileName, "UTF-8");
				// File reference to the request file
				vRequestFile = New File(vRequestFileName);
				// HTTP POST request headers
				vPOSTHeaders = New Map();
				vPOSTHeaders.Insert("Host", TrimAll(AssistHost));
				vPOSTHeaders.Insert("Accept", "text/html,application/xml;q=0.9,*/*;q=0.8");
				vPOSTHeaders.Insert("Accept-Language", "ru-ru,ru;q=0.8,en-us;q=0.5,en;q=0.3");
				vPOSTHeaders.Insert("Accept-Charset", "windows-1251,utf-8;q=0.7,*;q=0.7");
				vPOSTHeaders.Insert("Connection", "keep-alive");
				vPOSTHeaders.Insert("Content-Type", "application/x-www-form-urlencoded");
				vPOSTHeaders.Insert("Content-Length", XMLString(vRequestFile.Size()));
				// POST request data
				vHTTPRequestObj = New HTTPRequest("orderstate/orderstate.cfm", vPOSTHeaders);
				vHTTPRequestObj.SetBodyFileName(vRequestFileName);
				vHTTPCon.Post(vHTTPRequestObj, vResponseFileName);
				// Initialize response parameters
				vFirstcode = "";
				vSecondcode = "";
				vOrderAmount = 0;
				vOrderCurrencyCode = "";
				vOrderState = "";
				vBillnumber = "";
				// Read response file
				vXMLResponse = New XMLReader();
				vXMLResponse.OpenFile(vResponseFileName);
				While vXMLResponse.Read() Do
					If vXMLResponse.NodeType = XMLNodeType.StartElement Then
						If vXMLResponse.Name = "result" Then
							While vXMLResponse.ReadAttribute() Do
								If vXMLResponse.Name = "firstcode" Then
									vFirstcode = vXMLResponse.Value;
								ElsIf vXMLResponse.Name = "secondcode" Then
									vSecondcode = vXMLResponse.Value;
								EndIf;
							EndDo;
						ElsIf vXMLResponse.Name = "billnumber" Then
							If vXMLResponse.Read() Then
								If vXMLResponse.NodeType = XMLNodeType.Text Then
									vBillnumber = vXMLResponse.Value;
								EndIf;
							EndIf;
						ElsIf vXMLResponse.Name = "orderamount" Then
							If vXMLResponse.Read() Then
								If vXMLResponse.NodeType = XMLNodeType.Text Then
									vOrderAmount = Number(StrReplace(StrReplace(vXMLResponse.Value, ",", "."), " ", ""));
								EndIf;
							EndIf;
						ElsIf vXMLResponse.Name = "ordercurrency" Then
							If vXMLResponse.Read() Then
								If vXMLResponse.NodeType = XMLNodeType.Text Then
									vOrderCurrencyCode = vXMLResponse.Value;
								EndIf;
							EndIf;
						ElsIf vXMLResponse.Name = "orderstate" Then
							If vXMLResponse.Read() Then
								If vXMLResponse.NodeType = XMLNodeType.Text Then
									vOrderState = vXMLResponse.Value;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				EndDo;
				vXMLResponse.Close();
				vXMLResponse = Undefined;
				// Close files
				vRequestFile = Undefined;
				vRequestFileData = Undefined;
				vResponseFileData = Undefined;
				// Delete temporal files
				DeleteFiles(vRequestFileName);
				DeleteFiles(vResponseFileName);
				// Log payment data
				WriteLogEvent(NStr("en='DataProcessor.CheckAssistSystemReservationPayments'; de='DataProcessor.CheckAssistSystemReservationPayments'; ru='Обработка.ПроверитьПоступлениеОплатыПоСистемеAssist'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("ru = 'Платеж: '; en = 'Payment: '; de = 'Payment: '") + Chars.LF + 
							  NStr("en='Guest group code: '; de='Guest group code: '; ru='Код группы гостей: '") + vGuestGroupCode + Chars.LF +
							  NStr("en='Response codes: '; de='Response codes: '; ru='Коды ответа: '") + vFirstcode + "/" + vSecondcode + Chars.LF +
							  NStr("en='Order state: '; de='Order state: '; ru='Статус заказа: '") + vOrderState + Chars.LF +
							  NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + Format(vOrderAmount, "ND=17; NFD=2; NZ=; NG=") + Chars.LF +
							  NStr("en='Currency: ';ru='Валюта: ';de='Währung: '") + vOrderCurrencyCode + Chars.LF +
							  NStr("en='Billnumber: '; de='Billnumber: '; ru='Номер платежа: '") + vBillnumber);
				// Check payment response code
				If vFirstcode = "0" And Find(vOrderState, "Approved") > 0 Then
					// Call API to write payment to the database
					vAPIRet = cmWriteExternalPayment("", vGuestGroupCode, vGuestGroupClientCode, 
					                                 vGuestGroupClientFullName, "", "", vGuestGroupClientFullName, 
													 TrimAll(PaymentMethod.Code), vOrderAmount, Upper(vOrderCurrencyCode), 
													 vPaymentSectionCode, TrimAll(Hotel.Code), TrimAll(ExternalSystemCode), 
													 TrimAll(vBillnumber), TrimAll(vOrderState), TrimAll(vOrderState), 
													 TrimAll(GuaranteedReservationStatus.Code), 
													 CurrentSessionDate(), "", "");
				EndIf;
			EndDo;
			// Free HTTP connection
			vHTTPCon = Undefined;
		EndIf;
	EndIf;
	WriteLogEvent(NStr("en='DataProcessor.CheckAssistSystemReservationPayments'; de='DataProcessor.CheckAssistSystemReservationPayments'; ru='Обработка.ПроверитьПоступлениеОплатыПоСистемеAssist'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'"));
EndProcedure // pmDoCheck

// -----------------------------------------------------------------------------
HTTPRequest = "Submit=&Ordernumber=$qOrdernumber&Merchant_ID=$qMerchant_id&Login=$qLogin&Password=$qPassword&Startyear=$qStartyear&Startmonth=$qStartmonth&Startday=$qStartday&Starthour=$qStarthour&Startmin=$qStartmin&Endyear=$qEndyear&Endmonth=$qEndmonth&Endday=$qEndday&Endhour=$qEndhour&Endmin=$qEndmin&Format=3";