// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);

	If Not ValueIsFilled(Object.Ref) Then
		// Fill attributes with default values
		If Not ValueIsFilled(Object.Hotel) Then
			If ValueIsFilled(Object.RoomQuota) Then
				Object.Hotel = Object.RoomQuota.Hotel;
			Else
				Object.Hotel = SessionParameters.CurrentHotel;
			EndIf;
		EndIf;
		If Not ValueIsFilled(Object.Currency) Then
			If ValueIsFilled(Object.Hotel) Then
				Object.Currency = Object.Hotel.FolioCurrency;
			EndIf;
		EndIf;
		If Not Object.IsFolder Then
			If Not ValueIsFilled(Object.CreateDate) Then
				Object.CreateDate = CurrentSessionDate();
				Object.Author = SessionParameters.CurrentUser;
			EndIf;
		EndIf;
		// Process description
		DescriptionOnChangeAtServer();
	EndIf;
	
	// Check user rights to edit period
	If Not cmCheckUserPermissions("HavePermissionToSetFixedPeriodForTheHotelProduct") Then
		Items.FixProductPeriod.Enabled = False;
		Items.CheckInDate.Enabled = False;
		Items.Duration.Enabled = False;
		Items.CheckOutDate.Enabled = False;
		Items.CreateDate.Enabled = False;
	EndIf;
	
	// Check user rights to edit sum
	If Not cmCheckUserPermissions("HavePermissionToSetFixedCostForTheHotelProduct") Then
		Items.FixProductCost.Enabled = False;
		Items.Sum.Enabled = False;
		Items.Currency.Enabled = False;
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtServer
Function BeforeWriteAtServer(rMessage, rAttributeInErr, rDescriptionIsSet, rCodeIsSet)
	vObj = FormDataToValue(Object, Type("CatalogObject.HotelProducts"));
	// Check if description is set
	rDescriptionIsSet = False;
	If IsBlankString(vObj.Description) And 
	   ValueIsFilled(vObj.RoomType) And
	   ValueIsFilled(vObj.CheckInDate) And 
	   ValueIsFilled(vObj.CheckOutDate) Then
		vObj.Description = vObj.pmGetDefaultDescription();
		rDescriptionIsSet = True;
	EndIf;
	// Check if code is set
	rCodeIsSet = False;
	If IsBlankString(vObj.Code) Then
		vObj.Code = vObj.pmGetDefaultCode();
		rCodeIsSet = True;
	EndIf;
	vCancel = vObj.pmCheckHotelProductAttributes(rMessage, rAttributeInErr);
	ValueToFormData(vObj, Object);
	Return vCancel;
EndFunction

// --------------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	Var vMessage, vAttributeInErr, vDescriptionIsSet, vCodeIsSet;
	vCancel = BeforeWriteAtServer(vMessage, vAttributeInErr, vDescriptionIsSet, vCodeIsSet);
	If vCancel Then
		pCancel = True;
		If vDescriptionIsSet Then
			Object.Description = "";
		EndIf;
		If vCodeIsSet Then
			Object.Code = "";
		EndIf;
		vUM = New UserMessage();
		vUM.Field = vAttributeInErr;
		vUM.Text = vMessage;
		vUM.Message();
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	// Notify product is deleted
	If Object.DeletionMark Then
		Notify("HotelProduct.Deleted", Object.Ref, FormOwner);
	Else
		// Notify product cost change
		If (Object.FixProductCost Or Object.FixProductPeriod) And Object.Sum > 0 And Object.Duration > 0 Then
			Notify("HotelProduct.CostChange", Object.Ref, FormOwner);
		Else
			Notify("HotelProduct.Write", Object.Ref, FormOwner);
		EndIf;
	EndIf;
EndProcedure // AfterWrite

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckInDateOnChangeAtServer()
	vObj = FormDataToValue(Object, Type("CatalogObject.HotelProducts"));
	// Calculate check out date
	vObj.CheckOutDate = vObj.pmCalculateCheckOutDate();
	// Fix product period
	If Not vObj.FixPlannedPeriod Then
		vObj.FixProductPeriod = True;
	EndIf;
	ValueToFormData(vObj, Object);
EndProcedure // CheckInDateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckInDateOnChange(pItem)
	CheckInDateOnChangeAtServer();
