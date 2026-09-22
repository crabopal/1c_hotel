
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)   
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	If Object.Ref.IsEmpty() Then
		If Not ValueIsFilled(Object.Author) Then
			Object.Author = SessionParameters.CurrentUser;
		EndIf;
		If Parameters.IsExpense Then
			Object.OperationType = Enums.BonusesOperationTypes.Expense;
		Else
			Object.OperationType = Enums.BonusesOperationTypes.Receipt;
		EndIf;
		Object.Hotel = SessionParameters.CurrentHotel;
		If Not ValueIsFilled(Object.Source) Then
			If Object.OperationType = Enums.BonusesOperationTypes.Expense Then
				Object.Source = Catalogs.BonusOperationSources.EmptyRef();
			Else
				Object.Source = "";
			EndIf;
		EndIf;
		Items.FormSetDeletionMarkAction.Visible = False;
	Else
		Items.FormSetDeletionMarkAction.Visible = True;
		// Check rights to edit posted document
		If Not cmCheckUserPermissions("HavePermissionToEditPostedFolioTransactions") Then
			ReadOnly = True;
			Items.FormSetDeletionMarkAction.Visible = False;
		EndIf;
		// Check edit prohibited dates
		If Not ReadOnly Then
			If ValueIsFilled(Object.Hotel) Then
				If ValueIsFilled(Object.Hotel.EditProhibitedDate) And BegOfDay(Object.Hotel.EditProhibitedDate) >= BegOfDay(Object.Date) Then
					ReadOnly = True;
					Items.FormSetDeletionMarkAction.Visible = False;
				EndIf;
			EndIf;
		EndIf;
		// Check hotel accounting date
		If Not ReadOnly Then
			If ValueIsFilled(Object.Hotel) Then
				If Object.Hotel.DoNotEditClosedDateDocs And ValueIsFilled(Object.Hotel.AccountingDate) And Object.Date < BegOfDay(Object.Hotel.AccountingDate) Then
					ReadOnly = True;
					Items.FormSetDeletionMarkAction.Visible = False;
				EndIf;
			EndIf;   
			If ValueIsFilled(Object.Card) And ValueIsFilled(Object.Card.DiscountType) Then  
				ReadOnly = Object.Card.DiscountType.ExternalBonusSystemIsUsed;	
			EndIf;	
		EndIf;    
	EndIf;
	If ValueIsFilled(Parameters.DiscountCard) Then
		Object.Card = Parameters.DiscountCard;
		Object.Guest = Parameters.DiscountCard.Client;
		Items.Card.ReadOnly = True;
		Items.Client.ReadOnly = True;
	EndIf;	
	If TypeOf(Object.Source) = Type("String") Or TypeOf(Object.Source) = Type("CatalogRef.BonusOperationSources") Then
		Items.Source.ChooseType = False;
	Else
		Items.Source.ChooseType = True;
	EndIf; 
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);	
	
	// User rights
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	Notify("BonusesChanged");
EndProcedure // AfterWrite

// --------------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	If Object.BonusesQuantity = 0 Then
		Message = New UserMessage;
		Message.Text = Nstr("ru = 'Необходимо указать кол-во бонусов в операции!'; en = 'You must specify the bonuses quantity of the operation!'; de = 'Sie müssen den Boni-Menge der Operation angeben!'");
		Message.Field = "Object.BonusesQuantity";
		Message.Message();
		pCancel = True;
	EndIf;	
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	If pWriteParameters.WriteMode = DocumentWriteMode.Posting Then
		pCurrentObject.AdditionalProperties.Insert("DoCheckBalance", True);
	EndIf;
EndProcedure // BeforeWriteAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure FillCheckProcessingAtServer(pCancel, pCheckedAttributes)
	vObj = FormAttributeToValue("Object");
	pCancel = tcOnServer.cmFillCheckProcessingForm(pCheckedAttributes, CheckedAttributesManual, vObj);
EndProcedure

#EndRegion    

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure SourceOnChange(pItem)
	SourceOnChangeAtServer();
EndProcedure // SourceOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure SourceClearing(pItem, pStandardProcessing)
	Object.Source = Undefined;
EndProcedure // SourceClearing

// --------------------------------------------------------------------------------
&AtClient
Procedure ClientStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // ClientStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure ClientClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // ClientClearing

// --------------------------------------------------------------------------------
&AtClient
Procedure CardOnChange(pItem)
	CardOnChangeAtServer();
EndProcedure // CardOnChange

#EndRegion                   

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SetDeletionMarkAction(pCommand)
	If Not ValueIsFilled(Object.Ref) Then
		Return;
	EndIf;
	If Modified Then
		Modified = False;
	EndIf;
	SetDeletionMarkAtServer();
	Read();
	Notify("BonusesChanged");
	Close();
EndProcedure // SetDeletionMarkAction

#EndRegion     

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure SourceOnChangeAtServer()
	If TypeOf(Object.Source) = Type("String") Then
		Items.Source.ChooseType = False;
	ElsIf TypeOf(Object.Source) = Type("CatalogRef.BonusOperationSources") Then
		Items.Source.ChooseType = False;
		If ValueIsFilled(Object.Source) And Object.Source.BonusesQuantity <> 0 And Object.BonusesQuantity = 0 Then
			Object.BonusesQuantity = Object.Source.BonusesQuantity;
			If Object.Source.IsPerDay And ValueIsFilled(Object.GuestGroup) And 
			   ValueIsFilled(Object.GuestGroup.CheckInDate) And ValueIsFilled(Object.GuestGroup.CheckOutDate) And 
			   BegOfDay(Object.GuestGroup.CheckOutDate) > BegOfDay(Object.GuestGroup.CheckInDate) Then
				Object.BonusesQuantity = Object.BonusesQuantity * (BegOfDay(Object.GuestGroup.CheckOutDate) - BegOfDay(Object.GuestGroup.CheckInDate))/(24*3600);
			EndIf;
		EndIf;
	Else
		Items.Source.ChooseType = True;
	EndIf;
EndProcedure // SourceOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SetDeletionMarkAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.Read();
	vObj.SetDeletionMark(True);
	ValueToFormAttribute(vObj, "Object");
EndProcedure // SetDeletionMarkAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure CardOnChangeAtServer()
	Object.BonusesValidity = 0;
	vCard = Object.Card;
	If ValueIsFilled(vCard) Then
		vDiscountType = vCard.DiscountType;
		If ValueIsFilled(vDiscountType) And vDiscountType.BonusesValidity > 0 Then
			Object.BonusesValidity = vDiscountType.BonusesValidity;
		EndIf;
	EndIf;
EndProcedure // CardOnChangeAtServer

#EndRegion
