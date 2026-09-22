
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("ExternalSystemInteraction") Then
		ExternalSystemInteraction = Parameters.ExternalSystemInteraction;
	EndIf; 
	If Parameters.Property("IdentificationCard") Then
		IdentificationCard = Parameters.IdentificationCard;
		CardPresantation = GetCardIDPresantation(IdentificationCard);
	EndIf;
	vIsDetailsInfo = False;
	If Parameters.Property("IsDetailsInfo") Then
		vIsDetailsInfo = Parameters.IsDetailsInfo;
	EndIf;
	vReplaceCard = False;
	If Parameters.Property("IsReplaceCard") Then
		vReplaceCard = Parameters.IsReplaceCard;
	EndIf;
	If Parameters.Property("RateISD") Then
		Rate = Parameters.RateISD;
	EndIf;
	// Do processing
	If vReplaceCard Then
		If Not CheckCard() Then
			Return;
		EndIf;
		IdentificationCard = "";
		CardPresantation = "";
		PageType = 3;
		SetPage();
	ElsIf Not IsBlankString(IdentificationCard)  And ValueIsFilled(ExternalSystemInteraction) And vIsDetailsInfo = False Then
		FillCardData();
	ElsIf Not IsBlankString(IdentificationCard)  And ValueIsFilled(ExternalSystemInteraction) And vIsDetailsInfo = True Then
	    GetTransaction();
	Else
		PageType = 0;
		SetPage();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ExternalEvent(pSource, pEvent, pData)
	If Not IsInputAvailable() Then
		Return;
	EndIf;
	
	vEventData = tcConnectionHardwareAtClient.cmGetExternalEventResultInputDevice(pSource, pEvent, pData);
	
	If vEventData.DeviceType = "MagneticStripeCardReader" Then
		If Not PageType = 3 Then
			ClearFormAttributes();
		EndIf;
		
		IdentificationCard = vEventData.DeviceData;
		
		If Not IsBlankString(IdentificationCard) And ValueIsFilled(ExternalSystemInteraction) Then
			Items.ReplaceCardHelpMessage.BackColor = tcCommonFunctionOnClientServer.ColorConstructor();
			FillCardData();
			If PageType = 3 And CloseForm Then
				Close(New Structure("IdentificationCard, ReplaceCard", IdentificationCard, ReplaceCard));
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ExternalEvent

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ReadNewCard(pCommand)
	PageType = 0; // Read card
	SetPage();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearCard(pCommand)
	If Not IsBlankString(IdentificationCard)  And ValueIsFilled(ExternalSystemInteraction) Then
		// Ask user if he really wants to delete cards
		vNF = New NotifyDescription("AfterDeleteCardsConfirmation", ThisObject);
		vQuery = NStr("en = 'Do you want to delete selected cards?'; de = 'Wollen Sie alle Folio Karten zu löschen?'; ru = 'Хотите очистить карту?'");
		ShowQueryBox(vNF, vQuery, QuestionDialogMode.YesNo, , DialogReturnCode.No);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterDeleteCardsConfirmation(pUserAnswer, pExtraParams) Export
	If pUserAnswer = DialogReturnCode.Yes Then
		vKeyParams = New Structure;   
		vKeyParams.Insert("media_num", IdentificationCard);
		vKeyParams.Insert("pointsale", GetPSALID());
		vRes = ISD.ClearCard(ExternalSystemInteraction, vKeyParams); 
		If vRes.Success Then
			DeleteCard(IdentificationCard);
			ShowMessageBox(, Nstr("en = 'Successfully!'; de = 'Erfolgreich!'; ru = 'Успешно!'"));
		Else           
			HelpMessage = vRes.StatusDescription;
			ShowMessageBox(, vRes.StatusDescription, , Nstr("en = 'Card clearing error!'; de = 'Fehler beim Löschen der Karte!'; ru = 'Ошибка очистки карты!'"));
		EndIf;
		PageType = 0; // Read card
		SetPage();
	EndIf;
EndProcedure // AfterDeleteCardsConfirmation

// -----------------------------------------------------------------------------
&AtClient
Procedure IdentificationCard1StartChoice(Item, pChoiceData, pStandardProcessing)
	If Not IsBlankString(Item.EditText) Then
		IdentificationCard = Item.EditText;
		If Not IsBlankString(IdentificationCard) And ValueIsFilled(ExternalSystemInteraction) Then
			Items.ReplaceCardHelpMessage.BackColor = tcCommonFunctionOnClientServer.ColorConstructor();
			FillCardData();
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure IdentificationCard1OnChange(Item)
	If Not IsBlankString(IdentificationCard) And ValueIsFilled(ExternalSystemInteraction) Then
		Items.ReplaceCardHelpMessage.BackColor = tcCommonFunctionOnClientServer.ColorConstructor();
		FillCardData();
	EndIf;
