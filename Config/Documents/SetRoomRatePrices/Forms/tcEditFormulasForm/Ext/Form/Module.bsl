
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	Hotel = SessionParameters.CurrentHotel;
	If Parameters.Property("SelectedDocuments") And Parameters.SelectedDocuments.Count() > 0 Then
		For Each vDocsItem In Parameters.SelectedDocuments Do
			vDocsRow = SetRoomRatePricesDocs.Add();
			vDocsRow.SetRoomRatePrices = vDocsItem.Value;
		EndDo;
	EndIf;
	FormulasForDayTypesAndPriceTagsAvailability();
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure HotelClearing(pItem, pStandardProcessing)
	If Not CheckHotelViewAccess() Then
		pStandardProcessing = False;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure FormulasOnStartEdit(pItem, pNewRow, pClone)
	If pNewRow And Not pClone Then
		vRowData = Items.Formulas.CurrentData;
		vRowData.LeftBracket = "= (";
		vRowData.RightBracket = ") x";
		vRowData.PlusInBrackets = "+";
		vRowData.PlusOutBrackets = "+";
	EndIf;
EndProcedure // FormulasOnStartEdit

// -----------------------------------------------------------------------------
&AtClient
Procedure FormulasForDayTypesAndPricetagsOnStartEdit(pItem, pNewRow, pClone)
	 pItem.CurrentData.LeftBracket = NStr("en='Price = ('; ru='Цена = ('; de='Preis = ('");
	 pItem.CurrentData.PlusInBrackets = "+";
	 pItem.CurrentData.RightBracket = ") x";
	 pItem.CurrentData.PlusOutBrackets = "+";
EndProcedure // FormulasForDayTypesAndPricetagsOnStartEdit

// -----------------------------------------------------------------------------
&AtClient
Procedure DayTypeAndPriceTagFormulasViewOnChange(pItem)
	FormulasForDayTypesAndPriceTagsAvailability();
EndProcedure // DayTypeAndPriceTagFormulasViewOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PricesServiceOnChange(Item)
	PricesServiceOnChangeAtServer(Items.Prices.CurrentRow);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PricesRoomClassOnChange(pItem)
	vCurRow = Items.Prices.CurrentData;
	If ValueIsFilled(vCurRow.RoomClass) Then
		vCurRow.RoomType = Undefined;
	EndIf;
EndProcedure // PricesRoomClassOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PricesRoomTypeOnChange(pItem)
	vCurRow = Items.Prices.CurrentData;
	If ValueIsFilled(vCurRow.RoomType) Then
		vCurRow.RoomClass = Undefined;
	EndIf;
EndProcedure // PricesRoomTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FormulasRoomClassOnChange(pItem)
	vCurRow = Items.Formulas.CurrentData;
	If ValueIsFilled(vCurRow.RoomClass) Then
		vCurRow.RoomType = Undefined;
	EndIf;
EndProcedure // FormulasRoomClassOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FormulasRoomTypeOnChange(pItem)
	vCurRow = Items.Formulas.CurrentData;
	If ValueIsFilled(vCurRow.RoomType) Then
		vCurRow.RoomClass = Undefined;
	EndIf;
EndProcedure // FormulasRoomTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FormulasForDayTypesAndPricetagsRoomClassOnChange(pItem)
	vCurRow = Items.FormulasForDayTypesAndPricetags.CurrentData;
	If ValueIsFilled(vCurRow.RoomClass) Then
		vCurRow.RoomType = Undefined;
	EndIf;
EndProcedure // FormulasForDayTypesAndPricetagsRoomClassOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FormulasForDayTypesAndPricetagsRoomTypeOnChange(pItem)
	vCurRow = Items.FormulasForDayTypesAndPricetags.CurrentData;
	If ValueIsFilled(vCurRow.RoomType) Then
		vCurRow.RoomClass = Undefined;
	EndIf;
