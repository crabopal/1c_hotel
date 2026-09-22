		 
#Region Public

// --------------------------------------------------------------------------------
//  Get settings
// 
// Returns:
//  Structure - ExternalSystemCode, WSHost, ResourceAddress, EchoToken, TimeStamp, Version
//
Function GetSettings() Export
	vResult = New Structure("ExternalSystemCode, WSHost, ResourceAddress, EchoToken, TimeStamp, Version");
	vResult.ExternalSystemCode	= "Siteminder";
	vResult.WSHost				= "cmtpi.siteminder.com:443";
	vResult.ResourceAddress		= "pmsxchangev2/services/1CHOTEL";
	vResult.EchoToken			= String(New UUID);
	vResult.TimeStamp			= Format(CurrentSessionDate(),"DF=yyyy-MM-ddTHH:mm:ss+03:00");
	vResult.Version				= "1.0";
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
Function Ping(pUsername, pPassword, pHTTPHost, pResourceAddress) Export
	If NOT ValueIsFilled(pHTTPHost) Then
		Return Undefined;
	EndIf;
	vSettings = GetSettings();
	
	If ValueIsFilled(pResourceAddress) Then
		vResourceAddress = pResourceAddress; 	
	Else
		vResourceAddress = vSettings.ResourceAddress;	
	EndIf;
	
	vXMLDocument = New XMLWriter;
	vXMLDocument.SetString();
	
	#Region Envelope
	vXMLDocument.WriteStartElement("soapenv:Envelope");
	vXMLDocument.WriteAttribute("xmlns:soapenv","http://schemas.xmlsoap.org/soap/envelope/");
	vXMLDocument.WriteAttribute("xmlns:wsse","http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd");
	vXMLDocument.WriteAttribute("xmlns:ns","http://www.opentravel.org/OTA/2003/05");
		#Region Header
		vXMLDocument.WriteStartElement("soapenv:Header");
			#Region Security 
			vXMLDocument.WriteStartElement("wsse:Security");
			//vXMLDocument.WriteAttribute("soap:mustUnderstand", "1");

				#Region UsernameToken
				vXMLDocument.WriteStartElement("wsse:UsernameToken");
				
					vXMLDocument.WriteStartElement("wsse:Username");
					vXMLDocument.WriteText(pUsername);
					vXMLDocument.WriteEndElement();
					
					vXMLDocument.WriteStartElement("wsse:Password");
					vXMLDocument.WriteAttribute("Type", "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText");
					vXMLDocument.WriteText(pPassword);
					vXMLDocument.WriteEndElement();
					
				vXMLDocument.WriteEndElement(); //UsernameToken
				#EndRegion
			vXMLDocument.WriteEndElement(); //Security
			#EndRegion
		vXMLDocument.WriteEndElement(); //Header
		#EndRegion
		#Region Body
		vXMLDocument.WriteStartElement("soapenv:Body");	
			vXMLDocument.WriteStartElement("ns:OTA_PingRQ");
			vXMLDocument.WriteAttribute("TimeStamp", vSettings.TimeStamp);
			vXMLDocument.WriteAttribute("EchoToken", vSettings.EchoToken);
			vXMLDocument.WriteAttribute("Version", vSettings.Version);
			vXMLDocument.WriteEndElement(); //OTA_PingRQ
		vXMLDocument.WriteEndElement(); //Body
		#EndRegion
	vXMLDocument.WriteEndElement(); //Envelope
	#EndRegion	
	
	vXMLRequest 	= vXMLDocument.Close();
	vXMLRequest		= ChannelManagers.FormatXMLString(vXMLRequest);	
	vXMLResponse 	= ChannelManagers.SendQuery(vXMLRequest, pHTTPHost, vResourceAddress, "PingRQ");
	
	vResult = ChannelManagers.CheckXMLAnswerForErrors(vXMLResponse); 
	vResult.Insert("RawRequest", vXMLRequest);
	vResult.Insert("TimeStamp", vSettings.TimeStamp);
	vResult.Insert("EchoToken", vSettings.EchoToken);
	Return vResult; 
	
EndFunction

// --------------------------------------------------------------------------------
Function SetRoomRates(pUsername, pPassword, pHTTPHost, pResourceAddress, pRequestorID, pHotelCode, pRoomRates) Export
	
	vSettings = GetSettings();
	
	If ValueIsFilled(pResourceAddress) Then
		vResourceAddress = pResourceAddress; 	
	Else
		vResourceAddress = vSettings.ResourceAddress;	
	EndIf;
	
	vXMLDocument = New XMLWriter;
	vXMLDocument.SetString();
	
	#Region Envelope
	vXMLDocument.WriteStartElement("soapenv:Envelope");
	vXMLDocument.WriteAttribute("xmlns:soapenv","http://schemas.xmlsoap.org/soap/envelope/");
	vXMLDocument.WriteAttribute("xmlns:wsse","http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd");
	vXMLDocument.WriteAttribute("xmlns:ns","http://www.opentravel.org/OTA/2003/05");
		#Region Header
		vXMLDocument.WriteStartElement("soapenv:Header");
			#Region Security 
			vXMLDocument.WriteStartElement("wsse:Security");

				#Region UsernameToken
				vXMLDocument.WriteStartElement("wsse:UsernameToken");
				
					vXMLDocument.WriteStartElement("wsse:Username");
					vXMLDocument.WriteText(pUsername);
					vXMLDocument.WriteEndElement();
					
					vXMLDocument.WriteStartElement("wsse:Password");
					vXMLDocument.WriteAttribute("Type", "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText");
					vXMLDocument.WriteText(pPassword);
					vXMLDocument.WriteEndElement();
					
				vXMLDocument.WriteEndElement(); //UsernameToken
				#EndRegion
			vXMLDocument.WriteEndElement(); //Security
			#EndRegion
		vXMLDocument.WriteEndElement(); //Header
		#EndRegion
		#Region Body
		vXMLDocument.WriteStartElement("soapenv:Body");
			#Region OTA_HotelRateAmountNotifRQ
			vXMLDocument.WriteStartElement("ns:OTA_HotelRateAmountNotifRQ");
			vXMLDocument.WriteAttribute("TimeStamp", vSettings.TimeStamp);
			vXMLDocument.WriteAttribute("EchoToken", vSettings.EchoToken);
			vXMLDocument.WriteAttribute("Version", vSettings.Version);
			
				vXMLDocument.WriteStartElement("ns:POS");
					vXMLDocument.WriteStartElement("ns:Source");
						vXMLDocument.WriteStartElement("ns:RequestorID");
						vXMLDocument.WriteAttribute("ID", pRequestorID);
						vXMLDocument.WriteAttribute("Type", "22");
						vXMLDocument.WriteEndElement(); //RequestorID
					vXMLDocument.WriteEndElement(); //Source
				vXMLDocument.WriteEndElement(); //POS
				
				vXMLDocument.WriteStartElement("ns:RateAmountMessages");
				vXMLDocument.WriteAttribute("HotelCode", pHotelCode);
					
				For Each vRow in pRoomRates Do
				#Region RateAmountMessage
					vXMLDocument.WriteStartElement("ns:RateAmountMessage");
						vXMLDocument.WriteStartElement("ns:StatusApplicationControl");
						vXMLDocument.WriteAttribute("InvTypeCode", 					vRow.RoomTypeCode);
						vXMLDocument.WriteAttribute("RatePlanCode", 				vRow.RateCode);
						vXMLDocument.WriteEndElement(); //StatusApplicationControl
						
						vXMLDocument.WriteStartElement("ns:Rates");
						                                                                   
						vXMLDocument.WriteStartElement("ns:Rate");
							vXMLDocument.WriteAttribute("CurrencyCode", 			vRow.CurrencyCode);
							vXMLDocument.WriteAttribute("Start", 					Format(vRow.Start,"DF=yyyy-MM-dd"));
							vXMLDocument.WriteAttribute("End", 						Format(?(ValueIsFilled(vRow.End),vRow.End,vRow.Start),"DF=yyyy-MM-dd"));
							
								vXMLDocument.WriteStartElement("ns:BaseByGuestAmts");
									vXMLDocument.WriteStartElement("ns:BaseByGuestAmt");
									vXMLDocument.WriteAttribute("AmountAfterTax", 	Format(vRow.Price,"NFD=2; NDS=.; NZ=; NG="));
									vXMLDocument.WriteEndElement(); //BaseByGuestAmt
									
								vXMLDocument.WriteEndElement(); //BaseByGuestAmts
								
								vXMLDocument.WriteStartElement("ns:RateDescription");
								
									vXMLDocument.WriteStartElement("ns:Text");
									vXMLDocument.WriteText(							NStr(vRow.Description));
									vXMLDocument.WriteEndElement(); //Text
									
								vXMLDocument.WriteEndElement(); //RateDescription
								
							vXMLDocument.WriteEndElement(); //Rate
							
						vXMLDocument.WriteEndElement(); //Rates
					vXMLDocument.WriteEndElement(); //RateAmountMessage
				#EndRegion
				EndDo;
					
				vXMLDocument.WriteEndElement(); //RateAmountMessages

			vXMLDocument.WriteEndElement(); //OTA_HotelRateAmountNotifRQ
			#EndRegion
		vXMLDocument.WriteEndElement(); //Body
		#EndRegion
	vXMLDocument.WriteEndElement(); //Envelope
	#EndRegion	
	
	vXMLRequest = vXMLDocument.Close();

	vXMLRequest	= ChannelManagers.FormatXMLString(vXMLRequest);
	
	vXMLResponse = ChannelManagers.SendQuery(vXMLRequest, pHTTPHost, vResourceAddress, "HotelRateAmountNotifRQ");
	
	vResult = ChannelManagers.CheckXMLAnswerForErrors(vXMLResponse); 
	vResult.Insert("RawRequest", vXMLRequest);
	vResult.Insert("TimeStamp", vSettings.TimeStamp);
	vResult.Insert("EchoToken", vSettings.EchoToken);
	Return vResult; 
	
EndFunction

// --------------------------------------------------------------------------------
Function SetAvailability(pUsername, pPassword, pHTTPHost, pResourceAddress, pRequestorID, pHotelCode, pAvailability) Export
	
	vSettings = GetSettings();
	
	If ValueIsFilled(pResourceAddress) Then
		vResourceAddress = pResourceAddress; 	
	Else
		vResourceAddress = vSettings.ResourceAddress;	
	EndIf;
	
	vXMLDocument = New XMLWriter;
	vXMLDocument.SetString();
	
	#Region Envelope
	vXMLDocument.WriteStartElement("soapenv:Envelope");
	vXMLDocument.WriteAttribute("xmlns:soapenv","http://schemas.xmlsoap.org/soap/envelope/");
	vXMLDocument.WriteAttribute("xmlns:wsse","http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd");
	vXMLDocument.WriteAttribute("xmlns:ns","http://www.opentravel.org/OTA/2003/05");
		#Region Header
		vXMLDocument.WriteStartElement("soapenv:Header");
			#Region Security 
			vXMLDocument.WriteStartElement("wsse:Security");
			//vXMLDocument.WriteAttribute("soap:mustUnderstand", "1");

				#Region UsernameToken
				vXMLDocument.WriteStartElement("wsse:UsernameToken");
				
					vXMLDocument.WriteStartElement("wsse:Username");
					vXMLDocument.WriteText(pUsername);
					vXMLDocument.WriteEndElement();
					
					vXMLDocument.WriteStartElement("wsse:Password");
					vXMLDocument.WriteAttribute("Type", "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText");
					vXMLDocument.WriteText(pPassword);
					vXMLDocument.WriteEndElement();
					
				vXMLDocument.WriteEndElement(); //UsernameToken
				#EndRegion
			vXMLDocument.WriteEndElement(); //Security
			#EndRegion
		vXMLDocument.WriteEndElement(); //Header
		#EndRegion
		#Region Body
		vXMLDocument.WriteStartElement("soapenv:Body");
			#Region OTA_HotelAvailNotifRQ
			vXMLDocument.WriteStartElement("ns:OTA_HotelAvailNotifRQ");
			vXMLDocument.WriteAttribute("TimeStamp", vSettings.TimeStamp);
			vXMLDocument.WriteAttribute("EchoToken", vSettings.EchoToken);
			vXMLDocument.WriteAttribute("Version", vSettings.Version);
			
				vXMLDocument.WriteStartElement("ns:POS");
					vXMLDocument.WriteStartElement("ns:Source");
						vXMLDocument.WriteStartElement("ns:RequestorID");
						vXMLDocument.WriteAttribute("ID", pRequestorID);
						vXMLDocument.WriteAttribute("Type", "22");
						vXMLDocument.WriteEndElement(); //RequestorID
					vXMLDocument.WriteEndElement(); //Source
				vXMLDocument.WriteEndElement(); //POS
				
				#Region AvailStatusMessages
				vXMLDocument.WriteStartElement("ns:AvailStatusMessages");
				vXMLDocument.WriteAttribute("HotelCode", pHotelCode);
					
				For Each vRow in pAvailability Do
					vXMLDocument.WriteStartElement("ns:AvailStatusMessage");
					vXMLDocument.WriteAttribute("BookingLimit", 					Format(vRow.BookingLimit,"NFD=; NZ=; NG="));
					
						vXMLDocument.WriteStartElement("ns:StatusApplicationControl");
						vXMLDocument.WriteAttribute("Start", 						Format(vRow.Start,"DF=yyyy-MM-dd"));
						vXMLDocument.WriteAttribute("End", 							Format(vRow.End,"DF=yyyy-MM-dd"));
						vXMLDocument.WriteAttribute("InvTypeCode", 					vRow.RoomTypeCode);
						//vXMLDocument.WriteAttribute("RatePlanCode", 				vRow.RateCode);
						vXMLDocument.WriteEndElement(); //StatusApplicationControl
											
					vXMLDocument.WriteEndElement(); //AvailStatusMessage	
				EndDo;
					
				vXMLDocument.WriteEndElement(); //AvailStatusMessages
				#EndRegion
			vXMLDocument.WriteEndElement(); //OTA_HotelAvailNotifRQ
			#EndRegion
		vXMLDocument.WriteEndElement(); //Body
		#EndRegion
	vXMLDocument.WriteEndElement(); //Envelope
	#EndRegion	
	vXMLRequest = vXMLDocument.Close();
	
	vXMLRequest	= ChannelManagers.FormatXMLString(vXMLRequest);
	
	vXMLResponse = ChannelManagers.SendQuery(vXMLRequest, pHTTPHost, vResourceAddress, "HotelAvailNotifRQ");
	
	vResult = ChannelManagers.CheckXMLAnswerForErrors(vXMLResponse); 
	vResult.Insert("RawRequest", vXMLRequest);
	vResult.Insert("TimeStamp", vSettings.TimeStamp);
	vResult.Insert("EchoToken", vSettings.EchoToken);
	Return vResult; 
	
EndFunction