EndProcedure

&AtClient
Procedure DetailsInfo(Command)
	 GetTransaction();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function GetPSALID()
	vISDWorkstationID = "";
	vISDWorkstations = InformationRegisters.ExternalSystemIntegrationData.GetData(ExternalSystemInteraction, "Workstation", "ID", SessionParameters.CurrentWorkstation);
	If vISDWorkstations.Count() > 0 Then
		vISDWorkstationID = vISDWorkstations.Get(0).ExternalSystemDataCode;
	Endif;
	Return vISDWorkstationID;
EndFunction	

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure SetPage()
	If PageType = 0 Then  // Read card
		Items.Pages.CurrentPage = Items.InfoMessage;

		ClearFormAttributes();

		Items.ClearCard.Visible = False;
		Items.DetailsInfo.Visible = False;
	ElsIf PageType = 2 Then // Transactions
		// Show card transactions
		Items.Pages.CurrentPage = Items.Transactions;
		Items.ClearCard.Visible = False;
		Items.DetailsInfo.Visible = False;
	ElsIf PageType = 3 Then // Replace card
		// Show card transactions
		Items.Pages.CurrentPage = Items.ReplaceCardPage;
		Items.ClearCard.Visible = False;
		Items.DetailsInfo.Visible = False;
		Items.ServiceInformation.Visible = False;
		Items.IdentificationCard1.Enabled = False;
	Else // 1
		// Show card info
		Items.Pages.CurrentPage = Items.CardInfo;
		// User rights
		If tcOnServer.cmIsInRole("Administrator") Then
			Items.ClearCard.Visible = True;
		Else	
			Items.ClearCard.Visible = False;
		EndIf;

		Items.DetailsInfo.Visible = True;
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure ClearFormAttributes()
	Title = "";
	CheckInDate 		= Undefined;
	CheckOutDate 		= Undefined;
	Guest				= Undefined;
	HelpMessage 		= Undefined;
	IdentificationCard  = Undefined;
	Parking 			= Undefined;
	Rate 				= Undefined;
	Brand 				= Undefined;
	Model 				= Undefined;
	Plate 				= Undefined;
	ValidTo 			= Undefined;
	DiscountBalance		= Undefined;
	DiscountType		= Undefined;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillCardData()
	If Not CheckCard() Then
		Return;
	EndIf;	
	CurrentTime = CurrentSessionDate();
	CardPresantation = GetCardIDPresantation(IdentificationCard);
	If PageType = 3 Then // Replace card
		vCard = cmGetClientIdentificationCardById(IdentificationCard);
		If ValueIsFilled(vCard) Then
			ReplaceCardHelpMessage = NStr("en='This card is already registered!';ru='Эта карта уже зарегистрирована!';de='Diese Karte ist bereits registriert!'") + " " + String(vCard);
			Items.ReplaceCardHelpMessage.BackColor = tcCommonFunctionOnClientServer.ColorConstructor(255, 202, 197);
			IdentificationCard = "";
			Return;
		EndIf;	
		vKeyParams = New Structure;   
		vKeyParams.Insert("media_num", IdentificationCard);
		vKeyParams.Insert("tariff_id", Rate);
		vKeyParams.Insert("pointsale", GetPSALID());
		vKeyParams.Insert("Workstation",  String(SessionParameters.CurrentWorkstation));
		vKeyParams.Insert("Hotel", String(SessionParameters.CurrentHotel));
		vKeyParams.Insert("User", String(SessionParameters.CurrentUser));
		// Check card in ISD
		vRes = ISD.TestCard(ExternalSystemInteraction, vKeyParams);
		If Not vRes.Success Then
			ReplaceCardHelpMessage = ?(Not IsBlankString(vRes.StatusDescription), vRes.StatusDescription, vRes.MapResponse.Get("descr"));
			Items.ReplaceCardHelpMessage.BackColor = tcCommonFunctionOnClientServer.ColorConstructor(255, 202, 197);
			IdentificationCard = "";
		Else    
			vMediaNum = vRes.MapResponse.Get("media_num");
			If vMediaNum <> Undefined Then
				IdentificationCard = vMediaNum;	
				vCard = cmGetClientIdentificationCardById(IdentificationCard);
				If ValueIsFilled(vCard) Then
					ReplaceCardHelpMessage = NStr("en='This card is already registered!';ru='Эта карта уже зарегистрирована!';de='Diese Karte ist bereits registriert!'") + " " + String(vCard);
					Items.ReplaceCardHelpMessage.BackColor = tcCommonFunctionOnClientServer.ColorConstructor(255, 202, 197);
					IdentificationCard = "";
					Return;
				EndIf;	
			EndIf;

			vKeyParams = New Structure;   
			vKeyParams.Insert("media_num", IdentificationCard);
			vKeyParams.Insert("pointsale", GetPSALID());
			vKeyParams.Insert("Workstation",  String(SessionParameters.CurrentWorkstation));
			vKeyParams.Insert("Hotel", String(SessionParameters.CurrentHotel));
			vKeyParams.Insert("User", String(SessionParameters.CurrentUser));

			vRes = ISD.ClearCard(ExternalSystemInteraction, vKeyParams);
			If Not vRes.Success Then   
				If IsBlankString(vRes.StatusDescription) Then
					ReplaceCardHelpMessage = vRes.MapResponse.Get("descr");
				Else	
					ReplaceCardHelpMessage = vRes.StatusDescription; 
				EndIf;
				Items.ReplaceCardHelpMessage.BackColor = tcCommonFunctionOnClientServer.ColorConstructor(255, 202, 197);
				IdentificationCard = "";
			Else
				CloseForm = True;
			EndIf;
		EndIf;	
	Else	
		// Get params for query
		vKeyParams = New Structure;   
		vKeyParams.Insert("media_num", IdentificationCard);
		vKeyParams.Insert("pointsale", GetPSALID());
		vKeyParams.Insert("Workstation",  String(SessionParameters.CurrentWorkstation));
		vKeyParams.Insert("Hotel", String(SessionParameters.CurrentHotel));
		vKeyParams.Insert("User", String(SessionParameters.CurrentUser));

		vRes = ISD.CardInfo(ExternalSystemInteraction, vKeyParams);
		If vRes.Success Then  
			vMediaNum = vRes.MapResponse.Get("media_num");
			If vMediaNum <> Undefined Then
				IdentificationCard = vMediaNum;	
			EndIf;
			vParams = Catalogs.DataConvertationRules.JSONtoStructure(vRes.RawResponse);
			If vParams.Property("client") Then
				Guest = TrimAll(vParams.client);
				If Not IsBlankString(Guest) Then
					Title = Guest;
				EndIf;
			ElsIf vParams.Property("descr") Then
				If Not IsBlankString(vParams.descr) Then
					Title = vParams.descr;
				EndIf;
			EndIf;	
			If vParams.Property("release") Then
				CheckInDate = TrimAll(vParams.release);
			EndIf;
			If vParams.Property("stop") Then
				CheckOutDate = TrimAll(vParams.stop);
			EndIf;
			If vParams.Property("usedatleastonce") Then
				UsedAtleastOnce = vParams.usedatleastonce;
			EndIf;
			If vParams.Property("bonus_bal") Then
				DiscountBalance = vParams.bonus_bal;
			EndIf;
			If vParams.Property("diskt_name") Then
				DiscountType = vParams.diskt_name;
			EndIf;
			If vParams.Property("parking") Then
				If TypeOf(vParams.parking) = Type("Structure") Then
					vParkingArr = vParams.parking;
					If vParkingArr.Property("tariff") Then
						Parking = TrimAll(vParkingArr.tariff);
					EndIf;	
					If vParkingArr.Property("Brand") Then
						Brand = TrimAll(vParkingArr.Brand);
					EndIf;	
					If vParkingArr.Property("Model") Then
						Model = TrimAll(vParkingArr.Model);
					EndIf;	
					If vParkingArr.Property("Plate") Then
						Plate = TrimAll(vParkingArr.Plate);
					EndIf;	
					If vParkingArr.Property("usedatleastonce") Then
						ParkingUsedAtleastOnce = TrimAll(vParkingArr.usedatleastonce);
					EndIf;
					If vParkingArr.Property("location") Then
						Location = TrimAll(vParkingArr.location);
					EndIf;
				EndIf;
			Else
				Parking = "";
				Brand = "";
				Model = "";
				Plate = "";
				ParkingUsedAtleastOnce = "";
				Location = "";
			EndIf;
			If vParams.Property("ticket") Then
				Rate = TrimAll(vParams.ticket);
			EndIf;
			If vParams.Property("validto") Then
				ValidTo = TrimAll(vParams.validto);
			EndIf;
			HelpMessage = vRes.RawResponse;
		Else
			Title = "";
			CheckInDate 		= Undefined;
			CheckOutDate 		= Undefined;
			Guest				= Undefined;
			HelpMessage 		= Undefined;
			Parking 			= Undefined;
			Rate 				= Undefined;
			Brand 				= Undefined;
			Model 				= Undefined;
			Plate 				= Undefined;
			ValidTo 			= Undefined;

			HelpMessage = vRes.StatusDescription;
			If Not IsBlankString(HelpMessage) Then
				Title = HelpMessage;
			EndIf;
		EndIf;	
		
		Card = cmGetClientIdentificationCardById(IdentificationCard);
		If ValueIsFilled(Card) And ValueIsFilled(Card.DateTimeFrom) And ValueIsFilled(Card.DateTimeTo) Then
		    CheckInDate = Card.DateTimeFrom;
			CheckOutDate = Card.DateTimeTo;
		EndIf;
		PageType = 1; // Show card info
		SetPage();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure DeleteCard(pCard)
	// Delete card
	vCardRef = cmGetClientIdentificationCardById(pCard);
	If ValueIsFilled(vCardRef) Then
		vCardObj = vCardRef.GetObject();
		vCardObj.SetDeletionMark(True);
	EndIf; 
