#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("DiscountCard") Then   
		DiscountCard = Parameters.DiscountCard;  
		Client = DiscountCard.Client;
	EndIf; 
	If ValueIsFilled(DiscountCard.DiscountType) And DiscountCard.DiscountType.ExternalBonusSystemIsUsed And ValueIsFilled(DiscountCard.DiscountType.ExternalInteraction) Then
		ExternalInteraction = DiscountCard.DiscountType.ExternalInteraction;
		If ExternalInteraction.IntegrationType = Enums.Integrations.ISD Then
			Items.Identifier.ReadOnly = True;	
		EndIf;	
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(Cancel)  
	If Not ValueIsFilled(DiscountCard) Then 
		ShowMessageBox(New NotifyDescription("CloseForm", ThisObject), Nstr("en = 'Card ref not sent'; de = 'Kartenreferenz nicht gesendet'; ru = 'Не передана ссылка на карту'"));
	EndIf; 
	CurrentItem = Items.Identifier;
EndProcedure

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
	
	If vEventData.DeviceType = "MagneticStripeCardReader" Then
		Identifier = GetCardIDPresantation(vEventData.DeviceData, ExternalInteraction);
		ReplaceCard();
		If IsBlankString(LabelNotification) Then
			Notify("Catalog.DiscountCards.Changed", Client);
			Close();
		EndIf;
	EndIf;
EndProcedure // ExternalEvent

#EndRegion

#Region FormCommandsEventHandlers

 // -----------------------------------------------------------------------------
&AtClient
Procedure Replacing(Command)
	If CheckFilling() Then
		ReplaceCard();
		If IsBlankString(LabelNotification) Then
			Notify("Catalog.DiscountCards.Changed", Client);
			Close();
		EndIf;	
	EndIf;	

EndProcedure

#EndRegion

#Region Private
 
 // -----------------------------------------------------------------------------
&AtClient
Procedure CloseForm(pParams) Export
	ThisForm.Close();	
EndProcedure

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetCardIDPresantation(pID, pExternalInteraction)  
	If ValueIsFilled(pExternalInteraction) And pExternalInteraction.IntegrationType = Enums.Integrations.ISD Then 
		vID = pID;
		Try
			If Not StrLen(pID) = 20 Then
				vID =  Format(Number(GetBinaryDataBufferFromHexString(pID).ReadInt64(0, ByteOrder.BigEndian)),"NG=0");
			EndIf;	
		Except
		EndTry;
	EndIf;
	Return vID;
EndFunction //  GetCardIDPresantation()

// -----------------------------------------------------------------------------
&AtServer
Function GetISDTestCardParams(pCardID, pRateCode) 
	vKeyParams = New Structure;   
	vKeyParams.Insert("media_num", pCardID);
	vKeyParams.Insert("tariff_id", pRateCode); 
	vKeyParams.Insert("pointsale", ISD.GetPSALID(ExternalInteraction));
	vKeyParams.Insert("Workstation",  String(SessionParameters.CurrentWorkstation));
	vKeyParams.Insert("Hotel", String(SessionParameters.CurrentHotel));
	vKeyParams.Insert("User", String(SessionParameters.CurrentUser));
	Return vKeyParams;
EndFunction  

// -----------------------------------------------------------------------------   
&AtServer
Procedure ReplaceCard()
	If IsBlankString(Identifier) Then
		Return;
	EndIf;   
	LabelNotification = "";
	// Try to search discount card with this Id
	vDiscountCard = cmGetDiscountCardById(TrimAll(Identifier));
	If ValueIsFilled(vDiscountCard) And vDiscountCard.Client <> DiscountCard.Client Then
		LabelNotification = NStr("en='This card is already registered!';ru='Эта карта уже зарегистрирована!';de='Diese Karte ist bereits registriert!'") + " " + String(vDiscountCard);
		Items.LabelNotification.Visible = True;
		Return;
	EndIf;  
	// Update data from ISD
	If ValueIsFilled(ExternalInteraction) And ExternalInteraction.IntegrationType = Enums.Integrations.ISD Then 
		// Call ISD
		ReplaceInISD(); 
	Else
		// Update
		vDCObj = DiscountCard.GetObject(); 
		If Not IsBlankString(Remarks) Then
			vDCObj.Remarks = Remarks;
		EndIf;
		vDCObj.Identifier = Identifier; 
		vDCObj.Write();
	EndIf; 
EndProcedure

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetTariff(pExternalInteraction, pIsMain = True)
	vHotel = SessionParameters.CurrentHotel;
	vTariff = "";
	vTariffs = InformationRegisters.ExternalSystemIntegrationData.GetData(pExternalInteraction, "BonusRates");  
	If vTariffs.Count() > 0 Then
		// Try find by hotel
		vFilter = vTariffs.FindRows(New Structure("IsDefault, Hotel", pIsMain, vHotel)); 	
		If vFilter.Count() > 0 Then  
			vRow = vFilter[0];
			vTariff = vRow.ISDCode;
		Else
			vFilter = vTariffs.FindRows(New Structure("IsDefault", pIsMain)); 	
			If vFilter.Count() > 0 Then  
				vRow = vFilter[0];
				vTariff = vRow.ISDCode;
			EndIf;
		EndIf;
	EndIf;
	
	Return vTariff;
EndFunction	

// -----------------------------------------------------------------------------   
&AtServer
Procedure ReplaceInISD()
	vTariff = GetTariff(ExternalInteraction, Not ValueIsFilled(DiscountCard.Parent)); 
	If IsBlankString(vTariff) Then
		LabelNotification = NStr("en = 'ISD tariff mapping not configured!'; de = 'ISD-Tarifzuordnung nicht konfiguriert!'; ru = 'Не настроен маппинг тарифов ISD!'");
		Items.LabelNotification.Visible = True;
		Return;
	EndIf; 
	vKeyParams = GetISDTestCardParams(Identifier, vTariff);
	// Check card in ISD
	vRes = ISD.TestCard(ExternalInteraction, vKeyParams);
	If Not vRes.Success Then
		LabelNotification = ?(Not IsBlankString(vRes.StatusDescription), vRes.StatusDescription, vRes.MapResponse.Get("descr"));
		Items.LabelNotification.Visible = True;
		Return;	
	EndIf;	
	vKeyParams = New Structure;   
	vKeyParams.Insert("Card",           Undefined);
	vKeyParams.Insert("KeyOldID", 		DiscountCard.Identifier);
	vKeyParams.Insert("KeyNewID",		Identifier);   
	vKeyParams.Insert("WorkstationID",	ISD.GetPSALID(ExternalInteraction));
	// 
	vRes = ISD.ReplaceCard(ExternalInteraction, vKeyParams);
	If Not vRes.Success Then
		LabelNotification = ?(Not IsBlankString(vRes.StatusDescription), vRes.StatusDescription, vRes.MapResponse.Get("descr"));
		Items.LabelNotification.Visible = True;
		Return;	
	EndIf;	
	// Update
	vDCObj = DiscountCard.GetObject(); 
	If Not IsBlankString(Remarks) Then
		vDCObj.Remarks = Remarks;
	EndIf;
	vDCObj.Identifier = Identifier; 
	vDCObj.Write();
EndProcedure
 
 #EndRegion