// --------------------------------------------------------------------------------
Function SetRestrictions(pUsername, pPassword, pHTTPHost, pResourceAddress, pRequestorID, pHotelCode, pRestrictions) Export
	vSettings = GetSettings();
	
	If ValueIsFilled(pResourceAddress) Then
		vResourceAddress = pResourceAddress; 	
	Else
		vResourceAddress = vSettings.ResourceAddress;	
	EndIf;
	
	vXMLDocument = New XMLWriter;
	vXMLDocument.SetString();
	
	#Region Envelope
	vXMLDocument.WriteStartElement("soapenv:Envelope");
	vXMLDocument.WriteAttribute("xmlns:soapenv","http://schemas.xmlsoap.org/soap/envelope/");
	vXMLDocument.WriteAttribute("xmlns:wsse","http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd");
	vXMLDocument.WriteAttribute("xmlns:ns","http://www.opentravel.org/OTA/2003/05");
		#Region Header
		vXMLDocument.WriteStartElement("soapenv:Header");
			#Region Security 
			vXMLDocument.WriteStartElement("wsse:Security");
			//vXMLDocument.WriteAttribute("soap:mustUnderstand", "1");

				#Region UsernameToken
				vXMLDocument.WriteStartElement("wsse:UsernameToken");
				
					vXMLDocument.WriteStartElement("wsse:Username");
					vXMLDocument.WriteText(pUsername);
					vXMLDocument.WriteEndElement();
					
					vXMLDocument.WriteStartElement("wsse:Password");
					vXMLDocument.WriteAttribute("Type", "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText");
					vXMLDocument.WriteText(pPassword);
					vXMLDocument.WriteEndElement();
					
				vXMLDocument.WriteEndElement(); //UsernameToken
				#EndRegion
			vXMLDocument.WriteEndElement(); //Security
			#EndRegion
		vXMLDocument.WriteEndElement(); //Header
		#EndRegion
		#Region Body
		vXMLDocument.WriteStartElement("soapenv:Body");
			#Region OTA_HotelAvailNotifRQ
			vXMLDocument.WriteStartElement("ns:OTA_HotelAvailNotifRQ");
			vXMLDocument.WriteAttribute("TimeStamp", vSettings.TimeStamp);
			vXMLDocument.WriteAttribute("EchoToken", vSettings.EchoToken);
			vXMLDocument.WriteAttribute("Version", vSettings.Version);
			
				vXMLDocument.WriteStartElement("ns:POS");
					vXMLDocument.WriteStartElement("ns:Source");
						vXMLDocument.WriteStartElement("ns:RequestorID");
						vXMLDocument.WriteAttribute("ID", pRequestorID);
						vXMLDocument.WriteAttribute("Type", "22");
						vXMLDocument.WriteEndElement(); //RequestorID
					vXMLDocument.WriteEndElement(); //Source
				vXMLDocument.WriteEndElement(); //POS
				
				#Region AvailStatusMessages
				vXMLDocument.WriteStartElement("ns:AvailStatusMessages");
				vXMLDocument.WriteAttribute("HotelCode", pHotelCode);
					
				For Each vRow in pRestrictions Do
					#Region StopSell
					vXMLDocument.WriteStartElement("ns:AvailStatusMessage");
					
						vXMLDocument.WriteStartElement("ns:StatusApplicationControl");
						vXMLDocument.WriteAttribute("Start", 						Format(vRow.Start,"DF=yyyy-MM-dd"));
						vXMLDocument.WriteAttribute("End", 							Format(vRow.End,"DF=yyyy-MM-dd"));
						vXMLDocument.WriteAttribute("InvTypeCode", 					vRow.RoomTypeCode);
						vXMLDocument.WriteAttribute("RatePlanCode", 				vRow.RateCode);
						
							If ValueIsFilled(vRow.Agent) Then
								vXMLDocument.WriteStartElement("ns:DestinationSystemCodes");
									vXMLDocument.WriteStartElement("ns:DestinationSystemCode");
									vXMLDocument.WriteText(							vRow.Agent);
									vXMLDocument.WriteEndElement(); //DestinationSystemCode
								vXMLDocument.WriteEndElement(); //DestinationSystemCodes
							EndIf;

						vXMLDocument.WriteEndElement(); //StatusApplicationControl
						
						
						vXMLDocument.WriteStartElement("ns:RestrictionStatus");
						If vRow.StopSell Then
							vXMLDocument.WriteAttribute("Status","Close");
						Else
							vXMLDocument.WriteAttribute("Status","Open");
						EndIf;
						vXMLDocument.WriteEndElement(); //RestrictionStatus							
						
					vXMLDocument.WriteEndElement(); //AvailStatusMessage
					#EndRegion
					
					#Region CTA
					vXMLDocument.WriteStartElement("ns:AvailStatusMessage");
					
						vXMLDocument.WriteStartElement("ns:StatusApplicationControl");
						vXMLDocument.WriteAttribute("Start", 						Format(vRow.Start,"DF=yyyy-MM-dd"));
						vXMLDocument.WriteAttribute("End", 							Format(vRow.End,"DF=yyyy-MM-dd"));
						vXMLDocument.WriteAttribute("InvTypeCode", 					vRow.RoomTypeCode);
						vXMLDocument.WriteAttribute("RatePlanCode", 				vRow.RateCode);
						
							If ValueIsFilled(vRow.Agent) Then
								vXMLDocument.WriteStartElement("ns:DestinationSystemCodes");
									vXMLDocument.WriteStartElement("ns:DestinationSystemCode");
									vXMLDocument.WriteText(							vRow.Agent);
									vXMLDocument.WriteEndElement(); //DestinationSystemCode
								vXMLDocument.WriteEndElement(); //DestinationSystemCodes
							EndIf;
						vXMLDocument.WriteEndElement(); //StatusApplicationControl
						
						
						vXMLDocument.WriteStartElement("ns:RestrictionStatus");
						If vRow.CTA Then
							vXMLDocument.WriteAttribute("Status","Close");
						Else
							vXMLDocument.WriteAttribute("Status","Open");
						EndIf;
						vXMLDocument.WriteAttribute("Restriction","Arrival");
						vXMLDocument.WriteEndElement(); //RestrictionStatus
					vXMLDocument.WriteEndElement(); //AvailStatusMessage	
					#EndRegion
					
					#Region CTD

					vXMLDocument.WriteStartElement("ns:AvailStatusMessage");
					
						vXMLDocument.WriteStartElement("ns:StatusApplicationControl");
						vXMLDocument.WriteAttribute("Start", 						Format(vRow.Start,"DF=yyyy-MM-dd"));
						vXMLDocument.WriteAttribute("End", 							Format(vRow.End,"DF=yyyy-MM-dd"));
						vXMLDocument.WriteAttribute("InvTypeCode", 					vRow.RoomTypeCode);
						vXMLDocument.WriteAttribute("RatePlanCode", 				vRow.RateCode);
						
							If ValueIsFilled(vRow.Agent) Then
								vXMLDocument.WriteStartElement("ns:DestinationSystemCodes");
									vXMLDocument.WriteStartElement("ns:DestinationSystemCode");
									vXMLDocument.WriteText(									vRow.Agent);
									vXMLDocument.WriteEndElement(); //DestinationSystemCode
								vXMLDocument.WriteEndElement(); //DestinationSystemCodes
							EndIf;
						
						vXMLDocument.WriteEndElement(); //StatusApplicationControl
						
						vXMLDocument.WriteStartElement("ns:RestrictionStatus");
						If vRow.CTD Then
							vXMLDocument.WriteAttribute("Status","Close");
						Else
							vXMLDocument.WriteAttribute("Status","Open");
						EndIf;
						vXMLDocument.WriteAttribute("Restriction","Departure");
						vXMLDocument.WriteEndElement(); //RestrictionStatus
					vXMLDocument.WriteEndElement(); //AvailStatusMessage
					#EndRegion

					#Region MinMaxStay
					If ValueIsFilled(vRow.MinStay) or ValueIsFilled(vRow.MaxStay) Then
						vXMLDocument.WriteStartElement("ns:AvailStatusMessage");
						
							vXMLDocument.WriteStartElement("ns:StatusApplicationControl");
							vXMLDocument.WriteAttribute("Start", 						Format(vRow.Start,"DF=yyyy-MM-dd"));
							vXMLDocument.WriteAttribute("End", 							Format(vRow.End,"DF=yyyy-MM-dd"));
							vXMLDocument.WriteAttribute("InvTypeCode", 					vRow.RoomTypeCode);
							vXMLDocument.WriteAttribute("RatePlanCode", 				vRow.RateCode);
							
								If ValueIsFilled(vRow.Agent) Then
									vXMLDocument.WriteStartElement("ns:DestinationSystemCodes");
										vXMLDocument.WriteStartElement("ns:DestinationSystemCode");
										vXMLDocument.WriteText(									vRow.Agent);
										vXMLDocument.WriteEndElement(); //DestinationSystemCode
									vXMLDocument.WriteEndElement(); //DestinationSystemCodes
								EndIf;
							
							vXMLDocument.WriteEndElement(); //StatusApplicationControl
							
								vXMLDocument.WriteStartElement("ns:LengthsOfStay");
								If ValueIsFilled(vRow.MinStay) Then
									vXMLDocument.WriteStartElement("ns:LengthOfStay");
									vXMLDocument.WriteAttribute("MinMaxMessageType", 	"SetMinLOS");
									vXMLDocument.WriteAttribute("Time", 				Format(vRow.MinStay,"NFD=; NZ=; NG="));
		                            vXMLDocument.WriteEndElement(); //LengthOfStay
								EndIf;
								If ValueIsFilled(vRow.MaxStay) Then 
									vXMLDocument.WriteStartElement("ns:LengthOfStay");
									vXMLDocument.WriteAttribute("MinMaxMessageType", 	"SetMaxLOS");
									vXMLDocument.WriteAttribute("Time", 				Format(vRow.MaxStay,"NFD=; NZ=; NG="));
		                            vXMLDocument.WriteEndElement(); //LengthOfStay
								EndIf;
								
								vXMLDocument.WriteEndElement(); //LengthsOfStay
						vXMLDocument.WriteEndElement(); //AvailStatusMessage
					EndIf;													
					#EndRegion
				EndDo;
					
				vXMLDocument.WriteEndElement(); //AvailStatusMessages
				#EndRegion
			vXMLDocument.WriteEndElement(); //OTA_HotelAvailNotifRQ
			#EndRegion
		vXMLDocument.WriteEndElement(); //Body
		#EndRegion
	vXMLDocument.WriteEndElement(); //Envelope
	#EndRegion	
	vXMLRequest = vXMLDocument.Close();

	vXMLRequest	= ChannelManagers.FormatXMLString(vXMLRequest);
	
	vXMLResponse = ChannelManagers.SendQuery(vXMLRequest, pHTTPHost, vResourceAddress, "HotelAvailNotifRQ");
	
	vResult = ChannelManagers.CheckXMLAnswerForErrors(vXMLResponse); 
	vResult.Insert("RawRequest", vXMLRequest);
	vResult.Insert("TimeStamp", vSettings.TimeStamp);
	vResult.Insert("EchoToken", vSettings.EchoToken);

	Return vResult;	
	
EndFunction

// --------------------------------------------------------------------------------
Function GetReservations(pUsername, pPassword, pHTTPHost, pResourceAddress, pRequestorID, pHotelCode, pInteractionParameters, pLoadReservations = True, pConfirmReservations = True, pGetPrices, pDefaultAccomondationType) Export

	vSettings = GetSettings();
	
	If ValueIsFilled(pResourceAddress) Then
		vResourceAddress = pResourceAddress; 	
	Else
		vResourceAddress = vSettings.ResourceAddress;	
	EndIf;
	
	vXMLDocument = New XMLWriter;
	vXMLDocument.SetString();
	
	#Region Envelope
	vXMLDocument.WriteStartElement("soapenv:Envelope");
	vXMLDocument.WriteAttribute("xmlns:soapenv","http://schemas.xmlsoap.org/soap/envelope/");
	vXMLDocument.WriteAttribute("xmlns:wsse","http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd");
	vXMLDocument.WriteAttribute("xmlns:ns","http://www.opentravel.org/OTA/2003/05");
		#Region Header
		vXMLDocument.WriteStartElement("soapenv:Header");
			#Region Security 
			vXMLDocument.WriteStartElement("wsse:Security");
			//vXMLDocument.WriteAttribute("soap:mustUnderstand", "1");

				#Region UsernameToken
				vXMLDocument.WriteStartElement("wsse:UsernameToken");
				
					vXMLDocument.WriteStartElement("wsse:Username");
					vXMLDocument.WriteText(pUsername);
					vXMLDocument.WriteEndElement();
					
					vXMLDocument.WriteStartElement("wsse:Password");
					vXMLDocument.WriteAttribute("Type", "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText");
					vXMLDocument.WriteText(pPassword);
					vXMLDocument.WriteEndElement();
					
				vXMLDocument.WriteEndElement(); //UsernameToken
				#EndRegion
			vXMLDocument.WriteEndElement(); //Security
			#EndRegion
		vXMLDocument.WriteEndElement(); //Header
		#EndRegion
		#Region Body
		vXMLDocument.WriteStartElement("soapenv:Body");
			#Region OTA_ReadRQ
			vXMLDocument.WriteStartElement("ns:OTA_ReadRQ");
			vXMLDocument.WriteAttribute("TimeStamp", vSettings.TimeStamp);
			vXMLDocument.WriteAttribute("EchoToken", vSettings.EchoToken);
			vXMLDocument.WriteAttribute("Version", vSettings.Version);
			
				vXMLDocument.WriteStartElement("ns:POS");
					vXMLDocument.WriteStartElement("ns:Source");
						vXMLDocument.WriteStartElement("ns:RequestorID");
						vXMLDocument.WriteAttribute("ID", pRequestorID);
						vXMLDocument.WriteAttribute("Type", "22");
						vXMLDocument.WriteEndElement(); //RequestorID
					vXMLDocument.WriteEndElement(); //Source
				vXMLDocument.WriteEndElement(); //POS
				
				vXMLDocument.WriteStartElement("ns:ReadRequests");
					vXMLDocument.WriteStartElement("ns:HotelReadRequest");
						vXMLDocument.WriteAttribute("HotelCode", pHotelCode);
							vXMLDocument.WriteStartElement("ns:SelectionCriteria");
							vXMLDocument.WriteAttribute("SelectionType", "Undelivered");
							vXMLDocument.WriteEndElement(); //RequestorID
					vXMLDocument.WriteEndElement(); //HotelReadRequest
				vXMLDocument.WriteEndElement(); //ReadRequests
				
			vXMLDocument.WriteEndElement(); //OTA_ReadRQ
			#EndRegion
		vXMLDocument.WriteEndElement(); //Body
		#EndRegion
	vXMLDocument.WriteEndElement(); //Envelope
	#EndRegion	
	
	vXMLRequest = vXMLDocument.Close();

	vXMLRequest	= ChannelManagers.FormatXMLString(vXMLRequest);
	
	vXMLResponse = ChannelManagers.SendQuery(vXMLRequest, pHTTPHost, vResourceAddress, "ReadRQ");
	vResult = ChannelManagers.CheckXMLAnswerForErrors(vXMLResponse);
	vResult.Insert("RawRequest", vXMLRequest);
	vResult.Insert("TimeStamp", vSettings.TimeStamp);
	vResult.Insert("EchoToken", vSettings.EchoToken);
	If vResult.Success then
		vReservations 		= ReadReservationsXML(vXMLResponse);
		vResult.Insert("ReservationsCount", vReservations.Count());
		vResult.Insert("Loaded", False);
		vResult.Insert("Confirmed", False);
		If vReservations.Count() > 0  and pLoadReservations Then
			vLoadedReservations = LoadReservations(vReservations, pInteractionParameters, pGetPrices, pDefaultAccomondationType);
			vFailedRow 			= vLoadedReservations.Find(False,"Success");
			
			For Each vRow in vLoadedReservations Do
				For Each vError in vRow.Errors Do
					vNewError = New Structure("Code, Type, Description", vError.Code, vError.Type, vError.Description);
					vResult.Errors.Add(vNewError);
				EndDo;
			EndDo;
			
			If vFailedRow = Undefined Then
				tcCommonFunctionOnClientServer.UserMessage(Nstr("en = 'Successfully loaded reservations!'; de = 'Successfully loaded reservations!'; ru = 'Successfully loaded reservations!'"));
				vResult.Loaded = True;
			Else
				tcCommonFunctionOnClientServer.UserMessage(Nstr("en = 'Failed to load some reservations!'; de = 'Failed to load some reservations!'; ru = 'Failed to load some reservations!'"));
			EndIf;
			
			If pConfirmReservations Then
				vConfirmResult 		= ConfirmReservation(pUsername, pPassword, pHTTPHost, pResourceAddress, pRequestorID, pHotelCode, vLoadedReservations);
				
				If vConfirmResult <> Undefined and vConfirmResult.Success Then
					tcCommonFunctionOnClientServer.UserMessage(Nstr("en = 'Successfully confirmed reservations!'; de = 'Successfully confirmed reservations!'; ru = 'Successfully confirmed reservations!'"));
					vResult.Confirmed = True;
				Else
					tcCommonFunctionOnClientServer.UserMessage(Nstr("en = 'Failed to confirm reservations!'; de = 'Failed to confirm reservations!'; ru = 'Failed to confirm reservations!'"));
				EndIf;
			EndIf;
			
		EndIf;	
	EndIf;
	
	Return vResult;	

EndFunction

// --------------------------------------------------------------------------------
Function GetReservationsFromFile(pXMLResponse, pInteractionParameters, pGetPrices, pDefaultAccomondationType) Export
	
	vReservations 		= ReadReservationsXML(pXMLResponse);
	
	vResult = ChannelManagers.CheckXMLAnswerForErrors(pXMLResponse);
	vResult.Insert("ReservationsCount", vReservations.Count());
	vResult.Insert("Loaded", False);
	vResult.Insert("Confirmed", False);
	
	If vReservations.Count() > 0  Then
		
		vLoadedReservations = LoadReservations(vReservations, pInteractionParameters, pGetPrices, pDefaultAccomondationType);
		vFailedRow 			= vLoadedReservations.Find(False,"Success");
		
		For Each vRow in vLoadedReservations Do
			For Each vError in vRow.Errors Do
				vNewError = New Structure("Code, Type, Description", vError.Code, vError.Type, vError.Description);
				vResult.Errors.Add(vNewError);
			EndDo;
		EndDo;
		
		If vFailedRow = Undefined Then
			tcCommonFunctionOnClientServer.UserMessage(Nstr("en = 'Successfully loaded reservations!'; de = 'Successfully loaded reservations!'; ru = 'Successfully loaded reservations!'"));
			vResult.Loaded = True;
		Else
			tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Failed to load some reservations!'; de = 'Failed to load some reservations!'; ru = 'Failed to load some reservations!'"));
		EndIf;
		
	EndIf;
	
	Return vResult;	

EndFunction