EndProcedure // CheckInDateOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckOutDateOnChangeAtServer()
	vObj = FormDataToValue(Object, Type("CatalogObject.HotelProducts"));
	// Calculate duration
	vObj.Duration = vObj.pmCalculateDuration();
	// Fix product period
	If Not vObj.FixPlannedPeriod Then
		vObj.FixProductPeriod = True;
	EndIf;
	ValueToFormData(vObj, Object);
EndProcedure // CheckInDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckOutDateOnChange(pItem)
	CheckOutDateOnChangeAtServer();
EndProcedure // CheckInDateOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure DurationOnChangeAtServer()
	vObj = FormDataToValue(Object, Type("CatalogObject.HotelProducts"));
	// Calculate check out date
	vObj.CheckOutDate = vObj.pmCalculateCheckOutDate();
	// Fix product period
	If Not vObj.FixPlannedPeriod Then
		vObj.FixProductPeriod = True;
	EndIf;
	ValueToFormData(vObj, Object);
EndProcedure // DurationOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure DurationOnChange(pItem)
	DurationOnChangeAtServer();
EndProcedure // DurationOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SumOnChange(pItem)
	// Fix product cost
	Object.FixProductCost = True;
EndProcedure // SumOnChange

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetCurrentEmployeeAtServer()
	Return SessionParameters.CurrentUser;
EndFunction // GetCurrentEmployeeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure DeletionMarkOnChange(pItem)
	If Not Object.DeletionMark Then
		If ValueIsFilled(Object.DeletionMarkDate) Then
			Object.DeletionMarkDate = '00010101';
		EndIf;
		If ValueIsFilled(Object.DeletionMarkAuthor) Then
			Object.DeletionMarkAuthor = PredefinedValue("Catalog.Employees.EmptyRef");
		EndIf;
	Else
		If Not ValueIsFilled(Object.DeletionMarkDate) Then
			Object.DeletionMarkDate = CurrentDate();
		EndIf;
		If Not ValueIsFilled(Object.DeletionMarkAuthor) Then
			Object.DeletionMarkAuthor = GetCurrentEmployeeAtServer();
		EndIf;
	EndIf;
EndProcedure // DeletionMarkOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientOnChange(pItem)
	If ValueIsFilled(Object.Client) Then
		Object.FixedClient = True;
	Else
		Object.FixedClient = False;
	EndIf;
EndProcedure // ClientOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FixPlannedPeriodOnChange(pItem)
	If Object.FixPlannedPeriod Then
		If Object.FixProductPeriod Then
			Object.FixProductPeriod = False;
		EndIf;
	EndIf;
EndProcedure // FixPlannedPeriodOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FixProductPeriodOnChange(pItem)
	If Object.FixProductPeriod Then
		If Object.FixPlannedPeriod Then
			Object.FixPlannedPeriod = False;
		EndIf;
	EndIf;
EndProcedure // FixPlannedPeriodOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure DescriptionOnChangeAtServer()
	If Not IsBlankString(Object.Description) Then
		Object.Description = Catalogs.HotelProducts.SetVaucherNumberPresentation(Object.Description, Object.Parent);
		Object.Code = TrimAll(Object.Description);
	EndIf;
EndProcedure // DescriptionOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure DescriptionOnChange(pItem)
	DescriptionOnChangeAtServer();
EndProcedure // DescriptionOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ParentOnChange(pItem)
	DescriptionOnChangeAtServer();
EndProcedure // ParentOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure VaucherIsSpoiled(pCommand)
	If Not Object.DeletionMark Then
		Object.DeletionMark = True;
		Items.FormIsSpoiled.Title = NStr("en='--Vaucher is not spoiled--';ru='Бланк не испорчен';de='--Gutschein wird nicht verdorben--'");
		If ValueIsFilled(Object.DeletionMarkDate) Then
			Object.DeletionMarkDate = '00010101';
		EndIf;
		If ValueIsFilled(Object.DeletionMarkAuthor) Then
			Object.DeletionMarkAuthor = PredefinedValue("Catalog.Employees.EmptyRef");
		EndIf;
	Else
		Object.DeletionMark = False;
		Items.FormIsSpoiled.Title = NStr("en='--Vaucher is spoiled--';ru='Бланк испорчен';de='--Gutschein ist verdorben--'");;
		If Not ValueIsFilled(Object.DeletionMarkDate) Then
			Object.DeletionMarkDate = CurrentDate();
		EndIf;
		If Not ValueIsFilled(Object.DeletionMarkAuthor) Then
			Object.DeletionMarkAuthor = GetCurrentEmployeeAtServer();
		EndIf;
	EndIf;
EndProcedure // VaucherIsSpoiled