EndProcedure	

// -----------------------------------------------------------------------------
&AtServer
Procedure GetTransaction()
	If Not CheckCard() Then
		Return;
	EndIf;
	Transactions.Clear();
	// Get params for query
	vKeyParams = New Structure;   
	vKeyParams.Insert("media_num", IdentificationCard);
	vKeyParams.Insert("pointsale", GetPSALID());
	vKeyParams.Insert("Workstation", String(SessionParameters.CurrentWorkstation));
	vKeyParams.Insert("Hotel", String(SessionParameters.CurrentHotel));
	vKeyParams.Insert("User", String(SessionParameters.CurrentUser));

	vRes = ISD.GetDetails(ExternalSystemInteraction, vKeyParams);
	If vRes.Success Then
		vParams = Catalogs.DataConvertationRules.JSONtoStructure(vRes.RawResponse);
		If vParams.Property("cardDetails") Then
			vIdRow = 1;
			For Each vRow In vParams.cardDetails Do
				vNewRow = Transactions.Add();
				vNewRow.RowNumber = vIdRow;
				If vRow.Property("act") Then
					vNewRow.Action = vRow.act;
				EndIf;
				If vRow.Property("dev") Then
					vNewRow.Source = vRow.dev;
				EndIf;
				If vRow.Property("dt") Then
					vNewRow.Period = vRow.dt;
				EndIf;
				If vRow.Property("sys") Then
					vNewRow.System = vRow.sys;
				EndIf;
				vIdRow = vIdRow + 1;
			EndDo;
		EndIf;
		HelpMessage = vRes.RawResponse;
	Else
		HelpMessage = vRes.StatusDescription;
		If Not IsBlankString(HelpMessage) Then
			Title = HelpMessage;
		EndIf;
	EndIf;
	PageType = 2; // Show card info
	SetPage();