// --------------------------------------------------------------------------------
// Sync change
//
// Parameters:
//  pUsername					 - 	 - Channel manager login
//  pPassword					 - 	 - Channel manager password
//  pHTTPHost					 - 	 - Channel manager WS-host
//  pResourceAddress			 - 	 - 
//  pRequestorID				 - 	 - Channel manager requestor ID
//  pHotelCode					 - 	 - Hotel code in channel manager system
//  pInteractionParameters		 - 	 - ExternalSystemInteractions ref
//  pSyncInventory				 - 	 - 
//  pSyncRates					 - 	 - 
//  pSyncRestrictions			 - 	 - 
//  pSyncPeriod					 - 	 - 
//  pGetReservations			 - 	 - 
//  pGetPrices					 - 	 - 
//  pDefaultAccomondationType	 - 	 - 
//  pGetVacantRoomsAtMidnight	 - 	 - 
// 
// Returns:
//  Structure - of arrays RoomInventory
//
Function SyncChanges(pUsername, pPassword, pHTTPHost, pResourceAddress, pRequestorID, pHotelCode, pInteractionParameters, pSyncInventory, pSyncRates, pSyncRestrictions, pSyncPeriod, pGetReservations, pGetPrices, pDefaultAccomondationType, pGetVacantRoomsAtMidnight = False) Export
	vResult = New Structure("RoomInventory, RoomRates, RoomRestrictions, Reservations", New Array, New Array, New Array, New Array);
	
	vLastSyncDate = CurrentSessionDate();
	
	#Region Reservations
	If pGetReservations Then
		vResult.Reservations.Add(GetReservations(pUsername, pPassword, pHTTPHost, pResourceAddress, pRequestorID, pHotelCode, pInteractionParameters, True, True, pGetPrices, pDefaultAccomondationType));
		WriteLog(pInteractionParameters, "GetReservations", vResult.Reservations);
	EndIf;	
	#EndRegion
	
	// First get reservations, then, in case there were any, we have to immediatly return New availability
	vSyncTable = ChannelManagers.GetDateTablesToSync(pInteractionParameters, pSyncRates, pSyncRestrictions, pSyncPeriod, pGetVacantRoomsAtMidnight);
	
	#Region RoomInventory
	If pSyncInventory Then
		vSyncTable.RoomInventory.Columns.Add("RoomTypeCode");
		vSyncTable.RoomInventory = FilterBalancesTable(vSyncTable.RoomInventory, pInteractionParameters.Hotel, pInteractionParameters.InteractionID);
		
		If vSyncTable.RoomInventory.Count() > 0 Then
			vBalanceResult = Undefined;
			For Each vRoomInventoryRow in vSyncTable.RoomInventory Do
				If vBalanceResult = Undefined Then 
					vBalanceResult = GetBalances(vRoomInventoryRow.Hotel, pInteractionParameters.Allotment, vRoomInventoryRow.PeriodFrom, vRoomInventoryRow.PeriodTo, pInteractionParameters.InteractionID, vRoomInventoryRow.RoomType, vRoomInventoryRow.RoomTypeCode, pGetVacantRoomsAtMidnight);
				Else
					vBalance = GetBalances(vRoomInventoryRow.Hotel, pInteractionParameters.Allotment, vRoomInventoryRow.PeriodFrom, vRoomInventoryRow.PeriodTo, pInteractionParameters.InteractionID, vRoomInventoryRow.RoomType, vRoomInventoryRow.RoomTypeCode, pGetVacantRoomsAtMidnight);
					For Each vBalanceRow in vBalance Do
						vNewRow = vBalanceResult.Add();
						FillPropertyValues(vNewRow,vBalanceRow);
					EndDo;
				EndIf;
			EndDo;
			
			vAvailability = New ValueTable;
			vAvailability.Columns.Add("RoomTypeCode");
			vAvailability.Columns.Add("RateCode");
			vAvailability.Columns.Add("Start");
			vAvailability.Columns.Add("End");
			vAvailability.Columns.Add("BookingLimit");
			
			For Each vBalanceResultRow in vBalanceResult Do
				vNewRow 				= vAvailability.Add();
				vNewRow.RoomTypeCode 	= vBalanceResultRow.RoomTypeCode;
				vNewRow.Start 			= vBalanceResultRow.PeriodFrom;
				vNewRow.End 			= vBalanceResultRow.PeriodTo;
				vNewRow.BookingLimit 	= vBalanceResultRow.VacantRooms;			
			EndDo;
			
			vDailyAvailability = New ValueTable;
			vDailyAvailability.Columns.Add("Hotel");
			vDailyAvailability.Columns.Add("RoomType");
			vDailyAvailability.Columns.Add("Period");
			vDailyAvailability.Columns.Add("RoomsVacant");
			vDailyAvailability.Columns.Add("BedsVacant");
			
			For Each vBalanceResultRow in vBalanceResult Do
				vCurrentDate = BegOfDay(vBalanceResultRow.PeriodFrom);
				While BegOfDay(vCurrentDate) <= BegOfDay(vBalanceResultRow.PeriodTo) Do
					vNewRow 			= vDailyAvailability.Add();
					vNewRow.Hotel		= pInteractionParameters.Hotel; 					
					vNewRow.RoomType 	= vBalanceResultRow.RoomType;
					vNewRow.Period 		= vCurrentDate;
					vNewRow.RoomsVacant = vBalanceResultRow.VacantRooms;
					vNewRow.BedsVacant 	= vBalanceResultRow.VacantBeds;
					
					vCurrentDate = vCurrentDate + 24*60*60;
				EndDo;
			EndDo;
			
			SendRequests("SetAvailability", vResult.RoomInventory, pUsername, pPassword, pHTTPHost, pResourceAddress, pRequestorID, pHotelCode, vAvailability, 499);
			WriteLog(pInteractionParameters, "SetAvailability", vResult.RoomInventory);
		EndIf;
	EndIf;
	#EndRegion
	
	#Region RoomRate
	If pSyncRates Then 
		vSyncTable.RoomRate = FilterRatesTable(vSyncTable.RoomRate, pInteractionParameters.Hotel, pInteractionParameters.InteractionID);
		
		If vSyncTable.RoomRate.Count() > 0 Then
			vRatesResult = Undefined;
			For Each vRoomRateRow in vSyncTable.RoomRate Do
				vAccommodationsToSync = GetAllExternalRoomTypesCodes(vRoomRateRow.Hotel, pInteractionParameters.InteractionID, vRoomRateRow.RoomType);
				For Each vAccTemplate in vAccommodationsToSync Do
					If cmGetObjectRefByExternalSystemCode(vRoomRateRow.Hotel, pInteractionParameters.InteractionID, "Siteminder_RoomMapping_RR", vAccTemplate.ObjectExternalCode) = vRoomRateRow.RoomRate Then
						If vRatesResult = Undefined Then 
							vRatesResult = GetRates(vRoomRateRow.Hotel, pInteractionParameters, vRoomRateRow.PeriodFrom, vRoomRateRow.PeriodTo + 24*60*60, pInteractionParameters.InteractionID, vRoomRateRow.RoomType, "Siteminder_RoomMapping_RT", vAccTemplate.ObjectExternalCode);
						Else
							vRates = GetRates(vRoomRateRow.Hotel, pInteractionParameters, vRoomRateRow.PeriodFrom, vRoomRateRow.PeriodTo + 24*60*60, pInteractionParameters.InteractionID, vRoomRateRow.RoomType, "Siteminder_RoomMapping_RT", vAccTemplate.ObjectExternalCode);
							For Each vRateRow in vRates Do
								vNewRow = vRatesResult.Add();
								FillPropertyValues(vNewRow,vRateRow);
							EndDo;
						EndIf;
					EndIf;
				EndDo;
			EndDo;
			
			vRoomRates = PrepareRatesTable(vRatesResult, pInteractionParameters.Hotel, pInteractionParameters.InteractionID);
			    
			SendRequests("SetRoomRates", vResult.RoomRates, pUsername, pPassword, pHTTPHost, pResourceAddress, pRequestorID, pHotelCode, vRoomRates, 499);
			WriteLog(pInteractionParameters, "SetRoomRates", vResult.RoomRates);
		EndIf;
	EndIf;
	#EndRegion	
	
	#Region RoomRateRestrictions
	If pSyncRestrictions Then
		vSyncTable.RoomRestriction = FilterRatesTable(vSyncTable.RoomRestriction, pInteractionParameters.Hotel, pInteractionParameters.InteractionID); 
		
		If vSyncTable.RoomRestriction.Count() > 0 Then
			vRestrictionsResult = New ValueTable;
			vRestrictionsResult.Columns.Add("Start");
			vRestrictionsResult.Columns.Add("End");
			vRestrictionsResult.Columns.Add("RoomTypeCode");
			vRestrictionsResult.Columns.Add("RateCode");
			vRestrictionsResult.Columns.Add("Agent");
			vRestrictionsResult.Columns.Add("MinStay");
			vRestrictionsResult.Columns.Add("MaxStay");
			vRestrictionsResult.Columns.Add("StopSell");
			vRestrictionsResult.Columns.Add("CTA");
			vRestrictionsResult.Columns.Add("CTD");
			
			For Each vRoomRestrictionRow in vSyncTable.RoomRestriction Do
				vCurrentDate = vRoomRestrictionRow.PeriodFrom;
				While BegOfDay(vCurrentDate) <= BegOfDay(vRoomRestrictionRow.PeriodTo) Do
					vRestrictions = cmGetRoomRateRestrictions(pInteractionParameters.Hotel, vRoomRestrictionRow.RoomRate, vCurrentDate, vRoomRestrictionRow.RoomType,False);  
					vNewRow 				= vRestrictionsResult.Add();
					vNewRow.Start 			= vCurrentDate;
					vNewRow.End 			= vCurrentDate;
					vNewRow.RoomTypeCode	= vRoomRestrictionRow.RoomTypeCode;
					vNewRow.RateCode 		= vRoomRestrictionRow.RateCode;
					//vNewRow.Agent 			= ;
					If vRestrictions.MLOS > 0 Then
						vNewRow.MinStay 	= vRestrictions.MLOS;
					Else
						vNewRow.MinStay 	= 1;
					EndIf;
					If vRestrictions.MaxLOS > 0 Then
						vNewRow.MaxStay 	= vRestrictions.MaxLOS;
					Else
						vNewRow.MaxStay 	= 999;
					EndIf;
					vNewRow.StopSell 		= vRestrictions.StopSale;
					vNewRow.CTA 			= vRestrictions.CTA;
					vNewRow.CTD 			= vRestrictions.CTD;
					vCurrentDate = vCurrentDate + 24*60*60;
				EndDo;				
			EndDo;
			
			vClearArray = New Array;
			vPreviousRow = Undefined;
			For Each vRow in vRestrictionsResult Do
				If vPreviousRow <> Undefined Then
					If 	vPreviousRow.RoomTypeCode = vRow.RoomTypeCode
						And vPreviousRow.RateCode = vRow.RateCode
						And vPreviousRow.Agent = vRow.Agent
						And vPreviousRow.MinStay = vRow.MinStay
						And vPreviousRow.MaxStay = vRow.MaxStay
						And vPreviousRow.StopSell = vRow.StopSell
						And vPreviousRow.CTA = vRow.CTA
						And vPreviousRow.CTD = vRow.CTD Then
						vRow.Start = vPreviousRow.Start; 
						vClearArray.Add(vPreviousRow);
					EndIf;
				EndIf;
				vPreviousRow = vRow;
			EndDo;
			
			For Each vRow in vClearArray Do
				vRestrictionsResult.Delete(vRow);
			EndDo;
			
			SendRequests("SetRestrictions", vResult.RoomRestrictions, pUsername, pPassword, pHTTPHost, pResourceAddress, pRequestorID, pHotelCode, vRestrictionsResult, 124);
			WriteLog(pInteractionParameters, "SetRestrictions", vResult.RoomRestrictions);
		EndIf;
	EndIf;	
	#EndRegion
	
	#Region OnSuccess
	vSuccess = True;
	For Each vRow in vResult.RoomInventory Do
		If NOT vRow.Success Then
			vSuccess = False;
		EndIf;
	EndDo;
	For Each vRow in vResult.RoomRates Do
		If NOT vRow.Success Then
			vSuccess = False;
		EndIf;
	EndDo;
	For Each vRow in vResult.RoomRestrictions Do
		If NOT vRow.Success Then
			vSuccess = False;
		EndIf;
	EndDo;
	#EndRegion

	ChannelManagers.UpdateLastSyncTime(pInteractionParameters, False, vLastSyncDate, "", pSyncInventory, pSyncRates, pSyncRestrictions);
		
	Return vResult;
EndFunction // SyncChanges

// -------------------------------------------------------------------------
//  Function - Sync all for period
//
// Parameters:
//  pUsername					 - 	 - 
//  pPassword					 - 	 - 
//  pHTTPHost					 - 	 - 
//  pResourceAddress			 - 	 - 
//  pRequestorID				 - 	 - 
//  pHotelCode					 - 	 - 
//  pInteractionParameters		 - 	 - 
//  pPeriodFrom					 - 	 - 
//  pPeriodTo					 - 	 - 
//  pSyncAvailability			 - 	 - 
//  pSyncRoomRates				 - 	 - 
//  pSyncRestrictions			 - 	 - 
//  pGetVacantRoomsAtMidnight	 - 	 - 
// 
// Returns:
//  Structure - of arrays RoomInventory, RoomRates, RoomRestrictions, Reservations
//
Function SyncAllForPeriod(pUsername, pPassword, pHTTPHost, pResourceAddress, pRequestorID, pHotelCode, pInteractionParameters, pPeriodFrom, pPeriodTo, pSyncAvailability=true, pSyncRoomRates=true, pSyncRestrictions=true, pGetVacantRoomsAtMidnight=false) Export
	vResult = New Structure("RoomInventory, RoomRates, RoomRestrictions, Reservations", New Array, New Array, New Array, New Array);
	
	vLastSyncDate = CurrentSessionDate();
	
	#Region RoomInventory
	If pSyncAvailability Then
		vBalanceResult = Undefined;
		vRoomTypes = GetRoomTypesTable(pInteractionParameters.Hotel, pInteractionParameters.InteractionID);
		For Each vRoomTypeRow in vRoomTypes Do 
			If vBalanceResult = Undefined Then 
				vBalanceResult = GetBalances(pInteractionParameters.Hotel, pInteractionParameters.Allotment, pPeriodFrom, pPeriodTo, pInteractionParameters.InteractionID, vRoomTypeRow.RoomTypeRef, vRoomTypeRow.RoomTypeCode, pGetVacantRoomsAtMidnight);
			Else
				vBalance = GetBalances(pInteractionParameters.Hotel, pInteractionParameters.Allotment, pPeriodFrom, pPeriodTo, pInteractionParameters.InteractionID, vRoomTypeRow.RoomTypeRef, vRoomTypeRow.RoomTypeCode, pGetVacantRoomsAtMidnight);
				For Each vBalanceRow in vBalance Do
					vNewRow = vBalanceResult.Add();
					FillPropertyValues(vNewRow,vBalanceRow);
				EndDo;
			EndIf;
		EndDo;
		
		If vBalanceResult <> Undefined Then 
			vAvailability = New ValueTable;
			vAvailability.Columns.Add("RoomTypeCode");
			vAvailability.Columns.Add("RateCode");
			vAvailability.Columns.Add("Start");
			vAvailability.Columns.Add("End");
			vAvailability.Columns.Add("BookingLimit");
			
			For Each vBalanceResultRow in vBalanceResult Do
				vNewRow 				= vAvailability.Add();
				vNewRow.RoomTypeCode 	= vBalanceResultRow.RoomTypeCode;
				vNewRow.Start 			= vBalanceResultRow.PeriodFrom;
				vNewRow.End 			= vBalanceResultRow.PeriodTo;
				vNewRow.BookingLimit 	= vBalanceResultRow.VacantRooms;			
			EndDo;
			
			vDailyAvailability = New ValueTable;
			vDailyAvailability.Columns.Add("Hotel");
			vDailyAvailability.Columns.Add("RoomType");
			vDailyAvailability.Columns.Add("Period");
			vDailyAvailability.Columns.Add("RoomsVacant");
			vDailyAvailability.Columns.Add("BedsVacant");
			
			For Each vBalanceResultRow in vBalanceResult Do
				vCurrentDate = BegOfDay(vBalanceResultRow.PeriodFrom);
				While BegOfDay(vCurrentDate) <= BegOfDay(vBalanceResultRow.PeriodTo) Do
					vNewRow 			= vDailyAvailability.Add();
					vNewRow.Hotel		= pInteractionParameters.Hotel; 					
					vNewRow.RoomType 	= vBalanceResultRow.RoomType;
					vNewRow.Period 		= vCurrentDate;
					vNewRow.RoomsVacant = vBalanceResultRow.VacantRooms;
					vNewRow.BedsVacant 	= vBalanceResultRow.VacantBeds;
					
					vCurrentDate = vCurrentDate + 24*60*60;
				EndDo;
			EndDo;
			
			SendRequests("SetAvailability", vResult.RoomInventory, pUsername, pPassword, pHTTPHost, pResourceAddress, pRequestorID, pHotelCode, vAvailability, 499);
			WriteLog(pInteractionParameters, "SetAvailability", vResult.RoomInventory);
		EndIf;
	EndIf; // pSyncAvailability
	
	#EndRegion
	
	
	#Region RoomRate
	
	If pSyncRoomRates Then	
		vRatesResult 	= Undefined;
		vRoomRatesTable = GetRoomRatesTable(pInteractionParameters.Hotel, pInteractionParameters.InteractionID);
		vRoomTypes 		= GetRoomTypesTable(pInteractionParameters.Hotel, pInteractionParameters.InteractionID);
		For Each vRoomRateRow in vRoomRatesTable Do
			FillDailyPrices(pInteractionParameters, pInteractionParameters.Hotel, vRoomRateRow.RoomRateRef, Undefined, pPeriodFrom, pPeriodTo + 24*60*60);
		EndDo;
		
		For Each vRoomTypeRow in vRoomTypes Do
			vAccommodationsToSync = GetAllExternalRoomTypesCodes(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, vRoomTypeRow.RoomTypeRef);
			For Each vAccTemplate in vAccommodationsToSync Do 
				If vRatesResult = Undefined Then 
					vRatesResult = GetRates(pInteractionParameters.Hotel, pInteractionParameters, pPeriodFrom, pPeriodTo + 24*60*60, pInteractionParameters.InteractionID, vRoomTypeRow.RoomTypeRef, "Siteminder_RoomMapping_RT", vAccTemplate.ObjectExternalCode);
				Else
					vRates = GetRates(pInteractionParameters.Hotel, pInteractionParameters, pPeriodFrom, pPeriodTo + 24*60*60, pInteractionParameters.InteractionID, vRoomTypeRow.RoomTypeRef, "Siteminder_RoomMapping_RT", vAccTemplate.ObjectExternalCode);
					For Each vRateRow in vRates Do
						vNewRow = vRatesResult.Add();
						FillPropertyValues(vNewRow, vRateRow);
					EndDo;
				EndIf;
			EndDo;
		EndDo;
		
		If vRatesResult <> Undefined Then 
			vRoomRates = PrepareRatesTable(vRatesResult, pInteractionParameters.Hotel, pInteractionParameters.InteractionID);
			
			SendRequests("SetRoomRates", vResult.RoomRates, pUsername, pPassword, pHTTPHost, pResourceAddress, pRequestorID, pHotelCode, vRoomRates, 499);
			WriteLog(pInteractionParameters, "SetRoomRates", vResult.RoomRates);
		EndIf;	
	EndIf; // pSyncRoomRates

	#EndRegion
	
	#Region RoomRateRestrictions
	If pSyncRestrictions Then
		vSyncPeriod = (EndOfDay(pPeriodTo) - BegOfDay(pPeriodFrom))/(24*60*60);
		
		If vSyncPeriod > Int(vSyncPeriod) Then
			vSyncPeriod = Int(vSyncPeriod) + 1;	
		EndIf;
		
		vRestrictionsResult = GetRestrictionsTable(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, vSyncPeriod, pPeriodFrom);
		
		SendRequests("SetRestrictions", vResult.RoomRestrictions, pUsername, pPassword, pHTTPHost, pResourceAddress, pRequestorID, pHotelCode, vRestrictionsResult, 124);
		WriteLog(pInteractionParameters, "SetRestrictions", vResult.RoomRestrictions);
	EndIf; // pSyncRestrictions

	#EndRegion

	ChannelManagers.UpdateLastSyncTime(pInteractionParameters, True, vLastSyncDate, "", pSyncAvailability, pSyncRoomRates, pSyncRestrictions);
	
	Return vResult;
EndFunction // SyncAllForPeriod


#EndRegion
		 
#Region Private

// --------------------------------------------------------------------------------
Function ConfirmReservation(pUsername, pPassword, pHTTPHost, pResourceAddress, pRequestorID, pHotelCode, pReservations)
		
	vFilter = New Structure("Success", True);
	vSuccessTable = pReservations.Copy(vFilter);
	
	vSuccessResult = Undefined;
	vFailureResult = Undefined;
	
	If vSuccessTable.Count() > 0 Then
		vSuccessResult = GenerateConfirmRequest(pUsername, pPassword, pHTTPHost, pResourceAddress, pRequestorID, pHotelCode, vSuccessTable, True);
	EndIf;
	
	If vSuccessResult <> Undefined and vFailureResult <> Undefined Then
		
		vSuccessResult.RawAnswer = "Success reservations answer:" + Chars.LF + vSuccessResult.RawAnswer + "Failed reservations answer:" + Chars.LF + vFailureResult.RawAnswer;
		If NOT vSuccessResult.Success or NOT vFailureResult.Success Then
			vSuccessResult.Success = False;
		EndIf;
		For Each vErrorRow in vFailureResult.Errors Do
			vSuccessResult.Errors.Add(vErrorRow);
		EndDo;
		For Each vWarningRow in vFailureResult.Warnings Do
			vSuccessResult.Warnings.Add(vWarningRow);
		EndDo;
		Return vSuccessResult;
		
	ElsIf vSuccessResult <> Undefined Then
		
		Return vSuccessResult;
		
	ElsIf vFailureResult <> Undefined Then		
		
		Return vFailureResult;
		
	EndIf;

	Return Undefined;
