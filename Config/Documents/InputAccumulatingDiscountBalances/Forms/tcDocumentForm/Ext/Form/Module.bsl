
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	vObj = FormAttributeToValue("Object"); 
	If vObj.IsNew() Then
		// Use current time by default
		vObj.SetTime(AutoTimeMode.CurrentOrLast);
		// Fill attributes with default values
		If Not ValueIsFilled(vObj.Author) Then
			vObj.pmFillAttributesWithDefaultValues();
		Else
			vObj.pmFillAuthorAndDate();
		EndIf;  		  
	Else
	    // Check edit prohibited date
		If ValueIsFilled(vObj.Hotel) Then
			If ValueIsFilled(vObj.Hotel.EditProhibitedDate) And 
				BegOfDay(vObj.Hotel.EditProhibitedDate) >= BegOfDay(vObj.Date) Then
				ThisForm.ReadOnly = True;
			EndIf;
		EndIf;  
	EndIf;
	// User rights to open item
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		pCancel = True;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights for services and prices management!';ru='Нет прав на управление услугами и ценами!';de='Sie haben keine Rechte, Dienstleistungen und Preise zu verwalten!'"));
	EndIf;
	// Set object back to form attributes
	ValueToFormAttribute(vObj, "Object");
	// Form appearance
	SetFormAppearance();
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	Var vMessage; 
	Var vAttributeInErr;
	// Before posting actions
	If pWriteParameters.WriteMode = DocumentWriteMode.Posting Then
		// Check document attributes 		
		pCancel = CheckDocumentAttributesAtServer(vMessage, vAttributeInErr);
		If pCancel Then
			tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
		Else
			// Always undo posting first to repost document
			If Object.Posted Then
				pWriteParameters.WriteMode = DocumentWriteMode.Write;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

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
		vCardRowId = AddDiscountCard(vEventData.DeviceData);
		If vCardRowId >= 0 Then
			Items.Balances.CurrentRow = vCardRowId;
			ThisForm.CurrentItem = Items.BalancesBonus;
		EndIf;
	EndIf;
EndProcedure // ExternalEvent

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountTypeOnChange(pItem)
	DiscountTypeOnChangeAtServer(); 
EndProcedure // DiscountTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure BalancesOnStartEdit(pItem, pNewRow, pClone)    
	BalancesOnStartEditAtServer();
EndProcedure // BalancesOnStartEdit

// --------------------------------------------------------------------------------
&AtClient
Procedure BalancesOnEditEnd(pItem, pNewRow, pCancelEdit)
	// Appearance	
	If ValueIsFilled(Object.Ref) And ValueIsFilled(Object.DiscountType) Then
		If Object.Balances.Count() > 0 Then
			Items.DiscountType.ReadOnly = True;
		Else
			Items.DiscountType.ReadOnly = False;
		EndIf;
	EndIf;
	If ValueIsFilled(Object.DiscountType) Then
		Items.Balances.ChangeRowSet = True;
	Else
		Items.Balances.ChangeRowSet = False;
	EndIf;
EndProcedure // BalancesOnEditEnd

// --------------------------------------------------------------------------------
&AtClient
Procedure BalancesAfterDeleteRow(pItem)
	// Appearance	
	If ValueIsFilled(Object.Ref) And ValueIsFilled(Object.DiscountType) Then
		If Object.Balances.Count() > 0 Then
			Items.DiscountType.ReadOnly = True;
		Else
			Items.DiscountType.ReadOnly = False;
		EndIf;
	EndIf;
	If ValueIsFilled(Object.DiscountType) Then
		Items.Balances.ChangeRowSet = True;
	Else
		Items.Balances.ChangeRowSet = False;
	EndIf;
