
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		Items.List.ChangeRowSet = False;
	EndIf;             
	vCurWstn = SessionParameters.CurrentWorkstation;
	If ValueIsFilled(vCurWstn) Then
		If vCurWstn.HasConnectionToIdentityCardsProcessingSystem Then
			vIdentityCardSystemParameters = vCurWstn.IdentityCardsProcessingSystemParameters;  
			If ValueIsFilled(vIdentityCardSystemParameters.ExternalInteraction) Then   
				ExternalInteraction = vIdentityCardSystemParameters.ExternalInteraction; 
			EndIf;	
		EndIf;
	EndIf;     
	If Parameters.Property("SelMode") And Parameters.SelMode <> Undefined Then
		SelMode = Parameters.SelMode;	 
		If SelMode = 1 Then  
			Mode = 0;
			// Members(bonuses and discount)
			Items.Mode.ChoiceList.Delete(2);   
			Title = NStr("en = 'Members of the loyalty program'; de = 'Mitglieder des Treueprogramms'; ru = 'Участники программы лояльности'"); 
			Items.AmountValue.Visible = False;
		ElsIf SelMode = 2 Then
			Items.Mode.Visible = False;	   
			Title = NStr("en = 'Gift cards'; de = 'Beliebte Karten'; ru = 'Подарочные карты'");
		EndIf;	
	EndIf;	
	SetFormAppearance();
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
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
		// Try convert card id to dec for ISD
		vCardID = GetCardIdentifier(vEventData.DeviceData, ExternalInteraction);
		// Try to search discount card with this Id
		vDiscountCard = GetDiscountCardById(vCardID);
		If ValueIsFilled(vDiscountCard) Then
			OpenCard = vDiscountCard;
			OpenForm("Catalog.DiscountCards.ObjectForm",  New Structure("Key", OpenCard), ThisObject, UUID);
		Else
			vMsg = Nstr("en = 'Card with ID %1 not found!'; de = 'Karte mit ID %1 nicht gefunden!'; ru = 'Карта с ID %1 не найдена!'");
			ShowMessageBox(, StrTemplate(vMsg, vEventData.DeviceData));
		EndIf;
	EndIf;
EndProcedure // ExternalEvent