EndFunction

// --------------------------------------------------------------------------------
Function GenerateConfirmRequest(pUsername, pPassword, pHTTPHost, pResourceAddress, pRequestorID, pHotelCode, pReservations, pSuccess)
	vSettings = GetSettings();
	
	If ValueIsFilled(pResourceAddress) Then
		vResourceAddress = pResourceAddress; 	
	Else
		vResourceAddress = vSettings.ResourceAddress;	
	EndIf;
	
	vXMLDocument = New XMLWriter;
	vXMLDocument.SetString();
	
	#Region Envelope
	vXMLDocument.WriteStartElement("soapenv:Envelope");
	vXMLDocument.WriteAttribute("xmlns:soapenv","http://schemas.xmlsoap.org/soap/envelope/");
	vXMLDocument.WriteAttribute("xmlns:wsse","http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd");
	vXMLDocument.WriteAttribute("xmlns:ns","http://www.opentravel.org/OTA/2003/05");
		#Region Header
		vXMLDocument.WriteStartElement("soapenv:Header");
			#Region Security 
			vXMLDocument.WriteStartElement("wsse:Security");
			//vXMLDocument.WriteAttribute("soap:mustUnderstand", "1");

				#Region UsernameToken
				vXMLDocument.WriteStartElement("wsse:UsernameToken");
				
					vXMLDocument.WriteStartElement("wsse:Username");
					vXMLDocument.WriteText(pUsername);
					vXMLDocument.WriteEndElement();
					
					vXMLDocument.WriteStartElement("wsse:Password");
					vXMLDocument.WriteAttribute("Type", "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText");
					vXMLDocument.WriteText(pPassword);
					vXMLDocument.WriteEndElement();
					
				vXMLDocument.WriteEndElement(); //UsernameToken
				#EndRegion
			vXMLDocument.WriteEndElement(); //Security
			#EndRegion
		vXMLDocument.WriteEndElement(); //Header
		#EndRegion
		#Region Body
		vXMLDocument.WriteStartElement("soapenv:Body");
			#Region OTA_ReadRQ
			vXMLDocument.WriteStartElement("ns:OTA_NotifReportRQ");
			vXMLDocument.WriteAttribute("TimeStamp", vSettings.TimeStamp);
			vXMLDocument.WriteAttribute("EchoToken", vSettings.EchoToken);
			vXMLDocument.WriteAttribute("Version", vSettings.Version);
			
			If pSuccess Then
				vXMLDocument.WriteStartElement("ns:Success");
				vXMLDocument.WriteEndElement(); //Success
			Else
				vXMLDocument.WriteStartElement("ns:Errors");
				For Each vReservationRow in pReservations Do
					For Each vErrorRow in vReservationRow.Errors Do
						vXMLDocument.WriteStartElement("ns:Error");
						vXMLDocument.WriteAttribute("Type", vErrorRow.Type);
						vXMLDocument.WriteAttribute("Code", vErrorRow.Code);
						vXMLDocument.WriteText(vErrorRow.DescriptionForConfirm);
						vXMLDocument.WriteEndElement(); //Errors
					EndDo;
				EndDo;
				vXMLDocument.WriteEndElement(); //Errors	
			EndIf;
				vXMLDocument.WriteStartElement("ns:NotifDetails");
					vXMLDocument.WriteStartElement("ns:HotelNotifReport");
						vXMLDocument.WriteStartElement("ns:HotelReservations");
							For Each vReservationRow in pReservations Do
								vXMLDocument.WriteStartElement("ns:HotelReservation");
								vXMLDocument.WriteAttribute("CreateDateTime", 			vReservationRow.CreateDateTime);
								vXMLDocument.WriteAttribute("ResStatus", 				vReservationRow.ResStatus);
									vXMLDocument.WriteStartElement("ns:UniqueID");
									vXMLDocument.WriteAttribute("Type", 				"16");
									vXMLDocument.WriteAttribute("ID", 					vReservationRow.ID);
									vXMLDocument.WriteEndElement(); //UniqueID
									
									If pSuccess Then
										vXMLDocument.WriteStartElement("ns:ResGlobalInfo");
											vXMLDocument.WriteStartElement("ns:HotelReservationIDs");
												vXMLDocument.WriteStartElement("ns:HotelReservationID");
												vXMLDocument.WriteAttribute("Type", 		"14");
												vXMLDocument.WriteAttribute("ResID_Type", 	vReservationRow.PMS_ID);
												vXMLDocument.WriteEndElement(); //HotelReservationIDs
											vXMLDocument.WriteEndElement(); //HotelReservationIDs
										vXMLDocument.WriteEndElement(); //ResGlobalInfo
									EndIf;
								vXMLDocument.WriteEndElement(); //HotelReservation
							EndDo;
						vXMLDocument.WriteEndElement(); //HotelReservations
					vXMLDocument.WriteEndElement(); //HotelNotifReport
				vXMLDocument.WriteEndElement(); //NotifDetails
								
			vXMLDocument.WriteEndElement(); //OTA_NotifReportRQ
			#EndRegion
		vXMLDocument.WriteEndElement(); //Body
		#EndRegion
	vXMLDocument.WriteEndElement(); //Envelope
	#EndRegion	
	
	vXMLRequest = vXMLDocument.Close();

	vXMLRequest	= ChannelManagers.FormatXMLString(vXMLRequest);
	
	vXMLResponse = ChannelManagers.SendQuery(vXMLRequest, pHTTPHost, vResourceAddress, "NotifReportRQ");
	vResult = ChannelManagers.CheckXMLAnswerForErrors(vXMLResponse);
	
	Return vResult;	
EndFunction

// --------------------------------------------------------------------------------
Function ReadReservationsXML(pXMLResponse)
	vXMLReader 	= New XMLReader;
	vXMLReader.SetString(pXMLResponse);
	
	vDomBuilder = New DOMBuilder;
	vDomDoc 	= vDomBuilder.Read(vXMLReader);
	
	vResult = New ValueTable;
	vResult.Columns.Add("ResStatus");
	vResult.Columns.Add("CreateDateTime");
	vResult.Columns.Add("BookingChannel");
	vResult.Columns.Add("BookingChannelCode");
	vResult.Columns.Add("UniqueID");
	vResult.Columns.Add("MessageUniqueID");
	vResult.Columns.Add("RoomStays");
	vResult.Columns.Add("Services");
	vResult.Columns.Add("ResGuests");
	vResult.Columns.Add("DepositPayments");
	vResult.Columns.Add("CardNumber");
	vResult.Columns.Add("CardHolderName");
	vResult.Columns.Add("CardExpireDate");
	vResult.Columns.Add("Guarantee");
	vResult.Columns.Add("ContactPerson_ResGuestRPH");
	vResult.Columns.Add("ContactPerson_GivenName");
	vResult.Columns.Add("ContactPerson_Surname");
	vResult.Columns.Add("ContactPerson_Telephone");
	vResult.Columns.Add("ContactPerson_Email");
	vResult.Columns.Add("ContactPerson_Address");
	vResult.Columns.Add("ContactPerson_CountryName");
	vResult.Columns.Add("ContactPerson_CompanyName");
	vResult.Columns.Add("Comments");
	
	vReservations = vDomDoc.GetElementByTagName("HotelReservation");
	
	For Each vReservationRow in vReservations Do
		vNewReservation 				= vResult.Add();
		vNewReservation.ResStatus		= GetAttributeNodeValue(vReservationRow,"ResStatus");
		vNewReservation.CreateDateTime	= GetAttributeNodeValue(vReservationRow,"CreateDateTime");
		
		#Region BookingChannel
		vBookingChannels = vReservationRow.GetElementByTagName("BookingChannel");
		For Each vBookingRow in vBookingChannels Do
			If GetAttributeNodeValue(vBookingRow,"Primary") = "true" Then
				vCompanyName 						= vBookingRow.GetElementByTagName("CompanyName");
				If vCompanyName.Count() > 0 Then 
					vNewReservation.BookingChannel 		= vCompanyName[0].TextContent;
					vNewReservation.BookingChannelCode 	= GetAttributeNodeValue(vCompanyName[0],"Code");
				EndIf;
			EndIf;
		EndDo;
		#EndRegion
		
		#Region UniqueID
		vUniqueIDs = vReservationRow.GetElementByTagName("UniqueID");
		For Each vUniqueIDRow in vUniqueIDs Do
			If vUniqueIDRow.ParentNode.NodeName <> "HotelReservation" Then
				// If it's not reservation ID skip it. It night be ProfileID
				Continue;
			EndIf;
			If GetAttributeNodeValue(vUniqueIDRow,"Type") = "14" Then
				vNewReservation.UniqueID 	= GetAttributeNodeValue(vUniqueIDRow,"ID");			
			EndIf;
			If GetAttributeNodeValue(vUniqueIDRow,"Type") = "16" Then
				vNewReservation.MessageUniqueID = GetAttributeNodeValue(vUniqueIDRow,"ID");			
			EndIf;
		EndDo;
		#EndRegion
		
		#Region RoomStays
		vResultRoomStays = New ValueTable;
		vResultRoomStays.Columns.Add("RoomType");
		vResultRoomStays.Columns.Add("RoomTypeCode");
		vResultRoomStays.Columns.Add("RatePlanCode");
		vResultRoomStays.Columns.Add("Rates");
		vResultRoomStays.Columns.Add("Adults");
		vResultRoomStays.Columns.Add("Children");
		vResultRoomStays.Columns.Add("Infants");
		vResultRoomStays.Columns.Add("StartDate");
		vResultRoomStays.Columns.Add("EndDate");
		vResultRoomStays.Columns.Add("TotalAmount");
		vResultRoomStays.Columns.Add("TotalCurrencyCode");
		vResultRoomStays.Columns.Add("ServiceRPH");
		vResultRoomStays.Columns.Add("ResGuestRPH");
		vResultRoomStays.Columns.Add("HotelCode");
		vResultRoomStays.Columns.Add("Comments");

		vRoomStays = vReservationRow.GetElementByTagName("RoomStay");
		For Each vRoomStayRow in vRoomStays Do
			vNewRoomStay = vResultRoomStays.Add();
			
			#Region RoomType
			vRoomType = vRoomStayRow.GetElementByTagName("RoomType");
			If vRoomType.Count() > 0 Then 
				vNewRoomStay.RoomType 		= GetAttributeNodeValue(vRoomType[0],"RoomType");
				vNewRoomStay.RoomTypeCode 	= GetAttributeNodeValue(vRoomType[0],"RoomTypeCode");	
			EndIf;
			#EndRegion
			
			#Region RatePlan
			vRatePlan = vRoomStayRow.GetElementByTagName("RatePlan");
			If vRatePlan.Count() > 0 Then 
				vNewRoomStay.RatePlanCode 	= GetAttributeNodeValue(vRatePlan[0],"RatePlanCode");
			EndIf;
			#EndRegion
			
			#Region Rates
			vResultRoomStaysRates = New ValueTable;
			vResultRoomStaysRates.Columns.Add("EffectiveDate");
			vResultRoomStaysRates.Columns.Add("ExpireDate");
			vResultRoomStaysRates.Columns.Add("AmountAfterTax");
			vResultRoomStaysRates.Columns.Add("CurrencyCode");
			
			vRates = vRoomStayRow.GetElementByTagName("Rate");
			For Each vRateRow in vRates Do
				vNewRate = vResultRoomStaysRates.Add();
				vNewRate.EffectiveDate 		= GetAttributeNodeValue(vRateRow,"EffectiveDate");
				vNewRate.ExpireDate 		= GetAttributeNodeValue(vRateRow,"ExpireDate");
				vRateTotal 					= vRateRow.GetElementByTagName("Total");
				If vRateTotal.Count() > 0 Then 
					vNewRate.AmountAfterTax = GetAttributeNodeValue(vRateTotal[0], "AmountAfterTax", True);
										
					If vNewRate.AmountAfterTax = Undefined or vNewRate.AmountAfterTax = 0 Then
						vNewRate.AmountAfterTax = GetAttributeNodeValue(vRateTotal[0],"AmountBeforeTax");
						vTaxes 					= vRateTotal[0].GetElementByTagName("Taxes");
						vTaxesAmount 			= 0;
						If vTaxes.Count() > 0 Then
							vTaxesAmount = GetAttributeNodeValue(vTaxes[0],"Amount", True); 
						EndIf;
						
						vNewRate.AmountAfterTax = Number(vNewRate.AmountAfterTax) + Number(vTaxesAmount);

					EndIf;
					vNewRate.CurrencyCode 	= GetAttributeNodeValue(vRateTotal[0],"CurrencyCode");
				EndIf;
			EndDo;
			
			vNewRoomStay.Rates = vResultRoomStaysRates; 
			#EndRegion
			
			#Region GuestCount
			vGuestCounts = vRoomStayRow.GetElementByTagName("GuestCount");
			For Each vGuestCountRow in vGuestCounts Do
				If 	GetAttributeNodeValue(vGuestCountRow,"AgeQualifyingCode") 	= "10" 	Then
					vNewRoomStay.Adults 	= GetAttributeNodeValue(vGuestCountRow,"Count");	
				ElsIf GetAttributeNodeValue(vGuestCountRow,"AgeQualifyingCode") = "8" 	Then
					vNewRoomStay.Children 	= GetAttributeNodeValue(vGuestCountRow,"Count");	
				ElsIf GetAttributeNodeValue(vGuestCountRow,"AgeQualifyingCode") = "7" 	Then
					vNewRoomStay.Infants 	= GetAttributeNodeValue(vGuestCountRow,"Count");	
				EndIf;
			EndDo;
			#EndRegion
			
			#Region Dates
			vDates = vRoomStayRow.GetElementByTagName("TimeSpan");
			For Each vDateRow in vDates Do
				If 	vDateRow.ParentNode.NodeName = "RoomStay"	Then
					vNewRoomStay.StartDate 	= GetAttributeNodeValue(vDateRow,"Start");
					vNewRoomStay.EndDate 	= GetAttributeNodeValue(vDateRow,"End");
				EndIf;
			EndDo;
			#EndRegion
			
			#Region Total
			vTotals = vRoomStayRow.GetElementByTagName("Total");
			For Each vTotalRow in vTotals Do
				If vTotalRow.ParentNode.NodeName <> Undefined and vTotalRow.ParentNode.NodeName = "RoomStay" Then
					vNewRoomStay.TotalAmount 		= GetAttributeNodeValue(vTotalRow,"AmountAfterTax", True);
					If vNewRoomStay.TotalAmount = 0 Then
						vNewRoomStay.TotalAmount 	= GetAttributeNodeValue(vTotalRow,"AmountBeforeTax", True);
						vTaxes 						= vTotalRow.GetElementByTagName("Taxes");
						vTaxesAmount 				= 0;
						If vTaxes.Count() > 0 Then
							vTaxesAmount = GetAttributeNodeValue(vTaxes[0],"Amount", True); 
						EndIf;

						vNewRoomStay.TotalAmount 	= vNewRoomStay.TotalAmount + vTaxesAmount;  
						
					EndIf;
					vNewRoomStay.TotalCurrencyCode 	= GetAttributeNodeValue(vTotalRow,"CurrencyCode");
				EndIf;
			EndDo;
			#EndRegion
			
			#Region ServiceRPH
			vServiceRPHs = vRoomStayRow.GetElementByTagName("ServiceRPH");
			If vServiceRPHs.Count() > 0 Then
				vNewRoomStay.ServiceRPH = GetAttributeNodeValue(vServiceRPHs[0],"RPH"); 	
			EndIf;
			#EndRegion
			
			#Region ResGuestRPH
			vResGuestRPHArray = New Array;
			vResGuestRPHs = vRoomStayRow.GetElementByTagName("ResGuestRPH");
			For Each vResGuestRPHRow in vResGuestRPHs Do
				vResGuestRPHArray.Add(GetAttributeNodeValue(vResGuestRPHRow,"RPH")); 	
			EndDo;
			vNewRoomStay.ResGuestRPH = vResGuestRPHArray; 
			#EndRegion
			
			#Region HotelCode
			vBasicPropertyInfo = vRoomStayRow.GetElementByTagName("BasicPropertyInfo");
			If vBasicPropertyInfo.Count() > 0 Then
				vNewRoomStay.HotelCode = GetAttributeNodeValue(vBasicPropertyInfo[0],"HotelCode"); 	
			EndIf;
			#EndRegion
			
		#Region CommentsRoomStays
		vCommentsBlock = vRoomStayRow.GetElementByTagName("Comments");
		For Each vCommentsBlockRow in vCommentsBlock Do 
			If vCommentsBlockRow.ParentNode.LocalName = "RoomStay" Then 
				vComments = vCommentsBlockRow.GetElementByTagName("Comment");
				For Each vCommentRow in vComments Do
					vCommentText = vCommentRow.GetElementByTagName("Text");
					If vCommentText.Count() > 0 Then
						vNewRoomStay.Comments 		= String(vNewRoomStay.Comments) + String(vCommentText[0].TextContent) + Chars.LF;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
		#EndRegion

		EndDo;
		
		vNewReservation.RoomStays = vResultRoomStays;
		
		#EndRegion		
		
		#Region Services
		vResultServices = New ValueTable;
		vResultServices.Columns.Add("ServiceInventoryCode");
		vResultServices.Columns.Add("ServiceRPH");
		vResultServices.Columns.Add("AmountAfterTax");
		vResultServices.Columns.Add("CurrencyCode");
		vResultServices.Columns.Add("Description");
		vResultServices.Columns.Add("Quantity");
		
		vServices = vReservationRow.GetElementByTagName("Service");
		For Each vServiceRow in vServices Do
			vNewService = vResultServices.Add();
			vNewService.ServiceInventoryCode 	= GetAttributeNodeValue(vServiceRow,"ServiceInventoryCode");
			vNewService.ServiceRPH 				= GetAttributeNodeValue(vServiceRow,"ServiceRPH");
			vNewService.Quantity 				= GetAttributeNodeValue(vServiceRow,"Quantity");
			vTotal = vServiceRow.GetElementByTagName("Total");
			If vTotal.Count() > 0 Then
				vNewService.AmountAfterTax 	= GetAttributeNodeValue(vTotal[0],"AmountAfterTax", True);
				vNewService.CurrencyCode 	= GetAttributeNodeValue(vTotal[0],"CurrencyCode"); 
				If vNewService.AmountAfterTax = 0 Then
					vNewService.AmountAfterTax 	= GetAttributeNodeValue(vTotalRow,"AmountBeforeTax", True);
					vTaxes 						= vTotalRow.GetElementByTagName("Taxes");
					vTaxesAmount 				= 0;
					If vTaxes.Count() > 0 Then
						vTaxesAmount = GetAttributeNodeValue(vTaxes[0],"Amount", True); 
					EndIf;
					
					vNewService.AmountAfterTax 	= vNewService.AmountAfterTax + vTaxesAmount;  
					
				EndIf;
			EndIf;
			vDescription = vServiceRow.GetElementByTagName("Text");
			If vDescription.Count() > 0 Then
				vNewService.Description 	= vDescription[0].TextContent;	
			EndIf;
		EndDo;
		
		vNewReservation.Services = vResultServices;
		
		#EndRegion
		
		#Region ResGuests
		vResultResGuests = New ValueTable;
		vResultResGuests.Columns.Add("ResGuestRPH");
		vResultResGuests.Columns.Add("Primary");
		vResultResGuests.Columns.Add("GivenName");
		vResultResGuests.Columns.Add("Surname");
		vResultResGuests.Columns.Add("Telephone");
		vResultResGuests.Columns.Add("Email");
		vResultResGuests.Columns.Add("Address");
		vResultResGuests.Columns.Add("CountryName");
		vResultResGuests.Columns.Add("CompanyName");
		
		vResGuests = vReservationRow.GetElementByTagName("ResGuest");
		For Each vResGuest in vResGuests Do
			vNewGuest = vResultResGuests.Add();
			
			If GetAttributeNodeValue(vResGuest,"PrimaryIndicator") = "true" Then
				vNewGuest.Primary = True;
				
				vNewReservation.ContactPerson_ResGuestRPH = GetAttributeNodeValue(vResGuest,"ResGuestRPH");
				
				vGivenName 	= vResGuest.GetElementByTagName("GivenName");
				If vGivenName.Count() > 0 Then
					vNewReservation.ContactPerson_GivenName = vGivenName[0].TextContent;	
				EndIf;
				
				vSurname 	= vResGuest.GetElementByTagName("Surname");
				If vSurname.Count() > 0 Then
					vNewReservation.ContactPerson_Surname = vSurname[0].TextContent;	
				EndIf;
				
				vTelephone 	= vResGuest.GetElementByTagName("Telephone");
				If vTelephone.Count() > 0 Then
					vNewReservation.ContactPerson_Telephone = GetAttributeNodeValue(vTelephone[0],"PhoneNumber");	
				EndIf;
				
				vEmail 		= vResGuest.GetElementByTagName("Email");
				If vEmail.Count() > 0 Then
					vNewReservation.ContactPerson_Email = vEmail[0].TextContent;	
				EndIf;
				
				vAddress 	= vResGuest.GetElementByTagName("Address");
				If vAddress.Count() > 0 Then
					vCountryName 			= "";
					vPostalCode 			= "";
					vCityName 				= "";
					vAdditionalAdressInfo 	= "";
					vCompanyName			= "";
					For Each vAdressChildRow in vAddress[0].ChildNodes Do
						If vAdressChildRow.NodeName = "CountryName" Then
							vCountryName = vAdressChildRow.TextContent;
						ElsIf vAdressChildRow.NodeName = "PostalCode" Then
							vPostalCode = vAdressChildRow.TextContent;
						ElsIf vAdressChildRow.NodeName = "CityName" Then
							vCityName = vAdressChildRow.TextContent;
						ElsIf vAdressChildRow.NodeName = "CompanyName" Then
							vCompanyName = vAdressChildRow.TextContent; 
						Else
							If ValueIsFilled(vAdditionalAdressInfo) Then
								vAdditionalAdressInfo = vAdditionalAdressInfo + ", " + vAdressChildRow.TextContent;
							Else
								vAdditionalAdressInfo = vAdressChildRow.TextContent;
							EndIf;
						EndIf; 
					EndDo;
					vResGuestsInfoArray = New Array;
					vResGuestsInfoArray.Add(vCountryName);
					vResGuestsInfoArray.Add(vPostalCode);
					vResGuestsInfoArray.Add(vCityName);
					vResGuestsInfoArray.Add(vAdditionalAdressInfo);
					
					vNewReservation.ContactPerson_CountryName 	= vCountryName;
					vNewReservation.ContactPerson_Address 		= ArrayOfStringsToString(vResGuestsInfoArray, ", ");
					vNewReservation.ContactPerson_CompanyName 	= vCompanyName;
				EndIf;
			Else
				vNewGuest.Primary = False;	
			EndIf;	
			//Else
				
				
				
				vNewGuest.ResGuestRPH = GetAttributeNodeValue(vResGuest,"ResGuestRPH");
				
				vGivenName 	= vResGuest.GetElementByTagName("GivenName");
				If vGivenName.Count() > 0 Then
					vNewGuest.GivenName = vGivenName[0].TextContent;	
				EndIf;
				
				vSurname 	= vResGuest.GetElementByTagName("Surname");
				If vSurname.Count() > 0 Then
					vNewGuest.Surname = vSurname[0].TextContent;	
				EndIf;
				
				vTelephone 	= vResGuest.GetElementByTagName("Telephone");
				If vTelephone.Count() > 0 Then
					vNewGuest.Telephone = GetAttributeNodeValue(vTelephone[0],"PhoneNumber");	
				EndIf;
				
				vEmail 		= vResGuest.GetElementByTagName("Email");
				If vEmail.Count() > 0 Then
					vNewGuest.Email = vEmail[0].TextContent;	
				EndIf;
				
				vAddress 	= vResGuest.GetElementByTagName("Address");
				If vAddress.Count() > 0 Then
					vCountryName 			= "";
					vPostalCode 			= "";
					vCityName 				= "";
					vAdditionalAdressInfo 	= "";
					vAddressString 			= "";
					vCompanyName			= "";
					For Each vAdressChildRow in vAddress[0].ChildNodes Do
						If vAdressChildRow.NodeName = "CountryName" Then
							vCountryName = vAdressChildRow.TextContent;
						ElsIf vAdressChildRow.NodeName = "PostalCode" Then
							vPostalCode = vAdressChildRow.TextContent;
						ElsIf vAdressChildRow.NodeName = "CityName" Then
							vCityName = vAdressChildRow.TextContent;
						ElsIf vAdressChildRow.NodeName = "CompanyName" Then
							vCompanyName = vAdressChildRow.TextContent; 
						Else
							If ValueIsFilled(vAdditionalAdressInfo) Then
								vAdditionalAdressInfo = vAdditionalAdressInfo + ", " + vAdressChildRow.TextContent;
							Else
								vAdditionalAdressInfo = vAdressChildRow.TextContent;
							EndIf;
						EndIf; 
					EndDo;
					
					vResGuestsInfoArray = New Array;
					vResGuestsInfoArray.Add(vCountryName);
					vResGuestsInfoArray.Add(vPostalCode);
					vResGuestsInfoArray.Add(vCityName);
					vResGuestsInfoArray.Add(vAdditionalAdressInfo);
					
					vNewGuest.CountryName 	= vCountryName;
					vNewGuest.Address 		= ArrayOfStringsToString(vResGuestsInfoArray, ", ");
					vNewGuest.CompanyName 	= vCompanyName;
				EndIf;
			//EndIf;

		EndDo;
		
		vResultResGuests.Sort("Primary DESC");
		
		vNewReservation.ResGuests = vResultResGuests;
		
		#EndRegion
		
		#Region DepositPayments
		vResultDepositPayments = New ValueTable;
		vResultDepositPayments.Columns.Add("Amount");
		vResultDepositPayments.Columns.Add("Percent");
		vResultDepositPayments.Columns.Add("CurrencyCode");
		vResultDepositPayments.Columns.Add("TaxInclusive");
		vDepositPayments 	= vReservationRow.GetElementByTagName("DepositPayments");
		For Each vDepositPaymentsRow in vDepositPayments Do
			vAmountPercents 	= vDepositPaymentsRow.GetElementByTagName("AmountPercent");
			For Each vAmountPercentRow in vAmountPercents Do
				NewDepositPayment 				= vResultDepositPayments.Add();
				NewDepositPayment.Amount 		= GetAttributeNodeValue(vAmountPercentRow,"Amount", True);
				NewDepositPayment.Percent 		= GetAttributeNodeValue(vAmountPercentRow,"Percent", True);
				NewDepositPayment.CurrencyCode 	= GetAttributeNodeValue(vAmountPercentRow,"CurrencyCode");
				NewDepositPayment.TaxInclusive 	= GetAttributeNodeValue(vAmountPercentRow,"TaxInclusive");
				
				If NewDepositPayment.Amount = 0 and NewDepositPayment.Percent <> 0 Then
					vTotalSumm = 0;
					For Each vRoomStayRow in vNewReservation.RoomStays Do
						vTotalSumm = vTotalSumm + vRoomStayRow.TotalAmount;  
					EndDo;
					NewDepositPayment.Amount = vTotalSumm * (NewDepositPayment.Percent/100); 
				EndIf;
			EndDo;
		EndDo;
		
		vNewReservation.DepositPayments = vResultDepositPayments;
		#EndRegion
		
		#Region PaymentCard_Guarantee
		vPaymentCards = vReservationRow.GetElementByTagName("PaymentCard");
		If vPaymentCards.Count() > 0 Then
			vNewReservation.CardNumber 		= GetAttributeNodeValue(vPaymentCards[0],"CardNumber");
			vNewReservation.CardExpireDate 	= GetAttributeNodeValue(vPaymentCards[0],"ExpireDate");
			
			vCardHolderName = vPaymentCards[0].GetElementByTagName("CardHolderName");
			If vCardHolderName.Count() > 0 Then
				vNewReservation.CardHolderName 	= vCardHolderName[0].TextContent;	
			EndIf;
		EndIf;
		
		If ValueIsFilled(vNewReservation.CardNumber) Then
			vNewReservation.Guarantee = "Credit card";	
		Else
			vGuaranteeDescription = vReservationRow.GetElementByTagName("GuaranteeDescription");
			If vGuaranteeDescription.Count() > 0 Then
				vGuaranteeDescriptionText = vReservationRow.GetElementByTagName("Text");
				If vGuaranteeDescriptionText.Count() > 0 Then
					vNewReservation.Guarantee = vGuaranteeDescriptionText[0].TextContent;
				EndIf;
			EndIf;	
		EndIf;
		
		#EndRegion
		
		#Region CommentsGlobal
		vCommentsBlock = vReservationRow.GetElementByTagName("Comments");
		For Each vCommentsBlockRow in vCommentsBlock Do 
			If vCommentsBlockRow.ParentNode.LocalName = "ResGlobalInfo" Then 
				vComments = vCommentsBlockRow.GetElementByTagName("Comment");
				For Each vCommentRow in vComments Do
					vCommentText = vCommentRow.GetElementByTagName("Text");
					If vCommentText.Count() > 0 Then
						vNewReservation.Comments 		= String(vNewReservation.Comments) + String(vCommentText[0].TextContent) + Chars.LF;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
		#EndRegion
	EndDo;
	
	Return vResult; 