EndProcedure // BalancesAfterDeleteRow

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure SetFormAppearance()
	If ValueIsFilled(Object.DiscountType) Then
		If Object.DiscountType.IsAccumulatingDiscount Then
			Items.BalancesDiscountDimension.ChoiceParameters = New FixedArray(New Array());
			If Object.DiscountType.AccumulatingDiscountDimension = Enums.AccumulatingDiscountDimensions.Client Then
				Items.BalancesDiscountDimension.ChooseType = False;
				Items.BalancesDiscountDimension.TypeRestriction = cmGetCatalogTypeDescription("Clients");
			ElsIf Object.DiscountType.AccumulatingDiscountDimension = Enums.AccumulatingDiscountDimensions.Customer Then
				Items.BalancesDiscountDimension.ChooseType = False;
				Items.BalancesDiscountDimension.TypeRestriction = cmGetCatalogTypeDescription("Customers");
			ElsIf Object.DiscountType.AccumulatingDiscountDimension = Enums.AccumulatingDiscountDimensions.Agent Then
				Items.BalancesDiscountDimension.ChooseType = False;
				Items.BalancesDiscountDimension.TypeRestriction = cmGetCatalogTypeDescription("Customers");
			ElsIf Object.DiscountType.AccumulatingDiscountDimension = Enums.AccumulatingDiscountDimensions.Contract Then
				Items.BalancesDiscountDimension.ChooseType = False;
				Items.BalancesDiscountDimension.TypeRestriction = cmGetCatalogTypeDescription("Contracts");
			ElsIf Object.DiscountType.AccumulatingDiscountDimension = Enums.AccumulatingDiscountDimensions.DiscountCard Then
				Items.BalancesDiscountDimension.ChooseType = False;
				Items.BalancesDiscountDimension.TypeRestriction = cmGetCatalogTypeDescription("DiscountCards");
				vArray = New Array();
				vArray.Add(New ChoiceParameter("Filter.DiscountType", Object.DiscountType));
				Items.BalancesDiscountDimension.ChoiceParameters = New FixedArray(vArray);
			Else
				Items.BalancesDiscountDimension.ChooseType = True;
				vAccumulationDiscountDimensionTypes = New Array();
				vAccumulationDiscountDimensionTypes.Add(cmGetCatalogTypeDescription("DiscountCards"));
				vAccumulationDiscountDimensionTypes.Add(cmGetCatalogTypeDescription("Clients"));
				vAccumulationDiscountDimensionTypes.Add(cmGetCatalogTypeDescription("Customers"));
				vAccumulationDiscountDimensionTypes.Add(cmGetCatalogTypeDescription("Contracts"));
				Items.BalancesDiscountDimension.TypeRestriction = New TypeDescription(vAccumulationDiscountDimensionTypes);
			EndIf;
		ElsIf Object.DiscountType.LoyaltyType = Enums.LoyaltyType.Bonuses Then
			Items.BalancesDiscountDimension.ChooseType = False;
			Items.BalancesDiscountDimension.TypeRestriction = cmGetCatalogTypeDescription("DiscountCards");
			vArray = New Array();
			vArray.Add(New ChoiceParameter("Filter.DiscountType", Object.DiscountType));
			Items.BalancesDiscountDimension.ChoiceParameters = New FixedArray(vArray);
		EndIf;
	Else
		Items.BalancesDiscountDimension.ChoiceParameters = New FixedArray(New Array());
		Items.BalancesDiscountDimension.ChooseType = True;
		vAccumulationDiscountDimensionTypes = New Array();
		vAccumulationDiscountDimensionTypes.Add(cmGetCatalogTypeDescription("DiscountCards"));
		vAccumulationDiscountDimensionTypes.Add(cmGetCatalogTypeDescription("Clients"));
		vAccumulationDiscountDimensionTypes.Add(cmGetCatalogTypeDescription("Customers"));
		vAccumulationDiscountDimensionTypes.Add(cmGetCatalogTypeDescription("Contracts"));
		Items.BalancesDiscountDimension.TypeRestriction = New TypeDescription(vAccumulationDiscountDimensionTypes);
	EndIf;
	If ValueIsFilled(Object.Ref) And ValueIsFilled(Object.DiscountType) Then
		If Object.Balances.Count() > 0 Then
			Items.DiscountType.ReadOnly = True;
		Else
			Items.DiscountType.ReadOnly = False;
		EndIf;
	Endif;
	If ValueIsFilled(Object.DiscountType) Then
		Items.Balances.ChangeRowSet = True;
	Else
		Items.Balances.ChangeRowSet = False;
	EndIf;
	If ValueIsFilled(Object.DiscountType) Then
		If Object.DiscountType.IsAccumulatingDiscount Then
			Items.Source.Visible = False;
			If ValueIsFilled(Object.Source) Then
				Object.Source = Undefined;
			EndIf;
			If Object.DiscountType.BonusCalculationFactor <> 0 Then
				Items.BalancesResource.Visible = True;
				Items.BalancesBonus.Visible = True;
			Else
				Items.BalancesResource.Visible = True;
				Items.BalancesBonus.Visible = False;
			EndIf; 
		ElsIf Object.DiscountType.LoyaltyType = Enums.LoyaltyType.Bonuses Then
			Items.Source.Visible = True;
			Items.BalancesResource.Visible = False;
			Items.BalancesBonus.Visible = True;
		EndIf;
	Else
		Items.Source.Visible = False;
		Items.BalancesResource.Visible = False;
		Items.BalancesBonus.Visible = False;
		If ValueIsFilled(Object.Source) Then
			Object.Source = Undefined;
		EndIf;
	EndIf;