EndProcedure

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetCardIDPresantation(pID)
	vID = pID;
	Try
		If StrLen(pID) = 20 Then
			vID = Format(Number(pID), "NG=4,4,4,4,4");
		ElsIf StrLen(pID) = 16 Then
			vID =  Format(Number(GetBinaryDataBufferFromHexString(pID).ReadInt64(0, ByteOrder.BigEndian)), "NG=4,4,4,4,4");
		EndIf;	
	Except
	EndTry;
	
	Return vID;
EndFunction //  GetCardIDPresantation()

// -----------------------------------------------------------------------------
&AtServer
Function CheckCard()
	If Not IsBlankString(IdentificationCard)  And ValueIsFilled(ExternalSystemInteraction) Then
		vCard = cmGetClientIdentificationCardById(IdentificationCard);
		If ValueIsFilled(vCard) Then
			vKeyParams = New Structure;   
			vKeyParams.Insert("media_num", IdentificationCard);
			vKeyParams.Insert("pointsale", GetPSALID());
			vKeyParams.Insert("Workstation",  String(SessionParameters.CurrentWorkstation));
			vKeyParams.Insert("Hotel", String(SessionParameters.CurrentHotel));
			vKeyParams.Insert("User", String(SessionParameters.CurrentUser));
			// Check card in ISD
			vRes = ISD.IsReplacedCard(ExternalSystemInteraction, vKeyParams);
			If Not vRes.Success Then
				ReplaceCardHelpMessage = ?(Not IsBlankString(vRes.StatusDescription), vRes.StatusDescription, vRes.MapResponse.Get("descr"));
				Items.ReplaceCardHelpMessage.BackColor = tcCommonFunctionOnClientServer.ColorConstructor(255, 202, 197);
				IdentificationCard = "";
				Return False;
			Else
				vNewCardID = vRes.MapResponse.Get("actual_media_num");
				If ValueIsFilled(vNewCardID) Then
					ReplaceCard = vNewCardID;
					vCardObj = vCard.GetObject();
					vCardObj.Identifier = vNewCardID;
					vCardObj.Write();
					IdentificationCard = vNewCardID;
					CardPresantation = GetCardIDPresantation(IdentificationCard);
				EndIf;	
			EndIf;
		EndIf;
	EndIf;
	Return True;
EndFunction  // CheckCard()

#EndRegion  