EndFunction

// --------------------------------------------------------------------------------
Function GetAttributeNodeValue(pNode, pAttributeName, pNumber = False)
	vTempAttribute = pNode.Attributes.GetNamedItem(pAttributeName);
	If vTempAttribute <> Undefined Then
		If pNumber Then
			Try
				vResult = Number(vTempAttribute.NodeValue);
				Return vResult;
			Except
				Return 0;
			EndTry;
		Else
			Return vTempAttribute.NodeValue;	
		EndIf;
	Else
		If pNumber Then
			Return 0;
		Else
			Return Undefined;
		EndIf;
	EndIf;
EndFunction

// --------------------------------------------------------------------------------
Function GetObjectRefBySiteminderCode(pHotel, pInteractionID, pObjectName, pObjectCode)
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	ExternalSystemsObjectCodesMappings.ObjectTypeName AS ObjectTypeName,
	|	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode,
	|	ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef
	|FROM
	|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
	|WHERE
	|	ExternalSystemsObjectCodesMappings.Hotel = &qHotel
	|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
	|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = &qObjectTypeName
	|	AND ExternalSystemsObjectCodesMappings.ObjectExternalCode = &qObjectExternalCode";
	
	vQuery.SetParameter("qExternalSystemCode", pInteractionID);
	vQuery.SetParameter("qHotel", pHotel);
	vQuery.SetParameter("qObjectTypeName", pObjectName);
	vQuery.SetParameter("qObjectExternalCode", pObjectCode);
	
	vQueryResult = vQuery.Execute().Unload();
	
	If vQueryResult.Count() > 0 Then
		Return vQueryResult[0].ObjectRef;
	EndIf;
	
	Return Undefined;	
EndFunction

