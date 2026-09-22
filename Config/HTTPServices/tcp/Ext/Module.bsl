
#Region EventHandlers

// --------------------------------------------------------------------------------
Function SquirrelPOS_POST(pRequest)
	
	vResponseCode			= 200;
	vResult					= "";
	vError					= "";
	vBase64					= True;
	
	Try
		// Initialize mandatory params
		vParamsArray = New Array;
		vParamsArray.Add("Token");
		vParamsArray.Add("Value");
		vParamsArray.Add("Hotel");
		
		// Read request body
		vRequestParams = cmCheckRequestParameters("JSON", vParamsArray, , pRequest);
		
		If ValueIsFilled(vRequestParams.Error) Then
			WriteLogEvent("SquirrelPOS",,,, vRequestParams.Error);
			vResponseCode 	= 400;
			vResult			= vRequestParams.Error;
		Else
			
			vInteractionParameters = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByExternalToken(vRequestParams.Token);
			
			If ValueIsFilled(vInteractionParameters) AND Upper(TrimAll(vInteractionParameters.Hotel.Description)) = Upper(TrimAll(vRequestParams.Hotel)) Then
				
				vRequstData = ReadRequestMessage(vRequestParams.Value);
				
				vRequstMessageData 	= ParseMessageToStructure(vInteractionParameters, vRequstData.Message);
				vDataStructure 		= Undefined;
				vMessageType		= "E";
				
				If vRequstMessageData.MessageType = "A" Then
					// Get guests by room
					vMessageType 	= "C";
					vRoomInfo 		= cmGetHotelGuestsList("", vRequstMessageData.RoomNumber, "", "XDTO", vInteractionParameters.Code);				
					vRepeatableData	= GetRepeatableTable(vInteractionParameters, vMessageType);
					
					i = 1;
					For Each vGuestRow in vRoomInfo.GuestItems.GuestItem Do
						// Max 9 folios
						If i = 9 Then
							Break;
						EndIf;
						
						vNewRow 					= vRepeatableData.Add();
						vNewRow.CreditLimit 		= vGuestRow.CreditLimit * 100;
						
						vCardIDPOS = StrFind(vGuestRow.Guest, "(DC");

						If vCardIDPOS > 0 Then
							vNewRow.FolioName = Left(vGuestRow.Guest, vCardIDPOS - 1);
						Else
							vNewRow.FolioName 	= vGuestRow.Guest;
						EndIf;
						
						vNewRow.CurrentBalance 		= vGuestRow.ClientBalance * 100;
						
						vNewRow.CheckOutToday 		= "0";
						If ValueIsFilled(vGuestRow.CheckOutDate) AND BegOfDay(vGuestRow.CheckOutDate) = BegOfDay(CurrentSessionDate()) Then
							vNewRow.CheckOutToday 	= "1";
						EndIf;
										
						vNewRow.VoiceMailWaiting 	= "0";
						vNewRow.MessageWaiting 		= "0";
						
						i = i + 1;
					EndDo;
					
					vDataStructure 	= New Structure("RoomNumber, Repeatable", vRequstMessageData.RoomNumber, vRepeatableData);
					
				ElsIf vRequstMessageData.MessageType = "B" Then
					// Get guest by folio
					vMessageType =	 "D";
					vFolioInfo 						= cmGetFolioDescription(vRequstMessageData.AcctNumber, "", vInteractionParameters.Code, "XDTO");
					vDataStructure 					= New Structure("AccountNumber, CreditLimit, FolioName, CurrentBalance, CheckOutToday, VoiceMailWaiting, MessageWaiting");
					vDataStructure.AccountNumber 	= vRequstMessageData.AcctNumber;
					vDataStructure.CreditLimit 		= vFolioInfo.CreditLimit * 100;
					vDataStructure.FolioName 		= vFolioInfo.Client;
					vDataStructure.CurrentBalance 	= vFolioInfo.FolioBalance * 100;
					
					vDataStructure.CheckOutToday 		= "0";
					If ValueIsFilled(vFolioInfo.CheckOutDate) AND BegOfDay(vFolioInfo.CheckOutDate) = BegOfDay(CurrentSessionDate()) Then
						vDataStructure.CheckOutToday 	= "1";
					EndIf;

					vDataStructure.VoiceMailWaiting = "0";
					vDataStructure.MessageWaiting 	= "0";
					
				ElsIf vRequstMessageData.MessageType = "F" OR vRequstMessageData.MessageType = "G" OR vRequstMessageData.MessageType = "K" Then
					// Write POS order by room or Write POS order by folio
					vMessageType 	= "O";
					vTotalSum		= 0;
					vOrderDate		= Date("20" + Mid(vRequstMessageData.Date, 7, 2) + Mid(vRequstMessageData.Date, 1, 2) + Mid(vRequstMessageData.Date, 4, 2) + Mid(vRequstMessageData.Date, 9, 2) + Mid(vRequstMessageData.Date, 12, 2) + "00");
					
					vServices 		= InformationRegisters.ExternalSystemIntegrationData.GetData(vInteractionParameters, "services");
					If vServices.Count() <> 17 then
						vError 			= "Failed to find services mapping table! Check integration setting."; 
						vResponseCode 	= 400;
					EndIf;
					
					vPaymentMethods = InformationRegisters.ExternalSystemIntegrationData.GetData(vInteractionParameters, "paymentMethods");
					
					vDepartments 	= InformationRegisters.ExternalSystemIntegrationData.GetData(vInteractionParameters, "departments");
					vPOSData		= Undefined;
					
					If vDepartments.Count() > 0 Then
						vPOSDatas = vDepartments.FindRows(New Structure("id, Timezoneid", vRequstMessageData.DepartmentNumber, vRequstMessageData.TimezoneNumber));
						If vPOSDatas.Count() = 0 Then
							vPOSDatas = vDepartments.FindRows(New Structure("id, Timezoneid", vRequstMessageData.DepartmentNumber, ""));	
						EndIf;
						
						If vPOSDatas.Count() > 0 Then
							vPOSData = vPOSDatas[0];
						EndIf;
					EndIf;
					
					If vPOSData = Undefined Then
						vError 			= "Failed to find POS by id:" + vRequstMessageData.DepartmentNumber; 
						vResponseCode 	= 400;
					EndIf;
					
					If IsBlankString(vError) Then
						vXDTOOrderClient 			= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderClient"));
						vXDTOOrderDetails  			= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderDetails"));
						vXDTOSource 				= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "Source"));
						vXDTOOrderItems 			= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderItems"));
						vXDTOOrderPaymentMethods 	= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderPaymentMethods"));
						vXDTOPayment				= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderPayment"));
						vXDTOPaymentMethod 			= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderPaymentMethod"));
						
						// Client ifo
						If vRequstMessageData.MessageType = "F" Then
							// Write POS order by room
							vXDTOOrderClient.Room = vRequstMessageData.RoomNumber;
						Else
							// Write POS order by folio
							vXDTOOrderClient.FolioNumber = vRequstMessageData.AcctNumber;							
						EndIf;
						
						// Source info
						vXDTOSource.ExternalSystemCode 	= vInteractionParameters.Code;
						vXDTOSource.POS 				= vPOSData.RefKey2.Code;
						
						vCashRegister = vPOSData.RefKey2;
						
						// Order info
						vXDTOOrderDetails.Service 			= vPOSData.RefKey1.Code;
						vXDTOOrderDetails.OrderDate 		= vOrderDate;
						vXDTOOrderDetails.GuestsQuantity 	= Number(vRequstMessageData.Covers);
						
						vXDTOOrderDetails.OrderID = TrimAll(vInteractionParameters.Code) + vRequstMessageData.SequenceNumber + vRequstMessageData.CheckNumber;
						vXDTOOrderDetails.Remarks = NStr("de='Bestellung Nr. ';en='Order N ';ru='Заказ № '")+vRequstMessageData.CheckNumber;
						
						vExpectedTotal = 0;
						For i = 1 to 17 Do
							vFieldName = "";
							
							If i = 16 Then
								vFieldName = "Tip";	
							ElsIf i = 17 Then
								vFieldName = "Tender";	
							Else
								vFieldName = "NetSales" + i;								
							EndIf;
							If vFieldName = "Tender" Then
								vExpectedTotal = Number(vRequstMessageData[vFieldName])/100;
								vItemSum = 0;
							Else
								vItemSum = Number(vRequstMessageData[vFieldName]);
							EndIf;
							If vItemSum <> 0 Then
								
								vServiceRow = vServices.Find(vFieldName, "ID");
								vService	= vServiceRow.RefKey1;
								
								vItemSum				= vItemSum / 100;
								vXDTOOrderItem 			= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderItem"));
								vXDTOOrderItem.Service 	= vService.Code;
								vXDTOOrderItem.ItemName = vService.Description;
								vXDTOOrderItem.ItemId 	= vService.Code;
								vXDTOOrderItem.Quantity = 1;
								vXDTOOrderItem.Price 	= vItemSum;
								vXDTOOrderItem.Sum 		= vItemSum;
								vTotalSum 				= vTotalSum + vItemSum;
								vXDTOOrderItems.OrderItem.Add(vXDTOOrderItem);
							EndIf;
						EndDo;
						
						vXDTOOrderDetails.OrderItems 	= vXDTOOrderItems;
						vXDTOOrderDetails.Sum 			= vTotalSum;
						vXDTOOrderDetails.Quantity 		= 1;
						If vExpectedTotal <> vTotalSum Then
							WriteLogEvent("SquirrelPOS",,,, "Order total from POS (" + vExpectedTotal+") not equal to rows total ("+vTotalSum+")");
						EndIf;
						If vRequstMessageData.MessageType = "K" Then	
							vPaymentMethodRow = vPaymentMethods.Find(vRequstMessageData.PaymentMedia, "id");
							If vPaymentMethodRow <> Undefined Then
								vXDTOPaymentMethod.PaymentMethod 		= vPaymentMethodRow.RefKey1.Code;
								
								If NOT ValueIsFilled(vRequstMessageData.AcctNumber) Then
									vXDTOOrderClient.FolioNumber = GetFolioNumber(vInteractionParameters.Hotel, vInteractionParameters.Code, vPaymentMethodRow.RefKey1, vCashRegister);
								EndIf;
							Else
								vError 			= "Failed to find Payment Method by id:" + vRequstMessageData.PaymentMedia;
								vResponseCode 	= 400;
							EndIf;
							vXDTOPaymentMethod.Sum 					=  vTotalSum; // it might be diffent from expected Total ("tender") and it ussually means that this diffens will come with the next message 
							vXDTOPaymentMethod.Currency 			= TrimAll(vInteractionParameters.Currency.Code);
							vXDTOPaymentMethod.PaymentExternalCode 	= TrimAll(vInteractionParameters.Code) + vRequstMessageData.SequenceNumber + vRequstMessageData.CheckNumber;
							
							vXDTOOrderPaymentMethods.OrderPaymentMethod.Add(vXDTOPaymentMethod);
							vXDTOPayment.OrderPaymentMethods 	= vXDTOOrderPaymentMethods;
							vXDTOOrderDetails.Payment 			= vXDTOPayment;										
						EndIf;
						
						If IsBlankString(vError) Then
							If vTotalSum <> 0 Then
								// In some cases they send "refund" amount in diffenrent message but with 0 net sales.
								// And we skip it becouse we post payment only for totala net sales and it's already correct
								retOrder 	= cmWritePOSOrder(vXDTOOrderClient, vXDTOOrderDetails, vXDTOSource);
								vError 		= retOrder.Error;
							EndIf;
						Endif;
					EndIf;
					
					vDataStructure = New Structure("Success, ExplanationText", "", "");
					
					If IsBlankString(vError) Then
						vDataStructure.Success = "1";
					Else
						vDataStructure.Success 			= "0";
						vDataStructure.ExplanationText 	= vError;
						vResponseCode = 400;
					EndIf;
					
				Else
					vResponseCode = 400;
				EndIf;
				
				If vDataStructure <> Undefined Then
					vResult = CreateMessageFromStructure(vInteractionParameters, vMessageType, vDataStructure, vRequstMessageData.SequenceNumber);
				Else
					vResult			= "E" + vRequstMessageData.SequenceNumber + "FailedToReadMessage ";
					vResponseCode 	= 400;	
				EndIf;
				
				If vInteractionParameters.DebugMode OR vResponseCode <> 200 Then
					If vResponseCode <> 200 Then
						vEventType = Enums.ExternalSystemEventTypes.Error;
					Else
						vEventType = Enums.ExternalSystemEventTypes.Success	
					EndIf;
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteractionParameters, "tcp/SquirrelPOS", vEventType, StrReplace(vRequstData.Message, "%", "_REPLACED_"), vResult, vError, 40000);
				EndIf;
				
			Else
				WriteLogEvent("SquirrelPOS",,,, "Cant find external system ineraction by token:" + vRequestParams.Token);
				vResponseCode = 403;	
			EndIf;
		EndIf;
	Except
		vError = ErrorDescription();
		WriteLogEvent("SquirrelPOS",,,, vError);
		vResponseCode 	= 400;
	EndTry;
	
	If vRequstData <> Undefined AND vRequstData.BinaryDataBufferID <> Undefined Then
		vResultBodyBase64 = CreateResponseMessage(vRequstData.BinaryDataBufferID, vResult);
	Else
		vResultBodyBase64 = "";	
	EndIf;

	vResponse = New HTTPServiceResponse(vResponseCode);
	vResponse.SetBodyFromString(vResultBodyBase64);
	
	Return vResponse;
	