EndProcedure // SetFormAppearance

// -----------------------------------------------------------------------------
&AtServer
Procedure DiscountTypeOnChangeAtServer()
	// Appearance	
	SetFormAppearance();
EndProcedure // DiscountTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function CheckDocumentAttributesAtServer(pMessage, pAttributeInErr)
	vObj = FormAttributeToValue("Object");	
	Return vObj.pmCheckDocumentAttributes(pMessage, pAttributeInErr);   
EndFunction // CheckDocumentAttributesAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure BalancesOnStartEditAtServer()
	If ValueIsFilled(Object.DiscountType) Then
		vCurRow = Object.Balances.FindByID(Items.Balances.CurrentRow);
		If vCurRow <> Undefined Then
			If Object.DiscountType.AccumulatingDiscountDimension = Enums.AccumulatingDiscountDimensions.DiscountCard Then
				If TypeOf(vCurRow.DiscountDimension) <> Type("CatalogRef.DiscountCards") Then
					vCurRow.DiscountDimension = Catalogs.DiscountCards.EmptyRef();
				EndIf;
			ElsIf Object.DiscountType.AccumulatingDiscountDimension = Enums.AccumulatingDiscountDimensions.Client Then
				If TypeOf(vCurRow.DiscountDimension) <> Type("CatalogRef.Clients") Then
					vCurRow.DiscountDimension = Catalogs.Clients.EmptyRef();
				EndIf;
			Else
				If TypeOf(vCurRow.DiscountDimension) <> Type("CatalogRef.Customers") Then
					vCurRow.DiscountDimension = Catalogs.Customers.EmptyRef();
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // BalancesOnStartEditAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetDiscountCardById(pIdentifier, pSearchMarkedForDeletion = False) 
	Return cmGetDiscountCardById(pIdentifier);
EndFunction // cmGetDiscountCardById

// --------------------------------------------------------------------------------
&AtServer
Function AddDiscountCard(pCardID)
	vCardRow = Undefined;	
	If ValueIsFilled(Object.DiscountType) And Object.DiscountType.AccumulatingDiscountDimension = Enums.AccumulatingDiscountDimensions.DiscountCard Then
		vDiscountCard = GetDiscountCardById(pCardID);
		If ValueIsFilled(vDiscountCard) Then
			// Try to find this card in list
			vCardRows = Object.Balances.FindRows(New Structure("DiscountDimension", vDiscountCard));
			If vCardRows.Count() = 0 Then
				vCardRow = Object.Balances.Add();
				vCardRow.DiscountDimension = vDiscountCard;
			Else
				vCardRow = vCardRows.Get(vCardRows.Count() - 1);
			EndIf;
		EndIf;
	EndIf;
	If vCardRow = Undefined Then
		Return -1;
	Else
		Return vCardRow.GetID();
	EndIf;
EndFunction // AddDiscountCard  	

#EndRegion