// --------------------------------------------------------------------------------
Function LoadReservations(pReservations, pInteractionParameters, pGetPrices, pDefaultAccomondationType)
	
	vResult = New ValueTable;
	vResult.Columns.Add("ID");
	vResult.Columns.Add("PMS_ID");
	vResult.Columns.Add("Success");
	vResult.Columns.Add("Errors");
	vResult.Columns.Add("CreateDateTime");
	vResult.Columns.Add("ResStatus");

	vDefaultLanguageCode = Undefined;
	If ValueIsFilled(pInteractionParameters.Hotel) And ValueIsFilled(pInteractionParameters.Hotel.Language) Then
		vDefaultLanguageCode = Upper(TrimAll(pInteractionParameters.Hotel.Language.Code));
	EndIf;
	
	For Each vReservationRow in pReservations Do
		vErrors							= New ValueTable;
		vErrors.Columns.Add("Type");
		vErrors.Columns.Add("Code");
		vErrors.Columns.Add("DescriptionForConfirm");		
		vErrors.Columns.Add("Description");
		
		vSuccess						= True;
		vNewReservation 				= vResult.Add();
		vNewReservation.ID				= vReservationRow.MessageUniqueID;
		vNewReservation.CreateDateTime	= vReservationRow.CreateDateTime;
		vNewReservation.ResStatus		= vReservationRow.ResStatus;
		vExternalGroupReservation 		= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalGroupReservation"));
		
		vAgent = vReservationRow.BookingChannelCode;

		vCurrency = Undefined;
		
		#Region CreditCard
		If ValueIsFilled(vReservationRow.CardNumber) AND Not IsBlankString(vReservationRow.CardNumber) AND  vReservationRow.CardNumber <> "*" Then 
			vCreditCard 					= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "CreditCard"));
			vCreditCard.CardNumber 			= vReservationRow.CardNumber;
			vCreditCard.CardHolder 			= vReservationRow.CardHolderName;
			
			vMonth 			= Left(vReservationRow.CardExpireDate,2);
			vYear 			= Right(vReservationRow.CardExpireDate,2);
			try
			vCardExpireDate = "20" + vYear + "-" + vMonth + "-" + Day(EndOfMonth("20" + vYear + vMonth + "01"));    
			vCreditCard.CardValidTillDate 	= vCardExpireDate;
			vExternalGroupReservation.CreditCardData = vCreditCard;
			except
			// Sometimes in the date may be * or somthing else but not a date. in that case just ignore card data
			endtry;			
			
		EndIf;
		#EndRegion
		
		#Region Main_Guest		
		If ValueIsFilled(vReservationRow.ContactPerson_GivenName) Then 
			vMainGuest 					= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
			vMainGuest.ClientFirstName 	= vReservationRow.ContactPerson_GivenName;
			vMainGuest.ClientLastName 	= vReservationRow.ContactPerson_Surname;
			vMainGuest.ClientPhone 		= vReservationRow.ContactPerson_Telephone;
			vMainGuest.ClientEMail 		= vReservationRow.ContactPerson_Email;
			vMainGuest.Address 			= vReservationRow.ContactPerson_Address;
			vMainGuest.ClientCitizenship = vReservationRow.ContactPerson_CountryName;
		Else
			vMainGuest = Undefined;
		EndIf;
		#EndRegion
		
		#Region Services
		vChargeExtraService = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "ChargeExtraServices"));
		For Each vServiceRow in vReservationRow.Services Do
			If vServiceRow.ServiceRPH = Undefined Then
				// The absence of a ServiceRPH indicates that this is a HotelReservation level charge
				// stay levek services are loded later on stay level
				vChargeExtraServiceRow 				= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "ChargeExtraServiceRow"));
				If CheckServiceByCode(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, vServiceRow.ServiceInventoryCode) Then
					vChargeExtraServiceRow.Service 		= vServiceRow.ServiceInventoryCode;
				Else
					vChargeExtraServiceRow.Service 		= "OTHER";
				EndIf;
				vChargeExtraServiceRow.Price 		= vServiceRow.AmountAfterTax;
				vChargeExtraServiceRow.Quantity 	= vServiceRow.Quantity;
				vChargeExtraServiceRow.Currency 	= vServiceRow.CurrencyCode;
				vChargeExtraServiceRow.Remarks 		= vServiceRow.Description;
				vChargeExtraService.ChargeExtraServiceRow.Add(vChargeExtraServiceRow);
			EndIf;
		EndDo;
		vExternalGroupReservation.ChargeExtraServices = vChargeExtraService;
		#EndRegion
		
		#Region RoomStays
		vRoomStayIndex = 1;
		For Each vRoomStayRow in vReservationRow.RoomStays Do
			
			vPriceWas 	= False;
			vServiceWas = False;
			
			vFormattedCode = "<Inv>" + vRoomStayRow.RoomTypeCode + "</Inv><Rate>" + vRoomStayRow.RatePlanCode + "</Rate>"; 
			
			#Region Accomondation_type
			vAgeArray = New Array;
			If vRoomStayRow.Children = Undefined Then
				vRoomStayRow.Children = 0;
			EndIf;
			If vRoomStayRow.Infants = Undefined Then
				vRoomStayRow.Infants = 0;
			EndIf;
			For i = 1 to Number(vRoomStayRow.Children) Do
				vAgeArray.Add(pInteractionParameters.Hotel.ChildrenMaxAge);
			EndDo;
			For i = 1 to Number(vRoomStayRow.Infants) Do
				vAgeArray.Add(pInteractionParameters.Hotel.InfantsMaxAge);
			EndDo;
			
			vRoomTypeRef 		= GetObjectRefBySiteminderCode(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, "Siteminder_RoomMapping_RT", vFormattedCode); //cmGetObjectRefByExternalSystemCode(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, "Siteminder_RoomMapping_RT", vFormattedCode);
			If NOT ValueIsFilled(vRoomTypeRef) Then
				vError 				= vErrors.Add();
				vError.Type 			= "3";
				vError.Code 			= "783";
				vError.DescriptionForConfirm = "Room or rate not found";
				vError.Description 		= "en = 'Mapping not found for the room type code:'; de = 'Zuordnung für den Zimmertypcode nicht gefunden:'; ru = 'Не найдено соответсвие типу номера с кодом: '" + vFormattedCode; //#Translate

				vSuccess			= False;
			EndIf;
			
			// Seearch template by ages
			vAccomodationTemplateList = cmGetAccommodationTemplateDetailsByGuestsQuantity(Number(vRoomStayRow.Adults), Number(vRoomStayRow.Children) + Number(vRoomStayRow.Infants), vAgeArray, pInteractionParameters.Hotel);
			// Filter Templates by roomType
			vClearArray = New Array;
			For Each vTemplateRow in vAccomodationTemplateList Do
				If vTemplateRow.AccommodationTemplate.RoomTypes.Count() > 0 Then
					If vTemplateRow.AccommodationTemplate.RoomTypes.Find(vRoomTypeRef, "RoomType") = Undefined Then
						If ValueIsFilled(vRoomTypeRef) And Not vRoomTypeRef.IsFolder And ValueIsFilled(vRoomTypeRef.RoomClass) And vTemplateRow.AccommodationTemplate.RoomTypes.Find(vRoomTypeRef.RoomClass, "RoomClass") <> Undefined Then
							Continue;
						Else
							vClearArray.Add(vTemplateRow);
						EndIf;
					EndIf;
				EndIf;
			EndDo;
			
			For Each vClearRow in vClearArray Do
				vAccomodationTemplateList.Delete(vClearRow);
			EndDo;
			
			vAccomondationType 		= Undefined;
			If vAccomodationTemplateList = Undefined OR vAccomodationTemplateList.Count() = 0 Then
				vAccomondationTemplate 	= GetObjectRefBySiteminderCode(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, "Siteminder_RoomMapping_AT", vFormattedCode); 
			Else
				vAccomondationTemplate 	= vAccomodationTemplateList[0].AccommodationTemplate;	
			EndIf;
			
			vRoomCode = "";
			If NOT ValueIsFilled(vAccomondationTemplate) Then
				vError 					= vErrors.Add();
				vError.Type 			= "3";
				vError.Code 			= "450";
				vError.DescriptionForConfirm 	= "Unable to process";
				vError.Description 		= "en = 'Accommodation template not found'; de = 'Unterkunft-Vorlage nicht gefunden'; ru = 'Не найден шаблон размещения'";
				vSuccess				= False;
			Else
				vRoomCode = String(New UUID());
				vAccomondationType = New ValueTable;
				vAccomondationType.Columns.Add("AccommodationType");
				For Each vRow in vAccomondationTemplate.AccommodationTypes Do
					vNewRow = vAccomondationType.Add();
					vNewRow.AccommodationType = vRow.AccommodationType;
				EndDo;
			EndIf;	
			
			If NOT ValueIsFilled(vAccomondationType) Then
				vError 					= vErrors.Add();
				vError.Type 			= "3";
				vError.Code 			= "450";
				vError.DescriptionForConfirm 	= "Unable to process";
				vError.Description 		= "ru = 'Не найден тип размещения'"; //#Translate
				vSuccess				= False;
			EndIf;
			
			#EndRegion
			
			#Region CheckInOut_Time
			If vSuccess Then 
				vRoomRateRef = GetObjectRefBySiteminderCode(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, "Siteminder_RoomMapping_RR", vFormattedCode); //cmGetObjectRefByExternalSystemCode(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, "Siteminder_RoomMapping_RR", vFormattedCode);
				If Not ValueIsFilled(vRoomRateRef) Then
					vError 				= vErrors.Add();
					vError.Type 			= "3";
					vError.Code 			= "783";
					vError.DescriptionForConfirm 	= "Room or rate not found";
					vError.Description 		= "ru = 'Не найдено соответсвие тарифа с кодом: '" + vFormattedCode; //#Translate

					vSuccess			= False;
				Else
					vCheckOutTime = vRoomRateRef.ReferenceHour;
					vCheckInTime = vRoomRateRef.DefaultCheckInTime;	
				EndIf;
				
				If Not ValueIsFilled(vCheckInTime) Then
					vCheckInTime = vCheckOutTime;
				EndIf;
			EndIf;
			#EndRegion
			
			#Region Guests			
			If vSuccess Then
				vGuestsCount = Number(vRoomStayRow.Adults) + Number(vRoomStayRow.Children) + Number(vRoomStayRow.Infants);
				If vAccomondationType.Count() < vGuestsCount Then
					While vAccomondationType.Count() < vGuestsCount Do
						vNewRow = vAccomondationType.Add();
						vNewRow.AccommodationType = pDefaultAccomondationType;
					EndDo;
				EndIf;
				
				If vSuccess Then
					For vGuestsIndex = 1 To vGuestsCount Do
						
						#Region MainInfo
						vExternalGroupReservationRow 					= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/","WriteExternalGroupReservationRow"));
						vExternalGroupReservationRow.ReservationCode 	= vReservationRow.UniqueID + "/" + String(vRoomStayIndex) + "/" + String(vGuestsIndex);
						vExternalGroupReservationRow.GroupCode 			= vReservationRow.UniqueID;
						vExternalGroupReservationRow.Agent 				= vAgent;
						If vMainGuest <> Undefined Then 
							vExternalGroupReservationRow.GroupClient 	= vMainGuest;
						EndIf;
						vExternalGroupReservationRow.ReservationStatus	= vReservationRow.ResStatus;
						vExternalGroupReservationRow.PeriodFrom			= Date(StrReplace(vRoomStayRow.StartDate,"-","")) + (vCheckInTime - BegOfDay(vCheckInTime));
						vExternalGroupReservationRow.PeriodTo			= Date(StrReplace(vRoomStayRow.EndDate,"-","")) + (vCheckOutTime - BegOfDay(vCheckOutTime));
						vExternalGroupReservationRow.Hotel				= vRoomStayRow.HotelCode;
						vExternalGroupReservationRow.RoomType			= TrimAll(vRoomTypeRef.Code);
						vExternalGroupReservationRow.Room				= vRoomCode;
						vExternalGroupReservationRow.AccommodationType	= TrimAll(vAccomondationType[vGuestsIndex-1].AccommodationType.Code);
						vExternalGroupReservationRow.NumberOfRooms		= 1;
						vExternalGroupReservationRow.NumberOfPersons	= 1;
						vExternalGroupReservationRow.ExternalSystemCode	= pInteractionParameters.InteractionID;
						vExternalGroupReservationRow.DoPosting			= True;
						vExternalGroupReservationRow.GuaranteeType		= vReservationRow.Guarantee;
						vExternalGroupReservationRow.RoomRate			= TrimAll(vRoomRateRef.Code);
						vExternalGroupReservationRow.ReservationRemarks = String(vReservationRow.Comments) + Chars.LF + String(vRoomStayRow.Comments); 
						If ValueIsFilled(vReservationRow.ContactPerson_CompanyName) Then
							vExternalGroupReservationRow.Customer           = vReservationRow.ContactPerson_CompanyName;
						EndIf;
						#EndRegion
						
						#Region GuestInfo
						vGuest 			= Undefined;
						vTempDeleteRow 	= Undefined;
						For Each vGuestsRow in vReservationRow.ResGuests Do
							If vRoomStayRow.ResGuestRPH.Count() > 0 Then 
								For Each vResGuestRPH in vRoomStayRow.ResGuestRPH Do 
									If vResGuestRPH = vGuestsRow.ResGuestRPH or NOT ValueIsFilled(vRoomStayRow.ResGuestRPH) Then  
										vGuest 					= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
										vGuest.ClientFirstName 	= vGuestsRow.GivenName;
										vGuest.ClientLastName 	= vGuestsRow.Surname;
										vGuest.ClientPhone 		= vGuestsRow.Telephone;
										vGuest.ClientEMail 		= vGuestsRow.Email;
										vGuest.Address 			= vGuestsRow.Address;
										vGuest.ClientCitizenship = vGuestsRow.CountryName;
										vTempDeleteRow 			= vGuestsRow; 
										Break;
									EndIf;
								EndDo;
								If vTempDeleteRow <> Undefined Then
									Break;
								EndIf;
							Else
								vGuest 					= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
								vGuest.ClientFirstName 	= vGuestsRow.GivenName;
								vGuest.ClientLastName 	= vGuestsRow.Surname;
								vGuest.ClientPhone 		= vGuestsRow.Telephone;
								vGuest.ClientEMail 		= vGuestsRow.Email;
								vGuest.Address 			= vGuestsRow.Address;
								vTempDeleteRow 			= vGuestsRow; 
								Break;							
							EndIf;
						EndDo;
						
						If vTempDeleteRow <> Undefined Then
							vReservationRow.ResGuests.Delete(vTempDeleteRow);
							vTempDeleteRow = Undefined;
						EndIf;
						
						If vGuest <> Undefined Then 
							vExternalGroupReservationRow.Client	= vGuest;
						Else
							vExternalGroupReservationRow.Client	= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
						EndIf;
						
						vClientInfoArray = New Array;
						vClientInfoArray.Add(vReservationRow.ContactPerson_GivenName);
						vClientInfoArray.Add(vReservationRow.ContactPerson_Surname);
						vClientInfoArray.Add(vReservationRow.ContactPerson_Telephone);
						vClientInfoArray.Add(vReservationRow.ContactPerson_Email);
						vClientInfoArray.Add(vReservationRow.ContactPerson_Address);
						vExternalGroupReservationRow.ContactPerson 	= ArrayOfStringsToString(vClientInfoArray, ", ");
						#EndRegion
						
						#Region RoomStay_Services
						If vRoomStayRow.ServiceRPH <> Undefined Then
							vChargeExtraService = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "ChargeExtraServices"));
							For Each vServiceRow in vReservationRow.Services Do
								If vRoomStayRow.ServiceRPH = vServiceRow.ServiceRPH and Not vServiceWas Then
									vChargeExtraServiceRow 				= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "ChargeExtraServiceRow"));
									If CheckServiceByCode(pInteractionParameters.Hotel, pInteractionParameters.InteractionID, vServiceRow.ServiceInventoryCode) Then
										vChargeExtraServiceRow.Service 		= vServiceRow.ServiceInventoryCode;
									Else
										vChargeExtraServiceRow.Service 		= "OTHER";
									EndIf;
									vChargeExtraServiceRow.Price 		= ?(vServiceRow.AmountAfterTax=Undefined,0,vServiceRow.AmountAfterTax);
									If vServiceRow.Quantity = Undefined Then
										vServiceRow.Quantity = 1;
									EndIf;
									vChargeExtraServiceRow.Quantity 	= vServiceRow.Quantity;
									vChargeExtraServiceRow.Currency 	= vServiceRow.CurrencyCode;
									vChargeExtraServiceRow.Remarks 		= vServiceRow.Description;
									vChargeExtraServiceRow.ChargeDate 	= vRoomStayRow.StartDate;
									vChargeExtraService.ChargeExtraServiceRow.Add(vChargeExtraServiceRow);
								EndIf;
								
								If NOT ValueIsFilled(vCurrency) Then
									vCurrency = vServiceRow.CurrencyCode;
								EndIf;
								
							EndDo;
							vServiceWas = True;
							vExternalGroupReservationRow.ChargeExtraServices	= vChargeExtraService;
						EndIf;
						#EndRegion
						
						#Region Prices
						vPriceActuallyWas	= vPriceWas;
						vPrices = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "PricesPerDate"));
						If pGetPrices Then
							For Each vPriceRow in vRoomStayRow.Rates Do
								vStartDate 		= Date(StrReplace(vPriceRow.EffectiveDate,"-",""));
								vEndDate 		= Date(StrReplace(vPriceRow.ExpireDate,"-",""));
								If not vPriceWas Then
									vPriceAmount		= vPriceRow.AmountAfterTax;
									vPriceActuallyWas	= True;
								Else
									vPriceAmount = 0;
								EndIf;
								vPricesPerDay 	= GetRatesPerDay(vStartDate, vEndDate, vPriceAmount, vPriceRow.CurrencyCode);
								
								If NOT ValueIsFilled(vCurrency) Then
									vCurrency = vPriceRow.CurrencyCode;
								EndIf;
								
								For Each vDayRow in vPricesPerDay Do
									vPricePerDateRow 			= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "PricePerDateRow"));
									vPricePerDateRow.Date 		= vDayRow.Date;
									vPricePerDateRow.Price 		= Number(vDayRow.AmountAfterTax);
									vPricePerDateRow.Currency 	= vDayRow.CurrencyCode;
									vPrices.PricePerDateRow.Add(vPricePerDateRow);
								EndDo;
							EndDo;
						EndIf;
						vPriceWas = vPriceActuallyWas; 
						vExternalGroupReservationRow.PricesPerDate	= vPrices;
						#EndRegion
						
						
						vExternalGroupReservation.WriteExternalGroupReservationRow.Add(vExternalGroupReservationRow);
					EndDo;
				EndIf;
			EndIf;
			#EndRegion
			vRoomStayIndex = vRoomStayIndex + 1;
		EndDo;
		#EndRegion
		
		If vSuccess Then
			vAnswerXDTO = cmWriteExternalGroupReservation(vExternalGroupReservation, vDefaultLanguageCode, True);
			If ValueIsFilled(vAnswerXDTO.ErrorDescription) Then
				vError 				= vErrors.Add();
				vError.Type 		= "3";
				vError.Code 		= "448";
				vError.DescriptionForConfirm 	= "System error";
				vError.Description 		= "ru = 'Неудалось создать бронь по причине: '" + vAnswerXDTO.ErrorDescription; //#Translate
				vSuccess			= False;	
			Else
				vNewReservation.PMS_ID	= vAnswerXDTO.GuestGroup;
				For Each vPaymentRow in vReservationRow.DepositPayments Do
					If vPaymentRow.Amount > 0 Then
						Try
							vExternalPaymentData = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/","ExternalPaymentData"));
							vExternalPaymentData.ExternalPaymentCode = vReservationRow.UniqueID;
							
							If ValueIsFilled(vPaymentRow.CurrencyCode) Then
								vCurrency = vPaymentRow.CurrencyCode;
							EndIf;
							
							If NOT ValueIsFilled(vCurrency) Then
								vCurrency = vAnswerXDTO.Currency; 
							EndIf;
							
							vExternalPaymentResult = cmWriteExternalPayment(,vNewReservation.PMS_ID,,,,,,"ExternalPayment",vPaymentRow.Amount,vCurrency,,pInteractionParameters.Hotel,pInteractionParameters.InteractionID,,,,,,,,"XDTO",vExternalPaymentData);
							If ValueIsFilled(vExternalPaymentResult.ErrorDescription) Then
								vError 				= vErrors.Add();
								vError.Type			= "3";
								vError.Code 			= "448";
								vError.DescriptionForConfirm 	= "Failed to create external payment.";
								vError.Description 		= "ru = 'Неудалось создать платеж по причине: '" + vExternalPaymentResult.ErrorDescription; //#Translate
								vSuccess			= False;
							EndIf;
						Except
								vError 				= vErrors.Add();
								vError.Type 			= "3";
								vError.Code 			= "448";
								vError.DescriptionForConfirm 	= "Failed to create external payment.";
								vError.Description 		= "ru = 'Неудалось создать платеж по причине: '" + ErrorDescription(); //#Translate
								vSuccess			= False;	
						EndTry;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		
		vNewReservation.Success	= vSuccess;
		vNewReservation.Errors	= DeleteSameErrors(vErrors);
	EndDo;
	
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
Function ArrayOfStringsToString(pArray, pDelimiter)
	vResult = "";
	For Each vString in pArray Do
		If ValueIsFilled(vString) Then
			If vResult = "" Then
				vResult = vString; 
			Else
				vResult = vResult + pDelimiter + vString;	
			EndIf;
		EndIf;
	EndDo;
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
Function GetRatesPerDay(pStartDate, pEndDate, pAmountAfterTax, pCurrencyCode)
	vResult = New ValueTable;
	vResult.Columns.Add("Date");
	vResult.Columns.Add("AmountAfterTax");
	vResult.Columns.Add("CurrencyCode");
	
	vDatesCount = (BegOfDay(pEndDate) - BegOfDay(pStartDate)) / (24*60*60);
	
	For i = 1 to vDatesCount Do
		vNewDateRow = vResult.Add();
		vNewDateRow.Date 			= pStartDate + ((i-1)*24*60*60);
		vNewDateRow.AmountAfterTax 	= pAmountAfterTax;
		vNewDateRow.CurrencyCode 	= pCurrencyCode;
	EndDo;
	
	Return vResult; 
EndFunction

// --------------------------------------------------------------------------------  
//  Cause we dont want to spam siteminder with same error, right?
Function DeleteSameErrors(pErrorTable) 
	vPreviousRow 	= Undefined;
	vDeathArray 	= New Array;
	For Each vErrorRow in pErrorTable Do
		If vPreviousRow <> Undefined Then
			If vPreviousRow.Type = vErrorRow.Type and vPreviousRow.Code = vErrorRow.Code and vPreviousRow.Description = vErrorRow.Description Then
				vDeathArray.Add(vErrorRow);
			EndIf;
		EndIf;
		vPreviousRow = vErrorRow; 
	EndDo;
	
	For Each vRow in vDeathArray Do
		pErrorTable.Delete(vRow);	
	EndDo;
	
	Return pErrorTable; 
EndFunction

// --------------------------------------------------------------------------------
Function CheckServiceByCode(pHotelRef, pExternalSystemCode, pObjectExternalCode)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ExternalSystemsObjectCodesMappings.ObjectRef
	|FROM
	|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
	|WHERE
	|	ExternalSystemsObjectCodesMappings.Hotel = &qHotel
	|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
	|	AND (ExternalSystemsObjectCodesMappings.ObjectTypeName = ""Services""
	|			OR ExternalSystemsObjectCodesMappings.ObjectTypeName = ""ServicePackages"")
	|	AND ExternalSystemsObjectCodesMappings.ObjectExternalCode = &qObjectExternalCode";
	vQry.SetParameter("qHotel", pHotelRef);
	vQry.SetParameter("qExternalSystemCode", TrimAll(pExternalSystemCode));
	vQry.SetParameter("qObjectExternalCode", TrimAll(pObjectExternalCode));
	vObjects = vQry.Execute().Unload();
	If vObjects.Count() = 1 Then
		Return True;
	Else
		Return False;	
	EndIf;	