// --------------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "Catalog.DiscountCards.Changed" Then
		Items.List.Refresh();	    
		If ValueIsFilled(pSource) Then
			OpenForm("Catalog.DiscountCards.ObjectForm", New Structure("Key", pSource) , ThisObject, UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
		EndIf;	
	EndIf;	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SelClientOnChange(pItem)
	If ValueIsFilled(SelClient) Then
		AttributeChangeAtServer("Client", SelClient);
	Else
		ClearingAttributeAtServer("Client");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelDiscountTypeOnChange(Item)
	If ValueIsFilled(SelDiscountType) Then
		AttributeChangeAtServer("DiscountType", SelDiscountType);
	Else
		ClearingAttributeAtServer("DiscountType");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelAuthorOnChange(pItem)
	If ValueIsFilled(SelAuthor) Then
		AttributeChangeAtServer("Author", SelAuthor);
	Else
		ClearingAttributeAtServer("Author");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelAdditionalCardOnlyOnChange(pItem)
	If SelAdditionalCardOnly Then
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "ParentDiscountCard", 0, DataCompositionComparisonType.Filled, , True);
	Else
		ClearingAttributeAtServer("ParentDiscountCard");
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelConsumerOnChange(Item)
	If ValueIsFilled(SelConsumer) Then
		AttributeChangeAtServer("Consumer", SelConsumer);
	Else
		ClearingAttributeAtServer("Consumer");
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ModeOnChange(Item)
	SetFormAppearance();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure Add(pCommand)
	OpenForm("Catalog.DiscountCards.Form.tcIssueDiscountCard", , ThisObject, UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------  
&AtServer
Procedure SetFormAppearance()  
	vMembers = 1;
	vGiftCardsOnly = 2;  
	vDiscount = 3; 
	vAllCards = 0;   
	vFieldDesc = "LoyaltyType";
	
	If SelMode = vMembers Then   
		// Discounts and bonuses   
		vArr = New Array;
		vArr.Add(Enums.LoyaltyType.Discount);
		vArr.Add(Enums.LoyaltyType.Bonuses); 
		
		// Default
		If Mode = vAllCards Then   
			// All
			tcCommonFunctionOnClientServer.cmChangeFilterItems(List.SettingsComposer.Settings.Filter, vFieldDesc, , vArr, DataCompositionComparisonType.InList, True);
		ElsIf Mode = vDiscount Then
			// Discounts
			tcCommonFunctionOnClientServer.cmChangeFilterItems(List.SettingsComposer.Settings.Filter, vFieldDesc, , Enums.LoyaltyType.Discount, , True); 
		Else
			tcCommonFunctionOnClientServer.cmChangeFilterItems(List.SettingsComposer.Settings.Filter, vFieldDesc, , Enums.LoyaltyType.Bonuses, , True);
		EndIf; 	
	ElsIf SelMode = vGiftCardsOnly Then
		Mode = vGiftCardsOnly;
		// Gift cards
		tcCommonFunctionOnClientServer.cmChangeFilterItems(List.SettingsComposer.Settings.Filter, vFieldDesc, , Enums.LoyaltyType.Certificate, , True);
	Else	
		// Default
		If Mode = vAllCards Then
			// All
			tcCommonFunctionOnClientServer.cmChangeFilterItems(List.SettingsComposer.Settings.Filter, vFieldDesc, , , , False);
		ElsIf Mode = vGiftCardsOnly Then
			// Gift cards
			tcCommonFunctionOnClientServer.cmChangeFilterItems(List.SettingsComposer.Settings.Filter, vFieldDesc, , Enums.LoyaltyType.Certificate, , True);
		ElsIf Mode = vDiscount Then
			// Discounts
			tcCommonFunctionOnClientServer.cmChangeFilterItems(List.SettingsComposer.Settings.Filter, vFieldDesc, , Enums.LoyaltyType.Discount, , True); 
		Else
			tcCommonFunctionOnClientServer.cmChangeFilterItems(List.SettingsComposer.Settings.Filter, vFieldDesc, , Enums.LoyaltyType.Bonuses, , True);
		EndIf;  
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ListBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	If Not pClone Then
		pCancel = True;
		vLoyaltyType = Undefined;
		If Mode > 0 Then
			If Mode = 1 Then
				vLoyaltyType = PredefinedValue("Enum.LoyaltyType.Bonuses");
			ElsIf Mode = 2 Then
				vLoyaltyType = PredefinedValue("Enum.LoyaltyType.Certificate");
			ElsIf Mode = 3 Then
				vLoyaltyType = PredefinedValue("Enum.LoyaltyType.Discount");
			EndIf;
		Else
			vLoyaltyType = PredefinedValue("Enum.LoyaltyType.Certificate");
		EndIf;
		OpenForm("Catalog.DiscountCards.ObjectForm", New Structure("FillingValues", New Structure("Parent, LoyaltyType", pParent, vLoyaltyType)));
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenCardOnChange(pItem)
	If ValueIsFilled(OpenCard) Then
		OpenForm("Catalog.DiscountCards.ObjectForm", New Structure("Key", OpenCard), , OpenCard);
	EndIf;
EndProcedure // OpenCardOnChange

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetCardIdentifier(pCardData, pExternalInteraction)  
	vCardID = pCardData;
	If ValueIsFilled(pExternalInteraction) And pExternalInteraction.IntegrationType = Enums.Integrations.ISD Then
		Try
			If Not StrLen(vCardID) = 20 Then
				vCardID =  Format(Number(GetBinaryDataBufferFromHexString(vCardID).ReadInt64(0, ByteOrder.BigEndian)),"NG=0");
			EndIf;	
		Except
		EndTry;
	EndIf;
	Return vCardID;
EndFunction // GetCardIdentifier

// -----------------------------------------------------------------------------
&AtServer
Function GetDiscountCardById(pIdentifier, pSearchMarkedForDeletion = False)
	vDiscountCardRef = Catalogs.DiscountCards.EmptyRef();
	// Try to find discount card by identifier
	vQry =  New Query();
	vQry.Text = 
	"SELECT
	|	DiscountCards.Ref AS Ref
	|FROM
	|	Catalog.DiscountCards AS DiscountCards
	|WHERE
	|	(NOT DiscountCards.DeletionMark
	|			OR &qSearchMarkedForDeletion)
	|	AND DiscountCards.Identifier = &qIdentifier
	|
	|ORDER BY
	|	DiscountCards.Code";
	vQry.SetParameter("qIdentifier", TrimAll(pIdentifier));
	vQry.SetParameter("qSearchMarkedForDeletion", pSearchMarkedForDeletion);
	vDiscountCards = vQry.Execute().Unload();
	If vDiscountCards.Count() > 0 Then
		vDiscountCardRef = vDiscountCards.Get(0).Ref;
	EndIf;
	Return vDiscountCardRef;
EndFunction // GetDiscountCardById

// -----------------------------------------------------------------------------
&AtServer
Procedure AttributeChangeAtServer(pAttribute, pValue, pComparisonType = Undefined)
	If ValueIsFilled(pValue) Then
		vComparisonType = ?(pComparisonType = Undefined, DataCompositionComparisonType.Equal, pComparisonType);
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, pAttribute, pValue, vComparisonType, , True);
	EndIf;
EndProcedure // AttributeChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ClearingAttributeAtServer(pAttribute)
	tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, pAttribute, , , , False);
EndProcedure // ClearingAttributeAtServer

#EndRegion