EndProcedure // FormulasForDayTypesAndPricetagsRoomTypeOnChange

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ChooseDocsAction(pCommand)
	vParams = New Structure("MultipleChoice", True);
	OpenForm("Document.SetRoomRatePrices.ChoiceForm", vParams, ThisForm);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure FormExecute(pCommand)
	vErrorsArray = FormExecuteAtServer();
	For Each vError In vErrorsArray Do
		tcCommonFunctionOnClientServer.TextMessage(vError);
	EndDo;
	ShowMessageBox(, NStr("en='Completed!'; ru='Завершено!'; de='Beendet!'"));
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FillPricesFromDocument(pCommand)
	FormMode = "FillPricesFromTemplateDocument";
	OpenForm("Document.SetRoomRatePrices.ChoiceForm", , ThisForm,  ThisForm.UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // FillPricesFromDocument

// -----------------------------------------------------------------------------
&AtClient
Procedure FillAccTypeFormulasFromDocument(pCommand)
	FormMode = "FillAccTypeFormulasFromTemplateDocument";
	OpenForm("Document.SetRoomRatePrices.ChoiceForm", , ThisForm,  ThisForm.UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // FillAccTypeFormulasFromDocument

// -----------------------------------------------------------------------------
&AtClient
Procedure FillPriceTagFormulasFromDocument(pCommand)
	FormMode = "FillPriceTagFormulasFromTemplateDocument";
	OpenForm("Document.SetRoomRatePrices.ChoiceForm", , ThisForm,  ThisForm.UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // FillAccTypeFormulasFromDocument

// -----------------------------------------------------------------------------
&AtClient
Procedure CopySelectedValueDownTheList(pCommand)
	vListName = "";
	vCurItem = ThisForm.CurrentItem;
	If vCurItem.Name = "Prices" Then
		vListName = "Prices";
	ElsIf vCurItem.Name = "Formulas" Then
		vListName = "Formulas";
	ElsIf vCurItem.Name = "FormulasForDayTypesAndPricetags" Then
		vListName = "FormulasForDayTypesAndPricetags";
	EndIf;
	If Not IsBlankString(vListName) Then
		vColumnName = Mid(Items[vListName].CurrentItem.Name, StrLen(vListName) + 1);
		If Not IsBlankString(vColumnName) Then
			vCurData = Items[vListName].CurrentData;
			vCurRowIndex = ThisForm[vListName].IndexOf(vCurData);
			vCurValue = vCurData[vColumnName];
			For i = (vCurRowIndex + 1) To (ThisForm[vListName].Count() - 1) Do
				vRow = ThisForm[vListName].Get(i);
				vRow[vColumnName] = vCurValue;
			EndDo;
		EndIf;
	EndIf;
EndProcedure // CopySelectedValueDownTheList

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServerNoContext
Function CheckHotelViewAccess()
	Return AccessRight("View", Metadata.Catalogs.Hotels);
EndFunction

// --------------------------------------------------------------------------------
&AtServer
Function FormExecuteAtServer()
	vErrorsArray = New Array;
	For Each vDocRow In SetRoomRatePricesDocs Do
		If ValueIsFilled(vDocRow.SetRoomRatePrices) Then
			Try
				vDocObj = vDocRow.SetRoomRatePrices.GetObject();
				If ValueIsFilled(AccommodationService) Or PricesMultiplier <> 0 Then
					For Each vPricesRow In vDocObj.Prices Do
						If Not ValueIsFilled(AccommodationServiceRoomType) Or 
						   ValueIsFilled(AccommodationServiceRoomType) And AccommodationServiceRoomType = vPricesRow.RoomType Then
							If ValueIsFilled(AccommodationService) Then
								If vPricesRow.Service <> AccommodationService And vPricesRow.IsRoomRevenue And vPricesRow.IsInPrice Or Not ValueIsFilled(vPricesRow.Service) Then
									vPricesRow.Service = AccommodationService;
								EndIf;
								If vPricesRow.Service = AccommodationService Then
									If ValueIsFilled(AccommodationService.QuantityCalculationRule) Then
										vPricesRow.QuantityCalculationRule = AccommodationService.QuantityCalculationRule;
									EndIf;
								EndIf;
							EndIf;
							If PricesMultiplier <> 0 And vPricesRow.IsRoomRevenue And vPricesRow.IsInPrice Then
								vPricesRow.Price = Round(vPricesRow.Price * PricesMultiplier, 2);
							EndIf;
						EndIf;
					EndDo;
				EndIf;
				If ActionTypePrices = 2 Then
					vDocObj.Prices.Clear();
				EndIf;
				If ActionTypeFormulas = 2 Then
					vDocObj.Formulas.Clear();
				EndIf;
				If ActionTypeFormulasForDayTypesAndPricetags = 2 Then
					vDocObj.FormulasForDayTypesAndPricetags.Clear();
				EndIf;
				For Each vPricesRow In Prices Do
					If ValueIsFilled(vPricesRow.Currency) Then
						If ActionTypePrices = 1 Then
							// Try to find and delete this formula row in the document
							vExistingRows = vDocObj.Prices.FindRows(New Structure("ClientType, Service, RoomClass, RoomType, AccommodationType, Price, Currency, MinimumQuantity, VATRate, QuantityCalculationRule, IsRoomRevenue, IsInPrice, IsPricePerPerson", vPricesRow.ClientType, vPricesRow.Service, vPricesRow.RoomClass, vPricesRow.RoomType, vPricesRow.AccommodationType, vPricesRow.Price, vPricesRow.Currency, vPricesRow.MinimumQuantity, vPricesRow.VATRate, vPricesRow.QuantityCalculationRule, vPricesRow.IsRoomRevenue, vPricesRow.IsInPrice, vPricesRow.IsPricePerPerson));
							For Each vExistingRow In vExistingRows Do
								vDocObj.Prices.Delete(vExistingRow);
							EndDo;
						Else
							// Add this price row
							vDocPricesRow = vDocObj.Prices.Add();
							FillPropertyValues(vDocPricesRow, vPricesRow);
						EndIf;
					EndIf;
				EndDo;
				For Each vFormulasRow In Formulas Do
					If ValueIsFilled(vFormulasRow.AccommodationType) And ValueIsFilled(vFormulasRow.MasterAccType) Then
						If ActionTypeFormulas = 1 Then
							// Try to find and delete this formula row in the document
							vExistingRows = vDocObj.Formulas.FindRows(New Structure("ClientType, Service, RoomClass, RoomType, AccommodationType, MasterAccType, Multiplier, BracketsConstant, Constant", vFormulasRow.ClientType, vFormulasRow.Service, vFormulasRow.RoomClass, vFormulasRow.RoomType, vFormulasRow.AccommodationType, vFormulasRow.MasterAccType, vFormulasRow.Multiplier, vFormulasRow.BracketsConstant, vFormulasRow.Constant));
							For Each vExistingRow In vExistingRows Do
								vDocObj.Formulas.Delete(vExistingRow);
							EndDo;
						Else
							// Add this formula row
							vDocFormulasRow = vDocObj.Formulas.Add();
							FillPropertyValues(vDocFormulasRow, vFormulasRow);
						EndIf;
					EndIf;
				EndDo;
				For Each vFormulasRow In FormulasForDayTypesAndPricetags Do
					If ValueIsFilled(vFormulasRow.CalendarDayType) Or ValueIsFilled(vFormulasRow.PriceTag) Or ValueIsFilled(vFormulasRow.RoomType) Or ValueIsFilled(vFormulasRow.RoomClass) Then
						If ActionTypeFormulasForDayTypesAndPricetags = 1 Then
							// Try to find and delete this formula row in the document
							vExistingRows = vDocObj.FormulasForDayTypesAndPricetags.FindRows(New Structure("ClientType, Service, CalendarDayType, RoomClass, RoomType, PriceTag, AccommodationType, Discount, Multiplier, BracketsConstant, Constant", vFormulasRow.ClientType, vFormulasRow.Service, vFormulasRow.CalendarDayType, vFormulasRow.RoomClass, vFormulasRow.RoomType, vFormulasRow.PriceTag, vFormulasRow.AccommodationType, vFormulasRow.Discount, vFormulasRow.Multiplier, vFormulasRow.BracketsConstant, vFormulasRow.Constant));
							For Each vExistingRow In vExistingRows Do
								vDocObj.FormulasForDayTypesAndPricetags.Delete(vExistingRow);
							EndDo;
						Else
							// Add this formula row
							vDocFormulasRow = vDocObj.FormulasForDayTypesAndPricetags.Add();
							FillPropertyValues(vDocFormulasRow, vFormulasRow);
						EndIf;
					EndIf;
				EndDo;
				If vDocObj.Modified() Then
					vDocObj.Write(DocumentWriteMode.Posting);
					vDocObj.pmWriteToSetRoomRatePricesChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				EndIf;
			Except
				vError = cmGetRootErrorDescription(ErrorInfo());
				vErrorsArray.Add(vError);
			EndTry;
		EndIf;
	EndDo;
	Return vErrorsArray;
EndFunction

// --------------------------------------------------------------------------------
&AtClient
Procedure ChoiceProcessing(pSelectedValue, pChoiceSource)
	If ValueIsFilled(pSelectedValue) Then
		If TypeOf(pSelectedValue) = Type("DocumentRef.SetRoomRatePrices") Then
			If FormMode = "FillPricesFromTemplateDocument" Then
				FormMode = "";
				If ActionTypePrices <> 0 Then
					Prices.Clear();
				EndIf;
				FillPricesAtServer(pSelectedValue);
			ElsIf FormMode = "FillAccTypeFormulasFromTemplateDocument" Then
				FormMode = "";
				If ActionTypeFormulas <> 0 Then
					Formulas.Clear();
				EndIf;
				FillAccTypesFormulasAtServer(pSelectedValue);
			ElsIf FormMode = "FillPriceTagFormulasFromTemplateDocument" Then
				FormMode = "";
				If ActionTypeFormulasForDayTypesAndPricetags <> 0 Then
					FormulasForDayTypesAndPricetags.Clear();
				EndIf;
				FillPriceTagsFormulasAtServer(pSelectedValue);
			Else
				FormMode = "";
				If SetRoomRatePricesDocs.FindRows(New Structure("SetRoomRatePrices", pSelectedValue)).Count() = 0 Then
					vDocsRow = SetRoomRatePricesDocs.Add();
					vDocsRow.SetRoomRatePrices = pSelectedValue;
				EndIf;
			EndIf;
		ElsIf TypeOf(pSelectedValue) = Type("Array") Then
			FormMode = "";
			For Each vDoc In pSelectedValue Do
				If SetRoomRatePricesDocs.FindRows(New Structure("SetRoomRatePrices", vDoc)).Count() = 0 Then
					vDocsRow = SetRoomRatePricesDocs.Add();
					vDocsRow.SetRoomRatePrices = vDoc;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
EndProcedure // ChoiceProcessing

// -----------------------------------------------------------------------------
&AtServer
Procedure FillPricesAtServer(pDoc)
	For Each vTemplPricesRow In pDoc.Prices Do
		vPricesRow = Prices.Add();
		FillPropertyValues(vPricesRow, vTemplPricesRow);
	EndDo;
EndProcedure // FillPricesAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillAccTypesFormulasAtServer(pDoc)
	For Each vTemplFormulasRow In pDoc.Formulas Do
		vFormulasRow = Formulas.Add();
		FillPropertyValues(vFormulasRow, vTemplFormulasRow);
		vFormulasRow.LeftBracket = "= (";
		vFormulasRow.RightBracket = ") x";
		vFormulasRow.PlusInBrackets = "+";
		vFormulasRow.PlusOutBrackets = "+";
	EndDo;
EndProcedure // FillAccTypesFormulasAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillPriceTagsFormulasAtServer(pDoc)
	For Each vTemplFormulasRow In pDoc.FormulasForDayTypesAndPricetags Do
		vFormulasRow = FormulasForDayTypesAndPricetags.Add();
		FillPropertyValues(vFormulasRow, vTemplFormulasRow);
		vFormulasRow.LeftBracket = NStr("en='Price = ('; ru='Цена = ('; de='Preis = ('");
		vFormulasRow.RightBracket = ") x";
		vFormulasRow.PlusInBrackets = "+";
		vFormulasRow.PlusOutBrackets = "+";
	EndDo;
EndProcedure // FillPriceTagsFormulasAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FormulasForDayTypesAndPriceTagsAvailability()
	If DayTypeAndPriceTagFormulasView = 0 Then
		Items.FormulasForDayTypesAndPricetagsDiscount.Visible = True;
		Items.FormulasForDayTypesAndPricetagsLeftBracket.Visible = True;
		Items.FormulasForDayTypesAndPricetagsBracketsConstant.Visible = False;
		Items.FormulasForDayTypesAndPricetagsPlusInBrackets.Visible = False;
		Items.FormulasForDayTypesAndPricetagsMultiplier.Visible = False;
		Items.FormulasForDayTypesAndPricetagsRightBracket.Visible = True;
		Items.FormulasForDayTypesAndPricetagsPlusOutBrackets.Visible = False;
		Items.FormulasForDayTypesAndPricetagsConstant.Visible = False;
	Else
		Items.FormulasForDayTypesAndPricetagsDiscount.Visible = False;
		Items.FormulasForDayTypesAndPricetagsLeftBracket.Visible = True;
		Items.FormulasForDayTypesAndPricetagsBracketsConstant.Visible = True;
		Items.FormulasForDayTypesAndPricetagsPlusInBrackets.Visible = True;
		Items.FormulasForDayTypesAndPricetagsMultiplier.Visible = True;
		Items.FormulasForDayTypesAndPricetagsRightBracket.Visible = True;
		Items.FormulasForDayTypesAndPricetagsPlusOutBrackets.Visible = True;
		Items.FormulasForDayTypesAndPricetagsConstant.Visible = True;
	EndIf;
EndProcedure // FormulasForDayTypesAndPriceTagsAvailability

// -----------------------------------------------------------------------------
&AtServer
Procedure PricesServiceOnChangeAtServer(pRow)
	vCurRow = Prices.FindByID(pRow);
	If vCurRow <> Undefined Then
		If ValueIsFilled(vCurRow.Service) Then
			vService = vCurRow.Service;
			// Set default service attributes
			vCurRow.QuantityCalculationRule = vService.QuantityCalculationRule;
			vCurRow.IsRoomRevenue = vService.IsRoomRevenue;
			vCurRow.IsInPrice = vService.IsInPrice;
			vCurRow.IsPricePerPerson = vService.ChargePerPerson;
			// Get service attributes actual on document date
			vServicePrices = vService.GetObject().pmGetServicePrices(Hotel, CurrentSessionDate(), vCurRow.ClientType);
			If vServicePrices.Count() > 0 Then
				vServicePriceRow = vServicePrices.Get(0);
				// Fill default service attributes
				vCurRow.Currency = vServicePriceRow.Currency;
				vCurRow.VATRate = vServicePriceRow.VATRate;
			EndIf;
		EndIf;
	EndIf;
EndProcedure

#EndRegion