EndFunction

// --------------------------------------------------------------------------------
//  Prepare balances table to upload to channel
Function GetBalances(pHotel, pAllotment, pPeriodFrom, pPeriodTo, pExtSystemCode = Undefined, pRoomType, pRoomTypeCode, pGetVacantRoomsAtMidnight = False)
	TRooms = New ValueTable;
	TRooms.Columns.Add("RoomType");
	TRooms.Columns.Add("RoomTypeCode");
	TRooms.Columns.Add("Allotment");
	TRooms.Columns.Add("PeriodFrom");
	TRooms.Columns.Add("PeriodTo");
	TRooms.Columns.Add("VacantRooms");
	TRooms.Columns.Add("VacantBeds");
	TRooms.Columns.Add("StopSale");
	
	vClearArray = New Array;
	
	vBalances = cmGetRoomQuotaBalances(pHotel, pRoomType , , , , pAllotment, pPeriodFrom, pPeriodTo, pGetVacantRoomsAtMidnight);
	For Each vRow in vBalances Do
		If (BegOfDay(vRow.Period) < BegOfDay(pPeriodFrom)) Then
			vClearArray.Add(vRow);
		EndIf;
	EndDo;
	
	For Each vRow in vClearArray Do
		vBalances.Delete(vRow);	
	EndDo;
	
	// Check for stop internet sales
	For Each vRow In vBalances Do
		r = TRooms.Add();
		r.RoomType 		= vRow.RoomType;
		r.RoomTypeCode 	= pRoomTypeCode;
		If vRow.Period = Null Then
			r.PeriodFrom = BegOfDay(pPeriodFrom);
			r.PeriodTo = BegOfDay(pPeriodTo);
			r.VacantRooms = 0;
			r.VacantBeds = 0;
		Else
			r.PeriodFrom = BegOfDay(vRow.Period);
			r.PeriodTo = r.PeriodFrom;
			If ValueIsFilled(pAllotment) Then
				r.VacantRooms = ?(vRow.RoomsRemains=Null,0,?(vRow.RoomsRemains>0,vRow.RoomsRemains,0));
				r.VacantBeds = ?(vRow.BedsRemains=Null,0,?(vRow.BedsRemains>0,vRow.BedsRemains,0));
			Else
				r.VacantRooms = ?(vRow.RoomsVacant=Null,0,?(vRow.RoomsVacant>0,vRow.RoomsVacant,0));
				r.VacantBeds = ?(vRow.BedsVacant=Null,0,?(vRow.BedsVacant>0,vRow.BedsVacant,0));
			EndIf;
		EndIf;
	EndDo;
	TRooms.Sort("RoomType, Allotment, PeriodFrom, PeriodTo");
	
	// Merge identical values in consequent days to one row
	If TRooms.Count() > 1 Then
		prev = TRooms.Get(0);
		i = 1;
		While i < TRooms.Count() Do
			curr = TRooms.Get(i);
			If curr.RoomType = prev.RoomType Then
				If curr.VacantRooms = prev.VacantRooms AND
					curr.VacantBeds = prev.VacantBeds AND
					curr.StopSale = prev.StopSale AND
					curr.PeriodFrom - prev.PeriodTo >= 0 Then
					// Nothing has changed but period,then merge rows - just move PeriodTo to next date
					prev.PeriodTo = curr.PeriodFrom;
					TRooms.Delete(curr);
				Else
					If prev.PeriodFrom = prev.PeriodTo Or prev.PeriodFrom < prev.PeriodTo And prev.PeriodTo < (curr.PeriodFrom - 24*3600) Then
						prev.PeriodTo = curr.PeriodFrom - 24*3600;
					EndIf;
					// Move previous row 
					prev = curr;
					i=i+1;
				EndIf;
			Else
				// Move previous row 
				prev = curr;
				i=i+1;
			EndIf;				
		EndDo;
	EndIf;
	
	// Remove room types without mappings
	vRoomTypesWithoutMappings = New ValueList();
	If pExtSystemCode <> Undefined Then
		i = 0;
		While i < TRooms.Count() Do
			row = TRooms.Get(i);                                                                          
			If vRoomTypesWithoutMappings.FindByValue(row.RoomType) <> Undefined Then
				TRooms.Delete(i);
			ElsIf Not cmCheckExternalSystemCodeMapping(pHotel, pExtSystemCode, row.RoomType, "Siteminder_RoomMapping_RT") Then
				vRoomTypesWithoutMappings.Add(row.RoomType);
				TRooms.Delete(i);
			Else
				i = i + 1;
			EndIf;
		EndDo;
	EndIf;
	
	// Check for stop internet sales
	For Each row In TRooms Do
		vRemarks = "";
		row.StopSale = cmIsStopInternetSalePeriod(row.RoomType, row.PeriodFrom, EndOfDay(row.PeriodTo), vRemarks);
	EndDo;
	
	Return TRooms;
EndFunction // GetBalances

// --------------------------------------------------------------------------------
Function SendRequests(pMethodName, pResultArray, pUsername, pPassword, pHTTPHost, pResourceAddress, pRequestorID, pHotelCode, pTable, pMaxMsgSize)
	If pTable.Count() <> 0 Then 
		If pTable.Count() <= pMaxMsgSize Then
			pResultArray.Add(ExecuteRequest(pMethodName, pUsername, pPassword, pHTTPHost, pResourceAddress, pRequestorID, pHotelCode, pTable));
		Else
			vTempTab 		= pTable.CopyColumns();
			vDeletignArray 	= New Array();
			vRequestID		= 1;
			While pTable.Count() > 0 Do
				If pTable.Count() <= pMaxMsgSize Then
					pResultArray.Add(ExecuteRequest(pMethodName, pUsername, pPassword, pHTTPHost, pResourceAddress, pRequestorID, pHotelCode, pTable));
					pTable.Clear();
				Else
					For i = 1 to pMaxMsgSize Do
						vNewRow = vTempTab.Add();
						FillPropertyValues(vNewRow,pTable[i-1]);
						vDeletignArray.Add(pTable[i-1]);
					EndDo;
					
					pResultArray.Add(ExecuteRequest(pMethodName, pUsername, pPassword, pHTTPHost, pResourceAddress, pRequestorID, pHotelCode, vTempTab));
					
					For Each vRow in vDeletignArray Do
						pTable.Delete(vRow);	
					EndDo;
					
					vTempTab.Clear();
					vDeletignArray.Clear();
				EndIf;
			EndDo;	
		EndIf;
	Else
		vResultStructure 	= New Structure("RawAnswer, Success, Errors, Warnings", "", False, New Array, New Array);		
		vError = New Structure("Code, Type, Description");
		vError.Code = "404";
		vError.Type = "404";
		vError.Type = "Not found any data for " + pMethodName + ". Check external system codes!"; //#Translate
		vResultStructure.Errors.Add(vError); 
		pResultArray.Add(vResultStructure);
	EndIf;
	Return pResultArray;
EndFunction

// --------------------------------------------------------------------------------
Function ExecuteRequest(pMethodName, pUsername, pPassword, pHTTPHost, pResourceAddress, pRequestorID, pHotelCode, pTable)
	If pMethodName = "SetAvailability" Then
		Return SetAvailability(pUsername, pPassword, pHTTPHost, pResourceAddress, pRequestorID, pHotelCode, pTable); 	
	ElsIf pMethodName = "SetRoomRates" Then
		Return SetRoomRates(pUsername, pPassword, pHTTPHost, pResourceAddress, pRequestorID, pHotelCode, pTable);	
	ElsIf pMethodName = "SetRestrictions" Then
		Return SetRestrictions(pUsername, pPassword, pHTTPHost, pResourceAddress, pRequestorID, pHotelCode, pTable);			
	EndIf;
	Return Undefined;
EndFunction

// --------------------------------------------------------------------------------
Function FilterBalancesTable(pTable, pHotel, pInteractionID)
	
	vClearArray = New Array;
	
	For Each vRow in pTable Do
		vQuery = New Query;
		vQuery.Text = 
		"SELECT TOP 1
		|	ExternalSystemsObjectCodesMappings.ObjectTypeName AS ObjectTypeName,
		|	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode,
		|	ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef
		|FROM
		|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
		|WHERE
		|	ExternalSystemsObjectCodesMappings.Hotel = &qHotel
		|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
		|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""Siteminder_RoomMapping_RT""
		|	AND ExternalSystemsObjectCodesMappings.ObjectRef = &qRoomType";
		
		vQuery.SetParameter("qExternalSystemCode", 	pInteractionID);
		vQuery.SetParameter("qHotel", 				pHotel);
		vQuery.SetParameter("qRoomType", 			vRow.RoomType);
		
		vQueryResult = vQuery.Execute().Unload();
		
		If vQueryResult.Count() = 0 Then
			vClearArray.Add(vRow);
		EndIf;
		
		For Each vQuerryRow in vQueryResult Do
			vStartPosition 		= StrFind(vQuerryRow.ObjectExternalCode,"<Inv>") + 5;
			vEndPosition   		= StrFind(vQuerryRow.ObjectExternalCode,"</Inv>");
			vRow.RoomTypeCode	= Mid(vQuerryRow.ObjectExternalCode, vStartPosition, vEndPosition - vStartPosition);
		EndDo;
		
	EndDo;
	
	For Each vRow in vClearArray Do
		pTable.Delete(vRow);
	EndDo;
	
	Return pTable; 
EndFunction

// --------------------------------------------------------------------------------
Function GetRoomTypesTable(pHotel, pInteractionID)
	
	vResult = New ValueTable;
	vResult.Columns.Add("RoomTypeRef");
	vResult.Columns.Add("RoomTypeCode");
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT DISTINCT
	|	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode,
	|	ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef
	|FROM
	|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
	|WHERE
	|	ExternalSystemsObjectCodesMappings.Hotel = &qHotel
	|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
	|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""Siteminder_RoomMapping_RT""
	|
	|ORDER BY
	|	ObjectExternalCode";
	
	vQuery.SetParameter("qExternalSystemCode", 	pInteractionID);
	vQuery.SetParameter("qHotel", 				pHotel);
	
	vQueryResult = vQuery.Execute().Unload();
	
	vPreviousCode = Undefined;
	For Each vQuerryRow in vQueryResult Do		
		vStartPosition 		= StrFind(vQuerryRow.ObjectExternalCode,"<Inv>") + 5;
		vEndPosition   		= StrFind(vQuerryRow.ObjectExternalCode,"</Inv>");
		vInvCode			= Mid(vQuerryRow.ObjectExternalCode, vStartPosition, vEndPosition - vStartPosition);
		
		If vPreviousCode <> vInvCode Then
			vNewRow 				= vResult.Add();
			vNewRow.RoomTypeRef 	= vQuerryRow.ObjectRef;
			vNewRow.RoomTypeCode 	= vInvCode;
		EndIf;
		
		vPreviousCode = vInvCode; 
	EndDo;
	
Return vResult;
EndFunction

// --------------------------------------------------------------------------------
Function FilterRatesTable(pTable, pHotel, pInteractionID)
	
	vClearArray = New Array;
	
	For Each vRow in pTable Do
		vQuery = New Query;
		vQuery.Text = 
		"SELECT
		|	ExternalSystemsObjectCodesMappings.ObjectTypeName AS ObjectTypeName,
		|	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode,
		|	ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef
		|FROM
		|	(SELECT
		|		ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode
		|	FROM
		|		(SELECT
		|			ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode
		|		FROM
		|			InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
		|		WHERE
		|			ExternalSystemsObjectCodesMappings.Hotel = &qHotel
		|			AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
		|			AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""Siteminder_RoomMapping_RR""
		|			AND ExternalSystemsObjectCodesMappings.ObjectRef = &qRoomRate) AS RoomRate
		|			LEFT JOIN InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
		|			ON RoomRate.ObjectExternalCode = ExternalSystemsObjectCodesMappings.ObjectExternalCode
		|	WHERE
		|		ExternalSystemsObjectCodesMappings.Hotel = &qHotel
		|		AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
		|		AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""Siteminder_RoomMapping_RT""
		|		AND ExternalSystemsObjectCodesMappings.ObjectRef = &qRoomType) AS RoomRateType
		|		LEFT JOIN InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
		|		ON RoomRateType.ObjectExternalCode = ExternalSystemsObjectCodesMappings.ObjectExternalCode
		|WHERE
		|	ExternalSystemsObjectCodesMappings.Hotel = &qHotel
		|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
		|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""Siteminder_RoomMapping_AT""";
		
		vQuery.SetParameter("qExternalSystemCode", 	pInteractionID);
		vQuery.SetParameter("qHotel", 				pHotel);
		vQuery.SetParameter("qRoomRate", 			vRow.RoomRate);
		vQuery.SetParameter("qRoomType", 			vRow.RoomType);
		
		vQueryResult = vQuery.Execute().Unload();
		
		If vQueryResult.Count() = 0 Then
			vClearArray.Add(vRow);
		Else
			vStartPosition 	= StrFind(vQueryResult[0].ObjectExternalCode,"<Inv>") + 5;
			vEndPosition   	= StrFind(vQueryResult[0].ObjectExternalCode,"</Inv>");
			vRoomTypeCode	= Mid(vQueryResult[0].ObjectExternalCode, vStartPosition, vEndPosition - vStartPosition);
			
			
			vStartPosition 	= StrFind(vQueryResult[0].ObjectExternalCode,"<Rate>") + 6;
			vEndPosition   	= StrFind(vQueryResult[0].ObjectExternalCode,"</Rate>");
			vRoomRateCode	= Mid(vQueryResult[0].ObjectExternalCode, vStartPosition, vEndPosition - vStartPosition);

			vRow.RoomTypeCode	= vRoomTypeCode;
			vRow.RateCode		= vRoomRateCode;
		EndIf;
	EndDo;
	
	For Each vRow in vClearArray Do
		pTable.Delete(vRow);
	EndDo;
	vClearArray.Clear();
		
	Return pTable; 
EndFunction

// --------------------------------------------------------------------------------
Function GetRoomRatesTable(pHotel, pInteractionID)
	
	vResult = New ValueTable;
	vResult.Columns.Add("RoomRateRef");
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT DISTINCT
	|	ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef
	|FROM
	|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
	|WHERE
	|	ExternalSystemsObjectCodesMappings.Hotel = &qHotel
	|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
	|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""Siteminder_RoomMapping_RR""";
	
	vQuery.SetParameter("qExternalSystemCode", 	pInteractionID);
	vQuery.SetParameter("qHotel", 				pHotel);
	
	vQueryResult = vQuery.Execute().Unload();
	
	vPreviousCode = Undefined;
	For Each vQuerryRow in vQueryResult Do
		vNewRow 			= vResult.Add();
		vNewRow.RoomRateRef 	= vQuerryRow.ObjectRef;
	EndDo;
		
Return vResult;
EndFunction

// --------------------------------------------------------------------------------
Function PrepareRatesTable(pTable, pHotel, pInteractionID)
	vRoomRates = New ValueTable;
	vRoomRates.Columns.Add("RoomTypeCode");
	vRoomRates.Columns.Add("RateCode");
	vRoomRates.Columns.Add("Price");
	vRoomRates.Columns.Add("CurrencyCode");
	vRoomRates.Columns.Add("Start");
	vRoomRates.Columns.Add("End");
	vRoomRates.Columns.Add("Description");
	
	For Each vRow in pTable Do 
		vStartPosition 	= StrFind(vRow.RoomTypeCode,"<Inv>") + 5;
		vEndPosition   	= StrFind(vRow.RoomTypeCode,"</Inv>");
		vRoomTypeCode	= Mid(vRow.RoomTypeCode, vStartPosition, vEndPosition - vStartPosition);
		
		
		vStartPosition 	= StrFind(vRow.RoomTypeCode,"<Rate>") + 6;
		vEndPosition   	= StrFind(vRow.RoomTypeCode,"</Rate>");
		vRoomRateCode	= Mid(vRow.RoomTypeCode, vStartPosition, vEndPosition - vStartPosition);
				
		vPrice 		= vRow.Price;
		vCurrency	= vRow.Currency;
		
		If ValueIsFilled(vPrice) Then				
			If NOT ValueIsFilled(vCurrency) Then 
				vCurrency = cmGetObjectExternalSystemCodeByRef(pHotel, pInteractionID, "Currencies", pHotel.BaseCurrency);
				WriteLogEvent(pInteractionID + "_PrepareRatesTable", EventLogLevel.Warning,,CurrentSessionDate(),NStr("en = 'Currency not found for accommodation template! Template code:'; ru = 'В шаблоне размещения не найдена валюта! Код шаблона:'; de = 'Währung nicht gefunden für Unterkunft Vorlage! Vorlagencode:'") + vRow.RoomTypeCode);
			EndIf;		
			vNewRow 				= vRoomRates.Add();
			vNewRow.RoomTypeCode 	= vRoomTypeCode;
			vNewRow.RateCode 		= vRoomRateCode;
			vNewRow.Price 			= vPrice;
			vNewRow.CurrencyCode 	= vCurrency;
			vNewRow.Start 			= vRow.PeriodFrom;
			vNewRow.End 			= vRow.PeriodTo;
			vNewRow.Description 	= cmNStr(vRow.RoomRate.ReservationConditionsOnline); //inclusions
		Else
			WriteLogEvent(pInteractionID + "_PrepareRatesTable", EventLogLevel.Warning,,CurrentSessionDate(),NStr("en = 'Accommodation template in mapping table is not equal to accommodation template in prices! Template code:'; ru = 'Шаблон размещения в таблице соответсвий не соответсвует шаблону размещений в ценах! Код шаблона:'; de = 'Unterkunft Vorlage in Mapping-Tabelle ist nicht gleich Unterkunft Vorlage in Preisen! Vorlagencode:'") + vRow.RoomTypeCode);
		EndIf;
	EndDo;
	
	vRoomRates.Sort("RoomTypeCode, RateCode, Start");
	Return vRoomRates; 
EndFunction