EndFunction // SquirrelPOS_POST

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
//  Find or create a folio for transactions from pos system
Function GetFolioNumber(pHotel, pExternalSystemCode, pPaymentMethod, pCashRegister)
	// Try to find folio by description. 
	// We will have one folio for all reciepts for one shift date and staion code from r-keeper
	If Not ValueIsFilled(pHotel) Then
		pHotel = SessionParameters.CurrentHotel;
	EndIf;
	
	vShiftDate = pHotel.AccountingDate;
	
	vFolioDescription = "" + Format(vShiftDate,"DF=dd.MM.yyyy") + " " + pPaymentMethod + NStr("en=' - orders from ';ru=' - Загрузка из ';de=' - Laden aus '") +TrimAll(pCashRegister);
	
	vQ = New Query("SELECT
	|	Folio.Ref AS Ref,
	|	Folio.Number AS FolioNumber
	|FROM
	|	Document.Folio AS Folio
	|WHERE
	|	Folio.Description = &qDescription
	|	AND Folio.Hotel = &qHotel
	|	AND NOT Folio.IsClosed
	|	AND NOT Folio.DeletionMark");
	vQ.SetParameter("qDescription",vFolioDescription);
	vQ.SetParameter("qHotel",pHotel);
	
	qRes = vQ.Execute().Select();
	If qRes.Next() Then
		Return qRes.FolioNumber;
	Endif;
	
	// Folio not found  - create new one
	vCompany = pHotel.Company;
	
	If ValueIsFilled(pCashRegister) Then
		vCompany = pCashRegister.Owner;
	Endif;
	
	vFolioObj = Documents.Folio.CreateDocument();
	vFolioObj.pmFillAttributesWithDefaultValues();
	vFolioObj.Company = vCompany;
	vFolioObj.Date = CurrentSessionDate();
	vFolioObj.DateTimeFrom = BegOfDay(vShiftDate);
	vFolioObj.DateTimeTo = EndOfDay(vShiftDate);
	vFolioObj.Description = vFolioDescription;
	vFolioObj.Customer = cmGetObjectRefByExternalSystemCode(pHotel, pExternalSystemCode, "Customers", TrimAll(pCashRegister));
	If ValueIsFilled(vFolioObj.Customer) Then
		vFolioObj.Contract = vFolioObj.Customer.Contract;
	EndIf;
	vFolioObj.Write();
	
	Return vFolioObj.Number;
EndFunction // GetFolioNumber

// --------------------------------------------------------------------------------
Function ParseMessageToStructure(pInteractionParameters, pMessage)
	
	vResult = New Structure("MessageType, SequenceNumber", "", "");
	
	vResult.MessageType 	= Left(pMessage, 1);
	vResult.SequenceNumber	= Mid(pMessage, 2, 1);
	
	vMessageDescription = GetMessageDescription(pInteractionParameters, vResult.MessageType);
	
	vCurrentMessage = Mid(pMessage, 3);
	For Each vMessageRow in vMessageDescription Do
		vValue = TrimAll(Left(vCurrentMessage, vMessageRow.Lenght)); 
		vResult.Insert(vMessageRow.Name, vValue);
		vCurrentMessage = Mid(vCurrentMessage, vMessageRow.Lenght + 1);
	EndDo;
	
	Return vResult;
	
EndFunction // ParseMessageToStructure

// --------------------------------------------------------------------------------
Function GetMessageDescription(pInteractionParameters, pMessageType)
	
	vResult = New ValueTable;
	vResult.Columns.Add("Name");
	vResult.Columns.Add("Lenght");
	vResult.Columns.Add("Justify");
	vResult.Columns.Add("Repeatable");
	
	#Region Requests
	
	// Room Verify Request
	If pMessageType = "A" Then
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "RoomNumber";
		vNewRow.Lenght 	= 8;
		vNewRow.Justify = "Left";

		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "PaymentMedia";
		vNewRow.Lenght 	= 3;
		vNewRow.Justify = "Right";
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "DepartmentNumber";
		vNewRow.Lenght 	= 2;
		vNewRow.Justify = "Right";

		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "TimezoneNumber";
		vNewRow.Lenght 	= 2;
		vNewRow.Justify = "Right";

	// City Ledger Verify Request
	ElsIf pMessageType = "B" Then
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "AcctNumber";
		vNewRow.Lenght 	= 12;
		vNewRow.Justify = "Left";

		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "PaymentMedia";
		vNewRow.Lenght 	= 3;
		vNewRow.Justify = "Right";

		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "DepartmentNumber";
		vNewRow.Lenght 	= 2;
		vNewRow.Justify = "Right";

		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "TimezoneNumber";
		vNewRow.Lenght 	= 2;
		vNewRow.Justify = "Right";

	// Room Charge Posting
	ElsIf pMessageType = "F" Then
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "Date";
		vNewRow.Lenght 	= 13;
		vNewRow.Justify = "Right";
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "DepartmentNumber";
		vNewRow.Lenght 	= 2;
		vNewRow.Justify = "Right";
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "PaymentMedia";
		vNewRow.Lenght 	= 3;
		vNewRow.Justify = "Right";
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "RoomNumber";
		vNewRow.Lenght 	= 8;
		vNewRow.Justify = "Left";
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "FolioNumber";
		vNewRow.Lenght 	= 1;
		vNewRow.Justify = "Right";
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "CheckNumber";
		vNewRow.Lenght 	= 9;
		vNewRow.Justify = "Right";
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "Tender";
		vNewRow.Lenght 	= 9;
		vNewRow.Justify = "Right";
		
		For i = 1 to 15 Do
			vNewRow 		= vResult.Add();
			vNewRow.Name 	= "NetSales" + i;
			vNewRow.Lenght 	= 9;
			vNewRow.Justify = "Right";
		EndDo;
		
		For i = 1 to 3 Do
			vNewRow 		= vResult.Add();
			vNewRow.Name 	= "NetTaxClass" + i;
			vNewRow.Lenght 	= 9;
			vNewRow.Justify = "Right";
		EndDo;

		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "Tip";
		vNewRow.Lenght 	= 9;
		vNewRow.Justify = "Right";
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "NetServiceCharge";
		vNewRow.Lenght 	= 9;
		vNewRow.Justify = "Right";

		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "Covers";
		vNewRow.Lenght 	= 4;
		vNewRow.Justify = "Right";

		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "ServerName";
		vNewRow.Lenght 	= 12;
		vNewRow.Justify = "Left";
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "TimezoneNumber";
		vNewRow.Lenght 	= 2;
		vNewRow.Justify = "Right";
		
	// City Ledger Charge Posting
	ElsIf pMessageType = "G" Then
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "Date";
		vNewRow.Lenght 	= 13;
		vNewRow.Justify = "Right";
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "DepartmentNumber";
		vNewRow.Lenght 	= 2;
		vNewRow.Justify = "Right";
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "PaymentMedia";
		vNewRow.Lenght 	= 3;
		vNewRow.Justify = "Right";
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "AcctNumber";
		vNewRow.Lenght 	= 12;
		vNewRow.Justify = "Left";
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "CheckNumber";
		vNewRow.Lenght 	= 9;
		vNewRow.Justify = "Right";
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "Tender";
		vNewRow.Lenght 	= 9;
		vNewRow.Justify = "Right";
		
		For i = 1 to 15 Do
			vNewRow 		= vResult.Add();
			vNewRow.Name 	= "NetSales" + i;
			vNewRow.Lenght 	= 9;
			vNewRow.Justify = "Right";
		EndDo;
		
		For i = 1 to 3 Do
			vNewRow 		= vResult.Add();
			vNewRow.Name 	= "NetTaxClass" + i;
			vNewRow.Lenght 	= 9;
			vNewRow.Justify = "Right";
		EndDo;

		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "Tip";
		vNewRow.Lenght 	= 9;
		vNewRow.Justify = "Right";
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "NetServiceCharge";
		vNewRow.Lenght 	= 9;
		vNewRow.Justify = "Right";

		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "Covers";
		vNewRow.Lenght 	= 4;
		vNewRow.Justify = "Right";

		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "ServerName";
		vNewRow.Lenght 	= 12;
		vNewRow.Justify = "Left";
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "TimezoneNumber";
		vNewRow.Lenght 	= 2;
		vNewRow.Justify = "Right";
	// Other Payment Posting
	ElsIf pMessageType = "K" Then
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "Date";
		vNewRow.Lenght 	= 13;
		vNewRow.Justify = "Right";
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "DepartmentNumber";
		vNewRow.Lenght 	= 2;
		vNewRow.Justify = "Right";
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "PaymentMedia";
		vNewRow.Lenght 	= 3;
		vNewRow.Justify = "Right";
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "AcctNumber";
		vNewRow.Lenght 	= 19;
		vNewRow.Justify = "Left";
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "CheckNumber";
		vNewRow.Lenght 	= 9;
		vNewRow.Justify = "Right";
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "Tender";
		vNewRow.Lenght 	= 9;
		vNewRow.Justify = "Right";
		
		For i = 1 to 15 Do
			vNewRow 		= vResult.Add();
			vNewRow.Name 	= "NetSales" + i;
			vNewRow.Lenght 	= 9;
			vNewRow.Justify = "Right";
		EndDo;
		
		For i = 1 to 3 Do
			vNewRow 		= vResult.Add();
			vNewRow.Name 	= "NetTaxClass" + i;
			vNewRow.Lenght 	= 9;
			vNewRow.Justify = "Right";
		EndDo;

		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "Tip";
		vNewRow.Lenght 	= 9;
		vNewRow.Justify = "Right";
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "NetServiceCharge";
		vNewRow.Lenght 	= 9;
		vNewRow.Justify = "Right";

		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "Covers";
		vNewRow.Lenght 	= 4;
		vNewRow.Justify = "Right";

		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "ServerName";
		vNewRow.Lenght 	= 12;
		vNewRow.Justify = "Left";
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "TimezoneNumber";
		vNewRow.Lenght 	= 2;
		vNewRow.Justify = "Right";	
		
	#EndRegion
	
	#Region Responses
	
	// Room Verify Response
	ElsIf pMessageType = "C" Then
		
		vNewRow 			= vResult.Add();
		vNewRow.Name 		= "RoomNumber";
		vNewRow.Lenght 		= 8;   
		vNewRow.Justify 	= "Left";
		vNewRow.Repeatable 	= False;

		vNewRow 			= vResult.Add();
		vNewRow.Name 		= "CreditLimit";
		vNewRow.Lenght 		= 9;
		vNewRow.Justify 	= "Right";
		vNewRow.Repeatable 	= True;
		
		vNewRow 			= vResult.Add();
		vNewRow.Name 		= "FolioName";
		vNewRow.Lenght 		= 30;
		vNewRow.Justify 	= "Left";
		vNewRow.Repeatable 	= True;

		vNewRow 			= vResult.Add();
		vNewRow.Name 		= "CurrentBalance";
		vNewRow.Lenght 		= 9;
		vNewRow.Justify 	= "Right";
		vNewRow.Repeatable 	= True;

		vNewRow 			= vResult.Add();
		vNewRow.Name 		= "CheckOutToday";
		vNewRow.Lenght 		= 1;
		vNewRow.Justify 	= "Left";
		vNewRow.Repeatable 	= True;

		vNewRow 			= vResult.Add();
		vNewRow.Name 		= "VoiceMailWaiting";
		vNewRow.Lenght 		= 1;
		vNewRow.Justify 	= "Left";
		vNewRow.Repeatable 	= True;

		vNewRow 			= vResult.Add();
		vNewRow.Name 		= "MessageWaiting";
		vNewRow.Lenght 		= 1;
		vNewRow.Justify 	= "Left";
		vNewRow.Repeatable 	= True;

	// City Verify Response
	ElsIf pMessageType = "D" Then
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "AccountNumber";
		vNewRow.Lenght 	= 12;   
		vNewRow.Justify = "Left";

		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "CreditLimit";
		vNewRow.Lenght 	= 9;
		vNewRow.Justify = "Right";

		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "FolioName";
		vNewRow.Lenght 	= 30;
		vNewRow.Justify = "Left";

		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "CurrentBalance";
		vNewRow.Lenght 	= 9;
		vNewRow.Justify = "Right";
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "CheckOutToday";
		vNewRow.Lenght 	= 1;
		vNewRow.Justify = "Left";
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "VoiceMailWaiting";
		vNewRow.Lenght 	= 1;
		vNewRow.Justify = "Left";
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "MessageWaiting";
		vNewRow.Lenght 	= 1;
		vNewRow.Justify = "Left";
		
	// Posting Acknowledgement
	ElsIf pMessageType = "O" Then
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "Success";
		vNewRow.Lenght 	= 1;
		vNewRow.Justify = "Left";
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "ExplanationText";
		vNewRow.Lenght 	= 20;
		vNewRow.Justify = "Left";
		
	// Verify Failure Response
	ElsIf pMessageType = "E" Then
		
		vNewRow 		= vResult.Add();
		vNewRow.Name 	= "ExplanationText";
		vNewRow.Lenght 	= 20;
		vNewRow.Justify = "Left";
		
	#EndRegion
	
	Else
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SquirrelPOS_POST", Enums.ExternalSystemEventTypes.Error, pMessageType, , "Unknown message type!");
	EndIf;
	
	Return vResult;
	
EndFunction // GetMessageDescription

// --------------------------------------------------------------------------------
Function CreateMessageFromStructure(pInteractionParameters, pMessageType, pDataStructure, pSequenceNumber)
		
	vResult = pMessageType + pSequenceNumber;
	
	vMessageDescription = GetMessageDescription(pInteractionParameters, pMessageType);
	vRepeatableData 	= Undefined;
	pDataStructure.Property("Repeatable", vRepeatableData);		
	
	If vRepeatableData <> Undefined Then
		vFirstRow = True;
		For Each vDataRow in vRepeatableData Do
			For Each vMessageField in vMessageDescription Do
				vValue 	= Undefined;
				
				If vMessageField.Repeatable = True Then
					vValue	= vDataRow[vMessageField.Name];
					vResult = vResult + FormatValue(vValue, vMessageField.Lenght, vMessageField.Justify);	
				ElsIf vFirstRow Then						
					pDataStructure.Property(vMessageField.Name, vValue);
					vResult = vResult + FormatValue(vValue, vMessageField.Lenght, vMessageField.Justify);
				EndIf;
				
			EndDo;
			vFirstRow = False;
		EndDo;
	Else
		For Each vMessageField in vMessageDescription Do
			
			vValue 	= Undefined;	
			pDataStructure.Property(vMessageField.Name, vValue);
			vResult = vResult + FormatValue(vValue, vMessageField.Lenght, vMessageField.Justify);
			
		EndDo;		
	EndIf;
	
	Return vResult;
	
EndFunction // CreateMessageFromStructure

// --------------------------------------------------------------------------------
Function FormatValue(pValue, pLenght, pJustify)
	
	vResult = "";
	
	If NOT ValueIsFilled(pValue) Then
		If pJustify = "Right" Then
			While StrLen(vResult) < pLenght Do
				vResult = "0" + vResult;	
			EndDo;
		Else
			While StrLen(vResult) < pLenght Do
				vResult = vResult + " ";	
			EndDo;	
		EndIf;
		
		Return vResult;
	EndIf;
	
	vResult = TrimAll(Format(pValue, "NFD=0; NZ=0; NG="));
	
	If StrLen(vResult) >= pLenght Then
		vResult = Left(vResult, pLenght);
	Else
		If pJustify = "Right" Then
			While StrLen(vResult) < pLenght Do
				vResult = "0" + vResult;	
			EndDo;
		Else
			While StrLen(vResult) < pLenght Do
				vResult = vResult + " ";	
			EndDo;	
		EndIf;
	EndIf;
	
	Return vResult;
	
EndFunction // FormatValue

// --------------------------------------------------------------------------------
Function GetRepeatableTable(pInteractionParameters, pMessageType)
	
	vResult = New ValueTable;
	
	vMessageDescription = GetMessageDescription(pInteractionParameters, pMessageType);

	For Each vMessageRow in vMessageDescription Do
		If vMessageRow.Repeatable = True Then
			vResult.Columns.Add(vMessageRow.Name);	
		EndIf;
	EndDo;
	
	Return vResult;
	
EndFunction // GetRepeatableTable

// --------------------------------------------------------------------------------
Function ReadRequestMessage(pBase64Request)
	
	vResult = New Structure("BinaryDataBufferID, Message", Undefined, "");
	
	If NOT IsBlankString(pBase64Request) Then
		
		// Get binary array from request
		vBinaryDataBufferRequest = GetBinaryDataBufferFromBase64String(pBase64Request);
		
		// Cut message lenght data
		vBinaryDataBufferRequest = vBinaryDataBufferRequest.GetSlice(4);
		
		// Get message ID bytes
		vResult.BinaryDataBufferID = vBinaryDataBufferRequest.GetSlice(0, 4); 
		
		// Get message bytes
		vMessageBinaryDataBuffer = vBinaryDataBufferRequest.GetSlice(4);
		
		// Get message string
		vResult.Message = GetStringFromBinaryDataBuffer(vMessageBinaryDataBuffer);
		
	EndIf;
	
	Return vResult;
	
EndFunction // ReadRequestMessage

// --------------------------------------------------------------------------------
Function CreateResponseMessage(pBinaryDataBufferID, pResponseString)
	
	vResult = "";
	
	If NOT IsBlankString(pResponseString) Then
		
		// Get response lenght
		vResponseLenght	= StrLen(pResponseString);
		
		// Get binary array from response 
		vBinaryDataBufferResponse = GetBinaryDataBufferFromString(pResponseString);
		
		// Create result binary array (4 bytes response lenght, 4 bytes id, response) 
		vBinaryDataBufferResult = New BinaryDataBuffer(8 + vResponseLenght);
		
		// Write message lenght
		vBinaryDataBufferResult.WriteInt32(0, vResponseLenght, ByteOrder.BigEndian);
		
		// Write message id
		vBinaryDataBufferResult.Write(4, pBinaryDataBufferID);
		
		// Write message
		vBinaryDataBufferResult.Write(8, vBinaryDataBufferResponse);
		
		// Get base64 result string
		vResult = GetBase64StringFromBinaryDataBuffer(vBinaryDataBufferResult);
		
	EndIf;
	
	Return vResult;
	
EndFunction // CreateResponseMessage

#EndRegion