// --------------------------------------------------------------------------------
Function GetRestrictionsTable(pHotel, pInteractionID, pSyncPeriod, pPeriodFrom = Undefined)
		vRestrictionsResult = New ValueTable;
		vRestrictionsResult.Columns.Add("Start");
		vRestrictionsResult.Columns.Add("End");
		vRestrictionsResult.Columns.Add("RoomTypeCode");
		vRestrictionsResult.Columns.Add("RateCode");
		vRestrictionsResult.Columns.Add("Agent");
		vRestrictionsResult.Columns.Add("MinStay");
		vRestrictionsResult.Columns.Add("MaxStay");
		vRestrictionsResult.Columns.Add("StopSell");
		vRestrictionsResult.Columns.Add("CTA");
		vRestrictionsResult.Columns.Add("CTD");

		vQuery = New Query;
		vQuery.Text = 
		"SELECT DISTINCT
		|	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode,
		|	ExternalSystemsObjectCodesMappings.ObjectRef AS RoomType,
		|	RoomRate.ObjectRef AS RoomRate
		|FROM
		|	(SELECT DISTINCT
		|		ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode,
		|		ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef
		|	FROM
		|		InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
		|	WHERE
		|		ExternalSystemsObjectCodesMappings.Hotel = &qHotel
		|		AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
		|		AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""Siteminder_RoomMapping_RR"") AS RoomRate
		|		INNER JOIN InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
		|		ON RoomRate.ObjectExternalCode = ExternalSystemsObjectCodesMappings.ObjectExternalCode
		|WHERE
		|	ExternalSystemsObjectCodesMappings.Hotel = &qHotel
		|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
		|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""Siteminder_RoomMapping_RT""
		|
		|ORDER BY
		|	ObjectExternalCode";
		
		vQuery.SetParameter("qExternalSystemCode", 	pInteractionID);
		vQuery.SetParameter("qHotel", 				pHotel);		
		vQueryResult = vQuery.Execute().Unload();
		For Each vRow in vQueryResult Do
			vStartPosition 	= StrFind(vRow.ObjectExternalCode,"<Inv>") + 5;
			vEndPosition   	= StrFind(vRow.ObjectExternalCode,"</Inv>");
			vRoomTypeCode	= Mid(vRow.ObjectExternalCode, vStartPosition, vEndPosition - vStartPosition);
			
			
			vStartPosition 	= StrFind(vRow.ObjectExternalCode,"<Rate>") + 6;
			vEndPosition   	= StrFind(vRow.ObjectExternalCode,"</Rate>");
			vRoomRateCode	= Mid(vRow.ObjectExternalCode, vStartPosition, vEndPosition - vStartPosition);
			
			If pPeriodFrom = Undefined Then
				vCurrentDate = BegOfDay(CurrentSessionDate());
			Else
				vCurrentDate = BegOfDay(pPeriodFrom);
			EndIf;
			For i = 1 to pSyncPeriod Do
				vRestrictions = cmGetRoomRateRestrictions(pHotel, vRow.RoomRate, vCurrentDate, vRow.RoomType,False);  
					vNewRow 				= vRestrictionsResult.Add();
					vNewRow.Start 			= vCurrentDate;
					vNewRow.End 			= vCurrentDate;
					vNewRow.RoomTypeCode	= vRoomTypeCode;
					vNewRow.RateCode 		= vRoomRateCode;
					//vNewRow.Agent 			= ;
					If vRestrictions.MLOS > 0 Then
						vNewRow.MinStay 	= vRestrictions.MLOS;
					Else
						vNewRow.MinStay 	= 1;
					EndIf;
					If vRestrictions.MaxLOS > 0 Then
						vNewRow.MaxStay 	= vRestrictions.MaxLOS;
					Else
						vNewRow.MaxStay 	= 999;
					EndIf;
					vNewRow.StopSell 		= vRestrictions.StopSale;
					vNewRow.CTA 			= vRestrictions.CTA;
					vNewRow.CTD 			= vRestrictions.CTD;
				vCurrentDate = vCurrentDate + 24*60*60;
			EndDo;
		EndDo;
		
		vClearArray = New Array;
		vPreviousRow = Undefined;
		For Each vRow in vRestrictionsResult Do
			If vPreviousRow <> Undefined Then
				If 	vPreviousRow.RoomTypeCode = vRow.RoomTypeCode
				And vPreviousRow.RateCode = vRow.RateCode
				And vPreviousRow.Agent = vRow.Agent
				And vPreviousRow.MinStay = vRow.MinStay
				And vPreviousRow.MaxStay = vRow.MaxStay
				And vPreviousRow.StopSell = vRow.StopSell
				And vPreviousRow.CTA = vRow.CTA
				And vPreviousRow.CTD = vRow.CTD Then
					vRow.Start = vPreviousRow.Start; 
					vClearArray.Add(vPreviousRow);
				EndIf;
			EndIf;
			vPreviousRow = vRow;
		EndDo;
		
		For Each vRow in vClearArray Do
			vRestrictionsResult.Delete(vRow);
		EndDo;
		
		Return vRestrictionsResult;
EndFunction

// --------------------------------------------------------------------------------
Function GetRates(pHotel, pInteractionParameters, pPeriodFrom, pPeriodTo, pExternalSystemCode, pRoomType , pRoomTypesMappingName = "RoomTypes", pAccTemplate)
	vResult = New ValueTable;
	vResult.Columns.Add("RoomRate");
	vResult.Columns.Add("RoomType");
	vResult.Columns.Add("RoomTypeCode");
	vResult.Columns.Add("PeriodFrom");
	vResult.Columns.Add("PeriodTo");
	vResult.Columns.Add("Price");
	vResult.Columns.Add("Currency");
	vHotel 		= cmGetObjectExternalSystemCodeByRef(pHotel, pExternalSystemCode, "Hotels", pHotel);
	vRoomType 	= cmGetObjectExternalSystemCodeByRef(pHotel, pExternalSystemCode, pRoomTypesMappingName, pRoomType);
	vRoomRateArray = New Array;
	vRoomRateArray.Add(pAccTemplate);
	
	vExtraParameters = New Structure("AccTemplateCode, ForSiteminder", pAccTemplate, True);
	vNewPrices 	= cmGetAvailableRoomsWithDailyPrices(vHotel, vRoomType, pInteractionParameters.Allotment, pPeriodFrom, pPeriodTo, , vRoomRateArray, 0, 0, New Array , , pExternalSystemCode, , vExtraParameters);

	vCurrentRoomRate = Undefined;
	vRoomRatesTable = New ValueTable;
	For Each vRow in vNewPrices.RoomTypeDailyAvailabilityAndPricesRow Do
		For Each vPriceRow in vRow.RoomTypeDailyPrices.RoomRateDailyPriceRow Do
			If vPriceRow.Price <> Undefined and vPriceRow.Price > 0 Then	
				vNewRow 						= vResult.Add();
				vNewRow.RoomRate 				= Catalogs.RoomRates.FindByCode(vPriceRow.RoomRateCode);
				vNewRow.RoomType 				= pRoomType;
				vNewRow.RoomTypeCode 			= pAccTemplate;
				vNewRow.PeriodFrom 				= vRow.Period;
				vNewRow.Price 					= vPriceRow.Price;
				vNewRow.Currency 				= vPriceRow.Currency;
			EndIf;
		EndDo;
	EndDo;
	
	// Merge identical values in consequent days to one row
	vResult.Sort("RoomRate, RoomTypeCode, PeriodFrom");
	If vResult.Count() > 1 Then
		i = 0;
		vPrev = Undefined;
		vCur = Undefined;
		While i < vResult.Count() Do
			vCur = vResult[i];
			If vPrev <> Undefined Then
				If 	vPrev.RoomRate 	= vCur.RoomRate
				And vPrev.RoomType 	= vCur.RoomType
				And vPrev.RoomTypeCode 	= vCur.RoomTypeCode
				And vPrev.Price 	= vCur.Price
				And vPrev.Currency 	= vCur.Currency Then
					vPrev.PeriodTo = vCur.PeriodFrom;
					vResult.Delete(i);
				Else
					vPrev = vCur;
					i = i + 1;
				EndIf;
			Else
				vPrev = vCur;
				i = i + 1;
			EndIf;	
		EndDo;
		If vPrev <> Undefined Then
			If Not ValueIsFilled(vPrev.PeriodTo) Then
				vPrev.PeriodTo = vPrev.PeriodFrom;
			EndIf;
		EndIf;
	EndIf;
	
	vResult.Sort("RoomRate, RoomTypeCode, PeriodTo");
	Return vResult; 
EndFunction

// --------------------------------------------------------------------------------
Function GetAllExternalRoomTypesCodes(pHotel, pInteractionID, pRoomType)
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ExternalSystemsObjectCodesMappings.ObjectExternalCode,
		|	ExternalSystemsObjectCodesMappings.ObjectRef
		|FROM
		|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
		|WHERE
		|	ExternalSystemsObjectCodesMappings.Hotel = &qHotel
		|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
		|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""Siteminder_RoomMapping_RT""
		|	AND ExternalSystemsObjectCodesMappings.ObjectRef = &qObjectRef";
	
	vQuery.SetParameter("qExternalSystemCode", pInteractionID);
	vQuery.SetParameter("qHotel", pHotel);
	vQuery.SetParameter("qObjectRef", pRoomType);
	
	vQueryResult = vQuery.Execute().Unload();
	
	Return vQueryResult; 	
EndFunction

// --------------------------------------------------------------------------------
Procedure FillDailyPrices(pInteractionParameters, pHotel, pRoomRate, pRoomType = Undefined, pPeriodFrom, pPeriodTo)
	Try
		vObj 			= DataProcessors.FillRoomRateDailyPrices.Create();
		vObj.Hotel 		= pHotel;
		vObj.RoomType 	= pRoomType;
		vObj.RoomRate 	= pRoomRate;
		vObj.PeriodFrom = BegOfDay(pPeriodFrom);
		vObj.PeriodTo 	= EndOfDay(pPeriodTo);
		vObj.pmDoFill(True);
	Except
		vMessage = ("Error! Failed to fill room rate daily prices
		|Hotel: " + pHotel + " 
		|RoomRate:" + pRoomRate + "
		|RoomType:" + pRoomType + "
		|PeriodFrom:" + BegOfDay(pPeriodFrom) + "
		|PeriodTo:" + EndOfDay(pPeriodTo));      
		tcCommonFunctionOnClientServer.UserMessage(vMessage);
		WriteLogEvent(pInteractionParameters.InteractionID + "_FillDailyPrices", EventLogLevel.Error,,CurrentSessionDate(), vMessage);	
	EndTry;
EndProcedure

// --------------------------------------------------------------------------------
Procedure WriteLog(pInteractionParameters, pOperationName, pResultTable, JSONnotXML = True)
	Try
		For Each vResultRow in pResultTable Do
			For Each vErrorRow in vResultRow.Errors Do
				WriteLogEvent(pInteractionParameters.InteractionID + "_" + pOperationName, EventLogLevel.Warning,,CurrentSessionDate(),
				"Error! Code: " + vErrorRow.Code + ". Type: " + vErrorRow.Type + "." + Chars.LF + "Description: " + vErrorRow.Description);
			EndDo;
			For Each vWarningRow in vResultRow.Warnings Do
				WriteLogEvent(pInteractionParameters.InteractionID + "_" + pOperationName, EventLogLevel.Warning,,CurrentSessionDate(),
				"Warning! Code: " + vWarningRow.Code + ". Type: " + vWarningRow.Type + "." + Chars.LF + "Description: " + vWarningRow.Description);
			EndDo;
			If pOperationName = "GetReservations" Then
				If vResultRow.ReservationsCount > 0 Then
					If NOT vResultRow.Loaded Then
						WriteLogEvent(pInteractionParameters.InteractionID + "_" + pOperationName, EventLogLevel.Warning,,CurrentSessionDate(),NStr("en = 'Error!
						|Failed to load reservation from siteminder!'; ru = 'Ошибка!
						|Неудалось загрузить брони из siteminder!'; de = 'Error!
						|Fehler beim Laden der Reservierung von siteminder!'"));
					EndIf;
					
					If NOT vResultRow.Confirmed Then
						WriteLogEvent(pInteractionParameters.InteractionID + "_" + pOperationName, EventLogLevel.Warning,,CurrentSessionDate(),
						NStr("en = 'Error!
						|Failed to confirm reservation from siteminder!'; ru = 'Ошибка!
						|Неудалось подтвердить брони из siteminder!'; de = 'Error!
						|Die Reservierung von siteminder konnte nicht bestätigt werden!'"))
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		If ValueIsFilled(pInteractionParameters.LogFolder) Then
			If NOT JSONnotXML Then
				#Region XML
				vFullFileName = pInteractionParameters.LogFolder + "\" + cmGetValidFileName(pInteractionParameters.InteractionID + "_" + Format(CurrentSessionDate(),"DF=dd.MM.yyyy_HH_mm_ss") + ".xml");
				
				vXML = New XMLWriter;
				vXML.OpenFile(vFullFileName,"UTF-8");
				
				i = 1;
				vXML.WriteStartElement("Operations");
				For Each vResultRow in pResultTable Do 
					vXML.WriteStartElement(pOperationName);
					vXML.WriteAttribute("ID", String(i));
					If vResultRow.Success Then 
						vXML.WriteAttribute("Success", "True");
					Else
						vXML.WriteAttribute("Success", "False");
					EndIf;
					vXML.WriteAttribute("Date", String(CurrentSessionDate()));
						vXML.WriteStartElement("Request");
						vXML.WriteText(vResultRow.RawRequest);		
						vXML.WriteEndElement();
						vXML.WriteStartElement("Response");
						vXML.WriteText(vResultRow.RawResponse);		
						vXML.WriteEndElement();
						
						If vResultRow.Property("ReservationsCount") Then
							vXML.WriteStartElement("ReservationsFound");
							vXML.WriteAttribute("Count", 		String(vResultRow.ReservationsCount));
							If vResultRow.Loaded Then 
								vXML.WriteAttribute("Loaded", "True");
							Else
								vXML.WriteAttribute("Loaded", "False");	
							EndIf;
							If vResultRow.Confirmed Then 
								vXML.WriteAttribute("Confirmed", "True");
							Else
								vXML.WriteAttribute("Confirmed", "False");	
							EndIf; 
							vXML.WriteEndElement();	
						EndIf;
						
						vXML.WriteStartElement("Errors");
						For Each vErrorRow in vResultRow.Errors Do
							vXML.WriteStartElement("Error");
							vXML.WriteAttribute("Code", 		String(vErrorRow.Code)); 
							vXML.WriteAttribute("Type", 		String(vErrorRow.Type));
							vXML.WriteText(						String(vErrorRow.Description));
							vXML.WriteEndElement();
						EndDo;
						vXML.WriteEndElement();
						
						vXML.WriteStartElement("Warnings");
						For Each vWarningRow in vResultRow.Warnings Do
							vXML.WriteStartElement("Warning");
							vXML.WriteAttribute("Code", 		String(vWarningRow.Code)); 
							vXML.WriteAttribute("Type", 		String(vWarningRow.Type));
							vXML.WriteText(						String(vWarningRow.Description));
							vXML.WriteEndElement();
						EndDo;
						vXML.WriteEndElement();
					vXML.WriteEndElement();
					i = i + 1; 
				EndDo;
				vXML.WriteEndElement();
				vXML.Close();
				#EndRegion
			Else
				#Region JSON
				vFullFileName = pInteractionParameters.LogFolder + "\" + cmGetValidFileName(pInteractionParameters.InteractionID + "_" + Format(CurrentSessionDate(),"DF=dd.MM.yyyy_HH_mm_ss") + ".json");	
				
				vJSON = New JSONWriter;
				vJSON.ValidateStructure = False;
				vJSON.OpenFile(vFullFileName,"UTF-8");
				
				i = 1;
				vJSON.WriteStartObject();
				vJSON.WritePropertyName("Operations");
					vJSON.WriteStartArray();
					For Each vResultRow in pResultTable Do
						vJSON.WriteStartObject();
						vJSON.WritePropertyName("Operation");
						vJSON.WriteValue(pOperationName);
						
						vJSON.WritePropertyName("ID");
						vJSON.WriteValue(i);
						
						vJSON.WritePropertyName("TimeStamp");
						vJSON.WriteValue(vResultRow.TimeStamp);
						
						vJSON.WritePropertyName("EchoToken");
						vJSON.WriteValue(vResultRow.EchoToken);
						
						vJSON.WritePropertyName("Success");
						vJSON.WriteValue(vResultRow.Success);
						
						vJSON.WritePropertyName("Date");
						vJSON.WriteValue(String(CurrentSessionDate()));
						
						vJSON.WritePropertyName("Request");
						vJSON.WriteValue(vResultRow.RawRequest);
						
						vJSON.WritePropertyName("Response");
						vJSON.WriteValue(vResultRow.RawResponse);
						
						If vResultRow.Property("ReservationsCount") Then
						vJSON.WritePropertyName("ReservationsCount");
						vJSON.WriteValue(vResultRow.ReservationsCount);
						
						vJSON.WritePropertyName("Loaded");
						vJSON.WriteValue(vResultRow.Loaded);
						
						vJSON.WritePropertyName("Confirmed");
						vJSON.WriteValue(vResultRow.Confirmed);
						EndIf;
					
						vJSON.WritePropertyName("Errors");
						vJSON.WriteStartArray();
						For Each vErrorRow in vResultRow.Errors Do
							vJSON.WriteStartObject();
							vJSON.WritePropertyName("Code");
							vJSON.WriteValue(vErrorRow.Code);
							vJSON.WritePropertyName("Type");
							vJSON.WriteValue(vErrorRow.Type);
							vJSON.WritePropertyName("Description");
							vJSON.WriteValue(vErrorRow.Description);
							vJSON.WriteEndObject();
						EndDo;
						vJSON.WriteEndArray();
						
						vJSON.WritePropertyName("Warnings");
						vJSON.WriteStartArray();
						For Each vWarningRow in vResultRow.Warnings Do
							vJSON.WriteStartObject();
							vJSON.WritePropertyName("Code");
							vJSON.WriteValue(vWarningRow.Code);
							vJSON.WritePropertyName("Type");
							vJSON.WriteValue(vWarningRow.Type);
							vJSON.WritePropertyName("Description");
							vJSON.WriteValue(vWarningRow.Description);
							vJSON.WriteEndObject();
						EndDo;
						vJSON.WriteEndArray();
						vJSON.WriteEndObject();
						
						i = i + 1;
					EndDo;
					vJSON.WriteEndArray();
				vJSON.WriteEndObject();
				#EndRegion
			EndIf;
		EndIf;
	Except
		vError = ErrorDescription();
		WriteLogEvent(pInteractionParameters.InteractionID + "_" + pOperationName + "_" + "WriteLog", EventLogLevel.Warning,,CurrentSessionDate(),NStr("en = 'Cannot write log file for operation'; ru = 'Неудалось создать файл лога для операции'") + ": " + vError);
	EndTry;
EndProcedure

#EndRegion



